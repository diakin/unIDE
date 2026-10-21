# Проверка rapidq_ref/inc2026

Журнал проверки базового набора inc-файлов RapidQ. Сам журнал лежит вне папки inc2026, в ней только inc-файлы и подпапки с ресурсами.

## Как проверялось (2026-10-09)

- Набор: по одному файлу на компонент из rapidq_ref/inc (выбор по inc/COMPONENTS.md) и файлы, которые они подключают. ComPort.cmp и COMPORTxp.CMP переименованы в .inc.
- Каждый файл переведён RqToFb и скомпилирован fbc32 -c (сообщения использовались только как указатели на места).
- Каждый файл прочитан целиком; правки предложены по коду, документации html_doc и другим версиям файла в inc и inc/old.
- Каждая правка перепроверена отдельно (другим агентом, без участия того, кто её предложил). Отклонённые и недоказанные — в разделе «Вопросы», в файлы не внесены.
- Каждая внесённая правка помечена в строке комментарием `' inc2026: ...` (было, стало, основание). Число строк файлов не менялось, кроме QDebug.inc (+1 строка).
- После правок повторный перевод и fbc: ни в одном файле ошибок и подозрений не прибавилось.
- **В RapidQ (rc.exe) правки не проверялись** — rc.exe в этой среде нет. Следующий шаг — тестовые программы в rapidq_ref/inc2026_tests.

Итого: файлов 137, внесено правок в этом проходе 132, вопросов 124, замечаний по ресурсам 6.

Кроме того, внесены раньше (до этого прохода, коммит 2a310d6) правки в QChart.inc, QCoolBarXPv1d.inc, QHTML.inc, rapidq2.inc, Qposic1.inc, QPosicL.inc (пути к картинкам — из своей подпапки), и в этом проходе вручную — rapidq2.inc: Super.AddItems в QDriveComboBox (та же ошибка, что в QDriveCombobox.inc). Они тоже помечены `inc2026:` в строках.

## Файлы

