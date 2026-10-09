$DEFINE __COMMCTRL

Declare Sub InitCommonControls Lib "comctl32.dll" Alias "InitCommonControls"()

$IFNDEF __WIN32API
Const WM_USER = &H400
$ENDIF

Const CCM_FIRST               = &H2000
Const CCM_GETCOLORSCHEME      = (CCM_FIRST + 3)
Const CCM_GETDROPTARGET       = (CCM_FIRST + 4)
Const CCM_GETUNICODEFORMAT    = (CCM_FIRST + 6)
Const CCM_GETVERSION          = (CCM_FIRST + &H8)
Const CCM_LAST                = (CCM_FIRST + &H200)
Const CCM_SETBKCOLOR          = (CCM_FIRST + 1)
Const CCM_SETCOLORSCHEME      = (CCM_FIRST + 2)
Const CCM_SETNOTIFYWINDOW     = (CCM_FIRST + &H9)
Const CCM_SETUNICODEFORMAT    = (CCM_FIRST + 5)
Const CCM_SETVERSION          = (CCM_FIRST + &H7)
Const CCM_SETWINDOWTHEME      = (CCM_FIRST + &HB)

Const CCS_ADJUSTABLE          = &H20
Const CCS_BOTTOM              = &H3
Const CCS_LEFT                = (&H80 Or &H1)
Const CCS_NODIVIDER           = &H40
Const CCS_NOMOVEX             = (&H80 Or &H2)
Const CCS_NOMOVEY             = &H2
Const CCS_NOPARENTALIGN       = &H8
Const CCS_NORESIZE            = &H4
Const CCS_RIGHT               = (&H80 Or &H3)
Const CCS_TOP                 = &H1
Const CCS_VERT                = &H80

Const SBARS_SIZEGRIP = &H100

'TreeView Control
Const TVS_HASBUTTONS      = &H00000001
Const TVS_HASLINES        = &H00000002
Const TVS_LINESATROOT     = &H00000004
Const TVS_EDITLABELS      = &H00000008
Const TVS_DISABLEDRAGDROP = &H00000010
Const TVS_SHOWSELALWAYS   = &H00000020
Const TVS_RTLREADING      = &H00000040
Const TVS_NOTOOLTIPS      = &H00000080
Const TVS_CHECKBOXES      = &H00000100
Const TVS_TRACKSELECT     = &H00000200
Const TVS_SINGLEEXPAND    = &H00000400
Const TVS_INFOTIP         = &H00000800
Const TVS_FULLROWSELECT   = &H00001000
Const TVS_NOSCROLL        = &H00002000
Const TVS_NONEVENHEIGHT   = &H00004000
Const TVS_NOHSCROLL       = &H00008000  ' TVS_NOSCROLL overrides this

' end_r_commctrl

Const TVIF_TEXT           = &H0001
Const TVIF_IMAGE          = &H0002
Const TVIF_PARAM          = &H0004
Const TVIF_STATE          = &H0008
Const TVIF_HANDLE         = &H0010
Const TVIF_SELECTEDIMAGE  = &H0020
Const TVIF_CHILDREN       = &H0040
Const TVIF_INTEGRAL       = &H0080

Const TVIS_SELECTED       = &H0002
Const TVIS_CUT            = &H0004
Const TVIS_DROPHILITED    = &H0008
Const TVIS_BOLD           = &H0010
Const TVIS_EXPANDED       = &H0020
Const TVIS_EXPANDEDONCE   = &H0040
Const TVIS_EXPANDPARTIAL  = &H0080

Const TVIS_OVERLAYMASK    = &H00F00
Const TVIS_STATEIMAGEMASK = &H0F000
Const TVIS_USERMASK       = &H0F000

Const I_CHILDRENCALLBACK  = -1

TYPE TV_ITEM
    mask           AS LONG
    hItem          AS LONG
    STATE          AS LONG
    stateMask      AS LONG
    pszText        AS LONG 'String PTR
    cchTextMax     AS LONG
    iImage         AS LONG
    iSelectedImage AS LONG
    cChildren      AS LONG
    lParam         AS LONG
END TYPE

TYPE TVITEM
    mask           AS LONG
    hItem          AS LONG
    STATE          AS LONG
    stateMask      AS LONG
    pszText        AS LONG 'String PTR
    cchTextMax     AS LONG
    iImage         AS LONG
    iSelectedImage AS LONG
    cChildren      AS LONG
    lParam         AS LONG
END TYPE

' only used for Get and Set messages.  no notifies

TYPE TVITEMEX
    mask           AS LONG
    hItem          AS LONG
    STATE          AS LONG
    stateMask      AS LONG
    pszText        AS LONG 'String PTR
    cchTextMax     AS LONG
    iImage         AS LONG
    iSelectedImage AS LONG
    cChildren      AS LONG
    lParam         AS LONG
    iIntegral      AS LONG
END TYPE

Const TVI_ROOT               = &HFFFF0000???
Const TVI_FIRST              = &HFFFF0001???
Const TVI_LAST               = &HFFFF0002???
Const TVI_SORT               = &HFFFF0003???

TYPE TV_ITEM_UNION
    itemex AS LONG 'TVITEMEX
    item   AS LONG 'TV_ITEM
END TYPE

TYPE TV_INSERTSTRUCT
    hParent      AS LONG
    hInsertAfter AS LONG
    item         AS LONG'TV_ITEM_UNION
END TYPE

Const TV_FIRST = &H1100

Const TVM_INSERTITEM         = TV_FIRST
Const TVM_INSERTITEMW        = TV_FIRST + 50

Const TVM_DELETEITEM         = TV_FIRST + 1
Const TVM_EXPAND             = TV_FIRST + 2

Const TVE_COLLAPSE           = &H00000001
Const TVE_EXPAND             = &H00000002
Const TVE_TOGGLE             = &H00000003
Const TVE_EXPANDPARTIAL      = &H00004000
Const TVE_COLLAPSERESET      = &H00008000

Const TVM_GETITEMRECT        = TV_FIRST + 4
Const TVM_GETCOUNT           = TV_FIRST + 5
Const TVM_GETINDENT          = TV_FIRST + 6
Const TVM_SETINDENT          = TV_FIRST + 7
Const TVM_GETIMAGELIST       = TV_FIRST + 8
Const TVSIL_NORMAL           = 0
Const TVSIL_STATE            = 2

Const TVM_SETIMAGELIST       = TV_FIRST + 9
Const TVM_GETNEXTITEM        = TV_FIRST + 10
Const TVGN_ROOT              = &H0000
Const TVGN_NEXT              = &H0001
Const TVGN_PREVIOUS          = &H0002
Const TVGN_PARENT            = &H0003
Const TVGN_CHILD             = &H0004
Const TVGN_FIRSTVISIBLE      = &H0005
Const TVGN_NEXTVISIBLE       = &H0006
Const TVGN_PREVIOUSVISIBLE   = &H0007
Const TVGN_DROPHILITE        = &H0008
Const TVGN_CARET             = &H0009
Const TVGN_LASTVISIBLE       = &H000A

Const TVSI_NOSINGLEEXPAND    = &H08000 ' Should not conflict with TVGN flags.

Const TVM_SELECTITEM         = TV_FIRST + 11
Const TVM_GETITEM            = TV_FIRST + 12
Const TVM_GETITEMW           = TV_FIRST + 62
Const TVM_SETITEM            = TV_FIRST + 13
Const TVM_SETITEMW           = TV_FIRST + 63
Const TVM_EDITLABEL          = TV_FIRST + 14
Const TVM_EDITLABELW         = TV_FIRST + 65
Const TVM_GETEDITCONTROL     = TV_FIRST + 15
Const TVM_GETVISIBLECOUNT    = TV_FIRST + 16
Const TVM_HITTEST            = TV_FIRST + 17

TYPE TV_HITTESTINFO
    pt AS LONG'POINTAPI
    flags AS LONG
    hItem AS LONG
END TYPE

Const TVHT_NOWHERE           = &H0001
Const TVHT_ONITEMICON        = &H0002
Const TVHT_ONITEMLABEL       = &H0004
Const TVHT_ONITEMINDENT      = &H0008
Const TVHT_ONITEMBUTTON      = &H0010
Const TVHT_ONITEMRIGHT       = &H0020
Const TVHT_ONITEMSTATEICON   = &H0040
Const TVHT_ABOVE             = &H0100
Const TVHT_BELOW             = &H0200
Const TVHT_TORIGHT           = &H0400
Const TVHT_TOLEFT            = &H0800
Const TVHT_ONITEM            = TVHT_ONITEMICON OR TVHT_ONITEMLABEL _
                          OR TVHT_ONITEMSTATEICON

