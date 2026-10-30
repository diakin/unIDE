unit EdRichEmu;

// ---------------------------------------------------------------------------
//  Свой редактор вместо RichEdit в основном окне unIDE (план портирования,
//  шаг 0.7.4): ответы на сообщения окна RichEdit 4.1 из TEdBuffer /
//  TEdEditor.
//
//  Unit1 говорит с RichEdit1 сообщениями: прослойка EdApi (EM_*), свойства
//  VCL (SelStart - EM_EXGETSEL, Modified - EM_GETMODIFY, SetTextBuf -
//  WM_SETTEXT...), ввод с клавиатуры и мыши. В режиме «свой редактор»
//  оконная процедура RichEdit1 (NewRichEditProc) отдаёт их сюда раньше
//  самого RichEdit: что разобрано (Handle = True), до RichEdit не доходит.
//  Текст, выделение, откат, строки и места символов на экране - отсюда;
//  RichEdit остаётся окном без текста: фокус, курсор мыши, область текста
//  (EM_GETRECT / EM_SETRECT, поля), формат - его. Рисует, как и раньше,
//  Unit1 (HighlightVisibleText) по местам символов, которые даёт
//  EM_POSFROMCHAR.
//
//  Модель - как у RichEdit 4.1: сквозной индекс символа, перевод строки -
//  один символ (CR); WM_GETTEXT / WM_GETTEXTLENGTH и EM_GETTEXTEX с
//  GT_USECRLF - через CRLF. Окно ANSI (VCL), поэтому WM_GETTEXT,
//  WM_SETTEXT, EM_GETLINE, EM_REPLACESEL, WM_CHAR - в кодировке Windows,
//  а EM_GETTEXTRANGE, EM_GETSELTEXT, EM_FINDTEXTW - в UTF-16, как отвечал
//  RichEdit 4.1.
//
//  Экран: шрифт моноширинный - ячейка CharW x LineH (SetMetrics), строка
//  ARow - на высоте (ARow - первая видимая) x LineH от верха области
//  текста; табуляции - по TabChars колонок. Прокрутка - построчно.
//
//  Уведомления родителю - как у RichEdit, по маске EM_SETEVENTMASK:
//  EN_CHANGE (WM_COMMAND) после правки, EN_SELCHANGE (WM_NOTIFY) после
//  смены выделения - в конце сообщения, которое их вызвало.
//
//  Сообщение EM_*, которого здесь нет, уходит к RichEdit как раньше и
//  один раз пишется в журнал (OnLog): по нему видно, чего не хватает.
// ---------------------------------------------------------------------------

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  Windows, Messages, SysUtils, Classes, EdBuffer, EdEditor;

type
  TEdEmuHandleFunc = function: HWND of object;
  TEdEmuDefProc = procedure(var Message: TMessage) of object;
  TEdEmuLogEvent = procedure(const AText: string) of object;

  TEdRichEmu = class
  private
    FGetHandle: TEdEmuHandleFunc;
    FDefProc: TEdEmuDefProc;
    FBuffer: TEdBuffer;         // текст на экране: свой или буфер вкладки
    FOwnBuffer: TEdBuffer;      // свой (UseBuffer(nil))
    FEditor: TEdEditor;
    FTopRow: Integer;
    FLineH: Integer;
    FCharW: Integer;
    FModified: Boolean;
    FEventMask: Integer;
    FLimitText: Integer;
    FDepth: Integer;            // вложенность разбираемых сообщений
    FTextChanged: Boolean;      // за сообщение менялся текст
    FNeedPaint: Boolean;
    FUserMove: Boolean;         // ввод пользователя: каретку показать
    FLastSelMin: Integer;       // выделение, о котором уже сообщено
    FLastSelMax: Integer;
    FMouseSel: Boolean;         // левая кнопка нажата, выделение мышью
    FMousePt: TPoint;
    FDblTick: Cardinal;
    FDblPt: TPoint;
    FTimerOn: Boolean;
    FLogged: TList;             // номера сообщений, уже записанных в журнал
    FOnLog: TEdEmuLogEvent;
    function Wnd: HWND;
    function DefSend(AMsg: Cardinal; AWParam, ALParam: Integer): Integer;
    procedure BufferChanged(Sender: TObject; AFirst, AOldCount,
      ANewCount: Integer);
    procedure EditorMoved(Sender: TObject);
    procedure EditorScroll(Sender: TObject; ARows: Integer);
    procedure Log(const AText: string);
    procedure LogOnce(AMsg: Cardinal);
    // Индексы и места
    function CaretIndex: Integer;
    procedure GetSelIdx(var AMin, AMax: Integer);
    procedure SetSelIdx(AAnchor, AActive: Integer);
    procedure IdxToPos(AIndex: Integer; var ARow, ACol: Integer);
    function PosToIdx(ARow, ACol: Integer): Integer;
    function TextRect: TRect;
    function VisibleRows: Integer;
    function MaxTopRow: Integer;
    procedure ScrollToRow(ATop: Integer);
    procedure ScrollCaretIntoView;
    procedure CharPoint(AIndex: Integer; var APt: TPoint);
    function PointChar(const APt: TPoint): Integer;
    procedure PointPos(const APt: TPoint; var ARow, ACol: Integer);
    // Текст
    function WideText(AUseCrlf: Boolean): WideString;
    function TextLen(AUseCrlf: Boolean; ACodePage: UINT): Integer;
    function RangeText(AMin, AMax: Integer; AUseCrlf: Boolean): WideString;
    procedure SetAllText(const AText: WideString);
    procedure ReplaceSelText(const AText: WideString; ACanUndo: Boolean);
    function FindText(AFlags: Integer; AMin, AMax: Integer;
      const AWhat: WideString): Integer;
    // Сообщения
    procedure DoStreamIn(var Message: TMessage);
    procedure DoStreamOut(var Message: TMessage);
    function DoKeyDown(AKey: Word): Boolean;
    procedure DoChar(ACode: Integer);
    procedure DoMouseDown(var Message: TMessage; ADouble: Boolean);
    procedure DoMouseMove(var Message: TMessage);
    procedure DoMouseUp;
    procedure DoTimer;
    procedure Notify;
  public
    // AGetHandle - окно RichEdit1 (спрашивается каждый раз: VCL пересоздаёт
    // окно); ADefProc - прежняя оконная процедура (сам RichEdit)
    constructor Create(AGetHandle: TEdEmuHandleFunc; ADefProc: TEdEmuDefProc);
    destructor Destroy; override;
    // Начать работу: маска уведомлений - у RichEdit, его собственные
    // уведомления выключаются; текст - из ATakeText (ANSI, строки через
    // CRLF) - то, что было в RichEdit
    procedure Start(const ATakeText: string);
    // Начать работу посреди сеанса (переключение в IDE Options): текст,
    // выделение, первая видимая строка и «изменён» - у самого RichEdit; его
    // текст потом очищается. Откат начинается заново
    procedure TakeFromWindow;
    // Закончить работу посреди сеанса: текст, выделение, первая видимая
    // строка, «изменён» и маска уведомлений - обратно RichEdit. Откат у
    // RichEdit начинается заново. После вызова объект только освободить
    procedure GiveToWindow;
    // Показать другой текст - буфер вкладки (Unit1): буфер окну не
    // принадлежит, освобождает его хозяин, и до освобождения окно должно
    // перейти на другой буфер; nil - снова свой (очищается). Откат - у
    // буфера, поэтому он сохраняется между показами. Каретка - в начале,
    // прокрутка - сверху, «изменён» - AModified. Уведомления - как после
    // WM_SETTEXT (EN_CHANGE)
    procedure UseBuffer(ABuffer: TEdBuffer; AModified: Boolean);
    // Шаг строк и ширина символа (шрифт RichEdit1), табуляция - колонок
    procedure SetMetrics(ALineH, ACharW, ATabChars: Integer);
    // Сообщение окну RichEdit1: True - разобрано здесь, Message.Result -
    // ответ; False - отдать RichEdit
    function Handle(var Message: TMessage): Boolean;
    property Buffer: TEdBuffer read FBuffer;
    property Editor: TEdEditor read FEditor;
    property TopRow: Integer read FTopRow;
    property LineH: Integer read FLineH;
    property CharW: Integer read FCharW;
    property OnLog: TEdEmuLogEvent read FOnLog write FOnLog;
  end;

implementation

