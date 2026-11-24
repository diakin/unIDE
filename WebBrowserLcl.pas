unit WebBrowserLcl;

// ---------------------------------------------------------------------------
//  WebBrowserLcl - замена TWebBrowser (SHDocVw) для сборки Lazarus.
//
//  В LCL нет готового контейнера ActiveX для Internet Explorer. Чтобы
//  FmtView собирался без изменений, здесь описан класс с теми же
//  свойствами и методами, которые использует TWebPreview.
//
//  Только для FPC: в Delphi 7 используется настоящий SHDocVw.
//
//  Windows и Linux: страница показывается TIpHtmlPanel (пакет TurboPower
//  IPro из поставки Lazarus, он уже в зависимостях проекта): HTML 4 и
//  простой CSS, картинки с диска. Скрипты, .mht и CSS3 не поддерживаются;
//  полный вид - отдельное окно WebView2 (Wv2View). Navigate - путь файла (или file://). Щелчок по ссылке: метка на
//  той же странице ('#имя') - прокрутка к ней; остальное - в
//  OnBeforeNavigate2 (полный адрес), не отменили - страница открывается
//  здесь же. Document и ControlInterface - nil (нет OLE): прокрутка,
//  запомненная TWebPreview, не восстанавливается. ExecWB 12 / 17 -
//  копирование / выделить всё.
//
//  Обход ошибок IPro (Lazarus 3.0): страница перед разбором правится в
//  памяти (IproSafeHtml) - атрибут disabled у полей формы и
//  <input type="image"> дают Access violation внутри IPro, а <style> без
//  type="text/css" IPro пропускает, <iframe> с недоступным адресом
//  прерывает всю страницу (вместо него - ссылка). Исключение при открытии страницы
//  оставляет панель IPro с недостроенным документом, и после него не
//  открывалась уже ни одна страница - панель создаётся заново.
// ---------------------------------------------------------------------------

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
  SysUtils, Classes, Controls, Graphics, IpHtml, IpFileBroker, IpMsg;

type
  TWebBrowserBeforeNavigate2 = procedure(Sender: TObject;
    const ADisp: IDispatch; var AUrl: OleVariant; var AFlags: OleVariant;
    var ATargetFrameName: OleVariant; var APostData: OleVariant;
    var AHeaders: OleVariant; var ACancel: WordBool) of object;
  TWebBrowserDocumentComplete = procedure(Sender: TObject;
    const ADisp: IDispatch; var AUrl: OleVariant) of object;

  // Поставщик файлов: страницу открывает только Navigate (FAllowNav), щелчок
  // по ссылке идёт в OnHotClick (решает TWebPreview)
  TWebFileProvider = class(TIpFileDataProvider)
  public
    AllowNav: Boolean;
    function CanHandle(const AUrl: string): Boolean; override;
    // Страница - через IproSafeHtml
    function GetHtmlStream(const AUrl: string;
      APostData: TIpFormDataEntity): TStream; override;
    // Картинка: адрес file:// с %XX (пробелы, кириллица) - в путь
    procedure GetImage(Sender: TIpHtmlNode; const AUrl: string;
      var APicture: TPicture); override;
  end;

  TWebBrowser = class(TWinControl)
  private
    FPanel: TIpHtmlPanel;
    FProvider: TWebFileProvider;
    FPageUrl: string;
    procedure CreatePanel;
    procedure PanelHotClick(Sender: TObject);
    procedure OpenUrl(const AUrl: string);
  private
    FSilent: Boolean;
    FRegisterAsDropTarget: Boolean;
    FOnBeforeNavigate2: TWebBrowserBeforeNavigate2;
    FOnDocumentComplete: TWebBrowserDocumentComplete;
    function GetDocument: IDispatch;
    function GetControlInterface: IDispatch;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Navigate(const AUrl: WideString; var AFlags: OleVariant);
    procedure ExecWB(ACmdId, ACmdExecOpt: Integer);
    property Document: IDispatch read GetDocument;
    property ControlInterface: IDispatch read GetControlInterface;
    property Silent: Boolean read FSilent write FSilent;
    property RegisterAsDropTarget: Boolean read FRegisterAsDropTarget
      write FRegisterAsDropTarget;
    property OnBeforeNavigate2: TWebBrowserBeforeNavigate2
      read FOnBeforeNavigate2 write FOnBeforeNavigate2;
    property OnDocumentComplete: TWebBrowserDocumentComplete
      read FOnDocumentComplete write FOnDocumentComplete;
  end;

