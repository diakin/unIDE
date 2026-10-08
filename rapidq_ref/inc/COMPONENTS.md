# Компоненты RapidQ в rapidq_ref/inc

Компоненты, написанные на самом RapidQ (`TYPE Имя EXTENDS Класс`), из файлов этой папки и `object/`. Описание каждого — страница в `rapidq_ref/html_doc` (Appendix B, оглавление — `html_doc/custom.html`). Страницы собраны по исходникам: таблицы — открытые (PUBLIC) поля, методы и события из блока TYPE, значения по умолчанию — из CONSTRUCTOR, описания — по коду и комментариям в нём. Примеры на страницах, кроме помеченных «from the comments in the source file», написаны по списку членов и не запускались.

Состояние на 2026-10-08. Работоспособность компонентов не проверялась — это следующий этап.

## Список (134)

| Компонент | Наследует | Файл | Автор, версия | Описание | Страница |
|---|---|---|---|---|---|
| COMPORT | QOBJECT | `ComPort.cmp` | Pete Kleinschmidt, 0.9 | Comport — невизуальный компонент последовательного (COM) порта: открытие, настройка, запись и чтение через Win32 API файлов и коммуникаций. | [c_comport.html](../html_doc/c_comport.html) |
| MYCOM_PORT | QOBJECT | `COMPORTxp.CMP` | Pete Kleinschmidt, 0.9 | Объект последовательного (COM) порта: открытие, настройка, запись и чтение через Win32 API файлов, с событиями ошибок и завершения операций. | [c_mycom_port.html](../html_doc/c_mycom_port.html) |
| MYXPSKINNEDFORM | QFORM | `XPSkinMetallic_2.11_Res.inc` | 2.13 | Форма со скином: заменяет заголовок и рамку Windows картинками в стиле Windows XP Metallic, своими кнопками заголовка, системным всплывающим меню, скруглёнными углами и кнопкой по умолчанию. | [c_myxpskinnedform.html](../html_doc/c_myxpskinnedform.html) |
| QABOUT | QOBJECT | `object/QAbout.inc` | 1.2 | QAbout — создаёт и показывает модальное окно «О программе» с картинкой, названием и версией, текстом и кликабельными e-mail и веб-ссылкой. | [c_qabout.html](../html_doc/c_qabout.html) |
| QANIM | QIMAGE | `QAnim.inc` | 1.0 | Анимированное изображение: QImage, который по таймеру по очереди показывает кадры из своего QImageList. | [c_qanim.html](../html_doc/c_qanim.html) |
| QANIMATE | QOBJECT | `QAnimate.inc` | Nastase Eodor, 1.2 (stable) | Обёртка над стандартным элементом Windows Animation (SysAnimate32) для проигрывания беззвучных AVI-роликов. | [c_qanimate.html](../html_doc/c_qanimate.html) |
| QAVI | QOBJECT | `QAVI.inc` | JohnK (John Kelly); code contributions by Ray Mercer, 1.0 | Невизуальный компонент для чтения кадров AVI-файла в QBITMAP и записи битмапов в новый AVI-файл через Video for Windows (AVIFile API). | [c_qavi.html](../html_doc/c_qavi.html) |
| QBEVEL | QPANEL | `QBevel.inc` |  | Элемент «фаска» как TBevel в Delphi: QPANEL, показывающая выпуклую или вдавленную рамку, контур или одиночную линию. | [c_qbevel.html](../html_doc/c_qbevel.html) |
| QBITMAPEX | QBITMAP | `QBitmapEx.inc` | 1.4 | Расширенный QBITMAP: рисование через GDI, работа с буфером обмена, загрузка JPEG/GIF и сохранение в JPEG через NViewLib.dll. | [c_qbitmapex.html](../html_doc/c_qbitmapex.html) |
| QBROWSEDIALOG | QOBJECT | `QBrowseDialog.inc` | Psyclops | QBROWSEDIALOG — показывает стандартный диалог Windows «Обзор папок» и возвращает выбранную папку. | [c_qbrowsedialog.html](../html_doc/c_qbrowsedialog.html) |
| QBUTTONXP | QBUTTON | `QButtonXP.INC` | Nicolas Tillet, modified by Nastase Eodor | QButton, который переустанавливает стиль окна, чтобы кнопка рисовалась в стиле Windows XP при использовании вместе с QXPTheme.inc. | [c_qbuttonxp.html](../html_doc/c_qbuttonxp.html) |
| QCALENDAR | QPANEL | `qcalendar.inc` | Pasquale P.C.B. | Панель-календарь на месяц с сеткой дней, кнопками перехода по месяцам и годам, меню выбора месяца и кнопкой «Сегодня», с названиями из локали Windows. | [c_qcalendar.html](../html_doc/c_qcalendar.html) |
| QCANVASEX | QCANVAS | `QCanvasEx.inc` |  | Расширенный QCANVAS: рисование через GDI со стилем и толщиной пера и режимом смешивания, заливка фигур, иконки, заливка области, инверсия, зеркалирование и обмен битмапами через буфер обмена. | [c_qcanvasex.html](../html_doc/c_qcanvasex.html) |
| QCDAUDIO | QOBJECT | `Qcdaudio.inc` |  | Невизуальный проигрыватель аудио-CD через MCI-устройство cdaudio: открытие, воспроизведение, пауза, стоп, извлечение диска и выбор дорожки с событием изменения позиции. | [c_qcdaudio.html](../html_doc/c_qcdaudio.html) |
| QCGI | QOBJECT | `qcgi.inc` | Chris Warrington (with modifications by C. Baker), 1.6 | Невизуальный помощник для CGI-программ: читает переменные окружения CGI и разбирает данные формы GET/POST на пары имя/значение. | [c_qcgi.html](../html_doc/c_qcgi.html) |
| QCHART | QCANVAS | `QChart.inc` | Michael J. Zito, Build 3.6.04 | QChart — класс построения диаграмм на основе QCanvas: гистограммы, столбчатые, линейные, XY, круговые, box-plot, hi-lo и графики реального времени. | [c_qchart.html](../html_doc/c_qchart.html) |
| QCICCIO | QOBJECT | `qciccio.inc` |  | Пустая заготовка компонента: одно поле неопределённого типа ciccino и пустой конструктор. | [c_qciccio.html](../html_doc/c_qciccio.html) |
| QCOLORBUTTON | QPANEL | `QColorButton.inc` | Achilles B. Mina | QCOLORBUTTON — маленькая квадратная панель QPanel, работающая как кнопка с эффектом нажатия. | [c_qcolorbutton.html](../html_doc/c_qcolorbutton.html) |
| QCOLORDIALOG | QOBJECT | `object/QColorDialog.inc` | 1.1 | Объект диалога выбора цвета на основе стандартного диалога Windows ChooseColor, с собственным заголовком, 16 пользовательскими цветами и вариантами раскрытия. | [c_qcolordialog_object_qcolordialog.html](../html_doc/c_qcolordialog_object_qcolordialog.html) |
| QCOLORDIALOG | QOBJECT | `QColorDialog.inc` |  | Невизуальная обёртка над стандартным диалогом выбора цвета Windows (ChooseColor), возвращающая цвет в виде RGB-значения и HTML-строки #RRGGBB. | [c_qcolordialog_qcolordialog.html](../html_doc/c_qcolordialog_qcolordialog.html) |
| QCOLORDLG | QFORM | `RapidFRM.inc` | D. Glodt (original version) | QColorDlg — диалог выбора цвета на основе стандартного ChooseColor Windows, с выбором стиля, положения на экране, заголовка и пользовательских цветов. | [c_qcolordlg.html](../html_doc/c_qcolordlg.html) |
| QCOOLBARXP | QPANEL | `QCoolBarXPv1d.inc` | D-evolution, QCoolBarXPv1 | Панель инструментов в стиле Windows XP (rebar) с кнопками-картинками, разделителями, «ручкой», заголовком, выпадающими меню, встроенными полями ввода/списками и меню переполнения. | [c_qcoolbarxp.html](../html_doc/c_qcoolbarxp.html) |
| QCURSOR | QOBJECT | `QCursor.inc` | 1.0 | Объект для загрузки курсоров мыши из файлов или ресурсов, а также показа, скрытия и перемещения курсора. | [c_qcursor.html](../html_doc/c_qcursor.html) |
| QD3DCAMERA | QOBJECT | `RapidQ_D3D.inc` | JohnK, 1.1 | Невизуальный помощник-камера для Direct3D-программ RapidQ (QDXSCREEN): хранит положение и ориентацию камеры и передаёт их в QDXSCREEN. | [c_qd3dcamera.html](../html_doc/c_qd3dcamera.html) |
| QD3DCLONEMESH | QOBJECT | `RapidQ_D3D.inc` | JohnK, 1.0 | Невизуальный помощник для Direct3D-программ RapidQ: показывает одну сетку QD3DMESHBUILDER (из файла X или 3DS) в нескольких кадрах QD3DFRAME (до 100), чтобы одна модель появлялась в сцене многократно. | [c_qd3dclonemesh.html](../html_doc/c_qd3dclonemesh.html) |
| QD3DPRIMITIVE | QOBJECT | `RapidQ_D3D.inc` | JohnK, 1.1 | Невизуальный помощник для Direct3D-программ RapidQ: строит простые полигональные сетки (плоскости, куб, пирамиду, сферу, цилиндр, конус) в QD3DMESHBUILDER. | [c_qd3dprimitive.html](../html_doc/c_qd3dprimitive.html) |
| QDATABASE | QOBJECT | `QDataBase.inc` | 1.0 | Невизуальный компонент простой файловой базы данных с записями фиксированной длины, с доступом к полям и функциями поиска. | [c_qdatabase_qdatabase.html](../html_doc/c_qdatabase_qdatabase.html) |
| QDATABASE | QOBJECT | `qdataBaseSQL.inc` | Alberto (from Brasil) (netmask@ig.com.br) | Объект базы данных ODBC: подключается к файлам Access, dBase, Paradox, Excel или текстовым и читает список таблиц и описания их полей. | [c_qdatabase_qdatabasesql.html](../html_doc/c_qdatabase_qdatabasesql.html) |
| QDEBUG | QOBJECT | `QDebug.inc` | Pete Kleinschmidt, 0.9 | Объект для отладочного вывода строк в отдельное окно «Debug» с полем QRICHEDIT. | [c_qdebug.html](../html_doc/c_qdebug.html) |
| QDESKTOP | QOBJECT | `QDesktop.inc` | 1.0 | Объект для работы с рабочим столом: копирование экрана или обоев в контекст устройства, чтение цвета пикселя экрана и смена обоев. | [c_qdesktop.html](../html_doc/c_qdesktop.html) |
| QDFPANEL | QPANEL | `QDOCKFORM.inc` |  | Вспомогательная панель для QDOCKFORM: QPANEL, у которой свойства внешнего вида скрыты (объявлены как Private). | [c_qdfpanel.html](../html_doc/c_qdfpanel.html) |
| QDIGDISPLAY | QCANVAS | `QDigDisplay.inc` | Peter Molloy, 1.00 | Холст, показывающий строку символами «цифрового табло» из BMP-файлов. | [c_qdigdisplay.html](../html_doc/c_qdigdisplay.html) |
| QDIR | QOBJECT | `QDir.Inc` | Jacques Philippe, 1.0.4 | Невизуальный компонент поиска файлов в каталоге или дереве каталогов по маске и атрибутам с событием на каждый найденный файл. | [c_qdir.html](../html_doc/c_qdir.html) |
| QDIRLISTVIEW | QLISTVIEW | `qdirlistview.inc` | Rene Saarsoo | QListView для показа папок и файлов каталога с иконками и колонками размера, типа и даты, с переходом по папкам. | [c_qdirlistview.html](../html_doc/c_qdirlistview.html) |
| QDOCKFORM | QPANEL | `QDOCKFORM.inc` |  | Пристыковываемая панель инструментов: QPANEL с заголовком, которую можно перетащить с формы в плавающее окно без рамки и пристыковать обратно. | [c_qdockform.html](../html_doc/c_qdockform.html) |
| QDOWNLOAD | QOBJECT | `qdownload.inc` | v2 | Невизуальный объект, который скачивает файл с HTTP-сервера через QSocket и возвращает его в строке или сохраняет в файл, показывая прогресс и скорость. | [c_qdownload.html](../html_doc/c_qdownload.html) |
| QDRAWFOCUS | QOBJECT | `QDrawFocus.inc` | modified by JohnK, 1.3 | QDrawFocus — рисует на контексте устройства рамку выделения (focus rectangle), которую можно перемещать и растягивать мышью за правый и нижний край. | [c_qdrawfocus.html](../html_doc/c_qdrawfocus.html) |
| QDRAWMENU | QOBJECT | `QDrawMenu.inc` | 1.3 | Невизуальный помощник, делающий пункты меню самоотрисовываемыми, чтобы рядом с текстом показывалась картинка, по желанию в рамке-кнопке. | [c_qdrawmenu.html](../html_doc/c_qdrawmenu.html) |
| QDRIVE | QOBJECT | `QDrive.inc` |  | Объект, который перечисляет диски компьютера и сообщает их тип, размер и свободное место. | [c_qdrive.html](../html_doc/c_qdrive.html) |
| QDRIVECOMBOBOX | QCOMBOBOX | `QDriveCombobox.inc` |  | QDriveComboBox — выпадающий список QComboBox для показа имеющихся на компьютере дисков. | [c_qdrivecombobox.html](../html_doc/c_qdrivecombobox.html) |
| QFILEDIALOG | QOBJECT | `QFileDialog.inc` | JohnK, 1.0 | Объект диалога открытия или сохранения файла на основе стандартного диалога Windows (GetOpenFileName/GetSaveFileName) с предупреждением о перезаписи и множественным выбором. | [c_qfiledialog.html](../html_doc/c_qfiledialog.html) |
| QFILELISTVIEW | QLISTVIEW | `QFileListView.inc` | 1.1 | QListView со списком файлов каталога с системными значками, размером, типом и датой изменения, с фильтром по одной или нескольким маскам. | [c_qfilelistview.html](../html_doc/c_qfilelistview.html) |
| QFLASHLABEL | QLABEL | `QFlashLabel.inc` | 1.0 | Метка QLabel, которая умеет мигать текстом, переключая цвет шрифта между тёмным и светлым по таймеру. | [c_qflashlabel.html](../html_doc/c_qflashlabel.html) |
| QFLATBUTTON | QIMAGE | `QFlatButton.inc` |  | Плоская кнопка-картинка на основе QImage: при наведении мыши рисуется выпуклая рамка, при нажатии — вдавленная. | [c_qflatbutton.html](../html_doc/c_qflatbutton.html) |
| QFOCUS | QCANVAS | `qfocus.inc` | John Graves aka laddie@bellsouth.net | Холст, который можно перемещать и менять размер мышью, с мигающей пунктирной рамкой фокуса. | [c_qfocus.html](../html_doc/c_qfocus.html) |
| QFORMEX | QFORM | `object/QFormEx.inc` | 1.2 | Расширенная форма QFORM: приём перетаскиваемых файлов, значок в системном трее и управление кнопкой на панели задач. | [c_qformex.html](../html_doc/c_qformex.html) |
| QFORMMDI | QFORM | `object/QFormMDI.inc` | 1.0 | Родительская MDI-форма, которая создаёт дочерние MDI-окна вокруг существующих компонентов и даёт свойства, методы и события для управления ими. | [c_qformmdi.html](../html_doc/c_qformmdi.html) |
| QFTPCLIENT | QOBJECT | `QFTPCLIENT.INC` | Jacques Philippe | Объект FTP-клиента на основе wininet.dll: подключение к серверу, работа с каталогами, загрузка, скачивание, переименование и удаление файлов, список файлов с размером, датой и атрибутами. | [c_qftpclient.html](../html_doc/c_qftpclient.html) |
| QFTPDIRLISTVIEW | QLISTVIEW | `qftpdirlistview.inc` | Andrew Shelkovenko | QFTPDirListView — незаконченный список файлов на основе QListView, задуманный для просмотра FTP-каталогов; фактически код показывает папки и файлы локального каталога. | [c_qftpdirlistview.html](../html_doc/c_qftpdirlistview.html) |
| QGL | QOBJECT | `QGL.inc` | JohnK, alpha release 1.0 | Обёртка OpenGL: создаёт контекст рендеринга OpenGL на форме RapidQ (или в битмапе) и даёт функции для области вывода, текстур, тумана, полноэкранного режима и подсчёта FPS. | [c_qgl.html](../html_doc/c_qgl.html) |
| QGRIDCOLOR | QPANEL | `QGridColor.inc` | Nastase Eodor, 1.0.0 | QGridColor — панель QPanel с 16 стандартными цветами в виде ячеек; левый щелчок выбирает цвет переднего плана, правый — цвет фона. | [c_qgridcolor.html](../html_doc/c_qgridcolor.html) |
| QGROUPBOXUX | QGROUPBOX | `XPThemes.inc` |  | QGROUPBOX, который после вызова Subclass перерисовывает рамку и заголовок в стиле тем Windows XP. | [c_qgroupboxux.html](../html_doc/c_qgroupboxux.html) |
| QHEAD | QCANVAS | `QHead.inc` |  | Заголовочная панель на основе QCanvas, выровненная по верху родителя: левый и правый текст, необязательная иконка и градиентная линия. | [c_qhead.html](../html_doc/c_qhead.html) |
| QHTML | QPANEL | `QHTML.inc` | Pascal Delcombel, 1.0 | Панель для просмотра (только чтение) упрощённых HTML-страниц, написанная на чистом RapidQ без API и DLL. | [c_qhtml.html](../html_doc/c_qhtml.html) |
| QICMP | QOBJECT | `QICMP.INC` |  | Компонент ping: отправляет эхо-запросы ICMP через icmp.dll. | [c_qicmp.html](../html_doc/c_qicmp.html) |
| QICON | QOBJECT | `QICON.inc` | 1.2 | Невизуальный объект, извлекающий иконки из файлов и сохраняющий иконку или растр 32x32 в .ico на 16 или 256 цветов, а также превращающий его в курсор. | [c_qicon.html](../html_doc/c_qicon.html) |
| QID3TAG | QOBJECT | `Qid3Tag.inc` | Dreadsoft® Corporation | Невизуальный компонент чтения и записи тега ID3v1 в конце MP3-файла (название, исполнитель, альбом, год, комментарий, номер дорожки, жанр) со списком жанров и выпадающим списком. | [c_qid3tag.html](../html_doc/c_qid3tag.html) |
| QIMAGEBOX | QSCROLLBOX | `QImageBox.inc` | 1.0 | Контейнер с прокруткой для показа файла изображения (BMP, ICO, CUR, ANI, а через Nviewlib.dll также GIF, JPG, PCX, TGA и др.), уменьшенного по размеру и отцентрированного. | [c_qimagebox.html](../html_doc/c_qimagebox.html) |
| QIMAGEDIALOG | QOBJECT | `QImageDialog.inc` | 1.1 | Собственный диалог открытия файла из контролов RapidQ с уменьшенным предпросмотром выбранного изображения. | [c_qimagedialog.html](../html_doc/c_qimagedialog.html) |
| QIMAGEEX | QIMAGE | `object/QImageEx.inc` | 1.1 | Расширение QImage: копирование и вставка через буфер обмена, загрузка битмапа нужного размера и загрузка других форматов изображений через NViewLib.dll. | [c_qimageex.html](../html_doc/c_qimageex.html) |
| QIMAGELISTEX | QIMAGELIST | `QImageListEx.inc` |  | Расширение QImageList, которое заполняет список из одной горизонтальной полосы-битмапа (из файла или ресурса), при необходимости растягивая картинки. | [c_qimagelistex.html](../html_doc/c_qimagelistex.html) |
| QINI | QOBJECT | `object/QIni.inc` |  | QINI — невизуальный объект для чтения и записи значений в секции INI-файла и получения папок Windows, System и Temp. | [c_qini_object_qini.html](../html_doc/c_qini_object_qini.html) |
| QINI | QOBJECT | `QWinIni.inc` |  | Невизуальный объект для чтения и записи INI-файлов Windows через функции GetPrivateProfileString. | [c_qini_qwinini.html](../html_doc/c_qini_qwinini.html) |
| QINIFILE | QSTRINGLIST | `QIniFile.inc` | Nastase Eodor | Чтение и запись INI-файлов на основе QStringList: поиск секций и ключей, методы чтения и записи чисел и строк. | [c_qinifile_qinifile.html](../html_doc/c_qinifile_qinifile.html) |
| QINIFILE | QOBJECT | `QLibrary.Inc` |  | Простой объект для чтения и записи INI-файла: отдельных значений или целых секций текстового INI-файла. | [c_qinifile_qlibrary.html](../html_doc/c_qinifile_qlibrary.html) |
| QINPUTBOX | QOBJECT | `QInputBox.inc` |  | Невизуальный объект, показывающий модальный диалог ввода и возвращающий введённый пользователем текст. | [c_qinputbox.html](../html_doc/c_qinputbox.html) |
| QLED | QCANVAS | `QLed.inc` |  | Круглый светодиодный индикатор на QCanvas с шестью цветами и состояниями «вкл/выкл». | [c_qled.html](../html_doc/c_qled.html) |
| QLEDSCROLL | QCANVAS | `QLedScroll.inc` |  | Бегущая строка на QCanvas с необязательной сеткой, имитирующей светодиодное табло. | [c_qledscroll.html](../html_doc/c_qledscroll.html) |
| QLINE | QCANVAS | `QLine.inc` | 1.0 | Холст, рисующий объёмную (вдавленную) горизонтальную или вертикальную линию-разделитель. | [c_qline.html](../html_doc/c_qline.html) |
| QLINEGRAPH | QOBJECT | `qgraph.inc` | Jonathan Boles | Простой линейный график: рисует точки X/Y из QStringGrid на QCanvas с заголовком, подписями осей, автоматическим масштабом и делениями. | [c_qlinegraph.html](../html_doc/c_qlinegraph.html) |
| QLISTBOXEX | QLISTBOX | `QListBoxEx.inc` | 1.0 | QListBox с событием OnEnter, которое возникает при нажатии клавиши Enter. | [c_qlistboxex.html](../html_doc/c_qlistboxex.html) |
| QLISTVIEWEX | QLISTVIEW | `QListviewEx.inc` | Dreadsoft® Corporation | Расширенный QListView в табличном виде: плоские кнопки заголовков с сортировкой по клику, загрузка и сохранение CSV, фильтрация строк. | [c_qlistviewex.html](../html_doc/c_qlistviewex.html) |
| QMARKER | QPANEL | `QMarker.inc` |  | Панель с вертикальным столбцом цветных полос-строк, позволяющая выделять отдельные строки цветом или картинкой. | [c_qmarker.html](../html_doc/c_qmarker.html) |
| QMAXEDIT | QRICHEDIT | `RichEdPopUp.inc` | Psyclops | Расширение QRichEdit с контекстным меню как у стандартного поля Windows (Отменить, Вырезать, Копировать, Вставить, Удалить, Выделить всё) и функциями для позиций строк. | [c_qmaxedit_richedpopup.html](../html_doc/c_qmaxedit_richedpopup.html) |
| QMAXEDIT | QRICHEDIT | `ultraRichEd.inc` | Psyclops | QRichEdit с контекстным меню правки как в Windows (Отменить, Вырезать, Копировать, Вставить, Удалить, Выделить всё) и простой подсветкой ключевых слов. | [c_qmaxedit_ultrariched.html](../html_doc/c_qmaxedit_ultrariched.html) |
| QMAXSPLITTER | QPANEL | `QMaxSplitter.inc` | Psyclops | Разделитель (сплиттер) на основе QPANEL, повторяющий стили сплиттера Delphi 6: при перетаскивании изменяет размер соседнего выровненного элемента. | [c_qmaxsplitter.html](../html_doc/c_qmaxsplitter.html) |
| QMD2MODEL | QMEMORYSTREAM | `QGL.inc` | JohnK, alpha release 1.0 | Загрузчик и отрисовщик анимированных 3D-моделей Quake MD2 через OpenGL (с помощью объекта QGL). | [c_qmd2model.html](../html_doc/c_qmd2model.html) |
| QMENU | QOBJECT | `qmenu.inc` |  | Вспомогательный объект: рисует пункты меню формы с иконками (owner-draw) и показывает описания пунктов в строке состояния. | [c_qmenu.html](../html_doc/c_qmenu.html) |
| QMENUEX | QIMAGELIST | `rapidq2.inc` | John Kelly, 1.2 | Компонент на основе QIMAGELIST для owner-draw меню: рисует картинки или иконки рядом с пунктами меню и выдаёт строку подсказки для пункта под мышью. | [c_qmenuex.html](../html_doc/c_qmenuex.html) |
| QMIDI | QOBJECT | `QMidi.inc` | 1.2 | Невизуальный проигрыватель MIDI-файлов на основе MCI-секвенсора Windows: воспроизведение, пауза, стоп, перемотка, громкость и событие изменения позиции. | [c_qmidi.html](../html_doc/c_qmidi.html) |
| QMP3 | QOBJECT | `Qmp3.inc` | Dreadsoft Corporation (dreadsoft@yahoo.it) | Невизуальный компонент для чтения заголовка MP3, чтения и записи тегов ID3 v1.x и воспроизведения/остановки MP3 через MCI. | [c_qmp3.html](../html_doc/c_qmp3.html) |
| QODBC | QOBJECT | `odbc.inc` |  | Простой ODBC-клиент: список драйверов, подключение по строке соединения, список таблиц, выполнение SQL-запросов и чтение строк в текстовом виде. | [c_qodbc.html](../html_doc/c_qodbc.html) |
| QPAGESETUP | QOBJECT | `QPageSetup.inc` | 1.2 | Объект диалога параметров страницы на основе стандартного диалога Windows PageSetupDlg, возвращающий размер бумаги, ориентацию и поля. | [c_qpagesetup.html](../html_doc/c_qpagesetup.html) |
| QPANELUX | QPANEL | `XPThemes.inc` |  | QPanel, рамка которого после вызова Subclass рисуется цветом темы Windows XP. | [c_qpanelux.html](../html_doc/c_qpanelux.html) |
| QPOSIC | QPANEL | `Qposic1.inc` | 1.00 | Квадратный элемент управления положением по двум осям: вертикальная и горизонтальная полосы прокрутки и кнопки сброса, отмены, повтора и шага по диагонали. | [c_qposic.html](../html_doc/c_qposic.html) |
| QPOSICL | QPANEL | `QPosicL.inc` | 1.00 | Панель с вертикальной и горизонтальной полосами прокрутки и пятью кнопками для задания позиции по двум координатам (X/Y). | [c_qposicl.html](../html_doc/c_qposicl.html) |
| QPRINTERINFO | QOBJECT | `QPrinterInfo.inc` | 1.0 | Невизуальный объект, возвращающий размеры страницы, поля и разрешение принтера и переводящий миллиметры в пиксели принтера и обратно. | [c_qprinterinfo.html](../html_doc/c_qprinterinfo.html) |
| QPROCESS | QOBJECT | `QProcess.inc` | D. Glodt (original code), modified by JohnK, 1.1 | Невизуальный компонент, который выполняет обработчик события OnProcess в отдельном потоке Windows, с приоритетом, приостановкой, возобновлением и завершением. | [c_qprocess.html](../html_doc/c_qprocess.html) |
| QPROGRESS | QOBJECT | `object/QProgress.inc` |  | Индикатор выполнения: создаёт стандартный элемент Windows msctls_progress32 в родительском окне, заданном дескриптором. | [c_qprogress_object_qprogress.html](../html_doc/c_qprogress_object_qprogress.html) |
| QPROGRESS | QIMAGE | `QProgress.inc` | Johnk | Индикатор прогресса на основе QIMAGE: обычный QGAUGE или анимированная «бегущая» полоса (точка, прямоугольники, размытие, «парикмахерский столб») для задач неизвестной длительности. | [c_qprogress_qprogress.html](../html_doc/c_qprogress_qprogress.html) |
| QPROGRESSBAR | QOBJECT | `QProgressBar.inc` | Johnk (derived from code by Benjamin Maggi and David Burkley) | Компонент индикатора выполнения: создаёт настоящий Windows-контрол msctls_progress32 с цветами, плавным, вертикальным и бегущим (marquee) стилями и состоянием. | [c_qprogressbar.html](../html_doc/c_qprogressbar.html) |
| QRC4 | QOBJECT | `RC4crypt.inc` | Martin Wehner | Невизуальный потоковый шифр RC4 для шифрования и расшифровки строк по ключу. | [c_qrc4.html](../html_doc/c_qrc4.html) |
| QREDEX | QRICHEDIT | `QRedEx.Inc` | Jacques (2002-2005), [W]arriant (2006), 1.2.1 | Расширенный QRichEdit со встроенным контекстным меню правки, окнами поиска и замены, сохранением позиции прокрутки, лимитом размера текста и диалогами шрифта/цвета. | [c_qredex.html](../html_doc/c_qredex.html) |
| QREDIT | QRICHEDIT | `HiLight.inc` | William Yu | QRichEdit с простой автоматической подсветкой ключевых слов (синтаксиса). | [c_qredit.html](../html_doc/c_qredit.html) |
| QRICHEDITUX | QRICHEDIT | `XPThemes.inc` |  | QRICHEDIT, рамка которого после вызова Subclass рисуется цветом темы Windows XP. | [c_qricheditux.html](../html_doc/c_qricheditux.html) |
| QRICHEDIT_API | QOBJECT | `API_RichEdid.inc` |  | Незавершённая обёртка, создающая окно RichEdit напрямую через CreateWindowExA вместо QRICHEDIT. | [c_qrichedit_api_api_richedid.html](../html_doc/c_qrichedit_api_api_richedid.html) |
| QRICHEDIT_API | QOBJECT | `apiRe.inc` |  | Минимальная обёртка, создающая элемент Windows RichEdit (RICHED32.DLL) через CreateWindowEx, с перемещением, размером, показом и скрытием. | [c_qrichedit_api_apire.html](../html_doc/c_qrichedit_api_apire.html) |
| QRICHEDIT_XT | QRICHEDIT | `QRichEditXt.inc` |  | Расширение QRichEdit: автоопределение URL, ограничение длины текста, позиция прокрутки, управление авто-шрифтом и экспериментальная подсветка ключевых слов поверх текста. | [c_qrichedit_xt.html](../html_doc/c_qrichedit_xt.html) |
| QRPANEL | QPANEL | `QrPanel.inc` |  | QPanel со скруглёнными углами, получаемыми наложением скруглённой оконной области (region). | [c_qrpanel.html](../html_doc/c_qrpanel.html) |
| QRUN | QOBJECT | `QRun.inc` | 1.1 | Невизуальный объект для запуска программ и документов, поиска окон и управления ими (перечисление, закрытие, сворачивание, разворачивание, фокус, поверх всех). | [c_qrun.html](../html_doc/c_qrun.html) |
| QSAVEPLUS | QSAVEDIALOG | `QSavePlus.inc` | Suchart Chokphichitchai | Диалог сохранения файла с дополнительными проверками имени: несуществующий путь, недопустимое имя, отсутствие расширения и подтверждение перезаписи. | [c_qsaveplus.html](../html_doc/c_qsaveplus.html) |
| QSCROLLBOXUX | QSCROLLBOX | `XPThemes.inc` |  | QSCROLLBOX, рамка которого после вызова Subclass рисуется цветом темы Windows XP. | [c_qscrollboxux.html](../html_doc/c_qscrollboxux.html) |
| QSHFILEOPERATION | QOBJECT | `QSHFileOperation.inc` | Marcin Szafran, 1 | Обёртка над функцией API SHFileOperation для копирования, перемещения, переименования и удаления файлов и папок. | [c_qshfileoperation.html](../html_doc/c_qshfileoperation.html) |
| QSHUTDOWN | QOBJECT | `QShutdown.inc` |  | Невизуальный объект для выключения, принудительного выключения, перезагрузки Windows или выхода пользователя из системы. | [c_qshutdown.html](../html_doc/c_qshutdown.html) |
| QSKIN | QFORM | `QSkin.inc` | 1.2 | Форма со скином: QFORM без заголовка, размер которой подстраивается под изображение скина и которую можно перетаскивать за это изображение. | [c_qskin.html](../html_doc/c_qskin.html) |
| QSKINBTN | QIMAGE | `QSkinBtn.inc` | 1.0 | Кнопка со скином на основе QIMAGE: разные картинки для отжатого, нажатого и недоступного состояния, режимы обычной кнопки, фиксации и переключателя. | [c_qskinbtn.html](../html_doc/c_qskinbtn.html) |
| QSOCKETEX | QSOCKET | `QSocketEx.inc` | d_homans, JohnK | Расширение QSocket с функциями Winsock: исправленный GetPeerName, поиск имени и адреса хоста, проверка соединения, запись строки с CR LF, запись с кодом ошибки, завершение, режим блокировки и текст ошибок. | [c_qsocketex.html](../html_doc/c_qsocketex.html) |
| QSPINBUTTON | QPANEL | `QSpinEdit.inc` | Nastase Eodor <eodor@idilis.ro>, 1.0.0 | Счётчик (spin) на основе QPanel с двумя кнопками QCOOLBTN (+ и -) и необязательным полем QEDIT со значением. | [c_qspinbutton.html](../html_doc/c_qspinbutton.html) |
| QSPINTEXT | QPANEL | `qspintext.inc` | Mesut Akcan; OnChange event added by Andrew Shelkovenko, 1.01 | Поле со стрелками (spin edit): панель с QEdit и вертикальной полосой прокрутки для ввода числа от Min до Max, с событием OnChange. | [c_qspintext.html](../html_doc/c_qspintext.html) |
| QSPLASH | QOBJECT | `QSplash.inc` | 1.2 | QSplash — показывает заставку: окно без заголовка с картинкой и необязательным текстом, на заданное время или до закрытия программой. | [c_qsplash.html](../html_doc/c_qsplash.html) |
| QSQLTABLE | QOBJECT | `qdataBaseSQL.inc` | Alberto (from Brasil) (netmask@ig.com.br) | Объект SQL-запросов через ODBC: выполняет SQL-команды над базой Access, dBase, Paradox, Excel или текстовой и перемещается по строкам результата. | [c_qsqltable.html](../html_doc/c_qsqltable.html) |
| QSTATUSBAREX | QSTATUSBAR | `object/QStatusBarEx.inc` | 1.0 | Расширение QSTATUSBAR, позволяющее разместить QPanel (с элементами на ней) внутри одной из панелей строки состояния. | [c_qstatusbarex.html](../html_doc/c_qstatusbarex.html) |
| QSTRINGGRIDEX | QSTRINGGRID | `QStringGridEx.inc` | D. Glodt (per object/lire.txt), 1.0 | QStringGrid со стилем редактора по строкам, а не по столбцам: в строке может быть выпадающий список, кнопка «...» или обычное поле. | [c_qstringgridex.html](../html_doc/c_qstringgridex.html) |
| QSTRINGGRIDUX | QSTRINGGRID | `XPThemes.inc` |  | QStringGrid, рамка которого после вызова Subclass рисуется цветом темы Windows XP. | [c_qstringgridux.html](../html_doc/c_qstringgridux.html) |
| QSYSTEM | QOBJECT | `rapidq2.inc` | JohnK, 1.0c | Невизуальный объект со сведениями о Windows (версия ОС, память, диск, питание, системные метрики), умеющий открывать апплеты панели управления, усыплять, завершать сеанс, выключать и перезагружать компьютер. | [c_qsystem.html](../html_doc/c_qsystem.html) |
| QTABCONTROLEX | QTABCONTROL | `QtabControlEx.inc` | 1.0 | QTabControl со счётчиком вкладок и методами удаления вкладки и очистки всех вкладок. | [c_qtabcontrolex.html](../html_doc/c_qtabcontrolex.html) |
| QTBUTTON | QBUTTON | `QTButton95.inc` | D-evolution | Кнопка на основе QButton с отрисовкой из растрового скина или тем Windows XP, с эффектом наведения, иконкой, многострочной надписью и группами кнопок. | [c_qtbutton.html](../html_doc/c_qtbutton.html) |
| QTEXTBTN | QLABEL | `QTextBtn.inc` | 1.0 | Метка, работающая как текстовая кнопка: при нажатии меняет цвет шрифта; есть режимы обычной, фиксируемой и переключаемой кнопки. | [c_qtextbtn.html](../html_doc/c_qtextbtn.html) |
| QTEXTEDIT | QRICHEDIT | `QTextEdit.inc` |  | Расширение QRichEdit со встроенным контекстным меню Отменить/Вырезать/Копировать/Вставить/Выделить всё и дополнительными методами (отмена, ограничение длины, замена выделения, поиск). | [c_qtextedit.html](../html_doc/c_qtextedit.html) |
| QTOOLBAR | QOBJECT | `QToolBar.inc` | Nastase Eodor, 1.2 (stable) | Компонент панели инструментов на основе стандартного элемента Windows ToolBarWindow32: списки изображений, кнопки-переключатели и с выпадающим меню, подсказки и контекстное меню. | [c_qtoolbar.html](../html_doc/c_qtoolbar.html) |
| QTOOLBAREX | QPANEL | `QToolBarEX.inc` | d_homans@yahoo.com.au, 1.1 | Панель инструментов на основе QPanel с массивом плоских кнопок QCOOLBTN, картинки которых вырезаются из одной горизонтальной полосы-битмапа. | [c_qtoolbarex.html](../html_doc/c_qtoolbarex.html) |
| QTREEVIEWEX | QTREEVIEW | `QTreeviewEx.inc` |  | QtreeviewEx — расширение QTreeView: поиск родителя, детей и узлов по тексту, перемещение узлов и целых ветвей вверх, вниз и по уровням. | [c_qtreeviewex.html](../html_doc/c_qtreeviewex.html) |
| QVIDEO | QOBJECT | `QVideo.inc` | 1.3 | Объект-видеоплеер, воспроизводящий медиафайлы через строковые команды MCI. | [c_qvideo.html](../html_doc/c_qvideo.html) |
| QVOLUMEINFO | QOBJECT | `QVolumeInfo.inc` | Alain Besseleer alias Midipro2000, 1.0 | QVolumeInfo — невизуальный объект, получающий метку, серийный номер, файловую систему, размер, свободное место и тип диска. | [c_qvolumeinfo.html](../html_doc/c_qvolumeinfo.html) |
| QVUMETER | QCANVAS | `QVuMeter.inc` | 1.0 | Вертикальный столбиковый индикатор уровня (VU-метр), рисуемый на QCanvas. | [c_qvumeter.html](../html_doc/c_qvumeter.html) |
| QWAVE | QOBJECT | `QWave.inc` | 1.2 | Невизуальный объект для воспроизведения, записи, редактирования и сохранения WAV-файлов через строковые команды MCI. | [c_qwave.html](../html_doc/c_qwave.html) |
| QWEBCAM | QOBJECT | `VFW.inc` | John Kelly | Компонент захвата с веб-камеры: создаёт окно захвата Video for Windows (avicap32) на форме для предпросмотра, обработки кадров и сохранения кадров. | [c_qwebcam_vfw.html](../html_doc/c_qwebcam_vfw.html) |
| QWEBCAM | QOBJECT | `WebCam.inc` | John White (webcam.dll); wrapped as a component by JohnK | Невизуальная обёртка над webcam.dll: показ изображения веб-камеры на форме, запись видео, диалоги драйвера и захват кадров. | [c_qwebcam_webcam.html](../html_doc/c_qwebcam_webcam.html) |
| QXEDIT | QEDIT | `QxEdit.inc` | psyclops420 <psyclops420@yahoo.com>, 1.1 | Замена QEdit с подменой оконной процедуры: события OnGetFocus и OnLoseFocus, событие WndProc и опция перехода к следующему контролу по Enter. | [c_qxedit.html](../html_doc/c_qxedit.html) |
| QXPBUTTON | QBUTTON | `QXPButton.inc` | David Burkley (original Button_BMP_XP_Style code), edited by JohnK | Расширение QBUTTON, которое выводит картинку на кнопке в стиле Windows XP, передавая кнопке список изображений через BCM_SETIMAGELIST. | [c_qxpbutton.html](../html_doc/c_qxpbutton.html) |
| RQCONST | QSTRINGLIST | `QLibrary.Inc` |  | Список строк, загружающий определения CONST из include-файла RapidQ и возвращающий числовое значение константы по имени. | [c_rqconst.html](../html_doc/c_rqconst.html) |
| RSOCKET | QSOCKET | `RSocket.INC` | doctorelectron@cwdom.dm (Global Services) | Расширение QSocket с функциями Winsock: поиск имени и адреса хоста, адрес собеседника, прямое подключение с проверкой по тайм-ауту, режим блокировки, завершение соединения и текст ошибок. | [c_rsocket.html](../html_doc/c_rsocket.html) |
| TESTEDIT | QRICHEDIT | `TstRichEd.inc` |  | Небольшое тестовое расширение QRichEdit с одной функцией, возвращающей позицию первого символа строки, где стоит курсор. | [c_testedit.html](../html_doc/c_testedit.html) |
| XPGROUPBOX | QPANEL | `XP_MANIFEST.INC` | Paul Ludgate (xpGroupBox); file based on QXpTheme by Nicolas Tillet, additions by robin_q_master, modified for RQ2 by JohnK | Рамка группы (group box) в стиле Windows XP: тонкая скруглённая рамка с цветным заголовком, рисуемая на QCanvas внутри QPanel. | [c_xpgroupbox.html](../html_doc/c_xpgroupbox.html) |

