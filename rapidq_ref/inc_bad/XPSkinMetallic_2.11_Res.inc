'===========================================================================
'Windows XP Metallic Skin v2.13 * Fix le problиme de taille et toujours visible *	modifiй le 28 juin, 2003
'===========================================================================
'*[INSTALLATION/DERNIERS DЙTAILS] : ****
' -Insиrez une resource nommйe ICO dans laquelle sera inclus le chemin de l'icфne а utiliser, sinon vous recevrez
'  un msg d'erreur...
' -La Form principale doit se nommer MainForm, sinon vous devrez aporter certains changements а l'intйrieur de
'  l'OBJET...  << J'vais crйer un tutorial comme ceux de RapidQ! >>
' -N'utilisez plus AddBorderIcons/DelBorderIcons avec cet objet, utiliser plutot AddTitleIcons/DelTitleIcons...
'
'*[NOUVEAUTЙES & MISES А JOUR] : ****
' -Corrigй un petit prob avec ActiveInactive, la fenкtre n'est plus redessinйe comme ayant le focus lorsq'une
'  autre fenкtre la recouvre puis est dйplacйe, ainsi qu'un petit prob avec les btns de la barre de titre.
' -ActiveInactive dйteste les msgboxs... Non c'est faux il n'aime simplement pas WM_NCACTIVATE vous n'avez
'  plus а utiliser la commande .tmpInactive!
' -Corrigй le bug lorque la barre de titre est cachй, la taille de la fenкtre ce rйtrйcissait de la taille de la barre de
'  titre... et aussi lorsque croped!
' -Lorsque le MenuPopup est affichй ActiveInactive est stopй temporairement...
' -L'implantation du module de sйlection d'Apparence est presque terminй...
'  Note :  Certains format de bmp font planter le programme, pour rйsoudre ce 'tit prob ouvrez-les dans IE,
'  sйlectionnez "Enregistrer la cible sous" et йcrivez par dessus l'image dйfectueuse.
' -Moins de WiTH/END WiTH.
' -Agrandir et Restaurer devrait plutot bien fonctionner...
' -La fenкtre se reduit normallement et sans alternative, mкme lorsque ToujoursVisible est actif.  La fenкtre
'  pourra кtre croped sur demande. Aussi double-cliquer reduira ou restaurera la taille de la fenкtre si croped...
' -Peut maintenant se passer de Alternative
' -Aussi l'affichage de boоte de dialogue devrait fonctionner correctement via un petit truc qui peut кtre encore
'  amйliorй...
' -Wouhou! J'ai finallement rйussi а intйgrer SetWindowLong qui permet la fermeture de la fenкtre via la barre
'  d'outils. Les fonctions Rйduire/Agrandir/Restaurer/Dйplacer fonctionnent comme ils devraient...
' -ReDйsactive MainForm lorsqu'une PopupBox s'affiche... (oublier!)
' -Btn Aide maintenant actif et peut l'кtre sur commande aussi...
' -TweakColor et MenuColor en array...
' -Maintenant un bouton est aussi ajoutй par dйfaut а la Form lors de la crйation.
' -Ajoutй Timer aux boutons, une fois la souris sortie les йlйments sont restaurйs. Le Timer est stopй lorsqu'il a
'  fini son action pour йviter les flickings.
' -Finallement venu а bout de ToujoursVisible... Yessss! Pas parfait encore...!
' -Meilleur rendu des images servant de "SKIN".
' -Lorsque la fenкtre est en arriиre plan, elle change de couleur et reprend sa couleur une fois le focus retrouvй...
'  (Y'a toujours un bug aprиs le passage en mode ToujoursVisible!) GRRR!!!
' -Lorsqu'on clique sur la barre d'outil et que la fenкtre est en arriиre plan, elle est maintenant redessinйe avant
'  de la dйplacer...
' -Ajoutй un menu а l'icфne de la barre de titre, celui-ci manquait ainsi que lorsqu'on clique sur la barre de titre
'  (Title_Hot)... J'utilise maintenant un Form qui me permet de le personnaliser pour qu'il ressemble le plus
'  possible а celui de XP...
' -Le PopupMenu se retaille proprement si la taille d'un йlйment est plus grand que la sienne...
' -La largeur est automatiquement corrigйe sans avoir а ajouter 1 а Width...
'
'*[PROBLИMES QUI PEUVENT SURVENIR ET AVANCEMENT] : ****
' -Les Imgs du Menu ne sont pas redessinйes lorsqu'un itm est survolй...
' -Lorsque ActiveInactive(True) les bordures du bas ne sont pas dessinйes correctement, mais pas lorsque
'  ActiveInactive(False)... ?
' -Permettre de dйs/activer l'apparence de la fenкtre.
' -Petit problиme avec la seconde fenкtre elle cherche а s'afficher sur la barre d'outils.
' -MainForm sera bientot du passй, vous pourrez utiliser n'importe quel nom.
' -Permettre le CliqueDroit sur les items des MenuPopups.
' -???Pour Corriger le contour bleu utiliser un appelle API pour remplacer temporairement  la couleur du systиme
'  qui y corresponds. Pas question de retourner а l'ancien modиle!
' -On pourrait sыrement bйnificier de EXIT EVENT ou EXIT SUB
' -Les Boоtes de Dialogue externent sont masquйes derriиre la fenкtre principale lorsque ToujoursVisible est
'  activй... hmmm... l'alternative est de les crйer/simuler а l'aide de cet OBJET...
'  (Quand зa arrive appuyer sur CTRL+ALT+F4)
' -Comme j'suis nouveau, il peut y avoir des erreurs ou de mauvaises appellation dans la programmation de cet
'  OBJET.
' -Reste а faire un peu le mйnage... puis optimiser un peu le code avec quelques chose du genre de :
'  (seulement а titre d'example, n'est pк pas ce dont il doit avoir l'air... !)
'  dim objExample(5) as QObjExample
'  for i = (1 To 5)
'  i.parent=prntExample' Les 5 objets on le mкme parent... court et pratique... !
'  i.ect=etc... etc... etc...
' -*(IMPOSSIBLE) Les Images du Skin seront intйgrйes dans un imgList... pour facilitйe et tweaker le fichier
'  dans le cas de TweakSkin oщ elles sont remplacйes par une mйthode paint...  Mais la fenкtre ne se repaint
'  pas correctement lorsqu'elle en a besoin...
' -*Maintenant je sais que ToujoursVisible peut avoir l'effet de Perdre le Focus, le code doit кtre semi-intйgrй
'  et doit кtre un peu modifiй pour qu'il prenne en compte les popups...
' -Lorsque Maximisйe prevenir l'empкchement d'accиder au menu dйmarrй soit en dйtectant si la barre est fix
'  ou se masque automatiquement et laisser de la place en consйquence... Screen.Height+2 semble marcher!

$IFNDEF TRUE: $DEFINE True 1
$ENDIF

$IFNDEF FALSE: $DEFINE False 0
$ENDIF

$IFNDEF boolean: $DEFINE boolean integer
$ENDIF

' -- Action de DoubleCliquer sur la Barre de Titre
Const ttNothing		=0'	Aucune action
Const ttDefault		=1'	Action maximize, restore
Const ttCrop		=2'	Rйtrйssis la taille de la fenкtre а celle de la barre de titre...
' -- Fin
'
'******  Quelques API... Fenкtre toujours visible, etc...  ******
'{===
'Const WS_CHILD		=&H40000000
'Const WS_DISABLED		=&H8000000
'Const WS_CHILDWINDOW	=(WS_CHILD)
'Const WS_GROUP		=&H20000

'Const WS_EX_TOPMOST	= &H8&
'}===
Const GWL_WNDPROC	=(-4)
Const GWL_HWNDPARENT=(-8)
'Const GWL_HINSTANCE	=(-6)
'Const GWL_STYLE	=(-16)
'Const GWL_EXSTYLE	=(-20)
'Const GWL_USERDATA	=(-21)
'Const GWL_ID		=(-12)

Const HWND_DESKTOP		=0
'Const HWND_BOTTOM		=1
'Const HWND_TOPMOST		=-1
'Const HWND_NOTOPMOST	=-2

CONST SWP_NOMOVE	= &H2
CONST SWP_NOSIZE	= &H1

'Const WINDOWSTYLE	=HWND_TOPMOST OR HWND_NOTOPMOST OR _
'HWND_DESKTOP OR HWND_BOTTOM
' -- Act/Inactive
Const WM_ACTIVATE	=&H6'-6
Const WM_NCPAINT	=&H85
'Const WM_NCACTIVATE	=&H86' Cause certains problиmes...
Const WA_INACTIVE	=0
Const WA_ACTIVE	=1
Const WA_CLICKACTIVE	=2
' -- Fin

' -- Constants pour TitleBtns
Const tiSystemMenu	=0' Icфne de l'application
Const tiMinimize		=1' Btn Rйduire
Const tiMaximize		=2' Btn Agrandire
Const tiHelp		=3' Btn Aide
Const tiOnTop		=4' Btn ToujoursVisible
'Const tiSysTray		=5' Btn Rйduit dans la barre d'outil
'Const tiUserBtns	=6' 6 et plus... sont des btns persos
' -- Fin
'
'-- Dйtecte si l'Application est dйjа encours...
'CONST rqMainFromClassName	= "TMainForm"
CONST rqClassName		= "TForm"'	-- Classname pour tous les programmes Rapid-Q
'-->	Copiez cette ligne dans votre code avant $INCLUDE "XPSkin***.inc" et inscrivez-y le
'	nom que vous donneriez а votre fenкtre, puis dans votre forme principale inscrivez
'	Caption=myMainFormName.
'
'	CONST myMainFormName="Form style WinXP"
'
'--<	Fin

DECLARE FUNCTION FindWindow LIB "USER32" Alias "FindWindowA" _
	(className AS STRING, windowName AS STRING) AS INTEGER
DECLARE SUB SetForegroundWindow LIB "USER32" Alias "SetForegroundWindow" _
	(HWnd AS LONG)
DECLARE SUB ShowWindow LIB "USER32" Alias "ShowWindow" _
	(HWnd AS LONG, nCmd AS LONG)
'
$TYPECHECK Off
If LEN(myMainFormName)>0 Then
	DEFLNG hWnd=FindWindow(rqClassName, myMainFormName)
	IF hWnd THEN
'		ShowMessage ("Ce programme est dйjа encours d'exйcution!")
		SetForegroundWindow(hWnd): ShowWindow(hWnd,1): END
	END IF
End If
$TYPECHECK On
'-- Fin de la Dйtection
'
'-- Corrige le menu de la barre d'outil
Declare Function SetWindowLong Lib "USER32" Alias "SetWindowLongA" _
	(hwnd as Long, nIndex as Long, dwNewLong as Long) as Long

'SUB MinSet(fHand As Long, GWL_nIndex As Long, newhWnd As Long, appHand As Long)
'	SetWindowLong(fHand, Gwl_Hand, newhWnd)
'	SetWindowLong(appHand, GWL_Hand, fHand)
'END SUB
'Ex :
'	Minset(MainForm.Handle, -8, 0, Application.Handle)
'
Declare Function GetActiveWindow Lib "USER32" Alias "GetActiveWindow" () As Long
'*******************  Fin  ******************
'*  Crйe une fenкtre avec le haut arrondis  *
Declare Function CreateRoundRectRgn Lib "GDI32" Alias "CreateRoundRectRgn" _
	(X1 As Long, Y1 As Long, X2 As Long, Y2 As Long, X3 As Long, Y3 As Long) As Long
Declare Function SetWindowRgn Lib "USER32" Alias "SetWindowRgn" _
	(hwnd As Long, hRgn As Long, bRedraw As Long) As Long
Declare Function CreateRectRgn Lib "gdi32" Alias "CreateRectRgn" _
	(X1 As Long, Y1 As Long, X2 As Long, Y2 As Long) As Long
Declare Function DeleteObject Lib "GDI32" Alias "DeleteObject" _
	(hObject As Long) As Long
' -- Dйplacer une fenкtre sans bordures
Const WM_LBUTTONDOWN	= &H201
Const WM_NCLBUTTONDOWN	=&HA1
Const WM_SYSCOMMAND	=&H112
' Valeurs des Commandes du Menu Systиme
Const SC_MOVE			=&HF010
' Mouse Position Codes
Const HTCAPTION		=2

'Declare Function GetCursor Lib "user32" Alias "GetCursor" () As Long
Declare Function ReleaseCapture Lib "USER32" Alias "ReleaseCapture" () AS Long
' -- Act/Inactive
Declare Function CallWindowProc Lib "USER32" Alias "CallWindowProcA" _
	(lpPrevWndFunc As Long, hwnd As Long, msg As Long, _
	wParam As Long, lParam As Long) As Long
