'$REsource btn_BMP As "_RES\Boutons.bmp"
$Option Explicit

' Vous pouvez tricher ce composante par la mкme astuce utilisй ici 


$IFNDEF __RQNINC
'CONST False = 0
'CONST True = 1

'CONST clPurple = &HFF00FF
$ENDIF ' __RQINC

Const DefPixelFormat = 4
Const CharAnd	= "&"
Const ChardAnd	= "&&"

'Liste de tous les btns de type QTButton crййs lors du chargement
Dim AllQTBtnsHandle As QStringList, AllQTBtnsGrouped As QStringList
'
Dim AllQTBtnsRequester As Long, AllQTBtnsRequesterParent As Long
AllQTBtnsRequester = False' Btn appelant
AllQTBtnsRequesterParent = False' Parent du btn appelant

'Si vous voulez, vous pouver remplacer la resource par un objet bitmap
'mais n'oubliez pas de remplacer QTBtnBMP.BMPHandle = btn_BMP par
'QTBtnBMP.BMP = btn_BMP.BMP
Dim QTBtnBMP As QBitmap
	QTBtnBMP.BMPHandle = btn_BMP' REsource bitmap
	'QTBtnBMP.BMP = btn_BMP.BMP'  Image bitmap


Const BM_SETSTATE_QTBtn = &HF3
Const WM_LBUTTONDOWN_QTBtn = &H201
Const WM_LBUTTONUP_QTBtn = &H202

Declare Function SendMessage_QTBtn Lib "user32" Alias "SendMessageA" _
  (ByVal hwnd As Long, _
   ByVal wMsg As Long, _
   ByVal wParam As Long, _
   lParam As Long) As Long

Declare Function IsWindowEnabled_QTBtn Lib "user32" Alias "IsWindowEnabled" _
	(ByVal hwnd As Long) As Long

Declare Function LockWindowUpdate_QTBtn Lib "user32" Alias "LockWindowUpdate" _
	(ByVal hwndLock As Long) As Long

Declare Function SetCapture_QTBtn Lib "user32" Alias "SetCapture" _
	(ByVal hwnd As Long) As Long
Declare Function ReleaseCapture_QTBtn Lib "user32" Alias "ReleaseCapture" () As Long
Declare Function GetCapture_QTBtn Lib "user32" Alias "GetCapture" () As Long

Declare Function GetNextDlgTabItem_QTBtn Lib "user32" Alias "GetNextDlgTabItem" _
	(ByVal hDlg As Long, _
	 ByVal hCtl As Long, ByVal bPrevious As Long) As Long
Declare Function SetFocus_QTBtn Lib "user32" Alias "SetFocus" _
	(ByVal hwnd As Long) As Long
Declare Function GetParent_QTBtn Lib "user32" Alias "GetParent" _
	(ByVal hwnd As Long) As Long
Declare Function GetFocus_QTBtn Lib "user32" Alias "GetFocus" () As Long

Sub NextDlg_QTBtn(NextPrevTab As Long)'(CtrlHwnd As Long)
	Dim hwnd5 As Long, hwnd6 As Long
	ReleaseCapture_QTBtn' Corrige un bug / Fix a Bug
	hwnd6 = GetFocus_QTBtn()
	hwnd5 = GetNextDlgTabItem_QTBtn(GetParent_QTBtn(hwnd6),hwnd6, NextPrevTab)

	Call SetFocus_QTBtn(hwnd5)
End Sub

' Vйrifie la version de Windows puisque certains problиmes sont identifiйs
' sur l'un ou l'autre
TYPE OSVERSIONINFO_QTBtn
	dwOSVersionInfoSize As Long
	dwMajorVersion As Long
	dwMinorVersion As Long
	dwBuildNumber As Long
	dwPlatformId As Long
	szCSDVersion As String * 128
