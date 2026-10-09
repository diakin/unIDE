'=======================================================
' Type Objet
' Classe QPrinterInfo version 1.0
'=======================================================
const PI_HORZSIZE=4           '  Horizontal size in millimeters
const PI_VERTSIZE=6           '  Vertical size in millimeters
const PI_HORZRES=8            '  Horizontal width in pixels
const PI_VERTRES=10           '  Vertical width in pixels
const PI_LOGPIXELSX=88        '  Logical pixels/inch in X
const PI_LOGPIXELSY=90        '  Logical pixels/inch in Y
const PI_PHYSICALWIDTH=110 '  Physical Width in device units
const PI_PHYSICALHEIGHT=111 '  Physical Height in device units
const PI_PHYSICALOFFSETX=112 '  Physical Printable Area x margin
const PI_PHYSICALOFFSETY=113 '  Physical Printable Area y margin
      
DECLARE FUNCTION PiGetDeviceCaps LIB "gdi32" ALIAS "GetDeviceCaps" (hdc AS LONG,nIndex AS LONG) AS LONG
DECLARE FUNCTION PiGetDC LIB "user32" ALIAS "GetDC" (ByVal hwnd AS LONG) AS LONG
DECLARE FUNCTION PiReleaseDC LIB "user32" ALIAS "ReleaseDC" (ByVal hwnd AS LONG, ByVal hdc AS LONG) AS LONG
Declare Function PiGetDesktopWindow Lib "user32.dll" Alias "GetDesktopWindow" () As Long

Type QPrinterInfo Extends QObject

  '============================
  ' return scale printer
  '============================
  Function Scale() as double
    dim dc as long
  
    dc=PiGetDC(PiGetDesktopWindow())
    result=PiGetDeviceCaps(printer.handle,PI_LOGPIXELSX)/PiGetDeviceCaps(dc,PI_LOGPIXELSX)
    PiReleaseDC(PiGetDesktopWindow(),dc)
  End Function

  '=====================================
  'return dpi printer(points per inch)
  '=====================================
  Function Dpi() as integer  
    result=PiGetDeviceCaps(printer.handle,PI_LOGPIXELSX)
  End Function

  '=========================================
  'return ppm printer(pixel per millimeter)
  '=========================================
  Function Ppm() as double
    result=PiGetDeviceCaps(printer.handle,PI_HORZRES)/PiGetDeviceCaps(printer.handle,PI_HORZSIZE)
  End Function

  '=========================================
  'return convert millimeter to pixel
  '=========================================
  Function MetricToPixel(mm as double) as integer  
    result=Round(QPrinterInfo.Ppm()*mm)
  End Function

  '=========================================
  'return convert pixel to millimeter
  '=========================================
  Function PixelToMetric(pixel as integer) as double    
    result=pixel/QPrinterInfo.Ppm()
  End Function

  '=========================================
  'return horz page size in millimeter
  '=========================================
  Function HorzPageSize() as integer
    result=PiGetDeviceCaps(printer.handle,PI_HORZSIZE)
  End Function

  '=========================================
  'return vert page size in millimeter
  '=========================================
  Function VertPageSize() as integer
    result=PiGetDeviceCaps(printer.handle,PI_VERTSIZE)
  End Function

  '=========================================
  'return page width in pixel
  '=========================================
  Function PageWidth() as integer
    result=PiGetDeviceCaps(printer.handle,PI_HORZRES)
  End Function

  '=========================================
  'return page height in pixel
  '=========================================
  Function PageHeight() as integer
    result=PiGetDeviceCaps(printer.handle,PI_VERTRES)
  End Function

  '=========================================
  'return physical page width in pixel
  '=========================================
  Function PhWidth() as integer
    result=PiGetDeviceCaps(printer.handle,PI_PHYSICALWIDTH)
  End Function

  '=========================================
  'return physical page height in pixel
  '=========================================
  Function PhHeight() as integer
    result=PiGetDeviceCaps(printer.handle,PI_PHYSICALHEIGHT)
  End Function

  '=========================================
  'return physical page horz in millimeter
  '=========================================
  Function PhHorz() as integer
    dim pixel as integer
    
    pixel=PiGetDeviceCaps(printer.handle,PI_PHYSICALWIDTH)
    result=Round(pixel/QPrinterInfo.Ppm())
  End Function

  '=========================================
  'return physical page vert in millimeter
  '=========================================
  Function PhVert() as integer
    dim pixel as integer
    
    pixel=PiGetDeviceCaps(printer.handle,PI_PHYSICALHEIGHT)
    result=Round(pixel/QPrinterInfo.Ppm())
  End Function

  '=========================================
  'return physical margin x in millimeter
  '=========================================
  Function PhMarginX() as double
    dim pixel as integer
    
    pixel=PiGetDeviceCaps(printer.handle,PI_PHYSICALOFFSETX)
    result=pixel/QPrinterInfo.Ppm()
  End Function

  '=========================================
  'return physical margin y in millimeter
  '=========================================
  Function PhMarginY() as double
    dim pixel as integer
    
    pixel=PiGetDeviceCaps(printer.handle,PI_PHYSICALOFFSETY)
    result=pixel/QPrinterInfo.Ppm()
  End Function

  '=========================================
  'return physical margin x in pixel
  '=========================================
  Function PhLeftMargin() as integer
    result=PiGetDeviceCaps(printer.handle,PI_PHYSICALOFFSETX)
  End Function

  '=========================================
  'return physical margin y in pixel
  '=========================================
  Function PhTopMargin() as integer
    result=PiGetDeviceCaps(printer.handle,PI_PHYSICALOFFSETY)
  End Function
End Type
      