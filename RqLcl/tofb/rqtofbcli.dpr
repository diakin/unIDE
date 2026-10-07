// rqtofbcli - перевод программы RapidQ в FreeBASIC (модуль RqToFb).
//   rqtofbcli <главный.bas> <папка вывода> [smart|compat] [папки include через ;]
// Сообщения - в консоль, в конце строки APPTYPE=, OUT= и RC= (если есть
// $RESOURCE: файл .rc для fbc). Код завершения 1 -
// были ошибки.
program rqtofbcli;

{$APPTYPE CONSOLE}

uses
  SysUtils, Classes, RqToFb;

var
  Options: TRqFbOptions;
  ConvResult: TRqFbResult;
  Messages: TStringList;
  MsgIdx: Integer;
  Success: Boolean;

begin
  if ParamCount < 2 then
  begin
    Writeln('rqtofbcli <main.bas> <outdir> [smart|compat] [incdirs]');
    Halt(2);
  end;
  Options.Mode := rfmSmart;
  if (ParamCount >= 3) and (CompareText(ParamStr(3), 'compat') = 0) then
    Options.Mode := rfmCompat;
  Options.IncDirs := '';
  if ParamCount >= 4 then
    Options.IncDirs := ParamStr(4);
  Options.OutDir := ParamStr(2);
  Messages := TStringList.Create;
  try
    Success := RqToFbConvert(ParamStr(1), Options, Messages, ConvResult);
    for MsgIdx := 0 to Messages.Count - 1 do
      Writeln(Messages[MsgIdx]);
    Writeln('APPTYPE=', ConvResult.AppType);
    if ConvResult.Mode = rfmCompat then
      Writeln('MODE=COMPAT')
    else
      Writeln('MODE=SMART');
    Writeln('OUT=', ConvResult.MainOut);
    // ресурсы $RESOURCE: файл .rc - вторым файлом в командной строке fbc
    if ConvResult.ResourceFile <> '' then
      Writeln('RC=', ConvResult.ResourceFile);
    Writeln('ERRORS=', ConvResult.ErrorCount, ' WARNINGS=', ConvResult.WarningCount);
  finally
    Messages.Free;
  end;
  if not Success then
    Halt(1);
end.
