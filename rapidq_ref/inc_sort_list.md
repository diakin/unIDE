# Разбор inc-файлов в inc_good / inc_bad

Дата файла в git не хранится, поэтому здесь записаны исходные даты (из архивов пользователя) и откуда взят файл.

## Шаг 1: RQIDEdistr2026inc/inc (даты из RQIDEdistr2026inc.zip)

Одноимённые файлы (без учёта регистра) сравнивались по дате; новейший — в inc_good, остальные — в inc_bad/RQIDEdistr2026inc/<прежний путь>.

| Файл | inc_good: откуда, дата | inc_bad: откуда, дата |
|---|---|---|
| ace32.inc | ACE32.INC (2008-07-09 16:09) | newinc/ACE32.INC (2008-07-09 16:09) |
| addmenuitembitmaps4a.inc | AddMenuItemBitmaps4a.inc (2005-11-10 12:06) |  |
| advapi32.inc | AdvAPI32.inc (2000-06-27 14:21) |  |
| allprops.inc | AllProps.inc (2005-11-10 12:06) |  |
| api.inc | Api.inc (2004-03-17 17:59) |  |
| api_richedid.inc | API_RichEdid.inc (2004-03-17 17:59) |  |
| apidate.inc | ApiDate.inc (2005-11-10 12:07) |  |
| apire.inc | apiRe.inc (2004-03-17 17:59) |  |
| c_constants.inc | C_Constants.inc (2004-03-17 17:59) |  |
| callback_0.inc | CallBack_0.Inc (2006-08-18 20:23) |  |
| callback_1.inc | CallBack_1.Inc (2006-08-18 20:23) |  |
| callback_2.inc | CallBack_2.Inc (2006-08-18 20:23) |  |
| callback_3.inc | CallBack_3.Inc (2006-08-18 20:23) |  |
| callback_4.inc | CallBack_4.Inc (2006-08-18 20:23) |  |
| callback_5.inc | CallBack_5.Inc (2006-08-18 20:23) |  |
| callback_6.inc | CallBack_6.Inc (2006-08-18 20:23) |  |
| callback_7.inc | CallBack_7.Inc (2006-08-18 20:23) |  |
| callback_8.inc | CallBack_8.Inc (2006-08-18 20:23) |  |
| callbackall.inc | CallBackAll.Inc (2006-08-18 20:23) |  |
| callbackforwarder.inc | CallBackForwarder.Inc (2006-08-18 20:23) |  |
| callbacks.inc | CallBacks.Inc (2008-09-18 20:22) |  |
| cgi.inc | cgi.inc (2008-07-09 16:10) | newinc/cgi.inc (2008-07-09 16:10) |
| cm_constants.inc | CM_Constants.inc (2004-03-17 17:59) |  |
| cm_functions.inc | CM_Functions.inc (2004-03-17 17:59) |  |
| cmd5.inc | CMD5.inc (2012-09-11 20:22) | newinc/CMD5.inc (2008-07-09 16:09); inc2/CMD5.inc (2006-05-06 10:15) |
| codesense.inc | CodeSense.inc (2005-11-10 12:07) |  |
| commctrl.inc | CommCtrl.inc (2008-11-27 23:32) |  |
| commctrl32.inc | newinc/commctrl32.inc (2008-07-09 16:10) | commctrl32.inc (2008-06-08 20:44) |
| common.inc | Common.inc (2004-02-23 19:30) |  |
| constants.inc | constants.inc (2026-10-09 07:32) |  |
| control.inc | Control.inc (2004-03-17 17:59) |  |
| conversion.inc | conversion.inc (2026-10-08 23:01) |  |
| conversion1.inc | conversion1.inc (2005-03-09 11:57) |  |
| conversionold.inc | conversionOld.inc (2008-04-05 15:14) |  |
| converttotruepath.inc | ConvertToTruePath.inc (2026-10-09 01:33) |  |
| copy of nota.inc | Copy of NOTA.inc (2000-06-25 04:10) |  |
| createwind.inc | createWind.inc (2004-03-17 17:59) |  |
| credit.inc | cREdit.inc (2004-03-17 17:59) |  |
| daqmx.inc | DAQmx.inc (2008-06-06 11:00) |  |
| daqmxconst.inc | DAQmxConst.inc (2008-06-05 10:16) |  |
| dbase.inc | Dbase.inc (2004-03-17 17:59) |  |
| dbt.inc | DBT.INC (2004-03-17 17:59) |  |
| dbtools.inc | dbtools.inc (2004-03-17 17:59) |  |
| debug.inc | debug.inc (2004-10-11 15:01) |  |
| debugnosend.inc | debugNoSend.inc (2004-10-11 15:03) |  |
| debugwindow.inc | debugWindow.inc (2005-01-14 15:05) |  |
| deltags.inc | delTags.inc (2026-10-08 22:43) |  |
| dxfone!h.inc | DxfONE!h.inc (2004-03-17 17:59) |  |
| email.inc | eMail.Inc (2005-11-10 12:07) |  |
| eml.inc | eml.inc (2026-10-09 01:03) |  |
| emlold.inc | emlOld.inc (2008-03-31 13:21) |  |
| evaluate.inc | newinc/evaluate.inc (2008-07-09 16:10) | evaluate.inc (2004-03-17 18:59) |
| fbfunctions.inc | FBFunctions.inc (2006-11-20 13:23) |  |
| fbscancodes.inc | fbscancodes.inc (2008-04-04 11:27) |  |
| fileops.inc | fileops.inc (2009-06-17 07:40) |  |
| files.inc | Files.inc (2026-10-09 01:08) |  |
| files1.inc | Files1.inc (2004-01-28 22:49) |  |
| files2.inc | Files2.inc (2004-01-28 23:33) |  |
| filesbug.inc | FilesBug.inc (2005-01-15 20:21) |  |
| fileutils.inc | FileUtils.inc (2004-03-17 17:59) |  |
| form.inc | Form.inc (2006-07-24 03:57) |  |
| form1.inc | Form1.inc (2005-11-10 12:07) |  |
| ftiquery.inc | newinc/ftiQuery.inc (2008-07-09 16:10) | ftiQuery.inc (2004-03-17 18:59) |
| func_array.inc | func_array.inc (2022-06-19 11:09) |  |
| functions.inc | Functions.inc (2004-03-17 17:59) |  |
| gdi32.inc | GDI32.inc (2000-06-27 16:01) |  |
| gl.inc | newinc/gl.inc (2008-07-09 16:10) | openGL/gl.inc (2001-02-12 07:17) |
| glaux.inc | openGL/glaux.inc (2001-02-12 10:53) |  |
| glext.inc | newinc/glext.inc (2008-07-09 16:10) |  |
| glfw.inc | newinc/glfw.inc (2008-07-09 16:10) |  |
| glu.inc | newinc/glu.inc (2008-07-09 16:10) | openGL/glu.inc (2001-02-12 07:14) |
| glut.inc | newinc/glut.inc (2008-07-09 16:10) |  |
| glwgl.inc | newinc/glwgl.inc (2008-07-09 16:10) | openGL/glwgl.inc (2001-02-12 07:13) |
| hilight.inc | HiLight.inc (2004-03-17 17:59) |  |
| htmlhelp.inc | htmlhelp.inc (2010-01-24 14:13) |  |
| kernel32.inc | Kernel32.inc (2000-06-29 17:56) |  |
| keys.inc | keys.inc (2005-11-10 12:07) |  |
| labelgrid.inc | LabelGrid.inc (2005-02-18 10:15) |  |
| langiniheader.inc | LangIniHeader.inc (2008-08-12 15:33) |  |
| like.inc | newinc/like.inc (2008-07-09 16:10) | like.inc (2007-12-22 15:15) |
| math.inc | Math.inc (2016-07-04 09:47) |  |
| mdi_api.inc | MDI_API.INC (2008-07-18 11:24) |  |
| memory.inc | Memory.inc (2009-02-06 21:09) |  |
| menu.inc | menu.inc (2005-11-10 12:07) |  |
| microtimer.inc | microTIMER.inc (2008-07-09 16:10) | newinc/microTIMER.inc (2008-07-09 16:10); inc2/microTIMER.inc (2006-05-21 19:56) |
| minimize.inc | Minimize.inc (2007-01-25 22:26) |  |
| msgdlg.inc | msgdlg.inc (2004-03-17 17:59) |  |
| mysql.inc | newinc/MYSQL.INC (2008-07-09 16:09) | MYSQL.INC (2004-03-17 17:59) |
| newwindow23.inc | NewWindow23.inc (2005-09-25 08:07) |  |
| newwndproc.inc | NewWndProc.Inc (2026-10-09 23:20) |  |
| ni6210.inc | NI6210.inc (2010-03-18 14:11) |  |
| nota.inc | NOTA.inc (2000-07-07 08:47) |  |
| objecttoolbox.inc | newinc/objectToolbox.inc (2008-07-09 16:10) | objectToolbox.inc (2004-03-17 17:59) |
| odbc.inc | odbc.inc (2003-12-05 18:54) |  |
| odmenuxp.inc | ODMenuXP.inc (2005-11-10 12:07) |  |
| ole.inc | newinc/ole.inc (2008-07-09 16:10) | ole.inc (2008-07-09 16:10); inc2/ole.inc (2006-04-27 19:41) |
| parse.inc | parse.inc (2026-10-09 01:09) |  |
| pdecl.inc | pdecl.inc (2004-03-17 17:59) |  |
| printdlg.inc | newinc/printdlg.inc (2008-07-09 16:10) | printdlg.inc (2004-03-20 14:06) |
| printerdll.inc | PRINTERDLL.INC (2004-11-09 03:01) |  |
| printrichedit.inc | newinc/printrichedit.inc (2008-07-09 16:10) | printrichedit.inc (2004-03-17 18:59) |
| pulsar.inc | pulsar.inc (2004-11-18 19:54) |  |
| qabout.inc | newinc/QAbout.inc (2008-07-09 16:09) | QAbout.inc (2004-03-17 17:59); obj2004/QAbout.inc (2003-03-03 20:54); object/QAbout.inc (2003-03-03 20:54) |
| qanim.inc | newinc/QAnim.inc (2008-07-09 16:09) | QAnim.inc (2004-03-17 17:59); obj2004/QAnim.inc (2003-04-22 14:39); object/QAnim.inc (2003-04-22 14:39) |
| qanimate.inc | QAnimate.inc (2009-02-10 09:31) |  |
| qavi.inc | QAVI.inc (2009-12-20 16:15) | newinc/QAVI.inc (2008-07-09 16:09); inc2/QAVI.inc (2005-12-03 12:01) |
| qbevel.inc | newinc/QBevel.inc (2008-07-09 16:09) | QBevel.inc (2004-03-17 17:59) |
| qbitmapex.inc | object/QBitmapEx.inc (2011-05-19 10:01) | QBitmapEx.inc (2003-12-31 08:29); obj2004/QBitmapEx.inc (2003-12-31 08:29) |
| qbrowsedialog.inc | QBrowseDialog.inc (2020-10-15 10:36) |  |
| qbuttonxp.inc | QButtonXP.INC (2021-04-10 11:54) | newinc/QButtonXP.inc (2008-07-09 16:09) |
| qcalendar.inc | newinc/qcalendar.inc (2008-07-09 16:10) | qcalendar.inc (2008-07-09 16:10) |
| qcanvasex.inc | QCanvasEx.inc (2004-03-17 17:59) | obj2004/QCanvasEx.inc (2003-01-03 16:52); object/QCanvasEx.inc (2003-01-03 16:52) |
| qcdaudio.inc | newinc/Qcdaudio.inc (2008-07-09 16:09) | Qcdaudio.inc (2005-08-04 19:34); inc2/Qcdaudio.inc (2005-08-04 19:34); obj2004/Qcdaudio.inc (2001-12-31 10:29); object/Qcdaudio.inc (2001-12-31 10:29) |
| qcgi.inc | newinc/qcgi.inc (2008-07-09 16:10) | qcgi.inc (2005-02-22 21:55) |
| qchart.inc | QChart.inc (2016-10-10 01:35) | newinc/QChart.inc (2008-07-09 16:09) |
| qciccio.inc | qciccio.inc (2005-11-10 12:07) |  |
| qcolorbutton.inc | newinc/QColorButton.inc (2008-07-09 16:09) | QColorButton.inc (2004-08-16 00:45) |
| qcolordialog.inc | QColorDialog.inc (2005-05-27 19:53) | obj2004/QColorDialog.inc (2003-02-09 16:05); object/QColorDialog.inc (2003-02-09 16:05) |
| qcoolbarxp90.inc | QCoolBarXP90.inc (2005-11-10 12:08) |  |
| qcoolbarxpv1d.inc | QCoolBarXPv1d.inc (2005-11-10 12:08) |  |
| qcursor.inc | QCursor.inc (2008-07-09 16:09) | newinc/QCursor.inc (2008-07-09 16:09); inc2/QCursor.inc (2005-08-04 19:35); obj2004/QCursor.inc (2003-11-06 17:56); object/QCursor.inc (2003-11-06 17:56) |
| qdatabase.inc | QDataBase.inc (2008-07-09 16:09) | newinc/QDataBase.inc (2008-07-09 16:09); obj2004/QDataBase.inc (2004-11-04 18:33) |
| qdatabasesql.inc | newinc/qdataBaseSQL.inc (2008-07-09 16:10) | qdataBaseSQL.inc (2008-07-09 16:10); inc2/qdataBaseSQL.inc (2006-03-09 21:15) |
| qdebug.inc | QDebug.inc (2005-11-10 12:08) |  |
| qdesktop.inc | QDesktop.inc (2008-07-09 16:09) | newinc/QDesktop.inc (2008-07-09 16:09); obj2004/QDesktop.inc (2003-09-23 20:26); object/QDesktop.inc (2003-09-23 20:26) |
| qdigdisplay.inc | QDigDisplay.inc (2008-07-09 16:09) | newinc/QDigDisplay.inc (2008-07-09 16:09); QDigDisplay/QDigDisplay.inc (2005-01-08 11:16); Led/QDigDisplay.inc (2004-03-17 17:59) |
| qdir.inc | newinc/QDir.Inc (2008-07-09 16:09) | QDir.Inc (2005-10-11 20:58); inc2/QDir.Inc (2005-10-11 19:58); qdir/QDIR.INC (2004-03-04 09:34) |
| qdirlistview.inc | qdirlistview.inc (2021-03-12 00:14) | newinc/QDirListView.inc (2008-07-09 16:09) |
| qdirlistview1.inc | QDirListView1.inc (2009-03-24 13:05) |  |
| qdockform.inc | QDOCKFORM.inc (2004-03-11 06:19) |  |
| qdownload.inc | newinc/Qdownload.inc (2008-07-09 16:09) | qdownload.inc (2005-09-30 16:29) |
| qdrawfocus.inc | newinc/QDrawFocus.inc (2008-07-09 16:09) | QDrawFocus.inc (2008-06-24 10:18); inc2/QDrawFocus.inc (2005-08-04 19:39); obj2004/QDrawFocus.inc (2003-01-03 15:35); object/QDrawFocus.inc (2003-01-03 15:35) |
| qdrawmenu.inc | QDrawMenu.inc (2008-07-09 16:09) | newinc/QDrawMenu.inc (2008-07-09 16:09); obj2004/QDrawMenu.inc (2003-02-09 16:23); object/QDrawMenu.inc (2003-02-09 16:23) |
| qdrive.inc | QDrive.inc (2012-09-09 18:03) | newinc/QDrive.inc (2008-07-09 16:09); inc2/QDrive.inc (2005-08-04 19:45); obj2004/QDrive.inc (2001-12-18 06:36); object/QDrive.inc (2001-12-18 06:36) |
| qdrive2024.inc | qdrive2024.inc (2024-03-03 23:08) |  |
| qdrivecombobox.inc | QDriveCombobox.inc (2008-07-09 16:09) | newinc/QDriveCombobox.inc (2008-07-09 16:09); inc2/QDriveCombobox.inc (2005-11-10 20:56); obj2004/QDriveCombobox.inc (2001-05-23 16:33); object/QDriveCombobox.inc (2001-05-23 16:33) |
| qdxf.inc | QDXF.inc (2005-11-10 12:08) |  |
| qeditex.inc | qEditEx.inc (2021-02-26 13:10) |  |
| qfiledialog.inc | QFileDialog.inc (2021-04-29 07:46) |  |
| qfiledialogdoc.inc | QFileDialogDoc.inc (2021-04-29 14:00) |  |
| qfilelistview.inc | QFileListView.inc (2008-07-09 16:09) | newinc/QFileListView.inc (2008-07-09 16:09); inc2/QFileListView.inc (2005-08-04 19:46); obj2004/QFileListView.inc (2004-06-28 17:49); object/QFileListView.inc (2003-11-18 18:01) |
| qfiles.inc | newinc/QFiles.inc (2008-07-09 16:09) | QFiles.inc (2004-03-17 17:59) |
| qflashlabel.inc | QFlashLabel.inc (2008-07-09 16:09) | newinc/QFlashLabel.inc (2008-07-09 16:09); obj2004/QFlashLabel.inc (2003-09-18 16:08); object/QFlashLabel.inc (2003-09-18 16:08) |
| qflatbutton.inc | newinc/QFlatButton.inc (2008-07-09 16:09) | QFlatButton.inc (2004-03-17 17:59) |
| qfocus.inc | newinc/qfocus.inc (2008-07-09 16:10) | qfocus.inc (2006-05-17 19:09) |
| qformex.inc | obj2004/QFormEx.inc (2006-05-23 10:30) | QFormEx.inc (2004-03-17 17:59); object/QFormEx.inc (2003-10-07 20:18) |
| qformlocale.inc | QFormLocale.inc (2009-09-05 23:03) |  |
| qformmdi.inc | QFormMDI.inc (2004-03-17 17:59) | obj2004/QFormMDI.inc (2003-04-27 20:25); object/QFormMDI.inc (2003-04-27 20:25) |
| qformskin.inc | QFormSkin.inc (2005-11-10 12:08) |  |
| qftpclient.inc | newinc/QFTPCLIENT.INC (2008-07-09 16:09) | QFTPCLIENT.INC (2005-05-29 11:08) |
| qftpdirlistview.inc | qftpdirlistview.inc (2009-03-25 13:43) |  |
| qfunclib.inc | QFuncLib.inc (2006-05-26 00:24) |  |
| qgl.inc | QGL.inc (2008-07-09 16:10) | newinc/QGL.inc (2008-07-09 16:10) |
| qgraph.inc | newinc/qgraph.inc (2008-07-09 16:10) | qgraph.inc (2004-03-17 18:59) |
| qgridcolor.inc | QGridColor.inc (2005-11-10 12:08) |  |
| qhead.inc | QHead.inc (2005-11-10 12:08) |  |
| qhtml.inc | QHTML.inc (2008-07-09 16:09) | newinc/QHTML.inc (2008-07-09 16:09) |
| qicmp.inc | newinc/QICMP.INC (2008-07-09 16:09) | QICMP.INC (2004-03-17 17:59) |
| qicon.inc | QICON.inc (2010-12-31 12:55) | newinc/QICON.inc (2008-07-09 16:09); inc2/QICON.inc (2005-08-04 19:50); obj2004/QICON.inc (2004-02-02 10:52); object/QICON.inc (2002-10-19 15:31) |
| qid3tag.inc | Qid3Tag.inc (2003-02-06 10:57) |  |
| qimagebox.inc | QImageBox.inc (2008-07-09 16:09) | newinc/QImageBox.inc (2008-07-09 16:09); obj2004/QImageBox.inc (2004-02-09 08:57) |
| qimagedialog.inc | QImageDialog.inc (2008-07-09 16:09) | newinc/QImageDialog.inc (2008-07-09 16:09); obj2004/QImageDialog.inc (2004-02-22 16:17); object/QImageDialog.inc (2003-12-31 13:52) |
| qimageex.inc | QImageEx.inc (2004-03-17 17:59) | obj2004/QImageEx.inc (2003-12-31 09:21); object/QImageEx.inc (2003-12-31 09:21) |
| qimagelistex.inc | QImageListEx.inc (2013-08-11 20:00) |  |
| qini.inc | newinc/QIni.inc (2008-07-09 16:09) | QIni.inc (2008-02-10 13:14); inc2/QIni.inc (2005-08-04 19:52); obj2004/QIni.inc (2001-12-19 10:31); object/QIni.inc (2001-12-19 10:31) |
| qinifile.inc | QIniFile.inc (2009-06-15 23:16) |  |
| qinputbox.inc | QInputBox.inc (2005-11-10 12:08) |  |
| qled.inc | QLed.inc (2005-11-10 12:08) |  |
| qledscroll.inc | QLedScroll.inc (2005-11-10 12:08) |  |
| qlibrary.inc | QLibrary.Inc (2005-11-10 12:08) |  |
| qline.inc | newinc/QLine.inc (2008-07-09 16:09) | QLine.inc (2004-03-17 17:59); obj2004/QLine.inc (2003-04-15 08:27); object/QLine.inc (2003-04-15 08:27) |
| qlistboxex.inc | QListBoxEx.inc (2008-07-09 16:09) | newinc/QListBoxEx.inc (2008-07-09 16:09); obj2004/QListBoxEx.inc (2004-10-24 14:46) |
| qlistviewex.inc | QListviewEx.inc (2004-03-17 17:59) |  |
| qmaillabel.inc | QMailLabel/QMailLabel.inc (2005-10-23 17:33) |  |
| qmarker.inc | QMarker.inc (2005-11-10 12:08) |  |
| qmaxedit.inc | qmaxedit.inc (2004-03-17 17:59) |  |
| qmaxsplitter.inc | newinc/QMaxSplitter.inc (2008-07-09 16:09) | QMaxSplitter.inc (2005-08-04 19:55); inc2/QMaxSplitter.inc (2005-08-04 19:55) |
| qmenu.inc | qmenu.inc (2004-03-17 17:59) |  |
| qmidi.inc | newinc/QMidi.inc (2008-07-09 16:09) | QMidi.inc (2004-03-17 17:59); obj2004/QMidi.inc (2004-01-18 17:03); object/QMidi.inc (2002-10-04 12:57) |
| qmp3.inc | newinc/Qmp3.inc (2008-07-09 16:09) | Qmp3.inc (2005-08-04 19:57); inc2/Qmp3.inc (2005-08-04 19:57) |
| qodbc.inc | qodbc.inc (2005-01-05 20:58) |  |
| qpagesetup.inc | newinc/QPageSetup.inc (2008-07-09 16:09) | QPageSetup.inc (2005-08-04 20:00); inc2/QPageSetup.inc (2005-08-04 20:00); obj2004/QPageSetup.inc (2003-02-25 21:29); object/QPageSetup.inc (2003-02-25 21:29) |
| qpoint.inc | QPoint.inc (2005-11-10 12:08) |  |
| qposic.inc | qposic.inc (2004-03-17 17:59) |  |
| qposic1.inc | Qposic1.inc (2021-04-01 10:30) |  |
| qposicl.inc | QPosicL.inc (2004-04-11 21:29) |  |
| qprintdialog.inc | QPrintDialog.inc (2005-11-10 12:08) |  |
| qprinterinfo.inc | newinc/QPrinterInfo.inc (2008-07-09 16:09) | QPrinterInfo.inc (2004-03-17 17:59); obj2004/QPrinterInfo.inc (2003-02-27 06:45); object/QPrinterInfo.inc (2003-02-27 06:45) |
| qprocess.inc | newinc/QProcess.inc (2008-07-09 16:09) | QProcess.inc (2006-12-26 13:31); inc2/QProcess.inc (2005-10-17 17:00); obj2004/QProcess.inc (2003-10-10 13:59); object/QProcess.inc (2003-10-10 13:59) |
| qprogress.inc | QProgress.inc (2010-10-25 21:13) | newinc/QProgress.inc (2008-07-09 16:09); obj2004/QProgress.inc (2003-05-02 11:06); object/QProgress.inc (2003-05-02 11:06) |
| qprogressbar.inc | QProgressBar.inc (2010-11-10 20:21) |  |
| qredex.inc | QRedEx.Inc (2006-08-12 21:23) | QRedEx/QRedEx.Inc (2005-06-04 09:25) |
| qredextest.inc | QREDEXTest.INC (2005-09-26 17:59) |  |
| qredextest2.inc | QREDEXTest2.INC (2005-09-26 18:26) |  |
| qredit.inc | newinc/qREdit.inc (2008-07-09 16:10) | qREdit.inc (2004-03-17 17:59) |
| qricheditxt.inc | newinc/QRichEditXt.inc (2008-07-09 16:09) | QRichEditXt.inc (2004-05-12 10:27) |
| qrpanel.inc | QrPanel.inc (2008-07-18 12:59) | newinc/QrPanel.inc (2008-07-09 16:09) |
| qrun.inc | QRun.inc (2009-06-15 22:15) | newinc/QRun.inc (2008-07-09 16:09); obj2004/QRun.inc (2004-10-19 17:27); object/QRun.inc (2002-01-03 14:56) |
| qsaveplus.inc | QSavePlus.inc (2008-07-10 17:12) |  |
| qshfileoperation.inc | newinc/QSHFileOperation.inc (2008-07-09 16:09) | QSHFileOperation.inc (2004-03-17 17:59) |
| qshutdown.inc | QShutdown.inc (2008-07-09 16:09) | newinc/QShutdown.inc (2008-07-09 16:09) |
| qskin.inc | QSkin.inc (2008-07-09 16:09) | newinc/QSkin.inc (2008-07-09 16:09); obj2004/QSkin.inc (2003-09-16 19:09); object/QSkin.inc (2003-09-16 19:09) |
| qskinbtn.inc | QSkinBtn.inc (2008-07-09 16:09) | newinc/QSkinBtn.inc (2008-07-09 16:09); obj2004/QSkinBtn.inc (2003-08-28 16:46); object/QSkinBtn.inc (2003-08-28 16:46) |
| qsocketex.inc | QSocketEx.inc (2008-07-09 16:09) | newinc/QSocketEx.inc (2008-07-09 16:09) |
| qspinedit.inc | newinc/QSpinEdit.inc (2008-07-09 16:09) | QSpinEdit.inc (2005-11-10 12:08) |
| qspintext.inc | qspintext.inc (2004-06-15 12:00) |  |
| qspintextev.inc | qspintextev.inc (2004-04-20 13:22) |  |
| qspintextold.inc | qspintextOld.inc (2004-04-20 13:25) |  |
| qsplash.inc | QSplash.inc (2008-07-19 21:27) | newinc/QSplash.inc (2008-07-09 16:09); obj2004/QSplash.inc (2004-07-30 18:43); object/QSplash.inc (2003-04-29 21:09) |
| qsplitter.inc | QSplitter.inc (2008-07-09 16:09) | newinc/QSplitter.inc (2008-07-09 16:09) |
| qstatusbarex.inc | newinc/QStatusBarEx.inc (2008-07-09 16:09) | QStatusBarEx.inc (2004-03-17 17:59); obj2004/QStatusBarEx.inc (2003-02-04 10:17); object/QStatusBarEx.inc (2003-02-04 10:17) |
| qstringgridex.inc | QStringGridEx.inc (2008-07-09 16:09) | newinc/QStringGridEx.inc (2008-07-09 16:09); obj2004/QStringGridEx.inc (2003-06-25 12:16); object/QStringGridEx.inc (2003-06-25 12:16) |
| qtabcontrolex.inc | QtabControlEx.inc (2026-10-04 07:06) | newinc/QtabControlEx.inc (2008-07-09 16:09); obj2004/QtabControlEx.inc (2004-09-22 22:00) |
| qtbutton.inc | QTButton.inc (2005-11-10 12:08) |  |
| qtbutton72.inc | QTButton72.inc (2005-11-10 12:08) |  |
| qtbutton85b.inc | QTButton85b.inc (2005-11-10 12:08) |  |
| qtbutton94.inc | QTButton94.inc (2005-11-10 12:08) |  |
| qtbutton94b.inc | QTButton94b.inc (2005-11-10 12:08) |  |
| qtbutton95.inc | QTButton95.inc (2005-11-10 12:08) |  |
| qtbutton_addons.inc | QTButton_AddOns.inc (2005-11-10 12:08) |  |
| qtextbtn.inc | QTextBtn.inc (2010-06-21 22:20) | newinc/QTextBtn.inc (2008-07-09 16:09); obj2004/QTextBtn.inc (2003-08-31 09:09); object/QTextBtn.inc (2003-08-31 09:09) |
| qtextedit.inc | newinc/QTextEdit.inc (2008-07-09 16:09) | QTextEdit.inc (2005-09-26 18:53); obj2004/QTextEdit.inc (2002-02-15 13:20); object/QTextEdit.inc (2002-02-15 13:20) |
| qtextedittest.inc | QTextEditTest.inc (2005-09-26 18:51) |  |
| qthread.inc | obj2004/QThread.inc (2009-02-06 15:04) |  |
| qtoolbar.inc | QToolBar.inc (2009-06-15 23:17) |  |
| qtoolbarex.inc | QToolBarEX.inc (2013-08-11 20:00) |  |
| qtreeviewex.inc | newinc/QTreeviewEx.inc (2008-07-09 16:09) | obj2004/QTreeViewEx.inc (2004-10-08 13:34); QTreeviewEx.inc (2004-03-17 17:59) |
| qvideo.inc | newinc/QVideo.inc (2008-07-09 16:09) | QVideo.inc (2005-01-13 13:23); obj2004/QVideo.inc (2004-01-18 16:54); object/QVideo.inc (2002-10-04 12:58) |
| qvolumeinfo.inc | QVolumeInfo.inc (2012-09-09 19:26) |  |
| qvumeter.inc | QVuMeter.inc (2008-07-09 16:09) | newinc/QVuMeter.inc (2008-07-09 16:09); obj2004/QVuMeter.inc (2003-08-31 08:48); object/QVuMeter.inc (2003-08-31 08:48) |
| qwave.inc | newinc/QWave.inc (2008-07-09 16:09) | QWave.inc (2004-03-17 17:59); obj2004/QWave.inc (2004-01-18 17:00); object/QWave.inc (2002-10-04 12:57) |
| qwinini.inc | QWinIni.inc (2004-03-17 17:59) |  |
| qxedit.inc | QxEdit.inc (2004-02-20 14:19) |  |
| qxls.inc | newinc/QXLS.INC (2008-07-09 16:09) | QXLS.INC (2003-06-09 15:34) |
| qxpbutton.inc | QXPButton.inc (2010-08-11 19:49) |  |
| qxptheme.inc | QXpTheme.INC (2005-11-10 12:09) |  |
| rapidfrm.inc | RapidFRM.inc (2021-02-28 17:22) |  |
| rapidfrm_mods.inc | RapidFRM_Mods.inc (2021-02-28 23:12) |  |
| rapidq.inc | rapidq.inc (2026-10-09 01:14) | newinc/rapidq.inc (2008-07-09 16:10); inc2/rapidq.inc (2005-11-26 16:01) |
| rapidq2.inc | rapidq2.inc (2021-12-15 21:40) | newinc/RAPIDQ2.inc (2008-07-09 16:09); inc2/RAPIDQ2.inc (2006-04-12 14:00) |
| rapidq2007.inc | rapidq2007.inc (2008-01-16 14:08) |  |
| rapidq_d3d.inc | RapidQ_D3D.inc (2011-02-05 17:01) | newinc/RapidQ_D3D.inc (2008-07-09 16:09); inc2/RapidQ_D3D.inc (2006-03-05 18:21) |
| rapidq_ex.inc | rapidq_ex.inc (2008-05-11 13:15) |  |
| rapidqbug.inc | RAPIDQbug.INC (2005-01-15 20:04) |  |
| rapidql.inc | RAPIDQl.INC (2004-07-28 02:36) |  |
| rc4crypt.inc | RC4crypt.inc (2009-09-21 12:10) | newinc/RC4crypt.inc (2008-07-09 16:09) |
| registryvars.inc | registryVars.inc (2004-10-13 06:24) |  |
| resources2.inc | Resources2.inc (2005-11-10 12:09) |  |
| richeditapi.inc | RichEditApi.inc (2004-03-17 17:59) |  |
| richedpopup.inc | RichEdPopUp.inc (2008-07-09 11:24) |  |
| richedpopup1.inc | RichEdPopUp1.inc (2006-05-08 04:15) |  |
| richedpopupold.inc | RichEdPopUpold.inc (2005-01-13 10:08) |  |
| rq_math.inc | rq_math.inc (2004-03-17 17:59) |  |
| rqasmutils.inc | RqAsmUtils.Inc (2008-07-09 16:09) | newinc/RqAsmUtils.Inc (2008-07-09 16:09) |
| rqdate.inc | RQdate.inc (2008-01-22 14:36) |  |
| rqdialog.inc | RQDialog.inc (2004-03-17 17:59) |  |
| rqdxf.inc | RQDxf.inc (2004-03-17 17:59) |  |
| rqprocess.inc | RQProcess.inc (2008-07-07 14:54) |  |
| rsocket.inc | inc2/RSocket.INC (2005-01-06 08:44) | RSocket.INC (2003-06-06 16:11) |
| setfiletimeattrib.inc | SetFileTimeAttrib.inc (2004-07-04 18:45) |  |
| setup.inc | setup.inc (2004-03-17 17:59) |  |
| shell32.inc | Shell32.inc (2000-06-27 14:21) |  |
| shellredir.inc | ShellRedir.Inc (2011-02-23 22:02) |  |
| splash.inc | Splash.inc (2006-02-19 22:35) |  |
| splashform.inc | SplashForm.inc (2005-11-10 12:10) |  |
| stayontop.inc | StayOnTop.inc (2005-11-10 12:10) |  |
| stdobjbar.inc | stdObjbar.inc (2021-03-13 15:21) |  |
| stdobjmnu.inc | stdObjMnu.inc (2005-07-22 20:34) |  |
| sysutils.inc | SysUtils.inc (2008-11-11 23:03) |  |
| testincpath.inc | TestIncPAth.inc (2005-09-25 20:57) |  |
| trm_rqdeclares.inc | TRM_RQDeclares.INC (2004-03-17 17:59) |  |
| tstriched.inc | TstRichEd.inc (2004-09-23 16:14) |  |
| ultrariched.inc | ultraRichEd.inc (2004-03-17 17:59) |  |
| user32.inc | User32.inc (2000-07-07 15:09) |  |
| using.inc | using.inc (2004-03-17 17:59) |  |
| var.inc | var.inc (2021-04-01 10:31) |  |
| var2008.inc | var2008.inc (2013-05-24 10:14) |  |
| vfw.inc | VFW.inc (2008-07-09 16:09) | newinc/VFW.inc (2008-07-09 16:09) |
| vfw2.inc | vfw2.inc (2012-03-21 20:56) | newinc/VFW2.inc (2008-07-09 16:09); inc2/VFW2.inc (2006-02-05 17:55) |
| wad3.inc | Wad3.inc (2004-03-17 17:59) |  |
| webcam.inc | WebCam.inc (2008-07-09 16:10) | newinc/WebCam.inc (2008-07-09 16:10) |
| wfunctions.inc | WFunctions.inc (2005-11-10 12:10) |  |
| win32_constants.inc | Win32_constants.inc (2004-03-17 17:59) |  |
| win32api.inc | WIN32API.INC (2007-05-02 13:18) |  |
| windows.inc | WINDOWS.INC (2021-12-15 21:23) | newinc/WINDOWS.INC (2008-07-09 16:10); inc2/WINDOWS.INC (2006-04-12 14:06) |
| windowsapi.inc | WindowsAPI.inc (2000-07-01 17:57) |  |
| winmm.inc | WinMM.Inc (2000-06-28 01:20) |  |
| xp_manifest.inc | XP_MANIFEST.INC (2009-04-02 14:08) | newinc/XP_MANIFEST.INC (2008-07-09 16:10); inc2/XP_MANIFEST.INC (2006-05-21 01:38) |
| xp_manifest1.inc | xp_manifest1.inc (2021-04-10 01:29) |  |
| xpskinmetallic_2.11_res.inc | XPSkinMetallic_2.11_Res.inc (2005-11-10 12:10) |  |
| xpthemes.inc | XPThemes.inc (2009-06-15 22:50) |  |
| zlib.inc | zlib.inc (2006-10-04 21:27) |  |

