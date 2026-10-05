unit WndWatch;

// ---------------------------------------------------------------------------
//  Журнал окна: что происходит с главным окном и с перерисовкой.
//
//  Для поиска давней ошибки: когда поверх окна программы двигают другое
//  окно, на полосе вкладок и на строке состояния остаются белые полосы, а
//  потом окно пропадает с экрана, как свёрнутое (значок на панели задач
//  остаётся, щелчок по нему возвращает окно). Журнал - wnd.log рядом с exe.
//
//  Что пишется:
//  - окно приложения (Application.Handle, ему принадлежит значок на панели
//    задач) и главное окно: WM_SYSCOMMAND (свернуть, развернуть ...),
//    WM_SHOWWINDOW, WM_SIZE, WM_WINDOWPOSCHANGED с показом, скрытием или
//    сменой места в стопке окон, WM_ACTIVATEAPP, WM_ACTIVATE - с тем, какое
//    окно было на переднем плане;
//  - смена состояния окна (свёрнуто, скрыто, показано) по опросу раз в
//    250 мс - на случай, если сообщение прошло мимо;
//  - у окон с проверкой перерисовки (полоса вкладок, строка состояния ...):
//    область, которая не перерисована дольше 500 мс (сообщения программа в
//    это время выбирает - иначе опрос бы не сработал), и когда её
//    перерисовали; WM_PAINT дольше 100 мс; больше 60 WM_PAINT за секунду
//    (перерисовка по кругу); исключение внутри WM_PAINT и WM_ERASEBKGND.
//
//  Подключение - цепочкой WindowProc, как TMsgTimer в Unit1: обработка
//  окна не меняется, только запись до и после. Опрос - таймер своего
//  скрытого окна (AllocateHWnd) в главном потоке.
//
//  Кто скрыл или свернул окно: при скрытии главного окна (WM_SHOWWINDOW с
//  показом 0), команде SC_MINIMIZE и сворачивании окна приложения
//  (WM_SIZE SIZE_MINIMIZED) пишутся
//  - пришло ли сообщение из другого потока или процесса (InSendMessageEx):
//    тогда вызов сделан не нашим кодом - Windows, оболочка и т.п.;
//  - цепочка вызовов главного потока по .map (HangWatchCallStack): если
//    вызов наш, в ней видна процедура, которая его сделала.
//
//  Белые полосы (полоса вкладок, строка состояния - WndWatchControl с
//  AWhiteCheck): раз в 500 мс читаются две строки пикселей окна - вторая
//  сверху и вторая снизу - из его собственного рисунка (DC окна) и с
//  экрана. Серия белых пикселей ($FFFFFF) от 16 подряд - в журнал:
//  - «белая полоса в окне» - белое нарисовано в самом окне (его WM_PAINT
//    или стирание фона); к записи - последние сообщения рисования этого
//    окна (WM_PAINT с областью, WM_ERASEBKGND, WM_NCPAINT ...), время и
//    длительность;
//  - «белое только на экране» - в рисунке окна белого нет, а на экране в
//    этих точках оно есть, и сверху нет другого окна: окно нарисовано, но
//    на экран не попало (вывод окна на экран делает Windows).
//  В начале журнала - включена ли композиция рабочего стола (Aero, DWM).
//
//  Журнал больше 2 МБ при запуске переименовывается в wnd.old.log.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Controls, Forms,
  HangWatch;    // HangWatchCallStack - цепочка вызовов по .map

// Начать журнал ALogFile: окно приложения подключается сразу
procedure WndWatchStart(const ALogFile: string);
// Подключить окно AControl под именем AName. APaintCheck - следить за
// перерисовкой (непрорисованная область, частота и длительность WM_PAINT).
procedure WndWatchControl(AControl: TWinControl; const AName: string;
                          APaintCheck: Boolean;
                          AWhiteCheck: Boolean = False);
// То же для главного окна: дополнительно при его скрытии и сворачивании -
// откуда пришло сообщение и цепочка вызовов
procedure WndWatchMainForm(AForm: TWinControl; const AName: string);
// Остановить журнал (FormDestroy главного окна - до уничтожения окон)
procedure WndWatchStop;

implementation

const
  PollInterval = 250;     // опрос состояния, мс
  DirtyLimit = 500;       // область не перерисована дольше - в журнал
  PaintSlowLimit = 100;   // WM_PAINT дольше - в журнал
  PaintRateLimit = 60;    // WM_PAINT за секунду больше - в журнал
  LogMaxSize = 2 * 1024 * 1024;
  WhiteRunMin = 16;       // белых пикселей подряд - полоса
  TraceSize = 24;         // сколько последних сообщений рисования помнить

