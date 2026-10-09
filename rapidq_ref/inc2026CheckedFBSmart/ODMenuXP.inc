$IFNDEF __RQINC
$IFNDEF __RQINCTMP
$DEFINE __RQINCTMP
CONST False = 0
CONST True	= 1

CONST clBtnFace = -2147483633
CONST clHilight	= -2147483635
CONST clGrayText = -2147483631
CONST clBtnText	= -2147483630
CONST clMenuText = -2147483641
CONST clPurple	= &HFF00FF

CONST pf15bit	= 4
$ENDIF ' __RQINCTMP
$ENDIF ' __RQINC

Type POINTAPI_mOD
    X As Long
    Y As Long
End Type

Type RECT_mOD
    Left	As Long
    Top		As Long
    Right	As Long
    Bottom	As Long
End Type

' // TEST
Type Size_mOD
	cx As Long
	cy As Long
End Type

Dim lpSize_mOD As Size_mOD

Declare Function GetTextExtentPoint32_mOD Lib "gdi32" Alias "GetTextExtentPoint32A" ( _
		ByVal hdc As Long, _
		ByVal lpsz As String, _
		ByVal cbString As Long, _
		lpSize As Size_mOD) As Long
'Declare Function GetTabbedTextExtent_mOD Lib "user32.dll" Alias "GetTabbedTextExtentA" ( _
'		ByVal hdc As Long, _
'		ByVal lpString As String, _
'		ByVal nCount As Long, _
'		ByVal nTabPositions As Long, _
'		lpnTabStopPositions As Long) As Long
Declare Function GetDC_mOD Lib "user32.dll" Alias "GetDC" ( _
		ByVal hwnd As Long) As Long

Declare Function GetMenuCheckState(hMenu As Long, ID As Long) As Long
'Declare Function GetMenuCheckBMPHandle(hMenu As Long, ID As Long) As Long

'Dim mnuCheckBMP			As QBitmap, _
'	mnuCheckDisBMP		As QBitmap, _
'	mnuUnCheckBMP		As QBitmap, _
'	mnuUnCheckDisBMP	As QBitmap, _
'	mnuRadioBMP			As QBitmap, _
'	mnuRadioDisBMP		As QBitmap, _
'	mnuUnRadioBMP		As QBitmap, _
'	mnuUnRadioDisBMP	As QBitmap
'	mnuCheckBMP.PixelFormat			= True
'	mnuCheckDisBMP.PixelFormat		= True
'	mnuUnCheckBMP.PixelFormat		= True
'	mnuUnCheckDisBMP.PixelFormat	= True
'	mnuRadioBMP.PixelFormat			= True
'	mnuRadioDisBMP.PixelFormat		= True
'	mnuUnRadioBMP.PixelFormat		= True
'	mnuUnRadioDisBMP.PixelFormat	= True
Dim mnuCheckBMP			As QBitmap, _
	mnuRadioBMP			As QBitmap
	mnuCheckBMP.PixelFormat			= True
	mnuRadioBMP.PixelFormat			= True
Dim mnuCheckBMPCount	As Integer, _
	mnuRadioBMPCount	As Integer
	mnuCheckBMPCount	= False
	mnuRadioBMPCount	= False

Declare Function SystemParametersInfo_mOD Lib "user32" Alias "SystemParametersInfoA" ( _
		ByVal uAction As Long, ByVal uParam As Long, ByVal lpvParam As Long, ByVal fuWinIni As Long) As Long


Declare Function DrawMenuBar_mOD Lib "user32.dll" Alias "DrawMenuBar" (ByVal hwnd As Long) As Long
Declare Function EndMenu_mOD Lib "user32.dll" Alias "EndMenu" () As Long

'Declare Function CheckMenuItem Lib "user32.dll" Alias "CheckMenuItem" ( _
'		ByVal hMenu As Long, ByVal wIDCheckItem As Long, ByVal wCheck As Long) As Long
'Declare Function CheckMenuRadioItem Lib "user32.dll" Alias "CheckMenuRadioItem" ( _
'		ByVal hMenu As Long, ByVal idFirst As Long, ByVal idLast As Long, ByVal idCheck As Long, ByVal uFlags As Long) As Long
'Declare Function HiliteMenuItem Lib "user32.dll" Alias "HiliteMenuItem" ( _
'		ByVal hwnd As Long, ByVal hMenu As Long, ByVal wIDHiliteItem As Long, ByVal wHilite As Long) As Long
'Declare Function IsMenu Lib "user32.dll" Alias "IsMenu" (ByVal hMenu As Long) As Long
Declare Function MenuItemFromPoint_mOD Lib "user32.dll" Alias "MenuItemFromPoint" ( _
		ByVal hWnd As Long, ByVal hMenu As Long, ByVal ptScreen As POINTAPI_mOD) As Long
Declare Function ScreenToClient_mOD Lib "user32.dll" Alias "ScreenToClient" ( _
		ByVal hwnd As Long, ByRef lpPoint As POINTAPI_mOD) As Long

Declare Function WindowFromPoint_mOD Lib "user32" Alias "WindowFromPoint" ( _
		ByVal xPoint As Long, ByVal yPoint As Long) As Long

Declare Function GetActiveWindow_mOD Lib "user32.dll" Alias "GetActiveWindow" () As Long

' Vérifie la version de Windows puisque certains problèmes sont identifiés sur l'un ou l'autre
' Cette version a été modifiée pour supporter win 2000...
$IFNDEF __RQGETVERSION2
$DEFINE __RQGETVERSION2
Dim isXP_mOD	As Integer
	isXP_mOD	= False

TYPE OSVERSIONINFO_mOD
	dwOSVersionInfoSize	As Long
	dwMajorVersion		As Long
	dwMinorVersion		As Long
	dwBuildNumber		As Long
	dwPlatformId		As Long
	szCSDVersion		As String *128
END TYPE
'Const PLATFORM_WIN32_WINDOWS = 1
'Const PLATFORM_WIN32_NT = 2
Declare Function GetVersionEx_mOD Lib "kernel32.dll" Alias "GetVersionExA" _
	(ByVal lpVersionInformation As LONG) As Long

Dim sStruc_mOD As QMemoryStream

SUB GetVersion_mOD
	DIM rtn AS LONG
	DIM OSV AS OSVERSIONINFO_mOD

	WiTH sStruc_mOD
		OSV.dwOSVersionInfoSize = SizeOf(OSV)
		.WriteUDT(OSV)
		rtn = GetVersionEx_mOD(.Pointer)
		IF rtn <> False THEN
			.Position = False
			.ReadUDT(OSV)
			IF OSV.dwPlatformId = True THEN
				isXP_mOD = False
			ELSEIF OSV.dwPlatformId = 2 THEN
				IF OSV.dwMajorVersion=5 THEN
					' Windows XP and 2000
					IF OSV.dwMinorVersion = True THEN
						isXP_mOD = 2	' Windows XP
					ELSE
						isXP_mOD = True	' Windows 2000
					END IF
				END IF
			END IF
		END IF
		.Close
	End WiTH
END SUB
Call GetVersion_mOD
$ENDIF ' __RQGETVERSION2
' //

Const WM_PAINT_mOD		As Long = &HF
Const WM_NCPAINT_mOD	As Long = &H85
'Const WM_PRINT			As Long = &H317
'Const WM_PRINTCLIENT	As Long = &H318
Const WM_UNDOC_1E5		As Long = &H1E5
Const WM_UNDOC_1EB		As Long = &H1EB

Const SPI_SETMENUANIMATION_mOD		As Long = &H1003
'Const SPI_SETMENUDROPALIGNMENT_mOD	As Long = 28
'Const SPI_SETMENUFADE_mOD			As Long = &H1013
'Const SPI_SETMENUSHOWDELAY_mOD		As Long = 107

Declare Function InvalidateRect_mOD Lib "user32" Alias "InvalidateRect" ( _
		ByVal hwnd As Long, _
		lpRect As RECT_mOD, _
		ByVal bErase As Long) As Long
		
Declare Function GetSystemMenu_mOD Lib "user32" Alias "GetSystemMenu" ( _
		ByVal hwnd As Long, _
		ByVal bRevert As Long) As Long

Declare Sub ReleaseCapture_mOD Lib "user32" Alias "ReleaseCapture" ()

Declare Function SendMessage_mOD Lib "user32" Alias "SendMessageA" ( _
		ByVal hwnd As Long, _
		ByVal wMsg As Long, _
		ByVal wParam As Long, _
		lParam As Long ) As Long 

Declare Function IsZoomed_mOD Lib "user32" Alias "IsZoomed" (ByVal hwnd As Long) As Long

Declare Function GetSystemMetrics_mOD Lib "user32" Alias "GetSystemMetrics" (ByVal nIndex As Long) As Long

Const AC_SRC_OVER_mOD = &H00

Type BLENDFUNCTION_mOD
	BlendOp		As Byte
	BlendFlags	As Byte
	SourceConstantAlpha As Byte
	AlphaFormat	As Byte
End Type

Declare Function AlphaBlend_mOD Lib "msimg32.dll" Alias "AlphaBlend" ( _
		ByVal hdcDest As Long, _
		ByVal xDest As Long, _
		ByVal yDest As Long, _
		ByVal WidthDest As Long, _
		ByVal HeightDest As Long, _
		ByVal hdcSrc As Long, _
		ByVal xSrc As Long, _
		ByVal ySrc As Long, _
		ByVal WidthSrc As Long, _
		ByVal HeightSrc As Long, _
		ByRef Blendfunc As BLENDFUNCTION_mOD) As Long

Declare Sub RtlMoveMemory_mOD Lib "kernel32.dll" Alias "RtlMoveMemory" ( _
		byref Destination As long, _
		byref Source As BLENDFUNCTION_mOD, _
		Length As Long)

'Declare Function GetPixel_mOD Lib "gdi32.dll" Alias "GetPixel" ( _ 
'	 ByVal hdc As Long, _ 
'	 ByVal x As Long, _ 
'	 ByVal y As Long) As Long 


Dim BF_mOD	As BLENDFUNCTION_mOD, _
	lBF_mOD	As Long
' // Fin TEST

Declare Function FindWindow_mOD Lib "user32" Alias "FindWindowA" ( _
        ByVal lpClassName As String, _
        ByVal lpWindowName As String) As Long

Declare Function GetWindowRect_mOD Lib "user32" Alias "GetWindowRect" ( _
        ByVal hwnd As Long, _
        lpRect As RECT_mOD) As Long
Declare Function GetClientRect_mOD Lib "user32" Alias "GetClientRect" ( _
        ByVal hwnd As Long, _
        lpRect As RECT_mOD) As Long
Declare Function SetRect_mOD Lib "user32" Alias "SetRect" ( _
        lpRect As RECT_mOD, _
        ByVal X1 As Long, ByVal Y1 As Long, _
        ByVal X2 As Long, ByVal Y2 As Long) As Long

Declare Function GetWindowDC_mOD Lib "user32" Alias "GetWindowDC" ( _
        ByVal hwnd As Long) As Long
Declare Function ReleaseDC_mOD Lib "user32" Alias "ReleaseDC" ( _
        ByVal hwnd As Long, _
        ByVal hdc As Long) As Long


Const BF_RECT_mOD = (&H1 Or &H2 Or &H4 Or &H8)
Const BF_FLAT_mOD = &H4000	' For flat rather than 3-D borders.

Const BDR_RAISEDINNER_mOD = &H4

Declare Function DrawEdge_mOD Lib "user32" Alias "DrawEdge" ( _
        ByVal hdc As Long, _
        qrc As RECT_mOD, _
        ByVal edge As Long, _
        ByVal grfFlags As Long) As Long

'Declare Function MoveToEx_mOD Lib "gdi32" Alias "MoveToEx" ( _
'		ByVal hdc As Long, _
'		ByVal X As Long, _
'		ByVal Y As Long, _
'		lpPoint As POINTAPI_mOD) As Long
'Declare Function LineTo_mOD Lib "gdi32" Alias "LineTo" ( _
'		ByVal hdc As Long, _
'		ByVal X As Long, _
'		ByVal Y As Long) As Long

' -- Hook
Const WH_CALLWNDPROC_mOD = 4

Const HC_ACTION_mOD = 0

Type CWPSTRUCT_mOD
	lParam	As Long
	wParam	As Long
	message	As Long
	hwnd	As Long
End Type
Declare Function SetWindowsHookEx_mOD Lib "user32" Alias "SetWindowsHookExA" ( _
		ByVal idHook As Long, _
		ByVal lpfn As Long, _
		ByVal hmod As Long, _
		ByVal dwThreadId As Long) As Long
Declare Function UnhookWindowsHookEx_mOD Lib "user32" Alias "UnhookWindowsHookEx" ( _
		ByVal hHook As Long) As Long
Declare Function CallNextHookEx_mOD Lib "user32" Alias "CallNextHookEx" ( _
		ByVal hHook As Long, _
		ByVal ncode As Long, _
		ByVal wParam As Long, _
		lParam As Long) As Long
Declare Function GetWindowThreadProcessId_mOD Lib "user32" Alias "GetWindowThreadProcessId" ( _
		ByVal hwnd As Long, _
		lpdwProcessId As Long) As Long
Declare Function CallWindowProc_mOD Lib "user32" Alias "CallWindowProcA" ( _
		ByVal lpPrevWndFunc As Long, _
		ByVal hWnd As Long, _
		ByVal Msg As Long, _
		ByVal wParam As Long, _
		ByVal lParam As Long) As Long

Const GWL_WNDPROC_mOD		= (-4)
Const GWL_HWNDPARENT_mOD	= (-8)
Const GWL_STYLE_mOD			= (-16)
Const GWL_EXSTYLE_mOD		= (-20)
Const WS_BORDER_mOD			= &H800000
Const WS_EX_DLGMODALFRAME_mOD = &H1&
Const WS_EX_WINDOWEDGE_mOD As Long = &H100&


Declare Function GetWindowLong_mOD Lib "user32" Alias "GetWindowLongA" ( _
		ByVal hwnd As Long, ByVal nIndex As Long) As Long
Declare Function SetWindowLong_mOD Lib "user32" Alias "SetWindowLongA" ( _
		ByVal hwnd As Long, ByVal nIndex As Long, ByVal dwNewLong As Long) As Long

Declare Function SetProp_mOD Lib "user32" Alias "SetPropA" ( _
		ByVal hwnd As Long, ByVal lpString As String, ByVal hData As Long) As Long
Declare Function GetProp_mOD Lib "user32" Alias "GetPropA" ( _
		ByVal hwnd As Long, ByVal lpString As String) As Long
Declare Function RemoveProp_mOD Lib "user32" Alias "RemovePropA" ( _
		ByVal hwnd As Long, ByVal lpString As String) As Long

Declare Function GetClassName_mOD Lib "user32" Alias "GetClassNameA" ( _
		ByVal hwnd As Long, ByVal lpClassName As String, ByVal nMaxCount As Long) As Long


Declare Function pHookCallWndProc_mOD( _
		ByVal ncode As Long, _
		ByVal wParam As Long, _
		ByVal lParam As Long) As Long
Declare Function pSubclassWndProc_mOD( _
		ByVal hwnd As Long, _
		ByVal uMsg As Long, _
		ByVal wParam As Long, _
		ByVal lParam As Long) As Long

Declare Function pGetClassName_mOD(ByVal hwnd As Long) As String

Dim fhWnd_mOD As Long, _
	m_ThreadID_mOD As Long, _
	m_HookID_mOD As Long

'les contantes APIs
Const HTCAPTION_mOD		= 2
Const HTMENU_mOD		= 5
'Const HTTOP			= 12
'Const HTLEFT			= 10
'Const HTBOTTOM			= 15
'Const HTRIGHT			= 11
Const HTSYSMENU_mOD		= 3
Const HWND_DESKTOP_mOD	= 0
'Const MB_YESNO			= &H4

' System Menu Command Values
Const SC_SIZE_mOD		= &HF000
Const SC_MOVE_mOD		= &HF010
Const SC_MINIMIZE_mOD	= &HF020
Const SC_MAXIMIZE_mOD	= &HF030
Const SC_NEXTWINDOW_mOD	= &HF040
Const SC_PREVWINDOW_mOD	= &HF050
Const SC_CLOSE_mOD		= &HF060
Const SC_RESTORE_mOD	= &HF120

'en vlà queques unes pour jouer
Const WM_LBUTTONDOWN_mOD	= &H201
Const WM_RBUTTONDOWN_mOD	= &H204
'Const WM_NCLBUTTONUP		= &HA2
'Const WM_LBUTTONUP			= &H202
Const WM_COMMAND_mOD		= &H111
Const WM_SYSCOMMAND_mOD		= &H112

Const WM_NCHITTEST_mOD		= &H84
Const WM_NCMOUSEMOVE_mOD	= &HA0
Const WM_NCLBUTTONDOWN_mOD	= &HA1
Const WM_NCRBUTTONDOWN_mOD	= &HA4

