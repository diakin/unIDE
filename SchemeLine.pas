unit SchemeLine;

// ---------------------------------------------------------------------------
//  Разбор строки текста по цветовой схеме (TClrScheme) на куски одного
//  цвета - общий для всех, кто подсвечивает текст схемой без окна
//  редактора: RTF для просмотра (SchemeRtf) и редактор unIDE FAR (UnFar).
//
//  Подсвечивается: блочные комментарии (все пары схемы, через строки -
//  состояние AState переходит из строки в строку), строчный комментарий
//  (с уровнями CUSTOM1..5 по числу "!" за маркером), строки (все маркеры
//  схемы, экранирование StrEscape), числа (с &H / 0x, экспонентой и
//  суффиксами - как задано в Digits), ключевые слова (группы схемы, без
//  учёта регистра; слово с "$" на конце - если оно так и есть в группе),
//  операторы (группы Operators). Отметки строк, имена компонентов и пары
//  скобок - нет: это подсветка редактора unIDE, а не текста.
//
//  Цвета кусков - как в схеме: clNone / clDefault - «цвет текста / фон
//  схемы», подставляет вызывающий (TextFg / PageBg).
//
//  Текст - в кодировке Windows (cp1251), как его читает схема.
// ---------------------------------------------------------------------------

interface

uses
  SysUtils, Classes, Graphics, ClrScheme;

type
  // Кусок строки одного цвета: с символа Start (с 1), Len символов
  TSchemeRun = record
    Start: Integer;
    Len: Integer;
    Fg: TColor;
    Bg: TColor;
  end;
  TSchemeRuns = array of TSchemeRun;

  TSchemeColorizer = class
  private
    FScheme: TClrScheme;
    FKeywords: TStringList;   // слово -> группа (Objects)
    FTextFg: TColor;
    FPageBg: TColor;
    // Разбор текущей строки
    FLine: string;
    FLineLen: Integer;
    FCharPos: Integer;
    FInBlock: Integer;
    FRuns: TSchemeRuns;
    FRunCount: Integer;
    procedure Emit(AStart, ALen: Integer; AFg, ABg: TColor);
    function MarkAt(const AMark: string; APos: Integer): Boolean;
    function FindMark(const AMark: string; APos: Integer): Integer;
    procedure EmitBlockTail;
    function TryBlockComment: Boolean;
    function TryLineComment: Boolean;
    function TryString: Boolean;
    function TryNumber: Boolean;
    function TryWord: Boolean;
    function TryOperator: Boolean;
  public
    // AScheme = nil - без подсветки (вся строка - ADefFg / ADefBg).
    // Схема не копируется: живёт дольше разборщика
    constructor Create(AScheme: TClrScheme; ADefFg, ADefBg: TColor);
    destructor Destroy; override;
    // Куски строки ALine. AState - открытый блочный комментарий в начале
    // строки (-1 - нет; номер пары маркеров), на выходе - в её конце.
    // ARuns растёт по надобности, ACount - сколько в нём кусков
    procedure ColorLine(const ALine: string; var AState: Integer;
      var ARuns: TSchemeRuns; var ACount: Integer);
    property Scheme: TClrScheme read FScheme;
    // Цвет текста и фона схемы (уже без clNone)
    property TextFg: TColor read FTextFg;
    property PageBg: TColor read FPageBg;
  end;

// Фон окна для текста схемы: FTextBG или clWindow
function SchemePageColor(AScheme: TClrScheme): TColor;

implementation

const
  WordChars = ['A'..'Z', 'a'..'z', '0'..'9', '_'];
  WordStart = ['A'..'Z', 'a'..'z', '_'];
  HexChars = ['0'..'9', 'A'..'F', 'a'..'f'];

function SchemePageColor(AScheme: TClrScheme): TColor;
begin
  Result := clWindow;
  if (AScheme <> nil) and (AScheme.FTextBG <> clNone) then
    Result := AScheme.FTextBG;
end;

constructor TSchemeColorizer.Create(AScheme: TClrScheme; ADefFg,
  ADefBg: TColor);
