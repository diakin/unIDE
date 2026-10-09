'=======================================================
' Type Objet
' Classe QCanvasEx
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

Type TBITMAP
  bmType As Long
  bmWidth As Long
  bmHeight As Long
  bmWidthBytes As Long
  bmPlanes As Integer
  bmBitsPixel As Integer
  bmBits As Long
End Type

' type mixmode
Const R2_BLACK_CAN=1
Const R2_NOTMERGEPEN_CAN=2
Const R2_MASKNOTPEN_CAN=3
Const R2_NOTCOPYPEN_CAN=4
Const R2_MASKPENNOT_CAN=5
Const R2_NOT_CAN=6
Const R2_XORPEN_CAN=7
Const R2_NOTMASKPEN_CAN=8
Const R2_MASKPEN_CAN=9
Const R2_NOTXORPEN_CAN=10
Const R2_NOP_CAN=11
Const R2_MERGENOTPEN_CAN=12
Const R2_COPYPEN_CAN=13
Const R2_MERGEPENNOT_CAN=14
Const R2_MERGEPEN_CAN=15
Const R2_WHITE_CAN=16

'pen styles
Const PS_SOLID_CAN=0
Const PS_DASH_CAN=1
Const PS_DOT_CAN=2
Const PS_DASHDOT_CAN=3
Const PS_DASHDOTDOT_CAN=4
Const PS_NULL_CAN=5
Const PS_INSIDEFRAME_CAN=6

'copy modes
Const BLACKNESS_CAN=&H42
Const DSTINVERT_CAN=&H550009
Const MERGECOPY_CAN=&HC000CA
Const MERGEPAINT_CAN=&HBB0226
Const NOTSRCCOPY_CAN=&H330008
Const NOTSRCERASE_CAN=&H1100A6
Const PATCOPY_CAN=&HF00021
Const PATINVERT_CAN=&H5A0049
Const PATPAINT_CAN=&HFB0A09
Const SRCAND_CAN=&H8800C6
Const SRCCOPY_CAN=&HCC0020
Const SRCERASE_CAN=&H440328
Const SRCINVERT_CAN=&H660046
Const SRCPAINT_CAN=&HEE0086
Const WHITENESS_CAN=&HFF0062

Const CF_BITMAP_CAN=2
Const DI_MASK_CAN=&H1
Const DI_IMAGE_CAN=&H2
Const DI_NORMAL_CAN=DI_MASK_CAN Or DI_IMAGE_CAN
Const NULL_BRUSH_CAN=5
Const OPAQUE_CAN=2
Const TRANSPARENT_CAN=1



