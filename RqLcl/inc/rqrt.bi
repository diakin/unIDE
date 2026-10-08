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
    Dim Text As String = Level & ": " & Msg
    ' Ошибка в классе RapidQ (QSTRINGLIST и т.д.) - без файла и строки
    If FileName <> "" Then Text = FileName & "(" & LineNum & ") " & Text
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

' Ошибка в классе RapidQ (номер вне списка, нет файла): Smart -
' предупреждение, программа продолжает работу; Compat - конец программы
Sub RqRtClassError(ByRef Msg As String)
#ifdef RQ_COMPAT
    RqRtFatal(Msg, "", 0)
#else
    RqRtWarn(Msg, "", 0)
#endif
End Sub

' GOSUB/RETURN (в FreeBASIC -lang fb их нет). Препроцессор переводит
'   GOSUB Метка -> RqGosubPush(стек(), вершина, N): Goto Метка, а на новой
'                  строке - метка возврата rqgs_retN:
'   RETURN      -> On RqGosubPop(стек(), вершина, __FILE__, __LINE__) Goto
'                  rqgs_ret1, rqgs_ret2, ...
' Стек свой у модуля и у каждой SUB/FUNCTION (в рекурсии - у каждого вызова).
Sub RqGosubPush(Stk() As Long, ByRef Sp As Long, ByVal Site As Long)
    Sp += 1
    If Sp > UBound(Stk) Then ReDim Preserve Stk(1 To Sp * 2)
    Stk(Sp) = Site
End Sub

' Номер GOSUB, к которому вернуться. RETURN без GOSUB - 0 (On 0 Goto никуда
' не переходит): Smart - предупреждение, программа идёт дальше со следующего
' оператора; Compat - конец программы. Что делает RapidQ - не проверено.
Function RqGosubPop(Stk() As Long, ByRef Sp As Long, _
                    ByRef FileName As String, ByVal LineNum As Long) As Long
    If Sp <= 0 Then
#ifdef RQ_COMPAT
        RqRtFatal("RETURN без GOSUB", FileName, LineNum)
#else
        RqRtWarn("RETURN без GOSUB, программа идёт дальше", FileName, LineNum)
#endif
        Return 0
    End If
    Sp -= 1
    Return Stk(Sp + 1)
End Function

' SUBI / FUNCTIONI (документация RapidQ, глава 9): параметры - строки в
' ParamStr$(1..ParamStrCount), числа в ParamVal(1..ParamValCount).
' Препроцессор переводит SUBI Имя(...) в Sub Имя(ByRef RqParams As RqPList),
' вызов Имя "a", 5 - в Имя(RqPList().Arg("a").Arg(5)): временный список
' живёт до конца оператора; строка или число - выбирает перегрузка Arg.
Type RqPList
    Strs(Any) As String
    Vals(Any) As Double
    StrCount As Long
    ValCount As Long
    ' порядок значений (FORMAT$, INITARRAY): > 0 - номер в Vals, < 0 - в Strs
    ArgPos(Any) As Long
    ArgCount As Long
    Declare Function Arg Overload (ByRef Value As Const String) ByRef As RqPList
    Declare Function Arg Overload (ByVal Value As Double) ByRef As RqPList
End Type

Function RqPList.Arg(ByRef Value As Const String) ByRef As RqPList
    StrCount += 1
    ReDim Preserve Strs(1 To StrCount)
    Strs(StrCount) = Value
    ArgCount += 1
    ReDim Preserve ArgPos(1 To ArgCount)
    ArgPos(ArgCount) = -StrCount
    Return This
End Function

Function RqPList.Arg(ByVal Value As Double) ByRef As RqPList
    ValCount += 1
    ReDim Preserve Vals(1 To ValCount)
    Vals(ValCount) = Value
    ArgCount += 1
    ReDim Preserve ArgPos(1 To ArgCount)
    ArgPos(ArgCount) = ValCount
    Return This
End Function

' ParamStr$(Номер). Номер вне 1..ParamStrCount - пустая строка; Smart -
' и предупреждение (что делает RapidQ - не проверено)
Function RqParamStr(ByRef List As RqPList, ByVal Index As Long, _
                    ByRef FileName As String, ByVal LineNum As Long) As String
    If (Index >= 1) AndAlso (Index <= List.StrCount) Then Return List.Strs(Index)
#ifndef RQ_COMPAT
    RqRtWarn("ParamStr$(" & Index & "): строковых параметров " & List.StrCount, _
             FileName, LineNum)
#endif
    Return ""
End Function

' ParamVal(Номер). Номер вне 1..ParamValCount - 0; Smart - и предупреждение
Function RqParamVal(ByRef List As RqPList, ByVal Index As Long, _
                    ByRef FileName As String, ByVal LineNum As Long) As Double
    If (Index >= 1) AndAlso (Index <= List.ValCount) Then Return List.Vals(Index)
#ifndef RQ_COMPAT
    RqRtWarn("ParamVal(" & Index & "): числовых параметров " & List.ValCount, _
             FileName, LineNum)
#endif
    Return 0
End Function

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

' STRF$(значение, формат, точность, знаков) - как FloatToStrF Delphi.
' Форматы (документация RapidQ): 0 ffGeneral, 1 ffExponent, 2 ffFixed,
' 3 ffNumber. Точность - значащих цифр (1..18), знаков: у ffGeneral и
' ffExponent - не меньше цифр в порядке (0..4), у ffFixed и ffNumber - цифр
' после точки (0..18). Половина округляется от нуля. Точка и запятая между
' тысячами - всегда такие (у Delphi они из настроек Windows; как у RapidQ -
' не проверено). Больше 17 значащих цифр у Double нет - дальше нули.
Declare Function RqRtSprintf Cdecl Alias "sprintf" ( _
    ByVal Buffer As ZString Ptr, ByVal FormatText As ZString Ptr, ...) As Long

' Цифры модуля значения: DigitText - значащие, без нулей в конце; значение =
' 0.DigitText * 10^DotPos. Ноль - DigitText пустая, DotPos 0
Sub RqRtDecimal(ByVal Value As Double, ByRef DigitText As String, _
                ByRef DotPos As Long)
    Dim Buffer As ZString * 64
    DigitText = ""
    DotPos = 0
    If Value = 0 Then Exit Sub
    RqRtSprintf(@Buffer, "%.16e", Abs(Value))
    Dim NumText As String = Buffer
    Dim ExpPos As Long = InStr(NumText, "e")
    If ExpPos = 0 Then Exit Sub
    DigitText = Left(NumText, 1) & Mid(NumText, 3, ExpPos - 3)
    DotPos = ValInt(Mid(NumText, ExpPos + 1)) + 1
End Sub

' Округлить до NumDigits значащих цифр (половина - от нуля), убрать нули в
' конце. NumDigits = 0 - остаётся 1 в разряде перед первой цифрой или ноль
Sub RqRtRoundDigits(ByRef DigitText As String, ByRef DotPos As Long, _
                    ByVal NumDigits As Long)
    If DigitText = "" Then Exit Sub
    If NumDigits < 0 Then
        DigitText = ""
        DotPos = 0
        Exit Sub
    End If
    If NumDigits < Len(DigitText) Then
        Dim RoundUp As Long = (DigitText[NumDigits] >= Asc("5"))
        DigitText = Left(DigitText, NumDigits)
        If RoundUp Then
            Dim CharIdx As Long = NumDigits - 1
            Do While CharIdx >= 0 AndAlso DigitText[CharIdx] = Asc("9")
                DigitText[CharIdx] = Asc("0")
                CharIdx -= 1
            Loop
            If CharIdx < 0 Then
                DigitText = "1" & DigitText
                DotPos += 1
            Else
                DigitText[CharIdx] += 1
            End If
        End If
    End If
    Dim TextLen As Long = Len(DigitText)
    Do While TextLen > 0 AndAlso DigitText[TextLen - 1] = Asc("0")
        TextLen -= 1
    Loop
    DigitText = Left(DigitText, TextLen)
    If DigitText = "" Then DotPos = 0
End Sub

