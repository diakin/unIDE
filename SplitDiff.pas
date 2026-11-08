unit SplitDiff;

// ---------------------------------------------------------------------------
//  Сравнение двух панелей окна unIDE (как WinMerge): разница текстов двух
//  окон TEdView по строкам (TextDiff) и её показ.
//
//  - Строки выравниваются: против строк, которых нет в другой панели, -
//    пустые строки-заполнители (TEdView.SetDisplayMap). Обе панели имеют
//    одинаковое число строк экрана, поэтому прокрутка - на ту же строку
//    экрана (SyncFrom), и вниз, и вбок.
//  - Строки отличий - своим фоном, текущее отличие - другим; места
//    внутри изменённой строки, которых нет в парной строке, - ярче
//    (DiffInline, TEdView.OnMarkRuns).
//  - Пробелы и табуляции по умолчанию - IgnoreSpaceSmart: учитываются
//    только между двумя словами и внутри строк в кавычках.
//
//  Буферы не принадлежат объекту. После правки (Unit1 - после паузы в
//  наборе) - Recalc заново; до этого карту строк TEdView сдвигает сам.
//
//  Без Unit1: окна, цвета темы (Dark) и параметры задаёт владелец.
// ---------------------------------------------------------------------------

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  SysUtils, Classes, Graphics, EdBuffer, EdView, EdScheme, TextDiff;

type
  TSplitDiffSide = (sdsLeft, sdsRight);

  TSplitDiff = class
  private
    FLeft: TEdView;
    FRight: TEdView;
    FOptions: TDiffOptions;
    FDark: Boolean;
    // Цвета: строка отличия, место в ней, текущее отличие, место в нём,
    // заполнитель
    FColDiff, FColInline, FColCur, FColCurInline, FColFiller: TColor;
    FBlocks: TDiffBlocks;
    FRows: TDiffRows;
    FLeftMap, FRightMap: array of Integer;
    // Номер отличия каждой строки буфера (-1 - общая строка)
    FLeftDiff, FRightDiff: array of Integer;
    // Места отличий внутри строки (номера символов с 1)
    FLeftInline, FRightInline: array of TDiffRanges;
    // Первая строка экрана каждого отличия
    FDiffDisp: array of Integer;
    FCount: Integer;
    FCur: Integer;
    FSyncBusy: Boolean;
    procedure SetDark(AValue: Boolean);
    function ViewOf(ASide: TSplitDiffSide): TEdView;
    function DiffOfRow(ASide: TSplitDiffSide; ARow: Integer): Integer;
    procedure MarkRuns(ASide: TSplitDiffSide; ARow: Integer;
      const ALine: WideString; var ARuns: TEdRuns; var ACount: Integer);
    procedure LeftMarkRuns(Sender: TObject; ARow: Integer;
      const ALine: WideString; var ARuns: TEdRuns; var ACount: Integer);
    procedure RightMarkRuns(Sender: TObject; ARow: Integer;
      const ALine: WideString; var ARuns: TEdRuns; var ACount: Integer);
    procedure LeftRowStyle(Sender: TObject; ARow: Integer;
      var ABack, AFore: TColor);
  public
    constructor Create;
    destructor Destroy; override;
    // Окна панелей. Левому ставятся OnRowStyle и OnMarkRuns, правому -
    // OnMarkRuns (фон строк правого - через RowBack, у него свой
    // OnRowStyle); nil - отпустить окна
    procedure Attach(ALeft, ARight: TEdView);
    // Разница заново - по текстам буферов окон; карты строк - окнам
    procedure Recalc;
    // Карты строк - окнам снова (окно сменило буфер и карту потеряло)
    procedure ApplyMaps;
    // Убрать разницу и карты строк
    procedure Clear;
    // Фон строки ARow панели ASide: clNone - строка общая
    function RowBack(ASide: TSplitDiffSide; ARow: Integer): TColor;
    // Окно ASrc прокрутили - другое на ту же строку экрана и колонку
    procedure SyncFrom(ASrc: TEdView);
    // Перейти к отличию ADiffIdx: обе панели - к нему, каретка окна
    // AFocus (nil - левого) - на его первую строку
    procedure GoToDiff(ADiffIdx: Integer; AFocus: TEdView);
    // Следующее (ADir = 1) / предыдущее (-1) отличие от каретки окна
    // AFocus. False - дальше отличий нет
    function Go(ADir: Integer; AFocus: TEdView): Boolean;
    function FillerColor: TColor;
    // Свои цвета (настройки владельца); Dark ставит цвета по умолчанию
    procedure SetColors(ADiff, AInline, ACur, ACurInline, AFiller: TColor);
    property Options: TDiffOptions read FOptions write FOptions;
    // Тёмная тема: цвета отличий для тёмного фона
    property Dark: Boolean read FDark write SetDark;
    property Count: Integer read FCount;
    property Current: Integer read FCur;
    property LeftView: TEdView read FLeft;
    property RightView: TEdView read FRight;
  end;

