' Créé par D-évolution / Created by D-evolution -=@=- 2003 - 2005

' Dans la série de objet perso voici QCoolBarXP -- Immitation d'une Barre d'outil

' CoolBarXP est une version complètement revue de ma CoolBar, d'ailleur il y a
' encore des traces de cette dernière dans le code
' Tout ça est possible via une modification de l'Add-On fournis avec QTButton
' Voyez-les posibilités !!! 
' Il ne reste plus qu'a gérer l'effet Survolle, placer une image de fond et
' on obtient une Barre d'outil casi identique à celles de WinXP (sous XP)

' Pour plus de détail sur l'utilisation de ce composant reportez vous à la
' documentation fournise... (QCoolBarXP.html)
' For more details on using this component please refer to the doc
' (QCoolBarXP.html)

' Si la doc n'est pas disponible actuellement elle le sera sous peu...
'
$Option Explicit

'Const RGN_AND = 1
'Const RGN_COPY = 5
'Const RGN_OR = 2
Const RGN_XOR_QCBar = 3
'Const RGN_DIFF = 4

'Declare Function GetClipRgn_QCBar Lib "gdi32" Alias "GetClipRgn" _
'	 (ByVal hdc As Long, ByVal hRgn As Long) As Long
Declare Function DeleteObject_QCBar Lib "gdi32" Alias "DeleteObject" _
	 (ByVal hObject As Long) As Long
Declare Function CreateRectRgn_QCBar Lib "gdi32" Alias "CreateRectRgn" _
	(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long) As Long
'Declare Function OffsetRgn_QCBar Lib "gdi32" Alias "OffsetRgn" _
'	(ByVal hRgn As Long, ByVal x As Long, ByVal y As Long) As Long

Declare Function CombineRgn_QCBar Lib "gdi32"  Alias "CombineRgn" _
	(ByVal hDestRgn As Long, ByVal hSrcRgn1 As Long, ByVal hSrcRgn2 As Long, ByVal nCombineMode As Long) As Long
Declare Function SetWindowRgn_QCBar Lib "user32" Alias "SetWindowRgn" _
	 (ByVal hWnd As Long, ByVal hRgn As Long, ByVal bRedraw As Integer) As Long

' ===
' Extrait de QTButton

$IFNDEF __RQINC' ==(corrigé! doh!)
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

Dim QCBarOptimize As Integer
	QCBarOptimize = False

Dim QCBarBMP As QBitmap
'	QCBarBMP.BMPHandle = btn_BMP' REsource bitmap

'$IFNDEF __QTBTNSHARED95
'$DEFINE __QTBTNSHARED95
'
'Declare Function GetDC_QTBtn Lib "user32" _
'		Alias "GetDC" _
'		(ByVal hwnd As Long) As Long
'Declare Function ReleaseDC_QTBtn Lib "user32" _
'		Alias "ReleaseDC" ( _
'		ByVal hwnd As Long, _
'		ByVal hdc As Long) As Long
'
'CONST SrcCopy_QTBtn = &HCC0020	' Celui dans RapidQ.INC n'est pas correct
'
'Declare Function BitBlt_QTBtn Lib "gdi32" _
'		Alias "BitBlt" ( _
'		hDC As Integer, _
'		nXDest As Integer, nYDest As Integer, _
'		nWidth As Integer, nHeight As Integer, _
'		hdcSrc As Integer, _
'		nXSrc As Integer, nYSrc As Integer, _
'		dwRop As Integer) As Integer
'
'' Pour Win98 et supérieur
'Declare Function TransparentBlt_QTBtn Lib "msimg32" _
'		Alias "TransparentBlt" ( _
'		ByVal hdcDest As Long, _
'		ByVal nXOriginDest As Long, ByVal nYOriginDest As Long, _
'		ByVal nWidthDest As Long, ByVal nHeightDest As Long, _
'		ByVal hdcSrc As Long, _
'		ByVal nXOriginSrc As Long, ByVal nYOriginSrc As Long, _
'		ByVal nWidthSrc As Long, ByVal nHeightSrc As Long, _
'		ByVal crTransparent As Long) As Long
'$ENDIF ' __QTBTNSHARED

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

' Ajouté 6fév
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

' -- (Ajouté 11janv) Les Nouveaux API pour le suport des Thèmes de Bureau XP
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

Dim maxNumBMPs_QCBar As Integer
	maxNumBMPs_QCBar = 5

' //--

'Extrait de QTButton_AddOns
Sub Fast_QCBarToQTBtn( _
					   BtnType As String, _
					   PartID As Integer, _
					   Sender As QBitmap, _
					   Caption As String, _
					   wMenu As Integer, _
					   Grouped As Integer, _
					   Hwnd As Long)
					 '( _
					 '  BtnType As String, _
					 '  PartID As Integer, _
					 '  Sender As QBitmap, _
					 '  Caption As String, _
					 '  pWidth As Integer, _
					 '  pLeft As Integer, _
					 '  wMenu As Integer, _
					 '  Hwnd As Long)
	Dim Dest As QRect, Source As QRect
	Dim tmpBitmap1 As QBitmap, _
		NBitmap1 As QBitmap, _
		XPBitmap1 As QBitmap
	Dim XPBtnType As String ' Ajouté 19jan corrige un problème où les types sont différents
	Dim XPPartID As Integer
	'Dim oldCaption As String
	'	oldCaption = Sender.Caption
	Dim Width1 As Integer, Height1 As Integer
	Dim Width2 As Integer, Height2 As Integer
	Dim btnCount As Integer

	'Sender.Flat = False
	'Sender.NumBMPs = maxNumBMPs_QCBar
    'Sender.Spacing = False
	btnCount = maxNumBMPs_QCBar 'Sender.NumBMPs

	'if btnCount > maxNumBMPs_QCBar Then
	'	btnCount = maxNumBMPs_QCBar
	'	sender.numbmps = btncount
	'end if
	
	Dim fixTab As Integer
	fixTab = False

	if isXP_QTBtn and BtnType = xpt_TabBtn Then _
		fixTab = True
	if isXP_QTBtn and (BtnType = xpt_pushbtn or BtnType = xpt_toolbarbtn or BtnType = xpt_TabBtn) Then _
		PartID = True

	Width1 = ((Sender.Width +3) *btnCount) +True
	Height1 = Sender.Height +3
	DoEvents
	' Si l'image à déjà la même dimension elle ne sera pas redimensionnée
	'If QCBarOptimize <> True or (Width2 <> Width1 and Height2 <> Height1) Then
	If QCBarOptimize <> True or _
		(isXP_QTBtn = True and (XPBtnType <> BtnType or PartID <> XPPartID)) or _
		(tmpBitmap1.Width <> Width1 and tmpBitmap1.Height <> Height1 and _
		  Width2 <> tmpBitmap1.Width and Height2 <> tmpBitmap1.Width) Then
		With NBitmap1
			.Width = Width1		'== (mod)
			.Height = Height1	'== (mod)
			.FillRect(False, False, .Width, .Height, clBtnFace)'==(mod) (13janv remplacé clPurple par clBtnFace)
			'.PixelFormat = DefPixelFormat_CBar
		End With
		With XPBitmap1
			.Width = Width1		'== (mod)
			.Height = Height1	'== (mod)
			.FillRect(False, False, .Width, .Height, clBtnFace)'==(mod) (13janv remplacé clPurple par clBtnFace)
			'.PixelFormat = DefPixelFormat_CBar
		End With
		Width1 = Sender.Width *btnCount
		Height1 = Sender.Height

		tmpBitmap1.Font.Name = Sender.Font.Name' == (add)
		tmpBitmap1.Font.Size = Sender.Font.Size' == (add)
		tmpBitmap1.Font.Color = Sender.Font.Color' == (add)
		tmpBitmap1.Font.Bold = Sender.Font.Bold
		tmpBitmap1.Font.Italic = Sender.Font.Italic
		tmpBitmap1.Font.Underline = Sender.Font.Underline

		If isXP_QTBtn = False Then
			' Thème non activé ou ce n'est pas Windows XP

			Dim J As Integer, I As Integer
			For J = False To btnCount -True
				' Le centre ----------------------------------------------------------
				With Dest
					.Left = ((Width1 \btnCount) *J) +3 +(True *(J +True)) +(J *2) -iif(J = 2, True, False)
					.Top = 4 -iif(J=2, True, False)
					.Right = .Left +(Width1 \btnCount) -6
					.Bottom = Height1 -2 -iif(J = 2, True, False)
				End With
				With Source: .Left = ((QCBarBMP.Width \btnCount) *J) +3: .Top = 3: _
					.Right = .Left +(QCBarBMP.Width \btnCount) -6
					.Bottom = QCBarBMP.Height -3
				End With

				NBitmap1.CopyRect(Dest, QCBarBMP, Source)

				' Les coins ----------------------------------------------------------
				For I = False TO 3
					With Dest
						.Left = ((Width1 \btnCount) *J) _
								+IIf(I = False or I = 2, False, (Width1 \btnCount) -3) +(True *(J +True)) +(J *2) _
								-iif(J = 2, True, False)
						.Top = IIf(I<2, True, Height1 -2) -iif(J = 2, True, False)
						.Right = .Left +3
						.Bottom = .Top +3
					End With
					With Source
						.Left = ((QCBarBMP.Width \btnCount) *J) _
								+IIf(I = False or I = 2, False, (QCBarBMP.Width \btnCount) -3)
						.Top = IIf(I < 2, False, QCBarBMP.Height -3)
						.Right = .Left +3
						.Bottom = .Top +3
					End With
					NBitmap1.CopyRect(Dest, QCBarBMP, Source)
				Next I
				' Les horizontaux ----------------------------------------------------
				For I = False TO True
					With Dest
						.Left = ((Width1 \btnCount) *J) +3 +(True *(J +True)) +(J *2) -iif(J = 2, True, False)
						.Top = IIf(I = False, True, Height1 -2) -iif(J = 2, True, False)
						.Right = .Left +(Width1 \btnCount) -6
						.Bottom = .Top +3
					End With
					With Source
						.Left = (QCBarBMP.Width \btnCount) *J +3
						.Top = IIf(I = False, False, QCBarBMP.Height -3)
						.Right = .Left +(QCBarBMP.Width \btnCount) -6
						.Bottom = .Top +3
					End With
					NBitmap1.CopyRect(Dest, QCBarBMP, Source)
				Next I
				' Les verticaux ------------------------------------------------------
				For I = False TO True
					With Dest
						.Left = ((Width1 \btnCount) *J) _
								+IIf(I = False, False, (Width1 \btnCount) -3) +(True *(J +True)) +(J *2) _
								-iif(J = 2, True, False)
						.Top = 4 -iif(J = 2, True, False)
						.Right = .Left +3
						.Bottom = Height1 -2 -iif(J = 2, True, False)
					End With
					With Source
						.Left = ((QCBarBMP.Width \btnCount) *J) +IIf(I = False, False, (QCBarBMP.Width \btnCount) -3)
						.Top = 3
						.Right = .Left +3
						.Bottom = QCBarBMP.Height -3
					End With
					NBitmap1.CopyRect(Dest, QCBarBMP, Source)
				Next I
			Next J
			NBitmap1.PixelFormat = DefPixelFormat_CBar
		Else
			' Thème activé (Windows XP)
			' --
			Dim hTheme As Long
			'On Error Resume Next

			' Ouverture du thème
			Dim rtButton As String ', _
			'	bgButton As String
			rtButton = ""
			'bgButton =	"R" +rqNullChr_CBar +_
			'			"e" +rqNullChr_CBar +_
			'			"B" +rqNullChr_CBar +_
			'			"a" +rqNullChr_CBar +_
			'			"r" +rqNullChr_CBar +_
			'			rqNullChr_CBar

			Dim lR As Long
			Dim m_hDC As Long
			Dim m_lPartId As Long, m_lStateId As Long
			Dim tR As RECT_QTBtn

			' Finalement inutile
			'rtButton =	
			'hTheme = OpenThemeData_QTBtn(Hwnd, VarPtr(bgButton))
			'If hTheme <> False Then
			'	m_hDC = XPBitmap1.Handle

			'	tR.Left = -pLeft 'False
			'	tR.Top = False '-True 'False
			'	tR.Right = pWidth -pLeft 'Sender.Width
			'	tR.Bottom = Sender.Height +True

			'	lR = DrawThemeBackground_QTBtn(hTheme, _
			'							 m_hDC, _
			'							 6, _
			'							 True, _
			'							 tR, tR)
			'End If
			'CloseThemeData_QTBtn hTheme
			'CloseThemeData_QTBtn hTheme

			' Format unicode ?!?
			For I = True To Len(BtnType)
				rtButton = rtButton +Mid$(BtnType, I, True) +rqNullChr_CBar
			Next I
			rtButton = rtButton +rqNullChr_CBar ' Un dernier pour finaliser

			hTheme = OpenThemeData_QTBtn(Hwnd, VarPtr(rtButton))
			If hTheme <> False Then
				' Styles XP disponible

				' m_hDC est le DC pour dessiner
				' m_lPartId et m_lStateId sont la class + l'état à dessiner
				' tR est un RECT spécifiant la zone dans laquelle dessiner
				m_hDC = XPBitmap1.Handle
				Dim mLeft As Integer
				mLeft = False
				If wMenu > False Then
					m_lPartId = 3
					mLeft = 12
				ElseIf PartID > True Then
					m_lPartId = PartID
				Else
					m_lPartId = True 'BP_PUSHBUTTON
				End If

				For I = False To 2 Step 2
					m_lStateId = I +True 'PBS_NORMAL
					tR.Left = ((I *(Sender.Width +3)) +iif(I <> 2, True, False))
					tR.Top = True -iif(I <> 2, False, True) +fixTab 'False -iif(I <> 2, False, True)
					tR.Right = (tR.Left +Sender.Width) -mLeft '+True
					tR.Bottom = (Sender.Height +True -iif(I <> 2, False, True) +fixTab) -True '-2 '+iif(I <> 2, True, False)

					lR = DrawThemeBackground_QTBtn(hTheme, _
											 m_hDC, _
											 m_lPartId, _
											 m_lStateId, _
											 tR, tR)
				Next I
				' Inverse Sélectionné et Désactivé (Survolle est remplacé par Sélectionné)
				For I = True To 3 Step 2
					m_lStateId = (I +True) +iif(I = True, True +Grouped, False) '+iif(I = True, True, False)'PBS_NORMAL
					'tR.Left = (((I +iif(I = True, 2, -2)) *(Sender.Width +3)) +True)
					'tR.Top = True
					tR.Left = (((I +iif(I = True, 2, -2)) *(Sender.Width +3)) +iif(I = True, False, True))
					tR.Top = iif(I = True, False, True +fixTab)
					tR.Right = (tR.Left +Sender.Width) -mLeft '+True 
					tR.Bottom = Sender.Height +True +fixTab -True '-2 '+2

					lR = DrawThemeBackground_QTBtn( hTheme, _
													m_hDC, _
													m_lPartId, _
													m_lStateId, _
													tR, tR)
				Next I
				'Survole
				m_lStateId = 2
				tR.Left = (4 *(Sender.Width +3)) +True
				tR.Top = True
				tR.Right = (tR.Left +Sender.Width) -mLeft '+True 
				tR.Bottom = Sender.Height +fixTab +True '+2

				lR = DrawThemeBackground_QTBtn( hTheme, _
												m_hDC, _
												m_lPartId, _
												m_lStateId, _
												tR, tR)
				If wMenu > False Then
					mLeft = Sender.Width -11
					m_lPartId = 4

					For I = False To 2 Step 2
						m_lStateId = I +True 'PBS_NORMAL
						tR.Left = ((I *(Sender.Width +3)) +iif(I <> 2, True, False)) +mLeft
						tR.Top = True -iif(I <> 2, False, True) +fixTab 'False -iif(I <> 2, False, True)
						tR.Right = (tR.Left +Sender.Width) -mLeft '+True
						tR.Bottom = (Sender.Height +True -iif(I <> 2, False, True) +fixTab) -True '-2 '+iif(I <> 2, True, False)

						lR = DrawThemeBackground_QTBtn(hTheme, _
												 m_hDC, _
												 m_lPartId, _
												 m_lStateId, _
												 tR, tR)
					Next I
					' Inverse Sélectionné et Désactivé (Survolle est remplacé par Sélectionné)
					For I = True To 3 Step 2
						m_lStateId = (I +True) +iif(I = True, True, False)'PBS_NORMAL
						'tR.Left = (((I +iif(I = True, 2, -2)) *(Sender.Width +3)) +True)
						'tR.Top = True
						tR.Left = (((I +iif(I = True, 2, -2)) *(Sender.Width +3)) +iif(I = True, False, True)) +mLeft
						tR.Top = iif(I = True, False, True +fixTab)
						tR.Right = (tR.Left +Sender.Width) -mLeft '+True 
						tR.Bottom = Sender.Height +True +fixTab -True '-2 '+2

						lR = DrawThemeBackground_QTBtn(hTheme, _
												 m_hDC, _
												 m_lPartId, _
												 m_lStateId, _
												 tR, tR)
					Next I
					'Survole
					m_lStateId = 2
					tR.Left = (4 *(Sender.Width +3)) +True +mLeft
					tR.Top = True
					tR.Right = (tR.Left +Sender.Width) -mLeft '+True 
					tR.Bottom = Sender.Height +True +fixTab '-2 '+2

					lR = DrawThemeBackground_QTBtn(hTheme, _
											 m_hDC, _
											 m_lPartId, _
											 m_lStateId, _
											 tR, tR)
				End If
			End If

			' Session de dessin terminée
			CloseThemeData_QTBtn hTheme
			CloseThemeData_QTBtn hTheme
			'//--
			XPBitmap1.PixelFormat = DefPixelFormat_CBar
		End If

	End If
	Width2 = ((Sender.Width +3) *btnCount) +True
	Height2 = Sender.Height +3
	
	
	If isXP_QTBtn Then
		tmpBitmap1.BMP = XPBitmap1.BMP
	Else
		tmpBitmap1.BMP = NBitmap1.BMP
	End If

	'If Caption = "" Then
	'	'Sender.Layout = False
	'Else
	'	SetBkMode_QTBtn tmpBitmap1.Handle, True
	'	For I = False To 2 Step 2
	'		tR.Left = ((I *(Sender.Width +3)) +iif(I <> 2, True, False))
	'		tR.Top = True -iif(I <> 2, False, True) +fixTab 'False -iif(I <> 2, False, True)
	'		tR.Right = (tR.Left +Sender.Width) '+True
	'		tR.Bottom = (Sender.Height +True -iif(I <> 2, False, True) +fixTab) '+iif(I <> 2, True, False)

	'		DrawText_QTBtn (tmpBitmap1.Handle, Caption, Len(Caption), _
	'						tR, DT_CENTER_QTBtn OR DT_SINGLELINE_QTBtn OR DT_VCENTER_QTBtn)
	'	Next I
	'	' Inverse Survolle et Désactivé
	'	For I = True To 3 Step 2
	'		'tR.Left = (((I +iif(I = True, 2, -2)) *(Sender.Width +3)) +True)
	'		'tR.Top = True
	'		tR.Left = (((I +iif(I = True, 2, -2)) *(Sender.Width +3)) +iif(I = True, False, True))
	'		tR.Top = iif(I = True, False, True +fixTab)
	'		tR.Right = (tR.Left +Sender.Width) '+True 
	'		tR.Bottom = Sender.Height +True +fixTab '+2

	'		DrawText_QTBtn (tmpBitmap1.Handle, Caption, Len(Caption), _
	'						tR, DT_CENTER_QTBtn OR DT_SINGLELINE_QTBtn OR DT_VCENTER_QTBtn)
	'	Next I

	'	tmpBitmap1.Height = (Height1 +True) +tmpBitmap1.TextHeight(Caption)
	'	'Sender.Layout = 3
	'End If
	tmpBitmap1.PixelFormat = DefPixelFormat_CBar

	XPBtnType = BtnType
	If PartID <> True Then PartID = True
	XPPartID = True
	'tmpBitmap1.Transparent = True
	' Prévient l'apparission du rectangle de survole de CoolBtn
	'tmpBitmap1.Pixel(True, True) = clPurple
	'tmpBitmap1.TransparentColor = clPurple
	'tmpBitmap1.TransparentColor = tmpBitmap1.Pixel(True, True)
	Sender.BMP = tmpBitmap1.BMP
