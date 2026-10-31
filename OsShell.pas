unit OsShell;

// Оболочка ОС (шаг 0.4 плана портирования): открыть файл, папку или адрес
// программой, назначенной в системе; показать файл в папке; запустить
// программу через оболочку; убрать файл или папку в корзину. Выбор папки -
// FolderDlg (BrowseFolderDialog), он уже один на всю программу.
//
// Под Windows - ShellExecute и SHFileOperation, как было в модулях до
// этого шага. Не под Windows - xdg-open и gio trash (через ProcRun).
//
// Delphi 7: без PtrUInt, Exit(значение), inline.

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  {$IFDEF MSWINDOWS}Windows, ShellAPI,{$ENDIF} SysUtils, Classes;

type
  // Корзина: предупредить, если файл в корзину не помещается и будет
  // удалён насовсем (FOF_WANTNUKEWARNING)
  TShellRecycleOption = (sroNukeWarning);
  TShellRecycleOptions = set of TShellRecycleOption;

// Открыть файл, папку или адрес (http://...) программой системы. AOwner -
// окно для сообщений оболочки (0 - нет). False - не открылось
function ShellOpen(AOwner: THandle; const ATarget: string): Boolean;
// То же, AError - текст ошибки
function ShellOpenErr(AOwner: THandle; const ATarget: string;
  var AError: string): Boolean;
// Открыть файл, ADir - текущая папка для программы
function ShellOpenIn(AOwner: THandle; const ATarget, ADir: string): Boolean;
// Запустить программу AExe с параметрами AParams через оболочку, не ждать
function ShellRun(AOwner: THandle; const AExe, AParams, ADir: string): Boolean;
// Открыть папку файла AFile с выделенным файлом (Windows - Проводник
// /select; иначе - просто папку)
function ShellShowInFolder(AOwner: THandle; const AFile: string): Boolean;
// Файл или папку APath - в корзину без вопроса. Результат: 0 - готово,
// иначе код ошибки; AAborted - пользователь отменил
function ShellRecycle(AOwner: THandle; const APath: string;
  AOptions: TShellRecycleOptions; var AAborted: Boolean): Integer;
// Файлы (полные пути, Unicode) - в корзину без вопросов и без окон
// ошибок; которых нет - пропускаются. False - не вышло или отменено
function ShellRecycleFilesW(AOwner: THandle;
  const AFiles: array of WideString): Boolean;

implementation

{$IFNDEF MSWINDOWS}
uses
  ProcRun;

function QuoteArg(const AText: string): string;
begin
  Result := '"' + StringReplace(AText, '"', '\"', [rfReplaceAll]) + '"';
end;

// Запустить и забыть
function LaunchCmd(const ACmdLine, ADir: string; var AError: string): Boolean;
begin
  Result := ProcLaunch(ACmdLine, ADir, AError);
end;
{$ENDIF}

{$IFDEF MSWINDOWS}
const
  ShellFofWantNukeWarning = $4000;   // FOF_WANTNUKEWARNING (нет в Delphi 7)
  ShellFoDelete = 3;                  // FO_DELETE
  ShellFofSilent = $4;                // FOF_SILENT
  ShellFofNoConfirmation = $10;       // FOF_NOCONFIRMATION
  ShellFofAllowUndo = $40;            // FOF_ALLOWUNDO
  ShellFofNoErrorUI = $400;           // FOF_NOERRORUI

type
  // SHFILEOPSTRUCTW: в 32-битной Windows без выравнивания (pshpack1 в
  // shellapi.h), в 64-битной - обычное выравнивание
  {$IFDEF WIN64}
  TShellFileOpW = record
  {$ELSE}
  TShellFileOpW = packed record
  {$ENDIF}
    Wnd: HWND;
    Func: UINT;
    From: PWideChar;
    Dest: PWideChar;
    Flags: Word;
    AnyAborted: BOOL;
    NameMappings: Pointer;
    ProgressTitle: PWideChar;
  end;

function ShellFileOperationW(var AOp: TShellFileOpW): Integer; stdcall;
  external 'shell32.dll' name 'SHFileOperationW';
function ShellGetFileAttributesW(AName: PWideChar): DWORD; stdcall;
  external 'kernel32.dll' name 'GetFileAttributesW';

function OpenCode(AOwner: THandle; const AFile, AParams, ADir: string): Integer;
var
  ParamPtr, DirPtr: PChar;
begin
  ParamPtr := nil;
  if AParams <> '' then
    ParamPtr := PChar(AParams);
  DirPtr := nil;
  if ADir <> '' then
    DirPtr := PChar(ADir);
  Result := Integer(ShellExecute(AOwner, 'open', PChar(AFile), ParamPtr,
    DirPtr, SW_SHOWNORMAL));
end;
{$ENDIF}

function ShellOpenErr(AOwner: THandle; const ATarget: string;
  var AError: string): Boolean;
{$IFDEF MSWINDOWS}
var
  Code: Integer;
{$ENDIF}
begin
  AError := '';
  {$IFDEF MSWINDOWS}
  Code := OpenCode(AOwner, ATarget, '', '');
  Result := Code > 32;
  if not Result then
    AError := SysErrorMessage(Code) + ' (код ' + IntToStr(Code) + ')';
  {$ELSE}
  Result := LaunchCmd('xdg-open ' + QuoteArg(ATarget), '', AError);
  {$ENDIF}
