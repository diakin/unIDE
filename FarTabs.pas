unit FarTabs;

// ---------------------------------------------------------------------------
//  Вкладки папок над панелями uniFAR (FarApp): верхняя строка - вкладки
//  (шрифт 8 пт), под ней - строка с полным путём выбранной вкладки (шрифтом
//  панелей).
//
//  Самая левая вкладка - папка активной панели. За ней - последние папки
//  из истории папок (Alt+F12), сначала самые свежие, без повторов и без
//  папки активной панели; всего не больше MaxTabs.
//
//  Клавиши (их передаёт цикл сообщений FarApp, пока фокус в окне FAR):
//    Alt+Left / Alt+Right - курсор на вкладку активной панели (самую
//      левую), дальше - на соседнюю вкладку; активная панель сразу
//      переходит в папку вкладки. В режиме вкладок - и Left / Right без Alt.
//    Enter - на вкладке активной панели: её папка - в историю папок; на
//      другой вкладке - остаться в её папке. Режим вкладок кончается.
//    Del - убрать вкладку из списка (папку - из истории; закреплённую в
//      истории, Alt+F12 - Ins, не убирает).
//    Esc - выйти из режима вкладок; остальные клавиши - тоже, и клавиша
//      уходит панели.
//  Мышь: щелчок по вкладке - то же, что переход на неё; крестик - убрать.
//
//  Пока ходят по вкладкам, список не меняется (снимок при входе в режим),
//  и переходы не пишутся в историю (TFarView.HistoryPaused). Когда режим
//  кончается в другой папке, она пишется в историю как обычный переход.
//
//  Окно строится без LCL и VCL-форм: TCustomControl (в uniFAR - из
//  uniFAR\vcl\Controls). Текст - Unicode (DrawTextW).
// ---------------------------------------------------------------------------

{$IFDEF FPC}{$MODE DELPHI}{$CODEPAGE CP1251}{$ENDIF}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, UnFar;

type
  TFarTabBar = class(TCustomControl)
  private
    FView: TFarView;
    FModeOn: Boolean;          // курсор на вкладках (Alt+стрелка, щелчок)
    FSel: Integer;             // выбранная вкладка в режиме вкладок
    FSnapshot: TFarNames;      // список вкладок, пока режим включён
    FStartPath: WideString;    // папка активной панели при входе в режим
    FMaxTabs: Integer;
    FTabFont: HFONT;
    FTabTextH: Integer;
    FBuffer: TBitmap;
    FTabRects: array of TRect;
    FCloseRects: array of TRect;
    procedure CreateTabFont;
    function TabHeight: Integer;
    procedure CurrentTabs(var ATabs: TFarNames);
    function TabCaption(const APath: WideString): WideString;
    procedure GoToTab(AIndex: Integer);
    procedure RemoveTab(AIndex: Integer);
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent; AView: TFarView); reintroduce;
    destructor Destroy; override;
    // Высота полосы: вкладки + строка пути (шрифт панелей)
    function BarHeight: Integer;
    // Клавиша из цикла сообщений (WM_KEYDOWN / WM_SYSKEYDOWN окна FAR).
    // True - разобрана, панели не отдавать
    function HandleKey(AKey: Word): Boolean;
    procedure EnterMode;
    procedure LeaveMode;
    property ModeOn: Boolean read FModeOn;
    property MaxTabs: Integer read FMaxTabs write FMaxTabs;
  end;

implementation

const
  TabFontPt = 8;
  TabFontFace = 'Tahoma';
  TabPadX = 8;            // поля текста во вкладке
  TabGap = 2;             // между вкладками
  CloseW = 14;            // место под крестик
  TabMinW = 48;
  CloseMark: WideChar = WideChar($00D7);   // крестик (знак умножения)

type
  TTabSize = record
    cx: Longint;
    cy: Longint;
  end;

// W-функции - свои объявления (одинаково в Delphi 7 и Free Pascal)
function TabDrawText(ADC: HDC; AText: PWideChar; ACount: Integer;
  var ARect: TRect; AFormat: UINT): Integer; stdcall;
  external 'user32.dll' name 'DrawTextW';
