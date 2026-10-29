unit FarTabs;

// ---------------------------------------------------------------------------
//  Вкладки папок над панелями uniFAR (FarApp): строка вкладок шрифтом 8 пт.
//
//  Самая левая вкладка - папка активной панели. За ней - список вкладок
//  (свой, хранится в uniFAR.ini [FolderTabs]) без папки активной панели;
//  сколько поместится по ширине окна. Списка ещё нет (первый запуск) - в
//  него берутся последние папки истории папок (Alt+F12). Дальше история
//  на список не влияет: в список добавляет Enter, убирает Del.
//  Цвета - палитра FAR, группа «Вкладки» (F9 - Options - Colors).
//
//  Клавиши (их передаёт цикл сообщений FarApp, пока фокус в окне FAR):
//    Alt+Left / Alt+Right - курсор на вкладку активной панели (самую
//      левую), дальше - на соседнюю вкладку; активная панель сразу
//      переходит в папку вкладки. В режиме вкладок - и Left / Right без Alt.
//    Enter - на вкладке активной панели: её папка - в список вкладок
//      (первой); на другой вкладке - остаться в её папке. Режим вкладок
//      кончается.
//    Del - убрать вкладку из списка (история папок не меняется).
//    Esc - выйти из режима вкладок; остальные клавиши - тоже, и клавиша
//      уходит панели.
//  Мышь: вкладка под мышью подсвечивается, активная панель показывает её
//  папку (просмотр). Щелчок - остаться в этой папке; мышь ушла с полосы
//  без щелчка - панель возвращается в прежнюю папку. Крестик - убрать.
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
    FModeOn: Boolean;          // курсор на вкладках (Alt+стрелка, мышь)
    FHoverMode: Boolean;       // режим включила мышь: ушла - вернуться
    FHoverIdx: Integer;        // вкладка под мышью (-1 - нет)
    FTracking: Boolean;        // TrackMouseEvent: ждём WM_MOUSELEAVE
    FSel: Integer;             // выбранная вкладка в режиме вкладок
    FSnapshot: TFarNames;      // список вкладок, пока режим включён
    FStartPath: WideString;    // папка активной панели при входе в режим
    FStartItem: WideString;    // и имя под курсором (вернуться на него)
    FMaxTabs: Integer;
    FList: TFarNames;          // список вкладок (без вкладки активной панели)
    FIniName: string;          // где хранится список
    FTabFont: HFONT;
    FTabTextH: Integer;
    FBuffer: TBitmap;
    FTabRects: array of TRect;
    FCloseRects: array of TRect;
    procedure CreateTabFont;
    function TabHeight: Integer;
    procedure CurrentTabs(var ATabs: TFarNames);
    function TabWidth(ADC: HDC; const APath: WideString;
      AIndex: Integer): Integer;
    function TabAt(AX, AY: Integer): Integer;
    procedure CancelHover;
    function TabCaption(const APath: WideString): WideString;
    procedure GoToTab(AIndex: Integer);
    procedure RemoveTab(AIndex: Integer);
    function ListFind(const APath: WideString): Integer;
    procedure ListDelete(AIndex: Integer);
    procedure ListAddFirst(const APath: WideString);
    procedure SaveList;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMMouseLeave(var Message: TMessage); message $02A3;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent; AView: TFarView); reintroduce;
    destructor Destroy; override;
    // Высота полосы вкладок
    function BarHeight: Integer;
    // Клавиша из цикла сообщений (WM_KEYDOWN / WM_SYSKEYDOWN окна FAR).
    // True - разобрана, панели не отдавать
    function HandleKey(AKey: Word): Boolean;
    procedure EnterMode;
    procedure LeaveMode;
    // Список вкладок из uniFAR.ini [FolderTabs]; нет раздела - последние
    // папки истории (звать после TFarView.LoadState)
    procedure LoadList(const AIniName: string);
    property ModeOn: Boolean read FModeOn;
    property MaxTabs: Integer read FMaxTabs write FMaxTabs;
  end;

implementation

uses
  IniBuf;

const
  TabFontPt = 8;
  TabFontFace = 'Tahoma';
  TabPadX = 8;            // поля текста во вкладке
  TabGap = 2;             // между вкладками
  CloseW = 14;            // место под крестик
  TabMinW = 48;
  TabMaxW = 220;          // длинное имя - с многоточием
  TabMaxCount = 50;       // длина списка вкладок
  TabSection = 'FolderTabs';
  TabFirstFromHistory = 10;   // первый запуск: столько папок из истории
  CloseMark: WideChar = WideChar($00D7);   // крестик (знак умножения)

type
  TTabSize = record
    cx: Longint;
    cy: Longint;
  end;
  TTabTrackMouse = record
    cbSize: DWORD;
    dwFlags: DWORD;
    hwndTrack: HWND;
    dwHoverTime: DWORD;
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
function TabTrackMouseEvent(var AEvent: TTabTrackMouse): BOOL; stdcall;
  external 'user32.dll' name 'TrackMouseEvent';

