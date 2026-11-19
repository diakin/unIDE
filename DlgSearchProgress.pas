unit DlgSearchProgress;

// ---------------------------------------------------------------------------
//  Окно хода поиска потерянных файлов (Windows - Find lost files..., вопрос
//  «Искать их?» после загрузки проекта; Unit1.RelocateBrokenWindows).
//
//  Отдельное окно без модального цикла: поиск идёт в главном потоке, а
//  окно обслуживает SearchProgressPump, который поиск зовёт часто (не чаще
//  раза в 50 мс работает). Pump перерисовывает окна, пропускает мышь в
//  окно хода (кнопка Стоп, перетаскивание за заголовок), остальную мышь и
//  клавиатуру отбрасывает: команды меню посреди поиска не выполняются.
//  Esc в любом окне программы и Стоп - SearchProgressStopped = True.
//
//  В окне: какой файл ищется (N из M), папка обхода, список найденных и не
//  найденных файлов. После SearchProgressEnd окно остаётся с итогом,
//  кнопка становится «Закрыть»; следующий SearchProgressBegin берёт то же
//  окно и очищает список.
//
//  Окно строится в коде, .dfm нет.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls,
  UiButton,      // TUiButton
  UiEditCtrls,   // TUiListBox
  UiStdCtrls;    // TUiLabel

procedure SearchProgressBegin(const ACaption: string; ATotal: Integer);
procedure SearchProgressFile(const AFile: string; AIndex: Integer);
procedure SearchProgressDir(const ADir: string);
procedure SearchProgressResult(const AFile, AFound: string);
procedure SearchProgressEnd(const AResult: string);
// Окно живёт: перерисовка, мышь в окно хода, Esc. Не чаще раза в 50 мс
procedure SearchProgressPump;
function  SearchProgressStopped: Boolean;

implementation

type
  TDlgSearchProgress = class(TForm)
  private
    FLblFile: TUiLabel;
    FLblDir: TUiLabel;
    FLblList: TUiLabel;
    FList: TUiListBox;
    FBtnStop: TUiButton;
    FRunning: Boolean;
    FStopped: Boolean;
    FTotal: Integer;
    FFoundCount: Integer;
    FMissCount: Integer;
    FLastPump: Cardinal;
    procedure BtnStopClick(Sender: TObject);
    procedure FormCloseQueryEvent(Sender: TObject; var CanClose: Boolean);
    procedure UpdateListCaption;
  public
    constructor CreateDlg(AOwner: TComponent);
  end;

var
  Dlg: TDlgSearchProgress = nil;

// Длинный путь - начало и конец с многоточием посередине
function ShortPath(const APath: string; AMaxLen: Integer): string;
begin
  if Length(APath) <= AMaxLen then
    Result := APath
  else
    Result := Copy(APath, 1, 20) + '...' +
      Copy(APath, Length(APath) - (AMaxLen - 24), MaxInt);
end;

