$IFNDEF __QTBUTTON_ADDONS_INC   ' IncManager: include guard
$DEFINE __QTBUTTON_ADDONS_INC
' Crйй par D-йvolution / Created by D-evolution -=@=- 2005

' Pour plus de dйtail sur l'utilisation de ce composant reportez vous
' а la documentation fournise... (QTButton.html)
' For more details on using this component please refer to the doc
' (QTButton.html)

' Ajoutй ceci aprиs avoir inclus QTButton.inc (QTButtonXX.inc)
' Contient 2 SUBs vous permettant de transformer vos BUTTONs et COOLBTNs en TBUTTONs
' Cette mйthode rйduite, n'offre pas toutes les fonctionnalitйes de QTButton, mais seulement la fonction
' enjolivure, elle rйduit grandement votre code, et permet l'utilisation de tableaux d'objet...

' Add this once you have include QTButton.inc (QTButtonXX.inc)
' Contain 2 SUBs that will allow you to transform your BUTTONs et COOLBTNs en TBUTTONs
' Only skin function is offered by this reduced method, all others features are not possible, 
' but will reduces your code greatly and allow object arrays...

' IMPORTANT vous devez avoir au minimum la version (.94) de QTButton pour que cela fonctionne
' IMPORTANT you'll need at least version .94 of QTButton to make it work

' А FAIRE / TODO
' -Support icфne sur le btn
$Option Explicit

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

$IFNDEF __QTBTNSHARED94
$DEFINE __QTBTNSHARED94

Const rqNullChr = CHR$(0)
Const rqSL		= CHR$(10)

Const DefPixelFormat = 4

'Accйlиre l'affichage des btns а l'йcran maintenant jusqu'а 97% avec un affichage 
'parfait de 60% dans le cas oщ certains btns ont des dimensions diffйrentes sinon 
'зa grimpe jusqu'а 100%
'Dans l'йvйnement OnShow de votre fenкtre ajoutez ShowMessage STR$(DrawCount)
'pour afficher le nombre de fois oщ les btns ont eus а кtre RePaint 
'Note :  certains btns auront toute fois besoin d'кtre redessinйs...
Dim QTBtnOptimize As Integer
	QTBtnOptimize = False

'Si vous voulez, vous pouver remplacer la resource par un objet bitmap
'mais n'oubliez pas de remplacer QTBtnBMP.BMPHandle = btn_BMP par
'QTBtnBMP.BMP = btn_BMP.BMP
Dim QTBtnBMP As QBitmap
	QTBtnBMP.BMPHandle = btn_BMP' REsource bitmap
	'QTBtnBMP.BMP = btn_BMP.BMP'  Image bitmap

Dim maxNumBMPs_QTBtn As Integer
	maxNumBMPs_QTBtn = 4

Dim RequestRelease As Integer

$ENDIF ' __QTBTNSHARED

$IFNDEF __QTBTNSHARED95
$DEFINE __QTBTNSHARED95

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

Declare Function SetBkMode_QTBtn Lib "gdi32" Alias "SetBkMode" _
		(ByVal hdc As Long, ByVal nBkMode As Long) As Long 
'Declare Function SetTextColor Lib "gdi32" Alias "SetTextColor" _
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

'Class = "Button"
'  Part ="BP_PUSHBUTTON" id="1"
'	State ="PBS_NORMAL" id="1"
'	State ="PBS_HOT" id="2"
'	State ="PBS_PRESSED" id="3"
'	State ="PBS_DISABLED" id="4"
'	State ="PBS_DEFAULTED" id="5"
'Class = "Toolbar"
'  Part ="TP_BUTTON" id = "1"
'    State ="TS_NORMAL" id="1"
'    State ="TS_HOT" id="2"
'    State ="TS_PRESSED" id="3"
'    State ="TS_DISABLED" id="4"
'    State ="TS_CHECKED" id="5"
'    State ="TS_HOTCHECKED" id="6"
'Class = "Tab"
'  Part = "TABP_TABITEM" id = "1"
'    State = "TIS_NORMAL" id="1"
'    State = "TIS_HOT" id="2"
'    State = "TIS_SELECTED" id="3"
'    State = "TIS_DISABLED" id="4"
'    State = "TIS_FOCUSED" id="5"

'Const BST_PUSHED = &H4
'Const BST_FOCUS = &H8

Const xpt_PushBtn		= "Button"
Const xpt_ToolBarBtn	= "Toolbar"
Const xpt_TabBtn		= "Tab"
' //--
$ENDIF ' __RQOBJDRAWING


' -- Restaurй 11janv (Retirй 31dйc)
' Vйrifie la version de Windows puisque certains problиmes sont identifiйs
' sur l'un ou l'autre
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
' //

