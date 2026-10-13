$IFNDEF __SPLASHFORM_INC   ' IncManager: include guard
$DEFINE __SPLASHFORM_INC
Declare Sub Splash_Time(Sender as QTimer)

Create SplashForm as QForm
      BorderStyle = bsNone
      Center
      Top = 329
      Left = 401
      Width = 477
      Height = 365
End Create
Create SplashImage as QImage
      Parent    = SplashForm
      AutoSize  = True
      Align     = alClient
      BMPHandle = Splash_Res
      Center    = True
End Create
Create SplashTimer as QTimer
      Enabled  = True
      Interval = 1000
      OnTimer  = Splash_Time
End Create

SplashForm.Width  = SplashImage.Width
SplashForm.Height = SplashImage.Height

SplashForm.ShowModal
Sub Splash_Time(Sender as QTimer)
Sender.Tag = Sender.Tag + 1
If Sender.Tag = 4 then
   SplashForm.Close
End If
End Sub
$ENDIF   ' IncManager: __SPLASHFORM_INC
