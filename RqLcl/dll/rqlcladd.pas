// ---------------------------------------------------------------------------
//  RqLcl: свойства и методы RapidQ у классов, сделанных раньше, которых нет
//  в LCL или которые там другие.
//
//  QLABEL - TRqLabel (TLabel): Angle (Font.Orientation), LabelStyle,
//    UpperColor, LowerColor - объёмный текст: надпись рисуется три раза,
//    со сдвигом на 1 точку цветом UpperColor и LowerColor и на месте.
//  QEDIT - TMaskEdit: InputMask (EditMask), IsMasked, EditText;
//    PasswordChar - строка (у LCL Char).
//  QLISTBOX - TRqListBox (TListBox): TabWidth (LBS_USETABSTOPS,
//    LB_SETTABSTOPS, как TabWidth у Delphi), OnEnter - нажата клавиша
//    Enter (у LCL OnEnter - получение фокуса, у RapidQ его нет).
//  QSTRINGGRID - TRqStringGrid (TStringGrid): ColumnStyle(i) (gcsList 0,
//    gcsEllipsis 1, gcsNone 2), ColumnList(i) - пункты списка через LF,
//    TabStops(i) - Tab пропускает столбец с TabStops = 0; OnEllipsisClick
//    (Col, Row), OnListDropDown (Col, Row, BYREF S) - список раскрывается,
//    S - пункты через LF (на входе ColumnList столбца).
//  QFORM: AddBorderIcons / DelBorderIcons, HideTitleBar / ShowTitleBar
//    (стиль окна WS_CAPTION), ShapeForm (область окна по картинке).
//  QBUTTON, QCOOLBTN, QOVALBTN: StartDrag - элемент едет за мышью, пока
//    нажата кнопка мыши; возврат - когда кнопку отпустили.
//  QPOPUPMENU.WindowHandle, QIMAGELIST.Handle, Application.IcoHandle,
//  Application.HelpCommand / HelpContext / HelpJump, Clipboard.Format(i),
//  GetAsHandle, SetAsHandle.
// ---------------------------------------------------------------------------
unit rqlcladd;

{$mode objfpc}{$H+}
{$WARN SYMBOL_PLATFORM OFF}

interface

uses
  Windows, Classes, SysUtils, Types, LCLType, Controls, StdCtrls, Forms, Graphics,
  Grids, Menus, ImgList, MaskEdit, Clipbrd, InterfaceBase, LazUTF8,
  rqlclmisc;

type
  // QLABEL
  TRqLabel = class(TLabel)
  private
    FAngle: Integer;
    FLabelStyle: Integer;
    FUpperColor: TColor;
    FLowerColor: TColor;
    procedure SetAngle(AValue: Integer);
    procedure SetLabelStyle(AValue: Integer);
    procedure SetUpperColor(AValue: TColor);
    procedure SetLowerColor(AValue: TColor);
  protected
    procedure DoDrawText(var ARect: TRect; AFlags: Longint); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Angle: Integer read FAngle write SetAngle;
    property LabelStyle: Integer read FLabelStyle write SetLabelStyle;
    property UpperColor: TColor read FUpperColor write SetUpperColor;
    property LowerColor: TColor read FLowerColor write SetLowerColor;
  end;

  // QLISTBOX
  TRqListBox = class(TListBox)
  private
    FTabWidth: Integer;
    FOnEnterKey: TNotifyEvent;
    procedure SetTabWidth(AValue: Integer);
  protected
    procedure CreateParams(var AParams: TCreateParams); override;
    procedure InitializeWnd; override;
    procedure KeyDown(var AKey: Word; AShift: TShiftState); override;
  published
    property TabWidth: Integer read FTabWidth write SetTabWidth;
    // OnEnter RapidQ - клавиша Enter
    property OnEnter: TNotifyEvent read FOnEnterKey write FOnEnterKey;
  end;

  TRqListDropDownEvent = procedure(Sender: TObject; ACol, ARow: Integer;
                                   var AList: string) of object;

  // QSTRINGGRID
  TRqStringGrid = class(TStringGrid)
  private
    FColStyles: array of Integer;
    FColLists: array of string;
    FTabStops: array of Integer;
    FOnEllipsisClick: TOnSelectEvent;
    FOnListDropDown: TRqListDropDownEvent;
    procedure PickListDropDown(Sender: TObject);
    procedure EllipsisClicked(Sender: TObject; ACol, ARow: Integer);
    procedure SetOnEllipsisClick(AValue: TOnSelectEvent);
    function HasTabStopsOff: Boolean;
    procedure ReselectEditor;
  protected
    function GetDefaultEditor(AColumn: Integer): TWinControl; override;
    procedure KeyDown(var AKey: Word; AShift: TShiftState); override;
  public
    function GetColumnStyle(ACol: Integer): Integer;
    procedure SetColumnStyle(ACol, AValue: Integer);
    function GetColumnList(ACol: Integer): string;
    procedure SetColumnList(ACol: Integer; const AValue: string);
    function GetTabStop(ACol: Integer): Integer;
    procedure SetTabStop(ACol, AValue: Integer);
  published
    property OnEllipsisClick: TOnSelectEvent read FOnEllipsisClick
                                             write SetOnEllipsisClick;
    property OnListDropDown: TRqListDropDownEvent read FOnListDropDown
                                                  write FOnListDropDown;
  end;

