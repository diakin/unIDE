unit ExtCtrls;

// ---------------------------------------------------------------------------
//  uniFAR (Free Pascal, без LCL): заменитель модуля ExtCtrls из VCL - только
//  TTimer. Таймер Windows без окна (SetTimer с процедурой): срабатывает,
//  когда цикл сообщений программы (или модальное окно Windows) выбирает
//  WM_TIMER и отдаёт его DispatchMessage. Только в пути модулей uniFAR.
// ---------------------------------------------------------------------------

{$mode delphi}

interface

uses
  Windows, SysUtils, Classes;

type
  TTimer = class(TComponent)
  private
    FInterval: Cardinal;
    FEnabled: Boolean;
    FOnTimer: TNotifyEvent;
    FTimerId: UINT_PTR;
    procedure UpdateTimer;
    procedure SetEnabled(AValue: Boolean);
    procedure SetInterval(AValue: Cardinal);
    procedure SetOnTimer(AValue: TNotifyEvent);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Enabled: Boolean read FEnabled write SetEnabled;
    property Interval: Cardinal read FInterval write SetInterval;
    property OnTimer: TNotifyEvent read FOnTimer write SetOnTimer;
  end;

implementation

var
  // Таймеры с запущенным SetTimer: номер Windows -> объект
  ActiveTimers: TList = nil;

procedure ShimTimerProc(AWnd: HWND; AMsg: UINT; AIdEvent: UINT_PTR;
  ATime: DWORD); stdcall;
var
  TimerIdx: Integer;
  Timer: TTimer;
begin
  if ActiveTimers = nil then
    Exit;
  for TimerIdx := 0 to ActiveTimers.Count - 1 do
  begin
    Timer := TTimer(ActiveTimers[TimerIdx]);
    if Timer.FTimerId = AIdEvent then
    begin
      if Assigned(Timer.FOnTimer) then
        Timer.FOnTimer(Timer);
      Exit;
    end;
  end;
end;

constructor TTimer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FInterval := 1000;
  FEnabled := True;
end;

destructor TTimer.Destroy;
begin
  FEnabled := False;
  UpdateTimer;
  inherited Destroy;
end;

procedure TTimer.UpdateTimer;
begin
  if FTimerId <> 0 then
  begin
    KillTimer(0, FTimerId);
    FTimerId := 0;
    ActiveTimers.Remove(Self);
  end;
  if FEnabled and (FInterval > 0) and Assigned(FOnTimer) then
  begin
    FTimerId := SetTimer(0, 0, FInterval, @ShimTimerProc);
    if FTimerId <> 0 then
      ActiveTimers.Add(Self);
  end;
end;

procedure TTimer.SetEnabled(AValue: Boolean);
begin
  if AValue = FEnabled then
    Exit;
  FEnabled := AValue;
  UpdateTimer;
end;

procedure TTimer.SetInterval(AValue: Cardinal);
begin
  if AValue = FInterval then
    Exit;
  FInterval := AValue;
  UpdateTimer;
end;

procedure TTimer.SetOnTimer(AValue: TNotifyEvent);
begin
  FOnTimer := AValue;
  UpdateTimer;
end;

initialization
  ActiveTimers := TList.Create;

finalization
  FreeAndNil(ActiveTimers);

end.
