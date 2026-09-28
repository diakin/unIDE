unit DlgChooseList;

// Выбор одной строки из списка: проект нужного типа, место создания
// компонента, компилятор Delphi.
//
// Окно описано в DlgChooseList.dfm и правится в конструкторе форм.
// Заголовок, подпись и пункты выставляет TForm1.ChooseFromList (Unit1),
// она же забирает выбранную строку.
//
// Форма создаётся по месту, в .dpr её автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls,
  UiButton,     // TUiButton
  UiEditCtrls;  // TUiListBox

type
  TDlgChooseList = class(TForm)
    lblPrompt: TLabel;
    lstItems: TUiListBox;
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
procedure TDlgChooseList.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

end.
