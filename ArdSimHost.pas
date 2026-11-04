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
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Controls,
  Graphics, StdCtrls, ExtCtrls, Forms, UiStdCtrls, UiButton, UiEditCtrls, ProcRun;

const
  ArdSimScreenW = 480;
  ArdSimScreenH = 320;
  ArdSimKeyRows = 5;
  ArdSimKeyCols = 4;

type
  TArdSimTextEvent = procedure(Sender: TObject; const AText: string) of object;

  TArdSimPanel = class;

  // Экран прибора: картинка 480x320 в масштабе по размеру; в фокусе -
  // клавиши ПК работают как клавиатура прибора
  TArdSimScreen = class(TCustomControl)
  private
    FOwnerPanel: TArdSimPanel;
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
  end;

  TArdSimPanel = class(TUiPanel)
  private
    FBar: TUiPanel;
    FBtnBuild: TUiButton;
    FBtnRun: TUiButton;
    FBtnStop: TUiButton;
    FBtnIni: TUiButton;
    FBtnWindow: TUiButton;
    FStatus: TUiLabel;
    FScreen: TArdSimScreen;
    FKeypad: TUiPanel;
    FKeys: array[0..ArdSimKeyRows * ArdSimKeyCols - 1] of TUiButton;
    FSerial: TUiMemo;
    FTimer: TTimer;
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
    procedure KeyClick(Sender: TObject);
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

  KeyCaptions: array[0..ArdSimKeyRows - 1, 0..ArdSimKeyCols - 1] of string = (
    ('F1', 'F2', '#', '*'),
    ('1', '2', '3', '^'),
    ('4', '5', '6', 'v'),
    ('7', '8', '9', 'Esc'),
    ('<', '0', '>', 'Ent'));

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

// ---------------------------------------------------------------------------
//  TArdSimScreen
// ---------------------------------------------------------------------------

constructor TArdSimScreen.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  TabStop := True;
  ShowHint := True;
  ControlStyle := ControlStyle + [csOpaque];
end;

procedure TArdSimScreen.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  // стрелки, Enter и Esc - экрану, а не переходу между полями
  Message.Result := DLGC_WANTARROWS or DLGC_WANTALLKEYS or DLGC_WANTCHARS;
end;

procedure TArdSimScreen.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TArdSimScreen.WMSetFocus(var Message: TWMSetFocus);
begin
  inherited;
  Invalidate;
end;

procedure TArdSimScreen.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  Invalidate;
end;

procedure TArdSimScreen.Paint;
begin
  if FOwnerPanel <> nil then
    FOwnerPanel.PaintScreen(Canvas, ClientRect);
end;

procedure TArdSimScreen.MouseDown(Button: TMouseButton; Shift: TShiftState;
  PosX, PosY: Integer);
begin
  inherited;
  if CanFocus then
    SetFocus;
end;

// Клавиши ПК -> клавиатура прибора (как в окне ArdSim, sim_window.cpp)
procedure TArdSimScreen.KeyDown(var Key: Word; Shift: TShiftState);
var
  KeyRow, KeyCol: Integer;
begin
  inherited;
  if FOwnerPanel = nil then
    Exit;
  KeyRow := -1;
  KeyCol := -1;
  // Shift+3 / Shift+8 - это '#' и '*', они придут в KeyPress
  if (ssShift in Shift) and (Key >= Ord('0')) and (Key <= Ord('9')) then
    Exit;
  case Key of
    VK_F1: begin KeyRow := 0; KeyCol := 0; end;
    VK_F2: begin KeyRow := 0; KeyCol := 1; end;
    VK_MULTIPLY: begin KeyRow := 0; KeyCol := 3; end;
    Ord('1'), VK_NUMPAD1: begin KeyRow := 1; KeyCol := 0; end;
    Ord('2'), VK_NUMPAD2: begin KeyRow := 1; KeyCol := 1; end;
    Ord('3'), VK_NUMPAD3: begin KeyRow := 1; KeyCol := 2; end;
    VK_UP: begin KeyRow := 1; KeyCol := 3; end;
    Ord('4'), VK_NUMPAD4: begin KeyRow := 2; KeyCol := 0; end;
    Ord('5'), VK_NUMPAD5: begin KeyRow := 2; KeyCol := 1; end;
    Ord('6'), VK_NUMPAD6: begin KeyRow := 2; KeyCol := 2; end;
    VK_DOWN: begin KeyRow := 2; KeyCol := 3; end;
    Ord('7'), VK_NUMPAD7: begin KeyRow := 3; KeyCol := 0; end;
    Ord('8'), VK_NUMPAD8: begin KeyRow := 3; KeyCol := 1; end;
    Ord('9'), VK_NUMPAD9: begin KeyRow := 3; KeyCol := 2; end;
    VK_ESCAPE, VK_BACK: begin KeyRow := 3; KeyCol := 3; end;
    VK_LEFT: begin KeyRow := 4; KeyCol := 0; end;
    Ord('0'), VK_NUMPAD0: begin KeyRow := 4; KeyCol := 1; end;
    VK_RIGHT: begin KeyRow := 4; KeyCol := 2; end;
    VK_RETURN: begin KeyRow := 4; KeyCol := 3; end;
  end;
  if KeyRow >= 0 then
  begin
    FOwnerPanel.PostKey(KeyRow, KeyCol);
    Key := 0;
  end;
