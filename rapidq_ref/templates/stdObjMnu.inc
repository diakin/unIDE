DIM cmdForm AS QMenuItem
WITH cmdForm
  .Caption = "Create a new QFORM"  
'.Hint = "Create a new QFORM"
  .OnClick = ObjClick
  .Visible = 1
.tag=400
END WITH

DIM cmdLabel AS QMenuItem
WITH cmdLabel
  .Caption = "Create a new QLABEL"  
'.Hint = "Create a new QLABEL"
  .OnClick = ObjClick
.tag=401
END WITH

DIM cmdEdit AS QMenuItem
WITH cmdEdit
  .Caption = "Create a new QEDIT"  
'.Hint = "Create a new QEDIT"
  .OnClick = ObjClick
.tag=402
END WITH

DIM cmdButton AS QMenuItem
WITH cmdButton
  .Caption = "Create a new QBUTTON"  
'.Hint = "Create a new QBUTTON"
  .OnClick = ObjClick
.tag=403
END WITH

DIM cmdCoolBtn AS QMenuItem
WITH cmdCoolBtn
  .Caption = "Create a new QMenuItem"  
'.Hint = "Create a new QMenuItem"
  .OnClick = ObjClick
.tag=404
END WITH

DIM cmdOvalBtn AS QMenuItem
WITH cmdOvalBtn
  .Caption = "Create a new QOVALBUTTON"  
'.Hint = "Create a new QOVALBUTTON"
  .OnClick = ObjClick
.tag=405
END WITH

DIM cmdCheckBox AS QMenuItem
WITH cmdCheckBox
  .Caption = "Create a new QCheckBox"  
'.Hint = "Create a new QCheckBox"
  .OnClick = ObjClick
.tag=406
END WITH

DIM cmdRadio AS QMenuItem
WITH cmdRadio
  .Caption = "Create a new QRadioBtn"  
'.Hint = "Create a new QRadioBtn"
  .OnClick = ObjClick
.tag=407
END WITH

DIM cmdCombo AS QMenuItem
WITH cmdCombo
  .Caption = "Create a new QComboBox"  
'.Hint = "Create a new QComboBox"
  .OnClick = ObjClick
.tag=408
END WITH

DIM cmdListBox AS QMenuItem
WITH cmdListBox
  .Caption = "Create a new QListBox"  
'.Hint = "Create a new QListBox"
  .OnClick = ObjClick
.tag=409
END WITH

DIM cmdPanel AS QMenuItem
WITH cmdPanel
  .Caption = "Create a new QPanel"  
'.Hint = "Create a new QPanel"
  .OnClick = ObjClick
.tag=410
END WITH

DIM cmdImage AS QMenuItem
WITH cmdImage
  .Caption = "Create a new QImage"  
'.Hint = "Create a new QImage"
  .OnClick = ObjClick
.tag=411
END WITH

DIM cmdGroupBox AS QMenuItem
WITH cmdGroupBox
  .Caption = "Create a new QGroupBox"  
'.Hint = "Create a new QGroupBox"
  .OnClick = ObjClick
.tag=412
END WITH

DIM cmdScrollBox AS QMenuItem
WITH cmdScrollBox
  .Caption = "Create a new QScrollBox"  
'.Hint = "Create a new QScrollBox"
  .OnClick = ObjClick
.tag=413
END WITH

DIM cmdRichEdit AS QMenuItem
WITH cmdRichEdit
  .Caption = "Create a new QRichEdit"  
'.Hint = "Create a new QRichEdit"
  .OnClick = ObjClick
.tag=414
END WITH

DIM cmdStringGrid AS QMenuItem
WITH cmdStringGrid
  .Caption = "Create a new QStringGrid"  
'.Hint = "Create a new QStringGrid"
  .OnClick = ObjClick
.tag=415
END WITH

DIM cmdTabControl AS QMenuItem
WITH cmdTabControl
  .Caption = "Create a new QTabControl"  
'.Hint = "Create a new QTabControl"
  .OnClick = ObjClick
.tag=416
END WITH

DIM cmdCanvas AS QMenuItem
WITH cmdCanvas
  .Caption = "Create a new QCanvas"  
