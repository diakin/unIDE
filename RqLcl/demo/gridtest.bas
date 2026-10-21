#include once "rqlcl.bi"
Dim Shared Form As QFORM
Dim Shared Grid As QSTRINGGRID
Dim Shared Tree As QDIRTREE
Dim Shared FailCount As Long
Dim Shared TreeChanges As Long
Sub Check(ByVal Passed As Long, ByRef What As String)
    If Passed Then
        Print "ok   "; What
    Else
        Print "FAIL "; What
        FailCount += 1
    End If
End Sub
Sub TreeChange()
    TreeChanges += 1
End Sub
Sub FormShow()
    Check(Grid.ColCount = 5 And Grid.RowCount = 5, "defaults " & Grid.ColCount & "x" & Grid.RowCount)
    Check(Grid.DefaultRowHeight = 24, "row height " & Grid.DefaultRowHeight)
    Grid.SetCell(1, 1, "hello")
    Grid.SetCell(2, 1, "Привет")
    Check(Grid.Cell(1, 1) = "hello", "cell")
    Check(Grid.Cell(2, 1) = "Привет", "cell cp1251")
    Check(Grid.Cell(9, 9) = "", "cell out of range")
    Grid.ColWidths(1) = 100
    Check(Grid.ColWidths(1) = 100, "colwidths")
    Grid.Row = 2 : Grid.Col = 3
    Check(Grid.Row = 2 And Grid.Col = 3, "row col")
    Grid.AddOptions(10, 14)
    Grid.Separator = "~"
    Grid.SaveToFile("g.txt", 0, 0, 0)
    Grid.SwapCols(1, 2)
    Check(Grid.Cell(1, 1) = "Привет", "swapcols")
    Grid.DeleteRow(1)
    Check(Grid.RowCount = 4 And Grid.Cell(1, 1) = "", "deleterow")
    Grid.InsertRow(1)
    Check(Grid.RowCount = 5, "insertrow")
    Grid.LoadFromFile("g.txt", 0, 0, 30000)
    Check(Grid.Cell(1, 1) = "hello" And Grid.Cell(2, 1) = "Привет", "loadfromfile")
    Check(Grid.RowCount = 5, "rowcount after load " & Grid.RowCount)
    Dim FileNum As Long = FreeFile
    Open "g2.txt" For Output As #FileNum
    Print #FileNum, "a~b~c~d~e~f~g"
    Print #FileNum, "1~2"
    Close #FileNum
    Grid.LoadFromFile("g2.txt", 1, 0, 1)
    Check(Grid.RowCount = 2 And Grid.ColCount = 7 And Grid.Cell(6, 1) = "g", "load offset " & Grid.RowCount & "x" & Grid.ColCount)
    Dim Mem As QMEMORYSTREAM
    Grid.SaveToStream(Mem)
    Check(Mem.Size > 10, "savetostream " & Mem.Size)
    Grid.SetCell(0, 1, "zzz")
    Mem.Position = 0
    Grid.LoadFromStream(Mem)
    Check(Grid.Cell(0, 1) = "a", "loadfromstream")
    Check(Grid.TextWidth("Hello") > 0, "textwidth")
    ' дерево
    Tree.Directory = "C:\windows"
    Check(LCase(Tree.Directory) = "c:\windows", "tree dir " & Tree.Directory)
    Tree.Directory = "C:\"
    Check(Tree.Directory = "C:\", "tree root " & Tree.Directory)
    Form.Close
End Sub
Grid.Parent = Form
Tree.Parent = Form
Tree.Left = 350 : Tree.Width = 200 : Tree.Height = 300
Tree.OnChange = @TreeChange
Form.Width = 600 : Form.Height = 400
Form.OnShow = @FormShow
Form.ShowModal
Print "FAILS="; FailCount