' HotTrack
'Sub DrawHot(GoTimer As Integer)
'	If .Down = False and .NumBMPs >= maxNumBMPs_QTBtn and _
'		.Pushed >= False Then
'		TransparentBlt_QTBtn(This.BMPHot.Handle, _
'							 False, False, _
'							 This.Width, This.Height, _
'							 This.BMPBtn.Handle, _
'							 This.BMPBtn.Width -((This.BMPBtn.Width -True) \This.NumBMPs), True, _
'							 This.Width, This.Height, _
'							 IIf(isXP_QTBtn and .XPThemeEnabled, This.BMPBtn.Pixel(This.BMPBtn.Width -((This.BMPBtn.Width -True) \This.NumBMPs), False), clPurple))
'		'.BMPHot.TextOut(2,2,STR$(.Pushed),0,-1)
'		'.BMPHot.PixelFormat = pf15bit
'		BitBlt_QTBtn(This.hDC, _
'					 False, False, _
'					 This.Width, This.Height, _
'					 This.BMPHot.Handle, _
'					 False, False, _
'					 SrcCopy_QTBtn)
'		If GoTimer = True Then
'			'.HotTimer.Enabled = True
'			'.HotTimer.Interval = 50
'		End If
'	End If
'	'If .Pushed < False Then _
'	'	.HotTimer.Enabled = False
'End Sub
'Sub DrawNormal '(GoTimer As Integer)
'	TransparentBlt_QTBtn(This.BMPHot.Handle, _
'						 False, False, _
'						 This.Width, This.Height, _
'						 This.BMPBtn.Handle, _
'						 True, True, _
'						 This.Width, This.Height, _
'						 IIf(isXP_QTBtn and .XPThemeEnabled, This.BMPBtn.Pixel(False, False), clPurple))
'	'.BMPHot.TextOut(2,2,STR$(.Pushed),0,-1)
'	'.BMPHot.PixelFormat = pf15bit
'	BitBlt_QTBtn(This.hDC, _
'				 False, False, _
'				 This.Width, This.Height, _
'				 This.BMPHot.Handle, _
'				 False, False, _
'				 SrcCopy_QTBtn)
'	'If GoTimer = True Then
'	'	.HotTimer.Enabled = True
'	'	.HotTimer.Interval = 50
'	'End If
'	'If .Pushed < False Then _
'	'	.HotTimer.Enabled = False
'End Sub
	
