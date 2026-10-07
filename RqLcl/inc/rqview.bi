' ---------------------------------------------------------------------------
'  RqLcl: QLISTVIEW (TListView LCL) и QFONTDIALOG (TFontDialog LCL).
'  Подключается из rqlcl.bi.
' ---------------------------------------------------------------------------

' ---------------------------------------------------------------------------
'  QLISTITEM - пункт QLISTVIEW по номеру: List.Item(i).Caption (ItemType RapidQ).
'  Объект-посредник: значения читаются и пишутся в списке сразу; Handle -
'  окно списка (как TListItem.Handle Delphi)
' ---------------------------------------------------------------------------

Type QLISTITEM
    ListObj As Any Ptr
    ItemNum As Long
    Declare Property Caption() As String
    Declare Property Caption(ByRef Value As String)
    Declare Property Checked() As Long
    Declare Property Checked(ByVal Value As Long)
    Declare Property ImageIndex() As Long
    Declare Property ImageIndex(ByVal Value As Long)
    Declare Property Selected() As Long
    Declare Property Selected(ByVal Value As Long)
    Declare Property StateIndex() As Long
    Declare Property StateIndex(ByVal Value As Long)
    Declare Property Index() As Long
    Declare Property Handle() As Long
End Type

Property QLISTITEM.Caption() As String
    Return RqLclGetItemEx(ListObj, "Item.Caption", ItemNum, "QLISTVIEW.Item.Caption")
End Property
Property QLISTITEM.Caption(ByRef Value As String)
    If RqSetItemStr(ListObj, "Item.Caption", ItemNum, StrPtr(Value)) = 0 Then RqLclClassError("QLISTVIEW.Item.Caption")
End Property
Property QLISTITEM.Checked() As Long
    Return RqLclGetItemIntEx(ListObj, "Item.Checked", ItemNum, "QLISTVIEW.Item.Checked")
End Property
Property QLISTITEM.Checked(ByVal Value As Long)
    If RqSetItemInt(ListObj, "Item.Checked", ItemNum, Value) = 0 Then RqLclClassError("QLISTVIEW.Item.Checked")
End Property
Property QLISTITEM.ImageIndex() As Long
    Return RqLclGetItemIntEx(ListObj, "Item.ImageIndex", ItemNum, "QLISTVIEW.Item.ImageIndex")
End Property
Property QLISTITEM.ImageIndex(ByVal Value As Long)
    If RqSetItemInt(ListObj, "Item.ImageIndex", ItemNum, Value) = 0 Then RqLclClassError("QLISTVIEW.Item.ImageIndex")
End Property
Property QLISTITEM.Selected() As Long
    Return RqLclGetItemIntEx(ListObj, "Item.Selected", ItemNum, "QLISTVIEW.Item.Selected")
End Property
Property QLISTITEM.Selected(ByVal Value As Long)
    If RqSetItemInt(ListObj, "Item.Selected", ItemNum, Value) = 0 Then RqLclClassError("QLISTVIEW.Item.Selected")
End Property
Property QLISTITEM.StateIndex() As Long
    Return RqLclGetItemIntEx(ListObj, "Item.StateIndex", ItemNum, "QLISTVIEW.Item.StateIndex")
End Property
Property QLISTITEM.StateIndex(ByVal Value As Long)
    If RqSetItemInt(ListObj, "Item.StateIndex", ItemNum, Value) = 0 Then RqLclClassError("QLISTVIEW.Item.StateIndex")
End Property
Property QLISTITEM.Index() As Long
    Return RqLclGetItemIntEx(ListObj, "Item.Index", ItemNum, "QLISTVIEW.Item.Index")
End Property
Property QLISTITEM.Handle() As Long
    Return RqLclGetItemIntEx(ListObj, "Item.Handle", ItemNum, "QLISTVIEW.Item.Handle")
End Property

' ---------------------------------------------------------------------------
'  QLISTCOLUMN - столбец QLISTVIEW по номеру: List.Column(0).Width (ColumnType RapidQ)
' ---------------------------------------------------------------------------

Type QLISTCOLUMN
    ListObj As Any Ptr
    ColumnNum As Long
    Declare Property Caption() As String
    Declare Property Caption(ByRef Value As String)
    Declare Property Width() As Long
    Declare Property Width(ByVal Value As Long)
End Type

Property QLISTCOLUMN.Caption() As String
    Return RqLclGetItemEx(ListObj, "Column.Caption", ColumnNum, "QLISTVIEW.Column.Caption")
End Property
Property QLISTCOLUMN.Caption(ByRef Value As String)
    If RqSetItemStr(ListObj, "Column.Caption", ColumnNum, StrPtr(Value)) = 0 Then RqLclClassError("QLISTVIEW.Column.Caption")
End Property
Property QLISTCOLUMN.Width() As Long
    Return RqLclGetItemIntEx(ListObj, "Column.Width", ColumnNum, "QLISTVIEW.Column.Width")
End Property
Property QLISTCOLUMN.Width(ByVal Value As Long)
    If RqSetItemInt(ListObj, "Column.Width", ColumnNum, Value) = 0 Then RqLclClassError("QLISTVIEW.Column.Width")
End Property

' ---------------------------------------------------------------------------
'  QLISTVIEW - список с пунктами и столбцами (TListView); ViewStyle 0 vsIcon,
'  1 vsSmallIcon, 2 vsList, 3 vsReport; OnChange - SUB (Index%, Change%):
'  Change 0 текст, 1 значок, 2 состояние; OnColumnClick - SUB (Column%);
'  OnKeyPressed - как OnKeyPress
' ---------------------------------------------------------------------------