implementation

const
  // Цвета ($00BBGGRR): строка отличия, место внутри строки, текущее
  // отличие и место в нём, заполнитель - для светлой и тёмной темы
  LightDiffBack = $0090F4FF;       // светло-жёлтый
  LightInlineBack = $0030BCFF;     // оранжево-жёлтый
  LightCurBack = $00FFDCA0;        // светло-голубой
  LightCurInline = $00FFA040;      // голубой
  LightFiller = $00E0E0E0;
  DarkDiffBack = $00005A6E;        // тёмно-жёлтый
  DarkInlineBack = $00008CB4;      // жёлтый
  DarkCurBack = $00805418;         // синий
  DarkCurInline = $00C88C18;       // голубой
  DarkFiller = $00404040;
  // Длиннее - места внутри строки не ищутся (строка - фоном отличия)
  InlineMaxLen = 4000;

constructor TSplitDiff.Create;
begin
  inherited Create;
  FOptions := DiffDefaultOptions;
  FOptions.IgnoreSpaceSmart := True;
  FCur := -1;
  FDark := True;
  SetDark(False);
end;

procedure TSplitDiff.SetDark(AValue: Boolean);
begin
  FDark := AValue;
  if AValue then
    SetColors(DarkDiffBack, DarkInlineBack, DarkCurBack, DarkCurInline,
      DarkFiller)
  else
    SetColors(LightDiffBack, LightInlineBack, LightCurBack, LightCurInline,
      LightFiller);
end;

procedure TSplitDiff.SetColors(ADiff, AInline, ACur, ACurInline,
  AFiller: TColor);
begin
  FColDiff := ADiff;
  FColInline := AInline;
  FColCur := ACur;
  FColCurInline := ACurInline;
  FColFiller := AFiller;
end;

destructor TSplitDiff.Destroy;
begin
  Attach(nil, nil);
  inherited Destroy;
end;

procedure TSplitDiff.Attach(ALeft, ARight: TEdView);
begin
  if (FLeft <> nil) and (FLeft <> ALeft) then
  begin
    FLeft.OnMarkRuns := nil;
    FLeft.OnRowStyle := nil;
    FLeft.ClearDisplayMap;
  end;
  if (FRight <> nil) and (FRight <> ARight) then
  begin
    FRight.OnMarkRuns := nil;
    FRight.ClearDisplayMap;
  end;
  FLeft := ALeft;
  FRight := ARight;
  if FLeft <> nil then
  begin
    FLeft.OnMarkRuns := LeftMarkRuns;
    FLeft.OnRowStyle := LeftRowStyle;
  end;
  if FRight <> nil then
    FRight.OnMarkRuns := RightMarkRuns;
end;

function TSplitDiff.ViewOf(ASide: TSplitDiffSide): TEdView;
begin
  if ASide = sdsLeft then
    Result := FLeft
  else
    Result := FRight;
end;

function TSplitDiff.FillerColor: TColor;
begin
  Result := FColFiller;