'Const WM_DRAWCLIPBOARD		= &H308
'Const WM_SIZE				= &H5
'Const WM_MOVE				= &H3
'Const WM_MOUSEMOVE_mOD		= &H200
'Const WM_LBUTTONDBLCLK		= &H203
'Const WM_QUIT				= &H12
'Const WM_SHOWWINDOW		= &H18
'Const WM_KILLFOCUS			= &H8
'Const WM_CHILDACTIVATE		= &H22
'Const WM_MOUSEACTIVATE		= &H21
'Const WM_SETCURSOR			= &H20

Const WM_CREATE_mOD			= &H1
Const WM_DESTROY_mOD		= &H2

Const WM_NCACTIVATE_mOD		= &H86
Const WM_ACTIVATE_mOD		= &H6
Const WA_ACTIVE_mOD			= 1
Const WA_INACTIVE_mOD		= 0

'mes variables globales
Dim Add_MyProc As Long
	Add_MyProc = CODEPTR(pSubclassWndProc_mOD) 'instruction rapidQ (adressof en VB)


' Corrige le menu de la barre de tâches et ajoute aussi le support OwnerDraw
Sub FixTaskBarMenu (hWnd As Long)
	SetWindowLong_mOD ( hWnd, GWL_HWNDPARENT_mOD, HWND_DESKTOP_mOD )
	SetWindowLong_mOD ( Application.Handle, GWL_HWNDPARENT_mOD, hWnd )
End Sub

Declare Sub CheckMenuBarForItems(frmTmp As Long)

Dim mnuAltHook As Integer
	mnuAltHook = False

Declare Sub GetInfoFromMenu (iCaption As String) '(moCaption As String, iCaption As String)

Sub SetODMenuHookEnabled(hWnd As Long, Enabled As Integer, AltHook As Integer)
	Dim lRet As Long
	fhWnd_mOD = hWnd

	If Enabled > False Then
		mnuAltHook = AltHook
		If mnuAltHook = False Then
			' - Get the Process thread... 
			m_ThreadID_mOD = GetWindowThreadProcessId_mOD(fhwnd_mOD, False)

			If m_HookID_mOD <> False Then _
				UnhookWindowsHookEx_mOD m_HookID_mOD

			If m_ThreadID_mOD <> False Then
				' - Install our own hook...
				m_HookID_mOD = SetWindowsHookEx_mOD( _
									WH_CALLWNDPROC_mOD, _
									CodePtr(pHookCallWndProc_mOD), _
									False, _
									m_ThreadID_mOD)
				'GetInfoFromMenu("Hook Installé " +STR$(m_HookID_mOD))
			End If
		'	GetInfoFromMenu("Hook Installé")
		'Else
		'	GetInfoFromMenu("Alternative Hook Installé")
		End If

		' on lance et on prend en note l'adresse de la procedure
		' - Store the old windowproc...
		If GetProp_mOD (hWnd, "OldWndProc") = False Then _
			SetProp_mOD hWnd, "OldWndProc", SetWindowLong_mOD ( _
												hWnd, _
												GWL_WNDPROC_mOD, _
												Add_MyProc)
		CheckMenuBarForItems(fhWnd_mOD)
	Else
		If GetProp_mOD (hWnd, "OldWndProc") <> False Then
			' on arrête la procedure
			lRet = GetProp_mOD(hwnd, "OldWndProc")
			' - UnSubclass the window... 
			RemoveProp_mOD hwnd, "OldWndProc"
			SetWindowLong_mOD (hwnd, GWL_WNDPROC_mOD, lRet)
		End If

		If m_HookID_mOD <> False Then _
			UnhookWindowsHookEx_mOD m_HookID_mOD
	End If
End Sub

Dim hMainMenu	As Long
	hMainMenu	= False
Dim hMenuFound	As Long
	hMenuFound	= False
Dim hSysMenu	As Long

'Dim hMenuOpen2	As Long, _
'	hMenuOpen3	As Long
Dim hMenuCount	As Integer
	hMenuCount	= False
' // Fin Hook

Const TPM_HORIZONTAL		As Long = &H0&
Const TPM_LEFTALIGN			As Long = &H0&
Const TPM_LEFTBUTTON				= &H0				'&H0&
Const TPM_TOPALIGN			As Long = &H0&
Const TPM_RECURSE					= &H1				'&H1&
Const TPM_RIGHTBUTTON				= &H2				'&H2&
Const TPM_CENTERALIGN		As Long = &H4&
Const TPM_RIGHTALIGN		As Long = &H8&
Const TPM_VCENTERALIGN		As Long = &H10&
Const TPM_BOTTOMALIGN		As Long = &H20&
Const TPM_VERTICAL			As Long = &H40&
Const TPM_NONOTIFY			As Long = &H80&
Const TPM_RETURNCMD			As Long = &H100&
Const TPM_HORPOSANIMATION	As Long = &H400&
Const TPM_HORNEGANIMATION	As Long = &H800&
Const TPM_VERPOSANIMATION	As Long = &H1000&
Const TPM_VERNEGANIMATION	As Long = &H2000&
Const TPM_NOANIMATION		As Long = &H4000&

Declare Function TrackPopupMenuEx_mOD Lib "user32" Alias "TrackPopupMenuEx" ( _
		ByVal hMenu As Long, _
		ByVal wFlags As Long, _
		ByVal x As Long, ByVal y As Long, _
		ByVal hWnd As Long, _
		ByVal lptpm As Long) As Long

' ===============================================================================================

Declare Sub FindFirstMenu (Me As QTimer)


Dim lTimer_mOD As QTimer
	lTimer_mOD.Enabled = False
	lTimer_mOD.OnTimer = FindFirstMenu


' **************************************************************************************************
' INC
' **************************************************************************************************

Const ODT_MENU			= 1

Const ODS_SELECTED		= 1
Const ODS_GRAYED		= 2
Const ODS_DISABLED		= 4
Const ODS_CHECKED		= 8
Const ODS_FOCUS			= &H10
Const ODS_DEFAULT		= &H20
'Const ODS_COMBOBOXEDIT = &H1000
Const ODS_HOTLIGHT As Long = &H40

' Owner draw actions
'Const ODA_DRAWENTIRE	= &H1
'Const ODA_SELECT		= &H2
'Const ODA_FOCUS		= &H4

Const WM_DRAWITEM_mOD			= &H2B
Const WM_MEASUREITEM_mOD		= &H2C
Const WM_MENUSELECT_mOD			= &H11F
Const WM_INITMENUPOPUP_mOD		= &H117
Const WM_UNINITMENUPOPUP_mOD	= &H125

Const MIIM_BITMAP	As Long = &H80
Const MIIM_CHECKMARKS As Long = &H8
Const MIIM_DATA		As Long = &H20
Const MIIM_FTYPE	As Long = &H100
Const MIIM_ID		As Long = &H2
Const MIIM_STATE	As Long = &H1
Const MIIM_STRING	As Long = &H40
Const MIIM_SUBMENU	As Long = &H4
Const MIIM_TYPE		As Long = &H10

Const MF_APPEND As Long = &H100
Const MF_BITMAP As Long = &H4
Const MF_BYCOMMAND As Long = &H0
Const MF_BYPOSITION As Long = &H400
Const MF_CALLBACKS As Long = &H8000000
Const MF_CHANGE As Long = &H80
Const MF_CHECKED As Long = &H8
Const MF_CONV As Long = &H40000000
Const MF_DEFAULT As Long = &H1000
Const MF_DELETE As Long = &H200
Const MF_DISABLED As Long = &H2
'Const MF_DLL_NAME As String = "Microsoft Picture Converter"
Const MF_ENABLED As Long = &H0
Const MF_END As Long = &H80
Const MF_ERRORS As Long = &H10000000
'Const MF_FLAGS_FILL_IN_UNKNOWN_RESOURCE As Long = &H4
'Const MF_FLAGS_NO_CREATE_IF_NO_RESOURCE As Long = &H2
'Const MF_FPCR_FUNC As Long = &H25
'Const MF_FPCR_FUNC_STR As String = "mf_fpcr"
Const MF_GRAYED As Long = &H1
Const MF_HELP As Long = &H4000
Const MF_HILITE As Long = &H80
Const MF_HSZ_INFO As Long = &H1000000
Const MF_INSERT As Long = &H0
Const MF_LINKS As Long = &H20000000
Const MF_MASK As Long = &HFF000000
Const MF_MENUBARBREAK As Long = &H20
Const MF_MENUBREAK As Long = &H40
Const MF_MOUSESELECT As Long = &H8000
Const MF_OWNERDRAW As Long = &H100
Const MF_POPUP As Long = &H10
Const MF_POSTMSGS As Long = &H4000000
Const MF_REMOVE As Long = &H1000
Const MF_RIGHTJUSTIFY As Long = &H4000
Const MF_SENDMSGS As Long = &H2000000
Const MF_SEPARATOR As Long = &H800
Const MF_STRING As Long = &H0
Const MF_SYSMENU As Long = &H2000
Const MF_UNCHECKED As Long = &H0
Const MF_UNHILITE As Long = &H0
Const MF_USECHECKBITMAPS As Long = &H200

Const MFT_BITMAP		= MF_BITMAP
Const MFT_MENUBARBREAK	= MF_MENUBARBREAK
Const MFT_MENUBREAK		= MF_MENUBREAK
Const MFT_OWNERDRAW		= MF_OWNERDRAW
Const MFT_RADIOCHECK	= &H200
Const MFT_RIGHTJUSTIFY	= MF_RIGHTJUSTIFY
Const MFT_RIGHTORDER	= &H2000
Const MFT_SEPARATOR		= MF_SEPARATOR
Const MFT_STRING		= MF_STRING

Const MFS_CHECKED		= MF_CHECKED
Const MFS_DEFAULT		= MF_DEFAULT
Const MFS_DISABLED		= MF_DISABLED
Const MFS_ENABLED		= MF_ENABLED
Const MFS_GRAYED		= MF_GRAYED
Const MFS_HILITE		= MF_HILITE
Const MFS_UNCHECKED		= MF_UNCHECKED
Const MFS_UNHILITE		= MF_UNHILITE

Type MEASUREITEMSTRUCT_mOD
	CtlType		As Long
	CtlID		As Long
	itemID		As Long
	itemWidth	As Long
	itemHeight	As Long
	itemData	As DWORD
End Type

Type TDRAWITEMSTRUCT_mOD
	CtlType		As Long
	CtlID		As Long
	itemID		As Long
	itemAction	As Long
	itemState	As Long
	hwndItem	As Long
	hDC			As Long
	left		As Long
	top			As Long
	right		As Long
	bottom		As Long
	itemData	As DWORD
End Type

Type MENUITEMINFO_mOD
	cbSize		As Long
	fMask		As Long
	fType		As Long
	fState		As Long
	wID			As Long
	hSubMenu		As Long
	hbmpChecked		As Long
	hbmpUnchecked	As Long
	dwItemData		As Long
	dwTypeData		As Long
	cch				As Long
End Type

DIM MeasureItem As MEASUREITEMSTRUCT_mOD
DIM DrawItem As TDRAWITEMSTRUCT_mOD
DIM MII As MENUITEMINFO_mOD

'Dim mnuPoint As PointAPI_mOD

Declare Function GetMenuItemInfo_mOD Lib "user32.dll" Alias "GetMenuItemInfoA" ( _
		ByVal hMenu As Long, _
		ByVal uItem As Long, _
		ByVal fByPosition As Long, _
		lpmii As MENUITEMINFO_mOD ) As Long
'Declare Function SetMenuItemInfo_mOD Lib "user32.dll" Alias "SetMenuItemInfoA" ( _
'		ByVal hMenu As Long, _
'		ByVal uItem As Long, _
'		ByVal fByPosition As Long, _
'		lpmii As MENUITEMINFO_mOD ) As Long



Declare Function GetSysColor_mOD Lib "user32" Alias "GetSysColor" ( _
		ByVal nIndex As Long ) As Long

Declare Function ExcludeClipRect_mOD Lib "gdi32.dll" Alias "ExcludeClipRect" ( _
		ByVal hdc As Long, _
		ByVal X1 As Long, ByVal Y1 As Long, _
		ByVal X2 As Long, ByVal Y2 As Long) As Long


'$INCLUDE "module_Shadow2C.inc"
' -- Module Ombre
Declare Function GetDesktopWindow_mOD Lib "user32" Alias "GetDesktopWindow" () As Long

Declare Function GetPixel_mOD Lib "gdi32" Alias "GetPixel" ( _
		ByVal hdc As Long, _
		ByVal x As Long, _
		ByVal y As Long ) As Long
Declare Function SetPixel_mOD Lib "gdi32" Alias "SetPixel" ( _
		ByVal hdc As Long, _
		ByVal x As Long, _
		ByVal y As Long, _
		ByVal crColor As Long ) As Long

' ==

Const SRCCOPY_mOD = &HCC0020 ' (DWORD) dest = source
'Const SRCPAINT = &HEE0086        ' (DWORD) dest = source OR dest
'Const SRCAND = &H8800C6  ' (DWORD) dest = source AND dest
'Const SRCINVERT = &H660046       ' (DWORD) dest = source XOR dest
'Const SRCERASE = &H440328        ' (DWORD) dest = source AND (NOT dest )
'Const NOTSRCCOPY = &H330008      ' (DWORD) dest = (NOT source)
'Const NOTSRCERASE = &H1100A6     ' (DWORD) dest = (NOT src) AND (NOT dest)
'Const MERGECOPY = &HC000CA       ' (DWORD) dest = (source AND pattern)
'Const MERGEPAINT = &HBB0226      ' (DWORD) dest = (NOT source) OR dest
'Const PATCOPY = &HF00021 ' (DWORD) dest = pattern
'Const PATPAINT = &HFB0A09        ' (DWORD) dest = DPSnoo
'Const PATINVERT = &H5A0049       ' (DWORD) dest = pattern XOR dest
'Const DSTINVERT = &H550009       ' (DWORD) dest = (NOT dest)
'Const BLACKNESS = &H42 ' (DWORD) dest = BLACK
'Const WHITENESS = &HFF0062       ' (DWORD) dest = WHITE

Declare Function BitBlt_mOD Lib "gdi32" _
		Alias "BitBlt" ( _
		hDC As Integer, _
		nXDest As Integer, nYDest As Integer, _
		nWidth As Integer, nHeight As Integer, _
		hdcSrc As Integer, _
		nXSrc As Integer, nYSrc As Integer, _
		dwRop As Integer ) As Integer

Dim rBorder(2)	As QBitmap, _
	bBorder(2)	As QBitmap, _
	rBufLast(2)	As QBitmap, _
	bBufLast(2)	As QBitmap

Dim rRestore(2)	As RECT_mOD, _
	bRestore(2)	As RECT_mOD

Dim bdrEmpty(2)	As Integer
	bdrEmpty(0)	= 1
	bdrEmpty(1)	= 1
	bdrEmpty(2)	= 1
' // ==

Declare Sub DrawMenuShadow ( _ 
	hWnd As Long, _ 
	hDC As Long, _
	mnuIndex As Integer ) ', _ 
'	ByVal xOrg As Long, _ 
'	ByVal yOrg As Long)
Declare Sub RemoveMenuShadow ( _
	mnuIndex As Integer ) ', _
'	hWnd As Long, _ 
'	hDC As Long )

Type ColorParts 
	r As Long 
	g As Long 
	b As Long 
End Type 
 
Function pTransform( _ 
	ByVal lScale As Long, _ 
	ByVal lColor As Long) As Long 

	pTransform = lColor - Int(lColor * lScale / 255) 
End Function

Function pMask( _ 
	ByVal lScale As Long, _ 
	ByVal lColor As Long) As Long 

	Dim R As Long 
	Dim G As Long 
	Dim B As Long 

	Dim ConvertToRGB As ColorParts
	With ConvertToRGB  
		.b = int(lColor /65536)
		.g = int((lColor -(.b *65536)) /256)
		.r = int(lColor -(.b *65536) -(.g *256))

		R = pTransform(lScale, .R) 
		G = pTransform(lScale, .G) 
		B = pTransform(lScale, .B)  
	End With 

	pMask = RGB(R, G, B) 

End Function

