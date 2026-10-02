unit DlgIconEdit;

// Окно значков палитры (View - Palette Icons, или правая кнопка на кнопке
// палитры - Edit Icon): скрипт значка (формат - DsgIcons.pas), превью в
// светлой и тёмной теме, цвет частей. Применённое пишется в файл своих
// значков (palette_icons.txt рядом с программой) и сразу видно на палитре
// (OnApply - главное окно перерисовывает кнопки). Встроенный значок
// возвращает кнопка «Встроенный».
//
// Окно описано в DlgIconEdit.dfm и правится в конструкторе форм. Форма
// создаётся по месту, в .dpr её автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, Dialogs,
  UiButton,       // TUiButton
  UiEditCtrls,    // TUiListBox, TUiMemo
  UiStdDlgs,      // TUiColorDialog
  DsgIcons,       // скрипты значков, свои значки
  DsgPalette,     // DsgDrawSmoothScript
  UiDialogs;      // MessageDlg, ShowMessage по теме - последним

type
  TDlgIconEdit = class(TForm)
    lstIcons: TUiListBox;
    lblScript: TLabel;
    memScript: TUiMemo;
    pbPreview: TPaintBox;
    lblState: TLabel;
    lblCoords: TLabel;
    lblHelp: TLabel;
    btnColor: TUiButton;
    btnThemeInk: TUiButton;
    btnBuiltin: TUiButton;
    btnApply: TUiButton;
    btnClose: TUiButton;
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure lstIconsClick(Sender: TObject);
    procedure memScriptChange(Sender: TObject);
    procedure pbPreviewPaint(Sender: TObject);
    procedure pbPreviewMouseMove(Sender: TObject; Shift: TShiftState;
                                 X, Y: Integer);
    procedure btnColorClick(Sender: TObject);
    procedure btnThemeInkClick(Sender: TObject);
    procedure btnBuiltinClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
  private
    FCurName: string;        // значок в окне
    FModified: Boolean;      // скрипт правили и не применили
    FLoading: Boolean;       // скрипт ставит код - не правка
    FLightInk, FLightBack, FDarkInk, FDarkBack: TColor;
    FOnApply: TNotifyEvent;
    // $0128 - WM_UPDATEUISTATE, в Messages.pas Delphi 7 этой константы нет
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
    function ItemName(AIndex: Integer): string;
    function ItemCaption(const AName: string): string;
    procedure FillList(const ASelect: string);
    procedure ShowIcon(const AName: string);
    function ScriptFromMemo: string;
    procedure UpdateState;
    function AskApply: Boolean;
    procedure InsertLine(const AText: string);
    procedure SaveUser;
  public
    // Цвета превью: значок и фон светлой и тёмной темы. ASelect - значок,
    // который открыть ('' - первый).
    procedure Prepare(const ASelect: string; ALightInk, ALightBack,
                      ADarkInk, ADarkBack: TColor);
    // Значки сменились (Применить, Встроенный): палитру - перерисовать
    property OnApply: TNotifyEvent read FOnApply write FOnApply;
  end;

implementation

{$R *.dfm}

const
  // Превью: крупно - в 4 раза, точка значка = 4 точки экрана
  PreviewZoom = 4;
  PreviewSide = 24;
  BigLeft = 8;
  BigTop = 18;
  SmallLeft = 8 + PreviewSide * PreviewZoom + 16;
  PanelHeight = PreviewSide * PreviewZoom + 26;
  // Отметка своего значка в списке
  UserMark = '  *';

procedure TDlgIconEdit.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

procedure TDlgIconEdit.FormCreate(Sender: TObject);
begin
  FLightInk := clBlack;
  FLightBack := clBtnFace;
  FDarkInk := $00B0B0B0;
  FDarkBack := $00302D2D;
  lblHelp.Caption :=
    'Команда на строку, координаты в точках значка 24x24, дробные - через точку.' +
    #13#10 +
    'F x1 y1 x2 y2 - прямоугольник;  E ... - стереть;  R x1 y1 x2 y2 [w] - ' +
    'рамка;  O x1 y1 x2 y2 r [w] - скруглённая рамка' + #13#10 +
    'L x1 y1 x2 y2 [w] - линия;  C cx cy r [w] - окружность;  D cx cy r - ' +
    'круг;  K cx cy r - стереть круг' + #13#10 +
    'P x1 y1 x2 y2 ... - многоугольник;  Q ... - стереть;  T x y h B|N ' +
    'текст - надпись Arial' + #13#10 +
    '@ RRGGBB - дальше этим цветом;  @ - снова цветом значка темы. ' +
    'Координаты под мышью - справа под превью.';
