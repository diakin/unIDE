unit ArdSimHost;

// ---------------------------------------------------------------------------
//  Вкладка «Эмулятор» правой панели: скетч Arduino, собранный ArdSim
//  (ArdSim\build_sim.cmd), работает отдельным процессом без своего окна:
//    <скетч>_sim.exe /host:<имя>
//  Экран 480x320, вывод Serial и нажатия клавиш - через общую память
//  "Local\ArdSim_<имя>", её создаёт эта вкладка. Раскладка - как в
//  ArdSim\src\sim_host.cpp:
//    смещение 0       заголовок, 32 слова по 4 байта (индексы Hdr*)
//    смещение 128     экран 320 строк по 480 точек, RGB565 (как у UTFT)
//    смещение 307328  кольцо вывода Serial, 65536 байт
//  Сигналы (обороты, гармоники, ротор) задаются в ardsim.ini рядом с exe:
//  эмулятор перечитывает файл, когда тот меняется.
//
//  Отдельный процесс, а не DLL: скетч может писать за границы массивов, и
//  тогда упадёт только эмулятор, а не unIDE с несохранёнными файлами.
//
//  Прибор рисуется как BS10: зелёный корпус с экраном, под ним светлая
//  панель с клавиатурой (пропорции сняты с фото прибора). Экран по
//  умолчанию в размер настоящего дисплея 3.5" (73.44 x 48.96 мм, типовая
//  активная область 480x320); кнопка «Размер» переключает на «по ширине
//  панели». Если панель узкая или низкая, сначала уменьшаются зелёные поля
//  корпуса, потом сам экран.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Controls,
  Graphics, StdCtrls, ExtCtrls, Forms, UiStdCtrls, UiButton, UiEditCtrls,
  ProcRun;

const
  ArdSimScreenW = 480;
  ArdSimScreenH = 320;
  ArdSimKeyRows = 5;
  ArdSimKeyCols = 4;
  ArdSimKeyCount = ArdSimKeyRows * ArdSimKeyCols;

type
  TArdSimTextEvent = procedure(Sender: TObject; const AText: string) of object;

  TArdSimPanel = class;

  // Прибор целиком: корпус, экран, клавиатура. Клавиши - мышью или
  // клавишами ПК (когда прибор в фокусе)
  TArdSimDevice = class(TCustomControl)
  private
    FOwnerPanel: TArdSimPanel;
    FScreenW: Integer;         // ширина экрана, точек (высота - 2/3)
    FBodyRect: TRect;
    FPadRect: TRect;
    FScreenRect: TRect;
    FKeyRects: array[0..ArdSimKeyCount - 1] of TRect;
    FPressedKey: Integer;      // подсвеченная клавиша, -1 - нет
    FPressTimer: TTimer;
    FBuffer: TBitmap;
    procedure PressTimerTick(Sender: TObject);
    procedure ShowPressed(AKeyIdx: Integer);
    procedure DrawKey(ACanvas: TCanvas; AKeyIdx: Integer);
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
  protected
    procedure Paint; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      PosX, PosY: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Разложить корпус в AWidth x AHeight; экран шириной не больше
    // AScreenW. Результат - высота, которая нужна прибору
    function Arrange(AWidth, AHeight, AScreenW: Integer): Integer;
    procedure PressKey(AKeyIdx: Integer);
    procedure InvalidateScreen;
  end;

  TArdSimPanel = class(TUiPanel)
  private
    FBar: TUiPanel;
    FBtnBuild: TUiButton;
    FBtnRun: TUiButton;
    FBtnStop: TUiButton;
    FBtnIni: TUiButton;
    FBtnWindow: TUiButton;
    FBtnSize: TUiButton;
    FStatus: TUiLabel;
    FDevice: TArdSimDevice;
    FSerial: TUiMemo;
    FTimer: TTimer;
    FFitWidth: Boolean;       // экран по ширине панели, иначе - как дисплей
    FBuild: TProcRun;         // build_sim.cmd
    FBuildLine: string;       // недописанная строка вывода сборки
    FRunAfterBuild: Boolean;
    FSim: TProcRun;           // <скетч>_sim.exe /host:...
    FSimExe: string;
    FMapName: string;
    {$IFDEF MSWINDOWS}
    FMapping: THandle;
    FView: Pointer;
    {$ENDIF}
    FScreenVersion: Cardinal;
    FSerialRead: Cardinal;
    FPixels: array of Cardinal;   // экран в 32 бита для StretchDIBits
    FHasPicture: Boolean;
    FSketchFile: string;
    FArdSimDir: string;
    FMingwBin: string;
    FOnLog: TArdSimTextEvent;
    FOnOpenFile: TArdSimTextEvent;
    FOnNeedSketch: TNotifyEvent;
    procedure BtnBuildClick(Sender: TObject);
    procedure BtnRunClick(Sender: TObject);
    procedure BtnStopClick(Sender: TObject);
    procedure BtnIniClick(Sender: TObject);
    procedure BtnWindowClick(Sender: TObject);
    procedure BtnSizeClick(Sender: TObject);
    procedure TimerTick(Sender: TObject);
    procedure LayoutControls;
    procedure Log(const AText: string);
    procedure SetStatus(const AText: string);
    procedure UpdateButtons;
    function SketchReady: Boolean;
    function ExeOfSketch: string;
    function IniOfSketch: string;
    procedure StartBuild(ARunAfter: Boolean);
    procedure PollBuild;
    procedure StartSim;
    procedure StopSim;
    procedure PollSim;
    procedure FreeShared;
    function Header(AIndex: Integer): Cardinal;
    procedure SetHeader(AIndex: Integer; AValue: Cardinal);
    procedure AppendSerial(const AText: string);
  protected
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Нажатие клавиши прибора: строка 0..4, столбец 0..3
    procedure PostKey(ARow, ACol: Integer);
    // Экран прибора в прямоугольник ARect (3:2)
    procedure PaintScreen(ACanvas: TCanvas; const ARect: TRect);
    function Running: Boolean;
    function Building: Boolean;
    // Остановить эмулятор и сборку (закрытие unIDE)
    procedure StopAll;
    // .ino, который собирается; задаёт Unit1 (OnNeedSketch перед сборкой)
    property SketchFile: string read FSketchFile write FSketchFile;
    // Папка ArdSim (с build_sim.cmd); '' - искать рядом с unIDE
    property ArdSimDir: string read FArdSimDir write FArdSimDir;
    // Папка bin своего MinGW unIDE; '' - build_sim.cmd ищет сам
    property MingwBin: string read FMingwBin write FMingwBin;
    // Экран по ширине панели (True) или в размер настоящего дисплея
    property FitWidth: Boolean read FFitWidth;
    property OnLog: TArdSimTextEvent read FOnLog write FOnLog;
    property OnOpenFile: TArdSimTextEvent read FOnOpenFile write FOnOpenFile;
    property OnNeedSketch: TNotifyEvent read FOnNeedSketch write FOnNeedSketch;
  end;

