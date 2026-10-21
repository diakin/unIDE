unit DlgCompProgress;

// Окно хода сборки: что собирается, список этапов (ждёт, идёт, готово,
// ошибка, пропущен) с временем каждого, текущая строка (последняя строка
// Compilation log), полоса хода, число ошибок и предупреждений, кнопки
// "Стоп" и "Скрыть"/"Закрыть".
//
// Полоса считается по этапам: у каждого этапа вес (доля полосы). Внутри
// идущего этапа доля берётся
//   - точно, если её сообщает сам этап (перевод RqToFb - по строкам,
//     StageFraction с AExact = True);
//   - по времени прошлой сборки (оценка, AEstimateMs в StartStage), но не
//     меньше нижней границы, которую сообщает этап (fbc -v: "assembling:",
//     "linking:" - StageFraction с AExact = False);
//   - без оценки - по времени, с замедлением к концу этапа (первая сборка).
// Пока этап идёт, полоса не доходит до его конца: конец ставит EndStage.
//
// Окно описано в DlgCompProgress.dfm и правится в конструкторе форм.
// Этапы и их ход задаёт сборка - TForm1.CompileRapidQFb (Unit1); для
// других компиляторов - один этап (TForm1.CompProgressStart, Preferences -
// Show compiler progress). Таймер окна (tmrTick) двигает полосу между
// сообщениями; работает он, пока сборка отдаёт управление очереди
// сообщений (RunCompiler, ход перевода).
//
// Форма создаётся по месту, в .dpr её автосоздания нет.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ComCtrls, ExtCtrls,
  UiButton,     // TUiButton
  UiStdCtrls,   // TUiCheckBox
  UiEditCtrls;  // TUiListBox

