unit EdHost;

// ---------------------------------------------------------------------------
//  Окно основного редактора unIDE (RichEdit1 в Unit1) без RichEdit (план
//  портирования, шаг 0.7.7). Текст, выделение, откат, ввод и места
//  символов - у своего редактора (TEdRichEmu, EdRichEmu.pas): Unit1 ставит
//  его перед оконной процедурой окна (NewRichEditProc, DefEditProc).
//  Остальное, что раньше делал RichEdit, - EdHostWin.EdHostHandle.
//
//  Свойства и методы - те, что Unit1 брал у TRichEdit, и так же, как у
//  него, сообщениями окну (SelStart - EM_EXGETSEL, Modified - EM_GETMODIFY,
//  SelText - EM_REPLACESEL / EM_GETTEXTRANGE и т.д.): их разбирает свой
//  редактор, Unit1 не меняется. Lines - строки через EM_GETLINECOUNT,
//  EM_LINEINDEX, EM_GETLINE. OnChange - по EN_CHANGE от своего редактора.
//  Рисует окно Unit1 (WM_PAINT в NewRichEditProc).
// ---------------------------------------------------------------------------

interface

uses
  {$IFDEF FPC} LCLType, {$ENDIF}
  Windows, Messages, SysUtils, Classes, Graphics, Controls, StdCtrls,
  EdHostWin;

type
  TEdHostEdit = class(TCustomControl)
  private
    FState: TEdHostState;
    FLines: TStrings;
    FReadOnly: Boolean;
    FScrollBars: TScrollStyle;
    FOnChange: TNotifyEvent;
{$IFDEF FPC}
    FOrigWndProc: Pointer;   // оконная процедура LCL до EdHostSubProc
{$ENDIF}
    function GetSelStart: Integer;
    procedure SetSelStart(AValue: Integer);
    function GetSelLength: Integer;
    procedure SetSelLength(AValue: Integer);
    function GetSelText: string;
    procedure SetSelText(const AValue: string);
    function GetModified: Boolean;
    procedure SetModified(AValue: Boolean);
    procedure SetReadOnly(AValue: Boolean);
    procedure SetLines(AValue: TStrings);
    procedure CNCommand(var Message: TWMCommand); message CN_COMMAND;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
{$IFDEF FPC}
    procedure DestroyWnd; override;
    // Text окна: в LCL - поле FCaption и SetWindowTextW в UTF-8, здесь -
    // сообщения своему редактору в кодировке Windows, как в Delphi 7
    function RealGetText: TCaption; override;
    procedure RealSetText(const AValue: TCaption); override;
{$ENDIF}
    procedure WndProc(var Message: TMessage); override;
    procedure Paint; override;
    procedure Change; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
{$IFDEF FPC}
    // В LCL GetTextLen - длина FCaption, а не WM_GETTEXTLENGTH
    function GetTextLen: Integer; reintroduce;
{$ENDIF}
    procedure Undo;
    procedure CutToClipboard;
    procedure CopyToClipboard;
    procedure PasteFromClipboard;
    procedure ClearSelection;
    procedure SelectAll;
    property SelStart: Integer read GetSelStart write SetSelStart;
    property SelLength: Integer read GetSelLength write SetSelLength;
    // Выделенный текст в кодировке Windows (EM_GETTEXTRANGE в UTF-16)
    property SelText: string read GetSelText write SetSelText;
    property Modified: Boolean read GetModified write SetModified;
    property Lines: TStrings read FLines write SetLines;
    property ReadOnly: Boolean read FReadOnly write SetReadOnly;
    // Полос у окна нет (прокрутку рисует Unit1); свойство - для Unit1
    property ScrollBars: TScrollStyle read FScrollBars write FScrollBars;
    // Весь текст (WM_GETTEXT / WM_SETTEXT), перевод строки - CRLF
    property Text;
  published
    property Align;
    property Anchors;
    property Constraints;
    property Enabled;
    property Color;
    property Font;
    property ParentFont;
    property PopupMenu;
    property TabOrder;
    property TabStop;
    property Visible;
    property ShowHint;
    property OnEnter;
    property OnExit;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

const
  EM_EXGETSEL_ = WM_USER + 52;
  EM_EXSETSEL_ = WM_USER + 55;
  EM_SETEVENTMASK_ = WM_USER + 69;
  EM_GETTEXTRANGE_ = WM_USER + 75;
  EM_SCROLLCARET_ = $00B7;
  ENM_CHANGE_ = $00000001;
  ENM_SELCHANGE_ = $00080000;

