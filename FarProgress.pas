unit FarProgress;

// ---------------------------------------------------------------------------
//  Стандартное окно хода операции Windows (IProgressDialog, shell32) для
//  unIDE FAR: распаковка и упаковка архивов (7z.exe). То же окно, что
//  Windows показывает при копировании файлов, но ход задаёт программа.
//  Окно живёт в своём потоке оболочки: перерисовывается само, пока unIDE
//  читает вывод 7z.exe по таймеру. Кнопка «Отмена» - Cancelled.
//
//  Окно появляется не сразу: оболочка сама показывает его, если операция
//  идёт дольше пары секунд (короткие распаковки - без окна).
// ---------------------------------------------------------------------------

// Free Pascal (uniFAR): исходник в кодировке Windows-1251 - строки с
// кириллицей в WideString без кракозябр. Delphi 7 эту строку пропускает
{$IFDEF FPC}{$CODEPAGE CP1251}{$ENDIF}

interface

uses
  Windows, SysUtils, ActiveX;

type
  IFarProgressDialog = interface(IUnknown)
    ['{EBBC7C04-315E-11D2-B62F-006097DF5BD4}']
    function StartProgressDialog(AParent: HWND; AEnableModeless: IUnknown;
      AFlags: DWORD; AReserved: Pointer): HResult; stdcall;
    function StopProgressDialog: HResult; stdcall;
    function SetTitle(ATitle: PWideChar): HResult; stdcall;
    function SetAnimation(AInstance: THandle; AAnimationId: UINT): HResult;
      stdcall;
    function HasUserCancelled: BOOL; stdcall;
    function SetProgress(ACompleted, ATotal: DWORD): HResult; stdcall;
    function SetProgress64(ACompleted, ATotal: Int64): HResult; stdcall;
    function SetLine(ALineNum: DWORD; AText: PWideChar; ACompactPath: BOOL;
      AReserved: Pointer): HResult; stdcall;
    function SetCancelMsg(ACancelMsg: PWideChar; AReserved: Pointer): HResult;
      stdcall;
    function Timer(AAction: DWORD; AReserved: Pointer): HResult; stdcall;
  end;

  TFarProgress = class
  private
    FDialog: IFarProgressDialog;
    FComInit: Boolean;
    FPercent: Integer;
    FLine2: WideString;
  public
    destructor Destroy; override;
    // Показать (оболочка покажет окно, если операция затянется). False -
    // окна нет (COM недоступен) - работа идёт без него
    function Start(AParent: HWND; const ATitle, ALine1: WideString): Boolean;
    procedure SetPercent(APercent: Integer);
    // Вторая строка - обычно имя файла (длинный путь сокращается)
    procedure SetLine2(const AText: WideString);
    function Cancelled: Boolean;
    procedure Stop;
    function Active: Boolean;
  end;

// Из вывода 7z.exe -bsp1 ('  42% 3 - папка\файл', строки через #8 / #13):
// последний процент и имя файла после него. False - процента нет
function FarParse7zProgress(const ARaw: string; var APercent: Integer;
  var AFileName: string): Boolean;

implementation

const
  ClsidProgressDialog: TGUID = '{F8383852-FCD3-11D1-A6B9-006097DF5BD4}';
  ProgDlgNormal = $00000000;
  ProgDlgAutoTime = $00000002;
  ProgDlgNoMinimize = $00000008;
  ProgDlgTimerReset = $00000001;    // PDTIMER_RESET

destructor TFarProgress.Destroy;
begin
  Stop;
  inherited Destroy;
end;

function TFarProgress.Start(AParent: HWND; const ATitle,
  ALine1: WideString): Boolean;
var
  InitResult: HResult;
  Unknown: IUnknown;
