$IFNDEF __QSPINEDIT_INC   ' IncManager: include guard
$DEFINE __QSPINEDIT_INC
'======================================================================
'QSpinButton spin component for Rapidq
' v 1.0.0
' 2004 Nastase Eodor < eodor@idilis.ro >
'======================================================================

$IFNDEF TRUE
  $DEFINE True 1
$ENDIF

$IFNDEF FALSE
  $DEFINE False 0
$ENDIF

$IFNDEF boolean
  $DEFINE boolean integer
$ENDIF

Defint st3d   = 0
Defint stFlat = 1

Type QSpinButton extends QPanel
     Private :
     ic as double
     SpinUp as QCoolBtn
     SpinDown as QCoolBtn
     SpinEdit as QEdit

     Public :
     Font as QFont
     Value    as variant
     IncrementBy as variant
     MaxValue  as double
     MinValue as double
     ShowEdit as boolean
     Style    as integer
     Text     as string
     
     Sub Draw
        with QSpinButton
        .BevelInner  = 0
        .BevelOuter  = 0
            .SpinUp.Parent  = This
            .SPinUp.Top     = 0
            .SpinUp.Left    = 0
            .SpinUp.Height  = .Height/2
            .SpinUp.Font    = .Font
            .SpinUp.Caption = "+"
            .SpinUp.Hint    = " Increase Value "
            .SpinUp.ShowHint = .ShowHint

            .SpinDown.Parent  = This
            .SPinDown.Top     = .SpinUp.Height
            .SpinDown.Left    = 0
            .SpinDown.Height  = .Height/2
            .SpinDown.Font    = .Font
            .SpinDown.Caption = "-"
            .SpinDown.Hint    = " Decrease Value "
            .SpinDown.ShowHint = .ShowHint

            if .ShowEdit = 0 then
               .SpinDown.Width   = .Width
               .SpinUp.Width     = .Width
            elseif .ShowEdit = 1 then
               .SpinDown.Width   = .Width/4
               .SpinUp.Width     = .Width/4
            end if

            .SpinEdit.Parent   = This
            .SpinEdit.Width    = .Width*(3/4)
            .SpinEdit.Height   = .Height
            .SpinEdit.Align    = 4
            .SpinEdit.AutoSize = 1
            .SpinEdit.Text     = .Text
            .SpinEdit.Hint     = .Text
            .SpinEdit.ShowHint = .ShowHint

        if .ShowEdit = False then
           .SpinEdit.Visible = False
           end if
        if .ShowEdit = True then
           .SpinEdit.Visible = True
           end if
        if .Style = st3d then
           .SpinUp.Flat   = False
           .SpinDown.Flat = False
           .SpinEdit.BorderStyle = 1
           end if
        if .Style = stFlat then
           .SpinUp.Flat   = True
           .SpinDown.Flat = True
           .SpinEdit.BorderStyle = 0
           end if
         end with
     End Sub
      
     Sub Click(Sender as QCoolBtn)
     with QSpinButton
     ic = .IncrementBy
     if .Value >= .MaxValue then .Value = .MaxValue ' inc2026: >= вместо =>: в документации (operators.html) только >=, замена для единообразия, как в других inc
     if .Value <= .MinValue then .Value = .MinValue
     if .MaxValue = 0 and .MinValue = 0 then Exit Sub
     if Sender.Handle = .SpinUp.Handle then
             Inc(.Value,ic)
             end if
     if Sender.Handle = .SpinDown.Handle then
             Dec(.Value,ic)
             end if
     if VarType(This.Value) = 0 then
          if .Value > 0 then
             .SpinEdit.Text = "+" + str$(.Value)
          elseif .Value < 0 then
                 .SpinEdit.Text = "-" + str$(.Value)
          elseif .Value = 0 then
                 .SpinEdit.Text = str$(.Value)
          end if
     end if
     if VarType(This.Value) = 1 then
          if .Value > 0 then
             .SpinEdit.Text = "+" + strf$(.Value,0,4,4)
          elseif .Value < 0 then
                 .SpinEdit.Text = "-" + strf$(.Value,0,4,4)
          elseif .Value = 0 then
                 .SpinEdit.Text = str$(.Value)
          end if
     end if
     .Text = .SpinEdit.Text
     .Draw
     end with
     End Sub
     
     Sub Change(Sender as QEdit)
     with QSpinButton
         .Value = Val(.SpinEdit.Text)
     .Text = .SpinEdit.Text
     .Draw
     end with
     End Sub
     
     Constructor
     MaxValue = 10
     IncrementBy = 0.1
     Style = st3d
     ShowEdit = True
     MinValue = -10
     Value = 0
     Width = 50
     Height = 22
     Text = "0"
     ShowHint = 1
     Draw
     SpinUp.OnClick    = QSpinButton.Click
     SpinDown.OnClick  = QSpinButton.Click
     SpinEdit.OnChange = QSpinButton.Change
     End Constructor
End Type


$ENDIF   ' IncManager: __QSPINEDIT_INC
