'
' see example below for usage
'
'code derived from:
'''    Name: Button_BMP_XP_Style (.bas,.rqb,.rqw)
'''  Author: David Burkley
'''   Email: burkleyd@yahoo.com
'''    Date: July 15th, 2010
'''
''' edit by JohnK to keep methods/properties consistent
''' with QXPButton.inc
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

' What got me curious about this was an inquiry from JohnK.
' I tried a couple different ways of accomplishing the task
' of having a Bitmap show on a QButton, that has had it's OWNERDRAW
' style removed (in order for it to be able to use the XP Style),
' but had little or no luck.
' I thought I'd check online to see if maybe someone else has
' had any luck and sure enough... I found the code.
'
' As far as I can tell... there's only one drawback.
' "IF" you plan on having multiple Buttons (each with a different Bitmap)...
' you'll have to create a QImageList AND a new instance of a Type structure
' for each one.
'
' The reason you'll need an ImageList for each Button is because
' the OS uses the Bitmaps within the ImageList when the Button is
' in different states. Note: The order of the Bitmaps within the
' ImageList DOES matter! (see below)
' The reason you'll need a new instance of a Type structure for
' each Button is because the Type structure holds vital information
' (such as which ImageList and where to display the Bitmap) that the
' OS will use for each Button.
'
' In this demo there is one Button with six different Bitmaps associated
' with it (depending on it's state). So far... I've only seen the first
' four Bitmaps come into play (NORMAL, HOT, PRESSED, and DISBALED).
' The "DEFAULTED" state (I believe) is used for Dialog boxes.
' (it'll come into play for the Button that has the default focus)
' And... I don't have a Stylus to see what "STYLUSHOT" would look like.
' Although you DO have to have six Bitmaps in the ImageList...
' you do NOT neccessarily have to have six "different" Bitmaps.
' You could simply use one Bitmap for all six states.
' (just duplicate the same Bitmap six times)
'
' The ???_Margin field in the "BUTTON_IMAGELIST" Type structure represents
' the margin you want around the Bitmap. The only way to get these fields
' right is to experiment with them. For instance... the Button in this demo
' is 30 pixels in height. The ImageList's Bitmaps are 14 pixels in height.
' (30 - 14) \ 2 = 8. Top_Margin and Bottom_Margin are set to 8 to center it
' vertically. I set the Left_Margin to 8 also, so that it's not too close
' to the left edge of the Button. I set the Right_Margin to 0 (zero) so
' that the Button Caption will be as close as possible to the Bitmap.
' You do not necessarily have to have a Caption either. Here again...
' you'll have to experiment with the width of your QButton to get it
' to look right.
'
' One final note... you'll have to create a manifest for this demo
' AFTER you've created the executable. Then go ahead and run the
' executable to see that this really does work. :)




$IFNDEF OBJ_BITMAP
  $DEFINE OBJ_BITMAP 7
$ENDIF

$IFNDEF BS_OWNERDRAW
  $DEFINE BS_OWNERDRAW &HB
$ENDIF


$IFNDEF BUTTON_IMAGELIST_ALIGN_LEFT
  $DEFINE BUTTON_IMAGELIST_ALIGN_LEFT 0
$ENDIF

$IFNDEF BUTTON_IMAGELIST_ALIGN_RIGHT
  $DEFINE BUTTON_IMAGELIST_ALIGN_RIGHT 1
$ENDIF

$IFNDEF BUTTON_IMAGELIST_ALIGN_TOP
  $DEFINE BUTTON_IMAGELIST_ALIGN_TOP 2
$ENDIF

$IFNDEF BUTTON_IMAGELIST_ALIGN_BOTTOM
  $DEFINE BUTTON_IMAGELIST_ALIGN_BOTTOM 3
$ENDIF

$IFNDEF BUTTON_IMAGELIST_ALIGN_CENTER
  $DEFINE BUTTON_IMAGELIST_ALIGN_CENTER 4
$ENDIF

$IFNDEF BCM_SETIMAGELIST
  $DEFINE BCM_SETIMAGELIST &H1602
$ENDIF

'each Type will use 64k of memory, for this
'QObject we can replace with an array to save memory
'Type BUTTON_IMAGELIST
'    hImgLst       As Long
'    Left_Margin   As Long
'    Top_Margin    As Long
'    Right_Margin  As Long
'    Bottom_Margin As Long
'    Align         As Long
'End Type


'not in windows.inc...
Declare Function ImageList_AddMasked _
        Lib "comctl32" Alias "ImageList_AddMasked" _
        (ByVal hImageList As Long, _
         ByVal hbmImage As Long, _
         ByVal hBmMask As Long) As Long



$IFNDEF __WIN32API			'for windows 32 API calls/constants

Declare Function UpdateWindow _
        Lib "user32" Alias "UpdateWindow" _
        (ByVal hWnd As Long) As Long


    $IFNDEF __RQINC2			' & rapidQ2

    Const GWL_HWNDPARENT = (-8)
    Const GWL_STYLE = (-16)
    $DEFINE HWND_DESKTOP        0

    Declare Function GetWindowLong _
            Lib "user32" Alias "GetWindowLongA" _
            (ByVal hWnd As Long, ByVal nIndex As Long) As Long

    Declare Function SetWindowLong _
            Lib "user32" Alias "SetWindowLongA" _
            (ByVal hWnd As Long, ByVal nIndex As Long, _
             ByVal dwNewLong As Long) As Long

    Declare Function GetParent _
            Lib "user32" Alias "GetParent" _
            (ByVal hWnd As Long) As Long

    Declare Function GetCurrentObject _
            Lib "gdi32" Alias "GetCurrentObject" _
            (ByVal hdc As Long, _
             ByVal uObjectType As Long) As Long

    $ENDIF
$ENDIF



TYPE QXPBUTTON EXTENDS QBUTTON

    'The best option is to create... one Bitmap that contains all six Bitmaps.
    'Each Bitmap representing one of the six possible Button states.
    '(IN ORDER from left to right : NORMAL, HOT, PRESSED, DISABLED, DEFAULTED, and STYLUSHOT)
    'For this demo I've created one Bitmap that's 84 pixels in width and 14 pixels in height.
    'Each state Bitmap is 14 pixels in width and 14 pixels in height (14 x 6 = 84).
    'The width and height of each Bitmap HAS TO BE the same as the other Bitmaps.
    '(in other words... you can NOT do... 32x32, 24x32, 16x32, 32x32, 16x32, 24x32)
    '$Resource btn_states As "btn_states.bmp"


PUBLIC:
    ImageLeft        AS INTEGER      PROPERTY SET    Set_LeftMargin
    ImageTop         AS INTEGER      PROPERTY SET    Set_TopMargin
    ImageRight       AS INTEGER      PROPERTY SET    Set_RightMargin
    ImageBottom      AS INTEGER      PROPERTY SET    Set_BottomMargin
    ImageAlign       AS INTEGER      PROPERTY SET    Set_AlignImage

    'One ImageList for each Button you'll have.
    ImageList   As QImageList   'holds the BtnBmp (BtnBmp is added via a API function)

PRIVATE:
    hParent     As Long     'holds the handle to the parent of the Button
    hBitmap     As Long     'holds the handle to an object of the specified type that has been selected into the specified device context (DC).
    ColorMask   As Long     'holds the background color (which is typically the transparent color)
    EmptyFlag   As Long     'IF no .BMP (or .BMPhandle) exists... one will be created and this flag is set
    BILTM       As Long     'holds the orignal value of the ImageTop (when it was set or if it was set)
    BILRM       As Long     'holds the orignal value of the ImageRight (when it was set or if it was set)
    BtnBmp      As QBitmap      'holds a copy of the .BMP or .BMPhandle (or created if one doesn't exist)
    'ButtonImageList         AS BUTTON_IMAGELIST
    ButtonImageList(5)      AS INTEGER          'BUTTON_IMAGELIST Alias

WITH THIS

PUBLIC:

    SUB XPStyle
        'copy the Button's Bitmap to our Bitmap
        .BtnBmp.Bmp = This.BMP
        'if the Bitmap is empty after copying...
        'create one that's has 6 states that are only 1 pixel x 1 pixel in size
        If (.BtnBmp.Empty = 1) Then
          .BtnBmp.Width  = 6
          .BtnBmp.Height = 1
          .BtnBmp.FillRect(0,0,6,1,RGB(255,255,255))
          'This flag will be used when setting the Bitmap Alignment (aka Layout)
          .EmptyFlag = True
        Else
          'This flag will be used when setting the Bitmap Alignment (aka Layout)
          .EmptyFlag = False
        End If

        'get background color (Bottom Left-Most pixel per the Help file)
        .ColorMask = (.BtnBmp.Pixel(0, 0)) 'XOR &HFF000000
        'set the ImageList height based on our copied Bitmap height
        .ImageList.Height = .BtnBmp.Height
        'check if it's a multi-image bitmap (needed to set imagelist size correctly)
        If (.BtnBmp.Width / .BtnBmp.Height) > 3 Then
          'it's multi-image, so set the width to only one
          .ImageList.Width = .BtnBmp.Height
        Else
           'it's not multi-image, so set the width to the whole Bitmap width
          .ImageList.Width = .BtnBmp.Width
        End If

        'get the handle to an object of the specified type that has been selected into the specified device context (DC)
        .hBitmap = GetCurrentObject(This.BtnBmp.Handle, OBJ_BITMAP)
        'get the handle of the Button's parent
        .hParent = GetParent(This.Handle)
        'force a redraw of the parent (in order to add the Bitmap to it's DC. you won't actually see it.)
        UpdateWindow(.hParent)
        'after forcing the redraw this API function will work
        ImageList_AddMasked(This.ImageList.Handle, This.hBitmap, This.ColorMask)
        'Fill in the numeric array (which is a substitute for the BITMAP_IMAGELIST) with the needed information
        .ButtonImageList(0) = .ImageList.Handle
        .ButtonImageList(1) = .ImageLeft
        .ButtonImageList(2) = .ImageTop
        .ButtonImageList(3) = .ImageRight
        .ButtonImageList(4) = .ImageBottom
        .ButtonImageList(5) = .ImageAlign
    

        'condition the removal of the BS_ONWERDRAW style (so that it's not toggled back on and off)
        If (GetWindowLong(This.Handle, GWL_STYLE) And BS_OWNERDRAW) = BS_OWNERDRAW Then
          SetWindowLong(This.Handle, GWL_STYLE, (GetWindowLong(This.Handle, GWL_STYLE) XOR BS_OWNERDRAW))
        End If
        'need to make the Button invisible (for a split second) so that it can be updated with any new information
        This.Visible = False
          SendMessage(This.Handle, BCM_SETIMAGELIST, 0, VarPtr(This.ButtonImageList(0)))
        This.Visible = True

    END SUB


    Sub UpdateBtnBmp
        .XPStyle
    end Sub

    Property SET Set_LeftMargin (value As Long)
        .ImageLeft = value
        .UpdateBtnBmp
    End Property

    Property SET Set_TopMargin (value As Long)
        .ImageTop = value
        .BILTM = value
        .UpdateBtnBmp
    End Property

    Property SET Set_RightMargin (value As Long)
        .ImageRight = value
        .BILRM = value
        .UpdateBtnBmp
    End Property

    Property SET Set_BottomMargin (value As Long)
        .ImageBottom = value
        .UpdateBtnBmp
    End Property

    Property SET Set_AlignImage (value As Long)
'        If .osVersion >= &H251 Then
'          'if the O.S. is >= WinXP... use the new property(s)
'          'these conditions and equations need to be refined.
'          'the Bitmap (under certain conditions) doesn't display in the place you'd expect
          If (value = BUTTON_IMAGELIST_ALIGN_LEFT) And (.ImageRight > .BILRM) Then
            .ImageRight = .BILRM
          End If
          If (value = BUTTON_IMAGELIST_ALIGN_TOP) And (.EmptyFlag = False) Then
            .ImageTop = .BILTM + 3
          End If
          If (value = BUTTON_IMAGELIST_ALIGN_RIGHT) And (.EmptyFlag = False) Then
            .ImageRight = .BILRM + 1
          End If
          If (value = BUTTON_IMAGELIST_ALIGN_BOTTOM) And (.ImageTop > .BILTM) Then
            .ImageTop = .BILTM
          End If
          .ImageAlign = value
          .UpdateBtnBmp

'        Else
'          'if the O.S. is < WinXP... use the Layout property
'          This.Layout = value
'        End If
    End Property

End With

    Constructor
      'PRIVATE properties
'      osVersion  = 0
      hParent    = 0
      hBitmap    = 0
      ColorMask  = 0
      BILTM      = 0
      BILRM      = 0

      'PUBLIC properties
      ImageLeft = 0
      ImageTop = 0
      ImageRight = 0
      ImageBottom = 0
      ImageAlign   = BUTTON_IMAGELIST_ALIGN_LEFT
    End Constructor
End Type


'****** test code  #1  *****
'$INCLUDE <Rapidq2.inc>
'$INCLUDE <QXPButton.inc>
'$Resource btn_states As "btn_states.bmp"

'  this is easier to use but less efficent, uses disk I/O 
'CREATE MainForm AS QFORM
'    Center
'
'    CREATE Button AS QXPButton
'        Width = 90
'        Height = 30
'        Left = (MainForm.ClientWidth \ 2) - (Button.Width \ 2)
'        Top  = (MainForm.ClientHeight \ 2) - (Button.Height \ 2)
'        BMPHandle = btn_states
'        XPStyle
'        Caption = "Click Me"
'    END CREATE
'END CREATE
'
'MainForm.ShowModal




''***  test code #2   *****
'
''  what if the user may not be using windows XP or higher?
'$INCLUDE <Rapidq2.inc>
'$INCLUDE <QXPButton.inc>
'$Resource btn_states As "btn_states.bmp"
'
'CREATE MainForm AS QFORM
'    Center
'
'    CREATE Button AS QXPButton
'        Width = 90
'        Height = 30
'        Left = (MainForm.ClientWidth \ 2) - (Button.Width \ 2)
'        Top  = (MainForm.ClientHeight \ 2) - (Button.Height \ 2)
'        BMPHandle = btn_states
'        Caption = "Click Me"
'    END CREATE
'END CREATE
'
'DIM systm AS QSYSTEM
'IF (systm.MajorVersion >= 5) THEN Button.XPStyle
'
'
'MainForm.ShowModal



'/* Start of example code #3  */
'$Option Explicit
'
'$Resource btn_states As "btn_states.bmp" 'you can get this bitmap on David's website
'
'$Include <RapidQ.inc>
'$INCLUDE <QXPButton.inc>
'
'Declare Sub MainForm_OnShow
'Declare Sub MainForm_OnClose
'
'Declare Sub mDisable_OnClick
'Declare Sub mRelocateBMP_OnClick (Sender As QMenuItem)
'
'Create MainForm As QForm
'  DelBorderIcons(biMinimize, biMaximize)
'  BorderStyle = bsSingle
'  Width       = 320
'  Height      = 240
'  Left        = (Screen.Width\2)-(MainForm.Width\2)
'  Top         = (Screen.Height\2)-(MainForm.Height\2)
'  OnShow      = MainForm_OnShow
'  OnClose     = MainForm_OnClose
'  Create MainMenu As QMainMenu
'    Create mRelocateLeft As QMenuItem
'      Caption = "Left"
'      OnClick = mRelocateBMP_OnClick
'    End Create
'    Create mRelocateTop As QMenuItem
'      Caption = "Top"
'      OnClick = mRelocateBMP_OnClick
'    End Create
'    Create mRelocateRight As QMenuItem
'      Caption = "Right"
'      OnClick = mRelocateBMP_OnClick
'    End Create
'    Create mRelocateBottom As QMenuItem
'      Caption = "Bottom"
'      OnClick = mRelocateBMP_OnClick
'    End Create
'    Create mRelocateCenter As QMenuItem
'      Caption = "Center"
'      OnClick = mRelocateBMP_OnClick
'    End Create
'    Create mDisable As QMenuItem
'      Caption = "Disable"
'      OnClick = mDisable_OnClick
'    End Create
'  End Create
'  Create Button As QBtnBmpXP
'    Width   = 88
'    Height  = 44
'    Left    = (MainForm.ClientWidth \ 2) - (Button.Width \ 2)
'    Top     = (MainForm.ClientHeight \ 2) - (Button.Height \ 2)
'    Caption = "Click Me"
'    'Uncomment one or the other (but not both) and it works
'    'Using this causes disk I/O
'    'BMP = "btn_states.bmp"
'    'Using this does NOT causes disk I/O
'    BMPhandle = btn_states
'    'Ignored by the include file but still useable by O.S. < WinXP
'    NumBMPs = 3
'    'One simple subroutine call does it all
'    UpdateBtnBmp
'  End Create
'End Create
'
'MainForm.ShowModal
'
'Sub MainForm_OnShow
'End Sub
'
'Sub MainForm_OnClose
'    Application.Terminate
'End Sub
'
'Sub mRelocateBMP_OnClick (Sender As QMenuItem)
''Useable by everyone (the include file handles it)
'    Select Case Sender.Handle
'      Case mRelocateLeft.Handle
'        Button.ImageAlign = BUTTON_IMAGELIST_ALIGN_LEFT
'      Case mRelocateTop.Handle
'        Button.ImageAlign = BUTTON_IMAGELIST_ALIGN_TOP
'      Case mRelocateRight.Handle
'        Button.ImageAlign = BUTTON_IMAGELIST_ALIGN_RIGHT
'      Case mRelocateBottom.Handle
'        Button.ImageAlign = BUTTON_IMAGELIST_ALIGN_BOTTOM
'      Case mRelocateCenter.Handle
'        Button.ImageAlign = BUTTON_IMAGELIST_ALIGN_CENTER
'    End Select
'End Sub
'
'Sub mDisable_OnClick
'    Button.Enabled = Button.Enabled XOR 1
'    mDisable.Caption = IIf(Button.Enabled = True, "Disable", "Enable ")
'End Sub

'/* End of example code */



