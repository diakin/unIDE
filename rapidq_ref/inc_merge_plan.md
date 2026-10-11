# План сведения inc: rapidqAllProc.inc и rapidqComponents.inc

Составлено скриптом по rapidq_ref/inc_good (2026-10-11; с того же дня эти файлы - rapidq_ref/incOld, inc_good удалена). Дата файла - из inc_sort_list.md (архив RQIDEdistr2026inc; «inc2026» - исправленный файл, новее архива; «?» - даты нет).

Колонка «Брать» - предложение по умолчанию; поменяйте, где нужно другое. Решение по умолчанию: из нескольких версий класса - самая новая по дате; при равной дате - версия из rapidq2.inc (она уже проверена переводчиком), иначе самый большой файл.


Итого: файлов 292; классов в нескольких файлах 31; констант с разными числами 19.


## 1. Классы компонентов, которые есть в нескольких файлах

| Класс | Файлы (строк, дата) | Брать |
|---|---|---|
| Comport | ComPort.inc (572, ?)<br>rapidq2.inc (8183, inc2026) | rapidq2.inc |
| QAbout | QAbout.inc (165, ?)<br>rapidq2.inc (8183, inc2026) | rapidq2.inc |
| QBitmapEx | QBitmapEx.inc (369, inc2026)<br>rapidq2.inc (8183, inc2026) | rapidq2.inc |
| QCanvasEx | QCanvasEx.inc (365, 2004-03-17)<br>rapidq2.inc (8183, inc2026) | rapidq2.inc |
| QColorDialog | QColorDialog10.inc (107, ?)<br>QColorDialog11.inc (123, ?)<br>rapidq2.inc (8183, inc2026) | rapidq2.inc |
| QCoolBarXP | QCoolBarXP90.inc (2787, 2005-11-10)<br>QCoolBarXPv1d.inc (2269, inc2026) | QCoolBarXPv1d.inc |
| QDataBase | QDataBase.inc (693, inc2026)<br>qdataBaseSQL.inc (795, ?) | QDataBase.inc |
| QDebug | QDebug.inc (61, inc2026)<br>rapidq2.inc (8183, inc2026) | rapidq2.inc |
| QDFPANEL | QDOCKFORM.inc (1036, inc2026)<br>rapidq2.inc (8183, inc2026) | rapidq2.inc |
| QDOCKFORM | QDOCKFORM.inc (1036, inc2026)<br>rapidq2.inc (8183, inc2026) | rapidq2.inc |
| QDrive | QDrive.inc (108, 2012-09-09)<br>qdrive2024.inc (108, 2024-03-03) | qdrive2024.inc |
| QDriveComboBox | QDriveCombobox.inc (48, inc2026)<br>rapidq2.inc (8183, inc2026) | rapidq2.inc |
| QFILEDIALOG | QFileDialog.inc (251, inc2026)<br>QFileDialogDoc.inc (402, 2021-04-29)<br>rapidq2.inc (8183, inc2026) | rapidq2.inc |
| QFormEx | QFormEx.inc (179, inc2026)<br>rapidq2.inc (8183, inc2026) | rapidq2.inc |
| QFormMDI | QFormMDI.inc (694, inc2026)<br>rapidq2.inc (8183, inc2026) | rapidq2.inc |
| QImageEx | QImageEx.inc (111, inc2026)<br>rapidq2.inc (8183, inc2026) | rapidq2.inc |
| QINI | QIni.inc (122, inc2026)<br>QWinIni.inc (113, 2004-03-17) | QIni.inc |
| QIniFile | QIniFile.inc (211, 2009-06-15)<br>QLibrary.Inc (379, 2005-11-10) | QIniFile.inc |
| Qlistviewex | QListviewEx.inc (332, 2004-03-17)<br>rapidq2.inc (8183, inc2026) | rapidq2.inc |
| QMAXEDIT | RichEdPopUp.inc (150, 2008-07-09)<br>RichEdPopUp1.inc (136, 2006-05-08)<br>RichEdPopUpold.inc (161, 2005-01-13)<br>cREdit.inc (218, 2004-03-17)<br>qREdit.inc (218, ?)<br>qmaxedit.inc (91, 2004-03-17)<br>ultraRichEd.inc (218, 2004-03-17) | RichEdPopUp.inc |
| QMAXSPLITTER | QMaxSplitter.inc (264, inc2026)<br>QSplitter.inc (349, 2008-07-09) | QMaxSplitter.inc |
| qODBC | odbc.inc (324, inc2026)<br>qodbc.inc (380, 2005-01-05) | odbc.inc |
| QPageSetup | QPageSetup.inc (208, ?)<br>rapidq2.inc (8183, inc2026) | rapidq2.inc |
| QRedEx | QREDEXTest.INC (613, 2005-09-26)<br>QREDEXTest2.INC (15, 2005-09-26)<br>QRedEx.Inc (573, inc2026) | QRedEx.Inc |
| QRichEdit_api | API_RichEdid.inc (215, 2004-03-17)<br>apiRe.inc (167, 2004-03-17) | apiRe.inc |
| Qspintext | qspintext.inc (133, 2004-06-15)<br>qspintextOld.inc (80, 2004-04-20)<br>qspintextev.inc (91, 2004-04-20) | qspintext.inc |
| QTButton | QTButton.inc (720, 2005-11-10)<br>QTButton72.inc (364, 2005-11-10)<br>QTButton85b.inc (720, 2005-11-10)<br>QTButton94.inc (1251, 2005-11-10)<br>QTButton94b.inc (1443, 2005-11-10)<br>QTButton95.inc (1448, 2005-11-10) | QTButton95.inc |
| QTEXTEDIT | QTextEdit.inc (225, inc2026)<br>QTextEditTest.inc (83, 2005-09-26) | QTextEdit.inc |
| QWebCam | VFW.inc (1140, inc2026)<br>WebCam.inc (221, 2008-07-09)<br>vfw2.inc (1096, 2012-03-21) | VFW.inc |
| QxEDIT | QxEdit.inc (71, 2004-02-20)<br>qEditEx.inc (71, 2021-02-26) | qEditEx.inc |
| XpGroupBox | XP_MANIFEST.INC (136, inc2026)<br>xp_manifest1.inc (136, 2021-04-10) | XP_MANIFEST.INC |

