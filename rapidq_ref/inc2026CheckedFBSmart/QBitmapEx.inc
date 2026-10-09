'=======================================================
' Type Objet
' Classe QBitmapEx Version 1.4
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

Type TBITMAP_BMP
  bmType As Long
  bmWidth As Long
  bmHeight As Long
  bmWidthBytes As Long
  bmPlanes As Integer
  bmBitsPixel As Integer
  bmBits As Long
End Type

'pen styles
Const PS_SOLID_BMP=0
Const PS_DASH_BMP=1
Const PS_DOT_BMP=2
Const PS_DASHDOT_BMP=3
Const PS_DASHDOTDOT_BMP=4
Const PS_NULL_BMP=5
Const PS_INSIDEFRAME_BMP=6

'copy modes
Const BLACKNESS_BMP=&H42
Const DSTINVERT_BMP=&H550009
Const MERGECOPY_BMP=&HC000CA
Const MERGEPAINT_BMP=&HBB0226
Const NOTSRCCOPY_BMP=&H330008
Const NOTSRCERASE_BMP=&H1100A6
Const PATCOPY_BMP=&HF00021
Const PATINVERT_BMP=&H5A0049
Const PATPAINT_BMP=&HFB0A09
Const SRCAND_BMP=&H8800C6
Const SRCCOPY_BMP=&HCC0020
Const SRCERASE_BMP=&H440328
Const SRCINVERT_BMP=&H660046
Const SRCPAINT_BMP=&HEE0086
Const WHITENESS_BMP=&HFF0062

Const NULL_BRUSH_BMP=5
Const CF_BITMAP_BMP=2
Const DI_MASK_BMP=&H1
Const DI_IMAGE_BMP=&H2
Const DI_NORMAL_BMP=DI_MASK_BMP Or DI_IMAGE_BMP
Const OBJ_BITMAP_BMP=7      

