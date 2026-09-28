unit DlgPickFolder;

// Выбор папки: диск, дерево папок, файлы выбранной папки и поле пути.
//
// Окно описано в DlgPickFolder.dfm и правится в конструкторе форм.
// Стартовую папку, обработчики (PickEditChange, PickDirChange,
// PickOkClick) и результат - в TForm1.PickFolderDialog (Unit1). Связка
// диск - папки - файлы задана здесь: cmbDrive.DirList и
// lstDirs.FileList.
//
// Форма создаётся по месту, в .dpr её автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, FileCtrl,
  UiButton,     // TUiButton
  UiEditCtrls;  // TUiEdit

type
  TDlgPickFolder = class(TForm)
    pnlBottom: TPanel;
    lblPath: TLabel;
    edPath: TUiEdit;
    btnOk: TUiButton;
    btnCancel: TUiButton;
    // TDriveComboBox в Delphi 7 не умеет Align - по верху окна его держит
    // панель, а по ширине тянут якоря
    pnlDrive: TPanel;
    cmbDrive: TDriveComboBox;
    lstDirs: TDirectoryListBox;
    splDirs: TSplitter;
    lstFiles: TFileListBox;
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
procedure TDlgPickFolder.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

end.