Type QLISTVIEW Extends QCONTROL
    ItemWrap As QLISTITEM
    ColumnWrap As QLISTCOLUMN
    Declare Constructor()
    Declare Property Align() As Long
    Declare Property Align(ByVal Value As Long)
    Declare Property BorderStyle() As Long
    Declare Property BorderStyle(ByVal Value As Long)
    Declare Property CheckBoxes() As Long
    Declare Property CheckBoxes(ByVal Value As Long)
    Declare Property ColumnClick() As Long
    Declare Property ColumnClick(ByVal Value As Long)
    Declare Property ColumnsCount() As Long
    Declare Property ColumnsCount(ByVal Value As Long)
    Declare Property GridLines() As Long
    Declare Property GridLines(ByVal Value As Long)
    Declare Property HideSelection() As Long
    Declare Property HideSelection(ByVal Value As Long)
    Declare Property HotTrack() As Long
    Declare Property HotTrack(ByVal Value As Long)
    Declare Property ItemCount() As Long
    Declare Property ItemIndex() As Long
    Declare Property ItemIndex(ByVal Value As Long)
    Declare Property MultiSelect() As Long
    Declare Property MultiSelect(ByVal Value As Long)
    Declare Property ReadOnly() As Long
    Declare Property ReadOnly(ByVal Value As Long)
    Declare Property RowSelect() As Long
    Declare Property RowSelect(ByVal Value As Long)
    Declare Property SelCount() As Long
    Declare Property ShowColumnHeaders() As Long
    Declare Property ShowColumnHeaders(ByVal Value As Long)
    Declare Property SortType() As Long
    Declare Property SortType(ByVal Value As Long)
    Declare Property TabOrder() As Long
    Declare Property TabOrder(ByVal Value As Long)
    Declare Property Tag() As Long
    Declare Property Tag(ByVal Value As Long)
    Declare Property ViewStyle() As Long
    Declare Property ViewStyle(ByVal Value As Long)
    Declare Sub StrCall(ByRef MethodName As String, ByRef Text1 As String, ByVal IntArg1 As Long = 0, ByVal IntArg2 As Long = 0)
    Declare Function Item(ByVal ItemNum As Long) ByRef As QLISTITEM
    Declare Function Column(ByVal ColumnNum As Long) ByRef As QLISTCOLUMN
    Declare Property Selected(ByVal ItemNum As Long) As Long
    Declare Property Selected(ByVal ItemNum As Long, ByVal Value As Long)
    Declare Function SubItem(ByVal ItemNum As Long, ByVal SubNum As Long) As String
    Declare Sub SetSubItem(ByVal ItemNum As Long, ByVal SubNum As Long, ByRef Value As String)
    Declare Property LargeImages(ByRef Value As QIMAGELIST)
    Declare Property SmallImages(ByRef Value As QIMAGELIST)
    Declare Property StateImages(ByRef Value As QIMAGELIST)
    Declare Sub AddColumns Overload (ByRef Text1 As String)
    Declare Sub AddColumns Overload (ByRef Text1 As String, ByRef Text2 As String)
    Declare Sub AddColumns Overload (ByRef Text1 As String, ByRef Text2 As String, ByRef Text3 As String)
    Declare Sub AddColumns Overload (ByRef Text1 As String, ByRef Text2 As String, ByRef Text3 As String, ByRef Text4 As String)
    Declare Sub AddColumns Overload (ByRef Text1 As String, ByRef Text2 As String, ByRef Text3 As String, ByRef Text4 As String, ByRef Text5 As String)
    Declare Sub AddColumns Overload (ByRef Text1 As String, ByRef Text2 As String, ByRef Text3 As String, ByRef Text4 As String, ByRef Text5 As String, ByRef Text6 As String)
    Declare Sub AddItems Overload (ByRef Text1 As String)
    Declare Sub AddItems Overload (ByRef Text1 As String, ByRef Text2 As String)
    Declare Sub AddItems Overload (ByRef Text1 As String, ByRef Text2 As String, ByRef Text3 As String)
    Declare Sub AddItems Overload (ByRef Text1 As String, ByRef Text2 As String, ByRef Text3 As String, ByRef Text4 As String)
    Declare Sub AddItems Overload (ByRef Text1 As String, ByRef Text2 As String, ByRef Text3 As String, ByRef Text4 As String, ByRef Text5 As String)
    Declare Sub AddItems Overload (ByRef Text1 As String, ByRef Text2 As String, ByRef Text3 As String, ByRef Text4 As String, ByRef Text5 As String, ByRef Text6 As String)
    Declare Sub DelItems(ByVal Num1 As Long, ByVal Num2 As Long = -1, ByVal Num3 As Long = -1, ByVal Num4 As Long = -1)
    Declare Sub AddSubItem(ByVal ItemNum As Long, ByRef Text1 As String)
    Declare Sub Clear()
    Declare Sub ClearColumns()
    Declare Sub DelSubItem(ByVal ItemNum As Long, ByVal SubNum As Long)
    Declare Sub InsertItem(ByVal ItemNum As Long, ByRef Text1 As String)
    Declare Sub InsertSubItem(ByVal ItemNum As Long, ByVal SubNum As Long, ByRef Text1 As String)
    Declare Sub SwapItem(ByVal Num1 As Long, ByVal Num2 As Long)
    Declare Property OnClick(ByVal Handler As Sub())
    Declare Property OnClick(ByVal Handler As Sub(ByRef Sender As QLISTVIEW))
    Declare Property OnDblClick(ByVal Handler As Sub())
    Declare Property OnDblClick(ByVal Handler As Sub(ByRef Sender As QLISTVIEW))
    Declare Property OnChange(ByVal Handler As Sub(ByVal Index As Long, ByVal Change As Long))
    Declare Property OnChange(ByVal Handler As Sub(ByVal Index As Long, ByVal Change As Long, ByRef Sender As QLISTVIEW))
    Declare Property OnChange(ByVal Handler As Sub())
    Declare Property OnChange(ByVal Handler As Sub(ByRef Sender As QLISTVIEW))
    Declare Property OnColumnClick(ByVal Handler As Sub(ByVal ColumnNum As Long))
    Declare Property OnColumnClick(ByVal Handler As Sub(ByVal ColumnNum As Long, ByRef Sender As QLISTVIEW))
    Declare Property OnColumnClick(ByVal Handler As Sub())
    Declare Property OnColumnClick(ByVal Handler As Sub(ByRef Sender As QLISTVIEW))
    Declare Property OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    Declare Property OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QLISTVIEW))
    Declare Property OnKeyDown(ByVal Handler As Sub())
    Declare Property OnKeyDown(ByVal Handler As Sub(ByRef Sender As QLISTVIEW))
    Declare Property OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    Declare Property OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QLISTVIEW))
    Declare Property OnKeyUp(ByVal Handler As Sub())
    Declare Property OnKeyUp(ByVal Handler As Sub(ByRef Sender As QLISTVIEW))
    Declare Property OnKeyPress(ByVal Handler As Sub(ByRef Key As Long))
    Declare Property OnKeyPress(ByVal Handler As Sub(ByRef Key As Long, ByRef Sender As QLISTVIEW))
    Declare Property OnKeyPress(ByVal Handler As Sub())
    Declare Property OnKeyPress(ByVal Handler As Sub(ByRef Sender As QLISTVIEW))
    Declare Property OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QLISTVIEW))
    Declare Property OnMouseDown(ByVal Handler As Sub())
    Declare Property OnMouseDown(ByVal Handler As Sub(ByRef Sender As QLISTVIEW))
    Declare Property OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QLISTVIEW))
    Declare Property OnMouseUp(ByVal Handler As Sub())
    Declare Property OnMouseUp(ByVal Handler As Sub(ByRef Sender As QLISTVIEW))
    Declare Property OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QLISTVIEW))
    Declare Property OnMouseMove(ByVal Handler As Sub())
    Declare Property OnMouseMove(ByVal Handler As Sub(ByRef Sender As QLISTVIEW))
    Declare Property OnKeyPressed(ByVal Handler As Sub(ByRef Key As Long))
    Declare Property OnKeyPressed(ByVal Handler As Sub(ByRef Key As Long, ByRef Sender As QLISTVIEW))
    Declare Property OnKeyPressed(ByVal Handler As Sub())
    Declare Property OnKeyPressed(ByVal Handler As Sub(ByRef Sender As QLISTVIEW))
