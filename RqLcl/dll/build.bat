@echo off
rem Build rqlcl32.dll or rqlcl64.dll from rqlcl.lpr with the FPC that comes
rem with Lazarus. LCL and LazUtils are compiled from the Lazarus sources.
rem
rem   build.bat 32   - rqlcl32.dll (needs ppc386.exe: 32-bit Lazarus or the
rem                    i386-win32 cross add-on for 64-bit Lazarus)
rem   build.bat 64   - rqlcl64.dll (ppcx64.exe)
rem
rem Set LAZDIR and FPCVER below to your Lazarus installation.
rem fpc.cfg is not used (-n): it lists every FPC package, and the "menus"
rem unit of Free Vision would hide the LCL one.

set LAZDIR=C:\lazarus
set FPCVER=3.2.2

if "%1"=="32" goto win32
if "%1"=="64" goto win64
echo Usage: build.bat 32 or build.bat 64
goto end

:win32
set TARGET=i386-win32
set PPC=%LAZDIR%\fpc\%FPCVER%\bin\i386-win32\ppc386.exe
if not exist "%PPC%" set PPC=%LAZDIR%\fpc\%FPCVER%\bin\x86_64-win64\ppcross386.exe
set OPTS=-Twin32 -Pi386
set SUFFIX=32
goto build

:win64
set TARGET=x86_64-win64
set PPC=%LAZDIR%\fpc\%FPCVER%\bin\x86_64-win64\ppcx64.exe
set OPTS=-Twin64 -Px86_64
set SUFFIX=64
goto build

:build
if not exist "%PPC%" (
  echo Compiler not found: %PPC%
  goto end
)
set UNITS=%LAZDIR%\fpc\%FPCVER%\units\%TARGET%
set OUT=%~dp0out\%TARGET%
if not exist "%OUT%\units" mkdir "%OUT%\units"
set FU=
for %%P in (rtl rtl-objpas rtl-extra rtl-unicode rtl-generics rtl-console fcl-base fcl-image fcl-res fcl-xml fcl-registry fcl-process fcl-extra fcl-json chm pasjpeg paszlib hash winunits-base winunits-jedi regexpr) do call set FU=%%FU%% -Fu"%UNITS%\%%P"

"%PPC%" -n %OPTS% -Mobjfpc -Scghi -O2 -XX -Xs -CX -WG %FU% ^
  -Fu"%LAZDIR%\components\lazutils" -Fi"%LAZDIR%\components\lazutils" ^
  -Fu"%LAZDIR%\lcl" -Fi"%LAZDIR%\lcl\include" -Fu"%LAZDIR%\lcl\widgetset" ^
  -Fu"%LAZDIR%\lcl\interfaces\win32" -Fi"%LAZDIR%\lcl\interfaces\win32" ^
  -Fu"%LAZDIR%\lcl\forms" -Fu"%LAZDIR%\components\freetype" ^
  -dLCL -dLCLwin32 -dDisableUTF8RTL ^
  -FU"%OUT%\units" -FE"%OUT%" -o"%~dp0..\bin\rqlcl%SUFFIX%.dll" ^
  "%~dp0rqlcl.lpr"

:end
pause
