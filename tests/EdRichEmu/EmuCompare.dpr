program EmuCompare;

// Сверка TEdRichEmu с настоящим RichEdit 4.1 (msftedit.dll): два окна
// RICHEDIT50W, созданные ANSI-функцией (как у VCL). Окно B подменено:
// его сообщения сначала разбирает TEdRichEmu, остальное - сам RichEdit.
// Одни и те же сообщения уходят в A и B, ответы сравниваются.
//
// Сборка - Free Pascal win32 (или Delphi 7), запуск - Windows или Wine:
//   fpc -Twin32 -Mdelphi -Fu..\.. EmuCompare.dpr
// Известные расхождения (проверка под Wine, msftedit Wine 9.0): индексы за
// концом текста, EM_LINELENGTH(-1), выделение всего (у RichEdit - на символ
// больше: знак конца документа), Modified после WM_SETTEXT, место каретки
// после отката.

{$APPTYPE CONSOLE}
{$MODE DELPHI}

uses
  Windows, Messages, SysUtils, Classes, EdBuffer, EdEditor, EdRichEmu;

type
  THost = class
    Wnd: HWND;
    OldProc: Pointer;
    function GetHandle: HWND;
    procedure DefProc(var Message: TMessage);
    procedure LogLine(const AText: string);
  end;

const
  EM_EXGETSEL_ = WM_USER + 52;
  EM_EXSETSEL_ = WM_USER + 55;
  EM_EXLINEFROMCHAR_ = WM_USER + 54;
  EM_GETTEXTRANGE_ = WM_USER + 75;
  EM_GETSELTEXT_ = WM_USER + 62;
  EM_SETEVENTMASK_ = WM_USER + 69;
  EM_GETTEXTEX_ = WM_USER + 94;
  EM_GETTEXTLENGTHEX_ = WM_USER + 95;
  EM_FINDTEXTW_ = WM_USER + 123;
  EM_REDO_ = WM_USER + 84;
  EM_CANREDO_ = WM_USER + 85;
  EM_POSFROMCHAR_ = WM_USER + 38;
  ENM_CHANGE_ = 1;
  ENM_SELCHANGE_ = $80000;

type
  TRange = record
    cpMin, cpMax: Longint;
  end;
  TTextRangeW = record
    chrg: TRange;
    lpstrText: PWideChar;
  end;
  TFindTextW = record
    chrg: TRange;
    lpstrText: PWideChar;
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

var
  Host: THost;
  Emu: TEdRichEmu;
  ParentWnd, WndA, WndB: HWND;
  ChangeA, ChangeB, SelA, SelB: Integer;
  CheckCount, FailCount: Integer;
  CurrentOp: string;

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

