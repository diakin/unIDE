'-----------------------------------------------------------------------------|
' This file is a translation of the original C/C++ header file                |
'-----------------------------------------------------------------------------|
'   Dreadsoft® Corporation                                                    |
'(manco un diritto riservato)                                                 |
'    dreadsoft@yahoo.it                                                       |
'-----------------------------------------------------------------------------|


'-----------------------------------------------------------------------------|
' CodeMax/CodeSense Code Editor Control                                       |
' Original Copyright © 1997-2003 WinMain Software                             |
' Portions Copyright © 2000-2003 Nathan Lewis                                 |
'                                                                             |
' This header file declares all exported functionality of the CodeMax         |
' custom control. For a complete description of all declarations below,       |
' please refer to the CodeMax documentation.                                  |
'-----------------------------------------------------------------------------|


const CODESENSEWNDCLASS = "CodeSense"

'-----------------------------------------------------------------------------|
' Constants                                                                   |
'-----------------------------------------------------------------------------|


' maximum size (TCHARs) of text to find or replace
const CM_MAX_FINDREPL_TEXT = 100
' maximum MRU size in find and find/replace dialogs
const CM_FIND_REPLACE_MRU_MAX = 10
' required buffer size for pszMRUList argument CMSetFindReplaceMRUList() and CMGetFindReplaceMRUList()
const CM_FIND_REPLACE_MRU_BUFF_SIZE = ((CM_MAX_FINDREPL_TEXT + 1) * CM_FIND_REPLACE_MRU_MAX)
' maximum number of keystroke macros supported by CodeMax
const CM_MAX_MACROS = 10
' maximum size of command string returned in pszBuff param of CMGetCommandString() if bDescription is FALSE
const CM_MAX_CMD_STRING = 50
' maximum size of command string returned in pszBuff param of CMGetCommandString() if bDescription is TRUE
const CM_MAX_CMD_DESCRIPTION = 100
' maximum size of a language name set with CMRegisterLanguage
const CM_MAX_LANGUAGE_NAME = 30
' maximum tab size (characters)
const CM_MAX_TABSIZE = 100
' minimum tab size (characters)
const CM_MIN_TABSIZE = 2
' left margin width (pixels)
const CM_CXLEFTMARGIN = 24
' maximum CodeList tooltip text length
const CM_MAX_CODELIST_TIP = 128

'-----------------------------------------------------------------------------|
' CMM_SETLINESTYLE style bits                                                 |
'-----------------------------------------------------------------------------|

const CML_OWNERDRAW = &H1
const CML_NOTIFY_DEL = &H2

