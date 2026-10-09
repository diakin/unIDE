' /****************************************************************************
' *                                                                           *
' * HtmlHelp.h                                                                *
' *                                                                           *
' * Copyright (c) 1996-1997, Microsoft Corp. All rights reserved.             *
' *                                                                           *
' ****************************************************************************/
' converted for RapidQ

$IFNDEF HTMLHELP_INC
$DEFINE HTMLHELP_INC

' Commands to pass to HtmlHelp()

$DEFINE HH_DISPLAY_TOPIC        &h0000
$DEFINE HH_HELP_FINDER          &h0000  ' WinHelp equivalent
$DEFINE HH_DISPLAY_TOC          &h0001  
$DEFINE HH_DISPLAY_INDEX        &h0002  
$DEFINE HH_DISPLAY_SEARCH       &h0003  
$DEFINE HH_SET_WIN_TYPE         &h0004
$DEFINE HH_GET_WIN_TYPE         &h0005
$DEFINE HH_GET_WIN_HANDLE       &h0006
$DEFINE HH_ENUM_INFO_TYPE       &h0007  ' Get Info type name, call repeatedly to enumerate, -1 at end
$DEFINE HH_SET_INFO_TYPE        &h0008  ' Add Info type to filter.
$DEFINE HH_SYNC                 &h0009
$DEFINE HH_RESERVED1            &h000A
$DEFINE HH_RESERVED2            &h000B
$DEFINE HH_RESERVED3            &h000C
$DEFINE HH_KEYWORD_LOOKUP       &h000D
$DEFINE HH_DISPLAY_TEXT_POPUP   &h000E  ' display string resource id or text in a popup window
$DEFINE HH_HELP_CONTEXT         &h000F  ' display mapped numeric value in dwData
$DEFINE HH_TP_HELP_CONTEXTMENU  &h0010  ' text popup help, same as WinHelp HELP_CONTEXTMENU
$DEFINE HH_TP_HELP_WM_HELP      &h0011  ' text popup help, same as WinHelp HELP_WM_HELP
$DEFINE HH_CLOSE_ALL            &h0012  ' close all windows opened directly or indirectly by the caller
$DEFINE HH_ALINK_LOOKUP         &h0013  ' ALink version of HH_KEYWORD_LOOKUP
$DEFINE HH_GET_LAST_ERROR       &h0014  ' not currently implemented ' See HHERROR.h
$DEFINE HH_ENUM_CATEGORY        &h0015	' Get category name, call repeatedly to enumerate, -1 at end
$DEFINE HH_ENUM_CATEGORY_IT     &h0016  ' Get category info type members, call repeatedly to enumerate, -1 at end
$DEFINE HH_RESET_IT_FILTER      &h0017  ' Clear the info type filter of all info types.
$DEFINE HH_SET_INCLUSIVE_FILTER &h0018  ' set inclusive filtering method for untyped topics to be included in display
$DEFINE HH_SET_EXCLUSIVE_FILTER &h0019  ' set exclusive filtering method for untyped topics to be excluded from display
$DEFINE HH_INITIALIZE            &h001C  ' Initializes the help system.
$DEFINE HH_UNINITIALIZE          &h001D  ' Uninitializes the help system.
$DEFINE HH_PRETRANSLATEMESSAGE  &h00fd  ' Pumps messages. (NULL, NULL, MSG*). 
$DEFINE HH_SET_GLOBAL_PROPERTY  &h00fc  ' Set a global property. (NULL, NULL, HH_GPROP)