END TYPE
'Const PLATFORM_WIN32_WINDOWS = 1
'Const PLATFORM_WIN32_NT = 2
Declare Function GetVersionEx_QTBtn Lib "kernel32.dll" Alias "GetVersionExA" _
	(ByVal lpVersionInformation As LONG) As Long

DIM rtn_QTBtn AS LONG
DIM OSV_QTBtn AS OSVERSIONINFO_QTBtn, Mem_QTBtn AS QMEMORYSTREAM
DIM PixelFormatFix_QTBtn As Integer
PixelFormatFix_QTBtn = DefPixelFormat
SUB GetVersion_QTBtn
	OSV_QTBtn.dwOSVersionInfoSize = sizeof(OSV_QTBtn)
	Mem_QTBtn.WriteUDT(OSV_QTBtn)
	rtn_QTBtn = GetVersionEx_QTBtn(Mem_QTBtn.Pointer)
	IF rtn_QTBtn <> False THEN
		Mem_QTBtn.Position = False
		Mem_QTBtn.ReadUDT(OSV_QTBtn)
		IF OSV_QTBtn.dwPlatformId = True THEN _
			PixelFormatFix_QTBtn = 6
	END IF
	Mem_QTBtn.Close
END SUB
Call GetVersion_QTBtn

Declare Sub BMPStretch_Property (Sender As QButton)
Sub FixKind (oldvalue as integer, Sender As QButton)
	Sender.NumBMPs = oldvalue
End Sub

Dim RequestRelease As Integer

' Event Template pour les nouveaux йvйnements MouseLeave et MouseEnter
DECLARE SUB OnMouseEnterLeave_EventTemplate (X As Integer, Y As Integer, Shift As Integer, Sender As QButton)

' When Group = 0 it should be clean if present
Sub SetIndex (Index As Integer, Hwnd As Long)
	AllQTBtnsHandle.AddItems str$(Hwnd)
	AllQTBtnsGrouped.AddItems STR$(Index)
		   
'	If AllQTBtnsGrouped.ItemCount <> AllQTBtnsHandle.ItemCount Then ShowMessage "Erreur"
End Sub

