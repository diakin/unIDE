unit FmtView;

// ---------------------------------------------------------------------------
//  Просмотр файла "по формату" во вкладке редактора, поверх текста.
//  F12, кнопка Txt / Fmt на вкладке и меню правой кнопки - текст / просмотр.
//
//  Какие файлы и чем показываются (FmtKindOf):
//    .md, .markdown       - Markdown переводится в HTML (MdHtml), страница
//                           во встроенном IE в цветах редактора;
//    .html, .htm, .xhtml  - встроенный IE, страница как есть;
//    .mht, .mhtml         - встроенный IE (архив веб-страницы);
//    .rtf                 - RichEdit 4.1 только для чтения;
//    .rvf                 - тот же RichEdit; RTF из RVF делает помощник
//                           rvf2rtf.exe (собирается в Delphi с TRichView,
//                           исходник tools\rvf2rtf). Сам unIDE TRichView не
//                           использует: сборка unIDE не должна от него
//                           зависеть.
//
//  Встроенный IE (TWebPreview).
//    Файл не правился - IE открывает его с диска: картинки, стили и ссылки
//    по относительным путям работают сами. Правился (или это Markdown) -
//    страница пишется во временный файл %TEMP%\unide_fmt_<pid>.<ext>
//    (зона "этот компьютер"); у правленого HTML в <head> ставится
//    <base href> на папку файла, иначе относительные пути вели бы во
//    временную папку.
//    Ссылки со страницы внутри браузера не открываются (BeforeNavigate2):
//      - своя страница, её метки (#раздел), части архива .mht (mhtml:),
//        содержимое кадров (frame, iframe) - в браузере;
//      - метка, которую <base href> увёл на папку, - переход по странице
//        (JumpToAnchor);
//      - файл на диске, который открывается в unIDE, - вкладкой
//        (OnOpenFile), не сразу, а сообщением: событие приходит изнутри
//        IE, и переключение вкладки отсюда снова звало бы Navigate;
//      - остальное (http, mailto, pdf, картинки, папки) - программой Windows.
//
//    Режим IE - по <!DOCTYPE> страницы, как в самом Internet Explorer:
//    при первом показе для exe unIDE ставится FEATURE_BROWSER_EMULATION
//    (EnsureBrowserEmulation), без него встроенный IE рисует всё в режиме
//    IE 7.
//
//  RichEdit (TRtfPreview). RTF загружается EM_STREAMIN. Фон - белый, как
//  лист: цвета текста задаёт сам документ, и чёрный текст на тёмном фоне
//  темы Dark был бы не виден.
//
//  Прокрутка запоминается по файлу: после правки текста и F12 просмотр
//  открывается на том же месте.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, StdCtrls,
  ComCtrls, Menus, Forms, ShellAPI, Variants, ComObj, Registry, SHDocVw,
  MdHtml;

type
  TFmtKind = (fkNone, fkMarkdown, fkHtml, fkMht, fkRtf, fkRvf);

  TFmtOpenFileEvent = procedure(const AFileName: string) of object;
  TFmtLogEvent = procedure(const AText: string) of object;
  // Щелчок левой кнопкой по тексту RichEdit просмотра: строка и позиция в
  // ней (с 0) под мышью, первая видимая строка
  TFmtClickPosEvent = procedure(Sender: TObject;
    ALine, ACol, ATopLine: Integer) of object;

  // Встроенный IE: Markdown, HTML, MHT
  TWebPreview = class
  private
    FHost: TWinControl;
    FBrowser: TWebBrowser;
    FMsgWnd: HWND;            // окно для отложенных действий (WM_FMT_*)
    FTempBase: string;        // %TEMP%\unide_fmt_<pid> - без расширения
    FTempPage: string;        // временная страница, если показана она
    FCurrentPage: string;     // файл, который открыт в браузере
    FSourceFile: string;      // файл вкладки, который сейчас показан
    FScrollPos: TStringList;  // файл вкладки = прокрутка страницы, пикселей
    FPendingScroll: Integer;  // прокрутка после загрузки страницы
    FPendingOpen: string;     // файл для OnOpenFile
    FPendingAnchor: string;   // метка для JumpToAnchor
    FLastError: string;
    FOnOpenFile: TFmtOpenFileEvent;
    FOnLog: TFmtLogEvent;
    // Navigate вызван, BeforeNavigate2 этой страницы ещё не приходил
    FExpectOwn: Boolean;
    function IsOwnPage(const AUrl, ALocalPath: string): Boolean;
    function IsTopFrame(const ADisp: IDispatch): Boolean;
    function IsMovedAnchor(const AUrl, ALocalPath: string;
      out AAnchor: string): Boolean;
    procedure JumpToAnchor(const AAnchor: string);
    procedure LogImages;
    procedure Log(const AText: string);
    function EnsureBrowser: Boolean;
    function ReadScroll: Integer;
    procedure RememberScroll;
    function WriteTemp(const ABytes, AExt: string): Boolean;
    function OpenPage(const APage, ASourceFile: string): Boolean;
    procedure MsgWndProc(var Message: TMessage);
    procedure BrowserBeforeNavigate2(Sender: TObject; const ADisp: IDispatch;
      var AUrl: OleVariant; var AFlags: OleVariant;
      var ATargetFrameName: OleVariant; var APostData: OleVariant;
      var AHeaders: OleVariant; var ACancel: WordBool);
    procedure BrowserDocumentComplete(Sender: TObject; const ADisp: IDispatch;
      var AUrl: OleVariant);
  public
    // AHost - панель, которую просмотр закрывает целиком (FLeftHost)
    constructor Create(AHost: TWinControl);
    destructor Destroy; override;
    // Markdown: текст AUtf8Text (UTF-8) файла ASourceFile в цветах
    // редактора. False - не вышло, причина в LastError
    function ShowMarkdown(const AUtf8Text, ASourceFile: string;
      ABack, AFore: TColor): Boolean;
    // HTML, MHT с диска как есть
    function ShowFile(const AFileName: string): Boolean;
    // HTML, MHT из редактора: ABytes - текст в кодировке файла
    function ShowEdited(const ABytes, ASourceFile: string;
      AKind: TFmtKind): Boolean;
    procedure HideView;
    function IsShown: Boolean;
    procedure FocusView;
    // Копировать выделенное / выделить всё (Ctrl+C, Ctrl+A: эти клавиши
    // перехватывает меню формы, до IE они не доходят)
    procedure CopySelection;
    procedure SelectAll;
    // Окно AWnd - браузер просмотра или его дочернее окно (Internet
    // Explorer_Server), и просмотр на экране
    function OwnsWindow(AWnd: HWND): Boolean;
    property SourceFile: string read FSourceFile;
    property LastError: string read FLastError;
    property OnOpenFile: TFmtOpenFileEvent read FOnOpenFile write FOnOpenFile;
    // Журнал переходов браузера (адрес и что с ним сделано)
    property OnLog: TFmtLogEvent read FOnLog write FOnLog;
  end;

  // RichEdit 4.1 (msftedit.dll, RICHEDIT50W); нет его - RichEdit 2.0/3.0
  TRtfViewEdit = class(TRichEdit)
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  end;

  // RichEdit только для чтения: RTF, RVF (через rvf2rtf.exe)
  TRtfPreview = class
  private
    FHost: TWinControl;
    FPopup: TPopupMenu;
    FEdit: TRtfViewEdit;
    FSourceFile: string;
    FScrollLine: TStringList; // файл вкладки = первая видимая строка
    FLastError: string;
    FOnLog: TFmtLogEvent;
    FPaperColor: TColor;
    FWrapLines: Boolean;
    FOnClickPos: TFmtClickPosEvent;
    procedure SetPaperColor(AColor: TColor);
    procedure SetWrapLines(AValue: Boolean);
    procedure EditMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    function EnsureEdit: Boolean;
    procedure RememberScroll;
    procedure Log(const AText: string);
    function StreamIn(const ABytes: string): Boolean;
    function RunRvf2Rtf(const AHelper, ARvfFile, ARtfFile: string;
      out AError: string): Boolean;
  public
    // APopup - меню правой кнопки просмотра
    constructor Create(AHost: TWinControl; APopup: TPopupMenu);
    destructor Destroy; override;
    // ABytes - текст RTF (не RTF - показывается простым текстом)
    function ShowRtf(const ABytes, ASourceFile: string): Boolean;
    function ShowRtfFile(const AFileName: string): Boolean;
    // RVF с диска: rvf2rtf.exe, затем ShowRtf. Помощника нет или он не
    // справился - в просмотре текст о том, что случилось и что сделать
    function ShowRvfFile(const AFileName: string): Boolean;
    procedure HideView;
    function IsShown: Boolean;
    procedure FocusView;
    procedure CopySelection;
    procedure SelectAll;
    function OwnsWindow(AWnd: HWND): Boolean;
    // Первая видимая строка (с 0) / прокрутить так, чтобы ATopLine была
    // первой видимой
    function TopLine: Integer;
    procedure SetTopLine(ATopLine: Integer);
    property LastError: string read FLastError;
    property OnLog: TFmtLogEvent read FOnLog write FOnLog;
    // Фон окна (по умолчанию белый - лист документа)
    property PaperColor: TColor read FPaperColor write SetPaperColor;
    // Перенос строк по ширине окна (по умолчанию да; для текста
    // программы - нет, с горизонтальной прокруткой)
    property WrapLines: Boolean read FWrapLines write SetWrapLines;
    property OnClickPos: TFmtClickPosEvent read FOnClickPos write FOnClickPos;
  end;