Declare Function DrawIconExCan Lib "user32" Alias "DrawIconEx" (hdc As Long,xLeft As Long,yTop As Long,hIcon As Long,cxWidth As Long,cyWidth As Long,istepIfAniCur As Long,hbrFlickerFreeDraw As Long,diFlags As Long) As Long
Declare Function GetObjectCan Lib "gdi32" Alias "GetObjectA" (hObject As Long,nCount As Long, lpObject As TBITMAP) As Long
Declare Function DrawIconCan Lib "user32" Alias "DrawIcon" (hdc As Long,x As Long,y As Long,hIcon As Long) As Long
Declare Function DeleteObjectCan Lib "gdi32" Alias "DeleteObject" (hObject As Long) As Long
Declare Function CreateDCCan Lib "gdi32" Alias "CreateCompatibleDC" (hdc As Long) As Long
Declare Function SelectObjectCan Lib "gdi32" Alias "SelectObject" (hdc As Long,hObject As Long) As Long
Declare Function BitBltCan Lib "gdi32" Alias "BitBlt" (hDestDC As Long,x As Long,y As Long,nWidth As Long,nHeight As Long,hSrcDC As Long,xSrc As Long,ySrc As Long,dwRop As Long) As Long
Declare Function DeleteDCCan Lib "gdi32" Alias "DeleteDC" (hdc As Long) As Long
Declare Function CreateBitmapCan Lib "gdi32" Alias "CreateCompatibleBitmap" (hdc As Long,nWidth As Long,nHeight As Long) As Long
Declare Function SetROP2Can Lib "gdi32" Alias "SetROP2" (hdc As Long,nDrawMode As long) As Long
Declare Function LineToCan Lib "gdi32" Alias "LineTo" (hdc As Long,x As Long,y As Long) As Long
Declare Function CreatePenCan Lib "gdi32" Alias "CreatePen" (nPenStyle As Long, nWidth As Long, crColor As Long) As Long
Declare Function MoveToExCan Lib "gdi32" Alias "MoveToEx" (hdc As Long,x As Long,y As Long, lpPoint As long) As Long
Declare Function RectangleCan Lib "gdi32" Alias "Rectangle" (hdc As Long,X1 As Long,Y1 As Long,X2 As Long,Y2 As Long) As Long
Declare Function CreateSolidBrushCan Lib "gdi32" Alias "CreateSolidBrush" (crColor As Long) As Long
Declare Function EllipseCan Lib "gdi32" Alias "Ellipse" (hdc As Long,X1 As Long,Y1 As Long,X2 As Long,Y2 As Long) As Long
Declare Function GetStockObjectCan Lib "gdi32" Alias "GetStockObject" (nIndex As Long) As Long
Declare Function ExtFloodFillCan Lib "gdi32" Alias "ExtFloodFill" (hdc As Long,x As Long,y As Long,crColor As Long,wFillType As Long) As Long
Declare Function SetBkModeCan Lib "gdi32" Alias "SetBkMode" (hdc As Long,nBkMode As Long) As Long
Declare Function RoundRectCan Lib "gdi32" Alias "RoundRect" (hdc As Long,X1 As Long,Y1 As Long,X2 As Long,Y2 As Long,X3 As Long,Y3 As Long) As Long
Declare Function PatBltCan Lib "gdi32" Alias "PatBlt" (hdc As Long,x As Long,y As Long,nWidth As Long,nHeight As Long,dwRop As Long) As Long
Declare Function StretchBltCan Lib "gdi32" Alias "StretchBlt" (hdc As Long,x As Long,y As Long,nWidth As Long,nHeight As Long,hSrcDC As Long,xSrc As Long,ySrc As Long,nSrcWidth As Long,nSrcHeight As Long,dwRop As Long) As Long


