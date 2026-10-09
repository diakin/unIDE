
'=======================================================
' Type Objet
' Classe QDrawFocus Version 1.3
' modified by JohnK 8/2007
'=======================================================
$IFNDEF __QDRAWFOCUS_INC
  $DEFINE __QDRAWFOCUS_INC


$IFNDEF TRUE
  $DEFINE True 1
$ENDIF

$IFNDEF FALSE
  $DEFINE False 0
$ENDIF

$IFNDEF boolean
  $DEFINE boolean integer
$ENDIF

$IFNDEF __WIN32API				   'windows 32 definitions
   $IFNDEF __RQ2WIN32API

    Type RECT
        Left As Long
        Top As Long
        Right As Long
        Bottom As Long
    End Type
   DECLARE FUNCTION GetDC LIB "user32.dll" ALIAS "GetDC"(ByVal hwnd AS LONG) AS LONG
   $ENDIF
  'returns !0 on succeed
  DECLARE FUNCTION DrawFocusRect Lib "user32.dll" Alias "DrawFocusRect" (hdc As Long, ByRef lpRect As RECT) As Long
$ENDIF


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
    StartX as short
    StartY as short     'need to store starts for backwards selection
    Border as short
    Frame1 as boolean
    Frame2 as boolean
    Frame3 as boolean
    offsetX as short
    offsetY as short
    rect as RECT            'crashes with QRect , winXP

  
  WITH QDrawFocus

  PUBLIC:
  '==========================================
  ' Proprieté left en lecture seule
  '==========================================
  PROPERTY SET SetLeft(value as short)
  END PROPERTY

  '==========================================
  ' Proprieté top en lecture seule
  '==========================================
  PROPERTY SET SetTop(value as short)
  END PROPERTY

  '==========================================
  ' Proprieté width en lecture seule
  '==========================================
  PROPERTY SET SetWidth(value as short)
  END PROPERTY

  '==========================================
  ' Proprieté height en lecture seule
  '==========================================
  PROPERTY SET SetHeight(value as short)
  END PROPERTY

  '==========================================
  ' Proprieté move en lecture seule
  '==========================================
  PROPERTY SET SetMove(value as boolean)
  END PROPERTY

  '==========================================
  ' Proprieté inside en lecture seule
  '==========================================
  PROPERTY SET SetInside(value as boolean)
  END PROPERTY

  '==========================================
  ' Méthode:supprime le focus
  ' Parametres:
  ' handle:(handle DC)
  '==========================================
  Sub Remove(handle as long)
    if .Visible then
    ' remove focus by redrawing old one by XOR op
      DrawFocusRect(handle, QDrawFocus.Rect)
      .Visible=false
    end if
    if .ShowCursor then Screen.Cursor=0
  End Sub

  '============================================
  ' Méthode:debut du focus
  ' Parametres:
  ' handle:(handle DC)
  ' x,y:(position x,y)
  '============================================
  Sub Start(handle as long,x as integer,y as integer)
    ' click on focus
    .Inside=false
    .Move=false

    if x>.left and x<.left+.width and y>.top and y<.top+.height and .Visible=true then
      .Inside = true
    else
      .Remove(handle)     'redrawing removes old focus (if visible)
      .Inside = false
      .Move = false
      .left = x     :.StartX = x
      .top = y      :.StartY = y
      .Rect.left = x
      .Rect.top = y
      .Rect.Right = x           'these lines added; set to no size
      .Rect.Bottom = y
      .width = 0
      .height = 0
      if .ShowCursor then Screen.Cursor = -3
    end if

    if .Inside and .Visible then
      .Frame1=false
      .Frame2=false
      .Frame3=false
      .offsetX=x-.left
      .offsetY=y-.top
     'set up the correct cursor for which side we are on
      if x>.left+.width-.Border and x<.left+.width and y>.top+.height-.Border and y<.top+.height and .NoResize=false then
        .Frame3=true
        if .ShowCursor then Screen.Cursor=-8
      elseif y>.top+.height-.Border and y<.top+.height and .NoResize=false then
        .Frame2=true
        if .ShowCursor then Screen.Cursor=-7
      elseif x>.left+.width-.Border and x<.left+.width and .NoResize=false then
        .Frame1=true
        if .ShowCursor then Screen.Cursor=-9
      else
        if .ShowCursor then Screen.Cursor=-21
      end if
    end if
  End Sub

  '==========================================
  ' Méthode:dessine le focus
  ' Parametres:
  ' handle:(handle DC)
  ' x,y:(position x,y)
  ' flagDraw:(dessin focus si true)
  '==========================================
  Sub Draw(handle as long,x as integer,y as integer,flagDraw as boolean)
    ' move focus
    if flagDraw then

        if .Visible then        'set rect and draw it
            DrawFocusRect(handle,QDrawFocus.Rect)
        end if

        if .Inside and .Visible then  'move selection
            if .Frame1 and .NoResize=false then
              .Rect.right=x
              .Rect.bottom=.top+.height
              .width=x-.left
            end if

            if .Frame2 and .NoResize=false then
              .Rect.bottom=y
              .Rect.right=.left+.width
              .height=y-.top
            end if

            if .Frame3 and .NoResize=false then
              .Rect.right=x
              .Rect.bottom=y
              .width=x-.left
              .height=y-.top
            end if

            if .Frame1=false and .Frame2=false and .Frame3=false then
              .left=x-.offsetX
              .top=y-.offsetY
              .Rect.left=.left
              .Rect.top=.top
              .Rect.right=x-.offsetX+.width
              .Rect.bottom=y-.offsetY+.height
            end if

            DrawFocusRect(handle,QDrawFocus.Rect)
            .Move=true
            .Visible=true

        else
            'draw a new selection
            IF x < .StartX THEN     'moving leftward
                .left = x
                .Rect.left = x
                .Rect.right = .StartX
            ELSE
                .left = .StartX
                .Rect.left = .StartX
                .Rect.right = x
            END IF
            .width = ABS(x-.StartX)

            IF y < .Top THEN        'moving upward
                .Top = y
                .Rect.Top = y
                .Rect.Bottom = .StartY
            ELSE
                .Top = .StartY
                .Rect.Top = .StartY
                .Rect.bottom = y
            END IF
            .height = ABS(y-.StartY)

            DrawFocusRect(handle, QDrawFocus.Rect)
            .Visible = true
        end if              'end move selection

    else                    'no drawing flag
      ' show cursor focus
      if .Visible then
            if x>.left+.width-.Border and x<.left+.width and y>.top+.height-.Border and y<.top+.height and .NoResize=false then
              .Inside=true
              if .ShowCursor then Screen.Cursor=-8
            elseif x>.left and x<.left+.width and y>.top+.height-.Border and y<.top+.height and .NoResize=false then
              .Inside=true
              if .ShowCursor then Screen.Cursor=-7
            elseif x>.left+.width-.Border and x<.left+.width and y>.top and y<.top+.height and .NoResize=false then
              .Inside=true
              if .ShowCursor then Screen.Cursor=-9
            elseif x>.left and x<.left+.width-.Border and y>.top and y<.top+.height-.Border then
              .Inside=true
              if .ShowCursor then Screen.Cursor=-21
            else
              .Inside=false
              if .ShowCursor then Screen.Cursor=0
            end if
      end if            'end visible

    end if              'end drawing flag

  End Sub

  '==========================================
  ' Méthode:arrete le dessin du focus
  ' Parametres:
  ' handle:(handle DC)
  ' flagRemove:(suppression focus)
  '==========================================
  Sub Stop(handle as long,flagRemove as boolean)
    if .Move and flagRemove then
      .Remove(handle)
    end if
    if .ShowCursor then Screen.Cursor=0
  End Sub


END WITH
  CONSTRUCTOR
    Border=10
    ShowCursor=true
    Width= 0
    Height = 0
    Rect.Right = 0
    Rect.Bottom = 0

  END CONSTRUCTOR
END TYPE

$ENDIF