## Одно имя — разные компоненты

Это не версии одного кода, а разные компоненты с одним именем типа. Подключить два файла с одним именем в одну программу нельзя.

- **QCOLORDIALOG**: `object/QColorDialog.inc` — Объект диалога выбора цвета на основе стандартного диалога Windows ChooseColor, с собственным заголовком, 16 пользовательскими цветами и вариантами раскрытия.; `QColorDialog.inc` — Невизуальная обёртка над стандартным диалогом выбора цвета Windows (ChooseColor), возвращающая цвет в виде RGB-значения и HTML-строки #RRGGBB.
- **QDATABASE**: `QDataBase.inc` — Невизуальный компонент простой файловой базы данных с записями фиксированной длины, с доступом к полям и функциями поиска.; `qdataBaseSQL.inc` — Объект базы данных ODBC: подключается к файлам Access, dBase, Paradox, Excel или текстовым и читает список таблиц и описания их полей.
- **QINI**: `object/QIni.inc` — QINI — невизуальный объект для чтения и записи значений в секции INI-файла и получения папок Windows, System и Temp.; `QWinIni.inc` — Невизуальный объект для чтения и записи INI-файлов Windows через функции GetPrivateProfileString.
- **QINIFILE**: `QIniFile.inc` — Чтение и запись INI-файлов на основе QStringList: поиск секций и ключей, методы чтения и записи чисел и строк.; `QLibrary.Inc` — Простой объект для чтения и записи INI-файла: отдельных значений или целых секций текстового INI-файла.
- **QMAXEDIT**: `RichEdPopUp.inc` — Расширение QRichEdit с контекстным меню как у стандартного поля Windows (Отменить, Вырезать, Копировать, Вставить, Удалить, Выделить всё) и функциями для позиций строк.; `ultraRichEd.inc` — QRichEdit с контекстным меню правки как в Windows (Отменить, Вырезать, Копировать, Вставить, Удалить, Выделить всё) и простой подсветкой ключевых слов.
- **QPROGRESS**: `object/QProgress.inc` — Индикатор выполнения: создаёт стандартный элемент Windows msctls_progress32 в родительском окне, заданном дескриптором.; `QProgress.inc` — Индикатор прогресса на основе QIMAGE: обычный QGAUGE или анимированная «бегущая» полоса (точка, прямоугольники, размытие, «парикмахерский столб») для задач неизвестной длительности.
- **QRICHEDIT_API**: `API_RichEdid.inc` — Незавершённая обёртка, создающая окно RichEdit напрямую через CreateWindowExA вместо QRICHEDIT.; `apiRe.inc` — Минимальная обёртка, создающая элемент Windows RichEdit (RICHED32.DLL) через CreateWindowEx, с перемещением, размером, показом и скрытием.
- **QWEBCAM**: `VFW.inc` — Компонент захвата с веб-камеры: создаёт окно захвата Video for Windows (avicap32) на форме для предпросмотра, обработки кадров и сохранения кадров.; `WebCam.inc` — Невизуальная обёртка над webcam.dll: показ изображения веб-камеры на форме, запись видео, диалоги драйвера и захват кадров.