End Type

Constructor QLISTVIEW()
    RqObj = RqLclNew("QLISTVIEW", @This)
End Constructor
Property QLISTVIEW.Align() As Long
    Return RqGetInt(RqObj, "Align")
End Property
Property QLISTVIEW.Align(ByVal Value As Long)
    RqLclSetInt(RqObj, "Align", Value)
End Property
Property QLISTVIEW.BorderStyle() As Long
    Return RqGetInt(RqObj, "BorderStyle")
End Property
Property QLISTVIEW.BorderStyle(ByVal Value As Long)
    RqLclSetInt(RqObj, "BorderStyle", Value)
End Property
Property QLISTVIEW.CheckBoxes() As Long
    Return RqGetInt(RqObj, "CheckBoxes")
End Property
Property QLISTVIEW.CheckBoxes(ByVal Value As Long)
    RqLclSetInt(RqObj, "CheckBoxes", Value)
End Property
Property QLISTVIEW.ColumnClick() As Long
    Return RqGetInt(RqObj, "ColumnClick")
End Property
Property QLISTVIEW.ColumnClick(ByVal Value As Long)
    RqLclSetInt(RqObj, "ColumnClick", Value)
End Property
Property QLISTVIEW.ColumnsCount() As Long
    Return RqGetInt(RqObj, "ColumnsCount")
End Property
Property QLISTVIEW.ColumnsCount(ByVal Value As Long)
    RqLclSetInt(RqObj, "ColumnsCount", Value)
End Property
Property QLISTVIEW.GridLines() As Long
    Return RqGetInt(RqObj, "GridLines")
End Property
Property QLISTVIEW.GridLines(ByVal Value As Long)
    RqLclSetInt(RqObj, "GridLines", Value)
End Property
Property QLISTVIEW.HideSelection() As Long
    Return RqGetInt(RqObj, "HideSelection")
End Property
Property QLISTVIEW.HideSelection(ByVal Value As Long)
    RqLclSetInt(RqObj, "HideSelection", Value)
End Property
Property QLISTVIEW.HotTrack() As Long
    Return RqGetInt(RqObj, "HotTrack")
End Property
Property QLISTVIEW.HotTrack(ByVal Value As Long)
    RqLclSetInt(RqObj, "HotTrack", Value)
End Property
Property QLISTVIEW.ItemCount() As Long
    Return RqGetInt(RqObj, "ItemCount")
End Property
Property QLISTVIEW.ItemIndex() As Long
    Return RqGetInt(RqObj, "ItemIndex")
