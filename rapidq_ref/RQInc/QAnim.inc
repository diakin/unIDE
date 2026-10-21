'=======================================================
' Type Objet
' Classe QAnim Version 1.0
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

Type QAnim Extends QImage
  PRIVATE:
    Timer as QTimer
  PUBLIC:
    Speed as long property set SetSpeed
    ImageList as QimageList
    Index as short property set SetIndex
    Width as short property set SetWidth
    Height as short property set SetHeight
    BackColor as long property set SetBackColor
    Masked as boolean property set SetMasked
    Move as boolean property set SetMove

  '=====================================
  ' proprietй start/stop animation
  '=====================================
  Property Set SetMove(move as boolean)
    if move then
      if QAnim.ImageList.Count>0 then
        QAnim.Timer.Enabled=true
        QAnim.Move=true
      end if
    else
      QAnim.Timer.Enabled=false
      QAnim.Move=false
      QAnim.Index--
    end if
  End Property  
    
  '=====================================
  ' proprietй couleur de fond
  '=====================================
  Property Set SetBackColor(backcolor as long)
    QAnim.ImageList.bkcolor=backcolor
    if QAnim.ImageList.Count>0 and QAnim.visible=true then
      QAnim.bmp=QAnim.ImageList.GetBMP(QAnim.Index)
      if QAnim.visible=false then QAnim.visible=true
      QAnim.repaint
    end if
  End Property  

  '=========================================
  ' proprietй utilisation du masque image
  '=========================================
  Property Set SetMasked(masked as boolean)
    QAnim.ImageList.masked=masked
    if QAnim.ImageList.Count>0 and QAnim.visible=true then
      QAnim.bmp=QAnim.ImageList.GetBMP(QAnim.Index)
      if QAnim.visible=false then QAnim.visible=true
      QAnim.repaint
    end if
  End Property  
    
  '=====================================
  ' proprietй largeur image
  '=====================================
  Property Set SetWidth(width as short)
    super.width=width
    QAnim.ImageList.Width=width
  End Property  
  
  '=====================================
  ' proprietй hauteur image
  '=====================================
  Property Set SetHeight(height as short)
    super.height=height
    QAnim.ImageList.Height=height
  End Property  
    
  '=====================================
  ' proprietй vitesse animation
  '=====================================
  Property Set SetSpeed(speed as long)
    QAnim.Timer.Interval=speed
  End Property  

  '=====================================
  ' proprietй index image
  '=====================================
  Property Set SetIndex(index as short)
    if QAnim.ImageList.Count>0 then
      QAnim.Index=index
      QAnim.bmp=QAnim.ImageList.GetBMP(index)
      if QAnim.visible=false then QAnim.visible=true
      QAnim.repaint
    end if
  End Property  
  
  '=====================================
  ' evenement timer
  '=====================================
  Event Timer.OnTimer
    if QAnim.Index>QAnim.ImageList.Count-1 then QAnim.Index=0
    QAnim.bmp=QAnim.ImageList.GetBMP(QAnim.Index)
    if QAnim.visible=false then QAnim.visible=true
    QAnim.repaint
    QAnim.Index++
  End Event
      
  Constructor
    Timer.Enabled=false
    Timer.Interval=200
    Visible=false
    Index=0
    Move=false
    ImageList.masked=false
  End Constructor
End Type
      