'-----------------------------------------------------------------------------|
' Messages                                                                    |
'-----------------------------------------------------------------------------|
const CMM_SETLANGUAGE                 = ( WM_USER + 1600 )
const CMM_GETLANGUAGE                 = ( WM_USER + 1601 )
const CMM_ENABLECOLORSYNTAX           = ( WM_USER + 1610 )
const CMM_ISCOLORSYNTAXENABLED        = ( WM_USER + 1620 )
const CMM_SETCOLORS                   = ( WM_USER + 1630 )
const CMM_GETCOLORS                   = ( WM_USER + 1640 )
const CMM_ENABLEWHITESPACEDISPLAY     = ( WM_USER + 1800 )
const CMM_ISWHITESPACEDISPLAYENABLED  = ( WM_USER + 1810 )
const CMM_ENABLETABEXPAND             = ( WM_USER + 1811 )
const CMM_ISTABEXPANDENABLED          = ( WM_USER + 1812 )
const CMM_ENABLESMOOTHSCROLLING       = ( WM_USER + 1820 )
const CMM_SETTABSIZE                  = ( WM_USER + 1821 )
const CMM_GETTABSIZE                  = ( WM_USER + 1822 )
const CMM_ISSMOOTHSCROLLINGENABLED    = ( WM_USER + 1830 )
const CMM_SETREADONLY                 = ( WM_USER + 1840 )
const CMM_ISREADONLY                  = ( WM_USER + 1850 )
const CMM_ENABLELINETOOLTIPS          = ( WM_USER + 1860 )
const CMM_ISLINETOOLTIPSENABLED       = ( WM_USER + 1870 )
const CMM_ENABLELEFTMARGIN            = ( WM_USER + 1880 )
const CMM_ISLEFTMARGINENABLED         = ( WM_USER + 1890 )
const CMM_ENABLECOLUMNSEL             = ( WM_USER + 1891 )
const CMM_ISCOLUMNSELENABLED          = ( WM_USER + 1892 )
const CMM_ENABLEDRAGDROP              = ( WM_USER + 1893 )
const CMM_ISDRAGDROPENABLED           = ( WM_USER + 1894 )
const CMM_ENABLEOVERTYPE              = ( WM_USER + 1900 )
const CMM_ISOVERTYPEENABLED           = ( WM_USER + 1910 )
const CMM_ENABLECASESENSITIVE         = ( WM_USER + 1920 )
const CMM_ISCASESENSITIVEENABLED      = ( WM_USER + 1930 )
const CMM_ENABLEPRESERVECASE          = ( WM_USER + 1931 )
const CMM_ISPRESERVECASEENABLED       = ( WM_USER + 1932 )
const CMM_ENABLEWHOLEWORD             = ( WM_USER + 1940 )
const CMM_ISWHOLEWORDENABLED          = ( WM_USER + 1950 )
const CMM_SETTOPINDEX                 = ( WM_USER + 1960 )
const CMM_GETTOPINDEX                 = ( WM_USER + 1970 )
const CMM_GETVISIBLELINECOUNT         = ( WM_USER + 1980 )
const CMM_HITTEST                     = ( WM_USER + 1990 )
const CMM_OPENFILE                    = ( WM_USER + 2300 )
const CMM_SAVEFILE                    = ( WM_USER + 2310 )
const CMM_INSERTFILE                  = ( WM_USER + 2320 )
const CMM_INSERTTEXT                  = ( WM_USER + 2330 )
const CMM_SETTEXT                     = ( WM_USER + 2335 )
const CMM_REPLACETEXT                 = ( WM_USER + 2340 )
const CMM_GETTEXTLENGTH               = ( WM_USER + 2350 )
const CMM_GETTEXT                     = ( WM_USER + 2360 )
const CMM_GETLINECOUNT                = ( WM_USER + 2365 )
const CMM_GETLINE                     = ( WM_USER + 2370 )
const CMM_GETLINELENGTH               = ( WM_USER + 2380 )
const CMM_GETWORD                     = ( WM_USER + 2381 )
const CMM_GETWORDLENGTH               = ( WM_USER + 2382 )
const CMM_ADDTEXT                     = ( WM_USER + 2390 )
const CMM_DELETELINE                  = ( WM_USER + 2400 )
const CMM_INSERTLINE                  = ( WM_USER + 2410 )
const CMM_GETSEL                      = ( WM_USER + 2420 )
const CMM_GETSELFROMPOINT             = ( WM_USER + 2425 )
const CMM_SETSEL                      = ( WM_USER + 2430 )
const CMM_SELECTLINE                  = ( WM_USER + 2435 )
const CMM_DELETESEL                   = ( WM_USER + 2440 )
const CMM_REPLACESEL                  = ( WM_USER + 2450 )
const CMM_ISMODIFIED                  = ( WM_USER + 2460 )
const CMM_SETMODIFIED                 = ( WM_USER + 2461 )
const CMM_ENABLECRLF                  = ( WM_USER + 2470 )
const CMM_ISCRLFENABLED               = ( WM_USER + 2480 )
const CMM_SETFONTOWNERSHIP            = ( WM_USER + 2485 )
const CMM_GETFONTOWNERSHIP            = ( WM_USER + 2486 )
const CMM_EXECUTECMD                  = ( WM_USER + 2700 )
const CMM_SETSPLITTERPOS              = ( WM_USER + 2900 )
const CMM_GETSPLITTERPOS              = ( WM_USER + 2901 )
const CMM_SETAUTOINDENTMODE           = ( WM_USER + 3100 )
const CMM_GETAUTOINDENTMODE           = ( WM_USER + 3110 )
const CMM_CANUNDO                     = ( WM_USER + 3300 )
const CMM_CANREDO                     = ( WM_USER + 3310 )
const CMM_CANCUT                      = ( WM_USER + 3320 )
const CMM_CANCOPY                     = ( WM_USER + 3330 )
const CMM_CANPASTE                    = ( WM_USER + 3340 )
const CMM_REDO                        = ( WM_USER + 3350 )
const CMM_CLEARUNDOBUFFER             = ( WM_USER + 3351 )
const CMM_UNDO                        = ( WM_USER + 3360 )
const CMM_CUT                         = ( WM_USER + 3370 )
const CMM_COPY                        = ( WM_USER + 3380 )
const CMM_PASTE                       = ( WM_USER + 3390 )
const CMM_SETUNDOLIMIT                = ( WM_USER + 3400 )
const CMM_GETUNDOLIMIT                = ( WM_USER + 3410 )
const CMM_GETVIEWCOUNT                = ( WM_USER + 3600 )
const CMM_GETCURRENTVIEW              = ( WM_USER + 3610 )
const CMM_SHOWSCROLLBAR               = ( WM_USER + 3700 )
const CMM_HASSCROLLBAR                = ( WM_USER + 3710 )
const CMM_ENABLESPLITTER              = ( WM_USER + 3720 )
const CMM_ISSPLITTERENABLED           = ( WM_USER + 3730 )
const CMM_ISRECORDINGMACRO            = ( WM_USER + 3731 )
const CMM_ISPLAYINGMACRO              = ( WM_USER + 3732 )
const CMM_ENABLEGLOBALPROPS           = ( WM_USER + 3740 )
const CMM_ISGLOBALPROPSENABLED        = ( WM_USER + 3741 )
const CMM_SETDLGPARENT                = ( WM_USER + 3750 )