Const TVM_CREATEDRAGIMAGE    = TV_FIRST + 18
Const TVM_SORTCHILDREN       = TV_FIRST + 19
Const TVM_ENSUREVISIBLE      = TV_FIRST + 20

TYPE TV_SORTCB
    hParent     AS LONG
    lpfnCompare AS LONG
    lParam      AS LONG
END TYPE

Const TVM_SORTCHILDRENCB     = TV_FIRST + 21
Const TVM_ENDEDITLABELNOW    = TV_FIRST + 22
Const TVM_GETISEARCHSTRING   = TV_FIRST + 23
Const TVM_SETTOOLTIPS        = TV_FIRST + 24
Const TVM_GETTOOLTIPS        = TV_FIRST + 25
Const TVM_SETINSERTMARK      = TV_FIRST + 26
Const TVM_SETUNICODEFORMAT   = CCM_SETUNICODEFORMAT
Const TVM_GETUNICODEFORMAT   = CCM_GETUNICODEFORMAT
Const TVM_SETITEMHEIGHT      = TV_FIRST + 27
Const TVM_GETITEMHEIGHT      = TV_FIRST + 28
Const TVM_SETBKCOLOR         = TV_FIRST + 29
Const TVM_SETTEXTCOLOR       = TV_FIRST + 30
Const TVM_GETBKCOLOR         = TV_FIRST + 31
Const TVM_GETTEXTCOLOR       = TV_FIRST + 32
Const TVM_SETSCROLLTIME      = TV_FIRST + 33
Const TVM_GETSCROLLTIME      = TV_FIRST + 34
Const TVM_SETINSERTMARKCOLOR = TV_FIRST + 37
Const TVM_GETINSERTMARKCOLOR = TV_FIRST + 38
Const TVM_GETITEMSTATE = TV_FIRST + 39

' Despite this returning a DWORD, Microsoft documents one of the return
' values as being -1. What they mean is &HFFFFFFFF???, not &HFFFFFFFF&.
Const TVM_SETLINECOLOR = TV_FIRST + 40
Const TVM_GETLINECOLOR = TV_FIRST + 41


TYPE NM_TREEVIEW
    hdr     AS LONG'NMHDR
    action  AS LONG
    itemOld AS LONG'TV_ITEM
    itemNew AS LONG'TV_ITEM
    ptDrag  AS LONG'POINTAPI
END TYPE

Const TVN_FIRST = (-400)

Const TVN_SELCHANGING        = TVN_FIRST - 1
Const TVN_SELCHANGINGW       = TVN_FIRST - 50
Const TVN_SELCHANGED         = TVN_FIRST - 2
Const TVN_SELCHANGEDW        = TVN_FIRST - 51

Const TVC_UNKNOWN            = &H0000
Const TVC_BYMOUSE            = &H0001
Const TVC_BYKEYBOARD         = &H0002

Const TVN_GETDISPINFO        = TVN_FIRST - 3
Const TVN_GETDISPINFOW       = TVN_FIRST - 52
Const TVN_SETDISPINFO        = TVN_FIRST - 4
Const TVN_SETDISPINFOW       = TVN_FIRST - 53

Const TVIF_DI_SETITEM        = &H1000

TYPE TV_DISPINFO
    hdr  AS LONG'NMHDR
    item AS LONG'TV_ITEM
END TYPE

TYPE NMTVDISPINFO
    hdr  AS LONG'NMHDR
    item AS LONG'TV_ITEM
END TYPE

Const TVN_ITEMEXPANDING      = TVN_FIRST - 5
Const TVN_ITEMEXPANDINGW     = TVN_FIRST - 54
Const TVN_ITEMEXPANDED       = TVN_FIRST - 6
Const TVN_ITEMEXPANDEDW      = TVN_FIRST - 55
Const TVN_BEGINDRAG          = TVN_FIRST - 7
Const TVN_BEGINDRAGW         = TVN_FIRST - 56
Const TVN_BEGINRDRAG         = TVN_FIRST - 8
Const TVN_BEGINRDRAGW        = TVN_FIRST - 57
Const TVN_DELETEITEM         = TVN_FIRST - 9
Const TVN_DELETEITEMW        = TVN_FIRST - 58
Const TVN_BEGINLABELEDIT     = TVN_FIRST - 10
Const TVN_BEGINLABELEDITW    = TVN_FIRST - 59
Const TVN_ENDLABELEDIT       = TVN_FIRST - 11
Const TVN_ENDLABELEDITW      = TVN_FIRST - 60
Const TVN_KEYDOWN            = TVN_FIRST - 12
Const TVN_GETINFOTIP         = TVN_FIRST - 13
Const TVN_GETINFOTIPW        = TVN_FIRST - 14
Const TVN_SINGLEEXPAND       = TVN_FIRST - 15

Const TVNRET_DEFAULT = 0
Const TVNRET_SKIPOLD = 1
Const TVNRET_SKIPNEW = 2

TYPE TV_KEYDOWN
    hdr   AS LONG'NMHDR
    wVKey AS WORD
    flags AS LONG
END TYPE

TYPE NMTVKEYDOWN
    hdr   AS NMHDR
    wVKey AS WORD
    flags AS LONG
END TYPE

TYPE NMTVCUSTOMDRAW
    nmcd      AS LONG'NMCUSTOMDRAW
    clrText   AS LONG
    clrTextBk AS LONG
    iLevel    AS LONG
END TYPE

TYPE NMTVGETINFOTIP
    hdr        AS LONG'NMHDR
    pszText    AS LONG'String PTR
    cchTextMax AS LONG
    hItem      AS LONG
    lParam     AS LONG
END TYPE

' treeview's customdraw return meaning don't draw images.
' valid on CDRF_NOTIFYITEMPREPAINT
Const TVCDRF_NOIMAGES        = &H00010000

'TabControl

Const WC_TABCONTROL           = "SysTabControl32"

Const TCS_SCROLLOPPOSITE      = &H00000001  ' assumes multiline tab
Const TCS_BOTTOM              = &H00000002
Const TCS_RIGHT               = &H00000002
Const TCS_MULTISELECT         = &H00000004  ' allow multi-select in button mode
Const TCS_FLATBUTTONS         = &H00000008
Const TCS_FORCEICONLEFT       = &H00000010
Const TCS_FORCELABELLEFT      = &H00000020
Const TCS_HOTTRACK            = &H00000040
Const TCS_VERTICAL            = &H00000080
Const TCS_TABS                = &H00000000
Const TCS_BUTTONS             = &H00000100
Const TCS_SINGLELINE          = &H00000000
Const TCS_MULTILINE           = &H00000200
Const TCS_RIGHTJUSTIFY        = &H00000000
Const TCS_FIXEDWIDTH          = &H00000400
Const TCS_RAGGEDRIGHT         = &H00000800
Const TCS_FOCUSONBUTTONDOWN   = &H00001000
Const TCS_OWNERDRAWFIXED      = &H00002000
Const TCS_TOOLTIPS            = &H00004000
Const TCS_FOCUSNEVER          = &H00008000

Const TCS_EX_FLATSEPARATORS   = &H00000001
Const TCS_EX_REGISTERDROP     = &H00000002

Const TCM_FIRST = &H1300
Const TCM_GETIMAGELIST        = TCM_FIRST + 2
Const TCM_SETIMAGELIST        = TCM_FIRST + 3
Const TCM_GETITEMCOUNT        = TCM_FIRST + 4

Const TCIF_TEXT               = &H0001
Const TCIF_IMAGE              = &H0002
Const TCIF_RTLREADING         = &H0004
Const TCIF_PARAM              = &H0008
Const TCIF_STATE              = &H0010

Const TCIS_BUTTONPRESSED      = &H0001
Const TCIS_HIGHLIGHTED        = &H0002

TYPE TC_ITEMHEADER
    Mask          AS LONG
    lpReserved1   AS LONG
    lpReserved2   AS LONG
    pszText       AS LONG
    cchTextMax    AS LONG
    iImage        AS LONG
END TYPE

TYPE TC_ITEM
    Mask          AS LONG
    dwState       AS LONG
    dwStateMask   AS LONG
    pszText       AS LONG
    cchTextMax    AS LONG
    iImage        AS LONG
    lParam        AS LONG
END TYPE

