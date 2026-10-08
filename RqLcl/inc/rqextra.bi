' ---------------------------------------------------------------------------
'  RqLcl: QCANVAS, QSCROLLBAR, QTRACKBAR, QSCROLLBOX, QOVALBTN, QOUTLINE,
'  QHEADER, глобальный Printer, тип QNOTIFYICONDATA. Подключается из
'  rqlcl.bi.
'
'  Рисование (FillRect, TextOut, Draw, CopyRect...) - как у QIMAGE;
'  CopyMode - номер RapidQ (cmBlackness 0 ... cmSrcCopy 10 ... cmWhiteness 14).
' ---------------------------------------------------------------------------

' ---------------------------------------------------------------------------
'  QCANVAS - пустое место для рисования (TPaintBox); рисовать - в OnPaint
'  (или в любой момент: нарисованное держится до перерисовки окна)
' ---------------------------------------------------------------------------

Type QCANVAS Extends QCONTROL
    Declare Constructor()
    Declare Property CopyMode() As Long
    Declare Property CopyMode(ByVal Value As Long)
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
    Declare Sub CopyRect Overload (ByRef DstRect As QRECT, ByRef Source As QCONTROL, ByRef SrcRect As QRECT)
    Declare Sub Rotate(ByVal X1 As Long, ByVal Y1 As Long, ByVal Angle As Long)
    Declare Function TextWidth(ByRef Text1 As String) As Long
    Declare Function TextHeight(ByRef Text1 As String) As Long
    Declare Property OnClick(ByVal Handler As Sub())
    Declare Property OnClick(ByVal Handler As Sub(ByRef Sender As QCANVAS))
    Declare Property OnDblClick(ByVal Handler As Sub())
    Declare Property OnDblClick(ByVal Handler As Sub(ByRef Sender As QCANVAS))
    Declare Property OnPaint(ByVal Handler As Sub())
    Declare Property OnPaint(ByVal Handler As Sub(ByRef Sender As QCANVAS))
    Declare Property OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QCANVAS))
    Declare Property OnMouseDown(ByVal Handler As Sub())
    Declare Property OnMouseDown(ByVal Handler As Sub(ByRef Sender As QCANVAS))
    Declare Property OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QCANVAS))
    Declare Property OnMouseUp(ByVal Handler As Sub())
    Declare Property OnMouseUp(ByVal Handler As Sub(ByRef Sender As QCANVAS))
    Declare Property OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QCANVAS))
    Declare Property OnMouseMove(ByVal Handler As Sub())
    Declare Property OnMouseMove(ByVal Handler As Sub(ByRef Sender As QCANVAS))
End Type

Constructor QCANVAS()
    RqObj = RqLclNew("QCANVAS", @This)
End Constructor
Property QCANVAS.CopyMode() As Long
    Return RqGetInt(RqObj, "CopyMode")
End Property
Property QCANVAS.CopyMode(ByVal Value As Long)
    RqLclSetInt(RqObj, "CopyMode", Value)
End Property
' Pixel(x, y) - цвет точки; Obj.Pixel(x, y) = c - препроцессор: SetPixel
Function QCANVAS.Pixel(ByVal X As Long, ByVal Y As Long) As Long
    Return RqCallEx(RqObj, "GetPixel", 0, X, Y, 0, 0, 0)
End Function
Sub QCANVAS.SetPixel(ByVal X As Long, ByVal Y As Long, ByVal PixelColor As Long)
    If RqCallEx(RqObj, "SetPixel", 0, X, Y, PixelColor, 0, 0) = 0 Then RqLclClassError("QCANVAS.Pixel")
End Sub
Sub QCANVAS.DrawInts(ByRef MethodName As String, ByRef Text1 As String, IntList() As Long)
    If RqCallInts(RqObj, MethodName, StrPtr(Text1), @IntList(0), UBound(IntList) + 1) = 0 Then
        RqLclClassError("QCANVAS." & MethodName)
    End If
End Sub
' BackColor = -1 - фон прозрачный
Sub QCANVAS.TextOut(ByVal X1 As Long, ByVal Y1 As Long, ByRef Text1 As String, ByVal TextColor As Long, ByVal BackColor As Long = -1)
    Dim IntList(0 To 3) As Long = {X1, Y1, TextColor, BackColor}
    DrawInts("TextOut", Text1, IntList())
End Sub
Sub QCANVAS.FillRect(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal FillColor As Long)
    Dim IntList(0 To 4) As Long = {X1, Y1, X2, Y2, FillColor}
    DrawInts("FillRect", "", IntList())
End Sub
Sub QCANVAS.Line(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal LineColor As Long)
    Dim IntList(0 To 4) As Long = {X1, Y1, X2, Y2, LineColor}
    DrawInts("Line", "", IntList())
End Sub
Sub QCANVAS.Rectangle(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal LineColor As Long)
    Dim IntList(0 To 4) As Long = {X1, Y1, X2, Y2, LineColor}
    DrawInts("Rectangle", "", IntList())
End Sub
Sub QCANVAS.RoundRect(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal X3 As Long, ByVal Y3 As Long, ByVal FillColor As Long)
    Dim IntList(0 To 6) As Long = {X1, Y1, X2, Y2, X3, Y3, FillColor}
    DrawInts("RoundRect", "", IntList())
End Sub
Sub QCANVAS.Circle(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal LineColor As Long, ByVal FillFlag As Long)
    Dim IntList(0 To 5) As Long = {X1, Y1, X2, Y2, LineColor, FillFlag}
    DrawInts("Circle", "", IntList())
End Sub
Sub QCANVAS.Pset(ByVal X1 As Long, ByVal Y1 As Long, ByVal PixelColor As Long)
    Dim IntList(0 To 2) As Long = {X1, Y1, PixelColor}
    DrawInts("Pset", "", IntList())
End Sub
Sub QCANVAS.Paint(ByVal X1 As Long, ByVal Y1 As Long, ByVal FillColor As Long, ByVal BorderColor As Long)
    Dim IntList(0 To 3) As Long = {X1, Y1, FillColor, BorderColor}
    DrawInts("Paint", "", IntList())
End Sub
' Картинка - файл .bmp или "" (кэш: Obj.Draw(0, 0, Bitmap.BMP))
Sub QCANVAS.Draw(ByVal X1 As Long, ByVal Y1 As Long, ByRef BmpText As String)
    Dim IntList(0 To 1) As Long = {X1, Y1}
    DrawInts("Draw", BmpText, IntList())
End Sub
Sub QCANVAS.StretchDraw(ByRef DstRect As QRECT, ByRef BmpText As String)
    Dim IntList(0 To 3) As Long = {DstRect.Left, DstRect.Top, DstRect.Right, DstRect.Bottom}
    DrawInts("StretchDraw", BmpText, IntList())
End Sub
Sub QCANVAS.TextRect(ByRef ClipRect As QRECT, ByVal X1 As Long, ByVal Y1 As Long, ByRef Text1 As String, ByVal TextColor As Long, ByVal BackColor As Long = -1)
    Dim IntList(0 To 7) As Long = {ClipRect.Left, ClipRect.Top, ClipRect.Right, ClipRect.Bottom, X1, Y1, TextColor, BackColor}
    DrawInts("TextRect", Text1, IntList())
End Sub
Sub QCANVAS.CopyRectPtr(ByRef DstRect As QRECT, ByVal SourcePtr As Any Ptr, ByRef SrcRect As QRECT)
    Dim IntList(0 To 7) As Long = {DstRect.Left, DstRect.Top, DstRect.Right, DstRect.Bottom, _
        SrcRect.Left, SrcRect.Top, SrcRect.Right, SrcRect.Bottom}
    If RqCallObjInts(RqObj, "CopyRect", SourcePtr, @IntList(0), 8) = 0 Then RqLclClassError("QCANVAS.CopyRect")
End Sub
' Source - QIMAGE, QCANVAS, QBITMAP, QFORM (у кого есть холст)
Sub QCANVAS.CopyRect(ByRef DstRect As QRECT, ByRef Source As QCONTROL, ByRef SrcRect As QRECT)
    CopyRectPtr(DstRect, Source.RqObj, SrcRect)
End Sub
' Поворот пока не сделан - ошибка
Sub QCANVAS.Rotate(ByVal X1 As Long, ByVal Y1 As Long, ByVal Angle As Long)
    If RqCallEx(RqObj, "Rotate", 0, X1, Y1, Angle, 0, 0) = 0 Then RqLclClassError("QCANVAS.Rotate")
End Sub
Function QCANVAS.TextWidth(ByRef Text1 As String) As Long
    Return RqCallEx(RqObj, "TextWidth", StrPtr(Text1), 0, 0, 0, 0, 0)
End Function
Function QCANVAS.TextHeight(ByRef Text1 As String) As Long
    Return RqCallEx(RqObj, "TextHeight", StrPtr(Text1), 0, 0, 0, 0, 0)
End Function
Property QCANVAS.OnClick(ByVal Handler As Sub())
    SetEventEx(10, "OnClick", Cast(Any Ptr, Handler), 0)
End Property
Property QCANVAS.OnClick(ByVal Handler As Sub(ByRef Sender As QCANVAS))
    SetEventEx(10, "OnClick", Cast(Any Ptr, Handler), 3)
End Property
Property QCANVAS.OnDblClick(ByVal Handler As Sub())
    SetEventEx(11, "OnDblClick", Cast(Any Ptr, Handler), 0)
End Property
Property QCANVAS.OnDblClick(ByVal Handler As Sub(ByRef Sender As QCANVAS))
    SetEventEx(11, "OnDblClick", Cast(Any Ptr, Handler), 3)
End Property
Property QCANVAS.OnPaint(ByVal Handler As Sub())
    SetEventEx(25, "OnPaint", Cast(Any Ptr, Handler), 0)
End Property
Property QCANVAS.OnPaint(ByVal Handler As Sub(ByRef Sender As QCANVAS))
    SetEventEx(25, "OnPaint", Cast(Any Ptr, Handler), 3)
End Property
Property QCANVAS.OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(3, "OnMouseDown", Cast(Any Ptr, Handler), 1)
End Property
Property QCANVAS.OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QCANVAS))
    SetEventEx(3, "OnMouseDown", Cast(Any Ptr, Handler), 2)
End Property
Property QCANVAS.OnMouseDown(ByVal Handler As Sub())
    SetEventEx(3, "OnMouseDown", Cast(Any Ptr, Handler), 0)
End Property
Property QCANVAS.OnMouseDown(ByVal Handler As Sub(ByRef Sender As QCANVAS))
    SetEventEx(3, "OnMouseDown", Cast(Any Ptr, Handler), 3)
End Property
Property QCANVAS.OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(4, "OnMouseUp", Cast(Any Ptr, Handler), 1)
End Property
Property QCANVAS.OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QCANVAS))
    SetEventEx(4, "OnMouseUp", Cast(Any Ptr, Handler), 2)
End Property
Property QCANVAS.OnMouseUp(ByVal Handler As Sub())
    SetEventEx(4, "OnMouseUp", Cast(Any Ptr, Handler), 0)
End Property
Property QCANVAS.OnMouseUp(ByVal Handler As Sub(ByRef Sender As QCANVAS))
    SetEventEx(4, "OnMouseUp", Cast(Any Ptr, Handler), 3)
End Property
Property QCANVAS.OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(5, "OnMouseMove", Cast(Any Ptr, Handler), 1)
End Property
Property QCANVAS.OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QCANVAS))
    SetEventEx(5, "OnMouseMove", Cast(Any Ptr, Handler), 2)
