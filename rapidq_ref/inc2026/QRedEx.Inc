'
' --------------------------------------------------------------------
' QREDEX OBJECT               2002-2005                     By Jacques
'                                  2006                  By [W]arriant
'
' EXTENDS QRICHEDIT with  COPY, CUT, PASTE, DELETE, SELECT ALL, UNDO,
'        SEARCH,  REPLACE,  SAVEPOSITION,  RESTOREPOSITION,
'        SETMAXTEXTSIZE(Size), EXTENDSIZELIMIT, CHANGEFONT,
'        CHANGEFONTCOLOR, CHANGEBGCOLOR, TOPLINEINDEX, BOTTOLINEINDEX
'
' COMPONENT CODE
'
' V 0.0.3  2002 : major modification nearly a copy of Psyclops420 work.
'          See Yahoo RapidQ Group message #9414
' V 1.0.0  April 2005 added Search, Replace, SavePosition,
'          RestorePosition, ChangeFont, ChangeFontColor, ChangeBgColor,
'          SetMaxTextSize, ExtendSizeLimit
' V 1.1.0  June 2005 added TopLineIndex, BottomLineIndex
' V 1.2.0  June 2006 Added property Private OS_Version As Long
'          to use Sound or Beep if  Win9x < 5 or >= 5
' V 1.2.1  [W]arriant - July 2006: reconstructed find/replace code,
'          got "Replace up" working, some things corrected/optimized
'          All sounds and beep supressed, this nulls modifications
'          of V 1.2.0
' --------------------------------------------------------------------

Type QRDX_FINDTEXTEX
    charfrom As Long
    charto As Long
    text As Long
    foundfrom As Long
    foundto As Long
End Type

Type QRDX_TCHOOSECOLOR
    lStructSize As Long
    hwndOwner As Long
    hInstance As Long
    rgbResult As Long
    lpCustColors As Long
    flags As Long
    lCustData As Long
    lpfnHook As Long
    lpTemplateName As Long
End Type

Declare Function QRDX_SendMessage Lib "user32" Alias "SendMessageA" (hwnd As Long, wMsg As Long, wParam As Long, lParam As Long) As Long
Declare Function QRDX_SetWindowLong LIB "user32" ALIAS "SetWindowLongA" (hWnd AS Long, nIndex AS Long, dwNewLong AS Long) AS Long
Declare Function QRDX_GetWindowLong Lib "user32" Alias "GetWindowLongA" (hwnd As Long, nIndex As Long) As Long
Declare Function QRDX_SetFocus Lib "user32" Alias "SetFocus" (hwnd As Long) As Long

Declare Function QRDX_LockWindowUpdate Lib "user32" Alias "LockWindowUpdate" (hwndLock As Long) As Long
Declare Function QRDX_ChooseColor Lib "comdlg32.dll" Alias "ChooseColorA" (pChoosecolor As QRDX_TCHOOSECOLOR) As Long

' =============================================================================
' =============================================================================
Type QRedEx Extends QRichEdit
    With QRedEx
    PUBLIC:
        UsePopup AS LONG PROPERTY SET Set_Popup
        RichTextSizeLimit As Long
        SavedTopLeft As Long
        SavedBottomRight As Long
        SavedCaretPosition As Long
        ptPoint As String * 20          ' Buffer

    ' Search Form
        frmSearch As QForm
        edtSearchFor As QEdit
        lblSearchFor AS QLabel
        btnSearch As QButton
        chkSearchCaseS As QCheckBox
        chkSearchWholeWordsOnly As QCheckBox

    ' Replace Form
        frmReplace As QForm
        lblToBeReplaced AS QLabel
        edtToBeReplaced As QEdit
        lblReplacedBy AS QLabel
        edtReplacedBy As QEdit
        btnReplace As QButton
        btnFindNext As QButton
        btnReplaceAll As QButton
        chkReplaceCaseS As QCheckBox
        chkReplaceWholeWordsOnly As QCheckBox
        chkReplaceUp As QCheckBox

    PRIVATE:
        tColor As QRDX_TCHOOSECOLOR
        RgbInit (1 To 16) As Long
        fntRichEdit As QFont
        dlgFont As QFontDialog
        tFindS As QRDX_FINDTEXTEX     ' For Search
        tFindR As QRDX_FINDTEXTEX     ' For Replace
        iReturn As Long
        QRED_PopUpMenu As QPopUpMenu
        mnuUndo As QMenuItem
        mnuSep_1 As QMenuItem
        mnuCut AS QMenuItem
        mnuCopy AS QMenuItem
        mnuPaste AS QMenuItem
        mnuDelete AS QMenuItem
        mnuSep_2 As QMenuItem
        mnuSelectAll As QMenuItem
        mnuSep_3 As QMenuItem
        mnuSearch As QMenuItem
        mnuReplace As QMenuItem
        iOldWndProc As Long

