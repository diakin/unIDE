'------------- constant part DebugForm etc. -------
Dim WatchedVars(1) as string

Dim Operators(1) as string
dim OperatorsPos(1) as integer
dim OperatorsLenth(1) as integer

declare sub ~Continue
declare sub Trace
declare sub ViewStep (OperPos,OperLength)

dim ModeFlg as byte
'0 - StepByStep
'1 - Continue

  dim ~DebugForm as QFORM
  dim ~WatchDisplay as QRICHEDIT
  dim ~SrcDisplay as QRICHEDIT

  dim ~StepBtn as QButton
  with ~StepBtn
  .top=2
  .left=520
  .caption="Trace"
  .onclick=Trace
  .parent=~DebugForm
  end with
  
  dim ~ContBtn as QButton
  with ~ContBtn
  .top=40
  .left=520
  .caption="Continue"
  .onclick=~Continue
  .parent=~DebugForm
  end with
  
    ~DebugForm.Caption="Debug console"
    ~DebugForm.Width=680
    ~DebugForm.Height=400
    ~DebugForm.BorderStyle=5

    ~WatchDisplay.parent=~DebugForm
    ~WatchDisplay.Font.bold=1
    '~WatchDisplay.Align=5
    ~WatchDisplay.Top=2
    ~WatchDisplay.Left=2
    ~WatchDisplay.Height=(~DebugForm.Height-40)/2
    ~WatchDisplay.Width=~DebugForm.Width-280

    ~WatchDisplay.PlainText=1
    ~WatchDisplay.ReadOnly=1
    ~WatchDisplay.ScrollBars=3
    ~WatchDisplay.WordWrap=0
    ~WatchDisplay.color=&h77EEFF


    ~SrcDisplay.parent=~DebugForm
    ~SrcDisplay.Font.bold=1
    '~WatchDisplay.Align=5
    ~SrcDisplay.Top=(~DebugForm.Height-40)/2+5
    ~SrcDisplay.Left=2
    ~SrcDisplay.Height=(~DebugForm.Height-40)/2
    ~SrcDisplay.Width=~DebugForm.Width-280

    ~SrcDisplay.PlainText=1
    ~SrcDisplay.ReadOnly=1
    ~SrcDisplay.ScrollBars=3
    ~SrcDisplay.WordWrap=0
    ~SrcDisplay.color=&HE2F978

    ~DebugForm.center

'--**************************************************'
Subi RQDebug(...)
GetLinesLack=ParamStrCount-~WatchDisplay.LineCOunt-1   
print "GetLinesLack="; GetLinesLack
FOR Ij = 1 TO GetLinesLack
	~WatchDisplay.addString  "-" 'paramStr$(i)     
next iJ

FOR Ij = 1 TO ParamStrCount
	~WatchDisplay.Line(ij-1)=paramStr$(ij)+"="+str$(paramval(ij))
NEXT Ij

pv=paramval(ParamValCount)
'print"pv=";pv
op=OperatorsPos(pv)
'print"op=";op
ol=OperatorsLenth(pv)
'print"ol=";ol

call ViewStep (Op,OL)

if ModeFlg=0 then  ~DebugForm.showmodal else  ~DebugForm.show

End Subi '=======================================================================


'***************************************
sub ViewStep (OperPos,OperLength)
~SrcDisplay.SelStart=OperPos
~SrcDisplay.SelLength=OperLength
end sub

'***************************************
sub Trace
ModeFlg=0
~DebugForm.close
end sub

'***************************************
sub ~Continue
ModeFlg=1
~DebugForm.close
end sub
'=================================================

'-------- end of constant part -------------------
  