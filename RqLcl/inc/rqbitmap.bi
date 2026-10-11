' ---------------------------------------------------------------------------
'  RqLcl: QBITMAP - невидимая картинка с холстом (TBitmap). Подключается из
'  rqlcl.bi. Тип - наследник QCONTROL (как элементы), чтобы QBITMAP
'  принимали CopyRect и ImageList.Draw; Left, Visible и др. у него не
'  действуют. Font - шрифт холста.
'
'  BMP: чтение кладёт картинку в кэш DLL и возвращает "" (Image.BMP =
'  Bitmap.BMP, Canvas.Draw(0, 0, Bitmap.BMP)); запись - файл или "" (кэш).
'  CopyMode - код растровой операции Windows (cmSrcCopy = &HCC0020, rapidq2.inc;
'  номера 0..14 из документации RapidQ не работают - тест 2026-10-11).
'  PixelFormat: pfDevice 0, pf1bit 1, pf4bit 2, pf8bit 3, pf15bit 4,
'  pf16bit 5, pf24bit 6, pf32bit 7.
' ---------------------------------------------------------------------------

Type QBITMAP Extends QCONTROL
    Declare Constructor()
    Declare Property Height() As Long
    Declare Property Height(ByVal Value As Long)
    Declare Property Width() As Long
    Declare Property Width(ByVal Value As Long)
    Declare Property Monochrome() As Long
    Declare Property Monochrome(ByVal Value As Long)
    Declare Property PixelFormat() As Long
    Declare Property PixelFormat(ByVal Value As Long)
    Declare Property Top() As Long
    Declare Property Top(ByVal Value As Long)
    Declare Property Transparent() As Long
    Declare Property Transparent(ByVal Value As Long)
    Declare Property TransparentColor() As Long
    Declare Property TransparentColor(ByVal Value As Long)
    Declare Property TransparentMode() As Long
    Declare Property TransparentMode(ByVal Value As Long)
    Declare Property Handle() As Long
    Declare Property Handle(ByVal Value As Long)
    Declare Property Empty() As Long
    Declare Property BMP() As String
    Declare Property BMP(ByRef Value As String)
    Declare Property BMPHandle(ByVal Value As Long)
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
    Declare Sub LoadFromFile(ByRef FileName As String)
    Declare Sub SaveToFile(ByRef FileName As String)
    Declare Sub LoadFromStream(ByRef Stream As RqStream)
    Declare Sub SaveToStream(ByRef Stream As RqStream)
    Declare Function TempName() As String
End Type

Constructor QBITMAP()
    RqObj = RqLclNew("QBITMAP", @This)
End Constructor
Property QBITMAP.Height() As Long
    Return RqGetInt(RqObj, "Height")
End Property
Property QBITMAP.Height(ByVal Value As Long)
    RqLclSetInt(RqObj, "Height", Value)
End Property
Property QBITMAP.Width() As Long
    Return RqGetInt(RqObj, "Width")
End Property
Property QBITMAP.Width(ByVal Value As Long)
    RqLclSetInt(RqObj, "Width", Value)
End Property
Property QBITMAP.Monochrome() As Long
    Return RqGetInt(RqObj, "Monochrome")
End Property
Property QBITMAP.Monochrome(ByVal Value As Long)
    RqLclSetInt(RqObj, "Monochrome", Value)
End Property
Property QBITMAP.PixelFormat() As Long
    Return RqGetInt(RqObj, "PixelFormat")
End Property
Property QBITMAP.PixelFormat(ByVal Value As Long)
    RqLclSetInt(RqObj, "PixelFormat", Value)
End Property
Property QBITMAP.Top() As Long
    Return RqGetInt(RqObj, "Top")
End Property
Property QBITMAP.Top(ByVal Value As Long)
    RqLclSetInt(RqObj, "Top", Value)
End Property
Property QBITMAP.Transparent() As Long
    Return RqGetInt(RqObj, "Transparent")
End Property
Property QBITMAP.Transparent(ByVal Value As Long)
    RqLclSetInt(RqObj, "Transparent", Value)
End Property
Property QBITMAP.TransparentColor() As Long
    Return RqGetInt(RqObj, "TransparentColor")
End Property
Property QBITMAP.TransparentColor(ByVal Value As Long)
    RqLclSetInt(RqObj, "TransparentColor", Value)
End Property
Property QBITMAP.TransparentMode() As Long
    Return RqGetInt(RqObj, "TransparentMode")
End Property
Property QBITMAP.TransparentMode(ByVal Value As Long)
    RqLclSetInt(RqObj, "TransparentMode", Value)
End Property
Property QBITMAP.Handle() As Long
    Return RqGetInt(RqObj, "Handle")