'*******************  Fin  ******************
Declare Function EnableWindow Lib "user32" Alias "EnableWindow" _
	(hwnd As Long, fEnable As Long) As Long
Declare Function IsWindowEnabled Lib "user32" Alias "IsWindowEnabled" _
	(hwnd As Long) As Long
'Declare Function GetWindowLong Lib "user32" Alias "GetWindowLongA" _
'	(hwnd As Long, nIndex As Long) As Long
'****
' GetSystemMetrics() codes
Const SM_CXSCREEN		= 0
Const SM_CYSCREEN		= 1
'Const SM_CXVSCROLL		= 2
'Const SM_CYHSCROLL		= 3
Const SM_CYCAPTION		= 4
'Const SM_CXBORDER		= 5
'Const SM_CYBORDER		= 6
'Const SM_CXDLGFRAME		= 7
'Const SM_CYDLGFRAME		= 8
'Const SM_CYVTHUMB		= 9
'Const SM_CXHTHUMB		= 10
'Const SM_CXICON		= 11
'Const SM_CYICON		= 12
'Const SM_CXCURSOR		= 13
'Const SM_CYCURSOR		= 14
'Const SM_CYMENU		= 15
Const SM_CXFULLSCREEN	= 16
Const SM_CYFULLSCREEN	= 17
'Const SM_CYKANJIWINDOW	= 18
'Const SM_MOUSEPRESENT	= 19
'Const SM_CYVSCROLL		= 20
'Const SM_CXHSCROLL		= 21
'Const SM_DEBUG		= 22
'Const SM_SWAPBUTTON		= 23
'Const SM_RESERVED1		= 24
'Const SM_RESERVED2		= 25
'Const SM_RESERVED3		= 26
'Const SM_RESERVED4		= 27
'Const SM_CXMIN		= 28
'Const SM_CYMIN		= 29
'Const SM_CXSIZE		= 30
'Const SM_CYSIZE		= 31
'Const SM_CXFRAME		= 32
'Const SM_CYFRAME		= 33
'Const SM_CXMINTRACK		= 34
'Const SM_CYMINTRACK		= 35
'Const SM_CXDOUBLECLK		= 36
'Const SM_CYDOUBLECLK		= 37
'Const SM_CXICONSPACING	= 38
'Const SM_CYICONSPACING	= 39
'Const SM_MENUDROPALIGNMENT = 40
'Const SM_PENWINDOWS		= 41
'Const SM_DBCSENABLED		= 42
'Const SM_CMOUSEBUTTONS	= 43
'Const SM_CMETRICS		= 44
'Const SM_CXSIZEFRAME		= SM_CXFRAME
'Const SM_CYSIZEFRAME		= SM_CYFRAME
'Const SM_CXFIXEDFRAME	= SM_CXDLGFRAME
'Const SM_CYFIXEDFRAME	= SM_CYDLGFRAME

Declare Function GetSystemMetrics Lib "user32" Alias "GetSystemMetrics" _
	(nIndex As Long) As Long
'Declare Function GetDesktopWindow Lib "user32" Alias "GetDesktopWindow" () As Long
'Declare Function SetWindowPos Lib "user32" Alias "SetWindowPos" _
'	(hwnd As Long, hWndInsertAfter As Long, x As Long, y As Long, _
'	cx As Long, cy As Long, wFlags As Long) As Long

'****
DEFLNG mhWnd

DiM I AS Integer', DecacheSkin	AS Integer'	Empкche de recharger les imgs plus d'une fois
'						lorsque plus d'une fenкtre...
'If DecacheSkin=0 Then DecacheSkin=-1
'DiM ApparencePath(0 TO 1)	AS String'	Chemin des Apparences
'ApparencePath(0)=Command$()-Application.ExeName+"Apparences\"
'ApparencePath(1)=ApparencePath(0)+"LunaMettalic"'Blue,Mettalic
'DiM ApparenceBMP(0 TO 37)	AS QBitmap'	C'est ici que les skins stoqueront leures images...
'DiM ApparenceSettings		AS QStringList
DiM TwkColor(5)			AS Integer' RGB(102,102,126) >| | |, RGB(251,252,253) |>| |, RGB(168,169,187) | |>|, RGB(201,201,215), RGB(253,255,252), RGB(230,233,228)
DiM MenuColor(6) AS Integer, frmColor(1) AS Integer
DiM TitleBtnsBg(1)		AS QBitmap

frmColor(0)=clBtnFace
frmColor(1)=clBtnFace
TwkColor(0)=cl3DDkShadow
TwkColor(1)=clBtnShadow
TwkColor(2)=cl3DLight
TwkColor(3)=cl3DDkShadow
TwkColor(4)=clBtnShadow
TwkColor(5)=cl3DLight
MenuColor(0)=clBtnFace
MenuColor(1)=cl3DDkShadow
MenuColor(2)=cl3DDkShadow
MenuColor(3)=clBtnFace
MenuColor(4)=clBtnFace
MenuColor(5)=clBtnFace
MenuColor(6)=clBtnFace

'Function GetINIColor(ColorArray As Integer) AS INTEGER
'   dim DefaultINIColor as integer
'   SELECT CASE ColorArray
'	CASE 0, 1, 8, 10, 11, 12, 13, 14: DefaultINIColor=clBtnFace
'	CASE 2, 5, 9: DefaultINIColor=cl3DDkShadow
'	CASE 3, 6: DefaultINIColor=clBtnShadow'cl3DLight
'	CASE 4, 7: DefaultINIColor=cl3DLight
'	CASE ELSE: DefaultINIColor=IIf(LEN(ApparenceSettings.Item(3))>0,RGB(VAL( FIELD$(ApparenceSettings.Item(3),",",1) ),VAL( FIELD$(ApparenceSettings.Item(3),",",2) ),VAL( FIELD$(ApparenceSettings.Item(3),",",3) )),clBtnFace)
'   END SELECT
'   GetINIColor=IIf(LEN(ApparenceSettings.Item(ColorArray+3))>0,RGB(VAL( FIELD$(ApparenceSettings.Item(ColorArray+3),",",1) ),VAL( FIELD$(ApparenceSettings.Item(ColorArray+3),",",2) ),VAL( FIELD$(ApparenceSettings.Item(ColorArray+3),",",3) )), DefaultINIColor)
'End Function
''DiM DRect AS QRect, SRect AS QRect

'SUB ChargeSkin
''   La formule pour optenir les bonnes imgs :
''    SkinTitle WIDTH	= ( BMP.WIDTH - 80 ) /2
''    SkinTitle HEIGHT	= BMP.HEIGHT /2
''    SkinBorder WIDTH	= BMP.WIDTH /4
''    SkinBorder HEIGHT	= BMP.HEIGHT
''    SkinBottom WIDTH	= ( BMP.WIDTH - 80 ) /2
''    SkinBottom HEIGHT	= BMP.HEIGHT /2
'    Dim Title AS QBitmap, Border AS QBitmap, Bottom AS QBitmap
''    Dim BtnFrm AS QBitmap, BtnMax AS QBitmap, BtnMin AS QBitmap, BtnAide AS QBitmap
'    Dim TitleBtns AS QBitmap, TitleBtnsBg AS QBitmap
'    ApparenceSettings.Clear
'    If FileExists(ApparencePath(1)+"\Apparence.txt") Then
'       ApparenceSettings.LoadFromFile (ApparencePath(1)+"\Apparence.txt")
'       ApparenceSettings.Parse(ApparenceSettings.Text,";")
'    End If
'    FOR I =0 TO 5: TwkColor(I)=GetINIColor(I+2): NEXT
'    FOR I =0 TO 6: MenuColor(I)=GetINIColor(I+8): NEXT
'    If DecacheSkin=-2 Then Exit Sub
''Sleep 0,5: ShowMessage "CheckPoint 0"
'    If DecacheSkin and DirExists(ApparencePath(1)) Then: CHDIR ApparencePath(1)' Defaut
'	DecacheSkin=-2
''	If your app hang on loading try to load each BMPs in IE, save them again over each and try again, this should work !
'	If FileExists("SkinTitle.bmp") Then		Title.BMP	="SkinTitle.bmp"
''Sleep 0,5: ShowMessage "CheckPoint 1"
'	If FileExists("SkinBorder.bmp") Then	Border.BMP	="SkinBorder.bmp"'	Don't like small bitmap
''Sleep 0,5: ShowMessage "CheckPoint 2"
'	If FileExists("SkinBottom.bmp") Then	Bottom.BMP	="SkinBottom.bmp"'	Don't like small bitmap
''Sleep 0,5: ShowMessage "CheckPoint 3"
'	If FileExists("SkinTitleBtns.bmp") Then	TitleBtns.BMP	="SkinTitleBtns.bmp"
''Sleep 0,5: ShowMessage "CheckPoint 4"
'	If FileExists("SkinTitleBtnBg.bmp") Then	TitleBtnsBg.BMP	="SkinTitleBtnBg.bmp"
''Sleep 0,5: ShowMessage "CheckPoint 5"
''	Title
'	If Title.Empty=0 Then
'	   ApparenceBMP(0).Width=( Title.WIDTH - 80 ) /2
'	   ApparenceBMP(0).Height=Title.Height/2
'	   ApparenceBMP(0).Draw(0,0,Title.BMP)
'	   ApparenceBMP(1).Width=( Title.WIDTH - 80 ) /2
'	   ApparenceBMP(1).Height=ApparenceBMP(0).Height
'	   ApparenceBMP(1).Draw(-(80+ApparenceBMP(1).Width),0,Title.BMP)
'	   ApparenceBMP(2).Width=80
'	   ApparenceBMP(2).Height=ApparenceBMP(0).Height
'	   ApparenceBMP(2).Draw(-ApparenceBMP(0).Width,0,Title.BMP)
''	   -- Inactive
'	   ApparenceBMP(8).Width=ApparenceBMP(0).Width
'	   ApparenceBMP(8).Height=ApparenceBMP(0).Height
'	   ApparenceBMP(8).Draw(0,-ApparenceBMP(0).Height,Title.BMP)
'	   ApparenceBMP(9).Width=ApparenceBMP(1).Width
'	   ApparenceBMP(9).Height=ApparenceBMP(0).Height
'	   ApparenceBMP(9).Draw(-(80+ApparenceBMP(1).Width),-ApparenceBMP(0).Height,Title.BMP)
'	   ApparenceBMP(10).Width=80
'	   ApparenceBMP(10).Height=ApparenceBMP(0).Height
'	   ApparenceBMP(10).Draw(-ApparenceBMP(0).Width,-ApparenceBMP(0).Height,Title.BMP)
'	End If
''Sleep 0,5: ShowMessage "CheckPoint 6"
''	Border
'	If Border.Empty=0 Then
'	   ApparenceBMP(3).Width=Border.Width/4
'	   ApparenceBMP(3).Height=80
'	   ApparenceBMP(3).Draw(0,0,Border.BMP)
'	   ApparenceBMP(4).Width=ApparenceBMP(3).Width
'	   ApparenceBMP(4).Height=80
'	   ApparenceBMP(4).Draw(-(Border.Width-ApparenceBMP(3).Width),0,Border.BMP)
''	   -- Inactive
'	   ApparenceBMP(11).Width=ApparenceBMP(3).Width
'	   ApparenceBMP(11).Height=80
'	   ApparenceBMP(11).Draw(-ApparenceBMP(3).Width,0,Border.BMP)
'	   ApparenceBMP(12).Width=ApparenceBMP(3).Width
'	   ApparenceBMP(12).Height=80
'	   ApparenceBMP(12).Draw(-(Border.Width/2),0,Border.BMP)
'	End If
''Sleep 0,5: ShowMessage "CheckPoint 7"
''	Bottom
'	If Bottom.Empty=0 Then
'	   ApparenceBMP(5).Width=( Bottom.WIDTH - 80 ) /2
'	   ApparenceBMP(5).Height=Bottom.Height/2
'	   ApparenceBMP(5).Draw(0,0,Bottom.BMP)
'	   ApparenceBMP(6).Width=ApparenceBMP(5).Width
'	   ApparenceBMP(6).Height=ApparenceBMP(5).Height
'	   ApparenceBMP(6).Draw(-(80+ApparenceBMP(5).Width),0,Bottom.BMP)
'	   ApparenceBMP(7).Width=80
'	   ApparenceBMP(7).Height=ApparenceBMP(5).Height
'	   ApparenceBMP(7).Draw(-ApparenceBMP(5).Width,0,Bottom.BMP)
''	   -- Inactive
'	   ApparenceBMP(13).Width=ApparenceBMP(5).Width
'	   ApparenceBMP(13).Height=Bottom.Height/2
'	   ApparenceBMP(13).Draw(0,-ApparenceBMP(5).Height,Bottom.BMP)
'	   ApparenceBMP(14).Width=ApparenceBMP(5).Width
'	   ApparenceBMP(14).Height=ApparenceBMP(5).Height
'	   ApparenceBMP(14).Draw(-(80+ApparenceBMP(5).Width),-ApparenceBMP(5).Height,Bottom.BMP)
'	   ApparenceBMP(15).Width=80
'	   ApparenceBMP(15).Height=ApparenceBMP(5).Height
'	   ApparenceBMP(15).Draw(-ApparenceBMP(5).Width,-ApparenceBMP(5).Height,Bottom.BMP)
'	End If
''Sleep 0,5: ShowMessage "CheckPoint 8"
'	FOR I= 0 TO 19
'	      ApparenceBMP(I+16).Width=TitleBtns.Width/5
'	      ApparenceBMP(I+16).Height=TitleBtns.Height/5
'	      ApparenceBMP(I+16).Draw(-(IIf(I=0 or I=4 or I=8 or I=12 or I=16,0,IIf(I=1 or I=5 or I=9 or I=13 or I=17,1,IIf(I=2 or I=6 or I=10 or I=14 or I=18,2,3)))*ApparenceBMP(I+16).Width),-(IIf(I<4,0,IIf(I>=4 and I<8,1,IIf(I>=8 and I<12,2,IIf(I>=12 and I<16,3,4))))*ApparenceBMP(I+16).Height),TitleBtns.BMP)
''	      ApparenceBMP(I+16).SaveToFile("ttBtnBMP_"+STR$(I)+".bmp")
'	NEXT
''Sleep 0,5: ShowMessage "CheckPoint 9"
'	If TitleBtnsBg.Empty=0 and FileExists("SkinTitleBtnBg.bmp") Then
'	   ApparenceBMP(36).Width=TitleBtnsBg.WIDTH
'	   ApparenceBMP(36).Height=TitleBtnsBg.Height/2
'	   ApparenceBMP(36).Draw(0,0,TitleBtnsBg.BMP)
'	   ApparenceBMP(37).Width=ApparenceBMP(36).Width
'	   ApparenceBMP(37).Height=ApparenceBMP(36).Height
'	   ApparenceBMP(37).Draw(0,-ApparenceBMP(36).Height,TitleBtnsBg.BMP)
'	Else
'	   ApparenceBMP(36).Width=3: ApparenceBMP(36).Height=3
'	   ApparenceBMP(37).Width=3: ApparenceBMP(37).Height=3
'	   ApparenceBMP(36).FillRect(0,0,3,3,clPurple)
'	   ApparenceBMP(37).FillRect(0,0,3,3,clPurple)
'	End If
''Sleep 0,5: ShowMessage "CheckPoint 10"
'	CHDIR Command$()-Application.ExeName
'	FOR I=0 TO 15
'	   If ApparenceBMP(I).Empty Then: ApparenceBMP(I).Width=3: ApparenceBMP(I).Height=3
'	   End If
'	   ApparenceBMP(I).PixelFormat=4'3 lorsque indexйes, 4 pour 16bit
'	NEXT
'    End If
'End Sub
''ShowMessage "CheckPoint 11"

