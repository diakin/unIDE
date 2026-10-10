'
' --------------------------------------------------------------------
' QREDEX OBJECT        January 2002-2005           By Jacques Philippe
'
' EXTENDS QRICHEDIT with  COPY, CUT, PASTE, DELETE, SELECT ALL, UNDO,
'        SEARCH,  REPLACE,  SAVEPOSITION,  RESTOREPOSITION,
'        SETMAXTEXTSIZE(Size), EXTENDSIZELIMIT, CHANGEFONT,
'        CHANGEFONTCOLOR, CHANGEBGCOLOR
'
' COMPONENT CODE
'
' V 0.0.3  2002 : major modification nearly a copy of Psyclops420 work.
'          See Yahoo RapidQ Group message #9414
' V 1.0.0  April, 2005 Added Search, Replace, SavePosition,
'          RestorePosition, ChangeFont, ChangeFontColor, ChangeBgColor
'          SetMaxTextSize, ExtendSizeLimit
' --------------------------------------------------------------------
Type QRDX_FINDTEXT
    cpMin     As Long
    cpMax     As Long
    ptrString As Long
End Type
'
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
'
Declare Function QRDX_SendMessage Lib "user32" Alias "SendMessageA" (hwnd As Long, _
                                        wMsg As Long, wParam As Long, lParam As Long) As Long
Declare Function QRDX_SetWindowLong LIB "user32" ALIAS "SetWindowLongA" (ByVal hWnd AS Long, _
                                            ByVal nIndex AS Long, ByVal dwNewLong AS Long) AS Long
Declare Function QRDX_GetWindowLong Lib "user32" Alias "GetWindowLongA" (ByVal hwnd As Long, _
                                                                   ByVal nIndex As Long) As Long
Declare Function QRDX_SetFocus Lib "user32" Alias "SetFocus" (ByVal hwnd As Long) As Long
'
Declare Function QRDX_LockWindowUpdate Lib "user32" Alias "LockWindowUpdate"_
                                                             (ByVal hwndLock As Long) As Long
Declare Function QRDX_ChooseColor Lib "comdlg32.dll" Alias "ChooseColorA" (pChoosecolor As QRDX_TCHOOSECOLOR) As Long
'
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
        tFindS As QRDX_FINDTEXT     ' For Search
        tFindR As QRDX_FINDTEXT     ' For Replace
        iReturn As Long
        QRED_PopUpMenu As QPopUpMenu
        mnuSep_0 As QMenuItem
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
        mnuSep_4 As QMenuItem
        iOldWndProc As Long
'       ON POP UP
'       ---------
        Event QRED_PopUpMenu.OnPopUp
            DefInt boolSelLength, boolReadOnly, boolLenClip
            If .selLength Then boolSelLength = 1
            If .readOnly Then
                boolReadOnly = 0
            Else
                boolReadOnly = 1
            End If
            ClipBoard.Open
                If Len(ClipBoard.Text) Then boolLenClip = 1
            ClipBoard.Close
            .mnuCut.Enabled = boolSelLength And boolReadOnly
            .mnuPaste.Enabled = boolReadOnly And boolLenClip
            .mnuDelete.Enabled = boolSelLength And boolReadOnly
            .mnuCopy.Enabled = boolSelLength
            .mnuSelectAll.Enabled = 1    ' True
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
'
'       mnu UNDO
'       --------
        SUB OnClic_mnuUndo
            SendMessage(.Handle, &HC7, 0, 0)
        END SUB
'
'       mnu CUT
'       -------
        Sub OnClic_mnuCut
            .CutToClipBoard
        End Sub
'
'       mnu PASTE
'       ---------
        Sub OnClic_mnuPaste
            .PasteFromClipBoard
        End Sub
'
'       mnu COPY
'       --------
        Sub OnClic_mnuCopy
            .CopyToClipBoard
        End Sub
'
'       mnu DELETE
'       ----------
        Sub OnClic_mnuDelete
            SendMessage (.Handle, &H100, &H2E, 0)
        End Sub
