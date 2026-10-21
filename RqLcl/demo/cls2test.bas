' Проверка QGAUGE, QTABCONTROL, QRADIOBUTTON, QGROUPBOX, QTREEVIEW,
' QFILELISTBOX, QSTATUSBAR без пользователя. Сборка: fbc -s console
' cls2test.bas -i ..\inc

#include once "rqlcl.bi"
Dim Shared Form As QFORM
Dim Shared Gauge As QGAUGE
Dim Shared Tabs As QTABCONTROL
Dim Shared Radio1 As QRADIOBUTTON
Dim Shared Radio2 As QRADIOBUTTON
Dim Shared Group As QGROUPBOX
Dim Shared Tree As QTREEVIEW
Dim Shared Files As QFILELISTBOX
Dim Shared Bar As QSTATUSBAR
Dim Shared FailCount As Long
Dim Shared TreeChanges As Long, LastNode As Long, ExpandBlocked As Long, TabChanges As Long
Sub Check(ByVal Passed As Long, ByRef What As String)
    If Passed Then
        Print "ok   "; What
    Else
        Print "FAIL "; What
        FailCount += 1
    End If
End Sub
Sub TreeChange(ByVal Index As Long, ByRef Sender As QTREEVIEW)
    TreeChanges += 1 : LastNode = Index
End Sub
Sub TreeExpanding(ByVal Index As Long, ByRef AllowExpansion As Long)
    If Index = 0 Then
        AllowExpansion = 0
        ExpandBlocked += 1
    End If
End Sub
Sub TabsChange()
    TabChanges += 1
End Sub
' Папка для QFILELISTBOX: flb\a.txt, flb\b.bas, flb\sub
MkDir ExePath & "\flb"
MkDir ExePath & "\flb\sub"
Dim MakeNum As Long = FreeFile
Open ExePath & "\flb\a.txt" For Output As #MakeNum : Close #MakeNum
Open ExePath & "\flb\b.bas" For Output As #MakeNum : Close #MakeNum
Gauge.Parent = Form
Gauge.Width = 200 : Gauge.Height = 20
Gauge.ForeColor = &hFF0000
Gauge.Max = 200
Gauge.Position = 50
Tabs.Parent = Form
Tabs.Top = 30 : Tabs.Width = 300 : Tabs.Height = 60
Tabs.AddTabs("One", "Two", "Three")
Tabs.OnChange = @TabsChange
Group.Parent = Form
Group.Top = 100 : Group.Height = 60 : Group.Caption = "Group"
Radio1.Parent = Group : Radio1.Caption = "r1" : Radio1.Top = 5
Radio2.Parent = Group : Radio2.Caption = "r2" : Radio2.Top = 25
Tree.Parent = Form
Tree.Top = 170 : Tree.Height = 120
Tree.AddItems("Root1", "Root2")
Tree.AddChildItems(0, "Child1", "Child2")
Tree.OnChange = @TreeChange
Tree.OnExpanding = @TreeExpanding
Files.Parent = Form
Files.Left = 220 : Files.Top = 170 : Files.Height = 100
Bar.Parent = Form
Bar.AddPanels("first", "second")
Form.Width = 450 : Form.Height = 380
Form.Show
For WaitIdx As Long = 1 To 30
    DoEvents
    Sleep 10
Next
Check(Gauge.Position = 50 And Gauge.Max = 200, "gauge")
Check(Tabs.TabCount = 3 And Tabs.Tab(1) = "Two", "tabs " & Tabs.TabCount)
Tabs.Tab(1) = "Zwei"
Tabs.InsertTab(0, "Zero")
Tabs.DelTabs(3)
Check(Tabs.TabCount = 3 And Tabs.Tab(0) = "Zero" And Tabs.Tab(2) = "Zwei", "tabs edit " & Tabs.Tab(0) & Tabs.Tab(1) & Tabs.Tab(2))
Tabs.TabIndex = 2
Check(Tabs.TabIndex = 2, "tabindex")
Tabs.Color = &h00FF00
Check(Tabs.Color = &h00FF00, "tabs color")
Radio2.Checked = 1
Check(Radio2.Checked <> 0 And Radio1.Checked = 0, "radio")
Radio1.Checked = 1
Check(Radio2.Checked = 0, "radio group")
Check(Tree.ItemCount = 4, "tree count " & Tree.ItemCount)
Check(Tree.Item(1).Text = "Child1" And Tree.Item(1).Level = 1 And Tree.Item(1).Parent = 0, "tree item " & Tree.Item(1).Text)
Check(Tree.Item(0).Count = 2 And Tree.Item(0).HasChildren <> 0, "tree children")
Tree.Item(3).Text = "Root2x"
Check(Tree.Item(3).Text = "Root2x", "tree text set")
Tree.ItemIndex = 2
' OnChange в LCL - по таймеру после смены выделения
For WaitIdx As Long = 1 To 50
    DoEvents
    Sleep 10
    If TreeChanges > 0 Then Exit For
Next
Check(Tree.ItemIndex = 2 And TreeChanges > 0 And LastNode = 2, "tree select/onchange " & TreeChanges & " " & LastNode)
Tree.Expand(0)
Check(ExpandBlocked >= 1 And Tree.Item(1).IsVisible = 0, "tree onexpanding allow=0 " & ExpandBlocked)
Tree.SaveToFile("tree.txt")
Tree.Clear
Check(Tree.ItemCount = 0, "tree clear")
Tree.LoadFromFile("tree.txt")
Check(Tree.ItemCount = 4 And Tree.Item(2).Text = "Child2", "tree file " & Tree.ItemCount)
Tree.DelItems(1)
Check(Tree.ItemCount = 3, "tree delitems")
Check(Tree.Item(9).Text = "", "tree out of range")
Files.AddFileTypes(4)
Files.Mask = "*.*"
Files.Directory = ExePath & "\flb"
Dim FileList As String
For ItemIdx As Long = 0 To Files.ItemCount - 1
    FileList &= Files.Item(ItemIdx) & " "
Next
Check(InStr(FileList, "a.txt") > 0 And InStr(FileList, "[sub]") > 0, "filelistbox [" & FileList & "]")
Files.Mask = "*.bas"
Check(Files.ItemCount >= 1 And InStr(Files.Item(0) & Files.Item(Files.ItemCount - 1), ".bas") > 0, "mask " & Files.ItemCount)
Files.ItemIndex = Files.ItemCount - 1
Check(InStr(LCase(Files.FileName), "b.bas") > 0, "filename " & Files.FileName)
Check(Bar.PanelCount = 2 And Bar.Panel(1).Caption = "second", "statusbar panels")
Bar.Panel(0).Caption = "changed"
Bar.Panel(0).Width = 120
Check(Bar.Panel(0).Caption = "changed" And Bar.Panel(0).Width = 120, "panel set")
Bar.SimplePanel = 1
Bar.SimpleText = "simple"
Check(Bar.SimpleText = "simple", "simpletext")
Form.Close
Print "FAILS="; FailCount
