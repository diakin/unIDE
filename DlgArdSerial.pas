unit DlgArdSerial;

// Serial Monitor: обмен с платой Arduino через COM-порт, как окно Serial
// Monitor Arduino IDE. В arduino-cli 0.18.1 команды monitor нет, поэтому
// порт открывается здесь же (CreateFile), чтение - по таймеру без ожидания
// (таймауты порта: вернуть то, что уже пришло).
//
// - Строка сверху и Send: отправить текст с выбранным окончанием строки
//   (No line ending, Newline, Carriage return, Both NL & CR); Enter - то же.
// - Принятое - в поле вывода. Байты считаются UTF-8 (как в Arduino IDE);
//   байт, который не входит в правильную последовательность UTF-8, берётся
//   как символ кодовой страницы Windows. Незаконченная последовательность в
//   конце порции ждёт следующей. CR отбрасывается, LF - новая строка.
// - Autoscroll, Show timestamp (время прихода в начале строки), скорость,
//   окончание строки - запоминаются в editor.ini ([Compiler.Arduino]).
// - Порт открывается с DTR и RTS (как в Arduino IDE: у многих плат это
//   сброс при открытии).
// - Порт пропал (устройство отключили) - порт закрывается; когда порт с
//   тем же именем снова появится, TForm1 вызывает PortArrived, и он
//   открывается снова. Закрытый кнопкой Close порт сам не открывается.
//
// Окно описано в DlgArdSerial.dfm. Создаёт и показывает его TForm1
// (mArdMonitorClick, Unit1); порт - выбранный в меню Arduino - Port.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, IniFiles,
  UiButton,      // TUiButton
  UiEditCtrls,   // TUiEdit, TUiMemo, TUiComboBox
  UiStdCtrls,    // TUiCheckBox
  ArduinoCli;

type
  TDlgArdSerial = class(TForm)
    pnlTop: TPanel;
    edSend: TUiEdit;
    btnSend: TUiButton;
    memOut: TUiMemo;
    pnlBottom: TPanel;
    chkAutoscroll: TUiCheckBox;
    chkTimestamp: TUiCheckBox;
    lblState: TLabel;
    cbLineEnd: TUiComboBox;
    cbBaud: TUiComboBox;
    btnClear: TUiButton;
    btnOpen: TUiButton;
    tmrRead: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnSendClick(Sender: TObject);
    procedure edSendKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure btnClearClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure cbBaudChange(Sender: TObject);
    procedure OptionChange(Sender: TObject);
    procedure tmrReadTimer(Sender: TObject);
  private
    FSettingsFile: string;
    FSection: string;
    FSettingsLoaded: Boolean;
    FLoadingSettings: Boolean;
    FPort: THandle;
    FPortName: string;
    FLostPort: Boolean;        // порт закрыт, потому что пропал
    FPending: string;          // незаконченная последовательность UTF-8
    FAtLineStart: Boolean;
    FAnsiTable: array[128..255] of WideChar;
    FAnsiTableReady: Boolean;
    // $0128 - WM_UPDATEUISTATE, в Messages.pas Delphi 7 этой константы нет
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
    procedure LoadSettings;
    procedure SaveSetting(const AKey, AValue: string);
    function  CurrentBaud: Integer;
    function  OpenHandle: Boolean;
    procedure ClosePortHandle;
    function  ApplyBaud: Boolean;
    procedure PortFailed(const AWhat: string);
    procedure UpdateState(const AText: string);
    function  DecodeBytes(const ABytes: string): string;
    function  FormatIncoming(const AText: string): string;
    procedure AppendText(const AText: string);
  public
    // Открыть порт APortName (прежний закрывается)
    procedure OpenPort(const APortName: string);
    procedure ClosePort;
    // Порт пропал или снова появился (TForm1 по событию подключения)
    procedure PortRemoved(const APortName: string);
    procedure PortArrived(const APortName: string);
    // Загрузка скетча (Upload) в плату на этом порту: порт закрывается и
    // откроется снова по PortArrived - после загрузки, когда порт есть
    procedure PauseForUpload;
    function IsOpen: Boolean;
    property PortName: string read FPortName;
    property SettingsFile: string read FSettingsFile write FSettingsFile;
  end;

