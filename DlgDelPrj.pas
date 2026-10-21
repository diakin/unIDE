unit DlgDelPrj;

// Delete Projects: список проектов с галками, что удалять - только
// описание или папку целиком.
//
// Окно описано в DlgDelPrj.dfm и правится в конструкторе форм.
// Список заполняет, отмеченное удаляет и обработчики назначает
// TForm1.DeleteProjectClick (Unit1). Обработчики DelPrjCheckAll и
// DelPrjClickCheck находят список и кнопку "Удалить" по именам
// lstDelPrj и btnDelPrj - при переименовании поправить и их.
//
// Форма создаётся по месту, в .dpr её автосоздания нет.
//
// Размер окна меняется мышью (длинные пути к папкам проектов); положение
// и размер хранятся в editor.ini, раздел [DelPrjWindow] (LoadPlacement,
// SavePlacement). Список с горизонтальной прокруткой по самой длинной
// строке (FitScrollWidth).

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, CheckLst, IniFiles,
  UiButton,     // TUiButton
  UiStdCtrls;   // TUiRadioButton

type
  TDlgDelPrj = class(TForm)
    lblTitle: TLabel;
    lstDelPrj: TCheckListBox;
    btnMark: TUiButton;
    btnUnmark: TUiButton;
    rbPrj: TUiRadioButton;
    rbAll: TUiRadioButton;
    lblNote: TLabel;
    btnDelPrj: TUiButton;
    btnCancel: TUiButton;
  private
    // $0128 - WM_UPDATEUISTATE, в Messages.pas Delphi 7 этой константы нет
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
  public
    // Положение и размер окна - из AIniFile / в AIniFile (editor.ini)
    procedure LoadPlacement(const AIniFile: string);
    procedure SavePlacement(const AIniFile: string);
    // Ширина прокрутки списка - по самой длинной строке
    procedure FitScrollWidth;
  end;

implementation

{$R *.dfm}

// По нажатию Alt Windows меняет режим показа подчёркиваний, и кнопки окна
// пропадают с экрана - та же беда, что у главного окна (см.
// TForm1.WMUpdateUIState). Сообщение дальше не передаём: состояние не
// меняется, и перерисовывать нечего.
procedure TDlgDelPrj.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

const
  PlacementSection = 'DelPrjWindow';

procedure TDlgDelPrj.LoadPlacement(const AIniFile: string);
var
  Ini: TIniFile;
  WinLeft, WinTop, WinWidth, WinHeight: Integer;
  Work: TRect;
begin
  if (AIniFile = '') or not FileExists(AIniFile) then
    Exit;
  Ini := TIniFile.Create(AIniFile);
  try
    WinLeft := Ini.ReadInteger(PlacementSection, 'Left', MaxInt);
    WinTop := Ini.ReadInteger(PlacementSection, 'Top', MaxInt);
    WinWidth := Ini.ReadInteger(PlacementSection, 'Width', Width);
    WinHeight := Ini.ReadInteger(PlacementSection, 'Height', Height);
    if (WinLeft <> MaxInt) and (WinTop <> MaxInt) then
    begin
      // Окно - целиком на рабочем столе (монитор могли отключить)
      Work := Screen.DesktopRect;
      if WinWidth > Work.Right - Work.Left then
        WinWidth := Work.Right - Work.Left;
      if WinHeight > Work.Bottom - Work.Top then
        WinHeight := Work.Bottom - Work.Top;
      if WinLeft + WinWidth > Work.Right then
        WinLeft := Work.Right - WinWidth;
      if WinTop + WinHeight > Work.Bottom then
        WinTop := Work.Bottom - WinHeight;
      if WinLeft < Work.Left then
        WinLeft := Work.Left;
      if WinTop < Work.Top then
        WinTop := Work.Top;
      Position := poDesigned;
      SetBounds(WinLeft, WinTop, WinWidth, WinHeight);
    end;
    if Ini.ReadBool(PlacementSection, 'Maximized', False) then
      WindowState := wsMaximized;
  finally
    Ini.Free;
  end;
end;

procedure TDlgDelPrj.SavePlacement(const AIniFile: string);
var
  Ini: TIniFile;
  Place: TWindowPlacement;
begin
  if AIniFile = '' then
    Exit;
  // Размер "в обычном виде", и когда окно развёрнуто
  Place.length := SizeOf(Place);
  if not GetWindowPlacement(Handle, @Place) then
    Exit;
  Ini := TIniFile.Create(AIniFile);
  try
    Ini.WriteInteger(PlacementSection, 'Left', Place.rcNormalPosition.Left);
    Ini.WriteInteger(PlacementSection, 'Top', Place.rcNormalPosition.Top);
    Ini.WriteInteger(PlacementSection, 'Width',
                     Place.rcNormalPosition.Right - Place.rcNormalPosition.Left);
    Ini.WriteInteger(PlacementSection, 'Height',
                     Place.rcNormalPosition.Bottom - Place.rcNormalPosition.Top);
    Ini.WriteBool(PlacementSection, 'Maximized', WindowState = wsMaximized);
  finally
    Ini.Free;
  end;
end;

// Запас справа - на галку слева от текста и поля
procedure TDlgDelPrj.FitScrollWidth;
var
  ItemIdx, TextWidth, MaxWidth: Integer;
begin
  MaxWidth := 0;
  lstDelPrj.Canvas.Font := lstDelPrj.Font;
  for ItemIdx := 0 to lstDelPrj.Items.Count - 1 do
  begin
    TextWidth := lstDelPrj.Canvas.TextWidth(lstDelPrj.Items[ItemIdx]);
    if TextWidth > MaxWidth then
      MaxWidth := TextWidth;
  end;
  lstDelPrj.ScrollWidth := MaxWidth + 40;
end;

end.
