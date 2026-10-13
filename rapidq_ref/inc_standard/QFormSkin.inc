$IFNDEF __QFORMSKIN_INC   ' IncManager: include guard
$DEFINE __QFORMSKIN_INC
$Option Explicit

Const GWL_WNDPROC		= (-4)
Const GWL_HWNDPARENT	= (-8)
Const GWL_STYLE = (-16)
Const HWND_DESKTOP	= 0


Const WS_VISIBLE = &H10000000

CONST WM_PAINT = &H000F

Const WM_NCCREATE = &H81
Const WM_NCDESTROY = &H82
Const WM_NCCALCSIZE = &H83
Const WM_NCHITTEST = &H84
Const WM_NCPAINT = &H85
Const WM_NCACTIVATE = &H86


Const WM_KILLFOCUS = &H8
Const WM_MOUSEACTIVATE = &H21

Const WM_NCMOUSEMOVE = &HA0
Const WM_NCLBUTTONDOWN = &HA1
Const WM_NCLBUTTONUP = &HA2
Const WM_NCLBUTTONDBLCLK = &HA3
Const WM_NCRBUTTONDOWN = &HA4
Const WM_NCRBUTTONUP = &HA5
Const WM_NCRBUTTONDBLCLK = &HA6
Const WM_NCMBUTTONDOWN = &HA7
Const WM_NCMBUTTONUP = &HA8
Const WM_NCMBUTTONDBLCLK = &HA9

Const WM_MOUSEMOVE = &H200
Const WM_LBUTTONDOWN = &H201
Const WM_LBUTTONUP = &H202
Const WM_LBUTTONDBLCLK = &H203
Const WM_RBUTTONDOWN = &H204
Const WM_RBUTTONUP = &H205
Const WM_RBUTTONDBLCLK = &H206
Const WM_MBUTTONDOWN = &H207
Const WM_MBUTTONUP = &H208
Const WM_MBUTTONDBLCLK = &H209

CONST WM_USER = &H400
CONST WM_TRAYICON = WM_USER + 400

Const WM_SIZE = &H5
Const WM_SETTEXT = &HC

Const WM_SETCURSOR = &H20
Const WM_GETICON = &H7F

Const WM_SYSCOMMAND = &H112
Const WM_INITMENUPOPUP = &H117

' WM_NCHITTEST and MOUSEHOOKSTRUCT Mouse Position Codes
Const HTERROR = (-2)
Const HTTRANSPARENT = (-1)
Const HTNOWHERE = 0
Const HTCLIENT = 1
Const HTCAPTION = 2
Const HTSYSMENU = 3
Const HTGROWBOX = 4
Const HTSIZE = HTGROWBOX
Const HTMENU = 5
Const HTHSCROLL = 6
Const HTVSCROLL = 7
Const HTMINBUTTON = 8
Const HTMAXBUTTON = 9
Const HTLEFT = 10
Const HTRIGHT = 11
Const HTTOP = 12
Const HTTOPLEFT = 13
Const HTTOPRIGHT = 14
Const HTBOTTOM = 15
Const HTBOTTOMLEFT = 16
Const HTBOTTOMRIGHT = 17
Const HTBORDER = 18
Const HTREDUCE = HTMINBUTTON
Const HTZOOM = HTMAXBUTTON
Const HTSIZEFIRST = HTLEFT
Const HTSIZELAST = HTBOTTOMRIGHT
Const HTCLOSE = 20

Const WVR_VALIDRECTS = &H400

DECLARE FUNCTION SetWindowLong LIB "user32" ALIAS "SetWindowLongA" ( _
		ByVal hwnd AS Long, _
		ByVal nIndex AS Long, _
		ByVal dwNewLong AS LONG) AS LONG
Declare Function GetWindowLong Lib "user32" Alias "GetWindowLongA" ( _
		ByVal hwnd As Long, ByVal nIndex As Long) As Long
DECLARE FUNCTION CallWindowProc LIB "user32" ALIAS "CallWindowProcA" ( _
		ByVal lpPrevWndFunc As Long, _
		ByVal hwnd As Long, _
		ByVal Msg AS Long, _
		ByVal wParam As Long, _
		ByVal lParam As Long) As Long
Declare Function DefWindowProc Lib "user32" Alias "DefWindowProcA" ( _
		ByVal hWnd As Long, _
		ByVal wMsg As Long, _
		ByVal wParam As Long, _
		lParam As Long) As Long


Declare Function WindowProc ( ByVal hwnd As Long, _
		ByVal uMsg As Long, _
		ByVal wParam As Long, _
		ByVal lParam As Long ) As Long


Const SM_CYCAPTION = 4
Const SM_CXBORDER = 5
Const SM_CYBORDER = 6
Const SM_CXDLGFRAME = 7
Const SM_CYDLGFRAME = 8
CONST SM_CXSIZE = 30
CONST SM_CYSIZE = 31
CONST SM_CXFRAME = 32
CONST SM_CYFRAME = 33

DECLARE FUNCTION GetSystemMetrics LIB "user32" ALIAS "GetSystemMetrics" _
		(nIndex AS LONG) AS LONG

Type RECT
	Left As Long
	Top As Long
	Right As Long
	Bottom As Long
End Type
Type POINTAPI
	X As Long
	Y As Long
End Type
Type POINTS
	X As Integer
	Y As Integer
End Type

DECLARE FUNCTION GetWindowRect LIB "user32" ALIAS "GetWindowRect" _
		(hWnd AS LONG, lpRect AS Rect) AS LONG
Declare Function GetClientRect Lib "user32" Alias "GetClientRect" ( _
		ByVal hWnd As Long, lpRect As RECT) As Long
Declare Function SetRect Lib "user32" Alias "SetRect" ( _
        lpRect As RECT, _
        ByVal X1 As Long, ByVal Y1 As Long, _
        ByVal X2 As Long, ByVal Y2 As Long) As Long
Declare Function GetRgnBox Lib "gdi32.dll" Alias "GetRgnBox" ( _
		ByVal hRgn As Long, lpRect As RECT) As Long
Declare Function SetRectRgn Lib "gdi32.dll" Alias "SetRectRgn" ( _
		ByVal hRgn As Long, _
		ByVal X1 As Long, ByVal Y1 As Long, _
		ByVal X2 As Long, ByVal Y2 As Long) As Long
