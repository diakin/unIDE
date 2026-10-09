' Animate Component fo Rapidq
' Version 1.2 (stable)
' Coded by Nastase Eodor
' http://rqwork.evonet.ro
' mailTo: rqwork@evonet.ro

$DEFINE aviNone          0
$DEFINE aviFindFolder    150
$DEFINE aviFindFile      151
$DEFINE aviFindComputer  152
$DEFINE aviCopyFiles     160
$DEFINE aviCopyFile      161
$DEFINE aviRecycleFile   162
$DEFINE aviEmptyRecycle  163
$DEFINE aviDeleteFile    164

Declare Sub EventTemplate_Animate_Start(Sender&)
Declare Sub EventTemplate_Animate_Stop(Sender&)
Declare Sub EventTemplate_Animate_Paint(Sender&,Dc&)
Type QAnimate Extends QObject
     Private:
     NewProc        As Integer
     ClassProc      As Integer
     ParentProc     As Integer
     LastParentProc As Integer
     ParentWnd      As Integer
     ShellHandle    As Integer
     Background     As Integer
     WasOpened      As Integer
     WasPlaying     As Integer
     Public:
     Handle         As Integer
     Parent         As QForm   Property Set SetParent
     Parent2        As QPanel  Property Set SetParent2
     ParetWindow    As Integer Property Set SetParentWindow
     Left           As Integer Property Set SetLeft
     Top            As Integer Property Set SetTop
     Width          As Integer Property Set SetWidth
     Height         As Integer Property Set SetHeight
     Enabled        As Integer Property Set SetEnabled
     Visible        As Integer Property Set SetVisible
     Position       As Short   Property Set SetPosition
     BorderStyle    As Integer Property Set SetBorderStyle
     AutoPlay       As Integer Property Set SetAutoPlay
     Transparent    As Integer Property Set SetTransparent
     Center         As Integer Property Set SetCenter
     StartFrame     As Integer Property Set SetStartFrame
     StopFrame      As Integer Property Set SetStopFrame
     CommonAvi      As Integer Property Set SetCommonAvi
     File           As String  Property Set SetFile
     Repeat         As Integer Property Set SetRepeat
     Color          As Integer Property Set SetColor
     FrameCount     As Integer
     FrameWidth     As Integer
     FrameHeight    As Integer
     OnStart        As Event(EventTemplate_Animate_Start)
     OnStop         As Event(EventTemplate_Animate_Stop)
     OnPaint        As Event(EventTemplate_Animate_Paint)

     With This

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
     
     Sub GetAnimateInfo
         DefInt iResource,iGlobal,PResource,Size,Buff(18),i
         Dim Fs As QFileStream
         If .File <> "" Then
            Fs.Open(.File,0)
            For i = 0 To 17
                Buff(i) = Fs.ReadNum(4)
            Next i
            .FrameCount  = Buff(12)
            .FrameWidth  = Buff(16)
            .FrameHeight = Buff(17)
            FS.Close
         Else
            iResource = FindResource(.ShellHandle,.CommonAvi,"AVI")
            iGlobal   = LoadResource(.ShellHandle,iResource)
            PResource = LockResource(iGlobal)
            Size = SizeOfResource(.ShellHandle,iResource)
            If PResource Then
               ReDim P(Size) As Byte
               MemCpy VarPTR(P(0)),PResource,Size
               FreeResource(iResource)
               MemCpy VarPTR(Buff(0)),VarPTR(P(0)),18*SizeOf(Integer)
               .FrameCount  = Buff(12)
               .FrameWidth  = Buff(16)
               .FrameHeight = Buff(17)
            Else
               'Raise Error
            End If
         End If
     End Sub
     
     Sub Open
         If .Handle Then
            .WasOpened = 1
            If .CommonAVI = 0 Then
               If .File <> "" Then
                  SetWindowLong(.Handle,GWL_HINSTANCE,GetModuleHandle(0))
                  If FindResource(GetModuleHandle(0),NewZStr(.File),"AVI") Then
                     .GetAnimateInfo
                     If .Handle Then SendMessage(.Handle,ACM_OPEN,0,NewZStr(.File))
                  Else
                     .GetAnimateInfo
                     If .Handle Then SendMessage(.Handle,ACM_OPEN,0,NewZStr(.File))
                  End If
               End If
            ElseIf .CommonAVI <> 0 Then
               If FindResource(.ShellHandle,.CommonAvi,"AVI") Then
                  .GetAnimateInfo
                  If .Handle Then
                     SetWindowLong(.Handle,GWL_HINSTANCE,.ShellHandle)
                     SendMessage(.Handle,ACM_OPEN,0,.CommonAvi)
                  End If
               End If
            End If
         End If
     End Sub
     
     Sub Play
         If .Handle Then
            .Repaint
            .StartFrame = IIf(.StartFrame,.StartFrame,0)
            .StopFrame  = IIf(.StopFrame,.StopFrame,.FrameCount)
            SendMessage(.Handle,ACM_PLAY,.Repeat,MakeLong(.StartFrame,.StopFrame))
            .WasPlaying = 1
         End If
     End Sub
     
     Sub Stop
         If .Handle Then
             SendMessage(.Handle,ACM_STOP,0,0)
             .WasPlaying = 0
         End If
     End Sub
     
     Sub CreateWnd
         If .Handle Then Exit Sub
         DefInt ExStyle = IIf(.BorderStyle,WS_EX_CLIENTEDGE,0),Style = ws_child
         Style = Style Or IIf(.Transparent,ACS_TRANSPARENT,0)
         Style = Style Or IIf(.Center,ACS_CENTER,0)
         Style = Style Or IIf(.AutoPlay,ACS_AUTOPLAY,0)
         .Handle = CreateWindowEx(ExStyle,"QAnimate","",Style,.Left,.Top,.Width,.Height,.ParentWnd,0,GetModuleHandle(0),0)
         If .Handle Then
            ShowWindow(.Handle,IIf(.Visible,SW_SHOW,SW_HIDE))
         End If
     End Sub

     Sub ReCreateWnd
         DefInt i
         If .Handle Then
            DestroyWindow(.Handle)
            .Handle = 0
         End If
         .CreateWnd
         If .Handle Then
            If .WasOpened  Then .Open
            If .WasPlaying Then .Play
         End If
     End Sub
     
     Property Set SetTransparent(Value As Integer)
         .Transparent = Value
         .RecreateWnd
     End Property
     
     Property Set SetRepeat(Value As Integer)
         .Repeat = value
         .Stop
         .Play
     End Property
     
     Property Set SetStartFrame(Value As Integer)
         .StartFrame = value
         .Stop
         .Play
     End Property
     
     Property Set SetStopFrame(Value As Integer)
         .StopFrame = value
         .Stop
         .Play
     End Property
     
     Property Set SetCenter(Value As Integer)
         .Center = value
         .RecreateWnd
     End Property
     
     Property Set SetAutoplay(Value As Integer)
         .Autoplay = value
         .RecreateWnd
     End Property
     
     Property Set SetBorderStyle(Value As Integer)
         .BorderStyle = value
         .RecreateWnd
     End Property
     
     Property Set SetColor(Value As Integer)
         .Color = value
         If .Background Then
            DeleteObject(.Background)
            .Background = CreateSolidBrush(.Color)
         End If
     End Property
     
     Property Set SetFile(Value As String)
         .File = Value
         .CommonAvi = 0
         If .Handle Then .Open
     End Property
     
     Property Set SetCommonAvi(Value As Integer)
         .CommonAvi = Value
         If .Handle Then .Open
     End Property
     
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

     Property Set SetParentWindow(Value As Integer)
         .ParentWnd = Value
         If .Handle Then
            SetParent(.Handle,Value)
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
     
     Property Set SetEnabled(Value As Integer)
         .Enabled = Value
         If .Handle Then EnableWindow(.Handle,.Enabled)
     End Property

     Property Set SetVisible(Value As Integer)
         .Visible = value
         If .Handle Then ShowWindow(.Handle,IIf(.Visible,SW_SHOW,SW_HIDE))
     End Property

     Function ParentWndProc(hWnd&,Msg&,wParam&,lParam&) As Integer
         Result = CallWindowProc(.LastParentProc,hWnd&,Msg&,wParam&,lParam&)
         Select Case Msg&
         Case WM_COMMAND
              If HiWord(wParam&) = ACN_START Then
                 If .OnStart Then CallFunc .OnStart,lParam&
              ElseIf HiWord(wParam&) = ACN_STOP Then
                 If .OnStop Then CallFunc .OnStop, lParam&
              End If
         End Select
     End Function
     
     Function WndProc(hWnd&,Msg&,wParam&,lParam&) As Integer
         Result = CallWindowProc(.ClassProc,hWnd&,Msg&,wParam&,lParam&)
         Select Case Msg&
         Case WM_NCHITTEST
              Result = HTCLIENT
              Exit Function
         Case WM_PAINT
              If .OnPaint Then CallFunc .OnPaint, hWnd&, wParam&
              Result = 0
         Case WM_ERASEBKGND
              Dim R As Rect
              GetClientRect(hWnd&,R)
              FillRect(wParam&,R,.Background)
              Exit Function
         End Select
     End Function
     
     Sub Register
         DefInt F4,ClassProc
         Dim Wc As WNDCLASS
         InitCommonControls
         Bind F4 To This.WndProc
         .NewProc = SetNewCallBack_4(F4)
         Bind F4 To This.ParentWndProc
         .ParentProc = SetNewCallBack_4(F4)
         InitCommonControls
         If GetClassInfo(0,"SysAnimate32",Wc) Then
            .ClassProc = Wc.lpfnWndProc
            If GetClassInfo(GetModuleHandle(0),"QAnimate",Wc) = 0 Then
               Wc.lpfnWndProc   = .NewProc
               Wc.lpszClassName = NewZStr("QAnimate")
               Wc.hInstance     = GetModuleHandle(0)
               RegisterClass(Wc)
            End If
         End If
         .ShellHandle = GetModuleHandle(NewZStr("Shell32"))
         .Color       = GetSysColor(COLOR_WINDOW)
         .Background  = CreateSolidBrush(.Color)
     End Sub
     
     End With
     
     Constructor
     Register
     BorderStyle = 1
     Width       = 221
     Height      = 55
     Visible     = 1
     Position    = 0
     Repeat      = -1
     Transparent = 1
     CommonAvi   = aviNone
     End Constructor
End Type