End Property
Property QBITMAP.Handle(ByVal Value As Long)
    RqLclSetInt(RqObj, "Handle", Value)
End Property
Property QBITMAP.Empty() As Long
    Return RqGetInt(RqObj, "Empty")
End Property
Property QBITMAP.BMP() As String
    Return RqLclGetStr(RqObj, "BMP")
End Property
Property QBITMAP.BMP(ByRef Value As String)
    RqLclSetStr(RqObj, "BMP", Value)
End Property
Property QBITMAP.BMPHandle(ByVal Value As Long)
    RqLclSetInt(RqObj, "BMPHandle", Value)
End Property
Property QBITMAP.CopyMode() As Long
    Return RqGetInt(RqObj, "CopyMode")
End Property
Property QBITMAP.CopyMode(ByVal Value As Long)
    RqLclSetInt(RqObj, "CopyMode", Value)
End Property
' Pixel(x, y) - цвет точки; Obj.Pixel(x, y) = c - препроцессор: SetPixel
Function QBITMAP.Pixel(ByVal X As Long, ByVal Y As Long) As Long
    Return RqCallEx(RqObj, "GetPixel", 0, X, Y, 0, 0, 0)
End Function
Sub QBITMAP.SetPixel(ByVal X As Long, ByVal Y As Long, ByVal PixelColor As Long)
    If RqCallEx(RqObj, "SetPixel", 0, X, Y, PixelColor, 0, 0) = 0 Then RqLclClassError("QBITMAP.Pixel")
End Sub
Sub QBITMAP.DrawInts(ByRef MethodName As String, ByRef Text1 As String, IntList() As Long)
    If RqCallInts(RqObj, MethodName, StrPtr(Text1), @IntList(0), UBound(IntList) + 1) = 0 Then
        RqLclClassError("QBITMAP." & MethodName)
    End If
End Sub
' BackColor = -1 - фон прозрачный
Sub QBITMAP.TextOut(ByVal X1 As Long, ByVal Y1 As Long, ByRef Text1 As String, ByVal TextColor As Long, ByVal BackColor As Long = -1)
    Dim IntList(0 To 3) As Long = {X1, Y1, TextColor, BackColor}
    DrawInts("TextOut", Text1, IntList())
End Sub
Sub QBITMAP.FillRect(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal FillColor As Long)
    Dim IntList(0 To 4) As Long = {X1, Y1, X2, Y2, FillColor}
    DrawInts("FillRect", "", IntList())
End Sub
Sub QBITMAP.Line(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal LineColor As Long)
    Dim IntList(0 To 4) As Long = {X1, Y1, X2, Y2, LineColor}
    DrawInts("Line", "", IntList())
End Sub
Sub QBITMAP.Rectangle(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal LineColor As Long)
    Dim IntList(0 To 4) As Long = {X1, Y1, X2, Y2, LineColor}
    DrawInts("Rectangle", "", IntList())
End Sub
Sub QBITMAP.RoundRect(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal X3 As Long, ByVal Y3 As Long, ByVal FillColor As Long)
    Dim IntList(0 To 6) As Long = {X1, Y1, X2, Y2, X3, Y3, FillColor}
    DrawInts("RoundRect", "", IntList())
End Sub
Sub QBITMAP.Circle(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long, ByVal LineColor As Long, ByVal FillFlag As Long)
    Dim IntList(0 To 5) As Long = {X1, Y1, X2, Y2, LineColor, FillFlag}
    DrawInts("Circle", "", IntList())
End Sub
Sub QBITMAP.Pset(ByVal X1 As Long, ByVal Y1 As Long, ByVal PixelColor As Long)
    Dim IntList(0 To 2) As Long = {X1, Y1, PixelColor}
    DrawInts("Pset", "", IntList())
End Sub
Sub QBITMAP.Paint(ByVal X1 As Long, ByVal Y1 As Long, ByVal FillColor As Long, ByVal BorderColor As Long)
    Dim IntList(0 To 3) As Long = {X1, Y1, FillColor, BorderColor}
    DrawInts("Paint", "", IntList())
End Sub
' Картинка - файл .bmp или "" (кэш: Obj.Draw(0, 0, Bitmap.BMP))
Sub QBITMAP.Draw(ByVal X1 As Long, ByVal Y1 As Long, ByRef BmpText As String)
    Dim IntList(0 To 1) As Long = {X1, Y1}
    DrawInts("Draw", BmpText, IntList())
End Sub
Sub QBITMAP.StretchDraw(ByRef DstRect As QRECT, ByRef BmpText As String)
    Dim IntList(0 To 3) As Long = {DstRect.Left, DstRect.Top, DstRect.Right, DstRect.Bottom}
    DrawInts("StretchDraw", BmpText, IntList())
