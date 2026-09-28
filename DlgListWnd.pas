unit DlgListWnd;

// Окно со списком модулей и форм проекта (View Unit и View Form -
// одно окно).
//
// Окно описано в DlgListWnd.dfm и правится в конструкторе форм.
// Колонки, заголовок и обработчики списка (ProjectListSelect,
// ProjectListDblClick) выставляет TForm1.MakeListWindow, строки
// заполняет TForm1.FillModuleList (Unit1).
//
// Форма создаётся по месту, в .dpr её автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ComCtrls,
  UiComCtrls;   // TUiListView

type
  TDlgListWnd = class(TForm)
    lvList: TUiListView;
    lblPath: TLabel;
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
procedure TDlgListWnd.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

end.
