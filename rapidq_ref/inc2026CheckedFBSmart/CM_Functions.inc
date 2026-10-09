' *****************************************************************************
' Functions                                                                   *
' *****************************************************************************

Declare Function SendMsg Lib "user32" Alias "SendMessageA" _
(ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, lParam As long) As Long

'______________________________________________________________________________
Declare Function SetFocus Lib "user32" Alias "SetFocus" (ByVal hwnd As Long) As Long

'______________________________________________________________________________
Declare Function CMRegister lib "cmcs21.dll" alias "CMRegisterControl" _
(Version as DWORD) as integer

'______________________________________________________________________________
Declare Function CMUnRegister lib "cmcs21.dll" alias "CMUnregisterControl" _
as integer

Declare Function CMRegisterLanguage lib "cmcs21.dll" alias _
"CMRegisterLanguage" (pszName as long, Lang as long) as long

const True = 1
const False = 0

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
Function CM_EnableColumnSel( hwnd as long, bEnable as Bool) as long
Result = Sendmsg (hWnd, CMM_ENABLECOLUMNSEL, bEnable, 0)
End Function

'______________________________________________________________________________
Function CM_IsNormalizeCaseEnabled (hWnd as long) as long
Result = Sendmsg (hWnd, CMM_ISNORMALIZECASEENABLED, 0, 0)
End Function

'______________________________________________________________________________
Function CM_IsOvertypeEnabled (hWnd as long) as long
Result = Sendmsg (hWnd, CMM_ISOVERTYPEENABLED, 0, 0)
End Function

'______________________________________________________________________________
Function CM_EnableSelBounds (hWnd as long, bEnable as bool) as long
Result = Sendmsg (hWnd, CMM_ENABLESELBOUNDS, 0, bEnable)
End Function

'______________________________________________________________________________
Function CM_EnableLineToolTips (hWnd as long, bEnable as bool) as long
Result = Sendmsg (hWnd, CMM_ENABLELINETOOLTIPS, 0, bEnable)
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
Function CM_SetFontOwnership (hWnd as long, bEnable as bool) as long
Result = Sendmsg (hWnd, CMM_SETFONTOWNERSHIP, bEnable, 0)
IF CME_FAILURE Then ShowMessage "It Failed"
End Function

'______________________________________________________________________________
Function CM_GetFontOwnership (hWnd as long, bEnable as bool) as long
Result = Sendmsg (hWnd, CMM_GETFONTOWNERSHIP, bEnable, 0)
IF CME_FAILURE Then ShowMessage "It Failed"
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
Result = Sendmsg (hWnd, CMM_SETBORDERSTYLE, CM_BORDER_CORRAL ,0)
End function

'______________________________________________________________________________
Function CM_SetModified (hwnd as long, bModified as bool) as Long
Result = Sendmsg (hWnd, CMM_SETMODIFIED, bModified,0)
End function

'______________________________________________________________________________
Function CM_IsModified (hWnd as long) as long
Result = Sendmsg (hWnd, CMM_ISMODIFIED,0,0)
End function

'______________________________________________________________________________
Function CM_EnableHideSel (hwnd as Long, bEnabled as Bool) As Long
Result = Sendmsg (hWnd, CMM_ENABLEHIDESEL, bEnabled, 0)
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
Function CM_InsertText (hWnd as Long, pszText as string, pPos as CM_POSITION) as long
Dim tmp as string
tmp = pszText
Result = Sendmsg (hWnd, CMM_INSERTTEXT, pPos, varptr(tmp))
End function

'______________________________________________________________________________
Function CM_OpenFile (hWnd as long, pszFilename as string) as long
Dim filename as string
Filename = pszFilename
Result = Sendmsg(hWnd, CMM_OPENFILE, 0, varptr(filename))
End Function

'______________________________________________________________________________
Function CM_InsertFile (hWnd as long, pszFilename as string, pPos as CM_POSITION) as long
Dim filename as string
Filename = pszFilename
Result = Sendmsg(hWnd, CMM_INSERTFILE, pPos, varptr(filename))
End Function

'______________________________________________________________________________
Function CM_Print (hWnd as long, hdc as long, dwFlags as word) as long
Result = Sendmsg(hwnd, CMM_PRINT, CM_PRINT_COLOR, 0)
End Function

'______________________________________________________________________________
Function CM_CanCut (hWnd as long) as long
Result = sendmsg(hWnd, CMM_CANCUT,0,0)
End function

'______________________________________________________________________________
Function CM_Cut (hWnd as long) as long
Result = sendmsg(hWnd, CMM_CUT,0,0)
End function

'______________________________________________________________________________
Function CM_CanCopy (hWnd as long) as long
Result = sendmsg(hWnd, CMM_CANCOPY,0,0)
End function

'______________________________________________________________________________
Function CM_Copy (hWnd as long) as long
Result = sendmsg(hWnd, CMM_COPY,0,0)
End function

'______________________________________________________________________________
Function CM_Paste (hWnd as long) as long
Result = sendmsg(hWnd, CMM_PASTE,0,0)
End function

'______________________________________________________________________________
Function CM_Undo (hWnd as long) as long
Result = sendmsg(hWnd, CMM_UNDO,0,0)
End function

'______________________________________________________________________________
Function CM_Redo (hWnd as long) as long
Result = sendmsg(hWnd, CMM_REDO,0,0)
End function

'______________________________________________________________________________
Function CM_SetSelect (hWnd as long) as long
Result = sendmsg(hWnd, CMM_SETSEL,0,0)
End function

'______________________________________________________________________________
Function CM_SelectAll (hWnd as long) as long
Result = sendmsg(hWnd, CMM_EXECUTECMD,CMD_SELECTALL,0)
End function

'______________________________________________________________________________
Function CM_Capitalize (hWnd as long) as Long
Result = sendmsg(hWnd, CMM_EXECUTECMD, CMD_WORDCAPITALIZE,0)
End function

'______________________________________________________________________________
Function CM_DeleteLine (hWnd as long, nLine as integer) as long
Result = sendmsg(hWnd, CMM_DELETELINE, nLine, 0)
End function

'______________________________________________________________________________
Function CM_GotoLine (hWnd as long, nLine as integer) as long
Result = sendmsg(hWnd, CMM_EXECUTECMD, CMD_GOTOLINE,nLine)
End function

'______________________________________________________________________________
Function CM_Upper (hWnd as long) as long
Result = sendmsg(hWnd, CMM_EXECUTECMD, CMD_WORDUPPERCASE,0)
End function

'______________________________________________________________________________
Function CM_Lower (hWnd as long) as long
Result = sendmsg(hWnd, CMM_EXECUTECMD, CMD_WORDLOWERCASE,0)
End function

'______________________________________________________________________________
Function CM_Home (hWnd as long) as long
Result = sendmsg(hWnd, CMM_EXECUTECMD, CMD_HOME,0)
End function

'______________________________________________________________________________
Function CM_Properties (hWnd as long) as long
Result = sendmsg(hWnd, CMM_EXECUTECMD, CMD_PROPERTIES,0)
End function

'______________________________________________________________________________
Function CM_FindNext (hWnd as long) as long
Result = sendmsg(hWnd, CMM_EXECUTECMD, CMD_FINDNEXT,0)
End function

'______________________________________________________________________________
Function CM_Delete (hWnd as long) as long
Result = sendmsg(hWnd, CMM_EXECUTECMD, CMD_DELETE,0)
End function

'______________________________________________________________________________
Function CM_DeleteSel (hWnd as long) as Long
Result = sendmsg(hWnd, CM_DeleteSel(1),0,0)
End function 


'______________________________________________________________________________
Function CM_SetText (hWnd as Long, pszText as string) as long
Result = sendmsg(hWnd, pszText, 0, 0)
End function

'______________________________________________________________________________
Function CM_SaveFile (hWnd as long, Filename as string, bClearUndo as Bool) as long
Dim tempfilename as string
tempfilename = Filename
SendMsg(hWnd, CMM_SAVEFILE,bClearUndo, varptr(tempFilename))
IF CME_FAILURE  Then ShowMessage "There was a problem saving the file"
End function
'______________________________________________________________________________
Function CM_SaveFileAs (hWnd as long, Filename as string) as long
Dim tempfilename as string
tempfilename = Filename
SendMsg(hWnd, CMM_SAVEFILE,, varptr(tempFilename))
IF CME_FAILURE  Then ShowMessage "There was a problem saving the file"
End function

'______________________________________________________________________________
Function CM_ShowScrollBar (hWnd as long, bHorizontal as bool, _
bshow as bool) as long
Result = SendMsg(hWnd, CMM_SHOWSCROLLBAR, bHorizontal, bshow)
End  Function

'______________________________________________________________________________
Function CM_EnableSplitter (hWnd as long, bHorizontal as bool, _
bEnable as bool) as long
Result = SendMsg(hWnd, CMM_ENABLESPLITTER, bHorizontal, bEnable)
End function

'______________________________________________________________________________
Function CM_SetBookmark (hWnd as long, nline as integer, bEnable as bool) as long
Result = SendMsg(hWnd, CMM_SETBOOKMARK, nline, bEnable)
End function

'______________________________________________________________________________
Function CM_NextBookmark  (hWnd as long) as long
Result = SendMsg(hWnd, CMM_EXECUTECMD, CMD_BOOKMARKNEXT, 0)
End function

'______________________________________________________________________________
Function CM_PrevBookmark  (hWnd as long) as long
Result = SendMsg(hWnd, CMM_EXECUTECMD, CMD_BOOKMARKPREV, 0)
End function

'______________________________________________________________________________
Function CM_DelBookmark  (hWnd as long) as long
Result = SendMsg(hWnd, CMM_EXECUTECMD, CMD_BOOKMARKTOGGLE, 0)
End function

'______________________________________________________________________________
Function CM_SetImageList (hWnd as long, hImageList as long) as long
Result = SendMsg(hWnd, CMM_SETIMAGELIST, 0, hImageList)
End function

'______________________________________________________________________________
Function CM_GetImageList (hWnd as long) as long
Result = SendMsg(hWnd, CMM_GETIMAGELIST, 0, 0)
End function

'______________________________________________________________________________
Function CM_SetMarginImages (hWnd as long, nLine as integer, _
ByImageIndex as byte) as Long
ByImageIndex = ByImageIndex - 1
Result = SendMsg(hWnd, CMM_SETMARGINIMAGES, nLine, 2^ByImageIndex)
End function

'______________________________________________________________________________
Function CM_AboutBox (hWnd as long) as long
Result = SendMsg(hWnd, CMM_ABOUTBOX,0,0)
End function

















' *****************************************************************************
' Commands and dialog boxes                                                   *
' *****************************************************************************
Sub CMC_Find (hwnd as long)
sendmsg(hWnd, CMM_EXECUTECMD,CMD_FIND,0)
End sub

'______________________________________________________________________________
Sub CMC_FindReplace (hwnd as long)
SetFocus(hWnd)
sendmsg(hWnd, CMM_EXECUTECMD,CMD_FINDREPLACE,0)
End sub















' *****************************************************************************
' Extensions (not included in the original CodeSense API)                     *'
' *****************************************************************************

'______________________________________________________________________________
Function CM_GetSel (hwnd as long, Range as CM_RANGE, _
bNormalized as bool) as long

dim SelMS as qmemorystream
dim tempResult as long


SelMs.WriteNum(0, 4) '
SelMs.WriteNum(0, 4) '
SelMs.WriteNum(0, 4) '
SelMs.WriteNum(0, 4) '
SelMs.WriteNum(0, 4)
' The previous lines create a 20 byte buffer, to store CMM_RANGE data.
 '
SelMs.position = 0
TempResult = Sendmsg (hWnd, CMM_GETSEL, bNormalized, SelMs.Pointer)
SelMs.ReadUDT(Range)
SelMS.close
Result = TempResult
End function
'______________________________________________________________________________
Function CMX_GetCursorPos (hwnd as long, Cur as CMX_Cursor, _
ZeroBased as BOOL) as long
Dim Range as CM_RANGE
CM_Getsel(hwnd, Range, True)
If Range.StartLine = Range.Endline AND Range.StartCol = Range.EndCol then
Cur.WhereX = Range.StartCol + (1 - ZeroBased)
Cur.WhereY = Range.StartLine + (1 - ZeroBased)
result = 0
Else
Cur.WhereX = -1
Cur.WhereY = -1
result = -1
end if
End function














' *****************************************************************************
' Other functions                                                             *
' *****************************************************************************

Function LoadKeywords (Filename as string) as string
Dim Tempstr as String
Dim Load_fs as qfilestream
Load_fs.open(Filename, 2)
Load_fs.position = 0
Tempstr = Load_fs.readstr (Load_fs.size)
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
Sub RegisterRapidQLanguage
Dim NewLanguage as CM_LANGUAGE

Dim KeyWords as string
Dim Operators as string
Dim SingleLineComments as string
Dim MultiLineComments1 as string
Dim MultiLineComments2 as string
Dim ScopeKeywords1 as string
Dim ScopeKeywords2 as string
DIM TagElementNames as string
Dim StringDelims as string
Dim chEscape as string
Dim chTerminator as string
Dim TagAttributeNames as string
Dim TagEntities as string
Dim Empty as string
Empty = chr$(0)

Dim olddir as string
olddir = Curdir$
'Chdir FO_homedir

KeyWords =  LoadKeyWords("KEYWORD.LST") & chr$(10) & _
            LoadKeyWords("Scope1.lst") & chr$(10) & _
            LoadKeyWords("Operators.LST")

Operators = LoadKeyWords("Qtypes.LST") & chr$(10) & _
            LoadKeyWords("Directives.LST")


SinglelineComments = "'"

ScopeKeywords1 = LoadKeyWords("Properties.LST")
ScopeKeywords2 = LoadKeyWords("Scope2.lst")
TagElementNames = LoadKeyWords("Scope3.lst")

StringDelims = chr$(34)

chdir olddir

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
.pszTagElementNames = varptr(TagElementNames)
.pszTagAttributeNames = varptr(empty)
.pszTagEntities = varptr(empty)
End With

Cm_RegisterLanguage("RapidQ", NewLanguage)
End sub


'______________________________________________________________________________
'Declare sub codeform_Resize (sender as qform)
'
'Dim Winh(128) as long
'Dim UnId(128) as integer
'Dim CodeForm(128) as qform
'Dim SourceFile(129) as string
'Dim EW_RegistrationDone as Long
'Dim CurrentUnID as integer
'Dim CurrentFile as string
'CurrentUnID = 0
'
'Dim CS_Build_I as integer
'
'For CS_Build_I = 0 to 128
'CodeForm(CS_Build_I).onresize = CodeForm_resize
'Next

  