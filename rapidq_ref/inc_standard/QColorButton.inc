$IFNDEF __QCOLORBUTTON_INC   ' IncManager: include guard
$DEFINE __QCOLORBUTTON_INC
'QColorButton
'By Achilles B. Mina
'Uploaded 7/5/03

TYPE QCOLORBUTTON EXTENDS QPANEL
  SndFreq AS INTEGER
  SndDur AS SINGLE
  CONSTRUCTOR
    Height = 26
    Width = 26
    BevelInner = 2
    Color = &HEEEEEE
    Cursor = -21
  END CONSTRUCTOR
  EVENT OnMouseDown 
    QCOLORBUTTON.BorderStyle = 1
    QCOLORBUTTON.Caption = " " + QCOLORBUTTON.Caption
    'IF QCOLORBUTTON.SndFreq = 0 AND QCOLORBUTTON.SndDur = 0 THEN ' XP compatibles ;-('
''      SOUND(5000,.5)
    'ELSE
''      SOUND(QCOLORBUTTON.SndFreq,QCOLORBUTTON.SndDur)
    'END IF
  END EVENT
  EVENT OnMouseUp
    QCOLORBUTTON.BorderStyle = 0
    QCOLORBUTTON.Caption = QCOLORBUTTON.Caption - " "
  END EVENT
END TYPE

$ENDIF   ' IncManager: __QCOLORBUTTON_INC