var
  GroupIdx, WordIdx: Integer;
  WordText: string;
begin
  inherited Create;
  FScheme := AScheme;
  if AScheme <> nil then
  begin
    FTextFg := AScheme.FTextFG;
    FPageBg := SchemePageColor(AScheme);
  end
  else
  begin
    FTextFg := ADefFg;
    FPageBg := ADefBg;
  end;
  if (FTextFg = clNone) or (FTextFg = clDefault) then
    FTextFg := clWindowText;
  if (FPageBg = clNone) or (FPageBg = clDefault) then
    FPageBg := clWindow;
  FKeywords := TStringList.Create;
  FKeywords.CaseSensitive := False;
  FKeywords.Sorted := True;
  FKeywords.Duplicates := dupIgnore;   // слово в двух группах - первая
  if AScheme <> nil then
    for GroupIdx := 0 to High(AScheme.KeywordGroups) do
      if AScheme.KeywordGroups[GroupIdx].Words <> nil then
        for WordIdx := 0 to AScheme.KeywordGroups[GroupIdx].Words.Count - 1 do
        begin
          WordText := Trim(AScheme.KeywordGroups[GroupIdx].Words[WordIdx]);
          if WordText <> '' then
            FKeywords.AddObject(WordText, TObject(GroupIdx));
        end;
end;

destructor TSchemeColorizer.Destroy;
begin
  FKeywords.Free;
  inherited Destroy;
end;

// Кусок AStart..AStart+ALen-1; тот же цвет, что у предыдущего, - к нему
procedure TSchemeColorizer.Emit(AStart, ALen: Integer; AFg, ABg: TColor);
begin
  if ALen <= 0 then
    Exit;
  if (FRunCount > 0) and (FRuns[FRunCount - 1].Fg = AFg) and
     (FRuns[FRunCount - 1].Bg = ABg) and
     (FRuns[FRunCount - 1].Start + FRuns[FRunCount - 1].Len = AStart) then
  begin
    Inc(FRuns[FRunCount - 1].Len, ALen);
    Exit;
  end;
  if FRunCount >= Length(FRuns) then
    SetLength(FRuns, FRunCount * 2 + 16);
  FRuns[FRunCount].Start := AStart;
  FRuns[FRunCount].Len := ALen;
  FRuns[FRunCount].Fg := AFg;
  FRuns[FRunCount].Bg := ABg;
  Inc(FRunCount);
end;

// Маркер AMark в строке с позиции APos (без учёта регистра: REM, //, /')
function TSchemeColorizer.MarkAt(const AMark: string; APos: Integer): Boolean;
begin
  // Первый знак - без копирования строки: проверка идёт на каждом символе
  Result := (AMark <> '') and (APos + Length(AMark) - 1 <= FLineLen) and
            (UpCase(FLine[APos]) = UpCase(AMark[1])) and
            ((Length(AMark) = 1) or
             (CompareText(Copy(FLine, APos, Length(AMark)), AMark) = 0));
end;

// Позиция AMark в строке начиная с APos; 0 - нет
function TSchemeColorizer.FindMark(const AMark: string; APos: Integer): Integer;
begin
  Result := APos;
  while Result + Length(AMark) - 1 <= FLineLen do
  begin
    if MarkAt(AMark, Result) then
      Exit;
    Inc(Result);
  end;
  Result := 0;
end;

// Конец блочного комментария: от FCharPos до его маркера конца
// включительно или до конца строки
procedure TSchemeColorizer.EmitBlockTail;
var
  EndMark: string;
  EndAt: Integer;
  BcFg, BcBg: TColor;
begin
  EndMark := FScheme.BcEndMark(FInBlock);
  FScheme.BcColors(FInBlock, BcFg, BcBg);
  EndAt := 0;
  if EndMark <> '' then
    EndAt := FindMark(EndMark, FCharPos);
  if EndAt = 0 then
  begin
    Emit(FCharPos, FLineLen - FCharPos + 1, BcFg, BcBg);
    FCharPos := FLineLen + 1;
  end
  else
  begin
    Emit(FCharPos, EndAt + Length(EndMark) - FCharPos, BcFg, BcBg);
    FCharPos := EndAt + Length(EndMark);
    FInBlock := -1;
  end;