constructor TDlgSearchProgress.CreateDlg(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := 'Поиск потерянных файлов';
  BorderStyle := bsSizeToolWin;
  Position := poMainFormCenter;
  ClientWidth := 640;
  ClientHeight := 300;
  Constraints.MinWidth := 400;
  Constraints.MinHeight := 220;
  OnCloseQuery := FormCloseQueryEvent;

  FLblFile := TUiLabel.Create(Self);
  FLblFile.Parent := Self;
  FLblFile.AutoSize := False;
  FLblFile.SetBounds(8, 8, 624, 16);
  FLblFile.Anchors := [akLeft, akTop, akRight];
  FLblFile.Font.Style := [fsBold];

  FLblDir := TUiLabel.Create(Self);
  FLblDir.Parent := Self;
  FLblDir.AutoSize := False;
  FLblDir.SetBounds(8, 28, 624, 16);
  FLblDir.Anchors := [akLeft, akTop, akRight];

  FLblList := TUiLabel.Create(Self);
  FLblList.Parent := Self;
  FLblList.AutoSize := False;
  FLblList.SetBounds(8, 52, 624, 16);
  FLblList.Anchors := [akLeft, akTop, akRight];

  FList := TUiListBox.Create(Self);
  FList.Parent := Self;
  FList.SetBounds(8, 70, 624, 186);
  FList.Anchors := [akLeft, akTop, akRight, akBottom];

  FBtnStop := TUiButton.Create(Self);
  FBtnStop.Parent := Self;
  FBtnStop.SetBounds(544, 266, 88, 26);
  FBtnStop.Anchors := [akRight, akBottom];
  FBtnStop.Caption := 'Стоп';
  FBtnStop.Hint := 'Остановить поиск (или Esc)';
  FBtnStop.ShowHint := True;
  FBtnStop.OnClick := BtnStopClick;
end;

procedure TDlgSearchProgress.BtnStopClick(Sender: TObject);
begin
  if FRunning then
    FStopped := True
  else
    Hide;
end;

// Крестик во время поиска - то же, что Стоп; окно уходит после конца
procedure TDlgSearchProgress.FormCloseQueryEvent(Sender: TObject;
  var CanClose: Boolean);
begin
  if FRunning then
  begin
    FStopped := True;
    CanClose := False;
  end;
end;

procedure TDlgSearchProgress.UpdateListCaption;
begin
  FLblList.Caption := Format('Найдено: %d   не найдено: %d',
    [FFoundCount, FMissCount]);
end;

procedure SearchProgressBegin(const ACaption: string; ATotal: Integer);
begin
  if Dlg = nil then
    Dlg := TDlgSearchProgress.CreateDlg(Application);
  Dlg.Caption := ACaption;
  Dlg.FRunning := True;
  Dlg.FStopped := False;
  Dlg.FTotal := ATotal;
  Dlg.FFoundCount := 0;
  Dlg.FMissCount := 0;
  Dlg.FLastPump := 0;
  Dlg.FList.Items.Clear;
  Dlg.FLblFile.Caption := '';
  Dlg.FLblDir.Caption := '';
  Dlg.UpdateListCaption;
  Dlg.FBtnStop.Caption := 'Стоп';
  Dlg.Show;
  Dlg.Update;
end;

procedure SearchProgressFile(const AFile: string; AIndex: Integer);
begin
  if (Dlg = nil) or not Dlg.FRunning then
    Exit;
  Dlg.FLblFile.Caption := Format('Ищется %d из %d: %s',
    [AIndex, Dlg.FTotal, ExtractFileName(AFile)]);
  Dlg.FLblFile.Hint := AFile;
  Dlg.FLblFile.ShowHint := True;
  Dlg.FLblDir.Caption := '';
  Dlg.Update;
end;

procedure SearchProgressDir(const ADir: string);
begin
  if (Dlg = nil) or not Dlg.FRunning then
    Exit;
  Dlg.FLblDir.Caption := 'Папка: ' + ShortPath(ADir, 100);
end;

// AFound = '' - не найден
procedure SearchProgressResult(const AFile, AFound: string);
begin
  if (Dlg = nil) or not Dlg.FRunning then
    Exit;
  if AFound <> '' then
  begin
    Inc(Dlg.FFoundCount);
    Dlg.FList.Items.Add('найден: ' + AFile + '  ->  ' + AFound);
  end
  else
  begin
    Inc(Dlg.FMissCount);
    Dlg.FList.Items.Add('не найден: ' + AFile);
  end;
  Dlg.FList.ItemIndex := Dlg.FList.Items.Count - 1;
  Dlg.UpdateListCaption;
  Dlg.Update;
end;

procedure SearchProgressEnd(const AResult: string);
begin
  if Dlg = nil then
    Exit;
  Dlg.FRunning := False;
  Dlg.FLblFile.Caption := AResult;
  Dlg.FLblDir.Caption := '';
  Dlg.FBtnStop.Caption := 'Закрыть';
  Dlg.FBtnStop.Hint := '';
  Dlg.Update;
end;

// Окно хода или его элемент
function IsDlgWnd(AWnd: HWND): Boolean;
begin
  Result := (Dlg <> nil) and Dlg.HandleAllocated and
    ((AWnd = Dlg.Handle) or IsChild(Dlg.Handle, AWnd));
end;

procedure SearchProgressPump;
var
  WinMsg: TMsg;
  Command: Cardinal;
  TickNow: Cardinal;
begin
  if (Dlg = nil) or not Dlg.FRunning then
    Exit;
  TickNow := GetTickCount;
  if TickNow - Dlg.FLastPump < 50 then
    Exit;
  Dlg.FLastPump := TickNow;
  if Application.Active and (GetAsyncKeyState(VK_ESCAPE) < 0) then
    Dlg.FStopped := True;
  // Клавиатура - мимо (Esc проверен выше)
  while PeekMessage(WinMsg, 0, WM_KEYFIRST, WM_KEYLAST, PM_REMOVE) do
    ;
  // Мышь - только окну хода (Стоп, список)
  while PeekMessage(WinMsg, 0, WM_MOUSEFIRST, WM_MOUSELAST, PM_REMOVE) do
    if IsDlgWnd(WinMsg.hwnd) then
      DispatchMessage(WinMsg);
  // Заголовок: окно хода можно двигать и закрыть крестиком (= Стоп)
  while PeekMessage(WinMsg, 0, WM_NCMOUSEMOVE, WM_NCMBUTTONDBLCLK,
                    PM_REMOVE) do
    if IsDlgWnd(WinMsg.hwnd) then
      DispatchMessage(WinMsg);
  // Кнопка на панели задач: свернуть / развернуть; у окна хода - всё
  while PeekMessage(WinMsg, 0, WM_SYSCOMMAND, WM_SYSCOMMAND, PM_REMOVE) do
  begin
    Command := Cardinal(WinMsg.wParam) and $FFF0;
    if IsDlgWnd(WinMsg.hwnd) or (Command = SC_MINIMIZE) or
       (Command = SC_RESTORE) or (Command = SC_MAXIMIZE) then
      DispatchMessage(WinMsg);
  end;
  while PeekMessage(WinMsg, 0, WM_PAINT, WM_PAINT, PM_REMOVE) do
    DispatchMessage(WinMsg);
  // Остальное остаётся в очереди; PeekMessage заодно говорит Windows,
  // что программа отвечает
  PeekMessage(WinMsg, 0, 0, 0, PM_NOREMOVE);
end;

function SearchProgressStopped: Boolean;
begin
  Result := (Dlg <> nil) and Dlg.FStopped;
end;

end.