Declare Function CreateRectRgnIndirect Lib "gdi32" Alias "CreateRectRgnIndirect" (lpRect As RECT) As Long
Declare Function CreateRectRgn Lib "gdi32" Alias "CreateRectRgn" (ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long) As Long
Declare Function GetClipRgn Lib "gdi32" Alias "GetClipRgn" (ByVal hdc As Long, ByVal hRgn As Long) As Long
Declare Function SetWindowRgn Lib "user32" Alias "SetWindowRgn" (ByVal hWnd As Long, ByVal hRgn As Long, ByVal bRedraw As Integer) As Long
Declare Function SelectClipRgn Lib "gdi32" Alias "SelectClipRgn" (ByVal hdc As Long, ByVal hRgn As Long) As Long
Declare Function InvalidateRect Lib "user32" Alias "InvalidateRect" (ByVal hwnd As Long, lpRect As RECT, ByVal bErase As Long) As Long
Declare Function ValidateRect Lib "user32" Alias "ValidateRect" (ByVal hwnd As Long, lpRect As RECT) As Long
Declare Function InvalidateRgn Lib "user32" Alias "InvalidateRgn" (ByVal hwnd As Long, ByVal hRgn As Long, ByVal bErase As Long) As Long
Declare Function ValidateRgn Lib "user32" Alias "ValidateRgn" (ByVal hwnd As Long, ByVal hRgn As Long) As Long

Declare Function CreateEllipticRgn Lib "gdi32" Alias "CreateEllipticRgn" (ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long) As Long
Declare Function OffsetClipRgn Lib "gdi32" Alias "OffsetClipRgn" (ByVal hdc As Long, ByVal x As Long, ByVal y As Long) As Long

Declare Function ClientToScreen Lib "user32" Alias "ClientToScreen" (ByVal hwnd As Long, lpPoint As POINTAPI) As Long

DECLARE FUNCTION GetWindowDC LIB "user32" ALIAS "GetWindowDC" _
		(hWnd AS LONG) AS LONG
Declare Function ReleaseDC Lib "user32" Alias "ReleaseDC" ( _
		ByVal hwnd As Long, _
		ByVal hdc As Long) As Long

Declare Function DeleteObject Lib "gdi32" Alias "DeleteObject" (ByVal hObject As Long) As Long

Declare Function ReleaseCapture Lib "user32" Alias "ReleaseCapture" () As Long

Const ScrCopy = &HCC0020

Const DI_MASK = &H1
Const DI_IMAGE = &H2
Const DI_NORMAL = DI_MASK Or DI_IMAGE

Declare Function StretchBlt Lib "gdi32" Alias "StretchBlt" ( _
		ByVal hdc As Long, _
		ByVal x As Long, ByVal y As Long, _
		ByVal nWidth As Long, ByVal nHeight As Long, _
		ByVal hSrcDC As Long, _
		ByVal xSrc As Long, ByVal ySrc As Long, _
		ByVal nSrcWidth As Long, ByVal nSrcHeight As Long, _
		ByVal dwRop As Long) As Long

Declare Function ExtractIconEx Lib "shell32.dll" Alias "ExtractIconExA" ( _
		ByVal lpszFile As String, _
		ByVal nIconIndex As Long, _
		phiconLarge As Long, _
		phiconSmall As Long, _
		ByVal nIcons As Long) As Long
Declare Function DrawIcon Lib "user32" Alias "DrawIcon" (_
		ByVal hdc As Long, _
		ByVal x As Long, ByVal y As Long, _
		ByVal hIcon As Long) As Long
Declare Function DrawIconEx Lib "user32" Alias "DrawIconEx" ( _
		ByVal hdc As Long, _
		ByVal xLeft As Long, ByVal yTop As Long, _
		ByVal hIcon As Long, _
		ByVal cxWidth As Long, ByVal cyWidth As Long, _
		ByVal istepIfAniCur As Long, _
		ByVal hbrFlickerFreeDraw As Long, _
		ByVal diFlags As Long) As Long

Declare Function DestroyIcon Lib "user32" Alias "DestroyIcon" ( _
		ByVal hIcon As Long) As Long
Declare Function CopyImage Lib "user32.dll" Alias "CopyImage" ( _
		ByVal Handle As Long, _
		ByVal un1 As Long, _
		ByVal n1 As Long, ByVal n2 As Long, _
		ByVal un2 As Long) As Long

Declare Function DrawText Lib "user32" Alias "DrawTextA" ( _
		ByVal hdc As Long, _
		ByVal lpStr As String, _
		ByVal nCount As Long, _
		lpRect As RECT, _
		ByVal wFormat As Long) As Long
Declare Function SetTextColor Lib "gdi32" Alias "SetTextColor" ( _
		ByVal hdc As Long, ByVal crColor As Long) As Long
Declare Function SetBkMode Lib "gdi32" Alias "SetBkMode" ( _
		ByVal hdc As Long, ByVal nBkMode As Long) As Long

Declare Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" ( _
		pDest As Long, pSource As Long, ByVal ByteLen As Long)
Declare Function SendMessageAPI Lib "user32" Alias "SendMessageA" ( _
		ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, lParam As Long) As Long

Declare Function ExcludeUpdateRgn Lib "user32.dll" Alias "ExcludeUpdateRgn" ( _
		ByVal hdc As Long, ByVal hwnd As Long) As Long
Declare Function ExcludeClipRect Lib "gdi32.dll" Alias "ExcludeClipRect" ( _
		ByVal hdc As Long, _
		ByVal X1 As Long, ByVal Y1 As Long, _
		ByVal X2 As Long, ByVal Y2 As Long) As Long


Declare Function SetCursor Lib "user32" Alias "SetCursor" (ByVal hCursor As Long) _
	    As Long
Declare Function LoadCursor Lib "user32" Alias "LoadCursorA" _
	    (ByVal hInstance As Long, ByVal lpCursorName As Long) As Long

Const IDC_SIZENS = 32645&
Const IDC_SIZEWE = 32644&
Const IDC_SIZENWSE = 32642&
Const IDC_SIZENESW = 32643&


'mes variables globales
Dim adresse_mafonction As Long
'sauvegarde des adresses messages de windows pour mes 2 tools
Dim precedent_adresse_mainfrm As Long

adresse_mafonction = CODEPTR(WindowProc) 'instruction rapidQ (adressof en VB)

Sub SetODMenuHookEnabled(hWnd As Long, Enabled As Integer)
	If SetODMenuHookEnabled > 0 and precedent_adresse_mainfrm = 0 Then
		' on lance et on prend en note l'adresse de la procedure
		precedent_adresse_mainfrm = SetWindowLong (hWnd, GWL_WNDPROC, adresse_mafonction)
	ElseIf precedent_adresse_mainfrm <> 0 Then
		' on arrкte la procedure
		Call SetWindowLong(hWnd, GWL_WNDPROC, precedent_adresse_mainfrm)
	End If
End Sub

' Corrige le menu de la barre d'outil et ajoute aussi le support OwnerDraw
Sub FixTaskBar (hWnd As Long)
    SetWindowLong ( hWnd, GWL_HWNDPARENT, HWND_DESKTOP )
    SetWindowLong ( Application.Handle, GWL_HWNDPARENT, hWnd )
End Sub


Declare Sub GetInfoFromMenu (iCaption As String)



