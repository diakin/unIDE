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


CONST bsLowered    = 0
CONST bsRaised     = 1
CONST bsSpacer     = 0
CONST bsBox        = 1
CONST bsTopLine    = 2
CONST bsBottomLine = 3
CONST bsLeftLine   = 4
CONST bsRightLine  = 5
CONST bsFrame      = 6   


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
       
        CONSTRUCTOR
            Set_Shape(0)
            Set_Style(0)
            Canvas.Parent = This
            Canvas.Width = 2
            Canvas.Height = 2
        END CONSTRUCTOR
    END WITH
END TYPE

'=================================================
'        Sample program
'=================================================

DECLARE SUB ChangeStyle
DECLARE SUB ChangeShape

CREATE Form AS QFORM
    CREATE Menu AS QMAINMENU
        CREATE Item AS QMENUITEM
            Caption = "Menu"
        END CREATE
    END CREATE
    CREATE ToolBar AS QBEVEL
        Align = 1
        Height = 50
        Shape = bsTopLine
        Caption = "ToolBar"
    END CREATE
    CREATE Bevel AS QBEVEL
        Top = 80
        Left = 30
        Width = 130
        Height = 30
    END CREATE
    CREATE Style AS QCOMBOBOX
        Top = 150
        Left = 10
        AddItems "bsLowered", "bsRaised"
        ItemIndex = 0
        OnChange = ChangeStyle
    END CREATE
    CREATE Shape AS QCOMBOBOX
        Top = 150
        Left = 160
        AddItems "bsSpacer", "bsBox", "bsTopLine", "bsBottomLine", "bsLeftLine", "bsRightLine", "bsFrame"
        ItemIndex = 0
        OnChange = ChangeShape
    END CREATE
END CREATE

Form.ShowModal

SUB ChangeStyle
    Bevel.Style = Style.ItemIndex
END SUB

SUB ChangeShape
    Bevel.Shape = Shape.ItemIndex
END SUB