// Текст страницы, который IPro разберёт без Access violation (см. начало
// модуля). Байты - как в файле: имена тегов и атрибутов - ASCII
function IproSafeHtml(const AHtml: RawByteString): RawByteString;

implementation

function TWebFileProvider.CanHandle(const AUrl: string): Boolean;
begin
  Result := AllowNav and inherited CanHandle(AUrl);
end;

function IsNameChar(ACh: AnsiChar): Boolean;
begin
  Result := ACh in ['a'..'z', 'A'..'Z', '0'..'9', '-', '_', ':'];
end;

// Атрибут AName в тексте тега ATag (без '<' и '>'): позиция начала имени
// и длина всего атрибута с ="значение"; 0 - нет такого
function FindTagAttr(const ATag, AName: RawByteString;
  out AAttrLen: Integer): Integer;
var
  Lower: RawByteString;
  Pos1, Pos2: Integer;
  Quote: AnsiChar;
begin
  Result := 0;
  AAttrLen := 0;
  Lower := LowerCase(ATag);
  Pos1 := 1;
  // имя тега пропускаем
  while (Pos1 <= Length(Lower)) and IsNameChar(Lower[Pos1]) do
    Inc(Pos1);
  while Pos1 <= Length(Lower) do
  begin
    while (Pos1 <= Length(Lower)) and not IsNameChar(Lower[Pos1]) do
      Inc(Pos1);
    Pos2 := Pos1;
    while (Pos2 <= Length(Lower)) and IsNameChar(Lower[Pos2]) do
      Inc(Pos2);
    if Pos2 = Pos1 then
      Exit;
    if Copy(Lower, Pos1, Pos2 - Pos1) = AName then
      Result := Pos1;
    // значение: ="...", ='...' или =слово
    while (Pos2 <= Length(Lower)) and (Lower[Pos2] in [' ', #9, #13, #10]) do
      Inc(Pos2);
    if (Pos2 <= Length(Lower)) and (Lower[Pos2] = '=') then
    begin
      Inc(Pos2);
      while (Pos2 <= Length(Lower)) and (Lower[Pos2] in [' ', #9, #13, #10]) do
        Inc(Pos2);
      if (Pos2 <= Length(Lower)) and (Lower[Pos2] in ['"', '''']) then
      begin
        Quote := Lower[Pos2];
        Inc(Pos2);
        while (Pos2 <= Length(Lower)) and (Lower[Pos2] <> Quote) do
          Inc(Pos2);
        Inc(Pos2);
      end
      else
        while (Pos2 <= Length(Lower)) and
              not (Lower[Pos2] in [' ', #9, #13, #10, '/']) do
          Inc(Pos2);
    end;
    if Result > 0 then
    begin
      AAttrLen := Pos2 - Result;
      Exit;
    end;
    Pos1 := Pos2;
  end;
end;

// Значение атрибута как в теге, без кавычек; '' - нет атрибута или пустое
function TagAttrValueRaw(const ATag, AName: RawByteString): RawByteString;
var
  AttrAt, AttrLen, EqAt: Integer;
begin
  Result := '';
  AttrAt := FindTagAttr(ATag, AName, AttrLen);
  if AttrAt = 0 then
    Exit;
  Result := Copy(ATag, AttrAt, AttrLen);
  EqAt := Pos('=', Result);
  if EqAt = 0 then
  begin
    Result := '';
    Exit;
  end;
  Result := Trim(Copy(Result, EqAt + 1, MaxInt));
  if (Result <> '') and (Result[1] in ['"', '''']) then
    Result := Copy(Result, 2, Length(Result) - 2);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
end;

// То же строчными
function TagAttrValue(const ATag, AName: RawByteString): RawByteString;
begin
  Result := LowerCase(TagAttrValueRaw(ATag, AName));
end;

// Один тег (текст между '<' и '>'), исправленный для IPro
function IproSafeTag(const ATag: RawByteString): RawByteString;
var
  TagName, Src: RawByteString;
  NameEnd, AttrAt, AttrLen: Integer;
begin
  Result := ATag;
  NameEnd := 1;
  if (Result <> '') and (Result[1] = '/') then
    NameEnd := 2;
  while (NameEnd <= Length(Result)) and IsNameChar(Result[NameEnd]) do
    Inc(NameEnd);
  TagName := LowerCase(Copy(Result, 1, NameEnd - 1));
  if (TagName = 'input') or (TagName = 'select') or
     (TagName = 'textarea') or (TagName = 'button') or
     (TagName = 'option') or (TagName = 'optgroup') then
  begin
    // disabled: IPro ставит Enabled элементу, который ещё не создан
    repeat
      AttrAt := FindTagAttr(Result, 'disabled', AttrLen);
      if AttrAt > 0 then
        Delete(Result, AttrAt, AttrLen);
    until AttrAt = 0;
    // type="image": без картинки IPro обращается к пустой TPicture
    if (TagName = 'input') and (TagAttrValue(Result, 'type') = 'image') then
    begin
      AttrAt := FindTagAttr(Result, 'type', AttrLen);
      Delete(Result, AttrAt, AttrLen);
      Insert('type="submit"', Result, AttrAt);
    end;
  end
  else if (TagName = 'style') and (FindTagAttr(Result, 'type', AttrLen) = 0) then
    Insert(' type="text/css"', Result, NameEnd)
  // <iframe>: IPro грузит его сам и на адресе http(s):// или на
  // несуществующем файле прерывает всю страницу (Resource unavailable) -
  // вместо кадра ссылка на его адрес
  else if TagName = 'iframe' then
  begin
    Src := TagAttrValueRaw(Result, 'src');
    Result := 'a href="' + Src + '">[iframe: ' + Src + ']</a><span';
  end
  else if TagName = '/iframe' then
    Result := '/span';
end;

function IproSafeHtml(const AHtml: RawByteString): RawByteString;
var
  Pos1, TagEnd, Done: Integer;
  Lower: RawByteString;
begin
  Result := '';
  Lower := LowerCase(AHtml);
  Done := 1;
  Pos1 := 1;
  while Pos1 <= Length(AHtml) do
  begin
    if AHtml[Pos1] <> '<' then
    begin
      Inc(Pos1);
      Continue;
    end;
    // комментарии и <script> - как есть
    if Copy(AHtml, Pos1, 4) = '<!--' then
    begin
      TagEnd := Pos('-->', Copy(AHtml, Pos1 + 4, MaxInt));
      if TagEnd = 0 then
        Break;
      Pos1 := Pos1 + 4 + TagEnd + 2;
      Continue;
    end;
    if (Copy(Lower, Pos1, 7) = '<script') then
    begin
      TagEnd := Pos('</script', Copy(Lower, Pos1 + 7, MaxInt));
      if TagEnd = 0 then
        Break;
      Pos1 := Pos1 + 7 + TagEnd;
      Continue;
    end;
    if (Pos1 + 1 > Length(AHtml)) or
       not (AHtml[Pos1 + 1] in ['a'..'z', 'A'..'Z', '/']) then
    begin
      Inc(Pos1);
      Continue;
    end;
    TagEnd := Pos1 + 1;
    while (TagEnd <= Length(AHtml)) and (AHtml[TagEnd] <> '>') do
      Inc(TagEnd);
    if TagEnd > Length(AHtml) then
      Break;
    Result := Result + Copy(AHtml, Done, Pos1 + 1 - Done) +
              IproSafeTag(Copy(AHtml, Pos1 + 1, TagEnd - Pos1 - 1));
    Done := TagEnd;
    Pos1 := TagEnd + 1;
  end;
  Result := Result + Copy(AHtml, Done, MaxInt);
end;

function TWebFileProvider.GetHtmlStream(const AUrl: string;
  APostData: TIpFormDataEntity): TStream;
var
  Bytes: RawByteString;
begin
  Result := inherited GetHtmlStream(AUrl, APostData);
  SetLength(Bytes, Result.Size);
  if Bytes <> '' then
  begin
    Result.Position := 0;
    Result.ReadBuffer(Bytes[1], Length(Bytes));
  end;
  Bytes := IproSafeHtml(Bytes);
  Result.Size := 0;
  if Bytes <> '' then
    Result.WriteBuffer(Bytes[1], Length(Bytes));
  Result.Position := 0;
end;

// file:///папка/a%20b.png -> /папка/a b.png;
// Windows: file:///C:/папка/a%20b.png -> C:\папка\a b.png
function WebUrlToFile(const AUrl: string): string;
var
  Body: string;
  CharIdx: Integer;
begin
  Body := AUrl;
  if LowerCase(Copy(Body, 1, 5)) = 'file:' then
    Delete(Body, 1, 5);
  while Copy(Body, 1, 2) = '//' do
    Delete(Body, 1, 1);
  Result := '';
  CharIdx := 1;
  while CharIdx <= Length(Body) do
  begin
    if (Body[CharIdx] = '%') and (CharIdx + 2 <= Length(Body)) and
       (StrToIntDef('$' + Copy(Body, CharIdx + 1, 2), -1) >= 0) then
    begin
      Result := Result + Chr(StrToInt('$' + Copy(Body, CharIdx + 1, 2)));
      Inc(CharIdx, 3);
    end
    else
    begin
      Result := Result + Body[CharIdx];
      Inc(CharIdx);
    end;
  end;
{$IFDEF MSWINDOWS}
  // /C:/папка -> C:/папка
  if (Length(Result) >= 3) and (Result[1] = '/') and (Result[3] = ':') then
    Delete(Result, 1, 1);
  Result := StringReplace(Result, '/', '\', [rfReplaceAll]);
{$ENDIF}
end;

procedure TWebFileProvider.GetImage(Sender: TIpHtmlNode; const AUrl: string;
  var APicture: TPicture);
var
  FileName: string;
begin
  APicture := nil;
  FileName := WebUrlToFile(AUrl);
  if not FileExists(FileName) then
    Exit;
  APicture := TPicture.Create;
  try
    APicture.LoadFromFile(FileName);
    // IPro рисует картинку с Transparent := True; цвет прозрачности LCL
    // берёт из левого нижнего пикселя, и картинка без альфа-канала теряла
    // все точки этого цвета (белый фон снимка экрана). clNone - без маски
    if (APicture.Graphic is TRasterImage) and
       not TRasterImage(APicture.Graphic).Masked and
       (TRasterImage(APicture.Graphic).RawImage.Description.AlphaPrec = 0) then
      TRasterImage(APicture.Graphic).TransparentColor := clNone;
  except
    FreeAndNil(APicture);
  end;
end;

constructor TWebBrowser.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FProvider := TWebFileProvider.Create(Self);
  CreatePanel;
end;

procedure TWebBrowser.CreatePanel;
begin
  FPanel := TIpHtmlPanel.Create(Self);
  FPanel.Parent := Self;
  FPanel.Align := alClient;
  FPanel.DataProvider := FProvider;
  FPanel.OnHotClick := PanelHotClick;
  FPanel.AllowTextSelect := True;
end;

// Адрес страницы: путь -> file://путь (Windows: C:\папка -> file:///C:/папка,
// \\сервер\папка -> file://сервер/папка)
function WebFileUrl(const APath: string): string;
{$IFDEF MSWINDOWS}
var
  FullPath: string;
{$ENDIF}
begin
  if Pos('://', APath) > 0 then
    Result := APath
  else
  begin
{$IFDEF MSWINDOWS}
    FullPath := StringReplace(ExpandFileName(APath), '\', '/', [rfReplaceAll]);
    if Copy(FullPath, 1, 2) = '//' then
      Result := 'file:' + FullPath
    else
      Result := 'file:///' + FullPath;
{$ELSE}
    Result := 'file://' + ExpandFileName(APath);
{$ENDIF}
  end;
end;

procedure TWebBrowser.OpenUrl(const AUrl: string);
var
  NoDisp: IDispatch;
  UrlVar: OleVariant;
begin
  FPageUrl := AUrl;
  FProvider.AllowNav := True;
  try
    try
      FPanel.OpenURL(AUrl);
    except
      // Недостроенный документ IPro роняет и следующие страницы, и своё
      // освобождение: панель - заново, прежняя только убирается с экрана
      FPanel.Visible := False;
      FPanel.Parent := nil;
      FPanel.OnHotClick := nil;
      FPanel.DataProvider := nil;
      CreatePanel;
      raise;
    end;
  finally
    FProvider.AllowNav := False;
  end;
  if Assigned(FOnDocumentComplete) then
  begin
    NoDisp := nil;
    UrlVar := WideString(UTF8Decode(AUrl));
    FOnDocumentComplete(Self, NoDisp, UrlVar);
  end;
end;

procedure TWebBrowser.PanelHotClick(Sender: TObject);
var
  Href, FullUrl, PagePath: string;
  NoDisp: IDispatch;
  UrlVar, FlagsVar, FrameVar, PostVar, HeadersVar: OleVariant;
  Cancel: WordBool;
  HashPos: Integer;
begin
  Href := FPanel.HotURL;
  if Href = '' then
    Exit;
  // Метка на этой же странице
  if Href[1] = '#' then
  begin
    FPanel.MakeAnchorVisible(Copy(Href, 2, MaxInt));
    Exit;
  end;
  if (Pos('://', Href) > 0) or (Pos('mailto:', LowerCase(Href)) = 1) then
    FullUrl := Href
  else
  begin
    // Относительный адрес - от папки страницы
    PagePath := FPageUrl;
    HashPos := Pos('#', PagePath);
    if HashPos > 0 then
      SetLength(PagePath, HashPos - 1);
    if Href[1] = '/' then
      FullUrl := 'file://' + Href
    else
      FullUrl := Copy(PagePath, 1, LastDelimiter('/', PagePath)) + Href;
  end;
  Cancel := False;
  if Assigned(FOnBeforeNavigate2) then
  begin
    NoDisp := nil;
    UrlVar := WideString(UTF8Decode(FullUrl));
    FlagsVar := 0;
    FrameVar := '';
    PostVar := '';
    HeadersVar := '';
    FOnBeforeNavigate2(Self, NoDisp, UrlVar, FlagsVar, FrameVar, PostVar,
      HeadersVar, Cancel);
  end;
  if not Cancel then
    OpenUrl(FullUrl);
end;

function TWebBrowser.GetDocument: IDispatch;
begin
  Result := nil;
end;

function TWebBrowser.GetControlInterface: IDispatch;
begin
  Result := nil;
end;

// Как у IE: и свой переход сначала проходит OnBeforeNavigate2 (TWebPreview
// так узнаёт свою страницу)
procedure TWebBrowser.Navigate(const AUrl: WideString; var AFlags: OleVariant);
var
  FullUrl: string;
  NoDisp: IDispatch;
  UrlVar, FrameVar, PostVar, HeadersVar: OleVariant;
  Cancel: WordBool;
begin
  FullUrl := WebFileUrl(UTF8Encode(AUrl));
  Cancel := False;
  if Assigned(FOnBeforeNavigate2) then
  begin
    NoDisp := nil;
    UrlVar := WideString(UTF8Decode(FullUrl));
    FrameVar := '';
    PostVar := '';
    HeadersVar := '';
    FOnBeforeNavigate2(Self, NoDisp, UrlVar, AFlags, FrameVar, PostVar,
      HeadersVar, Cancel);
  end;
  if not Cancel then
    OpenUrl(FullUrl);
end;

procedure TWebBrowser.ExecWB(ACmdId, ACmdExecOpt: Integer);
begin
  case ACmdId of
    12: FPanel.CopyToClipboard;
    17: FPanel.SelectAll;
  end;
end;

end.