function AddGetInt(AObj: TObject; const AProp: string;
                   out AValue: Integer): Boolean;
function AddSetInt(AObj: TObject; const AProp: string;
                   AValue: Integer): Boolean;
function AddGetStr(AObj: TObject; const AProp: string;
                   out AValue: string): Boolean;
function AddSetStr(AObj: TObject; const AProp: string;
                   const AValue: string): Boolean;
function AddGetItem(AObj: TObject; const AProp: string; AIndex: Integer;
                    out AValue: string): Boolean;
function AddSetItem(AObj: TObject; const AProp: string; AIndex: Integer;
                    const AValue: string): Boolean;
function AddGetItemInt(AObj: TObject; const AProp: string; AIndex: Integer;
                       out AValue: Integer): Boolean;
function AddSetItemInt(AObj: TObject; const AProp: string; AIndex: Integer;
                       AValue: Integer): Boolean;
function AddCallEx(AObj: TObject; const AMethod, AStr: string;
                   AInt1, AInt2, AInt3: Integer;
                   out AIntResult: Integer): Boolean;

implementation

const
  GcsList = 0;
  GcsEllipsis = 1;
  GcsNone = 2;
  HH_DISPLAY_TOPIC = 0;
  HH_HELP_CONTEXT = $F;

type
  // Доступ к OnDropDown (protected у TCustomComboBox)
  TRqComboAccess = class(TCustomComboBox);

  // Число, которого нет у объекта LCL (QPOPUPMENU.WindowHandle)
  TRqIntHolder = class(TComponent)
  public
    Key: string;
    Value: Integer;
  end;

  THtmlHelpA = function(ACaller: HWND; AFile: PChar; ACommand: UINT;
                        AData: PtrUInt): HWND; stdcall;

function HolderOf(AComp: TComponent; const AKey: string): TRqIntHolder;
var
  CompIdx: Integer;
begin
  for CompIdx := 0 to AComp.ComponentCount - 1 do
    if (AComp.Components[CompIdx] is TRqIntHolder) and
       (TRqIntHolder(AComp.Components[CompIdx]).Key = AKey) then
    begin
      Result := TRqIntHolder(AComp.Components[CompIdx]);
      Exit;
    end;
  Result := TRqIntHolder.Create(AComp);
  Result.Key := AKey;
end;

procedure CheckIndex(const AWhat: string; AIndex, ACount: Integer);
begin
  if (AIndex < 0) or (AIndex >= ACount) then
    raise Exception.Create(AWhat + '(' + IntToStr(AIndex) + '): out of 0..' +
                           IntToStr(ACount - 1));
end;

// ---------------------------------------------------------------------------
//  TRqLabel
// ---------------------------------------------------------------------------

constructor TRqLabel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FUpperColor := clBtnHighlight;
  FLowerColor := clBtnShadow;
end;

// Angle - градусы против часовой стрелки; LCL поворачивает текст сама
// (Font.Orientation - десятые доли градуса)
procedure TRqLabel.SetAngle(AValue: Integer);
begin
  FAngle := AValue;
  Font.Orientation := AValue * 10;
  Invalidate;
end;

procedure TRqLabel.SetLabelStyle(AValue: Integer);
begin
  if (AValue < 0) or (AValue > 2) then
    raise Exception.Create('LabelStyle: ' + IntToStr(AValue) + ' out of 0..2');
  FLabelStyle := AValue;
  Invalidate;
end;

procedure TRqLabel.SetUpperColor(AValue: TColor);
begin
  FUpperColor := AValue;
  Invalidate;
end;

procedure TRqLabel.SetLowerColor(AValue: TColor);
begin
  FLowerColor := AValue;
  Invalidate;
end;

// lsRaised: свет слева сверху, тень справа снизу; lsRecessed - наоборот
procedure TRqLabel.DoDrawText(var ARect: TRect; AFlags: Longint);
var
  ShiftRect: TRect;
  TextColor, FirstColor, SecondColor: TColor;
