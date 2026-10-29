program SwitchTest;

// Переключение «свой редактор / RichEdit» посреди сеанса (TEdRichEmu.
// TakeFromWindow / GiveToWindow): текст (UTF-16), выделение, первая видимая
// строка, «изменён» и маска уведомлений переходят без потерь, лишних
// EN_CHANGE нет. Окно - настоящий RichEdit 4.1 (msftedit.dll).
//
// Сборка - Free Pascal win32 (или Delphi 7), запуск - Windows или Wine:
//   fpc -Twin32 -Mdelphi -Fu..\.. SwitchTest.dpr

{$APPTYPE CONSOLE}
{$MODE DELPHI}

uses
  Windows, Messages, SysUtils, Classes, EdBuffer, EdEditor, EdRichEmu;

const
  EM_EXGETSEL_ = WM_USER + 52;
  EM_SETEVENTMASK_ = WM_USER + 69;
  EM_GETEVENTMASK_ = WM_USER + 59;
  EM_GETTEXTEX_ = WM_USER + 94;
  EM_GETTEXTLENGTHEX_ = WM_USER + 95;
  EM_SETTEXTEX_ = WM_USER + 97;
  ENM_CHANGE_ = 1;
  ENM_SELCHANGE_ = $80000;

type
  TRange = record
    cpMin, cpMax: Longint;
  end;
  TGetTextEx = record
    cb: DWORD;
    flags: DWORD;
    codepage: UINT;
    lpDefaultChar: PAnsiChar;
    lpUsedDefChar: PBOOL;
  end;
  TGetTextLengthEx = record
    flags: DWORD;
    codepage: UINT;
  end;
  TSetTextEx = record
    flags: DWORD;
    codepage: UINT;
  end;

  THost = class
    Wnd: HWND;
    OldProc: Pointer;
    function GetHandle: HWND;
    procedure DefProc(var Message: TMessage);
    procedure LogLine(const AText: string);
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

procedure THost.LogLine(const AText: string);
begin
  Writeln('  [log] ', AText);
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

// Текст окна (через оконную процедуру - свой редактор, если он есть)
function TextOf(AReal: Boolean): WideString;
var
  LenInfo: TGetTextLengthEx;
  GetInfo: TGetTextEx;
  Chars: Integer;
begin
  LenInfo.flags := 0;
  LenInfo.codepage := 1200;
  if AReal then
    Chars := CallWindowProcA(Host.OldProc, EditWnd, EM_GETTEXTLENGTHEX_,
      Integer(@LenInfo), 0)
  else
    Chars := SendMessageA(EditWnd, EM_GETTEXTLENGTHEX_, Integer(@LenInfo), 0);
  SetLength(Result, Chars + 1);
  FillChar(GetInfo, SizeOf(GetInfo), 0);
  GetInfo.cb := (Chars + 1) * 2;
  GetInfo.codepage := 1200;
  if AReal then
    Chars := CallWindowProcA(Host.OldProc, EditWnd, EM_GETTEXTEX_,
      Integer(@GetInfo), Integer(PWideChar(Result)))
  else
    Chars := SendMessageA(EditWnd, EM_GETTEXTEX_, Integer(@GetInfo),
      Integer(PWideChar(Result)));
  SetLength(Result, Chars);
end;

function SelOf: string;
var
  Range: TRange;
begin
  SendMessageA(EditWnd, EM_EXGETSEL_, 0, Integer(@Range));
  Result := IntToStr(Range.cpMin) + '..' + IntToStr(Range.cpMax);
end;

var
  WndClass: TWndClassA;
  SetInfo: TSetTextEx;
  LineNo, ChangesBefore, TopBefore, MaskBefore: Integer;
  Source, Before, Expected: WideString;
  SelBefore: string;
  Ins: AnsiString;
