'$INCLUDE   "RAPIDQ.INC"  
DebugProcName$="RQDebug1"
ShowVal=0

'-- ***********************************************************************'
FUNCTION ~LoadString(FileName as STRING  ) AS string
DIM ~fileStr as QFileStream
result="0"
'fmOpenRead = 0
if ~fileStr.open (FileName,0 ) then'fmCreate'
	result="-1"
	result=~FileStr.ReadStr( ~FileStr.size) 
	~FileStr.Close
	'result=1
end if

END FUNCTION

'-- ***********************************************************************'
sub ~AddClrString (AddString$, Clr, Sender as QRICHEDIT)
'Add colored string to QRICHEDIT
Sender.SelStart =len (Sender.Text)
Sender.SelLength =Len(AddString$)
Sender.SelAttributes.Color=Clr
Sender.AddStrings AddString$
end sub

'------------- constant part DebugForm etc. -------

~clr2=0 ' &H80CBF0
~clr3=&HB6B5B3
~SelGridClr=&HCBF2FF'clo
~clSilver=&HB6B5B3 '&HA9A9A6
~clGreen=&H007900

CONST dalNone = 0
CONST dalTop = 1
CONST dalBottom = 2
CONST dalLeft = 3
CONST dalRight = 4
CONST dalClient = 5 

CONST ~goFixedVertLine = 0'-When True, horizontal lines appear between the rows
'-within nonscrolling regions.

CONST ~goFixedHorzLine = 1'-When True, vertical lines appear between the columns
'-within nonscrolling regions.

CONST ~goVertLine = 2 '- When True, horizontal lines appear between the rows.

CONST ~goHorzLine = 3
CONST ~goRangeSelect = 4
CONST ~goDrawFocusSelected = 5
CONST ~goRowSizing = 6
CONST ~goColSizing = 7
CONST ~goRowMoving = 8
CONST ~goColMoving = 9
CONST ~goEditing = 10
CONST ~goTabs = 11
CONST ~goRowSelect = 12
CONST ~goAlwaysShowEditor = 13
CONST ~goThumbTracking = 14

~stops=0
WaitCurs=1
~RunToCursorFlg=1
p~v=0


'--- Declarations ---
Declare Sub ~~exitdebug
Declare Sub ~DebugFormClose(Action AS INTEGER)

Declare SUB  ~SelectCell (Col% , Row%, CanSelect%, Sender AS QStringGrid)  
ColGalka=4
Declare Sub ~DrawCell  (Col%, Row%, State%, Rect AS QRect, Sender AS QStringGrid)

Declare Sub ~RunToCursor
Declare Sub ~tIMERBtnClick
Declare Sub ~DebugTimerOver
Declare Sub ~Debug1TimerOver
Declare Sub ~DebugFormResize 
'$INCLUDE "RichEdPopUp.inc"
'$Include "constants.inc"

Dim WatchedVars(1) as string

Dim ~Operators(1) as string
dim ~OperatorsPos(1) as integer
dim ~OperatorsLenth(1) as integer

dim ~DebugTimer as QTimer
~DebugTimer.Interval=200
~DebugTimer.Enabled=1
~DebugTimer.OnTimer=~DebugTimerOver

dim ~DebugTimer1 as QTimer
~DebugTimer1.Interval=400
~DebugTimer1.Enabled=0
~DebugTimer1.OnTimer=~Debug1TimerOver

declare sub ~Continue
declare sub ~Step
declare sub ViewStep (OperPos,OperLength)

dim ModeFlg as long
'-1 - RunToCursor
'0 - Continue
'1 - StepByStep
'2 - Timer
'4 - InstantWatch

ModeFlg=1