End Property
Property QCANVAS.OnMouseMove(ByVal Handler As Sub())
    SetEventEx(5, "OnMouseMove", Cast(Any Ptr, Handler), 0)
End Property
Property QCANVAS.OnMouseMove(ByVal Handler As Sub(ByRef Sender As QCANVAS))
    SetEventEx(5, "OnMouseMove", Cast(Any Ptr, Handler), 3)
End Property

' ---------------------------------------------------------------------------
'  QSCROLLBAR - полоса прокрутки (TScrollBar); Kind 0 sbHorizontal,
'  1 sbVertical; OnScroll (ScrollCode, ScrollPos): scLineUp 0, scLineDown 1,
'  scPageUp 2, scPageDown 3, scPosition 4, scTrack 5, scTop 6, scBottom 7,
'  scEndScroll 8
' ---------------------------------------------------------------------------

Type QSCROLLBAR Extends QCONTROL
    Declare Constructor()
    Declare Property Kind() As Long
    Declare Property Kind(ByVal Value As Long)
    Declare Property LargeChange() As Long
    Declare Property LargeChange(ByVal Value As Long)
    Declare Property Max() As Long
    Declare Property Max(ByVal Value As Long)
    Declare Property Min() As Long
    Declare Property Min(ByVal Value As Long)
    Declare Property PageSize() As Long
    Declare Property PageSize(ByVal Value As Long)
    Declare Property Position() As Long
    Declare Property Position(ByVal Value As Long)
    Declare Property SmallChange() As Long
    Declare Property SmallChange(ByVal Value As Long)
    Declare Property OnChange(ByVal Handler As Sub())
    Declare Property OnChange(ByVal Handler As Sub(ByRef Sender As QSCROLLBAR))
    Declare Property OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    Declare Property OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QSCROLLBAR))
    Declare Property OnKeyDown(ByVal Handler As Sub())
    Declare Property OnKeyDown(ByVal Handler As Sub(ByRef Sender As QSCROLLBAR))
    Declare Property OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    Declare Property OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QSCROLLBAR))
    Declare Property OnKeyUp(ByVal Handler As Sub())
    Declare Property OnKeyUp(ByVal Handler As Sub(ByRef Sender As QSCROLLBAR))
    Declare Property OnKeyPress(ByVal Handler As Sub(ByRef Key As Long))
    Declare Property OnKeyPress(ByVal Handler As Sub(ByRef Key As Long, ByRef Sender As QSCROLLBAR))
    Declare Property OnKeyPress(ByVal Handler As Sub())
    Declare Property OnKeyPress(ByVal Handler As Sub(ByRef Sender As QSCROLLBAR))
    Declare Property OnScroll(ByVal Handler As Sub(ByVal ScrollCode As Long, ByVal ScrollPos As Long))
    Declare Property OnScroll(ByVal Handler As Sub(ByVal ScrollCode As Long, ByVal ScrollPos As Long, ByRef Sender As QSCROLLBAR))
    Declare Property OnScroll(ByVal Handler As Sub())
    Declare Property OnScroll(ByVal Handler As Sub(ByRef Sender As QSCROLLBAR))
End Type

Constructor QSCROLLBAR()
    RqObj = RqLclNew("QSCROLLBAR", @This)
End Constructor
Property QSCROLLBAR.Kind() As Long
    Return RqGetInt(RqObj, "Kind")
End Property
Property QSCROLLBAR.Kind(ByVal Value As Long)
    RqLclSetInt(RqObj, "Kind", Value)
End Property
Property QSCROLLBAR.LargeChange() As Long
    Return RqGetInt(RqObj, "LargeChange")
End Property
Property QSCROLLBAR.LargeChange(ByVal Value As Long)
    RqLclSetInt(RqObj, "LargeChange", Value)
End Property
Property QSCROLLBAR.Max() As Long
    Return RqGetInt(RqObj, "Max")
End Property
Property QSCROLLBAR.Max(ByVal Value As Long)
    RqLclSetInt(RqObj, "Max", Value)
End Property
Property QSCROLLBAR.Min() As Long
    Return RqGetInt(RqObj, "Min")
End Property
Property QSCROLLBAR.Min(ByVal Value As Long)
    RqLclSetInt(RqObj, "Min", Value)
End Property
Property QSCROLLBAR.PageSize() As Long
    Return RqGetInt(RqObj, "PageSize")
End Property
Property QSCROLLBAR.PageSize(ByVal Value As Long)
    RqLclSetInt(RqObj, "PageSize", Value)
End Property
Property QSCROLLBAR.Position() As Long
    Return RqGetInt(RqObj, "Position")
End Property
Property QSCROLLBAR.Position(ByVal Value As Long)
    RqLclSetInt(RqObj, "Position", Value)
End Property
Property QSCROLLBAR.SmallChange() As Long
    Return RqGetInt(RqObj, "SmallChange")
End Property
Property QSCROLLBAR.SmallChange(ByVal Value As Long)
    RqLclSetInt(RqObj, "SmallChange", Value)
End Property
Property QSCROLLBAR.OnChange(ByVal Handler As Sub())
    SetEventEx(12, "OnChange", Cast(Any Ptr, Handler), 0)
End Property
Property QSCROLLBAR.OnChange(ByVal Handler As Sub(ByRef Sender As QSCROLLBAR))
    SetEventEx(12, "OnChange", Cast(Any Ptr, Handler), 3)
End Property
Property QSCROLLBAR.OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    SetEventEx(0, "OnKeyDown", Cast(Any Ptr, Handler), 1)
End Property
Property QSCROLLBAR.OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QSCROLLBAR))
    SetEventEx(0, "OnKeyDown", Cast(Any Ptr, Handler), 2)
End Property
Property QSCROLLBAR.OnKeyDown(ByVal Handler As Sub())
    SetEventEx(0, "OnKeyDown", Cast(Any Ptr, Handler), 0)
End Property
Property QSCROLLBAR.OnKeyDown(ByVal Handler As Sub(ByRef Sender As QSCROLLBAR))
    SetEventEx(0, "OnKeyDown", Cast(Any Ptr, Handler), 3)
End Property
Property QSCROLLBAR.OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    SetEventEx(1, "OnKeyUp", Cast(Any Ptr, Handler), 1)
End Property
Property QSCROLLBAR.OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QSCROLLBAR))
    SetEventEx(1, "OnKeyUp", Cast(Any Ptr, Handler), 2)
End Property
Property QSCROLLBAR.OnKeyUp(ByVal Handler As Sub())
    SetEventEx(1, "OnKeyUp", Cast(Any Ptr, Handler), 0)
End Property
Property QSCROLLBAR.OnKeyUp(ByVal Handler As Sub(ByRef Sender As QSCROLLBAR))
    SetEventEx(1, "OnKeyUp", Cast(Any Ptr, Handler), 3)
End Property
Property QSCROLLBAR.OnKeyPress(ByVal Handler As Sub(ByRef Key As Long))
    SetEventEx(2, "OnKeyPress", Cast(Any Ptr, Handler), 1)
End Property
Property QSCROLLBAR.OnKeyPress(ByVal Handler As Sub(ByRef Key As Long, ByRef Sender As QSCROLLBAR))
    SetEventEx(2, "OnKeyPress", Cast(Any Ptr, Handler), 2)
End Property
Property QSCROLLBAR.OnKeyPress(ByVal Handler As Sub())
    SetEventEx(2, "OnKeyPress", Cast(Any Ptr, Handler), 0)
End Property
Property QSCROLLBAR.OnKeyPress(ByVal Handler As Sub(ByRef Sender As QSCROLLBAR))
    SetEventEx(2, "OnKeyPress", Cast(Any Ptr, Handler), 3)
End Property
Property QSCROLLBAR.OnScroll(ByVal Handler As Sub(ByVal ScrollCode As Long, ByVal ScrollPos As Long))
    SetEventEx(24, "OnScroll", Cast(Any Ptr, Handler), 1)
End Property
Property QSCROLLBAR.OnScroll(ByVal Handler As Sub(ByVal ScrollCode As Long, ByVal ScrollPos As Long, ByRef Sender As QSCROLLBAR))
    SetEventEx(24, "OnScroll", Cast(Any Ptr, Handler), 2)
End Property
Property QSCROLLBAR.OnScroll(ByVal Handler As Sub())
    SetEventEx(24, "OnScroll", Cast(Any Ptr, Handler), 0)
End Property
Property QSCROLLBAR.OnScroll(ByVal Handler As Sub(ByRef Sender As QSCROLLBAR))
    SetEventEx(24, "OnScroll", Cast(Any Ptr, Handler), 3)
End Property

' ---------------------------------------------------------------------------
'  QTRACKBAR - ползунок (TTrackBar); Orientation 0 гориз., 1 верт.;
'  TickMarks 0 tmBottomRight, 1 tmTopLeft, 2 tmBoth; TickStyle 0 tsNone,
'  1 tsAuto, 2 tsManual (риски - SetTick)
' ---------------------------------------------------------------------------

Type QTRACKBAR Extends QCONTROL
    Declare Constructor()
    Declare Property Frequency() As Long
    Declare Property Frequency(ByVal Value As Long)
    Declare Property LineSize() As Long
    Declare Property LineSize(ByVal Value As Long)
    Declare Property Max() As Long
    Declare Property Max(ByVal Value As Long)
    Declare Property Min() As Long
    Declare Property Min(ByVal Value As Long)
    Declare Property Orientation() As Long
    Declare Property Orientation(ByVal Value As Long)
    Declare Property PageSize() As Long
    Declare Property PageSize(ByVal Value As Long)
    Declare Property Position() As Long
    Declare Property Position(ByVal Value As Long)
    Declare Property SelEnd() As Long
    Declare Property SelEnd(ByVal Value As Long)
    Declare Property SelStart() As Long
    Declare Property SelStart(ByVal Value As Long)
    Declare Property TickMarks() As Long
    Declare Property TickMarks(ByVal Value As Long)
    Declare Property TickStyle() As Long
    Declare Property TickStyle(ByVal Value As Long)
    Declare Sub SetTick(ByVal TickPos As Long)
    Declare Property OnChange(ByVal Handler As Sub())
    Declare Property OnChange(ByVal Handler As Sub(ByRef Sender As QTRACKBAR))
End Type

Constructor QTRACKBAR()
    RqObj = RqLclNew("QTRACKBAR", @This)
End Constructor
Property QTRACKBAR.Frequency() As Long
    Return RqGetInt(RqObj, "Frequency")
End Property
Property QTRACKBAR.Frequency(ByVal Value As Long)
    RqLclSetInt(RqObj, "Frequency", Value)
End Property
Property QTRACKBAR.LineSize() As Long
    Return RqGetInt(RqObj, "LineSize")
End Property
Property QTRACKBAR.LineSize(ByVal Value As Long)
    RqLclSetInt(RqObj, "LineSize", Value)
End Property
Property QTRACKBAR.Max() As Long
    Return RqGetInt(RqObj, "Max")
End Property
Property QTRACKBAR.Max(ByVal Value As Long)
    RqLclSetInt(RqObj, "Max", Value)
End Property
Property QTRACKBAR.Min() As Long
    Return RqGetInt(RqObj, "Min")
End Property
Property QTRACKBAR.Min(ByVal Value As Long)
    RqLclSetInt(RqObj, "Min", Value)
