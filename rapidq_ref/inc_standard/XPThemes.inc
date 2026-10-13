$IFNDEF __XPTHEMES_INC   ' IncManager: include guard
$DEFINE __XPTHEMES_INC
$DEFINE __XPTHEME
$IFNDEF __WIN32API

Const TRANSPARENT        = 1
Const DT_CENTER          = &H1
Const GWL_EXSTYLE        = -20
Const GWL_STYLE          = -16
Const GWL_WNDPROC        = (-4)
Const SWP_FRAMECHANGED   = &H20
Const WM_NCPAINT         = &H85
Const WM_PAINT           = &HF
Const WS_EX_CLIENTEDGE   = &H200
Const WS_BORDER          = &H800000
Const SWP_NOSIZE         = &H1
Const SWP_NOMOVE         = &H2
Const SWP_NOZORDER       = &H4
Const SWP_NOREDRAW       = &H8
Const SWP_NOACTIVATE     = &H10
  '
Const SWP_SHOWWINDOW     = &H40
Const SWP_HIDEWINDOW     = &H80
Const SWP_NOCOPYBITS     = &H100
Const SWP_NOOWNERZORDER  = &H200
Const SWP_NOSENDCHANGING = &H400
Const SWP_DRAWFRAME      = SWP_FRAMECHANGED
Const SWP_NOREPOSITION   = SWP_NOOWNERZORDER

Type LOGFONT
     lfHeight         As Long
     lfWidth          As Long
     lfEscapement     As Long
     lfOrientation    As Long
     lfWeight         As Long
     lfItalic         As Byte
     lfUnderline      As Byte
     lfStrikeOut      As Byte
     lfCharSet        As Byte
     lfOutPrecision   As Byte
     lfClipPrecision  As Byte
     lfQuality        As Byte
     lfPitchAndFamily As Byte
     lfFaceName       As String * 32
End Type

Type RECT
    Left   As Long
    Top    As Long
    Right  As Long
    Bottom As Long
End Type

Type SIZE
     cx As Long
     cy As Long
End Type