$DEFINE HHWIN_PROP_TAB_AUTOHIDESHOW 1    ' Automatically hide/show tri-pane window
$DEFINE HHWIN_PROP_ONTOP            2    ' Top-most window
$DEFINE HHWIN_PROP_NOTITLEBAR       4    ' no title bar
$DEFINE HHWIN_PROP_NODEF_STYLES     8    ' no default window styles (only HH_WINTYPE.dwStyles)
'etc...
'$DEFINE HHWIN_PROP_NODEF_EXSTYLES   (1 << 4)    ' no default extended window styles (only HH_WINTYPE.dwExStyles)
'$DEFINE HHWIN_PROP_TRI_PANE         (1 << 5)    ' use a tri-pane window
'$DEFINE HHWIN_PROP_NOTB_TEXT        (1 << 6)    ' no text on toolbar buttons
'$DEFINE HHWIN_PROP_POST_QUIT        (1 << 7)    ' post WM_QUIT message when window closes
'$DEFINE HHWIN_PROP_AUTO_SYNC        (1 << 8)    ' automatically ssync contents and index
'$DEFINE HHWIN_PROP_TRACKING         (1 << 9)    ' send tracking notification messages
'$DEFINE HHWIN_PROP_TAB_SEARCH       (1 << 10)   ' include search tab in navigation pane
'$DEFINE HHWIN_PROP_TAB_HISTORY      (1 << 11)   ' include history tab in navigation pane
'$DEFINE HHWIN_PROP_TAB_FAVORITES    (1 << 12)   ' include favorites tab in navigation pane
'$DEFINE HHWIN_PROP_CHANGE_TITLE     (1 << 13)   ' Put current HTML title in title bar
'$DEFINE HHWIN_PROP_NAV_ONLY_WIN     (1 << 14)   ' Only display the navigation window
'$DEFINE HHWIN_PROP_NO_TOOLBAR       (1 << 15)   ' Don't display a toolbar
'$DEFINE HHWIN_PROP_MENU             (1 << 16)   ' Menu
'$DEFINE HHWIN_PROP_TAB_ADVSEARCH    (1 << 17)   ' Advanced FTS UI.
'$DEFINE HHWIN_PROP_USER_POS         (1 << 18)   ' After initial creation, user controls window size/position
'$DEFINE HHWIN_PROP_TAB_CUSTOM1      (1 << 19)   ' Use custom tab #1
'$DEFINE HHWIN_PROP_TAB_CUSTOM2      (1 << 20)   ' Use custom tab #2
'$DEFINE HHWIN_PROP_TAB_CUSTOM3      (1 << 21)   ' Use custom tab #3
'$DEFINE HHWIN_PROP_TAB_CUSTOM4      (1 << 22)   ' Use custom tab #4
'$DEFINE HHWIN_PROP_TAB_CUSTOM5      (1 << 23)   ' Use custom tab #5
'$DEFINE HHWIN_PROP_TAB_CUSTOM6      (1 << 24)   ' Use custom tab #6
'$DEFINE HHWIN_PROP_TAB_CUSTOM7      (1 << 25)   ' Use custom tab #7
'$DEFINE HHWIN_PROP_TAB_CUSTOM8      (1 << 26)   ' Use custom tab #8
'$DEFINE HHWIN_PROP_TAB_CUSTOM9      (1 << 27)   ' Use custom tab #9
'$DEFINE HHWIN_TB_MARGIN             (1 << 28)   ' the window type has a margin
'
'$DEFINE HHWIN_PARAM_PROPERTIES      (1 << 1)    ' valid fsWinProperties
'$DEFINE HHWIN_PARAM_STYLES          (1 << 2)    ' valid dwStyles
'$DEFINE HHWIN_PARAM_EXSTYLES        (1 << 3)    ' valid dwExStyles
'$DEFINE HHWIN_PARAM_RECT            (1 << 4)    ' valid rcWindowPos
'$DEFINE HHWIN_PARAM_NAV_WIDTH       (1 << 5)    ' valid iNavWidth
'$DEFINE HHWIN_PARAM_SHOWSTATE       (1 << 6)    ' valid nShowState
'$DEFINE HHWIN_PARAM_INFOTYPES       (1 << 7)    ' valid apInfoTypes
'$DEFINE HHWIN_PARAM_TB_FLAGS        (1 << 8)    ' valid fsToolBarFlags
'$DEFINE HHWIN_PARAM_EXPANSION       (1 << 9)    ' valid fNotExpanded
'$DEFINE HHWIN_PARAM_TABPOS          (1 << 10)   ' valid tabpos
'$DEFINE HHWIN_PARAM_TABORDER        (1 << 11)   ' valid taborder
'$DEFINE HHWIN_PARAM_HISTORY_COUNT   (1 << 12)   ' valid cHistory
'$DEFINE HHWIN_PARAM_CUR_TAB         (1 << 13)   ' valid curNavType
'
'$DEFINE HHWIN_BUTTON_EXPAND         (1 << 1)    ' Expand/contract button
'$DEFINE HHWIN_BUTTON_BACK           (1 << 2)    ' Back button
'$DEFINE HHWIN_BUTTON_FORWARD        (1 << 3)    ' Forward button
'$DEFINE HHWIN_BUTTON_STOP           (1 << 4)    ' Stop button
'$DEFINE HHWIN_BUTTON_REFRESH        (1 << 5)    ' Refresh button
'$DEFINE HHWIN_BUTTON_HOME           (1 << 6)    ' Home button
'$DEFINE HHWIN_BUTTON_BROWSE_FWD     (1 << 7)    ' not implemented
'$DEFINE HHWIN_BUTTON_BROWSE_BCK     (1 << 8)    ' not implemented
'$DEFINE HHWIN_BUTTON_NOTES          (1 << 9)    ' not implemented
'$DEFINE HHWIN_BUTTON_CONTENTS       (1 << 10)   ' not implemented
'$DEFINE HHWIN_BUTTON_SYNC           (1 << 11)   ' Sync button
'$DEFINE HHWIN_BUTTON_OPTIONS        (1 << 12)   ' Options button
'$DEFINE HHWIN_BUTTON_PRINT          (1 << 13)   ' Print button
'$DEFINE HHWIN_BUTTON_INDEX          (1 << 14)   ' not implemented
'$DEFINE HHWIN_BUTTON_SEARCH         (1 << 15)   ' not implemented
'$DEFINE HHWIN_BUTTON_HISTORY        (1 << 16)   ' not implemented
'$DEFINE HHWIN_BUTTON_FAVORITES      (1 << 17)   ' not implemented
'$DEFINE HHWIN_BUTTON_JUMP1          (1 << 18)
'$DEFINE HHWIN_BUTTON_JUMP2          (1 << 19)
'$DEFINE HHWIN_BUTTON_ZOOM           (1 << 20)
'$DEFINE HHWIN_BUTTON_TOC_NEXT       (1 << 21)
'$DEFINE HHWIN_BUTTON_TOC_PREV       (1 << 22)

