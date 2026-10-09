' Crйй par D-йvolution / Created by D-evolution -=@=- 2003 - 2005

' [Franзais]
' Dans la sйrie des objets persos, voici QCoolBarXPv1 -- Immitation d'une Barre d'outil

' CoolBarXPv1 est une toute nouvelle version, complиtement revue de ma CoolBar, version 
' optimisйe afin de rйduire le scintillement lors du redimensionnement de la barre 
' d'outil...
' Tout зa est possible via une modification de l'Add-On fournis avec QTButton
' Voyez-les posibilitйs !!! 
' Il ne reste plus qu'a gйrer l'effet Survole, placer une image de fond et on obtient 
' une Barre d'outil casi identique а celles de WinXP (sous XP)

' Pour plus de dйtail sur l'utilisation de ce composant reportez vous а la documentation 
' fournise... (QCoolBarXP.html)

' Si la doc n'est pas disponible actuellement elle le sera sous peu...

' [English]
' In the serie of custum objects here's QCoolBarXPv1 -- ToolBar look with XP support

' CoolBarXPv1 is a completly new version, this version is optimized to reduce flickering 
' while resizing the toolbar...
' All that is possible via some modification of the Add-On that came with QTButton

' For more details on using this component please refer to the doc
' (QCoolBarXP.html)

' *You're free to fix my bad spelling ;)
$Option Explicit

Dim custBG		As QBitmap
Dim custGrip	As QBitmap

' ===
' Extrait de QTButton

$IFNDEF __RQINC' ==(corrigй! doh!)
$IFNDEF __RQINCTMP
$DEFINE __RQINCTMP
	CONST False = 0
	CONST True	= 1

	CONST clBtnFace = -2147483633
	CONST clHilight	= -2147483635
	CONST clGrayText = -2147483631
	CONST clBtnText	= -2147483630
	CONST clPurple	= &HFF00FF

	CONST pf15bit	= 4
$ENDIF ' __RQINCTMP
$ENDIF ' __RQINC

Const rqNullChr_CBar = CHR$(0)
'Const rqSL		= CHR$(10)

Const DefPixelFormat_CBar = 4

'Dim QCBarBMP As QBitmap
'	QCBarBMP.BMPHandle = btn_BMP' REsource bitmap

$IFNDEF __QTBTNSHARED95
$DEFINE __QTBTNSHARED95
'
Declare Function GetDC_QTBtn Lib "user32" _
		Alias "GetDC" _
		(ByVal hwnd As Long) As Long
Declare Function ReleaseDC_QTBtn Lib "user32" _
		Alias "ReleaseDC" ( _
		ByVal hwnd As Long, _
		ByVal hdc As Long) As Long

CONST SrcCopy_QTBtn = &HCC0020	' Celui dans RapidQ.INC n'est pas correct

Declare Function BitBlt_QTBtn Lib "gdi32" _
		Alias "BitBlt" ( _
		hDC As Integer, _
		nXDest As Integer, nYDest As Integer, _
		nWidth As Integer, nHeight As Integer, _
		hdcSrc As Integer, _
		nXSrc As Integer, nYSrc As Integer, _
		dwRop As Integer) As Integer

' Pour Win98 et supйrieur
Declare Function TransparentBlt_QTBtn Lib "msimg32" _
		Alias "TransparentBlt" ( _
		ByVal hdcDest As Long, _
		ByVal nXOriginDest As Long, ByVal nYOriginDest As Long, _
		ByVal nWidthDest As Long, ByVal nHeightDest As Long, _
		ByVal hdcSrc As Long, _
		ByVal nXOriginSrc As Long, ByVal nYOriginSrc As Long, _
		ByVal nWidthSrc As Long, ByVal nHeightSrc As Long, _
		ByVal crTransparent As Long) As Long
$ENDIF ' __QTBTNSHARED

$IFNDEF __RQOBJDRAWING
$DEFINE __RQOBJDRAWING
Declare Function SetCapture_QTBtn Lib "user32" Alias "SetCapture" _
		(ByVal hwnd As Long) As Long
Declare Function ReleaseCapture_QTBtn Lib "user32" Alias "ReleaseCapture" () As Long
Declare Function GetCapture_QTBtn Lib "user32" Alias "GetCapture" () As Long

Type RECT_QTBtn
	Left	As Long
	Top		As Long
	Right	As Long
	Bottom	As Long
End Type

Const DT_SINGLELINE_QTBtn As Long = &H20
Const DT_CENTER_QTBtn = &H1
Const DT_VCENTER_QTBtn As Long = &H4

Declare Function DrawText_QTBtn Lib "user32" Alias "DrawTextA" ( _
		ByVal hdc As Long, _
		ByVal lpStr As String, _
		ByVal nCount As Long, _
		lpRect As RECT_QTBtn, _
		ByVal wFormat As Long) As Long

' Ajoutй 6fйv
'Declare Function GetDC_QTBtn Lib "user32" _
'		Alias "GetDC" _
'		(ByVal hwnd As Long) As Long
'Declare Function DeleteDC_QTBtn Lib "gdi32" _
'		Alias "DeleteDC" (ByVal hdc As Long) As Long
'Declare Function ReleaseDC_QTBtn Lib "user32" _
'		Alias "ReleaseDC" ( _
'		ByVal hwnd As Long, _
'		ByVal hdc As Long) As Long
Declare Function SetBkMode_QTBtn Lib "gdi32" _
		Alias "SetBkMode" ( _
		ByVal hdc As Long, _
		ByVal nBkMode As Long) As Long
'Declare Function SetBkColor_QTBtn Lib "gdi32.dll" Alias "SetBkColor" _
'		(ByVal hdc As Long, ByVal crColor As Long) As Long
'Declare Function SetTextColor_QTBtn Lib "gdi32" Alias "SetTextColor" _
'		(ByVal hdc As Long, ByVal crColor As Long) As Long

' -- (Ajoutй 11janv) Les Nouveaux API pour le suport des Thиmes de Bureau XP
Declare Function OpenThemeData_QTBtn Lib "uxtheme.dll" Alias "OpenThemeData" ( _
		ByVal hwnd As Long, _
		ByVal pszClassList As Long) As Long

Declare Function CloseThemeData_QTBtn Lib "uxtheme.dll" Alias "CloseThemeData" ( _
		ByVal hTheme As Long) As Long

Declare Function DrawThemeBackground_QTBtn Lib "uxtheme.dll" Alias "DrawThemeBackground" ( _
		ByVal hTheme As Long, _
		ByVal hdc As Long, _
		ByVal iPartID As Long, _
		ByVal iStateID As Long, _
		pRect As RECT_QTBtn, _
		pClipRect As RECT_QTBtn) As Long
'Declare Function DrawThemeText_QTBtn Lib "uxtheme.dll" Alias "DrawThemeText" ( _
'		ByVal hTheme As Long, _
'		ByVal hdc As Long, _
'		ByVal iPartID As Long, _
'		ByVal iStateID As Long, _
'		ByVal pszText As Long, _
'		ByVal iCharCount As Long, _
'		ByVal dwTextFlags As Long, _
'		ByVal dwTextFlags2 As Long, _
'		pRect As RECT_QTBtn) As Long

Const xpt_PushBtn		= "Button"
Const xpt_ToolBarBtn	= "Toolbar"
Const xpt_TabBtn		= "Tab"
' //--
$ENDIF ' __RQOBJDRAWING

Const xpt_ReBar		= "ReBar" ' Seulement pour coolbarxp


$IFNDEF __RQGETVERSION
$DEFINE __RQGETVERSION
Dim isXP_QTBtn As Integer
	isXP_QTBtn = False

TYPE OSVERSIONINFO_QTBtn
	dwOSVersionInfoSize As Long
	dwMajorVersion As Long
	dwMinorVersion As Long
	dwBuildNumber As Long
	dwPlatformId As Long
	szCSDVersion As String *128
END TYPE
'Const PLATFORM_WIN32_WINDOWS = 1
'Const PLATFORM_WIN32_NT = 2
Declare Function GetVersionEx_QTBtn Lib "kernel32.dll" Alias "GetVersionExA" _
	(ByVal lpVersionInformation As LONG) As Long

DIM rtn_QTBtn AS LONG
DIM OSV_QTBtn AS OSVERSIONINFO_QTBtn, Mem_QTBtn AS QMEMORYSTREAM

DIM PixelFormatFix_QTBtn As Integer
	PixelFormatFix_QTBtn = pf15bit

SUB GetVersion_QTBtn
	OSV_QTBtn.dwOSVersionInfoSize = sizeof(OSV_QTBtn)
	Mem_QTBtn.WriteUDT(OSV_QTBtn)
	rtn_QTBtn = GetVersionEx_QTBtn(Mem_QTBtn.Pointer)
	IF rtn_QTBtn <> False THEN
		Mem_QTBtn.Position = False
		Mem_QTBtn.ReadUDT(OSV_QTBtn)
		IF OSV_QTBtn.dwPlatformId = True THEN
			isXP_QTBtn = False
		ELSEIF OSV_QTBtn.dwPlatformId = 2 THEN
			IF OSV_QTBtn.dwMajorVersion = 5 THEN _
				IF OSV_QTBtn.dwMinorVersion = True THEN _
					isXP_QTBtn = True
		END IF
	END IF
	Mem_QTBtn.Close
END SUB
Call GetVersion_QTBtn
$ENDIF ' __RQGETVERSION

Dim maxNumBMPs_CBar As Integer
	maxNumBMPs_CBar = 5

' //--

'Extrait de QTButton_AddOns

'DrawEdge Constants
'Const BDR_RAISEDOUTER_CBar	= &H1
Const BDR_SUNKENOUTER_CBar	= &H2
Const BDR_RAISEDINNER_CBar	= &H4
'Const BDR_SUNKENINNER_CBar	= &H8

'Const BDR_OUTER		= &H3
'Const BDR_INNER		= &HC
'Const BDR_RAISED		= &H5
'Const BDR_SUNKEN		= &HA

Const BF_LEFT_CBar		= &H1
Const BF_TOP_CBar		= &H2
Const BF_RIGHT_CBar		= &H4
Const BF_BOTTOM_CBar	= &H8

Const BF_RECT_CBar = (BF_LEFT_CBar Or BF_TOP_CBar Or BF_RIGHT_CBar Or BF_BOTTOM_CBar)

'Const BF_MIDDLE	= &H800		' Fill in the middle.
'Const BF_SOFT		= &H1000	' Use for softer buttons.
'Const BF_ADJUST	= &H2000	' Calculate the space left over.
Const BF_FLAT_CBar	= &H4000	' For flat rather than 3-D borders.
'Const BF_MONO		= &H8000	' For monochrome borders.

'Const DC_ACTIVE	= &H1
'Const DC_NOTACTIVE	= &H2
'Const DC_ICON		= &H4
'Const DC_TEXT		= &H8
'Const DFC_BUTTON	= 4
'Const DFC_POPUPMENU = 5			'Only Win98/2000 !!
'Const DFCS_BUTTON3STATE = &H10
'Const DT_CENTER	= &H1
'Const DC_GRADIENT	= &H20			'Only Win98/2000 !!
Declare Function DrawEdge_CBar Lib "user32" Alias "DrawEdge" ( _
		ByVal hdc As Long, _
		qrc As RECT_QTBtn, _
		ByVal edge As Long, _
		ByVal grfFlags As Long) _
		As Long
Declare Function SetRect_CBar Lib "user32" Alias "SetRect" ( _
		lpRect As RECT_QTBtn, _
		ByVal X1 As Long, ByVal Y1 As Long, _
		ByVal X2 As Long, ByVal Y2 As Long) _
		As Long

