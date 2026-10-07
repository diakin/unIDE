' Проверка QFONT без пользователя: свойства, Label.Font = Font (копия),
' Label.Font как обёртка над шрифтом элемента, FontCount/FontName, Handle.
' Сборка: fbc -s console fonttest.bas -i ..\inc

#include once "rqlcl.bi"
Dim Shared Form As QFORM
Dim Shared Label1 As QLABEL
Dim Shared Font1 As QFONT
Dim Shared FailCount As Long
Sub Check(ByVal Passed As Long, ByRef What As String)
    If Passed Then
        Print "ok   "; What
    Else
        Print "FAIL "; What
        FailCount += 1
    End If
End Sub
Sub FormShow()
    Form.Close
End Sub
Font1.Name = "Arial"
Font1.Size = 14
Font1.Color = &hFF
Font1.AddStyles(0, 1)
Check(Font1.Name = "Arial", "name " & Font1.Name)
Check(Font1.Size = 14, "size " & Font1.Size)
Check(Font1.Color = &hFF, "color " & Font1.Color)
Label1.Parent = Form
Label1.Caption = "Test"
Label1.Font = Font1
Check(Label1.Font.Name = "Arial", "label font name " & Label1.Font.Name)
Check(Label1.Font.Size = 14, "label font size " & Label1.Font.Size)
Dim LabelFont As QFONT = Label1.Font
LabelFont.Size = 20
Check(Label1.Font.Size = 20, "label font via wrapper " & Label1.Font.Size)
Font1.Size = 9
Check(Label1.Font.Size = 20, "label keeps copy " & Label1.Font.Size)
Font1.DelStyles(1)
Check(Font1.FontCount > 0, "fontcount " & Font1.FontCount)
Check(Len(Font1.FontName(0)) > 0, "fontname(0) " & Font1.FontName(0))
Check(Font1.Handle <> 0, "font handle")
Form.OnShow = @FormShow
Form.ShowModal
Check(Form.Handle <> 0, "form handle")
Print "FAILS="; FailCount