## Редакции в rapidq2.inc и rapidq.inc

`rapidq2.inc` (JohnK, версия 1.4k, 2013) и `rapidq.inc` содержат свои редакции части компонентов. Они остаются в этих файлах; страница описывает отдельный файл, а редакция упомянута в разделе «Other versions» на ней.

- COMPORT: `rapidq2.inc`, строка 5177; есть только там: DCBFLAGS, INQUE, OUTQUE, PURGEIN, PURGEOUT, WRITE
- QABOUT: `rapidq2.inc`, строка 6214
- QBITMAPEX: `rapidq2.inc`, строка 4366; есть только там: ALPHABLEND, POINTER
- QCANVASEX: `rapidq2.inc`, строка 4884
- QCOLORDIALOG: `rapidq2.inc`, строка 6050; есть только там: HEIGHT, WIDTH, WINDOWHANDLE
- QCOLORDIALOG: `rapidq2.inc`, строка 6050; есть только там: CAPTION, COLOR, COLORS, HEIGHT, STYLE, WIDTH, WINDOWHANDLE
- QDEBUG: `rapidq.inc`, строка 1060; есть только там: BUG, ERR$, ERRNUM, FORM, PRINTSTR, PRINTWRAP, REDIT, ROWNUM, SETERROR, TESTSOCKETS, VISIBLE
- QDEBUG: `rapidq2.inc`, строка 6372; есть только там: BREAK, BREAKBUTTON, BUG, CHECKMATCH, CLEAR, CLEARWATCH, ERR$, ERRNUM, FORM, GRID, PRINTSTR, PRINTWRAP, REDIT, REORDER, ROWNUM, SETERROR, TESTSOCKETS, TIMER1, VISIBLE, WATCHCOUNT, WATCHDOUBLE, WATCHINT, WATCHSINGLE, WATCHSTRING, WATCHTIME
- QDFPANEL: `rapidq2.inc`, строка 3343
- QDOCKFORM: `rapidq2.inc`, строка 3361; есть только там: CLOSE
- QDRIVECOMBOBOX: `rapidq2.inc`, строка 6168
- QFILEDIALOG: `rapidq2.inc`, строка 5877
- QFORMEX: `rapidq2.inc`, строка 2339; есть только там: BINDINDEX, CENTER, DROPPOINT, FRMTIMER, GRABWINDOWPROC, ICOANIMATE, ICONANIMCOUNT, MODIFYTRAYICON, MYWNDPROC, ONGETFOCUS, ONLOSTFOCUS, ONMESSAGE, ONMOUSEWHEEL, REMOVETASKBAR, SETTRAYICONINDEX, TASKBAR, THISFUNCPTR, TRANSPARENT, TRANSPARENTCLIENT, TRAYICO, TRAYICONHINT, TRAYICONINDEX, TRAYICONUPDATE
- QFORMMDI: `rapidq2.inc`, строка 2707; есть только там: BINDINDEX
- QIMAGEEX: `rapidq2.inc`, строка 4788
- QLISTVIEWEX: `rapidq2.inc`, строка 6714; есть только там: HEIGHT, IX, IY, LEFT, LX, LY, TOP, VISIBLE, WIDTH
- QPAGESETUP: `rapidq2.inc`, строка 7139; есть только там: BINDINDEX, COLLATE, COPIES, DEFAULTSOURCE, DUPLEX, MYWNDPROC, PAPERSIZE, PRINTCOLOR, PRINTQUALITY