End Property
Property QTRACKBAR.Orientation() As Long
    Return RqGetInt(RqObj, "Orientation")
End Property
Property QTRACKBAR.Orientation(ByVal Value As Long)
    RqLclSetInt(RqObj, "Orientation", Value)
End Property
Property QTRACKBAR.PageSize() As Long
    Return RqGetInt(RqObj, "PageSize")
End Property
Property QTRACKBAR.PageSize(ByVal Value As Long)
    RqLclSetInt(RqObj, "PageSize", Value)
End Property
Property QTRACKBAR.Position() As Long
    Return RqGetInt(RqObj, "Position")
End Property
Property QTRACKBAR.Position(ByVal Value As Long)
    RqLclSetInt(RqObj, "Position", Value)
End Property
Property QTRACKBAR.SelEnd() As Long
    Return RqGetInt(RqObj, "SelEnd")
End Property
Property QTRACKBAR.SelEnd(ByVal Value As Long)
    RqLclSetInt(RqObj, "SelEnd", Value)
End Property
Property QTRACKBAR.SelStart() As Long
    Return RqGetInt(RqObj, "SelStart")
End Property
Property QTRACKBAR.SelStart(ByVal Value As Long)
    RqLclSetInt(RqObj, "SelStart", Value)
End Property
Property QTRACKBAR.TickMarks() As Long
    Return RqGetInt(RqObj, "TickMarks")
End Property
Property QTRACKBAR.TickMarks(ByVal Value As Long)
    RqLclSetInt(RqObj, "TickMarks", Value)
End Property
Property QTRACKBAR.TickStyle() As Long
    Return RqGetInt(RqObj, "TickStyle")
End Property
Property QTRACKBAR.TickStyle(ByVal Value As Long)
    RqLclSetInt(RqObj, "TickStyle", Value)
End Property
Sub QTRACKBAR.SetTick(ByVal TickPos As Long)
    Dim CallText As String = ""
    If RqCallEx(RqObj, "SetTick", StrPtr(CallText), TickPos, 0, 0, 0, 0) = 0 Then RqLclClassError("QTRACKBAR.SetTick")
End Sub
Property QTRACKBAR.OnChange(ByVal Handler As Sub())
    SetEventEx(12, "OnChange", Cast(Any Ptr, Handler), 0)
End Property
Property QTRACKBAR.OnChange(ByVal Handler As Sub(ByRef Sender As QTRACKBAR))
    SetEventEx(12, "OnChange", Cast(Any Ptr, Handler), 3)
End Property

' ---------------------------------------------------------------------------
'  QSCROLLBOX - область с прокруткой (TScrollBox); элементы внутри -
'  Parent = ScrollBox. HorzMargin / VertMargin в LCL нет: читаются как 0,
'  запись не действует
' ---------------------------------------------------------------------------

Type QSCROLLBOX Extends QCONTROL
    Declare Constructor()
    Declare Property AutoScroll() As Long
    Declare Property AutoScroll(ByVal Value As Long)
    Declare Property BorderStyle() As Long
    Declare Property BorderStyle(ByVal Value As Long)
    Declare Property HorzIncrement() As Long
    Declare Property HorzIncrement(ByVal Value As Long)
    Declare Property HorzMargin() As Long
    Declare Property HorzMargin(ByVal Value As Long)
    Declare Property HorzPosition() As Long
    Declare Property HorzPosition(ByVal Value As Long)
    Declare Property HorzRange() As Long
    Declare Property HorzRange(ByVal Value As Long)
    Declare Property HorzTracking() As Long
    Declare Property HorzTracking(ByVal Value As Long)
    Declare Property HorzVisible() As Long
    Declare Property HorzVisible(ByVal Value As Long)
    Declare Property VertIncrement() As Long
    Declare Property VertIncrement(ByVal Value As Long)
    Declare Property VertMargin() As Long
    Declare Property VertMargin(ByVal Value As Long)
    Declare Property VertPosition() As Long
    Declare Property VertPosition(ByVal Value As Long)
    Declare Property VertRange() As Long
    Declare Property VertRange(ByVal Value As Long)
    Declare Property VertTracking() As Long
    Declare Property VertTracking(ByVal Value As Long)
    Declare Property VertVisible() As Long
    Declare Property VertVisible(ByVal Value As Long)
    Declare Property OnClick(ByVal Handler As Sub())
    Declare Property OnClick(ByVal Handler As Sub(ByRef Sender As QSCROLLBOX))
    Declare Property OnDblClick(ByVal Handler As Sub())
    Declare Property OnDblClick(ByVal Handler As Sub(ByRef Sender As QSCROLLBOX))
    Declare Property OnResize(ByVal Handler As Sub())
    Declare Property OnResize(ByVal Handler As Sub(ByRef Sender As QSCROLLBOX))
    Declare Property OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QSCROLLBOX))
    Declare Property OnMouseDown(ByVal Handler As Sub())
    Declare Property OnMouseDown(ByVal Handler As Sub(ByRef Sender As QSCROLLBOX))
    Declare Property OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QSCROLLBOX))
    Declare Property OnMouseUp(ByVal Handler As Sub())
    Declare Property OnMouseUp(ByVal Handler As Sub(ByRef Sender As QSCROLLBOX))
    Declare Property OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QSCROLLBOX))
    Declare Property OnMouseMove(ByVal Handler As Sub())
    Declare Property OnMouseMove(ByVal Handler As Sub(ByRef Sender As QSCROLLBOX))
End Type

Constructor QSCROLLBOX()
    RqObj = RqLclNew("QSCROLLBOX", @This)
End Constructor
Property QSCROLLBOX.AutoScroll() As Long
    Return RqGetInt(RqObj, "AutoScroll")
End Property
Property QSCROLLBOX.AutoScroll(ByVal Value As Long)
    RqLclSetInt(RqObj, "AutoScroll", Value)
End Property
Property QSCROLLBOX.BorderStyle() As Long
    Return RqGetInt(RqObj, "BorderStyle")
End Property
Property QSCROLLBOX.BorderStyle(ByVal Value As Long)
    RqLclSetInt(RqObj, "BorderStyle", Value)
End Property
Property QSCROLLBOX.HorzIncrement() As Long
    Return RqGetInt(RqObj, "HorzIncrement")
End Property
Property QSCROLLBOX.HorzIncrement(ByVal Value As Long)
    RqLclSetInt(RqObj, "HorzIncrement", Value)
End Property
Property QSCROLLBOX.HorzMargin() As Long
    Return RqGetInt(RqObj, "HorzMargin")
End Property
Property QSCROLLBOX.HorzMargin(ByVal Value As Long)
    RqLclSetInt(RqObj, "HorzMargin", Value)
End Property
Property QSCROLLBOX.HorzPosition() As Long
    Return RqGetInt(RqObj, "HorzPosition")
End Property
Property QSCROLLBOX.HorzPosition(ByVal Value As Long)
    RqLclSetInt(RqObj, "HorzPosition", Value)
End Property
Property QSCROLLBOX.HorzRange() As Long
    Return RqGetInt(RqObj, "HorzRange")
End Property
Property QSCROLLBOX.HorzRange(ByVal Value As Long)
    RqLclSetInt(RqObj, "HorzRange", Value)
End Property
Property QSCROLLBOX.HorzTracking() As Long
    Return RqGetInt(RqObj, "HorzTracking")
End Property
Property QSCROLLBOX.HorzTracking(ByVal Value As Long)
    RqLclSetInt(RqObj, "HorzTracking", Value)
End Property
Property QSCROLLBOX.HorzVisible() As Long
    Return RqGetInt(RqObj, "HorzVisible")
End Property
Property QSCROLLBOX.HorzVisible(ByVal Value As Long)
    RqLclSetInt(RqObj, "HorzVisible", Value)
End Property
Property QSCROLLBOX.VertIncrement() As Long
    Return RqGetInt(RqObj, "VertIncrement")
End Property
Property QSCROLLBOX.VertIncrement(ByVal Value As Long)
    RqLclSetInt(RqObj, "VertIncrement", Value)
End Property
Property QSCROLLBOX.VertMargin() As Long
    Return RqGetInt(RqObj, "VertMargin")
End Property
Property QSCROLLBOX.VertMargin(ByVal Value As Long)
    RqLclSetInt(RqObj, "VertMargin", Value)
End Property
Property QSCROLLBOX.VertPosition() As Long
    Return RqGetInt(RqObj, "VertPosition")
End Property
Property QSCROLLBOX.VertPosition(ByVal Value As Long)
    RqLclSetInt(RqObj, "VertPosition", Value)
End Property
Property QSCROLLBOX.VertRange() As Long
    Return RqGetInt(RqObj, "VertRange")
End Property
Property QSCROLLBOX.VertRange(ByVal Value As Long)
    RqLclSetInt(RqObj, "VertRange", Value)
End Property
Property QSCROLLBOX.VertTracking() As Long
    Return RqGetInt(RqObj, "VertTracking")
End Property
Property QSCROLLBOX.VertTracking(ByVal Value As Long)
    RqLclSetInt(RqObj, "VertTracking", Value)
End Property
Property QSCROLLBOX.VertVisible() As Long
    Return RqGetInt(RqObj, "VertVisible")
End Property
Property QSCROLLBOX.VertVisible(ByVal Value As Long)
    RqLclSetInt(RqObj, "VertVisible", Value)
End Property
Property QSCROLLBOX.OnClick(ByVal Handler As Sub())
    SetEventEx(10, "OnClick", Cast(Any Ptr, Handler), 0)
End Property
Property QSCROLLBOX.OnClick(ByVal Handler As Sub(ByRef Sender As QSCROLLBOX))
    SetEventEx(10, "OnClick", Cast(Any Ptr, Handler), 3)
End Property
Property QSCROLLBOX.OnDblClick(ByVal Handler As Sub())
    SetEventEx(11, "OnDblClick", Cast(Any Ptr, Handler), 0)
End Property
Property QSCROLLBOX.OnDblClick(ByVal Handler As Sub(ByRef Sender As QSCROLLBOX))
    SetEventEx(11, "OnDblClick", Cast(Any Ptr, Handler), 3)
End Property
Property QSCROLLBOX.OnResize(ByVal Handler As Sub())
    SetEventEx(21, "OnResize", Cast(Any Ptr, Handler), 0)
End Property
Property QSCROLLBOX.OnResize(ByVal Handler As Sub(ByRef Sender As QSCROLLBOX))
    SetEventEx(21, "OnResize", Cast(Any Ptr, Handler), 3)
End Property
Property QSCROLLBOX.OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(3, "OnMouseDown", Cast(Any Ptr, Handler), 1)
End Property
Property QSCROLLBOX.OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QSCROLLBOX))
    SetEventEx(3, "OnMouseDown", Cast(Any Ptr, Handler), 2)
End Property
Property QSCROLLBOX.OnMouseDown(ByVal Handler As Sub())
    SetEventEx(3, "OnMouseDown", Cast(Any Ptr, Handler), 0)
End Property
Property QSCROLLBOX.OnMouseDown(ByVal Handler As Sub(ByRef Sender As QSCROLLBOX))
    SetEventEx(3, "OnMouseDown", Cast(Any Ptr, Handler), 3)
End Property
Property QSCROLLBOX.OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(4, "OnMouseUp", Cast(Any Ptr, Handler), 1)
End Property
Property QSCROLLBOX.OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QSCROLLBOX))
    SetEventEx(4, "OnMouseUp", Cast(Any Ptr, Handler), 2)
