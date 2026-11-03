# Версии компонентов в inc_good: какая подключается

Часть компонентов объявлена и в RAPIDQ2.INC, и в отдельном файле. Если в программе подключены оба, rc.exe останавливается на повторном объявлении (например, `CHOOSECOLORDLG identifier already in use`). В inc_good такие места защищены метками, и подключается **первая** встреченная версия.

## Как выбрать версию

- Нужна версия из отдельного файла — подключите его **раньше** RAPIDQ.INC / RAPIDQ2.INC:
  ```
  $INCLUDE "QColorDialog11.inc"
  $INCLUDE "RAPIDQ.INC"
  ```
- Нужна версия из RAPIDQ2.INC — подключите RAPIDQ.INC первым; отдельный файл, подключённый позже (в том числе из другого inc), пропустится целиком.
- Две версии в отдельных файлах (QColorDialog10.inc и QColorDialog11.inc, QFileDialog.inc и QFileDialogDoc.inc) — подключается та, что раньше.

«Последнее включение перекрывает предыдущие» сделать нельзя: директивы `$IFNDEF` проверяют только то, что уже было определено выше по тексту.

## Метки

- `__ИМЯ_INC` — компонент уже объявлен. Ставится в начале отдельного файла и после `END TYPE` компонента в RAPIDQ2.INC; блок TYPE в RAPIDQ2.INC и весь отдельный файл обёрнуты в `$IFNDEF __ИМЯ_INC`.
- `__ИМЯ_INC_SA` — подключён отдельный файл. Им в RAPIDQ2.INC обёрнуты прочие объявления, которые есть и в отдельном файле (CONST, DECLARE API, TYPE записей, шаблоны событий).
- Суффикс `_INC` нужен потому, что `__COMPORT` уже используется в rapidq.inc (`$IFDEF __COMPORT` — константы br*/sb*/pr*), rapidq2007.inc и rapidq_ex.inc.

## Защищённые компоненты

| Компонент | Отдельные файлы |
|---|---|
| QAbout | QAbout.inc |
| QBitmapEx | QBitmapEx.inc |
| QCanvasEx | QCanvasEx.inc |
| QColorDialog | QColorDialog10.inc, QColorDialog11.inc |
| ComPort | ComPort.inc |
| QDebug | QDebug.inc |
| QDriveComboBox | QDriveCombobox.inc |
| QFileDialog | QFileDialog.inc, QFileDialogDoc.inc |
| QFormEx | QFormEx.inc |
| QFormMDI | QFormMDI.inc |
| QImageEx | QImageEx.inc |
| QListviewEx | QListviewEx.inc |
| QPageSetup | QPageSetup.inc |

QDockForm не менялся: в RAPIDQ2.INC он уже под меткой `__QDF_INC`, конфликтов нет.

## Что проверено и что нет

Проверено переводчиком RqToFb (2026-10-10): для каждого файла в обоих порядках (до и после RAPIDQ.INC) в переводе один TYPE компонента и нет новых повторных объявлений; перевод RAPIDQ.INC и RAPIDQ2.INC без отдельных файлов не изменился. **В rc.exe не проверялось.**

Замечания:
- Когда отдельный файл подключён первым, код RAPIDQ2.INC вне блока компонента пользуется его объявлениями. Найдено одно расхождение: QDebug в RAPIDQ2.INC вызывает `FormatMessage(…, 0&, …, 0&)`, а ComPort.inc объявляет `lpSource` и `Arguments` как `BYREF … AS LONG`. При `FORMAT_MESSAGE_FROM_SYSTEM` `lpSource` не используется; примет ли rc.exe число `0&` для BYREF-параметра — не проверено.
- QBitmapEx, QCanvasEx, QImageEx, QPageSetup, QFormMDI, QFormEx до RAPIDQ.INC: их `$DEFINE boolean integer` переопределяется в RAPIDQ.INC (`$DEFINE Boolean byte`). Так было и до защиты.
- QListviewEx.inc до RAPIDQ.INC: файл включает `$TYPECHECK ON`, и RAPIDQ.INC под ним даёт много ошибок. Так было и до защиты — подключайте его после.
- QFileDialogDoc.inc до RAPIDQ.INC: `brem`/`erem` определяются в RAPIDQ.INC, без него текст документации внутри файла читается как код. Подключайте после.
- Программа, которая подключает свой QFILEDIALOG.INC после RAPIDQ.INC (например, RQdebugger844-40.bas), теперь получает версию QFileDialog из RAPIDQ2.INC.
