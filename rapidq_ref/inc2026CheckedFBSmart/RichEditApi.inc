
'const WM_USER = &H400
'const CFM_BACKCOLOR = &H4000000
'const EM_SETCHARFORMAT = WM_USER + 68
'const EM_FORMATRANGE = WM_USER + 57
'const SCF_SELECTION = &H0001
; -------------------------- riched equates -------------------------------
const    ccTextLimitDefault        = &H32767

const    EM_CANPASTE                 =WM_USER + 50
const    EM_DISPLAYBAND              =WM_USER + 51
const    EM_EXGETSEL                 =WM_USER + 52
const    EM_EXLIMITTEXT              =WM_USER + 53
const    EM_EXLINEFROMCHAR           =WM_USER + 54
const    EM_EXSETSEL                 =WM_USER + 55
const    EM_FINDTEXT                 =WM_USER + 56
const    EM_FORMATRANGE              =WM_USER + 57
const    EM_GETCHARFORMAT            =WM_USER + 58
const    EM_GETEVENTMASK             =WM_USER + 59
const    EM_GETOLEINTERFACE          =WM_USER + 60
const    EM_GETPARAFORMAT            =WM_USER + 61
const    EM_GETSELTEXT               =WM_USER + 62
const    EM_HIDESELECTION            =WM_USER + 63
const    EM_PASTESPECIAL             =WM_USER + 64
const    EM_REQUESTRESIZE            =WM_USER + 65
const    EM_SELECTIONTYPE            =WM_USER + 66
const    EM_SETBKGNDCOLOR            =WM_USER + 67
const    EM_SETCHARFORMAT            =WM_USER + 68
const    EM_SETEVENTMASK             =WM_USER + 69
const    EM_SETOLECALLBACK           =WM_USER + 70
const    EM_SETPARAFORMAT            =WM_USER + 71
const    EM_SETTARGETDEVICE          =WM_USER + 72
const    EM_STREAMIN                 =WM_USER + 73
const    EM_STREAMOUT                =WM_USER + 74
const    EM_GETTEXTRANGE             =WM_USER + 75
const    EM_FINDWORDBREAK            =WM_USER + 76
const    EM_SETOPTIONS               =WM_USER + 77
const    EM_GETOPTIONS               =WM_USER + 78
const    EM_FINDTEXTEX               =WM_USER + 79
const    EM_GETWORDBREAKPROCEX       =WM_USER + 80
const    EM_SETWORDBREAKPROCEX       =WM_USER + 81
const    EM_SETUNDOLIMIT             =WM_USER + 82
const    EM_REDO                     =WM_USER + 84
const    EM_CANREDO                  =WM_USER + 85
const    EM_GETUNDONAME              =WM_USER + 86
const    EM_GETREDONAME              =WM_USER + 87
const    EM_STOPGROUPTYPING          =WM_USER + 88
const    EM_SETTEXTMODE              =WM_USER + 89
const    EM_GETTEXTMODE              =WM_USER + 90
const    EM_AUTOURLDETECT            =WM_USER + 91
const    EM_GETAUTOURLDETECT         =WM_USER + 92
const    EM_SETPALETTE               =WM_USER + 93
const    EM_GETTEXTEX                =WM_USER + 94
const    EM_GETTEXTLENGTHEX          =WM_USER + 95
const    EM_SHOWSCROLLBAR            =WM_USER + 96