End Property
Property QSCROLLBOX.OnMouseUp(ByVal Handler As Sub())
    SetEventEx(4, "OnMouseUp", Cast(Any Ptr, Handler), 0)
End Property
Property QSCROLLBOX.OnMouseUp(ByVal Handler As Sub(ByRef Sender As QSCROLLBOX))
    SetEventEx(4, "OnMouseUp", Cast(Any Ptr, Handler), 3)
End Property
Property QSCROLLBOX.OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(5, "OnMouseMove", Cast(Any Ptr, Handler), 1)
End Property
Property QSCROLLBOX.OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QSCROLLBOX))
    SetEventEx(5, "OnMouseMove", Cast(Any Ptr, Handler), 2)
End Property
Property QSCROLLBOX.OnMouseMove(ByVal Handler As Sub())
    SetEventEx(5, "OnMouseMove", Cast(Any Ptr, Handler), 0)
End Property
Property QSCROLLBOX.OnMouseMove(ByVal Handler As Sub(ByRef Sender As QSCROLLBOX))
    SetEventEx(5, "OnMouseMove", Cast(Any Ptr, Handler), 3)
End Property

' ---------------------------------------------------------------------------
'  QOVALBTN - кнопка-овал (TSpeedButton с овальной рамкой): Color - овал,
'  ColorHighLight / ColorShadow - рамка; картинка и текст - по центру
'  (Layout не учитывается)
' ---------------------------------------------------------------------------

Type QOVALBTN Extends QCONTROL
    Declare Constructor()
    Declare Property Caption() As String
    Declare Property Caption(ByRef Value As String)
    Declare Property ColorHighLight() As Long
    Declare Property ColorHighLight(ByVal Value As Long)
    Declare Property ColorShadow() As Long
    Declare Property ColorShadow(ByVal Value As Long)
    Declare Property Down() As Long
    Declare Property Down(ByVal Value As Long)
    Declare Property Flat() As Long
    Declare Property Flat(ByVal Value As Long)
    Declare Property GroupIndex() As Long
    Declare Property GroupIndex(ByVal Value As Long)
    Declare Property Layout() As Long
    Declare Property Layout(ByVal Value As Long)
    Declare Property NumBMPs() As Long
    Declare Property NumBMPs(ByVal Value As Long)
    Declare Property Spacing() As Long
    Declare Property Spacing(ByVal Value As Long)
    Declare Property Transparent() As Long
    Declare Property Transparent(ByVal Value As Long)
    Declare Property TransparentColor() As Long
    Declare Property TransparentColor(ByVal Value As Long)
    Declare Property BMP(ByRef Value As String)
    Declare Property BMPHandle(ByVal Value As Long)
    Declare Property OnClick(ByVal Handler As Sub())
    Declare Property OnClick(ByVal Handler As Sub(ByRef Sender As QOVALBTN))
    Declare Property OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QOVALBTN))
    Declare Property OnMouseDown(ByVal Handler As Sub())
    Declare Property OnMouseDown(ByVal Handler As Sub(ByRef Sender As QOVALBTN))
    Declare Property OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QOVALBTN))
    Declare Property OnMouseUp(ByVal Handler As Sub())
    Declare Property OnMouseUp(ByVal Handler As Sub(ByRef Sender As QOVALBTN))
    Declare Property OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QOVALBTN))
    Declare Property OnMouseMove(ByVal Handler As Sub())
    Declare Property OnMouseMove(ByVal Handler As Sub(ByRef Sender As QOVALBTN))
End Type

Constructor QOVALBTN()
    RqObj = RqLclNew("QOVALBTN", @This)
End Constructor
Property QOVALBTN.Caption() As String
    Return RqLclGetStr(RqObj, "Caption")
End Property
Property QOVALBTN.Caption(ByRef Value As String)
    RqLclSetStr(RqObj, "Caption", Value)
End Property
Property QOVALBTN.ColorHighLight() As Long
    Return RqGetInt(RqObj, "ColorHighLight")
End Property
Property QOVALBTN.ColorHighLight(ByVal Value As Long)
    RqLclSetInt(RqObj, "ColorHighLight", Value)
End Property
Property QOVALBTN.ColorShadow() As Long
    Return RqGetInt(RqObj, "ColorShadow")
End Property
Property QOVALBTN.ColorShadow(ByVal Value As Long)
    RqLclSetInt(RqObj, "ColorShadow", Value)
End Property
Property QOVALBTN.Down() As Long
    Return RqGetInt(RqObj, "Down")
End Property
Property QOVALBTN.Down(ByVal Value As Long)
    RqLclSetInt(RqObj, "Down", Value)
End Property
Property QOVALBTN.Flat() As Long
    Return RqGetInt(RqObj, "Flat")
End Property
Property QOVALBTN.Flat(ByVal Value As Long)
    RqLclSetInt(RqObj, "Flat", Value)
End Property
Property QOVALBTN.GroupIndex() As Long
    Return RqGetInt(RqObj, "GroupIndex")
End Property
Property QOVALBTN.GroupIndex(ByVal Value As Long)
    RqLclSetInt(RqObj, "GroupIndex", Value)
End Property
Property QOVALBTN.Layout() As Long
    Return RqGetInt(RqObj, "Layout")
End Property
Property QOVALBTN.Layout(ByVal Value As Long)
    RqLclSetInt(RqObj, "Layout", Value)
End Property
Property QOVALBTN.NumBMPs() As Long
    Return RqGetInt(RqObj, "NumBMPs")
End Property
Property QOVALBTN.NumBMPs(ByVal Value As Long)
    RqLclSetInt(RqObj, "NumBMPs", Value)
End Property
Property QOVALBTN.Spacing() As Long
    Return RqGetInt(RqObj, "Spacing")
End Property
Property QOVALBTN.Spacing(ByVal Value As Long)
    RqLclSetInt(RqObj, "Spacing", Value)
End Property
Property QOVALBTN.Transparent() As Long
    Return RqGetInt(RqObj, "Transparent")
End Property
Property QOVALBTN.Transparent(ByVal Value As Long)
    RqLclSetInt(RqObj, "Transparent", Value)
End Property
Property QOVALBTN.TransparentColor() As Long
    Return RqGetInt(RqObj, "TransparentColor")
End Property
Property QOVALBTN.TransparentColor(ByVal Value As Long)
    RqLclSetInt(RqObj, "TransparentColor", Value)
End Property
' Картинка: файл .bmp или "" (кэш); BMPHandle - ресурс $RESOURCE
Property QOVALBTN.BMP(ByRef Value As String)
    RqLclSetStr(RqObj, "BMP", Value)
End Property
Property QOVALBTN.BMPHandle(ByVal Value As Long)
    RqLclSetInt(RqObj, "BMPHandle", Value)
End Property
Property QOVALBTN.OnClick(ByVal Handler As Sub())
    SetEventEx(10, "OnClick", Cast(Any Ptr, Handler), 0)
End Property
Property QOVALBTN.OnClick(ByVal Handler As Sub(ByRef Sender As QOVALBTN))
    SetEventEx(10, "OnClick", Cast(Any Ptr, Handler), 3)
End Property
Property QOVALBTN.OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(3, "OnMouseDown", Cast(Any Ptr, Handler), 1)
End Property
Property QOVALBTN.OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QOVALBTN))
    SetEventEx(3, "OnMouseDown", Cast(Any Ptr, Handler), 2)
End Property
Property QOVALBTN.OnMouseDown(ByVal Handler As Sub())
    SetEventEx(3, "OnMouseDown", Cast(Any Ptr, Handler), 0)
End Property
Property QOVALBTN.OnMouseDown(ByVal Handler As Sub(ByRef Sender As QOVALBTN))
    SetEventEx(3, "OnMouseDown", Cast(Any Ptr, Handler), 3)
End Property
Property QOVALBTN.OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(4, "OnMouseUp", Cast(Any Ptr, Handler), 1)
End Property
Property QOVALBTN.OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QOVALBTN))
    SetEventEx(4, "OnMouseUp", Cast(Any Ptr, Handler), 2)
End Property
Property QOVALBTN.OnMouseUp(ByVal Handler As Sub())
    SetEventEx(4, "OnMouseUp", Cast(Any Ptr, Handler), 0)
End Property
Property QOVALBTN.OnMouseUp(ByVal Handler As Sub(ByRef Sender As QOVALBTN))
    SetEventEx(4, "OnMouseUp", Cast(Any Ptr, Handler), 3)
End Property
Property QOVALBTN.OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(5, "OnMouseMove", Cast(Any Ptr, Handler), 1)
End Property
Property QOVALBTN.OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QOVALBTN))
    SetEventEx(5, "OnMouseMove", Cast(Any Ptr, Handler), 2)
End Property
Property QOVALBTN.OnMouseMove(ByVal Handler As Sub())
    SetEventEx(5, "OnMouseMove", Cast(Any Ptr, Handler), 0)
End Property
Property QOVALBTN.OnMouseMove(ByVal Handler As Sub(ByRef Sender As QOVALBTN))
    SetEventEx(5, "OnMouseMove", Cast(Any Ptr, Handler), 3)
End Property

' ---------------------------------------------------------------------------
'  QOUTLINE - дерево в стиле Win 3.1 (TTreeView): OutlineStyle 0 osText,
'  1 osPlusMinusText, 2 osPictureText, 3 osPlusMinusPictureText,
'  4 osTreeText, 5 osTreePictureText; BMPClosed / BMPOpen / BMPLeaf -
'  картинки пунктов; BMPPlus / BMPMinus принимаются, не показываются
' ---------------------------------------------------------------------------

Type QOUTLINE Extends QCONTROL
    Declare Constructor()
    Declare Property BorderStyle() As Long
    Declare Property BorderStyle(ByVal Value As Long)
    Declare Property ItemHeight() As Long
    Declare Property ItemHeight(ByVal Value As Long)
    Declare Property ItemIndex() As Long
    Declare Property ItemIndex(ByVal Value As Long)
    Declare Property Row() As Long
    Declare Property Row(ByVal Value As Long)
    Declare Property LineCount() As Long
    Declare Property ItemCount() As Long
    Declare Property OutlineStyle() As Long
    Declare Property OutlineStyle(ByVal Value As Long)
    Declare Property ScrollBars() As Long
    Declare Property ScrollBars(ByVal Value As Long)
    Declare Property ItemSeparator() As String
    Declare Property ItemSeparator(ByRef Value As String)
    Declare Property BMPClosed(ByRef Value As String)
    Declare Property BMPHandleClosed(ByVal Value As Long)
    Declare Property BMPLeaf(ByRef Value As String)
    Declare Property BMPHandleLeaf(ByVal Value As Long)
    Declare Property BMPMinus(ByRef Value As String)
    Declare Property BMPHandleMinus(ByVal Value As Long)
    Declare Property BMPOpen(ByRef Value As String)
    Declare Property BMPHandleOpen(ByVal Value As Long)
    Declare Property BMPPlus(ByRef Value As String)
    Declare Property BMPHandlePlus(ByVal Value As Long)
    Declare Property Item(ByVal ItemNum As Long) As String
    Declare Property Item(ByVal ItemNum As Long, ByRef Value As String)
    Declare Function ItemLevel(ByVal ItemNum As Long) As Long
    Declare Sub OutlineCall(ByRef MethodName As String, ByRef Text1 As String, ByVal IntArg As Long = 0)
    Declare Sub AddLines Overload (ByRef Text1 As String)
    Declare Sub AddLines Overload (ByRef Text1 As String, ByRef Text2 As String)
    Declare Sub AddLines Overload (ByRef Text1 As String, ByRef Text2 As String, ByRef Text3 As String)
    Declare Sub AddLines Overload (ByRef Text1 As String, ByRef Text2 As String, ByRef Text3 As String, ByRef Text4 As String)
    Declare Sub AddChild(ByVal ItemNum As Long, ByRef Text1 As String)
    Declare Sub Insert(ByVal ItemNum As Long, ByRef Text1 As String)
    Declare Sub DelLines(ByVal Index1 As Long, ByVal Index2 As Long = -1, ByVal Index3 As Long = -1, ByVal Index4 As Long = -1)
    Declare Sub AddOptions(ByVal Option1 As Long, ByVal Option2 As Long = -1, ByVal Option3 As Long = -1, ByVal Option4 As Long = -1)
    Declare Sub DelOptions(ByVal Option1 As Long, ByVal Option2 As Long = -1, ByVal Option3 As Long = -1, ByVal Option4 As Long = -1)
    Declare Sub CallInts(ByRef MethodName As String, ByVal Int1 As Long, ByVal Int2 As Long, ByVal Int3 As Long, ByVal Int4 As Long)
    Declare Sub Clear()
    Declare Sub FullExpand()
    Declare Sub FullCollapse()
    Declare Property OnClick(ByVal Handler As Sub())
    Declare Property OnClick(ByVal Handler As Sub(ByRef Sender As QOUTLINE))
    Declare Property OnDblClick(ByVal Handler As Sub())
    Declare Property OnDblClick(ByVal Handler As Sub(ByRef Sender As QOUTLINE))