end;

procedure TDlgIconEdit.Prepare(const ASelect: string; ALightInk, ALightBack,
                               ADarkInk, ADarkBack: TColor);
begin
  FLightInk := ALightInk;
  FLightBack := ALightBack;
  FDarkInk := ADarkInk;
  FDarkBack := ADarkBack;
  FillList(ASelect);
end;

function TDlgIconEdit.ItemCaption(const AName: string): string;
begin
  Result := AName;
  if DsgIconUser(AName) <> '' then
    Result := Result + UserMark;
end;

function TDlgIconEdit.ItemName(AIndex: Integer): string;
var
  SpacePos: Integer;
begin
  Result := '';
  if (AIndex < 0) or (AIndex >= lstIcons.Items.Count) then
    Exit;
  Result := lstIcons.Items[AIndex];
  SpacePos := Pos(' ', Result);
  if SpacePos > 0 then
    Result := Copy(Result, 1, SpacePos - 1);
end;

procedure TDlgIconEdit.FillList(const ASelect: string);
var
  Names: TStringList;
  NameIdx, SelIdx: Integer;
begin
  Names := TStringList.Create;
  try
    DsgIconNames(Names);
    // Свои компоненты TUiX берут значок TX - ищем его
    if (CompareText(Copy(ASelect, 1, 3), 'TUi') = 0) and
       (Names.IndexOf(ASelect) < 0) then
      SelIdx := Names.IndexOf('T' + Copy(ASelect, 4, MaxInt))
    else
      SelIdx := Names.IndexOf(ASelect);
    lstIcons.Items.BeginUpdate;
    try
      lstIcons.Items.Clear;
      for NameIdx := 0 to Names.Count - 1 do
        lstIcons.Items.Add(ItemCaption(Names[NameIdx]));
    finally
      lstIcons.Items.EndUpdate;
    end;
  finally
    Names.Free;
  end;
  if SelIdx < 0 then
    SelIdx := 0;
  if lstIcons.Items.Count > 0 then
  begin
    lstIcons.ItemIndex := SelIdx;
    ShowIcon(ItemName(SelIdx));
  end;
end;

procedure TDlgIconEdit.ShowIcon(const AName: string);
var
  Script: string;
  CmdPos: Integer;
  Lines: TStringList;
begin
  FCurName := AName;
  Script := DsgIconScript(AName);
  Lines := TStringList.Create;
  try
    while Script <> '' do
    begin
      CmdPos := Pos(';', Script);
      if CmdPos = 0 then
        CmdPos := Length(Script) + 1;
      if Trim(Copy(Script, 1, CmdPos - 1)) <> '' then
        Lines.Add(Trim(Copy(Script, 1, CmdPos - 1)));
      Delete(Script, 1, CmdPos);
    end;
    FLoading := True;
    try
      memScript.Lines.Assign(Lines);
    finally
      FLoading := False;
    end;
  finally
    Lines.Free;
  end;
  FModified := False;
  UpdateState;
  pbPreview.Invalidate;
end;

function TDlgIconEdit.ScriptFromMemo: string;
var
  LineIdx: Integer;
  Line: string;
begin
  Result := '';
  for LineIdx := 0 to memScript.Lines.Count - 1 do
  begin
    Line := Trim(memScript.Lines[LineIdx]);
    if Line = '' then
      Continue;
    if Result <> '' then
      Result := Result + ';';
    Result := Result + Line;
  end;
end;

procedure TDlgIconEdit.UpdateState;
var
  Text: string;
begin
  if FCurName = '' then
    Text := ''
  else if DsgIconUser(FCurName) <> '' then
    Text := FCurName + ': свой значок (' +
            ExtractFileName(DsgIconUserFile) + ')'
  else if DsgIconBuiltin(FCurName) <> '' then
    Text := FCurName + ': встроенный значок'
  else
    Text := FCurName;
  if FModified then
    Text := Text + ' - изменён, не применён';
  lblState.Caption := Text;
  btnApply.Enabled := FModified;
  btnBuiltin.Enabled := (FCurName <> '') and
                        ((DsgIconUser(FCurName) <> '') or FModified) and
                        (DsgIconBuiltin(FCurName) <> '');
