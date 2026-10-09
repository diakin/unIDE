'=======================================================
' Type Objet
' Classe QLine version 1.0
'=======================================================
Declare Function DrawLine Lib "user32" Alias "DrawEdge" (hdc As Long,qrc As QRECT,edge As Long,grfFlags As Long) As Long
        
Type QLine extends QCanvas    
  PRIVATE:
    r as QRECT

    '==============================
    ' Méthode affichage ligne
    '==============================
    Sub draw
      if (QLine.Align=0 and QLine.Height>QLine.width) or (QLine.Align=3) or (QLine.Align=4) then
        QLine.r.Left=0 
        QLine.r.Top=-1
        QLine.r.Right=2 
        QLine.r.Bottom=QLine.Height
        QLine.width=2
      elseif (QLine.Align=0 and QLine.width>QLine.Height) or (QLine.Align=1) or (QLine.Align=2) then
        QLine.r.Left=-1 
        QLine.r.Top=0
        QLine.r.Right=QLine.width 
        QLine.r.Bottom=2
        QLine.Height=2
      end if
      DrawLine(QLine.handle,QLine.r,&h6,&h3)
    end sub

    '==============================
    ' Evénement OnPaint
    '==============================
    Event OnPaint
      QLine.draw
    End Event
    
    Constructor
      width=2
      Height=2
    end Constructor        
end type    
      