Type NCCALCSIZE_PARAMS  ' used when client rect needs to be calculated
   'rgrc(0 To 2) As RECT
   rgrc0Left As Long
   rgrc0Top As Long
   rgrc0Right As Long
   rgrc0Bottom As Long
   rgrc1Left As Long
   rgrc1Top As Long
   rgrc1Right As Long
   rgrc1Bottom As Long
   rgrc2Left As Long
   rgrc2Top As Long
   rgrc2Right As Long
   rgrc2Bottom As Long
   lppos As Long 'pointer to WINDOWPOS
End Type
Type WINDOWPOS          ' used when sizing or moving
   hWnd As Long
   hWndInsertAfter As Long
   X As Long
   Y As Long
   Cx As Long
   Cy As Long
   Flags As Long
End Type

Type MOVESIZE       ' Custom, used to track core window data
    wRgn As Long
    'wRect As RECT
    wRectLeft As Long
    wRectTop As Long
    wRectRight As Long
    wRectBottom As Long
    'mPts As POINTAPI
    mPtsX As Long
    mPtsY As Long
    hitTest As Long
    Action As Long
    Tag As Long
End Type

Dim SkinTop		As QBitmap, _
    SkinTop2	As QBitmap, _
    SkinMid		As QBitmap, _
    SkinBot		As QBitmap
Dim SkinBClose	As QBitmap, _
	SkinBMax	As QBitmap, _
	SkinBMin	As QBitmap, _
	SkinBHelp	As QBitmap, _
	SkinBTray	As QBitmap


Dim dc_Skin	As Long
Dim r_Skin	As RECT, _
	rc_Skin	As RECT, _
	r_bSkin	As RECT

Dim m_Position As MOVESIZE      ' tracks window size, hittest & current action

Dim Pt As POINTAPI
    
Dim hRgn_Client As Long

Dim Mem As QMemoryStream, _
	Mem2 As QMemoryStream

Dim s_CaptionY	As Integer, _
	s_BorderW	As Integer
	s_BorderW	= GetSystemMetrics(SM_CXDLGFRAME)
	s_CaptionY	= 24 'GetSystemMetrics(SM_CYCAPTION) +s_BorderW

Sub ConfigureNCandClient(hWnd As Long, lParam As Long)
	'Exit Function
            
	Dim tNCR As NCCALCSIZE_PARAMS
	Dim tWP As WINDOWPOS
	Dim m_Pos_wRect As RECT
	Dim tNCR_rgrc0 As RECT

    GetClientRect(hWnd, rc_Skin)
    Pt.X = rc_Skin.Left
    Pt.Y = rc_Skin.Top
    ClientToScreen(hWnd, Pt)
    'OffSetRect ...
    rc_Skin.Left = rc_Skin.Left +Pt.X
    rc_Skin.Right = rc_Skin.Left +rc_Skin.Right -8'+Pt.X
    rc_Skin.Top = rc_Skin.Top +Pt.Y
    rc_Skin.Bottom = rc_Skin.Top +rc_Skin.Bottom -8'+Pt.Y
    
	hRgn_Client = CreateRectRgnIndirect(rc_Skin)
	If hRgn_Client Then
	' Get the new window position & recommended client rect
    'CopyMemory tNCR, ByVal lParam, Len(tNCR)
	Mem.Position	= 0
	Mem.MemCopyFrom(lParam, SizeOf(tNCR))
	Mem.Position	= 0
	Mem.ReadUDT	(tNCR)

    'CopyMemory tWP, ByVal tNCR.lppos, Len(tWP)
	Mem2.Position	= 0
	Mem2.MemCopyFrom(tNCR.lppos, SizeOf(tWP))
	Mem2.Position	= 0
	Mem2.ReadUDT	(tWP)

	'SetRect m_Pos_wRect, m_Position.wRectLeft, m_Position.wRectTop, m_Position.wRectRight, m_Position.wRectBottom
	' set the new window rect here
    'SetRect m_Position.wRect, tWP.X, tWP.Y, tWP.X + tWP.Cx, tWP.Y + tWP.Cy
    SetRect m_Pos_wRect, tWP.X, tWP.Y, tWP.X + tWP.Cx, tWP.Y + tWP.Cy
	m_Position.wRectLeft = m_Pos_wRect.Left
    m_Position.wRectTop = m_Pos_wRect.Top
    m_Position.wRectRight = m_Pos_wRect.Right
    m_Position.wRectBottom = m_Pos_wRect.Bottom
    GetInfoFromMenu (STR$(m_Position.wRectLeft))
    GetInfoFromMenu (STR$(m_Position.wRectTop))
    GetInfoFromMenu (STR$(m_Position.wRectRight))
    GetInfoFromMenu (STR$(m_Position.wRectBottom))
    
	' calculate the client, titlebar, menubar, & nonclient button regions
    'CalculateBarRects False
       
	' use the calculated client region here (screen coords vs client coords)
    GetRgnBox hRgn_Client, tNCR_rgrc0 'tNCR.rgrc0
    tNCR.rgrc0Left = tNCR_rgrc0.Left
    tNCR.rgrc0Top = tNCR_rgrc0.Top
    tNCR.rgrc0Right = tNCR_rgrc0.Right
    tNCR.rgrc0Bottom = tNCR_rgrc0.Bottom

	' Return the new client area
    'tNCR.rgrc1 = tNCR.rgrc0
    tNCR.rgrc1Left = tNCR.rgrc0Left
    GetInfoFromMenu (STR$(tNCR.rgrc0Left))
    tNCR.rgrc1Top = tNCR.rgrc0Top
    GetInfoFromMenu (STR$(tNCR.rgrc0Top))
    tNCR.rgrc1Right = tNCR.rgrc0Right
    GetInfoFromMenu (STR$(tNCR.rgrc0Right))
    tNCR.rgrc1Bottom = tNCR.rgrc0Bottom
    GetInfoFromMenu (STR$(tNCR.rgrc0Bottom))
    'CopyMemory ByVal lParam, tNCR, Len(tNCR)
	Mem.Position	= 0
	Mem.WriteUDT	(tNCR)	'-- Write structure back to memory
	Mem.Position	= 0
	'-- Copy this structure back to the original address, so changes can take effect
	Mem.MemCopyTo	(lParam, SizeOf(tNCR))
	
	End If
	Mem.Close
	Mem2.Close
	If hRgn_Client Then DeleteObject hRgn_Client
	If m_Position.wRgn Then DeleteObject m_Position.wRgn
	SetRect m_Pos_wRect, 0, 0, -1, -1 ' reset to invalid value used in next line
	hRgn_Client = 0
	m_Position.wRgn = 0
    Pt.X = 0
    Pt.Y = 0
End Sub

Sub TitleBarMouseDown(hWnd As Long)
	Dim tPS As POINTS
	tPS.x = Screen.MouseX: tPS.y = Screen.MouseY
	ReleaseCapture
	SendMessageAPI hWnd, WM_NCLBUTTONDOWN, HTCAPTION, tPS