End Sub


Sub XPPart ( _
			 BtnType As String, _
			 PartID As Integer, _
			 Orientation As Integer, _
			 DisableXPThemeBG As Integer, _
			 Color, _
			 Sender As QImage, _
			 hWnd As Long)
	If isXP_QTBtn Then
		' Thème activé (Windows XP)
		' --
		Dim XPBitmap1 As QBitmap
		XPBitmap1.Width = Sender.Width
		XPBitmap1.Height = Sender.Height
		If DisableXPThemeBG or PartID <> 6 Then _
			XPBitmap1.FillRect(False, False, Sender.Width, Sender.Height, Color)

		Dim hTheme As Long
		'On Error Resume Next

		' Ouverture du thème
		Dim rtButton As String
		rtButton = ""
		' Format unicode ?!?
		Dim I As Integer
		For I = True To Len(BtnType)
			rtButton = rtButton +Mid$(BtnType, I, True) +rqNullChr_CBar
		Next I
		rtButton = rtButton +rqNullChr_CBar ' Un dernier pour finaliser

		hTheme = OpenThemeData_QTBtn(hWnd, VarPtr(rtButton))
		If hTheme <> False Then
			' Styles XP disponible

			Dim lR As Long
			Dim m_hDC As Long
			Dim m_lPartId As Long, m_lStateId As Long
			Dim tR As RECT_QTBtn

			' m_hDC est le DC pour dessiner
			' m_lPartId et m_lStateId sont la class + l'état à dessiner
			' tR est un RECT spécifiant la zone dans laquelle dessiner
			m_hDC = XPBitmap1.Handle
			If PartID > True Then _
				m_lPartId = PartID _
			Else _
				m_lPartId = True 'BP_PUSHBUTTON

			m_lStateId = True 'PBS_NORMAL
			If Orientation Then
				tR.Left = False -IIf(PartID =< 2, True, False)
				tR.Top = False
				tR.Right = Sender.Width -IIf(PartID =< 2, True, False)
				tR.Bottom = IIf(PartID =< 2, 8, Sender.Height)
			Else
				tR.Left = False
				tR.Top = False -IIf(PartID =< 2, True, False)
				tR.Right = IIf(PartID =< 2, 5, Sender.Width)
				tR.Bottom = Sender.Height -IIf(PartID =< 2, True, False)
			End If

			lR = DrawThemeBackground_QTBtn(hTheme, _
									 m_hDC, _
									 m_lPartId, _
									 m_lStateId, _
									 tR, tR)
			Sender.BMP = XPBitmap1.BMP
		End If

		' Session de dessin terminée
		CloseThemeData_QTBtn hTheme
		CloseThemeData_QTBtn hTheme
		'//--
		'XPBitmap1.PixelFormat = DefPixelFormat_CBar
	End If
End Sub
' //==

'Declare Function LoadIcon Lib "user32" Alias "LoadIconA" _
'	(ByVal hInstance As Long, ByVal lpIconName As Long) As Long
'Declare Function DestroyIcon Lib "user32" Alias "DestroyIcon" _
'	(ByVal hIcon As Long) As Long

'Declare Function LoadCursor Lib "user32" Alias "LoadCursorA" _
'	(ByVal hInstance As Long, ByVal lpCursorName As Long) As Long
'Declare Function DestroyCursor Lib "user32" Alias "DestroyCursor" _
'	(ByVal hCursor As Long) As Long
'Declare Function DrawIcon Lib "user32" Alias "DrawIcon" _
'	(ByVal hdc As Long, ByVal x As Long, ByVal y As Long, ByVal hIcon As Long) As Long
'Declare Function GetCursor Lib "user32" Alias "GetCursor" () As Long

'Declare Function CBar_EnumChild LIB "User32" ALIAS "EnumChildWindows" _
'	(hWndParent AS LONG,lpEnumFunc AS LONG,lParam AS LONG) _
'	AS LONG
'Declare Function CBar_GetClassName LIB "User32" ALIAS "GetClassNameA" _
'	(hwnd AS LONG,ByRef lpClassName AS STRING,nMaxCount AS LONG) _
'	AS LONG

'Declare Function CBar_GetParent Lib "user32" Alias "GetParent" _
'	(ByVal hwnd As Long) _
'	As Long
'Declare Function CBar_SetParent Lib "user32" Alias "SetParent" _
'	(ByVal hWndChild As Long, ByVal hWndNewParent As Long) _
'	As Long

'Declare Function EnumChild(hWnd as long,lParam as long) as long

'DIM LH AS LONG
'DIM BFR AS STRING: BFR = SPACE$(100)

'DECLARE FUNCTION CBar_GetWindowText LIB "user32" ALIAS "GetWindowTextA" _
'	(ByVal hwnd AS LONG, ByVal lpString AS STRING, ByVal cch AS LONG) _
'	AS LONG
'DECLARE FUNCTION CBar_GetClassName LIB "user32" ALIAS "GetClassNameA" _
'	(ByVal hwnd AS LONG, ByVal lpClassName AS STRING, ByVal nMaxCount AS LONG) _
'	AS LONG
'DECLARE FUNCTION CBar_GetWindowRect LIB "user32" ALIAS "GetWindowRect" _
'	(ByVal hwnd AS LONG, lpRect AS RECT_QTBtn) _
'	AS LONG


'DrawEdge Constants
'Const BDR_RAISEDOUTER = &H1
Const BDR_SUNKENOUTER_QCBar = &H2
'Const BDR_RAISEDINNER = &H4
'Const BDR_SUNKENINNER = &H8

'Const BDR_OUTER	= &H3
'Const BDR_INNER	= &HC
'Const BDR_RAISED	= &H5
'Const BDR_SUNKEN	= &HA

Const BF_LEFT_QCBar		= &H1
Const BF_TOP_QCBar		= &H2
Const BF_RIGHT_QCBar	= &H4
Const BF_BOTTOM_QCBar	= &H8

Const BF_RECT_QCBar = (BF_LEFT_QCBar Or BF_TOP_QCBar Or BF_RIGHT_QCBar Or BF_BOTTOM_QCBar)

'Const BF_MIDDLE	= &H800		' Fill in the middle.
'Const BF_SOFT		= &H1000	' Use for softer buttons.
'Const BF_ADJUST	= &H2000	' Calculate the space left over.
Const BF_FLAT_QCBar	= &H4000	' For flat rather than 3-D borders.
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

Declare Function DrawEdge_QCBar Lib "user32" Alias "DrawEdge" _
	(ByVal hdc As Long, qrc As RECT_QTBtn, ByVal edge As Long, ByVal grfFlags As Long) _
	As Long
'Declare Function DrawFrameControl Lib "user32" Alias "DrawFrameControl" _
'	(ByVal hdc As Long, lpRect As RECT_QTBtn, ByVal un1 As Long, ByVal un2 As Long) _
'	As Long
Declare Function SetRect_QCBar Lib "user32" Alias "SetRect" _
	(lpRect As RECT_QTBtn, ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, ByVal Y2 As Long) _
	As Long
'Declare Function OffsetRect Lib "user32" Alias "OffsetRect" _
'	(lpRect As RECT_QTBtn, ByVal x As Long, ByVal y As Long) _
'	As Long

Declare Function GetMenuItemCount_QCBar Lib "user32" Alias "GetMenuItemCount" ( _
		ByVal hMenu As Long) As Long
'Declare Function GetMenuItemRect Lib "user32" Alias "GetMenuItemRect" ( _
'		ByVal hwnd As Long, _
'		ByVal hMenu As Long, _
'		ByVal uItem As Long, _
'		lprcItem As RECT_QTBtn) As Long

'Const HTCLIENT_QCBar	= 1
Const HTCAPTION_QCBar	= 2
Const WM_NCLBUTTONDOWN_QCBar = &HA1
'Const WM_NCLBUTTONUP_QCBar	= &HA2
'Const WM_LBUTTONDOWN_QCBar = &H201
'Const WM_LBUTTONUP_QCBar = &H202
Declare Function SendMessage_QCBar Lib "user32" Alias "SendMessageA" _
	(ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long,lParam As long) _
	As Long


'Declare Sub BMPStretch2_Property (Width As Integer, Height As Integer, Sender As QBitmap)

Dim Style As Integer
	Style = False 'True

' Event Template pour les nouveaux événements MouseLeave et MouseEnter
DECLARE SUB CBarOnMouseEnter_EventTemplate (X As Integer, Y As Integer, Shift As Integer, ItemIndex As Integer, Sender As QPanel)
DECLARE SUB CBarOnMouseLeave_EventTemplate (X As Integer, Y As Integer, Shift As Integer, Sender As QPanel)
DECLARE SUB CBarOnChange_EventTemplate (ItemIndex As Integer, Sender As QPanel)
'Dim MainCoolBarHandles(4) As Long

'Type QMainCoolBar Extends QPanel
'  With QMainCoolBar
'	Panel(1 To 5)	As QPanel
'	PanelCount		As Integer
'	CoolBarCount	As Long
'	CoolBarHnd(40)	As Long
'
'	Function EnumChild(hWnd as long,lParam as long) as long
'		dim Buffer as string
'
'		Buffer = Space$(255)
'		Call CBar_GetClassName(hWnd, Buffer, 255)
'		if INSTR(UCASE$(Buffer), "TPANELS") then
'			if .CoolBarCount > False then
'				if hwnd <> .CoolBarHnd(.CoolBarCount -1) then
'					.CoolBarHnd(.CoolBarCount) = hWnd
'					.CoolBarCount ++
'				end if
'			else
'				.CoolBarHnd(.CoolBarCount) = hWnd
'				.CoolBarCount ++
'			end if
'		end if
'		Result=true
'	End Function
'
'	Function AddMainCoolBarHandle () As Long ' (hwnd As Long) As Long
'		Dim I As Integer
'		For I = False TO 4
'			If MainCoolBarHandles(I) = False and MainCoolBarHandles(I) <> .Handle Then
'				MainCoolBarHandles(I) = .Handle
'				Result = 1
'			End If
'		Next I
'	End Function
'
'	Sub RePaint
'		CBar_EnumChild(QMainCoolBar.Handle, CODEPTR(QMainCoolBar.EnumChild), False)
'		Dim I As Integer
'		Dim newParent As Long
'		newParent = .Panel(1).Handle
'		For I = True To .CoolBarCount -True
'			If .CoolBarHnd(I) <> newParent Then
'				If GetParent(.CoolBarHnd(I)) = .Handle Then
'					SetParent .CoolBarHnd(I), newParent
'					LH = GETWINDOWTEXT(.CoolBarHnd(I),@BFR, 100)
'					ShowMessage STR$(.CoolBarHnd(I)) +chr$(10) +_
'								STR$(.Handle) +chr$(10) +_
'								LEFT$(BFR, LH)
'				End If
'			End If
'			If GetParent(.CoolBarHnd(I)) = .Handle Then
'					SetParent .CoolBarHnd(I), newParent
'				LH = GETWINDOWTEXT(.CoolBarHnd(I),@BFR, 100)
'				ShowMessage "Erreur:  Parent " +STR$(GetParent(.CoolBarHnd(I))) +chr$(10) +_
'							STR$(newParent) +chr$(10) +_
'							STR$(.Handle) +chr$(10) +_
'							LEFT$(BFR, LH)
'			End If
'		Next I
'	End Sub
'
'	Constructor
'		Align		= alTop
'		BevelWidth	= False
'		PanelCount	= True
'		Panel(2).Parent = QMainCoolBar
'		Panel(2).Caption = "Panel2"
'		Panel(1).Align = alTop
'		Panel(1).Parent = QMainCoolBar
'		'Panel(1).Visible = False
'		Panel(1).Align = alTop
'		'AddMainCoolBarHandle'(QMainCoolBar.Handle)
'	End Constructor
'  End With
'End Type

