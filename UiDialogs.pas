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
  Buttons: TMsgDlgButtons; HelpCtx: Longint; PosX, PosY: Integer): Integer;
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

// Системное окно MessageBox (когда своих окон ещё/уже нет). Под FPC
// строки UTF-8 -> MessageBoxW (MessageBoxA показал бы их как CP_ACP)
function UiSysMessageBox(AWnd: HWND; const AText, ACaption: string;
  AFlags: UINT): Integer;

implementation

uses
  {$IFNDEF FPC} Consts, {$ENDIF} ExtCtrls, UiTheme, UiButton, UiStdCtrls,
  UiEditCtrls;

{$IFDEF FPC}
// В Free Pascal модуля Consts нет; подписи - те же, что в Consts Delphi 7
resourcestring
  SMsgDlgWarning = 'Warning';
  SMsgDlgError = 'Error';
  SMsgDlgInformation = 'Information';
  SMsgDlgConfirm = 'Confirm';
  SMsgDlgYes = '&Yes';
  SMsgDlgNo = '&No';
  SMsgDlgOK = 'OK';
  SMsgDlgCancel = 'Cancel';
  SMsgDlgHelp = '&Help';
  SMsgDlgAbort = '&Abort';
  SMsgDlgRetry = '&Retry';
  SMsgDlgIgnore = '&Ignore';
  SMsgDlgAll = '&All';
  SMsgDlgNoToAll = 'N&o to All';
  SMsgDlgYesToAll = 'Yes to &All';
{$ENDIF}

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
  FrameReserve = 40;    // рамка окна и запас до края рабочей области

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

// Ширина строки текста в пикселях (шрифт - выбранный в ADC)
function TextWidthOf(ADC: HDC; const AStr: string): Integer;
var
  Size: TSize;
begin
  Result := 0;
  if AStr = '' then
    Exit;
  if UiTextExtent(ADC, PChar(AStr), Length(AStr), Size) then
    Result := Size.cx;
end;

// Последний байт символа, который начинается с байта APos (в Lazarus
// строки в UTF-8 - символ из нескольких байтов не режем)
function CharLastByte(const AStr: string; APos: Integer): Integer;
begin
  Result := APos;
  {$IFDEF FPC}
  while (Result < Length(AStr)) and (Ord(AStr[Result + 1]) and $C0 = $80) do
    Inc(Result);
  {$ENDIF}
end;

// Слово шире AWrapWidth (обычно путь к файлу) - на куски по ширине.
// Режем после последнего \ или / в куске, нет их - по символу.
// DT_WORDBREAK такое слово не переносит, и строка обрезалась справа
function BreakLongWord(ADC: HDC; const AWord: string;
  AWrapWidth: Integer): string;
var
  Rest: string;
  CharPos, LastByte, FitLen, SepLen: Integer;
