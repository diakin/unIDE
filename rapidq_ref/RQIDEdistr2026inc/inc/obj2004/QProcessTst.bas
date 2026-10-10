$INCLUDE "RAPIDQ.INC"
$include "Object2004\QProcess.inc"
'--- Declarations ---


'QProgress Example


'Subs internal 
declare sub rout1

DECLARE SUB OpenClick
DECLARE SUB SendClick
DECLARE SUB fin

'Variables globales 
dim num as long
dim process as QProcess
process.OnProcess=rout1 'process routine

CREATE Form ASQFORM
	Caption = "Test process"
	Width=200
	Height=200
	Center
	CREATE OpenButton ASQBUTTON
		Caption="&Open"
		Left=20
		Top=50
		height=20
		OnClick=OpenClick
	END CREATE
	CREATE butexit ASQBUTTON
		Caption="Close"
		Left=20
		Top=75
		height=20
		Enabled=0
		OnClick=fin
	END CREATE
	CREATE ED ASQEDIT
		left=10
		top=10
		width=100
	END CREATE
END CREATE
Form.ShowModal

'*****************************************
SUB fin
process.close
OpenButton.enabled=1
end sub

'*****************************************
SUB OpenClick
OpenButton.enabled=0
butexit.enabled=1
process.priority=ProcessNormal
process.open
END SUB

'*****************************************
sub rout1 ' process routine
while true
	sleep 0.1
	num++
	ed.text="Count"+str$(num)
wend
end sub 