## Перенесены в inc/old (файлов: 61)

Правило: оставлена последняя версия — по номеру версии или дате в заголовке, по имени файла (QTButton95 > 94b > 94), по признакам в коде; из точных копий остаётся одна (в `inc/`, кроме тех, что RQdebugger подключает как `Object\...`). Файлы, которые подключаются из исходников в репозитории (RQdebugger844-40.bas, RQFormDsg2026-7.bas, DataParser15.bas, $DbgDisplay.bas, include других файлов), не переносились. `RqDataBuild` папку `old` пропускает.

| Файл в inc/old | Компонент | Оставлен | Причина |
|---|---|---|---|
| `QAbout.inc` | QABOUT | `object/QAbout.inc` | та же версия 1.2; в object/ — расчёт положения надписей, как в rapidq2.inc (2013) |
| `object/QAnim.inc` | QANIM | `QAnim.inc` | копия |
| `object/QBitmapEx.inc` | QBITMAPEX | `QBitmapEx.inc` | копия (отличаются только отступы) |
| `object/QCanvasEx.inc` | QCANVASEX | `QCanvasEx.inc` | в inc/ добавлен TextOut с прозрачным фоном |
| `object/Qcdaudio.inc` | QCDAUDIO | `Qcdaudio.inc` | копия |
| `QCoolBarXP90.inc` | QCOOLBARXP | `QCoolBarXPv1d.inc` | v1d — «полностью новая версия» (по заголовку) |
| `object/QCursor.inc` | QCURSOR | `QCursor.inc` | копия |
| `object/QDesktop.inc` | QDESKTOP | `QDesktop.inc` | копия |
| `QDirListView1.inc` | QDIRLISTVIEW | `qdirlistview.inc` | старее: абсолютные пути ресурсов, нет FilenameType/FilenameDate |
| `object/QDrawFocus.inc` | QDRAWFOCUS | `QDrawFocus.inc` | версия 1.2, в inc/ — 1.3 (2007) |
| `object/QDrawMenu.inc` | QDRAWMENU | `QDrawMenu.inc` | та же версия 1.3; в inc/ добавлена защита от повторного подключения |
| `object/QDrive.inc` | QDRIVE | `QDrive.inc` | та же версия; в inc/ добавлена защита от повторного подключения |
| `object/QDriveCombobox.inc` | QDRIVECOMBOBOX | `QDriveCombobox.inc` | копия |
| `QFileDialogDoc.inc` | QFILEDIALOG | `QFileDialog.inc` | тот же код 1.0 с русскими примечаниями к OPENFILENAME; RQdebugger подключает QFileDialog.inc |
| `object/QFileListView.inc` | QFILELISTVIEW | `QFileListView.inc` | версия 1.0, в inc/ — 1.1 |
| `object/QFlashLabel.inc` | QFLASHLABEL | `QFlashLabel.inc` | копия |
| `QFormEx.inc` | QFORMEX | `object/QFormEx.inc` | без версии, в object/ — 1.2 |
| `QFormMDI.inc` | QFORMMDI | `object/QFormMDI.inc` | та же версия 1.0; в object/ строки с application.hinstance заменены (исправление) |
| `object/QICON.inc` | QICON | `QICON.inc` | версия 1.1, в inc/ — 1.2 |
| `object/QImageDialog.inc` | QIMAGEDIALOG | `QImageDialog.inc` | версия 1.0, в inc/ — 1.1 |
| `QImageEx.inc` | QIMAGEEX | `object/QImageEx.inc` | без версии, в object/ — 1.1 (LoadOtherImage, декабрь 2003) |
| `QIni.inc` | QINI | `object/QIni.inc` | копия; RQdebugger подключает Object\QINI.inc |
| `object/QLine.inc` | QLINE | `QLine.inc` | копия |
| `cREdit.inc` | QMAXEDIT | `ultraRichEd.inc` | копия ultraRichEd.inc |
| `qmaxedit.inc` | QMAXEDIT | `RichEdPopUp.inc` | исходный вариант DHynes, из него сделан RichEdPopUp |
| `qREdit.inc` | QMAXEDIT | `ultraRichEd.inc` | копия ultraRichEd.inc |
| `RichEdPopUp1.inc` | QMAXEDIT | `RichEdPopUp.inc` | старее: нет LineFromPos; RQdebugger подключает RichEdPopUp.inc |
| `RichEdPopUpold.inc` | QMAXEDIT | `RichEdPopUp.inc` | старый вариант (по имени) |
| `QMaxSplitter.inc.txt` | QMAXSPLITTER | `QMaxSplitter.inc` | копия QSplitter.inc |
| `QSplitter.inc` | QMAXSPLITTER | `QMaxSplitter.inc` | старее: в QMaxSplitter.inc добавлены защиты $IFNDEF __WIN32API |
| `QSplitter.inc.txt` | QMAXSPLITTER | `QMaxSplitter.inc` | копия QSplitter.inc |
| `object/QMidi.inc` | QMIDI | `QMidi.inc` | копия |
| `qodbc.inc` | QODBC | `odbc.inc` | тот же компонент с тестовой программой ($APPTYPE CONSOLE) |
| `object/QPageSetup.inc` | QPAGESETUP | `QPageSetup.inc` | копия |
| `qposic.inc` | QPOSIC | `Qposic1.inc` | старее: в Qposic1.inc добавлены ресурсы кнопок |
| `object/QPrinterInfo.inc` | QPRINTERINFO | `QPrinterInfo.inc` | копия |
| `object/QProcess.inc` | QPROCESS | `QProcess.inc` | версия 1.0, в inc/ — 1.1 |
| `QREDEXTest.INC` | QREDEX | `QRedEx.Inc` | версия 1.0.0 (2005), в QRedEx.Inc — 1.2.1 (2006) |
| `QREDEXTest2.INC` | QREDEX | `QRedEx.Inc` | тестовый фрагмент |
| `object/QRun.inc` | QRUN | `QRun.inc` | ранний вариант без версии, в inc/ — 1.1 |
| `object/QSkin.inc` | QSKIN | `QSkin.inc` | копия |
| `object/QSkinBtn.inc` | QSKINBTN | `QSkinBtn.inc` | копия |
| `qspintextev.inc` | QSPINTEXT | `qspintext.inc` | промежуточный: нет OnChange, BgColor, FontColor |
| `qspintextOld.inc` | QSPINTEXT | `qspintext.inc` | старый вариант (по имени) |
| `object/QSplash.inc` | QSPLASH | `QSplash.inc` | версия 1.1, в inc/ — 1.2 |
| `QStatusBarEx.inc` | QSTATUSBAREX | `object/QStatusBarEx.inc` | копия; RQdebugger подключает Object\QStatusBarEx.inc |
| `object/QStringGridEx.inc` | QSTRINGGRIDEX | `QStringGridEx.inc` | копия |
| `QTButton.inc` | QTBUTTON | `QTButton95.inc` | копия QTButton85b.inc |
| `QTButton72.inc` | QTBUTTON | `QTButton95.inc` | версия 72 |
| `QTButton85b.inc` | QTBUTTON | `QTButton95.inc` | версия 85b |
| `QTButton94.inc` | QTBUTTON | `QTButton95.inc` | версия 94 |
| `QTButton94b.inc` | QTBUTTON | `QTButton95.inc` | версия 94b |
| `object/QTextBtn.inc` | QTEXTBTN | `QTextBtn.inc` | копия |
| `object/QTextEdit.inc` | QTEXTEDIT | `QTextEdit.inc` | копия |
| `QTextEditTest.inc` | QTEXTEDIT | `QTextEdit.inc` | тестовый вариант |
| `object/QVideo.inc` | QVIDEO | `QVideo.inc` | та же версия 1.3; в inc/ добавлена защита от повторного подключения |
| `object/QVuMeter.inc` | QVUMETER | `QVuMeter.inc` | копия |
| `object/QWave.inc` | QWAVE | `QWave.inc` | копия |
| `vfw2.inc` | QWEBCAM | `VFW.inc` | старее (1998); в VFW.inc (2007) больше свойств |
| `qEditEx.inc` | QXEDIT | `QxEdit.inc` | копия (в QxEdit.inc объявлен CallWindowProc) |
| `xp_manifest1.inc` | XPGROUPBOX | `XP_MANIFEST.INC` | копия |