Sub DrawMenuShadow '( _
'	hWnd As Long, _
'	hDC As Long, _
'	xOrg As Long, _
'	yOrg As Long )

	Dim hDcDsk As Long
	Dim Rec As RECT_mOD
	Dim winW As Long, winH As Long
	Dim X As Long, Y As Long, c As Long
	Dim xOrg As Long, yOrg As Long

	'- Dimension du menu...
	GetWindowRect_mOD hWnd, Rec
	SetRect_mOD(Rec, Rec.Left, Rec.Top, Rec.Right +4, Rec.Bottom +4)

	winW = Rec.Right - Rec.Left
	winH = Rec.Bottom - Rec.Top

	xOrg = Rec.Left
	yOrg = Rec.Top

	' - DC du bureau... 
	hDcDsk = GetWindowDC_mOD(GetDesktopWindow_mOD)

	If mnuIndex > UBOUND(bdrEmpty) Then
		ReDim bdrEmpty(mnuIndex)	As Integer
			  bdrEmpty(mnuIndex) = 1
		ReDim rBorder(mnuIndex)		'As QBitmap
		ReDim bBorder(mnuIndex)		'As QBitmap
		ReDim bBufLast(mnuIndex)	'As QBitmap
		ReDim bBufLast(mnuIndex)	'As QBitmap
		ReDim rRestore(mnuIndex)	'As RECT_mOD
		ReDim bRestore(mnuIndex)	'As RECT_mOD
	End If
	'If (bdrEmpty(0) = 1 and hWnd = hMenuFound) or _
	'	(bdrEmpty(1) = 1 and hWnd = hMenuOpen2) or _
	'	(bdrEmpty(2) = 1 and hWnd = hMenuOpen3) Then
	If bdrEmpty(mnuIndex) = 1 Then
		bdrEmpty(mnuIndex) = 0
		' Supérieure
		rBorder(mnuIndex).Width = 4
		rBorder(mnuIndex).Height = winH
		BitBlt_mOD ( rBorder(mnuIndex).Handle, _
					   0, 0, _
					   4, winH, _
					   hDcDsk, _
					   Rec.Right -4, Rec.Top, _
					   SrcCopy_mOD )
		SetRect_mOD(rRestore(mnuIndex), Rec.Right -4, Rec.Top, Rec.Right, Rec.Bottom +4)
		rBorder(mnuIndex).Width = 4
		rBorder(mnuIndex).Height = winH
		' Inférieure
		bBorder(mnuIndex).Width = winW -4
		bBorder(mnuIndex).Height = 4
		BitBlt_mOD ( bBorder(mnuIndex).Handle, _
					   0, 0, _
					   winW -4, 4, _
					   hDcDsk, _
					   Rec.Left, Rec.Bottom -4, _
					   SrcCopy_mOD )
		SetRect_mOD(bRestore(mnuIndex), Rec.Left, Rec.Bottom -4, Rec.Right +4, Rec.Bottom)
		bBorder(mnuIndex).Width = winW -4
		bBorder(mnuIndex).Height = 4

		rBufLast(mnuIndex).Width = 4
		rBufLast(mnuIndex).Height = winH
		bBufLast(mnuIndex).Width = winW -4
		bBufLast(mnuIndex).Height = 4

		' - Ombre à droite...
		Dim rwinW As Long
		Dim rwinH As Long
		rwinW	= 4
		rwinH	= 4
		For X = 1 To 4
			For Y = 0 To 3
				c = GetPixel_mOD	(rBorder(mnuIndex).Handle, rwinW - X, Y)
				SetPixel_mOD		rBufLast(mnuIndex).Handle, rwinW - X, Y, c ' winW problème ?
			Next Y
			For Y = 4 To 7
				c = GetPixel_mOD	(rBorder(mnuIndex).Handle, rwinW - X, Y)
				SetPixel_mOD		rBufLast(mnuIndex).Handle, rwinW - X, Y, pMask(3 * X * (Y - 3), c)
			Next Y
			For Y = 8 To winH - 5
				c = GetPixel_mOD	(rBorder(mnuIndex).Handle, rwinW - X, Y)
				SetPixel_mOD		rBufLast(mnuIndex).Handle, rwinW - X, Y, pMask(15 * X, c)
			Next Y
			For Y = winH - 4 To winH - 1
				c = GetPixel_mOD	(rBorder(mnuIndex).Handle, rwinW - X, Y)
				SetPixel_mOD		rBufLast(mnuIndex).Handle, rwinW - X, Y, pMask(3 * X * -(Y - winH), c)
			Next Y
		Next X

		' - Ombre en dessous...
		For Y = 1 To 4
			For X = 0 To 3
				c = GetPixel_mOD	(bBorder(mnuIndex).Handle, X, rwinH - Y)
				SetPixel_mOD		bBufLast(mnuIndex).Handle, X, 4 - Y, c ' winH problème ?
			Next X
			For X = 4 To 7
				c = GetPixel_mOD	(bBorder(mnuIndex).Handle, X, rwinH - Y)
				SetPixel_mOD		bBufLast(mnuIndex).Handle, X, 4 - Y, pMask(3 * (X - 3) * Y, c)
			Next X
			For X = 8 To winW - 5
				c = GetPixel_mOD	(bBorder(mnuIndex).Handle, X, rwinH - Y)
				SetPixel_mOD		bBufLast(mnuIndex).Handle, X, 4 - Y, pMask(15 * Y, c)
			Next X
		Next Y

	End If

	BitBlt_mOD ( hDcDsk, _
				   rRestore(mnuIndex).Left, rRestore(mnuIndex).Top, _
				   4, rRestore(mnuIndex).Bottom -rRestore(mnuIndex).Top, _
				   rBufLast(mnuIndex).Handle, _
				   0, 0, _
				   SrcCopy_mOD )
	BitBlt_mOD ( hDcDsk, _
				   bRestore(mnuIndex).Left, bRestore(mnuIndex).Top, _
				   bRestore(mnuIndex).Right -bRestore(mnuIndex).Left, 4, _
				   bBufLast(mnuIndex).Handle, _
				   0, 0, _
				   SrcCopy_mOD )

	' - Relâche le DC du bureau
	ReleaseDC_mOD GetDesktopWindow_mOD, hDcDsk

End Sub

Sub RemoveMenuShadow '( _
	'hWnd As Long, _ 
	'hDC As Long, _
	'mnuIndex As Integer )
	If bdrEmpty(mnuIndex) = 0 Then
		Dim hDcDsk As Long
		hDcDsk = GetWindowDC_mOD(GetDesktopWindow_mOD)
		bdrEmpty(mnuIndex) = 1
		BitBlt_mOD ( hDcDsk, _
					   rRestore(mnuIndex).Left, rRestore(mnuIndex).Top, _
					   4, rRestore(mnuIndex).Bottom -rRestore(mnuIndex).Top, _
					   rBorder(mnuIndex).Handle, _
					   0, 0, _
					   SrcCopy_mOD )
		BitBlt_mOD ( hDcDsk, _
					   bRestore(mnuIndex).Left, bRestore(mnuIndex).Top, _
					   bRestore(mnuIndex).Right -bRestore(mnuIndex).Left, 4, _
					   bBorder(mnuIndex).Handle, _
					   0, 0, _
					   SrcCopy_mOD )
		ReleaseDC_mOD GetDesktopWindow_mOD, hDcDsk

		'rBorder(mnuIndex).BMP = 0&
		'bBorder(mnuIndex).BMP = 0&
		'bBufLast(mnuIndex).BMP = 0&
		'bBufLast(mnuIndex).BMP = 0&
		'EmptyRect rRestore(mnuIndex)
		'EmptyRect bRestore(mnuIndex)
	End If
End Sub

' // -- Fin Module Ombre

Declare Sub mReplaceSysMenu (Enabled As Integer)

Dim mnuStyle		As Integer
Dim mnuBorders		As Integer
	mnuBorders		= True
Dim mnuShadow		As Integer
	mnuShadow		= IIf(isXP_mOD = 2, False, True)
Dim mnuReplaceSysMenu As Integer

Dim mnuCheckStyle	As Integer	'0. Normal, 1. Bitmap
'Dim mnuRadioStyle	As Integer	'0. Normal, 1. Bitmap

'Dim mnuAutoEndProc	As Integer
'	mnuAutoEndProc	= True

Dim mnuIcoHotFx		As Integer
	mnuIcoHotFx		= 2

Dim mnuTemp As QBitmap
Dim mnuImgL As QImageList

Dim mnuMain(False)		As Long
Dim mnuBitmap(False)	As Long
'Dim mnuShortCut(False)	As String
Dim mnuSystem(False)	As Long
Dim mnuSubMenu(False)	As Long

Dim mnuSysIntercepted	As Integer, _
	mnuSysFromIcon		As Integer
Dim mnuSysMainForm		As Long

Type ODCouleur
	MainMenuTxt			As Integer	' Couleur du texte
	MainMenuTxtSel		As Integer	' Couleur du texte sélectionné
	MainMenuTxtInactif	As Integer	' Couleur du texte inactif
	MenuFond			As Integer	' Couleur du menu
	MenuCont			As Integer	' Couleur de la bordure, si plat
	ItemFond1			As Integer	' Couleur de l'item
	ItemFond2			As Integer	' Couleur de l'item sous l'icône
	ItemFondSel1		As Integer	' Couleur de l'item sélectionné
	ItemFondSel2		As Integer	' Couleur de l'item sous l'icône sélectionnée
	ItemFondInact1		As Integer	' Couleur de l'item inactif
	ItemFondInact2		As Integer	' Couleur de l'item sous l'icône inactive
	ItemFondSelInact1	As Integer	' Couleur de l'item inactif sélectionné
	ItemFondSelInact2	As Integer	' Couleur de l'item sous l'icône inactive sélectionnée
	ItemContSel			As Integer	' Couleur de la bordue, si plat
	ItemContSelInactif	As Integer	' Couleur de la bordure inactive, si plat
	ItemTxt				As Integer	' Couleur du texte
	ItemTxtSel			As Integer	' Couleur du texte sélectionné
	ItemTxtInactif		As Integer	' Couleur du texte inactif
End Type


Dim mnuODCouleurs		As ODCouleur
Dim mnuODDefCouleurs	As ODCouleur
Dim mnuODMesCouleurs	As ODCouleur

' Je dois évaluer la plus longue chaîne avant de retirer les
' espace supplémentaires
CREATE pNewSysMenu AS QPOPUPMENU
	CREATE pSysRestore AS QMENUITEM
		Caption = "Restaurer"
		'ShortCut = ""
	END CREATE
	CREATE pSysMove AS QMENUITEM
		Caption = "Déplacer"
		'ShortCut = ""
	END CREATE
	CREATE pSysResize AS QMENUITEM
		Caption = "Taille"
		'ShortCut = ""
	END CREATE
	CREATE pSysMinimize AS QMENUITEM
		Caption = "Réduire"
		'ShortCut = ""
	END CREATE
	CREATE pSysMaximize AS QMENUITEM
		Caption = "Agrandir"
		'ShortCut = ""
	END CREATE
	CREATE pSysSeparator AS QMENUITEM
		Caption = "-"
	END CREATE
	CREATE pSysTerminate AS QMENUITEM
		Caption = "Fermer"
		ShortCut = "Alt+F4"
	END CREATE
END CREATE



' Ce SUB va être appellé chaque fois qu'un élément est sélectionné, 
' donc remplissez ce SUB avec vos paramêtres...
' moCaption   = Le titre du menue propriétaire, si null considérez 
'               que c'est votre fenêtre
' iCaption    = Le titre de l'élément sélectionné
'Declare Sub GetInfoFromMenu (iCaption As String) '(moCaption As String, iCaption As String)

'=======================================
' Méthode affiche le texte de menu
'=======================================
Const ODCOLOR_SCROLLBAR					As Long = -1
Const ODCOLOR_BACKGROUND				As Long = -2
Const ODCOLOR_DESKTOP					As Long = ODCOLOR_BACKGROUND
Const ODCOLOR_ACTIVECAPTION				As Long = -3
Const ODCOLOR_INACTIVECAPTION			As Long = -4
Const ODCOLOR_MENU						As Long = -5
Const ODCOLOR_WINDOW					As Long = -6
Const ODCOLOR_WINDOWFRAME				As Long = -7
Const ODCOLOR_MENUTEXT					As Long = -8
Const ODCOLOR_WINDOWTEXT				As Long = -9
Const ODCOLOR_CAPTIONTEXT				As Long = -10
Const ODCOLOR_ACTIVEBORDER				As Long = -11
Const ODCOLOR_INACTIVEBORDER			As Long = -12
Const ODCOLOR_APPWORKSPACE				As Long = -13
Const ODCOLOR_HIGHLIGHT					As Long = -14
Const ODCOLOR_HIGHLIGHTTEXT				As Long = -15
Const ODCOLOR_BTNFACE					As Long = -16
Const ODCOLOR_3DFACE					As Long = ODCOLOR_BTNFACE
Const ODCOLOR_BTNSHADOW					As Long = -17
Const ODCOLOR_3DSHADOW					As Long = ODCOLOR_BTNSHADOW
Const ODCOLOR_GRAYTEXT					As Long = -18
Const ODCOLOR_BTNTEXT					As Long = -19
Const ODCOLOR_INACTIVECAPTIONTEXT		As Long = -20
Const ODCOLOR_BTNHIGHLIGHT				As Long = -21
Const ODCOLOR_BTNHILIGHT				As Long = ODCOLOR_BTNHIGHLIGHT
Const ODCOLOR_3DHIGHLIGHT				As Long = ODCOLOR_BTNHIGHLIGHT
Const ODCOLOR_3DHILIGHT					As Long = ODCOLOR_BTNHIGHLIGHT
Const ODCOLOR_3DDKSHADOW				As Long = -22
Const ODCOLOR_3DLIGHT					As Long = -23
Const ODCOLOR_INFOTEXT					As Long = -24
Const ODCOLOR_INFOBK					As Long = -25
'Const ODCOLOR_
Const ODCOLOR_HOTLIGHT					As Long = -27
Const ODCOLOR_GRADIENTACTIVECAPTION		As Long = -28
Const ODCOLOR_GRADIENTINACTIVECAPTION	As Long = -29

Const COLOR_MENU_mOD			= 4		'Menu
Const COLOR_MENUTEXT_mOD		= 7		'Window Text
Const COLOR_HIGHLIGHT_mOD		= 13	'Selected item background
Const COLOR_HIGHLIGHTTEXT_mOD	= 14	'Selected menu item
Const COLOR_GRAYTEXT_mOD		= 17	'Grey text, of zero if dithering is used.

Const COLOR_BTNFACE_mOD			= 15
Const COLOR_BTNSHADOW_mOD		= 16

Const DT_SINGLELINE_mOD	As Long = &H20
Const DT_RIGHT_mOD		As Long = &H2
Const DT_CENTER_mOD		As Long = &H1
Const DT_VCENTER_mOD	As Long = &H4

'Const DT_ACCEPT_DBCS As Long = (&H20)
'Const DT_AGENT As Long = (&H3)
'Const DT_BOTTOM As Long = &H8
'Const DT_CALCRECT As Long = &H400
'Const DT_CENTER As Long = &H1
'Const DT_CHARSTREAM As Long = 4
'Const DT_DISPFILE As Long = 6
'Const DT_DISTLIST As Long = (&H1)
'Const DT_EDITABLE As Long = (&H2)
'Const DT_EDITCONTROL As Long = &H2000
'Const DT_END_ELLIPSIS As Long = &H8000
Const DT_EXPANDTABS_mOD As Long = &H40
'Const DT_EXTERNALLEADING As Long = &H200
'Const DT_FOLDER As Long = (&H1000000)
'Const DT_FOLDER_LINK As Long = (&H2000000)
'Const DT_FOLDER_SPECIAL As Long = (&H4000000)
'Const DT_FORUM As Long = (&H2)
'Const DT_GLOBAL As Long = (&H20000)
'Const DT_HIDEPREFIX As Long = &H100000
'Const DT_INTERNAL As Long = &H1000
'Const DT_LEFT As Long = &H0
'Const DT_LOCAL As Long = (&H30000)
'Const DT_MAILUSER As Long = (&H0)
'Const DT_METAFILE As Long = 5
'Const DT_MODIFIABLE As Long = (&H10000)
'Const DT_MODIFYSTRING As Long = &H10000
'Const DT_MULTILINE As Long = (&H1)
'Const DT_NOCLIP As Long = &H100
'Const DT_NOFULLWIDTHCHARBREAK As Long = &H80000
'Const DT_NOPREFIX As Long = &H800
'Const DT_NOT_SPECIFIC As Long = (&H50000)
'Const DT_ORGANIZATION As Long = (&H4)
'Const DT_PASSWORD_EDIT As Long = (&H10)
'Const DT_PATH_ELLIPSIS As Long = &H4000
'Const DT_PLOTTER As Long = 0
'Const DT_PREFIXONLY As Long = &H200000
'Const DT_PRIVATE_DISTLIST As Long = (&H5)
'Const DT_RASCAMERA As Long = 3
'Const DT_RASDISPLAY As Long = 1
'Const DT_RASPRINTER As Long = 2
'Const DT_REMOTE_MAILUSER As Long = (&H6)
'Const DT_REQUIRED As Long = (&H4)
'Const DT_RIGHT As Long = &H2
'Const DT_RTLREADING As Long = &H20000
'Const DT_SET_IMMEDIATE As Long = (&H8)
'Const DT_SET_SELECTION As Long = (&H40)
'Const DT_SINGLELINE As Long = &H20
Const DT_TABSTOP_mOD As Long = &H80
'Const DT_TOP As Long = &H0
'Const DT_VCENTER As Long = &H4
'Const DT_WAN As Long = (&H40000)
'Const DT_WORD_ELLIPSIS As Long = &H40000
'Const DT_WORDBREAK As Long = &H10


'Const OPAQUE_mOD = 2
Const TRANSPARENT_mOD = 1

Const NULL_BRUSH_mOD		As Long = 5
'Const ANSI_VAR_FONT_mOD	As Long = 12
'Const SYSTEM_FONT_mOD	As Long = 13

