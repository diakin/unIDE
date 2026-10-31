unit OsReg;

// Чтение реестра Windows: сведения об установленных программах (Delphi,
// AutoHotkey, Lazarus) и сохранённые переменные окружения.
//
// Настройки самой среды в реестр не пишутся - они в editor.ini. Здесь
// только чтение чужих записей. На других системах реестра нет: функции
// возвращают пустую строку или False, и вызывающий код идёт дальше по
// своим запасным путям (переменные окружения, папки по умолчанию).
//
// 64-разрядная сборка ищет ветку сначала в родном представлении, потом в
// 32-разрядном (Wow6432Node) - туда пишут установщики Delphi 7 и BDS.
// 32-разрядную программу Windows уводит туда сама.

interface

uses
  Classes;

type
  TOsRegRoot = (orUser, orMachine);   // HKEY_CURRENT_USER, HKEY_LOCAL_MACHINE

// Есть ли ветка
function OsRegKeyExists(ARoot: TOsRegRoot; const AKey: string): Boolean;

// Строковое значение (REG_SZ, REG_EXPAND_SZ). '' - нет ветки, нет значения
// или значение другого типа.
function OsRegReadString(ARoot: TOsRegRoot;
                         const AKey, AName: string): string;

// То же, сначала в HKCU, потом в HKLM. '' - нет нигде.
function OsRegReadAny(const AKey, AName: string): string;

// Имена подветок. False - ветки нет; AList при этом пуст.
function OsRegSubKeys(ARoot: TOsRegRoot; const AKey: string;
                      AList: TStrings): Boolean;

// Имена значений ветки. False - ветки нет; AList при этом пуст.
function OsRegValueNames(ARoot: TOsRegRoot; const AKey: string;
                         AList: TStrings): Boolean;

// Строковые значения ветки строками Имя=значение (нестроковые пропускаются).
// False - ветки нет; AList при этом пуст.
function OsRegValues(ARoot: TOsRegRoot; const AKey: string;
                     AList: TStrings): Boolean;

// Переменная окружения в том виде, как она сохранена в системе: сначала
// пользовательская (HKCU\Environment), потом общая (Session Manager).
// Нужна, когда переменную завели после запуска программы и в её
// собственном окружении её ещё нет. Вне Windows - ''.
function OsStoredEnvVar(const AName: string): string;

implementation

{$IFDEF MSWINDOWS}
uses
  Windows, Registry;

const
  OsKeyWow64Hive32 = $0200;   // KEY_WOW64_32KEY

function OsRegOpenView(ARoot: TOsRegRoot; const AKey: string;
                       AAccess: LongWord): TRegistry;
begin
  if AAccess = 0 then
    Result := TRegistry.Create
  else
    Result := TRegistry.Create(AAccess);
  try
    if ARoot = orUser then
      Result.RootKey := HKEY_CURRENT_USER
    else
      Result.RootKey := HKEY_LOCAL_MACHINE;
    if (AKey = '') or not Result.OpenKeyReadOnly(AKey) then
    begin
      Result.Free;
      Result := nil;
    end;
  except
    Result.Free;
    Result := nil;
  end;
end;

// 64-разрядная сборка: сначала родное представление, потом 32-разрядное
function OsRegOpen(ARoot: TOsRegRoot; const AKey: string): TRegistry;
begin
  Result := OsRegOpenView(ARoot, AKey, 0);
  {$IFDEF WIN64}
  if Result = nil then
    Result := OsRegOpenView(ARoot, AKey, KEY_READ or OsKeyWow64Hive32);
  {$ENDIF}
end;

function OsRegString(AReg: TRegistry; const AName: string): string;
begin
  Result := '';
  try
    if AReg.ValueExists(AName) and
       (AReg.GetDataType(AName) in [rdString, rdExpandString]) then
      Result := AReg.ReadString(AName);
  except
    Result := '';
  end;
end;