begin
  if (FLabelStyle = 0) or ((AFlags and DT_CALCRECT) <> 0) or not IsEnabled then
  begin
    inherited DoDrawText(ARect, AFlags);
    Exit;
  end;
  if FLabelStyle = 1 then
  begin
    FirstColor := FUpperColor;
    SecondColor := FLowerColor;
  end
  else
  begin
    FirstColor := FLowerColor;
    SecondColor := FUpperColor;
  end;
  TextColor := Canvas.Font.Color;
  ShiftRect := ARect;
  Types.OffsetRect(ShiftRect, -1, -1);
  Canvas.Font.Color := FirstColor;
  inherited DoDrawText(ShiftRect, AFlags);
  ShiftRect := ARect;
  Types.OffsetRect(ShiftRect, 1, 1);
  Canvas.Font.Color := SecondColor;
  inherited DoDrawText(ShiftRect, AFlags);
  Canvas.Font.Color := TextColor;
  inherited DoDrawText(ARect, AFlags);
end;

// ---------------------------------------------------------------------------
//  TRqListBox
// ---------------------------------------------------------------------------

procedure TRqListBox.SetTabWidth(AValue: Integer);
begin
  if AValue < 0 then
    AValue := 0;
  if FTabWidth = AValue then
    Exit;
  FTabWidth := AValue;
  if HandleAllocated then
    RecreateWnd(Self);
end;

procedure TRqListBox.CreateParams(var AParams: TCreateParams);
begin
  inherited CreateParams(AParams);
  if FTabWidth > 0 then
    AParams.Style := AParams.Style or LBS_USETABSTOPS;
end;

// Шаг табуляции - в единицах диалога (как у Delphi)
procedure TRqListBox.InitializeWnd;
var
  TabUnits: Integer;
begin
  inherited InitializeWnd;
  if FTabWidth > 0 then
  begin
    TabUnits := FTabWidth;
    SendMessage(Handle, LB_SETTABSTOPS, 1, LPARAM(@TabUnits));
  end;
end;

procedure TRqListBox.KeyDown(var AKey: Word; AShift: TShiftState);
begin
  inherited KeyDown(AKey, AShift);
  if (AKey = VK_RETURN) and Assigned(FOnEnterKey) then
    FOnEnterKey(Self);
end;

// ---------------------------------------------------------------------------
//  TRqStringGrid
// ---------------------------------------------------------------------------

function TRqStringGrid.GetColumnStyle(ACol: Integer): Integer;
begin
  CheckIndex('ColumnStyle', ACol, ColCount);
  if ACol < Length(FColStyles) then
    Result := FColStyles[ACol]
  else
    Result := GcsNone;
end;

procedure TRqStringGrid.SetColumnStyle(ACol, AValue: Integer);
var
  OldLen, ColIdx: Integer;
begin
  CheckIndex('ColumnStyle', ACol, ColCount);
  if (AValue < GcsList) or (AValue > GcsNone) then
    raise Exception.Create('ColumnStyle: ' + IntToStr(AValue) + ' out of 0..2');
  if ACol >= Length(FColStyles) then
  begin
    OldLen := Length(FColStyles);
    SetLength(FColStyles, ACol + 1);
    for ColIdx := OldLen to ACol do
      FColStyles[ColIdx] := GcsNone;
  end;
  FColStyles[ACol] := AValue;
  if ACol = Col then
    ReselectEditor;
end;

// Редактор текущей ячейки - заново (LCL выбирает его при переходе на
// ячейку): по новому стилю и списку столбца
procedure TRqStringGrid.ReselectEditor;
var
  WasEditing: Boolean;
begin
  WasEditing := EditorMode;
  if WasEditing then
    EditorMode := False;
  SelectEditor;
  if WasEditing then
    EditorMode := True;
end;

// Строки - в кодировке Windows, как пришли
function TRqStringGrid.GetColumnList(ACol: Integer): string;
begin
  CheckIndex('ColumnList', ACol, ColCount);
  if ACol < Length(FColLists) then
    Result := FColLists[ACol]
  else
    Result := '';
end;

procedure TRqStringGrid.SetColumnList(ACol: Integer; const AValue: string);
begin
  CheckIndex('ColumnList', ACol, ColCount);
  if ACol >= Length(FColLists) then
    SetLength(FColLists, ACol + 1);
  FColLists[ACol] := AValue;
  if (ACol = Col) and (GetColumnStyle(ACol) = GcsList) then
    ReselectEditor;
end;

function TRqStringGrid.GetTabStop(ACol: Integer): Integer;
begin
  CheckIndex('TabStops', ACol, ColCount);
  if ACol < Length(FTabStops) then
    Result := FTabStops[ACol]
  else
    Result := 1;
