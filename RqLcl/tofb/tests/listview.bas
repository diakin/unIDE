$APPTYPE CONSOLE
' QLISTVIEW (and an array of QLISTVIEW, as in RQdebugger) and QFONTDIALOG
DECLARE FUNCTION FindWindowByClass LIB "user32" ALIAS "FindWindowA" (ClassName AS STRING, WindowName AS LONG) AS LONG
DECLARE FUNCTION PostMessageA LIB "user32" ALIAS "PostMessageA" (hwnd AS LONG, wMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
DECLARE SUB GoSubs
DECLARE SUB ListChanged (Index AS INTEGER, Change AS BYTE)
DECLARE SUB HeaderClick (Column AS INTEGER)
DECLARE SUB CloseDialog
CONST vsReport = 3
CONST fdApplyButton = 15
DIM Changes AS INTEGER, Found AS INTEGER, Row AS INTEGER
DIM LastIndex AS INTEGER, LastChange AS INTEGER
DIM WindowsItemCount AS INTEGER
WindowsItemCount = 3

CREATE Form AS QFORM
  Caption = "List view"
  Width = 400 : Height = 300
  CREATE Panel1 AS QPANEL
    Align = 5
  END CREATE
END CREATE

DIM SubsListBox (WindowsItemCount-1) AS QListView
FOR Row = 0 TO WindowsItemCount - 1
  SubsListBox(Row).Parent = Panel1
  SubsListBox(Row).Align = 5
  SubsListBox(Row).AddColumns "Name", "Line", "File"
  SubsListBox(Row).Column(0).Width = 300
  SubsListBox(Row).GridLines = 1
  SubsListBox(Row).ViewStyle = vsReport
  SubsListBox(Row).OnClick = GoSubs
  SubsListBox(Row).Tag = Row
  SubsListBox(Row).Visible = (Row = 1)
NEXT Row

SUB GoSubs
END SUB

SUB ListChanged (Index AS INTEGER, Change AS BYTE)
  Changes = Changes + 1
  LastIndex = Index
  LastChange = Change
END SUB

SUB HeaderClick (Column AS INTEGER)
END SUB

SUB CloseDialog
  DIM Wnd AS LONG
  Wnd = FindWindowByClass("#32770", 0)
  IF Wnd <> 0 THEN
    Found = 1
    PostMessageA(Wnd, &H10, 0, 0)
  END IF
END SUB

Form.Show
WITH SubsListBox(1)
  .Clear
  .AddItems "Main", "Init"
  .AddSubItem 0, "10"
  .AddSubItem 0, "main.bas"
  .AddSubItem 1, "20"
  PRINT "items "; .ItemCount; " columns "; .ColumnsCount; " tag "; .Tag; " visible "; .Visible
  PRINT .Item(0).Caption; " "; .SubItem(0, 0); " "; .SubItem(0, 1); " | "; .Item(1).Caption; " "; .SubItem(1, 0)
  PRINT "width "; .Column(0).Width; " caption "; .Column(2).Caption; " view "; .ViewStyle; " grid "; .GridLines
END WITH
SubsListBox(1).SubItem(1, 2) = "init.inc"
PRINT "padded '"; SubsListBox(1).SubItem(1, 1); "' "; SubsListBox(1).SubItem(1, 2)
SubsListBox(1).ItemIndex = 1
PRINT "itemindex "; SubsListBox(1).ItemIndex; " selected "; SubsListBox(1).Selected(1); " "; SubsListBox(1).Item(1).Selected; " selcount "; SubsListBox(1).SelCount
SubsListBox(1).Item(0).Caption = "Start"
SubsListBox(1).InsertItem 1, "Middle"
SubsListBox(1).SwapItem 0, 2
FOR Row = 0 TO SubsListBox(1).ItemCount - 1
  PRINT Row; " "; SubsListBox(1).Item(Row).Caption; " index "; SubsListBox(1).Item(Row).Index
NEXT Row
SubsListBox(1).InsertSubItem 2, 0, "5"
SubsListBox(1).DelSubItem 2, 1
PRINT "subitems of 2: "; SubsListBox(1).SubItem(2, 0); " "; SubsListBox(1).SubItem(2, 1)
SubsListBox(1).DelItems 0
PRINT "after del "; SubsListBox(1).ItemCount; " first "; SubsListBox(1).Item(0).Caption

'' OnChange (Index, Change): selection from the program - Change 2 (state)
SubsListBox(1).AddItems "a", "b"
SubsListBox(1).OnChange = ListChanged
SubsListBox(1).OnColumnClick = HeaderClick
SubsListBox(1).ItemIndex = 3
DOEVENTS
IF Changes > 0 THEN PRINT "onchange "; LastIndex; " "; LastChange ELSE PRINT "no onchange"

' CheckBoxes, AddColumns with more arguments than overloads
SubsListBox(0).CheckBoxes = 1
SubsListBox(0).AddItems "x", "y"
SubsListBox(0).Item(1).Checked = 1
PRINT "checked "; SubsListBox(0).Item(0).Checked; SubsListBox(0).Item(1).Checked
SubsListBox(0).ClearColumns
SubsListBox(0).AddColumns "c1", "c2", "c3", "c4", "c5", "c6", "c7"
PRINT "columns "; SubsListBox(0).ColumnsCount; " last "; SubsListBox(0).Column(6).Caption
SubsListBox(0).ColumnsCount = 2
PRINT "columns "; SubsListBox(0).ColumnsCount

' QFONTDIALOG
DIM FontDialog AS QFontDialog
DIM HiLiteFont AS QFONT
DIM StrFont AS QFONT
HiLiteFont.Name = "Courier New"
HiLiteFont.Size = 12
FontDialog.Name = "FixedSys"
PRINT "dialog name "; FontDialog.Name
FontDialog.GetFont(HiLiteFont)
PRINT "from font "; FontDialog.Name; " "; FontDialog.Size
FontDialog.Size = 14
FontDialog.Color = &HFF
FontDialog.AddStyles 0, 1
FontDialog.AddOptions fdApplyButton
FontDialog.MinFontSize = 6
FontDialog.MaxFontSize = 30
FontDialog.SetFont(StrFont)
PRINT "to font "; StrFont.Name; " "; StrFont.Size; " color "; StrFont.Color; " bold "; StrFont.Bold; " italic "; StrFont.Italic
PRINT "sizes "; FontDialog.MinFontSize; FontDialog.MaxFontSize
IF FontDialog.FontCount > 0 AND LEN(FontDialog.FontName(0)) > 0 THEN PRINT "fonts listed"

DIM DlgTimer AS QTIMER
DlgTimer.Interval = 500
DlgTimer.OnTimer = CloseDialog
DlgTimer.Enabled = 1
PRINT "execute "; FontDialog.Execute; " closed "; Found
DlgTimer.Enabled = 0
Form.Close
