# unIDE, сборка Lazarus (laz64): проверка 2026-11-06

Что проверялось: код unIDE на известные расхождения LCL (win32) и VCL, плюс
ручной прогон сборки win64 под Wine. Исправления — в `mainTest`, коммит
`408fd87` (и ранее за день: 456a736, 20c456e, 86095e1, 0e1994d, 476e78f,
e0fffc3, 66c8812, 3171e8d).

## Как проверялось

1. **Сверка с исходниками LCL 3.0** (`lcl/interfaces/win32/win32callback.inc`,
   `win32wscustomlistview.inc`, `win32wsforms.pp`, `typinfo.pp` FPC 3.2.2).
   Главный источник расхождений: LCL win32 передаёт в WindowProc контрола
   только сообщения из своего списка в `win32callback.inc` и всё, что
   ≥ WM_USER. Остальные до обработчиков `message WM_...` не доходят.
   Все 90 обработчиков `message WM_/CM_/CN_` в unIDE сверены с этим списком.
2. **Сборка Linux/gtk2** (как раньше) — компиляция всего проекта.
3. **Сборка win64**: RTL FPC 3.2.2 и LCL 3.0 (win32 widgetset) собраны из
   исходников в контейнере, `SyntaxHLClaude.lpr` собран `ppcx64 -Twin64`,
   exe запущен под Wine 9.0 + Xvfb + openbox.

Ограничение: Wine — не Windows. comctl32, riched20, отрисовка рамок у Wine
свои. То, что видно только под Wine, ниже помечено как «под Wine, на Windows
не проверено».

## Исправлено в 408fd87 (причина проверена по коду LCL)

| Где | Что было | Причина | Исправление |
|---|---|---|---|
| ArdSimHost.pas, TArdSimWindow | После перемещения/растяжения окна эмулятора редактор не подгонялся под него (OnPlaced не вызывался) | WM_EXITSIZEMOVE нет в списке win32callback.inc — обработчик не вызывается | Под FPC: WM_MOVE/WM_SIZE + таймер 250 мс, ждёт отпускания кнопки мыши (как в конструкторе форм) |
| CodeInsight.pas, TCiListPopup | Щелчок по списку автодополнения мог забирать фокус у редактора | WM_MOUSEACTIVATE (MA_NOACTIVATE) не доходит до обработчика | Под FPC: WS_EX_NOACTIVATE в CreateParams |
| UiMenus.pas, TUiMenuWindow | То же для своих меню | То же | То же |
| DfmMove.pas (TMoveListView), DlgRqDeps.pas (TRqListView) | Цвета строк: в отчёте «Перенести в .dfm» зелёный/жёлтый фон строк, в RqDeps — цвет выделенной строки — в Lazarus не работали | NM_CUSTOMDRAW списка LCL обрабатывает в WM_NOTIFY родителя (ListViewParentMsgHandler) и как CN_NOTIFY не передаёт | Новая `UiListViewNotifyCN` (UiComCtrls.pas): после обработки LCL пересылает NM_CUSTOMDRAW списку как CN_NOTIFY, как в VCL. Вызывается из CreateWnd этих двух списков |
| FormDesigner.ApplyPropText, Unit1 (установка свойства по пути, DsgRttiTypeText), DsgClassDescW, FormSnapshot | Boolean-свойства (AutoSize, Visible, Enabled, Checked…) из инспектора не ставились живой форме (как было со строками до 3171e8d); в снимке формы и описании типов Boolean пропадал | В FPC Boolean — `tkBool`, а не `tkEnumeration` (проверено тестом: `TLabel.AutoSize` → tkBool) | `tkBool` рядом с `tkEnumeration` во всех пяти местах |
| FormSnapshot.pas | Строковые свойства в снимке формы пропадали | Строки в FPC — `tkAString` | Добавлены `tkAString`, `tkUString` |
| Unit1.UtilFormOf | Сравнение окна с Tag через `Integer(указатель)` | На win64 указатель усекался (совпадало по младшим 32 битам) | Под FPC — PtrInt |

## Проверено прогоном под Wine (сборка с исправлениями)

- Выпадающий список значения в инспекторе (AutoSize: False/True) — есть.
- Сетка инспектора — линии рисуются.
- Маркеры у TMemo — есть, растягивание работает, в .dfm пишутся Width/Height.
- Перемещение формы конструктора, затем постановка TLabel с палитры —
  форма осталась на новом месте, Left/Top в .dfm обновились.
- Растягивание TLabel за маркер — работает, в .dfm пишется `AutoSize = False`.
- AutoSize = True из инспектора — метка на форме сразу ужимается (это
  проверка исправления tkBool).