end;

procedure TRqStringGrid.SetTabStop(ACol, AValue: Integer);
var
  OldLen, ColIdx: Integer;
begin
  CheckIndex('TabStops', ACol, ColCount);
  if ACol >= Length(FTabStops) then
  begin
    OldLen := Length(FTabStops);
    SetLength(FTabStops, ACol + 1);
    for ColIdx := OldLen to ACol do
      FTabStops[ColIdx] := 1;
  end;
  FTabStops[ACol] := Ord(AValue <> 0);
end;

function TRqStringGrid.HasTabStopsOff: Boolean;
var
  ColIdx: Integer;
begin
  Result := False;
  for ColIdx := 0 to High(FTabStops) do
    if FTabStops[ColIdx] = 0 then
    begin
      Result := True;
      Exit;
    end;
end;

// gcsList - выпадающий список, gcsEllipsis - кнопка "..." у ячейки
function TRqStringGrid.GetDefaultEditor(AColumn: Integer): TWinControl;
var
  Style: Integer;
begin
  Result := inherited GetDefaultEditor(AColumn);
  if (Result = nil) or (AColumn < 0) or (AColumn >= ColCount) then
    Exit;
  Style := GetColumnStyle(AColumn);
  if Style = GcsList then
  begin
    Result := EditorByStyle(cbsPickList);
    if Result is TCustomComboBox then
    begin
      TCustomComboBox(Result).Items.Text := WinCPToUTF8(GetColumnList(AColumn));
      TRqComboAccess(Result).OnDropDown := @PickListDropDown;
    end;
  end
  else if Style = GcsEllipsis then
    Result := EditorByStyle(cbsEllipsis);
end;

procedure TRqStringGrid.PickListDropDown(Sender: TObject);
var
  ListText: string;
begin
  if not Assigned(FOnListDropDown) or not (Sender is TCustomComboBox) then
    Exit;
  ListText := GetColumnList(Col);
  FOnListDropDown(Self, Col, Row, ListText);
  TCustomComboBox(Sender).Items.Text := WinCPToUTF8(ListText);
end;

// Кнопку "..." LCL обрабатывает, только если есть OnButtonClick (у RapidQ
// его нет - занят здесь)
procedure TRqStringGrid.SetOnEllipsisClick(AValue: TOnSelectEvent);
begin
  FOnEllipsisClick := AValue;
  if Assigned(AValue) then
    OnButtonClick := @EllipsisClicked
  else
    OnButtonClick := nil;
end;

procedure TRqStringGrid.EllipsisClicked(Sender: TObject; ACol, ARow: Integer);
begin
  if Assigned(FOnEllipsisClick) then
    FOnEllipsisClick(Self, ACol, ARow);
end;

// Tab (goTabs) переходит дальше, пока не встретит столбец с TabStops <> 0
procedure TRqStringGrid.KeyDown(var AKey: Word; AShift: TShiftState);
var
  TabKey: Word;
  Tries: Integer;
begin
  if (AKey <> VK_TAB) or not (goTabs in Options) or not HasTabStopsOff then
  begin
    inherited KeyDown(AKey, AShift);
    Exit;
  end;
  inherited KeyDown(AKey, AShift);
  Tries := 0;
  while (Tries < ColCount) and (GetTabStop(Col) = 0) do
  begin
    TabKey := VK_TAB;
    inherited KeyDown(TabKey, AShift);
    Inc(Tries);
  end;
end;

// ---------------------------------------------------------------------------
//  QFORM
// ---------------------------------------------------------------------------

// Область окна - точки картинки, кроме цвета ATransColor; начало
// картинки - левый верхний угол окна (с рамкой и заголовком)
function RegionFromBitmap(ABitmap: TBitmap; ATransColor: TColor): HRGN;
type
  TPixelRow = array[0..MaxInt div 8] of DWORD;
  PPixelRow = ^TPixelRow;
var
  BmpInfo: Windows.TBitmapInfo;
  DibBits: Pointer;
  Dib, OldBmp: HBITMAP;
  MemDC: HDC;
  PicWidth, PicHeight, RowIdx, ColIdx, RunStart: Integer;
  TransRgb: DWORD;
  Row: PPixelRow;
  RunRgn: HRGN;
  ColorValue: TColor;