function OsRegKeyExists(ARoot: TOsRegRoot; const AKey: string): Boolean;
var
  Reg: TRegistry;
begin
  Reg := OsRegOpen(ARoot, AKey);
  Result := Reg <> nil;
  Reg.Free;
end;

function OsRegReadString(ARoot: TOsRegRoot;
                         const AKey, AName: string): string;
var
  Reg: TRegistry;
begin
  Result := '';
  Reg := OsRegOpen(ARoot, AKey);
  if Reg = nil then
    Exit;
  try
    Result := OsRegString(Reg, AName);
  finally
    Reg.Free;
  end;
end;

function OsRegSubKeys(ARoot: TOsRegRoot; const AKey: string;
                      AList: TStrings): Boolean;
var
  Reg: TRegistry;
begin
  AList.Clear;
  Reg := OsRegOpen(ARoot, AKey);
  Result := Reg <> nil;
  if not Result then
    Exit;
  try
    try
      Reg.GetKeyNames(AList);
    except
      AList.Clear;
    end;
  finally
    Reg.Free;
  end;
end;

function OsRegValueNames(ARoot: TOsRegRoot; const AKey: string;
                         AList: TStrings): Boolean;
var
  Reg: TRegistry;
begin
  AList.Clear;
  Reg := OsRegOpen(ARoot, AKey);
  Result := Reg <> nil;
  if not Result then
    Exit;
  try
    try
      Reg.GetValueNames(AList);
    except
      AList.Clear;
    end;
  finally
    Reg.Free;
  end;
end;

function OsRegValues(ARoot: TOsRegRoot; const AKey: string;
                     AList: TStrings): Boolean;
var
  Reg: TRegistry;
  Names: TStringList;
  NameIdx: Integer;
  Value: string;
begin
  AList.Clear;
  Reg := OsRegOpen(ARoot, AKey);
  Result := Reg <> nil;
  if not Result then
    Exit;
  Names := TStringList.Create;
  try
    try
      Reg.GetValueNames(Names);
    except
      Names.Clear;
    end;
    for NameIdx := 0 to Names.Count - 1 do
    begin
      if Names[NameIdx] = '' then
        Continue;
      try
        if Reg.GetDataType(Names[NameIdx]) in [rdString, rdExpandString] then
        begin
          Value := Reg.ReadString(Names[NameIdx]);
          AList.Add(Names[NameIdx] + '=' + Value);
        end;
      except
        // значение не прочиталось - пропускаем
      end;
    end;
  finally
    Names.Free;
    Reg.Free;
  end;
end;

{$ELSE}

function OsRegKeyExists(ARoot: TOsRegRoot; const AKey: string): Boolean;
begin
  Result := False;
end;

function OsRegReadString(ARoot: TOsRegRoot;
                         const AKey, AName: string): string;
begin
  Result := '';
end;

function OsRegSubKeys(ARoot: TOsRegRoot; const AKey: string;
                      AList: TStrings): Boolean;
begin
  AList.Clear;
  Result := False;
end;

function OsRegValueNames(ARoot: TOsRegRoot; const AKey: string;
                         AList: TStrings): Boolean;
begin
  AList.Clear;
  Result := False;
end;

function OsRegValues(ARoot: TOsRegRoot; const AKey: string;
                     AList: TStrings): Boolean;
begin
  AList.Clear;
  Result := False;
end;

{$ENDIF}

function OsRegReadAny(const AKey, AName: string): string;
begin
  Result := OsRegReadString(orUser, AKey, AName);
  if Result = '' then
    Result := OsRegReadString(orMachine, AKey, AName);
end;

function OsStoredEnvVar(const AName: string): string;
begin
  Result := '';
  if AName = '' then
    Exit;
  Result := OsRegReadString(orUser, 'Environment', AName);
  if Result = '' then
    Result := OsRegReadString(orMachine,
      'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', AName);
end;

end.
