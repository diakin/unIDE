' Прототип RqLcl: форма RapidQ с кнопкой, надписью и полем ввода.
' Сборка: fbc -s gui demo.bas -i ..\inc
' Рядом с demo.exe должна лежать rqlcl32.dll (32 бит) или rqlcl64.dll.

#include once "rqlcl.bi"

Dim Shared Form As QFORM
Dim Shared Label1 As QLABEL
Dim Shared Edit1 As QEDIT
Dim Shared Button1 As QBUTTON
Dim Shared ClickCount As Long

Sub Button1Click(ByRef Sender As QBUTTON)
    ClickCount += 1
    Label1.Caption = "Нажатий: " & ClickCount & ", в поле: " & Edit1.Text
End Sub

Sub Edit1Change(ByRef Sender As QEDIT)
    Form.Caption = "RqLcl - " & Sender.Text
End Sub

Form.Caption = "RqLcl - проверка"
Form.Width = 360
Form.Height = 170
Form.Center

Label1.Parent = Form
Label1.Left = 16
Label1.Top = 16
Label1.Caption = "Кнопка ещё не нажата"

Edit1.Parent = Form
Edit1.Left = 16
Edit1.Top = 48
Edit1.Width = 320
Edit1.Text = "Текст"
Edit1.OnChange = @Edit1Change

Button1.Parent = Form
Button1.Left = 16
Button1.Top = 88
Button1.Width = 120
Button1.Caption = "Нажми"
Button1.OnClick = @Button1Click

Form.ShowModal
