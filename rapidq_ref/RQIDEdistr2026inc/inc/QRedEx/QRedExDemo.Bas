'
' --------------------------------------------------------------------
' QREDEX OBJECT        January 2002-2005           By Jacques Philippe
'
' EXTENDS QRICHEDIT with  COPY, CUT, PASTE, DELETE, SELECT ALL, UNDO,
'        SEARCH,  REPLACE,  SAVEPOSITION,  RESTOREPOSITION,
'        SETMAXTEXTSIZE(Size), EXTENDSIZELIMIT, CHANGEFONT,
'        CHANGEFONTCOLOR, CHANGEBGCOLOR
'
' RAPIDQ DEMONSTRATION CODE
'
' V 0.0.3  2002 : major modification nearly a copy of Psyclops420 work.
'          See Yahoo RapidQ Group message #9414
' V 1.0.0  April, 2005 Added Search, Replace, SavePosition,
'          RestorePosition, ChangeFont, ChangeFontColor, ChangeBgColor,
'          SetMaxTextSize, ExtendSizeLimit
' --------------------------------------------------------------------
'
' frmDemoQRedEx    Gui Application
'
$Include "QRedEx.Inc"
'
$INCLUDE "RAPIDQ.INC"
$ESCAPECHARS ON
$TYPECHECK ON
'
Declare Sub OnClose_frmDemoQRedEx
Declare Sub OnClic_AnyMenu (Sender As QMenuItem)
'
Create frmDemoQRedEx As QForm
    Center
    Width = 1000
    height = 800
    Caption = "frmDemoQRedEx" 
    Font.Size = 12
    AutoScroll = False
    OnClose = OnClose_frmDemoQRedEx
    Create rchWin AS QRichEdit
        Align = 5
        Font.Name = "Courier"
        Font.Size = 12
        Color = &HFDFCF0
        Font.Color = &H800000
        ReadOnly = False
        WordWrap = False
        ScrollBars = ssBoth
        HideSelection = False
        PlainText = True
        ExtendSizeLimit
    End Create
    Create mnuMain AS QMAINMENU
        Create mnuChangeFontAndColor AS QMENUITEM
            Caption = "&FONT and COLORS    "        
            Create mnuChangeFont AS QMENUITEM
                Caption = "&CHANGE FONT    "
                OnClick = OnClic_AnyMenu
            End Create
            Create mnuChangeFontColor AS QMENUITEM
                Caption = "&CHANGE FONT COLOR    "
                OnClick = OnClic_AnyMenu
            End Create
            Create mnuChangeBgColor AS QMENUITEM
                Caption = "&CHANGE BG_COLOR    "
                OnClick = OnClic_AnyMenu
            End Create
        End Create
        Create mnuScrollPosition As QMenuItem
            Caption = "&SCROLL_POSITION     "
            Create mnuSavePosition As QMENUITEM
                Caption = "SAVE POSITION"
                OnClick = OnClic_AnyMenu
            End Create
            Create mnuRestorePosition AS QMENUITEM
                Caption = "RESTORE POSITION"
                OnClick = OnClic_AnyMenu
            End Create
            Create mnuGetTopBottomLinesIndex AS QMENUITEM
                Caption = "GET TOP and BOTTOM SCREEN LINE INDEX"
                OnClick = OnClic_AnyMenu
            End Create
        End create
    End Create
End Create
'
' --------------------------------------------------------------------
' API Call to have RapidQ programs minimized in the task bar
DECLARE FUNCTION SetWindowLong LIB "user32" ALIAS "SetWindowLongA" (hWnd AS LONG, _
                                               nIndex AS LONG, dwNewLong AS LONG) AS LONG
'      ----- API Constants and Functions
CONST GWL_HWNDPARENT = (-8)                   'Minimize to task bar
CONST HWND_DESKTOP = 0
setwindowlong(frmDemoQRedEx.handle, GWL_HWNDPARENT, HWND_DESKTOP)
setwindowlong(application.handle, GWL_HWNDPARENT, frmDemoQRedEx.handle)
' --------------------------------------------------------------------
'
' *************************************
frmDemoQRedEx.Show
' *************************************
'
rchWin.LoadFromFile ("QRedEx.Inc")
'
' *************************************
frmDemoQRedEx.Visible = False
frmDemoQRedEx.ShowModal
' *************************************
'
Sub OnClose_frmDemoQRedEx
    Application.Terminate
    End
End Sub
'
Sub OnClic_AnyMenu (Sender)
 With rchWin
    Select Case Sender.Handle
        Case mnuSavePosition.Handle
            .SavePosition
        Case mnuRestorePosition.Handle
            .RestorePosition
        Case mnuChangeFont.Handle
            .ChangeFont
        Case mnuChangeBgColor.Handle
            .ChangeBgcolor
        Case mnuChangeFontColor.Handle
            .ChangeFontcolor
        Case mnuGetTopBottomLinesIndex.Handle
            ShowMessage ("   TOP VISIBLE LINE INDEX = " & Str$(.TopLineIndex) _
                   & "\n\nBOTTOM VISIBLE LINE INDEX = " & Str$(.BottomLineIndex))
        End Select
  End With
End Sub
'
