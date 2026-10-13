unit SplashLoad;

// ---------------------------------------------------------------------------
//  Окно загрузки unIDE и журнал этапов запуска (startup.log рядом с exe).
//
//  Пока идёт запуск, главное окно невидимо (прозрачное, см. TForm1), а здесь
//  - небольшое окно с полосой хода и названием этапа. Каждый этап с его
//  длительностью - в журнал; в конце - итог. Полоса считается от числа
//  этапов прошлого запуска (из того же журнала).
//
//  Цикл сообщений в это время занят запуском, поэтому окно рисуется явно
//  (Update) при каждой смене этапа - без Application.ProcessMessages, чтобы
//  до конца загрузки не выполнялось ничего постороннего.
//
//  StartupSplashShow - в .dpr до создания форм; StartupStage - в начале
//  каждого этапа; StartupFinish - когда главное окно показано.
// ---------------------------------------------------------------------------

interface

uses
  Windows, SysUtils, Classes, Graphics, Controls, Forms, StdCtrls, ExtCtrls;

procedure StartupSplashShow;
procedure StartupStage(const AName: string);
// Дописать к названию текущего этапа (что выяснилось по ходу: откуда
// взята карта и т.п.)
procedure StartupStageNote(const ANote: string);
procedure StartupFinish;
// Идёт запуск (окно загрузки показано)
function  StartupActive: Boolean;

implementation

const
  LogName = 'startup.log';
  LogMaxLines = 600;     // журнал - последние запуски, не больше стольких строк

type
  TSplashForm = class(TForm)
  public
    lblTitle: TLabel;
    lblStage: TLabel;
    pbBar: TPaintBox;
    Fraction: Double;
    procedure BarPaint(Sender: TObject);
  end;

var
  Splash: TSplashForm = nil;
  StartLog: TStringList = nil;
  StartTick: Cardinal = 0;
  StageTick: Cardinal = 0;
  StageName: string = '';
  StageNo: Integer = 0;
  Expected: Integer = 0;   // этапов в прошлый раз
  Active: Boolean = False;

function LogPath: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + LogName;
end;

// Число этапов прошлого запуска: последняя строка "--- итого ..., этапов N"
function PreviousStages: Integer;
var
  OldLog: TStringList;
  LineIdx, MarkPos: Integer;
begin
  Result := 0;
  if not FileExists(LogPath) then
    Exit;
  OldLog := TStringList.Create;
  try
    try
      OldLog.LoadFromFile(LogPath);
    except
      Exit;
    end;
    for LineIdx := OldLog.Count - 1 downto 0 do
    begin
      MarkPos := Pos('этапов ', OldLog[LineIdx]);
      if (Copy(OldLog[LineIdx], 1, 4) = '--- ') and (MarkPos > 0) then
      begin
        Result := StrToIntDef(Trim(Copy(OldLog[LineIdx], MarkPos + 7, MaxInt)), 0);
        Exit;
      end;
    end;
  finally
    OldLog.Free;
  end;
end;

{ TSplashForm }

procedure TSplashForm.BarPaint(Sender: TObject);
var
  BarRect: TRect;
begin
  with pbBar.Canvas do
  begin
    Brush.Color := $00505050;
    FillRect(Rect(0, 0, pbBar.Width, pbBar.Height));
    BarRect := Rect(0, 0, Round(pbBar.Width * Fraction), pbBar.Height);
    Brush.Color := $00A08000;     // бирюзовый, как рамки IDE
    FillRect(BarRect);
  end;
end;

procedure StartupSplashShow;
begin
  if Active then
    Exit;
  Active := True;
  StartLog := TStringList.Create;
  StartTick := GetTickCount;
  StageTick := StartTick;
  StageName := '';
  StageNo := 0;
  Expected := PreviousStages;
  StartLog.Add('=== ' + FormatDateTime('dd.mm.yyyy hh:nn:ss', Now) + '  запуск ' +
               ExtractFileName(ParamStr(0)));
  try
    Splash := TSplashForm.CreateNew(nil);
    Splash.BorderStyle := bsNone;
    Splash.Position := poScreenCenter;
    Splash.Width := 440;
    Splash.Height := 86;
    Splash.Color := $00383838;
    Splash.Font.Name := 'Tahoma';
    Splash.Font.Height := -12;
    Splash.Font.Color := $00E0E0E0;
    Splash.lblTitle := TLabel.Create(Splash);
    Splash.lblTitle.Parent := Splash;
    Splash.lblTitle.SetBounds(16, 12, 408, 16);
    Splash.lblTitle.Font.Style := [fsBold];
    Splash.lblTitle.Caption := 'unIDE - загрузка';
    Splash.lblStage := TLabel.Create(Splash);
    Splash.lblStage.Parent := Splash;
    Splash.lblStage.AutoSize := False;
    Splash.lblStage.SetBounds(16, 34, 408, 16);
    Splash.lblStage.Caption := '';
    Splash.pbBar := TPaintBox.Create(Splash);
    Splash.pbBar.Parent := Splash;
    Splash.pbBar.SetBounds(16, 58, 408, 12);
    Splash.pbBar.OnPaint := Splash.BarPaint;
    Splash.Show;
    Splash.Update;
  except
    // окна нет - журнал этапов всё равно пишется
    FreeAndNil(Splash);
  end;
end;

// Прошлый этап - в журнал с его длительностью
procedure CloseStage;
var
  NowTick: Cardinal;
begin
  NowTick := GetTickCount;
  if StageName <> '' then
    StartLog.Add(Format('%6d мс  %s', [NowTick - StageTick, StageName]));
  StageTick := NowTick;
end;

procedure StartupStage(const AName: string);
var
  Total: Integer;
begin
  if not Active then
    Exit;
  CloseStage;
  StageName := AName;
  Inc(StageNo);
  if Splash = nil then
    Exit;
  Total := Expected;
  if Total <= StageNo then
    Total := StageNo + 1;
  Splash.Fraction := StageNo / Total;
  Splash.lblStage.Caption := AName;
  // Цикл сообщений занят запуском - рисуем сразу
  Splash.Update;
end;

procedure StartupStageNote(const ANote: string);
begin
  if Active and (StageName <> '') then
    StageName := StageName + ANote;
end;

procedure StartupFinish;
var
  FileLog: TStringList;
begin
  if not Active then
    Exit;
  CloseStage;
  StartLog.Add(Format('--- итого %d мс, этапов %d',
                      [GetTickCount - StartTick, StageNo]));
  FileLog := TStringList.Create;
  try
    try
      if FileExists(LogPath) then
        FileLog.LoadFromFile(LogPath);
      FileLog.AddStrings(StartLog);
      while FileLog.Count > LogMaxLines do
        FileLog.Delete(0);
      FileLog.SaveToFile(LogPath);
    except
      // журнал не записался - запуск от этого не страдает
    end;
  finally
    FileLog.Free;
  end;
  FreeAndNil(StartLog);
  FreeAndNil(Splash);
  Active := False;
end;

function StartupActive: Boolean;
begin
  Result := Active;
end;

end.
