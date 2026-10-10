' Control panel library for Rapid-Q!!!
' Version 1.0
' 3/25/01
' The name goes with the shell program name: control.exe
' I found out the arguments required to run the control panel applets!!!
' use: rundll32 <library (Shell32)>,Control_RunDLL <cplfile> 
' (@)<which dialog>
' optional comma and index to display the desired tab on the dialog!
 
' NOTE: if you have a cpl file that dosen't take any arguments and you would like
' to display it's tabbed index, use @0, comma, <index> 
' else, just use the above usage on lines 4-5.
' Not all dialogs of the Control Panel have arguments.

' If you see a sub/function that is prefixed with an 'n', it indicates that
' that dialog (applet) of the Control Panel has tabs, and the argument of the sub/function
' is the index of the tab (I think that indexing of any tab starts at 1). 

' Thanks to Rudy Elyn (email: Rudy@vt4.net) for his Config program (and source); 
' it served as a base to help me out in "cracking the command line".

' If you have any questions, comments, or just want to say hello, please email me at b_j0@yahoo.com :)

' It would be nice to email me if you like the library ;)

' It may not be all of them, but I did my best ;)

' The Control_RunDLL code in the shell command points out to me that there is an undocumented API
' sub/function called Control_RunDLL hiding in Shell32.dll and that it's argument(s) is/are:
'
' 1: the cpl file (located in the Windows System directory)
'
' 2: the number (tag) of the applet located in the cpl file that you wish to run (prefixed with an "@" (at) sign); 
'     the "tags" of each applet start at zero (I think!)
'
' 3:  the tab to display when the applet is shown (if the applet has one)
'
' 
' Oh yeah: 
' - not all of the subs load applets, they can load folders too.
' - you need Windows in order for this library to work
' - I will refer to all of the applets that have tabs, as dialogs, 
'   so all of them will be suffixed with Dlg
'
' - more libraries are coming soon :)

sub nOpenMouseDlg(index%)
PID = Shell("rundll32.exe shell32.dll,Control_RunDLL main.cpl @0,"+str$(index), 5)
end sub

sub nOpenKeyboardDlg(index%) 
if index%>1 then index%=0
PID = Shell("rundll32.exe shell32.dll,Control_RunDLL _
            main.cpl @1,"+str$(index%), 5)
end sub

sub OpenPrintersFolder
PID = Shell("rundll32.exe shell32.dll,Control_RunDLL main.cpl @2", 5)
end sub

sub OpenFontsFolder
PID = Shell("rundll32.exe shell32.dll,Control_RunDLL main.cpl @3", 5)
end sub

sub nOpenDisplayDlg(index%)
PID = Shell("rundll32.exe shell32.dll,Control_RunDLL desk.cpl @0,"+str$(index%), 5)
end sub

sub OpenTimeDlg
PID = Shell("rundll32.exe shell32.dll,Control_RunDLL timedate.cpl @0", 5)
end sub

sub nOpenDialingDlg(index%)
PID = Shell("rundll32.exe shell32.dll,Control_RunDLL telephon.cpl @0,"+str$(index%), 5)
end sub

sub nOpenSystemDialog(index%)
PID = Shell("rundll32.exe shell32.dll,Control_RunDLL sysdm.cpl @0"+str$(index%), 5)
end sub

sub OpenAddNewHardwareDlg
PID = Shell("rundll32.exe shell32.dll,Control_RunDLL sysdm.cpl @1", 5)
end sub

sub nOpenScannerDlg(index%)
PID = Shell("rundll32.exe shell32.dll,Control_RunDLL sticpl.cpl @0", 5)
end sub

sub OpenThemesDlg
PID = Shell("rundll32.exe shell32.dll,Control_RunDLL themes.cpl @0", 5)
end sub

sub nOpenAddRemoveProgramsDlg(index%)
PID = Shell("rundll32.exe shell32.dll,Control_RunDLL appwiz.cpl @0,"+str$(index%), 5)
end sub

sub nOpenPowerMgmtDlg(index%)
PID = Shell("rundll32.exe shell32.dll,Control_RunDLL powercfg.cpl @0,"+str$(index%), 5)
end sub

sub nOpenPasswordsDlg(index%)
PID = Shell("rundll32.exe shell32.dll,Control_RunDLL password.cpl @0,"+str$(index%), 5)
end sub

sub nOpenModemDlg(index%)
PID = Shell("rundll32.exe shell32.dll,Control_RunDLL modem.cpl @0,"+str$(index%), 5)
end sub

sub nOpenMMDeviceDlg(index%)
PID = Shell("rundll32.exe shell32.dll,Control_RunDLL mmsys.cpl @0,"+str$(index), 5)
end sub

sub OpenSoundsDlg
PID = Shell("rundll32.exe shell32.dll,Control_RunDLL mmsys.cpl @1", 5)
end sub

sub nOpenGamesDlg(index%)
PID = Shell("rundll32.exe shell32.dll,Control_RunDLL joy.cpl @0,"+str$(index%), 5)
end sub

sub nOpenRegionalDlg(index%)
PID = Shell("rundll32.exe shell32.dll,Control_RunDLL intl.cpl @0,"+str$(index%), 5)
end sub

sub nOpenInternetDlg(index%)
PID = Shell("rundll32.exe shell32.dll,Control_RunDLL inetcpl.cpl @0,"+str$(index%), 5)
end sub

sub nOpenUsersDlg(index%)
PID = Shell("rundll32.exe shell32.dll,Control_RunDLL inetcpl.cpl @1,"+str$(index%), 5)
end sub

' Only if one has TweakUI98 (or greater?) installed
' this one is not configured to accept arguments to display tabs at index%
sub OpenTweakUIDlg
PID = Shell("rundll32.exe shell32.dll,Control_RunDLL tweakui.cpl @0", 5)
end sub
  