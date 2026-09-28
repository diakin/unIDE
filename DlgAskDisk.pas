unit DlgAskDisk;

// Вопрос по файлу, который изменила на диске другая программа: перечитать,
// слить, открыть версию с диска в новой вкладке или оставить текст окна.
//
// Окно описано в DlgAskDisk.dfm и правится в конструкторе форм. Текст
// вопроса, видимость галки, доступность "Слить" и кнопку по умолчанию
// выставляет TForm1.AskDiskChange (Unit1), она же разбирает ответ по
// ModalResult кнопок:
//   btnReload - mrYes, btnMerge - mrAll, btnNewTab - mrRetry, btnKeep - mrNo.
//
// Форма создаётся на время вопроса, в .dpr её автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls,
  UiButton,    // TUiButton
  UiStdCtrls;  // TUiCheckBox

type
  TDlgAskDisk = class(TForm)
    lblInfo: TLabel;
    chkSame: TUiCheckBox;
    btnReload: TUiButton;
    btnMerge: TUiButton;
    btnNewTab: TUiButton;
    btnKeep: TUiButton;
  private
    // $0128 - WM_UPDATEUISTATE, в Messages.pas Delphi 7 этой константы нет
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
  end;

implementation

{$R *.dfm}

// По нажатию Alt Windows меняет режим показа подчёркиваний, и кнопки окна
// пропадают с экрана - та же беда, что у главного окна (см.
// TForm1.WMUpdateUIState). Сообщение дальше не передаём: состояние не
// меняется, и перерисовывать нечего. Окнам, собранным в коде, то же
// самое делает TAltFix в Unit1.
procedure TDlgAskDisk.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

end.