'SUB ChargeNewSkin
'	dim hActWnd as long
'	hActWnd=GetActiveWindow()
'	If DirExists(ApparencePath(1)) Then: DecacheSkin=1
'	   ShowWindow(hActWnd,0)
'	   ShowWindow(mhWnd,0)
'	   Call ChargeSkin
'	   ShowWindow(mhWnd,1)
'	   ShowWindow(hActWnd,1)
'	   SetForegroundWindow(hActWnd)
'	Else: ApparencePath(1)=ApparencePath(0)+"LunaMettalic": DecacheSkin=0
'	End If
'END SUB

dim flagWinProc		AS boolean
    flagWinProc=False

Application.Title=IIF(LEN(myMainFormName)>0,myMainFormName,)'"Form style WinXP")

TYPE myXPSkinnedForm EXTENDS QForm' Fenкtre avec Skin
  WiTH myXPSkinnedForm
'    Caption		AS STRING	PROPERTY SET SetCaption
    TitleBarHide		AS Integer
'    hWnd		AS LONG'	Ramplacй par mhWnd (mainWindowHandle)
    pOldProc		AS LONG
    flagWinProc		AS boolean
'    Alternative		AS QForm'	Si j'utilise QFormEx ici, la fenкtre se rйduira-t-elle correctement.... ? NON!
    XPPopupMenu	AS QForm
    ItmOptions		AS QLabel'	Remplacer avec QCoolBtn et qq QBitmap et qq QCanvas ou QImage... OnMouseMove... BlaBlaBla
    ItmOnTop		AS QLabel
    ItmOnTop_ICO	AS QImage
    ItmDeplace		AS QLabel
    ItmReduire		AS QLabel
    ItmReduire_ICO	AS QImage
    ItmAgrandir		AS QLabel
    ItmAgrandir_ICO	AS QImage
'    ItmSeparateur	AS QLabel
    ItmFermer		AS QLabel
    ItmFermer_ICO	AS QImage
    HiLight		AS QPanel'Canvas
'    HiLight_ICO		AS QImage
    QfRegion		AS Long'	API qui donne la fenкtre ronde sans utiliser le ShapeMask
    Rnd			AS Long'	Propriйtй de la fenкtre ronde
'    RndY		AS Long'	Propriйtй de la fenкtre ronde
'    ToujoursAct		AS Integer
'    ReduireAct		AS Integer
'    FermerAct		AS Interger'	Active le bouton si actif
    ToujoursVisible	AS Integer
    IsInBackGround	AS Integer
    Maximized		AS Integer
    Minimized		AS Integer
    Croped		AS Integer
    CropHeight		AS Integer'	Sauvegarde l'ancienne valeur de Height
    scrWIDTH		AS Integer'	Largeur du Bureau
'    oldWIDTH		AS Integer
    scrHEIGHT		AS Integer'	Hauteur du Bureau
'    oldHEIGHT		AS Integer
'    stdWidth		AS Integer'	Corrige la largeur
'    stdHeight		AS Integer'	Corrige la hauteur
'    AideAct		AS Integer
    PopupBox		AS Integer'	PROPERTY SET SetPopupBox'	Une boоte de dialogue n'affiche que le bouton fermer
    Title_Left		AS QImage
    Title_Mid		AS QImage
    Title_Right		AS QImage
    Title_ICO		AS QImage
    TitleBtnsBg		AS QImage
    ICOAsBMP		AS Integer'	Force l'icфne а кtre une img de votre choix...
    icoList		AS QImageList
    Title_Cap		AS QImage
    Title_Caption		AS QLabel
    TitleAsBMP		AS Integer
    Title_Hot		AS QImage
    Bot_Left		AS QImage
    Bot_Mid		AS QImage
    Bot_Right		AS QImage
    Border_Left		AS QImage
    Border_Right		AS QImage
  Private:
    btn_Toujours		AS QImage
    btn_Aide		AS QImage
    btn_Reduire		AS QImage
    btn_Agrandir		AS QImage
    btn_Fermer		AS QImage
'    ToujoursIsOn		AS Integer
'    AideIsOn		AS Integer
'    ReduireIsOn		AS Integer
'    AgrandirIsOn		AS Integer
'    FermerIsOn		AS Integer
    BtnIsOn(4)		AS Integer
  Public:
    MainBtn		AS QImage
    MainBtn.Caption	AS STRING
    MainBtnIsOn		AS Integer
    MainBtnIs1st		AS Integer
    MainBtnCentered	AS Integer
    PopupL		AS Integer
    PopupT		AS Integer
'    CenterL		AS Integer
'    CenterT		AS Integer
    ClickHold		AS Integer
    TiTleDblClick		AS Integer
    TweakSkin		AS Integer' Accйlиre le Skin et diminue la taille de l'.EXE, en ne peinturant que des lignes
'			plutot que des images.  Ne pas oublier de spйcifier les couleurs... !
'			Utiliser imgListe, sera utile pour rйellement rйduire la taille du programme, puisqu'on aura
'			simplement qu'a ajouter une imgRes vide plutot que de toutes les img requises pour le Skin...
    MainBtnTimer		AS QTimer
    ActiveTimer		AS QTimer
    MenuTimer		AS QTimer

  SUBI DelTitleIcons (...)
	FOR I = 1 TO ParamValCount
	   SELECT CASE ParamVal(I)'+1
	       CASE tiSystemMenu: .Title_ICO.Visible=0' et dйsactive le popup
	       CASE tiMinimize:	.btn_Reduire.Visible=0: .ItmReduire.Visible=0
	       CASE tiMaximize:	.btn_Agrandir.Visible=0: .ItmAgrandir.Visible=0: .TiTleDblClick=IIf(.TiTleDblClick=ttDefault,ttNothing,.TiTleDblClick)
	       CASE tiHelp:	.btn_Aide.Visible=0
	       CASE tiOnTop:	.btn_Toujours.Visible=0: .ItmOnTop.Visible=0
'	       CASE tiSysTray:	.btn_SysTray.Visible=0
'	       CASE tiUserBtns:	.btn_User.Visible=0
	   END SELECT
	   .DelBorderIcons(ParamVal(I))
	NEXT I
  END SUBI

  SUBI AddTitleIcons (...)
	FOR I = 1 TO ParamValCount
	   SELECT CASE ParamVal(I)'+1
	       CASE tiSystemMenu: .Title_ICO.Visible=1' et active le popup
	       CASE tiMinimize:	.btn_Reduire.Visible=1: .ItmReduire.Visible=1
	       CASE tiMaximize:	.btn_Agrandir.Visible=1: .ItmAgrandir.Visible=1
	       CASE tiHelp:	.btn_Aide.Visible=1
	       CASE tiOnTop:	.btn_Toujours.Visible=1: .ItmOnTop.Visible=1
'	       CASE tiSysTray:	.btn_SysTray.Visible=1
'	       CASE tiUserBtns:	.btn_User.Visible=1
	   END SELECT
	   .AddBorderIcons(ParamVal(I))
	NEXT I
  END SUBI

'  PROPERTY SET SetCaption(Title AS String)
'	.Caption=Title: Super.Caption=Title
''	If mhWnd=.Handle Then Application.Title=Title
'  END PROPERTY

 Private:
  SUB mainHandle(Value as Long)
	If mhWnd Then .PopupBox=1: .DelTitleIcons(tiMinimize,tiMaximize): .Center: Exit Sub Else mhWnd=1
  END SUB

 Public:
'  PROPERTY SET SetPopupBox(Value as Integer)
'	If Value=1 Then .DelTitleIcons(tiMinimize,tiMaximize)
'  END PROPERTY

  Sub ActiveOrInactive
	If .IsInBackGround=1 Then
'	   If .Color<>GetINIColor(1) Then .Color=GetINIColor(1)
	   If .Color<>frmColor(1) Then .Color=frmColor(1)
	   If .TweakSkin Then': .ActiveTimer.Enabled=1
	      FOR I=0 TO 2: .Rectangle(.Width-(I+2), .Height-(I+1),I,I, TwkColor(I+3))
	      NEXT
	   Else
	      .Bot_Left.BMPHandle=BOT_LDIS'BMP=ApparenceBMP(13).BMP
	      .Bot_Mid.BMPHandle=BOT_MDIS'BMP=ApparenceBMP(15).BMP
	      .Bot_Right.BMPHandle=BOT_RDIS'BMP=ApparenceBMP(14).BMP
	      .Border_Left.BMPHandle=BORDER_LDIS'BMP=ApparenceBMP(11).BMP
	      .Border_Right.BMPHandle=BORDER_RDIS'BMP=ApparenceBMP(12).BMP
	   End If
	   .Title_Left.BMPHandle=TITLE_LDIS'BMP=ApparenceBMP(8).BMP
	   .Title_Mid.BMPHandle=TITLE_MDIS'BMP=ApparenceBMP(10).BMP
	   .Title_Right.BMPHandle=TITLE_RDIS'BMP=ApparenceBMP(9).BMP
	   .TitleBtnsBg.BMP=TitleBtnsBg(0).BMP'BMPHandle=TITLE_BTNSBGDIS_BMP'BMP=ApparenceBMP(37).BMP
	   .Title_Cap.BMPHandle=TITLE_CAPDIS
	   .btn_Aide.BMPHandle=TAIDEDIS_BMP'BMP=ApparenceBMP(35).BMP
	   .btn_Reduire.BMPHandle=TREDDIS_BMP'BMP=ApparenceBMP(31).BMP
	   .btn_Agrandir.BMPHandle=TFIXDIS_BMP'BMP=ApparenceBMP(27).BMP
	   .btn_Fermer.BMPHandle=TCLOSEDIS_BMP'BMP=ApparenceBMP(19).BMP
	ElseIf .IsInBackGround=2 and IsWindowEnabled(.Handle) Then
	   IF GetActiveWindow()<>.Handle THEN Exit SUB
'	   If .Color<>GetINIColor(0) Then .Color=GetINIColor(0)
	   If .Color<>frmColor(0) Then .Color=frmColor(0)
	   If .TweakSkin Then': .ActiveTimer.Enabled=0
	      FOR I=0 TO 2: .Rectangle(.Width-(I+2), .Height-(I+1),I,I, TwkColor(I))
	      NEXT
	   Else
	      .Bot_Left.BMPHandle=BOT_LEFT'BMP=ApparenceBMP(5).BMP
	      .Bot_Mid.BMPHandle=BOT_MID'BMP=ApparenceBMP(7).BMP
	      .Bot_Right.BMPHandle=BOT_RIGHT'BMP=ApparenceBMP(6).BMP
	      .Border_Left.BMPHandle=BORDER_LEFT'BMP=ApparenceBMP(3).BMP
	      .Border_Right.BMPHandle=BORDER_RIGHT'BMP=ApparenceBMP(4).BMP
	   End If
	   .Title_Left.BMPHandle=TITLE_LEFT'BMP=ApparenceBMP(0).BMP
	   .Title_Mid.BMPHandle=TITLE_MID'BMP=ApparenceBMP(2).BMP
	   .Title_Right.BMPHandle=TITLE_RIGHT'BMP=ApparenceBMP(1).BMP
	   .TitleBtnsBg.BMP=TitleBtnsBg(1).BMP'BMPHandle=TITLE_BTNSBG_BMP'ApparenceBMP(36).BMP
	   .Title_Cap.BMPHandle=TITLE_CAP'BMP=ApparenceBMP(16).BMP
	   .btn_Aide.BMPHandle=TAIDE_BMP'BMP=ApparenceBMP(32).BMP
	   .btn_Reduire.BMPHandle=TRED_BMP'BMP=ApparenceBMP(28).BMP
	   .btn_Agrandir.BMPHandle=TFIX_BMP'BMP=ApparenceBMP(24).BMP
	   .btn_Fermer.BMPHandle=TCLOSE_BMP'BMP=ApparenceBMP(16).BMP
	End If
	If .Title_Mid.Left<>.Title_Left.Width Then'ApparenceBMP(0).Width Then
	   .Border_Left.Top=.Title_Mid.Height'ApparenceBMP(0).Height
'	   .Border_Left.Height=.Height-(.Title_Left.Height+.Bot_Mid.Height)'(ApparenceBMP(0).Height+ApparenceBMP(5).Height)
'	   .Border_Left.Width=ApparenceBMP(3).Width
	   .Border_Right.Top=.Title_Right.Top'ApparenceBMP(1).Height
	   .Border_Right.Left=.Width-(.Border_Right.Width+2)'(ApparenceBMP(4).Width+2)
	   .Border_Right.Height=.Border_Left.Height
'	   .Border_Right.Width=ApparenceBMP(4).Width
	   .Bot_Left.Top=.Height-.Bot_Left.Height'ApparenceBMP(5).Height
	   .Bot_Right.Top=.Bot_Left.Top
'	   .Title_Left.Height=ApparenceBMP(0).Height
'	   .Title_Right.Height=ApparenceBMP(1).Height
	   .Title_Right.Left=.Width-(.Title_Right.Width+2)'(ApparenceBMP(1).Width+2)
	   .Title_Mid.Left=.Title_Left.Width'ApparenceBMP(0).Width
'	   .Title_Mid.Height=ApparenceBMP(2).Height
	   .Title_Mid.Width=.Width-(.Title_Left.Width+.Title_Right.Width)'(ApparenceBMP(0).Width+ApparenceBMP(1).Width)
	   .Title_Hot.Height=.Title_Mid.Height'ApparenceBMP(2).Height
	   .TitleBtnsBg.Height=TitleBtnsBg(0).Height'ApparenceBMP(36).Height
	   .TitleBtnsBg.Left=.Width-(TitleBtnsBg(0).Width+.Title_Right.Width)'(ApparenceBMP(36).Width+ApparenceBMP(1).Width)
	   .Title_ICO.Top=(.Title_Mid.Height-16)/2+1'(ApparenceBMP(2).Height-16)/2+1
	   If .TitleAsBMP Then
	      .Title_Cap.Left=19
	      .Title_Cap.Top=(.Title_Mid.Height-.Title_Cap.Height)/2+1'(ApparenceBMP(2).Height-.Title_Cap.Height)/2+1
	   Else
	      .Title_Caption.Left=23
	      .Title_Caption.Top=(.Title_Mid.Height-.Title_Caption.Height)/2+1'(ApparenceBMP(2).Height-.Title_Caption.Height)/2+1
	   End If
	   .btn_Fermer.Top=(.Title_Mid.Height-.btn_Fermer.Height)/2+1'(ApparenceBMP(2).Height-ApparenceBMP(16).Height)/2+1
	   .btn_Agrandir.Top=.btn_Fermer.Top
	   .btn_Reduire.Top=.btn_Fermer.Top
	   .btn_Aide.Top=.btn_Fermer.Top
'	   .btn_Toujours.Top=.btn_Fermer.Top
	End If
  End Sub

  FUNCTION WindowProc (hwnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
   If .XPPopupMenu.Visible or .flagWinProc=False Then: Result=CallWindowProc(.pOldProc,hwnd,uMsg,wParam,lParam): Exit Function: End If

   SELECT CASE uMsg
     CASE WM_NCPAINT, WM_ACTIVATE, .XPPopupMenu.Visible=0
       If (wParam and &HFFFF)=0 Then: .IsInBackGround=1
'	-- Inactive
'	Result=CallWindowProc(.pOldProc,hwnd,uMsg,wParam,lParam)
''	.btn_Agrandir.Visible=0
	.ActiveOrInactive
       Else: .IsInBackGround=2' Utilisй pour rйtablire la fenкtre lors d'un clique sur la barre de titre
'	-- Active
''	.btn_Agrandir.Visible=1
	.ActiveOrInactive
      End If
'       Result=CallWindowProc(.pOldProc,.handle, umsg, wParam, lParam)
     CASE ELSE
       Result=CallWindowProc(.pOldProc,hwnd,uMsg,wParam,lParam)
     END SELECT
  End Function

  Function ActiveInactive(Value AS boolean) AS boolean
	if .flagWinProc=False and flagWinProc=False then
	   .flagWinProc=True: flagWinProc=True
	   .pOldProc=SetWindowLong(.Handle,GWL_WNDPROC,CODEPTR(myXPSkinnedForm.WindowProc))
	elseif Value=True and flagWinProc=True then
	   .flagWinProc=True
'	   .flagWinProc=False: .ActiveTimer.Enabled=1
	end if
  End Function

'  SUB tmpInactive: .flagWinProc=False: .ActiveTimer.Enabled=1
'  END SUB

  SUB MButOut
	WiTH MainBtn:	.TextOut((.Width-.TextWidth(.Caption))\2,(.Height-.TextHeight(.Caption))\2,.Caption, 0, -1)
	END WiTH
  END SUB

'  SUB ChargeNewSkin
'	dim hActWnd as long
'	hActWnd=GetActiveWindow()
'	If DirExists(ApparencePath(1)) Then: DecacheSkin=1
'	   .Visible=0
''	   ShowWindow(hActWnd,0)
'	   ShowWindow(mhWnd,0)
'	   Call ChargeSkin
'	   .Visible=1
'	   ShowWindow(mhWnd,1)
''	   ShowWindow(hActWnd,1)
'	   SetForegroundWindow(hActWnd)
'	Else: ApparencePath(1)=ApparencePath(0)+"LunaMettalic": DecacheSkin=0
'	End If
'  END SUB

  SUB OnTop
'	-- SetWindowLong(...), Autrement la fenкtre disparaоt..
'	SetWindowLong(.Handle, GWL_HWNDPARENT, HWND_DESKTOP)
'	-- Aumoins cette partie sinon la fenкtre disparaоt...
	SetWindowLong(Application.Handle, GWL_HWNDPARENT, mhWnd)
	If .CropHeight=0 Then .CropHeight=.Title_Mid.Height+.Bot_Mid.Height
	If .ToujoursVisible=0 Then
	   .ToujoursVisible=1: .FormStyle=3
	Else
	   If .CropHeight>.Height Then: SWAP .CropHeight,.Height: .Croped=0'.Minimized=0
	   End If
	   .ToujoursVisible=0: .FormStyle=0
	End If
'	If .WindowState<>wsNormal Then .WindowState=wsNormal
'	SetWindowLong(.Handle, GWL_HWNDPARENT, HWND_DESKTOP)
'	SetWindowLong(Application.HANDLE, GWL_HWNDPARENT, .Handle)
  END SUB

  SUB ItmOptions_Click: END SUB
  EVENT ItmOptions.OnMouseMove
	If .HiLight.Top<>.ItmOptions.Top-1 or .HiLight.Visible=0 Then
		If .HiLight.Font.Color<>clWhite Then .HiLight.Font.Color=clWhite
		.HiLight.Visible=1: .HiLight.Top=.ItmOptions.Top-1
		.HiLight.Caption="    &Options...": .HiLight.Font.DelStyles(0)
	End If
  END EVENT
  SUB ItmOnTop_Click: .OnTop: END SUB
  EVENT ItmOnTop.OnMouseMove
	If .HiLight.Top<>.ItmOnTop.Top-2 or .HiLight.Visible=0 Then
		If .HiLight.Font.Color<>clWhite Then .HiLight.Font.Color=clWhite
		If .PopupBox Then .HiLight.Font.Color=&H7F7F7F
		.HiLight.Visible=1: .HiLight.Top=.ItmOnTop.Top-2
		.HiLight.Caption="    Toujours &Visible": .HiLight.Font.DelStyles(0)
	End If
  END EVENT
  SUB ItmDeplace_Click
	.XPPopupMenu.Close
	ReleaseCapture
	SendMessage(.Handle, WM_SYSCOMMAND, SC_MOVE,0)
'	SendMessage(.Handle, WM_LBUTTONDOWN, HTCAPTION,0)
'	ShowMessage STR$(GetCursor())
  END SUB
  EVENT ItmDeplace.OnMouseMove
	If .HiLight.Top<>.ItmDeplace.Top-2 or .HiLight.Visible=0 Then
		If .HiLight.Font.Color<>clWhite Then .HiLight.Font.Color=clWhite
		If .Maximized Then .HiLight.Font.Color=&H7F7F7F
		.HiLight.Visible=1: .HiLight.Top=.ItmDeplace.Top-2
		.HiLight.Caption="    Dйpla&cement": .HiLight.Font.DelStyles(0)
	End If
  END EVENT
  SUB ItmReduire_Click
	If (.Croped=0 and .ToujoursVisible) Then
	   SWAP .CropHeight,.Height: .Croped=1: .Visible=0: .Visible=1': Application.Minimize
	ElseIf .Croped (.ToujoursVisible or .ToujoursVisible=0) Then
	   SWAP .CropHeight,.Height: .Visible=0: .Visible=1: .WindowState=wsNormal: .Croped=0
	ElseIf .ToujoursVisible=0 Then
	   .XPPopupMenu.Close: .WindowState=wsMinimized': .Minimized=1: .RePaint': Application.Minimize
	End If
  END SUB
  EVENT ItmReduire.OnMouseMove
	If .HiLight.Top<>.ItmReduire.Top-2 or .HiLight.Visible=0 Then
		If .HiLight.Font.Color<>clWhite Then .HiLight.Font.Color=clWhite
		If .PopupBox Then .HiLight.Font.Color=&H7F7F7F
		.HiLight.Visible=1: .HiLight.Top=.ItmReduire.Top-2
		.HiLight.Caption="    &Rйduire": .HiLight.Font.DelStyles(0)
	End If
  END EVENT
  SUB ItmAgrandir_Click: .WindowState=IIf(.WindowState=wsMaximized,wsNormal,wsMaximized)
	.XPPopupMenu.Close
  END SUB
  EVENT ItmAgrandir.OnMouseMove
	If .HiLight.Top<>.ItmAgrandir.Top-2 or .HiLight.Visible=0 Then
		If .HiLight.Font.Color<>clWhite Then .HiLight.Font.Color=clWhite
		If .PopupBox Then .HiLight.Font.Color=&H7F7F7F
		.HiLight.Visible=1: .HiLight.Top=.ItmAgrandir.Top-2
		.HiLight.Caption=IIf(.Maximized,"    Re&stauration","    &Agrandissement")
		.HiLight.Font.DelStyles(0)
	End If
  END EVENT
  SUB ItmFermer_Click
	If .PopupBox Then: .XPPopupMenu.Close: .Close
	Else: .XPPopupMenu.Close: Application.Terminate
	End If
  END SUB
  EVENT ItmFermer.OnMouseMove
	If .HiLight.Top<>.ItmFermer.Top-2 or .HiLight.Visible=0 Then
		If .HiLight.Font.Color<>clWhite Then .HiLight.Font.Color=clWhite
		.HiLight.Visible=1: .HiLight.Top=.ItmFermer.Top-2
		.HiLight.Caption="   "+.ItmFermer.Caption: .HiLight.Font.AddStyles(0)
	End If
  END EVENT
  EVENT HiLight.OnClick
	If .HiLight.Top=.ItmOptions.Top-2 Then:		.ItmOptions_Click
	ElseIf .HiLight.Top=.ItmOnTop.Top-2 Then:	If .PopupBox=0 Then .ItmOnTop_Click
	ElseIf .HiLight.Top=.ItmDeplace.Top-2 Then:	If .WindowState=wsNormal Then .ItmDeplace_Click
	ElseIf .HiLight.Top=.ItmReduire.Top-2 Then:	If .PopupBox=0 Then .ItmReduire_Click
	ElseIf .HiLight.Top=.ItmAgrandir.Top-2 Then:	If .PopupBox=0 Then .ItmAgrandir_Click
	ElseIf .HiLight.Top=.ItmFermer.Top-2 Then:	.ItmFermer_Click
	Else: .XPPopupMenu.Close
	End If
  END EVENT

  EVENT XPPopupMenu.OnShow
	.HiLight.Alignment=0: .HiLight.Font.Color=clWhite
	.XPPopupMenu.Left=.PopupL: .XPPopupMenu.Top=.PopupT
	.HiLight.Visible=0: .HiLight.Caption=""
	.MenuTimer.Enabled=1: .MenuTimer.Interval=1
	If .PopupBox Then .ItmOnTop.Font.Color=&H7F7F7F: .ItmReduire.Font.Color=&H7F7F7F: .ItmAgrandir.Font.Color=&H7F7F7F
'	If .ToujoursVisible Then .ItmOnTop_ICO.Visible=1 Else .ItmOnTop_ICO.Visible=0
	.ItmOnTop_ICO.Visible=Iif(.ToujoursVisible,1,0)' Immediate If
	If .Croped Then'or .Minimized Then
		.ItmReduire_ICO.BMPHandle=ItmRestaurer_BMP': .ItmReduire.Caption="Re&staurer"
	Else:	.ItmReduire_ICO.BMPHandle=ItmReduire_BMP': .ItmReduire.Caption="&Rйduire"
	End If
	If .Maximized Then: .ItmDeplace.Font.Color=&H7F7F7F
	   .ItmAgrandir_ICO.BMPHandle=ItmRestaurer_BMP
	Else: .ItmDeplace.Font.Color=0
	   .ItmAgrandir_ICO.BMPHandle=ItmAgrandir_BMP
	End If
	.ItmReduire.Caption=IIf(.Croped and .ItmReduire.Caption<>"Re&staurer","Re&staurer","&Rйduire")
	.ItmAgrandir.Caption=IIf(.Maximized and .ItmAgrandir.Caption<>"Re&stauration","Re&stauration","&Agrandissement")
'	SetForegroundWindow(.Handle)': ShowWindow(.Handle,1)
  END EVENT
  EVENT XPPopupMenu.OnPaint
	WiTH XPPopupMenu
		.Color=MenuColor(0)'clWhite
		.Rectangle(0,0,.Width,.Height, MenuColor(1))
		FOR I=0 TO 4: .Line(I,.Height-2,I,1, MenuColor(I+2))
		NEXT
		.Line(8,myXPSkinnedForm.ItmFermer.Top-3,.Width-6,myXPSkinnedForm.ItmFermer.Top-3, MenuColor(5))
	END WiTH
  END EVENT
  EVENT MenuTimer.OnTimer(b, x, y, shift)
	IF GetActiveWindow()=.XPPopupMenu.Handle THEN
	   .MenuTimer.Interval=1: .MenuTimer.Enabled=1
	ElseIf  GetActiveWindow()<>.XPPopupMenu.Handle or (b=0 or b=1) Then
	   .MenuTimer.Enabled=0: .XPPopupMenu.Close
	END IF
  END EVENT
  EVENT XPPopupMenu.OnClose: .XPPopupMenu.Visible=0: .MenuTimer.Enabled=0: .HiLight.Visible=0: END EVENT

  EVENT MainBtnTimer.OnTimer
	IF .MainBtnIs1st<1 THEN
	  IF (MouseX>2 and MouseX<(.MainBtn.Width-2)) and (MouseY>2 and MouseY<(.MainBtn.Height-2)) then
	     .MainBtnTimer.Interval = 200
	  ELSEIF .MainBtnIsOn THEN' Aide а rйsoudre les flickings
	   .MainBtnTimer.Enabled=0: .MainBtn.BMPHandle=BNORM_BMP: .MainBtnIsOn=0': CloseWasOn=1
	   .MButOut
	  END IF
	ELSEIF .MainBtnIs1st THEN
	  IF (MouseX>2 and MouseX<(.MainBtn.Width-2)) and (MouseY>2 and MouseY<(.MainBtn.Height-2)) then
	     .MainBtnTimer.Interval=200
	  ELSEIF .MainBtnIsOn THEN' Aide а rйsoudre les flickings
	     .MainBtnTimer.Enabled=0: .MainBtn.BMPHandle=BSEL_BMP: .MainBtnIsOn=0': CloseWasOn=1
	     .MButOut
	  END IF
	END IF
  END EVENT

  EVENT OnPaint
'	If .Minimized and .ToujoursVisible=0 Then .Minimized=0: .WindowState=wsMinimized': Application.Minimize
'	If .Color<>GetINIColor(0) Then .Color=GetINIColor(0)
	If .Color<>frmColor(0) Then .Color=frmColor(0)
	If .TweakSkin Then
	   FOR I=0 TO 2: .Rectangle(.Width-(I+2), .Height-(I+1),I,I, TwkColor(I))
	   NEXT
	End If
	If .WindowState=wsMaximized and .Title_Right.Left<>.Width-(.Title_Right.Width+2) Then: .Maximized=3
	   .Title_Right.Left=.Width-(.Title_Right.Width+2)
	   .Title_Mid.Width=.Width-(.Title_Left.Width+.Title_Right.Width-2)
	   .Border_Right.Left=.Width-(.Border_Right.Width+2)
	   .Bot_Right.Left=.Width-(.Bot_Right.Width+2)
	   .Bot_Mid.Width=.Width-(.Bot_Left.Width+.Bot_Right.Width+2)
	   .btn_Fermer.Left=.Width-27
'	   If .PopupBox=0 Then
'		If .AddTitleBtns(1)>0 and .AddTitleBtns(0)>0 Then: .btn_Aide.Left=.Width-98
'		Else: .btn_Aide.Left=.Width-(IIf(.AddTitleBtns(1)>0 or .AddTitleBtns(0)>0,75,52))
'		End If
'		If .AddTitleBtns(0)>0 Then
'		   .btn_Reduire.Left=.Width-(Iif(.AddTitleBtns(1)>0,73,50))
'		End If
'		If .AddTitleBtns(1)>0 Then
'		   .btn_Agrandir.Left=.Width-50
'		End If
'	   Else
'		If .AddTitleBtns(1)=1 and .AddTitleBtns(0)=1 Then: .btn_Aide.Left=.Width-98
'		Else: .btn_Aide.Left=.Width-(IIf(.AddTitleBtns(1)=1 or .AddTitleBtns(0)=1,75,52))
'		End If
'		If .AddTitleBtns(0)=1 Then
'		   .btn_Reduire.Left=.Width-(Iif(.AddTitleBtns(1)=1,73,50))
'		End If
'		If .AddTitleBtns(1)=1 Then
'		   .btn_Agrandir.Left=.Width-50
'		End If
'	   End If
'	   .Visible=0: .Visible=1
	End If
'	.TextOut(10,.Height-50,"ActiveTimer Actif :      "+STR$(.ActiveTimer.Enabled),0,-1)
'	.TextOut(10,.Height-60,"Taille Fenкtre :   "+STR$(.Width)+" x "+STR$(.Height),0,-1)
'	.TextOut(10,.Height-70,"Taille Йcran :      "+STR$(.scrWidth)+" x "+STR$(.scrHeight),0,-1)
'	.TextOut(10,.Height-80,"Title_Right.Left : "+STR$(.Title_Right.Left),0,-1)
'	.TextOut(150,.Height-50,"PopupBox :      "+STR$(.PopupBox),0,-1)
'	.TextOut(150,.Height-60,"hInst App :        "+STR$(Application.Handle),0,-1)
'	.TextOut(150,.Height-70,"hInst Qform :     "+STR$(.Handle),0,-1)
'	.TextOut(150,.Height-80,"hInst mhWnd :  "+STR$(mhWnd),0,-1)
'	.TextOut(10,.Height-90,"mhWnd doit йgaler l'Handle la forme principale",0,-1)
'	.TextOut(10,.Height-110,"frmCap   : "+.Caption,0,-1)
'	.TextOut(10,.Height-120,"SupCap : "+Super.Caption,0,-1)
'	.TextOut(10,.Height-130,"AppCap : "+Application.Title,0,-1)
'	.TextOut(10,.Height-150,"Dйbogage :",0,-1)
	If .WindowState=wsMaximized and .Maximized=1 Then .Maximized=2
	.IsInBackGround=0
  END EVENT
  EVENT ActiveTimer.OnTimer
    If .XPPopupMenu.Visible Then Exit Event
    IF GetActiveWindow()<>.Handle THEN: .flagWinProc=False
	If .IsInBackGround<>1 Then: .IsInBackGround=1: .ActiveOrInactive
	End If
    ElseIf GetActiveWindow()=.Handle Then: .ActiveTimer.Enabled=IIf(.PopupBox,1,0): .flagWinProc=IIf(flagWinProc=True and .flagWinProc=False,True,False)
	If .IsInBackGround<>2 Then: .IsInBackGround=2: .ActiveOrInactive
	End If
    End If
  END EVENT

  EVENT OnResize
	.scrHeight=GetSystemMetrics(IIf(Screen.Height-GetSystemMetrics(SM_CYFULLSCREEN)=<GetSystemMetrics(SM_CYCAPTION),_
	SM_CYSCREEN,SM_CYFULLSCREEN))
	.scrWidth=GetSystemMetrics(SM_CXFULLSCREEN)
	If .WindowState=wsMaximized and .Maximized=0 Then: .Maximized=1: .TitleBarHide=0
'	   DeleteObject .QfRegion
'	   .Height=.scrHeight+GetSystemMetrics(SM_CYCAPTION): .Width=.scrWidth+3
'>	   .QfRegion=CreateRectRgn(0,0,.scrWidth+2,.scrHeight+2)
'>	   SetWindowRgn .handle,.QfRegion,True
	   .Visible=0: .Visible=1
'	-- Cette ligne peut empкcher de restaurer la fenкtre а partir de la barre des tвches si utilisйe
'	   de cette faзon :  .WindowState<>wsMaximized
	ElseIf .WindowState=wsNormal and .Maximized Then: .Maximized=0: .Visible=0: .Visible=1
'	ElseIf .WindowState<>wsMaximized and .Croped Then: .Croped=0: .Visible=0: .Visible=1
	End If
'	If (.Height=.scrHeight and .Width=.scrWidth) Then: .Visible=0: .Visible=1: End If
'	.Visible=0: .Height=.scrHeight:.Visible=1': .RePaint
'	ShowMessage STR$(.Width)+" x "+STR$(.Height)
'	If .WindowState=wsMaximized Then: .Visible=0: .Visible=1
'	ElseIf .WindowState=wsNormal and (.height=.oldheight and .oldheight>0) and _
'	(.width=.oldwidth and .oldwidth>0) Then: .Visible=0: .Visible=1
'	End If' Retour en normal purement instable...
  END EVENT

  EVENT OnShow
	If .flagWinProc=True and .pOldProc=0 and mhWnd<>.Handle Then .ActiveTimer.Enabled=1
	mhWnd=FindWindow(rqClassName, myMainFormName)
'	SetWindowLong(mhWnd, GWL_HWNDPARENT, HWND_DESKTOP)
'	SetWindowLong(Application.Handle, GWL_HWNDPARENT, mhWnd)
'	If .Height<.scrHEIGHT and .Width<.scrWIDTH Then: .oldWIDTH=.Width: .oldHEIGHT=.Height: End If
'	-- Cette boоte ne sera pas affichйe si $TYPECHECK est On
	If LEN(myMainFormName)=0 or mhWnd<=2 Then ShowMessage _
	   "Attention une entrйe est incorrecte... le programme va continuer а"+CHR$(13)+_
	   "fonctionner, mais pour des raisons de compatibilitй veuillez ajouter la"+CHR$(13)+_
	   "ligne CONST myMainFormName="+CHR$(34)+"Le nom de votre forme"+CHR$(34)+_
	   +"et ajouter"+CHR$(13)+"а votre forme principale .Caption=myMainFormName."+_
	   CHR$(13)+CHR$(13)+_
	   "Ce faissant vous ne devriez plus recevoir ce message d'erreur."
'	--
'	If myMainFormName<>.Caption Then .PopupBox=1
'	If MainForm.Caption<>.Caption Then .PopupBox=1' Tente de dйtecter si c'est une Bфite de dialogue et mкme aller jusqu'а ajouter .Parent=MainForm pourquoi pas
	If mhWnd<>.Handle Then: .PopupBox=1
'	If .PopupBox Then
'	   .CenterL=(Screen.Width-.Width)\2: .CenterT=(Screen.Height-.Height)\2
'	   .Left=(Screen.Width-.Width)\2'.CenterL
'	   .Top=(Screen.Height-.Height)\2'.CenterT
	   If MainForm.FormStyle=3 Then: .Visible=0: .FormStyle=3: End If': .Parent=.Alternative
'	   If GetWindowLong(.handle,GWL_EXSTYLE)<GetWindowLong(mhWnd,GWL_EXSTYLE) and .FormStyle<>3 Then
'	      .Visible=0: .FormStyle=3
'	   End If
'	   SetWindowLong(.handle, GWL_HWNDPARENT, Getwindowlong(mhWnd, GWL_HWNDPARENT) OR WindowStyle)
'	   ShowMessage "Panic!"+NL+_
'	   STR$(GetWindowLong(mhWnd,GWL_EXSTYLE))+NL+_
'	   STR$(GetWindowLong(.handle,GWL_EXSTYLE))
	   .Visible=1'	Prйvient l'empиchement de la fermeture de la fenкtre
	   If MainForm.TweakSkin and .TweakSkin=0 Then .TweakSkin=1
'	   MainForm.Enabled=0
	   EnableWindow(mhWnd,)
	ElseIf mhWnd=.Handle and .PopupBox Then: .PopupBox=0
	End If
'	If .ToujoursVisible Then .Parent=.Alternative'	Ne pas dйplacer, doit toujours кtre aprиs FormStyle
'	If .Croped=0 Then .Height=.Height+20' Corrige la hauteur lorsque la barre de titre est cachйe
'	If .stdHeight<>.Height Then .stdHeight=.Height
'	If .stdWidth<>.Width Then .stdWidth=.Width+2
	.ShowTitleBar: .HideTitleBar
	If .TitleBarHide=0 Then: .Height=.Height+GetSystemMetrics(SM_CYCAPTION)
	   .TitleBarHide=1
	End If
'	If .stdHeight<>.Height Then .Height=.stdHeight' Fix height appraоt avoir masquй la barre de titre
'	If .stdWidth<>.Width Then .Width=.stdWidth
	.QfRegion=CreateRoundRectRgn(1,1,.Width,.Height+(.Rnd/3),.Rnd,.Rnd)
	SetWindowRgn .handle,.QfRegion,True
'	-- Affiche un bouton par dйfaut
	.MainBtn.Autosize=1
	.MainBtn.Parent=myXPSkinnedForm
	If .MainBtnCentered or .MainBtn.Top<30 Then .MainBtn.Top=.Height-34
	If .MainBtnIs1st<1 Then .MainBtn.BMPHandle=BNORM_BMP Else .MainBtn.BMPHandle=BSEL_BMP
'	.MainBtn.Font=Font
	.MButOut
'	-- Fin du bouton par dйfaut
	.Title_Left.Parent=myXPSkinnedForm
	.Title_Left.Autosize=1
	.Title_Left.BMPHandle=TITLE_LEFT'BMP=ApparenceBMP(0).BMP
	.Title_Right.Parent=myXPSkinnedForm
	.Title_Right.Autosize=1
	.Title_Right.BMPHandle=TITLE_RIGHT'BMP=ApparenceBMP(1).BMP
	.Title_Right.Left=.Width-(.Title_Right.Width+2)
	.Title_Mid.Parent=myXPSkinnedForm
	.Title_Mid.Autosize=1
	.Title_Mid.BMPHandle=TITLE_MID'BMP=ApparenceBMP(2).BMP
	.Title_Mid.Left=.Title_Left.Width'-1
	.Title_Mid.Autosize=0
	.Title_Mid.Width=.Width-(.Title_Left.Width+.Title_Right.Width-2)
	.Title_Mid.Stretch=1
	If .TitleAsBMP Then
	   .Title_Cap.Parent=myXPSkinnedForm: .Title_Cap.AutoSize=1
	   .Title_Cap.BMPHandle=TITLE_CAP'BMP=ApparenceBMP(16).BMP
	   .Title_Cap.Left=19: .Title_Cap.Top=(.Title_Mid.Height-.Title_Cap.Height)/2+1'8
	Else
	   .Title_Caption.Parent=myXPSkinnedForm: .Title_Caption.AutoSize=1
	   .Title_Caption.Left=23
'	   .Title_Caption.Font=Font
	   .Title_Caption.Font.AddStyles(0)
	   .Title_Caption.LabelStyle=1: .Title_Caption.Transparent=1
	   .Title_Caption.Caption=REPLACESUBSTR$(.Caption, "&", "&&")
	   .Title_Caption.Top=(.Title_Mid.Height-.Title_Caption.Height)/2+1'8
	End If
	If .TweakSkin=0 Then
	   .Bot_Mid.Parent=myXPSkinnedForm
	   .Bot_Mid.AutoSize=1
	   .Bot_Mid.BMPHandle=BOT_MID'BMP=ApparenceBMP(7).BMP
	   .Border_Left.Parent=myXPSkinnedForm
	   .Border_Left.Autosize=1
	   .Border_Left.BMPHandle=BORDER_LEFT'BMP=ApparenceBMP(3).BMP
	   .Border_Left.Top=.Title_Mid.Height
	   .Border_Left.Autosize=0
	   .Border_Left.Height=.Height-(.Title_Mid.Height+.Bot_Mid.Height+1)
	   .Border_Left.Stretch=1
	   .Border_Right.Parent=myXPSkinnedForm
	   .Border_Right.Autosize=1
	   .Border_Right.BMPHandle=BORDER_RIGHT'BMP=ApparenceBMP(4).BMP
	   .Border_Right.Left=.Width-(.Border_Right.Width+2)
	   .Border_Right.Top=.Title_Mid.Height
	   .Border_Right.Autosize=0
	   .Border_Right.Height=.Border_Left.Height'.Height-(.Title_Mid.Height+.Bot_Mid.Height)
	   .Border_Right.Stretch=1
	End If
	.TitleBtnsBg.Parent=myXPSkinnedForm
	.TitleBtnsBg.BMP=TitleBtnsBg(0).BMP'ApparenceBMP(36).BMP
	.TitleBtnsBg.AutoSize=1
	.TitleBtnsBg.Transparent=1
	.TitleBtnsBg.Left=.Width-(.TitleBtnsBg.Width+.Title_Right.Width)
	.Title_Hot.Parent=myXPSkinnedForm'-- Imitation d'un HotSpot
	.Title_Hot.Width=.Width
	.Title_Hot.Height=.Title_Mid.Height
	.Title_Hot.Transparent=1
	.Title_ICO.Parent=myXPSkinnedForm
	.Title_ICO.Left=4: .Title_ICO.Top=(.Title_Hot.Height-16)/2+1
	.Title_ICO.Width=16: .Title_ICO.Height=16
	.Title_ICO.Transparent=1
	If .ICOAsBMP Then .Title_ICO.BMPHANDLE=TITLE_ICO Else .Title_ICO.BMP=.icoList.GetBMP(0)
'	.Title_ICO.BMP=Iif(.ICOAsBMP,TITLE_ICO,.icoList.GetBMP(0))'Immediate If' Don't like arrays in iif
	.Title_ICO.Stretch=1
	.btn_Fermer.Parent=myXPSkinnedForm'	Title_Hot
	.btn_Fermer.Left=.Width-27
	.btn_Fermer.Autosize=1
	.btn_Fermer.BMPHandle=TCLOSE_BMP'BMP=ApparenceBMP(16).BMP
	.btn_Fermer.Top=(.Title_Mid.Height-.btn_Fermer.Height)/2+1'5
	.btn_Fermer.Hint="Fermer"
	If .btn_Aide.Visible Then: .btn_Aide.Parent=myXPSkinnedForm'	Title_Hot
	   If .btn_reduire.visible and .btn_Agrandir.visible then: .btn_Aide.Left=.Width-98
	   Else: .btn_Aide.Left=.Width-(IIf(.btn_reduire.visible or .btn_Agrandir.visible,75,52))
	   End If
	   .btn_Aide.Top=.btn_Fermer.Top
	   .btn_Aide.Autosize=1
	   .btn_Aide.BMPHandle=TAIDE_BMP'BMP=ApparenceBMP(32).BMP
	   .btn_Aide.Hint="Aide"
	End If
	If .btn_reduire.visible Then: .btn_Reduire.Parent=myXPSkinnedForm' Title_Hot
	   .btn_Reduire.Left=.Width-(Iif(.btn_Agrandir.visible,73,50))'Immediate If
	   .btn_Reduire.Top=.btn_Fermer.Top
	   .btn_Reduire.Autosize=1
	   .btn_Reduire.BMPHandle=TRED_BMP'BMP=ApparenceBMP(28).BMP
	   .btn_Reduire.Hint="Rйduire"
	End If
	If .btn_Agrandir.visible Then: .btn_Agrandir.Parent=myXPSkinnedForm' Title_Hot
	   .btn_Agrandir.Left=.Width-50
	   .btn_Agrandir.Top=.btn_Fermer.Top
	   .btn_Agrandir.Autosize=1
	   .btn_Agrandir.BMPHandle=TFIX_BMP'BMP=ApparenceBMP(24).BMP
	   .btn_Agrandir.Hint=IIf(.WindowState=wsMaximized,"Restaurer","Agrandir")
	End If
	If .TweakSkin=0 Then
	   .Bot_Left.Parent=myXPSkinnedForm
	   .Bot_Left.AutoSize=1
	   .Bot_Left.BMPHandle=BOT_LEFT'BMP=ApparenceBMP(5).BMP
	   .Bot_Left.Top=.Height-.Bot_Left.Height-1
	   .Bot_Right.Parent=myXPSkinnedForm
	   .Bot_Right.AutoSize=1
	   .Bot_Right.BMPHandle=BOT_RIGHT'BMP=ApparenceBMP(6).BMP
	   .Bot_Right.Top=.Bot_Left.Top'.Height-.Bot_Right.Height
	   .Bot_Right.Left=.Width-(.Bot_Right.Width+2)
	   .Bot_Mid.AutoSize=0
	   .Bot_Mid.Top=.Bot_Left.Top'.Height-.Bot_Mid.Height
	   .Bot_Mid.Left=.Bot_Left.Width
	   .Bot_Mid.Width=.Width-(.Bot_Left.Width+.Bot_Right.Width+2)
	   .Bot_Mid.Stretch=1
	End If
	If .MainBtnCentered Then .MainBtn.Left=(.Width-.MainBtn.Width)\2
	.XPPopupMenu.Parent=myXPSkinnedForm'.Alternative' Empкche la disparition de la fenкtre lorsque le menu est affichй et que ToujoursVisible est activй
	.XPPopupMenu.FormStyle=3: .XPPopupMenu.BorderStyle=0
	.XPPopupMenu.Width=123
	.HiLight.Parent=.XPPopupMenu: .HiLight.BevelWidth=0: .HiLight.BorderStyle=0: .HiLight.Left=6: .HiLight.Top=2: .HiLight.Color=MenuColor(1)'RGB(180,189,199)
	.ItmOptions.Parent=.XPPopupMenu: .ItmOptions.AutoSize=1: .ItmOptions.Transparent=1
	.ItmOptions.Left=18: .ItmOptions.Top=3
	.ItmOptions.Caption="&Options..."
	.ItmOptions.AutoSize=0: .ItmOptions.Width=(.XPPopupMenu.Width-.ItmOptions.Left)-4
	.ItmOnTop_ICO.Visible=IIf(.btn_Toujours.Visible,1,0)
	If .btn_Toujours.Visible Then
'	If .btn_Agrandir.Visible Then
	   .ItmOnTop.Parent=.XPPopupMenu: .ItmOnTop.AutoSize=1: .ItmOnTop.Transparent=1
	   .ItmOnTop.Left=18: .ItmOnTop.Top=3+(.ItmOptions.Top+.ItmOptions.Height)
	   .ItmOnTop.Caption="Toujours &Visible"
	   .ItmOnTop.AutoSize=0: .ItmOnTop.Width=(.XPPopupMenu.Width-.ItmOnTop.Left)-4
	   .ItmOnTop.Visible=1
	   .ItmOnTop_ICO.Visible=0: .ItmOnTop_ICO.Parent=.XPPopupMenu
	   .ItmOnTop_ICO.AutoSize=1: .ItmOnTop_ICO.BMPHandle=ItmOnTop_BMP
	   .ItmOnTop_ICO.Left=6: .ItmOnTop_ICO.Top=.ItmOnTop.Top+1
	End If
	.ItmDeplace.Parent=.XPPopupMenu: .ItmDeplace.AutoSize=1: .ItmDeplace.Transparent=1
	.ItmDeplace.Left=18: .ItmDeplace.Top=3+(.ItmOnTop.Top+.ItmOnTop.Height)
	.ItmDeplace.Caption="Dйpla&cement"
	.ItmDeplace.AutoSize=0: .ItmDeplace.Width=(.XPPopupMenu.Width-.ItmDeplace.Left)-4
	.ItmReduire_ICO.Visible=IIf(.btn_Reduire.Visible,1,0)
	If .btn_Reduire.Visible Then
	   .ItmReduire.Parent=.XPPopupMenu: .ItmReduire.AutoSize=1: .ItmReduire.Transparent=1
	   .ItmReduire.Left=18: .ItmReduire.Top=3+(.ItmDeplace.Top+.ItmDeplace.Height)
	   .ItmReduire.Caption="Rй&duire"
	   .ItmReduire.AutoSize=0: .ItmReduire.Width=(.XPPopupMenu.Width-.ItmReduire.Left)-4
	   .ItmReduire.Visible=1
	   .ItmReduire_ICO.Parent=.XPPopupMenu: .ItmReduire_ICO.AutoSize=1
	   .ItmReduire_ICO.BMPHandle=ItmReduire_BMP
	   .ItmReduire_ICO.Left=6: .ItmReduire_ICO.Top=.ItmReduire.Top+1
	End If
	.ItmAgrandir_ICO.Visible=IIf(.btn_Agrandir.Visible,1,0)
	If .btn_Agrandir.Visible Then
	   .ItmAgrandir.Parent=.XPPopupMenu: .ItmAgrandir.AutoSize=1: .ItmAgrandir.Transparent=1
	   .ItmAgrandir.Left=18: .ItmAgrandir.Top=3+(IIf(.ItmReduire.Visible,.ItmReduire.Top+.ItmReduire.Height,.ItmDeplace.Top+.ItmDeplace.Height))
	   .ItmAgrandir.Caption="&Agrandissement"
	   .ItmAgrandir.AutoSize=0: .ItmAgrandir.Width=(.XPPopupMenu.Width-.ItmAgrandir.Left)-4
	   .ItmAgrandir.Visible=1
	   .ItmAgrandir_ICO.Parent=.XPPopupMenu: .ItmAgrandir_ICO.AutoSize=1
	   .ItmAgrandir_ICO.BMPHandle=ItmAgrandir_BMP
	   .ItmAgrandir_ICO.Left=6: .ItmAgrandir_ICO.Top=.ItmAgrandir.Top+1
	End If
'	.ItmSeparateur.Parent=.XPPopupMenu: .ItmSeparateur.AutoSize=1: .ItmSeparateur.Transparent=1
'	.ItmSeparateur.Left=18: .ItmSeparateur.Top=3'+(.ItmReduire.Top+.ItmReduire.Height)
'	.ItmSeparateur.Caption="-"
'	.ItmSeparateur.AutoSize=0: .ItmSeparateur.Width=(.XPPopupMenu.Width-.ItmSeparateur.Left)-4
''	.ItmSeparateur.Height=.ItmReduire.Height/2
	.ItmFermer.Parent=.XPPopupMenu: .ItmFermer.AutoSize=1: .ItmFermer.Transparent=1
	.ItmFermer.Left=18: .ItmFermer.Top=6+(IIf(.ItmAgrandir.Visible=1,.ItmAgrandir.Top+.ItmAgrandir.Height,IIf(.btn_Reduire.Visible,.ItmReduire.Top+.ItmReduire.Height,.ItmDeplace.Top+.ItmDeplace.Height)))
	.ItmFermer.Caption="&Fermeture  Alt+F4"
	.ItmFermer.Font.AddStyles(0)
	.ItmFermer.AutoSize=0: .ItmFermer.Width=(.XPPopupMenu.Width-.ItmFermer.Left)-4
	.ItmFermer_ICO.Parent=.XPPopupMenu: .ItmFermer_ICO.AutoSize=1
	.ItmFermer_ICO.BMPHandle=ItmFermer_BMP
	.ItmFermer_ICO.Left=6: .ItmFermer_ICO.Top=.ItmFermer.Top+1
	If 16+(.ItmOptions.Width or .ItmOnTop.Width or .ItmDeplace.Width or .ItmReduire.Width or .ItmFermer.Width)-4>.XPPopupMenu.Width Then
		If .ItmOptions.Width>(.ItmOnTop.Width or .ItmDeplace.Width or .ItmReduire.Width or .ItmFermer.Width) Then
		   .XPPopupMenu.Width=.ItmOptions.Width+4
		ElseIf .ItmOnTop.Width>(.ItmOptions.Width or .ItmDeplace.Width or .ItmReduire.Width or .ItmFermer.Width) Then
		   .XPPopupMenu.Width=.ItmOnTop.Width+4
		ElseIf .ItmDeplace.Width>(.ItmOptions.Width or .ItmOnTop.Width or .ItmReduire.Width or .ItmFermer.Width) Then
		   .XPPopupMenu.Width=.ItmDeplace.Width+4
		ElseIf .ItmReduire.Width>(.ItmOptions.Width or .ItmDeplace.Width or .ItmOnTop.Width or .ItmFermer.Width) Then
		   .XPPopupMenu.Width=.ItmReduire.Width+4
		ElseIf .ItmAgrandir.Width>(.ItmOptions.Width or .ItmDeplace.Width or .ItmOnTop.Width or .ItmFermer.Width) Then
		   .XPPopupMenu.Width=.ItmAgrandir.Width+4
		ElseIf .ItmFermer.Width>(.ItmOptions.Width or .ItmDeplace.Width or .ItmOnTop.Width or .ItmReduire.Width) Then
		   .XPPopupMenu.Width=.ItmFermer.Width+4
		End If
	End If
	.HiLight.Width=.XPPopupMenu.Width-8: .HiLight.Height=.ItmOptions.Height+4
	.XPPopupMenu.Height=5+(.ItmFermer.Top+.ItmFermer.Height)
'	If .PopupBox=0 Then Application.Title=.Caption
	Application.ICOHandle=ICO
'	Call myXPSkinnedForm.ActiveInactive
	If mhWnd=.Handle Then
	   SetWindowLong(.Handle, GWL_HWNDPARENT, HWND_DESKTOP)
	   SetWindowLong(Application.HANDLE, GWL_HWNDPARENT, .Handle)
	End If
'	{===
'	SetWindowLong .XPPopupMenu.Handle, Gwl_style, WS_GROUP
'	}===
'	-- Peut pк rйsoudre le problиme oщ la barre des tвches est masquйe derriиre toutes les
'	   fenкtres lorsque cette fenкtre est Maximizйe...
'	GetDesktopWindow
  END EVENT

  EVENT OnClose
	DeleteObject .QfRegion
	.XPPopupMenu.Close
	If mhWnd<>.Handle Then
'	If .PopupBox Then
	      EnableWindow(mhWnd,1)': MainForm.Enabled=1': SetFocus(MainForm.Handle)' L'activer redonne le focus...
	Else: Application.Terminate
	End If
  END EVENT

'*******  Now Fully Working Script  *******
  EVENT Title_Hot.OnMouseDown(b, x, y, shift)
'	If .IsInBackGround>0 Then .Repaint' Force la fenкtre а se redessiner...
'	If GetCursor()=2638 Then SendMessage(.Handle, WM_LBUTTONDOWN, HTCAPTION,0)
	If b=1 Then
	    If .PopupL<>(.Left+.Title_ICO.Left)-1 Then .XPPopupMenu.Close
	    If .XPPopupMenu.Visible=0 Then
	       .PopupL=Screen.MouseX: .PopupT=Screen.MouseY: .XPPopupMenu.Show
	    End If
	ElseIf b=0 Then
	   If .WindowState=wsNormal Then: ReleaseCapture
	      SendMessage(.Handle, WM_NCLBUTTONDOWN, HTCAPTION,0)
	      .XPPopupMenu.Close
	   End If
	End If
  END EVENT
  EVENT Title_Hot.OnDblClick
       If .PopupBox=0 Then
	If .ToujoursVisible and .TiTleDblClick=ttNothing Then
	   If .Croped=0 Then
		SWAP .CropHeight,.Height: .Croped=1: .Visible=0: .Visible=1': Application.Minimize
	   Else:	SWAP .CropHeight,.Height: .Visible=0: .WindowState=wsNormal: .Visible=1: .Croped=0
	   End If
	ElseIf .TiTleDblClick=ttDefault Then
	   .scrHeight=GetSystemMetrics(IIf(Screen.Height-GetSystemMetrics(SM_CYFULLSCREEN)=<GetSystemMetrics(SM_CYCAPTION),_
	   SM_CYSCREEN,SM_CYFULLSCREEN))
	   .scrWidth=GetSystemMetrics(SM_CXFULLSCREEN)
	   If .WindowState=wsNormal Then
'	   If (.Height=.oldHeight and .Width=.oldWidth) Then
'	      .Visible=0: SWAP .Height,.scrHeight: SWAP .Width,.scrWidth: .Visible=1:
	      .WindowState=wsMaximized': .Repaint
'	   ElseIf (.Height>.oldHeight and .Width>.oldWidth) Then
	   ElseIf .WindowState=wsMaximized Then
'	      SWAP .Height,.oldHeight: SWAP .Width,.oldWidth: .Visible=0: .Visible=1:
	      .WindowState=wsNormal': .Repaint
	   End If
	ElseIf .TiTleDblClick=ttCrop Then
	   If .Croped=0 Then
		SWAP .CropHeight,.Height: .Croped=1: .Visible=0: .Visible=1': Application.Minimize
	   Else:	SWAP .CropHeight,.Height: .Croped=0: .Visible=0: .Visible=1': .WindowState=wsNormal: .Croped=0
	   End If
	End If
       End If
  END EVENT
  Event Title_Hot.OnMouseMove
	If .BtnIsOn(0) and .btn_Fermer.BMPHandle<>TCLOSE_BMP Then
	   If .IsInBackGround=1 Then .btn_Fermer.BMPHandle=TCLOSEDIS_BMP Else .btn_Fermer.BMPHandle=TCLOSE_BMP
	   .BtnIsOn(0)=0
	End If
'	If .BtnIsOn(0) and (.btn_Fermer.BMP=ApparenceBMP(17).BMP or .btn_Fermer.BMP=ApparenceBMP(18).BMP) Then
'	   If .IsInBackGround=1 Then .btn_Fermer.BMP=ApparenceBMP(19).BMP Else .btn_Fermer.BMP=ApparenceBMP(16).BMP
'	   .BtnIsOn(0)=0
'	End If

	If .BtnIsOn(1) and .btn_Agrandir.BMPHandle<>TFIX_BMP Then
	   If .IsInBackGround=1 Then .btn_Agrandir.BMPHandle=TFIXDIS_BMP Else .btn_Agrandir.BMPHandle=TFIX_BMP
	   .BtnIsOn(1)=0
	End If
'	If .BtnIsOn(1) and (.btn_Agrandir.BMP=ApparenceBMP(25).BMP or .btn_Agrandir.BMP=ApparenceBMP(26).BMP) Then
'	   If .IsInBackGround=1 Then .btn_Agrandir.BMP=ApparenceBMP(27).BMP Else .btn_Agrandir.BMP=ApparenceBMP(24).BMP
'	   .BtnIsOn(1)=0
'	End If

	If .BtnIsOn(2) and .btn_Reduire.BMPHandle<>TRED_BMP  Then
	   If .IsInBackGround=1 Then .btn_Reduire.BMPHandle=TREDDIS_BMP Else .btn_Reduire.BMPHandle=TRED_BMP
	   .BtnIsOn(2)=0
	End If
'	If .BtnIsOn(2) and (.btn_Reduire.BMP=ApparenceBMP(29).BMP or .btn_Reduire.BMP=ApparenceBMP(30).BMP) Then
'	   If .IsInBackGround=1 Then .btn_Reduire.BMP=ApparenceBMP(31).BMP Else .btn_Reduire.BMP=ApparenceBMP(28).BMP
'	   .BtnIsOn(2)=0
'	End If

	If .BtnIsOn(3) and .btn_Aide.BMPHandle<>TAIDE_BMP Then
	   If .IsInBackGround=1 Then .btn_Aide.BMPHandle=TAIDEDIS_BMP Else .btn_Aide.BMPHandle=TAIDE_BMP
	   .BtnIsOn(3)=0
	End If
'	If .BtnIsOn(3) and (.btn_Aide.BMP=ApparenceBMP(33).BMP or .btn_Aide.BMP=ApparenceBMP(34).BMP) Then
'	   If .IsInBackGround=1 Then .btn_Aide.BMP=ApparenceBMP(35).BMP Else .btn_Aide.BMP=ApparenceBMP(32).BMP
'	   .BtnIsOn(3)=0
'	End If
  END Event
'****************  Fin  *****************
'
'  Event Title_ICO.OnClick: End Event
  Event Title_ICO.OnMouseDown(b, x, y, shift)
	 If b=0 Then
	    If .XPPopupMenu.Visible Then
	       If .PopupL<>(.Left+.Title_ICO.Left)-1 Then
		.XPPopupMenu.Close
		.PopupL=(.Left+.Title_ICO.Left)-1: .PopupT=(.Top+.Title_ICO.Top+.Title_ICO.Height)
		.ClickHold=1: .XPPopupMenu.Show
	       End If
	    End If
	    If .XPPopupMenu.Visible=0 Then: .PopupL=(.Left+.Title_ICO.Left)-1: .PopupT=(.Top+.Title_ICO.Top+.Title_ICO.Height): .ClickHold=1: .XPPopupMenu.Show: End If
	 End If
  End Event
'  Event Title_ICO.OnMouseUp
'	If .ClickHold=1 Then .ClickHold=0
'  End Event
'
'*****  Actions du Bouton Principal *****
  Event MainBtn.OnMouseMove
	.MainBtnTimer.Interval=100: .MainBtnTimer.Enabled=1
	IF .MainBtnIs1st<1 THEN
	  IF (MouseX>2 and MouseX<(.MainBtn.Width-2)) and (MouseY>2 and MouseY<(.MainBtn.Height-2)) then
	   If .MainBtnIsOn<1 Then' Aide а rйsoudre les flickings
	      .MainBtn.BMPHandle=BOVER_BMP: .MainBtnIsOn=1': CloseWasOn=1
	      .MButOut
	   End If
	  ELSEIF .MainBtnIsOn THEN' Aide а rйsoudre les flickings
	      .MainBtn.BMPHandle=BNORM_BMP: .MainBtnIsOn=0': CloseWasOn=1
	      .MButOut
	  END IF
	ELSEIF .MainBtnIs1st THEN
	  IF (MouseX>2 and MouseX<(.MainBtn.Width-2)) and (MouseY>2 and MouseY<(.MainBtn.Height-2)) then
	   If .MainBtnIsOn<1 Then' Aide а rйsoudre les flickings
	      .MainBtn.BMPHandle=BOVER_BMP: .MainBtnIsOn=1': CloseWasOn=1
	      .MButOut
	   End If
	  ELSEIF .MainBtnIsOn THEN' Aide а rйsoudre les flickings
	     .MainBtn.BMPHandle=BSEL_BMP: .MainBtnIsOn=0': CloseWasOn=1
	     .MButOut
	  END IF
	END IF
  End Event
  Event MainBtn.OnMouseDown
	IF (MouseX>2 and MouseX<(.MainBtn.Width-2)) and (MouseY>2 and MouseY<(.MainBtn.Height-2)) then
		.MainBtn.BMPHandle=BPRES_BMP': CloseWasOn=1
	Else:	.MainBtn.BMPHandle=BNORM_BMP': CloseWasOn=1
	END IF
	.MButOut
  End Event
  Event MainBtn.OnMouseUp
	IF (MouseX>2 and MouseX<(.MainBtn.Width-2)) and (MouseY>2 and MouseY<(.MainBtn.Height-2)) then
	   .MainBtn.BMPHandle=BNORM_BMP': CloseWasOn=1
	   .MButOut
	END IF
  End Event
  Event MainBtn.OnClick: .Close: End Event
'****************  Fin  *****************
'
'*******  Actions du Bouton Fermer ******
  Event btn_Fermer.OnMouseMove
	If .BtnIsOn(0)<1 Then: .btn_Fermer.BMPHandle=TCLOSEON_BMP: .BtnIsOn(0)=1: End If
'	If .BtnIsOn(0)<1 Then: .btn_Fermer.BMP=ApparenceBMP(17).BMP: .BtnIsOn(0)=1: End If
  END Event
  Event btn_Fermer.OnMouseDown
	.btn_Fermer.BMPHandle=TCLOSEPRS_BMP
'	.btn_Fermer.BMP=ApparenceBMP(18).BMP
	.BtnIsOn(0)=1
  END Event
  Event btn_Fermer.OnMouseUp
	.btn_Fermer.BMPHandle=TCLOSEON_BMP
'	.btn_Fermer.BMP=ApparenceBMP(17).BMP
	.BtnIsOn(0)=1
  END Event
  Event btn_Fermer.OnClick: .Close: End Event
'****************  Fin  *****************
'
'*****  Actions du Bouton Toujours  *****
  Event btn_Agrandir.OnMouseMove
	If .BtnIsOn(1)<1 Then: .btn_Agrandir.BMPHandle=TFIXON_BMP: .BtnIsOn(1)=1: End If
'	If .BtnIsOn(1)<1 Then: .btn_Agrandir.BMP=ApparenceBMP(25).BMP: .BtnIsOn(1)=1: End If
  END Event
  Event btn_Agrandir.OnMouseDown
	.btn_Agrandir.BMPHandle=TFIXPRS_BMP
'	.btn_Agrandir.BMP=ApparenceBMP(26).BMP
	.BtnIsOn(1)=1
  END Event
  Event btn_Agrandir.OnMouseUp
	.btn_Agrandir.BMPHandle=TFIX_BMP
'	.btn_Agrandir.BMP=ApparenceBMP(25).BMP
	.BtnIsOn(1)=0
  END Event
  Event btn_Agrandir.OnClick' sub resize
	.ItmAgrandir_Click'.OnTop
  End Event' end sub
'****************  Fin  *****************
'
'******  Actions du Bouton Rйduire  *****
  Event btn_Reduire.OnMouseMove
	If .BtnIsOn(2)<1 Then: .btn_Reduire.BMPHandle=TREDON_BMP: .BtnIsOn(2)=1: End If
'	If .BtnIsOn(2)<1 Then: .btn_Reduire.BMP=ApparenceBMP(29).BMP: .BtnIsOn(2)=1: End If
  END Event
  Event btn_Reduire.OnMouseDown
	.btn_Reduire.BMPHandle=TREDPRS_BMP
'	.btn_Reduire.BMP=ApparenceBMP(30).BMP
	.BtnIsOn(2)=1
  END Event
  Event btn_Reduire.OnMouseUp
	.btn_Reduire.BMPHandle=TRED_BMP
'	.btn_Reduire.BMP=ApparenceBMP(29).BMP
	.BtnIsOn(2)=0
  END EVENT
  Event btn_Reduire.OnClick
'	SetWindowLong(.Handle, GWL_HWNDPARENT, HWND_DESKTOP)
'	SetWindowLong(Application.Handle, GWL_HWNDPARENT, .Handle)
'	.WindowState=wsMinimized' Application.Minimize
	If .ToujoursVisible=0 Then
	   .WindowState=wsMinimized': .Minimized=1: .Repaint
	ElseIf .ToujoursVisible Then
	   If .Croped=0 Then
	      SWAP .CropHeight,.Height: .Croped=1: .Visible=0: .Visible=1': Application.Minimize
	   Else
	      SWAP .CropHeight,.Height: .Visible=0: .Visible=1: .WindowState=wsNormal: .Croped=0
	   End If
	End If
  END EVENT
'****************  Fin  *****************
'
'*******  Actions du Bouton Aide  *******
  Event btn_Aide.OnMouseMove
	If .BtnIsOn(3)<1 Then: .btn_Aide.BMPHandle=TAIDEON_BMP: .BtnIsOn(3)=1: End If
'	If .BtnIsOn(3)<1 Then: .btn_Aide.BMP=ApparenceBMP(33).BMP: .BtnIsOn(3)=1: End If
  END Event
  Event btn_Aide.OnMouseDown
	.btn_Aide.BMPHandle=TAIDEPRS_BMP
'	.btn_Aide.BMP=ApparenceBMP(34).BMP
	.BtnIsOn(3)=1
  END Event
  Event btn_Aide.OnMouseUp
	.btn_Aide.BMPHandle=TAIDEON_BMP
'	.btn_Aide.BMP=ApparenceBMP(33).BMP
	.BtnIsOn(3)=1
  END Event
'  Event btn_Aide.OnClick: End Event
'****************  Fin  *****************

  CONSTRUCTOR
	DelTitleIcons(tiOnTop)
	btn_Aide.Visible=0
	ItmReduire.Visible=0': btn_Reduire.visible=0
	ItmAgrandir.Visible=0': btn_Agrandir.visible=0
'	AddTitleIcons(tiMinimize,tiMaximize)
	mainHandle(.Handle)
'	Center
'	WndProc=.DummyProc
'--	Doit ajouter 1px а la largeur des fenкtres et rammener de 1px les objets
'--	alignйs а droite, mais c'est cool j'ai plus besoin de ShapeMask...
	Width=400: Height=400
'	CropHeight=32' Pour la Taille Cropped (devrait кtre la taille de la Barre de titre + bordure du bas)
'	scrWIDTH=GetSystemMetrics(SM_CXFULLSCREEN)'Screen.Width+7
'	scrHEIGHT=GetSystemMetrics(SM_CYSCREEN)'Screen.Height+2
'--	Rend la fenкtre toujours visible sans API ni rien de plus que ces 2 ligne
	FormStyle=0'		Aide AlwaysOnTop а fonctionner vu que 3 = fsAlwaysOnTop
'	Parent=.Alternative' Est nйcessaire pour que Toujours Visible fonctionne
	BorderStyle=1'		1 est parfait sauf l'йtrange contour bleu.
'	DelBorderIcons(biMaximize)
	Rnd=15': RndY=15': ShapeForm(FormMask,RGB(255,0,255))' Sans FormMask
'	AutoScroll=0'				N'est pas nйcessaire pour une forme sans bordure
	Caption="Form style WinXP"'		Titre de la fenкtre & de la barre d'outils
	ICOHandle=ICO'			Icфne de la Barre de Titre & dans la barre d'outils
	Color=frmColor(0)'GetINIColor(0)'RGB(228,227,232)'&HE6DFE7
'	BtnIsOn(0)=0: BtnIsOn(1)=0: ToujoursVisible=0: BtnIsOn(2)=0: BtnIsOn(3)=0: PopupBox=0' Defaut=0 donc inutile
	MainBtnTimer.Enabled=0: MenuTimer.Enabled=0: ActiveTimer.Interval=200: ActiveTimer.Enabled=0' Quelques Timers certains devront кtre PRIVЙ
	MainBtnIs1st=1: MainBtnCentered=1
	MainBtn.Caption="Fermer"
	MainBtn.Font.Name="Tahoma"
	Title_Caption.Font.Name="Tahoma"
	TiTleDblClick=ttDefault
	icoList.Height=16: icoList.Width=16
	icoList.BkColor=clPurple
	icoList.AddICOHandle ICO
'	icoList.AddICOFile(.icoList.GetICO(1))
  END CONSTRUCTOR
  END WiTH
END TYPE

'Call ChargeSkin