End Sub

Dim m_bActive As Integer

Sub DrawWindowBorders (hWnd As Long, wParam As Long)
	' Draw borders & caption
	'If uMsg = WM_NCACTIVATE and wParam Then
	'	DefWindowProc hWnd, uMsg, wParam, lParam
	'Else
		If SkinTop.Empty = 0 Then
			StretchBlt ( dc_Skin, _
				     s_BorderW, 0, _
				     (r_Skin.Right -r_Skin.Left) -((s_BorderW *2) +IIf(SkinTop2.Empty = 1 or m_bActive = -1, 0, SkinTop2.Width)), s_CaptionY, _
				     SkinTop.Handle, _
				     s_BorderW, IIf(m_bActive = 0, SkinTop.Height /2, 0), _
				     SkinTop.Width -(s_BorderW *2 +1), SkinTop.Height /2, _
				     ScrCopy)
			'If SkinTop2.Empty = 0 Then
			'	StretchBlt ( dc_Skin, _
			'		     (r_Skin.Right -r_Skin.Left) -(s_BorderW +SkinTop2.Width), 0, _
			'		     SkinTop2.Width, s_CaptionY, _
			'		     SkinTop2.Handle, _
			'		     0, 0, _
			'		     SkinTop2.Width, SkinTop2.Height, _
			'		     ScrCopy)
			'End If
			StretchBlt ( dc_Skin, _
				     0, 0, _
				     s_BorderW, s_CaptionY, _
				     SkinTop.Handle, _
				     0, IIf(m_bActive = 0, SkinTop.Height /2, 0), _
				     s_BorderW, SkinTop.Height /2, _
				     ScrCopy)
			StretchBlt ( dc_Skin, _
				     (r_Skin.Right -r_Skin.Left) -s_BorderW, 0, _
				     s_BorderW, s_CaptionY, _
				     SkinTop.Handle, _
				     SkinTop.Width -s_BorderW, IIf(m_bActive = 0, SkinTop.Height /2, 0), _
				     s_BorderW, SkinTop.Height /2, _
				     ScrCopy)
		End If
		If SkinMid.Empty = 0 Then
			StretchBlt ( dc_Skin, _
				     0, s_CaptionY, _
				     s_BorderW, (r_Skin.Bottom -r_Skin.Top) -s_BorderW -s_CaptionY, _
				     SkinMid.Handle, _
				     IIf(m_bActive = 0, SkinMid.Width /4, 0), 0, _
				     SkinMid.Width /4, SkinMid.Height, _
				     ScrCopy)
			StretchBlt ( dc_Skin, _
				     (r_Skin.Right -r_Skin.Left) -s_BorderW, s_CaptionY, _
				     s_BorderW, (r_Skin.Bottom -r_Skin.Top) -s_BorderW -s_CaptionY, _
				     SkinMid.Handle, _
				     IIf(m_bActive = 0, (SkinMid.Width /4) *3, (SkinMid.Width /4) *2), 0, _
				     SkinMid.Width /4, SkinMid.Height, _
				     ScrCopy)
		End If
		If SkinBot.Empty = 0 Then
			StretchBlt ( dc_Skin, _
				     s_BorderW, (r_Skin.Bottom -r_Skin.Top) -s_BorderW, _
				     (r_Skin.Right -r_Skin.Left) -(s_BorderW *2), s_BorderW, _
				     SkinBot.Handle, _
				     s_BorderW, IIf(m_bActive = 0, SkinBot.Height /2, 0), _
				     SkinBot.Width -(s_BorderW *2), SkinBot.Height /2, _
				     ScrCopy)
			StretchBlt ( dc_Skin, _
				     0, (r_Skin.Bottom -r_Skin.Top) -s_BorderW, _
				     s_BorderW, s_BorderW, _
				     SkinBot.Handle, _
				     0, IIf(m_bActive = 0, SkinBot.Height /2, 0), _
				     s_BorderW, SkinBot.Height /2, _
				     ScrCopy)
			StretchBlt ( dc_Skin, _
				     (r_Skin.Right -r_Skin.Left) -s_BorderW, (r_Skin.Bottom -r_Skin.Top) -s_BorderW, _
				     s_BorderW, s_BorderW, _
				     SkinBot.Handle, _
				     SkinBot.Width -s_BorderW, IIf(m_bActive = 0, SkinBot.Height /2, 0), _
				     s_BorderW, SkinBot.Height /2, _
				     ScrCopy)
		End If
	'End If
End Sub

Sub DrawIconText (hWnd As Long, wParam As Long)
	' Draw Icon
	'ExtractIconEx "shell32.dll", Cnt, mIcon, ByVal 0&, 1
	'DrawIcon Me.hdc, 32 * Cnt, 0, mIcon
	'DestroyIcon mIcon
	Dim hIcon As Long
	'Dim SmallIcon As Long
	$TypeCheck Off
	hIcon = SendMessageAPI(hWnd, WM_GETICON, 1, ByVal 0&)
	$TypeCheck On
	'smallIcon = CopyImage(hIcon, 1, 16, 16, &H4000)
	DrawIconEx dc_Skin, s_BorderW +2, s_BorderW +1, hIcon, 16, 16, 0, 0, DI_NORMAL
	'DrawIcon dc_Skin, 4, 0, smallIcon 'hIcon
	DestroyIcon hIcon
	'DestroyIcon smallIcon
	' Draw Text
	Dim wCaption As String
	Dim r_wCaption As RECT
	$TypeCheck Off
	wCaption = SendMessageAPI(hWnd, &HD, 1, ByVal 0&)
	$TypeCheck On
	SetTextColor (dc_Skin, &HFFFFFF)
	SetBkMode (dc_Skin, 1)
	r_wCaption.Left	= s_BorderW + 16 + 6
	r_wCaption.Top	= s_BorderW
	r_wCaption.Right = r_Skin.Right -r_Skin.Left -(s_BorderW *2) -(GetSystemMetrics(SM_CXSIZE) *4)
	r_wCaption.Bottom = r_Skin.Top +s_CaptionY -4
	DrawText dc_Skin, wCaption, Len(wCaption), r_wCaption, &H0
End Sub

