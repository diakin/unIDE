unit AppMsgHook;

// ---------------------------------------------------------------------------
//  AppMsgHook - замена Application.OnMessage для сборки Lazarus (LCL win32).
//
//  В LCL у TApplication нет OnMessage. Здесь ставится ловушка
//  WH_GETMESSAGE на главный поток: она видит каждое сообщение, которое
//  GetMessage / PeekMessage(PM_REMOVE) забирают из очереди, до того как
//  его разберёт окно. Обработчик получает то же, что получал
//  Application.OnMessage: TMsg и Handled. Handled = True - сообщение
//  заменяется на WM_NULL, и окно его не получает.
//
//  Сообщения, которые PeekMessage только смотрит (PM_NOREMOVE), обработчику
//  не передаются: их потом заберут ещё раз.
//
//  Linux (gtk2): очереди сообщений Windows нет. Обработчику передаются
//  нажатия клавиш (WM_KEYDOWN, с Alt - WM_SYSKEYDOWN) из
//  Application.AddOnKeyDownBeforeHandler: LCL зовёт его до KeyPreview
//  формы и до ярлыков меню, как было с Application.OnMessage. hwnd -
//  Handle элемента с фокусом. Handled = True - клавиша дальше не идёт.
//  Символы (WM_CHAR) и мышь сюда не попадают.
// ---------------------------------------------------------------------------

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
  {$IFDEF UNIX}Classes, Controls, Forms, LCLType, {$ENDIF}Windows, Messages;

type
  TAppMsgEvent = procedure(var Msg: TMsg; var Handled: Boolean) of object;

// Поставить ловушку (повторный вызов заменяет обработчик); nil - снять
procedure AppMsgHookSet(AHandler: TAppMsgEvent);

implementation

{$IFDEF UNIX}
type
  TAppKeyHook = class
    procedure KeyBefore(Sender: TObject; var Key: Word; Shift: TShiftState);
  end;

var
  KeyHookHandler: TAppMsgEvent = nil;
  KeyHook: TAppKeyHook = nil;
  KeyHookBusy: Boolean = False;

procedure TAppKeyHook.KeyBefore(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  KeyMsg: TMsg;
  Handled: Boolean;
begin
  if not Assigned(KeyHookHandler) or KeyHookBusy or (Key = VK_UNKNOWN) then
    Exit;
  FillChar(KeyMsg, SizeOf(KeyMsg), 0);
  if (Sender is TWinControl) and TWinControl(Sender).HandleAllocated then
    KeyMsg.hwnd := TWinControl(Sender).Handle;
  if ssAlt in Shift then
    KeyMsg.message := WM_SYSKEYDOWN
  else
    KeyMsg.message := WM_KEYDOWN;
  KeyMsg.wParam := Key;
  Handled := False;
  KeyHookBusy := True;
  try
    KeyHookHandler(KeyMsg, Handled);
  finally
    KeyHookBusy := False;
  end;
  if Handled then
    Key := VK_UNKNOWN;
end;

procedure AppMsgHookSet(AHandler: TAppMsgEvent);
begin
  KeyHookHandler := AHandler;
  if Assigned(AHandler) and (KeyHook = nil) then
  begin
    KeyHook := TAppKeyHook.Create;
    Application.AddOnKeyDownBeforeHandler(KeyHook.KeyBefore);
  end
  else if not Assigned(AHandler) and (KeyHook <> nil) then
  begin
    if Application <> nil then
      Application.RemoveOnKeyDownBeforeHandler(KeyHook.KeyBefore);
    KeyHook.Free;
    KeyHook := nil;
  end;
end;
{$ELSE}

var
  HookHandle: HHOOK = 0;
  HookHandler: TAppMsgEvent = nil;
  HookBusy: Boolean = False;

function GetMsgProc(ACode: Integer; AWParam: WPARAM; ALParam: LPARAM): LRESULT; stdcall;
var
  MsgPtr: PMsg;
  Handled: Boolean;
begin
  if (ACode = HC_ACTION) and (AWParam = PM_REMOVE) and
     Assigned(HookHandler) and not HookBusy then
  begin
    MsgPtr := PMsg(ALParam);
    Handled := False;
    // Обработчик может сам вызвать Application.ProcessMessages - без
    // вложенного вызова себя же
    HookBusy := True;
    try
      HookHandler(MsgPtr^, Handled);
    finally
      HookBusy := False;
    end;
    if Handled then
      MsgPtr^.message := WM_NULL;
  end;
  Result := CallNextHookEx(HookHandle, ACode, AWParam, ALParam);
end;

procedure AppMsgHookSet(AHandler: TAppMsgEvent);
begin
  HookHandler := AHandler;
  if Assigned(AHandler) and (HookHandle = 0) then
    HookHandle := SetWindowsHookEx(WH_GETMESSAGE, @GetMsgProc, 0,
                                   GetCurrentThreadId)
  else if not Assigned(AHandler) and (HookHandle <> 0) then
  begin
    UnhookWindowsHookEx(HookHandle);
    HookHandle := 0;
  end;
end;
{$ENDIF}

initialization

finalization
  AppMsgHookSet(nil);

end.
