unit DlgWinList;

// Del WinList: открытые окна с галками - какие закрыть. Без заголовка и
// рамки: читается как раскрытое меню Windows, под которым и встаёт.
//
// Окно описано в DlgWinList.dfm и правится в конструкторе форм.
// Список, размер окна (по самому длинному пути и числу строк), ширины
// кнопок (по подписям), место на экране и обработчики (DlgCheckAllClick,
// DlgDeactivate) - в TForm1.DelWinListClick (Unit1). Размеры здесь -
// начальные, код их пересчитывает.
//
// Форма создаётся по месту, в .dpr её автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, CheckLst,
  UiButton;     // TUiButton

type
  TDlgWinList = class(TForm)
    pnlRoot: TPanel;
    pnlCaption: TPanel;
    pnlButtons: TPanel;
    btnAll: TUiButton;
    btnOk: TUiButton;
    btnCancel: TUiButton;
    lstWindows: TCheckListBox;
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
procedure TDlgWinList.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

end.