' Button IDs

$DEFINE IDTB_EXPAND             200
$DEFINE IDTB_CONTRACT           201
$DEFINE IDTB_STOP               202
$DEFINE IDTB_REFRESH            203
$DEFINE IDTB_BACK               204
$DEFINE IDTB_HOME               205
$DEFINE IDTB_SYNC               206
$DEFINE IDTB_PRINT              207
$DEFINE IDTB_OPTIONS            208
$DEFINE IDTB_FORWARD            209
$DEFINE IDTB_NOTES              210 ' not implemented
$DEFINE IDTB_BROWSE_FWD         211
$DEFINE IDTB_BROWSE_BACK        212
$DEFINE IDTB_CONTENTS           213 ' not implemented
$DEFINE IDTB_INDEX              214 ' not implemented
$DEFINE IDTB_SEARCH             215 ' not implemented
$DEFINE IDTB_HISTORY            216 ' not implemented
$DEFINE IDTB_FAVORITES          217 ' not implemented
$DEFINE IDTB_JUMP1              218
$DEFINE IDTB_JUMP2              219
$DEFINE IDTB_CUSTOMIZE          221
$DEFINE IDTB_ZOOM               222
$DEFINE IDTB_TOC_NEXT           223
$DEFINE IDTB_TOC_PREV           224

' Notification codes

'$DEFINE HHN_FIRST       -860U
'$DEFINE HHN_LAST        0U-879U

'$DEFINE HHN_NAVCOMPLETE   (HHN_FIRST-0)
'$DEFINE HHN_TRACK         (HHN_FIRST-1)
'$DEFINE HHN_WINDOW_CREATE (HHN_FIRST-2)

' typedef struct tagHHN_NOTIFY
' {
'     NMHDR   hdr;
'     PCSTR   pszUrl; ' Multi-byte, null-terminated string
' } HHN_NOTIFY;

