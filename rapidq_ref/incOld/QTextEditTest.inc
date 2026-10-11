Declare Function SendMessageA Lib "user32" Alias "SendMessageA"_
 (hwnd As Long, wMsg As Long, wParam As Long, lParam As Long) As Long

TYPE QTEXTEDIT EXTENDS QRICHEDIT
PRIVATE:
MaxMenu AS QPOPUPMENU
mnuUndo AS QMENUITEM
mnuSep1 AS QMENUITEM
mnuCut  AS QMENUITEM
mnuCopy AS QMENUITEM
mnuPaste AS QMENUITEM
mnuSep2 AS QMENUITEM
mnuSelectAll AS QMENUITEM

EVENT MaxMenu.OnPopup

END EVENT

PUBLIC:
UsePopup AS long PROPERTY SET Set_Popup

PROPERTY SET Set_Popup(Use as long)
QTEXTEDIT.MaxMenu.AutoPopup=Use
END PROPERTY

SUB Undo
SendMessage(QTEXTEDIT.Handle,&HC7,0,0)
END SUB 

SUB Cut
QTEXTEDIT.CutToClipBoard
END SUB

SUB Copy
QTEXTEDIT.CopyToClipboard
END SUB

SUB Paste
QTEXTEDIT.PasteFromClipboard
END SUB

SUB SelectAl
QTEXTEDIT.SelectAll
END SUB


constRUCTOR
mnuUndo.Caption="&Undo"
mnuUndo.OnClick=QTEXTEDIT.Undo
mnuUndo.ShortCut="CTRL+Z"
mnuSep1.Caption="-"
mnuCut.Caption="Cu&t"
mnuCut.OnClick=QTEXTEDIT.Cut
mnuCut.ShortCut="CTRL+X"
mnuCopy.Caption="&Copy"
mnuCopy.OnClick=QTEXTEDIT.Copy
mnuCopy.ShortCut="CTRL+C"
mnuPaste.Caption="&Paste"
mnuPaste.OnClick=QTEXTEDIT.Paste
mnuPaste.ShortCut="CTRL+V"
mnuSep2.Caption="-"
mnuSelectAll.Caption="Select &All"
mnuSelectAll.OnClick=QTEXTEDIT.SelectAl
mnuSelectAll.ShortCut="CTRL+A"
MaxMenu.AddItems QTEXTEDIT.mnuUndo,QTEXTEDIT.mnuSep1,QTEXTEDIT.mnuCut,QTEXTEDIT.mnuCopy,QTEXTEDIT.mnuPaste,QTEXTEDIT.mnuSep2,QTEXTEDIT.mnuSelectAll
PopupMenu=QTEXTEDIT.MaxMenu
UsePopup=1
END constRUCTOR
END TYPE

$UNDEF QRICHEDIT
$DEFINE QRICHEDIT QTEXTEDIT











