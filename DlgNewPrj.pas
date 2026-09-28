unit DlgNewPrj;

// New Project: имя, папка, "на базе существующего", тип проекта.
//
// Окно описано в DlgNewPrj.dfm и правится в конструкторе форм.
// Обработчики полей (NewPrjNameChange, NewPrjDirChange,
// NewPrjOnBaseClick), подсказку папки и само создание проекта ведёт
// TForm1.NewProjectClick (Unit1). Кнопка "..." закрывает окно с
// mrRetry: папка выбирается после закрытия, и окно показывается снова.
// Порядок типов в cbType важен только для пункта по умолчанию - его
// ставит код (ItemIndex := 0).
//
// Форма создаётся по месту, в .dpr её автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls,
  UiButton,     // TUiButton
  UiStdCtrls,   // TUiCheckBox
  UiEditCtrls;  // TUiEdit, TUiComboBox

type
  TDlgNewPrj = class(TForm)
    lblName: TLabel;
    edName: TUiEdit;
    lblDir: TLabel;
    edDir: TUiEdit;
    btnBrowse: TUiButton;
    chkBase: TUiCheckBox;
    lblType: TLabel;
    cbType: TUiComboBox;
    btnOk: TUiButton;
    btnCancel: TUiButton;
  private
    // $0128 - WM_UPDATEUISTATE, в Messages.pas Delphi 7 этой константы нет
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
  end;

implementation

{$R *.dfm}

// По нажатию Alt Windows меняет режим показа подчёркиваний, и кнопки окна
// пропадают с экрана - та же беда, что у главного окна (см.
// TForm1.WMUpdateUIState). Сообщение дальше не передаём: состояние не
// меняется, и перерисовывать нечего.
procedure TDlgNewPrj.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

end.