// Вид просмотра по расширению файла; fkNone - просмотра по формату нет
function FmtKindOf(const AFileName: string): TFmtKind;
// Название вида для строки состояния: 'Markdown', 'HTML', ...
function FmtKindName(AKind: TFmtKind): string;
// Просмотр - во встроенном IE (Markdown, HTML, MHT)
function FmtKindIsWeb(AKind: TFmtKind): Boolean;
// Файл с диска в UTF-8: BOM убирается, UTF-8 остаётся как есть, ANSI
// переводится. False - файл не прочитан
function MdFileToUtf8(const AFileName: string; out AText: string): Boolean;
// Цвета страницы Markdown по фону и тексту редактора
function MdColorsFor(ABack, AFore: TColor): TMdColors;
// Элемент - окно просмотра (браузер или RichEdit просмотра). Темы IDE и
// снимок формы его не трогают: цвета просмотра свои
function FmtIsViewControl(AControl: TControl): Boolean;
// Текст -> RTF (кириллица - \'xx в cp1251): сообщение в просмотре
function FmtPlainToRtf(const AText: string): string;
// Путь к rvf2rtf.exe ('' - не найден): рядом с exe unIDE, в его tools\ и
// tools\rvf2rtf\, то же на уровень выше
function FmtRvfHelperPath: string;

implementation

const
  WM_FMT_OPENFILE = WM_USER + 1;
  WM_FMT_ANCHOR = WM_USER + 2;
  // BrowserNavConstants: navNoHistory or navNoReadFromCache
  NavFlagsReload = $02 or $04;
  // Сколько ждать rvf2rtf.exe, мс
  RvfHelperTimeout = 20000;
  RvfHelperName = 'rvf2rtf.exe';

// ---------------------------------------------------------------------------
//  Виды файлов
// ---------------------------------------------------------------------------

function FmtKindOf(const AFileName: string): TFmtKind;
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(AFileName));
  if (Ext = '.md') or (Ext = '.markdown') or (Ext = '.mdown') or
     (Ext = '.mkd') then
    Result := fkMarkdown
  else if (Ext = '.html') or (Ext = '.htm') or (Ext = '.xhtml') then
    Result := fkHtml
  else if (Ext = '.mht') or (Ext = '.mhtml') then
    Result := fkMht
  else if Ext = '.rtf' then
    Result := fkRtf
  else if Ext = '.rvf' then
    Result := fkRvf
  else
    Result := fkNone;
end;

function FmtKindName(AKind: TFmtKind): string;
begin
  case AKind of
    fkMarkdown: Result := 'Markdown';
    fkHtml: Result := 'HTML';
    fkMht: Result := 'MHT';
    fkRtf: Result := 'RTF';
    fkRvf: Result := 'RVF';
  else
    Result := '';
  end;
end;

function FmtKindIsWeb(AKind: TFmtKind): Boolean;
begin
  Result := AKind in [fkMarkdown, fkHtml, fkMht];
end;

// ---------------------------------------------------------------------------
//  Мелочи
// ---------------------------------------------------------------------------

// Строка - правильный UTF-8 (с многобайтовыми символами или без)
function IsValidUtf8(const AText: string): Boolean;
var
  Idx, Extra, TailIdx: Integer;
  Lead: Byte;
begin
  Result := False;
  Idx := 1;
  while Idx <= Length(AText) do
  begin
    Lead := Byte(AText[Idx]);
    if Lead < $80 then
      Extra := 0
    else if (Lead and $E0) = $C0 then
      Extra := 1
    else if (Lead and $F0) = $E0 then
      Extra := 2
    else if (Lead and $F8) = $F0 then
      Extra := 3
    else
      Exit;
    if Idx + Extra > Length(AText) then
      Exit;
    for TailIdx := Idx + 1 to Idx + Extra do
      if (Byte(AText[TailIdx]) and $C0) <> $80 then
        Exit;
    Inc(Idx, Extra + 1);
  end;
  Result := True;
end;

// Файл целиком в строку; False - не прочитан
function ReadFileBytes(const AFileName: string; out ABytes: string): Boolean;
var
  Stream: TFileStream;
begin
  Result := False;
  ABytes := '';
  try
    Stream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
    try
      SetLength(ABytes, Stream.Size);
      if Stream.Size > 0 then
        Stream.ReadBuffer(ABytes[1], Stream.Size);
    finally
      Stream.Free;
    end;
    Result := True;
  except
    ABytes := '';
  end;
end;

function MdFileToUtf8(const AFileName: string; out AText: string): Boolean;
var
  Raw: string;
begin
  AText := '';
  Result := ReadFileBytes(AFileName, Raw);
  if not Result then
    Exit;
  if Copy(Raw, 1, 3) = #$EF#$BB#$BF then
    AText := Copy(Raw, 4, MaxInt)
  else if IsValidUtf8(Raw) then
    AText := Raw
  else
    AText := AnsiToUtf8(Raw);
end;

function ColorCss(AColor: TColor): string;
var
  Rgb: Longint;
begin
  Rgb := ColorToRGB(AColor);
  Result := Format('#%.2x%.2x%.2x',
    [GetRValue(Rgb), GetGValue(Rgb), GetBValue(Rgb)]);
end;

// Цвет между AFrom и ATo: APercent - доля ATo, в процентах
function MixColor(AFrom, ATo: TColor; APercent: Integer): TColor;
var
  FromRgb, ToRgb: Longint;

  function Channel(AFromPart, AToPart: Byte): Byte;
  begin
    Result := AFromPart + (Integer(AToPart) - AFromPart) * APercent div 100;
  end;

