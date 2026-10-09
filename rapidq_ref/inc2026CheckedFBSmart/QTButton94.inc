' Créé par D-évolution / Created by D-evolution -=@=- 2004 - 2005

' Pour plus de détail sur l'utilisation de ce composant reportez vous
' à la documentation fournise... (QTButton.html)
' For more details on using this component please refer to the doc
' (QTButton.html)

'$REsource btn_BMP As "_RES\Boutons.bmp"
$Option Explicit

' Vous pouvez tricher ce composante par la même astuce utilisé ici 


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

'Liste de tous les btns de type QTButton créés lors du chargement
Dim AllQTBtnsHandle As QStringList, AllQTBtnsGrouped As QStringList
'
Dim AllQTBtnsRequester As Long, AllQTBtnsRequesterParent As Long
	AllQTBtnsRequester			= False	' Btn appelant
	AllQTBtnsRequesterParent	= False	' Parent du btn appelant

$IFNDEF __QTBTNSHARED94
$DEFINE __QTBTNSHARED94

Const rqNullChr = CHR$(0)
Const rqSL		= CHR$(10)

Const DefPixelFormat = 4

'Accélère l'affichage des btns à l'écran maintenant jusqu'à 97% avec un affichage 
'parfait de 60% dans le cas où certains btns ont des dimensions différentes sinon 
'ça grimpe jusqu'à 100%
'Dans l'événement OnShow de votre fenêtre ajoutez ShowMessage STR$(DrawCount)
'pour afficher le nombre de fois où les btns ont eus à être RePaint 
'Note :  certains btns auront toute fois besoin d'être redessinés...
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

' -- Retiré 31déc
'Const BM_SETSTATE_QTBtn = &HF3
'Const WM_LBUTTONDOWN_QTBtn = &H201
' //--
Const WM_LBUTTONUP_QTBtn = &H202
Const WM_MOUSELAST_QTBtn = &H209


Declare Function SendMessage_QTBtn Lib "user32" Alias "SendMessageA" ( _
		ByVal hwnd As Long, _
		ByVal wMsg As Long, _
		ByVal wParam As Long, _
		lParam As Long) As Long

Declare Function IsWindowEnabled_QTBtn Lib "user32" Alias "IsWindowEnabled" _
		(ByVal hwnd As Long) As Long

'Declare Function LockWindowUpdate_QTBtn Lib "user32" Alias "LockWindowUpdate" _
'		(ByVal hwndLock As Long) As Long



'Declare Function GetDC Lib "user32" Alias "GetDC" _
'		(ByVal hwnd As Long) As Long
'Declare Function DrawFocusRect Lib "user32" Alias "DrawFocusRect" _
'		(ByVal hdc As Long, lpRect As RECTAPI) As Long
'Declare Function GetWindowRect Lib "user32" Alias "GetWindowRect" _
'		(ByVal hwnd As Long, lpRect As RECTAPI) As Long

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

Declare Function GetNextDlgTabItem_QTBtn Lib "user32" Alias "GetNextDlgTabItem" ( _
		ByVal hDlg As Long, _
		ByVal hCtl As Long, ByVal bPrevious As Long) As Long
Declare Function SetFocus_QTBtn Lib "user32" Alias "SetFocus" _
		(ByVal hwnd As Long) As Long
Declare Function GetParent_QTBtn Lib "user32" Alias "GetParent" _
		(ByVal hwnd As Long) As Long
Declare Function GetFocus_QTBtn Lib "user32" Alias "GetFocus" () As Long

Sub NextDlg_QTBtn(NextPrevTab As Long)'(CtrlHwnd As Long)
	Dim hwnd5 As Long, hwnd6 As Long
	ReleaseCapture_QTBtn
	hwnd6 = GetFocus_QTBtn()
	hwnd5 = GetNextDlgTabItem_QTBtn(GetParent_QTBtn(hwnd6),hwnd6, NextPrevTab)

	Call SetFocus_QTBtn(hwnd5)
End Sub

Declare Function GetSystemMetrics Lib "user32" Alias "GetSystemMetrics" _
    (ByVal nIndex As Long) As Long

    
' --	Redessine la région d'un contrôle (ComboBox)
Const RGN_AND	= 1
Const RGN_OR	= 2
Const RGN_XOR	= 3
Const RGN_DIFF	= 4

Declare Function CreateRectRgn_QTBtn Lib "gdi32" Alias "CreateRectRgn" ( _
		ByVal X1 As Long, _
		ByVal Y1 As Long, _
		ByVal X2 As Long, _
		ByVal Y2 As Long) As Long
Declare Function SetWindowRgn_QTBtn Lib "user32" Alias "SetWindowRgn" ( _
		ByVal hWnd As Long, _
		ByVal hRgn As Long, _
		ByVal bRedraw As Integer) As Long
Declare Function DeleteObject_QTBtn Lib "gdi32" Alias "DeleteObject" ( _
		ByVal hObject As Long) As Long

Sub HideBevelTrick_QTBtn(Sender As QButton, BevelWidth As Integer)
	' Ajouter RndRgn
    Dim rectRgn As Long

    ' Création des régions temporaires
    rectRgn	= CreateRectRgn_QTBtn(	BevelWidth, _
    								BevelWidth, _
    								Sender.Width -BevelWidth, _
    								Sender.Height -BevelWidth )
    DeleteObject_QTBtn SetWindowRgn_QTBtn( Sender.Handle, rectRgn, True )

    ' nettoyage de nos ressources
    DeleteObject_QTBtn rectRgn
End Sub
' //--


' -- Restauré 11janv (Retiré 31déc)
' Vérifie la version de Windows puisque certains problèmes sont identifiés
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
' //--