' 2.0
const CMM_ENABLESELBOUNDS             = ( WM_USER + 3760 )
const CMM_ISSELBOUNDSENABLED          = ( WM_USER + 3770 )
const CMM_SETFONTSTYLES               = ( WM_USER + 3780 )
const CMM_GETFONTSTYLES               = ( WM_USER + 3790 )
const CMM_ENABLEREGEXP                = ( WM_USER + 3800 )
const CMM_ISREGEXPENABLED             = ( WM_USER + 3810 )
const CMM_SETITEMDATA                 = ( WM_USER + 3820 )
const CMM_GETITEMDATA                 = ( WM_USER + 3830 )
const CMM_SETLINESTYLE                = ( WM_USER + 3840 )
const CMM_GETLINESTYLE                = ( WM_USER + 3850 )
const CMM_SETBOOKMARK                 = ( WM_USER + 3860 )
const CMM_GETBOOKMARK                 = ( WM_USER + 3870 )
const CMM_SETALLBOOKMARKS             = ( WM_USER + 3880 )
const CMM_GETALLBOOKMARKS             = ( WM_USER + 3890 )
const CMM_SETLINENUMBERING            = ( WM_USER + 3900 )
const CMM_GETLINENUMBERING            = ( WM_USER + 3910 )
const CMM_POSFROMCHAR                 = ( WM_USER + 3920 )
const CMM_ENABLEHIDESEL               = ( WM_USER + 3930 )
const CMM_ISHIDESELENABLED            = ( WM_USER + 3940 )
const CMM_SETHIGHLIGHTEDLINE          = ( WM_USER + 3950 )
const CMM_GETHIGHLIGHTEDLINE          = ( WM_USER + 3960 )
const CMM_ENABLENORMALIZECASE         = ( WM_USER + 3970 )
const CMM_ISNORMALIZECASEENABLED      = ( WM_USER + 3980 )
const CMM_SETDIVIDER                  = ( WM_USER + 3990 )
const CMM_GETDIVIDER                  = ( WM_USER + 4000 )
const CMM_ENABLEOVERTYPECARET         = ( WM_USER + 4010 )
const CMM_ISOVERTYPECARETENABLED      = ( WM_USER + 4020 )
const CMM_SETFINDTEXT                 = ( WM_USER + 4030 )
const CMM_GETFINDTEXT                 = ( WM_USER + 4040 )
const CMM_SETREPLACETEXT              = ( WM_USER + 4050 )
const CMM_GETREPLACETEXT              = ( WM_USER + 4060 )
const CMM_SETIMAGELIST                = ( WM_USER + 4070 )
const CMM_GETIMAGELIST                = ( WM_USER + 4080 )
const CMM_SETMARGINIMAGES             = ( WM_USER + 4090 )
const CMM_GETMARGINIMAGES             = ( WM_USER + 4100 )
const CMM_ABOUTBOX                    = ( WM_USER + 4110 )
const CMM_PRINT                       = ( WM_USER + 4120 )
const CMM_SETCARETPOS                 = ( WM_USER + 4130 )
const CMM_VIEWCOLTOBUFFERCOL          = ( WM_USER + 4140 )
const CMM_BUFFERCOLTOVIEWCOL          = ( WM_USER + 4150 )

' 2.1
const CMM_SETBORDERSTYLE              = ( WM_USER + 4160 )
const CMM_GETBORDERSTYLE              = ( WM_USER + 4170 )
const CMM_SETCURRENTVIEW              = ( WM_USER + 4180 )

' Changed due to addition of CMM_SETCURRENTVIEW in CodeMax 2.1.0.14
'const CMM_GETCURRENTTOKEN             = ( WM_USER + 4180 )
const CMM_GETCURRENTTOKEN             = ( WM_USER + 5000 )
const CMM_UPDATECONTROLPOSITIONS      = ( WM_USER + 5010 )



'-----------------------------------------------------------------------------|
' Notifications                                                               |
'-----------------------------------------------------------------------------|

const CMN_CHANGE = 100
const CMN_HSCROLL = 110
const CMN_VSCROLL = 120
const CMN_SELCHANGE = 130
const CMN_VIEWCHANGE = 140
const CMN_MODIFIEDCHANGE = 150
const CMN_SHOWPROPS = 160
const CMN_PROPSCHANGE = 170
const CMN_CREATE = 180
const CMN_DESTROY = 190

' 2.0
const CMN_DRAWLINE = 200
const CMN_DELETELINE = 210
const CMN_CMDFAILURE = 220
const CMN_REGISTEREDCMD = 230
const CMN_KEYDOWN = 240
const CMN_KEYUP = 250
const CMN_KEYPRESS = 260
const CMN_MOUSEDOWN = 270
const CMN_MOUSEUP = 280
const CMN_MOUSEMOVE = 290
const CMN_OVERTYPECHANGE = 300

' 2.1
const CMN_FINDWRAPPED = 310

const CMN_CODELIST = 320
const CMN_CODELISTSELMADE = 330
const CMN_CODELISTCANCEL = 340
const CMN_CODELISTCHAR = 350
const CMN_CODETIP = 360
const CMN_CODETIPINITIALIZE = 365
const CMN_CODETIPCANCEL = 370
const CMN_CODETIPUPDATE = 380
const CMN_CODELISTSELWORD = 390
const CMN_CODELISTSELCHANGE = 400
const CMN_CODELISTHOTTRACK = 410


'-----------------------------------------------------------------------------|
' Edit commands                                                               |
'-----------------------------------------------------------------------------|

