unit UiDialogs;

// ---------------------------------------------------------------------------
//  Окна сообщений из своих элементов (TUiLabel, TUiButton, TUiEdit) - вид
//  по теме UiTheme, как у остальных окон программы.
//
//  Функции - с теми же именами и параметрами, что в модуле Dialogs VCL:
//  ShowMessage, ShowMessageFmt, MessageDlg, MessageDlgPos, InputQuery,
//  InputBox. Модуль ставится в uses ПОСЛЕ Dialogs - тогда вызовы без имени
//  модуля попадают сюда, и менять их в коде не нужно. Вызов через имя
//  модуля (Dialogs.ShowMessage) по-прежнему даёт окно VCL.
//
//  UiMessageBox - замена Application.MessageBox (флаги MB_* и ответы ID*
//  те же). Application.MessageBox - метод, его вызовы меняются в коде.
//
//  Окно: значок (системный: ошибка, предупреждение, сведения, вопрос),
//  текст с переносами по ширине до половины экрана, кнопки справа внизу.
//  Кнопка по умолчанию и кнопка Esc выбираются так же, как у MessageDlg
//  VCL. Подписи кнопок и заголовки - строки VCL (модуль Consts).
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs;

procedure ShowMessage(const Msg: string);
procedure ShowMessageFmt(const Msg: string; Params: array of const);
function MessageDlg(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Longint): Integer;
function MessageDlgPos(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Longint; X, Y: Integer): Integer;
function InputQuery(const ACaption, APrompt: string;
  var Value: string): Boolean;
function InputBox(const ACaption, APrompt, ADefault: string): string;

// Окно с вопросом и своими подписями кнопок (вместо CreateMessageDialog
// VCL: у его TButton подписи пропадают по Alt, кнопки после правки
// подписей налезают друг на друга). Ответ - номер кнопки в AButtons (с 0),
// Esc и крестик - ACancelIndex. ADefaultIndex - кнопка Enter
function MessageDlgButtons(const Msg: string; DlgType: TMsgDlgType;
  const ACaption: string; const AButtons: array of string;
  ADefaultIndex, ACancelIndex: Integer): Integer;

// Как Application.MessageBox: флаги MB_OK, MB_YESNO, MB_ICONQUESTION,
// MB_DEFBUTTON2 и т. д.; ответ - IDOK, IDYES, IDNO...
function UiMessageBox(Text, Caption: PChar; Flags: Longint): Integer;

implementation

uses
  Consts, ExtCtrls, UiTheme, UiButton, UiStdCtrls, UiEditCtrls;

const
  // Части флагов MessageBox: кнопки, значок, кнопка по умолчанию
  MbTypeMask = $0000000F;
  MbIconMask = $000000F0;
  MbDefMask = $00000F00;

  Margin = 12;          // от края окна
  Gap = 8;              // между кнопками, между значком и текстом
  ButtonHeight = 25;
  MinButtonWidth = 75;
  IconSize = 32;

type
  TButtonDef = record
    Kind: TMsgDlgBtn;
    Result: Integer;
  end;

// Подпись и ответ кнопки - как у MessageDlg VCL
function ButtonCaption(AKind: TMsgDlgBtn): string;
begin
  case AKind of
    mbYes: Result := SMsgDlgYes;
    mbNo: Result := SMsgDlgNo;
    mbOK: Result := SMsgDlgOK;
    mbCancel: Result := SMsgDlgCancel;
    mbAbort: Result := SMsgDlgAbort;
    mbRetry: Result := SMsgDlgRetry;
    mbIgnore: Result := SMsgDlgIgnore;
    mbAll: Result := SMsgDlgAll;
    mbNoToAll: Result := SMsgDlgNoToAll;
    mbYesToAll: Result := SMsgDlgYesToAll;
    mbHelp: Result := SMsgDlgHelp;
  else
    Result := '';
  end;
end;

function ButtonResult(AKind: TMsgDlgBtn): Integer;
begin
  case AKind of
    mbYes: Result := mrYes;
    mbNo: Result := mrNo;
    mbOK: Result := mrOk;
    mbCancel: Result := mrCancel;
    mbAbort: Result := mrAbort;
    mbRetry: Result := mrRetry;
    mbIgnore: Result := mrIgnore;
    mbAll: Result := mrAll;
    mbNoToAll: Result := mrNoToAll;
    mbYesToAll: Result := mrYesToAll;
  else
    Result := mrNone;
  end;
