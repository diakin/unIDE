'************************************************************************************************
'*                
'* QButtonXP by Nicolas Tillet http://wwww.membres.lycos.fr/ntillet86  du 10/2003
'*      Modified by Nastase Eodor 6/2005
'*  Note : use with QXPTheme.inc in conjuction to take effects
'*                
'************************************************************************************************


DECLARE FUNCTION xpBSetWindowLong Lib "user32" Alias "SetWindowLongA" (BYVAL hwnd AS LONG, BYVAL nIndex AS LONG, BYVAL dwNewLong AS LONG) AS LONG
DECLARE FUNCTION xpBSetFocus Lib "user32" Alias "SetFocus" (BYVAL hwnd AS LONG) AS LONG

TYPE QButtonXP Extends QButton
Xp as integer property Set SetXp

With This
	
	Property Set SetXP(value as integer)
	'If value <> .Xp then
		.Xp = value
		XPBSetWindowLong (.Handle,-16,&h54010010 + .Default)
		This.Visible = 0
		This.Visible = 1 ' same with repaint
	'End If
	End Property
	
	Sub SetFocus
	xpBSetFocus (.Handle) 
	End Sub 
	
CONSTRUCTOR
'BevelWidth    = 0
'BorderColor   = &HBFD0D0
'CaptionColor  = &HD54600
'LunaDetect    = 1
'Canvas.Parent = XpGroupBox
'Canvas.Align  = 5   'alClient
 Xp =3
 '.SetXP(1)
END CONSTRUCTOR
	
	
End With
END TYPE 
