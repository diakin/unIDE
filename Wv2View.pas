unit Wv2View;

// ---------------------------------------------------------------------------
//  Просмотр страницы через Microsoft Edge WebView2 (Chromium) - отдельное
//  окно (проба замены встроенного IE). Обёртка - WebView4Delphi
//  (папка WebView4Delphi\source, см. README_unIDE.txt там же).
//
//  Загрузчик (GlobalWebView2Loader) создаётся при первом показе, а не при
//  запуске программы: без WebView2 Runtime unIDE работает как раньше.
//  Загрузчик встроенный (UseInternalLoader) - WebView2Loader.dll не нужна.
//  Runtime не установлен - Wv2Start возвращает False и причину; повторная
//  попытка (после установки Runtime) создаёт загрузчик заново.
//
//  Окно одно на программу (Wv2ShowFile): следующий файл открывается в нём
//  же. Закрытие окна его прячет; уничтожается окно в finalization этого
//  модуля - раньше, чем загрузчик (finalization uWVLoader): браузер должен
//  уйти до загрузчика.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, ExtCtrls,
  StdCtrls, Registry,
  uWVTypes, uWVTypeLibrary, uWVLoader, uWVBrowserBase, uWVBrowser,
  uWVWinControl, uWVWindowParent, uWVCoreWebView2Args;

const
  // Страница загрузки WebView2 Runtime (Evergreen Bootstrapper; на
  // Windows 7 ставит последнюю для неё версию 109)
  Wv2DownloadUrl =
    'https://developer.microsoft.com/microsoft-edge/webview2/consumer/';

type
  TWv2Form = class(TForm)
  private
    FTopPanel: TPanel;
    FPathLabel: TLabel;
    FReloadBtn: TButton;
    FWindowParent: TWVWindowParent;
    FBrowser: TWVBrowser;
    FWaitTimer: TTimer;
    FFileName: string;
    FBrowserReady: Boolean;
    FCreateAsked: Boolean;
    procedure WaitTimerTick(Sender: TObject);
    procedure ReloadClick(Sender: TObject);
    procedure BrowserAfterCreated(Sender: TObject);
    procedure BrowserInitError(Sender: TObject; aErrorCode: HRESULT;
      const aErrorMessage: wvstring);
    procedure BrowserTitleChanged(Sender: TObject);
    procedure BrowserNavCompleted(Sender: TObject; const aWebView: ICoreWebView2;
      const aArgs: ICoreWebView2NavigationCompletedEventArgs);
    procedure BrowserProcessFailed(Sender: TObject; const aWebView: ICoreWebView2;
      const aArgs: ICoreWebView2ProcessFailedEventArgs);
    procedure FormCloseEvent(Sender: TObject; var Action: TCloseAction);
    procedure StartBrowser;
    procedure NavigateFile;
    procedure SetStatus(const AText: string);
  protected
    procedure WMMove(var Message: TWMMove); message WM_MOVE;
    procedure WMMoving(var Message: TMessage); message WM_MOVING;
  public
    constructor CreateView(AOwner: TComponent);
    procedure ShowFile(const AFileName: string);
  end;

// Загрузчик WebView2: создать и запустить (асинхронно). False - не вышло,
// причина в AError; ARuntimeMissing - не установлен WebView2 Runtime
function Wv2Start(out AError: string; out ARuntimeMissing: Boolean): Boolean;
// Версия установленного WebView2 Runtime ('' - нет или загрузчика ещё нет)
function Wv2RuntimeVersion: string;
// Окно просмотра (создаётся при первом вызове) с файлом AFileName; nil -
// окна нет (Wv2Start не прошёл - причина в AError)
function Wv2ShowFile(const AFileName: string; out AError: string;
  out ARuntimeMissing: Boolean): TWv2Form;
// file:///D:/папка/файл.html: '\' -> '/', спецсимволы адреса - %XX
function Wv2FileUrl(const AFileName: string): WideString;
// Закрытие программы (FormDestroy главного окна): окно WebView2 и
// загрузчик - пока программа ещё целая. В finalization модулей (после
// конца Application.Run) их уничтожение давало Runtime error 216
procedure Wv2Shutdown;

