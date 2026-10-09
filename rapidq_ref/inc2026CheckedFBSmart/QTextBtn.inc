$TYPECHECK ON
'=======================================================
' Type Objet
' Classe QTextBtn version 1.0
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

Type QTextBtn extends QLabel
  DownColor as Long
  UpColor as Long property set SetUpColor
  mode as short property set SetMode
  down as boolean property set SetDown
  enabled as boolean property set SetEnabled

  '=========================================
  ' Proprietй couleur bouton relachй
  '=========================================  
  Property Set SetUpColor(value as long)
    QTextBtn.UpColor=value
    QTextBtn.font.color=QTextBtn.UpColor
  End Property
      
  '=========================================
  ' Proprietй enfoncement bouton
  '=========================================  
  Property Set SetDown(value as boolean)
    if super.Enabled then
      QTextBtn.Down=value
      if QTextBtn.Down then
        QTextBtn.font.color=QTextBtn.DownColor
      else
       QTextBtn.font.color=QTextBtn.UpColor
      end if
    end if
  End Property
  
  '=========================================
  ' Proprietй mode de fonctionnement
  '=========================================  
  Property Set SetMode(value as short)
    QTextBtn.mode=value
  End Property
  
    
  '=========================================
  ' Evenement enfoncement bouton
  '=========================================  
  Event OnMouseDown
    QTextBtn.font.color=QTextBtn.DownColor
  End Event

  '=========================================
  ' Evenement relachement bouton
  '=========================================  
  Event OnMouseUp
    if QTextBtn.mode=1 or QTextBtn.mode=2 then
      if QTextBtn.Down and QTextBtn.mode=2 then
      QTextBtn.font.color=QTextBtn.UpColor
        QTextBtn.Down=false
      else
        QTextBtn.Down=true
      end if
    else
      QTextBtn.font.color=QTextBtn.UpColor
      QTextBtn.Down=false
    end if
  End Event
      
  Constructor
    Transparent=true
    autosize=true
    Down=false
    mode=0
    cursor=-21
    UpColor=&h0
    DownColor=&h0
  End Constructor  
end type