begin
  FromRgb := ColorToRGB(AFrom);
  ToRgb := ColorToRGB(ATo);
  Result := RGB(Channel(GetRValue(FromRgb), GetRValue(ToRgb)),
                Channel(GetGValue(FromRgb), GetGValue(ToRgb)),
                Channel(GetBValue(FromRgb), GetBValue(ToRgb)));
end;

function MdColorsFor(ABack, AFore: TColor): TMdColors;
var
  Rgb: Longint;
  Luma: Integer;
begin
  Rgb := ColorToRGB(ABack);
  Luma := (GetRValue(Rgb) * 299 + GetGValue(Rgb) * 587 +
           GetBValue(Rgb) * 114) div 1000;
  Result.Dark := Luma < 128;
  Result.Back := ColorCss(ABack);
  Result.Text := ColorCss(AFore);
  Result.Muted := ColorCss(MixColor(ABack, AFore, 65));
  Result.Border := ColorCss(MixColor(ABack, AFore, 25));
  Result.CodeBack := ColorCss(MixColor(ABack, AFore, 8));
  if Result.Dark then
    Result.Link := '#6cb6ff'
  else
    Result.Link := '#0b5cad';
end;

// %XX -> байт
function PercentDecode(const AText: string): string;
var
  Idx, Code: Integer;
begin
  Result := '';
  Idx := 1;
  while Idx <= Length(AText) do
  begin
    if (AText[Idx] = '%') and (Idx + 2 <= Length(AText)) then
    begin
      Code := StrToIntDef('$' + Copy(AText, Idx + 1, 2), -1);
      if Code >= 0 then
      begin
        Result := Result + Chr(Code);
        Inc(Idx, 3);
        Continue;
      end;
    end;
    Result := Result + AText[Idx];
    Inc(Idx);
  end;
end;

// file:///C:/Папка/a%20b.md#метка -> C:\Папка\a b.md. Путь без file:
// (C:\..., C:/..., \\сервер\...) - тоже: IE может отдать адрес локального
// файла и так. '' - не файл (http:, mailto:, mhtml: ...)
function UrlToPath(const AUrl: string): string;
var
  Body, Decoded: string;
  CutAt: Integer;
