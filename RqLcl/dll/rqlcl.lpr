// RqLcl: RapidQ components on top of LCL, as a DLL for FreeBASIC programs.
// See rqlclcore.pas and ../README.md.
library rqlcl;

{$mode objfpc}{$H+}

uses
  Interfaces, // LCL widgetset (win32)
  Forms,
  rqlclcore;

exports
  RqInit,
  RqDone,
  RqCreate,
  RqFree,
  RqSetInt,
  RqGetInt,
  RqSetStr,
  RqGetStr,
  RqSetObj,
  RqSetEvent,
  RqCall,
  RqCallInt,
  RqGetObj,
  RqGetHandle,
  RqGetItemStr,
  RqDoEvents,
  RqLastError;

begin
end.