'       ON POP UP
'       ---------
        Event QRED_PopUpMenu.OnPopUp
            .mnuCut.Enabled = .sellength <> 0
            .mnuPaste.Enabled = len(clipboard.text) <> 0
            .mnuDelete.Enabled = .sellength <> 0
            .mnuCopy.Enabled = .sellength <> 0
            .mnuSelectAll.Enabled = len(.seltext) <> len(.text)
            .mnuUndo.Enabled = QRDX_SendMessage(.Handle, &HC6, 0, 0)

            If .ReadOnly Then
                .mnuCut.Visible = 0      ' False
                .mnuPaste.Visible = 0
                .mnuDelete.Visible = 0
                .mnuUndo.Visible = 0
                .mnuReplace.Visible = 0
            Else
                .mnuCut.Visible = 1      ' True
                .mnuPaste.Visible = 1
                .mnuDelete.Visible = 1
                .mnuUndo.Visible = 1
                .mnuReplace.Visible = 1
            End If
        End Event

'       mnu UNDO
'       --------
        SUB OnClic_mnuUndo
            QRDX_SendMessage(.Handle, &HC7, 0, 0)
        END SUB

'       mnu CUT
'       -------
        Sub OnClic_mnuCut
            .CutToClipBoard
        End Sub

'       mnu PASTE
'       ---------
        Sub OnClic_mnuPaste
            .PasteFromClipBoard
        End Sub

'       mnu COPY
'       --------
        Sub OnClic_mnuCopy
            .CopyToClipBoard
        End Sub

'       mnu DELETE
'       ----------
        Sub OnClic_mnuDelete
            QRDX_SendMessage (.Handle, &H100, &H2E, 0)
        End Sub

'       mnu SELECTALL
'       -------------
        Sub OnClic_mnuSelectAll
             .SelectAll
        End Sub

'       mnu SEARCH
'       ----------
        Sub OnClic_mnuSearch
            if len(.seltext) <> "" then .edtsearchfor.text = .seltext
            .frmSearch.Show
            QRDX_SetFocus (.edtSearchFor.Handle)
        End Sub

'       mnu REPLACE
'       -----------
        Sub OnClic_mnuReplace
             if len(.seltext) <> "" then .edttobereplaced.text = .seltext
             .frmReplace.Show
             QRDX_SetFocus (.edtToBeReplaced.Handle)
        End Sub

'       PROPERTY  UsePopUp
'       ------------------
        PUBLIC:
        PROPERTY SET Set_Popup(Use as long)
            .QRED_PopUpMenu.AutoPopup = Use
        END PROPERTY

'       Extend Size Limit
'       -----------------
        Sub ExtendSizeLimit
            QRDX_SendMessage (.handle, &HC5, .RichTextSizeLimit, 0)
        End Sub

        Sub SetMaxTextSize (iTextSizeMax As Long)
            QRDX_SendMessage (.handle, &HC5, iTextSizeMax, 0)
        End Sub

'       Save/Restore Screen Scroll Position
'       -----------------------------------
        Sub SavePosition
            SendMessage (.handle, 178, 0, Varptr(QRedEx.ptPoint))                               ' 178 EM_GETRECT
            .SavedTopLeft = QRDX_SendMessage (.handle, 215, 0, Varptr(QRedEx.ptPoint))          ' 215 EM_CHARFROMPOS
            .SavedBottomRight = QRDX_SendMessage (.handle, 215, 0, Varptr(QRedEx.ptPoint) + 2)  ' 215 EM_CHARFROMPOS
            .SavedCaretPosition = .SelStart
            If .SavedCaretPosition < .SavedTopLeft or .SavedCaretPosition > .SavedBottomRight Then _
                 .SavedCaretPosition = (.SavedBottomRight + .SavedTopLeft)/2
        End Sub

        Sub RestorePosition
            QRDX_SetFocus (.Handle)
            .SelStart = Len(.Text)
            .SelStart = .SavedTopLeft
            .SelStart = .SavedCaretPosition
        End Sub