end;

procedure TSplitDiff.Clear;
begin
  FBlocks := nil;
  FRows := nil;
  FLeftMap := nil;
  FRightMap := nil;
  FLeftDiff := nil;
  FRightDiff := nil;
  FLeftInline := nil;
  FRightInline := nil;
  FDiffDisp := nil;
  FCount := 0;
  FCur := -1;
  if FLeft <> nil then
  begin
    FLeft.ClearDisplayMap;
    FLeft.Invalidate;
  end;
  if FRight <> nil then
  begin
    FRight.ClearDisplayMap;
    FRight.Invalidate;
  end;
end;

// Строки буфера - строками для TextDiff (кодировка Windows, как у Unit1)
procedure BufferToLines(ABuffer: TEdBuffer; ALines: TStrings);
var
  RowIdx: Integer;
begin
  ALines.Clear;
  if ABuffer = nil then
    Exit;
  ALines.Capacity := ABuffer.Count;
  for RowIdx := 0 to ABuffer.Count - 1 do
    ALines.Add(EdAnsiLine(ABuffer[RowIdx]));
end;

procedure TSplitDiff.Recalc;
var
  LeftLines, RightLines, LeftCmp, RightCmp: TStringList;
  RowIdx, DiffIdx, LeftLine, RightLine: Integer;
  LeftRanges, RightRanges: TDiffRanges;
begin
  FBlocks := nil;
  FRows := nil;
  FCount := 0;
  if (FLeft = nil) or (FRight = nil) or (FLeft.Buffer = nil) or
     (FRight.Buffer = nil) then
  begin
    Clear;
    Exit;
  end;
  LeftLines := TStringList.Create;
  RightLines := TStringList.Create;
  LeftCmp := nil;
  RightCmp := nil;
  try
    BufferToLines(FLeft.Buffer, LeftLines);
    BufferToLines(FRight.Buffer, RightLines);
    // Без комментариев: места внутри строки - по строкам без них (символы
    // комментария - пробелы, номера символов те же)
    if FOptions.IgnoreComments then
    begin
      LeftCmp := TStringList.Create;
      RightCmp := TStringList.Create;
      DiffStripComments(LeftLines, LeftCmp, FOptions);
      DiffStripComments(RightLines, RightCmp, FOptions);
    end;
    FBlocks := DiffLines(LeftLines, RightLines, FOptions);
    FRows := DiffAlign(FBlocks);
    FCount := DiffCount(FBlocks);

    SetLength(FLeftMap, Length(FRows));
    SetLength(FRightMap, Length(FRows));
    SetLength(FLeftDiff, LeftLines.Count);
    SetLength(FRightDiff, RightLines.Count);
    SetLength(FLeftInline, 0);
    SetLength(FRightInline, 0);
    SetLength(FLeftInline, LeftLines.Count);
    SetLength(FRightInline, RightLines.Count);
    for RowIdx := 0 to High(FLeftDiff) do
      FLeftDiff[RowIdx] := -1;
    for RowIdx := 0 to High(FRightDiff) do
      FRightDiff[RowIdx] := -1;
    SetLength(FDiffDisp, FCount);
    for DiffIdx := 0 to FCount - 1 do
      FDiffDisp[DiffIdx] := -1;

    for RowIdx := 0 to High(FRows) do
    begin
      LeftLine := FRows[RowIdx].LeftLine;
      RightLine := FRows[RowIdx].RightLine;
      DiffIdx := FRows[RowIdx].DiffIndex;
      FLeftMap[RowIdx] := LeftLine;
      FRightMap[RowIdx] := RightLine;
      if DiffIdx < 0 then
        Continue;
      if (DiffIdx < FCount) and (FDiffDisp[DiffIdx] < 0) then
        FDiffDisp[DiffIdx] := RowIdx;
      if LeftLine >= 0 then
        FLeftDiff[LeftLine] := DiffIdx;
      if RightLine >= 0 then
        FRightDiff[RightLine] := DiffIdx;
      // Пара изменённых строк - места отличий внутри
      if (LeftLine >= 0) and (RightLine >= 0) and
         (Length(LeftLines[LeftLine]) <= InlineMaxLen) and
         (Length(RightLines[RightLine]) <= InlineMaxLen) then
      begin
        if LeftCmp <> nil then
          DiffInline(LeftCmp[LeftLine], RightCmp[RightLine], FOptions,
            LeftRanges, RightRanges)
        else
          DiffInline(LeftLines[LeftLine], RightLines[RightLine], FOptions,
            LeftRanges, RightRanges);
        FLeftInline[LeftLine] := LeftRanges;
        FRightInline[RightLine] := RightRanges;
      end;
    end;
  finally
    RightCmp.Free;
    LeftCmp.Free;
    RightLines.Free;
    LeftLines.Free;
  end;
  if FCur > FCount - 1 then
    FCur := FCount - 1;
  ApplyMaps;
