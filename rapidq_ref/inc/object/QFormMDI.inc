'=======================================================
' Type Objet
' Classe QFormMDI Version 1.0
'=======================================================
$IFNDEF TRUE
  $DEFINE True 1
$ENDIF

$IFNDEF FALSE
  $DEFINE False 0
$ENDIF

$IFNDEF boolean
  $DEFINE boolean integer
$ENDIF

TYPE MDI_CLASS
    cbSize AS LONG
    style AS LONG
    lpfnWndProc AS LONG
    cbClsExtra AS LONG
    cbWndExtra AS LONG
    hInstance AS LONG
    hIcon AS LONG
    hCursor AS LONG
    hbrBackground AS LONG
    lpszMenuName AS LONG
    lpszClassName AS LONG
    hIconSm AS LONG
END TYPE

Declare Function MDI_RegisterClass LIB "User32" ALIAS "RegisterClassExA" (pcWndClassEx AS MDI_CLASS) AS LONG
Declare Function MDI_EnumChild LIB "User32" ALIAS "EnumChildWindows" (hWndParent AS LONG,lpEnumFunc AS LONG,lParam AS LONG) AS LONG
Declare Function MDI_CreateWindow LIB "User32" ALIAS "CreateWindowExA" (dwExStyle AS LONG,lpClassName AS STRING,lpWindowName AS STRING,dwStyle AS LONG,x AS LONG,y AS LONG,nWidth AS LONG,nHeight AS LONG,hWndParent AS LONG,hMenu AS LONG,hInstance AS LONG,lpParam AS LONG) AS LONG
Declare Function MDI_DefChildProc LIB "User32" ALIAS "DefMDIChildProcA" (hWnd AS LONG,uMsg AS LONG,wParam AS LONG,lParam AS LONG) AS LONG
Declare Function MDI_GetClassName LIB "User32" ALIAS "GetClassNameA" (hwnd AS LONG,ByRef lpClassName AS STRING,nMaxCount AS LONG) AS LONG
Declare Function MDI_SetProp LIB "User32" ALIAS "SetPropA" (hwnd AS LONG,lpString AS STRING,hData AS LONG) AS LONG
Declare Function MDI_GetProp LIB "User32"  ALIAS "GetPropA" (hwnd AS LONG,lpString AS STRING) AS LONG
Declare Function MDI_GetClientRect LIB "User32" ALIAS "GetClientRect" (hwnd AS LONG,lpRect AS QRECT) AS LONG
Declare Function MDI_MoveWindow LIB "User32" ALIAS "MoveWindow" (hwnd AS LONG,x AS LONG,y AS LONG,nWidth AS LONG,nHeight AS LONG,bRepaint AS LONG) AS LONG
Declare Function MDI_SetLong LIB "User32" ALIAS "SetWindowLongA" (hwnd AS LONG,nIndex AS LONG,dwNewLong AS LONG) AS LONG
Declare Function MDI_GetText LIB "User32" ALIAS "GetWindowTextA" (hwnd AS LONG,ByRef lpString AS STRING,cch AS LONG) AS LONG
Declare Function MDI_SetText LIB "user32" ALIAS "SetWindowTextA" (hWnd AS LONG,lpString AS STRING) AS LONG
Declare Function MDI_SetFocus LIB "User32" ALIAS "SetFocus" (hwnd AS LONG) AS LONG
Declare Function MDI_SetParent Lib "user32" Alias "SetParent" (hWndChild As Long,hWndNewParent As Long) As Long
Declare Function MDI_GetParent Lib "user32" Alias "GetParent" (hwnd As Long) As Long
Declare Function MDI_GetRect LIB "user32" ALIAS "GetWindowRect" (hwnd AS LONG, lpRect AS QRECT) AS LONG
Declare Function MDI_isIconic Lib "user32" Alias "IsIconic" (hwnd As Long) As Long
Declare Function MDI_isZoomed Lib "user32" Alias "IsZoomed" (hwnd As Long) As Long
Declare Function MDI_GetTextLenght Lib "user32" Alias "GetWindowTextLengthA" (hwnd As Long) As Long
Declare Function MDI_SendMessage Lib "user32" Alias "SendMessageA" (hwnd As Long, wMsg As Long, wParam As Long, lParam As Long) As Long
Declare Function MDI_SetClassLong Lib "user32" Alias "SetClassLongA" (hwnd As Long,nIndex As Long,dwNewLong As Long) As Long
Declare Function MDI_ShowWindow Lib "user32" Alias "ShowWindow" (hwnd As Long,nCmdShow As Long) As Long