## Шаг 2: inc2026 (исправленные файлы, считаются новее)

Побайтное сравнение с inc_good. «заменён» — версия inc2026 отличается, она в inc_good, прежняя — в inc_bad/<её путь>. «совпадает» — копия из inc2026 в inc_bad/inc2026. Файлы с ресурсами — в inc_good/<имя>/ вместе с ресурсами.

| Файл inc2026 | Результат | Прежний файл inc_good |
|---|---|---|
| Api.inc | совпадает | RQIDEdistr2026inc/Api.inc |
| ApiDate.inc | заменён | RQIDEdistr2026inc/ApiDate.inc 2005-11-10 12:07 |
| apiRe.inc | совпадает | RQIDEdistr2026inc/apiRe.inc |
| CallBack_0.Inc | заменён | RQIDEdistr2026inc/CallBack_0.Inc 2006-08-18 20:23 |
| CallBack_1.Inc | заменён | RQIDEdistr2026inc/CallBack_1.Inc 2006-08-18 20:23 |
| CallBack_2.Inc | заменён | RQIDEdistr2026inc/CallBack_2.Inc 2006-08-18 20:23 |
| CallBack_3.Inc | заменён | RQIDEdistr2026inc/CallBack_3.Inc 2006-08-18 20:23 |
| CallBack_4.Inc | заменён | RQIDEdistr2026inc/CallBack_4.Inc 2006-08-18 20:23 |
| CallBack_5.Inc | заменён | RQIDEdistr2026inc/CallBack_5.Inc 2006-08-18 20:23 |
| CallBack_6.Inc | заменён | RQIDEdistr2026inc/CallBack_6.Inc 2006-08-18 20:23 |
| CallBack_7.Inc | заменён | RQIDEdistr2026inc/CallBack_7.Inc 2006-08-18 20:23 |
| CallBack_8.Inc | заменён | RQIDEdistr2026inc/CallBack_8.Inc 2006-08-18 20:23 |
| CallBacks.Inc | заменён | RQIDEdistr2026inc/CallBacks.Inc 2008-09-18 20:22 |
| ComPort.inc | новый |  |
| COMPORTxp.inc | новый |  |
| conversion.inc | заменён | RQIDEdistr2026inc/conversion.inc 2026-10-08 23:01 |
| eml.inc | заменён | RQIDEdistr2026inc/eml.inc 2026-10-09 01:03 |
| fbscancodes.inc | совпадает | RQIDEdistr2026inc/fbscancodes.inc |
| fileops.inc | совпадает | RQIDEdistr2026inc/fileops.inc |
| Files.inc | заменён | RQIDEdistr2026inc/Files.inc 2026-10-09 01:08 |
| func_array.inc | совпадает | RQIDEdistr2026inc/func_array.inc |
| HiLight.inc | совпадает | RQIDEdistr2026inc/HiLight.inc |
| Memory.inc | заменён | RQIDEdistr2026inc/Memory.inc 2009-02-06 21:09 |
| odbc.inc | заменён | RQIDEdistr2026inc/odbc.inc 2003-12-05 18:54 |
| parse.inc | заменён | RQIDEdistr2026inc/parse.inc 2026-10-09 01:09 |
| QAbout.inc | совпадает | RQIDEdistr2026inc/newinc/QAbout.inc |
| QAnim.inc | заменён | RQIDEdistr2026inc/newinc/QAnim.inc 2008-07-09 16:09 |
| QAnimate.inc | заменён | RQIDEdistr2026inc/QAnimate.inc 2009-02-10 09:31 |
| QAVI.inc | заменён | RQIDEdistr2026inc/QAVI.inc 2009-12-20 16:15 |
| QBevel.inc | заменён | RQIDEdistr2026inc/newinc/QBevel.inc 2008-07-09 16:09 |
| QBitmapEx.inc | заменён | RQIDEdistr2026inc/object/QBitmapEx.inc 2011-05-19 10:01 |
| QBrowseDialog.inc | совпадает | RQIDEdistr2026inc/QBrowseDialog.inc |
| QButtonXP.INC | заменён | RQIDEdistr2026inc/QButtonXP.INC 2021-04-10 11:54 |
| qcalendar.inc | заменён | RQIDEdistr2026inc/newinc/qcalendar.inc 2008-07-09 16:10 |
| QCanvasEx.inc | совпадает | RQIDEdistr2026inc/QCanvasEx.inc |
| Qcdaudio.inc | заменён | RQIDEdistr2026inc/newinc/Qcdaudio.inc 2008-07-09 16:09 |
| qcgi.inc | совпадает | RQIDEdistr2026inc/newinc/qcgi.inc |
| QChart.inc | заменён | RQIDEdistr2026inc/QChart.inc 2016-10-10 01:35 |
| qciccio.inc | совпадает | RQIDEdistr2026inc/qciccio.inc |
| QColorButton.inc | совпадает | RQIDEdistr2026inc/newinc/QColorButton.inc |
| QColorDialog.inc | заменён | RQIDEdistr2026inc/QColorDialog.inc 2005-05-27 19:53 |
| QCoolBarXPv1d.inc | заменён | RQIDEdistr2026inc/QCoolBarXPv1d.inc 2005-11-10 12:08 |
| QCursor.inc | совпадает | RQIDEdistr2026inc/QCursor.inc |
| QDataBase.inc | заменён | RQIDEdistr2026inc/QDataBase.inc 2008-07-09 16:09 |
| QDebug.inc | заменён | RQIDEdistr2026inc/QDebug.inc 2005-11-10 12:08 |
| QDesktop.inc | совпадает | RQIDEdistr2026inc/QDesktop.inc |
| QDigDisplay.inc | совпадает | RQIDEdistr2026inc/QDigDisplay.inc |
| QDir.Inc | заменён | RQIDEdistr2026inc/newinc/QDir.Inc 2008-07-09 16:09 |
| qdirlistview/qdirlistview.inc | заменён | RQIDEdistr2026inc/qdirlistview.inc 2021-03-12 00:14 |
| QDOCKFORM.inc | заменён | RQIDEdistr2026inc/QDOCKFORM.inc 2004-03-11 06:19 |
| qdownload.inc | заменён | RQIDEdistr2026inc/newinc/Qdownload.inc 2008-07-09 16:09 |
| QDrawFocus.inc | заменён | RQIDEdistr2026inc/newinc/QDrawFocus.inc 2008-07-09 16:09 |
| QDrawMenu.inc | совпадает | RQIDEdistr2026inc/QDrawMenu.inc |
| QDrive.inc | совпадает | RQIDEdistr2026inc/QDrive.inc |
| QDriveCombobox.inc | заменён | RQIDEdistr2026inc/QDriveCombobox.inc 2008-07-09 16:09 |
| QFileDialog.inc | заменён | RQIDEdistr2026inc/QFileDialog.inc 2021-04-29 07:46 |
| QFileListView.inc | совпадает | RQIDEdistr2026inc/QFileListView.inc |
| QFlashLabel.inc | совпадает | RQIDEdistr2026inc/QFlashLabel.inc |
| QFlatButton.inc | заменён | RQIDEdistr2026inc/newinc/QFlatButton.inc 2008-07-09 16:09 |
| qfocus.inc | совпадает | RQIDEdistr2026inc/newinc/qfocus.inc |
| QFormEx.inc | заменён | RQIDEdistr2026inc/obj2004/QFormEx.inc 2006-05-23 10:30 |
| QFormMDI.inc | заменён | RQIDEdistr2026inc/QFormMDI.inc 2004-03-17 17:59 |
| QFTPCLIENT.INC | совпадает | RQIDEdistr2026inc/newinc/QFTPCLIENT.INC |
| qftpdirlistview/qftpdirlistview.inc | заменён | RQIDEdistr2026inc/qftpdirlistview.inc 2009-03-25 13:43 |
| QGL.inc | заменён | RQIDEdistr2026inc/QGL.inc 2008-07-09 16:10 |
| qgraph.inc | заменён | RQIDEdistr2026inc/newinc/qgraph.inc 2008-07-09 16:10 |
| QGridColor.inc | совпадает | RQIDEdistr2026inc/QGridColor.inc |
| QHead.inc | заменён | RQIDEdistr2026inc/QHead.inc 2005-11-10 12:08 |
| QHTML.inc | заменён | RQIDEdistr2026inc/QHTML.inc 2008-07-09 16:09 |
| QICMP.INC | совпадает | RQIDEdistr2026inc/newinc/QICMP.INC |
| QICON.inc | совпадает | RQIDEdistr2026inc/QICON.inc |
| Qid3Tag.inc | заменён | RQIDEdistr2026inc/Qid3Tag.inc 2003-02-06 10:57 |
| QImageBox.inc | совпадает | RQIDEdistr2026inc/QImageBox.inc |
| QImageDialog.inc | совпадает | RQIDEdistr2026inc/QImageDialog.inc |
| QImageEx.inc | заменён | RQIDEdistr2026inc/QImageEx.inc 2004-03-17 17:59 |
| QImageListEx.inc | совпадает | RQIDEdistr2026inc/QImageListEx.inc |
| QIni.inc | заменён | RQIDEdistr2026inc/newinc/QIni.inc 2008-07-09 16:09 |
| QIniFile.inc | совпадает | RQIDEdistr2026inc/QIniFile.inc |
| QInputBox.inc | совпадает | RQIDEdistr2026inc/QInputBox.inc |
| QLed.inc | заменён | RQIDEdistr2026inc/QLed.inc 2005-11-10 12:08 |
| QLedScroll.inc | совпадает | RQIDEdistr2026inc/QLedScroll.inc |
| QLine.inc | совпадает | RQIDEdistr2026inc/newinc/QLine.inc |
| QListBoxEx.inc | совпадает | RQIDEdistr2026inc/QListBoxEx.inc |
| QListviewEx.inc | совпадает | RQIDEdistr2026inc/QListviewEx.inc |
| QMarker.inc | совпадает | RQIDEdistr2026inc/QMarker.inc |
| QMaxSplitter.inc | заменён | RQIDEdistr2026inc/newinc/QMaxSplitter.inc 2008-07-09 16:09 |
| qmenu.inc | заменён | RQIDEdistr2026inc/qmenu.inc 2004-03-17 17:59 |
| QMidi.inc | заменён | RQIDEdistr2026inc/newinc/QMidi.inc 2008-07-09 16:09 |
| Qmp3.inc | заменён | RQIDEdistr2026inc/newinc/Qmp3.inc 2008-07-09 16:09 |
| QPageSetup.inc | совпадает | RQIDEdistr2026inc/newinc/QPageSetup.inc |
| Qposic1/Qposic1.inc | заменён | RQIDEdistr2026inc/Qposic1.inc 2021-04-01 10:30 |
| QPosicL/QPosicL.inc | заменён | RQIDEdistr2026inc/QPosicL.inc 2004-04-11 21:29 |
| QPrinterInfo.inc | заменён | RQIDEdistr2026inc/newinc/QPrinterInfo.inc 2008-07-09 16:09 |
| QProcess.inc | заменён | RQIDEdistr2026inc/newinc/QProcess.inc 2008-07-09 16:09 |
| QProgress.inc | совпадает | RQIDEdistr2026inc/QProgress.inc |
| QProgressBar.inc | заменён | RQIDEdistr2026inc/QProgressBar.inc 2010-11-10 20:21 |
| QRedEx.Inc | заменён | RQIDEdistr2026inc/QRedEx.Inc 2006-08-12 21:23 |
| QRichEditXt.inc | заменён | RQIDEdistr2026inc/newinc/QRichEditXt.inc 2008-07-09 16:09 |
| QrPanel.inc | совпадает | RQIDEdistr2026inc/QrPanel.inc |
| QRun.inc | заменён | RQIDEdistr2026inc/QRun.inc 2009-06-15 22:15 |
| QSavePlus.inc | совпадает | RQIDEdistr2026inc/QSavePlus.inc |
| QSHFileOperation.inc | заменён | RQIDEdistr2026inc/newinc/QSHFileOperation.inc 2008-07-09 16:09 |
| QShutdown.inc | заменён | RQIDEdistr2026inc/QShutdown.inc 2008-07-09 16:09 |
| QSkin.inc | совпадает | RQIDEdistr2026inc/QSkin.inc |
| QSkinBtn.inc | совпадает | RQIDEdistr2026inc/QSkinBtn.inc |
| QSocketEx.inc | заменён | RQIDEdistr2026inc/QSocketEx.inc 2008-07-09 16:09 |
| QSpinEdit.inc | заменён | RQIDEdistr2026inc/newinc/QSpinEdit.inc 2008-07-09 16:09 |
| qspintext.inc | совпадает | RQIDEdistr2026inc/qspintext.inc |
| QSplash.inc | совпадает | RQIDEdistr2026inc/QSplash.inc |
| QStatusBarEx.inc | заменён | RQIDEdistr2026inc/newinc/QStatusBarEx.inc 2008-07-09 16:09 |
| QStringGridEx.inc | совпадает | RQIDEdistr2026inc/QStringGridEx.inc |
| QtabControlEx.inc | заменён | RQIDEdistr2026inc/QtabControlEx.inc 2026-10-04 07:06 |
| QTButton95.inc | совпадает | RQIDEdistr2026inc/QTButton95.inc |
| QTextBtn.inc | совпадает | RQIDEdistr2026inc/QTextBtn.inc |
| QTextEdit.inc | заменён | RQIDEdistr2026inc/newinc/QTextEdit.inc 2008-07-09 16:09 |
| QToolBar.inc | заменён | RQIDEdistr2026inc/QToolBar.inc 2009-06-15 23:17 |
| QToolBarEX.inc | совпадает | RQIDEdistr2026inc/QToolBarEX.inc |
| QTreeviewEx.inc | заменён | RQIDEdistr2026inc/newinc/QTreeviewEx.inc 2008-07-09 16:09 |
| QVideo.inc | совпадает | RQIDEdistr2026inc/newinc/QVideo.inc |
| QVolumeInfo.inc | заменён | RQIDEdistr2026inc/QVolumeInfo.inc 2012-09-09 19:26 |
| QVuMeter.inc | совпадает | RQIDEdistr2026inc/QVuMeter.inc |
| QWave.inc | заменён | RQIDEdistr2026inc/newinc/QWave.inc 2008-07-09 16:09 |
| QxEdit.inc | совпадает | RQIDEdistr2026inc/QxEdit.inc |
| QXPButton.inc | совпадает | RQIDEdistr2026inc/QXPButton.inc |
| RapidFRM.inc | совпадает | RQIDEdistr2026inc/RapidFRM.inc |
| rapidq.inc | заменён | RQIDEdistr2026inc/rapidq.inc 2026-10-09 01:14 |
| rapidq2.inc | заменён | RQIDEdistr2026inc/rapidq2.inc 2021-12-15 21:40 |
| RapidQ_D3D.inc | заменён | RQIDEdistr2026inc/RapidQ_D3D.inc 2011-02-05 17:01 |
| RC4crypt.inc | совпадает | RQIDEdistr2026inc/RC4crypt.inc |
| RichEdPopUp.inc | совпадает | RQIDEdistr2026inc/RichEdPopUp.inc |
| RSocket.INC | заменён | RQIDEdistr2026inc/inc2/RSocket.INC 2005-01-06 08:44 |
| SysUtils.inc | заменён | RQIDEdistr2026inc/SysUtils.inc 2008-11-11 23:03 |
| TstRichEd.inc | совпадает | RQIDEdistr2026inc/TstRichEd.inc |
| VFW.inc | заменён | RQIDEdistr2026inc/VFW.inc 2008-07-09 16:09 |
| XP_MANIFEST.INC | заменён | RQIDEdistr2026inc/XP_MANIFEST.INC 2009-04-02 14:08 |
| XPSkinMetallic_2.11_Res.inc | заменён | RQIDEdistr2026inc/XPSkinMetallic_2.11_Res.inc 2005-11-10 12:10 |
| XPThemes.inc | совпадает | RQIDEdistr2026inc/XPThemes.inc |