type
  // Сообщение рисования окна - для записи вместе с белой полосой
  TMsgTrace = record
    Tick: Cardinal;
    MsgId: Cardinal;
    WParamVal: Integer;
    AreaRect: TRect;        // WM_PAINT - область перерисовки, стирание -
    HasArea: Boolean;       // область отсечения DC
    Spent: Cardinal;
  end;

  TPixelRow = array[0..32767] of Cardinal;
  PPixelRow = ^TPixelRow;

  TWatchItem = class
  public
    Control: TWinControl;
    ItemName: string;
    OldProc: TWndMethod;
    PaintCheck: Boolean;
    WhiteCheck: Boolean;      // искать белые полосы
    StackOnHide: Boolean;     // при скрытии и сворачивании - кто вызвал
    Traces: array[0..TraceSize - 1] of TMsgTrace;
    TracePos: Integer;        // куда писать следующее
    TraceCount: Integer;
    WhiteWinText: string;     // последняя записанная полоса в окне, '' - нет
    WhiteWinSince: Cardinal;
    WhiteScrText: string;     // белое только на экране
    WhiteScrSince: Cardinal;
    PaintCount: Integer;      // WM_PAINT с прошлой секунды
    DirtySince: Cardinal;     // с какого опроса есть непрорисованная область
    DirtyLogged: Boolean;
    StateKnown: Boolean;
    LastIconic: Boolean;
    LastVisible: Boolean;
    procedure WatchProc(var Message: TMessage);
    procedure AddTrace(const ATrace: TMsgTrace);
    procedure TracesTo(ALines: TStrings; ANowTick: Cardinal);
  end;

  TWatcher = class
  private
    FLogFile: string;
    FItems: TList;
    FTimerWnd: HWND;
    FActive: Boolean;
    FSecondStart: Cardinal;
    FAppIconic: Boolean;
    FAppVisible: Boolean;
    FAppStateKnown: Boolean;
    FHooked: Boolean;
    FWhiteTurn: Boolean;      // проверка полос - через раз (500 мс)
    procedure CheckWhite(AItem: TWatchItem; AWnd: HWND; ANowTick: Cardinal);
    procedure TimerWndProc(var Message: TMessage);
    function  AppHook(var Message: TMessage): Boolean;
    procedure Poll;
  public
    constructor Create(const ALogFile: string);
    destructor Destroy; override;
    procedure Log(const AText: string);
    procedure LogWindowMessage(const AWho: string; AWnd: HWND;
                               var Message: TMessage; AAfter: Boolean);
    procedure LogWhoCalled(const AWho, AWhat: string);
    procedure Stop;
  end;

var
  Watcher: TWatcher = nil;
  // Подключённые окна: живут до конца программы - окно может обратиться к
  // своей WindowProc и после WndWatchStop, пока уничтожается
  AllItems: TList = nil;

// ---------------------------------------------------------------------------
//  Описание окон и сообщений
// ---------------------------------------------------------------------------

function WndText(AWnd: HWND): string;
var
  ClassBuf, TitleBuf: array[0..127] of Char;
  ProcId: DWORD;
  Owner: string;
begin
  if AWnd = 0 then
  begin
    Result := '(нет)';
    Exit;
  end;
  ClassBuf[0] := #0;
  TitleBuf[0] := #0;
  GetClassName(AWnd, ClassBuf, SizeOf(ClassBuf));
  GetWindowText(AWnd, TitleBuf, SizeOf(TitleBuf));
  GetWindowThreadProcessId(AWnd, @ProcId);
  if ProcId = GetCurrentProcessId then
    Owner := 'наше'
  else
    Owner := 'чужое';
  Result := Format('$%x %s "%s" (%s)', [AWnd, string(ClassBuf),
                                       string(TitleBuf), Owner]);
end;

function StateText(AWnd: HWND): string;
begin
  if not IsWindow(AWnd) then
  begin
    Result := 'нет окна';
    Exit;
  end;
  if IsWindowVisible(AWnd) then
    Result := 'видно'
  else
    Result := 'скрыто';
  if IsIconic(AWnd) then
    Result := Result + ', свёрнуто';
  if IsZoomed(AWnd) then
    Result := Result + ', развёрнуто';
end;

function SysCommandText(AParam: WPARAM): string;
begin
  case AParam and $FFF0 of
    SC_MINIMIZE: Result := 'SC_MINIMIZE';
    SC_MAXIMIZE: Result := 'SC_MAXIMIZE';
    SC_RESTORE: Result := 'SC_RESTORE';
    SC_CLOSE: Result := 'SC_CLOSE';
    SC_MOVE: Result := 'SC_MOVE';
    SC_SIZE: Result := 'SC_SIZE';
    SC_KEYMENU: Result := 'SC_KEYMENU';
    SC_MOUSEMENU: Result := 'SC_MOUSEMENU';
  else
    Result := '$' + IntToHex(AParam and $FFF0, 4);
  end;
end;