end;

// Изменённый скрипт при уходе с него: применить? False - не уходить.
function TDlgIconEdit.AskApply: Boolean;
begin
  Result := True;
  if not FModified then
    Exit;
  case MessageDlg('Значок ' + FCurName + ' изменён. Применить?',
                  mtConfirmation, [mbYes, mbNo, mbCancel], 0) of
    mrYes:
      btnApplyClick(nil);
    mrNo:
      FModified := False;
  else
    Result := False;
  end;
end;

procedure TDlgIconEdit.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := AskApply;
end;

procedure TDlgIconEdit.lstIconsClick(Sender: TObject);
var
  NewName: string;
begin
  NewName := ItemName(lstIcons.ItemIndex);
  if (NewName = '') or (NewName = FCurName) then
    Exit;
  if not AskApply then
  begin
    // Остаёмся на прежнем
    lstIcons.ItemIndex := lstIcons.Items.IndexOf(ItemCaption(FCurName));
    Exit;
  end;
  ShowIcon(NewName);
end;

procedure TDlgIconEdit.memScriptChange(Sender: TObject);
begin
  if FLoading then
    Exit;
  FModified := ScriptFromMemo <> DsgIconScript(FCurName);
  UpdateState;
  pbPreview.Invalidate;
end;

procedure TDlgIconEdit.pbPreviewPaint(Sender: TObject);
var
  Glyph: TBitmap;
  Script: string;
  PanelIdx, PanelTop: Integer;
  Ink, Back: TColor;
  PanelRect: TRect;
begin
  Script := ScriptFromMemo;
  Glyph := TBitmap.Create;
  try
    for PanelIdx := 0 to 1 do
    begin
      if PanelIdx = 0 then
      begin
        Ink := FLightInk;
        Back := FLightBack;
      end
      else
      begin
        Ink := FDarkInk;
        Back := FDarkBack;
      end;
      PanelTop := PanelIdx * (PanelHeight + 4);
      PanelRect := Rect(0, PanelTop, pbPreview.Width, PanelTop + PanelHeight);
      pbPreview.Canvas.Brush.Style := bsSolid;
      pbPreview.Canvas.Brush.Color := Back;
      pbPreview.Canvas.FillRect(PanelRect);
      pbPreview.Canvas.Font := Font;
      pbPreview.Canvas.Font.Color := Ink;
      if PanelIdx = 0 then
        pbPreview.Canvas.TextOut(BigLeft, PanelTop + 2, 'Light')
      else
        pbPreview.Canvas.TextOut(BigLeft, PanelTop + 2, 'Dark');

      DsgDrawSmoothScript(Glyph, Script, Ink, Back);
      // Пустые точки - прозрачный цвет кнопки палитры
      Glyph.TransparentColor := clOlive;
      Glyph.TransparentMode := tmFixed;
      Glyph.Transparent := True;
      // Крупно - без сглаживания растяжения: видна каждая точка
      SetStretchBltMode(pbPreview.Canvas.Handle, COLORONCOLOR);
      pbPreview.Canvas.StretchDraw(
        Rect(BigLeft, PanelTop + BigTop,
             BigLeft + PreviewSide * PreviewZoom,
             PanelTop + BigTop + PreviewSide * PreviewZoom), Glyph);
      pbPreview.Canvas.Draw(SmallLeft, PanelTop + BigTop +
                            (PreviewSide * PreviewZoom - PreviewSide) div 2,
                            Glyph);
      // Рамка крупного - границы поля 24x24
      pbPreview.Canvas.Brush.Style := bsClear;
      pbPreview.Canvas.Pen.Color := clGray;
      pbPreview.Canvas.Rectangle(BigLeft - 1, PanelTop + BigTop - 1,
                                 BigLeft + PreviewSide * PreviewZoom + 1,
                                 PanelTop + BigTop +
                                 PreviewSide * PreviewZoom + 1);
    end;
  finally
    Glyph.Free;
  end;
end;