Const TCM_GETITEM             = TCM_FIRST + 5
Const TCM_GETITEMW            = TCM_FIRST + 60
Const TCM_SETITEM            = TCM_FIRST + 6
Const TCM_SETITEMW           = TCM_FIRST + 61
Const TCM_INSERTITEM         = TCM_FIRST + 7
Const TCM_INSERTITEMW        = TCM_FIRST + 62

Const TCM_DELETEITEM         = TCM_FIRST + 8
Const TCM_DELETEALLITEMS      = TCM_FIRST + 9
Const TCM_GETITEMRECT         = TCM_FIRST + 10
Const TCM_GETCURSEL           = TCM_FIRST + 11
Const TCM_SETCURSEL           = TCM_FIRST + 12

Const TCHT_NOWHERE      = &H0001
Const TCHT_ONITEMICON   = &H0002
Const TCHT_ONITEMLABEL  = &H0004
Const TCHT_ONITEM       = TCHT_ONITEMICON OR TCHT_ONITEMLABEL

TYPE TC_HITTESTINFO
    pt    AS LONG 'POINTAPI
    flags AS LONG
END TYPE

Const TCM_HITTEST             = TCM_FIRST + 13
Const TCM_SETITEMEXTRA        = TCM_FIRST + 14
Const TCM_ADJUSTRECT          = TCM_FIRST + 40
Const TCM_SETITEMSIZE         = TCM_FIRST + 41
Const TCM_REMOVEIMAGE         = TCM_FIRST + 42
Const TCM_SETPADDING          = TCM_FIRST + 43
Const TCM_GETROWCOUNT         = TCM_FIRST + 44
Const TCM_GETTOOLTIPS         = TCM_FIRST + 45
Const TCM_SETTOOLTIPS         = TCM_FIRST + 46
Const TCM_GETCURFOCUS         = TCM_FIRST + 47
Const TCM_SETCURFOCUS         = TCM_FIRST + 48
Const TCM_SETMINTABWIDTH      = TCM_FIRST + 49
Const TCM_DESELECTALL         = TCM_FIRST + 50
Const TCM_HIGHLIGHTITEM       = TCM_FIRST + 51
Const TCM_SETEXTENDEDSTYLE    = TCM_FIRST + 52  ' optional wParam == mask
Const TCM_GETEXTENDEDSTYLE    = TCM_FIRST + 53
Const TCM_SETUNICODEFORMAT    = CCM_SETUNICODEFORMAT
Const TCM_GETUNICODEFORMAT    = CCM_GETUNICODEFORMAT
Const TCN_FIRST = -550
Const TCN_KEYDOWN             = TCN_FIRST - 0

TYPE TC_KEYDOWN
    hdr    AS LONG'NMHDR
    wVKey  AS WORD
    flags  AS LONG
END TYPE

Const TCN_SELCHANGE   = TCN_FIRST - 1
Const TCN_SELCHANGING = TCN_FIRST - 2
Const TCN_GETOBJECT   = TCN_FIRST - 3
Const TCN_FOCUSCHANGE = TCN_FIRST - 4

'ListView Control

Const LVS_ICON            = &H00000000
Const LVS_REPORT          = &H00000001
Const LVS_SMALLICON       = &H00000002
Const LVS_LIST            = &H00000003
Const LVS_TYPEMASK        = &H00000003
Const LVS_SINGLESEL       = &H00000004
Const LVS_SHOWSELALWAYS   = &H00000008
Const LVS_SORTASCENDING   = &H00000010
Const LVS_SORTDESCENDING  = &H00000020
Const LVS_SHAREIMAGELISTS = &H00000040
Const LVS_NOLABELWRAP     = &H00000080
Const LVS_AUTOARRANGE     = &H00000100
Const LVS_EDITLABELS      = &H00000200
Const LVS_OWNERDATA       = &H00001000
Const LVS_NOSCROLL        = &H00002000

Const LVS_TYPESTYLEMASK   = &H0000FC00

Const LVS_ALIGNTOP        = &H00000000
Const LVS_ALIGNLEFT       = &H00000800
Const LVS_ALIGNMASK       = &H00000C00

Const LVS_OWNERDRAWFIXED  = &H00000400
Const LVS_NOCOLUMNHEADER  = &H00004000
Const LVS_NOSORTHEADER    = &H00008000

' end_r_commctrl

Const LVM_SETUNICODEFORMAT   = CCM_SETUNICODEFORMAT

Const LVM_FIRST = &H1000

Const LVM_GETUNICODEFORMAT   = CCM_GETUNICODEFORMAT
Const LVM_GETBKCOLOR         = LVM_FIRST + 0
Const LVM_SETBKCOLOR         = LVM_FIRST + 1
Const LVM_GETIMAGELIST       = LVM_FIRST + 2

Const LVSIL_NORMAL           = 0
Const LVSIL_SMALL            = 1
Const LVSIL_STATE            = 2

Const LVM_SETIMAGELIST       = LVM_FIRST + 3
Const LVM_GETITEMCOUNT       = LVM_FIRST + 4

Const LVIF_TEXT              = &H0001
Const LVIF_IMAGE             = &H0002
Const LVIF_PARAM             = &H0004
Const LVIF_STATE             = &H0008
Const LVIF_INDENT            = &H0010
Const LVIF_NORECOMPUTE       = &H0800
Const LVIF_GROUPID           = &H0100
Const LVIF_COLUMNS           = &H0200

Const LVIS_FOCUSED           = &H0001
Const LVIS_SELECTED          = &H0002
Const LVIS_CUT               = &H0004
Const LVIS_DROPHILITED       = &H0008
Const LVIS_GLOW              = &H0010
Const LVIS_ACTIVATING        = &H0020

Const LVIS_OVERLAYMASK       = &H00F00
Const LVIS_STATEIMAGEMASK    = &H0F000

Const I_INDENTCALLBACK  = -1

Const I_GROUPIDCALLBACK = -1
Const I_GROUPIDNONE     = -2

TYPE LV_ITEM
    mask       AS LONG
    iItem      AS LONG
    iSubItem   AS LONG
    STATE      AS LONG
    stateMask  AS LONG
    pszText    AS LONG 'String PTR
    cchTextMax AS LONG
    iImage     AS LONG
    lParam     AS LONG
    iIndent    AS LONG
    iGroupId   AS LONG
    cColumns   AS LONG        ' tile view columns
    puColumns  AS LONG 'PTR
END TYPE

TYPE LVITEM
    mask       AS LONG
    iItem      AS LONG
    iSubItem   AS LONG
    STATE      AS LONG
    stateMask  AS LONG
    pszText    AS LONG 'String PTR
    cchTextMax AS LONG
    iImage     AS LONG
    lParam     AS LONG
    iIndent    AS LONG
    iGroupId   AS LONG
    cColumns   AS LONG        ' tile view columns
    puColumns  AS LONG 'PTR
END TYPE

Const I_IMAGECALLBACK = -1
Const I_IMAGENONE     = -2

Const LVM_GETITEM            = LVM_FIRST + 5
Const LVM_GETITEMW           = LVM_FIRST + 75

Const LVM_SETITEM            = LVM_FIRST + 6
Const LVM_SETITEMW           = LVM_FIRST + 76

Const LVM_INSERTITEM         = LVM_FIRST + 7
Const LVM_INSERTITEMW        = LVM_FIRST + 77

Const LVM_DELETEITEM         = LVM_FIRST + 8
Const LVM_DELETEALLITEMS     = LVM_FIRST + 9
Const LVM_GETCALLBACKMASK    = LVM_FIRST + 10
Const LVM_SETCALLBACKMASK    = LVM_FIRST + 11

Const LVNI_ALL               = &H0000
Const LVNI_FOCUSED           = &H0001
Const LVNI_SELECTED          = &H0002
Const LVNI_CUT               = &H0004
Const LVNI_DROPHILITED       = &H0008

Const LVNI_ABOVE             = &H0100
Const LVNI_BELOW             = &H0200
Const LVNI_TOLEFT            = &H0400
Const LVNI_TORIGHT           = &H0800

Const LVM_GETNEXTITEM        = LVM_FIRST + 12

Const LVFI_PARAM             = &H0001
Const LVFI_STRING            = &H0002
Const LVFI_PARTIAL           = &H0008
Const LVFI_WRAP              = &H0020
Const LVFI_NEARESTXY         = &H0040

TYPE LV_FINDINFO
    flags AS LONG
    psz AS LONG 'tString PTR
    lParam AS LONG
    pt AS LONG'POINTAPI
    vkDirection AS LONG
END TYPE

