#include once "rqstrlist.bi"
Dim StringList1 As QSTRINGLIST
Dim StringList2 As QSTRINGLIST
StringList1.AddItems "Oranges","Apples"
StringList2.AddItems "Byte","Word","Integer"
StringList1.AddList(StringList2)
StringList1.Sort
Print StringList1.Text;
Print StringList1.Item(3)
Print StringList1.IndexOf("word")
Print StringList1.IndexOf("hi")
Dim StringList As QSTRINGLIST
Print StringList.Parse("James:Brown:555-3454:House",":")
Print StringList.Build(0,StringList.ItemCount-1,",")
' sorted + duplicates
Dim SortList As QSTRINGLIST
SortList.Sorted = 1
SortList.AddItems "яблоко", "Банан", "абрикос", "банан", "Zeta", "alpha"
Print SortList.Build(0, SortList.ItemCount - 1, "|"); " count"; SortList.ItemCount
SortList.Duplicates = 1
SortList.AddItems "БАНАН"
Print SortList.Build(0, SortList.ItemCount - 1, "|")
' text set
Dim TextList As QSTRINGLIST
TextList.Text = "a" & Chr(13,10) & "b" & Chr(10) & "c" & Chr(13) & Chr(13,10) & "e"
Print TextList.ItemCount; " "; TextList.Build(0, 9, ",")
TextList.InsertItem 0, "first"
TextList.DelItems 2, 2
Print TextList.Build(0, 9, ",")
TextList.Exchange 0, 1
Print TextList.Item(0); TextList.Item(1)
Print "[" & TextList.Item(10) & "]"
TextList.SaveToFile "sl.txt"
Dim LoadList As QSTRINGLIST
LoadList.LoadFromFile "sl.txt"
Print LoadList.ItemCount; " "; LoadList.Build(0, 9, ",")
LoadList.LoadFromFile "nofile.txt"
Dim Mem As QMEMORYSTREAM
TextList.SaveToStream Mem
Mem.Position = 0
LoadList.LoadFromStream Mem
Print LoadList.Item(0)
Dim BigList As QSTRINGLIST
For ItemIdx As Long = 1 To 100000
    BigList.AddItems Str(100000 - ItemIdx)
Next
BigList.Sort
Print BigList.Item(0); " "; BigList.Item(99999); " "; BigList.ItemCount
