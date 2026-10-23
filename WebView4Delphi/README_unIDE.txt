WebView4Delphi в unIDE
======================

Источник: https://github.com/salvadordf/WebView4Delphi (лицензия MIT, файл LICENSE)
Версия: коммит 4009217 от 17.01.2023 ("Update to WebView2 NuGet 1.0.1518.46") -
под WebView2 Runtime 109, последний для Windows 7 (с версией 1.0.4314 от
23.10.2026 процесс браузера на Windows 7 завершался, пример SimpleBrowser_D7
не создавал окно браузера, ошибка 0x80070578).
Взяты папки source, bin32 (WebView2Loader.dll x86) и пример
demos\Delphi_VCL\SimpleBrowser (файлы для Delphi 7); файлы не менялись.

unIDE использует её в модуле Wv2View.pas: просмотр .html / .mht через
Microsoft Edge WebView2 (Chromium). Путь к модулям - SearchPath в
SyntaxHLClaude.dof (WebView4Delphi\source).

Загрузчик - WebView2Loader.dll Microsoft (bin32\WebView2Loader.dll, 32-битная, из
репозитория WebView4Delphi); unIDE ищет её рядом с exe, в WebView4Delphi\bin32 у exe
и уровнем выше. Нет dll - встроенный загрузчик (TWVLoader.UseInternalLoader).

Нужен установленный Microsoft Edge WebView2 Runtime. На Windows 7 последняя
версия - 109: страница https://developer.microsoft.com/microsoft-edge/webview2/consumer/,
"Evergreen Bootstrapper" (установка через интернет ставит 109).