'       Get Index of Top Screen Line
'       ----------------------------
        Function TopLineIndex () As Long
            SendMessage (.handle, 178, 0, Varptr(this.ptPoint))                                                     ' 178 EM_GETRECT
            Result = QRDX_SendMessage (.handle, 201, QRDX_SendMessage (.handle, 215, 0, Varptr(this.ptPoint)), 0)   ' 201 EM_LINEFROMCHAR, 215 EM_CHARFROMPOS
        End Function

'       Get Index of Bottom Screen Line
'       -------------------------------
        Function BottomLineIndex () As Long
            SendMessage (.handle, 178, 0, Varptr(this.ptPoint))                                                        ' 178 EM_GETRECT
            Result = QRDX_SendMessage (.handle, 201, QRDX_SendMessage (.handle, 215, 0, varptr(this.ptPoint) + 2), 0)  ' 201 EM_LINEFROMCHAR, 215 EM_CHARFROMPOS
        End Function

'       CHANGE FONT
'       -----------
        Sub ChangeFont
            .fntRichEdit.Name =  .font.Name
            .fntRichEdit.Size =  .font.Size
            .fntRichEdit.Color = .font.Color
            .dlgFont.GetFont(QRedEx.fntRichEdit)
            If .dlgFont.Execute Then
                .dlgFont.SetFont(QRedEx.fntRichEdit)
                .font = QRedEx.fntRichEdit
            End If
        End sub

'       CHANGE FONT COLOR
'       -----------------
        Sub ChangeFontColor
           .tColor.lStructSize = 36
           .tColor.hwndOwner = Application.Handle
           .tColor.hInstance = 0
           .tColor.rgbResult = QRedEx.Font.Color
           .tColor.lpCustColors = VarPtr(QRedEx.RgbInit(1))
           .tColor.flags = 131        ' CC_FULLOPEN = 2 ; CC_RGBINIT = 1 ; CC_SOLIDCOLOR = 128 ; CC_ANYCOLOR = 256 = &H100
           .tColor.lCustData = 0      ' ignored
           .tColor.lpfnHook = 0       ' ignored
           .tColor.lpTemplateName = 0 ' ignored
           If QRDX_ChooseColor (.tColor) <> 0 Then .Font.Color = .tColor.rgbResult
        End sub

'       CHANGE BGCOLOR
'       --------------
        Sub ChangeBgColor
           .tColor.lStructSize = 36
           .tColor.hwndOwner = Application.Handle
           .tColor.hInstance = 0
           .tColor.rgbResult = QRedEx.Color
           .tColor.lpCustColors = VarPtr(QRedEx.RgbInit(1))
           .tColor.flags = 131        ' CC_FULLOPEN = 2; CC_RGBINIT = 1; CC_SOLIDCOLOR = 128; CC_ANYCOLOR = 256 = &H100

           .tColor.lCustData = 0      ' ignored
           .tColor.lpfnHook = 0       ' ignored
           .tColor.lpTemplateName = 0 ' ignored
           If QRDX_ChooseColor (.tColor) <> 0 Then .Color = .tColor.rgbResult
        End sub

    PRIVATE:
'       Search
'       ------
        Sub OnClic_btnSearch
            defstr findstring = .edtSearchFor.Text
            if findstring = "" then goto searchnextend

            .tfinds.text     = varptr(findstring)
            .tfinds.charfrom = .selstart + .sellength
            .tfinds.charto   = len(.text)

            if qrdx_sendmessage(.handle, 1103, (.chkSearchCaseS.Checked * 4) or (.chkSearchWholeWordsOnly.Checked * 2), .tfinds) <> -1 then
                  .selstart  = .tfinds.foundfrom
                  .sellength = .tfinds.foundto - .tfinds.foundfrom
            else
                  showmessage "No matches found."
            end if

            searchnextend:
        End Sub

