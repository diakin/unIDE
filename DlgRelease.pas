unit DlgRelease;

// Build Release: файлы, которые кладутся в папку Release рядом с exe.
//
// Окно описано в DlgRelease.dfm и правится в конструкторе форм. Список
// заполняет по разбору исходников (ReleaseBuild) и выбранное сохраняет в
// описание проекта TForm1.ReleaseFilesDialog (Unit1). Кнопки "Отметить
// все" / "Снять все" работают здесь же, без главного окна.
//
// Форма создаётся по месту, в .dpr её автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, CheckLst,
  UiButton;     // TUiButton

type
  TDlgRelease = class(TForm)
    lblTitle: TLabel;
    lstFiles: TCheckListBox;
    btnMark: TUiButton;
    btnUnmark: TUiButton;
    lblNote: TLabel;
    btnOk: TUiButton;
    btnCancel: TUiButton;
    procedure btnMarkClick(Sender: TObject);
  private
    // $0128 - WM_UPDATEUISTATE, в Messages.pas Delphi 7 этой константы нет
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
  end;

implementation

{$R *.dfm}

// По нажатию Alt Windows меняет режим показа подчёркиваний, и кнопки окна
// пропадают с экрана. Сообщение дальше не передаём: состояние не
// меняется, и перерисовывать нечего.
procedure TDlgRelease.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

// "Отметить все" (Tag = 1) и "Снять все" (Tag = 0) - один обработчик
procedure TDlgRelease.btnMarkClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to lstFiles.Items.Count - 1 do
    lstFiles.Checked[I] := TComponent(Sender).Tag = 1;
end;

end.
