$APPTYPE CONSOLE
DECLARE FUNCTION SendMessage LIB "user32" ALIAS "SendMessageA" (hWnd AS LONG, Msg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
DECLARE SUB EditKeyDown (Key AS WORD, Shift AS INTEGER, Sender AS QEDIT)
DECLARE SUB GridSelect (Col%, Row%, CanSelect%, Sender AS QSTRINGGRID)
DECLARE SUB GridDraw (Col%, Row%, State%, Rect AS QRect, Sender AS QStringGrid)
DECLARE SUB EditPress (Key AS BYTE)
DECLARE SUB BtnDown
CONST goEditing = 10
CONST goTabs = 11
DIM DrawCount AS INTEGER

CREATE Form AS QFORM
    Caption = "Create test"
    Width = 500: Height = 400
    CREATE Edit1 AS QEDIT
        Left = 10: Top = 10: Width = 200
        OnKeyDown = EditKeyDown
        OnKeyPress = EditPress
    END CREATE
    CREATE Btn AS QBUTTON
        Left = 10: Top = 40
        Caption = "Btn"
        OnMouseDown = BtnDown
    END CREATE
    CREATE Grid AS QSTRINGGRID
        Top = 80: Left = 10
        ColCount = 4
        RowCount = 5
        Separator = "~"
        AddOptions = goEditing, goTabs
        Cell(1, 1) = "a"
        ColWidths(1) = 80
        OnSelectCell = GridSelect
        OnDrawCell = GridDraw
    END CREATE
END CREATE

SUB EditKeyDown (Key AS WORD, Shift AS INTEGER, Sender AS QEDIT)
    PRINT "keydown "; Key; " "; Shift; " "; Sender.Left
END SUB

SUB EditPress (Key AS BYTE)
    PRINT "press "; Key
END SUB

SUB BtnDown
    PRINT "btn down"
END SUB

SUB GridSelect (Col%, Row%, CanSelect%, Sender AS QSTRINGGRID)
    PRINT "select "; Col%; " "; Row%
    IF Col% = 3 THEN CanSelect% = 0
END SUB

SUB GridDraw (Col%, Row%, State%, Rect AS QRect, Sender AS QStringGrid)
    IF Col% = 1 AND Row% = 1 THEN
        DrawCount = DrawCount + 1
        Sender.FillRect(Rect.Left, Rect.Top, Rect.Right, Rect.Bottom, &H83FFFF)
        Sender.TextOut(Rect.Left + 2, Rect.Top + 2, "x", 0, -1)
    END IF
END SUB

Form.Show
FOR i = 1 TO 300
    DOEVENTS
NEXT i
SendMessage(Edit1.Handle, &H100, 65, 0)
SendMessage(Edit1.Handle, &H102, 98, 0)
SendMessage(Btn.Handle, &H201, 1, 0)
Grid.Row = 2: Grid.Col = 2
Grid.Col = 3
PRINT "col "; Grid.Col
PRINT "cell "; Grid.Cell(1, 1); " width "; Grid.ColWidths(1)
IF DrawCount > 0 THEN PRINT "drawn" ELSE PRINT "not drawn"
PRINT "edit left "; Edit1.Left; " form "; Form.Caption
Form.Close