- Кириллица в редакторе — нормально (при русской локали Wine).

## Найдено, не исправлено

Наблюдения под Wine; на Windows не проверено, причина в коде не подтверждена:

1. **Плашка в строке меню у окна сообщения.** При `ShowMessage` (например,
   «New Form: не найден файл проекта .dpr») в строке меню появляется плашка
   `SyntaxHLClaude_la.` — UtilMenuUpdate берёт все видимые формы с
   заголовком. В Delphi 7 окно ShowMessage тоже форма в Screen.CustomForms,
   поэтому неизвестно, специфично ли это для Lazarus. Если в сборке Delphi
   плашки у окна сообщения нет — стоит сравнить, через что показывается
   сообщение в каждой сборке.
2. **Текстовый курсор в TMemo на форме конструктора.** После выделения
   TMemo в нём мигает каретка ввода. Похоже, контрол получает фокус.
3. **После AutoSize = True в .dfm остаётся старая Width** (96 при
   фактических 34). Код записи общий для обеих сборок, это не обязательно
   расхождение Lazarus.
4. **Группа «Source code highlighting» в IDE Options — фиолетовый фон.** В
   Unit2.dfm у `grpHighlight` задан `Color = $00800040`. Как она выглядит в
   сборке Delphi, я не знаю; если там фон по теме, значит в Lazarus
   TUiGroupBox не перекрывает Color темой.
5. **Маркеры маленькой метки закрывают её текст** (у TLabel высотой 13
   верхний, средний и нижний маркеры сливаются). Неудобно, но не ошибка
   Lazarus.

Мелочи по коду (сообщения, которые LCL не передаёт; последствия небольшие):

- FormDesigner, TDsgHook: WM_NCLBUTTONDBLCLK по заголовку формы
  конструктора не приходит — двойной щелчок по заголовку в Lazarus не
  обрабатывается.
- Unit1, TabsWndProc: проверка WM_SETFONT не срабатывает (частично
  покрыто проверкой WM_PAINT под FPC).
- Wv2View: WM_MOVING не приходит, но там же обработан WM_MOVE с тем же
  вызовом (NotifyParentWindowPositionChanged) — последствий нет.
- WM_COPYDATA и WM_GETMINMAXINFO тоже не передаются, но в unIDE они не
  используются.

## Проверено, проблем нет

- 64 бита: 102 предупреждения FPC о преобразовании указатель↔целое. Все
  просмотрены: это числа, хранимые в `Data`/`TList` и читаемые обратно
  (сохраняются без потерь), и THandle в Objects. HangWatch уже разделён по
  CPUX64. Других `SetWindowLong(GWL_WNDPROC)` с 32-битными значениями нет
  (EdHost — SetWindowLongPtrA).
- `Screen.Forms` в LCL не включает THintWindow (только TForm), циклы по
  Screen.Forms не задеты. Screen.CustomForms — один цикл, исправлен в 86095e1.
- CreateParams форм: `WndParent` LCL учитывает (`win32wsforms.pp`), если он
  не 0.
- Окна с ParentWindow без Parent — только маркеры конструктора (исправлено
  456a736).

## Как собрать win64 в контейнере (для повторной проверки)

1. `cp -r /usr/share/fpcsrc/3.2.2 /tmp/w64/src`; в `rtl/x86_64/` создать
   `makefile.cpu` (`CPU_UNITS=cpu`); `fpcmake -Twin64 rtl/win64/Makefile.fpc`;
   `make all OS_TARGET=win64 CPU_TARGET=x86_64 FPC=/usr/bin/ppcx64` в
   `rtl/win64`.
2. LCL и пакеты FPC — отдельной пустой программой, которая перечисляет
   нужные модули, **без** `-Mdelphi` (пакеты без директивы mode с ним не
   собираются), RichMemo — с `-Mobjfpc -Sh`. Пути: исходники пакетов
   (`rtl-objpas`, `fcl-base`, `fcl-process`, `fcl-image`, `paszlib`, `hash`,
   `fcl-res`, `fcl-xml`, `winunits-base`, `chm`, `fcl-web/src/base`,
   `openssl`, …) и LCL (`lazutils`, `lcl`, `lcl/widgetset`,
   `lcl/interfaces/win32`, `turbopower_ipro`, `printers`), `-dLCL -dLCLwin32`.
3. Сам проект: `ppcx64 -Twin64 -Mdelphi`, готовые модули из шага 2 через `-Fu`.
4. Запуск: `apt-get install wine64 openbox`, Xvfb, `LANG=ru_RU.UTF-8`
   (иначе кириллица из файлов — «?»), openbox — чтобы у окон были рамки и
   работал фокус.
