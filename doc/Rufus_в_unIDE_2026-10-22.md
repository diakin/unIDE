# Rufus в unIDE (2026-10-22, mainTest 80a8ddb)

## Меню ReactOS
- **Write Image to USB (Rufus)...** — окно выбора образа (*.iso, *.img, *.vhd, *.vhdx); если открыт проект ReactOS и собран `<папка сборки>\<цель>.iso` (.img, .vhd) — он выбран заранее. Затем `rufusp.exe -g -i "<образ>"` через ShellExecuteW: Rufus требует прав администратора, Windows покажет запрос UAC. Флешку и запись выбирают в окне Rufus. Отказ UAC — сообщение в Compilation log.
- **Install Rufus (tools\rufus)...** — свой Rufus уже есть: путь и строка из `unide_rufus.txt` в журнал (переустановка — удалить папку). Нет — установка.

## Где и какой
- `<папка exe>\tools\rufus\rufusp.exe`, запасной вариант — `%LOCALAPPDATA%\unIDE\tools\rufus\`. Имя с 'p' — переносимый режим Rufus: настройки в `rufus.ini` рядом, не в реестре.
- Выбор сборки (RufusChoosePackage):
  - Windows 8+: официальный Rufus 4.15 — x64 (`rufus-4.15.exe`, 1989992, sha256 84c8a437…be106), x86 (`rufus-4.15_x86.exe`, 1933672, 20e13457…19576), ARM64 (`rufus-4.15_arm64.exe`, 5491048, af01a213…35c1c). Подписаны Akeo Consulting. Качаются как есть, сохраняются как rufusp.exe.
  - Windows 7 с KB2533623 (есть SetDefaultDllDirectories в kernel32): форк Alex313031 4.6.2208, zip x64 / x32 (суммы — в ревью). Из zip свой 7-Zip достаёт только rufusp.exe; если своего 7-Zip нет — он ставится первым.
  - Windows 7 без KB2533623: официальный 3.22 (`rufus-3.22.exe`, 1419336, ac2a1743…5f433), x86.
  - Vista и старше: нет.
- В официальных выпусках `rufus-X.exe` и `rufus-Xp.exe` побайтно одинаковы — переносимость определяется только по 'p' в имени (rufus.c).

## SzSetup
- `TSzPlan.Archive = -1` — без распаковки: MoveNames переносятся из папки загрузок.
- `TSzPlan.ExtractSubDir` — переносить из подпапки распакованного архива. В Sz7ZipPlan, QemuPlan, GitPlan присваивается '' явно (результат-запись функции в Delphi может прийти с прежними значениями).

## Проверено
- FPC-проверка RufusTool/SzSetup/QemuTool/GitTool и тест выбора сборки для Win10 x64/x86, Win11 ARM64, Win8, Win7 с KB и без, Vista, XP.
- Unit1 в FPC не проверяется (VCL) — проверка компиляцией в Delphi 7.