End Property
Property QLISTVIEW.ItemIndex(ByVal Value As Long)
    RqLclSetInt(RqObj, "ItemIndex", Value)
End Property
Property QLISTVIEW.MultiSelect() As Long
    Return RqGetInt(RqObj, "MultiSelect")
End Property
Property QLISTVIEW.MultiSelect(ByVal Value As Long)
    RqLclSetInt(RqObj, "MultiSelect", Value)
End Property
Property QLISTVIEW.ReadOnly() As Long
    Return RqGetInt(RqObj, "ReadOnly")
End Property
Property QLISTVIEW.ReadOnly(ByVal Value As Long)
    RqLclSetInt(RqObj, "ReadOnly", Value)
End Property
Property QLISTVIEW.RowSelect() As Long
    Return RqGetInt(RqObj, "RowSelect")
End Property
Property QLISTVIEW.RowSelect(ByVal Value As Long)
    RqLclSetInt(RqObj, "RowSelect", Value)
End Property
Property QLISTVIEW.SelCount() As Long
    Return RqGetInt(RqObj, "SelCount")
End Property
Property QLISTVIEW.ShowColumnHeaders() As Long
    Return RqGetInt(RqObj, "ShowColumnHeaders")
End Property
Property QLISTVIEW.ShowColumnHeaders(ByVal Value As Long)
    RqLclSetInt(RqObj, "ShowColumnHeaders", Value)
End Property
Property QLISTVIEW.SortType() As Long
    Return RqGetInt(RqObj, "SortType")
End Property
Property QLISTVIEW.SortType(ByVal Value As Long)
    RqLclSetInt(RqObj, "SortType", Value)
End Property
Property QLISTVIEW.TabOrder() As Long
    Return RqGetInt(RqObj, "TabOrder")
End Property
Property QLISTVIEW.TabOrder(ByVal Value As Long)
    RqLclSetInt(RqObj, "TabOrder", Value)
End Property
Property QLISTVIEW.Tag() As Long
    Return RqGetInt(RqObj, "Tag")
End Property
Property QLISTVIEW.Tag(ByVal Value As Long)
    RqLclSetInt(RqObj, "Tag", Value)
End Property
Property QLISTVIEW.ViewStyle() As Long
    Return RqGetInt(RqObj, "ViewStyle")
End Property
Property QLISTVIEW.ViewStyle(ByVal Value As Long)
    RqLclSetInt(RqObj, "ViewStyle", Value)
End Property
Sub QLISTVIEW.StrCall(ByRef MethodName As String, ByRef Text1 As String, ByVal IntArg1 As Long = 0, ByVal IntArg2 As Long = 0)
    If RqCallEx(RqObj, MethodName, StrPtr(Text1), IntArg1, IntArg2, 0, 0, 0) = 0 Then
        RqLclClassError("QLISTVIEW." & MethodName)
    End If
End Sub
Property QLISTVIEW.LargeImages(ByRef Value As QIMAGELIST)
    If RqSetObj(RqObj, "LargeImages", Value.RqObj) = 0 Then RqLclShowError("QLISTVIEW.LargeImages")
End Property
Property QLISTVIEW.SmallImages(ByRef Value As QIMAGELIST)
    If RqSetObj(RqObj, "SmallImages", Value.RqObj) = 0 Then RqLclShowError("QLISTVIEW.SmallImages")
End Property
Property QLISTVIEW.StateImages(ByRef Value As QIMAGELIST)
    If RqSetObj(RqObj, "StateImages", Value.RqObj) = 0 Then RqLclShowError("QLISTVIEW.StateImages")
End Property
' Пункт по номеру (с 0): List.Item(i).Caption = "..."
Function QLISTVIEW.Item(ByVal ItemNum As Long) ByRef As QLISTITEM
    ItemWrap.ListObj = RqObj
    ItemWrap.ItemNum = ItemNum
    Return ItemWrap
End Function
' Столбец по номеру (с 0): List.Column(0).Width = 100
Function QLISTVIEW.Column(ByVal ColumnNum As Long) ByRef As QLISTCOLUMN
    ColumnWrap.ListObj = RqObj
    ColumnWrap.ColumnNum = ColumnNum
    Return ColumnWrap
End Function
Property QLISTVIEW.Selected(ByVal ItemNum As Long) As Long
    Return RqLclGetItemIntEx(RqObj, "Selected", ItemNum, "QLISTVIEW.Selected")
End Property
Property QLISTVIEW.Selected(ByVal ItemNum As Long, ByVal Value As Long)
    If RqSetItemInt(RqObj, "Selected", ItemNum, Value) = 0 Then RqLclClassError("QLISTVIEW.Selected")
End Property
' Подпункт: SubItem(i, 0) - первый подпункт (второй столбец)
Function QLISTVIEW.SubItem(ByVal ItemNum As Long, ByVal SubNum As Long) As String
    Dim TextLen As Long = RqGetCell(RqObj, SubNum, ItemNum, 0, 0)
    If TextLen < 0 Then
        RqLclClassError("QLISTVIEW.SubItem")
        Return ""
    End If
    If TextLen = 0 Then Return ""
    Dim TextValue As String = Space(TextLen)
    RqGetCell(RqObj, SubNum, ItemNum, StrPtr(TextValue), TextLen + 1)
    Return TextValue
