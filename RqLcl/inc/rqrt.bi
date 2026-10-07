' ---------------------------------------------------------------------------
'  rqrt.bi - поддержка программ RapidQ, переведённых в FreeBASIC
'  препроцессором RqToFb (unIDE). Подключается им в начало главного файла.
'
'  Режим: RQ_SMART (по умолчанию) или RQ_COMPAT - #define перед этим файлом.
'    Compat - как RapidQ: дробное вне диапазона LONG в целую переменную
'             останавливает программу ошибкой, как EInvalidOp у RapidQ.
'    Smart  - перенос по разрядности и запись предупреждения; ошибки - с
'             файлом и строкой исходника RapidQ, именем переменной и
'             значением: окно, консоль (stderr) и <программа>_error.log
'             рядом с exe.
'
'  Присваивание: препроцессор оборачивает правую часть в функцию по типу
'  переменной слева (RqNum, RqLong, RqStr...), а перегрузку по типу правой
'  части выбирает fbc. Строка в число - 0, число в строку - "" (как RapidQ).
'  PRINT: каждый элемент - RqFmt (числа - как печатает RapidQ).
' ---------------------------------------------------------------------------

#pragma once

#ifndef RQ_COMPAT
    #ifndef RQ_SMART
        #define RQ_SMART
    #endif
#endif

Declare Function RqRtMessageBox Lib "user32" Alias "MessageBoxA" ( _
    ByVal WindowHandle As Any Ptr, ByVal Text As ZString Ptr, _
    ByVal Caption As ZString Ptr, ByVal Flags As ULong) As Long

Const RqRtMaxWarnings = 50      ' предупреждений в лог за один запуск

Dim Shared RqRtWarnCount As Long

' Лог-файл: <папка exe>\<имя exe>_error.log
Function RqRtLogName() As String
    Dim ExeName As String = Command(0)
    Dim SlashPos As Long = InStrRev(ExeName, Any "\/")
    If SlashPos > 0 Then ExeName = Mid(ExeName, SlashPos + 1)
    Dim DotPos As Long = InStrRev(ExeName, ".")
    If DotPos > 0 Then ExeName = Left(ExeName, DotPos - 1)
    If ExeName = "" Then ExeName = "program"
    Return ExePath() & "\" & ExeName & "_error.log"
End Function

