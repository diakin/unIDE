unit Controls;

// ---------------------------------------------------------------------------
//  uniFAR (Free Pascal, без LCL): заменитель модуля Controls из VCL - ровно
//  то, что нужно TFarView (UnFar): окно-элемент TCustomControl поверх WinAPI.
//
//  Окно Unicode (RegisterClassW, DefWindowProcW): WM_CHAR приходит в UTF-16.
//  Сообщения идут в методы message потомка (Dispatch), необработанные - в
//  DefWindowProcW. Мышь - в MouseDown / MouseMove / MouseUp / DblClick, как в
//  VCL (левая кнопка захватывает мышь до отпускания). WM_PAINT - в Paint с
//  Canvas на DC окна. Родитель - окно Windows (ParentWindow): форм VCL нет.
//
//  Модуль - только в пути модулей uniFAR (uniFAR\vcl); unIDE берёт VCL.
// ---------------------------------------------------------------------------

{$mode delphi}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics;

type
  TControlStyleItem = (csAcceptsControls, csCaptureMouse, csClickEvents,
    csOpaque, csDoubleClicks);
  TControlStyle = set of TControlStyleItem;
  TMouseButton = (mbLeft, mbRight, mbMiddle);

  TControl = class(TComponent)
  private
    FColor: TColor;
    FControlStyle: TControlStyle;
  protected
    procedure SetColor(AValue: TColor); virtual;
    procedure Resize; dynamic;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); dynamic;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); dynamic;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); dynamic;
    procedure DblClick; dynamic;
    property Color: TColor read FColor write SetColor;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Invalidate; virtual;
    property ControlStyle: TControlStyle read FControlStyle
      write FControlStyle;
  end;

  TWinControl = class(TControl)
  private
    FHandle: HWND;
    FParentWindow: HWND;
    FTabStop: Boolean;
    FVisible: Boolean;
    FLeft, FTop, FWidth, FHeight: Integer;
    function GetHandle: HWND;
    procedure SetParentWindow(AValue: HWND);
    procedure SetVisible(AValue: Boolean);
    function GetClientWidth: Integer;
    function GetClientHeight: Integer;
    function MouseShift(AKeys: WPARAM): TShiftState;
    procedure MouseButton(var AMessage: TWMMouse; AButton: TMouseButton;
      ADown, ADouble: Boolean);
    procedure WMLButtonDown(var Message: TWMMouse); message WM_LBUTTONDOWN;
    procedure WMLButtonUp(var Message: TWMMouse); message WM_LBUTTONUP;
    procedure WMLButtonDblClk(var Message: TWMMouse); message WM_LBUTTONDBLCLK;
    procedure WMRButtonDown(var Message: TWMMouse); message WM_RBUTTONDOWN;
    procedure WMRButtonUp(var Message: TWMMouse); message WM_RBUTTONUP;
    procedure WMRButtonDblClk(var Message: TWMMouse); message WM_RBUTTONDBLCLK;
    procedure WMMButtonDown(var Message: TWMMouse); message WM_MBUTTONDOWN;
    procedure WMMButtonUp(var Message: TWMMouse); message WM_MBUTTONUP;
    procedure WMMouseMove(var Message: TWMMouse); message WM_MOUSEMOVE;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
  protected
    procedure CreateWnd; virtual;
    procedure WndProc(var Message: TMessage); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure DefaultHandler(var Message); override;
    function HandleAllocated: Boolean;
    procedure HandleNeeded;
    procedure Invalidate; override;
    procedure Update;
    function Focused: Boolean;
    function CanFocus: Boolean;
    procedure SetFocus; virtual;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); virtual;
    function ScreenToClient(const APoint: TPoint): TPoint;
    function ClientToScreen(const APoint: TPoint): TPoint;
    property Handle: HWND read GetHandle;
    // Окно-родитель (обычно главное окно программы); задать - создать окно
    property ParentWindow: HWND read FParentWindow write SetParentWindow;
    property TabStop: Boolean read FTabStop write FTabStop;
    property Visible: Boolean read FVisible write SetVisible;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property ClientWidth: Integer read GetClientWidth;
    property ClientHeight: Integer read GetClientHeight;
  end;

  TCustomControl = class(TWinControl)
  private
    FCanvas: TCanvas;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
  protected
    procedure Paint; virtual;
    property Canvas: TCanvas read FCanvas;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  TMouse = class
  private
    function GetCursorPos: TPoint;
  public
    property CursorPos: TPoint read GetCursorPos;
  end;