function EmuWndProc(AWnd: HWND; AMsg: UINT; AWParam: WPARAM;
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
  begin
    if HWND(ALParam) = WndA then
      Inc(ChangeA)
    else if HWND(ALParam) = WndB then
      Inc(ChangeB);
  end;
  if (AMsg = WM_NOTIFY) and (PNMHdr(ALParam)^.code = $0702) then
  begin
    if PNMHdr(ALParam)^.hwndFrom = WndA then
      Inc(SelA)
    else if PNMHdr(ALParam)^.hwndFrom = WndB then
      Inc(SelB);
  end;
  Result := DefWindowProcA(AWnd, AMsg, AWParam, ALParam);
end;

procedure Same(const AWhat, AValA, AValB: string);
begin
  Inc(CheckCount);
  if AValA <> AValB then
  begin
    Inc(FailCount);
    Writeln('DIFF [', CurrentOp, '] ', AWhat, ': RichEdit="', AValA,
      '" emu="', AValB, '"');
  end;
end;

function Esc(const AText: string): string;
var
  CharIdx: Integer;
begin
  Result := '';
  for CharIdx := 1 to Length(AText) do
    case AText[CharIdx] of
      #13: Result := Result + '\r';
      #10: Result := Result + '\n';
      #9: Result := Result + '\t';
      #0: Result := Result + '\0';
    else
      Result := Result + AText[CharIdx];
    end;
end;

function SendBoth(AMsg: UINT; AWParam, ALParam: Integer;
  const AWhat: string): Integer;
var
  ResA, ResB: Integer;
begin
  ResA := SendMessageA(WndA, AMsg, AWParam, ALParam);
  ResB := SendMessageA(WndB, AMsg, AWParam, ALParam);
  Same(AWhat, IntToStr(ResA), IntToStr(ResB));
  Result := ResA;
end;

function GetTextOf(AWnd: HWND): string;
var
  Len: Integer;
begin
  Len := SendMessageA(AWnd, WM_GETTEXTLENGTH, 0, 0);
  SetLength(Result, Len + 1);
  Len := SendMessageA(AWnd, WM_GETTEXT, Len + 1, Integer(PAnsiChar(Result)));
  SetLength(Result, Len);
end;

function SelOf(AWnd: HWND): string;
var
  Range: TRange;
begin
  SendMessageA(AWnd, EM_EXGETSEL_, 0, Integer(@Range));
  Result := IntToStr(Range.cpMin) + '..' + IntToStr(Range.cpMax);
end;

function LineOf(AWnd: HWND; ALine: Integer): string;
var
  Buf: array[0..255] of AnsiChar;
  Got: Integer;
begin
  FillChar(Buf, SizeOf(Buf), 0);
  PWord(@Buf[0])^ := 200;
  Got := SendMessageA(AWnd, EM_GETLINE, ALine, Integer(@Buf[0]));
  Result := IntToStr(Got) + ':' + Esc(Copy(Buf, 1, Got));
end;

function RangeOf(AWnd: HWND; AMin, AMax: Integer): string;
var
  Range: TTextRangeW;
  Buf: array[0..511] of WideChar;
  Got: Integer;
begin
  FillChar(Buf, SizeOf(Buf), 0);
  Range.chrg.cpMin := AMin;
  Range.chrg.cpMax := AMax;
  Range.lpstrText := @Buf[0];
  Got := SendMessageA(AWnd, EM_GETTEXTRANGE_, 0, Integer(@Range));
  Result := IntToStr(Got) + ':' + Esc(string(WideString(PWideChar(@Buf[0]))));
end;

function TextExOf(AWnd: HWND; AFlags: DWORD; ACodepage: UINT): string;
var
  Info: TGetTextEx;
  Buf: array[0..1023] of Byte;
  Got: Integer;
begin
  FillChar(Buf, SizeOf(Buf), 0);
  FillChar(Info, SizeOf(Info), 0);
  Info.cb := SizeOf(Buf);
  Info.flags := AFlags;
  Info.codepage := ACodepage;
  Got := SendMessageA(AWnd, EM_GETTEXTEX_, Integer(@Info), Integer(@Buf[0]));
  if ACodepage = 1200 then
    Result := IntToStr(Got) + ':' + Esc(string(WideString(PWideChar(@Buf[0]))))
  else
    Result := IntToStr(Got) + ':' + Esc(string(PAnsiChar(@Buf[0])));
end;

function LenExOf(AWnd: HWND; AFlags: DWORD; ACodepage: UINT): string;
var
  Info: TGetTextLengthEx;
begin
  Info.flags := AFlags;
  Info.codepage := ACodepage;
  Result := IntToStr(SendMessageA(AWnd, EM_GETTEXTLENGTHEX_, Integer(@Info), 0));
end;

function SelTextOf(AWnd: HWND): string;
var
  Buf: array[0..511] of WideChar;
  Got: Integer;
begin
  FillChar(Buf, SizeOf(Buf), 0);
  Got := SendMessageA(AWnd, EM_GETSELTEXT_, 0, Integer(@Buf[0]));
  Result := IntToStr(Got) + ':' + Esc(string(WideString(PWideChar(@Buf[0]))));
end;

function FindOf(AWnd: HWND; AFlags, AMin, AMax: Integer;
  const AWhat: WideString): string;
var
  Find: TFindTextW;
begin
  Find.chrg.cpMin := AMin;
  Find.chrg.cpMax := AMax;
  Find.lpstrText := PWideChar(AWhat);
  Result := IntToStr(SendMessageW(AWnd, EM_FINDTEXTW_, AFlags, Integer(@Find)));
end;

procedure CompareState(const AOp: string);
var
  LineCount, LineIdx, CharIdx, TextLen: Integer;
begin
  CurrentOp := AOp;
  Same('text', Esc(GetTextOf(WndA)), Esc(GetTextOf(WndB)));
  Same('WM_GETTEXTLENGTH', IntToStr(SendMessageA(WndA, WM_GETTEXTLENGTH, 0, 0)),
    IntToStr(SendMessageA(WndB, WM_GETTEXTLENGTH, 0, 0)));
  Same('sel', SelOf(WndA), SelOf(WndB));
  LineCount := SendBoth(EM_GETLINECOUNT, 0, 0, 'EM_GETLINECOUNT');
  for LineIdx := -1 to LineCount do
  begin
    SendBoth(EM_LINEINDEX, LineIdx, 0, 'EM_LINEINDEX ' + IntToStr(LineIdx));
    if LineIdx >= 0 then
      Same('EM_GETLINE ' + IntToStr(LineIdx), LineOf(WndA, LineIdx),
        LineOf(WndB, LineIdx));
  end;
  TextLen := SendMessageA(WndA, WM_GETTEXTLENGTH, 0, 0);
  for CharIdx := -1 to TextLen + 1 do
  begin
    SendBoth(EM_LINELENGTH, CharIdx, 0, 'EM_LINELENGTH ' + IntToStr(CharIdx));
    SendBoth(EM_LINEFROMCHAR, CharIdx, 0, 'EM_LINEFROMCHAR ' + IntToStr(CharIdx));
    SendBoth(EM_EXLINEFROMCHAR_, 0, CharIdx, 'EM_EXLINEFROMCHAR ' +
      IntToStr(CharIdx));
  end;
  Same('range 0..-1', RangeOf(WndA, 0, -1), RangeOf(WndB, 0, -1));
  Same('range 2..7', RangeOf(WndA, 2, 7), RangeOf(WndB, 2, 7));
  Same('range 5..100', RangeOf(WndA, 5, 100), RangeOf(WndB, 5, 100));
  Same('textex crlf acp', TextExOf(WndA, 1, CP_ACP), TextExOf(WndB, 1, CP_ACP));
  Same('textex cr acp', TextExOf(WndA, 0, CP_ACP), TextExOf(WndB, 0, CP_ACP));
  Same('textex crlf uni', TextExOf(WndA, 1, 1200), TextExOf(WndB, 1, 1200));
  Same('textex sel', TextExOf(WndA, 2, 1200), TextExOf(WndB, 2, 1200));
  Same('lenex crlf precise bytes acp', LenExOf(WndA, 1 or 2 or 16, CP_ACP),
    LenExOf(WndB, 1 or 2 or 16, CP_ACP));
  Same('lenex cr precise bytes acp', LenExOf(WndA, 2 or 16, CP_ACP),
    LenExOf(WndB, 2 or 16, CP_ACP));
  Same('lenex 0 uni', LenExOf(WndA, 0, 1200), LenExOf(WndB, 0, 1200));
  Same('lenex crlf uni', LenExOf(WndA, 1, 1200), LenExOf(WndB, 1, 1200));
  Same('seltext', SelTextOf(WndA), SelTextOf(WndB));
  SendBoth(EM_CANUNDO, 0, 0, 'EM_CANUNDO');
  SendBoth(EM_CANREDO_, 0, 0, 'EM_CANREDO');
  Same('modify', IntToStr(Ord(SendMessageA(WndA, EM_GETMODIFY, 0, 0) <> 0)),
    IntToStr(Ord(SendMessageA(WndB, EM_GETMODIFY, 0, 0) <> 0)));
  Same('EN_CHANGE count', IntToStr(ChangeA), IntToStr(ChangeB));
  Same('EN_SELCHANGE count', IntToStr(SelA), IntToStr(SelB));
end;

procedure SetSelBoth(AMin, AMax: Integer);
var
  Range: TRange;
begin
  Range.cpMin := AMin;
  Range.cpMax := AMax;
  SendMessageA(WndA, EM_EXSETSEL_, 0, Integer(@Range));
  Range.cpMin := AMin;
  Range.cpMax := AMax;
  SendMessageA(WndB, EM_EXSETSEL_, 0, Integer(@Range));
end;

procedure ResetCounts;
begin
  ChangeA := 0;
  ChangeB := 0;
  SelA := 0;
  SelB := 0;
end;

procedure Step(const AOp: string; AMsg: UINT; AWParam, ALParam: Integer);
begin
  ResetCounts;
  CurrentOp := AOp;
  SendBoth(AMsg, AWParam, ALParam, 'result of ' + AOp);
  CompareState(AOp);
end;

procedure TypeChars(const AText: string);
var
  CharIdx: Integer;
begin
  ResetCounts;
  for CharIdx := 1 to Length(AText) do
  begin
    SendMessageA(WndA, WM_CHAR, Ord(AText[CharIdx]), 1);
    SendMessageA(WndB, WM_CHAR, Ord(AText[CharIdx]), 1);
  end;
  CompareState('type "' + Esc(AText) + '"');
end;

const
  EM_CHARFROMPOS_ = WM_USER + 39;
  EM_SCROLLCARET_ = WM_USER + 49;

var
  WndClass: TWndClassA;
  LineNo, CharNo, Bad: Integer;
  Pt: TPoint;
  Txt: AnsiString;
  Msg: TMsg;
begin
  if LoadLibrary('msftedit.dll') = 0 then
  begin
    Writeln('msftedit.dll не загрузилась');
    Halt(2);
  end;
  FillChar(WndClass, SizeOf(WndClass), 0);
  WndClass.lpfnWndProc := @ParentProc;
  WndClass.hInstance := HInstance;
  WndClass.lpszClassName := 'EmuCmpParent';
  RegisterClassA(WndClass);
  ParentWnd := CreateWindowExA(0, 'EmuCmpParent', 'cmp', WS_OVERLAPPEDWINDOW,
    0, 0, 800, 600, 0, 0, HInstance, nil);
  WndA := CreateWindowExA(0, 'RICHEDIT50W', '', WS_CHILD or WS_VISIBLE or
    ES_MULTILINE or WS_VSCROLL, 0, 0, 380, 300, ParentWnd, 101, HInstance, nil);
  WndB := CreateWindowExA(0, 'RICHEDIT50W', '', WS_CHILD or WS_VISIBLE or
    ES_MULTILINE or WS_VSCROLL, 400, 0, 380, 300, ParentWnd, 102, HInstance, nil);
  SendMessageA(WndA, EM_SETEVENTMASK_, 0, ENM_CHANGE_ or ENM_SELCHANGE_);
  SendMessageA(WndB, EM_SETEVENTMASK_, 0, ENM_CHANGE_ or ENM_SELCHANGE_);
  Host := THost.Create;
  Host.Wnd := WndB;
  Host.OldProc := Pointer(SetWindowLongA(WndB, GWL_WNDPROC,
    Integer(@EmuWndProc)));
  Emu := TEdRichEmu.Create(Host.GetHandle, Host.DefProc);
  Emu.OnLog := Host.LogLine;
  Emu.SetMetrics(16, 8, 4);
  Emu.Start('');
  ShowWindow(ParentWnd, SW_SHOW);

  CompareState('empty');
  Txt := 'line1'#13#10'line two'#13#10#13#10'last caf'#$E9;
  Step('settext', WM_SETTEXT, 0, Integer(PAnsiChar(Txt)));
  Txt := 'a'#13#10;
  Step('settext trailing break', WM_SETTEXT, 0, Integer(PAnsiChar(Txt)));
  Txt := 'line1'#13#10'line two'#13#10#13#10'last';
  Step('settext again', WM_SETTEXT, 0, Integer(PAnsiChar(Txt)));
  Step('setsel 3,8', EM_SETSEL, 3, 8);
  Step('setsel 8,3', EM_SETSEL, 8, 3);
  Step('setsel 0,-1', EM_SETSEL, 0, -1);
  Step('setsel -1,0', EM_SETSEL, -1, 0);
  Step('setsel 100,200', EM_SETSEL, 100, 200);
  ResetCounts;
  SetSelBoth(2, 9);
  CompareState('exsetsel 2,9');
  ResetCounts;
  SetSelBoth(9, 2);
  CompareState('exsetsel 9,2');
  ResetCounts;
  SetSelBoth(0, -1);
  CompareState('exsetsel 0,-1');
  SetSelBoth(6, 6);
  Txt := 'XY'#13#10'Z';
  Step('replacesel undo', EM_REPLACESEL, 1, Integer(PAnsiChar(Txt)));
  Step('undo', EM_UNDO, 0, 0);
  Step('redo', EM_REDO_, 0, 0);
  SetSelBoth(1, 4);
  Txt := 'Q';
  Step('replacesel noundo', EM_REPLACESEL, 0, Integer(PAnsiChar(Txt)));
  Step('undo after noundo', EM_UNDO, 0, 0);
  Step('setmodify 0', EM_SETMODIFY, 0, 0);
  SetSelBoth(3, 3);
  TypeChars('abc');
  Step('undo typing', EM_UNDO, 0, 0);
  TypeChars('d'#8'e'#13'f');
  Step('undo typing 2', EM_UNDO, 0, 0);
  Step('undo typing 3', EM_UNDO, 0, 0);
  SetSelBoth(2, 2);
  ResetCounts;
  SendMessageA(WndA, WM_KEYDOWN, VK_BACK, 1); SendMessageA(WndB, WM_KEYDOWN, VK_BACK, 1);
  CompareState('keydown back');
  ResetCounts;
  SendMessageA(WndA, WM_KEYDOWN, VK_RETURN, 1); SendMessageA(WndB, WM_KEYDOWN, VK_RETURN, 1);
  CompareState('keydown return');
  ResetCounts;
  SendMessageA(WndA, WM_KEYDOWN, VK_TAB, 1); SendMessageA(WndB, WM_KEYDOWN, VK_TAB, 1);
  CompareState('keydown tab');
  TypeChars(#9'x');
  ResetCounts;
  SendMessageA(WndA, WM_KEYDOWN, VK_RIGHT, 1); SendMessageA(WndB, WM_KEYDOWN, VK_RIGHT, 1);
  SendMessageA(WndA, WM_KEYDOWN, VK_DELETE, 1); SendMessageA(WndB, WM_KEYDOWN, VK_DELETE, 1);
  CompareState('right, delete');
  Step('undo keys', EM_UNDO, 0, 0);
  Step('undo keys 2', EM_UNDO, 0, 0);
  Txt := 'one two one Two'#13#10'twofold two';
  Step('settext find', WM_SETTEXT, 0, Integer(PAnsiChar(Txt)));
  CurrentOp := 'find';
  Same('find two down', FindOf(WndA, 1, 0, -1, 'two'), FindOf(WndB, 1, 0, -1, 'two'));
  Same('find Two case', FindOf(WndA, 1 or 4, 0, -1, 'Two'), FindOf(WndB, 1 or 4, 0, -1, 'Two'));
  Same('find two from 5', FindOf(WndA, 1, 5, -1, 'two'), FindOf(WndB, 1, 5, -1, 'two'));
  Same('find two word from 13', FindOf(WndA, 1 or 2, 13, -1, 'two'), FindOf(WndB, 1 or 2, 13, -1, 'two'));
  Same('find two in 0..5', FindOf(WndA, 1, 0, 5, 'two'), FindOf(WndB, 1, 0, 5, 'two'));
  Same('find two up from 15', FindOf(WndA, 0, 15, 0, 'two'), FindOf(WndB, 0, 15, 0, 'two'));
  Same('find none', FindOf(WndA, 1, 0, -1, 'zzz'), FindOf(WndB, 1, 0, -1, 'zzz'));
  // Места символов: туда и обратно, прокрутка
  Txt := '';
  for LineNo := 1 to 100 do
    Txt := Txt + 'row'#9 + IntToStr(LineNo) + #13#10;
  SendMessageA(WndB, WM_SETTEXT, 0, Integer(PAnsiChar(Txt)));
  Bad := 0;
  for CharNo := 0 to 300 do
  begin
    SendMessageA(WndB, EM_POSFROMCHAR_, Integer(@Pt), CharNo);
    if SendMessageA(WndB, EM_CHARFROMPOS_, 0, Integer(@Pt)) <> CharNo then
      Inc(Bad);
  end;
  Writeln('pos round trip mismatches: ', Bad);
  SendMessageA(WndB, EM_LINESCROLL, 0, 1000);
  Writeln('after LINESCROLL 1000: first visible ', SendMessageA(WndB, EM_GETFIRSTVISIBLELINE, 0, 0),
    ' (lines ', SendMessageA(WndB, EM_GETLINECOUNT, 0, 0), ')');
  SendMessageA(WndB, EM_SETSEL, 5, 5);
  SendMessageA(WndB, EM_SCROLLCARET_, 0, 0);
  Writeln('after SCROLLCARET to 5: first visible ', SendMessageA(WndB, EM_GETFIRSTVISIBLELINE, 0, 0));
  SendMessageA(WndB, EM_POSFROMCHAR_, Integer(@Pt), 4);
  Writeln('pos of char 4 (after tab): ', Pt.X, ',', Pt.Y);
  Txt := '';
  Step('settext empty', WM_SETTEXT, 0, Integer(PAnsiChar(Txt)));
  while PeekMessageA(Msg, 0, 0, 0, PM_REMOVE) do
    DispatchMessageA(Msg);
  Writeln('checks ', CheckCount, ', differences ', FailCount);
end.