| Файл | Статус | Правок | Вопросов | Кратко |
|---|---|---|---|---|
| Api.inc | просмотрен | 0 | 0 | Константы, записи и DECLARE для owner-draw меню. Ошибок не найдено; WindowProc объявлена, тело пишет программа. |
| ApiDate.inc | просмотрен | 1 | 0 | Функции lastdaym и weekday через GetDateFormat/GetLocaleInfo. У определения lastdayM добавлен тип AS STRING, как в DECLARE. |
| COMPORTxp.inc | просмотрен | 3 | 2 | Компонент последовательного порта MyCom_Port (WinAPI). Исправлены: MyPort.Handle в ReadString, повтор WriteTotalTimeoutMultiplier вместо WriteTotalTimeoutConstant, текст ошибки GetCommStatus. Вопросы: закомментированные константы CreateFile и StopBits по умолчанию. |
| CallBack_0.Inc | просмотрен | 2 | 1 | Переходник CALLBACK без параметров (by Jacques, помечен как непроверенный). Найдено: лишний & перед Forwardto (строка 35) и порядок Bind/присваивания в MasterCallBack_0 - вызывалась бы FuncBind_0 без тела вместо процедуры программы. |
| CallBack_1.Inc | просмотрен | 0 | 0 | Переходник CALLBACK с одним аргументом (SetNewCallBack_1). FuncBind_1 без тела - шаблон для BIND, так и задумано. Ошибок не найдено. |
| CallBack_2.Inc | просмотрен | 1 | 0 | Переходник CALLBACK с 2 аргументами. Имя первого параметра в заголовке MasterCallBack_2 расходилось с DECLARE - исправлено. |
| CallBack_3.Inc | просмотрен | 0 | 0 | Переходник CALLBACK на 3 аргумента. Ошибок не найдено; FuncBind_3 без тела - шаблон для BIND. |
| CallBack_4.Inc | просмотрен | 0 | 0 | Переходник CALLBACK на 4 аргумента (Jacques). FuncBind_4 без тела - намеренно, шаблон для BIND. Ошибок не найдено. |
| CallBack_5.Inc | просмотрен | 1 | 0 | Переходник CALLBACK с 5 аргументами. Первый параметр в заголовке MasterCallBack_5 назывался hBind (как локальная переменная) вместо hFunction из DECLARE - исправлено. |
| CallBack_6.Inc | просмотрен | 0 | 0 | Переходник CALLBACK с 6 параметрами; совпадает с CallBack_1...8 по схеме. Ошибок не найдено (FuncBind_6 без тела - так задумано, это шаблон для BIND). |
| CallBack_7.Inc | просмотрен | 0 | 0 | Переходник CALLBACK на 7 аргументов. Ошибок не найдено; FuncBind_7 без тела - шаблон для BIND. |
| CallBack_8.Inc | просмотрен | 0 | 0 | Переходник CALLBACK на 8 аргументов (Jacques). FuncBind_8 без тела - намеренно, шаблон для BIND. Ошибок не найдено. |
| CallBacks.Inc | просмотрен | 0 | 0 | Сборный include для CallBack_0..8.Inc. Ошибок не найдено (подозрения переводчика относятся к самим CallBack_N.Inc). |
| ComPort.inc | просмотрен | 3 | 3 | Компонент последовательного порта (Pete Kleinschmidt). Исправлено: ReadFile с MyPort.Handle, дважды WriteTotalTimeoutMultiplier вместо WriteTotalTimeoutConstant, сообщение ошибки GetCommStatus. Те же ошибки в inc/ComPort.cmp и COMPORTxp.inc. |
| Files.inc | просмотрен | 8 | 4 | Библиотека работы с файлами и папками (пути, копирование, удаление, преобразование файлов данных, DownLoadURL). Исправлено: crl/crl$, SubDir(d2), rzm24/frzm24, удвоенный путь в KillFiles, Adat!/Adat1!, Space -> Space$, END SUB у функции. Перенос Long_ оставлен как есть. Вопросы: ByVal в вызове, отладочные PRINT. |
| HiLight.inc | просмотрен | 0 | 0 | Пример William Yu: QRichEdit с подсветкой ключевых слов. Ошибок не найдено (ошибки перевода относятся к rapidq.inc и conversion.inc). |
| Memory.inc | просмотрен | 1 | 1 | Работа с кучей Windows (HeapAlloc и т.п.) и чтение чисел по адресу. Исправлен тип чтения в SingleFromPtr; вопрос по размеру в ReAllocate. |
| QAVI.inc | просмотрен | 6 | 0 | Компонент QAVI (чтение и запись AVI через avifil32). Исправлены незакрытая строка, END SUB у четырёх FUNCTION и проверка fps по полю вместо параметра. |
| QAbout.inc | просмотрен | 0 | 0 | QAbout (окно 'О программе'). Ошибок не найдено. |
| QAnim.inc | просмотрен | 0 | 0 | Анимация из QImageList по таймеру. Ошибок не найдено (поведение сеттеров Move/BackColor описано в c_qanim.html, это не синтаксические ошибки). |
| QAnimate.inc | просмотрен | 1 | 0 | Компонент QAnimate (Nastase Eodor), использует внешние объявления WinAPI и CallBack_4. Исправлен параметр FreeResource. |
| QBevel.inc | просмотрен | 0 | 0 | Компонент QBEVEL (аналог TBevel). Ошибок не найдено. |
| QBitmapEx.inc | просмотрен | 0 | 1 | QBitmapEx (рисование на QBitmap через GDI, буфер обмена, NViewLib). Ошибок не найдено; вопрос по структуре BITMAP. |
| QBrowseDialog.inc | просмотрен | 0 | 1 | QBROWSEDIALOG (диалог выбора папки). Ошибок в коде нет; MAX_PATH здесь закомментирован. |
| QButtonXP.INC | просмотрен | 0 | 0 | QButtonXP (кнопка со стилем XP). Ошибок не найдено. |
| QCanvasEx.inc | просмотрен | 0 | 2 | Расширенный QCanvas (рисование через GDI, буфер обмена, зеркало). Ошибок синтаксиса не найдено; вопросы: удаление битмапа после передачи в буфер обмена, поля TBITMAP. |
| QChart.inc | просмотрен | 0 | 2 | Компонент графиков QChart (TYPE EXTENDS QCANVAS). Новых ошибок, которые можно исправить без сомнений, не найдено; 2 вопроса: сравнение BYTE-поля AutoScale с -2 в PrintChart и Parent = QFORM в конструкторе. |
| QColorButton.inc | просмотрен | 0 | 0 | QCOLORBUTTON (QPanel-кнопка с эффектом нажатия). Ошибок не найдено. |
| QColorDialog.inc | просмотрен | 0 | 1 | Компонент QCOLORDIALOG (ChooseColor). Вопрос по структуре TCHOOSECOLOR. |
| QCoolBarXPv1d.inc | просмотрен | 0 | 2 | Панель инструментов в стиле XP (D-evolution). Ранее исправленное не трогал; новых доказанных ошибок не найдено, два вопроса. |
| QCursor.inc | просмотрен | 0 | 0 | Компонент QCursor (загрузка курсоров из файла/ресурса, видимость, перемещение). Ошибок не найдено. |
| QDOCKFORM.inc | просмотрен | 4 | 1 | Компонент QDOCKFORM (пристыковываемая панель). Исправлено: два ALIAS WinAPI без суффикса A и центрирование плавающей формы в Dock (UndockedForm без точки); вопрос по координатам FillRect. |
| QDataBase.inc | просмотрен | 4 | 1 | Простая файловая база записей фиксированной длины. Две FUNCTION закрывались END SUB, в SearchByField/SearchByRequest поле вырезалось MID$ с позиции, отсчитанной от 0 - исправлено. |
| QDebug.inc | просмотрен | 1 | 1 | Компонент QDebug (окно отладки с QRichEdit). Set_Enabled не сохранял значение, и Print никогда не печатал — добавлено присваивание; вопрос по True. |
| QDesktop.inc | просмотрен | 0 | 0 | Компонент QDesktop (копия экрана, обои, цвет точки через GDI). Объявления API верны, ошибок не найдено. |
| QDigDisplay.inc | просмотрен | 0 | 0 | QDigDisplay (цифровой индикатор из картинок). Картинки 32.bmp-64.bmp грузятся по имени из текущей папки. |
| QDir.Inc | просмотрен | 1 | 1 | Поиск файлов в папках с фильтром атрибутов (Jacques Philippe). Исправлена проверка результата CreateFile (ошибка - -1, а не 0). |
| QDrawFocus.inc | просмотрен | 1 | 0 | Компонент QDrawFocus (рамка выделения DrawFocusRect). Исправлено сравнение с .Top вместо .StartY. |
| QDrawMenu.inc | просмотрен | 0 | 1 | QdrawMenu (меню с картинками). Ошибок в TYPE нет; после TYPE - работающий пример с $RESOURCE по абсолютному пути. |
| QDrive.inc | просмотрен | 0 | 0 | Компонент QDrive (список дисков, тип, свободное место). Ошибок не найдено. |
| QDriveCombobox.inc | просмотрен | 1 | 0 | QComboBox со списком дисков. GetDrives вызывал собственный пустой AddItems (переопределение скрывает метод QComboBox) - исправлено на Super.AddItems. Та же ошибка в копии компонента в rapidq2.inc (строка 6183) - не в этой пачке. |
| QFTPCLIENT.INC | просмотрен | 0 | 1 | FTP-клиент QFtpClient на wininet.dll. Правок нет; вопрос по типу параметра lpFindFileData в DECLARE FtpFindFirstFileA (передаётся запись, объявлен LONG). |
| QFileDialog.inc | просмотрен | 2 | 0 | QFILEDIALOG (диалог открытия/сохранения через GetOpenFileName). Исправлено имя константы pdfStrTerm$ -> fdStrTerm$ и размер копируемого буфера FileTitle. |
| QFileListView.inc | просмотрен | 0 | 1 | QFileListView (список файлов на QListView с иконками). Ошибок не найдено; вопрос по INSTR с тремя параметрами. |
| QFlashLabel.inc | просмотрен | 0 | 0 | Мигающая надпись QFlashLabel (QLABEL с таймером). Ошибок не найдено. |
| QFlatButton.inc | просмотрен | 1 | 0 | QFlatButton (кнопка на QImage). Одна ошибка копирования в Depress: нижняя линия рисовалась до Height-1 по X вместо Width-1. |
| QFormEx.inc | просмотрен | 0 | 0 | Расширенная форма QFormEx (перетаскивание файлов, значок в трее, FormStyle). Ошибок не найдено (CODEPTR метода - ограничение переводчика, не RapidQ). |
| QFormMDI.inc | просмотрен | 0 | 0 | Компонент QFormMDI (MDI-форма на WinAPI). Ошибок не найдено. |
| QGL.inc | просмотрен | 7 | 6 | OpenGL-обёртка QGL и загрузчик моделей QMD2model. Исправлено: GL.hDC -> QGL.hDC во Flip, CASE < 801 -> CASE IS < 801, порядок аргументов Seek (4 места), => -> >=. Вопросы: путь <\GL\gl.inc>, приоритет AND/OR, SUB как PROPERTY SET, skins(1), QBITMAPEX.Pointer. |
| QGridColor.inc | просмотрен | 0 | 0 | Панель выбора 16 цветов. Ошибок не найдено. |
| QHTML.inc | просмотрен | 3 | 1 | Просмотр упрощённого HTML (Pascal Delcombel), уже правился ранее. Дополнительно: пропуск пробелов после '=' шёл назад (tBegin--), атрибут AREA назывался COORD вместо COORDS, сущность &supl; вместо &sup1;. |
| QHead.inc | просмотрен | 1 | 0 | QHead (заголовок с градиентом на QCanvas). Исправлено смещение белого текста по IconY вместо IconX. |
| QICMP.INC | просмотрен | 0 | 1 | QICMP (ping через icmp.dll). Ошибок синтаксиса не найдено; вопрос по разбору адреса через HEX$. |
| QICON.inc | просмотрен | 0 | 0 | Извлечение и сохранение иконок (D. Glodt). Заголовки ICO (62 байта) и размеры чтения bitmap проверены, ошибок не найдено. |
| QImageBox.inc | просмотрен | 0 | 1 | Компонент просмотра картинок на QScrollBox (BMP, ICO/CUR, остальные форматы через NViewLib.dll). Ошибок не найдено; вопрос по типам полей TBITMAP_IMGBOX. |
| QImageDialog.inc | просмотрен | 0 | 1 | Диалог открытия файла с предпросмотром картинки (QImageDialog). Ошибок не найдено; вопрос по типам полей TBITMAP_IMG. |
| QImageEx.inc | просмотрен | 1 | 0 | QImage с буфером обмена и загрузкой через NViewLib. Function CanPaste закрывалась End Sub - исправлено. |
| QImageListEx.inc | просмотрен | 0 | 0 | QImageListEx (разбор полосы картинок в QImageList через временный __tmp.bmp). Ошибок не найдено; fmCreate берётся из rapidq.inc. |
| QIni.inc | просмотрен | 0 | 0 | QINI - чтение/запись ini через GetPrivateProfileString, каталоги Windows. Ошибок не найдено. |
| QIniFile.inc | просмотрен | 0 | 0 | QIniFile (ini-файл на QStringList, зависит от SysUtils.inc). Ошибок не найдено. |
| QInputBox.inc | просмотрен | 0 | 1 | QInputBox - диалог ввода строки. Вопрос: SetFocus не объявлен при $TYPECHECK ON. |
| QLed.inc | просмотрен | 1 | 0 | Компонент QLed (светодиод на QCanvas). PROPERTY SET SetColor закрыта END SUB - исправлено на END PROPERTY. |
| QLedScroll.inc | просмотрен | 0 | 1 | QLEDSCROLL (бегущая строка на QCanvas). Ошибок не найдено; один вопрос: TextWidth без This. |
| QLine.inc | просмотрен | 0 | 0 | Линия QLine (QCANVAS, рисует DrawEdge). Ошибок не найдено. |
| QListBoxEx.inc | просмотрен | 0 | 0 | QListBoxEx (QListBox с событием OnEnter через скрытое меню). Ошибок не найдено. |
| QListviewEx.inc | просмотрен | 0 | 0 | QListviewEx (QListView с заголовками-кнопками и CSV). Ошибок не найдено. |
| QMarker.inc | просмотрен | 0 | 1 | QMarker - панель-разметка строк. Ресурс Mark.bmp не найден; вопрос по границе цикла в Draw. |
| QMaxSplitter.inc | просмотрен | 1 | 1 | Сплиттер на QPanel (Psyclops). Переменная R переименована в Rect1, но в одной строке осталась R; кроме того TYPE POINTAPI теперь стоит после DIM ... AS POINTAPI. |
| QMidi.inc | просмотрен | 0 | 0 | QMidi (проигрывание MIDI через MCI). Ошибок не найдено (громкость задаётся waveOutSetVolume - это поведение, не ошибка). |
| QPageSetup.inc | просмотрен | 0 | 0 | Диалог параметров страницы (PageSetupDlg). Ошибок не найдено. |
| QPosicL/QPosicL.inc | просмотрен | 0 | 0 | Панель позиционирования QPosicL (две полосы прокрутки и кнопки). Картинки уже переведены на $RESOURCE ранее; новых ошибок не найдено. |
| QPrinterInfo.inc | просмотрен | 0 | 0 | QPrinterInfo - сведения о принтере через GetDeviceCaps. Ошибок не найдено. |
| QProcess.inc | просмотрен | 0 | 0 | Поток (CreateThread) с событием OnProcess. CODEPTR(this.Process) - метод компонента, так же в rapidq2.inc; ошибок RapidQ не найдено. |
| QProgress.inc | просмотрен | 0 | 2 | Индикатор с бегущими фигурами (JohnK), таймер или поток. Явных ошибок синтаксиса нет; два вопроса: '+ =' с пробелом и ожидание .Visible, которое никто не меняет. |
| QProgressBar.inc | просмотрен | 1 | 2 | Компонент QProgressBar (msctls_progress32). Исправлен порядок x, y в CreateWindowEx; два вопроса. |
| QRedEx.Inc | просмотрен | 3 | 1 | QREDEX (QRichEdit с меню, поиском и заменой). Исправлены сравнение числа со строкой и вызов LockWindowUpdate без параметра. |
| QRichEditXt.inc | просмотрен | 1 | 18 | Экспериментальный QRichEdit_xt с подсветкой синтаксиса в WM_PAINT (много отладочных PRINT). Исправлено: AUTOFONT без точки. Вопросы: END PROPERTY SET, глобальный объект RichEdit, HiLiteFont не объявлен, & вместо AND, CODEPTR метода, передача записи в LONG. |
| QRun.inc | просмотрен | 2 | 0 | Компонент QRun (запуск файлов, перечисление окон). Исправлено: объявления Run_* API стояли под $IFNDEF __WIN32API, хотя под этими именами есть только здесь; условие перенесено на константы SW_. |
| QSHFileOperation.inc | просмотрен | 1 | 0 | Компонент QSHFileOperation (копирование, перенос, переименование, удаление через SHFileOperationA). Исправлен размер поля fFlags в SHFILEOPSTRUCT: 4 байта вместо 2 сдвигали следующие поля. |
| QSavePlus.inc | просмотрен | 0 | 1 | QSaveplus (QSaveDialog с проверкой имени и расширения). Ошибок в TYPE нет; после TYPE идёт работающий пример программы. |
| QShutdown.inc | просмотрен | 5 | 0 | Выключение/перезагрузка/выход из системы. В методах поле MyFlag использовалось без This, поле не менялось; исправлено по копии в rapidq2.inc. |
| QSkin.inc | просмотрен | 0 | 0 | QSkin (форма со скином-картинкой). Ошибок не найдено. |
| QSkinBtn.inc | просмотрен | 0 | 1 | Кнопка-картинка QSkinBtn (QIMAGE с тремя QBITMAP). Ошибок не найдено; вопрос: show.parent=qform. |
| QSocketEx.inc | просмотрен | 3 | 1 | Расширение QSocket (имя по адресу, адрес по имени, select, неблокирующий режим, текст ошибки Winsock). Исправлено: нет END CONSTRUCTOR; незакрытая строка "' в LastError; в gethostbyaddr третьим параметром передавался Protocol вместо Family (AF_INET). Вопрос: SUB WriteLine с типом результата As LONG. |
| QSpinEdit.inc | просмотрен | 1 | 0 | QSpinButton (QPanel с двумя QCoolBtn и QEdit). Найдено только =>, заменено на >=. |
| QSplash.inc | просмотрен | 0 | 0 | QSplash - заставка с картинкой и текстом. Ошибок не найдено. |
| QStatusBarEx.inc | просмотрен | 0 | 0 | Компонент QStatusBarEx (панель внутри секции QStatusBar). Ошибок не найдено. |
| QStringGridEx.inc | просмотрен | 0 | 0 | QStringGrid со стилем редактора по строкам (шаблон TYPE <Size>). Ошибок не найдено. |
| QTButton95.inc | просмотрен | 0 | 3 | QTButton (кнопка со скином/темой XP). Правок нет. Вопросы: сравнение Height2 с Bitmap1.Width, клавиши «вперёд», двойной CloseThemeData; ресурс btn_BMP должна объявить программа. |
| QTextBtn.inc | просмотрен | 0 | 1 | Текстовая кнопка QTextBtn (QLABEL). Вопрос: у свойства enabled указан установщик SetEnabled, которого в типе нет. |
| QTextEdit.inc | просмотрен | 0 | 0 | QTEXTEDIT на QRICHEDIT со своим контекстным меню; коды EM_* верные. Ошибок не найдено. |
| QToolBar.inc | просмотрен | 1 | 0 | Компонент QToolBar (Nastase Eodor), использует внешние объявления WinAPI (NMHDR, TBBUTTON, TB_*, CallBack_4). Исправлена граница индекса в DelButton. |
| QToolBarEX.inc | просмотрен | 0 | 0 | Панель инструментов из QCoolBtn с картинками из полосы bmp (QImageListEX). Ошибок не найдено. |
| QTreeviewEx.inc | просмотрен | 1 | 0 | QTreeView с перемещением веток через временный файл. В MoveDown у строки QStringList бралось .text - исправлено. |
| QVideo.inc | просмотрен | 0 | 1 | Компонент QVideo (видео через MCI). Явных ошибок нет; один вопрос по INSTR с пустым аргументом. |
| QVolumeInfo.inc | просмотрен | 1 | 1 | Компонент QVolumeInfo (сведения о томе). Исправлено => на >=; вопрос по Private Declare. |
| QVuMeter.inc | просмотрен | 0 | 0 | Компонент QVuMeter (индикатор уровня на QCanvas). Ошибок не найдено. |
| QWave.inc | просмотрен | 1 | 1 | Воспроизведение/запись WAV через MCI. В GetPosition вместо QWave было Wave - позиция не читалась. |
| QXPButton.inc | просмотрен | 0 | 1 | Кнопка QXPBUTTON (картинка на кнопке со стилем XP через BCM_SETIMAGELIST). Ошибок не найдено; вопрос: True/False в файле не определены. |
| Qcdaudio.inc | просмотрен | 5 | 0 | Компонент Qcdaudio (проигрыватель аудио-CD через MCI). Исправлено: лишний + перед запятой в 4 вызовах mciSendCdaudio; Declare Sub event_change вынесен из-под $IFNDEF __WIN32API (WINDOWS.INC его не объявляет). |
| Qid3Tag.inc | просмотрен | 2 | 1 | Компонент Qid3tag (чтение и запись тега ID3v1). Исправлена проверка filename без имени типа; вопрос по ReadByte/WriteByte. |
| Qmp3.inc | просмотрен | 5 | 1 | Qmp3 (заголовок mp3, теги ID3v1, проигрывание). Исправлены mp3.filename, tagstream в WriteTags, сравнение байта с 256 и повтор "320" в таблице Layer II. |
| Qposic1/Qposic1.inc | просмотрен | 0 | 0 | Компонент Qposic (две полосы прокрутки и кнопки). Пути $RESOURCE исправлены ранее; других ошибок не найдено. |
| QrPanel.inc | просмотрен | 0 | 0 | QRPANEL (панель со скруглёнными углами). Ошибок не найдено; True берётся из rapidq.inc. |
| QtabControlEx.inc | просмотрен | 0 | 0 | QTabControl со счётчиком вкладок TabCount. Ошибок не найдено. |
| QxEdit.inc | просмотрен | 0 | 0 | Компонент QxEDIT (QEDIT с OnGetFocus/OnLoseFocus и своей оконной процедурой). Ошибок не найдено (CODEPTR(This.Proc) - приём RapidQ, переводчик его не поддерживает). |
| RC4crypt.inc | просмотрен | 0 | 0 | Шифр RC4 (QRC4). Ошибок не найдено. |
| RSocket.INC | просмотрен | 0 | 0 | RSocket (QSocket с функциями Winsock). Ошибок не найдено. |
| RapidFRM.inc | просмотрен | 0 | 1 | RapidFRM (хук мыши, QColorDlg, функции вкладок, константы компонентов). Требует rapidq2.inc. Ошибок не найдено, один вопрос. |
| RapidQ_D3D.inc | просмотрен | 5 | 3 | Direct3D retained mode: константы, векторы, QD3DCamera, QD3DPrimitive, QD3DCloneMesh. Исправлены null, '< =' и порядок параметров CrossProduct. |
| RichEdPopUp.inc | просмотрен | 0 | 0 | Компонент QMAXEDIT (QRICHEDIT с контекстным меню и функциями строк). Ошибок не найдено. |
| SysUtils.inc | просмотрен | 1 | 0 | Функции для имён файлов, LoWord/HiWord/MakeLong, SysErrorMessage. MakeLong собирал число неверно - исправлено. |
| TstRichEd.inc | просмотрен | 0 | 1 | Тестовый TestEDIT (QRichEdit с методом LINEINDEX). Вопрос по глобальному DECLARE без тела. |
| VFW.inc | просмотрен | 4 | 2 | Обёртки Video for Windows (avicap32) и компонент QWebCam. Исправлены две процедуры: SetImageWidth (SUB с AS LONG -> FUNCTION) и END SUB у FUNCTION ShowDialogBox. Вопросы: SetWindowPos не объявлена, строки/записи в параметр As Long. |
| XPSkinMetallic_2.11_Res.inc | просмотрен | 3 | 5 | Компонент myXPSkinnedForm (форма со скином Windows XP, ресурсы BMP задаёт программа через $RESOURCE). Исправлены пропущенный оператор в ElseIf и =< на <=; несколько мест вынесены в вопросы. |
| XPThemes.inc | просмотрен | 0 | 1 | Подклассы QRichEdit/QScrollBox/QStringGrid/QPanel/QGroupBox с рамкой темы XP через CallBack_4. Ошибок синтаксиса не найдено, один вопрос. |
| XP_MANIFEST.INC | просмотрен | 1 | 0 | Создание .manifest для стиля XP, XPButton, XpGroupBox. Заменено => на >=. |
| apiRe.inc | просмотрен | 0 | 2 | Обёртка QRichEdit_api (окно RichEdit через CreateWindowExA). Ошибок, которые можно исправить без сомнений, не найдено; 2 вопроса: $DEFINE HWND INTEGER против параметров hwnd в DECLARE и Application.hInstance, которого нет в qapplication.html. Константы WS_EX_CLIENTEDGE/MDICHILD/OVERLAPPEDWINDOW по документации компонента должны быть определены до include - не трогал. |
| conversion.inc | просмотрен | 2 | 2 | Функции преобразования (кодовые страницы, hex, байты, Like, градусы, RC4); зависит от rapidq.inc (Num_*, ffFixed, qt, crlf, cr, lf, brem). Исправлены: AddChrAfter присваивал AddChrBefore, ConvertCodePage2 присваивал ConvertCodePage. Вопросы: аргументы MultiByteToWideChar в ConvertCodePage2, brem 0 без erem. |
| eml.inc | просмотрен | 1 | 2 | Функции разбора писем (заголовки, Base64, декодирование темы, адреса из .wab); зависит от rapidq.inc и conversion.inc. Исправлено: в GetMsgBodyCodeMethod тело использовало Msg вместо параметра MsgBody. Два вопроса. |
| fbscancodes.inc | просмотрен | 0 | 0 | Константы виртуальных клавиш VK_*; значения сверены с Windows, ошибок не найдено. |
| fileops.inc | просмотрен | 0 | 0 | Функции для имён файлов и путей, диалоги выбора. Ошибок не найдено. |
| func_array.inc | просмотрен | 0 | 4 | Процедуры для массивов SINGLE (среднее, экстремумы, разность/сумма, скользящее среднее, огибающие). Явных синтаксических ошибок нет; вопросы по логике: ReversX1 ничего не меняет, размер Nakop! в Nakopl, граница цикла в ARRMaxEx. |
| odbc.inc | просмотрен | 1 | 4 | Обёртка ODBC (TYPE qODBC). Исправлено: пробел в " NUMERIC". Вопросы: нет вызова SQLError перед сообщением об ошибке (есть в inc/old/qodbc.inc), Trim$ не определена, лишний драйвер в DriverCount, код на уровне модуля в конце файла. |
| parse.inc | просмотрен | 1 | 2 | Разбор строк исходника (GetCharNum, GetVarPos, ParseDim, ParseDef, DelComments, GetOperators); qt, ht, crlf - из rapidq.inc. Исправлен NEXT с другим именем счётчика; вопросы по k в ParseDim и NumOpers. |
| qcalendar.inc | просмотрен | 2 | 1 | Компонент qcalendar (календарь на QStringGrid). Исправлены имя подключаемого файла (apidate.bas -> ApiDate.inc) и выход за массив week(1 TO 7). |
| qcgi.inc | просмотрен | 0 | 0 | Библиотека QCGI (разбор переменных окружения CGI и строки запроса). Ошибок не найдено (i-- в строке 206 встречается и в других include, не трогал). |
| qciccio.inc | просмотрен | 0 | 1 | Пустая заготовка компонента Qciccio. Вопрос: тип поля ciccino нигде не определён. |
| qdirlistview/qdirlistview.inc | просмотрен | 3 | 0 | QDirListView (Rene Saarsoo) - список файлов и папок на QListView; vidnum$ берётся из conversion.inc (через rapidq.inc). Исправлено: опечатка PontPlace, флаг ColumnsInitialized без имени типа. Ресурсы: 4 иконки по пути resource\, а лежат рядом с .inc. |
| qdownload.inc | просмотрен | 0 | 1 | Загрузка файла по HTTP через QSocket. Синтаксических ошибок не найдено; файл зависит от констант RAPIDQ.INC. |
| qfocus.inc | просмотрен | 0 | 4 | Перемещаемый и растягиваемый QCanvas с мигающей рамкой. Явных ошибок синтаксиса не доказано; есть отладочные ShowMessage и непарные WITH/IF - вынесены вопросами. |
| qftpdirlistview/qftpdirlistview.inc | просмотрен | 1 | 4 | Незаконченный компонент (work in progress): FTP не реализован, в LoadDirectories вставлен пример QFtpClient и строка !!!!!!!!!!!!. Абсолютные пути к иконкам, опечатка PontPlace - исправлена, остальное вопросами. |
| qgraph.inc | просмотрен | 9 | 0 | Компонент QLineGraph (график по данным QStringGrid). Исправлены поля без «.» в WITH (AxisColour, ExtrapolateToZero), ширина не того заголовка и счётчик цикла после цикла. |
| qmenu.inc | просмотрен | 2 | 0 | QMenu (меню с картинками, owner-draw). Исправлены '= =' и перекрещённые END IF / END WITH. |
| qspintext.inc | просмотрен | 0 | 0 | Qspintext (поле со стрелками). Ошибок не найдено; vl - неявная глобальная переменная, работает. |
| rapidq.inc | просмотрен | 0 | 1 | Основной include: константы, QBColor, служебные функции, QDebug; подключает conversion/Files/func_array/parse/eml. Ошибок, требующих правки, не найдено; вопрос по QDebug - вызовы WinAPI без DECLARE. |
| rapidq2.inc | просмотрен | 7 | 6 | Большой include RapidQ2 (константы, WinAPI, QFormEx, QFormMDI, QDockForm, QBitmapEx, QCanvasEx, COMPORT, QMenuEx, QFileDialog, QPageSetup, QSystem, Screen.*). Найдено: неверное значение CDS_TEST, побитовое AND с INSTR в двух LoadOtherImage, перепутанные сон/гибернация в SetSuspendState; 6 вопросов. |

