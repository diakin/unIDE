unit DlgMatchList;

// Match list: результаты поиска по файлу - строка, текст, число
// вхождений; внизу галка "Disable comments". Поверх главного окна.
//
// Окно описано в DlgMatchList.dfm и правится в конструкторе форм.
// Окно создаётся один раз (TForm1.EnsureMatchForm, Unit1), дальше только
// показывается и прячется. Отрисовку грида, щелчки, ширины колонок и
// место на экране ведёт Unit1: ширина окна и высота строки там -
// константы MatchFormWidth и MatchRowHeight, по ним же считаются
// колонки, поэтому код выставляет их заново.
//
// Форма создаётся по месту, в .dpr её автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, Grids,
  UiStdCtrls;   // TUiCheckBox

type
  TDlgMatchList = class(TForm)
    grdMatches: TStringGrid;
    pnlBottom: TPanel;
    chkDisableRem: TUiCheckBox;
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
procedure TDlgMatchList.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

end.
