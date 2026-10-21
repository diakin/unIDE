' Attention!  Si l'item est masquй (.Visible = False)
' l'icфne devra кtre appliquйe а nouveau une fois 
' visible (.Visible = True)

'
'    BMPMenu.BMPHandle = Snew_bmp
'    ' Par position
'    CreateMenuBitmap (Popup1, 0, MF_BYPOSITION_AMIB, BMPMenu)
'    ' Par command
'    CreateMenuBitmap (Popup1, Item1.Command, 0, BMPMenu)
'

$IFNDEF _AMIB
$DEFINE _AMIB
$Option Explicit

Declare Function CreateCompatibleBitmap_AMIB Lib "gdi32" Alias "CreateCompatibleBitmap" ( _
		ByVal hdc As Long, ByVal nWidth As Long, ByVal nHeight As Long) As Long
Declare Function CreateCompatibleDC_AMIB Lib "gdi32" Alias "CreateCompatibleDC" ( _
		ByVal hdc As Long) As Long
Declare Function DeleteDC_AMIB Lib "gdi32" Alias "DeleteDC" ( _
		ByVal hdc As Long) As Long
Declare Function DeleteObject_AMIB Lib "gdi32" Alias "DeleteObject" ( _
		ByVal hObject As Long) As Long
Declare Function SelectObject_AMIB Lib "gdi32" Alias "SelectObject" ( _
		ByVal hdc As Long, ByVal hObject As Long) As Long
Declare Function SetBkMode_AMIB Lib "gdi32" Alias "SetBkMode" ( _
		ByVal hdc As Long, ByVal nBkMode As Long) As Long

Declare Function GetSystemMetrics_AMIB Lib "user32" Alias "GetSystemMetrics" ( _ 
		ByVal nIndex As Long) As Long

Declare Function PatBlt_AMIB Lib "gdi32" Alias "PatBlt" ( _ 
		ByVal hdc As Long, _ 
		ByVal x As Long, ByVal y As Long, _ 
		ByVal nWidth As Long, ByVal nHeight As Long, _ 
		ByVal dwRop As Long) As Long 
Declare Function TransparentBlt_AMIB Lib "msimg32.dll" Alias "TransparentBlt" ( _ 
		ByVal hdc As Long, _ 
		ByVal x As Long, ByVal y As Long, _ 
		ByVal nWidth As Long, ByVal nHeight As Long, _ 
		ByVal hSrcDC As Long, _ 
		ByVal xSrc As Long, ByVal ySrc As Long, _ 
		ByVal nSrcWidth As Long, ByVal nSrcHeight As Long, _ 
		ByVal crTransparent As Long) As Long


Declare Function SetMenuItemBitmaps_AMIB Lib "user32" Alias "SetMenuItemBitmaps" ( _
		ByVal hMenu As Long, _
		ByVal nPosition As Long, _
		ByVal wFlags As Long, _
		ByVal hBitmapUnchecked As Long, _
		ByVal hBitmapChecked As Long) As Long

Const MF_BYCOMMAND_AMIB As Long		= &H0
Const MF_BYPOSITION_AMIB As Long	= &H400

Const WHITENESS_AMIB As Long		= &HFF0062
Const TRANSPARENT_AMIB				= 1

Type Size_AMIB
	cx	As Long
	cy	As Long
End Type

Const SM_CXMENUCHECK_AMIB As Long	= 71
Const SM_CYMENUCHECK_AMIB As Long	= 72

Dim hwndDesktop_AMIB As Long, _
	hdcDesktop_AMIB	As Long, _
	hdcMem_AMIB		As Long
Dim hbm_AMIB		As Long, _
	hbmOld_AMIB		As Long

Dim BMPMenu As QBitmap

Sub CreateMenuBitmap (mPopup As QPopupMenu, mItem As Integer, flag_mItem As Long, Me As QBitmap)
	Dim Ret As Long
	Dim size As Size_AMIB
	If flag_mItem <> MF_BYPOSITION_AMIB Then _
		flag_mItem = MF_BYCOMMAND_AMIB

	' Crйe un DC compatible avec l'image en cours.
	hdcMem_AMIB		= CreateCompatibleDC_AMIB	(Me.Handle)
	' Dйtermine la taille de l'image requise.
	size.cx			= GetSystemMetrics_AMIB		(SM_CXMENUCHECK_AMIB)
	size.cy			= GetSystemMetrics_AMIB		(SM_CYMENUCHECK_AMIB)
	' Crйe un bitmap et le sйlectionne.
	hbm_AMIB		= CreateCompatibleBitmap_AMIB (Me.Handle, Me.Width, Me.Height)
	hbmOld_AMIB		= SelectObject_AMIB			(hdcMem_AMIB, hbm_AMIB)

	' Dйfinie la transparence du DC.
	SetBkMode_AMIB	hdcMem_AMIB, TRANSPARENT_AMIB
	' Efface le fond du DC.
	PatBlt_AMIB		(hdcMem_AMIB, 0, 0, size.cx, size.cy, WHITENESS_AMIB)

	' Copie l'image
	TransparentBlt_AMIB ( hdcMem_AMIB, 0, 0, _
		size.cx, size.cy, _ 
		Me.Handle, 0, 0, _ 
		Me.Width, Me.Height, _ 
		Me.Pixel(0,0))

	' Place l'image dans l'item du menu
	If hbm_AMIB <> 0 Then
		Ret = SetMenuItemBitmaps_AMIB (mPopup.Handle, mItem, flag_mItem, hbm_AMIB, hbm_AMIB)
		If Ret = 0 Then ShowMessage "Erreur:: imposible de dйfinir l'handle, mnuindex%" +STR$(mItem)
	Else
		ShowMessage "Erreur:: bitmap invalide, mnuindex%" +STR$(mItem)
	End If

	' Nettoie les ressources
	SelectObject_AMIB	(hdcMem_AMIB, hbmOld_AMIB)
	DeleteDC_AMIB		(hdcMem_AMIB)

End Sub


Sub ClearMenuBitmap (mPopup As QPopupMenu, mItem As Long, flag_mItem As Long)
	If flag_mItem <> MF_BYPOSITION_AMIB Then _
		flag_mItem = MF_BYCOMMAND_AMIB

	SetMenuItemBitmaps_AMIB (mPopup.Handle, mItem, flag_mItem, 0, 0)
End Sub
$ENDIF ' _AMIB