'
'       mnu SELECTALL
'       -------------
        Sub OnClic_mnuSelectAll
             .SelectAll
        End Sub
'
'       mnu SEARCH
'       ----------
        Sub OnClic_mnuSearch
            DefInt wParam, lParam
            DefStr sSelText
            If QRDX_SendMessage (.handle, 176, VarPtr(wParam), VarPtr(lParam)) <> - 1 Then
                sSelText = Mid$(.Text, wParam + 1, lParam - wParam)  ' EM_GETSEL  = 176
                If sSelText <> "" Then .edtSearchFor.Text = sSelText
            End If
            .frmSearch.Show
            QRDX_SetFocus (.edtSearchFor.Handle)
        End Sub
'
'       mnu REPLACE
'       -----------
        Sub OnClic_mnuReplace
             DefInt wParam, lParam
             DefStr sSelText
             If QRDX_SendMessage (.handle, 176, VarPtr(wParam), VarPtr(lParam)) <> - 1 Then
                 sSelText = Mid$(.Text, wParam + 1, lParam - wParam)  ' EM_GETSEL  = 176
                 If sSelText <> "" Then .edtToBeReplaced.Text = sSelText
             End If
             .frmReplace.Show
             QRDX_SetFocus (.edtToBeReplaced.Handle)
        End Sub
'
'       PROPERTY  UsePopUp
'       ------------------
        PUBLIC:
        PROPERTY SET Set_Popup(Use as long)
            .QRED_PopUpMenu.AutoPopup = Use
        END PROPERTY
'
'       Extend Size Limit
'       -----------------
        Sub ExtendSizeLimit
            QRDX_SendMessage (.handle, &HC5, .RichTextSizeLimit, 0)
        End Sub
'
        Sub SetMaxTextSize (iTextSizeMax As Long)
            QRDX_SendMessage (.handle, &HC5, iTextSizeMax, 0)
        End Sub
'     
'       Save/Restore Screen Scroll Position
'       -----------------------------------
        Sub SavePosition
            .iReturn = QRDX_SendMessage (.handle, 178, 0, Varptr(QRedEx.ptPoint))               ' 178 EM_GETRECT
            .SavedTopLeft = QRDX_SendMessage (.handle, 215, 0, Varptr(QRedEx.ptPoint))          ' 215 EM_CHARFROMPOS
            .SavedBottomRight = QRDX_SendMessage (.handle, 215, 0, Varptr(QRedEx.ptPoint) + 2)  ' 215 EM_CHARFROMPOS
            .SavedCaretPosition = .SelStart
            If (.SavedCaretPosition > .SavedTopLeft And _
                 .SavedCaretPosition < .SavedBottomRight) = 0 Then _
                 .SavedCaretPosition = (.SavedBottomRight + .SavedTopLeft)/2
        End Sub
'
        Sub RestorePosition
            QRDX_SetFocus (.Handle)
            .SelStart = Len(.Text)
            .SelStart = .SavedTopLeft
            .SelStart = .SavedCaretPosition
        End Sub
        ' Get Index of Top Screen Line
        ' ----------------------------
        Function TopLineIndex () As Long
            .iReturn = QRDX_SendMessage (.handle, 178, 0, Varptr(QRedEx.ptPoint))               ' 178 EM_GETRECT
            DefInt iSavedTopLeft = QRDX_SendMessage (.handle, 215, 0, Varptr(QRedEx.ptPoint))   ' 215 EM_CHARFROMPOS
            Result = QRDX_SendMessage (.handle, 201, iSavedTopLeft, 0)                         ' 201 EM_LINEFROMCHAR
        End Function
        ' Get Index of Bottom Screen Line
        ' -------------------------------
        Function BottomLineIndex () As Long
            .iReturn = QRDX_SendMessage (.handle, 178, 0, Varptr(QRedEx.ptPoint))                     ' 178 EM_GETRECT
            DefInt iSavedBottomRight = QRDX_SendMessage (.handle, 215, 0, Varptr(QRedEx.ptPoint) + 2) ' 215 EM_CHARFROMPOS
            Result =  QRDX_SendMessage (.handle, 201, iSavedBottomRight, 0)                           ' 201 EM_LINEFROMCHAR
        End Function
