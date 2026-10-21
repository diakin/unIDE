$APPTYPE CONSOLE
' QCANVAS, QBITMAP, QHEADER (appendix A): drawing, Pixel, CopyMode, CopyRect,
' Draw from Bitmap.BMP, OnPaint, Sections, OnDrawSection
$RESOURCE Red_BMP AS "res\red16.bmp"
DECLARE SUB CanvasPaint
DECLARE SUB DrawSection (Index AS INTEGER, Pressed AS INTEGER, Rect AS QRECT, Sender AS QHEADER)
DIM Painted AS INTEGER, Drawn AS INTEGER
DIM Bitmap AS QBITMAP
DIM Rect1 AS QRECT
CREATE Form AS QFORM
  Caption = "Canvas"
  Width = 320 : Height = 240
  CREATE Header AS QHEADER
    AddSections "One", "Two", "Three"
    Sections(1).AllowClick = 0
    Sections(0).Width = 100
    Sections(2).Style = 1
    OnDrawSection = DrawSection
  END CREATE
  CREATE Canvas AS QCANVAS
    Top = 40 : Width = 100 : Height = 100
    OnPaint = CanvasPaint
  END CREATE
END CREATE

SUB CanvasPaint
  Painted = 1
END SUB

SUB DrawSection (Index AS INTEGER, Pressed AS INTEGER, Rect AS QRECT, Sender AS QHEADER)
  Drawn = Index + 1
  Sender.TextOut(Rect.Left + 5, Rect.Top + 1, STR$(Index + 1), &HFF0000, -1)
END SUB

' QBITMAP
Bitmap.Width = 32 : Bitmap.Height = 32
PRINT "bitmap "; Bitmap.Width; Bitmap.Height; Bitmap.Empty
Bitmap.FillRect 0, 0, 32, 32, &HFFFFFF
Bitmap.Pset 1, 1, &H123456
PRINT "pset "; HEX$(Bitmap.Pixel(1, 1))
Bitmap.Pixel(2, 2) = &HFF
PRINT "pixel "; HEX$(Bitmap.Pixel(2, 2))
PRINT "copymode "; Bitmap.CopyMode
Bitmap.CopyMode = 14
PRINT "copymode "; Bitmap.CopyMode
Bitmap.CopyMode = 10
Bitmap.Font.Size = 14
PRINT "text "; (Bitmap.TextWidth("Hello") > 0); (Bitmap.TextHeight("Hello") > 0)
Bitmap.SaveToFile "canvas_tmp.bmp"
DIM Bitmap2 AS QBITMAP
Bitmap2.LoadFromFile "canvas_tmp.bmp"
PRINT "load "; Bitmap2.Width; " "; HEX$(Bitmap2.Pixel(1, 1))
DIM Stream AS QMEMORYSTREAM
Bitmap.SaveToStream Stream
PRINT "stream "; (Stream.Size > 0)
Stream.Position = 0
DIM Bitmap3 AS QBITMAP
Bitmap3.LoadFromStream Stream
PRINT "from stream "; Bitmap3.Width; " "; HEX$(Bitmap3.Pixel(2, 2))
Bitmap3.BMPHandle = Red_BMP
PRINT "bmphandle "; Bitmap3.Width; " "; HEX$(Bitmap3.Pixel(3, 3))
KILL "canvas_tmp.bmp"

' QCANVAS
Form.Show
DOEVENTS
PRINT "painted "; Painted
Canvas.FillRect 0, 0, 100, 100, &HFFFFFF
Canvas.Draw 10, 10, Bitmap.BMP
PRINT "canvas draw "; HEX$(Canvas.Pixel(11, 11))
Rect1.Left = 0 : Rect1.Top = 0 : Rect1.Right = 16 : Rect1.Bottom = 16
Canvas.CopyRect Rect1, Bitmap3, Rect1
PRINT "canvas copyrect "; HEX$(Canvas.Pixel(3, 3))
Bitmap.CopyRect Rect1, Bitmap3, Rect1
PRINT "bitmap copyrect "; HEX$(Bitmap.Pixel(3, 3))

' QHEADER
PRINT "sections "; Header.SectionsCount; " "; Header.Sections(1).Caption
PRINT "width "; Header.Sections(0).Width; " click "; Header.Sections(1).AllowClick; Header.Sections(0).AllowClick
PRINT "style "; Header.Sections(2).Style; Header.Sections(0).Style
Header.Sections(1).Caption = "Second"
Header.Sections(1).Alignment = 2
PRINT "caption "; Header.Sections(1).Caption; " align "; Header.Sections(1).Alignment
Header.Repaint
DOEVENTS
PRINT "drawn "; Drawn
Header.Clear
PRINT "cleared "; Header.SectionsCount
Form.Close