' Сообщение: лог, stderr и (AShowWindow <> 0) окно
Sub RqRtReport(ByRef Level As String, ByRef Msg As String, _
               ByRef FileName As String, ByVal LineNum As Long, _
               ByVal ShowWindow As Long)
    Dim Text As String = FileName & "(" & LineNum & ") " & Level & ": " & Msg
    Dim FileNum As Long = FreeFile
    If Open(RqRtLogName() For Append As #FileNum) = 0 Then
        Print #FileNum, Date & " " & Time & "  " & Text
        Close #FileNum
    End If
    FileNum = FreeFile
    Open Err For Output As #FileNum
    If Err = 0 Then
        Print #FileNum, Text
        Close #FileNum
    End If
    If ShowWindow Then RqRtMessageBox(0, Text, "RapidQ - FreeBASIC", &h10)
End Sub

' Предупреждение (программа продолжает работу), не больше RqRtMaxWarnings
Sub RqRtWarn(ByRef Msg As String, ByRef FileName As String, ByVal LineNum As Long)
    RqRtWarnCount += 1
    If RqRtWarnCount > RqRtMaxWarnings Then Exit Sub
    If RqRtWarnCount = RqRtMaxWarnings Then
        RqRtReport("Warning", Msg & " (дальше предупреждения не пишутся)", _
                   FileName, LineNum, 0)
    Else
        RqRtReport("Warning", Msg, FileName, LineNum, 0)
    End If
End Sub

' Ошибка, после которой программа не продолжает работу
Sub RqRtFatal(ByRef Msg As String, ByRef FileName As String, ByVal LineNum As Long)
    RqRtReport("Error", Msg, FileName, LineNum, 1)
    End 1
End Sub

' Int и Fix без перевода в целое: у FreeBASIC они для чисел больше 2^63
' переполняются; от 2^52 Double и так целое
Function RqRtFloor(ByVal Value As Double) As Double
    If Abs(Value) >= 4503599627370496.0 Then Return Value
    Return Int(Value)
End Function

Function RqRtTrunc(ByVal Value As Double) As Double
    If Abs(Value) >= 4503599627370496.0 Then Return Value
    Return Fix(Value)
End Function

' Целая часть Value, перенесённая по разрядности Bits (как переполнение у
' RapidQ для SHORT: 70000 -> 4464)
Function RqRtWrap(ByVal Value As Double, ByVal Bits As Long, _
                  ByVal IsSigned As Long) As LongInt
    If Value <> Value Then Return 0                ' NaN
    Dim Modulus As Double = 2.0 ^ Bits
    Dim Whole As Double = RqRtTrunc(Value)
    Dim Remainder As Double = Whole - RqRtFloor(Whole / Modulus) * Modulus
    If Remainder < 0 Then Remainder += Modulus
    If Remainder >= Modulus Then Remainder -= Modulus
    If IsSigned AndAlso (Remainder >= Modulus / 2) Then Remainder -= Modulus
    Return CLngInt(Remainder)
End Function

' Целое значение для переменной разрядности Bits. В диапазоне - отбрасывание
' дробной части (5.7 -> 5, -5.7 -> -5). Вне диапазона: Smart - перенос и
' предупреждение; Compat - LONG и DWORD останавливают программу (как RapidQ),
' остальные переносятся молча.
Function RqRtToInt(ByVal Value As Double, ByVal Bits As Long, _
                   ByVal IsSigned As Long, ByRef TypeName As String, _
                   ByRef VarName As String, ByRef FileName As String, _
                   ByVal LineNum As Long) As LongInt
    Dim Whole As Double = RqRtTrunc(Value)
    Dim MinValue As Double
    Dim MaxValue As Double
    If IsSigned Then
        MinValue = -(2.0 ^ (Bits - 1))
        MaxValue = 2.0 ^ (Bits - 1) - 1
    Else
        MinValue = 0
        MaxValue = 2.0 ^ Bits - 1
    End If
    If (Whole >= MinValue) AndAlso (Whole <= MaxValue) Then Return CLngInt(Whole)
    #ifdef RQ_COMPAT
        If Bits >= 32 Then
            RqRtReport("Error", "Exception EInvalidOp: Invalid floating point " & _
                       "operation (" & VarName & " = " & Value & ")", _
                       FileName, LineNum, 1)
            End 1
        End If
    #else
        RqRtWarn(VarName & " = " & Value & ": вне диапазона " & TypeName & _
                 ", перенос по разрядности -> " & RqRtWrap(Value, Bits, IsSigned), _
                 FileName, LineNum)
    #endif
    Return RqRtWrap(Value, Bits, IsSigned)
End Function

' --- Присваивание с преобразованием (препроцессор: Var = RqXxx(выражение,
'     "имя", __FILE__, __LINE__)) ---

Function RqNum Overload (ByVal Value As Double, ByRef VarName As String, _
                         ByRef FileName As String, ByVal LineNum As Long) As Double
    Return Value
End Function
Function RqNum Overload (ByRef Value As String, ByRef VarName As String, _
                         ByRef FileName As String, ByVal LineNum As Long) As Double
    Return 0
End Function

Function RqSng Overload (ByVal Value As Double, ByRef VarName As String, _
                         ByRef FileName As String, ByVal LineNum As Long) As Single
    Return CSng(Value)
End Function
Function RqSng Overload (ByRef Value As String, ByRef VarName As String, _
                         ByRef FileName As String, ByVal LineNum As Long) As Single
    Return 0
End Function

Function RqLong Overload (ByVal Value As Double, ByRef VarName As String, _
                          ByRef FileName As String, ByVal LineNum As Long) As Long
    Return CLng(RqRtToInt(Value, 32, 1, "LONG", VarName, FileName, LineNum))
End Function
Function RqLong Overload (ByRef Value As String, ByRef VarName As String, _
                          ByRef FileName As String, ByVal LineNum As Long) As Long
    Return 0
End Function

Function RqShort Overload (ByVal Value As Double, ByRef VarName As String, _
                           ByRef FileName As String, ByVal LineNum As Long) As Short
    Return CShort(RqRtToInt(Value, 16, 1, "SHORT", VarName, FileName, LineNum))
End Function
Function RqShort Overload (ByRef Value As String, ByRef VarName As String, _
                           ByRef FileName As String, ByVal LineNum As Long) As Short
    Return 0
End Function

Function RqByte Overload (ByVal Value As Double, ByRef VarName As String, _
                          ByRef FileName As String, ByVal LineNum As Long) As UByte
    Return CUByte(RqRtToInt(Value, 8, 0, "BYTE", VarName, FileName, LineNum))
End Function
Function RqByte Overload (ByRef Value As String, ByRef VarName As String, _
                          ByRef FileName As String, ByVal LineNum As Long) As UByte
    Return 0
End Function

Function RqWord Overload (ByVal Value As Double, ByRef VarName As String, _
                          ByRef FileName As String, ByVal LineNum As Long) As UShort
    Return CUShort(RqRtToInt(Value, 16, 0, "WORD", VarName, FileName, LineNum))
End Function
Function RqWord Overload (ByRef Value As String, ByRef VarName As String, _
                          ByRef FileName As String, ByVal LineNum As Long) As UShort
    Return 0
End Function

Function RqDword Overload (ByVal Value As Double, ByRef VarName As String, _
                           ByRef FileName As String, ByVal LineNum As Long) As ULong
    Return CULng(RqRtToInt(Value, 32, 0, "DWORD", VarName, FileName, LineNum))
End Function
Function RqDword Overload (ByRef Value As String, ByRef VarName As String, _
                           ByRef FileName As String, ByVal LineNum As Long) As ULong
    Return 0
End Function

Function RqStr Overload (ByRef Value As String, ByRef VarName As String, _
                         ByRef FileName As String, ByVal LineNum As Long) As String
    Return Value
End Function
Function RqStr Overload (ByVal Value As Double, ByRef VarName As String, _
                         ByRef FileName As String, ByVal LineNum As Long) As String
    Return ""
End Function

' --- PRINT ---

' Десятичная запись целого Double любого размера (1e20 -> 100000000000000000000)
Function RqRtWholeDigits(ByVal Value As Double) As String
    If Value < 9.0e18 Then Return Str(CLngInt(Value))
    ' Value = Mantissa * 2^Power, Mantissa < 2^53 - точное целое
    Dim Power As Long = 0
    Dim Mantissa As Double = Value
    While Mantissa >= 9007199254740992.0
        Mantissa /= 2
        Power += 1
    Wend
    Dim Digits As String = Str(CLngInt(Mantissa))
    Dim StepIdx As Long
    Dim DigitIdx As Long
    Dim Carry As Long
    Dim DigitValue As Long
    For StepIdx = 1 To Power
        ' Digits = Digits * 2
        Carry = 0
        For DigitIdx = Len(Digits) To 1 Step -1
            DigitValue = (Digits[DigitIdx - 1] - 48) * 2 + Carry
            Digits[DigitIdx - 1] = 48 + (DigitValue Mod 10)
            Carry = DigitValue \ 10
        Next
        If Carry > 0 Then Digits = Chr(48 + Carry) & Digits
    Next
    Return Digits
End Function

Function RqFmt Overload (ByRef Value As String) As String
    Return Value
End Function

Function RqFmt Overload (ByVal Value As LongInt) As String
    Return Str(Value)
End Function

' Число с плавающей точкой - как RapidQ: целое в пределах LONG без дробной
' части (5, 3), целое больше - с ".0" (100000000000000000000.0), дробное -
' 9 знаков после точки (5.500000000, 0.000010000)
Function RqFmt Overload (ByVal Value As Double) As String
    If Value <> Value Then Return "NAN"
    Dim Sign As String = ""
    Dim AbsValue As Double = Value
    If Value < 0 Then
        Sign = "-"
        AbsValue = -Value
    End If
    If AbsValue > 1.7e308 Then Return Sign & "INF"
    If AbsValue = RqRtFloor(AbsValue) Then
        If AbsValue <= 2147483647 Then Return Sign & Str(CLngInt(AbsValue))
        Return Sign & RqRtWholeDigits(AbsValue) & ".0"
    End If
    Dim WholePart As Double = RqRtFloor(AbsValue)
    Dim Fraction As LongInt = CLngInt(Int((AbsValue - WholePart) * 1000000000.0 + 0.5))
    If Fraction >= 1000000000 Then
        WholePart += 1
        Fraction -= 1000000000
    End If
    Return Sign & RqRtWholeDigits(WholePart) & "." & Right("000000000" & Str(Fraction), 9)
End Function

' ---------------------------------------------------------------------------
'  Функции RapidQ, которых нет в FreeBASIC (rapidq_ref/html_doc/
'  otherdetail.html). Функции со знаком $ препроцессор переименовывает:
'  INSERT$ -> RqInsert и т.д.; остальные называются как в RapidQ.
' ---------------------------------------------------------------------------

' FIELD$("John&Doe&555-1234", "&", 2) -> "Doe"; номер с 1, нет - ""
Function RqField(ByRef Source As String, ByRef Delim As String, _
                 ByVal FieldNum As Long) As String
    If (FieldNum < 1) Or (Len(Delim) = 0) Then Return ""
    Dim StartPos As Long = 1
    Dim FoundPos As Long
    Dim FieldIdx As Long = 1
    Do
        FoundPos = InStr(StartPos, Source, Delim)
        If FieldIdx = FieldNum Then
            If FoundPos = 0 Then Return Mid(Source, StartPos)
            Return Mid(Source, StartPos, FoundPos - StartPos)
        End If
        If FoundPos = 0 Then Return ""
        StartPos = FoundPos + Len(Delim)
        FieldIdx += 1
    Loop
End Function

' REPLACESUBSTR$("abcdefgabcdefg", "abc", "99") -> "99defg99defg" (все)
Function RqReplaceSubStr(ByRef Source As String, ByRef Find As String, _
                         ByRef Replacement As String) As String
    If Len(Find) = 0 Then Return Source
    Dim Result As String = ""
    Dim StartPos As Long = 1
    Dim FoundPos As Long = InStr(StartPos, Source, Find)
    While FoundPos > 0
        Result &= Mid(Source, StartPos, FoundPos - StartPos) & Replacement
        StartPos = FoundPos + Len(Find)
        FoundPos = InStr(StartPos, Source, Find)
    Wend
    Return Result & Mid(Source, StartPos)
End Function

' INSERT$("hi", "Hello", 3) -> "Hehillo"
Function RqInsert(ByRef InsertText As String, ByRef Source As String, _
                  ByVal Index As Long) As String
    If Index < 1 Then Index = 1
    Return Left(Source, Index - 1) & InsertText & Mid(Source, Index)
End Function

' DELETE$("Hello world", 2, 3) -> "Ho world"
Function RqDelete(ByRef Source As String, ByVal StartPos As Long, _
                  ByVal Count As Long) As String
    If (StartPos < 1) Or (Count <= 0) Then Return Source
    Return Left(Source, StartPos - 1) & Mid(Source, StartPos + Count)
End Function

' REPLACE$("Hello", "Jwer", 1) -> "Jwero" (поверх, с удлинением)
Function RqReplace(ByRef Source As String, ByRef Replacement As String, _
                   ByVal Index As Long) As String
    If Index < 1 Then Index = 1
    Return Left(Source, Index - 1) & Replacement & _
           Mid(Source, Index + Len(Replacement))
End Function

' REVERSE$("Hello") -> "olleH"
Function RqReverse(ByRef Source As String) As String
    Dim Result As String = Source
    Dim CharIdx As Long
    Dim TextLen As Long = Len(Source)
    For CharIdx = 0 To TextLen - 1
        Result[CharIdx] = Source[TextLen - 1 - CharIdx]
    Next
    Return Result
End Function

' CONVBASE$("FFD", 16, 2); отрицательные не поддержаны (как в RapidQ)
Function RqConvBase(ByRef Source As String, ByVal FromBase As Long, _
                    ByVal ToBase As Long) As String
    Const DigitChars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    If (FromBase < 2) Or (FromBase > 36) Or (ToBase < 2) Or (ToBase > 36) Then Return ""
    Dim Value As ULongInt = 0
    Dim CharIdx As Long
    Dim DigitValue As Long
    Dim Upper As String = UCase(Trim(Source))
    For CharIdx = 1 To Len(Upper)
        DigitValue = InStr(DigitChars, Mid(Upper, CharIdx, 1)) - 1
        If (DigitValue < 0) Or (DigitValue >= FromBase) Then Exit For
        Value = Value * FromBase + DigitValue
    Next
    If Value = 0 Then Return "0"
    Dim Result As String = ""
    While Value > 0
        Result = Mid(DigitChars, (Value Mod ToBase) + 1, 1) & Result
        Value \= ToBase
    Wend
    Return Result
End Function

' HEX$ в Windows-версии RapidQ дополняется нулями до 8 знаков;
' отрицательные - в дополнительном коде (32 бита)
Function RqHex(ByVal Value As Double) As String
    Return Hex(CLng(RqRtWrap(Value, 32, 1)), 8)
End Function

' RINSTR([start,] строка, искомое) - поиск справа налево; 0 - нет
Function Rinstr Overload (ByRef Source As String, ByRef Find As String) As Long
    Return InStrRev(Source, Find)
End Function
Function Rinstr Overload (ByVal StartPos As Long, ByRef Source As String, _
                          ByRef Find As String) As Long
    Return InStrRev(Source, Find, StartPos)
End Function

' TALLY("abcdefghijklmnabc", "abc") -> 2 (без перекрытий)
Function Tally(ByRef Source As String, ByRef Find As String) As Long
    If Len(Find) = 0 Then Return 0
    Dim Count As Long = 0
    Dim FoundPos As Long = InStr(Source, Find)
    While FoundPos > 0
        Count += 1
        FoundPos = InStr(FoundPos + Len(Find), Source, Find)
    Wend
    Return Count
End Function

' ROUND(3.49) -> 3, ROUND(3.50) -> 4 (половина - от нуля)
Function Round(ByVal Value As Double) As Double
    If Value >= 0 Then Return RqRtFloor(Value + 0.5)
    Return -RqRtFloor(-Value + 0.5)
End Function

' CEIL(66.2) -> 67, FLOOR(66.7) -> 66
Function Ceil(ByVal Value As Double) As Double
    Return -RqRtFloor(-Value)
End Function
Function Floor(ByVal Value As Double) As Double
    Return RqRtFloor(Value)
End Function

Declare Function RqRtGetFileAttributes Lib "kernel32" Alias "GetFileAttributesA" ( _
    ByVal FileName As ZString Ptr) As ULong

' FILEEXISTS / DIREXISTS: 0 - нет, иначе не 0
Function FileExists(ByRef FileName As String) As Long
    Dim Attr As ULong = RqRtGetFileAttributes(StrPtr(FileName))
    If Attr = &hFFFFFFFF Then Return 0
    If (Attr And &h10) <> 0 Then Return 0     ' папка
    Return 1
End Function
Function DirExists(ByRef DirName As String) As Long
    Dim Attr As ULong = RqRtGetFileAttributes(StrPtr(DirName))
    If Attr = &hFFFFFFFF Then Return 0
    If (Attr And &h10) = 0 Then Return 0
    Return 1
End Function

' SHOWMESSAGE "текст"
Sub ShowMessage(ByRef Text As String)
    Dim AppName As String = Command(0)
    Dim SlashPos As Long = InStrRev(AppName, Any "\/")
    If SlashPos > 0 Then AppName = Mid(AppName, SlashPos + 1)
    Dim DotPos As Long = InStrRev(AppName, ".")
    If DotPos > 0 Then AppName = Left(AppName, DotPos - 1)
    RqRtMessageBox(0, Text, AppName, 0)
End Sub

' MESSAGEBOX(текст, заголовок, флаги) - MessageBoxA
Function MessageBox(ByRef Text As String, ByRef Title As String, _
                    ByVal Flags As Long) As Long
    Return RqRtMessageBox(0, Text, Title, Flags)
End Function

' MESSAGEDLG(текст, msgType, msgButtons, helpContext): msgType 0..4 =
' mtWarning, mtError, mtInformation, mtConfirmation, mtCustom; кнопки -
' mbYes 1, mbNo 2, mbOK 4, mbCancel 8, mbAbort 32, mbRetry 64, mbIgnore 128.
' Результат - mrOk 1, mrCancel 2, mrAbort 3, mrRetry 4, mrIgnore 5, mrYes 6,
' mrNo 7 (те же номера, что у MessageBox).
Function MessageDlg(ByRef Text As String, ByVal MsgType As Long, _
                    ByVal Buttons As Long, ByVal HelpContext As Long) As Long
    Dim Flags As ULong = 0
    Select Case MsgType
        Case 0: Flags = &h30          ' MB_ICONWARNING
        Case 1: Flags = &h10          ' MB_ICONERROR
        Case 2: Flags = &h40          ' MB_ICONINFORMATION
        Case 3: Flags = &h20          ' MB_ICONQUESTION
    End Select
    If (Buttons And (1 Or 2)) = (1 Or 2) Then
        If (Buttons And 8) <> 0 Then
            Flags Or= &h3             ' MB_YESNOCANCEL
        Else
            Flags Or= &h4             ' MB_YESNO
        End If
    ElseIf (Buttons And (32 Or 64 Or 128)) = (32 Or 64 Or 128) Then
        Flags Or= &h2                 ' MB_ABORTRETRYIGNORE
    ElseIf (Buttons And (64 Or 8)) = (64 Or 8) Then
        Flags Or= &h5                 ' MB_RETRYCANCEL
    ElseIf (Buttons And (4 Or 8)) = (4 Or 8) Then
        Flags Or= &h1                 ' MB_OKCANCEL
    End If
    Dim Caption As String
    Select Case MsgType
        Case 0: Caption = "Warning"
        Case 1: Caption = "Error"
        Case 2: Caption = "Information"
        Case 3: Caption = "Confirm"
        Case Else: Caption = ""
    End Select
    Return RqRtMessageBox(0, Text, Caption, Flags)
End Function