begin
  Result := False;
  Stop;
  InitResult := CoInitialize(nil);
  // S_OK и S_FALSE (уже инициализирован) - парный CoUninitialize нужен
  FComInit := (InitResult = S_OK) or (InitResult = S_FALSE);
  if (CoCreateInstance(ClsidProgressDialog, nil, CLSCTX_INPROC_SERVER,
     IUnknown, Unknown) <> S_OK) or (Unknown = nil) or
     (Unknown.QueryInterface(IFarProgressDialog, FDialog) <> S_OK) then
  begin
    FDialog := nil;
    if FComInit then
      CoUninitialize;
    FComInit := False;
    Exit;
  end;
  FPercent := -1;
  FLine2 := '';
  FDialog.SetTitle(PWideChar(ATitle));
  FDialog.SetLine(1, PWideChar(ALine1), False, nil);
  FDialog.SetCancelMsg(PWideChar(WideString('Прерываю...')), nil);
  FDialog.SetProgress(0, 100);
  FDialog.StartProgressDialog(AParent, nil, ProgDlgNormal or ProgDlgAutoTime
    or ProgDlgNoMinimize, nil);
  FDialog.Timer(ProgDlgTimerReset, nil);
  Result := True;
end;

procedure TFarProgress.SetPercent(APercent: Integer);
begin
  if (FDialog = nil) or (APercent = FPercent) then
    Exit;
  if APercent < 0 then
    APercent := 0;
  if APercent > 100 then
    APercent := 100;
  FPercent := APercent;
  FDialog.SetProgress(APercent, 100);
end;

procedure TFarProgress.SetLine2(const AText: WideString);
begin
  if (FDialog = nil) or (AText = FLine2) then
    Exit;
  FLine2 := AText;
  FDialog.SetLine(2, PWideChar(AText), True, nil);
end;

function TFarProgress.Cancelled: Boolean;
begin
  Result := (FDialog <> nil) and FDialog.HasUserCancelled;
end;

procedure TFarProgress.Stop;
begin
  if FDialog <> nil then
  begin
    FDialog.StopProgressDialog;
    FDialog := nil;
  end;
  if FComInit then
  begin
    CoUninitialize;
    FComInit := False;
  end;
end;

function TFarProgress.Active: Boolean;
begin
  Result := FDialog <> nil;
end;

function FarParse7zProgress(const ARaw: string; var APercent: Integer;
  var AFileName: string): Boolean;
var
  CharIndex, StopIndex, DigitIndex, LineEnd: Integer;
  Tail: string;
begin
  Result := False;
  AFileName := '';
  CharIndex := Length(ARaw);
  StopIndex := CharIndex - 1024;
  if StopIndex < 1 then
    StopIndex := 1;
  // Последний '%' с цифрами перед ним
  while CharIndex > StopIndex do
  begin
    if (ARaw[CharIndex] = '%') and (CharIndex > 1) and
       (ARaw[CharIndex - 1] in ['0'..'9']) then
      Break;
    Dec(CharIndex);
  end;
  if (CharIndex <= StopIndex) or (ARaw[CharIndex] <> '%') then
    Exit;
  DigitIndex := CharIndex - 1;
  while (DigitIndex >= 1) and (ARaw[DigitIndex] in ['0'..'9']) do
    Dec(DigitIndex);
  APercent := StrToIntDef(Copy(ARaw, DigitIndex + 1,
    CharIndex - DigitIndex - 1), -1);
  if (APercent < 0) or (APercent > 100) then
    Exit;
  Result := True;
  // После процента: ' 3 - имя' (или '+ имя', '= имя') до #8 / #13 / #10
  LineEnd := CharIndex + 1;
  while (LineEnd <= Length(ARaw)) and not (ARaw[LineEnd] in [#8, #13, #10]) do
    Inc(LineEnd);
  Tail := Trim(Copy(ARaw, CharIndex + 1, LineEnd - CharIndex - 1));
  // Число файлов
  DigitIndex := 1;
  while (DigitIndex <= Length(Tail)) and (Tail[DigitIndex] in ['0'..'9']) do
    Inc(DigitIndex);
  Tail := Trim(Copy(Tail, DigitIndex, MaxInt));
  if (Length(Tail) >= 2) and (Tail[1] in ['-', '+', '=', 'U', 'T']) and
     (Tail[2] = ' ') then
    Tail := Trim(Copy(Tail, 3, MaxInt));
  AFileName := Tail;
end;

end.