const    EM_SETPUNCTUATION           =WM_USER + 100
const    EM_GETPUNCTUATION           =WM_USER + 101
const    EM_SETWORDWRAPMODE          =WM_USER + 102
const    EM_GETWORDWRAPMODE          =WM_USER + 103
const    EM_SETIMECOLOR              =WM_USER + 104
const    EM_GETIMECOLOR              =WM_USER + 105
const    EM_SETIMEOPTIONS            =WM_USER + 106
const    EM_GETIMEOPTIONS            =WM_USER + 107
const    EM_CONVPOSITION             =WM_USER + 108
const    EM_SETLANGOPTIONS           =WM_USER + 120
const    EM_GETLANGOPTIONS           =WM_USER + 121
const    EM_GETIMECOMPMODE           =WM_USER + 122
const    EM_FINDTEXTW                =WM_USER + 123
const    EM_FINDTEXTEXW              =WM_USER + 124
const    EM_RECONVERSION             =WM_USER + 125
const    EM_SETIMEMODEBIAS           =WM_USER + 126  
const    EM_GETIMEMODEBIAS           =WM_USER + 127
const    EM_SETBIDIOPTIONS           =WM_USER + 200
const    EM_GETBIDIOPTIONS           =WM_USER + 201
const    EM_SETTYPOGRAPHYOPTIONS     =WM_USER + 202
const    EM_GETTYPOGRAPHYOPTIONS     =WM_USER + 203
const    EM_SETEDITSTYLE             =WM_USER + 204
const    EM_GETEDITSTYLE             =WM_USER + 205

const    EM_OUTLINE                  =WM_USER + 220
const    EM_GETSCROLLPOS             =WM_USER + 221
const    EM_SETSCROLLPOS             =WM_USER + 222
const    EM_SETFONTSIZE              =WM_USER + 223
const    EM_GETZOOM                  =WM_USER + 224
const    EM_SETZOOM                  =WM_USER + 225

const    SES_EMULATESYSEDIT          =1
const    SES_BEEPONMAXTEXT           =2
const    SES_EXTENDBACKCOLOR         =4
const    SES_MAPCPS                  =8
const    SES_EMULATE10               =16
const    SES_USECRLF                 =32
const    SES_USEAIMM                 =64
const    SES_ALLOWBEEPS              =256

const    EN_MSGFILTER               = &H0700
const    EN_REQUESTRESIZE           = &H0701
const    EN_SELCHANGE               = &H0702
const    EN_DROPFILES               = &H0703
const    EN_PROTECTED               = &H0704
const    EN_CORRECTTEXT             = &H0705
const    EN_STOPNOUNDO              = &H0706
const    EN_IMECHANGE               = &H0707
const    EN_SAVECLIPBOARD           = &H0708
const    EN_OLEOPFAILED             = &H0709

const    ENM_NONE                   = &H00000000
const    ENM_CHANGE                 = &H00000001
const    ENM_UPDATE                 = &H00000002
const    ENM_SCROLL                 = &H00000004
const    ENM_KEYEVENTS              = &H00010000
const    ENM_MOUSEEVENTS            = &H00020000
const    ENM_REQUESTRESIZE          = &H00040000
const    ENM_SELCHANGE              = &H00080000
const    ENM_DROPFILES              = &H00100000
const    ENM_PROTECTED              = &H00200000
const    ENM_CORRECTTEXT            = &H00400000
const    ENM_IMECHANGE              = &H00800000
const    ES_SAVESEL                 = &H00008000
const    ES_SUNKEN                  = &H00004000
const    ES_DISABLENOSCROLL         = &H00002000
const    ES_SELECTIONBAR            = &H01000000
const    ES_EX_NOCALLOLEINIT        = &H01000000
const    ES_VERTICAL                = &H00400000
const    ES_NOIME                   = &H00080000
const    ES_SELFIME                 = &H00040000
const    ECO_AUTOWORDSELECTION      = &H00000001
const    ECO_AUTOVSCROLL            = &H00000040
const    ECO_AUTOHSCROLL            = &H00000080
const    ECO_NOHIDESEL              = &H00000100
const    ECO_READONLY               = &H00000800
const    ECO_WANTRETURN             = &H00001000
const    ECO_SAVESEL                = &H00008000
const    ECO_SELECTIONBAR           = &H01000000
const    ECO_VERTICAL               = &H00400000
const    ECOOP_SET                  = &H0001
const    ECOOP_OR                   = &H0002
const    ECOOP_AND                  = &H0003
const    ECOOP_XOR                  = &H0004
const    WB_CLASSIFY                 =3
const    WB_MOVEWORDLEFT             =4
const    WB_MOVEWORDRIGHT            =5
const    WB_LEFTBREAK                =6
const    WB_RIGHTBREAK               =7
const    WB_MOVEWORDPREV             =4
const    WB_MOVEWORDNEXT             =5
const    WB_PREVBREAK                =6
const    WB_NEXTBREAK                =7
const    PC_FOLLOWING                =1
const    PC_LEADING                  =2
const    PC_OVERFLOW                 =3
const    PC_DELIMITER                =4
const    WBF_WORDWRAP               = &H010
const    WBF_WORDBREAK              = &H020
const    WBF_OVERFLOW               = &H040
const    WBF_LEVEL1                 = &H080
const    WBF_LEVEL2                 = &H100
const    WBF_CUSTOM                 = &H200

