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
    procedure WndProc(var Message: TMessage); override;
    procedure Paint; override;
    procedure Change; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
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
    property Color;
    property Font;
    property ParentFont;
    property PopupMenu;
    property TabOrder;
    property TabStop;
    property Visible;
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
    procedure Insert(Index: Integer; const S: string); override;
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
  Got := SendMessage(FEdit.Handle, EM_GETLINE, Index, Integer(PChar(Result)));
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
  SendMessage(FEdit.Handle, EM_REPLACESEL, 0, Integer(PChar('')));
end;

procedure TEdHostLines.Insert(Index: Integer; const S: string);
var
  LineStart: Integer;
  Line: string;
begin
  LineStart := SendMessage(FEdit.Handle, EM_LINEINDEX, Index, 0);
  if LineStart >= 0 then
    Line := S + #13#10
  else
  begin
    // За последней строкой - в конец текста, с новой строки
    LineStart := FEdit.GetTextLen;
    Line := #13#10 + S;
  end;
  SendMessage(FEdit.Handle, EM_SETSEL, LineStart, LineStart);
  SendMessage(FEdit.Handle, EM_REPLACESEL, 0, Integer(PChar(Line)));
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

procedure TEdHostEdit.CreateWnd;
begin
  inherited CreateWnd;
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
  SendMessage(Handle, EM_EXGETSEL_, 0, Integer(@Range));
  Result := Range.cpMin;
end;

procedure TEdHostEdit.SetSelStart(AValue: Integer);
var
  Range: TEdCharRange;
begin
  Range.cpMin := AValue;
  Range.cpMax := AValue;
  SendMessage(Handle, EM_EXSETSEL_, 0, Integer(@Range));
end;

function TEdHostEdit.GetSelLength: Integer;
var
  Range: TEdCharRange;
begin
  SendMessage(Handle, EM_EXGETSEL_, 0, Integer(@Range));
  Result := Range.cpMax - Range.cpMin;
end;

// Как у TCustomRichEdit: начало выделения на месте, конец - через AValue
procedure TEdHostEdit.SetSelLength(AValue: Integer);
var
  Range: TEdCharRange;
begin
  SendMessage(Handle, EM_EXGETSEL_, 0, Integer(@Range));
  Range.cpMax := Range.cpMin + AValue;
  SendMessage(Handle, EM_EXSETSEL_, 0, Integer(@Range));
  SendMessage(Handle, EM_SCROLLCARET_, 0, 0);
end;

function TEdHostEdit.GetSelText: string;
var
  Range: TEdTextRangeW;
  Text: WideString;
  Got: Integer;
begin
  Result := '';
  SendMessage(Handle, EM_EXGETSEL_, 0, Integer(@Range.chrg));
  if Range.chrg.cpMax <= Range.chrg.cpMin then
    Exit;
  SetLength(Text, Range.chrg.cpMax - Range.chrg.cpMin + 1);
  Range.lpstrText := PWideChar(Text);
  Got := SendMessage(Handle, EM_GETTEXTRANGE_, 0, Integer(@Range));
  if Got <= 0 then
    Exit;
  if Got > Length(Text) - 1 then
    Got := Length(Text) - 1;
  SetLength(Text, Got);
  Result := string(Text);
end;

procedure TEdHostEdit.SetSelText(const AValue: string);
begin
  SendMessage(Handle, EM_REPLACESEL, 0, Integer(PChar(AValue)));
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

end.
