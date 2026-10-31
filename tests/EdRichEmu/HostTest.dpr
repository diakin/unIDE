program HostTest;

// Окно своего редактора без RichEdit (шаг 0.7.7): окно своего класса,
// сообщения - EdHostWin.EdHostHandle, перед ним - свой редактор
// (TEdRichEmu), как в Unit1 (RichEdit1 - EdHost.TEdHostEdit). Текст до
// запуска своего редактора переходит к нему, маска уведомлений - тоже,
// область текста, «только чтение», коды клавиш.
//
// Сборка - Free Pascal win32, запуск - Windows или Wine:
//   fpc -Twin32 -Mdelphi -Fu..\.. HostTest.dpr

{$APPTYPE CONSOLE}
{$MODE DELPHI}

uses
  Windows, Messages, SysUtils, Classes, EdBuffer, EdEditor, EdRichEmu,
  EdHostWin;

const
  EM_SETEVENTMASK_ = WM_USER + 69;
  EM_GETEVENTMASK_ = WM_USER + 59;
  EM_POSFROMCHAR_ = $00D6;
  ENM_CHANGE_ = 1;

type
  THost = class
    Wnd: HWND;
    function GetHandle: HWND;
    procedure DefProc(var Message: TMessage);
  end;

var
  Host: THost;
  HostState: TEdHostState;
  Emu: TEdRichEmu;
  ParentWnd, EditWnd: HWND;
  ChangeCount, FailCount: Integer;

// Окно без своего редактора: EdHostHandle, потом DefWindowProc
function HostDefault(AWnd: HWND; var Message: TMessage): LRESULT;
begin
  if EdHostHandle(AWnd, HostState, Message) then
    Result := Message.Result
  else
    Result := DefWindowProcA(AWnd, Message.Msg, Message.WParam,
      Message.LParam);
end;

function THost.GetHandle: HWND;
begin
  Result := Wnd;
end;

procedure THost.DefProc(var Message: TMessage);
begin
  Message.Result := HostDefault(Wnd, Message);
end;

function EditProc(AWnd: HWND; AMsg: UINT; AWParam: WPARAM;
  ALParam: LPARAM): LRESULT; stdcall;
var
  Message: TMessage;
begin
  Message.Msg := AMsg;
  Message.WParam := AWParam;
  Message.LParam := ALParam;
  Message.Result := 0;
  if (Emu <> nil) and Emu.Handle(Message) then
    Result := Message.Result
  else
    Result := HostDefault(AWnd, Message);
end;

function ParentProc(AWnd: HWND; AMsg: UINT; AWParam: WPARAM;
  ALParam: LPARAM): LRESULT; stdcall;
begin
  if (AMsg = WM_COMMAND) and (HiWord(AWParam) = EN_CHANGE) then
    Inc(ChangeCount);
  Result := DefWindowProcA(AWnd, AMsg, AWParam, ALParam);
end;

procedure Check(const AWhat: string; AOk: Boolean);
begin
  if AOk then
    Writeln('ok   ', AWhat)
  else
  begin
    Inc(FailCount);
    Writeln('FAIL ', AWhat);
  end;
end;

function WindowText: AnsiString;
var
  TextLen: Integer;
begin
  TextLen := SendMessageA(EditWnd, WM_GETTEXTLENGTH, 0, 0);
  SetLength(Result, TextLen + 1);
  TextLen := SendMessageA(EditWnd, WM_GETTEXT, TextLen + 1,
    Integer(PAnsiChar(Result)));
  SetLength(Result, TextLen);
end;

// Сравнение байтами: у строк cp1251 '=' Free Pascal сравнивает через
// перекодировку, под Wine она даёт неравенство и у одинаковых байтов
function SameBytes(const ALeft, ARight: AnsiString): Boolean;
begin
  Result := (Length(ALeft) = Length(ARight)) and ((ALeft = '') or
    (CompareByte(ALeft[1], ARight[1], Length(ALeft)) = 0));
end;

procedure TypeText(const AText: AnsiString);
var
  CharIdx: Integer;
begin
  for CharIdx := 1 to Length(AText) do
    SendMessageA(EditWnd, WM_CHAR, Ord(AText[CharIdx]), 0);
end;

var
  WndClass: TWndClassA;
  TextRect, GotRect: TRect;
  CharPt: TPoint;
  ChangesBefore: Integer;
  BaseText, TypedText: AnsiString;
