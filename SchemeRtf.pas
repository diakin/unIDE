unit SchemeRtf;

// ---------------------------------------------------------------------------
//  Текст с подсветкой по цветовой схеме (TClrScheme) - одной строкой RTF,
//  для просмотра в TRichEdit: окно загружает её разом, без раскраски по
//  словам через выделение (на файлах в десятки килобайт это медленно).
//
//  Что подсвечивается и как - SchemeLine (TSchemeColorizer, разбор строки
//  по схеме), общий с редактором unIDE FAR: комментарии, строки, числа,
//  ключевые слова, операторы. Отметки строк, имена компонентов и пары
//  скобок - нет: это подсветка редактора unIDE, а не текста.
//
//  Номера строк RTF совпадают со строками текста: каждая строка - свой \par.
//
//  SchemeRowsToRtf - то же для строк с обрамлением (разница git, окно
//  GitDiffView): у строки бывает колонка слева без подсветки (номера),
//  вводный кусок (+ / -), подложка всей строки и дополнение пробелами до
//  ширины; строку можно не подсвечивать (заголовки) и с неё начинать
//  разбор заново (новый кусок разницы - блочный комментарий не тянется).
// ---------------------------------------------------------------------------

interface

uses
  SysUtils, Classes, Graphics, ClrScheme, SchemeLine;

type
  // Строка для SchemeRowsToRtf. Цвета clNone - текст / фон схемы
  TSchemeRow = record
    Prefix: string;          // слева, без подсветки (номера строк)
    PrefixFg, PrefixBg: TColor;
    Lead: string;            // после Prefix, на подложке строки (+ / -)
    Text: string;            // сама строка (табуляции лучше заменить)
    Highlight: Boolean;      // True - по схеме, False - целиком TextFg
    TextFg: TColor;          // цвет строки без подсветки
    RowBg: TColor;           // подложка Lead, Text и дополнения
    PadTo: Integer;          // дополнить Text пробелами до этой длины
    ResetBlock: Boolean;     // разбор с этой строки - заново
  end;
  TSchemeRows = array of TSchemeRow;

// AText - текст файла; AFontName, AFontPt - шрифт. Цвет фона окна просмотра
// - SchemePageColor: подложка символов с ним совпадает, и \highlight
// пишется только там, где подложка другая (CUSTOM-комментарии и т.п.).
// AMarkLines - номера строк (с 1, Integer в Pointer), которые выделить как
// ошибочные: красным жирным текстом и красноватой подложкой. Подложку
// (\highlight) RichEdit 1.0 может не показать - красный текст виден всегда.
// Разбор строки при этом идёт как обычно: блочный комментарий, начатый в
// ней, продолжается и дальше.
// ACurLine - строка (с 1), на которую перешли: своя подложка (синеватая),
// цвета текста - как есть. Вместо выделения: системное выделение рисует
// светлым фоном, и светлые цвета схемы на нём не видны. 0 - нет.
function SchemeTextToRtf(const AText: string; AScheme: TClrScheme;
                         const AFontName: string; AFontPt: Integer;
                         AMarkLines: TList = nil;
                         ACurLine: Integer = 0): string;
function SchemePageColor(AScheme: TClrScheme): TColor;
// Строки ARows с подсветкой по схеме AScheme. AScheme = nil - без
// подсветки, цвета текста и фона - ADefFg / ADefBg
function SchemeRowsToRtf(const ARows: TSchemeRows; AScheme: TClrScheme;
                         const AFontName: string; AFontPt: Integer;
                         ADefFg, ADefBg: TColor): string;

implementation

type
  // Строка, растущая удвоением: сотни тысяч маленьких добавлений без
  // перевыделения на каждое
  TRtfBuf = class
  private
    FData: string;
    FLen: Integer;
  public
    procedure Add(const AText: string);
    function Text: string;
  end;

procedure TRtfBuf.Add(const AText: string);
var
  NewCap: Integer;
begin
  if AText = '' then
    Exit;
  if FLen + Length(AText) > Length(FData) then
  begin
    NewCap := Length(FData) * 2;
    if NewCap < 4096 then
      NewCap := 4096;
    while NewCap < FLen + Length(AText) do
      NewCap := NewCap * 2;
    SetLength(FData, NewCap);
  end;
  Move(AText[1], FData[FLen + 1], Length(AText));
  Inc(FLen, Length(AText));