implementation

{$R *.dfm}

const
  BaudRates: array[0..14] of Integer = (
    300, 1200, 2400, 4800, 9600, 19200, 38400, 57600, 74880, 115200,
    230400, 250000, 500000, 1000000, 2000000);
  LineEndNames: array[0..3] of string = (
    'No line ending', 'Newline', 'Carriage return', 'Both NL & CR');
  LineEndTexts: array[0..3] of string = ('', #10, #13, #13#10);
  DefaultBaud = 9600;
  // Поле вывода больше - первая четверть убирается
  MaxOutText = 400000;
  // Биты поля Flags структуры DCB
  DcbBinary = $00000001;
  DcbDtrEnable = $00000010;      // fDtrControl = DTR_CONTROL_ENABLE
  DcbRtsEnable = $00001000;      // fRtsControl = RTS_CONTROL_ENABLE

procedure TDlgArdSerial.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

procedure TDlgArdSerial.FormCreate(Sender: TObject);
var
  ItemIdx: Integer;
begin
  FPort := INVALID_HANDLE_VALUE;
  FAtLineStart := True;
  cbBaud.Items.Clear;
  for ItemIdx := Low(BaudRates) to High(BaudRates) do
    cbBaud.Items.Add(IntToStr(BaudRates[ItemIdx]) + ' baud');
  cbLineEnd.Items.Clear;
  for ItemIdx := Low(LineEndNames) to High(LineEndNames) do
    cbLineEnd.Items.Add(LineEndNames[ItemIdx]);
  cbBaud.ItemIndex := 4;        // 9600
  cbLineEnd.ItemIndex := 1;     // Newline
  chkAutoscroll.Checked := True;
  tmrRead.Enabled := False;
end;

procedure TDlgArdSerial.FormDestroy(Sender: TObject);
begin
  ClosePortHandle;
end;

procedure TDlgArdSerial.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  ClosePort;
  Action := caHide;
end;

// ---------------------------------------------------------------------------
//  Настройки
// ---------------------------------------------------------------------------

procedure TDlgArdSerial.LoadSettings;
var
  Ini: TIniFile;
  Baud, ItemIdx, LineEnd: Integer;
begin
  FSettingsLoaded := True;
  FSection := ArdLoadSettings(FSettingsFile).Section;
  if (FSettingsFile = '') or not FileExists(FSettingsFile) then
    Exit;
  FLoadingSettings := True;
  Ini := TIniFile.Create(FSettingsFile);
  try
    Baud := Ini.ReadInteger(FSection, 'MonitorBaud', DefaultBaud);
    for ItemIdx := Low(BaudRates) to High(BaudRates) do
      if BaudRates[ItemIdx] = Baud then
        cbBaud.ItemIndex := ItemIdx;
    LineEnd := Ini.ReadInteger(FSection, 'MonitorLineEnd', 1);
    if (LineEnd >= Low(LineEndNames)) and (LineEnd <= High(LineEndNames)) then
      cbLineEnd.ItemIndex := LineEnd;
    chkAutoscroll.Checked := Ini.ReadBool(FSection, 'MonitorAutoscroll', True);
    chkTimestamp.Checked := Ini.ReadBool(FSection, 'MonitorTimestamp', False);
  finally
    Ini.Free;
    FLoadingSettings := False;
  end;
end;

procedure TDlgArdSerial.SaveSetting(const AKey, AValue: string);
begin
  if FLoadingSettings or (FSettingsFile = '') then
    Exit;
  if FSection = '' then
    FSection := ArdLoadSettings(FSettingsFile).Section;
  ArdSaveSetting(FSettingsFile, FSection, AKey, AValue);
end;

procedure TDlgArdSerial.OptionChange(Sender: TObject);
const
  BoolText: array[Boolean] of string = ('0', '1');
begin
  if Sender = chkAutoscroll then
    SaveSetting('MonitorAutoscroll', BoolText[chkAutoscroll.Checked])
  else if Sender = chkTimestamp then
    SaveSetting('MonitorTimestamp', BoolText[chkTimestamp.Checked])
  else if (Sender = cbLineEnd) and (cbLineEnd.ItemIndex >= 0) then
    SaveSetting('MonitorLineEnd', IntToStr(cbLineEnd.ItemIndex));
end;

function TDlgArdSerial.CurrentBaud: Integer;
begin
  if (cbBaud.ItemIndex >= Low(BaudRates)) and
     (cbBaud.ItemIndex <= High(BaudRates)) then
    Result := BaudRates[cbBaud.ItemIndex]
  else
    Result := DefaultBaud;
end;

// ---------------------------------------------------------------------------
//  Порт
// ---------------------------------------------------------------------------

function TDlgArdSerial.IsOpen: Boolean;
begin
  Result := FPort <> INVALID_HANDLE_VALUE;
end;

procedure TDlgArdSerial.UpdateState(const AText: string);
begin
  lblState.Caption := AText;
  if IsOpen then
  begin
    btnOpen.Caption := 'Close';
    Caption := FPortName + ' - Serial Monitor';
  end
  else
  begin
    btnOpen.Caption := 'Open';
    if FPortName <> '' then
      Caption := FPortName + ' (закрыт) - Serial Monitor'
    else
      Caption := 'Serial Monitor';
  end;
  btnOpen.Enabled := FPortName <> '';
  btnSend.Enabled := IsOpen;
end;

function TDlgArdSerial.ApplyBaud: Boolean;
var
  Dcb: TDCB;
begin
  Result := False;
  if not IsOpen then
    Exit;
  FillChar(Dcb, SizeOf(Dcb), 0);
  Dcb.DCBlength := SizeOf(Dcb);
  if not GetCommState(FPort, Dcb) then
    Exit;
  Dcb.BaudRate := CurrentBaud;
  Dcb.ByteSize := 8;
  Dcb.Parity := NOPARITY;
  Dcb.StopBits := ONESTOPBIT;
  Dcb.Flags := DcbBinary or DcbDtrEnable or DcbRtsEnable;
  Result := SetCommState(FPort, Dcb);
end;

function TDlgArdSerial.OpenHandle: Boolean;
var
  Timeouts: TCommTimeouts;
  ErrorText: string;
begin
  Result := False;
  ClosePortHandle;
  if FPortName = '' then
    Exit;
  FPort := CreateFile(PChar('\\.\' + FPortName), GENERIC_READ or GENERIC_WRITE,
                      0, nil, OPEN_EXISTING, 0, 0);
  if FPort = INVALID_HANDLE_VALUE then
  begin
    ErrorText := SysErrorMessage(GetLastError);
    UpdateState('Не удалось открыть ' + FPortName + ': ' + ErrorText);
    Exit;
  end;
  SetupComm(FPort, 65536, 4096);
  if not ApplyBaud then
  begin
    ErrorText := SysErrorMessage(GetLastError);
    ClosePortHandle;
    UpdateState('Не удалось задать скорость ' + IntToStr(CurrentBaud) +
                ' порту ' + FPortName + ': ' + ErrorText);
    Exit;
  end;
  FillChar(Timeouts, SizeOf(Timeouts), 0);
  Timeouts.ReadIntervalTimeout := MAXDWORD;   // вернуть то, что уже пришло
  Timeouts.WriteTotalTimeoutConstant := 1000;
  SetCommTimeouts(FPort, Timeouts);
  PurgeComm(FPort, PURGE_RXCLEAR or PURGE_TXCLEAR);
  FPending := '';
  FLostPort := False;
  tmrRead.Enabled := True;
  Result := True;
  UpdateState(FPortName + ' открыт, ' + IntToStr(CurrentBaud) + ' бод');
end;

procedure TDlgArdSerial.ClosePortHandle;
begin
  tmrRead.Enabled := False;
  if FPort <> INVALID_HANDLE_VALUE then
  begin
    Windows.CloseHandle(FPort);
    FPort := INVALID_HANDLE_VALUE;
  end;
end;

procedure TDlgArdSerial.OpenPort(const APortName: string);
begin
  if not FSettingsLoaded then
    LoadSettings;
  FPortName := Trim(APortName);
  OpenHandle;
end;

procedure TDlgArdSerial.ClosePort;
begin
  FLostPort := False;
  if IsOpen then
  begin
    ClosePortHandle;
    UpdateState(FPortName + ' закрыт');
  end;
end;

// Чтение или запись не удались: порт закрывается
procedure TDlgArdSerial.PortFailed(const AWhat: string);
var
  ErrorText: string;
begin
  ErrorText := SysErrorMessage(GetLastError);
  ClosePortHandle;
  FLostPort := True;
  UpdateState(AWhat + ' ' + FPortName + ' не удалось: ' + ErrorText +
              '. Порт закрыт.');
end;

procedure TDlgArdSerial.PortRemoved(const APortName: string);
begin
  if (FPortName = '') or (CompareText(APortName, FPortName) <> 0) then
    Exit;
  if IsOpen then
  begin
    ClosePortHandle;
    FLostPort := True;
    UpdateState('Порт ' + FPortName + ' пропал из системы. Порт закрыт; ' +
                'откроется снова, когда появится.');
  end;
end;

procedure TDlgArdSerial.PauseForUpload;
begin
  if not IsOpen then
    Exit;
  ClosePortHandle;
  FLostPort := True;
  UpdateState(FPortName + ' закрыт на время загрузки скетча; откроется ' +
              'снова после неё');
end;

procedure TDlgArdSerial.PortArrived(const APortName: string);
begin
  if FLostPort and (CompareText(APortName, FPortName) = 0) and
     not IsOpen then
    OpenHandle;
end;

procedure TDlgArdSerial.btnOpenClick(Sender: TObject);
begin
  if IsOpen then
    ClosePort
  else
    OpenHandle;
end;

procedure TDlgArdSerial.cbBaudChange(Sender: TObject);
begin
  SaveSetting('MonitorBaud', IntToStr(CurrentBaud));
  if IsOpen then
  begin
    if ApplyBaud then
      UpdateState(FPortName + ' открыт, ' + IntToStr(CurrentBaud) + ' бод')
    else
      UpdateState('Не удалось задать скорость ' + IntToStr(CurrentBaud) +
                  ': ' + SysErrorMessage(GetLastError));
  end;
end;

// ---------------------------------------------------------------------------
//  Отправка
// ---------------------------------------------------------------------------

procedure TDlgArdSerial.btnSendClick(Sender: TObject);
var
  Data: string;
  Written: DWORD;
  LineEnd: string;
begin
  if not IsOpen then
    Exit;
  LineEnd := '';
  if (cbLineEnd.ItemIndex >= Low(LineEndTexts)) and
     (cbLineEnd.ItemIndex <= High(LineEndTexts)) then
    LineEnd := LineEndTexts[cbLineEnd.ItemIndex];
  Data := Utf8Encode(WideString(edSend.Text)) + LineEnd;
  if Data = '' then
    Exit;
  Written := 0;
  if not WriteFile(FPort, Data[1], Length(Data), Written, nil) then
  begin
    PortFailed('Запись в');
    Exit;
  end;
  edSend.Text := '';
end;

procedure TDlgArdSerial.edSendKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    btnSendClick(nil);
  end;
end;

// ---------------------------------------------------------------------------
//  Приём
// ---------------------------------------------------------------------------

procedure TDlgArdSerial.tmrReadTimer(Sender: TObject);
var
  Errors, ReadCount: DWORD;
  Stat: TComStat;
  Buffer: array[0..4095] of Char;
  Chunk, Part: string;
  ReadRound: Integer;
begin
  if not IsOpen then
    Exit;
  Chunk := '';
  for ReadRound := 1 to 16 do
  begin
    Errors := 0;
    if not ClearCommError(FPort, Errors, @Stat) then
    begin
      PortFailed('Чтение из');
      Break;
    end;
    if Stat.cbInQue = 0 then
      Break;
    ReadCount := 0;
    if not ReadFile(FPort, Buffer, SizeOf(Buffer), ReadCount, nil) then
    begin
      PortFailed('Чтение из');
      Break;
    end;
    if ReadCount = 0 then
      Break;
    SetString(Part, Buffer, ReadCount);
    Chunk := Chunk + Part;
  end;
  if Chunk <> '' then
    AppendText(FormatIncoming(DecodeBytes(Chunk)));
end;

// Байты UTF-8 - в текст кодовой страницы Windows
function TDlgArdSerial.DecodeBytes(const ABytes: string): string;
var
  Data: string;
  Wide: WideString;
  WideLen, ByteIdx, TailIdx, SeqLen, ContIdx, CodeValue, LeadByte: Integer;
  OneByte: Char;
  SeqValid: Boolean;

  function SeqLenOf(AByte: Integer): Integer;
  begin
    if (AByte >= $C2) and (AByte <= $DF) then
      Result := 2
    else if (AByte >= $E0) and (AByte <= $EF) then
      Result := 3
    else if (AByte >= $F0) and (AByte <= $F4) then
      Result := 4
    else
      Result := 1;
  end;

begin
  if not FAnsiTableReady then
  begin
    for CodeValue := 128 to 255 do
    begin
      OneByte := Chr(CodeValue);
      if MultiByteToWideChar(CP_ACP, 0, @OneByte, 1,
                             @FAnsiTable[CodeValue], 1) <> 1 then
        FAnsiTable[CodeValue] := '?';
    end;
    FAnsiTableReady := True;
  end;

  Data := FPending + ABytes;
  FPending := '';
  // Незаконченная последовательность в конце - до следующей порции
  for TailIdx := Length(Data) downto Length(Data) - 2 do
  begin
    if TailIdx < 1 then
      Break;
    LeadByte := Ord(Data[TailIdx]);
    if LeadByte and $C0 = $80 then
      Continue;                       // продолжение - смотрим левее
    SeqLen := SeqLenOf(LeadByte);
    if (SeqLen > 1) and (Length(Data) - TailIdx + 1 < SeqLen) then
    begin
      FPending := Copy(Data, TailIdx, MaxInt);
      SetLength(Data, TailIdx - 1);
    end;
    Break;
  end;

  SetLength(Wide, Length(Data));
  WideLen := 0;
  ByteIdx := 1;
  while ByteIdx <= Length(Data) do
  begin
    LeadByte := Ord(Data[ByteIdx]);
    Inc(WideLen);
    if LeadByte < $80 then
    begin
      Wide[WideLen] := WideChar(LeadByte);
      Inc(ByteIdx);
      Continue;
    end;
    SeqLen := SeqLenOf(LeadByte);
    SeqValid := (SeqLen > 1) and (ByteIdx + SeqLen - 1 <= Length(Data));
    if SeqValid then
      for ContIdx := 1 to SeqLen - 1 do
        if Ord(Data[ByteIdx + ContIdx]) and $C0 <> $80 then
          SeqValid := False;
    if not SeqValid then
    begin
      Wide[WideLen] := FAnsiTable[LeadByte];
      Inc(ByteIdx);
      Continue;
    end;
    case SeqLen of
      2:
        CodeValue := ((LeadByte and $1F) shl 6) or
                     (Ord(Data[ByteIdx + 1]) and $3F);
      3:
        CodeValue := ((LeadByte and $0F) shl 12) or
                     ((Ord(Data[ByteIdx + 1]) and $3F) shl 6) or
                     (Ord(Data[ByteIdx + 2]) and $3F);
    else
      CodeValue := Ord('?');          // вне BMP - в ANSI всё равно нет
    end;
    Wide[WideLen] := WideChar(CodeValue);
    Inc(ByteIdx, SeqLen);
  end;
  SetLength(Wide, WideLen);
  Result := string(Wide);
end;

// CR отбрасывается, LF - CRLF поля вывода; время в начале строки
function TDlgArdSerial.FormatIncoming(const AText: string): string;
var
  CharIdx: Integer;
  OneChar: Char;
begin
  Result := '';
  for CharIdx := 1 to Length(AText) do
  begin
    OneChar := AText[CharIdx];
    if OneChar = #13 then
      Continue;
    if FAtLineStart and chkTimestamp.Checked then
      Result := Result + FormatDateTime('hh:nn:ss.zzz', Now) + ' -> ';
    FAtLineStart := False;
    if OneChar = #10 then
    begin
      Result := Result + #13#10;
      FAtLineStart := True;
    end
    else if OneChar = #0 then
      Result := Result + ' '
    else
      Result := Result + OneChar;
  end;
end;

procedure TDlgArdSerial.AppendText(const AText: string);
var
  TextLen, CutPos, CutLine, FirstLine, SelFrom, SelTo: Integer;
  KeepView: Boolean;
begin
  if AText = '' then
    Exit;
  KeepView := not chkAutoscroll.Checked;
  FirstLine := 0;
  SelFrom := 0;
  SelTo := 0;
  if KeepView then
  begin
    FirstLine := SendMessage(memOut.Handle, EM_GETFIRSTVISIBLELINE, 0, 0);
    SendMessage(memOut.Handle, EM_GETSEL, WPARAM(@SelFrom), LPARAM(@SelTo));
    SendMessage(memOut.Handle, WM_SETREDRAW, 0, 0);
  end;
  try
    TextLen := GetWindowTextLength(memOut.Handle);
    if TextLen + Length(AText) > MaxOutText then
    begin
      // Первая четверть - до начала строки
      CutLine := SendMessage(memOut.Handle, EM_LINEFROMCHAR, TextLen div 4, 0);
      CutPos := SendMessage(memOut.Handle, EM_LINEINDEX, CutLine + 1, 0);
      if CutPos > 0 then
      begin
        SendMessage(memOut.Handle, EM_SETSEL, 0, CutPos);
        SendMessage(memOut.Handle, EM_REPLACESEL, 0, LPARAM(PChar('')));
        FirstLine := FirstLine - (CutLine + 1);
        if FirstLine < 0 then
          FirstLine := 0;
        SelFrom := 0;
        SelTo := 0;
      end;
      TextLen := GetWindowTextLength(memOut.Handle);
    end;
    SendMessage(memOut.Handle, EM_SETSEL, TextLen, TextLen);
    SendMessage(memOut.Handle, EM_REPLACESEL, 0, LPARAM(PChar(AText)));
    if KeepView then
    begin
      SendMessage(memOut.Handle, EM_SETSEL, SelFrom, SelTo);
      SendMessage(memOut.Handle, EM_LINESCROLL, 0,
        FirstLine - SendMessage(memOut.Handle, EM_GETFIRSTVISIBLELINE, 0, 0));
    end
    else
      SendMessage(memOut.Handle, EM_SCROLLCARET, 0, 0);
  finally
    if KeepView then
    begin
      SendMessage(memOut.Handle, WM_SETREDRAW, 1, 0);
      memOut.Invalidate;
    end;
  end;
end;

procedure TDlgArdSerial.btnClearClick(Sender: TObject);
begin
  memOut.Clear;
  FAtLineStart := True;
end;

end.
