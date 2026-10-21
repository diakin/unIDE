' QTIMER: OnTimer without parameters and with Sender, Interval and Enabled
' changed inside the handler, timer stops at Enabled = 0.
$APPTYPE CONSOLE
DIM TickCount AS INTEGER
DIM Form AS QFORM
DIM TimerA AS QTIMER
DIM TimerB AS QTIMER
DECLARE SUB TimerAOver
DECLARE SUB TimerBOver (Sender AS QTIMER)

SUB TimerAOver
  TickCount = TickCount + 1
  PRINT "a tick "; TickCount
  IF TickCount = 3 THEN
    TimerA.Enabled = 0
    TimerB.Tag = 7
    TimerB.Enabled = 1
  END IF
END SUB

SUB TimerBOver (Sender AS QTIMER)
  PRINT "b tag "; Sender.Tag; " a enabled "; TimerA.Enabled; " ticks "; TickCount
  Sender.Enabled = 0
  Form.Close
END SUB

PRINT "defaults "; TimerA.Enabled; " "; TimerA.Interval
TimerB.Enabled = 0
TimerB.Interval = 50
TimerB.OnTimer = TimerBOver
TimerA.Interval = 30
TimerA.OnTimer = TimerAOver
Form.ShowModal
PRINT "end "; TickCount
