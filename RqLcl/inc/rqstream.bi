' ---------------------------------------------------------------------------
'  rqstream.bi - QMEMORYSTREAM и QFILESTREAM RapidQ на FreeBASIC
'  (rapidq_ref/html_doc/qmemorystream.html, qfilestream.html).
'
'  Общее - в RqStream: Write/Read (размер по типу переменной), ReadNum,
'  WriteNum, ReadStr/WriteStr, ReadBinStr/WriteBinStr, ReadLine/WriteLine,
'  Seek, CopyFrom, Position, Size, LineCount, EOF. Хранилище - у потомка:
'  ReadBuf/WriteBuf/StreamSize/SetSize.
'  Типы RapidQ: BYTE - UByte, SHORT - Short, WORD - UShort, INTEGER/LONG -
'  Long, DWORD - ULong, SINGLE, DOUBLE, STRING. Целое FreeBASIC (Integer,
'  у литералов) пишется как LONG (4 байта, как INTEGER RapidQ).
'  Не сделано: ReadUDT/WriteUDT, LoadArray/SaveArray, ExtractRes.
' ---------------------------------------------------------------------------

#pragma once

#include once "rqrt.bi"   ' RqRtWarn

' Открытие и закрытие файла - вне типа: внутри методов QFILESTREAM слова
' Open и Close означали бы его же методы
Function RqRtFileOpen(ByRef FileName As String, ByVal Method As Long) As Long
    Dim FileNum As Long = FreeFile
    Dim Failed As Long
    If Method = 65535 Then
        ' fmCreate: создать заново (Output обнуляет файл)
        Failed = Open(FileName For Output As #FileNum)
        If Failed = 0 Then
            Close #FileNum
            Failed = Open(FileName For Binary Access Read Write As #FileNum)
        End If
    ElseIf (Method And 3) = 0 Then
        Failed = Open(FileName For Binary Access Read As #FileNum)
    ElseIf (Method And 3) = 1 Then
        Failed = Open(FileName For Binary Access Write As #FileNum)
    Else
        Failed = Open(FileName For Binary Access Read Write As #FileNum)
    End If
    If Failed <> 0 Then Return 0
    Return FileNum
End Function

Sub RqRtFileClose(ByVal FileNum As Long)
    If FileNum <> 0 Then Close #FileNum
End Sub

Type RqStream Extends Object
    Declare Virtual Function ReadBuf(ByVal Dest As Any Ptr, ByVal Count As Long) As Long
    Declare Virtual Sub WriteBuf(ByVal Source As Any Ptr, ByVal Count As Long)
    Declare Virtual Function StreamSize() As Long
    Declare Virtual Sub SetSize(ByVal NewSize As Long)
    Declare Virtual Sub Close()
    StreamPos As Long          ' текущая позиция, с 0

    Declare Property Position() As Long
    Declare Property Position(ByVal Value As Long)
    Declare Property Size() As Long
    Declare Property Size(ByVal Value As Long)
    Declare Property EOF() As Long
    Declare Property LineCount() As Long

    Declare Sub Seek(ByVal Offset As Long, ByVal Origin As Long)

    Declare Sub Write Overload (ByRef Value As UByte)
    Declare Sub Write Overload (ByRef Value As Short)
    Declare Sub Write Overload (ByRef Value As UShort)
    Declare Sub Write Overload (ByRef Value As Long)
    Declare Sub Write Overload (ByRef Value As ULong)
    Declare Sub Write Overload (ByRef Value As Integer)
    Declare Sub Write Overload (ByRef Value As Single)
    Declare Sub Write Overload (ByRef Value As Double)
    Declare Sub Write Overload (ByRef Value As String)

    Declare Sub Read Overload (ByRef Value As UByte)
    Declare Sub Read Overload (ByRef Value As Short)
    Declare Sub Read Overload (ByRef Value As UShort)
    Declare Sub Read Overload (ByRef Value As Long)
    Declare Sub Read Overload (ByRef Value As ULong)
    Declare Sub Read Overload (ByRef Value As Single)
    Declare Sub Read Overload (ByRef Value As Double)
    Declare Sub Read Overload (ByRef Value As String)

    Declare Function ReadNum(ByVal NumType As Long) As Double
    Declare Sub WriteNum(ByVal Value As Double, ByVal ByteCount As Long)
    Declare Function ReadStr(ByVal Count As Long) As String
    Declare Function ReadBinStr(ByVal Count As Long) As String
    Declare Sub WriteStr(ByRef Text As String, ByVal Count As Long)
    Declare Sub WriteBinStr(ByRef Text As String, ByVal Count As Long)
    Declare Function ReadLine() As String
    Declare Sub WriteLine(ByRef Text As String)
    Declare Sub CopyFrom(ByRef Source As RqStream, ByVal Count As Long)
End Type

Function RqStream.ReadBuf(ByVal Dest As Any Ptr, ByVal Count As Long) As Long
    Return 0
End Function
Sub RqStream.WriteBuf(ByVal Source As Any Ptr, ByVal Count As Long)
End Sub
Function RqStream.StreamSize() As Long
    Return 0
End Function
Sub RqStream.SetSize(ByVal NewSize As Long)
End Sub
Sub RqStream.Close()
End Sub

Property RqStream.Position() As Long
    Return StreamPos
End Property
Property RqStream.Position(ByVal Value As Long)
    If Value < 0 Then Value = 0
    StreamPos = Value
End Property
Property RqStream.Size() As Long
    Return StreamSize()
End Property
Property RqStream.Size(ByVal Value As Long)
    SetSize(Value)
End Property
Property RqStream.EOF() As Long
    If StreamPos >= StreamSize() Then Return -1
    Return 0
End Property

' Число строк: переводы LF (CRLF - одна строка) и последняя строка без LF
Property RqStream.LineCount() As Long
    Dim SavedPos As Long = StreamPos
    Dim Total As Long = StreamSize()
    Dim Count As Long = 0
    Dim ByteValue As UByte
    Dim LastByte As UByte = 10
    StreamPos = 0
    While StreamPos < Total
        ReadBuf(@ByteValue, 1)
        If ByteValue = 10 Then Count += 1
        LastByte = ByteValue
    Wend
    If (Total > 0) AndAlso (LastByte <> 10) Then Count += 1
    StreamPos = SavedPos
    Return Count
End Property

' Origin: 0 - от начала, 1 - от текущей, 2 - от конца (soFrom... RAPIDQ.INC)
Sub RqStream.Seek(ByVal Offset As Long, ByVal Origin As Long)
    Select Case Origin
        Case 1: Position = StreamPos + Offset
        Case 2: Position = StreamSize() + Offset
        Case Else: Position = Offset
    End Select
End Sub

Sub RqStream.Write(ByRef Value As UByte)
    WriteBuf(@Value, 1)
End Sub
Sub RqStream.Write(ByRef Value As Short)
    WriteBuf(@Value, 2)
End Sub
Sub RqStream.Write(ByRef Value As UShort)
    WriteBuf(@Value, 2)
End Sub
Sub RqStream.Write(ByRef Value As Long)
    WriteBuf(@Value, 4)
End Sub
Sub RqStream.Write(ByRef Value As ULong)
    WriteBuf(@Value, 4)
End Sub
Sub RqStream.Write(ByRef Value As Integer)
    Dim AsLong As Long = CLng(Value)
    WriteBuf(@AsLong, 4)
End Sub
Sub RqStream.Write(ByRef Value As Single)
    WriteBuf(@Value, 4)
End Sub
Sub RqStream.Write(ByRef Value As Double)
    WriteBuf(@Value, 8)
End Sub
Sub RqStream.Write(ByRef Value As String)
    If Len(Value) > 0 Then WriteBuf(StrPtr(Value), Len(Value))
End Sub

Sub RqStream.Read(ByRef Value As UByte)
    ReadBuf(@Value, 1)
End Sub
Sub RqStream.Read(ByRef Value As Short)
    ReadBuf(@Value, 2)
End Sub
Sub RqStream.Read(ByRef Value As UShort)
    ReadBuf(@Value, 2)
End Sub
Sub RqStream.Read(ByRef Value As Long)
    ReadBuf(@Value, 4)
End Sub
Sub RqStream.Read(ByRef Value As ULong)
    ReadBuf(@Value, 4)
End Sub
Sub RqStream.Read(ByRef Value As Single)
    ReadBuf(@Value, 4)
End Sub
Sub RqStream.Read(ByRef Value As Double)
    ReadBuf(@Value, 8)
End Sub
' Строка: столько байт, какова её длина (S$ = SPACE$(n) : Read(S$))
Sub RqStream.Read(ByRef Value As String)
    If Len(Value) > 0 Then ReadBuf(StrPtr(Value), Len(Value))
End Sub

' NumType - Num_BYTE 1, Num_SHORT 2, Num_WORD 3, Num_LONG 4, Num_DWORD 5,
' Num_SINGLE 6, Num_DOUBLE 8 (RAPIDQ.INC)
Function RqStream.ReadNum(ByVal NumType As Long) As Double
    Dim ByteValue As UByte
    Dim ShortValue As Short
    Dim WordValue As UShort
    Dim LongValue As Long
    Dim DwordValue As ULong
    Dim SingleValue As Single
    Dim DoubleValue As Double
    Select Case NumType
        Case 1: ReadBuf(@ByteValue, 1) : Return ByteValue
        Case 2: ReadBuf(@ShortValue, 2) : Return ShortValue
        Case 3: ReadBuf(@WordValue, 2) : Return WordValue
        Case 4: ReadBuf(@LongValue, 4) : Return LongValue
        Case 5: ReadBuf(@DwordValue, 4) : Return DwordValue
        Case 6: ReadBuf(@SingleValue, 4) : Return SingleValue
        Case Else: ReadBuf(@DoubleValue, 8) : Return DoubleValue
    End Select
End Function

' ByteCount: 1 - BYTE, 2 - SHORT, 4 - LONG, 8 - DOUBLE
Sub RqStream.WriteNum(ByVal Value As Double, ByVal ByteCount As Long)
    Dim ByteValue As UByte
    Dim ShortValue As Short
    Dim LongValue As Long
    Select Case ByteCount
        Case 1
            ByteValue = CUByte(CLngInt(Fix(Value)) And &hFF)
            WriteBuf(@ByteValue, 1)
        Case 2
            ShortValue = CShort(CLngInt(Fix(Value)) And &hFFFF)
            WriteBuf(@ShortValue, 2)
        Case 4
            LongValue = CLng(CLngInt(Fix(Value)) And &hFFFFFFFF)
            WriteBuf(@LongValue, 4)
        Case Else
            WriteBuf(@Value, 8)
    End Select
End Sub

Function RqStream.ReadStr(ByVal Count As Long) As String
    Dim Remain As Long = StreamSize() - StreamPos
    If Count > Remain Then Count = Remain
    If Count <= 0 Then Return ""
    Dim Text As String = Space(Count)
    ReadBuf(StrPtr(Text), Count)
    Return Text
End Function

Function RqStream.ReadBinStr(ByVal Count As Long) As String
    Return ReadStr(Count)
End Function

' Count байт строки; короче - дополняется нулями
Sub RqStream.WriteStr(ByRef Text As String, ByVal Count As Long)
    If Count <= 0 Then Exit Sub
    Dim Buffer As String = Left(Text, Count)
    If Len(Buffer) < Count Then Buffer &= String(Count - Len(Buffer), 0)
    WriteBuf(StrPtr(Buffer), Count)
End Sub

Sub RqStream.WriteBinStr(ByRef Text As String, ByVal Count As Long)
    WriteStr(Text, Count)
End Sub

' Строка до LF; CR перед LF отбрасывается (файлы Windows и UNIX)
Function RqStream.ReadLine() As String
    Dim Text As String = ""
    Dim ByteValue As UByte
    Dim Total As Long = StreamSize()
    While StreamPos < Total
        ReadBuf(@ByteValue, 1)
        If ByteValue = 10 Then Exit While
        Text &= Chr(ByteValue)
    Wend
    If Right(Text, 1) = Chr(13) Then Text = Left(Text, Len(Text) - 1)
    Return Text
End Function

Sub RqStream.WriteLine(ByRef Text As String)
    Dim LineText As String = Text & Chr(13, 10)
    WriteBuf(StrPtr(LineText), Len(LineText))
End Sub

' Count = 0 - весь Source с начала
Sub RqStream.CopyFrom(ByRef Source As RqStream, ByVal Count As Long)
    If Count = 0 Then
        Source.Position = 0
        Count = Source.Size
    End If
    If Count <= 0 Then Exit Sub
    Dim Buffer As String = Space(Count)
    Dim GotCount As Long = Source.ReadBuf(StrPtr(Buffer), Count)
    If GotCount > 0 Then WriteBuf(StrPtr(Buffer), GotCount)
End Sub

' ---------------------------------------------------------------------------
'  QMEMORYSTREAM - данные в строке
' ---------------------------------------------------------------------------

Type QMEMORYSTREAM Extends RqStream
    StreamData As String
    Declare Function ReadBuf(ByVal Dest As Any Ptr, ByVal Count As Long) As Long Override
    Declare Sub WriteBuf(ByVal Source As Any Ptr, ByVal Count As Long) Override
    Declare Function StreamSize() As Long Override
    Declare Sub SetSize(ByVal NewSize As Long) Override
    Declare Sub Close() Override
    ' Pointer RapidQ (слово Pointer у FreeBASIC занято; препроцессор
    ' переводит .Pointer в .PointerAddr)
    Declare Property PointerAddr() As Any Ptr
    Declare Sub MemCopyFrom(ByVal Address As Any Ptr, ByVal Count As Long)
    Declare Sub MemCopyTo(ByVal Address As Any Ptr, ByVal Count As Long)
End Type

Function QMEMORYSTREAM.ReadBuf(ByVal Dest As Any Ptr, ByVal Count As Long) As Long
    Dim Remain As Long = Len(StreamData) - StreamPos
    If Count > Remain Then Count = Remain
    If Count <= 0 Then Return 0
    Dim DestBytes As UByte Ptr = Dest
    Dim ByteIdx As Long
    For ByteIdx = 0 To Count - 1
        DestBytes[ByteIdx] = StreamData[StreamPos + ByteIdx]
    Next
    StreamPos += Count
    Return Count
End Function

Sub QMEMORYSTREAM.WriteBuf(ByVal Source As Any Ptr, ByVal Count As Long)
    If Count <= 0 Then Exit Sub
    If StreamPos + Count > Len(StreamData) Then
        StreamData &= String(StreamPos + Count - Len(StreamData), 0)
    End If
    Dim SourceBytes As UByte Ptr = Source
    Dim ByteIdx As Long
    For ByteIdx = 0 To Count - 1
        StreamData[StreamPos + ByteIdx] = SourceBytes[ByteIdx]
    Next
    StreamPos += Count
End Sub

Function QMEMORYSTREAM.StreamSize() As Long
    Return Len(StreamData)
End Function

Sub QMEMORYSTREAM.SetSize(ByVal NewSize As Long)
    If NewSize < 0 Then NewSize = 0
    If NewSize < Len(StreamData) Then
        StreamData = Left(StreamData, NewSize)
    Else
        StreamData &= String(NewSize - Len(StreamData), 0)
    End If
    If StreamPos > NewSize Then StreamPos = NewSize
End Sub

Sub QMEMORYSTREAM.Close()
    StreamData = ""
    StreamPos = 0
End Sub

Property QMEMORYSTREAM.PointerAddr() As Any Ptr
    Return StrPtr(StreamData)
End Property

Sub QMEMORYSTREAM.MemCopyFrom(ByVal Address As Any Ptr, ByVal Count As Long)
    WriteBuf(Address, Count)
End Sub

Sub QMEMORYSTREAM.MemCopyTo(ByVal Address As Any Ptr, ByVal Count As Long)
    ReadBuf(Address, Count)
End Sub

' ---------------------------------------------------------------------------
'  QFILESTREAM - файл, открытый Binary
' ---------------------------------------------------------------------------

Type QFILESTREAM Extends RqStream
    FileNum As Long
    Declare Function ReadBuf(ByVal Dest As Any Ptr, ByVal Count As Long) As Long Override
    Declare Sub WriteBuf(ByVal Source As Any Ptr, ByVal Count As Long) Override
    Declare Function StreamSize() As Long Override
    Declare Sub SetSize(ByVal NewSize As Long) Override
    Declare Sub Close() Override
    Declare Sub Open(ByRef FileName As String, ByVal Method As Long)
    Declare Property Handle() As Long
    Declare Destructor()
End Type

' Method: fmCreate 65535 - создать (стереть прежний), fmOpenRead 0,
' fmOpenWrite 1, fmOpenReadWrite 2 (младшие биты; флаги доступа fmShare...
' не учитываются)
Sub QFILESTREAM.Open(ByRef FileName As String, ByVal Method As Long)
    Close()
    FileNum = RqRtFileOpen(FileName, Method)
    If FileNum = 0 Then
        RqRtWarn("QFILESTREAM.Open: не удалось открыть " & FileName, __FILE__, __LINE__)
    End If
    StreamPos = 0
End Sub

Function QFILESTREAM.ReadBuf(ByVal Dest As Any Ptr, ByVal Count As Long) As Long
    If (FileNum = 0) Or (Count <= 0) Then Return 0
    Dim Remain As Long = LOF(FileNum) - StreamPos
    If Count > Remain Then Count = Remain
    If Count <= 0 Then Return 0
    Get #FileNum, StreamPos + 1, *CPtr(UByte Ptr, Dest), Count
    StreamPos += Count
    Return Count
End Function

Sub QFILESTREAM.WriteBuf(ByVal Source As Any Ptr, ByVal Count As Long)
    If (FileNum = 0) Or (Count <= 0) Then Exit Sub
    Put #FileNum, StreamPos + 1, *CPtr(UByte Ptr, Source), Count
    StreamPos += Count
End Sub

Function QFILESTREAM.StreamSize() As Long
    If FileNum = 0 Then Return 0
    Return LOF(FileNum)
End Function

Sub QFILESTREAM.SetSize(ByVal NewSize As Long)
    ' Размер у QFILESTREAM RapidQ только читается
End Sub

Sub QFILESTREAM.Close()
    RqRtFileClose(FileNum)
    FileNum = 0
    StreamPos = 0
End Sub

Property QFILESTREAM.Handle() As Long
    Return FileNum
End Property

Destructor QFILESTREAM()
    Close()
End Destructor