'styles
Const MDI_EX_MDICHILD=&H40
Const MDI_CHILD=&H40000000
Const MDI_VISIBLE=&H10000000
Const MDI_OVERLAPPED=&H0
Const MDI_CAPTION=&HC00000
Const MDI_SYSMENU=&H80000
Const MDI_THICKFRAME=&H40000
Const MDI_MINIMIZEBOX=&H20000
Const MDI_MAXIMIZEBOX=&H10000
Const MDI_OVERLAPPEDWINDOW=(MDI_OVERLAPPED OR MDI_CAPTION OR MDI_SYSMENU OR MDI_THICKFRAME OR MDI_MINIMIZEBOX OR MDI_MAXIMIZEBOX)

'messages
Const MDI_MOVE = &H3
Const MDI_CLOSE=&H10
Const MDI_CREATE=&H1
Const MDI_DESTROY=&H2
Const MDI_SIZE=&H5
Const MDI_SYSCOMMAND=&H112
Const MDI_MDIDESTROY=&H221
Const MDI_MDIRESTORE=&H223
Const MDI_MDIMAXIMIZE=&H225
Const MDI_MDITILE=&H226
Const MDI_MDICASCADE=&H227
Const MDI_MDIICONARRANGE=&H228
Const MDI_MDIACTIVATE=&H222
Const MDI_MDISETMENU=&H230
Const MDI_MDINEXT=&H224
Const MDI_MDIGETACTIVE = &H229
Const MDI_CHILDACTIVATE = &H22
Const MDI_TILE_VERTICAL=&H0
Const MDI_TILE_HORIZONTAL=&H1

Const MDI_HWND_DESKTOP=0
Const MDI_USEDEFAULT=&H80000000
Const MDI_MINIMIZE=&HF020
Const MDI_MAXIMIZE = &HF030
Const MDI_HWNDPARENT=-8
Const MDI_HICON=-14
Const MDI_COLOR_WINDOW=5
Const MDI_COLOR_BACKGROUND=1
Const MDI_COLOR_WINDOWFRAME=6
Const MDI_COLOR_APPWORKSPACE=12
Const MDI_COLOR_HIGHLIGHT=13

'Events
Declare Sub OnChildClose_eventTemplate(handleChild as long,index as integer,titleChild as string)
Declare Sub OnChildActive_eventTemplate(handleChild as long,index as integer,titleChild as string)
Declare Sub OnChildResize_eventTemplate(handleChild as long,index as integer,titleChild as string)


