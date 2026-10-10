'=======================================================
' Classe QProgress
' Totally redone by Johnk, didn't work reliably anyway, allows Marquees on Windows95 - XP
' uses multi-threading because it won't udate on one thread
' If you use threading you cannot include another CodePtr(SUB), address is used up!!!
'=======================================================
$IFNDEF __QPROGRESS_INC      'don't reload 
    $DEFINE __QPROGRESS_INC

$IFNDEF __WIN32API      'APIs     
    $DEFINE CREATE_SUSPENDED 4&
    Declare Function CreateThread Lib "kernel32" Alias "CreateThread" (lpThreadAttributes As long, ByVal dwStackSize As Long, lpStartAddress As Long, lpParameter As long, ByVal dwCreationFlags As Long, lpThreadId As Long) As Long
    Declare Function ResumeThread Lib "kernel32.dll" Alias "ResumeThread" (hThread As Long) As Long
    Declare Function SuspendThread Lib "kernel32" Alias "SuspendThread" (ByVal hThread As Long) As Long
    Declare Function TerminateThread Lib "kernel32" Alias "TerminateThread" (ByVal hThread As Long, ByVal dwExitCode As Long) As Long
$IFNDEF __RQ2WIN32API
    Declare Function SetParent Lib "user32" Alias "SetParent" (ByVal hWndChild As Long, ByVal hWndNewParent As Long) As Long
    Declare Function CloseHandle Lib "kernel32"  Alias "CloseHandle" (ByVal hObject As Long) As Long
$ENDIF
$ENDIF


$IFNDEF TRUE
  $DEFINE True 1
$ENDIF

$IFNDEF FALSE
  $DEFINE False 0
$ENDIF

$DEFINE gkMovingDot 5
$DEFINE gkMovingRect 6
$DEFINE gkMovingBlur 7
$DEFINE gkBarberPole 8


Type QProgress EXTENDS QIMAGE
    PRIVATE:
        BitMap        as QBitmap
        Increment     as Long
        ObjSize       as integer
        Offset        as integer    'moving graphic
        lpThreadAddr  as Long       'address of the thread sub
        ThreadID      as Long       'for background tasking
        hThread       as Long       'handle of the thread
        Timer         as QTimer     'background timer for marquee

    PUBLIC:
        Caption     as String
        Gauge       as QGauge
        StepSize    as integer
        Interval    as single                           'update interval
        Visible     as integer  PROPERTY SET SetVisible
        Color       as integer  PROPERTY SET SetColor
        BackColor   as integer  PROPERTY SET SetBackColor
        Range       as integer  PROPERTY SET SetRange
        value       as integer  PROPERTY SET SetValue
        Kind        as integer  PROPERTY SET SetKind
        Height      as integer  PROPERTY SET SetHeight 'superclassing
        Width       as integer  PROPERTY SET SetWidth   'etc..
        UseThreading as integer  PROPERTY SET SetMultiThreading


 WITH THIS

 PRIVATE:



    '***********************************************
    '   Create the pretty little graphic or "marquee" for Progress bars without know values
    '***********************************************
    SUB DrawObj
        DIM i as integer
        DIM j AS SINGLE
        DEFINT r = .Color AND &HFF
        DEFINT g = (.Color AND &HFF00) SHR 8
        DEFINT b = (.Color AND &HFF0000) SHR 16
        DEFINT r2 = .BackColor AND &HFF
        DEFINT g2 = (.BackColor AND &HFF00) SHR 8
        DEFINT b2 = (.BackColor AND &HFF0000) SHR 16

        IF .Kind > 4 THEN
            .ObjSize = .Height '* 0.8
            .BitMap.Height = .ObjSize                   'set dimensions for custom
            .BitMap.Width = .Width * 2
            .BitMap.FillRect(0, 0, .BitMap.Width, .BitMap.Height, .BackColor)
            .Offset = (.BitMap.Width - .ObjSize)\2
            IF .StepSize = 0 THEN .StepSize = .ObjSize\2

            SELECT CASE .Kind
            CASE gkMovingDot
                  .BitMap.Circle(.Offset, 0, .Offset + .ObjSize, .ObjSize, .Color, .Color)
    
            CASE gkMovingBlur
                FOR i = 0 TO .Offset
                    j = i/.Offset                         'set gradient
                    .BitMap.Line(i, 0, i, .ObjSize,_
                    RGB((r * j) + (r2 *(1-j)) , (g * j) + (g2 *(1-j)), (b * j) + (b2 *(1-j))))
                NEXT i

            CASE gkMovingRect
                i = .Offset
                j = 2
                 .BitMap.RoundRect(i, 0, i -.ObjSize, .ObjSize, .ObjSize\4, .ObjSize\4, .Color)
                 i = i- .ObjSize - j
                 .BitMap.RoundRect(i, 0, i -.ObjSize, .ObjSize, .ObjSize\4, .ObjSize\4,  RGB((r*.7)+(r2*.3), (g*.7)+(g2*.3), (b*.7)+(b2*.3)))
                 i = i- .ObjSize - j
                 .BitMap.RoundRect(i, 0, i -.ObjSize, .ObjSize, .ObjSize\4, .ObjSize\4, RGB((r*.4)+(r2*.6), (g*.4)+(g2*.6), (b*.4)+(b2*.6)))
                 i = i- .ObjSize - j
                 .BitMap.RoundRect(i, 0, i -.ObjSize, .ObjSize, .ObjSize\4, .ObjSize\4, RGB((r*.2)+(r2*.8), (g*.2)+(g2*.8), (b*.2)+(b2*.8)))

    
            CASE gkBarberPole
                FOR i = 1 TO .BitMap.Width
                    j = ((i MOD .ObjSize) /.ObjSize)^2                   'set gradient gamma
                    .BitMap.Line(i, 0, 0, i, _
                    RGB((r * j) + (r2 *(1-j)) , (g * j) + (g2 *(1-j)), (b * j) + (b2 *(1-j))))
                NEXT i
            END SELECT
            IF .Caption <> "" THEN .BitMap.TextOut(.Left+.Width\2, 0, .Caption, .Color, -1)
        END IF
    END SUB



  PUBLIC:

    '***********************************************
    '   Properties Get / Set 
    '***********************************************

    PROPERTY SET SetMultiThreading(Flag as integer)
        IF Flag= True THEN .UseThreading = True ELSE .UseThreading = False
    END PROPERTY

    PROPERTY SET SetBackColor(Clr as integer)
        .Gauge.BackColor = Clr
        .BackColor = Clr
        IF .Kind > 4 THEN .DrawObj        'custom BMP
    END PROPERTY

    PROPERTY SET SetColor(Clr as integer)
        .Color = Clr
        .Gauge.ForeColor = Clr
        IF .Kind > 4 THEN .DrawObj        'custom
    END PROPERTY

    PROPERTY SET SetWidth(width as integer)
        Super.Width=width
        This.Width = width
        IF .Kind > 4 THEN .DrawObj        'custom
    END PROPERTY

    PROPERTY SET SetHeight(height as integer)
        Super.Height = height
        This.Height = height
        IF .Kind > 4 THEN .DrawObj        'custom
    END PROPERTY

    PROPERTY SET SetRange(value as integer)
        .Gauge.Max = value
        .Gauge.Min = 0
    END PROPERTY

    PROPERTY SET SetKind(value as integer)
        .Kind = value
        IF value > 4 THEN       'custom
            .DrawObj            'draw it, updated sizes
            .Gauge.Enabled = False
            .Gauge.Visible = False
        ELSE
            .Gauge.Kind = value
            .Gauge.Enabled = True
            .Gauge.Visible = True
        END IF
    END PROPERTY

    PROPERTY SET SetValue(TheValue as integer)
        .Value = TheValue
        .Gauge.Position = TheValue
    END PROPERTY




  PRIVATE:


    '***********************************************
    '   Timer routine -- called when timer reaches end of interval, stops on .Visible = False command
    '   do not put a SLEEP command in this sub! only one thread is running, Also DoEvents does nothing
    '***********************************************
    SUB DrawMotionsTimer
