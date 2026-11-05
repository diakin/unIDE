unit TextDiff;

// ---------------------------------------------------------------------------
//  Разница двух текстов по строкам - для окна сравнения файлов (как в
//  WinMerge). Без VCL.
//
//  DiffLines - участки: общие строки и отличия (изменено, только слева,
//  только справа). Алгоритм Майерса O(ND) с поиском середины (линейная
//  память), как compareseq / diag в GNU diff: файлы размером с Unit1.pas
//  (90 000 строк) сравниваются без матрицы N*M. Если отличий очень много,
//  поиск середины останавливается раньше (TooExpensive, как в GNU diff) -
//  разница остаётся верной, но может быть не самой короткой.
//
//  Строки сравниваются по ключу: с параметрами (без учёта регистра,
//  пробелов) ключ - строка после приведения. Каждому ключу - свой номер,
//  дальше сравниваются числа.
//
//  DiffAlign - строки двух панелей друг против друга: у участка с разным
//  числом строк короткая сторона дополняется пустыми строками (-1).
//
//  DiffInline - отличия внутри пары строк: по словам, пробелам и знакам.
//  Номера символов - с 1, как в string.
// ---------------------------------------------------------------------------

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  SysUtils, Classes;

type
  TDiffOptions = record
    IgnoreCase: Boolean;         // без учёта регистра
    IgnoreSpaceChange: Boolean;  // пробелы и табуляции: только есть / нет
    IgnoreAllSpace: Boolean;     // пробелы и табуляции не учитываются
    // Пробелы и табуляции - только там, где они меняют смысл: между двумя
    // словами (буквы, цифры, '_') - есть / нет; внутри строк в кавычках
    // ('...' и "...") - как есть; остальные не учитываются
    IgnoreSpaceSmart: Boolean;
  end;

  TDiffKind = (dkEqual, dkChange, dkLeftOnly, dkRightOnly);

  // Участок: строки слева [LeftStart, LeftStart + LeftCount) и справа
  // [RightStart, RightStart + RightCount), номера с 0
  TDiffBlock = record
    Kind: TDiffKind;
    LeftStart, LeftCount: Integer;
    RightStart, RightCount: Integer;
  end;
  TDiffBlocks = array of TDiffBlock;

  // Строка вида сравнения: номера строк слева и справа (с 0; -1 - пустая
  // строка-выравнивание), номер отличия (с 0; -1 - общая строка)
  TDiffRow = record
    LeftLine, RightLine: Integer;
    DiffIndex: Integer;
  end;
  TDiffRows = array of TDiffRow;

  // Кусок строки: символы [Start, Start + Len), номера с 1
  TDiffRange = record
    Start, Len: Integer;
  end;
  TDiffRanges = array of TDiffRange;

// Параметры по умолчанию: всё учитывается
function DiffDefaultOptions: TDiffOptions;

// Участки разницы ALeft -> ARight по строкам
function DiffLines(ALeft, ARight: TStrings;
  const AOptions: TDiffOptions): TDiffBlocks;

// Число отличий (участков не dkEqual)
function DiffCount(const ABlocks: TDiffBlocks): Integer;

// Строки двух панелей друг против друга
function DiffAlign(const ABlocks: TDiffBlocks): TDiffRows;

// Отличия внутри пары строк: куски левой и правой строки, которых нет в
// другой
procedure DiffInline(const ALeftStr, ARightStr: string;
  const AOptions: TDiffOptions;
  var ALeftRanges, ARightRanges: TDiffRanges);

// Ключ строки для сравнения с учётом параметров
function DiffLineKey(const ALine: string; const AOptions: TDiffOptions): string;

implementation