SUB	Fast_QBtnToQTBtn_MouseMove(X As Integer, Y As Integer, Shift As Integer, Me As QButton)
	Static PosX As Integer, PosY As Integer
	Dim hDC As Long

	ReleaseDC_QTBtn (Me.Handle, hDC)
	If Me.Enabled Then
		Dim BMPBtn As QBitmap, _
			BMPHot As QBitmap

		' Retirй 6fйv
		'WITH Dest: .Left = False: .Right = (This.BMPBtn.Width -True) \This.NumBMPs
		'			.Top = False: .Bottom = This.BMPBtn.Height
		'END WITH

		' Get the device context
		hDC = GetDC_QTBtn(Me.Handle)
		' ...
		BMPHot.Height	= Me.Height
		BMPHot.Width	= Me.Width
		'SetBkColor_QTBtn	(This.BMPHot.Handle, &HFF00FF)
		'SetBkMode_QTBtn	(This.BMPHot.Handle, True)
		BMPHot.FillRect (False, False, BMPHot.Width, BMPHot.Height, clBtnFace)
		BMPBtn.BMP = Me.BMP

		If (X < False) Or (Y < False) Or _
			(X > Me.Width) Or (Y > Me.Height) Then
			'CALLFUNC(.OnMouseLeave, X, Y, Shift, Me)

			PosX = -True
			PosY = -True
			'.Pushed = False
			'.DrawNormal
	TransparentBlt_QTBtn(BMPHot.Handle, _
						 False, False, _
						 Me.Width, Me.Height, _
						 BMPBtn.Handle, _
						 True, True, _
						 Me.Width, Me.Height, _
						 clPurple) 'IIf(isXP_QTBtn and .XPThemeEnabled, This.BMPBtn.Pixel(False, False), clPurple))
	'.BMPHot.TextOut(2,2,STR$(.Pushed),0,-1)
	'.BMPHot.PixelFormat = pf15bit
	BitBlt_QTBtn(hDC, _
				 False, False, _
				 Me.Width, Me.Height, _
				 BMPHot.Handle, _
				 False, False, _
				 SrcCopy_QTBtn)
			' Inversй 6fйv pour accepter les changements dans la police
			' Remplacй .ReleaseHotTrack par ReleaseCapture puisque le SUB est vide
			ReleaseCapture_QTBtn '.ReleaseHotTrack
		ElseIf GetCapture_QTBtn() = Me.Handle and RequestRelease = False Then
			'This.DrawHot(False)
		TransparentBlt_QTBtn(BMPHot.Handle, _
							 False, False, _
							 Me.Width, Me.Height, _
							 BMPBtn.Handle, _
							 BMPBtn.Width -((BMPBtn.Width -True) \Me.NumBMPs), True, _
							 Me.Width, Me.Height, _
							 clPurple) 'IIf(isXP_QTBtn and .XPThemeEnabled, This.BMPBtn.Pixel(BMPBtn.Width -((BMPBtn.Width -True) \Me.NumBMPs), False), clPurple))
		'.BMPHot.TextOut(2,2,STR$(.Pushed),0,-1)
		'.BMPHot.PixelFormat = pf15bit
		BitBlt_QTBtn(hDC, _
					 False, False, _
					 Me.Width, Me.Height, _
					 BMPHot.Handle, _
					 False, False, _
					 SrcCopy_QTBtn)
		'If GoTimer = True Then
			'.HotTimer.Enabled = True
			'.HotTimer.Interval = 50
		'End If

		ElseIf GetCapture_QTBtn() <> Me.Handle and (RequestRelease = False _
			 and PosX <> X and PosY <> Y) Then
			' Verifie si la requete de relвcher la capture d'un QTBtn est 0
			' Check if the release capture request for QTBtn is 0
			' 
			' Ce qui va aussi empкcher le btn de reprendre son йtat initial
			' lors d'une action...
			PosX = X
			PosY = Y

			'LockWindowUpdate_QTBtn(This.Handle)
			' le pseudo-evйnement MOUSEENTER
			SetCapture_QTBtn Me.Handle
			' on met le caption en gras
			'.Font.Bold = True
			'.Font.Color = clHilight
			'.caption = "Dessus..."
			' -- Retirй 6fйv (test flickering)
			'If .NumBMPs => maxNumBMPs_QTBtn and .Down = False Then
			'	WITH Source: .Left = This.Dest.Right *(This.NumBMPs -True)
			'				.Right = .Left +This.Dest.Right
			'				  .Top = False: .Bottom = This.BMPBtn.Height
			'	END WITH
			'	.BMPBtn.CopyRect(This.Dest, This.BMPBtn, This.Source)
			'End If
			' //--

			'LockWindowUpdate_QTBtn(False)
			'CALLFUNC(.OnMouseEnter, X, Y, Shift, This)
			' -- Retirй 6fйv (test flickering)
			' Inversй 6fйv pour accepter les changements dans la police
			'.DrawCaption
			' //--
			'If .Pushed >= False Then _
				'This.DrawHot(True)
		TransparentBlt_QTBtn(BMPHot.Handle, _
							 False, False, _
							 Me.Width, Me.Height, _
							 BMPBtn.Handle, _
							 BMPBtn.Width -((BMPBtn.Width -True) \Me.NumBMPs), True, _
							 Me.Width, Me.Height, _
							 clPurple) 'IIf(isXP_QTBtn and .XPThemeEnabled, This.BMPBtn.Pixel(BMPBtn.Width -((BMPBtn.Width -True) \Me.NumBMPs), False), clPurple))
		'.BMPHot.TextOut(2,2,STR$(.Pushed),0,-1)
		'.BMPHot.PixelFormat = pf15bit
		BitBlt_QTBtn(hDC, _
					 False, False, _
					 Me.Width, Me.Height, _
					 BMPHot.Handle, _
					 False, False, _
					 SrcCopy_QTBtn)
		'If GoTimer = True Then
			'.HotTimer.Enabled = True
			'.HotTimer.Interval = 50
		'End If

		ElseIf RequestRelease = True Then	' Corrige l'йtat survolle du btn
											' Fix Hot state of btn
			PosX = -True	' < - corrige le problиme de survole
			PosY = -True
			'.Pushed = False
			' Remplacй .ReleaseHotTrack par ReleaseCapture puisque le SUB est vide
			ReleaseCapture_QTBtn '.ReleaseHotTrack
			'.DrawNormal
	TransparentBlt_QTBtn(BMPHot.Handle, _
						 False, False, _
						 Me.Width, Me.Height, _
						 BMPBtn.Handle, _
						 True, True, _
						 Me.Width, Me.Height, _
						 clPurple) 'IIf(isXP_QTBtn and .XPThemeEnabled, BMPBtn.Pixel(False, False), clPurple))
	'.BMPHot.TextOut(2,2,STR$(.Pushed),0,-1)
	'.BMPHot.PixelFormat = pf15bit
	BitBlt_QTBtn(hDC, _
				 False, False, _
				 Me.Width, Me.Height, _
				 BMPHot.Handle, _
				 False, False, _
				 SrcCopy_QTBtn)
			'BitBlt_QTBtn(This.hDC, False, False, Me.Width, Me.Height, BMPBtn.Handle, True, True, SrcCopy_QTBtn)
		End If
		If (PosX <> X and PosY <> Y) Then
			If X >= False and Y >= False and _
				X <= Me.Width and Y <= Me.Height Then '_
					'This.DrawHot(False)
		TransparentBlt_QTBtn(BMPHot.Handle, _
							 False, False, _
							 Me.Width, Me.Height, _
							 BMPBtn.Handle, _
							 BMPBtn.Width -((BMPBtn.Width -True) \Me.NumBMPs), True, _
							 Me.Width, Me.Height, _
							 clPurple) 'IIf(isXP_QTBtn and .XPThemeEnabled, BMPBtn.Pixel(BMPBtn.Width -((BMPBtn.Width -True) \Me.NumBMPs), False), clPurple))
		'.BMPHot.TextOut(2,2,STR$(.Pushed),0,-1)
		'.BMPHot.PixelFormat = pf15bit
		BitBlt_QTBtn(hDC, _
					 False, False, _
					 Me.Width, Me.Height, _
					 BMPHot.Handle, _
					 False, False, _
					 SrcCopy_QTBtn)
		'If GoTimer = True Then
			'.HotTimer.Enabled = True
			'.HotTimer.Interval = 50
		'End If
		End If
			RequestRelease = False	' Restaure la requкte а 0
					  				' Reset release request
		End If
		ReleaseDC_QTBtn (Me.Handle, hDC)
		'DeleteDC_QTBtn hDC
	End If
END SUB
' //

'Dim fastQTBtn_ImgLst_A As QImageList
'Dim fastQTBtn_ImgLst_D As QImageList
'Dim fastQTBtn_ImgLst_S As QImageList
''Dim fastQTBtn_ImgLst_H As QImageList

'Fast_QBtnToQTBtn( _
'				  BtnType As String, _
'				  PartID As Integer, _
'				  NumBMPs As Integer, _
'				  ICOIndex As Integer, _
'				  Me As QButton)

