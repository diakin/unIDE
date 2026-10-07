' Проверка QRICHEDIT без пользователя: AddStrings, SelAttributes (точка
' ввода и выделение), SelText, Line(i), RTF в файл и из файла, поток,
' PlainText, OnChange. Сборка: fbc -s console richtest.bas -i ..\inc

#include once "rqlcl.bi"
Dim Shared Form As QFORM
Dim Shared Rich As QRICHEDIT
Dim Shared FailCount As Long
Dim Shared ChangeCount As Long
Sub Check(ByVal Passed As Long, ByRef What As String)
    If Passed Then
        Print "ok   "; What
    Else
        Print "FAIL "; What
        FailCount += 1
    End If
End Sub
Sub RichChange()
    ChangeCount += 1
End Sub
Sub FormShow()
    Rich.AddStrings "first line"
    Rich.SelStart = Len(Rich.Text)
    Rich.SelLength = 5
    Rich.SelAttributes.Color = &hFF
    Rich.AddStrings "red line"
    Check(Rich.LineCount >= 2, "linecount " & Rich.LineCount)
    Check(Rich.Line(0) = "first line", "line0 [" & Rich.Line(0) & "]")
    Check(Rich.Line(1) = "red line", "line1 [" & Rich.Line(1) & "]")
    ' цвет второй строки и первой
    Rich.SelStart = 11 : Rich.SelLength = 3
    Check(Rich.SelText = "red", "seltext [" & Rich.SelText & "]")
    Check(Rich.SelAttributes.Color = &hFF, "red color " & Hex(Rich.SelAttributes.Color))
    Rich.SelStart = 0 : Rich.SelLength = 5
    Check(Rich.SelAttributes.Color <> &hFF, "first not red " & Hex(Rich.SelAttributes.Color))
    ' жирный на "first", цвет не трогается
    Rich.SelAttributes.AddStyles(0)
    Rich.SelStart = 1 : Rich.SelLength = 0
    Rich.SelStart = 0 : Rich.SelLength = 5
    Dim Sel As QFONT = Rich.SelAttributes
    Rich.SelStart = 12 : Rich.SelLength = 1
    Check(Rich.SelAttributes.Color = &hFF, "red kept after bold elsewhere")
    ' SelAttributes = Font
    Dim Fnt As QFONT
    Fnt.Name = "Courier New" : Fnt.Size = 16 : Fnt.Color = &hFF0000
    Rich.SelStart = 0 : Rich.SelLength = 5
    Rich.SelAttributes = Fnt
    Check(Rich.SelAttributes.Name = "Courier New", "assign name " & Rich.SelAttributes.Name)
    Check(Rich.SelAttributes.Size = 16, "assign size " & Rich.SelAttributes.Size)
    ' SelText замена
    Rich.SelStart = 0 : Rich.SelLength = 5
    Rich.SelText = "1st"
    Check(Rich.Line(0) = "1st line", "seltext set [" & Rich.Line(0) & "]")
    ' Line(i) =
    Rich.Line(1) = "second"
    Check(Rich.Line(1) = "second", "line set [" & Rich.Line(1) & "]")
    ' RTF файл
    Rich.SaveToFile "t.rtf"
    Dim FileNum As Long = FreeFile
    Dim Head As String = Space(5)
    Open "t.rtf" For Binary As #FileNum : Get #FileNum, , Head : Close #FileNum
    Check(Head = "{\rtf", "rtf file head " & Head)
    Rich.Clear
    Check(Len(Rich.Text) = 0, "clear")
    Rich.LoadFromFile "t.rtf"
    Check(Rich.Line(0) = "1st line", "load rtf line0 [" & Rich.Line(0) & "]")
    Rich.SelStart = 0 : Rich.SelLength = 2
    Check(Rich.SelAttributes.Size = 16, "load rtf keeps size " & Rich.SelAttributes.Size)
    ' поток
    Dim Mem As QMEMORYSTREAM
    Rich.SaveToStream Mem
    Check(Mem.Size > 20, "stream size " & Mem.Size)
    Rich.Clear
    Mem.Position = 0
    Rich.LoadFromStream Mem
    Check(Rich.Line(1) = "second", "stream load [" & Rich.Line(1) & "]")
    ' обычный текст, русский
    Rich.PlainText = 1
    Rich.Text = "Привет" & Chr(13, 10) & "мир"
    Check(Rich.Line(1) = "мир", "cp1251 text")
    Rich.SaveToFile "t.txt"
    Rich.Clear
    Rich.LoadFromFile "t.txt"
    Check(Rich.Line(0) = "Привет", "plain load")
    Check(ChangeCount > 0, "onchange " & ChangeCount)
    Rich.SelStart = 8
    Check(Rich.WhereY = 1, "wherey " & Rich.WhereY & " wherex " & Rich.WhereX)
    Form.Close
End Sub
Rich.Parent = Form
Rich.Width = 300 : Rich.Height = 200
Rich.OnChange = @RichChange
Form.OnShow = @FormShow
Form.ShowModal
Print "FAILS="; FailCount
