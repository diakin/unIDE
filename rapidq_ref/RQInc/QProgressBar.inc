'=======================================================
'QProgressBar.inc, replaces QProgress.inc
'Code derived from windows Progress bar in RQ by Benjamin Maggi 
'and marquee sample code courtesy from David Burkley
'Ex: It uses real Windows Progress Bar (comctl32.dll)

'major Code reworking by Johnk into QComponent
'=======================================================

$IFNDEF __QPROGRESSBAR_INC         'don't reload
    $DEFINE __QPROGRESSBAR_INC

    $IFNDEF __WIN32API  'APIs

        DECLARE FUNCTION UpdateWindow LIB "USER32" ALIAS "UpdateWindow" _
                 (hWnd AS LONG) AS LONG

        DECLARE FUNCTION DestroyWindow LIB "user32" ALIAS "DestroyWindow" (ByVal hWnd AS LONG) AS LONG

        '-- Window styles
        CONST WS_CHILD = &H40000000
        CONST WS_VISIBLE = &H10000000


        $IFNDEF __RQ2WIN32API
            DECLARE FUNCTION SetParent LIB "user32" ALIAS "SetParent"(ByVal hWndChild AS LONG , ByVal hWndNewParent AS LONG) AS LONG
            DECLARE FUNCTION CloseHandle LIB "kernel32" ALIAS "CloseHandle"(ByVal hObject AS LONG) AS LONG
            Declare Function CreateWindowEx Lib "user32" Alias "CreateWindowExA"_
                    (ByVal dwExStyle As Long, ByVal lpClassName As String, _
                    ByVal lpWindowName As String, ByVal dwStyle As Long, _
                    ByVal x As Long, ByVal y As Long, ByVal nWidth As Long, ByVal nHeight As Long,_
                    ByVal hWndParent As Long, ByVal hMenu As Long, ByVal hInstance As Long, lpParam As Long) As Long

            DECLARE SUB SetWindowPos Lib "User32"  ALIAS "SetWindowPos"_
                    (ByVal hWnd As Long,_
                    ByVal hWndInsertAfter As Long,_
                    ByVal X As Long,_
                    ByVal Y As Long,_
                    ByVal cx As Long, ByVal cy As Long, ByVal wFlags As Long)

            DECLARE FUNCTION SetWindowLong LIB "user32" ALIAS "SetWindowLongA" (hWnd AS LONG,nIndex AS LONG, dwNewLong AS LONG) AS LONG

            CONST GWL_STYLE = - 16
        $ENDIF
    $ENDIF

    $DEFINE PBS_OLD 0       'old school specific for QProgressBar
    'These are available only if the version of
    'comctl32.dll is greater than 4.70 (IE3 and later)
    $DEFINE PBM_SETRANGE &H0401
    $DEFINE PBM_SETPOS &H0402
    $DEFINE PBM_DELTAPOS &H0403
    $DEFINE PBM_SETSTEP &H0404
    $DEFINE PBM_STEPIT &H0405
    $DEFINE PBM_SETRANGE32 &H0406
    $DEFINE PBM_GETRANGE &H0407
    $DEFINE PBM_GETPOS &H0408
    $DEFINE PBM_SETBARCOLOR &H0409
    $DEFINE PBM_SETBKCOLOR &H2001
    $DEFINE PBM_SETMARQUEE &H040A
    $DEFINE PBM_GETSTEP &H040D
    $DEFINE PBM_GETBKCOLOR &H040E
    $DEFINE PBM_GETBARCOLOR &H040F
    $DEFINE PBM_SETSTATE &H0410
    $DEFINE PBM_GETSTATE &H0411


    $DEFINE PBS_SMOOTH  1  'Smooth will show filled bar otherwise block bar
    $DEFINE PBS_VERTICAL 4
    $DEFINE PBS_MARQUEE 8
    $DEFINE PBS_SMOOTHREVERSE 16

    $DEFINE PBST_NORMAL 1
    $DEFINE PBST_ERROR 2
    $DEFINE PBST_PAUSED 3

    $IFNDEF TRUE
        $DEFINE TRUE 1
    $ENDIF

    $IFNDEF FALSE
        $DEFINE FALSE 0
    $ENDIF

    $DEFINE SWP_HIDEWINDOW &H0080       'Hides the window.
    $DEFINE SWP_NOACTIVATE &H0010       'Does not activate the window. If this flag is not set, the window is activated and moved to the top of either the topmost or non-topmost group (depending on the setting of the hWndInsertAfter parameter).
    $DEFINE SWP_NOOWNERZORDER &H0200    'Does not change the owner window's position in the Z order.
    $DEFINE SWP_NOREDRAW  &H0008        'Does not redraw changes. If this flag is set, no repainting of any kind occurs. This applies to the client area, the nonclient area (including the title bar and scroll bars), and any part of the parent window uncovered as a result of the window being moved. When this flag is set, the application must explicitly invalidate or redraw any parts of the window and parent window that need redrawing.
    $DEFINE SWP_NOSIZE &H0001           'Retains the current size (ignores the cx and cy parameters).
    $DEFINE SWP_NOZORDER &H0004         'Retains the current Z order (ignores the hWndInsertAfter parameter)
    $DEFINE SWP_SHOWWINDOW &H0040 