Declare Function CreateFontIndirect Lib "gdi32" Alias "CreateFontIndirectA" (lpLogFont As LOGFONT) As Long
Declare Function DrawText Lib "user32" Alias "DrawTextA" (hDC As Long, lpStr As String, nCount As Long, lpRect As RECT, wFormat As Long) As Long
Declare Function ExcludeClipRect Lib "gdi32" Alias "ExcludeClipRect" (hDC As Long, Left As Long, Top As Long, Right As Long, Bottom As Long) As Long
Declare Function FillRect Lib "user32" Alias "FillRect" (hDC As Long, lpRect As RECT, hBrush As Long) As Long
Declare Function FrameRect Lib "user32" Alias "FrameRect" (hDC As Long, lpRect As RECT, hBrush As Long) As Long
Declare Function GetTextExtentPoint32 Lib "gdi32" Alias "GetTextExtentPoint32A" (hDC As Long, lpsz As String, cbString As Long, lpSize As SIZE) As Long
Declare Function GetVersion Lib "kernel32" Alias "GetVersion" () As Long
Declare Function GetWindowDC Lib "user32" Alias "GetWindowDC" (hWnd As Long) As Long
Declare Function SetTextColor Lib "gdi32" Alias "SetTextColor" (hDC As Long, crColor As Long) As Long
Declare Function CallWindowProc Lib "user32" Alias "CallWindowProcA" (ByVal lpPrevWndFunc As Long, ByVal hWnd As Long, ByVal Msg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
Declare Function SetWindowLong Lib "user32" Alias "SetWindowLongA" (ByVal hwnd As Long, ByVal nIndex As Long, ByVal dwNewLong As Long) As Long
Declare Function GetWindowLong Lib "user32" Alias "GetWindowLongA" (ByVal hwnd As Long, ByVal nIndex As Long) As Long
Declare Function SetWindowPos Lib "user32" Alias "SetWindowPos" (ByVal hwnd As Long, ByVal hWndInsertAfter As Long, ByVal x As Long, ByVal y As Long, ByVal cx As Long, ByVal cy As Long, ByVal wFlags As Long) As Long
Declare Function GetWindowRect Lib "user32" Alias "GetWindowRect" (ByVal hwnd As Long, lpRect As RECT) As Long
Declare Function CreateSolidBrush Lib "gdi32" Alias "CreateSolidBrush" (ByVal crColor As Long) As Long
Declare Function DeleteObject Lib "gdi32" Alias "DeleteObject" (ByVal hObject As Long) As Long
Declare Function SelectObject Lib "gdi32" Alias "SelectObject" (ByVal hdc As Long, ByVal hObject As Long) As Long
Declare Function GetSysColor Lib "user32" Alias "GetSysColor" (ByVal nIndex As Long) As Long
Declare Function SetBkMode Lib "gdi32" Alias "SetBkMode" (ByVal hdc As Long, ByVal nBkMode As Long) As Long

$ENDIF

$IFNDEF __RQCALLBACKS
        $INCLUDE "Callbacks.inc"
$ENDIF

Const BP_GROUPBOX     = &H4
Const TMT_BORDERCOLOR = &HED9
Const TMT_TEXTCOLOR   = &HEDB
Const TMT_MENUFONT    = &H323

Type MARGINS
     cxLeftWidth    As Long
     cxRightWidth   As Long
     cyTopHeight    As Long
     cyBottomHeight As Long
End Type

Declare Function CloseThemeData Lib "uxtheme" Alias "CloseThemeData" (hTheme As Long) As Long
Declare Function DrawThemeBackground Lib "uxtheme" Alias "DrawThemeBackground" (hTheme As Long, hDC As Long, iPartId As Long, iStateId As Long, pRect As RECT, pClipRect As RECT) As Long
Declare Function DrawThemeParentBackground Lib "uxtheme" Alias "DrawThemeParentBackground" (hWnd As Long, hDC As Long, prc As RECT) As Long
Declare Function GetThemeInt Lib "uxtheme" Alias "GetThemeInt" (hTheme As Long, iPartId As Long, iStateId As Long, iPropId As Long, piVal As Long) As Long
Declare Function GetThemeSysFont Lib "uxtheme" Alias "GetThemeSysFont" (hTheme As Long, iFontID As Long, plf As LOGFONT) As Long
Declare Function OpenThemeData Lib "uxtheme" Alias "OpenThemeData" (hWnd As Long, pszClAssList As String) As Long


TYPE QRichEditUx EXTENDS QRICHEDIT
  PRIVATE:
  ptrOldProc  AS LONG
  ptrWndProc  AS LONG
  Subclassed  AS LONG
  WITH QRichEditUx
  FUNCTION WndProc (hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG, CBindex AS LONG) AS LONG
    IF hWnd = .Handle THEN
      Result = CallWindowProc(.ptrOldProc, hWnd, uMsg, wParam, lParam)
      DEFLNG hTheme, hDC, hBrush, BorderColor, Style, ExStyle
      DIM R AS RECT
      IF uMsg = WM_NCPAINT THEN
        ' Open theme data for EDIT
        hTheme = OpenThemeData(hWnd,"E"+CHR$(0)+"D"+CHR$(0)+"I"+CHR$(0)+"T"+CHR$(0)+CHR$(0)+CHR$(0))
        IF hTheme THEN
          ' Get border color
          GetThemeInt(hTheme, 1, 1, TMT_BORDERCOLOR, @BorderColor)
          CloseThemeData(hTheme)
          ' Check if we have 98/2000 style border
          ExStyle = GetWindowLong(hWnd, GWL_EXSTYLE)
          IF ExStyle AND WS_EX_CLIENTEDGE THEN
            ' Remove ClientEdge border
            SetWindowLong(hWnd, GWL_EXSTYLE, ExStyle AND (NOT WS_EX_CLIENTEDGE))
            ' Add single line black border
            SetWindowLong(hWnd, GWL_STYLE, GetWindowLong(hWnd, GWL_STYLE) OR WS_BORDER)
            ' Ask it to resize its client area
            SetWindowPos(hWnd,0,0,0,0,0,SWP_FRAMECHANGED OR SWP_NOACTIVATE OR SWP_NOMOVE OR SWP_NOSIZE OR SWP_NOZORDER)
          END IF
          hDC = GetWindowDC(hWnd)
          GetWindowRect(hWnd, R)
          R.Right  = R.Right  - R.Left
          R.Bottom = R.Bottom - R.Top
          R.Top  = 0
          R.Left = 0
          hBrush = CreateSolidBrush(BorderColor)
          SelectObject(hDC, hBrush)
          ' Draw over black border with proper color
          FrameRect(hDC, R, hBrush)
          DeleteObject(hBrush)
        ELSE  ' In "Classic" mode
          ' Check if we have XP style border
          Style = GetWindowLong(hWnd, GWL_STYLE)
          IF Style AND WS_BORDER THEN
            ' Remove single line border
            SetWindowLong(hWnd, GWL_STYLE, Style AND (NOT WS_BORDER))
            ' Add ClientEdge border
            SetWindowLong(hWnd, GWL_EXSTYLE, GetWindowLong(hWnd, GWL_EXSTYLE) OR WS_EX_CLIENTEDGE)
            ' Ask it to resize its client area
            SetWindowPos(hWnd,0,0,0,0,0,SWP_FRAMECHANGED OR SWP_NOACTIVATE OR SWP_NOMOVE OR SWP_NOSIZE OR SWP_NOZORDER)
          END IF
        END IF
      END IF
    END IF
  END FUNCTION
  PUBLIC:
  SUB Subclass()
    DEFINT F4
    IF ((GetVersion AND 255) + (GetVersion AND &HFF00) / 25600) >= 5.01 THEN
      IF .Handle AND NOT .Subclassed THEN
        BIND F4 TO This.WndProc
        .ptrWndProc = SetNewCallBack_4(F4)
        .ptrOldProc = SetWindowLong(QRichEditUx.Handle,GWL_WNDPROC,.ptrWndProc)
        .Subclassed = 1
      END IF
    END IF
  END SUB
  END WITH
  CONSTRUCTOR
    Subclassed = 0
  END CONSTRUCTOR
END TYPE

TYPE QScrollBoxUx EXTENDS QSCROLLBOX
  PRIVATE:
  ptrOldProc  AS LONG
  ptrWndProc  AS LONG
  Subclassed  AS LONG
  WITH QScrollBoxUx
  FUNCTION WndProc (hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG, CBindex AS LONG) AS LONG
    IF hWnd = .Handle THEN
      Result = CallWindowProc(.ptrOldProc, hWnd, uMsg, wParam, lParam)
      DEFLNG hTheme, hDC, hBrush, BorderColor, Style, ExStyle
      DIM R AS RECT
      IF uMsg = WM_NCPAINT THEN
        ' Open theme data for EDIT
        hTheme = OpenThemeData(hWnd,"E"+CHR$(0)+"D"+CHR$(0)+"I"+CHR$(0)+"T"+CHR$(0)+CHR$(0)+CHR$(0))
        IF hTheme THEN
          ' Get border color
          GetThemeInt(hTheme, 1, 1, TMT_BORDERCOLOR, @BorderColor)
          CloseThemeData(hTheme)
          ' Check if we have 98/2000 style border
          ExStyle = GetWindowLong(hWnd, GWL_EXSTYLE)
          IF ExStyle AND WS_EX_CLIENTEDGE THEN
            ' Remove ClientEdge border
            SetWindowLong(hWnd, GWL_EXSTYLE, ExStyle AND (NOT WS_EX_CLIENTEDGE))
            ' Add single line black border
            SetWindowLong(hWnd, GWL_STYLE, GetWindowLong(hWnd, GWL_STYLE) OR WS_BORDER)
            ' Ask it to resize its client area
            SetWindowPos(hWnd,0,0,0,0,0,SWP_FRAMECHANGED OR SWP_NOACTIVATE OR SWP_NOMOVE OR SWP_NOSIZE OR SWP_NOZORDER)
          END IF
          hDC = GetWindowDC(hWnd)
          GetWindowRect(hWnd, R)
          R.Right  = R.Right  - R.Left
          R.Bottom = R.Bottom - R.Top
          R.Top  = 0
          R.Left = 0
          hBrush = CreateSolidBrush(BorderColor)
          SelectObject(hDC, hBrush)
          ' Draw over black border with proper color
          FrameRect(hDC, R, hBrush)
          DeleteObject(hBrush)
        ELSE  ' In "Classic" mode
          ' Check if we have XP style border
          Style = GetWindowLong(hWnd, GWL_STYLE)
          IF Style AND WS_BORDER THEN
            ' Remove single line border
            SetWindowLong(hWnd, GWL_STYLE, Style AND (NOT WS_BORDER))
            ' Add ClientEdge border
            SetWindowLong(hWnd, GWL_EXSTYLE, GetWindowLong(hWnd, GWL_EXSTYLE) OR WS_EX_CLIENTEDGE)
            ' Ask it to resize its client area
            SetWindowPos(hWnd,0,0,0,0,0,SWP_FRAMECHANGED OR SWP_NOACTIVATE OR SWP_NOMOVE OR SWP_NOSIZE OR SWP_NOZORDER)
          END IF
        END IF
      END IF
    END IF
  END FUNCTION
  PUBLIC:
  SUB Subclass()
    DEFINT F4
    IF ((GetVersion AND 255) + (GetVersion AND &HFF00) / 25600) >= 5.01 THEN ' OS >= XP
      IF .Handle AND NOT .Subclassed THEN
        BIND F4 TO This.WndProc
        .ptrWndProc = SetNewCallBack_4(F4)
        .ptrOldProc = SetWindowLong(.Handle,GWL_WNDPROC,.ptrWndProc)
        .Subclassed = 1
      END IF
    END IF
  END SUB
  END WITH
  CONSTRUCTOR
    Subclassed = 0
  END CONSTRUCTOR
END TYPE

TYPE QStringGridUx EXTENDS QStringGrid
  PRIVATE:
  ptrOldProc  AS LONG
  ptrWndProc  AS LONG
  Subclassed  AS LONG
  WITH QStringGridUx
  FUNCTION WndProc (hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG, CBindex AS LONG) AS LONG
    IF hWnd = .Handle THEN
      Result = CallWindowProc(.ptrOldProc, hWnd, uMsg, wParam, lParam)
      DEFLNG hTheme, hDC, hBrush, BorderColor, Style, ExStyle
      DIM R AS RECT
      IF uMsg = WM_NCPAINT THEN
        ' Open theme data for EDIT
        hTheme = OpenThemeData(hWnd,"E"+CHR$(0)+"D"+CHR$(0)+"I"+CHR$(0)+"T"+CHR$(0)+CHR$(0)+CHR$(0))
        IF hTheme THEN
          ' Get border color
          GetThemeInt(hTheme, 1, 1, TMT_BORDERCOLOR, @BorderColor)
          CloseThemeData(hTheme)
          ' Check if we have 98/2000 style border
          ExStyle = GetWindowLong(hWnd, GWL_EXSTYLE)
          IF ExStyle AND WS_EX_CLIENTEDGE THEN
            ' Remove ClientEdge border
            SetWindowLong(hWnd, GWL_EXSTYLE, ExStyle AND (NOT WS_EX_CLIENTEDGE))
            ' Add single line black border
            SetWindowLong(hWnd, GWL_STYLE, GetWindowLong(hWnd, GWL_STYLE) OR WS_BORDER)
            ' Ask it to resize its client area
            SetWindowPos(hWnd,0,0,0,0,0,SWP_FRAMECHANGED OR SWP_NOACTIVATE OR SWP_NOMOVE OR SWP_NOSIZE OR SWP_NOZORDER)
          END IF
          hDC = GetWindowDC(hWnd)
          GetWindowRect(hWnd, R)
          R.Right  = R.Right  - R.Left
          R.Bottom = R.Bottom - R.Top
          R.Top  = 0
          R.Left = 0
          hBrush = CreateSolidBrush(BorderColor)
          SelectObject(hDC, hBrush)
          ' Draw over black border with proper color
          FrameRect(hDC, R, hBrush)
          DeleteObject(hBrush)
        ELSE  ' In "Classic" mode
          ' Check if we have XP style border
          Style = GetWindowLong(hWnd, GWL_STYLE)
          IF Style AND WS_BORDER THEN
            ' Remove single line border
            SetWindowLong(hWnd, GWL_STYLE, Style AND (NOT WS_BORDER))
            ' Add ClientEdge border
            SetWindowLong(hWnd, GWL_EXSTYLE, GetWindowLong(hWnd, GWL_EXSTYLE) OR WS_EX_CLIENTEDGE)
            ' Ask it to resize its client area
            SetWindowPos(hWnd,0,0,0,0,0,SWP_FRAMECHANGED OR SWP_NOACTIVATE OR SWP_NOMOVE OR SWP_NOSIZE OR SWP_NOZORDER)
          END IF
        END IF
      END IF
    END IF
  END FUNCTION
  PUBLIC:
  SUB Subclass()
    DEFINT F4
    IF ((GetVersion AND 255) + (GetVersion AND &HFF00) / 25600) >= 5.01 THEN ' OS >= XP
      IF .Handle AND NOT .Subclassed THEN
        BIND F4 TO This.WndProc
        .ptrWndProc = SetNewCallBack_4(F4)
        .ptrOldProc = SetWindowLong(.Handle,GWL_WNDPROC,.ptrWndProc)
        .Subclassed = 1
      END IF
    END IF
  END SUB
  END WITH
  CONSTRUCTOR
    Subclassed = 0
  END CONSTRUCTOR
END TYPE

TYPE QPanelUx EXTENDS QPanel
  PRIVATE:
  ptrOldProc  AS LONG
  ptrWndProc  AS LONG
  Subclassed  AS LONG
  WITH QPanelUx
  FUNCTION WndProc (hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG, CBindex AS LONG) AS LONG
    IF hWnd = .Handle THEN
      Result = CallWindowProc(.ptrOldProc, hWnd, uMsg, wParam, lParam)
      DEFLNG hTheme, hDC, hBrush, BorderColor, Style, ExStyle
      DIM R AS RECT
      IF uMsg = WM_NCPAINT THEN
        ' Open theme data for EDIT
        hTheme = OpenThemeData(hWnd,"E"+CHR$(0)+"D"+CHR$(0)+"I"+CHR$(0)+"T"+CHR$(0)+CHR$(0)+CHR$(0))
        IF hTheme THEN
          ' Get border color
          GetThemeInt(hTheme, 1, 1, TMT_BORDERCOLOR, @BorderColor)
          CloseThemeData(hTheme)
          ' Check if we have 98/2000 style border
          ExStyle = GetWindowLong(hWnd, GWL_EXSTYLE)
          IF ExStyle AND WS_EX_CLIENTEDGE THEN
            ' Remove ClientEdge border
            SetWindowLong(hWnd, GWL_EXSTYLE, ExStyle AND (NOT WS_EX_CLIENTEDGE))
            ' Add single line black border
            SetWindowLong(hWnd, GWL_STYLE, GetWindowLong(hWnd, GWL_STYLE) OR WS_BORDER)
            ' Ask it to resize its client area
            SetWindowPos(hWnd,0,0,0,0,0,SWP_FRAMECHANGED OR SWP_NOACTIVATE OR SWP_NOMOVE OR SWP_NOSIZE OR SWP_NOZORDER)
          END IF
          hDC = GetWindowDC(hWnd)
          GetWindowRect(hWnd, R)
          R.Right  = R.Right  - R.Left
          R.Bottom = R.Bottom - R.Top
          R.Top  = 0
          R.Left = 0
          hBrush = CreateSolidBrush(BorderColor)
          SelectObject(hDC, hBrush)
          ' Draw over black border with proper color
          FrameRect(hDC, R, hBrush)
          DeleteObject(hBrush)
        ELSE  ' In "Classic" mode
          ' Check if we have XP style border
          Style = GetWindowLong(hWnd, GWL_STYLE)
          IF Style AND WS_BORDER THEN
            ' Remove single line border
            SetWindowLong(hWnd, GWL_STYLE, Style AND (NOT WS_BORDER))
            ' Add ClientEdge border
            SetWindowLong(hWnd, GWL_EXSTYLE, GetWindowLong(hWnd, GWL_EXSTYLE) OR WS_EX_CLIENTEDGE)
            ' Ask it to resize its client area
            SetWindowPos(hWnd,0,0,0,0,0,SWP_FRAMECHANGED OR SWP_NOACTIVATE OR SWP_NOMOVE OR SWP_NOSIZE OR SWP_NOZORDER)
          END IF
        END IF
      END IF
    END IF
  END FUNCTION
  PUBLIC:
  SUB Subclass()
    DEFINT F4
    IF ((GetVersion AND 255) + (GetVersion AND &HFF00) / 25600) >= 5.01 THEN ' OS >= XP
      IF .Handle AND NOT .Subclassed THEN
        BIND F4 TO This.WndProc
        .ptrWndProc = SetNewCallBack_4(F4)
        .ptrOldProc = SetWindowLong(.Handle,GWL_WNDPROC,.ptrWndProc)
        .Subclassed = 1
      END IF
    END IF
  END SUB
  END WITH
  CONSTRUCTOR
    Subclassed = 0
  END CONSTRUCTOR
END TYPE

TYPE QGroupBoxUx EXTENDS QGROUPBOX
  PRIVATE:
  ptrOldProc  AS LONG
  ptrWndProc  AS LONG
  Subclassed  AS LONG
  WITH QGroupBoxUx
  FUNCTION WndProc (hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG, CBindex AS LONG) AS LONG
    DEFLNG hTheme, hDC, hBrush, hFont, TextColor, RetVal
    DIM BGRect     AS RECT
    DIM BorderRect AS RECT
    DIM ClientRect AS RECT
    DIM TextRect   AS RECT
    DIM TextSize   AS SIZE
    DIM Margs      AS MARGINS
    DIM LF         AS LOGFONT
    IF hWnd = .Handle THEN
      Result = CallWindowProc(.ptrOldProc, hWnd, uMsg, wParam, lParam)
      IF uMsg = WM_PAINT OR uMsg = WM_NCPAINT THEN
        hTheme = OpenThemeData(hWnd,"B"+CHR$(0)+"U"+CHR$(0)+"T"+CHR$(0)+"T"+CHR$(0)+"O"+CHR$(0)+"N"+CHR$(0)+CHR$(0)+CHR$(0))
        IF hTheme THEN
          hDC = GetWindowDC(hWnd)
          GetWindowRect(hWnd, BGRect)
          BGRect.Right  = BGRect.Right - BGRect.Left
          BGRect.Bottom = BGRect.Bottom - BGRect.Top
          BGRect.Top  = 0
          BGRect.Left = 0
          ' Create a suitable font for the caption
          GetThemeSysFont(hTheme, TMT_MENUFONT, LF)
          LF.lfWeight = 0
          hFont = CreateFontIndirect(LF)
          SelectObject(hDC, hFont)
          ' Get the caption color
          GetThemeInt(hTheme, BP_GROUPBOX, 1, TMT_TEXTCOLOR, @TextColor)
          SetTextColor(hDC, TextColor)
          ' Get the font size
          GetTextExtentPoint32(hDC, "Xp", 2, TextSize)
          ' Erase old style BG
          BorderRect.Left   = 0
          BorderRect.Right  = BGRect.Right
          BorderRect.Bottom = BGRect.Bottom
          BorderRect.Top    = TextSize.cy \ 2
          ClientRect.Left   = 4
          ClientRect.Right  = BGRect.Right - 4
          ClientRect.Top    = TextSize.cy + 2
          ClientRect.Bottom = BGRect.Bottom - 4
          ExcludeClipRect(hDC, ClientRect.Left, ClientRect.Top, ClientRect.Right, ClientRect.Bottom)
          DrawThemeParentBackground(hWnd, hDC, BGRect)
          ' Draw XP style border
          DrawThemeBackground(hTheme, hDC, BP_GROUPBOX, 1, BorderRect, BorderRect)
          CloseThemeData(hTheme)
          IF .Caption <> "" THEN
            ' Draw caption BG
            GetTextExtentPoint32(hDC, .Caption, LEN(.Caption) + 1, TextSize)
            TextRect.Top    = 0
            TextRect.Left   = 7
            TextRect.Right  = TextRect.Left + TextSize.cx
            TextRect.Bottom = TextSize.cy
            hBrush = CreateSolidBrush(GetSysColor(15))
            SelectObject(hDC, hBrush)
            FillRect(hDC, TextRect, hBrush)
            DeleteObject(hBrush)
            ' Draw new caption
            SetBkMode(hDC, TRANSPARENT)
            DrawText(hDC, .Caption, LEN(.Caption), TextRect, DT_CENTER)
          END IF
          DeleteObject(hFont)
        END IF
      END IF
    END IF
  END FUNCTION
  PUBLIC:
  SUB Subclass()
    DEFINT F4
    IF ((GetVersion AND 255) + (GetVersion AND &HFF00) / 25600) >= 5.01 THEN ' OS >= XP
      IF .Handle AND NOT .Subclassed THEN
        BIND F4 TO This.WndProc
        .ptrWndProc = SetNewCallBack_4(F4)
        .ptrOldProc = SetWindowLong(.Handle,GWL_WNDPROC,.ptrWndProc)
        .Subclassed = 1
      END IF
    END IF
  END SUB
  END WITH
  CONSTRUCTOR
    Subclassed = 0
  END CONSTRUCTOR
END TYPE


$ENDIF   ' IncManager: __XPTHEMES_INC
