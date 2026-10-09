'QFlatButton - See "Appendix A QFLATBUTTON.htm" for usage
'Special thanks to Erlend Rovik <e-rovik@online.no> for the OnMouseDown/Up suggestion.
	Type QFlatButton EXTENDS QImage
		b as Integer
		CurrState as Integer
		FlatBMPHandle as STRING
		G as integer
		R as integer
		SUB GetColors
			Dim ColorScheme as QRegistry
			Dim SchemeText$ as string
			ColorScheme.OpenKey("\\Control Panel\\Colors", 0)
			if ColorScheme.ValueExists("ButtonFace") then
				SchemeText$ =  ColorScheme.ReadString("ButtonFace")
'Forgot to delete ling 16 :) ? ColorScheme.ReadString("ButtonFace")
				else
					SchemeText$ = "150 150 150"
			end if
			ColorScheme.closeKey
			dim SchemeWaldo& as integer
			for SchemeWaldo& = 0 to Len(SchemeText$)
				if Mid$( SchemeText$, ( Len(SchemeText$) - SchemeWaldo& ), 1 ) = " " then
					QFlatButton.B = Val( Right$(SchemeText$, SchemeWaldo&) )
					SchemeText$ = Left$( SchemeText$, ( ( Len(SchemeText$) - SchemeWaldo& ) - 1 ) )
					SchemeWaldo& = Len(SchemeText$)
				end if
			next
			SchemeWaldo& = 0
			for SchemeWaldo& = 0 to Len(SchemeText$)
				if Mid$( SchemeText$, ( Len(SchemeText$) - SchemeWaldo& ), 1 ) = " " then
					QFlatButton.G = Val( Right$(SchemeText$, SchemeWaldo&) )
					SchemeText$ = Left$( SchemeText$, ( ( Len(SchemeText$) - SchemeWaldo& ) - 1 ) )
					SchemeWaldo& = Len(SchemeText$)
				end if
			next
			QFlatButton.R = Val(SchemeText$)
		end SUB
		SUB Depress
			If QFlatButton.CurrState < 2 then
				QFlatButton.GetColors
				QFlatButton.FlatBMPHandle = QFlatButton.BMPHandle
				'Light
				QFlatButton.Line( (QFlatButton.Width - 1), 1, (QFlatButton.Width - 1), (QFlatButton.Height - 1), rgb( round(QFlatButton.R * 1.15), round(QFlatButton.G * 1.15), round(QFlatButton.B * 1.15) ) )
				QFlatButton.Line( 1, (QFlatButton.Height - 1), (QFlatButton.Height - 1), (QFlatButton.Height - 1), rgb( round(QFlatButton.R * 1.15), round(QFlatButton.G * 1.15), round(QFlatButton.B * 1.15) ) )
				'Dark
				QFlatButton.Line( 1, 1, 1, (QFlatButton.Height - 1), rgb( round(QFlatButton.R * .3), round(QFlatButton.G * .3), round(QFlatButton.B * .3) ) )
				QFlatButton.Line( 1, 1,(QFlatButton.Width - 1), 1, rgb( round(QFlatButton.R * .3), round(QFlatButton.G * .3), round(QFlatButton.B * .3) ) )
				QFlatButton.CurrState = 2
			end if
		end SUB
		SUB Flatten
			If QFlatButton.CurrState > 0 then
				QFlatButton.BMPHandle = QFlatButton.FlatBMPHandle
				QFlatButton.CurrState = 0
				QFlatButton.Stretch = 1
				QFlatButton.Transparent = 1
			end if
		end SUB
		SUB Raise
			If QFlatButton.CurrState = 0 or QFlatButton.CurrState > 1 then
				QFlatButton.CurrState = 1
				'Light
				QFlatButton.GetColors
				QFlatButton.Line( 1, 1, 1, (QFlatButton.Height - 1), rgb( round(QFlatButton.R * 1.15), round(QFlatButton.G * 1.15), round(QFlatButton.B * 1.15) ) )
				QFlatButton.Line( 1, 1, (QFlatButton.Width - 1), 1, rgb( round(QFlatButton.R * 1.15), round(QFlatButton.G * 1.15), round(QFlatButton.B * 1.15) ) )
				'Dark
				QFlatButton.Line( 1, (QFlatButton.Height - 1), (QFlatButton.Width - 1), (QFlatButton.Height - 1), rgb( round(QFlatButton.R * .3), round(QFlatButton.G * .3), round(QFlatButton.B * .3) ) )
				QFlatButton.Line( (QFlatButton.Width - 1), 1, (QFlatButton.Width - 1), (QFlatButton.Height - 1), rgb( round(QFlatButton.R * .3), round(QFlatButton.G * .3), round(QFlatButton.B * .3) ) )
			End If
		end SUB
		event OnMouseDown
			QFlatButton.Depress
		end event
		EVENT OnMouseMove
			if (MouseX > 3 and MouseX < (QFlatButton.Width - 3) ) and (MouseY > 3 and MouseY < ( QFlatButton.Height - 3 ) ) then
				QFlatButton.Raise
				Else
					QFlatButton.Flatten
			end if
		end Event
		Event OnMouseUp
			QFlatButton.Flatten
		end event
		constRUCTOR
			GetColors
			Autosize = 1
			CurrState = 0
			height = 25
			Stretch = 1
			Transparent = 1
			width = 25
		end constRUCTOR
	end type
	'FlatButton Constants
	const fbFlattened = 0
	const fbRaised = 1
	const fbDepressed = 2
  