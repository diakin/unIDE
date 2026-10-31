unit PathKit;

// Пути и имена программ (шаг 0.3 плана портирования): разделитель папок,
// расширение исполняемого файла, проверка "путь полный", папки рядом с exe.
//
// Под Windows всё совпадает с тем, что было в коде до этого шага: '\',
// '.exe', полный путь - с буквой диска, с '\' или '\\' в начале. Под
// Linux - '/', без расширения, полный путь начинается с '/'.
//
// Delphi 7: без PtrUInt, Exit(значение), inline. Без Forms: папка
// программы - по ParamStr(0) (то же, что Application.ExeName).

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  SysUtils;

const
  {$IFDEF MSWINDOWS}
  ExeExt = '.exe';
  {$ELSE}
  ExeExt = '';
  {$ENDIF}

// Имя исполняемого файла: 'fpc' -> 'fpc.exe' (Windows), 'fpc' (Linux)
function ExeName(const ABase: string): string;
// Разделитель папок у символа: под Windows '\' и '/', иначе '/'
function IsPathSep(ACh: Char): Boolean;
// Разделители - родные для системы: под Windows '/' -> '\', иначе
// '\' -> '/'
function PathNative(const APath: string): string;
// Путь полный (не от текущей папки): Windows - 'C:...', '\...', '\\...';
// иначе '/...'
function PathIsAbs(const APath: string): Boolean;
// Сетевой путь Windows '\\сервер\...'; не под Windows - False
function PathIsUnc(const APath: string): Boolean;
// ADir + AName через один разделитель; AName - с разделителями любого вида
function PathJoin(const ADir, AName: string): string;
// Папка программы с разделителем в конце
function AppDir: string;
// Папка рядом с программой с разделителем в конце: AppSubDir('schemes')
function AppSubDir(const AName: string): string;
// Файл в папке программы: AppFile('dsgcache\clipboard.txt')
function AppFile(const ARelName: string): string;

implementation

function ExeName(const ABase: string): string;
begin
  Result := ABase + ExeExt;
end;

function IsPathSep(ACh: Char): Boolean;
begin
  {$IFDEF MSWINDOWS}
  Result := (ACh = '\') or (ACh = '/');
  {$ELSE}
  Result := ACh = '/';
  {$ENDIF}
end;

function PathNative(const APath: string): string;
begin
  {$IFDEF MSWINDOWS}
  Result := StringReplace(APath, '/', '\', [rfReplaceAll]);
  {$ELSE}
  Result := StringReplace(APath, '\', '/', [rfReplaceAll]);
  {$ENDIF}
end;

function PathIsAbs(const APath: string): Boolean;
begin
  {$IFDEF MSWINDOWS}
  Result := (ExtractFileDrive(APath) <> '') or (Copy(APath, 1, 1) = '\');
  {$ELSE}
  Result := Copy(APath, 1, 1) = '/';
  {$ENDIF}
end;

function PathIsUnc(const APath: string): Boolean;
begin
  {$IFDEF MSWINDOWS}
  Result := Copy(APath, 1, 2) = '\\';
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function PathJoin(const ADir, AName: string): string;
begin
  if ADir = '' then
    Result := PathNative(AName)
  else
    Result := IncludeTrailingPathDelimiter(ADir) + PathNative(AName);
end;

function AppDir: string;
begin
  Result := ExtractFilePath(ParamStr(0));
end;

function AppSubDir(const AName: string): string;
begin
  Result := AppDir + PathNative(AName) + PathDelim;
end;

function AppFile(const ARelName: string): string;
begin
  Result := AppDir + PathNative(ARelName);
end;

end.