const CMD_FIRST = 100
const CMD_WORDUPPERCASE = (CMD_FIRST + 0)
const CMD_WORDTRANSPOSE = (CMD_FIRST + 1)
const CMD_WORDRIGHTEXTEND = (CMD_FIRST + 2)
const CMD_WORDRIGHT = (CMD_FIRST + 3)
const CMD_WORDENDRIGHT = (CMD_FIRST + 4)
const CMD_WORDENDRIGHTEXTEND = (CMD_FIRST + 5)
const CMD_WORDLOWERCASE = (CMD_FIRST + 6)
const CMD_WORDLEFTEXTEND = (CMD_FIRST + 7)
const CMD_WORDLEFT = (CMD_FIRST + 8)
const CMD_WORDENDLEFT = (CMD_FIRST + 9)
const CMD_WORDENDLEFTEXTEND = (CMD_FIRST + 10)
const CMD_WORDDELETETOSTART = (CMD_FIRST + 11)
const CMD_WORDDELETETOEND = (CMD_FIRST + 12)
const CMD_WORDCAPITALIZE = (CMD_FIRST + 13)
const CMD_WINDOWSTART = (CMD_FIRST + 14)
const CMD_WINDOWSCROLLUP = (CMD_FIRST + 15)
const CMD_WINDOWSCROLLTOTOP = (CMD_FIRST + 16)
const CMD_WINDOWSCROLLTOCENTER = (CMD_FIRST + 17)
const CMD_WINDOWSCROLLTOBOTTOM = (CMD_FIRST + 18)
const CMD_WINDOWSCROLLRIGHT = (CMD_FIRST + 19)
const CMD_WINDOWSCROLLLEFT = (CMD_FIRST + 20)
const CMD_WINDOWSCROLLDOWN = (CMD_FIRST + 21)
const CMD_WINDOWRIGHTEDGE = (CMD_FIRST + 22)
const CMD_WINDOWLEFTEDGE = (CMD_FIRST + 23)
const CMD_WINDOWEND = (CMD_FIRST + 24)
const CMD_UPPERCASESELECTION = (CMD_FIRST + 25)
const CMD_UNTABIFYSELECTION = (CMD_FIRST + 26)
const CMD_UNINDENTSELECTION = (CMD_FIRST + 27)
const CMD_UNDOCHANGES = (CMD_FIRST + 28)
const CMD_UNDO = (CMD_FIRST + 29)
const CMD_TABIFYSELECTION = (CMD_FIRST + 30)
const CMD_SENTENCERIGHT = (CMD_FIRST + 31)
const CMD_SENTENCELEFT = (CMD_FIRST + 32)
const CMD_SENTENCECUT = (CMD_FIRST + 33)
const CMD_SELECTSWAPANCHOR = (CMD_FIRST + 34)
const CMD_SELECTPARA = (CMD_FIRST + 35)
const CMD_SELECTLINE = (CMD_FIRST + 36)
const CMD_SELECTALL = (CMD_FIRST + 37)
const CMD_REDOCHANGES = (CMD_FIRST + 38)
const CMD_REDO = (CMD_FIRST + 39)
const CMD_PASTE = (CMD_FIRST + 40)
const CMD_PARAUP = (CMD_FIRST + 41)
const CMD_PARADOWN = (CMD_FIRST + 42)
const CMD_PAGEUPEXTEND = (CMD_FIRST + 43)
const CMD_PAGEUP = (CMD_FIRST + 44)
const CMD_PAGEDOWNEXTEND = (CMD_FIRST + 45)
const CMD_PAGEDOWN = (CMD_FIRST + 46)
const CMD_LOWERCASESELECTION = (CMD_FIRST + 47)
const CMD_LINEUPEXTEND = (CMD_FIRST + 48)
const CMD_LINEUP = (CMD_FIRST + 49)
const CMD_LINETRANSPOSE = (CMD_FIRST + 50)
const CMD_LINESTART = (CMD_FIRST + 51)
const CMD_LINEOPENBELOW = (CMD_FIRST + 52)
const CMD_LINEOPENABOVE = (CMD_FIRST + 53)
const CMD_LINEENDEXTEND = (CMD_FIRST + 54)
const CMD_LINEEND = (CMD_FIRST + 55)
const CMD_LINEDOWNEXTEND = (CMD_FIRST + 56)
const CMD_LINEDOWN = (CMD_FIRST + 57)
const CMD_LINEDELETETOSTART = (CMD_FIRST + 58)
const CMD_LINEDELETETOEND = (CMD_FIRST + 59)
const CMD_LINEDELETE = (CMD_FIRST + 60)
const CMD_LINECUT = (CMD_FIRST + 61)
const CMD_INDENTTOPREV = (CMD_FIRST + 62)
const CMD_INDENTSELECTION = (CMD_FIRST + 63)
const CMD_HOMEEXTEND = (CMD_FIRST + 64)
const CMD_HOME = (CMD_FIRST + 65)
const CMD_GOTOMATCHBRACE = (CMD_FIRST + 66)
const CMD_GOTOINDENTATION = (CMD_FIRST + 67)
const CMD_GOTOLINE = (CMD_FIRST + 68)
const CMD_FINDREPLACE = (CMD_FIRST + 69)
const CMD_REPLACE = (CMD_FIRST + 70)
const CMD_REPLACEALLINBUFFER = (CMD_FIRST + 71)
const CMD_REPLACEALLINSELECTION = (CMD_FIRST + 72)
const CMD_FINDPREVWORD = (CMD_FIRST + 73)
const CMD_FINDPREV = (CMD_FIRST + 74)
const CMD_FINDNEXTWORD = (CMD_FIRST + 75)
const CMD_FINDNEXT = (CMD_FIRST + 76)
const CMD_FINDMARKALL = (CMD_FIRST + 77)
const CMD_FIND = (CMD_FIRST + 78)
const CMD_SETFINDTEXT = (CMD_FIRST + 79)
const CMD_SETREPLACETEXT = (CMD_FIRST + 80)
const CMD_TOGGLEPRESERVECASE = (CMD_FIRST + 81)
const CMD_TOGGLEWHOLEWORD = (CMD_FIRST + 82)
const CMD_TOGGLECASESENSITIVE = (CMD_FIRST + 83)
const CMD_END = (CMD_FIRST + 84)
const CMD_TOGGLEWHITESPACEDISPLAY = (CMD_FIRST + 85)
const CMD_TOGGLEOVERTYPE = (CMD_FIRST + 86)
const CMD_SETREPEATCOUNT = (CMD_FIRST + 87)
const CMD_DOCUMENTSTARTEXTEND = (CMD_FIRST + 88)
const CMD_DOCUMENTSTART = (CMD_FIRST + 89)
const CMD_DOCUMENTENDEXTEND = (CMD_FIRST + 90)
const CMD_DOCUMENTEND = (CMD_FIRST + 91)
const CMD_DELETEHORIZONTALSPACE = (CMD_FIRST + 92)
const CMD_DELETEBLANKLINES = (CMD_FIRST + 93)
const CMD_DELETEBACK = (CMD_FIRST + 94)
const CMD_DELETE = (CMD_FIRST + 95)
const CMD_CUTSELECTION = (CMD_FIRST + 96)
const CMD_CUT = (CMD_FIRST + 97)
const CMD_COPY = (CMD_FIRST + 98)
const CMD_CHARTRANSPOSE = (CMD_FIRST + 99)
const CMD_CHARRIGHTEXTEND = (CMD_FIRST + 100)
const CMD_CHARRIGHT = (CMD_FIRST + 101)
const CMD_CHARLEFTEXTEND = (CMD_FIRST + 102)
const CMD_CHARLEFT = (CMD_FIRST + 103)
const CMD_BOOKMARKTOGGLE = (CMD_FIRST + 104)
const CMD_BOOKMARKPREV = (CMD_FIRST + 105)
const CMD_BOOKMARKNEXT = (CMD_FIRST + 106)
const CMD_BOOKMARKCLEARALL = (CMD_FIRST + 107)
const CMD_BOOKMARKJUMPTOFIRST = (CMD_FIRST + 108)
const CMD_BOOKMARKJUMPTOLAST = (CMD_FIRST + 109)
const CMD_APPENDNEXTCUT = (CMD_FIRST + 110)
const CMD_INSERTCHAR = (CMD_FIRST + 111)
const CMD_NEWLINE = (CMD_FIRST + 112)
const CMD_RECORDMACRO = (CMD_FIRST + 113)
const CMD_PLAYMACRO1 = (CMD_FIRST + 114)
const CMD_PLAYMACRO2 = (CMD_FIRST + 115)
const CMD_PLAYMACRO3 = (CMD_FIRST + 116)
const CMD_PLAYMACRO4 = (CMD_FIRST + 117)
const CMD_PLAYMACRO5 = (CMD_FIRST + 118)
const CMD_PLAYMACRO6 = (CMD_FIRST + 119)
const CMD_PLAYMACRO7 = (CMD_FIRST + 120)
const CMD_PLAYMACRO8 = (CMD_FIRST + 121)
const CMD_PLAYMACRO9 = (CMD_FIRST + 122)
const CMD_PLAYMACRO10 = (CMD_FIRST + 123)
const CMD_PROPERTIES = (CMD_FIRST + 124)
const CMD_BEGINUNDO = (CMD_FIRST + 125)
const CMD_ENDUNDO = (CMD_FIRST + 126)
const CMD_RESERVED3 = (CMD_FIRST + 127) '// internal use only

