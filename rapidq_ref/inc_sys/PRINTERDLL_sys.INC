' PRINTERDLL_sys.INC - отдельный inc, не входит в rapidqAllProc.inc /
' rapidqComponents.inc: своя DLL PrinterDLL.dll.
' Собран rapidq_ref/tools/build_inc.py из incOld/PRINTERDLL.INC; повторы объявлений
' общих файлов убраны (build_removed.txt). Подключать в программе,
' которой он нужен.
$IFNDEF __SEP_PRINTERDLL_INC
$DEFINE __SEP_PRINTERDLL_INC
$INCLUDE "rapidqComponents.inc"
'============================================================================
'[build_inc] PRINTERDLL.INC
'============================================================================
' printerdll CONST
CONST DONT_CREATE_PDC=0
CONST CREATE_THE_PDC=1
CONST DONT_DELETE_PDC=0
CONST DELETE_THE_PDC=1
CONST DIALOG_FILE_INVISIBLE=0
CONST DIALOG_FILE_VISIBLE=1
CONST DIALOG_PAGES_INVISIBLE=0
CONST DIALOG_PAGES_VISIBLE=1
CONST DIALOG_SELECTION_INVISIBLE=0
CONST DIALOG_SELECTION_VISIBLE=1
CONST DIALOG_NO_WARNINGS=0
CONST DIALOG_SHOW_WARNINGS=1
CONST DIALOG_PAGENUMBERS_OFF=0
CONST DIALOG_PAGENUMBERS_ON=1
CONST DIALOG_SELECTION_OFF=0
CONST DIALOG_SELECTION_ON=1
CONST DIALOG_USE_MILLIMETERS=0
CONST DIALOG_USE_INCHES=1
CONST DIALOG_DEFAULT_MARGINS=0
CONST DIALOG_VALUE_MARGINS=1
CONST DIALOG_DISABLE_MARGINS=2
CONST DIALOG_DEFAULT_MINMARGINS=0
CONST DIALOG_VALUE_MINMARGINS=1
CONST DIALOG_DISABLE_PAPER=0
CONST DIALOG_VALUE_PAPER=1
CONST DIALOG_PRINTER_DISABLED=0
CONST DIALOG_PRINTER_ENABLED=1
CONST DIALOG_ORIENTATION_DISABLED=0
CONST DIALOG_ORIENTATION_ENABLED=1
CONST SET_PI_ONLY=1
CONST SET_DM_ONLY=2
CONST SET_PI_AND_DM=0
CONST SET_LOCALLY=0
CONST SET_GLOBALLY=1

' Font Styles/Characteristics.
Const ITALIC_OFF = 0
Const ITALIC_ON = 1
Const UNDERLINE_OFF = 0
Const UNDERLINE_ON = 1
Const STRIKEOUT_OFF = 0
Const STRIKEOUT_ON = 1

' Bitmap Styles.

