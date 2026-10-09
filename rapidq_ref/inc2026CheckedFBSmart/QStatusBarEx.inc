'=======================================================
' Type Objet
' Classe QStatusBar version 1.0
'=======================================================
$IFNDEF TRUE
  $DEFINE True 1
$ENDIF

$IFNDEF FALSE
  $DEFINE False 0
$ENDIF

Declare Function SetParentStatusBar Lib "user32" Alias "SetParent" (hWndChild As Long,hWndNewParent As Long) As Long

TYPE QStatusBarEx EXTENDS QSTATUSBAR
  
  SUB AddOptPanel(panel as qpanel,index as integer)
    dim i as integer
  
    panel.BEVELOUTER=False
    panel.BEVELINNER=False
    if panel.height>(QStatusBarEx.height-4) then
      panel.height=QStatusBarEx.height-4
    end if
    if index>0 then
      panel.left=4
      for i=0 to index-1
        panel.left=panel.left+QStatusBarEx.panel(i).width
      next i
    else
      panel.left=2
    end if
    if panel.width>QStatusBarEx.panel(index).width-4 then
      panel.width=QStatusBarEx.panel(index).width-4
    end if
    panel.top=((QStatusBarEx.height-panel.height)/2)+1
    SetParentStatusBar panel.handle,QStatusBarEx.handle
    if panel.visible=False then panel.visible=true
  END SUB
END TYPE
      