TYPE LVFINDINFO
    flags       AS LONG
    psz         AS LONG 'String PTR
    lParam      AS LONG
    pt          AS LONG 'POINTAPI
    vkDirection AS LONG
END TYPE

Const LVM_FINDITEM           = LVM_FIRST + 13
Const LVM_FINDITEMW          = LVM_FIRST + 83
Const LVIR_BOUNDS            = 0
Const LVIR_ICON              = 1
Const LVIR_LABEL             = 2
Const LVIR_SELECTBOUNDS      = 3

Const LVM_GETITEMRECT        = LVM_FIRST + 14
Const LVM_SETITEMPOSITION    = LVM_FIRST + 15
Const LVM_GETITEMPOSITION    = LVM_FIRST + 16
Const LVM_GETSTRINGWIDTH     = LVM_FIRST + 17
Const LVM_GETSTRINGWIDTHW    = LVM_FIRST + 87

Const LVHT_NOWHERE           = &H0001
Const LVHT_ONITEMICON        = &H0002
Const LVHT_ONITEMLABEL       = &H0004
Const LVHT_ONITEMSTATEICON   = &H0008
Const LVHT_ONITEM            = (LVHT_ONITEMICON OR LVHT_ONITEMLABEL OR LVHT_ONITEMSTATEICON)

Const LVHT_ABOVE             = &H0008
Const LVHT_BELOW             = &H0010
Const LVHT_TORIGHT           = &H0020
Const LVHT_TOLEFT            = &H0040

TYPE LV_HITTESTINFO
    pt    AS LONG 'POINTAPI
    flags AS LONG
    iItem AS LONG
END TYPE

TYPE LVHITTESTINFO
    pt       AS LONG 'POINTAPI
    flags    AS LONG
    iItem    AS LONG
    iSubItem AS LONG
END TYPE

Const LVM_HITTEST            = LVM_FIRST + 18
Const LVM_ENSUREVISIBLE      = LVM_FIRST + 19
Const LVM_SCROLL             = LVM_FIRST + 20
Const LVM_REDRAWITEMS        = LVM_FIRST + 21
Const LVA_DEFAULT            = &H0000
Const LVA_ALIGNLEFT          = &H0001
Const LVA_ALIGNTOP           = &H0002
Const LVA_SNAPTOGRID         = &H0005

Const LVM_ARRANGE            = LVM_FIRST + 22
Const LVM_EDITLABEL          = LVM_FIRST + 23
Const LVM_EDITLABELW         = LVM_FIRST + 118
Const LVM_GETEDITCONTROL     = LVM_FIRST + 24

TYPE LV_COLUMN
    mask AS LONG
    fmt AS LONG
    cx AS LONG
    pszText AS LONG 'String PTR
    cchTextMax AS LONG
    iSubItem AS LONG
    iImage AS LONG
    iOrder AS LONG
END TYPE

TYPE LVCOLUMN
    mask AS LONG
    fmt AS LONG
    cx AS LONG
    pszText AS LONG 'String PTR
    cchTextMax AS LONG
    iSubItem AS LONG
    iImage AS LONG
    iOrder AS LONG
END TYPE

Const LVCF_FMT               = &H0001
Const LVCF_WIDTH             = &H0002
Const LVCF_TEXT              = &H0004
Const LVCF_SUBITEM           = &H0008
Const LVCF_IMAGE             = &H0010
Const LVCF_ORDER             = &H0020

Const LVCFMT_LEFT            = &H00000000
Const LVCFMT_RIGHT           = &H00000001
Const LVCFMT_CENTER          = &H00000002
Const LVCFMT_JUSTIFYMASK     = &H00000003
Const LVCFMT_IMAGE           = &H00000800
Const LVCFMT_BITMAP_ON_RIGHT = &H00001000
Const LVCFMT_COL_HAS_IMAGES  = &H00008000

Const LVM_GETCOLUMN          = LVM_FIRST + 25
Const LVM_GETCOLUMNW         = LVM_FIRST + 95

Const LVM_SETCOLUMN          = LVM_FIRST + 26
Const LVM_SETCOLUMNW         = LVM_FIRST + 96
Const LVM_INSERTCOLUMN       = LVM_FIRST + 27
Const LVM_INSERTCOLUMNW      = LVM_FIRST + 97
Const LVM_DELETECOLUMN       = LVM_FIRST + 28
Const LVM_GETCOLUMNWIDTH     = LVM_FIRST + 29
Const LVSCW_AUTOSIZE             = -1
Const LVSCW_AUTOSIZE_USEHEADER   = -2
Const LVM_SETCOLUMNWIDTH         = LVM_FIRST + 30
Const LVM_GETHEADER          = LVM_FIRST + 31
Const LVM_CREATEDRAGIMAGE    = LVM_FIRST + 33
Const LVM_GETVIEWRECT        = LVM_FIRST + 34
Const LVM_GETTEXTCOLOR       = LVM_FIRST + 35
Const LVM_SETTEXTCOLOR       = LVM_FIRST + 36
Const LVM_GETTEXTBKCOLOR     = LVM_FIRST + 37
Const LVM_SETTEXTBKCOLOR     = LVM_FIRST + 38
Const LVM_GETTOPINDEX        = LVM_FIRST + 39
Const LVM_GETCOUNTPERPAGE    = LVM_FIRST + 40
Const LVM_GETORIGIN          = LVM_FIRST + 41
Const LVM_UPDATE             = LVM_FIRST + 42
Const LVM_SETITEMSTATE       = LVM_FIRST + 43
Const LVM_GETITEMSTATE       = LVM_FIRST + 44
Const LVM_GETITEMTEXT        = (LVM_FIRST + 45)
Const LVM_GETITEMTEXTW       = (LVM_FIRST + 115)

Const LVM_SETITEMTEXT        = LVM_FIRST + 46
Const LVM_SETITEMTEXTW       = LVM_FIRST + 116

' these flags only apply to LVS_OWNERDATA listviews in report or list mode
Const LVSICF_NOINVALIDATEALL  = &H00000001
Const LVSICF_NOSCROLL         = &H00000002

Const LVM_SETITEMCOUNT       = LVM_FIRST + 47
Const LVM_SORTITEMS          = LVM_FIRST + 48
Const LVM_SETITEMPOSITION32  = LVM_FIRST + 49
Const LVM_GETSELECTEDCOUNT   = LVM_FIRST + 50
Const LVM_GETITEMSPACING     = LVM_FIRST + 51
Const LVM_GETISEARCHSTRING   = LVM_FIRST + 52
Const LVM_GETISEARCHSTRINGW  = LVM_FIRST + 117
Const LVM_SETICONSPACING     = LVM_FIRST + 53

' -1 for cx and cy means we'll use the default (system settings)
' 0 for cx or cy means use the current setting (allows you to change just one param)

Const LVM_SETEXTENDEDLISTVIEWSTYLE = LVM_FIRST + 54  ' optional wParam == mask
Const LVM_GETEXTENDEDLISTVIEWSTYLE = LVM_FIRST + 55

Const LVS_EX_GRIDLINES        = &H00000001
Const LVS_EX_SUBITEMIMAGES    = &H00000002
Const LVS_EX_CHECKBOXES       = &H00000004
Const LVS_EX_TRACKSELECT      = &H00000008
Const LVS_EX_HEADERDRAGDROP   = &H00000010
Const LVS_EX_FULLROWSELECT    = &H00000020 ' applies to report mode only
Const LVS_EX_ONECLICKACTIVATE = &H00000040
Const LVS_EX_TWOCLICKACTIVATE = &H00000080
Const LVS_EX_FLATSB           = &H00000100
Const LVS_EX_REGIONAL         = &H00000200
Const LVS_EX_INFOTIP          = &H00000400 ' listview does InfoTips for you
Const LVS_EX_UNDERLINEHOT     = &H00000800
Const LVS_EX_UNDERLINECOLD    = &H00001000
Const LVS_EX_MULTIWORKAREAS   = &H00002000
Const LVS_EX_LABELTIP         = &H00004000 ' listview unfolds partly hidden labels if it does not have infotip text
Const LVS_EX_BORDERSELECT     = &H00008000 ' border selection style instead of highlight
Const LVS_EX_DOUBLEBUFFER     = &H00010000
Const LVS_EX_HIDELABELS       = &H00020000
Const LVS_EX_SINGLEROW        = &H00040000
Const LVS_EX_SNAPTOGRID       = &H00080000 ' Icons automatically snap to grid.
Const LVS_EX_SIMPLESELECT     = &H00100000 ' Also changes overlay rendering to top right for icon mode.

