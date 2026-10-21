unit SchemeRtf;

// ---------------------------------------------------------------------------
//  Текст с подсветкой по цветовой схеме (TClrScheme) - одной строкой RTF,
//  для просмотра в TRichEdit: окно загружает её разом, без раскраски по
//  словам через выделение (на файлах в десятки килобайт это медленно).
//
//  Подсвечивается: блочные комментарии (все пары схемы, через строки),
//  строчный комментарий (с уровнями CUSTOM1..5 по числу "!" за маркером),
//  строки (все маркеры схемы, экранирование StrEscape), числа (с &H / 0x,
//  экспонентой и суффиксами - как задано в Digits), ключевые слова (группы
//  схемы, без учёта регистра; слово с "$" на конце - если оно так и есть в
//  группе), операторы (группы Operators). Отметки строк, имена компонентов
//  и пары скобок - нет: это подсветка редактора, а не текста.
//
//  Номера строк RTF совпадают со строками текста: каждая строка - свой \par.
// ---------------------------------------------------------------------------

interface

uses
  SysUtils, Classes, Graphics, ClrScheme;

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

implementation

const
  WordChars = ['A'..'Z', 'a'..'z', '0'..'9', '_'];
  WordStart = ['A'..'Z', 'a'..'z', '_'];
  HexChars = ['0'..'9', 'A'..'F', 'a'..'f'];

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
  Result := clWindow;
  if (AScheme <> nil) and (AScheme.FTextBG <> clNone) then
    Result := AScheme.FTextBG;
end;

function SchemeTextToRtf(const AText: string; AScheme: TClrScheme;
                         const AFontName: string; AFontPt: Integer;
                         AMarkLines: TList; ACurLine: Integer): string;
