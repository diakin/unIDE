// ---------------------------------------------------------------------------
//  RqLcl: событие WndProc RapidQ (QFORM, QEDIT, QLISTBOX, QLABEL) -
//  сообщения Windows элемента в обработчик программы.
//
//  Элемент с окном: окно подменяется своей оконной процедурой
//  (SetWindowLongPtrW, GWLP_WNDPROC), она вызывает обработчик и затем
//  прежнюю процедуру (LCL); результат сообщения не меняется. Окно,
//  созданное LCL заново (RecreateWnd), подменяется снова - по первому
//  сообщению LCL (TControl.WindowProc).
//  Элемент без окна (QLABEL): сообщения LCL (TControl.WindowProc); номера
//  сообщений мыши LCL совпадают с WM_..., окно - окно родителя.
// ---------------------------------------------------------------------------
unit rqlclwnd;

{$mode objfpc}{$H+}

interface

uses
  Windows, Classes, SysUtils, Controls, LMessages;

type
  TRqWndEvent = procedure(Sender: TObject; AWnd: HWND; AMsg: UINT;
                          AWParam: WPARAM; ALParam: LPARAM) of object;

  TRqWndHook = class(TComponent)
  private
    FControl: TControl;
    FOnMessage: TRqWndEvent;
    FHookWnd: HWND;
    FOldWndProc: LONG_PTR;
    FOldLclProc: TWndMethod;
    procedure LclWindowProc(var AMessage: TLMessage);
    procedure HookWindow;
    procedure UnhookWindow;
    procedure CallHandler(AWnd: HWND; AMsg: UINT; AWParam: WPARAM;
                          ALParam: LPARAM);
  public
    constructor CreateFor(AControl: TControl);
    destructor Destroy; override;
    property OnMessage: TRqWndEvent read FOnMessage write FOnMessage;
  end;

// Обработчик сообщений элемента; nil - снять (окно возвращается LCL)
procedure WndHookSet(AControl: TControl; AHandler: TRqWndEvent);

implementation

const
  HookPropName = 'RqLclWndHook';

function HookOf(AControl: TControl): TRqWndHook;
var
  CompIdx: Integer;
begin
  Result := nil;
  for CompIdx := 0 to AControl.ComponentCount - 1 do
    if AControl.Components[CompIdx] is TRqWndHook then
    begin
      Result := TRqWndHook(AControl.Components[CompIdx]);
      Exit;
    end;
end;

// Оконная процедура подменённого окна
function RqHookWndProc(AWnd: HWND; AMsg: UINT; AWParam: WPARAM;
                       ALParam: LPARAM): LRESULT; stdcall;
var
  Hook: TRqWndHook;
  OldProc: LONG_PTR;
begin
  Hook := TRqWndHook(GetPropA(AWnd, HookPropName));
  if Hook = nil then
  begin
    Result := DefWindowProcW(AWnd, AMsg, AWParam, ALParam);
    Exit;
  end;
  // прежняя процедура - до обработчика: он может уничтожить элемент
  OldProc := Hook.FOldWndProc;
  if AMsg = WM_NCDESTROY then
    Hook.UnhookWindow
  else
    Hook.CallHandler(AWnd, AMsg, AWParam, ALParam);
  Result := CallWindowProcW(WNDPROC(OldProc), AWnd, AMsg, AWParam, ALParam);
end;

constructor TRqWndHook.CreateFor(AControl: TControl);
begin
  inherited Create(AControl);
  FControl := AControl;
  FOldLclProc := AControl.WindowProc;
  AControl.WindowProc := @LclWindowProc;
  if AControl is TWinControl then
  begin
    // окно нужно сразу: сообщения до первого показа тоже приходят
    TWinControl(AControl).HandleNeeded;
    HookWindow;
  end;
end;

destructor TRqWndHook.Destroy;
begin
  FOnMessage := nil;
  UnhookWindow;
  if (FControl <> nil) and not (csDestroying in FControl.ComponentState) then
    FControl.WindowProc := FOldLclProc;
  inherited Destroy;
end;

procedure TRqWndHook.CallHandler(AWnd: HWND; AMsg: UINT; AWParam: WPARAM;
                                 ALParam: LPARAM);
begin
  if not Assigned(FOnMessage) or (csDestroying in FControl.ComponentState) then
    Exit;
  // исключение не должно уйти в Windows
  try
    FOnMessage(Self, AWnd, AMsg, AWParam, ALParam);
  except
  end;
end;

procedure TRqWndHook.HookWindow;
var
  NewWnd: HWND;
begin
  if not (FControl is TWinControl) or not TWinControl(FControl).HandleAllocated then
    Exit;
  NewWnd := TWinControl(FControl).Handle;
  if NewWnd = FHookWnd then
    Exit;
  UnhookWindow;
  FHookWnd := NewWnd;
  SetPropA(FHookWnd, HookPropName, THandle(Self));
  FOldWndProc := SetWindowLongPtrW(FHookWnd, GWLP_WNDPROC,
                                   LONG_PTR(@RqHookWndProc));
end;

// Окно - снова процедуре LCL, если поверх нашей никто не подменил
procedure TRqWndHook.UnhookWindow;
begin
  if FHookWnd = 0 then
    Exit;
  if IsWindow(FHookWnd) then
  begin
    if PtrUInt(GetWindowLongPtrW(FHookWnd, GWLP_WNDPROC)) = PtrUInt(@RqHookWndProc) then
      SetWindowLongPtrW(FHookWnd, GWLP_WNDPROC, FOldWndProc);
    RemovePropA(FHookWnd, HookPropName);
  end;
  FHookWnd := 0;
  FOldWndProc := 0;
end;

// Сообщение LCL: у элемента без окна - обработчику; у элемента с окном -
// проверка, не создано ли окно заново
procedure TRqWndHook.LclWindowProc(var AMessage: TLMessage);
var
  ParentWnd: HWND;
begin
  if not (FControl is TWinControl) then
  begin
    ParentWnd := 0;
    if (FControl.Parent <> nil) and FControl.Parent.HandleAllocated then
      ParentWnd := FControl.Parent.Handle;
    CallHandler(ParentWnd, AMessage.Msg, AMessage.WParam, AMessage.LParam);
  end;
  FOldLclProc(AMessage);
  if (FControl is TWinControl) and not (csDestroying in FControl.ComponentState) then
    HookWindow;
end;

procedure WndHookSet(AControl: TControl; AHandler: TRqWndEvent);
var
  Hook: TRqWndHook;
begin
  Hook := HookOf(AControl);
  if not Assigned(AHandler) then
  begin
    if Hook = nil then
      Exit;
    Hook.FOnMessage := nil;
    if not (csDestroying in AControl.ComponentState) then
      Hook.Free;
    Exit;
  end;
  if Hook = nil then
    Hook := TRqWndHook.CreateFor(AControl);
  Hook.FOnMessage := AHandler;
end;

end.