Type QTButton Extends QButton
  'YRESTE/TODO
	'!Ajoutй: Icon/BMP
	'!Ajoutй: Propriйtй de NumBMPs
	'!Ajoutй: Propriйtй de NumICOBMPs (indique le nombre d'image dans l'icone)
	'!Ajoutй: Propriйtй de Layout
	'Ajouter: Propriйtй de Spacing
	'Ajouter: Evйnement Default (onshow la souris pointe le btn... setfocus)
	'!Rйparй: Caption
	'!Ajoutй: Souslignage de la lettre dans BMPBtn; ex: "Dй&faut"
	'!ReCorrigй: & et && dans le caption; 1 souligne, 2 donnent & sans souligner
	'?Utiliser: TextRect plutot que TextOut (n'aime pas les bounds) utiliser une API
	'!Corrigй: Effet de Souslignage appuyer sur Alt+ChrSoulignй = clique
	'!Corrigй: Propriйtй de Height et Width
	'!Corrigй: Survole lorsque le nombre de btn est infйrieur а 4
	'!Corrigй: Survole lors d'un clique
	'-Inverser: Enfoncй et Dйsactivй dans le fichier BMP
	'!Corrigй: Lorsque le nombre de btns excиde 4 (NumBMPs)
	'!Ajoutй: Lignes Multiples basique (insиrez chr$(10) pour crйer une nouvelle ligne)
	'-Ajouter: HideCaption, pour afficher une icфne et masquer le texte (coolbtn like)
	'Corriger/Ajouter: propriйtй de police (comment?)
	'		pour l'instant vous devrez utiliser ReDraw aprиs avoir changй la police
	'!Corrigй: lorsque la souris pointe le btn, le clavier de rйpond plus
	'!Corrigй: Petit problиme de positinement du texte
	'!Corrigй: Problиme avec Enabled et la police en live
	'Corriger/Ajouter: Propriйtй de Visible (йviter de trop dessiner lorsqu'invisible)
	'Ajouter: AutoSize lorsque la taille du texte en pixel excиde celle du bouton
	'Ajouter: Propriйtй de Parent pour кtre sure que l'enjolivure sera dessinйe
	'Corriger: Propriйtй d'Align
	'!Ajoutй: Groupe de bouton
	'Indentifiй: 1) Problиme introduit... lorsque la souris quitte le contrфle, il est mal redessinй... arrrg!
	'			    Le problиme vient de l'ordre dans lequel NumBMPs est introduit.
	'				Rйsolution: l'insиrer aprиs les	paramиtres de positionnement et de taille.
	'			 2) Lorsque le caption du btn est trop long, le reste du texte apparaоt sur les divers
	'				effets, а savoir dйsactivй ,enfoncй, survollй. 	Ce problиme vient du fait que je 
	'				n'arrive toujours pas а utiliser TextRect.
	'			 3) Parfois le btn n'est pas dessinй lorsque NumBMPs n'est pas spйcifiй, donc ne pas
	'			    oublier de l'ajouter.
	'			 4) Plus d'une fenкtre alors qu'un btn n'est toujours pas visible, aura d'йtranges 
	'			    rйsultats d'affiche pour ce btn, surtout en utilisant ShapeForm.
	'			    Rйsolution: Dim DummyBtn As QTButton juste aprиs la fenкtre

  With QTButton
	Dest As QRECT
	Source As QRECT
	BMPBtn As QBitmap
	BMPtmp As QBitmap' Devrait reflйtй un seul btn, celui а rйintйgrer (normal, survole)
	ICOBMP As QBitmap' la petite icфne а afficher sur le btn
	Align as Integer Property Set SetAlign
	Caption as String Property Set SetCaption
	Enabled as Integer Property Set SetEnabled
	Height as Integer Property Set SetHeight
	Width as Integer Property Set SetWidth
	Layout as Integer Property Set SetLayout
	Spacing as Integer Property Set SetSpacing
	NumBMPs as Integer Property Set SetNumBMPs
	NumICOBMPs as Integer Property Set SetNumICOBMPs
	Kind as Integer Property Set SetKind
	Down as Integer Property Set SetDown
	GroupIndex as Integer Property Set SetGroupIndex
	OnMouseLeave AS EVENT(OnMouseEnterLeave_EventTemplate)
	OnMouseEnter AS EVENT(OnMouseEnterLeave_EventTemplate)

	'Nouvelles propriйtйs
	'qqchose as Integer Property Set SetQqChose

	Function TextWidth(text as string) As Integer:	Result = .BMPBtn.TextWidth(text)
	End Function
	Function TextHeight(text as string) As Integer:	Result = .BMPBtn.TextHeight(text)
	End Function

	Sub DrawCaption: Dim I As Integer
		dim color as integer, left as integer, top as integer, _
		ampandpos as integer, ampandposwidth as integer, dampand as integer, _
		capwidth as integer', noico as integer
		dim supCaption as string

		'noico	= .ICOBMP.Empty
		color	= iif(super.enabled = 1, .font.color, -2147483631)
		top		= ((.Height -.TextHeight(.Caption)) \2) +True
		dampand = tally(super.caption, "&&")
		supCaption = Super.Caption
		if dampand = False then _
			  ampandpos = INSTR(SupCaption, CharAnd): _
			  ampandposwidth = .TextWidth(LEFT$(SupCaption -CharAnd, ampandpos)) _
		else ampandposwidth	= False

		capwidth	= (.Width -( .TextWidth( Field$( .Caption _
					  -iif(dampand = False, CharAnd, ""), chr$(10), True) ) )) \2

		If .ICOBMP.Empty = False Then
			.ICOBMP.PixelFormat = PixelFormatFix_QTBtn'.PixelFormat'when kind no prob, when icobmp big prob
			.ICOBMP.Transparent = 1'True
		End If

		dim startFrom as integer, endTo as integer
		if .Enabled = True then
			startFrom = False
			endTo = .NumBMPs -True
		else
			startFrom = True
			endTo = True
		end if

		Dim J As Integer
		Dim LineCount As Integer
		Dim Down As Integer
		If .Caption <> "" Then
			For I = startFrom To endTo step 2
				If I = False And .Down = True Then _
					 Down = True _
				Else Down = False

				left = capwidth +(I *(.Width +3)) +True
				If .ICOBMP.Empty = False Then
					If .Layout = False Then
						left = left +(.ICOBMP.Width \.NumICOBMPs) \2 _
							   +iif(.Layout < 2, -(.Spacing \2), False) +.Spacing +Down
					ElseIf .Layout = True Then
						left = left -(((.ICOBMP.Width \.NumICOBMPs) \2) _
							   +iif(.Layout < 2, -(.Spacing \2), False) +.Spacing) +Down
					'ElseIf .Layout = 2 Then
					'ElseIf .Layout = 3 Then
					End If
				End If

				LineCount = Tally(.Caption, chr$(10)) +True
				If LineCount > True Then
					For J = True To LineCount
						.BMPBtn.TextOut( left +Down, _
										 top +(.TextHeight(.Caption) *((LineCount -True) /2)) _
										  +(.TextHeight(.Caption) *-(LineCount -J)) +Down, _
										 Field$(.Caption, chr$(10), J), _
										 color, -True)
					Next J
				Else
					.BMPBtn.TextOut( left +Down, _
									 top +iif(.Layout > True and .ICOBMP.Empty = False, _
											  iif(.Layout = 2, .ICOBMP.Height, -.ICOBMP.Height) \2, _
											  False ) +Down, _
									 .Caption, _
									 color, -True)
					'.BMPBtn.TextRect( QTButton.Dest, 3, 3, QTButton.Caption -CharAnd, color, -True)
				End If

				If dampand = False and Tally(SupCaption, CharAnd) = True Then
					Dim LineTop As Integer
					LineTop = top +.TextHeight(.Caption) -True _
							  -iif(.Layout > True, _
								   iif(.Layout = 2, -.ICOBMP.Height +True, .ICOBMP.Height) \2 -True,_
								   False) +Down
					.BMPBtn.Line( left +ampandposwidth -.TextWidth( MID$(SupCaption -CharAnd, ampandpos, True) ) _
								   +Down, _
								  LineTop, _
								  left +ampandposwidth -True +Down, _
								  LineTop, _
								  color)
				End If
			Next I
		End If
		' Fix Bug in Win9x where caption are draw in white color
		If .ICOBMP.Empty = False Then
			For I = startFrom To endTo step 2
				left = iif(.Layout > True, .Width \2, capwidth)
				left = left +(I *(.Width +3)) +True _
					   +iif(.Layout < 2 and .Caption <> "", _
							iif(.Layout = False, -((.ICOBMP.Width \.NumICOBMPs) +.Spacing) \2, _
								(.ICOBMP.Width \.NumICOBMPs) \2), _
							-(.ICOBMP.Width \.NumICOBMPs) \2 -True)

				Dim ICOtmp As QBitmap
				ICOtmp.Transparent = True
				If .NumICOBMPs > True Then