TYPE QFormMDI EXTENDS QFORM
  Private:
    hClient as long
    hChild(1024) as long
    hComponent as long
    ClassName as string
    ChildClass AS MDI_CLASS
    Rect AS QRECT
    style as long
  Public:
    ChildCaption as string PROPERTY SET SetChildCaption
    ChildHandle as long PROPERTY SET SetChildHandle
    ComponentIndex as integer PROPERTY SET SetComponentIndex
    ChildTop as short PROPERTY SET SetChildTop
    ChildLeft as short PROPERTY SET SetChildLeft
    ChildWidth as short PROPERTY SET SetChildWidth
    ChildHeight as short PROPERTY SET SetChildHeight
    MdiMenu as long PROPERTY SET SetMdiMenu
    ChildMax as integer PROPERTY SET SetChildMax
    ChildCount as integer PROPERTY SET SetChildCount
    ChildState as integer PROPERTY SET SetChildState
    ChildIcon as long PROPERTY SET SetChildIcon
    ChildResult as integer
    OnChildClose as EVENT(OnChildClose_eventTemplate)
    OnChildActive as EVENT(OnChildActive_eventTemplate)
    OnChildResize as EVENT(OnChildResize_eventTemplate)
  
  Private:

  '========================================================
  ' Fonction callback recherche handle fenetre client MDI
  '========================================================
  Function EnumClient(hWnd as long,lParam as long) as long
    dim Buffer as string

    Buffer=Space$(255)
    MDI_GetClassName(hWnd,Buffer,255)
    if INSTR(UCASE$(Buffer),"MDICLIENT") then QFormMDI.hClient=hWnd
    Result=True
  End Function

  '========================================================
  ' Fonction callback recherche handle fenetre fille MDI
  '========================================================
  Function EnumChild(hWnd as long,lParam as long) as long
    dim Buffer as string

    Buffer=Space$(255)
    MDI_GetClassName(hWnd,Buffer,255)
    if INSTR(UCASE$(Buffer),"MDICHILD") then
      if QFormMDI.ChildCount>0 then
        if hwnd<>QFormMDI.hChild(QFormMDI.ChildCount-1) then
          QFormMDI.hChild(QFormMDI.ChildCount)=hWnd
          QFormMDI.ChildCount++
        end if
      else
        QFormMDI.hChild(QFormMDI.ChildCount)=hWnd
        QFormMDI.ChildCount++
      end if
    end if
    Result=true
  End Function

  '========================================================
  ' Procedure adaptation dimentions fenetre fille MDI
  '========================================================
  Sub GetSizeChild(hwnd as long)
    dim Rc as QRect
    dim Rw as QRect
    dim borderX as short
    dim borderY as short
    dim top as short
    dim left as short

    MDI_GetClientRect(QFormMDI.hClient,Rc)
    MDI_GetRect(QFormMDI.hClient,Rw)
    top=Rw.top
    left=Rw.left
    borderX=((Rw.Right-Rw.Left)-Rc.Right)/2
    borderY=((Rw.Bottom-Rw.Top)-Rc.Bottom)/2
    MDI_GetRect(hWnd,Rw)
    QFormMDI.ChildLeft=Rw.Left-(left+borderX)
    QFormMDI.ChildTop=Rw.Top-(top+borderY)
    QFormMDI.ChildWidth=Rw.Right-Rw.Left
    QFormMDI.ChildHeight=Rw.Bottom-Rw.Top
  End Sub

  '========================================================
  ' Fonction retourne etat fenetre fille MDI
  '========================================================
  Function GetState(hwnd as long) as short
    if MDI_isIconic(hwnd) then
      result=1
    elseif MDI_isZoomed(hwnd) then
      result=2
    else
      result=0
    end if
  End Function

  '========================================================
  ' Fonction retourne le texte caption d'une fenetre MDI
  '========================================================
  Function GetTextChild(hwnd as long) as string
    dim size as integer
    dim buffer as string    

    size=MDI_GetTextLenght(hwnd)
    buffer=Space$(size)+chr$(0)
    size=MDI_GetText(hwnd,buffer,Len(buffer))
    result=Left$(buffer,size)
  End Function
  
