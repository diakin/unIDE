$IFNDEF __QVUMETER_INC   ' IncManager: include guard
$DEFINE __QVUMETER_INC
'=======================================================
' Type Objet
' Classe QVuMeter version 1.0
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

Type QVuMeter Extends QCanvas
  Max as integer
  Min as integer
  DarkColor as long
  LightColor as long
  Thickness as short Property Set SetThickness
  Interval as short Property Set SetInterval
  Value as long Property Set SetValue

  With QVuMeter
  
  '=========================================
  ' Proprietй intervale
  '=========================================  
  Property Set SetInterval(value as short)
    .Interval=int(value)
  End property

  '=========================================
  ' Proprietй йpaisseur
  '=========================================  
  Property Set SetThickness(value as short)
    .Thickness=int(value)
  End property
    
  '=========================================
  ' Proprietй valeur vu metre
  '=========================================  
  Property Set SetValue(value as long)
    .Value=value
    .repaint
  End Property
    
  '=========================================
  ' Evenement affichage vu metre
  '=========================================  
  Event OnPaint
    dim y as short
    dim i as short
    dim NbLine as short
    dim NbLight as short
    dim range as short
    dim ValMeter as integer
  
    NbLine=int(.height/(.thickness+.interval))
    range=.Max-.Min
    ValMeter=int(.Value-.Min)
    NbLight=int((NbLine/range)*ValMeter)    
    y=.height
    for i=1 to NbLine
      if i>NbLight then
        .Fillrect(0,y,.width,y-.thickness,.DarkColor)
      else
        .Fillrect(0,y,.width,y-.thickness,.LightColor)
      end if
      y=y-(.thickness +.interval)
    next i
  End Event
  
  End With
  
  Constructor
    DarkColor=&h0
    LightColor=&hffffff
    Min=0
    Max=100
    Thickness=2
    Interval=1
    Value=0
  End Constructor
End Type
$ENDIF   ' IncManager: __QVUMETER_INC