begin
  if LoadLibrary('msftedit.dll') = 0 then
  begin
    Writeln('msftedit.dll не загрузилась');
    Halt(2);
  end;
  FillChar(WndClass, SizeOf(WndClass), 0);
  WndClass.lpfnWndProc := @ParentProc;
  WndClass.hInstance := HInstance;
  WndClass.lpszClassName := 'SwitchParent';
  RegisterClassA(WndClass);
  ParentWnd := CreateWindowExA(0, 'SwitchParent', 'sw', WS_OVERLAPPEDWINDOW,
    0, 0, 600, 400, 0, 0, HInstance, nil);
  EditWnd := CreateWindowExA(0, 'RICHEDIT50W', '', WS_CHILD or WS_VISIBLE or
    ES_MULTILINE or WS_VSCROLL, 0, 0, 580, 300, ParentWnd, 101, HInstance, nil);
  Host := THost.Create;
  Host.Wnd := EditWnd;
  Host.OldProc := Pointer(SetWindowLongA(EditWnd, GWL_WNDPROC,
    Integer(@EditProc)));
  ShowWindow(ParentWnd, SW_SHOW);

  // Текст с символами вне cp1251: греческая омега и знак «примерно равно»
  Source := '';
  for LineNo := 1 to 200 do
    Source := Source + 'строка ' + WideString(IntToStr(LineNo)) + ' ' +
      WideChar($03A9) + WideChar($2248) + #9'x'#13;
  SetInfo.flags := 0;
  SetInfo.codepage := 1200;
  SendMessageA(EditWnd, EM_SETTEXTEX_, Integer(@SetInfo),
    Integer(PWideChar(Source)));
  SendMessageA(EditWnd, EM_SETEVENTMASK_, 0, ENM_CHANGE_ or ENM_SELCHANGE_);
  SendMessageA(EditWnd, EM_SETSEL, 500, 510);
  SendMessageA(EditWnd, EM_LINESCROLL, 0, 30);
  SendMessageA(EditWnd, EM_SETMODIFY, 1, 0);

  Before := TextOf(False);
  SelBefore := SelOf;
  TopBefore := SendMessageA(EditWnd, EM_GETFIRSTVISIBLELINE, 0, 0);
  MaskBefore := SendMessageA(EditWnd, EM_GETEVENTMASK_, 0, 0);
  ChangesBefore := ChangeCount;
  Writeln('RichEdit: ', Length(Before), ' chars, sel ', SelBefore,
    ', first visible ', TopBefore);

  // --- RichEdit -> свой ---
  Emu := TEdRichEmu.Create(Host.GetHandle, Host.DefProc);
  Emu.OnLog := Host.LogLine;
  Emu.SetMetrics(16, 8, 4);
  Emu.TakeFromWindow;
  Check('own: text same', TextOf(False) = Before);
  Check('own: sel same (' + SelOf + ')', SelOf = SelBefore);
  Check('own: first visible same (' +
    IntToStr(SendMessageA(EditWnd, EM_GETFIRSTVISIBLELINE, 0, 0)) + ')',
    SendMessageA(EditWnd, EM_GETFIRSTVISIBLELINE, 0, 0) = TopBefore);
  Check('own: modified', SendMessageA(EditWnd, EM_GETMODIFY, 0, 0) <> 0);
  Check('own: event mask same',
    SendMessageA(EditWnd, EM_GETEVENTMASK_, 0, 0) = MaskBefore);
  Check('own: RichEdit text emptied', TextOf(True) = '');
  Check('own: no EN_CHANGE on switch', ChangeCount = ChangesBefore);

  // Правка через свой
  SendMessageA(EditWnd, EM_SETSEL, 0, 0);
  Ins := 'Z';
  SendMessageA(EditWnd, EM_REPLACESEL, 1, Integer(PAnsiChar(Ins)));
  Check('own: EN_CHANGE on edit', ChangeCount = ChangesBefore + 1);
  Expected := 'Z' + Before;
  SendMessageA(EditWnd, EM_SETSEL, 600, 605);
  SendMessageA(EditWnd, EM_LINESCROLL, 0, 10);
  SelBefore := SelOf;
  TopBefore := SendMessageA(EditWnd, EM_GETFIRSTVISIBLELINE, 0, 0);
  ChangesBefore := ChangeCount;

  // --- свой -> RichEdit ---
  Emu.GiveToWindow;
  FreeAndNil(Emu);
  Check('rich: text same', TextOf(False) = Expected);
  Check('rich: sel same (' + SelOf + ' / ' + SelBefore + ')',
    SelOf = SelBefore);
  Check('rich: first visible same (' +
    IntToStr(SendMessageA(EditWnd, EM_GETFIRSTVISIBLELINE, 0, 0)) + ' / ' +
    IntToStr(TopBefore) + ')',
    SendMessageA(EditWnd, EM_GETFIRSTVISIBLELINE, 0, 0) = TopBefore);
  Check('rich: modified', SendMessageA(EditWnd, EM_GETMODIFY, 0, 0) <> 0);
  Check('rich: event mask back',
    SendMessageA(EditWnd, EM_GETEVENTMASK_, 0, 0) = MaskBefore);
  Check('rich: no EN_CHANGE on switch', ChangeCount = ChangesBefore);
  SendMessageA(EditWnd, EM_REPLACESEL, 1, Integer(PAnsiChar(Ins)));
  Check('rich: EN_CHANGE on edit', ChangeCount = ChangesBefore + 1);

  Writeln('failures ', FailCount);
end.
