'=======================================================
' Type Objet
' Classe QSkinBtn version 1.0
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

Type QSkinBtn extends qimage
  Private:
    show as qcanvas
    Align as integer
    Stretch as boolean
    Width as short
    Height as short
  Public:
    btUp as qbitmap
    btDown as qbitmap
    btEnable as qbitmap
    mode as short property set SetMode
    down as boolean property set SetDown
    enabled as boolean property set SetEnabled
  
  '=========================================
  ' Proprietй enable
  '=========================================  
  Property Set SetEnabled(value as boolean)
    QSkinBtn.bmp=QSkinBtn.btEnable.bmp
    QSkinBtn.repaint
    QSkinBtn.Enabled=value
    Super.Enabled=value
  End Property
    
  '=========================================
  ' Proprietй enfoncement bouton
  '=========================================  
  Property Set SetDown(value as boolean)
    if super.Enabled then
      QSkinBtn.Down=value
      if QSkinBtn.Down then
        QSkinBtn.bmp=QSkinBtn.btDown.bmp
      else
        QSkinBtn.bmp=QSkinBtn.btUp.bmp
      end if
      QSkinBtn.repaint
    end if
  End Property
  
  '=========================================
  ' Proprietй mode de fonctionnement
  '=========================================  
  Property Set SetMode(value as short)
    QSkinBtn.mode=value
  End Property
  
    
  '=========================================
  ' Evenement enfoncement bouton
  '=========================================  
  Event OnMouseDown
      QSkinBtn.bmp=QSkinBtn.btDown.bmp
      QSkinBtn.repaint
  End Event

  '=========================================
  ' Evenement relachement bouton
  '=========================================  
  Event OnMouseUp
    if QSkinBtn.mode=1 or QSkinBtn.mode=2 then
      if QSkinBtn.Down and QSkinBtn.mode=2 then
        QSkinBtn.bmp=QSkinBtn.btUp.bmp
        QSkinBtn.repaint
        QSkinBtn.Down=false
      else
        QSkinBtn.Down=true
      end if
    else
      QSkinBtn.bmp=QSkinBtn.btUp.bmp
      QSkinBtn.repaint
      QSkinBtn.Down=false
    end if
  End Event
  
  '=========================================
  ' Evenement affichage bouton
  '=========================================  
  Event Show.OnPaint
    if super.Enabled then
      if QSkinBtn.Down then
        QSkinBtn.bmp=QSkinBtn.btDown.bmp
      else
        QSkinBtn.bmp=QSkinBtn.btUp.bmp
      end if
    else
      QSkinBtn.bmp=QSkinBtn.btEnable.bmp
    end if
    QSkinBtn.Show.visible=false
  End Event
    
  Constructor
    autosize=true
    show.parent=qform
    Down=false
    mode=0
    Enabled=true
  End Constructor  
end type