create ~DebugForm as QFORM
	Caption="Debug console"
	Width=Screen.Width*0.8'800
	Height=Screen.Height*0.8 '600'Screen.Height*0.7'460
	'BorderStyle=5
	center
	onresize=~DebugFormResize 
	onclose=~DebugFormClose
	
	CREATE  ~DebugMainMenu as QMainMenu
		
		CREATE ~DebugRunToCursorMnu AS QMenuItem 
			caption="Run To Cursor"
			onclick=~RunToCursor
			'visible=0
		end create
		CREATE ~DebugStepMnu AS QMenuItem 
			caption="Step"
			onclick=~Step
		end create
		CREATE ~DebugContinueMnu AS QMenuItem 
			caption="Continue"
			onclick=~Continue
		end create
		
	end create
	
	CREATE ~_~_BigPanel AS QPANEL 
		Align = dalLeft ' 3
		Width=~DebugForm.Width-120
		color=&H006F00
		
		CREATE ~DebugPanel AS QPANEL 
			Align = dalTop 'alTop '-- Fill top portion of form 
			Height = 200 
			'Caption = "PANEL" 
			'Width=680-80
			
			create  ~LogEdit as QRICHEDIT '~WatchDisplay
				Align =daltop ' 5
				Font.bold=0
				'Font.size=11
				Font.Name="Courier New"'"FixedSys"
				'Height=(~DebugForm.Height-40)*0.3
				PlainText=1
				ReadOnly=1
				ScrollBars=3
				WordWrap=0
				color=&hffEEcc
				visible=0 ' 
				hideselection=0
				
			end create
			CREATE ~WatchPointStringGrid AS QSTRINGGRID
				Align =dalClient ' dalright 
				AddOptions(~goEditing,~goColSizing,~goRowSizing) 'goEditing
				FixedRows = 1
				FixedCols = 1 
				ColCount = 6 
				RowCount = 3
				DefaultRowHeight=16
				DefaultColWidth=150
				color=&h77EE0F
				cell (0,0) ="№"
				cell (1,0) ="SubName.VarName"
				cell (2,0) ="Value"
				cell (3,0) ="Watch Value"
				cell (4,0) ="Use Watch"
				cell (5,0) ="Var type"
				ColWidths(0)=30
				ColWidths(4)=60
				ColWidths(5)=60
				
				'OnSetEditText=ChangeSel 
				OnDrawCell = ~DrawCell
				OnSelectCell = ~SelectCell
				'OnListDropDown=SRGridListDropDown
				'OnKeyPress=SRGridKeyDn 
				
			END CREATE
			
		END CREATE 
		CREATE ~DebugSplitter AS QSPLITTER 
			'-- Note position 
			Align =1' alTop '-- Fill middle 
			Cursor =-15' crVSplit 
			Height = 10 
		END CREATE 
		
		create ~SrcDisplay as QRICHEDIT
			Align = 5'alClient 
			'Font.bold=1
			Font.Name="Courier New"'"FixedSys"
			PlainText=1
			ReadOnly=1
			Enabled=1
			hideselection=0
			ScrollBars=3
			WordWrap=0
			color=&HEEE2CF'&HE2F978
			'width=~SrcDScrollBox.width
			'height=~SrcDScrollBox.width+300
		end create
		
	end create 'big panel
	
	create ~StepBtn as QButton
		top=2
		left=~_~_BigPanel.Width+10
		caption="Step"
		onclick=~Step
	end create
	
	create ~ContBtn as QButton
		top=40
		left=~_~_BigPanel.Width+10
		caption="Continue"
		onclick=~Continue
	end create
	
	create ~tIMERBtn as QButton
		top=80
		left=~_~_BigPanel.Width+10
		caption="Timer"
		onclick=~tIMERBtnClick
	end create
	CREATE QuickCheckBox AS QCHECKBOX
		Caption = "Not showing"
		left=~_~_BigPanel.Width+10
		Top = 120
	END CREATE
	CREATE ~CoolExit AS QCoolbtn 
		left=~_~_BigPanel.Width+10
		Top = 160
		caption="Exit"
		onclick=~~exitdebug
	END CREATE
	
	
	
end create 'form


~srcdisplay.loadfromfile("$srcdisplay.bas") 
~srcdisplaylinecount=~srcdisplay.linecount 

DbgDisplayTxt$=~LoadString("$DbgDisplay.bas")
~OpCount1=tally(DbgDisplayTxt$,"RQDebug1(")+1

