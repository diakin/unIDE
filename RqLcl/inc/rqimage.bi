' ---------------------------------------------------------------------------
'  RqLcl: QIMAGE (TImage LCL) и QIMAGELIST (TImageList LCL). Подключается из
'  rqlcl.bi.
'
'  Кэш картинок RapidQ (глава 8): чтение Image.BMP, Form.Icon и
'  ImageList.GetBMP(i) / GetICO(i) кладут картинку в кэш DLL и возвращают "";
'  запись BMP = "" / Icon = "" берёт картинку из кэша:
'  Button.BMP = ImageList.GetBMP(0), Image.Icon = Form.Icon.
'  BMPHandle / ICOHandle / AddBMPHandle - ресурс $RESOURCE.
' ---------------------------------------------------------------------------

' ---------------------------------------------------------------------------
'  QIMAGE - картинка (TImage); рисование - на картинке (её размер - размер
'  элемента, если картинки ещё нет)
' ---------------------------------------------------------------------------

Type QIMAGE Extends QCONTROL
    Declare Constructor()
    Declare Property Align() As Long
    Declare Property Align(ByVal Value As Long)
    Declare Property AutoSize() As Long
    Declare Property AutoSize(ByVal Value As Long)
    Declare Property Center() As Long
    Declare Property Center(ByVal Value As Long)
    Declare Property CopyMode() As Long
    Declare Property CopyMode(ByVal Value As Long)
    Declare Property IncrementalDisplay() As Long
    Declare Property IncrementalDisplay(ByVal Value As Long)
    Declare Property Stretch() As Long
    Declare Property Stretch(ByVal Value As Long)
    Declare Property Tag() As Long
    Declare Property Tag(ByVal Value As Long)
    Declare Property Transparent() As Long
    Declare Property Transparent(ByVal Value As Long)
    Declare Property BMP() As String
    Declare Property BMP(ByRef Value As String)
    Declare Property Icon() As String
    Declare Property Icon(ByRef Value As String)
    Declare Property BMPHandle(ByVal Value As Long)
    Declare Property ICOHandle(ByVal Value As Long)
    Declare Function Pixel(ByVal X As Long, ByVal Y As Long) As Long
    Declare Sub SetPixel(ByVal X As Long, ByVal Y As Long, ByVal PixelColor As Long)
    Declare Sub DrawInts(ByRef MethodName As String, ByRef Text1 As String, IntList() As Long)
    Declare Sub FillRect(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal FillColor As Long)
    Declare Sub TextOut(ByVal X1 As Long, ByVal Y1 As Long, ByRef Text1 As String, ByVal TextColor As Long, ByVal BackColor As Long = -1)
    Declare Sub Line(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal LineColor As Long)
    Declare Sub Rectangle(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal LineColor As Long)
    Declare Sub RoundRect(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal X3 As Long, ByVal Y3 As Long, ByVal FillColor As Long)
    Declare Sub Circle(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal LineColor As Long, ByVal FillFlag As Long)
    Declare Sub Pset(ByVal X1 As Long, ByVal Y1 As Long, ByVal PixelColor As Long)
    Declare Sub Paint(ByVal X1 As Long, ByVal Y1 As Long, ByVal FillColor As Long, ByVal BorderColor As Long)
    Declare Sub Draw(ByVal X1 As Long, ByVal Y1 As Long, ByRef BmpText As String)
    Declare Sub StretchDraw(ByRef DstRect As QRECT, ByRef BmpText As String)
    Declare Sub TextRect(ByRef ClipRect As QRECT, ByVal X1 As Long, ByVal Y1 As Long, ByRef Text1 As String, ByVal TextColor As Long, ByVal BackColor As Long = -1)
    Declare Sub CopyRectPtr(ByRef DstRect As QRECT, ByVal SourcePtr As Any Ptr, ByRef SrcRect As QRECT)
    Declare Sub CopyRect(ByRef DstRect As QRECT, ByRef Source As QCONTROL, ByRef SrcRect As QRECT)
    Declare Sub Rotate(ByVal X1 As Long, ByVal Y1 As Long, ByVal Angle As Long)
    Declare Function TextWidth(ByRef Text1 As String) As Long
    Declare Function TextHeight(ByRef Text1 As String) As Long
    Declare Property OnClick(ByVal Handler As Sub())
    Declare Property OnClick(ByVal Handler As Sub(ByRef Sender As QIMAGE))
    Declare Property OnDblClick(ByVal Handler As Sub())
    Declare Property OnDblClick(ByVal Handler As Sub(ByRef Sender As QIMAGE))
    Declare Property OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QIMAGE))
    Declare Property OnMouseDown(ByVal Handler As Sub())
    Declare Property OnMouseDown(ByVal Handler As Sub(ByRef Sender As QIMAGE))
    Declare Property OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QIMAGE))
    Declare Property OnMouseUp(ByVal Handler As Sub())
    Declare Property OnMouseUp(ByVal Handler As Sub(ByRef Sender As QIMAGE))
    Declare Property OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QIMAGE))
    Declare Property OnMouseMove(ByVal Handler As Sub())
    Declare Property OnMouseMove(ByVal Handler As Sub(ByRef Sender As QIMAGE))