begin
  Result := '';
  if (Length(AUrl) >= 3) and (AUrl[1] in ['A'..'Z', 'a'..'z']) and
     (AUrl[2] = ':') and (AUrl[3] in ['\', '/']) then
    Body := '///' + AUrl
  else if Copy(AUrl, 1, 2) = '\\' then
    Body := AUrl
  else if CompareText(Copy(AUrl, 1, 5), 'file:') = 0 then
    Body := Copy(AUrl, 6, MaxInt)
  else
    Exit;
  CutAt := Pos('#', Body);
  if CutAt > 0 then
    Body := Copy(Body, 1, CutAt - 1);
  CutAt := Pos('?', Body);
  if CutAt > 0 then
    Body := Copy(Body, 1, CutAt - 1);
  if Copy(Body, 1, 3) = '///' then
    Delete(Body, 1, 3)
  else if Copy(Body, 1, 2) = '//' then
    Body := '\\' + Copy(Body, 3, MaxInt);   // file://сервер/папка

  // Байты от $80 после %XX - это UTF-8, их переводим в ANSI
  Decoded := PercentDecode(Body);
  if (Decoded <> Body) and IsValidUtf8(Decoded) and
     (Utf8ToAnsi(Decoded) <> '') then
    Decoded := Utf8ToAnsi(Decoded);
  Result := StringReplace(Decoded, '/', '\', [rfReplaceAll]);
end;

// Метка из адреса (после #), раскодированная из %XX и UTF-8
function UrlAnchor(const AUrl: string): WideString;
var
  HashAt: Integer;
  Raw: string;
begin
  Result := '';
  HashAt := Pos('#', AUrl);
  if HashAt = 0 then
    Exit;
  Raw := PercentDecode(Copy(AUrl, HashAt + 1, MaxInt));
  if IsValidUtf8(Raw) then
    Result := UTF8Decode(Raw)
  else
    Result := Raw;
end;

// Путь (ANSI) -> адрес file:/// только из ASCII: байты UTF-8 и пробелы -
// %XX. Годится для страницы в любой кодировке. ADir - на конце '/'
function PathToFileUrl(const APath: string; ADir: Boolean): string;
var
  Utf8Path: string;
  Idx: Integer;
  Ch: Char;
begin
  Utf8Path := AnsiToUtf8(StringReplace(APath, '\', '/', [rfReplaceAll]));
  Result := '';
  for Idx := 1 to Length(Utf8Path) do
  begin
    Ch := Utf8Path[Idx];
    if (Ord(Ch) >= $80) or (Ch in [' ', '%', '#', '"', '<', '>', '?']) then
      Result := Result + '%' + IntToHex(Ord(Ch), 2)
    else
      Result := Result + Ch;
  end;
  if ADir and (Result <> '') and (Result[Length(Result)] <> '/') then
    Result := Result + '/';
  if Copy(Result, 1, 2) = '//' then
    Result := 'file:' + Result          // \\сервер\папка
  else
    Result := 'file:///' + Result;
end;

// Файл, который по ссылке открывается в unIDE, а не программой Windows
function IsIdeFile(const AFileName: string): Boolean;
const
  Foreign: array[0..17] of string = (
    '.pdf', '.chm', '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.ico',
    '.zip', '.7z', '.rar', '.exe', '.dll', '.doc', '.docx', '.xls',
    '.xlsx', '.mp4');
var
  Ext: string;
  ExtIdx: Integer;
begin
  Result := False;
  if not FileExists(AFileName) then
    Exit;
  Ext := LowerCase(ExtractFileExt(AFileName));
  for ExtIdx := Low(Foreign) to High(Foreign) do
    if Foreign[ExtIdx] = Ext then
      Exit;
  Result := True;
end;

// Ключ файла в списках прокрутки (Values): '=' в имени файла допустим, а
// в TStringList он отделяет имя от значения
function ScrollKey(const AFileName: string): string;
begin
  Result := StringReplace(AFileName, '=', #1, [rfReplaceAll]);
end;

// Режим встроенного IE для exe unIDE (FEATURE_BROWSER_EMULATION, HKCU).
// Без записи встроенный IE рисует страницы в режиме IE 7, какая бы версия
// IE ни стояла. Значение - по установленному IE: 11000 для IE 11, 10000
// для IE 10 и т.д. - "режим по <!DOCTYPE>": страница с полным
// объявлением - в режиме этой версии, без объявления или с неполным -
// в режиме совместимости (IE 5), как в самом Internet Explorer.
// Запись, которую поставил кто-то другой (значение уже есть), не
// меняется. Читается при первом создании браузера в процессе - поэтому
// до TWebBrowser.Create. Результат - строка для журнала.
function EnsureBrowserEmulation: string;
const
  EmulationKey = 'Software\Microsoft\Internet Explorer\Main\FeatureControl\' +
                 'FEATURE_BROWSER_EMULATION';
  IeKey = 'Software\Microsoft\Internet Explorer';
var
  Reg: TRegistry;
  ExeName, IeVersion: string;
  IeMajor, DotAt, Emulation: Integer;
begin
  Result := '';
  ExeName := ExtractFileName(ParamStr(0));
  // Версия IE: svcVersion (IE 10 и новее: '11.0.9600...'), иначе Version
  // (IE 9 и старше: '9.0.8112...'; у IE 10-11 там '9.10...', '9.11...')
  IeVersion := '';
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    try
      if Reg.OpenKeyReadOnly(IeKey) then
      begin
        if Reg.ValueExists('svcVersion') then
          IeVersion := Reg.ReadString('svcVersion')
        else if Reg.ValueExists('Version') then
          IeVersion := Reg.ReadString('Version');
        Reg.CloseKey;
      end;
    except
      IeVersion := '';
    end;
  finally
    Reg.Free;
  end;
  DotAt := Pos('.', IeVersion);
  if DotAt > 0 then
    IeMajor := StrToIntDef(Copy(IeVersion, 1, DotAt - 1), 0)
  else
    IeMajor := StrToIntDef(IeVersion, 0);
  if IeMajor > 11 then
    IeMajor := 11;
  if IeMajor < 8 then
  begin
    Result := 'режим IE: версия IE не определена (' + IeVersion +
              '), запись не сделана';
    Exit;
  end;
  Emulation := IeMajor * 1000;

  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    try
      if Reg.OpenKey(EmulationKey, True) then
      begin
        if Reg.ValueExists(ExeName) then
          Result := 'режим IE: для ' + ExeName + ' уже записан (' +
                    IntToStr(Reg.ReadInteger(ExeName)) + ')'
        else
        begin
          Reg.WriteInteger(ExeName, Emulation);
          Result := 'режим IE: для ' + ExeName + ' записан ' +
                    IntToStr(Emulation) + ' (IE ' + IeVersion + ')';
        end;
        Reg.CloseKey;
      end
      else
        Result := 'режим IE: ключ реестра не открылся';
    except
      on E: Exception do
        Result := 'режим IE: не записан - ' + E.Message;
    end;
  finally
    Reg.Free;
  end;
end;

function TempFolder: string;
var
  Buf: array[0..MAX_PATH] of Char;
begin
  if GetTempPath(MAX_PATH, Buf) > 0 then
    Result := IncludeTrailingPathDelimiter(Buf)
  else
    Result := ExtractFilePath(ParamStr(0));
end;

// <base href="AUrl"> в <head> страницы (после <head ...>); нет <head> -
// после <html ...>; нет и его - в начало (после BOM)
function InsertBaseHref(const AHtml, AUrl: string): string;
var
  Lower, BaseTag: string;
  TagAt, CloseAt, InsertAt: Integer;
begin
  BaseTag := '<base href="' + AUrl + '">';
  Lower := LowerCase(AHtml);
  InsertAt := 0;
  TagAt := Pos('<head', Lower);
  if (TagAt > 0) and (TagAt + 5 <= Length(Lower)) and
     (Lower[TagAt + 5] in ['>', ' ', #9, #13, #10]) then
  begin
    CloseAt := TagAt;
    while (CloseAt <= Length(Lower)) and (Lower[CloseAt] <> '>') do
      Inc(CloseAt);
    InsertAt := CloseAt + 1;
  end
  else
  begin
    TagAt := Pos('<html', Lower);
    if TagAt > 0 then
    begin
      CloseAt := TagAt;
      while (CloseAt <= Length(Lower)) and (Lower[CloseAt] <> '>') do
        Inc(CloseAt);
      InsertAt := CloseAt + 1;
    end;
  end;
  if InsertAt = 0 then
  begin
    if Copy(AHtml, 1, 3) = #$EF#$BB#$BF then
      InsertAt := 4
    else
      InsertAt := 1;
  end;
  Result := Copy(AHtml, 1, InsertAt - 1) + BaseTag +
            Copy(AHtml, InsertAt, MaxInt);
end;

// Вариант - пустая ссылка на объект (getElementById ничего не нашёл)
function VarIsNoObject(const AValue: OleVariant): Boolean;
begin
  Result := VarIsNull(AValue) or VarIsEmpty(AValue) or
            ((TVarData(AValue).VType = varDispatch) and
             (TVarData(AValue).VDispatch = nil));
end;

// Текст -> RTF (кириллица - \'xx в cp1251): сообщение в просмотре
function PlainToRtf(const AText: string): string;
var
  Idx: Integer;
  Ch: Char;
begin
  Result := '{\rtf1\ansi\ansicpg1251\deff0{\fonttbl{\f0\fswiss Tahoma;}}' +
            '\f0\fs20 ';
  for Idx := 1 to Length(AText) do
  begin
    Ch := AText[Idx];
    case Ch of
      #13: ;
      #10: Result := Result + '\par ';
      '\', '{', '}': Result := Result + '\' + Ch;
    else
      if Ord(Ch) >= $80 then
        Result := Result + '\''' + LowerCase(IntToHex(Ord(Ch), 2))
      else
        Result := Result + Ch;
    end;
  end;
  Result := Result + '}';
end;

function FmtPlainToRtf(const AText: string): string;
begin
  Result := PlainToRtf(AText);
end;

function FmtIsViewControl(AControl: TControl): Boolean;
begin
  Result := (AControl is TRtfViewEdit) or (AControl is TWebBrowser);
end;

function FmtRvfHelperPath: string;
var
  ExeDir: string;
  Candidates: array[0..5] of string;
  CandIdx: Integer;
begin
  ExeDir := ExtractFilePath(ParamStr(0));
  Candidates[0] := ExeDir + RvfHelperName;
  Candidates[1] := ExeDir + 'tools\' + RvfHelperName;
  Candidates[2] := ExeDir + 'tools\rvf2rtf\' + RvfHelperName;
  Candidates[3] := ExeDir + '..\' + RvfHelperName;
  Candidates[4] := ExeDir + '..\tools\' + RvfHelperName;
  Candidates[5] := ExeDir + '..\tools\rvf2rtf\' + RvfHelperName;
  for CandIdx := Low(Candidates) to High(Candidates) do
    if FileExists(Candidates[CandIdx]) then
    begin
      Result := ExpandFileName(Candidates[CandIdx]);
      Exit;
    end;
  Result := '';
end;

// ---------------------------------------------------------------------------
//  TWebPreview
// ---------------------------------------------------------------------------

constructor TWebPreview.Create(AHost: TWinControl);
begin
  inherited Create;
  FHost := AHost;
  FScrollPos := TStringList.Create;
  FTempBase := TempFolder + 'unide_fmt_' + IntToStr(GetCurrentProcessId);
  FMsgWnd := Classes.AllocateHWnd(MsgWndProc);
end;

destructor TWebPreview.Destroy;
begin
  if FMsgWnd <> 0 then
    Classes.DeallocateHWnd(FMsgWnd);
  FreeAndNil(FBrowser);
  if (FTempPage <> '') and FileExists(FTempPage) then
    SysUtils.DeleteFile(FTempPage);
  FScrollPos.Free;
  inherited Destroy;
end;

// Браузер создаётся при первом показе: без просмотра IE не грузится
function TWebPreview.EnsureBrowser: Boolean;
begin
  Result := FBrowser <> nil;
  if Result then
    Exit;
  Log(EnsureBrowserEmulation);
  try
    FBrowser := TWebBrowser.Create(nil);
    // У TWebBrowser свои свойства Parent и Visible (свойства IWebBrowser2) -
    // поэтому через TWinControl: иначе окно контрола не привязывается и не
    // прячется
    TWinControl(FBrowser).Parent := FHost;
    TWinControl(FBrowser).Visible := False;
    FBrowser.SetBounds(0, 0, FHost.ClientWidth, FHost.ClientHeight);
    FBrowser.Anchors := [akLeft, akTop, akRight, akBottom];
    FBrowser.Silent := True;                 // без окон ошибок скриптов
    FBrowser.RegisterAsDropTarget := False;  // файл, брошенный мышью, не открывать
    FBrowser.OnBeforeNavigate2 := BrowserBeforeNavigate2;
    FBrowser.OnDocumentComplete := BrowserDocumentComplete;
    Result := True;
  except
    on E: Exception do
    begin
      FLastError := 'Встроенный Internet Explorer не создан: ' + E.Message;
      FreeAndNil(FBrowser);
    end;
  end;
end;

function TWebPreview.IsShown: Boolean;
begin
  Result := (FBrowser <> nil) and TWinControl(FBrowser).Visible;
end;

// Прокрутка страницы: в режиме IE=edge - у documentElement, в старых
// режимах - у body
function TWebPreview.ReadScroll: Integer;
var
  Doc: OleVariant;
begin
  Result := 0;
  if (FBrowser = nil) or (FBrowser.Document = nil) then
    Exit;
  try
    Doc := FBrowser.Document;
    Result := Doc.documentElement.scrollTop;
    if Result = 0 then
      Result := Doc.body.scrollTop;
  except
    Result := 0;
  end;
end;

procedure TWebPreview.RememberScroll;
begin
  if (FSourceFile = '') or not IsShown then
    Exit;
  FScrollPos.Values[ScrollKey(FSourceFile)] := IntToStr(ReadScroll);
end;

// Временная страница с расширением AExt ('.html', '.mht'); прежняя -
// удаляется (расширение могло быть другим)
function TWebPreview.WriteTemp(const ABytes, AExt: string): Boolean;
var
  Stream: TFileStream;
  NewPage: string;
begin
  Result := False;
  NewPage := FTempBase + AExt;
  if (FTempPage <> '') and (FTempPage <> NewPage) and FileExists(FTempPage) then
    SysUtils.DeleteFile(FTempPage);
  try
    Stream := TFileStream.Create(NewPage, fmCreate);
    try
      if ABytes <> '' then
        Stream.WriteBuffer(ABytes[1], Length(ABytes));
    finally
      Stream.Free;
    end;
    FTempPage := NewPage;
    Result := True;
  except
    on E: Exception do
      FLastError := 'Не записана страница ' + NewPage + ': ' + E.Message;
  end;
end;

// Открыть APage (файл на диске) как просмотр файла вкладки ASourceFile.
// Navigate - путём, а не адресом file:///: IE сам переводит его в адрес,
// и кириллица в пути не портится
function TWebPreview.OpenPage(const APage, ASourceFile: string): Boolean;
var
  Flags: OleVariant;
begin
  Result := False;
  FSourceFile := ASourceFile;
  FCurrentPage := APage;
  FPendingScroll := StrToIntDef(FScrollPos.Values[ScrollKey(FSourceFile)], 0);
  try
    TWinControl(FBrowser).Visible := True;
    FBrowser.BringToFront;
    Flags := NavFlagsReload;
    FExpectOwn := True;
    FBrowser.Navigate(WideString(APage), Flags);
    Result := True;
  except
    on E: Exception do
      FLastError := 'Просмотр не открылся: ' + E.Message;
  end;
end;

function TWebPreview.ShowMarkdown(const AUtf8Text, ASourceFile: string;
  ABack, AFore: TColor): Boolean;
var
  Html, BaseUrl, Title: string;
begin
  Result := False;
  FLastError := '';
  if not EnsureBrowser then
    Exit;
  RememberScroll;
  BaseUrl := '';
  Title := 'Markdown';
  if ASourceFile <> '' then
  begin
    BaseUrl := PathToFileUrl(ExtractFilePath(ASourceFile), True);
    // Страница - в UTF-8
    Title := AnsiToUtf8(ExtractFileName(ASourceFile));
  end;
  Html := #$EF#$BB#$BF +
          MdToHtmlPage(AUtf8Text, Title, BaseUrl, MdColorsFor(ABack, AFore));
  if not WriteTemp(Html, '.html') then
    Exit;
  Result := OpenPage(FTempPage, ASourceFile);
end;

function TWebPreview.ShowFile(const AFileName: string): Boolean;
begin
  Result := False;
  FLastError := '';
  if not EnsureBrowser then
    Exit;
  RememberScroll;
  Result := OpenPage(AFileName, AFileName);
end;

function TWebPreview.ShowEdited(const ABytes, ASourceFile: string;
  AKind: TFmtKind): Boolean;
var
  Page: string;
begin
  Result := False;
  FLastError := '';
  if not EnsureBrowser then
    Exit;
  RememberScroll;
  if AKind = fkMht then
    // Картинки и стили - внутри архива, <base> не нужен (и испортил бы
    // MIME-разметку)
    Result := WriteTemp(ABytes, '.mht')
  else
  begin
    Page := ABytes;
    if ASourceFile <> '' then
      Page := InsertBaseHref(Page,
        PathToFileUrl(ExtractFilePath(ASourceFile), True));
    Result := WriteTemp(Page, '.html');
  end;
  if Result then
    Result := OpenPage(FTempPage, ASourceFile);
end;

procedure TWebPreview.HideView;
begin
  if FBrowser = nil then
    Exit;
  RememberScroll;
  TWinControl(FBrowser).Visible := False;
end;

// ExecWB: OLECMDID_COPY = 12, OLECMDID_SELECTALL = 17,
// OLECMDEXECOPT_DODEFAULT = 0. Команда недоступна (нечего копировать) -
// исключение, его не показываем
procedure TWebPreview.CopySelection;
begin
  if not IsShown then
    Exit;
  try
    FBrowser.ExecWB(12, 0);
  except
  end;
end;

procedure TWebPreview.SelectAll;
begin
  if not IsShown then
    Exit;
  try
    FBrowser.ExecWB(17, 0);
  except
  end;
end;

function TWebPreview.OwnsWindow(AWnd: HWND): Boolean;
var
  BrowserWnd: HWND;
begin
  Result := False;
  if (AWnd = 0) or not IsShown or not TWinControl(FBrowser).HandleAllocated then
    Exit;
  BrowserWnd := TWinControl(FBrowser).Handle;
  Result := (AWnd = BrowserWnd) or IsChild(BrowserWnd, AWnd);
end;

procedure TWebPreview.FocusView;
begin
  try
    if IsShown and FBrowser.CanFocus then
      FBrowser.SetFocus;
  except
    // фокус - не главное: просмотр уже на экране
  end;
end;

procedure TWebPreview.BrowserDocumentComplete(Sender: TObject;
  const ADisp: IDispatch; var AUrl: OleVariant);
var
  Doc: OleVariant;
begin
  if not IsTopFrame(ADisp) then
    Exit;
  LogImages;
  if FPendingScroll <= 0 then
    Exit;
  try
    Doc := FBrowser.Document;
    Doc.parentWindow.scrollTo(0, FPendingScroll);
  except
    // страница без окна (не загрузилась) - остаётся вверху
  end;
  FPendingScroll := 0;
end;

// Картинки загруженной страницы - в журнал (OnLog): адрес страницы, режим
// IE, сколько картинок и какие не показаны, с адресом каждой. К
// DocumentComplete картинки уже загружены или не загрузились. Не
// показанная - naturalWidth = 0 (есть с IE9; в режиме ниже 9 его нет -
// тогда в журнал идёт адрес каждой картинки)
procedure TWebPreview.LogImages;
var
  Doc, Images, Img: OleVariant;
  ImgIdx, ImgCount, BrokenCount, ImgWidth: Integer;
  DocMode, ImgSrc: string;
begin
  if not Assigned(FOnLog) or (FBrowser = nil) or (FBrowser.Document = nil) then
    Exit;
  try
    Doc := FBrowser.Document;
    Images := Doc.images;
    ImgCount := Images.length;
  except
    Exit;
  end;
  try
    DocMode := VarToStr(Doc.documentMode);
  except
    DocMode := '?';
  end;
  Log('страница: ' + VarToStr(Doc.URL) + ', режим IE ' + DocMode +
      ', картинок: ' + IntToStr(ImgCount));
  BrokenCount := 0;
  for ImgIdx := 0 to ImgCount - 1 do
    try
      Img := Images.item(ImgIdx);
      ImgSrc := VarToStr(Img.src);
      try
        ImgWidth := Img.naturalWidth;
      except
        // Режим IE ниже 9: naturalWidth нет, а width у значка битой
        // картинки не 0 - загрузилась ли, не узнать; адрес - в журнал
        ImgWidth := -1;
      end;
      if ImgWidth = 0 then
      begin
        Inc(BrokenCount);
        Log('картинка не показана: ' + ImgSrc);
      end
      else if ImgWidth < 0 then
        Log('картинка (режим IE ' + DocMode + ', показана ли - не узнать): ' +
            ImgSrc);
    except
      // элемент без свойств картинки - пропустить
    end;
  if BrokenCount > 0 then
    Log('не показано картинок: ' + IntToStr(BrokenCount) + ' из ' +
        IntToStr(ImgCount));
end;

// Событие - от самой страницы, а не от кадра (frame, iframe) внутри неё
function TWebPreview.IsTopFrame(const ADisp: IDispatch): Boolean;
begin
  Result := True;
  if ADisp = nil then
    Exit;
  try
    Result := (ADisp as IUnknown) = (FBrowser.ControlInterface as IUnknown);
  except
    Result := True;
  end;
end;

// Своя страница: её первая загрузка после Navigate и переходы по меткам.
// Временная страница узнаётся по имени файла (unide_fmt_<pid>.*) в адресе
// любого вида - file:///, путь, короткие (ADMINI~1) или длинные имена
// папок; файл с диска - по полному пути. Первый переход после Navigate -
// своя страница, какой бы ни был адрес. Наружу (ShellExecute) своя
// страница не отдаётся никогда.
function TWebPreview.IsOwnPage(const AUrl, ALocalPath: string): Boolean;
var
  TempName: string;
begin
  Result := FExpectOwn;
  if Result or (FCurrentPage = '') then
    Exit;
  if FCurrentPage = FTempPage then
  begin
    TempName := LowerCase(ExtractFileName(FTempPage));
    Result := (Pos(TempName, LowerCase(AUrl)) > 0) or
              ((ALocalPath <> '') and
               (CompareText(ExtractFileName(ALocalPath), TempName) = 0));
  end
  else
    Result := (ALocalPath <> '') and
              (CompareText(ExpandFileName(ALocalPath),
                           ExpandFileName(FCurrentPage)) = 0);
end;

// Метка (#раздел) правленого HTML: <base href> на папку файла делает из
// неё адрес папки или файла вкладки с #раздел - IE ушёл бы со страницы
function TWebPreview.IsMovedAnchor(const AUrl, ALocalPath: string;
  out AAnchor: string): Boolean;
var
  SourceDir: string;
begin
  AAnchor := '';
  Result := False;
  if (Pos('#', AUrl) = 0) or (ALocalPath = '') or (FSourceFile = '') then
    Exit;
  SourceDir := ExcludeTrailingPathDelimiter(ExtractFilePath(
    ExpandFileName(FSourceFile)));
  Result := (CompareText(ExcludeTrailingPathDelimiter(
               ExpandFileName(ALocalPath)), SourceDir) = 0) or
            (CompareText(ExpandFileName(ALocalPath),
                         ExpandFileName(FSourceFile)) = 0);
  if Result then
    AAnchor := Copy(AUrl, Pos('#', AUrl), MaxInt);
end;

// Прокрутить страницу к метке AAnchor ('#раздел'): элемент с таким id,
// иначе первый с таким name (<a name="...">)
procedure TWebPreview.JumpToAnchor(const AAnchor: string);
var
  Doc, Elem, Elems: OleVariant;
  AnchorName: WideString;
begin
  if (FBrowser = nil) or (FBrowser.Document = nil) then
    Exit;
  AnchorName := UrlAnchor(AAnchor);
  if AnchorName = '' then
    Exit;
  try
    Doc := FBrowser.Document;
    Elem := Doc.getElementById(AnchorName);
    if VarIsNoObject(Elem) then
    begin
      Elems := Doc.getElementsByName(AnchorName);
      if Elems.length > 0 then
        Elem := Elems.item(0);
    end;
    if not VarIsNoObject(Elem) then
      Elem.scrollIntoView(True);
  except
    // метки нет на странице - остаёмся на месте
  end;
end;

procedure TWebPreview.BrowserBeforeNavigate2(Sender: TObject;
  const ADisp: IDispatch; var AUrl: OleVariant; var AFlags: OleVariant;
  var ATargetFrameName: OleVariant; var APostData: OleVariant;
  var AHeaders: OleVariant; var ACancel: WordBool);
var
  Url, LocalPath, Anchor: string;
begin
  Url := VarToStr(AUrl);
  // about:blank, страницы ошибок самого IE (res://ieframe.dll/...), части
  // архива .mht (mhtml:file://...!...)
  if (Url = '') or (CompareText(Copy(Url, 1, 6), 'about:') = 0) or
     (CompareText(Copy(Url, 1, 4), 'res:') = 0) or
     (CompareText(Copy(Url, 1, 6), 'mhtml:') = 0) then
  begin
    Log('браузер: ' + Url + ' - внутри');
    Exit;
  end;
  // Кадр страницы грузит своё содержимое - не мешать
  if not IsTopFrame(ADisp) then
  begin
    Log('браузер: ' + Url + ' - кадр страницы');
    Exit;
  end;
  LocalPath := UrlToPath(Url);
  if IsOwnPage(Url, LocalPath) then
  begin
    FExpectOwn := False;
    Log('браузер: ' + Url + ' - своя страница');
    Exit;
  end;

  ACancel := True;
  if IsMovedAnchor(Url, LocalPath, Anchor) then
  begin
    Log('браузер: ' + Url + ' - метка на странице');
    FPendingAnchor := Anchor;
    PostMessage(FMsgWnd, WM_FMT_ANCHOR, 0, 0);
  end
  else if (LocalPath <> '') and IsIdeFile(LocalPath) and
          Assigned(FOnOpenFile) then
  begin
    Log('браузер: ' + Url + ' - вкладкой: ' + LocalPath);
    FPendingOpen := LocalPath;
    PostMessage(FMsgWnd, WM_FMT_OPENFILE, 0, 0);
  end
  else if LocalPath <> '' then
  begin
    Log('браузер: ' + Url + ' - программой Windows: ' + LocalPath);
    ShellExecute(0, 'open', PChar(LocalPath), nil, nil, SW_SHOWNORMAL);
  end
  else
  begin
    Log('браузер: ' + Url + ' - программой Windows');
    ShellExecute(0, 'open', PChar(Url), nil, nil, SW_SHOWNORMAL);
  end;
end;

procedure TWebPreview.Log(const AText: string);
begin
  if Assigned(FOnLog) then
    FOnLog(AText);
end;

procedure TWebPreview.MsgWndProc(var Message: TMessage);
var
  FileName, Anchor: string;
begin
  if Message.Msg = WM_FMT_OPENFILE then
  begin
    FileName := FPendingOpen;
    FPendingOpen := '';
    if (FileName <> '') and Assigned(FOnOpenFile) then
      FOnOpenFile(FileName);
    Message.Result := 0;
  end
  else if Message.Msg = WM_FMT_ANCHOR then
  begin
    Anchor := FPendingAnchor;
    FPendingAnchor := '';
    JumpToAnchor(Anchor);
    Message.Result := 0;
  end
  else
    Message.Result := DefWindowProc(FMsgWnd, Message.Msg, Message.WParam,
      Message.LParam);
end;

// ---------------------------------------------------------------------------
//  TRtfViewEdit, TRtfPreview
// ---------------------------------------------------------------------------

var
  RtfEditLib: HMODULE = 0;
  RtfEditClass: string = '';

procedure TRtfViewEdit.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  // Библиотека грузится один раз и не выгружается: при выходе окна
  // просмотра уничтожаются позже finalization этого модуля (вместе с
  // главной формой), и выгруженная библиотека увела бы из-под них
  // оконную процедуру. Выгрузит её сам выход из программы
  if RtfEditClass = '' then
  begin
    RtfEditLib := LoadLibrary('msftedit.dll');
    if RtfEditLib <> 0 then
      RtfEditClass := 'RICHEDIT50W'
    else
    begin
      RtfEditLib := LoadLibrary('riched20.dll');
      if RtfEditLib <> 0 then
        RtfEditClass := 'RichEdit20A'
      else
        RtfEditClass := '-';   // остаётся RichEdit 1.0 из VCL
    end;
  end;
  if RtfEditClass <> '-' then
    CreateSubClass(Params, PChar(RtfEditClass));
end;

type
  // EDITSTREAM из richedit.h
  TRtfStreamCallback = function(ACookie: Longint; ABuffer: PByte;
    ACount: Longint; var ADone: Longint): Longint; stdcall;
  TRtfEditStream = record
    Cookie: Longint;
    Error: Longint;
    Callback: TRtfStreamCallback;
  end;
  // Чтение строки по частям для EM_STREAMIN
  TRtfStreamSource = record
    Data: string;
    ReadPos: Integer;   // с 1
  end;
  PRtfStreamSource = ^TRtfStreamSource;

const
  EM_STREAMIN_ = WM_USER + 73;
  SF_TEXT_ = $0001;
  SF_RTF_ = $0002;

function RtfStreamRead(ACookie: Longint; ABuffer: PByte; ACount: Longint;
  var ADone: Longint): Longint; stdcall;
var
  Source: PRtfStreamSource;
  Left: Integer;
begin
  Source := PRtfStreamSource(ACookie);
  Left := Length(Source^.Data) - Source^.ReadPos + 1;
  if Left > ACount then
    Left := ACount;
  if Left < 0 then
    Left := 0;
  if Left > 0 then
    Move(Source^.Data[Source^.ReadPos], ABuffer^, Left);
  Inc(Source^.ReadPos, Left);
  ADone := Left;
  Result := 0;
end;

constructor TRtfPreview.Create(AHost: TWinControl; APopup: TPopupMenu);
begin
  inherited Create;
  FHost := AHost;
  FPopup := APopup;
  FScrollLine := TStringList.Create;
  FPaperColor := clWhite;
  FWrapLines := True;
end;

destructor TRtfPreview.Destroy;
begin
  FreeAndNil(FEdit);
  FScrollLine.Free;
  inherited Destroy;
end;

function TRtfPreview.EnsureEdit: Boolean;
begin
  Result := FEdit <> nil;
  if Result then
    Exit;
  try
    FEdit := TRtfViewEdit.Create(nil);
    FEdit.Visible := False;
    FEdit.Parent := FHost;
    FEdit.SetBounds(0, 0, FHost.ClientWidth, FHost.ClientHeight);
    FEdit.Anchors := [akLeft, akTop, akRight, akBottom];
    FEdit.BorderStyle := bsNone;
    FEdit.ReadOnly := True;
    FEdit.WordWrap := FWrapLines;
    if FWrapLines then
      FEdit.ScrollBars := ssVertical
    else
      FEdit.ScrollBars := ssBoth;
    FEdit.HideSelection := False;
    FEdit.PlainText := False;
    // Лист по умолчанию белый: цвета текста задаёт документ (см. в начале
    // модуля)
    FEdit.Color := FPaperColor;
    FEdit.Font.Name := 'Tahoma';
    FEdit.Font.Size := 10;
    FEdit.Font.Color := clBlack;
    FEdit.PopupMenu := FPopup;
    FEdit.TabStop := False;
    FEdit.OnMouseDown := EditMouseDown;
    Result := True;
  except
    on E: Exception do
    begin
      FLastError := 'Окно RTF не создано: ' + E.Message;
      FreeAndNil(FEdit);
    end;
  end;
end;

function TRtfPreview.IsShown: Boolean;
begin
  Result := (FEdit <> nil) and FEdit.Visible;
end;

procedure TRtfPreview.RememberScroll;
begin
  if (FSourceFile = '') or not IsShown or not FEdit.HandleAllocated then
    Exit;
  FScrollLine.Values[ScrollKey(FSourceFile)] :=
    IntToStr(SendMessage(FEdit.Handle, EM_GETFIRSTVISIBLELINE, 0, 0));
end;

procedure TRtfPreview.Log(const AText: string);
begin
  if Assigned(FOnLog) then
    FOnLog(AText);
end;

// Текст в окно одним EM_STREAMIN: RTF - как RTF, иное - простым текстом
function TRtfPreview.StreamIn(const ABytes: string): Boolean;
var
  Source: TRtfStreamSource;
  Stream: TRtfEditStream;
  StreamFormat: Integer;
begin
  Source.Data := ABytes;
  Source.ReadPos := 1;
  Stream.Cookie := Longint(@Source);
  Stream.Error := 0;
  Stream.Callback := RtfStreamRead;
  if Copy(TrimLeft(ABytes), 1, 5) = '{\rtf' then
    StreamFormat := SF_RTF_
  else
    StreamFormat := SF_TEXT_;
  // ReadOnly на загрузку не влияет: EM_STREAMIN - программная запись
  SendMessage(FEdit.Handle, EM_STREAMIN_, StreamFormat, Longint(@Stream));
  Result := Stream.Error = 0;
  if not Result then
    FLastError := 'RichEdit не загрузил текст (код ' +
                  IntToStr(Stream.Error) + ')';
end;

function TRtfPreview.ShowRtf(const ABytes, ASourceFile: string): Boolean;
var
  TopLine: Integer;
begin
  Result := False;
  FLastError := '';
  if not EnsureEdit then
    Exit;
  RememberScroll;
  FSourceFile := ASourceFile;
  FEdit.Visible := True;
  FEdit.BringToFront;
  FEdit.HandleNeeded;
  SendMessage(FEdit.Handle, WM_SETREDRAW, 0, 0);
  try
    Result := StreamIn(ABytes);
    SendMessage(FEdit.Handle, EM_SETSEL, 0, 0);
    TopLine := StrToIntDef(FScrollLine.Values[ScrollKey(FSourceFile)], 0);
    if TopLine > 0 then
      SendMessage(FEdit.Handle, EM_LINESCROLL, 0, TopLine);
  finally
    SendMessage(FEdit.Handle, WM_SETREDRAW, 1, 0);
    FEdit.Invalidate;
  end;
end;

function TRtfPreview.ShowRtfFile(const AFileName: string): Boolean;
var
  Bytes: string;
begin
  Result := False;
  if not ReadFileBytes(AFileName, Bytes) then
  begin
    FLastError := 'Файл не прочитан: ' + AFileName;
    Exit;
  end;
  Result := ShowRtf(Bytes, AFileName);
end;

// rvf2rtf.exe "файл.rvf" "файл.rtf" без окна; ждать до RvfHelperTimeout.
// Коды выхода помощника: 0 - готово, 1 - не те параметры, 2 - RVF не
// прочитан, 3 - RTF не записан
function TRtfPreview.RunRvf2Rtf(const AHelper, ARvfFile, ARtfFile: string;
  out AError: string): Boolean;
var
  StartInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
  CmdLine: string;
  WaitResult, ExitCodeValue: DWORD;
begin
  Result := False;
  AError := '';
  CmdLine := '"' + AHelper + '" "' + ARvfFile + '" "' + ARtfFile + '"';
  FillChar(StartInfo, SizeOf(StartInfo), 0);
  StartInfo.cb := SizeOf(StartInfo);
  StartInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartInfo.wShowWindow := SW_HIDE;
  FillChar(ProcInfo, SizeOf(ProcInfo), 0);
  UniqueString(CmdLine);   // CreateProcess может писать в строку
  if not CreateProcess(nil, PChar(CmdLine), nil, nil, False, 0, nil,
                       PChar(ExtractFilePath(AHelper)), StartInfo,
                       ProcInfo) then
  begin
    AError := 'не запустился: ' + SysErrorMessage(GetLastError);
    Exit;
  end;
  try
    WaitResult := WaitForSingleObject(ProcInfo.hProcess, RvfHelperTimeout);
    if WaitResult <> WAIT_OBJECT_0 then
    begin
      TerminateProcess(ProcInfo.hProcess, 1);
      AError := 'не закончил работу за ' +
                IntToStr(RvfHelperTimeout div 1000) + ' с';
      Exit;
    end;
    ExitCodeValue := 0;
    GetExitCodeProcess(ProcInfo.hProcess, ExitCodeValue);
    case ExitCodeValue of
      0: Result := FileExists(ARtfFile);
      1: AError := 'не понял параметры (код 1)';
      2: AError := 'не прочитал RVF (код 2)';
      3: AError := 'не записал RTF (код 3)';
    else
      AError := 'завершился с кодом ' + IntToStr(ExitCodeValue);
    end;
    if (ExitCodeValue = 0) and not Result then
      AError := 'не создал ' + ARtfFile;
  finally
    CloseHandle(ProcInfo.hThread);
    CloseHandle(ProcInfo.hProcess);
  end;
end;

function TRtfPreview.ShowRvfFile(const AFileName: string): Boolean;
var
  Helper, RtfFile, Bytes, ErrText: string;
  OldCursor: TCursor;
begin
  Helper := FmtRvfHelperPath;
  if Helper = '' then
  begin
    Log('RVF: ' + RvfHelperName + ' не найден');
    Result := ShowRtf(PlainToRtf(
      'Просмотр RVF: не найден ' + RvfHelperName + '.'#10#10 +
      'RVF - формат TRichView. unIDE переводит его в RTF помощником ' +
      RvfHelperName + ', который собирается в Delphi с установленным ' +
      'TRichView: исходник - tools\rvf2rtf\rvf2rtf.dpr.'#10#10 +
      'Собранный ' + RvfHelperName + ' положите рядом с exe unIDE ' +
      '(или в его папку tools).'), AFileName);
    Exit;
  end;

  RtfFile := TempFolder + 'unide_rvf_' + IntToStr(GetCurrentProcessId) +
             '.rtf';
  if FileExists(RtfFile) then
    SysUtils.DeleteFile(RtfFile);
  OldCursor := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  try
    if not RunRvf2Rtf(Helper, AFileName, RtfFile, ErrText) then
    begin
      Log('RVF: ' + Helper + ' ' + ErrText);
      Result := ShowRtf(PlainToRtf('Просмотр RVF: ' + RvfHelperName + ' ' +
        ErrText + '.'#10#10 + 'Файл: ' + AFileName + #10 +
        'Помощник: ' + Helper), AFileName);
      Exit;
    end;
  finally
    Screen.Cursor := OldCursor;
  end;
  Log('RVF: ' + AFileName + ' -> ' + RtfFile);
  if not ReadFileBytes(RtfFile, Bytes) then
  begin
    FLastError := 'Не прочитан ' + RtfFile;
    Result := False;
    Exit;
  end;
  SysUtils.DeleteFile(RtfFile);
  Result := ShowRtf(Bytes, AFileName);
end;

procedure TRtfPreview.SetPaperColor(AColor: TColor);
begin
  FPaperColor := AColor;
  if FEdit <> nil then
    FEdit.Color := AColor;
end;

procedure TRtfPreview.SetWrapLines(AValue: Boolean);
begin
  FWrapLines := AValue;
  if FEdit <> nil then
  begin
    FEdit.WordWrap := AValue;
    if AValue then
      FEdit.ScrollBars := ssVertical
    else
      FEdit.ScrollBars := ssBoth;
  end;
end;

// EM_CHARFROMPOS у RichEdit: lParam - адрес точки (POINTL), а не
// координаты в самом lParam, как у простого поля
procedure TRtfPreview.EditMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
const
  EM_EXLINEFROMCHAR_ = WM_USER + 54;
var
  ClickPt: TPoint;
  CharIdx, LineIdx, LineStart: Integer;
begin
  if (Button <> mbLeft) or not Assigned(FOnClickPos) or
     not FEdit.HandleAllocated then
    Exit;
  ClickPt := Point(X, Y);
  CharIdx := SendMessage(FEdit.Handle, EM_CHARFROMPOS, 0, Longint(@ClickPt));
  if CharIdx < 0 then
    CharIdx := 0;
  LineIdx := SendMessage(FEdit.Handle, EM_EXLINEFROMCHAR_, 0, CharIdx);
  LineStart := SendMessage(FEdit.Handle, EM_LINEINDEX, LineIdx, 0);
  if LineStart < 0 then
    LineStart := CharIdx;
  FOnClickPos(Self, LineIdx, CharIdx - LineStart, TopLine);
end;

function TRtfPreview.TopLine: Integer;
begin
  Result := 0;
  if (FEdit <> nil) and FEdit.HandleAllocated then
    Result := SendMessage(FEdit.Handle, EM_GETFIRSTVISIBLELINE, 0, 0);
end;

procedure TRtfPreview.SetTopLine(ATopLine: Integer);
var
  CurTop: Integer;
begin
  if (FEdit = nil) or not FEdit.HandleAllocated then
    Exit;
  CurTop := SendMessage(FEdit.Handle, EM_GETFIRSTVISIBLELINE, 0, 0);
  if ATopLine <> CurTop then
    SendMessage(FEdit.Handle, EM_LINESCROLL, 0, ATopLine - CurTop);
end;

function TRtfPreview.OwnsWindow(AWnd: HWND): Boolean;
begin
  Result := (AWnd <> 0) and IsShown and FEdit.HandleAllocated and
            (AWnd = FEdit.Handle);
end;

procedure TRtfPreview.HideView;
begin
  if FEdit = nil then
    Exit;
  RememberScroll;
  FEdit.Visible := False;
end;

procedure TRtfPreview.FocusView;
begin
  if IsShown and FEdit.CanFocus then
    FEdit.SetFocus;
end;

procedure TRtfPreview.CopySelection;
begin
  if IsShown then
    FEdit.CopyToClipboard;
end;

procedure TRtfPreview.SelectAll;
begin
  if IsShown then
    FEdit.SelectAll;
end;

end.
