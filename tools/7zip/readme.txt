unIDE FAR - 7-Zip для работы с архивами
=======================================

Свой 7-Zip unIDE: отсюда 7z.exe вызывают unIDE FAR (просмотр, распаковка и
упаковка архивов) и меню ReactOS (Install RosBE - распаковка установщика
RosBE). Установленный в системе 7-Zip не используется и не меняется.

Где unIDE ищет 7-Zip (SzSetup.pas): tools\7zip рядом с exe, затем
%LOCALAPPDATA%\unIDE\tools\7zip. Нет 7z.exe и 7z.dll - unIDE предлагает
скачать 7-Zip сам: сборка x64 на 64-битной Windows, x86 на 32-битной; из
официального установщика берутся только 7z.exe, 7z.dll, License.txt, сам
установщик не запускается, права администратора не нужны. Если в папку у exe
не записать, 7-Zip ставится в профиль пользователя. Обновить или поставить
заново - меню ReactOS - Install 7-Zip.

Версия:   7-Zip 26.04 (2026-10-05), x86 (32-бит), работает в Windows 7 и XP
Источник: https://github.com/ip7z/7zip/releases/download/26.04/7z2604.exe
          (официальный установщик, файлы извлечены из него без изменений)
SHA-256:  7z2604.exe 39bf65045153fc26c42fa9fe47afd8cd1b11671c7f11d031e738c9a13960c009
          7z.exe     684955b4978fdbace051ffd55edab90d180b7cb4d208f943998866727d8d6c13
          7z.dll     4a796dd5993c7e1188da7610f0d81972cb21b82f28a7c9fb24015ec46b2c0308

Лицензия: GNU LGPL; часть кода - BSD 3-clause и BSD 2-clause; ограничение
unRAR (код распаковки RAR нельзя использовать для создания архиватора RAR).
Полный текст - License.txt. Сайт: https://www.7-zip.org

Обновление: скачать новый установщик x86 с 7-zip.org или с GitHub ip7z/7zip,
извлечь из него 7z.exe и 7z.dll (7z.exe x 7zXXXX.exe 7z.exe 7z.dll) и
заменить файлы здесь.