begin
  PicWidth := ABitmap.Width;
  PicHeight := ABitmap.Height;
  if (PicWidth <= 0) or (PicHeight <= 0) then
    raise Exception.Create('ShapeForm: empty picture');
  FillChar(BmpInfo, SizeOf(BmpInfo), 0);
  BmpInfo.bmiHeader.biSize := SizeOf(BmpInfo.bmiHeader);
  BmpInfo.bmiHeader.biWidth := PicWidth;
  BmpInfo.bmiHeader.biHeight := -PicHeight;
  BmpInfo.bmiHeader.biPlanes := 1;
  BmpInfo.bmiHeader.biBitCount := 32;
  BmpInfo.bmiHeader.biCompression := BI_RGB;
  DibBits := nil;
  Dib := CreateDIBSection(0, BmpInfo, DIB_RGB_COLORS, DibBits, 0, 0);
  if (Dib = 0) or (DibBits = nil) then
    raise Exception.Create('ShapeForm: CreateDIBSection failed');
  MemDC := CreateCompatibleDC(0);
  OldBmp := SelectObject(MemDC, Dib);
  Result := CreateRectRgn(0, 0, 0, 0);
  try
    BitBlt(MemDC, 0, 0, PicWidth, PicHeight, ABitmap.Canvas.Handle, 0, 0,
           SRCCOPY);
    GdiFlush;
    // TColor $00BBGGRR -> точка DIB $00RRGGBB
    ColorValue := ColorToRGB(ATransColor);
    TransRgb := ((DWORD(ColorValue) and $FF) shl 16) or
                (DWORD(ColorValue) and $FF00) or
                ((DWORD(ColorValue) shr 16) and $FF);
    for RowIdx := 0 to PicHeight - 1 do
    begin
      Row := PPixelRow(PtrUInt(DibBits) + PtrUInt(RowIdx * PicWidth * 4));
      ColIdx := 0;
      while ColIdx < PicWidth do
      begin
        while (ColIdx < PicWidth) and ((Row^[ColIdx] and $FFFFFF) = TransRgb) do
          Inc(ColIdx);
        RunStart := ColIdx;
        while (ColIdx < PicWidth) and ((Row^[ColIdx] and $FFFFFF) <> TransRgb) do
          Inc(ColIdx);
        if ColIdx > RunStart then
        begin
          RunRgn := CreateRectRgn(RunStart, RowIdx, ColIdx, RowIdx + 1);
          CombineRgn(Result, Result, RunRgn, RGN_OR);
          DeleteObject(RunRgn);
        end;
      end;
    end;
  finally
    SelectObject(MemDC, OldBmp);
    DeleteDC(MemDC);
    DeleteObject(Dib);
  end;
end;

procedure ShapeForm(AForm: TCustomForm; const AFileName: string;
                    AResId: Integer; ATransColor: TColor);
var
  ShapeBitmap: TBitmap;
  ResStream: TStream;
  ShapeRgn: HRGN;
begin
  ShapeBitmap := TBitmap.Create;
  try
    if AFileName <> '' then
      ShapeBitmap.LoadFromFile(WinCPToUTF8(AFileName))
    else
    begin
      ResStream := MiscResourceStream(AResId);
      if ResStream = nil then
        raise Exception.Create('ShapeForm: no resource ' + IntToStr(AResId));
      try
        ShapeBitmap.LoadFromStream(ResStream);
      finally
        ResStream.Free;
      end;
    end;
    ShapeRgn := RegionFromBitmap(ShapeBitmap, ATransColor);
    // область переходит окну (Windows освободит её сама)
    if SetWindowRgn(AForm.Handle, ShapeRgn, True) = 0 then
    begin
      DeleteObject(ShapeRgn);
      raise Exception.Create('ShapeForm: SetWindowRgn failed');
    end;
  finally
    ShapeBitmap.Free;
  end;
end;

// Заголовок окна: стиль WS_CAPTION; размер окна не меняется
procedure SetTitleBar(AForm: TCustomForm; AVisible: Boolean);
var
  FormWnd: HWND;
  WndStyle: PtrInt;
begin
  FormWnd := AForm.Handle;
  WndStyle := GetWindowLongPtrW(FormWnd, GWL_STYLE);
  if AVisible then
    WndStyle := WndStyle or WS_CAPTION
  else
    WndStyle := WndStyle and not PtrInt(WS_CAPTION);
  SetWindowLongPtrW(FormWnd, GWL_STYLE, WndStyle);
  SetWindowPos(FormWnd, 0, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or
               SWP_NOZORDER or SWP_NOACTIVATE or SWP_FRAMECHANGED);
end;

function BorderIconOf(AValue: Integer): TBorderIcon;
begin
  if (AValue < 0) or (AValue > Ord(High(TBorderIcon))) then
    raise Exception.Create('border icon ' + IntToStr(AValue) + ' out of 0..' +
                           IntToStr(Ord(High(TBorderIcon))));
  Result := TBorderIcon(AValue);
end;

