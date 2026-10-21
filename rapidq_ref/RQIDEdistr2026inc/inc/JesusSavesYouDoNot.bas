DECLARE SUB Dummy

CREATE Form AS QFORM
     Top = 50
     Left = 50
     Height = 400
     Width = 500
     Caption = "Form"
     Hint = ""
     ShowHint = 1
     OnClick = Dummy
     CREATE Edit AS QEDIT
          Top = 35
          Left = 5
          Height = 25
          Width = 60
          Color = 16777215
          Text = ""
          Hint = "Text here"
          ShowHint = 1
          OnKeyPress = Dummy
     END CREATE
END CREATE

Form.ShowModal