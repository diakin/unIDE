unit DlgUnusedPick;

// Move Unused Files: весь список файлов, не нужных для сборки, с галками -
// в несколько столбцов. Отмеченные переносятся, снятые остаются на месте.
// Галки по умолчанию - у всех, кроме AKeep (документы, файлы с именем
// проекта: exe, manifest, build.txt, _compile.bat/.log - их выбирает
// Unit1). Окно строится кодом, без .dfm.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, StdCtrls,
  CheckLst,
  UiButton, UiStdCtrls, UiTheme;

// AFiles - пути относительно папки проекта; AKeep - те из них, у которых
// галки по умолчанию нет. APicked - отмеченные после OK. False - отказ.
function UnusedFilesDialog(const ACaption, APrompt: string;
  AFiles, AKeep, APicked: TStrings): Boolean;

implementation

type
  // Обработчики окна: событиям VCL нужен метод объекта
  TUnusedPickHelper = class
  public
    List: TCheckListBox;
    CountLabel: TLabel;
    procedure UpdateCount;
    procedure ListClickCheck(Sender: TObject);
    procedure CheckAllClick(Sender: TObject);
    procedure UncheckAllClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
  end;

const
  ListColumns = 3;
  MarginSize = 12;
  ButtonHeight = 25;

procedure TUnusedPickHelper.UpdateCount;
var
  ItemIdx, CheckedCount: Integer;
begin
  CheckedCount := 0;
  for ItemIdx := 0 to List.Items.Count - 1 do
    if List.Checked[ItemIdx] then
      Inc(CheckedCount);
  CountLabel.Caption := 'Отмечено (будут перенесены): ' +
    IntToStr(CheckedCount) + ' из ' + IntToStr(List.Items.Count);
end;

procedure TUnusedPickHelper.ListClickCheck(Sender: TObject);
begin
  UpdateCount;
end;

procedure TUnusedPickHelper.CheckAllClick(Sender: TObject);
var
  ItemIdx: Integer;
begin
  for ItemIdx := 0 to List.Items.Count - 1 do
    List.Checked[ItemIdx] := True;
  UpdateCount;
end;

procedure TUnusedPickHelper.UncheckAllClick(Sender: TObject);
var
  ItemIdx: Integer;
begin
  for ItemIdx := 0 to List.Items.Count - 1 do
    List.Checked[ItemIdx] := False;
  UpdateCount;
end;

// Ширина столбца - по ширине списка: столбцов всегда ListColumns. Columns
// заново не ставится: свойство с тем же значением ничего не делает
procedure TUnusedPickHelper.FormResize(Sender: TObject);
begin
  {$IFNDEF FPC}
  if List.HandleAllocated then
    SendMessage(List.Handle, LB_SETCOLUMNWIDTH,
      List.ClientWidth div ListColumns, 0);
  {$ENDIF}
end;

function UnusedFilesDialog(const ACaption, APrompt: string;
  AFiles, AKeep, APicked: TStrings): Boolean;
var
  Form: TForm;
  Helper: TUnusedPickHelper;
  PromptLabel: TLabel;
  BtnOk, BtnCancel, BtnAll, BtnNone: TUiButton;
  ItemIdx, ItemIndexAdded: Integer;
