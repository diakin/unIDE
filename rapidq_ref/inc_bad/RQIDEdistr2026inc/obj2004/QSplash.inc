'=======================================================
' Type Objet
' Classe QSplash version 1.2
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

Type QSplash Extends QObject
  PRIVATE:
    form as QForm
    label1 as QLABEL
  PUBLIC:
    Image as Qimage
    Text as string
    TextCenter as boolean
    TextTop as Short
    TextLeft as Short
    TextFont as QFont
    TextTransparent as boolean
  
  '=======================
  ' Mйthode Show 
  '=======================
  Sub Show(Time as short)
    With QSplash
      .form.Center
      .form.ClientWidth=.Image.Width 
      if .text<>"" then
        .label1.Transparent=false
        .label1.autosize=true
        .label1.font=.TextFont
        .label1.caption=.text
        .label1.parent=.form
        if .textCenter then
          .label1.left=(.form.ClientWidth-.label1.Width)/2
        else
          .label1.left=.textLeft
        end if
        if .TextTransparent then
          .form.ClientHeight=.Image.Height 
          .label1.top=.TextTop
          .label1.Transparent=true
        else
          .label1.top=.Image.Height+10
          .form.ClientHeight=.label1.top+.label1.height+10
        end if
      else
        .form.ClientHeight=.Image.Height 
      end if
      .form.HideTitleBar
      .form.Show 
      .form.Repaint 
      SLEEP Time 
      .form.Close 
    End With
  End Sub
  
  Constructor
    form.BorderStyle=3 
    form.Center 
    Image.parent=QSplash.form
    Image.autosize=true
    Image.left=0
    Image.top=0
    Text=""
    TextLeft=5
    TextCenter=False
  End Constructor
End Type