// Координата значка с шагом 0.25 - текстом с точкой, как в скрипте
function CoordText(APixels: Integer): string;
const
  Fractions: array[0..3] of string = ('', '.25', '.5', '.75');
begin
  Result := IntToStr(APixels div PreviewZoom) +
            Fractions[APixels mod PreviewZoom];
end;

procedure TDlgIconEdit.pbPreviewMouseMove(Sender: TObject; Shift: TShiftState;
                                          X, Y: Integer);
var
  PanelIdx, LocalY, LocalX: Integer;
begin
  lblCoords.Caption := '';
  for PanelIdx := 0 to 1 do
  begin
    LocalX := X - BigLeft;
    LocalY := Y - PanelIdx * (PanelHeight + 4) - BigTop;
    if (LocalX >= 0) and (LocalY >= 0) and
       (LocalX < PreviewSide * PreviewZoom) and
       (LocalY < PreviewSide * PreviewZoom) then
    begin
      lblCoords.Caption := 'x ' + CoordText(LocalX) + '   y ' +
                           CoordText(LocalY);
      Exit;
    end;
  end;
end;

// Строка AText - перед строкой каретки
procedure TDlgIconEdit.InsertLine(const AText: string);
var
  LineIdx: Integer;
begin
  LineIdx := memScript.CaretPos.Y;
  if (LineIdx < 0) or (LineIdx > memScript.Lines.Count) then
    LineIdx := memScript.Lines.Count;
  memScript.Lines.Insert(LineIdx, AText);
  memScript.SetFocus;
end;

procedure TDlgIconEdit.btnColorClick(Sender: TObject);
var
  ColorDlg: TUiColorDialog;
  RGBValue: Longint;
begin
  ColorDlg := TUiColorDialog.Create(Self);
  try
    ColorDlg.Color := clRed;
    if not ColorDlg.Execute then
      Exit;
    RGBValue := ColorToRGB(ColorDlg.Color);
    InsertLine('@ ' + IntToHex(GetRValue(RGBValue), 2) +
               IntToHex(GetGValue(RGBValue), 2) +
               IntToHex(GetBValue(RGBValue), 2));
  finally
    ColorDlg.Free;
  end;
end;

procedure TDlgIconEdit.btnThemeInkClick(Sender: TObject);
begin
  InsertLine('@');
end;

procedure TDlgIconEdit.SaveUser;
var
  ErrText: string;
begin
  if not DsgIconSaveUser(ErrText) then
    ShowMessage('Файл своих значков не записан: ' + DsgIconUserFile +
                #13#10 + ErrText);
end;

procedure TDlgIconEdit.btnBuiltinClick(Sender: TObject);
var
  ItemIdx: Integer;
begin
  if FCurName = '' then
    Exit;
  DsgIconSetUser(FCurName, '');
  SaveUser;
  ItemIdx := lstIcons.ItemIndex;
  if ItemIdx >= 0 then
  begin
    lstIcons.Items[ItemIdx] := ItemCaption(FCurName);
    lstIcons.ItemIndex := ItemIdx;
  end;
  ShowIcon(FCurName);
  if Assigned(FOnApply) then
    FOnApply(Self);
end;

procedure TDlgIconEdit.btnApplyClick(Sender: TObject);
var
  Script: string;
  ItemIdx: Integer;
begin
  if FCurName = '' then
    Exit;
  Script := ScriptFromMemo;
  // Совпал со встроенным - свой не нужен
  if Script = DsgIconBuiltin(FCurName) then
    DsgIconSetUser(FCurName, '')
  else
    DsgIconSetUser(FCurName, Script);
  SaveUser;
  FModified := False;
  ItemIdx := lstIcons.ItemIndex;
  if ItemName(ItemIdx) <> FCurName then
    ItemIdx := lstIcons.Items.IndexOf(FCurName);
  if ItemIdx < 0 then
    ItemIdx := lstIcons.Items.IndexOf(FCurName + UserMark);
  if ItemIdx >= 0 then
  begin
    lstIcons.Items[ItemIdx] := ItemCaption(FCurName);
    // Замена строки снимает выделение - если это была выделенная, вернуть
    if lstIcons.ItemIndex < 0 then
      lstIcons.ItemIndex := ItemIdx;
  end;
  UpdateState;
  if Assigned(FOnApply) then
    FOnApply(Self);
end;

end.
