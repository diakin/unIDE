$IFNDEF __QHEAD_INC   ' IncManager: include guard
$DEFINE __QHEAD_INC
Type QHead extends QCanvas
     Public :
     Icon          as QBitmap
     AutoCenter    as integer
     IconX         as integer
     IconY         as integer
     CaptionX      as integer
     CaptionY      as integer
     StartColor    as integer Property Set SetStartColor
     EndColor      as integer Property Set SetEndColor
     Increment     as integer Property Set SetIncrement
     LeftText      as string  Property Set SetLeftText
     RightText     as string  Property Set SetRightText
     CaptionSize   as integer Property Set SetCaptionSize
     ShowLeftText  as integer Property Set SetShowRightText
     ShowRightText as integer Property Set SetShowLeftText
     ShowIcon      as integer Property Set SetShowIcon

     Sub DrawComponent
     Dim i as integer,Col as integer,fStep as integer,x as integer
     With QHead
     Col = .StartColor
     .Icon.Transparent = 1
     .Icon.TransparentMode = 0
     If .Align      <> 1 then .Align = 1
     If .CaptionSize = 0 then .CaptionSize = 12
     If .CaptionX    = 0 then .CaptionX = 12
     If .CaptionY    = 0 then .CaptionY  = 4
     .Font.Size = .CaptionSize
     .FillRect(0,0,.Width,.Height,.Color)
     For i = 0 to .Width Step 3
        If Col < .EndColor then
           Col = Col + .Increment
           Else
           Col = Col - .Increment
        End If
     .FillRect(i,.CaptionSize + 2*.CaptionY +1,i+3,.CaptionSize + 2*.CaptionY +3,Col)
     Next
     If .ShowLeftText then
       If .ShowIcon then
          .TextOut(.CaptionX+.Icon.Width +.IconX +2,.CaptionY,.LeftText,&H777777,-1)
          .TextOut(.CaptionX+.Icon.Width +.IconX +3,.CaptionY+1,.LeftText,&HFFFFFF,-1)   ' inc2026: было .IconY: белый текст - вторая половина тени к строке 41 (.IconX +2, .CaptionY), смещение по X на 1, как в строках 44-45; IconY к координате X не относится (копирование)
       Else
          .TextOut(.CaptionX,.CaptionY,.LeftText,&H777777,-1)
          .TextOut(.CaptionX+1,.CaptionY+1,.LeftText,&HFFFFFF,-1)
     End If
     End If
     If .ShowRightText then
      .TextOut(.Width -.TextWidth(.RightText)-.CaptionX,.CaptionY,.RightText,&H777777,-1)
      .TextOut(.Width -.TextWidth(.RightText)-(.CaptionX+1),.CaptionY+1,.RightText,&hffffff,-1)
     End If
     If .ShowIcon then
        If .AutoCenter then
          .Draw(.IconX,.CaptionSize + 2*.CaptionY +1,.Icon.BMP)
          Else
          .Draw(.IconX,.IconY,.Icon.BMP)
        End If
     End If
     End With
     End Sub
    
     Event OnPaint
     QHead.DrawComponent
     End Event
     
     Property Set SetStartColor(value as integer)
     QHead.StartColor = value
     QHead.DrawComponent
     End Property
     
     Property Set SetEndColor(value as integer)
     QHead.EndColor = value
     QHead.DrawComponent
     End Property
     
     Property Set SetIncrement(value as integer)
     QHead.Increment = value
     QHead.DrawComponent
     End Property
     
     Property Set SetLeftText(value as string)
     QHead.LeftText = value
     QHead.DrawComponent
     End Property
     
     Property Set SetRightText(value as string)
     QHead.RightText = value
     QHead.DrawComponent
     End Property
     
     Property Set SetCaptionSize(value as integer)
     QHead.CaptionSize = value
     QHead.DrawComponent
     End Property
     
     Property Set SetShowRightText(value as integer)
     QHead.ShowLeftText = value
     QHead.DrawComponent
     End Property
     
     Property Set SetShowLeftText(value as integer)
     QHead.ShowRightText = value
     QHead.DrawComponent
     End Property
     
     Property Set SetShowIcon(value as integer)
     QHead.ShowIcon = value
     QHead.DrawComponent
     End Property
     
     Constructor
     Color      = &hffffff
     StartColor = &H000044
     EndColor   = &H0000FF
     Increment  = &H0000001
     LeftText   = "QHead"
     RightText  = "Test Component"
     End Constructor
End Type
$ENDIF   ' IncManager: __QHEAD_INC