Const LVM_GETSUBITEMRECT      = LVM_FIRST + 56
Const LVM_SUBITEMHITTEST      = LVM_FIRST + 57
Const LVM_SETCOLUMNORDERARRAY = LVM_FIRST + 58
Const LVM_GETCOLUMNORDERARRAY = LVM_FIRST + 59
Const LVM_SETHOTITEM  = LVM_FIRST + 60
Const LVM_GETHOTITEM  = LVM_FIRST + 61
Const LVM_SETHOTCURSOR  = LVM_FIRST + 62
Const LVM_GETHOTCURSOR  = LVM_FIRST + 63
Const LVM_APPROXIMATEVIEWRECT = LVM_FIRST + 64
Const LV_MAX_WORKAREAS         = 16
Const LVM_SETWORKAREAS         = LVM_FIRST + 65
Const LVM_GETWORKAREAS        = LVM_FIRST + 70
Const LVM_GETNUMBEROFWORKAREAS  = LVM_FIRST + 73
Const LVM_GETSELECTIONMARK    = LVM_FIRST + 66
Const LVM_SETSELECTIONMARK    = LVM_FIRST + 67
Const LVM_SETHOVERTIME        = LVM_FIRST + 71
Const LVM_GETHOVERTIME        = LVM_FIRST + 72
Const LVM_SETTOOLTIPS       = LVM_FIRST + 74
Const LVM_GETTOOLTIPS       = LVM_FIRST + 78
Const LVM_SORTITEMSEX       = LVM_FIRST + 81

TYPE LVBKIMAGE
    ulFlags        AS LONG    ' LVBKIF_*
    hbm            AS LONG
    pszImage       AS LONG 'String PTR
    cchImageMax    AS LONG
    xOffsetPercent AS LONG
    yOffsetPercent AS LONG
END TYPE

Const LVBKIF_SOURCE_NONE      = &H00000000
Const LVBKIF_SOURCE_HBITMAP   = &H00000001
Const LVBKIF_SOURCE_URL       = &H00000002
Const LVBKIF_SOURCE_MASK      = &H00000003
Const LVBKIF_STYLE_NORMAL     = &H00000000
Const LVBKIF_STYLE_TILE       = &H00000010
Const LVBKIF_STYLE_MASK       = &H00000010
Const LVBKIF_FLAG_TILEOFFSET  = &H00000100
Const LVBKIF_TYPE_WATERMARK   = &H10000000

Const LVM_SETBKIMAGE          = LVM_FIRST + 68
Const LVM_SETBKIMAGEW         = LVM_FIRST + 138
Const LVM_GETBKIMAGE          = LVM_FIRST + 69
Const LVM_GETBKIMAGEW         = LVM_FIRST + 139

Const LVM_SETSELECTEDCOLUMN         = (LVM_FIRST + 140)
Const LVM_SETTILEWIDTH         = (LVM_FIRST + 141)

Const LV_VIEW_ICON      = &H0000
Const LV_VIEW_DETAILS   = &H0001
Const LV_VIEW_SMALLICON = &H0002
Const LV_VIEW_LIST      = &H0003
Const LV_VIEW_TILE      = &H0004
Const LV_VIEW_MAX       = &H0004

Const LVM_SETVIEW         = (LVM_FIRST + 142)
Const LVM_GETVIEW         = (LVM_FIRST + 143)

Const LVGF_NONE          = &H00000000
Const LVGF_HEADER        = &H00000001
Const LVGF_FOOTER        = &H00000002
Const LVGF_STATE         = &H00000004
Const LVGF_ALIGN         = &H00000008
Const LVGF_GROUPID       = &H00000010

Const LVGS_NORMAL        = &H00000000
Const LVGS_COLLAPSED     = &H00000001
Const LVGS_HIDDEN        = &H00000002

Const LVGA_HEADER_LEFT   = &H00000001
Const LVGA_HEADER_CENTER = &H00000002
Const LVGA_HEADER_RIGHT  = &H00000004  ' Don't forget to validate exclusivity
Const LVGA_FOOTER_LEFT   = &H00000008
Const LVGA_FOOTER_CENTER = &H00000010
Const LVGA_FOOTER_RIGHT  = &H00000020  ' Don't forget to validate exclusivity

' MSDN documents this type (incorrectly) as LV_GROUP
TYPE LVGROUP
    cbSize    AS LONG
    mask      AS LONG
    pszHeader AS LONG ' UnicodeZ string ptr
    cchHeader AS LONG
    pszFooter AS LONG ' UnicodeZ string ptr
    cchFooter AS LONG
    iGroupId  AS LONG
    stateMask AS LONG
    state     AS LONG
    uAlign    AS LONG
END TYPE

Const LVM_INSERTGROUP       = (LVM_FIRST + 145)
Const LVM_SETGROUPINFO      = (LVM_FIRST + 147)
Const LVM_GETGROUPINFO      = (LVM_FIRST + 149)
Const LVM_REMOVEGROUP       = (LVM_FIRST + 150)
Const LVM_MOVEGROUP         = (LVM_FIRST + 151)
Const LVM_MOVEITEMTOGROUP   = (LVM_FIRST + 154)

Const LVGMF_NONE        = &H00000000
Const LVGMF_BORDERSIZE  = &H00000001
Const LVGMF_BORDERCOLOR = &H00000002
Const LVGMF_TEXTCOLOR   = &H00000004

TYPE LVGROUPMETRICS
    cbSize   AS LONG
    mask     AS LONG
    nLeft    AS LONG
    nTop     AS LONG
    nRight   AS LONG
    nBottom  AS LONG
    crLeft   AS LONG
    crTop    AS LONG
    crRight  AS LONG
    crBottom AS LONG
    crHeader AS LONG
    crFooter AS LONG
END TYPE

Const LVM_SETGROUPMETRICS    = (LVM_FIRST + 155)
Const LVM_GETGROUPMETRICS    = (LVM_FIRST + 156)
Const LVM_ENABLEGROUPVIEW    = (LVM_FIRST + 157)
Const LVM_SORTGROUPS         = (LVM_FIRST + 158)

TYPE LVINSERTGROUPSORTED
    pfnGroupCompare AS LONG
    pvData AS LONG
    lvGrp AS LONG 'LVGROUP
END TYPE

Const LVM_INSERTGROUPSORTED           = (LVM_FIRST + 159)
Const LVM_REMOVEALLGROUPS             = (LVM_FIRST + 160)
Const LVM_HASGROUP                    = (LVM_FIRST + 161)

Const LVTVIF_AUTOSIZE    = &H00000000
Const LVTVIF_FIXEDWIDTH  = &H00000001
Const LVTVIF_FIXEDHEIGHT = &H00000002
Const LVTVIF_FIXEDSIZE   = &H00000003

Const LVTVIM_TILESIZE    = &H00000001
Const LVTVIM_COLUMNS     = &H00000002
Const LVTVIM_LABELMARGIN = &H00000004

TYPE LVTILEVIEWINFO
    cbSize        AS LONG
    dwMask        AS LONG   ' LVTVIM_*
    dwFlags       AS LONG   ' LVTVIF_*
    sizeTile      AS LONG 'SIZEL
    cLines        AS LONG
    rcLabelMargin AS LONG 'RECT
END TYPE

TYPE LVTILEINFO
    cbSize    AS LONG
    iItem     AS LONG
    cColumns  AS LONG
    puColumns AS LONG 'PTR
END TYPE

Const LVM_SETTILEVIEWINFO                 = (LVM_FIRST + 162)
Const LVM_GETTILEVIEWINFO                 = (LVM_FIRST + 163)
Const LVM_SETTILEINFO                     = (LVM_FIRST + 164)
Const LVM_GETTILEINFO                     = (LVM_FIRST + 165)

TYPE LVINSERTMARK
    cbSize     AS LONG
    dwFlags    AS LONG
    iItem      AS LONG
    dwReserved AS LONG
END TYPE

Const LVIM_AFTER = &H00000001 ' TRUE = insert After iItem, otherwise before
Const LVM_SETINSERTMARK                   = (LVM_FIRST + 166)
Const LVM_GETINSERTMARK                   = (LVM_FIRST + 167)
Const LVM_INSERTMARKHITTEST               = (LVM_FIRST + 168)
Const LVM_GETINSERTMARKRECT               = (LVM_FIRST + 169)
Const LVM_SETINSERTMARKCOLOR              = (LVM_FIRST + 170)
Const LVM_GETINSERTMARKCOLOR              = (LVM_FIRST + 171)

