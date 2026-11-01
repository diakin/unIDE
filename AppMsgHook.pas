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
// ---------------------------------------------------------------------------

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}

interface

uses
  Windows, Messages;

type
  TAppMsgEvent = procedure(var Msg: TMsg; var Handled: Boolean) of object;

// Поставить ловушку (повторный вызов заменяет обработчик); nil - снять
procedure AppMsgHookSet(AHandler: TAppMsgEvent);

implementation

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

initialization

finalization
  AppMsgHookSet(nil);

end.