begin
  Result := False;
  APicked.Clear;
  Helper := TUnusedPickHelper.Create;
  Form := TForm.CreateNew(Application);
  try
    Form.Caption := ACaption;
    Form.BorderStyle := bsSizeable;
    Form.BorderIcons := [biSystemMenu, biMaximize];
    Form.Position := poScreenCenter;
    if Application.MainForm <> nil then
      Form.Font := Application.MainForm.Font;
    Form.Color := UiThemeColor('Window.BG');
    Form.Font.Color := UiThemeColor('Window.Text');
    Form.ClientWidth := 900;
    Form.ClientHeight := 560;
    Form.Constraints.MinWidth := 480;
    Form.Constraints.MinHeight := 300;

    PromptLabel := TLabel.Create(Form);
    PromptLabel.Parent := Form;
    PromptLabel.AutoSize := False;
    PromptLabel.WordWrap := True;
    PromptLabel.SetBounds(MarginSize, 8, Form.ClientWidth - 2 * MarginSize, 44);
    PromptLabel.Anchors := [akLeft, akTop, akRight];
    PromptLabel.Caption := APrompt;

    Helper.List := TCheckListBox.Create(Form);
    Helper.List.Parent := Form;
    Helper.List.SetBounds(MarginSize, 56, Form.ClientWidth - 2 * MarginSize,
      Form.ClientHeight - 56 - ButtonHeight - 2 * MarginSize);
    Helper.List.Anchors := [akLeft, akTop, akRight, akBottom];
    Helper.List.Color := UiThemeColor('List.BG');
    Helper.List.Font.Color := UiThemeColor('List.Text');
    Helper.List.Columns := ListColumns;
    Helper.List.OnClickCheck := Helper.ListClickCheck;
    Helper.List.Items.BeginUpdate;
    try
      for ItemIdx := 0 to AFiles.Count - 1 do
      begin
        ItemIndexAdded := Helper.List.Items.Add(AFiles[ItemIdx]);
        Helper.List.Checked[ItemIndexAdded] :=
          AKeep.IndexOf(AFiles[ItemIdx]) < 0;
      end;
    finally
      Helper.List.Items.EndUpdate;
    end;

    BtnAll := TUiButton.Create(Form);
    BtnAll.Parent := Form;
    BtnAll.Caption := 'Отметить все';
    BtnAll.SetBounds(MarginSize, Form.ClientHeight - MarginSize - ButtonHeight,
      100, ButtonHeight);
    BtnAll.Anchors := [akLeft, akBottom];
    BtnAll.OnClick := Helper.CheckAllClick;

    BtnNone := TUiButton.Create(Form);
    BtnNone.Parent := Form;
    BtnNone.Caption := 'Снять все';
    BtnNone.SetBounds(BtnAll.Left + BtnAll.Width + 8, BtnAll.Top, 100,
      ButtonHeight);
    BtnNone.Anchors := [akLeft, akBottom];
    BtnNone.OnClick := Helper.UncheckAllClick;

    Helper.CountLabel := TLabel.Create(Form);
    Helper.CountLabel.Parent := Form;
    Helper.CountLabel.AutoSize := True;
    Helper.CountLabel.Left := BtnNone.Left + BtnNone.Width + 16;
    Helper.CountLabel.Top := BtnAll.Top + 6;
    Helper.CountLabel.Anchors := [akLeft, akBottom];

    BtnCancel := TUiButton.Create(Form);
    BtnCancel.Parent := Form;
    BtnCancel.Caption := 'Отмена';
    BtnCancel.Cancel := True;
    BtnCancel.ModalResult := mrCancel;
    BtnCancel.SetBounds(Form.ClientWidth - MarginSize - 90, BtnAll.Top, 90,
      ButtonHeight);
    BtnCancel.Anchors := [akRight, akBottom];

    BtnOk := TUiButton.Create(Form);
    BtnOk.Parent := Form;
    BtnOk.Caption := 'Перенести';
    BtnOk.Default := True;
    BtnOk.ModalResult := mrOk;
    BtnOk.SetBounds(BtnCancel.Left - 8 - 90, BtnAll.Top, 90, ButtonHeight);
    BtnOk.Anchors := [akRight, akBottom];

    Form.OnResize := Helper.FormResize;
    Helper.UpdateCount;
    Form.ActiveControl := Helper.List;
    if Form.ShowModal <> mrOk then
      Exit;
    for ItemIdx := 0 to Helper.List.Items.Count - 1 do
      if Helper.List.Checked[ItemIdx] then
        APicked.Add(Helper.List.Items[ItemIdx]);
    Result := True;
  finally
    Form.Free;
    Helper.Free;
  end;
end;

end.