Sub Fast_CBar( _
			   BtnType As String, _
			   PartID As Integer, _
			   StateID As Integer, _
			   Me As QBitmap, _
			   Caption As String, _
			   IcoWidth As Integer, _
			   FontName As String, _
			   wMenu As Integer, _
			   Grouped As Integer, _
			   Style As Integer, _
			   DisableXPTheme As Integer, _
			   Hwnd As Long) ' inc2026: FontName As String вместо As Integer (строка 278): параметр сравнивается с "", меняется SWAP с Me.Font.Name, вызовы передают строку (.Font.Name или ""); в QCoolBarXP90.inc - nFontName As String
	Dim Dest As QRect, Source As QRect
	Dim tR As RECT_QTBtn

	Dim fixTab As Integer
		fixTab = False

	If isXP_QTBtn and DisableXPTheme = False Then
		if BtnType = xpt_TabBtn Then _
			fixTab = True
		if BtnType = xpt_pushbtn or BtnType = xpt_toolbarbtn or BtnType = xpt_TabBtn Then _
			PartID = True
	End If

	Me.FillRect(False, False, Me.Width, Me.Height, clBtnFace)'==(mod) (13janv remplacй clPurple par clBtnFace)

	If FontName <> "" Then _
		SWAP Me.Font.Name, FontName' == (add) | inc2026: SWAP без скобок, как в документации (SWAP variable1, variable2)

	If isXP_QTBtn = False or DisableXPTheme = True Then
		' Temporairement indisponible

		'
		If StateID > False Then
			If Style Then
				' Bon c'est pour la survole
				Me.Rectangle( True, _
					True, _
					Me.Width, _
					Me.Height, _
					-2147483632) 'clBtnShadow
				Me.FillRect( 2, _
					2, _
					Me.Width -True, _
					Me.Height -True, _
					-2147483638) 'clActiveBorder
			Else
				SetRect_CBar ( tR, _
					True, _
					True, _
					Me.Width, _
					Me.Height)
				If StateID = True Then
					DrawEdge_CBar (Me.Handle, tR, BDR_RAISEDINNER_CBar, BF_RECT_CBar)
				Else
					DrawEdge_CBar (Me.Handle, tR, BDR_SUNKENOUTER_CBar, BF_RECT_CBar)
				End If
			End If
			If StateID = 2 or StateID = 4 Then
				Me.FillRect( 2, _
					2, _
					Me.Width -True, _
					Me.Height -True, _
					-2147483628)
				Me.Pixel(3, 3) = Me.Pixel(3, 3) -RGB(8, 11, 28)
				Me.FillRect( 2, _
					2, _
					Me.Width -True, _
					Me.Height -True, _
					Me.Pixel(3, 3)) 'clActiveBorder
			End If
		End If
		If wMenu > False Then
			Dim bFont As String
				bFont	= "Marlett"

			If Style Then
				Me.FillRect(Me.Width -11, _
					2, _
					Me.Width -True, _
					Me.Height -True, _
					IIf(StateID = False, clBtnFace, &HFFFFFF))
			Else
				If StateID +True >= 3 and wMenu < 2 Then
					SetRect_CBar ( tR, _
						Me.Width -11, 2, _
						Me.Width -11, Me.Height)
				Else
					SetRect_CBar ( tR, _
						Me.Width -12, True, _
						Me.Width -12, Me.Height)
				End If
				DrawEdge_CBar (Me.Handle, tR, BDR_RAISEDINNER_CBar, BF_RECT_CBar)
			End If

			SWAP Me.Font.Name, bFont ' inc2026: SWAP без скобок, как в документации (SWAP variable1, variable2)

			tR.Left		= Me.Width -11 +iif(StateID +True >= 3 and wMenu < 2, True, False)
			tR.Top		= False +iif(StateID +True >= 3 and wMenu < 2, True, False)
			tR.Right	= Me.Width +iif(StateID +True >= 3 and wMenu < 2, True, False)
			tR.Bottom	= Me.Height

			SetBkMode_QTBtn Me.Handle, True
			If StateID = 3 Then
				Me.Font.Color	= -2147483628 '-2147483626
				tR.Left			= tR.Left +True
				tR.Top			= tR.Top +True
				DrawText_QTBtn (Me.Handle, "6", True, _
					tR, DT_CENTER_QTBtn OR DT_SINGLELINE_QTBtn OR DT_VCENTER_QTBtn)
				tR.Left			= tR.Left -True
				tR.Top			= tR.Top -True
				Me.Font.Color	= clGrayText
			End If

			DrawText_QTBtn (Me.Handle, "6", True, _
				tR, DT_CENTER_QTBtn OR DT_SINGLELINE_QTBtn OR DT_VCENTER_QTBtn)
			SWAP Me.Font.Name, bFont ' inc2026: SWAP без скобок, как в документации (SWAP variable1, variable2)
		End If
	Else
		' Thиme activй (Windows XP)
		' --
		Dim hTheme As Long

		' Ouverture du thиme
		Dim rtButton As String ', _
			rtButton = ""

		Dim lR As Long
		Dim m_hDC As Long
		Dim m_lPartId As Long, m_lStateId As Long
		'Dim tR As RECT_QTBtn

		' Format unicode ?!?
		Dim I As Integer
		For I = True To Len(BtnType)
			rtButton = rtButton +Mid$(BtnType, I, True) +rqNullChr_CBar
		Next I
		rtButton = rtButton +rqNullChr_CBar ' Un dernier pour la route

		hTheme = OpenThemeData_QTBtn(Hwnd, VarPtr(rtButton))
		If hTheme <> False Then
			' Styles XP disponible

			' m_hDC est le DC pour dessiner
			' m_lPartId et m_lStateId sont la class + l'йtat а dessiner
			' tR est un RECT spйcifiant la zone dans laquelle dessiner
			m_hDC = Me.Handle
			Dim mLeft As Integer
				mLeft = False
			If wMenu > False Then
				m_lPartId = 3
				mLeft = 11
			ElseIf PartID > True Then
				m_lPartId = PartID
			Else
				m_lPartId = True 'BP_PUSHBUTTON
			End If

			m_lStateId	= StateID +True	'PBS_NORMAL
			If wMenu = 2 Then _
				m_lStateId --
			tR.Left		= False '+iif(StateID <> 2, True, False)
			tR.Top		= True 'True -iif(StateID <> 2, False, True) +fixTab
			tR.Right	= Me.Width -mLeft
			tR.Bottom	= Me.Height

			lR = DrawThemeBackground_QTBtn(hTheme, _
					 m_hDC, _
					 m_lPartId, _
					 m_lStateId, _
					 tR, tR)

			If wMenu > False Then
				m_lPartId	= 4
				If wMenu = 2 Then _
					m_lStateId ++

				tR.Left		= Me.Width -11
				tR.Top		= True
				tR.Right	= Me.Width
				tR.Bottom	= Me.Height

				lR = DrawThemeBackground_QTBtn(hTheme, _
						 m_hDC, _
						 m_lPartId, _
						 m_lStateId, _
						 tR, tR)
			End If
		End If

		' Session de dessin terminйe
		CloseThemeData_QTBtn hTheme
		CloseThemeData_QTBtn hTheme
		'//--
	End If

	If Caption <> "" Then
		If IcoWidth > False Then IcoWidth = IcoWidth +4
		SetBkMode_QTBtn Me.Handle, True
		tR.Left		= False +iif(StateID +True >= 3 and wMenu < 2, True, False) +IcoWidth
		tR.Top		= False +iif(StateID +True >= 3 and wMenu < 2, 2, False) +fixTab
		'tR.Top		= tR.Top +iif(StateID +True = 3, 4, False)
		tR.Right	= Me.Width +tR.Left -IcoWidth
		tR.Bottom	= Me.Height

		If StateID = 3 Then
			Me.Font.Color = -2147483628 '-2147483626
			tR.Left	= tR.Left +True
			tR.Top	= tR.Top +True
			DrawText_QTBtn (Me.Handle, Caption, Len(Caption), _
				tR, IIf(IcoWidth > False, False, DT_CENTER_QTBtn) OR DT_SINGLELINE_QTBtn OR DT_VCENTER_QTBtn)
			tR.Left	= tR.Left -True
			tR.Top	= tR.Top -True
			Me.Font.Color = clGrayText
		End If

		DrawText_QTBtn (Me.Handle, Caption, Len(Caption), _
			tR, IIf(IcoWidth > False, False, DT_CENTER_QTBtn) OR DT_SINGLELINE_QTBtn OR DT_VCENTER_QTBtn)
	End If
	'Me.PixelFormat = DefPixelFormat_CBar

	If FontName <> "" Then _
		SWAP Me.Font.Name, FontName' == (add) | inc2026: SWAP без скобок, как в документации (SWAP variable1, variable2)

	If PartID <> True Then _
		PartID = True
End Sub


Sub XPPart ( _
			 BtnType As String, _
			 PartID As Integer, _
			 Orientation As Integer, _
			 DisableXPThemeBG As Integer, _
			 Color, _
			 Me As QBitmap, _
			 hWnd As Long)
	If isXP_QTBtn Then
		' Thиme activй (Windows XP)
		' --
		If DisableXPThemeBG or PartID <> 6 Then _
			Me.FillRect(False, False, Me.Width, Me.Height, Color)

		Dim hTheme As Long

		' Ouverture du thиme
		Dim rtButton As String
			rtButton = ""
		' Format unicode ?!?
		Dim I As Integer
		For I = True To Len(BtnType)
			rtButton = rtButton +Mid$(BtnType, I, True) +rqNullChr_CBar
		Next I
		rtButton = rtButton +rqNullChr_CBar ' Et un dernier pour la route

		hTheme = OpenThemeData_QTBtn(hWnd, VarPtr(rtButton))
		If hTheme <> False Then
			' Styles XP disponible

			Dim lR As Long
			Dim m_hDC As Long
			Dim m_lPartId As Long, m_lStateId As Long
			Dim tR As RECT_QTBtn

			' m_hDC est le DC pour dessiner
			' m_lPartId et m_lStateId sont la classe + l'йtat а dessiner
			' tR est une structure RECT spйcifiant la zone dans laquelle dessiner
			m_hDC = Me.Handle
			If PartID > True Then _
				m_lPartId = PartID _
			Else _
				m_lPartId = True 'BP_PUSHBUTTON

			m_lStateId = True 'PBS_NORMAL
			If PartID <= 2 Then ' inc2026: <= вместо =< (в документации только <=)
				If Orientation Then _
					SetRect_CBar (tR, True, False, Me.Width -True, 8) _
				Else _
					SetRect_CBar (tR, False, True, 5, Me.Height -True)
			Else
				SetRect_CBar (tR, False, False, Me.Width, Me.Height)
			End If

			lR = DrawThemeBackground_QTBtn(hTheme, _
					m_hDC, _
					m_lPartId, _
					m_lStateId, _
					tR, tR)

		End If

		' Session de dessin terminйe
		CloseThemeData_QTBtn hTheme
		CloseThemeData_QTBtn hTheme
		'//--
	End If
End Sub
' //==


Const AC_SRC_OVER_CBar = &H00

Type BLENDFUNCTION_CBar
	BlendOp		As Byte
	BlendFlags	As Byte
	SourceConstantAlpha As Byte
	AlphaFormat	As Byte
End Type

Declare Function AlphaBlend_CBar Lib "msimg32" Alias "AlphaBlend" ( _
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
		ByRef Blendfunc As BLENDFUNCTION_CBar) As Long
		
Declare Sub RtlMoveMemory_CBar Lib "kernel32.dll" Alias "RtlMoveMemory" ( _
		byref Destination As long, _
		byref Source As BLENDFUNCTION_CBar, _
		Length As Long)

