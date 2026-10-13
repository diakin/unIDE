'================= QMAXSPLITTER ==================
'
' This one's a doozy. A splitter control that 
' emulates all of Delphi 6's splitter styles.
' It's based on a QPanel rather than QCanvas
' like the original for two reasons:

' 1. To get a handle
' 2. To improve drawing and aligning

' There are still some issues with this
' component, and they are:

' 1. Mouse trapping - if you move the mouse too
' fast, you leave the splitter behind. SetCapture
' doesn't seem to solve the problem, maybe sub-
' classing in the next version...

' 2. Setting MinSize to 0 sometimes causes
' resizing problems, I'm sure this is an oversight
' in the math, but I can live with it for now.

' 3. There are stil problems with CREATE, most 
' notably the order in which ALIGNed components
' are created, as well as the order in which 
' properties are assigned to sibling windows
' (Uncomment the "Color" in Rich3 and run. See
' what I mean? Now place the code for Rich3 AFTER
' the code for Split3. Problem solved!)
' Anyway, I had fun with it, I hope you will too.
' Psyclops ·)
' P.S. Sorry for the lack of comments, maybe in the
' next release...



DIM Moving      AS LONG
DIM SplitPos    AS POINTAPI
DIM OldSplitPos AS POINTAPI
DIM OldWhere    AS POINTAPI
DIM Org         AS POINTAPI
DIM Rect1           AS QRECT
DEFWORD PatternPtn(7) = {&H00AA, &H0055, &H00AA, &H0055, &H00AA, &H0055, &H00AA, &H0055}
DEFWORD SolidPtn(7) = {&H00FF, &H00FF, &H00FF, &H00FF, &H00FF, &H00FF, &H00FF, &H00FF}

const PATINVERT = &H5A0049
const rsNone    = 0
const rsSolid   = 1
const rsPattern = 2
const rsUpdate  = 3
$IFNDEF __WIN32API				   'windows 32 definitions
    TYPE POINTAPI
        X AS LONG
        Y AS LONG
    END TYPE
    
    Declare Function GetParent Lib "user32" Alias "GetParent" (ByVal hwnd As Long) As Long
    Declare Function ChildWindowFromPoint Lib "user32" ALIAS "ChildWindowFromPoint"(ByVal hWndParent As Long, ByVal X AS LONG, ByVal Y AS LONG) As Long
    Declare Function GetDC Lib "user32" Alias "GetDC" (ByVal hwnd As Long) As Long
    Declare Function CreateBitmap Lib "gdi32" ALIAS "CreateBitmap"(ByVal nWidth As Long, ByVal nHeight As Long, ByVal nPlanes As Long, ByVal nBitCount As Long, ByVal lpBits As LONG) As Long
    Declare Function CreatePatternBrush Lib "gdi32" ALIAS "CreatePatternBrush"(ByVal hBitmap As Long) As Long
    Declare Function SelectObject Lib "gdi32" Alias "SelectObject" (ByVal hdc As Long, ByVal hObject As Long) As Long
    Declare Function SetBrushOrgEx Lib "gdi32" ALIAS "SetBrushOrgEx"(ByVal hdc As Long, ByVal nXOrg As Long, ByVal nYOrg As Long, lppt As POINTAPI) As Long
    Declare Function ClientToScreen Lib "user32" Alias "ClientToScreen" (ByVal hwnd As Long, lpPoint As POINTAPI) As Long
    Declare Function PatBlt Lib "gdi32" Alias "PatBlt" (ByVal hdc As Long, ByVal x As Long, ByVal y As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal dwRop As Long) As Long
    Declare Function DeleteObject Lib "gdi32" Alias "DeleteObject" (ByVal hObject As Long) As Long
    Declare Function ReleaseDC Lib "user32" Alias "ReleaseDC" (ByVal hwnd As Long, ByVal hdc As Long) As Long
    Declare Function GetCursorPos Lib "user32" ALIAS "GetCursorPos"(lpPoint As POINTAPI) As Long
    Declare Function GetClientRect Lib "user32" Alias "GetClientRect" (ByVal hwnd As Long, lpRect As QRECT) As Long
    Declare Function ScreenToClient Lib "user32" ALIAS "ScreenToClient"(ByVal hwnd As Long, lpPoint As POINTAPI) As Long
    Declare Function OffsetRect Lib "user32" Alias "OffsetRect" (lpRect As QRECT, ByVal x As Long, ByVal y As Long) As Long
    Declare Function MoveWindow Lib "user32" Alias "MoveWindow" (ByVal hwnd As Long, ByVal x As Long, ByVal y As Long, ByVal nWidth As Long, ByVal nHeight As Long, ByVal bRepaint As Long) As Long
