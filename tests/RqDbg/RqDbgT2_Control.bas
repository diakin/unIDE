' unIDE, отладчик RapidQ: тест 2, управляющая программа (на месте
' unIDE). Запускать вместе с RqDbgT2_Target.exe из одной папки.
'
' Таймер 100 мс проверяет событие "stopped" с нулевым ожиданием. Когда
' Target остановился - показывает его файл состояния.
' Continue - пишет файл команды и поднимает "continue".
' Pause - поднимает "pause" (Target остановится в цикле Busy loop).
' Третья строка - файл хода RqDbgT2.run от Target: видно, идёт ли цикл
' после Continue (окно Target в цикле не перерисовывается).
' Continue посылается, только когда Target стоит.

DECLARE FUNCTION RqDbgCreateEvent LIB "kernel32" ALIAS "CreateEventA" (BYVAL EventAttr AS LONG, BYVAL ManualReset AS LONG, BYVAL InitialState AS LONG, EventName AS STRING) AS LONG
DECLARE FUNCTION RqDbgSetEvent LIB "kernel32" ALIAS "SetEvent" (BYVAL EventHandle AS LONG) AS LONG
DECLARE FUNCTION RqDbgWait LIB "kernel32" ALIAS "WaitForSingleObject" (BYVAL EventHandle AS LONG, BYVAL WaitMs AS LONG) AS LONG

DIM EvStopped AS LONG
DIM EvContinue AS LONG
DIM EvPause AS LONG
DIM ContinueCount AS INTEGER
DIM TargetStopped AS INTEGER
DIM PollTimer AS QTIMER

DECLARE SUB PollTimerOver
DECLARE SUB ContinueButtonClick
DECLARE SUB PauseButtonClick

CREATE MainForm AS QFORM
  Caption = "RqDbgT2 Control"
  Width = 520
  Height = 190
  Left = 100
  Top = 300
  CREATE StatusLabel AS QLABEL
    Left = 10
    Top = 10
    Width = 480
    Caption = "waiting for target"
  END CREATE
  CREATE StateLabel AS QLABEL
    Left = 10
    Top = 35
    Width = 480
    Caption = "-"
  END CREATE
  CREATE RunLabel AS QLABEL
    Left = 10
    Top = 55
    Width = 480
    Caption = "-"
  END CREATE
  CREATE ContinueButton AS QBUTTON
    Left = 10
    Top = 85
    Width = 120
    Caption = "Continue"
    OnClick = ContinueButtonClick
  END CREATE
  CREATE PauseButton AS QBUTTON
    Left = 140
    Top = 85
    Width = 120
    Caption = "Pause"
    OnClick = PauseButtonClick
  END CREATE
END CREATE

SUB PollTimerOver
  DIM StateFile AS QFILESTREAM
  DIM RunFile AS QFILESTREAM
  IF FILEEXISTS("RqDbgT2.run") THEN
    RunFile.Open("RqDbgT2.run", 64)   ' 64 - fmShareDenyNone: Target может писать в него
    RunLabel.Caption = "run file: " + RunFile.ReadLine
    RunFile.Close
  END IF
  IF RqDbgWait(EvStopped, 0) = 0 THEN
    TargetStopped = 1
    StatusLabel.Caption = "target stopped"
    StateLabel.Caption = "(no state file)"
    IF FILEEXISTS("RqDbgT2.state") THEN
      StateFile.Open("RqDbgT2.state", 0)
      StateLabel.Caption = StateFile.ReadLine
      StateFile.Close
    END IF
  END IF
END SUB

SUB ContinueButtonClick
  DIM CmdFile AS QFILESTREAM
  DIM CallRes AS LONG
  IF TargetStopped = 0 THEN
    StatusLabel.Caption = "target is not stopped - continue not sent"
    EXIT SUB
  END IF
  TargetStopped = 0
  ContinueCount = ContinueCount + 1
  CmdFile.Open("RqDbgT2.cmd", 65535)
  CmdFile.WriteLine("continue #" + STR$(ContinueCount))
  CmdFile.Close
  CallRes = RqDbgSetEvent(EvContinue)
  StatusLabel.Caption = "continue sent, SetEvent result=" + STR$(CallRes)
END SUB

SUB PauseButtonClick
  DIM CallRes AS LONG
  CallRes = RqDbgSetEvent(EvPause)
  StatusLabel.Caption = "pause sent, SetEvent result=" + STR$(CallRes)
END SUB

EvStopped = RqDbgCreateEvent(0, 0, 0, "unIDE_RqDbgT2_Stopped")
EvContinue = RqDbgCreateEvent(0, 0, 0, "unIDE_RqDbgT2_Continue")
EvPause = RqDbgCreateEvent(0, 0, 0, "unIDE_RqDbgT2_Pause")
StateLabel.Caption = "events:" + STR$(EvStopped) + STR$(EvContinue) + STR$(EvPause) + " (all must be non-zero)"

PollTimer.Interval = 100
PollTimer.OnTimer = PollTimerOver
PollTimer.Enabled = 1

MainForm.ShowModal
