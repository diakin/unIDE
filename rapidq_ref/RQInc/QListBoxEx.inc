'=======================================================
' Type Objet
' Classe QListBoxEx version 1.0
'=======================================================
$IFNDEF TRUE
  $DEFINE True 1
$ENDIF

$IFNDEF FALSE
  $DEFINE False 0
$ENDIF

Declare Sub OnEnter_eventTemplate

Type QListBoxEx Extends QListBox
  Private:
    HideMenu as QPopupMenu
    EnterKey as QMenuItem
  Public:
    OnEnter as EVENT(OnEnter_eventTemplate)

  '=================================================
  ' Evenement entrer 
  '=================================================
  Event EnterKey.OnClick
    if This.OnEnter<>0 then CALLFUNC this.OnEnter
  End Event
          
  Constructor
    EnterKey.ShortCut="Enter"
    EnterKey.Visible=False
    HideMenu.AddItems(This.EnterKey)
    PopupMenu=This.HideMenu
  End Constructor
End Type
