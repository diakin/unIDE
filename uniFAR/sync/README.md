# Копирование uniFAR в репозиторий diakin/uniFAR

uniFAR разрабатывается здесь, в unIDE (папка `uniFAR` и общие модули в корне:
`UnFar.pas`, `FarTabs.pas`, `ClrScheme.pas` и т.д.). Репозиторий
[diakin/uniFAR](https://github.com/diakin/uniFAR) - копия только того, что
нужно для сборки и поставки uniFAR отдельной программой. Файлы uniFAR правятся
в unIDE, в diakin/uniFAR они приходят копированием.

## Что копируется

`sync_unifar.py` сам строит список:

- `uniFAR/uniFAR.lpr` и все модули из его `uses`, рекурсивно (пути поиска как
  в `uniFAR.lpi`: `uniFAR`, `uniFAR/vcl`, корень unIDE);
- файлы из `{$I ...}` и `{$R ...}` этих модулей (например, `farfont.res`);
- постоянный список `EXTRA_PATHS` в начале скрипта: `.gitattributes`,
  `LICENSE`, `uniFAR.lpi`, `uniFAR/res`, `schemes`, `fonts`, `tools/7zip`,
  сам скрипт.

Новый модуль в `uses` у `UnFar.pas` попадёт в копию без правки скрипта.
Файл, который нужен во время работы, но не подключается из исходников (новая
папка рядом с exe), надо добавить в `EXTRA_PATHS`.

Раскладка папок та же, что в unIDE, поэтому `uniFAR.lpi` и команда сборки не
меняются. Список скопированных файлов и коммит unIDE записываются в
`.unide-sync` в корне diakin/uniFAR; файл из прошлого списка, который больше не
нужен, удаляется. Остальные файлы diakin/uniFAR (README.md, .github, legacy)
скрипт не трогает.

Посмотреть список, ничего не копируя:

    python uniFAR\sync\sync_unifar.py . --list

## Автоматически: GitHub Action

`.github/workflows/sync-unifar.yml` запускается после каждого push в
`mainTest` (и вручную: Actions - Sync uniFAR - Run workflow). Если файлы uniFAR
изменились, он делает коммит "Sync from unIDE: <заголовок коммита>" в
`master` репозитория diakin/uniFAR.

Для записи в другой репозиторий нужен токен. Настройка, один раз:

1. GitHub - Settings - Developer settings - Personal access tokens -
   Fine-grained tokens - Generate new token.
2. Repository access: Only select repositories - `diakin/uniFAR`.
3. Permissions - Repository permissions - Contents: Read and write.
4. Срок действия - на своё усмотрение (по истечении создать новый и заменить
   секрет).
5. В репозитории unIDE: Settings - Secrets and variables - Actions -
   New repository secret, имя `UNIFAR_SYNC_TOKEN`, значение - токен.

## Вручную, со своего компьютера

    cd <клон unIDE>
    python uniFAR\sync\sync_unifar.py . <клон uniFAR>
    cd <клон uniFAR>
    git add -A
    git commit -m "Sync from unIDE"
    git push

## Кодировка

Исходники в репозиториях хранятся в UTF-8, в рабочей папке - в cp1251 с CRLF
(`.gitattributes`, `working-tree-encoding`). Скрипт копирует файлы рабочей
папки байт в байт, `.gitattributes` копируется тоже, поэтому в diakin/uniFAR
файлы получаются такими же, как в unIDE.