'
'       CHANGE FONT
'       -----------
        Sub ChangeFont
            .dlgFont.GetFont(QRedEx.fntRichEdit)
            If .dlgFont.Execute = 0 Then
               ShowMessage("Error While Setting Fonts \n\n NOTHING DONE")
            Else
                .dlgFont.SetFont(QRedEx.fntRichEdit)
                .font = QRedEx.fntRichEdit
            End If
        End sub
'
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
'
'       CHANGE BGCOLOR
'       --------------
        Sub ChangeBgColor
           .tColor.lStructSize = 36
           .tColor.hwndOwner = Application.Handle
           .tColor.hInstance = 0
           .tColor.rgbResult = QRedEx.Color
           .tColor.lpCustColors = VarPtr(QRedEx.RgbInit(1))
           .tColor.flags = 131        ' CC_FULLOPEN = 2 ; CC_RGBINIT = 1 ; CC_SOLIDCOLOR = 128 ; CC_ANYCOLOR = 256 = &H100
           .tColor.lCustData = 0      ' ignored
           .tColor.lpfnHook = 0       ' ignored
           .tColor.lpTemplateName = 0 ' ignored
           If QRDX_ChooseColor (.tColor) <> 0 Then .Color = .tColor.rgbResult
        End sub
'
     PRIVATE:
'       Search
'       ------
        Sub OnClic_btnSearch
            DefInt ptrSel, searchFlags = 1   ' FR_DOWN
            DefStr sSearched = .edtSearchFor.Text
            If sSearched = "" Then Exit Sub
            .tFindS.ptrString = Varptr (sSearched)
            .tFindS.cpMin = .SelStart + 1
            .tFindS.cpMax = -1
            If .chkSearchCaseS.Checked <> 0 Then searchFlags = searchFlags + 4             ' FR_MATCHCASE
            If .chkSearchWholeWordsOnly.Checked <> 0 Then searchFlags = searchFlags + 2  ' FR_WHOLEWORD
            ptrSel = QRDX_SendMessage (.handle, 1080, searchFlags, .tFindS)                ' 1080 EM_FINDTEXT WM_USER + 56
            If ptrSel <> - 1 Then
                    .SelStart = ptrSel
                    .SelLength = Len(sSearched)
            Else
                Sound 3000, 5
                .SelStart = 0
            End If
        End Sub
'
'       Find Next (for Replace)
'       ---------
        Sub OnClic_btnFindNext
            DefInt ptrSel, replaceFlags = 1
            DefStr sSearched = .edtToBeReplaced.Text
            If sSearched = "" Then Exit Sub
            .tFindR.ptrString = Varptr (sSearched)
            If .chkReplaceCaseS.Checked <> 0 Then replaceFlags = replaceFlags + 4          ' FR_MATCHCASE
            If .chkReplaceWholeWordsOnly.Checked <> 0 Then replaceFlags = replaceFlags + 2 ' FR_WHOLEWORD
                .tFindR.cpMin = .SelStart + 1
                .tFindR.cpMax = - 1
                ptrSel = QRDX_SendMessage (.handle, 1080, replaceFlags, .tFindR)               ' 1080 EM_FINDTEXT WM_USER + 56
                If ptrSel <> - 1 Then
                    .SelStart = ptrSel
                    .SelLength = Len(sSearched)
                Else
                    Sound 3000, 5
                    .SelStart = 0
                End If
        End Sub