type
  TIntArray = array of Integer;
  TBoolArray = array of Boolean;

  // Состояние одного сравнения двух последовательностей чисел
  TDiffEngine = class
  private
    FLeftIds, FRightIds: TIntArray;
    FLeftChanged, FRightChanged: TBoolArray;
    FForward, FBackward: TIntArray;  // по диагоналям, со смещением FDiagOfs
    FDiagOfs: Integer;
    FTooExpensive: Integer;
    FMidLeft, FMidRight: Integer;
    procedure FindMiddle(LeftOff, LeftLim, RightOff, RightLim: Integer);
    procedure CompareSeq(LeftOff, LeftLim, RightOff, RightLim: Integer);
  public
    constructor Create(const ALeftIds, ARightIds: TIntArray);
    procedure Run;
    property LeftChanged: TBoolArray read FLeftChanged;
    property RightChanged: TBoolArray read FRightChanged;
  end;

const
  DiffNoLine = -1;
  DiffMaxInt = MaxInt;
  // Нижний порог числа шагов поиска середины (в GNU diff - 4096). Меньше -
  // быстрее на совсем разных файлах, но разница чаще не самая короткая
  DiffMinExpensive = 1024;

function DiffDefaultOptions: TDiffOptions;
begin
  Result.IgnoreCase := False;
  Result.IgnoreSpaceChange := False;
  Result.IgnoreAllSpace := False;
  Result.IgnoreSpaceSmart := False;
end;