End Type

Constructor QIMAGE()
    RqObj = RqLclNew("QIMAGE", @This)
End Constructor
Property QIMAGE.Align() As Long
    Return RqGetInt(RqObj, "Align")
End Property
Property QIMAGE.Align(ByVal Value As Long)
    RqLclSetInt(RqObj, "Align", Value)
End Property
Property QIMAGE.AutoSize() As Long
    Return RqGetInt(RqObj, "AutoSize")
End Property
Property QIMAGE.AutoSize(ByVal Value As Long)
    RqLclSetInt(RqObj, "AutoSize", Value)
End Property
Property QIMAGE.Center() As Long
    Return RqGetInt(RqObj, "Center")
End Property
Property QIMAGE.Center(ByVal Value As Long)
    RqLclSetInt(RqObj, "Center", Value)
End Property
Property QIMAGE.CopyMode() As Long
    Return RqGetInt(RqObj, "CopyMode")
End Property
Property QIMAGE.CopyMode(ByVal Value As Long)
    RqLclSetInt(RqObj, "CopyMode", Value)
End Property
Property QIMAGE.IncrementalDisplay() As Long
    Return RqGetInt(RqObj, "IncrementalDisplay")
End Property
Property QIMAGE.IncrementalDisplay(ByVal Value As Long)
    RqLclSetInt(RqObj, "IncrementalDisplay", Value)
End Property
Property QIMAGE.Stretch() As Long
    Return RqGetInt(RqObj, "Stretch")
End Property
Property QIMAGE.Stretch(ByVal Value As Long)
    RqLclSetInt(RqObj, "Stretch", Value)
End Property
Property QIMAGE.Tag() As Long
    Return RqGetInt(RqObj, "Tag")
End Property
Property QIMAGE.Tag(ByVal Value As Long)
    RqLclSetInt(RqObj, "Tag", Value)
End Property
Property QIMAGE.Transparent() As Long
    Return RqGetInt(RqObj, "Transparent")
End Property
Property QIMAGE.Transparent(ByVal Value As Long)
    RqLclSetInt(RqObj, "Transparent", Value)
End Property
Property QIMAGE.BMP() As String
    Return RqLclGetStr(RqObj, "BMP")
End Property
Property QIMAGE.BMP(ByRef Value As String)
    RqLclSetStr(RqObj, "BMP", Value)
End Property
Property QIMAGE.Icon() As String
    Return RqLclGetStr(RqObj, "Icon")
End Property
Property QIMAGE.Icon(ByRef Value As String)
    RqLclSetStr(RqObj, "Icon", Value)
End Property
Property QIMAGE.BMPHandle(ByVal Value As Long)
    RqLclSetInt(RqObj, "BMPHandle", Value)
End Property
Property QIMAGE.ICOHandle(ByVal Value As Long)
    RqLclSetInt(RqObj, "ICOHandle", Value)
End Property
' Pixel(x, y) - цвет точки; Image.Pixel(x, y) = c - препроцессор: SetPixel
Function QIMAGE.Pixel(ByVal X As Long, ByVal Y As Long) As Long
    Return RqCallEx(RqObj, "GetPixel", 0, X, Y, 0, 0, 0)
