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