function SizeText(AParam: WPARAM): string;
begin
  case AParam of
    SIZE_RESTORED: Result := 'SIZE_RESTORED';
    SIZE_MINIMIZED: Result := 'SIZE_MINIMIZED';
    SIZE_MAXIMIZED: Result := 'SIZE_MAXIMIZED';
    SIZE_MAXSHOW: Result := 'SIZE_MAXSHOW';
    SIZE_MAXHIDE: Result := 'SIZE_MAXHIDE';
  else
    Result := IntToStr(AParam);
  end;
end;

function InsertAfterText(AWnd: HWND): string;
begin
  case Integer(AWnd) of
    0: Result := 'HWND_TOP';
    1: Result := 'HWND_BOTTOM';
    -1: Result := 'HWND_TOPMOST';
    -2: Result := 'HWND_NOTOPMOST';
  else
    Result := WndText(AWnd);
  end;
end;

// Сообщение - скрытие или сворачивание окна: тогда в журнал - кто вызвал
function HideOrMinimizeText(const Message: TMessage): string;
begin
  Result := '';
  case Message.Msg of
    WM_SHOWWINDOW:
      if Message.WParam = 0 then
        Result := Format('WM_SHOWWINDOW показ=0 причина=%d',
                         [Message.LParam]);
    WM_SYSCOMMAND:
      if Message.WParam and $FFF0 = SC_MINIMIZE then
        Result := 'WM_SYSCOMMAND SC_MINIMIZE';
    WM_SIZE:
      if Message.WParam = SIZE_MINIMIZED then
        Result := 'WM_SIZE SIZE_MINIMIZED';
  end;
end;

// Своё описание: есть ли InSendMessageEx в Windows.pas Delphi 7 - не
// проверено, а в user32 она с Windows 2000
function InSendMessageExApi(lpReserved: Pointer): DWORD; stdcall;
  external user32 name 'InSendMessageEx';

function MsgShortName(AMsgId: Cardinal): string;
begin
  case AMsgId of
    WM_PAINT: Result := 'WM_PAINT';
    WM_ERASEBKGND: Result := 'WM_ERASEBKGND';
    WM_NCPAINT: Result := 'WM_NCPAINT';
    WM_PRINTCLIENT: Result := 'WM_PRINTCLIENT';
    WM_SETREDRAW: Result := 'WM_SETREDRAW';
    WM_SIZE: Result := 'WM_SIZE';
    WM_WINDOWPOSCHANGED: Result := 'WM_WINDOWPOSCHANGED';
    WM_DRAWITEM: Result := 'WM_DRAWITEM';
    CN_DRAWITEM: Result := 'CN_DRAWITEM';
  else
    Result := '$' + IntToHex(AMsgId, 4);
  end;
end;

function IsTracedMsg(AMsgId: Cardinal): Boolean;
begin
  Result := (AMsgId = WM_PAINT) or (AMsgId = WM_ERASEBKGND) or
            (AMsgId = WM_NCPAINT) or (AMsgId = WM_PRINTCLIENT) or
            (AMsgId = WM_SETREDRAW) or (AMsgId = WM_SIZE) or
            (AMsgId = WM_WINDOWPOSCHANGED) or (AMsgId = WM_DRAWITEM) or
            (AMsgId = CN_DRAWITEM);
end;

// Первая серия белых пикселей не короче WhiteRunMin в строке ширины
// AWidth, которая в ADC начинается в (AOrgX, AOrgY). ARunFrom, ARunTo - от
// начала строки.
function FindWhiteRun(ADC: HDC; AOrgX, AOrgY, AWidth: Integer;
                      var ARunFrom, ARunTo: Integer): Boolean;
var
  BmpInfo: TBitmapInfo;
  Bits: Pointer;
  MemDC: HDC;
  MemBmp, OldBmp: HBITMAP;
  Pixels: PPixelRow;
  PixIdx, RunStart: Integer;