End Type

Constructor QOUTLINE()
    RqObj = RqLclNew("QOUTLINE", @This)
End Constructor
Property QOUTLINE.BorderStyle() As Long
    Return RqGetInt(RqObj, "BorderStyle")
End Property
Property QOUTLINE.BorderStyle(ByVal Value As Long)
    RqLclSetInt(RqObj, "BorderStyle", Value)
End Property
Property QOUTLINE.ItemHeight() As Long
    Return RqGetInt(RqObj, "ItemHeight")
End Property
Property QOUTLINE.ItemHeight(ByVal Value As Long)
    RqLclSetInt(RqObj, "ItemHeight", Value)
End Property
Property QOUTLINE.ItemIndex() As Long
    Return RqGetInt(RqObj, "ItemIndex")
End Property
Property QOUTLINE.ItemIndex(ByVal Value As Long)
    RqLclSetInt(RqObj, "ItemIndex", Value)
End Property
Property QOUTLINE.Row() As Long
    Return RqGetInt(RqObj, "Row")
End Property
Property QOUTLINE.Row(ByVal Value As Long)
    RqLclSetInt(RqObj, "Row", Value)
End Property
Property QOUTLINE.LineCount() As Long
    Return RqGetInt(RqObj, "LineCount")
End Property
Property QOUTLINE.ItemCount() As Long
    Return RqGetInt(RqObj, "ItemCount")
End Property
Property QOUTLINE.OutlineStyle() As Long
    Return RqGetInt(RqObj, "OutlineStyle")
End Property
Property QOUTLINE.OutlineStyle(ByVal Value As Long)
    RqLclSetInt(RqObj, "OutlineStyle", Value)
End Property
Property QOUTLINE.ScrollBars() As Long
    Return RqGetInt(RqObj, "ScrollBars")
End Property
Property QOUTLINE.ScrollBars(ByVal Value As Long)
    RqLclSetInt(RqObj, "ScrollBars", Value)
End Property
Property QOUTLINE.ItemSeparator() As String
    Return RqLclGetStr(RqObj, "ItemSeparator")
End Property
Property QOUTLINE.ItemSeparator(ByRef Value As String)
    RqLclSetStr(RqObj, "ItemSeparator", Value)
End Property
Property QOUTLINE.BMPClosed(ByRef Value As String)
    RqLclSetStr(RqObj, "BMPClosed", Value)
End Property
Property QOUTLINE.BMPHandleClosed(ByVal Value As Long)
    RqLclSetInt(RqObj, "BMPHandleClosed", Value)
End Property
Property QOUTLINE.BMPLeaf(ByRef Value As String)
    RqLclSetStr(RqObj, "BMPLeaf", Value)
End Property
Property QOUTLINE.BMPHandleLeaf(ByVal Value As Long)
    RqLclSetInt(RqObj, "BMPHandleLeaf", Value)
End Property
Property QOUTLINE.BMPMinus(ByRef Value As String)
    RqLclSetStr(RqObj, "BMPMinus", Value)
End Property
Property QOUTLINE.BMPHandleMinus(ByVal Value As Long)
    RqLclSetInt(RqObj, "BMPHandleMinus", Value)
End Property
Property QOUTLINE.BMPOpen(ByRef Value As String)
    RqLclSetStr(RqObj, "BMPOpen", Value)
End Property
Property QOUTLINE.BMPHandleOpen(ByVal Value As Long)
    RqLclSetInt(RqObj, "BMPHandleOpen", Value)
End Property
Property QOUTLINE.BMPPlus(ByRef Value As String)
    RqLclSetStr(RqObj, "BMPPlus", Value)
End Property
Property QOUTLINE.BMPHandlePlus(ByVal Value As Long)
    RqLclSetInt(RqObj, "BMPHandlePlus", Value)
End Property
' Пункт по номеру (с 0, все уровни подряд)
Property QOUTLINE.Item(ByVal ItemNum As Long) As String
    Return RqLclGetItemEx(RqObj, "Item", ItemNum, "QOUTLINE.Item")
End Property
Property QOUTLINE.Item(ByVal ItemNum As Long, ByRef Value As String)
    If RqSetItemStr(RqObj, "Item", ItemNum, StrPtr(Value)) = 0 Then RqLclClassError("QOUTLINE.Item")
End Property
' Уровень пункта (0 - верхний)
Function QOUTLINE.ItemLevel(ByVal ItemNum As Long) As Long
    Return RqLclGetItemIntEx(RqObj, "Item.Level", ItemNum, "QOUTLINE.ItemLevel")
End Function
Sub QOUTLINE.OutlineCall(ByRef MethodName As String, ByRef Text1 As String, ByVal IntArg As Long = 0)
    If RqCallEx(RqObj, MethodName, StrPtr(Text1), IntArg, 0, 0, 0, 0) = 0 Then
        RqLclClassError("QOUTLINE." & MethodName)
    End If
End Sub
' Строки; ведущие пробелы (табуляции) - уровень: "Parent", " Child"
' (до четырёх за вызов; больше - препроцессор делит вызов)
Sub QOUTLINE.AddLines(ByRef Text1 As String)
    OutlineCall("AddLines", Text1)
End Sub
Sub QOUTLINE.AddLines(ByRef Text1 As String, ByRef Text2 As String)
    OutlineCall("AddLines", Text1) : OutlineCall("AddLines", Text2)
End Sub
Sub QOUTLINE.AddLines(ByRef Text1 As String, ByRef Text2 As String, ByRef Text3 As String)
    OutlineCall("AddLines", Text1) : OutlineCall("AddLines", Text2) : OutlineCall("AddLines", Text3)
End Sub
Sub QOUTLINE.AddLines(ByRef Text1 As String, ByRef Text2 As String, ByRef Text3 As String, ByRef Text4 As String)
    OutlineCall("AddLines", Text1) : OutlineCall("AddLines", Text2) : OutlineCall("AddLines", Text3)
    OutlineCall("AddLines", Text4)
End Sub
' Номера по очереди (-1 - нет), до четырёх за вызов
Sub QOUTLINE.CallInts(ByRef MethodName As String, ByVal Int1 As Long, ByVal Int2 As Long, ByVal Int3 As Long, ByVal Int4 As Long)
    Dim IntList(1 To 4) As Long = {Int1, Int2, Int3, Int4}
    For ArgIdx As Long = 1 To 4
        If (ArgIdx > 1) AndAlso (IntList(ArgIdx) = -1) Then Exit For
        OutlineCall(MethodName, "", IntList(ArgIdx))
    Next
End Sub
Sub QOUTLINE.AddChild(ByVal ItemNum As Long, ByRef Text1 As String)
    OutlineCall("AddChild", Text1, ItemNum)
End Sub
' Перед пунктом ItemNum (ItemCount - в конец)
Sub QOUTLINE.Insert(ByVal ItemNum As Long, ByRef Text1 As String)
    OutlineCall("Insert", Text1, ItemNum)
End Sub
Sub QOUTLINE.DelLines(ByVal Index1 As Long, ByVal Index2 As Long = -1, ByVal Index3 As Long = -1, ByVal Index4 As Long = -1)
    CallInts("DelLines", Index1, Index2, Index3, Index4)
End Sub
' ooDrawTreeRoot 0, ooDrawFocusRect 1, ooStretchBitmaps 2
Sub QOUTLINE.AddOptions(ByVal Option1 As Long, ByVal Option2 As Long = -1, ByVal Option3 As Long = -1, ByVal Option4 As Long = -1)
    CallInts("AddOptions", Option1, Option2, Option3, Option4)
End Sub
Sub QOUTLINE.DelOptions(ByVal Option1 As Long, ByVal Option2 As Long = -1, ByVal Option3 As Long = -1, ByVal Option4 As Long = -1)
    CallInts("DelOptions", Option1, Option2, Option3, Option4)
End Sub
Sub QOUTLINE.Clear()
    OutlineCall("Clear", "")
End Sub
Sub QOUTLINE.FullExpand()
    OutlineCall("FullExpand", "")
End Sub
Sub QOUTLINE.FullCollapse()
    OutlineCall("FullCollapse", "")
End Sub
Property QOUTLINE.OnClick(ByVal Handler As Sub())
    SetEventEx(10, "OnClick", Cast(Any Ptr, Handler), 0)
End Property
Property QOUTLINE.OnClick(ByVal Handler As Sub(ByRef Sender As QOUTLINE))
    SetEventEx(10, "OnClick", Cast(Any Ptr, Handler), 3)
End Property
Property QOUTLINE.OnDblClick(ByVal Handler As Sub())
    SetEventEx(11, "OnDblClick", Cast(Any Ptr, Handler), 0)
End Property
Property QOUTLINE.OnDblClick(ByVal Handler As Sub(ByRef Sender As QOUTLINE))
    SetEventEx(11, "OnDblClick", Cast(Any Ptr, Handler), 3)
End Property

' Секция QHEADER: Header.Sections(i).Width = 100 (Sections(i) возвращает
' эту обёртку с номером i)
Type QHEADERSECTION
    OwnerPtr As Any Ptr
    SectionNum As Long
    Declare Property Caption() As String
    Declare Property Caption(ByRef Value As String)
    Declare Property Alignment() As Long
    Declare Property Alignment(ByVal Value As Long)
    Declare Property AllowClick() As Long
    Declare Property AllowClick(ByVal Value As Long)
    Declare Property MaxWidth() As Long
    Declare Property MaxWidth(ByVal Value As Long)
    Declare Property MinWidth() As Long
    Declare Property MinWidth(ByVal Value As Long)
    Declare Property Style() As Long
    Declare Property Style(ByVal Value As Long)
    Declare Property Width() As Long
    Declare Property Width(ByVal Value As Long)
End Type
Property QHEADERSECTION.Caption() As String
    Return RqLclGetItemEx(OwnerPtr, "Sections.Caption", SectionNum, "QHEADER.Sections")
