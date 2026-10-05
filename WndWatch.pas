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
//  Журнал больше 2 МБ при запуске переименовывается в wnd.old.log.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Controls, Forms;

// Начать журнал ALogFile: окно приложения подключается сразу
procedure WndWatchStart(const ALogFile: string);
// Подключить окно AControl под именем AName. APaintCheck - следить за
// перерисовкой (непрорисованная область, частота и длительность WM_PAINT).
procedure WndWatchControl(AControl: TWinControl; const AName: string;
                          APaintCheck: Boolean);
// Остановить журнал (FormDestroy главного окна - до уничтожения окон)
procedure WndWatchStop;

implementation

const
  PollInterval = 250;     // опрос состояния, мс
  DirtyLimit = 500;       // область не перерисована дольше - в журнал
  PaintSlowLimit = 100;   // WM_PAINT дольше - в журнал
  PaintRateLimit = 60;    // WM_PAINT за секунду больше - в журнал
  LogMaxSize = 2 * 1024 * 1024;

type
  TWatchItem = class
  public
    Control: TWinControl;
    ItemName: string;
    OldProc: TWndMethod;
    PaintCheck: Boolean;
    PaintCount: Integer;      // WM_PAINT с прошлой секунды
    DirtySince: Cardinal;     // с какого опроса есть непрорисованная область
    DirtyLogged: Boolean;
    StateKnown: Boolean;
    LastIconic: Boolean;
    LastVisible: Boolean;
    procedure WatchProc(var Message: TMessage);
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
    procedure TimerWndProc(var Message: TMessage);
    function  AppHook(var Message: TMessage): Boolean;
    procedure Poll;
  public
    constructor Create(const ALogFile: string);
    destructor Destroy; override;
    procedure Log(const AText: string);
    procedure LogWindowMessage(const AWho: string; AWnd: HWND;
                               var Message: TMessage; AAfter: Boolean);
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

// Окно приложения: до его обработки (крюк HookMainWindow), дальше - как
// обычно
function TWatcher.AppHook(var Message: TMessage): Boolean;
begin
  Result := False;
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

// ---------------------------------------------------------------------------
//  TWatchItem
// ---------------------------------------------------------------------------

procedure TWatchItem.WatchProc(var Message: TMessage);
var
  StartTick, Spent: Cardinal;
  MsgId: Cardinal;
  WndHandle: HWND;
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
                          APaintCheck: Boolean);
var
  Item: TWatchItem;
begin
  if (Watcher = nil) or (AControl = nil) then
    Exit;
  Item := TWatchItem.Create;
  Item.Control := AControl;
  Item.ItemName := AName;
  Item.PaintCheck := APaintCheck;
  Item.OldProc := AControl.WindowProc;
  AControl.WindowProc := Item.WatchProc;
  Watcher.FItems.Add(Item);
  if AllItems = nil then
    AllItems := TList.Create;
  AllItems.Add(Item);
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
    TWatchItem(Watcher.FItems[ItemIdx]).PaintCheck := False;
end;

initialization

finalization
  // Watcher и элементы не освобождаются: окна, уничтожаясь после
  // WndWatchStop, ещё могут вызвать WatchProc. Выход из программы - память
  // вернёт Windows.

end.
