' ToolBar Component fo Rapidq
' Version 1.2 (stable)
' Coded by Nastase Eodor
' http://rqwork.evonet.ro
' mailTo: rqwork@evonet.ro

$IFNDEF __RQMEMORY
$Include "Memory.inc"
$ENDIF

$DEFINE tbsButton     TBSTYLE_BUTTON
$DEFINE tbsCheck      TBSTYLE_CHECK
$DEFINE tbsCheckGroup TBSTYLE_CHECKGROUP
$DEFINE tbsDropDown   TBSTYLE_DROPDOWN

Type ToolButton
     Down     As Integer
     Enabled  As Integer
     Visible  As Integer
     Hint     As Integer
     ShowHint As Integer
     DropDown As Integer
End Type

Declare Sub EventTemplate_ToolBar_ButtonClick(ButtonIndex&)
Declare Sub EventTemplate_ToolBar_Command(NotifyCode&,CommandID&,hwndCtrl&)
Type QToolBar Extends QObject
     Private:
     NM             As NMHDR
     TTX            As TOOLTIPTEXT
     TBn            As TBNOTIFY
     R              As Rect
     P              As Point
     LF             As LOGFONT
     TB             As TBBUTTON
     ToolButton     As ToolButton
     IDCommand      As Integer
     NewProc        As Integer
     ClassProc      As Integer
     ParentProc     As Integer
     LastParentProc As Integer
     ParentWnd      As Integer
     Buttons        As QStringList
     Public:
     Handle         As Integer
     Parent         As QForm   Property Set SetParent
     Parent2        As QPanel  Property Set SetParent2
     Left           As Integer Property Set SetLeft
     Top            As Integer Property Set SetTop
     Width          As Integer Property Set SetWidth
     Height         As Integer Property Set SetHeight
     Enabled        As Integer Property Set SetEnabled
     Visible        As Integer Property Set SetVisible
     AutoSize       As Integer Property Set SetAutoSize
     Flat           As Integer Property Set SetFlat
     Transparent    As Integer Property Set SetTransparent
     Wrapable       As Integer Property Set SetWrapable
     Divider        As Integer Property Set SetDivider
     ButtonWidth    As Integer Property Set SetButtonWidth
     ButtonHeight   As Integer Property Set SetButtonHeight
     Font           As QFont   Property Set SetFont
     PopupMenu      As QPopupMenu
     Images         As QImageList
     HotImages      As QImageList
     DisabledImages As QImageList
     OnButtonClick  As Event(EventTemplate_ToolBar_ButtonClick)
     OnCommand      As Event(EventTemplate_ToolBar_Command)
     
     With This
     
     Function Button(Index&) As Integer
         Result = Val(.Buttons.Item(Index&))
     End Function
     
     Function ButtonCount As Integer
         Result = .Buttons.ItemCount
     End Function
     
     Sub CreateWnd
         If .Handle Then Exit Sub
         Dim R As Rect
         DefInt Style = ws_child Or tbstyle_tooltips' Or ccs_nomovex or ccs_noresize Or ccs_noparentalign
         Style = Style Or IIf(.Flat,TBSTYLE_FLAT,0) Or IIf(.Transparent,TBSTYLE_TRANSPARENT,0) Or IIf(.Wrapable,TBSTYLE_WRAPABLE,0) Or IIf(.Divider,0,CCS_NODIVIDER) Or ccs_nomovey
         .Handle = CreateWindowEx(0,"QToolBar","",Style,.Left,.Top,.Width,.Height,.ParentWnd,0,GetModuleHandle(0),0)
         If .Handle Then
            SendMessage(.Handle,TB_BUTTONSTRUCTSIZE,SizeOf(This.TB),0)
            SendMessage(.Handle,TB_SETEXTENDEDSTYLE, 0, SendMessageA(.Handle,TB_GETEXTENDEDSTYLE, 0, 0) Or TBSTYLE_EX_DRAWDDARROWS)
            SendMessage(.Handle,TB_SETIMAGELIST,0,.Images.Handle)
            If .HotImages.Count Then SendMessage(.Handle,TB_SETHOTIMAGELIST,0,.HotImages.Handle)
            If .DisabledImages.Count Then SendMessage(.Handle,TB_SETDISABLEDIMAGELIST,0,.DisabledImages.Handle)
            SendMessage(.Handle,WM_SETFONT,.Font.Handle,1)
            ShowWindow(.Handle,IIf(.Visible,SW_SHOW,SW_HIDE))
            If .AutoSize Then SendMessage(.Handle,TB_AUTOSIZE,0,0)
            SendMessage(.Handle,TB_GETITEMRECT,0,R)
            .ButtonWidth  =  R.Right - R.Left
            .ButtonHeight =  R.Bottom - R.Top
            UpdateWindow(GetParent(.Handle))
         End If
     End Sub

     Sub RecreateWnd
         DefInt i
         If .Handle Then
            DestroyWindow(.Handle)
            .Handle = 0
         End If
         .CreateWnd
         If .Handle Then
            For i = 0 To .ButtonCount -1
                MemCpy .TB,.Button(i),SizeOf(This.TB)
                SendMessage(.Handle,TB_ADDBUTTONS,1,.TB)
                If .TB.fsStyle = tbsCheck Or .TB.fsStyle = tbsCheckGroup Then
                   MemCpy .ToolButton,.TB.dwData,SizeOf(This.ToolButton)
                   SendMessage(.Handle,TB_CHECKBUTTON,.TB.idCommand,.ToolButton.Down)
                End If
            Next i
         End If
         If .AutoSize Then SendMessage(.Handle,TB_AUTOSIZE,0,0)
     End Sub
     
     Sub Invalidate
         If .Handle Then InvalidateRect(.Handle,0,0)
     End Sub
     
     Sub Update
         If .Handle Then UpdateWindow(.Handle)
     End Sub
     
     Sub Repaint
         If .Handle Then
            RedrawWindow(.Handle,0,0,RDW_ERASE Or RDW_INVALIDATE)
            .Update
         End If
     End Sub
     
     Sub Refresh
         If .HotImages.Count Then SendMessage(.Handle,TB_SETHOTIMAGELIST,0,.HotImages.Handle)
         If .DisabledImages.Count Then SendMessage(.Handle,TB_SETDISABLEDIMAGELIST,0,.DisabledImages.Handle)
     End Sub
     
     Function GetCommandID(Index&) As Integer
         Result = -1
         If Index& > -1 And Index& <.ButtonCount Then
            MemCpy .TB,.Button(Index&),SizeOf(This.TB)
            Result = .TB.idCommand
         End If
     End Function
     
     Function GetIndex(CommandID&) As Integer
         DefInt i
         Result = -1
         For i = 0 To .ButtonCount -1
             MemCpy .TB,.Button(i),SizeOf(This.TB)
             If .TB.idCommand = CommandID& Then Result = i
         Next i
     End Function
     
     Sub SetButtonImageIndex(Index&,ImageIndex&)
         MemCpy .TB,.Button(Index&),SizeOf(This.TB)
         .TB.iBitmap = ImageIndex&
         MemCpy .Button(Index&),.TB,SizeOf(This.TB)
         If .Handle Then SendMessage(.Handle,TB_CHANGEBITMAP,.TB.idCommand,ImageIndex&)
     End Sub

     Function GetButtonImageIndex(Index&) As Integer
         Result = -1
         MemCpy .TB,.Button(Index&),SizeOf(This.TB)
         Result = .TB.iBitmap
     End Function
     
     Sub SetButtonCaption(Index&,Caption$)
         MemCpy .TB,.Button(Index&),SizeOf(This.TB)
         If .TB.iString Then
            PtrFree(.TB.iString)
            .TB.iString = NewZStr(Caption$)
            MemCpy .Button(Index&),.TB,SizeOf(This.TB)
            .RecreateWnd
         End If
     End Sub
     
     Function GetButtonCaption(Index&) As String
         Result = ""
         MemCpy .TB,.Button(Index&),SizeOf(This.TB)
         Result = StrFromPtr(.TB.iString)
     End Function
     
     Sub SetButtonDropDown(Index&,DropDown As QPopupMenu)
         MemCpy .TB,.Button(Index&),SizeOf(This.TB)
         If .TB.dwData Then
            MemCpy .ToolButton,.TB.dwData,SizeOf(This.ToolButton)
            .ToolButton.DropDown = DropDown.Handle
            MemCpy .TB.dwData,.ToolButton,SizeOf(This.ToolButton)
            MemCpy .Button(Index&),.TB,SizeOf(This.TB)
         End If
     End Sub

     Function GetButtonDropDown(Index&) As Integer
         Result = 0
         MemCpy .TB,.Button(Index&),SizeOf(This.TB)
         If .TB.dwData Then
            MemCpy .ToolButton,.TB.dwData,SizeOf(This.ToolButton)
            Result = .ToolButton.DropDown
         End If
     End Function
     
     Sub SetButtonHint(Index&,Hint$)
         MemCpy .TB,.Button(Index&),SizeOf(This.TB)
         If .TB.dwData Then
            MemCpy .ToolButton,.TB.dwData,SizeOf(This.ToolButton)
            .ToolButton.Hint = NewZStr(Hint$)
            MemCpy .TB.dwData,.ToolButton,SizeOf(This.ToolButton)
            MemCpy .Button(Index&),.TB,SizeOf(This.TB)
         End If
     End Sub

     Function GetButtonHint(Index&) As String
         Result = ""
         MemCpy .TB,.Button(Index&),SizeOf(This.TB)
         If .TB.dwData Then
            MemCpy .ToolButton,.TB.dwData,SizeOf(This.ToolButton)
            Result = StrFromPtr(.ToolButton.Hint)
         End If
     End Function
     
     Sub SetButtonShowHint(Index&,ShowHint&)
         MemCpy .TB,.Button(Index&),SizeOf(This.TB)
         If .TB.dwData Then
            MemCpy .ToolButton,.TB.dwData,SizeOf(This.ToolButton)
            .ToolButton.ShowHint = ShowHint&
            MemCpy .TB.dwData,.ToolButton,SizeOf(This.ToolButton)
            MemCpy .Button(Index&),.TB,SizeOf(This.TB)
         End If
     End Sub

     Function GetButtonShowHint(Index&) As Integer
         Result = 0
         MemCpy .TB,.Button(Index&),SizeOf(This.TB)
         If .TB.dwData Then
            MemCpy .ToolButton,.TB.dwData,SizeOf(This.ToolButton)
            Result = .ToolButton.ShowHint
         End If
     End Function

     Sub SetButtonDown(Index&,Down&)
         DefInt CommandID = .GetCommandID(Index&)
         If CommandID <> -1 Then
            SendMessage(.Handle,TB_CHECKBUTTON,CommandID,Down&)
            MemCpy .TB,.Button(Index&),SizeOf(This.TB)
            If .TB.dwData Then
               MemCpy .ToolButton,.TB.dwData,SizeOf(This.ToolButton)
               .ToolButton.Down = Down&
               MemCpy .TB.dwData,.ToolButton,SizeOf(This.ToolButton)
               MemCpy .Button(Index&),.TB,SizeOf(This.TB)
             End If
         End If
     End Sub

     Function GetButtonDown(Index&) As Integer
         DefInt CommandID = .GetCommandID(Index&)
         Result = 0
         If CommandID <> -1 Then
            If .Handle Then
               Result = SendMessageA(.Handle,TB_ISBUTTONCHECKED,CommandID,0)
            Else
               MemCpy .TB,.Button(Index&),SizeOf(This.TB)
               If .TB.dwData Then
                  MemCpy .ToolButton,.TB.dwData,SizeOf(This.ToolButton)
                  Result = .ToolButton.Down
               End If
            End If
         End If
     End Function

     Sub SetButtonEnabled(Index&,Enabled&)
         DefInt CommandID = .GetCommandID(Index&)
         If CommandID <> -1 Then
            SendMessage(.Handle,TB_ENABLEBUTTON,CommandID,Enabled&)
            MemCpy .TB,.Button(Index&),SizeOf(This.TB)
            If .TB.dwData Then
               MemCpy .ToolButton,.TB.dwData,SizeOf(This.ToolButton)
               .ToolButton.Enabled = Enabled&
               MemCpy .TB.dwData,.ToolButton,SizeOf(This.ToolButton)
               MemCpy .Button(Index&),.TB,SizeOf(This.TB)
             End If
         End If
     End Sub

     Function GetButtonEnabled(Index&) As Integer
         DefInt CommandID = .GetCommandID(Index&)
         Result = 0
         If CommandID <> -1 Then
            If .Handle Then
               Result = SendMessageA(.Handle,TB_ISBUTTONENABLED,CommandID,0)
            Else
               MemCpy .TB,.Button(Index&),SizeOf(This.TB)
               If .TB.dwData Then
                  MemCpy .ToolButton,.TB.dwData,SizeOf(This.ToolButton)
                  Result = .ToolButton.Enabled
               End If
            End If
         End If
     End Function

     Sub SetButtonVisible(Index&,Visible&)
         DefInt CommandID = .GetCommandID(Index&)
         If CommandID <> -1 Then
            SendMessage(.Handle,TB_HIDEBUTTON,CommandID,Visible&)
            MemCpy .TB,.Button(Index&),SizeOf(This.TB)
            If .TB.dwData Then
               MemCpy .ToolButton,.TB.dwData,SizeOf(This.ToolButton)
               .ToolButton.Visible = Visible&
               MemCpy .TB.dwData,.ToolButton,SizeOf(This.ToolButton)
               MemCpy .Button(Index&),.TB,SizeOf(This.TB)
             End If
         End If
     End Sub

     Function GetButtonVisible(Index&) As Integer
         DefInt CommandID = .GetCommandID(Index&)
         Result = 0
         If CommandID <> -1 Then
            If .Handle Then
               Result = SendMessageA(.Handle,TB_ISBUTTONHIDDEN,CommandID,0)
            Else
               MemCpy .TB,.Button(Index&),SizeOf(This.TB)
               If .TB.dwData Then
                  MemCpy .ToolButton,.TB.dwData,SizeOf(This.ToolButton)
                  Result = .ToolButton.Visible
               End If
            End If
         End If
     End Function

     Property Set SetParent(Value As QForm)
         .ParentWnd = Value.Handle
         If .Handle Then
            SetParent(.Handle,Value.Handle)
            If GetWindowLong(.ParentWnd,GWL_WNDPROC) <> .ParentProc Then
               .LastParentProc = SetWindowLong(.ParentWnd,GWL_WNDPROC,.ParentProc)
            End If
         Else
            .CreateWnd
            If GetWindowLong(.ParentWnd,GWL_WNDPROC) <> .ParentProc Then
               .LastParentProc = SetWindowLong(.ParentWnd,GWL_WNDPROC,.ParentProc)
            End If
         End If
     End Property
     
     Property Set SetParent2(Value As QPanel)
         .ParentWnd = Value.Handle
         If .Handle Then
            SetParent(.Handle,Value.Handle)
            If GetWindowLong(.ParentWnd,GWL_WNDPROC) <> .ParentProc Then
               .LastParentProc = SetWindowLong(.ParentWnd,GWL_WNDPROC,.ParentProc)
            End If
         Else
            .CreateWnd
            If GetWindowLong(.ParentWnd,GWL_WNDPROC) <> .ParentProc Then
               .LastParentProc = SetWindowLong(.ParentWnd,GWL_WNDPROC,.ParentProc)
            End If
         End If
     End Property
     
     Property Set SetLeft(Value As Integer)
         .Left = Value
         If .Handle Then MoveWindow(.Handle,.Left,.Top,.Width,.Height,1)
     End Property
     
     Property Set SetTop(Value As Integer)
         .Top = Value
         If .Handle Then MoveWindow(.Handle,.Left,.Top,.Width,.Height,1)
     End Property
     
     Property Set SetWidth(Value As Integer)
         .Width = value
         If .Handle Then MoveWindow(.Handle,.Left,.Top,.Width,.Height,1)
     End Property
     
     Property Set SetHeight(Value As Integer)
         .Height = value
         If .Handle Then MoveWindow(.Handle,.Left,.Top,.Width,.Height,1)
     End Property
     
     Property Set SetFlat(Value As Integer)
         .Flat = value
         .RecreateWnd
     End Property
     
     Property Set SetAutosize(Value As Integer)
         .Autosize = value
         .RecreateWnd
         SendMessage(.Handle,TB_AUTOSIZE,0,0)
     End Property
     
     Property Set SetTransparent(Value As Integer)
         .Transparent = value
         .RecreateWnd
     End Property
     
     Property Set SetWrapable(Value As Integer)
         .Wrapable = Value
         .RecreateWnd
     End Property
     
     Property Set SetDivider(Value As Integer)
         .Divider = Value
         .RecreateWnd
     End Property
     
     Property Set SetEnabled(Value As Integer)
         .Enabled = Value
         If .Handle Then EnableWindow(.Handle,.Enabled)
     End Property
     
     Property Set SetVisible(Value As Integer)
         .Visible = value
         If .Handle Then ShowWindow(.Handle,IIf(Value,SW_SHOW,SW_HIDE))
     End Property
     
     Property Set SetButtonWidth(Value As Integer)
         .ButtonWidth = value
         If .Handle Then
            SendMessage(.Handle,TB_SETBUTTONSIZE,0,(.ButtonHeight * &H10000) Or (.ButtonWidth And &HFFFF))
            .Invalidate
         End If
     End Property

     Property Set SetButtonHeight(Value As Integer)
         .ButtonHeight = value
         If .Handle Then
            SendMessage(.Handle,TB_SETBUTTONSIZE,0,(.ButtonHeight * &H10000) Or (.ButtonWidth And &HFFFF))
            .Invalidate
         End If
     End Property
     
     Property Set SetFont(Value As QFont)
         .Font.Name    = Value.Name
         .Font.Size    = value.Size
         .Font.CharSet = value.CharSet
         If GetObject(Value.Handle,SizeOf(This.LF),.LF) Then
            If .LF.lfWeight > 400 Then .Font.AddStyles fsBold
            If .LF.lfItalic    Then .Font.AddStyles fsItalic
            If .LF.lfUnderline Then .Font.AddStyles fsUnderline
            If .LF.lfStrikeout Then .Font.AddStyles fsStrikeout
         End If
         If .Handle Then SendMessage(.Handle,WM_SETFONT,.Font.Handle,1)
     End Property
     
     Sub AddButton(ImageIndex&,Caption$,Style&)
         .IDCommand++
         .TB.fsStyle   = IIf(Style& = 0,TBSTYLE_BUTTON,Style&)
         .TB.fsState   = TBSTATE_ENABLED
         .TB.iBitmap   = ImageIndex&
         .TB.idCommand = .IDCommand
         .TB.iString   = IIf(Caption$ <> "",NewZStr(Caption$),0)
         .TB.dwData    = NewPtr(SizeOf(This.ToolButton),.ToolButton)
         If SendMessageA(.Handle,TB_ADDBUTTONS,1,.TB) Then
            .Buttons.AddItems Str$( NewPtr(SizeOf(This.TB),.TB) )
         End If
     End Sub
     
     Sub AddSeparator
         .TB.fsStyle   = TBSTYLE_SEP
         .TB.fsState   = TBSTATE_ENABLED
         .TB.iBitmap   = -1
         .TB.idCommand = -1
         .TB.dwData    = 0
         .TB.iString   = 0
         If SendMessageA(.Handle,TB_ADDBUTTONS,1,.TB) Then
            .Buttons.AddItems Str$( NewPtr(SizeOf(This.TB),.TB) )
         End If
     End Sub
     
     Sub InsButton(Index&,ImageIndex&,Caption$,Style&)
         .IDCommand++
         .TB.fsStyle   = IIf(Style& = 0,TBSTYLE_BUTTON,Style&)
         .TB.fsState   = TBSTATE_ENABLED
         .TB.iBitmap   = ImageIndex&
         .TB.idCommand = .IDCommand
         .TB.iString   = IIf(Caption$ <> "",NewZStr(Caption$),0)
         .TB.dwData    = NewPtr(SizeOf(This.ToolButton),.ToolButton)
         If SendMessageA(.Handle,TB_INSERTBUTTON,Index&,.TB) Then
            .Buttons.InsertItem Index&,Str$( NewPtr(SizeOf(This.TB),.TB) )
         End If
     End Sub
     
     Sub DelButton(Index&)
         If Index& > -1 And Index& < .ButtonCount Then ' inc2026: < .ButtonCount вместо < .ButtonCount -1: иначе последнюю кнопку удалить нельзя; допустимые индексы 0..ButtonCount-1, как проверка в GetCommandID (строка 143)
            DefInt Ptr = .Button(Index&)
            PtrFree(Ptr)
            .Buttons.DelItems Index&
            SendMessage(.Handle,TB_DELETEBUTTON,Index&,0)
         End If
     End Sub

     Function ParentWndProc(hWnd&,Msg&,wParam&,lParam&) As Integer
         Select Case Msg&
         Case WM_COMMAND
              DefInt Index
              If lParam& = .Handle Then
                 Index = SendMessageA(.Handle,TB_COMMANDTOINDEX,LoWord(wParam&),0)
                 If Index <> -1 Then
                    If SendMessageA(.Handle,TB_GETBUTTON,Index,.TB) Then
                       If .TB.fsStyle = tbsCheck Or .TB.fsStyle = tbsCheckGroup Then
                          If .TB.dwData Then
                             MemCpy .ToolButton,.TB.dwData,SizeOf(This.ToolButton)
                             .ToolButton.Down = SendMessageA(.Handle,TB_ISBUTTONCHECKED,LoWord(wParam&),0)
                             MemCpy .TB.dwData,.ToolButton,SizeOf(This.ToolButton)
                          End If
                       End If
                    End If
                    If .OnButtonClick Then CallFunc .OnButtonClick,Index
                 End If
              End If
         Case WM_NOTIFY
              MemCpy .NM,LParam&,SizeOf(This.NM)
              If .NM.code = TTN_NEEDTEXT Then
                 MemCpy .TTX,LParam&,SizeOf(This.TTX)
                 Index = .GetIndex(.TTx.hdr.idFrom)
                 MemCpy .TB,.Button(Index),SizeOf(This.TB)
                 If .TB.dwData Then
                    MemCpy .ToolButton,.TB.dwData,SizeOf(This.ToolButton)
                    If .ToolButton.ShowHint Then
                       .TTx.lpszText = .ToolButton.Hint
                       MemCpy LParam&,.TTX,SizeOf(This.TTX)
                    End If
                 End If
              End If
              If .NM.code = TBN_DROPDOWN Then
                 MemCpy .TBn,LParam&,SizeOf(This.TBn)
                 If .Tbn.iItem <> -1 Then
                    SendMessage(.Tbn.hdr.hwndFrom,TB_GETRECT,.Tbn.iItem,.R)
                    MapWindowPoints(.Tbn.hdr.hwndFrom,0,.R,2)
                    index = SendMessageA(.Tbn.hdr.hwndFrom,TB_COMMANDTOINDEX,.Tbn.iItem,0)
                    If SendMessageA(.Tbn.hdr.hwndFrom,TB_GETBUTTON,index,.TB) Then
                       If .TB.dwData Then
                          MemCpy .ToolButton,.TB.dwData,SizeOf(This.ToolButton)
                          TrackPopupMenu(.ToolButton.DropDown,0,.R.Left,.R.Bottom,0,.Tbn.hdr.hwndFrom,0)
                       End If
                    End If
                 End If
              End If
         End Select
         Result = CallWindowProc(.LastParentProc,hWnd&,Msg&,wParam&,lParam&)
     End Function
     
     Function WndProc(hWnd&,Msg&,wParam&,lParam&) As Integer
         Select Case Msg&
         Case WM_RBUTTONDOWN
              .P.x = LoWord(lParam&)
              .P.y = HiWord(lParam&)
              ClientToScreen(.Handle,.P)
              TrackPopupMenu(.PopupMenu.Handle,0,.P.x,.P.y,0,.Handle,0)
         Case WM_COMMAND
              If .OnCommand Then CallFunc .OnCommand,HiWord(wParam&),LoWord(wParam&),lParam&
         End Select
         Result = CallWindowProc(.ClassProc,hWnd&,Msg&,wParam&,lParam&)
     End Function
     
     Sub Register
         DefInt F4,ClassProc
         Dim Wc As WNDCLASS
         Bind F4 To This.WndProc
         .NewProc = SetNewCallBack_4(F4)
         Bind F4 To This.ParentWndProc
         .ParentProc = SetNewCallBack_4(F4)
         InitCommonControls
         If GetClassInfo(0,"ToolBarWindow32",Wc) Then
            .ClassProc = Wc.lpfnWndProc
            If GetClassInfo(GetModuleHandle(0),"QToolBar",Wc) = 0 Then
               Wc.lpfnWndProc   = .NewProc
               Wc.lpszClassName = NewZStr("QToolBar")
               Wc.hInstance     = GetModuleHandle(0)
               RegisterClass(Wc)
            End If
         End If
     End Sub
     
     End With
     
     Constructor
     Register
     IDCommand   = 10
     Autosize    = 1
     Visible     = 1
     Transparent = 1
     Width       = 221
     Height      = 26
     End Constructor
End Type
