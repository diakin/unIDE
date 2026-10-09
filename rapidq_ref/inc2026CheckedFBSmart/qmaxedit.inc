'QMAXEDIT.INC by DHynes420@aol.com
'Usage:
'$INCLUDE "qmaxedit.inc"
'DIM RichEdit AS QRICHEDIT
Declare Function SendMessageA Lib "user32" Alias "SendMessageA" (hwnd As Long, wMsg As Long, wParam As Long, lParam As Long) As Long

TYPE QMAXEDIT EXTENDS QRICHEDIT

    WITH QMAXEDIT
     
        PRIVATE:

            MaxMenu      AS QPOPUPMENU
            mnuUndo      AS QMENUITEM
            mnuSep1      AS QMENUITEM
            mnuCut       AS QMENUITEM
            mnuCopy      AS QMENUITEM
            mnuPaste     AS QMENUITEM
            mnuDelete    AS QMENUITEM
            mnuSep2      AS QMENUITEM
            mnuSelectAll AS QMENUITEM
    
            EVENT MaxMenu.OnPopup
                .mnuUndo.Enabled = SendMessageA(.Handle, &HC6, 0, 0)
                .mnuCut.Enabled = .SelLength
                .mnuCopy.Enabled = .SelLength
                .mnuPaste.Enabled = LEN(ClipBoard.Text) 
                .mnuDelete.Enabled = .SelLength
                .mnuSelectAll.Enabled = (LEN(.Text) XOR LEN (.SelText)) 
            END EVENT
        
        PUBLIC:

            UsePopup AS LONG PROPERTY SET Set_Popup
                
            SUB Undo
                SendMessage(.Handle, &HC7, 0, 0)
            END SUB 
        
            SUB Cut
                .CutToClipBoard
            END SUB
        
            SUB Copy
                .CopyToClipboard
            END SUB
        
            SUB Paste
                .PasteFromClipboard
            END SUB
        
            SUB Delete
                SendMessage (.Handle, &H100, &H2E, 0)
            END SUB
        
            SUB SelectAl
                .SelectAll
            END SUB
        
            PROPERTY SET Set_Popup(Use as long)
                .MaxMenu.AutoPopup = Use
            END PROPERTY
            
            constRUCTOR
                mnuUndo.Caption = "&Undo"
                mnuUndo.OnClick = QMAXEDIT.Undo
                mnuSep1.Caption = "-"
                mnuCut.Caption = "Cu&t"
                mnuCut.OnClick = QMAXEDIT.Cut
                mnuCopy.Caption = "&Copy"
                mnuCopy.OnClick = QMAXEDIT.Copy
                mnuPaste.Caption = "&Paste"
                mnuPaste.OnClick = QMAXEDIT.Paste
                mnuDelete.Caption = "&Delete"
                mnuDelete.OnClick = QMAXEDIT.Delete
                mnuSep2.Caption = "-"
                mnuSelectAll.Caption = "Select &All"
                mnuSelectAll.OnClick = QMAXEDIT.SelectAl
                MaxMenu.AddItems QMAXEDIT.mnuUndo, QMAXEDIT.mnuSep1,_
                                QMAXEDIT.mnuCut, QMAXEDIT.mnuCopy,_
                                QMAXEDIT.mnuPaste, QMAXEDIT.mnuDelete,_
                                QMAXEDIT.mnuSep2, QMAXEDIT.mnuSelectAll
                PopupMenu = .MaxMenu
                Set_Popup = 1
            END constRUCTOR
            
    END WITH
    
END TYPE

$UNDEF QRICHEDIT
$DEFINE QRICHEDIT QMAXEDIT  