'// 2.0
const CMD_TOGGLEREGEXP = (CMD_FIRST + 128)
const CMD_CLEARSELECTION = (CMD_FIRST + 129)
const CMD_REGEXPON = (CMD_FIRST + 130)
const CMD_REGEXPOFF = (CMD_FIRST + 131)
const CMD_WHOLEWORDON = (CMD_FIRST + 132)
const CMD_WHOLEWORDOFF = (CMD_FIRST + 133)
const CMD_PRESERVECASEON = (CMD_FIRST + 134)
const CMD_PRESERVECASEOFF = (CMD_FIRST + 135)
const CMD_CASESENSITIVEON = (CMD_FIRST + 136)
const CMD_CASESENSITIVEOFF = (CMD_FIRST + 137)
const CMD_WHITESPACEDISPLAYON = (CMD_FIRST + 138)
const CMD_WHITESPACEDISPLAYOFF = (CMD_FIRST + 139)
const CMD_OVERTYPEON = (CMD_FIRST + 140)
const CMD_OVERTYPEOFF = (CMD_FIRST + 141)

'// 2.1
const CMD_CODELIST = (CMD_FIRST + 142)
const CMD_CODETIP = (CMD_FIRST + 143)
const CMD_LAST = (CMD_FIRST + 143)

'// all register commands must be at or higher than CMD_USER_BASE
const CMD_USER_BASE = (CMD_FIRST + 900)


const CMDERR_FAILURE = 1
const CMDERR_INPUT = 2
const CMDERR_SELECTION = 3
const CMDERR_NOTFOUND = 4
const CMDERR_EMPTYBUF = 5
const CMDERR_READONLY = 6


'-----------------------------------------------------------------------------|
' Language Support for CMM_SETLANGUAGE, RegisterLanguage(),                   |
' and UnregisterLanguage()                                                    |
'-----------------------------------------------------------------------------|

' stock languages
const CMLANG_CPP = "C/C++"
const CMLANG_PASCAL = "Pascal"
const CMLANG_BASIC = "Basic"
const CMLANG_SQL = "SQL"
const CMLANG_JAVA = "Java"
const CMLANG_HTML = "HTML"
const CMLANG_XML = "XML"

' language styles
const CMLS_PROCEDURAL = 0
const CMLS_SGML = 1

'-----------------------------------------------------------------------------|
' CM_LANGUAGE                                                                 |
'-----------------------------------------------------------------------------|
' The prefix "psz" means that the passed value is a pointer to a string       |
' The prefix "ch" means that the value is a pointer to a single-byte string   |
'-----------------------------------------------------------------------------|

