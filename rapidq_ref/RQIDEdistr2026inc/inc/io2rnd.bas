SUB io2RndInter1 (io$, rndf$, LostP)
'convert text file with the two-fields per string "point,data" format
' to binary format file with interpolation of missed points
' and with averaging-out of extra points
' points sequence can be to increase or to decrease
' outputs two binary files - argue (point number) and function (point value)
'---- for example -----
' 5,17.78091 
' 4,16.61626
' 4,13.44161 extra points
' 4,19.68366
'     points 2,3 is missed
' 1,19.87037  
' 0,16.64123 
'------------------------------------
'io$   - source text file
'rndf$ - name of destination binary file. (function (point value))

'- name of destination binary file. (argue (point number))
'ArgName$=FullPathNoExt(rndf$)+"Arg"+STRIPFILEEXT(rndf$)

'LostP - return number of missed points (use @LostP in sub call)
' call io2RndInter1 (io$, rndf$, @LostP)
'------------------------------------
dim io2RndFile2 as QfileStream
dim io2Rndtmp as QfileStream
dim io2RndList as QSTRINGLIST 
dim ioNumPnt as integer
dim i0 as integer
dim pnt as single
needtoWrite=0

if fileexists (io$)=0 then showmessage ("io2RndInter File not found "+io$): exit sub
if FileSize(io$)<1 then showmessage ("io2RndInter Zero size file "+io$): LostP=-99: exit sub

io2RndList.LoadFromFile (io$)
io2RndList.text=replacesubstr$(io2RndList.text,crlfcrlf,crlf)
ArgName$=FullPathNoExt(rndf$)+"Arg"+STRIPFILEEXT(rndf$)
'print"ArgName$=";ArgName$
io2RndFile2.Open(rndf$, fmCreate)   
io2Rndtmp.Open(ArgName$, fmCreate)   

pntOld = 0: AdatOld! = 0: LostP = 1: j=0: i0=0
i0=val(Field$(io2RndList.Item(0),",", 1))
iend=val(Field$(io2RndList.Item(io2RndList.ItemCount-1),",", 1))

if iend>i0 then
	io2stp=1
elseif iend<i0 then
	io2stp=-1
else
	showmessage ("io2RndInter Begin point= EndPoint")
end if

for k=0 to io2RndList.ItemCount-1
	pnt=val(Field$(io2RndList.Item(k),",", 1))
	Adat!=val( Field$(io2RndList.Item(k),",", 2) )
	IF pnt = i0 THEN
		if needtoWrite=1 then
			io2RndFile2.Position=io2RndFile2.Position-4 ' 4 byte for single type
			io2Rndtmp.Position=io2Rndtmp.Position-4
			io2RndFile2.WriteNum(AdatOld!,Num_SINGLE ) ' гбаҐ¤­пҐ¬
			io2Rndtmp.WriteNum (pntOld,Num_SINGLE)
			
'call  AddClrString ("pnt old="+str$(pntold)+" "+str$(AdatOld!) , clred, LogEdit)
			needtoWrite=0
		end if
		io2RndFile2.WriteNum(Adat!,Num_SINGLE )
		io2Rndtmp.WriteNum (pnt,Num_SINGLE)
'call  AddClrString ("pnt="+str$(pnt)+" "+str$(Adat!), clred, LogEdit)
		pntOld = pnt: AdatOld! = Adat!
	else
		if iend>i0 then
			if pnt < i0 then
				AdatOld! = (Adat!+AdatOld!)/2
				dec i0
				needtoWrite=1
			elseIF pnt > i0 THEN ' points missed - interpoliren
				ki! = (Adat! - AdatOld!) / (pnt - pntOld) 
				FOR j = i0 TO pnt -io2stp step io2stp
					LostP = LostP + 1
					Adat1! = AdatOld! + ki!*io2stp
					io2RndFile2.WriteNum(Adat1!,Num_SINGLE )
					io2Rndtmp.WriteNum (j,Num_SINGLE)
					AdatOld! = Adat1!
				NEXT j
				AdatOld! = Adat!: pntOld = pnt:
				'io2Rndtmp.WriteLine (str$(pnt)+" "+str$(Adat!) )
				io2Rndtmp.WriteNum (pnt,Num_SINGLE)
				io2RndFile2.WriteNum(Adat!,Num_SINGLE )
				i0 = j
			end if
		elseif iend<i0 then
			if pnt > i0 then ' extra points - averaging-out
				AdatOld! = (Adat!+AdatOld!)/2
				inc i0
				needtoWrite=1
			elseIF pnt < i0 THEN ' points missed - interpoliren
				ki! = (Adat! - AdatOld!) / (pnt - pntOld) 
				FOR j = i0 TO pnt -io2stp step io2stp
					LostP = LostP + 1
					Adat1! = AdatOld! + ki!*io2stp
					io2RndFile2.WriteNum(Adat1!,Num_SINGLE )
					io2Rndtmp.WriteNum (j,Num_SINGLE)
					AdatOld! = Adat1!
				NEXT j
				AdatOld! = Adat!: pntOld = pnt:
				'io2Rndtmp.WriteLine (str$(pnt)+" "+str$(Adat!) )
				io2Rndtmp.WriteNum (pnt,Num_SINGLE)
				io2RndFile2.WriteNum(Adat!,Num_SINGLE )
				i0 = j
			end if
		END IF
		
	else
		'showmessage ("io2RndInter Begin point= EndPoint"): exit sub
	end if
	
ex1:
	if iend>i0 then
		inc i0
	elseif iend<i0 then
		dec i0
	else
		'showmessage ("io2RndInter Begin point= EndPoint")
	end if
next k

io2RndFile2.close
io2Rndtmp.close
END SUB