Dim BF_CBar	As BLENDFUNCTION_CBar, _
	lBF_CBar	As Long


Declare Function GetWindowRect_CBar Lib "user32" Alias "GetWindowRect" ( _ 
        ByVal hwnd As Long, _ 
        ByRef lpRect As RECT_QTBtn ) As Long 

Declare Function PtInRect_CBar Lib "user32" Alias "PtInRect" ( _ 
        ByRef lpRect As RECT_QTBtn, _ 
        ByVal x As Long, ByVal y As Long ) As Long 


' Gиre les menus popup
'Const TPM_HORIZONTAL		As Long = &H0&
'Const TPM_LEFTALIGN			As Long = &H0&
Const TPM_LEFTBUTTON_CBar			= &H0				'&H0&
'Const TPM_TOPALIGN			As Long = &H0&
'Const TPM_RECURSE					= &H1				'&H1&
Const TPM_RIGHTBUTTON_CBar			= &H2				'&H2&
'Const TPM_CENTERALIGN		As Long = &H4&
'Const TPM_RIGHTALIGN		As Long = &H8&
'Const TPM_VCENTERALIGN		As Long = &H10&
'Const TPM_BOTTOMALIGN		As Long = &H20&
'Const TPM_VERTICAL			As Long = &H40&
'Const TPM_NONOTIFY			As Long = &H80&
Const TPM_RETURNCMD_CBar	As Long = &H100&
'Const TPM_HORPOSANIMATION	As Long = &H400&
'Const TPM_HORNEGANIMATION	As Long = &H800&
'Const TPM_VERPOSANIMATION	As Long = &H1000&
'Const TPM_VERNEGANIMATION	As Long = &H2000&
Const TPM_NOANIMATION_CBar	As Long = &H4000&

Declare Function TrackPopupMenuEx_CBar Lib "user32" Alias "TrackPopupMenuEx" ( _
		ByVal hMenu As Long, _
		ByVal wFlags As Long, _
		ByVal x As Long, ByVal y As Long, _
		ByVal hWnd As Long, _
		ByVal lptpm As Long) As Long
' // Fin - Gиre les menus popup

' Gиre les boоtes de texte et les comboboxes
'Const HWND_TOPMOST			= -1
'Const HWND_NOTOPMOST		= -2
Const SWP_NOSIZE_CBar		= &H1
'Const SWP_NOMOVE			= &H2
Const SWP_NOACTIVATE_CBar	= &H10
'Const SWP_SHOWWINDOW		= &H40
Const SWP_NOZORDER_CBar		= &H4

Declare Sub SetWindowPos_CBar Lib "user32" Alias "SetWindowPos" ( _
		ByVal hWnd As Long, _
		ByVal hWndInsertAfter As Long, _
		ByVal X As Long, ByVal Y As Long, _
		ByVal cx As Long, ByVal cy As Long, _
		ByVal wFlags As Long)
' // Fin - Gиre les boоtes de texte et les comboboxes

' Mйthode pour ajouter une icфne а l'item d'un menu
' //Fin


'Const HTCLIENT_CBar		= 1
Const HTCAPTION_CBar		= 2
Const WM_NCLBUTTONDOWN_CBar = &HA1
'Const WM_NCLBUTTONUP_CBar	= &HA2
'Const WM_LBUTTONDOWN_CBar	= &H201
'Const WM_LBUTTONUP_CBar	= &H202
Declare Function SendMessage_CBar Lib "user32" Alias "SendMessageA" ( _
		ByVal hwnd As Long, _
		ByVal wMsg As Long, _
		ByVal wParam As Long, _
		lParam As long) As Long

Const VK_LBUTTON_CBar As Long = &H1
'Const VK_RBUTTON_CBar As Long = &H2

Declare Function GetAsyncKeyState_CBar Lib "user32" _
		Alias "GetAsyncKeyState" ( _
		ByVal vKey As Long) _
		As Integer

Dim BMPCache	As QBitmap
'	BMPCache.BMPHandle = BG_BMP

Dim mnuItemExceed(False)	As QMenuItem

Dim CB_ItemCount As Integer
	CB_ItemCount = False

Sub RedimCBItems
	' Redimensionne les objets
	' cette mйthode devrait permettre de rйduire les reources utilisйes
	' par la barre d'outil et augmenter le nombre de btns possibles...
	ReDim mnuItemExceed(CB_ItemCount)		As QMenuItem
End Sub

'Declare Sub GetInfo (iIndex As String) 'Integer)

' Event Template pour les nouveaux йvйnements MouseLeave et MouseEnter
DECLARE SUB CBarOnMouseEnter_EventTemplate (X As Integer, Y As Integer, Shift As Integer, ItemIndex As Integer, Me As QPanel)
DECLARE SUB CBarOnMouseLeave_EventTemplate (X As Integer, Y As Integer, Shift As Integer, Me As QPanel)
DECLARE SUB CBarOnChange_EventTemplate (ItemIndex As Integer, Me As QPanel)