const    IMF_FORCENONE                 = &H0001
const    IMF_FORCEENABLE               = &H0002
const    IMF_FORCEDISABLE              = &H0004
const    IMF_CLOSESTATUSWINDOW         = &H0008
const    IMF_VERTICAL  = &H0020
const    IMF_FORCEACTIVE               = &H0040
const    IMF_FORCEINACTIVE             = &H0080
const    IMF_FORCEREMEMBER             = &H0100
const    WBF_CLASS              = &H0F
const    WBF_ISWHITE            = &H10
const    WBF_BREAKLINE          = &H20
const    WBF_BREAKAFTER         = &H40

const    CFM_BOLD              = &H00000001
const    CFM_ITALIC            = &H00000002
const    CFM_UNDERLINE         = &H00000004
const    CFM_STRIKEOUT         = &H00000008
const    CFM_PROTECTED         = &H00000010
const    CFM_SIZE              = &H80000000
const    CFM_COLOR             = &H40000000
const    CFM_FACE              = &H20000000
const    CFM_OFFSET            = &H10000000
const    CFM_CHARSET           = &H08000000
const    CFE_BOLD              = &H0001
const    CFE_ITALIC            = &H0002
const    CFE_UNDERLINE         = &H0004
const    CFE_STRIKEOUT         = &H0008
const    CFE_PROTECTED         = &H0010
const    CFE_AUTOCOLOR         = &H40000000

const    yHeigtCarPtsMost         = &H1638

const    SCF_SELECTION         = &H0001
const    SCF_WORD              = &H0002

const    SF_TEXT              = &H0001
const    SF_RTF               = &H0002
const    SF_RTFNOOBJS         = &H0003
const    SF_TEXTIZED          = &H0004
const    SFF_SELECTION         = &H8000
const    SFF_PLAINRTF         = &H4000

const    MAX_TAB_STOPS          =32

const    lDefaultTab            =720

const    PFM_STARTINDENT            = &H00000001
const    PFM_RIGHTINDENT            = &H00000002
const    PFM_OFFSET = &H00000004
const    PFM_ALIGNMENT              = &H00000008
const    PFM_TABSTOPS               = &H00000010
const    PFM_NUMBERING              = &H00000020
const    PFM_OFFSETINDENT           = &H80000000

const    PFN_BULLET = &H0001

const    PFA_LEFT   = &H0001
const    PFA_RIGHT  = &H0002
const    PFA_CENTER = &H0003

const    SEL_EMPTY               = &H0000
const    SEL_TEXT= &H0001
const    SEL_OBJECT              = &H0002
const    SEL_MULTICHAR           = &H0004
const    SEL_MULTIOBJECT         = &H0008
const    OLEOP_DOVERB           =1
; -------------------------- riched structures -----------------------------
TYPE  CHARFORMATA 
  cbSize             AS  DWORD              
  dwMask             AS  DWORD              
  dwEffects          AS  DWORD              
  yHeight            AS  DWORD              
  yOffset            AS  DWORD              
  crTextColor        AS    AS   COLORREF         
  bCharSet           AS   AS  BYTE                   
  bPitchAndFamily    AS   AS  BYTE                   
  szFaceName         AS   AS  BYTE             LF_FACESIZE dup()
  _wPad2             AS  WORD                   
END TYPE
const    CHARFORMAT  = <CHARFORMATA>

TYPE  CHARRANGE 
  cpMin   AS  DWORD              
  cpMax   AS  DWORD              
END TYPE
TYPE  TEXTRANGEA 
  chrg          CHARRANGE <>
  lpstrText      AS  DWORD              
