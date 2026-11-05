@echo off
rem ArdSim: builds an Arduino sketch (.ino) as a Windows program.
rem Usage: build_sim.cmd path\to\sketch.ino [mingw_bin_folder]
rem MinGW: the second argument, %ARDSIM_MINGW%, the unIDE tools\mingw
rem (Arduino menu - Install MinGW-w64) or g++ on PATH.
rem Fonts: *.c in the sketch folder, %ARDSIM_FONTS% (a folder) and the
rem files listed in ardsim_build\ardsim_fonts.txt (unIDE writes it before
rem the build: .c from the libraries folders that define the fonts the
rem sketch declares extern). Without that list (build from the command
rem line) - Documents\Arduino\libraries\UTFT\DefaultFonts.c. Fonts not found
rem are taken from ArdSim\fonts (stand-ins: the size is right, the look is not).
rem Result: <sketch folder>\ardsim_build\<sketch>_sim.exe
setlocal enabledelayedexpansion

set SIMDIR=%~dp0
set SIMDIR=%SIMDIR:~0,-1%
if "%~1"=="" (
  echo usage: build_sim.cmd sketch.ino [mingw_bin_folder]
  exit /b 2
)
set SKETCH=%~f1
set SKETCHDIR=%~dp1
set SKETCHDIR=%SKETCHDIR:~0,-1%
set SKETCHNAME=%~n1
set OUTDIR=%SKETCHDIR%\ardsim_build
set OBJDIR=%OUTDIR%\obj

rem ---- find g++
set GXX=
if not "%~2"=="" call :try_gxx "%~2"
if "%GXX%"=="" if not "%ARDSIM_MINGW%"=="" call :try_gxx "%ARDSIM_MINGW%"
if "%GXX%"=="" if not "%ARDSIM_MINGW%"=="" call :try_gxx "%ARDSIM_MINGW%\bin"
if "%GXX%"=="" call :try_gxx "%SIMDIR%\..\Output\tools\mingw\bin"
if "%GXX%"=="" call :try_gxx "%SIMDIR%\..\tools\mingw\bin"
if "%GXX%"=="" call :try_gxx "%LOCALAPPDATA%\unIDE\tools\mingw\bin"
if "%GXX%"=="" for %%G in (x86_64-w64-mingw32-g++.exe g++.exe) do if "!GXX!"=="" if not "%%~$PATH:G"=="" set GXX=%%~$PATH:G
if "%GXX%"=="" (
  echo ArdSim: MinGW g++ not found. Install it in unIDE: Arduino - Install MinGW-w64,
  echo or pass the folder with g++.exe as the second argument.
  exit /b 1
)
for %%G in ("%GXX%") do set GXXDIR=%%~dpG
set GCC=%GXXDIR%x86_64-w64-mingw32-gcc.exe
if not exist "%GCC%" set GCC=%GXXDIR%gcc.exe
set AR=%GXXDIR%ar.exe
if not exist "%AR%" set AR=%GXXDIR%x86_64-w64-mingw32-ar.exe
set PATH=%GXXDIR%;%PATH%
echo ArdSim: g++ = %GXX%

if not exist "%OBJDIR%\fonts" mkdir "%OBJDIR%\fonts"

rem ---- ardprep (once; the number changes with ardprep.cpp - then built again)
set ARDPREP=%SIMDIR%\tools\ardprep2.exe
if not exist "%ARDPREP%" (
  echo ArdSim: building ardprep
  "%GXX%" -std=gnu++17 -O1 -static -o "%ARDPREP%" "%SIMDIR%\tools\ardprep.cpp"
  if errorlevel 1 exit /b 1
)

rem ---- simulator runtime (always, a few seconds)
set CXXFLAGS=-std=gnu++17 -O0 -g -I"%SIMDIR%\include"
set RTOBJS=
pushd "%SIMDIR%\src"
for %%F in (*.cpp) do (
  echo   %%F
  "%GXX%" %CXXFLAGS% -c "%%F" -o "%OBJDIR%\%%~nF.o"
  if errorlevel 1 (popd & exit /b 1)
  set RTOBJS=!RTOBJS! "%OBJDIR%\%%~nF.o"
)
popd

