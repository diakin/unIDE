' =====================================================================
' ArdCliHelpLatest.bas - окно Arduino Cli Help для последней версии
' arduino-cli (1.5.x на 2026-10-08).
'
' Список команд, подкоманд и флагов читается из вывода --help указанного
' arduino-cli.exe. Встроенный список - на случай, если --help ничего
' не вернул. К каждой команде добавляется --no-color.
' Общая часть - ArdCliHelpCore.inc.
' =====================================================================
$APPTYPE GUI
$INCLUDE "RAPIDQ.INC"

DIM AchWaitLimitSec AS INTEGER
DIM AchWarnX64 AS INTEGER

AchProfileName$ = "arduino-cli 1.5"
AchCfgName$ = "ArdCliHelpLatest.cfg"
AchAutoArgs$ = " --no-color"
AchFallbackOrigin$ = "1.5, по документации arduino-cli"
AchWaitLimitSec = 600
AchWarnX64 = 0

AchNotes$ = "Профиль: последняя версия arduino-cli" + CHR$(13) + CHR$(10) + _
	CHR$(13) + CHR$(10) + _
	"Последний выпуск на 2026-10-08 - v1.5.1 от 5 июня 2026" + CHR$(13) + CHR$(10) + _
	"(https://github.com/arduino/arduino-cli/releases)." + CHR$(13) + CHR$(10) + _
	CHR$(13) + CHR$(10) + _
	"В 1.5.0-rc.1 проект переведён на Go 1.26+, а Go 1.21 и новее требуют" + CHR$(13) + CHR$(10) + _
	"Windows 10 (https://go.dev/doc/go1.21#ports). Официальные сборки 1.5.x" + CHR$(13) + CHR$(10) + _
	"рассчитаны на Windows 10 и новее." + CHR$(13) + CHR$(10) + _
	CHR$(13) + CHR$(10) + _
	"Отличия от 0.18.1 / 0.35, которые касаются этого окна:" + CHR$(13) + CHR$(10) + _
	"  - вместо --format используется --json;" + CHR$(13) + CHR$(10) + _
	"  - добавлены флаги --config-dir, --log, --no-color;" + CHR$(13) + CHR$(10) + _
	"  - добавлены команды monitor и profile, у config - get." + CHR$(13) + CHR$(10) + _
	CHR$(13) + CHR$(10) + _
	"К каждой команде добавляется --no-color, чтобы в выводе не было" + CHR$(13) + CHR$(10) + _
	"цветовых escape-последовательностей (они также удаляются при разборе)." + CHR$(13) + CHR$(10) + _
	CHR$(13) + CHR$(10) + _
	"Встроенный список команд и флагов - по документации 1.5" + CHR$(13) + CHR$(10) + _
	"(https://arduino.github.io/arduino-cli/1.5/commands/arduino-cli/)." + CHR$(13) + CHR$(10) + _
	CHR$(13) + CHR$(10) + _
	"Предел ожидания одной команды - 600 с." + CHR$(13) + CHR$(10) + _
	"Временные файлы - в папке ArdCliHelpTmp рядом с exe окна."

$INCLUDE "ArdCliHelpCore.inc"

' --- встроенный список: документация arduino-cli 1.5 ---
AchAddFallbackCmd "board", "Arduino board commands."
AchAddFallbackCmd "burn-bootloader", "Upload the bootloader."
AchAddFallbackCmd "cache", "Arduino cache commands."
AchAddFallbackCmd "compile", "Compiles Arduino sketches."
AchAddFallbackCmd "completion", "Generates completion scripts"
AchAddFallbackCmd "config", "Arduino configuration commands."
AchAddFallbackCmd "core", "Arduino core operations."
AchAddFallbackCmd "daemon", "Run the Arduino CLI as a gRPC daemon."
AchAddFallbackCmd "debug", "Debug Arduino sketches."
AchAddFallbackCmd "help", "Help about any command"
AchAddFallbackCmd "lib", "Arduino commands about libraries."
AchAddFallbackCmd "monitor", "Open a communication port with a board."
AchAddFallbackCmd "outdated", "Lists cores and libraries that can be upgraded"
AchAddFallbackCmd "profile", "Build profile operations."
AchAddFallbackCmd "sketch", "Arduino CLI sketch commands."
AchAddFallbackCmd "update", "Updates the index of cores and libraries"
AchAddFallbackCmd "upgrade", "Upgrades installed cores and libraries."
AchAddFallbackCmd "upload", "Upload Arduino sketches."
AchAddFallbackCmd "version", "Shows version number of Arduino CLI."

AchAddFallbackFlag "--additional-urls strings   Comma-separated list of additional URLs for the Boards Manager."
AchAddFallbackFlag "--config-dir string         Sets the default data directory."
AchAddFallbackFlag "--config-file string        The custom config file (if not specified the default will be used)."
AchAddFallbackFlag "-h, --help                  help for arduino-cli"
AchAddFallbackFlag "--json                      Print the output in JSON format."
AchAddFallbackFlag "--log                       Print the logs on the standard output."
AchAddFallbackFlag "--log-file string           Path to the file where logs will be written."
AchAddFallbackFlag "--log-format string         The output format for the logs, can be: text, json"
AchAddFallbackFlag "--log-level string          Messages with this level and above will be logged."
AchAddFallbackFlag "--no-color                  Disable colored output."

AchForm.ShowModal
