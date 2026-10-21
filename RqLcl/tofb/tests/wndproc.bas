$APPTYPE CONSOLE
' WndProc (QFORM, QEDIT, QLISTBOX, QLABEL): messages through SendMessage and
' PostMessage, WM_COPYDATA (not passed on by LCL), window recreated by
' BorderStyle, handler with Sender, mouse message of a label
DECLARE FUNCTION SendMessage LIB "user32" ALIAS "SendMessageA" (hWnd AS LONG, Msg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
DECLARE FUNCTION PostMessage LIB "user32" ALIAS "PostMessageA" (hWnd AS LONG, Msg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
DECLARE SUB FormWndProc (Hwnd&, uMsg&, wParam&, lParam&)
DECLARE SUB EditWndProc (Hwnd AS LONG, Msg AS LONG, wParam AS LONG, lParam AS LONG, Sender AS QEDIT)
DECLARE SUB ListWndProc (Hwnd AS INTEGER, Msg AS INTEGER, wParam AS INTEGER, lParam AS INTEGER)
DECLARE SUB LabelWndProc (Hwnd AS LONG, Msg AS LONG, wParam AS LONG, lParam AS LONG)
CONST WM_USER = &H400
CONST WM_COPYDATA = &H4A
CONST WM_LBUTTONDOWN = &H201
CONST WM_LBUTTONUP = &H202
DIM FormUser AS INTEGER, FormCopy AS INTEGER, FormWnd AS INTEGER, LastParam AS INTEGER
DIM EditUser AS INTEGER, EditSender AS STRING, ListUser AS INTEGER, LabelDown AS INTEGER
CREATE Form AS QFORM
  Caption = "WndProc"
  Width = 300 : Height = 200
  WndProc = FormWndProc
  CREATE Edit1 AS QEDIT
    Text = "edit"
    WndProc = EditWndProc
  END CREATE
  CREATE List1 AS QLISTBOX
    Top = 40
    WndProc = ListWndProc
  END CREATE
  CREATE Label1 AS QLABEL
    Left = 150 : Top = 100 : Width = 60 : Height = 20
    Caption = "label"
    WndProc = LabelWndProc
  END CREATE
END CREATE

SUB FormWndProc (Hwnd&, uMsg&, wParam&, lParam&)
  IF uMsg& = WM_USER + 1 THEN
    FormUser = FormUser + 1
    FormWnd = Hwnd&
    LastParam = wParam& + lParam&
  END IF
  IF uMsg& = WM_COPYDATA THEN FormCopy = FormCopy + 1
END SUB

SUB EditWndProc (Hwnd AS LONG, Msg AS LONG, wParam AS LONG, lParam AS LONG, Sender AS QEDIT)
  IF Msg = WM_USER + 5 THEN
    EditUser = EditUser + 1
    EditSender = Sender.Text
  END IF
END SUB

SUB ListWndProc (Hwnd AS INTEGER, Msg AS INTEGER, wParam AS INTEGER, lParam AS INTEGER)
  IF Msg = WM_USER + 7 THEN ListUser = ListUser + 1
END SUB

SUB LabelWndProc (Hwnd AS LONG, Msg AS LONG, wParam AS LONG, lParam AS LONG)
  IF Msg = WM_LBUTTONDOWN THEN LabelDown = LabelDown + 1
END SUB

' before Show: the window exists already
SendMessage Form.Handle, WM_USER + 1, 2, 3
PRINT "form send "; FormUser; " hwnd "; (FormWnd = Form.Handle); " params "; LastParam
Form.Show
DOEVENTS
PostMessage Form.Handle, WM_USER + 1, 10, 20
DOEVENTS
PRINT "form post "; FormUser; " params "; LastParam
SendMessage Form.Handle, WM_COPYDATA, 0, 0
PRINT "copydata "; FormCopy
SendMessage Edit1.Handle, WM_USER + 5, 0, 0
PRINT "edit "; EditUser; " sender "; EditSender
SendMessage List1.Handle, WM_USER + 7, 0, 0
SendMessage List1.Handle, WM_USER + 7, 0, 0
PRINT "list "; ListUser
' mouse on the label: the form window gets it, LCL passes it to the label
SendMessage Form.Handle, WM_LBUTTONDOWN, 1, (110 * 65536) + 160
SendMessage Form.Handle, WM_LBUTTONUP, 0, (110 * 65536) + 160
DOEVENTS
PRINT "label down "; LabelDown
' new window of the form (LCL RecreateWnd)
DIM OldHandle AS INTEGER
OldHandle = Form.Handle
Form.BorderStyle = 3
DOEVENTS
SendMessage Form.Handle, WM_USER + 1, 1, 1
PRINT "recreated "; (OldHandle <> Form.Handle); " form "; FormUser; " hwnd "; (FormWnd = Form.Handle)
Form.Close
