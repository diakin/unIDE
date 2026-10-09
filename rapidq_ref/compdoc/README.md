# compdoc — список и документация компонентов rapidq_ref/inc

Скрипты, которыми собраны `rapidq_ref/inc/COMPONENTS.md`, страницы Appendix B в `rapidq_ref/html_doc` (`c_*.html`, `custom.html`, раздел в `contents.html`) и единый вид остальных страниц (`rq.css`).

## Файлы

- `inventory.py`: разбор всех текстовых файлов `inc` (папку `old` пропускает). Для каждого файла собирает:
  - компоненты `TYPE Имя [<…>] EXTENDS Класс`;
  - поля, события `AS EVENT(…)`, методы, `PROPERTY SET`, блоки EVENT и значения из CONSTRUCTOR с учётом PUBLIC/PRIVATE;
  - комментарии и `$INCLUDE`.

  Строки с продолжением ` _` склеиваются.
- `groups.py`, `refs.py`: вспомогательные отчёты.
  - `groups.py` показывает одноимённые компоненты и похожесть их блоков TYPE.
  - `refs.py` показывает, какие файлы `inc` подключаются из исходников репозитория.
- `decisions.py`: какие файлы перенесены в `inc/old`, что вместо них оставлено, причины и спорные случаи.
- `catalog.py`: список документируемых компонентов и имена страниц.
  - Редакции из `rapidq.inc` и `rapidq2.inc` не получают своей страницы, если есть отдельный файл с тем же компонентом.
  - Одноимённые разные компоненты получают страницы с именем файла в названии.
- `notes/*.json`: описания на английском (для страниц) и краткие на русском (для списка), по одному ключу `Имя@файл` на компонент.
  - Написаны по коду и комментариям исходников.
  - Выборочная проверка 12 страниц нашла около 3 % неточностей; найденные исправлены.
- `gen_pages.py`: страницы `c_*.html`, `custom.html`, раздел Appendix B в `contents.html`. Он же заменяет ссылки `../custom/…` в `indexa.html` на эти страницы.
- `gen_list.py`: `rapidq_ref/inc/COMPONENTS.md`.
- `gen_chm.py`: `rapidq_ref/help/rapidq.chm` (компилятор `chmcmd` из Free Pascal) и `rapidq_ref/help/keywords.txt` (слово → страница, для F1 в unIDE). Оглавление строится из `contents.html` (с Appendix B), указатель — из ссылок `indexa.html` и имён компонентов. Компиляция идёт во временной копии `html_doc`, файлы `.hhp`/`.hhc`/`.hhk` в репозиторий не пишутся.
- `clean_index.py`: переписывает `indexa.html` (алфавитный указатель) одним видом: «ИМЯ – описание» по буквам. Записи берутся из исходного указателя; ссылки на страницы, которых нет в `html_doc`, становятся серым текстом; `TARGET="doc"` (кадр старой справки) убран.
- `normalize.py`: приводит старые страницы `html_doc` к единому виду. Ставит `<!DOCTYPE html>` и `X-UA-Compatible: IE=edge` (иначе окно CHM показывает страницы в режиме IE7), подключает `rq.css`, заменяет заголовочную таблицу на полосу заголовка, добавляет строку навигации, убирает `TARGET="doc"`. Текст страниц не меняет; повторный запуск ничего не делает.

- Appendix D (функции из include-файлов, `f_*.html`) — страницы, написанные вручную; первая — `f_sadd.html` (функция `sadd` из conversion.inc и её проверка в RapidQ). Скрипты их не создают и не меняют: раздел Appendix D в `contents.html` стоит после метки `<!-- /rq-appendix-b -->`, запись SADD в `indexa.html` — обычная запись указателя.
- Appendix E (unIDE) — `unide_debugger.html`, принципы работы отладчика unIDE для программ RapidQ; написана вручную, как страницы Appendix D. Раздел в `contents.html` стоит перед Appendix C, запись DEBUGGER — в `indexa.html`.

## Пересборка

Из этой папки:

```
python3 -I inventory.py ../inc inv.json
python3 -I catalog.py inv.json ../html_doc catalog.json batches 8
python3 -I gen_pages.py ../..
python3 -I clean_index.py ../..
python3 -I gen_list.py ../..
python3 -I gen_chm.py ../..
```

У нового компонента без записи в `notes` страница будет только с таблицами. Описание добавляется в `notes/extra.json` по образцу соседних записей.

В unIDE справку открывает `RqHelp.pas`: меню Help → RapidQ (оглавление, Appendix A, Appendix B, указатель, HTML-страницы в браузере) и F1 по слову под кареткой в файле RapidQ.

`RqLcl/tofb/gen_members.py` читает страницы Appendix A («Appendix A: ИМЯ» и таблицы Properties/Methods/Events). Страницы Appendix B он не читает, а `normalize.py` сохраняет текст, который ему нужен. Проверено: вывод `gen_members.py` до и после изменений `html_doc` одинаковый.