Sub DrawButtons (hWnd As Long, wParam As Long)
	' Draw Buttons
	'GetWindowRect(hWnd, r_bSkin)
	r_bSkin = r_Skin
	'r_bSkin.Left	= r_bSkin.Right -r_bSkin.Left -GetSystemMetrics(SM_CXFRAME) - _
	'				  GetSystemMetrics(SM_CXSIZE) * 4 + 1
	'r_bSkin.Top		= GetSystemMetrics(SM_CYFRAME) '+ 2
	'r_bSkin.Right	= r_bSkin.Left + GetSystemMetrics(SM_CXSIZE) - 1
	'r_bSkin.Bottom	= r_bSkin.Top + GetSystemMetrics(SM_CYSIZE) - 4
			
	If SkinTop2.Empty = 0 Then
		If m_bActive = -1 Then
			StretchBlt ( dc_Skin, _
					     (r_Skin.Right -r_Skin.Left) -(s_BorderW +SkinTop2.Width), 0, _
					     SkinTop2.Width, s_CaptionY, _
					     SkinTop2.Handle, _
					     0, 0, _
					     SkinTop2.Width, SkinTop2.Height, _
					     ScrCopy)
		Else
			StretchBlt ( dc_Skin, _
				     s_BorderW, 0, _
				     (r_Skin.Right -r_Skin.Left) -(s_BorderW *2), s_CaptionY, _
				     SkinTop.Handle, _
				     s_BorderW, IIf(m_bActive = 0, SkinTop.Height /2, 0), _
				     SkinTop.Width -(s_BorderW *2 +1), SkinTop.Height /2, _
				     ScrCopy)
		End If
	End If
	If SkinBClose.Empty = 0 Then _
		StretchBlt ( dc_Skin, _
				     r_bSkin.Right -r_bSkin.Left -s_BorderW - GetSystemMetrics(SM_CXSIZE) -1, s_BorderW +1, _
				     GetSystemMetrics(SM_CXSIZE), GetSystemMetrics(SM_CYSIZE) -1, _
				     SkinBClose.Handle, _
				     0, 0, _
				     SkinBClose.Width /6, SkinBClose.Height, _
				     ScrCopy)
	If SkinBMax.Empty = 0 Then _
		StretchBlt ( dc_Skin, _
				     r_bSkin.Right -r_bSkin.Left -s_BorderW - GetSystemMetrics(SM_CXSIZE) *2 -2, s_BorderW +1, _
				     GetSystemMetrics(SM_CXSIZE), GetSystemMetrics(SM_CYSIZE) -1, _
				     SkinBMax.Handle, _
				     0, 0, _
				     SkinBMax.Width /6, SkinBMax.Height, _
				     ScrCopy)
	If SkinBMin.Empty = 0 Then _
		StretchBlt ( dc_Skin, _
				     r_bSkin.Right -r_bSkin.Left -s_BorderW - GetSystemMetrics(SM_CXSIZE) *3 -2, s_BorderW +1, _
				     GetSystemMetrics(SM_CXSIZE), GetSystemMetrics(SM_CYSIZE) -1, _
				     SkinBMin.Handle, _
				     0, 0, _
				     SkinBMin.Width /6, SkinBMax.Height, _
				     ScrCopy)
	If SkinBHelp.Empty = 0 Then _
		StretchBlt ( dc_Skin, _
				     r_bSkin.Right -r_bSkin.Left -s_BorderW - GetSystemMetrics(SM_CXSIZE) *4 -6 -IIf(SkinBTray.Empty = 0, GetSystemMetrics(SM_CXSIZE), 0), s_BorderW +1, _
				     GetSystemMetrics(SM_CXSIZE), GetSystemMetrics(SM_CYSIZE) -1, _
				     SkinBHelp.Handle, _
				     0, 0, _
				     SkinBHelp.Width /6, SkinBHelp.Height, _
				     ScrCopy)
	If SkinBTray.Empty = 0 Then _
		StretchBlt ( dc_Skin, _
				     r_bSkin.Right -r_bSkin.Left -s_BorderW - GetSystemMetrics(SM_CXSIZE) *4 -3, s_BorderW +1, _
				     GetSystemMetrics(SM_CXSIZE), GetSystemMetrics(SM_CYSIZE) -1, _
				     SkinBTray.Handle, _
				     0, 0, _
				     SkinBTray.Width /6, SkinBTray.Height, _
				     ScrCopy)
End Sub

Sub RefreshBtns (hWnd As Long, wParam As Long)
	Select Case wParam
		Case 3, 10 To 18
			DrawButtons (hWnd, wParam)
		Case Else
			GetInfoFromMenu ("WM_??PAINT :  " +STR$(wParam))
	End Select
End Sub

Sub DrawHotStateBtns (hWnd As Long, wParam As Long)
	r_bSkin = r_Skin
	Select Case wParam 
		Case HTCLOSE
			If SkinBClose.Empty = 0 Then _
				StretchBlt ( dc_Skin, _
						     r_bSkin.Right -r_bSkin.Left -s_BorderW - GetSystemMetrics(SM_CXSIZE) -1, s_BorderW +1, _
						     GetSystemMetrics(SM_CXSIZE), GetSystemMetrics(SM_CYSIZE) -1, _
						     SkinBClose.Handle, _
						     (SkinBClose.Width /6) *2, 0, _
						     SkinBClose.Width /6, SkinBClose.Height, _
						     ScrCopy)
		Case HTMAXBUTTON
			If SkinBMax.Empty = 0 Then _
				StretchBlt ( dc_Skin, _
						     r_bSkin.Right -r_bSkin.Left -s_BorderW - GetSystemMetrics(SM_CXSIZE) *2 -2, s_BorderW +1, _
						     GetSystemMetrics(SM_CXSIZE), GetSystemMetrics(SM_CYSIZE) -1, _
						     SkinBMax.Handle, _
						     (SkinBMax.Width /6) *2, 0, _
						     SkinBMax.Width /6, SkinBMax.Height, _
						     ScrCopy)
	
		Case HTMINBUTTON
			If SkinBMin.Empty = 0 Then _
				StretchBlt ( dc_Skin, _
						     r_bSkin.Right -r_bSkin.Left -s_BorderW - GetSystemMetrics(SM_CXSIZE) *3 -2, s_BorderW +1, _
						     GetSystemMetrics(SM_CXSIZE), GetSystemMetrics(SM_CYSIZE) -1, _
						     SkinBMin.Handle, _
						     (SkinBMax.Width /6) *2, 0, _
						     SkinBMax.Width /6, SkinBMax.Height, _
						     ScrCopy)
		Case Else
	End Select
End Sub