'
'       Replace
'       -------
        Sub OnClic_btnReplace
            DefInt iTmp, ptrSel, replaceFlags = 1
            DefStr sSearched = .edtToBeReplaced.Text
            If sSearched = "" Then Exit Sub
            .tFindR.ptrString = Varptr (sSearched)
            If .chkReplaceCaseS.Checked <> 0 Then replaceFlags = replaceFlags + 4          ' FR_MATCHCASE
            If .chkReplaceWholeWordsOnly.Checked <> 0 Then replaceFlags = replaceFlags + 2 ' FR_WHOLEWORD
            If (.edtReplacedBy.Text = "" Or .SelLength = 0) Then Exit Sub
            iTmp = .SelStart + 1
            .Text = Delete$(.Text, iTmp, .SelLength)
            .Text = Insert$(.edtReplacedBy.Text, .Text, iTmp)
            .SelStart = .SelStart + Len(.edtReplacedBy.Text)
            ' Find Next
            .tFindR.cpMin = iTmp + Len(.edtReplacedBy.Text) - 1
            .tFindR.cpMax = - 1
            ptrSel = QRDX_SendMessage (.handle, 1080, replaceFlags, .tFindR)               ' 1080 EM_FINDTEXT WM_USER + 56
            If ptrSel <> - 1 Then
                .SelStart = ptrSel
                .SelLength = Len(sSearched)
            Else
                Sound 3000, 3
                .SelStart = 0
            End If
        End Sub
'
'       Replace All
'       -----------
        Sub OnClic_btnReplaceAll
            DefInt iTmp, ptrSel, replaceFlags = 1
            DefStr sSearched = .edtToBeReplaced.Text
            If sSearched = "" Then Exit Sub
            .tFindR.ptrString = Varptr (sSearched)
            If .chkReplaceCaseS.Checked <> 0 Then replaceFlags = replaceFlags + 4          ' FR_MATCHCASE
            If .chkReplaceWholeWordsOnly.Checked <> 0 Then replaceFlags = replaceFlags + 2 ' FR_WHOLEWORD
            .SavePosition
            QRDX_LockWinDowUpdate (QRedEx.Handle)
            ' Find First  
            .tFindR.cpMin = .SelStart + 1
            .tFindR.cpMax = - 1
            ptrSel = QRDX_SendMessage (.handle, 1080, replaceFlags, .tFindR)               ' 1080 EM_FINDTEXT WM_USER + 56
            If ptrSel <> - 1 Then
                .SelStart = ptrSel
                .SelLength = Len(sSearched)
            Else
                Sound 3000, 5
                .SelStart = 0
            End If
            If (.edtReplacedBy.Text = "" Or ptrSel = -1) = 0 Then
                While .SelLength > 0
                    iTmp = .SelStart + 1
                    .Text = Delete$(.Text, iTmp, .SelLength)
                    .Text = Insert$(.edtReplacedBy.Text, .Text, iTmp)
                    .SelStart = .SelStart + Len(.edtReplacedBy.Text)
                    ' Find Next
                    .tFindR.cpMin = iTmp + Len(.edtReplacedBy.Text) - 1
                    .tFindR.cpMax = - 1
                    ptrSel = QRDX_SendMessage (.handle, 1080, replaceFlags, .tFindR)               ' 1080 EM_FINDTEXT WM_USER + 56
                    If ptrSel <> - 1 Then
                        .SelStart = ptrSel
                        .SelLength = Len(sSearched)
                    Else
                        Sound 3000, 3
                        .SelStart = 0
                    End If
                Wend
            End If
            QRDX_LockWindowUpdate ()
            .RestorePosition
        End Sub
'
'       On Keypress EditBoxes
'       ---------------------
        Sub OnKeyPress_edtSearchFor (key As Byte)
            If Key = 13 Then .OnClic_btnSearch
        End Sub
'
        Sub OnKeyPress_edtToBeReplaced (key As Byte)
            If (Key = 13 or Key = 9) Then QRDX_SetFocus (.edtReplacedBy.handle)
        End Sub
'
        Sub OnKeyPress_edtReplacedBy (key As Byte)
            If (Key = 13) Then .OnClic_btnFindNext
        End Sub