End Function
' List.SubItem(i, j) = s (препроцессор: List.SetSubItem(i, j, s)); за
' последним подпунктом - добавляются пустые
Sub QLISTVIEW.SetSubItem(ByVal ItemNum As Long, ByVal SubNum As Long, ByRef Value As String)
    If RqSetCell(RqObj, SubNum, ItemNum, StrPtr(Value)) = 0 Then RqLclClassError("QLISTVIEW.SubItem")
End Sub
Sub QLISTVIEW.AddColumns(ByRef Text1 As String)
    StrCall("AddColumns", Text1)
End Sub
Sub QLISTVIEW.AddColumns(ByRef Text1 As String, ByRef Text2 As String)
    StrCall("AddColumns", Text1) : StrCall("AddColumns", Text2)
End Sub
Sub QLISTVIEW.AddColumns(ByRef Text1 As String, ByRef Text2 As String, ByRef Text3 As String)
    StrCall("AddColumns", Text1) : StrCall("AddColumns", Text2) : StrCall("AddColumns", Text3)
End Sub
Sub QLISTVIEW.AddColumns(ByRef Text1 As String, ByRef Text2 As String, ByRef Text3 As String, ByRef Text4 As String)
    StrCall("AddColumns", Text1) : StrCall("AddColumns", Text2) : StrCall("AddColumns", Text3) : StrCall("AddColumns", Text4)
End Sub
Sub QLISTVIEW.AddColumns(ByRef Text1 As String, ByRef Text2 As String, ByRef Text3 As String, ByRef Text4 As String, ByRef Text5 As String)
    StrCall("AddColumns", Text1) : StrCall("AddColumns", Text2) : StrCall("AddColumns", Text3) : StrCall("AddColumns", Text4) : StrCall("AddColumns", Text5)
End Sub
Sub QLISTVIEW.AddColumns(ByRef Text1 As String, ByRef Text2 As String, ByRef Text3 As String, ByRef Text4 As String, ByRef Text5 As String, ByRef Text6 As String)
    StrCall("AddColumns", Text1) : StrCall("AddColumns", Text2) : StrCall("AddColumns", Text3) : StrCall("AddColumns", Text4) : StrCall("AddColumns", Text5) : StrCall("AddColumns", Text6)
End Sub
Sub QLISTVIEW.AddItems(ByRef Text1 As String)
    StrCall("AddItems", Text1)
End Sub
Sub QLISTVIEW.AddItems(ByRef Text1 As String, ByRef Text2 As String)
    StrCall("AddItems", Text1) : StrCall("AddItems", Text2)
End Sub
Sub QLISTVIEW.AddItems(ByRef Text1 As String, ByRef Text2 As String, ByRef Text3 As String)
    StrCall("AddItems", Text1) : StrCall("AddItems", Text2) : StrCall("AddItems", Text3)
End Sub
Sub QLISTVIEW.AddItems(ByRef Text1 As String, ByRef Text2 As String, ByRef Text3 As String, ByRef Text4 As String)
    StrCall("AddItems", Text1) : StrCall("AddItems", Text2) : StrCall("AddItems", Text3) : StrCall("AddItems", Text4)
End Sub
Sub QLISTVIEW.AddItems(ByRef Text1 As String, ByRef Text2 As String, ByRef Text3 As String, ByRef Text4 As String, ByRef Text5 As String)
    StrCall("AddItems", Text1) : StrCall("AddItems", Text2) : StrCall("AddItems", Text3) : StrCall("AddItems", Text4) : StrCall("AddItems", Text5)
End Sub
Sub QLISTVIEW.AddItems(ByRef Text1 As String, ByRef Text2 As String, ByRef Text3 As String, ByRef Text4 As String, ByRef Text5 As String, ByRef Text6 As String)
    StrCall("AddItems", Text1) : StrCall("AddItems", Text2) : StrCall("AddItems", Text3) : StrCall("AddItems", Text4) : StrCall("AddItems", Text5) : StrCall("AddItems", Text6)
End Sub
Sub QLISTVIEW.DelItems(ByVal Num1 As Long, ByVal Num2 As Long = -1, ByVal Num3 As Long = -1, ByVal Num4 As Long = -1)
    Dim NumList(1 To 4) As Long = {Num1, Num2, Num3, Num4}
    For ArgIdx As Long = 1 To 4
        If (ArgIdx > 1) AndAlso (NumList(ArgIdx) = -1) Then Exit For
        StrCall("DelItems", "", NumList(ArgIdx))
    Next
End Sub
Sub QLISTVIEW.AddSubItem(ByVal ItemNum As Long, ByRef Text1 As String)
    StrCall("AddSubItem", Text1, ItemNum)
End Sub
Sub QLISTVIEW.Clear()
    StrCall("Clear", "")
End Sub
Sub QLISTVIEW.ClearColumns()
    StrCall("ClearColumns", "")
End Sub
Sub QLISTVIEW.DelSubItem(ByVal ItemNum As Long, ByVal SubNum As Long)
    StrCall("DelSubItem", "", ItemNum, SubNum)
End Sub
' ItemNum = ItemCount - в конец
Sub QLISTVIEW.InsertItem(ByVal ItemNum As Long, ByRef Text1 As String)
    StrCall("InsertItem", Text1, ItemNum)
End Sub
Sub QLISTVIEW.InsertSubItem(ByVal ItemNum As Long, ByVal SubNum As Long, ByRef Text1 As String)
    StrCall("InsertSubItem", Text1, ItemNum, SubNum)
End Sub
Sub QLISTVIEW.SwapItem(ByVal Num1 As Long, ByVal Num2 As Long)
    StrCall("SwapItem", "", Num1, Num2)
