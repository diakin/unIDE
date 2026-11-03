// unIDE, сборка для Linux: шрифты интерфейса.
// Формы unIDE рассчитаны на Tahoma 8 (высота 11 точек). В Linux этих шрифтов
// обычно нет, fontconfig подставляет первый попавшийся (здесь Inter, шире
// Tahoma), и подписи на кнопках обрезаются. Поэтому при запуске:
//  1) в fontconfig добавляются правила: Tahoma, MS Sans Serif, Segoe UI и
//     другие шрифты Windows -> Liberation Sans (метрики Arial, не шире
//     Tahoma), если его нет - Arimo, Nimbus Sans, FreeSans, DejaVu Sans;
//     Courier New/Consolas -> Liberation Mono и т.д.;
//  2) шрифт GTK по умолчанию (им рисуются элементы со шрифтом 'default':
//     в LCL это шрифт без явного Font в .dfm, в Delphi там MS Sans Serif 8)
//     = Tahoma 11 точек, то есть тот же шрифт, что и в формах.
// libfontconfig загружается динамически: без неё правила просто не ставятся.
unit UnixFonts;
{$mode delphi}{$H+}
interface

procedure UnixFontsSetup;

implementation

uses SysUtils, dynlibs{$IFDEF LCLGTK2}, gtk2{$ENDIF};

const
  // Семейства Windows через ; и замены для них (первая найденная)
  SansFamilies = 'Tahoma;MS Sans Serif;Microsoft Sans Serif;MS Shell Dlg;' +
                 'MS Shell Dlg 2;Segoe UI;Arial;Verdana';
  SansSubst = '<string>Liberation Sans</string><string>Arimo</string>' +
              '<string>Nimbus Sans</string><string>FreeSans</string>' +
              '<string>DejaVu Sans</string>';
  MonoFamilies = 'Courier New;Courier;Consolas;Lucida Console;Fixedsys';
  MonoSubst = '<string>Liberation Mono</string><string>Cousine</string>' +
              '<string>Nimbus Mono PS</string><string>FreeMono</string>' +
              '<string>DejaVu Sans Mono</string>';

// По правилу <match> на семейство: несколько значений в одном <test>
// fontconfig не поддерживает (предупреждение и проверка только первого)
function FamilyRules(const AFamilies, ASubst: string): string;
var
  Rest, Family: string;
  SepPos: Integer;
begin
  Result := '';
  Rest := AFamilies;
  while Rest <> '' do
  begin
    SepPos := Pos(';', Rest);
    if SepPos = 0 then
      SepPos := Length(Rest) + 1;
    Family := Copy(Rest, 1, SepPos - 1);
    Delete(Rest, 1, SepPos);
    Result := Result +
      ' <match target="pattern">' + LineEnding +
      '  <test name="family" qual="any"><string>' + Family + '</string></test>' + LineEnding +
      '  <edit name="family" mode="prepend" binding="strong">' + ASubst + '</edit>' + LineEnding +
      ' </match>' + LineEnding;
  end;
end;

function FontRules: string;
begin
  Result :=
    '<?xml version="1.0"?>' + LineEnding +
    '<!DOCTYPE fontconfig SYSTEM "fonts.dtd">' + LineEnding +
    '<fontconfig>' + LineEnding +
    FamilyRules(SansFamilies, SansSubst) +
    FamilyRules(MonoFamilies, MonoSubst) +
    '</fontconfig>' + LineEnding;
end;

type
  TFcConfigGetCurrent = function: Pointer; cdecl;
  TFcConfigParseAndLoadFromMemory = function(AConfig: Pointer; AText: PChar; AComplain: LongInt): LongInt; cdecl;

var
  FontsDone: Boolean = False;

procedure AddFontRules;
var
  LibHandle: TLibHandle;
  GetCurrent: TFcConfigGetCurrent;
  ParseMemory: TFcConfigParseAndLoadFromMemory;
  Config: Pointer;
begin
  LibHandle := LoadLibrary('libfontconfig.so.1');
  if LibHandle = NilHandle then
    LibHandle := LoadLibrary('libfontconfig.so');
  if LibHandle = NilHandle then
    Exit;
  // библиотеку не выгружаем: её же использует GTK/Pango
  GetCurrent := TFcConfigGetCurrent(GetProcedureAddress(LibHandle, 'FcConfigGetCurrent'));
  ParseMemory := TFcConfigParseAndLoadFromMemory(GetProcedureAddress(LibHandle, 'FcConfigParseAndLoadFromMemory'));
  if (@GetCurrent = nil) or (@ParseMemory = nil) then
    Exit; // fontconfig старше 2.12
  Config := GetCurrent();
  if Config <> nil then
    ParseMemory(Config, PChar(FontRules()), 1);
end;

procedure UnixFontsSetup;
begin
  if FontsDone then
    Exit;
  FontsDone := True;
  if SysUtils.GetEnvironmentVariable('UNIDE_SYSTEM_FONTS') = '1' then
    Exit; // для проверки: шрифты как в системе
  AddFontRules;
  {$IFDEF LCLGTK2}
  gtk_settings_set_string_property(gtk_settings_get_default, 'gtk-font-name', 'Tahoma 11px', 'unide');
  {$ENDIF}
end;

initialization
  UnixFontsSetup;
end.
