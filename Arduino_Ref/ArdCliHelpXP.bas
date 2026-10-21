' =====================================================================
' ArdCliHelpXP.bas - окно Arduino Cli Help, версия для Windows XP
' (в дальнейшем ReactOS).
'
' Список команд, подкоманд и флагов читается из вывода --help того
' arduino-cli.exe, который указан в поле пути, поэтому окно не привязано
' к версии CLI. Встроенный список нужен только на случай, если --help
' ничего не вернул.
' Общая часть - ArdCliHelpCore.inc.
' =====================================================================
$APPTYPE GUI
$INCLUDE "RAPIDQ.INC"

DIM AchWaitLimitSec AS INTEGER
DIM AchWarnX64 AS INTEGER

AchProfileName$ = "Windows XP / ReactOS"
AchCfgName$ = "ArdCliHelpXP.cfg"
AchAutoArgs$ = ""
AchFallbackOrigin$ = "0.18.1, из RQdebugger853-8"
AchWaitLimitSec = 900
AchWarnX64 = 1

AchNotes$ = "Профиль: Windows XP / ReactOS" + CHR$(13) + CHR$(10) + _
	CHR$(13) + CHR$(10) + _
	"Arduino CLI написан на Go. По заметкам к выпуску Go 1.10 это последняя" + CHR$(13) + CHR$(10) + _
	"версия Go, работающая на Windows XP; с Go 1.11 нужна Windows 7 или новее" + CHR$(13) + CHR$(10) + _
	"(https://go.dev/doc/go1.10#ports)." + CHR$(13) + CHR$(10) + _
	CHR$(13) + CHR$(10) + _
	"Какая версия arduino-cli работает на XP, не проверено. Окно не привязано" + CHR$(13) + CHR$(10) + _
	"к версии: команды, подкоманды и флаги читаются из --help указанного exe." + CHR$(13) + CHR$(10) + _
	CHR$(13) + CHR$(10) + _
	"Разрядность exe (x86 / x64) показана в заголовке окна. 64-разрядный exe" + CHR$(13) + CHR$(10) + _
	"на 32-разрядной Windows XP не запускается." + CHR$(13) + CHR$(10) + _
	CHR$(13) + CHR$(10) + _
	"Встроенный список команд и флагов (если --help ничего не вернул) -" + CHR$(13) + CHR$(10) + _
	"набор 0.18.1 из RQdebugger853-8." + CHR$(13) + CHR$(10) + _
	CHR$(13) + CHR$(10) + _
	"Предел ожидания одной команды - 900 с." + CHR$(13) + CHR$(10) + _
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
