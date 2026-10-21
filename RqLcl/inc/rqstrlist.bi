' ---------------------------------------------------------------------------
'  rqstrlist.bi - QSTRINGLIST RapidQ на FreeBASIC (без DLL)
'  (rapidq_ref/html_doc/qstringlist.html). Поведение - как у TStringList
'  Delphi, на котором сделан RapidQ:
'  - IndexOf, Find, Sort, Sorted - без учёта регистра, по правилам
'    Windows (CompareString, как AnsiCompareText);
'  - Text - строки через CR LF, после последней тоже CR LF; при записи
'    Text разделитель - CR LF, LF или CR;
'  - Duplicates (dupIgnore 0, dupAccept 1, dupError 2) действует только
'    при Sorted = 1.
'  Ошибки (номер вне списка, нет файла): Smart - предупреждение в лог и
'  stderr, программа продолжает работу; Compat - сообщение и конец
'  программы, как в RapidQ.
'  AddItems и DelItems - до шести параметров (в RapidQ не ограничено).
' ---------------------------------------------------------------------------

#pragma once

#include once "rqrt.bi"
#include once "rqstream.bi"

Declare Function RqRtCompareString Lib "kernel32" Alias "CompareStringA" ( _
    ByVal Locale As ULong, ByVal CmpFlags As ULong, _
    ByVal Text1 As ZString Ptr, ByVal Len1 As Long, _
    ByVal Text2 As ZString Ptr, ByVal Len2 As Long) As Long

' Сравнение без учёта регистра: <0, 0, >0
Function RqRtCompareText(ByRef Text1 As String, ByRef Text2 As String) As Long
    ' LOCALE_USER_DEFAULT, NORM_IGNORECASE; результат 1 / 2 / 3
    Return RqRtCompareString(&h400, 1, StrPtr(Text1), Len(Text1), _
                             StrPtr(Text2), Len(Text2)) - 2
End Function

