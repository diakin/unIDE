DIM cmdForm AS QCOOLBTN
WITH cmdForm
  .Align = 3
  .BMPHandle = Form_BMP
  .Flat = 1
  .Hint = "Create a new QFORM"
  .Parent = Panel0
  .OnClick = ObjClick
  .Visible = 1
  .Width = 30
.tag=400
.ShowHint=1
END WITH

DIM cmdLabel AS QCOOLBTN
WITH cmdLabel
  .Align = 3
  .BMPHandle = Label_BMP
  .Flat = 1
  .Hint = "Create a new QLABEL"
  .Parent = Panel0
  .OnClick = ObjClick
  .Width = 25
.tag=401
.ShowHint=1
END WITH

DIM cmdEdit AS QCOOLBTN
WITH cmdEdit
  .Align = 3
  .BMPHandle = Edit_BMP
  .Flat = 1
  .Hint = "Create a new QEDIT"
  .Parent = Panel0
  .OnClick = ObjClick
  .Width = 25
.tag=402
.ShowHint=1
END WITH

DIM cmdButton AS QCOOLBTN
WITH cmdButton
  .Align = 3
  .BMPHandle = Button_BMP
  .Flat = 1
  .Hint = "Create a new QBUTTON"
  .Parent = Panel0
  .OnClick = ObjClick
  .Width = 25
.tag=403
.ShowHint=1
END WITH

DIM cmdCoolBtn AS QCOOLBTN
WITH cmdCoolBtn
  .Align = 3
  .BMPHandle = CoolBtn_BMP
  .Flat = 1
  .Hint = "Create a new QCOOLBTN"
  .Parent = Panel1
  .OnClick = ObjClick
  .Width = 25
.tag=404
.ShowHint=1
END WITH

DIM cmdOvalBtn AS QCOOLBTN
WITH cmdOvalBtn
  .Align = 3
  .BMPHandle = OvalBtn_BMP
  .Flat = 1
  .Hint = "Create a new QOVALBUTTON"
  .Parent = Panel1
  .OnClick = ObjClick
  .Width = 25
.tag=405
.ShowHint=1
END WITH

DIM cmdCheckBox AS QCOOLBTN
WITH cmdCheckBox
  .Align = 3
  .BMPHandle = CheckBox_BMP
  .Flat = 1
  .Hint = "Create a new QCheckBox"
  .Parent = Panel0
  .OnClick = ObjClick
  .Width = 25
.tag=406
.ShowHint=1
END WITH

DIM cmdRadio AS QCOOLBTN
WITH cmdRadio
  .Align = 3
  .BMPHandle = Radio_BMP
  .Flat = 1
  .Hint = "Create a new QRadioBtn"
  .Parent = Panel0
  .OnClick = ObjClick
  .Width = 25
.tag=407
.ShowHint=1
END WITH

DIM cmdCombo AS QCOOLBTN
WITH cmdCombo
  .Align = 3
  .BMPHandle = Combo_BMP
  .Flat = 1
  .Hint = "Create a new QComboBox"
  .Parent = Panel0
  .OnClick = ObjClick
  .Width = 25
.tag=408
.ShowHint=1
END WITH

DIM cmdListBox AS QCOOLBTN
WITH cmdListBox
  .Align = 3
  .BMPHandle = QListBox_BMP
  .Flat = 1
  .Hint = "Create a new QListBox"
  .Parent = Panel0
  .OnClick = ObjClick
  .Width = 25
.tag=409
.ShowHint=1
END WITH

DIM cmdPanel AS QCOOLBTN
WITH cmdPanel
  .Align = 3
  .BMPHandle = QPanel_BMP
  .Flat = 1
  .Hint = "Create a new QPanel"
  .Parent = Panel0
  .OnClick = ObjClick
  .Width = 25
.tag=410
.ShowHint=1
END WITH

DIM cmdImage AS QCOOLBTN
WITH cmdImage
  .Align = 3
  .BMPHandle = QImage_BMP
  .Flat = 1
  .Hint = "Create a new QImage"
  .Parent = Panel1
  .OnClick = ObjClick
  .Width = 25
.tag=411
.ShowHint=1
END WITH

DIM cmdGroupBox AS QCOOLBTN
WITH cmdGroupBox
  .Align = 3
  .BMPHandle = QGroupBox_BMP
  .Flat = 1
  .Hint = "Create a new QGroupBox"
  .Parent = Panel0
  .OnClick = ObjClick
  .Width = 25
.tag=412
.ShowHint=1
END WITH

DIM cmdScrollBox AS QCOOLBTN
WITH cmdScrollBox
  .Align = 3
  .BMPHandle = ScrollBox_BMP
  .Flat = 1
  .Hint = "Create a new QScrollBox"
  .Parent = Panel1
  .OnClick = ObjClick
  .Width = 25
