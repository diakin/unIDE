' Проверка RqLcl без пользователя: форма открывается, OnShow нажимает
' кнопку три раза, проверяет надпись и свойства и закрывает форму.
' Итог - в консоль и в код завершения (0 - всё сошлось).
' Сборка: fbc -s console selftest.bas -i ..\inc

#include once "rqlcl.bi"

Dim Shared Form As QFORM
Dim Shared Label1 As QLABEL
Dim Shared Button1 As QBUTTON
Dim Shared Edit1 As QEDIT
Dim Shared ClickCount As Long
Dim Shared ChangeCount As Long
Dim Shared FailCount As Long
Dim Shared ShowCount As Long
Dim Shared CloseCount As Long

Sub Check(ByVal Passed As Long, ByRef What As String)
    If Passed Then
        Print "ok   "; What
    Else
        Print "FAIL "; What
        FailCount += 1
    End If
End Sub

Sub Button1Click(ByRef Sender As QBUTTON)
    ClickCount += 1
    Label1.Caption = "Clicks: " & ClickCount
End Sub

Sub Edit1Change(ByRef Sender As QEDIT)
    ChangeCount += 1
End Sub

Sub FormShow(ByRef Sender As QFORM)
    ShowCount += 1
    Button1.Click
    Button1.Click
    Button1.Click
    Check(ClickCount = 3, "OnClick fired 3 times (" & ClickCount & ")")
    Check(Label1.Caption = "Clicks: 3", "Label1.Caption = """ & Label1.Caption & """")
    Edit1.Text = "abc"
    Check(ChangeCount >= 1, "OnChange fired (" & ChangeCount & ")")
    Check(Edit1.Text = "abc", "Edit1.Text = """ & Edit1.Text & """")
    Check(Button1.Left = 16, "Button1.Left = " & Button1.Left)
    Check(Button1.Width = 120, "Button1.Width = " & Button1.Width)
    Check(Sender.Caption = "RqLcl selftest", "Sender.Caption = """ & Sender.Caption & """")
    Sender.Close
End Sub

Sub FormClose(ByRef Sender As QFORM)
    CloseCount += 1
End Sub

Form.Caption = "RqLcl selftest"
Form.Width = 300
Form.Height = 150
Form.OnShow = @FormShow
Form.OnClose = @FormClose

Label1.Parent = Form
Label1.Left = 10
Label1.Top = 10

Edit1.Parent = Form
Edit1.Left = 10
Edit1.Top = 40
Edit1.OnChange = @Edit1Change

Button1.Parent = Form
Button1.Left = 16
Button1.Top = 80
Button1.Width = 120
Button1.Caption = "Test"
Button1.OnClick = @Button1Click

Check(Form.Width = 300, "Form.Width = " & Form.Width)
Check(Button1.Caption = "Test", "Button1.Caption = """ & Button1.Caption & """")

Form.ShowModal
Check(ShowCount = 1, "OnShow fired once (" & ShowCount & ")")
Check(CloseCount = 1, "OnClose fired once (" & CloseCount & ")")

If FailCount = 0 Then
    Print "selftest passed"
Else
    Print "selftest FAILED: "; FailCount
End If
End FailCount
