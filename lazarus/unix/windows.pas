// unIDE, сборка под Linux: модуль Windows из объявлений FPC RTL (wininc, genwin.py).
// Вызовы WinAPI ведут к символам unidewin_*, их реализует WinImpl.pas.
unit windows;
{$PACKSET 1}
{$mode objfpc}
{$modeswitch ADVANCEDRECORDS}
{$modeswitch class}
{$inline on}
{$calling stdcall}
interface
uses Types;
type SIZE_T = PtrUInt; PSIZE_T = ^SIZE_T;
{$define read_interface}
{$undef read_implementation}
{$i base.inc}
{$i errors.inc}
{$i defines.inc}
{$i struct.inc}
{$i messages.inc}
{$i ascfun.inc}
{$i unifun.inc}
{$i ascdef.inc}
{$i func.inc}
{$i redef.inc}

// Под Windows - переменные SysUtils; здесь значения Windows 7
var
  Win32Platform: Longint = VER_PLATFORM_WIN32_NT;
  Win32MajorVersion: Longint = 6;
  Win32MinorVersion: Longint = 1;
  Win32BuildNumber: Longint = 7601;
  Win32CSDVersion: string = '';

implementation
uses WinImpl;
{$undef read_interface}
{$define read_implementation}
{$i base.inc}
{$i errors.inc}
{$i defines.inc}
{$i struct.inc}
{$i messages.inc}
{$i ascfun.inc}
{$i unifun.inc}
{$i ascdef.inc}
{$i func.inc}
{$i redef.inc}
end.