Sub Fast_QBtnToQTBtn( _
					  BtnType As String, _
					  PartID As Integer, _
					  NumBMPs As Integer, _
					  Layout As Integer, _
					  Spacing As Integer, _
					  Me As QButton)
	Dim Dest As QRect, Source As QRect
	Dim tmpBitmap1 As QBitmap, _
		NBitmap1 As QBitmap, _
		XPBitmap1 As QBitmap
	Dim XPBtnType As String ' Ajoutй 19jan corrige un problиme oщ les types sont diffйrents
	Dim XPPartID As Integer
	'Dim oldCaption As String
	'	oldCaption = Me.Caption
	Dim Width1 As Integer, Height1 As Integer
	'Dim Width2 As Integer, Height2 As Integer
	Dim tR As RECT_QTBtn
	Dim btnCount As Integer
	Dim btnCaption As String 'Restaure le titre lors d'un RePaint
	btnCaption = Me.Caption
	'Dim btnSpacing As Integer
	'btnSpacing = 4
	'Dim btnLayout As Integer
	'btnLayout = False
	Dim ICOBMP As QBitmap
	Dim ICOCount As Integer
	ICOCount = False
	If Me.Kind > False Then ' and ICOIndex > -1
		Me.Kind = Me.Kind
		ICOBMP.BMP = Me.BMP
		ICOCount = 2 'Me.NumBMPs
		Me.Caption = btnCaption 'Restaure le titre lors d'un RePaint
	End If

    Me.Spacing = False
	btnCount = NumBMPs 'Me.NumBMPs
	if btnCount > maxNumBMPs_QTBtn or btnCount < True Then _
		btnCount = maxNumBMPs_QTBtn
	Me.NumBMPs = btncount
	
	Dim fixTab As Integer
	fixTab = False

	if isXP_QTBtn and BtnType = xpt_TabBtn Then _
		fixTab = True
	if isXP_QTBtn and (BtnType = xpt_pushbtn or BtnType = xpt_toolbarbtn or BtnType = xpt_TabBtn) Then _
		PartID = True

	Width1 = ((Me.Width +3) *btnCount) +True
	Height1 = Me.Height +3

	' Si l'image а dйjа la mкme dimension elle ne sera pas redimensionnйe
	'If QTBtnOptimize <> True or _
	'	(isXP_QTBtn = True and (XPBtnType <> BtnType or PartID <> XPPartID)) or _
	'	((rWidth > False or rHeight > False) and _
	'	 (tmpBitmap1.Width <> Width1 and tmpBitmap1.Height <> Height1 and _
	'	  Width2 <> tmpBitmap1.Width and Height2 <> tmpBitmap1.Width)) Then
		With NBitmap1
			.Width = Width1		'== (mod)
			.Height = Height1	'== (mod)
			.FillRect(False, False, .Width, .Height, clBtnFace)'==(mod) (13janv remplacй clPurple par clBtnFace)
			'.PixelFormat = DefPixelFormat
		End With
		With XPBitmap1
			.Width = Width1		'== (mod)
			.Height = Height1	'== (mod)
			.FillRect(False, False, .Width, .Height, clBtnFace)'==(mod) (13janv remplacй clPurple par clBtnFace)
			'.PixelFormat = DefPixelFormat
		End With
		Width1 = Me.Width *btnCount
		Height1 = Me.Height

		tmpBitmap1.Font.Name = Me.Font.Name' == (add)
		tmpBitmap1.Font.Size = Me.Font.Size' == (add)
		tmpBitmap1.Font.Color = Me.Font.Color' == (add)
		tmpBitmap1.Font.Bold = Me.Font.Bold
		tmpBitmap1.Font.Italic = Me.Font.Italic
		tmpBitmap1.Font.Underline = Me.Font.Underline

		If isXP_QTBtn = False Then
			' Thиme non activй ou ce n'est pas Windows XP

			Dim J As Integer, I As Integer
			For J = False To btnCount -True
				' Le centre ----------------------------------------------------------
				With Dest
					.Left = ((Width1 \btnCount) *J) +3 +(True *(J +True)) +(J *2) -iif(J = 2, True, False)
					.Top = maxNumBMPs_QTBtn -iif(J=2, True, False)
					.Right = .Left +(Width1 \btnCount) -6
					.Bottom = Height1 -2 -iif(J = 2, True, False)
				End With
				With Source: .Left = ((QTBtnBMP.Width \btnCount) *J) +3: .Top = 3: _
					.Right = .Left +(QTBtnBMP.Width \btnCount) -6
					.Bottom = QTBtnBMP.Height -3
				End With

				NBitmap1.CopyRect(Dest, QTBtnBMP, Source)

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
						.Left = ((QTBtnBMP.Width \btnCount) *J) _
								+IIf(I = False or I = 2, False, (QTBtnBMP.Width \btnCount) -3)
						.Top = IIf(I < 2, False, QTBtnBMP.Height -3)
						.Right = .Left +3
						.Bottom = .Top +3
					End With
					NBitmap1.CopyRect(Dest, QTBtnBMP, Source)
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
						.Left = (QTBtnBMP.Width \btnCount) *J +3
						.Top = IIf(I = False, False, QTBtnBMP.Height -3)
						.Right = .Left +(QTBtnBMP.Width \btnCount) -6
						.Bottom = .Top +3
					End With
					NBitmap1.CopyRect(Dest, QTBtnBMP, Source)
				Next I
				' Les verticaux ------------------------------------------------------
				For I = False TO True
					With Dest
						.Left = ((Width1 \btnCount) *J) _
								+IIf(I = False, False, (Width1 \btnCount) -3) +(True *(J +True)) +(J *2) _
								-iif(J = 2, True, False)
						.Top = maxNumBMPs_QTBtn -iif(J = 2, True, False)
						.Right = .Left +3
						.Bottom = Height1 -2 -iif(J = 2, True, False)
					End With
					With Source
						.Left = ((QTBtnBMP.Width \btnCount) *J) +IIf(I = False, False, (QTBtnBMP.Width \btnCount) -3)
						.Top = 3
						.Right = .Left +3
						.Bottom = QTBtnBMP.Height -3
					End With
					NBitmap1.CopyRect(Dest, QTBtnBMP, Source)
				Next I
			Next J
			NBitmap1.PixelFormat = DefPixelFormat
		Else
			' Thиme activй (Windows XP)
			' --
			Dim hTheme As Long
			'On Error Resume Next

			' Ouverture du thиme
			Dim rtButton As String
			rtButton = ""
			' Format unicode ?!?
			For I = True To Len(BtnType)
				rtButton = rtButton +Mid$(BtnType, I, True) +rqNullChr
			Next I
			rtButton = rtButton +rqNullChr ' Un dernier pour finaliser

			'hTheme = False
			hTheme = OpenThemeData_QTBtn(Me.Handle, VarPtr(rtButton))
			If hTheme = False Then _
				hTheme = OpenThemeData_QTBtn(Me.Handle, VarPtr(rtButton))
			If hTheme <> False Then
				' Styles XP disponible

				Dim lR As Long
				Dim m_hDC As Long
				Dim m_lPartId As Long, m_lStateId As Long
				'Dim tR As RECT_QTBtn

				' m_hDC est le DC pour dessiner
				' m_lPartId et m_lStateId sont la class + l'йtat а dessiner
				' tR est un RECT spйcifiant la zone dans laquelle dessiner
				m_hDC = XPBitmap1.Handle
				If PartID > True Then _
					m_lPartId = PartID _
				Else _
					m_lPartId = True 'BP_PUSHBUTTON
				For I = False To 2 Step 2
					m_lStateId = I +True 'PBS_NORMAL
					tR.Left = ((I *(Me.Width +3)) +iif(I <> 2, True, False))
					tR.Top = True -iif(I <> 2, False, True) +fixTab 'False -iif(I <> 2, False, True)
					tR.Right = (tR.Left +Me.Width) '+True
					tR.Bottom = (Me.Height +True -iif(I <> 2, False, True) +fixTab) '+iif(I <> 2, True, False)

					lR = DrawThemeBackground_QTBtn(hTheme, _
											 m_hDC, _
											 m_lPartId, _
											 m_lStateId, _
											 tR, tR)
				Next I
				' Inverse Survolle et Dйsactivй
				For I = True To 3 Step 2
					m_lStateId = I +True 'PBS_NORMAL
					tR.Left = (((I +iif(I = True, 2, -2)) *(Me.Width +3)) +True)
					tR.Top = True 'False
					tR.Right = (tR.Left +Me.Width) '+True 
					tR.Bottom = Me.Height +True +fixTab '+2

					lR = DrawThemeBackground_QTBtn(hTheme, _
											 m_hDC, _
											 m_lPartId, _
											 m_lStateId, _
											 tR, tR)
				Next I
			End If

			' Session de dessin terminйe
			CloseThemeData_QTBtn hTheme
			CloseThemeData_QTBtn hTheme
			'//--
			XPBitmap1.PixelFormat = DefPixelFormat
		End If

	'End If
	'Width2 = ((Me.Width +3) *btnCount) +True
	'Height2 = Me.Height +3
	
	
	If isXP_QTBtn Then
		tmpBitmap1.BMP = XPBitmap1.BMP
	Else
		tmpBitmap1.BMP = NBitmap1.BMP
	End If

	If Me.Caption = "" Then
		Me.Layout = False
	Else
		SetBkMode_QTBtn tmpBitmap1.Handle, True
		For I = False To 2 Step 2
			tR.Left = ((I *(Me.Width +3)) +iif(I <> 2, True, False))
			tR.Top = True -iif(I <> 2, False, True) 'False -iif(I <> 2, False, True)
			tR.Right = (tR.Left +Me.Width) '+True
			tR.Bottom = (Me.Height +True -iif(I <> 2, False, True) +fixTab) '+iif(I <> 2, True, False)

			If ICOCount > False Then ' or ICOIndex > -1
				Select Case Layout 'Me.Layout
					Case True
						tR.Left = tR.Left -((ICOBMP.Width \ICOCount) _
									  +Spacing) '+Down
					Case 2
						tR.Top = tR.Top +((ICOBMP.Height +tmpBitmap1.TextHeight(Me.Caption)) \2) _
												+Spacing '+Down
					Case 3
						tR.Top = tR.Top -((ICOBMP.Height +tmpBitmap1.TextHeight(Me.Caption)) \2) _
												+Spacing '+Down
					Case Else
						tR.Left = tR.Left +(ICOBMP.Width \ICOCount) _
									  +Spacing '+Down
				End Select
			End If

			DrawText_QTBtn (tmpBitmap1.Handle, Me.Caption, Len(Me.Caption), _
							tR, DT_CENTER_QTBtn OR DT_SINGLELINE_QTBtn OR DT_VCENTER_QTBtn)
		Next I
		' Inverse Survolle et Dйsactivй
		For I = True To 3 Step 2
			tR.Left = (((I +iif(I = True, 2, -2)) *(Me.Width +3)) +True)
			tR.Top = True 'False
			tR.Right = (tR.Left +Me.Width) '+True 
			tR.Bottom = Me.Height +True +fixTab '+2

			If ICOCount > False Then ' or ICOIndex > -1
				Select Case Layout 'Me.Layout
					Case True
						tR.Left = tR.Left -((ICOBMP.Width \ICOCount) _
									  +Spacing) '+Down
					Case 2
						tR.Top = tR.Top +((ICOBMP.Height +tmpBitmap1.TextHeight(Me.Caption)) \2) _
												+Spacing '+Down
					Case 3
						tR.Top = tR.Top -((ICOBMP.Height +tmpBitmap1.TextHeight(Me.Caption)) \2) _
												+Spacing '+Down
					Case Else
						tR.Left = tR.Left +(ICOBMP.Width \ICOCount) _
									  +Spacing '+Down
				End Select
			End If

			DrawText_QTBtn (tmpBitmap1.Handle, Me.Caption, Len(Me.Caption), _
							tR, DT_CENTER_QTBtn OR DT_SINGLELINE_QTBtn OR DT_VCENTER_QTBtn)
		Next I

		tmpBitmap1.Height = (Height1 +True) +tmpBitmap1.TextHeight(Me.Caption)
		Me.Layout = 3
	End If
	tmpBitmap1.PixelFormat = DefPixelFormat

	XPBtnType = BtnType
	'tmpBitmap1.Transparent = True
	tmpBitmap1.TransparentColor = tmpBitmap1.Pixel(True, True)


	' Fix Bug in Win9x where caption are draw in white color
	If ICOCount > False Then
		' -- dйplacй
		Dim ICOtmp As QBitmap
		Dim Left As Integer
		Dim Top As Integer
		ICOtmp.Width = ICOBMP.Width \ICOCount
		ICOtmp.Height = ICOBMP.Height
		WITH Dest: .Left = False: .Right = ICOtmp.Width
					.Top = False: .Bottom = ICOtmp.Height
		END WITH
		' //-- dйplacй
		Dim StartFrom As Integer
		For I = False To NumBMPs -True 'step 2
			If Me.Kind > False Then ' and ICOIndex = 0
				If I = True Then _
					StartFrom = True _
				Else _
					StartFrom = False
			Else
				StartFrom = I
			End If
			left = iif(Layout > True, Me.Width \2, (Me.Width -( tmpBitmap1.TextWidth(Me.Caption)) ) \2)
			left = left +(I *(Me.Width +3)) +True _
				   +iif(Layout < 2 and Me.Caption <> "", _
						iif(Layout = False, -((ICOBMP.Width \ICOCount) +Spacing) \2, _
							(ICOBMP.Width \ICOCount) \2), _
						-(ICOBMP.Width \ICOCount) \2 -True)
			top = ((Me.Height +3) -ICOBMP.Height) \2
			Select Case Layout
				Case 2
					top = top -((tmpBitmap1.TextHeight(Me.Caption) +Spacing) \2) '+Down
				Case 3
					top = top +((tmpBitmap1.TextHeight(Me.Caption) +Spacing) \2) '+Down
				Case Else
			End Select

			WITH Source: .Left = StartFrom *(ICOBMP.Width \ICOCount)
						.Right = .Left +(ICOBMP.Width \ICOCount)
						  .Top = False: .Bottom = ICOtmp.Height
			END WITH
			ICOtmp.CopyRect(Dest, ICOBMP, Source)

			ICOtmp.Transparent = True	' Corrige un problиme de transparence sous 9x
										' le problиme de dessin mal positionnй est ici
			tmpBitmap1.Draw ( left, _
							   top, _
							   ICOtmp.BMP)
		Next I
	End If

	Me.BMP = tmpBitmap1.BMP