end;

function TSchemeColorizer.TryBlockComment: Boolean;
var
  Kind: Integer;
  StartMark: string;
  BcFg, BcBg: TColor;
begin
  Result := False;
  for Kind := 0 to Length(FScheme.FBcExtra) do
  begin
    StartMark := FScheme.BcStartMark(Kind);
    if MarkAt(StartMark, FCharPos) then
    begin
      FInBlock := Kind;
      FScheme.BcColors(Kind, BcFg, BcBg);
      // Маркер начала - уже часть комментария
      Emit(FCharPos, Length(StartMark), BcFg, BcBg);
      Inc(FCharPos, Length(StartMark));
      EmitBlockTail;
      Result := True;
      Exit;
    end;
  end;
end;

function TSchemeColorizer.TryLineComment: Boolean;
var
  Level, BangPos: Integer;
begin
  // ^; в схеме - комментарий только в начале строки, после пробелов
  Result := MarkAt(FScheme.FLineCommentMarker, FCharPos) and
            FScheme.LineCommentPosOk(FLine, FCharPos);
  if not Result then
    Exit;
  // Уровень CUSTOM - число "!" сразу за маркером, не больше 5
  Level := 0;
  BangPos := FCharPos + Length(FScheme.FLineCommentMarker);
  while (BangPos <= FLineLen) and (FLine[BangPos] = '!') and (Level < 5) do
  begin
    Inc(Level);
    Inc(BangPos);
  end;
  if Level > 0 then
    Emit(FCharPos, FLineLen - FCharPos + 1, FScheme.FCustomFG[Level],
      FScheme.FCustomBG[Level])
  else
    Emit(FCharPos, FLineLen - FCharPos + 1, FScheme.FLcFG, FScheme.FLcBG);
  FCharPos := FLineLen + 1;
end;

function TSchemeColorizer.TryString: Boolean;
var
  Kind, EndPos: Integer;
  Mark: string;
  StrFg, StrBg: TColor;