## 2. Файлы с компонентами (кандидаты в rapidqComponents.inc)

| Файл | Строк | Дата | Классы (базовый) | Брать |
|---|---|---|---|---|
| API_RichEdid.inc | 215 | 2004-03-17 | QRichEdit_api (QObject) | нет: черновик - внутри TYPE строки "dim Line as ARRAY of STRING" (список свойств), RapidQ такой тип не знает; взят apiRe.inc |
| COMPORTxp.inc | 556 | ? | MyCom_Port (QObject) | да |
| ComPort.inc | 572 | ? | Comport (QObject) | да |
| HiLight.inc | 141 | 2004-03-17 | QREdit (QRichEdit) | да |
| QAVI.inc | 790 | inc2026 | QAVI (Qobject) | да |
| QAbout.inc | 165 | ? | QAbout (QOBJECT) | да |
| QAnim.inc | 124 | inc2026 | QAnim (QImage) | да |
| QAnimate.inc | 373 | inc2026 | QAnimate (QObject) | да |
| QBevel.inc | 93 | inc2026 | QBEVEL (QPANEL) | да |
| QBitmapEx.inc | 369 | inc2026 | QBitmapEx (QBITMAP) | да |
| QBrowseDialog.inc | 107 | 2020-10-15 | QBROWSEDIALOG (QOBJECT) | да |
| QButtonXP.INC | 44 | inc2026 | QButtonXP (QButton) | да |
| QCanvasEx.inc | 365 | 2004-03-17 | QCanvasEx (QCANVAS) | да |
| QChart.inc | 2372 | inc2026 | QCHART (QCANVAS) | да |
| QColorButton.inc | 29 | ? | QCOLORBUTTON (QPANEL) | да |
| QColorDialog10.inc | 107 | ? | QColorDialog (QOBJECT) | да |
| QColorDialog11.inc | 123 | ? | QCOLORDIALOG (QOBJECT) | да |
| QCoolBarXP90.inc | 2787 | 2005-11-10 | QCoolBarXP (QPanel) | да |
| QCoolBarXPv1d.inc | 2269 | inc2026 | QCoolBarXP (QPanel) | да |
| QCursor.inc | 78 | 2008-07-09 | QCursor (QObject) | да |
| QDOCKFORM.inc | 1036 | inc2026 | QDFPANEL (QPANEL), QDOCKFORM (QPANEL) | да |
| QDataBase.inc | 693 | inc2026 | QDataBase (QObject) | да |
| QDebug.inc | 61 | inc2026 | QDebug (QObject) | да |
| QDesktop.inc | 75 | 2008-07-09 | QDesktop (QObject) | да |
| QDigDisplay.inc | 77 | 2008-07-09 | QDigDisplay (QCanvas) | да |
| QDir.Inc | 732 | inc2026 | QDir (QObject) | да |
| QDirListView1.inc | 343 | 2009-03-24 | QDirListView (QListView) | нет: $RESOURCE на файлы, которых нет в inc; подключать отдельно |
| QDrawFocus.inc | 301 | inc2026 | QDrawFocus (QOBJECT) | да |
| QDrawMenu.inc | 318 | 2008-07-09 | QdrawMenu (QOBJECT) | да, строки 1-228 (дальше пример программы) |
| QDrive.inc | 108 | 2012-09-09 | QDrive (QObject) | да |
| QDriveCombobox.inc | 48 | inc2026 | QDriveComboBox (QComboBox) | да |
| QFTPCLIENT.INC | 581 | ? | QFtpClient (QObject) | да |
| QFileDialog.inc | 251 | inc2026 | QFILEDIALOG (QOBJECT) | да |
| QFileDialogDoc.inc | 402 | 2021-04-29 | QFILEDIALOG (QOBJECT) | да |
| QFileListView.inc | 275 | 2008-07-09 | QFileListView (QListView) | да |
| QFlashLabel.inc | 92 | 2008-07-09 | QFlashLabel (QLabel) | да |
| QFlatButton.inc | 97 | inc2026 | QFlatButton (QImage) | да |
| QFormEx.inc | 179 | inc2026 | QFormEx (QFORM) | да |
| QFormMDI.inc | 694 | inc2026 | QFormMDI (QFORM) | да |
| QGL.inc | 859 | inc2026 | QGL (QOBJECT), QMD2model (QMEMORYSTREAM) | да |
| QGridColor.inc | 184 | 2005-11-10 | QGridColor (QPanel) | да |
| QHTML.inc | 2050 | inc2026 | QHTML (QPanel) | да |
| QHead.inc | 118 | inc2026 | QHead (QCanvas) | да |
| QICMP.INC | 152 | ? | QICMP (QObject) | да |
| QICON.inc | 353 | 2010-12-31 | QICON (QOBJECT) | да |
| QImageBox.inc | 281 | 2008-07-09 | QImageBox (QScrollbox) | да |
| QImageDialog.inc | 595 | 2008-07-09 | QImageDialog (QObject) | да |
| QImageEx.inc | 111 | inc2026 | QImageEx (QIMAGE) | да |
| QImageListEx.inc | 87 | 2013-08-11 | QImageListEX (QImageList) | да |
| QIni.inc | 122 | inc2026 | QINI (QObject) | да |
| QIniFile.inc | 211 | 2009-06-15 | QIniFile (QstringList) | да |
| QInputBox.inc | 102 | 2005-11-10 | QInputBox (QObject) | да |
| QLed.inc | 62 | inc2026 | QLed (QCanvas) | да |
| QLedScroll.inc | 58 | 2005-11-10 | QLEDSCROLL (QCANVAS) | да |
| QLibrary.Inc | 379 | 2005-11-10 | RQConst (QStringList), QIniFile (QObject) | да |
| QLine.inc | 42 | ? | QLine (QCanvas) | да |
| QListBoxEx.inc | 35 | 2008-07-09 | QListBoxEx (QListBox) | да |
| QListviewEx.inc | 332 | 2004-03-17 | Qlistviewex (Qlistview) | да |
| QMailLabel.inc | 61 | ? | QMailLabel (QLabel) | да |
| QMarker.inc | 51 | 2005-11-10 | QMarker (QPanel) | нет: $RESOURCE на файлы, которых нет в inc; подключать отдельно |
| QMaxSplitter.inc | 264 | inc2026 | QMAXSPLITTER (QPANEL) | да |
| QMidi.inc | 253 | inc2026 | QMidi (Qobject) | да |
| QPageSetup.inc | 208 | ? | QPageSetup (QOBJECT) | да |
| QPrinterInfo.inc | 157 | inc2026 | QPrinterInfo (QObject) | да |
| QProcess.inc | 111 | inc2026 | QProcess (QObject) | да |
| QProgress.inc | 298 | 2010-10-25 | QProgress (QIMAGE) | да |
| QProgressBar.inc | 288 | inc2026 | QProgressBar (QOBJECT) | да |
| QREDEXTest.INC | 613 | 2005-09-26 | QRedEx (QRichEdit) | да |
| QREDEXTest2.INC | 15 | 2005-09-26 | QRedEx (QRichEdit) | да |
| QRedEx.Inc | 573 | inc2026 | QRedEx (QRichEdit) | да |
| QRichEditXt.inc | 522 | inc2026 | QRichEdit_xt (QRichEdit) | да |
| QRun.inc | 209 | inc2026 | QRun (QObject) | да |
| QSHFileOperation.inc | 249 | inc2026 | QSHFileOperation (QObject) | да |
| QSavePlus.inc | 282 | 2008-07-10 | QSaveplus (QSaveDialog) | да, строки 1-216 (дальше пример программы) |
| QShutdown.inc | 116 | inc2026 | QShutDown (QOBJECT) | да |
| QSkin.inc | 69 | 2008-07-09 | QSkin (QForm) | да |
| QSkinBtn.inc | 115 | 2008-07-09 | QSkinBtn (qimage) | да |
| QSocketEx.inc | 295 | inc2026 | QSocketEx (QSocket) | да |
| QSpinEdit.inc | 158 | inc2026 | QSpinButton (QPanel) | да |
| QSplash.inc | 83 | 2008-07-19 | QSplash (QObject) | да |
| QSplitter.inc | 349 | 2008-07-09 | QMAXSPLITTER (QPANEL) | да, строки 1-255 (дальше пример программы) |
| QStatusBarEx.inc | 40 | inc2026 | QStatusBarEx (QSTATUSBAR) | да |
| QTButton.inc | 720 | 2005-11-10 | QTButton (QButton) | да |
| QTButton72.inc | 364 | 2005-11-10 | QTButton (QButton) | да |
| QTButton85b.inc | 720 | 2005-11-10 | QTButton (QButton) | да |
| QTButton94.inc | 1251 | 2005-11-10 | QTButton (QButton) | да |
| QTButton94b.inc | 1443 | 2005-11-10 | QTButton (QButton) | да |
| QTButton95.inc | 1448 | 2005-11-10 | QTButton (QButton) | да |
| QTextBtn.inc | 88 | 2010-06-21 | QTextBtn (QLabel) | да |
| QTextEdit.inc | 225 | inc2026 | QTEXTEDIT (QRICHEDIT) | да |
| QTextEditTest.inc | 83 | 2005-09-26 | QTEXTEDIT (QRICHEDIT) | да |
| QThread.inc | 102 | ? | QThread (QObject) | да |
| QToolBar.inc | 590 | inc2026 | QToolBar (QObject) | да |
| QToolBarEX.inc | 291 | 2013-08-11 | QToolBarEX (QPANEL) | да |
| QTreeviewEx.inc | 226 | inc2026 | QtreeviewEx (Qtreeview) | да |
| QVideo.inc | 472 | ? | QVideo (Qobject) | да |
| QVolumeInfo.inc | 203 | inc2026 | QVolumeInfo (QObject) | да |
| QVuMeter.inc | 87 | 2008-07-09 | QVuMeter (QCanvas) | да |
| QWave.inc | 429 | inc2026 | QWave (Qobject) | да |
| QWinIni.inc | 113 | 2004-03-17 | QINI (QObject) | да |
| QXPButton.inc | 502 | 2010-08-11 | QXPBUTTON (QBUTTON) | да |
| Qcdaudio.inc | 304 | inc2026 | Qcdaudio (Qobject) | да |
| Qid3Tag.inc | 134 | inc2026 | Qid3tag (QObject) | да |
| Qmp3.inc | 455 | inc2026 | Qmp3 (QObject) | да |
| QrPanel.inc | 45 | 2008-07-18 | QrPanel (QPanel) | да |
| QtabControlEx.inc | 79 | inc2026 | QTabControlEx (QTabControl) | да |
| QxEdit.inc | 71 | 2004-02-20 | QxEDIT (QEDIT) | да |
| RC4crypt.inc | 126 | 2009-09-21 | QRC4 (QOBJECT) | да |
| RSocket.INC | 202 | inc2026 | RSocket (QSocket) | да |
| RapidFRM.inc | 359 | 2021-02-28 | QColorDlg (QFORM) | да |
| RichEdPopUp.inc | 150 | 2008-07-09 | QMAXEDIT (QRICHEDIT) | да |
| RichEdPopUp1.inc | 136 | 2006-05-08 | QMAXEDIT (QRICHEDIT) | да |
| RichEdPopUpold.inc | 161 | 2005-01-13 | QMAXEDIT (QRICHEDIT) | да |
| TstRichEd.inc | 16 | 2004-09-23 | TestEDIT (QRICHEDIT) | да |
| VFW.inc | 1140 | inc2026 | QWebCam (QOBJECT) | да |
| WebCam.inc | 221 | 2008-07-09 | QWebCam (QOBJECT) | нет: при подключении сразу вызывает webcam.dll; подключать отдельно |
| XPSkinMetallic_2.11_Res.inc | 1515 | inc2026 | myXPSkinnedForm (QForm) | нет: нужны ресурсы Resources2.inc и CONST myMainFormName в программе; подключать отдельно |
| XPThemes.inc | 479 | 2009-06-15 | QRichEditUx (QRICHEDIT), QScrollBoxUx (QSCROLLBOX), QStringGridUx (QStringGrid), QPanelUx (QPanel), QGroupBoxUx (QGROUPBOX) | да |
| XP_MANIFEST.INC | 136 | inc2026 | XpGroupBox (QPANEL) | да |
| apiRe.inc | 167 | 2004-03-17 | QRichEdit_api (QObject) | да |
| cREdit.inc | 218 | 2004-03-17 | QMAXEDIT (QRICHEDIT) | да |
| odbc.inc | 324 | inc2026 | qODBC (QOBJECT) | да |
| qEditEx.inc | 71 | 2021-02-26 | QxEDIT (QEDIT) | да |
| qREdit.inc | 218 | ? | QMAXEDIT (QRICHEDIT) | да |
| qcalendar.inc | 393 | inc2026 | qcalendar (Qpanel) | да |
| qcgi.inc | 396 | ? | QCGI (QOBJECT) | да |
| qciccio.inc | 8 | 2005-11-10 | Qciccio (QOBJECT) | нет: пробный класс (поле AS ciccino - такого типа нет) |
| qdataBaseSQL.inc | 795 | ? | qDATABASE (QOBJECT), qSQLTABLE (QOBJECT) | да |
| qdownload.inc | 258 | inc2026 | Qdownload (qobject) | да |
| qdrive2024.inc | 108 | 2024-03-03 | QDrive (QObject) | да |
| qfocus.inc | 302 | ? | QFocus (QCanvas) | да |
| qgraph.inc | 180 | inc2026 | QLineGraph (qobject) | да |
| qmaxedit.inc | 91 | 2004-03-17 | QMAXEDIT (QRICHEDIT) | да |
| qmenu.inc | 182 | inc2026 | QMenu (QOBJECT) | да |
| qodbc.inc | 380 | 2005-01-05 | qODBC (Qobject) | да, строки 1-323 (дальше пример программы) |
| qposic.inc | 176 | 2004-03-17 | Qposic (qpanel) | да |
| qspintext.inc | 133 | 2004-06-15 | Qspintext (qpanel) | да |
| qspintextOld.inc | 80 | 2004-04-20 | Qspintext (qpanel) | да |
| qspintextev.inc | 91 | 2004-04-20 | Qspintext (qpanel) | да |
| ultraRichEd.inc | 218 | 2004-03-17 | QMAXEDIT (QRICHEDIT) | да |
| vfw2.inc | 1096 | 2012-03-21 | QWebCam (QOBJECT) | да |
| xp_manifest1.inc | 136 | 2021-04-10 | XpGroupBox (QPANEL) | да |