const
  // RichEdit.h - свои константы: в модуле Delphi 7 части нет
  EM_GETLIMITTEXT_ = WM_USER + 37;
  EM_POSFROMCHAR_ = WM_USER + 38;
  EM_CHARFROMPOS_ = WM_USER + 39;
  EM_SCROLLCARET_ = WM_USER + 49;
  // Те же четыре сообщения под номерами поля ввода (Messages.pas Delphi 7:
  // EM_GETLIMITTEXT = $D5, EM_POSFROMCHAR = $D6, EM_CHARFROMPOS = $D7,
  // EM_SCROLLCARET = $B7). RichEdit 4.1 отвечает на оба номера одинаково.
  // В RichEdit.pas Delphi 7 этой части RichEdit.h нет, и Unit1 / EdIntf
  // получают номера из Messages.pas
  EM_GETLIMITTEXT_ED = $00D5;
  EM_POSFROMCHAR_ED = $00D6;
  EM_CHARFROMPOS_ED = $00D7;
  EM_SCROLLCARET_ED = $00B7;
  EM_CANPASTE_ = WM_USER + 50;
  EM_DISPLAYBAND_ = WM_USER + 51;
  EM_EXGETSEL_ = WM_USER + 52;
  EM_EXLIMITTEXT_ = WM_USER + 53;
  EM_EXLINEFROMCHAR_ = WM_USER + 54;
  EM_EXSETSEL_ = WM_USER + 55;
  EM_FINDTEXT_ = WM_USER + 56;
  EM_FORMATRANGE_ = WM_USER + 57;
  EM_GETCHARFORMAT_ = WM_USER + 58;
  EM_GETEVENTMASK_ = WM_USER + 59;
  EM_GETOLEINTERFACE_ = WM_USER + 60;
  EM_GETPARAFORMAT_ = WM_USER + 61;
  EM_GETSELTEXT_ = WM_USER + 62;
  EM_HIDESELECTION_ = WM_USER + 63;
  EM_PASTESPECIAL_ = WM_USER + 64;
  EM_REQUESTRESIZE_ = WM_USER + 65;
  EM_SELECTIONTYPE_ = WM_USER + 66;
  EM_SETBKGNDCOLOR_ = WM_USER + 67;
  EM_SETCHARFORMAT_ = WM_USER + 68;
  EM_SETEVENTMASK_ = WM_USER + 69;
  EM_SETOLECALLBACK_ = WM_USER + 70;
  EM_SETPARAFORMAT_ = WM_USER + 71;
  EM_SETTARGETDEVICE_ = WM_USER + 72;
  EM_STREAMIN_ = WM_USER + 73;
  EM_STREAMOUT_ = WM_USER + 74;
  EM_GETTEXTRANGE_ = WM_USER + 75;
  EM_FINDWORDBREAK_ = WM_USER + 76;
  EM_SETOPTIONS_ = WM_USER + 77;
  EM_GETOPTIONS_ = WM_USER + 78;
  EM_FINDTEXTEX_ = WM_USER + 79;
  EM_SETUNDOLIMIT_ = WM_USER + 82;
  EM_REDO_ = WM_USER + 84;
  EM_CANREDO_ = WM_USER + 85;
  EM_GETUNDONAME_ = WM_USER + 86;
  EM_GETREDONAME_ = WM_USER + 87;
  EM_STOPGROUPTYPING_ = WM_USER + 88;
  EM_SETTEXTMODE_ = WM_USER + 89;
  EM_GETTEXTMODE_ = WM_USER + 90;
  EM_AUTOURLDETECT_ = WM_USER + 91;
  EM_GETTEXTEX_ = WM_USER + 94;
  EM_GETTEXTLENGTHEX_ = WM_USER + 95;
  EM_SHOWSCROLLBAR_ = WM_USER + 96;
  EM_SETTEXTEX_ = WM_USER + 97;
  EM_SETLANGOPTIONS_ = WM_USER + 120;
  EM_GETLANGOPTIONS_ = WM_USER + 121;
  EM_FINDTEXTW_ = WM_USER + 123;
  EM_FINDTEXTEXW_ = WM_USER + 124;
  EM_SETEDITSTYLE_ = WM_USER + 204;
  EM_GETEDITSTYLE_ = WM_USER + 205;
  EM_GETSCROLLPOS_ = WM_USER + 221;
  EM_SETSCROLLPOS_ = WM_USER + 222;
  EM_SETFONTSIZE_ = WM_USER + 223;
  EM_GETZOOM_ = WM_USER + 224;
  EM_SETZOOM_ = WM_USER + 225;
  EM_SETTYPOGRAPHYOPTIONS_ = WM_USER + 202;
  EM_GETTYPOGRAPHYOPTIONS_ = WM_USER + 203;

  ENM_CHANGE_ = $00000001;
  ENM_SELCHANGE_ = $00080000;
  EN_SELCHANGE_ = $0702;
  SEL_EMPTY_ = 0;
  SEL_TEXT_ = 1;
  SEL_MULTICHAR_ = 4;

  GT_USECRLF_ = 1;
  GT_SELECTION_ = 2;
  GTL_USECRLF_ = 1;
  GTL_NUMBYTES_ = 16;
  ST_SELECTION_ = 2;
  ST_UNICODE_ = 8;
  CP_UNICODE_ = 1200;

  FR_DOWN_ = 1;
  FR_WHOLEWORD_ = 2;
  FR_MATCHCASE_ = 4;

  SF_TEXT_ = 1;
  SF_UNICODE_ = 16;
  SFF_SELECTION_ = $8000;

  // Свой таймер прокрутки при выделении мышью у края
  EmuTimerId = $4544;
  // Предел объёма текста по умолчанию (RichEdit - 32767, VCL ставит больше)
  EmuDefaultLimit = $7FFFFFFF;

type
  TEmuCharRange = record
    cpMin: Longint;
    cpMax: Longint;
  end;
  PEmuCharRange = ^TEmuCharRange;

  TEmuTextRange = record
    chrg: TEmuCharRange;
    lpstrText: Pointer;
  end;
  PEmuTextRange = ^TEmuTextRange;

  TEmuFindText = record
    chrg: TEmuCharRange;
    lpstrText: Pointer;
  end;
  PEmuFindText = ^TEmuFindText;

  TEmuFindTextEx = record
    chrg: TEmuCharRange;
    lpstrText: Pointer;
    chrgText: TEmuCharRange;
  end;
  PEmuFindTextEx = ^TEmuFindTextEx;

  TEmuGetTextEx = record
    cb: DWORD;
    flags: DWORD;
    codepage: UINT;
    lpDefaultChar: PAnsiChar;
    lpUsedDefChar: PBOOL;
  end;
  PEmuGetTextEx = ^TEmuGetTextEx;

  TEmuGetTextLengthEx = record
    flags: DWORD;
    codepage: UINT;
  end;
  PEmuGetTextLengthEx = ^TEmuGetTextLengthEx;

  TEmuSetTextEx = record
    flags: DWORD;
    codepage: UINT;
  end;
  PEmuSetTextEx = ^TEmuSetTextEx;

  TEmuSelChange = record
    nmhdr: TNMHdr;
    chrg: TEmuCharRange;
    seltyp: Word;
  end;

  TEmuStreamCallback = function(dwCookie: Longint; pbBuff: PByte;
    cb: Longint; var pcb: Longint): Longint; stdcall;
  TEmuEditStream = record
    dwCookie: Longint;
    dwError: Longint;
    pfnCallback: TEmuStreamCallback;
  end;
  PEmuEditStream = ^TEmuEditStream;

function EmuTicks: Cardinal;
begin
  {$IFDEF FPC}
  Result := Cardinal(GetTickCount64);
  {$ELSE}
  Result := GetTickCount;
  {$ENDIF}
end;

function AnsiToWide(AText: PAnsiChar; ALen: Integer): WideString;
var
  WideLen: Integer;
begin
  Result := '';
  if (AText = nil) or (ALen <= 0) then
    Exit;
  WideLen := MultiByteToWideChar(CP_ACP, 0, AText, ALen, nil, 0);
  SetLength(Result, WideLen);
  if WideLen > 0 then
    MultiByteToWideChar(CP_ACP, 0, AText, ALen, PWideChar(Result), WideLen);
end;

function WideToAnsi(const AText: WideString; ACodePage: UINT): AnsiString;
var
  AnsiLen: Integer;
