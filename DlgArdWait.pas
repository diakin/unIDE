unit DlgArdWait;

// Ход загрузки arduino-cli (core install, lib install, update-index) -
// отдельное окно поверх остальных. Перенос WaitForm из RQdebugger
// (GetConsoleOutPut): полоса с процентом, кнопка Stop, вывод команды.
//
// Отличия от RQdebugger:
// - полоса - процент загрузки текущего пакета из строки прогресса
//   arduino-cli ("... 11.90 MiB / 15.75 MiB   75.56%"), а не счётчик
//   полусекунд ожидания; размер не известен ("/ ?", update-index) - полоса
//   пустая, вместо процента "?";
// - в окне весь вывод команды, строка прогресса обновляется на месте;
// - Stop и закрытие окна, пока команда идёт, прерывают arduino-cli.
//
// Окно занимает команда, в выводе которой пришла строка прогресса: тогда
// в окно переносится уже накопленный вывод команды и окно показывается.
// Команды без загрузки (списки, поиск) окно не трогают - и итог прошлой
// загрузки в нём остаётся (Board Manager после установки сразу читает
// списки заново). По окончании окно остаётся на экране с итогом в
// заголовке (Finished / Stopped / Error) - как в RQdebugger; закрывается
// крестиком или Esc. Следующая команда с загрузкой берёт то же окно.
//
// Порядок вызовов у того, кто запускает arduino-cli (ArdRunCli):
//   ArdWaitBegin(команда) - перед запуском;
//   ArdWaitLine(строка) - из AOnLine, ArdWaitProgress(текст) - из
//   AOnProgress, ArdWaitStopped - из AOnIdle (True - прервать);
//   ArdWaitEnd(код завершения) - после.
// Пока ArdWaitBegin не вызван (или после ArdWaitEnd) - ArdWaitLine и
// ArdWaitProgress ничего не делают, ArdWaitStopped - False.
//
// Окно описано в DlgArdWait.dfm. Создаётся при первом ArdWaitBegin, в .dpr
// его автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls,
  UiButton,      // TUiButton
  UiEditCtrls,   // TUiMemo
  UiTheme;       // UiThemeColor

type
  TDlgArdWait = class(TForm)
    pbGauge: TPaintBox;
    btnStop: TUiButton;
    memOut: TUiMemo;
    procedure pbGaugePaint(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
                          Shift: TShiftState);
  private
    FRunning: Boolean;        // команда идёт
    FOwnsWindow: Boolean;     // окно занято идущей командой (была загрузка)
    FPendingLines: TStringList; // вывод команды до первой строки прогресса
    FStopped: Boolean;        // нажата Stop (или окно закрыто во время работы)
    FFailed: Boolean;         // команда закончилась ошибкой или прервана
    FPercent: Integer;        // процент полосы, -1 - размер не известен
    FProgressIdx: Integer;    // строка прогресса в memOut, -1 - нет
    // $0128 - WM_UPDATEUISTATE, в Messages.pas Delphi 7 этой константы нет
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

procedure ArdWaitBegin(const ACommand: string);
procedure ArdWaitLine(const ALine: string);
procedure ArdWaitProgress(const AText: string);
procedure ArdWaitEnd(AExitCode: Integer);
function  ArdWaitStopped: Boolean;

implementation

uses
  ArduinoCli;    // ArdLogLine, ArdLogProgress, ArdRunCancelled

{$R *.dfm}

const
  GaugeRunColor = $000080FF;    // оранжевый: идёт загрузка
  GaugeOkColor = $0000B000;     // зелёный: закончено
  GaugeFailColor = $004040E0;   // красный: ошибка или прервано

var
  GWaitDlg: TDlgArdWait = nil;

// Процент из строки прогресса: число перед последним '%'. Размер не
// известен ("/ ?") - -1: у update-index процент тогда бессмысленный
// (76021.76%)
function ProgressPercent(const AText: string): Integer;
var
  PctPos, NumStart, ErrPos: Integer;
  Value: Double;
begin
  Result := -1;
  if Pos('/ ?', AText) > 0 then
    Exit;
  PctPos := LastDelimiter('%', AText);
  if PctPos <= 1 then
    Exit;
  NumStart := PctPos;
  while (NumStart > 1) and (AText[NumStart - 1] in ['0'..'9', '.']) do
    Dec(NumStart);
  if NumStart = PctPos then
    Exit;
  Val(Copy(AText, NumStart, PctPos - NumStart), Value, ErrPos);
  if ErrPos <> 0 then
    Exit;
  Result := Trunc(Value);
  if Result < 0 then
    Result := 0;
  if Result > 100 then
    Result := 100;
end;

{ TDlgArdWait }

// Полоса меняется несколько раз в секунду: без буфера она моргает
constructor TDlgArdWait.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  DoubleBuffered := True;
  FProgressIdx := -1;
  FPendingLines := TStringList.Create;
end;

destructor TDlgArdWait.Destroy;
begin
  FPendingLines.Free;
  inherited Destroy;
end;

// По нажатию Alt Windows меняет режим показа подчёркиваний, и кнопки окна
// пропадают с экрана - см. TDlgProgress.WMUpdateUIState
procedure TDlgArdWait.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