const
  TabTmeLeave = $00000002;

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
  FMaxTabs := TabMaxCount;
  FSel := 0;
  FHoverIdx := -1;
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
begin
  Result := TabHeight + 2;
end;

// Ширина вкладки по тексту (с полями и крестиком)
function TFarTabBar.TabWidth(ADC: HDC; const APath: WideString;
  AIndex: Integer): Integer;
var
  Caption: WideString;
  TextSize: TTabSize;
begin
  Caption := TabCaption(APath);
  TextSize.cx := 0;
  TextSize.cy := 0;
  if Caption <> '' then
    TabTextExtent(ADC, PWideChar(Caption), Length(Caption), TextSize);
  Result := TextSize.cx + 2 * TabPadX;
  if AIndex > 0 then
    Inc(Result, CloseW);
  if Result < TabMinW then
    Result := TabMinW;
  if Result > TabMaxW then
    Result := TabMaxW;
end;

// Вкладки сейчас: в режиме - снимок; иначе папка активной панели и
// свежие папки истории
procedure TFarTabBar.CurrentTabs(var ATabs: TFarNames);
var
  ListIdx, Count, UsedW, NextW: Integer;
  Path: WideString;
  MeasureDC: HDC;
  OldFont: HGDIOBJ;
begin
  if FModeOn then
  begin
    ATabs := Copy(FSnapshot, 0, Length(FSnapshot));
    Exit;
  end;
  SetLength(ATabs, 1);
  ATabs[0] := FView.ActivePath;
  Count := 1;
  // Сколько поместится по ширине окна
  MeasureDC := GetDC(0);
  OldFont := SelectObject(MeasureDC, FTabFont);
  try
    UsedW := 2 + TabWidth(MeasureDC, ATabs[0], 0) + TabGap;
    for ListIdx := 0 to High(FList) do
    begin
      Path := FList[ListIdx];
      if (Path = '') or TabSameName(Path, ATabs[0]) then
        Continue;
      NextW := TabWidth(MeasureDC, Path, Count);
      if UsedW + NextW > ClientWidth - 2 then
        Break;
      Inc(UsedW, NextW + TabGap);
      SetLength(ATabs, Count + 1);
      ATabs[Count] := Path;
      Inc(Count);
    end;
  finally
    SelectObject(MeasureDC, OldFont);
    ReleaseDC(0, MeasureDC);
  end;
end;

function TFarTabBar.ListFind(const APath: WideString): Integer;
begin
  Result := High(FList);
  while (Result >= 0) and not TabSameName(FList[Result], APath) do
    Dec(Result);
end;

procedure TFarTabBar.ListDelete(AIndex: Integer);
var
  ListIdx: Integer;
begin
  if (AIndex < 0) or (AIndex > High(FList)) then
    Exit;
  for ListIdx := AIndex to High(FList) - 1 do
    FList[ListIdx] := FList[ListIdx + 1];
  SetLength(FList, Length(FList) - 1);
end;

// Папка - первой в списке (была в нём - переезжает вперёд)
procedure TFarTabBar.ListAddFirst(const APath: WideString);
var
  ListIdx: Integer;
begin
  if APath = '' then
    Exit;
  ListDelete(ListFind(APath));
  SetLength(FList, Length(FList) + 1);
  for ListIdx := High(FList) downto 1 do
    FList[ListIdx] := FList[ListIdx - 1];
  FList[0] := APath;
  if Length(FList) > FMaxTabs then
    SetLength(FList, FMaxTabs);
end;

procedure TFarTabBar.LoadList(const AIniName: string);
var
  Ini: TBufIniFile;
  Count, ListIdx, HistIdx: Integer;
  Path: WideString;
begin
  FIniName := AIniName;
  SetLength(FList, 0);
  if AIniName = '' then
    Exit;
  Ini := TBufIniFile.Create(AIniName);
  try
    Count := Ini.ReadInteger(TabSection, 'Count', -1);
    if Count >= 0 then
    begin
      if Count > FMaxTabs then
        Count := FMaxTabs;
      for ListIdx := 1 to Count do
      begin
        Path := FarDecodePath(Ini.ReadString(TabSection,
          'Tab' + IntToStr(ListIdx), ''));
        if (Path <> '') and (ListFind(Path) < 0) then
        begin
          SetLength(FList, Length(FList) + 1);
          FList[High(FList)] := Path;
        end;
      end;
      Exit;
    end;
  finally
    Ini.Free;
  end;
  // Первый запуск: последние папки истории, свежие первыми
  for HistIdx := FView.HistoryCount - 1 downto 0 do
  begin
    if Length(FList) >= TabFirstFromHistory then
      Break;
    Path := FView.HistoryItem(HistIdx);
    if (Path <> '') and (ListFind(Path) < 0) then
    begin
      SetLength(FList, Length(FList) + 1);
      FList[High(FList)] := Path;
    end;
  end;
  SaveList;