begin
  Result := False;
  ARunFrom := -1;
  ARunTo := -1;
  if (AWidth <= 0) or (ADC = 0) then
    Exit;
  if AWidth > High(TPixelRow) + 1 then
    AWidth := High(TPixelRow) + 1;

  FillChar(BmpInfo, SizeOf(BmpInfo), 0);
  BmpInfo.bmiHeader.biSize := SizeOf(TBitmapInfoHeader);
  BmpInfo.bmiHeader.biWidth := AWidth;
  BmpInfo.bmiHeader.biHeight := -1;      // сверху вниз
  BmpInfo.bmiHeader.biPlanes := 1;
  BmpInfo.bmiHeader.biBitCount := 32;
  BmpInfo.bmiHeader.biCompression := BI_RGB;

  MemDC := CreateCompatibleDC(ADC);
  if MemDC = 0 then
    Exit;
  Bits := nil;
  MemBmp := CreateDIBSection(MemDC, BmpInfo, DIB_RGB_COLORS, Bits, 0, 0);
  if (MemBmp = 0) or (Bits = nil) then
  begin
    if MemBmp <> 0 then
      DeleteObject(MemBmp);
    DeleteDC(MemDC);
    Exit;
  end;
  OldBmp := SelectObject(MemDC, MemBmp);
  try
    if not BitBlt(MemDC, 0, 0, AWidth, 1, ADC, AOrgX, AOrgY, SRCCOPY) then
      Exit;
    GdiFlush;
    Pixels := PPixelRow(Bits);
    RunStart := -1;
    for PixIdx := 0 to AWidth do
    begin
      if (PixIdx < AWidth) and
         (Pixels^[PixIdx] and $FFFFFF = $FFFFFF) then
      begin
        if RunStart < 0 then
          RunStart := PixIdx;
        Continue;
      end;
      // Серия кончилась (или кончилась строка)
      if (RunStart >= 0) and (PixIdx - RunStart >= WhiteRunMin) then
      begin
        ARunFrom := RunStart;
        ARunTo := PixIdx - 1;
        Result := True;
        Exit;
      end;
      RunStart := -1;
    end;
  finally
    SelectObject(MemDC, OldBmp);
    DeleteObject(MemBmp);
    DeleteDC(MemDC);
  end;
end;

// Композиция рабочего стола (Aero): dwmapi.dll есть с Vista
function CompositionText: string;
type
  TDwmIsCompositionEnabled = function(var AEnabled: BOOL): HResult; stdcall;
var
  DwmLib: HMODULE;
  DwmFunc: TDwmIsCompositionEnabled;
  Enabled: BOOL;
begin
  Result := 'нет dwmapi.dll (композиции нет)';
  DwmLib := LoadLibrary('dwmapi.dll');
  if DwmLib = 0 then
    Exit;
  try
    @DwmFunc := GetProcAddress(DwmLib, 'DwmIsCompositionEnabled');
    if not Assigned(DwmFunc) then
      Exit;
    Enabled := False;
    if DwmFunc(Enabled) <> 0 then
      Result := 'не удалось узнать'
    else if Enabled then
      Result := 'включена (Aero)'
    else
      Result := 'выключена';
  finally
    FreeLibrary(DwmLib);
  end;
end;

// Программа на переднем плане (окно переднего плана - нашего процесса)
function AppIsForeground: Boolean;
var
  ProcId: DWORD;
begin
  ProcId := 0;
  GetWindowThreadProcessId(GetForegroundWindow, @ProcId);
  Result := ProcId = GetCurrentProcessId;
end;

// Откуда пришло сообщение (InSendMessageEx) - словами
function SenderText: string;
const
  ISMEX_SEND_ = $00000001;
  ISMEX_REPLIED_ = $00000008;
var
  Flags: DWORD;
begin
  Flags := InSendMessageExApi(nil);
  if Flags = 0 then
    Result := 'из своего потока (вызов нашего кода или выборка из очереди)'
  else if Flags and ISMEX_SEND_ <> 0 then
    Result := 'прислано из другого потока или процесса (SendMessage)'
  else
    Result := Format('из другого потока, флаги $%x', [Flags]);
  if Flags and ISMEX_REPLIED_ <> 0 then
    Result := Result + ', ответ уже дан';
end;

// ---------------------------------------------------------------------------
//  TWatcher
// ---------------------------------------------------------------------------

constructor TWatcher.Create(const ALogFile: string);
var
  OldFile: string;
  SearchRec: TSearchRec;
begin
  inherited Create;
  FLogFile := ALogFile;
  FItems := TList.Create;

  // Большой журнал - в .old, новый с начала
  if FindFirst(FLogFile, faAnyFile, SearchRec) = 0 then
  begin
    if SearchRec.Size > LogMaxSize then
    begin
      OldFile := ChangeFileExt(FLogFile, '.old.log');
      DeleteFile(OldFile);
      RenameFile(FLogFile, OldFile);
    end;
    FindClose(SearchRec);
  end;

  FActive := True;
  FSecondStart := GetTickCount;
  Log('=== запуск ' + Application.ExeName);
  Log('композиция рабочего стола: ' + CompositionText);

  Application.HookMainWindow(AppHook);
  FHooked := True;
  FTimerWnd := AllocateHWnd(TimerWndProc);
  SetTimer(FTimerWnd, 1, PollInterval, nil);
end;

destructor TWatcher.Destroy;
begin
  Stop;
  FItems.Free;
  inherited Destroy;
end;

procedure TWatcher.Stop;
begin
  if not FActive then
    Exit;
  FActive := False;
  if FTimerWnd <> 0 then
  begin
    KillTimer(FTimerWnd, 1);
    DeallocateHWnd(FTimerWnd);
    FTimerWnd := 0;
  end;
  if FHooked then
  begin
    Application.UnhookMainWindow(AppHook);
    FHooked := False;
  end;
  Log('=== остановлен');
end;