rem ---- stand-in fonts (every build: a second or two; fonts\*.c may change)
if exist "%OBJDIR%\libardsim_fonts.a" del "%OBJDIR%\libardsim_fonts.a"
if not exist "%OBJDIR%\libardsim_fonts.a" (
  echo   stand-in fonts
  set STANDINOBJS=
  pushd "%SIMDIR%\fonts"
  for %%F in (*.c) do (
    "%GCC%" -O1 -c "%%F" -o "%OBJDIR%\fonts\%%~nF.o"
    if errorlevel 1 (popd & exit /b 1)
    set STANDINOBJS=!STANDINOBJS! "%OBJDIR%\fonts\%%~nF.o"
  )
  popd
  "%AR%" rcs "%OBJDIR%\libardsim_fonts.a" !STANDINOBJS!
  if errorlevel 1 exit /b 1
)

rem ---- user fonts (UTFT .c files)
set FONTOBJS=
set FONTFLAGS=-O1 -D__arm__ -I"%SIMDIR%\include"
pushd "%SKETCHDIR%"
for %%F in (*.c) do (
  echo   font %%F
  "%GCC%" %FONTFLAGS% -c "%%F" -o "%OBJDIR%\user_%%~nF.o"
  if errorlevel 1 (popd & exit /b 1)
  set FONTOBJS=!FONTOBJS! "%OBJDIR%\user_%%~nF.o"
)
popd
if not "%ARDSIM_FONTS%"=="" (
  pushd "%ARDSIM_FONTS%"
  for %%F in (*.c) do (
    echo   font %ARDSIM_FONTS%\%%F
    "%GCC%" %FONTFLAGS% -c "%%F" -o "%OBJDIR%\userlib_%%~nF.o"
    if errorlevel 1 (popd & exit /b 1)
    set FONTOBJS=!FONTOBJS! "%OBJDIR%\userlib_%%~nF.o"
  )
  popd
)
rem unIDE list: fonts from the libraries folders. The number in the object
rem name: two libraries may have files with the same name
set FONTLIST=%OUTDIR%\ardsim_fonts.txt
set FONTNUM=0
if exist "%FONTLIST%" (
  for /f "usebackq delims=" %%F in ("%FONTLIST%") do (
    set /a FONTNUM+=1
    echo   font %%F
    "%GCC%" %FONTFLAGS% -c "%%F" -o "%OBJDIR%\lib!FONTNUM!_%%~nF.o"
    if errorlevel 1 exit /b 1
    set FONTOBJS=!FONTOBJS! "%OBJDIR%\lib!FONTNUM!_%%~nF.o"
  )
)
if not exist "%FONTLIST%" if "%ARDSIM_FONTS%"=="" (
  set UTFTFONTS=%USERPROFILE%\Documents\Arduino\libraries\UTFT\DefaultFonts.c
  if exist "!UTFTFONTS!" (
    echo   font !UTFTFONTS!
    "%GCC%" %FONTFLAGS% -c "!UTFTFONTS!" -o "%OBJDIR%\utft_DefaultFonts.o"
    if errorlevel 1 exit /b 1
    set FONTOBJS=!FONTOBJS! "%OBJDIR%\utft_DefaultFonts.o"
  )
)

rem ---- the sketch
"%ARDPREP%" "%SKETCH%" "%OBJDIR%\%SKETCHNAME%_sim.cpp"
if errorlevel 1 exit /b 1
echo   %SKETCHNAME%.ino
"%GXX%" %CXXFLAGS% -Wno-write-strings -I"%SKETCHDIR%" -c "%OBJDIR%\%SKETCHNAME%_sim.cpp" -o "%OBJDIR%\%SKETCHNAME%_sim.o"
if errorlevel 1 exit /b 1

set EXE=%OUTDIR%\%SKETCHNAME%_sim.exe
"%GXX%" -mwindows -static -o "%EXE%" "%OBJDIR%\%SKETCHNAME%_sim.o" %RTOBJS% %FONTOBJS% -L"%OBJDIR%" -lardsim_fonts -lgdi32 -lwinmm
if errorlevel 1 exit /b 1
echo ArdSim: %EXE%
if /i "%ARDSIM_RUN%"=="1" start "" "%EXE%"
exit /b 0

:try_gxx
if exist "%~1\x86_64-w64-mingw32-g++.exe" (
  set GXX=%~f1\x86_64-w64-mingw32-g++.exe
  goto :eof
)
if exist "%~1\g++.exe" set GXX=%~f1\g++.exe
goto :eof
