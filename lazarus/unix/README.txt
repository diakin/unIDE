unIDE: сборка под Linux (gtk2), этап 3.1 плана переноса

Модули-заменители WinAPI (только для Linux, в путях режима Linux64 в
lazarus/SyntaxHLClaude.lpi). Модули unIDE свои uses не меняют.

  windows.pas                - объявления из FPC RTL (rtl/win/wininc),
                               копии в wininc/*.inc
  (Messages - модуль LCL, lcl/nonwin32: у него TMessage = TLMessage, как
   нужно для WindowProc; своего messages.pas здесь нет - иначе lazbuild
   брал его, и TMessage был записью Windows, этап 7)
  richedit, commctrl, shellapi, activex, wininet .pas
                             - из FPC packages/winunits-base
  winimpl.pas                - реализация используемых вызовов WinAPI:
                               через LCLIntf (написано руками) и
                               заглушки winimpl_auto.inc (ноль / пусто)
  unixfonts.pas              - шрифты интерфейса: правила fontconfig (Tahoma,
                               MS Sans Serif, Segoe UI -> Liberation Sans и т.п.)
                               и шрифт gtk по умолчанию Tahoma 11px;
                               UNIDE_SYSTEM_FONTS=1 - без подмены

Все вызовы WinAPI (и свои external 'x.dll' в модулях unIDE под
{$IFDEF UNIX}) ведут на символы unidewin_<Имя>. Компоновка умная
(-CX -XX): нужны только символы, которые программа вызывает.

Пересоздать объявления (FPC 3.2.2, лицензия LGPL с исключением для
статической компоновки):
  python3 genwin.py <путь к исходникам FPC>

Новые вызовы WinAPI в коде: компоновщик пишет undefined reference to
`unidewin_X'. Список таких строк - в файл, затем
  python3 genimpl.py <файл со списком> <папка исходников unIDE (UTF-8, laz)>
дописывает заглушки в winimpl_auto.inc. Нужное поведение - руками в
winimpl.pas (там функция не попадёт в заглушки).