Declare Function DrawIconExBmp Lib "user32" Alias "DrawIconEx" (hdc As Long,xLeft As Long,yTop As Long,hIcon As Long,cxWidth As Long,cyWidth As Long,istepIfAniCur As Long,hbrFlickerFreeDraw As Long,diFlags As Long) As Long
Declare Function CreateDCBmp Lib "gdi32" Alias "CreateCompatibleDC" (hdc As Long) As Long
Declare Function SelectObjectBmp Lib "gdi32" Alias "SelectObject" (hdc As Long,hObject As Long) As Long
Declare Function BitBltBmp Lib "gdi32" Alias "BitBlt" (hDestDC As Long,x As Long,y As Long,nWidth As Long,nHeight As Long,hSrcDC As Long,xSrc As Long,ySrc As Long,dwRop As Long) As Long
Declare Function DeleteDCBmp Lib "gdi32" Alias "DeleteDC" (hdc As Long) As Long
Declare Function GetObjectBmp Lib "gdi32" Alias "GetObjectA" (hObject As Long,nCount As Long, lpObject As TBITMAP_BMP) As Long
Declare Function GetStockObjectBmp Lib "gdi32" Alias "GetStockObject" (nIndex As Long) As Long
Declare Function LineToBmp Lib "gdi32" Alias "LineTo" (hdc As Long,x As Long,y As Long) As Long
Declare Function CreatePenBmp Lib "gdi32" Alias "CreatePen" (nPenStyle As Long, nWidth As Long, crColor As Long) As Long
Declare Function MoveToExBmp Lib "gdi32" Alias "MoveToEx" (hdc As Long,x As Long,y As Long, lpPoint As long) As Long
Declare Function RectangleBmp Lib "gdi32" Alias "Rectangle" (hdc As Long,X1 As Long,Y1 As Long,X2 As Long,Y2 As Long) As Long
Declare Function CreateSolidBrushBmp Lib "gdi32" Alias "CreateSolidBrush" (crColor As Long) As Long
Declare Function ElipseBmp Lib "gdi32" Alias "Ellipse" (hdc As Long,X1 As Long,Y1 As Long,X2 As Long,Y2 As Long) As Long
Declare Function ExtFloodFillBmp Lib "gdi32" Alias "ExtFloodFill" (hdc As Long,x As Long,y As Long,crColor As Long,wFillType As Long) As Long
Declare Function RoundRectBmp Lib "gdi32" Alias "RoundRect" (hdc As Long,X1 As Long,Y1 As Long,X2 As Long,Y2 As Long,X3 As Long,Y3 As Long) As Long
Declare Function PatBltBmp Lib "gdi32" Alias "PatBlt" (hdc As Long,x As Long,y As Long,nWidth As Long,nHeight As Long,dwRop As Long) As Long
Declare Function StretchBltBmp Lib "gdi32" Alias "StretchBlt" (hdc As Long,x As Long,y As Long,nWidth As Long,nHeight As Long,hSrcDC As Long,xSrc As Long,ySrc As Long,nSrcWidth As Long,nSrcHeight As Long,dwRop As Long) As Long
Declare Function DeleteObjectBmp Lib "gdi32" Alias "DeleteObject" (hObject As Long) As Long
Declare Function GetCurrentObjectBmp Lib "gdi32" Alias "GetCurrentObject" (hdc As Long,uObjectType As Long) As Long
Declare Function Load_JPGBmp Lib "NViewLib.dll" Alias "Load_JPG" (FileName As String,Progress As Integer) As Long
Declare Function Load_GIFBmp Lib "NViewLib.dll" Alias "Load_GIF" (FileName As String,Progress As Integer) As Long
Declare Function LoadBmp Lib "NVIEWLIB" Alias "NViewLibLoad" (FileName As String,Progress As Integer) As Long
Declare Function SetLanguageBmp Lib "NVIEWLIB" Alias "NViewLibSetLanguage" (Language As String) As Integer
Declare Function GetWidthBmp Lib "NVIEWLIB" Alias "GetWidth" () As Integer
Declare Function GetHeightBmp Lib "NVIEWLIB" Alias "GetHeight" () As Integer
Declare Function SaveAsJPGBmp Lib "NViewLib.dll" Alias "NViewLibSaveAsJPG" (Quality As Integer,FileName As String) As Integer