type
  TEdCharRange = record
    cpMin: Longint;
    cpMax: Longint;
  end;
  TEdTextRangeW = record
    chrg: TEdCharRange;
    lpstrText: PWideChar;
  end;

  // Lines окна: строки через сообщения окну (их разбирает свой редактор)
  TEdHostLines = class(TStrings)
  private
    FEdit: TEdHostEdit;
  protected
    function Get(Index: Integer): string; override;
    function GetCount: Integer; override;
    procedure SetTextStr(const Value: string); override;
  public
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
    procedure Insert(Index: Integer; const Str: string); override;
  end;

// Число строк как у TRichEdit.Lines: пустая последняя строка не считается
function TEdHostLines.GetCount: Integer;
var
  LastStart: Integer;
begin
  Result := SendMessage(FEdit.Handle, EM_GETLINECOUNT, 0, 0);
  if Result > 0 then
  begin
    LastStart := SendMessage(FEdit.Handle, EM_LINEINDEX, Result - 1, 0);
    if SendMessage(FEdit.Handle, EM_LINELENGTH, LastStart, 0) = 0 then
      Dec(Result);
  end;
end;

function TEdHostLines.Get(Index: Integer): string;
var
  LineStart, LineLen, Got: Integer;
begin
  Result := '';
  LineStart := SendMessage(FEdit.Handle, EM_LINEINDEX, Index, 0);
  if LineStart < 0 then
    Exit;
  LineLen := SendMessage(FEdit.Handle, EM_LINELENGTH, LineStart, 0);
  // Первое слово буфера EM_GETLINE - его размер; не меньше двух байт
  SetLength(Result, LineLen + 2);
  PWord(PChar(Result))^ := LineLen + 2;
  Got := SendMessage(FEdit.Handle, EM_GETLINE, Index, LPARAM(PChar(Result)));
  if Got < 0 then
    Got := 0;
  if Got > LineLen then
    Got := LineLen;
  SetLength(Result, Got);
  while (Result <> '') and (Result[Length(Result)] in [#13, #10]) do
    SetLength(Result, Length(Result) - 1);
end;

procedure TEdHostLines.SetTextStr(const Value: string);
begin
  FEdit.SetTextBuf(PChar(Value));
end;

procedure TEdHostLines.Clear;
begin
  FEdit.SetTextBuf('');
end;

procedure TEdHostLines.Delete(Index: Integer);
var
  LineStart, NextStart: Integer;
begin
  LineStart := SendMessage(FEdit.Handle, EM_LINEINDEX, Index, 0);
  if LineStart < 0 then
    Exit;
  NextStart := SendMessage(FEdit.Handle, EM_LINEINDEX, Index + 1, 0);
  if NextStart < 0 then
    NextStart := LineStart + SendMessage(FEdit.Handle, EM_LINELENGTH,
      LineStart, 0);
  SendMessage(FEdit.Handle, EM_SETSEL, LineStart, NextStart);
  SendMessage(FEdit.Handle, EM_REPLACESEL, 0, LPARAM(PChar('')));
end;

procedure TEdHostLines.Insert(Index: Integer; const Str: string);
var
  LineStart: Integer;
  Line: string;
begin
  LineStart := SendMessage(FEdit.Handle, EM_LINEINDEX, Index, 0);
  if LineStart >= 0 then
    Line := Str + #13#10
  else
  begin
    // За последней строкой - в конец текста, с новой строки
    LineStart := FEdit.GetTextLen;
    Line := #13#10 + Str;
  end;
  SendMessage(FEdit.Handle, EM_SETSEL, LineStart, LineStart);
  SendMessage(FEdit.Handle, EM_REPLACESEL, 0, LPARAM(PChar(Line)));
end;

// ---------------------------------------------------------------------------

constructor TEdHostEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  EdHostInit(FState);
  // Без csSetCaption: имя компонента не должно стать текстом редактора
  ControlStyle := ControlStyle - [csSetCaption] + [csOpaque];
  FLines := TEdHostLines.Create;
  TEdHostLines(FLines).FEdit := Self;
  FScrollBars := ssNone;
  TabStop := True;
  Cursor := crIBeam;
  Width := 185;
  Height := 89;
end;

destructor TEdHostEdit.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

// Без CS_HREDRAW / CS_VREDRAW: строки не переносятся, и смена размера не
// требует перерисовать всё окно (как было у окна RichEdit)
procedure TEdHostEdit.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.WindowClass.style := Params.WindowClass.style and
    not (CS_HREDRAW or CS_VREDRAW);
end;

{$IFDEF FPC}
// LCL (win32callback) передаёт в WindowProc контрола только сообщения,
// которые разбирает сам, и сообщения от WM_USER. Остальные - EM_GETLINECOUNT,
// EM_EXGETSEL, WM_GETTEXT, WM_CUT и т.п. - уходят в DefWindowProc, и свой
// редактор их не видит (Lines.Count = 0, текст не показывается). Поэтому
// окно подклассируется: эти сообщения - сразу в WindowProc, прочие - в
// оконную процедуру LCL.
//
// Подкласс - ANSI (SetWindowLongPtrA), как окно в сборке Delphi 7: свой
// редактор и Unit1 передают текст в кодировке Windows (CP_ACP). Окна LCL -
// Unicode; текст сообщений от них (SetWindowTextW, WM_CHAR из очереди W)
// Windows сама переводит в ANSI перед вызовом подкласса, а для оконной
// процедуры LCL (CallWindowProcA) - обратно
const
  EdHostPropName = 'unIDE.EdHostEdit';

function EdHostRoutes(AMsg: UINT): Boolean;
begin
  // WM_PAINT - тоже мимо LCL: LCL сам делает BeginPaint и передаёт DC в
  // WParam, а Unit1 (NewRichEditProc) рисует всё окно сам, только при
  // WParam = 0
  Result := (AMsg = WM_PAINT) or (AMsg = WM_SETTEXT) or (AMsg = WM_GETTEXT) or
            (AMsg = WM_GETTEXTLENGTH) or
            ((AMsg >= $00B0) and (AMsg <= $00DA)) or   // EM_GETSEL..EM_GETIMESTATUS
            ((AMsg >= WM_CUT) and (AMsg <= WM_UNDO)) or
            // Символ - тоже мимо LCL: она переводит его в UTF-8 (KeyPress), а
            // в WindowProc отдаёт CN_CHAR / LM_CHAR без кириллицы
            (AMsg = WM_CHAR);
end;

function EdHostSubProc(AWnd: HWND; AMsg: UINT; AWParam: WPARAM;
  ALParam: LPARAM): LRESULT; stdcall;
var
  Host: TEdHostEdit;
  HostMsg: TMessage;
begin
  Host := TEdHostEdit(GetProp(AWnd, EdHostPropName));
  if Host = nil then
  begin
    Result := DefWindowProcA(AWnd, AMsg, AWParam, ALParam);
    Exit;
  end;
  if EdHostRoutes(AMsg) then
  begin
    FillChar(HostMsg, SizeOf(HostMsg), 0);
    HostMsg.Msg := AMsg;
    HostMsg.WParam := AWParam;
    HostMsg.LParam := ALParam;
    Host.WindowProc(HostMsg);
    Result := HostMsg.Result;
  end
  else
    Result := CallWindowProcA(WNDPROC(Host.FOrigWndProc), AWnd, AMsg,
                              AWParam, ALParam);
end;

procedure TEdHostEdit.DestroyWnd;
begin
  if HandleAllocated and (FOrigWndProc <> nil) then
  begin
    SetWindowLongPtrA(Handle, GWL_WNDPROC, LONG_PTR(FOrigWndProc));
    RemoveProp(Handle, EdHostPropName);
    FOrigWndProc := nil;
  end;
  inherited DestroyWnd;
end;

function TEdHostEdit.GetTextLen: Integer;
begin
  Result := 0;
  if HandleAllocated then
    Result := SendMessageA(Handle, WM_GETTEXTLENGTH, 0, 0);
end;

function TEdHostEdit.RealGetText: TCaption;
var
  TextLen: Integer;
begin
  Result := '';
  TextLen := GetTextLen;
  if TextLen <= 0 then
    Exit;
  SetLength(Result, TextLen + 1);
  TextLen := SendMessageA(Handle, WM_GETTEXT, TextLen + 1,
    LPARAM(PAnsiChar(Result)));
  if TextLen < 0 then
    TextLen := 0;
  SetLength(Result, TextLen);
end;

procedure TEdHostEdit.RealSetText(const AValue: TCaption);
begin
  if HandleAllocated then
    SendMessageA(Handle, WM_SETTEXT, 0, LPARAM(PAnsiChar(AValue)))
  else
    inherited RealSetText(AValue);
end;
{$ENDIF}

procedure TEdHostEdit.CreateWnd;
begin
  inherited CreateWnd;
{$IFDEF FPC}
  SetProp(Handle, EdHostPropName, THandle(Self));
  FOrigWndProc := Pointer(SetWindowLongPtrA(Handle, GWL_WNDPROC,
                                            LONG_PTR(@EdHostSubProc)));
{$ENDIF}
  // Маска уведомлений, как у TRichEdit: свой редактор берёт её при запуске
  SendMessage(Handle, EM_SETEVENTMASK_, 0, ENM_CHANGE_ or ENM_SELCHANGE_);
  if FReadOnly then
    SendMessage(Handle, EM_SETREADONLY, 1, 0);
end;

procedure TEdHostEdit.WndProc(var Message: TMessage);
begin
  if EdHostHandle(WindowHandle, FState, Message) then
    Exit;
  inherited WndProc(Message);
end;

// Рисует Unit1 (NewRichEditProc); сюда - только рисование в чужой DC
procedure TEdHostEdit.Paint;
begin
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);
end;

procedure TEdHostEdit.CMFontChanged(var Message: TMessage);
begin
  inherited;
  FState.CaretHeight := Abs(Font.Height);
  if FState.CaretHeight < 2 then
    FState.CaretHeight := 16;
end;

procedure TEdHostEdit.CNCommand(var Message: TWMCommand);
begin
  if Message.NotifyCode = EN_CHANGE then
    Change;
end;

procedure TEdHostEdit.Change;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TEdHostEdit.GetSelStart: Integer;
var
  Range: TEdCharRange;
begin
  SendMessage(Handle, EM_EXGETSEL_, 0, LPARAM(@Range));
  Result := Range.cpMin;
end;

procedure TEdHostEdit.SetSelStart(AValue: Integer);
var
  Range: TEdCharRange;
begin
  Range.cpMin := AValue;
  Range.cpMax := AValue;
  SendMessage(Handle, EM_EXSETSEL_, 0, LPARAM(@Range));
end;

function TEdHostEdit.GetSelLength: Integer;
var
  Range: TEdCharRange;
begin
  SendMessage(Handle, EM_EXGETSEL_, 0, LPARAM(@Range));
  Result := Range.cpMax - Range.cpMin;
end;

// Как у TCustomRichEdit: начало выделения на месте, конец - через AValue
procedure TEdHostEdit.SetSelLength(AValue: Integer);
var
  Range: TEdCharRange;
begin
  SendMessage(Handle, EM_EXGETSEL_, 0, LPARAM(@Range));
  Range.cpMax := Range.cpMin + AValue;
  SendMessage(Handle, EM_EXSETSEL_, 0, LPARAM(@Range));
  SendMessage(Handle, EM_SCROLLCARET_, 0, 0);
end;

function TEdHostEdit.GetSelText: string;
var
  Range: TEdTextRangeW;
  Text: WideString;
  Got: Integer;
begin
  Result := '';
  SendMessage(Handle, EM_EXGETSEL_, 0, LPARAM(@Range.chrg));
  if Range.chrg.cpMax <= Range.chrg.cpMin then
    Exit;
  SetLength(Text, Range.chrg.cpMax - Range.chrg.cpMin + 1);
  Range.lpstrText := PWideChar(Text);
  Got := SendMessage(Handle, EM_GETTEXTRANGE_, 0, LPARAM(@Range));
  if Got <= 0 then
    Exit;
  if Got > Length(Text) - 1 then
    Got := Length(Text) - 1;
  SetLength(Text, Got);
  {$IFDEF FPC}
  // Как у прочих строк редактора - в кодировке Windows (string(Text) под
  // FPC дал бы UTF-8)
  SetLength(Result, Got);
  if Got > 0 then
    SetLength(Result, WideCharToMultiByte(CP_ACP, 0, PWideChar(Text), Got,
      PAnsiChar(Result), Got, nil, nil));
  {$ELSE}
  Result := string(Text);
  {$ENDIF}
end;

procedure TEdHostEdit.SetSelText(const AValue: string);
begin
  SendMessage(Handle, EM_REPLACESEL, 0, LPARAM(PChar(AValue)));
end;

function TEdHostEdit.GetModified: Boolean;
begin
  Result := SendMessage(Handle, EM_GETMODIFY, 0, 0) <> 0;
end;

procedure TEdHostEdit.SetModified(AValue: Boolean);
begin
  SendMessage(Handle, EM_SETMODIFY, Ord(AValue), 0);
end;

procedure TEdHostEdit.SetReadOnly(AValue: Boolean);
begin
  FReadOnly := AValue;
  if HandleAllocated then
    SendMessage(Handle, EM_SETREADONLY, Ord(AValue), 0);
end;

procedure TEdHostEdit.SetLines(AValue: TStrings);
begin
  FLines.Assign(AValue);
end;

procedure TEdHostEdit.Undo;
begin
  SendMessage(Handle, EM_UNDO, 0, 0);
end;

procedure TEdHostEdit.CutToClipboard;
begin
  SendMessage(Handle, WM_CUT, 0, 0);
end;

procedure TEdHostEdit.CopyToClipboard;
begin
  SendMessage(Handle, WM_COPY, 0, 0);
end;

procedure TEdHostEdit.PasteFromClipboard;
begin
  SendMessage(Handle, WM_PASTE, 0, 0);
end;

procedure TEdHostEdit.ClearSelection;
begin
  SendMessage(Handle, WM_CLEAR, 0, 0);
end;

procedure TEdHostEdit.SelectAll;
begin
  SendMessage(Handle, EM_SETSEL, 0, -1);
end;

initialization
  RegisterClass(TEdHostEdit);

end.