Declare Function Printer_OpenDefault Lib "printerdll.dll" Alias "Printer_OpenDefault" (internalBufSize As Long) As Long
Declare Function XPrinter_OpenDefault Lib "printerdll.dll" Alias "XPrinter_OpenDefault" (internalBufSize As Long, printerName As String, portName As String, driverName As String, dataType As String, pDevMode As Long, access As Long) As Long
Declare Function Printer_CreatePDC Lib "printerdll.dll" Alias "Printer_CreatePDC" () As Long
Declare Function XPrinter_CreatePDC Lib "printerdll.dll" Alias "XPrinter_CreatePDC" (driverName As String, printerName As String, output As String, pDevMode As Long) As Long
Declare Function Printer_GetHandle Lib "printerdll.dll" Alias "Printer_GetHandle" () As Long
Declare Function Printer_Pause Lib "printerdll.dll" Alias "Printer_Pause" () As Long
Declare Function Printer_Delete Lib "printerdll.dll" Alias "Printer_Delete" () As Long
Declare Function Printer_Purge Lib "printerdll.dll" Alias "Printer_Purge" () As Long
Declare Function Printer_GetDefault Lib "printerdll.dll" Alias "Printer_GetDefault" () As Long
Declare Function Printer_SetDefault Lib "printerdll.dll" Alias "Printer_SetDefault" (printerName As String) As Long
Declare Function Printer_AddConnection Lib "printerdll.dll" Alias "Printer_AddConnection" (printerName As String) As Long
Declare Function Printer_DeleteConnection Lib "printerdll.dll" Alias "Printer_DeleteConnection" (printerName As String) As Long
Declare Function Dialog_Connection Lib "PrinterDLL.dll" Alias "Dialog_Connection" (hWindow As Long) As Long
Declare Function Dialog_Port Lib "PrinterDLL.dll" Alias "Dialog_Port" (serverName AS STRING, hWindow AS LONG, portName AS String) As Long
Declare Function Dialog_AdvancedProperties Lib "PrinterDLL.dll" Alias "Dialog_AdvancedProperties" (hWindow AS LONG) As Long
Declare Function Dialog_Properties Lib "PrinterDLL.dll" Alias "Dialog_Properties" (hWindow AS LONG, hPrinter As Long) As Long
Declare Function Dialog_PageSetup Lib "PrinterDLL.dll" Alias "Dialog_PageSetup" (flag As Long,hWindow As Long, measurement As Long, mo As Long, l1 As Long, t1 As Long, r1 As Long, b1 As Long, mmo As Long, l2 As Long, t2 As Long, r2 As Long, b2 As Long, po As Long, x As Long, y As Long, pbo As Long, oo As Long, wo As Long) As Long
Declare Function Dialog_PrintSetup Lib "PrinterDLL.dll" Alias "Dialog_PrintSetup" (flag As Long,hWindow As Long, fp As Long, tp As Long, minp As Long, maxp As Long, fo As Long, po As Long, so As Long, wo As Long, pn As Long,ss As Long) As Long
Declare Function Dialog_Print Lib "PrinterDLL.dll" Alias "Dialog_Print" (flag As Long,hWindow As Long, fp As Long, tp As Long, minp As Long, maxp As Long, fo As Long, po As Long, so As Long, wo As Long, pn As Long,ss As Long) As Long
Declare Function Printer_AddPrinter Lib "printerdll.dll" Alias "Printer_AddPrinter" (serverName As String, printerName As String, portName As String, driverName As String, processorName As String) As Long
Declare Function Printer_DeletePrinter Lib "printerdll.dll" Alias "Printer_DeletePrinter" (hPrinter As Long) As Long
Declare Function Printer_AddDriver Lib "printerdll.dll" Alias "Printer_AddDriver" (serverName As String, Version As Long, printer As String, environment As String, driverPath As String, dataFile As String, configFile As String) As Long
Declare Function Printer_GetDriver Lib "printerdll.dll" Alias "Printer_GetDriver" (hPrinter As Long, enviroment As String) As Long
Declare Function Job_Pause Lib "printerdll.dll" Alias "Job_Pause" (jobID As Long) As Long
Declare Function Job_Resume Lib "printerdll.dll" Alias "Job_Resume" (jobID As Long) As Long
Declare Function Job_Delete Lib "printerdll.dll" Alias "Job_Delete" (jobID As Long) As Long
Declare Function Job_Restart Lib "printerdll.dll" Alias "Job_Restart" (jobID As Long) As Long
Declare Function Document_Open Lib "printerdll.dll" Alias "Document_Open" (docTitle As String, outputName As String, datatypeName As String) As Long
Declare Function Page_New Lib "printerdll.dll" Alias "Page_New" () As Long
Declare Function Page_String Lib "printerdll.dll" Alias "Page_String" (x As Long, y As Long, buffer As String, bufSize As Long) As Long
Declare Function Page_Clipboard Lib "printerdll.dll" Alias "Page_Clipboard" (x As Long, y As Long) As Long
Declare Function Page_Print Lib "printerdll.dll" Alias "Page_Print" () As Long
Declare Function Document_Abort Lib "printerdll.dll" Alias "Document_Abort" () As Long
Declare Function Document_Close Lib "printerdll.dll" Alias "Document_Close" () As Long
Declare Function RawDocument_Open Lib "printerdll.dll" Alias "RawDocument_Open" (docTitle As String, outputName As String, datatypeName As String) As Long
Declare Function RawPage_New Lib "printerdll.dll" Alias "RawPage_New" () As Long
Declare Function RawPage_Buffer Lib "printerdll.dll" Alias "RawPage_Buffer" (buffer As Long, bufSize As Long) As Long
Declare Function RawPage_Clipboard Lib "printerdll.dll" Alias "RawPage_Clipboard" () As Long
Declare Function RawPage_Print Lib "printerdll.dll" Alias "RawPage_Print" () As Long
Declare Function RawDocument_Close Lib "printerdll.dll" Alias "RawDocument_Close" () As Long
Declare Function Brush_CreateHatch Lib "printerdll.dll" Alias "Brush_CreateHatch" (colour As Long, style As Long) As Long
Declare Function Brush_CreateSolid Lib "printerdll.dll" Alias "Brush_CreateSolid" (colour As Long) As Long
Declare Function Brush_CreateHollow Lib "printerdll.dll" Alias "Brush_CreateHollow" () As Long
Declare Function Brush_DeleteHatch Lib "printerdll.dll" Alias "Brush_DeleteHatch" () As Long
Declare Function Brush_DeleteSolid Lib "printerdll.dll" Alias "Brush_DeleteSolid" () As Long
Declare Function Brush_DeleteHollow Lib "printerdll.dll" Alias "Brush_DeleteHollow" () As Long
Declare Function Font_Create Lib "printerdll.dll" Alias "Font_Create" (height As Long, width As Long, esc As Long, ori As Long, fw As Long, ita As Long, unl As Long, strike As Long, cs As Long, op As Long, cp As Long, quality As Long, pitch As Long, fontName As String) As Long
Declare Function Font_Delete Lib "printerdll.dll" Alias "Font_Delete" () As Long
Declare Function Pen_Create Lib "printerdll.dll" Alias "Pen_Create" (style As Long, thickness As Long, colour As Long) As Long
Declare Function Pen_CreateSolid Lib "printerdll.dll" Alias "Pen_CreateSolid" (thickness As Long, colour As Long) As Long
Declare Function Pen_Delete Lib "printerdll.dll" Alias "Pen_Delete" () As Long
Declare Function Pen_DeleteSolid Lib "printerdll.dll" Alias "Pen_DeleteSolid" () As Long
Declare Function Pen_UseDefined Lib "printerdll.dll" Alias "Pen_UseDefined" (style As Long) As Long
Declare Function Font_UseDefined Lib "printerdll.dll" Alias "Font_UseDefined" (style As Long) As Long
Declare Function Brush_UseDefined Lib "printerdll.dll" Alias "Brush_UseDefined" (style As Long) As Long
Declare Function Pen_DeleteDefined Lib "printerdll.dll" Alias "Pen_DeleteDefined" () As Long
Declare Function Font_DeleteDefined Lib "printerdll.dll" Alias "Font_DeleteDefined" () As Long
Declare Function Brush_DeleteDefined Lib "printerdll.dll" Alias "Brush_DeleteDefined" () As Long
Declare Function Brush_CreateBMPattern Lib "printerdll.dll" Alias "Brush_CreateBMPattern" (bmWidth As Long, bmHeight As Long, bmPlanes As Long, bmBitPerPlane As Long, bmArray As Long) As Long
Declare Function Brush_DeleteBMPattern Lib "printerdll.dll" Alias "Brush_DeleteBMPattern" () As Long
Declare Function Draw_Ellipse Lib "printerdll.dll" Alias "Draw_Ellipse" (left As Long, top As Long, right As Long, bottom As Long) As Long
Declare Function Draw_Rectangle Lib "printerdll.dll" Alias "Draw_Rectangle" (left As Long, top As Long, right As Long, bottom As Long) As Long
Declare Function Draw_RoundRectangle Lib "printerdll.dll" Alias "Draw_RoundRectangle" (left As Long, top As Long, right As Long, bottom As Long, width As Long, height As Long) As Long
Declare Function Draw_LineTo Lib "printerdll.dll" Alias "Draw_LineTo" (x As Long, y As Long) As Long
Declare Function Draw_MoveCursorTo Lib "printerdll.dll" Alias "Draw_MoveCursorTo" (x As Long, y As Long) As Long
Declare Function Draw_PolyLine Lib "printerdll.dll" Alias "Draw_PolyLine" (pointsArray As Long, numPoints As Long) As Long
Declare Function Draw_PolyLineTo Lib "printerdll.dll" Alias "Draw_PolyLineTo" (pointsArray As Long, numPoints As Long) As Long
Declare Function Draw_FilledRectangle Lib "printerdll.dll" Alias "Draw_FilledRectangle" (left As Long, top As Long, right As Long, bottom As Long) As Long
Declare Function Draw_Arc Lib "printerdll.dll" Alias "Draw_Arc" (left As Long, top As Long, right As Long, bottom As Long, xpoint As long, ypoint As Long, xarc As Long, yarc As Long) As Long
Declare Function Draw_ArcTo Lib "printerdll.dll" Alias "Draw_ArcTo" (left As Long, top As Long, right As Long, bottom As Long, xrad1 As long, yrad1 As Long, xrad2 As Long, yrad2 As Long) As Long
Declare Function Draw_AngleArc Lib "printerdll.dll" Alias "Draw_AngleArc" (x As Long, y As Long, radius As Long, start As Long, sweep As Long) As Long
Declare Function Draw_PolyBezier Lib "printerdll.dll" Alias "Draw_PolyBezier" (pointsArray As Long, numPoints As Long) As Long
Declare Function Draw_PolyBezierTo Lib "printerdll.dll" Alias "Draw_PolyBezierTo" (pointsArray As Long, numPoints As Long) As Long
Declare Function Draw_Border Lib "printerdll.dll" Alias "Draw_Border" (left As Long, top As Long, right As Long, bottom As Long, edgeStyle As Long, borderStyle As Long) As Long
Declare Function Draw_Chord Lib "printerdll.dll" Alias "Draw_Chord" (left As Long, top As Long, right As Long, bottom As Long, xrad1 As long, yrad1 As Long, xrad2 As Long, yrad2 As Long) As Long
Declare Function Draw_FramedRectangle Lib "printerdll.dll" Alias "Draw_FramedRectangle" (left As Long, top As Long, right As Long, bottom As Long, hBrush As long) As Long
Declare Function Draw_Pie Lib "printerdll.dll" Alias "Draw_Pie" (left As Long, top As Long, right As Long, bottom As Long, xrad1 As long, yrad1 As Long, xrad2 As Long, yrad2 As Long) As Long
Declare Function Draw_Bitmap Lib "printerdll.dll" Alias "Draw_Bitmap" (sourceDC As Long, xSourceBM As Long, ySourceBM As Long, xDestBM As Long, yDestBM As Long, wDestBM As Long, hDestBM As Long, blitMethod As Long) As Long
Declare Function Draw_ResizedBitmap Lib "printerdll.dll" Alias "Draw_ResizedBitmap" (sourceDC As Long, xSourceBM As Long, ySourceBM As Long, wSourceBM As Long, hSourceBM As Long, xDestBM As Long, yDestBM As Long, wDestBM As Long, hDestBM As Long, blitMethod As Long) As Long
Declare Function Draw_PatternedBitmap Lib "printerdll.dll" Alias "Draw_PatternedBitmap" (xBM As Long, yBM As Long, wBM As Long, hBM As Long, blitMethod As Long) As Long
Declare Function BGColor_GetCurrentColor Lib "printerdll.dll" Alias "BGColor_GetCurrentColor" () As Long
Declare Function BGColor_SetCurrentColor Lib "printerdll.dll" Alias "BGColor_SetCurrentColor" (colour As Long) As Long
Declare Function BGMode_GetCurrentMode Lib "printerdll.dll" Alias "BGMode_GetCurrentMode" () As Long
Declare Function BGMode_SetTransparentMode Lib "printerdll.dll" Alias "BGMode_SetTransparentMode" () As Long
Declare Function BGMode_SetOpaqueMode Lib "printerdll.dll" Alias "BGMode_SetOpaqueMode" () As Long
Declare Function BGMode_SetMode Lib "printerdll.dll" Alias "BGMode_SetMode" (mode As Long) As Long
Declare Function MapMode_SetCurrentMode Lib "printerdll.dll" Alias "MapMode_SetCurrentMode" (mode As Long) As Long
Declare Function MapMode_GetCurrentMode Lib "printerdll.dll" Alias "MapMode_GetCurrentMode" () As Long
Declare Function MapperFlags_SetGetFlags Lib "printerdll.dll" Alias "MapperFlags_SetGetFlags" (flags As Long) As Long
Declare Function GraphicsMode_SetGetMode Lib "printerdll.dll" Alias "GraphicsMode_SetGetMode" (mode As Long) As Long
Declare Function ArcDirection_SetAntiClockwise Lib "printerdll.dll" Alias "ArcDirection_SetAntiClockwise" () As Long
Declare Function ArcDirection_SetClockwise Lib "printerdll.dll" Alias "ArcDirection_SetClockwise" () As Long
Declare Function ArcDirection_GetDirection Lib "printerdll.dll" Alias "ArcDirection_GetDirection" () As Long
Declare Function PrintFormat_SetPortrait Lib "printerdll.dll" Alias "PrintFormat_SetPortrait" (flag As Long) As Long
Declare Function PrintFormat_SetLandscape Lib "printerdll.dll" Alias "PrintFormat_SetLandscape" (flag As Long) As Long
Declare Function PrintQuality_SetLow Lib "printerdll.dll" Alias "PrintQuality_SetLow" (flag As Long) As Long
Declare Function PrintQuality_SetMedium Lib "printerdll.dll" Alias "PrintQuality_SetMedium" (flag As Long) As Long
Declare Function PrintQuality_SetHigh Lib "printerdll.dll" Alias "PrintQuality_SetHigh" (flag As Long) As Long
Declare Function PrintQuality_SetDraft Lib "printerdll.dll" Alias "PrintQuality_SetDraft" (flag As Long) As Long
Declare Function PrintColor_SetColor Lib "printerdll.dll" Alias "PrintColor_SetColor" (flag As Long) As Long
Declare Function PrintColor_SetBW Lib "printerdll.dll" Alias "PrintColor_SetBW" (flag As Long) As Long
Declare Function PrintDuplex_SetHorizontal Lib "printerdll.dll" Alias "PrintDuplex_SetHorizontal" (flag As Long) As Long
Declare Function PrintDuplex_SetVertical Lib "printerdll.dll" Alias "PrintDuplex_SetVertical" (flag As Long) As Long
Declare Function PrintDuplex_SetSimple Lib "printerdll.dll" Alias "PrintDuplex_SetSimple" (flag As Long) As Long
Declare Function PrintTTFont_SetBitmap Lib "printerdll.dll" Alias "PrintTTFont_SetBitmap" (flag As Long) As Long
Declare Function PrintTTFont_SetDownload Lib "printerdll.dll" Alias "PrintTTFont_SetDownload" (flag As Long) As Long
Declare Function PrintTTFont_SetSubstitute Lib "printerdll.dll" Alias "PrintTTFont_SetSubstitute" (flag As Long) As Long
Declare Function PrintScale_SetHalfSize Lib "printerdll.dll" Alias "PrintScale_SetHalfSize" (flag As Long) As Long
Declare Function PrintScale_SetSize Lib "printerdll.dll" Alias "PrintScale_SetSize" (flag As Long,sSize As Word) As Long
Declare Function PrintCopies_SetSize Lib "printerdll.dll" Alias "PrintCopies_SetSize" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetWidth Lib "printerdll.dll" Alias "PrintPaper_SetWidth" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetLength Lib "printerdll.dll" Alias "PrintPaper_SetLength" (flag As Long,sSize As Word) As Long
Declare Function PrintDPI_SetYResolution Lib "printerdll.dll" Alias "PrintDPI_SetYResolution" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetLetter Lib "printerdll.dll" Alias "PrintPaper_SetLetter" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetLegal Lib "printerdll.dll" Alias "PrintPaper_SetLegal" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetA4 Lib "printerdll.dll" Alias "PrintPaper_SetA4" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetCSheet Lib "printerdll.dll" Alias "PrintPaper_SetCSheet" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetDSheet Lib "printerdll.dll" Alias "PrintPaper_SetDSheet" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetESheet Lib "printerdll.dll" Alias "PrintPaper_SetESheet" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetLetterSmall Lib "printerdll.dll" Alias "PrintPaper_SetLetterSmall" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetTabloid Lib "printerdll.dll" Alias "PrintPaper_SetTabloid" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetLedger Lib "printerdll.dll" Alias "PrintPaper_SetLedger" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetStatement Lib "printerdll.dll" Alias "PrintPaper_SetStatement" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetExecutive Lib "printerdll.dll" Alias "PrintPaper_SetExecutive" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetA3 Lib "printerdll.dll" Alias "PrintPaper_SetA3" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetA4Small Lib "printerdll.dll" Alias "PrintPaper_SetA4Small" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetA5 Lib "printerdll.dll" Alias "PrintPaper_SetA5" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetB4 Lib "printerdll.dll" Alias "PrintPaper_SetB4" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetB5 Lib "printerdll.dll" Alias "PrintPaper_SetB5" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetFolio Lib "printerdll.dll" Alias "PrintPaper_SetFolio" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetQuarto Lib "printerdll.dll" Alias "PrintPaper_SetQuarto" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_Set10x14 Lib "printerdll.dll" Alias "PrintPaper_Set10x14" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_Set11x17 Lib "printerdll.dll" Alias "PrintPaper_Set11x17" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetNote Lib "printerdll.dll" Alias "PrintPaper_SetNote" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetEnv9 Lib "printerdll.dll" Alias "PrintPaper_SetEnv9" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetEnv10 Lib "printerdll.dll" Alias "PrintPaper_SetEnv10" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetEnv11 Lib "printerdll.dll" Alias "PrintPaper_SetEnv11" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetEnv12 Lib "printerdll.dll" Alias "PrintPaper_SetEnv12" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetEnv14 Lib "printerdll.dll" Alias "PrintPaper_SetEnv14" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetEnvDL Lib "printerdll.dll" Alias "PrintPaper_SetEnvDL" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetEnvC5 Lib "printerdll.dll" Alias "PrintPaper_SetEnvC5" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetEnvC3 Lib "printerdll.dll" Alias "PrintPaper_SetEnvC3" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetEnvC4 Lib "printerdll.dll" Alias "PrintPaper_SetEnvC4" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetEnvC6 Lib "printerdll.dll" Alias "PrintPaper_SetEnvC6" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetEnvC65 Lib "printerdll.dll" Alias "PrintPaper_SetEnvC65" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetEnvB4 Lib "printerdll.dll" Alias "PrintPaper_SetEnvB4" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetEnvB5 Lib "printerdll.dll" Alias "PrintPaper_SetEnvB5" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetEnvB6 Lib "printerdll.dll" Alias "PrintPaper_SetEnvB6" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetItaly Lib "printerdll.dll" Alias "PrintPaper_SetItaly" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetMonarch Lib "printerdll.dll" Alias "PrintPaper_SetMonarch" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetPersonal Lib "printerdll.dll" Alias "PrintPaper_SetPersonal" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetFFUS Lib "printerdll.dll" Alias "PrintPaper_SetFFUS" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetSFFGerman Lib "printerdll.dll" Alias "PrintPaper_SetSFFGerman" (flag As Long,sSize As Word) As Long
Declare Function PrintPaper_SetLFFGerman Lib "printerdll.dll" Alias "PrintPaper_SetLFFGerman" (flag As Long,sSize As Word) As Long
Declare Function PrintCollate_SetTrue Lib "printerdll.dll" Alias "PrintCollate_SetTrue" (flag As Long) As Long
Declare Function PrintCollate_SetFalse Lib "printerdll.dll" Alias "PrintCollate_SetFalse" (flag As Long) As Long
Declare Function PrintDither_SetNone Lib "printerdll.dll" Alias "PrintDither_SetNone" (flag As Long) As Long
Declare Function PrintDither_SetCoarse Lib "printerdll.dll" Alias "PrintDither_SetCoarse" (flag As Long) As Long
Declare Function PrintDither_SetFine Lib "printerdll.dll" Alias "PrintDither_SetFine" (flag As Long) As Long
Declare Function PrintDither_SetLineArt Lib "printerdll.dll" Alias "PrintDither_SetLineArt" (flag As Long) As Long
Declare Function PrintDither_SetGrayScale Lib "printerdll.dll" Alias "PrintDither_SetGrayScale" (flag As Long) As Long
Declare Function PrintDevice_SetName Lib "printerdll.dll" Alias "PrintDevice_SetName" (flag As Long, name As String) As Long
Declare Function PrintAttr_SetDefault Lib "printerdll.dll" Alias "PrintAttr_SetDefault" (flag As Long) As Long
Declare Function PrintAttr_SetDirect Lib "printerdll.dll" Alias "PrintAttr_SetDirect" (flag As Long) As Long
Declare Function PrintAttr_SetCompleteTest Lib "printerdll.dll" Alias "PrintAttr_SetCompleteTest" (flag As Long) As Long
Declare Function PrintAttr_SetEnableBidi Lib "printerdll.dll" Alias "PrintAttr_SetEnableBidi" (flag As Long) As Long
Declare Function PrintAttr_SetEnableDevQ Lib "printerdll.dll" Alias "PrintAttr_SetEnableDevQ" (flag As Long) As Long
Declare Function PrintAttr_SetKeepPrintedJobs Lib "printerdll.dll" Alias "PrintAttr_SetKeepPrintedJobs" (flag As Long) As Long
Declare Function PrintAttr_SetQueued Lib "printerdll.dll" Alias "PrintAttr_SetQueued" (flag As Long) As Long
Declare Function PrintAttr_SetShared Lib "printerdll.dll" Alias "PrintAttr_SetShared" (flag As Long) As Long
Declare Function PrintAttr_SetWorkOffline Lib "printerdll.dll" Alias "PrintAttr_SetWorkOffline" (flag As Long) As Long
Declare Function PrintAttr_SetValue Lib "printerdll.dll" Alias "PrintAttr_SetValue" (flag As Long,value As Long) As Long
Declare Function PrintPriority_SetValue Lib "printerdll.dll" Alias "PrintPriority_SetValue" (flag As Long,value As Long) As Long
Declare Function PrintDefaultPriority_SetValue Lib "printerdll.dll" Alias "PrintDefaultPriority_SetValue" (flag As Long,value As Long) As Long
Declare Function PrintStartTime_SetValue Lib "printerdll.dll" Alias "PrintStartTime_SetValue" (flag As Long,value As Long) As Long
Declare Function PrintUntilTime_SetValue Lib "printerdll.dll" Alias "PrintUntilTime_SetValue" (flag As Long,value As Long) As Long
Declare Function PrintPrinter_SetName Lib "printerdll.dll" Alias "PrintPrinter_SetName" (flag As Long,name As String) As Long
Declare Function PrintShare_SetName Lib "printerdll.dll" Alias "PrintShare_SetName" (flag As Long,name As String) As Long
Declare Function PrintPort_SetName Lib "printerdll.dll" Alias "PrintPort_SetName" (flag As Long,name As String) As Long
Declare Function PrintDriver_SetName Lib "printerdll.dll" Alias "PrintDriver_SetName" (flag As Long,name As String) As Long
Declare Function PrintComment_SetName Lib "printerdll.dll" Alias "PrintComment_SetName" (flag As Long,name As String) As Long
Declare Function PrintLocation_SetName Lib "printerdll.dll" Alias "PrintLocation_SetName" (flag As Long,name As String) As Long
Declare Function PrintSepFile_SetName Lib "printerdll.dll" Alias "PrintSepFile_SetName" (flag As Long,name As String) As Long
Declare Function PrintProcessor_SetName Lib "printerdll.dll" Alias "PrintProcessor_SetName" (flag As Long,name As String) As Long
Declare Function PrintDatatype_SetName Lib "printerdll.dll" Alias "PrintDatatype_SetName" (flag As Long,name As String) As Long
Declare Function PrintParameters_SetName Lib "printerdll.dll" Alias "PrintParameters_SetName" (flag As Long,name As String) As Long
Declare Function PrintFormat_GetValue Lib "printerdll.dll" Alias "PrintFormat_GetValue" () As Word
Declare Function PrintQuality_GetValue Lib "printerdll.dll" Alias "PrintQuality_GetValue" () As Word
Declare Function PrintColor_GetValue Lib "printerdll.dll" Alias "PrintColor_GetValue" () As Word
Declare Function PrintDuplex_GetValue Lib "printerdll.dll" Alias "PrintDuplex_GetValue" () As Word
Declare Function PrintTTFont_GetValue Lib "printerdll.dll" Alias "PrintTTFont_GetValue" () As Word
Declare Function PrintScale_GetValue Lib "printerdll.dll" Alias "PrintScale_GetValue" () As Word
Declare Function PrintCopies_GetValue Lib "printerdll.dll" Alias "PrintCopies_GetValue" () As Word
Declare Function PrintPaperWidth_GetValue Lib "printerdll.dll" Alias "PrintPaperWidth_GetValue" () As Word
Declare Function PrintPaperLength_GetValue Lib "printerdll.dll" Alias "PrintPaperLength_GetValue" () As Word
Declare Function PrintPaperSize_GetValue Lib "printerdll.dll" Alias "PrintPaperSize_GetValue" () As Word
Declare Function PrintYDPI_GetValue Lib "printerdll.dll" Alias "PrintYDPI_GetValue" () As Word
Declare Function PrintCollate_GetValue Lib "printerdll.dll" Alias "PrintCollate_GetValue" () As Word
Declare Function PrintDither_GetValue Lib "printerdll.dll" Alias "PrintDither_GetValue" () As Long
Declare Function PrintAttr_GetValue Lib "printerdll.dll" Alias "PrintAttr_GetValue" () As Long
Declare Function PrintPriority_GetValue Lib "printerdll.dll" Alias "PrintPriority_GetValue" () As Long
Declare Function PrintDefaultPriority_GetValue Lib "printerdll.dll" Alias "PrintDefaultPriority_GetValue" () As Long
Declare Function PrintStartTime_GetValue Lib "printerdll.dll" Alias "PrintStartTime_GetValue" () As Long
Declare Function PrintUntilTime_GetValue Lib "printerdll.dll" Alias "PrintUntilTime_GetValue" () As Long
Declare Function PrintStatus_GetValue Lib "printerdll.dll" Alias "PrintStatus_GetValue" () As Long
Declare Function PrintJobCount_GetValue Lib "printerdll.dll" Alias "PrintJobCount_GetValue" () As Long
Declare Function PrintAveragePPM_GetValue Lib "printerdll.dll" Alias "PrintAveragePPM_GetValue" () As Long
Declare Function PrintForm_GetName Lib "printerdll.dll" Alias "PrintForm_GetName" () As Long
Declare Function PrintDevice_GetName Lib "printerdll.dll" Alias "PrintDevice_GetName" () As Long
Declare Function PrintPrinter_GetName Lib "printerdll.dll" Alias "PrintPrinter_GetName" () As Long
Declare Function PrintShare_GetName Lib "printerdll.dll" Alias "PrintShare_GetName" () As Long
Declare Function PrintPort_GetName Lib "printerdll.dll" Alias "PrintPort_GetName" () As Long
Declare Function PrintDriver_GetName Lib "printerdll.dll" Alias "PrintDriver_GetName" () As Long
Declare Function PrintComment_GetName Lib "printerdll.dll" Alias "PrintComment_GetName" () As Long
Declare Function PrintLocation_GetName Lib "printerdll.dll" Alias "PrintLocation_GetName" () As Long
Declare Function PrintSepFile_GetName Lib "printerdll.dll" Alias "PrintSepFile_GetName" () As Long
Declare Function PrintProcessor_GetName Lib "printerdll.dll" Alias "PrintProcessor_GetName" () As Long
Declare Function PrintDatatype_GetName Lib "printerdll.dll" Alias "PrintDatatype_GetName" () As Long
Declare Function PrintParameters_GetName Lib "printerdll.dll" Alias "PrintParameters_GetName" () As Long
Declare Function PI2_GetAllInfo Lib "printerdll.dll" Alias "PI2_GetAllInfo" () As Long
Declare Function DM_GetAllInfo Lib "printerdll.dll" Alias "DM_GetAllInfo" () As Long
Declare Function Enum_RegLocalPrinters Lib "PrinterDLL.dll" Alias "Enum_RegLocalPrinters" () As Long
Declare Function Enum_LocalPrinters Lib "PrinterDLL.dll" Alias "Enum_LocalPrinters" () As Long
Declare Function Enum_Ports Lib "PrinterDLL.dll" Alias "Enum_Ports" (serverName As String) As Long
Declare Function XPrinter_DeletePDC Lib "printerdll.dll" Alias "XPrinter_DeletePDC" (hPDC As Long) As Long
Declare Function Printer_Close Lib "printerdll.dll" Alias "Printer_Close" (hPrinter As Long) As Long
Declare Function Printer_CloseDefault Lib "printerdll.dll" Alias "Printer_CloseDefault" () As Long
Declare Function Get_WinVer Lib "printerdll.dll" Alias "Get_WinVer" () As Long
Declare Function Dialog_ControlPanel Lib "printerdll.dll" Alias "Dialog_ControlPanel" (cplName As String) As Long

$ENDIF ' __SEP_PRINTERDLL_INC