redim ~Operators(~OpCount1-1) as string
redim ~Operatorspos(~OpCount1-1) as integer
redim ~Operatorslenth(~OpCount1-1) as integer

dim file as qfilestream 
file.open("$~OpPos.dat", fmread) 
file.loadarray(~Operatorspos(1),~OpCount1-1) 
file.close

file.open("$~OpLen.dat", fmread) 
file.loadarray(~Operatorslenth(1), ~OpCount1-1) 
file.close

'-------- end of constant part -------------------

'~DebugForm.showmodal

'--**************************************************'
Subi RQDebug1(...)
if ~CoolExit.Down = 1  then goto exitsubi

if  ShowVal=0 then goto NoShowVal

with ~WatchPointStringGrid
	
	.RowCount=ParamStrCount+1' GetLinesLack
	
	~k=0
	~l=1
	FOR Ij = 1 TO ParamStrCount
		if instr(paramStr$(ij),"~$#")>0 then ' string parameter - var name
			valName$=paramStr$(ij)-"~$#"
			if Ij< ParamStrCount then 
				if instr(paramStr$(ij+1),"~$#")=(0) then ' string parameter - vaк value
					.Cell(1,Ij)=valName$
					.Cell(2,Ij)=paramStr$(ij+1)
					.Cell(5,Ij)="String"
					~k=~k+2
					inc ~l
					inc ij
				else
					.Cell(1,Ij)=valName$
					.Cell(2,Ij)=str$(paramval(ij-~k))
					.Cell(5,Ij)="Int"
				end  if
			else
				.Cell(1,Ij)=valName$
				.Cell(2,Ij)=str$(paramval(ij-~k))
				.Cell(5,Ij)="Int"
				
			end if
		else
			showMessage "Error in Debug function. First parametr is not Var name"
			
		end if
	NEXT Ij
ShowVal=0

	NoShowVal:

	p~v=paramval(ParamValCount) ' operator index 
	'call  ~AddClrString ("310:p~v="+str$(p~v), clred, ~LogEdit)
	op=~OperatorsPos(p~v)
	ol=~OperatorsLenth(p~v)
	
	if ModeFlg=-1 then
		if WaitCurs>=op and WaitCurs<=op+ol then ModeFlg=1 :QuickCheckBox.checked=0
	end if
	
	for Ij=1 to .RowCount-1
		if .Cell(4,Ij)= "1" then 
			if .Cell(5,Ij)= "Int" then
				
				if val(.Cell(3,Ij))=val(.Cell(2,Ij)) then
					ModeFlg=1
				else
					
				end if
			elseif .Cell(5,Ij)= "String" then
				if .Cell(3,Ij)=.Cell(2,Ij) then
					ModeFlg=1
				else
					
				end if
			else 
			end if
		end if
		
	next 
	
end with

if QuickCheckBox.checked=0 then call ViewStep (Op,OL)


doevents
'~DebugForm.close

if ModeFlg>0  then  
	' show window and waiting for.. 
	ModeFlg=-2
	if ~DebugForm.visible =0 then ~DebugForm.show'modal 
	while ModeFlg=-2
		' waiting flag changing   for continue
		' 
		doevents
	wend
else  
end if
exitsubi:
End Subi '=============================

