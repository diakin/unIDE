#include once "rqlcl.bi"
Declare Function ClsSendMessage Lib "user32" Alias "SendMessageA" (ByVal Wnd As Any Ptr, ByVal Msg As ULong, ByVal WParam As UInteger, ByVal LParam As Integer) As Integer
Dim Shared Form As QFORM
Dim Shared MainMenu As QMAINMENU
Dim Shared FileMenu As QMENUITEM
Dim Shared OpenItem As QMENUITEM
Dim Shared SepItem As QMENUITEM
Dim Shared ExitItem As QMENUITEM
Dim Shared Popup As QPOPUPMENU
Dim Shared PopItem As QMENUITEM
Dim Shared Panel As QPANEL
Dim Shared CoolBtn As QCOOLBTN
Dim Shared Combo As QCOMBOBOX
Dim Shared Check1 As QCHECKBOX
Dim Shared List1 As QLISTBOX
Dim Shared Split As QSPLITTER
Dim Shared FailCount As Long
Dim Shared MenuClicks As Long, CheckClicks As Long, CoolClicks As Long, DrawItems As Long, MenuSenderOk As Long
Sub Check(ByVal Passed As Long, ByRef What As String)
    If Passed Then
        Print "ok   "; What
    Else
        Print "FAIL "; What
        FailCount += 1
    End If
End Sub
Sub OpenClick(ByRef Sender As QMENUITEM)
    MenuClicks += 1
    If @Sender = @OpenItem Then MenuSenderOk = 1
End Sub
Sub CheckClick()
    CheckClicks += 1
End Sub
Sub CoolClick()
    CoolClicks += 1
End Sub
Sub ListDraw(ByVal Index As Long, ByVal State As Long, ByRef R As QRECT, ByRef Sender As QLISTBOX)
    DrawItems += 1
    Sender.FillRect(R.Left, R.Top, R.Right, R.Bottom, &hFFFFFF)
    Sender.TextOut(R.Left + 2, R.Top, Sender.Item(Index), 0, -1)
End Sub
FileMenu.Caption = "&File"
OpenItem.Caption = "&Open"
OpenItem.ShortCut = "Ctrl+O"
OpenItem.OnClick = @OpenClick
SepItem.Caption = "-"
ExitItem.Caption = "E&xit"
FileMenu.AddItems(OpenItem, SepItem, ExitItem)
MainMenu.AddItems(FileMenu)
MainMenu.Parent = Form
PopItem.Caption = "Pop"
Popup.AddItems(PopItem)
Panel.Parent = Form
Panel.Align = 1
Panel.Height = 40
Panel.Caption = "panel"
Panel.BevelOuter = 1
Panel.PopupMenu = Popup
CoolBtn.Parent = Panel
CoolBtn.Left = 5 : CoolBtn.Top = 5 : CoolBtn.Width = 60 : CoolBtn.Height = 25
CoolBtn.Caption = "Cool"
CoolBtn.Flat = 1
CoolBtn.OnClick = @CoolClick
Combo.Parent = Form
Combo.Top = 50
Combo.AddItems("a", "b", "c")
Check1.Parent = Form
Check1.Top = 80
Check1.Caption = "check"
Check1.OnClick = @CheckClick
List1.Parent = Form
List1.Top = 110 : List1.Height = 120
List1.Style = 1
List1.OnDrawItem = @ListDraw
List1.AddItems("one", "two", "three")
Split.Parent = Form
Split.Align = 3
Split.MinSize = 40
Form.Width = 400 : Form.Height = 350
Form.Show
For WaitIdx As Long = 1 To 30
    DoEvents
    Sleep 10
Next
' РјРµРЅСЋ
Check(FileMenu.Count = 3, "menu count " & FileMenu.Count)
Check(OpenItem.ShortCut = "Ctrl+O", "shortcut " & OpenItem.ShortCut)
Check(ExitItem.MenuIndex = 2, "menuindex " & ExitItem.MenuIndex)
ClsSendMessage(Cast(Any Ptr, Form.Handle), &h111, OpenItem.Command, 0)   ' WM_COMMAND
Check(MenuClicks = 1 And MenuSenderOk = 1, "menu click " & MenuClicks)
FileMenu.DelItems(SepItem)
Check(FileMenu.Count = 2, "delitems " & FileMenu.Count)
FileMenu.Insert(1, SepItem)
Check(SepItem.MenuIndex = 1, "insert " & SepItem.MenuIndex)
FileMenu.DelIndex(1)
Check(FileMenu.Count = 2, "delindex " & FileMenu.Count)
' РєРѕРјР±РѕР±РѕРєСЃ
Check(Combo.ItemCount = 3 And Combo.Item(1) = "b", "combo items")
Combo.ItemIndex = 2
Check(Combo.Text = "c", "combo itemindex text [" & Combo.Text & "]")
Combo.Item(0) = "z"
Combo.DelItems(1)
Combo.InsertItem(0, "x")
Check(Combo.ItemCount = 3 And Combo.Item(0) = "x" And Combo.Item(1) = "z", "combo edit " & Combo.Item(0) & Combo.Item(1) & Combo.Item(2))
Check(Combo.Item(9) = "", "combo out of range")
Combo.Clear
Check(Combo.ItemCount = 0, "combo clear")
' С„Р»Р°Р¶РѕРє
Check1.Checked = 1
Check(Check1.Checked <> 0 And CheckClicks = 1, "checkbox " & CheckClicks)
' СЃРїРёСЃРѕРє
Check(List1.ItemCount = 3, "list count")
List1.MultiSelect = 1
List1.Selected(1) = 1
Check(List1.Selected(1) <> 0 And List1.SelCount = 1, "list selected " & List1.SelCount)
Check(Left(List1.Text, 5) = "one" & Chr(13, 10), "list text")
List1.SaveToFile("list.txt")
List1.Clear
List1.LoadFromFile("list.txt")
Check(List1.ItemCount = 3 And List1.Item(2) = "three", "list file")
Check(DrawItems > 0, "list ondrawitem " & DrawItems)
' РєРЅРѕРїРєР°
Dim BtnX As Long = 20, BtnY As Long = 15
ClsSendMessage(Cast(Any Ptr, Panel.Handle), &h201, 1, (BtnY Shl 16) Or BtnX)
ClsSendMessage(Cast(Any Ptr, Panel.Handle), &h202, 0, (BtnY Shl 16) Or BtnX)
Check(CoolClicks = 1, "coolbtn click " & CoolClicks)
Check(Form.ClientWidth > 0 And Form.ClientWidth <= Form.Width, "clientwidth " & Form.ClientWidth)
Check(Split.MinSize = 40, "splitter")
Form.Close
Print "FAILS="; FailCount