$ENDIF

TYPE QMAXSPLITTER EXTENDS QPANEL

    WITH QMAXSPLITTER
    
        Owner      AS LONG
        Tmr        AS QTIMER
        MinSize    AS LONG
        Beveled    AS LONG PROPERTY SET Set_Beveled
        Mover      AS LONG
        MoverRect  AS QRECT
        Style      AS LONG PROPERTY SET Set_Style
        Pattern(7) AS WORD
        Canvas     AS QCANVAS
        
        PROPERTY SET Set_Beveled(Bevel AS LONG)
            .Beveled = Bevel
            .Canvas.Visible = Bevel
            .Canvas.Repaint
        END PROPERTY        
        
        PROPERTY SET Set_Style(NewStyle AS LONG)
            DIM X AS LONG
            FOR X = 0 TO 7
                SELECT CASE NewStyle
                    CASE 0, 3
                        .Pattern(X) = 0
                    CASE 1
                        .Pattern(X) = SolidPtn(X)
                    CASE 2
                        .Pattern(X) = PatternPtn(X)
                END SELECT' CASE
            NEXT X   
            .Style = NewStyle
        END PROPERTY
        
        EVENT Tmr.OnTimer
            IF .Visible THEN
                .Owner = GetParent(.Handle)
                .Tmr.Enabled = 0
                Org.X = .Left
                Org.Y = .Top
                IF .Align = 1 THEN
                    DEC(Org.Y)
                ELSEIF .Align = 2 THEN
                    INC(Org.Y, .Height)
                ELSEIF .Align = 3 THEN
                    DEC(Org.X)
                ELSEIF .Align = 4 THEN
                    INC(Org.X, .Width)
                END IF
                .Mover = ChildWindowFromPoint(.Owner, Org.X, Org.Y)               
            END IF
        END EVENT
        
        EVENT Canvas.OnPaint
            SELECT CASE .Align
                CASE 1, 2
                    .Canvas.Line(0, 0, .Width, 0, &H808080)
                    .Canvas.Line(0, 1, .Width, 1, &HC8D0D8)
                    .Canvas.Line(0, 2, .Width, 2, &HFFFFFF)
                    .Canvas.Line(0, .Height-3, .Width, .Height-3, &H808080)
                    .Canvas.Line(0, .Height-2, .Width, .Height-2, &HC8D0D8)
                    .Canvas.Line(0, .Height-1, .Width, .Height-1, &HFFFFFF)                    
                CASE ELSE
                    .Canvas.Line(0, 0, 0, .Height, &H808080)
                    .Canvas.Line(1, 0, 1, .Height, &HC8D0D8)
                    .Canvas.Line(2, 0, 2, .Height, &HFFFFFF)
                    .Canvas.Line(.Width-3, 0, .Width-3, .Height, &H808080)
                    .Canvas.Line(.Width-2, 0, .Width-2, .Height, &HC8D0D8)
                    .Canvas.Line(.Width-1, 0, .Width-1, .Height, &HFFFFFF)
            END SELECT
        END EVENT
        
        SUB MoveChild(Where AS POINTAPI)
            ScreenToClient(.Mover, Where)
            GetClientRect(.Mover, This.MoverRect)
            OffsetRect(This.MoverRect, 1, 1)
            IF Where = OldWhere THEN EXIT SUB
            DIM Redraw AS LONG
            SELECT CASE .Align
                CASE 1
                    MoveWindow(.Mover, 0, 0, 0, .MoverRect.Top+Where.Y-1, 0)
                CASE 2
                    MoveWindow(.Mover, 0, Rect1.Bottom-(Where.Y+.Height), 0, .MoverRect.Bottom-(Where.Y+.Height)+1, 0)
                CASE 3
                    MoveWindow(.Mover, 0, 0, .MoverRect.Left+Where.X+1, 0, 0)
                CASE 4
                    MoveWindow(.Mover, Rect1.Right-(Where.X+.Width), 0, .MoverRect.Right-(Where.X+.Width)+1, 0, 0)
            END SELECT
            SendMessage(.Owner, &H5, 0, 0)
            DoEvents
            OldWhere = Where
        END SUB
        
        SUB DrawSplitter(Split AS POINTAPI)
            DIM hDC AS LONG
            DIM hBM AS LONG
            DIM hBr AS LONG
            DIM hOldBr AS LONG
            
            hDC = GetDC(0)
            hBm = CreateBitmap(8, 8, 1, 1, VARPTR(This.Pattern(0)))
            hBr = CreatePatternBrush(hBm)
            hOldBr = SelectObject(hDC, hBr)
            SetBrushOrgEx(hDC, Split.X, Split.Y, 0)
            
            Org.X = 0
            Org.Y = 0
            ClientToScreen(.Handle, Org)
            IF .Align = 1 OR .Align = 2 THEN
                PatBlt(hDC, Org.X, Split.Y, .Width, .Height, PATINVERT)
            ELSEIF .Align = 3 OR .Align = 4 THEN
                PatBlt(hDC, Split.X, Org.Y, .Width, .Height, PATINVERT)
            END IF
            SelectObject(hDC, hOldBr)
            DeleteObject(hBr)
            DeleteObject(hBm)
            ReleaseDC(0, hDC)
        END SUB

        EVENT Canvas.OnMouseDown(Button AS LONG, X AS LONG, Y AS LONG)
            IF Button = 0 THEN
                Moving = 1
                SplitPos.X = 0
                SplitPos.Y = 0
                ClientToScreen(.Handle, SplitPos)
                .DrawSplitter(SplitPos)
                OldSplitPos = SplitPos
            END IF
        END EVENT
                
        EVENT Canvas.OnMouseMove(X AS LONG, Y AS LONG)
            DIM OwnerOrg AS POINTAPI
            IF Moving = 1 THEN
                GetCursorPos(SplitPos)
                
                GetClientRect(.Owner, Rect1) ' inc2026: Rect1 вместо R: глобальная QRECT названа Rect1 (строка 42), её Bottom/Right читаются в строках 158, 162, 216, 220; R нигде не объявлена; в inc/old/QSplitter.inc строка 204 и старой версии везде R
                OwnerOrg.X = 0
                OwnerOrg.Y = 0
                ClientToScreen(.Owner, OwnerOrg)
                IF .Align = 1 OR .Align = 2 THEN
                    IF SplitPos.Y < (OwnerOrg.Y+.MinSize) OR SplitPos.Y > (OwnerOrg.Y-.MinSize) + Rect1.Bottom _
                     OR SplitPos.Y < (OwnerOrg.Y+(.Height/2)) THEN EXIT EVENT
                    SplitPos.Y = SplitPos.Y-(.Height/2)
                ELSEIF .Align = 3 OR .Align = 4 THEN
                    IF SplitPos.X < (OwnerOrg.X+.MinSize) OR SplitPos.X > (OwnerOrg.X-.MinSize) + Rect1.Right _
                     OR SplitPos.X < (OwnerOrg.X+(.Width/2)) THEN EXIT EVENT
                    SplitPos.X = SplitPos.X-(.Width/2)
                ELSE
                    EXIT EVENT
                END IF
                
                .DrawSplitter(OldSplitPos)
                .DrawSplitter(SplitPos)
                OldSplitPos = SplitPos
                IF .Style = 3 THEN
                    .MoveChild(SplitPos)
                END IF
            END IF
        END EVENT

        EVENT Canvas.OnMouseUp
            IF Moving = 1 THEN
                Moving = 0
                .DrawSplitter(OldSplitPos)
                .MoveChild(OldSplitPos)
            END IF
        END EVENT

        constRUCTOR
            Set_Style(2)
            Set_Beveled(0)
            Width = 5
            Height = 5
            Align = 1
            Tmr.Interval = 1
            MinSize = 30
            Cursor = -15
            Canvas.Parent = This
            Canvas.Align = 5
            BevelOuter = 0
            OnMouseDown = This.Canvas.InheritOnMouseDown
            OnMouseMove = This.Canvas.InheritOnMouseMove
            OnMouseUp = This.Canvas.InheritOnMouseUp
        END constRUCTOR
        
    END WITH
END TYPE

  