end;

procedure TSplitDiff.ApplyMaps;
begin
  if (FLeft = nil) or (FRight = nil) then
    Exit;
  FLeft.FillerColor := FillerColor;
  FRight.FillerColor := FillerColor;
  if Length(FRows) > 0 then
  begin
    FLeft.SetDisplayMap(FLeftMap);
    FRight.SetDisplayMap(FRightMap);
  end
  else
  begin
    FLeft.ClearDisplayMap;
    FRight.ClearDisplayMap;
  end;
  // Обе - на одну строку экрана, как левая
  FSyncBusy := True;
  try
    FRight.ScrollToDisp(FLeft.TopDisp, FLeft.LeftCol);
  finally
    FSyncBusy := False;
  end;
  FLeft.Invalidate;
  FRight.Invalidate;
end;

function TSplitDiff.DiffOfRow(ASide: TSplitDiffSide; ARow: Integer): Integer;
begin
  Result := -1;
  if ARow < 0 then
    Exit;
  if ASide = sdsLeft then
  begin
    if ARow < Length(FLeftDiff) then
      Result := FLeftDiff[ARow];
  end
  else if ARow < Length(FRightDiff) then
    Result := FRightDiff[ARow];
end;

function TSplitDiff.RowBack(ASide: TSplitDiffSide; ARow: Integer): TColor;
var
  DiffIdx: Integer;
begin
  Result := clNone;
  DiffIdx := DiffOfRow(ASide, ARow);
  if DiffIdx < 0 then
    Exit;
  if DiffIdx = FCur then
    Result := FColCur
  else
    Result := FColDiff;
end;

procedure TSplitDiff.LeftRowStyle(Sender: TObject; ARow: Integer;
  var ABack, AFore: TColor);
var
  Back: TColor;
begin
  Back := RowBack(sdsLeft, ARow);
  if Back <> clNone then
    ABack := Back;
end;

procedure TSplitDiff.MarkRuns(ASide: TSplitDiffSide; ARow: Integer;
  const ALine: WideString; var ARuns: TEdRuns; var ACount: Integer);
var
  DiffIdx, RangeIdx: Integer;
  Ranges: TDiffRanges;
  Back: TColor;
begin
  ACount := 0;
  DiffIdx := DiffOfRow(ASide, ARow);
  if DiffIdx < 0 then
    Exit;
  if ASide = sdsLeft then
  begin
    if ARow >= Length(FLeftInline) then
      Exit;
    Ranges := FLeftInline[ARow];
  end
  else
  begin
    if ARow >= Length(FRightInline) then
      Exit;
    Ranges := FRightInline[ARow];
  end;
  if Length(Ranges) = 0 then
    Exit;
  if DiffIdx = FCur then
    Back := FColCurInline
  else
    Back := FColInline;
  if Length(ARuns) < Length(Ranges) then
    SetLength(ARuns, Length(Ranges));
  for RangeIdx := 0 to High(Ranges) do
  begin
    if Ranges[RangeIdx].Len <= 0 then
      Continue;
    ARuns[ACount].Start := Ranges[RangeIdx].Start - 1;
    ARuns[ACount].Len := Ranges[RangeIdx].Len;
    ARuns[ACount].Fore := clNone;
    ARuns[ACount].Back := Back;
    ARuns[ACount].Style := [];
    Inc(ACount);
  end;
