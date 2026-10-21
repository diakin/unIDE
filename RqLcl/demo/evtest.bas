#include once "rqlcl.bi"
Declare Function EvSendMessage Lib "user32" Alias "SendMessageA" (ByVal Wnd As Any Ptr, ByVal Msg As ULong, ByVal WParam As UInteger, ByVal LParam As Integer) As Integer
Dim Shared Form As QFORM
Dim Shared Edit1 As QEDIT
Dim Shared Grid As QSTRINGGRID
Dim Shared Btn As QBUTTON
Dim Shared FailCount As Long
Dim Shared LastKey As Long, LastShift As Long, KeyUpCount As Long, PressKey As Long
Dim Shared MouseBtn As Long, MouseX As Long, MouseY As Long, PlainCount As Long, SenderOk As Long
Dim Shared SelCol As Long, SelRow As Long, DrawCount As Long, DrawRectOk As Long
Sub Check(ByVal Passed As Long, ByRef What As String)
    If Passed Then
        Print "ok   "; What
    Else
        Print "FAIL "; What
        FailCount += 1
    End If
End Sub
Sub EditKeyDown(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QEDIT)
    LastKey = Key : LastShift = Shift
    If @Sender = @Edit1 Then SenderOk = 1
End Sub
Sub EditKeyUp()
    KeyUpCount += 1
End Sub
Sub EditKeyPress(ByRef Key As Long)
    PressKey = Key
    If Key = Asc("x") Then Key = 0     ' РЅРµ РІРІРѕРґРёС‚СЊ x
End Sub
Sub BtnMouseDown(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long)
    MouseBtn = Button : MouseX = X : MouseY = Y
End Sub
Sub BtnMouseUp(ByRef Sender As QBUTTON)
    PlainCount += 1
End Sub
Sub GridSelect(ByVal Col As Long, ByVal Row As Long, ByRef CanSelect As Long)
    SelCol = Col : SelRow = Row
    If Col = 4 Then CanSelect = 0       ' СЃС‚РѕР»Р±РµС† 4 РІС‹Р±СЂР°С‚СЊ РЅРµР»СЊР·СЏ
End Sub
Sub GridDraw(ByVal Col As Long, ByVal Row As Long, ByVal State As Long, ByRef R As QRECT, ByRef Sender As QSTRINGGRID)
    DrawCount += 1
    If (R.Right > R.Left) And (R.Bottom > R.Top) Then DrawRectOk = 1
    If (Col = 1) And (Row = 1) Then
        Sender.FillRect(R.Left, R.Top, R.Right, R.Bottom, &h83FFFF)
        Sender.TextOut(R.Left + 2, R.Top + 2, "drawn", 0, -1)
    End If
End Sub
Sub FormShow()
    Edit1.SetFocus
    EvSendMessage(Cast(Any Ptr, Edit1.Handle), &h100, 65, 0)    ' WM_KEYDOWN 'A'
    EvSendMessage(Cast(Any Ptr, Edit1.Handle), &h101, 65, 0)    ' WM_KEYUP
    Check(LastKey = 65, "keydown key " & LastKey)
    Check(SenderOk = 1, "keydown sender")
    Check(KeyUpCount = 1, "keyup plain")
    EvSendMessage(Cast(Any Ptr, Edit1.Handle), &h102, Asc("b"), 0)  ' WM_CHAR
    Check(PressKey = Asc("b"), "keypress " & PressKey)
    EvSendMessage(Cast(Any Ptr, Edit1.Handle), &h102, 226, 0)       ' 'РІ' CP1251
    Check(PressKey = 226, "keypress cyrillic " & PressKey)
    EvSendMessage(Cast(Any Ptr, Edit1.Handle), &h102, Asc("x"), 0)
    Check(InStr(Edit1.Text, "x") = 0, "keypress cancel, text [" & Edit1.Text & "]")
    EvSendMessage(Cast(Any Ptr, Btn.Handle), &h201, 1, (7 Shl 16) Or 5)   ' WM_LBUTTONDOWN x=5 y=7
    EvSendMessage(Cast(Any Ptr, Btn.Handle), &h202, 0, (7 Shl 16) Or 5)
    Check(MouseBtn = 0 And MouseX = 5 And MouseY = 7, "mousedown " & MouseBtn & " " & MouseX & "," & MouseY)
    Check(PlainCount = 1, "mouseup sender only")
    Grid.Row = 2 : Grid.Col = 3
    Check(SelCol = 3 And SelRow = 2, "selectcell " & SelCol & "," & SelRow)
    Grid.Col = 4
    Check(Grid.Col = 3, "selectcell canselect=0, col " & Grid.Col)
    For WaitIdx As Long = 1 To 30
        DoEvents
        Sleep 10
        If DrawCount > 0 Then Exit For
    Next
    Check(DrawCount > 0 And DrawRectOk = 1, "drawcell " & DrawCount)
    Form.Close
End Sub
Edit1.Parent = Form
Btn.Parent = Form : Btn.Top = 40
Grid.Parent = Form : Grid.Top = 80
Grid.SetCell(1, 1, "cell")
Edit1.OnKeyDown = @EditKeyDown
Edit1.OnKeyUp = @EditKeyUp
Edit1.OnKeyPress = @EditKeyPress
Btn.OnMouseDown = @BtnMouseDown
Btn.OnMouseUp = @BtnMouseUp
Grid.OnSelectCell = @GridSelect
Grid.OnDrawCell = @GridDraw
Form.Show
For WaitIdx As Long = 1 To 30
    DoEvents
    Sleep 10
Next
FormShow()
Print "FAILS="; FailCount