var
  Body: TRtfBuf;
  Colors: TList;          // RGB цветов таблицы; индекс в \cf = позиция + 1
  Keywords: TStringList;  // слово -> группа (Objects)
  Lines: TStringList;
  TextFg, PageBg: TColor;
  CurFg, CurBg: TColor;   // цвета, которые сейчас действуют в RTF
  InBlock: Integer;       // пара маркеров открытого блочного комментария, -1
  LineMarked: Boolean;    // эта строка - с ошибкой (AMarkLines)
  MarkFg, MarkBg: TColor; // её цвета
  LineCurrent: Boolean;   // строка ACurLine
  CurLineBg: TColor;      // её подложка
  LineIdx, CharPos, LineLen, GroupIdx, WordIdx: Integer;
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

  // Кусок текста цветами AFg / ABg (clNone - цвет текста / фона схемы)
  procedure Emit(const AChunk: string; AFg, ABg: TColor);
  var
    CharIdx: Integer;
    Ch: Char;
  begin
    if AChunk = '' then
      Exit;
    if LineMarked then
    begin
      AFg := MarkFg;
      ABg := MarkBg;
    end;
    if LineCurrent then
      ABg := CurLineBg;
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

  // Маркер AMark в Line с позиции APos (без учёта регистра: REM, //, /')
  function MarkAt(const AMark: string; APos: Integer): Boolean;
  begin
    // Первый знак - без копирования строки: проверка идёт на каждом символе
    Result := (AMark <> '') and (APos + Length(AMark) - 1 <= LineLen) and
              (UpCase(Line[APos]) = UpCase(AMark[1])) and
              ((Length(AMark) = 1) or
               (CompareText(Copy(Line, APos, Length(AMark)), AMark) = 0));
  end;

  // Позиция AMark в Line начиная с APos; 0 - нет
  function FindMark(const AMark: string; APos: Integer): Integer;
  begin
    Result := APos;
    while Result + Length(AMark) - 1 <= LineLen do
    begin
      if MarkAt(AMark, Result) then
        Exit;
      Inc(Result);
    end;
    Result := 0;
  end;

  // Конец блочного комментария: от CharPos до его маркера конца
  // включительно или до конца строки
  procedure EmitBlockTail;
  var
    EndMark: string;
    EndAt: Integer;
    BcFg, BcBg: TColor;
  begin
    EndMark := AScheme.BcEndMark(InBlock);
    AScheme.BcColors(InBlock, BcFg, BcBg);
    EndAt := 0;
    if EndMark <> '' then
      EndAt := FindMark(EndMark, CharPos);
    if EndAt = 0 then
    begin
      Emit(Copy(Line, CharPos, MaxInt), BcFg, BcBg);
      CharPos := LineLen + 1;
    end
    else
    begin
      Emit(Copy(Line, CharPos, EndAt + Length(EndMark) - CharPos), BcFg, BcBg);
      CharPos := EndAt + Length(EndMark);
      InBlock := -1;
    end;
  end;

  function TryBlockComment: Boolean;
  var
    Kind: Integer;
    StartMark: string;
    BcFg, BcBg: TColor;
  begin
    Result := False;
    for Kind := 0 to Length(AScheme.FBcExtra) do
    begin
      StartMark := AScheme.BcStartMark(Kind);
      if MarkAt(StartMark, CharPos) then
      begin
        InBlock := Kind;
        AScheme.BcColors(Kind, BcFg, BcBg);
        // Маркер начала - уже часть комментария
        Emit(StartMark, BcFg, BcBg);
        Inc(CharPos, Length(StartMark));
        EmitBlockTail;
        Result := True;
        Exit;
      end;
    end;
  end;

  function TryLineComment: Boolean;
  var
    Level, BangPos: Integer;
  begin
    Result := MarkAt(AScheme.FLineCommentMarker, CharPos);
    if not Result then
      Exit;
    // Уровень CUSTOM - число "!" сразу за маркером, не больше 5
    Level := 0;
    BangPos := CharPos + Length(AScheme.FLineCommentMarker);
    while (BangPos <= LineLen) and (Line[BangPos] = '!') and (Level < 5) do
    begin
      Inc(Level);
      Inc(BangPos);
    end;
    if Level > 0 then
      Emit(Copy(Line, CharPos, MaxInt), AScheme.FCustomFG[Level],
           AScheme.FCustomBG[Level])
    else
      Emit(Copy(Line, CharPos, MaxInt), AScheme.FLcFG, AScheme.FLcBG);
    CharPos := LineLen + 1;
  end;

  function TryString: Boolean;
  var
    Kind, EndPos: Integer;
    Mark: string;
    StrFg, StrBg: TColor;
  begin
    Result := False;
    for Kind := 0 to Length(AScheme.FStrExtra) do
    begin
      Mark := AScheme.StrMark(Kind);
      if not MarkAt(Mark, CharPos) then
        Continue;
      EndPos := CharPos + Length(Mark);
      while EndPos <= LineLen do
      begin
        if (AScheme.FStrEscape <> #0) and (Line[EndPos] = AScheme.FStrEscape) then
          Inc(EndPos, 2)
        else if MarkAt(Mark, EndPos) then
        begin
          Inc(EndPos, Length(Mark));
          Break;
        end
        else
          Inc(EndPos);
      end;
      if EndPos > LineLen + 1 then
        EndPos := LineLen + 1;
      AScheme.StrColors(Kind, StrFg, StrBg);
      Emit(Copy(Line, CharPos, EndPos - CharPos), StrFg, StrBg);
      CharPos := EndPos;
      Result := True;
      Exit;
    end;
  end;

  function TryNumber: Boolean;
  var
    EndPos: Integer;
  begin
    Result := False;
    if (CharPos > 1) and (Line[CharPos - 1] in WordChars) then
      Exit;
    EndPos := CharPos;
    // &H1F, &O17, &B101
    if AScheme.FNumHexAmp and (Line[CharPos] = '&') and
       (CharPos + 2 <= LineLen) and (UpCase(Line[CharPos + 1]) in ['H', 'O', 'B']) and
       (Line[CharPos + 2] in HexChars) then
    begin
      EndPos := CharPos + 2;
      while (EndPos <= LineLen) and (Line[EndPos] in HexChars) do
        Inc(EndPos);
    end
    // 0x1F
    else if AScheme.FNumHex0x and (Line[CharPos] = '0') and
            (CharPos + 2 <= LineLen) and (Line[CharPos + 1] in ['x', 'X']) and
            (Line[CharPos + 2] in HexChars) then
    begin
      EndPos := CharPos + 2;
      while (EndPos <= LineLen) and (Line[EndPos] in HexChars) do
        Inc(EndPos);
    end
    else if Line[CharPos] in ['0'..'9'] then
    begin
      while (EndPos <= LineLen) and (Line[EndPos] in ['0'..'9', '.']) do
        Inc(EndPos);
      if AScheme.FNumExp and (EndPos <= LineLen) and
         (Line[EndPos] in ['e', 'E']) and (EndPos + 1 <= LineLen) and
         (Line[EndPos + 1] in ['0'..'9', '+', '-']) then
      begin
        Inc(EndPos, 2);
        while (EndPos <= LineLen) and (Line[EndPos] in ['0'..'9']) do
          Inc(EndPos);
      end;
    end
    else
      Exit;
    while (EndPos <= LineLen) and (Line[EndPos] in AScheme.FNumSuffix) do
      Inc(EndPos);
    Emit(Copy(Line, CharPos, EndPos - CharPos), AScheme.FDgFG, AScheme.FDgBG);
    CharPos := EndPos;
    Result := True;
  end;

  function TryWord: Boolean;
  var
    EndPos, FoundIdx: Integer;
    WordText: string;
  begin
    Result := Line[CharPos] in WordStart;
    if not Result then
      Exit;
    EndPos := CharPos;
    while (EndPos <= LineLen) and (Line[EndPos] in WordChars) do
      Inc(EndPos);
    WordText := Copy(Line, CharPos, EndPos - CharPos);
    // chr$, mid$: слово с "$" - если так записано в группе
    if (EndPos <= LineLen) and (Line[EndPos] = '$') and
       Keywords.Find(WordText + '$', FoundIdx) then
    begin
      WordText := WordText + '$';
      Inc(EndPos);
    end
    else if not Keywords.Find(WordText, FoundIdx) then
      FoundIdx := -1;
    if FoundIdx >= 0 then
    begin
      GroupIdx := Integer(Keywords.Objects[FoundIdx]);
      Emit(WordText, AScheme.KeywordGroups[GroupIdx].FgColor,
           AScheme.KeywordGroups[GroupIdx].BgColor);
    end
    else
      Emit(WordText, TextFg, PageBg);
    CharPos := EndPos;
  end;

  function TryOperator: Boolean;
  var
    OpIdx, Found: Integer;
  begin
    // Символ в двух группах - цветом той, что ниже в файле (как в редакторе)
    Found := -1;
    for OpIdx := 0 to High(AScheme.OpGroups) do
      if Line[CharPos] in AScheme.OpGroups[OpIdx].Chars then
        Found := OpIdx;
    Result := Found >= 0;
    if Result then
    begin
      Emit(Line[CharPos], AScheme.OpGroups[Found].FgColor,
           AScheme.OpGroups[Found].BgColor);
      Inc(CharPos);
    end;
  end;

var
  ColorIdx, Rgb: Integer;
  Header: string;
begin
  Body := TRtfBuf.Create;
  Colors := TList.Create;
  Keywords := TStringList.Create;
  Lines := TStringList.Create;
  try
    TextFg := AScheme.FTextFG;
    if (TextFg = clNone) or (TextFg = clDefault) then
      TextFg := clWindowText;
    PageBg := SchemePageColor(AScheme);
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

    Keywords.CaseSensitive := False;
    Keywords.Sorted := True;
    Keywords.Duplicates := dupIgnore;   // слово в двух группах - первая
    for GroupIdx := 0 to High(AScheme.KeywordGroups) do
      if AScheme.KeywordGroups[GroupIdx].Words <> nil then
        for WordIdx := 0 to AScheme.KeywordGroups[GroupIdx].Words.Count - 1 do
          if Trim(AScheme.KeywordGroups[GroupIdx].Words[WordIdx]) <> '' then
            Keywords.AddObject(Trim(AScheme.KeywordGroups[GroupIdx].Words[WordIdx]),
                               TObject(GroupIdx));

    Lines.Text := AText;
    InBlock := -1;
    for LineIdx := 0 to Lines.Count - 1 do
    begin
      Line := Lines[LineIdx];
      LineLen := Length(Line);
      CharPos := 1;
      LineMarked := (AMarkLines <> nil) and
                    (AMarkLines.IndexOf(Pointer(LineIdx + 1)) >= 0);
      LineCurrent := LineIdx + 1 = ACurLine;
      if LineMarked then
        Body.Add('\b ');
      // Пустая выделенная строка - пробел, чтобы подложка была видна
      if (LineMarked or LineCurrent) and (LineLen = 0) then
        Emit(' ', TextFg, PageBg);
      if InBlock >= 0 then
        EmitBlockTail;
      while CharPos <= LineLen do
      begin
        if TryBlockComment or TryLineComment or TryString or TryNumber or
           TryWord or TryOperator then
          Continue;
        Emit(Line[CharPos], TextFg, PageBg);
        Inc(CharPos);
      end;
      if LineMarked then
        Body.Add('\b0 ');
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
    Lines.Free;
    Keywords.Free;
    Colors.Free;
    Body.Free;
  end;
end;

end.