// Строка с временем; файл открывается на каждую запись - журнал не
// потеряется, если программа упадёт
procedure TWatcher.Log(const AText: string);
var
  Stream: TFileStream;
  LineText: string;
begin
  LineText := FormatDateTime('dd.mm.yy hh:nn:ss.zzz', Now) + '  ' + AText +
              #13#10;
  try
    if FileExists(FLogFile) then
    begin
      Stream := TFileStream.Create(FLogFile, fmOpenWrite or fmShareDenyNone);
      Stream.Seek(0, soFromEnd);
    end
    else
      Stream := TFileStream.Create(FLogFile, fmCreate);
    try
      Stream.WriteBuffer(LineText[1], Length(LineText));
    finally
      Stream.Free;
    end;
  except
    // Журнал не пишется (нет доступа к папке) - работе окна не мешаем
  end;
end;

// Сообщения о показе, состоянии и активности окна AWnd. AAfter - запись
// после обработки (с состоянием окна после неё)
procedure TWatcher.LogWindowMessage(const AWho: string; AWnd: HWND;
                                    var Message: TMessage; AAfter: Boolean);
var
  PosInfo: PWindowPos;
  Flags: Cardinal;
  Parts: string;
begin
  if not FActive then
    Exit;
  case Message.Msg of
    WM_SYSCOMMAND:
      if not AAfter and (Message.WParam and $FFF0 <> SC_MOVE) and
         (Message.WParam and $FFF0 <> SC_KEYMENU) then
        Log(Format('%s: WM_SYSCOMMAND %s, мышь (%d,%d); на переднем ' +
                   'плане %s', [AWho, SysCommandText(Message.WParam),
                   SmallInt(LoWord(Message.LParam)),
                   SmallInt(HiWord(Message.LParam)),
                   WndText(GetForegroundWindow)]));
    WM_SHOWWINDOW:
      if AAfter then
        Log(Format('%s: WM_SHOWWINDOW показ=%d причина=%d -> %s',
                   [AWho, Message.WParam, Message.LParam,
                    StateText(AWnd)]));
    WM_SIZE:
      if AAfter and (Message.WParam <> SIZE_RESTORED) then
        Log(Format('%s: WM_SIZE %s -> %s', [AWho, SizeText(Message.WParam),
                   StateText(AWnd)]));
    WM_WINDOWPOSCHANGED:
      if AAfter then
      begin
        PosInfo := PWindowPos(Message.LParam);
        if PosInfo = nil then
          Exit;
        Flags := PosInfo^.flags;
        Parts := '';
        if Flags and SWP_SHOWWINDOW <> 0 then
          Parts := Parts + ' SHOW';
        if Flags and SWP_HIDEWINDOW <> 0 then
          Parts := Parts + ' HIDE';
        if Flags and SWP_NOZORDER = 0 then
          Parts := Parts + ' место в стопке: после ' +
                   InsertAfterText(PosInfo^.hwndInsertAfter);
        if Parts <> '' then
          Log(Format('%s: WM_WINDOWPOSCHANGED%s; (%d,%d %dx%d) -> %s',
                     [AWho, Parts, PosInfo^.x, PosInfo^.y, PosInfo^.cx,
                      PosInfo^.cy, StateText(AWnd)]));
      end;
    WM_ACTIVATEAPP:
      if AAfter then
        Log(Format('%s: WM_ACTIVATEAPP %d; на переднем плане %s',
                   [AWho, Message.WParam, WndText(GetForegroundWindow)]));
    WM_ACTIVATE:
      if AAfter then
        Log(Format('%s: WM_ACTIVATE %d, другое окно %s', [AWho,
                   LoWord(Message.WParam), WndText(HWND(Message.LParam))]));
  end;
end;

// Кто вызвал: откуда сообщение и цепочка вызовов главного потока
procedure TWatcher.LogWhoCalled(const AWho, AWhat: string);
var
  StackLines: TStringList;
  LineIdx: Integer;
begin
  if not FActive then
    Exit;
  StackLines := TStringList.Create;
  try
    try
      HangWatchCallStack(StackLines);
    except
      on E: Exception do
        StackLines.Add('цепочка не получена: ' + E.Message);
    end;
    Log(Format('%s: %s - %s; на переднем плане %s',
               [AWho, AWhat, SenderText, WndText(GetForegroundWindow)]));
    for LineIdx := 0 to StackLines.Count - 1 do
      Log('    ' + StackLines[LineIdx]);
  finally
    StackLines.Free;
  end;
end;

// Окно приложения: до его обработки (крюк HookMainWindow), дальше - как
// обычно
function TWatcher.AppHook(var Message: TMessage): Boolean;
var
  WhatText: string;
