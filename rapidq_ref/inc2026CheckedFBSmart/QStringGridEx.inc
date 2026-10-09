'=======================================================
' Type Objet
' Classe QStringGridEx version 1.0
'=======================================================
Const grsList=2
Const grsEllipsis=1
Const grsNone=0

Type QStringGridEx<Size> extends QStringGrid
  Public:
    RowStyle(Size) as integer
    RowList(Size) as string
  Private:
  
  '==================================
  ' Mйthode style rangй
  '==================================
  Sub SetStyle(Col as integer,Row as integer)
    if QStringGridEx.RowStyle(Row)<>0 then
      if QStringGridEx.RowStyle(Row)=2 then
        QStringGridEx.ColumnList(Col)=QStringGridEx.RowList(Row)
        QStringGridEx.ColumnStyle(Col)=0
      elseif QStringGridEx.RowStyle(Row)=1 then
        QStringGridEx.ColumnStyle(Col)=1
      end if
    else
      QStringGridEx.ColumnStyle(Col)=2
    end if
  End Sub
  
  '==================================
  ' Evйnement sйlection cellule
  '==================================
  Event OnSelectCell(Col as integer,Row as integer,CanSelect as integer)
    QStringGridEx.SetStyle Col,Row
  End Event
  
  '==================================
  ' Evйnement dessin cellule
  '==================================
  Event OnDrawCell(Col as integer,Row as integer,State as integer,Rect as QRect)
    if Row=QStringGridEx.Row then QStringGridEx.SetStyle Col,Row
  End Event    
End Type