Declare Sub BMPStretch_Property( _
								XPThemeEnabled As Integer, _
								XPThemeWasEnabled As Integer, _
								BtnType As String, _
								BtnTypeWas As String, _
								HideBevelSize As Integer, _
								Sender As QButton)
'Declare Sub Fast_QBtnToQTBtn( _
'							 BtnType As String, _
'							 Sender As QButton)
'Declare Sub Fast_QCBtnToQTBtn( _
'							 BtnType As String, _
'							 Sender As QCoolBtn)

Sub FixKind_QTBtn (oldvalue as integer, Sender As QButton)
	Sender.NumBMPs = oldvalue
End Sub

' Event Template pour les nouveaux événements MouseLeave et MouseEnter
DECLARE SUB QTBtnOnMouseEnterLeave_EventTemplate (X As Integer, Y As Integer, Shift As Integer, Sender As QButton)

' Lorsque GroupIndex = 0 il doit être nettoyé s'il est présent dans la liste
Sub SetIndex_QTBtn (Index As Integer, Hwnd As Long)
	AllQTBtnsHandle.AddItems STR$(Hwnd)
	AllQTBtnsGrouped.AddItems STR$(Index)

'	If AllQTBtnsGrouped.ItemCount <> AllQTBtnsHandle.ItemCount Then ShowMessage "Erreur"
End Sub

' Déplacé 12janv afin de réduire le code
Sub	QTButton_KeyDown (Key AS Word, Shift AS INTEGER)
	If RequestRelease = False Then
		Select Case Key
			Case 40, 39, 9: Call NextDlg_QTBtn(True)	' Avance
			Case 38, 37: Call NextDlg_QTBtn(False)		' Recule
			Case Else
				'ShowMessage STR$(Key)
		End Select
	End If

	RequestRelease = True
End Sub
' //

dim rWidth as integer, _
	rHeight as integer
rWidth = 75
rHeight = 25