' Порядок: E, знак (минус всегда, плюс - если PlusSign), цифр не меньше
' MinDigits
Function RqRtExpText(ByVal ExpValue As Long, ByVal MinDigits As Long, _
                     ByVal PlusSign As Long) As String
    Dim ExpDigits As String = Str(Abs(ExpValue))
    Do While Len(ExpDigits) < MinDigits
        ExpDigits = "0" & ExpDigits
    Loop
    If ExpValue < 0 Then Return "E-" & ExpDigits
    If PlusSign Then Return "E+" & ExpDigits
    Return "E" & ExpDigits
End Function

' Запись с точкой: FracDigits цифр после точки; Thousands - запятые между
' тысячами в целой части
Function RqRtFixedText(ByRef DigitText As String, ByVal DotPos As Long, _
                       ByVal FracDigits As Long, ByVal Thousands As Long) As String
    Dim IntPart As String = "0"
    Dim FracSource As String
    If DotPos > 0 Then
        IntPart = Left(DigitText, DotPos)
        Do While Len(IntPart) < DotPos
            IntPart &= "0"
        Loop
        FracSource = Mid(DigitText, DotPos + 1)
    Else
        FracSource = String(-DotPos, "0") & DigitText
    End If
    Dim FracPart As String = Left(FracSource, FracDigits)
    Do While Len(FracPart) < FracDigits
        FracPart &= "0"
    Loop
    If Thousands Then
        Dim Grouped As String = ""
        Dim CharIdx As Long = Len(IntPart)
        Do While CharIdx > 3
            Grouped = "," & Mid(IntPart, CharIdx - 2, 3) & Grouped
            CharIdx -= 3
        Loop
        IntPart = Left(IntPart, CharIdx) & Grouped
    End If
    If FracDigits > 0 Then Return IntPart & "." & FracPart
    Return IntPart
End Function

' ffGeneral: короче всего; с порядком, если цифр до точки больше Precision
' или значение меньше 0.0001
Function RqRtGeneralText(ByRef DigitText As String, ByVal DotPos As Long, _
                         ByVal Precision As Long, ByVal ExpDigits As Long) As String
    If DigitText = "" Then Return "0"
    If (DotPos > Precision) Or (DotPos < -3) Then
        Dim Mantissa As String = Left(DigitText, 1)
        If Len(DigitText) > 1 Then Mantissa &= "." & Mid(DigitText, 2)
        Return Mantissa & RqRtExpText(DotPos - 1, ExpDigits, 0)
    End If
    Dim FracDigits As Long = Len(DigitText) - DotPos
    If FracDigits < 0 Then FracDigits = 0
    Return RqRtFixedText(DigitText, DotPos, FracDigits, 0)
End Function

Function RqStrF(ByVal Value As Double, ByVal FormatNum As Long, _
                ByVal Precision As Long, ByVal Digits As Long) As String
    If Value <> Value Then Return "NAN"
    If Value > 1.7976931348623157e+308 Then Return "INF"
    If Value < -1.7976931348623157e+308 Then Return "-INF"
    If Precision > 18 Then Precision = 18
    If Precision < 1 Then Precision = 1
    If Digits < 0 Then Digits = 0
    Dim DigitText As String
    Dim DotPos As Long
    Dim ResultText As String
    RqRtDecimal(Value, DigitText, DotPos)
    Select Case FormatNum
    Case 1   ' ffExponent: -d.ddd...E+dd, всего Precision цифр
        If Digits > 4 Then Digits = 4
        RqRtRoundDigits(DigitText, DotPos, Precision)
        Dim Mantissa As String = DigitText
        Do While Len(Mantissa) < Precision
            Mantissa &= "0"
        Loop
        ResultText = Left(Mantissa, 1)
        If Precision > 1 Then ResultText &= "." & Mid(Mantissa, 2)
        If DigitText = "" Then
            ResultText &= RqRtExpText(0, Digits, 1)
        Else
            ResultText &= RqRtExpText(DotPos - 1, Digits, 1)
        End If
    Case 2, 3   ' ffFixed, ffNumber: Digits цифр после точки
        If Digits > 18 Then Digits = 18
        Dim NumDigits As Long = DotPos + Digits
        If NumDigits > Precision Then NumDigits = Precision
        RqRtRoundDigits(DigitText, DotPos, NumDigits)
        If DotPos > Precision Then
            ' цифр до точки больше Precision - как ffGeneral
            If Digits > 4 Then Digits = 4
            ResultText = RqRtGeneralText(DigitText, DotPos, Precision, Digits)
        Else
            ResultText = RqRtFixedText(DigitText, DotPos, Digits, FormatNum = 3)
        End If
    Case Else   ' ffGeneral
        If Digits > 4 Then Digits = 4
        RqRtRoundDigits(DigitText, DotPos, Precision)
        ResultText = RqRtGeneralText(DigitText, DotPos, Precision, Digits)
    End Select
    ' минус - если после округления осталось не ноль
    If (Value < 0) And (DigitText <> "") Then ResultText = "-" & ResultText
    Return ResultText
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

' ---------------------------------------------------------------------------
'  DIR$ и FileRec (otherdetail.html): DIR$(маска, атрибуты) - первый файл,
'  DIR$ без параметров - следующий, "" - больше нет. Найденный файл
'  описывает FileRec: FileName, ShortName, Date, Time, Size, FileTime.
'  Атрибуты - как у FindFirst Delphi, на котором RapidQ: обычные файлы
'  (и только для чтения, архивные) - всегда, скрытые, системные и папки -
'  если их бит есть в атрибутах (&H2, &H4, &H10). Date - "MM-DD-YYYY",
'  Time - "HH:MM:SS" (местное время; формат RapidQ не проверен), FileTime -
'  дата и время DOS одним числом (новее - больше).
' ---------------------------------------------------------------------------

Type RqRtFindData
    FileAttributes As ULong
    CreationLow As ULong
    CreationHigh As ULong
    AccessLow As ULong
    AccessHigh As ULong
    WriteLow As ULong
    WriteHigh As ULong
    SizeHigh As ULong
    SizeLow As ULong
    Reserved0 As ULong
    Reserved1 As ULong
    FileName As ZString * 260
    AlternateName As ZString * 14
End Type

Type RqRtSystemTime
    Year As UShort
    Month As UShort
    DayOfWeek As UShort
    Day As UShort
    Hour As UShort
    Minute As UShort
    Second As UShort
    Milliseconds As UShort
End Type

Declare Function RqRtFindFirstFile Lib "kernel32" Alias "FindFirstFileA" ( _
    ByVal FileName As ZString Ptr, ByVal FindData As RqRtFindData Ptr) As Any Ptr
Declare Function RqRtFindNextFile Lib "kernel32" Alias "FindNextFileA" ( _
    ByVal FindHandle As Any Ptr, ByVal FindData As RqRtFindData Ptr) As Long
Declare Function RqRtFindClose Lib "kernel32" Alias "FindClose" ( _
    ByVal FindHandle As Any Ptr) As Long
Declare Function RqRtFileTimeToLocal Lib "kernel32" Alias "FileTimeToLocalFileTime" ( _
    ByVal FileTime As ULong Ptr, ByVal LocalTime As ULong Ptr) As Long
Declare Function RqRtFileTimeToSystemTime Lib "kernel32" Alias "FileTimeToSystemTime" ( _
    ByVal FileTime As ULong Ptr, ByVal SysTime As RqRtSystemTime Ptr) As Long
Declare Function RqRtFileTimeToDos Lib "kernel32" Alias "FileTimeToDosDateTime" ( _
    ByVal FileTime As ULong Ptr, ByVal DosDate As UShort Ptr, _
    ByVal DosTime As UShort Ptr) As Long

Type RqFileRecType
    FileName As String
    ShortName As String
    Date As String
    Time As String
    Size As LongInt
    FileTime As Long
End Type

Dim Shared FileRec As RqFileRecType
Dim Shared RqRtDirHandle As Any Ptr
Dim Shared RqRtDirAttr As Long