var
  Mouse: TMouse;

implementation

const
  ShimClassName: PWideChar = 'uniFARControl';
  {$ifdef CPU64}
  ShimSetPtrName = 'SetWindowLongPtrW';
  ShimGetPtrName = 'GetWindowLongPtrW';
  {$else}
  ShimSetPtrName = 'SetWindowLongW';
  ShimGetPtrName = 'GetWindowLongW';
  {$endif}

function ShimSetWindowPtr(AWnd: HWND; AIndex: Integer;
  AValue: PtrInt): PtrInt; stdcall; external 'user32.dll' name ShimSetPtrName;
function ShimGetWindowPtr(AWnd: HWND; AIndex: Integer): PtrInt; stdcall;
  external 'user32.dll' name ShimGetPtrName;

var
  ShimClassDone: Boolean = False;

function ShimWindowProc(AWnd: HWND; AMsg: UINT; AWParam: WPARAM;
  ALParam: LPARAM): LRESULT; stdcall;
var
  Control: TWinControl;
  Message: TMessage;
begin
  if AMsg = WM_NCCREATE then
  begin
    Control := TWinControl(LPCREATESTRUCT(ALParam)^.lpCreateParams);
    Control.FHandle := AWnd;
    ShimSetWindowPtr(AWnd, GWL_USERDATA, PtrInt(Control));
  end
  else
    Control := TWinControl(ShimGetWindowPtr(AWnd, GWL_USERDATA));
  if Control = nil then
  begin
    Result := DefWindowProcW(AWnd, AMsg, AWParam, ALParam);
    Exit;
  end;
  FillChar(Message, SizeOf(Message), 0);
  Message.Msg := AMsg;
  Message.WParam := AWParam;
  Message.LParam := ALParam;
  Message.Result := 0;
  Control.WndProc(Message);
  Result := Message.Result;
  if AMsg = WM_NCDESTROY then
  begin
    ShimSetWindowPtr(AWnd, GWL_USERDATA, 0);
    Control.FHandle := 0;
  end;
end;

procedure ShimRegisterClass;
var
  WndClass: TWndClassW;
begin
  if ShimClassDone then
    Exit;
  FillChar(WndClass, SizeOf(WndClass), 0);
  WndClass.style := CS_DBLCLKS;
  WndClass.lpfnWndProc := @ShimWindowProc;
  WndClass.hInstance := HInstance;
  WndClass.hCursor := LoadCursor(0, IDC_ARROW);
  WndClass.lpszClassName := ShimClassName;
  RegisterClassW(WndClass);
  ShimClassDone := True;
end;

// ---------------------------------------------------------------------------

constructor TControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FColor := clBtnFace;
  FControlStyle := [csCaptureMouse, csClickEvents, csDoubleClicks];
end;

procedure TControl.SetColor(AValue: TColor);
begin
  if AValue = FColor then
    Exit;
  FColor := AValue;
  Invalidate;
end;

procedure TControl.Resize;
begin
end;

procedure TControl.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
end;

procedure TControl.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
end;

procedure TControl.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
end;

procedure TControl.DblClick;
begin
end;

procedure TControl.Invalidate;
begin
end;

// ---------------------------------------------------------------------------

constructor TWinControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FVisible := True;
  FWidth := 100;
  FHeight := 100;
end;

destructor TWinControl.Destroy;
begin
  if FHandle <> 0 then
    DestroyWindow(FHandle);
  inherited Destroy;
end;

procedure TWinControl.CreateWnd;
var
  Style: DWORD;