end;

function DlgCaption(ADlgType: TMsgDlgType): string;
begin
  case ADlgType of
    mtWarning: Result := SMsgDlgWarning;
    mtError: Result := SMsgDlgError;
    mtInformation: Result := SMsgDlgInformation;
    mtConfirmation: Result := SMsgDlgConfirm;
  else
    Result := Application.Title;
  end;
end;

function DlgIcon(ADlgType: TMsgDlgType): HICON;
begin
  case ADlgType of
    mtWarning: Result := LoadIcon(0, IDI_EXCLAMATION);
    mtError: Result := LoadIcon(0, IDI_HAND);
    mtInformation: Result := LoadIcon(0, IDI_ASTERISK);
    mtConfirmation: Result := LoadIcon(0, IDI_QUESTION);
  else
    Result := 0;
  end;
end;

// Окно - по теме: фон и шрифт формы из ролей окна
procedure PaintDialogForm(AForm: TForm);
begin
  AForm.Color := UiThemeColor('Window.BG');
  AForm.Font.Color := UiThemeColor('Window.Text');
end;

function NewDialogForm(const ACaption: string): TForm;
begin
  Result := TForm.CreateNew(Application);
  Result.BorderStyle := bsDialog;
  Result.BorderIcons := [biSystemMenu];
  Result.Caption := ACaption;
  if Application.MainForm <> nil then
    Result.Font := Application.MainForm.Font;
  Result.Position := poScreenCenter;
  PaintDialogForm(Result);
end;

// Окно сообщения. ADefault / ACancel - какие кнопки нажимаются Enter и
// Esc; ALeft/ATop >= 0 - место окна, иначе по центру экрана.
function RunMessage(const AMsg, ACaption: string; AIcon: HICON;
  AButtons: TMsgDlgButtons; ADefault, ACancel: TMsgDlgBtn;
  ALeft, ATop: Integer): Integer;
var
  Form: TForm;
  TextLabel: TUiLabel;
  IconImage: TImage;
  Btn: TUiButton;
  Kind: TMsgDlgBtn;
  TextRect: TRect;
  Measure: TBitmap;
  TextLeft, ButtonsWidth, ButtonWidth, ButtonCount, X, Y, W, H: Integer;
  Flags: Cardinal;