' Подходит ли найденный файл к атрибутам (как FindFirst Delphi)
Private Function RqRtDirMatch(ByRef FindData As RqRtFindData) As Long
    ' &H2 скрытый, &H4 системный, &H8 метка тома, &H10 папка
    Return ((FindData.FileAttributes And Not RqRtDirAttr) And &H1E) = 0
End Function

Private Sub RqRtDirFill(ByRef FindData As RqRtFindData)
    Dim LocalTime(1) As ULong
    Dim SysTime As RqRtSystemTime
    Dim DosDate As UShort, DosTime As UShort
    FileRec.FileName = FindData.FileName
    FileRec.ShortName = FindData.AlternateName
    If FileRec.ShortName = "" Then FileRec.ShortName = FileRec.FileName
    FileRec.Size = (CLngInt(FindData.SizeHigh) Shl 32) Or FindData.SizeLow
    RqRtFileTimeToLocal(@FindData.WriteLow, @LocalTime(0))
    RqRtFileTimeToSystemTime(@LocalTime(0), @SysTime)
    FileRec.Date = Right("0" & SysTime.Month, 2) & "-" & Right("0" & SysTime.Day, 2) & _
                   "-" & SysTime.Year
    FileRec.Time = Right("0" & SysTime.Hour, 2) & ":" & Right("0" & SysTime.Minute, 2) & _
                   ":" & Right("0" & SysTime.Second, 2)
    RqRtFileTimeToDos(@LocalTime(0), @DosDate, @DosTime)
    FileRec.FileTime = (CLng(DosDate) Shl 16) Or DosTime
End Sub

' Следующий подходящий файл после FindFirst / FindNext; нет - ""
Private Function RqRtDirNext(ByRef FindData As RqRtFindData, ByVal HaveOne As Long) As String
    Do
        If HaveOne = 0 Then
            If RqRtDirHandle = 0 Then Return ""
            If RqRtFindNextFile(RqRtDirHandle, @FindData) = 0 Then
                RqRtFindClose(RqRtDirHandle)
                RqRtDirHandle = 0
                Return ""
            End If
        End If
        HaveOne = 0
        If RqRtDirMatch(FindData) Then
            RqRtDirFill(FindData)
            Return FileRec.FileName
        End If
    Loop
End Function

Function RqDir Overload (ByRef FileSpec As String, ByVal Attributes As Long = 0) As String
    Dim FindData As RqRtFindData
    If RqRtDirHandle <> 0 Then
        RqRtFindClose(RqRtDirHandle)
        RqRtDirHandle = 0
    End If
    RqRtDirAttr = Attributes
    RqRtDirHandle = RqRtFindFirstFile(StrPtr(FileSpec), @FindData)
    If (RqRtDirHandle = 0) OrElse (RqRtDirHandle = Cast(Any Ptr, -1)) Then
        RqRtDirHandle = 0
        Return ""
    End If
    Return RqRtDirNext(FindData, 1)
End Function

Function RqDir Overload () As String
    Dim FindData As RqRtFindData
    Return RqRtDirNext(FindData, 0)
End Function

' SLEEP секунды (consoledetail.html: можно дробь, клавишей не прерывается)
Sub RqSleep(ByVal Seconds As Double)
    If Seconds > 0 Then Sleep CLng(Seconds * 1000), 1
End Sub

' s$[N] RapidQ - символ строки с 1; вне строки (0, за концом) - ""
' (тест в RapidQ 2026-10-08). Только чтение: s$[N] = x RapidQ не компилирует.
Function RqStrIdx(ByRef Source As String, ByVal CharNum As Long) As String
    If (CharNum < 1) OrElse (CharNum > Len(Source)) Then Return ""
    Return Chr(Source[CharNum - 1])
End Function

' a$ - b$ RapidQ: из a$ убираются все вхождения b$ ("jello" - "l" ->
' "jeo", operators.html); b$ = "" - a$ без изменений
Function RqStrSub(ByRef Source As String, ByRef Part As String) As String
    If Len(Part) = 0 Then Return Source
    Dim ResultText As String
    Dim StartPos As Long = 1
    Dim FoundPos As Long = InStr(StartPos, Source, Part)
    While FoundPos > 0
        ResultText &= Mid(Source, StartPos, FoundPos - StartPos)
        StartPos = FoundPos + Len(Part)
        FoundPos = InStr(StartPos, Source, Part)
    Wend
    Return ResultText & Mid(Source, StartPos)
End Function

' ---------------------------------------------------------------------------
'  Ресурсы $RESOURCE (глава 8): препроцессор пишет файл .rc, где каждый
'  ресурс - RCDATA с номером 20001 + порядковый номер (с 0), содержимое -
'  файл как есть. Имя ресурса в программе - его номер.
' ---------------------------------------------------------------------------

Declare Function RqRtFindResource Lib "kernel32" Alias "FindResourceA" ( _
    ByVal hModule As Any Ptr, ByVal lpName As Any Ptr, ByVal lpType As Any Ptr) As Any Ptr
Declare Function RqRtLoadResource Lib "kernel32" Alias "LoadResource" ( _
    ByVal hModule As Any Ptr, ByVal hResInfo As Any Ptr) As Any Ptr
Declare Function RqRtLockResource Lib "kernel32" Alias "LockResource" ( _
    ByVal hResData As Any Ptr) As Any Ptr
Declare Function RqRtSizeofResource Lib "kernel32" Alias "SizeofResource" ( _
    ByVal hModule As Any Ptr, ByVal hResInfo As Any Ptr) As ULong
' тип параметра - как у RqLclGetModuleHandle в rqsys.bi (gcc в 64 бит
' не допускает двух разных объявлений одной функции)
Declare Function RqRtGetModuleHandle Lib "kernel32" Alias "GetModuleHandleA" ( _
    ByVal lpModuleName As ZString Ptr) As Any Ptr

Const RqResourceBase = 20001
Const RqRtRcData = 10   ' RT_RCDATA

Private Function RqRtResInfo(ByVal ResId As Long) As Any Ptr
    If (ResId <= 0) OrElse (ResId > &HFFFF) Then Return 0
    Return RqRtFindResource(RqRtGetModuleHandle(0), Cast(Any Ptr, CInt(ResId)), _
                            Cast(Any Ptr, CInt(RqRtRcData)))
End Function

' Поле записи STRING*N (препроцессор: N байт Имя_rqfix и свойство Имя):
' чтение - все N символов, запись - дополняется пробелами, лишнее
' отрезается (как у RapidQ, тест пользователя 2026-10-08)
Function RqFixGet(ByVal Source As UByte Ptr, ByVal ByteCount As Long) As String
    Dim Result As String = Space(ByteCount)
    For ByteIdx As Long = 0 To ByteCount - 1
        Result[ByteIdx] = Source[ByteIdx]
    Next
    Return Result
End Function
Sub RqFixSet(ByVal Dest As UByte Ptr, ByVal ByteCount As Long, ByRef Value As String)
    Dim ValueLen As Long = Len(Value)
    For ByteIdx As Long = 0 To ByteCount - 1
        If ByteIdx < ValueLen Then Dest[ByteIdx] = Value[ByteIdx] Else Dest[ByteIdx] = 32
    Next
End Sub

' RESOURCE(n) - номер n-го ресурса (с 0)
Function RqResource(ByVal ResNum As Long) As Long
    Return RqResourceBase + ResNum
End Function

' RESOURCECOUNT - число ресурсов в exe
Function RqResourceCount() As Long
    Dim ResCount As Long = 0
    While RqRtResInfo(RqResourceBase + ResCount) <> 0
        ResCount += 1
    Wend
    Return ResCount
End Function

