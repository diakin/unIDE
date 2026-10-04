' unIDE, отладчик RapidQ: тест 2, отлаживаемая программа.
' Запускать вместе с RqDbgT2_Control.exe из одной папки.
'
' Что проверяем:
'   1. CreateEventA / SetEvent / WaitForSingleObject объявляются через
'      DECLARE и работают в RapidQ.
'   2. Ожидание WaitForSingleObject блокирует программу целиком:
'      счётчик (таймер 100 мс) стоит, окно не перерисовывается, кнопки
'      не нажимаются. Ожидание снимает другой процесс (Control).
'   3. Пауза: в длинном цикле раз в 1000 проходов событие "pause"
'      проверяется с нулевым ожиданием. Control поднимает его - цикл
'      останавливается там же, где шёл.
'
' Порядок:
'   Кнопка "Stop here" - остановка в обработчике кнопки. В окне Control
'   должно появиться "target stopped" и текст состояния. Пока не нажата
'   "Continue" в Control, счётчик здесь стоит. После Continue здесь
'   видна команда из файла команды.
'   Кнопка "Busy loop" - цикл до 30 с. Во время цикла нажать "Pause" в
'   Control - здесь остановка, в Control номер прохода. Continue -
'   цикл идёт дальше.
'
' Ожидание - не бесконечное, а 60 с: если Control не ответит, программа
' сама продолжит и покажет "timeout".

DECLARE FUNCTION RqDbgCreateEvent LIB "kernel32" ALIAS "CreateEventA" (BYVAL EventAttr AS LONG, BYVAL ManualReset AS LONG, BYVAL InitialState AS LONG, EventName AS STRING) AS LONG
DECLARE FUNCTION RqDbgSetEvent LIB "kernel32" ALIAS "SetEvent" (BYVAL EventHandle AS LONG) AS LONG
DECLARE FUNCTION RqDbgWait LIB "kernel32" ALIAS "WaitForSingleObject" (BYVAL EventHandle AS LONG, BYVAL WaitMs AS LONG) AS LONG
DECLARE FUNCTION RqDbgTicks LIB "kernel32" ALIAS "GetTickCount" () AS LONG

DIM EvStopped AS LONG
DIM EvContinue AS LONG
DIM EvPause AS LONG
DIM TickCount AS LONG
DIM TickTimer AS QTIMER

DECLARE SUB StopPoint (StateText AS STRING)
DECLARE FUNCTION ReadCommand AS STRING
DECLARE SUB TickTimerOver
DECLARE SUB StopButtonClick
DECLARE SUB BusyButtonClick

CREATE MainForm AS QFORM
  Caption = "RqDbgT2 Target"
  Width = 520
  Height = 170
  Left = 100
  Top = 100
  CREATE CounterLabel AS QLABEL
    Left = 10
    Top = 10
    Width = 480
    Caption = "counter: 0"
  END CREATE
  CREATE StatusLabel AS QLABEL
    Left = 10
    Top = 35
    Width = 480
    Caption = "-"
  END CREATE
  CREATE StopButton AS QBUTTON
    Left = 10
    Top = 70
    Width = 120
    Caption = "Stop here"
    OnClick = StopButtonClick
  END CREATE
  CREATE BusyButton AS QBUTTON
    Left = 140
    Top = 70
    Width = 120
    Caption = "Busy loop"
    OnClick = BusyButtonClick
  END CREATE
END CREATE

' SUB - после CREATE: в них есть ссылки на метки формы
' Состояние - в файл, "стою" - событием, затем ждём "продолжить"
SUB StopPoint (StateText AS STRING)
  DIM StateFile AS QFILESTREAM
  DIM WaitRes AS LONG
  DIM CallRes AS LONG
  StateFile.Open("RqDbgT2.state", 65535)
  StateFile.WriteLine(StateText)
  StateFile.WriteLine("#end")
  StateFile.Close
  StatusLabel.Caption = "stopped: " + StateText
  CallRes = RqDbgSetEvent(EvStopped)
  WaitRes = RqDbgWait(EvContinue, 60000)
  IF WaitRes = 0 THEN
    StatusLabel.Caption = "continued, command: " + ReadCommand
  ELSEIF WaitRes = 258 THEN
    StatusLabel.Caption = "timeout (no answer from Control in 60 s)"
  ELSE
    StatusLabel.Caption = "wait error, result=" + STR$(WaitRes)
  END IF
END SUB

FUNCTION ReadCommand AS STRING
  DIM CmdFile AS QFILESTREAM
  ReadCommand = "(no command file)"
  IF FILEEXISTS("RqDbgT2.cmd") THEN
    CmdFile.Open("RqDbgT2.cmd", 0)
    ReadCommand = CmdFile.ReadLine
    CmdFile.Close
  END IF
END FUNCTION

SUB TickTimerOver
  TickCount = TickCount + 1
  CounterLabel.Caption = "counter: " + STR$(TickCount)
END SUB

SUB StopButtonClick
  DIM LocalNum AS INTEGER
  LocalNum = 42
  StopPoint("StopButtonClick, LocalNum=" + STR$(LocalNum) + ", counter=" + STR$(TickCount))
END SUB

SUB BusyButtonClick
  DIM LoopIdx AS LONG
  DIM SumVal AS LONG
  DIM StartTick AS LONG
  StartTick = RqDbgTicks
  StatusLabel.Caption = "busy loop (up to 30 s), press Pause in Control"
  LoopIdx = 0
  DO
    LoopIdx = LoopIdx + 1
    SumVal = SumVal + (LoopIdx MOD 7)
    IF (LoopIdx MOD 1000) = 0 THEN
      IF RqDbgWait(EvPause, 0) = 0 THEN
        StopPoint("pause in BusyButtonClick, LoopIdx=" + STR$(LoopIdx) + ", SumVal=" + STR$(SumVal))
      END IF
      IF RqDbgTicks - StartTick > 30000 THEN EXIT DO
    END IF
  LOOP
  StatusLabel.Caption = "busy loop done, LoopIdx=" + STR$(LoopIdx)
END SUB


' События с автосбросом: каждый SetEvent отпускает одно ожидание
EvStopped = RqDbgCreateEvent(0, 0, 0, "unIDE_RqDbgT2_Stopped")
EvContinue = RqDbgCreateEvent(0, 0, 0, "unIDE_RqDbgT2_Continue")
EvPause = RqDbgCreateEvent(0, 0, 0, "unIDE_RqDbgT2_Pause")
StatusLabel.Caption = "events:" + STR$(EvStopped) + STR$(EvContinue) + STR$(EvPause) + " (all must be non-zero)"

TickTimer.Interval = 100
TickTimer.OnTimer = TickTimerOver
TickTimer.Enabled = 1

MainForm.ShowModal