Declare Function SetBkMode_mOD Lib "gdi32" Alias "SetBkMode" ( _
        ByVal hdc As Long, _
        ByVal nBkMode As Long ) As Long

Declare Function FillRect_mOD Lib "user32" Alias "FillRect" ( _
        ByVal hdc As Long, _
        lpRect As RECT_mOD, _
        ByVal hBrush As Long ) As Long
Declare Function GetSysColorBrush_mOD Lib "user32" Alias "GetSysColorBrush" ( _
        ByVal nIndex As Long ) As Long
Declare Function GetStockObject_mOD Lib "gdi32" Alias "GetStockObject" ( _
		ByVal nIndex As Long) As Long
Declare Function GetObject_mOD Lib "gdi32" Alias "GetObjectA" ( _
		ByVal hObject As Long, _
		ByVal nCount As Long, _
		lpObject As Long) As Long

Declare Function SetTextColor_mOD Lib "gdi32" Alias "SetTextColor" ( _
        ByVal hDC As Long, _
        ByVal crColor As Long ) As Long

Declare Function DrawText_mOD Lib "user32" Alias "DrawTextA" (_
		ByVal hdc As Long, _
		ByVal lpStr As String, _
		ByVal nCount As Long, _
		lpRect As RECT_mOD, _
		ByVal wFormat As Long) As Long
Type DRAWTEXTPARAMS_mOD
	cbSize			As Long 
	iTabLength		As Long 
	iLeftMargin		As Long 
	iRightMargin	As Long 
	uiLengthDrawn	As Long 
End Type 
Declare Function DrawTextEx_mOD Lib "user32" Alias "DrawTextExA" ( _
		ByVal hDC As Long, _
		ByVal lpsz As String, _
		ByVal n As Long, _
		lpRect As RECT_mOD, _
		ByVal un As Long, _
		lpDrawTextParams As DRAWTEXTPARAMS_mOD) As Long

' Font Weights
'Const FW_DONTCARE = 0
'Const FW_THIN = 100
'Const FW_EXTRALIGHT = 200
'Const FW_LIGHT = 300
Const FW_NORMAL_mOD = 400
'Const FW_MEDIUM = 500
'Const FW_SEMIBOLD = 600
'Const FW_BOLD_mOD = 700
'Const FW_EXTRABOLD = 800
'Const FW_HEAVY = 900

' Logical Font
'Const LF_FACESIZE_mOD		= 32
'Const LF_FULLFACESIZE	= 64

'Type LOGFONT_mOD
'	lfHeight		As Long
'	lfWidth			As Long
'	lfEscapement	As Long
'	lfOrientation	As Long
'	lfWeight		As Long
'	lfItalic		As Byte
'	lfUnderline		As Byte
'	lfStrikeOut		As Byte
'	lfCharSet		As Byte
'	lfOutPrecision	As Byte
'	lfClipPrecision	As Byte
'	lfQuality		As Byte
'	lfPitchAndFamily As Byte
'	lfFaceName(True To LF_FACESIZE_mOD) As Byte
'End Type

Const DEFAULT_CHARSET_mOD		As Long = 1
Const OUT_DEFAULT_PRECIS_mOD	As Long = 0
Const CLIP_DEFAULT_PRECIS_mOD	As Long = 0
Const PROOF_QUALITY_mOD			As Long = 2
Const DEFAULT_PITCH_mOD			As Long = 0

'Declare Function CreateFontIndirect_mOD Lib "gdi32" Alias "CreateFontIndirectA" ( _
'		lpLogFont As LOGFONT_mOD) As Long
Declare Function CreateFont_mOD Lib "gdi32" Alias "CreateFontA" ( _
		ByVal nHeight As Long, _
		ByVal nWidth As Long, _
		ByVal nEscapement As Long, _
		ByVal nOrientation As Long, _
		ByVal fnWeight As Long, _
		ByVal fdwItalic As Integer, _
		ByVal fdwUnderline As Integer, _
		ByVal fdwStrikeOut As Integer, _
		ByVal fdwCharSet As Long, _
		ByVal fdwOutputPrecision As Long, _
		ByVal fdwClipPrecision As Long, _
		ByVal fdwQuality As Long, _
		ByVal fdwPitchAndFamily As Long, _
		ByVal lpszFace As String ) As Long

Declare Function SelectObject_mOD Lib "gdi32" Alias "SelectObject" (ByVal hdc As Long, ByVal hObject As Long) As Long
Declare Function DeleteObject_mOD Lib "gdi32" Alias "DeleteObject" (ByVal hObject As Long) As Long

Function ChangeFont_mOD(nFace As String, nSize As Integer, nWeight As Integer, nDegrees As Long) As Long
	'Create a specified font
	Result = CreateFont_mOD ( _
				13, False, _
				nDegrees * 10, _
				False, _
				nWeight, _
				False, False, False, _
				DEFAULT_CHARSET_mOD, _
				OUT_DEFAULT_PRECIS_mOD, _
				CLIP_DEFAULT_PRECIS_mOD, _
				PROOF_QUALITY_mOD, _
				DEFAULT_PITCH_mOD, _
				nFace ) '"Tahoma"
End Function

'Dim hFont As Long
'Dim lf As LOGFONT_mOD

Dim m_bActive As Integer

Declare Function SetMenuDefaultItem_mOD Lib "user32.dll" Alias "SetMenuDefaultItem" ( _
	 ByVal hMenu As Long, _
	 ByVal uItem As Long, _
	 ByVal fByPos As Long) As Long

Sub DefSysItem ()
	If mnuSysFromIcon = True Then
		SetMenuDefaultItem_mOD (pNewSysMenu.Handle, pSysTerminate.Command, MF_BYCOMMAND)
	Else
		If isZoomed_mOD(mnuSysMainForm) = False Then
			SetMenuDefaultItem_mOD (pNewSysMenu.Handle, pSysMaximize.Command, MF_BYCOMMAND)
		Else
			SetMenuDefaultItem_mOD (pNewSysMenu.Handle, pSysRestore.Command, MF_BYCOMMAND)
		End If
	End If
End Sub


Sub DrawMenuText (lColor As Long, lExtra As Integer)
	Dim Caption As String, ShortCut As String
	Dim txtparam As DRAWTEXTPARAMS_mOD
	Dim lItemRect As RECT_mOD

	If mnuMain(DrawItem.itemId) and hMainMenu = DrawItem.hwnditem and hSysMenu <> DrawItem.hwnditem Then
		If mnuBitmap(DrawItem.itemId) = False Then _
		   SetRect_mOD (lItemRect, DrawItem.Left, DrawItem.Top, DrawItem.Right, DrawItem.Bottom) _
		Else _
		   SetRect_mOD (lItemRect, DrawItem.Left, DrawItem.Top, DrawItem.Right, DrawItem.Bottom)
	Else
	   SetRect_mOD (lItemRect, DrawItem.Left, DrawItem.Top, DrawItem.Right, DrawItem.Bottom)
	End If
	Caption = Field$(VARPTR$(DrawItem.itemData), chr$(9), 1)
	ShortCut = Field$(VARPTR$(DrawItem.itemData), chr$(9), 2)

	If Caption <> "-" and Caption <> "" Then
		SetTextColor_mOD	(DrawItem.hDC, lColor)
		If mnuMain (DrawItem.itemId) and hMainMenu = DrawItem.hwnditem and mnuBitmap (DrawItem.itemId) = False and _
			hSysMenu <> DrawItem.hwnditem and pNewSysMenu.Handle <> DrawItem.HwndItem Then
			DrawText_mOD	( _
				DrawItem.hDC, _
				Caption, LEN(Caption), _
				lItemRect, _
				DT_SINGLELINE_mOD OR DT_VCENTER_mOD OR DT_CENTER_mOD)
		ElseIf pNewSysMenu.Handle = DrawItem.HwndItem Then
			WiTH txtparam
				.cbSize = SizeOf(txtparam)
				.iTabLength = 15
				.iLeftMargin = 31
				.iRightMargin = 10
				.uiLengthDrawn = False
			End WiTH
			DrawTextEx_mOD ( _
				DrawItem.hDC, _
				Caption, LEN(Caption), _
				lItemRect, _
				DT_SINGLELINE_mOD Or DT_VCENTER_mOD Or DT_EXPANDTABS_mOD Or DT_TABSTOP_mOD, _
				txtparam)
		Else
			WiTH txtparam
				.cbSize = SizeOf(txtparam)
				If DrawItem.Right -DrawItem.Left < 140 Then
					.iTabLength = 11
				Else
					.iTabLength = 18
				End If
				'.iTabLength = 18
				.iLeftMargin = IIf(mnuMain(DrawItem.ItemID), 23, 31)
				.iRightMargin = 10
				.uiLengthDrawn = False
			End WiTH
			DrawTextEx_mOD ( _
				DrawItem.hDC, _
				Caption, LEN(Caption), _
				lItemRect, _
				DT_SINGLELINE_mOD Or DT_VCENTER_mOD Or DT_EXPANDTABS_mOD Or DT_TABSTOP_mOD, _
				txtparam)
			'DrawText_mOD	(DrawItem.hDC, Caption, LEN(Caption), lItemRect, _
			'	DT_SINGLELINE_mOD OR DT_VCENTER_mOD OR DT_EXPANDTABS_mOD Or DT_TABSTOP_mOD)
			If mnuSubMenu(DrawItem.ItemID) = True and mnuMain(DrawItem.ItemID) = False Then
				Dim hFont As Long, oldFont As Long

				'SetTextColor_mOD (DrawItem.hDC, &H0000FF)
				hFont = ChangeFont_mOD ("Marlett", 24, FW_NORMAL_mOD, False)
				oldFont = SelectObject_mOD(DrawItem.hDC, hFont)

				lItemRect.Right = lItemRect.Right -True
				DrawText_mOD ( _
					DrawItem.hDC, _
					"8", True, _
					lItemRect, _
					DT_SINGLELINE_mOD Or DT_VCENTER_mOD Or DT_RIGHT_mOD)
				DeleteObject_mOD SelectObject_mOD(DrawItem.hDC, oldFont)
				DeleteObject_mOD hFont
			End If
		End If
		If ShortCut <> "" Then
			SetRect_mOD	(lItemRect, DrawItem.Right -71, DrawItem.Top, DrawItem.Right -8, DrawItem.Bottom)
			DrawText_mOD ( _
				DrawItem.hDC, _
				ShortCut, LEN(ShortCut), _
				lItemRect, _
				DT_SINGLELINE_mOD OR DT_VCENTER_mOD OR DT_RIGHT_mOD)
		End If
	Else
		' Rempli le rectangle avec une couleur système
		SetRect_mOD	(lItemRect, DrawItem.Left +31, DrawItem.Top +2, DrawItem.Right -3, DrawItem.Top +3)
		FillRect_mOD	(DrawItem.hDC, lItemRect, GetSysColorBrush_mOD(COLOR_GRAYTEXT_mOD))
	End If
End Sub

'======================================
'
'======================================
Declare Function Rectangle_mOD Lib "gdi32" Alias "Rectangle" ( _
		ByVal hdc As Long, _
		ByVal X1 As Long, _
		ByVal Y1 As Long, _
		ByVal X2 As Long, _
		ByVal Y2 As Long) As Long

Declare Function CreatePen_mOD Lib "gdi32" Alias "CreatePen" ( _
		ByVal nPenStyle As Long, _
		ByVal nWidth As Long, _
		ByVal crColor As Long ) As Long
Declare Function CreateSolidBrush_mOD Lib "gdi32" Alias "CreateSolidBrush" ( _
		ByVal crColor As Long) As Long

Type LOGBRUSH_mOD
	lbStyle As Long
	lbColor As Long
	lbHatch As Long
End Type
Type LOGPEN_mOD
	lopnStyle As Long
	lopnWidthX As Long 'POINTAPI_mOD
	lopnWidthY As Long 'POINTAPI_mOD
	lopnColor As Long
End Type

Const BS_SOLID_mOD As Long = 0
Const HS_SOLID_mOD As Long = 8

Const PS_SOLID_mOD As Long = 0

' 0. mnuFond, 1. mnuCont, 
' 2. itemFond1, 3. itemFond2, 
' 4. itemSel1, 5. itemSel2, 
' 6. ..., 7. ..., 
' 8. ..., 9. ..., 
' 10. ItemContSel, 11. ItemContSelInact, 
' 12. mnuMainFond
'Dim hHBr(13) As Long
Dim hRPen As Long
Dim hSRBr As Long

' Crée un pinceau ou un crayon réutilisable
Declare Function CreateBrushIndirect_mOD Lib "gdi32" Alias "CreateBrushIndirect" ( _
		lpLogBrush As LOGBRUSH_mOD ) As Long
Declare Function CreatePenIndirect_mOD Lib "gdi32" Alias "CreatePenIndirect" ( _
		lpLogPen As LOGPEN_mOD ) As Long

Sub ChangeBrush (nColor As Integer)
	'DeleteObject_mOD hSRBr
	hSRBr	= CreateSolidBrush_mOD (nColor)
End Sub
Sub ChangePen (nSize As Integer, nColor As Integer)
	' Il semblerait que si nSize est supérieur à 1
	' que le crayon créé soit de 3 à 10 plus lent
	If nSize > 2 Then nSize = 2 ' Bug étrange
	'DeleteObject_mOD hRPen
	hRPen	= CreatePen_mOD (PS_SOLID_mOD, nSize, nColor)
End Sub

WiTH mnuODDefCouleurs
	.MainMenuTxt		= GetSysColor_mOD(COLOR_MENUTEXT_mOD)	' Couleur du texte de la barre de menu
	.MainMenuTxtSel		= GetSysColor_mOD(COLOR_HIGHLIGHTTEXT_mOD)	' Couleur du texte sélectionné de la barre de menu
	.MainMenuTxtInactif	= GetSysColor_mOD(COLOR_GRAYTEXT_mOD)	' Couleur du texte inactif de la barre de menu
	.MenuFond			= &HFFFFFF	' Couleur du menu
	.MenuCont			= GetSysColor_mOD(COLOR_BTNSHADOW_mOD)	' Couleur de la bordure, si plat
	.ItemFond1			= &HFFFFFF	' Couleur de l'item
	.ItemFond2			= &HEFE7E0	' Couleur de l'item sous l'icône
	.ItemFondSel1		= &HFFDFBF	' Couleur de l'item sélectionné
	.ItemFondSel2		= &HFFDFBF	' Couleur de l'item sous l'icône sélectionnée
	.ItemFondInact1		= &HFFFFFF	' Couleur de l'item inactif
	.ItemFondInact2		= &HEFE7E0	' Couleur de l'item sous l'icône inactive
	.ItemFondSelInact1	= &HFFFFFF	' Couleur de l'item inactif sélectionné
	.ItemFondSelInact2	= &HFFFFFF	' Couleur de l'item sous l'icône inactive sélectionnée
	.ItemContSel		= &H903F00	' Couleur de la bordue, si plat
	.ItemContSelInactif	= GetSysColor_mOD(COLOR_BTNSHADOW_mOD)	' Couleur de la bordure inactive, si plat
	.ItemTxt			= GetSysColor_mOD(COLOR_MENUTEXT_mOD)	' Couleur du texte
	.ItemTxtSel			= &H903F00	' Couleur du texte sélectionné
	.ItemTxtInactif		= GetSysColor_mOD(COLOR_GRAYTEXT_mOD)	' Couleur du texte inactif
End WiTH
mnuODMesCouleurs = mnuODDefCouleurs


Function CheckIfSYSColor (lColor As Integer) As Integer
	If lColor =< -True and lColor => -29 Then ' SGN(lColor) = -True Then
		' Retourne la couleur correspondante
		Result = GetSysColor_mOD((lColor *-True) -True)
	ElseIf lColor =< -2147483624 and lColor => -2147483648 Then
		' Conversion des couleurs systèmes RapidQ pour être utilisées par les APIs
		Select Case lColor
			Case -2147483648: lColor = GetSysColor_mOD(False)		' clScrollBar
			Case -2147483647: lColor = GetSysColor_mOD(True)		' clBackGround
			Case -2147483646: lColor = GetSysColor_mOD(2)		' clActiveCaption
			Case -2147483645: lColor = GetSysColor_mOD(3)		' clInActiveCaption
			Case -2147483644: lColor = GetSysColor_mOD(4)		' clMenu
			Case -2147483643: lColor = GetSysColor_mOD(5)		' clWindow
			Case -2147483642: lColor = GetSysColor_mOD(6)		' clWindowFrame
			Case -2147483641: lColor = GetSysColor_mOD(7)		' clMenuText
			Case -2147483640: lColor = GetSysColor_mOD(8)		' clWindowText
			Case -2147483639: lColor = GetSysColor_mOD(9)		' clCaptionText
			Case -2147483638: lColor = GetSysColor_mOD(10)	' clActiveBorder
			Case -2147483637: lColor = GetSysColor_mOD(11)	' clInActiveBorder
			Case -2147483636: lColor = GetSysColor_mOD(12)	' clAppWorkSpace
			Case -2147483635: lColor = GetSysColor_mOD(13)	' clHilight
			Case -2147483634: lColor = GetSysColor_mOD(14)	' clHilightText
			Case -2147483633: lColor = GetSysColor_mOD(15)	' clBtnFace
			Case -2147483632: lColor = GetSysColor_mOD(16)	' clBtnShadow
			Case -2147483631: lColor = GetSysColor_mOD(17)	' clGrayText
			Case -2147483630: lColor = GetSysColor_mOD(18)	' clBtnText
			Case -2147483629: lColor = GetSysColor_mOD(19)	' clInActiveCaptionText
			Case -2147483628: lColor = GetSysColor_mOD(20)	' clBtnHighlight
			Case -2147483627: lColor = GetSysColor_mOD(21)	' cl3DDkShadow
			Case -2147483626: lColor = GetSysColor_mOD(22)	' cl3DLight
			Case -2147483625: lColor = GetSysColor_mOD(23)	' clInfoText
			Case -2147483624: lColor = GetSysColor_mOD(25)	' clInfoBk3DDkShadow
			'Case 536870911: lColor = GetSysColor_mOD()		' clNone
			'Case 536870912: lColor = GetSysColor_mOD()		' clDefault
			Case Else
				lColor = GetSysColor_mOD(15)
		End Select

		' Retourne la couleur correspondante
		Result = lColor
	Else
		' Retourne la couleur non modifiée
		Result = lColor
	End If
