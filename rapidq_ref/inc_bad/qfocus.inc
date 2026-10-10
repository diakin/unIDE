$TYPECHECK ON
'qfocus component by John Graves aka laddie@bellsouth.net
dim drag as qbutton
$include "rapidq2.inc"
$typecheck on
' This declaration is used as a template for event handlers 
' for OnHitFocus event 
Type POINTAPIFocus
        x As Long
        y As Long
End Type  

'  TYPE RectFocus
'       LEFT AS LONG
'       TOP AS LONG
'       RIGHT AS LONG
'       BOTTOM AS LONG
'      END TYPE  
     Type FBITMAP
  bmType As Long
  bmWidth As Long
  bmHeight As Long
  bmWidthBytes As Long
  bmPlanes As Integer
  bmBitsPixel As Integer
  bmBits As Long
End Type          
dim focusbitmap as qbitmap,focusimage as qimage

dim rectangledrag? as long
dim  rectanglesize? as long
dim cursor as pointapifocus
dim wrct as QRECT'rectfocus
dim crct as QRECT 'rectfocus
dim dragenable as long

'-----------------------------CopytoClipboard------------------   
declare sub objectfocusontimer
Declare Function CreateCompatiblefocusDC Lib "gdi32" Alias "CreateCompatibleDC" (ByVal hdc As Long) As Long
Declare Function focusBitBlt Lib "gdi32" Alias "BitBlt" (ByVal hDestDC As Long, ByVal x As Long, ByVal y As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal hSrcDC As Long, ByVal xSrc As Long, ByVal ySrc As Long, ByVal dwRop As Long) As Long
Declare Function CreateFocusBitmap Lib "gdi32" Alias "CreateCompatibleBitmap" (hdc As Long,nWidth As Long,nHeight As Long) As Long
Declare Function DeleteFocusObject Lib "gdi32" Alias "DeleteObject" (hObject As Long) As Long
Declare Function DeleteDCFocus Lib "gdi32" Alias "DeleteDC" (hdc As Long) As Long        
'------------------------Above for copytoclipboard----------------

Declare Function CreatePenFocus Lib "gdi32" Alias "CreatePen" (nPenStyle As Long, nWidth As Long, crColor As Long) As Long
Declare Function GetObjectFocus Lib "gdi32" Alias "GetObjectA" (hObject As Long,nCount As Long, lpObject As FBITMAP) As Long
Declare Function DeleteObjectFocus Lib "gdi32" Alias "DeleteObject" (hObject As Long) As Long
Declare Function SelectObjectFocus Lib "gdi32" Alias "SelectObject" (hdc As Long,hObject As Long) As Long
Declare Function RectangleFocus Lib "gdi32" Alias "Rectangle" (hdc As Long,X1 As Long,Y1 As Long,X2 As Long,Y2 As Long) As Long
Declare Function GetStockObjectFocus Lib "gdi32" Alias "GetStockObject" (nIndex As Long) As Long
Declare Function SetROP2focus Lib "gdi32" Alias "SetROP2" (hdc As Long,nDrawMode As long) As Long
Declare Function GetActiveWindowFocus Lib "user32" Alias "GetActiveWindow" () As Long
' Declare Function GetWindowRectFocus Lib "user32" Alias "GetWindowRect" (ByVal hwnd As Long, lpRect As RectFocus) As Long
' Declare Function GetClientRectFocus Lib "user32" Alias "GetClientRect" (ByVal hwnd As Long, lpRect As RectFocus) As Long
 Declare Function GetWindowRectFocus Lib "user32" Alias "GetWindowRect" (ByVal hwnd As Long, lpRect As QRECT) As Long
 Declare Function GetClientRectFocus Lib "user32" Alias "GetClientRect" (ByVal hwnd As Long, lpRect As QRECT) As Long

Declare Function GetCursorPosFocus Lib "user32" Alias "GetCursorPos" (lpPoint As POINTAPIFocus) As Long


Declare Sub SizeFocusEvent(width,height)
TYPE QFocus EXTENDS QCanvas
transparent as long
transparentcolor as long
OnSize as Event (SizeFocusEvent)
 ' Declare an event based on previously declared handler template 

objectfocustimer as qtimer
show as long
 EVENT OnMouseDown(Button AS LONG, x AS LONG, y AS LONG, Shift AS LONG)
  WITH QFocus
 rectangledrag?=1 


  END WITH
 END EVENT

 Event OnMouseMove(x as long,y as long, shift as integer)
 with QFocus



 dim size as integer, lh as long
 dim focuscursor as pointapifocus
 dim rct as QRECT 'rectfocus
 dim rct2 as QRECT 'rectfocus
 dim ret as long
 GetCursorPosFocus(focuscursor)
lh = getactivewindowfocus()

GetWindowRectFocus lh,rct
Showmessage str$(lh)
ret= GetClientRectFocus (lh, RCT2)
Showmessage "2"
 if x>6 or x<.width-6 then
 .cursor=-3
 size=0
 if rectangledrag?=1 then
 dragenable=1
 end if
 end if
if x>.width-7 or x< 7 then
dragenable=0
  .cursor=-14 
   size=2
 end if
 if y>.height-7 or y<7 then 
 dragenable=0
 .cursor=-15
 size=1
 end if