begin
  ShimRegisterClass;
  Style := WS_CLIPCHILDREN or WS_CLIPSIBLINGS;
  if FParentWindow <> 0 then
    Style := Style or WS_CHILD
  else
    Style := Style or WS_POPUP;
  if FTabStop then
    Style := Style or WS_TABSTOP;
  if FVisible then
    Style := Style or WS_VISIBLE;
  CreateWindowExW(0, ShimClassName, nil, Style, FLeft, FTop, FWidth, FHeight,
    FParentWindow, 0, HInstance, Self);
  if FHandle = 0 then
    raise Exception.CreateFmt('CreateWindowExW: ошибка %d', [GetLastError]);
end;

procedure TWinControl.WndProc(var Message: TMessage);
begin
  Dispatch(Message);
end;

procedure TWinControl.DefaultHandler(var Message);
begin
  with TMessage(Message) do
    if FHandle <> 0 then
      Result := DefWindowProcW(FHandle, Msg, WParam, LParam)
    else
      Result := 0;
end;

function TWinControl.HandleAllocated: Boolean;
begin
  Result := FHandle <> 0;
end;

procedure TWinControl.HandleNeeded;
begin
  if FHandle = 0 then
    CreateWnd;
end;

function TWinControl.GetHandle: HWND;
begin
  HandleNeeded;
  Result := FHandle;
end;

procedure TWinControl.SetParentWindow(AValue: HWND);
begin
  if AValue = FParentWindow then
    Exit;
  FParentWindow := AValue;
  if FHandle <> 0 then
    Windows.SetParent(FHandle, AValue)
  else if AValue <> 0 then
    CreateWnd;
end;

procedure TWinControl.SetVisible(AValue: Boolean);
begin
  FVisible := AValue;
  if FHandle <> 0 then
    if AValue then
      ShowWindow(FHandle, SW_SHOW)
    else
      ShowWindow(FHandle, SW_HIDE);
end;

function TWinControl.GetClientWidth: Integer;
var
  ClientRect: TRect;
begin
  if (FHandle <> 0) and GetClientRect(FHandle, ClientRect) then
    Result := ClientRect.Right - ClientRect.Left
  else
    Result := FWidth;
end;

function TWinControl.GetClientHeight: Integer;
var
  ClientRect: TRect;
begin
  if (FHandle <> 0) and GetClientRect(FHandle, ClientRect) then
    Result := ClientRect.Bottom - ClientRect.Top
  else
    Result := FHeight;
end;

procedure TWinControl.Invalidate;
begin
  if FHandle <> 0 then
    InvalidateRect(FHandle, nil, not (csOpaque in ControlStyle));
end;

procedure TWinControl.Update;
begin
  if FHandle <> 0 then
    UpdateWindow(FHandle);
end;

function TWinControl.Focused: Boolean;
begin
  Result := (FHandle <> 0) and (GetFocus = FHandle);
end;

function TWinControl.CanFocus: Boolean;
begin
  Result := (FHandle <> 0) and IsWindowVisible(FHandle) and
    IsWindowEnabled(FHandle);
end;

procedure TWinControl.SetFocus;
begin
  Windows.SetFocus(Handle);
end;

procedure TWinControl.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  FLeft := ALeft;
  FTop := ATop;
  FWidth := AWidth;
  FHeight := AHeight;
  if FHandle <> 0 then
    MoveWindow(FHandle, ALeft, ATop, AWidth, AHeight, True);
end;

function TWinControl.ScreenToClient(const APoint: TPoint): TPoint;
begin
  Result := APoint;
  if FHandle <> 0 then
    Windows.ScreenToClient(FHandle, Result);
end;

function TWinControl.ClientToScreen(const APoint: TPoint): TPoint;
begin
  Result := APoint;
  if FHandle <> 0 then
    Windows.ClientToScreen(FHandle, Result);
end;

function TWinControl.MouseShift(AKeys: WPARAM): TShiftState;
begin
  Result := [];
  if AKeys and MK_SHIFT <> 0 then
    Include(Result, ssShift);
  if AKeys and MK_CONTROL <> 0 then
    Include(Result, ssCtrl);
  if AKeys and MK_LBUTTON <> 0 then
    Include(Result, ssLeft);
  if AKeys and MK_RBUTTON <> 0 then
    Include(Result, ssRight);
  if AKeys and MK_MBUTTON <> 0 then
    Include(Result, ssMiddle);
  if GetKeyState(VK_MENU) < 0 then
    Include(Result, ssAlt);
