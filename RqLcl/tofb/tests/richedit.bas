$APPTYPE CONSOLE
DIM Form AS QFORM
DIM RichEdit AS QRICHEDIT
DIM Font AS QFONT

SUB AddClrString(AddString AS STRING, Clr AS INTEGER, Sender AS QRICHEDIT)
    Sender.SelStart = len(Sender.Text)
    Sender.SelLength = Len(AddString)
    Sender.SelAttributes.Color = Clr
    Sender.AddStrings AddString
END SUB

SUB FormShow
    AddClrString "hello", &HFF, RichEdit
    AddClrString "world", &HFF00, RichEdit
    RichEdit.SelStart = 13 : RichEdit.SelLength = 1
    PRINT "lines "; RichEdit.LineCount; " color "; HEX$(RichEdit.SelAttributes.Color)
    RichEdit.SelStart = 0 : RichEdit.SelLength = 5
    Font.Name = "Arial"
    Font.Size = 14
    Font.AddStyles(0)
    RichEdit.SelAttributes = Font
    PRINT RichEdit.SelAttributes.Name; " "; RichEdit.SelAttributes.Size
    RichEdit.Font.Size = 11
    PRINT "font "; RichEdit.Font.Size
    Form.Close
END SUB

RichEdit.Parent = Form
RichEdit.ScrollBars = 3
RichEdit.AddString "Hello world!"
Form.OnShow = FormShow
Form.ShowModal