type CM_LANGUAGE
    dwStyle as Dword
    bIsCaseSensitive as Bool
    pszKeywords as Long
    pszOperators as Long
    pszSingleLineComments as long
    pszMultiLineComments1 as long
    pszMultiLineComments2 as long
    pszScopeKeywords1 as long
    pszScopeKeywords2 as long
    pszStringDelims as long
    chEscape as long
    chTerminator as long
    pszTagElementNames as long
    pszTagAttributeNames as long
    pszTagEntities as long
End Type



'-----------------------------------------------------------------------------|
' CM_COLORS                                                                   |
'-----------------------------------------------------------------------------|
' Each property contains a RGB color value.                                   |
' Note: Use CLR_INVALID on background colors to specify transparent           |
' (text) or appropriate control panel setting                                 |
'-----------------------------------------------------------------------------|

Type CM_COLORS
     crWindow as Long
     crLeftMargin as Long
     crBookmark as Long
     crBookmarkBk as Long
     crText as Long
     crTextBk as Long
     crNumber as Long
     crNumberBk as Long
     crKeyword as Long
     crKeywordBk as Long
     crOperator as Long
     crOperatorBk as Long
     crScopeKeyword as Long
     crScopeKeywordBk as Long
     crComment as Long
     crCommentBk as Long
     crString as Long
     crStringBk as Long
     crTagText as Long
     crTagTextBk as Long
     crTagEntity as Long
     crTagEntityBk as Long
     crTagElementName as Long
     crTagElementNameBk as Long
     crTagAttributeName as Long
     crTagAttributeNameBk as Long
     crLineNumber as Long
     crLineNumberBk as Long
     crHDividerLines as Long
     crVDividerLines as Long
     crHighlightedLine as Long
End Type


'-----------------------------------------------------------------------------|
' CM_FONTSTYLES                                                               |
'-----------------------------------------------------------------------------|
' Font style settings for CMM_GETFONTSTYLES and CMM_SETFONTSTYLES             |
' each byte value is one of the CM_FONT_XXX values listed below               |
' this declaration                                                            |
'-----------------------------------------------------------------------------|

Type CM_FONTSTYLES
byText AS BYTE              ' plain text font style
byNumber AS BYTE            ' numeric literal font style
byKeyword AS BYTE           ' keyword font style
byOperator AS BYTE          ' operator font style
byScopeKeyword AS BYTE      ' scope keyword font style
byComment AS BYTE           ' comment font style
byString AS BYTE            ' string font style
byTagText AS BYTE           ' plain tag text font style
byTagEntity AS BYTE         ' tag entity font style
byTagElementName AS BYTE    ' tag element name font style
byTagAttributeName AS BYTE  ' tag attribute name font style
byLineNumber AS BYTE        ' line number font style
End Type

'-----------------------------------------------------------------------------|
' Font style options used in CM_FONTSTYLES                                    |
'-----------------------------------------------------------------------------|

const CM_FONT_NORMAL = 0
const CM_FONT_BOLD = 1
const CM_FONT_ITALIC = 2
const CM_FONT_BOLDITALIC = 3
const CM_FONT_UNDERLINE = 4

'-----------------------------------------------------------------------------|
' AutoIndent options                                                          |
'-----------------------------------------------------------------------------|

const CM_INDENT_OFF = 0
const CM_INDENT_SCOPE = 1
const CM_INDENT_PREVLINE = 2

'-----------------------------------------------------------------------------|
' Print option flags used with CMM_PRINT                                      |
'-----------------------------------------------------------------------------|

const CM_PRINT_PROMPTDLG = &H0
const CM_PRINT_DEFAULTPRN = &H1
const CM_PRINT_HDC = &H2
const CM_PRINT_RICHFONTS = &H4
const CM_PRINT_COLOR = &H8
const CM_PRINT_PAGENUMS = &H10
const CM_PRINT_DATETIME = &H20
const CM_PRINT_BORDERTHIN = &H40
const CM_PRINT_BORDERTHICK = &H80
const CM_PRINT_BORDERDOUBLE = &H100
const CM_PRINT_SELECTION = &H200


'-----------------------------------------------------------------------------|
' Border option flags used with CMM_GETBORDERSTYLE and CMM_SETBORDERSTYLE.    |
' Note: this values may be or'd together to achieve different effects.        |
'-----------------------------------------------------------------------------|

const CM_BORDER_NONE = &H0
const CM_BORDER_THIN = &H1
const CM_BORDER_CLIENT = &H2
const CM_BORDER_STATIC = &H4
const CM_BORDER_MODAL = &H8
const CM_BORDER_CORRAL = (CM_BORDER_MODAL OR CM_BORDER_CLIENT)


'-----------------------------------------------------------------------------|
' Text position indicators                                                    |
'-----------------------------------------------------------------------------|
'
'typedef struct _CM_POSITION {
'int nLine; ' zero-based line number
'int nCol; ' zero-based *buffer* column number
'} CM_POSITION;
'
'typedef struct _CM_RANGE {
'CM_POSITION posStart; ' the anchor
'CM_POSITION posEnd; ' the extension (if same as anchor, selection is empty)
'BOOL bColumnSel; ' TRUE if is a column selection, FALSE if paragragh selection
'} CM_RANGE;

'-----------------------------------------------------------------------------|
' Hot key descriptor                                                          |
'-----------------------------------------------------------------------------|

' typedef struct _CM_HOTKEY {
' BYTE byModifiers1; ' 1st keystroke's modifiers (combination of HOTKEYF_ALT, HOTKEYF_SHIFT, HOTKEYF_CONTROL)
' UINT nVirtKey1; ' 1st keystroke's virtkey (e.g. Ctrl + 'A')
' BYTE byModifiers2; ' 2nd keystroke's modifiers (combination of HOTKEYF_ALT, HOTKEYF_SHIFT, HOTKEYF_CONTROL)
' UINT nVirtKey2; ' 2nd keystroke's virtkey (e.g. Ctrl + 'A')
' } CM_HOTKEY;


'-----------------------------------------------------------------------------|
' CMN_DRAWLINE notification data passed to parent window                      |
'-----------------------------------------------------------------------------|

' typedef struct _CM_DRAWLINEDATA {
' NMHDR hdr; ' standard notification data
' HDC hDC; ' device context to draw with, clipped to current paint area
' RECT rcLine; ' bounds of line, excluding left margin region.
' int nLine; ' line number to draw
' int nLeftCol; ' leftmost visible col
' int nRightCol; ' rightmost visible col
' LPARAM lParam; ' itemdata associated with the line (CMM_SETITEMDATA)
' DWORD dwStyle; ' line style bits (CML_XXX)
' } CM_DRAWLINEDATA;

'-----------------------------------------------------------------------------|
' CMN_DELETELINE notification data passed to parent window                    |
'-----------------------------------------------------------------------------|

' typedef struct _CM_DELETELINEDATA {
' NMHDR hdr; ' standard notification data
' int nLine; ' line that is about to be deleted
' LPARAM lParam; ' itemdata associated with the line (CMM_SETITEMDATA)
' } CM_DELETELINEDATA;

'-----------------------------------------------------------------------------|
' CMN_CMDFAILURE notification data passed to parent window                    |
'-----------------------------------------------------------------------------|


' typedef struct _CM_CMDFAILUREDATA {
' NMHDR hdr; ' standard notification data
' WORD wCmd; ' CMD_XXX command that failed
' DWORD dwErr; ' CMDERR_XXX failure code
' } CM_CMDFAILUREDATA;

'-----------------------------------------------------------------------------|
' CMN_REGISTEREDCMD notification data passed to parent window                 |
'-----------------------------------------------------------------------------|

' typedef struct _CM_REGISTEREDCMDDATA {
' NMHDR hdr; ' standard notification data
' WORD wCmd; ' registered command to be executed
' } CM_REGISTEREDCMDDATA;

'-----------------------------------------------------------------------------|
' CMN_KEYDOWN, CMN_KEYUP, CMN_KEYPRESS notification                           |
' data passed to parent window                                                |
'-----------------------------------------------------------------------------|

' const CM_KEY_SHIFT = 0x1
' const CM_KEY_CTRL = 0x2
' const CM_KEY_ALT = 0x4
' typedef struct _CM_KEYDATA {
' NMHDR hdr; ' standard notification data
' int nKeyCode; ' virtkey if CMN_KEYUP or CMN_KEYDOWN. Ascii code if CMN_KEYPRESS
' int nKeyModifier; ' bitfield of: CM_KEY_SHIFT, CM_KEY_CTRL, and/or CM_KEY_ALT
' } CM_KEYDATA;

'-----------------------------------------------------------------------------|
' CMN_MOUSEDOWN, CMN_MOUSEUP, CMN_MOUSEPRESS notification                     |
' data passed to parent window                                                |
'-----------------------------------------------------------------------------|

' const CM_BTN_LEFT = 0x1
' const CM_BTN_RIGHT = 0x2
' const CM_BTN_MIDDLE = 0x4
' typedef struct _CM_MOUSEDATA {
' NMHDR hdr; ' standard notification data
' POINT pt; ' position of mouse (client coordinates)
' int nButton; ' bitfield of: CM_BTN_LEFT, CM_BTN_RIGHT, and/or CM_BTN_MIDDLE
' int nKeyModifier; ' bitfield of: CM_KEY_SHIFT, CM_KEY_CTRL, and/or CM_KEY_ALT
' } CM_MOUSEDATA;

'-----------------------------------------------------------------------------|
' CMN_FINDWRAPPED notification data passed to parent window                   |
'-----------------------------------------------------------------------------|

' typedef struct _CM_FINDWRAPPEDDATA {
' NMHDR hdr; ' standard notification data
' WORD wCmd; ' the command being executed
' BOOL bForward; ' TRUE if wrapped while searching forward, FALSE if searching backward
' } CM_FINDWRAPPEDDATA;
' 

'-----------------------------------------------------------------------------|
' CMN_CODELIST, CMN_CODELISTSELMADE, CMN_CODELISTCANCEL                       |
' notification data passed to parent window                                   |
'-----------------------------------------------------------------------------|

' typedef struct _CM_CODELISTDATA
' {
' NMHDR hdr; ' standard notification data
' HWND hListCtrl; ' handle to list view control window
' 
' } CM_CODELISTDATA, *LPCM_CODELISTDATA;


'-----------------------------------------------------------------------------|
' CMN_CODELISTCHAR notification data passed to parent window                  |
'-----------------------------------------------------------------------------|

' typedef struct _CM_CODELISTKEYDATA
' {
' CM_CODELISTDATA clData;
' WPARAM wChar; ' character code of key pressed
' LPARAM lKeyData; ' key data (repeat count, scan code, etc.)
' 
' } CM_CODELISTKEYDATA, *LPCM_CODELISTKEYDATA;


'-----------------------------------------------------------------------------|
' CMN_CODELISTSELWORD notification data passed to parent window               |
'-----------------------------------------------------------------------------|