begin
  Form := NewDialogForm(ACaption);
  Measure := TBitmap.Create;
  try
    Measure.Canvas.Font := Form.Font;

    // Значок
    TextLeft := Margin;
    if AIcon <> 0 then
    begin
      IconImage := TImage.Create(Form);
      IconImage.Parent := Form;
      IconImage.SetBounds(Margin, Margin, IconSize, IconSize);
      IconImage.Transparent := True;
      IconImage.Picture.Icon.Handle := AIcon;
      TextLeft := Margin + IconSize + Gap + 4;
    end;

    // Текст: ширина - до половины экрана, строки переносятся
    TextRect := Rect(0, 0, Screen.Width div 2, 0);
    Flags := DT_CALCRECT or DT_WORDBREAK or DT_NOPREFIX or DT_EXPANDTABS;
    DrawText(Measure.Canvas.Handle, PChar(AMsg), Length(AMsg), TextRect,
             Flags);
    TextLabel := TUiLabel.Create(Form);
    TextLabel.Parent := Form;
    TextLabel.ShowAccelChar := False;
    TextLabel.WordWrap := True;
    TextLabel.AutoSize := False;
    TextLabel.Caption := AMsg;
    TextLabel.SetBounds(TextLeft, Margin, TextRect.Right + 4, TextRect.Bottom);

    // Кнопки: ширина одна на всех - по самой длинной подписи
    ButtonWidth := MinButtonWidth;
    ButtonCount := 0;
    for Kind := Low(TMsgDlgBtn) to High(TMsgDlgBtn) do
      if (Kind in AButtons) and (Kind <> mbHelp) then
      begin
        Inc(ButtonCount);
        W := Measure.Canvas.TextWidth(StringReplace(ButtonCaption(Kind), '&',
                                                    '', [])) + 24;
        if W > ButtonWidth then
          ButtonWidth := W;
      end;
    if ButtonCount = 0 then
    begin
      Include(AButtons, mbOK);
      ButtonCount := 1;
      ADefault := mbOK;
      ACancel := mbOK;
    end;
    ButtonsWidth := ButtonCount * ButtonWidth + (ButtonCount - 1) * Gap;

    // Размер окна
    W := TextLeft + TextRect.Right + 4 + Margin;
    if W < ButtonsWidth + 2 * Margin then
      W := ButtonsWidth + 2 * Margin;
    H := TextRect.Bottom;
    if (AIcon <> 0) and (H < IconSize) then
      H := IconSize;
    Y := Margin + H + Margin + 4;
    Form.ClientWidth := W;
    Form.ClientHeight := Y + ButtonHeight + Margin;

    // Кнопки - по центру внизу
    X := (W - ButtonsWidth) div 2;
    for Kind := Low(TMsgDlgBtn) to High(TMsgDlgBtn) do
      if (Kind in AButtons) and (Kind <> mbHelp) then
      begin
        Btn := TUiButton.Create(Form);
        Btn.Parent := Form;
        Btn.Caption := ButtonCaption(Kind);
        Btn.ModalResult := ButtonResult(Kind);
        Btn.SetBounds(X, Y, ButtonWidth, ButtonHeight);
        Btn.Default := Kind = ADefault;
        Btn.Cancel := Kind = ACancel;
        if Kind = ADefault then
          Form.ActiveControl := Btn;
        Inc(X, ButtonWidth + Gap);
      end;

    if (ALeft >= 0) and (ATop >= 0) then
    begin
      Form.Position := poDesigned;
      Form.Left := ALeft;
      Form.Top := ATop;
    end;

    Result := Form.ShowModal;
  finally
    Measure.Free;
    Form.Free;
  end;
end;

function MessageDlgButtons(const Msg: string; DlgType: TMsgDlgType;
  const ACaption: string; const AButtons: array of string;
  ADefaultIndex, ACancelIndex: Integer): Integer;
const
  ResultBase = 100;     // ответ кнопки N - ResultBase + N
var
  Form: TForm;
  TextLabel: TUiLabel;
  IconImage: TImage;
  Btn: TUiButton;
  TextRect: TRect;
  Measure: TBitmap;
  Icon: HICON;
  BtnIdx, TextLeft, ButtonsWidth, X, Y, W, H, Answer: Integer;
  Widths: array of Integer;
  Title: string;
