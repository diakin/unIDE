unit DlgWinList;

// Del WinList: открытые окна с галками - какие закрыть. Без заголовка и
// рамки Windows: читается как раскрытое меню Windows, под которым и встаёт.
//
// Окно описано в DlgWinList.dfm и правится в конструкторе форм.
// Список, начальный размер окна (по самому длинному пути и числу строк),
// ширины кнопок (по подписям), место на экране и обработчики
// (DlgCheckAllClick, DlgDeactivate) - в TForm1.DelWinListClick (Unit1).
// Размеры в .dfm - начальные, код их пересчитывает.
//
// Кнопки - вверху, над списком. Размер окна меняется мышью за края и углы
// (рамка pnlRoot), окно переносится за полосу заголовка pnlCaption. Своей
// рамки у окна нет (bsNone), поэтому и то и другое сделано здесь, на
// мышиных событиях панелей - одинаково для Delphi 7 и Lazarus (win32, gtk2).
//
// Форма создаётся по месту, в .dpr её автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, CheckLst,
  UiButton;     // TUiButton

type
  // Какой край (или угол) окна тянем мышью; wleMove - переносим окно
  TWinListEdge = (wleNone, wleLeft, wleRight, wleTop, wleBottom,
    wleTopLeft, wleTopRight, wleBottomLeft, wleBottomRight, wleMove);

  TDlgWinList = class(TForm)
    pnlRoot: TPanel;
    pnlCaption: TPanel;
    pnlButtons: TPanel;
    btnAll: TUiButton;
    btnOk: TUiButton;
    btnCancel: TUiButton;
    lstWindows: TCheckListBox;
  private
    FDragEdge: TWinListEdge;     // что тянем сейчас; wleNone - не тянем
    FDragStart: TPoint;          // точка нажатия, экранные координаты
    FDragBounds: TRect;          // границы окна в момент нажатия
    function EdgeAt(PosX, PosY: Integer): TWinListEdge;
    procedure RootMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; PosX, PosY: Integer);
    procedure RootMouseMove(Sender: TObject; Shift: TShiftState;
      PosX, PosY: Integer);
    procedure CaptionMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; PosX, PosY: Integer);
    procedure DragMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; PosX, PosY: Integer);
    procedure DragTo(Sender: TObject; PosX, PosY: Integer);
    procedure ButtonsResize(Sender: TObject);
    // $0128 - WM_UPDATEUISTATE, в Messages.pas Delphi 7 этой константы нет
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
  public
    constructor Create(AOwner: TComponent); override;
    // Правые кнопки - к правому краю панели кнопок. Зовётся и при
    // изменении размера окна, и из Unit1 после подбора ширин кнопок.
    procedure LayoutButtons;
  end;

implementation

{$IFDEF FPC}{$R *.lfm}{$ELSE}{$R *.dfm}{$ENDIF}

const
  // Ширина зоны у угла, где тянется сразу по двум сторонам
  WinListCornerZone = 16;
  // Отступ крайних кнопок от краёв панели и зазор между кнопками
  WinListBtnMargin = 6;
  WinListBtnGap = 8;

constructor TDlgWinList.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDragEdge := wleNone;

  pnlRoot.OnMouseDown := RootMouseDown;
  pnlRoot.OnMouseMove := RootMouseMove;
  pnlRoot.OnMouseUp := DragMouseUp;

  pnlCaption.Cursor := crSizeAll;
  pnlCaption.OnMouseDown := CaptionMouseDown;
  pnlCaption.OnMouseMove := RootMouseMove;
  pnlCaption.OnMouseUp := DragMouseUp;

  pnlButtons.OnResize := ButtonsResize;

  // Ниже этого списка почти не видно. Минимальная ширина - по кнопкам,
  // её ставит LayoutButtons.
  Constraints.MinHeight := 120;
end;

// По нажатию Alt Windows меняет режим показа подчёркиваний, и кнопки окна
// пропадают с экрана - та же беда, что у главного окна (см.
// TForm1.WMUpdateUIState). Сообщение дальше не передаём: состояние не
// меняется, и перерисовывать нечего.
procedure TDlgWinList.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

procedure TDlgWinList.LayoutButtons;
var
  NeedW: Integer;
begin
  // Уже, чем нужно трём кнопкам, окно не сужается. Ширины кнопок задаёт
  // Unit1 по подписям, поэтому минимум считаем здесь, а не в .dfm. Рамку
  // берём из pnlRoot, а не из ширины панели кнопок: до выравнивания
  // (первый вызов из Unit1) её ширина ещё прежняя, из .dfm.
  NeedW := btnAll.Width + btnOk.Width + btnCancel.Width +
    2 * WinListBtnMargin + 2 * WinListBtnGap +
    2 * (pnlRoot.BorderWidth + pnlRoot.BevelWidth);
  if Constraints.MinWidth <> NeedW then
    Constraints.MinWidth := NeedW;

  btnAll.Left := WinListBtnMargin;
  btnCancel.Left := pnlButtons.ClientWidth - btnCancel.Width - WinListBtnMargin;
  btnOk.Left := btnCancel.Left - btnOk.Width - WinListBtnGap;
end;

procedure TDlgWinList.ButtonsResize(Sender: TObject);
begin
  LayoutButtons;
end;

// Края окна - это рамка pnlRoot (BorderWidth плюс бевел): дочерние панели
// и список её не закрывают, поэтому мышь над рамкой приходит в pnlRoot.
function TDlgWinList.EdgeAt(PosX, PosY: Integer): TWinListEdge;
var
  Frame: Integer;
  AtLeft, AtRight, AtTop, AtBottom: Boolean;
