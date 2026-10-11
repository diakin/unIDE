# Сборка rapidqAllProc.inc и rapidqComponents.inc

Собрано rapidq_ref/tools/build_inc.py из incOld по inc_merge_plan.md.

## Состав

- rapidqAllProc.inc: rapidq2.inc (без разделов компонентов), rapidq.inc, и 99 файлов: AddMenuItemBitmaps4a.inc, AdvAPI32.inc, Api.inc, ApiDate.inc, CallBack_0.Inc, CallBack_1.Inc, CallBack_2.Inc, CallBack_3.Inc, CallBack_4.Inc, CallBack_5.Inc, CallBack_6.Inc, CallBack_7.Inc, CallBack_8.Inc, CallBackAll.Inc, CallBackForwarder.Inc, CallBacks.Inc, CMD5.inc, CommCtrl.inc, commctrl32.inc, Common.inc, constants.inc, Control.inc, conversion.inc, conversion1.inc, conversionOld.inc, ConvertToTruePath.inc, Copy of NOTA.inc, createWind.inc, DBT.INC, debugWindow.inc, delTags.inc, eMail.Inc, eml.inc, emlOld.inc, evaluate.inc, FBFunctions.inc, fbscancodes.inc, fileops.inc, Files.inc, Files1.inc, Files2.inc, FilesBug.inc, FileUtils.inc, Form.inc, func_array.inc, GDI32.inc, htmlhelp.inc, Kernel32.inc, keys.inc, like.inc, Math.inc, MDI_API.INC, Memory.inc, microTIMER.inc, Minimize.inc, msgdlg.inc, NewWindow23.inc, NewWndProc.Inc, NOTA.inc, objectToolbox.inc, ODMenuXP.inc, ole.inc, parse.inc, pdecl.inc, printdlg.inc, PRINTERDLL.INC, printrichedit.inc, pulsar.inc, QFiles.inc, QFormLocale.inc, QFormSkin.inc, QFuncLib.inc, QPoint.inc, QPrintDialog.inc, QStringGridEx.inc, QXLS.INC, registryVars.inc, RichEditApi.inc, rq_math.inc, RqAsmUtils.Inc, RQDialog.inc, RQProcess.inc, SetFileTimeAttrib.inc, setup.inc, Shell32.inc, ShellRedir.Inc, SysUtils.inc, TestIncPAth.inc, TRM_RQDeclares.INC, User32.inc, using.inc, var.inc, var2008.inc, WFunctions.inc, Win32_constants.inc, WIN32API.INC, WINDOWS.INC, WindowsAPI.inc, WinMM.Inc
- rapidqComponents.inc: разделы компонентов rapidq2.inc и 95 файлов: apiRe.inc, odbc.inc, QCoolBarXPv1d.inc, QDataBase.inc, qdrive2024.inc, qEditEx.inc, QIni.inc, QIniFile.inc, QMaxSplitter.inc, QRedEx.Inc, qspintext.inc, QTextEdit.inc, RichEdPopUp.inc, VFW.inc, XP_MANIFEST.INC, COMPORTxp.inc, HiLight.inc, QAnim.inc, QAnimate.inc, QAVI.inc, QBevel.inc, QBrowseDialog.inc, QButtonXP.INC, qcalendar.inc, Qcdaudio.inc, qcgi.inc, QChart.inc, QColorButton.inc, QCursor.inc, qdataBaseSQL.inc, QDesktop.inc, QDigDisplay.inc, QDir.Inc, qdownload.inc, QDrawFocus.inc, QDrawMenu.inc, QFileListView.inc, QFlashLabel.inc, QFlatButton.inc, qfocus.inc, QFTPCLIENT.INC, qgraph.inc, QGridColor.inc, QHead.inc, QHTML.inc, QICMP.INC, QICON.inc, Qid3Tag.inc, QImageBox.inc, QImageDialog.inc, QImageListEx.inc, QInputBox.inc, QLed.inc, QLedScroll.inc, QLibrary.Inc, QLine.inc, QListBoxEx.inc, QMailLabel.inc, qmenu.inc, QMidi.inc, Qmp3.inc, qposic.inc, QPrinterInfo.inc, QProcess.inc, QProgress.inc, QProgressBar.inc, QRichEditXt.inc, QrPanel.inc, QRun.inc, QSavePlus.inc, QSHFileOperation.inc, QShutdown.inc, QSkin.inc, QSkinBtn.inc, QSocketEx.inc, QSpinEdit.inc, QSplash.inc, QStatusBarEx.inc, QtabControlEx.inc, QTextBtn.inc, QThread.inc, QToolBar.inc, QToolBarEX.inc, QTreeviewEx.inc, QVideo.inc, QVolumeInfo.inc, QVuMeter.inc, QWave.inc, QXPButton.inc, RapidFRM.inc, RapidQ_D3D.inc, RC4crypt.inc, RSocket.INC, TstRichEd.inc, XPThemes.inc
- не вошли: 96 файлов (ниже)

## Взята часть файла

- QDrawMenu.inc: строки 1-228 (дальше пример программы)
- QSavePlus.inc: строки 1-216 (дальше пример программы)
- RichEditApi.inc: строки 1-226 (дальше структуры, недопереведённые с ассемблера: "AS AS COLORREF", "CHARRANGE <>")
- using.inc: строки 1-232 (дальше пример программы)

## Не вошли

| Файл | Почему |
|---|---|
| ACE32.INC | в плане «?»: особая библиотека (своя DLL, OpenGL, базы данных), подключать отдельно |
| AllProps.inc | нет: фрагмент программы (объекты и процедуры основной программы) |
| API_RichEdid.inc | нет: черновик - внутри TYPE строки "dim Line as ARRAY of STRING" (список свойств), RapidQ такой тип не знает; взят apiRe.inc |
| C_Constants.inc | нет: часть CodeSense (cmcs21.dll), тип Bool - из $Define Bool Integer в CodeSense.inc; подключать CodeSense.inc |
| cgi.inc | в плане «?»: особая библиотека (своя DLL, OpenGL, базы данных), подключать отдельно |
| CM_Constants.inc | нет: часть CodeSense (cmcs21.dll), тип Bool - из $Define Bool Integer в CodeSense.inc; подключать CodeSense.inc |
| CM_Functions.inc | нет: часть CodeSense (cmcs21.dll), тип Bool - из $Define Bool Integer в CodeSense.inc; подключать CodeSense.inc |
| CodeSense.inc | нет: $RESOURCE на файлы, которых нет в inc; подключать отдельно |
| ComPort.inc | взята другая версия: Comport - rapidq2.inc |
| cREdit.inc | взята другая версия: QMAXEDIT - RichEdPopUp.inc |
| DAQmx.inc | в плане «?»: особая библиотека (своя DLL, OpenGL, базы данных), подключать отдельно |
| DAQmxConst.inc | в плане «?»: особая библиотека (своя DLL, OpenGL, базы данных), подключать отдельно |
| Dbase.inc | в плане «?»: особая библиотека (своя DLL, OpenGL, базы данных), подключать отдельно |
| dbtools.inc | в плане «?»: особая библиотека (своя DLL, OpenGL, базы данных), подключать отдельно |
| debug.inc | нет: подключать отдельно - при запуске создаёт окно отладки _DebugFORM |
| debugNoSend.inc | нет: подключать отдельно - при запуске создаёт окно отладки _DebugFORM и таймер; вызывает senddata из debug.inc |
| DxfONE!h.inc | в плане «?»: особая библиотека (своя DLL, OpenGL, базы данных), подключать отдельно |
| Form1.inc | нет: фрагмент программы (форма Form1 с кнопкой) |
| ftiQuery.inc | нет: FUNCTION внутри FUNCTION (ftiExtractProgPath вставлена в ftiExtractFileName, строки 110-143) |
| Functions.inc | нет: часть CodeSense (cmcs21.dll), тип Bool - из $Define Bool Integer в CodeSense.inc; подключать CodeSense.inc |
| gl.inc | в плане «?»: особая библиотека (своя DLL, OpenGL, базы данных), подключать отдельно |
| glaux.inc | в плане «?»: особая библиотека (своя DLL, OpenGL, базы данных), подключать отдельно |
| glext.inc | в плане «?»: особая библиотека (своя DLL, OpenGL, базы данных), подключать отдельно |
| glfw.inc | в плане «?»: особая библиотека (своя DLL, OpenGL, базы данных), подключать отдельно |
| glu.inc | в плане «?»: особая библиотека (своя DLL, OpenGL, базы данных), подключать отдельно |
| glut.inc | в плане «?»: особая библиотека (своя DLL, OpenGL, базы данных), подключать отдельно |
| glwgl.inc | в плане «?»: особая библиотека (своя DLL, OpenGL, базы данных), подключать отдельно |
| LabelGrid.inc | нет: фрагмент программы (при запуске строит сетку надписей на панели) |
| LangIniHeader.inc | нет: фрагмент программы (StartPath$, DIM LangIni AS QINI - класс из компонентов) |
| menu.inc | нет: фрагмент программы (меню формы MainForm, "Menu file for test.rqw") |
| MYSQL.INC | в плане «?»: особая библиотека (своя DLL, OpenGL, базы данных), подключать отдельно |
| NI6210.inc | в плане «?»: особая библиотека (своя DLL, OpenGL, базы данных), подключать отдельно |
| QAbout.inc | взята другая версия: QAbout - rapidq2.inc |
| QBitmapEx.inc | взята другая версия: QBitmapEx - rapidq2.inc |
| QCanvasEx.inc | взята другая версия: QCanvasEx - rapidq2.inc |
| qciccio.inc | нет: пробный класс (поле AS ciccino - такого типа нет) |
| QColorDialog10.inc | взята другая версия: QColorDialog - rapidq2.inc |
| QColorDialog11.inc | взята другая версия: QCOLORDIALOG - rapidq2.inc |
| QCoolBarXP90.inc | взята другая версия: QCoolBarXP - QCoolBarXPv1d.inc |
| QDebug.inc | взята другая версия: QDebug - rapidq2.inc |
| QDirListView1.inc | нет: $RESOURCE на файлы, которых нет в inc; подключать отдельно |
| QDOCKFORM.inc | взята другая версия: QDFPANEL - rapidq2.inc, QDOCKFORM - rapidq2.inc |
| QDrive.inc | взята другая версия: QDrive - qdrive2024.inc |
| QDriveCombobox.inc | взята другая версия: QDriveComboBox - rapidq2.inc |
| QDXF.inc | в плане «?»: особая библиотека (своя DLL, OpenGL, базы данных), подключать отдельно |
| QFileDialog.inc | взята другая версия: QFILEDIALOG - rapidq2.inc |
| QFileDialogDoc.inc | взята другая версия: QFILEDIALOG - rapidq2.inc |
| QFormEx.inc | взята другая версия: QFormEx - rapidq2.inc |
| QFormMDI.inc | взята другая версия: QFormMDI - rapidq2.inc |
| QGL.inc | подключает не вошедший gl.inc |
| QImageEx.inc | взята другая версия: QImageEx - rapidq2.inc |
| QListviewEx.inc | взята другая версия: Qlistviewex - rapidq2.inc |
| QMarker.inc | нет: $RESOURCE на файлы, которых нет в inc; подключать отдельно |
| qmaxedit.inc | взята другая версия: QMAXEDIT - RichEdPopUp.inc |
| qodbc.inc | взята другая версия: qODBC - odbc.inc |
| QPageSetup.inc | взята другая версия: QPageSetup - rapidq2.inc |
| QREDEXTest.INC | взята другая версия: QRedEx - QRedEx.Inc |
| QREDEXTest2.INC | взята другая версия: QRedEx - QRedEx.Inc |
| qREdit.inc | взята другая версия: QMAXEDIT - RichEdPopUp.inc |
| qspintextev.inc | взята другая версия: Qspintext - qspintext.inc |
| qspintextOld.inc | взята другая версия: Qspintext - qspintext.inc |
| QSplitter.inc | взята другая версия: QMAXSPLITTER - QMaxSplitter.inc |
| QTButton.inc | взята другая версия: QTButton - QTButton95.inc |
| QTButton72.inc | взята другая версия: QTButton - QTButton95.inc |
| QTButton85b.inc | взята другая версия: QTButton - QTButton95.inc |
| QTButton94.inc | взята другая версия: QTButton - QTButton95.inc |
| QTButton94b.inc | взята другая версия: QTButton - QTButton95.inc |
| QTButton95.inc | нет: нужен $RESOURCE btn_BMP в программе (QTBtnBMP.BMPHandle = btn_BMP при подключении); подключать отдельно |
| QTButton_AddOns.inc | нет: дополнение к QTButton, нужен ресурс btn_BMP в программе; подключать отдельно |
| QTextEditTest.inc | взята другая версия: QTEXTEDIT - QTextEdit.inc |
| QWinIni.inc | взята другая версия: QINI - QIni.inc |
| QxEdit.inc | взята другая версия: QxEDIT - qEditEx.inc |
| QXpTheme.INC | нет: подключать отдельно - при запуске пишет .manifest и перезапускает программу |
| RapidFRM_Mods.inc | нет: фрагмент программы (объекты и процедуры основной программы) |
| rapidq2007.inc | старая версия rapidq.inc |
| rapidq3.inc | копия rapidq.inc |
| rapidq_ex.inc | старая версия rapidq.inc |
| RAPIDQbug.INC | старая версия rapidq.inc |
| RAPIDQl.INC | старая версия rapidq.inc |
| Resources2.inc | нет: $RESOURCE на файлы, которых нет в inc; подключать отдельно |
| RichEdPopUp1.inc | взята другая версия: QMAXEDIT - RichEdPopUp.inc |
| RichEdPopUpold.inc | взята другая версия: QMAXEDIT - RichEdPopUp.inc |
| RQdate.inc | нет: обёртка своей fbDate.dll; вызывает ReadVarFromMemory из rapidq2007.inc (в самом файле функция названа ReadVarFromMemory2, а присваивается и вызывается ReadVarFromMemory) |
| RQDxf.inc | в плане «?»: особая библиотека (своя DLL, OpenGL, базы данных), подключать отдельно |
| Splash.inc | нет: фрагмент программы (заставка, CREATE формы и показ) |
| SplashForm.inc | нет: фрагмент программы (заставка, CREATE формы и показ) |
| StayOnTop.inc | нет: подключать отдельно - включает $OPTION VBDLL ON и WEAKTYPE ON для всего, что ниже, и создаёт таймер |
| stdObjbar.inc | нет: фрагмент программы (панель кнопок конструктора форм, картинки Form_BMP и др. - ресурсы программы) |
| stdObjMnu.inc | нет: фрагмент программы (объекты и процедуры основной программы) |
| ultraRichEd.inc | взята другая версия: QMAXEDIT - RichEdPopUp.inc |
| vfw2.inc | взята другая версия: QWebCam - VFW.inc |
| Wad3.inc | в плане «?»: особая библиотека (своя DLL, OpenGL, базы данных), подключать отдельно |
| WebCam.inc | нет: при подключении сразу вызывает webcam.dll; подключать отдельно |
| xp_manifest1.inc | взята другая версия: XpGroupBox - XP_MANIFEST.INC |
| XPSkinMetallic_2.11_Res.inc | нет: нужны ресурсы Resources2.inc и CONST myMainFormName в программе; подключать отдельно |
| zlib.inc | в плане «?»: особая библиотека (своя DLL, OpenGL, базы данных), подключать отдельно |

## CONST, TYPE и DECLARE подняты выше (нужны раньше своего места)

- NMHDR из WIN32API.INC(15032) - для CommCtrl.inc
- CBEN_FIRST из commctrl32.inc(234) - для commctrl32.inc
- SC_SIZE из WIN32API.INC(7327) - для commctrl32.inc
- CB_DELETESTRING из Win32_constants.inc(261) - для commctrl32.inc
- EXITPROCESS из Kernel32.inc(35) - для Copy of NOTA.inc
- GETCOMPUTERNAME из Kernel32.inc(52) - для Copy of NOTA.inc
- GETDISKFREESPACE из Kernel32.inc(94) - для Copy of NOTA.inc
- GETTEMPPATH из Kernel32.inc(148) - для Copy of NOTA.inc
- GETWINDOWSDIRECTORY из Kernel32.inc(213) - для Copy of NOTA.inc
- FILETIME из WIN32API.INC(478) - для WIN32API.INC
- EXCEPTION_RECORD из WIN32API.INC(1557) - для WIN32API.INC
- JOYINFO из WIN32API.INC(11663) - для WIN32API.INC
- JOYINFOEX из WIN32API.INC(11202) - для WIN32API.INC
- MIDIHDR из WIN32API.INC(11528) - для WIN32API.INC

## Исправлено в сборке

Внутренние процедуры с короткими именами (совпадали с переменными других файлов: QXLS.INC DIM F AS QFileStream) и опечатки:

- commctrl32.inc: 4 строк с числом 880U (суффикс C) - без U
- commctrl32.inc: 5 строк CONST без = - с =
- keys.inc: 46 строк "define ИМЯ значение" без $ - $define
- keys.inc: $OPTION INKEY$ TRAPALL закомментирован (действует на всю программу)
- NI6210.inc: 1 строк CONST без = - с =
- RichEditApi.inc: 3 строк-комментариев "; ..." - с '
- CMD5.inc: F, G, H, FF, GG, HH, II -> MD5_...
- SetFileTimeAttrib.inc: sysdir -> SFTA_...
- using.inc: log10, format -> USING_...

## DECLARE ... LIB с другими параметрами - под своим именем

То же имя объявлено выше в другом файле с другими параметрами; в этом файле функция и её вызовы переименованы, ALIAS прежний.

- Kernel32.inc: DECLARE GETVERSIONEX - GETVERSIONEX_Kernel32 (параметры не те, что у rapidq2.inc)
- MDI_API.INC: DECLARE CREATEFILE - CREATEFILE_MDI_API (параметры не те, что у rapidq2.inc)
- MDI_API.INC: DECLARE READFILE - READFILE_MDI_API (параметры не те, что у rapidq2.inc)
- QFormSkin.inc: DECLARE CLIENTTOSCREEN - CLIENTTOSCREEN_QFormSkin (параметры не те, что у rapidq2.inc)
- QFormSkin.inc: DECLARE GETCLIENTRECT - GETCLIENTRECT_QFormSkin (параметры не те, что у rapidq2.inc)
- QFormSkin.inc: DECLARE GETWINDOWRECT - GETWINDOWRECT_QFormSkin (параметры не те, что у rapidq2.inc)
- WIN32API.INC: DECLARE CLIENTTOSCREEN - CLIENTTOSCREEN_WIN32API (параметры не те, что у rapidq2.inc)
- WIN32API.INC: DECLARE CREATEFILE - CREATEFILE_WIN32API (параметры не те, что у rapidq2.inc)
- WIN32API.INC: DECLARE DRAWCAPTION - DRAWCAPTION_WIN32API (параметры не те, что у rapidq2.inc)
- WIN32API.INC: DECLARE DRAWEDGE - DRAWEDGE_WIN32API (параметры не те, что у rapidq2.inc)
- WIN32API.INC: DECLARE DRAWFRAMECONTROL - DRAWFRAMECONTROL_WIN32API (параметры не те, что у rapidq2.inc)
- WIN32API.INC: DECLARE GETCLIENTRECT - GETCLIENTRECT_WIN32API (параметры не те, что у rapidq2.inc)
- WIN32API.INC: DECLARE GETMENUITEMINFO - GETMENUITEMINFO_WIN32API (параметры не те, что у rapidq2.inc)
- WIN32API.INC: DECLARE GETOBJECT - GETOBJECT_WIN32API (параметры не те, что у rapidq2.inc)
- WIN32API.INC: DECLARE GETWINDOWRECT - GETWINDOWRECT_WIN32API (параметры не те, что у rapidq2.inc)
- WIN32API.INC: DECLARE INSERTMENUITEM - INSERTMENUITEM_WIN32API (параметры не те, что у rapidq2.inc)
- WIN32API.INC: DECLARE LOOKUPPRIVILEGEVALUE - LOOKUPPRIVILEGEVALUE_WIN32API (параметры не те, что у rapidq2.inc)
- WIN32API.INC: DECLARE MOVETOEX - MOVETOEX_WIN32API (параметры не те, что у rapidq2.inc)
- WIN32API.INC: DECLARE PAGESETUPDLG - PAGESETUPDLG_WIN32API (параметры не те, что у rapidq2.inc)
- WIN32API.INC: DECLARE QUERYPERFORMANCECOUNTER - QUERYPERFORMANCECOUNTER_WIN32API (параметры не те, что у microTIMER.inc)
- WIN32API.INC: DECLARE QUERYPERFORMANCEFREQUENCY - QUERYPERFORMANCEFREQUENCY_WIN32API (параметры не те, что у microTIMER.inc)
- WIN32API.INC: DECLARE REDRAWWINDOW - REDRAWWINDOW_WIN32API (параметры не те, что у QFormSkin.inc)
- WIN32API.INC: DECLARE RESETDC - RESETDC_WIN32API (параметры не те, что у PRINTERDLL.INC)
- WIN32API.INC: DECLARE SETMENUITEMINFO - SETMENUITEMINFO_WIN32API (параметры не те, что у rapidq2.inc)
- WIN32API.INC: DECLARE SETWINDOWRGN - SETWINDOWRGN_WIN32API (параметры не те, что у QFormSkin.inc)
- WIN32API.INC: DECLARE SHELL_NOTIFYICON - SHELL_NOTIFYICON_WIN32API (параметры не те, что у rapidq2.inc)
- WIN32API.INC: DECLARE SHGETFILEINFO - SHGETFILEINFO_WIN32API (параметры не те, что у ConvertToTruePath.inc)
- WINDOWS.INC: DECLARE ALPHABLEND - ALPHABLEND_WINDOWS (параметры не те, что у rapidq2.inc)
- WINDOWS.INC: DECLARE CLIENTTOSCREEN - CLIENTTOSCREEN_WINDOWS (параметры не те, что у rapidq2.inc)
- WINDOWS.INC: DECLARE CLIPCURSOR - CLIPCURSOR_WINDOWS (параметры не те, что у WIN32API.INC)
- WINDOWS.INC: DECLARE CREATEBITMAPINDIRECT - CREATEBITMAPINDIRECT_WINDOWS (параметры не те, что у WIN32API.INC)
- WINDOWS.INC: DECLARE CREATEFILE - CREATEFILE_WINDOWS (параметры не те, что у rapidq2.inc)
- WINDOWS.INC: DECLARE DRAWCAPTION - DRAWCAPTION_WINDOWS (параметры не те, что у rapidq2.inc)
- WINDOWS.INC: DECLARE DRAWEDGE - DRAWEDGE_WINDOWS (параметры не те, что у rapidq2.inc)
- WINDOWS.INC: DECLARE DRAWFRAMECONTROL - DRAWFRAMECONTROL_WINDOWS (параметры не те, что у rapidq2.inc)
- WINDOWS.INC: DECLARE GETCLIENTRECT - GETCLIENTRECT_WINDOWS (параметры не те, что у rapidq2.inc)
- WINDOWS.INC: DECLARE GETDISKFREESPACEEX - GETDISKFREESPACEEX_WINDOWS (параметры не те, что у rapidq2.inc)
- WINDOWS.INC: DECLARE GETMENUITEMINFO - GETMENUITEMINFO_WINDOWS (параметры не те, что у rapidq2.inc)
- WINDOWS.INC: DECLARE GETWINDOWRECT - GETWINDOWRECT_WINDOWS (параметры не те, что у rapidq2.inc)
- WINDOWS.INC: DECLARE INSERTMENUITEM - INSERTMENUITEM_WINDOWS (параметры не те, что у rapidq2.inc)
- WINDOWS.INC: DECLARE LOOKUPPRIVILEGEVALUE - LOOKUPPRIVILEGEVALUE_WINDOWS (параметры не те, что у rapidq2.inc)
- WINDOWS.INC: DECLARE MOVETOEX - MOVETOEX_WINDOWS (параметры не те, что у rapidq2.inc)
- WINDOWS.INC: DECLARE PAGESETUPDLG - PAGESETUPDLG_WINDOWS (параметры не те, что у rapidq2.inc)
- WINDOWS.INC: DECLARE QUERYPERFORMANCECOUNTER - QUERYPERFORMANCECOUNTER_WINDOWS (параметры не те, что у microTIMER.inc)
- WINDOWS.INC: DECLARE QUERYPERFORMANCEFREQUENCY - QUERYPERFORMANCEFREQUENCY_WINDOWS (параметры не те, что у microTIMER.inc)
- WINDOWS.INC: DECLARE REDRAWWINDOW - REDRAWWINDOW_WINDOWS (параметры не те, что у QFormSkin.inc)
- WINDOWS.INC: DECLARE RESETDC - RESETDC_WINDOWS (параметры не те, что у PRINTERDLL.INC)
- WINDOWS.INC: DECLARE SETMENUITEMINFO - SETMENUITEMINFO_WINDOWS (параметры не те, что у rapidq2.inc)
- WINDOWS.INC: DECLARE SETSERVICEBITS - SETSERVICEBITS_WINDOWS (параметры не те, что у WIN32API.INC)
- WINDOWS.INC: DECLARE SETWINDOWRGN - SETWINDOWRGN_WINDOWS (параметры не те, что у QFormSkin.inc)
- WINDOWS.INC: DECLARE SHELL_NOTIFYICON - SHELL_NOTIFYICON_WINDOWS (параметры не те, что у rapidq2.inc)
- WINDOWS.INC: DECLARE SHGETFILEINFO - SHGETFILEINFO_WINDOWS (параметры не те, что у ConvertToTruePath.inc)
- QMaxSplitter.inc: DECLARE CLIENTTOSCREEN - CLIENTTOSCREEN_QMaxSplitter (параметры не те, что у rapidq2.inc)
- QMaxSplitter.inc: DECLARE OFFSETRECT - OFFSETRECT_QMaxSplitter (параметры не те, что у WIN32API.INC)
- QICON.inc: DECLARE DRAWICON - DRAWICON_QICON (параметры не те, что у QFormSkin.inc)
- QProcess.inc: DECLARE CREATETHREAD - CREATETHREAD_QProcess (параметры не те, что у WIN32API.INC)
- QProgress.inc: DECLARE CREATETHREAD - CREATETHREAD_QProgress (параметры не те, что у WIN32API.INC)
- QThread.inc: DECLARE CREATETHREAD - CREATETHREAD_QThread (параметры не те, что у WIN32API.INC)
- RapidFRM.inc: DECLARE INVALIDATERECT - INVALIDATERECT_RapidFRM (параметры не те, что у QFormSkin.inc)
- XPThemes.inc: DECLARE GETWINDOWRECT - GETWINDOWRECT_XPThemes (параметры не те, что у rapidq2.inc)

## $DEFINE имени типом - только для своего файла

Имя ниже по сборке - имя переменной или параметра; в конце файла $UNDEF.

| Файл | Имя | Где ниже |
|---|---|---|
| apiRe.inc | HWND | odbc.inc(30): DECLARE FUNCTION SQLDriverConnect LIB "" ALIAS ""(ByVal ldbc |
| createWind.inc | HWND | Form.inc(46): (ByVal hwnd As Long, lpwndpl As WINDOWPLACEMENT) As Long |
| keys.inc | CHAR | QFuncLib.inc(72): function RemoveChar$(s as string,char as string) as string |

## Одно имя у процедуры и у DECLARE ... LIB (оставлено первое)

| Имя | Оставлено | Закомментировано |
|---|---|---|
| UPDATECOLORS | ODMenuXP.inc(1518) | WIN32API.INC(4562) |
| LOADSTRING | Files.inc(473) | WIN32API.INC(7456) |
| UPDATECOLORS | ODMenuXP.inc(1518) | WINDOWS.INC(4688) |
| LOADSTRING | Files.inc(473) | WINDOWS.INC(7719) |

## Убрано как повтор

- CONST: 7421
- DECLARE: 2043
- $DEFINE: 2026
- SUB/FUNCTION: 237
- TYPE: 494
- DIM/DEFxxx/CREATE: 132

## Повторы с другим текстом (оставлено первое)

| Вид | Имя | Оставлено | Убрано |
|---|---|---|---|
| $DEFINE | BOOLEAN | rapidq2.inc(2241): `LONG` | rapidq.inc(14): `BYTE` |
| DECLARE | SETWINDOWLONG | rapidq2.inc(1039): `DECLARE FUNCTION SETWINDOWLONG LIB "USER32" ALIAS "SETWINDOWLONGA" (HWND AS LONG` | Api.inc(94): `DECLARE FUNCTION SETWINDOWLONG LIB "USER32.DLL" ALIAS "SETWINDOWLONGA" _ (HWND A` |
| DECLARE | CALLWINDOWPROC | rapidq2.inc(1019): `DECLARE FUNCTION CALLWINDOWPROC LIB "USER32.DLL" ALIAS "CALLWINDOWPROCA" (LPPREV` | Api.inc(97): `DECLARE FUNCTION CALLWINDOWPROC LIB "USER32.DLL" ALIAS "CALLWINDOWPROCA" _ (LPPR` |
| DECLARE | GETMENUITEMINFO | rapidq2.inc(1604): `DECLARE FUNCTION GETMENUITEMINFO LIB "USER32.DLL" ALIAS "GETMENUITEMINFOA" (BYVA` | Api.inc(105): `DECLARE FUNCTION GETMENUITEMINFO LIB "USER32.DLL" ALIAS "GETMENUITEMINFOA" _ (BY` |
| DECLARE | SETMENUITEMINFO | rapidq2.inc(1605): `DECLARE FUNCTION SETMENUITEMINFO LIB "USER32.DLL" ALIAS "SETMENUITEMINFOA" (BYVA` | Api.inc(109): `DECLARE FUNCTION SETMENUITEMINFO LIB "USER32.DLL" ALIAS "SETMENUITEMINFOA" _ (BY` |
| DECLARE | INSERTMENUITEM | rapidq2.inc(1606): `DECLARE FUNCTION INSERTMENUITEM LIB "USER32.DLL" ALIAS "INSERTMENUITEMA" (BYVAL ` | Api.inc(113): `DECLARE FUNCTION INSERTMENUITEM LIB "USER32.DLL" ALIAS "INSERTMENUITEMA" _ (BYVA` |
| $DEFINE | TOOLTIPS_CLASS | CommCtrl.inc(1157): `CONST TOOLTIPS_CLASS = "TOOLTIPS_CLASS32"` | commctrl32.inc(80): `TOOLTIPS_CLASSA` |
| $DEFINE | WC_TABCONTROL | CommCtrl.inc(334): `CONST WC_TABCONTROL = "SYSTABCONTROL32"` | commctrl32.inc(90): `WC_TABCONTROLA` |
| $DEFINE | LVIF_GROUPID | CommCtrl.inc(500): `CONST LVIF_GROUPID = &H0100` | commctrl32.inc(789): `128` |
| $DEFINE | LVIF_COLUMNS | CommCtrl.inc(501): `CONST LVIF_COLUMNS = &H0200` | commctrl32.inc(790): `256` |
| $DEFINE | TVI_ROOT | CommCtrl.inc(121): `CONST TVI_ROOT = &HFFFF0000???` | commctrl32.inc(970): `(&HFFFF0000)` |
| $DEFINE | TVI_FIRST | CommCtrl.inc(122): `CONST TVI_FIRST = &HFFFF0001???` | commctrl32.inc(971): `(&HFFFF0001)` |
| $DEFINE | TVI_LAST | CommCtrl.inc(123): `CONST TVI_LAST = &HFFFF0002???` | commctrl32.inc(972): `(&HFFFF0002)` |
| $DEFINE | TVI_SORT | CommCtrl.inc(124): `CONST TVI_SORT = &HFFFF0003???` | commctrl32.inc(973): `(&HFFFF0003)` |
| $DEFINE | TVHT_ONITEM | CommCtrl.inc(203): `CONST TVHT_ONITEM = TVHT_ONITEMICON OR TVHT_ONITEMLABEL _ OR TVHT_ONITEMSTATEICO` | commctrl32.inc(1057): `(TVHT_ONITEMICON OR TVHT_ONITEMLABEL OR TVHT_ONITEMSTATEICON)` |
| $DEFINE | TCN_KEYDOWN | CommCtrl.inc(435): `CONST TCN_KEYDOWN = TCN_FIRST - 0` | commctrl32.inc(1128): `TCN_FIRST` |
| $DEFINE | CCM_SETBKCOLOR | CommCtrl.inc(15): `CONST CCM_SETBKCOLOR = (CCM_FIRST + 1)` | commctrl32.inc(1150): `8193` |
| $DEFINE | CCM_SETCOLORSCHEME | CommCtrl.inc(16): `CONST CCM_SETCOLORSCHEME = (CCM_FIRST + 2)` | commctrl32.inc(1151): `8194` |
| $DEFINE | CCM_GETCOLORSCHEME | CommCtrl.inc(10): `CONST CCM_GETCOLORSCHEME = (CCM_FIRST + 3)` | commctrl32.inc(1152): `8195` |
| $DEFINE | CCM_GETDROPTARGET | CommCtrl.inc(11): `CONST CCM_GETDROPTARGET = (CCM_FIRST + 4)` | commctrl32.inc(1153): `8196` |
| $DEFINE | CCM_SETUNICODEFORMAT | CommCtrl.inc(18): `CONST CCM_SETUNICODEFORMAT = (CCM_FIRST + 5)` | commctrl32.inc(1154): `8197` |
| $DEFINE | CCM_GETUNICODEFORMAT | CommCtrl.inc(12): `CONST CCM_GETUNICODEFORMAT = (CCM_FIRST + 6)` | commctrl32.inc(1155): `8198` |
| $DEFINE | CCM_SETVERSION | CommCtrl.inc(19): `CONST CCM_SETVERSION = (CCM_FIRST + &H7)` | commctrl32.inc(1156): `&H2007` |
| $DEFINE | CCM_GETVERSION | CommCtrl.inc(13): `CONST CCM_GETVERSION = (CCM_FIRST + &H8)` | commctrl32.inc(1157): `&H2008` |
| $DEFINE | CCM_SETNOTIFYWINDOW | CommCtrl.inc(17): `CONST CCM_SETNOTIFYWINDOW = (CCM_FIRST + &H9)` | commctrl32.inc(1158): `&H2009` |
| $DEFINE | CCM_SETWINDOWTHEME | CommCtrl.inc(20): `CONST CCM_SETWINDOWTHEME = (CCM_FIRST + &HB)` | commctrl32.inc(1159): `&H200B` |
| $DEFINE | SB_SETBKCOLOR | CommCtrl.inc(1485): `CONST SB_SETBKCOLOR = CCM_SETBKCOLOR` | commctrl32.inc(1241): `&H2001` |
| $DEFINE | SB_SETICON | CommCtrl.inc(1486): `CONST SB_SETICON = (WM_USER+15)` | commctrl32.inc(1302): `1039` |
| $DEFINE | SB_SETUNICODEFORMAT | CommCtrl.inc(1493): `CONST SB_SETUNICODEFORMAT = CCM_SETUNICODEFORMAT` | commctrl32.inc(1306): `&H2005` |
| TYPE | TVITEM | CommCtrl.inc(92): `TYPE TVITEM MASK AS LONG HITEM AS LONG STATE AS LONG STATEMASK AS LONG PSZTEXT A` | commctrl32.inc(1459): `TYPE TVITEM MASK AS DWORD ITEM AS DWORD STATE AS DWORD STATEMASK AS DWORD TEXT A` |
| TYPE | TVITEMEX | CommCtrl.inc(107): `TYPE TVITEMEX MASK AS LONG HITEM AS LONG STATE AS LONG STATEMASK AS LONG PSZTEXT` | commctrl32.inc(1472): `TYPE TVITEMEX MASK AS DWORD ITEM AS DWORD STATE AS DWORD STATEMASK AS DWORD TEXT` |
| DECLARE | INITCOMMONCONTROLS | CommCtrl.inc(3): `DECLARE SUB INITCOMMONCONTROLS LIB "COMCTL32.DLL" ALIAS "INITCOMMONCONTROLS"()` | commctrl32.inc(1553): `DECLARE SUB INITCOMMONCONTROLS LIB "COMCTL32" ALIAS "INITCOMMONCONTROLS" ()` |
| DECLARE | SETFOCUS | rapidq2.inc(1010): `DECLARE FUNCTION SETFOCUS LIB "USER32" ALIAS "SETFOCUS" (HWND AS LONG) AS LONG` | Common.inc(13): `DECLARE FUNCTION SETFOCUS LIB "USER32" ALIAS "SETFOCUS"(HWND AS LONG) AS LONG` |
| DECLARE | SETWINDOWLONG | rapidq2.inc(1039): `DECLARE FUNCTION SETWINDOWLONG LIB "USER32" ALIAS "SETWINDOWLONGA" (HWND AS LONG` | Common.inc(16): `DECLARE FUNCTION SETWINDOWLONG LIB "USER32" ALIAS "SETWINDOWLONGA"_ (HWND AS LON` |
| SUB/FUNCTION | ADDCHRBEFORE | conversion.inc(255): `FUNCTION ADDCHRBEFORE(NUMSTR AS STRING , DLINA AS INTEGER, CHR1 AS STRING) AS ST` | conversion1.inc(166): `FUNCTION ADDCHRBEFORE(NUMSTR AS STRING , DLINA AS INTEGER, CHR AS STRING) AS STR` |
| SUB/FUNCTION | BYTEREORDER | conversion.inc(303): `FUNCTION BYTEREORDER (BYTESTR$,REORDER$ ) AS STRING ~TMP$="" LENB=LEN(BYTESTR$) ` | conversion1.inc(198): `FUNCTION BYTEREORDER (BYTESTR$,REORDER$ ) AS STRING ~TMP$="" LENB=LEN(BYTESTR$) ` |
| SUB/FUNCTION | CBYTENUM | conversion.inc(337): `FUNCTION CBYTENUM (BYTESTR$,NUM_TYPE AS SHORT ) AS VARIANT DIM M AS QMEMORYSTREA` | conversion1.inc(232): `FUNCTION CBYTENUM (BYTESTR$,NUM_TYPE AS SHORT ) AS VARIANT DIM M AS QMEMORYSTREA` |
| SUB/FUNCTION | CNUMBYTE | conversion.inc(370): `FUNCTION CNUMBYTE (NUM, NUM_TYPE AS SHORT) AS STRING DIM M AS QMEMORYSTREAM SELE` | conversion1.inc(265): `FUNCTION CNUMBYTE (NUM, NUM_TYPE AS SHORT) AS STRING DIM M AS QMEMORYSTREAM SELE` |
| SUB/FUNCTION | TIMESTRING | conversion.inc(572): `FUNCTION TIMESTRING (TIMSEC AS INTEGER) AS STRING HR%=TIMSEC/3600 SECMIN=TIMSEC-` | conversion1.inc(451): `FUNCTION TIMESTRING (TIMSEC AS INTEGER) AS STRING HR%=TIMSEC/3600 SECMIN=TIMSEC-` |
| SUB/FUNCTION | OB2GRAD | conversion.inc(636): `SUB OB2GRAD (OBOR AS SINGLE, SECFULL AS INTEGER, SECMNT AS INTEGER, GRAD AS INTE` | conversion1.inc(512): `SUB OB2GRAD (OBOR AS SINGLE, SECFULL AS INTEGER, SECMNT AS INTEGER, GRAD AS INTE` |
| DECLARE | MULTIBYTETOWIDECHAR | conversion.inc(75): `DECLARE FUNCTION MULTIBYTETOWIDECHAR LIB "KERNEL32" ALIAS "MULTIBYTETOWIDECHAR" ` | conversionOld.inc(68): `DECLARE FUNCTION MULTIBYTETOWIDECHAR LIB "KERNEL32" ALIAS "MULTIBYTETOWIDECHAR" ` |
| DECLARE | WIDECHARTOMULTIBYTE | conversion.inc(81): `DECLARE FUNCTION WIDECHARTOMULTIBYTE LIB "KERNEL32" ALIAS "WIDECHARTOMULTIBYTE" ` | conversionOld.inc(74): `DECLARE FUNCTION WIDECHARTOMULTIBYTE LIB "KERNEL32" ALIAS "WIDECHARTOMULTIBYTE" ` |
| DECLARE | MULTIBYTETOWIDECHAR1 | conversion.inc(87): `DECLARE FUNCTION MULTIBYTETOWIDECHAR1 LIB "KERNEL32" ALIAS "MULTIBYTETOWIDECHAR"` | conversionOld.inc(80): `DECLARE FUNCTION MULTIBYTETOWIDECHAR1 LIB "KERNEL32" ALIAS "MULTIBYTETOWIDECHAR"` |
| DECLARE | WIDECHARTOMULTIBYTE1 | conversion.inc(93): `DECLARE FUNCTION WIDECHARTOMULTIBYTE1 LIB "KERNEL32" ALIAS "WIDECHARTOMULTIBYTE"` | conversionOld.inc(86): `DECLARE FUNCTION WIDECHARTOMULTIBYTE1 LIB "KERNEL32" ALIAS "WIDECHARTOMULTIBYTE"` |
| SUB/FUNCTION | ADDCHRBEFORE | conversion.inc(255): `FUNCTION ADDCHRBEFORE(NUMSTR AS STRING , DLINA AS INTEGER, CHR1 AS STRING) AS ST` | conversionOld.inc(248): `FUNCTION ADDCHRBEFORE(NUMSTR AS STRING , DLINA AS INTEGER, CHR AS STRING) AS STR` |
| SUB/FUNCTION | BYTEREORDER | conversion.inc(303): `FUNCTION BYTEREORDER (BYTESTR$,REORDER$ ) AS STRING ~TMP$="" LENB=LEN(BYTESTR$) ` | conversionOld.inc(280): `FUNCTION BYTEREORDER (BYTESTR$,REORDER$ ) AS STRING ~TMP$="" LENB=LEN(BYTESTR$) ` |
| SUB/FUNCTION | CBYTENUM | conversion.inc(337): `FUNCTION CBYTENUM (BYTESTR$,NUM_TYPE AS SHORT ) AS VARIANT DIM M AS QMEMORYSTREA` | conversionOld.inc(314): `FUNCTION CBYTENUM (BYTESTR$,NUM_TYPE AS SHORT ) AS VARIANT DIM M AS QMEMORYSTREA` |
| SUB/FUNCTION | CNUMBYTE | conversion.inc(370): `FUNCTION CNUMBYTE (NUM, NUM_TYPE AS SHORT) AS STRING DIM M AS QMEMORYSTREAM SELE` | conversionOld.inc(347): `FUNCTION CNUMBYTE (NUM, NUM_TYPE AS SHORT) AS STRING DIM M AS QMEMORYSTREAM SELE` |
| SUB/FUNCTION | RQBASE64ENCODE | eml.inc(250): `FUNCTION RQBASE64ENCODE(S AS STRING) AS STRING DIM LENSTR AS LONG, ENDPOS AS LON` | conversionOld.inc(823): `FUNCTION RQBASE64ENCODE(S AS STRING) AS STRING DIM LENSTR AS LONG, ENDPOS AS LON` |
| SUB/FUNCTION | RQBASE64DECODE | eml.inc(288): `FUNCTION RQBASE64DECODE (STXT AS STRING) AS STRING DIM LENSTR AS LONG, ENDPOS AS` | conversionOld.inc(861): `FUNCTION RQBASE64DECODE (S AS STRING) AS STRING DIM LENSTR AS LONG, ENDPOS AS LO` |
| SUB/FUNCTION | DELTAGS | conversion.inc(788): `FUNCTION DELTAGS (HTMLTEXT AS STRING) AS STRING STRING1$=HTMLTEXT STRING1$=REPLA` | conversionOld.inc(904): `FUNCTION DELTAGS (HTMLTEXT AS STRING) AS STRING STRING1$=HTMLTEXT STRING1$=REPLA` |
| SUB/FUNCTION | GETMSGHEADER | eml.inc(123): `FUNCTION GETMSGHEADER( SOURCE AS STRING) AS STRING DIM MSGHEADER AS QSTRINGLIST ` | conversionOld.inc(1027): `FUNCTION GETMSGHEADER( SOURCE AS STRING) AS STRING DIM MSGHEADER AS QSTRINGLIST ` |
| SUB/FUNCTION | GETMSGBODY | eml.inc(150): `FUNCTION GETMSGBODY( SOURCE AS STRING) AS STRING DIM MSGBODY AS QSTRINGLIST DIM ` | conversionOld.inc(1045): `FUNCTION GETMSGBODY( SOURCE AS STRING) AS STRING DIM MSGBODY AS QSTRINGLIST DIM ` |
| SUB/FUNCTION | GETHEADERFIELD | eml.inc(86): `FUNCTION GETHEADERFIELD( HEADER AS STRING, FIELD AS STRING) AS STRING HEADER=REP` | conversionOld.inc(1143): `FUNCTION GETHEADERFIELD( HEADER AS STRING, FIELD AS STRING) AS STRING FIELDIDX=-` |
| SUB/FUNCTION | RQCONVERTCODEPAGE | conversion.inc(874): `FUNCTION RQCONVERTCODEPAGE (SOURSESTRING AS STRING, INPAGE AS LONG, OUTPAGE AS L` | conversionOld.inc(1174): `FUNCTION RQCONVERTCODEPAGE (SOURSESTRING AS STRING, INPAGE AS LONG, OUTPAGE AS L` |
| SUB/FUNCTION | RQCONVERTCODEPAGE1 | conversion.inc(913): `FUNCTION RQCONVERTCODEPAGE1 (SOURSESTRINGPTR AS LONG, INPAGE AS LONG, OUTPAGE AS` | conversionOld.inc(1212): `FUNCTION RQCONVERTCODEPAGE1 (SOURSESTRING AS STRING, INPAGE AS LONG, OUTPAGE AS ` |
| CONST | PI | rapidq2.inc(60): `3.14159` | Copy of NOTA.inc(48): `CONST PI = 3.14159265358979323846` |
| DECLARE | LOADLIBRARY | rapidq2.inc(2261): `DECLARE FUNCTION LOADLIBRARY LIB "KERNEL32" ALIAS "LOADLIBRARYA" (BYVAL LPLIBFIL` | createWind.inc(3): `DECLARE FUNCTION LOADLIBRARY LIB "KERNEL32" ALIAS "LOADLIBRARYA" _ (LIBFILENAME ` |
| DECLARE | CREATEWINDOWEX | rapidq2.inc(987): `DECLARE FUNCTION CREATEWINDOWEX LIB "USER32" ALIAS "CREATEWINDOWEXA" (DWEXSTYLE ` | createWind.inc(8): `DECLARE FUNCTION CREATEWINDOWEX LIB "USER32" ALIAS "CREATEWINDOWEXA" _ (EXSTYLE&` |
| DECLARE | SETWINDOWTEXT | rapidq2.inc(1013): `DECLARE FUNCTION SETWINDOWTEXT LIB "USER32" ALIAS "SETWINDOWTEXTA" (BYVAL HWND A` | createWind.inc(29): `DECLARE FUNCTION SETWINDOWTEXT LIB "USER32" ALIAS "SETWINDOWTEXTA" _ (HWND AS IN` |
| SUB/FUNCTION | DELTAGS | conversion.inc(788): `FUNCTION DELTAGS (HTMLTEXT AS STRING) AS STRING STRING1$=HTMLTEXT STRING1$=REPLA` | delTags.inc(161): `FUNCTION DELTAGS(HTMLTEXT AS STRING) AS STRING DIM LOWHTML AS STRING, OUTTEXT AS` |
| SUB/FUNCTION | GETMSGBODYCONTENTTYPE | eml.inc(22): `FUNCTION GETMSGBODYCONTENTTYPE ( MSG AS STRING) AS STRING MSG=REPLACESUBSTR$(MSG` | emlOld.inc(22): `FUNCTION GETMSGBODYCONTENTTYPE ( MSG AS STRING) AS STRING MSG=REPLACESUBSTR$(MSG` |
| SUB/FUNCTION | GETMSGBODYCODEPAGE | eml.inc(39): `FUNCTION GETMSGBODYCODEPAGE ( MSG AS STRING) AS STRING DIM I AS LONG MSG=REPLACE` | emlOld.inc(39): `FUNCTION GETMSGBODYCODEPAGE ( MSG AS STRING) AS STRING DIM I AS LONG MSG=REPLACE` |
| SUB/FUNCTION | GETMSGBODYCODEMETHOD | eml.inc(64): `FUNCTION GETMSGBODYCODEMETHOD( MSGBODY AS STRING) AS STRING DIM I AS LONG MSGBOD` | emlOld.inc(64): `FUNCTION GETMSGBODYCODEMETHOD( MSGBODY AS STRING) AS STRING DIM I AS LONG MSG=RE` |
| SUB/FUNCTION | GETHEADERFIELD | eml.inc(86): `FUNCTION GETHEADERFIELD( HEADER AS STRING, FIELD AS STRING) AS STRING HEADER=REP` | emlOld.inc(86): `FUNCTION GETHEADERFIELD( HEADER AS STRING, FIELD AS STRING) AS STRING HEADER=REP` |
| SUB/FUNCTION | GETMSGHEADER | eml.inc(123): `FUNCTION GETMSGHEADER( SOURCE AS STRING) AS STRING DIM MSGHEADER AS QSTRINGLIST ` | emlOld.inc(119): `FUNCTION GETMSGHEADER( SOURCE AS STRING) AS STRING DIM MSGHEADER AS QSTRINGLIST ` |
| SUB/FUNCTION | GETMSGBODY | eml.inc(150): `FUNCTION GETMSGBODY( SOURCE AS STRING) AS STRING DIM MSGBODY AS QSTRINGLIST DIM ` | emlOld.inc(150): `FUNCTION GETMSGBODY( SOURCE AS STRING) AS STRING DIM MSGBODY AS QSTRINGLIST DIM ` |
| SUB/FUNCTION | ISKOI8 | eml.inc(177): `FUNCTION ISKOI8( RED$ AS STRING) AS LONG RESULT=0 IF INSTR(RED$, " Ч ")>0 THEN R` | emlOld.inc(181): `FUNCTION ISKOI8( RED$ AS STRING) AS LONG RESULT=0 IF INSTR(RED$, "ДЩ")>0 THEN RE` |
| SUB/FUNCTION | DECODESUBJ | eml.inc(333): `FUNCTION DECODESUBJ( SUBJECT AS STRING) AS STRING DIM I AS INTEGER DIM L AS INTE` | emlOld.inc(646): `FUNCTION DECODESUBJ( SUBJECT AS STRING) AS STRING DIM I AS INTEGER DIM L AS INTE` |
| SUB/FUNCTION | STRIPPATH | Files.inc(82): `FUNCTION STRIPPATH (FULLNAME AS STRING) AS STRING RESULT = LEFT$(FULLNAME, RINST` | fileops.inc(27): `FUNCTION STRIPPATH(FULLNAME AS STRING) AS STRING RESULT = LEFT$(FULLNAME , RINST` |
| SUB/FUNCTION | STRIPFILENAME | Files.inc(95): `FUNCTION STRIPFILENAME (FULLNAME AS STRING) AS STRING RESULT = RIGHT$(FULLNAME, ` | fileops.inc(33): `FUNCTION STRIPFILENAME(FULLNAME AS STRING) AS STRING RESULT = RIGHT$(FULLNAME , ` |
| SUB/FUNCTION | STRIPFILEEXT | Files.inc(110): `FUNCTION STRIPFILEEXT (FULLNAME AS STRING) AS STRING IF INSTR(FULLNAME,".")=0 TH` | fileops.inc(39): `FUNCTION STRIPFILEEXT(FULLNAME AS STRING) AS STRING RESULT = RIGHT$(FULLNAME , L` |
| SUB/FUNCTION | FILENAMENOEXT | Files.inc(120): `FUNCTION FILENAMENOEXT(FULLNAME AS STRING) AS STRING FULLNAME = RIGHT$(FULLNAME,` | fileops.inc(45): `FUNCTION FILENAMENOEXT(FULLNAME AS STRING) AS STRING FULLNAME = RIGHT$(FULLNAME ` |
| SUB/FUNCTION | FULLPATHNOEXT | Files.inc(127): `FUNCTION FULLPATHNOEXT(FULLNAME AS STRING) AS STRING RESULT = LEFT$(FULLNAME, RI` | fileops.inc(52): `FUNCTION FULLPATHNOEXT(FULLNAME AS STRING) AS STRING RESULT = LEFT$(FULLNAME , R` |
| SUB/FUNCTION | C_STYLE | Files.inc(133): `FUNCTION C_STYLE (FULLNAME AS STRING) AS STRING FULLNAME = REPLACESUBSTR$(FULLNA` | fileops.inc(58): `FUNCTION C_STYLE(FULLNAME AS STRING) AS STRING FULLNAME = REPLACESUBSTR$(FULLNAM` |
| SUB/FUNCTION | SYSDIR | Files.inc(160): `FUNCTION SYSDIR (DIR AS STRING) AS STRING DIM FO_REG AS QREGISTRY FO_REG.ROOTKEY` | fileops.inc(77): `FUNCTION SYSDIR(DIR AS STRING) AS STRING DIM FO_REG AS QREGISTRY FO_REG.ROOTKEY ` |
| SUB/FUNCTION | HOMEDIR | Files.inc(170): `FUNCTION HOMEDIR() AS STRING RESULT = LEFT$(COMMAND$(0), RINSTR(COMMAND$(0), "\"` | fileops.inc(86): `FUNCTION HOMEDIR() AS STRING RESULT = LEFT$(COMMAND$(0) , RINSTR(COMMAND$(0) , "` |
| SUB/FUNCTION | BROWSEFORFOLDERS | Files.inc(177): `FUNCTION BROWSEFORFOLDERS (INITIALDIR AS STRING, WINCAPT AS STRING) AS STRING DI` | fileops.inc(122): `FUNCTION BROWSEFORFOLDERS(INITIALDIR AS STRING , WINCAPT AS STRING) AS STRING DI` |
| SUB/FUNCTION | STRIPFILEEXT | Files.inc(110): `FUNCTION STRIPFILEEXT (FULLNAME AS STRING) AS STRING IF INSTR(FULLNAME,".")=0 TH` | Files1.inc(47): `FUNCTION STRIPFILEEXT (FULLNAME AS STRING) AS STRING FULLNAME=STRIPFILENAME(FULL` |
| SUB/FUNCTION | FILESIZE | Files.inc(385): `FUNCTION FILESIZE(FILENAME AS STRING) AS INTEGER DIM FILESTR AS QFILESTREAM IF F` | Files1.inc(316): `FUNCTION FILESIZE(FILENAME AS STRING) AS INTEGER DIM FILESTR AS QFILESTREAM IF F` |
| SUB/FUNCTION | SAVESTRING | Files.inc(399): `FUNCTION SAVESTRING(SS$ AS STRING ,FILENAME AS STRING ) AS INTEGER RESULT=0 IF F` | Files1.inc(329): `FUNCTION SAVESTRING(SS$ AS STRING ,FILENAME AS STRING ) AS INTEGER RESULT=0 IF F` |
| SUB/FUNCTION | SAVESTRINGEX | Files.inc(417): `FUNCTION SAVESTRINGEX(SS$ AS STRING ,FILENAME AS STRING, MODE AS INTEGER ) AS IN` | Files1.inc(344): `FUNCTION SAVESTRINGEX(SS$ AS STRING ,FILENAME AS STRING, MODE AS INTEGER ) AS IN` |
| SUB/FUNCTION | LOADSTRING | Files.inc(473): `FUNCTION LOADSTRING(FILENAME AS STRING ) AS STRING DIM FILESTR AS QFILESTREAM RE` | Files1.inc(377): `FUNCTION LOADSTRING(FILENAME AS STRING ) AS STRING DIM FILESTR AS QFILESTREAM RE` |
| SUB/FUNCTION | SUBDIRCOPY | Files.inc(550): `SUB SUBDIRCOPY (DIRSRC$, DIRDST$, MASK$) DIM FILESRC AS QFILESTREAM DIM FILEDST ` | Files1.inc(420): `SUB SUBDIRCOPY (DIRSRC$, DIRDST$, MASK$) DIM FILESRC AS QFILESTREAM DIM FILEDST ` |
| SUB/FUNCTION | FSUBDIRCOPY | Files.inc(643): `FUNCTION FSUBDIRCOPY (DIRSRC$, DIRDST$, MASK$) AS LONG DIM FILESRC AS QFILESTREA` | Files1.inc(509): `FUNCTION FSUBDIRCOPY (DIRSRC$, DIRDST$, MASK$) AS LONG DIM FILESRC AS QFILESTREA` |
| SUB/FUNCTION | DIRCOPY | Files.inc(759): `FUNCTION DIRCOPY (DIRSRC$, DIRDST$, MASK$) AS LONG RESULT=0 DIM FILESRC AS QFILE` | Files1.inc(641): `FUNCTION DIRCOPY (DIRSRC$, DIRDST$, MASK$) AS LONG RESULT=0 DIM FILESRC AS QFILE` |
| SUB/FUNCTION | FILECOPY | Files.inc(834): `SUB FILECOPY (FILESRC$, FILEDST$) DIM FILESRC AS QFILESTREAM DIM FILEDST AS QFIL` | Files1.inc(679): `SUB FILECOPY (FILESRC$, FILEDST$) IF FILESRC$=FILEDST$ THEN SHOWMESSAGE ("FILECO` |
| SUB/FUNCTION | FFILECOPY | Files.inc(867): `FUNCTION FFILECOPY (FILESRC$, FILEDST$) AS LONG RESULT=0 DIM FILESRC AS QFILESTR` | Files1.inc(712): `FUNCTION FFILECOPY (FILESRC$, FILEDST$) RESULT=0 IF FILESIZE(FILESRC$)=0 THEN EX` |
| SUB/FUNCTION | KILLFILES | Files.inc(906): `SUB KILLFILES (FILENAME$) FNAME$ =STRIPPATH (FILENAME$)+ DIR$(FILENAME$, 0 ) WHI` | Files1.inc(751): `SUB KILLFILES (FILENAME$) FNAME$ =STRIPPATH (FILENAME$)+ DIR$(FILENAME$, 0 ) WHI` |
| SUB/FUNCTION | KILLSUBDIR | Files.inc(922): `SUB KILLSUBDIR (DIRSRC$, MASK$) DIM FILESRC AS QFILESTREAM NUMFILES=0 DEFINT NSD` | Files1.inc(771): `SUB KILLSUBDIR (DIRSRC$, MASK$) DIM FILESRC AS QFILESTREAM NUMFILES=0 DEFINT NSD` |
| SUB/FUNCTION | IO2RNDINTER | Files.inc(1100): `SUB IO2RNDINTER (IO$, RNDF$, LOSTP) DIM IO2RNDFILE2 AS QFILESTREAM DIM IO2RNDTMP` | Files1.inc(959): `SUB IO2RNDINTER (IO$, RNDF$, LOSTP) DIM IO2RNDFILE2 AS QFILESTREAM DIM IO2RNDTMP` |
| SUB/FUNCTION | IO2RNDINTER1 | Files.inc(1176): `SUB IO2RNDINTER1 (IO$, RNDF$, LOSTP) DIM IO2RNDFILE2 AS QFILESTREAM DIM IO2RNDAR` | Files1.inc(1030): `SUB IO2RNDINTER1 (IO$, RNDF$, LOSTP) DIM IO2RNDFILE2 AS QFILESTREAM DIM IO2RNDAR` |
| SUB/FUNCTION | IOAVERAGE | Files.inc(1359): `SUB IOAVERAGE (IO$, OUTF$, BPNT AS INTEGER) DIM INPUTLIST AS QSTRINGLIST DIM OUT` | Files1.inc(1177): `SUB IOAVERAGE (IO$, OUTF$, BPNT AS INTEGER) DIM INPUTLIST AS QSTRINGLIST DIM OUT` |
| SUB/FUNCTION | FILESIZE | Files.inc(385): `FUNCTION FILESIZE(FILENAME AS STRING) AS INTEGER DIM FILESTR AS QFILESTREAM IF F` | Files2.inc(315): `FUNCTION FILESIZE(FILENAME AS STRING) AS INTEGER DIM FILESTR AS QFILESTREAM IF F` |
| SUB/FUNCTION | SAVESTRING | Files.inc(399): `FUNCTION SAVESTRING(SS$ AS STRING ,FILENAME AS STRING ) AS INTEGER RESULT=0 IF F` | Files2.inc(329): `FUNCTION SAVESTRING(SS$ AS STRING ,FILENAME AS STRING ) AS INTEGER RESULT=0 IF F` |
| SUB/FUNCTION | SAVESTRINGEX | Files.inc(417): `FUNCTION SAVESTRINGEX(SS$ AS STRING ,FILENAME AS STRING, MODE AS INTEGER ) AS IN` | Files2.inc(355): `FUNCTION SAVESTRINGEX(SS$ AS STRING ,FILENAME AS STRING, MODE AS INTEGER ) AS IN` |
| SUB/FUNCTION | LOADSTRING | Files.inc(473): `FUNCTION LOADSTRING(FILENAME AS STRING ) AS STRING DIM FILESTR AS QFILESTREAM RE` | Files2.inc(388): `FUNCTION LOADSTRING(FILENAME AS STRING ) AS STRING DIM FILESTR AS QFILESTREAM RE` |
| SUB/FUNCTION | SUBDIRCOPY | Files.inc(550): `SUB SUBDIRCOPY (DIRSRC$, DIRDST$, MASK$) DIM FILESRC AS QFILESTREAM DIM FILEDST ` | Files2.inc(431): `SUB SUBDIRCOPY (DIRSRC$, DIRDST$, MASK$) DIM FILESRC AS QFILESTREAM DIM FILEDST ` |
| SUB/FUNCTION | FSUBDIRCOPY | Files.inc(643): `FUNCTION FSUBDIRCOPY (DIRSRC$, DIRDST$, MASK$) AS LONG DIM FILESRC AS QFILESTREA` | Files2.inc(520): `FUNCTION FSUBDIRCOPY (DIRSRC$, DIRDST$, MASK$) AS LONG DIM FILESRC AS QFILESTREA` |
| SUB/FUNCTION | DIRCOPY | Files.inc(759): `FUNCTION DIRCOPY (DIRSRC$, DIRDST$, MASK$) AS LONG RESULT=0 DIM FILESRC AS QFILE` | Files2.inc(652): `FUNCTION DIRCOPY (DIRSRC$, DIRDST$, MASK$) AS LONG RESULT=0 DIM FILESRC AS QFILE` |
| SUB/FUNCTION | FILECOPY | Files.inc(834): `SUB FILECOPY (FILESRC$, FILEDST$) DIM FILESRC AS QFILESTREAM DIM FILEDST AS QFIL` | Files2.inc(690): `SUB FILECOPY (FILESRC$, FILEDST$) DIM FILESRC AS QFILESTREAM DIM FILEDST AS QFIL` |
| SUB/FUNCTION | FFILECOPY | Files.inc(867): `FUNCTION FFILECOPY (FILESRC$, FILEDST$) AS LONG RESULT=0 DIM FILESRC AS QFILESTR` | Files2.inc(717): `FUNCTION FFILECOPY (FILESRC$, FILEDST$) AS LONG RESULT=0 DIM FILESRC AS QFILESTR` |
| SUB/FUNCTION | KILLFILES | Files.inc(906): `SUB KILLFILES (FILENAME$) FNAME$ =STRIPPATH (FILENAME$)+ DIR$(FILENAME$, 0 ) WHI` | Files2.inc(755): `SUB KILLFILES (FILENAME$) FNAME$ =STRIPPATH (FILENAME$)+ DIR$(FILENAME$, 0 ) WHI` |
| SUB/FUNCTION | KILLSUBDIR | Files.inc(922): `SUB KILLSUBDIR (DIRSRC$, MASK$) DIM FILESRC AS QFILESTREAM NUMFILES=0 DEFINT NSD` | Files2.inc(775): `SUB KILLSUBDIR (DIRSRC$, MASK$) DIM FILESRC AS QFILESTREAM NUMFILES=0 DEFINT NSD` |
| SUB/FUNCTION | IO2RNDINTER | Files.inc(1100): `SUB IO2RNDINTER (IO$, RNDF$, LOSTP) DIM IO2RNDFILE2 AS QFILESTREAM DIM IO2RNDTMP` | Files2.inc(963): `SUB IO2RNDINTER (IO$, RNDF$, LOSTP) DIM IO2RNDFILE2 AS QFILESTREAM DIM IO2RNDTMP` |
| SUB/FUNCTION | IO2RNDINTER1 | Files.inc(1176): `SUB IO2RNDINTER1 (IO$, RNDF$, LOSTP) DIM IO2RNDFILE2 AS QFILESTREAM DIM IO2RNDAR` | Files2.inc(1034): `SUB IO2RNDINTER1 (IO$, RNDF$, LOSTP) DIM IO2RNDFILE2 AS QFILESTREAM DIM IO2RNDAR` |
| SUB/FUNCTION | IOAVERAGE | Files.inc(1359): `SUB IOAVERAGE (IO$, OUTF$, BPNT AS INTEGER) DIM INPUTLIST AS QSTRINGLIST DIM OUT` | Files2.inc(1203): `SUB IOAVERAGE (IO$, OUTF$, BPNT AS INTEGER) DIM INPUTLIST AS QSTRINGLIST DIM OUT` |
| SUB/FUNCTION | BROWSEFORFOLDERS | Files.inc(177): `FUNCTION BROWSEFORFOLDERS (INITIALDIR AS STRING, WINCAPT AS STRING) AS STRING DI` | FilesBug.inc(4): `FUNCTION BROWSEFORFOLDERS (INITIALDIR AS STRING, WINCAPT AS STRING) AS STRING DI` |
| DECLARE | GETCURRENTPROCESS | rapidq2.inc(1502): `DECLARE FUNCTION GETCURRENTPROCESS LIB "KERNEL32" ALIAS "GETCURRENTPROCESS"() AS` | Kernel32.inc(70): `DECLARE FUNCTION GETCURRENTPROCESS LIB "KERNEL32.DLL" ALIAS_ "GETCURRENTPROCESS"` |
| DECLARE | GETLASTERROR | rapidq2.inc(1894): `DECLARE FUNCTION GETLASTERROR LIB "KERNEL32" ALIAS "GETLASTERROR" () AS DWORD` | Kernel32.inc(108): `DECLARE FUNCTION GETLASTERROR LIB "KERNEL32.DLL" ALIAS_ "GETLASTERROR" AS LONG` |
| TYPE | OSVERSIONINFO | rapidq2.inc(2055): `TYPE OSVERSIONINFO DWOSVERSIONINFOSIZE AS LONG DWMAJORVERSION AS LONG DWMINORVER` | Kernel32.inc(188): `TYPE OSVERSIONINFO DWOSVERSIONINFOSIZE AS LONG DWMAJORVERSION AS LONG DWMINORVER` |
| $DEFINE | VK_EXECUTE | rapidq2.inc(1096): `&H2B` | keys.inc(44): `49` |
| DECLARE | REGISTERCLASSEX | rapidq2.inc(985): `DECLARE FUNCTION REGISTERCLASSEX LIB "USER32" ALIAS "REGISTERCLASSEXA" (PCWNDCLA` | MDI_API.INC(16): `DECLARE FUNCTION REGISTERCLASSEX LIB "USER32" ALIAS "REGISTERCLASSEXA" _ (PCWNDC` |
| DECLARE | ENUMCHILDWINDOWS | rapidq2.inc(986): `DECLARE FUNCTION ENUMCHILDWINDOWS LIB "USER32" ALIAS "ENUMCHILDWINDOWS" (HWNDPAR` | MDI_API.INC(18): `DECLARE FUNCTION ENUMCHILDWINDOWS LIB "USER32" ALIAS "ENUMCHILDWINDOWS" _ (HWNDP` |
| DECLARE | CREATEWINDOWEX | rapidq2.inc(987): `DECLARE FUNCTION CREATEWINDOWEX LIB "USER32" ALIAS "CREATEWINDOWEXA" (DWEXSTYLE ` | MDI_API.INC(20): `DECLARE FUNCTION CREATEWINDOWEX LIB "USER32" ALIAS "CREATEWINDOWEXA" _ (DWEXSTYL` |
| DECLARE | DEFMDICHILDPROC | rapidq2.inc(988): `DECLARE FUNCTION DEFMDICHILDPROC LIB "USER32" ALIAS "DEFMDICHILDPROCA" (HWND AS ` | MDI_API.INC(24): `DECLARE FUNCTION DEFMDICHILDPROC LIB "USER32" ALIAS "DEFMDICHILDPROCA" _ (HWND A` |
| DECLARE | GETCLASSNAME | rapidq2.inc(989): `DECLARE FUNCTION GETCLASSNAME LIB "USER32" ALIAS "GETCLASSNAMEA" (HWND AS LONG, ` | MDI_API.INC(26): `DECLARE FUNCTION GETCLASSNAME LIB "USER32" ALIAS "GETCLASSNAMEA" _ (HWND AS LONG` |
| DECLARE | SETPROP | rapidq2.inc(990): `DECLARE FUNCTION SETPROP LIB "USER32" ALIAS "SETPROPA" (HWND AS LONG,LPSTRING AS` | MDI_API.INC(35): `DECLARE FUNCTION SETPROP LIB "USER32" ALIAS "SETPROPA" _ (HWND AS LONG, LPSTRING` |
| DECLARE | GETPROP | rapidq2.inc(991): `DECLARE FUNCTION GETPROP LIB "USER32" ALIAS "GETPROPA" (HWND AS LONG,LPSTRING AS` | MDI_API.INC(37): `DECLARE FUNCTION GETPROP LIB "USER32" ALIAS "GETPROPA" _ (HWND AS LONG, LPSTRING` |
| DECLARE | GETCLIENTRECT | rapidq2.inc(992): `DECLARE FUNCTION GETCLIENTRECT LIB "USER32" ALIAS "GETCLIENTRECT" (HWND AS LONG,` | MDI_API.INC(39): `DECLARE FUNCTION GETCLIENTRECT LIB "USER32" ALIAS "GETCLIENTRECT" _ (HWND AS LON` |
| DECLARE | MOVEWINDOW | rapidq2.inc(993): `DECLARE FUNCTION MOVEWINDOW LIB "USER32" ALIAS "MOVEWINDOW" (HWND AS LONG,X AS L` | MDI_API.INC(41): `DECLARE FUNCTION MOVEWINDOW LIB "USER32" ALIAS "MOVEWINDOW" _ (HWND AS LONG, X A` |
| DECLARE | GETWINDOWTEXT | rapidq2.inc(997): `DECLARE FUNCTION GETWINDOWTEXT LIB "USER32" ALIAS "GETWINDOWTEXTA" (BYVAL HWND A` | MDI_API.INC(45): `DECLARE FUNCTION GETWINDOWTEXT LIB "USER32" ALIAS "GETWINDOWTEXTA" _ (HWND AS LO` |
| DECLARE | SETFOCUS | rapidq2.inc(1010): `DECLARE FUNCTION SETFOCUS LIB "USER32" ALIAS "SETFOCUS" (HWND AS LONG) AS LONG` | MDI_API.INC(47): `DECLARE FUNCTION SETFOCUS LIB "USER32" ALIAS "SETFOCUS" _ (HWND AS LONG) AS LONG` |
| DECLARE | GETPROCESSHEAP | Kernel32.inc(126): `DECLARE FUNCTION GETPROCESSHEAP LIB "KERNEL32.DLL" ALIAS_ "GETPROCESSHEAP" AS LO` | Memory.inc(25): `DECLARE FUNCTION GETPROCESSHEAP LIB "KERNEL32" ALIAS "GETPROCESSHEAP" () AS LONG` |
| TYPE | LARGE_INTEGER | rapidq2.inc(872): `TYPE LARGE_INTEGER LOWPART AS DWORD HIGHPART AS DWORD END TYPE` | microTIMER.inc(5): `TYPE LARGE_INTEGER LOWPART AS LONG HIGHPART AS LONG END TYPE` |
| CONST | PI | rapidq2.inc(60): `3.14159` | NOTA.inc(75): `CONST PI = 3.14159265358979323846` |
| SUB/FUNCTION | GETLASTERROR$ | Copy of NOTA.inc(320): `FUNCTION GETLASTERROR$ DIM BPMLOOKUPERROR$ AS STRING BPMLOOKUPERROR$ = "NO ERROR` | NOTA.inc(372): `FUNCTION GETLASTERROR$ DIM BPMLOOKUPERROR$ AS STRING BPMLOOKUPERROR$ = "NO ERROR` |
| CONST | MFT_BITMAP | rapidq2.inc(1545): `&H4` | ODMenuXP.inc(591): `CONST MFT_BITMAP = MF_BITMAP` |
| CONST | MFT_MENUBARBREAK | rapidq2.inc(1546): `&H20` | ODMenuXP.inc(592): `CONST MFT_MENUBARBREAK = MF_MENUBARBREAK` |
| CONST | MFT_MENUBREAK | rapidq2.inc(1547): `&H40` | ODMenuXP.inc(593): `CONST MFT_MENUBREAK = MF_MENUBREAK` |
| CONST | MFT_OWNERDRAW | rapidq2.inc(1548): `&H100` | ODMenuXP.inc(594): `CONST MFT_OWNERDRAW = MF_OWNERDRAW` |
| CONST | MFT_RIGHTJUSTIFY | rapidq2.inc(1550): `&H4000` | ODMenuXP.inc(596): `CONST MFT_RIGHTJUSTIFY = MF_RIGHTJUSTIFY` |
| CONST | MFT_SEPARATOR | rapidq2.inc(1552): `&H800` | ODMenuXP.inc(598): `CONST MFT_SEPARATOR = MF_SEPARATOR` |
| CONST | MFT_STRING | rapidq2.inc(1553): `&H0` | ODMenuXP.inc(599): `CONST MFT_STRING = MF_STRING` |
| CONST | MFS_CHECKED | rapidq2.inc(1554): `&H8` | ODMenuXP.inc(601): `CONST MFS_CHECKED = MF_CHECKED` |
| CONST | MFS_DEFAULT | rapidq2.inc(1555): `&H1000` | ODMenuXP.inc(602): `CONST MFS_DEFAULT = MF_DEFAULT` |
| CONST | MFS_DISABLED | rapidq2.inc(1556): `&H2` | ODMenuXP.inc(603): `CONST MFS_DISABLED = MF_DISABLED` |
| CONST | MFS_ENABLED | rapidq2.inc(1557): `&H0` | ODMenuXP.inc(604): `CONST MFS_ENABLED = MF_ENABLED` |
| CONST | MFS_GRAYED | rapidq2.inc(1558): `&H1` | ODMenuXP.inc(605): `CONST MFS_GRAYED = MF_GRAYED` |
| CONST | MFS_HILITE | rapidq2.inc(1559): `&H80` | ODMenuXP.inc(606): `CONST MFS_HILITE = MF_HILITE` |
| CONST | MFS_UNCHECKED | rapidq2.inc(1560): `&H0` | ODMenuXP.inc(607): `CONST MFS_UNCHECKED = MF_UNCHECKED` |
| CONST | MFS_UNHILITE | rapidq2.inc(1561): `&H0` | ODMenuXP.inc(608): `CONST MFS_UNHILITE = MF_UNHILITE` |
| DECLARE | PAGESETUPDLG | rapidq2.inc(7261): `DECLARE FUNCTION PAGESETUPDLG LIB "COMDLG32" ALIAS "PAGESETUPDLGA" (PTR AS TPSD)` | printdlg.inc(46): `DECLARE FUNCTION PAGESETUPDLG LIB "COMDLG32" ALIAS "PAGESETUPDLGA" _ (PTR AS TPS` |
| DECLARE | GETDESKTOPWINDOW | rapidq2.inc(1475): `DECLARE FUNCTION GETDESKTOPWINDOW LIB "USER32" ALIAS "GETDESKTOPWINDOW" () AS LO` | PRINTERDLL.INC(186): `DECLARE FUNCTION GETDESKTOPWINDOW LIB "USER32.DLL" ALIAS "GETDESKTOPWINDOW" () A` |
| DECLARE | GETDC | rapidq2.inc(1482): `DECLARE FUNCTION GETDC LIB "USER32.DLL" ALIAS "GETDC"(BYVAL HWND AS LONG) AS LON` | PRINTERDLL.INC(187): `DECLARE FUNCTION GETDC LIB "USER32.DLL" ALIAS "GETDC" (HWND AS LONG) AS LONG` |
| DECLARE | GETDEVICECAPS | rapidq2.inc(1454): `DECLARE FUNCTION GETDEVICECAPS LIB "GDI32.DLL" ALIAS "GETDEVICECAPS"(BYVAL HDC A` | PRINTERDLL.INC(188): `DECLARE FUNCTION GETDEVICECAPS LIB "GDI32.DLL" ALIAS "GETDEVICECAPS" (HDC AS LON` |
| DECLARE | RELEASEDC | rapidq2.inc(1483): `DECLARE FUNCTION RELEASEDC LIB "USER32.DLL" ALIAS "RELEASEDC"(BYVAL HWND AS LONG` | PRINTERDLL.INC(189): `DECLARE FUNCTION RELEASEDC LIB "USER32.DLL" ALIAS "RELEASEDC" (HWND AS LONG, HDC` |
| CONST | WM_TRAYICON | rapidq2.inc(867): `&H590` | QFormSkin.inc(47): `CONST WM_TRAYICON = WM_USER + 400` |
| DECLARE | SETWINDOWLONG | rapidq2.inc(1039): `DECLARE FUNCTION SETWINDOWLONG LIB "USER32" ALIAS "SETWINDOWLONGA" (HWND AS LONG` | QFormSkin.inc(89): `DECLARE FUNCTION SETWINDOWLONG LIB "USER32" ALIAS "SETWINDOWLONGA" ( _ BYVAL HWN` |
| DECLARE | GETWINDOWLONG | rapidq2.inc(1037): `DECLARE FUNCTION GETWINDOWLONG LIB "USER32" ALIAS "GETWINDOWLONGA" (HWND AS LONG` | QFormSkin.inc(93): `DECLARE FUNCTION GETWINDOWLONG LIB "USER32" ALIAS "GETWINDOWLONGA" ( _ BYVAL HWN` |
| DECLARE | CALLWINDOWPROC | rapidq2.inc(1019): `DECLARE FUNCTION CALLWINDOWPROC LIB "USER32.DLL" ALIAS "CALLWINDOWPROCA" (LPPREV` | QFormSkin.inc(95): `DECLARE FUNCTION CALLWINDOWPROC LIB "USER32" ALIAS "CALLWINDOWPROCA" ( _ BYVAL L` |
| DECLARE | DEFWINDOWPROC | rapidq2.inc(1042): `DECLARE FUNCTION DEFWINDOWPROC LIB "USER32" ALIAS "DEFWINDOWPROCA" (HWND AS LONG` | QFormSkin.inc(101): `DECLARE FUNCTION DEFWINDOWPROC LIB "USER32" ALIAS "DEFWINDOWPROCA" ( _ BYVAL HWN` |
| DECLARE | WINDOWPROC | Api.inc(100): `DECLARE FUNCTION WINDOWPROC(HWND AS LONG, UMSG AS LONG, WPARAM AS LONG, LPARAM A` | QFormSkin.inc(108): `DECLARE FUNCTION WINDOWPROC ( BYVAL HWND AS LONG, _ BYVAL UMSG AS LONG, _ BYVAL ` |
| DECLARE | GETSYSTEMMETRICS | rapidq2.inc(2169): `DECLARE FUNCTION GETSYSTEMMETRICS LIB "USER32" ALIAS "GETSYSTEMMETRICS" (BYVAL N` | QFormSkin.inc(124): `DECLARE FUNCTION GETSYSTEMMETRICS LIB "USER32" ALIAS "GETSYSTEMMETRICS" _ (NINDE` |
| DECLARE | CREATERECTRGN | GDI32.inc(62): `DECLARE FUNCTION CREATERECTRGN LIB "GDI32.DLL" ALIAS_ "CREATERECTRGN" (X1 AS LON` | QFormSkin.inc(157): `DECLARE FUNCTION CREATERECTRGN LIB "GDI32" ALIAS "CREATERECTRGN" (BYVAL X1 AS LO` |
| DECLARE | CREATEELLIPTICRGN | GDI32.inc(53): `DECLARE FUNCTION CREATEELLIPTICRGN LIB "GDI32.DLL" ALIAS_ "CREATEELLIPTICRGN" (X` | QFormSkin.inc(166): `DECLARE FUNCTION CREATEELLIPTICRGN LIB "GDI32" ALIAS "CREATEELLIPTICRGN" (BYVAL ` |
| DECLARE | RELEASEDC | rapidq2.inc(1483): `DECLARE FUNCTION RELEASEDC LIB "USER32.DLL" ALIAS "RELEASEDC"(BYVAL HWND AS LONG` | QFormSkin.inc(173): `DECLARE FUNCTION RELEASEDC LIB "USER32" ALIAS "RELEASEDC" ( _ BYVAL HWND AS LONG` |
| DECLARE | DELETEOBJECT | rapidq2.inc(1451): `DECLARE FUNCTION DELETEOBJECT LIB "GDI32" ALIAS "DELETEOBJECT" (HOBJECT AS LONG)` | QFormSkin.inc(177): `DECLARE FUNCTION DELETEOBJECT LIB "GDI32" ALIAS "DELETEOBJECT" (BYVAL HOBJECT AS` |
| DECLARE | STRETCHBLT | rapidq2.inc(1467): `DECLARE FUNCTION STRETCHBLT LIB "GDI32" ALIAS "STRETCHBLT" (HDC AS LONG,X AS LON` | QFormSkin.inc(187): `DECLARE FUNCTION STRETCHBLT LIB "GDI32" ALIAS "STRETCHBLT" ( _ BYVAL HDC AS LONG` |
| DECLARE | DRAWICONEX | rapidq2.inc(1477): `DECLARE FUNCTION DRAWICONEX LIB "USER32" ALIAS "DRAWICONEX" (HDC AS LONG,XLEFT A` | QFormSkin.inc(206): `DECLARE FUNCTION DRAWICONEX LIB "USER32" ALIAS "DRAWICONEX" ( _ BYVAL HDC AS LON` |
| DECLARE | SETBKMODE | rapidq2.inc(1466): `DECLARE FUNCTION SETBKMODE LIB "GDI32" ALIAS "SETBKMODE" (HDC AS LONG,NBKMODE AS` | QFormSkin.inc(231): `DECLARE FUNCTION SETBKMODE LIB "GDI32" ALIAS "SETBKMODE" ( _ BYVAL HDC AS LONG, ` |
| DECLARE | COPYMEMORY | PRINTERDLL.INC(185): `DECLARE SUB COPYMEMORY LIB "KERNEL32.DLL" ALIAS "RTLMOVEMEMORY" (BYVAL DEST AS L` | QFormSkin.inc(234): `DECLARE SUB COPYMEMORY LIB "KERNEL32" ALIAS "RTLMOVEMEMORY" ( _ PDEST AS LONG, P` |
| DECLARE | SENDMESSAGEAPI | rapidq2.inc(980): `DECLARE FUNCTION SENDMESSAGEAPI LIB "USER32" ALIAS "SENDMESSAGEA" (HWND AS LONG,` | QFormSkin.inc(236): `DECLARE FUNCTION SENDMESSAGEAPI LIB "USER32" ALIAS "SENDMESSAGEA" ( _ BYVAL HWND` |
| SUB/FUNCTION | SETODMENUHOOKENABLED | ODMenuXP.inc(416): `SUB SETODMENUHOOKENABLED(HWND AS LONG, ENABLED AS INTEGER, ALTHOOK AS INTEGER) D` | QFormSkin.inc(265): `SUB SETODMENUHOOKENABLED(HWND AS LONG, ENABLED AS INTEGER) IF SETODMENUHOOKENABL` |
| SUB/FUNCTION | HEXTODEC | rapidq2.inc(8136): `FUNCTION HEXTODEC(HEX AS STRING)AS LONG RESULT = VAL(CONVBASE$(HEX, 16, 10)) END` | QFuncLib.inc(176): `FUNCTION HEXTODEC(HEX AS STRING)AS LONG DIM BIT AS LONG DIM VALBIT AS INTEGER DI` |
| DECLARE | PAGESETUPDLG | rapidq2.inc(7261): `DECLARE FUNCTION PAGESETUPDLG LIB "COMDLG32" ALIAS "PAGESETUPDLGA" (PTR AS TPSD)` | QPrintDialog.inc(46): `DECLARE FUNCTION PAGESETUPDLG LIB "COMDLG32" ALIAS "PAGESETUPDLGA" _ (PTR AS TPS` |
| CONST | EM_CANPASTE | constants.inc(62): `CONST EM_CANPASTE = 1074` | RichEditApi.inc(10): `CONST EM_CANPASTE =WM_USER + 50` |
| CONST | EM_DISPLAYBAND | constants.inc(65): `CONST EM_DISPLAYBAND = 1075` | RichEditApi.inc(11): `CONST EM_DISPLAYBAND =WM_USER + 51` |
| CONST | EM_EXGETSEL | constants.inc(67): `CONST EM_EXGETSEL = 1076` | RichEditApi.inc(12): `CONST EM_EXGETSEL =WM_USER + 52` |
| CONST | EM_EXLIMITTEXT | constants.inc(68): `CONST EM_EXLIMITTEXT = 1077` | RichEditApi.inc(13): `CONST EM_EXLIMITTEXT =WM_USER + 53` |
| CONST | EM_EXLINEFROMCHAR | constants.inc(69): `CONST EM_EXLINEFROMCHAR = 1078` | RichEditApi.inc(14): `CONST EM_EXLINEFROMCHAR =WM_USER + 54` |
| CONST | EM_EXSETSEL | constants.inc(70): `CONST EM_EXSETSEL = 1079` | RichEditApi.inc(15): `CONST EM_EXSETSEL =WM_USER + 55` |
| CONST | EM_FINDTEXT | constants.inc(71): `CONST EM_FINDTEXT = 1080` | RichEditApi.inc(16): `CONST EM_FINDTEXT =WM_USER + 56` |
| CONST | EM_FORMATRANGE | constants.inc(75): `CONST EM_FORMATRANGE = 1081` | RichEditApi.inc(17): `CONST EM_FORMATRANGE =WM_USER + 57` |
| CONST | EM_GETCHARFORMAT | constants.inc(76): `CONST EM_GETCHARFORMAT = 1082` | RichEditApi.inc(18): `CONST EM_GETCHARFORMAT =WM_USER + 58` |
| CONST | EM_GETEVENTMASK | constants.inc(77): `CONST EM_GETEVENTMASK = 1083` | RichEditApi.inc(19): `CONST EM_GETEVENTMASK =WM_USER + 59` |
| CONST | EM_GETOLEINTERFACE | constants.inc(88): `CONST EM_GETOLEINTERFACE = 1084` | RichEditApi.inc(20): `CONST EM_GETOLEINTERFACE =WM_USER + 60` |
| CONST | EM_GETPARAFORMAT | constants.inc(89): `CONST EM_GETPARAFORMAT = 1085` | RichEditApi.inc(21): `CONST EM_GETPARAFORMAT =WM_USER + 61` |
| CONST | EM_GETSELTEXT | constants.inc(94): `CONST EM_GETSELTEXT = 1086` | RichEditApi.inc(22): `CONST EM_GETSELTEXT =WM_USER + 62` |
| CONST | EM_HIDESELECTION | constants.inc(100): `CONST EM_HIDESELECTION = 1087` | RichEditApi.inc(23): `CONST EM_HIDESELECTION =WM_USER + 63` |
| CONST | EM_PASTESPECIAL | constants.inc(106): `CONST EM_PASTESPECIAL = 1088` | RichEditApi.inc(24): `CONST EM_PASTESPECIAL =WM_USER + 64` |
| CONST | EM_REQUESTRESIZE | constants.inc(109): `CONST EM_REQUESTRESIZE = 1089` | RichEditApi.inc(25): `CONST EM_REQUESTRESIZE =WM_USER + 65` |
| CONST | EM_SELECTIONTYPE | constants.inc(112): `CONST EM_SELECTIONTYPE = 1090` | RichEditApi.inc(26): `CONST EM_SELECTIONTYPE =WM_USER + 66` |
| CONST | EM_SETBKGNDCOLOR | constants.inc(113): `CONST EM_SETBKGNDCOLOR = 1091` | RichEditApi.inc(27): `CONST EM_SETBKGNDCOLOR =WM_USER + 67` |
| CONST | EM_SETCHARFORMAT | constants.inc(114): `CONST EM_SETCHARFORMAT = 1092` | RichEditApi.inc(28): `CONST EM_SETCHARFORMAT =WM_USER + 68` |
| CONST | EM_SETEVENTMASK | constants.inc(115): `CONST EM_SETEVENTMASK = 1093` | RichEditApi.inc(29): `CONST EM_SETEVENTMASK =WM_USER + 69` |
| CONST | EM_SETOLECALLBACK | constants.inc(122): `CONST EM_SETOLECALLBACK = 1094` | RichEditApi.inc(30): `CONST EM_SETOLECALLBACK =WM_USER + 70` |
| CONST | EM_SETPARAFORMAT | constants.inc(124): `CONST EM_SETPARAFORMAT = 1095` | RichEditApi.inc(31): `CONST EM_SETPARAFORMAT =WM_USER + 71` |
| CONST | EM_SETTARGETDEVICE | constants.inc(132): `CONST EM_SETTARGETDEVICE = 1096` | RichEditApi.inc(32): `CONST EM_SETTARGETDEVICE =WM_USER + 72` |
| CONST | EM_STREAMIN | constants.inc(136): `CONST EM_STREAMIN = 1097` | RichEditApi.inc(33): `CONST EM_STREAMIN =WM_USER + 73` |
| CONST | EM_STREAMOUT | constants.inc(137): `CONST EM_STREAMOUT = 1098` | RichEditApi.inc(34): `CONST EM_STREAMOUT =WM_USER + 74` |
| CONST | EM_GETTEXTRANGE | constants.inc(95): `CONST EM_GETTEXTRANGE = 1099` | RichEditApi.inc(35): `CONST EM_GETTEXTRANGE =WM_USER + 75` |
| CONST | EM_FINDWORDBREAK | constants.inc(73): `CONST EM_FINDWORDBREAK = 1100` | RichEditApi.inc(36): `CONST EM_FINDWORDBREAK =WM_USER + 76` |
| CONST | EM_SETOPTIONS | constants.inc(123): `CONST EM_SETOPTIONS = 1101` | RichEditApi.inc(37): `CONST EM_SETOPTIONS =WM_USER + 77` |
| CONST | EM_GETOPTIONS | constants.inc(87): `CONST EM_GETOPTIONS = 1102` | RichEditApi.inc(38): `CONST EM_GETOPTIONS =WM_USER + 78` |
| CONST | EM_FINDTEXTEX | constants.inc(72): `CONST EM_FINDTEXTEX = 1103` | RichEditApi.inc(39): `CONST EM_FINDTEXTEX =WM_USER + 79` |
| CONST | EM_GETWORDBREAKPROCEX | constants.inc(98): `CONST EM_GETWORDBREAKPROCEX = 1104` | RichEditApi.inc(40): `CONST EM_GETWORDBREAKPROCEX =WM_USER + 80` |
| CONST | EM_SETWORDBREAKPROCEX | constants.inc(134): `CONST EM_SETWORDBREAKPROCEX = 1105` | RichEditApi.inc(41): `CONST EM_SETWORDBREAKPROCEX =WM_USER + 81` |
| CONST | EM_SETPUNCTUATION | constants.inc(126): `CONST EM_SETPUNCTUATION = 1124` | RichEditApi.inc(57): `CONST EM_SETPUNCTUATION =WM_USER + 100` |
| CONST | EM_GETPUNCTUATION | constants.inc(91): `CONST EM_GETPUNCTUATION = 1125` | RichEditApi.inc(58): `CONST EM_GETPUNCTUATION =WM_USER + 101` |
| CONST | EM_SETWORDWRAPMODE | constants.inc(135): `CONST EM_SETWORDWRAPMODE = 1126` | RichEditApi.inc(59): `CONST EM_SETWORDWRAPMODE =WM_USER + 102` |
| CONST | EM_GETWORDWRAPMODE | constants.inc(99): `CONST EM_GETWORDWRAPMODE = 1127` | RichEditApi.inc(60): `CONST EM_GETWORDWRAPMODE =WM_USER + 103` |
| CONST | EM_SETIMECOLOR | constants.inc(117): `CONST EM_SETIMECOLOR = 1128` | RichEditApi.inc(61): `CONST EM_SETIMECOLOR =WM_USER + 104` |
| CONST | EM_GETIMECOLOR | constants.inc(85): `CONST EM_GETIMECOLOR = 1129` | RichEditApi.inc(62): `CONST EM_GETIMECOLOR =WM_USER + 105` |
| CONST | EM_SETIMEOPTIONS | constants.inc(118): `CONST EM_SETIMEOPTIONS = 1130` | RichEditApi.inc(63): `CONST EM_SETIMEOPTIONS =WM_USER + 106` |
| CONST | EM_GETIMEOPTIONS | constants.inc(86): `CONST EM_GETIMEOPTIONS = 1131` | RichEditApi.inc(64): `CONST EM_GETIMEOPTIONS =WM_USER + 107` |
| SUB/FUNCTION | ACOSH | Math.inc(8): `FUNCTION ACOSH(VALUE AS DOUBLE) AS DOUBLE SELECT CASE VALUE CASE IS < 1 MESSAGEB` | rq_math.inc(32): `FUNCTION ACOSH(VALUE AS DOUBLE) AS DOUBLE SELECT CASE VALUE CASE IS < 1 MESSAGEB` |
| SUB/FUNCTION | ACOTH | Math.inc(25): `FUNCTION ACOTH(VALUE AS DOUBLE) AS DOUBLE SELECT CASE ABS (VALUE) CASE IS > 1 AC` | rq_math.inc(49): `FUNCTION ACOTH(VALUE AS DOUBLE) AS DOUBLE SELECT CASE ABS (VALUE) CASE IS > 1 AC` |
| SUB/FUNCTION | ACOSEC | Math.inc(36): `FUNCTION ACOSEC(VALUE AS DOUBLE) AS DOUBLE SELECT CASE ABS (VALUE) CASE IS < 1 M` | rq_math.inc(60): `FUNCTION ACOSEC(VALUE AS DOUBLE) AS DOUBLE SELECT CASE ABS (VALUE) CASE IS < 1 M` |
| SUB/FUNCTION | ACOSECH | Math.inc(47): `FUNCTION ACOSECH(VALUE AS DOUBLE) AS DOUBLE SELECT CASE ABS(VALUE) CASE = 0 MESS` | rq_math.inc(71): `FUNCTION ACOSECH(VALUE AS DOUBLE) AS DOUBLE SELECT CASE ABS(VALUE) CASE = 0 MESS` |
| SUB/FUNCTION | ASEC | Math.inc(75): `FUNCTION ASEC(VALUE AS DOUBLE) AS DOUBLE SELECT CASE ABS (VALUE) CASE IS < 1 MES` | rq_math.inc(99): `FUNCTION ASEC(VALUE AS DOUBLE) AS DOUBLE SELECT CASE ABS (VALUE) CASE IS < 1 MES` |
| SUB/FUNCTION | ASECH | Math.inc(86): `FUNCTION ASECH(VALUE AS DOUBLE) AS DOUBLE SELECT CASE ABS (VALUE) CASE IS > 1 ME` | rq_math.inc(110): `FUNCTION ASECH(VALUE AS DOUBLE) AS DOUBLE SELECT CASE ABS (VALUE) CASE IS > 1 ME` |
| SUB/FUNCTION | ATANH | Math.inc(99): `FUNCTION ATANH(VALUE AS DOUBLE) AS DOUBLE SELECT CASE ABS(VALUE) CASE IS < 1 ATA` | rq_math.inc(123): `FUNCTION ATANH(VALUE AS DOUBLE) AS DOUBLE SELECT CASE ABS(VALUE) CASE IS < 1 ATA` |
| SUB/FUNCTION | COTH | Math.inc(163): `FUNCTION COTH(VALUE AS DOUBLE) AS DOUBLE SELECT CASE VALUE CASE 0 MESSAGEBOX("ER` | rq_math.inc(187): `FUNCTION COTH(VALUE AS DOUBLE) AS DOUBLE SELECT CASE VALUE CASE 0 MESSAGEBOX("ER` |
| SUB/FUNCTION | FAC | Math.inc(211): `FUNCTION FAC(VALUE AS LONG) AS LONG SELECT CASE VALUE CASE IS < 13 N = VALUE VAL` | rq_math.inc(235): `FUNCTION FAC(VALUE AS LONG) AS LONG SELECT CASE VALUE CASE IS < 13 N = VALUE VAL` |
| SUB/FUNCTION | GCD | Math.inc(228): `FUNCTION GCD(VALUE1 AS DOUBLE, VALUE2 AS DOUBLE ) AS LONG ERROR% = 0 SELECT CASE` | rq_math.inc(259): `FUNCTION GCD(VALUE1 AS DOUBLE, VALUE2 AS DOUBLE ) AS LONG ERROR% = 0 SELECT CASE` |
| SUB/FUNCTION | LOG10 | Math.inc(281): `FUNCTION LOG10(VALUE AS DOUBLE) AS DOUBLE LOG10 = LOG (VALUE)/LOG(10) END FUNCTI` | rq_math.inc(312): `FUNCTION LOG10(VALUE AS DOUBLE) AS DOUBLE LOG10 = (LOG (VALUE) * LOG(10 * RQE)) ` |
| DECLARE | CALLASMPROC | ole.inc(126): `DECLARE FUNCTION CALLASMPROC LIB "USER32" ALIAS "CALLWINDOWPROCA" _ (PROC AS LON` | RqAsmUtils.Inc(2): `DECLARE FUNCTION CALLASMPROC LIB "USER32" ALIAS "CALLWINDOWPROCA" _ (PROC AS LON` |
| TYPE | OPENFILENAME | rapidq2.inc(1663): `TYPE OPENFILENAME LSTRUCTSIZE AS DWORD HWNDOWNER AS LONG HINSTANCE AS LONG LPSTR` | RQDialog.inc(27): `TYPE OPENFILENAME LSTRUCTSIZE AS LONG HWNDOWNER AS LONG HINSTANCE AS LONG LPSTRF` |
| DECLARE | CLOSEHANDLE | rapidq2.inc(2038): `DECLARE FUNCTION CLOSEHANDLE LIB "KERNEL32" ALIAS "CLOSEHANDLE" _ (HOBJECT AS LO` | RQProcess.inc(69): `DECLARE FUNCTION CLOSEHANDLE LIB "KERNEL32" ALIAS "CLOSEHANDLE" _ ( HANDLE AS LO` |
| DECLARE | GETLASTERROR | rapidq2.inc(1894): `DECLARE FUNCTION GETLASTERROR LIB "KERNEL32" ALIAS "GETLASTERROR" () AS DWORD` | RQProcess.inc(72): `DECLARE FUNCTION GETLASTERROR LIB "KERNEL32" ALIAS "GETLASTERROR" AS LONG` |
| DECLARE | EXITPROCESS | Kernel32.inc, поднято(35): `DECLARE FUNCTION EXITPROCESS LIB "KERNEL32.DLL" ALIAS_ "EXITPROCESS" (UEXITCODE ` | RQProcess.inc(77): `DECLARE SUB EXITPROCESS LIB "KERNEL32" ALIAS "EXITPROCESS" ( UEXITCODE AS LONG)` |
| DECLARE | GETWINDOWSDIRECTORY | Kernel32.inc, поднято(213): `DECLARE FUNCTION GETWINDOWSDIRECTORY LIB "KERNEL32.DLL" ALIAS_ "GETWINDOWSDIRECT` | SetFileTimeAttrib.inc(124): `DECLARE FUNCTION GETWINDOWSDIRECTORY LIB "KERNEL32" ALIAS "GETWINDOWSDIRECTORYA"` |
| DECLARE | SETWINDOWLONG | rapidq2.inc(1039): `DECLARE FUNCTION SETWINDOWLONG LIB "USER32" ALIAS "SETWINDOWLONGA" (HWND AS LONG` | setup.inc(1): `DECLARE FUNCTION SETWINDOWLONG LIB "USER32" ALIAS "SETWINDOWLONGA" (HWND AS LONG` |
| SUB/FUNCTION | MINSET | Common.inc(20): `SUB MINSET (FRMHANDLE AS INTEGER, APPHANDLE AS INTEGER) SETWINDOWLONG(FRMHANDLE,` | setup.inc(3): `SUB MINSET (FHAND AS INTEGER, APPHAND AS INTEGER) SETWINDOWLONG(FHAND, -8, 0) SE` |
| SUB/FUNCTION | EXTRACTFILENAME | Files.inc(277): `FUNCTION EXTRACTFILENAME(FILENAME AS STRING) AS STRING DIM LENGTH AS INTEGER DIM` | SysUtils.inc(3): `FUNCTION EXTRACTFILENAME(FILE AS STRING) AS STRING DEFINT SL,I IF FILE = "" THEN` |
| SUB/FUNCTION | EXTRACTFILEPATH | Files.inc(310): `FUNCTION EXTRACTFILEPATH(FILENAME AS STRING) AS STRING DIM LENGTH AS INTEGER DIM` | SysUtils.inc(17): `FUNCTION EXTRACTFILEPATH(FILE AS STRING) AS STRING DEFINT SL,I IF FILE = "" THEN` |
| SUB/FUNCTION | CHANGEFILEEXT | Files.inc(242): `FUNCTION CHANGEFILEEXT(FILENAME AS STRING, NEWEXT AS STRING) AS STRING DIM RETUR` | SysUtils.inc(59): `FUNCTION CHANGEFILEEXT(FILE AS STRING,EXT AS STRING) AS STRING DEFINT PT,I IF FI` |
| SUB/FUNCTION | TRIM$ | rapidq.inc(641): `FUNCTION TRIM$(S AS STRING) AS STRING RESULT=LTRIM$(RTRIM$(S)) END FUNCTION` | SysUtils.inc(93): `FUNCTION TRIM$(S AS STRING) AS STRING RESULT = LTRIM$(RTRIM$(S)) -CHR$(10)-CHR$(` |
| DECLARE | GETCAPTURE | rapidq2.inc(999): `DECLARE FUNCTION GETCAPTURE LIB "USER32" ALIAS "GETCAPTURE" () AS LONG` | User32.inc(29): `DECLARE FUNCTION GETCAPTURE LIB "USER32.DLL" ALIAS_ "GETCAPTURE" AS LONG` |
| DECLARE | GETCLASSNAME | rapidq2.inc(989): `DECLARE FUNCTION GETCLASSNAME LIB "USER32" ALIAS "GETCLASSNAMEA" (HWND AS LONG, ` | User32.inc(35): `DECLARE FUNCTION GETCLASSNAME LIB "USER32.DLL" ALIAS_ "GETCLASSNAMEA" (HWND AS L` |
| DECLARE | GETDESKTOPWINDOW | rapidq2.inc(1475): `DECLARE FUNCTION GETDESKTOPWINDOW LIB "USER32" ALIAS "GETDESKTOPWINDOW" () AS LO` | User32.inc(48): `DECLARE FUNCTION GETDESKTOPWINDOW LIB "USER32.DLL" ALIAS_ "GETDESKTOPWINDOW" AS ` |
| DECLARE | GETFOCUS | rapidq2.inc(994): `DECLARE FUNCTION GETFOCUS LIB "USER32" ALIAS "GETFOCUS"() AS LONG` | User32.inc(66): `DECLARE FUNCTION GETFOCUS LIB "USER32.DLL" ALIAS_ "GETFOCUS" AS LONG` |
| DECLARE | GETSYSTEMMETRICS | rapidq2.inc(2169): `DECLARE FUNCTION GETSYSTEMMETRICS LIB "USER32" ALIAS "GETSYSTEMMETRICS" (BYVAL N` | User32.inc(184): `DECLARE FUNCTION GETSYSTEMMETRICS LIB "USER32.DLL" ALIAS_ "GETSYSTEMMETRICS" (NI` |
| DECLARE | GETWINDOWTEXT | rapidq2.inc(997): `DECLARE FUNCTION GETWINDOWTEXT LIB "USER32" ALIAS "GETWINDOWTEXTA" (BYVAL HWND A` | User32.inc(190): `DECLARE FUNCTION GETWINDOWTEXT LIB "USER32.DLL" ALIAS_ "GETWINDOWTEXTA" (HWND AS` |
| DECLARE | GETWINDOWTEXTLENGTH | rapidq2.inc(998): `DECLARE FUNCTION GETWINDOWTEXTLENGTH LIB "USER32" ALIAS "GETWINDOWTEXTLENGTHA" (` | User32.inc(197): `DECLARE FUNCTION GETWINDOWTEXTLENGTH LIB "USER32.DLL" ALIAS_ "GETWINDOWTEXTLENGT` |
| DECLARE | SETFOREGROUNDWINDOW | rapidq2.inc(1012): `DECLARE FUNCTION SETFOREGROUNDWINDOW LIB "USER32" ALIAS "SETFOREGROUNDWINDOW" (B` | User32.inc(210): `DECLARE FUNCTION SETFOREGROUNDWINDOW LIB "USER32.DLL" ALIAS_ "SETFOREGROUNDWINDO` |
| DECLARE | SETWINDOWPOS | rapidq2.inc(1029): `DECLARE SUB SETWINDOWPOS LIB "USER32" ALIAS "SETWINDOWPOS"_ (BYVAL HWND AS LONG,` | User32.inc(216): `DECLARE FUNCTION SETWINDOWPOS LIB "USER32.DLL" ALIAS_ "SETWINDOWPOS" (HWND AS LO` |
| DECLARE | SETWINDOWRGN | QFormSkin.inc(159): `DECLARE FUNCTION SETWINDOWRGN LIB "USER32" ALIAS "SETWINDOWRGN" (BYVAL HWND AS L` | User32.inc(226): `DECLARE FUNCTION SETWINDOWRGN LIB "USER32.DLL" ALIAS_ "SETWINDOWRGN" (HWND AS LO` |
| DECLARE | BRINGWINDOWTOTOP | rapidq2.inc(984): `DECLARE FUNCTION BRINGWINDOWTOTOP LIB "USER32" ALIAS "BRINGWINDOWTOTOP" (BYVAL H` | WFunctions.inc(8): `DECLARE FUNCTION BRINGWINDOWTOTOP LIB "USER32" ALIAS "BRINGWINDOWTOTOP"_ (BYVAL ` |
| DECLARE | FINDWINDOW | User32.inc(17): `DECLARE FUNCTION FINDWINDOW LIB "USER32.DLL" ALIAS_ "FINDWINDOWA" (LPCLASSNAME A` | WFunctions.inc(11): `DECLARE FUNCTION FINDWINDOW LIB "USER32" ALIAS "FINDWINDOWA" _ (CLASSNAME AS STR` |
| DECLARE | SETWINDOWPOS | rapidq2.inc(1029): `DECLARE SUB SETWINDOWPOS LIB "USER32" ALIAS "SETWINDOWPOS"_ (BYVAL HWND AS LONG,` | WFunctions.inc(14): `DECLARE SUB SETWINDOWPOS LIB "USER32" ALIAS "SETWINDOWPOS"(HWND AS LONG,_ HWNDIN` |
| DECLARE | SHELLEXECUTE | rapidq2.inc(1056): `DECLARE FUNCTION SHELLEXECUTE LIB "SHELL32.DLL" ALIAS "SHELLEXECUTEA" (BYVAL HWN` | WFunctions.inc(18): `DECLARE FUNCTION SHELLEXECUTE LIB "SHELL32.DLL" ALIAS "SHELLEXECUTEA" _ (BYVAL H` |
| DECLARE | SETFOREGROUNDWINDOW | rapidq2.inc(1012): `DECLARE FUNCTION SETFOREGROUNDWINDOW LIB "USER32" ALIAS "SETFOREGROUNDWINDOW" (B` | WFunctions.inc(23): `DECLARE FUNCTION SETFOREGROUNDWINDOW LIB "USER32" ALIAS _ "SETFOREGROUNDWINDOW" ` |
| DECLARE | SETPARENT | rapidq2.inc(1011): `DECLARE FUNCTION SETPARENT LIB "USER32" ALIAS "SETPARENT" (HWNDCHILD AS LONG,HWN` | WFunctions.inc(26): `DECLARE FUNCTION SETPARENT LIB "USER32" ALIAS _ "SETPARENT"(HWNDCHILD AS LONG, H` |
| DECLARE | LOADLIBRARY | rapidq2.inc(2261): `DECLARE FUNCTION LOADLIBRARY LIB "KERNEL32" ALIAS "LOADLIBRARYA" (BYVAL LPLIBFIL` | WFunctions.inc(29): `DECLARE FUNCTION LOADLIBRARY LIB "KERNEL32" ALIAS "LOADLIBRARYA" _ (LIBFILENAME ` |
| DECLARE | LOADCURSOR | QFormSkin.inc(249): `DECLARE FUNCTION LOADCURSOR LIB "USER32" ALIAS "LOADCURSORA" _ (BYVAL HINSTANCE ` | WFunctions.inc(35): `DECLARE FUNCTION LOADCURSOR LIB "USER32" ALIAS "LOADCURSORA" _ (HINST AS LONG, C` |
| DECLARE | SETWINDOWLONG | rapidq2.inc(1039): `DECLARE FUNCTION SETWINDOWLONG LIB "USER32" ALIAS "SETWINDOWLONGA" (HWND AS LONG` | WFunctions.inc(41): `DECLARE FUNCTION SETWINDOWLONG LIB "USER32" ALIAS "SETWINDOWLONGA"_ (HWND AS LON` |
| DECLARE | GETWINDOWLONG | rapidq2.inc(1037): `DECLARE FUNCTION GETWINDOWLONG LIB "USER32" ALIAS "GETWINDOWLONGA" (HWND AS LONG` | WFunctions.inc(44): `DECLARE FUNCTION GETWINDOWLONG LIB "USER32" ALIAS "GETWINDOWLONGA"_ (HWND AS LON` |
| DECLARE | GETKEYSTATE | rapidq2.inc(1200): `DECLARE FUNCTION GETKEYSTATE LIB "USER32" ALIAS "GETKEYSTATE" (BYVAL NVIRTKEY AS` | WFunctions.inc(47): `DECLARE FUNCTION GETKEYSTATE LIB "USER32" ALIAS "GETKEYSTATE"_ (NVIRTKEY AS LONG` |
| CONST | WS_OVERLAPPEDWINDOW | rapidq2.inc(970): `CONST WS_OVERLAPPEDWINDOW=(WS_OVERLAPPED OR WS_CAPTION OR WS_SYSMENU OR WS_THICK` | Win32_constants.inc(49): `CONST WS_OVERLAPPEDWINDOW = &HCF0000` |
| TYPE | LARGE_INTEGER | rapidq2.inc(872): `TYPE LARGE_INTEGER LOWPART AS DWORD HIGHPART AS DWORD END TYPE` | WIN32API.INC(247): `TYPE LARGE_INTEGER LOWPART AS LONG HIGHPART AS LONG END TYPE` |
| TYPE | OVERLAPPED | rapidq2.inc(1813): `TYPE OVERLAPPED INTERNAL AS LONG INTERNALHIGH AS LONG OFFSET AS DWORD OFFSETHIGH` | WIN32API.INC(457): `TYPE OVERLAPPED INTERNAL AS LONG INTERNALHIGH AS LONG OFFSET AS LONG OFFSETHIGH ` |
| TYPE | SYSTEMTIME | ApiDate.inc(12): `TYPE SYSTEMTIME WYEAR AS WORD WMONTH AS WORD WDAYOFWEEK AS WORD WDAY AS WORD WHO` | WIN32API.INC(483): `TYPE SYSTEMTIME WYEAR AS INTEGER WMONTH AS INTEGER WDAYOFWEEK AS INTEGER WDAY AS` |
| TYPE | COMSTAT | rapidq2.inc(1784): `TYPE COMSTAT COMSTATFLAGS AS DWORD CBINQUE AS DWORD CBOUTQUE AS DWORD END TYPE` | WIN32API.INC(606): `TYPE COMSTAT FBITFIELDS AS LONG CBINQUE AS LONG CBOUTQUE AS LONG END TYPE` |
| TYPE | DCB | rapidq2.inc(1750): `TYPE DCB DCBLENGTH AS DWORD BAUDRATE AS DWORD DCBFLAGS AS DWORD WRESERVED AS WOR` | WIN32API.INC(664): `TYPE DCB DCBLENGTH AS LONG BAUDRATE AS LONG FBITFIELDS AS LONG WRESERVED AS INTE` |
| TYPE | COMMTIMEOUTS | rapidq2.inc(1738): `TYPE COMMTIMEOUTS READINTERVALTIMEOUT AS DWORD READTOTALTIMEOUTMULTIPLIER AS DWO` | WIN32API.INC(699): `TYPE COMMTIMEOUTS READINTERVALTIMEOUT AS LONG READTOTALTIMEOUTMULTIPLIER AS LONG` |
| TYPE | LUID_AND_ATTRIBUTES | rapidq2.inc(2179): `TYPE LUID_AND_ATTRIBUTES LOWPART AS LONG HIGHTPART AS LONG ATTRIBUTES AS LONG EN` | WIN32API.INC(1095): `TYPE LUID_AND_ATTRIBUTES PLUID AS LUID ATTRIBUTES AS LONG END TYPE` |
| DECLARE | GETMODULEHANDLE | createWind.inc(26): `DECLARE FUNCTION GETMODULEHANDLE LIB "KERNEL32" ALIAS "GETMODULEHANDLEA" _ (MODU` | WIN32API.INC(1824): `DECLARE FUNCTION GETMODULEHANDLE LIB "KERNEL32" ALIAS "GETMODULEHANDLEA" (BYVAL ` |
| DECLARE | GETCOMMANDLINE | Kernel32.inc(41): `DECLARE FUNCTION GETCOMMANDLINE LIB "KERNEL32.DLL" ALIAS_ "GETCOMMANDLINEA" AS S` | WIN32API.INC(1833): `DECLARE FUNCTION GETCOMMANDLINE LIB "KERNEL32" ALIAS "GETCOMMANDLINEA" AS STRING` |
| DECLARE | FREELIBRARY | createWind.inc(5): `DECLARE FUNCTION FREELIBRARY LIB "KERNEL32" ALIAS "FREELIBRARY" _ (HINST AS LONG` | WIN32API.INC(1844): `DECLARE FUNCTION FREELIBRARY LIB "KERNEL32" ALIAS "FREELIBRARY" (BYVAL HLIBMODUL` |
| DECLARE | GETVERSION | Kernel32.inc(177): `DECLARE FUNCTION GETVERSION LIB "KERNEL32.DLL" ALIAS_ "GETVERSION" AS DWORD` | WIN32API.INC(1869): `DECLARE FUNCTION GETVERSION LIB "KERNEL32" ALIAS "GETVERSION" () AS LONG` |
| DECLARE | GETLOGICALDRIVES | Kernel32.inc(114): `DECLARE FUNCTION GETLOGICALDRIVES LIB "KERNEL32.DLL" ALIAS_ "GETLOGICALDRIVES" A` | WIN32API.INC(1879): `DECLARE FUNCTION GETLOGICALDRIVES LIB "KERNEL32" ALIAS "GETLOGICALDRIVES" () AS ` |
| DECLARE | WRITEFILE | rapidq2.inc(1989): `DECLARE FUNCTION WRITEFILE LIB "KERNEL32" ALIAS "WRITEFILE"_ (HFILE AS LONG, _ L` | WIN32API.INC(1907): `DECLARE FUNCTION WRITEFILE LIB "KERNEL32" ALIAS "WRITEFILE" (BYVAL HFILE AS LONG` |
| DECLARE | READFILE | rapidq2.inc(2019): `DECLARE FUNCTION READFILE LIB "KERNEL32" ALIAS "READFILE"_ (HFILE AS LONG, _ BYR` | WIN32API.INC(1908): `DECLARE FUNCTION READFILE LIB "KERNEL32" ALIAS "READFILE" (BYVAL HFILE AS LONG, ` |
| DECLARE | CLOSEHANDLE | rapidq2.inc(2038): `DECLARE FUNCTION CLOSEHANDLE LIB "KERNEL32" ALIAS "CLOSEHANDLE" _ (HOBJECT AS LO` | WIN32API.INC(1916): `DECLARE FUNCTION CLOSEHANDLE LIB "KERNEL32" ALIAS "CLOSEHANDLE" (BYVAL HOBJECT A` |
| DECLARE | GETDRIVETYPE | rapidq2.inc(1505): `DECLARE FUNCTION GETDRIVETYPE LIB "KERNEL32" ALIAS "GETDRIVETYPEA" (NDRIVE AS ST` | WIN32API.INC(1919): `DECLARE FUNCTION GETDRIVETYPE LIB "KERNEL32" ALIAS "GETDRIVETYPEA" (BYVAL NDRIVE` |
| DECLARE | HEAPREALLOC | Memory.inc(22): `DECLARE FUNCTION HEAPREALLOC LIB "KERNEL32" ALIAS "HEAPREALLOC" (BYVAL HHEAP AS ` | WIN32API.INC(1966): `DECLARE FUNCTION HEAPREALLOC LIB "KERNEL32" ALIAS "HEAPREALLOC" (BYVAL HHEAP AS ` |
| DECLARE | HEAPFREE | Memory.inc(23): `DECLARE FUNCTION HEAPFREE LIB "KERNEL32" ALIAS "HEAPFREE" (BYVAL HHEAP AS LONG, ` | WIN32API.INC(1967): `DECLARE FUNCTION HEAPFREE LIB "KERNEL32" ALIAS "HEAPFREE" (BYVAL HHEAP AS LONG, ` |
| DECLARE | HEAPSIZE | Memory.inc(24): `DECLARE FUNCTION HEAPSIZE LIB "KERNEL32" ALIAS "HEAPSIZE" (BYVAL HHEAP AS LONG, ` | WIN32API.INC(1968): `DECLARE FUNCTION HEAPSIZE LIB "KERNEL32" ALIAS "HEAPSIZE" (BYVAL HHEAP AS LONG, ` |
| DECLARE | GETPROCESSHEAP | Kernel32.inc(126): `DECLARE FUNCTION GETPROCESSHEAP LIB "KERNEL32.DLL" ALIAS_ "GETPROCESSHEAP" AS LO` | WIN32API.INC(1969): `DECLARE FUNCTION GETPROCESSHEAP LIB "KERNEL32" ALIAS "GETPROCESSHEAP" () AS LONG` |
| DECLARE | OPENPROCESS | RQProcess.inc(66): `DECLARE FUNCTION OPENPROCESS LIB "KERNEL32" ALIAS "OPENPROCESS" _ (DESIREDACCESS` | WIN32API.INC(1971): `DECLARE FUNCTION OPENPROCESS LIB "KERNEL32" ALIAS "OPENPROCESS" (BYVAL DWDESIRED` |
| DECLARE | GETCURRENTPROCESS | rapidq2.inc(1502): `DECLARE FUNCTION GETCURRENTPROCESS LIB "KERNEL32" ALIAS "GETCURRENTPROCESS"() AS` | WIN32API.INC(1972): `DECLARE FUNCTION GETCURRENTPROCESS LIB "KERNEL32" ALIAS "GETCURRENTPROCESS" () A` |
| DECLARE | GETCURRENTPROCESSID | Kernel32.inc(76): `DECLARE FUNCTION GETCURRENTPROCESSID LIB "KERNEL32.DLL" ALIAS_ "GETCURRENTPROCES` | WIN32API.INC(1973): `DECLARE FUNCTION GETCURRENTPROCESSID LIB "KERNEL32" ALIAS "GETCURRENTPROCESSID" ` |
| DECLARE | EXITPROCESS | Kernel32.inc, поднято(35): `DECLARE FUNCTION EXITPROCESS LIB "KERNEL32.DLL" ALIAS_ "EXITPROCESS" (UEXITCODE ` | WIN32API.INC(1974): `DECLARE SUB EXITPROCESS LIB "KERNEL32" ALIAS "EXITPROCESS" (BYVAL UEXITCODE AS L` |
| DECLARE | TERMINATEPROCESS | RQProcess.inc(74): `DECLARE FUNCTION TERMINATEPROCESS LIB "KERNEL32" ALIAS "TERMINATEPROCESS" _ ( HP` | WIN32API.INC(1975): `DECLARE FUNCTION TERMINATEPROCESS LIB "KERNEL32" ALIAS "TERMINATEPROCESS" (BYVAL` |
| DECLARE | GETEXITCODEPROCESS | RQProcess.inc(79): `DECLARE FUNCTION GETEXITCODEPROCESS LIB "KERNEL32" ALIAS "GETEXITCODEPROCESS" _ ` | WIN32API.INC(1976): `DECLARE FUNCTION GETEXITCODEPROCESS LIB "KERNEL32" ALIAS "GETEXITCODEPROCESS" (B` |
| DECLARE | GETLASTERROR | rapidq2.inc(1894): `DECLARE FUNCTION GETLASTERROR LIB "KERNEL32" ALIAS "GETLASTERROR" () AS DWORD` | WIN32API.INC(1978): `DECLARE FUNCTION GETLASTERROR LIB "KERNEL32" ALIAS "GETLASTERROR" () AS LONG` |
| DECLARE | GETWINDOWSDIRECTORY | Kernel32.inc, поднято(213): `DECLARE FUNCTION GETWINDOWSDIRECTORY LIB "KERNEL32.DLL" ALIAS_ "GETWINDOWSDIRECT` | WIN32API.INC(2058): `DECLARE FUNCTION GETWINDOWSDIRECTORY LIB "KERNEL32" ALIAS "GETWINDOWSDIRECTORYA"` |
| DECLARE | GETTEMPPATH | Kernel32.inc, поднято(148): `DECLARE FUNCTION GETTEMPPATH LIB "KERNEL32.DLL" ALIAS_ "GETTEMPPATHA" (NBUFFERLE` | WIN32API.INC(2060): `DECLARE FUNCTION GETTEMPPATH LIB "KERNEL32" ALIAS "GETTEMPPATHA" (BYVAL NBUFFERL` |
| DECLARE | GETDISKFREESPACE | Kernel32.inc, поднято(94): `DECLARE FUNCTION GETDISKFREESPACE LIB "KERNEL32.DLL" ALIAS_ "GETDISKFREESPACEA" ` | WIN32API.INC(2063): `DECLARE FUNCTION GETDISKFREESPACE LIB "KERNEL32" ALIAS "GETDISKFREESPACEA" (BYVA` |
| DECLARE | CREATEDIRECTORY | Files.inc(34): `DECLARE FUNCTION CREATEDIRECTORY LIB "KERNEL32" ALIAS "CREATEDIRECTORYA" _ (BYVA` | WIN32API.INC(2064): `DECLARE FUNCTION CREATEDIRECTORY LIB "KERNEL32" ALIAS "CREATEDIRECTORYA" (BYVAL ` |
| DECLARE | SETFILEATTRIBUTES | Files.inc(31): `DECLARE FUNCTION SETFILEATTRIBUTES LIB "KERNEL32" ALIAS "SETFILEATTRIBUTESA"_ (B` | WIN32API.INC(2078): `DECLARE FUNCTION SETFILEATTRIBUTES LIB "KERNEL32" ALIAS "SETFILEATTRIBUTESA" (BY` |
| DECLARE | GETFILEATTRIBUTES | Files.inc(29): `DECLARE FUNCTION GETFILEATTRIBUTES LIB "KERNEL32" ALIAS "GETFILEATTRIBUTESA"_ (B` | WIN32API.INC(2079): `DECLARE FUNCTION GETFILEATTRIBUTES LIB "KERNEL32" ALIAS "GETFILEATTRIBUTESA" (BY` |
| DECLARE | DELETEFILE | Kernel32.inc(26): `DECLARE FUNCTION DELETEFILE LIB "KERNEL32.DLL" ALIAS_ "DELETEFILEA" (LPFILENAME ` | WIN32API.INC(2080): `DECLARE FUNCTION DELETEFILE LIB "KERNEL32" ALIAS "DELETEFILEA" (BYVAL LPFILENAME` |
| DECLARE | COPYFILE | Kernel32.inc(16): `DECLARE FUNCTION COPYFILE LIB "KERNEL32.DLL" ALIAS_ "COPYFILEA" (LPEXISTINGFILEN` | WIN32API.INC(2084): `DECLARE FUNCTION COPYFILE LIB "KERNEL32" ALIAS "COPYFILEA" (BYVAL LPEXISTINGFILE` |
| TYPE | TOKEN_PRIVILEGES | rapidq2.inc(2186): `TYPE TOKEN_PRIVILEGES PRIVILEGECOUNT AS LONG LOWPART AS LONG HIGHPART AS LONG AT` | WIN32API.INC(2154): `TYPE TOKEN_PRIVILEGES PRIVILEGECOUNT AS LONG PRIVILEGES(ANYSIZE_ARRAY) AS LUID_A` |
| DECLARE | OPENPROCESSTOKEN | rapidq2.inc(2197): `DECLARE FUNCTION OPENPROCESSTOKEN LIB "ADVAPI32" ALIAS "OPENPROCESSTOKEN" _ (PRO` | WIN32API.INC(2159): `DECLARE FUNCTION OPENPROCESSTOKEN LIB "ADVAPI32.DLL" ALIAS "OPENPROCESSTOKEN" (B` |
| DECLARE | ADJUSTTOKENPRIVILEGES | rapidq2.inc(2207): `DECLARE FUNCTION ADJUSTTOKENPRIVILEGES LIB "ADVAPI32" ALIAS "ADJUSTTOKENPRIVILEG` | WIN32API.INC(2164): `DECLARE FUNCTION ADJUSTTOKENPRIVILEGES LIB "ADVAPI32.DLL" ALIAS "ADJUSTTOKENPRIV` |
| DECLARE | GETENVIRONMENTSTRINGS | Kernel32.inc(102): `DECLARE FUNCTION GETENVIRONMENTSTRINGS LIB "KERNEL32.DLL" ALIAS_ "GETENVIRONMENT` | WIN32API.INC(2231): `DECLARE FUNCTION GETENVIRONMENTSTRINGS LIB "KERNEL32" ALIAS "GETENVIRONMENTSTRIN` |
| DECLARE | GETCURRENTTHREAD | Kernel32.inc(82): `DECLARE FUNCTION GETCURRENTTHREAD LIB "KERNEL32.DLL" ALIAS_ "GETCURRENTTHREAD" A` | WIN32API.INC(2237): `DECLARE FUNCTION GETCURRENTTHREAD LIB "KERNEL32" ALIAS "GETCURRENTTHREAD" () AS ` |
| DECLARE | GETCURRENTTHREADID | Kernel32.inc(88): `DECLARE FUNCTION GETCURRENTTHREADID LIB "KERNEL32.DLL" ALIAS_ "GETCURRENTTHREADI` | WIN32API.INC(2238): `DECLARE FUNCTION GETCURRENTTHREADID LIB "KERNEL32" ALIAS "GETCURRENTTHREADID" ()` |
| DECLARE | SETCOMMSTATE | rapidq2.inc(1953): `DECLARE FUNCTION SETCOMMSTATE LIB "KERNEL32" ALIAS "SETCOMMSTATE" _ (HFILE AS LO` | WIN32API.INC(2248): `DECLARE FUNCTION SETCOMMSTATE LIB "KERNEL32" ALIAS "SETCOMMSTATE" (BYVAL HCOMMDE` |
| DECLARE | SETCOMMTIMEOUTS | rapidq2.inc(1937): `DECLARE FUNCTION SETCOMMTIMEOUTS LIB "KERNEL32" ALIAS "SETCOMMTIMEOUTS"_ (HFILE ` | WIN32API.INC(2249): `DECLARE FUNCTION SETCOMMTIMEOUTS LIB "KERNEL32" ALIAS "SETCOMMTIMEOUTS" (BYVAL H` |
| DECLARE | GETCOMMSTATE | rapidq2.inc(1945): `DECLARE FUNCTION GETCOMMSTATE LIB "KERNEL32" ALIAS "GETCOMMSTATE" _ (HFILE AS LO` | WIN32API.INC(2250): `DECLARE FUNCTION GETCOMMSTATE LIB "KERNEL32" ALIAS "GETCOMMSTATE" (BYVAL NCID AS` |
| DECLARE | PURGECOMM | rapidq2.inc(1928): `DECLARE FUNCTION PURGECOMM LIB "KERNEL32" ALIAS "PURGECOMM"_ (HFILE AS LONG, _ D` | WIN32API.INC(2252): `DECLARE FUNCTION PURGECOMM LIB "KERNEL32" ALIAS "PURGECOMM" (BYVAL HFILE AS LONG` |
| DECLARE | CLEARCOMMERROR | rapidq2.inc(1964): `DECLARE FUNCTION CLEARCOMMERROR LIB "KERNEL32" ALIAS "CLEARCOMMERROR" _ (HFILE A` | WIN32API.INC(2259): `DECLARE FUNCTION CLEARCOMMERROR LIB "KERNEL32" ALIAS "CLEARCOMMERROR" (BYVAL HFI` |
| DECLARE | SETUPCOMM | rapidq2.inc(1917): `DECLARE FUNCTION SETUPCOMM LIB "KERNEL32" ALIAS "SETUPCOMM"_ (HFILE AS LONG,_ DW` | WIN32API.INC(2260): `DECLARE FUNCTION SETUPCOMM LIB "KERNEL32" ALIAS "SETUPCOMM" (BYVAL HFILE AS LONG` |
| DECLARE | GETTICKCOUNT | Kernel32.inc(159): `DECLARE FUNCTION GETTICKCOUNT LIB "KERNEL32.DLL" ALIAS_ "GETTICKCOUNT" AS LONG` | WIN32API.INC(2317): `DECLARE FUNCTION GETTICKCOUNT LIB "KERNEL32" ALIAS "GETTICKCOUNT" () AS LONG` |
| DECLARE | FORMATMESSAGE | rapidq2.inc(1902): `DECLARE FUNCTION FORMATMESSAGE LIB "KERNEL32" ALIAS "FORMATMESSAGEA" _ (DWFLAGS ` | WIN32API.INC(2318): `DECLARE FUNCTION FORMATMESSAGE LIB "KERNEL32" ALIAS "FORMATMESSAGEA" (BYVAL DWFL` |
| DECLARE | GETCOMPUTERNAME | Kernel32.inc, поднято(52): `DECLARE FUNCTION GETCOMPUTERNAME LIB "KERNEL32.DLL" ALIAS_ "GETCOMPUTERNAMEA" (L` | WIN32API.INC(2428): `DECLARE FUNCTION GETCOMPUTERNAME LIB "KERNEL32" ALIAS "GETCOMPUTERNAMEA" (BYVAL ` |
| DECLARE | GETUSERNAME | AdvAPI32.inc(14): `DECLARE FUNCTION GETUSERNAME LIB "ADVAPI32.DLL" ALIAS_ "GETUSERNAMEA" (LPBUFFER ` | WIN32API.INC(2430): `DECLARE FUNCTION GETUSERNAME LIB "ADVAPI32.DLL" ALIAS "GETUSERNAMEA" (BYVAL LPBU` |
| DECLARE | GETOEMCP | Kernel32.inc(120): `DECLARE FUNCTION GETOEMCP LIB "KERNEL32.DLL" ALIAS_ "GETOEMCP" AS LONG` | WIN32API.INC(2677): `DECLARE FUNCTION GETOEMCP LIB "KERNEL32" ALIAS "GETOEMCP" () AS LONG` |
| DECLARE | MULTIBYTETOWIDECHAR | conversion.inc(75): `DECLARE FUNCTION MULTIBYTETOWIDECHAR LIB "KERNEL32" ALIAS "MULTIBYTETOWIDECHAR" ` | WIN32API.INC(2680): `DECLARE FUNCTION MULTIBYTETOWIDECHAR LIB "KERNEL32" ALIAS "MULTIBYTETOWIDECHAR" ` |
| DECLARE | WIDECHARTOMULTIBYTE | conversion.inc(81): `DECLARE FUNCTION WIDECHARTOMULTIBYTE LIB "KERNEL32" ALIAS "WIDECHARTOMULTIBYTE" ` | WIN32API.INC(2681): `DECLARE FUNCTION WIDECHARTOMULTIBYTE LIB "KERNEL32" ALIAS "WIDECHARTOMULTIBYTE" ` |
| DECLARE | GETLOCALEINFO | ApiDate.inc(29): `DECLARE FUNCTION GETLOCALEINFO LIB "KERNEL32" ALIAS "GETLOCALEINFOA" _ (BYVAL LO` | WIN32API.INC(2687): `DECLARE FUNCTION GETLOCALEINFO LIB "KERNEL32" ALIAS "GETLOCALEINFOA" (BYVAL LOCA` |
| DECLARE | GETDATEFORMAT | ApiDate.inc(22): `DECLARE FUNCTION GETDATEFORMAT LIB "KERNEL32" ALIAS "GETDATEFORMATA" _ (BYVAL LO` | WIN32API.INC(2689): `DECLARE FUNCTION GETDATEFORMAT LIB "KERNEL32" ALIAS "GETDATEFORMATA" (BYVAL LOCA` |
| DECLARE | GETSYSTEMDEFAULTLANGID | Kernel32.inc(132): `DECLARE FUNCTION GETSYSTEMDEFAULTLANGID LIB "KERNEL32.DLL" ALIAS_ "GETSYSTEMDEFA` | WIN32API.INC(2691): `DECLARE FUNCTION GETSYSTEMDEFAULTLANGID LIB "KERNEL32" ALIAS "GETSYSTEMDEFAULTLA` |
| DECLARE | GETUSERDEFAULTLANGID | Kernel32.inc(165): `DECLARE FUNCTION GETUSERDEFAULTLANGID LIB "KERNEL32.DLL" ALIAS_ "GETUSERDEFAULTL` | WIN32API.INC(2692): `DECLARE FUNCTION GETUSERDEFAULTLANGID LIB "KERNEL32" ALIAS "GETUSERDEFAULTLANGID` |
| DECLARE | GETSYSTEMDEFAULTLCID | Kernel32.inc(138): `DECLARE FUNCTION GETSYSTEMDEFAULTLCID LIB "KERNEL32.DLL" ALIAS_ "GETSYSTEMDEFAUL` | WIN32API.INC(2693): `DECLARE FUNCTION GETSYSTEMDEFAULTLCID LIB "KERNEL32" ALIAS "GETSYSTEMDEFAULTLCID` |
| DECLARE | GETUSERDEFAULTLCID | Kernel32.inc(171): `DECLARE FUNCTION GETUSERDEFAULTLCID LIB "KERNEL32.DLL" ALIAS_ "GETUSERDEFAULTLCI` | WIN32API.INC(2694): `DECLARE FUNCTION GETUSERDEFAULTLCID LIB "KERNEL32" ALIAS "GETUSERDEFAULTLCID" ()` |
| DECLARE | GETTHREADLOCALE | Kernel32.inc(153): `DECLARE FUNCTION GETTHREADLOCALE LIB "KERNEL32.DLL" ALIAS_ "GETTHREADLOCALE" AS ` | WIN32API.INC(2810): `DECLARE FUNCTION GETTHREADLOCALE LIB "KERNEL32" ALIAS "GETTHREADLOCALE" () AS LO` |
| DECLARE | GETCONSOLECP | Kernel32.inc(58): `DECLARE FUNCTION GETCONSOLECP LIB "KERNEL32.DLL" ALIAS_ "GETCONSOLECP" AS LONG` | WIN32API.INC(2971): `DECLARE FUNCTION GETCONSOLECP LIB "KERNEL32" ALIAS "GETCONSOLECP" () AS LONG` |
| DECLARE | GETCONSOLEOUTPUTCP | Kernel32.inc(64): `DECLARE FUNCTION GETCONSOLEOUTPUTCP LIB "KERNEL32.DLL" ALIAS_ "GETCONSOLEOUTPUTC` | WIN32API.INC(2973): `DECLARE FUNCTION GETCONSOLEOUTPUTCP LIB "KERNEL32" ALIAS "GETCONSOLEOUTPUTCP" ()` |
| CONST | HOLLOW_BRUSH | rapidq2.inc(1262): `5` | WIN32API.INC(3830): `PUBLIC CONST HOLLOW_BRUSH = NULL_BRUSH` |
| TYPE | DEVMODE | rapidq2.inc(1305): `TYPE DEVMODE DMDEVICENAME AS STRING * CCHDEVICENAME DMSPECVERSION AS WORD DMDRIV` | WIN32API.INC(4068): `TYPE DEVMODE DMDEVICENAME AS STRING * CCHDEVICENAME DMSPECVERSION AS INTEGER DMD` |
| DECLARE | BITBLT | rapidq2.inc(1434): `DECLARE FUNCTION BITBLT LIB "GDI32.DLL" ALIAS "BITBLT" (_ BYVAL HDCDEST AS LONG,` | WIN32API.INC(4354): `DECLARE FUNCTION BITBLT LIB "GDI32" ALIAS "BITBLT" (BYVAL HDESTDC AS LONG, BYVAL` |
| DECLARE | COMBINERGN | GDI32.inc(43): `DECLARE FUNCTION COMBINERGN LIB "GDI32.DLL" ALIAS_ "COMBINERGN" (HRGNDEST AS LON` | WIN32API.INC(4358): `DECLARE FUNCTION COMBINERGN LIB "GDI32" ALIAS "COMBINERGN" (BYVAL HDESTRGN AS LO` |
| DECLARE | CREATECOMPATIBLEBITMAP | rapidq2.inc(1446): `DECLARE FUNCTION CREATECOMPATIBLEBITMAP LIB "GDI32" ALIAS "CREATECOMPATIBLEBITMA` | WIN32API.INC(4364): `DECLARE FUNCTION CREATECOMPATIBLEBITMAP LIB "GDI32" ALIAS "CREATECOMPATIBLEBITMA` |
| DECLARE | CREATECOMPATIBLEDC | rapidq2.inc(1447): `DECLARE FUNCTION CREATECOMPATIBLEDC LIB "GDI32" ALIAS "CREATECOMPATIBLEDC" (HDC ` | WIN32API.INC(4367): `DECLARE FUNCTION CREATECOMPATIBLEDC LIB "GDI32" ALIAS "CREATECOMPATIBLEDC" (BYVA` |
| DECLARE | CREATEDC | rapidq2.inc(1429): `DECLARE FUNCTION CREATEDC LIB "GDI32" ALIAS "CREATEDCA" (_ BYVAL LPDRIVERNAME AS` | WIN32API.INC(4368): `DECLARE FUNCTION CREATEDC LIB "GDI32" ALIAS "CREATEDCA" (BYVAL LPDRIVERNAME AS S` |
| DECLARE | CREATEELLIPTICRGN | GDI32.inc(53): `DECLARE FUNCTION CREATEELLIPTICRGN LIB "GDI32.DLL" ALIAS_ "CREATEELLIPTICRGN" (X` | WIN32API.INC(4374): `DECLARE FUNCTION CREATEELLIPTICRGN LIB "GDI32" ALIAS "CREATEELLIPTICRGN" (BYVAL ` |
| DECLARE | CREATEPEN | rapidq2.inc(1448): `DECLARE FUNCTION CREATEPEN LIB "GDI32" ALIAS "CREATEPEN" (NPENSTYLE AS LONG, NWI` | WIN32API.INC(4385): `DECLARE FUNCTION CREATEPEN LIB "GDI32" ALIAS "CREATEPEN" (BYVAL NPENSTYLE AS LON` |
| DECLARE | CREATERECTRGN | GDI32.inc(62): `DECLARE FUNCTION CREATERECTRGN LIB "GDI32.DLL" ALIAS_ "CREATERECTRGN" (X1 AS LON` | WIN32API.INC(4387): `DECLARE FUNCTION CREATERECTRGN LIB "GDI32" ALIAS "CREATERECTRGN" (BYVAL X1 AS LO` |
| DECLARE | CREATEROUNDRECTRGN | GDI32.inc(72): `DECLARE FUNCTION CREATEROUNDRECTRGN LIB "GDI32.DLL" ALIAS_ "CREATEROUNDRECTRGN" ` | WIN32API.INC(4391): `DECLARE FUNCTION CREATEROUNDRECTRGN LIB "GDI32" ALIAS "CREATEROUNDRECTRGN" (BYVA` |
| DECLARE | CREATESOLIDBRUSH | rapidq2.inc(1449): `DECLARE FUNCTION CREATESOLIDBRUSH LIB "GDI32" ALIAS "CREATESOLIDBRUSH" (CRCOLOR ` | WIN32API.INC(4393): `DECLARE FUNCTION CREATESOLIDBRUSH LIB "GDI32" ALIAS "CREATESOLIDBRUSH" (BYVAL CR` |
| DECLARE | DELETEDC | rapidq2.inc(1450): `DECLARE FUNCTION DELETEDC LIB "GDI32" ALIAS "DELETEDC" (HDC AS LONG) AS LONG` | WIN32API.INC(4395): `DECLARE FUNCTION DELETEDC LIB "GDI32" ALIAS "DELETEDC" (BYVAL HDC AS LONG) AS LO` |
| DECLARE | DELETEOBJECT | rapidq2.inc(1451): `DECLARE FUNCTION DELETEOBJECT LIB "GDI32" ALIAS "DELETEOBJECT" (HOBJECT AS LONG)` | WIN32API.INC(4396): `DECLARE FUNCTION DELETEOBJECT LIB "GDI32" ALIAS "DELETEOBJECT" (BYVAL HOBJECT AS` |
| DECLARE | ELLIPSE | rapidq2.inc(1452): `DECLARE FUNCTION ELLIPSE LIB "GDI32" ALIAS "ELLIPSE" (HDC AS LONG,X1 AS LONG,Y1 ` | WIN32API.INC(4437): `DECLARE FUNCTION ELLIPSE LIB "GDI32" ALIAS "ELLIPSE" (BYVAL HDC AS LONG, BYVAL X` |
| DECLARE | EXCLUDECLIPRECT | QFormSkin.inc(241): `DECLARE FUNCTION EXCLUDECLIPRECT LIB "GDI32.DLL" ALIAS "EXCLUDECLIPRECT" ( _ BYV` | WIN32API.INC(4443): `DECLARE FUNCTION EXCLUDECLIPRECT LIB "GDI32" ALIAS "EXCLUDECLIPRECT" (BYVAL HDC ` |
| DECLARE | EXTFLOODFILL | rapidq2.inc(1453): `DECLARE FUNCTION EXTFLOODFILL LIB "GDI32" ALIAS "EXTFLOODFILL" (HDC AS LONG,X AS` | WIN32API.INC(4445): `DECLARE FUNCTION EXTFLOODFILL LIB "GDI32" ALIAS "EXTFLOODFILL" (BYVAL HDC AS LON` |
| DECLARE | GETCURRENTOBJECT | rapidq2.inc(1456): `DECLARE FUNCTION GETCURRENTOBJECT LIB "GDI32" ALIAS "GETCURRENTOBJECT" (HDC AS L` | WIN32API.INC(4467): `DECLARE FUNCTION GETCURRENTOBJECT LIB "GDI32" ALIAS "GETCURRENTOBJECT" (BYVAL HD` |
| DECLARE | GETDEVICECAPS | rapidq2.inc(1454): `DECLARE FUNCTION GETDEVICECAPS LIB "GDI32.DLL" ALIAS "GETDEVICECAPS"(BYVAL HDC A` | WIN32API.INC(4469): `DECLARE FUNCTION GETDEVICECAPS LIB "GDI32" ALIAS "GETDEVICECAPS" (BYVAL HDC AS L` |
| DECLARE | GETPIXEL | rapidq2.inc(1457): `DECLARE FUNCTION GETPIXEL LIB "GDI32" ALIAS "GETPIXEL" (HDC AS LONG,X AS LONG,Y ` | WIN32API.INC(4484): `DECLARE FUNCTION GETPIXEL LIB "GDI32" ALIAS "GETPIXEL" (BYVAL HDC AS LONG, BYVAL` |
| DECLARE | GETRGNBOX | QFormSkin.inc(150): `DECLARE FUNCTION GETRGNBOX LIB "GDI32.DLL" ALIAS "GETRGNBOX" ( _ BYVAL HRGN AS L` | WIN32API.INC(4488): `DECLARE FUNCTION GETRGNBOX LIB "GDI32" ALIAS "GETRGNBOX" (BYVAL HRGN AS LONG, LP` |
| DECLARE | GETSTOCKOBJECT | rapidq2.inc(1458): `DECLARE FUNCTION GETSTOCKOBJECT LIB "GDI32" ALIAS "GETSTOCKOBJECT" (NINDEX AS LO` | WIN32API.INC(4489): `DECLARE FUNCTION GETSTOCKOBJECT LIB "GDI32" ALIAS "GETSTOCKOBJECT" (BYVAL NINDEX` |
| DECLARE | LINETO | rapidq2.inc(1459): `DECLARE FUNCTION LINETO LIB "GDI32" ALIAS "LINETO" (HDC AS LONG,X AS LONG,Y AS L` | WIN32API.INC(4508): `DECLARE FUNCTION LINETO LIB "GDI32" ALIAS "LINETO" (BYVAL HDC AS LONG, BYVAL X A` |
| DECLARE | PATBLT | rapidq2.inc(1461): `DECLARE FUNCTION PATBLT LIB "GDI32" ALIAS "PATBLT" (HDC AS LONG,X AS LONG,Y AS L` | WIN32API.INC(4514): `DECLARE FUNCTION PATBLT LIB "GDI32" ALIAS "PATBLT" (BYVAL HDC AS LONG, BYVAL X A` |
| DECLARE | RECTANGLE | rapidq2.inc(1462): `DECLARE FUNCTION RECTANGLE LIB "GDI32" ALIAS "RECTANGLE" (HDC AS LONG,X1 AS LONG` | WIN32API.INC(4523): `DECLARE FUNCTION RECTANGLE LIB "GDI32" ALIAS "RECTANGLE" (BYVAL HDC AS LONG, BYV` |
| DECLARE | ROUNDRECT | rapidq2.inc(1463): `DECLARE FUNCTION ROUNDRECT LIB "GDI32" ALIAS "ROUNDRECT" (HDC AS LONG,X1 AS LONG` | WIN32API.INC(4528): `DECLARE FUNCTION ROUNDRECT LIB "GDI32" ALIAS "ROUNDRECT" (BYVAL HDC AS LONG, BYV` |
| DECLARE | SELECTOBJECT | rapidq2.inc(1464): `DECLARE FUNCTION SELECTOBJECT LIB "GDI32" ALIAS "SELECTOBJECT" (HDC AS LONG,HOBJ` | WIN32API.INC(4535): `DECLARE FUNCTION SELECTOBJECT LIB "GDI32" ALIAS "SELECTOBJECT" (BYVAL HDC AS LON` |
| DECLARE | SETBKMODE | rapidq2.inc(1466): `DECLARE FUNCTION SETBKMODE LIB "GDI32" ALIAS "SETBKMODE" (HDC AS LONG,NBKMODE AS` | WIN32API.INC(4538): `DECLARE FUNCTION SETBKMODE LIB "GDI32" ALIAS "SETBKMODE" (BYVAL HDC AS LONG, BYV` |
| DECLARE | STRETCHBLT | rapidq2.inc(1467): `DECLARE FUNCTION STRETCHBLT LIB "GDI32" ALIAS "STRETCHBLT" (HDC AS LONG,X AS LON` | WIN32API.INC(4552): `DECLARE FUNCTION STRETCHBLT LIB "GDI32" ALIAS "STRETCHBLT" (BYVAL HDC AS LONG, B` |
| DECLARE | SETRECTRGN | QFormSkin.inc(152): `DECLARE FUNCTION SETRECTRGN LIB "GDI32.DLL" ALIAS "SETRECTRGN" ( _ BYVAL HRGN AS` | WIN32API.INC(4553): `DECLARE FUNCTION SETRECTRGN LIB "GDI32" ALIAS "SETRECTRGN" (BYVAL HRGN AS LONG, ` |
| DECLARE | SETROP2 | rapidq2.inc(1465): `DECLARE FUNCTION SETROP2 LIB "GDI32" ALIAS "SETROP2" (HDC AS LONG,NDRAWMODE AS L` | WIN32API.INC(4555): `DECLARE FUNCTION SETROP2 LIB "GDI32" ALIAS "SETROP2" (BYVAL HDC AS LONG, BYVAL N` |
| DECLARE | SETTEXTCOLOR | QFormSkin.inc(229): `DECLARE FUNCTION SETTEXTCOLOR LIB "GDI32" ALIAS "SETTEXTCOLOR" ( _ BYVAL HDC AS ` | WIN32API.INC(4559): `DECLARE FUNCTION SETTEXTCOLOR LIB "GDI32" ALIAS "SETTEXTCOLOR" (BYVAL HDC AS LON` |
| DECLARE | GETPROCESSWINDOWSTATION | User32.inc(120): `DECLARE FUNCTION GETPROCESSWINDOWSTATION LIB "USER32.DLL" ALIAS_ "GETPROCESSWIND` | WIN32API.INC(6111): `DECLARE FUNCTION GETPROCESSWINDOWSTATION LIB "USER32" ALIAS "GETPROCESSWINDOWSTA` |
| CONST | WM_MOUSELAST | rapidq2.inc(864): `&H20A` | WIN32API.INC(6300): `PUBLIC CONST WM_MOUSELAST = &H209` |
| CONST | WS_TILED | Win32_constants.inc(56): `CONST WS_TILED = 0` | WIN32API.INC(6458): `PUBLIC CONST WS_TILED = WS_OVERLAPPED` |
| CONST | WS_ICONIC | Win32_constants.inc(43): `CONST WS_ICONIC = &H20000000` | WIN32API.INC(6459): `PUBLIC CONST WS_ICONIC = WS_MINIMIZE` |
| CONST | WS_SIZEBOX | Win32_constants.inc(52): `CONST WS_SIZEBOX = &H40000` | WIN32API.INC(6460): `PUBLIC CONST WS_SIZEBOX = WS_THICKFRAME` |
| CONST | WS_TILEDWINDOW | Win32_constants.inc(57): `CONST WS_TILEDWINDOW = &HCF0000` | WIN32API.INC(6462): `PUBLIC CONST WS_TILEDWINDOW = WS_OVERLAPPEDWINDOW` |
| CONST | WS_POPUPWINDOW | Win32_constants.inc(51): `CONST WS_POPUPWINDOW = &H80880000` | WIN32API.INC(6469): `PUBLIC CONST WS_POPUPWINDOW = (WS_POPUP OR WS_BORDER OR WS_SYSMENU)` |
| CONST | WS_CHILDWINDOW | Win32_constants.inc(36): `CONST WS_CHILDWINDOW = &H40000000` | WIN32API.INC(6471): `PUBLIC CONST WS_CHILDWINDOW = (WS_CHILD)` |
| TYPE | WINDOWPLACEMENT | Form.inc(26): `PRIVATE TYPE WINDOWPLACEMENT LENGTH AS LONG FLAGS AS LONG SHOWCMD AS LONG PTMINP` | WIN32API.INC(6568): `TYPE WINDOWPLACEMENT LENGTH AS LONG FLAGS AS LONG SHOWCMD AS LONG PTMINPOSITION ` |
| TYPE | MEASUREITEMSTRUCT | rapidq2.inc(1563): `TYPE MEASUREITEMSTRUCT CTLTYPE AS LONG CTLID AS LONG ITEMID AS LONG ITEMWIDTH AS` | WIN32API.INC(6599): `TYPE MEASUREITEMSTRUCT CTLTYPE AS LONG CTLID AS LONG ITEMID AS LONG ITEMWIDTH AS` |
| TYPE | DRAWITEMSTRUCT | rapidq2.inc(1572): `TYPE DRAWITEMSTRUCT CTLTYPE AS LONG CTLID AS LONG ITEMID AS LONG ITEMACTION AS L` | WIN32API.INC(6609): `TYPE DRAWITEMSTRUCT CTLTYPE AS LONG CTLID AS LONG ITEMID AS LONG ITEMACTION AS L` |
| DECLARE | REGISTERHOTKEY | User32.inc(203): `DECLARE FUNCTION REGISTERHOTKEY LIB "USER32.DLL" ALIAS_ "REGISTERHOTKEY" (HWND A` | WIN32API.INC(6652): `DECLARE FUNCTION REGISTERHOTKEY LIB "USER32" ALIAS "REGISTERHOTKEY" (BYVAL HWND ` |
| DECLARE | UNREGISTERHOTKEY | User32.inc(232): `DECLARE FUNCTION UNREGISTERHOTKEY LIB "USER32.DLL" ALIAS_ "UNREGISTERHOTKEY" (HW` | WIN32API.INC(6653): `DECLARE FUNCTION UNREGISTERHOTKEY LIB "USER32" ALIAS "UNREGISTERHOTKEY" (BYVAL H` |
| DECLARE | GETMESSAGEPOS | User32.inc(102): `DECLARE FUNCTION GETMESSAGEPOS LIB "USER32.DLL" ALIAS_ "GETMESSAGEPOS" AS LONG` | WIN32API.INC(6675): `DECLARE FUNCTION GETMESSAGEPOS LIB "USER32" ALIAS "GETMESSAGEPOS" () AS LONG` |
| DECLARE | GETMESSAGETIME | User32.inc(108): `DECLARE FUNCTION GETMESSAGETIME LIB "USER32.DLL" ALIAS_ "GETMESSAGETIME" AS LONG` | WIN32API.INC(6676): `DECLARE FUNCTION GETMESSAGETIME LIB "USER32" ALIAS "GETMESSAGETIME" () AS LONG` |
| DECLARE | GETMESSAGEEXTRAINFO | User32.inc(96): `DECLARE FUNCTION GETMESSAGEEXTRAINFO LIB "USER32.DLL" ALIAS_ "GETMESSAGEEXTRAINF` | WIN32API.INC(6677): `DECLARE FUNCTION GETMESSAGEEXTRAINFO LIB "USER32" ALIAS "GETMESSAGEEXTRAINFO" ()` |
| DECLARE | DEFWINDOWPROC | rapidq2.inc(1042): `DECLARE FUNCTION DEFWINDOWPROC LIB "USER32" ALIAS "DEFWINDOWPROCA" (HWND AS LONG` | WIN32API.INC(6706): `DECLARE FUNCTION DEFWINDOWPROC LIB "USER32" ALIAS "DEFWINDOWPROCA" (BYVAL HWND A` |
| DECLARE | GETDOUBLECLICKTIME | User32.inc(60): `DECLARE FUNCTION GETDOUBLECLICKTIME LIB "USER32.DLL" ALIAS_ "GETDOUBLECLICKTIME"` | WIN32API.INC(6710): `DECLARE FUNCTION GETDOUBLECLICKTIME LIB "USER32" ALIAS "GETDOUBLECLICKTIME" () A` |
| DECLARE | CREATEWINDOWEX | rapidq2.inc(987): `DECLARE FUNCTION CREATEWINDOWEX LIB "USER32" ALIAS "CREATEWINDOWEXA" (DWEXSTYLE ` | WIN32API.INC(6719): `DECLARE FUNCTION CREATEWINDOWEX LIB "USER32" ALIAS "CREATEWINDOWEXA" (BYVAL DWEX` |
| DECLARE | SHOWWINDOW | rapidq2.inc(1017): `DECLARE FUNCTION SHOWWINDOW LIB "USER32" ALIAS "SHOWWINDOW" (HWND AS LONG,NCMDSH` | WIN32API.INC(6725): `DECLARE FUNCTION SHOWWINDOW LIB "USER32" ALIAS "SHOWWINDOW" (BYVAL HWND AS LONG,` |
| DECLARE | MOVEWINDOW | rapidq2.inc(993): `DECLARE FUNCTION MOVEWINDOW LIB "USER32" ALIAS "MOVEWINDOW" (HWND AS LONG,X AS L` | WIN32API.INC(6731): `DECLARE FUNCTION MOVEWINDOW LIB "USER32" ALIAS "MOVEWINDOW" (BYVAL HWND AS LONG,` |
| DECLARE | SETWINDOWPOS | rapidq2.inc(1029): `DECLARE SUB SETWINDOWPOS LIB "USER32" ALIAS "SETWINDOWPOS"_ (BYVAL HWND AS LONG,` | WIN32API.INC(6732): `DECLARE FUNCTION SETWINDOWPOS LIB "USER32" ALIAS "SETWINDOWPOS" (BYVAL HWND AS L` |
| DECLARE | GETWINDOWPLACEMENT | Form.inc(45): `PRIVATE DECLARE FUNCTION GETWINDOWPLACEMENT LIB "USER32" ALIAS "GETWINDOWPLACEME` | WIN32API.INC(6733): `DECLARE FUNCTION GETWINDOWPLACEMENT LIB "USER32" ALIAS "GETWINDOWPLACEMENT" (BYV` |
| DECLARE | SETWINDOWPLACEMENT | Form.inc(47): `PRIVATE DECLARE FUNCTION SETWINDOWPLACEMENT LIB "USER32" ALIAS "SETWINDOWPLACEME` | WIN32API.INC(6734): `DECLARE FUNCTION SETWINDOWPLACEMENT LIB "USER32" ALIAS "SETWINDOWPLACEMENT" (BYV` |
| DECLARE | GETDIALOGBASEUNITS | User32.inc(54): `DECLARE FUNCTION GETDIALOGBASEUNITS LIB "USER32.DLL" ALIAS_ "GETDIALOGBASEUNITS"` | WIN32API.INC(6800): `DECLARE FUNCTION GETDIALOGBASEUNITS LIB "USER32" ALIAS "GETDIALOGBASEUNITS" () A` |
| DECLARE | GETOPENCLIPBOARDWINDOW | User32.inc(114): `DECLARE FUNCTION GETOPENCLIPBOARDWINDOW LIB "USER32.DLL" ALIAS_ "GETOPENCLIPBOAR` | WIN32API.INC(6823): `DECLARE FUNCTION GETOPENCLIPBOARDWINDOW LIB "USER32" ALIAS "GETOPENCLIPBOARDWIND` |
| DECLARE | CHARTOOEM | conversion.inc(60): `DECLARE FUNCTION CHARTOOEM LIB "USER32" ALIAS "CHARTOOEMA" _ (BYVAL LPSZSRC AS S` | WIN32API.INC(6824): `DECLARE FUNCTION CHARTOOEM LIB "USER32" ALIAS "CHARTOOEMA" (BYVAL LPSZSRC AS STR` |
| DECLARE | OEMTOCHAR | conversion.inc(66): `DECLARE FUNCTION OEMTOCHAR LIB "USER32" ALIAS "OEMTOCHARA" _ (BYVAL LPSZSRC AS S` | WIN32API.INC(6825): `DECLARE FUNCTION OEMTOCHAR LIB "USER32" ALIAS "OEMTOCHARA" (BYVAL LPSZSRC AS STR` |
| DECLARE | SETFOCUS | rapidq2.inc(1010): `DECLARE FUNCTION SETFOCUS LIB "USER32" ALIAS "SETFOCUS" (HWND AS LONG) AS LONG` | WIN32API.INC(6841): `DECLARE FUNCTION SETFOCUS LIB "USER32" ALIAS "SETFOCUS" (BYVAL HWND AS LONG) AS ` |
| DECLARE | GETFOCUS | rapidq2.inc(994): `DECLARE FUNCTION GETFOCUS LIB "USER32" ALIAS "GETFOCUS"() AS LONG` | WIN32API.INC(6842): `DECLARE FUNCTION GETFOCUS LIB "USER32" ALIAS "GETFOCUS" () AS LONG` |
| DECLARE | GETACTIVEWINDOW | User32.inc(23): `DECLARE FUNCTION GETACTIVEWINDOW LIB "USER32.DLL" ALIAS_ "GETACTIVEWINDOW" AS LO` | WIN32API.INC(6843): `DECLARE FUNCTION GETACTIVEWINDOW LIB "USER32" ALIAS "GETACTIVEWINDOW" () AS LONG` |
| DECLARE | GETKBCODEPAGE | User32.inc(84): `DECLARE FUNCTION GETKBCODEPAGE LIB "USER32.DLL" ALIAS_ "GETKBCODEPAGE" AS LONG` | WIN32API.INC(6846): `DECLARE FUNCTION GETKBCODEPAGE LIB "USER32" ALIAS "GETKBCODEPAGE" () AS LONG` |
| DECLARE | MOUSE_EVENT | QFormSkin.inc(723): `DECLARE SUB MOUSE_EVENT LIB "USER32" ALIAS "MOUSE_EVENT" ( _ BYVAL DWFLAGS AS LO` | WIN32API.INC(6874): `DECLARE SUB MOUSE_EVENT LIB "USER32" ALIAS "MOUSE_EVENT" (BYVAL DWFLAGS AS LONG,` |
| DECLARE | GETINPUTSTATE | User32.inc(78): `DECLARE FUNCTION GETINPUTSTATE LIB "USER32.DLL" ALIAS_ "GETINPUTSTATE" AS LONG` | WIN32API.INC(6877): `DECLARE FUNCTION GETINPUTSTATE LIB "USER32" ALIAS "GETINPUTSTATE" () AS LONG` |
| DECLARE | SETCAPTURE | rapidq2.inc(1008): `DECLARE FUNCTION SETCAPTURE LIB "USER32" ALIAS "SETCAPTURE" (HWND AS LONG) AS LO` | WIN32API.INC(6880): `DECLARE FUNCTION SETCAPTURE LIB "USER32" ALIAS "SETCAPTURE" (BYVAL HWND AS LONG)` |
| DECLARE | GETMENU | rapidq2.inc(1603): `DECLARE FUNCTION GETMENU LIB "USER32" ALIAS "GETMENU" (HWND AS LONG) AS LONG` | WIN32API.INC(6972): `DECLARE FUNCTION GETMENU LIB "USER32" ALIAS "GETMENU" (BYVAL HWND AS LONG) AS LO` |
| DECLARE | MODIFYMENU | rapidq2.inc(1607): `DECLARE FUNCTION MODIFYMENU LIB "USER32" ALIAS "MODIFYMENUA" (HMENU AS LONG,UPOS` | WIN32API.INC(6990): `DECLARE FUNCTION MODIFYMENU LIB "USER32" ALIAS "MODIFYMENUA" (BYVAL HMENU AS LON` |
| DECLARE | GETMENUCHECKMARKDIMENSIONS | User32.inc(90): `DECLARE FUNCTION GETMENUCHECKMARKDIMENSIONS LIB "USER32.DLL" ALIAS_ "GETMENUCHEC` | WIN32API.INC(6994): `DECLARE FUNCTION GETMENUCHECKMARKDIMENSIONS LIB "USER32" ALIAS "GETMENUCHECKMARK` |
| DECLARE | DRAWICON | QFormSkin.inc(202): `DECLARE FUNCTION DRAWICON LIB "USER32" ALIAS "DRAWICON" (_ BYVAL HDC AS LONG, _ ` | WIN32API.INC(7004): `DECLARE FUNCTION DRAWICON LIB "USER32" ALIAS "DRAWICON" (BYVAL HDC AS LONG, BYVA` |
| DECLARE | DRAWTEXT | QFormSkin.inc(223): `DECLARE FUNCTION DRAWTEXT LIB "USER32" ALIAS "DRAWTEXTA" ( _ BYVAL HDC AS LONG, ` | WIN32API.INC(7023): `DECLARE FUNCTION DRAWTEXT LIB "USER32" ALIAS "DRAWTEXTA" (BYVAL HDC AS LONG, BYV` |
| DECLARE | SETACTIVEWINDOW | rapidq2.inc(1484): `DECLARE FUNCTION SETACTIVEWINDOW LIB "USER32" ALIAS "SETACTIVEWINDOW" (HWND AS I` | WIN32API.INC(7028): `DECLARE FUNCTION SETACTIVEWINDOW LIB "USER32" ALIAS "SETACTIVEWINDOW" (BYVAL HWN` |
| DECLARE | GETFOREGROUNDWINDOW | User32.inc(72): `DECLARE FUNCTION GETFOREGROUNDWINDOW LIB "USER32.DLL" ALIAS_ "GETFOREGROUNDWINDO` | WIN32API.INC(7029): `DECLARE FUNCTION GETFOREGROUNDWINDOW LIB "USER32" ALIAS "GETFOREGROUNDWINDOW" ()` |
| DECLARE | GETDC | rapidq2.inc(1482): `DECLARE FUNCTION GETDC LIB "USER32.DLL" ALIAS "GETDC"(BYVAL HWND AS LONG) AS LON` | WIN32API.INC(7033): `DECLARE FUNCTION GETDC LIB "USER32" ALIAS "GETDC" (BYVAL HWND AS LONG) AS LONG` |
| DECLARE | GETWINDOWDC | QFormSkin.inc(171): `DECLARE FUNCTION GETWINDOWDC LIB "USER32" ALIAS "GETWINDOWDC" _ (HWND AS LONG) A` | WIN32API.INC(7054): `DECLARE FUNCTION GETWINDOWDC LIB "USER32" ALIAS "GETWINDOWDC" (BYVAL HWND AS LON` |
| DECLARE | RELEASEDC | rapidq2.inc(1483): `DECLARE FUNCTION RELEASEDC LIB "USER32.DLL" ALIAS "RELEASEDC"(BYVAL HWND AS LONG` | WIN32API.INC(7055): `DECLARE FUNCTION RELEASEDC LIB "USER32" ALIAS "RELEASEDC" (BYVAL HWND AS LONG, B` |
| DECLARE | EXCLUDEUPDATERGN | QFormSkin.inc(239): `DECLARE FUNCTION EXCLUDEUPDATERGN LIB "USER32.DLL" ALIAS "EXCLUDEUPDATERGN" ( _ ` | WIN32API.INC(7061): `DECLARE FUNCTION EXCLUDEUPDATERGN LIB "USER32" ALIAS "EXCLUDEUPDATERGN" (BYVAL H` |
| DECLARE | SETPROP | rapidq2.inc(990): `DECLARE FUNCTION SETPROP LIB "USER32" ALIAS "SETPROPA" (HWND AS LONG,LPSTRING AS` | WIN32API.INC(7116): `DECLARE FUNCTION SETPROP LIB "USER32" ALIAS "SETPROPA" (BYVAL HWND AS LONG, BYVA` |
| DECLARE | GETPROP | rapidq2.inc(991): `DECLARE FUNCTION GETPROP LIB "USER32" ALIAS "GETPROPA" (HWND AS LONG,LPSTRING AS` | WIN32API.INC(7117): `DECLARE FUNCTION GETPROP LIB "USER32" ALIAS "GETPROPA" (BYVAL HWND AS LONG, BYVA` |
| DECLARE | SETWINDOWTEXT | rapidq2.inc(1013): `DECLARE FUNCTION SETWINDOWTEXT LIB "USER32" ALIAS "SETWINDOWTEXTA" (BYVAL HWND A` | WIN32API.INC(7120): `DECLARE FUNCTION SETWINDOWTEXT LIB "USER32" ALIAS "SETWINDOWTEXTA" (BYVAL HWND A` |
| DECLARE | GETWINDOWTEXT | rapidq2.inc(997): `DECLARE FUNCTION GETWINDOWTEXT LIB "USER32" ALIAS "GETWINDOWTEXTA" (BYVAL HWND A` | WIN32API.INC(7121): `DECLARE FUNCTION GETWINDOWTEXT LIB "USER32" ALIAS "GETWINDOWTEXTA" (BYVAL HWND A` |
| DECLARE | SETCURSOR | QFormSkin.inc(247): `DECLARE FUNCTION SETCURSOR LIB "USER32" ALIAS "SETCURSOR" (BYVAL HCURSOR AS LONG` | WIN32API.INC(7169): `DECLARE FUNCTION SETCURSOR LIB "USER32" ALIAS "SETCURSOR" (BYVAL HCURSOR AS LONG` |
| DECLARE | GETCURSOR | User32.inc(42): `DECLARE FUNCTION GETCURSOR LIB "USER32.DLL" ALIAS_ "GETCURSOR" AS LONG` | WIN32API.INC(7172): `DECLARE FUNCTION GETCURSOR LIB "USER32" ALIAS "GETCURSOR" () AS LONG` |
| DECLARE | GETSYSCOLOR | rapidq2.inc(1602): `DECLARE FUNCTION GETSYSCOLOR LIB "USER32" ALIAS "GETSYSCOLOR" (NINDEX AS LONG) A` | WIN32API.INC(7223): `DECLARE FUNCTION GETSYSCOLOR LIB "USER32" ALIAS "GETSYSCOLOR" (BYVAL NINDEX AS L` |
| DECLARE | SETRECT | QFormSkin.inc(146): `DECLARE FUNCTION SETRECT LIB "USER32" ALIAS "SETRECT" ( _ LPRECT AS RECT, _ BYVA` | WIN32API.INC(7230): `DECLARE FUNCTION SETRECT LIB "USER32" ALIAS "SETRECT" (LPRECT AS RECT, BYVAL X1 ` |
| DECLARE | GETWINDOWLONG | rapidq2.inc(1037): `DECLARE FUNCTION GETWINDOWLONG LIB "USER32" ALIAS "GETWINDOWLONGA" (HWND AS LONG` | WIN32API.INC(7244): `DECLARE FUNCTION GETWINDOWLONG LIB "USER32" ALIAS "GETWINDOWLONGA" (BYVAL HWND A` |
| DECLARE | SETWINDOWLONG | rapidq2.inc(1039): `DECLARE FUNCTION SETWINDOWLONG LIB "USER32" ALIAS "SETWINDOWLONGA" (HWND AS LONG` | WIN32API.INC(7245): `DECLARE FUNCTION SETWINDOWLONG LIB "USER32" ALIAS "SETWINDOWLONGA" (BYVAL HWND A` |
| DECLARE | SETCLASSLONG | rapidq2.inc(1009): `DECLARE FUNCTION SETCLASSLONG LIB "USER32" ALIAS "SETCLASSLONGA" (HWND AS LONG,N` | WIN32API.INC(7249): `DECLARE FUNCTION SETCLASSLONG LIB "USER32" ALIAS "SETCLASSLONGA" (BYVAL HWND AS ` |
| DECLARE | GETPARENT | rapidq2.inc(995): `DECLARE FUNCTION GETPARENT LIB "USER32" ALIAS "GETPARENT" (HWND AS LONG) AS LONG` | WIN32API.INC(7252): `DECLARE FUNCTION GETPARENT LIB "USER32" ALIAS "GETPARENT" (BYVAL HWND AS LONG) A` |
| DECLARE | SETPARENT | rapidq2.inc(1011): `DECLARE FUNCTION SETPARENT LIB "USER32" ALIAS "SETPARENT" (HWNDCHILD AS LONG,HWN` | WIN32API.INC(7253): `DECLARE FUNCTION SETPARENT LIB "USER32" ALIAS "SETPARENT" (BYVAL HWNDCHILD AS LO` |
| DECLARE | FINDWINDOW | User32.inc(17): `DECLARE FUNCTION FINDWINDOW LIB "USER32.DLL" ALIAS_ "FINDWINDOWA" (LPCLASSNAME A` | WIN32API.INC(7254): `DECLARE FUNCTION FINDWINDOW LIB "USER32" ALIAS "FINDWINDOWA" (BYVAL LPCLASSNAME ` |
| DECLARE | GETCLASSNAME | rapidq2.inc(989): `DECLARE FUNCTION GETCLASSNAME LIB "USER32" ALIAS "GETCLASSNAMEA" (HWND AS LONG, ` | WIN32API.INC(7256): `DECLARE FUNCTION GETCLASSNAME LIB "USER32" ALIAS "GETCLASSNAMEA" (BYVAL HWND AS ` |
| DECLARE | LOADCURSOR | QFormSkin.inc(249): `DECLARE FUNCTION LOADCURSOR LIB "USER32" ALIAS "LOADCURSORA" _ (BYVAL HINSTANCE ` | WIN32API.INC(7350): `DECLARE FUNCTION LOADCURSOR LIB "USER32" ALIAS "LOADCURSORA" (BYVAL HINSTANCE AS` |
| DECLARE | DESTROYICON | QFormSkin.inc(215): `DECLARE FUNCTION DESTROYICON LIB "USER32" ALIAS "DESTROYICON" ( _ BYVAL HICON AS` | WIN32API.INC(7381): `DECLARE FUNCTION DESTROYICON LIB "USER32" ALIAS "DESTROYICON" (BYVAL HICON AS LO` |
| CONST | LBS_STANDARD | Win32_constants.inc(138): `CONST LBS_STANDARD = &HA00003` | WIN32API.INC(7712): `PUBLIC CONST LBS_STANDARD = (LBS_NOTIFY OR LBS_SORT OR WS_VSCROLL OR WS_BORDER)` |
| DECLARE | DEFMDICHILDPROC | rapidq2.inc(988): `DECLARE FUNCTION DEFMDICHILDPROC LIB "USER32" ALIAS "DEFMDICHILDPROCA" (HWND AS ` | WIN32API.INC(7819): `DECLARE FUNCTION DEFMDICHILDPROC LIB "USER32" ALIAS "DEFMDICHILDPROCA" (BYVAL HW` |
| DECLARE | SYSTEMPARAMETERSINFO | rapidq2.inc(1485): `DECLARE FUNCTION SYSTEMPARAMETERSINFO LIB "USER32" ALIAS "SYSTEMPARAMETERSINFOA"` | WIN32API.INC(7959): `DECLARE FUNCTION SYSTEMPARAMETERSINFO LIB "USER32" ALIAS "SYSTEMPARAMETERSINFOA"` |
| DECLARE | DRAGQUERYFILE | rapidq2.inc(1052): `DECLARE FUNCTION DRAGQUERYFILE LIB "SHELL32" ALIAS "DRAGQUERYFILEA" (HDROP AS LO` | WIN32API.INC(14398): `DECLARE FUNCTION DRAGQUERYFILE LIB "SHELL32.DLL" ALIAS "DRAGQUERYFILEA" (BYVAL H` |
| DECLARE | DRAGQUERYPOINT | rapidq2.inc(1053): `DECLARE FUNCTION DRAGQUERYPOINT LIB "SHELL32" ALIAS "DRAGQUERYPOINT" (HDROP AS L` | WIN32API.INC(14399): `DECLARE FUNCTION DRAGQUERYPOINT LIB "SHELL32.DLL" ALIAS "DRAGQUERYPOINT" (BYVAL ` |
| DECLARE | DRAGFINISH | rapidq2.inc(1051): `DECLARE SUB DRAGFINISH LIB "SHELL32" ALIAS "DRAGFINISH" (HDROP AS LONG)` | WIN32API.INC(14400): `DECLARE SUB DRAGFINISH LIB "SHELL32.DLL" ALIAS "DRAGFINISH" (BYVAL HDROP AS LONG` |
| DECLARE | DRAGACCEPTFILES | rapidq2.inc(1050): `DECLARE SUB DRAGACCEPTFILES LIB "SHELL32" ALIAS "DRAGACCEPTFILES" (HWND AS LONG,` | WIN32API.INC(14401): `DECLARE SUB DRAGACCEPTFILES LIB "SHELL32.DLL" ALIAS "DRAGACCEPTFILES" (BYVAL HWN` |
| DECLARE | FINDEXECUTABLE | Shell32.inc(14): `DECLARE FUNCTION FINDEXECUTABLE LIB "SHELL32.DLL" ALIAS_ "FINDEXECUTABLEA" (LPFI` | WIN32API.INC(14403): `DECLARE FUNCTION FINDEXECUTABLE LIB "SHELL32.DLL" ALIAS "FINDEXECUTABLEA" (BYVAL` |
| TYPE | APPBARDATA | QFormLocale.inc(94): `TYPE APPBARDATA CBSIZE AS LONG HWND AS LONG UCALLBACKMESSAGE AS LONG UEDGE AS LO` | WIN32API.INC(14449): `TYPE APPBARDATA CBSIZE AS LONG HWND AS LONG UCALLBACKMESSAGE AS LONG UEDGE AS LO` |
| DECLARE | EXTRACTICONEX | QFormSkin.inc(196): `DECLARE FUNCTION EXTRACTICONEX LIB "SHELL32.DLL" ALIAS "EXTRACTICONEXA" ( _ BYVA` | WIN32API.INC(14467): `DECLARE FUNCTION EXTRACTICONEX LIB "SHELL32.DLL" ALIAS "EXTRACTICONEXA" (BYVAL L` |
| DECLARE | GETVERSIONEX | rapidq2.inc(2067): `DECLARE FUNCTION GETVERSIONEX LIB "KERNEL32.DLL" ALIAS "GETVERSIONEXA" (LPVERSIO` | WIN32API.INC(14939): `DECLARE FUNCTION GETVERSIONEX LIB "KERNEL32" ALIAS "GETVERSIONEXA" (BYVAL LPVERS` |
| TYPE | OPENFILENAME | rapidq2.inc(1663): `TYPE OPENFILENAME LSTRUCTSIZE AS DWORD HWNDOWNER AS LONG HINSTANCE AS LONG LPSTR` | WIN32API.INC(14970): `TYPE OPENFILENAME LSTRUCTSIZE AS LONG HWNDOWNER AS LONG HINSTANCE AS LONG LPSTRF` |
| DECLARE | GETOPENFILENAME | rapidq2.inc(1699): `DECLARE FUNCTION GETOPENFILENAME LIB "COMDLG32" ALIAS "GETOPENFILENAMEA" (POPENF` | WIN32API.INC(14993): `DECLARE FUNCTION GETOPENFILENAME LIB "COMDLG32.DLL" ALIAS "GETOPENFILENAMEA" (PO` |
| DECLARE | GETSAVEFILENAME | rapidq2.inc(1698): `DECLARE FUNCTION GETSAVEFILENAME LIB "COMDLG32" ALIAS "GETSAVEFILENAMEA" (POPENF` | WIN32API.INC(14995): `DECLARE FUNCTION GETSAVEFILENAME LIB "COMDLG32.DLL" ALIAS "GETSAVEFILENAMEA" (PO` |
| TYPE | NM_LISTVIEW | CommCtrl.inc(962): `TYPE NM_LISTVIEW HDR AS LONG IITEM AS LONG ISUBITEM AS LONG UNEWSTATE AS LONG UO` | WIN32API.INC(15040): `TYPE NM_LISTVIEW NMHDR HDR INTEGER IITEM INTEGER ISUBITEM INTEGER UNEWSTATE INTE` |
| TYPE | CHOOSECOLOR | rapidq2.inc(1610): `TYPE CHOOSECOLOR LSTRUCTSIZE AS LONG HWNDOWNER AS LONG HINSTANCE AS LONG RGBRESU` | WIN32API.INC(15069): `TYPE CHOOSECOLOR LSTRUCTSIZE AS LONG HWNDOWNER AS LONG HINSTANCE AS LONG RGBRESU` |
| DECLARE | READFILEEX | rapidq2.inc(2045): `DECLARE FUNCTION READFILEEX LIB "KERNEL32" ALIAS "READFILEEX"_ (BYVAL HFILE AS L` | WIN32API.INC(15369): `DECLARE FUNCTION READFILEEX LIB "KERNEL32" ALIAS "READFILEEX" (BYVAL HFILE AS LO` |
| DECLARE | CALLWINDOWPROC | rapidq2.inc(1019): `DECLARE FUNCTION CALLWINDOWPROC LIB "USER32.DLL" ALIAS "CALLWINDOWPROCA" (LPPREV` | WIN32API.INC(15448): `DECLARE FUNCTION CALLWINDOWPROC LIB "USER32" ALIAS "CALLWINDOWPROCA" (BYVAL LPPR` |
| DECLARE | COPYIMAGE | QFormSkin.inc(217): `DECLARE FUNCTION COPYIMAGE LIB "USER32.DLL" ALIAS "COPYIMAGE" ( _ BYVAL HANDLE A` | WIN32API.INC(15456): `DECLARE FUNCTION COPYIMAGE LIB "USER32" ALIAS "COPYIMAGE" (BYVAL HANDLE AS LONG,` |
| DECLARE | DRAWICONEX | rapidq2.inc(1477): `DECLARE FUNCTION DRAWICONEX LIB "USER32" ALIAS "DRAWICONEX" (HDC AS LONG,XLEFT A` | WIN32API.INC(15468): `DECLARE FUNCTION DRAWICONEX LIB "USER32" ALIAS "DRAWICONEX" (BYVAL HDC AS LONG, ` |
| DECLARE | ENUMCHILDWINDOWS | rapidq2.inc(986): `DECLARE FUNCTION ENUMCHILDWINDOWS LIB "USER32" ALIAS "ENUMCHILDWINDOWS" (HWNDPAR` | WIN32API.INC(15480): `DECLARE FUNCTION ENUMCHILDWINDOWS LIB "USER32" ALIAS "ENUMCHILDWINDOWS" (BYVAL H` |
| TYPE | MENUITEMINFO | rapidq2.inc(1587): `TYPE MENUITEMINFO CBSIZE AS LONG FMASK AS LONG FTYPE AS LONG FSTATE AS LONG WID ` | WIN32API.INC(15494): `TYPE MENUITEMINFO CBSIZE AS LONG FMASK AS LONG FTYPE AS LONG FSTATE AS LONG WID ` |
| DECLARE | LOADCURSORFROMFILE | WFunctions.inc(38): `DECLARE FUNCTION LOADCURSORFROMFILE LIB "USER32" ALIAS "LOADCURSORFROMFILEA" _ (` | WIN32API.INC(15528): `DECLARE FUNCTION LOADCURSORFROMFILE LIB "USER32" ALIAS "LOADCURSORFROMFILEA" (BY` |
| DECLARE | LOADIMAGE | rapidq2.inc(1478): `DECLARE FUNCTION LOADIMAGE LIB "USER32" ALIAS "LOADIMAGEA" (HINST AS LONG,LPSZ A` | WIN32API.INC(15529): `DECLARE FUNCTION LOADIMAGE LIB "USER32" ALIAS "LOADIMAGEA" (BYVAL HINST AS LONG,` |
| TYPE | WNDCLASSEX | rapidq2.inc(930): `TYPE WNDCLASSEX CBSIZE AS LONG STYLE AS LONG LPFNWNDPROC AS LONG CBCLSEXTRA AS L` | WIN32API.INC(15553): `TYPE WNDCLASSEX CBSIZE AS LONG STYLE AS LONG LPFNWNDPROC AS LONG CBCLSEXTRA AS L` |
| DECLARE | REGISTERCLASSEX | rapidq2.inc(985): `DECLARE FUNCTION REGISTERCLASSEX LIB "USER32" ALIAS "REGISTERCLASSEXA" (PCWNDCLA` | WIN32API.INC(15568): `DECLARE FUNCTION REGISTERCLASSEX LIB "USER32" ALIAS "REGISTERCLASSEXA" (PCWNDCLA` |
| TYPE | POINTS | QFormSkin.inc(137): `TYPE POINTS X AS INTEGER Y AS INTEGER END TYPE` | WINDOWS.INC(80): `TYPE POINTS X AS SHORT Y AS SHORT END TYPE` |
| TYPE | MSG | WIN32API.INC(107): `TYPE MSG HWND AS LONG MESSAGE AS LONG WPARAM AS LONG LPARAM AS LONG TIME AS LONG` | WINDOWS.INC(85): `TYPE MSG HWND AS LONG MESSAGE AS LONG WPARAM AS LONG LPARAM AS LONG TIME AS LONG` |
| TYPE | STARTUPINFO | WIN32API.INC(116): `TYPE STARTUPINFO CB AS LONG LPRESERVED AS STRING LPDESKTOP AS STRING LPTITLE AS ` | WINDOWS.INC(95): `TYPE STARTUPINFO CB AS LONG LPRESERVED AS LONG LPDESKTOP AS LONG LPTITLE AS LONG` |
| TYPE | LDT_ENTRY | WIN32API.INC(241): `TYPE LDT_ENTRY LIMITLOW AS INTEGER BASELOW AS INTEGER HIGHWORD AS LONG END TYPE` | WINDOWS.INC(222): `TYPE LDT_ENTRY LIMITLOW AS WORD BASELOW AS WORD HIGHWORD AS LONG END TYPE` |
| TYPE | LARGE_INTEGER | rapidq2.inc(872): `TYPE LARGE_INTEGER LOWPART AS DWORD HIGHPART AS DWORD END TYPE` | WINDOWS.INC(240): `TYPE LARGE_INTEGER LOWPART AS LONG HIGHPART AS LONG END TYPE` |
| TYPE | SECURITY_QUALITY_OF_SERVICE | WIN32API.INC(258): `TYPE SECURITY_QUALITY_OF_SERVICE LENGTH AS LONG IMPERSONATIONLEVEL AS INTEGER CO` | WINDOWS.INC(251): `TYPE SECURITY_QUALITY_OF_SERVICE LENGTH AS LONG IMPERSONATIONLEVEL AS WORD CONTE` |
| TYPE | OVERLAPPED | rapidq2.inc(1813): `TYPE OVERLAPPED INTERNAL AS LONG INTERNALHIGH AS LONG OFFSET AS DWORD OFFSETHIGH` | WINDOWS.INC(450): `TYPE OVERLAPPED INTERNAL AS LONG INTERNALHIGH AS LONG OFFSET AS LONG OFFSETHIGH ` |
| TYPE | COMMPROP | WIN32API.INC(572): `TYPE COMMPROP WPACKETLENGTH AS INTEGER WPACKETVERSION AS INTEGER DWSERVICEMASK A` | WINDOWS.INC(565): `TYPE COMMPROP WPACKETLENGTH AS WORD WPACKETVERSION AS WORD DWSERVICEMASK AS LONG` |
| TYPE | COMSTAT | rapidq2.inc(1784): `TYPE COMSTAT COMSTATFLAGS AS DWORD CBINQUE AS DWORD CBOUTQUE AS DWORD END TYPE` | WINDOWS.INC(600): `TYPE COMSTAT FBITFIELDS AS LONG CBINQUE AS LONG CBOUTQUE AS LONG END TYPE` |
| TYPE | DCB | rapidq2.inc(1750): `TYPE DCB DCBLENGTH AS DWORD BAUDRATE AS DWORD DCBFLAGS AS DWORD WRESERVED AS WOR` | WINDOWS.INC(658): `TYPE DCB DCBLENGTH AS LONG BAUDRATE AS LONG FBITFIELDS AS LONG WRESERVED AS WORD` |
| TYPE | COMMTIMEOUTS | rapidq2.inc(1738): `TYPE COMMTIMEOUTS READINTERVALTIMEOUT AS DWORD READTOTALTIMEOUTMULTIPLIER AS DWO` | WINDOWS.INC(693): `TYPE COMMTIMEOUTS READINTERVALTIMEOUT AS LONG READTOTALTIMEOUTMULTIPLIER AS LONG` |
| TYPE | SYSTEM_INFO | WIN32API.INC(707): `TYPE SYSTEM_INFO DWOEMID AS LONG DWPAGESIZE AS LONG LPMINIMUMAPPLICATIONADDRESS ` | WINDOWS.INC(701): `TYPE SYSTEM_INFO DWOEMID AS LONG DWPAGESIZE AS LONG LPMINIMUMAPPLICATIONADDRESS ` |
| TYPE | LUID_AND_ATTRIBUTES | rapidq2.inc(2179): `TYPE LUID_AND_ATTRIBUTES LOWPART AS LONG HIGHTPART AS LONG ATTRIBUTES AS LONG EN` | WINDOWS.INC(1070): `TYPE LUID_AND_ATTRIBUTES PLUID AS LUID ATTRIBUTES AS LONG END TYPE` |
| TYPE | ACL | WIN32API.INC(1130): `TYPE ACL ACLREVISION AS BYTE SBZ1 AS BYTE ACLSIZE AS INTEGER ACECOUNT AS INTEGER` | WINDOWS.INC(1105): `TYPE ACL ACLREVISION AS BYTE SBZ1 AS BYTE ACLSIZE AS WORD ACECOUNT AS WORD SBZ2 ` |
| TYPE | PRIVILEGE_SET | WIN32API.INC(1435): `TYPE PRIVILEGE_SET PRIVILEGECOUNT AS LONG CONTROL AS LONG PRIVILEGE(ANYSIZE_ARRA` | WINDOWS.INC(1410): `TYPE PRIVILEGE_SET PRIVILEGECOUNT AS LONG CONTROL AS LONG LPPRIVILEGEARRAY AS LO` |
| TYPE | CREATE_PROCESS_DEBUG_INFO | WIN32API.INC(1577): `TYPE CREATE_PROCESS_DEBUG_INFO HFILE AS LONG HPROCESS AS LONG HTHREAD AS LONG LP` | WINDOWS.INC(1556): `TYPE CREATE_PROCESS_DEBUG_INFO HFILE AS LONG HPROCESS AS LONG HTHREAD AS LONG LP` |
| TYPE | LOAD_DLL_DEBUG_INFO | WIN32API.INC(1598): `TYPE LOAD_DLL_DEBUG_INFO HFILE AS LONG LPBASEOFDLL AS LONG DWDEBUGINFOFILEOFFSET` | WINDOWS.INC(1577): `TYPE LOAD_DLL_DEBUG_INFO HFILE AS LONG LPBASEOFDLL AS LONG DWDEBUGINFOFILEOFFSET` |
| TYPE | OUTPUT_DEBUG_STRING_INFO | WIN32API.INC(1611): `TYPE OUTPUT_DEBUG_STRING_INFO LPDEBUGSTRINGDATA AS STRING FUNICODE AS INTEGER ND` | WINDOWS.INC(1590): `TYPE OUTPUT_DEBUG_STRING_INFO LPDEBUGSTRINGDATA AS STRING FUNICODE AS WORD NDEBU` |
| TYPE | OFSTRUCT | WIN32API.INC(1809): `TYPE OFSTRUCT CBYTES AS BYTE FFIXEDDISK AS BYTE NERRCODE AS INTEGER RESERVED1 AS` | WINDOWS.INC(1788): `TYPE OFSTRUCT CBYTES AS BYTE FFIXEDDISK AS BYTE NERRCODE AS WORD RESERVED1 AS WO` |
| DECLARE | GETMODULEHANDLE | createWind.inc(26): `DECLARE FUNCTION GETMODULEHANDLE LIB "KERNEL32" ALIAS "GETMODULEHANDLEA" _ (MODU` | WINDOWS.INC(1803): `DECLARE FUNCTION GETMODULEHANDLE LIB "KERNEL32" ALIAS "GETMODULEHANDLEA" (BYVAL ` |
| DECLARE | GETCOMMANDLINE | Kernel32.inc(41): `DECLARE FUNCTION GETCOMMANDLINE LIB "KERNEL32.DLL" ALIAS_ "GETCOMMANDLINEA" AS S` | WINDOWS.INC(1812): `DECLARE FUNCTION GETCOMMANDLINE LIB "KERNEL32" ALIAS "GETCOMMANDLINEA" () AS STR` |
| DECLARE | FREELIBRARY | createWind.inc(5): `DECLARE FUNCTION FREELIBRARY LIB "KERNEL32" ALIAS "FREELIBRARY" _ (HINST AS LONG` | WINDOWS.INC(1823): `DECLARE FUNCTION FREELIBRARY LIB "KERNEL32" ALIAS "FREELIBRARY" (BYVAL HLIBMODUL` |
| TYPE | CRITICAL_SECTION | WIN32API.INC(1851): `TYPE CRITICAL_SECTION DUMMY AS LONG END TYPE` | WINDOWS.INC(1830): `TYPE CRITICAL_SECTION DEBUGINFO AS LONG LOCKCOUNT AS LONG RECURSIONCOUNT AS LONG` |
| DECLARE | GETVERSION | Kernel32.inc(177): `DECLARE FUNCTION GETVERSION LIB "KERNEL32.DLL" ALIAS_ "GETVERSION" AS DWORD` | WINDOWS.INC(1864): `DECLARE FUNCTION GETVERSION LIB "KERNEL32" ALIAS "GETVERSION" () AS LONG` |
| DECLARE | GETLOGICALDRIVES | Kernel32.inc(114): `DECLARE FUNCTION GETLOGICALDRIVES LIB "KERNEL32.DLL" ALIAS_ "GETLOGICALDRIVES" A` | WINDOWS.INC(1874): `DECLARE FUNCTION GETLOGICALDRIVES LIB "KERNEL32" ALIAS "GETLOGICALDRIVES" () AS ` |
| DECLARE | WRITEFILE | rapidq2.inc(1989): `DECLARE FUNCTION WRITEFILE LIB "KERNEL32" ALIAS "WRITEFILE"_ (HFILE AS LONG, _ L` | WINDOWS.INC(1902): `DECLARE FUNCTION WRITEFILE LIB "KERNEL32" ALIAS "WRITEFILE" (BYVAL HFILE AS LONG` |
| DECLARE | READFILE | rapidq2.inc(2019): `DECLARE FUNCTION READFILE LIB "KERNEL32" ALIAS "READFILE"_ (HFILE AS LONG, _ BYR` | WINDOWS.INC(1903): `DECLARE FUNCTION READFILE LIB "KERNEL32" ALIAS "READFILE" (BYVAL HFILE AS LONG, ` |
| DECLARE | CLOSEHANDLE | rapidq2.inc(2038): `DECLARE FUNCTION CLOSEHANDLE LIB "KERNEL32" ALIAS "CLOSEHANDLE" _ (HOBJECT AS LO` | WINDOWS.INC(1911): `DECLARE FUNCTION CLOSEHANDLE LIB "KERNEL32" ALIAS "CLOSEHANDLE" (BYVAL HOBJECT A` |
| DECLARE | GETDRIVETYPE | rapidq2.inc(1505): `DECLARE FUNCTION GETDRIVETYPE LIB "KERNEL32" ALIAS "GETDRIVETYPEA" (NDRIVE AS ST` | WINDOWS.INC(1914): `DECLARE FUNCTION GETDRIVETYPE LIB "KERNEL32" ALIAS "GETDRIVETYPEA" (BYVAL NDRIVE` |
| DECLARE | GETCURRENTTHREAD | Kernel32.inc(82): `DECLARE FUNCTION GETCURRENTTHREAD LIB "KERNEL32.DLL" ALIAS_ "GETCURRENTTHREAD" A` | WINDOWS.INC(1986): `DECLARE FUNCTION GETCURRENTTHREAD LIB "KERNEL32" ALIAS "GETCURRENTTHREAD" () AS ` |
| DECLARE | GETCURRENTPROCESS | rapidq2.inc(1502): `DECLARE FUNCTION GETCURRENTPROCESS LIB "KERNEL32" ALIAS "GETCURRENTPROCESS"() AS` | WINDOWS.INC(1987): `DECLARE FUNCTION GETCURRENTPROCESS LIB "KERNEL32" ALIAS "GETCURRENTPROCESS" () A` |
| DECLARE | HEAPREALLOC | Memory.inc(22): `DECLARE FUNCTION HEAPREALLOC LIB "KERNEL32" ALIAS "HEAPREALLOC" (BYVAL HHEAP AS ` | WINDOWS.INC(1998): `DECLARE FUNCTION HEAPREALLOC LIB "KERNEL32" ALIAS "HEAPREALLOC" (BYVAL HHEAP AS ` |
| DECLARE | HEAPFREE | Memory.inc(23): `DECLARE FUNCTION HEAPFREE LIB "KERNEL32" ALIAS "HEAPFREE" (BYVAL HHEAP AS LONG, ` | WINDOWS.INC(1999): `DECLARE FUNCTION HEAPFREE LIB "KERNEL32" ALIAS "HEAPFREE" (BYVAL HHEAP AS LONG, ` |
| DECLARE | HEAPSIZE | Memory.inc(24): `DECLARE FUNCTION HEAPSIZE LIB "KERNEL32" ALIAS "HEAPSIZE" (BYVAL HHEAP AS LONG, ` | WINDOWS.INC(2000): `DECLARE FUNCTION HEAPSIZE LIB "KERNEL32" ALIAS "HEAPSIZE" (BYVAL HHEAP AS LONG, ` |
| DECLARE | GETPROCESSHEAP | Kernel32.inc(126): `DECLARE FUNCTION GETPROCESSHEAP LIB "KERNEL32.DLL" ALIAS_ "GETPROCESSHEAP" AS LO` | WINDOWS.INC(2001): `DECLARE FUNCTION GETPROCESSHEAP LIB "KERNEL32" ALIAS "GETPROCESSHEAP" () AS LONG` |
| DECLARE | OPENPROCESS | RQProcess.inc(66): `DECLARE FUNCTION OPENPROCESS LIB "KERNEL32" ALIAS "OPENPROCESS" _ (DESIREDACCESS` | WINDOWS.INC(2003): `DECLARE FUNCTION OPENPROCESS LIB "KERNEL32" ALIAS "OPENPROCESS" (BYVAL DWDESIRED` |
| DECLARE | GETCURRENTPROCESSID | Kernel32.inc(76): `DECLARE FUNCTION GETCURRENTPROCESSID LIB "KERNEL32.DLL" ALIAS_ "GETCURRENTPROCES` | WINDOWS.INC(2004): `DECLARE FUNCTION GETCURRENTPROCESSID LIB "KERNEL32" ALIAS "GETCURRENTPROCESSID" ` |
| DECLARE | EXITPROCESS | Kernel32.inc, поднято(35): `DECLARE FUNCTION EXITPROCESS LIB "KERNEL32.DLL" ALIAS_ "EXITPROCESS" (UEXITCODE ` | WINDOWS.INC(2005): `DECLARE SUB EXITPROCESS LIB "KERNEL32" ALIAS "EXITPROCESS" (BYVAL UEXITCODE AS L` |
| DECLARE | TERMINATEPROCESS | RQProcess.inc(74): `DECLARE FUNCTION TERMINATEPROCESS LIB "KERNEL32" ALIAS "TERMINATEPROCESS" _ ( HP` | WINDOWS.INC(2006): `DECLARE FUNCTION TERMINATEPROCESS LIB "KERNEL32" ALIAS "TERMINATEPROCESS" (BYVAL` |
| DECLARE | GETEXITCODEPROCESS | RQProcess.inc(79): `DECLARE FUNCTION GETEXITCODEPROCESS LIB "KERNEL32" ALIAS "GETEXITCODEPROCESS" _ ` | WINDOWS.INC(2007): `DECLARE FUNCTION GETEXITCODEPROCESS LIB "KERNEL32" ALIAS "GETEXITCODEPROCESS" (B` |
| DECLARE | GETLASTERROR | rapidq2.inc(1894): `DECLARE FUNCTION GETLASTERROR LIB "KERNEL32" ALIAS "GETLASTERROR" () AS DWORD` | WINDOWS.INC(2009): `DECLARE FUNCTION GETLASTERROR LIB "KERNEL32" ALIAS "GETLASTERROR" () AS LONG` |
| DECLARE | GETPRIVATEPROFILESTRING | WIN32API.INC(2051): `DECLARE FUNCTION GETPRIVATEPROFILESTRING LIB "KERNEL32" ALIAS "GETPRIVATEPROFILE` | WINDOWS.INC(2085): `DECLARE FUNCTION GETPRIVATEPROFILESTRING LIB "KERNEL32" ALIAS "GETPRIVATEPROFILE` |
| DECLARE | WRITEPRIVATEPROFILESTRING | WIN32API.INC(2053): `DECLARE FUNCTION WRITEPRIVATEPROFILESTRING LIB "KERNEL32" ALIAS "WRITEPRIVATEPRO` | WINDOWS.INC(2087): `DECLARE FUNCTION WRITEPRIVATEPROFILESTRING LIB "KERNEL32" ALIAS "WRITEPRIVATEPRO` |
| DECLARE | GETPRIVATEPROFILESECTION | WIN32API.INC(2055): `DECLARE FUNCTION GETPRIVATEPROFILESECTION LIB "KERNEL32" ALIAS "GETPRIVATEPROFIL` | WINDOWS.INC(2089): `DECLARE FUNCTION GETPRIVATEPROFILESECTION LIB "KERNEL32" ALIAS "GETPRIVATEPROFIL` |
| DECLARE | GETWINDOWSDIRECTORY | Kernel32.inc, поднято(213): `DECLARE FUNCTION GETWINDOWSDIRECTORY LIB "KERNEL32.DLL" ALIAS_ "GETWINDOWSDIRECT` | WINDOWS.INC(2092): `DECLARE FUNCTION GETWINDOWSDIRECTORY LIB "KERNEL32" ALIAS "GETWINDOWSDIRECTORYA"` |
| DECLARE | GETSYSTEMDIRECTORY | WIN32API.INC(2059): `DECLARE FUNCTION GETSYSTEMDIRECTORY LIB "KERNEL32" ALIAS "GETSYSTEMDIRECTORYA" (` | WINDOWS.INC(2093): `DECLARE FUNCTION GETSYSTEMDIRECTORY LIB "KERNEL32" ALIAS "GETSYSTEMDIRECTORYA" (` |
| DECLARE | GETTEMPPATH | Kernel32.inc, поднято(148): `DECLARE FUNCTION GETTEMPPATH LIB "KERNEL32.DLL" ALIAS_ "GETTEMPPATHA" (NBUFFERLE` | WINDOWS.INC(2094): `DECLARE FUNCTION GETTEMPPATH LIB "KERNEL32" ALIAS "GETTEMPPATHA" (BYVAL NBUFFERL` |
| DECLARE | GETCURRENTDIRECTORY | WIN32API.INC(2062): `DECLARE FUNCTION GETCURRENTDIRECTORY LIB "KERNEL32" ALIAS "GETCURRENTDIRECTORY" ` | WINDOWS.INC(2096): `DECLARE FUNCTION GETCURRENTDIRECTORY LIB "KERNEL32" ALIAS "GETCURRENTDIRECTORY" ` |
| DECLARE | GETDISKFREESPACE | Kernel32.inc, поднято(94): `DECLARE FUNCTION GETDISKFREESPACE LIB "KERNEL32.DLL" ALIAS_ "GETDISKFREESPACEA" ` | WINDOWS.INC(2097): `DECLARE FUNCTION GETDISKFREESPACE LIB "KERNEL32" ALIAS "GETDISKFREESPACEA" (BYVA` |
| DECLARE | CREATEDIRECTORY | Files.inc(34): `DECLARE FUNCTION CREATEDIRECTORY LIB "KERNEL32" ALIAS "CREATEDIRECTORYA" _ (BYVA` | WINDOWS.INC(2099): `DECLARE FUNCTION CREATEDIRECTORY LIB "KERNEL32" ALIAS "CREATEDIRECTORYA" (BYVAL ` |
| DECLARE | GETFULLPATHNAME | WIN32API.INC(2067): `DECLARE FUNCTION GETFULLPATHNAME LIB "KERNEL32" ALIAS "GETFULLPATHNAMEA" (BYVAL ` | WINDOWS.INC(2102): `DECLARE FUNCTION GETFULLPATHNAME LIB "KERNEL32" ALIAS "GETFULLPATHNAMEA" (BYVAL ` |
| DECLARE | SETFILEATTRIBUTES | Files.inc(31): `DECLARE FUNCTION SETFILEATTRIBUTES LIB "KERNEL32" ALIAS "SETFILEATTRIBUTESA"_ (B` | WINDOWS.INC(2113): `DECLARE FUNCTION SETFILEATTRIBUTES LIB "KERNEL32" ALIAS "SETFILEATTRIBUTESA" (BY` |
| DECLARE | GETFILEATTRIBUTES | Files.inc(29): `DECLARE FUNCTION GETFILEATTRIBUTES LIB "KERNEL32" ALIAS "GETFILEATTRIBUTESA"_ (B` | WINDOWS.INC(2114): `DECLARE FUNCTION GETFILEATTRIBUTES LIB "KERNEL32" ALIAS "GETFILEATTRIBUTESA" (BY` |
| DECLARE | DELETEFILE | Kernel32.inc(26): `DECLARE FUNCTION DELETEFILE LIB "KERNEL32.DLL" ALIAS_ "DELETEFILEA" (LPFILENAME ` | WINDOWS.INC(2115): `DECLARE FUNCTION DELETEFILE LIB "KERNEL32" ALIAS "DELETEFILEA" (BYVAL LPFILENAME` |
| DECLARE | COPYFILE | Kernel32.inc(16): `DECLARE FUNCTION COPYFILE LIB "KERNEL32.DLL" ALIAS_ "COPYFILEA" (LPEXISTINGFILEN` | WINDOWS.INC(2119): `DECLARE FUNCTION COPYFILE LIB "KERNEL32" ALIAS "COPYFILEA" (BYVAL LPEXISTINGFILE` |
| TYPE | EVENTLOGRECORD | WIN32API.INC(2092): `TYPE EVENTLOGRECORD LENGTH AS LONG RESERVED AS LONG RECORDNUMBER AS LONG TIMEGEN` | WINDOWS.INC(2127): `TYPE EVENTLOGRECORD LENGTH AS LONG RESERVED AS LONG RECORDNUMBER AS LONG TIMEGEN` |
| DECLARE | GETVOLUMEINFORMATION | WIN32API.INC(2117): `DECLARE FUNCTION GETVOLUMEINFORMATION LIB "KERNEL32" ALIAS "GETVOLUMEINFORMATION` | WINDOWS.INC(2152): `DECLARE FUNCTION GETVOLUMEINFORMATION LIB "KERNEL32" ALIAS "GETVOLUMEINFORMATION` |
| $DEFINE | TOKENUSER | WIN32API.INC(2131): `PUBLIC CONST TOKENUSER = 1` | WINDOWS.INC(2166): `= 1` |
| $DEFINE | TOKENGROUPS | WIN32API.INC(2132): `PUBLIC CONST TOKENGROUPS = 2` | WINDOWS.INC(2167): `= 2` |
| $DEFINE | TOKENPRIVILEGES | WIN32API.INC(2133): `PUBLIC CONST TOKENPRIVILEGES = 3` | WINDOWS.INC(2168): `= 3` |
| $DEFINE | TOKENOWNER | WIN32API.INC(2134): `PUBLIC CONST TOKENOWNER = 4` | WINDOWS.INC(2169): `= 4` |
| $DEFINE | TOKENPRIMARYGROUP | WIN32API.INC(2135): `PUBLIC CONST TOKENPRIMARYGROUP = 5` | WINDOWS.INC(2170): `= 5` |
| $DEFINE | TOKENDEFAULTDACL | WIN32API.INC(2136): `PUBLIC CONST TOKENDEFAULTDACL = 6` | WINDOWS.INC(2171): `= 6` |
| $DEFINE | TOKENSOURCE | WIN32API.INC(2137): `PUBLIC CONST TOKENSOURCE = 7` | WINDOWS.INC(2172): `= 7` |
| $DEFINE | TOKENTYPE | WIN32API.INC(2138): `PUBLIC CONST TOKENTYPE = 8` | WINDOWS.INC(2173): `= 8` |
| $DEFINE | TOKENIMPERSONATIONLEVEL | WIN32API.INC(2139): `PUBLIC CONST TOKENIMPERSONATIONLEVEL = 9` | WINDOWS.INC(2174): `= 9` |
| $DEFINE | TOKENSTATISTICS | WIN32API.INC(2140): `PUBLIC CONST TOKENSTATISTICS = 10` | WINDOWS.INC(2175): `= 10` |
| DECLARE | OPENPROCESSTOKEN | rapidq2.inc(2197): `DECLARE FUNCTION OPENPROCESSTOKEN LIB "ADVAPI32" ALIAS "OPENPROCESSTOKEN" _ (PRO` | WINDOWS.INC(2208): `DECLARE FUNCTION OPENPROCESSTOKEN LIB "ADVAPI32.DLL" ALIAS "OPENPROCESSTOKEN" (B` |
| DECLARE | ADJUSTTOKENPRIVILEGES | rapidq2.inc(2207): `DECLARE FUNCTION ADJUSTTOKENPRIVILEGES LIB "ADVAPI32" ALIAS "ADJUSTTOKENPRIVILEG` | WINDOWS.INC(2212): `DECLARE FUNCTION ADJUSTTOKENPRIVILEGES LIB "ADVAPI32.DLL" ALIAS "ADJUSTTOKENPRIV` |
| DECLARE | GETSIDLENGTHREQUIRED | WIN32API.INC(2175): `DECLARE FUNCTION GETSIDLENGTHREQUIRED LIB "ADVAPI32.DLL" ALIAS "GETSIDLENGTHREQU` | WINDOWS.INC(2223): `DECLARE FUNCTION GETSIDLENGTHREQUIRED LIB "ADVAPI32.DLL" ALIAS "GETSIDLENGTHREQU` |
| DECLARE | ALLOCATEANDINITIALIZESID | WIN32API.INC(2176): `DECLARE FUNCTION ALLOCATEANDINITIALIZESID LIB "ADVAPI32.DLL" ALIAS "ALLOCATEANDI` | WINDOWS.INC(2224): `DECLARE FUNCTION ALLOCATEANDINITIALIZESID LIB "ADVAPI32.DLL" ALIAS "ALLOCATEANDI` |
| DECLARE | INITIALIZESID | WIN32API.INC(2178): `DECLARE FUNCTION INITIALIZESID LIB "ADVAPI32.DLL" ALIAS "INITIALIZESID" (SID AS ` | WINDOWS.INC(2226): `DECLARE FUNCTION INITIALIZESID LIB "ADVAPI32.DLL" ALIAS "INITIALIZESID" (SID AS ` |
| DECLARE | GETSIDSUBAUTHORITYCOUNT | WIN32API.INC(2181): `DECLARE FUNCTION GETSIDSUBAUTHORITYCOUNT LIB "ADVAPI32.DLL" ALIAS "GETSIDSUBAUTH` | WINDOWS.INC(2229): `DECLARE FUNCTION GETSIDSUBAUTHORITYCOUNT LIB "ADVAPI32.DLL" ALIAS "GETSIDSUBAUTH` |
| DECLARE | GETENVIRONMENTSTRINGS | Kernel32.inc(102): `DECLARE FUNCTION GETENVIRONMENTSTRINGS LIB "KERNEL32.DLL" ALIAS_ "GETENVIRONMENT` | WINDOWS.INC(2277): `DECLARE FUNCTION GETENVIRONMENTSTRINGS LIB "KERNEL32" ALIAS "GETENVIRONMENTSTRIN` |
| DECLARE | GETCURRENTTHREADID | Kernel32.inc(88): `DECLARE FUNCTION GETCURRENTTHREADID LIB "KERNEL32.DLL" ALIAS_ "GETCURRENTTHREADI` | WINDOWS.INC(2283): `DECLARE FUNCTION GETCURRENTTHREADID LIB "KERNEL32" ALIAS "GETCURRENTTHREADID" ()` |
| DECLARE | SETCOMMSTATE | rapidq2.inc(1953): `DECLARE FUNCTION SETCOMMSTATE LIB "KERNEL32" ALIAS "SETCOMMSTATE" _ (HFILE AS LO` | WINDOWS.INC(2291): `DECLARE FUNCTION SETCOMMSTATE LIB "KERNEL32" ALIAS "SETCOMMSTATE" (BYVAL HCOMMDE` |
| DECLARE | SETCOMMTIMEOUTS | rapidq2.inc(1937): `DECLARE FUNCTION SETCOMMTIMEOUTS LIB "KERNEL32" ALIAS "SETCOMMTIMEOUTS"_ (HFILE ` | WINDOWS.INC(2292): `DECLARE FUNCTION SETCOMMTIMEOUTS LIB "KERNEL32" ALIAS "SETCOMMTIMEOUTS" (BYVAL H` |
| DECLARE | GETCOMMSTATE | rapidq2.inc(1945): `DECLARE FUNCTION GETCOMMSTATE LIB "KERNEL32" ALIAS "GETCOMMSTATE" _ (HFILE AS LO` | WINDOWS.INC(2293): `DECLARE FUNCTION GETCOMMSTATE LIB "KERNEL32" ALIAS "GETCOMMSTATE" (BYVAL NCID AS` |
| DECLARE | PURGECOMM | rapidq2.inc(1928): `DECLARE FUNCTION PURGECOMM LIB "KERNEL32" ALIAS "PURGECOMM"_ (HFILE AS LONG, _ D` | WINDOWS.INC(2295): `DECLARE FUNCTION PURGECOMM LIB "KERNEL32" ALIAS "PURGECOMM" (BYVAL HFILE AS LONG` |
| DECLARE | TRANSMITCOMMCHAR | WIN32API.INC(2255): `DECLARE FUNCTION TRANSMITCOMMCHAR LIB "KERNEL32" ALIAS "TRANSMITCOMMCHAR" (BYVAL` | WINDOWS.INC(2298): `DECLARE FUNCTION TRANSMITCOMMCHAR LIB "KERNEL32" ALIAS "TRANSMITCOMMCHAR" (BYVAL` |
| DECLARE | CLEARCOMMERROR | rapidq2.inc(1964): `DECLARE FUNCTION CLEARCOMMERROR LIB "KERNEL32" ALIAS "CLEARCOMMERROR" _ (HFILE A` | WINDOWS.INC(2302): `DECLARE FUNCTION CLEARCOMMERROR LIB "KERNEL32" ALIAS "CLEARCOMMERROR" (BYVAL HFI` |
| DECLARE | SETUPCOMM | rapidq2.inc(1917): `DECLARE FUNCTION SETUPCOMM LIB "KERNEL32" ALIAS "SETUPCOMM"_ (HFILE AS LONG,_ DW` | WINDOWS.INC(2303): `DECLARE FUNCTION SETUPCOMM LIB "KERNEL32" ALIAS "SETUPCOMM" (BYVAL HFILE AS LONG` |
| DECLARE | GETTICKCOUNT | Kernel32.inc(159): `DECLARE FUNCTION GETTICKCOUNT LIB "KERNEL32.DLL" ALIAS_ "GETTICKCOUNT" AS LONG` | WINDOWS.INC(2360): `DECLARE FUNCTION GETTICKCOUNT LIB "KERNEL32" ALIAS "GETTICKCOUNT" () AS LONG` |
| DECLARE | FORMATMESSAGE | rapidq2.inc(1902): `DECLARE FUNCTION FORMATMESSAGE LIB "KERNEL32" ALIAS "FORMATMESSAGEA" _ (DWFLAGS ` | WINDOWS.INC(2361): `DECLARE FUNCTION FORMATMESSAGE LIB "KERNEL32" ALIAS "FORMATMESSAGEA" (BYVAL DWFL` |
| DECLARE | BACKUPREAD | WIN32API.INC(2367): `DECLARE FUNCTION BACKUPREAD LIB "KERNEL32" ALIAS "BACKUPREAD" (BYVAL HFILE AS LO` | WINDOWS.INC(2410): `DECLARE FUNCTION BACKUPREAD LIB "KERNEL32" ALIAS "BACKUPREAD" (BYVAL HFILE AS LO` |
| DECLARE | BACKUPWRITE | WIN32API.INC(2369): `DECLARE FUNCTION BACKUPWRITE LIB "KERNEL32" ALIAS "BACKUPWRITE" (BYVAL HFILE AS ` | WINDOWS.INC(2412): `DECLARE FUNCTION BACKUPWRITE LIB "KERNEL32" ALIAS "BACKUPWRITE" (BYVAL HFILE AS ` |
| DECLARE | GETCOMPUTERNAME | Kernel32.inc, поднято(52): `DECLARE FUNCTION GETCOMPUTERNAME LIB "KERNEL32.DLL" ALIAS_ "GETCOMPUTERNAMEA" (L` | WINDOWS.INC(2471): `DECLARE FUNCTION GETCOMPUTERNAME LIB "KERNEL32" ALIAS "GETCOMPUTERNAMEA" (BYVAL ` |
| DECLARE | GETUSERNAME | AdvAPI32.inc(14): `DECLARE FUNCTION GETUSERNAME LIB "ADVAPI32.DLL" ALIAS_ "GETUSERNAMEA" (LPBUFFER ` | WINDOWS.INC(2473): `DECLARE FUNCTION GETUSERNAME LIB "ADVAPI32.DLL" ALIAS "GETUSERNAMEA" (BYVAL LPBU` |
| DECLARE | GETOEMCP | Kernel32.inc(120): `DECLARE FUNCTION GETOEMCP LIB "KERNEL32.DLL" ALIAS_ "GETOEMCP" AS LONG` | WINDOWS.INC(2726): `DECLARE FUNCTION GETOEMCP LIB "KERNEL32" ALIAS "GETOEMCP" () AS LONG` |
| DECLARE | ISDBCSLEADBYTE | WIN32API.INC(2679): `DECLARE FUNCTION ISDBCSLEADBYTE LIB "KERNEL32" ALIAS "ISDBCSLEADBYTE" (BYVAL BTE` | WINDOWS.INC(2728): `DECLARE FUNCTION ISDBCSLEADBYTE LIB "KERNEL32" ALIAS "ISDBCSLEADBYTE" (BYVAL BTE` |
| DECLARE | MULTIBYTETOWIDECHAR | conversion.inc(75): `DECLARE FUNCTION MULTIBYTETOWIDECHAR LIB "KERNEL32" ALIAS "MULTIBYTETOWIDECHAR" ` | WINDOWS.INC(2729): `DECLARE FUNCTION MULTIBYTETOWIDECHAR LIB "KERNEL32" ALIAS "MULTIBYTETOWIDECHAR" ` |
| DECLARE | WIDECHARTOMULTIBYTE | conversion.inc(81): `DECLARE FUNCTION WIDECHARTOMULTIBYTE LIB "KERNEL32" ALIAS "WIDECHARTOMULTIBYTE" ` | WINDOWS.INC(2730): `DECLARE FUNCTION WIDECHARTOMULTIBYTE LIB "KERNEL32" ALIAS "WIDECHARTOMULTIBYTE" ` |
| DECLARE | GETLOCALEINFO | ApiDate.inc(29): `DECLARE FUNCTION GETLOCALEINFO LIB "KERNEL32" ALIAS "GETLOCALEINFOA" _ (BYVAL LO` | WINDOWS.INC(2736): `DECLARE FUNCTION GETLOCALEINFO LIB "KERNEL32" ALIAS "GETLOCALEINFOA" (BYVAL LOCA` |
| DECLARE | GETDATEFORMAT | ApiDate.inc(22): `DECLARE FUNCTION GETDATEFORMAT LIB "KERNEL32" ALIAS "GETDATEFORMATA" _ (BYVAL LO` | WINDOWS.INC(2738): `DECLARE FUNCTION GETDATEFORMAT LIB "KERNEL32" ALIAS "GETDATEFORMATA" (BYVAL LOCA` |
| DECLARE | GETSYSTEMDEFAULTLANGID | Kernel32.inc(132): `DECLARE FUNCTION GETSYSTEMDEFAULTLANGID LIB "KERNEL32.DLL" ALIAS_ "GETSYSTEMDEFA` | WINDOWS.INC(2740): `DECLARE FUNCTION GETSYSTEMDEFAULTLANGID LIB "KERNEL32" ALIAS "GETSYSTEMDEFAULTLA` |
| DECLARE | GETUSERDEFAULTLANGID | Kernel32.inc(165): `DECLARE FUNCTION GETUSERDEFAULTLANGID LIB "KERNEL32.DLL" ALIAS_ "GETUSERDEFAULTL` | WINDOWS.INC(2741): `DECLARE FUNCTION GETUSERDEFAULTLANGID LIB "KERNEL32" ALIAS "GETUSERDEFAULTLANGID` |
| DECLARE | GETSYSTEMDEFAULTLCID | Kernel32.inc(138): `DECLARE FUNCTION GETSYSTEMDEFAULTLCID LIB "KERNEL32.DLL" ALIAS_ "GETSYSTEMDEFAUL` | WINDOWS.INC(2742): `DECLARE FUNCTION GETSYSTEMDEFAULTLCID LIB "KERNEL32" ALIAS "GETSYSTEMDEFAULTLCID` |
| DECLARE | GETUSERDEFAULTLCID | Kernel32.inc(171): `DECLARE FUNCTION GETUSERDEFAULTLCID LIB "KERNEL32.DLL" ALIAS_ "GETUSERDEFAULTLCI` | WINDOWS.INC(2743): `DECLARE FUNCTION GETUSERDEFAULTLCID LIB "KERNEL32" ALIAS "GETUSERDEFAULTLCID" ()` |
| DECLARE | GETTHREADLOCALE | Kernel32.inc(153): `DECLARE FUNCTION GETTHREADLOCALE LIB "KERNEL32.DLL" ALIAS_ "GETTHREADLOCALE" AS ` | WINDOWS.INC(2859): `DECLARE FUNCTION GETTHREADLOCALE LIB "KERNEL32" ALIAS "GETTHREADLOCALE" () AS LO` |
| TYPE | COORD | WIN32API.INC(2817): `TYPE COORD X AS INTEGER Y AS INTEGER END TYPE` | WINDOWS.INC(2866): `TYPE COORD X AS SHORT Y AS SHORT END TYPE` |
| TYPE | SMALL_RECT | WIN32API.INC(2822): `TYPE SMALL_RECT LEFT AS INTEGER TOP AS INTEGER RIGHT AS INTEGER BOTTOM AS INTEGE` | WINDOWS.INC(2871): `TYPE SMALL_RECT LEFT AS SHORT TOP AS SHORT RIGHT AS SHORT BOTTOM AS SHORT END TY` |
| TYPE | KEY_EVENT_RECORD | WIN32API.INC(2829): `TYPE KEY_EVENT_RECORD BKEYDOWN AS LONG WREPEATCOUNT AS INTEGER WVIRTUALKEYCODE A` | WINDOWS.INC(2878): `TYPE KEY_EVENT_RECORD BKEYDOWN AS LONG WREPEATCOUNT AS WORD WVIRTUALKEYCODE AS W` |
| TYPE | CHAR_INFO | WIN32API.INC(2886): `TYPE CHAR_INFO CHAR AS INTEGER ATTRIBUTES AS INTEGER END TYPE` | WINDOWS.INC(2935): `TYPE CHAR_INFO CHAR AS WORD ATTRIBUTES AS WORD END TYPE` |
| TYPE | CONSOLE_SCREEN_BUFFER_INFO | WIN32API.INC(2901): `TYPE CONSOLE_SCREEN_BUFFER_INFO DWSIZE AS COORD DWCURSORPOSITION AS COORD WATTRI` | WINDOWS.INC(2950): `TYPE CONSOLE_SCREEN_BUFFER_INFO DWSIZE AS COORD DWCURSORPOSITION AS COORD WATTRI` |
| DECLARE | FILLCONSOLEOUTPUTCHARACTER | WIN32API.INC(2942): `DECLARE FUNCTION FILLCONSOLEOUTPUTCHARACTER LIB "KERNEL32" ALIAS "FILLCONSOLEOUT` | WINDOWS.INC(2991): `DECLARE FUNCTION FILLCONSOLEOUTPUTCHARACTER LIB "KERNEL32" ALIAS "FILLCONSOLEOUT` |
| DECLARE | GETCONSOLECP | Kernel32.inc(58): `DECLARE FUNCTION GETCONSOLECP LIB "KERNEL32.DLL" ALIAS_ "GETCONSOLECP" AS LONG` | WINDOWS.INC(3020): `DECLARE FUNCTION GETCONSOLECP LIB "KERNEL32" ALIAS "GETCONSOLECP" () AS LONG` |
| DECLARE | GETCONSOLEOUTPUTCP | Kernel32.inc(64): `DECLARE FUNCTION GETCONSOLEOUTPUTCP LIB "KERNEL32.DLL" ALIAS_ "GETCONSOLEOUTPUTC` | WINDOWS.INC(3022): `DECLARE FUNCTION GETCONSOLEOUTPUTCP LIB "KERNEL32" ALIAS "GETCONSOLEOUTPUTCP" ()` |
| TYPE | BITMAPCOREHEADER | WIN32API.INC(3297): `TYPE BITMAPCOREHEADER BCSIZE AS LONG BCWIDTH AS INTEGER BCHEIGHT AS INTEGER BCPL` | WINDOWS.INC(3341): `TYPE BITMAPCOREHEADER BCSIZE AS LONG BCWIDTH AS WORD BCHEIGHT AS WORD BCPLANES A` |
| TYPE | BITMAPINFOHEADER | WIN32API.INC(3305): `TYPE BITMAPINFOHEADER BISIZE AS LONG BIWIDTH AS LONG BIHEIGHT AS LONG BIPLANES A` | WINDOWS.INC(3349): `TYPE BITMAPINFOHEADER BISIZE AS LONG BIWIDTH AS LONG BIHEIGHT AS LONG BIPLANES A` |
| TYPE | BITMAPINFO | WIN32API.INC(3325): `TYPE BITMAPINFO BMIHEADER AS BITMAPINFOHEADER BMICOLORS AS RGBQUAD END TYPE` | WINDOWS.INC(3370): `TYPE BITMAPINFO BMIHEADER_BISIZE AS LONG BMIHEADER_BIWIDTH AS LONG BMIHEADER_BIH` |
| TYPE | BITMAPCOREINFO | WIN32API.INC(3330): `TYPE BITMAPCOREINFO BMCIHEADER AS BITMAPCOREHEADER BMCICOLORS AS RGBTRIPLE END T` | WINDOWS.INC(3401): `TYPE BITMAPCOREINFO BMCIHEADER_BCSIZE AS LONG BMCIHEADER_BCWIDTH AS WORD BMCIHEA` |
| TYPE | BITMAPFILEHEADER | WIN32API.INC(3335): `TYPE BITMAPFILEHEADER BFTYPE AS INTEGER BFSIZE AS LONG BFRESERVED1 AS INTEGER BF` | WINDOWS.INC(3416): `TYPE BITMAPFILEHEADER BFTYPE AS WORD BFSIZE AS LONG BFRESERVED1 AS WORD BFRESERV` |
| TYPE | METARECORD | WIN32API.INC(3349): `TYPE METARECORD RDSIZE AS LONG RDFUNCTION AS INTEGER RDPARM(1) AS INTEGER END TY` | WINDOWS.INC(3430): `TYPE METARECORD RDSIZE AS LONG RDFUNCTION AS WORD RDPARM(1) AS WORD END TYPE` |
| TYPE | METAHEADER | WIN32API.INC(3363): `TYPE METAHEADER MTTYPE AS INTEGER MTHEADERSIZE AS INTEGER MTVERSION AS INTEGER M` | WINDOWS.INC(3444): `TYPE METAHEADER MTTYPE AS WORD MTHEADERSIZE AS WORD MTVERSION AS WORD MTSIZE AS ` |
| TYPE | ENHMETAHEADER | WIN32API.INC(3384): `TYPE ENHMETAHEADER ITYPE AS LONG NSIZE AS LONG RCLBOUNDS AS RECTL RCLFRAME AS RE` | WINDOWS.INC(3465): `TYPE ENHMETAHEADER ITYPE AS LONG NSIZE AS LONG RCLBOUNDS AS RECTL RCLFRAME AS RE` |
| TYPE | PELARRAY | WIN32API.INC(3468): `TYPE PELARRAY PAXCOUNT AS LONG PAYCOUNT AS LONG PAXEXT AS LONG PAYEXT AS LONG PA` | WINDOWS.INC(3549): `TYPE PELARRAY PAXCOUNT AS LONG PAYCOUNT AS LONG PAXEXT AS LONG PAYEXT AS LONG PA` |
| TYPE | LOGPALETTE | WIN32API.INC(3508): `TYPE LOGPALETTE PALVERSION AS INTEGER PALNUMENTRIES AS INTEGER PALPALENTRY(1) AS` | WINDOWS.INC(3589): `TYPE LOGPALETTE PALVERSION AS WORD PALNUMENTRIES AS WORD PALPALENTRY(1) AS PALET` |
| CONST | HOLLOW_BRUSH | rapidq2.inc(1262): `5` | WINDOWS.INC(3911): `PUBLIC CONST HOLLOW_BRUSH = NULL_BRUSH` |
| CONST | CDS_TEST | rapidq2.inc(1366): `&H2` | WINDOWS.INC(4190): `CONST CDS_TEST = &H4` |
| TYPE | FIXED | WIN32API.INC(4292): `TYPE FIXED FRACT AS INTEGER VALUE AS INTEGER END TYPE` | WINDOWS.INC(4413): `TYPE FIXED FRACT AS WORD VALUE AS SHORT END TYPE` |
| TYPE | GLYPHMETRICS | WIN32API.INC(4304): `TYPE GLYPHMETRICS GMBLACKBOXX AS LONG GMBLACKBOXY AS LONG GMPTGLYPHORIGIN AS POI` | WINDOWS.INC(4425): `TYPE GLYPHMETRICS GMBLACKBOXX AS LONG GMBLACKBOXY AS LONG GMPTGLYPHORIGIN AS POI` |
| TYPE | TTPOLYCURVE | WIN32API.INC(4328): `TYPE TTPOLYCURVE WTYPE AS INTEGER CPFX AS INTEGER APFX AS POINTFX END TYPE` | WINDOWS.INC(4449): `TYPE TTPOLYCURVE WTYPE AS WORD CPFX AS WORD APFX AS POINTFX END TYPE` |
| TYPE | RASTERIZER_STATUS | WIN32API.INC(4340): `TYPE RASTERIZER_STATUS NSIZE AS INTEGER WFLAGS AS INTEGER NLANGUAGEID AS INTEGER` | WINDOWS.INC(4461): `TYPE RASTERIZER_STATUS NSIZE AS WORD WFLAGS AS WORD NLANGUAGEID AS WORD END TYPE` |
| DECLARE | BITBLT | rapidq2.inc(1434): `DECLARE FUNCTION BITBLT LIB "GDI32.DLL" ALIAS "BITBLT" (_ BYVAL HDCDEST AS LONG,` | WINDOWS.INC(4475): `DECLARE FUNCTION BITBLT LIB "GDI32" ALIAS "BITBLT" (BYVAL HDESTDC AS LONG, BYVAL` |
| DECLARE | COMBINERGN | GDI32.inc(43): `DECLARE FUNCTION COMBINERGN LIB "GDI32.DLL" ALIAS_ "COMBINERGN" (HRGNDEST AS LON` | WINDOWS.INC(4479): `DECLARE FUNCTION COMBINERGN LIB "GDI32" ALIAS "COMBINERGN" (BYVAL HDESTRGN AS LO` |
| DECLARE | CREATECOMPATIBLEBITMAP | rapidq2.inc(1446): `DECLARE FUNCTION CREATECOMPATIBLEBITMAP LIB "GDI32" ALIAS "CREATECOMPATIBLEBITMA` | WINDOWS.INC(4485): `DECLARE FUNCTION CREATECOMPATIBLEBITMAP LIB "GDI32" ALIAS "CREATECOMPATIBLEBITMA` |
| DECLARE | CREATECOMPATIBLEDC | rapidq2.inc(1447): `DECLARE FUNCTION CREATECOMPATIBLEDC LIB "GDI32" ALIAS "CREATECOMPATIBLEDC" (HDC ` | WINDOWS.INC(4488): `DECLARE FUNCTION CREATECOMPATIBLEDC LIB "GDI32" ALIAS "CREATECOMPATIBLEDC" (BYVA` |
| DECLARE | CREATEDC | rapidq2.inc(1429): `DECLARE FUNCTION CREATEDC LIB "GDI32" ALIAS "CREATEDCA" (_ BYVAL LPDRIVERNAME AS` | WINDOWS.INC(4489): `DECLARE FUNCTION CREATEDC LIB "GDI32" ALIAS "CREATEDCA" (BYVAL LPDRIVERNAME AS S` |
| DECLARE | CREATEELLIPTICRGN | GDI32.inc(53): `DECLARE FUNCTION CREATEELLIPTICRGN LIB "GDI32.DLL" ALIAS_ "CREATEELLIPTICRGN" (X` | WINDOWS.INC(4495): `DECLARE FUNCTION CREATEELLIPTICRGN LIB "GDI32" ALIAS "CREATEELLIPTICRGN" (BYVAL ` |
| DECLARE | CREATEPEN | rapidq2.inc(1448): `DECLARE FUNCTION CREATEPEN LIB "GDI32" ALIAS "CREATEPEN" (NPENSTYLE AS LONG, NWI` | WINDOWS.INC(4506): `DECLARE FUNCTION CREATEPEN LIB "GDI32" ALIAS "CREATEPEN" (BYVAL NPENSTYLE AS LON` |
| DECLARE | CREATERECTRGN | GDI32.inc(62): `DECLARE FUNCTION CREATERECTRGN LIB "GDI32.DLL" ALIAS_ "CREATERECTRGN" (X1 AS LON` | WINDOWS.INC(4508): `DECLARE FUNCTION CREATERECTRGN LIB "GDI32" ALIAS "CREATERECTRGN" (BYVAL X1 AS LO` |
| DECLARE | CREATEROUNDRECTRGN | GDI32.inc(72): `DECLARE FUNCTION CREATEROUNDRECTRGN LIB "GDI32.DLL" ALIAS_ "CREATEROUNDRECTRGN" ` | WINDOWS.INC(4512): `DECLARE FUNCTION CREATEROUNDRECTRGN LIB "GDI32" ALIAS "CREATEROUNDRECTRGN" (BYVA` |
| DECLARE | CREATESOLIDBRUSH | rapidq2.inc(1449): `DECLARE FUNCTION CREATESOLIDBRUSH LIB "GDI32" ALIAS "CREATESOLIDBRUSH" (CRCOLOR ` | WINDOWS.INC(4514): `DECLARE FUNCTION CREATESOLIDBRUSH LIB "GDI32" ALIAS "CREATESOLIDBRUSH" (BYVAL CR` |
| DECLARE | DELETEDC | rapidq2.inc(1450): `DECLARE FUNCTION DELETEDC LIB "GDI32" ALIAS "DELETEDC" (HDC AS LONG) AS LONG` | WINDOWS.INC(4516): `DECLARE FUNCTION DELETEDC LIB "GDI32" ALIAS "DELETEDC" (BYVAL HDC AS LONG) AS LO` |
| DECLARE | DELETEOBJECT | rapidq2.inc(1451): `DECLARE FUNCTION DELETEOBJECT LIB "GDI32" ALIAS "DELETEOBJECT" (HOBJECT AS LONG)` | WINDOWS.INC(4517): `DECLARE FUNCTION DELETEOBJECT LIB "GDI32" ALIAS "DELETEOBJECT" (BYVAL HOBJECT AS` |
| DECLARE | ELLIPSE | rapidq2.inc(1452): `DECLARE FUNCTION ELLIPSE LIB "GDI32" ALIAS "ELLIPSE" (HDC AS LONG,X1 AS LONG,Y1 ` | WINDOWS.INC(4563): `DECLARE FUNCTION ELLIPSE LIB "GDI32" ALIAS "ELLIPSE" (BYVAL HDC AS LONG, BYVAL X` |
| DECLARE | EXCLUDECLIPRECT | QFormSkin.inc(241): `DECLARE FUNCTION EXCLUDECLIPRECT LIB "GDI32.DLL" ALIAS "EXCLUDECLIPRECT" ( _ BYV` | WINDOWS.INC(4569): `DECLARE FUNCTION EXCLUDECLIPRECT LIB "GDI32" ALIAS "EXCLUDECLIPRECT" (BYVAL HDC ` |
| DECLARE | EXTFLOODFILL | rapidq2.inc(1453): `DECLARE FUNCTION EXTFLOODFILL LIB "GDI32" ALIAS "EXTFLOODFILL" (HDC AS LONG,X AS` | WINDOWS.INC(4571): `DECLARE FUNCTION EXTFLOODFILL LIB "GDI32" ALIAS "EXTFLOODFILL" (BYVAL HDC AS LON` |
| DECLARE | GETCHARWIDTHFLOAT | WIN32API.INC(4459): `DECLARE FUNCTION GETCHARWIDTHFLOAT LIB "GDI32" ALIAS "GETCHARWIDTHFLOATA" (BYVAL` | WINDOWS.INC(4585): `DECLARE FUNCTION GETCHARWIDTHFLOAT LIB "GDI32" ALIAS "GETCHARWIDTHFLOATA" (BYVAL` |
| DECLARE | GETCURRENTOBJECT | rapidq2.inc(1456): `DECLARE FUNCTION GETCURRENTOBJECT LIB "GDI32" ALIAS "GETCURRENTOBJECT" (HDC AS L` | WINDOWS.INC(4593): `DECLARE FUNCTION GETCURRENTOBJECT LIB "GDI32" ALIAS "GETCURRENTOBJECT" (BYVAL HD` |
| DECLARE | GETDEVICECAPS | rapidq2.inc(1454): `DECLARE FUNCTION GETDEVICECAPS LIB "GDI32.DLL" ALIAS "GETDEVICECAPS"(BYVAL HDC A` | WINDOWS.INC(4595): `DECLARE FUNCTION GETDEVICECAPS LIB "GDI32" ALIAS "GETDEVICECAPS" (BYVAL HDC AS L` |
| DECLARE | GETPIXEL | rapidq2.inc(1457): `DECLARE FUNCTION GETPIXEL LIB "GDI32" ALIAS "GETPIXEL" (HDC AS LONG,X AS LONG,Y ` | WINDOWS.INC(4610): `DECLARE FUNCTION GETPIXEL LIB "GDI32" ALIAS "GETPIXEL" (BYVAL HDC AS LONG, BYVAL` |
| DECLARE | GETRGNBOX | QFormSkin.inc(150): `DECLARE FUNCTION GETRGNBOX LIB "GDI32.DLL" ALIAS "GETRGNBOX" ( _ BYVAL HRGN AS L` | WINDOWS.INC(4614): `DECLARE FUNCTION GETRGNBOX LIB "GDI32" ALIAS "GETRGNBOX" (BYVAL HRGN AS LONG, LP` |
| DECLARE | GETSTOCKOBJECT | rapidq2.inc(1458): `DECLARE FUNCTION GETSTOCKOBJECT LIB "GDI32" ALIAS "GETSTOCKOBJECT" (NINDEX AS LO` | WINDOWS.INC(4615): `DECLARE FUNCTION GETSTOCKOBJECT LIB "GDI32" ALIAS "GETSTOCKOBJECT" (BYVAL NINDEX` |
| DECLARE | LINETO | rapidq2.inc(1459): `DECLARE FUNCTION LINETO LIB "GDI32" ALIAS "LINETO" (HDC AS LONG,X AS LONG,Y AS L` | WINDOWS.INC(4634): `DECLARE FUNCTION LINETO LIB "GDI32" ALIAS "LINETO" (BYVAL HDC AS LONG, BYVAL X A` |
| DECLARE | PATBLT | rapidq2.inc(1461): `DECLARE FUNCTION PATBLT LIB "GDI32" ALIAS "PATBLT" (HDC AS LONG,X AS LONG,Y AS L` | WINDOWS.INC(4640): `DECLARE FUNCTION PATBLT LIB "GDI32" ALIAS "PATBLT" (BYVAL HDC AS LONG, BYVAL X A` |
| DECLARE | RECTANGLE | rapidq2.inc(1462): `DECLARE FUNCTION RECTANGLE LIB "GDI32" ALIAS "RECTANGLE" (HDC AS LONG,X1 AS LONG` | WINDOWS.INC(4649): `DECLARE FUNCTION RECTANGLE LIB "GDI32" ALIAS "RECTANGLE" (BYVAL HDC AS LONG, BYV` |
| DECLARE | ROUNDRECT | rapidq2.inc(1463): `DECLARE FUNCTION ROUNDRECT LIB "GDI32" ALIAS "ROUNDRECT" (HDC AS LONG,X1 AS LONG` | WINDOWS.INC(4654): `DECLARE FUNCTION ROUNDRECT LIB "GDI32" ALIAS "ROUNDRECT" (BYVAL HDC AS LONG, BYV` |
| DECLARE | SELECTOBJECT | rapidq2.inc(1464): `DECLARE FUNCTION SELECTOBJECT LIB "GDI32" ALIAS "SELECTOBJECT" (HDC AS LONG,HOBJ` | WINDOWS.INC(4661): `DECLARE FUNCTION SELECTOBJECT LIB "GDI32" ALIAS "SELECTOBJECT" (BYVAL HDC AS LON` |
| DECLARE | SETBKMODE | rapidq2.inc(1466): `DECLARE FUNCTION SETBKMODE LIB "GDI32" ALIAS "SETBKMODE" (HDC AS LONG,NBKMODE AS` | WINDOWS.INC(4664): `DECLARE FUNCTION SETBKMODE LIB "GDI32" ALIAS "SETBKMODE" (BYVAL HDC AS LONG, BYV` |
| DECLARE | SETMETAFILEBITSEX | WIN32API.INC(4547): `DECLARE FUNCTION SETMETAFILEBITSEX LIB "GDI32" ALIAS "SETMETAFILEBITSEX" (BYVAL ` | WINDOWS.INC(4673): `DECLARE FUNCTION SETMETAFILEBITSEX LIB "GDI32" ALIAS "SETMETAFILEBITSEX" (BYVAL ` |
| DECLARE | STRETCHBLT | rapidq2.inc(1467): `DECLARE FUNCTION STRETCHBLT LIB "GDI32" ALIAS "STRETCHBLT" (HDC AS LONG,X AS LON` | WINDOWS.INC(4678): `DECLARE FUNCTION STRETCHBLT LIB "GDI32" ALIAS "STRETCHBLT" (BYVAL HDC AS LONG, B` |
| DECLARE | SETRECTRGN | QFormSkin.inc(152): `DECLARE FUNCTION SETRECTRGN LIB "GDI32.DLL" ALIAS "SETRECTRGN" ( _ BYVAL HRGN AS` | WINDOWS.INC(4679): `DECLARE FUNCTION SETRECTRGN LIB "GDI32" ALIAS "SETRECTRGN" (BYVAL HRGN AS LONG, ` |
| DECLARE | SETROP2 | rapidq2.inc(1465): `DECLARE FUNCTION SETROP2 LIB "GDI32" ALIAS "SETROP2" (HDC AS LONG,NDRAWMODE AS L` | WINDOWS.INC(4681): `DECLARE FUNCTION SETROP2 LIB "GDI32" ALIAS "SETROP2" (BYVAL HDC AS LONG, BYVAL N` |
| DECLARE | SETTEXTCOLOR | QFormSkin.inc(229): `DECLARE FUNCTION SETTEXTCOLOR LIB "GDI32" ALIAS "SETTEXTCOLOR" ( _ BYVAL HDC AS ` | WINDOWS.INC(4685): `DECLARE FUNCTION SETTEXTCOLOR LIB "GDI32" ALIAS "SETTEXTCOLOR" (BYVAL HDC AS LON` |
| DECLARE | GETENHMETAFILEBITS | WIN32API.INC(4574): `DECLARE FUNCTION GETENHMETAFILEBITS LIB "GDI32" ALIAS "GETENHMETAFILEBITS" (BYVA` | WINDOWS.INC(4700): `DECLARE FUNCTION GETENHMETAFILEBITS LIB "GDI32" ALIAS "GETENHMETAFILEBITS" (BYVA` |
| DECLARE | GETWINMETAFILEBITS | WIN32API.INC(4578): `DECLARE FUNCTION GETWINMETAFILEBITS LIB "GDI32" ALIAS "GETWINMETAFILEBITS" (BYVA` | WINDOWS.INC(4704): `DECLARE FUNCTION GETWINMETAFILEBITS LIB "GDI32" ALIAS "GETWINMETAFILEBITS" (BYVA` |
| DECLARE | SETENHMETAFILEBITS | WIN32API.INC(4581): `DECLARE FUNCTION SETENHMETAFILEBITS LIB "GDI32" ALIAS "SETENHMETAFILEBITS" (BYVA` | WINDOWS.INC(4707): `DECLARE FUNCTION SETENHMETAFILEBITS LIB "GDI32" ALIAS "SETENHMETAFILEBITS" (BYVA` |
| DECLARE | SETWINMETAFILEBITS | WIN32API.INC(4582): `DECLARE FUNCTION SETWINMETAFILEBITS LIB "GDI32" ALIAS "SETWINMETAFILEBITS" (BYVA` | WINDOWS.INC(4708): `DECLARE FUNCTION SETWINMETAFILEBITS LIB "GDI32" ALIAS "SETWINMETAFILEBITS" (BYVA` |
| DECLARE | GDICOMMENT | WIN32API.INC(4583): `DECLARE FUNCTION GDICOMMENT LIB "GDI32" ALIAS "GDICOMMENT" (BYVAL HDC AS LONG, B` | WINDOWS.INC(4709): `DECLARE FUNCTION GDICOMMENT LIB "GDI32" ALIAS "GDICOMMENT" (BYVAL HDC AS LONG, B` |
| TYPE | COLORADJUSTMENT | WIN32API.INC(4629): `TYPE COLORADJUSTMENT CASIZE AS INTEGER CAFLAGS AS INTEGER CAILLUMINANTINDEX AS I` | WINDOWS.INC(4755): `TYPE COLORADJUSTMENT CASIZE AS WORD CAFLAGS AS WORD CAILLUMINANTINDEX AS WORD CA` |
| DECLARE | GETPATH | WIN32API.INC(4667): `DECLARE FUNCTION GETPATH LIB "GDI32" ALIAS "GETPATH" (BYVAL HDC AS LONG, LPPOINT` | WINDOWS.INC(4793): `DECLARE FUNCTION GETPATH LIB "GDI32" ALIAS "GETPATH" (BYVAL HDC AS LONG, LPPOINT` |
| DECLARE | POLYDRAW | WIN32API.INC(4669): `DECLARE FUNCTION POLYDRAW LIB "GDI32" ALIAS "POLYDRAW" (BYVAL HDC AS LONG, LPPT ` | WINDOWS.INC(4795): `DECLARE FUNCTION POLYDRAW LIB "GDI32" ALIAS "POLYDRAW" (BYVAL HDC AS LONG, LPPT ` |
| DECLARE | GETMITERLIMIT | WIN32API.INC(4677): `DECLARE FUNCTION GETMITERLIMIT LIB "GDI32" ALIAS "GETMITERLIMIT" (BYVAL HDC AS L` | WINDOWS.INC(4803): `DECLARE FUNCTION GETMITERLIMIT LIB "GDI32" ALIAS "GETMITERLIMIT" (BYVAL HDC AS L` |
| DECLARE | GETOBJECT | rapidq2.inc(1455): `DECLARE FUNCTION GETOBJECT LIB "GDI32" ALIAS "GETOBJECTA" (HOBJECT AS LONG,NCOUN` | WINDOWS.INC(4806): `DECLARE FUNCTION GETOBJECT LIB "GDI32" ALIAS "GETOBJECTA" (BYVAL HOBJECT AS LONG` |
| TYPE | KERNINGPAIR | WIN32API.INC(4712): `TYPE KERNINGPAIR WFIRST AS INTEGER WSECOND AS INTEGER IKERNAMOUNT AS LONG END TY` | WINDOWS.INC(4838): `TYPE KERNINGPAIR WFIRST AS WORD WSECOND AS WORD IKERNAMOUNT AS LONG END TYPE` |
| TYPE | EMRGDICOMMENT | WIN32API.INC(4990): `TYPE EMRGDICOMMENT PEMR AS EMR CBDATA AS LONG DATA(1) AS INTEGER END TYPE` | WINDOWS.INC(5116): `TYPE EMRGDICOMMENT PEMR AS EMR CBDATA AS LONG DATA(1) AS WORD END TYPE` |
| TYPE | EMRPOLYDRAW | WIN32API.INC(5223): `TYPE EMRPOLYDRAW PEMR AS EMR RCLBOUNDS AS RECTL CPTL AS LONG APTL(1) AS POINTL A` | WINDOWS.INC(5349): `TYPE EMRPOLYDRAW PEMR AS EMR RCLBOUNDS AS RECTL CPTL AS LONG APTL(1) AS POINTL A` |
| TYPE | EMRPOLYDRAW16 | WIN32API.INC(5231): `TYPE EMRPOLYDRAW16 PEMR AS EMR RCLBOUNDS AS RECTL CPTS AS LONG APTS(1) AS POINTS` | WINDOWS.INC(5357): `TYPE EMRPOLYDRAW16 PEMR AS EMR RCLBOUNDS AS RECTL CPTS AS LONG APTS(1) AS POINTS` |
| TYPE | EMRINVERTRGN | WIN32API.INC(5275): `TYPE EMRINVERTRGN PEMR AS EMR RCLBOUNDS AS RECTL CBRGNDATA AS LONG RGNDATA(1) AS` | WINDOWS.INC(5401): `TYPE EMRINVERTRGN PEMR AS EMR RCLBOUNDS AS RECTL CBRGNDATA AS LONG RGNDATA(1) AS` |
| TYPE | EMRPAINTRGN | WIN32API.INC(5282): `TYPE EMRPAINTRGN PEMR AS EMR RCLBOUNDS AS RECTL CBRGNDATA AS LONG RGNDATA(1) AS ` | WINDOWS.INC(5408): `TYPE EMRPAINTRGN PEMR AS EMR RCLBOUNDS AS RECTL CBRGNDATA AS LONG RGNDATA(1) AS ` |
| TYPE | EMRFILLRGN | WIN32API.INC(5289): `TYPE EMRFILLRGN PEMR AS EMR RCLBOUNDS AS RECTL CBRGNDATA AS LONG IHBRUSH AS LONG` | WINDOWS.INC(5415): `TYPE EMRFILLRGN PEMR AS EMR RCLBOUNDS AS RECTL CBRGNDATA AS LONG IHBRUSH AS LONG` |
| TYPE | EMRFRAMERGN | WIN32API.INC(5297): `TYPE EMRFRAMERGN PEMR AS EMR RCLBOUNDS AS RECTL CBRGNDATA AS LONG IHBRUSH AS LON` | WINDOWS.INC(5423): `TYPE EMRFRAMERGN PEMR AS EMR RCLBOUNDS AS RECTL CBRGNDATA AS LONG IHBRUSH AS LON` |
| TYPE | EMREXTSELECTCLIPRGN | WIN32API.INC(5306): `TYPE EMREXTSELECTCLIPRGN PEMR AS EMR CBRGNDATA AS LONG IMODE AS LONG RGNDATA(1) ` | WINDOWS.INC(5432): `TYPE EMREXTSELECTCLIPRGN PEMR AS EMR CBRGNDATA AS LONG IMODE AS LONG RGNDATA(1) ` |
| TYPE | BITMAPV4HEADER | WIN32API.INC(5521): `TYPE BITMAPV4HEADER BV4SIZE AS LONG BV4WIDTH AS LONG BV4HEIGHT AS LONG BV4PLANES` | WINDOWS.INC(5647): `TYPE BITMAPV4HEADER BV4SIZE AS LONG BV4WIDTH AS LONG BV4HEIGHT AS LONG BV4PLANES` |
| DECLARE | GETPROCESSWINDOWSTATION | User32.inc(120): `DECLARE FUNCTION GETPROCESSWINDOWSTATION LIB "USER32.DLL" ALIAS_ "GETPROCESSWIND` | WINDOWS.INC(6286): `DECLARE FUNCTION GETPROCESSWINDOWSTATION LIB "USER32" ALIAS "GETPROCESSWINDOWSTA` |
| CONST | WS_TILED | Win32_constants.inc(56): `CONST WS_TILED = 0` | WINDOWS.INC(6648): `PUBLIC CONST WS_TILED = WS_OVERLAPPED` |
| CONST | WS_ICONIC | Win32_constants.inc(43): `CONST WS_ICONIC = &H20000000` | WINDOWS.INC(6649): `PUBLIC CONST WS_ICONIC = WS_MINIMIZE` |
| CONST | WS_SIZEBOX | Win32_constants.inc(52): `CONST WS_SIZEBOX = &H40000` | WINDOWS.INC(6650): `PUBLIC CONST WS_SIZEBOX = WS_THICKFRAME` |
| CONST | WS_TILEDWINDOW | Win32_constants.inc(57): `CONST WS_TILEDWINDOW = &HCF0000` | WINDOWS.INC(6652): `PUBLIC CONST WS_TILEDWINDOW = WS_OVERLAPPEDWINDOW` |
| CONST | WS_POPUPWINDOW | Win32_constants.inc(51): `CONST WS_POPUPWINDOW = &H80880000` | WINDOWS.INC(6660): `PUBLIC CONST WS_POPUPWINDOW = (WS_POPUP OR WS_BORDER OR WS_SYSMENU)` |
| CONST | WS_CHILDWINDOW | Win32_constants.inc(36): `CONST WS_CHILDWINDOW = &H40000000` | WINDOWS.INC(6662): `PUBLIC CONST WS_CHILDWINDOW = (WS_CHILD)` |
| CONST | FVIRTKEY | WIN32API.INC(6526): `PUBLIC CONST FVIRTKEY = TRUE` | WINDOWS.INC(6717): `PUBLIC CONST FVIRTKEY = 1` |
| TYPE | ACCEL | WIN32API.INC(6532): `TYPE ACCEL FVIRT AS BYTE KEY AS INTEGER CMD AS INTEGER END TYPE` | WINDOWS.INC(6723): `TYPE ACCEL FVIRT AS BYTE KEY AS WORD CMD AS WORD END TYPE` |
| TYPE | WINDOWPLACEMENT | Form.inc(26): `PRIVATE TYPE WINDOWPLACEMENT LENGTH AS LONG FLAGS AS LONG SHOWCMD AS LONG PTMINP` | WINDOWS.INC(6759): `TYPE WINDOWPLACEMENT LENGTH AS LONG FLAGS AS LONG SHOWCMD AS LONG PTMINPOSITION ` |
| DECLARE | REGISTERHOTKEY | User32.inc(203): `DECLARE FUNCTION REGISTERHOTKEY LIB "USER32.DLL" ALIAS_ "REGISTERHOTKEY" (HWND A` | WINDOWS.INC(6875): `DECLARE FUNCTION REGISTERHOTKEY LIB "USER32" ALIAS "REGISTERHOTKEY" (BYVAL HWND ` |
| DECLARE | UNREGISTERHOTKEY | User32.inc(232): `DECLARE FUNCTION UNREGISTERHOTKEY LIB "USER32.DLL" ALIAS_ "UNREGISTERHOTKEY" (HW` | WINDOWS.INC(6876): `DECLARE FUNCTION UNREGISTERHOTKEY LIB "USER32" ALIAS "UNREGISTERHOTKEY" (BYVAL H` |
| DECLARE | GETMESSAGEPOS | User32.inc(102): `DECLARE FUNCTION GETMESSAGEPOS LIB "USER32.DLL" ALIAS_ "GETMESSAGEPOS" AS LONG` | WINDOWS.INC(6896): `DECLARE FUNCTION GETMESSAGEPOS LIB "USER32" ALIAS "GETMESSAGEPOS" () AS LONG` |
| DECLARE | GETMESSAGETIME | User32.inc(108): `DECLARE FUNCTION GETMESSAGETIME LIB "USER32.DLL" ALIAS_ "GETMESSAGETIME" AS LONG` | WINDOWS.INC(6897): `DECLARE FUNCTION GETMESSAGETIME LIB "USER32" ALIAS "GETMESSAGETIME" () AS LONG` |
| DECLARE | GETMESSAGEEXTRAINFO | User32.inc(96): `DECLARE FUNCTION GETMESSAGEEXTRAINFO LIB "USER32.DLL" ALIAS_ "GETMESSAGEEXTRAINF` | WINDOWS.INC(6898): `DECLARE FUNCTION GETMESSAGEEXTRAINFO LIB "USER32" ALIAS "GETMESSAGEEXTRAINFO" ()` |
| DECLARE | SENDMESSAGEAPI | rapidq2.inc(980): `DECLARE FUNCTION SENDMESSAGEAPI LIB "USER32" ALIAS "SENDMESSAGEA" (HWND AS LONG,` | WINDOWS.INC(6900): `DECLARE FUNCTION SENDMESSAGEAPI LIB "USER32" ALIAS "SENDMESSAGEA" (BYVAL HWND AS` |
| TYPE | WNDCLASS | WIN32API.INC(6689): `TYPE WNDCLASS STYLE AS LONG LPFNWNDPROC AS LONG CBCLSEXTRA AS LONG CBWNDEXTRA2 A` | WINDOWS.INC(6911): `TYPE WNDCLASS STYLE AS LONG LPFNWNDPROC AS LONG CBCLSEXTRA AS LONG CBWNDEXTRA2 A` |
| DECLARE | DEFWINDOWPROC | rapidq2.inc(1042): `DECLARE FUNCTION DEFWINDOWPROC LIB "USER32" ALIAS "DEFWINDOWPROCA" (HWND AS LONG` | WINDOWS.INC(6928): `DECLARE FUNCTION DEFWINDOWPROC LIB "USER32" ALIAS "DEFWINDOWPROCA" (BYVAL HWND A` |
| DECLARE | GETDOUBLECLICKTIME | User32.inc(60): `DECLARE FUNCTION GETDOUBLECLICKTIME LIB "USER32.DLL" ALIAS_ "GETDOUBLECLICKTIME"` | WINDOWS.INC(6932): `DECLARE FUNCTION GETDOUBLECLICKTIME LIB "USER32" ALIAS "GETDOUBLECLICKTIME" () A` |
| DECLARE | CREATEWINDOWEX | rapidq2.inc(987): `DECLARE FUNCTION CREATEWINDOWEX LIB "USER32" ALIAS "CREATEWINDOWEXA" (DWEXSTYLE ` | WINDOWS.INC(6941): `DECLARE FUNCTION CREATEWINDOWEX LIB "USER32" ALIAS "CREATEWINDOWEXA"_ (BYVAL DWE` |
| DECLARE | SHOWWINDOW | rapidq2.inc(1017): `DECLARE FUNCTION SHOWWINDOW LIB "USER32" ALIAS "SHOWWINDOW" (HWND AS LONG,NCMDSH` | WINDOWS.INC(6952): `DECLARE FUNCTION SHOWWINDOW LIB "USER32" ALIAS "SHOWWINDOW" (BYVAL HWND AS LONG,` |
| DECLARE | MOVEWINDOW | rapidq2.inc(993): `DECLARE FUNCTION MOVEWINDOW LIB "USER32" ALIAS "MOVEWINDOW" (HWND AS LONG,X AS L` | WINDOWS.INC(6958): `DECLARE FUNCTION MOVEWINDOW LIB "USER32" ALIAS "MOVEWINDOW" (BYVAL HWND AS LONG,` |
| DECLARE | SETWINDOWPOS | rapidq2.inc(1029): `DECLARE SUB SETWINDOWPOS LIB "USER32" ALIAS "SETWINDOWPOS"_ (BYVAL HWND AS LONG,` | WINDOWS.INC(6959): `DECLARE FUNCTION SETWINDOWPOS LIB "USER32" ALIAS "SETWINDOWPOS" (BYVAL HWND AS L` |
| DECLARE | GETWINDOWPLACEMENT | Form.inc(45): `PRIVATE DECLARE FUNCTION GETWINDOWPLACEMENT LIB "USER32" ALIAS "GETWINDOWPLACEME` | WINDOWS.INC(6960): `DECLARE FUNCTION GETWINDOWPLACEMENT LIB "USER32" ALIAS "GETWINDOWPLACEMENT" (BYV` |
| DECLARE | SETWINDOWPLACEMENT | Form.inc(47): `PRIVATE DECLARE FUNCTION SETWINDOWPLACEMENT LIB "USER32" ALIAS "SETWINDOWPLACEME` | WINDOWS.INC(6961): `DECLARE FUNCTION SETWINDOWPLACEMENT LIB "USER32" ALIAS "SETWINDOWPLACEMENT" (BYV` |
| TYPE | DLGTEMPLATE | WIN32API.INC(6767): `TYPE DLGTEMPLATE STYLE AS LONG DWEXTENDEDSTYLE AS LONG CDIT AS INTEGER X AS INTE` | WINDOWS.INC(6996): `TYPE DLGTEMPLATE STYLE AS LONG DWEXTENDEDSTYLE AS LONG CDIT AS WORD X AS WORD Y ` |
| TYPE | DLGITEMTEMPLATE | WIN32API.INC(6777): `TYPE DLGITEMTEMPLATE STYLE AS LONG DWEXTENDEDSTYLE AS LONG X AS INTEGER Y AS INT` | WINDOWS.INC(7006): `TYPE DLGITEMTEMPLATE STYLE AS LONG DWEXTENDEDSTYLE AS LONG X AS WORD Y AS WORD C` |
| DECLARE | GETDIALOGBASEUNITS | User32.inc(54): `DECLARE FUNCTION GETDIALOGBASEUNITS LIB "USER32.DLL" ALIAS_ "GETDIALOGBASEUNITS"` | WINDOWS.INC(7029): `DECLARE FUNCTION GETDIALOGBASEUNITS LIB "USER32" ALIAS "GETDIALOGBASEUNITS" () A` |
| DECLARE | GETOPENCLIPBOARDWINDOW | User32.inc(114): `DECLARE FUNCTION GETOPENCLIPBOARDWINDOW LIB "USER32.DLL" ALIAS_ "GETOPENCLIPBOAR` | WINDOWS.INC(7052): `DECLARE FUNCTION GETOPENCLIPBOARDWINDOW LIB "USER32" ALIAS "GETOPENCLIPBOARDWIND` |
| DECLARE | CHARTOOEM | conversion.inc(60): `DECLARE FUNCTION CHARTOOEM LIB "USER32" ALIAS "CHARTOOEMA" _ (BYVAL LPSZSRC AS S` | WINDOWS.INC(7053): `DECLARE FUNCTION CHARTOOEM LIB "USER32" ALIAS "CHARTOOEMA" (BYVAL LPSZSRC AS STR` |
| DECLARE | OEMTOCHAR | conversion.inc(66): `DECLARE FUNCTION OEMTOCHAR LIB "USER32" ALIAS "OEMTOCHARA" _ (BYVAL LPSZSRC AS S` | WINDOWS.INC(7054): `DECLARE FUNCTION OEMTOCHAR LIB "USER32" ALIAS "OEMTOCHARA" (BYVAL LPSZSRC AS STR` |
| DECLARE | ISCHARALPHA | WIN32API.INC(6836): `DECLARE FUNCTION ISCHARALPHA LIB "USER32" ALIAS "ISCHARALPHAA" (BYVAL CCHAR AS B` | WINDOWS.INC(7065): `DECLARE FUNCTION ISCHARALPHA LIB "USER32" ALIAS "ISCHARALPHAA" (BYVAL CCHAR AS L` |
| DECLARE | ISCHARALPHANUMERIC | WIN32API.INC(6837): `DECLARE FUNCTION ISCHARALPHANUMERIC LIB "USER32" ALIAS "ISCHARALPHANUMERICA" (BY` | WINDOWS.INC(7066): `DECLARE FUNCTION ISCHARALPHANUMERIC LIB "USER32" ALIAS "ISCHARALPHANUMERICA" (BY` |
| DECLARE | ISCHARUPPER | WIN32API.INC(6838): `DECLARE FUNCTION ISCHARUPPER LIB "USER32" ALIAS "ISCHARUPPERA" (BYVAL CCHAR AS B` | WINDOWS.INC(7067): `DECLARE FUNCTION ISCHARUPPER LIB "USER32" ALIAS "ISCHARUPPERA" (BYVAL CCHAR AS L` |
| DECLARE | ISCHARLOWER | WIN32API.INC(6839): `DECLARE FUNCTION ISCHARLOWER LIB "USER32" ALIAS "ISCHARLOWERA" (BYVAL CCHAR AS B` | WINDOWS.INC(7068): `DECLARE FUNCTION ISCHARLOWER LIB "USER32" ALIAS "ISCHARLOWERA" (BYVAL CCHAR AS L` |
| DECLARE | SETFOCUS | rapidq2.inc(1010): `DECLARE FUNCTION SETFOCUS LIB "USER32" ALIAS "SETFOCUS" (HWND AS LONG) AS LONG` | WINDOWS.INC(7070): `DECLARE FUNCTION SETFOCUS LIB "USER32" ALIAS "SETFOCUS" (BYVAL HWND AS LONG) AS ` |
| DECLARE | GETFOCUS | rapidq2.inc(994): `DECLARE FUNCTION GETFOCUS LIB "USER32" ALIAS "GETFOCUS"() AS LONG` | WINDOWS.INC(7071): `DECLARE FUNCTION GETFOCUS LIB "USER32" ALIAS "GETFOCUS" () AS LONG` |
| DECLARE | GETACTIVEWINDOW | User32.inc(23): `DECLARE FUNCTION GETACTIVEWINDOW LIB "USER32.DLL" ALIAS_ "GETACTIVEWINDOW" AS LO` | WINDOWS.INC(7072): `DECLARE FUNCTION GETACTIVEWINDOW LIB "USER32" ALIAS "GETACTIVEWINDOW" () AS LONG` |
| DECLARE | GETKBCODEPAGE | User32.inc(84): `DECLARE FUNCTION GETKBCODEPAGE LIB "USER32.DLL" ALIAS_ "GETKBCODEPAGE" AS LONG` | WINDOWS.INC(7075): `DECLARE FUNCTION GETKBCODEPAGE LIB "USER32" ALIAS "GETKBCODEPAGE" () AS LONG` |
| DECLARE | GETKEYBOARDSTATE | WIN32API.INC(6849): `DECLARE FUNCTION GETKEYBOARDSTATE LIB "USER32" ALIAS "GETKEYBOARDSTATE" (PBKEYST` | WINDOWS.INC(7078): `DECLARE FUNCTION GETKEYBOARDSTATE LIB "USER32" ALIAS "GETKEYBOARDSTATE" (BYREF P` |
| DECLARE | TOASCII | WIN32API.INC(6854): `DECLARE FUNCTION TOASCII LIB "USER32" ALIAS "TOASCII" (BYVAL UVIRTKEY AS LONG, B` | WINDOWS.INC(7082): `DECLARE FUNCTION TOASCII LIB "USER32" ALIAS "TOASCII" (BYVAL UVIRTKEY AS LONG, B` |
| DECLARE | TOUNICODE | WIN32API.INC(6855): `DECLARE FUNCTION TOUNICODE LIB "USER32" ALIAS "TOUNICODE" (BYVAL WVIRTKEY AS LON` | WINDOWS.INC(7083): `DECLARE FUNCTION TOUNICODE LIB "USER32" ALIAS "TOUNICODE" (BYVAL WVIRTKEY AS LON` |
| DECLARE | VKKEYSCAN | WIN32API.INC(6858): `DECLARE FUNCTION VKKEYSCAN LIB "USER32" ALIAS "VKKEYSCANA" (BYVAL CCHAR AS BYTE)` | WINDOWS.INC(7086): `DECLARE FUNCTION VKKEYSCAN LIB "USER32" ALIAS "VKKEYSCANA" (BYVAL CCHAR AS LONG)` |
| DECLARE | KEYBD_EVENT | WIN32API.INC(6863): `DECLARE SUB KEYBD_EVENT LIB "USER32" ALIAS "KEYBD_EVENT" (BYVAL BVK AS BYTE, BYV` | WINDOWS.INC(7091): `DECLARE SUB KEYBD_EVENT LIB "USER32" ALIAS "KEYBD_EVENT" (BVK AS LONG, BSCAN AS ` |
| DECLARE | MOUSE_EVENT | QFormSkin.inc(723): `DECLARE SUB MOUSE_EVENT LIB "USER32" ALIAS "MOUSE_EVENT" ( _ BYVAL DWFLAGS AS LO` | WINDOWS.INC(7102): `DECLARE SUB MOUSE_EVENT LIB "USER32" ALIAS "MOUSE_EVENT" (BYVAL DWFLAGS AS LONG,` |
| DECLARE | GETINPUTSTATE | User32.inc(78): `DECLARE FUNCTION GETINPUTSTATE LIB "USER32.DLL" ALIAS_ "GETINPUTSTATE" AS LONG` | WINDOWS.INC(7105): `DECLARE FUNCTION GETINPUTSTATE LIB "USER32" ALIAS "GETINPUTSTATE" () AS LONG` |
| DECLARE | SETCAPTURE | rapidq2.inc(1008): `DECLARE FUNCTION SETCAPTURE LIB "USER32" ALIAS "SETCAPTURE" (HWND AS LONG) AS LO` | WINDOWS.INC(7108): `DECLARE FUNCTION SETCAPTURE LIB "USER32" ALIAS "SETCAPTURE" (BYVAL HWND AS LONG)` |
| DECLARE | GETMENU | rapidq2.inc(1603): `DECLARE FUNCTION GETMENU LIB "USER32" ALIAS "GETMENU" (HWND AS LONG) AS LONG` | WINDOWS.INC(7223): `DECLARE FUNCTION GETMENU LIB "USER32" ALIAS "GETMENU" (BYVAL HWND AS LONG) AS LO` |
| DECLARE | MODIFYMENU | rapidq2.inc(1607): `DECLARE FUNCTION MODIFYMENU LIB "USER32" ALIAS "MODIFYMENUA" (HMENU AS LONG,UPOS` | WINDOWS.INC(7241): `DECLARE FUNCTION MODIFYMENU LIB "USER32" ALIAS "MODIFYMENUA" (BYVAL HMENU AS LON` |
| DECLARE | GETMENUCHECKMARKDIMENSIONS | User32.inc(90): `DECLARE FUNCTION GETMENUCHECKMARKDIMENSIONS LIB "USER32.DLL" ALIAS_ "GETMENUCHEC` | WINDOWS.INC(7245): `DECLARE FUNCTION GETMENUCHECKMARKDIMENSIONS LIB "USER32" ALIAS "GETMENUCHECKMARK` |
| DECLARE | DRAWICON | QFormSkin.inc(202): `DECLARE FUNCTION DRAWICON LIB "USER32" ALIAS "DRAWICON" (_ BYVAL HDC AS LONG, _ ` | WINDOWS.INC(7256): `DECLARE FUNCTION DRAWICON LIB "USER32" ALIAS "DRAWICON" (BYVAL HDC AS LONG, BYVA` |
| DECLARE | DRAWTEXT | QFormSkin.inc(223): `DECLARE FUNCTION DRAWTEXT LIB "USER32" ALIAS "DRAWTEXTA" ( _ BYVAL HDC AS LONG, ` | WINDOWS.INC(7277): `DECLARE FUNCTION DRAWTEXT LIB "USER32" ALIAS "DRAWTEXTA" (BYVAL HDC AS LONG, BYV` |
| DECLARE | SETACTIVEWINDOW | rapidq2.inc(1484): `DECLARE FUNCTION SETACTIVEWINDOW LIB "USER32" ALIAS "SETACTIVEWINDOW" (HWND AS I` | WINDOWS.INC(7282): `DECLARE FUNCTION SETACTIVEWINDOW LIB "USER32" ALIAS "SETACTIVEWINDOW" (BYVAL HWN` |
| DECLARE | GETFOREGROUNDWINDOW | User32.inc(72): `DECLARE FUNCTION GETFOREGROUNDWINDOW LIB "USER32.DLL" ALIAS_ "GETFOREGROUNDWINDO` | WINDOWS.INC(7283): `DECLARE FUNCTION GETFOREGROUNDWINDOW LIB "USER32" ALIAS "GETFOREGROUNDWINDOW" ()` |
| DECLARE | GETDC | rapidq2.inc(1482): `DECLARE FUNCTION GETDC LIB "USER32.DLL" ALIAS "GETDC"(BYVAL HWND AS LONG) AS LON` | WINDOWS.INC(7287): `DECLARE FUNCTION GETDC LIB "USER32" ALIAS "GETDC" (BYVAL HWND AS LONG) AS LONG` |
| DECLARE | GETWINDOWDC | QFormSkin.inc(171): `DECLARE FUNCTION GETWINDOWDC LIB "USER32" ALIAS "GETWINDOWDC" _ (HWND AS LONG) A` | WINDOWS.INC(7308): `DECLARE FUNCTION GETWINDOWDC LIB "USER32" ALIAS "GETWINDOWDC" (BYVAL HWND AS LON` |
| DECLARE | RELEASEDC | rapidq2.inc(1483): `DECLARE FUNCTION RELEASEDC LIB "USER32.DLL" ALIAS "RELEASEDC"(BYVAL HWND AS LONG` | WINDOWS.INC(7309): `DECLARE FUNCTION RELEASEDC LIB "USER32" ALIAS "RELEASEDC" (BYVAL HWND AS LONG, B` |
| DECLARE | EXCLUDEUPDATERGN | QFormSkin.inc(239): `DECLARE FUNCTION EXCLUDEUPDATERGN LIB "USER32.DLL" ALIAS "EXCLUDEUPDATERGN" ( _ ` | WINDOWS.INC(7315): `DECLARE FUNCTION EXCLUDEUPDATERGN LIB "USER32" ALIAS "EXCLUDEUPDATERGN" (BYVAL H` |
| DECLARE | SETPROP | rapidq2.inc(990): `DECLARE FUNCTION SETPROP LIB "USER32" ALIAS "SETPROPA" (HWND AS LONG,LPSTRING AS` | WINDOWS.INC(7370): `DECLARE FUNCTION SETPROP LIB "USER32" ALIAS "SETPROPA" (BYVAL HWND AS LONG, BYVA` |
| DECLARE | GETPROP | rapidq2.inc(991): `DECLARE FUNCTION GETPROP LIB "USER32" ALIAS "GETPROPA" (HWND AS LONG,LPSTRING AS` | WINDOWS.INC(7371): `DECLARE FUNCTION GETPROP LIB "USER32" ALIAS "GETPROPA" (BYVAL HWND AS LONG, BYVA` |
| DECLARE | SETWINDOWTEXT | rapidq2.inc(1013): `DECLARE FUNCTION SETWINDOWTEXT LIB "USER32" ALIAS "SETWINDOWTEXTA" (BYVAL HWND A` | WINDOWS.INC(7374): `DECLARE FUNCTION SETWINDOWTEXT LIB "USER32" ALIAS "SETWINDOWTEXTA" (BYVAL HWND A` |
| DECLARE | GETWINDOWTEXT | rapidq2.inc(997): `DECLARE FUNCTION GETWINDOWTEXT LIB "USER32" ALIAS "GETWINDOWTEXTA" (BYVAL HWND A` | WINDOWS.INC(7375): `DECLARE FUNCTION GETWINDOWTEXT LIB "USER32" ALIAS "GETWINDOWTEXTA" (BYVAL HWND A` |
| DECLARE | SETCURSOR | QFormSkin.inc(247): `DECLARE FUNCTION SETCURSOR LIB "USER32" ALIAS "SETCURSOR" (BYVAL HCURSOR AS LONG` | WINDOWS.INC(7423): `DECLARE FUNCTION SETCURSOR LIB "USER32" ALIAS "SETCURSOR" (BYVAL HCURSOR AS LONG` |
| DECLARE | GETCURSOR | User32.inc(42): `DECLARE FUNCTION GETCURSOR LIB "USER32.DLL" ALIAS_ "GETCURSOR" AS LONG` | WINDOWS.INC(7426): `DECLARE FUNCTION GETCURSOR LIB "USER32" ALIAS "GETCURSOR" () AS LONG` |
| DECLARE | GETSYSCOLOR | rapidq2.inc(1602): `DECLARE FUNCTION GETSYSCOLOR LIB "USER32" ALIAS "GETSYSCOLOR" (NINDEX AS LONG) A` | WINDOWS.INC(7477): `DECLARE FUNCTION GETSYSCOLOR LIB "USER32" ALIAS "GETSYSCOLOR" (BYVAL NINDEX AS L` |
| DECLARE | SETRECT | QFormSkin.inc(146): `DECLARE FUNCTION SETRECT LIB "USER32" ALIAS "SETRECT" ( _ LPRECT AS RECT, _ BYVA` | WINDOWS.INC(7484): `DECLARE FUNCTION SETRECT LIB "USER32" ALIAS "SETRECT" (LPRECT AS RECT, BYVAL X1 ` |
| DECLARE | GETWINDOWLONG | rapidq2.inc(1037): `DECLARE FUNCTION GETWINDOWLONG LIB "USER32" ALIAS "GETWINDOWLONGA" (HWND AS LONG` | WINDOWS.INC(7498): `DECLARE FUNCTION GETWINDOWLONG LIB "USER32" ALIAS "GETWINDOWLONGA" (BYVAL HWND A` |
| DECLARE | SETWINDOWLONG | rapidq2.inc(1039): `DECLARE FUNCTION SETWINDOWLONG LIB "USER32" ALIAS "SETWINDOWLONGA" (HWND AS LONG` | WINDOWS.INC(7499): `DECLARE FUNCTION SETWINDOWLONG LIB "USER32" ALIAS "SETWINDOWLONGA" (BYVAL HWND A` |
| DECLARE | SETCLASSLONG | rapidq2.inc(1009): `DECLARE FUNCTION SETCLASSLONG LIB "USER32" ALIAS "SETCLASSLONGA" (HWND AS LONG,N` | WINDOWS.INC(7503): `DECLARE FUNCTION SETCLASSLONG LIB "USER32" ALIAS "SETCLASSLONGA" (BYVAL HWND AS ` |
| DECLARE | GETPARENT | rapidq2.inc(995): `DECLARE FUNCTION GETPARENT LIB "USER32" ALIAS "GETPARENT" (HWND AS LONG) AS LONG` | WINDOWS.INC(7506): `DECLARE FUNCTION GETPARENT LIB "USER32" ALIAS "GETPARENT" (BYVAL HWND AS LONG) A` |
| DECLARE | SETPARENT | rapidq2.inc(1011): `DECLARE FUNCTION SETPARENT LIB "USER32" ALIAS "SETPARENT" (HWNDCHILD AS LONG,HWN` | WINDOWS.INC(7507): `DECLARE FUNCTION SETPARENT LIB "USER32" ALIAS "SETPARENT" (BYVAL HWNDCHILD AS LO` |
| DECLARE | FINDWINDOW | User32.inc(17): `DECLARE FUNCTION FINDWINDOW LIB "USER32.DLL" ALIAS_ "FINDWINDOWA" (LPCLASSNAME A` | WINDOWS.INC(7508): `DECLARE FUNCTION FINDWINDOW LIB "USER32" ALIAS "FINDWINDOWA" (BYVAL LPCLASSNAME ` |
| DECLARE | GETCLASSNAME | rapidq2.inc(989): `DECLARE FUNCTION GETCLASSNAME LIB "USER32" ALIAS "GETCLASSNAMEA" (HWND AS LONG, ` | WINDOWS.INC(7510): `DECLARE FUNCTION GETCLASSNAME LIB "USER32" ALIAS "GETCLASSNAMEA" (BYVAL HWND AS ` |
| DECLARE | GETNEXTWINDOW | WIN32API.INC(7258): `DECLARE FUNCTION GETNEXTWINDOW LIB "USER32" ALIAS "GETWINDOW" (BYVAL HWND AS LON` | WINDOWS.INC(7512): `DECLARE FUNCTION GETNEXTWINDOW LIB "USER32" ALIAS "GETNEXTWINDOW" (BYVAL HWND AS` |
| TYPE | MENUITEMTEMPLATEHEADER | WIN32API.INC(7313): `TYPE MENUITEMTEMPLATEHEADER VERSIONNUMBER AS INTEGER OFFSET AS INTEGER END TYPE` | WINDOWS.INC(7567): `TYPE MENUITEMTEMPLATEHEADER VERSIONNUMBER AS WORD OFFSET AS WORD END TYPE` |
| TYPE | MENUITEMTEMPLATE | WIN32API.INC(7318): `TYPE MENUITEMTEMPLATE MTOPTION AS INTEGER MTID AS INTEGER MTSTRING AS BYTE END T` | WINDOWS.INC(7572): `TYPE MENUITEMTEMPLATE MTOPTION AS WORD MTID AS WORD MTSTRING AS BYTE END TYPE` |
| DECLARE | LOADCURSOR | QFormSkin.inc(249): `DECLARE FUNCTION LOADCURSOR LIB "USER32" ALIAS "LOADCURSORA" _ (BYVAL HINSTANCE ` | WINDOWS.INC(7613): `DECLARE FUNCTION LOADCURSOR LIB "USER32" ALIAS "LOADCURSORA" (BYVAL HINSTANCE AS` |
| DECLARE | CREATEICON | WIN32API.INC(7380): `DECLARE FUNCTION CREATEICON LIB "USER32" ALIAS "CREATEICON" (BYVAL HINSTANCE AS ` | WINDOWS.INC(7643): `DECLARE FUNCTION CREATEICON LIB "USER32" ALIAS "CREATEICON" (BYVAL HINSTANCE AS ` |
| DECLARE | DESTROYICON | QFormSkin.inc(215): `DECLARE FUNCTION DESTROYICON LIB "USER32" ALIAS "DESTROYICON" ( _ BYVAL HICON AS` | WINDOWS.INC(7644): `DECLARE FUNCTION DESTROYICON LIB "USER32" ALIAS "DESTROYICON" (BYVAL HICON AS LO` |
| DECLARE | LOOKUPICONIDFROMDIRECTORY | WIN32API.INC(7382): `DECLARE FUNCTION LOOKUPICONIDFROMDIRECTORY LIB "USER32" ALIAS "LOOKUPICONIDFROMD` | WINDOWS.INC(7645): `DECLARE FUNCTION LOOKUPICONIDFROMDIRECTORY LIB "USER32" ALIAS "LOOKUPICONIDFROMD` |
| DECLARE | CREATEICONFROMRESOURCE | WIN32API.INC(7383): `DECLARE FUNCTION CREATEICONFROMRESOURCE LIB "USER32" ALIAS "CREATEICONFROMRESOUR` | WINDOWS.INC(7646): `DECLARE FUNCTION CREATEICONFROMRESOURCE LIB "USER32" ALIAS "CREATEICONFROMRESOUR` |
| CONST | LBS_STANDARD | Win32_constants.inc(138): `CONST LBS_STANDARD = &HA00003` | WINDOWS.INC(7976): `PUBLIC CONST LBS_STANDARD = (LBS_NOTIFY OR LBS_SORT OR WS_VSCROLL OR WS_BORDER)` |
| DECLARE | DEFMDICHILDPROC | rapidq2.inc(988): `DECLARE FUNCTION DEFMDICHILDPROC LIB "USER32" ALIAS "DEFMDICHILDPROCA" (HWND AS ` | WINDOWS.INC(8083): `DECLARE FUNCTION DEFMDICHILDPROC LIB "USER32" ALIAS "DEFMDICHILDPROCA" (BYVAL HW` |
| DECLARE | SYSTEMPARAMETERSINFO | rapidq2.inc(1485): `DECLARE FUNCTION SYSTEMPARAMETERSINFO LIB "USER32" ALIAS "SYSTEMPARAMETERSINFOA"` | WINDOWS.INC(8223): `DECLARE FUNCTION SYSTEMPARAMETERSINFO LIB "USER32" ALIAS "SYSTEMPARAMETERSINFOA"` |
| TYPE | DDEACK | WIN32API.INC(7991): `TYPE DDEACK BAPPRETURNCODE AS INTEGER RESERVED AS INTEGER FBUSY AS INTEGER FACK ` | WINDOWS.INC(8255): `TYPE DDEACK BAPPRETURNCODE AS WORD RESERVED AS WORD FBUSY AS WORD FACK AS WORD E` |
| TYPE | DDEADVISE | WIN32API.INC(8005): `TYPE DDEADVISE RESERVED AS INTEGER FDEFERUPD AS INTEGER FACKREQ AS INTEGER CFFOR` | WINDOWS.INC(8269): `TYPE DDEADVISE RESERVED AS WORD FDEFERUPD AS WORD FACKREQ AS WORD CFFORMAT AS WO` |
| TYPE | DDEDATA | WIN32API.INC(8022): `TYPE DDEDATA UNUSED AS INTEGER FRESPONSE AS INTEGER FRELEASE AS INTEGER RESERVED` | WINDOWS.INC(8286): `TYPE DDEDATA UNUSED AS WORD FRESPONSE AS WORD FRELEASE AS WORD RESERVED AS WORD ` |
| TYPE | DDEPOKE | WIN32API.INC(8042): `TYPE DDEPOKE UNUSED AS INTEGER FRELEASE AS INTEGER FRESERVED AS INTEGER CFFORMAT` | WINDOWS.INC(8306): `TYPE DDEPOKE UNUSED AS WORD FRELEASE AS WORD FRESERVED AS WORD CFFORMAT AS WORD ` |
| TYPE | DDELN | WIN32API.INC(8060): `TYPE DDELN UNUSED AS INTEGER FRELEASE AS INTEGER FDEFERUPD AS INTEGER FACKREQ AS` | WINDOWS.INC(8324): `TYPE DDELN UNUSED AS WORD FRELEASE AS WORD FDEFERUPD AS WORD FACKREQ AS WORD CFF` |
| TYPE | DDEUP | WIN32API.INC(8068): `TYPE DDEUP UNUSED AS INTEGER FACK AS INTEGER FRELEASE AS INTEGER FRESERVED AS IN` | WINDOWS.INC(8332): `TYPE DDEUP UNUSED AS WORD FACK AS WORD FRELEASE AS WORD FRESERVED AS WORD FACKRE` |
| DECLARE | DDECLIENTTRANSACTION | WIN32API.INC(8283): `DECLARE FUNCTION DDECLIENTTRANSACTION LIB "USER32" ALIAS "DDECLIENTTRANSACTION" ` | WINDOWS.INC(8547): `DECLARE FUNCTION DDECLIENTTRANSACTION LIB "USER32" ALIAS "DDECLIENTTRANSACTION" ` |
| DECLARE | DDECREATEDATAHANDLE | WIN32API.INC(8286): `DECLARE FUNCTION DDECREATEDATAHANDLE LIB "USER32" ALIAS "DDECREATEDATAHANDLE" (B` | WINDOWS.INC(8550): `DECLARE FUNCTION DDECREATEDATAHANDLE LIB "USER32" ALIAS "DDECREATEDATAHANDLE" (B` |
| DECLARE | DDEADDDATA | WIN32API.INC(8287): `DECLARE FUNCTION DDEADDDATA LIB "USER32" ALIAS "DDEADDDATAA" (BYVAL HDATA AS LON` | WINDOWS.INC(8551): `DECLARE FUNCTION DDEADDDATA LIB "USER32" ALIAS "DDEADDDATAA" (BYVAL HDATA AS LON` |
| DECLARE | DDEGETDATA | WIN32API.INC(8288): `DECLARE FUNCTION DDEGETDATA LIB "USER32" ALIAS "DDEGETDATAA" (BYVAL HDATA AS LON` | WINDOWS.INC(8552): `DECLARE FUNCTION DDEGETDATA LIB "USER32" ALIAS "DDEGETDATAA" (BYVAL HDATA AS LON` |
| TYPE | MIXERCAPS | WIN32API.INC(10874): `TYPE MIXERCAPS WMID AS INTEGER WPID AS INTEGER VDRIVERVERSION AS LONG SZPNAME AS` | WINDOWS.INC(11140): `TYPE MIXERCAPS WMID AS WORD WPID AS WORD VDRIVERVERSION AS LONG SZPNAME AS STRIN` |
| TYPE | TARGET | WIN32API.INC(10888): `TYPE TARGET DWTYPE AS LONG DWDEVICEID AS LONG WMID AS INTEGER WPID AS INTEGER VD` | WINDOWS.INC(11154): `TYPE TARGET DWTYPE AS LONG DWDEVICEID AS LONG WMID AS WORD WPID AS WORD VDRIVERV` |
| TYPE | JOYCAPS | WIN32API.INC(11648): `TYPE JOYCAPS WMID AS INTEGER WPID AS INTEGER SZPNAME AS STRING * MAXPNAMELEN WXM` | WINDOWS.INC(11464): `TYPE JOYCAPS WMID AS WORD WPID AS WORD SZPNAME AS STRING * MAXPNAMELEN WXMIN AS ` |
| TYPE | WAVEOUTCAPS | WIN32API.INC(11367): `TYPE WAVEOUTCAPS WMID AS INTEGER WPID AS INTEGER VDRIVERVERSION AS LONG SZPNAME ` | WINDOWS.INC(11666): `TYPE WAVEOUTCAPS WMID AS WORD WPID AS WORD VDRIVERVERSION AS LONG SZPNAME AS STR` |
| TYPE | WAVEINCAPS | WIN32API.INC(11384): `TYPE WAVEINCAPS WMID AS INTEGER WPID AS INTEGER VDRIVERVERSION AS LONG SZPNAME A` | WINDOWS.INC(11683): `TYPE WAVEINCAPS WMID AS WORD WPID AS WORD VDRIVERVERSION AS LONG SZPNAME AS STRI` |
| TYPE | WAVEFORMAT | WIN32API.INC(11411): `TYPE WAVEFORMAT WFORMATTAG AS INTEGER NCHANNELS AS INTEGER NSAMPLESPERSEC AS LON` | WINDOWS.INC(11710): `TYPE WAVEFORMAT WFORMATTAG AS WORD NCHANNELS AS WORD NSAMPLESPERSEC AS LONG NAVG` |
| TYPE | PCMWAVEFORMAT | WIN32API.INC(11419): `TYPE PCMWAVEFORMAT WF AS WAVEFORMAT WBITSPERSAMPLE AS INTEGER END TYPE` | WINDOWS.INC(11718): `TYPE PCMWAVEFORMAT WF AS WAVEFORMAT WBITSPERSAMPLE AS WORD END TYPE` |
| TYPE | MIDIOUTCAPS | WIN32API.INC(11497): `TYPE MIDIOUTCAPS WMID AS INTEGER WPID AS INTEGER VDRIVERVERSION AS LONG SZPNAME ` | WINDOWS.INC(11795): `TYPE MIDIOUTCAPS WMID AS WORD WPID AS WORD VDRIVERVERSION AS LONG SZPNAME AS STR` |
| TYPE | MIDIINCAPS | WIN32API.INC(11521): `TYPE MIDIINCAPS WMID AS INTEGER WPID AS INTEGER VDRIVERVERSION AS LONG SZPNAME A` | WINDOWS.INC(11819): `TYPE MIDIINCAPS WMID AS WORD WPID AS WORD VDRIVERVERSION AS LONG SZPNAME AS STRI` |
| DECLARE | MIDISTREAMPROPERTY | WIN32API.INC(11193): `DECLARE FUNCTION MIDISTREAMPROPERTY LIB "WINMM.DLL" ALIAS "MIDISTREAMPROPERTY" (` | WINDOWS.INC(11895): `DECLARE FUNCTION MIDISTREAMPROPERTY LIB "WINMM.DLL" ALIAS "MIDISTREAMPROPERTY" (` |
| TYPE | AUXCAPS | WIN32API.INC(11582): `TYPE AUXCAPS WMID AS INTEGER WPID AS INTEGER VDRIVERVERSION AS LONG SZPNAME AS S` | WINDOWS.INC(11908): `TYPE AUXCAPS WMID AS WORD WPID AS WORD VDRIVERVERSION AS LONG SZPNAME AS STRING ` |
| TYPE | MCI_STATUS_PARMS | WIN32API.INC(12109): `TYPE MCI_STATUS_PARMS DWCALLBACK AS LONG DWRETURN AS LONG DWITEM AS LONG DWTRACK` | WINDOWS.INC(12384): `TYPE MCI_STATUS_PARMS DWCALLBACK AS LONG DWRETURN AS LONG DWITEM AS LONG DWTRACK` |
| TYPE | MCI_WAVE_SET_PARMS | WIN32API.INC(12285): `TYPE MCI_WAVE_SET_PARMS DWCALLBACK AS LONG DWTIMEFORMAT AS LONG DWAUDIO AS LONG ` | WINDOWS.INC(12560): `TYPE MCI_WAVE_SET_PARMS DWCALLBACK AS LONG DWTIMEFORMAT AS LONG DWAUDIO AS LONG ` |
| DECLARE | ENUMPRINTERS | WIN32API.INC(12797): `DECLARE FUNCTION ENUMPRINTERS LIB "WINSPOOL.DRV" ALIAS "ENUMPRINTERSA" (BYVAL FL` | WINDOWS.INC(13072): `DECLARE FUNCTION ENUMPRINTERS LIB "WINSPOOL.DRV" ALIAS "ENUMPRINTERSA" (BYVAL FL` |
| DECLARE | SETJOB | WIN32API.INC(12825): `DECLARE FUNCTION SETJOB LIB "WINSPOOL.DRV" ALIAS "SETJOBA" (BYVAL HPRINTER AS LO` | WINDOWS.INC(13100): `DECLARE FUNCTION SETJOB LIB "WINSPOOL.DRV" ALIAS "SETJOBA" (BYVAL HPRINTER AS LO` |
| DECLARE | GETJOB | WIN32API.INC(12826): `DECLARE FUNCTION GETJOB LIB "WINSPOOL.DRV" ALIAS "GETJOBA" (BYVAL HPRINTER AS LO` | WINDOWS.INC(13101): `DECLARE FUNCTION GETJOB LIB "WINSPOOL.DRV" ALIAS "GETJOBA" (BYVAL HPRINTER AS LO` |
| DECLARE | ENUMJOBS | WIN32API.INC(12827): `DECLARE FUNCTION ENUMJOBS LIB "WINSPOOL.DRV" ALIAS "ENUMJOBSA" (BYVAL HPRINTER A` | WINDOWS.INC(13102): `DECLARE FUNCTION ENUMJOBS LIB "WINSPOOL.DRV" ALIAS "ENUMJOBSA" (BYVAL HPRINTER A` |
| DECLARE | ENUMPRINTERDRIVERS | WIN32API.INC(12832): `DECLARE FUNCTION ENUMPRINTERDRIVERS LIB "WINSPOOL.DRV" ALIAS "ENUMPRINTERDRIVERS` | WINDOWS.INC(13107): `DECLARE FUNCTION ENUMPRINTERDRIVERS LIB "WINSPOOL.DRV" ALIAS "ENUMPRINTERDRIVERS` |
| DECLARE | GETPRINTERDRIVER | WIN32API.INC(12833): `DECLARE FUNCTION GETPRINTERDRIVER LIB "WINSPOOL.DRV" ALIAS "GETPRINTERDRIVERA" (` | WINDOWS.INC(13108): `DECLARE FUNCTION GETPRINTERDRIVER LIB "WINSPOOL.DRV" ALIAS "GETPRINTERDRIVERA" (` |
| DECLARE | GETPRINTERDRIVERDIRECTORY | WIN32API.INC(12834): `DECLARE FUNCTION GETPRINTERDRIVERDIRECTORY LIB "WINSPOOL.DRV" ALIAS "GETPRINTERD` | WINDOWS.INC(13109): `DECLARE FUNCTION GETPRINTERDRIVERDIRECTORY LIB "WINSPOOL.DRV" ALIAS "GETPRINTERD` |
| DECLARE | ENUMPRINTPROCESSORS | WIN32API.INC(12838): `DECLARE FUNCTION ENUMPRINTPROCESSORS LIB "WINSPOOL.DRV" ALIAS "ENUMPRINTPROCESSO` | WINDOWS.INC(13113): `DECLARE FUNCTION ENUMPRINTPROCESSORS LIB "WINSPOOL.DRV" ALIAS "ENUMPRINTPROCESSO` |
| DECLARE | ENUMPRINTPROCESSORDATATYPES | WIN32API.INC(12840): `DECLARE FUNCTION ENUMPRINTPROCESSORDATATYPES LIB "WINSPOOL.DRV" ALIAS "ENUMPRINT` | WINDOWS.INC(13115): `DECLARE FUNCTION ENUMPRINTPROCESSORDATATYPES LIB "WINSPOOL.DRV" ALIAS "ENUMPRINT` |
| DECLARE | STARTDOCPRINTER | WIN32API.INC(12843): `DECLARE FUNCTION STARTDOCPRINTER LIB "WINSPOOL.DRV" ALIAS "STARTDOCPRINTERA" (BY` | WINDOWS.INC(13118): `DECLARE FUNCTION STARTDOCPRINTER LIB "WINSPOOL.DRV" ALIAS "STARTDOCPRINTERA" (BY` |
| DECLARE | ADDJOB | WIN32API.INC(12851): `DECLARE FUNCTION ADDJOB LIB "WINSPOOL.DRV" ALIAS "ADDJOBA" (BYVAL HPRINTER AS LO` | WINDOWS.INC(13126): `DECLARE FUNCTION ADDJOB LIB "WINSPOOL.DRV" ALIAS "ADDJOBA" (BYVAL HPRINTER AS LO` |
| DECLARE | GETPRINTERDATA | WIN32API.INC(12857): `DECLARE FUNCTION GETPRINTERDATA LIB "WINSPOOL.DRV" ALIAS "GETPRINTERDATAA" (BYVA` | WINDOWS.INC(13132): `DECLARE FUNCTION GETPRINTERDATA LIB "WINSPOOL.DRV" ALIAS "GETPRINTERDATAA" (BYVA` |
| DECLARE | SETPRINTERDATA | WIN32API.INC(12858): `DECLARE FUNCTION SETPRINTERDATA LIB "WINSPOOL.DRV" ALIAS "SETPRINTERDATAA" (BYVA` | WINDOWS.INC(13133): `DECLARE FUNCTION SETPRINTERDATA LIB "WINSPOOL.DRV" ALIAS "SETPRINTERDATAA" (BYVA` |
| DECLARE | ADDFORM | WIN32API.INC(12898): `DECLARE FUNCTION ADDFORM LIB "WINSPOOL.DRV" ALIAS "ADDFORMA" (BYVAL HPRINTER AS ` | WINDOWS.INC(13173): `DECLARE FUNCTION ADDFORM LIB "WINSPOOL.DRV" ALIAS "ADDFORMA" (BYVAL HPRINTER AS ` |
| DECLARE | GETFORM | WIN32API.INC(12900): `DECLARE FUNCTION GETFORM LIB "WINSPOOL.DRV" ALIAS "GETFORMA" (BYVAL HPRINTER AS ` | WINDOWS.INC(13175): `DECLARE FUNCTION GETFORM LIB "WINSPOOL.DRV" ALIAS "GETFORMA" (BYVAL HPRINTER AS ` |
| DECLARE | SETFORM | WIN32API.INC(12901): `DECLARE FUNCTION SETFORM LIB "WINSPOOL.DRV" ALIAS "SETFORMA" (BYVAL HPRINTER AS ` | WINDOWS.INC(13176): `DECLARE FUNCTION SETFORM LIB "WINSPOOL.DRV" ALIAS "SETFORMA" (BYVAL HPRINTER AS ` |
| DECLARE | ENUMFORMS | WIN32API.INC(12902): `DECLARE FUNCTION ENUMFORMS LIB "WINSPOOL.DRV" ALIAS "ENUMFORMSA" (BYVAL HPRINTER` | WINDOWS.INC(13177): `DECLARE FUNCTION ENUMFORMS LIB "WINSPOOL.DRV" ALIAS "ENUMFORMSA" (BYVAL HPRINTER` |
| DECLARE | ENUMMONITORS | WIN32API.INC(12904): `DECLARE FUNCTION ENUMMONITORS LIB "WINSPOOL.DRV" ALIAS "ENUMMONITORSA" (BYVAL PN` | WINDOWS.INC(13179): `DECLARE FUNCTION ENUMMONITORS LIB "WINSPOOL.DRV" ALIAS "ENUMMONITORSA" (BYVAL PN` |
| DECLARE | ADDMONITOR | WIN32API.INC(12905): `DECLARE FUNCTION ADDMONITOR LIB "WINSPOOL.DRV" ALIAS "ADDMONITORA" (BYVAL PNAME ` | WINDOWS.INC(13180): `DECLARE FUNCTION ADDMONITOR LIB "WINSPOOL.DRV" ALIAS "ADDMONITORA" (BYVAL PNAME ` |
| DECLARE | ADDPRINTPROVIDOR | WIN32API.INC(12924): `DECLARE FUNCTION ADDPRINTPROVIDOR LIB "WINSPOOL.DRV" ALIAS "ADDPRINTPROVIDORA" (` | WINDOWS.INC(13199): `DECLARE FUNCTION ADDPRINTPROVIDOR LIB "WINSPOOL.DRV" ALIAS "ADDPRINTPROVIDORA" (` |
| DECLARE | WNETGETCONNECTION | WIN32API.INC(12995): `DECLARE FUNCTION WNETGETCONNECTION LIB "MPR.DLL" ALIAS "WNETGETCONNECTIONA" (BYV` | WINDOWS.INC(13270): `DECLARE FUNCTION WNETGETCONNECTION LIB "MPR.DLL" ALIAS "WNETGETCONNECTIONA" (BYV` |
| TYPE | NCB | WIN32API.INC(13059): `TYPE NCB NCB_COMMAND AS INTEGER NCB_RETCODE AS INTEGER NCB_LSN AS INTEGER NCB_NU` | WINDOWS.INC(13334): `TYPE NCB NCB_COMMAND AS BYTE NCB_RETCODE AS BYTE NCB_LSN AS BYTE NCB_NUM AS BYTE` |
| TYPE | ADAPTER_STATUS | WIN32API.INC(13077): `TYPE ADAPTER_STATUS ADAPTER_ADDRESS AS STRING * 6 REV_MAJOR AS INTEGER RESERVED0` | WINDOWS.INC(13352): `TYPE ADAPTER_STATUS ADAPTER_ADDRESS AS STRING * 6 REV_MAJOR AS WORD RESERVED0 AS` |
| TYPE | NAME_BUFFER | WIN32API.INC(13107): `TYPE NAME_BUFFER NAME AS STRING * NCBNAMSZ NAME_NUM AS INTEGER NAME_FLAGS AS INT` | WINDOWS.INC(13382): `TYPE NAME_BUFFER NAME AS STRING * NCBNAMSZ NAME_NUM AS WORD NAME_FLAGS AS WORD E` |
| TYPE | SESSION_HEADER | WIN32API.INC(13126): `TYPE SESSION_HEADER SESS_NAME AS INTEGER NUM_SESS AS INTEGER RCV_DG_OUTSTANDING ` | WINDOWS.INC(13401): `TYPE SESSION_HEADER SESS_NAME AS WORD NUM_SESS AS WORD RCV_DG_OUTSTANDING AS WOR` |
| TYPE | SESSION_BUFFER | WIN32API.INC(13133): `TYPE SESSION_BUFFER LSN AS INTEGER STATE AS INTEGER LOCAL_NAME AS STRING * NCBNA` | WINDOWS.INC(13408): `TYPE SESSION_BUFFER LSN AS WORD STATE AS WORD LOCAL_NAME AS STRING * NCBNAMSZ RE` |
| TYPE | LANA_ENUM | WIN32API.INC(13150): `TYPE LANA_ENUM LENGTH AS INTEGER LANA(MAX_LANA) AS INTEGER END TYPE` | WINDOWS.INC(13425): `TYPE LANA_ENUM LENGTH AS WORD LANA(MAX_LANA) AS WORD END TYPE` |
| TYPE | FIND_NAME_HEADER | WIN32API.INC(13155): `TYPE FIND_NAME_HEADER NODE_COUNT AS INTEGER RESERVED AS INTEGER UNIQUE_GROUP AS ` | WINDOWS.INC(13430): `TYPE FIND_NAME_HEADER NODE_COUNT AS WORD RESERVED AS WORD UNIQUE_GROUP AS WORD E` |
| TYPE | FIND_NAME_BUFFER | WIN32API.INC(13161): `TYPE FIND_NAME_BUFFER LENGTH AS INTEGER ACCESS_CONTROL AS INTEGER FRAME_CONTROL ` | WINDOWS.INC(13436): `TYPE FIND_NAME_BUFFER LENGTH AS WORD ACCESS_CONTROL AS WORD FRAME_CONTROL AS WOR` |
| TYPE | ACTION_HEADER | WIN32API.INC(13170): `TYPE ACTION_HEADER TRANSPORT_ID AS LONG ACTION_CODE AS INTEGER RESERVED AS INTEG` | WINDOWS.INC(13445): `TYPE ACTION_HEADER TRANSPORT_ID AS LONG ACTION_CODE AS WORD RESERVED AS WORD END` |
| DECLARE | NETBIOS | WIN32API.INC(13253): `DECLARE FUNCTION NETBIOS LIB "NETAPI32.DLL" ALIAS "NETBIOS" (PNCB AS NCB) AS BYT` | WINDOWS.INC(13528): `DECLARE FUNCTION NETBIOS LIB "NETAPI32.DLL" ALIAS "NETBIOS" (PNCB AS NCB) AS LON` |
| DECLARE | REGENUMVALUE | WIN32API.INC(13470): `DECLARE FUNCTION REGENUMVALUE LIB "ADVAPI32.DLL" ALIAS "REGENUMVALUEA" (BYVAL HK` | WINDOWS.INC(13745): `DECLARE FUNCTION REGENUMVALUE LIB "ADVAPI32.DLL" ALIAS "REGENUMVALUEA" (BYVAL HK` |
| DECLARE | DRAGQUERYFILE | rapidq2.inc(1052): `DECLARE FUNCTION DRAGQUERYFILE LIB "SHELL32" ALIAS "DRAGQUERYFILEA" (HDROP AS LO` | WINDOWS.INC(14658): `DECLARE FUNCTION DRAGQUERYFILE LIB "SHELL32.DLL" ALIAS "DRAGQUERYFILEA" (BYVAL H` |
| DECLARE | DRAGQUERYPOINT | rapidq2.inc(1053): `DECLARE FUNCTION DRAGQUERYPOINT LIB "SHELL32" ALIAS "DRAGQUERYPOINT" (HDROP AS L` | WINDOWS.INC(14659): `DECLARE FUNCTION DRAGQUERYPOINT LIB "SHELL32.DLL" ALIAS "DRAGQUERYPOINT" (BYVAL ` |
| DECLARE | DRAGFINISH | rapidq2.inc(1051): `DECLARE SUB DRAGFINISH LIB "SHELL32" ALIAS "DRAGFINISH" (HDROP AS LONG)` | WINDOWS.INC(14660): `DECLARE SUB DRAGFINISH LIB "SHELL32.DLL" ALIAS "DRAGFINISH" (BYVAL HDROP AS LONG` |
| DECLARE | DRAGACCEPTFILES | rapidq2.inc(1050): `DECLARE SUB DRAGACCEPTFILES LIB "SHELL32" ALIAS "DRAGACCEPTFILES" (HWND AS LONG,` | WINDOWS.INC(14661): `DECLARE SUB DRAGACCEPTFILES LIB "SHELL32.DLL" ALIAS "DRAGACCEPTFILES" (BYVAL HWN` |
| DECLARE | FINDEXECUTABLE | Shell32.inc(14): `DECLARE FUNCTION FINDEXECUTABLE LIB "SHELL32.DLL" ALIAS_ "FINDEXECUTABLEA" (LPFI` | WINDOWS.INC(14663): `DECLARE FUNCTION FINDEXECUTABLE LIB "SHELL32.DLL" ALIAS "FINDEXECUTABLEA" (BYVAL` |
| TYPE | APPBARDATA | QFormLocale.inc(94): `TYPE APPBARDATA CBSIZE AS LONG HWND AS LONG UCALLBACKMESSAGE AS LONG UEDGE AS LO` | WINDOWS.INC(14709): `TYPE APPBARDATA CBSIZE AS LONG HWND AS LONG UCALLBACKMESSAGE AS LONG UEDGE AS LO` |
| DECLARE | EXTRACTICONEX | QFormSkin.inc(196): `DECLARE FUNCTION EXTRACTICONEX LIB "SHELL32.DLL" ALIAS "EXTRACTICONEXA" ( _ BYVA` | WINDOWS.INC(14727): `DECLARE FUNCTION EXTRACTICONEX LIB "SHELL32.DLL" ALIAS "EXTRACTICONEXA" (BYVAL L` |
| TYPE | SHFILEOPSTRUCT | WIN32API.INC(14505): `TYPE SHFILEOPSTRUCT HWND AS LONG WFUNC AS LONG PFROM AS STRING PTO AS STRING FFL` | WINDOWS.INC(14765): `TYPE SHFILEOPSTRUCT HWND AS LONG WFUNC AS LONG PFROM AS STRING PTO AS STRING FFL` |
| DECLARE | SHFILEOPERATION | WIN32API.INC(14516): `DECLARE FUNCTION SHFILEOPERATION LIB "SHELL32.DLL" ALIAS " SHFILEOPERATIONA" (LP` | WINDOWS.INC(14776): `DECLARE FUNCTION SHFILEOPERATION LIB "SHELL32.DLL" ALIAS "SHFILEOPERATIONA" (LPF` |
| DECLARE | SHEMPTYRECYCLEBIN | Shell32.inc(21): `DECLARE FUNCTION SHEMPTYRECYCLEBIN LIB "SHELL32.DLL" ALIAS_ "SHEMPTYRECYCLEBINA"` | WINDOWS.INC(14920): `DECLARE FUNCTION SHEMPTYRECYCLEBIN LIB "SHELL32.DLL" ALIAS "SHEMPTYRECYCLEBINA" ` |
| DECLARE | GETFILEVERSIONINFO | WIN32API.INC(14839): `DECLARE FUNCTION GETFILEVERSIONINFO LIB "VERSION.DLL" ALIAS "GETFILEVERSIONINFOA` | WINDOWS.INC(15131): `DECLARE FUNCTION GETFILEVERSIONINFO LIB "VERSION.DLL" ALIAS "GETFILEVERSIONINFOA` |
| DECLARE | GETVERSIONEX | rapidq2.inc(2067): `DECLARE FUNCTION GETVERSIONEX LIB "KERNEL32.DLL" ALIAS "GETVERSIONEXA" (LPVERSIO` | WINDOWS.INC(15290): `DECLARE FUNCTION GETVERSIONEX LIB "KERNEL32" ALIAS "GETVERSIONEXA" (BYVAL LPVERS` |
| TYPE | CHOOSECOLOR | rapidq2.inc(1610): `TYPE CHOOSECOLOR LSTRUCTSIZE AS LONG HWNDOWNER AS LONG HINSTANCE AS LONG RGBRESU` | WINDOWS.INC(15406): `TYPE CHOOSECOLOR LSTRUCTSIZE AS LONG HWNDOWNER AS LONG HINSTANCE AS LONG RGBRESU` |
| DECLARE | CHOOSECOLORDLG | WIN32API.INC(15081): `DECLARE FUNCTION CHOOSECOLORDLG LIB "COMDLG32.DLL" ALIAS "CHOOSECOLORA" (PCHOOSE` | WINDOWS.INC(15447): `DECLARE FUNCTION CHOOSECOLORDLG LIB "COMDLG32" ALIAS "CHOOSECOLORA" (CC AS CHOOS` |
| TYPE | FINDREPLACE | WIN32API.INC(15093): `TYPE FINDREPLACE LSTRUCTSIZE AS LONG HWNDOWNER AS LONG HINSTANCE AS LONG FLAGS A` | WINDOWS.INC(15454): `TYPE FINDREPLACE LSTRUCTSIZE AS LONG HWNDOWNER AS LONG HINSTANCE AS LONG FLAGS A` |
| TYPE | CHOOSEFONT | WIN32API.INC(15130): `TYPE CHOOSEFONT LSTRUCTSIZE AS LONG HWNDOWNER AS LONG HDC AS LONG LPLOGFONT AS L` | WINDOWS.INC(15491): `TYPE CHOOSEFONT LSTRUCTSIZE AS LONG HWNDOWNER AS LONG HDC AS LONG LPLOGFONT AS L` |
| TYPE | PRINTDLG | WIN32API.INC(15209): `TYPE PRINTDLG LSTRUCTSIZE AS LONG HWNDOWNER AS LONG HDEVMODE AS LONG HDEVNAMES A` | WINDOWS.INC(15570): `TYPE PRINTDLG LSTRUCTSIZE AS LONG HWNDOWNER AS LONG HDEVMODE AS LONG HDEVNAMES A` |
| TYPE | DEVNAMES | WIN32API.INC(15258): `TYPE DEVNAMES WDRIVEROFFSET AS INTEGER WDEVICEOFFSET AS INTEGER WOUTPUTOFFSET AS` | WINDOWS.INC(15619): `TYPE DEVNAMES WDRIVEROFFSET AS WORD WDEVICEOFFSET AS WORD WOUTPUTOFFSET AS WORD ` |
| TYPE | COMMCONFIG | WIN32API.INC(15330): `TYPE COMMCONFIG DWSIZE AS LONG WVERSION AS INTEGER WRESERVED AS INTEGER DCBX AS ` | WINDOWS.INC(15690): `TYPE COMMCONFIG DWSIZE AS LONG WVERSION AS WORD WRESERVED AS WORD DCBX AS DCB DW` |
| DECLARE | READFILEEX | rapidq2.inc(2045): `DECLARE FUNCTION READFILEEX LIB "KERNEL32" ALIAS "READFILEEX"_ (BYVAL HFILE AS L` | WINDOWS.INC(15729): `DECLARE FUNCTION READFILEEX LIB "KERNEL32" ALIAS "READFILEEX" (BYVAL HFILE AS LO` |
| TYPE | PIXELFORMATDESCRIPTOR | WIN32API.INC(15386): `TYPE PIXELFORMATDESCRIPTOR NSIZE AS INTEGER NVERSION AS INTEGER DWFLAGS AS LONG ` | WINDOWS.INC(15746): `TYPE PIXELFORMATDESCRIPTOR NSIZE AS WORD NVERSION AS WORD DWFLAGS AS LONG IPIXEL` |
| DECLARE | SETPRINTER | WIN32API.INC(15445): `DECLARE FUNCTION SETPRINTER LIB "WINSPOOL.DRV" ALIAS "SETPRINTERA" (BYVAL HPRINT` | WINDOWS.INC(15828): `DECLARE FUNCTION SETPRINTER LIB "WINSPOOL.DRV" ALIAS "SETPRINTERA" (BYVAL HPRINT` |
| DECLARE | CALLWINDOWPROC | rapidq2.inc(1019): `DECLARE FUNCTION CALLWINDOWPROC LIB "USER32.DLL" ALIAS "CALLWINDOWPROCA" (LPPREV` | WINDOWS.INC(15831): `DECLARE FUNCTION CALLWINDOWPROC LIB "USER32" ALIAS "CALLWINDOWPROCA" (BYVAL LPPR` |
| DECLARE | COPYIMAGE | QFormSkin.inc(217): `DECLARE FUNCTION COPYIMAGE LIB "USER32.DLL" ALIAS "COPYIMAGE" ( _ BYVAL HANDLE A` | WINDOWS.INC(15839): `DECLARE FUNCTION COPYIMAGE LIB "USER32" ALIAS "COPYIMAGE" (BYVAL HANDLE AS LONG,` |
| DECLARE | DRAWICONEX | rapidq2.inc(1477): `DECLARE FUNCTION DRAWICONEX LIB "USER32" ALIAS "DRAWICONEX" (HDC AS LONG,XLEFT A` | WINDOWS.INC(15851): `DECLARE FUNCTION DRAWICONEX LIB "USER32" ALIAS "DRAWICONEX" (BYVAL HDC AS LONG, ` |
| DECLARE | ENUMCHILDWINDOWS | rapidq2.inc(986): `DECLARE FUNCTION ENUMCHILDWINDOWS LIB "USER32" ALIAS "ENUMCHILDWINDOWS" (HWNDPAR` | WINDOWS.INC(15870): `DECLARE FUNCTION ENUMCHILDWINDOWS LIB "USER32" ALIAS "ENUMCHILDWINDOWS" (BYVAL H` |
| DECLARE | LOADCURSORFROMFILE | WFunctions.inc(38): `DECLARE FUNCTION LOADCURSORFROMFILE LIB "USER32" ALIAS "LOADCURSORFROMFILEA" _ (` | WINDOWS.INC(15918): `DECLARE FUNCTION LOADCURSORFROMFILE LIB "USER32" ALIAS "LOADCURSORFROMFILEA" (BY` |
| DECLARE | LOADIMAGE | rapidq2.inc(1478): `DECLARE FUNCTION LOADIMAGE LIB "USER32" ALIAS "LOADIMAGEA" (HINST AS LONG,LPSZ A` | WINDOWS.INC(15919): `DECLARE FUNCTION LOADIMAGE LIB "USER32" ALIAS "LOADIMAGEA" (BYVAL HINST AS LONG,` |
| DECLARE | LOOKUPICONIDFROMDIRECTORYEX | WIN32API.INC(15530): `DECLARE FUNCTION LOOKUPICONIDFROMDIRECTORYEX LIB "USER32" ALIAS "LOOKUPICONIDFRO` | WINDOWS.INC(15920): `DECLARE FUNCTION LOOKUPICONIDFROMDIRECTORYEX LIB "USER32" ALIAS "LOOKUPICONIDFRO` |
| DECLARE | REGISTERCLASSEX | rapidq2.inc(985): `DECLARE FUNCTION REGISTERCLASSEX LIB "USER32" ALIAS "REGISTERCLASSEXA" (PCWNDCLA` | WINDOWS.INC(15958): `DECLARE FUNCTION REGISTERCLASSEX LIB "USER32" ALIAS "REGISTERCLASSEXA" (PCWNDCLA` |
| DECLARE | TOASCIIEX | WIN32API.INC(15588): `DECLARE FUNCTION TOASCIIEX LIB "USER32" ALIAS "TOASCIIEX" (BYVAL UVIRTKEY AS LON` | WINDOWS.INC(15977): `DECLARE FUNCTION TOASCIIEX LIB "USER32" ALIAS "TOASCIIEX" (BYVAL UVIRTKEY AS LON` |
| DECLARE | VKKEYSCANEX | WIN32API.INC(15597): `DECLARE FUNCTION VKKEYSCANEX LIB "USER32" ALIAS "VKKEYSCANEXA" (BYVAL CH AS BYTE` | WINDOWS.INC(15986): `DECLARE FUNCTION VKKEYSCANEX LIB "USER32" ALIAS "VKKEYSCANEXA" (BYVAL CH AS LONG` |
| DECLARE | MCIGETERRORSTRING | WIN32API.INC(11818): `DECLARE FUNCTION MCIGETERRORSTRING LIB "WINMM.DLL" ALIAS "MCIGETERRORSTRINGA" (B` | WinMM.Inc(13): `DECLARE FUNCTION MCIGETERRORSTRING LIB "WINMM.DLL" ALIAS_ "MCIGETERRORSTRINGA" (` |
| DECLARE | MCISENDSTRING | WIN32API.INC(11810): `DECLARE FUNCTION MCISENDSTRING LIB "WINMM.DLL" ALIAS "MCISENDSTRINGA" (BYVAL LPS` | WinMM.Inc(19): `DECLARE FUNCTION MCISENDSTRING LIB "WINMM.DLL" ALIAS_ "MCISENDSTRINGA" (LPSTRCOM` |
| DECLARE | TIMEGETTIME | WIN32API.INC(11621): `DECLARE FUNCTION TIMEGETTIME LIB "WINMM.DLL" ALIAS "TIMEGETTIME" () AS LONG` | WinMM.Inc(29): `DECLARE FUNCTION TIMEGETTIME LIB "WINMM.DLL" ALIAS_ "TIMEGETTIME" AS LONG` |
| CONST | RGN_MAX | WIN32API.INC(3033): `PUBLIC CONST RGN_MAX = RGN_COPY` | WindowsAPI.inc(48): `CONST RGN_MAX = 5` |
| CONST | RGN_MIN | WIN32API.INC(3032): `PUBLIC CONST RGN_MIN = RGN_AND` | WindowsAPI.inc(49): `CONST RGN_MIN = 1` |
| DECLARE | CHOOSECOLORDLG | WIN32API.INC(15081): `DECLARE FUNCTION CHOOSECOLORDLG LIB "COMDLG32.DLL" ALIAS "CHOOSECOLORA" (PCHOOSE` | rapidq2.inc (компоненты)(1695): `DECLARE FUNCTION CHOOSECOLORDLG LIB "COMDLG32" ALIAS "CHOOSECOLORA" (CC AS CHOOS` |
| DECLARE | LOADLIBRARY | rapidq2.inc(2261): `DECLARE FUNCTION LOADLIBRARY LIB "KERNEL32" ALIAS "LOADLIBRARYA" (BYVAL LPLIBFIL` | apiRe.inc(13): `DECLARE FUNCTION LOADLIBRARY LIB "KERNEL32" ALIAS "LOADLIBRARYA" _ (LIBFILENAME ` |
| CONST | WS_TILED | Win32_constants.inc(56): `CONST WS_TILED = 0` | apiRe.inc(46): `PUBLIC CONST WS_TILED = WS_OVERLAPPED` |
| CONST | WS_ICONIC | Win32_constants.inc(43): `CONST WS_ICONIC = &H20000000` | apiRe.inc(47): `PUBLIC CONST WS_ICONIC = WS_MINIMIZE` |
| CONST | WS_SIZEBOX | Win32_constants.inc(52): `CONST WS_SIZEBOX = &H40000` | apiRe.inc(48): `PUBLIC CONST WS_SIZEBOX = WS_THICKFRAME` |
| CONST | WS_TILEDWINDOW | Win32_constants.inc(57): `CONST WS_TILEDWINDOW = &HCF0000` | apiRe.inc(50): `PUBLIC CONST WS_TILEDWINDOW = WS_OVERLAPPEDWINDOW` |
| CONST | WS_POPUPWINDOW | Win32_constants.inc(51): `CONST WS_POPUPWINDOW = &H80880000` | apiRe.inc(57): `PUBLIC CONST WS_POPUPWINDOW = (WS_POPUP OR WS_BORDER OR WS_SYSMENU)` |
| CONST | WS_CHILDWINDOW | Win32_constants.inc(36): `CONST WS_CHILDWINDOW = &H40000000` | apiRe.inc(59): `PUBLIC CONST WS_CHILDWINDOW = (WS_CHILD)` |
| $DEFINE | BOOLEAN | rapidq2.inc(2241): `LONG` | QDataBase.inc(14): `INTEGER` |
| DECLARE | GETDISKFREESPACE | Kernel32.inc, поднято(94): `DECLARE FUNCTION GETDISKFREESPACE LIB "KERNEL32.DLL" ALIAS_ "GETDISKFREESPACEA" ` | qdrive2024.inc(23): `DECLARE FUNCTION GETDISKFREESPACE LIB "KERNEL32" ALIAS "GETDISKFREESPACEA" (ROOT` |
| DECLARE | SETWINDOWLONG | rapidq2.inc(1039): `DECLARE FUNCTION SETWINDOWLONG LIB "USER32" ALIAS "SETWINDOWLONGA" (HWND AS LONG` | qEditEx.inc(16): `DECLARE FUNCTION SETWINDOWLONG LIB "USER32" ALIAS "SETWINDOWLONGA"(HWND AS LONG,` |
| DECLARE | ONGETFOCUS_EVENTTEMPLATE | rapidq2.inc(2413): `DECLARE SUB ONGETFOCUS_EVENTTEMPLATE` | qEditEx.inc(22): `DECLARE SUB ONGETFOCUS_EVENTTEMPLATE(SENDER AS QEDIT)` |
| $DEFINE | BOOLEAN | rapidq2.inc(2241): `LONG` | QIni.inc(14): `INTEGER` |
| DECLARE | GETPRIVATEPROFILESTRING | WIN32API.INC(2051): `DECLARE FUNCTION GETPRIVATEPROFILESTRING LIB "KERNEL32" ALIAS "GETPRIVATEPROFILE` | QIni.inc(17): `DECLARE FUNCTION GETPRIVATEPROFILESTRING LIB "KERNEL32" ALIAS "GETPRIVATEPROFILE` |
| DECLARE | WRITEPRIVATEPROFILESTRING | WIN32API.INC(2053): `DECLARE FUNCTION WRITEPRIVATEPROFILESTRING LIB "KERNEL32" ALIAS "WRITEPRIVATEPRO` | QIni.inc(21): `DECLARE FUNCTION WRITEPRIVATEPROFILESTRING LIB "KERNEL32" ALIAS "WRITEPRIVATEPRO` |
| DECLARE | GETWINDOWSDIRECTORY | Kernel32.inc, поднято(213): `DECLARE FUNCTION GETWINDOWSDIRECTORY LIB "KERNEL32.DLL" ALIAS_ "GETWINDOWSDIRECT` | QIni.inc(24): `DECLARE FUNCTION GETWINDOWSDIRECTORY LIB "KERNEL32.DLL" ALIAS "GETWINDOWSDIRECTO` |
| DECLARE | GETSYSTEMDIRECTORY | WIN32API.INC(2059): `DECLARE FUNCTION GETSYSTEMDIRECTORY LIB "KERNEL32" ALIAS "GETSYSTEMDIRECTORYA" (` | QIni.inc(25): `DECLARE FUNCTION GETSYSTEMDIRECTORY LIB "KERNEL32" ALIAS "GETSYSTEMDIRECTORYA" (` |
| DECLARE | GETTEMPPATH | Kernel32.inc, поднято(148): `DECLARE FUNCTION GETTEMPPATH LIB "KERNEL32.DLL" ALIAS_ "GETTEMPPATHA" (NBUFFERLE` | QIni.inc(26): `DECLARE FUNCTION GETTEMPPATH LIB "KERNEL32" ALIAS "GETTEMPPATHA" (NBUFFERLENGTH ` |
| DECLARE | GETWINDOWSDIRECTORY | Kernel32.inc, поднято(213): `DECLARE FUNCTION GETWINDOWSDIRECTORY LIB "KERNEL32.DLL" ALIAS_ "GETWINDOWSDIRECT` | QIniFile.inc(8): `DECLARE FUNCTION GETWINDOWSDIRECTORY LIB "KERNEL32" ALIAS "GETWINDOWSDIRECTORYA"` |
| DECLARE | GETPARENT | rapidq2.inc(995): `DECLARE FUNCTION GETPARENT LIB "USER32" ALIAS "GETPARENT" (HWND AS LONG) AS LONG` | QMaxSplitter.inc(57): `DECLARE FUNCTION GETPARENT LIB "USER32" ALIAS "GETPARENT" (BYVAL HWND AS LONG) A` |
| DECLARE | CHILDWINDOWFROMPOINT | WIN32API.INC(7189): `DECLARE FUNCTION CHILDWINDOWFROMPOINT LIB "USER32" ALIAS "CHILDWINDOWFROMPOINT" ` | QMaxSplitter.inc(58): `DECLARE FUNCTION CHILDWINDOWFROMPOINT LIB "USER32" ALIAS "CHILDWINDOWFROMPOINT"(` |
| DECLARE | GETDC | rapidq2.inc(1482): `DECLARE FUNCTION GETDC LIB "USER32.DLL" ALIAS "GETDC"(BYVAL HWND AS LONG) AS LON` | QMaxSplitter.inc(59): `DECLARE FUNCTION GETDC LIB "USER32" ALIAS "GETDC" (BYVAL HWND AS LONG) AS LONG` |
| DECLARE | CREATEBITMAP | WIN32API.INC(4361): `DECLARE FUNCTION CREATEBITMAP LIB "GDI32" ALIAS "CREATEBITMAP" (BYVAL NWIDTH AS ` | QMaxSplitter.inc(60): `DECLARE FUNCTION CREATEBITMAP LIB "GDI32" ALIAS "CREATEBITMAP"(BYVAL NWIDTH AS L` |
| DECLARE | CREATEPATTERNBRUSH | WIN32API.INC(4390): `DECLARE FUNCTION CREATEPATTERNBRUSH LIB "GDI32" ALIAS "CREATEPATTERNBRUSH" (BYVA` | QMaxSplitter.inc(61): `DECLARE FUNCTION CREATEPATTERNBRUSH LIB "GDI32" ALIAS "CREATEPATTERNBRUSH"(BYVAL` |
| DECLARE | SELECTOBJECT | rapidq2.inc(1464): `DECLARE FUNCTION SELECTOBJECT LIB "GDI32" ALIAS "SELECTOBJECT" (HDC AS LONG,HOBJ` | QMaxSplitter.inc(62): `DECLARE FUNCTION SELECTOBJECT LIB "GDI32" ALIAS "SELECTOBJECT" (BYVAL HDC AS LON` |
| DECLARE | SETBRUSHORGEX | WIN32API.INC(4706): `DECLARE FUNCTION SETBRUSHORGEX LIB "GDI32" ALIAS "SETBRUSHORGEX" (BYVAL HDC AS L` | QMaxSplitter.inc(63): `DECLARE FUNCTION SETBRUSHORGEX LIB "GDI32" ALIAS "SETBRUSHORGEX"(BYVAL HDC AS LO` |
| DECLARE | PATBLT | rapidq2.inc(1461): `DECLARE FUNCTION PATBLT LIB "GDI32" ALIAS "PATBLT" (HDC AS LONG,X AS LONG,Y AS L` | QMaxSplitter.inc(65): `DECLARE FUNCTION PATBLT LIB "GDI32" ALIAS "PATBLT" (BYVAL HDC AS LONG, BYVAL X A` |
| DECLARE | DELETEOBJECT | rapidq2.inc(1451): `DECLARE FUNCTION DELETEOBJECT LIB "GDI32" ALIAS "DELETEOBJECT" (HOBJECT AS LONG)` | QMaxSplitter.inc(66): `DECLARE FUNCTION DELETEOBJECT LIB "GDI32" ALIAS "DELETEOBJECT" (BYVAL HOBJECT AS` |
| DECLARE | RELEASEDC | rapidq2.inc(1483): `DECLARE FUNCTION RELEASEDC LIB "USER32.DLL" ALIAS "RELEASEDC"(BYVAL HWND AS LONG` | QMaxSplitter.inc(67): `DECLARE FUNCTION RELEASEDC LIB "USER32" ALIAS "RELEASEDC" (BYVAL HWND AS LONG, B` |
| DECLARE | GETCURSORPOS | WIN32API.INC(7170): `DECLARE FUNCTION GETCURSORPOS LIB "USER32" ALIAS "GETCURSORPOS" (LPPOINT AS POIN` | QMaxSplitter.inc(68): `DECLARE FUNCTION GETCURSORPOS LIB "USER32" ALIAS "GETCURSORPOS"(LPPOINT AS POINT` |
| DECLARE | GETCLIENTRECT | rapidq2.inc(992): `DECLARE FUNCTION GETCLIENTRECT LIB "USER32" ALIAS "GETCLIENTRECT" (HWND AS LONG,` | QMaxSplitter.inc(69): `DECLARE FUNCTION GETCLIENTRECT LIB "USER32" ALIAS "GETCLIENTRECT" (BYVAL HWND AS` |
| DECLARE | SCREENTOCLIENT | WIN32API.INC(7185): `DECLARE FUNCTION SCREENTOCLIENT LIB "USER32" ALIAS "SCREENTOCLIENT" (BYVAL HWND ` | QMaxSplitter.inc(70): `DECLARE FUNCTION SCREENTOCLIENT LIB "USER32" ALIAS "SCREENTOCLIENT"(BYVAL HWND A` |
| DECLARE | MOVEWINDOW | rapidq2.inc(993): `DECLARE FUNCTION MOVEWINDOW LIB "USER32" ALIAS "MOVEWINDOW" (HWND AS LONG,X AS L` | QMaxSplitter.inc(72): `DECLARE FUNCTION MOVEWINDOW LIB "USER32" ALIAS "MOVEWINDOW" (BYVAL HWND AS LONG,` |
| $DEFINE | BOOLEAN | rapidq2.inc(2241): `LONG` | QTextEdit.inc(14): `INTEGER` |
| DECLARE | SENDMESSAGEA | Common.inc(14): `DECLARE FUNCTION SENDMESSAGEA LIB "USER32" ALIAS "SENDMESSAGEA" _ (HWND AS LONG,` | QTextEdit.inc(17): `DECLARE FUNCTION SENDMESSAGEA LIB "USER32" ALIAS "SENDMESSAGEA" (HWND AS LONG, W` |
| $DEFINE | QRICHEDIT | QRedEx.Inc(573): `QREDEX` | QTextEdit.inc(225): `QTEXTEDIT` |
| DECLARE | SENDMESSAGEA | Common.inc(14): `DECLARE FUNCTION SENDMESSAGEA LIB "USER32" ALIAS "SENDMESSAGEA" _ (HWND AS LONG,` | RichEdPopUp.inc(7): `DECLARE FUNCTION SENDMESSAGEA LIB "USER32" ALIAS "SENDMESSAGEA" (HWND _ AS LONG,` |
| $DEFINE | QRICHEDIT | QRedEx.Inc(573): `QREDEX` | RichEdPopUp.inc(138): `QMAXEDIT` |
| DECLARE | SENDMESSAGEAPI | rapidq2.inc(980): `DECLARE FUNCTION SENDMESSAGEAPI LIB "USER32" ALIAS "SENDMESSAGEA" (HWND AS LONG,` | VFW.inc(105): `DECLARE FUNCTION SENDMESSAGEAPI LIB "USER32" ALIAS "SENDMESSAGEA" (BYVAL HWND AS` |
| TYPE | BITMAPINFOHEADER | WIN32API.INC(3305): `TYPE BITMAPINFOHEADER BISIZE AS LONG BIWIDTH AS LONG BIHEIGHT AS LONG BIPLANES A` | VFW.inc(114): `TYPE BITMAPINFOHEADER BISIZE AS LONG BIWIDTH AS LONG BIHEIGHT AS LONG BIPLANES A` |
| TYPE | BITMAPINFO | WIN32API.INC(3325): `TYPE BITMAPINFO BMIHEADER AS BITMAPINFOHEADER BMICOLORS AS RGBQUAD END TYPE` | VFW.inc(129): `TYPE BITMAPINFO BMIHEADER_BISIZE AS DWORD BMIHEADER_BIWIDTH AS LONG BMIHEADER_BI` |
| $DEFINE | GWL_STYLE | rapidq2.inc(780): `CONST GWL_STYLE = -16` | XP_MANIFEST.INC(17): `&HFFFFFFF0` |
| DECLARE | SLEEP | WIN32API.INC(1867): `DECLARE SUB SLEEP LIB "KERNEL32" ALIAS "SLEEP" (BYVAL DWMILLISECONDS AS LONG)` | COMPORTxp.inc(145): `DECLARE SUB SLEEP LIB "KERNEL32" ALIAS "SLEEP" _ (DWMILLISECONDS AS DWORD)` |
| DECLARE | GETLASTERROR | rapidq2.inc(1894): `DECLARE FUNCTION GETLASTERROR LIB "KERNEL32" ALIAS "GETLASTERROR" () AS DWORD` | COMPORTxp.inc(153): `DECLARE FUNCTION GETLASTERROR LIB "KERNEL32" ALIAS "GETLASTERROR" _ () _ AS DWOR` |
| DECLARE | FORMATMESSAGE | rapidq2.inc(1902): `DECLARE FUNCTION FORMATMESSAGE LIB "KERNEL32" ALIAS "FORMATMESSAGEA" _ (DWFLAGS ` | COMPORTxp.inc(160): `DECLARE FUNCTION FORMATMESSAGE LIB "KERNEL32" ALIAS "FORMATMESSAGEA" _ (DWFLAGS ` |
| $DEFINE | QRICHEDIT | QRedEx.Inc(573): `QREDEX` | HiLight.inc(140): `QREDIT` |
| $DEFINE | BOOLEAN | rapidq2.inc(2241): `LONG` | QAnim.inc(14): `INTEGER` |
| TYPE | BITMAPINFOHEADER | WIN32API.INC(3305): `TYPE BITMAPINFOHEADER BISIZE AS LONG BIWIDTH AS LONG BIHEIGHT AS LONG BIPLANES A` | QAVI.inc(42): `TYPE BITMAPINFOHEADER BISIZE AS LONG BIWIDTH AS LONG BIHEIGHT AS LONG BIPLANES A` |
| $DEFINE | BOOLEAN | rapidq2.inc(2241): `LONG` | Qcdaudio.inc(14): `INTEGER` |
| $DEFINE | BOOLEAN | rapidq2.inc(2241): `LONG` | QCursor.inc(14): `INTEGER` |
| DECLARE | LOADCURSORFROMFILE | WFunctions.inc(38): `DECLARE FUNCTION LOADCURSORFROMFILE LIB "USER32" ALIAS "LOADCURSORFROMFILEA" _ (` | QCursor.inc(18): `DECLARE FUNCTION LOADCURSORFROMFILE LIB "USER32" ALIAS "LOADCURSORFROMFILEA" (CU` |
| DECLARE | SETCURSORPOS | rapidq2.inc(1065): `DECLARE FUNCTION SETCURSORPOS LIB "USER32" ALIAS "SETCURSORPOS" (BYVAL X AS LONG` | QCursor.inc(19): `DECLARE FUNCTION SETCURSORPOS LIB "USER32" ALIAS "SETCURSORPOS" (X AS LONG,Y AS ` |
| DECLARE | SHOWCURSOR | WIN32API.INC(7167): `DECLARE FUNCTION SHOWCURSOR LIB "USER32" ALIAS "SHOWCURSOR" (BYVAL BSHOW AS LONG` | QCursor.inc(20): `DECLARE FUNCTION SHOWCURSOR LIB "USER32" ALIAS "SHOWCURSOR" (BSHOW AS LONG) AS L` |
| TYPE | QDATABASE | QDataBase.inc(31): `TYPE QDATABASE EXTENDS QOBJECT PRIVATE: MEM AS QMEMORYSTREAM FILE AS QFILESTREAM` | qdataBaseSQL.inc(130): `TYPE QDATABASE EXTENDS QOBJECT PUBLIC: DRIVERSTR AS STRING DATABASENAME AS STRIN` |
| DECLARE | PAINTDESKTOP | WIN32API.INC(15551): `DECLARE FUNCTION PAINTDESKTOP LIB "USER32" ALIAS "PAINTDESKTOP" (BYVAL HDC AS LO` | QDesktop.inc(9): `DECLARE FUNCTION PAINTDESKTOP LIB "USER32" ALIAS "PAINTDESKTOP" (HDC AS INTEGER)` |
| $DEFINE | BOOLEAN | rapidq2.inc(2241): `LONG` | QDrawFocus.inc(20): `INTEGER` |
| DECLARE | DRAWFOCUSRECT | WIN32API.INC(7226): `DECLARE FUNCTION DRAWFOCUSRECT LIB "USER32" ALIAS "DRAWFOCUSRECT" (BYVAL HDC AS ` | QDrawFocus.inc(35): `DECLARE FUNCTION DRAWFOCUSRECT LIB "USER32.DLL" ALIAS "DRAWFOCUSRECT" (HDC AS LO` |
| $DEFINE | BOOLEAN | rapidq2.inc(2241): `LONG` | QDrawMenu.inc(15): `INTEGER` |
| $DEFINE | BOOLEAN | rapidq2.inc(2241): `LONG` | QFileListView.inc(14): `INTEGER` |
| TYPE | SHFILEINFO | WIN32API.INC(14619): `TYPE SHFILEINFO HICON AS LONG IICON AS LONG DWATTRIBUTES AS LONG SZDISPLAYNAME A` | QFileListView.inc(18): `TYPE SHFILEINFO HICON AS LONG IICON AS INTEGER DWATTRIBUTES AS DWORD SZDISPLAYNA` |
| $DEFINE | BOOLEAN | rapidq2.inc(2241): `LONG` | QFlashLabel.inc(14): `INTEGER` |
| $DEFINE | BOOLEAN | rapidq2.inc(2241): `LONG` | QICON.inc(14): `INTEGER` |
| DECLARE | EXTRACTASSOCIATEDICON | WIN32API.INC(14407): `DECLARE FUNCTION EXTRACTASSOCIATEDICON LIB "SHELL32.DLL" ALIAS "EXTRACTASSOCIATE` | QICON.inc(17): `DECLARE FUNCTION EXTRACTASSOCIATEDICON LIB "SHELL32.DLL" ALIAS "EXTRACTASSOCIATE` |
| DECLARE | EXTRACTICON | WIN32API.INC(14408): `DECLARE FUNCTION EXTRACTICON LIB "SHELL32.DLL" ALIAS "EXTRACTICONA" (BYVAL HINST` | QICON.inc(18): `DECLARE FUNCTION EXTRACTICON LIB "SHELL32.DLL" ALIAS "EXTRACTICONA" (HINST AS LO` |
| DECLARE | DESTROYICON | QFormSkin.inc(215): `DECLARE FUNCTION DESTROYICON LIB "USER32" ALIAS "DESTROYICON" ( _ BYVAL HICON AS` | QICON.inc(19): `DECLARE FUNCTION DESTROYICON LIB "USER32" ALIAS "DESTROYICON" (HICON AS LONG) AS` |
| $DEFINE | BOOLEAN | rapidq2.inc(2241): `LONG` | QImageBox.inc(14): `INTEGER` |
| $DEFINE | BOOLEAN | rapidq2.inc(2241): `LONG` | QImageDialog.inc(14): `INTEGER` |
| SUB/FUNCTION | TRIM$ | rapidq.inc(641): `FUNCTION TRIM$(S AS STRING) AS STRING RESULT=LTRIM$(RTRIM$(S)) END FUNCTION` | QLibrary.Inc(9): `FUNCTION TRIM$ (DATUM AS STRING) AS STRING RESULT = LTRIM$(RTRIM$(DATUM)) END FU` |
| TYPE | QINIFILE | QIniFile.inc(11): `TYPE QINIFILE EXTENDS QSTRINGLIST PRIVATE: WINDOWSDIR AS STRING NAME AS STRING P` | QLibrary.Inc(137): `TYPE QINIFILE EXTENDS QOBJECT PUBLIC: NAME AS STRING LINES AS QSTRINGLIST LINECO` |
| DECLARE | DRAWLINE | QChart.inc(141): `DECLARE SUB DRAWLINE (OVERLAY AS INTEGER, COLNUM AS INTEGER)` | QLine.inc(5): `DECLARE FUNCTION DRAWLINE LIB "USER32" ALIAS "DRAWEDGE" (HDC AS LONG,QRC AS QREC` |
| $DEFINE | BOOLEAN | rapidq2.inc(2241): `LONG` | QMidi.inc(14): `INTEGER` |
| DECLARE | EVENT_CHANGE | Qcdaudio.inc(21): `DECLARE SUB EVENT_CHANGE(TRACK AS INTEGER,TIME AS STRING)` | QMidi.inc(25): `DECLARE SUB EVENT_CHANGE(POSITION AS LONG)` |
| DECLARE | MCISENDSTRING | WIN32API.INC(11810): `DECLARE FUNCTION MCISENDSTRING LIB "WINMM.DLL" ALIAS "MCISENDSTRINGA" (BYVAL LPS` | Qmp3.inc(16): `DECLARE FUNCTION MCISENDSTRING LIB "WINMM.DLL" ALIAS "MCISENDSTRINGA" _ (BYVAL L` |
| DECLARE | RESUMETHREAD | WIN32API.INC(2000): `DECLARE FUNCTION RESUMETHREAD LIB "KERNEL32" ALIAS "RESUMETHREAD" (BYVAL HTHREAD` | QProcess.inc(19): `DECLARE FUNCTION RESUMETHREAD LIB "KERNEL32.DLL" ALIAS "RESUMETHREAD" (HTHREAD A` |
| DECLARE | SETPARENT | rapidq2.inc(1011): `DECLARE FUNCTION SETPARENT LIB "USER32" ALIAS "SETPARENT" (HWNDCHILD AS LONG,HWN` | QProcess.inc(40): `DECLARE FUNCTION SETPARENT LIB "USER32" ALIAS "SETPARENT" (BYVAL HWNDCHILD AS LO` |
| DECLARE | CLOSEHANDLE | rapidq2.inc(2038): `DECLARE FUNCTION CLOSEHANDLE LIB "KERNEL32" ALIAS "CLOSEHANDLE" _ (HOBJECT AS LO` | QProcess.inc(41): `DECLARE FUNCTION CLOSEHANDLE LIB "KERNEL32" ALIAS "CLOSEHANDLE" (BYVAL HOBJECT A` |
| DECLARE | RESUMETHREAD | WIN32API.INC(2000): `DECLARE FUNCTION RESUMETHREAD LIB "KERNEL32" ALIAS "RESUMETHREAD" (BYVAL HTHREAD` | QProgress.inc(14): `DECLARE FUNCTION RESUMETHREAD LIB "KERNEL32.DLL" ALIAS "RESUMETHREAD"(HTHREAD AS` |
| DECLARE | SUSPENDTHREAD | WIN32API.INC(1999): `DECLARE FUNCTION SUSPENDTHREAD LIB "KERNEL32" ALIAS "SUSPENDTHREAD" (BYVAL HTHRE` | QProgress.inc(15): `DECLARE FUNCTION SUSPENDTHREAD LIB "KERNEL32" ALIAS "SUSPENDTHREAD"(BYVAL HTHREA` |
| DECLARE | TERMINATETHREAD | WIN32API.INC(2243): `DECLARE FUNCTION TERMINATETHREAD LIB "KERNEL32" ALIAS "TERMINATETHREAD" (BYVAL H` | QProgress.inc(16): `DECLARE FUNCTION TERMINATETHREAD LIB "KERNEL32" ALIAS "TERMINATETHREAD"(BYVAL HT` |
| DECLARE | SETPARENT | rapidq2.inc(1011): `DECLARE FUNCTION SETPARENT LIB "USER32" ALIAS "SETPARENT" (HWNDCHILD AS LONG,HWN` | QProgress.inc(19): `DECLARE FUNCTION SETPARENT LIB "USER32" ALIAS "SETPARENT"(BYVAL HWNDCHILD AS LON` |
| DECLARE | CLOSEHANDLE | rapidq2.inc(2038): `DECLARE FUNCTION CLOSEHANDLE LIB "KERNEL32" ALIAS "CLOSEHANDLE" _ (HOBJECT AS LO` | QProgress.inc(20): `DECLARE FUNCTION CLOSEHANDLE LIB "KERNEL32" ALIAS "CLOSEHANDLE"(BYVAL HOBJECT AS` |
| DECLARE | UPDATEWINDOW | WIN32API.INC(7027): `DECLARE FUNCTION UPDATEWINDOW LIB "USER32" ALIAS "UPDATEWINDOW" (BYVAL HWND AS L` | QProgressBar.inc(15): `DECLARE FUNCTION UPDATEWINDOW LIB "USER32" ALIAS "UPDATEWINDOW" _ (HWND AS LONG)` |
| DECLARE | SETPARENT | rapidq2.inc(1011): `DECLARE FUNCTION SETPARENT LIB "USER32" ALIAS "SETPARENT" (HWNDCHILD AS LONG,HWN` | QProgressBar.inc(26): `DECLARE FUNCTION SETPARENT LIB "USER32" ALIAS "SETPARENT"(BYVAL HWNDCHILD AS LON` |
| DECLARE | CLOSEHANDLE | rapidq2.inc(2038): `DECLARE FUNCTION CLOSEHANDLE LIB "KERNEL32" ALIAS "CLOSEHANDLE" _ (HOBJECT AS LO` | QProgressBar.inc(27): `DECLARE FUNCTION CLOSEHANDLE LIB "KERNEL32" ALIAS "CLOSEHANDLE"(BYVAL HOBJECT AS` |
| DECLARE | CREATEWINDOWEX | rapidq2.inc(987): `DECLARE FUNCTION CREATEWINDOWEX LIB "USER32" ALIAS "CREATEWINDOWEXA" (DWEXSTYLE ` | QProgressBar.inc(28): `DECLARE FUNCTION CREATEWINDOWEX LIB "USER32" ALIAS "CREATEWINDOWEXA"_ (BYVAL DWE` |
| $DEFINE | PBM_SETRANGE | commctrl32.inc(686): `(WM_USER+1)` | QProgressBar.inc(50): `&H0401` |
| $DEFINE | PBM_SETPOS | commctrl32.inc(687): `(WM_USER+2)` | QProgressBar.inc(51): `&H0402` |
| $DEFINE | PBM_DELTAPOS | commctrl32.inc(688): `(WM_USER+3)` | QProgressBar.inc(52): `&H0403` |
| $DEFINE | PBM_SETSTEP | commctrl32.inc(689): `(WM_USER+4)` | QProgressBar.inc(53): `&H0404` |
| $DEFINE | PBM_STEPIT | commctrl32.inc(690): `(WM_USER+5)` | QProgressBar.inc(54): `&H0405` |
| $DEFINE | PBM_SETBKCOLOR | commctrl32.inc(695): `CCM_SETBKCOLOR` | QProgressBar.inc(59): `&H2001` |
| DECLARE | SETWINDOWLONG | rapidq2.inc(1039): `DECLARE FUNCTION SETWINDOWLONG LIB "USER32" ALIAS "SETWINDOWLONGA" (HWND AS LONG` | QRichEditXt.inc(162): `DECLARE FUNCTION SETWINDOWLONG LIB "USER32" ALIAS "SETWINDOWLONGA" (BYVAL HWND A` |
| DECLARE | CALLWINDOWPROC | rapidq2.inc(1019): `DECLARE FUNCTION CALLWINDOWPROC LIB "USER32.DLL" ALIAS "CALLWINDOWPROCA" (LPPREV` | QRichEditXt.inc(167): `DECLARE FUNCTION CALLWINDOWPROC LIB "USER32" ALIAS "CALLWINDOWPROCA" _ (BYVAL LP` |
| DECLARE | SENDMESSAGEAPI | rapidq2.inc(980): `DECLARE FUNCTION SENDMESSAGEAPI LIB "USER32" ALIAS "SENDMESSAGEA" (HWND AS LONG,` | QRichEditXt.inc(171): `DECLARE FUNCTION SENDMESSAGEAPI LIB "USER32.DLL" ALIAS "SENDMESSAGEA" (HWND AS L` |
| DECLARE | GETDC | rapidq2.inc(1482): `DECLARE FUNCTION GETDC LIB "USER32.DLL" ALIAS "GETDC"(BYVAL HWND AS LONG) AS LON` | QRichEditXt.inc(173): `DECLARE FUNCTION GETDC LIB "USER32" ALIAS "GETDC"(BYVAL HWND AS LONG) AS LONG` |
| DECLARE | SETBKMODE | rapidq2.inc(1466): `DECLARE FUNCTION SETBKMODE LIB "GDI32" ALIAS "SETBKMODE" (HDC AS LONG,NBKMODE AS` | QRichEditXt.inc(174): `DECLARE FUNCTION SETBKMODE LIB "GDI32" ALIAS "SETBKMODE" (BYVAL HDC AS LONG, BYV` |
| DECLARE | SELECTOBJECT | rapidq2.inc(1464): `DECLARE FUNCTION SELECTOBJECT LIB "GDI32" ALIAS "SELECTOBJECT" (HDC AS LONG,HOBJ` | QRichEditXt.inc(177): `DECLARE FUNCTION SELECTOBJECT LIB "GDI32" ALIAS "SELECTOBJECT" (BYVAL HDC AS LON` |
| DECLARE | SETTEXTCOLOR | QFormSkin.inc(229): `DECLARE FUNCTION SETTEXTCOLOR LIB "GDI32" ALIAS "SETTEXTCOLOR" ( _ BYVAL HDC AS ` | QRichEditXt.inc(178): `DECLARE FUNCTION SETTEXTCOLOR LIB "GDI32" ALIAS "SETTEXTCOLOR" (BYVAL HDC AS LON` |
| DECLARE | FORMWNDPROC | createWind.inc(32): `DECLARE SUB FORMWNDPROC (HANDLE AS INTEGER, UMSG AS LONG, WPARAM AS LONG,LPARAM ` | QRichEditXt.inc(181): `DECLARE SUB FORMWNDPROC (HWND AS LONG, UMSG AS LONG, WPARAM AS LONG, LPARAM AS L` |
| DECLARE | CREATEROUNDRECTRGN | GDI32.inc(72): `DECLARE FUNCTION CREATEROUNDRECTRGN LIB "GDI32.DLL" ALIAS_ "CREATEROUNDRECTRGN" ` | QrPanel.inc(13): `DECLARE FUNCTION CREATEROUNDRECTRGN LIB "GDI32"ALIAS "CREATEROUNDRECTRGN" (X1 AS` |
| DECLARE | SETWINDOWRGN | QFormSkin.inc(159): `DECLARE FUNCTION SETWINDOWRGN LIB "USER32" ALIAS "SETWINDOWRGN" (BYVAL HWND AS L` | QrPanel.inc(14): `DECLARE FUNCTION SETWINDOWRGN LIB "USER32" ALIAS "SETWINDOWRGN" (HWND AS LONG, H` |
| $DEFINE | BOOLEAN | rapidq2.inc(2241): `LONG` | QRun.inc(14): `INTEGER` |
| CONST | FALSE | rapidq2.inc(82): `CONST FALSE = 0` | QSavePlus.inc(26): `CONST FALSE = 0 :CONST TRUE = 1` |
| TYPE | SHFILEOPSTRUCT | WIN32API.INC(14505): `TYPE SHFILEOPSTRUCT HWND AS LONG WFUNC AS LONG PFROM AS STRING PTO AS STRING FFL` | QSHFileOperation.inc(80): `TYPE SHFILEOPSTRUCT HWND AS LONG WFUNC AS LONG PFROM AS LONG PTO AS LONG FFLAGS ` |
| DECLARE | SHFILEOPERATION | WIN32API.INC(14516): `DECLARE FUNCTION SHFILEOPERATION LIB "SHELL32.DLL" ALIAS " SHFILEOPERATIONA" (LP` | QSHFileOperation.inc(95): `DECLARE FUNCTION SHFILEOPERATION LIB "SHELL32.DLL" _ ALIAS "SHFILEOPERATIONA" (L` |
| DECLARE | EXITWINDOWSEX | rapidq2.inc(1481): `DECLARE FUNCTION EXITWINDOWSEX LIB "USER32" ALIAS "EXITWINDOWSEX" (BYVAL UFLAGS ` | QShutdown.inc(29): `DECLARE FUNCTION EXITWINDOWSEX LIB "USER32" ALIAS "EXITWINDOWSEX" (UFLAGS AS LON` |
| $DEFINE | BOOLEAN | rapidq2.inc(2241): `LONG` | QSkinBtn.inc(14): `INTEGER` |
| DECLARE | INET_ADDR | QICMP.INC(31): `DECLARE FUNCTION INET_ADDR LIB "WSOCK32.DLL" ALIAS "INET_ADDR"_ (BYVAL CP AS STR` | QSocketEx.inc(31): `DECLARE FUNCTION INET_ADDR LIB "WSOCK32.DLL" ALIAS "INET_ADDR" (BYVAL CP AS STRI` |
| DECLARE | WSAGETLASTERROR | rapidq2.inc(1888): `DECLARE FUNCTION WSAGETLASTERROR LIB "WSOCK32" ALIAS "WSAGETLASTERROR" () AS LON` | QSocketEx.inc(41): `DECLARE FUNCTION WSAGETLASTERROR LIB "WSOCK32.DLL" ALIAS "WSAGETLASTERROR"() AS ` |
| DECLARE | LSTRLEN | WIN32API.INC(2345): `DECLARE FUNCTION LSTRLEN LIB "KERNEL32" ALIAS "LSTRLENA" (BYVAL LPSTRING AS STRI` | QSocketEx.inc(45): `DECLARE FUNCTION LSTRLEN LIB "KERNEL32.DLL" ALIAS "LSTRLENA" (BYVAL LPSTRING AS ` |
| DECLARE | LSTRCPY | WIN32API.INC(15379): `DECLARE FUNCTION LSTRCPY LIB "KERNEL32" ALIAS "LSTRCPYA" (BYVAL LPSTRING1 AS STR` | QSocketEx.inc(46): `DECLARE FUNCTION LSTRCPY LIB "KERNEL32.DLL" ALIAS "LSTRCPYA" _ (BYVAL LPSTRING1 ` |
| $DEFINE | BOOLEAN | rapidq2.inc(2241): `LONG` | QSpinEdit.inc(16): `INTEGER` |
| $DEFINE | BOOLEAN | rapidq2.inc(2241): `LONG` | QSplash.inc(14): `INTEGER` |
| $DEFINE | BOOLEAN | rapidq2.inc(2241): `LONG` | QTextBtn.inc(15): `INTEGER` |
| DECLARE | GETTHREADPRIORITY | WIN32API.INC(2240): `DECLARE FUNCTION GETTHREADPRIORITY LIB "KERNEL32" ALIAS "GETTHREADPRIORITY" (BYV` | QThread.inc(42): `DECLARE FUNCTION GETTHREADPRIORITY LIB "KERNEL32" ALIAS "GETTHREADPRIORITY" (HTH` |
| DECLARE | SETTHREADPRIORITY | WIN32API.INC(2239): `DECLARE FUNCTION SETTHREADPRIORITY LIB "KERNEL32" ALIAS "SETTHREADPRIORITY" (BYV` | QThread.inc(44): `DECLARE FUNCTION SETTHREADPRIORITY LIB "KERNEL32" ALIAS "SETTHREADPRIORITY" (HTH` |
| $DEFINE | BOOLEAN | rapidq2.inc(2241): `LONG` | QVideo.inc(18): `INTEGER` |
| DECLARE | MCISENDSTRING | WIN32API.INC(11810): `DECLARE FUNCTION MCISENDSTRING LIB "WINMM.DLL" ALIAS "MCISENDSTRINGA" (BYVAL LPS` | QVideo.inc(23): `DECLARE FUNCTION MCISENDSTRING LIB "WINMM.DLL" ALIAS "MCISENDSTRINGA" (LPSTRCOMM` |
| DECLARE | MCIGETERRORSTRING | WIN32API.INC(11818): `DECLARE FUNCTION MCIGETERRORSTRING LIB "WINMM.DLL" ALIAS "MCIGETERRORSTRINGA" (B` | QVideo.inc(24): `DECLARE FUNCTION MCIGETERRORSTRING LIB "WINMM.DLL" ALIAS "MCIGETERRORSTRINGA" (D` |
| DECLARE | WAVEOUTSETVOLUME | WIN32API.INC(11428): `DECLARE FUNCTION WAVEOUTSETVOLUME LIB "WINMM.DLL" ALIAS "WAVEOUTSETVOLUME" (BYVA` | QVideo.inc(25): `DECLARE FUNCTION WAVEOUTSETVOLUME LIB "WINMM" ALIAS "WAVEOUTSETVOLUME" (WDEVICEI` |
| DECLARE | MOVEWINDOW | rapidq2.inc(993): `DECLARE FUNCTION MOVEWINDOW LIB "USER32" ALIAS "MOVEWINDOW" (HWND AS LONG,X AS L` | QVideo.inc(29): `DECLARE FUNCTION MOVEWINDOW LIB "USER32" ALIAS "MOVEWINDOW" (HWND AS LONG,X AS I` |
| DECLARE | SETFOREGROUNDWINDOW | rapidq2.inc(1012): `DECLARE FUNCTION SETFOREGROUNDWINDOW LIB "USER32" ALIAS "SETFOREGROUNDWINDOW" (B` | QVideo.inc(30): `DECLARE FUNCTION SETFOREGROUNDWINDOW LIB "USER32" ALIAS "SETFOREGROUNDWINDOW" (H` |
| DECLARE | GETWINDOWRECT | rapidq2.inc(996): `DECLARE FUNCTION GETWINDOWRECT LIB "USER32" ALIAS "GETWINDOWRECT" (BYVAL HWND AS` | QVideo.inc(31): `DECLARE FUNCTION GETWINDOWRECT LIB "USER32" ALIAS "GETWINDOWRECT" (HWND AS LONG,` |
| DECLARE | EVENT_CHANGE | Qcdaudio.inc(21): `DECLARE SUB EVENT_CHANGE(TRACK AS INTEGER,TIME AS STRING)` | QVideo.inc(37): `DECLARE SUB EVENT_CHANGE(POSITION AS LONG,TIMEPOS AS LONG)` |
| $DEFINE | BOOLEAN | rapidq2.inc(2241): `LONG` | QVuMeter.inc(14): `INTEGER` |
| $DEFINE | BOOLEAN | rapidq2.inc(2241): `LONG` | QWave.inc(14): `INTEGER` |
| DECLARE | EVENT_CHANGE | Qcdaudio.inc(21): `DECLARE SUB EVENT_CHANGE(TRACK AS INTEGER,TIME AS STRING)` | QWave.inc(34): `DECLARE SUB EVENT_CHANGE(POSITION AS LONG)` |
| DECLARE | IMAGELIST_ADDMASKED | commctrl32.inc(1521): `DECLARE FUNCTION IMAGELIST_ADDMASKED LIB "COMCTL32" ALIAS "IMAGELIST_ADDMASKED" ` | QXPButton.inc(137): `DECLARE FUNCTION IMAGELIST_ADDMASKED _ LIB "COMCTL32" ALIAS "IMAGELIST_ADDMASKED` |
| DECLARE | UPDATEWINDOW | WIN32API.INC(7027): `DECLARE FUNCTION UPDATEWINDOW LIB "USER32" ALIAS "UPDATEWINDOW" (BYVAL HWND AS L` | QXPButton.inc(147): `DECLARE FUNCTION UPDATEWINDOW _ LIB "USER32" ALIAS "UPDATEWINDOW" _ (BYVAL HWND ` |
| DECLARE | GETWINDOWLONG | rapidq2.inc(1037): `DECLARE FUNCTION GETWINDOWLONG LIB "USER32" ALIAS "GETWINDOWLONGA" (HWND AS LONG` | QXPButton.inc(158): `DECLARE FUNCTION GETWINDOWLONG _ LIB "USER32" ALIAS "GETWINDOWLONGA" _ (BYVAL HW` |
| DECLARE | SETWINDOWLONG | rapidq2.inc(1039): `DECLARE FUNCTION SETWINDOWLONG LIB "USER32" ALIAS "SETWINDOWLONGA" (HWND AS LONG` | QXPButton.inc(162): `DECLARE FUNCTION SETWINDOWLONG _ LIB "USER32" ALIAS "SETWINDOWLONGA" _ (BYVAL HW` |
| DECLARE | GETPARENT | rapidq2.inc(995): `DECLARE FUNCTION GETPARENT LIB "USER32" ALIAS "GETPARENT" (HWND AS LONG) AS LONG` | QXPButton.inc(167): `DECLARE FUNCTION GETPARENT _ LIB "USER32" ALIAS "GETPARENT" _ (BYVAL HWND AS LON` |
| DECLARE | GETCURRENTOBJECT | rapidq2.inc(1456): `DECLARE FUNCTION GETCURRENTOBJECT LIB "GDI32" ALIAS "GETCURRENTOBJECT" (HDC AS L` | QXPButton.inc(171): `DECLARE FUNCTION GETCURRENTOBJECT _ LIB "GDI32" ALIAS "GETCURRENTOBJECT" _ (BYVA` |
| DECLARE | GETACTIVEWINDOW | User32.inc(23): `DECLARE FUNCTION GETACTIVEWINDOW LIB "USER32.DLL" ALIAS_ "GETACTIVEWINDOW" AS LO` | RapidFRM.inc(13): `DECLARE FUNCTION GETACTIVEWINDOW LIB "USER32" ALIAS "GETACTIVEWINDOW" () AS LONG` |
| DECLARE | WINDOWFROMPOINT | WIN32API.INC(7188): `DECLARE FUNCTION WINDOWFROMPOINT LIB "USER32" ALIAS "WINDOWFROMPOINT" (BYVAL XPO` | RapidFRM.inc(14): `DECLARE FUNCTION WINDOWFROMPOINT LIB "USER32" ALIAS "WINDOWFROMPOINT" (X AS LONG` |
| DECLARE | SCREENTOCLIENT | WIN32API.INC(7185): `DECLARE FUNCTION SCREENTOCLIENT LIB "USER32" ALIAS "SCREENTOCLIENT" (BYVAL HWND ` | RapidFRM.inc(15): `DECLARE FUNCTION SCREENTOCLIENT LIB "USER32" ALIAS "SCREENTOCLIENT" (HWND AS LON` |
| DECLARE | UPDATEWINDOW | WIN32API.INC(7027): `DECLARE FUNCTION UPDATEWINDOW LIB "USER32" ALIAS "UPDATEWINDOW" (BYVAL HWND AS L` | RapidFRM.inc(17): `DECLARE FUNCTION UPDATEWINDOW LIB "USER32" ALIAS "UPDATEWINDOW" (HWND AS LONG) A` |
| DECLARE | SETBKCOLOR | WIN32API.INC(4537): `DECLARE FUNCTION SETBKCOLOR LIB "GDI32" ALIAS "SETBKCOLOR" (BYVAL HDC AS LONG, B` | RapidFRM.inc(20): `DECLARE FUNCTION SETBKCOLOR LIB "GDI32" ALIAS "SETBKCOLOR" (HDC AS LONG, CRCOLOR` |
| DECLARE | DESTROYWINDOW | WIN32API.INC(6723): `DECLARE FUNCTION DESTROYWINDOW LIB "USER32" ALIAS "DESTROYWINDOW" (BYVAL HWND AS` | RapidFRM.inc(21): `DECLARE FUNCTION DESTROYWINDOW LIB "USER32" ALIAS "DESTROYWINDOW" (HWND AS LONG)` |
| DECLARE | SETWINDOWSHOOKEX | WIN32API.INC(15584): `DECLARE FUNCTION SETWINDOWSHOOKEX LIB "USER32" ALIAS "SETWINDOWSHOOKEXA" (BYVAL ` | RapidFRM.inc(24): `DECLARE FUNCTION SETWINDOWSHOOKEX LIB "USER32" ALIAS "SETWINDOWSHOOKEXA" (IDHOOK` |
| DECLARE | CALLNEXTHOOKEX | WIN32API.INC(7275): `DECLARE FUNCTION CALLNEXTHOOKEX LIB "USER32" ALIAS "CALLNEXTHOOKEX" (BYVAL HHOOK` | RapidFRM.inc(26): `DECLARE FUNCTION CALLNEXTHOOKEX LIB "USER32" ALIAS "CALLNEXTHOOKEX" (HHOOK AS LO` |
| DECLARE | UNHOOKWINDOWSHOOKEX | WIN32API.INC(7274): `DECLARE FUNCTION UNHOOKWINDOWSHOOKEX LIB "USER32" ALIAS "UNHOOKWINDOWSHOOKEX" (B` | RapidFRM.inc(28): `DECLARE FUNCTION UNHOOKWINDOWSHOOKEX LIB "USER32" ALIAS "UNHOOKWINDOWSHOOKEX" (H` |
| DECLARE | GETCURRENTTHREADID | Kernel32.inc(88): `DECLARE FUNCTION GETCURRENTTHREADID LIB "KERNEL32.DLL" ALIAS_ "GETCURRENTTHREADI` | RapidFRM.inc(29): `DECLARE FUNCTION GETCURRENTTHREADID LIB "KERNEL32" ALIAS "GETCURRENTTHREADID" ()` |
| $DEFINE | TCM_SETIMAGELIST | CommCtrl.inc(362): `CONST TCM_SETIMAGELIST = TCM_FIRST + 3` | RapidFRM.inc(198): `&H1303` |
| $DEFINE | TCM_GETITEMCOUNT | CommCtrl.inc(363): `CONST TCM_GETITEMCOUNT = TCM_FIRST + 4` | RapidFRM.inc(199): `&H1304` |
| $DEFINE | TCM_SETITEM | CommCtrl.inc(395): `CONST TCM_SETITEM = TCM_FIRST + 6` | RapidFRM.inc(200): `&H1306` |
| $DEFINE | TCM_INSERTITEM | CommCtrl.inc(397): `CONST TCM_INSERTITEM = TCM_FIRST + 7` | RapidFRM.inc(201): `&H1307` |
| $DEFINE | TCM_DELETEITEM | CommCtrl.inc(400): `CONST TCM_DELETEITEM = TCM_FIRST + 8` | RapidFRM.inc(202): `&H1308` |
| $DEFINE | TCM_DELETEALLITEMS | CommCtrl.inc(401): `CONST TCM_DELETEALLITEMS = TCM_FIRST + 9` | RapidFRM.inc(203): `&H1309` |
| $DEFINE | TCM_GETITEMRECT | CommCtrl.inc(402): `CONST TCM_GETITEMRECT = TCM_FIRST + 10` | RapidFRM.inc(204): `&H130A` |
| DECLARE | GETHOSTBYADDR | QSocketEx.inc(27): `DECLARE FUNCTION GETHOSTBYADDR LIB "WSOCK32.DLL" ALIAS "GETHOSTBYADDR" (ADDR AS ` | RSocket.INC(9): `DECLARE FUNCTION GETHOSTBYADDR LIB "WSOCK32.DLL" ALIAS "GETHOSTBYADDR"_ (ADDR AS` |
| DECLARE | GETHOSTBYNAME | QSocketEx.inc(28): `DECLARE FUNCTION GETHOSTBYNAME LIB "WSOCK32.DLL" ALIAS "GETHOSTBYNAME" (BYVAL NA` | RSocket.INC(11): `DECLARE FUNCTION GETHOSTBYNAME LIB "WSOCK32.DLL" ALIAS "GETHOSTBYNAME"_ (BYVAL N` |
| DECLARE | GETPEERNAMEX | QSocketEx.inc(26): `DECLARE FUNCTION GETPEERNAMEX LIB "WSOCK32.DLL" ALIAS "GETPEERNAME" (SKT AS LONG` | RSocket.INC(13): `DECLARE FUNCTION GETPEERNAMEX LIB "WSOCK32.DLL" ALIAS "GETPEERNAME"_ (S AS LONG,` |
| DECLARE | HTONS | QSocketEx.inc(33): `DECLARE FUNCTION HTONS LIB "WSOCK32.DLL" ALIAS "HTONS" (HOSTSHORT AS INTEGER) AS` | RSocket.INC(15): `DECLARE FUNCTION HTONS LIB "WSOCK32.DLL" ALIAS "HTONS" (HOSTSHORT AS INTEGER)_ A` |
| DECLARE | INET_NTOA | QSocketEx.inc(32): `DECLARE FUNCTION INET_NTOA LIB "WSOCK32.DLL" ALIAS "INET_NTOA" (INADDR AS LONG) ` | RSocket.INC(19): `DECLARE FUNCTION INET_NTOA LIB "WSOCK32.DLL" ALIAS "INET_NTOA"_ (INADDR AS LONG)` |
| DECLARE | IOCTLSOCKET | QSocketEx.inc(34): `DECLARE FUNCTION IOCTLSOCKET LIB "WSOCK32.DLL" ALIAS "IOCTLSOCKET"(BYVAL S AS LO` | RSocket.INC(21): `DECLARE FUNCTION IOCTLSOCKET LIB "WSOCK32.DLL" ALIAS "IOCTLSOCKET"_ (S AS LONG,C` |
| DECLARE | SHUTDOWN | QSocketEx.inc(29): `DECLARE FUNCTION SHUTDOWN LIB "WSOCK32.DLL" ALIAS "SHUTDOWN"(S AS LONG,HOW AS LO` | RSocket.INC(26): `DECLARE FUNCTION SHUTDOWN LIB "WSOCK32.DLL" ALIAS "SHUTDOWN"_ (S AS LONG,HOW AS ` |
| DECLARE | WSAGETLASTERROR | rapidq2.inc(1888): `DECLARE FUNCTION WSAGETLASTERROR LIB "WSOCK32" ALIAS "WSAGETLASTERROR" () AS LON` | RSocket.INC(30): `DECLARE FUNCTION WSAGETLASTERROR LIB "WSOCK32.DLL" ALIAS "WSAGETLASTERROR"_ () A` |
| DECLARE | COPYMEMORY | PRINTERDLL.INC(185): `DECLARE SUB COPYMEMORY LIB "KERNEL32.DLL" ALIAS "RTLMOVEMEMORY" (BYVAL DEST AS L` | RSocket.INC(42): `DECLARE SUB COPYMEMORY LIB "KERNEL32.DLL" ALIAS "RTLMOVEMEMORY"_ (HPVDEST AS LON` |
| DECLARE | LSTRLEN | WIN32API.INC(2345): `DECLARE FUNCTION LSTRLEN LIB "KERNEL32" ALIAS "LSTRLENA" (BYVAL LPSTRING AS STRI` | RSocket.INC(44): `DECLARE FUNCTION LSTRLEN LIB "KERNEL32.DLL" ALIAS "LSTRLENA"_ (BYVAL LPSTRING AS` |
| DECLARE | LSTRCPY | WIN32API.INC(15379): `DECLARE FUNCTION LSTRCPY LIB "KERNEL32" ALIAS "LSTRCPYA" (BYVAL LPSTRING1 AS STR` | RSocket.INC(46): `DECLARE FUNCTION LSTRCPY LIB "KERNEL32.DLL" ALIAS "LSTRCPYA"_ (BYVAL LPSTRING1 A` |
| DECLARE | SENDMESSAGEA | Common.inc(14): `DECLARE FUNCTION SENDMESSAGEA LIB "USER32" ALIAS "SENDMESSAGEA" _ (HWND AS LONG,` | TstRichEd.inc(2): `DECLARE FUNCTION SENDMESSAGEA LIB "USER32" ALIAS "SENDMESSAGEA" (HWND _ AS LONG,` |
| $DEFINE | QRICHEDIT | QRedEx.Inc(573): `QREDEX` | TstRichEd.inc(14): `QMAXEDIT` |
| TYPE | LOGFONT | WIN32API.INC(3518): `TYPE LOGFONT LFHEIGHT AS LONG LFWIDTH AS LONG LFESCAPEMENT AS LONG LFORIENTATION` | XPThemes.inc(28): `TYPE LOGFONT LFHEIGHT AS LONG LFWIDTH AS LONG LFESCAPEMENT AS LONG LFORIENTATION` |
| DECLARE | DRAWTEXT | QFormSkin.inc(223): `DECLARE FUNCTION DRAWTEXT LIB "USER32" ALIAS "DRAWTEXTA" ( _ BYVAL HDC AS LONG, ` | XPThemes.inc(58): `DECLARE FUNCTION DRAWTEXT LIB "USER32" ALIAS "DRAWTEXTA" (HDC AS LONG, LPSTR AS ` |
| DECLARE | EXCLUDECLIPRECT | QFormSkin.inc(241): `DECLARE FUNCTION EXCLUDECLIPRECT LIB "GDI32.DLL" ALIAS "EXCLUDECLIPRECT" ( _ BYV` | XPThemes.inc(59): `DECLARE FUNCTION EXCLUDECLIPRECT LIB "GDI32" ALIAS "EXCLUDECLIPRECT" (HDC AS LON` |
| DECLARE | FILLRECT | WIN32API.INC(7227): `DECLARE FUNCTION FILLRECT LIB "USER32" ALIAS "FILLRECT" (BYVAL HDC AS LONG, LPRE` | XPThemes.inc(60): `DECLARE FUNCTION FILLRECT LIB "USER32" ALIAS "FILLRECT" (HDC AS LONG, LPRECT AS ` |
| DECLARE | FRAMERECT | WIN32API.INC(7228): `DECLARE FUNCTION FRAMERECT LIB "USER32" ALIAS "FRAMERECT" (BYVAL HDC AS LONG, LP` | XPThemes.inc(61): `DECLARE FUNCTION FRAMERECT LIB "USER32" ALIAS "FRAMERECT" (HDC AS LONG, LPRECT A` |
| DECLARE | GETTEXTEXTENTPOINT32 | WIN32API.INC(4498): `DECLARE FUNCTION GETTEXTEXTENTPOINT32 LIB "GDI32" ALIAS "GETTEXTEXTENTPOINT32A" ` | XPThemes.inc(62): `DECLARE FUNCTION GETTEXTEXTENTPOINT32 LIB "GDI32" ALIAS "GETTEXTEXTENTPOINT32A" ` |
| DECLARE | GETVERSION | Kernel32.inc(177): `DECLARE FUNCTION GETVERSION LIB "KERNEL32.DLL" ALIAS_ "GETVERSION" AS DWORD` | XPThemes.inc(63): `DECLARE FUNCTION GETVERSION LIB "KERNEL32" ALIAS "GETVERSION" () AS LONG` |
| DECLARE | GETWINDOWDC | QFormSkin.inc(171): `DECLARE FUNCTION GETWINDOWDC LIB "USER32" ALIAS "GETWINDOWDC" _ (HWND AS LONG) A` | XPThemes.inc(64): `DECLARE FUNCTION GETWINDOWDC LIB "USER32" ALIAS "GETWINDOWDC" (HWND AS LONG) AS ` |
| DECLARE | SETTEXTCOLOR | QFormSkin.inc(229): `DECLARE FUNCTION SETTEXTCOLOR LIB "GDI32" ALIAS "SETTEXTCOLOR" ( _ BYVAL HDC AS ` | XPThemes.inc(65): `DECLARE FUNCTION SETTEXTCOLOR LIB "GDI32" ALIAS "SETTEXTCOLOR" (HDC AS LONG, CRC` |
| DECLARE | CALLWINDOWPROC | rapidq2.inc(1019): `DECLARE FUNCTION CALLWINDOWPROC LIB "USER32.DLL" ALIAS "CALLWINDOWPROCA" (LPPREV` | XPThemes.inc(66): `DECLARE FUNCTION CALLWINDOWPROC LIB "USER32" ALIAS "CALLWINDOWPROCA" (BYVAL LPPR` |
| DECLARE | SETWINDOWLONG | rapidq2.inc(1039): `DECLARE FUNCTION SETWINDOWLONG LIB "USER32" ALIAS "SETWINDOWLONGA" (HWND AS LONG` | XPThemes.inc(67): `DECLARE FUNCTION SETWINDOWLONG LIB "USER32" ALIAS "SETWINDOWLONGA" (BYVAL HWND A` |
| DECLARE | GETWINDOWLONG | rapidq2.inc(1037): `DECLARE FUNCTION GETWINDOWLONG LIB "USER32" ALIAS "GETWINDOWLONGA" (HWND AS LONG` | XPThemes.inc(68): `DECLARE FUNCTION GETWINDOWLONG LIB "USER32" ALIAS "GETWINDOWLONGA" (BYVAL HWND A` |
| DECLARE | SETWINDOWPOS | rapidq2.inc(1029): `DECLARE SUB SETWINDOWPOS LIB "USER32" ALIAS "SETWINDOWPOS"_ (BYVAL HWND AS LONG,` | XPThemes.inc(69): `DECLARE FUNCTION SETWINDOWPOS LIB "USER32" ALIAS "SETWINDOWPOS" (BYVAL HWND AS L` |
| DECLARE | CREATESOLIDBRUSH | rapidq2.inc(1449): `DECLARE FUNCTION CREATESOLIDBRUSH LIB "GDI32" ALIAS "CREATESOLIDBRUSH" (CRCOLOR ` | XPThemes.inc(71): `DECLARE FUNCTION CREATESOLIDBRUSH LIB "GDI32" ALIAS "CREATESOLIDBRUSH" (BYVAL CR` |
| DECLARE | DELETEOBJECT | rapidq2.inc(1451): `DECLARE FUNCTION DELETEOBJECT LIB "GDI32" ALIAS "DELETEOBJECT" (HOBJECT AS LONG)` | XPThemes.inc(72): `DECLARE FUNCTION DELETEOBJECT LIB "GDI32" ALIAS "DELETEOBJECT" (BYVAL HOBJECT AS` |
| DECLARE | SELECTOBJECT | rapidq2.inc(1464): `DECLARE FUNCTION SELECTOBJECT LIB "GDI32" ALIAS "SELECTOBJECT" (HDC AS LONG,HOBJ` | XPThemes.inc(73): `DECLARE FUNCTION SELECTOBJECT LIB "GDI32" ALIAS "SELECTOBJECT" (BYVAL HDC AS LON` |
| DECLARE | GETSYSCOLOR | rapidq2.inc(1602): `DECLARE FUNCTION GETSYSCOLOR LIB "USER32" ALIAS "GETSYSCOLOR" (NINDEX AS LONG) A` | XPThemes.inc(74): `DECLARE FUNCTION GETSYSCOLOR LIB "USER32" ALIAS "GETSYSCOLOR" (BYVAL NINDEX AS L` |
| DECLARE | SETBKMODE | rapidq2.inc(1466): `DECLARE FUNCTION SETBKMODE LIB "GDI32" ALIAS "SETBKMODE" (HDC AS LONG,NBKMODE AS` | XPThemes.inc(75): `DECLARE FUNCTION SETBKMODE LIB "GDI32" ALIAS "SETBKMODE" (BYVAL HDC AS LONG, BYV` |

## $INCLUDE файлов, которых нет в сборке (остались как есть)


## Директивы, на которые стоит посмотреть

- WIN32API.INC: `$UNDEF TRUE, FALSE, ANY, INTEGER`
- WINDOWS.INC: `$UNDEF BOOLEAN`
- QTextEdit.inc: `$UNDEF QRICHEDIT`
- RichEdPopUp.inc: `$UNDEF QRICHEDIT`
- HiLight.inc: `$APPTYPE GUI`
- HiLight.inc: `$UNDEF QRICHEDIT`
- TstRichEd.inc: `$UNDEF QRICHEDIT`