begin
  Result := '';
  if AText = '' then
    Exit;
  AnsiLen := WideCharToMultiByte(ACodePage, 0, PWideChar(AText), Length(AText),
    nil, 0, nil, nil);
  SetLength(Result, AnsiLen);
  if AnsiLen > 0 then
    WideCharToMultiByte(ACodePage, 0, PWideChar(AText), Length(AText),
      PAnsiChar(Result), AnsiLen, nil, nil);
end;

function WideUpper(const AText: WideString): WideString;
begin
  Result := AText;
  if Result <> '' then
    CharUpperBuffW(PWideChar(Result), Length(Result));
end;

// ---------------------------------------------------------------------------

constructor TEdRichEmu.Create(AGetHandle: TEdEmuHandleFunc;
  ADefProc: TEdEmuDefProc);
begin
  inherited Create;
  FGetHandle := AGetHandle;
  FDefProc := ADefProc;
  FOwnBuffer := TEdBuffer.Create;
  FBuffer := FOwnBuffer;
  FBuffer.AddListener(BufferChanged);
  FEditor := TEdEditor.Create;
  FEditor.Buffer := FBuffer;
  FEditor.SmartHome := False;      // Home - в начало строки, как в RichEdit
  FEditor.AutoIndent := False;     // Enter - без отступа (отступ - у Unit1)
  FEditor.TypingUndo := True;      // Backspace, Enter в наборе - одна правка
  FEditor.OnCaretMove := EditorMoved;
  FEditor.OnScroll := EditorScroll;
  FLineH := 16;
  FCharW := 8;
  FLimitText := EmuDefaultLimit;
  FLogged := TList.Create;
end;

destructor TEdRichEmu.Destroy;
begin
  FLogged.Free;
  FEditor.Free;
  // Буфер вкладки живёт дальше - подписку с него снять
  FBuffer.RemoveListener(BufferChanged);
  FOwnBuffer.Free;
  inherited Destroy;
end;

function TEdRichEmu.Wnd: HWND;
begin
  Result := FGetHandle();
end;

// Сообщение самому RichEdit (прежней оконной процедуре)
function TEdRichEmu.DefSend(AMsg: Cardinal; AWParam, ALParam: Integer): Integer;
var
  Message: TMessage;
begin
  Message.Msg := AMsg;
  Message.WParam := AWParam;
  Message.LParam := ALParam;
  Message.Result := 0;
  FDefProc(Message);
  Result := Message.Result;
end;

procedure TEdRichEmu.Start(const ATakeText: string);
begin
  // Уведомления - наши: маску берём у RichEdit, его собственные выключаем
  FEventMask := DefSend(EM_GETEVENTMASK_, 0, 0);
  DefSend(EM_SETEVENTMASK_, 0, 0);
  SetAllText(AnsiToWide(PAnsiChar(ATakeText), Length(ATakeText)));
  FModified := False;
  FTextChanged := False;
  FLastSelMin := 0;
  FLastSelMax := 0;
end;

procedure TEdRichEmu.TakeFromWindow;
const
  NoText: AnsiString = '';
var
  LenInfo: TEmuGetTextLengthEx;
  GetInfo: TEmuGetTextEx;
  Range: TEmuCharRange;
  TextChars, GotChars, TopLine: Integer;
  WasModified: Boolean;
  Text: WideString;
begin
  // Текст - в UTF-16, перевод строки - CR, как в модели RichEdit
  LenInfo.flags := 0;
  LenInfo.codepage := CP_UNICODE_;
  TextChars := DefSend(EM_GETTEXTLENGTHEX_, Integer(@LenInfo), 0);
  if TextChars < 0 then
    TextChars := 0;
  SetLength(Text, TextChars + 1);
  FillChar(GetInfo, SizeOf(GetInfo), 0);
  GetInfo.cb := (TextChars + 1) * 2;
  GetInfo.flags := 0;
  GetInfo.codepage := CP_UNICODE_;
  GotChars := DefSend(EM_GETTEXTEX_, Integer(@GetInfo), Integer(PWideChar(Text)));
  if GotChars < 0 then
    GotChars := 0;
  if GotChars > TextChars then
    GotChars := TextChars;
  SetLength(Text, GotChars);
  Range.cpMin := 0;
  Range.cpMax := 0;
  DefSend(EM_EXGETSEL_, 0, Integer(@Range));
  TopLine := DefSend(EM_GETFIRSTVISIBLELINE, 0, 0);
  WasModified := DefSend(EM_GETMODIFY, 0, 0) <> 0;

  Start('');
  SetAllText(Text);
  SetSelIdx(Range.cpMin, Range.cpMax);
  ScrollToRow(TopLine);
  FModified := WasModified;
  // Текст и выделение те же, что были у RichEdit: уведомлять не о чем
  FTextChanged := False;
  GetSelIdx(FLastSelMin, FLastSelMax);
  FNeedPaint := True;

  // Свой текст у RichEdit больше не нужен; уведомления у него уже выключены
  DefSend(WM_SETTEXT, 0, Integer(PAnsiChar(NoText)));
  DefSend(EM_EMPTYUNDOBUFFER, 0, 0);
end;

procedure TEdRichEmu.GiveToWindow;
var
  SetInfo: TEmuSetTextEx;
  Range: TEmuCharRange;
  SelMin, SelMax, TopLine: Integer;
  Text: WideString;
begin
  DoMouseUp;
  Text := WideText(False);
  GetSelIdx(SelMin, SelMax);
  // Уведомления у RichEdit выключены (Start) - текст ставится молча
  SetInfo.flags := 0;
  SetInfo.codepage := CP_UNICODE_;
  DefSend(EM_SETTEXTEX_, Integer(@SetInfo), Integer(PWideChar(Text)));
  Range.cpMin := SelMin;
  Range.cpMax := SelMax;
  DefSend(EM_EXSETSEL_, 0, Integer(@Range));
  TopLine := DefSend(EM_GETFIRSTVISIBLELINE, 0, 0);
  if TopLine <> FTopRow then
    DefSend(EM_LINESCROLL, 0, FTopRow - TopLine);
  DefSend(EM_SETMODIFY, Ord(FModified), 0);
  DefSend(EM_SETEVENTMASK_, 0, FEventMask);
end;

procedure TEdRichEmu.SetMetrics(ALineH, ACharW, ATabChars: Integer);
begin
  if ALineH > 0 then
    FLineH := ALineH;
  if ACharW > 0 then
    FCharW := ACharW;
  if ATabChars > 0 then
    FEditor.TabSize := ATabChars;
end;

procedure TEdRichEmu.Log(const AText: string);
begin
  if Assigned(FOnLog) then
    FOnLog(AText);
end;

procedure TEdRichEmu.LogOnce(AMsg: Cardinal);
begin
  if FLogged.IndexOf(Pointer(AMsg)) >= 0 then
    Exit;
  FLogged.Add(Pointer(AMsg));
  if AMsg >= WM_USER then
    Log(Format('свой редактор: сообщение WM_USER+%d ($%.4x) не разобрано - ' +
      'отдано RichEdit', [AMsg - WM_USER, AMsg]))
  else
    Log(Format('свой редактор: сообщение $%.4x не разобрано - отдано ' +
      'RichEdit', [AMsg]));
end;

procedure TEdRichEmu.BufferChanged(Sender: TObject; AFirst, AOldCount,
  ANewCount: Integer);
begin
  FTextChanged := True;
  FModified := True;
  FNeedPaint := True;
end;

// Каретка или выделение сдвинулись (TEdEditor)
procedure TEdRichEmu.EditorMoved(Sender: TObject);
begin
  if FUserMove then
    ScrollCaretIntoView;
end;

procedure TEdRichEmu.EditorScroll(Sender: TObject; ARows: Integer);
begin
  ScrollToRow(FTopRow + ARows);
end;

// ---------------------------------------------------------------------------
//  Индексы, места на экране
// ---------------------------------------------------------------------------

procedure TEdRichEmu.IdxToPos(AIndex: Integer; var ARow, ACol: Integer);
begin
  if AIndex < 0 then
    AIndex := 0;
  FBuffer.PosOfIndex(AIndex, ARow, ACol);
end;

function TEdRichEmu.PosToIdx(ARow, ACol: Integer): Integer;
begin
  Result := FBuffer.CharIndex(ARow, ACol);
end;

function TEdRichEmu.CaretIndex: Integer;
begin
  Result := PosToIdx(FEditor.CaretRow, FEditor.CaretCol);