'.Hint = "Create a new QCanvas"
  .OnClick = ObjClick
.tag=417
END WITH

DIM cmdStatus AS QMenuItem
WITH cmdStatus
  .Caption = "Create a new QStatusBar"  
'.Hint = "Create a new QStatusBar"
  .OnClick = ObjClick
.tag=418
END WITH

DIM cmdScrollBar AS QMenuItem
WITH cmdScrollBar
  .Caption = "Create a new QScrollBar"  
'.Hint = "Create a new QScrollBar"
  .OnClick = ObjClick
.tag=419
END WITH

DIM cmdTrackBar AS QMenuItem
WITH cmdTrackBar
  .Caption = "Create a new QTrackBar"  
'.Hint = "Create a new QTrackBar"
  .OnClick = ObjClick
.tag=420
END WITH

DIM cmdFileList AS QMenuItem
WITH cmdFileList
  .Caption = "Create a new QFileListBox"  
'.Hint = "Create a new QFileListBox"
  .OnClick = ObjClick
.tag=421
END WITH

DIM cmdGuage AS QMenuItem
WITH cmdGuage
  .Caption = "Create a new QGauge"  
'.Hint = "Create a new QGauge"
  .OnClick = ObjClick
.tag=422
END WITH

DIM cmdDirTree AS QMenuItem
WITH cmdDirTree
  .Caption = "Create a new QDirTree"  
'.Hint = "Create a new QDirTree"
  .OnClick = ObjClick
.tag=423
END WITH

DIM cmdListView AS QMenuItem
WITH cmdListView
  .Caption = "Create a new QListView"  
'.Hint = "Create a new QListView"
  .OnClick = ObjClick
.tag=424
END WITH

DIM cmdBitmap AS QMenuItem
WITH cmdBitmap
  .Caption = "Create a new QBitmap"  
'.Hint = "Create a new QBitmap"
  .OnClick = ObjClick
.tag=425
END WITH

DIM cmdOutline AS QMenuItem
WITH cmdOutline
  .Caption = "Create a new QOutline"  
'.Hint = "Create a new QOutline"
  .OnClick = ObjClick
.tag=426
END WITH

DIM cmdSplitter AS QMenuItem
WITH cmdSplitter
  .Caption = "Create a new QSplitter"  
'.Hint = "Create a new QOutline"
  .OnClick = ObjClick
.tag=427
END WITH

DIM cmdGauge AS QMenuItem
WITH cmdGauge
  .Caption = "Create a new QGauge"  
'.Hint = "Create a new QOutline"
  .OnClick = ObjClick
.tag=428
END WITH



'!!! -------- Add MenuItems -----------
ComponentMnu.AddItems cmdForm
ComponentMnu.AddItems cmdLabel
ComponentMnu.AddItems cmdEdit
ComponentMnu.AddItems cmdButton
ComponentMnu.AddItems cmdCoolBtn
ComponentMnu.AddItems cmdOvalBtn
ComponentMnu.AddItems cmdCheckBox
ComponentMnu.AddItems cmdRadio
ComponentMnu.AddItems cmdCombo
ComponentMnu.AddItems cmdListBox
ComponentMnu.AddItems cmdPanel
ComponentMnu.AddItems cmdImage
ComponentMnu.AddItems cmdGroupBox
ComponentMnu.AddItems cmdScrollBox
ComponentMnu.AddItems cmdRichEdit
ComponentMnu.AddItems cmdStringGrid
ComponentMnu.AddItems cmdTabControl
ComponentMnu.AddItems cmdCanvas
ComponentMnu.AddItems cmdStatus
ComponentMnu.AddItems cmdScrollBar
ComponentMnu.AddItems cmdTrackBar
ComponentMnu.AddItems cmdFileList
ComponentMnu.AddItems cmdGuage
ComponentMnu.AddItems cmdDirTree
ComponentMnu.AddItems cmdListView
ComponentMnu.AddItems cmdBitmap
ComponentMnu.AddItems cmdOutline 
ComponentMnu.AddItems cmdSplitter
ComponentMnu.AddItems cmdGauge
     