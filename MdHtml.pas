unit MdHtml;

// ---------------------------------------------------------------------------
//  Markdown -> HTML для просмотра .md в unIDE (см. MdView).
//
//  Модуль без VCL и без Windows: только SysUtils и Classes. Текст на входе
//  - в UTF-8 (перевод из ANSI делает MdView), разметка Markdown вся из
//  ASCII, поэтому разбор идёт по байтам и многобайтовых символов не
//  касается. Байты от $80 и выше считаются буквами - это нужно для правил
//  подчёркивания внутри слов (snake_case, кириллица).
//
//  Что поддержано (CommonMark и расширения GitHub, в той мере, в какой они
//  встречаются в README и заметках):
//    - заголовки # ... ###### и подчёркнутые === / ---;
//    - абзацы, жёсткий перевод строки (два пробела или \ в конце строки);
//    - блоки кода ``` / ~~~ (с языком - класс language-xxx) и с отступом
//      в 4 пробела;
//    - цитаты >, вложенные;
//    - списки маркированные (- * +) и нумерованные (1. 1)), вложенные,
//      плотные и с пустыми строками, задачи [ ] / [x];
//    - таблицы GitHub с выравниванием столбцов (:--, :-:, --:);
//    - горизонтальная черта (---, ***, ___);
//    - блоки HTML (div, table, details...) - как есть;
//    - ссылки [текст](адрес "заголовок"), ссылки по метке [текст][метка] с
//      определениями [метка]: адрес, картинки ![alt](адрес), <адрес>,
//      голые http://, https://, www.;
//    - **полужирный**, *курсив*, ***оба***, __ / _, ~~зачёркнутый~~,
//      `код`, экранирование \*, сущности &amp; &#123;, строчные теги HTML.
//
//  Относительные адреса ссылок и картинок переводятся в абсолютные по
//  ABaseUrl (папка .md как file:///...): страница лежит во временной
//  папке, и иначе картинки рядом с .md не нашлись бы. <base href> для
//  этого не годится: с ним ссылка на метку (#раздел) уводит со страницы.
// ---------------------------------------------------------------------------

interface

uses
  SysUtils, Classes;

type
  // Цвета страницы, строками CSS ('#rrggbb')
  TMdColors = record
    Back: string;      // фон
    Text: string;      // текст
    Link: string;      // ссылки
    Muted: string;     // цитаты, подписи
    Border: string;    // рамки таблиц, линии
    CodeBack: string;  // фон кода
    Dark: Boolean;     // тёмная тема - полосы прокрутки IE в тон
  end;

// Тело страницы (без <html>, <head>)
function MdToHtmlBody(const ASrc, ABaseUrl: string): string;
// Страница целиком: заголовок, стили, тело. Кодировка - UTF-8
function MdToHtmlPage(const ASrc, ATitle, ABaseUrl: string;
  const AColors: TMdColors): string;
// Путь к папке или файлу -> адрес file:///C:/Папка/ (пробел и % - %20,
// %25; разделитель - /). Для папки ADir = True: на конце '/'
function MdFileUrl(const APath: string; ADir: Boolean): string;
// Цвета по умолчанию - светлая тема
function MdDefaultColors: TMdColors;
// Текст для атрибута и для тела HTML: & < > " - сущностями
function MdEscape(const AText: string): string;

implementation

const
  // Метка подстановки в строке разбора: TokOpen + номер + TokClose.
  // В исходном тексте эти байты заменяются пробелом (MdPrepare).
  TokOpen = #1;
  TokClose = #2;
  TabWidth = 4;

type
  TMdConverter = class
  private
    FBaseUrl: string;
    FTokens: TStringList;    // готовый HTML подстановок
    FRefs: TStringList;      // метка (нижний регистр) = адрес #9 заголовок
    FSlugs: TStringList;     // уже выданные id заголовков
    function AddToken(const AHtml: string): string;
    function ExpandTokens(const AText: string): string;
    // Блоки
    function Blocks(ALines: TStrings; ATight: Boolean): string;
    function TryFence(ALines: TStrings; var ALineIdx: Integer;
      var AOut: string): Boolean;
    function TryIndentedCode(ALines: TStrings; var ALineIdx: Integer;
      var AOut: string): Boolean;
    function TryQuote(ALines: TStrings; var ALineIdx: Integer;
      var AOut: string): Boolean;
    function TryList(ALines: TStrings; var ALineIdx: Integer;
      var AOut: string): Boolean;
    function TryTable(ALines: TStrings; var ALineIdx: Integer;
      var AOut: string): Boolean;
    function TryHtmlBlock(ALines: TStrings; var ALineIdx: Integer;
      var AOut: string): Boolean;
    function Heading(ALevel: Integer; const AText: string): string;
    function Paragraph(const AText: string; ATight: Boolean): string;
    // Строка
    function InlineHtml(const AText: string): string;
    function ScanInline(const AText: string): string;
    function Emphasis(const AText: string): string;
    function TryLink(const AText: string; var APos: Integer;
      AImage: Boolean; var AOut: string): Boolean;
    function TryAngle(const AText: string; var APos: Integer;
      var AOut: string): Boolean;
    function TryBareUrl(const AText: string; var APos: Integer;
      var AOut: string): Boolean;
    function ResolveUrl(const AUrl: string): string;
    function ResolveRawHtml(const AHtml: string): string;
    procedure CollectRefs(ALines: TStrings);
  public
    constructor Create(const ABaseUrl: string);
    destructor Destroy; override;
    function Convert(const ASrc: string): string;
  end;

// ---------------------------------------------------------------------------
//  Мелочи
// ---------------------------------------------------------------------------

