unit DlgFifDisk;

// Find In Files на диске: папки (несколько - через ";"), маски файлов,
// вложенные папки. Кнопка "..." - окно Directory Tree: отмеченные в его
// списке папки подставляются все.
//
// Окно описано в DlgFifDisk.dfm и правится в конструкторе форм.
// Значения прошлого поиска подставляет и результат забирает
// TForm1.FifDiskDialog (Unit1). Кнопка "..." закрывает окно с mrRetry:
// папка выбирается после закрытия, и окно показывается снова.
//
// Форма создаётся по месту, в .dpr её автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls,
  UiButton,     // TUiButton
  UiStdCtrls,   // TUiCheckBox
  UiEditCtrls;  // TUiEdit

type
  TDlgFifDisk = class(TForm)
    lblDir: TLabel;
    edDir: TUiEdit;
    btnBrowse: TUiButton;
    lblMask: TLabel;
    edMask: TUiEdit;
    chkSub: TUiCheckBox;
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
procedure TDlgFifDisk.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

end.