end;

function TRtfBuf.Text: string;
begin
  Result := Copy(FData, 1, FLen);
end;

function SchemePageColor(AScheme: TClrScheme): TColor;
begin
  Result := SchemeLine.SchemePageColor(AScheme);
end;

// Общее для SchemeTextToRtf и SchemeRowsToRtf
function RowsToRtfCore(const ARows: TSchemeRows; AScheme: TClrScheme;
                       const AFontName: string; AFontPt: Integer;
                       AMarkLines: TList; ACurLine: Integer;
                       ADefFg, ADefBg: TColor): string;
var
  Body: TRtfBuf;
  Colors: TList;          // RGB цветов таблицы; индекс в \cf = позиция + 1
  Colorizer: TSchemeColorizer;
  Runs: TSchemeRuns;
  RunCount, RunIdx: Integer;
  RowBg: TColor;          // подложка текущей строки (TSchemeRow.RowBg)
  TextFg, PageBg: TColor;
  CurFg, CurBg: TColor;   // цвета, которые сейчас действуют в RTF
  InBlock: Integer;       // пара маркеров открытого блочного комментария, -1
  LineMarked: Boolean;    // эта строка - с ошибкой (AMarkLines)
  MarkFg, MarkBg: TColor; // её цвета
  LineCurrent: Boolean;   // строка ACurLine
  CurLineBg: TColor;      // её подложка
  LineIdx, LineLen: Integer;
  Line: string;

  function ColorIndex(AColor: TColor): Integer;
  var
    Rgb: Integer;
  begin
    Rgb := ColorToRGB(AColor);
    Result := Colors.IndexOf(Pointer(Rgb));
    if Result < 0 then
      Result := Colors.Add(Pointer(Rgb));
    Inc(Result);
  end;

  // Кусок текста ровно этими цветами (clNone - цвет текста / фона схемы)
  procedure EmitRaw(const AChunk: string; AFg, ABg: TColor);
  var
    CharIdx: Integer;
    Ch: Char;
  begin
    if AChunk = '' then
      Exit;
    if (AFg = clNone) or (AFg = clDefault) then
      AFg := TextFg;
    if (ABg = clNone) or (ABg = clDefault) then
      ABg := PageBg;
    if ColorToRGB(AFg) <> ColorToRGB(CurFg) then
    begin
      Body.Add('\cf' + IntToStr(ColorIndex(AFg)) + ' ');
      CurFg := AFg;
    end;
    if ColorToRGB(ABg) <> ColorToRGB(CurBg) then
    begin
      if ColorToRGB(ABg) = ColorToRGB(PageBg) then
        Body.Add('\highlight0 ')
      else
        Body.Add('\highlight' + IntToStr(ColorIndex(ABg)) + ' ');
      CurBg := ABg;
    end;
    for CharIdx := 1 to Length(AChunk) do
    begin
      Ch := AChunk[CharIdx];
      case Ch of
        '\', '{', '}':
          Body.Add('\' + Ch);
        #9:
          Body.Add('\tab ');
        #0..#8, #10..#31:
          ;
        #128..#255:
          Body.Add('\''' + LowerCase(IntToHex(Ord(Ch), 2)));
      else
        Body.Add(Ch);
      end;
    end;
  end;

  // Кусок текста строки: ошибочная / текущая строка и подложка строки -
  // поверх цветов AFg / ABg
  procedure Emit(const AChunk: string; AFg, ABg: TColor);
  begin
    if LineMarked then
    begin
      AFg := MarkFg;
      ABg := MarkBg;
    end;
    if LineCurrent then
      ABg := CurLineBg
    else if (RowBg <> clNone) and not LineMarked then
      ABg := RowBg;
    EmitRaw(AChunk, AFg, ABg);
  end;

var
  ColorIdx, Rgb: Integer;
  Header: string;
begin
  Body := TRtfBuf.Create;
  Colors := TList.Create;
  Colorizer := TSchemeColorizer.Create(AScheme, ADefFg, ADefBg);
  try
    RowBg := clNone;
    TextFg := Colorizer.TextFg;
    PageBg := Colorizer.PageBg;
    CurFg := TextFg;
    CurBg := PageBg;
    ColorIndex(TextFg);   // \cf1 - цвет текста
    LineMarked := False;
    LineCurrent := False;
    // Ошибочная строка: на тёмном фоне - светло-красный текст, на светлом -
    // тёмно-красный; подложка - фон с примесью красного
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

    InBlock := -1;
    Runs := nil;
    for LineIdx := 0 to High(ARows) do
    begin
      Line := ARows[LineIdx].Text;
      LineLen := Length(Line);
      LineMarked := (AMarkLines <> nil) and
                    (AMarkLines.IndexOf(Pointer(LineIdx + 1)) >= 0);
      LineCurrent := LineIdx + 1 = ACurLine;
      if ARows[LineIdx].ResetBlock then
        InBlock := -1;
      // Колонка слева - своими цветами, без подложки строки
      RowBg := clNone;
      EmitRaw(ARows[LineIdx].Prefix, ARows[LineIdx].PrefixFg,
              ARows[LineIdx].PrefixBg);
      RowBg := ARows[LineIdx].RowBg;
      Emit(ARows[LineIdx].Lead, TextFg, PageBg);
      if LineMarked then
        Body.Add('\b ');
      // Пустая выделенная строка - пробел, чтобы подложка была видна
      if (LineMarked or LineCurrent) and (LineLen = 0) then
        Emit(' ', TextFg, PageBg);
      if (AScheme = nil) or not ARows[LineIdx].Highlight then
        // Без подсветки - целиком цветом строки
        Emit(Line, ARows[LineIdx].TextFg, PageBg)
      else
      begin
        Colorizer.ColorLine(Line, InBlock, Runs, RunCount);
        for RunIdx := 0 to RunCount - 1 do
          Emit(Copy(Line, Runs[RunIdx].Start, Runs[RunIdx].Len),
               Runs[RunIdx].Fg, Runs[RunIdx].Bg);
      end;
      if ARows[LineIdx].PadTo > LineLen then
        Emit(StringOfChar(' ', ARows[LineIdx].PadTo - LineLen), TextFg,
             PageBg);
      if LineMarked then
        Body.Add('\b0 ');
      RowBg := clNone;
      Body.Add('\par'#13#10);
    end;

    Header := '{\rtf1\ansi\ansicpg1251\deff0{\fonttbl{\f0\fmodern\fcharset204 ' +
              AFontName + ';}}{\colortbl ;';
    for ColorIdx := 0 to Colors.Count - 1 do
    begin
      Rgb := Integer(Colors[ColorIdx]);
      Header := Header + Format('\red%d\green%d\blue%d;',
                                [Rgb and $FF, (Rgb shr 8) and $FF,
                                 (Rgb shr 16) and $FF]);
    end;
    Header := Header + '}\f0\fs' + IntToStr(AFontPt * 2) + '\cf1 ';
    Result := Header + Body.Text + '}';
  finally
    Colorizer.Free;
    Colors.Free;
    Body.Free;
  end;
end;

function SchemeTextToRtf(const AText: string; AScheme: TClrScheme;
                         const AFontName: string; AFontPt: Integer;
                         AMarkLines: TList; ACurLine: Integer): string;
var
  Lines: TStringList;
  Rows: TSchemeRows;
  LineIdx: Integer;
begin
  Lines := TStringList.Create;
  try
    Lines.Text := AText;
    SetLength(Rows, Lines.Count);
    for LineIdx := 0 to Lines.Count - 1 do
    begin
      Rows[LineIdx].Prefix := '';
      Rows[LineIdx].PrefixFg := clNone;
      Rows[LineIdx].PrefixBg := clNone;
      Rows[LineIdx].Lead := '';
      Rows[LineIdx].Text := Lines[LineIdx];
      Rows[LineIdx].Highlight := True;
      Rows[LineIdx].TextFg := clNone;
      Rows[LineIdx].RowBg := clNone;
      Rows[LineIdx].PadTo := 0;
      Rows[LineIdx].ResetBlock := False;
    end;
  finally
    Lines.Free;
  end;
  Result := RowsToRtfCore(Rows, AScheme, AFontName, AFontPt, AMarkLines,
                          ACurLine, clNone, clNone);
end;

function SchemeRowsToRtf(const ARows: TSchemeRows; AScheme: TClrScheme;
                         const AFontName: string; AFontPt: Integer;
                         ADefFg, ADefBg: TColor): string;
begin
  Result := RowsToRtfCore(ARows, AScheme, AFontName, AFontPt, nil, 0,
                          ADefFg, ADefBg);
end;

end.