End Sub
Property QLISTVIEW.OnClick(ByVal Handler As Sub())
    SetEventEx(10, "OnClick", Cast(Any Ptr, Handler), 0)
End Property
Property QLISTVIEW.OnClick(ByVal Handler As Sub(ByRef Sender As QLISTVIEW))
    SetEventEx(10, "OnClick", Cast(Any Ptr, Handler), 3)
End Property
Property QLISTVIEW.OnDblClick(ByVal Handler As Sub())
    SetEventEx(11, "OnDblClick", Cast(Any Ptr, Handler), 0)
End Property
Property QLISTVIEW.OnDblClick(ByVal Handler As Sub(ByRef Sender As QLISTVIEW))
    SetEventEx(11, "OnDblClick", Cast(Any Ptr, Handler), 3)
End Property
Property QLISTVIEW.OnChange(ByVal Handler As Sub(ByVal Index As Long, ByVal Change As Long))
    SetEventEx(22, "OnChange", Cast(Any Ptr, Handler), 1)
End Property
Property QLISTVIEW.OnChange(ByVal Handler As Sub(ByVal Index As Long, ByVal Change As Long, ByRef Sender As QLISTVIEW))
    SetEventEx(22, "OnChange", Cast(Any Ptr, Handler), 2)
End Property
Property QLISTVIEW.OnChange(ByVal Handler As Sub())
    SetEventEx(22, "OnChange", Cast(Any Ptr, Handler), 0)
End Property
Property QLISTVIEW.OnChange(ByVal Handler As Sub(ByRef Sender As QLISTVIEW))
    SetEventEx(22, "OnChange", Cast(Any Ptr, Handler), 3)
End Property
Property QLISTVIEW.OnColumnClick(ByVal Handler As Sub(ByVal ColumnNum As Long))
    SetEventEx(23, "OnColumnClick", Cast(Any Ptr, Handler), 1)
End Property
Property QLISTVIEW.OnColumnClick(ByVal Handler As Sub(ByVal ColumnNum As Long, ByRef Sender As QLISTVIEW))
    SetEventEx(23, "OnColumnClick", Cast(Any Ptr, Handler), 2)
End Property
Property QLISTVIEW.OnColumnClick(ByVal Handler As Sub())
    SetEventEx(23, "OnColumnClick", Cast(Any Ptr, Handler), 0)
End Property
Property QLISTVIEW.OnColumnClick(ByVal Handler As Sub(ByRef Sender As QLISTVIEW))
    SetEventEx(23, "OnColumnClick", Cast(Any Ptr, Handler), 3)
End Property
Property QLISTVIEW.OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    SetEventEx(0, "OnKeyDown", Cast(Any Ptr, Handler), 1)
End Property
Property QLISTVIEW.OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QLISTVIEW))
    SetEventEx(0, "OnKeyDown", Cast(Any Ptr, Handler), 2)
End Property
Property QLISTVIEW.OnKeyDown(ByVal Handler As Sub())
    SetEventEx(0, "OnKeyDown", Cast(Any Ptr, Handler), 0)
End Property
Property QLISTVIEW.OnKeyDown(ByVal Handler As Sub(ByRef Sender As QLISTVIEW))
    SetEventEx(0, "OnKeyDown", Cast(Any Ptr, Handler), 3)
End Property
Property QLISTVIEW.OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    SetEventEx(1, "OnKeyUp", Cast(Any Ptr, Handler), 1)
End Property
Property QLISTVIEW.OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QLISTVIEW))
    SetEventEx(1, "OnKeyUp", Cast(Any Ptr, Handler), 2)
End Property
Property QLISTVIEW.OnKeyUp(ByVal Handler As Sub())
    SetEventEx(1, "OnKeyUp", Cast(Any Ptr, Handler), 0)
End Property
Property QLISTVIEW.OnKeyUp(ByVal Handler As Sub(ByRef Sender As QLISTVIEW))
    SetEventEx(1, "OnKeyUp", Cast(Any Ptr, Handler), 3)
End Property
Property QLISTVIEW.OnKeyPress(ByVal Handler As Sub(ByRef Key As Long))
    SetEventEx(2, "OnKeyPress", Cast(Any Ptr, Handler), 1)
End Property
Property QLISTVIEW.OnKeyPress(ByVal Handler As Sub(ByRef Key As Long, ByRef Sender As QLISTVIEW))
    SetEventEx(2, "OnKeyPress", Cast(Any Ptr, Handler), 2)
End Property
Property QLISTVIEW.OnKeyPress(ByVal Handler As Sub())
    SetEventEx(2, "OnKeyPress", Cast(Any Ptr, Handler), 0)
End Property
Property QLISTVIEW.OnKeyPress(ByVal Handler As Sub(ByRef Sender As QLISTVIEW))
    SetEventEx(2, "OnKeyPress", Cast(Any Ptr, Handler), 3)
End Property
Property QLISTVIEW.OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(3, "OnMouseDown", Cast(Any Ptr, Handler), 1)
End Property
Property QLISTVIEW.OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QLISTVIEW))
    SetEventEx(3, "OnMouseDown", Cast(Any Ptr, Handler), 2)
End Property
Property QLISTVIEW.OnMouseDown(ByVal Handler As Sub())
    SetEventEx(3, "OnMouseDown", Cast(Any Ptr, Handler), 0)
End Property
Property QLISTVIEW.OnMouseDown(ByVal Handler As Sub(ByRef Sender As QLISTVIEW))
    SetEventEx(3, "OnMouseDown", Cast(Any Ptr, Handler), 3)
