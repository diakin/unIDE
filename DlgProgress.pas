unit DlgProgress;

// Ход долгой операции (замена по всему файлу, Find In Files по проекту и
// на диске): подпись этапа до трёх строк, полоса и кнопка "Стоп".
//
// Окно описано в DlgProgress.dfm и правится в конструкторе форм.
// Окно создаётся один раз и дальше только показывается и прячется - см.
// TForm1.ProgressStart, ProgressStep, ProgressStop (Unit1). Обработчик
// кнопки (ProgAbortClick) назначает ProgressStart. Крестика у окна нет:
// выход только через "Стоп", иначе окно можно закрыть, а цикл
// продолжит работать вслепую.
//
// Форма создаётся по месту, в .dpr её автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ComCtrls,
  UiButton;     // TUiButton

type
  TDlgProgress = class(TForm)
    lblStage: TLabel;
    barProgress: TProgressBar;
    btnStop: TUiButton;
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
procedure TDlgProgress.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

end.