End Property
Property QHEADERSECTION.Caption(ByRef Value As String)
    If RqSetItemStr(OwnerPtr, "Sections.Caption", SectionNum, StrPtr(Value)) = 0 Then RqLclClassError("QHEADER.Sections")
End Property
Property QHEADERSECTION.Alignment() As Long
    Return RqLclGetItemIntEx(OwnerPtr, "Sections.Alignment", SectionNum, "QHEADER.Sections")
End Property
Property QHEADERSECTION.Alignment(ByVal Value As Long)
    If RqSetItemInt(OwnerPtr, "Sections.Alignment", SectionNum, Value) = 0 Then RqLclClassError("QHEADER.Sections")
End Property
Property QHEADERSECTION.AllowClick() As Long
    Return RqLclGetItemIntEx(OwnerPtr, "Sections.AllowClick", SectionNum, "QHEADER.Sections")
End Property
Property QHEADERSECTION.AllowClick(ByVal Value As Long)
    If RqSetItemInt(OwnerPtr, "Sections.AllowClick", SectionNum, Value) = 0 Then RqLclClassError("QHEADER.Sections")
End Property
Property QHEADERSECTION.MaxWidth() As Long
    Return RqLclGetItemIntEx(OwnerPtr, "Sections.MaxWidth", SectionNum, "QHEADER.Sections")
End Property
Property QHEADERSECTION.MaxWidth(ByVal Value As Long)
    If RqSetItemInt(OwnerPtr, "Sections.MaxWidth", SectionNum, Value) = 0 Then RqLclClassError("QHEADER.Sections")
End Property
Property QHEADERSECTION.MinWidth() As Long
    Return RqLclGetItemIntEx(OwnerPtr, "Sections.MinWidth", SectionNum, "QHEADER.Sections")
End Property
Property QHEADERSECTION.MinWidth(ByVal Value As Long)
    If RqSetItemInt(OwnerPtr, "Sections.MinWidth", SectionNum, Value) = 0 Then RqLclClassError("QHEADER.Sections")
End Property
Property QHEADERSECTION.Style() As Long
    Return RqLclGetItemIntEx(OwnerPtr, "Sections.Style", SectionNum, "QHEADER.Sections")
End Property
Property QHEADERSECTION.Style(ByVal Value As Long)
    If RqSetItemInt(OwnerPtr, "Sections.Style", SectionNum, Value) = 0 Then RqLclClassError("QHEADER.Sections")
End Property
Property QHEADERSECTION.Width() As Long
    Return RqLclGetItemIntEx(OwnerPtr, "Sections.Width", SectionNum, "QHEADER.Sections")
End Property
Property QHEADERSECTION.Width(ByVal Value As Long)
    If RqSetItemInt(OwnerPtr, "Sections.Width", SectionNum, Value) = 0 Then RqLclClassError("QHEADER.Sections")
End Property

' ---------------------------------------------------------------------------
'  QHEADER - заголовки столбцов (THeaderControl); Sections(i): Caption,
'  Width, MinWidth, MaxWidth, Alignment (0 слева, 1 справа, 2 по центру),
'  Style (0 hsText, 1 hsOwnerDraw - рисует OnDrawSection), AllowClick.
'  OnSectionTrack (Index, Width, State): 0 начало, 1 движение, 2 конец
' ---------------------------------------------------------------------------

Type QHEADER Extends QCONTROL
    SectionWrap As QHEADERSECTION
    Declare Constructor()
    Declare Property HotTrack() As Long
    Declare Property HotTrack(ByVal Value As Long)
    Declare Property SectionsCount() As Long
    Declare Function Sections(ByVal SectionNum As Long) ByRef As QHEADERSECTION
    Declare Sub AddSections Overload (ByRef Text1 As String)
    Declare Sub AddSections Overload (ByRef Text1 As String, ByRef Text2 As String)
    Declare Sub AddSections Overload (ByRef Text1 As String, ByRef Text2 As String, ByRef Text3 As String)
    Declare Sub AddSections Overload (ByRef Text1 As String, ByRef Text2 As String, ByRef Text3 As String, ByRef Text4 As String)
    Declare Sub Clear()
    Declare Property CopyMode() As Long
    Declare Property CopyMode(ByVal Value As Long)
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
    Declare Sub CopyRect Overload (ByRef DstRect As QRECT, ByRef Source As QCONTROL, ByRef SrcRect As QRECT)
    Declare Sub Rotate(ByVal X1 As Long, ByVal Y1 As Long, ByVal Angle As Long)
    Declare Function TextWidth(ByRef Text1 As String) As Long
    Declare Function TextHeight(ByRef Text1 As String) As Long
    Declare Property OnResize(ByVal Handler As Sub())
    Declare Property OnResize(ByVal Handler As Sub(ByRef Sender As QHEADER))
    Declare Property OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QHEADER))
    Declare Property OnMouseDown(ByVal Handler As Sub())
    Declare Property OnMouseDown(ByVal Handler As Sub(ByRef Sender As QHEADER))
    Declare Property OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QHEADER))
    Declare Property OnMouseUp(ByVal Handler As Sub())
    Declare Property OnMouseUp(ByVal Handler As Sub(ByRef Sender As QHEADER))
    Declare Property OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QHEADER))
    Declare Property OnMouseMove(ByVal Handler As Sub())
    Declare Property OnMouseMove(ByVal Handler As Sub(ByRef Sender As QHEADER))
    Declare Property OnDrawSection(ByVal Handler As Sub(ByVal Index As Long, ByVal Pressed As Long, ByRef R As QRECT))
    Declare Property OnDrawSection(ByVal Handler As Sub(ByVal Index As Long, ByVal Pressed As Long, ByRef R As QRECT, ByRef Sender As QHEADER))
    Declare Property OnDrawSection(ByVal Handler As Sub())
    Declare Property OnDrawSection(ByVal Handler As Sub(ByRef Sender As QHEADER))
    Declare Property OnSectionClick(ByVal Handler As Sub(ByVal Index As Long))
    Declare Property OnSectionClick(ByVal Handler As Sub(ByVal Index As Long, ByRef Sender As QHEADER))
    Declare Property OnSectionClick(ByVal Handler As Sub())
    Declare Property OnSectionClick(ByVal Handler As Sub(ByRef Sender As QHEADER))
    Declare Property OnSectionResize(ByVal Handler As Sub(ByVal Index As Long))
    Declare Property OnSectionResize(ByVal Handler As Sub(ByVal Index As Long, ByRef Sender As QHEADER))
    Declare Property OnSectionResize(ByVal Handler As Sub())
    Declare Property OnSectionResize(ByVal Handler As Sub(ByRef Sender As QHEADER))
    Declare Property OnSectionTrack(ByVal Handler As Sub(ByVal Index As Long, ByVal SectionWidth As Long, ByVal State As Long))
    Declare Property OnSectionTrack(ByVal Handler As Sub(ByVal Index As Long, ByVal SectionWidth As Long, ByVal State As Long, ByRef Sender As QHEADER))
    Declare Property OnSectionTrack(ByVal Handler As Sub())
    Declare Property OnSectionTrack(ByVal Handler As Sub(ByRef Sender As QHEADER))
End Type

Constructor QHEADER()
    RqObj = RqLclNew("QHEADER", @This)
End Constructor
Property QHEADER.HotTrack() As Long
    Return RqGetInt(RqObj, "HotTrack")
End Property
Property QHEADER.HotTrack(ByVal Value As Long)
    RqLclSetInt(RqObj, "HotTrack", Value)
End Property
Property QHEADER.SectionsCount() As Long
    Return RqGetInt(RqObj, "SectionsCount")
End Property
Function QHEADER.Sections(ByVal SectionNum As Long) ByRef As QHEADERSECTION
    SectionWrap.OwnerPtr = RqObj
    SectionWrap.SectionNum = SectionNum
    Return SectionWrap
End Function
' Секции, до четырёх за вызов (больше - препроцессор делит вызов)
Sub QHEADER.AddSections(ByRef Text1 As String)
    If RqCallEx(RqObj, "AddSections", StrPtr(Text1), 0, 0, 0, 0, 0) = 0 Then RqLclClassError("QHEADER.AddSections")
End Sub
Sub QHEADER.AddSections(ByRef Text1 As String, ByRef Text2 As String)
    AddSections(Text1) : AddSections(Text2)
End Sub
Sub QHEADER.AddSections(ByRef Text1 As String, ByRef Text2 As String, ByRef Text3 As String)
    AddSections(Text1) : AddSections(Text2) : AddSections(Text3)
End Sub
Sub QHEADER.AddSections(ByRef Text1 As String, ByRef Text2 As String, ByRef Text3 As String, ByRef Text4 As String)
    AddSections(Text1) : AddSections(Text2) : AddSections(Text3) : AddSections(Text4)
End Sub
Sub QHEADER.Clear()
    If RqCallEx(RqObj, "Clear", 0, 0, 0, 0, 0, 0) = 0 Then RqLclClassError("QHEADER.Clear")
End Sub
Property QHEADER.CopyMode() As Long
    Return RqGetInt(RqObj, "CopyMode")
End Property
Property QHEADER.CopyMode(ByVal Value As Long)
    RqLclSetInt(RqObj, "CopyMode", Value)
End Property
' Pixel(x, y) - цвет точки; Obj.Pixel(x, y) = c - препроцессор: SetPixel
Function QHEADER.Pixel(ByVal X As Long, ByVal Y As Long) As Long
    Return RqCallEx(RqObj, "GetPixel", 0, X, Y, 0, 0, 0)
End Function
Sub QHEADER.SetPixel(ByVal X As Long, ByVal Y As Long, ByVal PixelColor As Long)
    If RqCallEx(RqObj, "SetPixel", 0, X, Y, PixelColor, 0, 0) = 0 Then RqLclClassError("QHEADER.Pixel")
End Sub
Sub QHEADER.DrawInts(ByRef MethodName As String, ByRef Text1 As String, IntList() As Long)
    If RqCallInts(RqObj, MethodName, StrPtr(Text1), @IntList(0), UBound(IntList) + 1) = 0 Then
        RqLclClassError("QHEADER." & MethodName)
    End If
End Sub
' BackColor = -1 - фон прозрачный
Sub QHEADER.TextOut(ByVal X1 As Long, ByVal Y1 As Long, ByRef Text1 As String, ByVal TextColor As Long, ByVal BackColor As Long = -1)
    Dim IntList(0 To 3) As Long = {X1, Y1, TextColor, BackColor}
    DrawInts("TextOut", Text1, IntList())
End Sub
Sub QHEADER.FillRect(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal FillColor As Long)
    Dim IntList(0 To 4) As Long = {X1, Y1, X2, Y2, FillColor}
    DrawInts("FillRect", "", IntList())
End Sub
Sub QHEADER.Line(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal LineColor As Long)
    Dim IntList(0 To 4) As Long = {X1, Y1, X2, Y2, LineColor}
    DrawInts("Line", "", IntList())
End Sub
Sub QHEADER.Rectangle(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal LineColor As Long)
    Dim IntList(0 To 4) As Long = {X1, Y1, X2, Y2, LineColor}
    DrawInts("Rectangle", "", IntList())
End Sub
Sub QHEADER.RoundRect(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal X3 As Long, ByVal Y3 As Long, ByVal FillColor As Long)
    Dim IntList(0 To 6) As Long = {X1, Y1, X2, Y2, X3, Y3, FillColor}
    DrawInts("RoundRect", "", IntList())
