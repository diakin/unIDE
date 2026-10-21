unit DlgWatch;

// Окно Watch: выражения отладчика и их значения на остановке, как Watch
// List в Delphi. Ctrl+F5 в редакторе добавляет сюда имя под кареткой.
//
// Окно описано в DlgWatch.dfm и правится в конструкторе форм. Список
// выражений, вычисление (DbgSymbols) и обработчики пунктов меню - в
// TForm1 (Unit1, раздел "Окно Watch"): окно только показывает.
//
// Форма создаётся по месту, в .dpr её автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ComCtrls, Menus,
  UiComCtrls,   // TUiListView
  UiMenus;      // TUiPopupMenu

type
  TDlgWatch = class(TForm)
    lvWatch: TUiListView;
    lblWhere: TLabel;
    pmWatch: TUiPopupMenu;
    miWatchAdd: TMenuItem;
    miWatchEdit: TMenuItem;
    // Условие строки (=10, <5): точки останова RapidQ стоят, только если
    // оно выполнено
    miWatchCond: TMenuItem;
    miWatchDelete: TMenuItem;
    miWatchDeleteAll: TMenuItem;
    miWatchSep: TMenuItem;
    miWatchLocals: TMenuItem;
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
procedure TDlgWatch.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

end.