begin
  Result := False;
  if FActive then
  begin
    WhatText := HideOrMinimizeText(Message);
    if WhatText <> '' then
      LogWhoCalled('окно приложения', WhatText);
  end;
  if FActive then
    LogWindowMessage('окно приложения', Application.Handle, Message, False);
  // Состояние после - в опросе (Poll): у крюка нет вызова "после"
  if FActive and ((Message.Msg = WM_SHOWWINDOW) or
                  (Message.Msg = WM_SIZE) or
                  (Message.Msg = WM_WINDOWPOSCHANGED) or
                  (Message.Msg = WM_ACTIVATEAPP)) then
    LogWindowMessage('окно приложения', Application.Handle, Message, True);
end;

procedure TWatcher.TimerWndProc(var Message: TMessage);
begin
  if Message.Msg = WM_TIMER then
  begin
    if FActive then
      Poll;
    Message.Result := 0;
  end
  else
    Message.Result := DefWindowProc(FTimerWnd, Message.Msg, Message.WParam,
                                    Message.LParam);
end;

// Опрос: состояние окон, непрорисованные области, частота WM_PAINT
procedure TWatcher.Poll;
var
  ItemIdx: Integer;
  Item: TWatchItem;
  NowTick: Cardinal;
  NowIconic, NowVisible: Boolean;
  DirtyRect: TRect;
  WndHandle: HWND;
  SecondDone: Boolean;
begin
  NowTick := GetTickCount;

  // Окно приложения
  NowIconic := IsIconic(Application.Handle);
  NowVisible := IsWindowVisible(Application.Handle);
  if FAppStateKnown and ((NowIconic <> FAppIconic) or
                         (NowVisible <> FAppVisible)) then
    Log('окно приложения: состояние -> ' + StateText(Application.Handle) +
        '; на переднем плане ' + WndText(GetForegroundWindow));
  FAppIconic := NowIconic;
  FAppVisible := NowVisible;
  FAppStateKnown := True;

  SecondDone := NowTick - FSecondStart >= 1000;
  FWhiteTurn := not FWhiteTurn;

  for ItemIdx := 0 to FItems.Count - 1 do
  begin
    Item := TWatchItem(FItems[ItemIdx]);
    if (Item.Control = nil) or not Item.Control.HandleAllocated then
      Continue;
    WndHandle := Item.Control.Handle;

    // Состояние окна (главное: свёрнуто, скрыто)
    NowIconic := IsIconic(WndHandle);
    NowVisible := IsWindowVisible(WndHandle);
    if Item.StateKnown and ((NowIconic <> Item.LastIconic) or
                            (NowVisible <> Item.LastVisible)) then
      Log(Item.ItemName + ': состояние -> ' + StateText(WndHandle) +
          '; на переднем плане ' + WndText(GetForegroundWindow));
    Item.LastIconic := NowIconic;
    Item.LastVisible := NowVisible;
    Item.StateKnown := True;

    if Item.WhiteCheck and FWhiteTurn and NowVisible and not NowIconic then
      CheckWhite(Item, WndHandle, NowTick);

    if not Item.PaintCheck then
      Continue;

    // Непрорисованная область. Опрос идёт таймером, а WM_TIMER Windows
    // выдаёт после WM_PAINT: раз дошло до опроса, а область осталась, -
    // её не перерисовали
    if NowVisible and GetUpdateRect(WndHandle, DirtyRect, False) then
    begin
      if Item.DirtySince = 0 then
        Item.DirtySince := NowTick
      else if not Item.DirtyLogged and
              (NowTick - Item.DirtySince >= DirtyLimit) then
      begin
        Log(Format('%s: не перерисовано %d мс, область (%d,%d)-(%d,%d)',
                   [Item.ItemName, NowTick - Item.DirtySince,
                    DirtyRect.Left, DirtyRect.Top, DirtyRect.Right,
                    DirtyRect.Bottom]));
        Item.DirtyLogged := True;
      end;
    end
    else
    begin
      if Item.DirtyLogged then
        Log(Format('%s: перерисовано через %d мс',
                   [Item.ItemName, NowTick - Item.DirtySince]));
      Item.DirtySince := 0;
      Item.DirtyLogged := False;
    end;

    if SecondDone then
    begin
      if Item.PaintCount > PaintRateLimit then
        Log(Format('%s: WM_PAINT %d раз за %d мс', [Item.ItemName,
                   Item.PaintCount, NowTick - FSecondStart]));
      Item.PaintCount := 0;
    end;
  end;

  if SecondDone then
    FSecondStart := NowTick;
end;

// Белые полосы в окне AWnd: строка 1 и предпоследняя, в рисунке окна и
// на экране. Пишется только смена: появилась, изменилась, пропала.
procedure TWatcher.CheckWhite(AItem: TWatchItem; AWnd: HWND;
                              ANowTick: Cardinal);
var
  ClientBox: TRect;
  RowIdx, RowY, RunFrom, RunTo, ScrFrom, ScrTo, MidX: Integer;
  WinDC, ScrDC: HDC;
  RowOrigin, MidPt: TPoint;
  WinText, ScrText, ActiveText: string;
  HitWnd: HWND;
  TraceLines: TStringList;
  LineIdx: Integer;
