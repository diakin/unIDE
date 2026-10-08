$APPTYPE CONSOLE
' Members of existing classes (appendix A): QFORM border icons, title bar,
' ShapeForm; QLABEL Angle/LabelStyle; QEDIT PasswordChar/InputMask;
' QBUTTON Kind/Layout/StartDrag; QLISTBOX TabWidth, OnEnter, OnMeasureItem;
' QSTRINGGRID ColumnStyle/ColumnList/TabStops; QTREEVIEW Images, OnDeletion;
' QPOPUPMENU.WindowHandle, QIMAGELIST.Handle, Clipboard.Format,
' Application.IcoHandle; streams SaveArray/LoadArray, WriteUDT/ReadUDT,
' ExtractRes; Rotate; QIMAGE Center method
$RESOURCE Red_BMP AS "res\red16.bmp"
$RESOURCE Green_ICO AS "res\green16.ico"
$RESOURCE Note_TXT AS "res\note.txt"
DECLARE FUNCTION GetWindowLong LIB "user32" ALIAS "GetWindowLongA" (hWnd AS LONG, nIndex AS LONG) AS LONG
DECLARE FUNCTION SendMessage LIB "user32" ALIAS "SendMessageA" (hWnd AS LONG, Msg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
DECLARE SUB ListEnter
DECLARE SUB Measure (Index AS INTEGER, Height AS INTEGER)
DECLARE SUB Deleted (Index AS INTEGER)
TYPE TTest
  S AS STRING*8
  N AS INTEGER
END TYPE
DIM Enters AS INTEGER, Measures AS INTEGER, LastDeleted AS INTEGER
LastDeleted = -1

CREATE Form AS QFORM
  Caption = "Members"
  Width = 400 : Height = 300
  CREATE Label1 AS QLABEL
    Caption = "Label"
    Angle = 90
    LabelStyle = 1
  END CREATE
  CREATE Edit1 AS QEDIT
    Left = 60
    PasswordChar = "*"
  END CREATE
  CREATE Edit2 AS QEDIT
    Left = 200
    InputMask = "00-00;1;_"
  END CREATE
  CREATE Button1 AS QBUTTON
    Top = 40
    Kind = 1
    Layout = 2
  END CREATE
  CREATE List1 AS QLISTBOX
    Top = 80 : Height = 80
    Style = 2
    TabWidth = 40
    OnEnter = ListEnter
    OnMeasureItem = Measure
  END CREATE
  CREATE Grid1 AS QSTRINGGRID
    Left = 150 : Top = 80 : Width = 200 : Height = 100
    ColCount = 4 : RowCount = 3
  END CREATE
  CREATE Tree1 AS QTREEVIEW
    Top = 170 : Height = 80
    OnDeletion = Deleted
  END CREATE
  CREATE Image1 AS QIMAGE
    Left = 300 : Top = 200 : Width = 40 : Height = 40
  END CREATE
END CREATE
DIM Popup AS QPOPUPMENU
DIM Images AS QIMAGELIST

SUB ListEnter
  Enters = Enters + 1
END SUB
SUB Measure (Index AS INTEGER, Height AS INTEGER)
  Measures = Measures + 1
  Height = 20 + Index
END SUB
SUB Deleted (Index AS INTEGER)
  LastDeleted = Index
END SUB

Form.Show
DOEVENTS
' QFORM
Form.AddBorderIcons 3
Form.DelBorderIcons 1, 2
Form.HideTitleBar
PRINT "caption bit "; (GetWindowLong(Form.Handle, -16) AND &HC00000) = &HC00000
Form.ShowTitleBar
PRINT "caption bit "; (GetWindowLong(Form.Handle, -16) AND &HC00000) = &HC00000
' QLABEL
PRINT "label "; Label1.Angle; Label1.LabelStyle; " "; HEX$(Label1.UpperColor)
Label1.LabelStyle = 2
Label1.Repaint
' QEDIT
PRINT "password "; Edit1.PasswordChar; " masked "; Edit1.IsMasked; Edit2.IsMasked
Edit2.Text = "12-34"
PRINT "mask "; Edit2.InputMask; " "; Edit2.EditText; " "; Edit2.Text
Edit1.PasswordChar = ""
PRINT "password "; LEN(Edit1.PasswordChar)
' QBUTTON
PRINT "button "; Button1.Kind; Button1.Layout
Button1.StartDrag
PRINT "drag "; Button1.Left; Button1.Top
' QLISTBOX
List1.AddItems "a" + CHR$(9) + "b", "c"
DOEVENTS
PRINT "list measures "; Measures > 0; " tab "; List1.TabWidth
SendMessage List1.Handle, &H100, 13, 0
PRINT "enters "; Enters
DIM R AS QRECT
R.Left = 0 : R.Top = 0 : R.Right = 20 : R.Bottom = 10
List1.CopyMode = 12
PRINT "copymode "; List1.CopyMode
List1.TextRect(R, 1, 1, "x", 0, &HFFFFFF)
List1.CopyRect(R, Image1, R)
Grid1.TextRect(R, 1, 1, "y", 0, -1)
' QSTRINGGRID
Grid1.ColumnStyle(1) = 0
Grid1.ColumnList(1) = "10" + CHR$(10) + "11"
Grid1.TabStops(2) = 0
PRINT "grid "; Grid1.ColumnStyle(1); Grid1.ColumnStyle(2); " "; LEN(Grid1.ColumnList(1)); Grid1.TabStops(2); Grid1.TabStops(3)
Grid1.AddOptions 11
Grid1.Col = 1
SendMessage Grid1.Handle, &H100, 9, 0
PRINT "tab to col "; Grid1.Col
' QTREEVIEW
Images.AddBMPHandle Red_BMP, 0
Tree1.Images = Images
Tree1.AddItems "one", "two", "three"
Tree1.DelItems 1
PRINT "deleted "; LastDeleted; Tree1.ItemCount
' QPOPUPMENU, QIMAGELIST
Popup.WindowHandle = 123
PRINT "popup "; Popup.WindowHandle; " imagelist "; Images.Handle <> 0
' Clipboard
Clipboard.SetAsText "clip"
DIM HasText AS INTEGER, FormatIdx AS INTEGER
FOR FormatIdx = 0 TO Clipboard.FormatCount - 1
  IF Clipboard.Format(FormatIdx) = 1 THEN HasText = 1
NEXT
PRINT "clipboard "; HasText; Clipboard.GetAsHandle(1) <> 0
Application.IcoHandle = Green_ICO
' Streams
DIM Mem AS QMEMORYSTREAM
DIM A(1 TO 3) AS LONG, B(1 TO 3) AS LONG, D(5) AS DOUBLE
A(1) = 10 : A(2) = 20 : A(3) = 30 : D(0) = 1.5
Mem.SaveArray(A(1), 3)
Mem.SaveArray(D(), 1)
PRINT "array size "; Mem.Size
Mem.Position = 0
Mem.LoadArray(B(1), 3)
PRINT "array "; B(1); B(2); B(3)
DIM T1 AS TTest, T2 AS TTest
T1.S = "abc" : T1.N = 77
Mem.Position = 0
Mem.WriteUDT(T1)
Mem.Position = 0
Mem.ReadUDT(T2)
PRINT "udt "; RTRIM$(T2.S); T2.N
Mem.Position = 0
Mem.Size = 0
Mem.ExtractRes(Resource(2))
Mem.Position = 0
PRINT "res "; Mem.ReadLine
' Rotate
DIM Bmp AS QBITMAP
Bmp.Width = 20 : Bmp.Height = 10
Bmp.FillRect(0, 0, 20, 10, &HFFFFFF)
Bmp.Pset(15, 5, &HFF)
Bmp.Rotate(10, 5, 180)
PRINT "rotate "; HEX$(Bmp.Pixel(4, 5)); " "; HEX$(Bmp.Pixel(5, 5)); " "; HEX$(Bmp.Pixel(15, 5))
' QIMAGE.Center (method)
Image1.Center
PRINT "center "; Image1.Center
' ShapeForm
Form.ShapeForm(Red_BMP, &HFFFFFF)
PRINT "shaped"
Form.Close