End Sub
Sub QHEADER.Circle(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal LineColor As Long, ByVal FillFlag As Long)
    Dim IntList(0 To 5) As Long = {X1, Y1, X2, Y2, LineColor, FillFlag}
    DrawInts("Circle", "", IntList())
End Sub
Sub QHEADER.Pset(ByVal X1 As Long, ByVal Y1 As Long, ByVal PixelColor As Long)
    Dim IntList(0 To 2) As Long = {X1, Y1, PixelColor}
    DrawInts("Pset", "", IntList())
End Sub
Sub QHEADER.Paint(ByVal X1 As Long, ByVal Y1 As Long, ByVal FillColor As Long, ByVal BorderColor As Long)
    Dim IntList(0 To 3) As Long = {X1, Y1, FillColor, BorderColor}
    DrawInts("Paint", "", IntList())
End Sub
' Картинка - файл .bmp или "" (кэш: Obj.Draw(0, 0, Bitmap.BMP))
Sub QHEADER.Draw(ByVal X1 As Long, ByVal Y1 As Long, ByRef BmpText As String)
    Dim IntList(0 To 1) As Long = {X1, Y1}
    DrawInts("Draw", BmpText, IntList())
End Sub
Sub QHEADER.StretchDraw(ByRef DstRect As QRECT, ByRef BmpText As String)
    Dim IntList(0 To 3) As Long = {DstRect.Left, DstRect.Top, DstRect.Right, DstRect.Bottom}
    DrawInts("StretchDraw", BmpText, IntList())
End Sub
Sub QHEADER.TextRect(ByRef ClipRect As QRECT, ByVal X1 As Long, ByVal Y1 As Long, ByRef Text1 As String, ByVal TextColor As Long, ByVal BackColor As Long = -1)
    Dim IntList(0 To 7) As Long = {ClipRect.Left, ClipRect.Top, ClipRect.Right, ClipRect.Bottom, X1, Y1, TextColor, BackColor}
    DrawInts("TextRect", Text1, IntList())
End Sub
Sub QHEADER.CopyRectPtr(ByRef DstRect As QRECT, ByVal SourcePtr As Any Ptr, ByRef SrcRect As QRECT)
    Dim IntList(0 To 7) As Long = {DstRect.Left, DstRect.Top, DstRect.Right, DstRect.Bottom, _
        SrcRect.Left, SrcRect.Top, SrcRect.Right, SrcRect.Bottom}
    If RqCallObjInts(RqObj, "CopyRect", SourcePtr, @IntList(0), 8) = 0 Then RqLclClassError("QHEADER.CopyRect")
End Sub
' Source - QIMAGE, QCANVAS, QBITMAP, QFORM (у кого есть холст)
Sub QHEADER.CopyRect(ByRef DstRect As QRECT, ByRef Source As QCONTROL, ByRef SrcRect As QRECT)
    CopyRectPtr(DstRect, Source.RqObj, SrcRect)
End Sub
' Поворот пока не сделан - ошибка
Sub QHEADER.Rotate(ByVal X1 As Long, ByVal Y1 As Long, ByVal Angle As Long)
    If RqCallEx(RqObj, "Rotate", 0, X1, Y1, Angle, 0, 0) = 0 Then RqLclClassError("QHEADER.Rotate")
End Sub
Function QHEADER.TextWidth(ByRef Text1 As String) As Long
    Return RqCallEx(RqObj, "TextWidth", StrPtr(Text1), 0, 0, 0, 0, 0)
End Function
Function QHEADER.TextHeight(ByRef Text1 As String) As Long
    Return RqCallEx(RqObj, "TextHeight", StrPtr(Text1), 0, 0, 0, 0, 0)
End Function
Property QHEADER.OnResize(ByVal Handler As Sub())
    SetEventEx(21, "OnResize", Cast(Any Ptr, Handler), 0)
End Property
Property QHEADER.OnResize(ByVal Handler As Sub(ByRef Sender As QHEADER))
    SetEventEx(21, "OnResize", Cast(Any Ptr, Handler), 3)
End Property
Property QHEADER.OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(3, "OnMouseDown", Cast(Any Ptr, Handler), 1)
End Property
Property QHEADER.OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QHEADER))
    SetEventEx(3, "OnMouseDown", Cast(Any Ptr, Handler), 2)
End Property
Property QHEADER.OnMouseDown(ByVal Handler As Sub())
    SetEventEx(3, "OnMouseDown", Cast(Any Ptr, Handler), 0)
End Property
Property QHEADER.OnMouseDown(ByVal Handler As Sub(ByRef Sender As QHEADER))
    SetEventEx(3, "OnMouseDown", Cast(Any Ptr, Handler), 3)
End Property
Property QHEADER.OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(4, "OnMouseUp", Cast(Any Ptr, Handler), 1)
End Property
Property QHEADER.OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QHEADER))
    SetEventEx(4, "OnMouseUp", Cast(Any Ptr, Handler), 2)
End Property
Property QHEADER.OnMouseUp(ByVal Handler As Sub())
    SetEventEx(4, "OnMouseUp", Cast(Any Ptr, Handler), 0)
End Property
Property QHEADER.OnMouseUp(ByVal Handler As Sub(ByRef Sender As QHEADER))
    SetEventEx(4, "OnMouseUp", Cast(Any Ptr, Handler), 3)
End Property
Property QHEADER.OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(5, "OnMouseMove", Cast(Any Ptr, Handler), 1)
End Property
Property QHEADER.OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QHEADER))
    SetEventEx(5, "OnMouseMove", Cast(Any Ptr, Handler), 2)
End Property
Property QHEADER.OnMouseMove(ByVal Handler As Sub())
    SetEventEx(5, "OnMouseMove", Cast(Any Ptr, Handler), 0)
End Property
Property QHEADER.OnMouseMove(ByVal Handler As Sub(ByRef Sender As QHEADER))
    SetEventEx(5, "OnMouseMove", Cast(Any Ptr, Handler), 3)
End Property
Property QHEADER.OnDrawSection(ByVal Handler As Sub(ByVal Index As Long, ByVal Pressed As Long, ByRef R As QRECT))
    SetEventEx(26, "OnDrawSection", Cast(Any Ptr, Handler), 1)
End Property
Property QHEADER.OnDrawSection(ByVal Handler As Sub(ByVal Index As Long, ByVal Pressed As Long, ByRef R As QRECT, ByRef Sender As QHEADER))
    SetEventEx(26, "OnDrawSection", Cast(Any Ptr, Handler), 2)
End Property
Property QHEADER.OnDrawSection(ByVal Handler As Sub())
    SetEventEx(26, "OnDrawSection", Cast(Any Ptr, Handler), 0)
End Property
Property QHEADER.OnDrawSection(ByVal Handler As Sub(ByRef Sender As QHEADER))
    SetEventEx(26, "OnDrawSection", Cast(Any Ptr, Handler), 3)
End Property
Property QHEADER.OnSectionClick(ByVal Handler As Sub(ByVal Index As Long))
    SetEventEx(27, "OnSectionClick", Cast(Any Ptr, Handler), 1)
End Property
Property QHEADER.OnSectionClick(ByVal Handler As Sub(ByVal Index As Long, ByRef Sender As QHEADER))
    SetEventEx(27, "OnSectionClick", Cast(Any Ptr, Handler), 2)
End Property
Property QHEADER.OnSectionClick(ByVal Handler As Sub())
    SetEventEx(27, "OnSectionClick", Cast(Any Ptr, Handler), 0)
End Property
Property QHEADER.OnSectionClick(ByVal Handler As Sub(ByRef Sender As QHEADER))
    SetEventEx(27, "OnSectionClick", Cast(Any Ptr, Handler), 3)
End Property
Property QHEADER.OnSectionResize(ByVal Handler As Sub(ByVal Index As Long))
    SetEventEx(28, "OnSectionResize", Cast(Any Ptr, Handler), 1)
End Property
Property QHEADER.OnSectionResize(ByVal Handler As Sub(ByVal Index As Long, ByRef Sender As QHEADER))
    SetEventEx(28, "OnSectionResize", Cast(Any Ptr, Handler), 2)
End Property
Property QHEADER.OnSectionResize(ByVal Handler As Sub())
    SetEventEx(28, "OnSectionResize", Cast(Any Ptr, Handler), 0)
End Property
Property QHEADER.OnSectionResize(ByVal Handler As Sub(ByRef Sender As QHEADER))
    SetEventEx(28, "OnSectionResize", Cast(Any Ptr, Handler), 3)
End Property
Property QHEADER.OnSectionTrack(ByVal Handler As Sub(ByVal Index As Long, ByVal SectionWidth As Long, ByVal State As Long))
    SetEventEx(29, "OnSectionTrack", Cast(Any Ptr, Handler), 1)
End Property
Property QHEADER.OnSectionTrack(ByVal Handler As Sub(ByVal Index As Long, ByVal SectionWidth As Long, ByVal State As Long, ByRef Sender As QHEADER))
    SetEventEx(29, "OnSectionTrack", Cast(Any Ptr, Handler), 2)
End Property
Property QHEADER.OnSectionTrack(ByVal Handler As Sub())
    SetEventEx(29, "OnSectionTrack", Cast(Any Ptr, Handler), 0)
End Property
Property QHEADER.OnSectionTrack(ByVal Handler As Sub(ByRef Sender As QHEADER))
    SetEventEx(29, "OnSectionTrack", Cast(Any Ptr, Handler), 3)
End Property

' Printer.Capabilities.Copies / Orientation / Collate
Type QPRINTERCAPS
    OwnerPtr As Any Ptr
    Declare Property Copies() As Long
    Declare Property Orientation() As Long
    Declare Property Collate() As Long
End Type
Property QPRINTERCAPS.Copies() As Long
    Return RqGetInt(OwnerPtr, "Capabilities.Copies")
End Property
Property QPRINTERCAPS.Orientation() As Long
    Return RqGetInt(OwnerPtr, "Capabilities.Orientation")
End Property
Property QPRINTERCAPS.Collate() As Long
    Return RqGetInt(OwnerPtr, "Capabilities.Collate")
End Property

' ---------------------------------------------------------------------------
'  Printer - глобальный объект RapidQ (печать функциями Windows): рисование
'  - между BeginDoc и EndDoc, координаты - точки принтера (PageWidth,
'  PageHeight); Orientation 0 книжная, 1 альбомная (до BeginDoc);
'  Printers(i), PrinterIndex - принтеры Windows (сначала - по умолчанию)
' ---------------------------------------------------------------------------

