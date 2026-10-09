$Resource Bit_Res as "Mark.bmp"

Type QMarker extends QPanel
     MarkColor   as integer
     RowHeight    as integer
     Row(200)     as QPanel
     RowColor     as integer
     Mark         as QImage

     Sub Draw
     dim i as integer
     dim y as integer
     dim NoRow as integer
        with QMarker
             NoRow = .Height / .RowHeight
        for i = 0 to .Height
            .Row(i).Parent = This
            .Row(i).Color  = .RowColor
            .Row(i).Width  = .Width
            .Row(i).Height = .RowHeight
            .Row(i).Top    = i * .RowHeight
        next i
        end with
     End Sub
     
     Sub SetMark(ARow as integer,AColor as integer)
     with QMarker
     .Row(ARow).Color = AColor
     end with
     End Sub
     

     Sub SetImage(ARow as integer)
     with QMarker
        .Mark.Parent = .Row(ARow)
        .Mark.BMPHandle = Bit_Res
        .Mark.Transparent = 1
        .Mark.Align = 5
        .Mark.Stretch = 1
     end with
     End Sub
     
     Constructor
      'RowHeight = 18
      'Width = 40
      RowColor=&hc0c0c0
      Draw
     End Constructor
End Type
 

