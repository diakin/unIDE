$IFNDEF TRUE
  $DEFINE True 1
$ENDIF

$IFNDEF FALSE
  $DEFINE False 0
$ENDIF

'$IFNDEF boolean
''  $DEFINE boolean integer
'ENDIF

DECLARE FUNCTION LoadLibrary LIB "KERNEL32" ALIAS "LoadLibraryA" _
                 (LibFileName AS STRING) AS LONG
dim hInst AS LONG
$DEFINE HWND INTEGER

'const WS_EX_CLIENTEDGE = &H200 ' Just some of the many API constants
'const WS_CHILD = &H40000000
'const WS_VISIBLE = &H10000000
'const WS_BORDER = &H800000

' Window Styles
Public Const WS_OVERLAPPED = &H0&
Public Const WS_POPUP = &H80000000
Public Const WS_CHILD = &H40000000
Public Const WS_MINIMIZE = &H20000000
Public Const WS_VISIBLE = &H10000000
Public Const WS_DISABLED = &H8000000
Public Const WS_CLIPSIBLINGS = &H4000000
Public Const WS_CLIPCHILDREN = &H2000000
Public Const WS_MAXIMIZE = &H1000000
Public Const WS_CAPTION = &HC00000                  '  WS_BORDER Or WS_DLGFRAME
Public Const WS_BORDER = &H800000
Public Const WS_DLGFRAME = &H400000
Public Const WS_VSCROLL = &H200000
Public Const WS_HSCROLL = &H100000
Public Const WS_SYSMENU = &H80000
Public Const WS_THICKFRAME = &H40000
Public Const WS_GROUP = &H20000
Public Const WS_TABSTOP = &H10000

Public Const WS_MINIMIZEBOX = &H20000
Public Const WS_MAXIMIZEBOX = &H10000

Public Const WS_TILED = WS_OVERLAPPED
Public Const WS_ICONIC = WS_MINIMIZE
Public Const WS_SIZEBOX = WS_THICKFRAME
Public Const WS_OVERLAPPEDWINDOW = (WS_OVERLAPPED Or WS_CAPTION Or WS_SYSMENU Or WS_THICKFRAME Or WS_MINIMIZEBOX Or WS_MAXIMIZEBOX)
Public Const WS_TILEDWINDOW = WS_OVERLAPPEDWINDOW

'
'   Common Window Styles
'  /


Public Const WS_POPUPWINDOW = (WS_POPUP Or WS_BORDER Or WS_SYSMENU)

Public Const WS_CHILDWINDOW = (WS_CHILD)

' Extended Window Styles
Public Const WS_EX_DLGMODALFRAME = &H1&
Public Const WS_EX_NOPARENTNOTIFY = &H4&
Public Const WS_EX_TOPMOST = &H8&
Public Const WS_EX_ACCEPTFILES = &H10&
Public Const WS_EX_TRANSPARENT = &H20&




Const SW_HIDE = 0
Const SW_SHOW = 5

DECLARE FUNCTION CreateRichEdit LIB "USER32" ALIAS "CreateWindowExA" _
       (ExStyle&, ClassName$, WindowName$, Style&, X&, Y&, _
          Width&, Height&, WndParent&, hMenu&, hInstance&, Param&) AS LONG

Declare Function MoveRichEdit Lib "user32" Alias "MoveWindow" _
(hwnd As Long,x As integer,y As integer,nWidth As integer, _
nHeight As integer,bRepaint As Long) As Long

Declare Function ShowRichEdit Lib "user32" Alias "ShowWindow" _
 (hwnd As Long,nCmdShow As Long) As Long


TYPE QRichEdit_api EXTENDS QObject

    PUBLIC:
      Parent  as integer PROPERTY SET SetParent
      left    as short   PROPERTY SET SetLeft
      Top     as short   PROPERTY SET SetTop
      Width   as short   PROPERTY SET SetWidth
      Height  as short   PROPERTY SET SetHeight
      Visible as integer PROPERTY SET SetVisible
      Handle  as integer

    
    PROPERTY SET SetVisible(visible as integer)
      QRichedit_api.visible=visible
      if visible=0 then
        ShowRichedit(QRichEdit_api.Handle,SW_HIDE)
      else
        ShowRichedit(QRichEdit_api.Handle,SW_SHOW)
      end if
    END PROPERTY

    PROPERTY SET SetLeft(left as short)
    with QRichEdit_api
      .Left=left
       MoveRichEdit(.Handle,.Left,.Top,.Width,.Height,true)
    end with
    END PROPERTY

    PROPERTY SET SetTop(top as short)
    with QRichEdit_api
      .Top=top
      MoveRichEdit(.Handle,.Left,.Top,.Width,.Height,true)
    end with
    END PROPERTY

    PROPERTY SET SetWidth(width as short)
   with QRichEdit_api
      .Width=width
    MoveRichEdit(.Handle,.Left,.Top,.Width,.Height,true)
    end with
    END PROPERTY

    PROPERTY SET SetHeight(height as short)
   with QRichEdit_api
      .Height=height
      MoveRichEdit(.Handle,.Left,.Top,.Width,.Height,true)
    end with
    END PROPERTY
    PROPERTY SET SetParent(parent as integer)
   with QRichEdit_api
       .Parent = parent
hInst = LoadLibrary("RICHED32.DLL")


.Handle = CreateRichEdit(WS_EX_CLIENTEDGE or WS_EX_MDICHILD or WS_EX_NOPARENTNOTIFY or _
WS_EX_OVERLAPPEDWINDOW or WS_EX_TRANSPARENT _
,"RichEdit","RichEdit_API", _
WS_CHILD OR WS_VISIBLE OR WS_BORDER, _
.left, .top, .width, .height, _
.Parent, 0, Application.hInstance,0)

'.Handle = CreateRichEdit(WS_EX_CLIENTEDGE _
',"RichEdit","RichEdit_API", _
'WS_CHILD OR WS_BORDER , _
'.left, .top, .width, .height, _
'.Parent, 0, Application.hInstance,0)
    .visible=1

    end with
    END PROPERTY

    constRUCTOR
   with QRichEdit_api
    Left=65
    Top=5
    Width=200
    Height=100
    visible=1
    end with
    END constRUCTOR

END TYPE
  