
'this structure already in RapidQ2 and Windows.inc
$IFNDEF __WIN32API
    $IFNDEF __RQINC2
    Type LARGE_INTEGER ' Large 64-bit Integer in a 32-bit world
        LowPart As Long
        HighPart As Long
    End Type
    $ENDIF          'RapidQ2

 Declare Function QueryPerformanceCounter Lib "kernel32" Alias_
   "QueryPerformanceCounter" (lpPerformanceCount As long) As Long
 Declare Function QueryPerformanceFrequency Lib "kernel32" Alias_
   "QueryPerformanceFrequency" (lpFrequency As Long) As Long
$ENDIF      'windows inc


'From Jacques P.
FuncTion  MicroTimer_dwToDbl (iDw As Long) As Double
    DefDbl dwTmp, dbl2exp31
    dwTmp = iDw
    dbl2exp31 = 2147483648                  ' 2^31
    If dwTmp < 0 Then                       ' Bit 31, Integer bit sign is set
        dwTmp = dwTmp SHL 1                 ' get rid of bit 31
        dwTmp = dwTmp SHR 1
        Result = dbl2exp31  +  dwTmp        ' add the value of bit 31
    Else
        Result = dwTmp
    End If
End Function


FUNCTION microTIMER() AS DOUBLE
    STATIC AlreadyInit AS INTEGER
    STATIC myFreq as DOUBLE
    DIM TimerFreq as LARGE_INTEGER
    DIM TimerMS as LARGE_INTEGER
    DIM myResult as DOUBLE

    IF AlreadyInit = 0 THEN                 'get our timer resolution
        QueryPerformanceFrequency(TimerFreq)
        AlreadyInit = 1
        IF TimerFreq.HighPart = 0 THEN      'check we can handle frequency in our range
            myFreq = MicroTimer_dwToDbl(TimerFreq.LowPart)
        ELSE
            RESULT = 0.0
            EXIT FUNCTION
        END IF
    END IF
  QueryPerformanceCounter(TimerMS)
  myResult = MicroTimer_dwToDbl(TimerMS.HighPart) * 4294967296.0_
            + MicroTimer_dwToDbl(TimerMS.LowPart)
  RESULT = myResult / myFreq        'result is in relative time
END FUNCTION


'sample code
' DIM a as double
' a = microTimer      'always call at least once to initialize
' a = microTimer      
' 'wait for 3.5 milliseconds
' DO 
' Loop until (microTimer - a) > 0.00350


'Sample #2 see speed of timer
' $INCLUDE <RapidQ2.inc>
' dim degug as qdebug
' for a = 1 to 25
'   degug.Print microTimer
' next a