// ---------------------------------------------------------------------------
//  StartDrag
// ---------------------------------------------------------------------------

procedure StartDrag(AControl: TControl);
var
  ButtonKey: Integer;
  StartPos, CursorPos: TPoint;
  StartLeft, StartTop: Integer;
begin
  if GetSystemMetrics(SM_SWAPBUTTON) <> 0 then
    ButtonKey := VK_RBUTTON
  else
    ButtonKey := VK_LBUTTON;
  // кнопка мыши уже отпущена - двигать нечего
  if GetAsyncKeyState(ButtonKey) >= 0 then
    Exit;
  // нажатие кнопки (элемента) отменяется - иначе по отпусканию был бы Click
  ReleaseCapture;
  SetCaptureControl(nil);
  GetCursorPos(StartPos);
  StartLeft := AControl.Left;
  StartTop := AControl.Top;
  while GetAsyncKeyState(ButtonKey) < 0 do
  begin
    GetCursorPos(CursorPos);
    AControl.SetBounds(StartLeft + CursorPos.X - StartPos.X,
                       StartTop + CursorPos.Y - StartPos.Y,
                       AControl.Width, AControl.Height);
    Application.ProcessMessages;
    if (csDestroying in AControl.ComponentState) or Application.Terminated then
      Exit;
    Sleep(10);
  end;
end;

// ---------------------------------------------------------------------------
//  Application: справка
// ---------------------------------------------------------------------------

function HelpWindow: HWND;
begin
  if (Application.MainForm <> nil) and Application.MainForm.HandleAllocated then
    Result := Application.MainForm.Handle
  else
    Result := WidgetSet.AppHandle;
end;

// Файл .chm - HtmlHelp (hhctrl.ocx), остальные - WinHelp
function CallHtmlHelp(const AFile: string; ACommand: UINT;
                      AData: PtrUInt): Boolean;
var
  HelpLib: HMODULE;
  HtmlHelpProc: THtmlHelpA;
begin
  Result := False;
  HelpLib := LoadLibrary('hhctrl.ocx');
  if HelpLib = 0 then
    raise Exception.Create('HtmlHelp: hhctrl.ocx not found');
  HtmlHelpProc := THtmlHelpA(GetProcAddress(HelpLib, 'HtmlHelpA'));
  if not Assigned(HtmlHelpProc) then
    raise Exception.Create('HtmlHelp: no HtmlHelpA in hhctrl.ocx');
  Result := HtmlHelpProc(HelpWindow, PChar(AFile), ACommand, AData) <> 0;
end;

function HelpFileName: string;
begin
  Result := UTF8ToWinCP(Application.HelpFile);
  if Result = '' then
    raise Exception.Create('Application.HelpFile is empty');
end;

function IsChm(const AFile: string): Boolean;
begin
  Result := CompareText(ExtractFileExt(AFile), '.chm') = 0;
end;

function HelpCall(const AMethod, AStr: string; AInt1, AInt2: Integer): Integer;
var
  FileName, Command: string;
begin
  FileName := HelpFileName;
  if AMethod = 'HELPCOMMAND' then
    Result := Ord(WinHelpA(HelpWindow, PChar(FileName), UINT(AInt1),
                           PtrUInt(PtrInt(AInt2))))
  else if AMethod = 'HELPCONTEXT' then
  begin
    if IsChm(FileName) then
      Result := Ord(CallHtmlHelp(FileName, HH_HELP_CONTEXT, PtrUInt(AInt1)))
    else
      Result := Ord(WinHelpA(HelpWindow, PChar(FileName), HELP_CONTEXT,
                             PtrUInt(AInt1)));
  end
  else
  begin
    // HelpJump: у .hlp - макрос JumpID, у .chm - страница с этим именем
    if IsChm(FileName) then
      Result := Ord(CallHtmlHelp(FileName + '::/' + AStr, HH_DISPLAY_TOPIC, 0))
    else
    begin
      Command := 'JumpID("","' + AStr + '")';
      Result := Ord(WinHelpA(HelpWindow, PChar(FileName), HELP_COMMAND,
                             PtrUInt(PChar(Command))));
    end;
  end;
  if Result = 0 then
    raise Exception.Create(AMethod + ': help file ' + FileName +
                           ' could not be shown');
end;

// ---------------------------------------------------------------------------
//  Clipboard: форматы и данные функциями Windows (номера форматов Windows)
// ---------------------------------------------------------------------------

function ClipboardFormatAt(AIndex: Integer): Integer;
var
  FormatId: UINT;
  FormatIdx: Integer;
