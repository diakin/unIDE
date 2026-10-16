unit MdView;

// ---------------------------------------------------------------------------
//  Просмотр Markdown во вкладке редактора: текст .md переводится в HTML
//  (MdHtml) и показывается встроенным Internet Explorer (TWebBrowser,
//  SHDocVw) поверх редактора. F12 во вкладке .md - текст / просмотр.
//
//  Страница пишется во временный файл (%TEMP%\unide_md_<pid>.html, UTF-8
//  с BOM) и открывается из него: так у неё зона "этот компьютер", и
//  картинки рядом с .md (file:///...) показываются. В странице стоит
//  X-UA-Compatible: IE=edge - без него встроенный IE рисует в режиме IE7.
//
//  Ссылки со страницы внутри браузера не открываются (BeforeNavigate2):
//    - метка на этой же странице (#раздел) - переход по странице;
//    - файл на диске, который можно править, - в unIDE (OnOpenFile), не
//      сразу, а сообщением: событие приходит изнутри IE, и переключение
//      вкладки отсюда снова звало бы Navigate;
//    - остальное (http, mailto, картинки, папки) - программой Windows.
//
//  Прокрутка страницы запоминается по файлу .md: после правки текста и
//  F12 страница открывается на том же месте.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, ShellAPI,
  Variants, ComObj, SHDocVw, MdHtml;

type
  TMdOpenFileEvent = procedure(const AFileName: string) of object;
  TMdLogEvent = procedure(const AText: string) of object;

  TMdPreview = class
  private
    FHost: TWinControl;
    FBrowser: TWebBrowser;
    FMsgWnd: HWND;            // окно для отложенного открытия файла
    FHtmlFile: string;        // временная страница
    FSourceFile: string;      // .md, который сейчас показан
    FScrollPos: TStringList;  // файл .md = прокрутка страницы, пикселей
    FPendingScroll: Integer;  // прокрутка после загрузки страницы
    FPendingOpen: string;     // файл для OnOpenFile
    FLastError: string;
    FOnOpenFile: TMdOpenFileEvent;
    FOnLog: TMdLogEvent;
    // Navigate своей страницы вызван, её BeforeNavigate2 ещё не приходил
    FExpectOwn: Boolean;
    function IsOwnPage(const AUrl, ALocalPath: string): Boolean;
    procedure Log(const AText: string);
    function EnsureBrowser: Boolean;
    function ReadScroll: Integer;
    procedure RememberScroll;
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
    // Показать текст AUtf8Text (UTF-8) файла ASourceFile в цветах
    // редактора. False - не вышло, причина в LastError
    function ShowText(const AUtf8Text, ASourceFile: string;
      ABack, AFore: TColor): Boolean;
    procedure HideView;
    function IsShown: Boolean;
    procedure FocusView;
    // Копировать выделенное на странице / выделить всю страницу (Ctrl+C,
    // Ctrl+A: эти клавиши перехватывает меню формы, до IE они не доходят)
    procedure CopySelection;
    procedure SelectAll;
    property SourceFile: string read FSourceFile;
    property LastError: string read FLastError;
    property OnOpenFile: TMdOpenFileEvent read FOnOpenFile write FOnOpenFile;
    // Журнал переходов браузера (адрес и что с ним сделано)
    property OnLog: TMdLogEvent read FOnLog write FOnLog;
  end;

// .md, .markdown, .mdown, .mkd
function IsMarkdownFile(const AFileName: string): Boolean;
// Файл с диска в UTF-8: BOM убирается, UTF-8 остаётся как есть, ANSI
// переводится. False - файл не прочитан
function MdFileToUtf8(const AFileName: string; out AText: string): Boolean;
// Цвета страницы по фону и тексту редактора
function MdColorsFor(ABack, AFore: TColor): TMdColors;

implementation

const
  WM_MD_OPENFILE = WM_USER + 1;
  // BrowserNavConstants: navNoHistory or navNoReadFromCache
  NavFlagsReload = $02 or $04;

function IsMarkdownFile(const AFileName: string): Boolean;
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(AFileName));
  Result := (Ext = '.md') or (Ext = '.markdown') or (Ext = '.mdown') or
            (Ext = '.mkd');
end;

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

function MdFileToUtf8(const AFileName: string; out AText: string): Boolean;
var
  Stream: TFileStream;
  Raw: string;
begin
  Result := False;
  AText := '';
  try
    Stream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
    try
      SetLength(Raw, Stream.Size);
      if Stream.Size > 0 then
        Stream.ReadBuffer(Raw[1], Stream.Size);
    finally
      Stream.Free;
    end;
  except
    Exit;
  end;
  if Copy(Raw, 1, 3) = #$EF#$BB#$BF then
    AText := Copy(Raw, 4, MaxInt)
  else if IsValidUtf8(Raw) then
    AText := Raw
  else
    AText := AnsiToUtf8(Raw);
  Result := True;
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

