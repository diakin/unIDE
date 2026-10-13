$IFNDEF __FUNCTIONS_INC   ' IncManager: include guard
$DEFINE __FUNCTIONS_INC
Declare Function SendMsg Lib "user32" Alias "SendMessageA" _
(ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, lParam As long) As Long

'______________________________________________________________________________
Declare Function CMRegister lib "cmcs21.dll" alias "CMRegisterControl" _
(Version as DWORD) as integer

'______________________________________________________________________________
Declare Function CMUnRegister lib "cmcs21.dll" alias "CMUnregisterControl" _
as integer

Declare Function CMRegisterLanguage lib "cmcs21.dll" alias _
"CMRegisterLanguage" (pszName as long, Lang as long) as long


'______________________________________________________________________________
Function CM_SetLanguage (hWnd as long, pszName as string) as long
Dim LangName as string
LangName = pszName
Result = Sendmsg (hWnd, CMM_SETLANGUAGE, 0, varptr(LangName))
End Function

'______________________________________________________________________________
Function CM_GetLanguage (hwnd as long) as string
Dim LangName as string
LangName = String$(20, CM_MAX_LANGUAGE_NAME)
Sendmsg (hWnd, CMM_GETLANGUAGE, 0, varptr(LangName))
Result = LangName
End function

'______________________________________________________________________________
Function Cm_EnableColorSyntax (hWnd as long, Enable as integer) as long
Result = Sendmsg (hWnd, CMM_ENABLECOLORSYNTAX, Enable, 0)
End Function

'______________________________________________________________________________

Function Cm_IsColorSyntaxEnabled (hWnd as long) as Bool
Result = Sendmsg (hWnd, CMM_ISCOLORSYNTAXENABLED, 0, 0)
End Function

'______________________________________________________________________________
Function Cm_SetColors (hWnd as long, colors as CM_COLORS) as long
Dim Col_Mem as qmemorystream
Dim output as long
Col_Mem.position = 0
Col_Mem.WriteUDT(colors)
output = Sendmsg (hWnd, CMM_SETCOLORS, 0, Col_Mem.pointer)
Col_Mem.close
Result = output
End Function

'______________________________________________________________________________
Function Cm_RegisterLanguage (pszName as String, Lang as CM_LANGUAGE) as long
Dim error as long
Dim LangName as string
LangName = pszName
Dim RL_Mem as qmemorystream
RL_mem.position = 0
RL_Mem.WriteUDT(Lang)
error = CMRegisterLanguage(varptr(LangName), RL_Mem.pointer)
RL_Mem.close
result = error
End function


'______________________________________________________________________________
Function CM_SetFontStyles (hWnd as long, FontStyles as CM_FONTSTYLES) as long
Dim Fn_Mem as qmemorystream
Dim output as long
Fn_Mem.position = 0
Fn_Mem.WriteUDT(FontStyles)
output = Sendmsg (hWnd, CMM_SETFONTSTYLES, 0, Fn_Mem.pointer)
Fn_Mem.close
Result = output
End Function

'______________________________________________________________________________
Function CM_SetLinenumbering (hwnd as long, _
LineNumbering as CM_LINENUMBERING) as long

Dim Ln_Mem as qmemorystream
Dim output as long
Ln_Mem.position = 0
Ln_Mem.WriteUDT(Linenumbering)
output = Sendmsg (hWnd, CMM_SETLINENUMBERING, 0, Ln_Mem.pointer)
Ln_Mem.close
Result = output
End function

'______________________________________________________________________________
Function CM_EnableLeftMargin (hWnd as long, benable as BOOL) as long
Result = Sendmsg (hWnd, CMM_ENABLELEFTMARGIN, bEnable, 0)
End Function

'______________________________________________________________________________
Function CM_IsLeftMarginEnabled (hWnd as long) as long
Result = Sendmsg (hWnd, CMM_ISLEFTMARGINENABLED,0,0)
End Function

'______________________________________________________________________________
Function CM_SetBorderStyle(hWnd as long, dwStyle as dword) as long
Result = Sendmsg (hWnd, CMM_SETBORDERSTYLE, dwStyle,0)
End function

'______________________________________________________________________________
Function CM_SetDivider (hWnd as long, nLine as Integer, bEnable as BOOL) as long
Result = Sendmsg (hWnd, CMM_SETDIVIDER, nline, bEnable)
End Function

'______________________________________________________________________________
Function CM_GetDivider (hWnd as long, nLine as Integer) as Bool
Result = Sendmsg (hWnd, CMM_GETDIVIDER, nline, 0)
End Function

'______________________________________________________________________________
Function CM_EnableDragDrop (hWnd as Long, bEnable as bool) as long
Result = Sendmsg (hWnd, CMM_ENABLEDRAGDROP, bEnable, 0)
End function

'______________________________________________________________________________
Function CM_IsDragDropEnabled (hWnd as Long) as bool
Result = Sendmsg (hWnd, CMM_ISDRAGDROPENABLED, 0, 0)
End function


'______________________________________________________________________________
Function LoadKeywords (Filename as string) as string
Dim Tempstr as String
Dim Load_fs as qfilestream
Load_fs.open(Filename, 2)
Load_fs.position = 0
Tempstr = Load_fs.readstr(Load_fs.size)
Load_fs.close
Tempstr = replacesubstr$(Tempstr, chr$(13), "")
Result = TempStr
End Function

'______________________________________________________________________________
FUNCTION SplitPath(Source AS STRING) AS STRING
    DIM Path AS STRING
    DIM Position AS LONG
    Path = ""
    Position = INSTR(1,Source,"\\")
    WHILE Position > 0
      Path = Path + LEFT$(Source,Position)
      Source = DELETE$(Source,1,Position)
      Position = INSTR(Source,"\\")
    WEND
    Result = Path
END FUNCTION

'______________________________________________________________________________
Function LoadFile (Filename as string, hwnd As Long) as string
Dim Tempstr as String
Dim Load_fs as qfilestream
Load_fs.open(Filename, 2)
Load_fs.position = 0
Tempstr = Load_fs.readstr(Load_fs.size)
Load_fs.close
Result = Sendmsg (hWnd, CMM_INSERTTEXT , 0, Varptr(TempStr))
End Function
'______________________________________________________________________________
Sub RegisterRapidQLanguage
Dim NewLanguage as CM_LANGUAGE

Dim KeyWords as string
Dim Operators as string
Dim SingleLineComments as string
Dim MultiLineComments1 as string
Dim MultiLineComments2 as string
Dim ScopeKeywords1 as string
Dim ScopeKeywords2 as string
Dim StringDelims as string
Dim chEscape as string
Dim chTerminator as string
Dim TagElementNames as string
Dim TagAttributeNames as string
Dim TagEntities as string
Dim Empty as string
Empty = chr$(0)

KeyWords =  LoadKeyWords("KEYWORD.LST") & chr$(10) & _
            LoadKeyWords("Scope1.lst") & chr$(10) & _
            LoadKeyWords("Operators.LST")

Operators = LoadKeyWords("Qtypes.LST") & chr$(10) & _
            LoadKeyWords("Directives.LST")


SinglelineComments = "'"

ScopeKeywords1 = LoadKeyWords("Properties.LST")
ScopeKeywords2 = LoadKeyWords("Scope2.lst")


StringDelims = chr$(34)



With NewLanguage
.dwStyle = CMLS_PROCEDURAL
.bIsCaseSensitive = False
.pszKeywords = varptr(KeyWords)
.pszOperators = varptr(Operators)
.pszSingleLineComments = varptr(SingleLineComments)
.pszMultiLineComments1 = varptr(empty)
.pszMultiLineComments2 = varptr(empty)
.pszScopeKeywords1 = varptr(ScopeKeywords1)
.pszScopeKeywords2 = varptr(ScopeKeywords2)
.pszStringDelims = varptr(StringDelims)
.chEscape = varptr(empty)
.chTerminator = varptr(empty)
.pszTagElementNames = varptr(empty)
.pszTagAttributeNames = varptr(empty)
.pszTagEntities = varptr(empty)
End With

Cm_RegisterLanguage("RapidQ", NewLanguage)
End sub  
$ENDIF   ' IncManager: __FUNCTIONS_INC