begin
  CheckIndex('Format', AIndex, CountClipboardFormats);
  Result := 0;
  if not OpenClipboard(WidgetSet.AppHandle) then
    raise Exception.Create('Format: clipboard is busy');
  try
    FormatId := 0;
    FormatIdx := 0;
    repeat
      FormatId := EnumClipboardFormats(FormatId);
      if FormatId = 0 then
        Break;
      if FormatIdx = AIndex then
      begin
        Result := Integer(FormatId);
        Break;
      end;
      Inc(FormatIdx);
    until False;
  finally
    CloseClipboard;
  end;
end;

function ClipboardGetHandle(AFormat: Integer): Integer;
begin
  if not OpenClipboard(WidgetSet.AppHandle) then
    raise Exception.Create('GetAsHandle: clipboard is busy');
  try
    Result := Integer(PtrInt(GetClipboardData(UINT(AFormat))));
  finally
    CloseClipboard;
  end;
end;

// Как у Delphi: буфер очищается, данные переходят Windows
procedure ClipboardSetHandle(AFormat, AHandle: Integer);
begin
  if not OpenClipboard(WidgetSet.AppHandle) then
    raise Exception.Create('SetAsHandle: clipboard is busy');
  try
    EmptyClipboard;
    if SetClipboardData(UINT(AFormat), THandle(PtrInt(AHandle))) = 0 then
      raise Exception.Create('SetAsHandle: SetClipboardData failed, error ' +
                             IntToStr(GetLastError));
  finally
    CloseClipboard;
  end;
end;

// ---------------------------------------------------------------------------
//  Функции для rqlclcore
// ---------------------------------------------------------------------------

function AddGetInt(AObj: TObject; const AProp: string;
                   out AValue: Integer): Boolean;
var
  Prop: string;
begin
  Result := False;
  AValue := 0;
  Prop := UpperCase(AProp);
  if (AObj is TPopupMenu) and (Prop = 'WINDOWHANDLE') then
  begin
    // не задан - окно, которому LCL отдаёт команды меню
    AValue := HolderOf(TComponent(AObj), 'WindowHandle').Value;
    if AValue = 0 then
      AValue := Integer(PtrInt(WidgetSet.AppHandle));
    Result := True;
  end
  // QEDIT.IsMasked: у LCL public, не в RTTI
  else if (AObj is TMaskEdit) and (Prop = 'ISMASKED') then
  begin
    AValue := Ord(TMaskEdit(AObj).IsMasked);
    Result := True;
  end
  else if (AObj is TCustomImageList) and (Prop = 'HANDLE') then
  begin
    AValue := Integer(PtrInt(TCustomImageList(AObj).Reference[
                TCustomImageList(AObj).Width].Handle));
    Result := True;
  end;
end;

function AddSetInt(AObj: TObject; const AProp: string;
                   AValue: Integer): Boolean;
var
  Prop: string;
  ResStream: TStream;
begin
  Result := False;
  Prop := UpperCase(AProp);
  if (AObj is TPopupMenu) and (Prop = 'WINDOWHANDLE') then
  begin
    HolderOf(TComponent(AObj), 'WindowHandle').Value := AValue;
    Result := True;
  end
  else if (AObj is TCustomImageList) and (Prop = 'HANDLE') then
    raise Exception.Create('QIMAGELIST.Handle is read-only in RqLcl')
  // Application.IcoHandle = ресурс $RESOURCE с файлом .ico
  else if (AObj is TApplication) and (Prop = 'ICOHANDLE') then
  begin
    ResStream := MiscResourceStream(AValue);
    if ResStream = nil then
      raise Exception.Create('IcoHandle: no resource ' + IntToStr(AValue));
    try
      Application.Icon.LoadFromStream(ResStream);
    finally
      ResStream.Free;
    end;
    Result := True;
  end;
end;

function AddGetStr(AObj: TObject; const AProp: string;
                   out AValue: string): Boolean;
begin
  Result := False;
  AValue := '';
  if (AObj is TCustomEdit) and (UpperCase(AProp) = 'PASSWORDCHAR') then
  begin
    if TCustomEdit(AObj).PasswordChar <> #0 then
      AValue := TCustomEdit(AObj).PasswordChar;
    Result := True;
  end
  // QEDIT.EditText: текст с символами маски (у LCL public)
  else if (AObj is TMaskEdit) and (UpperCase(AProp) = 'EDITTEXT') then
  begin
    AValue := UTF8ToWinCP(TMaskEdit(AObj).EditText);
    Result := True;
  end;
end;

// PasswordChar: первая буква строки, "" - текст виден
function AddSetStr(AObj: TObject; const AProp: string;
                   const AValue: string): Boolean;