End Function
Sub UpdateColors
	' // Charge les nouvelles couleurs
	'hHBr(13)	= GetStockObject_mOD(NULL_BRUSH_mOD)
	'WiTH mnuODCouleurs
	'	ChangeBrush	(True, GetSysColor_mOD(COLOR_BTNFACE_mOD), 12)
	'	ChangeBrush	(True, .ItemContSelInactif, 11)
	'	ChangeBrush	(True, .ItemContSel, 10)
	'	ChangeBrush	(True, .ItemFondSelInact2, 9)
	'	ChangeBrush	(True, .ItemFondSelInact1, 8)
	'	ChangeBrush	(True, .ItemFondInact2, 7)
	'	ChangeBrush	(True, .ItemFondInact1, 6)
	'	ChangeBrush	(True, .ItemFondSel2, 5)
	'	ChangeBrush	(True, .ItemFondSel1, 4)
	'	ChangeBrush	(True, .ItemFond2, 3)
	'	ChangeBrush	(True, .ItemFond1, 2)
	'	ChangeBrush	(2, .MenuCont, 1)
	'	ChangeBrush	(True, .MenuFond, False)
	'End WiTH
	DrawMenuBar_mOD(hMainMenu)
End Sub
Sub LoadNewColors
	' // Charge nos nouvelles couleurs
	WiTH mnuODMesCouleurs
		.MainMenuTxt		= CheckIfSYSColor(.MainMenuTxt)
		.MainMenuTxtSel		= CheckIfSYSColor(.MainMenuTxtSel)
		.MainMenuTxtInactif	= CheckIfSYSColor(.MainMenuTxtInactif)
		.MenuFond			= CheckIfSYSColor(.MenuFond)
		.MenuCont			= CheckIfSYSColor(.MenuCont)
		.ItemFond1			= CheckIfSYSColor(.ItemFond1)
		.ItemFond2			= CheckIfSYSColor(.ItemFond2)
		.ItemFondSel1		= CheckIfSYSColor(.ItemFondSel1)
		.ItemFondSel2		= CheckIfSYSColor(.ItemFondSel2)
		.ItemFondInact1		= CheckIfSYSColor(.ItemFondInact1)
		.ItemFondInact2		= CheckIfSYSColor(.ItemFondInact2)
		.ItemFondSelInact1	= CheckIfSYSColor(.ItemFondSelInact1)
		.ItemFondSelInact2	= CheckIfSYSColor(.ItemFondSelInact2)
		.ItemContSel		= CheckIfSYSColor(.ItemContSel)
		.ItemContSelInactif	= CheckIfSYSColor(.ItemContSelInactif)
		.ItemTxt			= CheckIfSYSColor(.ItemTxt)
		.ItemTxtSel			= CheckIfSYSColor(.ItemTxtSel)
		.ItemTxtInactif		= CheckIfSYSColor(.ItemTxtInactif)
	End WiTH
	mnuODCouleurs = mnuODMesCouleurs
	Call UpdateColors
End Sub
Sub LoadDefaultColors
	' // Attention ceci va remplacer nos couleurs par les couleurs prédéfinies
	mnuODCouleurs = mnuODDefCouleurs
	Call UpdateColors
End Sub
Call LoadDefaultColors


Declare Sub pDrawBorder (hMenu As Long)

Sub DrawMenuRectangle( Left, Top, Right, Bottom, lColor1 As Long, lColor2 As Long, lExtra As Integer, iBrush As Integer )
	Dim hPen As Long
	Dim hBr As Long

	If mnuMain(DrawItem.itemId) and hMainMenu = DrawItem.hwnditem and lExtra = False and hSysMenu <> DrawItem.hwnditem Then
		lColor1 = GetSysColor_mOD(COLOR_BTNFACE_mOD)
		'lColor2 = GetSysColor_mOD(COLOR_BTNFACE_mOD)
		iBrush = 12
		ChangeBrush (lColor1)
	Else
		' Crée un nouveau pinceau
		'hHBr = CreateSolidBrush_mOD(lColor2)
		ChangeBrush (lColor2)
	End If
	' Sélectionne le nouveau pinceau dans le DC et supprime l'ancien
	hBr = SelectObject_mOD(DrawItem.hDC, hSRBr) 'hHBr)
	' Crée un nouveau crayon
	ChangePen (True, lColor1)
	' Sélectionne le nouveau crayon dans le DC et supprime l'ancien
	hPen = SelectObject_mOD(DrawItem.hDC, hRPen) 'hRPen)

	Rectangle_mOD ( _
		DrawItem.hDC, left, top, right, bottom )

	' Restaure et supprime le crayon et le pinceau
	DeleteObject_mOD SelectObject_mOD(DrawItem.hDC, hPen)
	DeleteObject_mOD SelectObject_mOD(DrawItem.hDC, hBr)
End Sub

'=======================================
' Méthode affiche le bouton de menu
'=======================================
' Pour Win98 et supérieur
Declare Function TransparentBlt_mOD Lib "msimg32" _
		Alias "TransparentBlt" ( _
		ByVal hdcDest As Long, _
		ByVal nXOriginDest As Long, ByVal nYOriginDest As Long, _
		ByVal nWidthDest As Long, ByVal nHeightDest As Long, _
		ByVal hdcSrc As Long, _
		ByVal nXOriginSrc As Long, ByVal nYOriginSrc As Long, _
		ByVal nWidthSrc As Long, ByVal nHeightSrc As Long, _
		ByVal crTransparent As Long) As Long

Sub DrawMenuBitmap(lExtra As Integer)
	Dim tmpBMP As QBitmap ', _
		'bgBMP As QBitmap
	Dim isEnabled As Integer, _
		isRadio As Integer, _
		isCheck As Integer, _
		isDecal As Integer
		isDecal = False
	Dim cIndex As String

	tmpBMP.Width	= 20
	tmpBMP.Height	= 20
	tmpBMP.FillRect	(False, False, 20, 20, clPurple)
	'bgBMP.Width	= 20
	'bgBMP.Height	= 20
	'bgBMP.FillRect	(False, False, 20, 20, &HEFE7E0)

	If mnuBitmap(DrawItem.itemId) => mnuImgL.Count Then _
	   mnuBitmap(DrawItem.itemId) = False
	If mnuIcoHotFx = False or mnuIcoHotFx > 4 Then _
		isDecal = True

	'If mnuBitmap(DrawItem.itemId) < False Then
		If mnuBitmap(DrawItem.itemId) = -True and mnuCheckBMP.Empty = False Then
			isCheck = True
		'ElseIf mnuBitmap(DrawItem.itemId) = -2 Then
		'	isRadio = True
		'Else
		'	mnuBitmap(DrawItem.itemId) = False
		End If
	'End If

	If lExtra = 2 Then
		'If isRadio = False Then _
			isRadio = GetMenuCheckState(DrawItem.hwnditem, DrawItem.ItemID)
		isEnabled = IIf((MFS_DISABLED AND DrawItem.itemState) <> False, False, True)

		If (MFS_CHECKED and DrawItem.itemState) = False and DrawItem.HwndItem <> pNewSysMenu.Handle Then
			If mnuCheckStyle and isRadio and mnuRadioBMP.Empty = False and (mnuRadioBMPCount > True) Then
				If isEnabled or (isEnabled = False and mnuRadioBMPCount < 4) Then
				'	tmpBMP.Draw(2, 2, mnuUnRadioBMP.BMP)
					BitBlt_mOD ( _
						tmpBMP.Handle, _
						2, 2, _
						mnuRadioBMP.Width /mnuRadioBMPCount, mnuRadioBMP.Height, _
						mnuRadioBMP.Handle, _
						mnuRadioBMP.Width /4, False, _
						SRCCOPY_mOD )
				Else
				'	tmpBMP.Draw(2, 2, mnuUnRadioDisBMP.BMP)
					BitBlt_mOD  ( _
						tmpBMP.Handle, _
						2, 2, _
						mnuRadioBMP.Width /mnuRadioBMPCount, mnuRadioBMP.Height, _
						mnuRadioBMP.Handle, _
						mnuRadioBMP.Width /2, False, _
						SRCCOPY_mOD )
				End If
			ElseIf mnuCheckStyle and isCheck and isRadio = False and mnuCheckBMP.Empty = False and (mnuCheckBMPCount > True) Then
				If isEnabled or (isEnabled = False and mnuCheckBMPCount < 4) Then
				'	tmpBMP.Draw(2, 2, mnuUnCheckBMP.BMP)
					BitBlt_mOD ( _
						tmpBMP.Handle, _
						2, 2, _
						mnuCheckBMP.Width /mnuCheckBMPCount, mnuCheckBMP.Height, _
						mnuCheckBMP.Handle, _
						mnuCheckBMP.Width /4, False, _
						SRCCOPY_mOD )
				Else
				'	tmpBMP.Draw(2, 2, mnuUnCheckDisBMP.BMP)
					BitBlt_mOD  ( _
						tmpBMP.Handle, _
						2, 2, _
						mnuCheckBMP.Width /mnuCheckBMPCount, mnuCheckBMP.Height, _
						mnuCheckBMP.Handle, _
						mnuCheckBMP.Width /2, False, _
						SRCCOPY_mOD )
				End If
			Else
				If mnuIcoHotFx >= 2 Then
					mnuImgL.DrawingStyle = True
					mnuImgL.Draw	( tmpBMP, False, False, mnuBitmap(DrawItem.itemId) )

					TransparentBlt_mOD( DrawItem.hDC, _
										  DrawItem.left +4, DrawItem.top +2, _
										  20, 20, _
										  tmpBMP.Handle, _
										  False, False, _
										  20, 20, _
										  clPurple ) 'tmpBMP.Pixel(True, True) )
				End If
				mnuImgL.DrawingStyle = 2
				mnuImgL.Draw	( tmpBMP, False, False, mnuBitmap(DrawItem.itemId) ) '_
			End If

		Else 'If DrawItem.HwndItem = pNewSysMenu.Handle Then
			tmpBMP.Font.Name = "Marlett"
			tmpBMP.Font.Size = 10

			Select Case DrawItem.ItemID
				Case pSysTerminate.Command
					cIndex = "r"
				Case pSysMaximize.Command
					cIndex = "1"
				Case pSysMinimize.Command
					cIndex = "0"
				'Case pSysResize.Command
				'Case pSysMove.Command
				Case pSysRestore.Command
					cIndex = "2"
				Case Else
					cIndex = ""
					If (MFS_CHECKED And DrawItem.itemState) <> False Then
						If mnuCheckStyle and (mnuCheckBMP.Empty = False or (isRadio and mnuRadioBMP.Empty = False)) Then
							If isRadio Then
								If isEnabled or (isEnabled = False and (mnuRadioBMPCount < 3)) Then
								'	tmpBMP.Draw(2, 2, mnuRadioBMP.BMP)
									BitBlt_mOD ( _
										tmpBMP.Handle, _
										2, 2, _
										mnuRadioBMP.Width /mnuRadioBMPCount, mnuRadioBMP.Height, _
										mnuRadioBMP.Handle, _
										False, False, _
										SRCCOPY_mOD )
								Else
								'	tmpBMP.Draw(2, 2, mnuRadioDisBMP.BMP)
									BitBlt_mOD ( _
										tmpBMP.Handle, _
										2, 2, _
										mnuRadioBMP.Width /mnuRadioBMPCount, mnuRadioBMP.Height, _
										mnuRadioBMP.Handle, _
										mnuRadioBMP.Width /2, False, _
										SRCCOPY_mOD )
								End If
							Else
								If isEnabled or (isEnabled = False and (mnuCheckBMPCount < 3)) Then
								'	tmpBMP.Draw(2, 2, mnuCheckBMP.BMP)
									BitBlt_mOD ( _
										tmpBMP.Handle, _
										2, 2, _
										mnuCheckBMP.Width /mnuCheckBMPCount, mnuCheckBMP.Height, _
										mnuCheckBMP.Handle, _
										False, False, _
										SRCCOPY_mOD )
								Else
								'	tmpBMP.Draw(2, 2, mnuCheckDisBMP.BMP)
									BitBlt_mOD ( _
										tmpBMP.Handle, _
										2, 2, _
										mnuCheckBMP.Width /mnuCheckBMPCount, mnuCheckBMP.Height, _
										mnuCheckBMP.Handle, _
										mnuCheckBMP.Width /2, False, _
										SRCCOPY_mOD )
								End If
							End If
						Else
							cIndex = IIf(isRadio, "h", "a")
						End If
					End If
						
					'If (MFS_CHECKED And DrawItem.itemState) <> False Then _
					'	ShowMessage STR$(GetMenuCheckBMPHandle(DrawItem.hwnditem, DrawItem.ItemID))
							
			End Select

			If cIndex <> "" Then _
				tmpBMP.TextOut ( _
								 (18 -tmpBMP.TextWidth(cIndex)) \2, _
								 (18 -tmpBMP.TextHeight(cIndex)) \2, _
								 cIndex, _
								 clMenuText, -True)
		End If

		If (mnuIcoHotFx = 3 or mnuIcoHotFx = 4) and (isRadio or isCheck) Then _
			isDecal = True

		TransparentBlt_mOD( DrawItem.hDC, _
							  DrawItem.left +3 +isDecal, DrawItem.top +True +isDecal, _
							  20, 20, _
							  tmpBMP.Handle, _
							  False, False, _
							  20, 20, _
							  clPurple ) 'tmpBMP.Pixel(True, True) )
	Else
		'If isRadio = False Then _
			isRadio = GetMenuCheckState(DrawItem.hwnditem, DrawItem.ItemID)
		'isEnabled = IIf((MFS_DISABLED AND DrawItem.itemState) <> False, False, True)
		If (MFS_CHECKED And DrawItem.itemState) = False and DrawItem.HwndItem <> pNewSysMenu.Handle Then
			'If lExtra = True Then _
			'	mnuImgL.DrawingStyle = True
			If mnuCheckStyle and isRadio and mnuRadioBMP.Empty = False Then
				If lExtra <> True or (lExtra = True and mnuRadioBMPCount < 4) Then
				'	tmpBMP.Draw(2, 2, mnuUnRadioBMP.BMP)
					BitBlt_mOD ( _
						tmpBMP.Handle, _
						2, 2, _
						mnuRadioBMP.Width /mnuRadioBMPCount, mnuRadioBMP.Height, _
						mnuRadioBMP.Handle, _
						mnuRadioBMP.Width /4, False, _
						SRCCOPY_mOD )
				Else
				'	tmpBMP.Draw(2, 2, mnuUnRadioDisBMP.BMP)
					BitBlt_mOD  ( _
						tmpBMP.Handle, _
						2, 2, _
						mnuRadioBMP.Width /mnuRadioBMPCount, mnuRadioBMP.Height, _
						mnuRadioBMP.Handle, _
						mnuRadioBMP.Width /2, False, _
						SRCCOPY_mOD )
				End If
			ElseIf mnuCheckStyle and isCheck and isRadio = False and mnuCheckBMP.Empty = False Then
				If lExtra <> True or (lExtra = True and mnuCheckBMPCount < 4) Then
				'	tmpBMP.Draw(2, 2, mnuUnCheckBMP.BMP)
					BitBlt_mOD ( _
						tmpBMP.Handle, _
						2, 2, _
						mnuCheckBMP.Width /mnuCheckBMPCount, mnuCheckBMP.Height, _
						mnuCheckBMP.Handle, _
						mnuCheckBMP.Width /4, False, _
						SRCCOPY_mOD )
				Else
				'	tmpBMP.Draw(2, 2, mnuUnCheckDisBMP.BMP)
					BitBlt_mOD  ( _
						tmpBMP.Handle, _
						2, 2, _
						mnuCheckBMP.Width /mnuCheckBMPCount, mnuCheckBMP.Height, _
						mnuCheckBMP.Handle, _
						mnuCheckBMP.Width /2, False, _
						SRCCOPY_mOD )
				End If
			Else
				mnuImgL.Draw	( tmpBMP, False, False, mnuBitmap(DrawItem.itemId) )
			End If
			'If lExtra = True Then _
			'	BitBlt ( tmpBMP.Handle, _
			'			 False, False, _
			'			 20, 20, _
			'			 bgBMP.Handle, _
			'			 False, False, _
			'			 PATPAINT )
		Else 'If DrawItem.HwndItem = pNewSysMenu.Handle Then
			tmpBMP.Font.Name = "Marlett"
			tmpBMP.Font.Size = 10

			Select Case DrawItem.ItemID
				Case pSysTerminate.Command
					cIndex = "r"
				Case pSysMaximize.Command
					cIndex = "1"
				Case pSysMinimize.Command
					cIndex = "0"
				'Case pSysResize.Command
				'Case pSysMove.Command
				Case pSysRestore.Command
					cIndex = "2"
				Case Else
					cIndex = ""
					If (MFS_CHECKED And DrawItem.itemState) <> False Then
						If mnuCheckStyle and (mnuCheckBMP.Empty = False or (isRadio and mnuRadioBMP.Empty = False)) Then
							If isRadio Then
								If lExtra <> True or (lExtra = True and mnuRadioBMPCount < 3) Then
								'	tmpBMP.Draw(2, 2, mnuRadioBMP.BMP)
									BitBlt_mOD ( _
										tmpBMP.Handle, _
										2, 2, _
										mnuRadioBMP.Width /mnuRadioBMPCount, mnuRadioBMP.Height, _
										mnuRadioBMP.Handle, _
										False, False, _
										SRCCOPY_mOD )
								Else
								'	tmpBMP.Draw(2, 2, mnuRadioDisBMP.BMP)
									BitBlt_mOD  ( _
										tmpBMP.Handle, _
										2, 2, _
										mnuRadioBMP.Width /mnuRadioBMPCount, mnuRadioBMP.Height, _
										mnuRadioBMP.Handle, _
										mnuRadioBMP.Width /2, False, _
										SRCCOPY_mOD )
								End If
							Else
								If lExtra <> True or (lExtra = True and (mnuCheckBMPCount < 3)) Then
								'	tmpBMP.Draw(2, 2, mnuCheckBMP.BMP)
									BitBlt_mOD ( _
										tmpBMP.Handle, _
										2, 2, _
										mnuCheckBMP.Width /mnuCheckBMPCount, mnuCheckBMP.Height, _
										mnuCheckBMP.Handle, _
										False, False, _
										SRCCOPY_mOD )
								Else
								'	tmpBMP.Draw(2, 2, mnuCheckDisBMP.BMP)
									BitBlt_mOD ( _
										tmpBMP.Handle, _
										2, 2, _
										mnuCheckBMP.Width /mnuCheckBMPCount, mnuCheckBMP.Height, _
										mnuCheckBMP.Handle, _
										mnuCheckBMP.Width /2, False, _
										SRCCOPY_mOD )
								End If
							End If
						Else
							cIndex = IIf(isRadio, "h", "a")
						End If
					'Else
						'If mnuCheckStyle and (mnuCheckBMP.Empty = True or mnuCheckBMP.Empty = True) Then _
						'	cIndex = ""
					End If
			End Select

			If cIndex <> "" Then _
				tmpBMP.TextOut ( _
								 (18 -tmpBMP.TextWidth(cIndex)) \2, _
								 (18 -tmpBMP.TextHeight(cIndex)) \2, _
								 cIndex, _
								 IIf(lExtra = True, clGrayText, clMenuText), -True)
		End If

		If (lExtra = True and isRadio = False and isCheck = False) or m_bActive = False Then
			Dim alBMP As QBitmap
			alBMP.Width		= 20
			alBMP.Height	= 20
			alBMP.FillRect	(False, False, 20, 20, GetPixel_mOD(DrawItem.hDC, DrawItem.left +4, DrawItem.top +2))
			
	        With BF_mOD
	            .BlendOp		= AC_SRC_OVER_mOD
	            .BlendFlags		= False
	            .SourceConstantAlpha = 84
	            .AlphaFormat	= False
	        End With
	        'copie la structure BLENDFUNCTION dans un Long
	        RtlMoveMemory_mOD lBF_mOD, BF_mOD, 4
	        AlphaBlend_mOD alBMP.Handle, False, False, 20, 20, tmpBMP.handle, False, False, 20, 20, lBF_mOD

			TransparentBlt_mOD( DrawItem.hDC, _
								  DrawItem.left +4, DrawItem.top +2, _
								  20, 20, _
								  alBMP.Handle, _
								  False, False, _
								  20, 20, _
								  alBMP.Pixel(alBMP.Width -True, alBMP.Height -True) )
		Else
			TransparentBlt_mOD( DrawItem.hDC, _
								  DrawItem.left +4, DrawItem.top +2, _
								  20, 20, _
								  tmpBMP.Handle, _
								  False, False, _
								  20, 20, _
								  clPurple ) 'tmpBMP.Pixel(True, True) )
		End If
	End If
	mnuImgL.DrawingStyle = 2
	isCheck = False
	isRadio = False
	tmpBMP.FillRect (0, 0, tmpBMP.Width, tmpBMP.Height, &HFF00FF)