end;

procedure TSplitDiff.LeftMarkRuns(Sender: TObject; ARow: Integer;
  const ALine: WideString; var ARuns: TEdRuns; var ACount: Integer);
begin
  MarkRuns(sdsLeft, ARow, ALine, ARuns, ACount);
end;

procedure TSplitDiff.RightMarkRuns(Sender: TObject; ARow: Integer;
  const ALine: WideString; var ARuns: TEdRuns; var ACount: Integer);
begin
  MarkRuns(sdsRight, ARow, ALine, ARuns, ACount);
end;

procedure TSplitDiff.SyncFrom(ASrc: TEdView);
var
  Other: TEdView;
begin
  if FSyncBusy or (FLeft = nil) or (FRight = nil) then
    Exit;
  if ASrc = FLeft then
    Other := FRight
  else if ASrc = FRight then
    Other := FLeft
  else
    Exit;
  FSyncBusy := True;
  try
    Other.ScrollToDisp(ASrc.TopDisp, ASrc.LeftCol);
  finally
    FSyncBusy := False;
  end;
end;

procedure TSplitDiff.GoToDiff(ADiffIdx: Integer; AFocus: TEdView);
var
  Disp, Top, Row: Integer;
begin
  if (FCount = 0) or (FLeft = nil) or (FRight = nil) then
    Exit;
  if ADiffIdx < 0 then
    ADiffIdx := 0;
  if ADiffIdx > FCount - 1 then
    ADiffIdx := FCount - 1;
  FCur := ADiffIdx;
  if AFocus = nil then
    AFocus := FLeft;
  Disp := FDiffDisp[ADiffIdx];
  if Disp < 0 then
    Disp := 0;
  // Отличие - на треть окна от верха, как в WinMerge
  Top := Disp - FLeft.VisibleRows div 3;
  if Top < 0 then
    Top := 0;
  FSyncBusy := True;
  try
    FLeft.ScrollToDisp(Top, 0);
    FRight.ScrollToDisp(Top, 0);
    Row := AFocus.RowNearDisp(Disp);
    AFocus.MoveTo(Row, 0, False);
    // Каретка не должна увести окно с места
    if AFocus.TopDisp <> Top then
    begin
      FLeft.ScrollToDisp(Top, 0);
      FRight.ScrollToDisp(Top, 0);
    end;
  finally
    FSyncBusy := False;
  end;
  FLeft.Invalidate;
  FRight.Invalidate;
end;

function TSplitDiff.Go(ADir: Integer; AFocus: TEdView): Boolean;
var
  CaretDisp, DiffIdx, Target: Integer;
begin
  Result := False;
  if (FCount = 0) or (FLeft = nil) or (FRight = nil) then
    Exit;
  if AFocus = nil then
    AFocus := FLeft;
  CaretDisp := AFocus.DispOfRow(AFocus.CaretRow);
  Target := -1;
  // Каретка на начале текущего отличия - соседнее
  if (FCur >= 0) and (FCur < FCount) and
     (AFocus.RowNearDisp(FDiffDisp[FCur]) = AFocus.CaretRow) then
    Target := FCur + ADir
  else if ADir > 0 then
  begin
    for DiffIdx := 0 to FCount - 1 do
      if FDiffDisp[DiffIdx] > CaretDisp then
      begin
        Target := DiffIdx;
        Break;
      end;
  end
  else
    for DiffIdx := FCount - 1 downto 0 do
      if FDiffDisp[DiffIdx] < CaretDisp then
      begin
        Target := DiffIdx;
        Break;
      end;
  if (Target < 0) or (Target > FCount - 1) then
    Exit;
  GoToDiff(Target, AFocus);
  Result := True;
end;

end.