'        IF (.visible = False) THEN .Timer.Enabled = False
        .Increment += .StepSize
        IF .Increment > 0  THEN .Increment = -1* .Offset
        .Draw(.Increment, 0, .BitMap.BMP)
    END SUB



    '***********************************************
    '   Threading routine -- continual loop once thread starts
    '***********************************************
    SUB DrawMotions
        DIM i as integer
        DO                                       'Form is ready for painting
            .Increment += .StepSize
            IF .Increment > 0  THEN .Increment = -1* .Offset
            IF .Gauge.Enabled THEN
                  .Gauge.Position = .Value
                  .Gauge.Height = .Height
                  .Gauge.Width = .Width
            ELSE
                  .Draw(.Increment, 0, .BitMap.BMP)
                  .Repaint
            END IF
            'DOEVENTS
            SLEEP This.Interval
        LOOP UNTIL (.Visible = False)
        IF (.hThread <> 0) THEN TerminateThread(.hThread, 0&) : .hThread = 0
    END SUB


    '***********************************************
    '  Create Threading -- cannot use CodePtr (sub..) in any other code!
    '***********************************************
    SUB CreateMyThread
        .lpThreadAddr = CodePtr(This.DrawMotions)
        .hThread = CreateThread (0&, 0&, This.lpThreadAddr, 0&, CREATE_SUSPENDED, VarPtr(This.ThreadID))
    END SUB


    '***********************************************
    '  Timers /threads off OnClose command
    '***********************************************

    SUB Close
        .Timer.Enabled = False          'always turn off processes
        IF .UseThreading THEN 
            IF .hThread <> 0 THEN TerminateThread(.hThread, 0&)
        END IF
        .hThread = 0
    END SUB



  PUBLIC:



    '***********************************************
    '  Timers get started OnShow by .Visible command
    '***********************************************

    PROPERTY SET SetVisible(TheState AS INTEGER)
      IF .Kind > 4 THEN
        IF TheState <> 0 THEN                               'show the form
            IF .UseThreading THEN 
                IF .hThread = 0 THEN .CreateMyThread
                DO: LOOP UNTIL .Visible = True              'wait for the form to appear
                ResumeThread(.hThread)
            ELSE
                .Timer.OnTimer =  This.DrawMotionsTimer     'set our sub for time-out event
                .Timer.Interval = (.Interval * 1000)        'rescale for integer millisec.
                .Timer.Enabled = True
            END IF
        ELSE
            .Close
        END IF
      END IF
      SUPER.Visible = TheState
    END PROPERTY

    
    '***********************************************
    CONSTRUCTOR
        UseThreading = False            'default is Qtimer for marquees
        Timer.Enabled = False           'turn off until needed
        Visible = False
        hThread = 0
        Left = 0
        Top = 0
        Width = 200
        Height = 20
        StepSize = 50
        Color = RGB(128,128,128)        'grey
        BackColor = 0
        Kind = 0                        ' gkText = 0, gkHorizontalBar = 1, gkVerticalBar = 2, gkPie = 3, gkNeedle = 4
        Gauge.Parent = QProgress
        Gauge.Left = 0
        Gauge.Top = 0
        BitMap.Width = 0                'don't allocate mem yet
        BitMap.Height = 0
        Interval = 0.500                '2 times/sec update
        Increment = 0
    END CONSTRUCTOR
    END WITH
END TYPE

$ENDIF