'
        PRIVATE:
        CONSTRUCTOR
            WantTabs = 1
            RichTextSizeLimit = 1048576
            PopUpMenu = QRedEx.QRED_PopUpMenu
            mnuSep_0.Caption = "-"
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
            mnuSep_4.Caption = "-"
            QRED_PopUpMenu.AddItems QRedEx.mnuSep_0, QRedEx.mnuUndo,QRedEx.mnuSep_1, _
                        QRedEx.mnuCopy, QRedEx.mnuCut, QRedEx.mnuDelete, _
                        QRedEx.mnuPaste, QRedEx.mnuSep_2, QRedEx.mnuSelectAll, _
                        QRedEx.mnuSep_3, QRedEx.mnuSearch, QRedEx.mnuReplace, _
                        QRedEx.mnuSep_4
'   ColorDialog PreSelected Colors
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
' FORM SEARCH
' -----------
            frmSearch.Center
            frmSearch.BorderStyle = 3 ' bsNone
            frmSearch.Caption = " SEARCH IN TEXT :"
            frmsearch.Width = 400
            frmSearch.Height = 125
            frmSearch.Visible = 0
            frmSearch.Color = &HB0B0B0
            frmSearch.Font.Name = "courier"
            frmSearch.Font.Size = 12
'
            lblSearchFor.Parent = QRedEx.frmSearch
            lblSearchFor.Top  = 5
            lblSearchFor.Left = 5
            lblSearchFor.Color = &H80FFFF ' &HFFFFFF
            lblSearchFor.Font.Color = &H000000
            lblSearchFor.Caption = " STRING TO SEARCH FOR : "
'
            edtSearchFor.Parent = QRedEx.frmSearch
            edtSearchFor.Top = 30
            edtSearchFor.Left = 5
            edtSearchFor.Width = QRedEx.frmSearch.ClientWidth - 10
            edtSearchFor.Height = 20
            edtSearchFor.OnKeyPress = QRedEx.OnKeyPress_edtSearchFor
'
            btnSearch.Parent = QRedEx.frmSearch
            btnSearch.Top = 65
            btnSearch.Left = 5
            btnSearch.Width = 125 'QRedEx.frmSearch.ClientWidth - 10
            btnSearch.Height = 25
            btnSearch.Caption = "&FIND NEXT"
            btnSearch.OnClick = QRedEx.OnClic_btnSearch
'
            chkSearchCaseS.Parent = QRedEx.frmSearch
            chkSearchCaseS.Top = 65
            chkSearchCaseS.Left = 150
            chkSearchCaseS.Width = 110
            chkSearchCaseS.Height = 25
            chkSearchCaseS.Font.Size = 10
            chkSearchCaseS.Caption = "MATCH CASE"
'
            chkSearchWholeWordsOnly.Parent = QRedEx.frmSearch
            chkSearchWholeWordsOnly.Top = 65
            chkSearchWholeWordsOnly.Left = 280
            chkSearchWholeWordsOnly.Width = 110
            chkSearchWholeWordsOnly.Height = 25
            chkSearchWholeWordsOnly.Font.Size = 10
            chkSearchWholeWordsOnly.Caption = "FULL WORD"

' FORM REPLACE
' ------------
            frmReplace.Center
            frmReplace.BorderStyle = 3 ' bsNone
            frmReplace.Caption = " REPLACE IN TEXT :"
            frmReplace.Font.Name = "courier"
            frmReplace.Font.Size = 12
            frmReplace.Width = 500
            frmReplace.Height = 210
            frmReplace.Visible = 0
            frmReplace.Color = &HB0B0B0
'
            lblToBeReplaced.Parent = QRedEx.frmReplace
            lblToBeReplaced.Top  = 5
            lblToBeReplaced.Left = 5
            lblToBeReplaced.Color = &H80FFFF ' &HFFFFFF
            lblToBeReplaced.Font.Color = &H000000
            lblToBeReplaced.Caption = " STRING TO BE REPLACED : "
'
            edtToBeReplaced.Parent = QRedEx.frmReplace
            edtToBeReplaced.Top = 30
            edtToBeReplaced.Left = 5
            edtToBeReplaced.Width = QRedEx.frmReplace.ClientWidth - 10
            edtToBeReplaced.Height = 20
            edtToBeReplaced.OnKeyPress = QRedEx.OnKeyPress_edtToBeReplaced