## 3. Файлы с константами, DECLARE и процедурами (кандидаты в rapidqAllProc.inc)

Особые библиотеки (OpenGL, DAQmx, ODBC, MySQL и т.п.) помечены «?» - нужны ли они в общем файле, решите.

| Файл | Строк | Дата | CONST/$DEFINE | DECLARE | SUB/FUNCTION | Подключает | Брать |
|---|---|---|---|---|---|---|---|
| ACE32.INC | 903 | 2008-07-09 | 439 | 302 | 0 |  | ? |
| AddMenuItemBitmaps4a.inc | 125 | 2005-11-10 | 7 | 10 | 2 |  | да |
| AdvAPI32.inc | 16 | 2000-06-27 | 0 | 1 | 0 |  | да |
| AllProps.inc | 283 | 2005-11-10 | 0 | 0 | 0 |  | нет: фрагмент программы (объекты и процедуры основной программы) |
| Api.inc | 116 | 2004-03-17 | 41 | 7 | 0 |  | да |
| ApiDate.inc | 73 | inc2026 | 0 | 4 | 2 |  | да |
| CMD5.inc | 818 | 2012-09-11 | 21 | 0 | 16 |  | да |
| CM_Constants.inc | 895 | 2004-03-17 | 404 | 0 | 0 |  | нет: часть CodeSense (cmcs21.dll), тип Bool - из $Define Bool Integer в CodeSense.inc; подключать CodeSense.inc |
| CM_Functions.inc | 590 | 2004-03-17 | 2 | 5 | 68 |  | нет: часть CodeSense (cmcs21.dll), тип Bool - из $Define Bool Integer в CodeSense.inc; подключать CodeSense.inc |
| C_Constants.inc | 869 | 2004-03-17 | 404 | 0 | 0 |  | нет: часть CodeSense (cmcs21.dll), тип Bool - из $Define Bool Integer в CodeSense.inc; подключать CodeSense.inc |
| CallBackAll.Inc | 54 | 2006-08-18 | 0 | 0 | 0 | CallBack_0.Inc, CallBack_1.Inc, CallBack_2.Inc, CallBack_3.Inc ... | да |
| CallBackForwarder.Inc | 81 | 2006-08-18 | 1 | 2 | 1 |  | да |
| CallBack_0.Inc | 60 | inc2026 | 2 | 4 | 3 |  | да |
| CallBack_1.Inc | 61 | inc2026 | 2 | 4 | 3 |  | да |
| CallBack_2.Inc | 61 | inc2026 | 2 | 4 | 3 |  | да |
| CallBack_3.Inc | 61 | inc2026 | 2 | 4 | 3 |  | да |
| CallBack_4.Inc | 61 | inc2026 | 2 | 4 | 3 |  | да |
| CallBack_5.Inc | 61 | inc2026 | 2 | 4 | 3 |  | да |
| CallBack_6.Inc | 63 | inc2026 | 2 | 4 | 3 |  | да |
| CallBack_7.Inc | 61 | inc2026 | 2 | 4 | 3 |  | да |
| CallBack_8.Inc | 61 | inc2026 | 2 | 4 | 3 |  | да |
| CallBacks.Inc | 56 | inc2026 | 1 | 0 | 0 | CallBack_0.Inc, CallBack_1.Inc, CallBack_2.Inc, CallBack_3.Inc ... | да |
| CodeSense.inc | 1163 | 2005-11-10 | 32 | 943 | 0 | Win32_constants.inc, CM_Constants.inc, CM_Functions.inc | нет: $RESOURCE на файлы, которых нет в inc; подключать отдельно |
| CommCtrl.inc | 1502 | 2008-11-27 | 840 | 1 | 0 |  | да |
| Common.inc | 38 | 2004-02-23 | 2 | 4 | 1 |  | да |
| Control.inc | 137 | 2004-03-17 | 0 | 0 | 22 |  | да |
| ConvertToTruePath.inc | 39 | 2026-10-09 | 1 | 1 | 1 |  | да |
| Copy of NOTA.inc | 525 | ? | 10 | 19 | 19 |  | да |
| DAQmx.inc | 741 | 2008-06-06 | 13 | 213 | 0 |  | ? |
| DAQmxConst.inc | 1448 | 2008-06-05 | 979 | 0 | 0 |  | ? |
| DBT.INC | 156 | 2004-03-17 | 1 | 0 | 6 |  | да |
| Dbase.inc | 652 | 2004-03-17 | 0 | 0 | 32 |  | ? |
| DxfONE!h.inc | 202 | 2004-03-17 | 0 | 5 | 5 |  | ? |
| FBFunctions.inc | 25 | 2006-11-20 | 0 | 4 | 1 |  | да |
| FileUtils.inc | 157 | 2004-03-17 | 0 | 0 | 5 |  | да |
| Files.inc | 1486 | inc2026 | 19 | 7 | 42 |  | да |
| Files1.inc | 1256 | 2004-01-28 | 8 | 3 | 36 |  | да |
| Files2.inc | 1284 | 2004-01-28 | 8 | 3 | 36 |  | да |
| FilesBug.inc | 27 | 2005-01-15 | 0 | 0 | 1 |  | да |
| Form.inc | 104 | 2006-07-24 | 15 | 0 | 2 |  | да |
| Form1.inc | 15 | 2005-11-10 | 0 | 0 | 0 |  | да |
| Functions.inc | 219 | 2004-03-17 | 0 | 4 | 19 |  | нет: часть CodeSense (cmcs21.dll), тип Bool - из $Define Bool Integer в CodeSense.inc; подключать CodeSense.inc |
| GDI32.inc | 77 | 2000-06-27 | 0 | 4 | 0 |  | да |
| Kernel32.inc | 214 | 2000-06-29 | 0 | 27 | 0 |  | да |
| LabelGrid.inc | 76 | 2005-02-18 | 0 | 0 | 0 |  | да |
| LangIniHeader.inc | 21 | 2008-08-12 | 0 | 0 | 0 |  | нет: фрагмент программы (StartPath$, DIM LangIni AS QINI - класс из компонентов) |
| MDI_API.INC | 96 | 2008-07-18 | 41 | 14 | 0 |  | да |
| MYSQL.INC | 60 | ? | 45 | 0 | 0 |  | ? |
| Math.inc | 541 | 2016-07-04 | 6 | 0 | 50 |  | да |
| Memory.inc | 238 | inc2026 | 14 | 7 | 24 |  | да |
| Minimize.inc | 5 | 2007-01-25 | 0 | 1 | 1 |  | да |
| NI6210.inc | 390 | 2010-03-18 | 3 | 19 | 0 | DAQmxConst.inc | ? |
| NOTA.inc | 616 | 2000-07-07 | 11 | 23 | 23 |  | да |
| NewWindow23.inc | 0 | 2005-09-25 | 0 | 0 | 0 |  | да |
| NewWndProc.Inc | 53 | 2026-10-09 | 2 | 5 | 2 |  | да |
| ODMenuXP.inc | 2928 | 2005-11-10 | 207 | 77 | 33 |  | да |
| PRINTERDLL.INC | 420 | 2004-11-09 | 172 | 235 | 0 |  | да |
| QDXF.inc | 258 | 2005-11-10 | 0 | 9 | 9 |  | ? |
| QFiles.inc | 125 | ? | 1 | 8 | 8 |  | да |
| QFormLocale.inc | 154 | 2009-09-05 | 7 | 2 | 1 |  | да |
| QFormSkin.inc | 1106 | 2005-11-10 | 99 | 45 | 13 |  | да |
| QFuncLib.inc | 204 | 2006-05-26 | 1 | 0 | 17 |  | да |
| QPoint.inc | 10 | 2005-11-10 | 0 | 0 | 1 |  | да |
| QPrintDialog.inc | 60 | 2005-11-10 | 18 | 1 | 0 |  | да |
| QStringGridEx.inc | 44 | 2008-07-09 | 3 | 0 | 1 |  | да |
| QTButton_AddOns.inc | 1112 | 2005-11-10 | 23 | 13 | 4 |  | нет: дополнение к QTButton, нужен ресурс btn_BMP в программе; подключать отдельно |
| QXLS.INC | 771 | ? | 42 | 25 | 25 |  | да |
| QXpTheme.INC | 38 | 2005-11-10 | 0 | 0 | 0 |  | да |
| RQDialog.inc | 105 | 2004-03-17 | 3 | 2 | 1 |  | да |
| RQDxf.inc | 256 | 2004-03-17 | 0 | 9 | 9 |  | ? |
| RQProcess.inc | 202 | 2008-07-07 | 30 | 14 | 5 |  | да |
| RQdate.inc | 287 | 2008-01-22 | 11 | 18 | 7 |  | да |
| RapidFRM_Mods.inc | 75 | 2021-02-28 | 0 | 3 | 3 |  | нет: фрагмент программы (объекты и процедуры основной программы) |
| Resources2.inc | 55 | 2005-11-10 | 0 | 0 | 0 |  | нет: $RESOURCE на файлы, которых нет в inc; подключать отдельно |
| RichEditApi.inc | 457 | 2004-03-17 | 206 | 0 | 0 |  | да, строки 1-226 (дальше структуры, недопереведённые с ассемблера: "AS AS COLORREF", "CHARRANGE <>") |
| RqAsmUtils.Inc | 495 | 2008-07-09 | 0 | 1 | 22 |  | да |
| SetFileTimeAttrib.inc | 243 | 2004-07-04 | 14 | 7 | 1 |  | да |
| Shell32.inc | 41 | 2000-06-27 | 0 | 3 | 0 |  | да |
| ShellRedir.Inc | 232 | 2011-02-23 | 5 | 8 | 1 |  | да |
| Splash.inc | 54 | 2006-02-19 | 0 | 0 | 0 |  | нет: фрагмент программы (заставка, CREATE формы и показ) |
| SplashForm.inc | 33 | 2005-11-10 | 0 | 1 | 1 |  | нет: фрагмент программы (заставка, CREATE формы и показ) |
| StayOnTop.inc | 30 | 2005-11-10 | 4 | 2 | 1 |  | да |
| SysUtils.inc | 120 | inc2026 | 1 | 0 | 10 |  | да |
| TRM_RQDeclares.INC | 121 | 2004-03-17 | 43 | 1 | 0 |  | да |
| TestIncPAth.inc | 0 | 2005-09-25 | 0 | 0 | 0 |  | да |
| User32.inc | 235 | 2000-07-07 | 45 | 26 | 0 |  | да |
| WFunctions.inc | 50 | 2005-11-10 | 6 | 13 | 0 |  | да |
| WIN32API.INC | 15648 | 2007-05-02 | 5 | 1514 | 0 |  | да |
| WINDOWS.INC | 16045 | 2021-12-15 | 1083 | 1526 | 0 |  | да |
| Wad3.inc | 316 | 2004-03-17 | 2 | 2 | 2 |  | ? |
| Win32_constants.inc | 337 | 2004-03-17 | 279 | 0 | 0 |  | да |
| WinMM.Inc | 31 | 2000-06-28 | 0 | 3 | 0 |  | да |
| WindowsAPI.inc | 89 | 2000-07-01 | 14 | 0 | 0 | AdvAPI32.inc, GDI32.inc, Kernel32.inc, Shell32.inc ... | да |
| cgi.inc | 139 | 2008-07-09 | 0 | 0 | 5 |  | ? |
| commctrl32.inc | 1564 | ? | 1349 | 57 | 0 |  | да |
| constants.inc | 273 | 2026-10-09 | 147 | 2 | 1 |  | да |
| conversion.inc | 1190 | inc2026 | 50 | 10 | 33 |  | да |
| conversion1.inc | 547 | 2005-03-09 | 1 | 6 | 17 |  | да |
| conversionOld.inc | 1402 | 2008-04-05 | 50 | 10 | 33 |  | да |
| createWind.inc | 33 | 2004-03-17 | 9 | 6 | 0 |  | да |
| dbtools.inc | 57 | 2004-03-17 | 4 | 0 | 6 |  | ? |
| debug.inc | 126 | 2004-10-11 | 1 | 4 | 5 |  | да |
| debugNoSend.inc | 94 | 2004-10-11 | 0 | 3 | 3 |  | да |
| debugWindow.inc | 119 | 2005-01-14 | 0 | 3 | 2 |  | да |
| delTags.inc | 335 | 2026-10-08 | 0 | 0 | 6 |  | да |
| eMail.Inc | 139 | 2005-11-10 | 11 | 1 | 1 |  | да |
| eml.inc | 597 | inc2026 | 0 | 0 | 14 |  | да |
| emlOld.inc | 763 | 2008-03-31 | 0 | 0 | 15 |  | да |
| evaluate.inc | 557 | ? | 0 | 8 | 7 |  | да |
| fbscancodes.inc | 134 | 2008-04-04 | 117 | 0 | 0 |  | да |
| fileops.inc | 197 | 2009-06-17 | 1 | 0 | 12 |  | да |
| ftiQuery.inc | 376 | ? | 10 | 0 | 4 |  | нет: FUNCTION внутри FUNCTION (ftiExtractProgPath вставлена в ftiExtractFileName, строки 110-143) |
| func_array.inc | 548 | 2022-06-19 | 0 | 0 | 25 |  | да |
| gl.inc | 1377 | ? | 760 | 421 | 19 |  | ? |
| glaux.inc | 316 | ? | 120 | 52 | 12 |  | ? |
| glext.inc | 5115 | ? | 2453 | 0 | 0 |  | ? |
| glfw.inc | 318 | ? | 130 | 44 | 0 |  | ? |
| glu.inc | 425 | ? | 177 | 58 | 10 |  | ? |
| glut.inc | 360 | ? | 165 | 114 | 0 | GL/gl.inc, GL/glu.inc | ? |
| glwgl.inc | 157 | ? | 70 | 17 | 0 |  | ? |
| htmlhelp.inc | 397 | 2010-01-24 | 60 | 2 | 0 |  | да |
| keys.inc | 120 | 2005-11-10 | 47 | 0 | 0 |  | да |
| like.inc | 130 | ? | 1 | 2 | 2 |  | да |
| menu.inc | 134 | 2005-11-10 | 0 | 12 | 11 |  | да |
| microTIMER.inc | 73 | 2008-07-09 | 0 | 2 | 2 |  | да |
| msgdlg.inc | 82 | 2004-03-17 | 14 | 2 | 1 |  | да |
| objectToolbox.inc | 107 | ? | 1 | 1 | 2 |  | да |
| ole.inc | 170 | ? | 13 | 14 | 2 |  | да |
| parse.inc | 273 | inc2026 | 0 | 0 | 8 |  | да |
| pdecl.inc | 46 | 2004-03-17 | 0 | 1 | 1 |  | да |
| printdlg.inc | 60 | ? | 18 | 1 | 0 |  | да |
| printrichedit.inc | 173 | ? | 0 | 0 | 1 |  | да |
| pulsar.inc | 213 | 2004-11-18 | 0 | 22 | 3 |  | да |
| registryVars.inc | 139 | 2004-10-13 | 6 | 0 | 5 |  | да |
| rq_math.inc | 481 | 2004-03-17 | 4 | 0 | 45 |  | да |
| setup.inc | 5 | 2004-03-17 | 0 | 1 | 1 |  | да |
| stdObjMnu.inc | 245 | 2005-07-22 | 0 | 0 | 0 |  | нет: фрагмент программы (объекты и процедуры основной программы) |
| stdObjbar.inc | 351 | 2021-03-13 | 0 | 0 | 0 |  | да |
| using.inc | 243 | 2004-03-17 | 8 | 1 | 0 |  | да |
| var.inc | 353 | 2021-04-01 | 1 | 0 | 0 |  | да |
| var2008.inc | 258 | 2013-05-24 | 15 | 0 | 0 |  | да |
| zlib.inc | 143 | 2006-10-04 | 37 | 50 | 0 |  | ? |

