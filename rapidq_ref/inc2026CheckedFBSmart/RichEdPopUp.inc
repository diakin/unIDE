'Just the other day I whipped up a little QRICHEDIT extension to pop 
'up a menu exactly like the default windows context menu. Here it is, 
'enjoy:

'================== START NEW COMPONENT ============================

Declare Function SendMessageA Lib "user32" Alias "SendMessageA" (hwnd _
As Long, wMsg As Long, wParam As Long, lParam As Long) As Long

Declare Function LINEINDEX as long ' позиция первого символа в строке
Declare Function LINEFROMCHAR as long  'номер строки содержащей начало выделения

Declare Function LINEFROMPos (chrpos as long) as long  'номер строки содержащей символ в данной позиции


Declare Function GoToLineEnd as long 
Declare Function GoToLineBegin as long 

const rEM_EXLINEFROMCHAR = 1078
const rEM_LINEINDEX = 187
const rEM_LINEFROMCHAR = 201

const rEM_LINELENGTH = 193


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
	RichFont as QFont
	
	Function LINEINDEX as long
	result=SendMessageA (.handle,rEM_LINEINDEX,.WhereY,0)'posFirstCharOf Current Line
	end function
	
	Function GetLINEIdx(line as long) as long ' позиция первого символа строки N line в тексте
	result=SendMessageA (.handle,rEM_LINEINDEX,line,0)'.LINEINDEX
	end function
	
	Function LINEFROMCHAR as long
	result=SendMessageA (.handle,rEM_LINEFROMCHAR,.SelStart,0)'.LINEINDEX текущей строки
	end function
	
	Function LINEFROMPos (chrpos as long) as long
	result=SendMessageA (.handle,rEM_LINEFROMCHAR,chrpos,0)'.LINEINDEX по заданной позиции курсора
	end function
	
	
	Function GoToLineEnd as long
	.selstart=.LINEINDEX+len(.line(.WhereY)) ' установить курсор в конец текущей строки
	end function
	
	Function GoToLineBegin as long  ' установить курсор в начало текущей строки
	.selstart=.LINEINDEX
	end function
	
	
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
	QMAXEDIT.mnuCut, QMAXEDIT.mnuCopy, QMAXEDIT.mnuPaste, QMAXEDIT.mnuDelete,_
	QMAXEDIT.mnuSep2, QMAXEDIT.mnuSelectAll
	PopupMenu = .MaxMenu
	Set_Popup = 1
	END constRUCTOR
	
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