Type QBitmapEx EXTENDS QBITMAP
  PRIVATE:
    info as TBITMAP_BMP
    hpen as long
    hbrush as long
    oldpen as long
    oldbrush as long
  PUBLIC:
    PenStyle as long
    PenSize as integer
      
  '========================================
  ' méthode dessin d'icones
  '========================================
  Sub DrawIco(left as integer,top as integer,width as integer,height as integer,handle as long)
    DrawIconExBmp(QBitmapEx.handle,left,top,handle,width,height,0,0,DI_NORMAL_BMP)
  End Sub

  '================================================
  ' méthode copie le contenu dans le presse papier
  '================================================
  Sub CopyToClipboard
    dim hBitmap as integer
    dim bitmap as QBitmap 
    
    bitmap.bmp=this.bmp
    bitmap.pixelformat=0
    hBitmap=GetCurrentObjectBmp(bitmap.handle,OBJ_BITMAP_BMP)
    clipboard.open
    clipboard.clear
    clipboard.SetAsHandle(CF_BITMAP_BMP,hBitmap)
    clipboard.close
  End Sub

  '=============================================
  ' méthode colle une image du le presse papier
  '=============================================
  Sub PasteFromClipboard(x as short,y as short)
    dim hDC as integer
    dim hBitmap as integer
    dim hOldBitmap as integer

    if clipboard.hasformat(CF_BITMAP_BMP) then
      clipboard.open
      hBitmap=clipboard.GetAsHandle(CF_BITMAP_BMP)
      clipboard.close
      GetObjectBmp(hBitmap,SIZEOF(QBitmapEx.info),QBitmapEx.info)
      hDC=CreateDCBmp(QBitmapEx.handle)
      hOldBitmap=SelectObjectBmp(hDC,hBitmap)
      BitBltBmp(QBitmapEx.handle,x,y,QBitmapEx.info.bmwidth,QBitmapEx.info.bmheight,hDC,0,0,SRCCOPY_BMP)
      SelectObjectBmp(hDC,hOldBitmap)
      DeleteDCBmp(hDC)
    end if
  End Sub

  '===============================================
  ' méthode info largeur image du presse papier
  '===============================================
  Function GetWidthClipboard as integer
    dim hBitmap as integer

    if clipboard.hasformat(CF_BITMAP_BMP) then
      clipboard.open
      hBitmap=clipboard.GetAsHandle(CF_BITMAP_BMP)
      clipboard.close
      GetObjectBmp(hBitmap,SIZEOF(QBitmapEx.info),QBitmapEx.info)
      result=QBitmapEx.info.bmwidth
    end if
  End Function

  '===============================================
  ' méthode info hauteur image du presse papier
  '===============================================
  Function GetHeightClipboard as integer
    dim hBitmap as integer

    if clipboard.hasformat(CF_BITMAP_BMP) then
      clipboard.open
      hBitmap=clipboard.GetAsHandle(CF_BITMAP_BMP)
      clipboard.close
      GetObjectBmp(hBitmap,SIZEOF(QBitmapEx.info),QBitmapEx.info)
      result=QBitmapEx.info.bmheight
    end if
  End Function

  '===============================================
  ' méthode info image presente dans presse papier
  '===============================================
  Function CanPaste as boolean
    result=clipboard.hasformat(CF_BITMAP_BMP)
  End Function

  '========================================
  ' méthode trace un cercle vide
  '========================================
  Sub circle(x1 as integer,y1 as integer,x2 as integer,y2 as integer,c as long)
    QBitmapEx.hbrush=GetStockObjectBmp(NULL_BRUSH_BMP)
    QBitmapEx.oldbrush=SelectObjectBmp(QBitmapEx.handle,QBitmapEx.hbrush)
    QBitmapEx.hpen=CreatePenBmp(QBitmapEx.PenStyle,QBitmapEx.PenSize,c)
    QBitmapEx.oldpen=SelectObjectBmp(QBitmapEx.handle,QBitmapEx.hpen)
    ElipseBmp(QBitmapEx.handle,x1,y1,x2,y2)
    SelectObjectBmp(QBitmapEx.handle,QBitmapEx.oldpen)
    SelectObjectBmp(QBitmapEx.handle,QBitmapEx.oldbrush)
    DeleteObjectBmp(QBitmapEx.hpen)
  End Sub

  '========================================
  ' méthode trace un cercle plein
  '========================================
  Sub circleFilled(x1 as integer,y1 as integer,x2 as integer,y2 as integer,c as long,fill as long)
    QBitmapEx.hpen=CreatePenBmp(QBitmapEx.PenStyle,QBitmapEx.PenSize,c)
    QBitmapEx.hbrush=CreateSolidBrushBmp(fill)
    QBitmapEx.oldpen=SelectObjectBmp(QBitmapEx.handle,QBitmapEx.hpen)
    QBitmapEx.oldbrush=SelectObjectBmp(QBitmapEx.handle,QBitmapEx.hbrush)
    ElipseBmp(QBitmapEx.handle,x1,y1,x2,y2)
    SelectObjectBmp(QBitmapEx.handle,QBitmapEx.oldpen)
    SelectObjectBmp(QBitmapEx.handle,QBitmapEx.oldbrush)
    DeleteObjectBmp(QBitmapEx.hpen)
    DeleteObjectBmp(QBitmapEx.hbrush)
  End Sub

  '========================================
  ' méthode trace un rectangle vide
  '========================================
  Sub rectangle(x1 as integer,y1 as integer,x2 as integer,y2 as integer,c as long)
    QBitmapEx.hbrush=GetStockObjectBmp(NULL_BRUSH_BMP)
    QBitmapEx.oldbrush=SelectObjectBmp(QBitmapEx.handle,QBitmapEx.hbrush)
    QBitmapEx.hpen=CreatePenBmp(QBitmapEx.PenStyle,QBitmapEx.PenSize,c)
    QBitmapEx.oldpen=SelectObjectBmp(QBitmapEx.handle,QBitmapEx.hpen)
    RectangleBmp(QBitmapEx.handle,x1,y1,x2,y2)
    SelectObjectBmp(QBitmapEx.handle,QBitmapEx.oldpen)
    SelectObjectBmp(QBitmapEx.handle,QBitmapEx.oldbrush)
    DeleteObjectBmp(QBitmapEx.hpen)
  End Sub
  
  '==================================================
  ' méthode trace un rectangle vide au coins arrondi
  '==================================================
  Sub RoundRect(x1 as integer,y1 as integer,x2 as integer,y2 as integer,x3 as integer,y3 as integer,c as long)
    QBitmapEx.hbrush=GetStockObjectBmp(NULL_BRUSH_BMP)
    QBitmapEx.oldbrush=SelectObjectBmp(QBitmapEx.handle,QBitmapEx.hbrush)
    QBitmapEx.hpen=CreatePenBmp(QBitmapEx.PenStyle,QBitmapEx.PenSize,c)
    QBitmapEx.oldpen=SelectObjectBmp(QBitmapEx.handle,QBitmapEx.hpen)
    RoundRectBmp(QBitmapEx.handle,x1,y1,x2,y2,x3,y3)
    SelectObjectBmp(QBitmapEx.handle,QBitmapEx.oldpen)
    SelectObjectBmp(QBitmapEx.handle,QBitmapEx.oldbrush)
    DeleteObjectBmp(QBitmapEx.hpen)
  End Sub

  '==================================================
  ' méthode trace un rectangle plein au coins arrondi
  '==================================================
  Sub RoundRectFilled(x1 as integer,y1 as integer,x2 as integer,y2 as integer,x3 as integer,y3 as integer,c as long,fill as long)
    QBitmapEx.hpen=CreatePenBmp(QBitmapEx.PenStyle,QBitmapEx.PenSize,c)
    QBitmapEx.hbrush=CreateSolidBrushBmp(fill)
    QBitmapEx.oldpen=SelectObjectBmp(QBitmapEx.handle,QBitmapEx.hpen)
    QBitmapEx.oldbrush=SelectObjectBmp(QBitmapEx.handle,QBitmapEx.hbrush)
    RoundRectBmp(QBitmapEx.handle,x1,y1,x2,y2,x3,y3)
    SelectObjectBmp(QBitmapEx.handle,QBitmapEx.oldpen)
    SelectObjectBmp(QBitmapEx.handle,QBitmapEx.oldbrush)
    DeleteObjectBmp(QBitmapEx.hpen)
    DeleteObjectBmp(QBitmapEx.hbrush)
  End Sub
    
  '==================================================
  ' méthode trace un rectangle plein
  '==================================================
  Sub rectangleFilled(x1 as integer,y1 as integer,x2 as integer,y2 as integer,c as long,fill as long)
    QBitmapEx.hpen=CreatePenBmp(QBitmapEx.PenStyle,QBitmapEx.PenSize,c)
    QBitmapEx.hbrush=CreateSolidBrushBmp(fill)
    QBitmapEx.oldpen=SelectObjectBmp(QBitmapEx.handle,QBitmapEx.hpen)
    QBitmapEx.oldbrush=SelectObjectBmp(QBitmapEx.handle,QBitmapEx.hbrush)
    RectangleBmp(QBitmapEx.handle,x1,y1,x2,y2)
    SelectObjectBmp(QBitmapEx.handle,QBitmapEx.oldpen)
    SelectObjectBmp(QBitmapEx.handle,QBitmapEx.oldbrush)
    DeleteObjectBmp(QBitmapEx.hpen)
    DeleteObjectBmp(QBitmapEx.hbrush)
  End Sub
  
  '==================================================
  ' méthode trace une ligne
  '==================================================
  Sub line(x1 as integer,y1 as integer,x2 as integer,y2 as integer,c as long)
    QBitmapEx.hpen=CreatePenBmp(QBitmapEx.PenStyle,QBitmapEx.PenSize,c)
    QBitmapEx.oldpen=SelectObjectBmp(QBitmapEx.handle,QBitmapEx.hpen)
    MoveToExBmp(QBitmapEx.handle,x1,y1,0)
    LineToBmp(QBitmapEx.handle,x2,y2)
    SelectObjectBmp(QBitmapEx.handle,QBitmapEx.oldpen)
    DeleteObjectBmp(QBitmapEx.hpen)
  End Sub

  '==================================================
  ' méthode rempli une surface
  '==================================================
  Sub FillSurface(x as integer,y as integer,c as long)
    QBitmapEx.hbrush=CreateSolidBrushBmp(c)
    QBitmapEx.oldbrush=SelectObjectBmp(QBitmapEx.handle,QBitmapEx.hbrush)
    ExtFloodFillBmp(QBitmapEx.handle,x,y,QBitmapEx.pixel(x,y),1)
    SelectObjectBmp(QBitmapEx.handle,QBitmapEx.oldbrush)
    DeleteObjectBmp(QBitmapEx.hbrush)
  End Sub
    
  '==================================================
  ' méthode inverse les couleurs
  '==================================================
  Sub InvertColor(x as integer,y as integer,width as integer,height as integer)
    PatBltBmp(QBitmapEx.handle,x,y,Width,Height,DSTINVERT_BMP)
  End Sub

  '==================================================
  ' méthode effectue un miroir en x
  '==================================================
  Sub mirror(x as integer,y as integer,width as integer,height as integer)
    StretchBltBmp(QBitmapEx.handle,x+width,y,-Width,Height,QBitmapEx.handle,x,y,Width,Height,SRCCOPY_BMP)
  End Sub

  '==================================================
  ' méthode effectue un miroir en y
  '==================================================
  Sub flip(x as integer,y as integer,width as integer,height as integer)
    StretchBltBmp(QBitmapEx.handle,x,y+height,Width,-Height,QBitmapEx.handle,x,y,Width,Height,SRCCOPY_BMP)
  End Sub

  '==================================================
  ' méthode charge les formats dll
  '==================================================
  Sub LoadOtherImage(FileName as string,Progress as boolean,Language as string)
    dim hDC as integer
    dim hBitmap as long
    dim hOldBitmap as integer

    SetLanguageBmp(language)
    hBitmap=LoadBmp(FileName,Progress)
    if hBitmap<>0 then
      this.pixelformat=6
      this.width=GetWidthBmp()
      this.height=GetHeightBmp()
      hDC=CreateDCBmp(QBitmapEx.handle)
      hOldBitmap=SelectObjectBmp(hDC,hBitmap)
      BitBltBmp(QBitmapEx.handle,0,0,this.width,this.height,hDC,0,0,SRCCOPY_BMP)
      SelectObjectBmp(hDC,hOldBitmap)
      DeleteDCBmp(hDC)
      DeleteObjectBmp(hBitmap)
    end if    
  End Sub

  '==================================================
  ' méthode sauve le bitmap au format Jpg
  '==================================================
  Sub SaveAsJpg(FileName as string,Quality as Integer)
    dim hBitmap as integer
    dim path as string
    dim File as string
    dim bitmap as qbitmap
    
    if FileName<>"" then
      path=LEFT$(FileName,RINSTR(FileName,"\"))
      if DirExists(path) then
      	File=path+"temp.bmp"
      	bitmap.pixelformat=5
      	bitmap.width=this.width
      	bitmap.height=this.height
      	bitmap.draw(0,0,this.bmp)
      	bitmap.pixelformat=6
        bitmap.SaveToFile(File)
        hBitmap=LoadBmp(File,false)
        SaveAsJPGBmp(Quality,FileName)
        DeleteObjectBmp(hBitmap)
        Kill File
      end if
    end if  
  End Sub
    
  Constructor
    PenStyle=PS_SOLID_BMP
    PenSize=1
  End Constructor
End Type
