$IFNDEF __QDESKTOP_INC   ' IncManager: include guard
$DEFINE __QDESKTOP_INC
'=======================================================
' Type Objet
' Classe QDesktop version 1.0
'=======================================================
Declare Function SetActiveDesktop Lib "USER32" Alias "SetActiveWindow" (hWnd as integer) as integer
Declare Function GetDCDesktop LIB "user32" Alias "GetDC" (hWnd as integer) as integer
Declare Function ReleaseDCDesktop Lib "user32" Alias "ReleaseDC" (hWnd as integer,hDC as integer) as integer
Declare Function BitBltDesktop Lib "gdi32" Alias "BitBlt" (hDC as integer,nXDest as integer,nYDest as integer,nWidth as integer,nHeight as integer,hdcSrc as integer,nXSrc as integer,nYSrc as integer,dwRop as integer) as integer
Declare Function PaintDesktop Lib "user32" Alias "PaintDesktop" (HDC as integer) as integer
Declare Function GetPixelDesktop Lib "gdi32" Alias "GetPixel" (hdc as Long,x as Long,y as Long) as Long
Declare Function SystemParametersInfo Lib "user32" Alias "SystemParametersInfoA" (uAction as Long,uParam as Long,lpvParam as Long,fuWinIni as Long) as Long

' SystemParametersInfo flags
Const SPIF_UPDATEINIFILE=&H1
Const SPIF_SENDWININICHANGE=&H2
Const SPI_SETDESKWALLPAPER=20

Type QDesktop Extends QObject  
  '===============================================
  ' Method copy desktop
  '===============================================
  Sub Copy(handle as long,x as integer,y as integer,width as integer,height as integer)
    dim DC as integer
    dim nWidth as integer
    dim nHeight as integer

    'SetActiveDesktop(0)
    DC=GetDCDesktop(0)
    if width>Screen.Width then
      nWidth=Screen.Width
    else
      nWidth=width
    end if
    if height>Screen.Height then
      nHeight=Screen.Height
    else
      nHeight=height
    end if
    BitBltDesktop(handle,x,y,nWidth,nHeight,DC,0,0,&HCC0020)
    ReleaseDCDesktop(0,DC)
  End Sub
  
  '===============================================
  ' Method copy wallpaper
  '===============================================
  Sub CopyWallPaper(handle as long)
    PaintDesktop(handle)
  End Sub
  
  '===============================================
  ' Method return color pixel
  '===============================================
  Function GetPixel(x as integer,y as integer) as Long
    dim DC as integer
    dim color as long
    
    DC=GetDCDesktop(0)
    color=GetPixelDesktop(DC,x,y)
    ReleaseDCDesktop(0,DC)
    result=color
  End Function
  
  '===============================================
  ' Method change wallpaper
  '===============================================
  Sub ChangeWallPaper(FileName as string)
    dim File as string
    dim Flag as long
    
    if FileName<>"" then
      File=FileName
      Flag=SPIF_UPDATEINIFILE+SPIF_SENDWININICHANGE
      SystemParametersInfo(SPI_SETDESKWALLPAPER,0,Varptr(File),Flag)
    end if
  End Sub
End Type
$ENDIF   ' IncManager: __QDESKTOP_INC
