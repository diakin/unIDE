'=======================================================
' Type Objet
' Classe QImageEx version 1.1
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
Declare Function LoadImageImg Lib "user32" Alias "LoadImageA" (hInst As Long,lpsz As String,dwImageType As Long,dwDesiredWidth As Long,dwDesiredHeight As Long,dwFlags As Long) As Long
Declare Function Load_JPGImg Lib "NViewLib.dll" Alias "Load_JPG" (FileName As String,Progress As Integer) As Long
Declare Function Load_GIFImg Lib "NViewLib.dll" Alias "Load_GIF" (FileName As String,Progress As Integer) As Long
Declare Function LoadImg Lib "NVIEWLIB" Alias "NViewLibLoad" (FileName As String,Progress As Integer) As Long
Declare Function SetLanguageImg Lib "NVIEWLIB" Alias "NViewLibSetLanguage" (Language As String) As Integer
Declare Function GetWidthImg Lib "NVIEWLIB" Alias "GetWidth" () As Integer
Declare Function GetHeightImg Lib "NVIEWLIB" Alias "GetHeight" () As Integer
Declare Function SaveAsJPGImg Lib "NViewLib.dll" Alias "NViewLibSaveAsJPG" (Quality As Integer,FileName As String) As Integer


Type QImageEx EXTENDS QIMAGE
  PRIVATE:
    bitmap as QBitmap

  PUBLIC:  
  '===================================================
  ' Mйthode copie image dans presse papier
  '===================================================
  Sub CopyToClipboard(rect as QRECT)
    dim hDC as integer
    dim hBitmap as integer
    dim hOldBitmap as integer
    dim width as integer
    dim height as integer

    width=rect.right-rect.left
    height=rect.bottom-rect.top
    hDC=CreateDCImg(This.handle)
    hBitmap=CreateBitmapImg(This.handle,width,height)
    hOldBitmap=SelectObjectImg(hDC,hBitmap)
    BitBltImg(hDC,0,0,width,height,This.handle,rect.left,rect.top,SRCCOPY_IMG)
    clipboard.open
    clipboard.clear
    clipboard.SetAsHandle(CF_BITMAP_IMG,hBitmap)
    clipboard.close
    SelectObjectImg(hDC,hOldBitmap)
    DeleteDCImg(hDC)
    DeleteObjectImg(hBitmap)
  End Sub
  
  '===================================================
  ' Mйthode colle image du presse papier
  '===================================================
  Sub PasteFromClipboard
    if clipboard.hasformat(CF_BITMAP_IMG) then
      clipboard.open
      This.handle=clipboard.GetAsHandle(CF_BITMAP_IMG)
      clipboard.close
    end if
  End Sub

  '===================================================
  ' Mйthode charge et affiche un fichier bitmap
  '===================================================
  Sub LoadFromFile(FileName as string,width as short,height as short,real as boolean)
    if real then
      This.bitmap.bmp=FileName
      This.handle=LoadImageImg(Application.hInstance,fileName,0,This.bitmap.width,This.bitmap.height,&H10)
    else
      This.handle=LoadImageImg(Application.hInstance,fileName,0,width,height,&H10)
    end if
  End Sub

  '===================================================
  ' Mйthode info image prйsente dans presse papier
  '===================================================
  Function CanPaste as boolean
    result=clipboard.hasformat(CF_BITMAP_IMG)
  End Function ' inc2026: было End Sub у Function CanPaste (строка 92); в rapidq2.inc у QImageEx - END FUNCTION

  '==================================================
  ' mйthode charge les formats dll
  '==================================================
  Sub LoadOtherImage(FileName as string,Progress as boolean,Language as string)
    if FileName<>"" and FileExists(FileName) then
      SetLanguageImg(language)
      this.handle=LoadImg(FileName,Progress)
      this.width=GetWidthImg
      this.height=GetHeightImg
    end if
  End Sub    
End Type