End Function
Sub QIMAGE.SetPixel(ByVal X As Long, ByVal Y As Long, ByVal PixelColor As Long)
    If RqCallEx(RqObj, "SetPixel", 0, X, Y, PixelColor, 0, 0) = 0 Then RqLclClassError("QIMAGE.Pixel")
End Sub
Sub QIMAGE.DrawInts(ByRef MethodName As String, ByRef Text1 As String, IntList() As Long)
    If RqCallInts(RqObj, MethodName, StrPtr(Text1), @IntList(0), UBound(IntList) + 1) = 0 Then
        RqLclClassError("QIMAGE." & MethodName)
    End If
End Sub
Sub QIMAGE.FillRect(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal FillColor As Long)
    Dim IntList(0 To 4) As Long = {X1, Y1, X2, Y2, FillColor}
    DrawInts("FillRect", "", IntList())
End Sub
' BackColor = -1 - фон прозрачный
Sub QIMAGE.TextOut(ByVal X1 As Long, ByVal Y1 As Long, ByRef Text1 As String, ByVal TextColor As Long, ByVal BackColor As Long = -1)
    Dim IntList(0 To 3) As Long = {X1, Y1, TextColor, BackColor}
    DrawInts("TextOut", Text1, IntList())
End Sub
Sub QIMAGE.Line(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal LineColor As Long)
    Dim IntList(0 To 4) As Long = {X1, Y1, X2, Y2, LineColor}
    DrawInts("Line", "", IntList())
End Sub
Sub QIMAGE.Rectangle(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal LineColor As Long)
    Dim IntList(0 To 4) As Long = {X1, Y1, X2, Y2, LineColor}
    DrawInts("Rectangle", "", IntList())
End Sub
Sub QIMAGE.RoundRect(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal X3 As Long, ByVal Y3 As Long, ByVal FillColor As Long)
    Dim IntList(0 To 6) As Long = {X1, Y1, X2, Y2, X3, Y3, FillColor}
    DrawInts("RoundRect", "", IntList())
End Sub
Sub QIMAGE.Circle(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal LineColor As Long, ByVal FillFlag As Long)
    Dim IntList(0 To 5) As Long = {X1, Y1, X2, Y2, LineColor, FillFlag}
    DrawInts("Circle", "", IntList())
End Sub
Sub QIMAGE.Pset(ByVal X1 As Long, ByVal Y1 As Long, ByVal PixelColor As Long)
    Dim IntList(0 To 2) As Long = {X1, Y1, PixelColor}
    DrawInts("Pset", "", IntList())
End Sub
Sub QIMAGE.Paint(ByVal X1 As Long, ByVal Y1 As Long, ByVal FillColor As Long, ByVal BorderColor As Long)
    Dim IntList(0 To 3) As Long = {X1, Y1, FillColor, BorderColor}
    DrawInts("Paint", "", IntList())
End Sub
' Картинка - файл .bmp или "" (кэш: Image.Draw(0, 0, ImageList.GetBMP(1)))
Sub QIMAGE.Draw(ByVal X1 As Long, ByVal Y1 As Long, ByRef BmpText As String)
    Dim IntList(0 To 1) As Long = {X1, Y1}
    DrawInts("Draw", BmpText, IntList())
End Sub
Sub QIMAGE.StretchDraw(ByRef DstRect As QRECT, ByRef BmpText As String)
    Dim IntList(0 To 3) As Long = {DstRect.Left, DstRect.Top, DstRect.Right, DstRect.Bottom}
    DrawInts("StretchDraw", BmpText, IntList())
End Sub
Sub QIMAGE.TextRect(ByRef ClipRect As QRECT, ByVal X1 As Long, ByVal Y1 As Long, ByRef Text1 As String, ByVal TextColor As Long, ByVal BackColor As Long = -1)
    Dim IntList(0 To 7) As Long = {ClipRect.Left, ClipRect.Top, ClipRect.Right, ClipRect.Bottom, X1, Y1, TextColor, BackColor}
    DrawInts("TextRect", Text1, IntList())