function TabTextExtent(ADC: HDC; AText: PWideChar; ACount: Integer;
  var ASize: TTabSize): BOOL; stdcall;
  external 'gdi32.dll' name 'GetTextExtentPoint32W';
function TabFileAttr(AFileName: PWideChar): DWORD; stdcall;
  external 'kernel32.dll' name 'GetFileAttributesW';

function TabSameName(const AFirst, ASecond: WideString): Boolean;
var
  First, Second: WideString;
begin
  First := AFirst;
  Second := ASecond;
  if (Length(First) > 3) and (First[Length(First)] = '\') then
    SetLength(First, Length(First) - 1);
  if (Length(Second) > 3) and (Second[Length(Second)] = '\') then
    SetLength(Second, Length(Second) - 1);
  Result := WideUpperCase(First) = WideUpperCase(Second);
end;

function TabDirExists(const APath: WideString): Boolean;
var
  Attr: DWORD;
begin
  Attr := TabFileAttr(PWideChar(APath));
  Result := (Attr <> $FFFFFFFF) and (Attr and FILE_ATTRIBUTE_DIRECTORY <> 0);
end;

{ TFarTabBar }

constructor TFarTabBar.Create(AOwner: TComponent; AView: TFarView);
begin
  inherited Create(AOwner);
  FView := AView;
  FMaxTabs := 10;
  FSel := 0;
  FBuffer := TBitmap.Create;
  CreateTabFont;
end;

destructor TFarTabBar.Destroy;
begin
  if FTabFont <> 0 then
    DeleteObject(FTabFont);
  FBuffer.Free;
  inherited Destroy;
end;

procedure TFarTabBar.CreateTabFont;
var
  ScreenDC: HDC;
  OldFont: HGDIOBJ;
  Metrics: TTextMetric;
begin
  ScreenDC := GetDC(0);
  try
    FTabFont := CreateFont(-MulDiv(TabFontPt, GetDeviceCaps(ScreenDC,
      LOGPIXELSY), 72), 0, 0, 0, FW_NORMAL, 0, 0, 0, DEFAULT_CHARSET,
      OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY,
      DEFAULT_PITCH or FF_SWISS, TabFontFace);
    OldFont := SelectObject(ScreenDC, FTabFont);
    GetTextMetrics(ScreenDC, Metrics);
    FTabTextH := Metrics.tmHeight;
    SelectObject(ScreenDC, OldFont);
  finally
    ReleaseDC(0, ScreenDC);
  end;
  if FTabTextH < 8 then
    FTabTextH := 13;
end;

function TFarTabBar.TabHeight: Integer;
begin
  Result := FTabTextH + 7;
end;

function TFarTabBar.BarHeight: Integer;
var
  PathH: Integer;
begin
  PathH := 16;
  if (FView <> nil) and (FView.CellHeight > 0) then
    PathH := FView.CellHeight;
  Result := TabHeight + PathH;
end;

// Вкладки сейчас: в режиме - снимок; иначе папка активной панели и
// свежие папки истории
procedure TFarTabBar.CurrentTabs(var ATabs: TFarNames);
var
  HistIdx, TabIdx, Count: Integer;
  Path: WideString;
  Dup: Boolean;
begin
  if FModeOn then
  begin
    ATabs := Copy(FSnapshot, 0, Length(FSnapshot));
    Exit;
  end;
  SetLength(ATabs, 1);
  ATabs[0] := FView.ActivePath;
  Count := 1;
  for HistIdx := FView.HistoryCount - 1 downto 0 do
  begin
    if Count >= FMaxTabs then
      Break;
    Path := FView.HistoryItem(HistIdx);
    if Path = '' then
      Continue;
    Dup := False;
    for TabIdx := 0 to Count - 1 do
      if TabSameName(ATabs[TabIdx], Path) then
      begin
        Dup := True;
        Break;
      end;
    if Dup then
      Continue;
    SetLength(ATabs, Count + 1);
    ATabs[Count] := Path;
    Inc(Count);
  end;
end;

function TFarTabBar.TabCaption(const APath: WideString): WideString;
var
  Path: WideString;
  CharIdx: Integer;
begin
  Path := APath;
  if (Length(Path) > 3) and (Path[Length(Path)] = '\') then
    SetLength(Path, Length(Path) - 1);
  // Корень диска - «D:»
  if (Length(Path) <= 3) and (Length(Path) >= 2) and (Path[2] = ':') then
  begin
    Result := Copy(Path, 1, 2);
    Exit;
  end;
  CharIdx := Length(Path);
  while (CharIdx > 0) and (Path[CharIdx] <> '\') and (Path[CharIdx] <> '/') do
    Dec(CharIdx);
  Result := Copy(Path, CharIdx + 1, MaxInt);
  if Result = '' then
    Result := Path;
end;

procedure TFarTabBar.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TFarTabBar.Paint;
var
  Tabs: TFarNames;
  Pal: TFarPalette;
  DrawDC: HDC;
  OldFont: HGDIOBJ;
  TabIdx, TabCount, TabX, TabW, MaxW, TextW, TabH, PathH, PathY: Integer;
  Widths: array of Integer;
  TotalW: Integer;
  Caption, PathText: WideString;
  TextSize: TTabSize;
  TextRect, TabRect: TRect;
  Selected: Boolean;
  BackColor, TextColor: TColor;
  FrameBrush, FillBrush: HBRUSH;
begin
  if FView = nil then
    Exit;
  if (FBuffer.Width <> ClientWidth) or (FBuffer.Height <> ClientHeight) then
  begin
    FBuffer.Width := ClientWidth;
    FBuffer.Height := ClientHeight;
  end;
  Pal := FView.Palette;
  CurrentTabs(Tabs);
  TabCount := Length(Tabs);
  TabH := TabHeight;
  PathH := ClientHeight - TabH;
  DrawDC := FBuffer.Canvas.Handle;

  // Фон полосы вкладок
  FillBrush := CreateSolidBrush(ColorToRGB(Pal[fpCmdBack]));
  TextRect := Rect(0, 0, ClientWidth, TabH);
  FillRect(DrawDC, TextRect, FillBrush);
  DeleteObject(FillBrush);

  // Ширины: по тексту; не помещаются - поровну
  OldFont := SelectObject(DrawDC, FTabFont);
  SetLength(Widths, TabCount);
  TotalW := 0;
  for TabIdx := 0 to TabCount - 1 do
  begin
    Caption := TabCaption(Tabs[TabIdx]);
    TextSize.cx := 0;
    TextSize.cy := 0;
    if Caption <> '' then
      TabTextExtent(DrawDC, PWideChar(Caption), Length(Caption), TextSize);
    TextW := TextSize.cx + 2 * TabPadX;
    if TabIdx > 0 then
      Inc(TextW, CloseW);
    if TextW < TabMinW then
      TextW := TabMinW;
    Widths[TabIdx] := TextW;
    Inc(TotalW, TextW + TabGap);
  end;
  if (TabCount > 0) and (TotalW > ClientWidth - 4) then
  begin
    MaxW := (ClientWidth - 4) div TabCount - TabGap;
    if MaxW < 24 then
      MaxW := 24;
    for TabIdx := 0 to TabCount - 1 do
      if Widths[TabIdx] > MaxW then
        Widths[TabIdx] := MaxW;
  end;

  SetLength(FTabRects, TabCount);
  SetLength(FCloseRects, TabCount);
  SetBkMode(DrawDC, TRANSPARENT);
  TabX := 2;
  for TabIdx := 0 to TabCount - 1 do
  begin
    TabW := Widths[TabIdx];
    TabRect := Rect(TabX, 2, TabX + TabW, TabH);
    FTabRects[TabIdx] := TabRect;
    Selected := FModeOn and (TabIdx = FSel);
    if Selected then
    begin
      BackColor := Pal[fpPanelCursorBack];
      TextColor := Pal[fpPanelCursorText];
    end
    else
    begin
      BackColor := Pal[fpPanelBack];
      if TabIdx = 0 then
        TextColor := Pal[fpPanelHeader]
      else
        TextColor := Pal[fpPanelText];
    end;
    FillBrush := CreateSolidBrush(ColorToRGB(BackColor));
    FillRect(DrawDC, TabRect, FillBrush);
    DeleteObject(FillBrush);
    FrameBrush := CreateSolidBrush(ColorToRGB(Pal[fpPanelFrame]));
    FrameRect(DrawDC, TabRect, FrameBrush);
    DeleteObject(FrameBrush);
    SetTextColor(DrawDC, ColorToRGB(TextColor));
    Caption := TabCaption(Tabs[TabIdx]);
    TextRect := Rect(TabX + TabPadX, 2, TabX + TabW - TabPadX, TabH);
    if TabIdx > 0 then
    begin
      Dec(TextRect.Right, CloseW - 4);
      FCloseRects[TabIdx] := Rect(TabX + TabW - CloseW - 2, 2,
        TabX + TabW - 2, TabH);
      TabDrawText(DrawDC, @CloseMark, 1, FCloseRects[TabIdx],
        DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
    end
    else
      FCloseRects[TabIdx] := Rect(0, 0, 0, 0);
    if Caption <> '' then
      TabDrawText(DrawDC, PWideChar(Caption), Length(Caption), TextRect,
        DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX or
        DT_END_ELLIPSIS);
    Inc(TabX, TabW + TabGap);
  end;
  SelectObject(DrawDC, OldFont);

  // Строка пути: выбранная вкладка (не в режиме - активная панель)
  PathY := TabH;
  FillBrush := CreateSolidBrush(ColorToRGB(Pal[fpPanelBack]));
  TextRect := Rect(0, PathY, ClientWidth, PathY + PathH);
  FillRect(DrawDC, TextRect, FillBrush);
  DeleteObject(FillBrush);
  PathText := '';
  if FModeOn and (FSel >= 0) and (FSel < TabCount) then
    PathText := Tabs[FSel]
  else if TabCount > 0 then
    PathText := Tabs[0];
  if (Length(PathText) > 3) and (PathText[Length(PathText)] = '\') then
    SetLength(PathText, Length(PathText) - 1);
  if PathText <> '' then
  begin
    PathText := ' ' + PathText;
    if FView.MainFont <> 0 then
      OldFont := SelectObject(DrawDC, FView.MainFont)
    else
      OldFont := SelectObject(DrawDC, FTabFont);
    SetTextColor(DrawDC, ColorToRGB(Pal[fpPanelHeader]));
    TabDrawText(DrawDC, PWideChar(PathText), Length(PathText), TextRect,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX or
      DT_PATH_ELLIPSIS);
    SelectObject(DrawDC, OldFont);
  end;
  Canvas.Draw(0, 0, FBuffer);
end;

procedure TFarTabBar.EnterMode;
begin
  if FModeOn or (FView = nil) or not FView.TabsAllowed then
    Exit;
  CurrentTabs(FSnapshot);
  FStartPath := FView.ActivePath;
  FModeOn := True;
  FSel := 0;
  FView.HistoryPaused := True;
  Invalidate;
end;

procedure TFarTabBar.LeaveMode;
var
  NowPath: WideString;
begin
  if not FModeOn then
    Exit;
  FModeOn := False;
  FView.HistoryPaused := False;
  // Остались в другой папке - она в историю, как обычный переход
  NowPath := FView.ActivePath;
  if (NowPath <> '') and not TabSameName(NowPath, FStartPath) then
    FView.HistoryAddPath(NowPath);
  SetLength(FSnapshot, 0);
  Invalidate;
end;

procedure TFarTabBar.GoToTab(AIndex: Integer);
var
  Path: WideString;
begin
  if (AIndex < 0) or (AIndex > High(FSnapshot)) then
    Exit;
  FSel := AIndex;
  Path := FSnapshot[AIndex];
  if not TabSameName(Path, FView.ActivePath) then
  begin
    if TabDirExists(Path) then
      FView.ShowFolder(Path)
    else
      FView.StatusText(FarProduct + ': папки нет - ' + string(Path) +
        ' (Del - убрать вкладку)');
  end;
  Invalidate;
end;

procedure TFarTabBar.RemoveTab(AIndex: Integer);
var
  Tabs: TFarNames;
  Path: WideString;
  Removed, TabIdx: Integer;
begin
  CurrentTabs(Tabs);
  if (AIndex < 0) or (AIndex > High(Tabs)) then
    Exit;
  Path := Tabs[AIndex];
  Removed := FView.HistoryRemovePath(Path);
  if Removed < 0 then
  begin
    FView.StatusText(FarProduct + ': папка закреплена в истории (Alt+F12, ' +
      'Ins - открепить)');
    Exit;
  end;
  if AIndex = 0 then
  begin
    // Вкладка активной панели остаётся: убрана только запись истории
    if Removed = 0 then
      FView.StatusText(FarProduct + ': этой папки в истории нет');
    Invalidate;
    Exit;
  end;
  if FModeOn then
  begin
    for TabIdx := AIndex to High(FSnapshot) - 1 do
      FSnapshot[TabIdx] := FSnapshot[TabIdx + 1];
    SetLength(FSnapshot, Length(FSnapshot) - 1);
    if FSel = AIndex then
    begin
      if FSel > High(FSnapshot) then
        FSel := High(FSnapshot);
      GoToTab(FSel);
    end
    else if FSel > AIndex then
      Dec(FSel);
  end;
  Invalidate;
end;

function TFarTabBar.HandleKey(AKey: Word): Boolean;
var
  ShiftDown, CtrlDown, AltDown: Boolean;
begin
  Result := False;
  if FView = nil then
    Exit;
  ShiftDown := GetKeyState(VK_SHIFT) < 0;
  CtrlDown := GetKeyState(VK_CONTROL) < 0;
  AltDown := GetKeyState(VK_MENU) < 0;
  if not FModeOn then
  begin
    // Alt+Left / Alt+Right - курсор на вкладку активной панели
    if AltDown and not CtrlDown and not ShiftDown and
       ((AKey = VK_LEFT) or (AKey = VK_RIGHT)) and FView.TabsAllowed then
    begin
      EnterMode;
      Result := FModeOn;
    end;
    Exit;
  end;
  // Режим вкладок: панель могла смениться (диалог, редактор) - выйти
  if not FView.TabsAllowed then
  begin
    LeaveMode;
    Exit;
  end;
  Result := True;
  case AKey of
    VK_SHIFT, VK_CONTROL, VK_MENU:
      ;  // клавиши-модификаторы режим не прерывают
    VK_LEFT:
      if Length(FSnapshot) > 0 then
        GoToTab((FSel - 1 + Length(FSnapshot)) mod Length(FSnapshot));
    VK_RIGHT:
      if Length(FSnapshot) > 0 then
        GoToTab((FSel + 1) mod Length(FSnapshot));
    VK_HOME:
      GoToTab(0);
    VK_END:
      GoToTab(High(FSnapshot));
    VK_RETURN:
      begin
        if FSel = 0 then
        begin
          FView.HistoryAddPath(FView.ActivePath);
          FView.StatusText(FarProduct + ': папка добавлена в историю - ' +
            string(FView.ActivePath));
        end;
        LeaveMode;
      end;
    VK_DELETE:
      RemoveTab(FSel);
    VK_ESCAPE:
      LeaveMode;
  else
    // Другая клавиша - режим кончается, клавиша уходит панели
    LeaveMode;
    Result := False;
  end;
end;

procedure TFarTabBar.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  TabIdx: Integer;
  ClickPt: TPoint;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (FView = nil) or (Button <> mbLeft) then
    Exit;
  ClickPt := Point(X, Y);
  for TabIdx := 0 to High(FTabRects) do
    if PtInRect(FTabRects[TabIdx], ClickPt) then
    begin
      if (TabIdx > 0) and PtInRect(FCloseRects[TabIdx], ClickPt) then
        RemoveTab(TabIdx)
      else if FView.TabsAllowed then
      begin
        if not FModeOn then
          EnterMode;
        GoToTab(TabIdx);
      end;
      Break;
    end;
  if FView.HandleAllocated then
    Windows.SetFocus(FView.Handle);
  Invalidate;
end;

end.