function IsSpaceChar(ACh: Char): Boolean;
begin
  Result := (ACh = ' ') or (ACh = #9);
end;

function IsWordChar(ACh: Char): Boolean;
begin
  Result := (ACh = '_') or (ACh in ['0'..'9', 'A'..'Z', 'a'..'z']) or
            (Ord(ACh) >= 128);
end;

// Ключ строки при IgnoreSpaceSmart: пробелы вне кавычек - один пробел
// между двумя словами, иначе ничего; в кавычках - как есть
function SmartSpaceKey(const ALine: string): string;
var
  SrcIdx, OutLen: Integer;
  InSpace: Boolean;
  Quote: Char;
begin
  SetLength(Result, Length(ALine));
  OutLen := 0;
  InSpace := False;
  Quote := #0;
  SrcIdx := 1;
  while SrcIdx <= Length(ALine) do
  begin
    if Quote <> #0 then
    begin
      Inc(OutLen);
      Result[OutLen] := ALine[SrcIdx];
      if (ALine[SrcIdx] = '\') and (SrcIdx < Length(ALine)) then
      begin
        Inc(SrcIdx);
        Inc(OutLen);
        Result[OutLen] := ALine[SrcIdx];
      end
      else if ALine[SrcIdx] = Quote then
        Quote := #0;
    end
    else if IsSpaceChar(ALine[SrcIdx]) then
      InSpace := True
    else
    begin
      if InSpace and (OutLen > 0) and IsWordChar(Result[OutLen]) and
         IsWordChar(ALine[SrcIdx]) then
      begin
        Inc(OutLen);
        Result[OutLen] := ' ';
      end;
      InSpace := False;
      Inc(OutLen);
      Result[OutLen] := ALine[SrcIdx];
      if (ALine[SrcIdx] = '''') or (ALine[SrcIdx] = '"') then
        Quote := ALine[SrcIdx];
    end;
    Inc(SrcIdx);
  end;
  SetLength(Result, OutLen);
end;

function DiffLineKey(const ALine: string; const AOptions: TDiffOptions): string;
var
  SrcIdx, OutLen: Integer;
  InSpace: Boolean;
begin
  if AOptions.IgnoreSpaceSmart and not AOptions.IgnoreAllSpace then
    Result := SmartSpaceKey(ALine)
  else if AOptions.IgnoreAllSpace or AOptions.IgnoreSpaceChange then
  begin
    SetLength(Result, Length(ALine));
    OutLen := 0;
    InSpace := False;
    for SrcIdx := 1 to Length(ALine) do
      if IsSpaceChar(ALine[SrcIdx]) then
        InSpace := True
      else
      begin
        // пробелы между словами - один пробел (кроме IgnoreAllSpace);
        // в начале и в конце строки - не учитываются
        if InSpace and (OutLen > 0) and not AOptions.IgnoreAllSpace then
        begin
          Inc(OutLen);
          Result[OutLen] := ' ';
        end;
        InSpace := False;
        Inc(OutLen);
        Result[OutLen] := ALine[SrcIdx];
      end;
    SetLength(Result, OutLen);
  end
  else
    Result := ALine;
  if AOptions.IgnoreCase then
    Result := AnsiLowerCase(Result);
end;

// ---------------------------------------------------------------------------
//  TDiffEngine
// ---------------------------------------------------------------------------

constructor TDiffEngine.Create(const ALeftIds, ARightIds: TIntArray);
var
  DiagCount: Integer;
begin
  inherited Create;
  FLeftIds := ALeftIds;
  FRightIds := ARightIds;
  SetLength(FLeftChanged, Length(FLeftIds));
  SetLength(FRightChanged, Length(FRightIds));
  // диагонали от -(M + 1) до N + 1
  FDiagOfs := Length(FRightIds) + 1;
  SetLength(FForward, Length(FLeftIds) + Length(FRightIds) + 3);
  SetLength(FBackward, Length(FLeftIds) + Length(FRightIds) + 3);
  // Порог, как в GNU diff: примерно корень из числа диагоналей, не меньше
  // DiffMinExpensive
  FTooExpensive := 1;
  DiagCount := Length(FLeftIds) + Length(FRightIds) + 3;
  while DiagCount <> 0 do
  begin
    FTooExpensive := FTooExpensive shl 1;
    DiagCount := DiagCount shr 2;
  end;
  if FTooExpensive < DiffMinExpensive then
    FTooExpensive := DiffMinExpensive;
end;

procedure TDiffEngine.Run;
begin
  CompareSeq(0, Length(FLeftIds), 0, Length(FRightIds));
end;

// Середина кратчайшего пути правок для участка [LeftOff, LeftLim) x
// [RightOff, RightLim): FMidLeft, FMidRight. Диагональ Diag = X - Y.
procedure TDiffEngine.FindMiddle(LeftOff, LeftLim, RightOff, RightLim: Integer);
var
  DiagMin, DiagMax, FwdMid, BackMid: Integer;
  FwdMin, FwdMax, BackMin, BackMax: Integer;
  IsOdd: Boolean;
  Cost, Diag, LowVal, HighVal, PosX, PosY: Integer;
  FwdBest, FwdBestX, BackBest, BackBestX: Integer;
begin
  DiagMin := LeftOff - RightLim;
  DiagMax := LeftLim - RightOff;
  FwdMid := LeftOff - RightOff;
  BackMid := LeftLim - RightLim;
  FwdMin := FwdMid;
  FwdMax := FwdMid;
  BackMin := BackMid;
  BackMax := BackMid;
  IsOdd := Odd(FwdMid - BackMid);
  FForward[FDiagOfs + FwdMid] := LeftOff;
  FBackward[FDiagOfs + BackMid] := LeftLim;

  Cost := 1;
  while True do
  begin
    // Шаг вперёд
    if FwdMin > DiagMin then
    begin
      Dec(FwdMin);
      FForward[FDiagOfs + FwdMin - 1] := -1;
    end
    else
      Inc(FwdMin);
    if FwdMax < DiagMax then
    begin
      Inc(FwdMax);
      FForward[FDiagOfs + FwdMax + 1] := -1;
    end
    else
      Dec(FwdMax);
    Diag := FwdMax;
    while Diag >= FwdMin do
    begin
      LowVal := FForward[FDiagOfs + Diag - 1];
      HighVal := FForward[FDiagOfs + Diag + 1];
      if LowVal >= HighVal then
        PosX := LowVal + 1
      else
        PosX := HighVal;
      PosY := PosX - Diag;
      while (PosX < LeftLim) and (PosY < RightLim) and
            (FLeftIds[PosX] = FRightIds[PosY]) do
      begin
        Inc(PosX);
        Inc(PosY);
      end;
      FForward[FDiagOfs + Diag] := PosX;
      if IsOdd and (BackMin <= Diag) and (Diag <= BackMax) and
         (FBackward[FDiagOfs + Diag] <= PosX) then
      begin
        FMidLeft := PosX;
        FMidRight := PosY;
        Exit;
      end;
      Dec(Diag, 2);
    end;

    // Шаг назад
    if BackMin > DiagMin then
    begin
      Dec(BackMin);
      FBackward[FDiagOfs + BackMin - 1] := DiffMaxInt;
    end
    else
      Inc(BackMin);
    if BackMax < DiagMax then
    begin
      Inc(BackMax);
      FBackward[FDiagOfs + BackMax + 1] := DiffMaxInt;
    end
    else
      Dec(BackMax);
    Diag := BackMax;
    while Diag >= BackMin do
    begin
      LowVal := FBackward[FDiagOfs + Diag - 1];
      HighVal := FBackward[FDiagOfs + Diag + 1];
      if LowVal < HighVal then
        PosX := LowVal
      else
        PosX := HighVal - 1;
      PosY := PosX - Diag;
      while (LeftOff < PosX) and (RightOff < PosY) and
            (FLeftIds[PosX - 1] = FRightIds[PosY - 1]) do
      begin
        Dec(PosX);
        Dec(PosY);
      end;
      FBackward[FDiagOfs + Diag] := PosX;
      if not IsOdd and (FwdMin <= Diag) and (Diag <= FwdMax) and
         (PosX <= FForward[FDiagOfs + Diag]) then
      begin
        FMidLeft := PosX;
        FMidRight := PosY;
        Exit;
      end;
      Dec(Diag, 2);
    end;

    // Слишком много отличий: берём лучшую из достигнутых точек
    if Cost >= FTooExpensive then
    begin
      FwdBest := -1;
      FwdBestX := LeftOff;
      Diag := FwdMax;
      while Diag >= FwdMin do
      begin
        PosX := FForward[FDiagOfs + Diag];
        if PosX > LeftLim then
          PosX := LeftLim;
        PosY := PosX - Diag;
        if RightLim < PosY then
        begin
          PosX := RightLim + Diag;
          PosY := RightLim;
        end;
        if FwdBest < PosX + PosY then
        begin
          FwdBest := PosX + PosY;
          FwdBestX := PosX;
        end;
        Dec(Diag, 2);
      end;
      BackBest := DiffMaxInt;
      BackBestX := LeftLim;
      Diag := BackMax;
      while Diag >= BackMin do
      begin
        PosX := FBackward[FDiagOfs + Diag];
        if PosX < LeftOff then
          PosX := LeftOff;
        PosY := PosX - Diag;
        if PosY < RightOff then
        begin
          PosX := RightOff + Diag;
          PosY := RightOff;
        end;
        if PosX + PosY < BackBest then
        begin
          BackBest := PosX + PosY;
          BackBestX := PosX;
        end;
        Dec(Diag, 2);
      end;
      if (LeftLim + RightLim) - BackBest < FwdBest - (LeftOff + RightOff) then
      begin
        FMidLeft := FwdBestX;
        FMidRight := FwdBest - FwdBestX;
      end
      else
      begin
        FMidLeft := BackBestX;
        FMidRight := BackBest - BackBestX;
      end;
      Exit;
    end;
    Inc(Cost);
  end;
end;

procedure TDiffEngine.CompareSeq(LeftOff, LeftLim, RightOff, RightLim: Integer);
var
  MidLeft, MidRight: Integer;
begin
  // Вторая половина - циклом, а не вызовом: глубина рекурсии меньше
  while True do
  begin
    while (LeftOff < LeftLim) and (RightOff < RightLim) and
          (FLeftIds[LeftOff] = FRightIds[RightOff]) do
    begin
      Inc(LeftOff);
      Inc(RightOff);
    end;
    while (LeftOff < LeftLim) and (RightOff < RightLim) and
          (FLeftIds[LeftLim - 1] = FRightIds[RightLim - 1]) do
    begin
      Dec(LeftLim);
      Dec(RightLim);
    end;
    if LeftOff = LeftLim then
    begin
      while RightOff < RightLim do
      begin
        FRightChanged[RightOff] := True;
        Inc(RightOff);
      end;
      Exit;
    end;
    if RightOff = RightLim then
    begin
      while LeftOff < LeftLim do
      begin
        FLeftChanged[LeftOff] := True;
        Inc(LeftOff);
      end;
      Exit;
    end;
    FindMiddle(LeftOff, LeftLim, RightOff, RightLim);
    MidLeft := FMidLeft;
    MidRight := FMidRight;
    CompareSeq(LeftOff, MidLeft, RightOff, MidRight);
    LeftOff := MidLeft;
    RightOff := MidRight;
  end;
end;

// ---------------------------------------------------------------------------
//  Номера ключей и сборка участков
// ---------------------------------------------------------------------------

// Каждой строке - номер её ключа; одинаковые ключи - один номер. Свой
// хеш, а не сортированный TStringList: сравнение строк в TStringList
// зависит от языка Windows (CompareString), а здесь нужно точное равенство.
procedure KeysToIds(ALeft, ARight: TStrings; var ALeftIds, ARightIds: TIntArray);
var
  BucketHeads, NextKey: TIntArray;
  KeyTexts: array of string;
  KeyCount, BucketMask, LineIdx: Integer;

  function HashOf(const AKey: string): Cardinal;
  var
    CharIdx: Integer;
  begin
    Result := 2166136261;
    for CharIdx := 1 to Length(AKey) do
      // FNV-1a; умножение в Int64 - без переполнения при {$Q+}
      Result := Cardinal((Int64(Result xor Ord(AKey[CharIdx])) * 16777619) and $FFFFFFFF);
  end;

  function IdOf(const AKey: string): Integer;
  var
    Bucket: Integer;
  begin
    Bucket := Integer(HashOf(AKey) and Cardinal(BucketMask));
    Result := BucketHeads[Bucket];
    while Result >= 0 do
    begin
      if KeyTexts[Result] = AKey then
        Exit;
      Result := NextKey[Result];
    end;
    Result := KeyCount;
    KeyTexts[KeyCount] := AKey;
    NextKey[KeyCount] := BucketHeads[Bucket];
    BucketHeads[Bucket] := KeyCount;
    Inc(KeyCount);
  end;

begin
  // Корзин - степень двойки, не меньше числа строк
  BucketMask := 1023;
  while BucketMask < ALeft.Count + ARight.Count do
    BucketMask := BucketMask * 2 + 1;
  SetLength(BucketHeads, BucketMask + 1);
  for LineIdx := 0 to BucketMask do
    BucketHeads[LineIdx] := -1;
  SetLength(KeyTexts, ALeft.Count + ARight.Count);
  SetLength(NextKey, ALeft.Count + ARight.Count);
  KeyCount := 0;
  SetLength(ALeftIds, ALeft.Count);
  for LineIdx := 0 to ALeft.Count - 1 do
    ALeftIds[LineIdx] := IdOf(ALeft[LineIdx]);
  SetLength(ARightIds, ARight.Count);
  for LineIdx := 0 to ARight.Count - 1 do
    ARightIds[LineIdx] := IdOf(ARight[LineIdx]);
end;

procedure AddBlock(var ABlocks: TDiffBlocks; var ACount: Integer;
  AKind: TDiffKind; ALeftStart, ALeftCount, ARightStart, ARightCount: Integer);
begin
  if ACount >= Length(ABlocks) then
    SetLength(ABlocks, ACount * 2 + 16);
  ABlocks[ACount].Kind := AKind;
  ABlocks[ACount].LeftStart := ALeftStart;
  ABlocks[ACount].LeftCount := ALeftCount;
  ABlocks[ACount].RightStart := ARightStart;
  ABlocks[ACount].RightCount := ARightCount;
  Inc(ACount);
end;

// Участки по отметкам изменённых элементов
function ChangedToBlocks(const ALeftChanged, ARightChanged: TBoolArray): TDiffBlocks;
var
  LeftIdx, RightIdx, LeftLen, RightLen, StartLeft, StartRight, Count: Integer;
  Kind: TDiffKind;
begin
  Result := nil;
  Count := 0;
  LeftLen := Length(ALeftChanged);
  RightLen := Length(ARightChanged);
  LeftIdx := 0;
  RightIdx := 0;
  while (LeftIdx < LeftLen) or (RightIdx < RightLen) do
  begin
    StartLeft := LeftIdx;
    StartRight := RightIdx;
    if (LeftIdx < LeftLen) and (RightIdx < RightLen) and
       not ALeftChanged[LeftIdx] and not ARightChanged[RightIdx] then
    begin
      while (LeftIdx < LeftLen) and (RightIdx < RightLen) and
            not ALeftChanged[LeftIdx] and not ARightChanged[RightIdx] do
      begin
        Inc(LeftIdx);
        Inc(RightIdx);
      end;
      AddBlock(Result, Count, dkEqual, StartLeft, LeftIdx - StartLeft,
        StartRight, RightIdx - StartRight);
    end
    else
    begin
      while (LeftIdx < LeftLen) and ALeftChanged[LeftIdx] do
        Inc(LeftIdx);
      while (RightIdx < RightLen) and ARightChanged[RightIdx] do
        Inc(RightIdx);
      if (LeftIdx = StartLeft) and (RightIdx = StartRight) then
      begin
        // Не должно случаться (общие строки идут парами); на всякий
        // случай - остаток как отличие, чтобы не зациклиться
        LeftIdx := LeftLen;
        RightIdx := RightLen;
      end;
      if (LeftIdx > StartLeft) and (RightIdx > StartRight) then
        Kind := dkChange
      else if LeftIdx > StartLeft then
        Kind := dkLeftOnly
      else
        Kind := dkRightOnly;
      AddBlock(Result, Count, Kind, StartLeft, LeftIdx - StartLeft,
        StartRight, RightIdx - StartRight);
    end;
  end;
  SetLength(Result, Count);
end;

function DiffLines(ALeft, ARight: TStrings;
  const AOptions: TDiffOptions): TDiffBlocks;
var
  LeftKeys, RightKeys: TStringList;
  LeftIds, RightIds: TIntArray;
  Engine: TDiffEngine;
  LineIdx: Integer;
  PlainKeys: Boolean;
begin
  PlainKeys := not AOptions.IgnoreCase and not AOptions.IgnoreSpaceChange and
    not AOptions.IgnoreAllSpace and not AOptions.IgnoreSpaceSmart;
  LeftKeys := nil;
  RightKeys := nil;
  try
    if PlainKeys then
      KeysToIds(ALeft, ARight, LeftIds, RightIds)
    else
    begin
      LeftKeys := TStringList.Create;
      RightKeys := TStringList.Create;
      LeftKeys.Capacity := ALeft.Count;
      for LineIdx := 0 to ALeft.Count - 1 do
        LeftKeys.Add(DiffLineKey(ALeft[LineIdx], AOptions));
      RightKeys.Capacity := ARight.Count;
      for LineIdx := 0 to ARight.Count - 1 do
        RightKeys.Add(DiffLineKey(ARight[LineIdx], AOptions));
      KeysToIds(LeftKeys, RightKeys, LeftIds, RightIds);
    end;
  finally
    RightKeys.Free;
    LeftKeys.Free;
  end;

  Engine := TDiffEngine.Create(LeftIds, RightIds);
  try
    Engine.Run;
    Result := ChangedToBlocks(Engine.LeftChanged, Engine.RightChanged);
  finally
    Engine.Free;
  end;
end;

function DiffCount(const ABlocks: TDiffBlocks): Integer;
var
  BlockIdx: Integer;
begin
  Result := 0;
  for BlockIdx := 0 to High(ABlocks) do
    if ABlocks[BlockIdx].Kind <> dkEqual then
      Inc(Result);
end;

function DiffAlign(const ABlocks: TDiffBlocks): TDiffRows;
var
  BlockIdx, RowCount, RowIdx, Rows, DiffNum, Line: Integer;
begin
  Result := nil;
  RowCount := 0;
  for BlockIdx := 0 to High(ABlocks) do
    if ABlocks[BlockIdx].LeftCount > ABlocks[BlockIdx].RightCount then
      Inc(RowCount, ABlocks[BlockIdx].LeftCount)
    else
      Inc(RowCount, ABlocks[BlockIdx].RightCount);
  SetLength(Result, RowCount);

  RowIdx := 0;
  DiffNum := -1;
  for BlockIdx := 0 to High(ABlocks) do
  begin
    with ABlocks[BlockIdx] do
    begin
      if Kind <> dkEqual then
        Inc(DiffNum);
      Rows := LeftCount;
      if RightCount > Rows then
        Rows := RightCount;
      for Line := 0 to Rows - 1 do
      begin
        if Line < LeftCount then
          Result[RowIdx].LeftLine := LeftStart + Line
        else
          Result[RowIdx].LeftLine := DiffNoLine;
        if Line < RightCount then
          Result[RowIdx].RightLine := RightStart + Line
        else
          Result[RowIdx].RightLine := DiffNoLine;
        if Kind = dkEqual then
          Result[RowIdx].DiffIndex := -1
        else
          Result[RowIdx].DiffIndex := DiffNum;
        Inc(RowIdx);
      end;
    end;
  end;
end;

// ---------------------------------------------------------------------------
//  Отличия внутри строки
// ---------------------------------------------------------------------------

type
  TCharClass = (ccSpace, ccWord, ccOther);

function CharClassOf(ACh: Char): TCharClass;
begin
  if IsSpaceChar(ACh) then
    Result := ccSpace
  else if (ACh in ['0'..'9', 'A'..'Z', 'a'..'z', '_']) or (Ord(ACh) >= 128) then
    Result := ccWord
  else
    Result := ccOther;
end;

// Слова, пробелы, отдельные знаки: начало каждого куска (с 1) в AStarts,
// последний элемент - Length + 1
procedure SplitTokens(const AStr: string; ATokens: TStrings;
  var AStarts: TIntArray; const AOptions: TDiffOptions);
var
  CharIdx, TokStart, Count: Integer;
  TokClass: TCharClass;
  Token: string;
  Quote: Char;
  Escaped: Boolean;
begin
  ATokens.Clear;
  // IgnoreSpaceSmart: строка в кавычках (как в SmartSpaceKey) - пробелы
  // в ней как есть
  Quote := #0;
  Escaped := False;
  SetLength(AStarts, Length(AStr) + 1);
  Count := 0;
  CharIdx := 1;
  while CharIdx <= Length(AStr) do
  begin
    TokStart := CharIdx;
    TokClass := CharClassOf(AStr[CharIdx]);
    Inc(CharIdx);
    if TokClass <> ccOther then
      while (CharIdx <= Length(AStr)) and
            (CharClassOf(AStr[CharIdx]) = TokClass) do
        Inc(CharIdx);
    Token := Copy(AStr, TokStart, CharIdx - TokStart);
    if TokClass = ccSpace then
    begin
      if AOptions.IgnoreAllSpace then
        Token := ''
      else if AOptions.IgnoreSpaceSmart and (Quote <> #0) then
        // в кавычках - как есть
      else if AOptions.IgnoreSpaceSmart then
      begin
        // Между двумя словами - есть / нет, иначе не учитывается
        if (TokStart > 1) and (CharIdx <= Length(AStr)) and
           IsWordChar(AStr[TokStart - 1]) and IsWordChar(AStr[CharIdx]) then
          Token := ' '
        else
          Token := '';
      end
      else if AOptions.IgnoreSpaceChange then
        Token := ' ';
    end
    else if AOptions.IgnoreCase then
      Token := AnsiLowerCase(Token);
    if AOptions.IgnoreSpaceSmart and (TokClass <> ccSpace) and
       (CharIdx - TokStart = 1) then
    begin
      if Escaped then
        Escaped := False
      else if (Quote <> #0) and (AStr[TokStart] = '\') then
        Escaped := True
      else if (Quote = #0) and ((AStr[TokStart] = '''') or
              (AStr[TokStart] = '"')) then
        Quote := AStr[TokStart]
      else if AStr[TokStart] = Quote then
        Quote := #0;
    end
    else
      Escaped := False;
    ATokens.Add(Token);
    AStarts[Count] := TokStart;
    Inc(Count);
  end;
  AStarts[Count] := Length(AStr) + 1;
  SetLength(AStarts, Count + 1);
end;

procedure AddRange(var ARanges: TDiffRanges; AStart, ALen: Integer);
var
  Count: Integer;
begin
  if ALen <= 0 then
    Exit;
  Count := Length(ARanges);
  SetLength(ARanges, Count + 1);
  ARanges[Count].Start := AStart;
  ARanges[Count].Len := ALen;
end;

// Есть ли в кусках [AFrom, ATo) что-то, кроме неучитываемых пробелов
function HasCountedTokens(ATokens: TStrings; AFrom, ATo: Integer): Boolean;
var
  TokIdx: Integer;
begin
  Result := False;
  for TokIdx := AFrom to ATo - 1 do
    if ATokens[TokIdx] <> '' then
    begin
      Result := True;
      Exit;
    end;
end;

procedure DiffInline(const ALeftStr, ARightStr: string;
  const AOptions: TDiffOptions;
  var ALeftRanges, ARightRanges: TDiffRanges);
var
  LeftTokens, RightTokens: TStringList;
  LeftStarts, RightStarts, LeftIds, RightIds: TIntArray;
  Engine: TDiffEngine;
  TokBlocks: TDiffBlocks;
  BlockIdx, LeftFrom, LeftTo, RightFrom, RightTo: Integer;
  LeftCh, RightCh: string;
begin
  ALeftRanges := nil;
  ARightRanges := nil;
  LeftTokens := TStringList.Create;
  RightTokens := TStringList.Create;
  try
    SplitTokens(ALeftStr, LeftTokens, LeftStarts, AOptions);
    SplitTokens(ARightStr, RightTokens, RightStarts, AOptions);
    KeysToIds(LeftTokens, RightTokens, LeftIds, RightIds);
    Engine := TDiffEngine.Create(LeftIds, RightIds);
    try
      Engine.Run;
      TokBlocks := ChangedToBlocks(Engine.LeftChanged, Engine.RightChanged);
    finally
      Engine.Free;
    end;

    for BlockIdx := 0 to High(TokBlocks) do
      with TokBlocks[BlockIdx] do
      begin
        if Kind = dkEqual then
          Continue;
        if (Kind = dkLeftOnly) and
           not HasCountedTokens(LeftTokens, LeftStart, LeftStart + LeftCount) then
          Continue;
        if (Kind = dkRightOnly) and
           not HasCountedTokens(RightTokens, RightStart, RightStart + RightCount) then
          Continue;
        // символы участка: [From, To)
        LeftFrom := LeftStarts[LeftStart];
        LeftTo := LeftStarts[LeftStart + LeftCount];
        RightFrom := RightStarts[RightStart];
        RightTo := RightStarts[RightStart + RightCount];
        if Kind = dkChange then
        begin
          // Изменённое слово - только отличающиеся символы: общее начало
          // и конец отбрасываются (protocol1Pl / protocol11 -> Pl / 1)
          while (LeftFrom < LeftTo) and (RightFrom < RightTo) do
          begin
            LeftCh := ALeftStr[LeftFrom];
            RightCh := ARightStr[RightFrom];
            if AOptions.IgnoreCase then
            begin
              LeftCh := AnsiLowerCase(LeftCh);
              RightCh := AnsiLowerCase(RightCh);
            end;
            if LeftCh <> RightCh then
              Break;
            Inc(LeftFrom);
            Inc(RightFrom);
          end;
          while (LeftFrom < LeftTo) and (RightFrom < RightTo) do
          begin
            LeftCh := ALeftStr[LeftTo - 1];
            RightCh := ARightStr[RightTo - 1];
            if AOptions.IgnoreCase then
            begin
              LeftCh := AnsiLowerCase(LeftCh);
              RightCh := AnsiLowerCase(RightCh);
            end;
            if LeftCh <> RightCh then
              Break;
            Dec(LeftTo);
            Dec(RightTo);
          end;
        end;
        AddRange(ALeftRanges, LeftFrom, LeftTo - LeftFrom);
        AddRange(ARightRanges, RightFrom, RightTo - RightFrom);
      end;
  finally
    RightTokens.Free;
    LeftTokens.Free;
  end;
end;

end.