End Property
Property QLISTVIEW.OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(4, "OnMouseUp", Cast(Any Ptr, Handler), 1)
End Property
Property QLISTVIEW.OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QLISTVIEW))
    SetEventEx(4, "OnMouseUp", Cast(Any Ptr, Handler), 2)
End Property
Property QLISTVIEW.OnMouseUp(ByVal Handler As Sub())
    SetEventEx(4, "OnMouseUp", Cast(Any Ptr, Handler), 0)
End Property
Property QLISTVIEW.OnMouseUp(ByVal Handler As Sub(ByRef Sender As QLISTVIEW))
    SetEventEx(4, "OnMouseUp", Cast(Any Ptr, Handler), 3)
End Property
Property QLISTVIEW.OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(5, "OnMouseMove", Cast(Any Ptr, Handler), 1)
End Property
Property QLISTVIEW.OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QLISTVIEW))
    SetEventEx(5, "OnMouseMove", Cast(Any Ptr, Handler), 2)
End Property
Property QLISTVIEW.OnMouseMove(ByVal Handler As Sub())
    SetEventEx(5, "OnMouseMove", Cast(Any Ptr, Handler), 0)
End Property
Property QLISTVIEW.OnMouseMove(ByVal Handler As Sub(ByRef Sender As QLISTVIEW))
    SetEventEx(5, "OnMouseMove", Cast(Any Ptr, Handler), 3)
End Property
Property QLISTVIEW.OnKeyPressed(ByVal Handler As Sub(ByRef Key As Long))
    SetEventEx(2, "OnKeyPress", Cast(Any Ptr, Handler), 1)
End Property
Property QLISTVIEW.OnKeyPressed(ByVal Handler As Sub(ByRef Key As Long, ByRef Sender As QLISTVIEW))
    SetEventEx(2, "OnKeyPress", Cast(Any Ptr, Handler), 2)
End Property
Property QLISTVIEW.OnKeyPressed(ByVal Handler As Sub())
    SetEventEx(2, "OnKeyPress", Cast(Any Ptr, Handler), 0)
End Property
Property QLISTVIEW.OnKeyPressed(ByVal Handler As Sub(ByRef Sender As QLISTVIEW))
    SetEventEx(2, "OnKeyPress", Cast(Any Ptr, Handler), 3)
End Property

' ---------------------------------------------------------------------------
'  QFONTDIALOG - окно выбора шрифта (TFontDialog); GetFont(F) - шрифт окна из F,
'  SetFont(F) - выбранный шрифт в F; AddStyles fsBold 0..fsStrikeOut 3,
'  AddOptions fdAnsiOnly 0..fdApplyButton 15 - номера как в RapidQ
' ---------------------------------------------------------------------------

Type QFONTDIALOG
    RqObj As Any Ptr
    OnApplyProc As Sub(ByRef Sender As QFONTDIALOG)
    OnApplyProcPlain As Sub()
    Declare Constructor()
    Declare Property Color() As Long
    Declare Property Color(ByVal Value As Long)
    Declare Property FontCount() As Long
    Declare Property MaxFontSize() As Long
    Declare Property MaxFontSize(ByVal Value As Long)
    Declare Property MinFontSize() As Long
    Declare Property MinFontSize(ByVal Value As Long)
    Declare Property Name() As String
    Declare Property Name(ByRef Value As String)
    Declare Property Size() As Long
    Declare Property Size(ByVal Value As Long)
    Declare Property FontName(ByVal ItemNum As Long) As String
    Declare Sub StrCall(ByRef MethodName As String, ByRef Text1 As String, ByVal IntArg1 As Long = 0, ByVal IntArg2 As Long = 0)
    Declare Sub AddStyles(ByVal Num1 As Long, ByVal Num2 As Long = -1, ByVal Num3 As Long = -1, ByVal Num4 As Long = -1)
    Declare Sub DelStyles(ByVal Num1 As Long, ByVal Num2 As Long = -1, ByVal Num3 As Long = -1, ByVal Num4 As Long = -1)
    Declare Sub AddOptions(ByVal Num1 As Long, ByVal Num2 As Long = -1, ByVal Num3 As Long = -1, ByVal Num4 As Long = -1)
    Declare Sub DelOptions(ByVal Num1 As Long, ByVal Num2 As Long = -1, ByVal Num3 As Long = -1, ByVal Num4 As Long = -1)
    ' 1 - шрифт выбран, 0 - отмена
    Declare Function Execute() As Long
    Declare Sub GetFont(ByRef SrcFont As QFONT)
    Declare Sub SetFont(ByRef DstFont As QFONT)
    Declare Property OnApply(ByVal Handler As Sub())
    Declare Property OnApply(ByVal Handler As Sub(ByRef Sender As QFONTDIALOG))
End Type

Constructor QFONTDIALOG()
    RqObj = RqLclNew("QFONTDIALOG", @This)
End Constructor
Property QFONTDIALOG.Color() As Long
    Return RqGetInt(RqObj, "Color")
End Property
Property QFONTDIALOG.Color(ByVal Value As Long)
    RqLclSetInt(RqObj, "Color", Value)
End Property
Property QFONTDIALOG.FontCount() As Long
    Return RqGetInt(RqObj, "FontCount")
End Property
Property QFONTDIALOG.MaxFontSize() As Long
    Return RqGetInt(RqObj, "MaxFontSize")
End Property
Property QFONTDIALOG.MaxFontSize(ByVal Value As Long)
    RqLclSetInt(RqObj, "MaxFontSize", Value)