Sub DrawDownStateBtns (hWnd As Long, wParam As Long)
	r_bSkin = r_Skin
	Select Case wParam 
		Case HTCLOSE
			If SkinBClose.Empty = 0 Then _
				StretchBlt ( dc_Skin, _
						     r_bSkin.Right -r_bSkin.Left -s_BorderW - GetSystemMetrics(SM_CXSIZE) -1, s_BorderW +1, _
						     GetSystemMetrics(SM_CXSIZE), GetSystemMetrics(SM_CYSIZE) -1, _
						     SkinBClose.Handle, _
						     SkinBClose.Width /6, 0, _
						     SkinBClose.Width /6, SkinBClose.Height, _
						     ScrCopy)
		Case HTMAXBUTTON
			If SkinBMax.Empty = 0 Then _
				StretchBlt ( dc_Skin, _
						     r_bSkin.Right -r_bSkin.Left -s_BorderW - GetSystemMetrics(SM_CXSIZE) *2 -2, s_BorderW +1, _
						     GetSystemMetrics(SM_CXSIZE), GetSystemMetrics(SM_CYSIZE) -1, _
						     SkinBMax.Handle, _
						     SkinBMax.Width /6, 0, _
						     SkinBMax.Width /6, SkinBMax.Height, _
						     ScrCopy)
	
		Case HTMINBUTTON
			If SkinBMin.Empty = 0 Then _
				StretchBlt ( dc_Skin, _
						     r_bSkin.Right -r_bSkin.Left -s_BorderW - GetSystemMetrics(SM_CXSIZE) *3 -2, s_BorderW +1, _
						     GetSystemMetrics(SM_CXSIZE), GetSystemMetrics(SM_CYSIZE) -1, _
						     SkinBMin.Handle, _
						     SkinBMax.Width /6, 0, _
						     SkinBMax.Width /6, SkinBMax.Height, _
						     ScrCopy)
		Case Else
	End Select
End Sub

Sub ProtectFromDrawing '(hWnd As Long, rect As RECT)
	'hdc = GetWindowDC(hWnd)
	GetInfoFromMenu ("new clipping region's complexity :  " +STR$( _
	ExcludeClipRect ( dc_Skin, _
					  r_Skin.Left, _
					  r_Skin.Top, _
					  r_Skin.Right, _
					  r_Skin.Bottom)))
	'ReleaseDC(hdc)
End Sub

Dim btnState As Integer

Declare Sub mouse_event Lib "user32" Alias "mouse_event" ( _
		ByVal dwFlags As Long, _
		ByVal dx As Long, ByVal dy As Long, _
		ByVal cButtons As Long, _
		ByVal dwExtraInfo As Long)

' Redraw window:
Const RDW_ALLCHILDREN = &H80
Const RDW_ERASE = &H4
Const RDW_ERASENOW = &H200
Const RDW_FRAME = &H400
Const RDW_INTERNALPAINT = &H2
Const RDW_INVALIDATE = &H1
Const RDW_NOCHILDREN = &H40
Const RDW_NOERASE = &H20
Const RDW_NOFRAME = &H800
Const RDW_NOINTERNALPAINT = &H10
Const RDW_UPDATENOW = &H100
Const RDW_VALIDATE = &H8

Declare Function RedrawWindow Lib "user32" Alias "RedrawWindow" ( _
		ByVal hwnd As Long, _
		lprcUpdate As Long, _
		ByVal hrgnUpdate As Long, _
		ByVal fuRedraw As Long) As Long

Sub Redraw(hwnd As Long)
	$TypeCheck Off
	RedrawWindow hwnd, ByVal 0&, 0, RDW_UPDATENOW Or RDW_INVALIDATE Or RDW_INTERNALPAINT Or RDW_ALLCHILDREN
	$TypeCheck On
End Sub

Dim tNCR As NCCALCSIZE_PARAMS
Dim tWP As WINDOWPOS
' Borders:
Dim m_lLeft As Long, _
	m_lTop As Long
Dim m_lRight As Long, _
	m_lBottom As Long