END TYPE
const    TEXTRANGE  = <TEXTRANGEA>

TYPE  EDITSTREAM 
  dwCookie       AS  DWORD              
  dwError        AS  DWORD              
  pfnCallback    AS  DWORD              
END TYPE
TYPE  FINDTEXTA 
  chrg          CHARRANGE  <>
  lpstrText      AS  DWORD              
END TYPE
const    FINDTEXT  = <FINDTEXTA>

TYPE  FINDTEXTEXA 
  chrg          CHARRANGE <>
  lpstrText      AS  DWORD              
  chrgText      CHARRANGE <>
END TYPE
const    FINDTEXTEX  = <FINDTEXTEXA>

TYPE  FORMATRANGE 
  hdc            AS  DWORD              
  hdcTarget      AS  DWORD              
  rc            RECT <>
  rcPage        RECT <>
  chrg          CHARRANGE <>
END TYPE
TYPE  PARAFORMAT 
  cbSize             AS  DWORD             
  dwMask             AS  DWORD             
  wNumbering         AS  WORD                  
  wEffects           AS  WORD                  
  dxStartIndent      AS  DWORD             
  dxRightIndent      AS  DWORD             
  dxOffset           AS  DWORD             
  wAlignment         AS  WORD                  
  cTabCount          AS  WORD                  
  rgxTabs            AS  DWORD         MAX_TAB_STOPS dup()
END TYPE
TYPE  PARAFORMAT2 
  cbSize             AS  DWORD            
  dwMask             AS  DWORD            
  wNumbering         AS  WORD                 
  wEffects           AS  WORD                 
  dxStartIndent      AS  DWORD            
  dxRightIndent      AS  DWORD            
  dxOffset           AS  DWORD            
  wAlignment         AS  WORD                 
  cTabCount          AS  WORD                 
  rgxTabs            AS  DWORD         MAX_TAB_STOPS dup()
  dySpaceBefore      AS  DWORD            
  dySpaceAfter       AS  DWORD            
  dyLineSpacing      AS  DWORD            
  sStyle             AS  WORD                 
  bLineSpacingRule   AS   AS  BYTE                 
  bOutlineLevel      AS   AS  BYTE                 
  wShadingWeight     AS  WORD                 
  wShadingStyle      AS  WORD                 
  wNumberingStart    AS  WORD                 
  wNumberingStyle    AS  WORD                 
  wNumberingTab      AS  WORD                 
  wBorderSpace       AS  WORD                 
  wBorderWidth       AS  WORD                 
  wBorders           AS  WORD                 
END TYPE
TYPE  MSGFILTER 
  nmhdr     NMHDR <>
  msg        AS  DWORD              
  wParam     AS  DWORD              
  lParam     AS  DWORD              
END TYPE
TYPE  REQRESIZE 
  nmhdr  NMHDR <>
  rc     RECT <>
END TYPE
TYPE  SELCHANGE 
  nmhdr     NMHDR <>
  chrg      CHARRANGE <>
  seltyp     AS  WORD                  
END TYPE
TYPE  ENDROPFILES 
  nmhdr         NMHDR <>
  hDrop          AS  DWORD              
  cp             AS  DWORD              
  fProtected     AS  DWORD              
END TYPE
TYPE  ENPROTECTED 
  nmhdr     NMHDR <>
  msg        AS  DWORD              
  wPad1      AS  DWORD         
  wParam     AS  DWORD              
  wPad2      AS  DWORD         
  lParam     AS  DWORD              
  chrg      CHARRANGE <>
END TYPE
TYPE  ENSAVECLIPBOARD 
  nmhdr         NMHDR <>
  cObjectCount   AS  DWORD              
  cch            AS  DWORD              
END TYPE
TYPE  ENOLEOPFAILED 
  nmhdr     NMHDR <>
  iob        AS  DWORD              
  lOper      AS  DWORD              
  hr         AS  DWORD              
END TYPE
TYPE  ENCORRECTTEXT 
  nmhdr     NMHDR <>
  chrg      CHARRANGE <>
  seltyp     AS  WORD                  