begin
  Title := ACaption;
  if Title = '' then
    Title := DlgCaption(DlgType);
  Form := NewDialogForm(Title);
  Measure := TBitmap.Create;
  try
    Measure.Canvas.Font := Form.Font;
    TextLeft := Margin;
    Icon := DlgIcon(DlgType);
    if Icon <> 0 then
    begin
      IconImage := TImage.Create(Form);
      IconImage.Parent := Form;
      IconImage.SetBounds(Margin, Margin, IconSize, IconSize);
      IconImage.Transparent := True;
      IconImage.Picture.Icon.Handle := Icon;
      TextLeft := Margin + IconSize + Gap + 4;
    end;
    TextRect := Rect(0, 0, Screen.Width div 2, 0);
    DrawText(Measure.Canvas.Handle, PChar(Msg), Length(Msg), TextRect,
             DT_CALCRECT or DT_WORDBREAK or DT_NOPREFIX or DT_EXPANDTABS);
    TextLabel := TUiLabel.Create(Form);
    TextLabel.Parent := Form;
    TextLabel.ShowAccelChar := False;
    TextLabel.WordWrap := True;
    TextLabel.AutoSize := False;
    TextLabel.Caption := Msg;
    TextLabel.SetBounds(TextLeft, Margin, TextRect.Right + 4, TextRect.Bottom);

    // Ширина каждой кнопки - по своей подписи
    SetLength(Widths, Length(AButtons));
    ButtonsWidth := 0;
    for BtnIdx := 0 to High(AButtons) do
    begin
      Widths[BtnIdx] := Measure.Canvas.TextWidth(StringReplace(AButtons[BtnIdx],
        '&', '', [])) + 24;
      if Widths[BtnIdx] < MinButtonWidth then
        Widths[BtnIdx] := MinButtonWidth;
      Inc(ButtonsWidth, Widths[BtnIdx]);
      if BtnIdx > 0 then
        Inc(ButtonsWidth, Gap);
    end;

    W := TextLeft + TextRect.Right + 4 + Margin;
    if W < ButtonsWidth + 2 * Margin then
      W := ButtonsWidth + 2 * Margin;
    H := TextRect.Bottom;
    if (Icon <> 0) and (H < IconSize) then
      H := IconSize;
    Y := Margin + H + Margin + 4;
    Form.ClientWidth := W;
    Form.ClientHeight := Y + ButtonHeight + Margin;

    X := (W - ButtonsWidth) div 2;
    for BtnIdx := 0 to High(AButtons) do
    begin
      Btn := TUiButton.Create(Form);
      Btn.Parent := Form;
      Btn.Caption := AButtons[BtnIdx];
      Btn.ModalResult := ResultBase + BtnIdx;
      Btn.SetBounds(X, Y, Widths[BtnIdx], ButtonHeight);
      Btn.Default := BtnIdx = ADefaultIndex;
      Btn.Cancel := BtnIdx = ACancelIndex;
      if BtnIdx = ADefaultIndex then
        Form.ActiveControl := Btn;
      Inc(X, Widths[BtnIdx] + Gap);
    end;

    Answer := Form.ShowModal;
    if (Answer >= ResultBase) and (Answer <= ResultBase + High(AButtons)) then
      Result := Answer - ResultBase
    else
      Result := ACancelIndex;
  finally
    Measure.Free;
    Form.Free;
  end;
end;

// Кнопка Enter и кнопка Esc - как у MessageDlg VCL
procedure PickDefaults(AButtons: TMsgDlgButtons;
  var ADefault, ACancel: TMsgDlgBtn);
var
  Kind: TMsgDlgBtn;
begin
  if mbOK in AButtons then
    ADefault := mbOK
  else if mbYes in AButtons then
    ADefault := mbYes
  else
  begin
    // Иначе - первая по порядку
    ADefault := mbOK;
    for Kind := Low(TMsgDlgBtn) to High(TMsgDlgBtn) do
      if Kind in AButtons then
      begin
        ADefault := Kind;
        Break;
      end;
  end;
  if mbCancel in AButtons then
    ACancel := mbCancel
  else if mbNo in AButtons then
    ACancel := mbNo
  else
    ACancel := mbOK;
end;

function MessageDlgPos(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Longint; X, Y: Integer): Integer;
var
  Def, Cancel: TMsgDlgBtn;
begin
  PickDefaults(Buttons, Def, Cancel);
  Result := RunMessage(Msg, DlgCaption(DlgType), DlgIcon(DlgType), Buttons,
                       Def, Cancel, X, Y);
end;

function MessageDlg(const Msg: string; DlgType: TMsgDlgType;
  Buttons: TMsgDlgButtons; HelpCtx: Longint): Integer;
begin
  Result := MessageDlgPos(Msg, DlgType, Buttons, HelpCtx, -1, -1);
end;

procedure ShowMessage(const Msg: string);
begin
  RunMessage(Msg, Application.Title, 0, [mbOK], mbOK, mbOK, -1, -1);
end;

procedure ShowMessageFmt(const Msg: string; Params: array of const);
begin
  ShowMessage(Format(Msg, Params));
end;

function UiMessageBox(Text, Caption: PChar; Flags: Longint): Integer;
var
  Buttons: TMsgDlgButtons;
  Icon: HICON;
  Def, Cancel: TMsgDlgBtn;
  Order: array[0..2] of TMsgDlgBtn;
  Count, DefIndex: Integer;