FUNCTION WindowProc '(ByVal hwnd AS Long, ByVal uMsg AS Long,ByVal wParam AS Long, ByVal lParam AS LONG) AS LONG
	Dim PrevProc As Long
	Static s_dx As Long
	Static s_dy As Long
	PrevProc = precedent_adresse_mainfrm
	Select Case uMsg
		Case WM_NCACTIVATE
			m_bActive = Not (wParam = 0)
			
			WindowProc = CallWindowProc(PrevProc, hwnd, uMsg, wParam, lParam)
            
            WindowProc hWnd, WM_NCPAINT, 0, 0
            
            Redraw hWnd
            
		Case WM_PAINT, WM_NCPAINT, WM_INITMENUPOPUP 'WM_NCACTIVATE, WM_SETTEXT, WM_KILLFOCUS, WM_MOUSEACTIVATE, WM_SYSCOMMAND, 
			WindowProc = CallWindowProc(PrevProc, hwnd, uMsg, wParam, lParam)
			GetInfoFromMenu ("WM_??PAINT :  " +STR$(lParam) +", " +STR$(wParam))
			
			GetWindowRect(hWnd, r_Skin)
			dc_Skin = GetWindowDC(hWnd)
			
			DrawWindowBorders (hWnd, wParam)
			DrawButtons (hWnd, wParam)
			DrawIconText (hWnd, wParam)
			
			Select Case btnState
				Case 1
					DrawHotStateBtns (hWnd, HTCLOSE)
				Case 2
					DrawHotStateBtns (hWnd, HTMAXBUTTON)
				Case 3
					DrawHotStateBtns (hWnd, HTMINBUTTON)
				Case 4
					DrawDownStateBtns (hWnd, HTCLOSE)
				Case 5
					DrawDownStateBtns (hWnd, HTMAXBUTTON)
				Case 6
					DrawDownStateBtns (hWnd, HTMINBUTTON)
				Case Else
			End Select
			
			ReleaseDC (hWnd, dc_Skin)
		Case WM_NCCALCSIZE
        '    If wParam Then
		'		WindowProc = CallWindowProc(PrevProc, hwnd, uMsg, wParam, lParam)
        '        'DefWindowProc hWnd, uMsg, wParam, lParam
		'		ConfigureNCandClient(hWnd, lParam)
        '        'NewWndProc = WVR_VALIDRECTS  ' special meaning
        '        WindowProc = &H400
        '        'bWasIntercepted = True  ' don't forward this message
		'	End If
		'	GetInfoFromMenu ("WM_NCCALCSIZE :  " +STR$(lParam) +", " +STR$(wParam))
			If wParam <> 0 Then

				' Get the structure pointed to by lParam:
				'CopyMemory tNCR, ByVal lParam, Len(tNCR)
				'CopyMemory tWP, ByVal tNCR.lppos, Len(tWP)
				Mem.Position	= 0
				Mem.MemCopyFrom(lParam, SizeOf(tNCR))
				Mem.Position	= 0
				Mem.ReadUDT	(tNCR)

				Mem2.Position	= 0
				Mem2.MemCopyFrom(tNCR.lppos, SizeOf(tWP))
				Mem2.Position	= 0
				Mem2.ReadUDT	(tWP)

				'With tNCR.rgrc(0)
					' Set these
					tNCR.rgrc0left		= tWP.x
					tNCR.rgrc0top		= tWP.y
					tNCR.rgrc0right		= tWP.x + tWP.cx
					tNCR.rgrc0bottom	= tWP.y + tWP.cy

					' Defaults
					m_lLeft		= GetSystemMetrics(SM_CXFRAME) -2
					m_lRight	= m_lLeft
					m_lTop		= GetSystemMetrics(SM_CYCAPTION) + GetSystemMetrics(SM_CYFRAME)
					If m_lTop < 24 Then _
						m_lTop = 24
					m_lBottom	= GetSystemMetrics(SM_CYFRAME) -2

					' If the window in question is an MDI child, then we
					' ant to ensure that the standard settings get sent
					' back to windows: to prevent drawing additional borders,
					' which aren't required:
					'If Not m_bZoomedMDIChild Then
					'	' If the implementation is valid then request the
					'	' physical size of the title bar and borders:
					'	If GetImplementation(Implementation) Then
					'		Implementation.GetLeftMarginWidth m_lLeft
					'		Implementation.GetTopMarginHeight m_lTop
					'		Implementation.GetRightMarginWidth m_lRight
					'		Implementation.GetBottomMarginHeight m_lBottom
					'	End If
					'End If

					' Set our physical left/top/right/bottom values:
					tNCR.rgrc0Left = tNCR.rgrc0Left + m_lLeft
					tNCR.rgrc0Top = tNCR.rgrc0Top + m_lTop
					tNCR.rgrc0Right = tNCR.rgrc0Right - m_lRight - 1
					tNCR.rgrc0Bottom = tNCR.rgrc0Bottom - m_lBottom - 1
				'End With

				' Return the new client area size to windows:
				tNCR.rgrc1Left = tNCR.rgrc0Left
				tNCR.rgrc1Top = tNCR.rgrc0Top
				tNCR.rgrc1Right = tNCR.rgrc0Right
				tNCR.rgrc1Bottom = tNCR.rgrc0Bottom
				'CopyMemory ByVal lParam, tNCR, Len(tNCR)
				Mem.Position	= 0
				Mem.WriteUDT	(tNCR)	'-- Write structure back to memory
				Mem.Position	= 0
				
				Mem.MemCopyTo	(lParam, SizeOf(tNCR))
				Mem.Close: Mem2.Close
				WindowProc = WVR_VALIDRECTS

			Else
				' lParam points to a rectangle
				'WindowProc = CallOldWindowProc(hwnd, uMsg, wParam, lParam)
				WindowProc = CallWindowProc(PrevProc, hwnd, uMsg, wParam, lParam)
			End If
		Case WM_NCLBUTTONDOWN 'TO WM_NCMBUTTONDBLCLK
		
		    'Dim Ret As Long
		    
		    
            'If s_dx = 0 Then s_dx = 1
            'If s_dy = 0 Then s_dy = 1
            's_dx = -1 * s_dx: s_dy = -1 * s_dy
            'mouse_event &H1, s_dx, s_dy, 0, 0

            Dim hRgn As Long
			GetWindowRect(hWnd, r_Skin)
			dc_Skin = GetWindowDC(hWnd)
			GetInfoFromMenu ("Souris activйe :  " +STR$(hWnd) +", " +STR$(lParam) +", " +STR$(wParam))
			hRgn = CreateRectRgn(r_Skin.Left, r_Skin.Top +20, r_Skin.Right, r_Skin.Bottom) 'CreateRectRgnIndirect(0&)
            ValidateRgn(hWnd, hRgn)
			Select Case wParam
				Case HTMINBUTTON
					If btnState <> 6 Then
						DrawButtons(hWnd, wParam)
						DrawDownStateBtns (hWnd, wParam)
						btnState = 6
						GetInfoFromMenu ("WM_NCLBUTTONDOWN :  " +STR$(wParam))
					End If
				Case HTMAXBUTTON
					If btnState <> 5 Then
						DrawButtons (hWnd, wParam)
						DrawDownStateBtns (hWnd, wParam)
						btnState = 5
						GetInfoFromMenu ("WM_NCLBUTTONDOWN :  " +STR$(wParam))
					End If
				Case HTCLOSE
					If btnState <> 4 Then
						DrawButtons (hWnd, wParam)
						DrawDownStateBtns (hWnd, wParam)
						btnState = 4
					End If
		'		Case 2, 5, 8, 9, 10 To 18, 20 '3, 
		'			If uMsg = &HA4 Then _
		'				lParam = 0
		'			Dim m_wParam2 As Long
		'			m_wParam2 = wParam
		'			wParam = 0
		'			WindowProc = CallWindowProc(PrevProc, hwnd, uMsg, wParam, lParam)
		'			wParam = 0
		'			
		'			GetWindowRect(hWnd, r_Skin)
		'			dc_Skin = GetWindowDC(hWnd)
		'			
		'			RefreshBtns (hWnd, m_wParam2)
		'			
		'			ReleaseDC (hWnd, dc_Skin)
		'			'SendMessageAPI (hWnd, WM_NCLBUTTONDOWN, m_wParam2, 0&)
				Case Else
		'			If wParam <> 0 and wParam <> 4 Then _
		'				GetInfoFromMenu ("Souris activйe :  " +STR$(hWnd) +", " +STR$(lParam) +", " +STR$(wParam))
		'			WindowProc = CallWindowProc(PrevProc, hwnd, uMsg, wParam, lParam)
			End Select
			
			
    ''create a temporary region
    'Ret = CreateEllipticRgn(0, 0, 1, 1)
    ''copy the current clipping region into the temporary region
    'GetClipRgn dc_Skin, Ret
    'OffsetClipRgn dc_Skin, 10, 10
    ''set the new window region
    'SetWindowRgn hWnd, Ret, 1
			
			
			'hRgn = CreateRectRgn(r_Skin.Left, r_Skin.Top +20, r_Skin.Right, r_Skin.Bottom) 'CreateRectRgnIndirect(0&)
            'ValidateRgn(hWnd, hRgn)
			WindowProc = CallWindowProc(PrevProc, hwnd, uMsg, wParam, lParam)
            '$TypeCheck Off
            'ValidateRect(hWnd, ByVal 0&)
            '$TypeCheck On
            'ValidateRgn(hWnd, hRgn)
            DeleteObject hRgn
			ReleaseDC (hWnd, dc_Skin)
		Case WM_NCMOUSEMOVE, WM_MOUSEMOVE ', WM_NCHITTEST, WM_MOUSEMOVE
			Select Case wParam
				Case HTMINBUTTON
					If btnState <> 3 and btnState <> 6 Then
						GetWindowRect(hWnd, r_Skin)
						dc_Skin = GetWindowDC(hWnd)
						DrawButtons(hWnd, wParam)
						DrawHotStateBtns (hWnd, wParam)
						ReleaseDC (hWnd, dc_Skin)
						btnState = 3
					End If
				Case HTMAXBUTTON
					If btnState <> 2 and btnState <> 5 Then
						GetWindowRect(hWnd, r_Skin)
						dc_Skin = GetWindowDC(hWnd)
						DrawButtons (hWnd, wParam)
						DrawHotStateBtns (hWnd, wParam)
						ReleaseDC (hWnd, dc_Skin)
						btnState = 2
					End If
				Case HTCLOSE
					If btnState <> 1 and btnState <> 4 Then
						GetWindowRect(hWnd, r_Skin)
						dc_Skin = GetWindowDC(hWnd)
						DrawButtons (hWnd, wParam)
						DrawHotStateBtns (hWnd, wParam)
						ReleaseDC (hWnd, dc_Skin)
						btnState = 1
					End If
		'		Case 10 To 18
		'			Dim m_wParam As Long
		'			m_wParam = wParam
		'			wParam = 0
		'			WindowProc = CallWindowProc(PrevProc, hwnd, uMsg, wParam, lParam)
		'			wParam = 0
		'			'GetInfoFromMenu ("WM_NCHITTEST :  " +STR$(hWnd) +", " +STR$(lParam) +", " +STR$(wParam))
		'			
		'			GetWindowRect(hWnd, r_Skin)
		'			dc_Skin = GetWindowDC(hWnd)
		'			
		'			RefreshBtns (hWnd, m_wParam)
		'			
		'			ReleaseDC (hWnd, dc_Skin)
		'			'WindowProc = CallWindowProc(PrevProc, hwnd, uMsg, wParam, lParam)
				Case Else
					If btnState > 0 Then
						GetWindowRect(hWnd, r_Skin)
						dc_Skin = GetWindowDC(hWnd)
						DrawButtons(hWnd, wParam)
						ReleaseDC (hWnd, dc_Skin)
						btnState = 0
					End If
		'			GetInfoFromMenu ("WM_NCHITTEST :  " +STR$(wParam))
					'WindowProc = CallWindowProc(PrevProc, hwnd, uMsg, wParam, lParam)
		'			If wParam <> 0 and wParam <> 2 and wParam <> 3 and wParam <> 8 and wParam <> 9 and wParam <> 20 Then _
		'				GetInfoFromMenu ("WM_NCHITTEST :  " +STR$(hWnd) +", " +STR$(lParam) +", " +STR$(wParam))
			End Select
			WindowProc = CallWindowProc(PrevProc, hwnd, uMsg, wParam, lParam)
        'Case WM_SIZE
		'	WindowProc = CallWindowProc(PrevProc, hwnd, uMsg, wParam, lParam)
		'	SendMessageAPI hWnd, WM_NCPAINT, 0, 0
		Case WM_SETCURSOR
			Dim HtPlus As Long
			Dim lStyle As Long, _
				lNewStyle As Long
			If hWnd = wParam Then
				HtPlus = VAL(Right$(hex$(lParam), 2))
				Select Case HtPlus
					Case 0, 10 To 18
						' Sans ceci, Windows redessine la zone de la barre de titre
						' ainsi que les btns rйduire/agrandir/fermer chaque fois que
						' la souris est relвchйe suivant un йvйnement appuyй NC.

	    				lStyle = GetWindowLong(hWnd, GWL_STYLE)
						lNewStyle = lStyle And Not WS_VISIBLE
						SetWindowLong (hWnd, GWL_STYLE, lNewStyle)
						CallWindowProc(PrevProc, hwnd, uMsg, wParam, lParam)
						'WindowProc = CallWindowProc(PrevProc, hwnd, uMsg, wParam, lParam)
						SetWindowLong (hWnd, GWL_STYLE, lStyle)
						GetInfoFromMenu ("WM_SETCURSOR :  " +STR$(HtPlus))
					Case Else
						WindowProc = CallWindowProc(PrevProc, hwnd, uMsg, wParam, lParam)
				End Select
			Else
				WindowProc = CallWindowProc(PrevProc, hwnd, uMsg, wParam, lParam)
			End If
			' If we don't catch this the controlbox area
            ' will show an ugly flicker.
            'Dim hRgn As Long
			'GetWindowRect(hWnd, r_Skin)
			'dc_Skin = GetWindowDC(hWnd)
            'Select Case HtPlus
            '    Case HTTOP, HTBOTTOM
            '        GetInfoFromMenu ("WM_SETCURSOR :  " +STR$(HtPlus))
            '    	'$TypeCheck Off
            '        'SetCursor LoadCursor(ByVal 0&, IDC_SIZENS)
            '    	'$TypeCheck On
            '		'SelectClipRgn (dc_Skin, hRgn)
            '    Case HTLEFT, HTRIGHT
            '        GetInfoFromMenu ("WM_SETCURSOR :  " +STR$(HtPlus))
            '    	'$TypeCheck Off
            '        'SetCursor LoadCursor(ByVal 0&, IDC_SIZEWE)
            '    	'$TypeCheck On
            '		'SelectClipRgn (dc_Skin, hRgn)
            '    Case HTTOPLEFT, HTBOTTOMRIGHT
            '        GetInfoFromMenu ("WM_SETCURSOR :  " +STR$(HtPlus))
            '    	'$TypeCheck Off
            '        'SetCursor LoadCursor(ByVal 0&, IDC_SIZENWSE)
            '    	'$TypeCheck On
            '		'SelectClipRgn (dc_Skin, hRgn)
            '    Case HTTOPRIGHT, HTBOTTOMLEFT
            '        GetInfoFromMenu ("WM_SETCURSOR :  " +STR$(HtPlus))
            '    	'$TypeCheck Off
            '        'SetCursor LoadCursor(ByVal 0&, IDC_SIZENESW)
            '    	'$TypeCheck On
            '		'SelectClipRgn (dc_Skin, hRgn)
            '    'Case 18
            '    '    GetInfoFromMenu ("WM_SETCURSOR :  " +STR$(HtPlus))
            '	'	'SelectClipRgn (dc_Skin, hRgn)
            '	Case 0
            '       	GetInfoFromMenu ("WM_SETCURSOR :  " +STR$(HtPlus) +" vs " +STR$(lParam) +" vs " +STR$(wParam))
            '    Case Else
            '        ' Let Windows handle this one.
            '        'If HtPlus <> 4 Then
            '        	'WindowProc = CallWindowProc(PrevProc, hwnd, uMsg, wParam, lParam)
            '        'End If
            'End Select
			'hRgn = CreateRectRgnIndirect(0&)
            'ProtectFromDrawing
            'WindowProc = 1
            'WindowProc = CallWindowProc(PrevProc, hwnd, uMsg, wParam, lParam)
            '$TypeCheck Off
            'ValidateRect(hWnd, ByVal 0&)
            '$TypeCheck On
            'ValidateRgn(hWnd, hRgn)
            'DeleteObject hRgn
			'ReleaseDC (hWnd, dc_Skin)
		Case Else
			WindowProc = CallWindowProc(PrevProc, hwnd, uMsg, wParam, lParam)
	End Select
	'WindowProc = CallWindowProc(PrevProc, hwnd, uMsg, wParam, lParam)

END FUNCTION
$ENDIF   ' IncManager: __QFORMSKIN_INC