Type QCanvasEx EXTENDS QCANVAS
  PRIVATE:
    info as TBITMAP
    hpen as long
    hbrush as long
    oldpen as long
    oldbrush as long

  PUBLIC:
    MixMode as long
    PenStyle as long
    PenSize as integer


  '========================================
  ' méthode dessin d'icones
  '========================================
  Sub DrawIco(left as integer,top as integer,width as integer,height as integer,handle as long)
    DrawIconExCan(QCanvasEx.handle,left,top,handle,width,height,0,0,DI_NORMAL_CAN)
  End Sub
 
  '================================================
  ' méthode copie le contenu dans le presse papier
  '================================================
  Sub CopyToClipboard(rect as QRECT)
    dim hDC as integer
    dim hBitmap as integer
    dim hOldBitmap as integer
    dim width as integer
    dim height as integer

    width=rect.right-rect.left
    height=rect.bottom-rect.top
    hDC=CreateDCCan(QCanvasEx.handle)
    hBitmap=CreateBitmapCan(QCanvasEx.handle,width,height)
    hOldBitmap=SelectObjectCan(hDC,hBitmap)
    BitBltCan(hDC,0,0,width,height,QCanvasEx.handle,rect.left,rect.top,SRCCOPY_CAN)
    clipboard.open
    clipboard.clear
    clipboard.SetAsHandle(CF_BITMAP_CAN,hBitmap)
    clipboard.close
    SelectObjectCan(hDC,hOldBitmap)
    DeleteDCCan(hDC)
    DeleteObjectCan(hBitmap)
  End Sub
  
  '=============================================
  ' méthode colle une image du le presse papier
  '=============================================
  Sub PasteFromClipboard(x as short,y as short)
    dim hDC as integer
    dim hBitmap as integer
    dim hOldBitmap as integer

    if clipboard.hasformat(CF_BITMAP_CAN) then
      clipboard.open
      hBitmap=clipboard.GetAsHandle(CF_BITMAP_CAN)
      clipboard.close
      GetObjectCan(hBitmap,SIZEOF(QCanvasEx.info),QCanvasEx.info)
      hDC=CreateDCCan(QCanvasEx.handle)
      hOldBitmap=SelectObjectCan(hDC,hBitmap)
      BitBltCan(QCanvasEx.handle,x,y,QCanvasEx.info.bmwidth,QCanvasEx.info.bmheight,hDC,0,0,SRCCOPY_CAN)
      SelectObjectCan(hDC,hOldBitmap)
      DeleteDCCan(hDC)
    end if
  End Sub

  '===============================================
  ' méthode info largeur image du presse papier
  '===============================================
  Function GetWidthClipboard as integer
    dim hBitmap as integer

    if clipboard.hasformat(CF_BITMAP_CAN) then
      clipboard.open
      hBitmap=clipboard.GetAsHandle(CF_BITMAP_CAN)
      clipboard.close
      GetObjectCan(hBitmap,SIZEOF(QCanvasEx.info),QCanvasEx.info)
      result=QCanvasEx.info.bmwidth
    end if
  End Function

  '===============================================
  ' méthode info hauteur image du presse papier
  '===============================================
  Function GetHeightClipboard as integer
    dim hBitmap as integer

    if clipboard.hasformat(CF_BITMAP_CAN) then
      clipboard.open
      hBitmap=clipboard.GetAsHandle(CF_BITMAP_CAN)
      clipboard.close
      GetObjectCan(hBitmap,SIZEOF(QCanvasEx.info),QCanvasEx.info)
      result=QCanvasEx.info.bmheight
    end if
  End Function

  '===============================================
  ' méthode info image presente dans presse papier
  '===============================================
  Function CanPaste as boolean
    result=clipboard.hasformat(CF_BITMAP_CAN)
  End Function

  '========================================
  ' méthode trace un cercle vide
  '========================================
  Sub circle(x1 as integer,y1 as integer,x2 as integer,y2 as integer,c as long)
    QCanvasEx.hbrush=GetStockObjectCan(NULL_BRUSH_CAN)
    QCanvasEx.oldbrush=SelectObjectCan(QCanvasEx.handle,QCanvasEx.hbrush)
    QCanvasEx.hpen=CreatePenCan(QCanvasEx.PenStyle,QCanvasEx.PenSize,c)
    QCanvasEx.oldpen=SelectObjectCan(QCanvasEx.handle,QCanvasEx.hpen)
    SetROP2Can(QCanvasEx.handle,QCanvasEx.mixmode)
    EllipseCan(QCanvasEx.handle,x1,y1,x2,y2)
    SelectObjectCan(QCanvasEx.handle,QCanvasEx.oldpen)
    SelectObjectCan(QCanvasEx.handle,QCanvasEx.oldbrush)
    DeleteObjectCan(QCanvasEx.hpen)
  End Sub

  '========================================
  ' méthode trace un cercle plein
  '========================================
  Sub circleFilled(x1 as integer,y1 as integer,x2 as integer,y2 as integer,c as long,fill as long)
    QCanvasEx.hpen=CreatePenCan(QCanvasEx.PenStyle,QCanvasEx.PenSize,c)
    QCanvasEx.hbrush=CreateSolidBrushCan(fill)
    QCanvasEx.oldpen=SelectObjectCan(QCanvasEx.handle,QCanvasEx.hpen)
    QCanvasEx.oldbrush=SelectObjectCan(QCanvasEx.handle,QCanvasEx.hbrush)
    SetROP2Can(QCanvasEx.handle,QCanvasEx.mixmode)
    EllipseCan(QCanvasEx.handle,x1,y1,x2,y2)
    SelectObjectCan(QCanvasEx.handle,QCanvasEx.oldpen)
    SelectObjectCan(QCanvasEx.handle,QCanvasEx.oldbrush)
    DeleteObjectCan(QCanvasEx.hpen)
    DeleteObjectCan(QCanvasEx.hbrush)
  End Sub

  '========================================
  ' méthode trace un rectangle vide
  '========================================
  Sub rectangle(x1 as integer,y1 as integer,x2 as integer,y2 as integer,c as long)
    QCanvasEx.hbrush=GetStockObjectCan(NULL_BRUSH_CAN)
    QCanvasEx.oldbrush=SelectObjectCan(QCanvasEx.handle,QCanvasEx.hbrush)
    QCanvasEx.hpen=CreatePenCan(QCanvasEx.PenStyle,QCanvasEx.PenSize,c)
    QCanvasEx.oldpen=SelectObjectCan(QCanvasEx.handle,QCanvasEx.hpen)
    SetROP2Can(QCanvasEx.handle,QCanvasEx.mixmode)
    RectangleCan(QCanvasEx.handle,x1,y1,x2,y2)
    SelectObjectCan(QCanvasEx.handle,QCanvasEx.oldpen)
    SelectObjectCan(QCanvasEx.handle,QCanvasEx.oldbrush)
    DeleteObjectCan(QCanvasEx.hpen)
  End Sub
  
  '==================================================
  ' méthode trace un rectangle vide au coins arrondi
  '==================================================
  Sub RoundRect(x1 as integer,y1 as integer,x2 as integer,y2 as integer,x3 as integer,y3 as integer,c as long)
    QCanvasEx.hbrush=GetStockObjectCan(NULL_BRUSH_CAN)
    QCanvasEx.oldbrush=SelectObjectCan(QCanvasEx.handle,QCanvasEx.hbrush)
    QCanvasEx.hpen=CreatePenCan(QCanvasEx.PenStyle,QCanvasEx.PenSize,c)
    QCanvasEx.oldpen=SelectObjectCan(QCanvasEx.handle,QCanvasEx.hpen)
    SetROP2Can(QCanvasEx.handle,QCanvasEx.mixmode)
    RoundRectCan(QCanvasEx.handle,x1,y1,x2,y2,x3,y3)
    SelectObjectCan(QCanvasEx.handle,QCanvasEx.oldpen)
    SelectObjectCan(QCanvasEx.handle,QCanvasEx.oldbrush)
    DeleteObjectCan(QCanvasEx.hpen)
  End Sub

  '==================================================
  ' méthode trace un rectangle plein au coins arrondi
  '==================================================
  Sub RoundRectFilled(x1 as integer,y1 as integer,x2 as integer,y2 as integer,x3 as integer,y3 as integer,c as long,fill as long)
    QCanvasEx.hpen=CreatePenCan(QCanvasEx.PenStyle,QCanvasEx.PenSize,c)
    QCanvasEx.hbrush=CreateSolidBrushCan(fill)
    QCanvasEx.oldpen=SelectObjectCan(QCanvasEx.handle,QCanvasEx.hpen)
    QCanvasEx.oldbrush=SelectObjectCan(QCanvasEx.handle,QCanvasEx.hbrush)
    SetROP2Can(QCanvasEx.handle,QCanvasEx.mixmode)
    RoundRectCan(QCanvasEx.handle,x1,y1,x2,y2,x3,y3)
    SelectObjectCan(QCanvasEx.handle,QCanvasEx.oldpen)
    SelectObjectCan(QCanvasEx.handle,QCanvasEx.oldbrush)
    DeleteObjectCan(QCanvasEx.hpen)
    DeleteObjectCan(QCanvasEx.hbrush)
  End Sub
    
  '==================================================
  ' méthode trace un rectangle plein
  '==================================================
  Sub rectangleFilled(x1 as integer,y1 as integer,x2 as integer,y2 as integer,c as long,fill as long)
    QCanvasEx.hpen=CreatePenCan(QCanvasEx.PenStyle,QCanvasEx.PenSize,c)
    QCanvasEx.hbrush=CreateSolidBrushCan(fill)
    QCanvasEx.oldpen=SelectObjectCan(QCanvasEx.handle,QCanvasEx.hpen)
    QCanvasEx.oldbrush=SelectObjectCan(QCanvasEx.handle,QCanvasEx.hbrush)
    SetROP2Can(QCanvasEx.handle,QCanvasEx.mixmode)
    RectangleCan(QCanvasEx.handle,x1,y1,x2,y2)
    SelectObjectCan(QCanvasEx.handle,QCanvasEx.oldpen)
    SelectObjectCan(QCanvasEx.handle,QCanvasEx.oldbrush)
    DeleteObjectCan(QCanvasEx.hpen)
    DeleteObjectCan(QCanvasEx.hbrush)
  End Sub
  
  '==================================================
  ' méthode trace une ligne
  '==================================================
  Sub line(x1 as integer,y1 as integer,x2 as integer,y2 as integer,c as long)
    QCanvasEx.hpen=CreatePenCan(QCanvasEx.PenStyle,QCanvasEx.PenSize,c)
    QCanvasEx.oldpen=SelectObjectCan(QCanvasEx.handle,QCanvasEx.hpen)
    SetROP2Can(QCanvasEx.handle,QCanvasEx.mixmode)
    MoveToExCan(QCanvasEx.handle,x1,y1,0)
    LineToCan(QCanvasEx.handle,x2,y2)
    SelectObjectCan(QCanvasEx.handle,QCanvasEx.oldpen)
    DeleteObjectCan(QCanvasEx.hpen)
  End Sub

  '==================================================
  ' méthode rempli une surface
  '==================================================
  Sub FillSurface(x as integer,y as integer,c as long)
    QCanvasEx.hbrush=CreateSolidBrushCan(c)
    QCanvasEx.oldbrush=SelectObjectCan(QCanvasEx.handle,QCanvasEx.hbrush)
    ExtFloodFillCan(QCanvasEx.handle,x,y,QCanvasEx.pixel(x,y),1)
    SelectObjectCan(QCanvasEx.handle,QCanvasEx.oldbrush)
    DeleteObjectCan(QCanvasEx.hbrush)
  End Sub
  
  '==================================================
  ' méthode affiche du texte
  '==================================================
  Sub TextOut(x as integer,y as integer,s as string,fc as long,bc as long)
    SetBkModeCan(QCanvasEx.handle,TRANSPARENT_CAN)
    super.TextOut(x,y,s,fc,bc)
    SetBkModeCan(QCanvasEx.handle,OPAQUE_CAN)
  End Sub
  
  '==================================================
  ' méthode inverse les couleurs
  '==================================================
  Sub InvertColor(x as integer,y as integer,width as integer,height as integer)
    PatBltCan(QCanvasEx.handle,x,y,Width,Height,DSTINVERT_CAN)
  End Sub

  '==================================================
  ' méthode effectue un miroir en x
  '==================================================
  Sub mirror(x as integer,y as integer,width as integer,height as integer)
    StretchBltCan(QCanvasEx.handle,x+width,y,-Width,Height,QCanvasEx.handle,x,y,Width,Height,SRCCOPY_CAN)
  End Sub

  '==================================================
  ' méthode effectue un miroir en y
  '==================================================
  Sub flip(x as integer,y as integer,width as integer,height as integer)
    StretchBltCan(QCanvasEx.handle,x,y+height,Width,-Height,QCanvasEx.handle,x,y,Width,Height,SRCCOPY_CAN)
  End Sub
    
  Constructor
    MixMode=R2_COPYPEN_CAN
    PenStyle=PS_SOLID_CAN
    PenSize=1
  End Constructor
End Type
      