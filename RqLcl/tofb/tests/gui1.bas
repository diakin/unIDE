$APPTYPE CONSOLE
$INCLUDE "mylib.inc"
$DEFINE DEBUGMODE
DECLARE SUB ShowInfo (Msg AS STRING)

DIM Form AS QFORM
DIM Label1 AS QLABEL
DIM Edit1 AS QEDIT
DIM Button1 AS QBUTTON
DEFINT Clicks = 0
DIM Names$(3)

SUB ShowInfo (Msg AS STRING)
  Total = Total + 1  ' неявная переменная модуля (есть ниже)
  Local1 = 7         ' неявная локальная
  PRINT "info: "; Msg; " "; Total; " "; Local1
END SUB

FUNCTION Describe$ (N AS INTEGER)
  SELECT CASE N
    CASE 1: Describe$ = "one"
    CASE 2: Describe$ = "two"
    CASE ELSE: Describe$ = "many"
  END SELECT
END FUNCTION

SUB Button1Click
  INC Clicks
  Label1.Caption = "Clicks: " + STR$(Clicks) + " " + Describe$(Clicks)
END SUB

SUB FormShow
  FOR i = 1 TO 3
    Button1.Click
  NEXT i
  IF Clicks = 3 THEN PRINT "clicks ok" ELSE PRINT "clicks FAIL"
  PRINT Label1.Caption
  Edit1.Text = Greeting$ + " " + STR$(Twice(21))
  PRINT Edit1.Text
  Form.Close
END SUB

Total = 100
$IFDEF DEBUGMODE
ShowInfo "debug on"
$ELSE
ShowInfo "debug off"
$ENDIF
$IFNDEF DEBUGMODE
PRINT "must not print"
$ENDIF

Names$(1) = "x" : Names$(2) = 5
PRINT "names: "; Names$(1); "["; Names$(2); "]"

$ESCAPECHARS ON
PRINT "tab:\tend \x41\66"
$ESCAPECHARS OFF

Form.Caption = "gui1"
Form.Width = 300 : Form.Height = 150
Label1.Parent = Form
Label1.Top = 10 : Label1.Left = 10
Edit1.Parent = Form
Edit1.Top = 40 : Edit1.Left = 10
Button1.Parent = Form
Button1.Top = 80 : Button1.Left = 10
Button1.Caption = "Go"
Button1.OnClick = Button1Click
Form.OnShow = FormShow
Form.ShowModal
PRINT "end, Total="; Total