' Весь файл в строку; 0 - не открылся
Function RqRtReadFile(ByRef FileName As String, ByRef FileData As String) As Long
    Dim FileNum As Long = FreeFile
    FileData = ""
    If Open(FileName For Binary Access Read As #FileNum) <> 0 Then Return 0
    If LOF(FileNum) > 0 Then
        FileData = Space(LOF(FileNum))
        Get #FileNum, , FileData
    End If
    Close #FileNum
    Return 1
End Function

Function RqRtWriteFile(ByRef FileName As String, ByRef FileData As String) As Long
    Dim FileNum As Long = FreeFile
    If Open(FileName For Output As #FileNum) <> 0 Then Return 0
    Close #FileNum
    If Open(FileName For Binary Access Write As #FileNum) <> 0 Then Return 0
    If Len(FileData) > 0 Then Put #FileNum, , FileData
    Close #FileNum
    Return 1
End Function

Type QSTRINGLIST
    ItemList(Any) As String
    ItemTotal As Long
    SortedFlag As Long
    DupMode As Long
    Declare Property Item(ByVal ItemIndex As Long) As String
    Declare Property Item(ByVal ItemIndex As Long, ByRef Value As String)
    Declare Property ItemCount() As Long
    Declare Property Text() As String
    Declare Property Text(ByRef Value As String)
    Declare Property Sorted() As Long
    Declare Property Sorted(ByVal Value As Long)
    Declare Property Duplicates() As Long
    Declare Property Duplicates(ByVal Value As Long)
    Declare Sub AddItems Overload (ByRef Text1 As String)
    Declare Sub AddItems Overload (ByRef Text1 As String, ByRef Text2 As String)
    Declare Sub AddItems Overload (ByRef Text1 As String, ByRef Text2 As String, _
        ByRef Text3 As String)
    Declare Sub AddItems Overload (ByRef Text1 As String, ByRef Text2 As String, _
        ByRef Text3 As String, ByRef Text4 As String)
    Declare Sub AddItems Overload (ByRef Text1 As String, ByRef Text2 As String, _
        ByRef Text3 As String, ByRef Text4 As String, ByRef Text5 As String)
    Declare Sub AddItems Overload (ByRef Text1 As String, ByRef Text2 As String, _
        ByRef Text3 As String, ByRef Text4 As String, ByRef Text5 As String, _
        ByRef Text6 As String)
    Declare Sub AddList(ByRef Source As QSTRINGLIST)
    Declare Function Build(ByVal StartIdx As Long, ByVal EndIdx As Long, _
        ByRef Delim As String) As String
    Declare Sub Clear()
    Declare Sub DelItems(ByVal Index1 As Long, ByVal Index2 As Long = -1, _
        ByVal Index3 As Long = -1, ByVal Index4 As Long = -1, _
        ByVal Index5 As Long = -1, ByVal Index6 As Long = -1)
    Declare Sub Exchange(ByVal Index1 As Long, ByVal Index2 As Long)
    Declare Function Find(ByRef Value As String) As Long
    Declare Function IndexOf(ByRef Value As String) As Long
    Declare Sub InsertItem(ByVal ItemIndex As Long, ByRef Value As String)
    Declare Sub LoadFromFile(ByRef FileName As String)
    Declare Sub LoadFromStream(ByRef Stream As RqStream)
    Declare Function Parse(ByRef Source As String, ByRef Delim As String) As Long
    Declare Sub SaveToFile(ByRef FileName As String)
    Declare Sub SaveToStream(ByRef Stream As RqStream)
    Declare Sub Sort()
    ' служебное
    Declare Sub AddOne(ByRef Value As String)
    Declare Sub InsertAt(ByVal ItemIndex As Long, ByRef Value As String)
    Declare Sub DeleteAt(ByVal ItemIndex As Long)
    Declare Function FindSorted(ByRef Value As String, ByRef FoundIdx As Long) As Long
    Declare Function CheckIndex(ByVal ItemIndex As Long, ByRef What As String) As Long
    Declare Sub QuickSort(ByVal LowIdx As Long, ByVal HighIdx As Long)
End Type

' Номер в списке? Нет - ошибка (текст как у Delphi: List index out of bounds)
Function QSTRINGLIST.CheckIndex(ByVal ItemIndex As Long, ByRef What As String) As Long
    If (ItemIndex >= 0) AndAlso (ItemIndex < ItemTotal) Then Return 1
    RqRtClassError("QSTRINGLIST." & What & ": List index out of bounds (" & _
        ItemIndex & "), ItemCount = " & ItemTotal)
    Return 0
End Function

Sub QSTRINGLIST.InsertAt(ByVal ItemIndex As Long, ByRef Value As String)
    If ItemTotal > UBound(ItemList) Then
        Dim NewCap As Long = (UBound(ItemList) + 1) * 2
        If NewCap < 16 Then NewCap = 16
        ReDim Preserve ItemList(0 To NewCap - 1)
    End If
    For MoveIdx As Long = ItemTotal To ItemIndex + 1 Step -1
        Swap ItemList(MoveIdx), ItemList(MoveIdx - 1)
    Next
    ItemList(ItemIndex) = Value
    ItemTotal += 1
End Sub

Sub QSTRINGLIST.DeleteAt(ByVal ItemIndex As Long)
    For MoveIdx As Long = ItemIndex To ItemTotal - 2
        Swap ItemList(MoveIdx), ItemList(MoveIdx + 1)
    Next
    ItemTotal -= 1
    ItemList(ItemTotal) = ""
End Sub

' Двоичный поиск в отсортированном списке: 1 - найдено (FoundIdx - номер),
' 0 - нет (FoundIdx - место для вставки)
Function QSTRINGLIST.FindSorted(ByRef Value As String, ByRef FoundIdx As Long) As Long
    Dim LowIdx As Long = 0
    Dim HighIdx As Long = ItemTotal - 1
    Dim Found As Long = 0
    While LowIdx <= HighIdx
        Dim MidIdx As Long = (LowIdx + HighIdx) \ 2
        Dim CmpResult As Long = RqRtCompareText(ItemList(MidIdx), Value)
        If CmpResult < 0 Then
            LowIdx = MidIdx + 1
        Else
            HighIdx = MidIdx - 1
            If CmpResult = 0 Then
                Found = 1
                ' у dupAccept - первый из равных
            End If
        End If
    Wend
    FoundIdx = LowIdx
    Return Found
End Function

Sub QSTRINGLIST.AddOne(ByRef Value As String)
    Dim InsertIdx As Long
    If SortedFlag = 0 Then
        InsertAt(ItemTotal, Value)
        Exit Sub
    End If
    If FindSorted(Value, InsertIdx) Then
        If DupMode = 0 Then Exit Sub               ' dupIgnore
        If DupMode = 2 Then                        ' dupError
            RqRtClassError("QSTRINGLIST.AddItems: String list does not allow duplicates (" & Value & ")")
            Exit Sub
        End If
    End If
    InsertAt(InsertIdx, Value)
End Sub

Property QSTRINGLIST.Item(ByVal ItemIndex As Long) As String
    If CheckIndex(ItemIndex, "Item") = 0 Then Return ""
    Return ItemList(ItemIndex)
End Property

Property QSTRINGLIST.Item(ByVal ItemIndex As Long, ByRef Value As String)
    If CheckIndex(ItemIndex, "Item") = 0 Then Exit Property
    ItemList(ItemIndex) = Value
    If SortedFlag Then
        ' Delphi: Operation not allowed on sorted list
#ifdef RQ_COMPAT
        RqRtClassError("QSTRINGLIST.Item: Operation not allowed on sorted list")
#else
        RqRtWarn("QSTRINGLIST.Item = ...: список Sorted, порядок восстановлен", "", 0)
        Sort()
#endif
    End If
End Property

Property QSTRINGLIST.ItemCount() As Long
    Return ItemTotal
End Property

Property QSTRINGLIST.Text() As String
    Dim TotalLen As Long = 0
    For ItemIdx As Long = 0 To ItemTotal - 1
        TotalLen += Len(ItemList(ItemIdx)) + 2
    Next
    Dim Joined As String = Space(TotalLen)
    Dim WritePos As Long = 1
    For ItemIdx As Long = 0 To ItemTotal - 1
        Dim ItemLen As Long = Len(ItemList(ItemIdx))
        If ItemLen > 0 Then Mid(Joined, WritePos, ItemLen) = ItemList(ItemIdx)
        WritePos += ItemLen
        Mid(Joined, WritePos, 2) = Chr(13, 10)
        WritePos += 2
    Next
    Return Joined
End Property

Property QSTRINGLIST.Text(ByRef Value As String)
    Clear()
    Dim StartPos As Long = 1
    Dim TextLen As Long = Len(Value)
    Dim ScanPos As Long = 1
    While ScanPos <= TextLen
        Dim CharCode As Long = Value[ScanPos - 1]
        If (CharCode = 13) OrElse (CharCode = 10) Then
            AddOne(Mid(Value, StartPos, ScanPos - StartPos))
            If (CharCode = 13) AndAlso (ScanPos < TextLen) AndAlso (Value[ScanPos] = 10) Then
                ScanPos += 1
            End If
            StartPos = ScanPos + 1
        End If
        ScanPos += 1
    Wend
    If StartPos <= TextLen Then AddOne(Mid(Value, StartPos))
End Property

Property QSTRINGLIST.Sorted() As Long
    Return SortedFlag
End Property

Property QSTRINGLIST.Sorted(ByVal Value As Long)
    Dim NewFlag As Long = IIf(Value <> 0, 1, 0)
    If NewFlag = SortedFlag Then Exit Property
    SortedFlag = NewFlag
    If SortedFlag Then Sort()
End Property

Property QSTRINGLIST.Duplicates() As Long
    Return DupMode
End Property

Property QSTRINGLIST.Duplicates(ByVal Value As Long)
    DupMode = Value
End Property

Sub QSTRINGLIST.AddItems(ByRef Text1 As String)
    AddOne(Text1)
End Sub
Sub QSTRINGLIST.AddItems(ByRef Text1 As String, ByRef Text2 As String)
    AddOne(Text1) : AddOne(Text2)
End Sub
Sub QSTRINGLIST.AddItems(ByRef Text1 As String, ByRef Text2 As String, _
        ByRef Text3 As String)
    AddOne(Text1) : AddOne(Text2) : AddOne(Text3)
End Sub
Sub QSTRINGLIST.AddItems(ByRef Text1 As String, ByRef Text2 As String, _
        ByRef Text3 As String, ByRef Text4 As String)
    AddOne(Text1) : AddOne(Text2) : AddOne(Text3) : AddOne(Text4)
End Sub
Sub QSTRINGLIST.AddItems(ByRef Text1 As String, ByRef Text2 As String, _
        ByRef Text3 As String, ByRef Text4 As String, ByRef Text5 As String)
    AddOne(Text1) : AddOne(Text2) : AddOne(Text3) : AddOne(Text4)
    AddOne(Text5)
End Sub
Sub QSTRINGLIST.AddItems(ByRef Text1 As String, ByRef Text2 As String, _
        ByRef Text3 As String, ByRef Text4 As String, ByRef Text5 As String, _
        ByRef Text6 As String)
    AddOne(Text1) : AddOne(Text2) : AddOne(Text3) : AddOne(Text4)
    AddOne(Text5) : AddOne(Text6)
End Sub

Sub QSTRINGLIST.AddList(ByRef Source As QSTRINGLIST)
    ' Источник может быть этим же списком - число строк берётся заранее
    Dim SourceTotal As Long = Source.ItemTotal
    For ItemIdx As Long = 0 To SourceTotal - 1
        AddOne(Source.ItemList(ItemIdx))
    Next
End Sub

' Строки StartIdx..EndIdx через Delim
Function QSTRINGLIST.Build(ByVal StartIdx As Long, ByVal EndIdx As Long, _
        ByRef Delim As String) As String
    Dim Joined As String = ""
    If StartIdx < 0 Then StartIdx = 0
    If EndIdx > ItemTotal - 1 Then EndIdx = ItemTotal - 1
    For ItemIdx As Long = StartIdx To EndIdx
        If ItemIdx > StartIdx Then Joined &= Delim
        Joined &= ItemList(ItemIdx)
    Next
    Return Joined
End Function

Sub QSTRINGLIST.Clear()
    Erase ItemList
    ItemTotal = 0
End Sub

' Удаление по номерам - по очереди, как при нескольких вызовах
Sub QSTRINGLIST.DelItems(ByVal Index1 As Long, ByVal Index2 As Long = -1, _
        ByVal Index3 As Long = -1, ByVal Index4 As Long = -1, _
        ByVal Index5 As Long = -1, ByVal Index6 As Long = -1)
    Dim IndexList(1 To 6) As Long = {Index1, Index2, Index3, Index4, Index5, Index6}
    For ArgIdx As Long = 1 To 6
        If (ArgIdx > 1) AndAlso (IndexList(ArgIdx) = -1) Then Exit For
        If CheckIndex(IndexList(ArgIdx), "DelItems") Then DeleteAt(IndexList(ArgIdx))
    Next
End Sub

Sub QSTRINGLIST.Exchange(ByVal Index1 As Long, ByVal Index2 As Long)
    If CheckIndex(Index1, "Exchange") = 0 Then Exit Sub
    If CheckIndex(Index2, "Exchange") = 0 Then Exit Sub
    Swap ItemList(Index1), ItemList(Index2)
End Sub

Function QSTRINGLIST.Find(ByRef Value As String) As Long
    Return IndexOf(Value)
End Function

' Номер строки (без учёта регистра); нет - -1
Function QSTRINGLIST.IndexOf(ByRef Value As String) As Long
    Dim FoundIdx As Long
    If SortedFlag Then
        If FindSorted(Value, FoundIdx) Then Return FoundIdx
        Return -1
    End If
    For ItemIdx As Long = 0 To ItemTotal - 1
        If RqRtCompareText(ItemList(ItemIdx), Value) = 0 Then Return ItemIdx
    Next
    Return -1
End Function

Sub QSTRINGLIST.InsertItem(ByVal ItemIndex As Long, ByRef Value As String)
    If SortedFlag Then
#ifdef RQ_COMPAT
        RqRtClassError("QSTRINGLIST.InsertItem: Operation not allowed on sorted list")
#else
        RqRtWarn("QSTRINGLIST.InsertItem: список Sorted, строка добавлена по порядку", "", 0)
        AddOne(Value)
#endif
        Exit Sub
    End If
    ' Вставка в конец (номер = ItemCount) допустима
    If (ItemIndex < 0) OrElse (ItemIndex > ItemTotal) Then
        RqRtClassError("QSTRINGLIST.InsertItem: List index out of bounds (" & _
            ItemIndex & "), ItemCount = " & ItemTotal)
        Exit Sub
    End If
    InsertAt(ItemIndex, Value)
End Sub

Sub QSTRINGLIST.LoadFromFile(ByRef FileName As String)
    Dim FileData As String
    If RqRtReadFile(FileName, FileData) = 0 Then
        RqRtClassError("QSTRINGLIST.LoadFromFile: Cannot open file """ & FileName & """")
        Clear()
        Exit Sub
    End If
    Text = FileData
End Sub

' С текущей позиции потока до конца
Sub QSTRINGLIST.LoadFromStream(ByRef Stream As RqStream)
    Dim DataLen As Long = Stream.Size - Stream.Position
    Dim StreamText As String
    If DataLen > 0 Then
        StreamText = Space(DataLen)
        DataLen = Stream.ReadBuf(StrPtr(StreamText), DataLen)
        StreamText = Mid(StreamText, 1, DataLen)
    End If
    Text = StreamText
End Sub

' Список очищается, Source делится по Delim; результат - число строк
Function QSTRINGLIST.Parse(ByRef Source As String, ByRef Delim As String) As Long
    Clear()
    If Len(Delim) = 0 Then
        AddOne(Source)
        Return ItemTotal
    End If
    Dim StartPos As Long = 1
    Do
        Dim DelimPos As Long = InStr(StartPos, Source, Delim)
        If DelimPos = 0 Then
            AddOne(Mid(Source, StartPos))
            Exit Do
        End If
        AddOne(Mid(Source, StartPos, DelimPos - StartPos))
        StartPos = DelimPos + Len(Delim)
    Loop
    Return ItemTotal
End Function

Sub QSTRINGLIST.SaveToFile(ByRef FileName As String)
    If RqRtWriteFile(FileName, Text) = 0 Then
        RqRtClassError("QSTRINGLIST.SaveToFile: Cannot create file """ & FileName & """")
    End If
End Sub

Sub QSTRINGLIST.SaveToStream(ByRef Stream As RqStream)
    Dim StreamText As String = Text
    If Len(StreamText) > 0 Then Stream.WriteBuf(StrPtr(StreamText), Len(StreamText))
End Sub

Sub QSTRINGLIST.QuickSort(ByVal LowIdx As Long, ByVal HighIdx As Long)
    Do While LowIdx < HighIdx
        Dim LeftIdx As Long = LowIdx
        Dim RightIdx As Long = HighIdx
        Dim Pivot As String = ItemList((LowIdx + HighIdx) \ 2)
        Do
            While RqRtCompareText(ItemList(LeftIdx), Pivot) < 0
                LeftIdx += 1
            Wend
            While RqRtCompareText(ItemList(RightIdx), Pivot) > 0
                RightIdx -= 1
            Wend
            If LeftIdx <= RightIdx Then
                If LeftIdx <> RightIdx Then Swap ItemList(LeftIdx), ItemList(RightIdx)
                LeftIdx += 1
                RightIdx -= 1
            End If
        Loop While LeftIdx <= RightIdx
        ' меньшую часть - рекурсией, большую - циклом
        If RightIdx - LowIdx < HighIdx - LeftIdx Then
            If LowIdx < RightIdx Then QuickSort(LowIdx, RightIdx)
            LowIdx = LeftIdx
        Else
            If LeftIdx < HighIdx Then QuickSort(LeftIdx, HighIdx)
            HighIdx = RightIdx
        End If
    Loop
End Sub

Sub QSTRINGLIST.Sort()
    If ItemTotal > 1 Then QuickSort(0, ItemTotal - 1)
End Sub