begin
  // Кириллица cp1251 байтами: литерал перекодировался бы по кодовой
  // странице системы
  BaseText := 'abc'#13#10'xyz';
  BaseText[6] := AnsiChar($E0);
  BaseText[7] := AnsiChar($E1);
  BaseText[8] := AnsiChar($E2);
  TypedText := 'abcX'#13#10'xyz';
  TypedText[7] := AnsiChar($E0);
  TypedText[8] := AnsiChar($E1);
  TypedText[9] := AnsiChar($E2);
  EdHostInit(HostState);
  FillChar(WndClass, SizeOf(WndClass), 0);
  WndClass.lpfnWndProc := @ParentProc;
  WndClass.hInstance := HInstance;
  WndClass.lpszClassName := 'HostParent';
  RegisterClassA(WndClass);
  FillChar(WndClass, SizeOf(WndClass), 0);
  WndClass.lpfnWndProc := @EditProc;
  WndClass.hInstance := HInstance;
  WndClass.style := CS_DBLCLKS;
  WndClass.lpszClassName := 'HostEdit';
  RegisterClassA(WndClass);
  ParentWnd := CreateWindowExA(0, 'HostParent', 'host', WS_OVERLAPPEDWINDOW,
    0, 0, 600, 400, 0, 0, HInstance, nil);
  EditWnd := CreateWindowExA(0, 'HostEdit', '', WS_CHILD or WS_VISIBLE,
    0, 0, 580, 300, ParentWnd, 101, HInstance, nil);
  Host := THost.Create;
  Host.Wnd := EditWnd;

  // --- До своего редактора ---
  SendMessageA(EditWnd, EM_SETEVENTMASK_, 0, ENM_CHANGE_);
  Check('pre: event mask kept',
    SendMessageA(EditWnd, EM_GETEVENTMASK_, 0, 0) = ENM_CHANGE_);
  SendMessageA(EditWnd, WM_SETTEXT, 0, Integer(PAnsiChar(BaseText)));
  Check('pre: window text', SameBytes(WindowText, BaseText));
  Check('pre: dlgcode', SendMessageA(EditWnd, WM_GETDLGCODE, 0, 0) =
    DLGC_WANTARROWS or DLGC_WANTTAB or DLGC_WANTCHARS or DLGC_WANTALLKEYS);
  Check('pre: unknown EM_ -> 0', SendMessageA(EditWnd, WM_USER + 71, 5, 0) = 0);

  // --- Свой редактор забирает текст и маску ---
  Emu := TEdRichEmu.Create(Host.GetHandle, Host.DefProc);
  Emu.SetMetrics(16, 8, 4);
  Emu.TakeFromWindow;

  Check('emu: text taken', SameBytes(WindowText, BaseText));
  Check('emu: 2 lines', SendMessageA(EditWnd, EM_GETLINECOUNT, 0, 0) = 2);
  Check('emu: not modified', SendMessageA(EditWnd, EM_GETMODIFY, 0, 0) = 0);

  ChangesBefore := ChangeCount;
  SendMessageA(EditWnd, EM_SETSEL, 3, 3);
  TypeText('X');
  Check('emu: typed', SameBytes(WindowText, TypedText));
  Check('emu: EN_CHANGE after typing', ChangeCount = ChangesBefore + 1);
  Check('emu: modified', SendMessageA(EditWnd, EM_GETMODIFY, 0, 0) <> 0);
  SendMessageA(EditWnd, EM_UNDO, 0, 0);
  Check('emu: undo', SameBytes(WindowText, BaseText));

  // --- Область текста ---
  SendMessageA(EditWnd, EM_GETRECT, 0, Integer(@GotRect));
  Check('rect: client by default', (GotRect.Left = 0) and (GotRect.Top = 0) and
    (GotRect.Right = 580) and (GotRect.Bottom = 300));
  TextRect := Rect(10, 4, 500, 280);
  SendMessageA(EditWnd, EM_SETRECT, 0, Integer(@TextRect));
  SendMessageA(EditWnd, EM_GETRECT, 0, Integer(@GotRect));
  Check('rect: set', EqualRect(GotRect, TextRect));
  SendMessageA(EditWnd, EM_POSFROMCHAR_, Integer(@CharPt), 5);
  Check('rect: char point uses rect (' + IntToStr(CharPt.X) + ',' +
    IntToStr(CharPt.Y) + ')', (CharPt.X = 10 + 8) and (CharPt.Y = 4 + 16));
  SendMessageA(EditWnd, EM_SETRECT, 0, 0);
  SendMessageA(EditWnd, EM_GETRECT, 0, Integer(@GotRect));
  Check('rect: reset', GotRect.Right = 580);

  // --- Только чтение ---
  SendMessageA(EditWnd, EM_SETREADONLY, 1, 0);
  Check('readonly: style', GetWindowLongA(EditWnd, GWL_STYLE) and
    ES_READONLY <> 0);
  TypeText('Z');
  Check('readonly: no typing', SameBytes(WindowText, BaseText));
  SendMessageA(EditWnd, EM_SETREADONLY, 0, 0);
  TypeText('Z');
  Check('readonly off: typing', Pos('Z', WindowText) > 0);

  DestroyWindow(ParentWnd);
  if FailCount = 0 then
    Writeln('HostTest: all ok')
  else
    Writeln('HostTest: ', FailCount, ' failed');
  Halt(Ord(FailCount > 0));
end.