End Sub



'==============================================
' Méthode ajoute un bitmap a l'item menu 
'==============================================

Declare Function ModifyMenu_mOD Lib "user32" Alias "ModifyMenuA" ( _
		ByVal hMenu As Long, _
		ByVal nPosition As Long, _
		ByVal wFlags As Long, _
		ByVal wIDNewItem As Long, _
		ByVal lpString As String) As Long

Sub MakeODItem (ParentHnd As Long, mItem As QMenuItem, bmpIndex As Long)
	Dim retVal As Long, S As String
	S = mItem.Caption
	Dim lgRet As Long
	Dim stBuffer As String * 256
	Dim mnString As String
	Dim lpItemInfo As MENUITEMINFO_mOD
	Dim wID As Long, lpData As Long
	Dim nCaption As String

	' Cette partie est pour le menu système
	If ParentHnd = pNewSysMenu.Handle and (fhWnd_mOD <> False) Then
		Dim iSysPos As Long
		Select Case mItem.Command
			Case pSysRestore.Command:	iSysPos = False
			Case pSysMove.Command:		iSysPos = True
			Case pSysResize.Command:	iSysPos = 2
			Case pSysMinimize.Command:	iSysPos = 3
			Case pSysMaximize.Command:	iSysPos = 4
			Case pSysSeparator.Command:	iSysPos = 5
			Case pSysTerminate.Command:	iSysPos = 6
		End Select
		WiTH lpItemInfo
			.cbSize = SizeOf(lpItemInfo)
			.dwTypeData = VarPTR(stBuffer) ' & Chr$(False)
			.cch = 256
			.fMask = MIIM_ID Or MIIM_STATE Or MIIM_TYPE Or MIIM_DATA Or MIIM_SUBMENU
			.wID = iSysPos
		End WiTH
		lgRet = GetMenuItemInfo_mOD(GetSystemMenu_mOD(fhWnd_mOD, False), iSysPos, MF_BYPOSITION, lpItemInfo)
		mnString = Left$(VarPTR$(lpItemInfo.dwTypeData), lpItemInfo.cch) '-chr$(38)
		nCaption = mnString
	End If
	WiTH lpItemInfo
		.cbSize = SizeOf(lpItemInfo)
		.dwTypeData = VarPTR(stBuffer) ' & Chr$(False)
		.cch = 256
		'.fType = MFT_STRING
		'.fState = MFS_DEFAULT
		.fMask = MIIM_ID Or MIIM_STATE Or MIIM_TYPE Or MIIM_DATA Or MIIM_SUBMENU
		.wID = mItem.Command
	End WiTH
	lgRet = GetMenuItemInfo_mOD(ParentHnd, mItem.Command, MF_BYCOMMAND, lpItemInfo)
	wID = lpItemInfo.wID
	If ParentHnd = pNewSysMenu.Handle and (fhWnd_mOD <> False) Then
		' Ici on donne le vrai titre de l'item
		mnString = nCaption
	Else
		mnString = Left$(VarPTR$(lpItemInfo.dwTypeData), lpItemInfo.cch) '-chr$(38)
	End If
	'GetInfoFromMenu mnString +", " +STR$(Len(mnString))

	lpData = lpItemInfo.fType Or lpItemInfo.fState
	' On empêche d'appliquer le style ownerdraw une seconde fois
	If (lpData and MFT_OWNERDRAW) = False Then
		If mnString = "" Then
		'		lpData = lpData Or MFT_SEPARATOR
		Else
			' Permet le survole d'un item désactivé
			If (lpData and MFS_GRAYED) <> False Then _
				lpData = lpData And Not MFS_GRAYED Or MFS_DISABLED
		End If
		ModifyMenu_mOD(ParentHnd, wID, lpData Or MFT_OWNERDRAW, wID, mnString & chr$(False))
	End If

	' L'option est décoché, -2 vas résoudre le problème d'initialisation...
	If mItem.Checked = False and mItem.RadioItem <> True Then _
		mItem.Checked = -2

	If UBound(mnubitmap) < wID Then
		ReDim mnuMain (wID)		As Long
		ReDim mnubitmap(wID)	As Long
		'ReDim mnuShortCut(wID)	As String
		ReDim mnuSystem(wID)	As Long
		ReDim mnuSubMenu(wID)	As Long
	End If
	mnubitmap (wID) = bmpIndex
	'mnuShortCut (wID) = mItem.ShortCut
	If ParentHnd = pNewSysMenu.Handle Then _
		mnuSystem(wID) = True
End Sub
Sub MakeODMenuBarItem (ParentHnd As Long, mItem As QMenuItem, bmpIndex As Long)
	If UBound(mnuMain) < mItem.Command Then
		ReDim mnuMain(mItem.Command)		As Long
		ReDim mnubitmap(mItem.Command)		As Long
		'ReDim mnuShortCut(mItem.Command)	As String
		ReDim mnuSystem(mItem.Command)		As Long
		ReDim mnuSubMenu(mItem.Command)		As Long
	End If
	mnuMain (mItem.Command) = True
	MakeODItem (ParentHnd, mItem, bmpIndex)
	DrawMenuBar_mOD(ParentHnd)
	hMainMenu = ParentHnd
End Sub


Declare Function GetMenu_mOD Lib "user32.dll" Alias "GetMenu" ( _ 
		ByVal hwnd As Long) As Long
Declare Function GetSubMenu_mOD Lib "user32.dll" Alias "GetSubMenu" ( _ 
		ByVal hMenu As Long, _
		ByVal nPos As Long) As Long
Declare Function GetMenuItemCount_mOD Lib "user32" Alias "GetMenuItemCount" ( _
		ByVal hMenu As Long ) As Long


Sub MakeODMenu (hSrcMenu As Long)
	' Parcours les menus de la fenêtre donnée en paramètre et les affiche
	' dans le contrôle ListBox passé en paramètre.
	Dim hMenu As Long, lgNbMenu As Long
	Dim hSubMenu As Long, lgNbSousMenu As Long
	Dim lgRet As Long
	Dim I As Integer
	Dim stBuffer As String * 256
	Dim mnString As String
	Dim lpItemInfo As MENUITEMINFO_mOD
	Dim wID As Long, lpData As Long
	'Dim chara As String
	'Dim K As Integer

	' Récupère un pointeur vers le menu courant
	hMenu = hSrcMenu 'GetMenu_mOD(hSrcMenu)
	' Récupère le nombre d'élément de premier niveau
	lgNbMenu = GetMenuItemCount_mOD(hMenu)
	' Parcours les éléments de premier niveau
	If lgNbMenu > False Then
		For I = False To (lgNbMenu - True)
			' Mise à jour de la structure
			'stBuffer = Space$(80)
			WiTH lpItemInfo
				.cbSize = SizeOf(lpItemInfo) '44
				.dwTypeData = VarPTR(stBuffer) ' & Chr$(False)
				.cch = 256
				'.fType = MFT_STRING
				'.fState = MFS_DEFAULT
				.fMask = MIIM_ID Or MIIM_STATE Or MIIM_TYPE Or MIIM_DATA Or MIIM_SUBMENU
			End WiTH
			' Récupère le contenu du menu
			lgRet = GetMenuItemInfo_mOD(hMenu, I, MF_BYPOSITION, lpItemInfo)
			wID = lpItemInfo.wID
			If UBound(mnuMain) < wID Then
				ReDim mnuMain (wID)		As Long
				ReDim mnubitmap(wID)	As Long
				'ReDim mnuShortCut(wID)	As String
				ReDim mnuSystem(wID)	As Long
				ReDim mnuSubMenu(wID)	As Long
			End If
			If hMenu = hMainMenu Then _
				mnuMain (wID) = True
			If hMenu = pNewSysMenu.Handle Then _
				mnuSystem(wID) = True
			mnString = Left$(VarPTR$(lpItemInfo.dwTypeData), lpItemInfo.cch) '-chr$(38)
			'chara = ""
			'For K = True To Len(mnString)
			'	chara = chara +Mid$(mnString, K, True) +", " +STR$(ASC(Mid$(mnString, K, True))) +chr$(10)
			'NExt K
			'showmessage chara

			' On empêche d'appliquer le style ownerdraw une seconde fois
			lpData = lpItemInfo.fType Or lpItemInfo.fState
			'If (lpData and MFS_DISABLED) <> False Then _
			'	lpData = lpData Or MFS_GRAYED 'MFS_DISABLED
			If (lpData and MFT_OWNERDRAW) = False Then
				If mnString = "" Then
				'	lpData = lpData Or MFT_SEPARATOR
				Else
					' Permet le survole d'un item désactivé
					If (lpData and MFS_GRAYED) <> False Then _
						lpData = lpData And Not MFS_GRAYED Or MFS_DISABLED
				End If
				lgRet = ModifyMenu_mOD(hMenu, wID, lpData Or MFT_OWNERDRAW, wID, mnString & chr$(False))
				'lpItemInfo.dwTypeData = mnString & chr$(False)
				'lpItemInfo.cch = Len(mnString) +True
				'lgRet = SetMenuItemInfo_mOD(hMenu, wID, MF_BYCOMMAND, lpItemInfo)
				'GetInfoFromMenu mnString +", " +STR$(lpData) +", " + STR$(lgRet)
			End If
			' Récupère un pointeur vers le sous-menu
			hSubMenu = GetSubMenu_mOD(hMenu, I)
			' Récupère le nombre de sous-menus
			lgNbSousMenu = GetMenuItemCount_mOD(hSubMenu)
			' Parcours des éléments de second niveau
			If lgNbSousMenu > False Then
				MakeODMenu(hSubMenu)
				mnuSubMenu(wID) = True		' -1 aucun sous-menu, 0 n'a pas été vérifié
			Else
				mnuSubMenu(wID) = -True	' 1 a un sous-menu
			End If
			'ShowMessage STR$(I) +", " +VarPTR$(lpItemInfo.dwTypeData)
		Next I
	End If
End Sub

Sub CheckMenuBarForItems(frmTmp As Long)
	Dim hMenu As Long, lgNbMenu As Long

	' Récupère un pointeur vers le menu courant
	hMenu = GetMenu_mOD(frmTmp)
	' Récupère le nombre d'élément de premier niveau
	lgNbMenu = GetMenuItemCount_mOD(hMenu)
	' Parcours les éléments de premier niveau
	hMainMenu = hMenu
	If lgNbMenu > False Then _
		MakeODMenu(hMenu)
	DrawMenuBar_mOD(hMenu)
End Sub
' **************************************************************************************************

' ==================================================================================================

Sub mReplaceSysMenu '()
	mnuReplaceSysMenu = Enabled
	If Enabled = True Then
		' Doit avoir sa propre fonction owner comme MainForm
		'MakeODItem (pNewSysMenu.Handle, pSysRestore, False)
		'MakeODItem (pNewSysMenu.Handle, pSysMove, False)
		'MakeODItem (pNewSysMenu.Handle, pSysResize, False)
		'MakeODItem (pNewSysMenu.Handle, pSysMinimize, False)
		'MakeODItem (pNewSysMenu.Handle, pSysMaximize, False)
		'MakeODItem (pNewSysMenu.Handle, pSysSeparator, False)
		'MakeODItem (pNewSysMenu.Handle, pSysTerminate, False)
		MakeODMenu (pNewSysMenu.Handle)
	End If
End Sub

Sub pFixItemState ()
	If IsZoomed_mOD (mnuSysMainForm) Then
		pSysRestore.Enabled	= True
		pSysMove.Enabled	= False
		pSysResize.Enabled	= False
		pSysMaximize.Enabled = False
	Else
		pSysRestore.Enabled	= False
		pSysMove.Enabled	= True
		pSysResize.Enabled	= True
		pSysMaximize.Enabled = True
	End If
