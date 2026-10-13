$IFNDEF __QREDEXTEST2_INC   ' IncManager: include guard
$DEFINE __QREDEXTEST2_INC
' =======================================
Type QRedEx Extends QRichEdit
MaxMenu      AS QPOPUPMENU
mnuUndo      AS QMENUITEM

CONSTRUCTOR
	mnuUndo.Caption = "&Undo"
	MaxMenu.AddItems QRedEx.mnuUndo
	PopupMenu = QRedEx.MaxMenu
	MaxMenu.AutoPopup=1
END CONSTRUCTOR

End Type
' =======================================
'
$ENDIF   ' IncManager: __QREDEXTEST2_INC