## Внесённые правки

### ApiDate.inc
- строка 36: добавлено as string, как в DECLARE (строка 34): без типа функция числовая, и строка в строке 48 дала бы 0

### COMPORTxp.inc
- строка 340: было ERROR_CHANGING_PORTSETTINGS, стало ERROR_GETTING_PORT_STATUS: ошибка ClearCommError - это ошибка получения состояния порта; константа ERROR_GETTING_PORT_STATUS (строка 139) объявлена и больше нигде не используется
- строка 402: было второе присваивание WriteTotalTimeoutMultiplier = 1000 (строкой выше уже 0), стало WriteTotalTimeoutConstant = 1000: поле WriteTotalTimeoutConstant (строка 16) иначе не задаётся, по образцу ReadTotalTimeoutMultiplier/Constant (строки 399-400)
- строка 529–533: в строке 529 было MyPort.Handle (MyPort нигде не объявлен), стало MyCom_Port.Handle, как во всех остальных методах типа MyCom_Port

### CallBack_0.Inc
- строка 35: Forwardto вместо &Forwardto: адрес мастер-функции пишется в машинный код (mov eax, ...), "&" перед именем - не оператор RapidQ (operators.html: & - только сложение строк); во всех CallBack_1...8.Inc и CallBackForwarder.Inc строка 72 - WriteNum(Forwardto, 4)
- строка 51: добавлено : hBind = hFunction после Bind: BIND записывает в hBind адрес FuncBind_0 (глава 11) и затирает hFunction из строки выше, а у FuncBind_0 тела нет; в CallBack_1...8.Inc порядок такой же - DefInt hBind, Bind, hBind = hFunction

### CallBack_2.Inc
- строка 49: hFunction вместо cbIndex: в DECLARE (строка 45) и в теле (строка 52) - hFunction, как в CallBack_0/1/3/4; RapidQ берёт имена из DECLARE, так что поведение не меняется, cbIndex нигде не используется

### CallBack_5.Inc
- строка 49: hFunction вместо hBind: в заголовке было hBind - то же имя, что у локальной DefInt hBind (строка 50); в DECLARE (строка 45) и в теле (строка 52) - hFunction, как в CallBack_4/6/7/8

### ComPort.inc
- строка 345: ERROR_GETTING_PORT_STATUS вместо ERROR_CHANGING_PORTSETTINGS: это ошибка ClearCommError в GetCommStatus; константа ERROR_GETTING_PORT_STATUS объявлена в строке 139 и больше нигде не используется, текст ERROR_CHANGING_PORTSETTINGS - для SetCommState (строка 447)
- строка 410: WriteTotalTimeoutConstant вместо WriteTotalTimeoutMultiplier: строкой выше Multiplier уже = 0, по образцу Read (строки 407-408) второе поле - Constant (поле объявлено в строке 16), иначе Multiplier = 1000 мс на каждый байт
- строка 542–546: ComPort.Handle вместо MyPort.Handle в строке 542: MyPort нигде не объявлен (0), ReadFile получал неверный дескриптор; во всех остальных вызовах - ComPort.Handle (строки 339, 469, 500)

### Files.inc
- строка 442: crl$="" вместо crl="": в ветке else - crl$=crlf, ниже используется crl$ (строка 446); crl - другая, числовая переменная
- строка 675: SubDir(i) вместо SubDir(d2): d2 нигде не получает значения (0), поэтому атрибуты брались для папки верхнего уровня, а не для текущей SubDir(i) (строка 672)
- строка 692: SubDir(i) вместо SubDir(d2): d2 нигде не получает значения (0); текущая папка - SubDir(i) (строка 691)
- строка 790: frzm24 вместо rzm24: ответ MessageDlg записан в frzm24 (строка 789), rzm24 нигде не получает значения - ответ "Нет" не обрабатывался
- строка 916: fileexists(FName$) вместо fileexists(StripPath(FileName$)+FName$): FName$ уже содержит путь (строки 911, 917), путь удваивался и проверка никогда не срабатывала
- строка 1301: Adat1! вместо Adat!: в цикле интерполяции пишется промежуточное значение Adat1! (строка 1299), так же в парной ветке (строка 1323)
- строка 1450: Space$ вместо Space: в RapidQ есть только SPACE$ (indexa.html); Space без $ - необъявленное имя
- строка 1485: END FUNCTION вместо END SUB: процедура открыта как function DownLoadURL (строка 1440)

### Memory.inc
- строка 141: ReadNum(6) вместо ReadNum(4): аргумент ReadNum - тип, а не размер; 4 = Num_LONG (целое), 6 = Num_SINGLE (rapidq.inc строки 370-376, qmemorystream.html); функция читает SINGLE

### QAVI.inc
- строка 386: строка закрывалась апострофом: было "internal error', стало "internal error"
- строка 405: было END SUB, стало END FUNCTION: закрывает FUNCTION CheckAVIError (строка 366)
- строка 469: было QAVI.fps, стало параметр fps: ограничение 60 должно действовать на параметр, который идёт в .dwRate (строка 475); поле QAVI.FPS здесь не используется
- строка 570: было END SUB, стало END FUNCTION: закрывает FUNCTION CreateAVIFile (строка 453)
- строка 617: было END SUB, стало END FUNCTION: закрывает FUNCTION GetAVIFileInfo (строка 579)
- строка 718: было END SUB, стало END FUNCTION: закрывает FUNCTION AVItoBMP (строка 626)

### QAnimate.inc
- строка 97: FreeResource(iGlobal) вместо FreeResource(iResource): по WinAPI FreeResource принимает дескриптор из LoadResource (строка 91), а не из FindResource

### QDOCKFORM.inc
- строка 7: ALIAS "DefWindowProcA" вместо "DefWindowProc": user32.dll экспортирует только DefWindowProcA/DefWindowProcW (функция в файле не вызывается)
- строка 17: ALIAS "CallWindowProcA" вместо "CallWindowProc": user32.dll экспортирует только CallWindowProcA/CallWindowProcW, как в rapidq.inc строка 1320 (функция в файле не вызывается)
- строка 171: .UndockedForm.Width вместо UndockedForm.Width: без точки внутри WITH THIS это необъявленная переменная (0), форма не центрируется; в inc/rapidq2.inc строка 3476 - .UndockedForm.Width
- строка 172: .UndockedForm.Height вместо UndockedForm.Height - так же, как строкой выше (inc/rapidq2.inc строка 3477)