Sub DrawMyText( _
				Left As Integer, _
				Top As Integer, _
				Right As Integer, _
				Bottom As Integer, _
				Caption As String, _
				nFontName As String, _
				nColor As Integer, _
				Sender As QBitmap)
	Dim tR As RECT_QTBtn
	SetRect_QCBar(tR, Left, Top, Right, Bottom)

	Dim sFontName As String
	If nFontName <> "" and nFontName <> Sender.Font.Name Then
		sFontName = Sender.Font.Name
		Sender.Font.Name = nFontName
	End If
	Dim sColor As Integer
	If nColor <> -True and nColor <> Sender.Font.Color Then
		sColor = Sender.Font.Color
		Sender.Font.Color = nColor
	End If

	SetBkMode_QTBtn Sender.Handle, True
	DrawText_QTBtn (Sender.Handle, Caption, Len(Caption), _
					tR, DT_SINGLELINE_QTBtn OR DT_VCENTER_QTBtn) ' DT_CENTER_QTBtn OR

	If nFontName <> "" and nFontName = Sender.Font.Name Then _
		Sender.Font.Name = sFontName
	If nColor <> False and nColor = Sender.Font.Color Then _
		Sender.Font.Color = sColor
	nFontName = ""
	sFontName = ""
	nColor = -True
	sColor = -True
	SetRect_QCBar(tR, False, False, False, False)
End Sub

Const VK_LBUTTON_QCBar As Long = &H1
'Const VK_RBUTTON_QCBar As Long = &H2

Declare Function GetAsyncKeyState_QCBar Lib "user32" _
		Alias "GetAsyncKeyState" ( _
		ByVal vKey As Long) _
		As Integer

