'=======================================================
' Type Objet
' Classe QImageEx
'=======================================================
$IFNDEF TRUE
  $DEFINE True 1
$ENDIF

$IFNDEF FALSE
  $DEFINE False 0
$ENDIF

$IFNDEF boolean
  $DEFINE boolean integer
$ENDIF

Const SRCCOPY_IMG=&HCC0020 
Const CF_BITMAP_IMG=2

Declare Function DeleteObjectImg Lib "gdi32" Alias "DeleteObject" (hObject As Long) As Long
Declare Function CreateDCImg Lib "gdi32" Alias "CreateCompatibleDC" (hdc As Long) As Long
Declare Function SelectObjectImg Lib "gdi32" Alias "SelectObject" (hdc As Long,hObject As Long) As Long
Declare Function BitBltImg Lib "gdi32" Alias "BitBlt" (hDestDC As Long,x As Long,y As Long,nWidth As Long,nHeight As Long,hSrcDC As Long,xSrc As Long,ySrc As Long,dwRop As Long) As Long
Declare Function DeleteDCImg Lib "gdi32" Alias "DeleteDC" (hdc As Long) As Long
Declare Function CreateBitmapImg Lib "gdi32" Alias "CreateCompatibleBitmap" (hdc As Long,nWidth As Long,nHeight As Long) As Long
DECLARE FUNCTION LoadImageImg Lib "user32" ALIAS "LoadImageA" (hInst AS LONG,lpsz AS STRING, dwImageType AS LONG,dwDesiredWidth AS LONG, dwDesiredHeight AS LONG,dwFlags AS LONG) AS LONG


Type QImageEx EXTENDS QIMAGE
  PRIVATE:
    bitmap as QBitmap

  PUBLIC:  
  '===================================================
  ' Méthode copie image dans presse papier
  '===================================================
  Sub CopyToClipboard(rect as QRECT)
    dim hDC as integer
    dim hBitmap as integer
    dim hOldBitmap as integer
    dim width as integer
    dim height as integer

    width=rect.right-rect.left
    height=rect.bottom-rect.top
    hDC=CreateDCImg(QImageEx.handle)
    hBitmap=CreateBitmapImg(QImageEx.handle,width,height)
    hOldBitmap=SelectObjectImg(hDC,hBitmap)
    BitBltImg(hDC,0,0,width,height,QImageEx.handle,rect.left,rect.top,SRCCOPY_IMG)
    clipboard.open
    clipboard.clear
    clipboard.SetAsHandle(CF_BITMAP_IMG,hBitmap)
    clipboard.close
    SelectObjectImg(hDC,hOldBitmap)
    DeleteDCImg(hDC)
    DeleteObjectImg(hBitmap)
  End Sub
  
  '===================================================
  ' Méthode colle image du presse papier
  '===================================================
  Sub PasteFromClipboard
    if clipboard.hasformat(CF_BITMAP_IMG) then
      clipboard.open
      QImageEx.handle=clipboard.GetAsHandle(CF_BITMAP_IMG)
      clipboard.close
    end if
  End Sub

  '===================================================
  ' Méthode charge et affiche un fichier bitmap
  '===================================================
  Sub LoadFromFile(FileName as string,width as short,height as short,real as boolean)
    if real then
      QImageEx.bitmap.bmp=FileName
      QImageEx.handle=LoadImageImg(Application.hInstance,fileName,0,QImageEx.bitmap.width,QImageEx.bitmap.height,&H10)
    else
      QImageEx.handle=LoadImageImg(Application.hInstance,fileName,0,width,height,&H10)
    end if
  End Sub

  '===================================================
  ' Méthode info image présente dans presse papier
  '===================================================
  Function CanPaste as boolean
    result=clipboard.hasformat(CF_BITMAP_IMG)
  End Sub
    
End Type
      