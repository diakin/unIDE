'Uploaded by : psyclops420 <psyclops420@yahoo.com>  
'Description : New QEDIT component, two new events, OnGetFocus and OnLoseFocus, plus implemented WndProc  

' v1.0: 
' Fixed WndProc (actually, wrote it from scratch ·) 
' Two new events, OnGetFocus and OnLoseFocus 
' When using the new events, you MUST use the Sender parameter 
' Custom events MUST have at least one paramater, haven't found 
' a way aroud this yet 

' v1.1: 
' Fixed a little bug in WndProc(check for assignment) 
' Added Property EnterKey 

'DECLARE FUNCTION CallWindowProc LIB "User32" ALIAS "CallWindowProcA"(lpPrevWndFunc AS LONG, hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
DECLARE FUNCTION SetWindowLong LIB "User32" ALIAS "SetWindowLongA"(hWnd AS LONG, nIndex AS LONG, dwNewLong AS LONG) AS LONG
DECLARE FUNCTION GetParent LIB "User32" ALIAS "GetParent" (hWnd AS LONG) AS LONG

CONST ekNormal = 0
CONST ekTab = 1

DECLARE SUB OnGetFocus_EventTemplate(Sender AS QEDIT)
DECLARE SUB OnLoseFocus_EventTemplate(Sender AS QEDIT)
DECLARE SUB WndProc_EventTemplate(hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG)

TYPE QxEDIT EXTENDS QEDIT
    Tmr AS QTIMER
    OldWndProc AS LONG
    EnterKey AS LONG PROPERTY SET Set_EnterKey
    OnGetFocus AS EVENT(OnGetFocus_EventTemplate)
    OnLoseFocus AS EVENT(OnLoseFocus_EventTemplate)
    WndProc AS EVENT(WndProc_EventTemplate)
    
    WITH This
        
        PROPERTY SET Set_EnterKey(NewEnterKey AS LONG)
            .EnterKey = NewEnterKey
        END PROPERTY SET
        
        FUNCTION Proc(hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
            IF hWnd = .Handle THEN
                Result = CallWindowProc(.OldWndProc, hWnd, uMsg, wParam, lParam) 
                IF uMsg = &H7 THEN
                    CALLFUNC(.OnGetFocus, This)
                ELSEIF uMsg = &H8 THEN
                    CALLFUNC(.OnLoseFocus, This)
                ELSEIF uMsg = &H100  AND wParam = &HD AND .EnterKey THEN
                    KillMessage(GetParent(.Handle), &H102)
                    SendMessage(GetParent(.Handle), &H28, 0, 0)
                END IF
                IF .WndProc>0 THEN CALLFUNC(.WndProc, hWnd, uMsg, wParam, lParam)
            END IF
        END FUNCTION
        
        EVENT Tmr.OnTimer
                .OldWndProc = SetWindowLong(This.Handle, -4, CODEPTR(This.Proc))
                .Tmr.Enabled = 0
        END EVENT
    
        CONSTRUCTOR
            Tmr.Interval = 1
        END CONSTRUCTOR
    
    END WITH

END TYPE

$UNDEF QEDIT
$DEFINE QEDIT QxEDIT
 

