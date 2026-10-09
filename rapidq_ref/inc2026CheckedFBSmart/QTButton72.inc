'$REsource btn_BMP As "../_res/Boutons.bmp"
$Option Explicit
' Vous pouvez tricher ce composante par la mкme astuce utilisй ici 


'Si vous voulez, vous pouver remplacer la resource par un objet bitmap
'mais n'oubliez pas de remplacer QTBtnBMP.BMPHandle = btn_BMP par
'QTBtnBMP.BMP = btn_BMP.BMP
Dim QTBtnBMP As QBitmap
	QTBtnBMP.BMPHandle = btn_BMP' REsource bitmap
	'QTBtnBMP.BMP = btn_BMP.BMP'  Image bitmap


Declare Function SetCapture_QTBtn Lib "user32" Alias "SetCapture" _
	(ByVal hwnd As Long) As Long
Declare Function ReleaseCapture_QTBtn Lib "user32" Alias "ReleaseCapture" () As Long
Declare Function GetCapture_QTBtn Lib "user32" Alias "GetCapture" () As Long

Declare Sub BMPStretch_Property (Sender As QButton)
Declare Sub FixKind (oldvalue as integer, Sender As QButton)

Type QTButton Extends QButton

  With QTButton
	Dest As QRECT
	Source As QRECT
	BMPBtn As QBitmap
	BMPtmp As QBitmap
	ICOBMP As QBitmap' la petite icфne а afficher sur le btn
	Align as Integer Property Set SetAlign
	Caption as String Property Set SetCaption
	Enabled as Integer Property Set SetEnabled
	Height as Integer Property Set SetHeight
	Width as Integer Property Set SetWidth
	Layout as Integer Property Set SetLayout
	Spacing as Integer Property Set SetSpacing
	NumBMPs as Integer Property Set SetNumBMPs
	Kind as Integer Property Set SetKind
	PixelFormat as Integer Property Set SetPixelFormat
	
	'Nouvelles propriйtйs
	'qqchose as Integer Property Set SetQqChose

	Function TextWidth(text as string) As Integer:	Result = .BMPBtn.TextWidth(text)
	End Function
	Function TextHeight(text as string) As Integer:	Result = .BMPBtn.TextHeight(text)
	End Function

	Sub DrawCaption: Dim I As Integer
		dim color as integer, left as integer, top as integer, ampandpos as integer, dampand as integer, _
		capwidth as integer', noico as integer
		dim supCaption as string

		'noico	= .ICOBMP.Empty
		color	= iif(super.enabled = 1, .font.color, -2147483631)
		top		= ((.Height -.TextHeight(.Caption)) \2) +1
		dampand = tally(super.caption, "&&")
		supCaption = Super.Caption
		if dampand = 0 then
			  ampandpos	= .TextWidth(LEFT$(SupCaption, INSTR(SupCaption, "&") -1))
		else: ampandpos	= 0
		end if
		capwidth	= (.Width -(.TextWidth(.Caption -iif(dampand = 0, "&", "")))) \2
		

		If .ICOBMP.Empty = 0 Then
			.ICOBMP.PixelFormat = .PixelFormat
			.ICOBMP.Transparent = 1
		End If

		dim startFrom as integer, endTo as integer
		if .Enabled = 1 then
			startFrom = 0
			endTo = .NumBMPs -1
		else
			startFrom = 1
			endTo = 1
		end if
		
		'For I = 0 To iif(.font.color = -2147483635, 0, .NumBMPs -1)
		For I = startFrom To endTo step 2
			 
			'WITH Dest: .Left = (QTButton.BMPBtn.Width -1) \QTButton.NumBMPs: .Right = .Left +(QTButton.BMPBtn.Width -1) \QTButton.NumBMPs
			'			.Top = 0: .Bottom = QTButton.BMPBtn.Height
			'END WITH
			left = capwidth +(I *(.Width +3)) +1 +iif(.ICOBMP.Empty = 0, .ICOBMP.Width \2 +iif(.caption<>"", -(.Spacing \2), 0), 0)
			If .ICOBMP.Empty = 0 Then _
				.BMPBtn.Draw ( left -(.ICOBMP.Width), (.Height +3 -.ICOBMP.Height) \2, .ICOBMP.BMP)

			.BMPBtn.TextOut( left +iif(.ICOBMP.Empty = 0, .Spacing, 0), top, .Caption, color, -1)
			'.BMPBtn.TextRect( QTButton.Dest, 3, 3, QTButton.Caption -"&", color, -1)

			If dampand = 0 and Tally(SupCaption, "&") = 1 Then
				.BMPBtn.Line( left +ampandpos, _
							top +.TextHeight(.Caption) -1, _
							left +ampandpos +.TextWidth( MID$(.Caption, INSTR(.Caption, "&") +1, 1) ), _
							top +.TextHeight(.Caption) -1, _
							color)
			End If
		Next I
		.BMPbtn.PixelFormat = 4
		.BMP = .BMPBtn.BMP
	End Sub
	Sub ReDraw

		Static checkICO As Integer
		If checkICO = 0 and .kind = 0 Then
			.ICOBMP.BMP = .BMP
			checkICO = 1
		End If
		If .NumBMPs >4 Then .NumBMPs = 4
			'.BMPBtn.Width = .BMPBtn.Width -(.BMPBtn.Width \.NumBMPs)
		'End If
		BMPStretch_Property (QTButton)
		.BMPBtn.BMP = .BMP

		If .Caption = "" Then
			  Super.Layout = 0
		Else: .BMPBtn.Height = .BMPBtn.Height +.TextHeight(.Caption) +2
			  .BMPBtn.Paint (1, .BMPBtn.Height -1, &HFF00FF, &HFF00FF) 
			  Super.Layout = 3
		End If

		If .NumBMPs >= 4 Then
			WITH Dest: .Left = 0: .Right = (QTButton.BMPBtn.Width -1) \QTButton.NumBMPs
						.Top = 0: .Bottom = QTButton.BMPBtn.Height
			END WITH
			WITH Source: .Left = 0: .Right = QTButton.Dest.Right
						  .Top = 0: .Bottom = QTButton.BMPBtn.Height
			END WITH
			.BMPtmp.Width = .Dest.Right: .BMPtmp.Height = .Dest.Bottom
			.BMPtmp.CopyRect(QTButton.Dest, QTButton.BMPBtn, QTButton.Source)
		End If

		'If .Layout <> 0 Then .Layout = 0
		'.Spacing = -.TextWidth(" ")'-.TextWidth(lpcaption)'

		.BMPBtn.Font.Bold = .Font.Bold
		.BMPBtn.Font.Italic = .Font.Italic
		.BMPBtn.Font.Underline = .Font.Underline
		.DrawCaption
	End Sub

	Sub ReleaseHotTrack
		' le pseudo-evйnement MOUSELEAVE
		ReleaseCapture_QTBtn
		' dans cet example, on retourne le caption а la normal
		'.Font.Bold = 0
		.Font.Color = -2147483630
		'.caption = "Dehors..."
		If .NumBMPs =>4 Then
			WITH Dest: .Left = 0: .Right = (QTButton.BMPBtn.Width -1) \QTButton.NumBMPs
						.Top = 0: .Bottom = QTButton.BMPBtn.Height
			END WITH
			WITH Source: .Left = 0: .Right = QTButton.Dest.Right
						  .Top = 0: .Bottom = QTButton.BMPtmp.Height
			END WITH
			.BMPBtn.CopyRect(QTButton.Dest, QTButton.BMPtmp, QTButton.Source)
		End If

		.DrawCaption
	End Sub
	Event OnMouseUp(btn As Integer, X As Integer, Y As Integer, Shift As Integer)
		.ReleaseHotTrack
	End Event
	Event OnMouseMove(X As Integer, Y As Integer, Shift As Integer)
		WITH Dest: .Left = 0: .Right = (QTButton.BMPBtn.Width -1) \QTButton.NumBMPs
					.Top = 0: .Bottom = QTButton.BMPBtn.Height
		END WITH
		If (X < 0) Or (Y < 0) Or (X > .Width) _
			Or (Y > .Height) Then
			.ReleaseHotTrack
		ElseIf GetCapture_QTBtn() <> .Handle Then
			' le pseudo-evйnement MOUSEENTER
			SetCapture_QTBtn .Handle
			' dans cet example, on met le caption en gras
			'.Font.Bold = 1
			.Font.Color = -2147483635
			'.caption = "Dessus..."
			If .NumBMPs =>4 Then
				WITH Source: .Left = QTButton.Dest.Right *(QTButton.NumBMPs -1)
							.Right = .Left +QTButton.Dest.Right
							  .Top = 0: .Bottom = QTButton.BMPBtn.Height
				END WITH
				.BMPBtn.CopyRect(QTButton.Dest, QTButton.BMPBtn, QTButton.Source)
			End If

			.DrawCaption
		End If
	End Event

	Sub FixBtnSize
		If .Align <> 0 Then Exit Sub'!-- 22/08
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
		.ReDraw
	End Property
	Property Set SetSpacing (lpspacing as integer)
		.Spacing = lpspacing': Super.Layout = lplayout
		.ReDraw
	End Property
	Property Set SetCaption (lpcaption as string)
		if tally(lpcaption,"&&") = 1 then _
			.Caption = replacesubstr$(lpcaption,"&&","&") _
		else _
			.Caption = lpcaption -"&"
		Super.Caption = lpcaption
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
	Property Set SetKind (lpkind as integer)
		Dim numbmps as integer
		numbmps = .NumBMPs
		If lpKind > 0 Then
			.Kind = lpkind: Super.Kind = lpkind
			.ICOBMP.BMP = .BMP
			.BMPbtn.PixelFormat = 4
			.ICOBMP.Width = .ICOBMP.Width /2'Super.NumBMPs
		End If
			
		Call FixKind (numbmps, QTButton)
		.ReDraw
	End Property
	Property Set SetPixelFormat(lpformat as integer)
		.PixelFormat = lpformat
		If .ICOBMP.Empty = 0 Then .ICOBMP.PixelFormat = lpformat
	End Property

	Constructor
		BMPtmp.PixelFormat = 4
		BMPBtn.PixelFormat = 4
		ICOBMP.PixelFormat = 4
		Spacing = 4
		Enabled = 1
		NumBMPs = 1
		Layout = 3'0
		FixBtnSize
	End Constructor
  End With
