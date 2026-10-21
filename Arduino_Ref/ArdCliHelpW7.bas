' =====================================================================
' ArdCliHelpW7.bas - окно Arduino Cli Help, версия для Windows 7
' (arduino-cli 0.18.1 ... 0.35.x).
'
' Список команд, подкоманд и флагов читается из вывода --help указанного
' arduino-cli.exe. Встроенный список - на случай, если --help ничего
' не вернул. Общая часть - ArdCliHelpCore.inc.
' =====================================================================
$APPTYPE GUI
$INCLUDE "RAPIDQ.INC"

DIM AchWaitLimitSec AS INTEGER
DIM AchWarnX64 AS INTEGER

AchProfileName$ = "Windows 7"
AchCfgName$ = "ArdCliHelpW7.cfg"
AchAutoArgs$ = ""
AchFallbackOrigin$ = "0.18.1, из RQdebugger853-8"
AchWaitLimitSec = 600
AchWarnX64 = 0

AchNotes$ = "Профиль: Windows 7" + CHR$(13) + CHR$(10) + _
	CHR$(13) + CHR$(10) + _
	"Go 1.21 и новее требуют Windows 10 (https://go.dev/doc/go1.21#ports)." + CHR$(13) + CHR$(10) + _
	CHR$(13) + CHR$(10) + _
	"На форуме Arduino пользователь сообщает, что на Windows 7 у него работала" + CHR$(13) + CHR$(10) + _
	"arduino-cli 0.35.2, а более новые версии завершались с исключением" + CHR$(13) + CHR$(10) + _
	"0xc0000005; новую версию он собрал через go-legacy-win7" + CHR$(13) + CHR$(10) + _
	"(https://forum.arduino.cc/t/arduino-cli-1-2-0-windows-7/1368165)." + CHR$(13) + CHR$(10) + _
	CHR$(13) + CHR$(10) + _
	"RQdebugger853-8 работает с arduino-cli 0.18.1." + CHR$(13) + CHR$(10) + _
	CHR$(13) + CHR$(10) + _
	"Глобальные флаги 0.35 по документации: --additional-urls, --config-file," + CHR$(13) + CHR$(10) + _
	"--format (text, json, jsonmini, yaml), --log, --log-file, --log-format," + CHR$(13) + CHR$(10) + _
	"--log-level, --no-color. В 0.35 есть команда monitor, в 0.18.1 её нет." + CHR$(13) + CHR$(10) + _
	CHR$(13) + CHR$(10) + _
	"Встроенный список команд и флагов (если --help ничего не вернул) -" + CHR$(13) + CHR$(10) + _
	"набор 0.18.1 из RQdebugger853-8." + CHR$(13) + CHR$(10) + _
	CHR$(13) + CHR$(10) + _
	"Предел ожидания одной команды - 600 с." + CHR$(13) + CHR$(10) + _
	"Временные файлы - в папке ArdCliHelpTmp рядом с exe окна."

$INCLUDE "ArdCliHelpCore.inc"

' --- встроенный список: 0.18.1 (RQdebugger853-8) ---
AchAddFallbackCmd "board", "Arduino board commands."
AchAddFallbackCmd "burn-bootloader", "Upload the bootloader."
AchAddFallbackCmd "cache", "Arduino cache commands."
AchAddFallbackCmd "compile", "Compiles Arduino sketches."
AchAddFallbackCmd "completion", "Generates completion scripts"
AchAddFallbackCmd "config", "Arduino configuration commands."
AchAddFallbackCmd "core", "Arduino core operations."
AchAddFallbackCmd "daemon", "Run as a daemon on port 50051"
AchAddFallbackCmd "debug", "Debug Arduino sketches."
AchAddFallbackCmd "help", "Help about any command"
AchAddFallbackCmd "lib", "Arduino commands about libraries."
AchAddFallbackCmd "outdated", "Lists cores and libraries that can be upgraded"
AchAddFallbackCmd "sketch", "Arduino CLI sketch commands."
AchAddFallbackCmd "update", "Updates the index of cores and libraries"
AchAddFallbackCmd "upgrade", "Upgrades installed cores and libraries."
AchAddFallbackCmd "upload", "Upload Arduino sketches."
AchAddFallbackCmd "version", "Shows version number of Arduino CLI."

AchAddFallbackFlag "--additional-urls strings   Comma-separated list of additional URLs for the Boards Manager."
AchAddFallbackFlag "--config-file string        The custom config file (if not specified the default will be used)."
AchAddFallbackFlag "--format string             The output format, can be {text|json}."
AchAddFallbackFlag "-h, --help                  help for arduino-cli"
AchAddFallbackFlag "--log-file string           Path to the file where logs will be written."
AchAddFallbackFlag "--log-format string         The output format for the logs, can be {text|json}."
AchAddFallbackFlag "--log-level string          Messages with this level and above will be logged."
AchAddFallbackFlag "-v, --verbose               Print the logs on the standard output."

AchForm.ShowModal