## 4. Файлы rapidq*.inc

| Файл | Строк | Дата | Классов | Подключает |
|---|---|---|---|---|
| RAPIDQbug.INC | 825 | 2005-01-15 | 0 | C:\BAS\RAPIDQ\inc\conversion.inc, C:\BAS\RAPIDQ\inc\FilesBug.inc, C:\BAS\RAPIDQ\inc\func_array.inc |
| RAPIDQl.INC | 804 | 2004-07-28 | 0 | C:\BAS\RAPIDQ\inc\conversion.inc |
| RapidQ_D3D.inc | 1014 | inc2026 | 3 |  |
| rapidq.inc | 881 | inc2026 | 0 | RAPIDQ2.INC, conversion.inc, Files.inc, func_array.inc, parse.inc, fbscancodes.inc |
| rapidq2.inc | 8183 | inc2026 | 17 |  |
| rapidq2007.inc | 985 | 2008-01-16 | 0 | C:\BAS\RAPIDQ\inc\conversion.inc, C:\BAS\RAPIDQ\inc\Files.inc, C:\BAS\RAPIDQ\inc\func_array.inc, C:\BAS\RAPIDQ\inc\parse.inc, C:\BAS\RAPIDQ\inc\fbscancodes.inc |
| rapidq3.inc | 881 | ? | 0 | RAPIDQ2.INC, conversion.inc, Files.inc, func_array.inc, parse.inc, fbscancodes.inc |
| rapidq_ex.inc | 969 | 2008-05-11 | 0 | C:\BAS\RAPIDQ\inc\conversion.inc, C:\BAS\RAPIDQ\inc\Files.inc, C:\BAS\RAPIDQ\inc\func_array.inc, C:\BAS\RAPIDQ\inc\parse.inc, C:\BAS\RAPIDQ\inc\fbscancodes.inc, C:\BAS\RAPIDQ\inc\eml.inc |