' EXTRACTRESOURCE(ресурс, файл) - записать ресурс в файл
Sub RqExtractResource(ByVal ResId As Long, ByRef FileName As String)
    Dim ResInfo As Any Ptr = RqRtResInfo(ResId)
    If ResInfo = 0 Then
        RqRtClassError("EXTRACTRESOURCE: no resource " & ResId)
        Exit Sub
    End If
    Dim ExeModule As Any Ptr = RqRtGetModuleHandle(0)
    Dim ResSize As ULong = RqRtSizeofResource(ExeModule, ResInfo)
    Dim ResData As UByte Ptr = RqRtLockResource(RqRtLoadResource(ExeModule, ResInfo))
    Dim FileNum As Long = FreeFile
    ' прежнее содержимое файла - стереть
    If Open(FileName For Output As #FileNum) = 0 Then Close #FileNum
    If Open(FileName For Binary Access Write As #FileNum) <> 0 Then
        RqRtClassError("EXTRACTRESOURCE: cannot write " & FileName)
        Exit Sub
    End If
    Put #FileNum, 1, *ResData, ResSize
    Close #FileNum
End Sub

' ---------------------------------------------------------------------------
'  SetNewWndProc из NewWndProc.inc (препроцессор заменяет её тело): окну -
'  новая оконная процедура, результат - прежняя. У RapidQ здесь строился
'  переходник x86 (CODEPTR RapidQ не даёт процедуру, годную для Windows);
'  процедура FreeBASIC годится сама. SetWindowLongA / SetWindowLongPtrA -
'  через DyLibSymbol, чтобы не спорить с DECLARE программы (другие типы
'  параметров у того же имени gcc в 64 бит не принимает).
' ---------------------------------------------------------------------------
Type RqRtSetWndLongFn As Function (ByVal Wnd As Any Ptr, ByVal Index As Long, ByVal NewLong As Integer) As Integer
Function RqSetWndProc(ByVal Wnd As Integer, ByVal NewProc As Integer) As Integer
    Static SetWndLong As RqRtSetWndLongFn
    If SetWndLong = 0 Then
#ifdef __FB_64BIT__
        SetWndLong = Cast(RqRtSetWndLongFn, DyLibSymbol(DyLibLoad("user32"), "SetWindowLongPtrA"))
#else
        SetWndLong = Cast(RqRtSetWndLongFn, DyLibSymbol(DyLibLoad("user32"), "SetWindowLongA"))
#endif
    End If
    Return SetWndLong(Cast(Any Ptr, Wnd), -4, NewProc)
End Function

' ---------------------------------------------------------------------------
'  Адреса и память (otherdetail.html): VARPTR, VARPTR$, MEMCPY, MEMSET,
'  MEMCMP. Адрес - число Integer: в 32 бит он помещается в LONG, как у
'  RapidQ; в 64 бит в LONG-переменную адрес не помещается.
' ---------------------------------------------------------------------------

' VARPTR(x) -> RqVarPtr(@x): перегрузка - по типу указателя. У строки -
' адрес её символов: RapidQ-программы пишут через него в саму строку
' (MEMCPY(VARPTR(s$), ...) в QFileDialog.inc, буфер MultiByteToWideChar в
' conversion.inc); @ FreeBASIC у строки - адрес дескриптора, поэтому
' StrPtr. У остального (числа, элементы массивов, записи TYPE) - сам адрес.
Function RqVarPtr Overload (ByVal Address As String Ptr) As Integer
    Return Cast(Integer, StrPtr(*Address))
End Function
Function RqVarPtr Overload (ByVal Address As Any Ptr) As Integer
    Return Cast(Integer, Address)
End Function

' VARPTR$(адрес) - строка по адресу, до нулевого байта (RQConvertCodePage1
' в conversion.inc: Len(VARPTR$(SourseStringPtr)))
Function RqVarPtrStr(ByVal Address As Integer) As String
    If Address = 0 Then Return ""
    Return *Cast(ZString Ptr, Address)
End Function

' Нулевой адрес у MEMCPY / MEMSET / MEMCMP: Smart - предупреждение и
' ничего не делается; Compat - ошибка и конец программы (у RapidQ, видимо,
' падение - не проверено)
Private Function RqRtNullAddr(ByRef FuncName As String, ByVal Address1 As Integer, _
                              ByVal Address2 As Integer, ByVal ByteCount As Integer) As Long
    If ByteCount <= 0 Then Return 1
    If (Address1 <> 0) And (Address2 <> 0) Then Return 0
    RqRtClassError(FuncName & ": address 0 (" & ByteCount & " bytes)")
    Return 1
End Function

' MEMCPY(куда, откуда, байт). Области могут перекрываться - копируется так,
' что результат как у копии через промежуточный буфер.
Sub RqMemCpy(ByVal Dest As Integer, ByVal Source As Integer, ByVal ByteCount As Integer)
    If RqRtNullAddr("MEMCPY", Dest, Source, ByteCount) Then Exit Sub
    Dim DestPtr As UByte Ptr = Cast(UByte Ptr, Dest)
    Dim SrcPtr As UByte Ptr = Cast(UByte Ptr, Source)
    Dim ByteIdx As Integer
    If DestPtr < SrcPtr Then
        For ByteIdx = 0 To ByteCount - 1
            DestPtr[ByteIdx] = SrcPtr[ByteIdx]
        Next
    ElseIf DestPtr > SrcPtr Then
        For ByteIdx = ByteCount - 1 To 0 Step -1
            DestPtr[ByteIdx] = SrcPtr[ByteIdx]
        Next
    End If
End Sub

' MEMSET(адрес, байт, сколько)
Sub RqMemSet(ByVal Address As Integer, ByVal FillByte As Long, ByVal ByteCount As Integer)
    If RqRtNullAddr("MEMSET", Address, Address, ByteCount) Then Exit Sub
    Dim DestPtr As UByte Ptr = Cast(UByte Ptr, Address)
    Dim ByteIdx As Integer
    For ByteIdx = 0 To ByteCount - 1
        DestPtr[ByteIdx] = FillByte And &hFF
    Next
End Sub

' MEMCMP(адрес1, адрес2, сколько): по документации - 0, если содержимое
' НЕ совпадает, иначе не 0 (здесь 1; какое именно не 0 у RapidQ - не
' проверено)
Function RqMemCmp(ByVal Address1 As Integer, ByVal Address2 As Integer, _
                  ByVal ByteCount As Integer) As Long
    If ByteCount <= 0 Then Return 1
    If RqRtNullAddr("MEMCMP", Address1, Address2, ByteCount) Then Return 0
    Dim Ptr1 As UByte Ptr = Cast(UByte Ptr, Address1)
    Dim Ptr2 As UByte Ptr = Cast(UByte Ptr, Address2)
    Dim ByteIdx As Integer
    For ByteIdx = 0 To ByteCount - 1
        If Ptr1[ByteIdx] <> Ptr2[ByteIdx] Then Return 0
    Next
    Return 1
End Function

' ---------------------------------------------------------------------------
'  SENDMESSAGE, POSTMESSAGE, KILLMESSAGE (otherdetail.html). Функции Windows -
'  через DyLibSymbol, как SetWindowLongA ниже: программа может сама объявить
'  SendMessageA с другими типами параметров (constants.inc, RQSV...inc).
' ---------------------------------------------------------------------------
Type RqRtSendMsgFn As Function (ByVal Wnd As Any Ptr, ByVal Msg As ULong, _
    ByVal WParam As UInteger, ByVal LParam As Integer) As Integer
Type RqRtPostMsgFn As Function (ByVal Wnd As Any Ptr, ByVal Msg As ULong, _
    ByVal WParam As UInteger, ByVal LParam As Integer) As Long
Type RqRtPeekMsgFn As Function (ByVal MsgBuf As Any Ptr, ByVal Wnd As Any Ptr, _
    ByVal MsgFirst As ULong, ByVal MsgLast As ULong, ByVal RemoveFlag As ULong) As Long

Private Function RqRtUser32(ByRef ProcName As String) As Any Ptr
    Static User32 As Any Ptr
    If User32 = 0 Then User32 = DyLibLoad("user32")
    Return DyLibSymbol(User32, ProcName)
End Function

' SENDMESSAGE hWnd, uMsg, wParam, lParam - как оператор и как функция.
' lParam-строка - адрес её символов, как параметр STRING у DECLARE ... LIB
' (глава 9; что делает RapidQ со строкой здесь - не проверено)
Function RqSendMessage Overload (ByVal Wnd As Integer, ByVal Msg As Long, _
                                 ByVal WParam As Integer, ByVal LParam As Integer) As Integer
    Static SendMsg As RqRtSendMsgFn
    If SendMsg = 0 Then SendMsg = Cast(RqRtSendMsgFn, RqRtUser32("SendMessageA"))
    Return SendMsg(Cast(Any Ptr, Wnd), Msg, WParam, LParam)
End Function
Function RqSendMessage Overload (ByVal Wnd As Integer, ByVal Msg As Long, _
                                 ByVal WParam As Integer, ByRef LParam As String) As Integer
    Return RqSendMessage(Wnd, Msg, WParam, Cast(Integer, StrPtr(LParam)))
End Function

' POSTMESSAGE hWnd, uMsg, wParam, lParam - не ждёт обработки
Function RqPostMessage(ByVal Wnd As Integer, ByVal Msg As Long, _
                       ByVal WParam As Integer, ByVal LParam As Integer) As Long
    Static PostMsg As RqRtPostMsgFn
    If PostMsg = 0 Then PostMsg = Cast(RqRtPostMsgFn, RqRtUser32("PostMessageA"))
    Return PostMsg(Cast(Any Ptr, Wnd), Msg, WParam, LParam)
End Function

' KILLMESSAGE hWnd, Message - убрать из очереди окна все такие сообщения
' (PeekMessage с PM_REMOVE)
Sub RqKillMessage(ByVal Wnd As Integer, ByVal Msg As Long)
    Static PeekMsg As RqRtPeekMsgFn
    If PeekMsg = 0 Then PeekMsg = Cast(RqRtPeekMsgFn, RqRtUser32("PeekMessageA"))
    Dim MsgBuf(0 To 15) As Integer   ' MSG - 28 байт (48 в 64 бит), с запасом
    While PeekMsg(@MsgBuf(0), Cast(Any Ptr, Wnd), Msg, Msg, 1) <> 0
    Wend
End Sub

' ---------------------------------------------------------------------------
'  SHELL (otherdetail.html). SHELL команда - ждёт конца программы; так и
'  Shell FreeBASIC (через cmd). SHELL(команда, showCMD) - функция: не ждёт,
'  результат - номер процесса (PID). Программа запускается CreateProcessA с
'  этим showCMD; не запустилась (команда cmd вроде "Start файл") - в Smart
'  ещё раз через cmd /c, в Compat - результат 0 (что делает RapidQ - не
'  проверено).
' ---------------------------------------------------------------------------
Type RqRtStartupInfo
    cb As ULong
    lpReserved As ZString Ptr
    lpDesktop As ZString Ptr
    lpTitle As ZString Ptr
    dwX As ULong
    dwY As ULong
    dwXSize As ULong
    dwYSize As ULong
    dwXCountChars As ULong
    dwYCountChars As ULong
    dwFillAttribute As ULong
    dwFlags As ULong
    wShowWindow As UShort
    cbReserved2 As UShort
    lpReserved2 As UByte Ptr
    hStdInput As Any Ptr
    hStdOutput As Any Ptr
    hStdError As Any Ptr
End Type
Type RqRtProcessInfo
    hProcess As Any Ptr
    hThread As Any Ptr
    dwProcessId As ULong
    dwThreadId As ULong
End Type
Type RqRtCreateProcFn As Function (ByVal AppName As ZString Ptr, _
    ByVal CmdLine As ZString Ptr, ByVal ProcAttr As Any Ptr, _
    ByVal ThreadAttr As Any Ptr, ByVal InheritHandles As Long, _
    ByVal CreationFlags As ULong, ByVal Environment As Any Ptr, _
    ByVal CurDir As ZString Ptr, ByVal StartInfo As RqRtStartupInfo Ptr, _
    ByVal ProcInfo As RqRtProcessInfo Ptr) As Long
Type RqRtCloseHandleFn As Function (ByVal Handle As Any Ptr) As Long

Private Function RqRtStartProcess(ByRef CmdLine As String, ByVal ShowCmd As Long) As Long
    Static CreateProc As RqRtCreateProcFn
    Static CloseHnd As RqRtCloseHandleFn
    If CreateProc = 0 Then
        Dim Kernel32 As Any Ptr = DyLibLoad("kernel32")
        CreateProc = Cast(RqRtCreateProcFn, DyLibSymbol(Kernel32, "CreateProcessA"))
        CloseHnd = Cast(RqRtCloseHandleFn, DyLibSymbol(Kernel32, "CloseHandle"))
    End If
    Dim StartInfo As RqRtStartupInfo
    Dim ProcInfo As RqRtProcessInfo
    StartInfo.cb = SizeOf(RqRtStartupInfo)
    StartInfo.dwFlags = 1                  ' STARTF_USESHOWWINDOW
    StartInfo.wShowWindow = ShowCmd
    ' строку команды CreateProcessA может менять - своя копия
    Dim CmdBuf As String = CmdLine & Chr(0)
    If CreateProc(0, StrPtr(CmdBuf), 0, 0, 0, 0, 0, 0, @StartInfo, @ProcInfo) = 0 Then
        Return 0
    End If
    CloseHnd(ProcInfo.hThread)
    CloseHnd(ProcInfo.hProcess)
    Return ProcInfo.dwProcessId
End Function

Function RqShell Overload (ByRef CmdLine As String) As Long
    Return Shell(CmdLine)
End Function
Function RqShell Overload (ByRef CmdLine As String, ByVal ShowCmd As Long) As Long
    Dim ProcId As Long = RqRtStartProcess(CmdLine, ShowCmd)
#ifndef RQ_COMPAT
    If ProcId = 0 Then
        Dim ComSpec As String = Environ("COMSPEC")
        If ComSpec = "" Then ComSpec = "cmd.exe"
        ProcId = RqRtStartProcess("""" & ComSpec & """ /c " & CmdLine, ShowCmd)
    End If
#endif
    Return ProcId
End Function

' ---------------------------------------------------------------------------
'  QUICKSORT(первый, последний, ASCEND|DESCEND) (otherdetail.html): сортирует
'  элементы массива от первого до последнего по адресам в памяти. Перевод:
'  ASCEND -> 0, DESCEND -> 1. Массивы FreeBASIC лежат в памяти каждый
'  отдельно - сортировка через границу двух массивов ("span sort")
'  препроцессор не переводит.
' ---------------------------------------------------------------------------
#macro RQ_QUICKSORT(ElemType)
Private Sub RqRtQSort_##ElemType(ByVal Arr As ElemType Ptr, ByVal LowIdx As Integer, _
                                 ByVal HighIdx As Integer, ByVal Descend As Long)
    While LowIdx < HighIdx
        Dim Pivot As ElemType = Arr[(LowIdx + HighIdx) \ 2]
        Dim LeftIdx As Integer = LowIdx
        Dim RightIdx As Integer = HighIdx
        Do While LeftIdx <= RightIdx
            If Descend Then
                Do While Arr[LeftIdx] > Pivot : LeftIdx += 1 : Loop
                Do While Arr[RightIdx] < Pivot : RightIdx -= 1 : Loop
            Else
                Do While Arr[LeftIdx] < Pivot : LeftIdx += 1 : Loop
                Do While Arr[RightIdx] > Pivot : RightIdx -= 1 : Loop
            End If
            If LeftIdx <= RightIdx Then
                Swap Arr[LeftIdx], Arr[RightIdx]
                LeftIdx += 1
                RightIdx -= 1
            End If
        Loop
        ' меньшую часть - рекурсией, большую - в цикле (глубина стека - log n)
        If RightIdx - LowIdx < HighIdx - LeftIdx Then
            RqRtQSort_##ElemType(Arr, LowIdx, RightIdx, Descend)
            LowIdx = LeftIdx
        Else
            RqRtQSort_##ElemType(Arr, LeftIdx, HighIdx, Descend)
            HighIdx = RightIdx
        End If
    Wend
End Sub
Sub RqQuickSort Overload (ByRef First As ElemType, ByRef Last As ElemType, _
                          ByVal Direction As Long)
    Dim ElemCount As Integer = (@Last - @First) + 1
    If ElemCount < 2 Then Exit Sub
    RqRtQSort_##ElemType(@First, 0, ElemCount - 1, Direction <> 0)
End Sub
#endmacro
RQ_QUICKSORT(Byte)
RQ_QUICKSORT(UByte)
RQ_QUICKSORT(Short)
RQ_QUICKSORT(UShort)
RQ_QUICKSORT(Long)
RQ_QUICKSORT(ULong)
RQ_QUICKSORT(Integer)
RQ_QUICKSORT(UInteger)
RQ_QUICKSORT(LongInt)
RQ_QUICKSORT(ULongInt)
RQ_QUICKSORT(Single)
RQ_QUICKSORT(Double)
RQ_QUICKSORT(String)

' ---------------------------------------------------------------------------
'  VARIANT (datatypes.html, otherdetail.html: VARTYPE). Хранит число (целое),
'  дробное или строку; VARTYPE: 0 - число, 1 - дробное, 2 - строка. Тип
'  меняется при присваивании: дробное с целым значением - число (пример
'  VARTYPE: 77.0 -> 0, 77.01 -> 1). Не присвоенный - число 0.
'  В операции тип выбирает левый операнд (datatypes.html): 101 + "99.5" ->
'  200.5, "101" + 99.5 -> "10199.5". Строка в числе - Val, число в строке -
'  Str ("99.5"); как RapidQ переводит здесь числа вроде 1e20 - не проверено.
' ---------------------------------------------------------------------------
Type RqVariant
    Kind As Long        ' 0 - число, 1 - дробное, 2 - строка (как VARTYPE)
    NumVal As Double
    StrVal As String
    Declare Constructor()
    Declare Constructor(ByVal Value As Double)
    Declare Constructor(ByRef Value As Const String)
    Declare Operator Let(ByVal Value As Double)
    Declare Operator Let(ByRef Value As Const String)
    Declare Operator Cast() As Double
    Declare Operator Cast() As String
    Declare Operator += (ByRef Value As RqVariant)
    Declare Operator += (ByVal Value As Double)
    Declare Operator += (ByRef Value As Const String)
    Declare Operator -= (ByRef Value As RqVariant)
    Declare Operator -= (ByVal Value As Double)
    Declare Operator *= (ByVal Value As Double)
    Declare Operator /= (ByVal Value As Double)
End Type

Function RqVarNum(ByRef Value As RqVariant) As Double
    If Value.Kind = 2 Then Return Val(Value.StrVal)
    Return Value.NumVal
End Function
Function RqVarText(ByRef Value As RqVariant) As String
    If Value.Kind = 2 Then Return Value.StrVal
    Return Str(Value.NumVal)
End Function

Constructor RqVariant()
End Constructor
Constructor RqVariant(ByVal Value As Double)
    This = Value
End Constructor
Constructor RqVariant(ByRef Value As Const String)
    This = Value
End Constructor
Operator RqVariant.Let(ByVal Value As Double)
    NumVal = Value
    StrVal = ""
    If Value = Int(Value) Then Kind = 0 Else Kind = 1
End Operator
Operator RqVariant.Let(ByRef Value As Const String)
    Kind = 2
    StrVal = Value
    NumVal = 0
End Operator
Operator RqVariant.Cast() As Double
    Return RqVarNum(This)
End Operator
Operator RqVariant.Cast() As String
    Return RqVarText(This)
End Operator

' + : левая строка - склейка, иначе сложение чисел
Operator + (ByRef LeftV As RqVariant, ByRef RightV As RqVariant) As RqVariant
    If LeftV.Kind = 2 Then Return RqVariant(LeftV.StrVal & RqVarText(RightV))
    Return RqVariant(LeftV.NumVal + RqVarNum(RightV))
End Operator
Operator + (ByRef LeftV As RqVariant, ByVal RightN As Double) As RqVariant
    If LeftV.Kind = 2 Then Return RqVariant(LeftV.StrVal & Str(RightN))
    Return RqVariant(LeftV.NumVal + RightN)
End Operator
Operator + (ByVal LeftN As Double, ByRef RightV As RqVariant) As RqVariant
    Return RqVariant(LeftN + RqVarNum(RightV))
End Operator
Operator + (ByRef LeftV As RqVariant, ByRef RightS As String) As RqVariant
    If LeftV.Kind = 2 Then Return RqVariant(LeftV.StrVal & RightS)
    Return RqVariant(LeftV.NumVal + Val(RightS))
End Operator
Operator + (ByRef LeftS As String, ByRef RightV As RqVariant) As RqVariant
    Return RqVariant(LeftS & RqVarText(RightV))
End Operator

' - * / ^ \ MOD - всегда числа
#macro RQ_VAR_NUMOP(OpSym)
Operator OpSym (ByRef LeftV As RqVariant, ByRef RightV As RqVariant) As RqVariant
    Return RqVariant(RqVarNum(LeftV) OpSym RqVarNum(RightV))
End Operator
Operator OpSym (ByRef LeftV As RqVariant, ByVal RightN As Double) As RqVariant
    Return RqVariant(RqVarNum(LeftV) OpSym RightN)
End Operator
Operator OpSym (ByVal LeftN As Double, ByRef RightV As RqVariant) As RqVariant
    Return RqVariant(LeftN OpSym RqVarNum(RightV))
End Operator
Operator OpSym (ByRef LeftV As RqVariant, ByRef RightS As String) As RqVariant
    Return RqVariant(RqVarNum(LeftV) OpSym Val(RightS))
End Operator
Operator OpSym (ByRef LeftS As String, ByRef RightV As RqVariant) As RqVariant
    Return RqVariant(Val(LeftS) OpSym RqVarNum(RightV))
End Operator
#endmacro
RQ_VAR_NUMOP(-)
RQ_VAR_NUMOP(*)
RQ_VAR_NUMOP(/)
RQ_VAR_NUMOP(^)
RQ_VAR_NUMOP(\)
RQ_VAR_NUMOP(Mod)

' AND OR XOR - побитово, над целыми
#macro RQ_VAR_BITOP(OpSym)
Operator OpSym (ByRef LeftV As RqVariant, ByRef RightV As RqVariant) As RqVariant
    Return RqVariant(CLngInt(RqVarNum(LeftV)) OpSym CLngInt(RqVarNum(RightV)))
End Operator
Operator OpSym (ByRef LeftV As RqVariant, ByVal RightN As Double) As RqVariant
    Return RqVariant(CLngInt(RqVarNum(LeftV)) OpSym CLngInt(RightN))
End Operator
Operator OpSym (ByVal LeftN As Double, ByRef RightV As RqVariant) As RqVariant
    Return RqVariant(CLngInt(LeftN) OpSym CLngInt(RqVarNum(RightV)))
End Operator
#endmacro
RQ_VAR_BITOP(And)
RQ_VAR_BITOP(Or)
RQ_VAR_BITOP(Xor)

Operator - (ByRef Value As RqVariant) As RqVariant
    Return RqVariant(-RqVarNum(Value))
End Operator
Operator Not (ByRef Value As RqVariant) As RqVariant
    Return RqVariant(Not CLngInt(RqVarNum(Value)))
End Operator

' Сравнение: левая строка - сравнение строк, иначе чисел (-1 / 0)
#macro RQ_VAR_CMPOP(OpSym)
Operator OpSym (ByRef LeftV As RqVariant, ByRef RightV As RqVariant) As Integer
    If LeftV.Kind = 2 Then Return LeftV.StrVal OpSym RqVarText(RightV)
    Return LeftV.NumVal OpSym RqVarNum(RightV)
End Operator
Operator OpSym (ByRef LeftV As RqVariant, ByVal RightN As Double) As Integer
    If LeftV.Kind = 2 Then Return LeftV.StrVal OpSym Str(RightN)
    Return LeftV.NumVal OpSym RightN
End Operator
Operator OpSym (ByVal LeftN As Double, ByRef RightV As RqVariant) As Integer
    Return LeftN OpSym RqVarNum(RightV)
End Operator
Operator OpSym (ByRef LeftV As RqVariant, ByRef RightS As String) As Integer
    If LeftV.Kind = 2 Then Return LeftV.StrVal OpSym RightS
    Return LeftV.NumVal OpSym Val(RightS)
End Operator
Operator OpSym (ByRef LeftS As String, ByRef RightV As RqVariant) As Integer
    Return LeftS OpSym RqVarText(RightV)
End Operator
#endmacro
RQ_VAR_CMPOP(=)
RQ_VAR_CMPOP(<>)
RQ_VAR_CMPOP(<)
RQ_VAR_CMPOP(>)
RQ_VAR_CMPOP(<=)
RQ_VAR_CMPOP(>=)

' & - склейка строк
Operator & (ByRef LeftV As RqVariant, ByRef RightV As RqVariant) As String
    Return RqVarText(LeftV) & RqVarText(RightV)
End Operator
Operator & (ByRef LeftV As RqVariant, ByRef RightS As String) As String
    Return RqVarText(LeftV) & RightS
End Operator
Operator & (ByRef LeftS As String, ByRef RightV As RqVariant) As String
    Return LeftS & RqVarText(RightV)
End Operator

Operator RqVariant.+= (ByRef Value As RqVariant)
    This = This + Value
End Operator
Operator RqVariant.+= (ByVal Value As Double)
    This = This + Value
End Operator
Operator RqVariant.+= (ByRef Value As Const String)
    This = This + Cast(String, Value)
End Operator
Operator RqVariant.-= (ByRef Value As RqVariant)
    This = RqVarNum(This) - RqVarNum(Value)
End Operator
Operator RqVariant.-= (ByVal Value As Double)
    This = RqVarNum(This) - Value
End Operator
Operator RqVariant.*= (ByVal Value As Double)
    This = RqVarNum(This) * Value
End Operator
Operator RqVariant./= (ByVal Value As Double)
    This = RqVarNum(This) / Value
End Operator

' VARTYPE(x): 0 - число, 1 - дробное, 2 - строка
Function RqVarType Overload (ByRef Value As RqVariant) As Long
    Return Value.Kind
End Function
Function RqVarType Overload (ByVal Value As Double) As Long
    If Value = Int(Value) Then Return 0
    Return 1
End Function
Function RqVarType Overload (ByRef Value As String) As Long
    Return 2
End Function

' Присваивание VARIANT переменной другого типа: строка в числе - Val,
' число в строке - Str (у VARIANT тип меняется по месту; что делает здесь
' RapidQ - не проверено)
Function RqNum Overload (ByRef Value As RqVariant, ByRef VarName As String, _
                         ByRef FileName As String, ByVal LineNum As Long) As Double
    Return RqVarNum(Value)
End Function
Function RqSng Overload (ByRef Value As RqVariant, ByRef VarName As String, _
                         ByRef FileName As String, ByVal LineNum As Long) As Single
    Return CSng(RqVarNum(Value))
End Function
Function RqLong Overload (ByRef Value As RqVariant, ByRef VarName As String, _
                          ByRef FileName As String, ByVal LineNum As Long) As Long
    Return RqLong(RqVarNum(Value), VarName, FileName, LineNum)
End Function
Function RqShort Overload (ByRef Value As RqVariant, ByRef VarName As String, _
                           ByRef FileName As String, ByVal LineNum As Long) As Short
    Return RqShort(RqVarNum(Value), VarName, FileName, LineNum)
End Function
Function RqByte Overload (ByRef Value As RqVariant, ByRef VarName As String, _
                          ByRef FileName As String, ByVal LineNum As Long) As UByte
    Return RqByte(RqVarNum(Value), VarName, FileName, LineNum)
End Function
Function RqWord Overload (ByRef Value As RqVariant, ByRef VarName As String, _
                          ByRef FileName As String, ByVal LineNum As Long) As UShort
    Return RqWord(RqVarNum(Value), VarName, FileName, LineNum)
End Function
Function RqDword Overload (ByRef Value As RqVariant, ByRef VarName As String, _
                           ByRef FileName As String, ByVal LineNum As Long) As ULong
    Return RqDword(RqVarNum(Value), VarName, FileName, LineNum)
End Function
Function RqStr Overload (ByRef Value As RqVariant, ByRef VarName As String, _
                         ByRef FileName As String, ByVal LineNum As Long) As String
    Return RqVarText(Value)
End Function
' PRINT: строка - как есть, число - кратко, как в примере datatypes.html
' (PRINT V1+V2 -> 200.5; у DOUBLE PRINT дал бы 200.500000000 - не проверено)
Function RqFmt Overload (ByRef Value As RqVariant) As String
    Return RqVarText(Value)
End Function

' ---------------------------------------------------------------------------
'  INITARRAY(Массив, значение, ...) (otherdetail.html): первые элементы
'  массива по порядку в памяти (у многомерного - весь блок), остальные не
'  меняются. Перевод: RqInitArray(Массив(), RqPList().Arg(...)...).
'  Значений больше, чем элементов, - лишние не пишутся (Smart -
'  предупреждение). Строки в числовой массив и числа в строковый не идут
'  (0 / ""), как присваивание RapidQ.
' ---------------------------------------------------------------------------
Type RqRtArrayInfo
    IndexPtr As Any Ptr
    BasePtr As Any Ptr
    ByteSize As UInteger
    ElemLen As UInteger
End Type
Extern "rtlib"
    Declare Function RqRtArrayDesc Alias "fb_ArrayGetDesc" (Arr() As Any) As RqRtArrayInfo Ptr
End Extern

Private Function RqRtArrayCount(ByVal Info As RqRtArrayInfo Ptr, ByVal ArgCount As Long) As Integer
    If (Info = 0) OrElse (Info->ElemLen = 0) OrElse (Info->BasePtr = 0) Then Return 0
    Dim ElemCount As Integer = Info->ByteSize \ Info->ElemLen
    If ArgCount > ElemCount Then
#ifndef RQ_COMPAT
        RqRtClassError("INITARRAY: " & ArgCount & " values, array has " & ElemCount & " elements")
#endif
        Return ElemCount
    End If
    Return ArgCount
End Function

#macro RQ_INITARRAY(ElemType, IsInt)
Sub RqInitArray Overload (Arr() As ElemType, ByRef List As RqPList)
    Dim FirstPtr As ElemType Ptr = RqRtArrayDesc(Arr())->BasePtr
    Dim FillCount As Integer = RqRtArrayCount(RqRtArrayDesc(Arr()), List.ArgCount)
    Dim ArgIdx As Integer
    For ArgIdx = 1 To FillCount
        If List.ArgPos(ArgIdx) > 0 Then
            If IsInt Then
                FirstPtr[ArgIdx - 1] = RqRtTrunc(List.Vals(List.ArgPos(ArgIdx)))
            Else
                FirstPtr[ArgIdx - 1] = List.Vals(List.ArgPos(ArgIdx))
            End If
        Else
            FirstPtr[ArgIdx - 1] = 0
        End If
    Next
End Sub
#endmacro
RQ_INITARRAY(Byte, 1)
RQ_INITARRAY(UByte, 1)
RQ_INITARRAY(Short, 1)
RQ_INITARRAY(UShort, 1)
RQ_INITARRAY(Long, 1)
RQ_INITARRAY(ULong, 1)
RQ_INITARRAY(Integer, 1)
RQ_INITARRAY(UInteger, 1)
RQ_INITARRAY(LongInt, 1)
RQ_INITARRAY(ULongInt, 1)
RQ_INITARRAY(Single, 0)
RQ_INITARRAY(Double, 0)

Sub RqInitArray Overload (Arr() As String, ByRef List As RqPList)
    Dim FirstPtr As String Ptr = RqRtArrayDesc(Arr())->BasePtr
    Dim FillCount As Integer = RqRtArrayCount(RqRtArrayDesc(Arr()), List.ArgCount)
    Dim ArgIdx As Integer
    For ArgIdx = 1 To FillCount
        If List.ArgPos(ArgIdx) < 0 Then
            FirstPtr[ArgIdx - 1] = List.Strs(-List.ArgPos(ArgIdx))
        Else
            FirstPtr[ArgIdx - 1] = ""
        End If
    Next
End Sub

Sub RqInitArray Overload (Arr() As RqVariant, ByRef List As RqPList)
    Dim FirstPtr As RqVariant Ptr = RqRtArrayDesc(Arr())->BasePtr
    Dim FillCount As Integer = RqRtArrayCount(RqRtArrayDesc(Arr()), List.ArgCount)
    Dim ArgIdx As Integer
    For ArgIdx = 1 To FillCount
        If List.ArgPos(ArgIdx) < 0 Then
            FirstPtr[ArgIdx - 1] = List.Strs(-List.ArgPos(ArgIdx))
        Else
            FirstPtr[ArgIdx - 1] = List.Vals(List.ArgPos(ArgIdx))
        End If
    Next
End Sub

' ---------------------------------------------------------------------------
'  FORMAT$(формат, значения...) (otherdetail.html) - Format Delphi:
'  "%" [индекс ":"] ["-"] [ширина] ["." точность] тип; ширина и точность
'  могут быть "*" (берутся из значений). Типы: d, u, x (целые), e, f, g,
'  n, m (дробные), s (строка), p (адрес); "%%" - знак процента.
'  e, f, g, n - те же правила, что у STRF$ (FloatToStrF Delphi). m - как n
'  (знак валюты и формат Windows не подставляются; у RapidQ - по настройкам
'  Windows, не проверено). Разделители - точка и запятая между тысячами.
'  Неверный формат, нет значения, строка вместо числа и наоборот: у Delphi
'  - ошибка EConvertError; Compat - ошибка и конец программы, Smart -
'  предупреждение: строка вместо числа - Val, число вместо строки - Str.
' ---------------------------------------------------------------------------
Private Function RqRtFormatError(ByRef FormatText As String, ByRef Spec As String) As Long
    RqRtClassError("FORMAT$: format '" & Spec & "' invalid or incompatible with argument (" & FormatText & ")")
    Return 0
End Function

Function RqFormat Overload (ByRef FormatText As String, ByRef List As RqPList) As String
    Dim ResultText As String
    Dim CharPos As Long = 1
    Dim TextLen As Long = Len(FormatText)
    Dim NextArg As Long = 0          ' номер значения с 0, как в Delphi
    Do While CharPos <= TextLen
        Dim CurChar As String = Mid(FormatText, CharPos, 1)
        If CurChar <> "%" Then
            ResultText &= CurChar
            CharPos += 1
            Continue Do
        End If
        Dim SpecStart As Long = CharPos
        CharPos += 1
        If Mid(FormatText, CharPos, 1) = "%" Then
            ResultText &= "%"
            CharPos += 1
            Continue Do
        End If
        ' число или "*" (индекс или ширина)
        Dim LeftAlign As Long = 0
        Dim WidthVal As Long = -1
        Dim PrecVal As Long = -1
        Dim NumText As String
        Dim Pass As Long
        For Pass = 0 To 2
            ' Pass 0 - индекс или ширина, 1 - ширина после "-", 2 - точность
            If Pass = 1 Then
                If Mid(FormatText, CharPos, 1) = "-" Then
                    LeftAlign = 1
                    CharPos += 1
                End If
                If WidthVal >= 0 Then Continue For
            End If
            If Pass = 2 Then
                If Mid(FormatText, CharPos, 1) <> "." Then Exit For
                CharPos += 1
            End If
            Dim FieldVal As Long = -1
            If Mid(FormatText, CharPos, 1) = "*" Then
                CharPos += 1
                If (NextArg < List.ArgCount) AndAlso (List.ArgPos(NextArg + 1) > 0) Then
                    FieldVal = CLng(List.Vals(List.ArgPos(NextArg + 1)))
                Else
                    RqRtFormatError(FormatText, Mid(FormatText, SpecStart, CharPos - SpecStart))
                    FieldVal = 0
                End If
                NextArg += 1
            Else
                NumText = ""
                Do While (CharPos <= TextLen) AndAlso (InStr("0123456789", Mid(FormatText, CharPos, 1)) > 0)
                    NumText &= Mid(FormatText, CharPos, 1)
                    CharPos += 1
                Loop
                If NumText <> "" Then FieldVal = ValInt(NumText)
            End If
            If Pass = 0 Then
                If (FieldVal >= 0) AndAlso (Mid(FormatText, CharPos, 1) = ":") Then
                    NextArg = FieldVal
                    CharPos += 1
                Else
                    WidthVal = FieldVal
                End If
            ElseIf Pass = 1 Then
                WidthVal = FieldVal
            Else
                PrecVal = FieldVal
                If PrecVal < 0 Then PrecVal = 0
            End If
        Next
        Dim TypeCh As String = LCase(Mid(FormatText, CharPos, 1))
        CharPos += 1
        Dim Spec As String = Mid(FormatText, SpecStart, CharPos - SpecStart)
        Dim ArgPos As Long = 0
        If NextArg < List.ArgCount Then ArgPos = List.ArgPos(NextArg + 1)
        NextArg += 1
        Dim NumVal As Double = 0
        Dim TextVal As String = ""
        If ArgPos > 0 Then
            NumVal = List.Vals(ArgPos)
            TextVal = Str(NumVal)
        ElseIf ArgPos < 0 Then
            TextVal = List.Strs(-ArgPos)
            NumVal = Val(TextVal)
        End If
        Dim Piece As String
        Select Case TypeCh
        Case "d", "u", "x", "p"
            If ArgPos <= 0 Then RqRtFormatError(FormatText, Spec)
            Dim IntVal As LongInt = CLngInt(RqRtTrunc(NumVal))
            If NumVal <> RqRtTrunc(NumVal) Then RqRtFormatError(FormatText, Spec)
            If TypeCh = "d" Then
                Piece = Str(Abs(IntVal))
            ElseIf TypeCh = "u" Then
                Piece = Str(CULng(IntVal And &hFFFFFFFF))
            Else
                Piece = Hex(CULng(IntVal And &hFFFFFFFF))
                If TypeCh = "p" Then PrecVal = 8
            End If
            Do While Len(Piece) < PrecVal
                Piece = "0" & Piece
            Loop
            If (TypeCh = "d") AndAlso (IntVal < 0) Then Piece = "-" & Piece
        Case "e", "f", "g", "n", "m"
            If ArgPos <= 0 Then RqRtFormatError(FormatText, Spec)
            Select Case TypeCh
            Case "e"
                If (PrecVal < 0) OrElse (PrecVal > 18) Then PrecVal = 15
                Piece = RqStrF(NumVal, 1, PrecVal, 3)
            Case "g"
                If (PrecVal < 0) OrElse (PrecVal > 18) Then PrecVal = 15
                Piece = RqStrF(NumVal, 0, PrecVal, 3)
            Case "f"
                If PrecVal < 0 Then PrecVal = 2
                Piece = RqStrF(NumVal, 2, 18, PrecVal)
            Case Else
                If PrecVal < 0 Then PrecVal = 2
                Piece = RqStrF(NumVal, 3, 18, PrecVal)
            End Select
        Case "s"
            If ArgPos >= 0 Then RqRtFormatError(FormatText, Spec)
            Piece = TextVal
            If (PrecVal >= 0) AndAlso (Len(Piece) > PrecVal) Then Piece = Left(Piece, PrecVal)
        Case Else
            RqRtFormatError(FormatText, Spec)
            Piece = ""
        End Select
        If Len(Piece) < WidthVal Then
            If LeftAlign Then
                Piece &= Space(WidthVal - Len(Piece))
            Else
                Piece = Space(WidthVal - Len(Piece)) & Piece
            End If
        End If
        ResultText &= Piece
    Loop
    Return ResultText
End Function
Function RqFormat Overload (ByRef FormatText As String) As String
    Return RqFormat(FormatText, RqPList())
End Function
