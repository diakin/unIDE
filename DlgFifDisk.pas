unit DlgFifDisk;

// Find In Files - окно поиска в файлах проекта и на диске. Немодальное:
// пока идёт поиск, найденное сразу появляется в Match list, и с ним можно
// работать; кнопка "Найти" на время поиска становится "Стоп".
//
// Папки (несколько - через ";", только для поиска на диске), список
// расширений с галками, другие маски, вложенные папки, строка хода
// поиска. Кнопка "..." - окно Directory Tree: отмеченные в его списке
// папки подставляются все.
//
// Окно описано в DlgFifDisk.dfm и правится в конструкторе форм.
// Значения подставляет, поиск ведёт и обработчики кнопок назначает
// TForm1 (Unit1: FifShowWindow, FifRun). Окно создаётся один раз и
// дальше только показывается и прячется; в .dpr его автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, CheckLst,
  UiButton,     // TUiButton
  UiStdCtrls,   // TUiCheckBox
  UiEditCtrls;  // TUiEdit

type
  TDlgFifDisk = class(TForm)
    lblDir: TLabel;
    edDir: TUiEdit;
    btnBrowse: TUiButton;
    lblExt: TLabel;
    lstExt: TCheckListBox;
    btnExtAll: TUiButton;
    btnExtNone: TUiButton;
    lblMask: TLabel;
    edMask: TUiEdit;
    chkSub: TUiCheckBox;
    lblStatus: TLabel;
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