' TYPE HH_POPUP
'     cbStruct   AS         INTEGER       ' sizeof this structure
'     hinst   AS            LONG   ' instance handle for string resource
'     idString   AS         LONG      ' string resource id, or text id if pszFile is specified in HtmlHelp call
'     pszText   AS          LONG   ' used if idString is zero
'     pt_x   AS               INTEGER     ' top center of popup window POINT
'     pt_y   AS               INTEGER     ' top center of popup window
'     clrForeground   AS    INTEGER  ' use -1 for default
'     clrBackground   AS    INTEGER  ' use -1 for default
' '    rcMargins   AS        RECT      ' amount of space between edges of window and text, -1 for each member to ignore
'     rcMarginsTop   AS        INTEGER      ' amount of space between edges of window and text, -1 for each member to ignore
'     rcMarginsLeft   AS        INTEGER      ' amount of space between edges of window and text, -1 for each member to ignore
'     rcMarginsBottom   AS        INTEGER      ' amount of space between edges of window and text, -1 for each member to ignore
'     rcMarginsRight   AS        INTEGER      ' amount of space between edges of window and text, -1 for each member to ignore
'     pszFont   AS          LONG   ' facename, point size, char set, BOLD ITALIC UNDERLINE
' END TYPE

TYPE HH_AKLINK
    cbStruct        AS INTEGER        ' sizeof this structure
    fReserved       AS INTEGER       ' must be FALSE (really!)
    pszKeywords     AS LONG          ' semi-colon separated keywords
    pszUrl          AS LONG          ' URL to jump to if no keywords found (may be NULL)
    pszMsgText      AS LONG          ' Message text to display in MessageBox if pszUrl is NULL and no keyword match
    pszMsgTitle     AS LONG          ' Message text to display in MessageBox if pszUrl is NULL and no keyword match
    pszWindow       AS LONG          ' Window to display URL in
    fIndexOnFail    AS LONG          ' Displays index if keyword lookup fails.
END TYPE
' 
' $DEFINE HHWIN_NAVTYPE_TOC           0
' $DEFINE HHWIN_NAVTYPE_INDEX         1
' $DEFINE HHWIN_NAVTYPE_SEARCH        2
' $DEFINE HHWIN_NAVTYPE_FAVORITES     3
' $DEFINE HHWIN_NAVTYPE_HISTORY       4' not implemented
' $DEFINE HHWIN_NAVTYPE_AUTHOR        5
' $DEFINE HHWIN_NAVTYPE_CUSTOM_FIRST  11
' '
' 'enum {
' '    IT_INCLUSIVE,
' '    IT_EXCLUSIVE,
' '    IT_HIDDEN,
' '};
' '
' 'typedef struct tagHH_ENUM_IT
' '{
' '    int       cbStruct;          ' size of this structure
' '    int       iType;             ' the type of the information type ie. Inclusive, Exclusive, or Hidden
' '    LPCSTR    pszCatName;        ' Set to the name of the Category to enumerate the info types in a category; else NULL
' '    LPCSTR    pszITName;         ' volitile pointer to the name of the infotype. Allocated by call. Caller responsible for freeing
' '    LPCSTR    pszITDescription;  ' volitile pointer to the description of the infotype.
' '} HH_ENUM_IT, *PHH_ENUM_IT;
' '
' 'typedef struct tagHH_ENUM_CAT
' '{
' '    int       cbStruct;          ' size of this structure
' '    LPCSTR    pszCatName;        ' volitile pointer to the category name
' '    LPCSTR    pszCatDescription; ' volitile pointer to the category description
' '} HH_ENUM_CAT, *PHH_ENUM_CAT;
' '
' 'typedef struct tagHH_SET_INFOTYPE
' '{
' '    int       cbStruct;          ' the size of this structure
' '    LPCSTR    pszCatName;        ' the name of the category, if any, the InfoType is a member of.
' '    LPCSTR    pszInfoTypeName;   ' the name of the info type to add to the filter
' '} HH_SET_INFOTYPE, *PHH_SET_INFOTYPE;
' '
' 'typedef DWORD HH_INFOTYPE;
' 'typedef HH_INFOTYPE* PHH_INFOTYPE;
' '
' 'enum {
' '    HHWIN_NAVTAB_TOP,
' '    HHWIN_NAVTAB_LEFT,
' '    HHWIN_NAVTAB_BOTTOM,
' '};
' 
' $DEFINE HH_MAX_TABS 19  ' maximum number of tabs
' 
' 
' $DEFINE HH_TAB_CONTENTS     0
' $DEFINE HH_TAB_INDEX        1
' $DEFINE HH_TAB_SEARCH       2
' $DEFINE HH_TAB_FAVORITES    3
' $DEFINE HH_TAB_HISTORY      4
' $DEFINE HH_TAB_AUTHOR       5
' $DEFINE HH_TAB_CUSTOM_FIRST 11 
' $DEFINE HH_TAB_CUSTOM_LAST = 19
' $DEFINE HH_MAX_TABS_CUSTOM 9
' 
' ' HH_DISPLAY_SEARCH Command Related Structures and Constants
' 
' '$DEFINE HH_FTS_DEFAULT_PROXIMITY (-1)
' 
 TYPE HH_FTS_QUERY
     cbStruct             AS INTEGER        ' Sizeof structure in bytes.
     fUniCodeStrings      AS INTEGER       ' TRUE if all strings are unicode.
     pszSearchQuery       AS LONG        ' String containing the search query.
     iProximity           AS LONG       ' Word proximity.
     fStemmedSearch       AS INTEGER       ' TRUE for StemmedSearch only.
     fTitleOnly           AS INTEGER       ' TRUE for Title search only.
     fExecute             AS INTEGER       ' TRUE to initiate the search.
     pszWindow            AS LONG        ' Window to display in
 END TYPE