if rectangledrag?=1 and size=2   then
dragenable=0
dim focusreturn as long
'x axis

if x>=6 and x=.width then
if x=.width-3  and .width > 5 then

.left=.left+14
.width=x-14
end if

end if ' end x<4 and x=.width

.width=x

callfunc (.onsize,.width,.height)
if .width<2 then .width=2

end if


if rectangledrag?=1 and size=1 then
'y axis
dragenable=0
if y>=6 and y=.height then
if y=.height-3  and .height > 5 then

.top=.top+14
.height=y-14
end if
end if ' end x<4 and x=.width

.height=y
callfunc (.onsize,.width,.height)
end if

if .height<2 then .height=2
 end with
 end event
 event onmouseup
 with qFocus
 dragenable=0
 rectangledrag?=0
 rectanglesize?=0
 end with
 end event
 
 Event objectfocustimer.ontimer
   WITH QFocus
   focusimage.transparent=.transparent
   focusbitmap.transparentcolor=.transparentcolor
dim retf as long
GetCursorposfocus(cursor)
retf=GetActiveWindowFocus
getwindowrectfocus(retf,wrct)
getclientrectfocus(retf,crct)
dim leftadjust as integer
dim topadjust as long
leftadjust=(wrct.right-crct.right-wrct.left)/2
topadjust=(wrct.bottom-crct.bottom-wrct.top-leftadjust)
cursor.x=cursor.x-wrct.left-leftadjust
cursor.y=cursor.y-wrct.top-topadjust

   dim focusindex as long,focuscolor as long
   dim focushbrush as long, focusoldbrush as long
   dim focuspen as long,focushpen as long
   dim focussolidpen as long,focusoldpen as long

      
      if .show=1 then
   focusindex++
   if focusindex=1 then 
   focuscolor=&h0000f
   else
   focuscolor=&hffffff
   focusindex=0
   end if
focushbrush=GetStockObjectfocus(5)
focusoldbrush=SelectObjectfocus(.handle,focushbrush)
focushpen=CreatePenfocus(2,1,focuscolor)
focusoldpen=SelectObjectfocus(.handle,focushpen)
SetROP2focus(.handle,13) '13 is copy always pen color
  Rectanglefocus(.handle,0,0,.width,.height)
SelectObjectfocus(.handle,focusoldpen)
SelectObjectfocus(.handle,focusoldbrush)
DeleteObjectfocus(focushpen)

end if

if dragenable=1 then



leftadjust=(wrct.right-crct.right-wrct.left)/2
topadjust=(wrct.bottom-crct.bottom-wrct.top-leftadjust)


with qfocus
this.left=cursor.x-(this.width*.5)
this.top=cursor.y-(this.height*.5)
end if

  END WITH
 doevents
 end event
 
   Sub CopyToClipboard
   with qfocus
   this.repaint
  ' this.draw(0,0,focusbitmap)
  focusbitmap.width=this.width :focusbitmap.height=this.height


dim hDC as integer

    dim hBitmap as integer
    dim hOldBitmap as integer

    hDC=CreateCompatiblefocusDC(this.handle)
    hBitmap=CreateFocusBitmap(this.handle,this.width,this.height)
    hOldBitmap=SelectObjectfocus(hDC,hBitmap)
    focusBitBlt(hdc,0, 0,this.width,this.height, this.handle, 0,0, &HCC0020)
    clipboard.open
    clipboard.clear
    clipboard.SetAsHandle(2,hBitmap)
    clipboard.close
    SelectObjectFocus(hDC,hOldBitmap)
    DeleteDCFocus(hDC)
    DeletefocusObject(hBitmap)
    this.show=1
    end with    
  End Sub
  
'----------------------------------SUB----------paste for bitmap --------------------------------------
  Sub PasteFromClipboard
    dim hDC as integer
    dim hBitmap as integer
    dim hOldBitmap as integer
'-------clipboardpaste for bitmap
    if clipboard.hasformat(2) then

      clipboard.open
     focusimage.handle=clipboard.GetAsHandle(2)
     focusbitmap.bmp=focusimage.bmp
      clipboard.close

end if
  End Sub
  '------------------------------------------------------------------------------------------------------------------------------------------
  sub dragme
dim cursor as pointapifocus
dragenable=0
GetCursorposfocus(cursor)
dim ret as long : ret=getactivewindowfocus
getwindowrectfocus(ret,wrct)
getclientrectfocus(ret,crct)
dim leftadjust as integer
dim topadjust as long
leftadjust=(wrct.right-crct.right-wrct.left)/2
topadjust=(wrct.bottom-crct.bottom-wrct.top-leftadjust)
cursor.x=cursor.x-wrct.left-leftadjust
cursor.y=cursor.y-wrct.top-topadjust

with qfocus
this.left=cursor.x-(this.width/2)
this.top=cursor.y-(this.height/2)

end with

end sub




 CONSTRUCTOR
  objectfocustimer.enabled=1
  objectfocustimer.interval=1
  with qfocus
transparentcolor=&hffffff
transparent=1
 end with
 END CONSTRUCTOR
END TYPE
$typecheck off