begin
  Result := False;
  if (AObj is TCustomEdit) and (UpperCase(AProp) = 'PASSWORDCHAR') then
  begin
    if AValue = '' then
      TCustomEdit(AObj).PasswordChar := #0
    else
      TCustomEdit(AObj).PasswordChar := AValue[1];
    Result := True;
  end
  else if (AObj is TMaskEdit) and (UpperCase(AProp) = 'EDITTEXT') then
  begin
    TMaskEdit(AObj).EditText := WinCPToUTF8(AValue);
    Result := True;
  end;
end;

function AddGetItem(AObj: TObject; const AProp: string; AIndex: Integer;
                    out AValue: string): Boolean;
begin
  Result := False;
  AValue := '';
  if (AObj is TRqStringGrid) and (UpperCase(AProp) = 'COLUMNLIST') then
  begin
    AValue := TRqStringGrid(AObj).GetColumnList(AIndex);
    Result := True;
  end;
end;

function AddSetItem(AObj: TObject; const AProp: string; AIndex: Integer;
                    const AValue: string): Boolean;
begin
  Result := False;
  if (AObj is TRqStringGrid) and (UpperCase(AProp) = 'COLUMNLIST') then
  begin
    TRqStringGrid(AObj).SetColumnList(AIndex, AValue);
    Result := True;
  end;
end;

function AddGetItemInt(AObj: TObject; const AProp: string; AIndex: Integer;
                       out AValue: Integer): Boolean;
var
  Prop: string;
begin
  Result := False;
  AValue := 0;
  Prop := UpperCase(AProp);
  if AObj is TRqStringGrid then
  begin
    Result := True;
    if Prop = 'COLUMNSTYLE' then
      AValue := TRqStringGrid(AObj).GetColumnStyle(AIndex)
    else if Prop = 'TABSTOPS' then
      AValue := TRqStringGrid(AObj).GetTabStop(AIndex)
    else
      Result := False;
  end
  else if (AObj is TClipboard) and (Prop = 'FORMAT') then
  begin
    AValue := ClipboardFormatAt(AIndex);
    Result := True;
  end;
end;

function AddSetItemInt(AObj: TObject; const AProp: string; AIndex: Integer;
                       AValue: Integer): Boolean;
var
  Prop: string;
begin
  Result := False;
  Prop := UpperCase(AProp);
  if AObj is TRqStringGrid then
  begin
    Result := True;
    if Prop = 'COLUMNSTYLE' then
      TRqStringGrid(AObj).SetColumnStyle(AIndex, AValue)
    else if Prop = 'TABSTOPS' then
      TRqStringGrid(AObj).SetTabStop(AIndex, AValue)
    else
      Result := False;
  end
  else if (AObj is TClipboard) and (Prop = 'FORMAT') then
    raise Exception.Create('Clipboard.Format is read-only in RqLcl');
end;

function AddCallEx(AObj: TObject; const AMethod, AStr: string;
                   AInt1, AInt2, AInt3: Integer;
                   out AIntResult: Integer): Boolean;
var
  Method: string;
  Form: TCustomForm;
begin
  Result := False;
  AIntResult := 1;
  Method := UpperCase(AMethod);
  if AObj is TCustomForm then
  begin
    Form := TCustomForm(AObj);
    Result := True;
    if Method = 'ADDBORDERICON' then
      Form.BorderIcons := Form.BorderIcons + [BorderIconOf(AInt1)]
    else if Method = 'DELBORDERICON' then
      Form.BorderIcons := Form.BorderIcons - [BorderIconOf(AInt1)]
    else if Method = 'HIDETITLEBAR' then
      SetTitleBar(Form, False)
    else if Method = 'SHOWTITLEBAR' then
      SetTitleBar(Form, True)
    // AStr - файл .bmp; "" - ресурс AInt1; AInt2 - прозрачный цвет
    else if Method = 'SHAPEFORM' then
      ShapeForm(Form, AStr, AInt1, TColor(AInt2))
    else
      Result := False;
  end
  else if (AObj is TControl) and (Method = 'STARTDRAG') then
  begin
    StartDrag(TControl(AObj));
    Result := True;
  end
  else if (AObj is TApplication) and ((Method = 'HELPCOMMAND') or
          (Method = 'HELPCONTEXT') or (Method = 'HELPJUMP')) then
  begin
    AIntResult := HelpCall(Method, AStr, AInt1, AInt2);
    Result := True;
  end
  else if AObj is TClipboard then
  begin
    Result := True;
    if Method = 'GETASHANDLE' then
      AIntResult := ClipboardGetHandle(AInt1)
    else if Method = 'SETASHANDLE' then
      ClipboardSetHandle(AInt1, AInt2)
    else
      Result := False;
  end;
end;

end.