'					ShowMessage STR$(.ICOBMP.Width) +chr$(10) +_
'									STR$(.NumICOBMPs)
					ICOtmp.Width = .ICOBMP.Width \.NumICOBMPs
					ICOtmp.Height = .ICOBMP.Height
					' ==(add)
					WITH Dest: .Left = False: .Right = ICOtmp.Width
							    .Top = False: .Bottom = ICOtmp.Height
					END WITH
					WITH Source: .Left = I *(QTButton.ICOBMP.Width \QTButton.NumICOBMPs)
								.Right = .Left +(QTButton.ICOBMP.Width \QTButton.NumICOBMPs)
								  .Top = False: .Bottom = .Top +QTButton.ICOBMP.Height
					END WITH
					ICOtmp.CopyRect(QTButton.Dest, QTButton.ICOBMP, QTButton.Source)

				Else
					ICOtmp.BMP = .ICOBMP.BMP
				End If
				.BMPBtn.Draw ( left, _
							   (.Height +3 -.ICOBMP.Height) \2 _
							    +iif(.Layout > True and .Caption <> "", _
									 iif(.Layout = 2, -.ICOBMP.Height, .ICOBMP.Height) \2, False), _
							   ICOtmp.BMP)
			Next I
		End If

		.BMP = .BMPBtn.BMP
	End Sub
	Sub ReDraw
		LockWindowUpdate_QTBtn(GetParent_QTBtn(QTButton.Handle))

		Static checkICO As Integer
		If checkICO = False and .kind = False Then
			.ICOBMP.BMP = .BMP
			checkICO = True
		End If
		If .NumBMPs > DefPixelFormat Then .NumBMPs = DefPixelFormat
		BMPStretch_Property (QTButton)
		.BMPBtn.BMP = .BMP
		.BMPbtn.PixelFormat = DefPixelFormat' == (add)

		If .Caption = "" Then
			  Super.Layout = 0'1
		Else: .BMPBtn.Height = .BMPBtn.Height +.TextHeight(.Caption) +2
			  .BMPBtn.Paint (True, .BMPBtn.Height -True, clPurple, clPurple)
			  Super.Layout = 3
		End If

		If .NumBMPs >= DefPixelFormat Then
			WITH Dest: .Left = False: .Right = (QTButton.BMPBtn.Width -True) \QTButton.NumBMPs
						.Top = False: .Bottom = QTButton.BMPBtn.Height
			END WITH
			WITH Source: .Left = False: .Right = QTButton.Dest.Right
						  .Top = False: .Bottom = QTButton.BMPBtn.Height
			END WITH
			.BMPtmp.Width = .Dest.Right: .BMPtmp.Height = .Dest.Bottom
			.BMPtmp.CopyRect(QTButton.Dest, QTButton.BMPBtn, QTButton.Source)
		End If

		.BMPBtn.Font.Name = .Font.Name' == (add)
		.BMPBtn.Font.Size = .Font.Size' == (add)
		.BMPBtn.Font.Color = .Font.Color' == (add)
		.BMPBtn.Font.Bold = .Font.Bold
		.BMPBtn.Font.Italic = .Font.Italic
		.BMPBtn.Font.Underline = .Font.Underline		
		.DrawCaption
		LockWindowUpdate_QTBtn(False)
	End Sub
	Sub DrawDownUp
		If .NumBMPs >= 3 Then
			WITH Dest: .Left = QTButton.Down: .Right = .Left +(QTButton.BMPBtn.Width -True) \QTButton.NumBMPs
					.Top = QTButton.Down: .Bottom = .Top +QTButton.BMPBtn.Height
			END WITH
			WITH Source: .Top = False: .Bottom = QTButton.BMPBtn.Height
			END WITH
			If .Down = True Then
				' Btn enfoncй
				WITH Source: .Left = (QTButton.Dest.Right -True) *2
							.Right = .Left +QTButton.Dest.Right -True
				END WITH
				.BMPBtn.CopyRect(QTButton.Dest, QTButton.BMPBtn, QTButton.Source)
			Else
				' Btn normal
				WITH Source: .Left = False: .Right = QTButton.Dest.Right
				END WITH
				.BMPBtn.CopyRect(QTButton.Dest, QTButton.BMPtmp, QTButton.Source)
			End If

			.BMP = .BMPBtn.BMP
			.DrawCaption
		End If
	End Sub

	Sub ReleaseHotTrack
		LockWindowUpdate_QTBtn(GetParent_QTBtn(QTButton.Handle))
		' le pseudo-evйnement MOUSELEAVE
		ReleaseCapture_QTBtn
		' on retourne le caption а la normal
		'.Font.Bold = False
		.Font.Color = -2147483630
		'.caption = "Dehors..."
		If .NumBMPs => DefPixelFormat and .Down = False Then
			WITH Dest: .Left = False: .Right = (QTButton.BMPBtn.Width -True) \QTButton.NumBMPs
						.Top = False: .Bottom = QTButton.BMPBtn.Height
			END WITH
			WITH Source: .Left = False: .Right = QTButton.Dest.Right
						  .Top = False: .Bottom = QTButton.BMPtmp.Height
			END WITH
			.BMPBtn.CopyRect(QTButton.Dest, QTButton.BMPtmp, QTButton.Source)
			'.BMPBtn.Draw( False, False, QTButton.BMPtmp)
		End If

		.DrawCaption
		LockWindowUpdate_QTBtn(False)
	End Sub
	Event OnMouseUp(btn As Integer, X As Integer, Y As Integer, Shift As Integer)
		.ReleaseHotTrack

		' fait parti d'un groupe ?
		If .GroupIndex > False Then
			If AllQTBtnsRequester = False and btn = False Then
				Static currHwnd As Long

				Dim I As Integer
				' identifie le button qui appelle tous les autres
				AllQTBtnsRequester = .Handle
				' identifie le Parent du groupe appellй, comme зa si deux groupes ont le mкme
				' indentifiant mais pas le mкme parent, seul les btns du groupe ayant le parent 
				' conrrespondant seront appelйs.
				If AllQTBtnsRequesterParent = False Then _
					AllQTBtnsRequesterParent = GetParent_QTBtn(QTButton.Handle)

				For I = False To AllQTBtnsHandle.ItemCount -True
					If AllQTBtnsGrouped.Item(AllQTBtnsHandle.IndexOf(STR$(.Handle))) > False and _
						VAL(AllQTBtnsGrouped.Item(I)) = .GroupIndex and _
						GetParent_QTBtn(QTButton.Handle) = AllQTBtnsRequesterParent Then
						' retrouve l'handle du btn
						' get the handle of that button
						currHwnd = VAL(AllQTBtnsHandle.Item(I))

						If IsWindowEnabled_QTBtn(currHwnd) = True Then
							If currHwnd <> .Handle Then

								$TypeCheck Off
								' restaure le dernier йtat du btn а la normal
								' restore the last button state to normal
								'Call SendMessage_QTBtn(.Handle, WM_LBUTTONDOWN_QTBtn, False, ByVal 0&)
								' et envoit les msgs enfoncй/terminй de la souris pour lancer
								' l'йvйnement clic du btn, et indique visiblement sont йtat enfoncй
								' and send mouse down and up messages to fire its click event, 
								' and visibly indicate its pressed state.
								'Call SendMessage_QTBtn(currHwnd, WM_LBUTTONDOWN_QTBtn, False, ByVal 0&)
								Call SendMessage_QTBtn(currHwnd, WM_LBUTTONUP_QTBtn, False, ByVal 0&)
								'Call SendMessage_QTBtn(currHwnd, BM_SETSTATE_QTBtn, 1, ByVal 0&)
								Call SendMessage_QTBtn(currHwnd, BM_SETSTATE_QTBtn, False, ByVal 0&)
								$TypeCheck On

								'SetFocus_QTBtn(QTButton.Handle)
							ElseIf currHwnd = .Handle Then
								.Down = True
							End If
						End If
						' redonne le focus au btn appellant
						SetFocus_QTBtn(.Handle)

					End If
				Next I

				currHwnd = False
				AllQTBtnsRequester = False
				AllQTBtnsRequesterParent = False
				.DrawDownUp
			ElseIf (AllQTBtnsRequester <> False and AllQTBtnsRequester <> .Handle) and _
				GetParent_QTBtn(QTButton.Handle) = AllQTBtnsRequesterParent Then
				If VAL(AllQTBtnsGrouped.Item(AllQTBtnsHandle.IndexOf(STR$(AllQTBtnsRequester)))) = .GroupIndex and _
					.Down = True Then
					.Down = False
					.DrawDownUp
				End If
			End If
		End If
	End Event
	Event OnMouseMove(X As Integer, Y As Integer, Shift As Integer)
		Static PosX As Integer, PosY As Integer

		WITH Dest: .Left = False: .Right = (QTButton.BMPBtn.Width -True) \QTButton.NumBMPs
					.Top = False: .Bottom = QTButton.BMPBtn.Height
		END WITH
		If (X < False) Or (Y < False) Or (X > .Width) _
			Or (Y > .Height) Then
			.ReleaseHotTrack
			CALLFUNC(.OnMouseLeave, X, Y, Shift, QTButton)
		ElseIf (GetCapture_QTBtn() <> .Handle) and (RequestRelease = False _
			 and PosX <> X and PosY <> Y) Then
			' Verifie si la requete de relвcher la capture d'un QTBtn est 0
			' Check if the release capture request for QTBtn is 0
			' 
			' Ce qui va aussi empкcher le btn de reprendre son йtat initial
			' lors d'une action...
			PosX = X
			PosY = Y

			' le pseudo-evйnement MOUSEENTER
			SetCapture_QTBtn .Handle
			' on met le caption en gras
			'.Font.Bold = True
			.Font.Color = -2147483635
			'.caption = "Dessus..."
			If .NumBMPs => DefPixelFormat and .Down = False Then
				WITH Source: .Left = QTButton.Dest.Right *(QTButton.NumBMPs -True)
							.Right = .Left +QTButton.Dest.Right
							  .Top = False: .Bottom = QTButton.BMPBtn.Height
				END WITH
				.BMPBtn.CopyRect(QTButton.Dest, QTButton.BMPBtn, QTButton.Source)
			End If

			.DrawCaption
			CALLFUNC(.OnMouseEnter, X, Y, Shift, QTButton)
		ElseIf RequestRelease = True Then' Corrige l'йtat survolle du btn
										 ' Fix Hot state of btn
			.ReleaseHotTrack
		End If
		If (PosX <> X and PosY <> Y) Then RequestRelease = False' Restaure la requкte а 0
							  									' Reset release request
	End Event
	Event OnKeyDown(Key AS Word, Shift AS INTEGER)