### QDataBase.inc
- строка 378: было End Sub у Function GetRecord (строка 352)
- строка 417: было End Sub у Function GetRecordUdt (строка 383)
- строка 540: pointer+1 вместо pointer: pointer - сумма размеров предыдущих полей (строки 530-535, отсчёт с 0), а MID$ считает позицию с 1 (документация MID$: MID$("Hello",3,2) = "ll"); было - текст поля со сдвигом на символ влево, у первого поля MID$(...,0,...)
- строка 593: pointer+1 вместо pointer: pointer - сумма размеров предыдущих полей (строки 583-588, отсчёт с 0), а MID$ считает позицию с 1 (документация MID$: MID$("Hello",3,2) = "ll"); было - текст поля со сдвигом на символ влево, у первого поля MID$(...,0,...)

### QDebug.inc
- строка 32: добавлено QDebug.Enabled = EnabledValue: PROPERTY SET сам значение не сохраняет (chapter10.html, пример Set_Focus), а Print (строка 44) проверяет QDebug.Enabled

### QDir.Inc
- строка 649: QDIR_INVALID_HANDLE_VALUE вместо 0: CreateFile при ошибке возвращает INVALID_HANDLE_VALUE = -1, а не 0 (константа объявлена в строке 20 и не использовалась), иначе ненайденный файл не обнаруживался

### QDrawFocus.inc
- строка 230: было y < .Top, стало y < .StartY: как для X в строке 219 (x < .StartX); .Top меняется в строке 231, и при обратном движении рамка получала Bottom < Top

### QDriveCombobox.inc
- строка 25: Super.AddItems вместо QDriveComboBox.AddItems: в типе объявлен свой пустой SUB AddItems (строка 31), он скрывает унаследованный метод (глава 10.3: "you won't be able to access the inherited one... you must explicitly call the SUPER class"), и GetDrives ничего не добавлял; так же super.AddTabs в QtabControlEx.inc строка 40

### QFileDialog.inc
- строка 155: было pdfStrTerm$ (нигде не объявлена, пустая строка), стало fdStrTerm$ (CONST в строке 100); в старой версии inc/old/QFileDialogDoc.inc константа называлась pdfStrTerm$, при переименовании эта строка осталась прежней
- строка 204: было .OFN.nMaxFile, стало .OFN.nMaxFileTitle: копируется буфер имени без пути (lpstrFileTitle), его размер nMaxFileTitle (строки 170-171, 203); nMaxFile - размер другого буфера (строка 169)

### QFlatButton.inc
- строка 44: было (QFlatButton.Height - 1) третьим параметром (x2), стало (QFlatButton.Width - 1): нижняя светлая линия должна идти по ширине кнопки, как тёмная линия в Raise (строка 67)

### QGL.inc
- строка 249: QGL.hDC вместо GL.hDC: внутри TYPE QGL к своим полям везде обращение через QGL. (строки 147, 243); GL - имя переменной программы, работало только при DIM GL AS QGL (c_qgl.html, Notes)
- строка 263: CASE IS < вместо CASE <: сравнение в CASE по документации через IS (conditions.html), как в строке 261; CASE > 5 без IS RapidQ не считает сравнением (тест в RAPIDQ_RULES.md)
- строка 536: Seek(смещение, откуда): по документации QFILESTREAM.Seek (Position%, From%) (qfilestream.html) - аргументы были переставлены
- строка 565: Seek(смещение, откуда): по документации QFILESTREAM.Seek (Position%, From%) (qfilestream.html) - аргументы были переставлены
- строка 575: Seek(смещение, откуда): по документации QFILESTREAM.Seek (Position%, From%) (qfilestream.html) - аргументы были переставлены
- строка 593: Seek(смещение, откуда): по документации QFILESTREAM.Seek (Position%, From%) (qfilestream.html) - аргументы были переставлены
- строка 774: >= вместо => (в документации только >=, operators.html)

### QHTML.inc
- строка 232: tBegin++ вместо tBegin--: цикл пропускает пробелы после "=" перед значением, идти нужно вперёд; с -- tBegin возвращался на "=" и значением атрибута вида name= "x" становилось "="
- строка 378: &sup1; вместо &supl;: сущность HTML - sup1 (верхний индекс 1, байт B9), рядом &sup2; и &sup3;; с буквой l замена не срабатывала
- строка 645: COORDS вместо COORD: у тега AREA атрибут называется COORDS (HTML 4.01), имя атрибута сравнивается целиком (строка 227), и координаты не читались

### QHead.inc
- строка 42: было .IconY: белый текст - вторая половина тени к строке 41 (.IconX +2, .CaptionY), смещение по X на 1, как в строках 44-45; IconY к координате X не относится (копирование)

### QImageEx.inc
- строка 94: было End Sub у Function CanPaste (строка 92); в rapidq2.inc у QImageEx - END FUNCTION

### QLed.inc
- строка 46: END PROPERTY вместо END SUB: процедура открыта как PROPERTY SET SetColor (строка 43); SetState закрыта END PROPERTY (строка 51), так же в документации (chapter10.html, 10.8)

### QMaxSplitter.inc
- строка 211: Rect1 вместо R: глобальная QRECT названа Rect1 (строка 42), её Bottom/Right читаются в строках 158, 162, 216, 220; R нигде не объявлена; в inc/old/QSplitter.inc строка 204 и старой версии везде R

### QProgressBar.inc
- строка 121–122: в строке 122 было .Top, .Left, стало .Left, .Top: у CreateWindowEx сначала x, потом y

### QRedEx.Inc
- строка 174: было len(.seltext) <> "" - число сравнивалось со строкой; нужен 0 (есть выделенный текст)
- строка 182: было len(.seltext) <> "" - число сравнивалось со строкой; нужен 0 (есть выделенный текст)
- строка 375: было () без параметра: в DECLARE (строка 52) и в WinAPI у LockWindowUpdate один параметр, снятие блокировки - LockWindowUpdate(0) (блокировка - строка 364)

### QRichEditXt.inc
- строка 496: .AUTOFONT вместо AUTOFONT: без точки внутри WITH THIS это необъявленная переменная (0), условие всегда истинно; соседние проверки - .HiLight, .AUTOURLDETECT (строки 492, 501)

### QRun.inc
- строка 17: $IFNDEF __WIN32API перенесён со строки 17 на строку 30: DECLARE Run_FindExecutable ... Run_SetWindowPos - свои имена, в Win32 API их нет; при определённом __WIN32API все методы QRun оставались без функций. Под условием должны быть только $DEFINE SW_* (их может задавать Win32 API). В inc/old/object/QRun.inc объявления без условия.
- строка 30: Вторая часть переноса $IFNDEF __WIN32API (см. строку 17); $ENDIF в строке 48 остаётся на месте.

### QSHFileOperation.inc
- строка 85: As Word вместо As Integer: FILEOP_FLAGS - 2 байта, в 32-битном shellapi.h SHFILEOPSTRUCT упакована по 1 байту (pshpack1), TYPE RapidQ тоже без выравнивания. INTEGER RapidQ - 4 байта, поэтому fAnyOperationsAborted, hNameMappings и lpszProgressTitle были сдвинуты на 2 байта (комментарий автора в строке 88: прогресс-заголовок 'Does not work'). Значения флагов (до &H4000) в WORD помещаются.

### QShutdown.inc
- строка 89: This.MyFlag вместо MyFlag: внутри метода поле пишется через This или имя типа (глава 10.3), без него MyFlag - необъявленная локальная переменная (0), и ExitWindowsEx всегда получал 0 = EWX_LOGOFF; так в копии компонента в rapidq2.inc (строки 7777-7797)
- строка 94: This.MyFlag вместо MyFlag: внутри метода поле пишется через This или имя типа (глава 10.3), без него MyFlag - необъявленная локальная переменная (0), и ExitWindowsEx всегда получал 0 = EWX_LOGOFF; так в копии компонента в rapidq2.inc (строки 7777-7797)
- строка 99: This.MyFlag вместо MyFlag: внутри метода поле пишется через This или имя типа (глава 10.3), без него MyFlag - необъявленная локальная переменная (0), и ExitWindowsEx всегда получал 0 = EWX_LOGOFF; так в копии компонента в rapidq2.inc (строки 7777-7797)
- строка 104: This.MyFlag вместо MyFlag: внутри метода поле пишется через This или имя типа (глава 10.3), без него MyFlag - необъявленная локальная переменная (0), и ExitWindowsEx всегда получал 0 = EWX_LOGOFF; так в копии компонента в rapidq2.inc (строки 7777-7797)
- строка 109: This.MyFlag вместо MyFlag: внутри метода поле пишется через This или имя типа (глава 10.3), без него MyFlag - необъявленная локальная переменная (0), и ExitWindowsEx всегда получал 0 = EWX_LOGOFF; так в копии компонента в rapidq2.inc (строки 7777-7797)

### QSocketEx.inc
- строка 101: Family вместо Protocol: третий параметр gethostbyaddr - тип адреса (AF_INET = 2). У QSOCKET по qsocket.html Protocol по умолчанию IPPROTO_IP (0), Family - AF_INET; в RSocket.INC (строка 86) передаётся 2.
- строка 205: Было "' - незакрытая строка (кавычка и апостроф). Значение tstr всё равно задаётся в каждой ветви SELECT CASE (есть CASE ELSE), поэтому пустая строка поведения не меняет.
- строка 289–292: Добавлен END CONSTRUCTOR: после Tag =0 сразу шёл END TYPE (глава 10: CONSTRUCTOR ... END CONSTRUCTOR). Число строк не меняется - занята пустая строка 292.

### QSpinEdit.inc
- строка 100: >= вместо =>: в документации (operators.html) только >=, замена для единообразия, как в других inc

### QToolBar.inc
- строка 488: < .ButtonCount вместо < .ButtonCount -1: иначе последнюю кнопку удалить нельзя; допустимые индексы 0..ButtonCount-1, как проверка в GetCommandID (строка 143)

### QTreeviewEx.inc
- строка 120: .item(i) вместо .item(i).text: внутри WITH sl это QStringList, Item - массив строк (qstringlist.html), у строки нет .text; так же строки 117 и 212

### QVolumeInfo.inc
- строка 113: => заменено на >=, как в документации (operators.html)

### QWave.inc
- строка 189: QWave.FileOpen вместо Wave.FileOpen: объект Wave нигде не объявлен (0), и GetPosition никогда не читал позицию; везде в типе - QWave.FileOpen (строки 81, 108, 130, 203)

### Qcdaudio.inc
- строка 21–25: Declare Sub event_change вынесен из-под $IFNDEF __WIN32API
- строка 99: Убран лишний + перед запятой: было "..."+, - у оператора + нет второго операнда (то же в строках 99, 113, 129, 284; остальные вызовы mciSendCdaudio в файле без +).
- строка 113: Убран лишний + перед запятой: было "..."+, - у оператора + нет второго операнда (то же в строках 99, 113, 129, 284; остальные вызовы mciSendCdaudio в файле без +).
- строка 129: Убран лишний + перед запятой: было "..."+, - у оператора + нет второго операнда (то же в строках 99, 113, 129, 284; остальные вызовы mciSendCdaudio в файле без +).
- строка 284: Убран лишний + перед запятой: было "..."+, - у оператора + нет второго операнда (то же в строках 99, 113, 129, 284; остальные вызовы mciSendCdaudio в файле без +).

### Qid3Tag.inc
- строка 93: было filename без имени типа — необъявленная переменная (всегда ""), стало Qid3tag.filename, как в строках 98 и 122 (chapter10.html)
- строка 117: было filename без имени типа — необъявленная переменная (всегда ""), стало Qid3tag.filename, как в строках 98 и 122 (chapter10.html)

### Qmp3.inc
- строка 70: было mp3.filename - глобальный объект mp3 нигде не объявлен ($typecheck on); имя файла компонента - Qmp3.filename, как в строках 93, 381, 412
- строка 76: было bb = 256: BYTE не бывает 256, синхронизация кадра mp3 - байт &HFF (255), затем байт > 223 (строка 78)
- строка 103: было mp3.filename - глобальный объект mp3 нигде не объявлен ($typecheck on); имя файла компонента - Qmp3.filename (строка 93)
- строка 171: было "320" дважды: в таблице MPEG-1 Layer II 14 значений (32 ... 320, 384), из-за повтора индекс 13 давал 320 вместо 384
- строка 420–421: строки 420-421: было tagstream - это локальный поток SUB readtags; в writetags открыт wtagstream (строка 418)

### RapidQ_D3D.inc
- строка 258: было (a, b, Norm), в DECLARE (строка 257) - (Norm, a, b); RapidQ берёт параметры из DECLARE, поэтому работа не меняется, заголовок приведён к DECLARE (результат первым, как у D3DRMVectorCrossProduct)
- строка 483: было null - не объявлен (файл только делает $UNDEF null в конце), при $TYPECHECK ON (строка 16) - ошибка; поле STRING, нужна пустая строка
- строка 895: '< =' с пробелом -> документированный оператор '<='
- строка 964: было null - не объявлен (файл только делает $UNDEF null в конце), при $TYPECHECK ON (строка 16) - ошибка; поле STRING, нужна пустая строка
- строка 990: было null - не объявлен (файл только делает $UNDEF null в конце), при $TYPECHECK ON (строка 16) - ошибка; поле STRING, нужна пустая строка