TYPE LVSETINFOTIP
    cbSize   AS LONG
    dwFlags  AS LONG
    pszText  AS LONG ' UnicodeZ string ptr
    iItem    AS LONG
    iSubItem AS LONG
END TYPE

Const LVM_SETINFOTIP         = (LVM_FIRST + 173)
Const LVM_GETSELECTEDCOLUMN   = (LVM_FIRST + 174)
Const LVM_ISGROUPVIEWENABLED  = (LVM_FIRST + 175)
Const LVM_GETOUTLINECOLOR     = (LVM_FIRST + 176)
Const LVM_SETOUTLINECOLOR     = (LVM_FIRST + 177)
Const LVM_CANCELEDITLABEL     = (LVM_FIRST + 179)

' These next to methods make it easy to identify an item that can be repositioned
' within listview. For example: Many developers use the lParam to store an identifier that is
' unique. Unfortunately, in order to find this item, they have to iterate through all of the items
' in the listview. Listview will maintain a unique identifier.  The upper bound is the size of a DWORD.
Const LVM_MAPINDEXTOID     = (LVM_FIRST + 180)
Const LVM_MAPIDTOINDEX     = (LVM_FIRST + 181)


TYPE NM_LISTVIEW
    hdr       AS LONG 'NMHDR
    iItem     AS LONG
    iSubItem  AS LONG
    uNewState AS LONG
    uOldState AS LONG
    uChanged  AS LONG
    ptAction  AS LONG 'POINTAPI
    lParam    AS LONG
END TYPE

TYPE NMLISTVIEW
    hdr       AS LONG 'NMHDR
    iItem     AS LONG
    iSubItem  AS LONG
    uNewState AS LONG
    uOldState AS LONG
    uChanged  AS LONG
    ptAction  AS LONG 'POINTAPI
    lParam    AS LONG
END TYPE

' NMITEMACTIVATE is used instead of NMLISTVIEW in IE >= 0x400
' therefore all the fields are the same except for extra uKeyFlags
' they are used to store key flags at the time of the single click with
' delayed activation - because by the time the timer goes off a user may
' not hold the keys (shift, ctrl) any more

TYPE NMITEMACTIVATE
    hdr       AS LONG 'NMHDR
    iItem     AS LONG
    iSubItem  AS LONG
    uNewState AS LONG
    uOldState AS LONG
    uChanged  AS LONG
    ptAction  AS LONG 'POINTAPI
    lParam    AS LONG
    uKeyFlags AS LONG
END TYPE

' key flags stored in uKeyFlags
Const LVKF_ALT       = &H0001
Const LVKF_CONTROL   = &H0002
Const LVKF_SHIFT     = &H0004

TYPE NMLVCUSTOMDRAW
    nmcd        AS LONG 'NMCUSTOMDRAW
    clrText     AS LONG
    clrTextBk   AS LONG
    iSubItem    AS LONG
    dwItemType  AS LONG
    ' Item custom draw
    clrFace     AS LONG
    iIconEffect AS LONG
    iIconPhase  AS LONG
    iPartId     AS LONG
    iStateId    AS LONG
    ' Group Custom Draw
    rcText      AS LONG 'RECT
    uAlign      AS LONG ' Alignment. Use LVGA_HEADER_CENTER, LVGA_HEADER_RIGHT, LVGA_HEADER_LEFT
END TYPE

' dwItemType
Const LVCDI_ITEM  = &H00000000
Const LVCDI_GROUP = &H00000001

' ListView custom draw return values
Const LVCDRF_NOSELECT     = &H00010000
Const LVCDRF_NOGROUPFRAME = &H00020000

TYPE NMLVCACHEHINT
    hdr   AS LONG 'NMHDR
    iFrom AS LONG
    iTo   AS LONG
END TYPE

TYPE NM_CACHEHINT
    hdr   AS LONG 'NMHDR
    iFrom AS LONG
    iTo   AS LONG
END TYPE

TYPE NMLVFINDITEM
    hdr    AS LONG 'NMHDR
    iStart AS LONG
    lvfi   AS LONG 'LVFINDINFO
END TYPE

TYPE NM_FINDITEM
    hdr    AS LONG 'NMHDR
    iStart AS LONG
    lvfi   AS LONG 'LVFINDINFO
END TYPE

TYPE NMLVODSTATECHANGE
    hdr       AS LONG 'NMHDR
    iFrom     AS LONG
    iTo       AS LONG
    uNewState AS LONG
    uOldState AS LONG
END TYPE

TYPE NM_ODSTATECHANGE
    hdr       AS LONG 'NMHDR
    iFrom     AS LONG
    iTo       AS LONG
    uNewState AS LONG
    uOldState AS LONG
END TYPE

Const LVN_FIRST = -100

Const LVN_ITEMCHANGING    = LVN_FIRST
Const LVN_ITEMCHANGED     = LVN_FIRST - 1
Const LVN_INSERTITEM      = LVN_FIRST - 2
Const LVN_DELETEITEM      = LVN_FIRST - 3
Const LVN_DELETEALLITEMS  = LVN_FIRST - 4
Const LVN_BEGINLABELEDIT  = LVN_FIRST - 5
Const LVN_BEGINLABELEDITW = LVN_FIRST - 75
Const LVN_ENDLABELEDIT    = LVN_FIRST - 6
Const LVN_ENDLABELEDITW   = LVN_FIRST - 76
Const LVN_COLUMNCLICK     = LVN_FIRST - 8
Const LVN_BEGINDRAG       = LVN_FIRST - 9
Const LVN_BEGINRDRAG      = LVN_FIRST - 11

Const LVN_ODCACHEHINT     = LVN_FIRST - 13
Const LVN_ODFINDITEM      = LVN_FIRST - 52
Const LVN_ODFINDITEMW     = LVN_FIRST - 79

Const LVN_ITEMACTIVATE    = LVN_FIRST - 14
Const LVN_ODSTATECHANGED  = LVN_FIRST - 15

Const LVN_HOTTRACK        = LVN_FIRST - 21

Const LVN_GETDISPINFO     = LVN_FIRST - 50
Const LVN_GETDISPINFOW    = LVN_FIRST - 77
Const LVN_SETDISPINFO     = LVN_FIRST - 51
Const LVN_SETDISPINFOW    = LVN_FIRST - 78

Const LVIF_DI_SETITEM     = &H1000

TYPE LV_DISPINFO
    hdr  AS LONG 'NMHDR
    item AS LONG 'LV_ITEM
END TYPE

TYPE NMLVDISPINFO
    hdr  AS LONG 'NMHDR
    item AS LONG 'LVITEM
END TYPE

Const LVN_KEYDOWN          = LVN_FIRST - 55

TYPE LV_KEYDOWN
    hdr   AS LONG 'NMHDR
    wVKey AS WORD
    flags AS LONG
END TYPE

TYPE NMLVKEYDOWN
    hdr   AS LONG 'NMHDR
    wVKey AS WORD
    flags AS LONG
END TYPE

Const LVN_MARQUEEBEGIN     = LVN_FIRST - 56

TYPE NMLVGETINFOTIP
    hdr        AS LONG 'NMHDR
    dwFlags    AS LONG
    pszText    AS LONG 'String PTR
    cchTextMax AS LONG
    iItem      AS LONG
    iSubItem   AS LONG
    lParam     AS LONG
END TYPE

' NMLVGETINFOTIPA.dwFlag values

Const LVGIT_UNFOLDED  = &H0001

Const LVN_GETINFOTIP        = LVN_FIRST - 57
Const LVN_GETINFOTIPW       = LVN_FIRST - 58

TYPE NMLVSCROLL
    hdr AS LONG 'NMHDR
    dx  AS LONG
    dy  AS LONG
END TYPE

Const LVN_BEGINSCROLL       = LVN_FIRST - 80
Const LVN_ENDSCROLL         = LVN_FIRST - 81