Type QTButton Extends QButton
  'YRESTE/TODO
	'-Fonction spécial transforme QButton en QTButton appelle un SUB qui applique les mêmes
	' propriétés que QTButton à QButton, utile pour les tableaux
	'-Corriger: Lorsque Kind n'est pas Faux et que Caption = "" le btn est mal dessiné
	'!Ajouté: Propriété de XPThemeBtnType (Sélectionnez entre 3 type de bouton; classic, barre d'outil, onglet)
	'!Corrigé: problèmes positionnement et de transparence pour certains thèmes de bureau
	'!Ajouté/Corrigé: Propriété de XPThemeEnabled (Active et désactive le theme)
	'!Ajouté/Amélioré: support des thèmes de bureau XP (Passé de Resource à l'API OpenThemeData)
	'!Remplacé certains CopyRect par StretchDraw c'est le cas pour l'effet Survole
	'!Corrigé: problème lorsque l'option Down d'un btn est vrai, l'icône est dessinée deux fois
	'Ajouter annuler l'effet enfoncé de l'icône
	'Ajouter réagit en tant que btn de barre d'outil (le focus est restauré à son ancien propriétaire)
	'!-Corriger: Effet de rafraîchissement causé par GroupIndex
	'!Ajouté: Icon/BMP
	'!Ajouté: Propriété de NumBMPs
	'!Ajouté: Propriété de NumICOBMPs (indique le nombre d'image dans l'icone)
	'!Ajouté: Propriété de Layout
	'!Ajouté: Propriété de Spacing
	'Ajouter: Evénement Default (onshow la souris pointe le btn... setfocus)
	'	Peut-être ajouter une méthode pour automatiser le procèssuce
	'!Réparé: Caption
	'!Ajouté: Sous-lignage de la lettre dans BMPBtn; ex: "Dé&faut"
	'!Amélioré/ReCorrigé: & et && dans le caption; 1 souligne, 2 donnent & sans souligner
	'!Corrigé: Un API vient corriger le problème avec TextRect et TextOut _
	'   (TextRect n'aime pas les bounds)
	'!Corrigé: Effet de Sous-lignage appuyer sur Alt+ChrSouligné = clic
	'!Corrigé: Propriété de Height et Width
	'!Corrigé: Survole lorsque le nombre de btn est inférieur à 4
	'!Corrigé: Survole lors d'un clique
	'-Inverser: Enfoncé et Désactivé dans le fichier BMP
	'!Corrigé: Lorsque le nombre de btns excède 4 (NumBMPs)
	'!Amélioré/Ajouté: Lignes Multiples basique (insèrez chr$(10) ou "\n" pour créer une nouvelle ligne)
	'-Ajouter: HideCaption, pour afficher une icône et masquer le texte (coolbtn like)
	'Corriger/Ajouter: propriété de police (comment?)
	'	pour l'instant vous devrez utiliser ReDraw après avoir changé la police
	'	sinon je pourrais faire en sorte que QTBtn vérifie l'état de la police
	'	à chque action...
	'!Corrigé: lorsque la souris pointe le btn, le clavier ne répond plus
	'!Corrigé: Petit problème de positionement du texte
	'!Corrigé: Problème avec Enabled et la police lors de l'exécution
	'Corriger/Ajouter: Propriété de Visible (éviter de trop dessiner lorsqu'invisible)
	'Ajouter: AutoSize lorsque la taille du texte en pixel excède celle du bouton
	'Ajouter: Propriété de Parent pour être sure que l'enjolivure sera dessinée
	'Corriger: Propriété d'Align
	'!Ajouté: Groupe de bouton
	'Ajouter: AllowAllUp (si on clique sur un btn enfoncé du groupe, ils seront tous rétablis à la normal)
	'Ajouter: AllowDown (permet a un btn de garder son état enfoncé)
	'Ajouter: Lorsque GroupIndex > Faux et qu'on appuie sur une touche QTBtn tente de rejoindre
	'	le btn suivant (comme TabControl) 
	'
	'Quelques problèmes identifiés :
	'		 1) Problème introduit... lorsque la souris quitte le contrôle, il est mal redessiné... arrrg!
	'			Le problème vient de l'ordre dans lequel NumBMPs est introduit.
	'			Résolution: l'insèrer après les	paramètres de positionnement.
	'			(Semble être corrigé)
	'		 2) Lorsque le titre du btn est trop long, le reste du texte apparaît sur les divers
	'			effets, à savoir désactivé ,enfoncé, survollé. 	Ce problème vient du fait que je 
	'			n'arrive toujours pas à utiliser TextRect.
	'			Résolution: un API est utilisé pour corrigé ce problème
	'		 3) Parfois le btn n'est pas dessiné lorsque NumBMPs n'est pas spécifié, donc ne pas
	'			oublier de l'ajouter.
	'			Résolution: Left et Top devrait toujours être les premiers champs déclarés ensuit
	'						vient NumBMPs si le nombre est supérieur à 1, puis vient Height et Width
	'						etc...
	'		 4) Plus d'une fenêtre alors qu'un btn n'est toujours pas visible, aura d'étranges 
	'			résultats d'affichage pour ce btn, surtout en utilisant ShapeForm.
	'			Résolution: Dim DummyBtn As QTButton juste après la fenêtre
	'						DummyBtn.ReDraw durant le chargement de la form peut aussi aider
	'		 5) Problème de mémoire reliré à l'image du btn, il semble que l'image se pert en mémoire
	'			et peut se retrouver n'import où, les contrôles utilisant le mode OwnerDraw en
	'			seront grandement irrités...
	'			(J'essaie d'identifier le problème...)
	'						DummyBtn.ReDraw durant le chargement de la form peut aussi aider
	'		 6) Lorsque l'on définie Height ou Width sur le premier bouton il est mal dessiné
	'			Résolution: Placer temporairement btn.Redraw avant ou pendant l'affichage de la fenêtre 

  With This 'QTButton
   PRIVATE:
	cRect As RECT_QTBtn

	Dest	As QRECT
	Source	As QRECT
	BMPBtnClean As QBitmap	' Copie de l'image du bouton sans aucune modification
							' BMPtmp pourrait être ramplacé par BMPBtnClean
	BMPBtn	As QBitmap
	BMPtmp	As QBitmap		' Devrait reflété un seul btn, celui à réintégrer (normal, survole)
   PUBLIC:
	ICOBMP	As QBitmap		' la petite icône à afficher sur le btn

   PRIVATE:
	PropID		As Integer	' Qui appelle ReDraw
	BtnNeedDraw	As Integer	' Détermine si le btn doit être totallement redessiné
							' ou dans les cas de Caption, Layout, Spacing seule
							' la partie text doit être mise à jour...
	ActAsToolBar As Integer
	PrevFocus	As Long

	HideBevelSize As Integer

	XPThemeBtnTypeWas As String
	XPThemeWasEnabled As Integer
	' Property Set
   PUBLIC:
	XPThemeBtnType	As String Property Set SetXPThemeBtnType
	XPThemeEnabled	As Integer Property Set SetXPThemeEnabled

	Align		As Integer	Property Set SetAlign
	Caption 	As String	Property Set SetCaption
	Enabled 	As Integer	Property Set SetEnabled
	Down		As Integer	Property Set SetDown
	GroupIndex	As Integer	Property Set SetGroupIndex
	Kind		As Integer	Property Set SetKind
	Layout		As Integer	Property Set SetLayout
	Spacing		As Integer	Property Set SetSpacing
	Height		As Integer	Property Set SetHeight
	Width		As Integer	Property Set SetWidth
	NumBMPs		As Integer	Property Set SetNumBMPs
	NumICOBMPs	As Integer	Property Set SetNumICOBMPs

	' 14/15 déc
	FlickeringTrick As Integer	Property Set SetNewBtnRegion
	HideFocusRect As Integer Property Set SetHideFocusRect

	' EventTemplate
	OnMouseLeave AS EVENT(QTBtnOnMouseEnterLeave_EventTemplate)
	OnMouseEnter AS EVENT(QTBtnOnMouseEnterLeave_EventTemplate)

	'Nouvelles propriétés
	'qqchose as qqchose Property Set SetQqChose

	Function TextWidth(text as string) As Integer:	Result = .BMPBtn.TextWidth(text)
	End Function
	Function TextHeight(text as string) As Integer:	Result = .BMPBtn.TextHeight(text)
	End Function

	'Sub ResizeTo(Height As Integer, Width As Integer)
	'End Sub

   PRIVATE:
	Sub FixBtnSize
		If .Align <> False Then Exit Sub'!-- 22/08
		dim height as integer, width as integer
		height = super.height: width = super.width

		.height = height: .width = width
	End Sub

	Sub DrawCaption: Dim I As Integer
		.propID = False
		dim color as integer, left as integer, top as integer ', _
		dim capwidth as integer', noico as integer

		.BMPBtn.Font.Name = .Font.Name' == (add)
		.BMPBtn.Font.Size = .Font.Size' == (add)
		.BMPBtn.Font.Color = .Font.Color' == (add)
		.BMPBtn.Font.Bold = .Font.Bold
		.BMPBtn.Font.Italic = .Font.Italic
		.BMPBtn.Font.Underline = .Font.Underline

		'noico	= .ICOBMP.Empty
		color	= iif(super.enabled = 1, .font.color, -2147483631) 'clGrayText

		capwidth	= (.Width -( .TextWidth( Field$( .Caption, rqSL, True) ) )) \2

		If .ICOBMP.Empty = False Then
			.ICOBMP.PixelFormat = PixelFormatFix_QTBtn '.PixelFormat'when kind no prob, when icobmp big prob
			.ICOBMP.Transparent = 1	'True
		End If

		dim startFrom as integer, endTo as integer
		if .Enabled = True then
			startFrom = False
			endTo = .NumBMPs -True
		else
			startFrom = True
			endTo = True
		end if

		Dim LineCount As Integer
		Dim Down As Integer
		If .Caption <> "" Then
			For I = startFrom To endTo step 2
				If I = False And .Down = True Then _
					 Down = True _
				Else Down = False

				.cRect.Left = (I *(.Width +3)) +True +Down
				.cRect.Top = True + Down	'iif(.Layout > True and .ICOBMP.Empty = False, _
											'	 iif(.Layout = 2, .ICOBMP.Height, -.ICOBMP.Height), _
											'	 False ) +True +Down
				.cRect.Right = .Width +.cRect.Left
				.cRect.Bottom = .Height +True
				If .ICOBMP.Empty = False Then
					Select Case .Layout
						Case True
							.cRect.Left = .cRect.Left -((.ICOBMP.Width \.NumICOBMPs) _
										  +.Spacing) +Down
						Case 2
							.cRect.Top = .cRect.Top +((.ICOBMP.Height +.TextHeight(.Caption)) \2) _
													+.Spacing +Down
						Case 3
							.cRect.Top = .cRect.Top -((.ICOBMP.Height +.TextHeight(.Caption)) \2) _
													+.Spacing +Down
						Case Else
							.cRect.Left = .cRect.Left +(.ICOBMP.Width \.NumICOBMPs) _
										  +.Spacing +Down
					End Select
				End If

				LineCount = Tally(.Caption, rqSL) +Tally(.Caption, "\n") +True
				'SetTextColor This.BMPBtn.Handle, clGrayText
				.BMPBtn.Font.Color = color
				SetBkMode_QTBtn This.BMPBtn.Handle, True
				If LineCount > True Then
					.cRect.Top = .cRect.Top +(((.Height -3 -True) -(.TextHeight(.Caption) *(LineCount -True))) /3)
					DrawText_QTBtn (This.BMPBtn.Handle, This.Caption, Len(This.Caption), _
									This.cRect, DT_CENTER_QTBtn)
				Else
					DrawText_QTBtn (This.BMPBtn.Handle, This.Caption, Len(This.Caption), _
									This.cRect, DT_CENTER_QTBtn OR DT_SINGLELINE_QTBtn OR DT_VCENTER_QTBtn)
				End If

			Next I
		End If
		' Fix Bug in Win9x where caption are draw in white color
		If .ICOBMP.Empty = False Then
			' -- déplacé
			Dim ICOtmp As QBitmap
			ICOtmp.Width = .ICOBMP.Width \.NumICOBMPs
			ICOtmp.Height = .ICOBMP.Height
			WITH Dest: .Left = False: .Right = ICOtmp.Width
						.Top = False: .Bottom = ICOtmp.Height
			END WITH
			' //-- déplacé
			For I = startFrom To endTo step 2
				left = iif(.Layout > True, .Width \2, capwidth)
				left = left +(I *(.Width +3)) +True _
					   +iif(.Layout < 2 and .Caption <> "", _
							iif(.Layout = False, -((.ICOBMP.Width \.NumICOBMPs) +.Spacing) \2, _
								(.ICOBMP.Width \.NumICOBMPs) \2), _
							-(.ICOBMP.Width \.NumICOBMPs) \2 -True)
				top = ((.Height +3) -.ICOBMP.Height) \2
				Select Case .Layout
					Case 2
						top = top -((.TextHeight(.Caption) +.Spacing) \2) +Down
					Case 3
						top = top +((.TextHeight(.Caption) +.Spacing) \2) +Down
					Case Else
				End Select

				WITH Source: .Left = I *(This.ICOBMP.Width \This.NumICOBMPs)
							.Right = .Left +(This.ICOBMP.Width \This.NumICOBMPs)
							  .Top = False: .Bottom = ICOtmp.Height
				END WITH
				ICOtmp.CopyRect(This.Dest, This.ICOBMP, This.Source)

				ICOtmp.Transparent = True	' Corrige un problème de transparence sous 9x
											' le problème de dessin mal positionné est ici
				.BMPBtn.Draw ( left, _
							   top, _
							   ICOtmp.BMP)
			Next I
		End If

		.BMP = .BMPBtn.BMP
	End Sub
   PUBLIC:
	Sub ReDraw
		' Liste propID
		' 1. Align
		' 2. Caption
		' 3. Down
		' 4. Enabled
		' 5. GroupIndex
		' 6./7. Height/Width
		' 8. Kind
		' 9. Layout
		' 10./11. Left/Top
		'12./13 NumBMPs/NumICOBMPs
		'14. Spacing
		'15./16. XPThemeEnabled/XPThemeBtnType
		Dim FastDraw As Integer
		FastDraw = False
		If .BtnNeedDraw = False and (_
			.propID = 2 or _
			.propID = 4 or _
			.propID = 5 or _
			.propID = 8 or _
			.propID = 9 or _
			.propID = 10 or _
			.propID = 11 or _
			.propID = 13 or _
			.propID = 14) Then
			.BMPBtn.BMP = .BMPBtnClean.BMP
			FastDraw = True
		End If
		.BtnNeedDraw = False
		.propID = False
		rWidth = Super.Width '.Width
		rHeight = Super.Height '.Height
		If .Width = False or .Height = False Then .FixBtnSize
		'LockWindowUpdate_QTBtn(This.Handle)

		Static checkICO As Integer
		If checkICO = False and .kind = False Then
			.ICOBMP.BMP = .BMP
			checkICO = True
		End If
		If .NumBMPs > maxNumBMPs_QTBtn Then .NumBMPs = maxNumBMPs_QTBtn
		If FastDraw = False Then
			BMPStretch_Property(This.XPThemeEnabled, This.XPThemeWasEnabled, _
								This.XPThemeBtnType, This.XPThemeBtnTypeWas, _
								This.HideBevelSize, _
								This)
			.BMPBtn.BMP = .BMP
			.BMPBtnClean.BMP = .BMPBtn.BMP
			.BMPBtn.PixelFormat = DefPixelFormat' == (add)
			.BMPBtn.TransparentColor = .BMPBtn.Pixel(True, True)
		End If
		.BMPBtn.PixelFormat = DefPixelFormat' == (add)
		.BMPBtn.TransparentColor = .BMPBtn.Pixel(True, True)' Ajouté 13janv (résou un problème de tranparence
															'				 avec certains thème de bureau
		If .Caption = "" Then
			  Super.Layout = 0 '1
		Else: .BMPBtn.Height = .BMPBtn.Height +.TextHeight(.Caption) +2
			  Super.Layout = 3
		End If

		.BMPtmp.Height = .BMPBtn.Height
		If FastDraw = False Then _
			.BMPBtnClean.Height = .BMPBtn.Height
		.DrawCaption ' // -- déplacé
		If .NumBMPs >= maxNumBMPs_QTBtn Then
			WITH Dest: .Left = False: .Right = (This.BMPBtn.Width -True) \This.NumBMPs
						.Top = False: .Bottom = This.BMPBtn.Height
			END WITH
			WITH Source: .Left = False: .Right = This.Dest.Right
						  .Top = False: .Bottom = This.BMPBtn.Height
			END WITH
			.BMPtmp.Width = .Dest.Right: .BMPtmp.Height = .BMPBtn.Height '.Dest.Bottom
			.BMPtmp.CopyRect(This.Dest, This.BMPBtn, This.Source)
		End If

		'.DrawCaption
		'LockWindowUpdate_QTBtn(False)
	End Sub
   PRIVATE:
	Sub DrawDownUp
		If .BtnNeedDraw Then .ReDraw
		If .NumBMPs >= 3 Then
			WITH Dest: .Left = This.Down: .Right = .Left +(This.BMPBtn.Width -True) \This.NumBMPs
					.Top = This.Down: .Bottom = .Top +This.BMPBtn.Height
			END WITH
			'WITH Source: .Top = False: .Bottom = This.BMPBtn.Height
			'END WITH
			If .Down = True Then
				' Btn enfoncé
				WITH Source: .Left = (This.Dest.Right -True) *2
							.Right = .Left +This.Dest.Right -True
						  	.Top = False: .Bottom = This.BMPBtn.Height  ' // -- Stretché lorsque Groupé
				END WITH
				.BMPBtn.CopyRect(This.Dest, This.BMPBtn, This.Source)
			Else
				' Btn normal
				'WITH Source: .Left = False: .Right = This.Dest.Right
				'END WITH
				'.BMPBtn.CopyRect(This.Dest, This.BMPtmp, This.Source)
				.BMPBtn.StretchDraw(This.Dest, This.BMPtmp.BMP)
			End If

			.BMP = .BMPBtn.BMP
			.DrawCaption
		End If
	End Sub

	Sub ReleaseHotTrack
		' le pseudo-evénement MOUSELEAVE
		ReleaseCapture_QTBtn
		' on retourne le caption à la normal
		'.Font.Bold = False
		.Font.Color = clBtnText
		'.caption = "Dehors..."
		'LockWindowUpdate_QTBtn(This.Handle)
		If .NumBMPs => maxNumBMPs_QTBtn and .Down = False Then
			WITH Dest: .Left = False: .Right = (This.BMPBtn.Width -True) \This.NumBMPs
						.Top = False: .Bottom = This.BMPBtn.Height
			END WITH
			'WITH Source: .Left = False: .Right = This.Dest.Right
			'			  .Top = False: .Bottom = This.BMPtmp.Height
			'END WITH
			'.BMPBtn.CopyRect(This.Dest, This.BMPtmp, This.Source)
			.BMPBtn.StretchDraw(This.Dest, This.BMPtmp.BMP)
			'.BMPBtn.Draw( False, False, This.BMPtmp)
		End If

		.DrawCaption
		'LockWindowUpdate_QTBtn(False)
	End Sub
   PUBLIC:
	'Event OnMouseDown(btn As Integer, X As Integer, Y As Integer, Shift As Integer)
	'	' Doit être hérité si ActAsToolBar est vrai
	'	If .ActAsToolBar = True and .PrevFocus <> False and _
	'		.PrevFocus <> .Handle and GetFocus_QTBtn() <> .PrevFocus Then
	'		$TypeCheck Off
	'		Call SendMessage_QTBtn(.Handle, &H8, True, ByVal 0&)
	'		$TypeCheck On
	'		'Call SetFocus_QTBtn(.PrevFocus)
	'	End If
	'End Event
	'Event OnClick'(btn As Integer, X As Integer, Y As Integer, Shift As Integer)
	'	' Doit être hérité si ActAsToolBar est vrai
	'	If .ActAsToolBar = True and .PrevFocus <> False and _
	'		.PrevFocus <> .Handle and GetFocus_QTBtn() <> .PrevFocus Then
	'		$TypeCheck Off
	'		Call SendMessage_QTBtn(.Handle, &H8, True, ByVal 0&)
	'		$TypeCheck On
	'		'Call SetFocus_QTBtn(.PrevFocus)
	'	End If
	'End Event
	Event OnMouseUp(btn As Integer, X As Integer, Y As Integer, Shift As Integer)
		.ReleaseHotTrack
		'If .ActAsToolBar = True and .PrevFocus <> False and _
		'	.PrevFocus <> .Handle and GetFocus_QTBtn() <> .PrevFocus Then _
		'	Call SetFocus_QTBtn(.PrevFocus)

		' fait parti d'un groupe ?
		If .GroupIndex > False Then
			If AllQTBtnsRequester = False and btn = False Then
				Static currHwnd As Long

				Dim I As Integer
				' identifie le button qui appelle tous les autres
				AllQTBtnsRequester = .Handle
				' identifie le Parent du groupe appellé, comme ça si deux groupes ont le même
				' indentifiant mais pas le même parent, seul les btns du groupe ayant le parent 
				' conrrespondant seront appelés.
				If AllQTBtnsRequesterParent = False Then _
					AllQTBtnsRequesterParent = GetParent_QTBtn(This.Handle)
				'ShowMessage STR$(AllQTBtnsRequesterParent)

				For I = False To AllQTBtnsHandle.ItemCount -True
					'If AllQTBtnsGrouped.Item(AllQTBtnsHandle.IndexOf(STR$(.Handle))) > False and _
					If	VAL(AllQTBtnsGrouped.Item(I)) = .GroupIndex and _
						GetParent_QTBtn(VAL(AllQTBtnsHandle.Item(I))) = AllQTBtnsRequesterParent Then
						' retrouve l'handle du btn
						' get the handle of that button
						currHwnd = VAL(AllQTBtnsHandle.Item(I))

						If IsWindowEnabled_QTBtn(currHwnd) = True Then
							If currHwnd <> .Handle Then

								$TypeCheck Off
								' restaure le dernier état du btn à la normal
								' restore the last button state to normal
								'Call SendMessage_QTBtn(.Handle, WM_LBUTTONDOWN_QTBtn, False, ByVal 0&)
								' et envoit les msgs enfoncé/terminé de la souris pour lancer
								' l'événement clic du btn, et indique visiblement sont état enfoncé
								' and send mouse down and up messages to fire its click event, 
								' and visibly indicate its pressed state.
								'Call SendMessage_QTBtn(currHwnd, WM_LBUTTONDOWN_QTBtn, False, ByVal 0&)
								Call SendMessage_QTBtn(currHwnd, WM_LBUTTONUP_QTBtn, False, ByVal 0&)
								'Call SendMessage_QTBtn(currHwnd, BM_SETSTATE_QTBtn, 1, ByVal 0&)
								'Call SendMessage_QTBtn(currHwnd, BM_SETSTATE_QTBtn, False, ByVal 0&)
								Call SendMessage_QTBtn(currHwnd, WM_MOUSELAST_QTBtn, False, ByVal 0&)
								$TypeCheck On

								'SetFocus_QTBtn(This.Handle)
							ElseIf currHwnd = .Handle Then
								.Down = True
							End If
						End If

					End If
				Next I
				' redonne le focus au btn appellant
				If .ActAsToolBar = False Then _
					SetFocus_QTBtn(.Handle)

				currHwnd = False
				AllQTBtnsRequester = False
				AllQTBtnsRequesterParent = False
				.DrawDownUp
			ElseIf (AllQTBtnsRequester <> False and AllQTBtnsRequester <> .Handle) and _
				GetParent_QTBtn(This.Handle) = AllQTBtnsRequesterParent Then
				If VAL(AllQTBtnsGrouped.Item(AllQTBtnsHandle.IndexOf(STR$(AllQTBtnsRequester)))) = .GroupIndex and _
					.Down = True Then
					.Down = False
					.DrawDownUp
				End If
			End If
		End If
		'Dim rc3 As RECTAPI
		'Call GetWindowRect_QTBtn(This.Handle, rc3)
		'rc3.right = rc3.right -10
		'Call DrawFocusRect_QTBtn(GetDC_QTBtn(This.Handle), rc3)
	End Event
   PRIVATE:
	Event OnMouseMove(X As Integer, Y As Integer, Shift As Integer)
		Static PosX As Integer, PosY As Integer

		If .ActAsToolBar = True and GetFocus_QTBtn() <> .Handle Then _
			.PrevFocus = GetFocus_QTBtn()

		WITH Dest: .Left = False: .Right = (This.BMPBtn.Width -True) \This.NumBMPs
					.Top = False: .Bottom = This.BMPBtn.Height
		END WITH

		If (X < False) Or (Y < False) Or _
			(X > .Width) Or (Y > .Height) Then
			.ReleaseHotTrack
			CALLFUNC(.OnMouseLeave, X, Y, Shift, This)
		ElseIf (GetCapture_QTBtn() <> .Handle) and (RequestRelease = False _
			 and PosX <> X and PosY <> Y) Then
			' Verifie si la requete de relâcher la capture d'un QTBtn est 0
			' Check if the release capture request for QTBtn is 0
			' 
			' Ce qui va aussi empêcher le btn de reprendre son état initial
			' lors d'une action...
			PosX = X
			PosY = Y

			'LockWindowUpdate_QTBtn(This.Handle)
			' le pseudo-evénement MOUSEENTER
			SetCapture_QTBtn .Handle
			' on met le caption en gras
			'.Font.Bold = True
			.Font.Color = clHilight
			'.caption = "Dessus..."
			If .NumBMPs => maxNumBMPs_QTBtn and .Down = False Then
				WITH Source: .Left = This.Dest.Right *(This.NumBMPs -True)
							.Right = .Left +This.Dest.Right
							  .Top = False: .Bottom = This.BMPBtn.Height
				END WITH
				.BMPBtn.CopyRect(This.Dest, This.BMPBtn, This.Source)
			End If

			.DrawCaption
			'LockWindowUpdate_QTBtn(False)
			CALLFUNC(.OnMouseEnter, X, Y, Shift, This)
		ElseIf RequestRelease = True Then	' Corrige l'état survolle du btn
											' Fix Hot state of btn
			.ReleaseHotTrack
		End If
		If (PosX <> X and PosY <> Y) Then RequestRelease = False	' Restaure la requête à 0
							  										' Reset release request
	End Event
   PUBLIC:
	' -- 12 janv (déplacé)
	'Event OnKeyDown(Key AS Word, Shift AS INTEGER)
	'	'.ReleaseHotTrack
	'	If RequestRelease = False Then
	'		Select Case Key
	'			Case 40, 39, 9: Call NextDlg_QTBtn(True)	' Avance
	'			Case 38, 37: Call NextDlg_QTBtn(False)		' Recule
	'			Case Else
	'		End Select
	'	End If

	'	RequestRelease = True
	'End Event
	' //--

	'Property Set SetAlign (lpalign as integer)
	'	.Align = lpalign: Super.Align = lpAlign
	'	.ReDraw
	'End Property
	Property Set SetLayout (lplayout as integer)
		.Layout = lplayout': Super.Layout = lplayout
		.propID = 14
		If .BtnNeedDraw Then
			.ReDraw
		Else
			.DrawCaption
		End If
	End Property
	Property Set SetSpacing (lpspacing as integer)
		.Spacing = lpspacing': Super.Layout = lplayout
		.propID = 9
		If .BtnNeedDraw Then
			.ReDraw
		Else
			.DrawCaption
		End If
		'.ReDraw '.DrawCaption '.ReDraw
	End Property
	Property Set SetCaption (lpcaption as string)
		.Caption = lpCaption
		.Caption = ReplaceSubStr$(.Caption, "\n", rqSL)
		Super.Caption = lpcaption -chr$(10) -chr$(13) -"\n"
		.propID = 2
		.ReDraw
	End Property
	Property Set SetEnabled (lpenabled as integer)
		Super.Enabled = lpenabled: .Enabled = lpenabled 
		.propID = 4
		If .BtnNeedDraw Then
			.ReDraw
		Else
			.DrawCaption
		End If
	End Property
	Property Set SetHeight (lpheight as integer)
		'.ReleaseHotTrack
		.Height = lpheight: Super.Height = lpheight
		.propID = 6
		.ReDraw
	End Property
	Property Set SetWidth (lpwidth as integer)
		.Width = lpwidth: Super.Width = lpwidth
		.propID = 7
		.ReDraw
	End Property
	Property Set SetNumBMPs (lpnumbmps as integer)
		.NumBMPs = lpnumbmps: Super.NumBMPs = lpnumbmps
		.propID = 12
		.ReDraw
	End Property
	Property Set SetNumICOBMPs (lpnumicobmps as integer)
		.NumICOBMPs = lpnumicobmps
		.propID = 13
		If .BtnNeedDraw = False Then
			.ReDraw
		Else
			.DrawCaption'ReDraw'==(mod)
		End If
	End Property
	Property Set SetKind (lpkind as integer)
		Dim numbmps as integer
		numbmps = .NumBMPs
		If lpKind > False Then
			.Kind = lpkind: Super.Kind = lpkind
			.NumICOBMPs = 2
			.ICOBMP.BMP = .BMP
		End If
			
		Call FixKind_QTBtn (numbmps, This)
		.propID = 8
		.ReDraw
	End Property
	Property Set SetGroupIndex (lpIndex As Integer)
		.GroupIndex = lpIndex
		Call SetIndex_QTBtn(lpIndex, .Handle)
	End Property
	Property Set SetDown (lpDown As Integer)
		.Down = lpDown
		.propID = 3
		.DrawDownUp
	End Property
	Property Set SetXPThemeEnabled(lpEnabled As Integer)
		.XPThemeEnabled = lpEnabled
		.propID = 15
		If .XPThemeEnabled <> .XPThemeWasEnabled Then _
			.ReDraw
		.XPThemeWasEnabled = lpEnabled
	End Property
	Property Set SetXPThemeBtnType(lpBtnType As String)
		.XPThemeBtnType = lpBtnType
		.propID = 16
		If (.XPThemeBtnType <> .XPThemeBtnTypeWas) and _
			.XPThemeEnabled = True Then _
			.ReDraw
		.XPThemeBtnTypeWas = lpBtnType
	End Property
	Property Set SetNewBtnRegion(lpnewregion As Integer)
		.FlickeringTrick = lpnewregion
		If .FlickeringTrick > False Then
			HideBevelTrick_QTBtn(This, 2)
			.HideBevelSize = 2 'True
		End If
	End Property
	Property Set SetHideFocusRect(lpnewregion As Integer)
		.HideFocusRect = lpnewregion
		If .HideFocusRect > False Then
			HideBevelTrick_QTBtn(This, 5)
			.HideBevelSize = 5
		End If
	End Property

	Constructor
		BtnNeedDraw = True
		XPThemeEnabled = True
		XPThemeWasEnabled = True
		XPThemeBtnType = xpt_PushBtn
		XPThemeBtnTypeWas = xpt_PushBtn
		BMPtmp.PixelFormat = DefPixelFormat
		BMPBtn.PixelFormat = DefPixelFormat
		Spacing = maxNumBMPs_QTBtn
		Enabled = True
		NumBMPs = True
		NumICOBMPs = True
		Layout = False
		Down = False
		
		'FixBtnSize
		OnKeyDown = QTButton_KeyDown
	End Constructor
  End With