'		.ReleaseHotTrack
		If RequestRelease = False Then
			Select Case Key
				Case 40, 39, 9: Call NextDlg_QTBtn(True)
				Case 38, 37: Call NextDlg_QTBtn(False)
			End Select
		End If

		RequestRelease = True
	End Event

	Sub FixBtnSize
		If .Align <> False Then Exit Sub'!-- 22/08
		dim height as integer, width as integer
		height = super.height: width = super.width

		.height = height: .width = width
	End Sub

	'Property Set SetAlign (lpalign as integer)
	'	.Align = lpalign: Super.Align = lpAlign
	'	.ReDraw
	'End Property
	Property Set SetLayout (lplayout as integer)
		.Layout = lplayout': Super.Layout = lplayout
		.DrawCaption
	End Property
	Property Set SetSpacing (lpspacing as integer)
		.Spacing = lpspacing': Super.Layout = lplayout
		.ReDraw
	End Property
	Property Set SetCaption (lpcaption as string)
		if tally(lpcaption, ChardAnd) = True then _
			.Caption = replacesubstr$(lpcaption, ChardAnd, CharAnd) _
		else _
			.Caption = lpcaption -CharAnd
		Super.Caption = lpcaption -chr$(10) -chr$(13)
		.ReDraw
	End Property
	Property Set SetEnabled (lpenabled as integer)
		Super.Enabled = lpenabled: .Enabled = lpenabled 
		.DrawCaption
	End Property
	Property Set SetHeight (lpheight as integer)
		'.ReleaseHotTrack
		.Height = lpheight: Super.Height = lpheight
		.ReDraw
	End Property
	Property Set SetWidth (lpwidth as integer)
		.Width = lpwidth: Super.Width = lpwidth
		.ReDraw
	End Property
	Property Set SetNumBMPs (lpnumbmps as integer)
		.NumBMPs = lpnumbmps: Super.NumBMPs = lpnumbmps
		.ReDraw
	End Property
	Property Set SetNumICOBMPs (lpnumicobmps as integer)
		.NumICOBMPs = lpnumicobmps
		.DrawCaption'ReDraw'==(mod)
	End Property
	Property Set SetKind (lpkind as integer)
		Dim numbmps as integer
		numbmps = .NumBMPs
		If lpKind > False Then
			.Kind = lpkind: Super.Kind = lpkind
			.NumICOBMPs = 2
			.ICOBMP.BMP = .BMP
		End If
			
		Call FixKind (numbmps, QTButton)
		.ReDraw
	End Property
	Property Set SetGroupIndex (lpIndex As Integer)
		.GroupIndex = lpIndex
		Call SetIndex(lpIndex, .Handle)
	End Property
	Property Set SetDown (lpDown As Integer)
		.Down = lpDown
		.DrawDownUp
	End Property

	Constructor
		BMPtmp.PixelFormat = DefPixelFormat
		BMPBtn.PixelFormat = DefPixelFormat
		Spacing = DefPixelFormat
		Enabled = True
		NumBMPs = True
		NumICOBMPs = True
		Layout = False'3'False
		Down = False
		FixBtnSize
	End Constructor
  End With
