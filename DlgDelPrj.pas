unit DlgDelPrj;

// Delete Projects: список проектов с галками, что удалять - только
// описание или папку целиком.
//
// Окно описано в DlgDelPrj.dfm и правится в конструкторе форм.
// Список заполняет, отмеченное удаляет и обработчики назначает
// TForm1.DeleteProjectClick (Unit1). Обработчики DelPrjCheckAll и
// DelPrjClickCheck находят список и кнопку "Удалить" по именам
// lstDelPrj и btnDelPrj - при переименовании поправить и их.
//
// Форма создаётся по месту, в .dpr её автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, CheckLst,
  UiButton,     // TUiButton
  UiStdCtrls;   // TUiRadioButton

type
  TDlgDelPrj = class(TForm)
    lblTitle: TLabel;
    lstDelPrj: TCheckListBox;
    btnMark: TUiButton;
    btnUnmark: TUiButton;
    rbPrj: TUiRadioButton;
    rbAll: TUiRadioButton;
    lblNote: TLabel;
    btnDelPrj: TUiButton;
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
procedure TDlgDelPrj.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

end.
