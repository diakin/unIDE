# ReactOS: Run в своём QEMU unIDE (22.10.2026)

Коммит `aadf16a`, ветка mainTest. Код: `QemuTool.pas`, `SzSetup.pas` (общая установка), `Unit1.pas` (`RosRunImage`, `RosEnsureQemu`, `RosSetupQemu`, `RosStartEmulator`, `RosInstallQemuClick`), `RosProj.pas` (`RunCommand`), `DlgNewPrj.pas` (поле «Запуск (Run)»).

## Какой QEMU и почему

- Сборки QEMU для Windows — qemu.weilnetz.de (Stefan Weil). Проверены таблицы импорта `qemu-system-i386.exe` и всех его DLL.
- 7.1, 7.2, 8.0, 8.2, 9.0, 9.2: `qemu-system-i386.exe` импортирует `PathCchSkipRoot` из `api-ms-win-core-path-l1-1-0.dll` — в Windows 7 этой DLL нет, программа не запустится.
- **7.0.0** (2022-04-19, w64 и w32): этого импорта нет, других функций новее Windows 7 не найдено. SHA-512 установщиков совпали с опубликованными (`.sha512` рядом на сайте).
- Проверка по импорту показывает, что программа загрузится; работу на Windows 7 покажет только запуск.
- Сборка: w64 на 64-битной Windows x64, w32 — на 32-битной и ARM64; Windows 7 и новее.

| Файл | Размер | SHA-256 |
|---|---|---|
| qemu-w64-setup-20220419.exe | 132 732 320 | 410c674d87a28760cc90a3c1bf0b7cb8bf5d2e4253a8f9e07b218d2bc7300af3 |
| qemu-w32-setup-20220419.exe | 139 283 976 | 69dd281848108162496a60f19608ece2ac7940e0a3f8516d7ff417996c3645c3 |

## Установка (как свой 7-Zip)

- Папка: `<exe>\tools\qemu\`, если туда не записать — `%LOCALAPPDATA%\unIDE\tools\qemu\`.
- Установщик NSIS не запускается: свой 7-Zip достаёт `qemu-system-i386.exe`, `qemu-system-i386w.exe`, `qemu-img.exe`, все DLL, прошивки x86 (`share\bios*`, `vgabios*`, `efi-*.rom`, `pxe-*.rom` …), `share\keymaps`, `share\icons`, `lib`, лицензии — около 120 МБ из 1,3 ГБ. Папка заменяется целиком; рядом — `unide_qemu.txt`.
- Нет своего 7-Zip — ставится первым.
- Драйверов и ускорителей (HAXM, WHPX) нет — процессор эмулируется программно (TCG): медленнее, но QEMU — обычная программа, системы не касается.
- Вызов: первый Run проекта ReactOS (вопрос 9813) или меню ReactOS → Install QEMU 7.0.0 (tools\qemu).
- `SzSetup`: установка по плану `TSzPlan` (что скачать, чем распаковать, что достать, перенос по файлам или папкой целиком) — общий поток `TSzInstall` для 7-Zip и QEMU; две установки сразу не идут.

## Run проекта ReactOS

- Образ: `<папка сборки>\<цель>.iso`, иначе `.img`, `.vhd`. Нет — сообщение «соберите проект».
- Своя команда (свойства проекта → «Запуск (Run)», `ReactOS_RunCommand`): подстановки `%ISO%` / `%IMAGE%`, `%BUILDDIR%`, `%SOURCEDIR%`, `%SERIAL%`, `%QEMU%` (свой QEMU, ставится при надобности). Пусто — свой QEMU.
- Свой QEMU: `qemu-system-i386w.exe -name "ReactOS (<цель>)" -m 1024 (512 на 32-битной Windows) -rtc base=localtime -vga std -netdev user,id=net0 -device ne2k_pci,netdev=net0`, для `.iso` — диск `unide-qemu\hdd.qcow2` (8 ГБ, создаёт `qemu-img`, один раз) на IDE 0, ISO — CD-ROM на IDE 2, `-boot d`; `.vhd` / `.img` — жёсткий диск, `-boot c`; COM1 — `unide-qemu\serial.log` (отладочный вывод ReactOS KDSERIAL). Запятые в путях удваиваются.
- Вывод QEMU — `unide-qemu\qemu.log`; закрылся в первые 3 с — код и начало журнала в лог. Второй запуск, пока работает прежний, не делается (тот же диск).
- Проверено: QEMU 8.2 под Linux с ReactOS 0.4.15 bootcd — с теми же параметрами (и путём с пробелом и запятой) доходит до окна установки, COM1 пишется. На Windows 7 с QEMU 7.0.0 не проверялось.