End Type


'Private:
' Reduit la taille du code dans l'application
Dim DrawCount As Integer
Sub BMPStretch_Property

	' Pour corriger .Align
	'If Sender.Align <> False Then ...
	'	Call ClientRect API to Find parent width and height
	'End If

	Dim Dest As QRect, Source As QRect
	Dim Bitmap1 As QBitmap, _
		XPBitmap1 As QBitmap
	Dim XPBtnType As String ' Ajouté 19jan corrige un problème où les types sont différents
	Dim Width1 As Integer, Height1 As Integer
	Dim Width2 As Integer, Height2 As Integer
	Dim btnCount As Integer

	btnCount = Sender.NumBMPs
	if btnCount > maxNumBMPs_QTBtn Then
		btnCount = maxNumBMPs_QTBtn
		sender.numbmps = btncount
	end if

	Width1 = ((Sender.Width +3) *btnCount) +True
	Height1 = Sender.Height +3
	DoEvents
	' Si l'image à déjà la même dimension elle ne sera pas redimensionnée
	'If QTBtnOptimize <> True or (Width2 <> Width1 and Height2 <> Height1) Then
	If QTBtnOptimize <> True or _
		(XPThemeEnabled <> XPThemeWasEnabled) or _
		((BtnType <> BtnTypeWas) and XPThemeEnabled = True) or _
		((XPBtnType <> BtnType) and XPThemeEnabled = True) or _
		((rWidth > False or rHeight > False) and _
		 (Bitmap1.Width <> Width1 and Bitmap1.Height <> Height1 and _
		  Width2 <> Bitmap1.Width and Height2 <> Bitmap1.Width)) Then
		DrawCount ++
		With Bitmap1
			.Width = Width1		'== (mod)
			.Height = Height1	'== (mod)
			.FillRect(False, False, .Width, .Height, clBtnFace)'==(mod) (13janv remplacé clPurple par clBtnFace)
			'.PixelFormat = DefPixelFormat
		End With
		With XPBitmap1
			.Width = Width1		'== (mod)
			.Height = Height1	'== (mod)
			.FillRect(False, False, .Width, .Height, clBtnFace)'==(mod) (13janv remplacé clPurple par clBtnFace)
			'.PixelFormat = DefPixelFormat
		End With
		Width1 = Sender.Width *btnCount
		Height1 = Sender.Height

		If XPThemeEnabled = False or isXP_QTBtn = False Then
			' Thème non activé ou ce n'est pas Windows XP

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

				Bitmap1.CopyRect(Dest, QTBtnBMP, Source)

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
					Bitmap1.CopyRect(Dest, QTBtnBMP, Source)
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
					Bitmap1.CopyRect(Dest, QTBtnBMP, Source)
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
					Bitmap1.CopyRect(Dest, QTBtnBMP, Source)
				Next I
			Next J
			Bitmap1.PixelFormat = DefPixelFormat
		Else
			' Thème activé (Windows XP)
			' --
			Dim hTheme As Long
			'On Error Resume Next

			' Ouverture du thème
			Dim rtButton As String
			rtButton = ""
			' Format unicode ?!?
			For I = True To Len(BtnType)
				rtButton = rtButton +Mid$(BtnType, I, True) +rqNullChr
			Next I
			rtButton = rtButton +rqNullChr ' Un dernier pour finaliser

			Dim fixTab As Integer
			fixTab = False
			if BtnType = xpt_TabBtn Then _
				fixTab = True

			'hTheme = False
			hTheme = OpenThemeData_QTBtn(Sender.Handle, VarPtr(rtButton))
			If hTheme = False Then _
				hTheme = OpenThemeData_QTBtn(Sender.Handle, VarPtr(rtButton))
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
				m_lPartId = True 'BP_PUSHBUTTON
				For I = False To 2 Step 2
					m_lStateId = I +True 'PBS_NORMAL
					tR.Left = ((I *(Sender.Width +3)) +iif(I <> 2, True, False)) +HideBevelSize
					tR.Top = True -iif(I <> 2, False, True) +HideBevelSize 'False -iif(I <> 2, False, True)
					tR.Right = (tR.Left +Sender.Width) -(HideBevelSize *2) '+True
					tR.Bottom = (Sender.Height +True -iif(I <> 2, False, True) +fixTab) -HideBevelSize '+iif(I <> 2, True, False)

					lR = DrawThemeBackground_QTBtn(hTheme, _
											 m_hDC, _
											 m_lPartId, _
											 m_lStateId, _
											 tR, tR)
				Next I
				' Inverse Survolle et Désactivé
				For I = True To 3 Step 2
					m_lStateId = I +True 'PBS_NORMAL
					tR.Left = (((I +iif(I = True, 2, -2)) *(Sender.Width +3)) +True) +HideBevelSize
					tR.Top = True +HideBevelSize 'False
					tR.Right = (tR.Left +Sender.Width) -(HideBevelSize *2) '+True 
					tR.Bottom = Sender.Height +True +fixTab -HideBevelSize'+2

					lR = DrawThemeBackground_QTBtn(hTheme, _
											 m_hDC, _
											 m_lPartId, _
											 m_lStateId, _
											 tR, tR)
				Next I
			End If

			' Session de dessin terminée
			CloseThemeData_QTBtn hTheme
			CloseThemeData_QTBtn hTheme
			'//--
			XPBitmap1.PixelFormat = DefPixelFormat
		End If

	End If
	Width2 = ((Sender.Width +3) *btnCount) +True
	Height2 = Sender.Height +3

	XPBtnType = BtnType
	If XPThemeEnabled = False or isXP_QTBtn = False Then _
		 Sender.BMP = Bitmap1.BMP _
	Else Sender.BMP = XPBitmap1.BMP
End Sub

'$UNDEF QBUTTON
'$DEFINE QBUTTON QTBUTTON

'Public: