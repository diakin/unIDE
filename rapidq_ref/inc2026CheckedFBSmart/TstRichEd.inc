const rEM_LINEINDEX = 187
Declare Function SendMessageA Lib "user32" Alias "SendMessageA" (hwnd _
As Long, wMsg As Long, wParam As Long, lParam As Long) As Long

Declare Function LINEINDEX as long ' позиция первого символа в строке
TYPE TestEDIT EXTENDS QRICHEDIT
    WITH TestEDIT
		Function LINEINDEX as long
			result=SendMessageA (.handle,rEM_LINEINDEX,.WhereY,0)'.LINEINDEX
		end function
    END WITH
END TYPE
$UNDEF QRICHEDIT
$DEFINE QRICHEDIT QMAXEDIT
'================= END NEW COMPONENT ========================
  