'       Find Next (for Replace)
'       ---------
        Sub OnClic_btnFindNext
            defstr findstring = .edtToBeReplaced.Text
            deflng upfrom, upto
            if findstring = "" then goto findnextend

            .tfindr.text = varptr(findstring)
            if .chkreplaceup.checked then
                  .tfindr.charfrom = 0
                  .tfindr.charto   = .selstart

                  if qrdx_sendmessage(.handle, 1103, (.chkReplaceCaseS.Checked * 4) or (.chkReplaceWholeWordsOnly.Checked * 2), .tfindr) = -1 then
                        showmessage "No matches found."
                        goto findnextend
                  end if

                  do
                        .tfindr.charfrom = .tfindr.foundto
                        upfrom = .tfindr.foundfrom
                        upto   = .tfindr.foundto
                  loop until qrdx_sendmessage(.handle, 1103, (.chkReplaceCaseS.Checked * 4) or (.chkReplaceWholeWordsOnly.Checked * 2), .tfindr) = -1

                  .selstart  = upfrom
                  .sellength = upto - upfrom
            else
                  .tfindr.charfrom = .selstart + .sellength
                  .tfindr.charto   = len(.text)

                  if qrdx_sendmessage(.handle, 1103, (.chkReplaceCaseS.Checked * 4) or (.chkReplaceWholeWordsOnly.Checked * 2), .tfindr) <> -1 then
                        .selstart  = .tfindr.foundfrom
                        .sellength = .tfindr.foundto - .tfindr.foundfrom
                  else
                        showmessage "No matches found."
                  end if
            end if

            findnextend:
        End Sub

'       Replace
'       -------
        Sub OnClic_btnReplace
            if iif(.chkReplaceCaseS.Checked, .seltext = .edtToBeReplaced.Text, lcase$(.seltext) = lcase$(.edtToBeReplaced.Text)) then .seltext = .edtReplacedBy.Text
            .onclic_btnfindnext
        End Sub

'       Replace All
'       -----------
        Sub OnClic_btnReplaceAll
            defstr findstring = .edtToBeReplaced.Text
            if findstring = "" then goto findreplaceallend

            .tfindr.text     = varptr(findstring)
            .tfindr.charfrom = 0
            .tfindr.charto   = len(.text)

            if qrdx_sendmessage(.handle, 1103, (.chkReplaceCaseS.Checked * 4) or (.chkReplaceWholeWordsOnly.Checked * 2), .tfindr) = -1 then
                  showmessage "No matches found"
                  goto findreplaceallend
            end if

            .SavePosition
            QRDX_LockWinDowUpdate (QRedEx.Handle)

            do
                  .selstart  = .tfindr.foundfrom
                  .sellength = .tfindr.foundto - .tfindr.foundfrom
                  .seltext   = .edtReplacedBy.Text
                  .tfindr.charfrom = .tfindr.foundfrom + len(.edtReplacedBy.Text)
            loop until qrdx_sendmessage(.handle, 1103, (.chkReplaceCaseS.Checked * 4) or (.chkReplaceWholeWordsOnly.Checked * 2), .tfindr) = -1

            .selstart = 0

            QRDX_LockWindowUpdate ()
            .RestorePosition

            findreplaceallend:
        End Sub

