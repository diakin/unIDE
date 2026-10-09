'=======================================================
'Classe QProgress
'Totally redone by Johnk, didn't work reliably anyway, allows Marquees on Windows95 - XP
'uses multi-threading because it won't udate on one thread
'If you use threading you cannot include another CodePtr(SUB), address is used up!!!
'=======================================================

$IFNDEF __QPROGRESS_INC  'don't reload
    $DEFINE __QPROGRESS_INC

    $IFNDEF __WIN32API  'APIs
        $DEFINE CREATE_SUSPENDED 4&
        DECLARE FUNCTION CreateThread LIB "kernel32" ALIAS "CreateThread"(lpThreadAttributes AS LONG , ByVal dwStackSize AS LONG , lpStartAddress AS LONG , lpParameter AS LONG , ByVal dwCreationFlags AS LONG , lpThreadId AS LONG) AS LONG
        DECLARE FUNCTION ResumeThread LIB "kernel32.dll" ALIAS "ResumeThread"(hThread AS LONG) AS LONG
        DECLARE FUNCTION SuspendThread LIB "kernel32" ALIAS "SuspendThread"(ByVal hThread AS LONG) AS LONG
        DECLARE FUNCTION TerminateThread LIB "kernel32" ALIAS "TerminateThread"(ByVal hThread AS LONG , ByVal dwExitCode AS LONG) AS LONG

        $IFNDEF __RQ2WIN32API
            DECLARE FUNCTION SetParent LIB "user32" ALIAS "SetParent"(ByVal hWndChild AS LONG , ByVal hWndNewParent AS LONG) AS LONG
            DECLARE FUNCTION CloseHandle LIB "kernel32" ALIAS "CloseHandle"(ByVal hObject AS LONG) AS LONG
        $ENDIF
    $ENDIF


    $IFNDEF TRUE
        $DEFINE TRUE 1
    $ENDIF

    $IFNDEF FALSE
        $DEFINE FALSE 0
    $ENDIF

    $DEFINE gkMovingDot 5
    $DEFINE gkMovingRect 6
    $DEFINE gkMovingBlur 7
    $DEFINE gkBarberPole 8


    TYPE QProgress EXTENDS QIMAGE
        PRIVATE :
        BitMap      AS QBITMAP
        Increment   AS LONG
        ObjSize     AS INTEGER
        Offset      AS INTEGER  'moving graphic
        lpThreadAddr AS LONG    'address of the thread sub
        ThreadID    AS LONG     'for background tasking
        hThread     AS LONG     'handle of the thread
        TIMER       AS QTIMER  'background timer for marquee

        PUBLIC :
        Caption     AS STRING
        Gauge       AS QGAUGE
        StepSize    AS INTEGER
        Interval    AS SINGLE  'update interval
        Visible     AS INTEGER PROPERTY SET SetVisible
        Color       AS INTEGER PROPERTY SET SetColor
        BackColor   AS INTEGER PROPERTY SET SetBackColor
        Range       AS INTEGER PROPERTY SET SetRange
        value       AS INTEGER PROPERTY SET SetValue
        Kind        AS INTEGER PROPERTY SET SetKind
        Height      AS INTEGER PROPERTY SET SetHeight  'superclassing
        Width       AS INTEGER PROPERTY SET SetWidth  'etc..
        UseThreading AS INTEGER PROPERTY SET SetMultiThreading


        WITH THIS

            PRIVATE :


            '***********************************************
            'Create the pretty little graphic or "marquee" for Progress bars without know values
            '***********************************************
            SUB DrawObj
                DIM i AS INTEGER
                DIM j AS SINGLE
                DEFINT r = .Color AND &HFF
                DEFINT g = (.Color AND &HFF00) SHR 8
                DEFINT b = (.Color AND &HFF0000) SHR 16
                DEFINT r2 = .BackColor AND &HFF
                DEFINT g2 = (.BackColor AND &HFF00) SHR 8
                DEFINT b2 = (.BackColor AND &HFF0000) SHR 16

                IF .Kind > 4 THEN
                    .ObjSize = .Height  '* 0.8
                    .BitMap.Height = .ObjSize  'set dimensions for custom
                    .BitMap.Width = .Width * 2
                    .BitMap.FillRect(0 , 0 , .BitMap.Width , .BitMap.Height , .BackColor)
                    .Offset = (.BitMap.Width - .ObjSize) \ 2
                    IF .StepSize = 0 THEN .StepSize = .ObjSize \ 2

                    SELECT CASE .Kind
                        CASE gkMovingDot
                            .BitMap.Circle(.Offset , 0 , .Offset + .ObjSize , .ObjSize , .Color , .Color)

                        CASE gkMovingBlur
                            FOR i = 0 TO .Offset
                                j = i / .Offset  'set gradient
                                .BitMap.Line(i , 0 , i , .ObjSize , _
                                    RGB((r * j) + (r2 * (1 - j)) , (g * j) + (g2 * (1 - j)) , (b * j) + (b2 * (1 - j))))
                            NEXT i

                        CASE gkMovingRect
                            i = .Offset
                            j = 2
                            .BitMap.RoundRect(i , 0 , i - .ObjSize , .ObjSize , .ObjSize \ 4 , .ObjSize \ 4 , .Color)
                            i = i - .ObjSize - j
                            .BitMap.RoundRect(i , 0 , i - .ObjSize , .ObjSize , .ObjSize \ 4 , .ObjSize \ 4 , RGB((r * .7) + (r2 * .3) , (g * .7) + (g2 * .3) , (b * .7) + (b2 * .3)))
                            i = i - .ObjSize - j
                            .BitMap.RoundRect(i , 0 , i - .ObjSize , .ObjSize , .ObjSize \ 4 , .ObjSize \ 4 , RGB((r * .4) + (r2 * .6) , (g * .4) + (g2 * .6) , (b * .4) + (b2 * .6)))
                            i = i - .ObjSize - j
                            .BitMap.RoundRect(i , 0 , i - .ObjSize , .ObjSize , .ObjSize \ 4 , .ObjSize \ 4 , RGB((r * .2) + (r2 * .8) , (g * .2) + (g2 * .8) , (b * .2) + (b2 * .8)))


                        CASE gkBarberPole
                            FOR i = 1 TO .BitMap.Width
                                j = ((i MOD .ObjSize) / .ObjSize) ^2  'set gradient gamma
                                .BitMap.Line(i , 0 , 0 , i , _
                                    RGB((r * j) + (r2 * (1 - j)) , (g * j) + (g2 * (1 - j)) , (b * j) + (b2 * (1 - j))))
                            NEXT i
                    END SELECT
                    IF .Caption <> "" THEN .BitMap.TextOut(.Left + .Width \ 2 , 0 , .Caption , .Color , - 1)
                END IF
            END SUB


            PUBLIC :

            '***********************************************
            'Properties Get / Set
            '***********************************************

            PROPERTY SET SetMultiThreading(Flag AS INTEGER)
                IF Flag = TRUE THEN .UseThreading = TRUE ELSE .UseThreading = FALSE
            END PROPERTY

            PROPERTY SET SetBackColor(Clr AS INTEGER)
                .Gauge.BackColor = Clr
                .BackColor = Clr
                IF .Kind > 4 THEN .DrawObj  'custom BMP
            END PROPERTY

            PROPERTY SET SetColor(Clr AS INTEGER)
                .Color = Clr
                .Gauge.ForeColor = Clr
                IF .Kind > 4 THEN .DrawObj  'custom
            END PROPERTY

            PROPERTY SET SetWidth(Width AS INTEGER)
                Super.Width = Width
                This.Width = Width
                IF .Kind > 4 THEN .DrawObj  'custom
            END PROPERTY

            PROPERTY SET SetHeight(Height AS INTEGER)
                Super.Height = Height
                This.Height = Height
                IF .Kind > 4 THEN .DrawObj  'custom
            END PROPERTY

            PROPERTY SET SetRange(value AS INTEGER)
                .Gauge.Max = value
                .Gauge.Min = 0
            END PROPERTY

            PROPERTY SET SetKind(value AS INTEGER)
                .Kind = value
                IF value > 4 THEN  'custom
                    .DrawObj  'draw it, updated sizes
                    .Gauge.Enabled = FALSE
                    .Gauge.Visible = FALSE
                ELSE
                    .Gauge.Kind = value
                    .Gauge.Enabled = TRUE
                    .Gauge.Visible = TRUE
                END IF
            END PROPERTY

            PROPERTY SET SetValue(TheValue AS INTEGER)
                .Value = TheValue
                .Gauge.Position = TheValue
            END PROPERTY


            PRIVATE :


            '***********************************************
            'Timer routine -- called when timer reaches end of interval, stops on .Visible = False command
            'do not put a SLEEP command in this sub! only one thread is running, Also DoEvents does nothing
            '***********************************************
            SUB DrawMotionsTimer
                'IF (.visible = False) THEN .Timer.Enabled = False
                .Increment + = .StepSize
                IF .Increment > 0 THEN .Increment = - 1 * .Offset
                .Draw(.Increment , 0 , .BitMap.BMP)
            END SUB


            '***********************************************
            'Threading routine -- continual loop once thread starts
            '***********************************************
            SUB DrawMotions
                DIM i AS INTEGER
                DO  'Form is ready for painting
                    .Increment + = .StepSize
                    IF .Increment > 0 THEN .Increment = - 1 * .Offset
                    IF .Gauge.Enabled THEN
                        .Gauge.Position = .Value
                        .Gauge.Height = .Height
                        .Gauge.Width = .Width
                    ELSE
                        .Draw(.Increment , 0 , .BitMap.BMP)
                        .Repaint
                    END IF
                    'DOEVENTS
                    SLEEP This.Interval
                LOOP UNTIL (.Visible = FALSE)
                IF (.hThread <> 0) THEN TerminateThread(.hThread , 0&)  : .hThread = 0
            END SUB


            '***********************************************
            'Create Threading -- cannot use CodePtr (sub..) in any other code!
            '***********************************************
            SUB CreateMyThread
                .lpThreadAddr = CODEPTR(This.DrawMotions)
                .hThread = CreateThread(0& , 0& , This.lpThreadAddr , 0& , CREATE_SUSPENDED , VARPTR(This.ThreadID))
            END SUB


            '***********************************************
            'Timers /threads off OnClose command
            '***********************************************

            SUB Close
                .TIMER.Enabled = FALSE  'always turn off processes
                IF .UseThreading THEN
                    IF .hThread <> 0 THEN TerminateThread(.hThread , 0&)
                END IF
                .hThread = 0
            END SUB


            PUBLIC :


            '***********************************************
            'Timers get started OnShow by .Visible command
            '***********************************************

            PROPERTY SET SetVisible(TheState AS INTEGER)
                IF .Kind > 4 THEN
                    IF TheState <> 0 THEN  'show the form
                        IF .UseThreading THEN
                            IF .hThread = 0 THEN .CreateMyThread
                            DO :  LOOP UNTIL .Visible = TRUE  'wait for the form to appear
                            ResumeThread(.hThread)
                        ELSE
                            .TIMER.OnTimer = This.DrawMotionsTimer  'set our sub for time-out event
                            .TIMER.Interval = (.Interval * 1000) 'rescale for integer millisec.
                            .TIMER.Enabled = TRUE
                        END IF
                    ELSE
                        .Close
                    END IF
                END IF
                SUPER.Visible = TheState
            END PROPERTY


            '***********************************************
            CONSTRUCTOR
                UseThreading = FALSE  'default is Qtimer for marquees
                TIMER.Enabled = FALSE  'turn off until needed
                Visible = FALSE
                hThread = 0
                Left = 0
                Top = 0
                Width = 200
                Height = 20
                StepSize = 50
                Color = RGB(128 , 128 , 128) 'grey
                BackColor = 0
                Kind = 0  'gkText = 0, gkHorizontalBar = 1, gkVerticalBar = 2, gkPie = 3, gkNeedle = 4
                Gauge.Parent = QProgress
                Gauge.Left = 0
                Gauge.Top = 0
                BitMap.Width = 0  'don't allocate mem yet
                BitMap.Height = 0
                Interval = 0.500  '2 times/sec update
                Increment = 0
            END CONSTRUCTOR
        END WITH
    END TYPE

$ENDIF