implementation

var
  GWv2Form: TWv2Form;

// Папка данных WebView2 (кэш, профиль): %LOCALAPPDATA%\unIDE\WebView2;
// нет LOCALAPPDATA - папка Temp
function Wv2DataFolder: string;
var
  Buf: array[0..MAX_PATH] of Char;
  Len: DWORD;
begin
  Len := GetEnvironmentVariable('LOCALAPPDATA', Buf, MAX_PATH);
  if (Len > 0) and (Len < MAX_PATH) then
    Result := IncludeTrailingPathDelimiter(Buf)
  else
  begin
    Len := GetTempPath(MAX_PATH, Buf);
    if Len > 0 then
      Result := IncludeTrailingPathDelimiter(Buf)
    else
      Result := ExtractFilePath(ParamStr(0));
  end;
  Result := Result + 'unIDE\WebView2';
end;

// WebView2Loader.dll Microsoft (32-битная): рядом с exe, в
// WebView4Delphi\bin32 у exe или уровнем выше; '' - нет
function Wv2LoaderDll: string;
var
  ExeDir, Cand: string;
  CandIdx: Integer;
begin
  Result := '';
  ExeDir := ExtractFilePath(ParamStr(0));
  for CandIdx := 0 to 2 do
  begin
    case CandIdx of
      0: Cand := ExeDir + 'WebView2Loader.dll';
      1: Cand := ExeDir + 'WebView4Delphi\bin32\WebView2Loader.dll';
    else
      Cand := ExpandFileName(ExeDir + '..\WebView4Delphi\bin32\WebView2Loader.dll');
    end;
    if FileExists(Cand) then
    begin
      Result := Cand;
      Exit;
    end;
  end;
end;

// Версия WebView2 Runtime по реестру - так проверять её советует
// Microsoft: ключ клиента EdgeUpdate {F3017226-...}, значение pv
// (HKLM 32/64 и HKCU); '' или 0.0.0.0 - Runtime не установлен. Сам
// Microsoft Edge (браузер) - не Runtime
function Wv2RuntimeVersion: string;
const
  ClientKey = 'Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}';
var
  Reg: TRegistry;
  KeyIdx: Integer;
  KeyPath: string;
begin
  Result := '';
  for KeyIdx := 0 to 3 do
  begin
    Reg := TRegistry.Create(KEY_READ);
    try
      if KeyIdx < 2 then
        Reg.RootKey := HKEY_LOCAL_MACHINE
      else
        Reg.RootKey := HKEY_CURRENT_USER;
      if Odd(KeyIdx) then
        KeyPath := 'SOFTWARE\WOW6432Node\' + ClientKey
      else
        KeyPath := 'SOFTWARE\' + ClientKey;
      try
        if Reg.OpenKeyReadOnly(KeyPath) then
        begin
          if Reg.ValueExists('pv') then
            Result := Trim(Reg.ReadString('pv'));
          Reg.CloseKey;
        end;
      except
        Result := '';
      end;
    finally
      Reg.Free;
    end;
    if (Result <> '') and (Result <> '0.0.0.0') then
      Exit;
    Result := '';
  end;
end;

// Какой загрузчик сейчас: для строки окна и журнала
function Wv2LoaderName: string;
begin
  if (GlobalWebView2Loader <> nil) and not GlobalWebView2Loader.UseInternalLoader then
    Result := 'WebView2Loader.dll'
  else
    Result := 'встроенный загрузчик';
end;