Type QCoolBarXP Extends QPanel
  ' À Faire/TODO :
  ' *Permettre de modifier l'orientation de la barre						(Orientation)
  '																			(0. Horizontal, 1. Vertical)
  ' Permettre de définir l'espace entre les btns							(BtnsSpacing)
  ' Permettre de définir l'emplacement vertical (à partir du haut) des btns	(BtnsDistVert)
  ' Permettre de définir l'emplacement horizontal (à partir de la gauche) des btns	(BtnsDistHorz)
  ' *Permettre de regrouper/dégrouper certains btns							(DefineBtnsGroup(Group, ...))
  '																			(-1) nettoie tous les groupes
  ' *Permettre d'initialliser l'état enfoncé de certains btns				(InitBtnsDownUp(False ou True, ...))
  '   DefineBtnsGroup doit avoir été définie au préalable					(False ou True) enfonce ou non tous les btns
  ' Permettre de désélectionner un btn groupé
  ' *Permettre de désactiver/activer certains btns							(EnableBtns(False ou True,...))
  '																			(False ou True) désactive ou active tous les btns
  ' *Permettre d'afficher/masquer le titre des btns							(ShowBtnsCaption(False ou True, ...))
  '   non disponnible si l'Orientation de la Barre est autre que Faux
  ' *Lorsque la largeur de la Barre est inférieur à celle de sont Parent
  '   afficher soit un popupmenu, soit une barre flottante					(ExceedShowPopup(Menu ou FloatBar))
  ' *Permettre de désactiver l'image de fond sous XP						(DisableXPThemeBG)
  ' Permettre de désactiver le thème XP										(DisableXPTheme)
  ' Permettre de personnaliser l'image de fond								(CustBG = IMGBMP/RES)
  ' *Permettre le partage d'une image de fond commune						(BGFromContainer)
  ' Permettre de personnaliser l'image de la "Grippe"						(CustGrip = IMGBMP/RES)
  ' Permettre de personnaliser l'image des btns	(non-XP)					(CustBtns = IMGBMP/RES)
  ' *Permettre d'ajouter des images pour les états Désactivés/Survolle/Sélectionné	(IMGL? (IMGBMP/RES))
  ' Permettre d'utiliser une collection d'image à la place des ImageLists	(CollectionBMP.Empty = Faux)
  ' Permettre de placer une image ou un titre devant un contrôle (Edit, ComboBox)
  ' Réintroduire les 4 styles de btns offerts par la version original
  ' Si ShowGrip = 2 la grippe sera affiche comme décoration seulement
  ' Ajouter DelItems
  ' Permettre de vérouiller la barre (si align = 0 donc à corriger)
  ' Corriger l'arrière plan lorsque Orientation = Vrai
  ' Plus besoin de lancer .RePaint, mais il est toujours conseillé
  '   puisque l'on voit les btns se positionner lors du chargement
  '
  With This
   PRIVATE:
	IsPainted	As Integer
	'dummypanel		As QPanel		' Utiliser pour forcer BtnsHotTrack à garder le premier plan
	FlickeringFree	As QPanel
	Dest			As QRect
	Src				As QRect
	PnlExceed		As QPanel		' ...
	CBtnExceed		As QCoolBtn		' ...
	CBtnExceedHot	As QImage		' ...
	CBtnExceedHotTrack	As QImage	' Capture l'événement OnMouseMove avant que CoolBtn l'intercepte
	mnuExceed		As QPopupMenu	' ...
	mnuItemExceed(30) As QMenuItem	' ...
	mnuItemCount	As Integer		' ...
	CoolBtnBMP		As QBitmap		' Img sur laquelle l'enjolivure est dessinée avant d'être transférée
	CoolBtn(30)		As QCoolBtn		' Btns de la Barre d'outil
	ImgBtnHot(30)	As QImage		' Image(s) survolle de chaque btns
	BMPtmp			As QBitmap		' Image temporaire
	BtnsHotTrack	As QImage		' Capture l'événement OnMouseMove avant que CoolBtn l'intercepte
	'IMGMask		As QBitmap		' ...
	IMGBackGround	As QImage		' Image de fond
	IMGStretchedBackGround As QImage
	IMGStretchedBackGround2 As QImage
	IMGBackGroundFix As QBitmap		' Corrige les dimensions de IMGBackGround
	'Bitmap2		AS QBitmap
	'Bitmap3		AS QBitmap
	DragTimer		As QTimer
   PUBLIC:
	mnuPopup(29)	AS QPopupMenu	' Menu popup pour chaque btn, il seront affiché sur demande
	'CustBG			As QBitmap		' Image de fond
	'CustGrip		As QBitmap		' Image de la "Grippe"
	'CustSkin		As QBitmap		' Image de l'enjolivure
	imgLA			AS QImageList	' ImgLst des btns Actifs
	imgLD			AS QImageList	' ImgLst des btns Inactifs
	imgLS			AS QImageList	' ImgLst des btns Sélectionnés
	imgLH			AS QImageList	' ImgLst des btns Survollés
	'CollectionBMP	AS QBitmap		' Une collection d'image de tous les btns
   PRIVATE:
	imgLBK			AS QBitmap		' Corrige le problème de transparence des ImgLists
	'CanvasLeft		AS QCanvas		' ...
	CanvasRight		AS QCanvas		' ...
	CaptionWidth	As Integer		' Largeur du titre de la barre
	CaptionHeight	As Integer		' Hauteur du titre de la barre (En réalité il sagit de la position suppérieur)
	Btn(30)			As String		' Titre de chaque btn
	ShowBtnCapt(30)	As Integer		' Largeur du titre de chaque btn en pixel
	BtnLeft(30)		As Integer		' Position horizontal de chaque btns
	BtnWidth(30)	As Integer		' Largeur de chaque btns
	'BtnCaptionWidth(30) As Integer	' Largeur du titre de chaque btn
	BtnCount		As Integer		' Nombre de btn
   PUBLIC:
	ShowGrip		As Integer		' Affiche ou Masque la "Grippe"
	'BtnsSpacing		As Integer		' Espace entre les btns
	'BtnsDistVert	As Integer		' Ditance à partir du Haut
	'BtnsDistHorz	As Integer		' Distance à partir du bas

	'DisableXPTheme		As Integer	' Désactive le Thème XP
	DisableXPThemeBG	As Integer	' Désactive le fond XP
	'SharedBG		As QBitmap		' ...
   PRIVATE:
	GripWidth		As Integer		' Largeur de la "Grippe"
	BtnMenu(30)		As Integer		' Est-ce qu'il y a un Menu pour ce btn
	'OrgFontName		As String
	'OrgFontSize		As Integer
	WidthChanged	As Integer		' Largeur modifiée

	EditCount		As Integer		' Nombre de contrôle Edit
	EditCtrl(4)		As Long
	EditLeft(4)		As Integer
	EditWidth(4)	As Integer
	EditHeight(4)	As Integer
	'EditBG(4)		As QImage
	ComboBoxCount	As Integer		' Nombre de contrôle ComboBox
	ComboBoxCtrl(4)	As Long
	ComboBoxLeft(4)	As Integer
	ComboBoxWidth(4) As Integer
	ComboBoxHeight(4) As Integer
	'ComboBoxBG(4)	As QImage
	'HintSquare		As QImage		' Devrait aider à corriger l'affichage de l'info bulle
   PUBLIC:
	'Height			As Integer PROPERTY SET SetHeight
	'Width			As Integer PROPERTY SET SetWidth

	HideCaption		As Integer PROPERTY SET SetHideCaption	' Masque le titre de la CoolBar
	ItemsWidth		As Integer PROPERTY SET SetItemsWidth	' Dimension des btns de la barre
	Orientation		As Integer PROPERTY SET SetOrientation	' Orientation de la barre (0. Horz, True. Vert)

	OnMouseLeave	AS EVENT(CBarOnMouseLeave_EventTemplate)	' La souris quitte la barre
	OnMouseEnter	AS EVENT(CBarOnMouseEnter_EventTemplate)	' La souris entre et se déplace sur la barre
	OnChange		AS EVENT(CBarOnChange_EventTemplate)		' Un btn est cliqué
	'Nouvelles propriétés
	'qqchose as qqchose Property Set SetQqChose

   PRIVATE:
	Function TextWidth(text as string) As Integer:	Result = .IMGBackGround.TextWidth(text)
	End Function
	Function TextHeight(text as string) As Integer:	Result = .IMGBackGround.TextHeight(text)
	End Function

	SUB mnuItem_Click(Sender As QMenuItem)
		If Sender.Caption <> "-" Then
			If .CoolBtn(Sender.Tag).GroupIndex > True Then _
				.CoolBtn(Sender.Tag).Down = True
			CALLFUNC(.OnChange, Sender.Tag, This)
		End If
	END SUB

   PUBLIC:
	SUBI AddItems (...)
		DIM I AS INTEGER
		.BtnCount = .BtnCount +ParamStrCount	' Devrait être .BtnCount +ParamStrCount
		'ReDim Btn(ParamStrCount -True) As String
		If .ItemsWidth = False Then
			If .Orientation Then
				  .ItemsWidth = .ClientWidth -2 '24
			Else: .ItemsWidth = .ClientHeight -2 '24
			End If
		End If

		ReDim .BtnLeft(.BtnCount -True)		As Integer
		ReDim .BtnWidth(.BtnCount -True)	As Integer
		'ReDim .Btn(.BtnCount -True)			As String 'Plante
		ReDim .ShowBtnCapt(.BtnCount -True)	As Integer
		ReDim .BtnMenu(.BtnCount -True)		As Integer

		.BtnLeft(False) = False		' Devrait être .BtnLeft(.BtnCount -ParamStrCount)
		.BtnWidth(False) = False	' Devrait être .BtnWidth(.BtnCount -ParamStrCount)
		FOR I = True TO ParamStrCount
			.Btn(I -True) = ParamStr$(I)
			.mnuItemExceed(I -True).Caption = ParamStr$(I)
			.mnuItemExceed(I -True).Tag = I -True
			.mnuItemExceed(I -True).OnClick = This.mnuItem_Click
			If ParamStr$(I) = "-" Then
				.BtnWidth(I -True) = 5
			'ElseIf Tally(ParamStr$(I), "EditCtrl") or Tally(ParamStr$(I), "ComboBoxCtrl") Then
			'	.BtnWidth(I -True) = False
			Else
				.BtnWidth(I -True) = .ItemsWidth +_
									 IIf(.ShowBtnCapt(I -True) = True and .Orientation = False, _
										 .TextWidth(ParamStr$(I)) +3, _
										 False)
				.CoolBtn(I -True).GroupIndex = True
				.CoolBtn(I -True).AllowAllUp = True
			End If
		NEXT I
		FOR I = False TO .BtnCount -True
			.BtnLeft(I +True) = .BtnLeft(I) +.BtnWidth(I)
		NEXT I
		'ShowMessage STR$(.BtnLeft(0)) +" /" +STR$(.BtnWidth(0)) +chr$(10) +_
		'			STR$(.BtnLeft(1)) +" /" +STR$(.BtnWidth(1)) +chr$(10) +_
		'			STR$(.BtnLeft(2)) +" /" +STR$(.BtnWidth(2)) +chr$(10) +_
		'			STR$(.BtnLeft(3)) +" /" +STR$(.BtnWidth(3)) +chr$(10) +_
		'			STR$(.BtnLeft(4)) +" /" +STR$(.BtnWidth(4))
		If .Orientation Then _
			.ClientHeight = .BtnLeft(.BtnCount -True) +.BtnWidth(.BtnCount -True) +2 _
		Else _
			.ClientWidth = .BtnLeft(.BtnCount -True) +.BtnWidth(.BtnCount -True) +2
		'.FlickeringFree.Height = .ClientHeight
		'.FlickeringFree.Width = .ClientWidth
	END SUBI
	Sub AddEditCtrl (Sender As QEdit)

		ReDim .EditCtrl(.EditCount +True)	As Long
		ReDim .EditLeft(.EditCount +True)	As Integer
		ReDim .EditWidth(.EditCount +True)	As Integer
		ReDim .EditHeight(.EditCount +True)	As Integer

		Sender.Left = .btnLeft(.BtnCount) +6
		Sender.Top = (This.FlickeringFree.Height -Sender.Height) \2 -True
		Sender.Parent = This.FlickeringFree 'This
		.EditCtrl(.EditCount) = Sender.Handle
		.EditLeft(.EditCount) = Sender.Left
		.EditWidth(.EditCount) = Sender.Width
		.EditHeight(.EditCount) = Sender.Height
		'.EditBG(.EditCount).Enabled = False
		'.EditBG(.EditCount).AutoSize = True
		'.EditBG(.EditCount).Left = Sender.Left
		'.EditBG(.EditCount).Top = Sender.Top
		'.BMPtmp.Width = Sender.Width
		'.BMPtmp.Height = Sender.Height
		'.BMPtmp.FillRect(False, False, .BMPtmp.Width, .BMPtmp.Height, -2147483627)
		'.EditBG(.EditCount).BMP = .BMPtmp.BMP
		'.EditBG(.EditCount).Parent = This.FlickeringFree 'This
		.EditCount ++
	End Sub
	Sub AddComboBoxCtrl (Sender As QComboBox)

		ReDim .ComboBoxCtrl(.ComboBoxCount +True)	As Long
		ReDim .ComboBoxLeft(.ComboBoxCount +True)	As Integer
		ReDim .ComboBoxWidth(.ComboBoxCount +True)	As Integer
		ReDim .ComboBoxHeight(.ComboBoxCount +True)	As Integer

		Sender.Left = .btnLeft(.BtnCount) +5
		Sender.Top = (This.FlickeringFree.Height -Sender.Height +6) \2 -True
		Sender.Parent = This.FlickeringFree 'This
		.ComboBoxCtrl(.ComboBoxCount) = Sender.Handle
		.ComboBoxLeft(.ComboBoxCount) = Sender.Left
		.ComboBoxWidth(.ComboBoxCount) = Sender.Width
		.ComboBoxHeight(.ComboBoxCount) = Sender.Height
		'.ComboBoxBG(.ComboBoxCount).Enabled = False
		'.ComboBoxBG(.ComboBoxCount).AutoSize = True
		'.ComboBoxBG(.ComboBoxCount).Left = Sender.Left
		'.ComboBoxBG(.ComboBoxCount).Top = Sender.Top
		'.BMPtmp.Width = Sender.Width
		'.BMPtmp.Height = Sender.Height
		'.BMPtmp.FillRect(False, False, .BMPtmp.Width, .BMPtmp.Height, -2147483627)
		'.ComboBoxBG(.ComboBoxCount).BMP = .BMPtmp.BMP
		'.ComboBoxBG(.ComboBoxCount).Parent = This.FlickeringFree 'This
		.ComboBoxCount ++
	End Sub

	SUBI DefineBtnsGroup (...)
		'... = ParamValCount
		Dim I As Integer
		Dim modSepState As Integer
			modSepState = False
		Dim Index As Integer
			Index = IIf(ParamVal(True) = False, True, False)

		If ParamValCount = True Then
			If (ParamVal(True) <= False) Then
				For I = False To .BtnCount -True
					If .Btn(I) <> "-" Then
						.CoolBtn(I).GroupIndex = True
						.CoolBtn(I).AllowAllUp = True
					End If
				Next I
			Else
				For I = False To .BtnCount -True
					If .Btn(I) <> "-" Then
						.CoolBtn(I).GroupIndex = ParamVal(True) +Index +True
						.CoolBtn(I).AllowAllUp = False
					End If
				Next I
			End If
		ElseIf ParamValCount > True Then
			For I = 2 To ParamValCount
				If .Btn(ParamVal(I)) <> "-" Then
					.CoolBtn(ParamVal(I)).GroupIndex = ParamVal(True) +Index +True
					.CoolBtn(ParamVal(I)).AllowAllUp = False 'True
				Else
					modSepState ++
				End If
			Next I
		Else
			ShowMessage "Erreur: paramètre(s) manquant(s) ou incorrect(s)"
		End If
		If modSepState Then _
			ShowMessage "Avertissement: vous tentez de redéfinir le " +CHR$(10) +_
						"               groupe d'un séparateur..."
	END SUBI
	SUBI InitBtnsDownUp (...)
		'... = ParamValCount
		Dim I As Integer
		Dim modSepState As Integer
			modSepState = False
		Dim Index As Integer
			Index = IIf(ParamVal(True) = False, True, False)

		If ParamValCount = True and (ParamVal(True) = False or ParamVal(True) = True) Then
			For I = False To .BtnCount -True
				If .Btn(I) <> "-" Then _
					.CoolBtn(I).Down = ParamVal(True)
			Next I
		ElseIf ParamValCount > True and (ParamVal(True) = False or ParamVal(True) = True) Then
			For I = 2 To ParamValCount
				If .Btn(ParamVal(I)) <> "-" Then
					.CoolBtn(ParamVal(I)).Down = ParamVal(True)
				Else
					modSepState ++
				End If
			Next I
		Else
			ShowMessage "Erreur: paramètre(s) manquant(s) ou incorrect(s)"
		End If
		If modSepState Then _
			ShowMessage "Avertissement: vous tentez de modifier l'état " +CHR$(10) +_
						"               enfoncé d'un séparateur..."
	END SUBI

	SUBI EnableBtns (...)
		'... = ParamValCount
		Dim I As Integer
		Dim modSepState As Integer
		modSepState = False
		If ParamValCount = True and (ParamVal(True) = False or ParamVal(True) = True) Then
			For I = False To .BtnCount -True
				If .Btn(I) <> "-" Then _
					.CoolBtn(I).Enabled = ParamVal(True)
			Next I
		ElseIf ParamValCount > True Then
			For I = 2 To ParamValCount
				If .Btn(ParamVal(I)) <> "-" Then
					.CoolBtn(ParamVal(I)).Enabled = ParamVal(True)
				Else
					modSepState ++
				End If
			Next I
		Else
			ShowMessage "Erreur: paramètre(s) manquant(s) ou incorrect(s)"
		End If
		If modSepState Then _
			ShowMessage "Avertissement: vous tentez de modifier l'état " +CHR$(10) +_
						"               active/inactive d'un séparateur..."
	END SUBI
	SUBI ShowBtnsCaption (...)
		'... = ParamValCount
		Dim I As Integer
		Dim modSepState As Integer
		modSepState = False
		If ParamValCount = True and (ParamVal(True) = False or ParamVal(True) = True) Then
			For I = False To .BtnCount -True
				If .Btn(I) <> "-" Then _
					.ShowBtnCapt(I) = ParamVal(True)
			Next I
		ElseIf ParamValCount > True Then
			For I = 2 To ParamValCount
				If .Btn(ParamVal(I)) <> "-" Then
					.ShowBtnCapt(ParamVal(I)) = ParamVal(True)
				Else
					modSepState ++
				End If
			Next I
		Else
			ShowMessage "Erreur: paramètre(s) manquant(s) ou incorrect(s)"
		End If
		If modSepState Then _
			ShowMessage "Avertissement: vous tentez de modifier " +CHR$(10) +_
						"               un séparateur..."
	END SUBI
   PRIVATE:
	'Sub FixBtnSize
	'	If .Align <> False Then Exit Sub'!-- 22/08
	'	dim height as integer, width as integer
	'	height = super.height: width = super.width

	'	.height = height: .width = width
	'	.FlickeringFree.Height = height
	'	.FlickeringFree.Width = Width
	'End Sub
	Sub ShapeBar(Sender As QPanel)
		Dim hRgn As Long, _
			hRgn2 As Long
		Dim hDC As Long
		Dim I As Integer
		' Clean previouse rgn
		SetWindowRgn_QCBar Sender.Handle, False, True
		'hDC = GetDC_QTBtn(Sender.Handle)
		'destroy the previous region
		DeleteObject_QCBar hRgn
		DeleteObject_QCBar hRgn2
		'create an elliptic region
		If .Orientation Then
			hRgn = CreateRectRgn_QCBar(False, False, False, False)
			If .ShowGrip = True Then
				hRgn2 = CreateRectRgn_QCBar(True, True, Sender.Width, .GripWidth)
				CombineRgn_QCBar hRgn, hRgn, hRgn2, RGN_XOR_QCBar
				DeleteObject_QCBar hRgn2
			End If
			'If .ShowGrip = True Then _
			For I = False To .BtnCount -True
				hRgn2 = CreateRectRgn_QCBar(True, .BtnLeft(I), Sender.Width -True, .BtnLeft(I) +.BtnWidth(I))
				'Combine our two regions
				CombineRgn_QCBar hRgn, hRgn, hRgn2, RGN_XOR_QCBar
				DeleteObject_QCBar hRgn2
			Next I
		Else
			hRgn = CreateRectRgn_QCBar(False, False, False, False)
			If .ShowGrip = True Then
				hRgn2 = CreateRectRgn_QCBar ( True, _
										True, _
										.GripWidth, _
										Sender.Height -True)
				CombineRgn_QCBar hRgn, hRgn, hRgn2, RGN_XOR_QCBar
				DeleteObject_QCBar hRgn2
			End If
			If .HideCaption = False Then
				hRgn2 = CreateRectRgn_QCBar ( .GripWidth, _
										.CaptionHeight, _
										.GripWidth +.CaptionWidth, _
										This.ClientHeight -.CaptionHeight)
				CombineRgn_QCBar hRgn, hRgn, hRgn2, RGN_XOR_QCBar
				DeleteObject_QCBar hRgn2
			End If
			For I = False To .BtnCount -True
				hRgn2 = CreateRectRgn_QCBar(.BtnLeft(I), False, .BtnLeft(I) +.BtnWidth(I), Sender.Height)
				'Combine our two regions
				CombineRgn_QCBar hRgn, hRgn, hRgn2, RGN_XOR_QCBar
				DeleteObject_QCBar hRgn2
			Next I
			If .EditCount Then
				For I = False To .EditCount -True
					'If .EditTop(I) > Sender.ClientHeight -.EditHeight(I) Then _
						'hRgn2 = CreateRectRgn ( .EditLeft(I) +IIf(isXP_QTBtn, False, True), _
						'						(Sender.ClientHeight \2) -(.EditHeight(I) \2) -True +IIf(isXP_QTBtn, False, True), _
						'						.EditLeft(I) +.EditWidth(I) -IIf(isXP_QTBtn, False, True), _
						'						(Sender.ClientHeight \2) +(.EditHeight(I) \2) -IIf(isXP_QTBtn, False, True))
						hRgn2 = CreateRectRgn_QCBar ( .EditLeft(I), _
												(Sender.Height \2) -(.EditHeight(I) \2) -True, _
												.EditLeft(I) +.EditWidth(I), _
												(Sender.Height \2) +(.EditHeight(I) \2) +True)
						'Combine our two regions
						CombineRgn_QCBar hRgn, hRgn, hRgn2, RGN_XOR_QCBar
						DeleteObject_QCBar hRgn2
					'End If
				Next I
			End If
			If .ComboBoxCount Then
				For I = False To .ComboBoxCount -True
					'If .EditTop(I) > Sender.ClientHeight -.ComboBoxHeight(I) Then _
						'hRgn2 = CreateRectRgn ( .ComboBoxLeft(I) +IIf(isXP_QTBtn, False, True), _
						'						(Sender.ClientHeight \2) -(.ComboBoxHeight(I) \2) -True +IIf(isXP_QTBtn, False, True), _
						'						.ComboBoxLeft(I) +.ComboBoxWidth(I) -IIf(isXP_QTBtn, False, True), _
						'						(Sender.ClientHeight \2) +(.ComboBoxHeight(I) \2) -IIf(isXP_QTBtn, False, True))
						hRgn2 = CreateRectRgn_QCBar ( .ComboBoxLeft(I), _
												(Sender.Height \2) -(.ComboBoxHeight(I) \2) -True, _
												.ComboBoxLeft(I) +.ComboBoxWidth(I), _
												(Sender.Height \2) +(.ComboBoxHeight(I) \2) +True)
						'Combine our two regions
						CombineRgn_QCBar hRgn, hRgn, hRgn2, RGN_XOR_QCBar
						DeleteObject_QCBar hRgn2
					'End If
				Next I
			End If
		End If
		'OffsetRgn hRgn, 10, 10
		'SelectClipRgn hDC, hRgn
		'move the clipping region
		'OffsetClipRgn hDC, 10, 10
		'set the new window region
		'SetWindowRgn Me.Handle, Ret, True
		SetWindowRgn_QCBar Sender.Handle, hRgn, True
		'clean up
		DeleteObject_QCBar hRgn
		DeleteObject_QCBar hRgn2
		'ReleaseDC_QTBtn (Sender.Handle, hDC)
		'DeleteDC_QTBtn hDC
		'Reset rgn address to 0
		'hRgn = 0
		End Sub

   PUBLIC:
	Sub RePaint
		Dim btnStandSet As Integer, _
			btnMenuSet As Integer
		Dim I As Integer, _
			J As Integer
		Dim R As RECT_QTBtn
		'Dim btnWidth As Integer
		Dim curLeft As Integer
		'btnWidth = (This.ClientWidth -2) /.BtnCount

		static wasgripped as integer
		If .ShowGrip = True Then
			If wasgripped = False Then 'or .WidthChanged = True Then
				FOR I = False To .BtnCount' -True
					INC(.BtnLeft(I), IIf(.Orientation, 8, 5))
				NEXT I
			End If
			wasgripped = True
		Else
			If wasgripped = True Then 'or .WidthChanged = True Then
				FOR I = False To .BtnCount' -True
					DEC(.BtnLeft(I), IIf(.Orientation, 8, 5))
				NEXT I
			End If
			.GripWidth = False
			wasgripped = False
		End If
		static wascaptioned as integer
		If .HideCaption = False Then
			.CaptionHeight = (.ClientHeight -.TextHeight(.Caption)) \2
			.CaptionWidth = .TextWidth(.Caption) +5
			'.IMGBackGround.FillRect ( False, False, 5, .ClientHeight -2, clBtnFace )
			'FOR I = 2 TO (.ClientHeight -5) STEP 3
			'	.IMGBackGround.Line	 ( 1, I, 3, I, clBtnShadow )
			'NEXT I
			If wascaptioned = False Then 'or .WidthChanged = True Then
				FOR I = False To .BtnCount
					INC(.BtnLeft(I), .CaptionWidth)
				NEXT I
			End If
			wascaptioned = True
		Else
			.CaptionHeight = False
			.CaptionWidth = False
			If wascaptioned = True Then 'or .WidthChanged = True Then
				FOR I = False To .BtnCount -True
					DEC(.BtnLeft(I), .CaptionWidth)
				NEXT I
			End If
			.CaptionWidth = False
			wascaptioned = False
		End If
		Static MenuCount As Integer
		'MenuCount = False
		If MenuCount = False Then
			FOR I = False To .BtnCount ' -True
				If MenuCount > False Then _
					.BtnLeft(I) = .BtnLeft(I) +(MenuCount *8)
				If GetMenuItemCount_QCBar (This.mnuPopup(I).Handle) > False Then
					MenuCount ++
					.BtnMenu(I) = True
					.BtnWidth(I) = .BtnWidth(I) +8
					.mnuPopup(I).Alignment = True
					'.BtnLeft(I +True) = .BtnLeft(I +True) +(MenuCount *8)
					'ShowMessage "Button X got a menu!"' +STR$()
				Else
					.BtnMenu(I) = False
				End If
			NEXT I
		End If
		If .Orientation Then
			.ClientHeight = .BtnLeft(.BtnCount -True) +.BtnWidth(.BtnCount -True) +3
			.FlickeringFree.Width	= .Width -(.BevelWidth *2) '.ClientWidth
			.FlickeringFree.Height	= .BtnLeft(.BtnCount -True) +.BtnWidth(.BtnCount -True) +3
		Else
			.ClientWidth = .BtnLeft(.BtnCount -True) +.BtnWidth(.BtnCount -True) +3 _
							+IIf(.EditCount > False, .EditLeft(.EditCount -True) +.EditWidth(.EditCount -True), False) + _
							+IIf(.ComboBoxCount > False, .ComboBoxLeft(.ComboBoxCount -True) +.ComboBoxWidth(.ComboBoxCount -True), False)
			.FlickeringFree.Width	= .BtnLeft(.BtnCount -True) +.BtnWidth(.BtnCount -True) +3 _
										+IIf(.EditCount > False, .EditLeft(.EditCount -True) +.EditWidth(.EditCount -True), False) + _
										+IIf(.ComboBoxCount > False, .ComboBoxLeft(.ComboBoxCount -True) +.ComboBoxWidth(.ComboBoxCount -True), False)
			.FlickeringFree.Height	= .Height -(.BevelWidth *2) '.ClientHeight
		End If
		
		'.FlickeringFree.Height = .ClientHeight
		'.FlickeringFree.Width = .ClientWidth
		.IMGBackGround.Font.Color		= .Font.Color
		.IMGBackGround.Font.Name		= .Font.Name
		.IMGBackGround.Font.Size		= .Font.Size
		.IMGBackGround.Font.Bold		= .Font.Bold
		.IMGBackGround.Font.Italic		= .Font.Italic
		.IMGBackGround.Font.Underline	= .Font.Underline
		.IMGStretchedBackGround.Stretch	= False

		.IMGBackGroundFix.Width			= .FlickeringFree.Width 'IMGBackGround.Width
		.IMGBackGroundFix.Height		= .FlickeringFree.Height '.IMGBackGround.Height
		.IMGBackGroundFix.FillRect		(False, False, .IMGBackGroundFix.Width, .IMGBackGroundFix.Height, _
										 This.Color) 'clBtnFace)
		.IMGBackGround.Transparent = False
		.IMGBackGround.BMP				= .IMGBackGroundFix.BMP

		If isXP_QTBtn Then
			If .DisableXPThemeBG = False Then _
				.IMGStretchedBackGround2.BMP	= .IMGBackGroundFix.BMP
			If .Orientation Then _
				.IMGBackGroundFix.Height	= Screen.Height -.Top -20 _
			Else _
				.IMGBackGroundFix.Width		= Screen.Width -.Left
			.IMGBackGroundFix.FillRect( False, False, _
										.IMGBackGroundFix.Width, .IMGBackGroundFix.Height, _
										This.Color) 'clBtnFace)
			If .DisableXPThemeBG = False Then _
				.IMGStretchedBackGround.BMP	= .IMGBackGroundFix.BMP
			'.IMGStretchedBackGround.Width = Screen.Width
			' Ajouté 13fév
			.IMGBackGroundFix.Width		= .FlickeringFree.Width
			.IMGBackGroundFix.Height	= .FlickeringFree.Height
		Else
			.IMGStretchedBackGround.Visible = False
			.IMGStretchedBackGround2.Visible = False
		End If

		If isXP_QTBtn and .DisableXPThemeBG = False Then
			'If .SharedBG.Empty = False Then
			'	'.IMGStretchedBackGround.Width = This.SharedBG.Width -(This.SharedBG.Width \5) '.SharedBG.Width
			'	WITH Dest: .Left = False: .Right  = This.IMGStretchedBackGround.Width 'This.ClientWidth
			'			   .Top  = False: .Bottom = This.ClientHeight
			'	END WITH
			'	WITH Src: .Left = This.SharedBG.Width -(This.SharedBG.Width \4) '.Left
			'			.Right  = This.Left +This.SharedBG.Width
			'			  .Top	= This.Top:  .Bottom = This.Top +This.Height +2 '+True
			'	END WITH
			'	.IMGStretchedBackGround.CopyRect(This.Dest, This.SharedBG, This.Src)
			'	.Dest.Right = This.ClientWidth
			'	.Src.Left = .Left
			'	.IMGStretchedBackGround2.CopyRect(This.Dest, This.SharedBG, This.Src)
			'Else
				XPPart ( _
						 xpt_ReBar, _
						 6, _
						 This.Orientation, _
						 True, _
						 This.Color, _
						 This.IMGStretchedBackGround, _
						 This.Handle)
				XPPart ( _
						 xpt_ReBar, _
						 6, _
						 This.Orientation, _
						 True, _
						 This.Color, _
						 This.IMGStretchedBackGround2, _
						 This.Handle)
			'End If
			.IMGStretchedBackGround.Visible = True
			.IMGStretchedBackGround2.Visible = True
			.IMGStretchedBackGround.Stretch = True
		End If
		'.BtnsHotTrack.Width = This.ClientWidth -2
		'.BtnsHotTrack.Height = This.ClientHeight -2

		'static wasgripped as integer
		If .ShowGrip = True Then
			.GripWidth = IIf(.Orientation, 8, 5)
			'.IMGBackGround.FillRect ( False, False, IIf(.Orientation, 8, 5), .ClientHeight -2, clBtnFace )
			If isXP_QTBtn Then
				XPPart ( xpt_ReBar, _
						 True, _
						 This.Orientation, _
						 This.DisableXPThemeBG, _
						 This.Color, _
						 This.IMGBackGround, _
						 This.Handle)
			Else
				If .Orientation Then
					FOR I = 2 TO (.ClientWidth -5) STEP 3
						.IMGBackGround.Line	 ( I, True, I, 3, -2147483632 ) 'clBtnShadow
					NEXT I
				Else
					FOR I = 2 TO (.ClientHeight -IIf(.Orientation, 8, 5)) STEP 3
						.IMGBackGround.Line	 ( True, I, 3, I, -2147483632 ) 'clBtnShadow
					NEXT I
				End If
			End If
		'	If wasgripped = False Then 'or .WidthChanged = True Then
		'		FOR I = False To .BtnCount' -True
		'			INC(.BtnLeft(I), IIf(.Orientation, 8, 5))
		'		NEXT I
		'	End If
		'	wasgripped = True
		'Else
		'	If wasgripped = True Then 'or .WidthChanged = True Then
		'		FOR I = False To .BtnCount' -True
		'			DEC(.BtnLeft(I), IIf(.Orientation, 8, 5))
		'		NEXT I
		'	End If
		'	.GripWidth = False
		'	wasgripped = False
		End If

		curLeft = False
		Dim sepBefore As Integer
			sepBefore = False
		For I = False To .BtnCount -True

			'If I > False Then _
			'	curLeft = curLeft +.BtnWidth(I)
			If .btn(I) <> "-" Then
				.CoolBtn(I).Visible = False
				.CoolBtn(I).Parent = This.FlickeringFree 'this
				.CoolBtn(I).Width = .btnwidth(I)
				.CoolBtn(I).Height = .ItemsWidth -2 'This.ClientHeight -2
				.ImgBtnHot(I).Visible = False
				.ImgBtnHot(I).Enabled = False
				.ImgBtnHot(I).Parent = This.FlickeringFree 'this
				.ImgBtnHot(I).Width = .btnwidth(I) 'This.ClientWidth -2
				.ImgBtnHot(I).Height = .ItemsWidth -2 '.btnwidth(I)
				If .Orientation Then
					.CoolBtn(I).Left = True
					.CoolBtn(I).Top = .btnleft(I)
					'.CoolBtn(I).Width = .btnwidth(I) 'This.ClientWidth -2
					'.CoolBtn(I).Height = .ItemsWidth -2 '.btnwidth(I)
					.ImgBtnHot(I).Left = True
					.ImgBtnHot(I).Top = .btnleft(I)
					'.ImgBtnHot(I).Width = .btnwidth(I) 'This.ClientWidth -2
					'.ImgBtnHot(I).Height = .ItemsWidth -2 '.btnwidth(I)
				Else
					.CoolBtn(I).Left = .btnleft(I)
					.CoolBtn(I).Top = IIf(.BevelWidth, False, True)
					'.CoolBtn(I).Width = .btnwidth(I)
					'.CoolBtn(I).Height = .ItemsWidth -2 'This.ClientHeight -2
					.ImgBtnHot(I).Left = .btnleft(I)
					.ImgBtnHot(I).Top = IIf(.BevelWidth, False, True)
					'.ImgBtnHot(I).Width = .btnwidth(I)
					'.ImgBtnHot(I).Height = .ItemsWidth -2 'This.ClientHeight -2
				End If
				.CoolBtn(I).Flat = True
				'.CoolBtn(I).GroupIndex = True
				'.CoolBtn(I).AllowAllUp = True
				.CoolBtn(I).NumBMPs = maxNumBMPs_QCBar
				.CoolBtn(I).Spacing = False
				If .CoolBtn(I).Caption = "" Then _
					.CoolBtn(I).Layout = False _
				Else _
					.CoolBtn(I).Layout = 3

				If isXP_QTBtn = False Then
					.CoolBtnBMP.Width = ((.btnwidth(I) +3) *maxNumBMPs_QCBar) +2
					.CoolBtnBMP.Height = .btnwidth(I) +True
					.CoolBtnBMP.FillRect(False, False, .CoolBtnBMP.Width, .CoolBtnBMP.Height, clBtnFace)
				Else
					.CoolBtnBMP.Width = .btnwidth(I)
					.CoolBtnBMP.Height = .ItemsWidth -2 '((.btnwidth(I) -IIf(.BtnMenu(I), 8, False)) -2) 'This.ClientHeight -2

					Fast_QCBarToQTBtn( xpt_ToolBarBtn, _
									   True, _
									   This.CoolBtnBMP, _
									   "", _
									   This.BtnMenu(I), _
									   IIf(This.CoolBtn(I).GroupIndex > True, 2, False), _
									   This.Handle)
				End If