// Папка ArdSim рядом с unIDE: <exe>\ArdSim, <exe>\..\ArdSim; нет - ''
function ArdSimFindDir: string;

implementation

const
  HostMagic = $4D495341;    // 'ASIM'
  HostLayout = 1;
  HdrMagic = 0;
  HdrLayout = 1;
  HdrHostPid = 2;
  HdrSimPid = 3;
  HdrScreenVersion = 4;
  HdrKeyWrite = 5;
  HdrKeyRead = 6;
  HdrSerialWrite = 7;
  HdrState = 8;
  HdrStopRequest = 9;
  HdrKeyQueue = 16;
  KeyQueueSize = 16;
  HeaderBytes = 128;
  ScreenBytes = ArdSimScreenW * ArdSimScreenH * 2;
  SerialRingBytes = 65536;
  SharedBytes = HeaderBytes + ScreenBytes + SerialRingBytes;
  SerialMaxChars = 60000;

  // Активная область дисплея 3.5" 480x320 (типовая по документации на
  // такие модули), мм
  DisplayWidthMm = 73.44;

  // Пропорции корпуса BS10 (по фото), в долях ширины экрана
  BodySideK = 0.40;       // зелёное поле слева и справа от экрана
  BodyTopK = 0.27;        // над экраном
  BodyBottomK = 0.26;     // под экраном
  PadWidthK = 1.22;       // ширина панели клавиатуры
  PadTopK = 0.14;         // от верха панели до первого ряда
  PadBottomK = 0.07;      // под последним рядом
  KeyWidthK = 0.23;
  KeyHeightK = 0.165;
  KeyPitchXK = 0.274;
  KeyPitchYK = 0.195;
  MinBorder = 8;          // поле корпуса, меньше которого не ужимать
  RimWidth = 3;           // чёрный кант корпуса

  // Цвета (TColor - $00BBGGRR)
  ClrRim = $00202020;
  ClrBody = $007A9E10;      // тёмно-зелёный корпус
  ClrPad = $00B0D676;       // светло-зелёная панель клавиатуры
  ClrBezel = $00303030;     // рамка вокруг дисплея
  ClrKeyWhite = $00F2F2F2;
  ClrKeyYellow = $001ED2FF;
  ClrKeyRed = $00463CDE;
  ClrKeyText = $00303030;
  ClrKeyEdge = $00808080;

  KeyCaptions: array[0..ArdSimKeyRows - 1, 0..ArdSimKeyCols - 1] of string = (
    ('F1', 'F2', '#', '*'),
    ('1', '2', '3', '^'),
    ('4', '5', '6', 'v'),
    ('7', '8', '9', 'Esc'),
    ('<', '0', '>', 'Ent'));

type
  TKeyLook = (klWhite, klYellow, klRed, klOval);

var
  MapCounter: Integer = 0;

function ArdSimFindDir: string;
var
  ExeDir: string;