end;

procedure TFarTabBar.SaveList;
var
  Ini: TBufIniFile;
  ListIdx: Integer;
begin
  if FIniName = '' then
    Exit;
  Ini := TBufIniFile.Create(FIniName);
  try
    Ini.EraseSection(TabSection);
    Ini.WriteInteger(TabSection, 'Count', Length(FList));
    for ListIdx := 0 to High(FList) do
      Ini.WriteString(TabSection, 'Tab' + IntToStr(ListIdx + 1),
        FarEncodePath(FList[ListIdx]));
  finally
    Ini.Free;
  end;
end;

// Подпись вкладки: «D:\» - корень, «D:\папка» - папка в корне, глубже -
// «D:\..\папка». Сетевой путь - «\\сервер\..\папка»; FTP, архив - имя
// после последнего / или \
function TFarTabBar.TabCaption(const APath: WideString): WideString;
var
  Path, Root, Name: WideString;
  CharIdx, RootLen: Integer;
begin
  Path := APath;
  if (Length(Path) > 3) and ((Path[Length(Path)] = '\') or
     (Path[Length(Path)] = '/')) then
    SetLength(Path, Length(Path) - 1);
  // Корень пути: «D:\» или «\\сервер\»; иначе - без корня
  Root := '';
  if (Length(Path) >= 2) and (Path[2] = ':') then
    Root := Copy(Path, 1, 2) + '\'
  else if Copy(Path, 1, 2) = '\\' then
  begin
    CharIdx := 3;
    while (CharIdx <= Length(Path)) and (Path[CharIdx] <> '\') do
      Inc(CharIdx);
    Root := Copy(Path, 1, CharIdx);
    if (Length(Root) > 0) and (Root[Length(Root)] <> '\') then
      Root := Root + '\';
  end;
  RootLen := Length(Root);
  if (Root <> '') and (Length(Path) <= RootLen) then
  begin
    Result := Root;
    Exit;
  end;
  CharIdx := Length(Path);
  while (CharIdx > 0) and (Path[CharIdx] <> '\') and (Path[CharIdx] <> '/') do
    Dec(CharIdx);
  Name := Copy(Path, CharIdx + 1, MaxInt);
  if Name = '' then
    Name := Path;
  if Root = '' then
    Result := Name
  else if CharIdx <= RootLen then
    Result := Root + Name                    // папка прямо в корне
  else
    Result := Root + '..\' + Name;
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
  TabIdx, TabCount, TabX, TabW, TabH: Integer;
  Caption: WideString;
  TextRect, TabRect: TRect;
  Lit: Boolean;
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
  DrawDC := FBuffer.Canvas.Handle;

  // Фон полосы
  FillBrush := CreateSolidBrush(ColorToRGB(Pal[fpTabBarBack]));
  TextRect := Rect(0, 0, ClientWidth, ClientHeight);
  FillRect(DrawDC, TextRect, FillBrush);
  DeleteObject(FillBrush);

  OldFont := SelectObject(DrawDC, FTabFont);
  SetLength(FTabRects, TabCount);
  SetLength(FCloseRects, TabCount);
  SetBkMode(DrawDC, TRANSPARENT);
  TabX := 2;
  for TabIdx := 0 to TabCount - 1 do
  begin
    TabW := TabWidth(DrawDC, Tabs[TabIdx], TabIdx);
    // Первая вкладка шире окна - по ширине окна
    if TabX + TabW > ClientWidth - 2 then
      TabW := ClientWidth - 2 - TabX;
    if TabW < 8 then
    begin
      SetLength(FTabRects, TabIdx);
      SetLength(FCloseRects, TabIdx);
      Break;
    end;
    TabRect := Rect(TabX, 2, TabX + TabW, TabH + 2);
    FTabRects[TabIdx] := TabRect;
    // Подсвечена: под мышью или курсор режима вкладок
    Lit := (FModeOn and (TabIdx = FSel)) or (TabIdx = FHoverIdx);
    if Lit then
    begin
      BackColor := Pal[fpTabSelBack];
      TextColor := Pal[fpTabSelText];
    end
    else
    begin
      BackColor := Pal[fpTabBack];
      if TabIdx = 0 then
        TextColor := Pal[fpTabCurText]
      else
        TextColor := Pal[fpTabText];
    end;
    FillBrush := CreateSolidBrush(ColorToRGB(BackColor));
    FillRect(DrawDC, TabRect, FillBrush);
    DeleteObject(FillBrush);
    FrameBrush := CreateSolidBrush(ColorToRGB(Pal[fpTabFrame]));
    FrameRect(DrawDC, TabRect, FrameBrush);
    DeleteObject(FrameBrush);
    SetTextColor(DrawDC, ColorToRGB(TextColor));
    Caption := TabCaption(Tabs[TabIdx]);
    TextRect := Rect(TabX + TabPadX, TabRect.Top, TabX + TabW - TabPadX,
      TabRect.Bottom);
    if TabIdx > 0 then
    begin
      Dec(TextRect.Right, CloseW - 4);
      FCloseRects[TabIdx] := Rect(TabX + TabW - CloseW - 2, TabRect.Top,
        TabX + TabW - 2, TabRect.Bottom);
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
  Canvas.Draw(0, 0, FBuffer);
end;

function TFarTabBar.TabAt(AX, AY: Integer): Integer;
var
  TabIdx: Integer;
begin
  Result := -1;
  for TabIdx := 0 to High(FTabRects) do
    if PtInRect(FTabRects[TabIdx], Point(AX, AY)) then
    begin
      Result := TabIdx;
      Exit;
    end;
end;

// Мышь ушла с полосы, не щёлкнув: просмотр кончился - панель в прежнюю
// папку
procedure TFarTabBar.CancelHover;
begin
  FHoverIdx := -1;
  if FModeOn and FHoverMode then
  begin
    if (FStartPath <> '') and not TabSameName(FStartPath, FView.ActivePath) and
       TabDirExists(FStartPath) then
    begin
      // Курсор - на прежнее имя
      if (FStartItem <> '') and (FStartItem <> '..') then
      begin
        if FStartPath[Length(FStartPath)] = '\' then
          FView.ShowFile(FStartPath + FStartItem)
        else
          FView.ShowFile(FStartPath + '\' + FStartItem);
      end
      else
        FView.ShowFolder(FStartPath);
    end;
    FHoverMode := False;
    LeaveMode;
  end;
  Invalidate;
end;

procedure TFarTabBar.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  TrackInfo: TTabTrackMouse;
  TabIdx: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  if FView = nil then
    Exit;
  if not FTracking then
  begin
    TrackInfo.cbSize := SizeOf(TrackInfo);
    TrackInfo.dwFlags := TabTmeLeave;
    TrackInfo.hwndTrack := Handle;
    TrackInfo.dwHoverTime := 0;
    FTracking := TabTrackMouseEvent(TrackInfo);
  end;
  TabIdx := TabAt(X, Y);
  if (TabIdx < 0) or (TabIdx = FHoverIdx) then
    Exit;
  FHoverIdx := TabIdx;
  // Вкладка под мышью: панель показывает её папку (просмотр)
  if not FModeOn and FView.TabsAllowed then
  begin
    EnterMode;
    FHoverMode := FModeOn;
  end;
  if FModeOn then
    GoToTab(TabIdx);
  Invalidate;
end;

procedure TFarTabBar.WMMouseLeave(var Message: TMessage);
begin
  FTracking := False;
  CancelHover;
  Message.Result := 0;
end;

procedure TFarTabBar.EnterMode;
begin
  if FModeOn or (FView = nil) or not FView.TabsAllowed then
    Exit;
  CurrentTabs(FSnapshot);
  FStartPath := FView.ActivePath;
  FStartItem := FView.ActiveCursorItem;
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
  ListIdx, TabIdx: Integer;
begin
  CurrentTabs(Tabs);
  if (AIndex < 0) or (AIndex > High(Tabs)) then
    Exit;
  Path := Tabs[AIndex];
  ListIdx := ListFind(Path);
  if ListIdx >= 0 then
  begin
    ListDelete(ListIdx);
    SaveList;
  end;
  if AIndex = 0 then
  begin
    // Вкладка активной панели остаётся всегда: из списка убрана её папка
    if ListIdx < 0 then
      FView.StatusText(FarProduct + ': этой папки нет в списке вкладок');
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
  // Клавиатура - режим больше не «просмотр мышью»
  FHoverMode := False;
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
          ListAddFirst(FView.ActivePath);
          SaveList;
          FView.StatusText(FarProduct + ': папка добавлена во вкладки - ' +
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
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (FView = nil) or (Button <> mbLeft) then
    Exit;
  TabIdx := TabAt(X, Y);
  if TabIdx >= 0 then
  begin
    if (TabIdx > 0) and PtInRect(FCloseRects[TabIdx], Point(X, Y)) then
      RemoveTab(TabIdx)
    else if FView.TabsAllowed or FModeOn then
    begin
      // Щелчок - остаться в папке вкладки
      if not FModeOn then
        EnterMode;
      GoToTab(TabIdx);
      FHoverMode := False;
      LeaveMode;
    end;
  end;
  if FView.HandleAllocated then
    Windows.SetFocus(FView.Handle);
  Invalidate;
end;

end.