' typedef struct _CM_CODELISTSELWORDDATA
' {
' CM_CODELISTDATA clData;
' int iItem; ' list item about to be selected
' 
' } CM_CODELISTSELWORDDATA, *LPCM_CODELISTSELWORDDATA;


'-----------------------------------------------------------------------------|
' CMN_CODELISTSELCHANGE notification data passed to parent window             |
'-----------------------------------------------------------------------------|

' typedef struct _CM_CODELISTSELCHANGEDATA
' {
' CM_CODELISTDATA clData;
' int iItem;
' LPTSTR pszText;
' TCHAR szText[CM_MAX_CODELIST_TIP];
' HINSTANCE hInstance;
' 
' } CM_CODELISTSELCHANGEDATA, *LPCM_CODELISTSELCHANGEDATA;


''''''''''''''''''''''''''''''/
'
' CMN_CODELISTHOTTRACK notification data passed to parent
' window
'
' typedef struct _CM_CODELISTHOTTRACKDATA
' {
' CM_CODELISTDATA clData;
' int iItem; ' index of the list item that is "hot"
' 
' } CM_CODELISTHOTTRACKDATA, *LPCM_CODELISTHOTTRACKDATA;
'
' 
' ''''''''''''''''''''''''''''''/
' '
' ' CMN_CODETIPCANCEL, CMN_CODETIPINITIALIZE,
' ' CMN_CODETIPUPDATE notification data passed to parent
' ' window
' '
' 
' ' Structure used if nTipType is set to CM_TIPSTYLE_NORMAL
' typedef struct _CM_CODETIPDATA
' {
' NMHDR hdr; ' standard notification data
' HWND hToolTip; ' handle to tooltip window
' UINT nTipType; ' type of tooltip in use
' 
' } CM_CODETIPDATA, *LPCM_CODETIPDATA;
' 
' ' Structure used if nTipType is set to CM_TIPSTYLE_HIGHLIGHT
' typedef struct _CM_CODETIPHIGHLIGHTDATA
' {
' CM_CODETIPDATA ctData;
' UINT nHighlightStartPos;
' UINT nHighlightEndPos;
' 
' } CM_CODETIPHIGHLIGHTDATA, *LPCM_CODETIPHIGHLIGHTDATA;
' 
' ' structure used if nTipType is set to CM_TIPSTYLE_FUNCHIGHLIGHT
' typedef struct _CM_CODETIPFUNCHIGHLIGHTDATA
' {
' CM_CODETIPDATA ctData;
' UINT nArgument;
' 
' } CM_CODETIPFUNCHIGHLIGHTDATA, *LPCM_CODETIPFUNCHIGHLIGHTDATA;
' 
' ' structure used if nTipType is set to CM_TIPSTYLE_MULTIFUNC
' typedef struct _CM_CODETIPMULTIFUNCDATA
' {
' CM_CODETIPFUNCHIGHLIGHTDATA ctfData;
' UINT nFuncCount;
' UINT nCurrFunc;
' 
' } CM_CODETIPMULTIFUNCDATA, *LPCM_CODETIPMULTIFUNCDATA;

'-----------------------------------------------------------------------------|
' Tooltip window styles specified as return value from                        |
' CMN_CODETIP notifications                                                   |
'-----------------------------------------------------------------------------|

const CM_TIPSTYLE_NONE = 0
const CM_TIPSTYLE_NORMAL = 1
const CM_TIPSTYLE_HIGHLIGHT = 2
const CM_TIPSTYLE_FUNCHIGHLIGHT = 3
const CM_TIPSTYLE_MULTIFUNC = 4


'-----------------------------------------------------------------------------|
' data passed to CMM_SETLINENUMBERING                                         |
'-----------------------------------------------------------------------------|

const CM_BINARY = 2
const CM_OCTAL = 8
const CM_DECIMAL = 10
const CM_HEXADECIMAL = 16

type CM_LINENUMBERING
    bEnabled as bool
    nStartAt as integer
    dwStyle as DWORD
End type

'-----------------------------------------------------------------------------|
' Error codes                                                                 |
'-----------------------------------------------------------------------------|

const CME_SUCCESS = 1
const CME_FAILURE = 0
const CME_BADARGUMENT = -1

'-----------------------------------------------------------------------------|
' CMM_HITTEST return codes                                                    |
'-----------------------------------------------------------------------------|

const CM_NOWHERE = 0
const CM_HSPLITTER = 1
const CM_VSPLITTER = 2
const CM_HVSPLITTER = 3
const CM_EDITSPACE = 4
const CM_HSCROLLBAR = 5
const CM_VSCROLLBAR = 6
const CM_SIZEBOX = 7
const CM_LEFTMARGIN = 8


'-----------------------------------------------------------------------------|
' CMM_GETCURRENTTOKEN return codes                                            |
'-----------------------------------------------------------------------------|

const CM_TOKENTYPE_KEYWORD = &H01
const CM_TOKENTYPE_OPERATOR = &H02
const CM_TOKENTYPE_STRING = &H03
const CM_TOKENTYPE_SINGLELINECOMMENT = &H04
const CM_TOKENTYPE_MULTILINECOMMENT = &H05
const CM_TOKENTYPE_NUMBER = &H06
const CM_TOKENTYPE_SCOPEBEGIN = &H07
const CM_TOKENTYPE_SCOPEEND = &H08
const CM_TOKENTYPE_TEXT = &Hff
const CM_TOKENTYPE_UNKNOWN AS DWORD = -1


'-----------------------------------------------------------------------------|
' Exported functions                                                          |
'-----------------------------------------------------------------------------|

const CM_VERSION = &H02100
  