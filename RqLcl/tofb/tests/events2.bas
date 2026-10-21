$APPTYPE CONSOLE
' Events (appendix A): QTREEVIEW OnEditing, OnEdited (BYREF S),
' OnGetImageIndex, OnGetSelectedIndex; QSTRINGGRID OnListDropDown (BYREF S),
' OnEllipsisClick; QFORM OnHint
DECLARE FUNCTION SendMessage LIB "user32" ALIAS "SendMessageA" (hWnd AS LONG, Msg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
DECLARE FUNCTION GetFocus LIB "user32" ALIAS "GetFocus" () AS LONG
DECLARE FUNCTION GetParent LIB "user32" ALIAS "GetParent" (hWnd AS LONG) AS LONG
DECLARE FUNCTION GetWindow LIB "user32" ALIAS "GetWindow" (hWnd AS LONG, uCmd AS LONG) AS LONG
DECLARE FUNCTION SetCursorPos LIB "user32" ALIAS "SetCursorPos" (X AS LONG, Y AS LONG) AS LONG
DECLARE SUB TreeEditing (Index AS INTEGER, AllowEdit AS INTEGER)
DECLARE SUB TreeEdited (Index AS INTEGER, S AS STRING)
DECLARE SUB TreeImage (Index AS INTEGER)
DECLARE SUB TreeSelected (Index AS INTEGER)
DECLARE SUB ListDropDown (Col AS INTEGER, Row AS INTEGER, S AS STRING)
DECLARE SUB Ellipsis (Col AS LONG, Row AS LONG, Sender AS QSTRINGGRID)
DECLARE SUB FormHint (Hint AS STRING)
DIM Editings AS INTEGER, Images AS INTEGER, Selects AS INTEGER, LastHint AS STRING
DIM EditedText AS STRING, DropText AS STRING, EllipsisText AS STRING
$RESOURCE Red_BMP AS "res\red16.bmp"
DIM ImageList1 AS QIMAGELIST
ImageList1.AddBMPHandle Red_BMP, 0

CREATE Form AS QFORM
  Caption = "Events"
  Width = 400 : Height = 300
  OnHint = FormHint
  CREATE Tree1 AS QTREEVIEW
    Width = 150 : Height = 120
    OnEditing = TreeEditing
    OnEdited = TreeEdited
    OnGetImageIndex = TreeImage
    OnGetSelectedIndex = TreeSelected
  END CREATE
  CREATE Grid1 AS QSTRINGGRID
    Left = 160 : Width = 230 : Height = 120
    ColCount = 3 : RowCount = 3
    OnListDropDown = ListDropDown
    OnEllipsisClick = Ellipsis
  END CREATE
  CREATE Button1 AS QBUTTON
    Top = 150 : Left = 20 : Width = 100 : Height = 30
    Hint = "Button hint|Long button hint"
    ShowHint = 1
  END CREATE
END CREATE

SUB TreeEditing (Index AS INTEGER, AllowEdit AS INTEGER)
  Editings = Editings + 1
  IF Index = 1 THEN AllowEdit = 0
END SUB
SUB TreeEdited (Index AS INTEGER, S AS STRING)
  EditedText = STR$(Index) + " " + S
  S = UCASE$(S)
END SUB
SUB TreeImage (Index AS INTEGER)
  Images = Images + 1
END SUB
SUB TreeSelected (Index AS INTEGER)
  Selects = Selects + 1
END SUB
SUB ListDropDown (Col AS INTEGER, Row AS INTEGER, S AS STRING)
  DropText = STR$(Col) + STR$(Row) + " " + STR$(LEN(S))
  S = "x" + CHR$(10) + "y" + CHR$(10) + "z"
END SUB
SUB Ellipsis (Col AS LONG, Row AS LONG, Sender AS QSTRINGGRID)
  EllipsisText = STR$(Col) + STR$(Row)
  Sender.Cell(Col, Row) = "clicked"
END SUB
SUB FormHint (Hint AS STRING)
  LastHint = Hint
END SUB

Tree1.AddItems "one", "two"
Tree1.Images = ImageList1
Form.Show
DOEVENTS
PRINT "images "; Images > 0; Selects > 0
' F2 - edit the selected node; Enter in the editor ends editing
Tree1.ItemIndex = 0
Tree1.SetFocus
DOEVENTS
SendMessage Tree1.Handle, &H100, 113, 0
DOEVENTS
SendMessage GetFocus, &H100, 13, 0
DOEVENTS
PRINT "edited "; Editings; " "; EditedText; " -> "; Tree1.Item(0).Text
Tree1.ItemIndex = 1
SendMessage Tree1.Handle, &H100, 113, 0
DOEVENTS
PRINT "editings "; Editings; " focus on tree "; GetFocus = Tree1.Handle
' Grid: drop-down list column
Grid1.AddOptions 10
Grid1.ColumnStyle(1) = 0
Grid1.ColumnList(1) = "10" + CHR$(10) + "11"
Grid1.Col = 1 : Grid1.Row = 1
Grid1.SetFocus
Grid1.EditorMode = 1
DOEVENTS
DIM Combo AS LONG
Combo = GetFocus
' combobox with an edit field: the focus is on its edit
IF SendMessage(Combo, &H146, 0, 0) <= 0 THEN Combo = GetParent(Combo)
PRINT "items before "; SendMessage(Combo, &H146, 0, 0)
SendMessage Combo, &H14F, 1, 0
DOEVENTS
PRINT "dropdown "; DropText; " items "; SendMessage(Combo, &H146, 0, 0)
SendMessage Combo, &H14F, 0, 0
Grid1.EditorMode = 0
' Grid: ellipsis column; the button is the sibling of the cell editor
Grid1.ColumnStyle(2) = 1
Grid1.Col = 2 : Grid1.Row = 2
Grid1.EditorMode = 1
DOEVENTS
DIM Child AS LONG
Child = GetWindow(GetParent(GetFocus), 5)
WHILE Child <> 0
  IF Child <> GetFocus THEN SendMessage Child, &HF5, 0, 0
  Child = GetWindow(Child, 2)
WEND
DOEVENTS
Grid1.EditorMode = 0
PRINT "ellipsis "; EllipsisText; " "; Grid1.Cell(2, 2)
' Hint: mouse over the button
Form.SetFocus
SetCursorPos Form.Left + 60, Form.Top + 200
SendMessage Button1.Handle, &H200, 0, &H00050005
DOEVENTS
PRINT "hint "; LastHint
Form.Close
