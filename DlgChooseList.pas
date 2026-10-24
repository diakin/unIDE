unit DlgChooseList;

// Выбор одной строки из списка: проект нужного типа, место создания
// компонента, компилятор Delphi.
//
// Окно описано в DlgChooseList.dfm и правится в конструкторе форм.
// Заголовок, подпись и пункты выставляет TForm1.ChooseFromList (Unit1),
// она же забирает выбранную строку.
//
// Форма создаётся по месту, в .dpr её автосоздания нет.
//
// HelpText не пуст - слева внизу кнопка Help (создаётся кодом, SetHelp):
// окно со справкой - многострочное поле только для чтения.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls,
  UiButton,     // TUiButton
  UiEditCtrls;  // TUiListBox, TUiMemo

type
  TDlgChooseList = class(TForm)
    lblPrompt: TLabel;
    lstItems: TUiListBox;
    btnOk: TUiButton;
    btnCancel: TUiButton;
  private
    FHelpText: string;
    FBtnHelp: TUiButton;
    procedure BtnHelpClick(Sender: TObject);
    // $0128 - WM_UPDATEUISTATE, в Messages.pas Delphi 7 этой константы нет
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
  public
    // Справка: не пусто - кнопка Help слева внизу (место - по btnOk)
    procedure SetHelp(const AText: string);
  end;

implementation

{$R *.dfm}

// По нажатию Alt Windows меняет режим показа подчёркиваний, и кнопки окна
// пропадают с экрана - та же беда, что у главного окна (см.
// TForm1.WMUpdateUIState). Сообщение дальше не передаём: состояние не
// меняется, и перерисовывать нечего.
procedure TDlgChooseList.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

procedure TDlgChooseList.SetHelp(const AText: string);
begin
  FHelpText := AText;
  if AText = '' then
  begin
    if FBtnHelp <> nil then
      FBtnHelp.Visible := False;
    Exit;
  end;
  if FBtnHelp = nil then
  begin
    FBtnHelp := TUiButton.Create(Self);
    FBtnHelp.Parent := Self;
    FBtnHelp.Caption := 'Help';
    FBtnHelp.OnClick := BtnHelpClick;
  end;
  FBtnHelp.Visible := True;
  FBtnHelp.SetBounds(lstItems.Left, btnOk.Top, 84, btnOk.Height);
end;

// Справка - окно с полем только для чтения (текст длинный, MessageBox
// его не вместит)
procedure TDlgChooseList.BtnHelpClick(Sender: TObject);
var
  HelpForm: TForm;
  HelpMemo: TUiMemo;
  BtnClose: TUiButton;
begin
  HelpForm := TForm.CreateNew(Self);
  try
    HelpForm.Caption := Caption + ' - справка';
    HelpForm.Position := poOwnerFormCenter;
    HelpForm.BorderStyle := bsSizeable;
    HelpForm.BorderIcons := [biSystemMenu, biMaximize];
    HelpForm.ClientWidth := 640;
    HelpForm.ClientHeight := 460;
    HelpForm.Font.Assign(Font);

    BtnClose := TUiButton.Create(HelpForm);
    BtnClose.Parent := HelpForm;
    BtnClose.Caption := 'OK';
    BtnClose.Default := True;
    BtnClose.Cancel := True;
    BtnClose.ModalResult := mrOk;
    BtnClose.SetBounds(HelpForm.ClientWidth - 96, HelpForm.ClientHeight - 36,
      84, 26);
    BtnClose.Anchors := [akRight, akBottom];

    HelpMemo := TUiMemo.Create(HelpForm);
    HelpMemo.Parent := HelpForm;
    HelpMemo.SetBounds(12, 12, HelpForm.ClientWidth - 24,
      HelpForm.ClientHeight - 60);
    HelpMemo.Anchors := [akLeft, akTop, akRight, akBottom];
    HelpMemo.ReadOnly := True;
    HelpMemo.WordWrap := True;
    HelpMemo.ScrollBars := ssVertical;
    HelpMemo.Lines.Text := FHelpText;

    HelpForm.ActiveControl := BtnClose;
    HelpForm.ShowModal;
  finally
    HelpForm.Free;
  end;
end;

end.