begin
  if not GetClientRect(AWnd, ClientBox) then
    Exit;
  if (ClientBox.Right < WhiteRunMin) or (ClientBox.Bottom < 4) then
    Exit;

  WinText := '';
  ScrText := '';
  WinDC := GetDC(AWnd);
  ScrDC := GetDC(0);
  try
    for RowIdx := 0 to 1 do
    begin
      if RowIdx = 0 then
        RowY := 1
      else
        RowY := ClientBox.Bottom - 2;

      // Рисунок окна
      if FindWhiteRun(WinDC, 0, RowY, ClientBox.Right, RunFrom, RunTo) then
        WinText := WinText + Format(' строка %d x=%d..%d;',
                                    [RowY, RunFrom, RunTo]);

      // Экран: только если в середине найденного белого сверху наше окно
      RowOrigin := Point(0, RowY);
      Windows.ClientToScreen(AWnd, RowOrigin);
      if FindWhiteRun(ScrDC, RowOrigin.X, RowOrigin.Y, ClientBox.Right,
                      ScrFrom, ScrTo) then
      begin
        MidX := (ScrFrom + ScrTo) div 2;
        MidPt := Point(RowOrigin.X + MidX, RowOrigin.Y);
        HitWnd := WindowFromPoint(MidPt);
        if (HitWnd = AWnd) or IsChild(AWnd, HitWnd) then
          // В рисунке окна в этом месте белого нет - пишем отдельно
          if not FindWhiteRun(WinDC, ScrFrom, RowY, ScrTo - ScrFrom + 1,
                              RunFrom, RunTo) then
            ScrText := ScrText + Format(' строка %d x=%d..%d;',
                                        [RowY, ScrFrom, ScrTo]);
      end;
    end;
  finally
    ReleaseDC(0, ScrDC);
    ReleaseDC(AWnd, WinDC);
  end;

  if AppIsForeground then
    ActiveText := 'программа активна'
  else
    ActiveText := 'программа не активна, на переднем плане ' +
                  WndText(GetForegroundWindow);

  if WinText <> AItem.WhiteWinText then
  begin
    if WinText <> '' then
    begin
      Log(Format('%s: белая полоса в окне:%s %s', [AItem.ItemName, WinText,
                 ActiveText]));
      if AItem.WhiteWinText = '' then
      begin
        AItem.WhiteWinSince := ANowTick;
        TraceLines := TStringList.Create;
        try
          AItem.TracesTo(TraceLines, ANowTick);
          Log('    последние сообщения рисования (мс назад, сообщение, ' +
              'область, длительность):');
          for LineIdx := 0 to TraceLines.Count - 1 do
            Log('    ' + TraceLines[LineIdx]);
        finally
          TraceLines.Free;
        end;
      end;
    end
    else
      Log(Format('%s: белой полосы в окне больше нет (была %d мс)',
                 [AItem.ItemName, ANowTick - AItem.WhiteWinSince]));
    AItem.WhiteWinText := WinText;
  end;

  if ScrText <> AItem.WhiteScrText then
  begin
    if ScrText <> '' then
    begin
      if AItem.WhiteScrText = '' then
        AItem.WhiteScrSince := ANowTick;
      Log(Format('%s: белое только на экране (в рисунке окна его нет):%s ' +
                 '%s', [AItem.ItemName, ScrText, ActiveText]));
    end
    else
      Log(Format('%s: на экране белого больше нет (было %d мс)',
                 [AItem.ItemName, ANowTick - AItem.WhiteScrSince]));
    AItem.WhiteScrText := ScrText;
  end;
end;

// ---------------------------------------------------------------------------
//  TWatchItem
// ---------------------------------------------------------------------------

procedure TWatchItem.AddTrace(const ATrace: TMsgTrace);
begin
  Traces[TracePos] := ATrace;
  TracePos := (TracePos + 1) mod TraceSize;
  if TraceCount < TraceSize then
    Inc(TraceCount);
end;

// Последние сообщения рисования, от старых к новым
procedure TWatchItem.TracesTo(ALines: TStrings; ANowTick: Cardinal);
var
  StepIdx, SlotIdx: Integer;
  Trace: TMsgTrace;
  AreaText: string;
begin
  for StepIdx := 0 to TraceCount - 1 do
  begin
    SlotIdx := (TracePos - TraceCount + StepIdx + TraceSize) mod TraceSize;
    Trace := Traces[SlotIdx];
    if Trace.HasArea then
      AreaText := Format('(%d,%d)-(%d,%d)', [Trace.AreaRect.Left,
                         Trace.AreaRect.Top, Trace.AreaRect.Right,
                         Trace.AreaRect.Bottom])
    else
      AreaText := '';
    ALines.Add(Format('%6d  %-20s %-22s %d мс wParam=$%x',
                      [ANowTick - Trace.Tick, MsgShortName(Trace.MsgId),
                       AreaText, Trace.Spent, Trace.WParamVal]));
  end;