End Sub
Sub pShowSysPopup (FromIcon As Integer, X As Integer, Y As Integer)
    Dim sMenu As Long
    Dim sStyle As Long
		sStyle = TPM_RETURNCMD or TPM_RIGHTBUTTON
	' Détermine quels items sont innactifs (gris)
	pFixItemState
	' Détermine quel item est par défaut (gras)
	DefSysItem
	If FromIcon Then
		Dim mRect As RECT_mOD
		GetWindowRect_mOD (mnuSysMainForm, mRect)
		X = mRect.Left +GetSystemMetrics_mOD(7) +True
		Y = mRect.Top +GetSystemMetrics_mOD(4) +GetSystemMetrics_mOD(8)
	End If
    If isXP_mOD = False Then _
		sStyle = sStyle or TPM_RECURSE or TPM_NOANIMATION
    'GetInfoFromMenu ("DebugInfo:: " +STR$(X) +", " +STR$(Y))
	sMenu = TrackPopupMenuEx_mOD( _
				pNewSysMenu.Handle, _
				sStyle, _
				X, Y, _
				mnuSysMainForm, 0&)
End Sub
Sub pShowPopup (Popup As QPopupMenu, X As Integer, Y As Integer, hWndParent As Long)
    Dim sMenu As Long
    Dim sStyle As Long
	    sStyle = TPM_RETURNCMD
    If isXP_mOD = False Then _
		sStyle = sStyle or TPM_RIGHTBUTTON or TPM_NOANIMATION ' or TPM_RECURSE
    'GetInfoFromMenu ("DebugInfo:: " +STR$(X) +", " +STR$(Y))
	sMenu = TrackPopupMenuEx_mOD( _
				Popup.Handle, _
				sStyle, _
				X, Y, _
				IIf(hWndParent <> False, hWndParent, WindowFromPoint_mOD(X, Y)), 0&)
End Sub

Sub FindFirstMenu '(Me As QTimer)
    Dim hMenu As Long

    Me.Enabled = False
    hMenu = FindWindow_mOD("#32768", 0&)

    If hMenu <> False Then
       'Me.Enabled = False
       If hMenu <> 144 Then ' Désolé mais 144 est un menu instable
			' Force le menu à ce repeindre
			hMenuFound = hMenu
			lTimer_mOD.Enabled = False
			Dim empRect As RECT_mOD
			If GetProp_mOD (hMenu, "isPopup") = False Then
				WiTH empRect: .Left = False: .Top = False: .Right = True: .Bottom = True: End WiTH
				InvalidateRect_mOD (hMenu, empRect, 0&)
				'InvalidateRect_mOD (hMenu, ByVal False, 0&)

				hMenuCount ++
				' - Store the old windowproc... 
				SetProp_mOD (hMenu, "iShadow", hMenuCount -True)
				SetProp_mOD (hMenu, "isPopup", True)
				SetProp_mOD (hMenu, "OldWndProc", SetWindowLong_mOD(hMenu, GWL_WNDPROC_mOD, Add_MyProc))
			End If

       Else ' Arrgh! sous win9x ça peut arriver souvant, alors on utilisera un timer
			lTimer_mOD.Enabled = False
			hMenuFound = False
			hMenuCount = False
			'GetInfoFromMenu ("DebugInfo:: Cette version de menu est trop instable...", "")

       End If
    Else
		hMenuFound = False
        Me.Enabled = True
    End If
    
	If mnuSysIntercepted = True Then _
		mnuSysIntercepted = False

End Sub


Sub pDrawBorder '(hMenu As Long)
	Dim lRect As RECT_mOD
	Dim hDC As Long
	Dim lTmp As Long

	hDC = GetWindowDC_mOD (hMenu)
	GetClientRect_mOD(hMenu, lRect)
	If mnuBorders > False Then
		With lRect
			'FillRect_mOD	(hDC, lRect, GetSysColorBrush_mOD(COLOR_BTNFACE_mOD))
			SetRect_mOD(lRect, .Left, .Top, .Right +6, .Bottom +6)

			If mnuStyle = True Then
				Dim hPen As Long
				Dim hBr As Long

				' Sélectionne le nouveau pinceau dans le DC et supprime l'ancien
				hBr = SelectObject_mOD(hDC, GetStockObject_mOD(NULL_BRUSH_mOD)) 'hHBr(False))
				' Crée un nouveau crayon
				ChangePen (True, GetSysColor_mOD(16))
				' Sélectionne le nouveau crayon dans le DC et supprime l'ancien
				hPen = SelectObject_mOD(hDC, hRPen)

				Rectangle_mOD ( _
								  hDC, .left, .top, .right, .bottom )

				' Puisqu'il semblerait qu'un crayon de taille supérieure à 1 soit
				' de 3 à 10 plus lent, 1 sera sélectionné et le rectangle sera
				' resdessiné 1 fois de plus...
				' Crée un nouveau crayon
				ChangePen (True, GetSysColor_mOD(4)) '&HFFFFFF
				' Sélectionne le nouveau crayon dans le DC et supprime l'ancien
				DeleteObject_mOD SelectObject_mOD(hDC, hRPen)

				Rectangle_mOD ( _
								  hDC, .left +2, .top +2, .right -True, .bottom -True )
				'Rectangle_mOD ( _
				'				  hDC, .left +2, .top +2, .right -True, .bottom -True )

				' Restaure et supprime le crayon et le pinceau
				DeleteObject_mOD SelectObject_mOD(hDC, hPen)
				DeleteObject_mOD SelectObject_mOD(hDC, hBr)
			Else
				DrawEdge_mOD hdc, lRect, BDR_RAISEDINNER_mOD, BF_RECT_mOD 'or BF_FLAT_mOD
				SetRect_mOD(lRect, .Left +True, .Top +True, .Right -True, .Bottom -True)
				DrawEdge_mOD hdc, lRect, BDR_RAISEDINNER_mOD, BF_RECT_mOD or BF_FLAT_mOD
				SetRect_mOD(lRect, .Left +True, .Top +True, .Right -True, .Bottom -True)
				DrawEdge_mOD hdc, lRect, BDR_RAISEDINNER_mOD, BF_RECT_mOD or BF_FLAT_mOD

			End If

		End With
	End If

	If isXP_mOD < 2 or (mnuShadow = True and isXP_mOD < 2) Then _
		DrawMenuShadow(hMenu, hDC, GetProp_mOD(hMenu, "iShadow"))

	ReleaseDC_mOD(hMenu, hDC)
End Sub

' AVERTISSMENT !!!
' Il y a un erreur ici, wParam ne retourne pas correctement l'ID de l'item
' sélectionné, ce que peut causer des ennuis...
' Puisque que l'item est redessiné .wID dans MII est rempli, mais peut être 
' dangereux, puisque si l'.wID ne correspont pas, le msg n'aura aucun sens.
SUB ShowDescription (wParam As Long, lParam As Long, hWnd As Long)
	Dim a As String
	Dim TabPos As Integer
	a = LEFT$(hex$(wParam), 4)
	If lParam = False And a = "FFFF" Then	' Le système a fermé le menu
		GetInfoFromMenu(" ")  
	Else									' Recherche le titre de l'item sélectionné
		If lParam = DrawItem.hwnditem Then
			WiTH MII
        		.cbSize = SizeOf (MII)
				.fMask = MIIM_STATE Or MIIM_TYPE Or MIIM_DATA Or MIIM_ID
				GetMenuItemInfo_mOD(lParam, 0, MF_BYCOMMAND, MII)
				TabPos = InStr(VarPtr$(.dwITemData), chr$(9)) -True
				If TabPos > False Then .cch = TabPos
				GetInfoFromMenu(Left$(VarPtr$(.dwITemData), .cch))
			End WiTH
		End If
	End If
END SUB


'**********************************
'gestion evenement (messages windows) des objets crees
'**********************************
Function pSubclassWndProc_mOD '( _
'	ByVal hwnd As Long, _
'	ByVal uMsg As Long, _
'	ByVal wParam As Long, _
'	ByVal lParam As Long) As Long

	Dim lRet As Long
	Dim lTmp As Long
	Dim mnuIntercepted As Integer

	lRet = GetProp_mOD(hwnd, "OldWndProc")

    ' On doit déterminer si, c'est bien un menu où la fenêtre
	'If hMenuCount > False and pGetClassName_mOD(hwnd) = "#32768" Then
	If hMenuCount > False and GetProp_mOD(hwnd, "isPopup") = True Then

		'lRet = GetProp_mOD(hwnd, "OldWndProc")
	
		Select Case uMsg
	 
			Case WM_CREATE_mOD		   
				' - Change the window border 
				' and make it flat... 
				'lTmp = GetWindowLong_mOD(hwnd, GWL_STYLE_mOD) 
				'lTmp = lTmp And Not WS_BORDER_mOD 
			 
				'SetWindowLong_mOD hwnd, GWL_STYLE_mOD, lTmp 
			 
				'lTmp = GetWindowLong_mOD(hwnd, GWL_EXSTYLE_mOD) 
				'lTmp = lTmp And Not WS_EX_WINDOWEDGE_mOD 
				'lTmp = lTmp And Not WS_EX_DLGMODALFRAME_mOD 
			 
				'SetWindowLong_mOD hwnd, GWL_EXSTYLE_mOD, lTmp 

				'GetInfoFromMenu ("Création du menu " +STR$(hWnd))
			Case WM_DESTROY_mOD 
				If mnuIntercepted = True Then _
					mnuIntercepted = False
				'lRet = GetProp_mOD(hwnd, "OldWndProc")
				If lRet <> False and mnuAltHook = True Then
					SystemParametersInfo_mOD (&H1003, False, True, False)
					'SystemParametersInfo_mOD (&H1025, False, True, False)
					hMenuCount --
					RemoveMenuShadow (GetProp_mOD(hwnd, "iShadow"))
					RemoveProp_mOD hwnd, "iShadow"
					RemoveProp_mOD hwnd, "isPopup"
					' - UnSubclass the window... 
					RemoveProp_mOD hwnd, "OldWndProc"
					SetWindowLong_mOD (hwnd, GWL_WNDPROC_mOD, lRet)
					'GetInfoFromMenu ("Arrêt de la procédure :  " +STR$(SetWindowLong_mOD (CWP.hwnd, GWL_WNDPROC_mOD, lRet)))
				End If
				' - UnSubclass the window...
				'RemoveProp_mOD hwnd, "OldWndProc"
				'GetInfoFromMenu ("Arrêt de la procédure :  " +STR$(SetWindowLong_mOD (hwnd, GWL_WNDPROC_mOD, lRet)))

				'GetInfoFromMenu ("Destruction du menu " +STR$(hWnd))
			'Case WM_UNDOC_1EB
				'GetInfoFromMenu ("DebugInfo:: Je peins dans la fenêtre..." +STR$(WPARAM), "")
				'pDrawBorder (hWnd)
				'Result = False
			'Case WM_UNDOC_1E5 
				'pDrawBorder (hWnd)
			Case WM_PAINT_mOD
				pDrawBorder (hWnd)
			Case WM_NCPAINT_mOD
				'GetInfoFromMenu ("DebugInfo:: Je peins sur la fenêtre...", "")
				pDrawBorder (hWnd)
				'Result = False
			Case Else
				'GetInfoFromMenu (STR$(uMsg))

		End Select
	Else
		' et là c'est la fenêtre
		'PrevProc = GetProp_mOD(hwnd, "OldWndProc")
		Select Case uMsg
			Case WM_NCACTIVATE_mOD
				m_bActive = Not (wParam = False)
				DrawMenuBar_mOD(hMainMenu)
            Case WM_NCPAINT_mOD
				If GetActiveWindow_mOD = hWnd Then _
					m_bActive = -True
            Case WM_DESTROY_mOD
            	 'DeleteObject_mOD hHBr(False)
            	 'DeleteObject_mOD hHBr(True)
            	 'DeleteObject_mOD hHBr(2)
            	 'DeleteObject_mOD hHBr(3)
            	 'DeleteObject_mOD hHBr(4)
            	 'DeleteObject_mOD hHBr(5)
            	 'DeleteObject_mOD hHBr(6)
            	 'DeleteObject_mOD hHBr(7)
            	 'DeleteObject_mOD hHBr(8)
            	 'DeleteObject_mOD hHBr(9)
            	 'DeleteObject_mOD hHBr(10)
            	 'DeleteObject_mOD hHBr(11)
            	 'DeleteObject_mOD hHBr(12)
                 'DeleteObject_mOD hHBr(13)
                 DeleteObject_mOD hSRBr
                 DeleteObject_mOD hRPen
                 'If mnuAutoEndProc = True Then _
                 '   SetODMenuHookEnabled(hWnd, False)
			Case WM_MEASUREITEM_mOD
				 sStruc_mOD.Position	= False
				 '-- lParam& is a pointer to the MeasureItem structure
				 sStruc_mOD.MemCopyFrom(lParam, SizeOf(MeasureItem))
				 sStruc_mOD.Position	= False
			     '-- After we copy it we have to read the structure
				 sStruc_mOD.ReadUDT	(MeasureItem)
				 '-- There are other types, such as listboxes, etc. that we want to avoid.
				 IF MeasureItem.CtlType = ODT_MENU THEN
					Dim S As String
					S	= VarPTR$(MeasureItem.itemData) -"&"
					'Dim tabar(True) As Long, tabex As Long
					Dim iDC As Long, hFont As Long
					If S <> "-" and S <> "" Then
						iDC = GetDC_mOD (hWnd)
						hFont = SelectObject_mOD(iDC, GetStockObject_mOD(17)) 'DEFAULT_GUI_FONT

						'tabex = GetTabbedTextExtent_mOD ( _ 
						'	iDC, _ 
						'	S -&, Len(S -&), _ 
						'	False, _ 
						'	VarPtr(tabar(True)))
						GetTextExtentPoint32_mOD ( _
							iDC, _
							S +chr$(False), Len(S), _
							lpSize_mOD)
						MeasureItem.itemHeight = 20						'-- hauteur de l'item
						'MeasureItem.itemWidth = (tabex Mod &H1000)		'-- largeur de l'item
						MeasureItem.itemWidth = lpSize_mOD.cx
						SelectObject_mOD iDC, hFont
						iDC = ReleaseDC_mOD (hWnd, iDC)

						If  mnuMain(MeasureItem.ItemID) = False Then
							INC(MeasureItem.itemWidth, 33)							'-- Doit être assez grand
							If mnuSystem(MeasureItem.ItemID) = True Then _
								INC(MeasureItem.itemWidth, 40)
						Else
							If mnuBitmap(MeasureItem.ItemID) > False Then
								INC(MeasureItem.itemWidth, 17)						'-- Doit être assez grand
							'Else
							'	'INC(MeasureItem.itemWidth, 25)						'-- Doit être assez grand
							End If

						End If
					Else
						MeasureItem.itemHeight = 6
					End If

					sStruc_mOD.Position	= False
					sStruc_mOD.WriteUDT	(MeasureItem)	'-- Write structure back to memory
					sStruc_mOD.Position	= False
					'-- Copy this structure back to the original address, so changes can take effect
					sStruc_mOD.MemCopyTo	(lParam, SizeOf(MeasureItem))
				 END IF
				 sStruc_mOD.Close
			Case WM_DRAWITEM_mOD
				'GetInfoFromMenu ("DebugInfo:: " +STR$(uMsg) +", " +STR$(lParam) +", " +STR$(wParam) +", " +STR$(hWnd))

				sStruc_mOD.Position	= False
				sStruc_mOD.MemCopyFrom(lParam, SizeOf(DrawItem))
				sStruc_mOD.Position	= False
				sStruc_mOD.ReadUDT	(DrawItem)
				IF DrawItem.CtlType = ODT_MENU THEN

					SetBkMode_mOD(DrawItem.hDC, TRANSPARENT_mOD)

					' HotLight est supporté à partir de Windows 98 mais semble inactif...
					' il y sûrement une chose qui manque, peut-être reste-t-il un message
					' à envoyer au MainMenu ... ?!?
                    'GetInfoFromMenu (VarPTR$(DrawItem.itemData))
					IF ((ODS_SELECTED Or ODS_HOTLIGHT) And DrawItem.itemState) <> False And _
						VarPTR$(DrawItem.itemData) <> "-" THEN

						If (ODS_DISABLED AND DrawItem.itemState) <> False Then
							DrawMenuRectangle ( _
												DrawItem.left, DrawItem.top, _
												DrawItem.right, DrawItem.bottom, _
												mnuODCouleurs.ItemContSelInactif, mnuODCouleurs.ItemFondSelInact1, True, 8 )
							DrawMenuBitmap(True)
						Else
							DrawMenuRectangle ( _
												DrawItem.left, DrawItem.top, _
												DrawItem.right, DrawItem.bottom, _
												mnuODCouleurs.ItemContSel, mnuODCouleurs.ItemFondSel1, True, 4 )
							DrawMenuBitmap(2)
						End If

					   if (ODS_DISABLED and DrawItem.itemState) <> False then _
						  DrawMenuText (mnuODCouleurs.ItemTxtInactif, False) _
					   else _
						  DrawMenuText (mnuODCouleurs.ItemTxtSel, False)

					ELSEIF (ODS_DISABLED AND DrawItem.itemState) <> False THEN
						DrawMenuRectangle ( _
											DrawItem.left +24, DrawItem.top, _
											DrawItem.right, DrawItem.bottom, _
											mnuODCouleurs.ItemFondInact1, mnuODCouleurs.ItemFondInact1, False, 6 )
						DrawMenuRectangle ( _
											DrawItem.left, DrawItem.top, _
											DrawItem.left +24, DrawItem.bottom, _
											mnuODCouleurs.ItemFondInact2, mnuODCouleurs.ItemFondInact2, False, 7 )

						DrawMenuBitmap(True)

						DrawMenuText (mnuODCouleurs.ItemTxtInactif, False)
					ELSE
						DrawMenuRectangle ( _
											DrawItem.left +24, DrawItem.top, _
											DrawItem.right, DrawItem.bottom, _
											mnuODCouleurs.ItemFond1, mnuODCouleurs.ItemFond1, False, 2 )
						DrawMenuRectangle ( _
											DrawItem.left, DrawItem.top, _
											DrawItem.left +24, DrawItem.bottom, _
											mnuODCouleurs.ItemFond2, mnuODCouleurs.ItemFond2, False, 3 )

						DrawMenuBitmap(False)

						DrawMenuText (IIf(hMainMenu = DrawItem.hwnditem, _
											IIf(m_bActive = -True, mnuODCouleurs.MainMenuTxt, mnuODCouleurs.MainMenuTxtInactif), _
											mnuODCouleurs.ItemTxt), False)
					END IF
					' Empêche la flèche de sous-menu de se dessiner
					If mnuSubMenu(DrawItem.ItemID) = True Then
						ExcludeClipRect_mOD ( _
							DrawItem.hDC, _
							DrawItem.left, DrawItem.top, _
							DrawItem.right, DrawItem.bottom)
					ElseIf mnuSubMenu(DrawItem.ItemID) = False Then
						ExcludeClipRect_mOD ( _
							DrawItem.hDC, _
							False, False, _
							False, False)
					End If
				END IF
				'GetTextExtentPoint32_mOD ( _
				'	DrawItem.hDC, _
				'	VarPTR$(DrawItem.itemData) -&, _
				'	Len(VarPTR$(DrawItem.itemData) -&), _
				'	lpSize_mOD)
				'GetInfoFromMenu (VarPTR$(DrawItem.itemData) +", Left: " +STR$(lpSize_mOD.cx) +", Top: " +STR$(lpSize_mOD.cy) +" -> GetTextExtentPoint32_mOD")
				'Dim tabar(True) As Long
				'Dim tabex As Long
				'tabex = GetTabbedTextExtent_mOD ( _ 
				'	DrawItem.hDC, _ 
				'	VarPTR$(DrawItem.itemData) -&, _ 
				'	Len(VarPTR$(DrawItem.itemData) -&), _ 
				'	False, _ 
				'	VarPtr(tabar(True)))
				'GetInfoFromMenu (VarPTR$(DrawItem.itemData) +", Left: " +STR$((tabex Mod &H1000)) +" -> GetTabbedTextExtent_mOD")
				sStruc_mOD.Close
                'Result = True
			'Case 516', 517', 123, &H20 'WM_SETCURSOR
			'	If FindWindow_mOD("#32768", 0&) <> False Then
			'		ReleaseCapture_mOD
			'	'	EndMenu_mOD
			'		SendMessage_mOD(hWnd, WM_NCLBUTTONDOWN_mOD, (-True), 0&)
			'		'SendMessage_mOD(hWnd, WM_NCRBUTTONDOWN_mOD, HTCAPTION_mOD, lParam)
			'	End If
			'Case 517', 123, &H20 'WM_SETCURSOR
			'	GetInfoFromMenu ("DebugInfo:: " +STR$(lParam) +", " +STR$(wParam) +", " +STR$(hWnd))
			'	If FindWindow_mOD("#32768", 0&) <> False Then
			'		'ReleaseCapture_mOD
			'		'EndMenu_mOD
			'		SendMessage_mOD(hWnd, WM_NCRBUTTONDOWN_mOD, HTCAPTION_mOD, 0&)
			'	End If
            Case WM_INITMENUPOPUP_mOD			' Menu popup initialisé
                If wParam = GetSystemMenu_mOD(hWnd, False) Then
					mnuSysMainForm = hWnd
					If mnuReplaceSysMenu = True Then
                		mnuSysIntercepted = True
                		EndMenu_mOD
                	End If
                End If
				' Désactive l'animation pour corriger le problème d'actualisation du menu
				SystemParametersInfo_mOD (SPI_SETMENUANIMATION_mOD, False, False, False)
                'If hMenuFound = False Then
                    'hMenuFound = False
                    'GetInfoFromMenu ("DebugInfo:: Menu popup initialisé...", "")
                    If mnuAltHook = True Then
    	                lTimer_mOD.Interval = True
	                    lTimer_mOD.Enabled = True
                    End If
                   'FindFirstMenu (lTimer_mOD)
                'End If
            Case WM_UNINITMENUPOPUP_mOD		' Menu popup fermé
				SystemParametersInfo_mOD (SPI_SETMENUANIMATION_mOD, False, True, False)
				If mnuReplaceSysMenu = True and wParam <> GetSystemMenu_mOD(hWnd, False) Then _
					mnuSysFromIcon = False
				'GetInfoFromMenu ("DebugInfo:: Fermeture du menu popup...")