End Property
Property QFONTDIALOG.MinFontSize() As Long
    Return RqGetInt(RqObj, "MinFontSize")
End Property
Property QFONTDIALOG.MinFontSize(ByVal Value As Long)
    RqLclSetInt(RqObj, "MinFontSize", Value)
End Property
Property QFONTDIALOG.Name() As String
    Return RqLclGetStr(RqObj, "Name")
End Property
Property QFONTDIALOG.Name(ByRef Value As String)
    RqLclSetStr(RqObj, "Name", Value)
End Property
Property QFONTDIALOG.Size() As Long
    Return RqGetInt(RqObj, "Size")
End Property
Property QFONTDIALOG.Size(ByVal Value As Long)
    RqLclSetInt(RqObj, "Size", Value)
End Property
' Имя шрифта системы по номеру (с 0)
Property QFONTDIALOG.FontName(ByVal ItemNum As Long) As String
    Return RqLclGetItemEx(RqObj, "FontName", ItemNum, "QFONTDIALOG.FontName")
End Property
Sub QFONTDIALOG.StrCall(ByRef MethodName As String, ByRef Text1 As String, ByVal IntArg1 As Long = 0, ByVal IntArg2 As Long = 0)
    If RqCallEx(RqObj, MethodName, StrPtr(Text1), IntArg1, IntArg2, 0, 0, 0) = 0 Then
        RqLclClassError("QFONTDIALOG." & MethodName)
    End If
End Sub
Sub QFONTDIALOG.AddStyles(ByVal Num1 As Long, ByVal Num2 As Long = -1, ByVal Num3 As Long = -1, ByVal Num4 As Long = -1)
    Dim NumList(1 To 4) As Long = {Num1, Num2, Num3, Num4}
    For ArgIdx As Long = 1 To 4
        If (ArgIdx > 1) AndAlso (NumList(ArgIdx) = -1) Then Exit For
        StrCall("AddStyles", "", NumList(ArgIdx))
    Next
End Sub
Sub QFONTDIALOG.DelStyles(ByVal Num1 As Long, ByVal Num2 As Long = -1, ByVal Num3 As Long = -1, ByVal Num4 As Long = -1)
    Dim NumList(1 To 4) As Long = {Num1, Num2, Num3, Num4}
    For ArgIdx As Long = 1 To 4
        If (ArgIdx > 1) AndAlso (NumList(ArgIdx) = -1) Then Exit For
        StrCall("DelStyles", "", NumList(ArgIdx))
    Next
End Sub
Sub QFONTDIALOG.AddOptions(ByVal Num1 As Long, ByVal Num2 As Long = -1, ByVal Num3 As Long = -1, ByVal Num4 As Long = -1)
    Dim NumList(1 To 4) As Long = {Num1, Num2, Num3, Num4}
    For ArgIdx As Long = 1 To 4
        If (ArgIdx > 1) AndAlso (NumList(ArgIdx) = -1) Then Exit For
        StrCall("AddOptions", "", NumList(ArgIdx))
    Next
End Sub
Sub QFONTDIALOG.DelOptions(ByVal Num1 As Long, ByVal Num2 As Long = -1, ByVal Num3 As Long = -1, ByVal Num4 As Long = -1)
    Dim NumList(1 To 4) As Long = {Num1, Num2, Num3, Num4}
    For ArgIdx As Long = 1 To 4
        If (ArgIdx > 1) AndAlso (NumList(ArgIdx) = -1) Then Exit For
        StrCall("DelOptions", "", NumList(ArgIdx))
    Next
End Sub
Function QFONTDIALOG.Execute() As Long
    Return RqLclCallValue(RqObj, "Execute")
End Function
' Шрифт окна берётся из SrcFont (до Execute)
Sub QFONTDIALOG.GetFont(ByRef SrcFont As QFONT)
    If RqSetObj(RqGetObj(RqObj, "Font"), "Assign", SrcFont.RqObj) = 0 Then RqLclShowError("QFONTDIALOG.GetFont")
End Sub
' Выбранный шрифт - в DstFont (после Execute)
Sub QFONTDIALOG.SetFont(ByRef DstFont As QFONT)
    If RqSetObj(DstFont.RqObj, "Assign", RqGetObj(RqObj, "Font")) = 0 Then RqLclShowError("QFONTDIALOG.SetFont")
End Sub
Private Sub QFONTDIALOG_ApplyEvent stdcall (ByVal UserPtr As Any Ptr, ByVal ObjPtr As Any Ptr)
    Dim DialogPtr As QFONTDIALOG Ptr = UserPtr
    If DialogPtr->OnApplyProc <> 0 Then DialogPtr->OnApplyProc(*DialogPtr)
    If DialogPtr->OnApplyProcPlain <> 0 Then DialogPtr->OnApplyProcPlain()
End Sub
' OnApply - кнопка Apply (есть при AddOptions fdApplyButton)
Property QFONTDIALOG.OnApply(ByVal Handler As Sub())
    OnApplyProcPlain = Handler
    OnApplyProc = 0
    If RqSetEvent(RqObj, "OnApply", @QFONTDIALOG_ApplyEvent) = 0 Then RqLclShowError("OnApply")
End Property
Property QFONTDIALOG.OnApply(ByVal Handler As Sub(ByRef Sender As QFONTDIALOG))
    OnApplyProc = Handler
    OnApplyProcPlain = 0
    If RqSetEvent(RqObj, "OnApply", @QFONTDIALOG_ApplyEvent) = 0 Then RqLclShowError("OnApply")
End Property