'       On Keypress EditBoxes
'       ---------------------
        Sub OnKeyPress_edtSearchFor (key As Byte)
            If Key = 13 Then .OnClic_btnSearch
        End Sub

        Sub OnKeyPress_edtToBeReplaced (key As Byte)
            If (Key = 13 or Key = 9) Then QRDX_SetFocus (.edtReplacedBy.handle)
        End Sub

        Sub OnKeyPress_edtReplacedBy (key As Byte)
            If (Key = 13) Then .OnClic_btnFindNext
        End Sub


        CONSTRUCTOR
            WantTabs = 1
            RichTextSizeLimit = 1048576
            PopUpMenu = QRedEx.QRED_PopUpMenu
            mnuUnDo.Caption = "&Undo"
            mnuUndo.OnClick = QRedEx.OnClic_mnuUndo
            mnuSep_1.Caption = "-"
            mnuCut.Caption = "Cu&t"
            mnuCut.OnClick = QRedEx.OnClic_mnuCut
            mnuCopy.Caption = "&Copy"
            mnuCopy.OnClick = QRedEx.OnClic_mnuCopy
            mnuPaste.Caption = "&Paste"
            mnuPaste.OnClick = QRedEx.OnClic_mnuPaste
            mnuDelete.Caption = "&Delete"
            mnuDelete.OnClick = QRedEx.OnClic_mnuDelete
            mnuSep_2.Caption = "-"
            mnuSelectAll.Caption = "Select &All"
            mnuSelectAll.OnClick = QRedEx.OnClic_mnuSelectAll
            mnuSep_3.Caption = "-"
            mnuSearch.Caption = "&Search"
            mnuSearch.OnClick =  QRedEx.OnClic_mnuSearch
            mnuReplace.Caption = "&Replace"
            mnuReplace.OnClick =  QRedEx.OnClic_mnuReplace
            QRED_PopUpMenu.AddItems QRedEx.mnuUndo,QRedEx.mnuSep_1, _
                        QRedEx.mnuCopy, QRedEx.mnuCut, QRedEx.mnuPaste, _
                        QRedEx.mnuDelete, QRedEx.mnuSep_2, QRedEx.mnuSelectAll, _
                        QRedEx.mnuSep_3, QRedEx.mnuSearch, QRedEx.mnuReplace

'     ColorDialog PreSelected Colors
            RgbInit (1)=&H0
            RgbInit (2)=&H808080

            RgbInit (3)=&H000080
            RgbInit (4)=&H008080
            RgbInit (5)=&H008000
            RgbInit (6)=&H808000
            RgbInit (7)=&H800000
            RgbInit (8)=&H800080

            RgbInit (9)=&HFFFFFF
            RgbInit(10)=&HC0C0C0
            RgbInit(11)=&H0000FF
            RgbInit(12)=&H00FFFF
            RgbInit(13)=&H00FF00
            RgbInit(14)=&HFFFF00

            RgbInit(15)=&HFF0000
            RgbInit(16)=&HFF00FF

'    FORM SEARCH
'    -----------
            frmSearch.Center
            frmSearch.BorderStyle = 3 ' bsNone
            frmSearch.Caption = "Search in text"
            frmsearch.Width = 400
            frmSearch.Height = 125
            frmSearch.Visible = 0

            lblSearchFor.Parent = QRedEx.frmSearch
            lblSearchFor.Top  = 5
            lblSearchFor.Left = 5
            lblSearchFor.Caption = "Text to search for:"

            edtSearchFor.Parent = QRedEx.frmSearch
            edtSearchFor.Top = 30
            edtSearchFor.Left = 5
            edtSearchFor.Width = QRedEx.frmSearch.ClientWidth - 10
            edtSearchFor.Height = 20
            edtSearchFor.OnKeyPress = QRedEx.OnKeyPress_edtSearchFor

            btnSearch.Parent = QRedEx.frmSearch
            btnSearch.Top = 65
            btnSearch.Left = 5
            btnSearch.Width = 125 'QRedEx.frmSearch.ClientWidth - 10
            btnSearch.Height = 25
            btnSearch.Caption = "&Find Next"
            btnSearch.OnClick = QRedEx.OnClic_btnSearch

            chkSearchCaseS.Parent = QRedEx.frmSearch
            chkSearchCaseS.Top = 65
            chkSearchCaseS.Left = 150
            chkSearchCaseS.Width = 110
            chkSearchCaseS.Height = 25
            chkSearchCaseS.Caption = "Match case"

            chkSearchWholeWordsOnly.Parent = QRedEx.frmSearch
            chkSearchWholeWordsOnly.Top = 65
            chkSearchWholeWordsOnly.Left = 280
            chkSearchWholeWordsOnly.Width = 110
            chkSearchWholeWordsOnly.Height = 25
            chkSearchWholeWordsOnly.Caption = "Full word"

