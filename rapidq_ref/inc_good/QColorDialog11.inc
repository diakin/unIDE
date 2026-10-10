'=======================================================
' Type Objet
' Classe QColorDialog version 1.1
'=======================================================
$IFNDEF TRUE
$DEFINE True 1
$ENDIF

$IFNDEF FALSE
$DEFINE False 0
$ENDIF

CONST CC_RGBINIT=&H1
CONST CC_FULLOPEN=&H2
CONST CC_ENABLEHOOK=&H10
CONST CC_PREVENTFULLOPEN=&H4
CONST WM_INITDIALOG=&H110
CONST SWP_NOSIZE=&H1
CONST SWP_NOACTIVATE=&H10
CONST cdNormal=0
CONST cdFullOpen=1
CONST cdNoFullOpen=2

TYPE TCHOOSECOLOR
  lStructSize AS LONG
  hWndOwner AS LONG
  hInstance AS LONG
  rgbResult AS LONG
  CustColors(1 TO 16) AS LONG
  Flags AS DWORD
  lCustData AS LONG
  lpfnHook AS LONG
  lpTemplateName AS LONG
END TYPE

DECLARE FUNCTION ChooseColorDlg LIB "COMDLG32" ALIAS "ChooseColorA" (CC AS TCHOOSECOLOR) AS LONG
DECLARE FUNCTION GetCdRect LIB "user32" ALIAS "GetWindowRect" (hwnd AS LONG, lpRect AS QRECT) AS LONG
DECLARE FUNCTION MoveCd LIB "user32" ALIAS "MoveWindow" (hwnd AS LONG,x AS LONG,y AS LONG,nWidth AS LONG,nHeight AS LONG,bRepaint AS LONG) AS LONG
DECLARE FUNCTION SetCdText LIB "user32" ALIAS "SetWindowTextA" (hWnd AS LONG,ByRef lpString AS STRING) AS LONG

TYPE QCOLORDIALOG EXTENDS QOBJECT
  PRIVATE:
  CC AS TCHOOSECOLOR
  PUBLIC:
  Caption as string
  Color as long
  Colors(1 TO 16) as long
  Style as long

  WITH QCOLORDIALOG

    Function HookProc(hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
      dim R as QRECT

      if uMsg=WM_INITDIALOG then  ' all initializing is done inside
        GetCdRect(hWnd,R)    ' this if-then statement
        MoveCd(hWnd,((Screen.Width-(R.Right-R.Left))/2),((Screen.Height-(R.Bottom-R.Top))/2),(R.Right-R.Left),(R.Bottom-R.Top),0)
        if LEN(.Caption) then
          SetCdText(hWnd,.Caption)
        end if
        Result=true
      else
        Result=false
      end if
    End Function

    '==========================================
    ' Mйthode affichage boite dialogue couleur
    '==========================================
    Function Execute AS LONG
      dim i as long

      .CC.lStructSize=SIZEOF(QCOLORDIALOG.CC)
      .CC.hWndOwner=Application.Handle
      .CC.RGBResult=.Color
      for i=1 to 16
        .CC.CustColors(i)=.Colors(i)
      next i
      .CC.Flags=CC_RGBINIT
      if .Caption<>"" then .CC.Flags=.CC.Flags OR CC_ENABLEHOOK
      Select Case .Style
      case cdFullOpen
        .CC.Flags =.CC.Flags OR CC_FULLOPEN
      case cdNoFullOpen
        .CC.Flags =.CC.Flags OR CC_PREVENTFULLOPEN
      End Select
      if .Caption<>"" then .CC.lpfnHook=CODEPTR(QCOLORDIALOG.HookProc)
      if ChooseColorDlg(.CC) <> 0 then
        for i=1 to 16
          .Colors(i)=.CC.CustColors(i)
        next i
        .Color=.CC.RGBResult
        Result=true
      else
        Result=false
      end if
    End Function

    CONSTRUCTOR
    Caption=""
    Colors(1)=&H0
    Colors(2)=&H808080
    Colors(3)=&H000080
    Colors(4)=&H008080
    Colors(5)=&H008000
    Colors(6)=&H808000
    Colors(7)=&H800000
    Colors(8)=&H800080
    Colors(9)=&HFFFFFF
    Colors(10)=&HC0C0C0
    Colors(11)=&H0000FF
    Colors(12)=&H00FFFF
    Colors(13)=&H00FF00
    Colors(14)=&HFFFF00
    Colors(15)=&HFF0000
    Colors(16)=&HFF00FF
  END CONSTRUCTOR

END WITH
END TYPE

