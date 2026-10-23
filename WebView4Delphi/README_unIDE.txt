WebView4Delphi в unIDE
======================

Источник: https://github.com/salvadordf/WebView4Delphi (лицензия MIT, файл LICENSE)
Версия: коммит 0a27539 от 23.10.2026 ("Update to WebView2 NuGet 1.0.4314.35").
Взята только папка source; файлы не менялись.

unIDE использует её в модуле Wv2View.pas: просмотр .html / .mht через
Microsoft Edge WebView2 (Chromium). Путь к модулям - SearchPath в
SyntaxHLClaude.dof (WebView4Delphi\source).

Загрузчик - встроенный (TWVLoader.UseInternalLoader = True), поэтому
WebView2Loader.dll рядом с exe не нужна.

Нужен установленный Microsoft Edge WebView2 Runtime. На Windows 7 последняя
версия - 109: страница https://developer.microsoft.com/microsoft-edge/webview2/consumer/,
"Evergreen Bootstrapper" (установка через интернет ставит 109).
