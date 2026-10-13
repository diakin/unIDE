$IFNDEF __QFORMLOCALE_INC   ' IncManager: include guard
$DEFINE __QFORMLOCALE_INC
'''    Name: QFormLocale (.inc)
'''  Author: David Burkley
'''   Email: burkleyd@yahoo.com
'''    Date: December 13th, 2006
'''
''' You can "not" distribute this source code
''' without asking and receiving verifiable
''' permission from myself. If I do give
''' permission... this entire header must
''' remain intacted with this source code.
'''
''' You may "freely" use this source code for
''' "non-profitable" programs only.
''' For programs "other than" non-profitable,
''' it "can not" be used until a verifiable
''' monetary compensation has been agreed upon.
'''
''' If you do make use of this source code in
''' your "non-profitable" program... all I ask
''' in return is... please give credit, where
''' credit is due. You can do this by simply
''' mentioning to your end-users (perhaps in
''' an "About" menu option), my name, my email
''' address, and my website.

'' I apologize if there's insufficient comments.
'' If you need specific information about the
'' code below... please contact me via email
'' with the word "RapidQ" in the subject line.
'' (emails without it, get deleted automatically)

' This function actually has 2 uses. Please read the following to discover them.
'
' The first use would be to... call this function, within a subroutine for a QForm
' OnShow event, and pass the name of the form, the desired width, and the desired height
' and it'll place your program's window in the top left corner of the end-user's screen
' (provided you "did not" use the QForm's Center method in your code) at the size you
' specified.
' If the end-user's Taskbar is located at the top (or on the left side) of the screen...
' your program will adjust itself down (or right) so that the TaskBar is still showing.
' Note: this only works if the end-user's Taskbar is not set up to hide when it's inactive.
' If the call to the API function SHAppBarMessage fails... then this function will fail too.
' So you'll need code to compensate for this kind of failure in your OnShow event subroutine.
'
' If you wish to avoid a repeat of this function every time your program starts up...
' you need to do 2 things. 1) Write coding to store your program's window size and
' location in an ".ini" file when it closes and then read that ".ini" file when it starts
' up again. 2) Add to your coding a conditional "If/Then" statement to ONLY call this
' function... if the ".ini" file is tainted or missing.
'
' If the width and height parameters passed, are "bigger than" the end-user's actual screen
' size OR are passed as 0 (zero)... it'll default to a maximized window with the Taskbar
' still showing. But... the maximize button will be in an "incorrect state". So you really
' should try to avoid this kind of situation by passing the width and height parameters
' that are within a reasonable size during the OnShow event subroutine.
'
' The second use would be to... do a conditional "If/Then" statement, within a subroutine
' for a QForm OnResize event, to call this function if the QForm's WindowState is equal
' to wsMaximized. If you pass the width and height parameters as 0 (zero) AND the size
' of your program's window is smaller than the actual screen size... your program will
' then be maximized with the end-user's Taskbar will still be showing and the maximize
' button will be in the "correct state".
'

' Define some variables and assign a value to them.
' For use with SHAppBarMessage.
$IFNDEF ABM_GETTASKBARPOS
  $DEFINE ABM_GETTASKBARPOS &H5
$ENDIF
$IFNDEF ABE_LEFT
  $DEFINE ABE_LEFT 0
$ENDIF
$IFNDEF ABE_TOP
  $DEFINE ABE_TOP 1
$ENDIF
$IFNDEF ABE_RIGHT
  $DEFINE ABE_RIGHT 2
$ENDIF
$IFNDEF ABE_BOTTOM
  $DEFINE ABE_BOTTOM 3
$ENDIF

' Define some variables and assign a value to them.
' For use with GetSystemMetrics.
$IFNDEF SM_CXSCREEN
  $DEFINE SM_CXSCREEN 0
$ENDIF
$IFNDEF SM_CYSCREEN
  $DEFINE SM_CYSCREEN 1
$ENDIF

' Create a block of data (known as a Type).
' For use with SHAppBarMessage.
Type APPBARDATA
  cbSize As Long
  hWnd As Long
  uCallbackMessage As Long
  uEdge As Long
  Left As Long
  Top As Long
  Right As Long
  Bottom As Long
  lParam As Long 
End Type

' Declare the 2 needed API functions.
' Renamed the original function name, just in case it's used elsewhere.
Declare Function FL_SHAppBarMessage Lib "shell32" Alias "SHAppBarMessage" (ByVal dwMessage As Long, pData As APPBARDATA) As Long
Declare Function FL_GetSystemMetrics Lib "user32" Alias "GetSystemMetrics" (ByVal nIndex As Long) As Long

' Call this function to initially display your form or when it's been maximized.
Function FormLocale (AppForm As QForm, AppWidth As Integer, AppHeight As Integer) As Long
  Dim ABD As APPBARDATA
  Dim FL_lRet As Long
  Dim tbWidth As Long  ' tb is short for Taskbar
  Dim ScrnWidth As Integer
  Dim ScrnHeight As Integer
  ABD.cbSize = SizeOf(ABD)
  FL_lRet = FL_SHAppBarMessage(ABM_GETTASKBARPOS, ABD)
  ' FL_lRet will contain a value if the above call succeeded.
  ' Most likely cause for it to fail will be... because the
  ' end-users Taskbar is set to hide when it's inactive.
  If FL_lRet Then
    tbWidth = ABD.Right - ABD.Left
    ScrnWidth = FL_GetSystemMetrics(SM_CXSCREEN)
    ScrnHeight = FL_GetSystemMetrics(SM_CYSCREEN)
    If AppWidth = 0 Then AppWidth = ScrnWidth
    If AppHeight = 0 Then AppHeight = ScrnHeight
    Select Case ABD.uEdge
      Case ABE_BOTTOM
        AppForm.Left = 0
        AppForm.Top = 0
        AppForm.Width = IIF(AppWidth > ScrnWidth, ScrnWidth, AppWidth)
        AppForm.Height = IIF(AppHeight > ABD.Top, ABD.Top, AppHeight)
      Case ABE_LEFT
        AppForm.Left = ABD.Right
        AppForm.Top = 0
        AppForm.Width = IIF(AppWidth > (ScrnWidth - tbWidth) + (ABD.Left * -1), (ScrnWidth - tbWidth) + (ABD.Left * -1), AppWidth)
        AppForm.Height = IIF(AppHeight > ScrnHeight, ScrnHeight, AppHeight)
      Case ABE_RIGHT
        AppForm.Left = 0
        AppForm.Top = 0
        AppForm.Width = IIF(AppWidth > ABD.Left, ABD.Left, AppWidth)
        AppForm.Height = IIF(AppHeight > ScrnHeight, ScrnHeight, AppHeight)
      Case ABE_TOP
        AppForm.Left = 0
        AppForm.Top = ABD.Bottom
        AppForm.Width = IIF(AppWidth > ScrnWidth, ScrnWidth, AppWidth)
        AppForm.Height = IIF(AppHeight > ScrnHeight - ABD.Bottom, ScrnHeight - ABD.Bottom, AppHeight)
    End Select
  End If
  Result = FL_lRet ' Tell the main program... whether or not this function succeeded.
End Function

$ENDIF   ' IncManager: __QFORMLOCALE_INC