'''ToolTip

Const TOOLTIPS_CLASS     = "tooltips_class32"
Const TTS_ALWAYSTIP      = &H01
Const TTS_NOPREFIX       = &H02
Const TTS_BALLOON        = &H40

Const TTF_ABSOLUTE       = &H80
Const TTF_CENTERTIP      = &H2
Const TTF_DI_SETITEM     = &H8000
Const TTF_IDISHWND       = &H1
Const TTF_RTLREADING     = &H4
Const TTF_SUBCLASS       = &H10
Const TTF_TRACK          = &H20
Const TTF_TRANSPARENT    = &H100
Const TTM_TRACKPOSITION  = WM_USER + 18
Const TTM_TRACKACTIVATE  = WM_USER + 17
Const TTM_ADDTOOLW       = WM_USER + 50
Const TTM_ADDTOOLA       = WM_USER + 4
Const TTM_ACTIVATE       = WM_USER + 1
Const TTM_UPDATETIPTEXTA = WM_USER + 12

Type TOOLINFO
     cbSize     As Long
     uFlags     As Long
     hWnd       As Long
     uId        As Long
     rectLeft   As Long
     rectTop    As Long
     RectRight  As Long
     RectBottom As Long
     hInst      As Long
     lpszText   As Long
     lParam     As Long
End Type

Type TOOLTIPTEXT
    hdr.hwndFrom As Long 
    hdr.idFrom   As Long 
    hdr.code     As Long
    lpszText     As Long 
    szText(80)   As Byte 
    hinst        As Long 
    uFlags       As Long
End Type

Const TTN_FIRST        = -520
Const TTN_GETDISPINFOA = (TTN_FIRST - 0)
CONST TTN_NEEDTEXT     = TTN_GETDISPINFOA

'''ToolBar
CONST TB_ENABLEBUTTON	= (WM_USER+1)
CONST TB_CHECKBUTTON	= (WM_USER+2)
CONST TB_PRESSBUTTON	= (WM_USER+3)
CONST TB_HIDEBUTTON	= (WM_USER+4)
CONST TB_INDETERMINATE	= (WM_USER+5)
CONST TB_ISBUTTONENABLED	= (WM_USER+9)
CONST TB_ISBUTTONCHECKED	= (WM_USER+10)
CONST TB_ISBUTTONPRESSED	= (WM_USER+11)
CONST TB_ISBUTTONHIDDEN	= (WM_USER+12)
CONST TB_ISBUTTONINDETERMINATE	= (WM_USER+13)
CONST TB_ISBUTTONHIGHLIGHTED	= (WM_USER+14)
CONST TB_SETSTATE	= (WM_USER+17)
CONST TB_GETSTATE	= (WM_USER+18)
CONST TB_ADDBITMAP	= (WM_USER+19)
CONST TB_ADDBUTTONS	= (WM_USER+20)
CONST TB_INSERTBUTTON	= (WM_USER+21)
CONST TB_DELETEBUTTON	= (WM_USER+22)
CONST TB_GETBUTTON	= (WM_USER+23)
CONST TB_BUTTONCOUNT	= (WM_USER+24)
CONST TB_COMMANDTOINDEX	= (WM_USER+25)
CONST TB_SAVERESTORE	= (WM_USER+26)
CONST TB_CUSTOMIZE	= (WM_USER+27)
CONST TB_ADDSTRING	= (WM_USER+28)
CONST TB_GETITEMRECT	= (WM_USER+29)
CONST TB_BUTTONSTRUCTSIZE	= (WM_USER+30)
CONST TB_SETBUTTONSIZE	= (WM_USER+31)
CONST TB_SETBITMAPSIZE	= (WM_USER+32)
CONST TB_AUTOSIZE	= (WM_USER+33)
CONST TB_GETTOOLTIPS	= (WM_USER+35)
CONST TB_SETTOOLTIPS	= (WM_USER+36)
CONST TB_SETPARENT	= (WM_USER+37)
CONST TB_SETROWS	= (WM_USER+39)
CONST TB_GETROWS	= (WM_USER+40)
CONST TB_GETBITMAPFLAGS	= (WM_USER+41)
CONST TB_SETCMDID	= (WM_USER+42)
CONST TB_CHANGEBITMAP	= (WM_USER+43)
CONST TB_GETBITMAP	= (WM_USER+44)
CONST TB_GETBUTTONTEXT	= (WM_USER+45)
CONST TB_REPLACEBITMAP	= (WM_USER+46)
CONST TB_GETBUTTONSIZE	= (WM_USER+58)
CONST TB_SETBUTTONWIDTH	= (WM_USER+59)
CONST TB_SETINDENT	= (WM_USER+47)
CONST TB_SETIMAGELIST	= (WM_USER+48)
CONST TB_GETIMAGELIST	= (WM_USER+49)
CONST TB_LOADIMAGES	= (WM_USER+50)
CONST TB_GETRECT	= (WM_USER+51)
CONST TB_SETHOTIMAGELIST	= (WM_USER+52)
CONST TB_GETHOTIMAGELIST	= (WM_USER+53)
CONST TB_SETDISABLEDIMAGELIST = (WM_USER+54)
CONST TB_GETDISABLEDIMAGELIST	= (WM_USER+55)
CONST TB_SETSTYLE	= (WM_USER+56)
CONST TB_GETSTYLE	= (WM_USER+57)
CONST TB_SETMAXTEXTROWS	= (WM_USER+60)
CONST TB_GETTEXTROWS	= (WM_USER+61)
CONST TB_GETOBJECT	= (WM_USER+62)
CONST TB_GETBUTTONINFO	= (WM_USER+65)
CONST TB_SETBUTTONINFO	= (WM_USER+66)
CONST TB_HITTEST	= (WM_USER+69)
CONST TB_SETEXTENDEDSTYLE	= (WM_USER+84)
CONST TB_GETEXTENDEDSTYLE	= (WM_USER+85)
CONST TB_SETDRAWTEXTFLAGS	= (WM_USER+70)
CONST TB_GETHOTITEM	= (WM_USER+71)
CONST TB_SETHOTITEM	= (WM_USER+72)
CONST TB_SETANCHORHIGHLIGHT	= (WM_USER+73)
CONST TB_GETANCHORHIGHLIGHT	= (WM_USER+74)
CONST TB_MAPACCELERATOR	= (WM_USER+78)
CONST TB_GETINSERTMARK	= (WM_USER+79)
CONST TB_SETINSERTMARK	= (WM_USER+80)
CONST TB_INSERTMARKHITTEST	= (WM_USER+81)
CONST TB_MOVEBUTTON		= (WM_USER+82)
CONST TB_GETMAXSIZE		= (WM_USER+83)
CONST TB_GETPADDING		= (WM_USER+86)
CONST TB_SETPADDING		= (WM_USER+87)
CONST TB_SETINSERTMARKCOLOR	= (WM_USER+88)
CONST TB_GETINSERTMARKCOLOR	= (WM_USER+89)
CONST TB_MAPACCELERATORW	= (WM_USER+90)
CONST TB_SETCOLORSCHEME	= CCM_SETCOLORSCHEME
CONST TB_GETCOLORSCHEME	= CCM_GETCOLORSCHEME
CONST TB_SETUNICODEFORMAT =	CCM_SETUNICODEFORMAT
CONST TB_GETUNICODEFORMAT =	CCM_GETUNICODEFORMAT
CONST TBBF_LARGE = 1
Const TBN_FIRST = (-700)
CONST TBN_GETBUTTONINFO	= (TBN_FIRST-0)
CONST TBN_BEGINDRAG	= (TBN_FIRST-1)
CONST TBN_ENDDRAG	= (TBN_FIRST-2)
CONST TBN_BEGINADJUST	= (TBN_FIRST-3)
CONST TBN_ENDADJUST	= (TBN_FIRST-4)
CONST TBN_RESET	= (TBN_FIRST-5)
CONST TBN_QUERYINSERT	= (TBN_FIRST-6)
CONST TBN_QUERYDELETE	= (TBN_FIRST-7)
CONST TBN_TOOLBARCHANGE	= (TBN_FIRST-8)
CONST TBN_CUSTHELP	= (TBN_FIRST-9)
CONST TBN_DROPDOWN	= (TBN_FIRST-10)
CONST TBN_HOTITEMCHANGE	= (TBN_FIRST-13)
CONST TBN_DRAGOUT	= (TBN_FIRST-14)
CONST TBN_DELETINGBUTTON	= (TBN_FIRST-15)
CONST TBN_GETDISPINFO	= (TBN_FIRST-16)
CONST TBN_GETINFOTIP	= (TBN_FIRST-18)
CONST TBN_GETBUTTONINFOW	= (TBN_FIRST-20)
CONST TBN_RESTORE	= (TBN_FIRST-21)
CONST TBN_SAVE	= (TBN_FIRST-22)
CONST TBN_INITCUSTOMIZE	= (TBN_FIRST-23)
Const TBNF_DI_SETITEM = &H10000000
Const TBNF_IMAGE = &H1
Const TBNF_TEXT = &H2
'Const TBNOTIFY = NMTOOLBAR
'Const TBNOTIFYA = NMTOOLBARA
'Const TBNOTIFYW = NMTOOLBARW
Const TBNRF_ENDCUSTOMIZE = &H2
Const TBNRF_HIDEHELP = &H1
Const TBS_AUTOTICKS = &H1
Const TBS_BOTH = &H8
Const TBS_BOTTOM = &H0
Const TBS_ENABLESELRANGE = &H20
Const TBS_FIXEDLENGTH = &H40
Const TBS_HORZ = &H0
Const TBS_LEFT = &H4
Const TBS_NOTHUMB = &H80
Const TBS_NOTICKS = &H10
Const TBS_REVERSED = &H200
Const TBS_RIGHT = &H0
Const TBS_TOOLTIPS = &H100
Const TBS_TOP = &H4
Const TBS_VERT = &H2
Const TBSTATE_CHECKED = &H1
Const TBSTATE_ELLIPSES = &H40
Const TBSTATE_ENABLED = &H4
Const TBSTATE_HIDDEN = &H8
Const TBSTATE_INDETERMINATE = &H10
Const TBSTATE_MARKED = &H80
Const TBSTATE_PRESSED = &H2
Const TBSTATE_WRAP = &H20
Const TBSTYLE_ALTDRAG = &H400
Const TBSTYLE_AUTOSIZE = &H10
Const TBSTYLE_BUTTON = &H0
Const TBSTYLE_CHECK = &H2
Const TBSTYLE_CUSTOMERASE = &H2000
Const TBSTYLE_DROPDOWN = &H8
Const TBSTYLE_EX_DOUBLEBUFFER = &H80
Const TBSTYLE_EX_DRAWDDARROWS = &H1
Const TBSTYLE_EX_HIDECLIPPEDBUTTONS = &H10
Const TBSTYLE_EX_MIXEDBUTTONS = &H8
Const TBSTYLE_FLAT = &H800
Const TBSTYLE_GROUP = &H4
Const TBSTYLE_CHECKGROUP = (TBSTYLE_GROUP Or TBSTYLE_CHECK)
Const TBSTYLE_LIST = &H1000
Const TBSTYLE_NOPREFIX = &H20
Const TBSTYLE_REGISTERDROP = &H4000
Const TBSTYLE_SEP = &H1
Const TBSTYLE_TOOLTIPS = &H100
Const TBSTYLE_TRANSPARENT = &H8000
Const TBSTYLE_WRAPABLE = &H200
Const TBTS_BOTTOM = 2
Const TBTS_LEFT = 1
Const TBTS_RIGHT = 3
Const TBTS_TOP = 0

type TBADDBITMAP 
   handle As Integer 
   nID    As Integer 
end type 

type TBBUTTON 
   iBitmap    As Integer 
   idCommand  As Integer 
   fsState    as byte
   fsStyle    as byte
   bReserved  as short
   dwData     As Integer 
   iString    As Integer 
end type 

Type TBNOTIFY
    hdr.hwndFrom        As Long 
    hdr.idFrom          As Long 
    hdr.code            As Long
    iItem               As Integer 
    tbButton.iBitmap    As Integer 
    tbButton.idCommand  As Integer 
    tbButton.fsState    as byte
    tbButton.fsStyle    as byte
    tbButton.bReserved  as short
    tbButton.dwData     As Integer 
    tbButton.iString    As Integer 
    cchText             As Integer 
    pszText             As Integer 
End Type

'''SysPager
Const PGF_CALCHEIGHT = 2
Const PGF_CALCWIDTH = 1
Const PGF_DEPRESSED = 4
Const PGF_GRAYED = 2
Const PGF_HOT = 8
Const PGF_INVISIBLE = 0
Const PGF_NORMAL = 1
Const PGF_SCROLLDOWN = 2
Const PGF_SCROLLLEFT = 4
Const PGF_SCROLLRIGHT = 8
Const PGF_SCROLLUP = 1
Const PGK_CONTROL = 2
Const PGK_MENU = 4
Const PGK_SHIFT = 1
Const PGM_FIRST = &H1400
Const PGM_FORWARDMOUSE = (PGM_FIRST + 3)
Const PGM_GETBKCOLOR = (PGM_FIRST + 5)
Const PGM_GETBORDER = (PGM_FIRST + 7)
Const PGM_GETBUTTONSIZE = (PGM_FIRST + 11)
Const PGM_GETBUTTONSTATE = (PGM_FIRST + 12)
Const PGM_GETDROPTARGET = CCM_GETDROPTARGET
Const PGM_GETPOS = (PGM_FIRST + 9)
Const PGM_RECALCSIZE = (PGM_FIRST + 2)
Const PGM_SETBKCOLOR = (PGM_FIRST + 4)
Const PGM_SETBORDER = (PGM_FIRST + 6)
Const PGM_SETBUTTONSIZE = (PGM_FIRST + 10)
Const PGM_SETCHILD = (PGM_FIRST + 1)
Const PGM_SETPOS = (PGM_FIRST + 8)
Const PGN_FIRST = (-900)
Const PGN_CALCSIZE = (PGN_FIRST-2)
Const PGN_HOTITEMCHANGE = (PGN_FIRST - 3)
Const PGN_LAST = (-950)
Const PGN_SCROLL = (PGN_FIRST-1)
Const PGS_AUTOSCROLL = &H2
Const PGS_DRAGNDROP = &H4
Const PGS_HORZ = &H1
Const PGS_VERT = &H0

'''UpDown
Const UD_MAXVAL	        = &h7fff
Const UD_MINVAL	        = (-UD_MAXVAL)
Const UDN_FIRST         = -721
Const UDN_DELTAPOS      = (UDN_FIRST-1)
Const UDS_WRAP	        = 1
Const UDS_SETBUDDYINT	= 2
Const UDS_ALIGNRIGHT	= 4
Const UDS_ALIGNLEFT	= 8
Const UDS_AUTOBUDDY	= 16
Const UDS_ARROWKEYS	= 32
Const UDS_HORZ          = 64
Const UDS_NOTHOUSANDS	= 128
Const UDS_HOTTRACK	= &h0100
Const UDM_SETRANGE	= (WM_USER+101)
Const UDM_GETRANGE	= (WM_USER+102)
Const UDM_SETPOS	= (WM_USER+103)
Const UDM_GETPOS	= (WM_USER+104)
Const UDM_SETBUDDY	= (WM_USER+105)
Const UDM_GETBUDDY	= (WM_USER+106)
Const UDM_SETACCEL	= (WM_USER+107)
Const UDM_GETACCEL	= (WM_USER+108)
Const UDM_SETBASE	= (WM_USER+109)
Const UDM_GETBASE	= (WM_USER+110)
Const UDM_SETRANGE32	= (WM_USER+111)
Const UDM_GETRANGE32	= (WM_USER+112)
Const UDM_SETPOS32	= (WM_USER+113)
Const UDM_GETPOS32	= (WM_USER+114)
Const UDM_SETUNICODEFORMAT	= CCM_SETUNICODEFORMAT
Const UDM_GETUNICODEFORMAT	= CCM_GETUNICODEFORMAT

Type NM_UPDOWNW 
    hdr.hwndFrom As Long 
    hdr.idFrom   As Long 
    hdr.code     As Long
    iPos         As Integer
    iDelta       As Integer
End Type

'''Animate
Const ACM_OPEN  = (WM_USER+100)
Const ACM_OPENW = (WM_USER+103)
Const ACM_PLAY  = (WM_USER+101)
Const ACM_STOP  = (WM_USER+102)
Const ACN_START       = 1
Const ACN_STOP        = 2
Const ACS_AUTOPLAY    = &H4
Const ACS_CENTER      = &H1
Const ACS_TIMER       = &H8
Const ACS_TRANSPARENT = &H2

'''StatusBar
Const SB_SETBKCOLOR = CCM_SETBKCOLOR
Const SB_SETICON = (WM_USER+15)
Const SB_SETMINHEIGHT = (WM_USER+8)
Const SB_SETPARTS = (WM_USER+4)
Const SB_SETTEXTA = (WM_USER+1)
Const SB_SETTEXTW = (WM_USER+11)
Const SB_SETTIPTEXTA = (WM_USER+16)
Const SB_SETTIPTEXTW = (WM_USER+17)
Const SB_SETUNICODEFORMAT = CCM_SETUNICODEFORMAT
Const SB_SIMPLE = (WM_USER+9)

Const SBT_NOBORDERS = &H100
Const SBT_NOTABPARSING = &H800
Const SBT_OWNERDRAW = &H1000
Const SBT_POPOUT = &H200
Const SBT_RTLREADING = &H400
Const SBT_TOOLTIPS = &H800