function IsSpaceChar(AChar: Char): Boolean;
begin
  Result := (AChar = ' ') or (AChar = #9) or (AChar = #10) or (AChar = #13);
end;

// Буква или цифра; байты UTF-8 (от $80) - тоже буквы
function IsWordChar(AChar: Char): Boolean;
begin
  Result := (AChar in ['A'..'Z', 'a'..'z', '0'..'9']) or (Ord(AChar) >= $80);
end;

function IsAsciiPunct(AChar: Char): Boolean;
begin
  Result := AChar in ['!'..'/', ':'..'@', '['..'`', '{'..'~'];
end;

function MdEscape(const AText: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(AText) do
    case AText[I] of
      '&': Result := Result + '&amp;';
      '<': Result := Result + '&lt;';
      '>': Result := Result + '&gt;';
      '"': Result := Result + '&quot;';
    else
      Result := Result + AText[I];
    end;
end;

// Число пробелов в начале строки (табуляции к этому времени развёрнуты)
function IndentOf(const ALine: string): Integer;
begin
  Result := 0;
  while (Result < Length(ALine)) and (ALine[Result + 1] = ' ') do
    Inc(Result);
end;

function IsBlank(const ALine: string): Boolean;
begin
  Result := Trim(ALine) = '';
end;

// Убрать до ACount пробелов слева
function DropIndent(const ALine: string; ACount: Integer): string;
var
  Cut: Integer;
begin
  Cut := IndentOf(ALine);
  if Cut > ACount then
    Cut := ACount;
  Result := Copy(ALine, Cut + 1, MaxInt);
end;

// Табуляции -> пробелы до ближайшей кратной TabWidth позиции
function ExpandTabs(const ALine: string): string;
var
  I, Col: Integer;
begin
  if Pos(#9, ALine) = 0 then
  begin
    Result := ALine;
    Exit;
  end;
  Result := '';
  Col := 0;
  for I := 1 to Length(ALine) do
    if ALine[I] = #9 then
    begin
      repeat
        Result := Result + ' ';
        Inc(Col);
      until Col mod TabWidth = 0;
    end
    else
    begin
      Result := Result + ALine[I];
      Inc(Col);
    end;
end;

function RepeatChar(AChar: Char; ACount: Integer): string;
begin
  Result := StringOfChar(AChar, ACount);
end;

// Заголовок ATX: '#' x уровень, затем пробел или конец строки
function AtxLevel(const ALine: string; out AText: string): Integer;
var
  Body: string;
  Level, Cut: Integer;
begin
  Result := 0;
  if IndentOf(ALine) > 3 then
    Exit;
  Body := TrimLeft(ALine);
  Level := 0;
  while (Level < Length(Body)) and (Body[Level + 1] = '#') do
    Inc(Level);
  if (Level < 1) or (Level > 6) then
    Exit;
  if (Length(Body) > Level) and not IsSpaceChar(Body[Level + 1]) then
    Exit;
  Body := Trim(Copy(Body, Level + 1, MaxInt));
  // Закрывающие # (перед ними пробел) - не текст
  Cut := Length(Body);
  while (Cut > 0) and (Body[Cut] = '#') do
    Dec(Cut);
  if (Cut = 0) or (Body[Cut] = ' ') then
    Body := TrimRight(Copy(Body, 1, Cut));
  AText := Body;
  Result := Level;
end;

// --- / *** / ___ (три и больше, пробелы между ними можно)
function IsRule(const ALine: string): Boolean;
var
  Body: string;
  I, Count: Integer;
  Mark: Char;
begin
  Result := False;
  if IndentOf(ALine) > 3 then
    Exit;
  Body := Trim(ALine);
  if Body = '' then
    Exit;
  Mark := Body[1];
  if not (Mark in ['-', '*', '_']) then
    Exit;
  Count := 0;
  for I := 1 to Length(Body) do
    if Body[I] = Mark then
      Inc(Count)
    else if Body[I] <> ' ' then
      Exit;
  Result := Count >= 3;
end;

// Подчёркивание заголовка: 1 - ===, 2 - ---, 0 - нет
function SetextLevel(const ALine: string): Integer;
var
  Body: string;
  I: Integer;
begin
  Result := 0;
  if IndentOf(ALine) > 3 then
    Exit;
  Body := Trim(ALine);
  if Body = '' then
    Exit;
  for I := 1 to Length(Body) do
    if Body[I] <> Body[1] then
      Exit;
  if Body[1] = '=' then
    Result := 1
  else if Body[1] = '-' then
    Result := 2;
end;

// Маркер списка в начале строки.
// AIndent - отступ маркера, AContentCol - с какого столбца (с 0) идёт текст
// пункта, AOrdered и AStart - нумерованный и его номер, AMark - знак
// маркера ('-', '*', '+', '.', ')').
function ListMarker(const ALine: string; out AIndent, AContentCol: Integer;
  out AOrdered: Boolean; out AStart: Integer; out AMark: Char): Boolean;
var
  Idx, DigitEnd, Spaces: Integer;
begin
  Result := False;
  AIndent := IndentOf(ALine);
  AOrdered := False;
  AStart := 1;
  AMark := ' ';
  AContentCol := 0;
  Idx := AIndent + 1;
  if Idx > Length(ALine) then
    Exit;
  if ALine[Idx] in ['-', '*', '+'] then
  begin
    AMark := ALine[Idx];
    Inc(Idx);
  end
  else if ALine[Idx] in ['0'..'9'] then
  begin
    DigitEnd := Idx;
    while (DigitEnd <= Length(ALine)) and (ALine[DigitEnd] in ['0'..'9']) do
      Inc(DigitEnd);
    if (DigitEnd - Idx > 9) or (DigitEnd > Length(ALine)) or
       not (ALine[DigitEnd] in ['.', ')']) then
      Exit;
    AOrdered := True;
    AStart := StrToIntDef(Copy(ALine, Idx, DigitEnd - Idx), 1);
    AMark := ALine[DigitEnd];
    Idx := DigitEnd + 1;
  end
  else
    Exit;

  // После маркера - пробел или конец строки
  if Idx > Length(ALine) then
  begin
    AContentCol := Idx;  // пустой пункт
    Result := True;
    Exit;
  end;
  if ALine[Idx] <> ' ' then
    Exit;
  Spaces := 0;
  while (Idx + Spaces <= Length(ALine)) and (ALine[Idx + Spaces] = ' ') do
    Inc(Spaces);
  // Больше 4 пробелов - это код внутри пункта, текст с одного пробела
  if (Spaces > 4) or (Idx + Spaces > Length(ALine)) then
    Spaces := 1;
  AContentCol := Idx - 1 + Spaces;
  Result := True;
end;

// Строка - начало блока кода ```/~~~ (отступ до 3)
function FenceOpen(const ALine: string; out AFenceChar: Char;
  out AFenceLen: Integer; out AInfo: string): Boolean;
var
  Body: string;
begin
  Result := False;
  AFenceLen := 0;
  AFenceChar := ' ';
  AInfo := '';
  if IndentOf(ALine) > 3 then
    Exit;
  Body := TrimLeft(ALine);
  if (Body = '') or not (Body[1] in ['`', '~']) then
    Exit;
  AFenceChar := Body[1];
  while (AFenceLen < Length(Body)) and (Body[AFenceLen + 1] = AFenceChar) do
    Inc(AFenceLen);
  if AFenceLen < 3 then
    Exit;
  AInfo := Trim(Copy(Body, AFenceLen + 1, MaxInt));
  // У ``` в строке описания обратных кавычек быть не может
  if (AFenceChar = '`') and (Pos('`', AInfo) > 0) then
    Exit;
  Result := True;
end;

// Строка начинает блок HTML: открывающий или закрывающий тег из списка
// блочных, или комментарий
function HtmlBlockStart(const ALine: string): Boolean;
const
  BlockTags: array[0..33] of string = (
    'address', 'article', 'aside', 'blockquote', 'center', 'dd', 'details',
    'dialog', 'div', 'dl', 'dt', 'fieldset', 'figure', 'footer', 'form',
    'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'header', 'hr', 'li', 'nav', 'ol',
    'p', 'pre', 'section', 'summary', 'table', 'ul', 'style', 'script');
var
  Body, TagName: string;
  Idx, TagIdx: Integer;
begin
  Result := False;
  if IndentOf(ALine) > 3 then
    Exit;
  Body := TrimLeft(ALine);
  if (Length(Body) < 2) or (Body[1] <> '<') then
    Exit;
  if Copy(Body, 1, 4) = '<!--' then
  begin
    Result := True;
    Exit;
  end;
  Idx := 2;
  if Body[Idx] = '/' then
    Inc(Idx);
  TagName := '';
  while (Idx <= Length(Body)) and (Body[Idx] in ['A'..'Z', 'a'..'z', '0'..'9']) do
  begin
    TagName := TagName + Body[Idx];
    Inc(Idx);
  end;
  if TagName = '' then
    Exit;
  if (Idx <= Length(Body)) and not (Body[Idx] in [' ', '>', '/']) then
    Exit;
  TagName := LowerCase(TagName);
  for TagIdx := Low(BlockTags) to High(BlockTags) do
    if BlockTags[TagIdx] = TagName then
    begin
      Result := True;
      Exit;
    end;
end;

// Ячейки строки таблицы: разделитель | вне `кода` и не после \
procedure SplitRow(const ALine: string; ACells: TStrings);
var
  Body, Cell: string;
  Idx, TickRun, CloseRun: Integer;
  InCode: Boolean;
begin
  ACells.Clear;
  Body := Trim(ALine);
  if (Body <> '') and (Body[1] = '|') then
    Delete(Body, 1, 1);
  if (Body <> '') and (Body[Length(Body)] = '|') and
     ((Length(Body) < 2) or (Body[Length(Body) - 1] <> '\')) then
    Delete(Body, Length(Body), 1);
  Cell := '';
  InCode := False;
  TickRun := 0;
  Idx := 1;
  while Idx <= Length(Body) do
  begin
    if (Body[Idx] = '\') and (Idx < Length(Body)) and (Body[Idx + 1] = '|') then
    begin
      // \| в ячейке - сама черта
      Cell := Cell + '|';
      Inc(Idx, 2);
      Continue;
    end;
    if Body[Idx] = '`' then
    begin
      CloseRun := 0;
      while (Idx + CloseRun <= Length(Body)) and (Body[Idx + CloseRun] = '`') do
        Inc(CloseRun);
      if not InCode then
      begin
        InCode := True;
        TickRun := CloseRun;
      end
      else if CloseRun = TickRun then
        InCode := False;
      Cell := Cell + Copy(Body, Idx, CloseRun);
      Inc(Idx, CloseRun);
      Continue;
    end;
    if (Body[Idx] = '|') and not InCode then
    begin
      ACells.Add(Trim(Cell));
      Cell := '';
    end
    else
      Cell := Cell + Body[Idx];
    Inc(Idx);
  end;
  ACells.Add(Trim(Cell));
end;

// Строка-разделитель таблицы: |---|:--:|--:| ; в AAligns - 'l', 'c', 'r'
// или ' ' на столбец
function IsTableSeparator(const ALine: string; AAligns: TStrings): Boolean;
var
  Cells: TStringList;
  CellIdx, CharIdx: Integer;
  Cell: string;
  Left, Right: Boolean;
begin
  Result := False;
  AAligns.Clear;
  if (Pos('-', ALine) = 0) or (IndentOf(ALine) > 3) then
    Exit;
  // Без | это подчёркивание заголовка или черта, а не таблица
  if Pos('|', ALine) = 0 then
    Exit;
  Cells := TStringList.Create;
  try
    SplitRow(ALine, Cells);
    for CellIdx := 0 to Cells.Count - 1 do
    begin
      Cell := Cells[CellIdx];
      if Cell = '' then
        Exit;
      Left := Cell[1] = ':';
      Right := Cell[Length(Cell)] = ':';
      for CharIdx := 1 to Length(Cell) do
        if not (Cell[CharIdx] in ['-', ':']) then
          Exit;
      if Pos('-', Cell) = 0 then
        Exit;
      if Left and Right then
        AAligns.Add('c')
      else if Right then
        AAligns.Add('r')
      else if Left then
        AAligns.Add('l')
      else
        AAligns.Add(' ');
    end;
    Result := AAligns.Count > 0;
  finally
    Cells.Free;
  end;
end;

// Текст без разметки - для alt картинки и id заголовка
function StripTags(const AHtml: string): string;
var
  Idx: Integer;
  InTag: Boolean;
begin
  Result := '';
  InTag := False;
  for Idx := 1 to Length(AHtml) do
    if AHtml[Idx] = '<' then
      InTag := True
    else if AHtml[Idx] = '>' then
      InTag := False
    else if not InTag then
      Result := Result + AHtml[Idx];
end;

// id заголовка как у GitHub: нижний регистр (ASCII), пробелы -> '-',
// знаки препинания убираются, байты UTF-8 остаются
function SlugOf(const AText: string): string;
var
  Idx: Integer;
  Ch: Char;
begin
  Result := '';
  for Idx := 1 to Length(AText) do
  begin
    Ch := AText[Idx];
    if Ch in ['A'..'Z'] then
      Result := Result + Chr(Ord(Ch) + 32)
    else if (Ch in ['a'..'z', '0'..'9', '-', '_']) or (Ord(Ch) >= $80) then
      Result := Result + Ch
    else if Ch = ' ' then
      Result := Result + '-';
  end;
end;

// Сущности &amp; &lt; ... обратно в символы - для id из уже готового HTML
function UnescapeBasic(const AText: string): string;
begin
  Result := StringReplace(AText, '&lt;', '<', [rfReplaceAll]);
  Result := StringReplace(Result, '&gt;', '>', [rfReplaceAll]);
  Result := StringReplace(Result, '&quot;', '"', [rfReplaceAll]);
  Result := StringReplace(Result, '&amp;', '&', [rfReplaceAll]);
end;

function MdFileUrl(const APath: string; ADir: Boolean): string;
var
  Idx: Integer;
  Ch: Char;
begin
  Result := '';
  for Idx := 1 to Length(APath) do
  begin
    Ch := APath[Idx];
    case Ch of
      '\': Result := Result + '/';
      ' ': Result := Result + '%20';
      '%': Result := Result + '%25';
      '#': Result := Result + '%23';
    else
      Result := Result + Ch;
    end;
  end;
  if ADir and (Result <> '') and (Result[Length(Result)] <> '/') then
    Result := Result + '/';
  if Copy(Result, 1, 2) = '//' then
    Result := 'file:' + Result          // \\сервер\папка
  else
    Result := 'file:///' + Result;
end;

function MdDefaultColors: TMdColors;
begin
  Result.Back := '#ffffff';
  Result.Text := '#1f2328';
  Result.Link := '#0b5cad';
  Result.Muted := '#59636e';
  Result.Border := '#d1d9e0';
  Result.CodeBack := '#f3f4f6';
  Result.Dark := False;
end;

// ---------------------------------------------------------------------------
//  TMdConverter
// ---------------------------------------------------------------------------

constructor TMdConverter.Create(const ABaseUrl: string);
begin
  inherited Create;
  FBaseUrl := ABaseUrl;
  FTokens := TStringList.Create;
  FRefs := TStringList.Create;
  FSlugs := TStringList.Create;
end;

destructor TMdConverter.Destroy;
begin
  FSlugs.Free;
  FRefs.Free;
  FTokens.Free;
  inherited Destroy;
end;

function TMdConverter.AddToken(const AHtml: string): string;
begin
  Result := TokOpen + IntToStr(FTokens.Add(AHtml)) + TokClose;
end;

function TMdConverter.ExpandTokens(const AText: string): string;
var
  Idx, CloseIdx, TokIdx: Integer;
begin
  Result := '';
  Idx := 1;
  while Idx <= Length(AText) do
  begin
    if AText[Idx] = TokOpen then
    begin
      CloseIdx := Idx + 1;
      while (CloseIdx <= Length(AText)) and (AText[CloseIdx] <> TokClose) do
        Inc(CloseIdx);
      TokIdx := StrToIntDef(Copy(AText, Idx + 1, CloseIdx - Idx - 1), -1);
      if (TokIdx >= 0) and (TokIdx < FTokens.Count) then
        Result := Result + FTokens[TokIdx];
      Idx := CloseIdx + 1;
    end
    else
    begin
      Result := Result + AText[Idx];
      Inc(Idx);
    end;
  end;
end;

// Адрес из текста: относительный - от папки .md; метка (#...), схема
// (http:, mailto: ...) и путь от корня диска - как есть
function TMdConverter.ResolveUrl(const AUrl: string): string;
var
  Idx: Integer;
  HasScheme: Boolean;
begin
  Result := AUrl;
  if (AUrl = '') or (AUrl[1] = '#') or (FBaseUrl = '') then
    Exit;
  // Схема: буквы, затем ':' (C:\ - тоже "схема", это путь от диска)
  HasScheme := False;
  Idx := 1;
  while (Idx <= Length(AUrl)) and
        (AUrl[Idx] in ['A'..'Z', 'a'..'z', '0'..'9', '+', '-', '.']) do
    Inc(Idx);
  if (Idx > 1) and (Idx <= Length(AUrl)) and (AUrl[Idx] = ':') then
    HasScheme := True;
  if HasScheme then
  begin
    if Idx = 2 then  // C:\... или C:/...
      Result := MdFileUrl(AUrl, False);
    Exit;
  end;
  if (AUrl[1] = '/') or (AUrl[1] = '\') then
    Exit;
  Result := FBaseUrl + StringReplace(StringReplace(AUrl, '\', '/',
    [rfReplaceAll]), ' ', '%20', [rfReplaceAll]);
end;

// src="..." и href="..." в HTML из текста .md - через ResolveUrl
// (<img src="icons/logo.png"> в README)
function TMdConverter.ResolveRawHtml(const AHtml: string): string;
var
  Lower: string;
  Idx, AttrLen, ValStart, ValEnd: Integer;
  Quote: Char;
begin
  Result := '';
  Lower := LowerCase(AHtml);
  Idx := 1;
  while Idx <= Length(AHtml) do
  begin
    AttrLen := 0;
    if (Copy(Lower, Idx, 5) = 'src="') or (Copy(Lower, Idx, 5) = 'src=''') then
      AttrLen := 4
    else if (Copy(Lower, Idx, 6) = 'href="') or
            (Copy(Lower, Idx, 6) = 'href=''') then
      AttrLen := 5;
    if (AttrLen > 0) and (Idx > 1) and IsSpaceChar(AHtml[Idx - 1]) then
    begin
      Quote := AHtml[Idx + AttrLen];
      ValStart := Idx + AttrLen + 1;
      ValEnd := ValStart;
      while (ValEnd <= Length(AHtml)) and (AHtml[ValEnd] <> Quote) do
        Inc(ValEnd);
      Result := Result + Copy(AHtml, Idx, AttrLen + 1) +
        ResolveUrl(Copy(AHtml, ValStart, ValEnd - ValStart));
      Idx := ValEnd;
      Continue;
    end;
    Result := Result + AHtml[Idx];
    Inc(Idx);
  end;
end;

// Определения ссылок [метка]: адрес "заголовок" - собрать и убрать из
// текста. Внутри блоков ``` не трогаются.
procedure TMdConverter.CollectRefs(ALines: TStrings);
var
  LineIdx, CloseIdx, Idx: Integer;
  Line, Body, Name, Url, Title: string;
  InFence: Boolean;
  FenceChar, OtherChar: Char;
  FenceLen, OtherLen: Integer;
  Info: string;
begin
  InFence := False;
  FenceChar := ' ';
  FenceLen := 0;
  LineIdx := 0;
  while LineIdx < ALines.Count do
  begin
    Line := ALines[LineIdx];
    if FenceOpen(Line, OtherChar, OtherLen, Info) then
    begin
      if not InFence then
      begin
        InFence := True;
        FenceChar := OtherChar;
        FenceLen := OtherLen;
      end
      else if (OtherChar = FenceChar) and (OtherLen >= FenceLen) and
              (Info = '') then
        InFence := False;
      Inc(LineIdx);
      Continue;
    end;
    if InFence or (IndentOf(Line) > 3) then
    begin
      Inc(LineIdx);
      Continue;
    end;
    Body := Trim(Line);
    CloseIdx := Pos(']:', Body);
    if (Body <> '') and (Body[1] = '[') and (CloseIdx > 2) and
       (Copy(Body, 2, 1) <> '^') then
    begin
      Name := LowerCase(Trim(Copy(Body, 2, CloseIdx - 2)));
      Body := Trim(Copy(Body, CloseIdx + 2, MaxInt));
      if (Name <> '') and (Pos(']', Name) = 0) and (Body <> '') then
      begin
        // Адрес: <...> или до пробела
        if Body[1] = '<' then
        begin
          Idx := Pos('>', Body);
          if Idx = 0 then
            Idx := Length(Body) + 1;
          Url := Copy(Body, 2, Idx - 2);
          Body := Trim(Copy(Body, Idx + 1, MaxInt));
        end
        else
        begin
          Idx := 1;
          while (Idx <= Length(Body)) and not IsSpaceChar(Body[Idx]) do
            Inc(Idx);
          Url := Copy(Body, 1, Idx - 1);
          Body := Trim(Copy(Body, Idx, MaxInt));
        end;
        Title := '';
        if (Length(Body) >= 2) and (Body[1] in ['"', '''', '(']) then
          Title := Copy(Body, 2, Length(Body) - 2)
        else if Body <> '' then
        begin
          // После адреса что-то ещё - это не определение
          Inc(LineIdx);
          Continue;
        end;
        if FRefs.IndexOfName(Name) < 0 then
          FRefs.Add(Name + '=' + Url + #9 + Title);
        ALines.Delete(LineIdx);
        Continue;
      end;
    end;
    Inc(LineIdx);
  end;
end;

function TMdConverter.Convert(const ASrc: string): string;
var
  Lines: TStringList;
  Text: string;
  LineIdx: Integer;
begin
  // Переводы строк -> LF, служебные байты меток -> пробел
  Text := StringReplace(ASrc, #13#10, #10, [rfReplaceAll]);
  Text := StringReplace(Text, #13, #10, [rfReplaceAll]);
  Text := StringReplace(Text, TokOpen, ' ', [rfReplaceAll]);
  Text := StringReplace(Text, TokClose, ' ', [rfReplaceAll]);
  // BOM UTF-8
  if Copy(Text, 1, 3) = #$EF#$BB#$BF then
    Delete(Text, 1, 3);
  Lines := TStringList.Create;
  try
    Lines.Text := StringReplace(Text, #10, #13#10, [rfReplaceAll]);
    for LineIdx := 0 to Lines.Count - 1 do
      Lines[LineIdx] := ExpandTabs(Lines[LineIdx]);
    CollectRefs(Lines);
    Result := Blocks(Lines, False);
  finally
    Lines.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  Блоки
// ---------------------------------------------------------------------------

function TMdConverter.Heading(ALevel: Integer; const AText: string): string;
var
  Inner, Slug, Base: string;
  Suffix: Integer;
begin
  Inner := InlineHtml(AText);
  Base := SlugOf(UnescapeBasic(StripTags(Inner)));
  Slug := Base;
  Suffix := 0;
  while FSlugs.IndexOf(Slug) >= 0 do
  begin
    Inc(Suffix);
    Slug := Base + '-' + IntToStr(Suffix);
  end;
  FSlugs.Add(Slug);
  Result := '<h' + IntToStr(ALevel) + ' id="' + MdEscape(Slug) + '">' +
    Inner + '</h' + IntToStr(ALevel) + '>'#10;
end;

function TMdConverter.Paragraph(const AText: string; ATight: Boolean): string;
var
  Body: string;
begin
  Body := InlineHtml(AText);
  if ATight then
    Result := Body + #10
  else
    Result := '<p>' + Body + '</p>'#10;
end;

function TMdConverter.Blocks(ALines: TStrings; ATight: Boolean): string;
var
  LineIdx, Level: Integer;
  Line, Para, Text: string;
  BlockHtml: string;

  procedure FlushPara;
  begin
    if Para <> '' then
      Result := Result + Paragraph(Para, ATight);
    Para := '';
  end;

begin
  Result := '';
  Para := '';
  LineIdx := 0;
  while LineIdx < ALines.Count do
  begin
    Line := ALines[LineIdx];

    if IsBlank(Line) then
    begin
      FlushPara;
      Inc(LineIdx);
      Continue;
    end;

    // Подчёркнутый заголовок: строка === или --- сразу под абзацем
    if Para <> '' then
    begin
      Level := SetextLevel(Line);
      if Level > 0 then
      begin
        Result := Result + Heading(Level, Para);
        Para := '';
        Inc(LineIdx);
        Continue;
      end;
    end;

    // Блоки, которые могут прервать абзац
    BlockHtml := '';
    if TryFence(ALines, LineIdx, BlockHtml) or
       TryTable(ALines, LineIdx, BlockHtml) or
       TryQuote(ALines, LineIdx, BlockHtml) or
       TryHtmlBlock(ALines, LineIdx, BlockHtml) then
    begin
      FlushPara;
      Result := Result + BlockHtml;
      Continue;
    end;

    Level := AtxLevel(Line, Text);
    if Level > 0 then
    begin
      FlushPara;
      Result := Result + Heading(Level, Text);
      Inc(LineIdx);
      Continue;
    end;

    if IsRule(Line) then
    begin
      FlushPara;
      Result := Result + '<hr>'#10;
      Inc(LineIdx);
      Continue;
    end;

    if TryList(ALines, LineIdx, BlockHtml) then
    begin
      FlushPara;
      Result := Result + BlockHtml;
      Continue;
    end;

    // Код с отступом не прерывает абзац: такая строка - его продолжение
    if (Para = '') and TryIndentedCode(ALines, LineIdx, BlockHtml) then
    begin
      Result := Result + BlockHtml;
      Continue;
    end;

    if Para = '' then
      Para := TrimLeft(Line)
    else
      Para := Para + #10 + TrimLeft(Line);
    Inc(LineIdx);
  end;
  FlushPara;
end;

function TMdConverter.TryFence(ALines: TStrings; var ALineIdx: Integer;
  var AOut: string): Boolean;
var
  FenceChar, CloseChar: Char;
  FenceLen, CloseLen, Indent, LineIdx: Integer;
  Info, CloseInfo, Code, Lang: string;
  SpaceAt: Integer;
begin
  Result := FenceOpen(ALines[ALineIdx], FenceChar, FenceLen, Info);
  if not Result then
    Exit;
  Indent := IndentOf(ALines[ALineIdx]);
  Code := '';
  LineIdx := ALineIdx + 1;
  while LineIdx < ALines.Count do
  begin
    if FenceOpen(ALines[LineIdx], CloseChar, CloseLen, CloseInfo) and
       (CloseChar = FenceChar) and (CloseLen >= FenceLen) and
       (CloseInfo = '') then
      Break;
    Code := Code + DropIndent(ALines[LineIdx], Indent) + #10;
    Inc(LineIdx);
  end;
  // Закрывающей строки нет - блок до конца текста
  ALineIdx := LineIdx + 1;
  Lang := Info;
  SpaceAt := Pos(' ', Lang);
  if SpaceAt > 0 then
    Lang := Copy(Lang, 1, SpaceAt - 1);
  if Lang <> '' then
    AOut := '<pre><code class="language-' + MdEscape(Lang) + '">'
  else
    AOut := '<pre><code>';
  AOut := AOut + MdEscape(Code) + '</code></pre>'#10;
end;

function TMdConverter.TryIndentedCode(ALines: TStrings; var ALineIdx: Integer;
  var AOut: string): Boolean;
var
  LineIdx, LastCode: Integer;
  Code: string;
begin
  Result := IndentOf(ALines[ALineIdx]) >= 4;
  if not Result then
    Exit;
  // Пустые строки внутри - часть кода, если за ними снова строка с отступом
  LineIdx := ALineIdx;
  LastCode := ALineIdx;
  while LineIdx < ALines.Count do
  begin
    if IsBlank(ALines[LineIdx]) then
    begin
      Inc(LineIdx);
      Continue;
    end;
    if IndentOf(ALines[LineIdx]) < 4 then
      Break;
    LastCode := LineIdx;
    Inc(LineIdx);
  end;
  Code := '';
  for LineIdx := ALineIdx to LastCode do
    Code := Code + DropIndent(ALines[LineIdx], 4) + #10;
  ALineIdx := LastCode + 1;
  AOut := '<pre><code>' + MdEscape(Code) + '</code></pre>'#10;
end;

function TMdConverter.TryQuote(ALines: TStrings; var ALineIdx: Integer;
  var AOut: string): Boolean;
var
  Inner: TStringList;
  Line, Body: string;
  LineIdx: Integer;
begin
  Line := ALines[ALineIdx];
  Result := (IndentOf(Line) <= 3) and (Copy(TrimLeft(Line), 1, 1) = '>');
  if not Result then
    Exit;
  Inner := TStringList.Create;
  try
    LineIdx := ALineIdx;
    while LineIdx < ALines.Count do
    begin
      Line := ALines[LineIdx];
      if IsBlank(Line) then
        Break;
      Body := TrimLeft(Line);
      if (IndentOf(Line) <= 3) and (Copy(Body, 1, 1) = '>') then
      begin
        Delete(Body, 1, 1);
        if Copy(Body, 1, 1) = ' ' then
          Delete(Body, 1, 1);
        Inner.Add(Body);
      end
      else
        // Строка без > сразу за строкой цитаты - её продолжение
        Inner.Add(Line);
      Inc(LineIdx);
    end;
    ALineIdx := LineIdx;
    AOut := '<blockquote>'#10 + Blocks(Inner, False) + '</blockquote>'#10;
  finally
    Inner.Free;
  end;
end;

function TMdConverter.TryHtmlBlock(ALines: TStrings; var ALineIdx: Integer;
  var AOut: string): Boolean;
var
  LineIdx: Integer;
begin
  Result := HtmlBlockStart(ALines[ALineIdx]);
  if not Result then
    Exit;
  AOut := '';
  LineIdx := ALineIdx;
  while (LineIdx < ALines.Count) and not IsBlank(ALines[LineIdx]) do
  begin
    AOut := AOut + ALines[LineIdx] + #10;
    Inc(LineIdx);
  end;
  AOut := ResolveRawHtml(AOut);
  ALineIdx := LineIdx;
end;

function TMdConverter.TryTable(ALines: TStrings; var ALineIdx: Integer;
  var AOut: string): Boolean;
var
  Aligns, Cells: TStringList;
  LineIdx, CellIdx: Integer;
  Line, Attr: string;

  function AlignAttr(AColumn: Integer): string;
  begin
    Result := '';
    if AColumn < Aligns.Count then
      case Aligns[AColumn][1] of
        'l': Result := ' style="text-align:left"';
        'c': Result := ' style="text-align:center"';
        'r': Result := ' style="text-align:right"';
      end;
  end;

begin
  Result := False;
  Line := ALines[ALineIdx];
  if (Pos('|', Line) = 0) or (ALineIdx + 1 >= ALines.Count) or
     (IndentOf(Line) > 3) then
    Exit;
  Aligns := TStringList.Create;
  Cells := TStringList.Create;
  try
    if not IsTableSeparator(ALines[ALineIdx + 1], Aligns) then
      Exit;
    SplitRow(Line, Cells);
    if Cells.Count <> Aligns.Count then
      Exit;
    Result := True;

    AOut := '<table>'#10'<thead><tr>';
    for CellIdx := 0 to Cells.Count - 1 do
      AOut := AOut + '<th' + AlignAttr(CellIdx) + '>' +
        InlineHtml(Cells[CellIdx]) + '</th>';
    AOut := AOut + '</tr></thead>'#10'<tbody>'#10;

    LineIdx := ALineIdx + 2;
    while LineIdx < ALines.Count do
    begin
      Line := ALines[LineIdx];
      if IsBlank(Line) or (Pos('|', Line) = 0) then
        Break;
      SplitRow(Line, Cells);
      AOut := AOut + '<tr>';
      // Ячеек меньше, чем столбцов - пустые; больше - лишние отбрасываются
      for CellIdx := 0 to Aligns.Count - 1 do
      begin
        Attr := AlignAttr(CellIdx);
        if CellIdx < Cells.Count then
          AOut := AOut + '<td' + Attr + '>' + InlineHtml(Cells[CellIdx]) +
            '</td>'
        else
          AOut := AOut + '<td' + Attr + '></td>';
      end;
      AOut := AOut + '</tr>'#10;
      Inc(LineIdx);
    end;
    AOut := AOut + '</tbody>'#10'</table>'#10;
    ALineIdx := LineIdx;
  finally
    Cells.Free;
    Aligns.Free;
  end;
end;

// Список: пункты одного вида (маркированные или нумерованные с одним
// знаком) на отступе меньше столбца текста пункта. Строки пункта - со
// сдвигом на столбец текста, разбираются как блоки заново (вложенные
// списки, код, цитаты). Пустая строка между пунктами делает список
// "свободным": текст пунктов в <p>.
function TMdConverter.TryList(ALines: TStrings; var ALineIdx: Integer;
  var AOut: string): Boolean;
var
  Indent, ContentCol, Start, LineIdx, ItemIdx: Integer;
  Ordered, Loose, PendingBlank: Boolean;
  Mark: Char;
  SubIndent, SubCol, SubStart: Integer;
  SubOrdered: Boolean;
  SubMark: Char;
  Items: TList;
  Item: TStringList;
  Line, First, Body, Check: string;
  OtherIdx: Integer;
  HtmlText: string;
  OtherText: string;
begin
  Result := ListMarker(ALines[ALineIdx], Indent, ContentCol, Ordered, Start,
    Mark);
  if not Result then
    Exit;
  // "* * *" и "- - -" - черта, а не список
  if IsRule(ALines[ALineIdx]) then
  begin
    Result := False;
    Exit;
  end;

  Items := TList.Create;
  try
    Loose := False;
    PendingBlank := False;
    Item := nil;
    LineIdx := ALineIdx;
    while LineIdx < ALines.Count do
    begin
      Line := ALines[LineIdx];

      if IsBlank(Line) then
      begin
        PendingBlank := True;
        if Item <> nil then
          Item.Add('');
        Inc(LineIdx);
        Continue;
      end;

      // Новый пункт этого же списка
      if ListMarker(Line, SubIndent, SubCol, SubOrdered, SubStart, SubMark) and
         (SubIndent < ContentCol) and not IsRule(Line) then
      begin
        if (SubOrdered <> Ordered) or (SubMark <> Mark) then
          Break;   // другой вид маркера - другой список
        if (Item <> nil) and PendingBlank then
          Loose := True;
        PendingBlank := False;
        Item := TStringList.Create;
        Items.Add(Item);
        ContentCol := SubCol;
        Item.Add(Copy(Line, SubCol + 1, MaxInt));
        Inc(LineIdx);
        Continue;
      end;

      if IndentOf(Line) >= ContentCol then
      begin
        // Продолжение пункта с отступом (в том числе вложенный список)
        if Item <> nil then
          Item.Add(Copy(Line, ContentCol + 1, MaxInt));
        PendingBlank := False;
        Inc(LineIdx);
        Continue;
      end;

      // Строка без отступа: после пустой строки - конец списка; сразу за
      // текстом пункта - его продолжение (если не начало другого блока)
      if PendingBlank then
        Break;
      if (AtxLevel(Line, OtherText) > 0) or IsRule(Line) or
         (Copy(TrimLeft(Line), 1, 1) = '>') or
         FenceOpen(Line, SubMark, SubIndent, OtherText) or
         HtmlBlockStart(Line) then
        Break;
      if Item <> nil then
        Item.Add(TrimLeft(Line));
      Inc(LineIdx);
    end;

    // Пустые строки в конце пунктов не считаются
    for ItemIdx := 0 to Items.Count - 1 do
    begin
      Item := TStringList(Items[ItemIdx]);
      while (Item.Count > 0) and IsBlank(Item[Item.Count - 1]) do
        Item.Delete(Item.Count - 1);
      // Пустая строка внутри пункта между его блоками - тоже "свободный"
      for OtherIdx := 1 to Item.Count - 2 do
        if IsBlank(Item[OtherIdx]) and not IsBlank(Item[OtherIdx + 1]) and
           (IndentOf(Item[OtherIdx + 1]) = 0) and
           not ListMarker(Item[OtherIdx + 1], SubIndent, SubCol, SubOrdered,
             SubStart, SubMark) then
          Loose := True;
    end;

    if Ordered then
    begin
      if Start <> 1 then
        AOut := '<ol start="' + IntToStr(Start) + '">'#10
      else
        AOut := '<ol>'#10;
    end
    else
      AOut := '<ul>'#10;

    for ItemIdx := 0 to Items.Count - 1 do
    begin
      Item := TStringList(Items[ItemIdx]);
      Check := '';
      if Item.Count > 0 then
      begin
        First := Item[0];
        Body := Copy(First, 1, 4);
        if (Body = '[ ] ') or (First = '[ ]') then
          Check := '<input type="checkbox" disabled> '
        else if (Body = '[x] ') or (Body = '[X] ') or (First = '[x]') or
                (First = '[X]') then
          Check := '<input type="checkbox" checked disabled> ';
        if Check <> '' then
          Item[0] := Copy(First, 5, MaxInt);
      end;
      HtmlText := Blocks(Item, not Loose);
      // Плотный список: перевод строки в конце пункта не нужен
      while (HtmlText <> '') and (HtmlText[Length(HtmlText)] = #10) do
        Delete(HtmlText, Length(HtmlText), 1);
      if Check <> '' then
      begin
        if Copy(HtmlText, 1, 3) = '<p>' then
          HtmlText := '<p>' + Check + Copy(HtmlText, 4, MaxInt)
        else
          HtmlText := Check + HtmlText;
        AOut := AOut + '<li class="task">' + HtmlText + '</li>'#10;
      end
      else
        AOut := AOut + '<li>' + HtmlText + '</li>'#10;
    end;

    if Ordered then
      AOut := AOut + '</ol>'#10
    else
      AOut := AOut + '</ul>'#10;
    ALineIdx := LineIdx;
  finally
    for ItemIdx := 0 to Items.Count - 1 do
      TStringList(Items[ItemIdx]).Free;
    Items.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  Строка: сначала ScanInline меняет код, ссылки, теги, сущности и
//  экранированные знаки на метки подстановки (их HTML уже готов), потом
//  Emphasis расставляет выделение по оставшемуся тексту и экранирует его,
//  в конце метки разворачиваются.
// ---------------------------------------------------------------------------

function TMdConverter.InlineHtml(const AText: string): string;
var
  Body: string;
begin
  Body := TrimRight(AText);
  Result := ExpandTokens(Emphasis(ScanInline(Body)));
end;

function TMdConverter.ScanInline(const AText: string): string;
var
  Idx, RunLen, CloseIdx, CloseLen, SpaceCount: Integer;
  Code, Piece, Entity: string;
  Found: Boolean;
begin
  Result := '';
  Idx := 1;
  while Idx <= Length(AText) do
  begin
    // \ + знак препинания - сам знак; \ в конце строки - перевод строки
    if AText[Idx] = '\' then
    begin
      if (Idx < Length(AText)) and IsAsciiPunct(AText[Idx + 1]) then
      begin
        Result := Result + AddToken(MdEscape(AText[Idx + 1]));
        Inc(Idx, 2);
        Continue;
      end;
      if (Idx < Length(AText)) and (AText[Idx + 1] = #10) then
      begin
        Result := Result + AddToken('<br>') + #10;
        Inc(Idx, 2);
        Continue;
      end;
    end;

    // `код` - столько же обратных кавычек закрывают
    if AText[Idx] = '`' then
    begin
      RunLen := 0;
      while (Idx + RunLen <= Length(AText)) and (AText[Idx + RunLen] = '`') do
        Inc(RunLen);
      Found := False;
      CloseIdx := Idx + RunLen;
      while CloseIdx <= Length(AText) do
      begin
        if AText[CloseIdx] = '`' then
        begin
          CloseLen := 0;
          while (CloseIdx + CloseLen <= Length(AText)) and
                (AText[CloseIdx + CloseLen] = '`') do
            Inc(CloseLen);
          if CloseLen = RunLen then
          begin
            Found := True;
            Break;
          end;
          Inc(CloseIdx, CloseLen);
        end
        else
          Inc(CloseIdx);
      end;
      if Found then
      begin
        Code := Copy(AText, Idx + RunLen, CloseIdx - Idx - RunLen);
        Code := StringReplace(Code, #10, ' ', [rfReplaceAll]);
        if (Length(Code) >= 2) and (Code[1] = ' ') and
           (Code[Length(Code)] = ' ') and (Trim(Code) <> '') then
          Code := Copy(Code, 2, Length(Code) - 2);
        Result := Result + AddToken('<code>' + MdEscape(Code) + '</code>');
        Idx := CloseIdx + RunLen;
      end
      else
      begin
        Result := Result + Copy(AText, Idx, RunLen);
        Inc(Idx, RunLen);
      end;
      Continue;
    end;

    if (AText[Idx] = '!') and (Idx < Length(AText)) and
       (AText[Idx + 1] = '[') then
    begin
      CloseIdx := Idx + 1;
      if TryLink(AText, CloseIdx, True, Piece) then
      begin
        Result := Result + AddToken(Piece);
        Idx := CloseIdx;
        Continue;
      end;
    end;

    if AText[Idx] = '[' then
    begin
      CloseIdx := Idx;
      if TryLink(AText, CloseIdx, False, Piece) then
      begin
        Result := Result + AddToken(Piece);
        Idx := CloseIdx;
        Continue;
      end;
    end;

    if AText[Idx] = '<' then
    begin
      CloseIdx := Idx;
      if TryAngle(AText, CloseIdx, Piece) then
      begin
        Result := Result + AddToken(Piece);
        Idx := CloseIdx;
        Continue;
      end;
    end;

    if (AText[Idx] in ['h', 'w']) and
       ((Idx = 1) or not IsWordChar(AText[Idx - 1])) then
    begin
      CloseIdx := Idx;
      if TryBareUrl(AText, CloseIdx, Piece) then
      begin
        Result := Result + AddToken(Piece);
        Idx := CloseIdx;
        Continue;
      end;
    end;

    // &имя; &#123; &#x1F; - как есть
    if AText[Idx] = '&' then
    begin
      CloseIdx := Idx + 1;
      while (CloseIdx <= Length(AText)) and (CloseIdx - Idx <= 32) and
            (AText[CloseIdx] in ['A'..'Z', 'a'..'z', '0'..'9', '#']) do
        Inc(CloseIdx);
      if (CloseIdx <= Length(AText)) and (AText[CloseIdx] = ';') and
         (CloseIdx > Idx + 1) then
      begin
        Entity := Copy(AText, Idx, CloseIdx - Idx + 1);
        Result := Result + AddToken(Entity);
        Idx := CloseIdx + 1;
        Continue;
      end;
    end;

    // Два пробела и больше перед переводом строки - жёсткий перевод
    if AText[Idx] = ' ' then
    begin
      SpaceCount := 0;
      while (Idx + SpaceCount <= Length(AText)) and
            (AText[Idx + SpaceCount] = ' ') do
        Inc(SpaceCount);
      if (SpaceCount >= 2) and (Idx + SpaceCount <= Length(AText)) and
         (AText[Idx + SpaceCount] = #10) then
      begin
        Result := Result + AddToken('<br>') + #10;
        Inc(Idx, SpaceCount + 1);
        Continue;
      end;
    end;

    Result := Result + AText[Idx];
    Inc(Idx);
  end;
end;

// [текст](адрес "заголовок"), [текст][метка], [текст] - по метке.
// APos - на '[' (для картинки - на '[' после '!'); при успехе - за концом.
function TMdConverter.TryLink(const AText: string; var APos: Integer;
  AImage: Boolean; var AOut: string): Boolean;
var
  Idx, Depth, TextEnd, Paren, UrlStart: Integer;
  LinkText, Url, Title, RefName, RefValue, TitleAttr: string;
  Quote: Char;
  RefIdx, TabAt: Integer;
  Resolved: Boolean;
begin
  Result := False;
  // Конец текста ссылки: парная ']' (вложенные [] и `код` учитываются)
  Idx := APos + 1;
  Depth := 1;
  while Idx <= Length(AText) do
  begin
    case AText[Idx] of
      '\': Inc(Idx);
      '[': Inc(Depth);
      ']':
        begin
          Dec(Depth);
          if Depth = 0 then
            Break;
        end;
      TokOpen:
        // метка подстановки внутри текста ссылки - пропустить целиком
        while (Idx <= Length(AText)) and (AText[Idx] <> TokClose) do
          Inc(Idx);
    end;
    Inc(Idx);
  end;
  if Idx > Length(AText) then
    Exit;
  TextEnd := Idx;
  LinkText := Copy(AText, APos + 1, TextEnd - APos - 1);
  Url := '';
  Title := '';
  Resolved := False;
  Idx := TextEnd + 1;

  if (Idx <= Length(AText)) and (AText[Idx] = '(') then
  begin
    // (адрес "заголовок")
    Inc(Idx);
    while (Idx <= Length(AText)) and IsSpaceChar(AText[Idx]) do
      Inc(Idx);
    if (Idx <= Length(AText)) and (AText[Idx] = '<') then
    begin
      UrlStart := Idx + 1;
      while (Idx <= Length(AText)) and (AText[Idx] <> '>') and
            (AText[Idx] <> #10) do
        Inc(Idx);
      if (Idx > Length(AText)) or (AText[Idx] <> '>') then
        Exit;
      Url := Copy(AText, UrlStart, Idx - UrlStart);
      Inc(Idx);
    end
    else
    begin
      UrlStart := Idx;
      Paren := 0;
      while Idx <= Length(AText) do
      begin
        if IsSpaceChar(AText[Idx]) then
          Break;
        if AText[Idx] = '(' then
          Inc(Paren)
        else if AText[Idx] = ')' then
        begin
          if Paren = 0 then
            Break;
          Dec(Paren);
        end;
        Inc(Idx);
      end;
      Url := Copy(AText, UrlStart, Idx - UrlStart);
    end;
    while (Idx <= Length(AText)) and IsSpaceChar(AText[Idx]) do
      Inc(Idx);
    if (Idx <= Length(AText)) and (AText[Idx] in ['"', '''', '(']) then
    begin
      Quote := AText[Idx];
      if Quote = '(' then
        Quote := ')';
      UrlStart := Idx + 1;
      Inc(Idx);
      while (Idx <= Length(AText)) and (AText[Idx] <> Quote) do
        Inc(Idx);
      if Idx > Length(AText) then
        Exit;
      Title := Copy(AText, UrlStart, Idx - UrlStart);
      Inc(Idx);
      while (Idx <= Length(AText)) and IsSpaceChar(AText[Idx]) do
        Inc(Idx);
    end;
    if (Idx > Length(AText)) or (AText[Idx] <> ')') then
      Exit;
    Inc(Idx);
    Resolved := True;
  end
  else
  begin
    // [текст][метка] или [текст][] или просто [текст]
    RefName := LinkText;
    if (Idx <= Length(AText)) and (AText[Idx] = '[') then
    begin
      UrlStart := Idx + 1;
      while (Idx <= Length(AText)) and (AText[Idx] <> ']') do
        Inc(Idx);
      if Idx > Length(AText) then
        Exit;
      if Idx > UrlStart then
        RefName := Copy(AText, UrlStart, Idx - UrlStart);
      Inc(Idx);
    end;
    RefIdx := FRefs.IndexOfName(LowerCase(Trim(ExpandTokens(RefName))));
    if RefIdx < 0 then
      RefIdx := FRefs.IndexOfName(LowerCase(Trim(RefName)));
    if RefIdx >= 0 then
    begin
      RefValue := FRefs.ValueFromIndex[RefIdx];
      TabAt := Pos(#9, RefValue);
      Url := Copy(RefValue, 1, TabAt - 1);
      Title := Copy(RefValue, TabAt + 1, MaxInt);
      Resolved := True;
    end;
  end;

  if not Resolved then
    Exit;

  TitleAttr := '';
  if Title <> '' then
    TitleAttr := ' title="' + MdEscape(Title) + '"';
  if AImage then
    AOut := '<img src="' + MdEscape(ResolveUrl(Url)) + '" alt="' +
      MdEscape(UnescapeBasic(StripTags(InlineHtml(LinkText)))) + '"' +
      TitleAttr + '>'
  else
    AOut := '<a href="' + MdEscape(ResolveUrl(Url)) + '"' + TitleAttr + '>' +
      InlineHtml(LinkText) + '</a>';
  APos := Idx;
  Result := True;
end;

// <http://адрес>, <почта@домен>, строчный тег HTML, <!-- комментарий -->
function TMdConverter.TryAngle(const AText: string; var APos: Integer;
  var AOut: string): Boolean;
var
  Idx, Colon: Integer;
  Body: string;
  InQuote: Char;
begin
  Result := False;
  Idx := APos + 1;
  if Idx > Length(AText) then
    Exit;

  if Copy(AText, APos, 4) = '<!--' then
  begin
    Idx := Pos('-->', Copy(AText, APos + 4, MaxInt));
    if Idx = 0 then
      Exit;
    AOut := Copy(AText, APos, Idx + 6);
    APos := APos + Idx + 6;
    Result := True;
    Exit;
  end;

  // Автоссылка: без пробелов до '>'
  Idx := APos + 1;
  while (Idx <= Length(AText)) and (AText[Idx] <> '>') and
        not IsSpaceChar(AText[Idx]) and (AText[Idx] <> '<') do
    Inc(Idx);
  if (Idx <= Length(AText)) and (AText[Idx] = '>') and (Idx > APos + 1) then
  begin
    Body := Copy(AText, APos + 1, Idx - APos - 1);
    Colon := Pos(':', Body);
    if (Colon > 2) and (Body[1] in ['A'..'Z', 'a'..'z']) then
    begin
      AOut := '<a href="' + MdEscape(Body) + '">' + MdEscape(Body) + '</a>';
      APos := Idx + 1;
      Result := True;
      Exit;
    end;
    if (Pos('@', Body) > 1) and (Pos('/', Body) = 0) then
    begin
      AOut := '<a href="mailto:' + MdEscape(Body) + '">' + MdEscape(Body) +
        '</a>';
      APos := Idx + 1;
      Result := True;
      Exit;
    end;
  end;

  // Тег: < или </, имя с буквы, атрибуты (в кавычках - что угодно), >
  Idx := APos + 1;
  if (Idx <= Length(AText)) and (AText[Idx] = '/') then
    Inc(Idx);
  if (Idx > Length(AText)) or not (AText[Idx] in ['A'..'Z', 'a'..'z']) then
    Exit;
  InQuote := #0;
  while Idx <= Length(AText) do
  begin
    if InQuote <> #0 then
    begin
      if AText[Idx] = InQuote then
        InQuote := #0;
    end
    else if AText[Idx] in ['"', ''''] then
      InQuote := AText[Idx]
    else if AText[Idx] = '>' then
      Break
    else if AText[Idx] = '<' then
      Exit;
    Inc(Idx);
  end;
  if Idx > Length(AText) then
    Exit;
  AOut := ResolveRawHtml(Copy(AText, APos, Idx - APos + 1));
  APos := Idx + 1;
  Result := True;
end;

// http://..., https://..., www.... в тексте. Знаки препинания в конце и
// непарная ')' - не часть адреса.
function TMdConverter.TryBareUrl(const AText: string; var APos: Integer;
  var AOut: string): Boolean;
var
  Idx, OpenCount, CloseCount, CharIdx: Integer;
  Url, Href: string;
begin
  Result := False;
  if not ((Copy(AText, APos, 7) = 'http://') or
          (Copy(AText, APos, 8) = 'https://') or
          (Copy(AText, APos, 4) = 'www.')) then
    Exit;
  Idx := APos;
  while (Idx <= Length(AText)) and not IsSpaceChar(AText[Idx]) and
        (AText[Idx] <> '<') and (AText[Idx] <> TokOpen) do
    Inc(Idx);
  Url := Copy(AText, APos, Idx - APos);
  while (Url <> '') and (Url[Length(Url)] in ['.', ',', ':', ';', '!', '?',
                                              '*', '_', '~', '''', '"']) do
    Delete(Url, Length(Url), 1);
  OpenCount := 0;
  CloseCount := 0;
  for CharIdx := 1 to Length(Url) do
    if Url[CharIdx] = '(' then
      Inc(OpenCount)
    else if Url[CharIdx] = ')' then
      Inc(CloseCount);
  while (Url <> '') and (Url[Length(Url)] = ')') and (CloseCount > OpenCount) do
  begin
    Delete(Url, Length(Url), 1);
    Dec(CloseCount);
  end;
  if (Length(Url) <= 8) or ((Copy(Url, 1, 4) = 'www.') and (Pos('.', Copy(Url, 5, MaxInt)) = 0)) then
    Exit;
  Href := Url;
  if Copy(Href, 1, 4) = 'www.' then
    Href := 'http://' + Href;
  AOut := '<a href="' + MdEscape(Href) + '">' + MdEscape(Url) + '</a>';
  APos := APos + Length(Url);
  Result := True;
end;

// Выделение * _ ~~ по тексту с метками подстановки; остальной текст -
// с экранированием & < > ".
function TMdConverter.Emphasis(const AText: string): string;
var
  Idx, RunLen, CloseIdx, CloseLen, Used: Integer;
  Mark: Char;
  OpenTag, CloseTag: string;

  function RunAt(APos: Integer): Integer;
  begin
    Result := 0;
    while (APos + Result <= Length(AText)) and
          (AText[APos + Result] = AText[APos]) do
      Inc(Result);
  end;

  function CanOpen(APos, ALen: Integer): Boolean;
  begin
    Result := (APos + ALen <= Length(AText)) and
              not IsSpaceChar(AText[APos + ALen]);
    if Result and (AText[APos] = '_') and (APos > 1) and
       IsWordChar(AText[APos - 1]) then
      Result := False;
  end;

  function CanClose(APos, ALen, AFrom: Integer): Boolean;
  begin
    Result := (APos > AFrom) and not IsSpaceChar(AText[APos - 1]);
    if Result and (AText[APos] = '_') and (APos + ALen <= Length(AText)) and
       IsWordChar(AText[APos + ALen]) then
      Result := False;
  end;

  // Закрывающая серия для открывающей длины ALen с позиции AFrom.
  // Вложенная открывающая серия того же знака пропускается вместе со своей
  // закрывающей: в **а *б* в** звёздочка после "б" закрывает *б*, а не **.
  function FindCloser(AFrom: Integer; AMark: Char; ALen: Integer;
    out AFoundLen: Integer): Integer;
  var
    ScanIdx, Run, InnerLen, Inner: Integer;
    Opens, Closes: Boolean;
  begin
    Result := 0;
    AFoundLen := 0;
    ScanIdx := AFrom;
    while ScanIdx <= Length(AText) do
    begin
      if AText[ScanIdx] = AMark then
      begin
        Run := RunAt(ScanIdx);
        Closes := CanClose(ScanIdx, Run, AFrom);
        Opens := CanOpen(ScanIdx, Run);
        if Closes and ((AMark <> '~') or (Run >= 2)) and
           ((Run >= ALen) or not Opens) then
        begin
          Result := ScanIdx;
          AFoundLen := Run;
          Exit;
        end;
        if Opens and not Closes then
        begin
          Inner := FindCloser(ScanIdx + Run, AMark, Run, InnerLen);
          if Inner > 0 then
          begin
            ScanIdx := Inner + InnerLen;
            Continue;
          end;
        end;
        Inc(ScanIdx, Run);
      end
      else
        Inc(ScanIdx);
    end;
  end;

begin
  Result := '';
  Idx := 1;
  while Idx <= Length(AText) do
  begin
    Mark := AText[Idx];
    if Mark in ['*', '_', '~'] then
    begin
      RunLen := RunAt(Idx);
      if ((Mark <> '~') or (RunLen = 2)) and CanOpen(Idx, RunLen) then
      begin
        CloseIdx := FindCloser(Idx + RunLen, Mark, RunLen, CloseLen);
        if CloseIdx > 0 then
        begin
          Used := RunLen;
          if CloseLen < Used then
            Used := CloseLen;
          if Used > 3 then
            Used := 3;
          if Mark = '~' then
          begin
            Used := 2;
            OpenTag := '<del>';
            CloseTag := '</del>';
          end
          else if Used = 3 then
          begin
            OpenTag := '<strong><em>';
            CloseTag := '</em></strong>';
          end
          else if Used = 2 then
          begin
            OpenTag := '<strong>';
            CloseTag := '</strong>';
          end
          else
          begin
            OpenTag := '<em>';
            CloseTag := '</em>';
          end;
          // Лишние знаки открывающей серии - текстом перед тегом
          Result := Result + RepeatChar(Mark, RunLen - Used) + OpenTag +
            Emphasis(Copy(AText, Idx + RunLen, CloseIdx - Idx - RunLen)) +
            CloseTag;
          // Лишние знаки закрывающей серии пойдут дальше обычным разбором
          Idx := CloseIdx + Used;
          Continue;
        end;
      end;
      Result := Result + Copy(AText, Idx, RunLen);
      Inc(Idx, RunLen);
      Continue;
    end;

    if Mark = TokOpen then
    begin
      // Метка подстановки - как есть
      CloseIdx := Idx;
      while (CloseIdx <= Length(AText)) and (AText[CloseIdx] <> TokClose) do
        Inc(CloseIdx);
      Result := Result + Copy(AText, Idx, CloseIdx - Idx + 1);
      Idx := CloseIdx + 1;
      Continue;
    end;

    case Mark of
      '&': Result := Result + '&amp;';
      '<': Result := Result + '&lt;';
      '>': Result := Result + '&gt;';
      '"': Result := Result + '&quot;';
    else
      Result := Result + Mark;
    end;
    Inc(Idx);
  end;
end;

// ---------------------------------------------------------------------------
//  Страница
// ---------------------------------------------------------------------------

function MdToHtmlBody(const ASrc, ABaseUrl: string): string;
var
  Converter: TMdConverter;
begin
  Converter := TMdConverter.Create(ABaseUrl);
  try
    Result := Converter.Convert(ASrc);
  finally
    Converter.Free;
  end;
end;

function MdToHtmlPage(const ASrc, ATitle, ABaseUrl: string;
  const AColors: TMdColors): string;
var
  Css: string;
begin
  // Стили - для IE 9-11 (режим IE=edge): без переменных CSS и flex
  Css :=
    'html{background:' + AColors.Back + ';}'#10 +
    'body{margin:0;padding:12px 24px 40px 24px;background:' + AColors.Back +
      ';color:' + AColors.Text + ';font-family:"Segoe UI",Tahoma,Arial,' +
      'sans-serif;font-size:14px;line-height:1.5;word-wrap:break-word;}'#10 +
    'a{color:' + AColors.Link + ';text-decoration:none;}'#10 +
    'a:hover{text-decoration:underline;}'#10 +
    'h1,h2,h3,h4,h5,h6{margin:22px 0 10px 0;font-weight:600;line-height:1.25;}'#10 +
    'h1{font-size:1.9em;padding-bottom:.3em;border-bottom:1px solid ' +
      AColors.Border + ';}'#10 +
    'h2{font-size:1.5em;padding-bottom:.3em;border-bottom:1px solid ' +
      AColors.Border + ';}'#10 +
    'h3{font-size:1.25em;}h4{font-size:1em;}h5{font-size:.9em;}'#10 +
    'h6{font-size:.85em;color:' + AColors.Muted + ';}'#10 +
    'p,ul,ol,table,pre,blockquote{margin:0 0 12px 0;}'#10 +
    'ul,ol{padding-left:2em;}li{margin:2px 0;}li>p{margin:6px 0;}'#10 +
    'li.task{list-style-type:none;margin-left:-1.4em;}'#10 +
    'code{font-family:Consolas,"Courier New",monospace;font-size:90%;' +
      'background:' + AColors.CodeBack + ';padding:1px 4px;}'#10 +
    'pre{font-family:Consolas,"Courier New",monospace;font-size:90%;' +
      'line-height:1.4;background:' + AColors.CodeBack + ';border:1px solid ' +
      AColors.Border + ';padding:10px 12px;overflow:auto;}'#10 +
    'pre code{background:transparent;padding:0;font-size:100%;}'#10 +
    'blockquote{margin-left:0;padding:0 1em;color:' + AColors.Muted +
      ';border-left:4px solid ' + AColors.Border + ';}'#10 +
    'table{border-collapse:collapse;}'#10 +
    'th,td{border:1px solid ' + AColors.Border + ';padding:5px 12px;' +
      'vertical-align:top;}'#10 +
    'th{font-weight:600;background:' + AColors.CodeBack + ';}'#10 +
    'hr{height:2px;border:0;background:' + AColors.Border +
      ';margin:20px 0;}'#10 +
    'img{max-width:100%;}'#10;
  if AColors.Dark then
    // Полосы прокрутки IE (свойства только IE) - в тон тёмной странице
    Css := Css +
      'html{scrollbar-face-color:' + AColors.CodeBack +
        ';scrollbar-track-color:' + AColors.Back +
        ';scrollbar-arrow-color:' + AColors.Muted +
        ';scrollbar-shadow-color:' + AColors.Border +
        ';scrollbar-highlight-color:' + AColors.Border +
        ';scrollbar-3dlight-color:' + AColors.Back +
        ';scrollbar-darkshadow-color:' + AColors.Back + ';}'#10;

  Result :=
    '<!DOCTYPE html>'#10 +
    '<html>'#10'<head>'#10 +
    '<meta http-equiv="X-UA-Compatible" content="IE=edge">'#10 +
    '<meta http-equiv="Content-Type" content="text/html; charset=utf-8">'#10 +
    '<title>' + MdEscape(ATitle) + '</title>'#10 +
    '<style>'#10 + Css + '</style>'#10 +
    '</head>'#10'<body>'#10 +
    MdToHtmlBody(ASrc, ABaseUrl) +
    '</body>'#10'</html>'#10;
end;

end.