// file:///C:/Папка/a%20b.md#метка -> C:\Папка\a b.md. Путь без file:
// (C:\..., C:/..., \\сервер\...) - тоже: IE может отдать адрес локального
// файла и так. '' - не файл (http:, mailto: ...)
function UrlToPath(const AUrl: string): string;
var
  Body, Decoded: string;
  Idx, HashAt, Code: Integer;
  HasHigh: Boolean;
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
  HashAt := Pos('#', Body);
  if HashAt > 0 then
    Body := Copy(Body, 1, HashAt - 1);
  HashAt := Pos('?', Body);
  if HashAt > 0 then
    Body := Copy(Body, 1, HashAt - 1);
  if Copy(Body, 1, 3) = '///' then
    Delete(Body, 1, 3)
  else if Copy(Body, 1, 2) = '//' then
    Body := '\\' + Copy(Body, 3, MaxInt);   // file://сервер/папка

  // %XX -> байт; байты от $80 - это UTF-8, их переводим в ANSI
  Decoded := '';
  HasHigh := False;
  Idx := 1;
  while Idx <= Length(Body) do
  begin
    if (Body[Idx] = '%') and (Idx + 2 <= Length(Body)) then
    begin
      Code := StrToIntDef('$' + Copy(Body, Idx + 1, 2), -1);
      if Code >= 0 then
      begin
        Decoded := Decoded + Chr(Code);
        if Code >= $80 then
          HasHigh := True;
        Inc(Idx, 3);
        Continue;
      end;
    end;
    Decoded := Decoded + Body[Idx];
    Inc(Idx);
  end;
  if HasHigh and IsValidUtf8(Decoded) and (Utf8ToAnsi(Decoded) <> '') then
    Decoded := Utf8ToAnsi(Decoded);
  Result := StringReplace(Decoded, '/', '\', [rfReplaceAll]);
end;

// Файл, который открывается в unIDE, а не программой Windows
function IsEditableFile(const AFileName: string): Boolean;
const
  Foreign: array[0..19] of string = (
    '.html', '.htm', '.pdf', '.chm', '.png', '.jpg', '.jpeg', '.gif',
    '.bmp', '.ico', '.zip', '.7z', '.rar', '.exe', '.dll', '.doc', '.docx',
    '.xls', '.xlsx', '.mp4');
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

function TempFolder: string;
var
  Buf: array[0..MAX_PATH] of Char;
begin
  if GetTempPath(MAX_PATH, Buf) > 0 then
    Result := IncludeTrailingPathDelimiter(Buf)
  else
    Result := ExtractFilePath(ParamStr(0));
end;

{ TMdPreview }

constructor TMdPreview.Create(AHost: TWinControl);
begin
  inherited Create;
  FHost := AHost;
  FScrollPos := TStringList.Create;
  FHtmlFile := TempFolder + 'unide_md_' + IntToStr(GetCurrentProcessId) +
    '.html';
  FMsgWnd := Classes.AllocateHWnd(MsgWndProc);
end;

destructor TMdPreview.Destroy;
begin
  if FMsgWnd <> 0 then
    Classes.DeallocateHWnd(FMsgWnd);
  FreeAndNil(FBrowser);
  if FileExists(FHtmlFile) then
    SysUtils.DeleteFile(FHtmlFile);
  FScrollPos.Free;
  inherited Destroy;
end;

// Браузер создаётся при первом показе: без .md в работе IE не грузится
function TMdPreview.EnsureBrowser: Boolean;
begin
  Result := FBrowser <> nil;
  if Result then
    Exit;
  try
    FBrowser := TWebBrowser.Create(nil);
    // У TWebBrowser своё свойство Parent (IDispatch документа) - поэтому
    // через TWinControl
    TWinControl(FBrowser).Parent := FHost;
    // Visible - тоже через TWinControl: у TWebBrowser есть своё Visible
    // (свойство IWebBrowser2), окно контрола оно не прячет
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

function TMdPreview.IsShown: Boolean;
begin
  Result := (FBrowser <> nil) and TWinControl(FBrowser).Visible;
end;

// Прокрутка страницы: в режиме IE=edge - у documentElement, в старых
// режимах - у body
function TMdPreview.ReadScroll: Integer;
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

procedure TMdPreview.RememberScroll;
begin
  if (FSourceFile = '') or not IsShown then
    Exit;
  FScrollPos.Values[FSourceFile] := IntToStr(ReadScroll);
end;

function TMdPreview.ShowText(const AUtf8Text, ASourceFile: string;
  ABack, AFore: TColor): Boolean;
var
  Html, BaseUrl, Title: string;
  Stream: TFileStream;
  Flags: OleVariant;
const
  Bom: string = #$EF#$BB#$BF;
begin
  Result := False;
  FLastError := '';
  if not EnsureBrowser then
    Exit;
  RememberScroll;

  FSourceFile := ASourceFile;
  BaseUrl := '';
  Title := 'Markdown';
  if ASourceFile <> '' then
  begin
    // Страница - в UTF-8, путь в ней - тоже
    BaseUrl := MdFileUrl(AnsiToUtf8(ExtractFilePath(ASourceFile)), True);
    Title := AnsiToUtf8(ExtractFileName(ASourceFile));
  end;
  Html := MdToHtmlPage(AUtf8Text, Title, BaseUrl, MdColorsFor(ABack, AFore));

  try
    Stream := TFileStream.Create(FHtmlFile, fmCreate);
    try
      Stream.WriteBuffer(Bom[1], Length(Bom));
      if Html <> '' then
        Stream.WriteBuffer(Html[1], Length(Html));
    finally
      Stream.Free;
    end;
  except
    on E: Exception do
    begin
      FLastError := 'Не записана страница ' + FHtmlFile + ': ' + E.Message;
      Exit;
    end;
  end;

  FPendingScroll := StrToIntDef(FScrollPos.Values[FSourceFile], 0);
  try
    TWinControl(FBrowser).Visible := True;
    FBrowser.BringToFront;
    Flags := NavFlagsReload;
    FExpectOwn := True;
    FBrowser.Navigate(WideString(MdFileUrl(FHtmlFile, False)), Flags);
    Result := True;
  except
    on E: Exception do
      FLastError := 'Просмотр не открылся: ' + E.Message;
  end;
end;

procedure TMdPreview.HideView;
begin
  if FBrowser = nil then
    Exit;
  RememberScroll;
  TWinControl(FBrowser).Visible := False;
end;

// ExecWB: OLECMDID_COPY = 12, OLECMDID_SELECTALL = 17,
// OLECMDEXECOPT_DODEFAULT = 0. Команда недоступна (нечего копировать) -
// исключение, его не показываем
procedure TMdPreview.CopySelection;
begin
  if not IsShown then
    Exit;
  try
    FBrowser.ExecWB(12, 0);
  except
  end;
end;

procedure TMdPreview.SelectAll;
begin
  if not IsShown then
    Exit;
  try
    FBrowser.ExecWB(17, 0);
  except
  end;
end;

procedure TMdPreview.FocusView;
begin
  try
    if IsShown and FBrowser.CanFocus then
      FBrowser.SetFocus;
  except
    // фокус - не главное: просмотр уже на экране
  end;
end;

procedure TMdPreview.BrowserDocumentComplete(Sender: TObject;
  const ADisp: IDispatch; var AUrl: OleVariant);
var
  Doc: OleVariant;
begin
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

procedure TMdPreview.BrowserBeforeNavigate2(Sender: TObject;
  const ADisp: IDispatch; var AUrl: OleVariant; var AFlags: OleVariant;
  var ATargetFrameName: OleVariant; var APostData: OleVariant;
  var AHeaders: OleVariant; var ACancel: WordBool);
var
  Url, LocalPath: string;
begin
  Url := VarToStr(AUrl);
  // about:blank и страницы ошибок самого IE (res://ieframe.dll/...)
  if (Url = '') or (CompareText(Copy(Url, 1, 6), 'about:') = 0) or
     (CompareText(Copy(Url, 1, 4), 'res:') = 0) then
  begin
    Log('браузер: ' + Url + ' - внутри');
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
  if (LocalPath <> '') and IsEditableFile(LocalPath) and
     Assigned(FOnOpenFile) then
  begin
    Log('браузер: ' + Url + ' - вкладкой: ' + LocalPath);
    FPendingOpen := LocalPath;
    PostMessage(FMsgWnd, WM_MD_OPENFILE, 0, 0);
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

// Своя страница: её первая загрузка после Navigate и переходы по меткам
// #раздел. Узнаётся по имени файла (unide_md_<pid>.html) в адресе в любом
// виде - file:///, путь, короткие (ADMINI~1) или длинные имена папок;
// первый переход после Navigate - своя страница, какой бы ни был адрес.
// Наружу (ShellExecute) своя страница не отдаётся никогда.
function TMdPreview.IsOwnPage(const AUrl, ALocalPath: string): Boolean;
var
  PageName: string;
begin
  PageName := LowerCase(ExtractFileName(FHtmlFile));
  Result := FExpectOwn or
            (Pos(PageName, LowerCase(AUrl)) > 0) or
            ((ALocalPath <> '') and
             (CompareText(ExtractFileName(ALocalPath), PageName) = 0));
end;

procedure TMdPreview.Log(const AText: string);
begin
  if Assigned(FOnLog) then
    FOnLog(AText);
end;

procedure TMdPreview.MsgWndProc(var Message: TMessage);
var
  FileName: string;
begin
  if Message.Msg = WM_MD_OPENFILE then
  begin
    FileName := FPendingOpen;
    FPendingOpen := '';
    if (FileName <> '') and Assigned(FOnOpenFile) then
      FOnOpenFile(FileName);
    Message.Result := 0;
  end
  else
    Message.Result := DefWindowProc(FMsgWnd, Message.Msg, Message.WParam,
      Message.LParam);
end;

end.
