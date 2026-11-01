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
// ---------------------------------------------------------------------------

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
  SysUtils, Classes, Controls;

type
  TWebBrowserBeforeNavigate2 = procedure(Sender: TObject;
    const ADisp: IDispatch; var AUrl: OleVariant; var AFlags: OleVariant;
    var ATargetFrameName: OleVariant; var APostData: OleVariant;
    var AHeaders: OleVariant; var ACancel: WordBool) of object;
  TWebBrowserDocumentComplete = procedure(Sender: TObject;
    const ADisp: IDispatch; var AUrl: OleVariant) of object;

  TWebBrowser = class(TWinControl)
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

implementation

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

end.
