unit IniCp;

// ---------------------------------------------------------------------------
//  Ini-файлы unIDE (editor.ini, файлы проектов) - в кодировке Windows
//  (CP1251): их пишет и сборка Delphi 7, и они лежат в git как
//  windows-1251. В сборке Lazarus строки - UTF-8, и путь с кириллицей,
//  прочитанный как есть, не находился (FileExists) и показывался "?".
//
//  Модуль подключается ПОСЛЕ IniFiles: его TIniFile и TMemIniFile
//  закрывают одноимённые классы IniFiles. Под FPC они переводят значения
//  при чтении (CP_ACP -> UTF-8; значение, которое уже в UTF-8, - как есть)
//  и при записи (UTF-8 -> CP_ACP). Ключи и имена разделов не переводятся.
//  В Delphi 7 - те же классы IniFiles без изменений.
// ---------------------------------------------------------------------------

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  Classes, IniFiles;

type
{$IFDEF FPC}
  TIniFile = class(IniFiles.TIniFile)
  public
    function ReadString(const Section, Ident, Default: string): string; override;
    procedure WriteString(const Section, Ident, Value: string); override;
    procedure ReadSectionValues(const Section: string; Strings: TStrings;
      AOptions: TSectionValuesOptions = [svoIncludeInvalid]); overload; override;
  end;

  TMemIniFile = class(IniFiles.TMemIniFile)
  public
    function ReadString(const Section, Ident, Default: string): string; override;
    procedure WriteString(const Section, Ident, Value: string); override;
    procedure ReadSectionValues(const Section: string; Strings: TStrings;
      AOptions: TSectionValuesOptions = [svoIncludeInvalid]); overload; override;
  end;
{$ELSE}
  TIniFile = IniFiles.TIniFile;
  TMemIniFile = IniFiles.TMemIniFile;
{$ENDIF}

// Значение из файла (CP1251) - в строку программы и обратно. В Delphi 7 -
// как есть
function IniFileToText(const AValue: string): string;
function IniTextToFile(const AValue: string): string;

implementation

uses
  EdScheme, LazPrep;

function HasHighBytes(const AValue: string): Boolean;
var
  CharIdx: Integer;
begin
  Result := False;
  for CharIdx := 1 to Length(AValue) do
    if Ord(AValue[CharIdx]) >= $80 then
    begin
      Result := True;
      Exit;
    end;
end;

function IniFileToText(const AValue: string): string;
begin
  Result := AValue;
  {$IFDEF FPC}
  // Уже UTF-8 (записано прежней сборкой Lazarus) - не переводить второй раз
  if HasHighBytes(AValue) and not LooksUtf8(AValue) then
    Result := EdUiText(AValue);
  {$ENDIF}
end;

function IniTextToFile(const AValue: string): string;
begin
  Result := AValue;
  {$IFDEF FPC}
  if HasHighBytes(AValue) and LooksUtf8(AValue) then
    Result := EdAnsiText(UTF8Decode(AValue));
  {$ENDIF}
end;

{$IFDEF FPC}
procedure ValuesToText(Strings: TStrings);
var
  LineIdx: Integer;
begin
  for LineIdx := 0 to Strings.Count - 1 do
    if HasHighBytes(Strings[LineIdx]) then
      Strings[LineIdx] := IniFileToText(Strings[LineIdx]);
end;

{ TIniFile }

function TIniFile.ReadString(const Section, Ident, Default: string): string;
begin
  Result := inherited ReadString(Section, Ident, #1);
  if Result = #1 then
    Result := Default
  else
    Result := IniFileToText(Result);
end;

procedure TIniFile.WriteString(const Section, Ident, Value: string);
begin
  inherited WriteString(Section, Ident, IniTextToFile(Value));
end;

procedure TIniFile.ReadSectionValues(const Section: string; Strings: TStrings;
  AOptions: TSectionValuesOptions);
begin
  inherited ReadSectionValues(Section, Strings, AOptions);
  ValuesToText(Strings);
end;

{ TMemIniFile }

function TMemIniFile.ReadString(const Section, Ident, Default: string): string;
begin
  Result := inherited ReadString(Section, Ident, #1);
  if Result = #1 then
    Result := Default
  else
    Result := IniFileToText(Result);
end;

procedure TMemIniFile.WriteString(const Section, Ident, Value: string);
begin
  inherited WriteString(Section, Ident, IniTextToFile(Value));
end;

procedure TMemIniFile.ReadSectionValues(const Section: string; Strings: TStrings;
  AOptions: TSectionValuesOptions);
begin
  inherited ReadSectionValues(Section, Strings, AOptions);
  ValuesToText(Strings);
end;
{$ENDIF}

end.
