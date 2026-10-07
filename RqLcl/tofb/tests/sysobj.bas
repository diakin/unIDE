$APPTYPE CONSOLE
' QTIMER, QOPENDIALOG, QSAVEDIALOG, Application, Screen, Clipboard, DIR$ и FileRec
DECLARE FUNCTION FindWindowA LIB "user32" ALIAS "FindWindowA" (ClassName AS LONG, WindowName AS STRING) AS LONG
DECLARE FUNCTION PostMessageA LIB "user32" ALIAS "PostMessageA" (hwnd AS LONG, wMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
DECLARE SUB TimerOver
DECLARE SUB CloseDialog
DIM Ticks AS INTEGER, Waits AS INTEGER, Found AS INTEGER
DIM Name$ AS STRING, Size AS INTEGER
DIM Names AS QSTRINGLIST
DIM Open1 AS QOPENDIALOG
DIM Save1 AS QSAVEDIALOG

CREATE Form AS QFORM
  Caption = "System objects"
  Width = 300 : Height = 200
  CREATE Timer1 AS QTIMER
    Interval = 50
    Enabled = 0
    OnTimer = TimerOver
  END CREATE
END CREATE
DIM DlgTimer AS QTIMER
DlgTimer.Enabled = 0
DlgTimer.Interval = 300
DlgTimer.OnTimer = CloseDialog

SUB TimerOver
  Ticks = Ticks + 1
  IF Ticks >= 3 THEN Timer1.Enabled = 0
END SUB

SUB CloseDialog
  DIM Wnd AS LONG
  Wnd = FindWindowA(0, "Pick a file")
  IF Wnd <> 0 THEN
    Found = 1
    PostMessageA(Wnd, &H10, 0, 0)
  END IF
END SUB

' QTIMER
Form.Show
Timer1.Enabled = 1
DO
  DOEVENTS
  Waits = Waits + 1
  SLEEP 0.01
LOOP UNTIL Ticks >= 3 OR Waits > 500
PRINT "timer ticks "; Ticks; " enabled "; Timer1.Enabled; " interval "; Timer1.Interval

' Application
IF RIGHT$(LCASE$(Application.ExeName), 4) = ".exe" AND INSTR(Application.ExeName, "\") = 0 THEN PRINT "exe name ok" ELSE PRINT "exe "; Application.ExeName
Application.Title = "My title"
PRINT "title "; Application.Title
Application.HintPause = 100
Application.HintColor = &H7AFF59
PRINT "hint "; Application.HintPause; " "; HEX$(Application.HintColor)

' Screen
IF Screen.Width > 0 AND Screen.Height > 0 THEN PRINT "screen ok" ELSE PRINT "screen 0"

' Clipboard
Clipboard.Text = "clip text"
PRINT "clipboard "; Clipboard.Text; " has text "; (Clipboard.HasFormat(1) <> 0)
Clipboard.Clear
PRINT "after clear ["; Clipboard.Text; "]"

' QOPENDIALOG, QSAVEDIALOG
Open1.Caption = "Pick a file"
Open1.Filter = "Text|*.txt|All|*.*"
Open1.FilterIndex = 2
Open1.InitialDir = "C:\"
PRINT "open "; Open1.Caption; " "; Open1.Filter; " "; Open1.FilterIndex; " "; Open1.InitialDir
DlgTimer.Enabled = 1
PRINT "execute "; Open1.Execute; " dialog found "; Found
DlgTimer.Enabled = 0
Save1.FileName = "out.bas"
PRINT "save "; Save1.FileName

' DIR$ и FileRec
MKDIR "dirtest"
MKDIR "dirtest\sub"
OPEN "dirtest\a.txt" FOR OUTPUT AS #1
PRINT #1, "12345"
CLOSE #1
OPEN "dirtest\b.bas" FOR OUTPUT AS #1
CLOSE #1
Names.Sorted = 1
Name$ = DIR$("dirtest\*.*", 0)
WHILE Name$ <> ""
  Names.AddItems Name$
  Name$ = DIR$
WEND
PRINT "files: "; Names.ItemCount; " "; Names.Item(0); " "; Names.Item(1)
Names.Clear
Name$ = DIR$("dirtest\*", &H10)
WHILE Name$ <> ""
  Names.AddItems Name$
  Name$ = DIR$
WEND
PRINT "with dirs: "; Names.ItemCount; " "; Names.Item(Names.ItemCount - 1)
Name$ = DIR$("dirtest\a.txt", 0)
PRINT "a.txt size "; FileRec.Size; " date len "; LEN(FileRec.Date); " "; MID$(FileRec.Date, 3, 1); MID$(FileRec.Date, 6, 1); " time len "; LEN(FileRec.Time)
IF FileRec.FileTime > 0 THEN PRINT "filetime ok"
PRINT "none ["; DIR$("dirtest\*.xyz", 0); "]"
KILL "dirtest\a.txt"
KILL "dirtest\b.bas"
RMDIR "dirtest\sub"
RMDIR "dirtest"

' Application.Terminate: следующий DOEVENTS заканчивает программу
PRINT "terminate"
Application.Terminate
DOEVENTS
PRINT "not printed"
