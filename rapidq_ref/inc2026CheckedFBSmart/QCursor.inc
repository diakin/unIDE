'=======================================================
' Type Objet
' Classe QCursor version 1.0
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

$IFNDEF __WIN32API				   'windows 32 definitions
    Declare Function LoadCursorFromFile Lib "user32" Alias "LoadCursorFromFileA" (CursorFileName as string) as long
    Declare Function SetCursorPos Lib "user32" Alias "SetCursorPos" (x As Long,y As Long) As Long
    Declare Function ShowCursor Lib "user32" Alias "ShowCursor" (bShow As Long) As Long
$ENDIF
Type QCursor Extends QObject
  Private:
    FileName as string
  Public:
    Count as integer Property Set SetCount
    Visible as  boolean Property Set SetShow
     
  '==============================
  ' proprietй nombre de curseur
  '==============================
  Property Set SetCount(count as integer)
    'Read only
  End Property

  '==============================
  ' proprietй visibilitй curseur
  '==============================
  Property Set SetShow(visible as boolean)
    This.Visible=visible
    ShowCursor(visible)
  End Property

  '==============================
  ' mйthode chargement curseur
  '==============================
  Sub LoadFromResource(Res as long)    
    if Res<RESOURCECOUNT() and Res>-1 then
      EXTRACTRESOURCE Resource(Res),This.FileName
      This.Count++
      Screen.Cursors(This.Count)=LoadCursorFromFile(This.FileName)
      if FileExists(This.FileName) then Kill This.FileName
    end if
  End Sub

  '==============================
  ' mйthode chargement curseur
  '==============================
  Sub LoadFromFile(FileName as string)    
    if FileExists(FileName) then
      This.Count++
      Screen.Cursors(This.Count)=LoadCursorFromFile(FileName)
    end if
  End Sub

  '==============================
  ' mйthode dйplacement curseur
  '==============================
  Sub Move(x as long,y as long)
    SetCursorPos(x,y)
  End Sub
  
  Constructor
    Count=0
    Visible=true
    FileName=left$(command$(0),rinstr(command$(0),"\"))+"temp.cur"
  End Constructor
End Type