// Полоса как QGauge в RQdebugger: заливка по проценту, процент по центру
procedure TDlgArdWait.pbGaugePaint(Sender: TObject);
var
  GaugeCanvas: TCanvas;
  GaugeRect, BarRect: TRect;
  PercentText: string;
  TextSize: TSize;
begin
  GaugeCanvas := pbGauge.Canvas;
  GaugeRect := pbGauge.ClientRect;
  GaugeCanvas.Brush.Style := bsSolid;
  GaugeCanvas.Brush.Color := UiThemeColor('Edit.BG');
  GaugeCanvas.FillRect(GaugeRect);

  if FPercent > 0 then
  begin
    if FRunning then
      GaugeCanvas.Brush.Color := GaugeRunColor
    else if FFailed then
      GaugeCanvas.Brush.Color := GaugeFailColor
    else
      GaugeCanvas.Brush.Color := GaugeOkColor;
    BarRect := GaugeRect;
    BarRect.Right := GaugeRect.Left +
                     MulDiv(GaugeRect.Right - GaugeRect.Left, FPercent, 100);
    GaugeCanvas.FillRect(BarRect);
  end;

  if FPercent < 0 then
    PercentText := '?'
  else
    PercentText := IntToStr(FPercent) + '%';
  GaugeCanvas.Font.Assign(pbGauge.Font);
  GaugeCanvas.Font.Color := UiThemeColor('Edit.Text');
  GaugeCanvas.Brush.Style := bsClear;
  TextSize := GaugeCanvas.TextExtent(PercentText);
  GaugeCanvas.TextOut((GaugeRect.Left + GaugeRect.Right - TextSize.cx) div 2,
                      (GaugeRect.Top + GaugeRect.Bottom - TextSize.cy) div 2,
                      PercentText);
end;

procedure TDlgArdWait.btnStopClick(Sender: TObject);
begin
  if not (FRunning and FOwnsWindow) then
    Exit;
  FStopped := True;
  btnStop.Enabled := False;
  Caption := 'Stopping...';
end;

// Закрытие во время работы - то же, что Stop: иначе окно пропало бы, а
// загрузка шла бы дальше без возможности её прервать
procedure TDlgArdWait.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FRunning and FOwnsWindow then
    btnStopClick(nil);
  CanClose := True;
end;

procedure TDlgArdWait.FormKeyDown(Sender: TObject; var Key: Word;
                                  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    Key := 0;
    Close;
  end;
end;

// ---------------------------------------------------------------------------

procedure ArdWaitBegin(const ACommand: string);
begin
  if GWaitDlg = nil then
    GWaitDlg := TDlgArdWait.Create(Application);
  // Само окно не трогаем: оно может показывать итог прошлой загрузки
  GWaitDlg.FRunning := True;
  GWaitDlg.FOwnsWindow := False;
  GWaitDlg.FStopped := False;
  GWaitDlg.FPendingLines.Clear;
  GWaitDlg.FPendingLines.Add('> arduino-cli ' + ACommand);
end;

procedure ArdWaitLine(const ALine: string);
begin
  if (GWaitDlg = nil) or not GWaitDlg.FRunning then
    Exit;
  if GWaitDlg.FOwnsWindow then
    ArdLogLine(GWaitDlg.memOut.Lines, GWaitDlg.FProgressIdx, ALine)
  else
    GWaitDlg.FPendingLines.Add(ALine);
end;

procedure ArdWaitProgress(const AText: string);
begin
  if (GWaitDlg = nil) or not GWaitDlg.FRunning then
    Exit;
  with GWaitDlg do
  begin
    // Первая строка прогресса команды - окно её: накопленный вывод, полоса
    // с нуля, Stop доступна
    if not FOwnsWindow then
    begin
      FOwnsWindow := True;
      FFailed := False;
      FProgressIdx := -1;
      memOut.Lines.Assign(FPendingLines);
      FPendingLines.Clear;
      btnStop.Enabled := True;
      Caption := 'Waiting...';
      if not Visible then
        Show;
    end;
    ArdLogProgress(memOut.Lines, FProgressIdx, AText);
    FPercent := ProgressPercent(AText);
    // Окно закрыто во время работы (это Stop) - заново не показывается
    if Visible then
      pbGauge.Repaint;
  end;
end;

procedure ArdWaitEnd(AExitCode: Integer);
begin
  if (GWaitDlg = nil) or not GWaitDlg.FRunning then
    Exit;
  with GWaitDlg do
  begin
    FRunning := False;
    FPendingLines.Clear;
    if not FOwnsWindow then
      Exit;      // загрузки не было - окно не её
    FOwnsWindow := False;
    btnStop.Enabled := False;
    if AExitCode = 0 then
    begin
      FFailed := False;
      FPercent := 100;
      Caption := 'Finished';
    end
    else if (AExitCode = ArdRunCancelled) or FStopped then
    begin
      FFailed := True;
      Caption := 'Stopped';
      memOut.Lines.Add('Прервано');
    end
    else
    begin
      FFailed := True;
      Caption := 'Error (code ' + IntToStr(AExitCode) + ')';
      memOut.Lines.Add('Код завершения ' + IntToStr(AExitCode));
    end;
    if Visible then
      pbGauge.Repaint;
  end;
end;

function ArdWaitStopped: Boolean;
begin
  Result := (GWaitDlg <> nil) and GWaitDlg.FRunning and
            GWaitDlg.FOwnsWindow and GWaitDlg.FStopped;
end;

end.
