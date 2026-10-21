unit DlgTidyIni;

// Tidy editor.ini: поиск проектов в папке и разбор editor.ini.
//
// Слева - диск и дерево папок, под ними путь и кнопка Scan: в выбранной
// папке и подпапках ищутся editor*.ini и *.prj (TidyScanProjects,
// IniTidy). Справа - найденные проекты, которых в editor.ini нет; Add to
// editor.ini переносит отмеченные. Tidy and restart - разбор editor.ini
// и перезапуск unIDE (TForm1.TidyRun).
//
// Окно описано в DlgTidyIni.dfm и правится в конструкторе форм.
// Обработчики, список найденного и результат - в TForm1.TidyIniClick
// (Unit1). Связка диск - папки задана здесь: cmbDrive.DirList.
//
// Форма создаётся по месту, в .dpr её автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, FileCtrl, CheckLst,
  UiButton,     // TUiButton
  UiEditCtrls;  // TUiEdit

type
  TDlgTidyIni = class(TForm)
    pnlTop: TPanel;
    lblInfo: TLabel;
    pnlDirs: TPanel;
    // TDriveComboBox в Delphi 7 не умеет Align - по верху его держит
    // панель, а по ширине тянут якоря
    pnlDrive: TPanel;
    cmbDrive: TDriveComboBox;
    lstDirs: TDirectoryListBox;
    pnlScan: TPanel;
    edPath: TUiEdit;
    btnScan: TUiButton;
    splDirs: TSplitter;
    pnlFound: TPanel;
    lblFound: TLabel;
    lstFound: TCheckListBox;
    pnlFoundBtns: TPanel;
    btnMark: TUiButton;
    btnUnmark: TUiButton;
    lblScan: TLabel;
    pnlBottom: TPanel;
    btnAdd: TUiButton;
    btnTidy: TUiButton;
    btnClose: TUiButton;
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
procedure TDlgTidyIni.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

end.