## 5. Константы с разными числами в разных файлах

| Имя | Значение: файлы | Брать |
|---|---|---|
| CDS_TEST | 2: rapidq2.inc<br>4: WINDOWS.INC | 2 |
| CMBLACKNESS | 0: RAPIDQbug.INC, RAPIDQl.INC, rapidq2007.inc, rapidq_ex.inc<br>66: rapidq2.inc | код Windows (rapidq2.inc) |
| CMDSTINVERT | 1: RAPIDQbug.INC, RAPIDQl.INC, rapidq2007.inc, rapidq_ex.inc<br>5570569: rapidq2.inc | код Windows (rapidq2.inc) |
| CMMERGECOPY | 2: RAPIDQbug.INC, RAPIDQl.INC, rapidq2007.inc, rapidq_ex.inc<br>12583114: rapidq2.inc | код Windows (rapidq2.inc) |
| CMMERGEPAINT | 3: RAPIDQbug.INC, RAPIDQl.INC, rapidq2007.inc, rapidq_ex.inc<br>12255782: rapidq2.inc | код Windows (rapidq2.inc) |
| CMNOTSRCCOPY | 4: RAPIDQbug.INC, RAPIDQl.INC, rapidq2007.inc, rapidq_ex.inc<br>3342344: rapidq2.inc | код Windows (rapidq2.inc) |
| CMNOTSRCERASE | 5: RAPIDQbug.INC, RAPIDQl.INC, rapidq2007.inc, rapidq_ex.inc<br>1114278: rapidq2.inc | код Windows (rapidq2.inc) |
| CMPATCOPY | 6: RAPIDQbug.INC, RAPIDQl.INC, rapidq2007.inc, rapidq_ex.inc<br>15728673: rapidq2.inc | код Windows (rapidq2.inc) |
| CMPATINVERT | 7: RAPIDQbug.INC, RAPIDQl.INC, rapidq2007.inc, rapidq_ex.inc<br>5898313: rapidq2.inc | код Windows (rapidq2.inc) |
| CMPATPAINT | 8: RAPIDQbug.INC, RAPIDQl.INC, rapidq2007.inc, rapidq_ex.inc<br>16452105: rapidq2.inc | код Windows (rapidq2.inc) |
| CMSRCAND | 9: RAPIDQbug.INC, RAPIDQl.INC, rapidq2007.inc, rapidq_ex.inc<br>8913094: rapidq2.inc | код Windows (rapidq2.inc) |
| CMSRCCOPY | 10: RAPIDQbug.INC, RAPIDQl.INC, rapidq2007.inc, rapidq_ex.inc<br>13369376: rapidq2.inc | код Windows (rapidq2.inc) |
| CMSRCERASE | 11: RAPIDQbug.INC, RAPIDQl.INC, rapidq2007.inc, rapidq_ex.inc<br>4457256: rapidq2.inc | код Windows (rapidq2.inc) |
| CMSRCINVERT | 12: RAPIDQbug.INC, RAPIDQl.INC, rapidq2007.inc, rapidq_ex.inc<br>6684742: rapidq2.inc | код Windows (rapidq2.inc) |
| CMSRCPAINT | 13: RAPIDQbug.INC, RAPIDQl.INC, rapidq2007.inc, rapidq_ex.inc<br>15597702: rapidq2.inc | код Windows (rapidq2.inc) |
| CMWHITENESS | 14: RAPIDQbug.INC, RAPIDQl.INC, rapidq2007.inc, rapidq_ex.inc<br>16711778: rapidq2.inc | код Windows (rapidq2.inc) |
| LVIF_COLUMNS | 256: commctrl32.inc<br>512: CommCtrl.inc | 512 |
| LVIF_GROUPID | 128: commctrl32.inc<br>256: CommCtrl.inc | 256 |
| VK_EXECUTE | 43: fbscancodes.inc, rapidq2.inc<br>49: keys.inc | 43 |

Константы cm* (CopyMode у QBITMAP, QCANVAS, QIMAGE): тест в RapidQ 2026-10-11
(RqLcl/tofb/tests/research/CopyModeTest.bas) - RapidQ принимает коды растровых
операций Windows, как в rapidq2.inc (cmSrcCopy = &HCC0020); номера 0..14 из
документации (qbitmap.html) рисуют чёрным. Берутся значения rapidq2.inc.