' 
' ' HH_WINTYPE Structure
' ' typedef struct tagHH_WINTYPE {
' '     int     cbStruct;        ' IN: size of this structure including all Information Types
' '     BOOL    fUniCodeStrings; ' IN/OUT: TRUE if all strings are in UNICODE
' '     LPCTSTR pszType;         ' IN/OUT: Name of a type of window
' '     DWORD   fsValidMembers;  ' IN: Bit flag of valid members (HHWIN_PARAM_)
' '     DWORD   fsWinProperties; ' IN/OUT: Properties/attributes of the window (HHWIN_)
' ' 
' '     LPCTSTR pszCaption;      ' IN/OUT: Window title
' '     DWORD   dwStyles;        ' IN/OUT: Window styles
' '     DWORD   dwExStyles;      ' IN/OUT: Extended Window styles
' '     RECT    rcWindowPos;     ' IN: Starting position, OUT: current position
' '     int     nShowState;      ' IN: show state (e.g., SW_SHOW)
' ' 
' '     HWND  hwndHelp;          ' OUT: window handle
' '     HWND  hwndCaller;        ' OUT: who called this window
' ' 
' '     HH_INFOTYPE* paInfoTypes;  ' IN: Pointer to an array of Information Types
' ' 
' '     ' The following members are only valid if HHWIN_PROP_TRI_PANE is set
' ' 
' '     HWND  hwndToolBar;      ' OUT: toolbar window in tri-pane window
' '     HWND  hwndNavigation;   ' OUT: navigation window in tri-pane window
' '     HWND  hwndHTML;         ' OUT: window displaying HTML in tri-pane window
' '     int   iNavWidth;        ' IN/OUT: width of navigation window
' '     RECT  rcHTML;           ' OUT: HTML window coordinates
' ' 
' '     LPCTSTR pszToc;         ' IN: Location of the table of contents file
' '     LPCTSTR pszIndex;       ' IN: Location of the index file
' '     LPCTSTR pszFile;        ' IN: Default location of the html file
' '     LPCTSTR pszHome;        ' IN/OUT: html file to display when Home button is clicked
' '     DWORD   fsToolBarFlags; ' IN: flags controling the appearance of the toolbar
' '     BOOL    fNotExpanded;   ' IN: TRUE/FALSE to contract or expand, OUT: current state
' '     int     curNavType;     ' IN/OUT: UI to display in the navigational pane
' '     int     tabpos;         ' IN/OUT: HHWIN_NAVTAB_TOP, HHWIN_NAVTAB_LEFT, or HHWIN_NAVTAB_BOTTOM
' '     int     idNotify;       ' IN: ID to use for WM_NOTIFY messages
' '     BYTE    tabOrder[HH_MAX_TABS + 1];    ' IN/OUT: tab order: Contents, Index, Search, History, Favorites, Reserved 1-5, Custom tabs
' '     int     cHistory;       ' IN/OUT: number of history items to keep (default is 30)
' '     LPCTSTR pszJump1;       ' Text for HHWIN_BUTTON_JUMP1
' '     LPCTSTR pszJump2;       ' Text for HHWIN_BUTTON_JUMP2
' '     LPCTSTR pszUrlJump1;    ' URL for HHWIN_BUTTON_JUMP1
' '     LPCTSTR pszUrlJump2;    ' URL for HHWIN_BUTTON_JUMP2
' '     RECT    rcMinSize;      ' Minimum size for window (ignored in version 1)
' '     int     cbInfoTypes;    ' size of paInfoTypes;
' '     LPCTSTR pszCustomTabs;  ' multiple zero-terminated strings
' ' } HH_WINTYPE, *PHH_WINTYPE;
' 
' $DEFINE HHACT_TAB_CONTENTS 0
' $DEFINE HHACT_TAB_INDEX 1
' $DEFINE HHACT_TAB_SEARCH 2
' $DEFINE HHACT_TAB_HISTORY 3
' $DEFINE HHACT_TAB_FAVORITES 4 
' 
' $DEFINE HHACT_EXPAND 5
' $DEFINE HHACT_CONTRACT 6
' $DEFINE HHACT_BACK 7
' $DEFINE HHACT_FORWARD 8
' $DEFINE HHACT_STOP 9
' $DEFINE HHACT_REFRESH 10
' $DEFINE HHACT_HOME 11
' $DEFINE HHACT_SYNC 12
' $DEFINE HHACT_OPTIONS 13
' $DEFINE HHACT_PRINT 14
' $DEFINE HHACT_HIGHLIGHT 15
' $DEFINE HHACT_CUSTOMIZE 16
' $DEFINE HHACT_JUMP1 17
' $DEFINE HHACT_JUMP2 18
' $DEFINE HHACT_ZOOM 19
' $DEFINE HHACT_TOC_NEXT 20
' $DEFINE HHACT_TOC_PREV 21
' $DEFINE HHACT_NOTES 22
' $DEFINE HHACT_LAST_ENUM 23
' 
' '
' 'typedef struct tagHHNTRACK
' '{
' '    NMHDR   hdr;
' '    PCSTR   pszCurUrl;      ' Multi-byte, null-terminated string
' '    int     idAction;       ' HHACT_ value
' '    HH_WINTYPE* phhWinType; ' Current window type structure
' '} HHNTRACK;
' '
' 'HWND
' 'WINAPI
' 'HtmlHelpA(
' '    HWND hwndCaller,
' '    LPCSTR pszFile,
' '    UINT uCommand,
' '    DWORD_PTR dwData
' '    );
' '
' 'HWND
' 'WINAPI
' 'HtmlHelpW(
' '    HWND hwndCaller,
' '    LPCWSTR pszFile,
' '    UINT uCommand,
' '    DWORD_PTR dwData
' '    );
' 
' 
' '''''''''''''''''''''''''''''''''''''''/
' '
' ' Global Control Properties. 
' '
' 'typedef enum tagHH_GPROPID
' '{
' '    HH_GPROPID_SINGLETHREAD=1,      ' VARIANT_BOOL: True for single thread
' '    HH_GPROPID_TOOLBAR_MARGIN=2,    ' long: Provides a left/right margin around the toolbar.
' '    HH_GPROPID_UI_LANGUAGE=3,       ' long: LangId of the UI.
' '    HH_GPROPID_CURRENT_SUBSET=4,    ' BSTR: Current subset.
' '    HH_GPROPID_CONTENT_LANGUAGE=5   ' long: LandId for desired content.
' '} HH_GPROPID;
' 
' '''''''''''''''''''''''''''''''''''''''/
' '
' ' Global Property structure
' 
' 'typedef struct tagHH_GLOBAL_PROPERTY
' '{
' '    HH_GPROPID  id;
' '    VARIANT     var;
' '} HH_GLOBAL_PROPERTY ;


Declare Function HtmlHelp Lib "hhctrl.ocx" Alias "HtmlHelpA" _
       (hwndCaller As Long, _
        pszFile As String, _
        uCommand As Long, _
        dwData As Long) As Long

Declare Function htmlHelpString Lib "hhctrl.ocx" Alias "HtmlHelpA" _
       (hwnd As Long, _
        lpHelpFile As String, _
        wCommand As Long, _
        dwData As String) As Long

$ENDIF      'HTMLHELP_INC 
  