' QPrintDialog.inc - отдельный inc, не входит в rapidqAllProc.inc /
' rapidqComponents.inc: пример - при запуске открывает окно параметров страницы и печатает поля через PRINT.
' Собран rapidq_ref/tools/build_inc.py из incOld/QPrintDialog.inc; повторы объявлений
' общих файлов - '~dup. Подключать в программе, которой он нужен.
$IFNDEF __SEP_QPRINTDIALOG_INC
$DEFINE __SEP_QPRINTDIALOG_INC
$INCLUDE "rapidqComponents.inc"
'============================================================================
'[build_inc] QPrintDialog.inc
'============================================================================
' Page setup dialog example

'~dup CONST PSD_DEFAULTMINMARGINS = 0   ' повтор, первое: rapidq2.inc(7210)
'~dup CONST PSD_MINMARGINS = &H1   ' повтор, первое: rapidq2.inc(7211)
'~dup CONST PSD_MARGINS = &H2   ' повтор, первое: rapidq2.inc(7212)
'~dup CONST PSD_INTHOUSANDTHSOFINCHES = &H4   ' повтор, первое: rapidq2.inc(7213)
'~dup CONST PSD_INHUNDREDTHSOFMILLIMETERS = &H8   ' повтор, первое: rapidq2.inc(7214)
'~dup CONST PSD_DISABLEMARGINS = &H10   ' повтор, первое: rapidq2.inc(7215)
'~dup CONST PSD_DISABLEPRINTER = &H20   ' повтор, первое: rapidq2.inc(7216)
'~dup CONST PSD_NOWARNING = &H80   ' повтор, первое: rapidq2.inc(7217)
'~dup CONST PSD_DISABLEORIENTATION = &H100   ' повтор, первое: rapidq2.inc(7218)
'~dup CONST PSD_DISABLEPAPER = &H200   ' повтор, первое: rapidq2.inc(7219)
'~dup CONST PSD_RETURNDEFAULT = &H400   ' повтор, первое: rapidq2.inc(7220)
'~dup CONST PSD_SHOWHELP = &H800   ' повтор, первое: rapidq2.inc(7221)
'~dup CONST PSD_ENABLEPAGESETUPHOOK = &H2000   ' повтор, первое: rapidq2.inc(7222)
'~dup CONST PSD_ENABLEPAGESETUPTEMPLATE = &H8000   ' повтор, первое: rapidq2.inc(7223)
'~dup CONST PSD_ENABLEPAGESETUPTEMPLATEHANDLE = &H20000   ' повтор, первое: rapidq2.inc(7224)
'~dup CONST PSD_ENABLEPAGEPAINTHOOK = &H40000   ' повтор, первое: rapidq2.inc(7225)
'~dup CONST PSD_DISABLEPAGEPAINTING = &H80000   ' повтор, первое: rapidq2.inc(7226)
'~dup CONST PSD_NONETWORKBUTTON = &H200000   ' повтор, первое: rapidq2.inc(7227)

'~dup TYPE TPSD   ' повтор, первое: rapidq2.inc(7232)
'~dup     lStructSize AS LONG
'~dup     hWndOwner AS LONG
'~dup     hDevMode AS LONG
'~dup     hDevNames AS LONG
'~dup     Flags AS LONG
'~dup     ptPaperSizeX AS LONG
'~dup     ptPaperSizeY AS LONG
'~dup     rtMinMarginLeft AS LONG
'~dup     rtMinMarginTop AS LONG
'~dup     rtMinMarginRight AS LONG
'~dup     rtMinMarginBottom AS LONG
'~dup     rtMarginLeft AS LONG
'~dup     rtMarginTop AS LONG
'~dup     rtMarginRight AS LONG
'~dup     rtMarginBottom AS LONG
'~dup     hInstance AS LONG
'~dup     lParam AS LONG
'~dup     lpfnPageSetupHook AS LONG
'~dup     lpfnPagePaintHook AS LONG
'~dup     lpPageSetupTemplate AS LONG
'~dup     hPageSetupTemplate AS LONG
'~dup END TYPE

'~dup DECLARE FUNCTION PageSetupDlg LIB "COMDLG32" ALIAS "PageSetupDlgA" _   ' повтор, первое: rapidq2.inc(7261)
'~dup                  (Ptr AS TPSD) AS LONG


'~dup DIM PSD AS TPSD   ' повтор, первое: printdlg.inc(50)

PSD.lStructSize = SIZEOF(PSD)
PSD.Flags = PSD_MINMARGINS + PSD_MARGINS
PSD.hWndOwner = 0

PRINT IIF(PageSetupDlg(PSD), "Start printing", "Cancel print")
?PSD.rtMarginLeft
?PSD.rtMarginTop
?PSD.rtMarginRight
?PSD.rtMarginBottom

$ENDIF ' __SEP_QPRINTDIALOG_INC