end;

procedure TWinControl.MouseButton(var AMessage: TWMMouse;
  AButton: TMouseButton; ADown, ADouble: Boolean);
var
  Shift: TShiftState;
begin
  Shift := MouseShift(AMessage.Keys);
  if ADown then
  begin
    if (AButton = mbLeft) and (csCaptureMouse in ControlStyle) then
      SetCapture(FHandle);
    // Как в VCL: двойной щелчок - DblClick, затем MouseDown с ssDouble
    if ADouble then
    begin
      Include(Shift, ssDouble);
      if csDoubleClicks in ControlStyle then
        DblClick;
    end;
    MouseDown(AButton, Shift, AMessage.XPos, AMessage.YPos);
  end
  else
  begin
    if (AButton = mbLeft) and (GetCapture = FHandle) then
      ReleaseCapture;
    MouseUp(AButton, Shift, AMessage.XPos, AMessage.YPos);
  end;
  AMessage.Result := 0;
end;

procedure TWinControl.WMLButtonDown(var Message: TWMMouse);
begin
  MouseButton(Message, mbLeft, True, False);
end;

procedure TWinControl.WMLButtonUp(var Message: TWMMouse);
begin
  MouseButton(Message, mbLeft, False, False);
end;

procedure TWinControl.WMLButtonDblClk(var Message: TWMMouse);
begin
  MouseButton(Message, mbLeft, True, True);
end;

procedure TWinControl.WMRButtonDown(var Message: TWMMouse);
begin
  MouseButton(Message, mbRight, True, False);
end;

procedure TWinControl.WMRButtonUp(var Message: TWMMouse);
begin
  MouseButton(Message, mbRight, False, False);
  // Правая кнопка - ещё и WM_CONTEXTMENU (DefWindowProc)
  inherited;
end;

procedure TWinControl.WMRButtonDblClk(var Message: TWMMouse);
begin
  MouseButton(Message, mbRight, True, True);
end;

procedure TWinControl.WMMButtonDown(var Message: TWMMouse);
begin
  MouseButton(Message, mbMiddle, True, False);
end;

procedure TWinControl.WMMButtonUp(var Message: TWMMouse);
begin
  MouseButton(Message, mbMiddle, False, False);
end;

procedure TWinControl.WMMouseMove(var Message: TWMMouse);
begin
  MouseMove(MouseShift(Message.Keys), Message.XPos, Message.YPos);
  Message.Result := 0;
end;

procedure TWinControl.WMSize(var Message: TWMSize);
var
  WindowRect: TRect;
begin
  if FHandle <> 0 then
  begin
    GetWindowRect(FHandle, WindowRect);
    FWidth := WindowRect.Right - WindowRect.Left;
    FHeight := WindowRect.Bottom - WindowRect.Top;
  end;
  Resize;
  Message.Result := 0;
end;

// ---------------------------------------------------------------------------

constructor TCustomControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCanvas := TCanvas.Create;
end;

destructor TCustomControl.Destroy;
begin
  inherited Destroy;
  FCanvas.Free;
end;

procedure TCustomControl.WMPaint(var Message: TWMPaint);
var
  PaintInfo: TPaintStruct;
  PaintDC: HDC;
begin
  PaintDC := BeginPaint(FHandle, PaintInfo);
  try
    FCanvas.Handle := PaintDC;
    try
      Paint;
    finally
      FCanvas.Handle := 0;
    end;
  finally
    EndPaint(FHandle, PaintInfo);
  end;
  Message.Result := 0;
end;

procedure TCustomControl.Paint;
begin
  FCanvas.Brush.Color := Color;
  FCanvas.FillRect(Rect(0, 0, ClientWidth, ClientHeight));
end;

// ---------------------------------------------------------------------------

function TMouse.GetCursorPos: TPoint;
begin
  Result := Point(0, 0);
  Windows.GetCursorPos(Result);
end;

initialization
  Mouse := TMouse.Create;

finalization
  Mouse.Free;

end.
