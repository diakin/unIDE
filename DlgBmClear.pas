unit DlgBmClear;

// Clear List в меню Bookmarks: закладки окна списком с галками, удаляются
// только отмеченные. Кнопки: отметить все, снять все, отметить
// несуществующие (строки закладки в файле нет).
//
// То же окно - для Hot Bookmarks - «Закрепить...» (HotBmPinClick): там
// отметки - закреплённые, кнопка - OK, пустой выбор допустим (AllowNone).
//
// Окно описано в DlgBmClear.dfm и правится в конструкторе форм. Список
// заполняет и отмеченное удаляет TForm1.BmClearClick (Unit1); отметки по
// кнопкам - здесь. Несуществующие закладки - пункты с Objects <> nil.
//
// Форма создаётся по месту, в .dpr её автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, CheckLst,
  UiButton;     // TUiButton

type
  TDlgBmClear = class(TForm)
    lblTitle: TLabel;
    lstBm: TCheckListBox;
    btnMark: TUiButton;
    btnUnmark: TUiButton;
    btnMarkMissing: TUiButton;
    lblCount: TLabel;
    btnDelete: TUiButton;
    btnCancel: TUiButton;
    procedure btnMarkClick(Sender: TObject);
    procedure btnUnmarkClick(Sender: TObject);
    procedure btnMarkMissingClick(Sender: TObject);
    procedure lstBmClickCheck(Sender: TObject);
  private
    FAllowNone: Boolean;
    // $0128 - WM_UPDATEUISTATE, в Messages.pas Delphi 7 этой константы нет
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
  public
    // Число отметок - в подпись и в доступность кнопки удаления
    procedure UpdateCount;
    // Кнопка подтверждения доступна и без отметок
    property AllowNone: Boolean read FAllowNone write FAllowNone;
  end;

implementation

{$R *.dfm}

procedure TDlgBmClear.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

procedure TDlgBmClear.UpdateCount;
var
  ItemIdx, Marked: Integer;
begin
  Marked := 0;
  for ItemIdx := 0 to lstBm.Items.Count - 1 do
    if lstBm.Checked[ItemIdx] then
      Inc(Marked);
  lblCount.Caption := 'Отмечено: ' + IntToStr(Marked) + ' из ' +
                      IntToStr(lstBm.Items.Count);
  btnDelete.Enabled := (Marked > 0) or FAllowNone;
end;

procedure TDlgBmClear.btnMarkClick(Sender: TObject);
var
  ItemIdx: Integer;
begin
  for ItemIdx := 0 to lstBm.Items.Count - 1 do
    lstBm.Checked[ItemIdx] := True;
  UpdateCount;
end;

procedure TDlgBmClear.btnUnmarkClick(Sender: TObject);
var
  ItemIdx: Integer;
begin
  for ItemIdx := 0 to lstBm.Items.Count - 1 do
    lstBm.Checked[ItemIdx] := False;
  UpdateCount;
end;

// Отмечены только закладки, строки которых в файле нет
procedure TDlgBmClear.btnMarkMissingClick(Sender: TObject);
var
  ItemIdx: Integer;
begin
  for ItemIdx := 0 to lstBm.Items.Count - 1 do
    lstBm.Checked[ItemIdx] := lstBm.Items.Objects[ItemIdx] <> nil;
  UpdateCount;
end;

procedure TDlgBmClear.lstBmClickCheck(Sender: TObject);
begin
  UpdateCount;
end;

end.