begin
  Frame := pnlRoot.BorderWidth + 2;
  AtLeft := PosX < Frame;
  AtRight := PosX >= pnlRoot.Width - Frame;
  AtTop := PosY < Frame;
  AtBottom := PosY >= pnlRoot.Height - Frame;

  // У угла зона шире: на тонкой рамке в сам угол трудно попасть
  if AtLeft or AtRight then
  begin
    if PosY < WinListCornerZone then
      AtTop := True
    else if PosY >= pnlRoot.Height - WinListCornerZone then
      AtBottom := True;
  end
  else if AtTop or AtBottom then
  begin
    if PosX < WinListCornerZone then
      AtLeft := True
    else if PosX >= pnlRoot.Width - WinListCornerZone then
      AtRight := True;
  end;

  if AtTop and AtLeft then
    Result := wleTopLeft
  else if AtTop and AtRight then
    Result := wleTopRight
  else if AtBottom and AtLeft then
    Result := wleBottomLeft
  else if AtBottom and AtRight then
    Result := wleBottomRight
  else if AtLeft then
    Result := wleLeft
  else if AtRight then
    Result := wleRight
  else if AtTop then
    Result := wleTop
  else if AtBottom then
    Result := wleBottom
  else
    Result := wleNone;
end;

procedure TDlgWinList.RootMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; PosX, PosY: Integer);
begin
  if Button <> mbLeft then
    Exit;
  FDragEdge := EdgeAt(PosX, PosY);
  if FDragEdge = wleNone then
    Exit;
  FDragStart := pnlRoot.ClientToScreen(Point(PosX, PosY));
  FDragBounds := BoundsRect;
end;

procedure TDlgWinList.CaptionMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; PosX, PosY: Integer);
begin
  if Button <> mbLeft then
    Exit;
  FDragEdge := wleMove;
  FDragStart := pnlCaption.ClientToScreen(Point(PosX, PosY));
  FDragBounds := BoundsRect;
end;

procedure TDlgWinList.RootMouseMove(Sender: TObject; Shift: TShiftState;
  PosX, PosY: Integer);
begin
  if FDragEdge <> wleNone then
  begin
    DragTo(Sender, PosX, PosY);
    Exit;
  end;

  if Sender <> pnlRoot then
    Exit;
  // Курсор показывает, что край можно тянуть
  case EdgeAt(PosX, PosY) of
    wleLeft, wleRight: pnlRoot.Cursor := crSizeWE;
    wleTop, wleBottom: pnlRoot.Cursor := crSizeNS;
    wleTopLeft, wleBottomRight: pnlRoot.Cursor := crSizeNWSE;
    wleTopRight, wleBottomLeft: pnlRoot.Cursor := crSizeNESW;
  else
    pnlRoot.Cursor := crDefault;
  end;
end;

procedure TDlgWinList.DragMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; PosX, PosY: Integer);
begin
  if FDragEdge <> wleNone then
    DragTo(Sender, PosX, PosY);
  FDragEdge := wleNone;
end;

// Новые границы окна от точки нажатия: двигается только тот край, за
// который тянут, противоположный стоит на месте. Мышь при нажатой кнопке
// захвачена панелью, поэтому события идут и за пределами окна.
procedure TDlgWinList.DragTo(Sender: TObject; PosX, PosY: Integer);
var
  CurPos: TPoint;
  DeltaX, DeltaY, NewLeft, NewTop, NewRight, NewBottom: Integer;
  MinW, MinH: Integer;
begin
  CurPos := TControl(Sender).ClientToScreen(Point(PosX, PosY));
  DeltaX := CurPos.X - FDragStart.X;
  DeltaY := CurPos.Y - FDragStart.Y;

  NewLeft := FDragBounds.Left;
  NewTop := FDragBounds.Top;
  NewRight := FDragBounds.Right;
  NewBottom := FDragBounds.Bottom;

  if FDragEdge = wleMove then
  begin
    SetBounds(NewLeft + DeltaX, NewTop + DeltaY,
      NewRight - NewLeft, NewBottom - NewTop);
    Exit;
  end;

  if FDragEdge in [wleLeft, wleTopLeft, wleBottomLeft] then
    Inc(NewLeft, DeltaX);
  if FDragEdge in [wleRight, wleTopRight, wleBottomRight] then
    Inc(NewRight, DeltaX);
  if FDragEdge in [wleTop, wleTopLeft, wleTopRight] then
    Inc(NewTop, DeltaY);
  if FDragEdge in [wleBottom, wleBottomLeft, wleBottomRight] then
    Inc(NewBottom, DeltaY);

  // Минимум держим сами: иначе при упоре в Constraints левый/верхний край
  // уезжал бы вместе с мышью, а правый оставался на месте
  MinW := Constraints.MinWidth;
  MinH := Constraints.MinHeight;
  if NewRight - NewLeft < MinW then
  begin
    if FDragEdge in [wleLeft, wleTopLeft, wleBottomLeft] then
      NewLeft := NewRight - MinW
    else
      NewRight := NewLeft + MinW;
  end;
  if NewBottom - NewTop < MinH then
  begin
    if FDragEdge in [wleTop, wleTopLeft, wleTopRight] then
      NewTop := NewBottom - MinH
    else
      NewBottom := NewTop + MinH;
  end;

  SetBounds(NewLeft, NewTop, NewRight - NewLeft, NewBottom - NewTop);
end;

end.
