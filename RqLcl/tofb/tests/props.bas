$APPTYPE CONSOLE
' Align, Tag, TabOrder у всех элементов; свойства QLABEL, QEDIT, QFORM,
' QBUTTON; QFORM.OnResize, QLABEL.OnClick
DECLARE FUNCTION SendMessageA LIB "user32" ALIAS "SendMessageA" (hwnd AS LONG, wMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
DECLARE SUB FormResize
DECLARE SUB LabelClick (Sender AS QLABEL)
DIM Resizes AS INTEGER

CREATE Form AS QFORM
  Caption = "Props"
  Width = 400 : Height = 300
  BorderStyle = 2
  KeyPreview = 1
  AutoScroll = 0
  Tag = 7
  OnResize = FormResize
  CREATE Label1 AS QLABEL
    Caption = "label"
    Left = 10 : Top = 10 : Width = 100 : Height = 20
    AutoSize = 0
    Transparent = 1
    Alignment = 2
    WordWrap = 1
    Layout = 1
    Tag = 11
    OnClick = LabelClick
  END CREATE
  CREATE Edit1 AS QEDIT
    Left = 10 : Top = 40
    Text = "abcdef"
    MaxLength = 20
    ReadOnly = 1
    TabOrder = 1
    Tag = 12
  END CREATE
  CREATE Btn1 AS QBUTTON
    Caption = "btn"
    Left = 10 : Top = 70
    TabOrder = 0
    ModalResult = 1
    Tag = 13
  END CREATE
  CREATE Cool AS QCOOLBTN
    Left = 100 : Top = 70
    TabOrder = 3
  END CREATE
  CREATE Bottom AS QPANEL
    Align = 2
    Height = 30
  END CREATE
END CREATE

SUB FormResize
  Resizes = Resizes + 1
END SUB

SUB LabelClick (Sender AS QLABEL)
  PRINT "label click "; Sender.Tag
END SUB

PRINT "tags "; Form.Tag; " "; Label1.Tag; " "; Edit1.Tag; " "; Btn1.Tag
PRINT "label "; Label1.Transparent; Label1.AutoSize; Label1.Alignment; Label1.WordWrap; Label1.Layout
PRINT "edit "; Edit1.MaxLength; Edit1.ReadOnly; Edit1.TabOrder
PRINT "button "; Btn1.TabOrder; Btn1.ModalResult; " cool "; Cool.TabOrder
PRINT "form "; Form.BorderStyle; Form.KeyPreview; Form.AutoScroll
PRINT "align "; Bottom.Align; Label1.Align
Btn1.Align = 4
PRINT "btn align "; Btn1.Align
Form.Show
DOEVENTS
Edit1.SelStart = 2
Edit1.SelLength = 3
PRINT "sel "; Edit1.SelText
Form.Width = 450
DOEVENTS
IF Resizes > 0 THEN PRINT "resize ok" ELSE PRINT "no resize"
SendMessageA(Form.Handle, &H201, 1, 15 + 15 * 65536)
SendMessageA(Form.Handle, &H202, 0, 15 + 15 * 65536)
DOEVENTS
Form.Close
PRINT "end"