'				If Style = 2 Then
'					'Style2
'					.IMGBackGround.Rectangle(.btnLeft(I), _
'									 False, _
'									 .btnLeft(I +True), _
'									 This.ClientHeight -2, _
'									 clBtnShadow)
'					.IMGBackGround.FillRect(.btnLeft(I) +True, _
'									True, _
'									.btnLeft(I +True) -True, _
'									This.ClientHeight -3, _
'									clActiveBorder)
'				End If
				'If Style < 2 Then
				'	'SetRect_QCBar R, .btnLeft(I), False, .btnLeft(I +True), This.Height -2
				'	'If Style = True Then
				'	'	'Style1
				'	'	DrawEdge_QCBar .IMGBackGround.Handle, R, BDR_RAISEDINNER, BF_RECT_QCBar OR BF_FLAT_QCBar 'BDR_SUNKENOUTER_QCBar, BF_RECT_QCBar '
				'	'Else
				'	'	DrawEdge_QCBar .IMGBackGround.Handle, R, BDR_RAISEDINNER, BF_RECT_QCBar 'BDR_SUNKENOUTER_QCBar, BF_RECT_QCBar '
				'	'End If
				'ElseIf Style = 2 Then
'				If Style = 2 Then
'					'Style2
'					.IMGBackGround.FillRect(.btnLeft(I), _
'									False, _
'									.btnLeft(I +True), _
'									This.ClientHeight -2, _
'									clBtnFace)
'				End If
'				If Style = 3 Then
'					If btnStandSet = False Then 'and .IMGSkin.Empty = False Then
'						.Bitmap2.BMP = .IMGSkin.BMP
'						BMPStretch2_Property (.btnWidth(I), .ClientHeight -2, This.Bitmap2)
'						'.Bitmap2.SaveToFile("C:\RapidQ\Temp\testbtnbmp.bmp")
'						
'						btnStandSet = True
'						.IMGBackGround.Draw(.btnLeft(I), _
'									False, _
'									This.Bitmap2.BMP)
'					End If
'				End If
				.imgLBK.Width	= .imgLA.Width
				.imgLBK.Height	= .imgLA.Height