begin
  // Кнопки - по флагам, в порядке MessageBox
  case Flags and MbTypeMask of
    MB_OKCANCEL:
      begin Order[0] := mbOK; Order[1] := mbCancel; Count := 2; end;
    MB_ABORTRETRYIGNORE:
      begin Order[0] := mbAbort; Order[1] := mbRetry; Order[2] := mbIgnore;
            Count := 3; end;
    MB_YESNOCANCEL:
      begin Order[0] := mbYes; Order[1] := mbNo; Order[2] := mbCancel;
            Count := 3; end;
    MB_YESNO:
      begin Order[0] := mbYes; Order[1] := mbNo; Count := 2; end;
    MB_RETRYCANCEL:
      begin Order[0] := mbRetry; Order[1] := mbCancel; Count := 2; end;
  else
    begin Order[0] := mbOK; Count := 1; end;
  end;
  Buttons := [];
  for DefIndex := 0 to Count - 1 do
    Include(Buttons, Order[DefIndex]);

  case Flags and MbIconMask of
    MB_ICONHAND: Icon := LoadIcon(0, IDI_HAND);
    MB_ICONQUESTION: Icon := LoadIcon(0, IDI_QUESTION);
    MB_ICONEXCLAMATION: Icon := LoadIcon(0, IDI_EXCLAMATION);
    MB_ICONASTERISK: Icon := LoadIcon(0, IDI_ASTERISK);
  else
    Icon := 0;
  end;

  // Кнопка по умолчанию - MB_DEFBUTTON1..3; Esc - Cancel, иначе No, иначе
  // единственная
  DefIndex := (Flags and MbDefMask) shr 8;
  if DefIndex >= Count then
    DefIndex := 0;
  Def := Order[DefIndex];
  if mbCancel in Buttons then
    Cancel := mbCancel
  else if mbNo in Buttons then
    Cancel := mbNo
  else if Count = 1 then
    Cancel := Order[0]
  else
    Cancel := mbIgnore;

  // Ответы MessageBox (IDOK, IDYES...) совпадают с mrOk, mrYes...
  Result := RunMessage(StrPas(Text), StrPas(Caption), Icon, Buttons, Def,
                       Cancel, -1, -1);
end;

function InputQuery(const ACaption, APrompt: string;
  var Value: string): Boolean;
var
  Form: TForm;
  PromptLabel: TUiLabel;
  Edit: TUiEdit;
  BtnOk, BtnCancel: TUiButton;
  Measure: TBitmap;
  W, Y: Integer;
begin
  Result := False;
  Form := NewDialogForm(ACaption);
  Measure := TBitmap.Create;
  try
    Measure.Canvas.Font := Form.Font;
    W := Measure.Canvas.TextWidth(APrompt) + 2 * Margin;
    if W < 320 then
      W := 320;
    Form.ClientWidth := W;

    PromptLabel := TUiLabel.Create(Form);
    PromptLabel.Parent := Form;
    PromptLabel.Caption := APrompt;
    PromptLabel.SetBounds(Margin, Margin, W - 2 * Margin,
                          Measure.Canvas.TextHeight('0'));
    Y := PromptLabel.Top + PromptLabel.Height + 4;

    Edit := TUiEdit.Create(Form);
    Edit.Parent := Form;
    Edit.SetBounds(Margin, Y, W - 2 * Margin, 21);
    Edit.Text := Value;
    Edit.SelectAll;
    Inc(Y, Edit.Height + Margin);

    BtnCancel := TUiButton.Create(Form);
    BtnCancel.Parent := Form;
    BtnCancel.Caption := SMsgDlgCancel;
    BtnCancel.ModalResult := mrCancel;
    BtnCancel.Cancel := True;
    BtnCancel.SetBounds(W - Margin - MinButtonWidth, Y, MinButtonWidth,
                        ButtonHeight);

    BtnOk := TUiButton.Create(Form);
    BtnOk.Parent := Form;
    BtnOk.Caption := SMsgDlgOK;
    BtnOk.ModalResult := mrOk;
    BtnOk.Default := True;
    BtnOk.SetBounds(BtnCancel.Left - Gap - MinButtonWidth, Y,
                    MinButtonWidth, ButtonHeight);

    Form.ClientHeight := Y + ButtonHeight + Margin;
    Form.ActiveControl := Edit;

    if Form.ShowModal = mrOk then
    begin
      Value := Edit.Text;
      Result := True;
    end;
  finally
    Measure.Free;
    Form.Free;
  end;
end;

function InputBox(const ACaption, APrompt, ADefault: string): string;
begin
  Result := ADefault;
  InputQuery(ACaption, APrompt, Result);
end;

end.