'***************************************
sub ViewStep (OperPos,OperLength)
~SrcDisplay.SelStart=OperPos-1
~SrcDisplay.SelLength=OperLength+1
end sub
'***************************************
sub ~Continue
ModeFlg=0
~DebugTimer1.Enabled=0
if p~v =~OpCount1-1 then ~DebugForm.close
end sub
'*****************************************
Sub ~Debug1TimerOver
ModeFlg=2
if p~v =~OpCount1-1 then ~DebugForm.close
End Sub 
'*****************************************
Sub ~tIMERBtnClick
ModeFlg=2:
~DebugTimer1.Enabled=1
'~RunToCursorFlg=0
'~DebugForm.close
End Sub 
'*****************************************
Sub ~RunToCursor
' save cursor position
~DebugTimer1.Enabled=0
WaitCurs=~SrcDisplay.SelStart
'call  ~AddClrString ("357:WaitCurs="+str$(WaitCurs), clred, ~LogEdit)
ModeFlg=-1
if p~v =~OpCount1-1 then ~DebugForm.close
End Sub 
'***************************************
sub ~Step
ModeFlg=1
~DebugTimer1.Enabled=0
if p~v =~OpCount1-1 then ~DebugForm.close
end sub
'*****************************************
Sub ~DebugFormResize 
~_~_BigPanel.Align = 3
~_~_BigPanel.Width=~DebugForm.Width-120
End Sub  
'*****************************************
Sub ~DebugTimerOver
~StepBtn.left=~_~_BigPanel.Width+10
~ContBtn.left=~_~_BigPanel.Width+10
~tIMERBtn.left=~_~_BigPanel.Width+10
ShowVal=1

End Sub 
'*****************************************
SUB ~DrawCell (Col%, Row%, State%, Rect AS QRect, Sender AS QStringGrid)

with Sender
	'!!!-------      'and Col%>1 'and Col%<>3'
	if Row%=.Row and Row%>0 and Col%=.Col   then     
		.FillRect(Rect.Left, Rect.Top, Rect.Left+.ColWidths(Col%), Rect.Top+.RowHeights(Row%), ~SelGridClr)
		.TextOut(Rect.Left+2, Rect.Top+2, .Cell(Col%, Row%), ~Clr2, -1)
		
	elseif Row%>0 then
		.TextOut(Rect.Left+2, Rect.Top+2, .Cell(Col%, Row%), ~Clr2, -1)
	end if      
	
	if  col%=4 and row%<>0 then ' checkbox
		if row%=ctg then GalClr= &H0000FF else GalClr= &H0000FF 'clBlue 
		.FillRect(Rect.Left, Rect.Top, Rect.Left+.ColWidths(Col%), Rect.Top+.RowHeights(Row%), .color)
		.Rectangle(Rect.Left+1, Rect.Top+1, Rect.Left+13, Rect.Top+13, -1)
		if .Cell(ColGalka, Row%)="1" then 
			.Line(Rect.Left+2, Rect.Top+2, Rect.Left+6, Rect.Top+10, GalClr)
			.Line(Rect.Left+3, Rect.Top+2, Rect.Left+7, Rect.Top+10, GalClr)
			.Line(Rect.Left+6, Rect.Top+10, Rect.Left+10, Rect.Top+6, GalClr)
			.Line(Rect.Left+7, Rect.Top+10, Rect.Left+10, Rect.Top+7, GalClr)
		else
			.FillRect(Rect.Left, Rect.Top, Rect.Left+.ColWidths(Col%), Rect.Top+.RowHeights(Row%), .color)
			.Rectangle(Rect.Left+1, Rect.Top+1, Rect.Left+13, Rect.Top+13, 0)
		end if
	else
	end if
	
	if .Cell(1, .RowCount-1)<>"" or .Cell(2, .RowCount-1)<>"" then .InsertRow (.RowCount) 
	
end with

End Sub 

'*****************************************
SUB  ~SelectCell (Col% , Row%, CanSelect%, Sender AS QStringGrid)  
with Sender
	if  col%=ColGalka then .DelOptions (~GoEditing) else  .AddOptions (~GoEditing)
	
	if Sender.Cell(1, .RowCount-1)<>"" then 
		.InsertRow (.RowCount) 
	else
		
	end if
	
	for r%=1 to .RowCount-1
		.Cell(0, R%)=str$(r%)
	next
	
	if  col%=ColGalka then  
		if .Cell(ColGalka, Row%)="1" then .Cell(ColGalka, Row%)="0" else .Cell(ColGalka, Row%)="1"
	end if
	
	oldcell$=.Cell(Col%, Row%)
	
	
end with
END  SUB 



'*****************************************
Sub ~DebugFormClose (Action AS INTEGER)

ModeFlg=1
End Sub  

'*****************************************
Sub ~~exitdebug
~CoolExit.Down = True 
 
End Sub 
