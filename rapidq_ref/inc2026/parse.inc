'-- *********************************************************************'
function GetCharNum (Oper$ as string, getC as string) as long
'return Char count  in checked string
'getC - Char 
'Oper$ - checked string
'if getC commented,  or quoted (just text)  - return error code
'print "getC=";getC

DIM ch  AS STRING * 1
ch=getC
'print"qt=";qt

result=-1 ' error
QTNum=0 
tmpres=0

FirstRem=instr(Oper$, "'")

FirstQT=instr(Oper$, qt)
'print"FirstQT=";FirstQT

if FirstRem < FirstQT and FirstRem >0 then ' есть комментарий - его отбрасываем
	Oper$=left$(Oper$,FirstRem)
	result=tally(Oper$,getC)
	exit function
end if

'print"Oper$=";Oper$

for ~i=1 to Len(Oper$)
	chrs$=Oper$[~i]
	if chrs$=qt and QTNum=0 then 
		QTNum=1 'следующий char  находится после первого вхождения qt
	elseif chrs$=qt and QTNum=1 then
		QTNum=0 'следующий char находимся после второго вхождения qt
	elseif chrs$=ch and QTNum=0 then
		inc tmpres
		'print"tmpres=";tmpres
	else
	end if
next i
result=tmpres

end function 'sub '


'-- *********************************************************************'
Function GetVarPos (Oper$ as string, getV$ as string) as long
'return variable  position in checked string
'getV$ - variable name 
'Oper$ - checked string
'if getV$ commented,  or quoted (just text, not varname)  - return error code
result=-1 ' error
'cr+lf+",./\| !@#$%^&*()_+=-?><~`;:[]{}'"+ht+qt
defstr Lsep$="()[]=><, :+-*\/;."
defstr Rsep$="[()]=><, :'+-*\/;."

Oper$=lcase$(Oper$)-ht
getV$=lcase$(getV$)-ht

Wpos=instr(Oper$,getV$) 
if Wpos=0 then result=0: exit function 'pattern not contained
'check comment and string

while Wpos>0 

	if (instr(Lsep$,Oper$[Wpos-1])>0 or Wpos=1) and (instr(Rsep$,Oper$[Wpos+len(getV$)])>0  or Wpos+len(getV$)-1=len(Oper$))  then
		'check string 
		QPos1=rinstr(Wpos,Oper$,qt) ''1 quote pos   
		QPos2= instr(Wpos,Oper$,qt) '2 quote pos   
		CPos=rinstr(Wpos,Oper$,"'") 'comment pos  

		if QPos1<Wpos and QPos2 >Wpos and QPos1>0 then 'it's string, not var
		elseif (CPos<Wpos and CPos>0) and  QPos1<CPos    then 'it's comment and QPos2>0
		else
			result=Wpos 
			exit while
		end if
	else
	end if
		Wpos=instr(Wpos+1, Oper$,getV$) 
	result=-2 'present, but not var
wend

end function

'-- *********************************************************************'
sub ParseDim (Var$() as string,VarType$() as string, SrcTxt$ as string, VarCount as long)
SrcTxt$=Ucase$(SrcTxt$)
DIMPos=instr(SrcTxt$,"DIM ")

if DIMPos=0 then VarCount=0: exit sub

SrcTxt$=right$(SrcTxt$,len(SrcTxt$)-DIMPos-3)
asPos=GetVarPos(SrcTxt$,"AS")
comPos=instr(SrcTxt$,",")
while comPos >0 
	Var$(k)=trim$(Left$(SrcTxt$, asPos-1))
	VarType$(k)=trim$(mid$(SrcTxt$,asPos+2, comPos-asPos-2))
	SrcTxt$=right$(SrcTxt$,len(SrcTxt$)-comPos)
	asPos=GetVarPos(SrcTxt$,"AS")
	comPos=instr(SrcTxt$,",")
	inc k
wend
Var$(k)=trim$(Left$(SrcTxt$, asPos-1))
VarType$(k)=trim$(right$(SrcTxt$,len(SrcTxt$)-asPos-1))
VarCount=k+1
end sub '


'-- *********************************************************************'


'-- *********************************************************************'
'DEFSTR A, B, C="Hello", D, E
sub ParseDef (Var$() as string,VarType$ as string, SrcTxt$ as string, VarCount as long)
SrcTxt$=Ucase$(SrcTxt$)
DEFPos=instr(SrcTxt$,"DEF")

if DEFPos=0 then VarCount=0: exit sub

SrcTxt$=right$(SrcTxt$,len(SrcTxt$)-DEFPos-2)
VarPos=instr(SrcTxt$," ")-1
VarType$=left$(SrcTxt$,VarPos)
SrcTxt$=right$(SrcTxt$,len(SrcTxt$)-VarPos)

'VarType$=left$(SrcTxt$,instr(SrcTxt$," "))

