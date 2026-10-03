'Just the other day I whipped up a little QRICHEDIT extension to pop 
'up a menu exactly like the default windows context menu. Here it is, 
'enjoy:


'result= SendMessageAPI (SrcEdit.handle,EM_EXLIMITTEXT,0,65535*32)
'LChar=SendMessageAPI (SrcEdit.handle,EM_LINEINDEX,SrcEdit.LineCount-2,0)
'result= SendMessageAPI (hWnd,EM_GETRECT,0,M.Pointer)
'lchar=SendMessageAPI (hWnd,EM_CHARFROMPOS,0,M.Pointer)
'line_number= SendMessageAPI (hWnd,EM_LINEFROMCHAR,lchar,0 )
'FIRSTVISIBLELINE= SendMessageAPI (hWnd,EM_GETFIRSTVISIBLELINE,0,0)
'FirstChar=SendMessageAPI (hWnd,EM_LINEINDEX,line_number,0) 
'LastVISIBLELINE=SendMessageAPI (hWnd,EM_LINEFROMCHAR,Lastchar,0 )

const rEM_EXLIMITTEXT = 1077
const rEM_LINEINDEX = 187
const rEM_LIMITTEXT = 197
const rEM_LINEFROMCHAR = 201
const rEM_LINELENGTH = 193
const rEM_LINESCROLL = 182
const rEM_PASTESPECIAL = 1088
const rEM_POSFROMCHAR = 214
const rEM_REPLACESEL = 194
const rEM_REQUESTRESIZE = 1089
const rEM_SCROLL = 181
const rEM_SCROLLCARET = 183

'================== START NEW COMPONENT ============================

Declare Function SendMessageA Lib "user32" Alias "SendMessageA" (hwnd _
As Long, wMsg As Long, wParam As Long, lParam As Long) As Long

Declare Function LINEINDEX as long ' позиция первого символа в строке
Declare Function LINEFROMCHAR as long  'номер строки содержащей символ в данной позиции
Declare Function GoToLineEnd as long  'установить курсор в конец строки
Declare Function GoToLineBegin as long  'установить курсор в начало строки


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
		LimitText AS LONG PROPERTY SET SetLimitText
		'LINEINDEX as long
		'LINEFROMCHAR as long

            PROPERTY SET SetLimitText(LimText as long)
'LimText - это значение, которое задает пользователь
'QMAXEDIT.LimitText - это свойство, которое можно потом считать (read)
' при изменении свойства .LimitText выполняется операция
.LimitText=LimText
result= SendMessageA (.handle,rEM_EXLIMITTEXT,0,.LimitText)
            END PROPERTY


Function LINEFROMCHAR  as long
result= SendMessageA (.handle, rEM_LINEFROMCHAR,.selstart,0 ) '
END function

		Function LINEINDEX as long
result=SendMessageA (.handle,rEM_LINEINDEX,.WhereY,0)'.LINEINDEX
		end function

Function GoToLineEnd as long
.selstart=.LINEINDEX+len(.Line(.whereY) )
END function

Function GoToLineBegin as long
.selstart=.LINEINDEX
END function

            PROPERTY SET Set_Popup(Use as long)
                .MaxMenu.AutoPopup = Use
            END PROPERTY

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
        
            
            CONSTRUCTOR
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
QMAXEDIT.mnuCut, QMAXEDIT.mnuCopy, QMAXEDIT.mnuPaste, QMAXEDIT.mnuDelete,_
QMAXEDIT.mnuSep2, QMAXEDIT.mnuSelectAll
                PopupMenu = .MaxMenu
                Set_Popup = 1
            END CONSTRUCTOR
            
    END WITH
    
END TYPE

$UNDEF QRICHEDIT
$DEFINE QRICHEDIT QMAXEDIT

'================= END NEW COMPONENT ========================


'To turn off the popup, set UsePopup = 0
'To use a different popup, just set Popupmenu = <new popup>

'Create the new richedit as you would the old one, thanks to the 
'$UNDEF-$DEFINE Keywords...ain't RapidQ great?

'Psyclops
   