function Wv2Start(out AError: string; out ARuntimeMissing: Boolean): Boolean;
begin
  AError := '';
  ARuntimeMissing := False;
  // Runtime не установлен - не запускать: загрузчик мог взять что-то
  // другое (сбой процесса, вид 0, код $FFFFFFFF на Windows 7 без Runtime)
  if Wv2RuntimeVersion = '' then
  begin
    AError := 'Microsoft Edge WebView2 Runtime не найден в реестре ' +
              '(EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5})';
    ARuntimeMissing := True;
    Result := False;
    Exit;
  end;
  // Прежняя попытка не удалась (Runtime не было) - загрузчик заново
  if (GlobalWebView2Loader <> nil) and
     GlobalWebView2Loader.InitializationError then
    FreeAndNil(GlobalWebView2Loader);
  if GlobalWebView2Loader = nil then
  begin
    GlobalWebView2Loader := TWVLoader.Create(nil);
    // COM главного потока уже поднят (встроенный IE, ComObj)
    GlobalWebView2Loader.InitCOMLibrary := False;
    // Загрузчик Microsoft (WebView2Loader.dll), если он есть: со встроенным
    // загрузчиком процесс WebView2 на Windows 7 завершался сразу после
    // показа страницы (сбой процесса, вид 0 - BROWSER_PROCESS_EXITED).
    // Нет dll - встроенный
    if Wv2LoaderDll <> '' then
    begin
      GlobalWebView2Loader.UseInternalLoader := False;
      GlobalWebView2Loader.LoaderDllPath := Wv2LoaderDll;
    end
    else
      GlobalWebView2Loader.UseInternalLoader := True;
    GlobalWebView2Loader.ShowMessageDlg := False;
    // Без GPU: на Windows 7 окно WebView2 с ускорением бывает чёрным
    // (--disable-gpu --disable-gpu-compositing)
    GlobalWebView2Loader.EnableGPU := False;
    // Журнал Chromium: EBWebView\chrome_debug.log в папке данных - причина,
    // по которой процесс браузера завершается (сбой процесса, вид 0)
    GlobalWebView2Loader.AdditionalBrowserArguments :=
      '--enable-logging --v=1';
    GlobalWebView2Loader.TargetCompatibleBrowserVersion := '86.0.616.0';
    GlobalWebView2Loader.UserDataFolder := Wv2DataFolder;
    try
      ForceDirectories(Wv2DataFolder);
    except
      // не создалась - WebView2 скажет сам
    end;
    if not GlobalWebView2Loader.StartWebView2 then
    begin
      AError := GlobalWebView2Loader.ErrorMessage;
      ARuntimeMissing := Wv2RuntimeVersion = '';
      FreeAndNil(GlobalWebView2Loader);
      Result := False;
      Exit;
    end;
  end;
  Result := not GlobalWebView2Loader.InitializationError;
  if not Result then
  begin
    AError := GlobalWebView2Loader.ErrorMessage;
    ARuntimeMissing := Wv2RuntimeVersion = '';
  end;
end;

function Wv2FileUrl(const AFileName: string): WideString;
var
  Wide: WideString;
  CharIdx: Integer;
  Ch: WideChar;
begin
  Wide := WideString(ExpandFileName(AFileName));
  Result := 'file:///';
  for CharIdx := 1 to Length(Wide) do
  begin
    Ch := Wide[CharIdx];
    case Ch of
      '\': Result := Result + '/';
      '%': Result := Result + '%25';
      '#': Result := Result + '%23';
      '?': Result := Result + '%3F';
      ' ': Result := Result + '%20';
    else
      Result := Result + Ch;
    end;
  end;
end;

function Wv2ShowFile(const AFileName: string; out AError: string;
  out ARuntimeMissing: Boolean): TWv2Form;
begin
  Result := nil;
  if not Wv2Start(AError, ARuntimeMissing) then
    Exit;
  if GWv2Form = nil then
    GWv2Form := TWv2Form.CreateView(Application);
  GWv2Form.ShowFile(AFileName);
  Result := GWv2Form;
end;

{ TWv2Form }

