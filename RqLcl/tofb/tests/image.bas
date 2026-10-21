$APPTYPE CONSOLE
' QIMAGE and QIMAGELIST (appendix A, chapter 8): image cache (GetBMP, BMP,
' Icon), BMPHandle, AddBMPHandle, drawing, Pixel, ImageList.Draw, CopyRect
$RESOURCE Red_BMP AS "res\red16.bmp"
$RESOURCE Green_ICO AS "res\green16.ico"
DIM List AS QIMAGELIST
DIM Rect1 AS QRECT, Rect2 AS QRECT
CREATE Form AS QFORM
  Caption = "Images"
  Width = 300 : Height = 200
  CREATE Image1 AS QIMAGE
    Width = 40 : Height = 40
  END CREATE
  CREATE Image2 AS QIMAGE
    Left = 50 : Width = 40 : Height = 40
  END CREATE
  CREATE Btn1 AS QBUTTON
    Top = 60
  END CREATE
  CREATE Lv AS QLISTVIEW
    Top = 100
  END CREATE
END CREATE

List.Width = 16 : List.Height = 16
List.Masked = 0
List.AddBMPFile "res\red16.bmp", 0
List.AddICOFile "res\green16.ico"
List.AddBMPHandle Red_BMP, 0
List.AddICOHandle Green_ICO
PRINT "count "; List.Count; " size "; List.Width; "x"; List.Height
List.InsertBMPFile 0, "res\red16.bmp", 0
List.Delete 0
PRINT "count "; List.Count

' drawing on the image
Image1.FillRect 0, 0, 40, 40, &HFFFFFF
Image1.Pset 1, 1, &H123456
PRINT "pset "; HEX$(Image1.Pixel(1, 1))
Image1.Pixel(2, 1) = &HFF0000
PRINT "pixel "; HEX$(Image1.Pixel(2, 1))
Image1.Line 0, 10, 39, 10, 0
PRINT "line "; HEX$(Image1.Pixel(5, 10))
PRINT "text "; (Image1.TextWidth("Hello") > 0)
' ImageList.Draw and the cache
List.Draw Image1, 20, 20, 1
PRINT "list draw "; HEX$(Image1.Pixel(28, 28))
Image1.Draw 0, 20, List.GetBMP(0)
PRINT "draw cache "; HEX$(Image1.Pixel(5, 25))
' CopyRect from Image1 to Image2
Rect1.Left = 0 : Rect1.Top = 0 : Rect1.Right = 40 : Rect1.Bottom = 40
Image2.FillRect 0, 0, 40, 40, 0
Image2.CopyRect Rect1, Image1, Rect1
PRINT "copyrect "; HEX$(Image2.Pixel(28, 28)); " "; HEX$(Image2.Pixel(1, 1))
' resources and BMP / Icon through the cache
Image2.BMPHandle = Red_BMP
PRINT "bmphandle "; HEX$(Image2.Pixel(3, 3))
Btn1.BMP = List.GetBMP(1)
Form.ICOHandle = Green_ICO
Image2.Icon = Form.Icon
Image1.BMP = "res\red16.bmp"
Btn1.BMP = Image1.BMP
Lv.SmallImages = List
Image1.Stretch = 1 : Image1.Center = 1
PRINT "flags "; Image1.Stretch; Image1.Center; Image1.AutoSize
List.Clear
PRINT "cleared "; List.Count