## Выбор по косвенным признакам

Здесь версию нельзя было определить по номеру или дате. При необходимости файлы можно поменять местами (git mv).

- **QABOUT**: Обе копии — версия 1.2. Оставлена object/QAbout.inc: она совпадает с QAbout из rapidq2.inc (2013) на 99 %.
- **QCANVASEX**: object/ помечена 1.2, в inc/ версии нет, но есть TextOut, которого нет в 1.2. Оставлена inc/QCanvasEx.inc.
- **QFORMMDI**: Обе — 1.0. Оставлена object/: в ней старые строки закомментированы и заменены, значит её правили позже.
- **QMAXEDIT**: Две ветки одного компонента: RichEdPopUp.inc (подключён в RQdebugger, функции строк) и ultraRichEd.inc (подсветка синтаксиса). Оставлены обе; вместе их подключить нельзя — одно имя типа.
- **QPOSIC**: В Qposic1.inc ресурсы кнопок заданы абсолютными путями (C:\_F\bas\rapidq\RQIDE\inc\…).
- **QRICHEDIT_API**: API_RichEdid.inc и apiRe.inc — варианты одного кода, который новее, не видно. Оставлены оба.

## Что не трогалось

- Файлы без компонентов (объявления Windows API, константы, функции) — 143 файлов. Среди них тоже есть старые варианты (`Files1.inc`, `Files2.inc`, `FilesBug.inc`, `conversionOld.inc`, `RAPIDQl.INC`, `RAPIDQbug.INC`, `rapidq2007.inc`, `rapidq_ex.inc`), но они вне этого списка.
- `rapidq_ref/ComponentAll.data` не пересобирался: полная пересборка `RqDataBuild` меняет и другие части файла (убирает комментарии в начале), а для QINI взяла бы `QWinIni.inc` (другой компонент). В нём у части классов строка `'@source` указывает на файлы, которые теперь в `old` (QTButton.inc, QAbout.inc, qposic.inc и др.); она только показывается в подсказке конструктора.