'			Case WM_MOUSEMOVE_mOD
'			Case WM_NCMOUSEMOVE_mOD
				' Ici le code va service à détecter le survole du menu pour win9x uniquement
				'GetInfoFromMenu (STR$(Screen.MouseX) +", " +STR$(Screen.MouseY) +", " +STR$(wPAram))
				'If wParam = HTMENU_mOD and hMainMenu <> False and isXP_mOD = False Then
				'	mnuPoint.X = Screen.MouseX
				'	mnuPoint.Y = Screen.MouseY
				'	ScreenToClient_mOD(hMainMenu, mnuPoint)
				'	GetInfoFromMenu (STR$(Screen.MouseX) +", " +STR$(Screen.MouseY) +", " +STR$(wParam), "")
				'	GetInfoFromMenu (STR$(MenuItemFromPoint_mOD(hWnd, hMainMenu, Point)), "")
				'End If
'			Case WM_NCHITTEST_mOD
			Case WM_MENUSELECT_mOD
				ShowDescription wParam, lParam, hWnd
			Case WM_NCLBUTTONDOWN_mOD
				mnuSysFromIcon = False
				If mnuReplaceSysMenu = True and wParam = HTSYSMENU_mOD Then
					mnuSysMainForm = hWnd
					Dim mRect As RECT_mOD
					mnuIntercepted = True
					mnuSysFromIcon = True
					GetWindowRect_mOD (hWnd, mRect)
					'pFixItemState
					pShowSysPopup ( True, False, _
									False)
					'GetInfoFromMenu ("Menu intercepté et remplacé")
'				Else
'					mnuSysFromIcon = False
				End If

'				GetInfoFromMenu ("DebugInfo:: " +STR$(lParam) +", " +STR$(wParam) +", " +STR$(hWnd))
				'wParam = 2
			Case WM_NCRBUTTONDOWN_mOD
				mnuSysFromIcon = False
				If mnuReplaceSysMenu = True and (wParam = HTCAPTION_mOD Or wParam = HTSYSMENU_mOD) Then
					mnuIntercepted = True
					mnuSysMainForm = hWnd
					'pFixItemState
					pShowSysPopup ( False, Screen.MouseX, _
									Screen.MouseY)
				End If
				'GetInfoFromMenu ("DebugInfo:: " +STR$(lParam) +", " +STR$(wParam) +", " +STR$(hWnd))
			Case &H313
				mnuSysFromIcon = False
				If mnuReplaceSysMenu = True and (wParam = HTCAPTION_mOD Or wParam = HTSYSMENU_mOD Or wParam = False) Then
					mnuSysMainForm = hWnd
					mnuIntercepted = True
					'pFixItemState
					pShowSysPopup ( False, Screen.MouseX, _
									Screen.MouseY)
				End If
				'GetInfoFromMenu ("Menu from bar:: " +STR$(lParam) +", " +STR$(wParam) +", " +STR$(hWnd))
			Case WM_COMMAND_mOD
				If mnuReplaceSysMenu = True Then
					ReleaseCapture_mOD
					Select Case wParam
						Case pSysTerminate.Command
							SendMessage_mOD(hWnd, WM_SYSCOMMAND_mOD, SC_CLOSE_mOD, False)
						Case pSysMaximize.Command
							SendMessage_mOD(hWnd, WM_SYSCOMMAND_mOD, SC_MAXIMIZE_mOD, False)
						Case pSysMinimize.Command
							SendMessage_mOD(hWnd, WM_SYSCOMMAND_mOD, SC_MINIMIZE_mOD, False)
						Case pSysResize.Command
							SendMessage_mOD(hWnd, WM_SYSCOMMAND_mOD, SC_SIZE_mOD, False)
						Case pSysMove.Command
							SendMessage_mOD(hWnd, WM_SYSCOMMAND_mOD, SC_MOVE_mOD, False)
						Case pSysRestore.Command
							SendMessage_mOD(hWnd, WM_SYSCOMMAND_mOD, SC_RESTORE_mOD, False)
						Case Else
							'ShowMessage STR$(wParam)
					End Select
				End If
            Case Else
            	'If uMsg <> 289 and uMsg <> 278 and uMsg <> 32 and uMsg <> 529 and uMsg <> 123 and _
            	'	uMsg <> 533 and uMsg <> 787 and uMsg <> 127 Then _
            	'If uMsg <> 289 and uMsg <> 132 and uMsg <> 32 Then _
				'	GetInfoFromMenu ("DebugInfo:: " +STR$(uMsg) +", " +STR$(lParam) +", " +STR$(wParam) +", " +STR$(hWnd))
        End Select
'				If uMsg = 43 Then _
'					GetInfoFromMenu ("DebugInfo:: " +STR$(uMsg) +", " +STR$(lParam) +", " +STR$(wParam) +", " +STR$(hWnd))

	End If

	If mnuIntercepted = True Then
		' - Call the next WindowProc...
		pSubclassWndProc_mOD = CallWindowProc_mOD( _ 
								lRet, _ 
								hwnd, _ 
								WM_NCLBUTTONDOWN_mOD, _ 
								(-True), _ 
								lParam)
		mnuIntercepted = False
	Else
		' - Call the next WindowProc... 
		pSubclassWndProc_mOD = CallWindowProc_mOD( _ 
								lRet, _ 
								hwnd, _ 
								uMsg, _ 
								wParam, _ 
								lParam)
	End If
End Function

Dim sStrucH_mOD As QMemoryStream

Function pHookCallWndProc_mOD '( _ 
'	ByVal ncode As Long, _ 
'	ByVal wParam As Long, _ 
'	ByVal lParam As Long) As Long 

	Dim CWP As CWPSTRUCT_mOD 
	Dim lRet As Long   
	'GetInfoFromMenu ("hooked")
	 
	If ncode = HC_ACTION_mOD Then 
		'CopyMemory CWP, ByVal lParam, Len(CWP) 
		sStrucH_mOD.Position = False
		'-- lParam& is a pointer to the TMeasureItem structure
		sStrucH_mOD.MemCopyFrom(lParam, SIZEOF(CWP))
		sStrucH_mOD.Position	= False
		'-- After we copy it we have to read the structure
		sStrucH_mOD.ReadUDT	(CWP)

		Select Case CWP.message 
			Case WM_CREATE_mOD 
				' - Make sure that the window 
				' belongs to the menu class 
				If CWP.hwnd <> 144 and pGetClassName_mOD(CWP.hwnd) = "#32768" Then 
					SystemParametersInfo_mOD (&H1003, False, False, False) ' Sans animation
					'SystemParametersInfo_mOD (&H1025, False, False, False) ' Sans ombre
					hMenuFound = CWP.hwnd
					SetProp_mOD (CWP.hwnd, "iShadow", hMenuCount)
					SetProp_mOD (CWP.hwnd, "isPopup", True)
					hMenuCount ++
				 
					' - Subclass the window... 
					lRet = SetWindowLong_mOD( _ 
							CWP.hwnd, _ 
							GWL_WNDPROC_mOD, _ 
							Add_MyProc) 
					 
					' - Store the old windowproc... 
					SetProp_mOD CWP.hwnd, "OldWndProc", lRet

					'GetInfoFromMenu ("Création d'un menu dans le hook " +STR$(CWP.hwnd))
				End If
			Case WM_DESTROY_mOD
				If CWP.hwnd <> 144 and pGetClassName_mOD(CWP.hwnd) = "#32768" Then
					lRet = GetProp_mOD(CWP.hwnd, "OldWndProc")
					If lRet <> False Then
						SystemParametersInfo_mOD (&H1003, False, True, False)
						'SystemParametersInfo_mOD (&H1025, False, True, False)
						hMenuCount --
						RemoveMenuShadow (GetProp_mOD(CWP.hwnd, "iShadow"))
						RemoveProp_mOD CWP.hwnd, "iShadow"
						RemoveProp_mOD CWP.hwnd, "isPopup"
						' - UnSubclass the window... 
						RemoveProp_mOD CWP.hwnd, "OldWndProc"
						SetWindowLong_mOD (CWP.hwnd, GWL_WNDPROC_mOD, lRet)
						'GetInfoFromMenu ("Arrêt de la procédure :  " +STR$(SetWindowLong_mOD (CWP.hwnd, GWL_WNDPROC_mOD, lRet)))
					End If

					'GetInfoFromMenu ("Destruction du menu " +STR$(CWP.hwnd))
				End If
			Case Else

		End Select 
		 
		sStrucH_mOD.Close
	End If

	' - Call the next hook... 
	pHookCallWndProc_mOD = CallNextHookEx_mOD( _ 
							WH_CALLWNDPROC_mOD, _ 
							ncode, _ 
							wParam, _ 
							lParam) 

End Function

' TEST Menu sytème
'Declare Function GetMenuItemCount_mOD Lib "user32" Alias "GetMenuItemCount" ( _
'		ByVal hMenu As Long ) As Long


'Function GetMenuName(hMenu As Long, ID As Long) As String
'	Dim Buffer As String, retval As Long, MenuStr As String
'	WiTH MII
'		.cbSize = SizeOf (MII)
'		.fMask = MIIM_STATE Or MIIM_TYPE Or MIIM_SUBMENU Or MIIM_ID
'		' Make room in the string buffer.
'		Buffer = Space$(256)
'		.dwTypeData = VarPTR(Buffer)
'		.cch = 256
'		retval = GetMenuItemInfo_mOD(hMenu, ID, MF_BYCOMMAND, MII)
'		MenuStr = Left$(VarPTR$(.dwTypeData), .cch)
'	End WiTH
'	result = MenuStr
'End Function
'Function GetMenuNameByPos(hMenu As Long, ID As Long) As String
'	Dim Buffer As String, retval As Long, MenuStr As String
'	MenuStr = Space$(64)
'	WiTH MII
'		.cbSize = SizeOf (MII)
'		.fMask = MIIM_STATE Or MIIM_TYPE Or MIIM_DATA Or MIIM_ID
'		' Make room in the string buffer.
'		Buffer = Space$(256)
'		.dwTypeData = VarPTR(Buffer)
'		.cch = 256
'		retval = GetMenuItemInfo_mOD(hMenu, ID, MF_BYPOSITION, MII)
'		MenuStr = Left$(VarPTR$(.dwTypeData), .cch)
'	End WiTH
'	result = MenuStr
'End Function
Function GetMenuCheckState '(hMenu As Long, ID As Long) As Long
    WiTH MII
        .cbSize = SizeOf (MII)
        .fMask = MIIM_STATE Or MIIM_TYPE Or MIIM_DATA Or MIIM_ID
	    GetMenuItemInfo_mOD(hMenu, ID, MF_BYCOMMAND, MII)
    	result = IIf((MFT_RADIOCHECK And .fType) <> False , True, False)
    End WiTH
End Function
'Function GetMenuCheckBMPHandle '(hMenu As Long, ID As Long) As Long
'	WiTH MII
'		.cbSize = SizeOf (MII)
'		.fMask = MIIM_STATE Or MIIM_TYPE Or MIIM_DATA Or MIIM_ID Or MIIM_CHECKMARKS
'		GetMenuItemInfo_mOD(hMenu, ID, MF_BYCOMMAND, MII)
'		result = .hbmpChecked 'IIf(.hbmpChecked <> False , True, False)
'	End WiTH
'End Function
'Function GetMenuShortByPos(hMenu As Long, ID As Long) As String
'End Function


Function pGetClassName_mOD '(ByVal hwnd As Long) As String 
	Dim sClass As String 
	Dim nLen As Long
	 
	sClass = Space$(128) 'String$(128, Chr$(False)) 
	nLen = GetClassName_mOD(hwnd, @sClass, 128) 
	 
	If nLen = False Then 
		sClass = "" 
	Else 
		sClass = Left$(sClass, nLen) 
	End If 
	 
	pGetClassName_mOD = sClass
End Function