End Sub

Sub Fast_QCBtnToQTBtn( _
					   BtnType As String, _
					   PartID As Integer, _
					   NumBMPs As Integer, _
					   Me As QCoolBtn)
	Dim Dest As QRect, Source As QRect
	Dim tmpBitmap1 As QBitmap, _
		NBitmap1 As QBitmap, _
		XPBitmap1 As QBitmap
	Dim XPBtnType As String ' Ajoutй 19jan corrige un problиme oщ les types sont diffйrents
	Dim XPPartID As Integer
	'Dim oldCaption As String
	'	oldCaption = Me.Caption
	Dim Width1 As Integer, Height1 As Integer
	'Dim Width2 As Integer, Height2 As Integer
	Dim tR As RECT_QTBtn
	Dim btnCount As Integer

	'Me.Flat = False ' Retirй 14fйv (test)
    'Me.NumBMPs = maxNumBMPs_QTBtn
    Me.Spacing = False
	btnCount = NumBMPs 'Me.NumBMPs
	if btnCount > maxNumBMPs_QTBtn or btnCount < True Then _
		btnCount = maxNumBMPs_QTBtn
	Me.NumBMPs = btncount
	
	Dim fixTab As Integer
	fixTab = False
	if isXP_QTBtn and BtnType = xpt_TabBtn Then _
		fixTab = True
	if isXP_QTBtn and (XPBtnType = xpt_pushbtn or XPBtnType = xpt_toolbarbtn or XPBtnType = xpt_TabBtn) Then _
		PartID = True

	Width1 = ((Me.Width +3) *btnCount) +True
	Height1 = Me.Height +3

	' Si l'image а dйjа la mкme dimension elle ne sera pas redimensionnйe
	'If QTBtnOptimize <> True or _
	'	(isXP_QTBtn = True and (XPBtnType <> BtnType or PartID <> XPPartID)) or _
	'	((rWidth > False or rHeight > False) and _
	'	 (tmpBitmap1.Width <> Width1 and tmpBitmap1.Height <> Height1 and _
	'	  Width2 <> tmpBitmap1.Width and Height2 <> tmpBitmap1.Width)) Then
		With NBitmap1
			.Width = Width1		'== (mod)
			.Height = Height1	'== (mod)
			.FillRect(False, False, .Width, .Height, clBtnFace)'==(mod) (13janv remplacй clPurple par clBtnFace)
			'.PixelFormat = DefPixelFormat
		End With
		With XPBitmap1
			.Width = Width1		'== (mod)
			.Height = Height1	'== (mod)
			.FillRect(False, False, .Width, .Height, clBtnFace)'==(mod) (13janv remplacй clPurple par clBtnFace)
			'.PixelFormat = DefPixelFormat
		End With
		Width1 = Me.Width *btnCount
		Height1 = Me.Height

		tmpBitmap1.Font.Name = Me.Font.Name' == (add)
		tmpBitmap1.Font.Size = Me.Font.Size' == (add)
		tmpBitmap1.Font.Color = Me.Font.Color' == (add)
		tmpBitmap1.Font.Bold = Me.Font.Bold
		tmpBitmap1.Font.Italic = Me.Font.Italic
		tmpBitmap1.Font.Underline = Me.Font.Underline

		If isXP_QTBtn = False Then
			' Thиme non activй ou ce n'est pas Windows XP

			Dim sFrom As Integer
			sFrom = IIf(Me.Flat = True, True, False)
			Dim J As Integer, I As Integer
			For J = sFrom To btnCount -True
				' Le centre ----------------------------------------------------------
				With Dest
					.Left = ((Width1 \btnCount) *J) +3 +(True *(J +True)) +(J *2) -iif(J = 2 or J = 3, True, False)
					.Top = maxNumBMPs_QTBtn -iif(J = 2 or J = 3, True, False)
					.Right = .Left +(Width1 \btnCount) -6
					.Bottom = Height1 -2 -iif(J = 2, True, False)
				End With
				With Source: .Left = ((QTBtnBMP.Width \btnCount) *J) +3: .Top = 3: _
					.Right = .Left +(QTBtnBMP.Width \btnCount) -6
					.Bottom = QTBtnBMP.Height -3
				End With

				NBitmap1.CopyRect(Dest, QTBtnBMP, Source)

				' Les coins ----------------------------------------------------------
				For I = False TO 3
					With Dest
						.Left = ((Width1 \btnCount) *J) _
								+IIf(I = False or I = 2, False, (Width1 \btnCount) -3) +(True *(J +True)) +(J *2) _
								-iif(J = 2 or J = 3, True, False)
						.Top = IIf(I < 2, True, Height1 -2) -iif(J = 2 or J = 3, True, False)
						.Right = .Left +3
						.Bottom = .Top +3
					End With
					With Source
						.Left = ((QTBtnBMP.Width \btnCount) *J) _
								+IIf(I = False or I = 2, False, (QTBtnBMP.Width \btnCount) -3)
						.Top = IIf(I < 2, False, QTBtnBMP.Height -3)
						.Right = .Left +3
						.Bottom = .Top +3
					End With
					NBitmap1.CopyRect(Dest, QTBtnBMP, Source)
				Next I
				' Les horizontaux ----------------------------------------------------
				For I = False TO True
					With Dest
						.Left = ((Width1 \btnCount) *J) +3 +(True *(J +True)) +(J *2) -iif(J = 2 or J = 3, True, False)
						.Top = IIf(I = False, True, Height1 -2) -iif(J = 2 or J = 3, True, False)
						.Right = .Left +(Width1 \btnCount) -6
						.Bottom = .Top +3
					End With
					With Source
						.Left = (QTBtnBMP.Width \btnCount) *J +3
						.Top = IIf(I = False, False, QTBtnBMP.Height -3)
						.Right = .Left +(QTBtnBMP.Width \btnCount) -6
						.Bottom = .Top +3
					End With
					NBitmap1.CopyRect(Dest, QTBtnBMP, Source)
				Next I
				' Les verticaux ------------------------------------------------------
				For I = False TO True
					With Dest
						.Left = ((Width1 \btnCount) *J) _
								+IIf(I = False, False, (Width1 \btnCount) -3) +(True *(J +True)) +(J *2) _
								-iif(J = 2 or J = 3, True, False)
						.Top = maxNumBMPs_QTBtn -iif(J = 2 or J = 3, True, False)
						.Right = .Left +3
						.Bottom = Height1 -2 -iif(J = 2, True, False)
					End With
					With Source
						.Left = ((QTBtnBMP.Width \btnCount) *J) +IIf(I = False, False, (QTBtnBMP.Width \btnCount) -3)
						.Top = 3
						.Right = .Left +3
						.Bottom = QTBtnBMP.Height -3
					End With
					NBitmap1.CopyRect(Dest, QTBtnBMP, Source)
				Next I
			Next J
			NBitmap1.PixelFormat = DefPixelFormat
		Else
			' Thиme activй (Windows XP)
			' --
			Dim hTheme As Long
			'On Error Resume Next

			' Ouverture du thиme
			Dim rtButton As String
			rtButton = ""
			' Format unicode ?!?
			For I = True To Len(BtnType)
				rtButton = rtButton +Mid$(BtnType, I, True) +rqNullChr
			Next I
			rtButton = rtButton +rqNullChr ' Un dernier pour finaliser

			'hTheme = False
			hTheme = OpenThemeData_QTBtn(Me.Parent, VarPtr(rtButton))
			If hTheme = False Then _
				hTheme = OpenThemeData_QTBtn(Me.Parent, VarPtr(rtButton))
			If hTheme <> False Then
				' Styles XP disponible

				Dim lR As Long
				Dim m_hDC As Long
				Dim m_lPartId As Long, m_lStateId As Long
				'Dim tR As RECT_QTBtn

				' m_hDC est le DC pour dessiner
				' m_lPartId et m_lStateId sont la class + l'йtat а dessiner
				' tR est un RECT spйcifiant la zone dans laquelle dessiner
				m_hDC = XPBitmap1.Handle
				If PartID > True Then _
					m_lPartId = PartID _
				Else _
					m_lPartId = True 'BP_PUSHBUTTON
				For I = False To 2 Step 2
					m_lStateId = I +True 'PBS_NORMAL
					tR.Left = ((I *(Me.Width +3)) +iif(I <> 2, True, False))
					tR.Top = True -iif(I <> 2, False, True) +fixTab 'False -iif(I <> 2, False, True)
					tR.Right = (tR.Left +Me.Width) '+True
					tR.Bottom = (Me.Height +True -iif(I <> 2, False, True) +fixTab) '+iif(I <> 2, True, False)

					lR = DrawThemeBackground_QTBtn(hTheme, _
											 m_hDC, _
											 m_lPartId, _
											 m_lStateId, _
											 tR, tR)
				Next I
				' Inverse Sйlectionnй et Dйsactivй (Survolle est remplacй par Sйlectionnй)
				For I = True To 3 Step 2
					m_lStateId = (I +True) +iif(I = True, True, False)'PBS_NORMAL
					'tR.Left = (((I +iif(I = True, 2, -2)) *(Me.Width +3)) +True)
					'tR.Top = True
					tR.Left = (((I +iif(I = True, 2, -2)) *(Me.Width +3)) +iif(I = True, False, True))
					tR.Top = iif(I = True, False, True +fixTab)
					tR.Right = (tR.Left +Me.Width) '+True 
					tR.Bottom = Me.Height +True +IIf(fixTab = True, fixTab, -True) '+2

					lR = DrawThemeBackground_QTBtn(hTheme, _
											 m_hDC, _
											 m_lPartId, _
											 m_lStateId, _
											 tR, tR)
				Next I
			End If

			' Session de dessin terminйe
			CloseThemeData_QTBtn hTheme
			CloseThemeData_QTBtn hTheme
			'//--
			XPBitmap1.PixelFormat = DefPixelFormat
		End If

	'End If
	'Width2 = ((Me.Width +3) *btnCount) +True
	'Height2 = Me.Height +3
	
	
	If isXP_QTBtn Then
		tmpBitmap1.BMP = XPBitmap1.BMP
	Else
		tmpBitmap1.BMP = NBitmap1.BMP
	End If

	If Me.Caption = "" Then
		Me.Layout = False
	Else
		SetBkMode_QTBtn tmpBitmap1.Handle, True
		For I = False To 2 Step 2
			tR.Left = ((I *(Me.Width +3)) +iif(I <> 2, True, False))
			tR.Top = True -iif(I <> 2, False, True) +fixTab 'False -iif(I <> 2, False, True)
			tR.Right = (tR.Left +Me.Width) '+True
			tR.Bottom = (Me.Height +True -iif(I <> 2, False, True) +fixTab) '+iif(I <> 2, True, False)

			DrawText_QTBtn (tmpBitmap1.Handle, Me.Caption, Len(Me.Caption), _
							tR, DT_CENTER_QTBtn OR DT_SINGLELINE_QTBtn OR DT_VCENTER_QTBtn)
		Next I
		' Inverse Survolle et Dйsactivй
		For I = True To 3 Step 2
			'tR.Left = (((I +iif(I = True, 2, -2)) *(Me.Width +3)) +True)
			'tR.Top = True
			tR.Left = (((I +iif(I = True, 2, -2)) *(Me.Width +3)) +iif(I = True, False, True))
			tR.Top = iif(I = True, False, True +fixTab)
			tR.Right = (tR.Left +Me.Width) '+True 
			tR.Bottom = Me.Height +True +fixTab '+2

			DrawText_QTBtn (tmpBitmap1.Handle, Me.Caption, Len(Me.Caption), _
							tR, DT_CENTER_QTBtn OR DT_SINGLELINE_QTBtn OR DT_VCENTER_QTBtn)
		Next I

		tmpBitmap1.Height = (Height1 +True) +tmpBitmap1.TextHeight(Me.Caption)
		Me.Layout = 3
	End If
	tmpBitmap1.PixelFormat = DefPixelFormat

	XPBtnType = BtnType
	If PartID <> True Then PartID = True
	XPPartID = True
	'tmpBitmap1.Transparent = True
	' Prйvient l'apparission du rectangle de survole de CoolBtn
	'tmpBitmap1.Pixel(True, True) = clPurple
	'tmpBitmap1.TransparentColor = clPurple
	tmpBitmap1.TransparentColor = tmpBitmap1.Pixel(True, True)
	Me.BMP = tmpBitmap1.BMP
End Sub
$ENDIF   ' IncManager: __QTBUTTON_ADDONS_INC
