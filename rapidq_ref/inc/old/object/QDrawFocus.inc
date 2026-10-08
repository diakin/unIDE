'=======================================================
' Type Objet
' Classe QDrawFocus Version 1.2
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

Declare Function DrawFocusRect Lib "user32" Alias "DrawFocusRect" (hdc As Long,lpRect As QRECT) As Long

TYPE QDrawFocus EXTENDS QOBJECT
  '===================================================
  ' champs objet
  '===================================================
  PUBLIC:
    Left as short PROPERTY SET SetLeft
    Top as short PROPERTY SET SetTop
    Width as short PROPERTY SET SetWidth
    Height as short PROPERTY SET SetHeight
    Move as boolean PROPERTY SET SetMove
    Visible as boolean
    Inside as boolean PROPERTY SET SetInside
    NoResize as boolean
    ShowCursor as boolean
  PRIVATE:
    Border as short
    Frame1 as boolean
    Frame2 as boolean
    Frame3 as boolean
    offsetX as short
    offsetY as short
    rect as QRECT
    
  PUBLIC:
  '==========================================
  ' Proprietй left en lecture seule
  '==========================================
  PROPERTY SET SetLeft(value as short)
  END PROPERTY

  '==========================================
  ' Proprietй top en lecture seule
  '==========================================
  PROPERTY SET SetTop(value as short)
  END PROPERTY

  '==========================================
  ' Proprietй width en lecture seule
  '==========================================
  PROPERTY SET SetWidth(value as short)
  END PROPERTY

  '==========================================
  ' Proprietй height en lecture seule
  '==========================================
  PROPERTY SET SetHeight(value as short)
  END PROPERTY

  '==========================================
  ' Proprietй move en lecture seule
  '==========================================
  PROPERTY SET SetMove(value as boolean)
  END PROPERTY

  '==========================================
  ' Proprietй inside en lecture seule
  '==========================================
  PROPERTY SET SetInside(value as boolean)
  END PROPERTY

  '==========================================
  ' Mйthode:supprime le focus
  ' Parametres:
  ' handle:(handle DC)
  '==========================================
  Sub Remove(handle as long)
    ' remove focus
    if QDrawFocus.Visible then
      QDrawFocus.rect.right=QDrawFocus.left+QDrawFocus.width
      QDrawFocus.rect.bottom=QDrawFocus.top+QDrawFocus.height
      QDrawFocus.rect.left=QDrawFocus.left
      QDrawFocus.rect.top=QDrawFocus.top
      DrawFocusRect(handle,QDrawFocus.rect)
      QDrawFocus.Visible=false
    end if
    if QDrawFocus.ShowCursor then Screen.Cursor=0
  End Sub

  '============================================
  ' Mйthode:debut du focus
  ' Parametres:
  ' handle:(handle DC)
  ' x,y:(position x,y)
  '============================================
  Sub Start(handle as long,x as integer,y as integer)
    ' click on focus
    QDrawFocus.Inside=false
    QDrawFocus.Move=false
    if x>QDrawFocus.left and x<QDrawFocus.left+QDrawFocus.width and y>QDrawFocus.top and y<QDrawFocus.top+QDrawFocus.height and QDrawFocus.Visible=true then
      QDrawFocus.Inside=true
    else
      QDrawFocus.Remove(handle)
      QDrawFocus.Inside=false
      QDrawFocus.Move=false
      QDrawFocus.left=x
      QDrawFocus.top=y
      QDrawFocus.rect.left=x
      QDrawFocus.rect.top=y
      if QDrawFocus.ShowCursor then Screen.Cursor=-3
    end if
    if QDrawFocus.Inside and QDrawFocus.Visible then
      QDrawFocus.Frame1=false
      QDrawFocus.Frame2=false
      QDrawFocus.Frame3=false
      QDrawFocus.offsetX=x-QDrawFocus.left
      QDrawFocus.offsetY=y-QDrawFocus.top
      if x>QDrawFocus.left+QDrawFocus.width-QDrawFocus.Border and x<QDrawFocus.left+QDrawFocus.width and y>QDrawFocus.top+QDrawFocus.height-QDrawFocus.Border and y<QDrawFocus.top+QDrawFocus.height and QDrawFocus.NoResize=false then
        QDrawFocus.Frame3=true
        if QDrawFocus.ShowCursor then Screen.Cursor=-8
      elseif y>QDrawFocus.top+QDrawFocus.height-QDrawFocus.Border and y<QDrawFocus.top+QDrawFocus.height and QDrawFocus.NoResize=false then
        QDrawFocus.Frame2=true
        if QDrawFocus.ShowCursor then Screen.Cursor=-7
      elseif x>QDrawFocus.left+QDrawFocus.width-QDrawFocus.Border and x<QDrawFocus.left+QDrawFocus.width and QDrawFocus.NoResize=false then
        QDrawFocus.Frame1=true
        if QDrawFocus.ShowCursor then Screen.Cursor=-9
      else
        if QDrawFocus.ShowCursor then Screen.Cursor=-21
      end if
    end if
  End Sub

  '==========================================
  ' Mйthode:dessine le focus
  ' Parametres:
  ' handle:(handle DC)
  ' x,y:(position x,y)
  ' flagDraw:(dessin focus si true)
  '==========================================
  Sub Draw(handle as long,x as integer,y as integer,flagDraw as boolean)
    ' move focus
    if flagDraw then
      if QDrawFocus.Visible then
        QDrawFocus.rect.right=QDrawFocus.left+QDrawFocus.width
        QDrawFocus.rect.bottom=QDrawFocus.top+QDrawFocus.height
        QDrawFocus.rect.left=QDrawFocus.left
        QDrawFocus.rect.top=QDrawFocus.top
        DrawFocusRect(handle,QDrawFocus.rect)
      end if
      if QDrawFocus.Inside and QDrawFocus.Visible then
        if QDrawFocus.Frame1 and QDrawFocus.NoResize=false then
          QDrawFocus.rect.right=x
          QDrawFocus.rect.bottom=QDrawFocus.top+QDrawFocus.height
          QDrawFocus.width=x-QDrawFocus.left
        end if
        if QDrawFocus.Frame2 and QDrawFocus.NoResize=false then
          QDrawFocus.rect.bottom=y
          QDrawFocus.rect.right=QDrawFocus.left+QDrawFocus.width
          QDrawFocus.height=y-QDrawFocus.top
        end if
        if QDrawFocus.Frame3 and QDrawFocus.NoResize=false then
          QDrawFocus.rect.right=x
          QDrawFocus.rect.bottom=y
          QDrawFocus.width=x-QDrawFocus.left
          QDrawFocus.height=y-QDrawFocus.top
        end if
        if QDrawFocus.Frame1=false and QDrawFocus.Frame2=false and QDrawFocus.Frame3=false then
          QDrawFocus.left=x-QDrawFocus.offsetX
          QDrawFocus.top=y-QDrawFocus.offsetY
          QDrawFocus.rect.left=QDrawFocus.left
          QDrawFocus.rect.top=QDrawFocus.top
          QDrawFocus.rect.right=x-QDrawFocus.offsetX+QDrawFocus.width
          QDrawFocus.rect.bottom=y-QDrawFocus.offsetY+QDrawFocus.height
        end if
        DrawFocusRect(handle,QDrawFocus.rect)
        QDrawFocus.Move=true
        QDrawFocus.Visible=true
      else
        QDrawFocus.width=x-QDrawFocus.left
        QDrawFocus.height=y-QDrawFocus.top
        QDrawFocus.rect.right=x
        QDrawFocus.rect.bottom=y
        DrawFocusRect(handle,QDrawFocus.rect)
        QDrawFocus.Visible=true
      end if
    else
      ' show cursor focus
      if QDrawFocus.Visible then
        if x>QDrawFocus.left+QDrawFocus.width-QDrawFocus.Border and x<QDrawFocus.left+QDrawFocus.width and y>QDrawFocus.top+QDrawFocus.height-QDrawFocus.Border and y<QDrawFocus.top+QDrawFocus.height and QDrawFocus.NoResize=false then
          QDrawFocus.Inside=true
          if QDrawFocus.ShowCursor then Screen.Cursor=-8
        elseif x>QDrawFocus.left and x<QDrawFocus.left+QDrawFocus.width and y>QDrawFocus.top+QDrawFocus.height-QDrawFocus.Border and y<QDrawFocus.top+QDrawFocus.height and QDrawFocus.NoResize=false then
          QDrawFocus.Inside=true
          if QDrawFocus.ShowCursor then Screen.Cursor=-7
        elseif x>QDrawFocus.left+QDrawFocus.width-QDrawFocus.Border and x<QDrawFocus.left+QDrawFocus.width and y>QDrawFocus.top and y<QDrawFocus.top+QDrawFocus.height and QDrawFocus.NoResize=false then
          QDrawFocus.Inside=true
          if QDrawFocus.ShowCursor then Screen.Cursor=-9
        elseif x>QDrawFocus.left and x<QDrawFocus.left+QDrawFocus.width-QDrawFocus.Border and y>QDrawFocus.top and y<QDrawFocus.top+QDrawFocus.height-QDrawFocus.Border then
          QDrawFocus.Inside=true
          if QDrawFocus.ShowCursor then Screen.Cursor=-21
        else
          QDrawFocus.Inside=false
          if QDrawFocus.ShowCursor then Screen.Cursor=0
        end if
      end if
    end if
  End Sub

  '==========================================
  ' Mйthode:arrete le dessin du focus
  ' Parametres:
  ' handle:(handle DC)
  ' flagRemove:(suppression focus)
  '==========================================
  Sub Stop(handle as long,flagRemove as boolean)
    ' click off focus
    if QDrawFocus.Move and flagRemove then
      QDrawFocus.Remove(handle)
    end if
    if QDrawFocus.ShowCursor then Screen.Cursor=0
  End Sub

  CONSTRUCTOR
    Border=10
    ShowCursor=true
  END CONSTRUCTOR
END TYPE