END TYPE
TYPE  PUNCTUATION 
  iSize          AS  DWORD              
  szPunctuation  AS  DWORD              
END TYPE
TYPE  COMPCOLOR 
  crText         AS  DWORD              
  crBackground   AS  DWORD              
  dwEffects      AS  DWORD              
END TYPE
TYPE  REPASTESPECIAL 
  dwAspect   AS  DWORD              
  dwParam    AS  DWORD              
END TYPE
  
;========================[ RichEdit v3 by Ewayne '==============================
CFM_BACKCOLOR           equ 4000000h
CFM_LCID                equ 2000000h
CFM_UNDERLINETYPE       equ 800000h
CFM_WEIGHT              equ 400000h
CFM_SPACING             equ 200000h
CFM_KERNING             equ 100000h
CFM_STYLE               equ 80000h
CFM_ANIMATION           equ 40000h
CFM_REVAUTHOR           equ 8000h
CFM_SMALLCAPS           equ 40h
CFM_ALLCAPS             equ 80h
CFM_HIDDEN              equ 100h
CFM_OUTLINE             equ 200h
CFM_SHADOW              equ 400h
CFM_EMBOSS              equ 800h
CFM_IMPRINT             equ 1000h
CFM_DISABLED            equ 2000h
CFM_REVISED             equ 4000h
SCF_DEFAULT             equ 0
SCF_SELECTION           equ 1
SCF_WORD                equ 2
SCF_ALL                 equ 4
SCF_SCF_USEUIRULES      equ 8
CFU_CF1UNDERLINE        equ 0ffh
CFU_INVERT              equ 0feh
CFU_UNDERLINEHAIRLINE   equ 10
CFU_UNDERLINETHICK      equ 9
CFU_UNDERLINEWAVE       equ 8
CFU_UNDERLINEDASHDOTDOT equ 7
CFU_UNDERLINEDASHDOT    equ 6
CFU_UNDERLINEDASH       equ 5
CFU_UNDERLINEDOTTED     equ 4
CFU_UNDERLINEDOUBLE     equ 3
CFU_UNDERLINEWORD       equ 2
CFU_UNDERLINE           equ 1
CFU_UNDERLINENONE       equ 0

PFM_SPACEBEFORE         equ 40h
PFM_SPACEAFTER          equ 80h
PFM_LINESPACING         equ 100h
PFM_STYLE               equ 400h
PFM_BORDER              equ 800h
PFM_SHADING             equ 1000h
PFM_NUMBERINGSTYLE      equ 2000h
PFM_NUMBERINGTAB        equ 4000h
PFM_NUMBERINGSTART      equ 8000h
PFM_RTLPARA             equ 10000h
PFM_KEEP                equ 20000h
PFM_KEEPNEXT            equ 40000h
PFM_PAGEBREAKBEFORE     equ 80000h
PFM_NOLINENUMBER        equ 100000h
PFM_NOWIDOWCONTROL      equ 200000h
PFM_DONOTHYPHEN         equ 400000h
PFM_SIDEBYSIDE          equ 800000h
PFM_TABLE               equ 40000000h
PFM_COLLAPSED           equ 1000000h
PFM_OUTLINELEVEL        equ 2000000h
PFM_BOX                 equ 4000000h

CHARFORMAT2 STRUCT
  cbSize            DWORD      ?
  dwMask            DWORD      ?
  dwEffects         DWORD      ?
  yHeight           DWORD      ?
  yOffset           DWORD      ?
  crTextColor       DWORD      ?
  bCharSet          BYTE       ?
  bPitchAndFamily   BYTE       ?
  szFaceName        BYTE LF_FACESIZE dup(?)
  _wPad2            WORD       ?
  wWeight           WORD       ?
  sSpacing          WORD       ?
  crBackColor       DWORD      ?
  lcid              DWORD      ?
  dwReserved        DWORD      ?
  sStyle            WORD       ?
  wKerning          WORD       ?
  bUnderlineType    BYTE       ?
  bAnimation        BYTE       ? 
  bRevAuthor        BYTE       ?
  bReserved1        BYTE       ?
CHARFORMAT2 ENDS
   