' unIDE, отладчик RapidQ: тест 3 - замедление от вставок перед операторами.
'
' Один и тот же цикл (3 оператора в теле) в нескольких вариантах:
'   V0  без вставок;
'   V1  перед каждым оператором вызов RqDbg(N) - SUB проверяет режим шага
'       и массив точек останова;
'   V2  перед каждым оператором IF RqDbgOn THEN RqDbg(N): при RqDbgOn = 0
'       (нет точек и шага) вызова нет, только проверка флага;
'   V3  как V2, но RqDbgOn = 1 (точки останова есть) - каждый раз вызов;
'   V4  перед каждым оператором IF RqDbgBrk(N) THEN RqDbg(N) - проверка
'       элемента массива на месте, без вызова;
'   V5  как V1, плюс внутри RqDbg раз в 1000 вызовов проверка события
'       "pause" (WaitForSingleObject с нулевым ожиданием).
' Время каждого варианта (мс) и отношение к V0 - в консоль и в
' RqDbgT3.log. Число проходов - LoopMax; если V0 идёт меньше 300 мс,
' увеличить LoopMax.

$APPTYPE CONSOLE

DECLARE FUNCTION RqDbgTicks LIB "kernel32" ALIAS "GetTickCount" () AS LONG
DECLARE FUNCTION RqDbgCreateEvent LIB "kernel32" ALIAS "CreateEventA" (BYVAL EventAttr AS LONG, BYVAL ManualReset AS LONG, BYVAL InitialState AS LONG, EventName AS STRING) AS LONG
DECLARE FUNCTION RqDbgWait LIB "kernel32" ALIAS "WaitForSingleObject" (BYVAL EventHandle AS LONG, BYVAL WaitMs AS LONG) AS LONG

DIM LogFile AS QFILESTREAM
DIM RqDbgBrk(1000) AS INTEGER
DIM RqDbgStep AS INTEGER
DIM RqDbgOn AS INTEGER
DIM RqDbgHit AS LONG
DIM RqDbgPollCnt AS LONG
DIM RqDbgEvPause AS LONG

DECLARE SUB LogLine (LogText AS STRING)
DECLARE SUB RqDbg (PointId AS LONG)
DECLARE SUB RqDbgPoll (PointId AS LONG)

SUB LogLine (LogText AS STRING)
  PRINT LogText
  LogFile.WriteLine(LogText)
END SUB

SUB RqDbg (PointId AS LONG)
  IF RqDbgStep THEN
    RqDbgHit = RqDbgHit + 1
    EXIT SUB
  END IF
  IF RqDbgBrk(PointId) THEN
    RqDbgHit = RqDbgHit + 1
  END IF
END SUB

SUB RqDbgPoll (PointId AS LONG)
  IF RqDbgStep THEN
    RqDbgHit = RqDbgHit + 1
    EXIT SUB
  END IF
  IF RqDbgBrk(PointId) THEN
    RqDbgHit = RqDbgHit + 1
  END IF
  RqDbgPollCnt = RqDbgPollCnt + 1
  IF RqDbgPollCnt >= 1000 THEN
    RqDbgPollCnt = 0
    IF RqDbgWait(RqDbgEvPause, 0) = 0 THEN
      RqDbgHit = RqDbgHit + 1
    END IF
  END IF
END SUB

DIM LoopMax AS LONG
DIM LoopIdx AS LONG
DIM SumVal AS LONG
DIM OtherVal AS LONG
DIM StartTick AS LONG
DIM BaseMs AS LONG
DIM SpentMs AS LONG
DIM WaitKey AS STRING

LoopMax = 300000
LogFile.Open("RqDbgT3.log", 65535)
RqDbgEvPause = RqDbgCreateEvent(0, 0, 0, "unIDE_RqDbgT3_Pause")
LogLine("RqDbgT3 start, LoopMax=" + STR$(LoopMax) + ", pause event=" + STR$(RqDbgEvPause))
' Точка останова на номере, которого в цикле нет: проверки идут,
' остановок нет
RqDbgBrk(999) = 1

