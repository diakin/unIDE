const LdCyan   = 1
const LdPurple = 2
const LdBlue   = 3
const Ldyellow = 4
const LdGreen  = 5
const LdRed    = 6
const LdOn     = 1
const LdOff    = 0

Type QLed extends QCanvas
     LedColor as byte Property Set SetColor
     LedState as integer Property Set SetState
     Size     as integer
     
     Sub Draw
     dim basecolor as integer,bright as integer
     dim t as integer,p1 as integer,p2 as integer
     dim colorstepsize as integer,fadecolor as integer
     If This.LedState = LdOff then
        bright=&h80
        else
        bright=&hff
     End If
     This.Height= This.Size
     This.Width = This.Height
     basecolor= bright*(1 and not This.LedColor)
     basecolor= basecolor+256*bright*(2 and not This.LedColor)/2
     basecolor= basecolor+256^2*bright*(4 and not This.LedColor)/4
     This.Circle(0,0,This.Size,This.Size,0,basecolor)
     p1= This.Size/5
     p2= This.Size/1.2
     colorstepsize= 256/(p2-p1-This.Size/6)
     fadecolor= basecolor
     For t = p2 to p1+qled.size/6+2 Step -1
         fadecolor= fadecolor+colorstepsize*(This.LedColor and 1)
         fadecolor= fadecolor+colorstepsize*256*(This.LedColor and 2)/2
         fadecolor= fadecolor+colorstepsize*256^2*(This.LedColor and 4)/4
         This.Circle(p1,p1,t,t,fadecolor,fadecolor)
     Next t
     This.Circle(p1,p1,t,t,fadecolor,fadecolor)
     End Sub
     
     Property Set SetColor(Value as byte)
     This.LedColor = Value
     This.Draw
     End Sub
     
     Property Set SetState(Value as integer)
     This.LedState = Value
     This.Draw
     End Property
 
     Event OnPaint
     This.Draw
     End Event
     
     Constructor
     Size = 15
     LedColor = LdRed
     End Constructor
End Type