End Sub
Sub QIMAGE.CopyRectPtr(ByRef DstRect As QRECT, ByVal SourcePtr As Any Ptr, ByRef SrcRect As QRECT)
    Dim IntList(0 To 7) As Long = {DstRect.Left, DstRect.Top, DstRect.Right, DstRect.Bottom, _
        SrcRect.Left, SrcRect.Top, SrcRect.Right, SrcRect.Bottom}
    If RqCallObjInts(RqObj, "CopyRect", SourcePtr, @IntList(0), 8) = 0 Then RqLclClassError("QIMAGE.CopyRect")
End Sub
' Source - QIMAGE, QCANVAS, QBITMAP, QFORM (у кого есть холст)
Sub QIMAGE.CopyRect(ByRef DstRect As QRECT, ByRef Source As QCONTROL, ByRef SrcRect As QRECT)
    CopyRectPtr(DstRect, Source.RqObj, SrcRect)
End Sub

' Поворот пока не сделан - ошибка
Sub QIMAGE.Rotate(ByVal X1 As Long, ByVal Y1 As Long, ByVal Angle As Long)
    If RqCallEx(RqObj, "Rotate", 0, X1, Y1, Angle, 0, 0) = 0 Then RqLclClassError("QIMAGE.Rotate")
End Sub
Function QIMAGE.TextWidth(ByRef Text1 As String) As Long
    Return RqCallEx(RqObj, "TextWidth", StrPtr(Text1), 0, 0, 0, 0, 0)
End Function
Function QIMAGE.TextHeight(ByRef Text1 As String) As Long
    Return RqCallEx(RqObj, "TextHeight", StrPtr(Text1), 0, 0, 0, 0, 0)
End Function
Property QIMAGE.OnClick(ByVal Handler As Sub())
    SetEventEx(10, "OnClick", Cast(Any Ptr, Handler), 0)
End Property
Property QIMAGE.OnClick(ByVal Handler As Sub(ByRef Sender As QIMAGE))
    SetEventEx(10, "OnClick", Cast(Any Ptr, Handler), 3)
End Property
Property QIMAGE.OnDblClick(ByVal Handler As Sub())
    SetEventEx(11, "OnDblClick", Cast(Any Ptr, Handler), 0)
End Property
Property QIMAGE.OnDblClick(ByVal Handler As Sub(ByRef Sender As QIMAGE))
    SetEventEx(11, "OnDblClick", Cast(Any Ptr, Handler), 3)
End Property
Property QIMAGE.OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(3, "OnMouseDown", Cast(Any Ptr, Handler), 1)
End Property
Property QIMAGE.OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QIMAGE))
    SetEventEx(3, "OnMouseDown", Cast(Any Ptr, Handler), 2)
End Property
Property QIMAGE.OnMouseDown(ByVal Handler As Sub())
    SetEventEx(3, "OnMouseDown", Cast(Any Ptr, Handler), 0)
End Property
Property QIMAGE.OnMouseDown(ByVal Handler As Sub(ByRef Sender As QIMAGE))
    SetEventEx(3, "OnMouseDown", Cast(Any Ptr, Handler), 3)
End Property
Property QIMAGE.OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(4, "OnMouseUp", Cast(Any Ptr, Handler), 1)
End Property
Property QIMAGE.OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QIMAGE))
    SetEventEx(4, "OnMouseUp", Cast(Any Ptr, Handler), 2)
End Property
Property QIMAGE.OnMouseUp(ByVal Handler As Sub())
    SetEventEx(4, "OnMouseUp", Cast(Any Ptr, Handler), 0)
End Property
Property QIMAGE.OnMouseUp(ByVal Handler As Sub(ByRef Sender As QIMAGE))
    SetEventEx(4, "OnMouseUp", Cast(Any Ptr, Handler), 3)
End Property
Property QIMAGE.OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(5, "OnMouseMove", Cast(Any Ptr, Handler), 1)
End Property
Property QIMAGE.OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QIMAGE))
    SetEventEx(5, "OnMouseMove", Cast(Any Ptr, Handler), 2)
End Property
Property QIMAGE.OnMouseMove(ByVal Handler As Sub())
    SetEventEx(5, "OnMouseMove", Cast(Any Ptr, Handler), 0)
End Property
Property QIMAGE.OnMouseMove(ByVal Handler As Sub(ByRef Sender As QIMAGE))
    SetEventEx(5, "OnMouseMove", Cast(Any Ptr, Handler), 3)