end;

procedure TArdSimScreen.KeyPress(var Key: Char);
begin
  inherited;
  if FOwnerPanel = nil then
    Exit;
  if Key = '#' then
  begin
    FOwnerPanel.PostKey(0, 2);
    Key := #0;
  end
  else if Key = '*' then
  begin
    FOwnerPanel.PostKey(0, 3);
    Key := #0;
  end;
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

var
  KeyRow, KeyCol, KeyIdx: Integer;
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
  FBtnBuild := MakeButton(FBar, 'Build+Run',
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
  FStatus := TUiLabel.Create(Self);
  FStatus.Parent := Self;
  FStatus.AutoSize := False;
  FStatus.Caption := '';

  FScreen := TArdSimScreen.Create(Self);
  FScreen.FOwnerPanel := Self;
  FScreen.Parent := Self;
  FScreen.Hint := 'Экран прибора. Щёлкните, чтобы клавиши ПК работали как ' +
    'клавиатура: 0-9, F1, F2, #, *, стрелки, Enter, Esc';

  FKeypad := TUiPanel.Create(Self);
  FKeypad.Parent := Self;
  FKeypad.BevelOuter := bvNone;
  FKeypad.Caption := '';
  for KeyRow := 0 to ArdSimKeyRows - 1 do
    for KeyCol := 0 to ArdSimKeyCols - 1 do
    begin
      KeyIdx := KeyRow * ArdSimKeyCols + KeyCol;
      FKeys[KeyIdx] := MakeButton(FKeypad, KeyCaptions[KeyRow, KeyCol], '',
        KeyClick);
      FKeys[KeyIdx].Tag := KeyIdx;
    end;

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

// Сверху вниз: кнопки, строка состояния, экран (по ширине, 3:2),
// клавиатура прибора, вывод Serial - всё остальное
procedure TArdSimPanel.LayoutControls;
const
  Gap = 4;
  BarH = 24;
  StatusH = 18;
  KeyH = 26;
var
  AreaW, PosY, ScreenH, ButtonW, KeyW, KeyRow, KeyCol: Integer;
  Buttons: array[0..4] of TUiButton;
  BtnIdx: Integer;
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
  ButtonW := (AreaW - 4 * 2) div 5;
  for BtnIdx := 0 to 4 do
    Buttons[BtnIdx].SetBounds(BtnIdx * (ButtonW + 2), 0, ButtonW, BarH);
  Inc(PosY, BarH + 2);
  FStatus.SetBounds(Gap, PosY, AreaW, StatusH);
  Inc(PosY, StatusH);
  ScreenH := AreaW * ArdSimScreenH div ArdSimScreenW;
  FScreen.SetBounds(Gap, PosY, AreaW, ScreenH);
  Inc(PosY, ScreenH + Gap);
  KeyW := (AreaW - (ArdSimKeyCols - 1) * 2) div ArdSimKeyCols;
  if KeyW > 70 then
    KeyW := 70;
  FKeypad.SetBounds(Gap, PosY, ArdSimKeyCols * (KeyW + 2),
                    ArdSimKeyRows * (KeyH + 2));
  for KeyRow := 0 to ArdSimKeyRows - 1 do
    for KeyCol := 0 to ArdSimKeyCols - 1 do
      FKeys[KeyRow * ArdSimKeyCols + KeyCol].SetBounds(KeyCol * (KeyW + 2),
        KeyRow * (KeyH + 2), KeyW, KeyH);
  Inc(PosY, FKeypad.Height + Gap);
  if ClientHeight - PosY - Gap > 20 then
    FSerial.SetBounds(Gap, PosY, AreaW, ClientHeight - PosY - Gap)
  else
    FSerial.SetBounds(Gap, PosY, AreaW, 20);
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

procedure TArdSimPanel.KeyClick(Sender: TObject);
var
  KeyIdx: Integer;
begin
  KeyIdx := (Sender as TComponent).Tag;
  PostKey(KeyIdx div ArdSimKeyCols, KeyIdx mod ArdSimKeyCols);
  if FScreen.CanFocus then
    FScreen.SetFocus;
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
  FScreen.Invalidate;
  if FScreen.CanFocus then
    FScreen.SetFocus;
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
    FScreen.Invalidate;
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

// Экран: RGB565 из общей памяти -> 32 бита -> StretchDIBits по размеру,
// с сохранением 3:2. Эмулятор не запущен - последняя картинка (её копия в
// FPixels) или пустое поле
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
    ACanvas.TextOut(DrawX + 8, DrawY + 8, 'Build+Run - собрать и запустить');
    ACanvas.Brush.Style := bsSolid;
  end;
  if FScreen.Focused then
  begin
    ACanvas.Brush.Color := clHighlight;
    ACanvas.FrameRect(Rect(DrawX, DrawY, DrawX + DrawW, DrawY + DrawH));
  end;
end;

end.