constructor TWv2Form.CreateView(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := 'WebView2';
  Width := 1000;
  Height := 750;
  Position := poScreenCenter;
  OnClose := FormCloseEvent;

  FTopPanel := TPanel.Create(Self);
  FTopPanel.Parent := Self;
  FTopPanel.Align := alTop;
  FTopPanel.Height := 30;
  FTopPanel.BevelOuter := bvNone;
  FTopPanel.Caption := '';

  FReloadBtn := TButton.Create(Self);
  FReloadBtn.Parent := FTopPanel;
  FReloadBtn.SetBounds(6, 3, 90, 24);
  FReloadBtn.Caption := 'Обновить';
  FReloadBtn.Hint := 'Открыть файл заново (с диска)';
  FReloadBtn.ShowHint := True;
  FReloadBtn.OnClick := ReloadClick;

  FPathLabel := TLabel.Create(Self);
  FPathLabel.Parent := FTopPanel;
  FPathLabel.SetBounds(104, 8, 880, 16);
  FPathLabel.Anchors := [akLeft, akTop, akRight];
  FPathLabel.AutoSize := False;
  FPathLabel.ShowAccelChar := False;
  FPathLabel.Caption := '';

  FWindowParent := TWVWindowParent.Create(Self);
  FWindowParent.Parent := Self;
  FWindowParent.Align := alClient;

  FBrowser := TWVBrowser.Create(Self);
  FBrowser.TargetCompatibleBrowserVersion := '86.0.616.0';
  FBrowser.OnAfterCreated := BrowserAfterCreated;
  FBrowser.OnInitializationError := BrowserInitError;
  FBrowser.OnDocumentTitleChanged := BrowserTitleChanged;
  FBrowser.OnNavigationCompleted := BrowserNavCompleted;
  FBrowser.OnProcessFailed := BrowserProcessFailed;
  FWindowParent.Browser := FBrowser;

  // Окружение WebView2 создаётся асинхронно - браузер ждёт его по таймеру
  FWaitTimer := TTimer.Create(Self);
  FWaitTimer.Enabled := False;
  FWaitTimer.Interval := 100;
  FWaitTimer.OnTimer := WaitTimerTick;
end;

procedure TWv2Form.SetStatus(const AText: string);
begin
  FPathLabel.Caption := AText;
  FPathLabel.Hint := AText;
end;

procedure TWv2Form.ShowFile(const AFileName: string);
begin
  FFileName := AFileName;
  Caption := 'WebView2 - ' + ExtractFileName(AFileName);
  SetStatus(AFileName);
  Show;
  if WindowState = wsMinimized then
    WindowState := wsNormal;
  BringToFront;
  if FBrowserReady then
    NavigateFile
  else
    StartBrowser;
end;

// Окружение готово - браузер в окне; нет - ждать по таймеру
procedure TWv2Form.StartBrowser;
begin
  if FCreateAsked then
    Exit;
  if (GlobalWebView2Loader = nil) or GlobalWebView2Loader.InitializationError then
  begin
    SetStatus('WebView2 не запустился');
    Exit;
  end;
  if GlobalWebView2Loader.Initialized then
  begin
    FCreateAsked := True;
    SetStatus('Запуск WebView2...');
    if not FBrowser.CreateBrowser(FWindowParent.Handle) then
    begin
      FCreateAsked := False;
      SetStatus('WebView2: браузер не создался');
    end;
  end
  else
  begin
    SetStatus('Ожидание WebView2...');
    FWaitTimer.Enabled := True;
  end;
end;

procedure TWv2Form.WaitTimerTick(Sender: TObject);
begin
  FWaitTimer.Enabled := False;
  if (GlobalWebView2Loader = nil) or GlobalWebView2Loader.InitializationError then
  begin
    if GlobalWebView2Loader <> nil then
      SetStatus('WebView2 не запустился: ' + GlobalWebView2Loader.ErrorMessage)
    else
      SetStatus('WebView2 не запустился');
    Exit;
  end;
  if GlobalWebView2Loader.Initialized then
    StartBrowser
  else
    FWaitTimer.Enabled := True;
end;

procedure TWv2Form.NavigateFile;
begin
  if FFileName = '' then
    Exit;
  SetStatus(FFileName + '   (WebView2 ' + Wv2RuntimeVersion + ', ' +
            Wv2LoaderName + ')');
  if not FBrowser.Navigate(Wv2FileUrl(FFileName)) then
    SetStatus('WebView2: не открылся ' + FFileName);
end;

procedure TWv2Form.ReloadClick(Sender: TObject);
begin
  if FBrowserReady then
    NavigateFile;
end;

procedure TWv2Form.BrowserAfterCreated(Sender: TObject);
begin
  FBrowserReady := True;
  FWindowParent.UpdateSize;
  NavigateFile;
end;

procedure TWv2Form.BrowserInitError(Sender: TObject; aErrorCode: HRESULT;
  const aErrorMessage: wvstring);
begin
  FCreateAsked := False;
  SetStatus('WebView2: ошибка ' + IntToHex(aErrorCode, 8) + ' - ' +
            string(aErrorMessage));
end;

procedure TWv2Form.BrowserTitleChanged(Sender: TObject);
begin
  if FBrowser.DocumentTitle <> '' then
    Caption := 'WebView2 - ' + string(FBrowser.DocumentTitle)
  else
    Caption := 'WebView2 - ' + ExtractFileName(FFileName);
end;

// Загрузка закончилась: успех - путь и версия Runtime, ошибка - её код
// (COREWEBVIEW2_WEB_ERROR_STATUS)
procedure TWv2Form.BrowserNavCompleted(Sender: TObject;
  const aWebView: ICoreWebView2;
  const aArgs: ICoreWebView2NavigationCompletedEventArgs);
var
  Args: TCoreWebView2NavigationCompletedEventArgs;
begin
  Args := TCoreWebView2NavigationCompletedEventArgs.Create(aArgs);
  try
    if Args.IsSuccess then
      SetStatus(FFileName + '   (загружено, WebView2 ' + Wv2RuntimeVersion +
                ', ' + Wv2LoaderName + ')')
    else
      SetStatus('WebView2: страница не загрузилась, код ошибки ' +
                IntToStr(Integer(Args.WebErrorStatus)) + ' - ' + FFileName);
  finally
    Args.Free;
  end;
end;

// Процесс WebView2 (браузер, страница, GPU) упал или завис
procedure TWv2Form.BrowserProcessFailed(Sender: TObject;
  const aWebView: ICoreWebView2;
  const aArgs: ICoreWebView2ProcessFailedEventArgs);
var
  Args: TCoreWebView2ProcessFailedEventArgs;
begin
  Args := TCoreWebView2ProcessFailedEventArgs.Create(aArgs);
  try
    // Вид: 0 - процесс браузера завершился, 1 - процесс страницы
    // завершился, 2 - страница не отвечает, 3+ - фреймы, GPU, служебные.
    // Причина: 0 неожиданно, 1 не отвечает, 2 завершён извне, 3 упал,
    // 4 не запустился, 5 нехватка памяти, 7 обычный выход, 8 аварийный
    // выход, 9 проверка целостности (модуль не дали загрузить)
    SetStatus('WebView2: сбой процесса, вид ' +
              IntToStr(Integer(Args.ProcessFailedKind)) + ', причина ' +
              IntToStr(Integer(Args.Reason)) + ', код выхода $' +
              IntToHex(Args.ExtiCode, 8) + ' ' +
              string(Args.ProcessDescription) + ' (' + Wv2LoaderName +
              '); журнал - ' + Wv2DataFolder + '\EBWebView\chrome_debug.log');
  finally
    Args.Free;
  end;
end;

procedure TWv2Form.FormCloseEvent(Sender: TObject; var Action: TCloseAction);
begin
  Action := caHide;
end;

// Без этого часть элементов страницы (выпадающие списки) встаёт не на место
procedure TWv2Form.WMMove(var Message: TWMMove);
begin
  inherited;
  if FBrowser <> nil then
    FBrowser.NotifyParentWindowPositionChanged;
end;

procedure TWv2Form.WMMoving(var Message: TMessage);
begin
  inherited;
  if FBrowser <> nil then
    FBrowser.NotifyParentWindowPositionChanged;
end;

procedure Wv2Shutdown;
begin
  // Браузер - раньше загрузчика
  try
    if GWv2Form <> nil then
    begin
      GWv2Form.Hide;
      FreeAndNil(GWv2Form);
    end;
  except
    GWv2Form := nil;
  end;
  try
    if GlobalWebView2Loader <> nil then
      FreeAndNil(GlobalWebView2Loader);
  except
    GlobalWebView2Loader := nil;
  end;
end;

initialization

finalization
  // На случай, если Wv2Shutdown не звали
  Wv2Shutdown;

end.
