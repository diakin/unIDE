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
  FontRules =
    '<?xml version="1.0"?>' + LineEnding +
    '<!DOCTYPE fontconfig SYSTEM "fonts.dtd">' + LineEnding +
    '<fontconfig>' + LineEnding +
    ' <match target="pattern">' + LineEnding +
    '  <test name="family" qual="any"><string>Tahoma</string><string>MS Sans Serif</string>' +
    '<string>Microsoft Sans Serif</string><string>MS Shell Dlg</string><string>MS Shell Dlg 2</string>' +
    '<string>Segoe UI</string><string>Arial</string><string>Verdana</string></test>' + LineEnding +
    '  <edit name="family" mode="prepend" binding="strong"><string>Liberation Sans</string>' +
    '<string>Arimo</string><string>Nimbus Sans</string><string>FreeSans</string><string>DejaVu Sans</string></edit>' + LineEnding +
    ' </match>' + LineEnding +
    ' <match target="pattern">' + LineEnding +
    '  <test name="family" qual="any"><string>Courier New</string><string>Courier</string>' +
    '<string>Consolas</string><string>Lucida Console</string><string>Fixedsys</string></test>' + LineEnding +
    '  <edit name="family" mode="prepend" binding="strong"><string>Liberation Mono</string>' +
    '<string>Cousine</string><string>Nimbus Mono PS</string><string>FreeMono</string><string>DejaVu Sans Mono</string></edit>' + LineEnding +
    ' </match>' + LineEnding +
    '</fontconfig>' + LineEnding;

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
    ParseMemory(Config, PChar(FontRules), 1);
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