### SysUtils.inc
- строка 110: было (a or b) shl 16 - младшее слово тоже сдвигалось и смешивалось со старшим; MAKELONG Windows: a - младшее слово, b - старшее (так вызывается в QAnimate.inc: MakeLong(.StartFrame,.StopFrame) для ACM_PLAY)

### VFW.inc
- строка 928: было SUB ... AS LONG с RESULT внутри и END SUB (строка 945); стало FUNCTION, как SetImageHeight (строка 902): результат используется в конструкторе, строка 1128
- строка 936: было EXIT SUB, стало EXIT FUNCTION: SetImageWidth - FUNCTION (строка 928)
- строка 945: было END SUB, стало END FUNCTION: SetImageWidth - FUNCTION (строка 928)
- строка 999: было END SUB, стало END FUNCTION: блок открыт FUNCTION ShowDialogBox (строка 975)

### XPSkinMetallic_2.11_Res.inc
- строка 787: было «.Croped (.ToujoursVisible or ...)» без оператора между условиями, стало «.Croped and (...)»: ветка восстанавливает свёрнутую форму (строка 788 ставит .Croped=0), так же как строки 1269 и 1452
- строка 959–960: =< заменено на <= в строке 959 (строкой выше), как в документации (operators.html)
- строка 1272–1273: =< заменено на <= в строке 1272 (строкой выше), как в документации (operators.html)

### XP_MANIFEST.INC
- строка 57: >= вместо => (в документации только >=)

### conversion.inc
- строка 279–280: в функции AddChrAfter было присваивание AddChrBefore (копия из AddChrBefore, строки 264-265), стало AddChrAfter - иначе результат функции не задаётся
- строка 974: было ConvertCodePage = ... (такой функции нет, необъявленная переменная), стало ConvertCodePage2 - имя этой функции (строка 949), иначе она возвращает пустую строку

### eml.inc
- строка 67–71: MsgBody вместо Msg в теле функции

### odbc.inc
- строка 207: убран пробел в начале (было " NUMERIC"; остальные названия типов в этом SELECT без пробела)

### parse.inc
- строка 41: next ~i вместо next i: счётчик цикла строки 30 - ~i (так же в GetOperators, строка 261); i здесь нигде не присваивается

### qcalendar.inc
- строка 5: было "apidate.bas" — такого файла нет, функции weekday, lastdaym, SYSTEMTIME, GetDateFormat, GetLocaleInfo есть в ApiDate.inc того же автора (inc2026)
- строка 159: было до grid.colcount+1 (=9 при ColCount=8, строка 378), стало до 7: массив week(1 TO 7) (строка 153), дней в неделе 7, столбцы 0..6

### qdirlistview/qdirlistview.inc
- строка 151: PointPlace вместо PontPlace: дальше (строки 155, 157) используется PointPlace, а объявлена другая переменная
- строка 181: QDirListView.ColumnsInitialized вместо ColumnsInitialized: без имени типа внутри TYPE это отдельная необъявленная переменная, а поле (строка 52) задаётся в CONSTRUCTOR (строка 317)
- строка 216: QDirListView.ColumnsInitialized - так же, как в строке 181

### qftpdirlistview/qftpdirlistview.inc
- строка 201: PointPlace вместо PontPlace: объявлена PontPlace, а присваивается и проверяется PointPlace (строки 205, 207); то же в inc/qdirlistview.inc

### qgraph.inc
- строка 104: было textwidth(.YTitle), стало .XTitle: строка выводит XTitle и центрируется по его ширине, как заголовок в строке 102
- строка 107: было AxisColour без точки — необъявленная переменная (0), стало .AxisColour — поле типа (строка 47); в методах поля пишутся через имя типа или WITH (chapter10.html)
- строка 108: было AxisColour без точки — необъявленная переменная (0), стало .AxisColour — поле типа (строка 47); в методах поля пишутся через имя типа или WITH (chapter10.html)
- строка 135: было AxisColour без точки — необъявленная переменная (0), стало .AxisColour — поле типа (строка 47); в методах поля пишутся через имя типа или WITH (chapter10.html)
- строка 136: было AxisColour без точки — необъявленная переменная (0), стало .AxisColour — поле типа (строка 47); в методах поля пишутся через имя типа или WITH (chapter10.html)
- строка 140: было AxisColour без точки — необъявленная переменная (0), стало .AxisColour — поле типа (строка 47); в методах поля пишутся через имя типа или WITH (chapter10.html)
- строка 141: было AxisColour без точки — необъявленная переменная (0), стало .AxisColour — поле типа (строка 47); в методах поля пишутся через имя типа или WITH (chapter10.html)
- строка 145: было ExtrapolateToZero без точки — необъявленная переменная (0), стало .ExtrapolateToZero — поле типа (строка 46, по умолчанию 1)
- строка 146–147: в строке 147 было Cell(0,i) и Cell(1,i) — i осталось после цикла по шкале Y (строка 139), стало строка 0: линия от начала координат к первой точке

### qmenu.inc
- строка 52–53: строки 52-53 переставлены: было END IF, затем END WITH - WITH mii открыт внутри ELSE (строка 48) и должен закрыться до END IF
- строка 164: было '= =' - лишний знак равенства

### rapidq2.inc
- строка 1348: CDS_TEST было &H4 (это значение CDS_FULLSCREEN), в Windows SDK (winuser.h) CDS_TEST = &H2; Screen.SetResolution (строка 7860) вместо проверки режима сразу его включал
- строка 4634: AND в RapidQ побитовый (operators.html: 5 AND 3 = 1): (NViewLibPresent AND 2) = 2, а INSTR для .JPG даёт 1, для .JPEG - 5, 2 AND 1 = 0 - jpeg.dll не использовался; добавлено сравнение INSTR(...) > 0 (-1), 2 AND -1 = 2
- строка 4859: AND в RapidQ побитовый (operators.html: 5 AND 3 = 1): (NViewLibPresent AND 2) = 2, а INSTR для .JPG даёт 1, для .JPEG - 5, 2 AND 1 = 0 - jpeg.dll не использовался; добавлено сравнение INSTR(...) > 0 (-1), 2 AND -1 = 2
- строка 7557: SetSuspendState(Hibernate, ...): первый параметр TRUE - гибернация, FALSE - сон (MSDN); у sysHibernate* стоял 0, у sysSleep* - 1, перепутано; 0 -> 1
- строка 7559: SetSuspendState(Hibernate, ...): первый параметр TRUE - гибернация, FALSE - сон (MSDN); у sysHibernate* стоял 0, у sysSleep* - 1, перепутано; 0 -> 1
- строка 7561: SetSuspendState(Hibernate, ...): первый параметр TRUE - гибернация, FALSE - сон (MSDN); у sysHibernate* стоял 0, у sysSleep* - 1, перепутано; 1 -> 0
- строка 7563: SetSuspendState(Hibernate, ...): первый параметр TRUE - гибернация, FALSE - сон (MSDN); у sysHibernate* стоял 0, у sysSleep* - 1, перепутано; 1 -> 0

## Вопросы (в файлы не внесено, нужна проверка в RapidQ или решение)

### COMPORTxp.inc
- строка 290: StopBits = 1 по умолчанию, а по константам (строки 94-96) 1 = ONE5STOPBITS (1,5 стоп-бита), 1 стоп-бит - ONESTOPBIT = 0. При 8 битах данных 1,5 стоп-бита SetCommState обычно не принимает. Так же в ComPort.inc; возможно, нужно ONESTOPBIT.
- строка 359–365: FILE_SHARE_READ, FILE_SHARE_WRITE, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL закомментированы в строках 111-120 (в ComPort.inc они объявлены). Без include, где они есть (windows.inc/rapidq2.inc), они равны 0, и CreateFile с dwCreationDisposition = 0 не откроет порт. Проверить, с каким include предполагается этот файл.

### CallBack_0.Inc
- строка 52: CallFunc (hBind, hBind) передаёт один параметр (шаблон FuncBind_0 объявлен с одним параметром, "Bind dont work with no Arg function"), а процедура программы для _0 параметров не имеет: при stdcall она не снимет 4 байта со стека. Нужно проверить в RapidQ, восстанавливает ли CALLFUNC стек; файл автором не проверялся.

### ComPort.inc
- строка 290: StopBits = 1 по умолчанию: в DCB 1 = ONE5STOPBITS (1,5 стоповых бита, строки 43 и 95), а не один стоп-бит (ONESTOPBIT = 0). С DataBits = 8 Windows такую комбинацию обычно отвергает (SetCommState). Вероятно, нужно ONESTOPBIT; но программы пользователя могут задавать StopBits сами - решить пользователю.
- строка 372: FILE_ATTRIBUTE_NORMAL закомментирован (строка 120) - без windows.inc это необъявленная переменная, 0. Для CreateFile 0 допустим, вызов работает; можно раскомментировать константу.
- строка 451: ComPort.Connected = TRUE (и FALSE в строках 295, 477): TRUE/FALSE в файле не определены - без rapidq.inc это 0, и Connected после успешного Open остаётся 0. Проверить, что программы с ComPort подключают rapidq.inc.

### Files.inc
- строка 52–53: не внесено: `Long_` в конце строки — перенос, такая запись встречается в User32.inc, WINDOWS.INC, Kernel32.inc (`Alias_`); правка была бы только оформлением. (предлагалось: пробел перед _ строкой выше (было Long_ - знак переноса слит с именем, в документации перенос через " _"))
- строка 61–62: не внесено: `Long_` в конце строки — перенос, такая запись встречается в User32.inc, WINDOWS.INC, Kernel32.inc (`Alias_`); правка была бы только оформлением. (предлагалось: пробел перед _ строкой выше (было Long_ - знак переноса слит с именем, в документации перенос через " _"))
- строка 947: Активные PRINT/LOCATE в библиотечных процедурах (строки 947, 1226, 1245, 1264-1265). По документации (chapter3.html, $APPTYPE) без $APPTYPE RapidQ сам определяет тип программы по исходнику - PRINT может сделать GUI-программу консольной. Похоже на оставленную отладку; закомментировать или нет - решить пользователю.
- строка 1458: ByVal 0& в вызове функции - запись VB; в документации RapidQ BYVAL только в объявлении параметров. Если rc не принимает - заменить на 0. vbNullString в файле не объявлена (будет 0).

### Memory.inc
- строка 46: ReAllocate: новый размер PtrSize(P&)*Count& - текущий размер блока, умноженный на Count&. По имени параметра ожидался бы размер Count& (или Count& элементов); проверить, как функцию вызывают.

### QBitmapEx.inc
- строка 22–23: В BITMAP (WinAPI) bmPlanes и bmBitsPixel - WORD, здесь Integer (4 байта): структура 28 байт вместо 24, bmBitsPixel и bmBits смещены. Используются только bmWidth/bmHeight - на работу не влияет. В VFW.inc (TBITMAP) эти поля WORD.

### QBrowseDialog.inc
- строка 80–81: MAX_PATH объявлен в строке 38 закомментированным, в rapidq.inc и rapidq2.inc его нет (есть в WINDOWS.INC, WIN32API.INC). Без них MAX_PATH - необъявленная переменная = 0 и STRING*0 - буфер для SHGetPathFromIDList нулевой длины. Решить: раскомментировать CONST в строке 38 (с $IFNDEF) или оставить требование подключать WINDOWS.INC.

### QCanvasEx.inc
- строка 22–23: TBITMAP: bmPlanes и bmBitsPixel объявлены AS INTEGER (4 байта), в Windows BITMAP это WORD (2 байта) - структура 28 байт вместо 24 и bmBits не на своём месте. Используются только bmWidth/bmHeight (стоят до этих полей), поэтому на работу не влияет. То же в QImageBox.inc и QImageDialog.inc.
- строка 144–148: CopyToClipboard: после clipboard.SetAsHandle(CF_BITMAP, hBitmap) битмап удаляется DeleteObjectCan(hBitmap) (строка 148). По правилам Windows (SetClipboardData) после передачи владеет буфер обмена, объект удалять нельзя - картинка в буфере может оказаться недействительной. Зависит от того, копирует ли SetAsHandle RapidQ данные; проверить.

### QChart.inc
- строка 2188–2193: AutoScale объявлено AS BYTE (строка 168), а у BYTE по datatypes.html диапазон 0..255. В строках 2169/2172 туда пишется NOT 1 = -2, при переносе по разрядности это 254, поэтому сравнение с -2 никогда не выполнится и после печати автомасштаб не включится обратно. Скорее всего нужно сравнивать с 254 (или не трогать сравнение, а запомнить старое значение в отдельной переменной). Что RapidQ записывает в BYTE при отрицательном значении, тестом не проверялось (проверен только перенос положительных: b?=300 -> 44) - проверить в RapidQ: DIM b AS BYTE : b = NOT 1 : PRINT b, (b = -2).
- строка 2325: Parent присваивается имя класса QFORM, а не объект формы. Тот же приём в QSkinBtn.inc (show.parent=qform). Проверить в RapidQ, принимает ли rc.exe имя класса справа и что получается (родитель - последняя созданная форма или 0). В заголовке файла (строка 20) сказано, что Parent задаёт пользователь, поэтому на работу это, видимо, не влияет.