select case VarType$
case "STR"
VarType$="STRING"
case "DBL"
VarType$="DOUBLE"
case "INT"
VarType$="INTEGER"
case "LNG"
VarType$="LONG"
case "SNG"
VarType$="SINGLE"
CASE ELSE

end select

ComCnt=tally(SrcTxt$,",")
for k=0 to ComCnt-1
	Var$(k)=trim$(field$(SrcTxt$,",",k+1)-VarType$)
next k
Var$(k)=trim$(field$(SrcTxt$,",",k+1))
VarCount= k+1
end sub 
'-- *********************************************************************'

'-- *********************************************************************'
sub DelComments (STxt$ as string)
'delete comments in SrcTxt$
'function tally -  see http://forum.qbasicnews.com/viewtopic.php?t=8787
' qt as string =chr$(34)
NQT=tally(STxt$, qt)
PQT1=0
PQT2=0
PRem=0
for i=0 to NQT+1 
	PQT1=instr(PQT2+1,STxt$, qt)
	if PQT1=0 and PQT2>0 then ' no quotes yet
		i=NQT+1
	else
		PQT2=instr(PQT1+1,STxt$, qt)
	end if
	'PQT2=instr(PQT1+1,STxt$, qt)
	PRem=instr(PRem+1,STxt$, "'")
		if (PRem < PQT1 and PRem >0) or (PQT1=0 and PRem >0)  then 
			STxt$=left$(STxt$,PRem-1)
			'print"2STxt$=";STxt$
		exit for
		else
		PRem=PQT2
		end if
next
end sub '
'-- *********************************************************************'
function DelCommentsF (STxt$ as string) as string
DelComments (@STxt$)
result=STxt$
end function 

'-- *********************************************************************'
sub ReplaceComments (STxt$ as string)
'replace comments in SrcTxt$ by spaces, so full string lenth is not changing
NQT=tally(STxt$, qt)
PQT1=0
PQT2=0
PRem=0
for i=0 to NQT+1 
	PQT1=instr(PQT2+1,STxt$, qt)
	if PQT1=0 and PQT2>0 then ' больше кавычек нет
		i=NQT+1
	else
		PQT2=instr(PQT1+1,STxt$, qt)
	end if
	'PQT2=instr(PQT1+1,STxt$, qt)
	PRem=instr(PRem+1,STxt$, "'")
		if (PRem < PQT1 and PRem >0) or (PQT1=0 and PRem >0)  then 
			cmntLen=len(STxt$)-PRem+1
			STxt$=replace$(STxt$,STRING$(cmntLen, " "), PRem)
			'STxt$=left$(STxt$,PRem-1)
			'print"2STxt$=";STxt$
		exit for
		else
		PRem=PQT2
		end if
next
end sub '
'-- *********************************************************************'

'-- *********************************************************************'
sub GetOperators (Oper$() as string,OperPos() as integer, SrcTxt$ as string,NumOpers as long)
'parse and return  operators in checked string SrcTxt$
'operators - not quoted and not commented parts of line delimited by ":"
'Oper$() - array of operators
'OperPos() - operator's positions

ch$=chr$(58)
QTNum=0 
dim SrcList as QStringList
bop=1: eop=1

SrcList.text=SrcTxt$
for i=0 to SrcList.ItemCount-1
	ReplaceComments (@SrcList.Item(i))
	SrcL$=rtrim$(SrcList.Item(i))
	ss$=right$(SrcL$,1)
	if ss$="_" then SrcList.Item(i)=SrcL$
next i

SrcList.text=replacesubStr$(SrcList.text,"_"+crlf,"")


SrcTxt$=SrcList.text
SrcTxt$=replacesubStr$(SrcTxt$,"_"+crlf,"")
SrcTxt$=replacesubStr$(SrcTxt$,crlf," :")

k=0
for ~i=1 to Len(SrcTxt$)
	chrs$=SrcTxt$[~i]
	if chrs$=qt and QTNum=0 then 
		QTNum=1 'следующий char  находится после первого вхождения qt
	elseif chrs$=qt and QTNum=1 then
		QTNum=0 'следующий char находимся после второго вхождения qt
	elseif chrs$=ch$ and QTNum=0 then
		eop=~i
		~tmp$=trim$(mid$(SrcTxt$,bop,eop-bop))
'print"~tmp$=";~tmp$
		if ~tmp$<>"" and ~tmp$<>":" then
			Oper$(k)=~tmp$
			OperPos(k)=bop
			k ++
		end if
			bop=eop+1
	else
	end if
next ~i
eop=~i

~tmp$=trim$(mid$(SrcTxt$,bop,eop-bop))
if ~tmp$<>"" then
	Oper$(k)=~tmp$
	OperPos(k)=bop
end if

NumOpers=k
'print"sub GetOperators.NumOpers=";NumOpers
end sub '
'-- *********************************************************************'
         