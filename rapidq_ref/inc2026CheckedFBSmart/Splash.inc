


Create SplashForm as QForm
      BorderStyle = bsNone
      Center
      Top = 333
      Left = 401
      Width = 477
      Height = 358
    CREATE Imagestart AS QIMAGE
      BMPHandle = Splash_Res
        Left = 0
        Top = 0
        Width = 477
        Height = 301
    END CREATE
    CREATE Labelstart AS QLABEL
        Caption = "Label1"
        Left = 100
        Top = 205
        Transparent = 1
    END CREATE
    CREATE Gaugestart AS QGAUGE
        Left = 28
        Top = 221
        Width = 412
        Height = 20
        Kind = 1
	forecolor=&H800000
        Position = 0
    END CREATE
Create Label_splash_version as QLabel
      Top     = 260
      Left    = 100
      Width   = 300
      Height  = 30
      Caption = versione$
        Transparent = 1
End Create
End Create

'Create SplashTimer as QTimer
'      Enabled  = True
'      Interval = 1000
'      OnTimer  = Splash_Time
'End Create

SplashForm.Width  = 477
SplashForm.Height = 301

SplashForm.Show

LabelStart.Caption = "Loading : Start Program"
valoregaugestart = 10