begin
  Result := False;
  for Kind := 0 to Length(FScheme.FStrExtra) do
  begin
    Mark := FScheme.StrMark(Kind);
    if not MarkAt(Mark, FCharPos) then
      Continue;
    EndPos := FCharPos + Length(Mark);
    while EndPos <= FLineLen do
    begin
      if (FScheme.FStrEscape <> #0) and (FLine[EndPos] = FScheme.FStrEscape) then
        Inc(EndPos, 2)
      else if MarkAt(Mark, EndPos) then
      begin
        Inc(EndPos, Length(Mark));
        Break;
      end
      else
        Inc(EndPos);
    end;
    if EndPos > FLineLen + 1 then
      EndPos := FLineLen + 1;
    FScheme.StrColors(Kind, StrFg, StrBg);
    Emit(FCharPos, EndPos - FCharPos, StrFg, StrBg);
    FCharPos := EndPos;
    Result := True;
    Exit;
  end;
end;

function TSchemeColorizer.TryNumber: Boolean;
var
  EndPos: Integer;
begin
  Result := False;
  if (FCharPos > 1) and (FLine[FCharPos - 1] in WordChars) then
    Exit;
  EndPos := FCharPos;
  // &H1F, &O17, &B101
  if FScheme.FNumHexAmp and (FLine[FCharPos] = '&') and
     (FCharPos + 2 <= FLineLen) and
     (UpCase(FLine[FCharPos + 1]) in ['H', 'O', 'B']) and
     (FLine[FCharPos + 2] in HexChars) then
  begin
    EndPos := FCharPos + 2;
    while (EndPos <= FLineLen) and (FLine[EndPos] in HexChars) do
      Inc(EndPos);
  end
  // 0x1F
  else if FScheme.FNumHex0x and (FLine[FCharPos] = '0') and
          (FCharPos + 2 <= FLineLen) and (FLine[FCharPos + 1] in ['x', 'X']) and
          (FLine[FCharPos + 2] in HexChars) then
  begin
    EndPos := FCharPos + 2;
    while (EndPos <= FLineLen) and (FLine[EndPos] in HexChars) do
      Inc(EndPos);
  end
  else if FLine[FCharPos] in ['0'..'9'] then
  begin
    while (EndPos <= FLineLen) and (FLine[EndPos] in ['0'..'9', '.']) do
      Inc(EndPos);
    if FScheme.FNumExp and (EndPos <= FLineLen) and
       (FLine[EndPos] in ['e', 'E']) and (EndPos + 1 <= FLineLen) and
       (FLine[EndPos + 1] in ['0'..'9', '+', '-']) then
    begin
      Inc(EndPos, 2);
      while (EndPos <= FLineLen) and (FLine[EndPos] in ['0'..'9']) do
        Inc(EndPos);
    end;
  end
  else
    Exit;
  while (EndPos <= FLineLen) and (FLine[EndPos] in FScheme.FNumSuffix) do
    Inc(EndPos);
  Emit(FCharPos, EndPos - FCharPos, FScheme.FDgFG, FScheme.FDgBG);
  FCharPos := EndPos;
  Result := True;
end;

function TSchemeColorizer.TryWord: Boolean;
var
  EndPos, FoundIdx, GroupIdx: Integer;
  WordText: string;
begin
  Result := FLine[FCharPos] in WordStart;
  if not Result then
    Exit;
  EndPos := FCharPos;
  while (EndPos <= FLineLen) and (FLine[EndPos] in WordChars) do
    Inc(EndPos);
  WordText := Copy(FLine, FCharPos, EndPos - FCharPos);
  // chr$, mid$: слово с "$" - если так записано в группе
  if (EndPos <= FLineLen) and (FLine[EndPos] = '$') and
     FKeywords.Find(WordText + '$', FoundIdx) then
    Inc(EndPos)
  else if not FKeywords.Find(WordText, FoundIdx) then
    FoundIdx := -1;
  if FoundIdx >= 0 then
  begin
    GroupIdx := Integer(FKeywords.Objects[FoundIdx]);
    Emit(FCharPos, EndPos - FCharPos, FScheme.KeywordGroups[GroupIdx].FgColor,
      FScheme.KeywordGroups[GroupIdx].BgColor);
  end
  else
    Emit(FCharPos, EndPos - FCharPos, FTextFg, FPageBg);
  FCharPos := EndPos;
end;

function TSchemeColorizer.TryOperator: Boolean;
var
  OpIdx, Found: Integer;
begin
  // Символ в двух группах - цветом той, что ниже в файле (как в редакторе)
  Found := -1;
  for OpIdx := 0 to High(FScheme.OpGroups) do
    if FLine[FCharPos] in FScheme.OpGroups[OpIdx].Chars then
      Found := OpIdx;
  Result := Found >= 0;
  if Result then
  begin
    Emit(FCharPos, 1, FScheme.OpGroups[Found].FgColor,
      FScheme.OpGroups[Found].BgColor);
    Inc(FCharPos);
  end;
end;

procedure TSchemeColorizer.ColorLine(const ALine: string; var AState: Integer;
  var ARuns: TSchemeRuns; var ACount: Integer);
begin
  FLine := ALine;
  FLineLen := Length(ALine);
  FCharPos := 1;
  FInBlock := AState;
  FRuns := ARuns;
  FRunCount := 0;
  try
    if FScheme = nil then
    begin
      Emit(1, FLineLen, FTextFg, FPageBg);
      FCharPos := FLineLen + 1;
      FInBlock := -1;
    end
    else if FInBlock >= 0 then
      EmitBlockTail;
    while FCharPos <= FLineLen do
    begin
      if TryBlockComment or TryLineComment or TryString or TryNumber or
         TryWord or TryOperator then
        Continue;
      Emit(FCharPos, 1, FTextFg, FPageBg);
      Inc(FCharPos);
    end;
  finally
    ARuns := FRuns;
    ACount := FRunCount;
    AState := FInBlock;
    FRuns := nil;
    FLine := '';
  end;
end;

end.