Type QCoolBarXP Extends QPanel
   PUBLIC:
	ItemCount			As Integer		' Nombre d'item
	ItemsWidth			As Integer
	'ItemsHeight		As Integer
	Item(29)			As String		' Titre de chaque item
	'CustBG			As QBitmap			' Image de fond
	'CustGrip		As QBitmap			' Image de la "Grippe"
	'CustSkin		As QBitmap			' Image de l'enjolivure

	imgLA			AS QImageList		' ImgLst des btns Actifs
	'imgLD			AS QImageList		' ImgLst des btns Inactifs
	'imgLS			AS QImageList		' ImgLst des btns Sйlectionnйs
	'imgLH			AS QImageList		' ImgLst des btns Survollйs
	'CollectionBMP	AS QBitmap			' Une collection d'image de tous les btns

   PRIVATE:
	DragTimer			As QTimer
	FreePanelL			As QPanel		' Paneau sur lequel repose l'image de la barre d'outil
	FreePanelM			As QPanel		' ...
	FreePanelR			As QPanel		' Paneau sur lequel repose l'image du menu lorsque la taille est rйduite
	BtnCache			As QBitmap		' Garde en mйmoire l'image de la barre pour un affichage plus rapide
	CanvasL				As QCanvas		' Gestion de de l'йvйnement OnPaint
	CanvasR				As QCanvas		' Gestion de de l'йvйnement OnPaint
	CanvasLMsg			As Integer
	ImageL				As QImage		' Image sur laquelle est dessinй la barre d'outil
	ImageR				As QImage		' Image sur laquelle est dessinй le menu lorsque la taille est rйduite
	ImageLH				As QImage		' Image affichйe lorsqu'un item est survolй ou sйlectionnй
	ImageRH				As QImage		' Image affichйe lorsque le menu est survolй ou sйlectionnй
	'Fond				As QImage
	CoolBtnBMP			As QBitmap
	CoolBtnBMPE			As QBitmap
	ItemLeft(6)			As Integer
	ItemWidth(6)		As Integer
	ShowBtnCapt(6)		As Integer
	ShowBtnCaptAll		As Integer
	LastItemLeft		As Integer
	LastItemTop			As Integer
	ItemGroup(6)		As Integer
	GroupAllowAllUp(6)	As Integer		' Ici ce n'est pas l'item, mais l'index du group qui est passй comme argument
	ItemEnabled(6)		As Integer
	ItemDown(6)			As Integer
	wasHideGrip			As Integer		' Je crois que c'est complиtement obselиt maintenant
	wasHideCaption		As Integer		' Je crois que c'est complиtement obselиt maintenant
	GripWidth			As Integer		' Largeur de la "Grippe"
	GripHeight			As Integer		' Hauteur de la "Grippe"
	CaptionWidth		As Integer		' Largeur du titre de la barre
	CaptionHeight		As Integer		' Hauteur du titre de la barre (En rйalitй il sagit de la position suppйrieur)
	isExceedWidth		As Integer
	isExceedHeight		As Integer
	isPaintReady		As Integer
	ForceRePaint		As Integer
	ForceEvalPos		As Integer
	BMPCache2			As QBitmap
	ItemPopupHnd(6)		AS Long
	mnuExceed			As QPopupMenu	' ...
	mnuItemExceedIndex(6) As Integer
	mnuItemCount		As Integer		' ...
	ED_Count			As Integer		' Nombre de contrфle Edit
	ED_Ctrl(6)			As Long
	ED_AfterIndex(6)	As Integer
	ED_Left(6)			As Integer
	ED_Width(6)			As Integer
	ED_Height(6)		As Integer
	'ED_BG(6)			As QImage
	CB_Count			As Integer		' Nombre de contrфle ComboBox
	CB_Ctrl(6)			As Long
	CB_AfterIndex(6)	As Integer
	CB_Left(6)			As Integer
	CB_Width(6)			As Integer
	CB_Height(6)		As Integer
	'CB_BG(6)			As QImage

   PUBLIC:
	'Height				As Integer	PROPERTY SET SetHeight
	'Width				As Integer	PROPERTY SET SetWidth
	DisableXPTheme		As Integer	' Propriйtй					' Dйsactive le Thиme XP
	DisableXPThemeBG	As Integer	' Propriйtй					' Dйsactive le fond XP
	DisableBG			As Integer	' Propriйtй					' Dйsactive le fond si custBG.Empty = False
	Style				As Integer	' Propriйtй
	'BtnsSpacing		As Integer								' Espace entre les items
	HideGrip			As Integer	PROPERTY SET SetHideGrip	' Affiche/Masque la "Grippe"
	HideCaption			As Integer	PROPERTY SET SetHideCaption	' Affiche/Masque le titre de la barre
	Caption				As String	PROPERTY SET SetCaption
	'ItemsWidth			As Integer	PROPERTY SET SetItemsWidth	' Dimension des items de la barre
	Orientation			As Integer	PROPERTY SET SetOrientation	' Orientation de la barre (False. Horz, True. Vert)

	'BevelWidth			As Integer PROPERTY SET SetBevelWidth	' ...
	BorderStyle			As Integer PROPERTY SET SetBorderStyle	' ...

	'OnMouseLeave	AS EVENT(CBarOnMouseLeave_EventTemplate)	' La souris quitte la barre
	'OnMouseEnter	AS EVENT(CBarOnMouseEnter_EventTemplate)	' La souris entre et se dйplace sur la barre
	OnChange		AS EVENT(CBarOnChange_EventTemplate)		' Un btn est cliquй
	'Nouvelles propriйtйs
	'qqchose as qqchose Property Set SetQqChose
	
	With This
   PRIVATE:
	Function TextWidth(text as string) As Integer:	Result = .BtnCache.TextWidth(text)
	End Function
	Function TextHeight(text as string) As Integer:	Result = .BtnCache.TextHeight(text)
	End Function

	Sub pShowPopup (iPopup As Long, X As Integer, Y As Integer)
		Dim sMenu As Long
		Dim sStyle As Long
		sStyle = TPM_RETURNCMD_CBar
		' Si ODMenuXP est dйtectй
		$IFNDEF __RQGETVERSION2
			'If isXP_QTBtn = False Then _
				sStyle = sStyle or TPM_LEFTBUTTON_CBar or TPM_RIGHTBUTTON_CBar
		$ELSE
			'If isXP_QTBtn = False Then _
				sStyle = sStyle or TPM_LEFTBUTTON_CBar or TPM_RIGHTBUTTON_CBar or TPM_NOANIMATION_CBar
		$ENDIF
		sMenu = TrackPopupMenuEx_CBar( _
					.ItemPopupHnd(iPopup), _
					sStyle, _
					X, Y, _
					This.Handle, 0&)
	End Sub
	SUB EvalBtnPos
		If ((.wasHideGrip <> .HideGrip) or (.wasHideCaption <> .HideCaption) or .ForceEvalPos) and _
			.ItemCount > False Then
			
			.ItemLeft(False) = False
			.ItemWidth(False) = False

			Dim I As Integer
			Dim SepBefore As Integer
			FOR I = False TO .ItemCount -True
				If .Item(I) = "-" Then
					.ItemWidth(I) = 5
					SepBefore ++
				Else
					.ItemWidth(I) = .ItemsWidth
					If .imgLA.Count > False and (I -SepBefore < .imgLA.Count) Then
						.ItemWidth(I) = .imgLA.Width +8 +_
							IIf(.Orientation = False and (.ShowBtnCapt(I) = True or .ShowBtnCaptAll = True), _
								 .TextWidth(.Item(I)) +4, _
								 False) +_
							IIf(.ItemPopupHnd(I), 12, False)
					End If
				End If
			NEXT I
			SepBefore = False
			If .HideGrip = False  Then _
				.ItemLeft(False) = .ItemLeft(False) +8
			If .HideCaption = False and .Caption <> "" Then _
				.ItemLeft(False) = .ItemLeft(False) +.CaptionWidth +4

			.wasHideGrip = .HideGrip
			.wasHideCaption = .HideCaption

			Dim J As Integer
			If .ED_Count > False Then
				FOR J = False TO .ED_Count -True
					If .ED_AfterIndex(J) = -True Then
						.ED_Left(J) = .ItemLeft(False)
						.ItemLeft(False) = .ItemLeft(False) +.ED_Width(J) +6
						Exit For
					End If
				NEXT J
			End If
			If .CB_Count > False Then
				FOR J = False TO .CB_Count -True
					If .CB_AfterIndex(J) = -True Then
						.CB_Left(J) = .ItemLeft(False)
						.ItemLeft(False) = .ItemLeft(False) +.CB_Width(J) +6
						Exit For
					End If
				NEXT J
			End If

			FOR I = False TO .ItemCount -True
				.ItemLeft(I +True) = .ItemLeft(I) +.ItemWidth(I)
				If .ED_Count > False Then
					FOR J = False TO .ED_Count -True
						If .ED_AfterIndex(J) = I Then
							.ED_Left(J) = .ItemLeft(I +True)
							.ItemLeft(I +True) = .ItemLeft(I +True) +.ED_Width(J) +6
							SetWindowPos_CBar (.ED_Ctrl(J), False, _
								.ED_Left(J), (.FreePanelL.Height -.ED_Height(J)) \2, _
								False, False, _
								SWP_NOACTIVATE_CBar Or SWP_NOSIZE_CBar Or SWP_NOZORDER_CBar)
							Exit For
						End If
					NEXT J
				End If
				If .CB_Count > False Then
					FOR J = False TO .CB_Count -True
						If .CB_AfterIndex(J) = I Then
							.CB_Left(J) = .ItemLeft(I +True)
							.ItemLeft(I +True) = .ItemLeft(I +True) +.CB_Width(J) +6
							SetWindowPos_CBar (.CB_Ctrl(J), False, _
								.CB_Left(J), (.FreePanelL.Height -.CB_Height(J)) \2, _
								False, False, _
								SWP_NOACTIVATE_CBar Or SWP_NOSIZE_CBar Or SWP_NOZORDER_CBar)
							Exit For
						End If
					NEXT J
				End If
			NEXT I
		End If
		If .Orientation Then
			.LastItemLeft	= False
			.LastItemTop	= .ItemLeft(.ItemCount -True) +(.ItemWidth(.ItemCount -True) \.66)
		Else
			.LastItemLeft	= .ItemLeft(.ItemCount -True) +(.ItemWidth(.ItemCount -True) \.66)
			.LastItemTop	= False
		End If
	END SUB
   PUBLIC:

	SUB RePaint
		DIM I AS INTEGER, J AS INTEGER
		DIM R AS RECT_QTBtn

		If .isPaintReady = True or .ForceRePaint = True Then
			.isPaintReady = 2
			If .Orientation Then
				.LastItemLeft	= False
				.LastItemTop	= .ItemLeft(.ItemCount -True) +(.ItemWidth(.ItemCount -True) \.66)
			Else
				.LastItemLeft	= .ItemLeft(.ItemCount -True) +(.ItemWidth(.ItemCount -True) \.66)
				.LastItemTop	= False
			End If


			If .Orientation Then
				.BMPCache2.Width	= .FreePanelL.Width
				.BMPCache2.Height	= .ItemLeft(.ItemCount -True) +.ItemWidth(.ItemCount -True)
			Else
				.BMPCache2.Width	= .ItemLeft(.ItemCount -True) +.ItemWidth(.ItemCount -True)
				.BMPCache2.Height	= .FreePanelL.Height
			End If
			'GetInfo (.Caption +"::Paint  " +STR$(.BMPCache2.Width) +", " +STR$(.BMPCache2.Height))
			'.BMPCache2.FillRect (False, False, .BMPCache2.Width, .BMPCache2.Height, This.Color)
			'.BMPCache2.Transparent = True
			'.BMPCache2.TransparentColor = This.Color
			Dim sepBefore As Integer
				sepBefore = False

			If isXP_QTBtn = False or .DisableXPTheme = True Then _
				 .BMPCache2.FillRect (False, False, .BMPCache2.Width, .BMPCache2.Height, This.Color)


			If .HideGrip = False Then

				If isXP_QTBtn and .DisableXPTheme = False Then
					XPPart ( xpt_ReBar, True, _
						This.Orientation, _
						True, _
						This.Color, _
						This.BMPCache2, This.Handle)
				ElseIf .DisableBG = False and custGrip.Empty = False Then
					Dim oldGripH As Integer
					If isXP_QTBtn = False Then _
						custGrip.PixelFormat = 4
					custGrip.TransparentColor	= custGrip.Pixel(False, False)
					custGrip.Transparent		= True
					'custGrip.Height = 5
					.BMPCache2.Draw(False, 4, _
						custGrip.BMP)
					oldGripH		= custGrip.Height
					'For I = False To (.BMPCache2.Height -custGrip.Height) \custGrip.Height
						'custGrip.Height = .BMPCache2.Height -custGrip.Height -10
						.BMPCache2.Draw(False, oldGripH +4, _
							custGrip.BMP)
					'	custGrip.Height	= oldGripH
					'Next I
				Else
					If .Orientation Then
						If .Style = False Then
							SetRect_CBar ( R, _
								2, _
								2, _
								.BMPCache2.Width -3, _
								5)
							DrawEdge_CBar (.BMPCache2.Handle, R, BDR_RAISEDINNER_CBar, BF_RECT_CBar)
						Else
							FOR I = 3 TO (.ClientWidth -5) STEP 3
								.BMPCache2.Line	 ( I, 2, I, 4, -2147483632 ) 'clBtnShadow
							NEXT I
						End If
					Else
						If .Style = False Then
							SetRect_CBar ( R, _
								2, _
								2, _
								5, _
								.BMPCache2.Height -3)
							DrawEdge_CBar (.BMPCache2.Handle, R, BDR_RAISEDINNER_CBar, BF_RECT_CBar)
						Else
							FOR I = 3 TO (.ClientHeight -5) STEP 3
								.BMPCache2.Line	 ( 2, I, 4, I, -2147483632 ) 'clBtnShadow
							NEXT I
						End If
					End If
				End If
			End If
			If .HideCaption = False and .Caption <> "" Then
				If .Orientation Then
					.CaptionHeight = (.ClientWidth -.TextHeight(.Caption)) \2
					'.CaptionWidth = .TextWidth(.Caption) +4

					Dim RotCapCache As QBitmap
					RotCapCache.Height		= .TextWidth(.Caption) +4 '.TextHeight(.Caption) +4
					RotCapCache.Width		= .TextWidth(.Caption) +4
					RotCapCache.FillRect	(False, False, RotCapCache.Height, RotCapCache.Width, This.Color)
					RotCapCache.TextOut		(False, False, .Caption, .Font.Color, -True)
					RotCapCache.Rotate		(25, 25, 90)
					RotCapCache.Width		= .TextHeight(.Caption) +4
					RotCapCache.TransparentColor = RotCapCache.Pixel(False, False)
					RotCapCache.Transparent	= True
					This.BMPCache2.Draw		((.ClientWidth -RotCapCache.Width) \2, 4, RotCapCache.BMP)
				Else
					.CaptionHeight		= (.ClientHeight -.TextHeight(.Caption)) \2
					'.CaptionWidth		= .TextWidth(.Caption) +4
					' Il y a un bug avec win9x oщ le texte du titre est invisible... ???
					If isXP_QTBtn Then
						.BMPCache2.TextOut	(.GripWidth +2, .CaptionHeight, .Caption, .Font.Color, -True)
					Else
						.BMPCache2.TextOut	(.GripWidth +2, .CaptionHeight, .Caption, False, -True)
					End If
				End If
			End If

			If .ItemCount > False Then
				Dim imgLBK As QBitmap
				For I = False To .ItemCount -True

					If .Item(I) <> "-" Then
						'If .Orientation Then
						'Else
						'End If
						.CoolBtnBMP.Width = .ItemWidth(I)
						.CoolBtnBMP.Height = .ItemsWidth

						'CoolBtnI
						If .imgLA.Count > False and (I -SepBefore) < .imgLA.Count Then _
							imgLBK.BMP	= .imgLA.GetBMP(I -sepBefore)

						.CoolBtnBMP.Font.Color = IIf (.ItemEnabled(I), This.Font.Color, clGrayText)

						Fast_CBar( xpt_ToolBarBtn, _
							True, _
							IIf(.ItemDown(I), 4, IIf(.ItemEnabled(I), False, 3)), _
							This.CoolBtnBMP, _
							IIf(.Orientation = False and (.ShowBtnCapt(I) = True or .ShowBtnCaptAll = True), _
								.Item(I), ""), _
							IIf(.imgLA.Count > False and (I -SepBefore) < .imgLA.Count, imgLBK.Width +2, False), _
							This.CoolBtnBMP.Font.Name, _
							IIf(.ItemPopupHnd(I), True, False), _
							False, _
							.Style, _
							.DisableXPTheme, _
							This.Handle)

						If .imgLA.Count > False and (I -sepBefore) < .imgLA.Count Then
							Dim decal As Integer
								decal = IIf(.ItemDown(I), True, False)

							imgLBK.BMP				= .imgLA.GetBMP(I -sepBefore)
							imgLBK.TransparentColor	= imgLBK.Pixel(False, False) 'clWhite
							If imgLBK.TransparentColor <> clPurple Then _
								imgLBK.TransparentColor	= imgLBK.Pixel(imgLBK.Width -True, False) 'clWhite
							imgLBK.Transparent		= True
							
							If .ItemEnabled(I) = False Then 'and (.imgLD.Count = False or (I +True > .imgLD.Count)) Then
								Dim alBMP As QBitmap
								alBMP.Width		= imgLBK.Width
								alBMP.Height	= imgLBK.Width
								alBMP.FillRect	(False, False, imgLBK.Width, imgLBK.Height, This.Color)

								BF_CBar.BlendOp				= AC_SRC_OVER_CBar
								BF_CBar.BlendFlags			= False
								BF_CBar.SourceConstantAlpha	= 84
								BF_CBar.AlphaFormat			= False

								' Copie la structure BLENDFUNCTION dans un Long
								RtlMoveMemory_CBar lBF_CBar, BF_CBar, 4
								AlphaBlend_CBar (alBMP.Handle, _
									False, False, _
									imgLBK.Width, imgLBK.Height, _
									imgLBK.handle, _
									False, False, _
									imgLBK.Width, imgLBK.Height, _
									lBF_CBar)
								imgLBK.BMP				= alBMP.BMP
								imgLBK.TransparentColor	= imgLBK.Pixel(False, False) 'clWhite
								'If imgLBK.TransparentColor <> clPurple Then _
								'	imgLBK.TransparentColor	= imgLBK.Pixel(imgLBK.Width -True, False) 'clWhite
								imgLBK.Transparent		= True
							End If

							If (.Orientation = False and (.ShowBtnCapt(I) = True or .ShowBtnCaptAll = True)) or _
								.ItemPopupHnd(I) Then
								.CoolBtnBMP.Draw ( 4 +decal, _
									((This.CoolBtnBMP.Height -imgLBK.Height) \2) +decal, _
									imgLBK.BMP)
							Else
								.CoolBtnBMP.Draw ( ((This.CoolBtnBMP.Width -imgLBK.Width) \2) +decal, _
									((This.CoolBtnBMP.Height -imgLBK.Height) \2) +decal, _
									imgLBK.BMP)
							End If
						End If

						.BMPCache2.Draw (IIf(.Orientation, False, .ItemLeft(I)), _
							IIf(.Orientation, .ItemLeft(I), False), _
							.CoolBtnBMP.BMP)

					Else
						If .Orientation Then
							SetRect_CBar ( R, _
								False +IIf(.BevelWidth = False, 2, False), _
								.ItemLeft(I) +True, _
								This.FreePanelL.Width -3, _
								.ItemLeft(I) +IIf(.Style < 2 or isXP_QTBtn = False, 3, 2))
						Else
							SetRect_CBar ( R, _
								.ItemLeft(I) +True, _
								2, _
								.ItemLeft(I) +IIf(.Style < 2 or isXP_QTBtn = False, 3, 2), _
								This.FreePanelL.Height -3)
						End If
						DrawEdge_CBar (.BMPCache2.Handle, R, BDR_SUNKENOUTER_CBar, BF_RECT_CBar)
						sepBefore ++

					End If
				Next I
			End If
		End If
	END SUB
   PRIVATE:
	SUB CanvasPaint (Me As QCanvas)
		Static fixHotUp As Integer
		' Corrige l'optimisation d'oh! 
		' et voilа aucun scintillement et le redimensionnment est constant
		If .isPaintReady = False Then _
			.isPaintReady = True
		If .CanvasL.Width = 2 Then
			fixHotUp = True
		ElseIf fixHotUp = True Then
			fixHotUp = False
		Else
			.ImageLH.Visible = False
			fixHotUp = False
		End If
		'wasBtn = -True ' devra кtre une propriйtй de la barre pour rйsoudre le problиme d'apparission
						' lorsque la fenкtre a perdue le focus et que l'ont tente de sйlectionner le mкme
						' item
		' Dessine le fond de la barre
		'BMPCache.Transparent = False
		BMPCache.Width	= This.ClientWidth	'This.Width
		BMPCache.Height	= This.ClientHeight	'This.Height
		If isXP_QTBtn and .DisableXPThemeBG = False Then
			XPPart (xpt_ReBar, 6, _
				False, _
				True, _
				This.Color, _
				BMPCache, This.Handle)
		ElseIf custBG.Empty or .DisableBG = True Then
			BMPCache.FillRect ( _
				False, False, _
				BMPCache.Width, BMPCache.Height, _
				This.Color)
		Else
			Dim sR As QRect
			sR.Left		= False
			sR.Top		= False
			sR.Right	= BMPCache.Width
			sR.Bottom	= BMPCache.Height
			BMPCache.StretchDraw ( _
				sR, _
				custBG.BMP)
		End If

		If .BorderStyle Then
			Dim R As RECT_QTBtn
			SetRect_CBar ( R, _
				False, _
				False, _
				BMPCache.Width, _
				BMPCache.Height)
			DrawEdge_CBar (BMPCache.Handle, R, BDR_RAISEDINNER_CBar, BF_RECT_CBar)
		End If

		If .Orientation = False Then
			If .FreePanelR.Visible = False and .Width < .LastItemLeft Then
				.FreePanelR.Height	= .FreePanelL.Height
				.FreePanelR.Visible	= True
				.isExceedWidth		= 12
			ElseIf .FreePanelR.Visible = True and .Width > .LastItemLeft Then
				.FreePanelR.Visible	= False
				.isExceedWidth		= False
				.isExceedHeight		= False
			End If
		ElseIf .Orientation Then
			If .FreePanelR.Visible = False and .Height < .LastItemTop Then
				.FreePanelR.Width	= .FreePanelL.Width
				.FreePanelR.Visible	= True
				.isExceedHeight		= 12
			ElseIf .FreePanelR.Visible = True and .Height > .LastItemTop Then
				.FreePanelR.Visible	= False
				.isExceedWidth		= False
				.isExceedHeight		= False
			End If
		End If
		If .FreePanelR.Visible Then
			If .Orientation Then
				If .ClientHeight > 12 Then _
					.FreePanelR.Top = .ClientHeight -12
			Else
				If .ClientWidth > 12 Then _
					.FreePanelR.Left = .ClientWidth -12
			End If
		End If
		If .Orientation Then
			.FreePanelL.Width = .ClientWidth -.isExceedWidth
			'.FreePanelL.Height = .ClientHeight -.isExceedHeight -2
		Else
			.FreePanelL.Width = .ClientWidth -.isExceedWidth -2
			'.FreePanelL.Height = .ClientHeight -.isExceedHeight
		End If
		.FreePanelL.Height = .ClientHeight -.isExceedHeight
		If .FreePanelL.Width <> False and .FreePanelL.Height <> False Then
			.BtnCache.Width		= This.FreePanelL.Width
			.BtnCache.Height	= This.FreePanelL.Height
			.ImageL.BMP			= This.BtnCache.BMP
			' // Dessine le fond de la barre
			BitBlt_QTBtn ( Me.Handle, _ 
				False, False, _ 
				Me.Width, Me.Height, _
				BMPCache.Handle, _ 
				False, False, _ 
				SrcCopy_QTBtn)
			If .Orientation Then
				BitBlt_QTBtn ( This.ImageL.Handle, _ 
					False, False, _ 
					This.ImageL.Width, This.ImageL.Height, _
					BMPCache.Handle, _ 
					False, True, _ 
					SrcCopy_QTBtn)
			Else
				BitBlt_QTBtn ( This.ImageL.Handle, _ 
					False, False, _ 
					This.ImageL.Width, This.ImageL.Height, _
					BMPCache.Handle, _ 
					True, False, _ 
					SrcCopy_QTBtn)
			End If
			' // Dessine les boutons sur le fond de la barre
			If .isPaintReady < 2 Then _
				Call This.RePaint
			If .isPaintReady = 2 Then
				If (isXP_QTBtn and .DisableXPThemeBG = False) or _
					(custBG.Empty = False and .DisableBG = False) Then
					TransparentBlt_QTBtn ( .ImageL.Handle, _
						False, False, _ 
						.BMPCache2.Width, .BMPCache2.Height, _
						.BMPCache2.Handle, _ 
						False, False, _ 
						.BMPCache2.Width, .BMPCache2.Height, _
						.BMPCache2.Pixel(False, False))
				Else
					BitBlt_QTBtn ( .ImageL.Handle, _
						False, False, _ 
						.BMPCache2.Width, .BMPCache2.Height, _
						.BMPCache2.Handle, _ 
						False, False, _ 
						SrcCopy_QTBtn)
				End If
			End If
			'GetInfo (.Caption +"::Paint  " +STR$(.isPaintReady) +", " +STR$(.ForceRePaint))
			.BtnCache.BMP = 0&
		End If
		If .FreePanelR.Visible Then
			.CoolBtnBMPE.Width	= This.FreePanelR.Width
			.CoolBtnBMPE.Height	= This.FreePanelR.Height

			' Exceed Btn
			Fast_CBar( xpt_ToolBarBtn, _
				IIf(.Orientation, 5, 4), _
				False, _
				This.CoolBtnBMPE, _
				"", _
				False, _
				"", _
				False, _
				False, _
				.Style, _
				.DisableXPTheme, _
				This.Handle)
			.CoolBtnBMPE.TextOut(((12 -.CoolBtnBMPE.TextWidth("»")) \2) +True, _
				-6, _
				"»", _
				.Font.Color, _
				-True)

			If .Orientation Then
				BitBlt_QTBtn ( This.ImageR.Handle, _ 
					False, False, _ 
					This.FreePanelR.Width, This.FreePanelR.Height, _
					BMPCache.Handle, _ 
					False, This.FreePanelR.Top, _ 
					SrcCopy_QTBtn)
			Else
				BitBlt_QTBtn ( This.ImageR.Handle, _ 
					False, False, _ 
					This.FreePanelR.Width, This.FreePanelR.Height, _
					BMPCache.Handle, _ 
					This.FreePanelR.Left, False, _ 
					SrcCopy_QTBtn)
			End If
			' //
			TransparentBlt_QTBtn ( .ImageR.Handle, _
				False, False, _ 
				.ImageR.Width, .ImageR.Height, _
				.CoolBtnBMPE.Handle, _ 
				False, False, _ 
				.CoolBtnBMPE.Width, .CoolBtnBMPE.Height, _
				.CoolBtnBMPE.Pixel(False, False))
		End If
		If .BorderStyle Then
			'Dim R As RECT_QTBtn
			If .Orientation Then
				SetRect_CBar ( R, _
					False, _
					-True, _
					.Width, _
					.Height)
			Else
				SetRect_CBar ( R, _
					-True, _
					False, _
					.Width, _
					.ImageL.Height)
			End If
			DrawEdge_CBar (.ImageL.Handle, R, BDR_RAISEDINNER_CBar, BF_RECT_CBar)
		End If
		.BtnCache.Width		= True
		.BtnCache.Height	= True
		'BMPCache.BMP		= "" '0&
	END SUB

	SUB mnuItem_Click(Me As QMenuItem)
		If Me.Caption <> "-" Then
			If .ItemGroup(Me.Tag) <> False Then
				.ItemDown(Me.Tag) = IIf(.ItemDown(Me.Tag), False, True)
				.isPaintReady = False
				This.CanvasPaint (This.CanvasL)
			End If
			CALLFUNC(This.OnChange, Me.Tag, This)
		End If
	END SUB

   PUBLIC:
	' == Ajout d'items а la barre ==
	SUBI AddItems (...)
		If ParamStrCount > False Then
			DIM I AS INTEGER
			.ItemCount = .ItemCount +ParamStrCount	' Devrait кtre .ItemCount +ParamStrCount
			If .ItemsWidth = False Then
				If .Orientation Then
					  .ItemsWidth = .FreePanelL.Width -2
				Else: .ItemsWidth = .FreePanelL.Height -2
				End If
			End If

			ReDim .ItemLeft(.ItemCount -True)			As Integer
			ReDim .ItemWidth(.ItemCount -True)			As Integer
			'ReDim .Item(.ItemCount -True)				As String	' Plantage du compilateur
			ReDim .ShowBtnCapt(.ItemCount -True)		As Integer
			ReDim .ItemGroup(.ItemCount -True)			As Integer
			ReDim .ItemEnabled(.ItemCount -True)		As Integer
			ReDim .ItemDown(.ItemCount -True)			As Integer
			ReDim .ItemPopupHnd(.ItemCount -True)		As Long
			ReDim .mnuItemExceedIndex(.ItemCount -True)	As Integer

			.ItemLeft(False)	= False	' Devrait кtre .ItemLeft(.ItemCount -ParamStrCount)
			.ItemWidth(False)	= False	' Devrait кtre .ItemWidth(.ItemCount -ParamStrCount)
			FOR I = True TO ParamStrCount
				.mnuItemExceedIndex(I -True)		= CB_ItemCount
				mnuItemExceed(CB_ItemCount).Caption	= IIf(ParamStr$(I) = "", "...", ParamStr$(I))
				mnuItemExceed(CB_ItemCount).Tag		= I -True
				mnuItemExceed(CB_ItemCount).OnClick = This.mnuItem_Click
				.mnuExceed.AddItems (mnuItemExceed(CB_ItemCount))
				' Corrige les valeurs incorrrects
				.Item(I -True)			= ParamStr$(I)
				.ItemGroup(I -True)		= False
				.ItemEnabled(I -True)	= True
				.ItemDown(I -True)		= False
				.ItemPopupHnd(I -True)	= False
				.ShowBtnCapt(I -True)	= IIf(.ShowBtnCaptAll, True, False)
				If ParamStr$(I) = "-" Then
					.ItemWidth(I -True) = 5
				Else
					.ItemWidth(I -True) = .ItemsWidth +_
						IIf(.Orientation = False and .ShowBtnCapt(I -True), _
						.TextWidth(ParamStr$(I)) +3, _
						False)
					'CoolBtnI
				End If
				CB_ItemCount ++
				Call RedimCBItems
			NEXT I
			If .HideGrip = False Then _
				.ItemLeft(False) = .ItemLeft(False) +8
			If .HideCaption = False and .Caption <> "" Then _
				.ItemLeft(False) = .ItemLeft(False) +.CaptionWidth '+4
			I = False
			FOR I = False TO .ItemCount -True
				.ItemLeft(I +True) = .ItemLeft(I) +.ItemWidth(I)
			NEXT I
			If .isPaintReady = 2 Then _
				Call This.RePaint
			'.isPaintReady = False
		End If
	END SUBI
	'SUBI DelItems (...)
	'END SUBI
	SUB AsignPopupToItem (Me As QPopupMenu, iIndex As Integer)
		If .ItemCount = False Then _
			Exit Sub
		If .Item(iIndex) <> "-" Then
			.ItemPopupHnd(iIndex) = Me.Handle
		Else
			ShowMessage "Avertissement: vous tentez d'asigner un menu popup " +CHR$(10) +_
						"               а un item..."
		End If
		.ForceEvalPos = True
		Call This.EvalBtnPos
		.ForceEvalPos = False
		If .isPaintReady = 2 Then
			.ForceRePaint = True
			Call This.RePaint
			.ForceRePaint = False
		End If
	END SUB

	Sub InsertED_Ctrl (iAfter As Integer, Me As QEdit)

		If .Orientation = True Then
			ShowMessage "Orientation = True n'est pas supportй !"
			Exit Sub
		End If
			
		ReDim .ED_Ctrl(.ED_Count)		As Long
		ReDim .ED_AfterIndex(.ED_Count)	As Integer
		ReDim .ED_Left(.ED_Count)		As Integer
		ReDim .ED_Width(.ED_Count)		As Integer
		ReDim .ED_Height(.ED_Count)		As Integer

		.ED_Count ++

		Me.Visible						= False
		Me.Parent						= This.FreePanelL
		.ED_Ctrl(.ED_Count -True)		= Me.Handle
		.ED_Width(.ED_Count -True)		= Me.Width
		.ED_Height(.ED_Count -True)		= Me.Height
		.ED_AfterIndex(.ED_Count -True)	= iAfter
		' Appelle EvalPos
		.ForceEvalPos = True
		Call This.EvalBtnPos
		.ForceEvalPos = False
		If iAfter = -True or (iAfter > -True and iAfter < (.ItemCount -True)) Then
			Me.Left	= .ED_Left(.ED_Count -True)
		Else
			Me.Left	= .ItemLeft(.ItemCount -True) +6
		End If
		Me.Top		= (This.FreePanelL.Height -Me.Height) \2 '-True
		'.ED_Ctrl(.ED_Count -True) = Me.Handle
		'.ED_Left(.ED_Count -True) = Me.Left
		Me.Parent	= This.FreePanelL
		Me.Visible	= True

		If .isPaintReady = 2 Then _
			Call This.RePaint
	End Sub
	Sub InsertCB_Ctrl (iAfter As Integer, Me As QComboBox)

		If .Orientation = True Then
			ShowMessage "Orientation = True n'est pas supportй !"
			Exit Sub
		End If
		ReDim .CB_Ctrl(.CB_Count)		As Long
		ReDim .CB_AfterIndex(.CB_Count)	As Integer ' inc2026: CB_Count вместо ED_Count: остальные массивы CB_ здесь по .CB_Count (копия из InsertED_Ctrl)
		ReDim .CB_Left(.CB_Count)		As Integer
		ReDim .CB_Width(.CB_Count)		As Integer
		ReDim .CB_Height(.CB_Count)		As Integer

		.CB_Count ++

		.CB_Ctrl(.CB_Count -True) = Me.Handle
		.CB_Width(.CB_Count -True) = Me.Width
		.CB_Height(.CB_Count -True) = Me.Height
		.CB_AfterIndex(.CB_Count -True) = iAfter
		' Appelle EvalPos
		Call This.EvalBtnPos
		If iAfter = -True or (iAfter > -True and iAfter < (.ItemCount -True)) Then
			Me.Left		= .CB_Left(.CB_Count -True) ' inc2026: CB_Count вместо ED_Count: позиция только что добавленного списка (копия из InsertED_Ctrl)
		Else
			Me.Left		= .ItemLeft(.ItemCount -True) +6
		End If
		Me.Top		= (This.FreePanelL.Height -Me.Height) \2 '-True
		Me.Parent	= This.FreePanelL
		'.CB_Ctrl(.CB_Count -True) = Me.Handle
		'.CB_Left(.CB_Count -True) = Me.Left

		If .isPaintReady = 2 Then _
			Call This.RePaint
	End Sub

	SUBI ItemsGroup (...)
		'... = ParamValCount
		Dim I As Integer
		Dim modSepState As Integer
			modSepState = False
		Dim Index As Integer
			Index = IIf(ParamVal(True) <= False, False, ParamVal(True))

		If ParamValCount = True Then
			For I = False To .ItemCount -True
				If .Item(I) <> "-" Then
					.ItemGroup(I) = Index
					.GroupAllowAllUp(Index) = True
				End If
			Next I
		ElseIf ParamValCount > True Then
			For I = 2 To ParamValCount
				If .Item(ParamVal(I)) <> "-" Then
					.ItemGroup(ParamVal(I)) = Index
					.GroupAllowAllUp(Index) = True 'False
				Else
					modSepState ++
				End If
			Next I
		Else
			ShowMessage "Erreur: paramиtre(s) manquant(s) ou incorrect(s)"
		End If
		If modSepState Then _
			ShowMessage "Avertissement: vous tentez de redйfinir le " +CHR$(10) +_
						"               groupe d'un sйparateur..."
		If .isPaintReady = 2 Then _
			Call This.RePaint
	END SUBI
	SUBI DefineGroupAllowAllUp (...)
		If .isPaintReady = 2 Then _
			Call This.RePaint
	END SUBI
	SUBI ItemsDown (...)
		'... = ParamValCount
		Dim I As Integer
		Dim modSepState As Integer
			modSepState = False
		Dim Index As Integer
			Index = IIf(ParamVal(True) <> False, True, False)

		If ParamValCount = True Then
			For I = False To .ItemCount -True
				If .Item(I) <> "-" and .ItemGroup(I) > False Then _
					.ItemDown(I) = Index
			Next I
		ElseIf ParamValCount > True Then
			For I = 2 To ParamValCount
				If .Item(ParamVal(I)) <> "-" Then
					If .ItemGroup(ParamVal(I)) > False Then _
						.ItemDown(ParamVal(I)) = Index
				Else
					modSepState ++
				End If
			Next I
		Else
			ShowMessage "Erreur: paramиtre(s) manquant(s) ou incorrect(s)"
		End If
		If modSepState Then _
			ShowMessage "Avertissement: vous tentez de modifier l'йtat " +CHR$(10) +_
						"               enfoncй d'un sйparateur..."
		If .isPaintReady = 2 Then _
			Call This.RePaint
	END SUBI
	SUBI ItemsEnabled (...)
		'... = ParamValCount
		Dim I As Integer
		Dim modSepState As Integer
			modSepState = False

		If ParamValCount = True Then
			For I = False To .ItemCount -True
				If .Item(I) <> "-" Then _
					.ItemEnabled(I) = ParamVal(True)
			Next I
		ElseIf ParamValCount > True Then
			For I = 2 To ParamValCount
				If .Item(ParamVal(I)) <> "-" Then
					.ItemEnabled(ParamVal(I)) = ParamVal(True)
					'GetInfo (.Caption +"::Enabled " +STR$(ParamVal(True)) +" Item " +STR$(ParamVal(I)))
				Else
					modSepState ++
				End If
			Next I
		Else
			ShowMessage "Erreur: paramиtre(s) manquant(s) ou incorrect(s)"
		End If
		If modSepState Then _
			ShowMessage "Avertissement: vous tentez de modifier l'йtat " +CHR$(10) +_
						"               enfoncй d'un sйparateur..."
		If .isPaintReady = 2 Then _
			Call This.RePaint
	END SUBI
   PRIVATE:
	Event CanvasL.OnPaint
		.CanvasLMsg = True
		This.CanvasPaint (This.CanvasL)
		'.CanvasLMsg = False
	End Event
	Event CanvasR.OnPaint
		Dim R As RECT_QTBtn
		GetWindowRect_CBar (This.Handle, R)

		'CALLFUNC(.OnChange, .canvaslmsg, This)
		If .CanvasLMsg = False or R.Left < False Then
			.CanvasLMsg = False
			This.CanvasPaint (This.CanvasL)
		End If

		If .Orientation Then
			BitBlt_QTBtn ( .CanvasR.Handle, _ 
				False, False, _ 
				.CanvasR.Width, .CanvasR.Height, _
				BMPCache.Handle, _ 
				False, .FreePanelM.Top, _ 
				SrcCopy_QTBtn)
		Else
			BitBlt_QTBtn ( .CanvasR.Handle, _ 
				False, False, _ 
				.CanvasR.Width, .CanvasR.Height, _
				BMPCache.Handle, _ 
				.FreePanelM.Left, False, _ 
				SrcCopy_QTBtn)
		End If
		
		'SetRect_CBar ( R, _
		'	-True, _
		'	False, _
		'	2, _
		'	.CanvasR.Height)
		'DrawEdge_CBar (.ImageL.Handle, R, BDR_RAISEDINNER_CBar, BF_RECT_CBar)
		
	End Event
	Event ImageL.OnMouseMove (X As Integer, Y As Integer, Shift As Integer)
		SetCapture_QTBtn This.Handle
	End Event
	Event ImageR.OnMouseMove (X As Integer, Y As Integer, Shift As Integer)
		SetCapture_QTBtn This.Handle
	End Event
	Event ImageLH.OnMouseMove (X As Integer, Y As Integer, Shift As Integer)
		SetCapture_QTBtn This.Handle
	End Event
	Event ImageRH.OnMouseMove (X As Integer, Y As Integer, Shift As Integer)
		SetCapture_QTBtn This.Handle
	End Event
	SUB DrawHotItemState (iIndex As Integer, iState As Integer, iMenuDown As Integer)
		Dim SepBefore As Integer
			sepBefore = False
		.ImageLH.Visible = False

		If iIndex = -True Then
			'.CoolBtnBMPE.Width		= .FreePanelL.Width		' Devrait кtre FreePanelR.Width n'est pas dimensionnй correctement
			'.CoolBtnBMPE.Height	= .FreePanelL.Height	' Devrait кtre FreePanelR.Height n'est pas dimensionnй correctement

			' Exceed Btn
			Fast_CBar( xpt_ToolBarBtn, _
				IIf(.Orientation, 5, 4), _
				iState, _
				This.CoolBtnBMPE, _
				"", _
				False, _
				"", _
				False, _
				False, _
				.Style, _
				.DisableXPTheme, _
				This.Handle)
			.CoolBtnBMPE.TextOut(((12 -.CoolBtnBMPE.TextWidth("»")) \2) +True, _
				-6, _
				"»", _
				.Font.Color, _
				-True)

			.ImageRH.BMP = .CoolBtnBMPE.BMP
			.ImageRH.Visible = True
		ElseIf .ItemEnabled(iIndex) Then
			Dim I As Integer
			For I = False To iIndex
				'If .Item(I) <> "-" Then
				'Else
				If .Item(I) = "-" Then
					sepBefore ++
				End If
			Next I

			Dim imgLBK As QBitmap
			.CoolBtnBMP.Width	= .ItemWidth(iIndex)
			.CoolBtnBMP.Height	= .ItemsWidth

			'CoolBtnI
			If .imgLA.Count > False and (iIndex -SepBefore) < .imgLA.Count Then _
				imgLBK.BMP	= .imgLA.GetBMP(iIndex -sepBefore)

			
			.CoolBtnBMP.Font.Color = IIf (.ItemEnabled(iIndex), This.Font.Color, clGrayText) ' inc2026: iIndex вместо I: I здесь - счётчик цикла выше, после него I = iIndex + 1; вся ветка про элемент iIndex

			Fast_CBar( xpt_ToolBarBtn, _
				True, _
				IIf(.ItemDown(iIndex) and iState = True, 5, iState), _
				This.CoolBtnBMP, _
				IIf(.Orientation = False and (.ShowBtnCapt(iIndex) = True or .ShowBtnCaptAll = True), _
					This.Item(iIndex), ""), _
				IIf(.imgLA.Count > False and (iIndex -SepBefore) < .imgLA.Count, imgLBK.Width +2, False), _
				This.CoolBtnBMP.Font.Name, _
				IIf(.ItemPopupHnd(iIndex), True +iMenuDown, False), _
				False, _
				.Style, _
				.DisableXPTheme, _
				This.Handle)

			Dim decal As Integer
				decal = False
			If (iState = 2 and iMenuDown = False) or .ItemDown(iIndex) Then _
				decal = True
			If .imgLA.Count > False and (iIndex -sepBefore) < .imgLA.Count Then
				imgLBK.BMP				= .imgLA.GetBMP(iIndex -sepBefore)
				imgLBK.TransparentColor	= imgLBK.Pixel(False, False) 'clWhite
				If imgLBK.TransparentColor <> clPurple Then _
					imgLBK.TransparentColor	= imgLBK.Pixel(imgLBK.Width -True, False) 'clWhite
				imgLBK.Transparent		= True
				If (.Orientation = False and (.ShowBtnCapt(iIndex) = True or .ShowBtnCaptAll = True)) or _
					.ItemPopupHnd(iIndex) Then
					.CoolBtnBMP.Draw( 4 +decal, _
						((This.CoolBtnBMP.Height -imgLBK.Height) \2) +decal, _
						imgLBK.BMP)
				Else
					.CoolBtnBMP.Draw( ((This.CoolBtnBMP.Width -imgLBK.Width) \2) +decal, _
						((This.CoolBtnBMP.Height -imgLBK.Height) \2) +decal, _
						imgLBK.BMP)
				End If
			End If

			If .Orientation Then
				.ImageLH.Left	= False
				.ImageLH.Top	= .ItemLeft(iIndex)
			Else
				.ImageLH.Left	= .ItemLeft(iIndex)
				.ImageLH.Top	= False
			End If
			.CoolBtnBMP.TransparentColor	= .CoolBtnBMP.Pixel(False, False) ' Couleur par dйfaut  48163823
			.CoolBtnBMP.Transparent			= True
			.ImageLH.BMP					= .CoolBtnBMP.BMP
			.ImageLH.Transparent			= True
			.ImageLH.Visible				= True
		End If
	END SUB
	Event OnMouseMove (X As Integer, Y As Integer, Shift As Integer)
		Dim curBtn As Integer
		Dim ItemWidth As Integer
		Dim I As Integer
		Dim R As RECT_QTBtn
		Static firstAction As Integer
		Static wasBtn As Integer
		Static PosX As Integer, PosY As Integer
		Static isHoverInsCtrl As Integer
		Dim sepBefore As Integer


		GetWindowRect_CBar (This.Handle, R)

		If (GetCapture_QTBtn() = This.Handle And PtInRect_CBar (R, Screen.MouseX, Screen.MouseY) = False) or _
			isHoverInsCtrl = True Then
			ReleaseCapture_QTBtn

			wasBtn = -True
			isHoverInsCtrl = False

			.ImageLH.Visible = False
			.ImageRH.Visible = False
			' le pseudo-evйnement MOUSELEAVE
			'CALLFUNC(.OnMouseLeave, X, Y, Shift, This)
		ElseIf (GetCapture_QTBtn() <> This.Handle) and _
				(PosX <> X and PosY <> Y) Then
			' Verifie si la requete de relвcher la capture d'un QCBar est False
			' 
			' Ce qui va aussi empкcher le btn de reprendre son йtat initial
			' lors d'une action...
			PosX = X
			PosY = Y

			' le pseudo-evйnement MOUSEENTER
			SetCapture_QTBtn This.Handle
		ElseIf .FreePanelR.Visible and .Orientation and _
			(Y >= .ClientHeight -12 and Y <= .ClientHeight) Then ' inc2026: >= и <= вместо => и =< (в документации только >= и <=)
			.DrawHotItemState (-True, True, False)
			curBtn = -True
			wasBtn = -True
		ElseIf .FreePanelR.Visible and .Orientation = False and _
			(X >= .ClientWidth -12 and X <= .ClientWidth) Then ' inc2026: >= и <= вместо => и =< (в документации только >= и <=)
			.DrawHotItemState (-True, True, False)
			curBtn = -True
			wasBtn = -True
		Else
			.ImageRH.Visible = False
			Dim J As Integer
			FOR I = False TO .ItemCount -True
				If .Orientation Then
					If Y >= .ItemLeft(I) and Y <= .ItemLeft(I) +.ItemWidth(I) Then '.ItemLeft(I +True) Then
						curBtn = I
						If .ED_Count > False Then
							For J = False To .ED_Count -True
								If Y >= .ED_Left(J) and Y <= .ED_Left(J) Then
									curBtn = -True
									wasBtn = -True
									isHoverInsCtrl = True
									Exit For
								End If
							Next J
						End If
						If .CB_Count > False Then
							For J = False To .CB_Count -True
								If Y >= .CB_Left(J) and Y <= .CB_Left(J) Then
									curBtn = -True
									wasBtn = -True
									isHoverInsCtrl = True
									Exit For
								End If
							Next J
						End If
						Exit For
					Else
						curBtn = -True
					End If
				Else
					If X >= .ItemLeft(I) and X <= .ItemLeft(I) +.ItemWidth(I) Then '.ItemLeft(I +True) Then
						curBtn = I
						If .ED_Count > False Then
							For J = False To .ED_Count -True
								If X >= .ED_Left(J) and X <= .ED_Left(J) Then
									curBtn = -True
									wasBtn = -True
									isHoverInsCtrl = True
									Exit For
								End If
							Next J
						End If
						If .CB_Count > False Then
							For J = False To .CB_Count -True
								If X >= .CB_Left(J) and X <= .CB_Left(J) Then
									curBtn = -True
									wasBtn = -True
									isHoverInsCtrl = True
									Exit For
								End If
							Next J
						End If
						Exit For
					Else
						curBtn = -True
					End If
				End If
			NEXT I
			If (curBtn > -True and curBtn < .ItemCount) Then
				If firstAction = False or (wasBtn <> curBtn or wasBtn = -True) Then
					firstAction = True
					'Application.ShowHint = False
					'If .Item(curBtn) = "-" Then .Hint = "" Else .Hint = .Item(curBtn)
					'Application.ShowHint = True

					If .Orientation Then
						If (Y > .ItemLeft(curBtn) or Y < .ItemLeft(curBtn) +.ItemWidth(curBtn)) _
							And .Item(curBtn) <> "-" Then
							.DrawHotItemState (curBtn, True, False)
						Else
							.ImageLH.Visible = False
						End If
					Else
						If (X > .ItemLeft(curBtn) or X < .ItemLeft(curBtn) +.ItemWidth(curBtn)) _
							And .Item(curBtn) <> "-" Then
							.DrawHotItemState (curBtn, True, False)
						Else
							.ImageLH.Visible = False
						End If
					End If
				End If
				wasBtn = curBtn
				'CALLFUNC(.OnMouseEnter, X, Y, Shift, curBtn, This)	

				'GetInfo(CurBtn)
			Else
				.ImageLH.Visible = False
				'curBtn = -1
				If .Orientation Then
					If (Y > .ItemLeft(.ItemCount -True) +.ItemWidth(.ItemCount -True) or _
						Y < .ItemLeft(False)) And wasBtn <> -True Then
						'.Hint = ""
						'CALLFUNC(.OnMouseEnter, X, Y, Shift, curBtn, This)
						wasBtn = -True
					End If
				Else
					If (X > .ItemLeft(.ItemCount -True) +.ItemWidth(.ItemCount -True) or _
						X < .ItemLeft(False)) And wasBtn <> -True Then
						'.Hint = ""
						'CALLFUNC(.OnMouseEnter, X, Y, Shift, curBtn, This)
						wasBtn = -True
					End If

				End If
				'GetInfo(CurBtn)
			End If
		End If
		'GetInfo (curBtn)
	End Event
	Event OnMouseDown (btn As Integer, X As Integer, Y As Integer, Shift As Integer)
		If btn = False Then
			If .FreePanelR.Visible and _
				((.Orientation and _
				(Y >= .ClientHeight -12 and Y <= .ClientHeight)) or _
				(.Orientation = False and _
				(X >= .ClientWidth -12 and X <= .ClientWidth))) Then ' inc2026: >= и <= вместо => и =< здесь и строкой 1930 (в документации только >= и <=)
				.DrawHotItemState (-True, 2, False)
				.mnuExceed.Popup(Screen.MouseX +(.FreePanelR.Left -X), _
								 Screen.MouseY +(.ClientHeight -Y))
				.ImageRH.Visible = False
			Else
				Dim I As Integer
				Dim curBtn As Integer
				Dim R As RECT_QTBtn
				'curBtn = -1
				FOR I = False TO .ItemCount -True
					If .Orientation = False and (X >= .ItemLeft(I) and X <= .ItemLeft(I) +.ItemWidth(I)) Then '.ItemLeft(I +True)) Then
						curBtn = I
						Exit For
					ElseIf .Orientation and (Y >= .ItemLeft(I) and Y <= .ItemLeft(I) +.ItemWidth(I)) Then '.ItemLeft(I +True)) Then
						curBtn = I
						Exit For
					Else
						curBtn = -True
					End If
				NEXT I
				If curBtn > -True Then
					If .ItemEnabled(curBtn) Then
						If (X > .ItemLeft(curBtn) or X < .ItemLeft(curBtn) +.ItemWidth(curBtn)) _
							And .Item(curBtn) <> "-" Then
							If .ItemPopupHnd(curBtn) Then
								If X < .ItemLeft(curBtn) +.ItemWidth(curBtn) -11 Then
									.DrawHotItemState (curBtn, 2, False)
								Else
									.DrawHotItemState (curBtn, 2, True)
									.pShowPopup(curBtn, _
										Screen.MouseX +(.ItemLeft(curBtn) -X), _
										Screen.MouseY +(This.Height -True -Y))
									.ImageLH.Visible = False
								End If
							Else
								.DrawHotItemState (curBtn, 2, False)
							End If
						End If
					End If
				ElseIf .HideGrip = False Then
					If .Orientation = False and (X >= False and X <= 7) and _
						.Width > 29 Then
						ReleaseCapture_QTBtn
						.DragTimer.Interval	= 50
						.DragTimer.Enabled	= True
						SendMessage_CBar(This.Handle, WM_NCLBUTTONDOWN_CBar, HTCAPTION_CBar, False)
					ElseIf .Orientation and (Y >= False and Y <= 7) and _
						.Height > 29 Then
						ReleaseCapture_QTBtn
						.DragTimer.Interval	= 50
						.DragTimer.Enabled	= True
						SendMessage_CBar(This.Handle, WM_NCLBUTTONDOWN_CBar, HTCAPTION_CBar, False)
					End If
				End If
			End If
		End If
	End Event
	Event OnMouseUp (btn As Integer, X As Integer, Y As Integer, Shift As Integer)
		If btn = False Then
			If .FreePanelR.Visible and _
				((.Orientation and _
				(Y >= .ClientHeight -12 and Y <= .ClientHeight)) or _
				(.Orientation = False and _
				(X >= .ClientWidth -12 and X <= .ClientWidth))) Then ' inc2026: >= и <= вместо => и =< здесь и строкой 1994 (в документации только >= и <=)
				.DrawHotItemState (-True, True, False)
			Else
				Dim I As Integer
				Dim curBtn As Integer
				Dim R As RECT_QTBtn
				'curBtn = -1
				FOR I = False TO .ItemCount -True
					If .Orientation = False and (X >= .ItemLeft(I) and X <= .ItemLeft(I) +.ItemWidth(I)) Then '.ItemLeft(I +True)) Then
						curBtn = I
						Exit For
					ElseIf .Orientation and (Y >= .ItemLeft(I) and Y <= .ItemLeft(I) +.ItemWidth(I)) Then '.ItemLeft(I +True)) Then
						curBtn = I
						Exit For
					Else
						curBtn = -True
					End If
				NEXT I
				If curBtn > -True Then
					'GetInfo = 1003
					If .ItemEnabled(curBtn) Then
						Dim oldX As Integer, _
							oldY As Integer
						oldX = Screen.MouseX
						oldY = Screen.MouseY
						If (X > .ItemLeft(curBtn) or X < .ItemLeft(curBtn) +.ItemWidth(curBtn)) _
							And .Item(curBtn) <> "-" Then
							If .ItemGroup(curBtn) <> False Then
								.ItemDown(curBtn) = IIf(.ItemDown(curBtn), False, True)
								.isPaintReady = False
								This.CanvasPaint (This.CanvasL)
							End If
							.DrawHotItemState (curBtn, True, False)
						End If
						CALLFUNC(.OnChange, curBtn, This)
						' Si la position du curseur n'est pas celle mйmorisйe, 
						' on suppose que la fenкtre a perdu son focus et on
						' masque l'item sйlectionnй
						If oldX <> Screen.MouseX and oldY <> Screen.MouseY Then _
							.ImageLH.Visible = False
					End If
				End If
			End If
		End If
	End Event
	Event mnuExceed.OnPopup
		If .ItemCount Then
			Dim I As Integer
			For I = False To .ItemCount -True
				If .Orientation Then
					If .Height < (.ItemLeft(I) +(.ItemWidth(I) \.66)) Then
						mnuItemExceed(This.mnuItemExceedIndex(I)).Visible = True
						'GetInfo (1009)
					Else
						mnuItemExceed(This.mnuItemExceedIndex(I)).Visible = False
						'GetInfo (1010)
					End If
				Else
					If .Width < (.ItemLeft(I) +(.ItemWidth(I) \.66)) Then
						mnuItemExceed(This.mnuItemExceedIndex(I)).Visible = True
						'GetInfo (1009)
					Else
						mnuItemExceed(This.mnuItemExceedIndex(I)).Visible = False
						'GetInfo (1010)
					End If
				End If
				If I = .ItemCount -True and mnuItemExceed(This.mnuItemExceedIndex(I)).Caption = "-" Then _
					mnuItemExceed(This.mnuItemExceedIndex(I)).Visible = False
			Next I
			$IFDEF _AMIB
			Dim sepBefore As Integer
				sepBefore = False
			For I = False To .ItemCount -True
				If .Item(I) = "-" Then
					sepBefore ++
				Else
					If mnuItemExceed(This.mnuItemExceedIndex(I)).Visible = True Then
						BMPMenu.Width	= .imgLA.Width
						BMPMenu.Height	= .imgLA.Height
						BMPMenu.BMP		= .imgLA.GetBMP(I -sepBefore)
						'ClearMenuBitmap(This.mnuExceed, _
						'	mnuItemExceed(This.mnuItemExceedIndex(I)).Command, _
						'	False)
						CreateMenuBitmap(This.mnuExceed, _
							mnuItemExceed(This.mnuItemExceedIndex(I)).Command, _
							False, _
							BMPMenu)
					End If
				End If
			Next I
			$ENDIF
		End If
	End Event
	Event DragTimer.OnTimer
		If GetAsyncKeyState_CBar(VK_LBUTTON_CBar) = False Then
			.Align				= .Align
			.DragTimer.Enabled	= False
		End If
	End Event

   PUBLIC:
	PROPERTY SET SetHideGrip(nState As Integer)
		.HideGrip = nState
		If .ItemCount > False Then
			Call This.EvalBtnPos
			If .isPaintReady > False Then
				.ForceRePaint = True
				Call This.RePaint
				.ForceRePaint = False
			End If
		End If
	END PROPERTY
	PROPERTY SET SetHideCaption(nState As Integer)
		.HideCaption = nState
		If .ItemCount > False Then
			Call This.EvalBtnPos
			If .isPaintReady > False Then
				.ForceRePaint = True
				Call This.RePaint
				.ForceRePaint = False
			End If
		End If
	END PROPERTY
	PROPERTY SET SetCaption(nCaption As String)
		Super.Caption = ""
		.Caption = nCaption
		.CaptionWidth = .TextWidth (nCaption) '+4
		.CaptionHeight = .TextHeight (nCaption)
		If .ItemCount > False Then
			.ForceEvalPos = True
			Call This.EvalBtnPos
			.ForceEvalPos = False
			If .isPaintReady > False Then
				.ForceRePaint = True
				Call This.RePaint
				.ForceRePaint = False
			End If
		End If
	END PROPERTY
	'PROPERTY SET SetItemsWidth(width as integer)
	'END PROPERTY
	PROPERTY SET SetOrientation(orientation as integer)
		.Orientation = orientation
		If .Orientation Then
			.FreePanelL.Align = True
			.FreePanelR.Align = 2
			.FreePanelR.Left = False
			.FreePanelR.Height = 12
			.FreePanelR.Width = .FreePanelL.Width
			.isExceedWidth = False
			.isExceedHeight = False
		'	.CanvasR.Visible = False
			.FreePanelM.Align = 2
		Else
			.FreePanelL.Align = 3
			.FreePanelR.Align = 4
			.FreePanelR.Top = False
			.FreePanelR.Height = .FreePanelL.Height
			.FreePanelR.Width = 12
			.isExceedWidth = False
			.isExceedHeight = False
		'	.CanvasR.Visible = True
			.FreePanelM.Align = 4
		End If

		.CanvasL.Align = IIf(.Orientation, True, 3)
		'.CanvasR.Align = IIf(.Orientation, 2, 4)
		.GripWidth = IIf(.Orientation, 8, 5)
		
		.CoolBtnBMPE.Width = This.FreePanelR.Width
		.CoolBtnBMPE.Height = This.FreePanelR.Height
	END PROPERTY
	'PROPERTY SET SetBevelWidth(bw as integer)
	'	.BevelWidth = 0
	'	Super.BevelWidth = 0
	'END PROPERTY
	PROPERTY SET SetBorderStyle(bs as integer)
		.BorderStyle = bs
		Super.BorderStyle = 0
	END PROPERTY

	SUBI ItemsCaptionVisible (...)
		'... = ParamValCount
		Dim I As Integer
		Dim modSepState As Integer
		modSepState = False
		If ParamValCount = True and (ParamVal(True) = False or ParamVal(True) = True) Then
			.ShowBtnCaptAll = True
			For I = False To .ItemCount -True
				If .Item(I) <> "-" Then _
					.ShowBtnCapt(I) = ParamVal(True)
			Next I
		ElseIf ParamValCount > True Then
			For I = 2 To ParamValCount
				If .Item(ParamVal(I)) <> "-" Then
					.ShowBtnCapt(ParamVal(I)) = ParamVal(True)
				Else
					modSepState ++
				End If
			Next I
		Else
			ShowMessage "Erreur: paramиtre(s) manquant(s) ou incorrect(s)"
		End If
		If modSepState Then _
			ShowMessage "Avertissement: vous tentez de modifier " +CHR$(10) +_
						"               un sйparateur..."
		If .ItemCount > False Then
			.ForceEvalPos = True
			Call This.EvalBtnPos
			.ForceEvalPos = False
		End If
		If .isPaintReady > False Then
			.ForceRePaint = True
			Call This.RePaint
			.ForceRePaint = False
		End If
	END SUBI

	Constructor
		BevelWidth				= False
		BorderStyle				= True
		'Align					= True 'False
		'FreePanelL.Caption		= "L"
		FreePanelL.Align		= 3
		FreePanelL.BevelWidth	= False
		FreePanelL.Parent		= This
		'FreePanelL.Visible		= False
		FreePanelM.Align		= 4
		FreePanelM.Width		= 1
		'FreePanelM.Height		= 39
		FreePanelM.BevelWidth	= False
		'FreePanelM.Visible		= False
		FreePanelM.Parent		= This
		'FreePanelR.Caption		= "R"
		FreePanelR.Align		= 4
		FreePanelR.Width		= 12
		'FreePanelR.Height		= 39
		FreePanelR.BevelWidth	= False
		'FreePanelR.Visible		= False
		FreePanelR.Parent		= This
		CanvasL.Align			= 3
		CanvasL.Width			= True
		CanvasL.Height			= True
		CanvasL.Parent			= This
		CanvasR.Align			= 5 '4
		CanvasR.Width			= True
		CanvasR.Height			= True
		'CanvasR.Parent			= This
		CanvasR.Parent			= This.FreePanelM
		ImageL.Align			= 5
		ImageL.Parent			= This.FreePanelL
		ImageR.Align			= 5
		ImageR.Parent			= This.FreePanelR
		ImageLH.Visible			= False
		ImageLH.Parent			= This.FreePanelL
		ImageRH.Align			= 5
		ImageRH.Visible			= False
		ImageRH.Parent			= This.FreePanelR
		CoolBtnBMPE.Font.Name	= "MS Sans Serif"
		CoolBtnBMPE.Font.Bold	= True
		CoolBtnBMPE.Font.Size	= 12
		ItemsWidth				= 39 ' .ClientWidth -2
		GripWidth				= 5
		'mnuExceed.Alignment	= True
		DragTimer.Enabled		= False
		OnChange				= CBarOnChange_EventTemplate	' Dйfinie temporairement l'adresse, sinon il y 
																' a risque de complications... !
																' Ex: L'appelle de OnChange pourrait une autre 
																' Function... j'ai dйjа vu зa qqpart !!!
		CanvasLMsg				= False
		ImgLA.BkColor			= clPurple
	End Constructor
	End With
End Type