'				.IMGBackGround.Draw(((.BtnWidth(I) -IIf(.BtnMenu(I) = True, 8, False) -.imgLBK.Width) \2) +.btnLeft(I), _
'							(This.ClientHeight -2 -.imgLBK.Height) \2, _
'							.imgLBK.BMP) '.imgLA.GetBMP(I -sepBefore)) 'Bitmap2.BMP)

				'.CoolBtnBMP.BMP = .CoolBtn(I).BMP
				'.CoolBtnBMP.Draw(((.BtnWidth(I) -IIf(.BtnMenu(I) = True, 8, False) -.imgLBK.Width) \2) +True, _
				'			((This.ClientHeight -2 -.imgLBK.Height) \2) +True , _
				'			.imgLBK.BMP) '.imgLA.GetBMP(I -sepBefore)) 'Bitmap2.BMP)

				Dim Left As Integer
					Left = False
				For J = False To 3
					If (I -True =< .imgLA.Count) Then
						If J = False or _
							(J = True and (I +True > .imgLD.Count)) or _
							(J = 2 and (I +True > .imgLS.Count)) or _
							(J = 3 and (I +True > .imgLS.Count)) Then
							.imgLBK.BMP	= .imgLA.GetBMP(I -sepBefore)
						ElseIf J = True Then
							.imgLBK.BMP	= .imgLD.GetBMP(I -sepBefore)
						ElseIf J = 2 Then
							.imgLBK.BMP	= .imgLS.GetBMP(I -sepBefore)
						ElseIf J = 3 Then
							.imgLBK.BMP	= .imgLS.GetBMP(I -sepBefore)
						End If

						.imgLBK.TransparentColor = .imgLBK.Pixel(False, False) 'clWhite
						.imgLBK.Transparent = True

						If .ShowBtnCapt(I) = True and .Btn(I) <> "" Then
							Left = J *(.CoolBtnBMP.Width \5) +3
						Else
							Left = J *(.CoolBtnBMP.Width \5) -IIf(.BtnMenu(I), 6, False) _
											+(((.CoolBtnBMP.Width \5) -.imgLBK.Width) \2)
						End If

						.CoolBtnBMP.Draw( _
										  Left, _
										  ((This.CoolBtnBMP.Height -.imgLBK.Height) \2), _
										  .imgLBK.BMP) '.imgLA.GetBMP(I -sepBefore)) 'Bitmap2.BMP)
					End If
					If isXP_QTBtn = False and .BtnMenu(I) Then
						DrawMyText( _
									((J +True) *(This.CoolBtnBMP.Width \5)) -14, _
									False, _
									((J +True) *(This.CoolBtnBMP.Width \5)), _
									This.CoolBtnBMP.Height -True -IIf(.ShowBtnCapt(I) = True, True, False), _
									"6", _
									"Marlett", _
									IIf(.CoolBtn(I).Enabled, -2147483630, -2147483631), _
									This.CoolBtnBMP)
					End If
				Next J
				If .ShowBtnCapt(I) = True and .Btn(I) <> "" Then
					For J = False To 4 'step 2
						'SetTextColor This.CoolBtnBMP.Handle, clGrayText
						If .CoolBtn(I).Enabled = False Then
							DrawMyText( _
										((This.CoolBtnBMP.Width \5) *J) +2, _
										2, _
										(This.CoolBtnBMP.Width \5) *(J +True) -IIf(.BtnMenu(I), 12, False) +True, _
										This.CoolBtnBMP.Height, _
										This.Btn(I), _
										"", _
										-2147483628, _
										This.CoolBtnBMP)
						End If

						DrawMyText( _
									((This.CoolBtnBMP.Width \5) *J) +.imgLBK.Width +4, _
									True, _
									(This.CoolBtnBMP.Width \5) *(J +True) -IIf(.BtnMenu(I), 12, False), _
									This.CoolBtnBMP.Height -True, _
									This.Btn(I), _
									"", _
									IIf(J <> True and .CoolBtn(I).Enabled, -2147483630, -2147483631), _
									This.CoolBtnBMP)
					Next J
				End If

				'.BMPtmp.BMP = .CoolBtnBMP.BMP
				WITH Dest: .Left = False: .Right = This.CoolBtn(I).Width
							.Top = False: .Bottom = This.CoolBtnBMP.Height
				END WITH
				WITH Src: .Left = ((This.CoolBtn(I).Width +3) *4) +True
							 .Right = .Left +This.CoolBtn(I).Width
							  .Top = True: .Bottom = This.CoolBtnBMP.Height +True
				END WITH
				.BMPtmp.Width = .Dest.Right: .BMPtmp.Height = .Dest.Bottom
				If isXP_QTBtn Then
					.BMPtmp.CopyRect(This.Dest, This.CoolBtnBMP, This.Src)
				Else
					' Style2
					.BMPtmp.Rectangle( False, _
									   False, _
									   .btnWidth(I), _
									   .ItemsWidth -2, _
									   -2147483632) 'clBtnShadow
					.BMPtmp.FillRect( True, _
									  True, _
									  .btnWidth(I) -True, _
									  .ItemsWidth -3, _
									  -2147483638) 'clActiveBorder
					If .ShowBtnCapt(I) = True and .Btn(I) <> "" Then
						'SetTextColor This.CoolBtnBMP.Handle, clGrayText
						If .CoolBtn(I).Enabled = False Then
							DrawMyText( _
										2, _
										2, _
										This.BMPtmp.Width -IIf(.BtnMenu(I), 12, False) +True, _
										This.ItemsWidth, _
										This.Btn(I), _
										"", _
										-2147483628, _
										This.BMPtmp)
						End If

						DrawMyText( _
									.imgLBK.Width +3, _
									True, _
									This.BMPtmp.Width -IIf(.BtnMenu(I), 12, False), _
									This.ItemsWidth -True, _
									This.Btn(I), _
									"", _
									IIf(J <> True and .CoolBtn(I).Enabled, -2147483630, -2147483631), _
									This.BMPtmp)
					End If
					If .BtnMenu(I) Then
						DrawMyText( _
									.btnWidth(I) -12, _
									False, _
									.btnWidth(I), _
									(.ItemsWidth /2) +9, _
									"6", _
									"Marlett", _
									IIf(.CoolBtn(I).Enabled, -2147483630, -2147483631), _
									This.BMPtmp)
					End If
				End If
				If (I -True =< .imgLA.Count) Then
					If (I +True > .imgLH.Count) Then
						.imgLBK.BMP	= .imgLA.GetBMP(I -sepBefore)
					Else
						.imgLBK.BMP	= .imgLH.GetBMP(I -sepBefore)
					End If

					.imgLBK.TransparentColor = .imgLBK.Pixel(False, False) 'clWhite
					.imgLBK.Transparent = True

					If .ShowBtnCapt(I) = True and .Btn(I) <> "" Then
						Left = 2
					Else
						Left = (.BtnWidth(I) -IIf(.BtnMenu(I) = True, 12, False) -.imgLBK.Width) \2
					End If
					.BMPtmp.Draw(Left, _
								 ((.ItemsWidth -2 -.imgLBK.Height) \2) , _
								 .imgLBK.BMP)
				End If
				
				.BMPtmp.PixelFormat = pf15bit
				'.BMPtmp.Pixel(False, False) = .BMPtmp.Pixel(False, .BMPtmp.Height -1)
				.BMPtmp.Transparent = True
				.BMPtmp.TransparentColor = .BMPtmp.Pixel(False, False) 'clWhite
				.ImgBtnHot(I).BMP = .BMPtmp.BMP
				'.ImgBtnHot(I).Draw(False, _
				'			 False, _
				'			.BMPtmp.BMP)
				If isXP_QTBtn Then _
					.ImgBtnHot(I).Transparent = True _
				Else _
					.ImgBtnHot(I).Transparent = False

				.CoolBtnBMP.Width = ((.CoolBtn(I).Width +3) *4) +True
				.CoolBtn(I).BMP = .CoolBtnBMP.BMP

				'Dim hCursor As Long
				'load the 'Size-All' cursos
				'$TypeCheck Off
				'hCursor = LoadCursor(ByVal 0&, 32753)
				'DrawIcon(IMGBackGround1.Hanlde, 0, 0, GetCursor)
				'$TypeCheck On
				'DestroyCursor (hCursor)
'				If .BtnMenu(I) Then
'					If Style = False Then
'						.IMGBackGround.FillRect(.btnLeft(I +True) -12, _
'										True, _
'										.btnLeft(I) +.btnWidth(I) -True, _
'										This.ClientHeight -3, _
'										clWhite)
'					End If
'					If Style = 3 Then
'						If btnMenuSet = False and .IMGSkin.Empty = False Then
'							.Bitmap3.BMP = .IMGSkin.BMP
'							BMPStretch2_Property (.btnWidth(I), .ClientHeight -2, This.Bitmap3)
'							btnMenuSet = True
'							'.Bitmap3.SaveToFile("C:\RapidQ\Temp\testbtnbmp.bmp")
'
'							.IMGBackGround.Draw(.btnLeft(I), _
'									False, _
'									This.Bitmap3.BMP)
'						End If
'					End If
'					.IMGBackGround.Font.Name = "Marlett"
'					.IMGBackGround.TextOut( .BtnLeft(I +True) -12, _
'									5, _
'									"6", .Font.Color, -True )
'					.IMGBackGround.Font.Name = .Font.Name
'				End If

'				If Style = False Then
'					'Style1
'					SetRect_QCBar R, .btnLeft(I), False, .btnLeft(I +True), This.ClientHeight -2
'					DrawEdge_QCBar .IMGBackGround.Handle, R, BDR_RAISEDINNER, BF_RECT_QCBar 'OR BF_FLAT_QCBar ''BDR_SUNKENOUTER_QCBar, BF_RECT_QCBar '
'				End If
				.CoolBtn(I).Visible = True
			Else
				If .Orientation Then
					SetRect_QCBar ( R, _
									False +IIf(.BevelWidth = False, 2, False), _
									.btnLeft(I) +True, _
									This.ClientWidth -3, _
									.btnLeft(I) +IIf(Style < 2 or isXP_QTBtn = False, 3, 2))
				Else
					SetRect_QCBar ( R, _
									.btnLeft(I) +True, _
									2, _
									.btnLeft(I) +IIf(Style < 2 or isXP_QTBtn = False, 3, 2), _
									This.Height -3)
				End If
				DrawEdge_QCBar .IMGBackGround.Handle, R, BDR_SUNKENOUTER_QCBar, BF_RECT_QCBar 'BDR_SUNKENOUTER_QCBar, BF_RECT_QCBar '
				sepBefore ++

			End If
		Next I
		If wascaptioned = True Then 'or .WidthChanged = True Then _
			.IMGBackGround.TextOut(.GripWidth +2, .CaptionHeight, .Caption, .Font.Color, -True)
		End If
		.WidthChanged = False
		'If .Orientation Then
		'	.ClientHeight = .BtnLeft(.BtnCount -True) +.BtnWidth(.BtnCount -True) +3
		'	.FlickeringFree.Width	= .ClientWidth
		'Else
		'	.ClientWidth = .BtnLeft(.BtnCount -True) +.BtnWidth(.BtnCount -True) +3 _
		'					+IIf(.EditCount > False, .EditLeft(.EditCount -True) +.EditWidth(.EditCount -True), False) + _
		'					+IIf(.ComboBoxCount > False, .ComboBoxLeft(.ComboBoxCount -True) +.ComboBoxWidth(.ComboBoxCount -True), False)
		'	.FlickeringFree.Width	= .BtnLeft(.BtnCount -True) +.BtnWidth(.BtnCount -True) +3 _
		'								+IIf(.EditCount > False, .EditLeft(.EditCount -True) +.EditWidth(.EditCount -True), False) + _
		'								+IIf(.ComboBoxCount > False, .ComboBoxLeft(.ComboBoxCount -True) +.ComboBoxWidth(.ComboBoxCount -True), False)
		'End If
		'.FlickeringFree.Height	= .ClientHeight
		''.FlickeringFree.Width	= .ClientWidth
		.BtnsHotTrack.Parent = This '.DummyPanel
		.BtnsHotTrack.Parent = This.FlickeringFree 'This
		.IMGBackGround.Transparent = True
		'SetWindowPos ( _
		'			   This.BtnsHotTrack.Handle, _
		'			   HWND_TOP, _
		'			   False, _
		'			   False, _
		'			   False, _
		'			   False, _
		'			   SWP_NOMOVE Or SWP_NOSIZE)

		If .Orientation Then
			.PnlExceed.Align = 2
			.PnlExceed.Top = This.Height -12
			.PnlExceed.Width = This.ClientWidth
			.PnlExceed.Height = 12
			'.CBtnExceed.Align = 1
			.CBtnExceed.Height = 12
			.CBtnExceed.Width = This.PnlExceed.ClientWidth
			.CoolBtnBMP.Width = .CBtnExceed.Width
			.CoolBtnBMP.Height = .CBtnExceed.Height
		Else
			.PnlExceed.Align = 4
			.PnlExceed.Left = This.Width -12
			.PnlExceed.Width = 12
			.PnlExceed.Height = This.ClientHeight
			'.CBtnExceed.Align = 3
			.CBtnExceed.Height = This.PnlExceed.ClientHeight
			.CBtnExceed.Width = 12
			.CoolBtnBMP.Width = .CBtnExceed.Width
			.CoolBtnBMP.Height = This.PnlExceed.ClientHeight '.CBtnExceed.Height
		End If
		.CBtnExceedHot.Width = .CBtnExceed.Width
		.CBtnExceedHot.Height = .CBtnExceed.Height
		'.PnlExceed.Parent = This '.DummyPanel
		'.PnlExceed.Parent = This

		If isXP_QTBtn = False Then
			.CoolBtnBMP.Width = ((.btnwidth(I) +3) *4) +2
			.CoolBtnBMP.Height = .btnwidth(I) +True
			.CoolBtnBMP.FillRect(False, False, .CoolBtnBMP.Width, .CoolBtnBMP.Height, clBtnFace)
			.CoolBtnBMP.Font.Name = "MS Sans Serif"
			.CoolBtnBMP.Font.Bold = True
			.CoolBtnBMP.Font.Size = 12
			For I = False To 3
				.BMPtmp.TextOut((I *.PnlExceed.Width) +((.PnlExceed.Width -.TextWidth("»") -True) \2), _
								-6, _
								"»", _
								.Font.Color, _
								-True)
			Next I
			.CoolBtnBMP.Font.Name = This.Font.Name
			.CoolBtnBMP.Font.Bold = This.Font.Bold
			.CoolBtnBMP.Font.Size = This.Font.Size
			
			' Style2
			.BMPtmp.Width = .PnlExceed.Width: .BMPtmp.Height = .PnlExceed.Height
			.BMPtmp.Rectangle( False, _
							   False, _
							   .BMPtmp.Width, _
							   .BMPtmp.Height, _
							   -2147483632) 'clBtnShadow
			.BMPtmp.FillRect( True, _
							  True, _
							  .BMPtmp.Width -True, _
							  .BMPtmp.Height -True, _
							  -2147483638) 'clActiveBorder
			.BMPtmp.Font.Name = "MS Sans Serif"
			.BMPtmp.Font.Bold = True
			.BMPtmp.Font.Size = 12
			.BMPtmp.TextOut((.BMPtmp.Width -.TextWidth("»") -True) \2, -6, "»", .Font.Color, -True)
			'.BMPtmp.TextOut((.BMPtmp.Width -.BMPtmp.TextWidth(">>")) \2, -2, ">>", .Font.Color, -True)
			.BMPtmp.Font.Name = This.Font.Name
			.BMPtmp.Font.Bold = This.Font.Bold
			.BMPtmp.Font.Size = This.Font.Size
			.CBtnExceedHot.BMP = .BMPtmp.BMP
		Else
			Fast_QCBarToQTBtn( xpt_ReBar, _
							   IIf(.Orientation, 5, 4), _
							   This.CoolBtnBMP, _
							   "", _
							   False, _
							   False, _
							   This.Handle)

			WITH Dest: .Left = False: .Right = This.CBtnExceed.Width
						.Top = False: .Bottom = This.CoolBtnBMP.Height
			END WITH
			WITH Src: .Left = ((This.CBtnExceed.Width +3) *4) +True
						 .Right = .Left +This.CBtnExceed.Width +True
						  .Top = True: .Bottom = This.CoolBtnBMP.Height +True
			END WITH
			.BMPtmp.Width = .Dest.Right: .CBtnExceedHot.Height = .Dest.Bottom
			'.BMPtmp.FillRect(,,,,, clBtnFace)
			
			.BMPtmp.CopyRect(This.Dest, This.CoolBtnBMP, This.Src)
			.CBtnExceedHot.BMP = .BMPtmp.BMP

			.CoolBtnBMP.Width = ((.CBtnExceed.Width +3) *3) +True
			.CBtnExceed.NumBMPs = 3
			.CBtnExceed.BMP = .CoolBtnBMP.BMP
		End If

		.ShapeBar(This.FlickeringFree)
	End Sub


	'PROPERTY SET SetHeight(Height As Integer)
	'	.Height = Height
	'	Super.Height = Height
	'END PROPERTY
	'PROPERTY SET SetWidth(Width As Integer)
	'	.Width = Width
	'	Super.Width = Width
	'	'.FlickeringFree.Width = .ClientWidth
	'	.FlickeringFree.Visible = IIf(.FlickeringFree.Visible, 0, 1)
	'END PROPERTY
	PROPERTY SET SetHideCaption(hide as integer)
		.HideCaption = hide
		.RePaint
		'If .HideCaption = True Then
		'	.CaptionHeight = False
		'	.CaptionWidth = False
		'Else
		'	.CaptionHeight = (.Height -.TextHeight(.Caption)) /2
		'	.CaptionWidth = .TextWidth(.Caption) +5
		'	.IMGBackGround.TextOut(2, .CaptionHeight, .Caption, .Font.Color, -1)
		'End If
	END PROPERTY
	PROPERTY SET SetItemsWidth(width as integer)
		.ItemsWidth = width

		Dim I As Integer
		'.BtnLeft(False) = False
		.BtnWidth(False) = False
		FOR I = False TO .BtnCount
			If .Btn(I) = "-" Then _
				.BtnWidth(I) = 5 _
			Else _
				.BtnWidth(I) = .ItemsWidth
		NEXT I
		FOR I = False TO .BtnCount -True
			.BtnLeft(I +True) = .BtnLeft(I) +.BtnWidth(I)
		NEXT I
		.WidthChanged = True

	END PROPERTY
	PROPERTY SET SetOrientation(orientation as integer)
		.Orientation = orientation
		.FlickeringFree.Align = IIf(.Orientation, True, 3)
	END PROPERTY

   PRIVATE:
	Event DragTimer.OnTimer '(Sender As QTimer)
		If GetAsyncKeyState_QCBar(VK_LBUTTON_QCBar) = False Then
			.Align = .Align '.RePaint
			.DragTimer.Enabled = False
		End If
	End Event
	Event IMGBackGround.OnMouseMove (X As Integer, Y As Integer, Shift As Integer)
		SetCapture_QTBtn This.Handle
	End Event
	Event BtnsHotTrack.OnMouseMove (X As Integer, Y As Integer, Shift As Integer)
		SetCapture_QTBtn This.Handle
	End Event
	Event CBtnExceedHotTrack.OnMouseMove (X As Integer, Y As Integer, Shift As Integer)
		SetCapture_QTBtn This.Handle
	End Event
	'Event CanvasLeft.OnMouseMove (X As Integer, Y As Integer, Shift As Integer)
	'	SetCapture_QTBtn This.Handle '.IMGBackGround.Handle
	'End Event
	'Event CanvasLeft.OnPaint
	'	If .Top > 40 Then .Height = .Height \2
	'End Event
	Event CanvasRight.OnPaint
		If .IsPainted = False Then
			.IsPainted = True
			'.FlickeringFree.Visible = False
			.RePaint
			.FlickeringFree.Visible = True
			'.mnuItemCount = GetMenuItemCount_QCBar(.mnuExceed.Handle)
		End If
		Dim btnNum As Integer
		Dim I As Integer

		For I = -(.BtnCount -True) To False
			If .Btn(I *-True) <> "-" Then
				btnNum = I *-True
				Exit For
			End If
		Next I
		If .Orientation = False Then
			If .Width < (.BtnLeft(btnNum) +(.BtnWidth(btnNum) \.66)) and _
				.Btn(btnNum) <> "-" and _
				.PnlExceed.Visible = False Then
				.PnlExceed.Visible = True
			ElseIf .Width > (.BtnLeft(btnNum) +(.BtnWidth(btnNum) \.66)) and .PnlExceed.Visible = True Then
				.PnlExceed.Visible = False
			End If
		ElseIf .Orientation Then
			If .Height < (.BtnLeft(btnNum) +(.BtnWidth(btnNum) \.66)) and _
				.Btn(btnNum) <> "-" and _
				.PnlExceed.Visible = False Then
				.PnlExceed.Visible = True
			ElseIf .Height > (.BtnLeft(btnNum) +(.BtnWidth(btnNum) \.66)) and .PnlExceed.Visible = True Then
				.PnlExceed.Visible = False
			End If
		End If
		'If .mnuItemCount Then
		'	For I = False To .mnuItemCount -True
		'		.mnuExceed.DelIndex (False)
		'		'CALLFUNC(.OnMouseEnter, False, False, False, 1000, This)
		'	Next I
		'	.mnuItemCount = False
		'End If
		'.RePaint
	End Event
	Event OnMouseMove (X As Integer, Y As Integer, Shift As Integer)
		Dim curPosX As Integer
		Dim curBtn As Integer
		Dim btnWidth As Integer
		Dim I As Integer
		Dim R As RECT_QTBtn
		'Dim mDC As Integer
		'If mDC = False Then _
		'	mDC = GetDC_QTBtn(This.Handle) 
		Static firstAction As Integer
		Static wasBtn As Integer
		'wasBtn = -1
		Static PosX As Integer, PosY As Integer
		Dim sepBefore As Integer

		If .Orientation Then _
			btnWidth = (This.ClientHeight -2) /5 _
		Else _
			btnWidth = (This.ClientWidth -2) /5

		If (X < False) Or (Y < False) Or (X > This.Width) _
			Or (Y > This.Height) Then
			' le pseudo-evénement MOUSELEAVE
			ReleaseCapture_QTBtn
			' on retourne le caption à la normal
			'This.Font.Bold = False
			'This.Font.Color = -2147483630
			'This.caption = "Dehors..."
			'StatusBar1.Panel(0).Caption = "Dehors"
			wasBtn = -True
			If curBtn > -True Then
				sepBefore = False
				FOR I = False TO curBtn
					If .btn(I) = "-" Then _
						sepBefore ++
				NEXT I
				If .btn(curBtn) <> "-" Then