type
  TCompStageState = (cssWait, cssRun, cssDone, cssFail, cssSkip);

  TCompStage = record
    Text: string;            // название этапа
    Note: string;            // пояснение серым после названия
    Weight: Integer;         // доля полосы
    State: TCompStageState;
    StartTick: Cardinal;
    Elapsed: Cardinal;       // мс, у законченного этапа
    EstimateMs: Cardinal;    // оценка по прошлой сборке, 0 - нет
    Fraction: Double;        // сообщённая доля этапа (0..1)
    Exact: Boolean;          // Fraction точная, по времени не считать
  end;

  TDlgCompProgress = class(TForm)
    lblProgram: TLabel;
    lstStages: TUiListBox;
    lblLine: TLabel;
    barProgress: TProgressBar;
    lblPercent: TLabel;
    lblCounts: TLabel;
    chkAutoClose: TUiCheckBox;
    btnStop: TUiButton;
    btnClose: TUiButton;
    tmrTick: TTimer;
    tmrClose: TTimer;
    procedure lstStagesDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure tmrTickTimer(Sender: TObject);
    procedure tmrCloseTimer(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FStages: array of TCompStage;
    FBuilding: Boolean;
    FAbort: Boolean;
    FStartTick: Cardinal;
    FLineText: string;       // полный текст строки (lblLine - обрезанный)
    FErrors: Integer;        // счётчики строки lblCounts
    FWarnings: Integer;
    FHints: Integer;
    procedure ShowCounts;
    // $0128 - WM_UPDATEUISTATE, в Messages.pas Delphi 7 этой константы нет
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
    function ValidStage(AStage: Integer): Boolean;
    function RunningStage: Integer;
    function StageShare(AStage: Integer): Double;
    procedure RedrawStage(AStage: Integer);
    procedure UpdateProgress;
    procedure FitLine;
  public
    constructor Create(AOwner: TComponent); override;
    // Новая сборка: этапы, счётчики и строка - с начала. AProgram - что
    // собирается (верхняя строка окна).
    procedure BeginBuild(const AProgram: string);
    // Этап в конец списка; результат - его номер
    function AddStage(const AText: string; AWeight: Integer): Integer;
    // Вес этапа (до его начала): доли полосы по времени прошлой сборки
    procedure SetStageWeight(AStage, AWeight: Integer);
    procedure StartStage(AStage: Integer; AEstimateMs: Cardinal;
                         const ANote: string);
    // Доля идущего этапа (0..1) и пояснение ('' - прежнее). AExact = False
    // - нижняя граница: оценка по времени может быть больше.
    procedure StageFraction(AStage: Integer; AFraction: Double;
                            AExact: Boolean; const ANote: string);
    procedure EndStage(AStage: Integer; AOk: Boolean; const ANote: string);
    procedure SkipStage(AStage: Integer; const ANote: string);
    // Время законченного этапа, мс (0 - не закончен)
    function StageMs(AStage: Integer): Cardinal;
    // Текущая строка: последнее сообщение сборки
    procedure ShowLine(const AText: string);
    procedure SetCounts(AErrors, AWarnings, AHints: Integer);
    // Конец сборки. Идущий этап - готов (AOk) или с ошибкой. AResult -
    // итог под полосой. Удачная сборка и флажок "Закрывать" - окно
    // прячется через секунду.
    procedure FinishBuild(AOk: Boolean; const AResult: string);
    property Building: Boolean read FBuilding;
    property AbortRequested: Boolean read FAbort;
  end;

// Время для окна: 850 мс, 2,4 с, 1 мин 05 с
function CompMsText(AMs: Cardinal): string;

implementation

{$R *.dfm}

const
  MarkWidth = 22;   // место под значок этапа слева

function CompMsText(AMs: Cardinal): string;
begin
  if AMs < 1000 then
    Result := IntToStr(Integer(AMs)) + ' мс'
  else if AMs < 60000 then
    Result := Format('%.1f с', [AMs / 1000])
  else
    Result := Format('%d мин %.2d с', [Integer(AMs div 60000),
                                       Integer((AMs mod 60000) div 1000)]);
end;

// Яркость цвета 0..255: на тёмном фоне значки светлее
function ColorLuma(AColor: TColor): Integer;
var
  RgbValue: Longint;
begin
  RgbValue := ColorToRGB(AColor);
  Result := (GetRValue(RgbValue) * 299 + GetGValue(RgbValue) * 587 +
             GetBValue(RgbValue) * 114) div 1000;
end;

// Середина между двумя цветами - для второстепенного текста
function ColorMid(AColor1, AColor2: TColor): TColor;
var
  Rgb1, Rgb2: Longint;
begin
  Rgb1 := ColorToRGB(AColor1);
  Rgb2 := ColorToRGB(AColor2);
  Result := RGB((GetRValue(Rgb1) + GetRValue(Rgb2)) div 2,
                (GetGValue(Rgb1) + GetGValue(Rgb2)) div 2,
                (GetBValue(Rgb1) + GetBValue(Rgb2)) div 2);
end;

constructor TDlgCompProgress.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // Строки и полоса меняются раз в 150 мс - без буфера окно моргает
  DoubleBuffered := True;
end;

// По нажатию Alt Windows меняет режим показа подчёркиваний, и кнопки окна
// пропадают с экрана - та же беда, что у главного окна (см.
// TForm1.WMUpdateUIState)
procedure TDlgCompProgress.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

function TDlgCompProgress.ValidStage(AStage: Integer): Boolean;
begin
  Result := (AStage >= 0) and (AStage <= High(FStages));
end;

function TDlgCompProgress.RunningStage: Integer;
var
  StageIdx: Integer;
begin
  Result := -1;
  for StageIdx := 0 to High(FStages) do
    if FStages[StageIdx].State = cssRun then
    begin
      Result := StageIdx;
      Exit;
    end;
end;

procedure TDlgCompProgress.BeginBuild(const AProgram: string);
begin
  tmrClose.Enabled := False;
  SetLength(FStages, 0);
  lstStages.Items.Clear;
  FBuilding := True;
  FAbort := False;
  FStartTick := GetTickCount;
  lblProgram.Caption := AProgram;
  ShowLine('');
  barProgress.Position := 0;
  lblPercent.Caption := '0 %';
  SetCounts(0, 0, 0);
  btnStop.Enabled := True;
  btnClose.Caption := 'Скрыть';
  tmrTick.Enabled := True;
end;

function TDlgCompProgress.AddStage(const AText: string; AWeight: Integer): Integer;
begin
  Result := Length(FStages);
  SetLength(FStages, Result + 1);
  with FStages[Result] do
  begin
    Text := AText;
    Note := '';
    if AWeight < 1 then
      AWeight := 1;
    Weight := AWeight;
    State := cssWait;
    StartTick := 0;
    Elapsed := 0;
    EstimateMs := 0;
    Fraction := 0;
    Exact := False;
  end;
  lstStages.Items.Add(AText);
end;

procedure TDlgCompProgress.SetStageWeight(AStage, AWeight: Integer);
begin
  if not ValidStage(AStage) then
    Exit;
  if AWeight < 1 then
    AWeight := 1;
  FStages[AStage].Weight := AWeight;
end;

procedure TDlgCompProgress.StartStage(AStage: Integer; AEstimateMs: Cardinal;
                                      const ANote: string);
begin
  if not ValidStage(AStage) then
    Exit;
  with FStages[AStage] do
  begin
    State := cssRun;
    StartTick := GetTickCount;
    EstimateMs := AEstimateMs;
    Fraction := 0;
    Exact := False;
    Note := ANote;
  end;
  RedrawStage(AStage);
  UpdateProgress;
end;

procedure TDlgCompProgress.StageFraction(AStage: Integer; AFraction: Double;
                                         AExact: Boolean; const ANote: string);
begin
  if not ValidStage(AStage) or (FStages[AStage].State <> cssRun) then
    Exit;
  if AFraction < 0 then
    AFraction := 0;
  if AFraction > 1 then
    AFraction := 1;
  with FStages[AStage] do
  begin
    Fraction := AFraction;
    Exact := AExact;
    if (ANote <> '') and (ANote <> Note) then
    begin
      Note := ANote;
      RedrawStage(AStage);
    end;
  end;
  UpdateProgress;
end;

procedure TDlgCompProgress.EndStage(AStage: Integer; AOk: Boolean;
                                    const ANote: string);
begin
  if not ValidStage(AStage) then
    Exit;
  with FStages[AStage] do
  begin
    if State = cssRun then
      Elapsed := GetTickCount - StartTick;
    if AOk then
      State := cssDone
    else
      State := cssFail;
    Fraction := 1;
    Exact := True;
    if ANote <> '' then
      Note := ANote;
  end;
  RedrawStage(AStage);
  UpdateProgress;
end;

procedure TDlgCompProgress.SkipStage(AStage: Integer; const ANote: string);
begin
  if not ValidStage(AStage) then
    Exit;
  FStages[AStage].State := cssSkip;
  FStages[AStage].Note := ANote;
  RedrawStage(AStage);
  UpdateProgress;
end;

function TDlgCompProgress.StageMs(AStage: Integer): Cardinal;
begin
  Result := 0;
  if ValidStage(AStage) and (FStages[AStage].State in [cssDone, cssFail]) then
    Result := FStages[AStage].Elapsed;
end;

// Доля этапа 0..1 для полосы
function TDlgCompProgress.StageShare(AStage: Integer): Double;
var
  ElapsedMs: Cardinal;
  ByTime: Double;
begin
  Result := 0;
  with FStages[AStage] do
    case State of
      cssDone, cssFail:
        Result := 1;
      cssRun:
        begin
          if Exact then
            Result := Fraction
          else
          begin
            ElapsedMs := GetTickCount - StartTick;
            if EstimateMs > 0 then
              ByTime := ElapsedMs / EstimateMs
            else
              // Оценки нет: половина за 4 с, дальше всё медленнее
              ByTime := ElapsedMs / (ElapsedMs + 4000.0);
            Result := ByTime;
            if Fraction > Result then
              Result := Fraction;
          end;
          // Конец этапа ставит EndStage
          if Result > 0.95 then
            Result := 0.95;
        end;
    end;
end;

procedure TDlgCompProgress.UpdateProgress;
var
  StageIdx, Running: Integer;
  TotalWeight, DoneWeight: Double;
  Percent: Integer;
  Info: string;
  ElapsedMs: Cardinal;
begin
  TotalWeight := 0;
  DoneWeight := 0;
  for StageIdx := 0 to High(FStages) do
    if FStages[StageIdx].State <> cssSkip then
    begin
      TotalWeight := TotalWeight + FStages[StageIdx].Weight;
      DoneWeight := DoneWeight + FStages[StageIdx].Weight * StageShare(StageIdx);
    end;
  if TotalWeight > 0 then
    Percent := Round(DoneWeight * 100 / TotalWeight)
  else
    Percent := 0;
  if Percent > 100 then
    Percent := 100;
  if barProgress.Position <> Percent then
    barProgress.Position := Percent;

  if not FBuilding then
    Exit;
  Info := IntToStr(Percent) + ' %';
  Running := RunningStage;
  if Running >= 0 then
    with FStages[Running] do
    begin
      ElapsedMs := GetTickCount - StartTick;
      Info := Info + '   ' + Text + ': ' + CompMsText(ElapsedMs);
      if EstimateMs > 0 then
        Info := Info + ' (в прошлый раз ' + CompMsText(EstimateMs) + ')'
      else if not Exact then
        Info := Info + ' (время этапа заранее неизвестно)';
      RedrawStage(Running);   // время в строке этапа
    end;
  lblPercent.Caption := Info;
end;

procedure TDlgCompProgress.RedrawStage(AStage: Integer);
var
  ItemBox: TRect;
begin
  if not ValidStage(AStage) or not lstStages.HandleAllocated or
     (AStage >= lstStages.Items.Count) then
    Exit;
  ItemBox := lstStages.ItemRect(AStage);
  InvalidateRect(lstStages.Handle, @ItemBox, False);
end;

procedure TDlgCompProgress.ShowLine(const AText: string);
begin
  FLineText := AText;
  FitLine;
end;

// Строка не длиннее метки: хвост заменяется на "..."
procedure TDlgCompProgress.FitLine;
var
  Shown: string;
  Limit: Integer;
begin
  Shown := FLineText;
  Canvas.Font := lblLine.Font;
  Limit := lblLine.Width;
  if Canvas.TextWidth(Shown) > Limit then
  begin
    while (Shown <> '') and (Canvas.TextWidth(Shown + '...') > Limit) do
      SetLength(Shown, Length(Shown) - 1);
    Shown := Shown + '...';
  end;
  if lblLine.Caption <> Shown then
    lblLine.Caption := Shown;
  lblLine.Hint := FLineText;
end;

procedure TDlgCompProgress.SetCounts(AErrors, AWarnings, AHints: Integer);
begin
  FErrors := AErrors;
  FWarnings := AWarnings;
  FHints := AHints;
  ShowCounts;
end;

procedure TDlgCompProgress.ShowCounts;
var
  CountsText: string;
begin
  CountsText := Format('Ошибок: %d    Предупреждений: %d', [FErrors, FWarnings]);
  if FHints > 0 then
    CountsText := CountsText + Format('    Подсказок: %d', [FHints]);
  if FStartTick <> 0 then
    CountsText := CountsText + '    Прошло: ' +
                  CompMsText(GetTickCount - FStartTick);
  if lblCounts.Caption <> CountsText then
    lblCounts.Caption := CountsText;
end;

procedure TDlgCompProgress.FinishBuild(AOk: Boolean; const AResult: string);
var
  Running: Integer;
  ElapsedMs: Cardinal;
begin
  Running := RunningStage;
  while Running >= 0 do
  begin
    EndStage(Running, AOk, '');
    Running := RunningStage;
  end;
  ElapsedMs := GetTickCount - FStartTick;
  ShowCounts;
  FBuilding := False;
  tmrTick.Enabled := False;
  if AOk then
    barProgress.Position := 100;
  lblPercent.Caption := AResult + ', ' + CompMsText(ElapsedMs);
  btnStop.Enabled := False;
  btnClose.Caption := 'Закрыть';
  if AOk and chkAutoClose.Checked and Visible then
  begin
    tmrClose.Interval := 1200;
    tmrClose.Enabled := True;
  end;
end;

procedure TDlgCompProgress.tmrTickTimer(Sender: TObject);
begin
  if not FBuilding then
  begin
    tmrTick.Enabled := False;
    Exit;
  end;
  UpdateProgress;
  ShowCounts;   // "Прошло"
end;

procedure TDlgCompProgress.tmrCloseTimer(Sender: TObject);
begin
  tmrClose.Enabled := False;
  if not FBuilding then
    Hide;
end;

procedure TDlgCompProgress.btnStopClick(Sender: TObject);
begin
  if not FBuilding then
    Exit;
  FAbort := True;
  btnStop.Enabled := False;
  ShowLine('Остановка...');
end;

// Во время сборки - только спрятать окно: сборка идёт дальше, итог - в
// Compilation log
procedure TDlgCompProgress.btnCloseClick(Sender: TObject);
begin
  tmrClose.Enabled := False;
  Hide;
end;

procedure TDlgCompProgress.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  tmrClose.Enabled := False;
  Action := caHide;
end;

// Строка этапа: значок, название, пояснение серым, время справа
procedure TDlgCompProgress.lstStagesDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  Cnv: TCanvas;
  BackColor, TextColor, DimColor, MarkColor: TColor;
  IsDark: Boolean;
  MidX, MidY, TextLeft, TimeLeft: Integer;
  TimeText, NoteText: string;
  TextBox: TRect;
  Stage: TCompStage;
begin
  Cnv := lstStages.Canvas;
  BackColor := lstStages.Color;
  TextColor := lstStages.Font.Color;
  DimColor := ColorMid(TextColor, BackColor);
  IsDark := ColorLuma(BackColor) < 128;
  Cnv.Brush.Style := bsSolid;
  Cnv.Brush.Color := BackColor;
  Cnv.FillRect(Rect);
  if not ValidStage(Index) then
    Exit;
  Stage := FStages[Index];

  // Значок
  MidX := Rect.Left + MarkWidth div 2;
  MidY := (Rect.Top + Rect.Bottom) div 2;
  Cnv.Pen.Width := 2;
  case Stage.State of
    cssWait:
      begin
        Cnv.Pen.Width := 1;
        Cnv.Pen.Color := DimColor;
        Cnv.Brush.Style := bsClear;
        Cnv.Ellipse(MidX - 3, MidY - 3, MidX + 4, MidY + 4);
      end;
    cssRun:
      begin
        if IsDark then
          MarkColor := $00FFC060
        else
          MarkColor := $00C06000;
        Cnv.Pen.Width := 1;
        Cnv.Pen.Color := MarkColor;
        Cnv.Brush.Color := MarkColor;
        Cnv.Polygon([Point(MidX - 3, MidY - 5), Point(MidX + 4, MidY),
                     Point(MidX - 3, MidY + 5)]);
      end;
    cssDone:
      begin
        if IsDark then
          MarkColor := $0070D070
        else
          MarkColor := $00008000;
        Cnv.Pen.Color := MarkColor;
        Cnv.MoveTo(MidX - 5, MidY);
        Cnv.LineTo(MidX - 2, MidY + 4);
        Cnv.LineTo(MidX + 5, MidY - 4);
      end;
    cssFail:
      begin
        if IsDark then
          MarkColor := $006060FF
        else
          MarkColor := $000000C0;
        Cnv.Pen.Color := MarkColor;
        Cnv.MoveTo(MidX - 4, MidY - 4);
        Cnv.LineTo(MidX + 5, MidY + 5);
        Cnv.MoveTo(MidX + 4, MidY - 4);
        Cnv.LineTo(MidX - 5, MidY + 5);
      end;
    cssSkip:
      begin
        Cnv.Pen.Color := DimColor;
        Cnv.MoveTo(MidX - 4, MidY);
        Cnv.LineTo(MidX + 5, MidY);
      end;
  end;
  Cnv.Pen.Width := 1;

  // Время справа
  case Stage.State of
    cssRun:
      TimeText := CompMsText(GetTickCount - Stage.StartTick);
    cssDone, cssFail:
      TimeText := CompMsText(Stage.Elapsed);
  else
    TimeText := '';
  end;
  Cnv.Brush.Style := bsClear;
  Cnv.Font := lstStages.Font;
  TimeLeft := Rect.Right - 6;
  if TimeText <> '' then
  begin
    TimeLeft := Rect.Right - 6 - Cnv.TextWidth(TimeText);
    Cnv.Font.Color := DimColor;
    Cnv.TextOut(TimeLeft, MidY - Cnv.TextHeight('0') div 2, TimeText);
  end;

  // Название и пояснение
  TextLeft := Rect.Left + MarkWidth;
  TextBox := Classes.Rect(TextLeft, Rect.Top, TimeLeft - 8, Rect.Bottom);
  Cnv.Font := lstStages.Font;
  if Stage.State in [cssWait, cssSkip] then
    Cnv.Font.Color := DimColor
  else
    Cnv.Font.Color := TextColor;
  if Stage.State = cssRun then
    Cnv.Font.Style := [fsBold];
  Cnv.TextRect(TextBox, TextLeft, MidY - Cnv.TextHeight('0') div 2, Stage.Text);
  if Stage.Note <> '' then
  begin
    TextLeft := TextLeft + Cnv.TextWidth(Stage.Text);
    Cnv.Font.Style := [];
    Cnv.Font.Color := DimColor;
    NoteText := '   ' + Stage.Note;
    TextBox.Left := TextLeft;
    if TextBox.Left < TextBox.Right then
      Cnv.TextRect(TextBox, TextLeft, MidY - Cnv.TextHeight('0') div 2, NoteText);
  end;
end;

end.