End Property

' ---------------------------------------------------------------------------
'  QIMAGELIST - набор картинок одного размера (TImageList); Width / Height -
'  размер (смена очищает набор), Masked - прозрачность по MaskColor;
'  DrawingStyle 0 dsFocus, 1 dsSelected, 2 dsNormal, 3 dsTransparent
' ---------------------------------------------------------------------------

Type QIMAGELIST
    RqObj As Any Ptr
    Declare Constructor()
    Declare Property BkColor() As Long
    Declare Property BkColor(ByVal Value As Long)
    Declare Property BlendColor() As Long
    Declare Property BlendColor(ByVal Value As Long)
    Declare Property DrawingStyle() As Long
    Declare Property DrawingStyle(ByVal Value As Long)
    Declare Property Height() As Long
    Declare Property Height(ByVal Value As Long)
    Declare Property ImageType() As Long
    Declare Property ImageType(ByVal Value As Long)
    Declare Property Masked() As Long
    Declare Property Masked(ByVal Value As Long)
    Declare Property Width() As Long
    Declare Property Width(ByVal Value As Long)
    Declare Property Count() As Long
    Declare Sub ListCall(ByRef MethodName As String, ByRef Text1 As String, ByVal IntArg1 As Long = 0, ByVal IntArg2 As Long = 0, ByVal IntArg3 As Long = 0)
    Declare Sub AddBMPFile(ByRef FileName As String, ByVal MaskColor As Long = 0)
    Declare Sub AddICOFile(ByRef FileName As String)
    Declare Sub AddBMPHandle(ByVal ResHandle As Long, ByVal MaskColor As Long = 0)
    Declare Sub AddICOHandle(ByVal ResHandle As Long)
    Declare Sub InsertBMPFile(ByVal ItemNum As Long, ByRef FileName As String, ByVal MaskColor As Long = 0)
    Declare Sub InsertICOFile(ByVal ItemNum As Long, ByRef FileName As String)
    Declare Sub InsertBMPHandle(ByVal ItemNum As Long, ByVal ResHandle As Long, ByVal MaskColor As Long = 0)
    Declare Sub InsertICOHandle(ByVal ItemNum As Long, ByVal ResHandle As Long)
    Declare Sub Clear()
    ' Delete - слово FreeBASIC; препроцессор: List.Delete -> List.Delete_v
    Declare Sub Delete_v(ByVal ItemNum As Long)
    Declare Function GetBMP(ByVal ItemNum As Long) As String
    Declare Function GetICO(ByVal ItemNum As Long) As String
    Declare Sub DrawPtr(ByVal TargetPtr As Any Ptr, ByVal X As Long, ByVal Y As Long, ByVal ItemNum As Long)
    Declare Sub Draw(ByRef Target As QCONTROL, ByVal X As Long, ByVal Y As Long, ByVal ItemNum As Long)
End Type

Constructor QIMAGELIST()
    RqObj = RqLclNew("QIMAGELIST", @This)
End Constructor
Property QIMAGELIST.BkColor() As Long
    Return RqGetInt(RqObj, "BkColor")
End Property
Property QIMAGELIST.BkColor(ByVal Value As Long)
    RqLclSetInt(RqObj, "BkColor", Value)
End Property
Property QIMAGELIST.BlendColor() As Long
    Return RqGetInt(RqObj, "BlendColor")
End Property
Property QIMAGELIST.BlendColor(ByVal Value As Long)
    RqLclSetInt(RqObj, "BlendColor", Value)
End Property
Property QIMAGELIST.DrawingStyle() As Long
    Return RqGetInt(RqObj, "DrawingStyle")
End Property
Property QIMAGELIST.DrawingStyle(ByVal Value As Long)
    RqLclSetInt(RqObj, "DrawingStyle", Value)
End Property
Property QIMAGELIST.Height() As Long
    Return RqGetInt(RqObj, "Height")
End Property
Property QIMAGELIST.Height(ByVal Value As Long)
    RqLclSetInt(RqObj, "Height", Value)
End Property
Property QIMAGELIST.ImageType() As Long
    Return RqGetInt(RqObj, "ImageType")
End Property
Property QIMAGELIST.ImageType(ByVal Value As Long)
    RqLclSetInt(RqObj, "ImageType", Value)