### QColorDialog.inc
- строка 29: CustColors(1 TO 16) AS LONG внутри TCHOOSECOLOR: у API CHOOSECOLOR здесь указатель lpCustColors на массив, а не сам массив (lStructSize должен быть 36). В rapidq2.inc строка 1595 то же поле помечено «this is wrong, API expects pointer to array». Проверить в RapidQ, работает ли диалог; исправление требует указателя на массив цветов.

### QCoolBarXPv1d.inc
- строка 1824: Проверка попадания в поле Edit: Y >= .ED_Left(J) and Y <= .ED_Left(J) - верхняя граница равна нижней, вероятно нужно .ED_Left(J) +.ED_Width(J). То же для CB_ в строке 1834 и по X в строках 1851, 1861 - проверить
- строка 2261: OnChange = CBarOnChange_EventTemplate - у этой SUB есть только DECLARE (строка 702), тела нет; CALLFUNC(.OnChange, ...) (строки 1358, 2030) вызовет её, если программа не назначила свой обработчик. Проверить, что делает RapidQ в этом случае

### QDOCKFORM.inc
- строка 272: Нижняя граница FillRect - .Canvas.Width - 16 - 10 + 16 (ширина вместо высоты, похоже на копию третьего параметра); то же в строках 338, 489, 552 и в inc/rapidq2.inc. Вероятно, задумано 12 + 16 (или 6 + 16) - высота кнопки закрытия; проверить в RapidQ, не затирается ли лишняя область холста.

### QDataBase.inc
- строка 88–90: GetFieldCount даёт 0, если в формате записи одно поле (нет запятой), хотя GetRecordSize это поле считает; тогда GetFieldName/GetFieldSize ничего не возвращают. Возможно, задумано result=tally(Record,",")+1 для непустой строки - проверить, нужно ли менять

### QDebug.inc
- строка 32: True в файле не определён (нет $DEFINE True и $INCLUDE RAPIDQ.INC). Без rapidq.inc True — необъявленная переменная 0, и окно отладки не показывается. Другие файлы задают «$IFNDEF TRUE: $DEFINE True 1».

### QDir.Inc
- строка 241: lblDirStop.Font.Bold = True - True в файле не определён; без rapidq.inc это 0 и надпись не жирная. Мелочь, проверить подключение rapidq.inc.

### QDrawMenu.inc
- строка 231–317: После END TYPE не закомментирован пример ($TYPECHECK ON, $RESOURCE, CREATE Form, Form.ShowModal, SUB Show/MenuItemClick) - при $INCLUDE файла пример компилируется и запускается. Решить, закомментировать ли его или вынести в .bas.

### QFTPCLIENT.INC
- строка 120–122: не внесено: как RapidQ передаёт запись в параметр DLL, объявленный As Long (адрес или копию), в документации не сказано; если адрес — прежнее объявление работает. (предлагалось: lpFindFileData As QFTP_WIN32_FIND_DATA вместо As Long: в строке 541 передаётся запись .WIN32_FIND_DATA (при $TYPECHECK ON), FtpFindFirstFileA ждёт адрес структуры WIN32_FIND_DATA; так же объявлен QFTP_InternetFindNextFile (строка 125). Запись RapidQ передаёт по ссылке (глава 3.5).)

### QFileListView.inc
- строка 134: instr(File,".",0) - по документации INSTR([start,] search-string, find-string), начальная позиция - первый параметр. Так же в строке 144 и в qdirlistview.inc, qftpdirlistview.inc. Проверить, как rc.exe понимает третий числовой параметр; по смыслу нужно instr(File,".").

### QGL.inc
- строка 5: $INCLUDE <\GL\gl.inc> начинается с обратной косой черты (строка 6 - <GL\glu.inc> без неё); \GL\... может пониматься как путь от корня диска. Файлов GL\gl.inc и GL\glu.inc в inc2026 нет.
- строка 331: QGLinternalBMP.Pointer: у QBITMAPEX в inc2026/QBitmapEx.inc нет члена POINTER (есть в издании QBITMAPEX из rapidq2.inc, c_qbitmapex.html). С QBitmapEx.inc строки 323 и 331 не соберутся.
- строка 345–348: Приоритет: AND выше OR (operators.html), поэтому проверка NViewLibPresent относится только к .PCX, а JPG/TGA/GIF всегда идут в LoadOtherImage. NViewLibPresent в файле не объявлена (0). Вероятно, задумано (A OR B OR C OR D) AND NViewLibPresent - но тогда без NViewLibPresent JPG пойдут в LoadFromFile. Логику не менял.
- строка 550: QMD2model вызывает GL.CreateTextureFromFile - нужна глобальная переменная программы GL AS QGL (так и написано в c_qmd2model.html). Не ошибка синтаксиса, но жёсткая зависимость от имени.
- строка 736: CreateAnimationSet передаёт This.skins(1) (номер текстуры OpenGL) как индекс скина theSkin, а DrawMD2 снова берёт This.skins(theSkin) - двойная индексация (отмечено в c_qmd2model.html). Вероятно, нужен индекс 0 (или 1); как задумано - неизвестно.
- строка 761: FPS объявлено AS SINGLE PROPERTY SET MD2_Set_FPS (строка 497), а MD2_Set_FPS написана как SUB ... END SUB, не PROPERTY SET ... END PROPERTY (chapter10.html, 10.8). Принимает ли rc SUB как установщик - проверить в RapidQ.

### QHTML.inc
- строка 1397: Event Image.OnMouseUp(Button, x, y, shift, Cancel as integer): у QImage.OnMouseUp по документации 4 параметра (qimage.html: Button%, X%, Y%, Shift%); пятый Cancel и присваивание Cancel = 1 ничего не дают. Проверить, принимает ли RapidQ лишний параметр обработчика.

### QICMP.INC
- строка 89–101: ReplyAddress (и ReplyTTL, строки 144-145) берёт байты из HEX$ по фиксированным позициям 1,3,5,7; HEX$ без ведущих нулей даёт меньше 8 цифр (например, адрес с младшим байтом меньше 16), и адрес/TTL получаются неверными. Нужно дополнять строку нулями слева до 8 знаков - проверить HEX$ в RapidQ.

### QImageBox.inc
- строка 30–31: TBITMAP_IMGBOX: bmPlanes/bmBitsPixel AS INTEGER вместо WORD (BITMAP Windows) - сдвигает bmBits; используются только bmWidth/bmHeight, на работу не влияет.

### QImageDialog.inc
- строка 30–31: TBITMAP_IMG: bmPlanes/bmBitsPixel AS INTEGER вместо WORD (BITMAP Windows) - сдвигает bmBits; используются только bmWidth/bmHeight, на работу не влияет.

### QInputBox.inc
- строка 82: SetFocus вызывается, но его DECLARE закомментирован (строка 3), а в начале файла $Typecheck on. В rapidq.inc SetFocus не объявлен (объявлен в qdirlistview.inc). Если программа сама не объявляет SetFocus, RapidQ, вероятно, не скомпилирует; проверить и при необходимости раскомментировать DECLARE.

### QLedScroll.inc
- строка 18: В методе Rewind вызывается TextWidth(this.Text) без This./имени типа; по главе 10 внутри TYPE имя без This - переменная (кроме CONSTRUCTOR). Проверить в RapidQ, вызывается ли метод QCanvas.TextWidth; если нет - нужно this.TextWidth(this.Text).

### QMarker.inc
- строка 16: Цикл for i = 0 to .Height идёт по пикселям высоты, а массив Row(200) - 201 панель; при Height > 200 выход за границы. Вычисленное в строке 15 NoRow (число строк) не используется - видимо, задумано for i = 0 to NoRow. Кроме того, в CONSTRUCTOR RowHeight не задан (строка 44 закомментирована), и .Height / .RowHeight - деление на 0. Проверить в RapidQ.

### QMaxSplitter.inc
- строка 37–41: DIM SplitPos/OldSplitPos/OldWhere/Org AS POINTAPI стоят до TYPE POINTAPI (строка 52, внутри $IFNDEF __WIN32API). В старой версии (inc/old/QMaxSplitter.inc.txt) TYPE POINTAPI был выше этих DIM. Без windows.inc (__WIN32API не определён) RapidQ, вероятно, не знает тип в строке 38. Предложение: перенести блок $IFNDEF __WIN32API ... $ENDIF (строки 51-73) выше строки 37; проверить компиляцией в RapidQ.

### QProgress.inc
- строка 194: ".Increment + = .StepSize" - в документации (troubles.html) оператор пишется слитно: I += 15. Принимает ли rc.exe "+ =" с пробелом, не проверено; то же в строке 206. Если нет - заменить на +=.
- строка 257: DO : LOOP UNTIL .Visible = TRUE - поле Visible имеет PROPERTY SET SetVisible, установщик значение не сохраняет (SUPER.Visible в строке 268 - другое свойство), в конструкторе Visible = FALSE. При UseThreading и Kind > 4 цикл, вероятно, бесконечный; так же LOOP UNTIL (.Visible = FALSE) в строке 218 никогда не завершится сам. Проверить в RapidQ.

### QProgressBar.inc
- строка 167: SetWindowPos с SWP_NOSIZE: Width и Height, заданные после создания окна (SetWidth, SetHeight вызывают ReDraw), не применяются. Если нужно менять размер, флаг должен быть только SWP_NOZORDER.
- строка 175: Свойства Parent, Max, Min, Position объявлены «PROPERTY SET SetXxx» (строки 98, 104, 105, 108), а обработчики написаны как SUB, не PROPERTY SET. Кроме того, метод SetParent совпадает по имени с API SetParent (строка 26), который вызывается в строке 182. Проверить в RapidQ.

### QRedEx.Inc
- строка 209: EM_CHARFROMPOS получает Varptr(ptPoint) + 2: после EM_GETRECT в буфере RECT (left, top, right, bottom по 4 байта), правый нижний угол начинается со смещения 8, а не 2. Со смещением 2 точка получается примерно (0, right*65536) - то есть начало нижней строки, а не правый нижний символ. Так же в строке 233 (BottomLineIndex - там номер строки тот же). Проверить, не задумано ли +8.

