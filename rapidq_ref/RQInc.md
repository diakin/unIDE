# Папка RQInc

Собрана `rapidq_ref/tools/build_standard.py`. Набор inc, который ставится с unIDE: IDE Options - Compilers - RapidQ Basic, поле Include UnIde. Свои inc пользователя - поле Include User; какую папку берёт проект - Project Properties.

- из `incOld` без изменений: 267 файлов (без ошибок проверки INC Manager);
- из `inc_sys`: 15 файлов: debug_sys.inc, debugNoSend_sys.inc, debugWindow_sys.inc, FBFunctions_sys.inc, PRINTERDLL_sys.INC, pulsar_sys.inc, QImageBox_sys.inc, QImageDialog_sys.inc, QPrintDialog_sys.inc, RapidQ_D3D_sys.inc, RQControls.inc, RQProc.inc, TRM_RQDeclares_sys.INC, var2008_sys.inc, var_sys.inc;
- не взяты: 25 файлов incOld с ошибками (ниже).

Старая программа подключает файлы incOld под прежними именами. Новая - `RQControls.inc` (он подключает `RQProc.inc`) и при необходимости отдельные файлы `*_sys.inc`. Отдельный файл `*_sys` сам подключает `RQControls.inc`, поэтому вместе со старым `RAPIDQ.INC` его не подключают.

## Не взяты

Чтобы взять файл - внести имя в `ALLOW` в build_standard.py и собрать заново, или исправить файл в incOld.

| Файл | Что нашла проверка |
|---|---|
| API_RichEdid.inc | незакрытые/перепутанные блоки (21); строки 56, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 138 ... |
| cgi.inc | незакрытые/перепутанные блоки (2); строки 64, 137 |
| commctrl32.inc | числа с суффиксом U/L из C (4); CONST без = (5); строки 239, 240, 241, 242, 478, 479, 480, 481, 482 |
| cREdit.inc | $UNDEF/$DEFINE встроенного класса QRICHEDIT (2); строки 206, 207 |
| Files1.inc | незакрытые/перепутанные блоки (1); строки 747 |
| glaux.inc | незакрытые/перепутанные блоки (2); строки 193, 196 |
| HiLight.inc | $UNDEF/$DEFINE встроенного класса QRICHEDIT (2); строки 139, 140 |
| keys.inc | DEFINE без $ (46); строки 37, 38, 39, 67, 68, 69, 70, 71, 72, 73, 74, 75 ... |
| qEditEx.inc | $UNDEF/$DEFINE встроенного класса QEDIT (2); строки 68, 69 |
| qfocus.inc | незакрытые/перепутанные блоки (3); строки 63, 221, 299 |
| qmaxedit.inc | $UNDEF/$DEFINE встроенного класса QRICHEDIT (2); строки 91, 92 |
| QRedEx.Inc | $UNDEF/$DEFINE встроенного класса QRICHEDIT (2); строки 572, 573 |
| QREDEXTest.INC | $UNDEF/$DEFINE встроенного класса QRICHEDIT (2); строки 611, 612 |
| qREdit.inc | $UNDEF/$DEFINE встроенного класса QRICHEDIT (2); строки 206, 207 |
| QTextEdit.inc | $UNDEF/$DEFINE встроенного класса QRICHEDIT (2); строки 224, 225 |
| QTextEditTest.inc | $UNDEF/$DEFINE встроенного класса QRICHEDIT (2); строки 71, 72 |
| QThread.inc | TYPE с именем встроенного класса (1); строки 50 |
| QxEdit.inc | $UNDEF/$DEFINE встроенного класса QEDIT (2); строки 70, 71 |
| RichEditApi.inc | ";" вне строки (3); строки 7, 227, 375 |
| RichEdPopUp.inc | $UNDEF/$DEFINE встроенного класса QRICHEDIT (2); строки 137, 138 |
| RichEdPopUp1.inc | $UNDEF/$DEFINE встроенного класса QRICHEDIT (2); строки 124, 125 |
| RichEdPopUpold.inc | $UNDEF/$DEFINE встроенного класса QRICHEDIT (2); строки 149, 150 |
| TstRichEd.inc | $UNDEF/$DEFINE встроенного класса QRICHEDIT (2); строки 13, 14 |
| ultraRichEd.inc | $UNDEF/$DEFINE встроенного класса QRICHEDIT (2); строки 206, 207 |
| vfw2.inc | незакрытые/перепутанные блоки (1); строки 854 |