begin
  ExeDir := ExtractFilePath(ParamStr(0));
  Result := ExeDir + 'ArdSim\';
  if FileExists(Result + 'build_sim.cmd') then
    Exit;
  Result := ExpandFileName(ExeDir + '..\ArdSim\');
  if FileExists(Result + 'build_sim.cmd') then
    Exit;
  Result := '';
end;

function KeyLookOf(AKeyIdx: Integer): TKeyLook;
begin
  case AKeyIdx of
    0, 1: Result := klYellow;     // F1 F2
    2, 3: Result := klRed;        // # *
    15, 19: Result := klOval;     // Esc Ent
  else
    Result := klWhite;
  end;
end;

// Темнее на AShift (подсветка нажатой клавиши)
function DarkerColor(AColor: TColor; AShift: Integer): TColor;
var
  Red, Green, Blue: Integer;
begin
  AColor := ColorToRGB(AColor);
  Red := (AColor and $FF) - AShift;
  Green := ((AColor shr 8) and $FF) - AShift;
  Blue := ((AColor shr 16) and $FF) - AShift;
  if Red < 0 then Red := 0;
  if Green < 0 then Green := 0;
  if Blue < 0 then Blue := 0;
  Result := TColor(Red or (Green shl 8) or (Blue shl 16));
end;

// ---------------------------------------------------------------------------
//  TArdSimDevice
// ---------------------------------------------------------------------------

constructor TArdSimDevice.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  TabStop := True;
  ShowHint := True;
  ControlStyle := ControlStyle + [csOpaque];
  FPressedKey := -1;
  FScreenW := ArdSimScreenW;
  FBuffer := TBitmap.Create;
  FPressTimer := TTimer.Create(Self);
  FPressTimer.Enabled := False;
  FPressTimer.Interval := 150;
  FPressTimer.OnTimer := PressTimerTick;
end;

destructor TArdSimDevice.Destroy;
begin
  FBuffer.Free;
  inherited Destroy;
end;

// Сверху вниз: корпус (поля, экран, поля), под ним панель клавиатуры.
// Экран - не шире AScreenW; поля корпуса по бокам ужимаются до MinBorder,
// когда не хватает ширины. Если не хватает высоты: сначала уменьшается
// клавиатура (до PadMinK от размера по фото), потом поля сверху и снизу,
// потом экран - корпус с экраном остаётся похожим на прибор
function TArdSimDevice.Arrange(AWidth, AHeight, AScreenW: Integer): Integer;
const
  PadMinK = 0.6;

  function NeedHeight(AScreen: Integer; APadK: Double; ACompact: Boolean): Integer;
  var
    Borders: Integer;
  begin
    if ACompact then
      Borders := 2 * MinBorder
    else
      Borders := Round(AScreen * (BodyTopK + BodyBottomK));
    Result := Borders + AScreen * ArdSimScreenH div ArdSimScreenW +
              Round(AScreen * APadK * (PadTopK + PadBottomK + 4 * KeyPitchYK +
                                       KeyHeightK));
  end;

var
  ScreenW, ScreenH, SideBorder, TopBorder, BottomBorder: Integer;
  BodyW, BodyLeft, PadW, PadLeft, PadTop, GridW, GridLeft, GridTop: Integer;
  KeyW, KeyH, PitchX, PitchY, KeyRow, KeyCol, PadUnit: Integer;
  PadK: Double;
  Compact: Boolean;
begin
  ScreenW := AScreenW;
  if ScreenW > AWidth - 2 * MinBorder then
    ScreenW := AWidth - 2 * MinBorder;
  if ScreenW < 120 then
    ScreenW := 120;
  PadK := 1.0;
  Compact := False;
  if AHeight > 0 then
  begin
    while (PadK > PadMinK) and (NeedHeight(ScreenW, PadK, False) > AHeight) do
      PadK := PadK - 0.02;
    if NeedHeight(ScreenW, PadK, False) > AHeight then
    begin
      Compact := True;
      while (ScreenW > 120) and (NeedHeight(ScreenW, PadK, True) > AHeight) do
        Dec(ScreenW, 4);
    end;
  end;
  FScreenW := ScreenW;
  ScreenH := ScreenW * ArdSimScreenH div ArdSimScreenW;

  SideBorder := Round(ScreenW * BodySideK);
  if ScreenW + 2 * SideBorder > AWidth then
    SideBorder := (AWidth - ScreenW) div 2;
  if SideBorder < MinBorder then
    SideBorder := MinBorder;
  if Compact then
  begin
    TopBorder := MinBorder;
    BottomBorder := MinBorder;
  end
  else
  begin
    TopBorder := Round(ScreenW * BodyTopK);
    BottomBorder := Round(ScreenW * BodyBottomK);
  end;
  BodyW := ScreenW + 2 * SideBorder;
  BodyLeft := (AWidth - BodyW) div 2;
  if BodyLeft < 0 then
    BodyLeft := 0;
  FBodyRect := Rect(BodyLeft, 0, BodyLeft + BodyW,
                    TopBorder + ScreenH + BottomBorder);
  FScreenRect := Rect(BodyLeft + SideBorder, TopBorder,
                      BodyLeft + SideBorder + ScreenW, TopBorder + ScreenH);

  // клавиатура - в долях ширины экрана, умноженной на PadK
  PadUnit := Round(ScreenW * PadK);
  KeyW := Round(PadUnit * KeyWidthK);
  KeyH := Round(PadUnit * KeyHeightK);
  PitchX := Round(PadUnit * KeyPitchXK);
  PitchY := Round(PadUnit * KeyPitchYK);
  GridW := 3 * PitchX + KeyW;
  PadW := Round(PadUnit * PadWidthK);
  if PadW < GridW + 2 * MinBorder then
    PadW := GridW + 2 * MinBorder;
  if PadW > BodyW then
    PadW := BodyW;
  PadLeft := (AWidth - PadW) div 2;
  if PadLeft < 0 then
    PadLeft := 0;
  PadTop := FBodyRect.Bottom - RimWidth;
  GridTop := FBodyRect.Bottom + Round(PadUnit * PadTopK);
  GridLeft := PadLeft + (PadW - GridW) div 2;
  FPadRect := Rect(PadLeft, PadTop, PadLeft + PadW,
                   GridTop + 4 * PitchY + KeyH + Round(PadUnit * PadBottomK));
  for KeyRow := 0 to ArdSimKeyRows - 1 do
    for KeyCol := 0 to ArdSimKeyCols - 1 do
      FKeyRects[KeyRow * ArdSimKeyCols + KeyCol] :=
        Rect(GridLeft + KeyCol * PitchX, GridTop + KeyRow * PitchY,
             GridLeft + KeyCol * PitchX + KeyW, GridTop + KeyRow * PitchY + KeyH);
  Result := FPadRect.Bottom + 1;
end;

procedure TArdSimDevice.InvalidateScreen;
var
  Area: TRect;
begin
  if not HandleAllocated then
    Exit;
  Area := FScreenRect;
  InvalidateRect(Handle, @Area, False);
end;

procedure TArdSimDevice.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  // стрелки, Enter и Esc - прибору, а не переходу между полями
  Message.Result := DLGC_WANTARROWS or DLGC_WANTALLKEYS or DLGC_WANTCHARS;
end;

procedure TArdSimDevice.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TArdSimDevice.WMSetFocus(var Message: TWMSetFocus);
begin
  inherited;
  Invalidate;
end;

procedure TArdSimDevice.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  Invalidate;
end;

procedure TArdSimDevice.PressTimerTick(Sender: TObject);
var
  KeyIdx: Integer;
  Area: TRect;
begin
  FPressTimer.Enabled := False;
  KeyIdx := FPressedKey;
  FPressedKey := -1;
  if (KeyIdx >= 0) and HandleAllocated then
  begin
    Area := FKeyRects[KeyIdx];
    InvalidateRect(Handle, @Area, False);
  end;
end;

procedure TArdSimDevice.ShowPressed(AKeyIdx: Integer);
var
  Area: TRect;
begin
  if FPressedKey >= 0 then
    PressTimerTick(nil);
  FPressedKey := AKeyIdx;
  if HandleAllocated then
  begin
    Area := FKeyRects[AKeyIdx];
    InvalidateRect(Handle, @Area, False);
  end;
  FPressTimer.Enabled := False;
  FPressTimer.Enabled := True;
end;

procedure TArdSimDevice.PressKey(AKeyIdx: Integer);
begin
  if (AKeyIdx < 0) or (AKeyIdx >= ArdSimKeyCount) then
    Exit;
  ShowPressed(AKeyIdx);
  if FOwnerPanel <> nil then
    FOwnerPanel.PostKey(AKeyIdx div ArdSimKeyCols, AKeyIdx mod ArdSimKeyCols);
end;

procedure TArdSimDevice.MouseDown(Button: TMouseButton; Shift: TShiftState;
  PosX, PosY: Integer);
var
  KeyIdx: Integer;
  HitPoint: TPoint;
begin
  inherited;
  if CanFocus then
    SetFocus;
  if Button <> mbLeft then
    Exit;
  HitPoint := Point(PosX, PosY);
  for KeyIdx := 0 to ArdSimKeyCount - 1 do
    if PtInRect(FKeyRects[KeyIdx], HitPoint) then
    begin
      PressKey(KeyIdx);
      Exit;
    end;
end;

// Клавиши ПК -> клавиатура прибора (как в окне ArdSim, sim_window.cpp)
procedure TArdSimDevice.KeyDown(var Key: Word; Shift: TShiftState);
var
  KeyIdx: Integer;
begin
  inherited;
  // Shift+3 / Shift+8 - это '#' и '*', они придут в KeyPress
  if (ssShift in Shift) and (Key >= Ord('0')) and (Key <= Ord('9')) then
    Exit;
  case Key of
    VK_F1: KeyIdx := 0;
    VK_F2: KeyIdx := 1;
    VK_MULTIPLY: KeyIdx := 3;
    Ord('1'), VK_NUMPAD1: KeyIdx := 4;
    Ord('2'), VK_NUMPAD2: KeyIdx := 5;
    Ord('3'), VK_NUMPAD3: KeyIdx := 6;
    VK_UP: KeyIdx := 7;
    Ord('4'), VK_NUMPAD4: KeyIdx := 8;
    Ord('5'), VK_NUMPAD5: KeyIdx := 9;
    Ord('6'), VK_NUMPAD6: KeyIdx := 10;
    VK_DOWN: KeyIdx := 11;
    Ord('7'), VK_NUMPAD7: KeyIdx := 12;
    Ord('8'), VK_NUMPAD8: KeyIdx := 13;
    Ord('9'), VK_NUMPAD9: KeyIdx := 14;
    VK_ESCAPE, VK_BACK: KeyIdx := 15;
    VK_LEFT: KeyIdx := 16;
    Ord('0'), VK_NUMPAD0: KeyIdx := 17;
    VK_RIGHT: KeyIdx := 18;
    VK_RETURN: KeyIdx := 19;
  else
    KeyIdx := -1;
  end;
  if KeyIdx >= 0 then
  begin
    PressKey(KeyIdx);
    Key := 0;
  end;
end;

procedure TArdSimDevice.KeyPress(var Key: Char);
begin
  inherited;
  if Key = '#' then
  begin
    PressKey(2);
    Key := #0;
  end
  else if Key = '*' then
  begin
    PressKey(3);
    Key := #0;
  end;
end;

// Одна клавиша: цвет и форма как на приборе; стрелки - треугольником
procedure TArdSimDevice.DrawKey(ACanvas: TCanvas; AKeyIdx: Integer);
var
  Area: TRect;
  Look: TKeyLook;
  Fill, TextColor: TColor;
  Caption: string;
  KeyW, KeyH, MidX, MidY, ArrowLen, ArrowHalf, Corner: Integer;
  TextSize: TSize;
  Arrow: array[0..2] of TPoint;
  ArrowDir: Integer;   // 0 вверх, 1 вниз, 2 влево, 3 вправо, -1 не стрелка
begin
  Area := FKeyRects[AKeyIdx];
  KeyW := Area.Right - Area.Left;
  KeyH := Area.Bottom - Area.Top;
  Look := KeyLookOf(AKeyIdx);
  case Look of
    klYellow: Fill := ClrKeyYellow;
    klRed, klOval: Fill := ClrKeyRed;
  else
    Fill := ClrKeyWhite;
  end;
  if AKeyIdx = FPressedKey then
    Fill := DarkerColor(Fill, 70);
  if Look = klOval then
    TextColor := clWhite
  else
    TextColor := ClrKeyText;

  ACanvas.Pen.Color := ClrKeyEdge;
  ACanvas.Pen.Width := 1;
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := Fill;
  if Look = klOval then
  begin
    ACanvas.Pen.Color := DarkerColor(Fill, 40);
    ACanvas.Ellipse(Area.Left, Area.Top, Area.Right, Area.Bottom);
  end
  else
  begin
    Corner := KeyH div 4;
    ACanvas.RoundRect(Area.Left, Area.Top, Area.Right, Area.Bottom,
                      Corner, Corner);
  end;

  MidX := (Area.Left + Area.Right) div 2;
  MidY := (Area.Top + Area.Bottom) div 2;
  Caption := KeyCaptions[AKeyIdx div ArdSimKeyCols, AKeyIdx mod ArdSimKeyCols];
  case AKeyIdx of
    7: ArrowDir := 0;
    11: ArrowDir := 1;
    16: ArrowDir := 2;
    18: ArrowDir := 3;
  else
    ArrowDir := -1;
  end;
  if ArrowDir >= 0 then
  begin
    ArrowLen := KeyH * 2 div 5;
    ArrowHalf := ArrowLen div 2;
    case ArrowDir of
      0: begin
           Arrow[0] := Point(MidX, MidY - ArrowHalf);
           Arrow[1] := Point(MidX - ArrowHalf, MidY + ArrowHalf);
           Arrow[2] := Point(MidX + ArrowHalf, MidY + ArrowHalf);
         end;
      1: begin
           Arrow[0] := Point(MidX, MidY + ArrowHalf);
           Arrow[1] := Point(MidX - ArrowHalf, MidY - ArrowHalf);
           Arrow[2] := Point(MidX + ArrowHalf, MidY - ArrowHalf);
         end;
      2: begin
           Arrow[0] := Point(MidX - ArrowHalf, MidY);
           Arrow[1] := Point(MidX + ArrowHalf, MidY - ArrowHalf);
           Arrow[2] := Point(MidX + ArrowHalf, MidY + ArrowHalf);
         end;
    else
      Arrow[0] := Point(MidX + ArrowHalf, MidY);
      Arrow[1] := Point(MidX - ArrowHalf, MidY - ArrowHalf);
      Arrow[2] := Point(MidX - ArrowHalf, MidY + ArrowHalf);
    end;
    ACanvas.Pen.Color := TextColor;
    ACanvas.Brush.Color := TextColor;
    ACanvas.Polygon(Arrow);
    Exit;
  end;

  ACanvas.Brush.Style := bsClear;
  ACanvas.Font.Name := 'Arial';
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Color := TextColor;
  ACanvas.Font.Height := -(KeyH * 11 div 20);
  if ACanvas.Font.Height > -8 then
    ACanvas.Font.Height := -8;
  TextSize := ACanvas.TextExtent(Caption);
  // широкие подписи (Esc, Ent) - помельче, чтобы влезли в овал
  if TextSize.cx > KeyW * 4 div 5 then
  begin
    ACanvas.Font.Height := ACanvas.Font.Height * (KeyW * 4 div 5) div TextSize.cx;
    TextSize := ACanvas.TextExtent(Caption);
  end;
  ACanvas.TextOut(MidX - TextSize.cx div 2, MidY - TextSize.cy div 2, Caption);
  ACanvas.Brush.Style := bsSolid;
end;

procedure TArdSimDevice.Paint;
var
  Draw: TCanvas;
  Corner, KeyIdx: Integer;
  Bezel: TRect;
begin
  if (FBuffer.Width <> ClientWidth) or (FBuffer.Height <> ClientHeight) then
  begin
    FBuffer.Width := ClientWidth;
    FBuffer.Height := ClientHeight;
  end;
  Draw := FBuffer.Canvas;
  // фон - как у панели вокруг
  Draw.Brush.Style := bsSolid;
  Draw.Brush.Color := Color;
  Draw.FillRect(ClientRect);

  // панель клавиатуры (под корпусом, её верх закрывает корпус)
  Corner := (FPadRect.Right - FPadRect.Left) div 12;
  Draw.Pen.Color := ClrRim;
  Draw.Pen.Width := RimWidth;
  Draw.Brush.Color := ClrPad;
  Draw.RoundRect(FPadRect.Left + 1, FPadRect.Top + 1, FPadRect.Right - 1,
                 FPadRect.Bottom - 1, Corner, Corner);
  // корпус
  Corner := (FBodyRect.Right - FBodyRect.Left) div 16;
  Draw.Brush.Color := ClrBody;
  Draw.RoundRect(FBodyRect.Left + 1, FBodyRect.Top + 1, FBodyRect.Right - 1,
                 FBodyRect.Bottom - 1, Corner, Corner);
  Draw.Pen.Width := 1;
  // рамка дисплея
  Bezel := FScreenRect;
  InflateRect(Bezel, 3, 3);
  Draw.Brush.Color := ClrBezel;
  Draw.FillRect(Bezel);
  if FOwnerPanel <> nil then
    FOwnerPanel.PaintScreen(Draw, FScreenRect);
  if Focused then
  begin
    // в фокусе: клавиши ПК идут прибору
    Draw.Brush.Color := clHighlight;
    Draw.FrameRect(Bezel);
  end;
  for KeyIdx := 0 to ArdSimKeyCount - 1 do
    DrawKey(Draw, KeyIdx);
  Canvas.Draw(0, 0, FBuffer);
end;

// ---------------------------------------------------------------------------
//  TArdSimPanel
// ---------------------------------------------------------------------------

constructor TArdSimPanel.Create(AOwner: TComponent);

  function MakeButton(AParent: TWinControl; const ACaption, AHint: string;
    AClick: TNotifyEvent): TUiButton;
  begin
    Result := TUiButton.Create(Self);
    Result.Parent := AParent;
    Result.Caption := ACaption;
    Result.Hint := AHint;
    Result.ShowHint := True;
    Result.OnClick := AClick;
    Result.TabStop := False;
  end;

begin
  inherited Create(AOwner);
  BevelOuter := bvNone;
  Caption := '';
  {$IFDEF MSWINDOWS}
  FMapping := 0;
  FView := nil;
  {$ENDIF}
  SetLength(FPixels, ArdSimScreenW * ArdSimScreenH);

  FBar := TUiPanel.Create(Self);
  FBar.Parent := Self;
  FBar.BevelOuter := bvNone;
  FBar.Caption := '';
  FBtnBuild := MakeButton(FBar, 'Build',
    'Собрать скетч под ПК (ArdSim\build_sim.cmd, MinGW g++) и запустить',
    BtnBuildClick);
  FBtnRun := MakeButton(FBar, 'Run', 'Запустить собранный скетч без сборки',
    BtnRunClick);
  FBtnStop := MakeButton(FBar, 'Stop', 'Остановить эмулятор', BtnStopClick);
  FBtnIni := MakeButton(FBar, 'ini',
    'ardsim.ini - сигналы, тахометр, модель ротора. Эмулятор перечитывает ' +
    'его после сохранения', BtnIniClick);
  FBtnWindow := MakeButton(FBar, 'Окно',
    'Запустить собранный скетч в отдельном окне ArdSim (с панелью сигналов)',
    BtnWindowClick);
  FBtnSize := MakeButton(FBar, 'Размер',
    'Экран как настоящий дисплей 3.5" / по ширине панели', BtnSizeClick);
  FStatus := TUiLabel.Create(Self);
  FStatus.Parent := Self;
  FStatus.AutoSize := False;
  FStatus.Caption := '';

  FDevice := TArdSimDevice.Create(Self);
  FDevice.FOwnerPanel := Self;
  FDevice.Parent := Self;
  FDevice.Hint := 'Щёлкните по прибору, чтобы клавиши ПК работали как ' +
    'клавиатура: 0-9, F1, F2, #, *, стрелки, Enter, Esc';

  FSerial := TUiMemo.Create(Self);
  FSerial.Parent := Self;
  FSerial.ReadOnly := True;
  FSerial.ScrollBars := ssVertical;
  FSerial.WordWrap := False;
  FSerial.Font.Name := 'Courier New';
  FSerial.Font.Size := 9;

  FTimer := TTimer.Create(Self);
  FTimer.Interval := 40;
  FTimer.Enabled := False;
  FTimer.OnTimer := TimerTick;

  SetStatus('Скетч не запущен');
  UpdateButtons;
end;

destructor TArdSimPanel.Destroy;
begin
  FTimer.Enabled := False;
  StopAll;
  inherited Destroy;
end;

procedure TArdSimPanel.Resize;
begin
  inherited;
  LayoutControls;
end;

// Сверху вниз: кнопки, строка состояния, прибор, вывод Serial - всё
// остальное (не меньше SerialMinH)
procedure TArdSimPanel.LayoutControls;
const
  Gap = 4;
  BarH = 24;
  StatusH = 18;
  SerialMinH = 60;
var
  AreaW, PosY, ButtonW, BtnIdx, ScreenW, DeviceH: Integer;
  Buttons: array[0..5] of TUiButton;
begin
  if FBar = nil then
    Exit;
  AreaW := ClientWidth - 2 * Gap;
  if AreaW < 60 then
    AreaW := 60;
  PosY := Gap;
  FBar.SetBounds(Gap, PosY, AreaW, BarH);
  Buttons[0] := FBtnBuild;
  Buttons[1] := FBtnRun;
  Buttons[2] := FBtnStop;
  Buttons[3] := FBtnIni;
  Buttons[4] := FBtnWindow;
  Buttons[5] := FBtnSize;
  ButtonW := (AreaW - 5 * 2) div 6;
  for BtnIdx := 0 to 5 do
    Buttons[BtnIdx].SetBounds(BtnIdx * (ButtonW + 2), 0, ButtonW, BarH);
  Inc(PosY, BarH + 2);
  FStatus.SetBounds(Gap, PosY, AreaW, StatusH);
  Inc(PosY, StatusH);
  if FFitWidth then
    ScreenW := AreaW
  else
    ScreenW := Round(DisplayWidthMm * Screen.PixelsPerInch / 25.4);
  DeviceH := FDevice.Arrange(AreaW, ClientHeight - PosY - SerialMinH - 2 * Gap,
                             ScreenW);
  FDevice.SetBounds(Gap, PosY, AreaW, DeviceH);
  FDevice.Invalidate;
  Inc(PosY, DeviceH + Gap);
  if ClientHeight - PosY - Gap > 20 then
    FSerial.SetBounds(Gap, PosY, AreaW, ClientHeight - PosY - Gap)
  else
    FSerial.SetBounds(Gap, PosY, AreaW, 20);
end;

procedure TArdSimPanel.BtnSizeClick(Sender: TObject);
begin
  FFitWidth := not FFitWidth;
  LayoutControls;
end;

procedure TArdSimPanel.Log(const AText: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Self, AText);
end;

procedure TArdSimPanel.SetStatus(const AText: string);
begin
  FStatus.Caption := AText;
end;

procedure TArdSimPanel.UpdateButtons;
begin
  FBtnBuild.Enabled := not Building;
  FBtnRun.Enabled := not Building;
  FBtnStop.Enabled := Running or Building;
  FBtnWindow.Enabled := not Building;
end;

function TArdSimPanel.Running: Boolean;
begin
  Result := (FSim <> nil) and FSim.Running;
end;

function TArdSimPanel.Building: Boolean;
begin
  Result := FBuild <> nil;
end;

function TArdSimPanel.SketchReady: Boolean;
begin
  if Assigned(FOnNeedSketch) then
    FOnNeedSketch(Self);
  Result := (FSketchFile <> '') and FileExists(FSketchFile);
  if not Result then
  begin
    SetStatus('Нет скетча: откройте .ino');
    Log('ArdSim: нет скетча .ino для сборки (вкладка Arduino или проект ' +
        'со скетчем)');
  end;
end;

function TArdSimPanel.ExeOfSketch: string;
begin
  Result := ExtractFilePath(FSketchFile) + 'ardsim_build\' +
            ChangeFileExt(ExtractFileName(FSketchFile), '') + '_sim.exe';
end;

function TArdSimPanel.IniOfSketch: string;
begin
  Result := ExtractFilePath(ExeOfSketch) + 'ardsim.ini';
end;

procedure TArdSimPanel.BtnBuildClick(Sender: TObject);
begin
  if Building or not SketchReady then
    Exit;
  StopSim;
  StartBuild(True);
end;

procedure TArdSimPanel.BtnRunClick(Sender: TObject);
begin
  if Building or not SketchReady then
    Exit;
  if not FileExists(ExeOfSketch) then
  begin
    // ещё не собирался - собрать
    StartBuild(True);
    Exit;
  end;
  StopSim;
  StartSim;
end;

procedure TArdSimPanel.BtnStopClick(Sender: TObject);
begin
  StopAll;
end;

procedure TArdSimPanel.BtnIniClick(Sender: TObject);
var
  IniFile: string;
begin
  if not SketchReady then
    Exit;
  IniFile := IniOfSketch;
  if not FileExists(IniFile) then
  begin
    SetStatus('ardsim.ini появится после первого запуска');
    Log('ArdSim: ' + IniFile + ' создаётся при первом запуске эмулятора');
    Exit;
  end;
  if Assigned(FOnOpenFile) then
    FOnOpenFile(Self, IniFile);
end;

procedure TArdSimPanel.BtnWindowClick(Sender: TObject);
var
  WindowRun: TProcRun;
begin
  if Building or not SketchReady then
    Exit;
  if not FileExists(ExeOfSketch) then
  begin
    SetStatus('Сначала Build+Run');
    Exit;
  end;
  WindowRun := TProcRun.Create;
  try
    WindowRun.CommandLine := '"' + ExeOfSketch + '"';
    WindowRun.Dir := ExtractFilePath(ExeOfSketch);
    if not WindowRun.Start then
      Log('ArdSim: не запустился ' + ExeOfSketch + ' - ' + WindowRun.ErrorText);
  finally
    WindowRun.Free;   // процесс работает дальше сам
  end;
end;


// ---------------------------------------------------------------- сборка

procedure TArdSimPanel.StartBuild(ARunAfter: Boolean);
var
  SimDir, Command: string;
begin
  SimDir := FArdSimDir;
  if SimDir = '' then
    SimDir := ArdSimFindDir;
  if (SimDir = '') or not FileExists(IncludeTrailingPathDelimiter(SimDir) +
     'build_sim.cmd') then
  begin
    SetStatus('Не найдена папка ArdSim');
    Log('ArdSim: не найден build_sim.cmd (папка ArdSim рядом с unIDE ' +
        'или на уровень выше)');
    Exit;
  end;
  SimDir := IncludeTrailingPathDelimiter(SimDir);
  // cmd /c ""файл" "аргумент"" - внешние кавычки снимает cmd
  Command := '"' + SimDir + 'build_sim.cmd" "' + FSketchFile + '"';
  if FMingwBin <> '' then
    Command := Command + ' "' + ExcludeTrailingPathDelimiter(FMingwBin) + '"';
  FBuild := TProcRun.Create;
  FBuild.CommandLine := 'cmd.exe /c "' + Command + '"';
  FBuild.Dir := SimDir;
  FBuild.Window := pwHidden;
  FBuild.Console := pcNoWindow;
  FBuild.CaptureOutput := True;
  FBuildLine := '';
  FRunAfterBuild := ARunAfter;
  Log('ArdSim: сборка ' + FSketchFile);
  if not FBuild.Start then
  begin
    Log('ArdSim: build_sim.cmd не запустился - ' + FBuild.ErrorText);
    FreeAndNil(FBuild);
    SetStatus('Сборка не запустилась');
    UpdateButtons;
    Exit;
  end;
  SetStatus('Сборка...');
  FTimer.Enabled := True;
  UpdateButtons;
end;

procedure TArdSimPanel.PollBuild;
var
  Chunk: string;
  Got, LineEnd: Integer;
  Finished: Boolean;
  ExitCode: Integer;
begin
  if FBuild = nil then
    Exit;
  Chunk := '';
  Got := FBuild.Read(Chunk, 65536);
  Finished := Got < 0;
  if Got > 0 then
  begin
    FBuildLine := FBuildLine + Chunk;
    repeat
      LineEnd := Pos(#10, FBuildLine);
      if LineEnd = 0 then
        Break;
      Log(TrimRight(Copy(FBuildLine, 1, LineEnd - 1)));
      Delete(FBuildLine, 1, LineEnd);
    until False;
  end;
  // -1: программа вышла и вывод прочитан весь
  if not Finished then
    Exit;
  if Trim(FBuildLine) <> '' then
    Log(TrimRight(FBuildLine));
  FBuildLine := '';
  FBuild.WaitFor(1000);
  ExitCode := FBuild.ExitCode;
  FreeAndNil(FBuild);
  if ExitCode <> 0 then
  begin
    SetStatus('Сборка не удалась, см. журнал');
    Log('ArdSim: сборка не удалась, код ' + IntToStr(ExitCode));
    UpdateButtons;
    Exit;
  end;
  SetStatus('Собрано');
  if FRunAfterBuild then
    StartSim;
  UpdateButtons;
end;

// ---------------------------------------------------------------- эмулятор

function TArdSimPanel.Header(AIndex: Integer): Cardinal;
begin
  {$IFDEF MSWINDOWS}
  if FView <> nil then
    Result := PCardinal(PAnsiChar(FView) + AIndex * 4)^
  else
  {$ENDIF}
    Result := 0;
end;

procedure TArdSimPanel.SetHeader(AIndex: Integer; AValue: Cardinal);
begin
  {$IFDEF MSWINDOWS}
  if FView <> nil then
    PCardinal(PAnsiChar(FView) + AIndex * 4)^ := AValue;
  {$ENDIF}
end;

procedure TArdSimPanel.StartSim;
begin
  {$IFDEF MSWINDOWS}
  FSimExe := ExeOfSketch;
  if not FileExists(FSimExe) then
  begin
    SetStatus('Нет ' + ExtractFileName(FSimExe));
    Exit;
  end;
  Inc(MapCounter);
  FMapName := IntToStr(GetCurrentProcessId) + '_' + IntToStr(MapCounter);
  FMapping := CreateFileMapping(INVALID_HANDLE_VALUE, nil, PAGE_READWRITE, 0,
                                SharedBytes, PChar('Local\ArdSim_' + FMapName));
  if FMapping = 0 then
  begin
    Log('ArdSim: общая память не создана, код ' + IntToStr(GetLastError));
    Exit;
  end;
  FView := MapViewOfFile(FMapping, FILE_MAP_ALL_ACCESS, 0, 0, SharedBytes);
  if FView = nil then
  begin
    Log('ArdSim: общая память не открыта, код ' + IntToStr(GetLastError));
    FreeShared;
    Exit;
  end;
  FillChar(FView^, SharedBytes, 0);
  SetHeader(HdrHostPid, GetCurrentProcessId);
  SetHeader(HdrLayout, HostLayout);
  SetHeader(HdrMagic, HostMagic);
  FScreenVersion := 0;
  FSerialRead := 0;
  FHasPicture := False;
  FSerial.Lines.Clear;

  FSim := TProcRun.Create;
  FSim.CommandLine := '"' + FSimExe + '" /host:' + FMapName;
  FSim.Dir := ExtractFilePath(FSimExe);
  FSim.Window := pwHidden;
  if not FSim.Start then
  begin
    Log('ArdSim: не запустился ' + FSimExe + ' - ' + FSim.ErrorText);
    FreeAndNil(FSim);
    FreeShared;
    SetStatus('Эмулятор не запустился');
    UpdateButtons;
    Exit;
  end;
  Log('ArdSim: запущен ' + FSimExe);
  SetStatus('Работает: ' + ExtractFileName(FSketchFile));
  FTimer.Enabled := True;
  FDevice.Invalidate;
  if FDevice.CanFocus then
    FDevice.SetFocus;
  {$ELSE}
  SetStatus('Эмулятор работает только в Windows');
  {$ENDIF}
  UpdateButtons;
end;

procedure TArdSimPanel.FreeShared;
begin
  {$IFDEF MSWINDOWS}
  if FView <> nil then
    UnmapViewOfFile(FView);
  FView := nil;
  if FMapping <> 0 then
    CloseHandle(FMapping);
  FMapping := 0;
  {$ENDIF}
end;

procedure TArdSimPanel.StopSim;
begin
  if FSim = nil then
    Exit;
  if FSim.Running then
  begin
    // просьба выйти; скетч может считать без вызовов API - тогда снять
    SetHeader(HdrStopRequest, 1);
    if not FSim.WaitFor(500) then
      FSim.Terminate(1);
  end;
  FreeAndNil(FSim);
  FreeShared;
  SetStatus('Остановлен');
  UpdateButtons;
end;

procedure TArdSimPanel.StopAll;
begin
  if FBuild <> nil then
  begin
    FBuild.KillTree;
    FreeAndNil(FBuild);
    Log('ArdSim: сборка остановлена');
  end;
  StopSim;
  if FTimer <> nil then
    FTimer.Enabled := False;
end;

procedure TArdSimPanel.PostKey(ARow, ACol: Integer);
var
  KeyWrite: Cardinal;
begin
  if not Running then
    Exit;
  KeyWrite := Header(HdrKeyWrite);
  if KeyWrite - Header(HdrKeyRead) >= KeyQueueSize then
    Exit;   // эмулятор не успевает разбирать
  SetHeader(HdrKeyQueue + Integer(KeyWrite mod KeyQueueSize),
            Cardinal(ARow * ArdSimKeyCols + ACol));
  SetHeader(HdrKeyWrite, KeyWrite + 1);
end;

procedure TArdSimPanel.AppendSerial(const AText: string);
var
  Converted: string;
  CharIdx: Integer;
begin
  Converted := '';
  for CharIdx := 1 to Length(AText) do
  begin
    if AText[CharIdx] = #13 then
      Continue;
    if AText[CharIdx] = #10 then
      Converted := Converted + #13#10
    else
      Converted := Converted + AText[CharIdx];
  end;
  if FSerial.GetTextLen > SerialMaxChars then
  begin
    FSerial.SelStart := 0;
    FSerial.SelLength := SerialMaxChars div 3;
    FSerial.SelText := '';
  end;
  FSerial.SelStart := FSerial.GetTextLen;
  FSerial.SelLength := 0;
  FSerial.SelText := Converted;
end;

procedure TArdSimPanel.PollSim;
var
  Version, Written, Count, ByteIdx: Cardinal;
  Ring: PAnsiChar;
  Text: string;
  ExitCode: Integer;
begin
  {$IFDEF MSWINDOWS}
  if (FSim = nil) or (FView = nil) then
    Exit;
  Version := Header(HdrScreenVersion);
  if Version <> FScreenVersion then
  begin
    FScreenVersion := Version;
    FHasPicture := True;
    FDevice.InvalidateScreen;
  end;
  Written := Header(HdrSerialWrite);
  if Written <> FSerialRead then
  begin
    Count := Written - FSerialRead;
    if Count > SerialRingBytes then
    begin
      // кольцо обогнало чтение: старое потеряно
      FSerialRead := Written - SerialRingBytes;
      Count := SerialRingBytes;
    end;
    Ring := PAnsiChar(FView) + HeaderBytes + ScreenBytes;
    SetLength(Text, Count);
    for ByteIdx := 0 to Count - 1 do
      Text[ByteIdx + 1] := Char(Ring[(FSerialRead + ByteIdx) mod SerialRingBytes]);
    FSerialRead := Written;
    AppendSerial(Text);
  end;
  if not FSim.Running then
  begin
    ExitCode := FSim.ExitCode;
    FreeAndNil(FSim);
    FreeShared;
    if ExitCode = 0 then
      SetStatus('Эмулятор завершился')
    else
    begin
      SetStatus('Эмулятор завершился, код ' + IntToStr(ExitCode));
      Log('ArdSim: ' + ExtractFileName(FSimExe) + ' завершился, код ' +
          IntToStr(ExitCode));
    end;
    UpdateButtons;
  end;
  {$ENDIF}
end;

procedure TArdSimPanel.TimerTick(Sender: TObject);
begin
  PollBuild;
  PollSim;
  if (FBuild = nil) and (FSim = nil) then
    FTimer.Enabled := False;
end;


// Экран: RGB565 из общей памяти -> 32 бита -> StretchDIBits в ARect
// (3:2). Эмулятор не запущен - последняя картинка (её копия в FPixels)
// или пустое поле
procedure TArdSimPanel.PaintScreen(ACanvas: TCanvas; const ARect: TRect);
var
  {$IFDEF MSWINDOWS}
  Info: TBitmapInfo;
  Source: PWord;
  PixelIdx: Integer;
  Color, Red, Green, Blue: Cardinal;
  {$ENDIF}
  AreaW, AreaH, DrawW, DrawH, DrawX, DrawY: Integer;
begin
  AreaW := ARect.Right - ARect.Left;
  AreaH := ARect.Bottom - ARect.Top;
  ACanvas.Brush.Color := clBlack;
  ACanvas.FillRect(ARect);
  DrawW := AreaW;
  DrawH := DrawW * ArdSimScreenH div ArdSimScreenW;
  if DrawH > AreaH then
  begin
    DrawH := AreaH;
    DrawW := DrawH * ArdSimScreenW div ArdSimScreenH;
  end;
  DrawX := ARect.Left + (AreaW - DrawW) div 2;
  DrawY := ARect.Top + (AreaH - DrawH) div 2;
  {$IFDEF MSWINDOWS}
  if FView <> nil then
  begin
    Source := PWord(PAnsiChar(FView) + HeaderBytes);
    for PixelIdx := 0 to ArdSimScreenW * ArdSimScreenH - 1 do
    begin
      Color := Source^;
      Inc(Source);
      Red := (Color shr 11) and $1F;
      Green := (Color shr 5) and $3F;
      Blue := Color and $1F;
      Red := (Red shl 3) or (Red shr 2);
      Green := (Green shl 2) or (Green shr 4);
      Blue := (Blue shl 3) or (Blue shr 2);
      FPixels[PixelIdx] := (Red shl 16) or (Green shl 8) or Blue;
    end;
  end;
  if FHasPicture then
  begin
    FillChar(Info, SizeOf(Info), 0);
    Info.bmiHeader.biSize := SizeOf(TBitmapInfoHeader);
    Info.bmiHeader.biWidth := ArdSimScreenW;
    Info.bmiHeader.biHeight := -ArdSimScreenH;   // сверху вниз
    Info.bmiHeader.biPlanes := 1;
    Info.bmiHeader.biBitCount := 32;
    Info.bmiHeader.biCompression := BI_RGB;
    // меньше 1:1 - HALFTONE (тонкие линии и мелкий текст не пропадают)
    if DrawW < ArdSimScreenW then
    begin
      SetStretchBltMode(ACanvas.Handle, HALFTONE);
      SetBrushOrgEx(ACanvas.Handle, 0, 0, nil);
    end
    else
      SetStretchBltMode(ACanvas.Handle, COLORONCOLOR);
    StretchDIBits(ACanvas.Handle, DrawX, DrawY, DrawW, DrawH, 0, 0,
      ArdSimScreenW, ArdSimScreenH, @FPixels[0], Info, DIB_RGB_COLORS, SRCCOPY);
  end
  else
  {$ENDIF}
  begin
    ACanvas.Font.Color := clGray;
    ACanvas.Brush.Style := bsClear;
    ACanvas.Font.Height := -11;
    ACanvas.Font.Style := [];
    ACanvas.TextOut(DrawX + 6, DrawY + 6, 'Build - собрать и запустить');
    ACanvas.Brush.Style := bsSolid;
  end;
end;

end.
