$IFNDEF __QFLASHLABEL_INC   ' IncManager: include guard
$DEFINE __QFLASHLABEL_INC
'=======================================================
' Type Objet
' Classe QFlashLabel version 1.0
'=======================================================
$IFNDEF TRUE
  $DEFINE True 1
$ENDIF

$IFNDEF FALSE
  $DEFINE False 0
$ENDIF

$IFNDEF boolean
  $DEFINE boolean integer
$ENDIF

Type QFlashLabel extends QLabel
  Private:
    Timer as QTimer
  Public:
    LightColor as Long
    DarkColor as Long property set SetDarkColor
    Flash as boolean property set SetFlash
    State as short property set SetState
    Speed as long property set SetSpeed

  '=========================================
  ' Proprietй couleur texte label
  '=========================================  
  Property Set SetDarkColor(color as long)
    QFlashLabel.DarkColor=color
    QFlashLabel.font.color=QFlashLabel.DarkColor
  End Property
      
  '=========================================
  ' Proprietй йtat couleur texte label
  '=========================================  
  Property Set SetState(state as short)
    QFlashLabel.State=state
    if QFlashLabel.State=1 then
      QFlashLabel.font.color=QFlashLabel.LightColor
    else
      QFlashLabel.font.color=QFlashLabel.DarkColor
    end if
  End Property

  '=========================================
  ' Proprietй clignotement texte label
  '=========================================  
  Property Set SetFlash(flash as boolean)
    QFlashLabel.Flash=flash
    if QFlashLabel.Flash then
      QFlashLabel.Timer.Enabled=true
    else
      QFlashLabel.Timer.Enabled=false
      QFlashLabel.State=0
      QFlashLabel.font.color=QFlashLabel.DarkColor
    end if
  End Property
  
  '=====================================
  ' proprietй vitesse clignotement
  '=====================================
  Property Set SetSpeed(speed as long)
    QFlashLabel.Timer.Interval=speed
    QFlashLabel.Speed=speed
  End Property  
  
  '=====================================
  ' evenement timer
  '=====================================
  Event Timer.OnTimer
    if QFlashLabel.State then
      QFlashLabel.State=false
      QFlashLabel.font.color=QFlashLabel.DarkColor
    else
      QFlashLabel.State=true
      QFlashLabel.font.color=QFlashLabel.LightColor
    end if
  End Event
          
  Constructor
    Timer.Enabled=false
    Timer.Interval=1000
    Speed=1000
    Transparent=true
    autosize=true
    DarkColor=&h0
    LightColor=&h0
    State=0
  End Constructor  
end type
$ENDIF   ' IncManager: __QFLASHLABEL_INC
