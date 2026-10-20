unit DlgHotFolders;

// Directory Tree: папки для поиска потерянных файлов - дерево папок
// слева, отмеченный список справа.
//
// Окно описано в DlgHotFolders.dfm и правится в конструкторе форм.
// Заполнение, обработчики (HfAddClick, HfDelClick, HfTreeExpanding,
// HfTreeChange, HfTreeDblClick) и сохранение списка - в
// TForm1.ShowHotFolders (Unit1).
//
// Форма создаётся по месту, в .dpr её автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, ComCtrls, CheckLst,
  UiButton,     // TUiButton
  UiEditCtrls,  // TUiEdit
  UiComCtrls;   // TUiTreeView

type
  TDlgHotFolders = class(TForm)
    pnlBottom: TPanel;
    btnOk: TUiButton;
    btnCancel: TUiButton;
    pnlTop: TPanel;
    btnAdd: TUiButton;
    btnDel: TUiButton;
    lblNote: TLabel;
    pnlPath: TPanel;
    edPath: TUiEdit;
    tvFolders: TUiTreeView;
    splFolders: TSplitter;
    lstFolders: TCheckListBox;
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
procedure TDlgHotFolders.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

end.
