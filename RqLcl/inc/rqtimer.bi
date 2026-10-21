' ---------------------------------------------------------------------------
'  rqtimer.bi - QTIMER RapidQ на FreeBASIC (без DLL), таймер Windows
'  SetTimer (rapidq_ref/html_doc/qtimer.html):
'  - Enabled (по умолчанию 1), Interval (мс, по умолчанию 1000 - как у
'    TTimer Delphi; в документации RapidQ значения нет), Tag, OnTimer;
'  - таймер идёт, когда Enabled <> 0, Interval > 0 и задан OnTimer (как у
'    TTimer); смена Interval или Enabled запускает отсчёт заново;
'  - OnTimer вызывается из цикла сообщений (ShowModal, DoEvents формы) -
'    как в RapidQ: без окна и цикла сообщений таймер не срабатывает;
'  - обработчик: Sub() или Sub(ByRef Sender As QTIMER).
' ---------------------------------------------------------------------------

#pragma once

#include once "rqrt.bi"

Declare Function RqRtSetTimer Lib "user32" Alias "SetTimer" ( _
    ByVal WindowHandle As Any Ptr, ByVal EventId As UInteger, _
    ByVal Elapse As ULong, ByVal TimerFunc As Any Ptr) As UInteger
Declare Function RqRtKillTimer Lib "user32" Alias "KillTimer" ( _
    ByVal WindowHandle As Any Ptr, ByVal EventId As UInteger) As Long

Type QTIMER
    TimerId As UInteger
    IntervalMs As Long = 1000
    EnabledFlag As Long = 1
    TagValue As Long
    OnTimerProc As Sub(ByRef Sender As QTIMER)
    OnTimerProcPlain As Sub()
    Declare Constructor()
    Declare Destructor()
    Declare Sub Restart()
    Declare Property Enabled() As Long
    Declare Property Enabled(ByVal Value As Long)
    Declare Property Interval() As Long
    Declare Property Interval(ByVal Value As Long)
    Declare Property Tag() As Long
    Declare Property Tag(ByVal Value As Long)
    Declare Property OnTimer(ByVal Handler As Sub(ByRef Sender As QTIMER))
    Declare Property OnTimer(ByVal Handler As Sub())
End Type

' Работающие таймеры: номер SetTimer -> объект
Dim Shared RqTimerIds() As UInteger
Dim Shared RqTimerObjs() As QTIMER Ptr
Dim Shared RqTimerCount As Long

Private Sub RqTimerProc stdcall (ByVal WindowHandle As Any Ptr, _
        ByVal Msg As ULong, ByVal EventId As UInteger, ByVal TickCount As ULong)
    Dim TimerIdx As Long
    For TimerIdx = 0 To RqTimerCount - 1
        If RqTimerIds(TimerIdx) = EventId Then
            Dim TimerPtr As QTIMER Ptr = RqTimerObjs(TimerIdx)
            If TimerPtr->OnTimerProc <> 0 Then TimerPtr->OnTimerProc(*TimerPtr)
            If TimerPtr->OnTimerProcPlain <> 0 Then TimerPtr->OnTimerProcPlain()
            Exit Sub
        End If
    Next
End Sub

Private Sub RqTimerForget(ByVal EventId As UInteger)
    Dim TimerIdx As Long
    For TimerIdx = 0 To RqTimerCount - 1
        If RqTimerIds(TimerIdx) = EventId Then
            RqTimerCount -= 1
            RqTimerIds(TimerIdx) = RqTimerIds(RqTimerCount)
            RqTimerObjs(TimerIdx) = RqTimerObjs(RqTimerCount)
            Exit Sub
        End If
    Next
End Sub

Constructor QTIMER()
End Constructor

Destructor QTIMER()
    If TimerId <> 0 Then
        RqRtKillTimer(0, TimerId)
        RqTimerForget(TimerId)
        TimerId = 0
    End If
End Destructor

' Остановить и, если нужно, запустить заново с текущими Interval/Enabled
Sub QTIMER.Restart()
    If TimerId <> 0 Then
        RqRtKillTimer(0, TimerId)
        RqTimerForget(TimerId)
        TimerId = 0
    End If
    If (EnabledFlag = 0) Or (IntervalMs <= 0) Then Exit Sub
    If (OnTimerProc = 0) And (OnTimerProcPlain = 0) Then Exit Sub
    TimerId = RqRtSetTimer(0, 0, IntervalMs, @RqTimerProc)
    If TimerId = 0 Then
        RqRtClassError("QTIMER: SetTimer не создал таймер")
        Exit Sub
    End If
    If RqTimerCount > UBound(RqTimerIds) Then
        ReDim Preserve RqTimerIds(RqTimerCount * 2 + 3)
        ReDim Preserve RqTimerObjs(RqTimerCount * 2 + 3)
    End If
    RqTimerIds(RqTimerCount) = TimerId
    RqTimerObjs(RqTimerCount) = @This
    RqTimerCount += 1
End Sub

Property QTIMER.Enabled() As Long
    Return EnabledFlag
End Property
Property QTIMER.Enabled(ByVal Value As Long)
    EnabledFlag = Value
    Restart()
End Property

Property QTIMER.Interval() As Long
    Return IntervalMs
End Property
Property QTIMER.Interval(ByVal Value As Long)
    IntervalMs = Value
    Restart()
End Property

Property QTIMER.Tag() As Long
    Return TagValue
End Property
Property QTIMER.Tag(ByVal Value As Long)
    TagValue = Value
End Property

Property QTIMER.OnTimer(ByVal Handler As Sub(ByRef Sender As QTIMER))
    OnTimerProc = Handler
    OnTimerProcPlain = 0
    Restart()
End Property
Property QTIMER.OnTimer(ByVal Handler As Sub())
    OnTimerProcPlain = Handler
    OnTimerProc = 0
    Restart()
End Property