End Type

'Private:
' Reduit la taille du code dans l'application
Sub BMPStretch_Property
	
	' Pour corriger .Align
	'If Sender.Align <> False Then ...
	'	Call ClientRect API to Find parent width and height
	'End If

	Dim Dest As QRect, Source As QRect
	Dim Bitmap1 As QBitmap
	Dim Width1 As Integer, Height1 As Integer
	Dim btnCount As Integer

	btnCount = Sender.NumBMPs
	if btnCount > DefPixelFormat Then
		btnCount = DefPixelFormat
		sender.numbmps = btncount
	end if

	Width1 = Sender.Width *btnCount
	Height1 = Sender.Height
	With Bitmap1
		.Width = Width1 +(3 *btnCount) +True'== (mod)
		.Height = Height1 +3'== (mod)
		.FillRect(False, False, Bitmap1.Width, Bitmap1.Height, clPurple)'==(mod)
		.PixelFormat = DefPixelFormat
	End With

	Dim J As Integer, I As Integer
	For J = False To btnCount -True
		' Le centre ----------------------------------------------------------
		With Dest
			.Left = ((Width1 \btnCount) *J) +3 +(True *(J +True)) +(J *2) -iif(J = 2, True, False)
			.Top = DefPixelFormat -iif(J=2, True, False)
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
				.Top = DefPixelFormat -iif(J = 2, True, False)
				.Right = .Left +3
				.Bottom = Height1 -2 -iif(J = 2, True, False)
			End With
			With Source
				.Left = ((QTBtnBMP.Width \btnCount) *J) +IIf(I = False, False, (QTBtnBMP.Width \btnCount) -3)
				.Top = 3
				.Right = .Left +3
				.Bottom = QTBtnBMP.Height-3
			End With
			Bitmap1.CopyRect(Dest, QTBtnBMP, Source)
		Next I
	Next J

	'QTBtnBMP.BMP = 
	Bitmap1.PixelFormat = DefPixelFormat
	Sender.BMP = Bitmap1.BMP
End Sub

'Public: