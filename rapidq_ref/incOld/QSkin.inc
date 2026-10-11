'=======================================================
' Type Objet
' Classe QSkin version 1.2
'=======================================================
$IFNDEF TRUE
  $DEFINE True 1
$ENDIF

$IFNDEF FALSE
  $DEFINE False 0
$ENDIF

Declare Function SkinReleaseCapture Lib "user32" Alias "ReleaseCapture" () As Long
Declare Function SkinSetLong LIB "User32" ALIAS "SetWindowLongA" (hwnd as Long,nIndex as Long,dwNewLong as Long) as Long
Const SKIN_SYSCOMMAND=&h112
Const SKIN_MOVE=&hF012
Const SKIN_HWNDPARENT=-8
Const SKIN_HWNDDESKTOP=0
 
Type QSkin extends QForm
  Skin as Qimage
  OffsWidth as short
  OffsHeight as short
    
  '==============================
  ' evenement resize
  '==============================    
  Event OnResize
    QSkin.Width=QSkin.Skin.Width+QSkin.OffsWidth
    QSkin.Height=QSkin.Skin.Height+QSkin.OffsHeight
    QSkin.hidetitlebar
  End Event
  
  '==============================
  ' evenement onmousedown
  '==============================    
  Event Skin.onmousedown(Button as short,X as short,Y as short,Shift as short)
   SkinReleaseCapture
   SendMessage(QSkin.handle,SKIN_SYSCOMMAND,SKIN_MOVE,0)
  End Event
  
  '=================================================
  ' mйthode rйduction applcaton dans barre de tache
  '=================================================
  Sub SetDeskBar
    SkinSetLong(QSkin.handle,SKIN_HWNDPARENT,SKIN_HWNDDESKTOP)
    SkinSetLong(application.handle,SKIN_HWNDPARENT,QSkin.handle)
  End Sub

  '=================================================
  ' mйthode redimensionnement application
  '=================================================
  Sub Resize
    QSkin.Width=QSkin.Skin.Width+QSkin.OffsWidth
    QSkin.Height=QSkin.Skin.Height+QSkin.OffsHeight
    QSkin.hidetitlebar
  End Sub
      
  constructor
    borderStyle=1
    DelBorderIcons 2
    Skin.parent=QSkin
    Skin.autosize=true
    Skin.left=0
    Skin.top=0
    OffsWidth=0
    OffsHeight=0
  end constructor  
End Type
