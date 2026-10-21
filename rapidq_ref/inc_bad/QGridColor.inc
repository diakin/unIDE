'QGridColor v 1.0.0
'Author : Nastase Eodor
'2004
'mail :eodor@idilis.ro

Const st1x16 = 0
Const st2x8  = 1
Const st4x4  = 2

Declare Sub CellClicked
Type QGridColor extends QPanel
     Private:
     Colors(16)     as integer
     SColors(16)    as string
     ColorCells(16) as QPanel
     Public:
     OnCellClick    as Event(CellClicked)
     FGColor        as integer
     BKColor        as integer
     Style          as integer Property Set SetStyle
     ShowCaption    as integer
     ShowHints      as integer Property Set SetShowHint

     Sub LoadColors
     With This
          .Colors(0) = 0               : .SColors(0) = "Black"
          .Colors(1) = &H800000        : .SColors(1) = "Navy"
          .Colors(2) = &H8000          : .SColors(2) = "Green"
          .Colors(3) = &H808000        : .SColors(3) = "Teal"
          .Colors(4) = &H80            : .SColors(4) = "Maroon"
          .Colors(5) = &H800080        : .SColors(5) = "Purple"
          .Colors(6) = &H8080          : .SColors(6) = "Olive"
          .Colors(7) = &HC0C0C0        : .SColors(7) = "Silver"
          .Colors(8) = &H808080        : .SColors(8) = "Gray"
          .Colors(9) = &HFF0000        : .SColors(9) = "Blue"
          .Colors(10) = &HFF00         : .SColors(10) = "Lime"
          .Colors(11) = &HFFFF00       : .SColors(11) = "Aqua"
          .Colors(12) = &HFF           : .SColors(12) = "Red"
          .Colors(13) = &HFF00FF       : .SColors(13) = "Fuchsia"
          .Colors(14) = &HFFFF         : .SColors(14) = "Yellow"
          .Colors(15) = &HFFFFFF       : .SColors(15) = "White"
     End With
     End Sub
     
     Sub CellClick(Button as integer,x as integer,y as integer,Shift as integer,Sender as QPanel)
     Dim i as integer
     With This
          If Button = 0 then
             If .ShowCaption then
                 For i = 0 to 15
                     If .ColorCells(i).Caption <> "BK" then
                        .ColorCells(i).Caption = ""
                     End If
                 Next i
             Sender.Caption = "FG"
             End If
             .FGColor = Sender.Color
             If .OnCellClick <> 0 then CallFunc .OnCellClick
          ElseIf Button = 1 then
             If .ShowCaption then
                For i = 0 to 15
                    If .ColorCells(i).Caption <> "FG" then
                       .ColorCells(i).Caption = ""
                    End If
                Next i
             Sender.Caption = "BK"
             End If
             .BKColor = Sender.Color
             If .OnCellClick <> 0 then CallFunc .OnCellClick
          End If
     End With
     End Sub
     
     Sub Draw
     Dim i as integer
     With This
          .BevelOuter = 0
          If .Style = st1x16 then
              For i = 0 to 15
                  .ColorCells(i).Parent      = This
                  .ColorCells(i).BevelOuter  = 0
                  .ColorCells(i).BorderStyle = 1
                  .ColorCells(i).Width       = .Width/16
                  .ColorCells(i).Height      = .Height -2
                  .ColorCells(i).Color       = .Colors(i)
                  .ColorCells(i).Top         = 1
                  .ColorCells(i).Left        = i*.Width/16
              Next i
          ElseIf .Style = st2x8 then
              For i = 0 to 7
                  .ColorCells(i).Parent      = This
                  .ColorCells(i).BevelOuter  = 0
                  .ColorCells(i).BorderStyle = 1
                  .ColorCells(i).Width       = .Width/8
                  .ColorCells(i).Height      = .Height/2 -1
                  .ColorCells(i).Color       = .Colors(i)
                  .ColorCells(i).Top         = 1
                  .ColorCells(i).Left        = i*.Width/8
              Next i
              For i = 0 to 7
                  .ColorCells(i+8).Parent      = This
                  .ColorCells(i+8).BevelOuter  = 0
                  .ColorCells(i+8).BorderStyle = 1
                  .ColorCells(i+8).Width       = .Width/8
                  .ColorCells(i+8).Height      = .Height/2 -1
                  .ColorCells(i+8).Color       = .Colors(i+8)
                  .ColorCells(i+8).Top         = 1 + .Height/2
                  .ColorCells(i+8).Left        = i*.Width/8
              Next i
          ElseIf .Style = st4x4 then
              For i = 0 to 3
                  .ColorCells(i).Parent      = This
                  .ColorCells(i).BevelOuter  = 0
                  .ColorCells(i).BorderStyle = 1
                  .ColorCells(i).Width       = .Width/4
                  .ColorCells(i).Height      = .Height/4 -1
                  .ColorCells(i).Color       = .Colors(i)
                  .ColorCells(i).Top         = 1
                  .ColorCells(i).Left        = i*.Width/4
              Next i
              For i = 0 to 3
                  .ColorCells(i+4).Parent      = This
                  .ColorCells(i+4).BevelOuter  = 0
                  .ColorCells(i+4).BorderStyle = 1
                  .ColorCells(i+4).Width       = .Width/4
                  .ColorCells(i+4).Height      = .Height/4 -2
                  .ColorCells(i+4).Color       = .Colors(i+4)
                  .ColorCells(i+4).Top         = 1 + .Height/4
                  .ColorCells(i+4).Left        = i*.Width/4
              Next i
              For i = 0 to 3
                  .ColorCells(i+8).Parent      = This
                  .ColorCells(i+8).BevelOuter  = 0
                  .ColorCells(i+8).BorderStyle = 1
                  .ColorCells(i+8).Width       = .Width/4
                  .ColorCells(i+8).Height      = .Height/4 -1
                  .ColorCells(i+8).Color       = .Colors(i+8)
                  .ColorCells(i+8).Top         = 1 + .Height/2
                  .ColorCells(i+8).Left        = i*.Width/4
              Next i
              For i = 0 to 3
                  .ColorCells(i+12).Parent      = This
                  .ColorCells(i+12).BevelOuter  = 0
                  .ColorCells(i+12).BorderStyle = 1
                  .ColorCells(i+12).Width       = .Width/4
                  .ColorCells(i+12).Height      = .Height/4 -1
                  .ColorCells(i+12).Color       = .Colors(i+12)
                  .ColorCells(i+12).Top         = 1 + 3* .Height/4
                  .ColorCells(i+12).Left        = i*.Width/4
              Next i
          End If
      For i = 0 to 15
          .ColorCells(i).OnMouseDown = This.CellClick
          .ColorCells(i).Hint        = .SColors(i)
          If .ShowHints then .ColorCells(i).ShowHint = 1
      Next i
      End With
      End Sub
      
      Property Set SetStyle(fStyle as integer)
      With This
          .Style = fStyle
          .Draw
      End With
      End Property
      
      Property Set SetShowHint(fShow as integer)
      Dim i as integer
      With This
           .ShowHints = fShow
           For i = 0 to 15
               If .ShowHints then
                  .ColorCells(i).Hint     = .SColors(i)
                  .ColorCells(i).ShowHint = 1
               End If
           Next i
      End With
      End Property

      Constructor
      LoadColors
      Draw
      End Constructor
End Type