'					.imgLBK.Width = .imgLA.Width
'					.imgLBK.Height = .imgLA.Height
'					If Style > False Then
'						.IMGBackGround.FillRect(.btnLeft(curBtn), _
'										False, _
'										.btnLeft(curBtn +True), _
'										This.ClientHeight -2, _
'										clBtnFace)
'					End If
'					.imgLBK.BMP = .imgLA.GetBMP(curBtn -sepBefore)
'					.imgLBK.TransparentColor = .imgLBK.Pixel(0,0) 'clWhite
'					.imgLBK.Transparent = True
'					.IMGBackGround.Draw(((.btnWidth(curBtn) -IIf(.BtnMenu(curBtn) = True, 8, False) -.imgLBK.Width) \2) +.btnLeft(curBtn), _
'								(This.ClientHeight -2 -.imgLBK.Height) \2, _
'								.imgLBK.BMP) '.imgLA.GetBMP(curBtn -sepBefore)) 'Bitmap2.BMP)
					'$TypeCheck Off
					'hCursor = LoadCursor(ByVal 0&, 32753)
					'DrawIcon(IMGBackGround1.Hanlde, 0, 0, GetCursor)
					'$TypeCheck On
					'DestroyCursor (hCursor)
'					If .BtnMenu(curBtn) Then
'						.IMGBackGround.Font.Name = "Marlett"
'						.IMGBackGround.TextOut( .BtnLeft(curBtn +True) -12, _
'										5, _
'										"6", .Font.Color, -True )
'						.IMGBackGround.Font.Name = .Font.Name
'					End If
					If .CoolBtn(curBtn).Enabled Then
						.ImgBtnHot(curBtn).Visible = False
						.CoolBtn(curBtn).Down = False
						.Hint = ""
					End If
	' !!Repetitive	''If .CBtnExceedHot.Visible Then _
					''	.CBtnExceedHot.Visible = False
				End If
			End If
			If .CBtnExceedHot.Visible Then _
				.CBtnExceedHot.Visible = False
			CALLFUNC(.OnMouseLeave, X, Y, Shift, This)
		ElseIf (GetCapture_QTBtn() <> This.Handle) and _
				(PosX <> X and PosY <> Y) Then
			' Verifie si la requete de relâcher la capture d'un QCBar est 0
			' Check if the release capture request for QCBar is 0
			' 
			' Ce qui va aussi empêcher le btn de reprendre son état initial
			' lors d'une action...
			PosX = X
			PosY = Y

			' le pseudo-evénement MOUSEENTER
			SetCapture_QTBtn This.Handle
			' on met le caption en gras
			'.Font.Bold = True
			'This.Font.Color = -2147483635
			'.caption = "Dessus..."

			'ReleaseCapture_QTBtn
		Else
			If .EditCount > False Then
				FOR I = False TO .EditCount -True
					If X >= .EditLeft(I) And X <= .EditLeft(I) +.EditWidth(I) Then
						If .CBtnExceedHot.Visible Then _
							.CBtnExceedHot.Visible = False
						ReleaseCapture_QTBtn
						Exit For
					End If
				NEXT I
			End If
			If .ComboBoxCount > False Then
				FOR I = False TO .ComboBoxCount -True
					If X >= .ComboBoxLeft(I) And X <= .ComboBoxLeft(I) +.ComboBoxWidth(I) Then
						If .CBtnExceedHot.Visible Then _
							.CBtnExceedHot.Visible = False
						ReleaseCapture_QTBtn
						Exit For
					End If
				NEXT I
			End If
			'StatusBar1.Panel(0).Caption = "Dedans"
			'btnWidth = (This.ClientWidth -2) /5
			'curPosX = ROUND(X \btnWidth) +1
			'curBtn = -1 'curPosX -1
			FOR I = False TO .BtnCount -True
				If .Orientation Then
					If Y >= .BtnLeft(I) and Y <= .BtnLeft(I +True) Then
						curBtn = I
						Exit For
					Else
						curBtn = -True
					End If
				Else
					If X >= .BtnLeft(I) and X <= .BtnLeft(I +True) Then
						curBtn = I
						Exit For
					Else
						curBtn = -True
					End If
				End If
			NEXT I
			If (curBtn > -True and curBtn < .btnCount) Then
				If firstAction = False or (wasBtn <> curBtn or wasBtn = -True) Then 'curPosX Then
					firstAction = True
					Application.ShowHint = False
					ReleaseCapture_QTBtn
					If .btn(curBtn) = "-" Then .Hint = "" Else .Hint = .Btn(curBtn)
					Application.ShowHint = True
					SetCapture_QTBtn This.Handle
'					If Style = 2 and .btn(curBtn) <> "-" Then
'						'Style2
'						.IMGBackGround.Rectangle(.btnLeft(curBtn), _
'										 False, _
'										 .btnLeft(curBtn) +.btnWidth(curBtn), _
'										 This.ClientHeight -2, _
'										 clBtnShadow)
'						.IMGBackGround.FillRect(.btnLeft(curBtn) +True, _
'										True, _
'										.btnLeft(curBtn) +.btnWidth(curBtn) -True, _
'										This.ClientHeight -3, _
'										clActiveBorder)
'					End If

					sepBefore = False
					.imgLBK.Width = .imgLA.Width
					.imgLBK.Height = .imgLA.Height
					For I = False To .BtnCount -True
						If .btn(I) <> "-" Then
'							If I <> curBtn Then
'								If Style < 2 Then
'									SetRect_QCBar R, .btnLeft(I), False, .btnLeft(I +True), This.Height -2
'									If Style = True Then
'										'Style1
'										DrawEdge_QCBar .IMGBackGround.Handle, R, BDR_RAISEDINNER, BF_RECT_QCBar OR BF_FLAT_QCBar 'BDR_SUNKENOUTER_QCBar, BF_RECT_QCBar '
'									Else
'										DrawEdge_QCBar .IMGBackGround.Handle, R, BDR_RAISEDINNER, BF_RECT_QCBar ' BDR_SUNKENOUTER_QCBar, BF_RECT_QCBar '
'									End If
'								ElseIf Style = 2 Then
'									'Style2
'									.IMGBackGround.FillRect(.btnLeft(I), _
'													False, _
'													.btnLeft(I +True), _
'													This.ClientHeight -2, _
'													clBtnFace)
'								End If
'							End If
'							.imgLBK.BMP = .imgLA.GetBMP(I -sepBefore)
'							.imgLBK.TransparentColor = .imgLBK.Pixel(0,0) 'clWhite
'							.imgLBK.Transparent = True
'							.IMGBackGround.Draw(((.btnWidth(I) -IIf(.BtnMenu(I) = True, 8, False) -.imgLBK.Width) \2) +.btnLeft(I), _
'										(This.ClientHeight -2 -.imgLBK.Height) \2, _
'										.imgLBK.BMP) '.imgLA.GetBMP(I -sepBefore)) 'Bitmap2.BMP)
							'$TypeCheck Off
							'hCursor = LoadCursor(ByVal 0&, 32753)
							'DrawIcon(IMGBackGround1.Hanlde, 0, 0, GetCursor)
							'$TypeCheck On
							'DestroyCursor (hCursor)
'							If .BtnMenu(I) Then
'								If Style = True Then
'									.IMGBackGround.FillRect(.btnLeft(I +True) -12, _
'													True, _
'													.btnLeft(I) +.btnWidth(I) -True, _
'													This.ClientHeight -3, _
'													clBtnFace)
'								End If
'								.IMGBackGround.Font.Name = "Marlett"
'								.IMGBackGround.TextOut( .BtnLeft(I +True) -12, _
'												5, _
'												"6", .Font.Color, -True )
'								.IMGBackGround.Font.Name = .Font.Name
'							End If
						Else
							sepBefore ++
						End If
					Next I
