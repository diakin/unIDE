$IFNDEF __QTOOLBAREX_INC   ' IncManager: include guard
$DEFINE __QTOOLBAREX_INC
'
' Generic toolbar using QPanel & QCoolBtns v1.1
' Author:   d_homans@yahoo.com.au
' Date:     1 Mar 2011
'
' Note:
'   This is a modified version of my QToolBarEX. The QCoolBtns have been
'   moved into the 'PUBLIC' area of the code hence are "visible" to the
'   RapidFRM application, so that I can copy the bitmaps of the non-visible 
'   components for use elsewhere. 
'
$INCLUDE "QImageListEX.inc"                                             ' Build using a bmp "strip" image

$IFNDEF MAXTOOLBTNS
$DEFINE MAXTOOLBTNS     64                                              ' User code can alter - to save memory...
$ENDIF                                                                  ' ... usage? or >64 button toolbars?

$IFNDEF __RQINC2
$DEFINE alNone          0
$DEFINE alTop           1
$DEFINE alBottom        2
$DEFINE alLeft          3
$DEFINE alRight         4
$DEFINE alClient        5
$ENDIF

$IFNDEF True
$DEFINE False           0
$DEFINE True            1
$ENDIF

DIM ButtonImages AS QImageListEX                                        ' MUST be global!

DECLARE SUB ToolBtnClick_Event(Index AS integer)

TYPE QToolBarEX EXTENDS QPANEL
WITH QToolBarEX

    BMP             AS string  PROPERTY SET SetBtnFile                  ' Load a bitmap file
    BMPHandle       AS integer PROPERTY SET SetBtnResource              ' Load a bitmap resource
    BtnCount        AS integer PROPERTY SET SetBtnCount                 ' Number of button images in bitmap "strip"
    BtnSpacer       AS integer PROPERTY SET SetBtnSpacing               ' Spacing between buttons
    BtnMask         AS integer PROPERTY SET SetBtnMask                  ' Defaults to bottom LHS pixel (of each image!)
    Cursor          AS integer PROPERTY SET SetCursor                   ' Cursor for all buttons
    Enabled         AS integer PROPERTY SET SetBtnEnable                ' Enable/disable all buttons
    GroupIndex      AS integer PROPERTY SET SetGroup                    ' Allows a button in a group to stay down
    Height          AS integer PROPERTY SET SetHeight                   ' Valid for align=alTop or alBottom
    Hint            AS string  PROPERTY SET SetHint                     ' CSV string, one token per button
    NumBMPs         AS integer PROPERTY SET SetBtnBitmaps               ' Number of images per button
    Width           AS integer PROPERTY SET SetWidth                    ' Valid for align=alLeft or alRight
    tbButtons(MAXTOOLBTNS)    AS QCOOLBTN                               ' Unable to "REDIM" on the fly

    OnSelect        AS EVENT(ToolBtnClick_Event)                        ' Button click event sub

PRIVATE:
    BtnWidth        AS integer
    BtnHeight       AS integer

PUBLIC:
    ' Property "meaningless" for alTop, alBottom (depends on parent)
    PROPERTY SET SetWidth(W AS integer)
        SELECT CASE .Align
            CASE alLeft, alRight
                IF W > 0 THEN
                    SUPER.Width=W
                    .Width=W
                    .BtnWidth=W-2
                END IF
        END SELECT
    END PROPERTY

    ' Property "meaningless" for alLeft, alRight (depends on parent)
    PROPERTY SET SetHeight(H AS integer)
        SELECT CASE .Align
            CASE alTop, alBottom
                IF H > 0 THEN
                    SUPER.Height=H
                    .Height=H
                    .BtnHeight=H-2
                END IF
        END SELECT
    END PROPERTY

    PROPERTY SET SetBtnEnable(state AS integer)
    DEFINT i, which

        IF state=False THEN which=False ELSE which=True             ' Just making sure its a 0/1
        FOR i=0 TO .BtnCount-1
            .tbButtons(i).Enabled=which
            .tbButtons(i).ShowHint=which
        NEXT i
        .Enabled=which
    END PROPERTY

    PROPERTY SET SetBtnCount(numButtons AS integer)
        IF (numButtons>0) AND (numButtons<=MAXTOOLBTNS) THEN
            .BtnCount=numButtons
        END IF
    END PROPERTY

    PROPERTY SET SetBtnSpacing(gap AS integer)
        IF gap >= 0 THEN
            .BtnSpacer=gap
        END IF
    END PROPERTY

    PROPERTY SET SetBtnMask(Mask AS integer)
        .BtnMask=Mask                                                   ' FIXME: Override default?
    END PROPERTY

    ' Bitmaps per button (1 to 4 for a QCoolBtn)
    PROPERTY SET SetBtnBitmaps(imgCount AS integer)
        IF (imgCount>0) AND (imgCount<5) THEN
            .NumBMPs=imgCount
        END IF
    END PROPERTY

    PROPERTY SET SetGroup(Index AS integer)
    DEFINT i, maxbtns

        ' NB IF BtnCount has not been set yet in user code, fudge it
        maxbtns=IIF(.BtnCount=0,MAXTOOLBTNS,.BtnCount)
        IF .GroupIndex<>Index THEN
            .GroupIndex=Index                                           ' Any non-zero value will do
            IF (Index=0) OR ((Index<>0) AND (.NumBMPs=4)) THEN          ' IF we have 4 imgs per button
                FOR i=0 TO maxbtns-1
                    .tbButtons(i).GroupIndex=Index                      ' Set the button
                NEXT i
            END IF
        END IF
    END PROPERTY
    
    PROPERTY SET SetCursor(curType AS integer)
        IF (curType >= -21) AND (curType <= 0) THEN
            .Cursor=curType
        END IF
    END PROPERTY

    ' Multi-hints CSV string. If button hint string present, then button hint is enabled
    PROPERTY SET SetHint(hString AS string)
    DEFINT i, count, maxbtns

        ' NB IF BtnCount has not been set yet in user code, fudge it
        maxbtns=IIF(.BtnCount=0,MAXTOOLBTNS,.BtnCount)
        IF hString="" THEN
            FOR i=0 TO maxbtns-1
                .tbButtons(i).Hint=""
                .tbButtons(i).ShowHint=False
            NEXT i
        ELSE
            count=TALLY(hString,",")+1
            FOR i=0 TO maxbtns-1
                IF (i+1)>count THEN EXIT FOR                            ' More Btns than hints?
                .tbButtons(i).Hint=FIELD$(hString,",",i+1)
                .tbButtons(i).ShowHint=True
            NEXT i
            FOR i=i TO maxbtns-1                                        ' Tidy up
                .tbButtons(i).ShowHint=False
            NEXT i
        END IF
        .Hint=hString
    END PROPERTY

PRIVATE:
    SUB WhichButton(Sender AS QCOOLBTN)
        IF .OnSelect>0 THEN
            CALLFUNC(.OnSelect,Sender.Tag)                              ' Call the click event
        END IF
    END SUB

    SUB InitButtons
    DEFINT i

        FOR i=0 TO .BtnCount-1
            .tbButtons(i).Parent=THIS
            SELECT CASE .Align
                CASE alLeft, alRight
                    .tbButtons(i).Left=1
                    .tbButtons(i).Top=i*(.BtnHeight+.BtnSpacer)+1       ' Fix for each button
                CASE alTop, alBottom
                    .tbButtons(i).Left=i*(.BtnWidth+.BtnSpacer)+1       ' ditto
                    .tbButtons(i).Top=1
            END SELECT
            .tbButtons(i).Width=.BtnWidth
            .tbButtons(i).Height=.BtnHeight
            .tbButtons(i).Spacing=0
            .tbButtons(i).Flat=True
            .tbButtons(i).Cursor=.Cursor
            .tbButtons(i).NumBMPs=.NumBMPs
            IF .NumBMPs=4 THEN
                .tbButtons(i).GroupIndex=.GroupIndex                    ' Only if images support it
            END IF
            .tbButtons(i).Tag=i                                         ' Internal use
            .tbButtons(i).BMP=ButtonImages.GetBMP(i)                    ' Load button image(s)
            .tbButtons(i).OnClick=THIS.WhichButton
        NEXT i
        FOR i=i TO MAXTOOLBTNS
            .tbButtons(i).Enabled=False
            .tbButtons(i).Visible=False
        NEXT i
    END SUB

    SUB ProcessTheButtons
    DEFINT imgWidth, imgHeight

        imgWidth=ButtonImages.Width\.NumBMPs                            ' Button img width
        imgHeight=ButtonImages.Height                                   ' Button img height

        SELECT CASE .Align
            CASE alTop, alBottom
                IF .Width=0 THEN                                        ' Using the bitmap dimensions
                    .BtnWidth=imgWidth+2                                ' Using a FIXED 1 pixel border
'                    .Width=(imgWidth+4)*.BtnCount+4                    ' Width may depend on Parent! Leaving as 0
                END IF
                IF .Height=0 THEN THIS.SetHeight(imgHeight+4)           ' 1 pixel border for button + ...
            CASE alLeft, alRight                                        ' ...1 pixel border for parent
                IF .Height=0 THEN                                       ' Using the bitmap dimensions
                    .BtnHeight=imgHeight+2
'                    .Height=(imgHeight+4)*.BtnCount+4                  ' Height may depend on Parent! Leaving as 0
                END IF
                IF .Width=0 THEN THIS.SetWidth(imgWidth+4)
        END SELECT
        .InitButtons
    END SUB

PUBLIC:
    PROPERTY SET SetBtnFile(FileStr AS string)
        IF FileExists(FileStr)=0 THEN  ShowMessage "File error! Cannot load bitmap": EXIT SUB
        IF .BtnCount=0 THEN ShowMessage "Button count not set! Cannot load bitmap": EXIT SUB
        IF (.Align=alClient) OR (.Align=alNone) THEN .Align=alTop       ' Not allowed default to top

        ButtonImages.FixWidth=0: ButtonImages.FixHeight=0               ' Default - no stretch
        SELECT CASE .Align
            CASE alLeft, alRight
                IF .Width>0 THEN ButtonImages.FixWidth=(.Width-4)*.NumBMPs   ' Not using defaults of bitmap?
            CASE alTop, alBottom
                IF .Height>0 THEN ButtonImages.FixHeight=.Height-4      '  Not using defaults of bitmap?
        END SELECT

        ButtonImages.ExtractFile(FileStr,.BtnCount,.BtnMask)            ' Load the image cache

        IF ButtonImages.Count<>.BtnCount THEN
            ShowMessage "Unknown error! Failed to load bitmap"
        ELSE
            .ProcessTheButtons
        END IF
    END PROPERTY

    PROPERTY SET SetBtnResource(ResIndex AS integer)
        IF .BtnCount=0 THEN ShowMessage "Button count not set! Cannot load bitmap": EXIT SUB
        IF (.Align=alClient) OR (.Align=alNone) THEN .Align=alTop       ' Not allowed default to top

        ButtonImages.FixWidth=0: ButtonImages.FixHeight=0               ' Default - no stretch
        SELECT CASE .Align
            CASE alLeft, alRight
                IF .Width>0 THEN ButtonImages.FixWidth=(.Width-4)*.NumBMPs
            CASE alTop, alBottom
                IF .Height>0 THEN ButtonImages.FixHeight=.Height-4
        END SELECT

        ButtonImages.ExtractRes(ResIndex,.BtnCount,.BtnMask)            ' Load the image cache

        IF ButtonImages.Count<>.BtnCount THEN
            ShowMessage "Unknown error! Failed to load bitmap"
        ELSE
            .ProcessTheButtons
        END IF
    END PROPERTY

    EVENT OnClick
    ' Do nothing on clicking the QPanel
    END EVENT

CONSTRUCTOR
    Align=alTop
    Left=0
    Top=0
    Width=0
    Height=0
    BtnCount=0
    BtnSpacer=1
    BtnMask=&hffffff
    NumBMPs=1
    GroupIndex=0
    Enabled=True
    Hint=""
    Cursor=0                                                            ' crDefault
    OnSelect=0                                                          ' Default no OnClick
END CONSTRUCTOR
END WITH
END TYPE
$ENDIF   ' IncManager: __QTOOLBAREX_INC