' --- V0 ---
SumVal = 0
StartTick = RqDbgTicks
FOR LoopIdx = 1 TO LoopMax
  SumVal = SumVal + (LoopIdx MOD 7)
  OtherVal = SumVal - LoopIdx
  IF OtherVal < 0 THEN OtherVal = 0
NEXT
BaseMs = RqDbgTicks - StartTick
IF BaseMs < 1 THEN BaseMs = 1
LogLine("V0 plain:               " + STR$(BaseMs) + " ms, SumVal=" + STR$(SumVal))

' --- V1 ---
SumVal = 0
StartTick = RqDbgTicks
FOR LoopIdx = 1 TO LoopMax
  RqDbg(101): SumVal = SumVal + (LoopIdx MOD 7)
  RqDbg(102): OtherVal = SumVal - LoopIdx
  RqDbg(103): IF OtherVal < 0 THEN OtherVal = 0
NEXT
SpentMs = RqDbgTicks - StartTick
LogLine("V1 call each stmt:      " + STR$(SpentMs) + " ms, x" + STRF$(SpentMs / BaseMs, 2, 10, 1) + ", SumVal=" + STR$(SumVal))

' --- V2 ---
RqDbgOn = 0
SumVal = 0
StartTick = RqDbgTicks
FOR LoopIdx = 1 TO LoopMax
  IF RqDbgOn THEN RqDbg(101)
  SumVal = SumVal + (LoopIdx MOD 7)
  IF RqDbgOn THEN RqDbg(102)
  OtherVal = SumVal - LoopIdx
  IF RqDbgOn THEN RqDbg(103)
  IF OtherVal < 0 THEN OtherVal = 0
NEXT
SpentMs = RqDbgTicks - StartTick
LogLine("V2 flag check, off:     " + STR$(SpentMs) + " ms, x" + STRF$(SpentMs / BaseMs, 2, 10, 1) + ", SumVal=" + STR$(SumVal))

' --- V3 ---
RqDbgOn = 1
SumVal = 0
StartTick = RqDbgTicks
FOR LoopIdx = 1 TO LoopMax
  IF RqDbgOn THEN RqDbg(101)
  SumVal = SumVal + (LoopIdx MOD 7)
  IF RqDbgOn THEN RqDbg(102)
  OtherVal = SumVal - LoopIdx
  IF RqDbgOn THEN RqDbg(103)
  IF OtherVal < 0 THEN OtherVal = 0
NEXT
SpentMs = RqDbgTicks - StartTick
LogLine("V3 flag check, on:      " + STR$(SpentMs) + " ms, x" + STRF$(SpentMs / BaseMs, 2, 10, 1) + ", SumVal=" + STR$(SumVal))

' --- V4 ---
SumVal = 0
StartTick = RqDbgTicks
FOR LoopIdx = 1 TO LoopMax
  IF RqDbgBrk(101) THEN RqDbg(101)
  SumVal = SumVal + (LoopIdx MOD 7)
  IF RqDbgBrk(102) THEN RqDbg(102)
  OtherVal = SumVal - LoopIdx
  IF RqDbgBrk(103) THEN RqDbg(103)
  IF OtherVal < 0 THEN OtherVal = 0
NEXT
SpentMs = RqDbgTicks - StartTick
LogLine("V4 inline array check:  " + STR$(SpentMs) + " ms, x" + STRF$(SpentMs / BaseMs, 2, 10, 1) + ", SumVal=" + STR$(SumVal))

' --- V5 ---
SumVal = 0
StartTick = RqDbgTicks
FOR LoopIdx = 1 TO LoopMax
  RqDbgPoll(101): SumVal = SumVal + (LoopIdx MOD 7)
  RqDbgPoll(102): OtherVal = SumVal - LoopIdx
  RqDbgPoll(103): IF OtherVal < 0 THEN OtherVal = 0
NEXT
SpentMs = RqDbgTicks - StartTick
LogLine("V5 call + poll/1000:    " + STR$(SpentMs) + " ms, x" + STRF$(SpentMs / BaseMs, 2, 10, 1) + ", SumVal=" + STR$(SumVal))

LogLine("hits (must be 0): " + STR$(RqDbgHit))
LogLine("RqDbgT3 end")
LogFile.Close
INPUT "Enter - exit", WaitKey