End Type

'Private:
' Reduit la taille du code dans l'aplication
Sub BMPStretch_Property

	Dim Dest As QRect, Source As QRect
	Dim Bitmap1 As QBitmap
	Dim Width1 As Integer, Height1 As Integer
	Dim btnCount As Integer

	btnCount = Sender.NumBMPs
	if btnCount >4 Then
		btnCount =4
		sender.numbmps =btncount
	end if

	With Bitmap1: .Width = ((Sender.Width +3) *btnCount) +1
		.Height = Sender.Height +3
		.FillRect(0, 0, Bitmap1.Width, Bitmap1.Height, &HFF00FF)
		.PixelFormat = 4
	End With
	Width1 = Sender.Width *btnCount
	Height1 = Sender.Height

	Dim J As Integer, I As Integer', Width1 As Integer
	For J = 0 To btnCount-1
		' Le centre ----------------------------------------------------------
		With Dest
			.Left = ((Width1 \btnCount) *J) +3 +(1 *(J+1)) +(J*2) -iif(J=2, 1, 0)
			.Top = 4 -iif(J=2, 1, 0)
			.Right = .Left +(Width1 \btnCount) -6
			.Bottom = Height1 -2 -iif(J=2, 1, 0)
		End With
		With Source: .Left = ((QTBtnBMP.Width \btnCount) *J) +3: .Top = 3: _
			.Right = .Left +(QTBtnBMP.Width \btnCount) -6
			.Bottom = QTBtnBMP.Height -3
		End With

		Bitmap1.CopyRect(Dest, QTBtnBMP, Source)

		' Les coins ----------------------------------------------------------
		For I = 0 TO 3
			With Dest
				.Left = ((Width1 \btnCount) *J) +IIf(I=0 or I=2, 0, (Width1 \btnCount) -3) +(1 *(J+1)) +(J*2) -iif(J=2, 1, 0)
				.Top = IIf(I<2, 1, Height1 -2) -iif(J=2, 1, 0)
				.Right = .Left +3
				.Bottom = .Top +3
			End With
			With Source
				.Left = ((QTBtnBMP.Width \btnCount) *J) +IIf(I=0 or I=2, 0, (QTBtnBMP.Width \btnCount) -3)
				.Top = IIf(I<2, 0, QTBtnBMP.Height-3)
				.Right = .Left +3
				.Bottom = .Top +3
			End With
			Bitmap1.CopyRect(Dest, QTBtnBMP, Source)
		Next I
		' Les horizontaux ----------------------------------------------------
		For I = 0 TO 1
			With Dest
				.Left = ((Width1 \btnCount) *J) +3 +(1 *(J+1)) +(J*2) -iif(J=2, 1, 0)
				.Top = IIf(I=0, 1, Height1 -2) -iif(J=2, 1, 0)
				.Right = .Left +(Width1 \btnCount) -6
				.Bottom = .Top +3
			End With
			With Source
				.Left = (QTBtnBMP.Width \btnCount) *J +3
				.Top = IIf(I=0, 0, QTBtnBMP.Height -3)
				.Right = .Left +(QTBtnBMP.Width \btnCount) -6
				.Bottom = .Top +3
			End With
			Bitmap1.CopyRect(Dest, QTBtnBMP, Source)
		Next I
		' Les verticaux ------------------------------------------------------
		For I = 0 TO 1
			With Dest
				.Left = ((Width1 \btnCount) *J) +IIf(I=0, 0, (Width1 \btnCount) -3) +(1 *(J+1)) +(J*2) -iif(J=2, 1, 0)
				.Top = 4 -iif(J=2, 1, 0)
				.Right = .Left +3
				.Bottom = Height1 -2 -iif(J=2, 1, 0)
			End With
			With Source
				.Left = ((QTBtnBMP.Width\btnCount) *J) +IIf(I=0, 0, (QTBtnBMP.Width \btnCount) -3)
				.Top = 3
				.Right = .Left +3
				.Bottom = QTBtnBMP.Height-3
			End With
			Bitmap1.CopyRect(Dest, QTBtnBMP, Source)
		Next I
	Next J

	'QTBtnBMP.BMP = 
	Bitmap1.PixelFormat = 4
	Sender.BMP = Bitmap1.BMP
End Sub

Sub FixKind: Sender.NumBMPs = oldvalue
End Sub

'Public: