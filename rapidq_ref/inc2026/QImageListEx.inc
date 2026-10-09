$IFNDEF __QIMGLISTEX                                                    ' Only include once
$DEFINE __QIMGLISTEX

'-------------------- The component -----------------------------------------------
' Add multiple images to a QImageList from one bitmap "strip"
' The NumImages parameter determines each image that is added to the list
' The layout of the bitmap "strip" MUST be horizontal
' IF FixWidth &/or FixHeight <> 0, the images will be "stretched" to suit
' IF FixWidth & FixHeight = 0, the images will be loaded "as is"
'----------------------------------------------------------------------------------
TYPE QImageListEX EXTENDS QImageList

WITH QImageListEX
    ' 2 New properties
    FixWidth AS integer                                                 ' IF > 0 use this width
    FixHeight AS integer                                                ' IF > 0 use this height

PRIVATE:
    FullBitmap  AS QBITMAP
    ImageCount  AS integer
    ImageMask   AS integer

' On entry: FullBitmap is the final size bitmap containing 'n' images
    SUB LoadImageList
    DIM tmpBitmap AS QBITMAP
    DIM src AS QRECT, dest AS QRECT
    DEFINT i

        .Clear                                                          ' Ensure ImageList cleared
        .BkColor=536870911                                              ' clNone
        tmpBitmap.Width=.Width: tmpBitmap.Height=.Height
        dest.Left=0: dest.Top=0
        dest.Right=.Width: dest.Bottom=.Height
        src.Top=0: src.Bottom=.Height
        FOR i=0 TO .ImageCount-1
            src.Left=i*.Width: src.Right=src.Left+.Width
            tmpBitmap.CopyRect(dest,THIS.FullBitmap,src)                ' Copy individual images
            tmpBitmap.SaveToFile("__tmp.bmp")                           ' Save to a file
            .AddBMPFile("__tmp.bmp",.ImageMask)                         ' Read into ImageList
            KILL "__tmp.bmp"
            DoEvents
        NEXT i
        KILL "__tmp.bmp"
        DoEvents
    END SUB

PUBLIC:
    ' 2 new methods
    SUB ExtractFile(filename AS string, NumImages AS integer, ColorMask AS integer)
    DIM tmpBitmap AS QBITMAP
    DIM rect AS QRECT

        IF ((FileExists(filename)=0) OR (NumImages<=0)) THEN EXIT SUB
        tmpBitmap.BMP=filename                                          ' Load original sized user file
        .Width=tmpBitmap.Width\NumImages: .Height=tmpBitmap.Height      ' Default images width & height
        IF .FixWidth>0 THEN .Width=.FixWidth                            ' Adjust for "stretch"ed?
        IF .FixHeight>0 THEN .Height=.FixHeight                         ' ditto?
        .FullBitmap.Width=.Width*NumImages                              ' Size FullBitmap
        .FullBitmap.Height=.Height                                      ' ditto
        rect.Left=0: rect.Right=.FullBitmap.Width
        rect.Top=0: rect.Bottom=.Height
        .FullBitmap.StretchDraw(rect,tmpBitmap.BMP)                     ' Re-size multi-image bitmap
        .ImageCount=NumImages
        .ImageMask=ColorMask
        .LoadImageList                                                  ' Extract each image into ImageList  
    END SUB

    SUB ExtractRes(ResIndex AS integer, NumImages AS integer, ColorMask AS integer)
    DIM File AS QFILESTREAM

        File.Open("__tmp.bmp", fmCreate)
        File.ExtractRes(RESOURCE(ResIndex))
        File.Close
        DoEvents
        .ExtractFile("__tmp.bmp",NumImages,ColorMask)
    END SUB

CONSTRUCTOR
    FixWidth=0
    FixHeight=0
    ImageCount=0
    ImageMask=536870911                                                 ' clNone
END CONSTRUCTOR
END WITH
END TYPE

$ENDIF      ' End of $IFNDEF __QIMGLISTEX
