unit DlgEnvVar;

// Имя и значение переменной среды: подмена системной переменной и своя
// переменная (вкладка Environment Variables окна IDE Options).
//
// Окно описано в DlgEnvVar.dfm и правится в конструкторе форм. Заголовок,
// значения полей и запрет правки имени выставляет TForm2.EnvEditDialog
// (Unit2), она же проверяет и забирает введённое.
//
// Форма создаётся по месту, в .dpr её автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls,
  UiButton,     // TUiButton
  UiEditCtrls;  // TUiEdit

type
  TDlgEnvVar = class(TForm)
    lblName: TLabel;
    lblValue: TLabel;
    edName: TUiEdit;
    edValue: TUiEdit;
    btnOk: TUiButton;
    btnCancel: TUiButton;
  private
    // $0128 - WM_UPDATEUISTATE, в Messages.pas Delphi 7 этой константы нет
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
  end;

implementation

{$R *.dfm}

// По нажатию Alt Windows меняет режим показа подчёркиваний, и кнопки окна
// пропадают с экрана (см. TForm1.WMUpdateUIState). Сообщение дальше не
// передаём: состояние не меняется, и перерисовывать нечего.
procedure TDlgEnvVar.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

end.