End Property
Property QIMAGELIST.Masked() As Long
    Return RqGetInt(RqObj, "Masked")
End Property
Property QIMAGELIST.Masked(ByVal Value As Long)
    RqLclSetInt(RqObj, "Masked", Value)
End Property
Property QIMAGELIST.Width() As Long
    Return RqGetInt(RqObj, "Width")
End Property
Property QIMAGELIST.Width(ByVal Value As Long)
    RqLclSetInt(RqObj, "Width", Value)
End Property
Property QIMAGELIST.Count() As Long
    Return RqGetInt(RqObj, "Count")
End Property
Sub QIMAGELIST.ListCall(ByRef MethodName As String, ByRef Text1 As String, ByVal IntArg1 As Long = 0, ByVal IntArg2 As Long = 0, ByVal IntArg3 As Long = 0)
    If RqCallEx(RqObj, MethodName, StrPtr(Text1), IntArg1, IntArg2, IntArg3, 0, 0) = 0 Then
        RqLclClassError("QIMAGELIST." & MethodName)
    End If
End Sub
' MaskColor - прозрачный цвет картинки (при Masked = 1)
Sub QIMAGELIST.AddBMPFile(ByRef FileName As String, ByVal MaskColor As Long = 0)
    ListCall("AddBMPFile", FileName, 0, 0, MaskColor)
End Sub
Sub QIMAGELIST.AddICOFile(ByRef FileName As String)
    ListCall("AddICOFile", FileName)
End Sub
Sub QIMAGELIST.AddBMPHandle(ByVal ResHandle As Long, ByVal MaskColor As Long = 0)
    ListCall("AddBMPHandle", "", 0, ResHandle, MaskColor)
End Sub
Sub QIMAGELIST.AddICOHandle(ByVal ResHandle As Long)
    ListCall("AddICOHandle", "", 0, ResHandle)
End Sub
Sub QIMAGELIST.InsertBMPFile(ByVal ItemNum As Long, ByRef FileName As String, ByVal MaskColor As Long = 0)
    ListCall("InsertBMPFile", FileName, ItemNum, 0, MaskColor)
End Sub
Sub QIMAGELIST.InsertICOFile(ByVal ItemNum As Long, ByRef FileName As String)
    ListCall("InsertICOFile", FileName, ItemNum)
End Sub
Sub QIMAGELIST.InsertBMPHandle(ByVal ItemNum As Long, ByVal ResHandle As Long, ByVal MaskColor As Long = 0)
    ListCall("InsertBMPHandle", "", ItemNum, ResHandle, MaskColor)
End Sub
Sub QIMAGELIST.InsertICOHandle(ByVal ItemNum As Long, ByVal ResHandle As Long)
    ListCall("InsertICOHandle", "", ItemNum, ResHandle)
End Sub
Sub QIMAGELIST.Clear()
    ListCall("Clear", "")
End Sub
Sub QIMAGELIST.Delete_v(ByVal ItemNum As Long)
    ListCall("Delete", "", ItemNum)
End Sub
' Картинка - в кэш, результат "" (Button.BMP = List.GetBMP(0))
Function QIMAGELIST.GetBMP(ByVal ItemNum As Long) As String
    ListCall("GetBMP", "", ItemNum)
    Return ""
End Function
Function QIMAGELIST.GetICO(ByVal ItemNum As Long) As String
    ListCall("GetICO", "", ItemNum)
    Return ""
End Function
Sub QIMAGELIST.DrawPtr(ByVal TargetPtr As Any Ptr, ByVal X As Long, ByVal Y As Long, ByVal ItemNum As Long)
    Dim IntList(0 To 2) As Long = {X, Y, ItemNum}
    If RqCallObjInts(RqObj, "Draw", TargetPtr, @IntList(0), 3) = 0 Then RqLclClassError("QIMAGELIST.Draw")
End Sub
' Target - QIMAGE, QCANVAS, QBITMAP, QFORM (у кого есть холст)
Sub QIMAGELIST.Draw(ByRef Target As QCONTROL, ByVal X As Long, ByVal Y As Long, ByVal ItemNum As Long)
    DrawPtr(Target.RqObj, X, Y, ItemNum)
End Sub