TYPE QProgressBar EXTENDS QOBJECT

    PUBLIC :
        Parent      AS INTEGER PROPERTY SET SetParent
        Handle      AS INTEGER
        'Caption     AS STRING
        Interval    AS INTEGER                           'update interval
        Increment   AS INTEGER
        Visible     AS INTEGER PROPERTY SET SetVisible
        Max         AS INTEGER PROPERTY SET SetMax
        Min         AS INTEGER PROPERTY SET SetMin
        Color       AS INTEGER PROPERTY SET SetColor
        BackColor   AS INTEGER PROPERTY SET SetBackColor
        Position    AS INTEGER PROPERTY SET SetPosition
        Kind        AS INTEGER PROPERTY SET SetKind
        Top         AS INTEGER PROPERTY SET SetTop
        Left        AS INTEGER PROPERTY SET SetLeft
        Height      AS INTEGER PROPERTY SET SetHeight
        Width       AS INTEGER PROPERTY SET SetWidth  'etc..
        State       AS INTEGER PROPERTY SET SetState

    WITH THIS

    SUB Create
        DEFINT NewStyle = WS_CHILD OR WS_VISIBLE
        IF .Kind <> PBS_OLD THEN NewStyle = NewStyle OR .Kind
        .Handle = CreateWindowEx(0, "msctls_progress32", "", NewStyle, _
                    .Left, .Top, .Width, .Height, .Parent, 0, Application.hInstance, 0) ' inc2026: в строке 122 было .Top, .Left, стало .Left, .Top: у CreateWindowEx сначала x, потом y
    END SUB



    '***********************************************
    'Timers /threads off OnClose command
    '***********************************************

    SUB Close
        IF .Handle <> 0 THEN
            IF .Kind = PBS_MARQUEE THEN SendMessage(.Handle , PBM_SETMARQUEE , 0 , 0)
            DestroyWindow(.Handle)
            .Handle = 0
            .Visible = False
        END IF
    END SUB


    SUB SetRange                    'Set the range of the progress bar.
        'lParam LOWORD= minimum range,  HIWORD = maximum range; minimum range cannot be negative
        'default, min = 0, max = 100 ; max > min, highest range = 0 to 65,535. 
        IF This.Max > &HFFFF THEN This.Max = &HFFFF          '16 bit only
        IF This.Max > This.Min THEN SendMessage(This.Handle, PBM_SETRANGE, 0, This.Min + (This.Max SHL 16))
    END SUB


    'make a general reformat sub for operations on setting properties
    SUB ReDraw
        IF .Visible = False THEN EXIT SUB
        IF This.Handle = 0 THEN .Create         'make new one
        IF This.Handle = 0 THEN EXIT SUB        'failed!!
        .SetRange                               'take care of min / max properties

        IF .Kind <> PBS_MARQUEE THEN
            'step increment by which the progress bar increases its current position on PBM_STEPIT message, default is 10. 
            SendMessage(.Handle, PBM_SETSTEP, .Increment, 0)
            SendMessage (.Handle, PBM_SETBKCOLOR, 0, .BackColor)
            SendMessage (.Handle, PBM_SETBARCOLOR, 0, .Color)
            SendMessage(.Handle, PBM_SETPOS, .Position, 0)
        ELSE
            SendMessage(.Handle , PBM_SETMARQUEE , 1 , .Interval)    '1 = on, 40 = milliseconds update
        END IF

        'IF This.Visible THEN TheParams = TheParams OR SWP_SHOWWINDOW ELSE TheParams = TheParams OR SWP_HIDEWINDOW
        SetWindowPos(.Handle, 0, .Left, .Top, .Width, .Height, SWP_NOSIZE OR SWP_NOZORDER)
    END SUB


    '***********************************************
    'Properties Get / Set
    '***********************************************

    SUB SetParent(TheParent AS INTEGER)
        .Parent = TheParent
        IF .Parent = 0 THEN EXIT SUB

        IF .Handle = 0 THEN
            .Create
        ELSE
            IF TheParent THEN SetParent(.Handle, TheParent)
        END IF
        .ReDraw
    END SUB


    SUB SetMax(TheValue)
        .Max = TheValue
        .ReDraw
    END SUB

    SUB SetMin(TheValue)
        .Min = TheValue
        .ReDraw
    END SUB


    SUB SetPosition(TheValue AS INTEGER)
        .Position =  TheValue
        .ReDraw
    END SUB


    PROPERTY SET SetBackColor(Clr AS INTEGER)
        .BackColor = Clr
        .ReDraw
    END PROPERTY

    PROPERTY SET SetColor(Clr AS INTEGER)
        .Color = Clr
        .ReDraw
    END PROPERTY

    PROPERTY SET SetTop(Top AS INTEGER)
        .Top = Top
        .ReDraw
    END PROPERTY


    PROPERTY SET SetLeft(Left AS INTEGER)
        .Left = Left
        .ReDraw
    END PROPERTY

    PROPERTY SET SetWidth(Width AS INTEGER)
        .Width = Width
        .ReDraw
    END PROPERTY

    PROPERTY SET SetHeight(Height AS INTEGER)
        .Height = Height
        .ReDraw
    END PROPERTY


    PROPERTY SET SetKind(value AS INTEGER)
        IF value <> .Kind THEN
            .Close
            .Kind = value
            IF .Kind = PBS_VERTICAL THEN IF .Width > .Height THEN SWAP(.Width, .Height)
            .ReDraw
        END IF
    END PROPERTY

    PROPERTY SET SetState(value AS INTEGER)
        .State = value
        IF .State < 2 THEN  SendMessage(.Handle, PBM_SETSTATE, PBST_NORMAL, 0)
        IF .State = 2 THEN  SendMessage(.Handle, PBM_SETSTATE, PBST_ERROR, 0)
        IF .State = 3 THEN  SendMessage(.Handle, PBM_SETSTATE, PBST_PAUSED, 0)
        .ReDraw
    END PROPERTY


    PROPERTY SET SetVisible(TheState AS INTEGER)
        IF TheState = False THEN
            .Close                  'destroy
            .Visible = False
        ELSE
            .Visible = True
            .ReDraw                 'will recreate
        END IF
    END PROPERTY


    '***********************************************
    CONSTRUCTOR
        Visible = True
        Handle = 0
        Parent = 0
        Left = 0
        Top = 0
        Width = 100
        Height = 18
        Min = 0
        Max = 100
        Color = RGB(128 , 128 , 128) 'grey
        BackColor = 0
        Kind = PBS_OLD
        Interval = 40       '40 msec update
        Increment = 1
        State = 0       'normal
    END CONSTRUCTOR

    END WITH
END TYPE

$ENDIF
