unit EdRows;

// ---------------------------------------------------------------------------
//  Текст с подсветкой по схеме в окне своего редактора (план портирования,
//  шаг 0.7.6, часть 2): замена просмотрам RTF (SchemeRtf - TRichEdit).
//
//  TEdRowsView - TEdView только для чтения. Строки - те же TSchemeRows, что
//  у SchemeRowsToRtf (разница git, GitDiffView): колонка слева без
//  подсветки (номера), вводный кусок (+ / -), подложка строки и дополнение
//  пробелами, строки без подсветки, сброс блочного комментария. Цвета - как
//  в RowsToRtfCore (SchemeRtf), только кусками окна, без RTF.
//
//  Строки с ошибкой (AMarkLines) и текущая (ACurLine) - своим фоном во всю
//  ширину окна, ошибочная - ещё красным жирным текстом (как в RTF).
// ---------------------------------------------------------------------------

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  {$IFDEF MSWINDOWS}Windows,{$ENDIF}
  SysUtils, Classes, Graphics, Controls, ClrScheme, SchemeLine, SchemeRtf,
  EdBuffer, EdView;

type
  TEdRowsView = class(TEdView)
  private
    FRowsBuffer: TEdBuffer;
    FRowRuns: array of TEdRuns;   // куски строки - готовые, цвета явные
    FRowRunCount: array of Integer;
    FRowBack: array of TColor;    // фон строки во всю ширину; clNone - нет
    FRowFore: array of TColor;    // цвет всей строки; clNone - по кускам
    procedure RowsLineRuns(Sender: TObject; ARow: Integer;
      const ALine: WideString; var ARuns: TEdRuns; var ACount: Integer);
    procedure RowsRowStyle(Sender: TObject; ARow: Integer;
      var ABack, AFore: TColor);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Строки ARows с подсветкой по AScheme (nil - без подсветки, цвета
    // ADefFg / ADefBg). Схема не принадлежит окну. AMarkLines - номера
    // строк с ошибкой (с 1, Integer в Pointer), ACurLine - текущая (с 1,
    // 0 - нет). Окно - в начало текста
    procedure ShowRows(const ARows: TSchemeRows; AScheme: TClrScheme;
      ADefFg, ADefBg: TColor; AMarkLines: TList = nil;
      ACurLine: Integer = 0);
    // Простой текст (строки через любые переводы строк) цветами AFg / ABg
    procedure ShowPlain(const AText: string; AFg, ABg: TColor);
  end;

// Строки TSchemeRows для текста файла (как SchemeTextToRtf: каждая строка -
// с подсветкой, без колонки и подложки)
function SchemeTextRows(const AText: string): TSchemeRows;

implementation

function SchemeTextRows(const AText: string): TSchemeRows;
var
  Lines: TStringList;
  LineIdx: Integer;
begin
  Result := nil;
  Lines := TStringList.Create;
  try
    Lines.Text := AText;
    SetLength(Result, Lines.Count);
    for LineIdx := 0 to Lines.Count - 1 do
    begin
      Result[LineIdx].Prefix := '';
      Result[LineIdx].PrefixFg := clNone;
      Result[LineIdx].PrefixBg := clNone;
      Result[LineIdx].Lead := '';
      Result[LineIdx].Text := Lines[LineIdx];
      Result[LineIdx].Highlight := True;
      Result[LineIdx].TextFg := clNone;
      Result[LineIdx].RowBg := clNone;
      Result[LineIdx].PadTo := 0;
      Result[LineIdx].ResetBlock := False;
    end;
  finally
    Lines.Free;
  end;
end;

constructor TEdRowsView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRowsBuffer := TEdBuffer.Create;
  ReadOnly := True;
  ShowGutter := False;
  OnLineRuns := RowsLineRuns;
  OnRowStyle := RowsRowStyle;
  Buffer := FRowsBuffer;
end;

destructor TEdRowsView.Destroy;
begin
  Buffer := nil;
  FRowsBuffer.Free;
  inherited Destroy;
end;

procedure TEdRowsView.ShowRows(const ARows: TSchemeRows; AScheme: TClrScheme;
  ADefFg, ADefBg: TColor; AMarkLines: TList; ACurLine: Integer);
var
  Colorizer: TSchemeColorizer;
  SchemeRuns: TSchemeRuns;
  RunCount, RunIdx, InBlock, LineIdx, LineLen: Integer;
  TextFg, PageBg, RowBg, MarkFg, MarkBg, CurLineBg: TColor;
  LineMarked, LineCurrent: Boolean;
  Text, Line: string;
  Rgb: Longint;
  AllLines: TStringList;

  // Кусок строки ровно этими цветами (clNone - цвет текста / фон схемы)
  procedure EmitRaw(const AChunk: string; AFg, ABg: TColor;
    AStyle: TFontStyles);
  var
    Runs: TEdRuns;
    Count: Integer;
  begin
    if AChunk = '' then
      Exit;
    if (AFg = clNone) or (AFg = clDefault) then
      AFg := TextFg;
    if (ABg = clNone) or (ABg = clDefault) then
      ABg := PageBg;
    Runs := FRowRuns[LineIdx];
    Count := FRowRunCount[LineIdx];
    // Тот же вид, что у предыдущего куска, - продолжить его
    if (Count > 0) and (Runs[Count - 1].Fore = AFg) and
       (Runs[Count - 1].Back = ABg) and (Runs[Count - 1].Style = AStyle) and
       (Runs[Count - 1].Start + Runs[Count - 1].Len = Length(Line)) then
      Inc(Runs[Count - 1].Len, Length(AChunk))
    else
    begin
      if Count >= Length(Runs) then
      begin
        SetLength(Runs, Count * 2 + 4);
        FRowRuns[LineIdx] := Runs;
      end;
      Runs[Count].Start := Length(Line);
      Runs[Count].Len := Length(AChunk);
      Runs[Count].Fore := AFg;
      Runs[Count].Back := ABg;
      Runs[Count].Style := AStyle;
      FRowRunCount[LineIdx] := Count + 1;
    end;
    Line := Line + AChunk;
  end;

  // Кусок строки: подложка строки - поверх ABg
  procedure Emit(const AChunk: string; AFg, ABg: TColor);
  var
    Style: TFontStyles;
  begin
    Style := [];
    if LineMarked then
    begin
      AFg := MarkFg;
      Style := [fsBold];
    end;
    if (RowBg <> clNone) and not LineMarked and not LineCurrent then
      ABg := RowBg;
    EmitRaw(AChunk, AFg, ABg, Style);
  end;

begin
  Colorizer := TSchemeColorizer.Create(AScheme, ADefFg, ADefBg);
  AllLines := TStringList.Create;
  try
    TextFg := Colorizer.TextFg;
    PageBg := Colorizer.PageBg;
    // Ошибочная и текущая строки - цвета RowsToRtfCore (SchemeRtf)
    Rgb := ColorToRGB(PageBg);
    if (Rgb and $FF) + ((Rgb shr 8) and $FF) + ((Rgb shr 16) and $FF) < 384 then
    begin
      MarkFg := TColor($006060FF);
      CurLineBg := TColor($00704020);
      MarkBg := TColor(((Rgb and $FF) * 6 div 10 + $66) or
                       ((((Rgb shr 8) and $FF) * 6 div 10) shl 8) or
                       ((((Rgb shr 16) and $FF) * 6 div 10) shl 16));
    end
    else
    begin
      MarkFg := TColor($000000B0);
      CurLineBg := TColor($00FFE0B0);
      MarkBg := TColor($00D8D8FF);
    end;

    SetLength(FRowRuns, Length(ARows));
    SetLength(FRowRunCount, Length(ARows));
    SetLength(FRowBack, Length(ARows));
    SetLength(FRowFore, Length(ARows));
    InBlock := -1;
    SchemeRuns := nil;
    for LineIdx := 0 to High(ARows) do
    begin
      FRowRuns[LineIdx] := nil;
      FRowRunCount[LineIdx] := 0;
      FRowBack[LineIdx] := clNone;
      FRowFore[LineIdx] := clNone;
      Line := '';
      Text := ARows[LineIdx].Text;
      LineLen := Length(Text);
      LineMarked := (AMarkLines <> nil) and
                    (AMarkLines.IndexOf(Pointer(LineIdx + 1)) >= 0);
      LineCurrent := LineIdx + 1 = ACurLine;
      if LineMarked then
      begin
        FRowBack[LineIdx] := MarkBg;
        FRowFore[LineIdx] := MarkFg;
      end;
      if LineCurrent then
        FRowBack[LineIdx] := CurLineBg;
      if ARows[LineIdx].ResetBlock then
        InBlock := -1;
      // Колонка слева - своими цветами, без подложки строки
      EmitRaw(ARows[LineIdx].Prefix, ARows[LineIdx].PrefixFg,
        ARows[LineIdx].PrefixBg, []);
      RowBg := ARows[LineIdx].RowBg;
      Emit(ARows[LineIdx].Lead, TextFg, PageBg);
      if (AScheme = nil) or not ARows[LineIdx].Highlight then
        Emit(Text, ARows[LineIdx].TextFg, PageBg)
      else
      begin
        Colorizer.ColorLine(Text, InBlock, SchemeRuns, RunCount);
        for RunIdx := 0 to RunCount - 1 do
          Emit(Copy(Text, SchemeRuns[RunIdx].Start, SchemeRuns[RunIdx].Len),
            SchemeRuns[RunIdx].Fg, SchemeRuns[RunIdx].Bg);
      end;
      if ARows[LineIdx].PadTo > LineLen then
        Emit(StringOfChar(' ', ARows[LineIdx].PadTo - LineLen), TextFg,
          PageBg);
      AllLines.Add(Line);
    end;
    TextColor := TextFg;
    BackColor := PageBg;
    GutterColor := PageBg;
    // Строки через перевод строки, без последнего - строк столько же, сколько
    // ARows
    Text := AllLines.Text;
    if (Length(Text) >= Length(sLineBreak)) and
       (Copy(Text, Length(Text) - Length(sLineBreak) + 1,
             Length(sLineBreak)) = sLineBreak) then
      SetLength(Text, Length(Text) - Length(sLineBreak));
    FRowsBuffer.SetText(WideString(Text));
  finally
    AllLines.Free;
    Colorizer.Free;
  end;
  ClearSelection;
  CaretTo(0, 0);
  ScrollTo(0, 0);
  RefreshAll;
end;

procedure TEdRowsView.ShowPlain(const AText: string; AFg, ABg: TColor);
begin
  SetLength(FRowRuns, 0);
  SetLength(FRowRunCount, 0);
  SetLength(FRowBack, 0);
  SetLength(FRowFore, 0);
  TextColor := AFg;
  BackColor := ABg;
  GutterColor := ABg;
  FRowsBuffer.SetText(WideString(AText));
  ClearSelection;
  CaretTo(0, 0);
  ScrollTo(0, 0);
  RefreshAll;
end;

procedure TEdRowsView.RowsLineRuns(Sender: TObject; ARow: Integer;
  const ALine: WideString; var ARuns: TEdRuns; var ACount: Integer);
var
  RunIdx: Integer;
begin
  ACount := 0;
  if (ARow < 0) or (ARow > High(FRowRunCount)) then
    Exit;
  ACount := FRowRunCount[ARow];
  if Length(ARuns) < ACount then
    SetLength(ARuns, ACount + 8);
  for RunIdx := 0 to ACount - 1 do
    ARuns[RunIdx] := FRowRuns[ARow][RunIdx];
end;

procedure TEdRowsView.RowsRowStyle(Sender: TObject; ARow: Integer;
  var ABack, AFore: TColor);
begin
  if (ARow < 0) or (ARow > High(FRowBack)) then
    Exit;
  if FRowBack[ARow] <> clNone then
    ABack := FRowBack[ARow];
  if FRowFore[ARow] <> clNone then
    AFore := FRowFore[ARow];
end;

end.
