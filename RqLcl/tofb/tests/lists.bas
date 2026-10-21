$APPTYPE CONSOLE
DIM StringList1 AS QStringList
DIM StringList2 AS QStringList
StringList1.AddItems "Oranges","Apples"
StringList2.AddItems "Byte","Word","Integer"
StringList1.AddList(StringList2)
StringList1.Sort
?StringList1.Text
?StringList1.Item(3)
?StringList1.IndexOf("Word")
?StringList1.IndexOf("hi")
DIM StringList AS QSTRINGLIST
StringList.Parse("James:Brown:555-3454:House",":")
PRINT StringList.Build(0,StringList.ItemCount-1,",")
StringList.Item(0) = "Jim"
s$ = StringList.Item(0) + "!"
PRINT s$; " "; StringList.ItemCount

DIM Form AS QFORM
DIM Grid AS QSTRINGGRID
DIM Registry AS QREGISTRY
DIM DirTree AS QDIRTREE

SUB ClearGrid (Sender AS QSTRINGGRID)
    FOR y = Sender.FixedRows TO Sender.RowCount - 1
        FOR x = Sender.FixedCols TO Sender.ColCount - 1
            Sender.Cell(x, y) = ""
        NEXT x
    NEXT y
END SUB

SUB FormShow
    Grid.Cell(1, 1) = "a"
    Grid.Cell(2, 2) = "b" + "c"
    IF Grid.Cell(2, 2) = "bc" THEN Grid.Cell(3, 3) = "yes"
    PRINT Grid.Cell(1, 1); Grid.Cell(2, 2); Grid.Cell(3, 3)
    ClearGrid Grid
    PRINT "["; Grid.Cell(1, 1); Grid.Cell(3, 3); "]"
    Grid.ColWidths(1) = 77
    PRINT Grid.ColWidths(1)
    DirTree.Directory = "C:\windows"
    PRINT LCASE$(DirTree.Directory)
    Form.Close
END SUB

Registry.OpenKey("Software\RqLclTest2", 1)
Registry.WriteString("Name", "value1")
PRINT Registry.ReadString("Name"); " "; Registry.ValueExists("Name")
Registry.CloseKey
PRINT Registry.DeleteKey("\Software\RqLclTest2")

Grid.Parent = Form
DirTree.Parent = Form
DirTree.Left = 350
Form.OnShow = FormShow
Form.ShowModal
