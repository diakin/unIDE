'=============== QBEVEL =======================
'
' This component duplicates the Delphi TBevel.
' Not an entirely revolutionary thing, but as 
' with most of my components, something to save
' time and coding. Play around with the combo
' boxes to see the effects. Rather simple
' actually, only two new properties: Shape and
' Style. I think you'll find them pretty self-
' explanatory...


const bsLowered    = 0
const bsRaised     = 1
const bsSpacer     = 0
const bsBox        = 1
const bsTopLine    = 2
const bsBottomLine = 3
const bsLeftLine   = 4
const bsRightLine  = 5
const bsFrame      = 6   


TYPE QBEVEL EXTENDS QPANEL
    
    WITH QBEVEL
    
        Style AS LONG PROPERTY SET Set_Style
        Shape AS LONG PROPERTY SET Set_Shape
        Canvas AS QCANVAS

        EVENT Canvas.OnPaint
        
            SELECT CASE .Shape
                CASE 0, 1, 6
                    EXIT EVENT
                CASE 2
                    .Canvas.Line(0, 0, .Width, 0, IIF(.Style, &HFFFFFF, &H808080))
                    .Canvas.Line(0, 1, .Width, 1, IIF(.Style, &H808080, &HFFFFFF))
                CASE 3
                    .Canvas.Line(0, 0, .Width, 0, IIF(.Style, &HFFFFFF, &H808080))
                    .Canvas.Line(0, 1, .Width, 1, IIF(.Style, &H808080, &HFFFFFF))
                CASE 4
                    .Canvas.Line(0, 0, 0, .Height, IIF(.Style, &HFFFFFF, &H808080))
                    .Canvas.Line(1, 0, 1, .Height, IIF(.Style, &H808080, &HFFFFFF))
                CASE 5
                    .Canvas.Line(0, 0, 0, .Height, IIF(.Style, &HFFFFFF, &H808080))
                    .Canvas.Line(1, 0, 1, .Height, IIF(.Style, &H808080, &HFFFFFF))
            END SELECT
        END EVENT
        
        PROPERTY SET Set_Style(NewStyle AS LONG)
            .Style = NewStyle
            SELECT CASE .Shape
                CASE 1
                    .BevelInner = 0
                    .BevelOuter = .Style+1
                CASE 6
                    .BevelInner = 2-.Style
                    .BevelOuter = 1+.Style
                CASE ELSE
                    .BevelInner = 0
                    .BevelOuter = 0
                    .Canvas.Repaint
            END SELECT
        END PROPERTY

        PROPERTY SET Set_Shape(NewShape AS LONG)
            .Shape = NewShape
            SELECT CASE .Shape
                CASE 1
                    .BevelInner = 0
                    .BevelOuter = .Style+1 
                CASE 6
                    .BevelInner = 2-.Style
                    .BevelOuter = 1+.Style                    
                CASE ELSE
                    .BevelInner = 0
                    .BevelOuter = 0
                    .Canvas.Align = .Shape-1
                    .Canvas.Repaint
            END SELECT
        END PROPERTY
       
        constRUCTOR
            Set_Shape(0)
            Set_Style(0)
            Canvas.Parent = This
            Canvas.Width = 2
            Canvas.Height = 2
        END constRUCTOR
    END WITH
END TYPE
  