end;

procedure TWatchItem.WatchProc(var Message: TMessage);
var
  StartTick, Spent: Cardinal;
  MsgId: Cardinal;
  WndHandle: HWND;
  Trace: TMsgTrace;
  Traced: Boolean;
begin
  MsgId := Message.Msg;
  if (Watcher = nil) or not Watcher.FActive then
  begin
    OldProc(Message);
    Exit;
  end;

  WndHandle := 0;
  if Control.HandleAllocated then
    WndHandle := Control.Handle;
  Watcher.LogWindowMessage(ItemName, WndHandle, Message, False);

  StartTick := GetTickCount;
  if MsgId = WM_PAINT then
    Inc(PaintCount);
  if StackOnHide and (HideOrMinimizeText(Message) <> '') then
    Watcher.LogWhoCalled(ItemName, HideOrMinimizeText(Message));

  // Сообщение рисования - в память окна (к записи о белой полосе)
  Traced := WhiteCheck and IsTracedMsg(MsgId);
  if Traced then
  begin
    FillChar(Trace, SizeOf(Trace), 0);
    Trace.Tick := StartTick;
    Trace.MsgId := MsgId;
    Trace.WParamVal := Message.WParam;
    if (MsgId = WM_PAINT) and (WndHandle <> 0) then
      Trace.HasArea := GetUpdateRect(WndHandle, Trace.AreaRect, False)
    else if ((MsgId = WM_ERASEBKGND) or (MsgId = WM_PRINTCLIENT)) and
            (Message.WParam <> 0) then
      Trace.HasArea := GetClipBox(HDC(Message.WParam), Trace.AreaRect) <>
                       ERROR;
  end;

  try
    OldProc(Message);
  except
    on E: Exception do
    begin
      if (MsgId = WM_PAINT) or (MsgId = WM_ERASEBKGND) or
         (MsgId = WM_NCPAINT) then
        Watcher.Log(Format('%s: исключение в $%x: %s: %s',
                           [ItemName, MsgId, E.ClassName, E.Message]));
      raise;
    end;
  end;
  Spent := GetTickCount - StartTick;
  if Traced then
  begin
    Trace.Spent := Spent;
    AddTrace(Trace);
  end;

  if (Watcher = nil) or not Watcher.FActive then
    Exit;
  if PaintCheck and (MsgId = WM_PAINT) and (Spent >= PaintSlowLimit) then
    Watcher.Log(Format('%s: WM_PAINT %d мс', [ItemName, Spent]));
  if Control.HandleAllocated then
    Watcher.LogWindowMessage(ItemName, Control.Handle, Message, True);
end;

// ---------------------------------------------------------------------------

procedure WndWatchStart(const ALogFile: string);
begin
  if Watcher <> nil then
    Exit;
  Watcher := TWatcher.Create(ALogFile);
end;

procedure WndWatchControl(AControl: TWinControl; const AName: string;
                          APaintCheck: Boolean;
                          AWhiteCheck: Boolean = False);
var
  Item: TWatchItem;
begin
  if (Watcher = nil) or (AControl = nil) then
    Exit;
  Item := TWatchItem.Create;
  Item.Control := AControl;
  Item.ItemName := AName;
  Item.PaintCheck := APaintCheck;
  Item.WhiteCheck := AWhiteCheck;
  Item.OldProc := AControl.WindowProc;
  AControl.WindowProc := Item.WatchProc;
  Watcher.FItems.Add(Item);
  if AllItems = nil then
    AllItems := TList.Create;
  AllItems.Add(Item);
end;

procedure WndWatchMainForm(AForm: TWinControl; const AName: string);
begin
  WndWatchControl(AForm, AName, False);
  if (Watcher <> nil) and (Watcher.FItems.Count > 0) then
    TWatchItem(Watcher.FItems[Watcher.FItems.Count - 1]).StackOnHide := True;
end;

procedure WndWatchStop;
var
  ItemIdx: Integer;
begin
  if Watcher = nil then
    Exit;
  Watcher.Stop;
  // Окна ещё живы: обработчики остаются в цепочке и дальше только передают
  // сообщения (FActive = False); ссылки на окна опросу больше не нужны
  for ItemIdx := 0 to Watcher.FItems.Count - 1 do
  begin
    TWatchItem(Watcher.FItems[ItemIdx]).PaintCheck := False;
    TWatchItem(Watcher.FItems[ItemIdx]).WhiteCheck := False;
  end;
end;

initialization

finalization
  // Watcher и элементы не освобождаются: окна, уничтожаясь после
  // WndWatchStop, ещё могут вызвать WatchProc. Выход из программы - память
  // вернёт Windows.

end.
