program TabsTest;

// Буфер вкладки в своём редакторе (TEdRichEmu.UseBuffer): окно показывает
// чужой TEdBuffer, правка и откат идут в него, при смене буфера откат
// каждого сохраняется, подписка со скрытого буфера снята, EN_CHANGE - как
// после WM_SETTEXT. Окно - RichEdit 4.1 (msftedit.dll).
//
// Сборка - Free Pascal win32, запуск - Windows или Wine:
//   fpc -Twin32 -Mdelphi -Fu..\.. TabsTest.dpr

{$APPTYPE CONSOLE}
{$MODE DELPHI}

uses
  Windows, Messages, SysUtils, Classes, EdBuffer, EdEditor, EdRichEmu;

const
  EM_SETEVENTMASK_ = WM_USER + 69;
  ENM_CHANGE_ = 1;

type
  THost = class
    Wnd: HWND;
    OldProc: Pointer;
    function GetHandle: HWND;
    procedure DefProc(var Message: TMessage);
  end;

var
  Host: THost;
  Emu: TEdRichEmu;
  ParentWnd, EditWnd: HWND;
  ChangeCount, FailCount: Integer;

function THost.GetHandle: HWND;
begin
  Result := Wnd;
end;

procedure THost.DefProc(var Message: TMessage);
begin
  Message.Result := CallWindowProcA(OldProc, Wnd, Message.Msg,
    Message.WParam, Message.LParam);
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
    Result := CallWindowProcA(Host.OldProc, AWnd, AMsg, AWParam, ALParam);
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

// Текст окна (через свой редактор), ANSI, CRLF
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

procedure TypeText(const AText: AnsiString);
var
  CharIdx: Integer;
begin
  for CharIdx := 1 to Length(AText) do
    SendMessageA(EditWnd, WM_CHAR, Ord(AText[CharIdx]), 0);
end;

var
  WndClass: TWndClassA;
  FirstTab, SecondTab: TEdBuffer;
  ChangesBefore, VersionBefore, EndRow, EndCol: Integer;
begin
  if LoadLibrary('msftedit.dll') = 0 then
  begin
    Writeln('msftedit.dll не загрузилась');
    Halt(2);
  end;
  FillChar(WndClass, SizeOf(WndClass), 0);
  WndClass.lpfnWndProc := @ParentProc;
  WndClass.hInstance := HInstance;
  WndClass.lpszClassName := 'TabsParent';
  RegisterClassA(WndClass);
  ParentWnd := CreateWindowExA(0, 'TabsParent', 'tabs', WS_OVERLAPPEDWINDOW,
    0, 0, 600, 400, 0, 0, HInstance, nil);
  EditWnd := CreateWindowExA(0, 'RICHEDIT50W', '', WS_CHILD or WS_VISIBLE or
    ES_MULTILINE or WS_VSCROLL, 0, 0, 580, 300, ParentWnd, 101, HInstance, nil);
  Host := THost.Create;
  Host.Wnd := EditWnd;
  Host.OldProc := Pointer(SetWindowLongA(EditWnd, GWL_WNDPROC,
    Integer(@EditProc)));
  SendMessageA(EditWnd, EM_SETEVENTMASK_, 0, ENM_CHANGE_);

  Emu := TEdRichEmu.Create(Host.GetHandle, Host.DefProc);
  Emu.SetMetrics(16, 8, 4);
  Emu.TakeFromWindow;

  FirstTab := TEdBuffer.Create;
  FirstTab.SetText('first tab'#13#10'line 2');
  SecondTab := TEdBuffer.Create;
  SecondTab.SetText('second');

  // Первая вкладка на экране
  ChangesBefore := ChangeCount;
  Emu.UseBuffer(FirstTab, False);
  Check('first: shown', Emu.Buffer = FirstTab);
  Check('first: text', WindowText = 'first tab'#13#10'line 2');
  Check('first: EN_CHANGE once', ChangeCount = ChangesBefore + 1);
  Check('first: not modified', SendMessageA(EditWnd, EM_GETMODIFY, 0, 0) = 0);
  SendMessageA(EditWnd, EM_SETSEL, 5, 5);
  TypeText('XY');
  Check('first: typed into buffer', FirstTab[0] = 'firstXY tab');
  Check('first: modified', SendMessageA(EditWnd, EM_GETMODIFY, 0, 0) <> 0);

  // Вторая вкладка: первая сохраняет текст и откат
  Emu.UseBuffer(SecondTab, False);
  Check('second: text', WindowText = 'second');
  Check('second: not modified', SendMessageA(EditWnd, EM_GETMODIFY, 0, 0) = 0);
  Check('first: kept text', FirstTab.GetText(#10) = 'firstXY tab'#10'line 2');
  Check('first: kept undo', FirstTab.CanUndo);
  Check('second: no undo', SendMessageA(EditWnd, EM_CANUNDO, 0, 0) = 0);
  SendMessageA(EditWnd, EM_SETSEL, 6, 6);
  TypeText('!');
  Check('second: typed', SecondTab[0] = 'second!');

  // Правка скрытого буфера окну не видна: подписка снята
  SendMessageA(EditWnd, EM_SETMODIFY, 0, 0);
  ChangesBefore := ChangeCount;
  VersionBefore := FirstTab.Version;
  FirstTab.SetText('replaced');
  Check('hidden: version grew', FirstTab.Version > VersionBefore);
  Check('hidden: window not modified',
    SendMessageA(EditWnd, EM_GETMODIFY, 0, 0) = 0);
  Check('hidden: no EN_CHANGE', ChangeCount = ChangesBefore);
  FirstTab.SetText('firstXY tab'#10'line 2');
  FirstTab.InsertText(0, 0, 'Z', False, 0, 0, EndRow, EndCol);

  // Назад к первой: откат - её
  Emu.UseBuffer(FirstTab, True);
  Check('first again: modified as given',
    SendMessageA(EditWnd, EM_GETMODIFY, 0, 0) <> 0);
  Check('first again: can undo', SendMessageA(EditWnd, EM_CANUNDO, 0, 0) <> 0);
  SendMessageA(EditWnd, EM_UNDO, 0, 0);
  Check('first again: undo in its buffer (' + WindowText + ')',
    WindowText = 'firstXY tab'#13#10'line 2');

  // Свой буфер снова: пустой, буферы вкладок не тронуты
  Emu.UseBuffer(nil, False);
  Check('own: empty', WindowText = '');
  Check('own: tabs kept', (SecondTab[0] = 'second!') and
    (FirstTab[0] = 'firstXY tab'));

  // Окно уходит раньше буферов - подписку с показанного снимает само
  Emu.UseBuffer(SecondTab, False);
  Emu.Free;
  Emu := nil;
  SecondTab.InsertText(0, 0, 'q', False, 0, 0, EndRow, EndCol);
  Check('after free: buffer usable', SecondTab[0] = 'qsecond!');
  FirstTab.Free;
  SecondTab.Free;

  Writeln('failures ', FailCount);
  if FailCount > 0 then
    Halt(1);
end.