'					If Style = True and .btn(curBtn) <> "-" Then
'						'Style1
'						If .BtnMenu(curBtn) Then
'							'avec menu
'							SetRect_QCBar R, .btnLeft(curBtn), False, .btnLeft(curBtn +True) -11, This.ClientHeight -2
'							DrawEdge_QCBar .IMGBackGround.Handle, R, BDR_RAISEDINNER, BF_RECT_QCBar 'OR BF_FLAT_QCBar ''BDR_SUNKENOUTER_QCBar, BF_RECT_QCBar '
'							SetRect_QCBar R, .btnLeft(curBtn +True) -10, False, .btnLeft(curBtn +True), This.ClientHeight -2
'							DrawEdge_QCBar .IMGBackGround.Handle, R, BDR_RAISEDINNER, BF_RECT_QCBar 'OR BF_FLAT_QCBar ''BDR_SUNKENOUTER_QCBar, BF_RECT_QCBar '
'						Else
'							'sans menu
'							SetRect_QCBar R, .btnLeft(curBtn), False, .btnLeft(curBtn +True), This.ClientHeight -2
'							DrawEdge_QCBar .IMGBackGround.Handle, R, BDR_RAISEDINNER, BF_RECT_QCBar 'OR BF_FLAT_QCBar ''BDR_SUNKENOUTER_QCBar, BF_RECT_QCBar '
'						End If
'					End If
					.ImgBtnHot(wasBtn).Visible = False
					.CoolBtn(wasBtn).Down = False
					If .CBtnExceedHot.Visible Then _
						.CBtnExceedHot.Visible = False
				End If
				wasBtn = curBtn 'curPosX
				If .CoolBtn(curBtn).Down = False and .CoolBtn(curBtn).Enabled Then
					If (.Orientation and Y < This.Height -IIf(.PnlExceed.Visible, 12, False)) or _
						(.Orientation = False and X < This.Width -IIf(.PnlExceed.Visible, 12, False)) Then
						.ImgBtnHot(curBtn).Visible = True
					Else
						.ImgBtnHot(curBtn).Visible = False
					End If
				End If
				CALLFUNC(.OnMouseEnter, X, Y, Shift, curBtn, This)	

				If .PnlExceed.Visible Then
					If .Orientation Then
						If (X > False and X < This.Width) and _
							(Y >= This.Height -12 and Y <= This.Height) Then
							.CBtnExceedHot.Visible = True
							CALLFUNC(.OnMouseEnter, X, Y, Shift, 99, This)
						Else
							.CBtnExceedHot.Visible = False
						End If
					Else
						If (X >= This.Width -12 and X <= This.Width) and _
							(Y > False and Y < This.Height) Then
							.CBtnExceedHot.Visible = True
							CALLFUNC(.OnMouseEnter, X, Y, Shift, 99, This)
						Else
							.CBtnExceedHot.Visible = False
						End If
					End If
				End If
			Else
				'curBtn = -1
				If .Orientation Then
					If (Y > .btnLeft(.btnCount -True) +.btnWidth(.btnCount -True) or _
						Y < .btnLeft(0)) And wasBtn <> -True Then
						.ImgBtnHot(wasBtn).Visible = False
						.ImgBtnHot(curBtn).Visible = False
						.CoolBtn(wasBtn).Down = False
						.Hint = ""
						CALLFUNC(.OnMouseEnter, X, Y, Shift, curBtn, This)
						'.RePaint
						wasBtn = -True
					End If
				Else
					If (X > .btnLeft(.btnCount -True) +.btnWidth(.btnCount -True) or _
						X < .btnLeft(0)) And wasBtn <> -True Then
						.ImgBtnHot(wasBtn).Visible = False
						.ImgBtnHot(curBtn).Visible = False
						.CoolBtn(wasBtn).Down = False
						.Hint = ""
						CALLFUNC(.OnMouseEnter, X, Y, Shift, curBtn, This)
						'.RePaint
						wasBtn = -True
					End If
				End If
			End If
		End If
		'CALLFUNC(.OnMouseEnter, X, Y, Shift, This)
		'wasBtn = curPosX
	End Event
	Event OnMouseDown (btn As Integer, X As Integer, Y As Integer, Shift As Integer)
		Dim I As Integer
		Dim curBtn As Integer
		Dim R As RECT_QTBtn
		'curBtn = -1
		FOR I = False TO .BtnCount -True
			If .Orientation = False and (X >= .BtnLeft(I) and X <= .BtnLeft(I +True)) Then
				curBtn = I
				Exit For
			ElseIf .Orientation and (Y >= .BtnLeft(I) and Y <= .BtnLeft(I +True)) Then
				curBtn = I
				Exit For
			Else
				curBtn = -True
			End If
		NEXT I
		If .Orientation = False and (curBtn = -True and X >= False and X <= 7) and _
			.Width > 29 Then
			'ShowMessage "Star drag..."
			ReleaseCapture_QTBtn
			SendMessage_QCBar(This.Handle, WM_NCLBUTTONDOWN_QCBar, HTCAPTION_QCBar, False)
			.DragTimer.Interval = 50
			.DragTimer.Enabled = True
			'SetCapture_QTBtn (This.Handle)
		ElseIf .Orientation and (curBtn = -True and Y >= False and Y <= 7) and _
			.Height > 29 Then
			ReleaseCapture_QTBtn
			SendMessage_QCBar(This.Handle, WM_NCLBUTTONDOWN_QCBar, HTCAPTION_QCBar, False)
			.DragTimer.Interval = 50
			.DragTimer.Enabled = True
		ElseIf .Orientation = False and .PnlExceed.Visible and (X >= .Width -12 and X <= .Width) Then
			'.mnuItemCount = GetMenuItemCount_QCBar(.mnuExceed.Handle)
			If .mnuItemCount Then
				For I = False To .mnuItemCount -True
					.mnuExceed.DelIndex (False)
				Next I
				.mnuItemCount = False
			End If
			For I = -(.BtnCount -True) To False
				If .Width < (.BtnLeft(I *-True) +(.BtnWidth(I *-True) \.66)) Then
					.mnuExceed.AddItems (This.mnuItemExceed(I *-True))
					'CALLFUNC(.OnMouseEnter, False, False, False, 1001, This)
					.mnuItemCount ++
				Else
					Exit For
				End If
			Next I
			If .mnuItemCount Then
				.CBtnExceed.Down = True
				.CBtnExceedHot.Visible = False
				.mnuExceed.Alignment = True
				.mnuExceed.Popup(Screen.MouseX +(.PnlExceed.Left -X +.pnlExceed.Width), _
							 Screen.MouseY +(.ClientHeight -Y) -2)
			End If
			'.CBtnExceedHot.Visible = False
			.CBtnExceed.Down = False
		ElseIf .Orientation and .PnlExceed.Visible and (Y >= .Height -12 and X <= .Height) Then
			'.mnuItemCount = GetMenuItemCount_QCBar(.mnuExceed.Handle)
			Dim MenuHeight As Integer
				MenuHeight = False
			If .mnuItemCount Then
				For I = False To .mnuItemCount -True
					.mnuExceed.DelIndex (False)
				Next I
				.mnuItemCount = False
				MenuHeight = False
			End If
			For I = -(.BtnCount -True) To False
				If .Height < (.BtnLeft(I *-True) +(.BtnWidth(I *-True) \.66)) Then
					.mnuExceed.Insert (False, This.mnuItemExceed(I *-True))
					MenuHeight = MenuHeight +IIf(.mnuItemExceed(I *-True).Caption <> "-", 17, 9)
					'CALLFUNC(.OnMouseEnter, False, False, False, 1001, This)
					.mnuItemCount ++
				Else
					Exit For
				End If
			Next I
			If .mnuItemCount Then
				'If .mnuItemExceed(.BtnCount -.mnuItemCount -True).Caption = "-" Then _
				'		.mnuExceed.DelIndex (.mnuItemCount -True)
				'If .mnuItemExceed(.BtnCount -True).Caption = "-" Then _
				'		.mnuExceed.DelIndex (False)
				MenuHeight = MenuHeight +6
				.CBtnExceed.Down = True
				.CBtnExceedHot.Visible = False
				.mnuExceed.Alignment = False
				.mnuExceed.Popup(Screen.MouseX +(.PnlExceed.Left -X +.pnlExceed.Width) +True, _
								 Screen.MouseY +(.ClientHeight -Y) -MenuHeight)
			End If
			'.CBtnExceedHot.Visible = False
			.CBtnExceed.Down = False

		'ElseIf .BtnMenu(curBtn) = True and X >= .BtnLeft(curBtn +True) -12 Then
		'	.mnuPopup(curBtn).Popup(Screen.MouseX +(.BtnLeft(curBtn +True) -X) +True, _
		'							Screen.MouseY +(.ClientHeight -Y) -2)
		'	curBtn = -True
		Else
			If Btn = False Then
				'Dim R As RECT_QTBtn
				Dim sepBefore As Integer
				sepBefore = False
				If curBtn > -True Then
					sepBefore = False
					FOR I = False TO curBtn
						If .btn(I) = "-" Then _
							sepBefore ++
					NEXT I
					If .btn(curBtn) <> "-" and .CoolBtn(curBtn).Enabled Then
						.ImgBtnHot(curBtn).Visible = False
						.CoolBtn(curBtn).Down = True
						If .Orientation = False and .BtnMenu(curBtn) and X >= .BtnLeft(curBtn +True) -12 Then
'							If Style < 2 Then
'								SetRect_QCBar R, .btnLeft(curBtn +True) -12, False, .btnLeft(curBtn +True), This.ClientHeight -2
'								DrawEdge_QCBar .IMGBackGround.Handle, R, BDR_SUNKENOUTER_QCBar, BF_RECT_QCBar 
'							Else
'								'Style2
'								.IMGBackGround.Rectangle(.btnLeft(curBtn), _
'												 False, _
'												 .btnLeft(curBtn) +.btnWidth(curBtn), _
'												 This.ClientHeight -2, _
'												 clBtnShadow)
'								.IMGBackGround.FillRect(.btnLeft(curBtn +True) -12, _
'												True, _
'												.btnLeft(curBtn) +.btnWidth(curBtn) -True, _
'												This.ClientHeight -3, _
'												clWhite)
'							End If
							'If .BtnMenu(curBtn) Then
'								.IMGBackGround.Font.Name = "Marlett"
'								.IMGBackGround.TextOut( .BtnLeft(curBtn +True) -12, _
'												5, _
'												"6", .Font.Color, -True )
'								.IMGBackGround.Font.Name = .Font.Name
							'End If
							If .CoolBtn(curBtn).Enabled Then _
								.mnuPopup(curBtn).Popup(Screen.MouseX +(.BtnLeft(curBtn +True) -X) +True, _
														Screen.MouseY +(.ClientHeight -Y) -2)
							.CoolBtn(curBtn).Down = False
						ElseIf .Orientation and .BtnMenu(curBtn) and X >= .BtnWidth(curBtn) -12 Then
							If .CoolBtn(curBtn).Enabled Then _
								.mnuPopup(curBtn).Popup(Screen.MouseX +(.BtnWidth(curBtn) -X) +True, _
														Screen.MouseY +(.ClientHeight -Y) -2)
							.CoolBtn(curBtn).Down = False
'						Else
'							If Style = 2 Then
'								'Style2
'								.IMGBackGround.Rectangle(.btnLeft(curBtn), _
'												 False, _
'												 .btnLeft(curBtn) +.btnWidth(curBtn), _
'												 This.ClientHeight -2, _
'												 clBtnShadow)
'								.IMGBackGround.FillRect(.btnLeft(curBtn) +True, _
'												True, _
'												.btnLeft(curBtn) +.btnWidth(curBtn) -True, _
'												This.ClientHeight -3, _
'												clWhite)
'							End If

'							.imgLBK.Width = .imgLA.Width
'							.imgLBK.Height = .imgLA.Height
'							If Style <> 2 Then
'								.IMGBackGround.FillRect(.btnLeft(curBtn), _
'												False, _
'												.btnLeft(curBtn +True), _
'												This.ClientHeight -2, _
'												clBtnFace)
'							End If
'							.imgLBK.BMP = .imgLA.GetBMP(curBtn -sepBefore)
'							.imgLBK.TransparentColor = .imgLBK.Pixel(0,0) 'clWhite
'							.imgLBK.Transparent = True
'							.IMGBackGround.Draw(((.btnWidth(curBtn) -IIf(.BtnMenu(curBtn) = True, 8, False) -.imgLBK.Width) \2) +.btnLeft(curBtn), _
'										(This.ClientHeight -2 -.imgLBK.Height) \2, _
'										.imgLBK.BMP) '.imgLA.GetBMP(curBtn -sepBefore)) 'Bitmap2.BMP)
'							If .BtnMenu(curBtn) Then
'								.IMGBackGround.Font.Name = "Marlett"
'								.IMGBackGround.TextOut( .BtnLeft(curBtn +True) -12, _
'												5, _
'												"6", .Font.Color, -True )
'								.IMGBackGround.Font.Name = .Font.Name
'							End If
'							If Style <> 2 and .btn(curBtn) <> "-" Then
'								'Style1
'								SetRect_QCBar R, .btnLeft(curBtn), False, .btnLeft(curBtn +True), This.ClientHeight -2
'								DrawEdge_QCBar .IMGBackGround.Handle, R, BDR_SUNKENOUTER_QCBar, BF_RECT_QCBar 'OR BF_FLAT_QCBar ''BDR_SUNKENOUTER_QCBar, BF_RECT_QCBar '
'							End If
							'CALLFUNC(.OnChange, curBtn, This)
						End If
					End If
				End If
			ElseIf .BtnMenu(curBtn) Then
				.mnuPopup(curBtn).Popup(Screen.MouseX, _
										Screen.MouseY)
				.CoolBtn(curBtn).Down = False
			End If
			'ShowMessage STR$(curBtn)
		End If
	End Event
	Event OnMouseUp (btn As Integer, X As Integer, Y As Integer, Shift As Integer)
		.Align = .Align
		Dim curBtn As Integer
		Dim I As Integer
		FOR I = False TO .BtnCount -True
			If (.Orientation = False and (X >= .BtnLeft(I) and X <= .BtnLeft(I +True))) or _
			   (.Orientation and (Y >= .BtnLeft(I) and Y <= .BtnLeft(I +True))) Then
				curBtn = I
				Exit For
			Else
				curBtn = -True
			End If
		NEXT I

		Dim sepBefore As Integer
			sepBefore = False

		If (.Orientation = False and .PnlExceed.Visible and (X >= .Width -12 and X <= .Width)) or _
		   (.Orientation and .PnlExceed.Visible and (Y >= .Height -12 and Y <= .Height)) Then _
		   .CBtnExceedHot.Visible = True
		If .Orientation = False and (.PnlExceed.Visible = False or (.PnlExceed.Visible and X < .Width -12)) or _
		   .Orientation and (.PnlExceed.Visible = False or (.PnlExceed.Visible and Y < .Height -12)) Then
			If curBtn > -True and .CoolBtn(curBtn).Enabled Then
				sepBefore = False
				FOR I = False TO curBtn
					If .btn(I) = "-" Then _
						sepBefore ++
				NEXT I
				If .btn(curBtn) <> "-" Then
					.ImgBtnHot(curBtn).Visible = False
					If .CoolBtn(curBtn).GroupIndex > True and .CoolBtn(curBtn).Down = False Then _
						.CoolBtn(curBtn).Down = True _
					Else _
						.CoolBtn(curBtn).Down = False 'True

					If .Orientation = False and .BtnMenu(curBtn) and X >= .BtnLeft(curBtn +True) -12 Then
					ElseIf .Orientation and .BtnMenu(curBtn) and X >= .BtnWidth(curBtn) -12 Then
					Else
						'If .BtnMenu(curBtn) Then
						'End If
						If .CoolBtn(curBtn).Enabled Then _
							CALLFUNC(.OnChange, curBtn, This)
					End If
				End If
			End If
		End If
	End Event
   PUBLIC:

	Constructor
		Align = False
		Alignment = False 'taLeftJustify
		Caption = "CoolBar"
		Width = 120
		Height = 24
		IMGStretchedBackGround.Align = 4'5 'alClient
		IMGStretchedBackGround.Enabled = False
		IMGStretchedBackGround.Stretch = True
		IMGStretchedBackGround.AutoSize = True
		IMGStretchedBackGround.Parent = This
		IMGStretchedBackGround2.Align = 5 'alClient
		IMGStretchedBackGround2.Enabled = False
		IMGStretchedBackGround2.Stretch = True
		IMGStretchedBackGround2.AutoSize = True
		IMGStretchedBackGround2.Parent = This.FlickeringFree
		FlickeringFree.Align = 3
		FlickeringFree.BevelWidth = False
		FlickeringFree.Visible = False
		FlickeringFree.Parent = This
		IMGBackGround.Align = 5 'alClient
		IMGBackGround.Enabled = False
		IMGBackGround.AutoSize = True
		IMGBackGround.Transparent = True
		IMGBackGround.Parent = This.FlickeringFree 'This
		BtnsHotTrack.Parent = This.FlickeringFree 'This
		BtnsHotTrack.Align = 5 'alClient
		'BtnsHotTrack.Top = True
		'BtnsHotTrack.Left = True
		BtnsHotTrack.Transparent = True
		'IMGBackGround.Hint = "CoolBar"
		'IMGBackGround.ShowHint = True
		PnlExceed.Left = This.Width -12
		PnlExceed.Width = 12
		PnlExceed.Align = 4
		PnlExceed.BevelWidth = False
		PnlExceed.Visible = False
		PnlExceed.Parent = This
		'PnlExceed.PopupMenu = .mnuExceed 
		'mnuExceed.Alignment = True
		'CBtnExceed.Align = 3' 4
		CBtnExceed.Flat = True
		CBtnExceed.Width = 12
		'CBtnExceed.Height = This.ClientHeight
		CBtnExceed.GroupIndex = True
		CBtnExceed.AllowAllUp = True
		CBtnExceed.Spacing = False
		CBtnExceed.Layout = False
		CBtnExceed.NumBMPs = 4
		'CBtnExceed.Visible = False
		CBtnExceed.Parent = This.PnlExceed
		CBtnExceedHot.Enabled = False
		CBtnExceedHot.Width = 12
		CBtnExceedHot.Visible = False
		CBtnExceedHot.Parent = This.PnlExceed
		CBtnExceedHotTrack.Parent = This.PnlExceed 'This
		CBtnExceedHotTrack.Align = 5 'alClient
		CBtnExceedHotTrack.Transparent = True
		'CanvasLeft.Parent = This
		'CanvasLeft.Align = alClient
		'CanvasRight.Left = This.Width -13
		'CanvasRight.Align = 4 'alClient
		CanvasRight.Width = True
		CanvasRight.Height = True
		CanvasRight.Parent = This '.PnlExceed
		HideCaption = True
		Hint = "CoolBar"
		ShowHint = True
		ItemsWidth = 24
		imgLA.BkColor = This.Color
		Orientation = False
		DragTimer.Enabled = False
		'RePaint
	End Constructor
  End With
End Type