public:
  '========================================================
  ' Procedure de fenetre enfant MDI
  '========================================================
  Function ChildProc(hWnd as long,uMsg as long,wParam as long,lParam as long) as long
    Select Case uMsg
    Case MDI_CREATE
      MDI_SetParent(QFormMDI.hComponent,hWnd)
      MDI_ShowWindow(QFormMDI.hComponent,true)
      MDI_SetProp(hWnd,"EditHandle",QFormMDI.hComponent)
      MDI_SetProp(hWnd,"EditIndex",QFormMDI.ComponentIndex)
      QFormMDI.ChildCount++
      if QFormMDI.MdiMenu>0 then SendMessage(QFormMDI.hClient,MDI_MDISETMENU,0,QFormMDI.MdiMenu)
      Result=MDI_DefChildProc(hWnd,uMsg,wParam,lParam)
    Case MDI_SIZE
      QFormMDI.hComponent=MDI_GetProp(hWnd,"EditHandle")
      QFormMDI.ComponentIndex=MDI_GetProp(hWnd,"EditIndex")
      QFormMDI.ChildCaption=QFormMDI.GetTextChild(hwnd)
      MDI_GetClientRect(hWnd,QFormMDI.Rect)
      MDI_MoveWindow(QFormMDI.hComponent,0,0,QFormMDI.Rect.Right,QFormMDI.Rect.Bottom,True)
      QFormMDI.GetSizeChild(hwnd)
      if QFormMDI.OnChildResize<>0 then CALLFUNC(QFormMDI.OnChildResize,hwnd,QFormMDI.ComponentIndex,QFormMDI.ChildCaption)
      Result=MDI_DefChildProc(hWnd,uMsg,wParam,lParam)
    Case MDI_MDIACTIVATE
      QFormMDI.ChildHandle=hWnd
      QFormMDI.ChildCaption=QFormMDI.GetTextChild(hwnd)
      QFormMDI.GetSizeChild(hwnd)
      MDI_SetFocus(MDI_GetProp(lParam,"EditHandle"))
      QFormMDI.ComponentIndex=MDI_GetProp(hWnd,"EditIndex")
      QFormMDI.ChildState=QFormMDI.GetState(hwnd)
      if QFormMDI.OnChildActive<>0 then CALLFUNC(QFormMDI.OnChildActive,hwnd,QFormMDI.ComponentIndex,QFormMDI.ChildCaption)
      Result=MDI_DefChildProc(hWnd,uMsg,wParam,lParam)
    Case MDI_CLOSE
      QFormMDI.ChildResult=True
      QFormMDI.ChildCaption=QFormMDI.GetTextChild(hwnd)
      QFormMDI.ComponentIndex=MDI_GetProp(hWnd,"EditIndex")
      if QFormMDI.OnChildClose<>0 then CALLFUNC(QFormMDI.OnChildClose,hwnd,QFormMDI.ComponentIndex,QFormMDI.ChildCaption)
      if QFormMDI.ChildResult>0 then
        Result=MDI_DefChildProc(hWnd,uMsg,wParam,lParam)
      else
        Result=False
      end if
    Case MDI_DESTROY
      QFormMDI.hComponent=MDI_GetProp(hWnd,"EditHandle")
      MDI_MoveWindow(QFormMDI.hComponent,0,0,0,0,0)
      MDI_ShowWindow(QFormMDI.hComponent,false)
      MDI_SetParent(QFormMDI.hComponent,QFormMDI.handle)
      QFormMDI.ChildCount--
      Result=MDI_DefChildProc(hWnd,uMsg,wParam,lParam)
    Case MDI_MOVE
      QFormMDI.GetSizeChild(hwnd)
      Result=MDI_DefChildProc(hWnd,uMsg,wParam,lParam)
    Case else
      if QFormMDI.ChildCount>0 then
        QFormMDI.ChildState=QFormMDI.GetState(hwnd)
      end if
      Result=MDI_DefChildProc(hWnd,uMsg,wParam,lParam)
    End Select
  End Function

  Public:

  '========================================================
  ' Proprietй nombre max fenetre fille MDI
  '========================================================
  Property Set SetChildMax(number as integer)
    if number<=1024 then QFormMDI.ChildMax=number
  End Property

  '========================================================
  ' Proprietй icon fenetre fille MDI
  '========================================================
  Property Set SetChildIcon(handle as long)
    if QFormMDI.ChildCount>0 then
      MDI_SetClassLong(QFormMDI.ChildHandle,MDI_HICON,handle)
    else
      QFormMDI.ChildClass.hIcon=handle
      QFormMDI.ChildClass.hIconSm=handle
    end if
  End Property

  '========================================================
  ' Proprietй caption fenetre fille MDI active
  '========================================================
  Property Set SetChildCaption(caption as string)
    if QFormMDI.ChildCount>0 then
      QFormMDI.ChildCaption=caption
      MDI_SetText(QFormMDI.ChildHandle,QFormMDI.ChildCaption)
    end if
  End Property  

  '========================================================
  ' Proprietй handle fenetre fille MDI active
  '========================================================
  Property Set SetChildHandle(handle as long)
    'lecture uniquement
  End Property  

  '========================================================
  ' Proprietй index composant fenetre fille MDI active
  '========================================================
  Property Set SetComponentIndex(index as integer)
    'lecture uniquement
  End Property  

  '========================================================
  ' Proprietй top fenetre fille MDI active
  '========================================================
  Property Set SetChildTop(top as short)
    if QFormMDI.ChildCount>0 then
      QFormMDI.ChildTop=top
      MDI_MoveWindow(QFormMDI.ChildHandle,QFormMDI.ChildLeft,QFormMDI.ChildTop,QFormMDI.ChildWidth,QFormMDI.ChildHeight,True)
    end if
  End Property  

  '========================================================
  ' Proprietй left fenetre fille MDI active
  '========================================================
  Property Set SetChildLeft(left as short)
    if QFormMDI.ChildCount>0 then
      QFormMDI.ChildLeft=left
      MDI_MoveWindow(QFormMDI.ChildHandle,QFormMDI.ChildLeft,QFormMDI.ChildTop,QFormMDI.ChildWidth,QFormMDI.ChildHeight,True)
    end if
  End Property  

  '========================================================
  ' Proprietй width fenetre fille MDI active
  '========================================================
  Property Set SetChildWidth(width as short)
    if QFormMDI.ChildCount>0 then
      QFormMDI.ChildWidth=width
      MDI_MoveWindow(QFormMDI.ChildHandle,QFormMDI.ChildLeft,QFormMDI.ChildTop,QFormMDI.ChildWidth,QFormMDI.ChildHeight,True)
    end if
  End Property  

  '========================================================
  ' Proprietй height fenetre fille MDI active
  '========================================================
  Property Set SetChildHeight(height as short)
    if QFormMDI.ChildCount>0 then
      QFormMDI.ChildHeight=height
      MDI_MoveWindow(QFormMDI.ChildHandle,QFormMDI.ChildLeft,QFormMDI.ChildTop,QFormMDI.ChildWidth,QFormMDI.ChildHeight,True)
    end if
  End Property  

  '========================================================
  ' Proprietй handle menu fenetre fille MDI
  '========================================================
  Property Set SetMdiMenu(MenuHandle as long)
      if MenuHandle>0 then QFormMDI.MdiMenu=MenuHandle
  End Property  

  '========================================================
  ' Proprietй nombre fenetre fille MDI
  '========================================================
  Property Set SetChildCount(index as integer)
    'lecture uniquement
  End Property  

  '========================================================
  ' Proprietй etat fenetre fille MDI active
  '========================================================
  Property Set SetChildState(state as integer)
    if QFormMDI.ChildCount>0 then
      QFormMDI.ChildState=state
      if state=1 then
        SendMessage(QFormMDI.ChildHandle,MDI_SYSCOMMAND,MDI_MINIMIZE,0)
      elseif state=2 then
        SendMessage(QFormMDI.hClient,MDI_MDIMAXIMIZE,QFormMDI.ChildHandle,0)
        MDI_SetFocus(MDI_GetProp(QFormMDI.ChildHandle,"EditHandle"))
      else
        SendMessage(QFormMDI.hClient,MDI_MDIRESTORE,QFormMDI.ChildHandle,0)
        MDI_SetFocus(MDI_GetProp(QFormMDI.ChildHandle,"EditHandle"))
      end if
    end if
  End Property  
  
  '========================================================
  ' Mйthode addition d'une fenetre fille MDI
  '========================================================
  Sub AddChild(handle as long,Title as string,index as integer,Left as short,Top as short,Width as short,Height as short,DefaultSize as boolean)
    'init client MDI
    if QFormMDI.hClient=0 then
      QFormMDI.ChildClass.cbSize=SIZEOF(QFormMDI.ChildClass)
      QFormMDI.ChildClass.lpfnWndProc=CODEPTR(QFormMDI.ChildProc)
      QFormMDI.ChildClass.hbrBackground=MDI_COLOR_WINDOWFRAME
      QFormMDI.ChildClass.lpszClassName=VARPTR(QFormMDI.ClassName)
      'QFormMDI.ChildClass.hinstance=application.hinstance
      MDI_RegisterClass(QFormMDI.ChildClass)
      MDI_EnumChild(QFormMDI.Handle,CODEPTR(QFormMDI.EnumClient),0)
    end if
    if QFormMDI.ChildCount<QFormMDI.ChildMax and handle<>0 then
      QFormMDI.hComponent=handle
      QFormMDI.ComponentIndex=index
      QFormMDI.style=MDI_CHILD OR MDI_VISIBLE OR MDI_OVERLAPPEDWINDOW
      if DefaultSize=True then
        'QFormMDI.hChild(QFormMDI.ChildCount)=MDI_CreateWindow(MDI_EX_MDICHILD,QFormMDI.ClassName,Title,QFormMDI.style,MDI_USEDEFAULT,MDI_USEDEFAULT,MDI_USEDEFAULT,MDI_USEDEFAULT,QFormMDI.hClient,0,application.hinstance,0)
        QFormMDI.hChild(QFormMDI.ChildCount)=MDI_CreateWindow(MDI_EX_MDICHILD,QFormMDI.ClassName,Title,QFormMDI.style,MDI_USEDEFAULT,MDI_USEDEFAULT,MDI_USEDEFAULT,MDI_USEDEFAULT,QFormMDI.hClient,0,0,0)
      else
        'QFormMDI.hChild(QFormMDI.ChildCount)=MDI_CreateWindow(MDI_EX_MDICHILD,QFormMDI.ClassName,Title,QFormMDI.style,Left,Top,Width,Height,QFormMDI.hClient,0,application.hinstance,0)
        QFormMDI.hChild(QFormMDI.ChildCount)=MDI_CreateWindow(MDI_EX_MDICHILD,QFormMDI.ClassName,Title,QFormMDI.style,Left,Top,Width,Height,QFormMDI.hClient,0,0,0)
      end if
    end if
  End Sub

  '========================================================
  ' Mйthode fermeture fenetre fille MDI active
  '========================================================
  Sub CloseChild
    if QFormMDI.ChildCount>0 then
      QFormMDI.ChildResult=True
      QFormMDI.ChildHandle=MDI_SendMessage(QFormMDI.hClient,MDI_MDIGETACTIVE,0,0)
      QFormMDI.ComponentIndex=MDI_GetProp(QFormMDI.ChildHandle,"EditIndex")
      QFormMDI.ChildCaption=QFormMDI.GetTextChild(QFormMDI.ChildHandle)
      if QFormMDI.OnChildClose<>0 then CALLFUNC(QFormMDI.OnChildClose,QFormMDI.CHildHandle,QFormMDI.ComponentIndex,QFormMDI.ChildCaption)
      if QFormMDI.ChildResult>0 then
        SendMessage(QFormMDI.hClient,MDI_MDIDESTROY,QFormMDI.ChildHandle,0)
      end if
      if QFormMDI.ChildCount>0 then
        QFormMDI.ChildHandle=MDI_SendMessage(QFormMDI.hClient,MDI_MDIGETACTIVE,0,0)
        QFormMDI.ComponentIndex=MDI_GetProp(QFormMDI.ChildHandle,"EditIndex")
        QFormMDI.ChildCaption=QFormMDI.GetTextChild(QFormMDI.ChildHandle)
        QFormMDI.ChildState=QFormMDI.GetState(QFormMDI.ChildHandle)
        QFormMDI.GetSizeChild(QFormMDI.ChildHandle)
        MDI_SetFocus(MDI_GetProp(QFormMDI.ChildHandle,"EditHandle"))
      end if
    end if
  End Sub

  '========================================================
  ' Mйthode fermeture fenetres fille MDI
  '========================================================
  Sub CloseAllChild 
    dim i as integer

    if QFormMDI.ChildCount>0 then
      QFormMDI.ChildCount=0
      MDI_EnumChild(QFormMDI.hClient,CODEPTR(QFormMDI.EnumChild),0)
      if QFormMDI.ChildCount>1 then
        for i=0 to QFormMDI.ChildCount-1
          QFormMDI.ChildResult=True
          QFormMDI.ComponentIndex=MDI_GetProp(QFormMDI.hChild(i),"EditIndex")
          QFormMDI.ChildCaption=QFormMDI.GetTextChild(QFormMDI.hChild(i))
          if QFormMDI.OnChildClose<>0 then CALLFUNC(QFormMDI.OnChildClose,QFormMDI.hChild(i),QFormMDI.ComponentIndex,QFormMDI.ChildCaption)
          if QFormMDI.ChildResult>0 then
            SendMessage(QFormMDI.hClient,MDI_MDIDESTROY,QFormMDI.hChild(i),0)
          end if
        next i
      else
        if QFormMDI.ChildCount>0 then
          QFormMDI.ChildResult=True
          QFormMDI.ComponentIndex=MDI_GetProp(QFormMDI.hChild(0),"EditIndex")
          QFormMDI.ChildCaption=QFormMDI.GetTextChild(QFormMDI.hChild(0))
          if QFormMDI.OnChildClose<>0 then CALLFUNC(QFormMDI.OnChildClose,QFormMDI.hChild(0),QFormMDI.ComponentIndex,QFormMDI.ChildCaption)
          if QFormMDI.ChildResult>0 then
            SendMessage(QFormMDI.hClient,MDI_MDIDESTROY,QFormMDI.hChild(0),0)
          end if
        end if
      end if
      if QFormMDI.ChildCount>0 then
        QFormMDI.ChildHandle=MDI_SendMessage(QFormMDI.hClient,MDI_MDIGETACTIVE,0,0)
        QFormMDI.ComponentIndex=MDI_GetProp(QFormMDI.ChildHandle,"EditIndex")
        QFormMDI.ChildCaption=QFormMDI.GetTextChild(QFormMDI.ChildHandle)
        QFormMDI.ChildState=QFormMDI.GetState(QFormMDI.ChildHandle)
        QFormMDI.GetSizeChild(QFormMDI.ChildHandle)
        MDI_SetFocus(MDI_GetProp(QFormMDI.ChildHandle,"EditHandle"))
      end if
    end if
  End Sub

  '========================================================
  ' Mйthode mise en cascade des fenetres fille MDI
  '========================================================
  Sub CascadeChild
    if QFormMDI.ChildCount>0 then
      SendMessage(QFormMDI.hClient,MDI_MDICASCADE,0,0)
    end if
  End Sub

  '========================================================
  ' Mйthode mise en horizontale fenetres fille MDI
  '========================================================
  Sub SetHorzChild
    if QFormMDI.ChildCount>0 then
      SendMessage(QFormMDI.hClient,MDI_MDITILE,MDI_TILE_HORIZONTAL,0)
    end if
  End Sub

  '========================================================
  ' Mйthode mise en verticale fenetres fille MDI
  '========================================================
  Sub SetVertChild
    if QFormMDI.ChildCount>0 then
      SendMessage(QFormMDI.hClient,MDI_MDITILE,MDI_TILE_VERTICAL,0)
    end if
  End Sub

  '========================================================
  ' Mйthode arrangement des fenetres fille MDI en icone
  '========================================================
  Sub IconArrangeChild
    if QFormMDI.ChildCount>0 then
      SendMessage(QFormMDI.hClient,MDI_MDIICONARRANGE,0,0)
    end if
  End Sub

  '========================================================
  ' Mйthode reduit en icone les fenetres fille MDI
  '========================================================
  Sub MinimizeAllChild
    dim i as integer

    if QFormMDI.ChildCount>0 then
      QFormMDI.ChildCount=0
      MDI_EnumChild(QFormMDI.hClient,CODEPTR(QFormMDI.EnumChild),0)
      for i=0 to QFormMDI.ChildCount-1
        SendMessage(QFormMDI.hChild(i),MDI_SYSCOMMAND,MDI_MINIMIZE,0)
      next i
      if QFormMDI.ChildCount>0 then
        QFormMDI.ChildHandle=MDI_SendMessage(QFormMDI.hClient,MDI_MDIGETACTIVE,0,0)
        QFormMDI.ComponentIndex=MDI_GetProp(QFormMDI.ChildHandle,"EditIndex")
        QFormMDI.ChildCaption=QFormMDI.GetTextChild(QFormMDI.ChildHandle)
        QFormMDI.ChildState=QFormMDI.GetState(QFormMDI.ChildHandle)
        QFormMDI.GetSizeChild(QFormMDI.ChildHandle)
        MDI_SetFocus(MDI_GetProp(QFormMDI.ChildHandle,"EditHandle"))
      end if
    end if
  End Sub

  '========================================================
  ' Mйthode met en taille maxi les fenetres fille MDI
  '========================================================
  Sub MaximizeAllChild
    dim i as integer

    if QFormMDI.ChildCount>0 then
      QFormMDI.ChildCount=0
      MDI_EnumChild(QFormMDI.hClient,CODEPTR(QFormMDI.EnumChild),0)
      for i=0 to QFormMDI.ChildCount-1
        SendMessage(QFormMDI.hClient,MDI_MDIMAXIMIZE,QFormMDI.hChild(i),0)
      next i
      if QFormMDI.ChildCount>0 then
        QFormMDI.ChildHandle=MDI_SendMessage(QFormMDI.hClient,MDI_MDIGETACTIVE,0,0)
        QFormMDI.ComponentIndex=MDI_GetProp(QFormMDI.ChildHandle,"EditIndex")
        QFormMDI.ChildCaption=QFormMDI.GetTextChild(QFormMDI.ChildHandle)
        QFormMDI.ChildState=QFormMDI.GetState(QFormMDI.ChildHandle)
        QFormMDI.GetSizeChild(QFormMDI.ChildHandle)
        MDI_SetFocus(MDI_GetProp(QFormMDI.ChildHandle,"EditHandle"))
      end if
    end if
  End Sub

  '========================================================
  ' Mйthode restauration taille des fenetres fille MDI
  '========================================================
  Sub RestoreChild
    dim i as integer

    if QFormMDI.ChildCount>0 then
      QFormMDI.ChildCount=0
      MDI_EnumChild(QFormMDI.hClient,CODEPTR(QFormMDI.EnumChild),0)
      for i=0 to QFormMDI.ChildCount-1
        SendMessage(QFormMDI.hClient,MDI_MDIRESTORE,QFormMDI.hChild(i),0)
      next i
      if QFormMDI.ChildCount>0 then
        QFormMDI.ChildHandle=MDI_SendMessage(QFormMDI.hClient,MDI_MDIGETACTIVE,0,0)
        QFormMDI.ComponentIndex=MDI_GetProp(QFormMDI.ChildHandle,"EditIndex")
        QFormMDI.ChildCaption=QFormMDI.GetTextChild(QFormMDI.ChildHandle)
        QFormMDI.ChildState=QFormMDI.GetState(QFormMDI.ChildHandle)
        QFormMDI.GetSizeChild(QFormMDI.ChildHandle)
        MDI_SetFocus(MDI_GetProp(QFormMDI.ChildHandle,"EditHandle"))
      end if
    end if
  End Sub

  '========================================================
  ' Mйthode active la fenetre fille MDI suivante
  '========================================================
  Sub ActiveNextChild
    if QFormMDI.ChildCount>0 then
      SendMessage(QFormMDI.hClient,MDI_MDINEXT,QFormMDI.ChildHandle,False)
    end if
  End Sub

  '========================================================
  ' Mйthode active la fenetre fille MDI prйcedente
  '========================================================
  Sub ActivePreviousChild
    if QFormMDI.ChildCount>0 then
      SendMessage(QFormMDI.hClient,MDI_MDINEXT,QFormMDI.ChildHandle,True)
    end if
  End Sub

  '========================================================
  ' Mйthode retourne index titre fenetre fille MDI 
  '========================================================
  Function GetChild(title as string) as integer
    dim i as integer
    dim index as integer

    if QFormMDI.ChildCount>0 then
      QFormMDI.ChildCount=0
      MDI_EnumChild(QFormMDI.hClient,CODEPTR(QFormMDI.EnumChild),0)
      index=0
      for i=0 to QFormMDI.ChildCount-1
        if title=QFormMDI.GetTextChild(QFormMDI.hChild(i)) then index=i
      next i
      result=index
    else
      result=0
    end if
  End Function

  '========================================================
  ' Mйthode retourne l'existence titre fenetre fille MDI 
  '========================================================
  Function ChildExist(title as string) as boolean
    dim i as integer
    dim exist as integer

    if QFormMDI.ChildCount>0 then
      QFormMDI.ChildCount=0
      MDI_EnumChild(QFormMDI.hClient,CODEPTR(QFormMDI.EnumChild),0)
      exist=False
      for i=0 to QFormMDI.ChildCount-1
        if title=QFormMDI.GetTextChild(QFormMDI.hChild(i)) then exist=True
      next i
      result=exist
    else
      result=False
    end if
  End Function


  '========================================================
  ' Mйthode active la fenetre fille MDI par index
  '========================================================
  Sub ActiveChild(index as integer)
    if QFormMDI.ChildCount>0 then
      SendMessage(QFormMDI.hClient,MDI_MDIACTIVATE,QFormMDI.hChild(index),0)
    end if
  End Sub

  '========================================================
  ' Mйthode retourne etat associй MDI d'un composant 
  '========================================================
  Function FreeChild(handle as long) as boolean
    if MDI_GetParent(handle)=QFormMDI.handle then
      result=True
    else
      result=False
    end if
  End Function
  
  '=============================================================================
  ' mйthode application dans barre outil bureau lors de la reduction fenetre
  '=============================================================================
  Sub SetDeskBar
    MDI_SetLong(QFormMDI.handle,MDI_HWNDPARENT,MDI_HWND_DESKTOP)
    MDI_SetLong(application.handle,MDI_HWNDPARENT,QFormMDI.handle)
  End Sub
    
  Constructor
    FormStyle=2
    Color=-2147483636
    ChildMax=1024
    ClassName="MDIChild"
    hClient=0
    ChildCount=0
  End Constructor
END TYPE
