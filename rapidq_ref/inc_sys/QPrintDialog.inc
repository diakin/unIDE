' QPrintDialog.inc - отдельный inc, не входит в rapidqAllProc.inc /
' rapidqComponents.inc: пример - при запуске открывает окно параметров страницы и печатает поля через PRINT.
' Собран rapidq_ref/tools/build_inc.py из incOld/QPrintDialog.inc; повторы объявлений
' общих файлов убраны (build_removed.txt). Подключать в программе,
' которой он нужен.
$IFNDEF __SEP_QPRINTDIALOG_INC
$DEFINE __SEP_QPRINTDIALOG_INC
$INCLUDE "rapidqComponents.inc"
'============================================================================
'[build_inc] QPrintDialog.inc
'============================================================================
' Page setup dialog example

PSD.lStructSize = SIZEOF(PSD)
PSD.Flags = PSD_MINMARGINS + PSD_MARGINS
PSD.hWndOwner = 0

PRINT IIF(PageSetupDlg(PSD), "Start printing", "Cancel print")
?PSD.rtMarginLeft
?PSD.rtMarginTop
?PSD.rtMarginRight
?PSD.rtMarginBottom

$ENDIF ' __SEP_QPRINTDIALOG_INC