Type QPRINTER
    RqObj As Any Ptr
    FontWrap As QFONT = QFONT(0)
    CapsWrap As QPRINTERCAPS
    Declare Function Obj() As Any Ptr
    Declare Property Aborted() As Long
    Declare Property Copies() As Long
    Declare Property Copies(ByVal Value As Long)
    Declare Property FontsCount() As Long
    Declare Property Handle() As Long
    Declare Property Orientation() As Long
    Declare Property Orientation(ByVal Value As Long)
    Declare Property PageHeight() As Long
    Declare Property PageNumber() As Long
    Declare Property PageWidth() As Long
    Declare Property PrinterIndex() As Long
    Declare Property PrinterIndex(ByVal Value As Long)
    Declare Property PrintersCount() As Long
    Declare Property Printing() As Long
    Declare Property Title() As String
    Declare Property Title(ByRef Value As String)
    Declare Property Printers(ByVal ItemNum As Long) As String
    Declare Property Fonts(ByVal ItemNum As Long) As String
    Declare Function Capabilities() ByRef As QPRINTERCAPS
    Declare Function Font() ByRef As QFONT
    Declare Sub BeginDoc()
    Declare Sub EndDoc()
    Declare Sub NewPage()
    Declare Sub Abort()
    Declare Property CopyMode() As Long
    Declare Property CopyMode(ByVal Value As Long)
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
    Declare Sub CopyRect Overload (ByRef DstRect As QRECT, ByRef Source As QCONTROL, ByRef SrcRect As QRECT)
    Declare Sub Rotate(ByVal X1 As Long, ByVal Y1 As Long, ByVal Angle As Long)
    Declare Function TextWidth(ByRef Text1 As String) As Long
    Declare Function TextHeight(ByRef Text1 As String) As Long
End Type
Function QPRINTER.Obj() As Any Ptr
    If RqObj = 0 Then RqObj = RqLclNew("QPRINTER", 0)
    Return RqObj
End Function
Property QPRINTER.Aborted() As Long
    Return RqGetInt(Obj(), "Aborted")
End Property
Property QPRINTER.Copies() As Long
    Return RqGetInt(Obj(), "Copies")
End Property
Property QPRINTER.Copies(ByVal Value As Long)
    RqLclSetInt(Obj(), "Copies", Value)
End Property
Property QPRINTER.FontsCount() As Long
    Return RqGetInt(Obj(), "FontsCount")
End Property
Property QPRINTER.Handle() As Long
    Return RqGetInt(Obj(), "Handle")
End Property
Property QPRINTER.Orientation() As Long
    Return RqGetInt(Obj(), "Orientation")
End Property
Property QPRINTER.Orientation(ByVal Value As Long)
    RqLclSetInt(Obj(), "Orientation", Value)
End Property
Property QPRINTER.PageHeight() As Long
    Return RqGetInt(Obj(), "PageHeight")
End Property
Property QPRINTER.PageNumber() As Long
    Return RqGetInt(Obj(), "PageNumber")
End Property
Property QPRINTER.PageWidth() As Long
    Return RqGetInt(Obj(), "PageWidth")
End Property
Property QPRINTER.PrinterIndex() As Long
    Return RqGetInt(Obj(), "PrinterIndex")
End Property
Property QPRINTER.PrinterIndex(ByVal Value As Long)
    RqLclSetInt(Obj(), "PrinterIndex", Value)
End Property
Property QPRINTER.PrintersCount() As Long
    Return RqGetInt(Obj(), "PrintersCount")
End Property
Property QPRINTER.Printing() As Long
    Return RqGetInt(Obj(), "Printing")
End Property
Property QPRINTER.Title() As String
    Return RqLclGetStr(Obj(), "Title")
End Property
Property QPRINTER.Title(ByRef Value As String)
    RqLclSetStr(Obj(), "Title", Value)
End Property
Property QPRINTER.Printers(ByVal ItemNum As Long) As String
    Return RqLclGetItemEx(Obj(), "Printers", ItemNum, "Printer.Printers")
End Property
Property QPRINTER.Fonts(ByVal ItemNum As Long) As String
    Return RqLclGetItemEx(Obj(), "Fonts", ItemNum, "Printer.Fonts")
End Property
Function QPRINTER.Capabilities() ByRef As QPRINTERCAPS
    CapsWrap.OwnerPtr = Obj()
    Return CapsWrap
End Function
' Шрифт холста; Obj.Font = Font копирует значения (QFONT.Let)
Function QPRINTER.Font() ByRef As QFONT
    FontWrap.RqObj = RqGetObj(Obj(), "Font")
    If FontWrap.RqObj = 0 Then RqLclShowError("QPRINTER.Font")
    Return FontWrap
End Function
Sub QPRINTER.BeginDoc()
    If RqCallEx(Obj(), "BeginDoc", 0, 0, 0, 0, 0, 0) = 0 Then RqLclClassError("Printer.BeginDoc")
End Sub
Sub QPRINTER.EndDoc()
    If RqCallEx(Obj(), "EndDoc", 0, 0, 0, 0, 0, 0) = 0 Then RqLclClassError("Printer.EndDoc")
End Sub
Sub QPRINTER.NewPage()
    If RqCallEx(Obj(), "NewPage", 0, 0, 0, 0, 0, 0) = 0 Then RqLclClassError("Printer.NewPage")
End Sub
Sub QPRINTER.Abort()
    If RqCallEx(Obj(), "Abort", 0, 0, 0, 0, 0, 0) = 0 Then RqLclClassError("Printer.Abort")
End Sub
Property QPRINTER.CopyMode() As Long
    Return RqGetInt(Obj(), "CopyMode")
End Property
Property QPRINTER.CopyMode(ByVal Value As Long)
    RqLclSetInt(Obj(), "CopyMode", Value)
End Property
' Pixel(x, y) - цвет точки; Obj.Pixel(x, y) = c - препроцессор: SetPixel
Function QPRINTER.Pixel(ByVal X As Long, ByVal Y As Long) As Long
    Return RqCallEx(Obj(), "GetPixel", 0, X, Y, 0, 0, 0)
End Function
Sub QPRINTER.SetPixel(ByVal X As Long, ByVal Y As Long, ByVal PixelColor As Long)
    If RqCallEx(Obj(), "SetPixel", 0, X, Y, PixelColor, 0, 0) = 0 Then RqLclClassError("QPRINTER.Pixel")
End Sub
Sub QPRINTER.DrawInts(ByRef MethodName As String, ByRef Text1 As String, IntList() As Long)
    If RqCallInts(Obj(), MethodName, StrPtr(Text1), @IntList(0), UBound(IntList) + 1) = 0 Then
        RqLclClassError("QPRINTER." & MethodName)
    End If
End Sub
' BackColor = -1 - фон прозрачный
Sub QPRINTER.TextOut(ByVal X1 As Long, ByVal Y1 As Long, ByRef Text1 As String, ByVal TextColor As Long, ByVal BackColor As Long = -1)
    Dim IntList(0 To 3) As Long = {X1, Y1, TextColor, BackColor}
    DrawInts("TextOut", Text1, IntList())
End Sub
Sub QPRINTER.FillRect(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal FillColor As Long)
    Dim IntList(0 To 4) As Long = {X1, Y1, X2, Y2, FillColor}
    DrawInts("FillRect", "", IntList())
End Sub
Sub QPRINTER.Line(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal LineColor As Long)
    Dim IntList(0 To 4) As Long = {X1, Y1, X2, Y2, LineColor}
    DrawInts("Line", "", IntList())
End Sub
Sub QPRINTER.Rectangle(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal LineColor As Long)
    Dim IntList(0 To 4) As Long = {X1, Y1, X2, Y2, LineColor}
    DrawInts("Rectangle", "", IntList())
End Sub
Sub QPRINTER.RoundRect(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal X3 As Long, ByVal Y3 As Long, ByVal FillColor As Long)
    Dim IntList(0 To 6) As Long = {X1, Y1, X2, Y2, X3, Y3, FillColor}
    DrawInts("RoundRect", "", IntList())
End Sub
Sub QPRINTER.Circle(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal LineColor As Long, ByVal FillFlag As Long)
    Dim IntList(0 To 5) As Long = {X1, Y1, X2, Y2, LineColor, FillFlag}
    DrawInts("Circle", "", IntList())
End Sub
Sub QPRINTER.Pset(ByVal X1 As Long, ByVal Y1 As Long, ByVal PixelColor As Long)
    Dim IntList(0 To 2) As Long = {X1, Y1, PixelColor}
    DrawInts("Pset", "", IntList())
End Sub
Sub QPRINTER.Paint(ByVal X1 As Long, ByVal Y1 As Long, ByVal FillColor As Long, ByVal BorderColor As Long)
    Dim IntList(0 To 3) As Long = {X1, Y1, FillColor, BorderColor}
    DrawInts("Paint", "", IntList())
End Sub
' Картинка - файл .bmp или "" (кэш: Obj.Draw(0, 0, Bitmap.BMP))
Sub QPRINTER.Draw(ByVal X1 As Long, ByVal Y1 As Long, ByRef BmpText As String)
    Dim IntList(0 To 1) As Long = {X1, Y1}
    DrawInts("Draw", BmpText, IntList())
End Sub
Sub QPRINTER.StretchDraw(ByRef DstRect As QRECT, ByRef BmpText As String)
    Dim IntList(0 To 3) As Long = {DstRect.Left, DstRect.Top, DstRect.Right, DstRect.Bottom}
    DrawInts("StretchDraw", BmpText, IntList())
End Sub
Sub QPRINTER.TextRect(ByRef ClipRect As QRECT, ByVal X1 As Long, ByVal Y1 As Long, ByRef Text1 As String, ByVal TextColor As Long, ByVal BackColor As Long = -1)
    Dim IntList(0 To 7) As Long = {ClipRect.Left, ClipRect.Top, ClipRect.Right, ClipRect.Bottom, X1, Y1, TextColor, BackColor}
    DrawInts("TextRect", Text1, IntList())
End Sub
Sub QPRINTER.CopyRectPtr(ByRef DstRect As QRECT, ByVal SourcePtr As Any Ptr, ByRef SrcRect As QRECT)
    Dim IntList(0 To 7) As Long = {DstRect.Left, DstRect.Top, DstRect.Right, DstRect.Bottom, _
        SrcRect.Left, SrcRect.Top, SrcRect.Right, SrcRect.Bottom}
    If RqCallObjInts(Obj(), "CopyRect", SourcePtr, @IntList(0), 8) = 0 Then RqLclClassError("QPRINTER.CopyRect")
End Sub
' Source - QIMAGE, QCANVAS, QBITMAP, QFORM (у кого есть холст)
Sub QPRINTER.CopyRect(ByRef DstRect As QRECT, ByRef Source As QCONTROL, ByRef SrcRect As QRECT)
    CopyRectPtr(DstRect, Source.RqObj, SrcRect)
End Sub
' Поворот пока не сделан - ошибка
Sub QPRINTER.Rotate(ByVal X1 As Long, ByVal Y1 As Long, ByVal Angle As Long)
    If RqCallEx(Obj(), "Rotate", 0, X1, Y1, Angle, 0, 0) = 0 Then RqLclClassError("QPRINTER.Rotate")
End Sub
Function QPRINTER.TextWidth(ByRef Text1 As String) As Long
    Return RqCallEx(Obj(), "TextWidth", StrPtr(Text1), 0, 0, 0, 0, 0)
End Function
Function QPRINTER.TextHeight(ByRef Text1 As String) As Long
    Return RqCallEx(Obj(), "TextHeight", StrPtr(Text1), 0, 0, 0, 0, 0)
End Function

Dim Shared Printer As QPRINTER

' ---------------------------------------------------------------------------
'  QNOTIFYICONDATA - структура NOTIFYICONDATA Windows для Shell_NotifyIcon
'  (значок в области уведомлений); cbSize ставится сам
' ---------------------------------------------------------------------------

Type QNOTIFYICONDATA
    cbSize As Long
    hWnd As Integer
    uID As Long
    uFlags As Long
    uCallBackMessage As Long
    hIcon As Integer
    szTip As ZString * 64
    Declare Constructor()
End Type

Constructor QNOTIFYICONDATA()
    cbSize = SizeOf(QNOTIFYICONDATA)
End Constructor