end;

function ShellOpen(AOwner: THandle; const ATarget: string): Boolean;
var
  ErrText: string;
begin
  Result := ShellOpenErr(AOwner, ATarget, ErrText);
end;

function ShellOpenIn(AOwner: THandle; const ATarget, ADir: string): Boolean;
{$IFNDEF MSWINDOWS}
var
  ErrText: string;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  Result := OpenCode(AOwner, ATarget, '', ADir) > 32;
  {$ELSE}
  Result := LaunchCmd('xdg-open ' + QuoteArg(ATarget), ADir, ErrText);
  {$ENDIF}
end;

function ShellRun(AOwner: THandle; const AExe, AParams, ADir: string): Boolean;
{$IFNDEF MSWINDOWS}
var
  ErrText: string;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  Result := OpenCode(AOwner, AExe, AParams, ADir) > 32;
  {$ELSE}
  Result := LaunchCmd(QuoteArg(AExe) + ' ' + AParams, ADir, ErrText);
  {$ENDIF}
end;

function ShellShowInFolder(AOwner: THandle; const AFile: string): Boolean;
begin
  {$IFDEF MSWINDOWS}
  Result := OpenCode(AOwner, 'explorer.exe', '/select,"' + AFile + '"',
    '') > 32;
  {$ELSE}
  Result := ShellOpen(AOwner, ExtractFilePath(AFile));
  {$ENDIF}
end;

function ShellRecycle(AOwner: THandle; const APath: string;
  AOptions: TShellRecycleOptions; var AAborted: Boolean): Integer;
{$IFDEF MSWINDOWS}
var
  Op: TSHFileOpStruct;
  Src: string;
begin
  AAborted := False;
  // Список путей для оболочки заканчивается двумя нулями
  Src := ExcludeTrailingPathDelimiter(APath) + #0#0;
  FillChar(Op, SizeOf(Op), 0);
  Op.Wnd := AOwner;
  Op.wFunc := ShellFoDelete;
  Op.pFrom := PChar(Src);
  Op.fFlags := ShellFofAllowUndo or ShellFofNoConfirmation;
  if sroNukeWarning in AOptions then
    Op.fFlags := Op.fFlags or ShellFofWantNukeWarning;
  Result := SHFileOperation(Op);
  AAborted := Op.fAnyOperationsAborted;
end;
{$ELSE}
var
  Proc: TProcRun;
begin
  AAborted := False;
  Proc := TProcRun.Create;
  try
    Proc.CommandLine := 'gio trash ' +
      QuoteArg(ExcludeTrailingPathDelimiter(APath));
    if not Proc.Start then
    begin
      Result := Proc.ErrorCode;
      if Result = 0 then
        Result := -1;
      Exit;
    end;
    Proc.WaitFor($FFFFFFFF);
    Result := Proc.ExitCode;
  finally
    Proc.Free;
  end;
end;
{$ENDIF}

function ShellRecycleFilesW(AOwner: THandle;
  const AFiles: array of WideString): Boolean;
{$IFDEF MSWINDOWS}
var
  FromList: WideString;
  FileIdx: Integer;
  ShellOp: TShellFileOpW;
begin
  Result := True;
  FromList := '';
  // Только то, что есть: отсутствующий файл SHFileOperation считает
  // ошибкой и не трогает остальные
  for FileIdx := 0 to High(AFiles) do
    if (AFiles[FileIdx] <> '') and
       (ShellGetFileAttributesW(PWideChar(AFiles[FileIdx])) <> $FFFFFFFF) then
      FromList := FromList + AFiles[FileIdx] + WideChar(#0);
  if FromList = '' then
    Exit;
  FromList := FromList + WideChar(#0);
  FillChar(ShellOp, SizeOf(ShellOp), 0);
  ShellOp.Wnd := AOwner;
  ShellOp.Func := ShellFoDelete;
  ShellOp.From := PWideChar(FromList);
  ShellOp.Flags := ShellFofAllowUndo or ShellFofNoConfirmation or
    ShellFofSilent or ShellFofNoErrorUI;
  Result := (ShellFileOperationW(ShellOp) = 0) and not ShellOp.AnyAborted;
end;
{$ELSE}
var
  CmdLine, FileName: string;
  FileIdx: Integer;
  Proc: TProcRun;
begin
  Result := True;
  CmdLine := '';
  for FileIdx := 0 to High(AFiles) do
  begin
    FileName := UTF8Encode(AFiles[FileIdx]);
    if (FileName <> '') and (FileExists(FileName) or
       DirectoryExists(FileName)) then
      CmdLine := CmdLine + ' ' + QuoteArg(FileName);
  end;
  if CmdLine = '' then
    Exit;
  Proc := TProcRun.Create;
  try
    Proc.CommandLine := 'gio trash' + CmdLine;
    Result := Proc.Start;
    if Result then
    begin
      Proc.WaitFor($FFFFFFFF);
      Result := Proc.ExitCode = 0;
    end;
  finally
    Proc.Free;
  end;
end;
{$ENDIF}

end.