End Sub
Sub QBITMAP.TextRect(ByRef ClipRect As QRECT, ByVal X1 As Long, ByVal Y1 As Long, ByRef Text1 As String, ByVal TextColor As Long, ByVal BackColor As Long = -1)
    Dim IntList(0 To 7) As Long = {ClipRect.Left, ClipRect.Top, ClipRect.Right, ClipRect.Bottom, X1, Y1, TextColor, BackColor}
    DrawInts("TextRect", Text1, IntList())
End Sub
Sub QBITMAP.CopyRectPtr(ByRef DstRect As QRECT, ByVal SourcePtr As Any Ptr, ByRef SrcRect As QRECT)
    Dim IntList(0 To 7) As Long = {DstRect.Left, DstRect.Top, DstRect.Right, DstRect.Bottom, _
        SrcRect.Left, SrcRect.Top, SrcRect.Right, SrcRect.Bottom}
    If RqCallObjInts(RqObj, "CopyRect", SourcePtr, @IntList(0), 8) = 0 Then RqLclClassError("QBITMAP.CopyRect")
End Sub
' Source - QIMAGE, QCANVAS, QBITMAP, QFORM (у кого есть холст)
Sub QBITMAP.CopyRect(ByRef DstRect As QRECT, ByRef Source As QCONTROL, ByRef SrcRect As QRECT)
    CopyRectPtr(DstRect, Source.RqObj, SrcRect)
End Sub
' Поворот пока не сделан - ошибка
Sub QBITMAP.Rotate(ByVal X1 As Long, ByVal Y1 As Long, ByVal Angle As Long)
    If RqCallEx(RqObj, "Rotate", 0, X1, Y1, Angle, 0, 0) = 0 Then RqLclClassError("QBITMAP.Rotate")
End Sub
Function QBITMAP.TextWidth(ByRef Text1 As String) As Long
    Return RqCallEx(RqObj, "TextWidth", StrPtr(Text1), 0, 0, 0, 0, 0)
End Function
Function QBITMAP.TextHeight(ByRef Text1 As String) As Long
    Return RqCallEx(RqObj, "TextHeight", StrPtr(Text1), 0, 0, 0, 0, 0)
End Function
Sub QBITMAP.LoadFromFile(ByRef FileName As String)
    If RqCallEx(RqObj, "LoadFromFile", StrPtr(FileName), 0, 0, 0, 0, 0) = 0 Then RqLclClassError("QBITMAP.LoadFromFile")
End Sub
Sub QBITMAP.SaveToFile(ByRef FileName As String)
    If RqCallEx(RqObj, "SaveToFile", StrPtr(FileName), 0, 0, 0, 0, 0) = 0 Then RqLclClassError("QBITMAP.SaveToFile")
End Sub
' Поток - через временный файл (строки DLL не передают нулевые байты)
Function QBITMAP.TempName() As String
    Dim TempDir As String = Environ("TEMP")
    If TempDir = "" Then TempDir = "."
    Return TempDir & "\rqlcl_bmp_" & Hex(Cast(UInteger, @This)) & ".bmp"
End Function
' Из потока - от текущей позиции до конца
Sub QBITMAP.LoadFromStream(ByRef Stream As RqStream)
    Dim DataLen As Long = Stream.Size - Stream.Position
    Dim StreamText As String
    If DataLen > 0 Then
        StreamText = Space(DataLen)
        DataLen = Stream.ReadBuf(StrPtr(StreamText), DataLen)
        StreamText = Mid(StreamText, 1, DataLen)
    End If
    Dim FileName As String = TempName()
    Dim FileNum As Long = FreeFile
    If Open(FileName For Binary Access Write As #FileNum) <> 0 Then
        RqRtClassError("QBITMAP.LoadFromStream: cannot write " & FileName)
        Exit Sub
    End If
    If Len(StreamText) > 0 Then Put #FileNum, , StreamText
    Close #FileNum
    LoadFromFile(FileName)
    Kill FileName
End Sub
' В поток с текущей позиции
Sub QBITMAP.SaveToStream(ByRef Stream As RqStream)
    Dim FileName As String = TempName()
    SaveToFile(FileName)
    Dim FileNum As Long = FreeFile
    If Open(FileName For Binary Access Read As #FileNum) <> 0 Then
        RqRtClassError("QBITMAP.SaveToStream: cannot read " & FileName)
        Exit Sub
    End If
    Dim StreamText As String = Space(LOF(FileNum))
    If Len(StreamText) > 0 Then Get #FileNum, , StreamText
    Close #FileNum
    Kill FileName
    If Len(StreamText) > 0 Then Stream.WriteBuf(StrPtr(StreamText), Len(StreamText))
End Sub
