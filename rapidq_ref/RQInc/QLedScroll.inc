TYPE QLEDSCROLL EXTENDS QCANVAS
 TextColor as LONG
 BgColor as LONG
 X as SINGLE
 Y as INTEGER
 Text as STRING
 Raster as INTEGER
 RasterLen as INTEGER
 Font as QFONT
 
 CONSTRUCTOR
  Width=200
  Height=32
  RasterLen=2
 END CONSTRUCTOR
 
 SUB Rewind
  this.X=this.Width+TextWidth(this.Text)+1
 END SUB
 
 SUB Paint
  y=this.Y
  this.FillRect 0,0,this.Width,this.Height,this.BgColor
  this.TextOut this.X,y,this.Text,this.TextColor,this.BgColor

  if this.Raster then
   for i=0 to this.Width step this.RasterLen
    this.Line i,0,i,this.Height,this.BgColor
   next i
   for i=0 to this.Height step this.RasterLen
    this.Line 0,i,this.Width,i,this.BgColor
   next i  
  end if
 END SUB
 
 SUB Repaint
  this.Paint
 END SUB
 
 EVENT OnPaint
  this.Paint
 END EVENT

 SUB Move(p AS SINGLE)
  this.X=this.X-p
 END SUB
 
 SUB SetString(s$)
  this.Text=s$
  this.Rewind
 END SUB
 
 SUB SetColor(c AS LONG)
  this.TextColor=c
  this.Font.Color=this.TextColor
 END SUB

END TYPE