'    FORM REPLACE
'    ------------
            frmReplace.Center
            frmReplace.BorderStyle = 3 ' bsNone
            frmReplace.Caption = "Replace in text"
            frmReplace.Width = 400
            frmReplace.Height = 210
            frmReplace.Visible = 0

            lblToBeReplaced.Parent = QRedEx.frmReplace
            lblToBeReplaced.Top  = 5
            lblToBeReplaced.Left = 5
            lblToBeReplaced.Caption = "Text to be replaced:"

            edtToBeReplaced.Parent = QRedEx.frmReplace
            edtToBeReplaced.Top = 30
            edtToBeReplaced.Left = 5
            edtToBeReplaced.Width = QRedEx.frmReplace.ClientWidth - 10
            edtToBeReplaced.Height = 20
            edtToBeReplaced.OnKeyPress = QRedEx.OnKeyPress_edtToBeReplaced

            lblReplacedBy.Parent = QRedEx.frmReplace
            lblReplacedBy.Top  = 65
            lblReplacedBy.Left = 5
            lblReplacedBy.Caption = "Replacement text:"

            edtReplacedBy.Parent = QRedEx.frmReplace
            edtReplacedBy.Top = 95
            edtReplacedBy.Left = 5
            edtReplacedBy.Width = QRedEx.frmReplace.ClientWidth - 10
            edtReplacedBy.Height = 20
            edtReplacedBy.OnKeyPress = QRedEx.OnKeyPress_edtReplacedBy

            btnFindNext.Parent = QRedEx.frmReplace
            btnFindNext.Top = 130
            btnFindNext.Left = 5
            btnFindNext.Width = (QRedEx.frmReplace.ClientWidth - 20)/3
            btnFindNext.Height = 25
            btnFindNext.Caption = "&Find next"
            btnFindNext.OnClick = QRedEx.OnClic_btnFindNext

            btnReplace.Parent = QRedEx.frmReplace
            btnReplace.Top = 130
            btnReplace.Left = 10 + (QRedEx.frmReplace.ClientWidth - 20)/3
            btnReplace.Width = (QRedEx.frmReplace.ClientWidth - 20)/3
            btnReplace.Height = 25
            btnReplace.Caption = "&Replace"
            btnReplace.OnClick = QRedEx.OnClic_btnReplace

            btnReplaceAll.Parent = QRedEx.frmReplace
            btnReplaceAll.Top = 130
            btnReplaceAll.Left = 15 + 2 * (QRedEx.frmReplace.ClientWidth - 20)/3
            btnReplaceAll.Width = (QRedEx.frmReplace.ClientWidth - 20)/3
            btnReplaceAll.Height = 25
            btnReplaceAll.Caption = "Replace &All"
            btnReplaceAll.OnClick = QRedEx.OnClic_btnReplaceAll

            chkReplaceCaseS.Parent = QRedEx.frmReplace
            chkReplaceCaseS.Top = 155
            chkReplaceCaseS.Left = 5
            chkReplaceCaseS.Width = (QRedEx.frmReplace.ClientWidth - 20)/3
            chkReplaceCaseS.Height = 25
            chkReplaceCaseS.Caption = "Match case"

            chkReplaceWholeWordsOnly.Parent = QRedEx.frmReplace
            chkReplaceWholeWordsOnly.Top = 155
            chkReplaceWholeWordsOnly.Left = 10 + (QRedEx.frmReplace.ClientWidth - 20)/3
            chkReplaceWholeWordsOnly.Width = 30 + (QRedEx.frmReplace.ClientWidth - 20)/3
            chkReplaceWholeWordsOnly.Height = 25
            chkReplaceWholeWordsOnly.Caption = "Full word"

            chkReplaceUp.Parent = QRedEx.frmReplace
            chkReplaceUp.Top = 155
            chkReplaceUp.Left = 15 + 2 * (QRedEx.frmReplace.ClientWidth - 20)/3
            chkReplaceUp.Width = (QRedEx.frmReplace.ClientWidth - 20)/3
            chkReplaceUp.Height = 25
            chkReplaceUp.Caption = "Replace up"
        END CONSTRUCTOR
    End With
End Type

' =============================================================================
' =============================================================================

$UNDEF QRICHEDIT
$DEFINE QRICHEDIT QREDEX