'
            lblReplacedBy.Parent = QRedEx.frmReplace
            lblReplacedBy.Top  = 65
            lblReplacedBy.Left = 5
            lblReplacedBy.Color = &H80FFFF ' &HFFFFFF
            lblReplacedBy.Font.Color = &H000000
            lblReplacedBy.Caption = " REPLACEMENT STRING : "
'
            edtReplacedBy.Parent = QRedEx.frmReplace
            edtReplacedBy.Top = 95
            edtReplacedBy.Left = 5
            edtReplacedBy.Width = QRedEx.frmReplace.ClientWidth - 10
            edtReplacedBy.Height = 20
            edtReplacedBy.OnKeyPress = QRedEx.OnKeyPress_edtReplacedBy
'
            btnFindNext.Parent = QRedEx.frmReplace
            btnFindNext.Top = 130
            btnFindNext.Left = 5
            btnFindNext.Width = (QRedEx.frmReplace.ClientWidth - 20)/3
            btnFindNext.Height = 25
            btnFindNext.Caption = "&FIND NEXT"
            btnFindNext.OnClick = QRedEx.OnClic_btnFindNext
'
            btnReplace.Parent = QRedEx.frmReplace
            btnReplace.Top = 130
            btnReplace.Left = 10 + (QRedEx.frmReplace.ClientWidth - 20)/3
            btnReplace.Width = (QRedEx.frmReplace.ClientWidth - 20)/3
            btnReplace.Height = 25
            btnReplace.Caption = "&REPLACE"
            btnReplace.OnClick = QRedEx.OnClic_btnReplace

            btnReplaceAll.Parent = QRedEx.frmReplace
            btnReplaceAll.Top = 130
            btnReplaceAll.Left = 15 + 2 * (QRedEx.frmReplace.ClientWidth - 20)/3
            btnReplaceAll.Width = (QRedEx.frmReplace.ClientWidth - 20)/3
            btnReplaceAll.Height = 25
            btnReplaceAll.Caption = "REPLACE &ALL"
            btnReplaceAll.OnClick = QRedEx.OnClic_btnReplaceAll
'
            chkReplaceCaseS.Parent = QRedEx.frmReplace
            chkReplaceCaseS.Top = 155
            chkReplaceCaseS.Left = 5
            chkReplaceCaseS.Width = (QRedEx.frmReplace.ClientWidth - 20)/3
            chkReplaceCaseS.Height = 25
            chkReplaceCaseS.Font.Size = 10
            chkReplaceCaseS.Caption = "MATCH CASE"
'
            chkReplaceWholeWordsOnly.Parent = QRedEx.frmReplace
            chkReplaceWholeWordsOnly.Top = 155
            chkReplaceWholeWordsOnly.Left = 10 + (QRedEx.frmReplace.ClientWidth - 20)/3
            chkReplaceWholeWordsOnly.Width = 30 + (QRedEx.frmReplace.ClientWidth - 20)/3
            chkReplaceWholeWordsOnly.Height = 25
            chkReplaceWholeWordsOnly.Font.Size = 10
            chkReplaceWholeWordsOnly.Caption = "FULL WORD"
'
            chkReplaceUp.Parent = QRedEx.frmReplace
            chkReplaceUp.Top = 155
            chkReplaceUp.Left = 15 + 2 * (QRedEx.frmReplace.ClientWidth - 20)/3
            chkReplaceUp.Width = (QRedEx.frmReplace.ClientWidth - 20)/3
            chkReplaceUp.Height = 25
            chkReplaceUp.Font.Size = 10
            chkReplaceUp.Caption = "REPLACE UP"
            chkReplaceUp.ShowHint = True
            chkReplaceUp.Hint = "CANT HAVE IT WORK"
            chkReplaceUp.Enabled = False
        END CONSTRUCTOR
    End With
End Type
' =============================================================================
' =============================================================================
$UNDEF QRICHEDIT
$DEFINE QRICHEDIT QREDEX
'
