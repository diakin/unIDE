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
