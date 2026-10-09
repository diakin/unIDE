' DxfONE!h.inc for DxfONE! WIN RapidQ - Jan.2003

declare sub About
declare sub EditAbout
declare sub ParseAbout
declare sub OptionsAbout
declare sub OtherAbout

SUB About
 CREATE AboutForm AS QForm
  BorderStyle = 6
  Caption = "DxfONE! " + Ver$
  IcoHandle = ICO
  ClientHeight = 120
  ClientWidth = 600
  Visible = 0
  Enabled = 1
  Center
  CREATE About0Label AS QLabel
   Caption = "(c)2002~2003 arch. Giovanni M. Seregni - Milan, Italy - Email gmseregni@hotmail.com"
   Left = 25
   Top = 10
  END CREATE
  CREATE About1Label AS QLabel
   Caption = "Questo programma, compilato con RapidQ, appartiene al software freeware e non può essere venduto."
   Left = 55
   Top = 36
  END CREATE
  CREATE About2Label AS QLabel
   Caption = "Dell'uso del programmma e di ogni conseguenza è responsabile esclusivamente l'utilizzatore."
   Left = 55
   Top = 50
  END CREATE
  CREATE About3Label AS QLabel
   Caption = "This program compiled on Windows (RapidQ) is copyrighted freeware, it may not be sold."
   Left = 55
   Top = 68
  END CREATE
   CREATE About4Label AS QLabel
   Caption = "Use this program at your own risk, no warranties for correct function can be given."
   Left = 55
   Top = 82
  END CREATE
 End CREATE
 AboutForm.ShowModal
END SUB

SUB EditAbout
 CREATE AboutEditForm AS QForm
  BorderStyle = 6
  Caption = "Edit Menu Tutorial"
  IcoHandle = ICO
  ClientHeight = 152
  ClientWidth = 600
  Visible = 0
  Enabled = 1
  Center
  CREATE About0EditLabel AS QLabel
   Caption = "DxfONE! allows you to modify the loaded image of your bitmap:"
   Left = 25
   Top = 10
  END CREATE
  CREATE About1EditLabel AS QLabel
   Caption = "The Halftone command creates a B/W reduction, usefull for colored bitmap DXF exporting."
   Left = 55
   Top = 36
  END CREATE
  CREATE About2EditLabel AS QLabel
   Caption = "The medium mode is default and creates a B&&W DXF file easy to edit in your favorite CAD system."
   Left = 55
   Top = 50
  END CREATE
  CREATE About3EditLabel AS QLabel
   Caption = "Checking mode by Options -> SetHalftone menu allows you to brighten or darken drawing."
   Left = 55
   Top = 68
  END CREATE
   CREATE About4EditLabel AS QLabel
   Caption = "The mode you had setting is saved in config. file (DxfONE!.cf), created the 1st day of use."
   Left = 55
   Top = 82
  END CREATE
  CREATE About5EditLabel AS QLabel
   Caption = "The Outline command creates a new look of your bitmap, drawing a border around the black areas."
   Left = 55
   Top = 100
  END CREATE
  CREATE About6EditLabel AS QLabel
   Caption = "This feature, useful to generate smaller DXF files, works in B/W mode: try Halftone command before."
   Left = 55
   Top = 114
  END CREATE
 END CREATE
 AboutEditForm.ShowModal
END SUB

SUB ParseAbout
 CREATE AboutParseForm AS QForm
  BorderStyle = 6
  Caption = "Parse Menu Tutorial"
  IcoHandle = ICO
  ClientHeight = 134
  ClientWidth = 600
  Visible = 0
  Enabled = 1
  Center
  CREATE About0ParseLabel AS QLabel
   Caption = "DxfONE! allows you to save DXF files by the loaded image of your bitmaps:"
   Left = 25
   Top = 10
  END CREATE
  CREATE About1ParseLabel AS QLabel
   Caption = "The first command advailable is B&&W, usefull for almost architectural drawings."
   Left = 55
   Top = 36
  END CREATE
  CREATE About2ParseLabel AS QLabel
   Caption = "B&&W creates the DXF (points and lines) resulting by the black bitmap's pixels."
   Left = 55
   Top = 50
  END CREATE
  CREATE About3ParseLabel AS QLabel
   Caption = "The Colored command is created to import the image file as similar as possible to bitmap,"
   Left = 55
   Top = 68
  END CREATE
  CREATE About4ParseLabel AS QLabel
   Caption = "the original colors become Solid objects colored from the CAD standard palette."
   Left = 55
   Top = 82
  END CREATE
   CREATE About5ParseLabel AS QLabel
   Caption = "The colored entities are now editable, contrary to what is possible importing a raster image."
   Left = 55
   Top = 96
  END CREATE
 End CREATE
 AboutParseForm.ShowModal
END SUB

SUB OptionsAbout
 CREATE AboutOptionsForm AS QForm
  BorderStyle = 6
  Caption = "Options Menu Tutorial"
  IcoHandle = ICO
  ClientHeight = 120
  ClientWidth = 600
  Visible = 0
  Enabled = 1
  Center
  CREATE Options0EditLabel AS QLabel
   Caption = "DxfONE! allows you to modify the loaded image of your bitmap:"
   Left = 25
   Top = 10
  END CREATE
  CREATE Options1EditLabel AS QLabel
   Caption = "Checking mode by Options -> SetHalftone menu allows you to brighten or darken drawing, before"
   Left = 55
   Top = 36
  END CREATE
  CREATE Options2EditLabel AS QLabel
   Caption = "your execution of the Halftone command from Edit menu (for B/W reduction)."
   Left = 55
   Top = 50
  END CREATE
  CREATE Options3EditLabel AS QLabel
   Caption = "The medium mode is default and creates a B&&W DXF file easy to edit in your favorite CAD system."
   Left = 55
   Top = 68
  END CREATE
  CREATE Options4EditLabel AS QLabel
   Caption = "Your setting is saved in config. file (DxfONE!.cf), created the 1st day of use."
   Left = 55
   Top = 82
  END CREATE
 END CREATE
 AboutOptionsForm.ShowModal
END SUB

SUB OtherAbout
 CREATE AboutOtherForm AS QForm
  BorderStyle = 6
  Caption = " May the source be with you"
  IcoHandle = ICO
  ClientHeight = 40
  ClientWidth = 400
  Visible = 0
  Enabled = 1
  Center
  CREATE Options0OtherLabel AS QLabel
   Caption = "Other FREE software, drawings and clip of the same author:"
   Left = 5
   Top = 4
  END CREATE
  CREATE Options1OtherLabel AS QLabel
   Caption = "Gallery Download at http://digilander.libero.it/missoririsorgimento"
   Left = 50
   Top = 24
  END CREATE
 END CREATE
 AboutOtherForm.ShowModal
END SUB
  