.tag=413
.ShowHint=1
END WITH

DIM cmdRichEdit AS QCOOLBTN
WITH cmdRichEdit
  .Align = 3
  .BMPHandle = RichEdit_BMP
  .Flat = 1
  .Hint = "Create a new QRichEdit"
  .Parent = Panel0
  .OnClick = ObjClick
  .Width = 25
.tag=414
.ShowHint=1
END WITH

DIM cmdStringGrid AS QCOOLBTN
WITH cmdStringGrid
  .Align = 3
  .BMPHandle = StringGrid_BMP
  .Flat = 1
  .Hint = "Create a new QStringGrid"
  .Parent = Panel0
  .OnClick = ObjClick
  .Width = 25
.tag=415
.ShowHint=1
END WITH

DIM cmdTabControl AS QCOOLBTN
WITH cmdTabControl
  .Align = 3
  .BMPHandle = TabControl_BMP
  .Flat = 1
  .Hint = "Create a new QTabControl"
  .Parent = Panel2
  .OnClick = ObjClick
  .Width = 25
.tag=416
.ShowHint=1
END WITH

DIM cmdCanvas AS QCOOLBTN
WITH cmdCanvas
  .Align = 3
  .BMPHandle = Canvas_BMP
  .Flat = 1
  .Hint = "Create a new QCanvas"
  .Parent = Panel2
  .OnClick = ObjClick
  .Width = 25
.tag=417
.ShowHint=1
END WITH

DIM cmdStatus AS QCOOLBTN
WITH cmdStatus
  .Align = 3
  .BMPHandle = Status_BMP
  .Flat = 1
  .Hint = "Create a new QStatusBar"
  .Parent = Panel1
  .OnClick = ObjClick
  .Width = 25
.tag=418
.ShowHint=1
END WITH

DIM cmdScrollBar AS QCOOLBTN
WITH cmdScrollBar
  .Align = 3
  .BMPHandle = ScrollBar_BMP
  .Flat = 1
  .Hint = "Create a new QScrollBar"
  .Parent = Panel1
  .OnClick = ObjClick
  .Width = 35
.tag=419
.ShowHint=1
END WITH

DIM cmdTrackBar AS QCOOLBTN
WITH cmdTrackBar
  .Align = 3
  .BMPHandle = TrackBar_BMP
  .Flat = 1
  .Hint = "Create a new QTrackBar"
  .Parent = Panel1
  .OnClick = ObjClick
  .Width = 35
.tag=420
.ShowHint=1
END WITH

DIM cmdFileList AS QCOOLBTN
WITH cmdFileList
  .Align = 3
  .BMPHandle = FileList_BMP
  .Flat = 1
  .Hint = "Create a new QFileListBox"
  .Parent = Panel2
  .OnClick = ObjClick
  .Width = 35
.tag=421
.ShowHint=1
END WITH

DIM cmdGuage AS QCOOLBTN
WITH cmdGuage
  .Align = 3
  .BMPHandle = Guage_BMP
  .Flat = 1
  .Hint = "Create a new QGauge"
  .Parent = Panel1
  .OnClick = ObjClick
  .Width = 35
.tag=422
.ShowHint=1
END WITH

DIM cmdDirTree AS QCOOLBTN
WITH cmdDirTree
  .Align = 3
  .BMPHandle = DirTree_BMP
  .Flat = 1
  .Hint = "Create a new QDirTree"
  .Parent = Panel1
  .OnClick = ObjClick
  .Width = 35
.tag=423
.ShowHint=1
END WITH

DIM cmdListView AS QCOOLBTN
WITH cmdListView
  .Align = 3
  .BMPHandle = ListView_BMP
  .Flat = 1
  .Hint = "Create a new QListView"
  .Parent = Panel1
  .OnClick = ObjClick
  .Width = 35
.tag=424
.ShowHint=1
END WITH

DIM cmdBitmap AS QCOOLBTN
WITH cmdBitmap
  .Align = 3
  .BMPHandle = Bitmap_BMP
  .Flat = 1
  .Hint = "Create a new QBitmap"
  .Parent = Panel2
  .OnClick = ObjClick
  .Width = 35
.tag=425
.ShowHint=1
END WITH

DIM cmdOutline AS QCOOLBTN
WITH cmdOutline
  .Align = 3
  .BMPHandle = Outline_BMP
  .Flat = 1
  .Hint = "Create a new QOutline"
  .Parent = Panel2
  .OnClick = ObjClick
  .Width = 35
.tag=426
.ShowHint=1
END WITH
    