end;

procedure TEdRichEmu.GetSelIdx(var AMin, AMax: Integer);
var
  Row1, Col1, Row2, Col2: Integer;
begin
  if FEditor.SelRange(Row1, Col1, Row2, Col2) then
  begin
    AMin := PosToIdx(Row1, Col1);
    AMax := PosToIdx(Row2, Col2);
  end
  else
  begin
    AMin := CaretIndex;
    AMax := AMin;
  end;
end;

// Выделение: от AAnchor до AActive (каретка - на AActive). Конец набора
procedure TEdRichEmu.SetSelIdx(AAnchor, AActive: Integer);
var
  AnchorRow, AnchorCol, ActiveRow, ActiveCol, OldMin, OldMax: Integer;
  TextLen: Integer;
begin
  TextLen := FBuffer.TextLength;
  if AAnchor > TextLen then
    AAnchor := TextLen;
  if AActive > TextLen then
    AActive := TextLen;
  if AAnchor < 0 then
    AAnchor := 0;
  if AActive < 0 then
    AActive := 0;
  GetSelIdx(OldMin, OldMax);
  IdxToPos(AAnchor, AnchorRow, AnchorCol);
  IdxToPos(AActive, ActiveRow, ActiveCol);
  FEditor.StopTyping;
  FEditor.ClearSelection;
  FEditor.CaretTo(ActiveRow, ActiveCol);
  if AAnchor <> AActive then
    FEditor.SetSelection(AnchorRow, AnchorCol);
  if (OldMin <> OldMax) or (AAnchor <> AActive) then
    FNeedPaint := True;
end;

// Область текста - у самого RichEdit (поля, EM_SETRECT Unit1)
function TEdRichEmu.TextRect: TRect;
begin
  Result := Rect(0, 0, 0, 0);
  DefSend(EM_GETRECT, 0, Integer(@Result));
  if Result.Bottom <= Result.Top then
    Windows.GetClientRect(Wnd, Result);
end;

function TEdRichEmu.VisibleRows: Integer;
var
  Area: TRect;
begin
  Area := TextRect;
  Result := (Area.Bottom - Area.Top) div FLineH;
  if Result < 1 then
    Result := 1;
end;

// Ниже - не прокручивается: последняя строка у нижнего края области
function TEdRichEmu.MaxTopRow: Integer;
begin
  Result := FBuffer.Count - VisibleRows;
  if Result < 0 then
    Result := 0;
end;

procedure TEdRichEmu.ScrollToRow(ATop: Integer);
begin
  if ATop > MaxTopRow then
    ATop := MaxTopRow;
  if ATop < 0 then
    ATop := 0;
  if ATop = FTopRow then
    Exit;
  FTopRow := ATop;
  FNeedPaint := True;
end;

procedure TEdRichEmu.ScrollCaretIntoView;
var
  CaretRow, Rows: Integer;
begin
  CaretRow := FEditor.CaretRow;
  Rows := VisibleRows;
  if CaretRow < FTopRow then
    ScrollToRow(CaretRow)
  else if CaretRow >= FTopRow + Rows then
    ScrollToRow(CaretRow - Rows + 1);
end;

// Левый верхний угол символа AIndex в окне (конец текста - за последним)
procedure TEdRichEmu.CharPoint(AIndex: Integer; var APt: TPoint);
var
  Row, Col: Integer;
  Area: TRect;
begin
  Area := TextRect;
  IdxToPos(AIndex, Row, Col);
  APt.X := Area.Left + FEditor.ScreenCol(Row, Col) * FCharW;
  APt.Y := Area.Top + (Row - FTopRow) * FLineH;
end;

procedure TEdRichEmu.PointPos(const APt: TPoint; var ARow, ACol: Integer);
var
  Area: TRect;
  ScreenColumn: Integer;
begin
  Area := TextRect;
  if APt.Y < Area.Top then
    ARow := FTopRow + (APt.Y - Area.Top - FLineH + 1) div FLineH
  else
    ARow := FTopRow + (APt.Y - Area.Top) div FLineH;
  if ARow < 0 then
    ARow := 0;
  if ARow >= FBuffer.Count then
    ARow := FBuffer.Count - 1;
  // Ближе к правому краю ячейки - после символа
  ScreenColumn := (APt.X - Area.Left + FCharW div 2) div FCharW;
  if ScreenColumn < 0 then
    ScreenColumn := 0;
  ACol := FEditor.ColAtScreen(ARow, ScreenColumn);
end;

function TEdRichEmu.PointChar(const APt: TPoint): Integer;
var
  Row, Col: Integer;
begin
  PointPos(APt, Row, Col);
  Result := PosToIdx(Row, Col);
end;

// ---------------------------------------------------------------------------
//  Текст
// ---------------------------------------------------------------------------

// Длина текста: в UTF-16 или в кодировке ACodePage, перевод строки - CR
// или CRLF. Однобайтовая кодировка - по числу символов, без перекодирования
function TEdRichEmu.TextLen(AUseCrlf: Boolean; ACodePage: UINT): Integer;
var
  CpInfo: TCPInfo;
begin
  if (ACodePage <> CP_UNICODE_) and
     not (GetCPInfo(ACodePage, CpInfo) and (CpInfo.MaxCharSize = 1)) then
  begin
    Result := Length(WideToAnsi(WideText(AUseCrlf), ACodePage));
    Exit;
  end;
  Result := FBuffer.TextLength;
  if AUseCrlf then
    Inc(Result, FBuffer.Count - 1);
end;

