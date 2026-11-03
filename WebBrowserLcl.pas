unit WebBrowserLcl;

// ---------------------------------------------------------------------------
//  WebBrowserLcl - заглушка TWebBrowser (SHDocVw) для сборки Lazarus.
//
//  В LCL нет готового контейнера ActiveX для Internet Explorer. Чтобы
//  FmtView собирался без изменений, здесь описан класс с теми же
//  свойствами и методами, которые использует TWebPreview. Конструктор
//  выдаёт исключение: TWebPreview.EnsureBrowser ловит его и пишет
//  причину в FLastError, просмотр через IE в этой сборке недоступен.
//  Просмотр .html / .mht через WebView2 (Wv2View) работает отдельно.
//
//  Только для FPC: в Delphi 7 используется настоящий SHDocVw.
//
//  Linux: не заглушка - страница показывается TIpHtmlPanel (пакет
//  TurboPower IPro из поставки Lazarus): HTML 4 и простой CSS, картинки с
//  диска. Navigate - путь файла (или file://). Щелчок по ссылке: метка на
//  той же странице ('#имя') - прокрутка к ней; остальное - в
//  OnBeforeNavigate2 (полный адрес), не отменили - страница открывается
//  здесь же. Document и ControlInterface - nil (нет OLE): прокрутка,
//  запомненная TWebPreview, не восстанавливается. ExecWB 12 / 17 -
//  копирование / выделить всё.
// ---------------------------------------------------------------------------

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
  SysUtils, Classes, Controls
  {$IFDEF UNIX}, Graphics, IpHtml, IpFileBroker{$ENDIF};

type
  TWebBrowserBeforeNavigate2 = procedure(Sender: TObject;
    const ADisp: IDispatch; var AUrl: OleVariant; var AFlags: OleVariant;
    var ATargetFrameName: OleVariant; var APostData: OleVariant;
    var AHeaders: OleVariant; var ACancel: WordBool) of object;
  TWebBrowserDocumentComplete = procedure(Sender: TObject;
    const ADisp: IDispatch; var AUrl: OleVariant) of object;

{$IFDEF UNIX}
  // Поставщик файлов: страницу открывает только Navigate (FAllowNav), щелчок
  // по ссылке идёт в OnHotClick (решает TWebPreview)
  TWebFileProvider = class(TIpFileDataProvider)
  public
    AllowNav: Boolean;
    function CanHandle(const AUrl: string): Boolean; override;
    // Картинка: адрес file:// с %XX (пробелы, кириллица) - в путь
    procedure GetImage(Sender: TIpHtmlNode; const AUrl: string;
      var APicture: TPicture); override;
  end;
{$ENDIF}

  TWebBrowser = class(TWinControl)
  private
{$IFDEF UNIX}
    FPanel: TIpHtmlPanel;
    FProvider: TWebFileProvider;
    FPageUrl: string;
    procedure PanelHotClick(Sender: TObject);
    procedure OpenUrl(const AUrl: string);
  private
{$ENDIF}
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

implementation

{$IFDEF UNIX}
function TWebFileProvider.CanHandle(const AUrl: string): Boolean;
begin
  Result := AllowNav and inherited CanHandle(AUrl);
end;

// file:///папка/a%20b.png -> /папка/a b.png
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
  except
    FreeAndNil(APicture);
  end;
end;

constructor TWebBrowser.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FProvider := TWebFileProvider.Create(Self);
  FPanel := TIpHtmlPanel.Create(Self);
  FPanel.Parent := Self;
  FPanel.Align := alClient;
  FPanel.DataProvider := FProvider;
  FPanel.OnHotClick := PanelHotClick;
  FPanel.AllowTextSelect := True;
end;

// Адрес страницы: путь -> file://путь
function WebFileUrl(const APath: string): string;
begin
  if Pos('://', APath) > 0 then
    Result := APath
  else
    Result := 'file://' + ExpandFileName(APath);
end;

procedure TWebBrowser.OpenUrl(const AUrl: string);
var
  NoDisp: IDispatch;
  UrlVar: OleVariant;
begin
  FPageUrl := AUrl;
  FProvider.AllowNav := True;
  try
    FPanel.OpenURL(AUrl);
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
{$ELSE}

constructor TWebBrowser.Create(AOwner: TComponent);
begin
  raise Exception.Create('в сборке Lazarus встроенного Internet Explorer нет');
end;

function TWebBrowser.GetDocument: IDispatch;
begin
  Result := nil;
end;

function TWebBrowser.GetControlInterface: IDispatch;
begin
  Result := nil;
end;

procedure TWebBrowser.Navigate(const AUrl: WideString; var AFlags: OleVariant);
begin
end;

procedure TWebBrowser.ExecWB(ACmdId, ACmdExecOpt: Integer);
begin
end;
{$ENDIF}

end.