### QRichEditXt.inc
- строка 222: не внесено: `END PROPERTY SET` встречается и в других файлах (inc/QxEdit.inc, inc/old/qEditEx.inc), RapidQ, по-видимому, его принимает. В QHTML.inc такая замена уже сделана раньше — она безвредна. (предлагалось: END PROPERTY вместо END PROPERTY SET (так в документации, глава 10.8))
- строка 229: не внесено: `END PROPERTY SET` встречается и в других файлах (inc/QxEdit.inc, inc/old/qEditEx.inc), RapidQ, по-видимому, его принимает. В QHTML.inc такая замена уже сделана раньше — она безвредна. (предлагалось: END PROPERTY вместо END PROPERTY SET (так в документации, глава 10.8))
- строка 237: не внесено: `END PROPERTY SET` встречается и в других файлах (inc/QxEdit.inc, inc/old/qEditEx.inc), RapidQ, по-видимому, его принимает. В QHTML.inc такая замена уже сделана раньше — она безвредна. (предлагалось: END PROPERTY вместо END PROPERTY SET (так в документации, глава 10.8))
- строка 245: не внесено: `END PROPERTY SET` встречается и в других файлах (inc/QxEdit.inc, inc/old/qEditEx.inc), RapidQ, по-видимому, его принимает. В QHTML.inc такая замена уже сделана раньше — она безвредна. (предлагалось: END PROPERTY вместо END PROPERTY SET (так в документации, глава 10.8))
- строка 251: не внесено: `END PROPERTY SET` встречается и в других файлах (inc/QxEdit.inc, inc/old/qEditEx.inc), RapidQ, по-видимому, его принимает. В QHTML.inc такая замена уже сделана раньше — она безвредна. (предлагалось: END PROPERTY вместо END PROPERTY SET (так в документации, глава 10.8))
- строка 258: не внесено: `END PROPERTY SET` встречается и в других файлах (inc/QxEdit.inc, inc/old/qEditEx.inc), RapidQ, по-видимому, его принимает. В QHTML.inc такая замена уже сделана раньше — она безвредна. (предлагалось: END PROPERTY вместо END PROPERTY SET (так в документации, глава 10.8))
- строка 280–281: HiLiteFont нигде не объявлен (ни поле TYPE, ни DIM) - HiLiteFont.Handle и HiLiteFont.color дают 0 или ошибку компиляции. Нужно поле шрифта подсветки (например HiLiteFont AS QFONT) или .Font; решить автору.
- строка 337: не внесено: компонент рассчитан на глобальный объект программы с именем RichEdit (как и HiLiteFont), так написано в c_qrichedit_xt.html; замена на .Handle/.line(i) меняет устройство компонента. (предлагалось: .Handle вместо RichEdit.Handle: объекта RichEdit нет (тип называется QRichEdit_xt), окно - сам компонент (hWnd = .Handle, строка 264))
- строка 343: не внесено: компонент рассчитан на глобальный объект программы с именем RichEdit (как и HiLiteFont), так написано в c_qrichedit_xt.html; замена на .Handle/.line(i) меняет устройство компонента. (предлагалось: .line(i) вместо richedit.line(i): объекта RichEdit нет, строки берутся у самого компонента (как .Handle в строке 337))
- строка 345: не внесено: компонент рассчитан на глобальный объект программы с именем RichEdit (как и HiLiteFont), так написано в c_qrichedit_xt.html; замена на .Handle/.line(i) меняет устройство компонента. (предлагалось: .line(i) вместо richedit.line(i): объекта RichEdit нет, строки берутся у самого компонента (как .Handle в строке 337))
- строка 351: EM_POSFROMCHAR: запись VisPoint1 (TYPE Point) передаётся в параметр wParam, объявленный AS LONG (строка 171); так же .ScrollPoint в строках 221, 490. Неясно, передаёт ли RapidQ в LONG адрес записи; в строках 285-300 для того же сделано через QMemoryStream (M.Pointer). Проверить, что координаты приходят.
- строка 355: не внесено: компонент рассчитан на глобальный объект программы с именем RichEdit (как и HiLiteFont), так написано в c_qrichedit_xt.html; замена на .Handle/.line(i) меняет устройство компонента. (предлагалось: .line(i) вместо richedit.line(i): объекта RichEdit нет, строки берутся у самого компонента (как .Handle в строке 337))
- строка 357: не внесено: компонент рассчитан на глобальный объект программы с именем RichEdit (как и HiLiteFont), так написано в c_qrichedit_xt.html; замена на .Handle/.line(i) меняет устройство компонента. (предлагалось: .line(i) вместо richedit.line(i): объекта RichEdit нет, строки берутся у самого компонента (как .Handle в строке 337))
- строка 408: не внесено: компонент рассчитан на глобальный объект программы с именем RichEdit (как и HiLiteFont), так написано в c_qrichedit_xt.html; замена на .Handle/.line(i) меняет устройство компонента. (предлагалось: .line(i) вместо richedit.line(i): объекта RichEdit нет, строки берутся у самого компонента (как .Handle в строке 337))
- строка 409: не внесено: компонент рассчитан на глобальный объект программы с именем RichEdit (как и HiLiteFont), так написано в c_qrichedit_xt.html; замена на .Handle/.line(i) меняет устройство компонента. (предлагалось: .line(i) вместо richedit.line(i): объекта RichEdit нет, строки берутся у самого компонента (как .Handle в строке 337))
- строка 475: не внесено: компонент рассчитан на глобальный объект программы с именем RichEdit (как и HiLiteFont), так написано в c_qrichedit_xt.html; замена на .Handle/.line(i) меняет устройство компонента. (предлагалось: .line(i) вместо richedit.line(i): объекта RichEdit нет, строки берутся у самого компонента (как .Handle в строке 337))
- строка 497: & в RapidQ - сложение (operators.html), не AND: GETLANGOPTIONS + (-2) вычитает 2 и правильно снимает IMF_AUTOFONT, только если этот бит был установлен. Задумано, видимо, ... AND NOT IMF_AUTOFONT; проверить.
- строка 506: CODEPTR(This.Proc) - адрес метода TYPE; у метода есть скрытый This, Windows его не передаст (RAPIDQ_RULES: «Метод своего компонента ... ошибка перевода»; другие компоненты строят переходник через BIND + SetNewCallBack_4). Проверить в RapidQ, вызывается ли Proc вообще.

### QSavePlus.inc
- строка 223–282: После END TYPE не закомментирован пример: CREATE form, CREATE saveDlg, form.ShowModal - при $INCLUDE файла пример компилируется и запускается. Также файл включает $ESCAPECHARS ON и CONST false/true для всей программы, а mtConfirmation, mbYes, mrYes и др. берёт из rapidq.inc (строки 28-34 закомментированы). Решить, оставлять ли пример (закомментировать или вынести в отдельный .bas).

### QSkinBtn.inc
- строка 110: Родителем внутреннего QCANVAS show назначается имя класса qform, а не форма. От этого зависит Show.OnPaint (строки 95-106), который выбирает картинку. Проверить в RapidQ, что даёт такое присваивание (тот же приём в QChart.inc строка 2325).

### QSocketEx.inc
- строка 166: SUB объявлена с типом результата As LONG, хотя ничего не возвращает. Проверить, принимает ли rc.exe 'SUB ... As LONG'; если нет - убрать ' As LONG'. Переводчик эту часть отбросил.

### QTButton95.inc
- строка 383–384: Для 'вперёд' (стрелки вниз/вправо, Tab) вызывается NextDlg_QTBtn(True), а это параметр bPrevious у GetNextDlgTabItem (строка 245): TRUE - предыдущий элемент. Похоже, True и False перепутаны; проверить в RapidQ, куда переходит фокус.
- строка 1272: не внесено: `Height2 <> Bitmap1.Width` похоже на опечатку, но всё условие перерисовки собрано через AND и не совпадает с комментарием автора; правка может убрать часть перерисовок. (предлагалось: было Height2 <> Bitmap1.Width - высоту сравнивали с шириной (копирование); пары Width/Width и Height/Height, как в строке 1271 и в закомментированной строке 1265)
- строка 1430–1431: CloseThemeData_QTBtn hTheme вызывается дважды подряд (и при hTheme = 0). Второй вызов закрывает уже закрытый handle; вероятно, лишняя строка. Так же в старых версиях QTButton94.inc/94b.inc.

### QTextBtn.inc
- строка 23: PROPERTY SET SetEnabled нигде в типе нет (то же в inc/old/object/QTextBtn.inc); fbc: 'Element not defined, SetEnabled'. Проверить в RapidQ, компилируется ли файл. Варианты исправления: добавить установщик по образцу QSkinBtn.inc (строки 35-40) - 'Property Set SetEnabled(value as boolean) / QTextBtn.Enabled=value / Super.Enabled=value / End Property' (SetDown проверяет super.Enabled), либо убрать строку 23, чтобы работало унаследованное Enabled от QLABEL.

### QVideo.inc
- строка 262: instr(,mediadim," ") — первый аргумент (начальная позиция) пустой. Проверить, принимает ли rc.exe; иначе instr(mediadim," ") или instr(1,mediadim," ").

### QVolumeInfo.inc
- строка 64: «Private Declare Function» вне TYPE — синтаксис VB; в документации RapidQ DECLARE без Private. Проверить, принимает ли rc.exe.

### QWave.inc
- строка 129: SetFrequence принимает WV_KHZ8, WV_KHZ11, WV_KHZ44, но не WV_KHZ22 (константа объявлена в строке 28) - похоже на пропуск; так же во всех версиях файла. Добавлять ли "or freq=WV_KHZ22"?

### QXPButton.inc
- строка 228–231: True и False используются (строки 228, 231, 269, 271, 310, 313), но в файле не определены - в отличие от QTextBtn/QSkinBtn и др., где есть $IFNDEF TRUE / $DEFINE True 1. Без rapidq.inc или rapidq2.inc (они подключены в примерах в конце файла) оба слова - необъявленные переменные со значением 0, и This.Visible = True в строке 271 оставит кнопку скрытой. Решить: считать файл зависимым от rapidq.inc/rapidq2.inc (записать в Requires) или добавить в начало блоки $IFNDEF TRUE / $DEFINE True 1 и $IFNDEF FALSE / $DEFINE False 0, как в соседних компонентах.

### Qid3Tag.inc
- строка 110–111: tagstream.readbyte(1) и writebyte (строки 129-130): в qfilestream.html у QFILESTREAM нет ReadByte и WriteByte, есть ReadNum(Num_BYTE) и WriteNum(число, 1). Проверить в RapidQ, есть ли недокументированные методы.

### Qmp3.inc
- строка 176–182: Таблица битрейтов MPEG-2/2.5 Layer III ("8","16","24","32","64","80","56","64","128","160","112","128","256","320") не совпадает со стандартом (8,16,24,32,40,48,56,64,80,96,112,128,144,160). Это больше чем опечатка - решить, заменять ли таблицу.

### RapidFRM.inc
- строка 246: SendMessageAPI объявлен в rapidq2.inc с lParam As Long, а передаётся запись TabHdr (TabTCITEMHEADER). Нужен адрес записи; проверить, передаёт ли RapidQ адрес записи в параметр Long, или нужно VARPTR(TabHdr).