function TEdRichEmu.WideText(AUseCrlf: Boolean): WideString;
begin
  if AUseCrlf then
    Result := FBuffer.GetText(#13#10)
  else
    Result := FBuffer.GetText(#13);
end;

function TEdRichEmu.RangeText(AMin, AMax: Integer;
  AUseCrlf: Boolean): WideString;
var
  Row1, Col1, Row2, Col2, CharIdx: Integer;
  Raw: WideString;
begin
  Result := '';
  if AMax <= AMin then
    Exit;
  IdxToPos(AMin, Row1, Col1);
  IdxToPos(AMax, Row2, Col2);
  Raw := FBuffer.TextRange(Row1, Col1, Row2, Col2);
  if AUseCrlf then
    Result := EdCrlf(Raw)
  else
  begin
    Result := Raw;
    for CharIdx := 1 to Length(Result) do
      if Result[CharIdx] = #10 then
        Result[CharIdx] := #13;
  end;
end;

procedure TEdRichEmu.UseBuffer(ABuffer: TEdBuffer; AModified: Boolean);
begin
  if ABuffer = nil then
  begin
    ABuffer := FOwnBuffer;
    FOwnBuffer.SetText('');
  end;
  if ABuffer <> FBuffer then
  begin
    FBuffer.RemoveListener(BufferChanged);
    FBuffer := ABuffer;
    FBuffer.AddListener(BufferChanged);
  end;
  FEditor.Buffer := FBuffer;
  FTopRow := 0;
  FModified := AModified;
  FTextChanged := True;
  FNeedPaint := True;
  // Вне сообщения окну - уведомить сразу (в сообщении - Handle в конце)
  if FDepth = 0 then
    Notify;
end;

// Весь текст заново (WM_SETTEXT): откат пуст, каретка - в начале
procedure TEdRichEmu.SetAllText(const AText: WideString);
begin
  FBuffer.SetText(AText);
  FEditor.Buffer := FBuffer;
  FTopRow := 0;
  FTextChanged := True;
  FNeedPaint := True;
end;

// EM_REPLACESEL: без отката (ACanUndo = False) - и откат очищается, как у
// RichEdit
procedure TEdRichEmu.ReplaceSelText(const AText: WideString;
  ACanUndo: Boolean);
var
  Row1, Col1, Row2, Col2, EndRow, EndCol: Integer;
  WasReadOnly: Boolean;
begin
  if ACanUndo then
  begin
    // Из кода - и у окна только для чтения (как у RichEdit)
    WasReadOnly := FEditor.ReadOnly;
    FEditor.ReadOnly := False;
    try
      FEditor.InsertText(AText, False);
    finally
      FEditor.ReadOnly := WasReadOnly;
    end;
    FBuffer.BeginGroup;
    Exit;
  end;
  if FEditor.SelRange(Row1, Col1, Row2, Col2) then
    FBuffer.DeleteRaw(Row1, Col1, Row2, Col2)
  else
  begin
    Row1 := FEditor.CaretRow;
    Col1 := FEditor.CaretCol;
  end;
  FBuffer.InsertRaw(Row1, Col1, EdNormalizeBreaks(AText), EndRow, EndCol);
  FBuffer.ClearUndo;
  FEditor.ClearSelection;
  FEditor.CaretTo(EndRow, EndCol);
end;

// Поиск AWhat в [AMin, AMax) (AMax = -1 - до конца); без FR_DOWN - назад
// от AMin до AMax. Результат - позиция или -1
function TEdRichEmu.FindText(AFlags: Integer; AMin, AMax: Integer;
  const AWhat: WideString): Integer;
var
  Hay, Needle: WideString;
  TextLen, FromIdx, ToIdx, PosIdx, MatchIdx: Integer;
  WholeOk: Boolean;
begin
  Result := -1;
  if AWhat = '' then
    Exit;
  TextLen := FBuffer.TextLength;
  Hay := WideText(False);
  Needle := AWhat;
  if AFlags and FR_MATCHCASE_ = 0 then
  begin
    Hay := WideUpper(Hay);
    Needle := WideUpper(Needle);
  end;
  if AFlags and FR_DOWN_ <> 0 then
  begin
    FromIdx := AMin;
    ToIdx := AMax;
    if (ToIdx < 0) or (ToIdx > TextLen) then
      ToIdx := TextLen;
    if FromIdx < 0 then
      FromIdx := 0;
    PosIdx := FromIdx;
    while PosIdx + Length(Needle) <= ToIdx do
    begin
      if CompareMem(@Hay[PosIdx + 1], @Needle[1],
         Length(Needle) * SizeOf(WideChar)) then
      begin
        WholeOk := True;
        if AFlags and FR_WHOLEWORD_ <> 0 then
          WholeOk := ((PosIdx = 0) or not EdIsWordChar(Hay[PosIdx])) and
            ((PosIdx + Length(Needle) >= Length(Hay)) or
             not EdIsWordChar(Hay[PosIdx + Length(Needle) + 1]));
        if WholeOk then
        begin
          Result := PosIdx;
          Exit;
        end;
      end;
      Inc(PosIdx);
    end;
  end
  else
  begin
    // Назад: от AMin к AMax (AMax <= AMin; -1 - к началу)
    FromIdx := AMin;
    if (FromIdx < 0) or (FromIdx > TextLen) then
      FromIdx := TextLen;
    ToIdx := AMax;
    if ToIdx < 0 then
      ToIdx := 0;
    MatchIdx := FromIdx - Length(Needle);
    while MatchIdx >= ToIdx do
    begin
      if CompareMem(@Hay[MatchIdx + 1], @Needle[1],
         Length(Needle) * SizeOf(WideChar)) then
      begin
        WholeOk := True;
        if AFlags and FR_WHOLEWORD_ <> 0 then
          WholeOk := ((MatchIdx = 0) or not EdIsWordChar(Hay[MatchIdx])) and
            ((MatchIdx + Length(Needle) >= Length(Hay)) or
             not EdIsWordChar(Hay[MatchIdx + Length(Needle) + 1]));
        if WholeOk then
        begin
          Result := MatchIdx;
          Exit;
        end;
      end;
      Dec(MatchIdx);
    end;
  end;
end;

// ---------------------------------------------------------------------------
//  Потоки (EM_STREAMIN / EM_STREAMOUT): только текст, ANSI или UTF-16
// ---------------------------------------------------------------------------

procedure TEdRichEmu.DoStreamIn(var Message: TMessage);
var
  Stream: PEmuEditStream;
  Chunk: array[0..4095] of Byte;
  Got: Longint;
  Raw: AnsiString;
  Text: WideString;
  OldLen: Integer;
begin
  Stream := PEmuEditStream(Message.LParam);
  Raw := '';
  repeat
    Got := 0;
    Stream^.dwError := Stream^.pfnCallback(Stream^.dwCookie, @Chunk[0],
      SizeOf(Chunk), Got);
    if (Stream^.dwError <> 0) or (Got <= 0) then
      Break;
    OldLen := Length(Raw);
    SetLength(Raw, OldLen + Got);
    Move(Chunk[0], Raw[OldLen + 1], Got);
  until False;
  if Message.WParam and SF_UNICODE_ <> 0 then
  begin
    SetLength(Text, Length(Raw) div 2);
    if Text <> '' then
      Move(Raw[1], Text[1], Length(Text) * 2);
  end
  else
    Text := AnsiToWide(PAnsiChar(Raw), Length(Raw));
  if Message.WParam and SFF_SELECTION_ <> 0 then
    ReplaceSelText(Text, False)
  else
    SetAllText(Text);
  Message.Result := Length(Text);
end;

procedure TEdRichEmu.DoStreamOut(var Message: TMessage);
var
  Stream: PEmuEditStream;
  SelMin, SelMax, Written, Done: Longint;
  Text: WideString;
  Raw: AnsiString;
begin
  Stream := PEmuEditStream(Message.LParam);
  if Message.WParam and SFF_SELECTION_ <> 0 then
  begin
    GetSelIdx(SelMin, SelMax);
    Text := RangeText(SelMin, SelMax, True);
  end
  else
    Text := WideText(True);
  if Message.WParam and SF_UNICODE_ <> 0 then
  begin
    SetLength(Raw, Length(Text) * 2);
    if Text <> '' then
      Move(Text[1], Raw[1], Length(Raw));
  end
  else
    Raw := WideToAnsi(Text, CP_ACP);
  Done := 0;
  while Done < Length(Raw) do
  begin
    Written := 0;
    Stream^.dwError := Stream^.pfnCallback(Stream^.dwCookie,
      @Raw[Done + 1], Length(Raw) - Done, Written);
    if (Stream^.dwError <> 0) or (Written <= 0) then
      Break;
    Inc(Done, Written);
  end;
  Message.Result := Done;
end;

// ---------------------------------------------------------------------------
//  Клавиатура и мышь - как RichEdit 4.1: Enter, Backspace - на WM_KEYDOWN,
//  Tab и символы - WM_CHAR
// ---------------------------------------------------------------------------

function TEdRichEmu.DoKeyDown(AKey: Word): Boolean;
var
  Shift: TShiftState;
begin
  Result := True;
  Shift := [];
  if GetKeyState(VK_SHIFT) < 0 then
    Include(Shift, ssShift);
  if GetKeyState(VK_CONTROL) < 0 then
    Include(Shift, ssCtrl);
  if GetKeyState(VK_MENU) < 0 then
    Include(Shift, ssAlt);
  // Tab - символом (WM_CHAR)
  if AKey = VK_TAB then
    Exit;
  FEditor.PageRows := VisibleRows;
  FUserMove := True;
  try
    FEditor.KeyDown(AKey, Shift);
  finally
    FUserMove := False;
  end;
end;

procedure TEdRichEmu.DoChar(ACode: Integer);
var
  AnsiCh: AnsiChar;
  WideCh: WideChar;
begin
  FUserMove := True;
  try
    // Enter и Backspace RichEdit 4.1 разбирает на WM_KEYDOWN (наблюдение
    // в unIDE 2026-10-10: перевод строки вставлялся ещё до WM_CHAR #13), их
    // WM_CHAR и Ctrl+Backspace (#127) - без действия
    case ACode of
      9:
        FEditor.InsertText(#9, True);
    else
      if ACode >= 32 then
      begin
        // Окно ANSI: символ - в кодировке Windows
        AnsiCh := AnsiChar(ACode);
        WideCh := WideChar(ACode);
        if ACode >= 128 then
          MultiByteToWideChar(CP_ACP, 0, @AnsiCh, 1, @WideCh, 1);
        FEditor.TypeChar(WideCh);
      end;
    end;
  finally
    FUserMove := False;
  end;
end;

procedure TEdRichEmu.DoMouseDown(var Message: TMessage; ADouble: Boolean);
var
  ClickPt: TPoint;
  ClickRow, ClickCol: Integer;
  IsTriple: Boolean;
begin
  if GetFocus <> Wnd then
    Windows.SetFocus(Wnd);
  ClickPt := Point(SmallInt(LoWord(Message.LParam)),
    SmallInt(HiWord(Message.LParam)));
  PointPos(ClickPt, ClickRow, ClickCol);
  FUserMove := True;
  try
    IsTriple := not ADouble and (FDblTick <> 0) and
      (EmuTicks - FDblTick <= GetDoubleClickTime) and
      (Abs(ClickPt.X - FDblPt.X) <= 4) and (Abs(ClickPt.Y - FDblPt.Y) <= 4);
    if IsTriple then
    begin
      FDblTick := 0;
      FEditor.SelectLine(ClickRow);
      Exit;
    end;
    if ADouble then
    begin
      FDblTick := EmuTicks;
      FDblPt := ClickPt;
      FEditor.SelectWordAt(ClickRow, ClickCol);
      Exit;
    end;
    FDblTick := 0;
    if Message.WParam and MK_SHIFT <> 0 then
      FEditor.MoveTo(ClickRow, ClickCol, True)
    else
    begin
      FEditor.MoveTo(ClickRow, ClickCol, False);
      FEditor.SetSelection(FEditor.CaretRow, FEditor.CaretCol);
    end;
    FMouseSel := True;
    FMousePt := ClickPt;
    SetCapture(Wnd);
  finally
    FUserMove := False;
  end;
end;

procedure TEdRichEmu.DoMouseMove(var Message: TMessage);
var
  Area: TRect;
  MouseRow, MouseCol: Integer;
begin
  if not FMouseSel then
    Exit;
  FMousePt := Point(SmallInt(LoWord(Message.LParam)),
    SmallInt(HiWord(Message.LParam)));
  PointPos(FMousePt, MouseRow, MouseCol);
  FUserMove := True;
  try
    FEditor.MoveTo(MouseRow, MouseCol, True);
  finally
    FUserMove := False;
  end;
  // Выше или ниже области текста - прокрутка таймером, пока мышь там
  Area := TextRect;
  if (FMousePt.Y < Area.Top) or (FMousePt.Y >= Area.Bottom) then
  begin
    if not FTimerOn then
      SetTimer(Wnd, EmuTimerId, 50, nil);
    FTimerOn := True;
  end
  else if FTimerOn then
  begin
    KillTimer(Wnd, EmuTimerId);
    FTimerOn := False;
  end;
end;

procedure TEdRichEmu.DoMouseUp;
begin
  if FTimerOn then
    KillTimer(Wnd, EmuTimerId);
  FTimerOn := False;
  if FMouseSel then
  begin
    FMouseSel := False;
    if GetCapture = Wnd then
      ReleaseCapture;
  end;
  if FEditor.SelActive and not FEditor.HasSelection then
    FEditor.ClearSelection;
end;

procedure TEdRichEmu.DoTimer;
var
  Area: TRect;
  MouseRow, MouseCol: Integer;
begin
  if not FMouseSel then
  begin
    KillTimer(Wnd, EmuTimerId);
    FTimerOn := False;
    Exit;
  end;
  Area := TextRect;
  if FMousePt.Y < Area.Top then
    ScrollToRow(FTopRow - 1)
  else if FMousePt.Y >= Area.Bottom then
    ScrollToRow(FTopRow + 1);
  PointPos(FMousePt, MouseRow, MouseCol);
  FEditor.MoveTo(MouseRow, MouseCol, True);
end;

// ---------------------------------------------------------------------------
//  Уведомления родителю и перерисовка - в конце внешнего сообщения
// ---------------------------------------------------------------------------

procedure TEdRichEmu.Notify;
var
  SelMin, SelMax: Integer;
  SelMoved: Boolean;
  Info: TEmuSelChange;
  Parent, Window: HWND;
begin
  Window := Wnd;
  Parent := GetParent(Window);
  // Выделение появилось, сменилось или пропало - перерисовать: RichEdit сам
  // помечал грязной изменившуюся область, и Unit1 рисует выделение только
  // в кадре (HighlightVisibleText). Без этого выделение мышью и Shift+
  // стрелками на экране не появлялось
  GetSelIdx(SelMin, SelMax);
  SelMoved := (SelMin <> FLastSelMin) or (SelMax <> FLastSelMax);
  if SelMoved and ((SelMin <> SelMax) or (FLastSelMin <> FLastSelMax)) then
    FNeedPaint := True;
  if FNeedPaint then
  begin
    FNeedPaint := False;
    InvalidateRect(Window, nil, False);
  end;
  if FTextChanged then
  begin
    FTextChanged := False;
    if (FEventMask and ENM_CHANGE_ <> 0) and (Parent <> 0) then
      SendMessage(Parent, WM_COMMAND, MakeWParam(GetDlgCtrlID(Window),
        EN_CHANGE), Integer(Window));
  end;
  if SelMoved then
  begin
    FLastSelMin := SelMin;
    FLastSelMax := SelMax;
    if (FEventMask and ENM_SELCHANGE_ <> 0) and (Parent <> 0) then
    begin
      FillChar(Info, SizeOf(Info), 0);
      Info.nmhdr.hwndFrom := Window;
      Info.nmhdr.idFrom := GetDlgCtrlID(Window);
      Info.nmhdr.code := EN_SELCHANGE_;
      Info.chrg.cpMin := SelMin;
      Info.chrg.cpMax := SelMax;
      if SelMax = SelMin then
        Info.seltyp := SEL_EMPTY_
      else
        Info.seltyp := SEL_TEXT_;
      SendMessage(Parent, WM_NOTIFY, Info.nmhdr.idFrom, Integer(@Info));
    end;
  end;
end;

// ---------------------------------------------------------------------------
//  Разбор сообщений
// ---------------------------------------------------------------------------

function TEdRichEmu.Handle(var Message: TMessage): Boolean;
var
  SelMin, SelMax, Row, Col, Count, MaxChars, LineIdx: Integer;
  Text: WideString;
  Raw: AnsiString;
  Range: PEmuCharRange;
  TextRange: PEmuTextRange;
  GetEx: PEmuGetTextEx;
  LenEx: PEmuGetTextLengthEx;
  SetEx: PEmuSetTextEx;
  FindRec: PEmuFindText;
  FindEx: PEmuFindTextEx;
  Pt: PPoint;
  Codepage: UINT;
  WhatText: WideString;
begin
  Result := True;
  Inc(FDepth);
  try
    Message.Result := 0;
    case Message.Msg of
      // --- Текст целиком ---
      WM_GETTEXT:
        begin
          Raw := WideToAnsi(WideText(True), CP_ACP);
          MaxChars := Message.WParam - 1;
          if MaxChars < 0 then
            MaxChars := 0;
          if Length(Raw) < MaxChars then
            MaxChars := Length(Raw);
          if Message.LParam <> 0 then
          begin
            if MaxChars > 0 then
              Move(Raw[1], PAnsiChar(Message.LParam)^, MaxChars);
            PAnsiChar(Message.LParam)[MaxChars] := #0;
          end;
          Message.Result := MaxChars;
        end;
      WM_GETTEXTLENGTH:
        Message.Result := TextLen(True, CP_ACP);
      WM_SETTEXT:
        begin
          if Message.LParam <> 0 then
            SetAllText(AnsiToWide(PAnsiChar(Message.LParam),
              StrLen(PAnsiChar(Message.LParam))))
          else
            SetAllText('');
          Message.Result := 1;
        end;
      EM_SETTEXTEX_:
        begin
          SetEx := PEmuSetTextEx(Message.WParam);
          Text := '';
          if Message.LParam <> 0 then
          begin
            if (SetEx <> nil) and ((SetEx^.codepage = CP_UNICODE_) or
               (SetEx^.flags and ST_UNICODE_ <> 0)) then
              Text := PWideChar(Message.LParam)
            else
              Text := AnsiToWide(PAnsiChar(Message.LParam),
                StrLen(PAnsiChar(Message.LParam)));
          end;
          if (SetEx <> nil) and (SetEx^.flags and ST_SELECTION_ <> 0) then
            ReplaceSelText(Text, True)
          else
            SetAllText(Text);
          Message.Result := 1;
        end;
      EM_GETTEXTEX_:
        begin
          GetEx := PEmuGetTextEx(Message.WParam);
          if GetEx^.flags and GT_SELECTION_ <> 0 then
          begin
            GetSelIdx(SelMin, SelMax);
            Text := RangeText(SelMin, SelMax, GetEx^.flags and GT_USECRLF_ <> 0);
          end
          else
            Text := WideText(GetEx^.flags and GT_USECRLF_ <> 0);
          if GetEx^.codepage = CP_UNICODE_ then
          begin
            MaxChars := Integer(GetEx^.cb) div 2 - 1;
            if MaxChars < 0 then
              MaxChars := 0;
            if Length(Text) < MaxChars then
              MaxChars := Length(Text);
            if MaxChars > 0 then
              Move(Text[1], Pointer(Message.LParam)^, MaxChars * 2);
            if GetEx^.cb >= 2 then
              PWideChar(Message.LParam)[MaxChars] := #0;
          end
          else
          begin
            Codepage := GetEx^.codepage;
            Raw := WideToAnsi(Text, Codepage);
            MaxChars := Integer(GetEx^.cb) - 1;
            if MaxChars < 0 then
              MaxChars := 0;
            if Length(Raw) < MaxChars then
              MaxChars := Length(Raw);
            if MaxChars > 0 then
              Move(Raw[1], Pointer(Message.LParam)^, MaxChars);
            if GetEx^.cb >= 1 then
              PAnsiChar(Message.LParam)[MaxChars] := #0;
          end;
          Message.Result := MaxChars;
        end;
      EM_GETTEXTLENGTHEX_:
        begin
          LenEx := PEmuGetTextLengthEx(Message.WParam);
          if LenEx = nil then
            Message.Result := TextLen(True, CP_UNICODE_)
          else
          begin
            Message.Result := TextLen(LenEx^.flags and GTL_USECRLF_ <> 0,
              LenEx^.codepage);
            if (LenEx^.flags and GTL_NUMBYTES_ <> 0) and
               (LenEx^.codepage = CP_UNICODE_) then
              Message.Result := Message.Result * 2;
          end;
        end;
      EM_STREAMIN_:
        DoStreamIn(Message);
      EM_STREAMOUT_:
        DoStreamOut(Message);

      // --- Куски текста ---
      EM_GETTEXTRANGE_:
        begin
          TextRange := PEmuTextRange(Message.LParam);
          SelMin := TextRange^.chrg.cpMin;
          SelMax := TextRange^.chrg.cpMax;
          if (SelMax < 0) or (SelMax > FBuffer.TextLength) then
            SelMax := FBuffer.TextLength;
          if SelMin < 0 then
            SelMin := 0;
          Text := RangeText(SelMin, SelMax, False);
          if Text <> '' then
            Move(Text[1], TextRange^.lpstrText^, Length(Text) * 2);
          PWideChar(TextRange^.lpstrText)[Length(Text)] := #0;
          Message.Result := Length(Text);
        end;
      EM_GETSELTEXT_:
        begin
          GetSelIdx(SelMin, SelMax);
          Text := RangeText(SelMin, SelMax, False);
          if Message.LParam <> 0 then
          begin
            if Text <> '' then
              Move(Text[1], Pointer(Message.LParam)^, Length(Text) * 2);
            PWideChar(Message.LParam)[Length(Text)] := #0;
          end;
          Message.Result := Length(Text);
        end;
      EM_GETLINE:
        begin
          // Строка вместе с CR, как у RichEdit 4.1 (и последняя: у RichEdit
          // текст кончается знаком абзаца); ANSI. В первом слове буфера - его
          // размер в символах
          if (Message.WParam >= 0) and (Message.WParam < FBuffer.Count) then
          begin
            Text := FBuffer[Message.WParam] + #13;
            Raw := WideToAnsi(Text, CP_ACP);
            MaxChars := PWord(Message.LParam)^;
            if Length(Raw) < MaxChars then
              MaxChars := Length(Raw);
            if MaxChars > 0 then
              Move(Raw[1], Pointer(Message.LParam)^, MaxChars);
            Message.Result := MaxChars;
          end;
        end;

      // --- Строки ---
      EM_GETLINECOUNT:
        Message.Result := FBuffer.Count;
      EM_LINEINDEX:
        begin
          LineIdx := Message.WParam;
          if LineIdx = -1 then
            LineIdx := FEditor.CaretRow;
          if (LineIdx < 0) or (LineIdx >= FBuffer.Count) then
            Message.Result := -1
          else
            Message.Result := PosToIdx(LineIdx, 0);
        end;
      EM_LINELENGTH:
        begin
          if Message.WParam = -1 then
            Row := FEditor.CaretRow
          else
            IdxToPos(Message.WParam, Row, Col);
          Message.Result := FBuffer.LineLength(Row);
        end;
      EM_LINEFROMCHAR, EM_EXLINEFROMCHAR_:
        begin
          if Message.Msg = EM_LINEFROMCHAR then
            SelMin := Message.WParam
          else
            SelMin := Message.LParam;
          if SelMin = -1 then
            GetSelIdx(SelMin, SelMax);
          IdxToPos(SelMin, Row, Col);
          Message.Result := Row;
        end;

      // --- Выделение и правка ---
      EM_EXGETSEL_:
        begin
          GetSelIdx(SelMin, SelMax);
          Range := PEmuCharRange(Message.LParam);
          Range^.cpMin := SelMin;
          Range^.cpMax := SelMax;
        end;
      EM_GETSEL:
        begin
          GetSelIdx(SelMin, SelMax);
          if Message.WParam <> 0 then
            PDWORD(Message.WParam)^ := SelMin;
          if Message.LParam <> 0 then
            PDWORD(Message.LParam)^ := SelMax;
          if SelMax > $FFFF then
            Message.Result := -1
          else
            Message.Result := MakeLong(SelMin, SelMax);
        end;
      EM_EXSETSEL_, EM_SETSEL:
        begin
          if Message.Msg = EM_EXSETSEL_ then
          begin
            Range := PEmuCharRange(Message.LParam);
            SelMin := Range^.cpMin;
            SelMax := Range^.cpMax;
          end
          else
          begin
            SelMin := Message.WParam;
            SelMax := Message.LParam;
          end;
          if SelMin = -1 then
          begin
            // Снять выделение: каретка - на его конце
            GetSelIdx(SelMin, SelMax);
            SelMin := SelMax;
          end
          else if (SelMax = -1) or (SelMax > FBuffer.TextLength) then
            SelMax := FBuffer.TextLength;
          // Каретка - на большем конце (так у RichEdit и при обратном
          // порядке концов)
          if SelMin > SelMax then
          begin
            Count := SelMin;
            SelMin := SelMax;
            SelMax := Count;
          end;
          SetSelIdx(SelMin, SelMax);
          GetSelIdx(SelMin, SelMax);
          Message.Result := SelMax;
        end;
      EM_REPLACESEL:
        begin
          if Message.LParam <> 0 then
            Text := AnsiToWide(PAnsiChar(Message.LParam),
              StrLen(PAnsiChar(Message.LParam)))
          else
            Text := '';
          ReplaceSelText(Text, Message.WParam <> 0);
          Message.Result := Length(Text);
        end;
      EM_SELECTIONTYPE_:
        begin
          GetSelIdx(SelMin, SelMax);
          if SelMax = SelMin then
            Message.Result := SEL_EMPTY_
          else if SelMax - SelMin = 1 then
            Message.Result := SEL_TEXT_
          else
            Message.Result := SEL_TEXT_ or SEL_MULTICHAR_;
        end;
      EM_HIDESELECTION_:
        ;
      WM_CUT:
        begin
          FUserMove := True;
          try
            FEditor.CutToClipboard;
          finally
            FUserMove := False;
          end;
        end;
      WM_COPY:
        FEditor.CopyToClipboard;
      WM_PASTE, EM_PASTESPECIAL_:
        begin
          FUserMove := True;
          try
            FEditor.PasteFromClipboard;
          finally
            FUserMove := False;
          end;
        end;
      WM_CLEAR:
        FEditor.DeleteSelection;
      EM_CANPASTE_:
        Message.Result := Ord(IsClipboardFormatAvailable(CF_UNICODETEXT) or
          IsClipboardFormatAvailable(CF_TEXT));

      // --- Откат ---
      EM_CANUNDO:
        Message.Result := Ord(FBuffer.CanUndo);
      EM_CANREDO_:
        Message.Result := Ord(FBuffer.CanRedo);
      EM_UNDO, WM_UNDO:
        begin
          Message.Result := Ord(FBuffer.CanUndo);
          FUserMove := True;
          try
            FEditor.Undo;
          finally
            FUserMove := False;
          end;
        end;
      EM_REDO_:
        begin
          Message.Result := Ord(FBuffer.CanRedo);
          FUserMove := True;
          try
            FEditor.Redo;
          finally
            FUserMove := False;
          end;
        end;
      EM_EMPTYUNDOBUFFER:
        FBuffer.ClearUndo;
      EM_STOPGROUPTYPING_:
        FEditor.StopTyping;
      EM_SETUNDOLIMIT_:
        Message.Result := Message.WParam;
      EM_GETMODIFY:
        Message.Result := Ord(FModified);
      EM_SETMODIFY:
        FModified := Message.WParam <> 0;

      // --- Поиск ---
      EM_FINDTEXTW_, EM_FINDTEXTEXW_, EM_FINDTEXT_, EM_FINDTEXTEX_:
        begin
          FindRec := PEmuFindText(Message.LParam);
          if (Message.Msg = EM_FINDTEXTW_) or (Message.Msg = EM_FINDTEXTEXW_) then
            WhatText := PWideChar(FindRec^.lpstrText)
          else
            WhatText := AnsiToWide(PAnsiChar(FindRec^.lpstrText),
              StrLen(PAnsiChar(FindRec^.lpstrText)));
          Message.Result := FindText(Message.WParam, FindRec^.chrg.cpMin,
            FindRec^.chrg.cpMax, WhatText);
          if (Message.Msg = EM_FINDTEXTEXW_) or (Message.Msg = EM_FINDTEXTEX_) then
          begin
            FindEx := PEmuFindTextEx(Message.LParam);
            if Message.Result >= 0 then
            begin
              FindEx^.chrgText.cpMin := Message.Result;
              FindEx^.chrgText.cpMax := Message.Result + Length(WhatText);
            end
            else
            begin
              FindEx^.chrgText.cpMin := -1;
              FindEx^.chrgText.cpMax := -1;
            end;
          end;
        end;

      // --- Пределы, режимы, уведомления ---
      EM_EXLIMITTEXT_:
        if Message.LParam <= 0 then
          FLimitText := EmuDefaultLimit
        else
          FLimitText := Message.LParam;
      EM_LIMITTEXT:
        if Message.WParam <= 0 then
          FLimitText := EmuDefaultLimit
        else
          FLimitText := Message.WParam;
      EM_GETLIMITTEXT_, EM_GETLIMITTEXT_ED:
        Message.Result := FLimitText;
      EM_SETEVENTMASK_:
        begin
          Message.Result := FEventMask;
          FEventMask := Message.LParam;
          // Сам RichEdit молчит (окно пересоздано - VCL ставит маску заново)
          DefSend(EM_SETEVENTMASK_, 0, 0);
        end;
      EM_GETEVENTMASK_:
        Message.Result := FEventMask;
      EM_SETREADONLY:
        begin
          FEditor.ReadOnly := Message.WParam <> 0;
          // Стиль ES_READONLY и вид - у RichEdit
          Result := False;
        end;

      // --- Экран ---
      EM_POSFROMCHAR_, EM_POSFROMCHAR_ED:
        begin
          Pt := PPoint(Message.WParam);
          if Pt <> nil then
            CharPoint(Message.LParam, Pt^);
        end;
      EM_CHARFROMPOS_, EM_CHARFROMPOS_ED:
        Message.Result := PointChar(PPoint(Message.LParam)^);
      EM_GETFIRSTVISIBLELINE:
        Message.Result := FTopRow;
      EM_LINESCROLL:
        begin
          ScrollToRow(FTopRow + Message.LParam);
          Message.Result := 1;
        end;
      EM_SCROLLCARET_, EM_SCROLLCARET_ED:
        ScrollCaretIntoView;
      EM_SCROLL:
        begin
          Count := FTopRow;
          case Message.WParam of
            SB_LINEUP: ScrollToRow(FTopRow - 1);
            SB_LINEDOWN: ScrollToRow(FTopRow + 1);
            SB_PAGEUP: ScrollToRow(FTopRow - VisibleRows);
            SB_PAGEDOWN: ScrollToRow(FTopRow + VisibleRows);
          end;
          Message.Result := MakeLong(Word(FTopRow - Count), 1);
        end;
      WM_VSCROLL:
        begin
          case LoWord(Message.WParam) of
            SB_LINEUP: ScrollToRow(FTopRow - 1);
            SB_LINEDOWN: ScrollToRow(FTopRow + 1);
            SB_PAGEUP: ScrollToRow(FTopRow - VisibleRows);
            SB_PAGEDOWN: ScrollToRow(FTopRow + VisibleRows);
            SB_TOP: ScrollToRow(0);
            SB_BOTTOM: ScrollToRow(MaxTopRow);
            SB_THUMBTRACK, SB_THUMBPOSITION: ScrollToRow(HiWord(Message.WParam));
          end;
        end;
      WM_HSCROLL:
        // Окно растянуто во всю ширину, вбок сдвигает Unit1 (FScrollX)
        ;
      WM_MOUSEWHEEL:
        begin
          Count := 3;
          SystemParametersInfo(SPI_GETWHEELSCROLLLINES, 0, @Count, 0);
          if (Count <= 0) or (Count > VisibleRows) then
            Count := VisibleRows;
          ScrollToRow(FTopRow - SmallInt(HiWord(Message.WParam)) * Count div
            WHEEL_DELTA);
        end;
      EM_GETSCROLLPOS_:
        begin
          Pt := PPoint(Message.LParam);
          Pt^.X := 0;
          Pt^.Y := FTopRow * FLineH;
          Message.Result := 1;
        end;
      EM_SETSCROLLPOS_:
        begin
          Pt := PPoint(Message.LParam);
          ScrollToRow(Pt^.Y div FLineH);
          Message.Result := 1;
        end;

      // --- Клавиатура и мышь ---
      WM_KEYDOWN:
        DoKeyDown(Message.WParam);
      WM_SYSKEYDOWN:
        if Message.WParam = VK_BACK then
          DoKeyDown(VK_BACK)
        else
          Result := False;
      WM_CHAR:
        DoChar(Message.WParam and $FF);
      WM_IME_CHAR:
        // Символ IME - через DefWindowProc он придёт как WM_CHAR
        Message.Result := DefWindowProcA(Wnd, Message.Msg, Message.WParam,
          Message.LParam);
      WM_LBUTTONDOWN:
        DoMouseDown(Message, False);
      WM_LBUTTONDBLCLK:
        DoMouseDown(Message, True);
      WM_MOUSEMOVE:
        DoMouseMove(Message);
      WM_LBUTTONUP:
        DoMouseUp;
      WM_CAPTURECHANGED:
        begin
          if FMouseSel and (HWND(Message.LParam) <> Wnd) then
            DoMouseUp;
          Result := False;
        end;
      WM_TIMER:
        if Message.WParam = EmuTimerId then
          DoTimer
        else
          Result := False;

      // --- Остальное, что у RichEdit, - ему без записи в журнал ---
      EM_GETRECT, EM_SETRECT, EM_SETRECTNP, EM_SETMARGINS, EM_GETMARGINS,
      EM_SETCHARFORMAT_, EM_GETCHARFORMAT_, EM_SETPARAFORMAT_,
      EM_GETPARAFORMAT_, EM_SETBKGNDCOLOR_, EM_SETTARGETDEVICE_,
      EM_SETOPTIONS_, EM_GETOPTIONS_, EM_SETOLECALLBACK_,
      EM_GETOLEINTERFACE_, EM_SETTEXTMODE_, EM_GETTEXTMODE_,
      EM_AUTOURLDETECT_, EM_SETLANGOPTIONS_, EM_GETLANGOPTIONS_,
      EM_SETEDITSTYLE_, EM_GETEDITSTYLE_, EM_SETTYPOGRAPHYOPTIONS_,
      EM_GETTYPOGRAPHYOPTIONS_, EM_GETZOOM_, EM_SETZOOM_, EM_SETFONTSIZE_,
      EM_SHOWSCROLLBAR_, EM_REQUESTRESIZE_, EM_SETWORDBREAKPROC,
      EM_GETWORDBREAKPROC, EM_GETUNDONAME_, EM_GETREDONAME_:
        Result := False;
    else
      Result := False;
      // EM_* и сообщения поля ввода, которых здесь нет, - в журнал
      if ((Message.Msg >= WM_USER) and (Message.Msg < WM_USER + $200)) or
         ((Message.Msg >= EM_GETSEL) and (Message.Msg <= $00DA)) then
        LogOnce(Message.Msg);
    end;
  finally
    Dec(FDepth);
  end;
  if FDepth = 0 then
    Notify;
end;

end.