begin
  Result := '';
  Rest := AWord;
  while (Rest <> '') and (TextWidthOf(ADC, Rest) > AWrapWidth) do
  begin
    FitLen := 0;
    SepLen := 0;
    CharPos := 1;
    while CharPos <= Length(Rest) do
    begin
      LastByte := CharLastByte(Rest, CharPos);
      if TextWidthOf(ADC, Copy(Rest, 1, LastByte)) > AWrapWidth then
        Break;
      FitLen := LastByte;
      if (Rest[LastByte] = '\') or (Rest[LastByte] = '/') then
        SepLen := LastByte;
      CharPos := LastByte + 1;
    end;
    if FitLen = 0 then
      FitLen := CharLastByte(Rest, 1);
    if SepLen > 0 then
      FitLen := SepLen;
    Result := Result + Copy(Rest, 1, FitLen) + #13#10;
    Delete(Rest, 1, FitLen);
  end;
  Result := Result + Rest;
end;

// Позиция последнего байта последнего #13#10 в строке (0 - нет)
function LastBreak(const AStr: string): Integer;
begin
  Result := Length(AStr);
  while (Result > 0) and (AStr[Result] <> #10) do
    Dec(Result);
end;

// Текст окна сообщения и его размер. Ширина переноса - половина экрана;
// слово длиннее (путь к файлу) расширяет её до своей длины, но не шире
// рабочей области экрана за вычетом полей окна (AReserved - значок, поля,
// рамка). Что и тогда не влезает - режется на строки (BreakLongWord).
// Результат - текст для надписи с готовыми переводами строк; ATextRect -
// его размер
function PrepareMessageText(ADC: HDC; const AMsg: string; AReserved: Integer;
  var ATextRect: TRect): string;
var
  MaxWidth, WrapWidth, WordWidth, CharIdx, WordStart, LineStart, LineEnd,
    PiecePos: Integer;
  WordText, LineText, CurLine, Candidate: string;

  function IsBreakChar(AChar: Char): Boolean;
  begin
    Result := (AChar = ' ') or (AChar = #9) or (AChar = #13) or (AChar = #10);
  end;

begin
  MaxWidth := Screen.WorkAreaWidth - AReserved;
  WrapWidth := Screen.Width div 2;
  if WrapWidth > MaxWidth then
    WrapWidth := MaxWidth;
  if WrapWidth < 200 then
    WrapWidth := 200;

  // Самое длинное слово - ширина переноса по нему, если влезает на экран
  CharIdx := 1;
  while CharIdx <= Length(AMsg) do
  begin
    if IsBreakChar(AMsg[CharIdx]) then
    begin
      Inc(CharIdx);
      Continue;
    end;
    WordStart := CharIdx;
    while (CharIdx <= Length(AMsg)) and not IsBreakChar(AMsg[CharIdx]) do
      Inc(CharIdx);
    WordWidth := TextWidthOf(ADC, Copy(AMsg, WordStart, CharIdx - WordStart));
    if WordWidth > WrapWidth then
    begin
      WrapWidth := WordWidth;
      if WrapWidth > MaxWidth then
        WrapWidth := MaxWidth;
    end;
  end;

  // Перенос строк - здесь, а не в надписи (WordWrap): по пробелам, слово
  // шире переноса - на куски (BreakLongWord). Надпись выводит готовые строки
  Result := '';
  LineStart := 1;
  while LineStart <= Length(AMsg) + 1 do
  begin
    LineEnd := LineStart;
    while (LineEnd <= Length(AMsg)) and (AMsg[LineEnd] <> #10) do
      Inc(LineEnd);
    LineText := Copy(AMsg, LineStart, LineEnd - LineStart);
    if (LineText <> '') and (LineText[Length(LineText)] = #13) then
      SetLength(LineText, Length(LineText) - 1);
    if LineStart > 1 then
      Result := Result + #13#10;
    if TextWidthOf(ADC, LineText) <= WrapWidth then
      Result := Result + LineText
    else
    begin
      CurLine := '';
      CharIdx := 1;
      while CharIdx <= Length(LineText) + 1 do
      begin
        WordStart := CharIdx;
        while (CharIdx <= Length(LineText)) and (LineText[CharIdx] <> ' ') do
          Inc(CharIdx);
        WordText := Copy(LineText, WordStart, CharIdx - WordStart);
        Inc(CharIdx); // пробел после слова
        if CurLine = '' then
          Candidate := WordText
        else
          Candidate := CurLine + ' ' + WordText;
        if (CurLine = '') or (TextWidthOf(ADC, Candidate) <= WrapWidth) then
          CurLine := Candidate
        else
        begin
          Result := Result + CurLine + #13#10;
          CurLine := WordText;
        end;
        if TextWidthOf(ADC, CurLine) > WrapWidth then
        begin
          // Слово длиннее строки: все куски, кроме последнего, - готовые
          // строки, последний продолжает строку
          CurLine := BreakLongWord(ADC, CurLine, WrapWidth);
          PiecePos := LastBreak(CurLine);
          Result := Result + Copy(CurLine, 1, PiecePos);
          Delete(CurLine, 1, PiecePos);
        end;
      end;
      Result := Result + CurLine;
    end;
    LineStart := LineEnd + 1;
  end;

  ATextRect := Rect(0, 0, WrapWidth, 0);
  UiDrawText(ADC, PChar(Result), Length(Result), ATextRect,
             DT_CALCRECT or DT_NOPREFIX or DT_EXPANDTABS);
end;

// DC для замеров текста шрифтом AFont. Свой DC экрана с явно выбранным
// шрифтом: у TBitmap.Canvas в Lazarus шрифт в Handle выбирается не сразу,
// и замер мог идти другим шрифтом, чем у надписи. Освобождать -
// EndMeasureDC
function BeginMeasureDC(AFont: TFont; var AOldFont: HGDIOBJ): HDC;
begin
  Result := GetDC(0);
  AOldFont := SelectObject(Result, AFont.Handle);
end;

procedure EndMeasureDC(ADC: HDC; AOldFont: HGDIOBJ);
begin
  SelectObject(ADC, AOldFont);
  ReleaseDC(0, ADC);
end;

// Шрифт надписи - как у окна. TUiLabel ставит цвет шрифта ещё в
// конструкторе (ApplyTheme), до Parent: ParentFont от этого выключается, и
// надпись оставалась со шрифтом по умолчанию, а замер шёл шрифтом окна
procedure UseFormFont(ALabel: TUiLabel; AForm: TForm);
begin
  ALabel.Font := AForm.Font;
  ALabel.Font.Color := UiThemeColorFor(ALabel, 'Window.Text');
end;

// Надпись с текстом сообщения: строки уже разбиты (PrepareMessageText),
// WordWrap выключен. Размер - по замеру и по самой надписи (что больше),
// ATextRect получает итоговый размер - по нему считается окно
function NewMessageLabel(AForm: TForm; ALeft: Integer; const AText: string;
  var ATextRect: TRect): TUiLabel;
{$IFDEF FPC}
var
  PrefWidth, PrefHeight: Integer;
{$ENDIF}
begin
  Result := TUiLabel.Create(AForm);
  Result.Parent := AForm;
  UseFormFont(Result, AForm);
  Result.ShowAccelChar := False;
  Result.WordWrap := False;
  Result.AutoSize := False;
  Result.Caption := AText;
  {$IFDEF FPC}
  PrefWidth := 0;
  PrefHeight := 0;
  Result.GetPreferredSize(PrefWidth, PrefHeight, True, False);
  if PrefWidth > ATextRect.Right then
    ATextRect.Right := PrefWidth;
  if PrefHeight > ATextRect.Bottom then
    ATextRect.Bottom := PrefHeight;
  {$ENDIF}
  Result.SetBounds(ALeft, Margin, ATextRect.Right + 4, ATextRect.Bottom);
end;

// Окно сообщения. ADefault / ACancel - какие кнопки нажимаются Enter и
// Esc; ALeft/ATop >= 0 - место окна, иначе по центру экрана.
function RunMessage(const AMsg, ACaption: string; AIcon: HICON;
  AButtons: TMsgDlgButtons; ADefault, ACancel: TMsgDlgBtn;
  ALeft, ATop: Integer): Integer;
var
  Form: TForm;
  IconImage: TImage;
  Btn: TUiButton;
  Kind: TMsgDlgBtn;
  TextRect: TRect;
  Measure: TBitmap;
  TextLeft, ButtonsWidth, ButtonWidth, ButtonCount, PosX, PosY, WidthPx, HeightPx: Integer;
  MsgText: string;
  MeasureDC: HDC;
  OldFont: HGDIOBJ;
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

    // Текст: ширина - до половины экрана (длинный путь - шире), строки
    // переносятся
    MeasureDC := BeginMeasureDC(Form.Font, OldFont);
    try
      MsgText := PrepareMessageText(MeasureDC, AMsg,
                                    TextLeft + 4 + Margin + FrameReserve,
                                    TextRect);
    finally
      EndMeasureDC(MeasureDC, OldFont);
    end;
    NewMessageLabel(Form, TextLeft, MsgText, TextRect);

    // Кнопки: ширина одна на всех - по самой длинной подписи
    ButtonWidth := MinButtonWidth;
    ButtonCount := 0;
    for Kind := Low(TMsgDlgBtn) to High(TMsgDlgBtn) do
      if (Kind in AButtons) and (Kind <> mbHelp) then
      begin
        Inc(ButtonCount);
        WidthPx := Measure.Canvas.TextWidth(StringReplace(ButtonCaption(Kind), '&',
                                                    '', [])) + 24;
        if WidthPx > ButtonWidth then
          ButtonWidth := WidthPx;
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
    WidthPx := TextLeft + TextRect.Right + 4 + Margin;
    if WidthPx < ButtonsWidth + 2 * Margin then
      WidthPx := ButtonsWidth + 2 * Margin;
    HeightPx := TextRect.Bottom;
    if (AIcon <> 0) and (HeightPx < IconSize) then
      HeightPx := IconSize;
    PosY := Margin + HeightPx + Margin + 4;
    Form.ClientWidth := WidthPx;
    Form.ClientHeight := PosY + ButtonHeight + Margin;

    // Кнопки - по центру внизу
    PosX := (WidthPx - ButtonsWidth) div 2;
    for Kind := Low(TMsgDlgBtn) to High(TMsgDlgBtn) do
      if (Kind in AButtons) and (Kind <> mbHelp) then
      begin
        Btn := TUiButton.Create(Form);
        Btn.Parent := Form;
        Btn.Caption := ButtonCaption(Kind);
        Btn.ModalResult := ButtonResult(Kind);
        Btn.SetBounds(PosX, PosY, ButtonWidth, ButtonHeight);
        Btn.Default := Kind = ADefault;
        Btn.Cancel := Kind = ACancel;
        if Kind = ADefault then
          Form.ActiveControl := Btn;
        Inc(PosX, ButtonWidth + Gap);
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
  IconImage: TImage;
  Btn: TUiButton;
  TextRect: TRect;
  Measure: TBitmap;
  Icon: HICON;
  BtnIdx, TextLeft, ButtonsWidth, PosX, PosY, WidthPx, HeightPx, Answer: Integer;
  Widths: array of Integer;
  Title, MsgText: string;
  MeasureDC: HDC;
  OldFont: HGDIOBJ;
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
    MeasureDC := BeginMeasureDC(Form.Font, OldFont);
    try
      MsgText := PrepareMessageText(MeasureDC, Msg,
                                    TextLeft + 4 + Margin + FrameReserve,
                                    TextRect);
    finally
      EndMeasureDC(MeasureDC, OldFont);
    end;
    NewMessageLabel(Form, TextLeft, MsgText, TextRect);

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

    WidthPx := TextLeft + TextRect.Right + 4 + Margin;
    if WidthPx < ButtonsWidth + 2 * Margin then
      WidthPx := ButtonsWidth + 2 * Margin;
    HeightPx := TextRect.Bottom;
    if (Icon <> 0) and (HeightPx < IconSize) then
      HeightPx := IconSize;
    PosY := Margin + HeightPx + Margin + 4;
    Form.ClientWidth := WidthPx;
    Form.ClientHeight := PosY + ButtonHeight + Margin;

    PosX := (WidthPx - ButtonsWidth) div 2;
    for BtnIdx := 0 to High(AButtons) do
    begin
      Btn := TUiButton.Create(Form);
      Btn.Parent := Form;
      Btn.Caption := AButtons[BtnIdx];
      Btn.ModalResult := ResultBase + BtnIdx;
      Btn.SetBounds(PosX, PosY, Widths[BtnIdx], ButtonHeight);
      Btn.Default := BtnIdx = ADefaultIndex;
      Btn.Cancel := BtnIdx = ACancelIndex;
      if BtnIdx = ADefaultIndex then
        Form.ActiveControl := Btn;
      Inc(PosX, Widths[BtnIdx] + Gap);
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
  Buttons: TMsgDlgButtons; HelpCtx: Longint; PosX, PosY: Integer): Integer;
var
  Def, Cancel: TMsgDlgBtn;
begin
  PickDefaults(Buttons, Def, Cancel);
  Result := RunMessage(Msg, DlgCaption(DlgType), DlgIcon(DlgType), Buttons,
                       Def, Cancel, PosX, PosY);
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

function UiSysMessageBox(AWnd: HWND; const AText, ACaption: string;
  AFlags: UINT): Integer;
{$IFDEF FPC}
var
  WideText, WideCaption: WideString;
{$ENDIF}
begin
  {$IFDEF FPC}
  WideText := UTF8Decode(AText);
  WideCaption := UTF8Decode(ACaption);
  Result := MessageBoxW(AWnd, PWideChar(WideText), PWideChar(WideCaption),
    AFlags);
  {$ELSE}
  Result := MessageBox(AWnd, PChar(AText), PChar(ACaption), AFlags);
  {$ENDIF}
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
  WidthPx, PosY: Integer;
begin
  Result := False;
  Form := NewDialogForm(ACaption);
  Measure := TBitmap.Create;
  try
    Measure.Canvas.Font := Form.Font;
    WidthPx := Measure.Canvas.TextWidth(APrompt) + 2 * Margin;
    if WidthPx < 320 then
      WidthPx := 320;
    Form.ClientWidth := WidthPx;

    PromptLabel := TUiLabel.Create(Form);
    PromptLabel.Parent := Form;
    UseFormFont(PromptLabel, Form);
    PromptLabel.Caption := APrompt;
    PromptLabel.SetBounds(Margin, Margin, WidthPx - 2 * Margin,
                          Measure.Canvas.TextHeight('0'));
    PosY := PromptLabel.Top + PromptLabel.Height + 4;

    Edit := TUiEdit.Create(Form);
    Edit.Parent := Form;
    Edit.SetBounds(Margin, PosY, WidthPx - 2 * Margin, 21);
    Edit.Text := Value;
    Edit.SelectAll;
    Inc(PosY, Edit.Height + Margin);

    BtnCancel := TUiButton.Create(Form);
    BtnCancel.Parent := Form;
    BtnCancel.Caption := SMsgDlgCancel;
    BtnCancel.ModalResult := mrCancel;
    BtnCancel.Cancel := True;
    BtnCancel.SetBounds(WidthPx - Margin - MinButtonWidth, PosY, MinButtonWidth,
                        ButtonHeight);

    BtnOk := TUiButton.Create(Form);
    BtnOk.Parent := Form;
    BtnOk.Caption := SMsgDlgOK;
    BtnOk.ModalResult := mrOk;
    BtnOk.Default := True;
    BtnOk.SetBounds(BtnCancel.Left - Gap - MinButtonWidth, PosY,
                    MinButtonWidth, ButtonHeight);

    Form.ClientHeight := PosY + ButtonHeight + Margin;
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