### RapidQ_D3D.inc
- строка 436: MouseNotDown нигде не объявлен, при $TYPECHECK ON - ошибка компиляции, если программа сама его не определит. Значение неизвестно (комментарий: 'can't use false'); нужно решить, какую константу объявить.
- строка 538–542: MakeHorizPlane берёт z вершин как -1 и 1 без zc (zc = DrawCenter.z вычисляется в строке 535 и не используется), в отличие от MakeVertZPlane (-1+zc, 1+zc). Возможно, пропущено +zc.
- строка 650–682: MakePyramid вызывает CreateFace один раз, а затем добавляет вершины всех четырёх граней в тот же Face после AddFace. В остальных Make* перед каждой гранью CreateFace (комментарий 'recreate to null prior faces'). Проверить, не нужен ли CreateFace перед каждой гранью.

### TstRichEd.inc
- строка 5: Declare Function LINEINDEX as long — глобальное объявление без LIB и без тела; функция определена только как метод TestEDIT (строка 8). Проверить, не мешает ли rc.exe; вероятно, строку можно убрать. Также строки 13-14 подменяют QRICHEDIT на QMAXEDIT для всего кода после include.

### VFW.inc
- строка 488: В SendMessageAPI параметр lParam объявлен As Long (строка 105), а сюда передаётся строка szBuffer (так же в строках 498, 519, 674), в строках 506, 534, 546, 582, 610, 614, 654, 658 - запись TYPE. Проверить в RapidQ, передаёт ли он в этом случае адрес; если нет, нужен VARPTR(szBuffer).
- строка 1094: SetWindowPos в этом файле не объявлена (нет и в блоке $IFNDEF __WIN32API / __RQINC2). Без windows.inc или rapidq2.inc ReSize не скомпилируется. Проверить, нужен ли DECLARE в блоке строк 22-108.

### XPSkinMetallic_2.11_Res.inc
- строка 460: IIF(LEN(myMainFormName)>0,myMainFormName,) — третий аргумент IIF пустой (значение по умолчанию вырезано в комментарий). Проверить, принимает ли rc.exe пустой аргумент; если нет — вернуть "Form style WinXP" или "".
- строка 683: CASE WM_NCPAINT, WM_ACTIVATE, .XPPopupMenu.Visible=0 — третий элемент списка CASE логическое выражение (0 или -1), оно сравнивается с номером сообщения uMsg. Похоже на ошибку замысла; что хотел автор, по коду не ясно.
- строка 866: EVENT MenuTimer.OnTimer(b, x, y, shift) — по qtimer.html OnTimer без параметров; b в строке 869 тогда всегда 0, и (b=0 or b=1) всегда истинно. Проверить, принимает ли RapidQ обработчик с лишними параметрами.
- строка 992–993: Строка 992 кончается на «+_», строка 993 начинается с «+"et ajouter"» — получается «CHR$(34) + +"et ajouter"» (унарный плюс перед строкой) и нет пробела перед «et». Проверить, компилирует ли rc.exe; иначе убрать один «+».
- строка 1015: EnableWindow(mhWnd,) — второй аргумент пустой. По замыслу (закомментировано «MainForm.Enabled=0», в OnClose строка 1243 EnableWindow(mhWnd,1)) нужно EnableWindow(mhWnd,0). Проверить, что передаёт RapidQ для пустого аргумента.

### XPThemes.inc
- строка 161: IF .Handle AND NOT .Subclassed - NOT побитовый: при Subclassed = 1 получается .Handle AND -2, это не ноль почти для любого окна, так что повторный вызов Subclass подменит оконную процедуру второй раз (то же в строках 233, 305, 377, 465). Вероятно, задумано .Subclassed = 0; проверить

### apiRe.inc
- строка 16: После $DEFINE HWND INTEGER в DECLARE MoveRichEdit (строка 79) и ShowRichEdit (строка 83) параметр называется hwnd. Если $DEFINE в RapidQ заменяет без учёта регистра (как и остальные имена), строка станет '(INTEGER As Long, ...' - ошибка. Проверить в RapidQ; при ошибке переименовать параметры (например hWndRE) или убрать $DEFINE (в файле HWND больше нигде не используется).
- строка 145: В qapplication.html свойства hInstance нет: hInstance приложения - Application.Handle ('hInstance of the application'). Так же Application.hInstance написано в QImageEx.inc и rapidq2.inc. Проверить в RapidQ, есть ли недокументированное hInstance; если нет - заменить на Application.Handle.

### conversion.inc
- строка 969: В ConvertCodePage2 параметры MultiByteToWideChar переставлены относительно RQConvertCodePage (строка 904): cchMultiByte = RetStrLong (число широких символов), cchWideChar = LenSourseString. Для многобайтовых кодировок (UTF-8) входная строка обрезается. Проверить, задумано ли это в экспериментальной версии.
- строка 1039: brem 0 ($ifdef 0 через $define в rapidq.inc) без парного erem до конца файла. Проверить, закрывает ли RapidQ $IFDEF в конце include-файла; если нет, текст программы после $INCLUDE "conversion.inc" будет пропущен. Можно добавить erem последней строкой.

### eml.inc
- строка 71–82: GetMsgBodyCodeMethod ищет "charset=" в значении Content-Transfer-Encoding (скопировано из GetMsgBodyCodePage); у этого поля нет параметров, функция всегда возвращает "". Вероятно, нужно result = field$(ContentTransferEncoding$,";",1) - проверить по вызовам.
- строка 558: Chr(0) без $ - в документации RapidQ только CHR$. Проверить, компилирует ли rc.exe; на результат не влияет, строка 571 убирает chr$(0) ещё раз.

### func_array.inc
- строка 72: ARRMaxEx перебирает MinEl TO MaxEl-1, а парная ARRMinEx (строка 87) и ARRMax - MinEl TO MaxEl: последний элемент в поиске максимума не участвует. Возможно, намеренно - проверить.
- строка 139: Тип параметра AS int (и dim ... as int в Files.inc, conversion.inc): в документации такого типа нет (chapter3.html: BYTE, WORD, DWORD, SHORT, INTEGER, LONG, SINGLE, DOUBLE, STRING, VARIANT). Файлы пользователя давно собираются, значит rc, видимо, принимает; уточнить.
- строка 308: Nakopl: REDIM Nakop!(0 to period-1), но дальше пишется Nakop!(ibeg..iend) и Nakop!(iend+1..NumPnt) (строки 335-349), то есть индексы до NumPnt - далеко за границей массива из period элементов (RapidQ границы не проверяет - порча памяти). Вероятно, нужен размер по числу точек (0 to NumPnt-1) и цикл в строке 345 до NumPnt-1; NumPnt считается ниже (строка 326).
- строка 502–511: ReversX1 ничего не делает: ddi/ddj записываются обратно на свои же места (Dat!(i)=ddi, Dat!(N-1-i)=ddj); к тому же цикл идёт по всему массиву (0..N-1), так что и при правильном обмене массив перевернулся бы дважды, а элемент UBOUND не участвует. Для переворота: Dat!(i)=ddj, Dat!(NumPoint-1-i)=ddi и цикл до (NumPoint-1)\2. Не исправлял - меняется поведение.

### odbc.inc
- строка 96–101: Подсчёт драйверов: DriverCount увеличивается до вызова SQLDrivers, и после последнего (неудачного, SQL_NO_DATA) вызова в Driver(DriverCount) пишется прежнее описание - драйверов получается на один больше. Ответ SQL_SUCCESS_WITH_INFO (обрезанное имя) обрывает цикл. Логику не менял.
- строка 171: не внесено: строку SQLError могли убрать намеренно при переделке из inc/old/qodbc.inc; возврат вызова API меняет поведение без проверки. (предлагалось: возвращён вызов SQLError из inc/old/qodbc.inc (строка 174): без него sSQLState, sErrorMsg и iLen в сообщении ниже всегда пустые; поля через qODBC., как в остальных строках метода)
- строка 173: Trim$ - не функция RapidQ (в документации только LTRIM$ и RTRIM$, indexa.html) и в файле не определена; Trim$ есть в SysUtils.inc и QLibrary.Inc. Без них rc, вероятно, не соберёт строку. Возможная замена: LTRIM$(RTRIM$(...)). Проверить в RapidQ.
- строка 321–324: В конце include объявляются глобальные myDB и sSQL и сразу вызывается myDB.ODBCInit - при подключении файла программа инициализирует ODBC (и при ошибке показывает MESSAGEBOX), а имена myDB/sSQL заняты. Остаток примера из inc/old/qodbc.inc; оставить или убрать - решить пользователю.

### parse.inc
- строка 98: В ParseDim счётчик k не объявлен и не обнуляется перед циклом (строки 97-107). Если необъявленная переменная в SUB в RapidQ общая (глобальная), при втором вызове заполнение начнётся не с 0; проверить и при необходимости добавить k=0 перед циклом.
- строка 270: NumOpers=k: последний оператор (строки 264-268) записывается в Oper$(k), но k не увеличивается, поэтому NumOpers на 1 меньше числа записанных операторов, если в конце строки нет ":". Проверить, как вызывающий код использует NumOpers (0..NumOpers или 0..NumOpers-1).

### qcalendar.inc
- строка 392: Today.font.addstyles=0 — AddStyles метод, в строке 366 он вызван как метод (Panel1.font.addstyles 0). Проверить, принимает ли rc.exe форму с «=»; иначе Today.font.addstyles 0.

### qciccio.inc
- строка 2: Тип ciccino не определён ни в этом файле, ни в других include (так и в документации c_qciccio.html: файл сам по себе не компилируется). Похоже на тестовую заготовку; решить, оставлять ли файл в базовом наборе.

### qdownload.inc
- строка 56–58: True, False (строки 56, 58, 86, 128, 131, 139, 141, 152 и др.) и fmCreate (строка 245) в файле не определены и нет $INCLUDE "RAPIDQ.INC". Без него в RapidQ это необъявленные переменные со значением 0: Check всегда 0, CASE True и CASE False совпадают, файл открывается с режимом 0 (чтение) вместо fmCreate. Проверить, требовать ли RAPIDQ.INC (или добавить $IFNDEF-определения, как в QImageEx.inc)

### qfocus.inc
- строка 93–95: В OnMouseMove остались отладочные Showmessage str$(lh) и Showmessage "2" - окно сообщения на каждое движение мыши. Похоже на забытую отладку; убрать (закомментировать) или оставить - решить пользователю
- строка 96: Условие x>6 or x<.width-6 истинно всегда; по смыслу (середина, не край) нужно and. Следующие проверки (строки 103, 108) перекрывают результат у краёв, поэтому на работу влияет мало - проверить
- строка 180–193: focusindex объявлен DIM внутри события таймера и обнуляется при каждом вызове, поэтому focusindex++ всегда даёт 1 и рамка не мигает (всегда цвет &h0000f), хотя по коду задумано чередование с белым. Нужна переменная вне события (поле TYPE или глобальная) - проверить
- строка 206–219: Непарные блоки в objectfocustimer.ontimer: WITH QFocus (строка 165), внутри IF dragenable=1 (строка 206) второй with qfocus (строка 214), затем end if (217) до END WITH (219); один WITH так и не закрыт до end event. Вероятно, строка 214 лишняя (внутри и так This.). Проверить, компилирует ли это rc.exe

### qftpdirlistview/qftpdirlistview.inc
- строка 66–85: PROPERTY SET Set_FilenameProp описан три раза (для FilenameSize, FilenameType, FilenameDate), а сеттер подключён только у FilenameSize (строки 56-58). Если RapidQ берёт последнее описание, присваивание FilenameSize запишет значение в FilenameDate. Вероятно, второй и третий сеттер нужно переименовать или убрать - проверить в RapidQ
- строка 104–108: vidnum$ не определена: функция закомментирована (строки 30-36). Без неё вызов vidnum$(...) не скомпилируется - раскомментировать функцию или заменить на STR$ (строка 105)
- строка 129–156: LoadDirectories начинается с вставленного примера QFtpClient (жёсткий хост www.bigftp.com, логин, пароль, PRINT) и строки !!!!!!!!!!!! (156), которая в RapidQ не компилируется. Похоже на намеренную метку незаконченного кода - решить, комментировать ли пример и строку 156
- строка 160–169: faDirectory (160), FALSE (169, 231, 386...) и TRUE (266, 387) в файле и в QFTPCLIENT.INC не определены (нет RAPIDQ.INC) - тогда это 0: Dir$ ищет без атрибута каталога. Проверить, нужен ли $INCLUDE "RAPIDQ.INC"

### rapidq.inc
- строка 1144: QDebug (строки 1143-1174) вызывает SetLastError, GetLastError, WSAGetLastError, FormatMessage и константы FORMAT_MESSAGE_FROM_SYSTEM, LANG_NEUTRAL, но в rapidq.inc и в подключаемых им файлах их DECLARE/CONST нет (в inc/rapidq2.inc они объявлены, строки 1820-1847). Работает, только если программа объявляет их сама; проверить в RapidQ, компилируется ли QDebug.ErrNum/Err$/SetError без этих объявлений, и при необходимости добавить DECLARE из rapidq2.inc.

### rapidq2.inc
- строка 2525: В QFormEx (EXTENDS QFORM) иконка берётся как QForm.Icon - имя базового типа, а не QFormEx.Icon/This.Icon; в inc/object/QFormEx.inc и inc/old/QFormEx.inc было Application.Icon. Проверить, что QForm.Icon внутри типа даёт иконку этой формы.
- строка 2571: TrayIconIndex объявлен 'PROPERTY SET SetTrayIconIndex' (строка 2359), а установщик написан как SUB, не PROPERTY SET ... END PROPERTY (глава 10.8 показывает только PROPERTY SET). Проверить в RapidQ, вызывается ли SUB при присваивании TrayIconIndex. Там же: при TheIndex <= 0 вызывается GetICO(TheIndex - 1) с отрицательным номером.
- строка 2607–2614: SetTransparent ставит окну WS_EX_LAYERED, а вызов SetLayeredWindowAttributes закомментирован (строка 2611); layered-окно без SetLayeredWindowAttributes/UpdateLayeredWindow Windows не рисует - форма станет невидимой при любом значении Transparent. То же у SetTransparentClient (строка 2598). Проверить в RapidQ, почему вызов закомментирован (объявлен в строке 1006).
- строка 5751–5761: AddBMPFile и ICOFile загружают картинку в .image(MenuItem.Command), а Transparent/TransparentColor ставят в .image(.LastMenu) - LastMenu задаётся только в AddDescription/MenuModify и может указывать на другой пункт. Похоже, должно быть .image(MenuItem.Command); другой версии для сверки нет.
- строка 7344–7397: PSD.hDevMode по API PageSetupDlg - дескриптор глобальной памяти (GlobalAlloc), а сюда пишется адрес локальной записи DevM (UDTPTR). Проверить в RapidQ, что диалог принимает такие настройки и не падает.
- строка 7566–7567: RESULT = BATTERY_LIFE_UNKNOWN внутри PROPERTY SET SetPowerStatus ничего не возвращает (у установщика нет результата; код остался от FUNCTION GetPowerStatus, строка 7551). Возможно, имелось в виду THIS.PowerStatus = BATTERY_LIFE_UNKNOWN.

## Ресурсы

- qftpdirlistview/qftpdirlistview.inc, строка 19: $RESOURCE с абсолютными путями C:\bas\RapidQ\inc\... (комментарий в строке 18 об этом). Сами иконки лежат рядом: inc2026/qftpdirlistview/ Файлы: dir_XP_small.ico, dir_XP_large.ico, default_small.ico, default_large.ico
- QTButton95.inc, строка 59: Нужен ресурс btn_BMP, который файл не объявляет: строка 8 '$REsource btn_BMP As "_RES\Boutons.bmp"' закомментирована; при $Option Explicit без него - ошибка. Программа должна объявить $RESOURCE btn_BMP до $INCLUDE. Файлы: Boutons.bmp
- QDrawMenu.inc, строка 233: Пример: 8 ресурсов $RESOURCE по абсолютному пути \rapidQ\icon\play.bmp (от корня диска). Файлы: play.bmp
- QDigDisplay.inc, строка 22: 33 картинки грузятся при работе программы по голому имени файла (AddBMPFile "32.bmp" ... "64.bmp") из текущей папки. Файлы: 32.bmp, 33.bmp, 34.bmp, 35.bmp, 36.bmp, 37.bmp, 38.bmp, 39.bmp, 40.bmp, 41.bmp, 42.bmp, 43.bmp, 44.bmp, 45.bmp, 46.bmp, 47.bmp, 48.bmp, 49.bmp, 50.bmp, 51.bmp, 52.bmp, 53.bmp, 54.bmp, 55.bmp, 56.bmp, 57.bmp, 58.bmp, 59.bmp, 60.bmp, 61.bmp, 62.bmp, 63.bmp, 64.bmp
- qdirlistview/qdirlistview.inc, строка 20: $RESOURCE с путём "resource\..." относительно текущей папки компиляции; в inc2026/qdirlistview иконки лежат рядом с .inc, папки resource нет (в старой версии inc/old/QDirListView1.inc - абсолютные пути C:\bas\RapidQ\inc\). Файлы: dir_XP_small.ico, dir_XP_large.ico, default_small.ico, default_large.ico
- QMarker.inc, строка 1: $RESOURCE Mark.bmp по имени без пути - файла нет ни в inc2026, ни в inc. Файлы: Mark.bmp
