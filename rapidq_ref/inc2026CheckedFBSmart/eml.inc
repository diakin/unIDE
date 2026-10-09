'*****************************************
Function GetSubjCodePage( Subject As String) As String
zza$=Subject
CodePage$=field$(zza$,"?",2)
result=""
if CodePage$ <>"" then
	result=CodePage$
elseif CodePage$="" and isKOI8(zza$)=1 then
	result="koi8-r"
else
	result=""
end if

end function

'*****************************************
Function GetSubjCodeMethod( Subject As String) As String
result=lcase$(field$(Subject,"?",3))
end function

'*****************************************
Function GetMsgBodyContentType ( Msg As String) As String
'Content-Type: text/plain; charset=koi8-r
'Content-Type: text/plain; charset=UTF-8
'Content-Type: text/plain;format=flowed;charset="koi8-r";reply-type=original

Msg=replacesubstr$(Msg,ht," ")
Msg=replacesubstr$(Msg,crlf+" ","")
Msg=replacesubstr$(Msg,";"+crlf,"; ")
'print"Msg=";Msg


ContentType$=GetHeaderField(Msg,"Content-Type")
'print"GetMsgBodyContentType ContentType$=";ContentType$
result=field$(ContentType$,";",1)
end function

'*****************************************
Function GetMsgBodyCodePage ( Msg As String) As String
'Content-Type: text/plain; charset=koi8-r
'Content-Type: text/plain; charset=UTF-8
'Content-Type: text/plain;format=flowed;charset="koi8-r";reply-type=original
dim i as long
Msg=replacesubstr$(Msg,ht," ")
Msg=replacesubstr$(Msg,crlf+" ","")
Msg=replacesubstr$(Msg,";"+crlf,"; ")

ContentType$=GetHeaderField(Msg,"Content-Type")
semicolCount=tally(ContentType$,";")
for i=1 to semicolCount
	valfield$=field$(ContentType$,";",i+1)
	if instr(valfield$,"charset=")>0 then
		param$=field$(valfield$,"=",2)
		exit for
	else
		
	end if
	
next i
result=param$
end function

'*****************************************
Function GetMsgBodyCodeMethod( Msg As String) As String
'Content-Transfer-Encoding: 8bit
dim i as long
Msg=replacesubstr$(Msg,ht," ")
Msg=replacesubstr$(Msg,crlf+" ","")
Msg=replacesubstr$(Msg,";"+crlf,"; ")

ContentTransferEncoding$=GetHeaderField(Msg,"Content-Transfer-Encoding")
semicolCount=tally(ContentTransferEncoding$,";")
for i=1 to semicolCount
	valfield$=field$(ContentTransferEncoding$,";",i+1)
	if instr(valfield$,"charset=")>0 then
		param$=field$(valfield$,"=",2)
		exit for
	else
		
	end if
next i
result=param$
end function

'*****************************************
Function GetHeaderField( Header As String, Field as string) As String
Header=replacesubstr$(Header,ht," ")
Header=replacesubstr$(Header,crlf+" ","")
Header=replacesubstr$(Header,";"+crlf,"; ")

'print"Header=";Header
' returm requared field value from message header
dim i as long
fieldidx=-1
dim HeaderList as QStringList
HeaderList.text=(Header)

if instr(Field,":")=0 then Field=Field+":"

field=lcase$(Field)'+":"
lenfield=len(field)

for i2=0 to HeaderList.Itemcount-1
	hitem$=lcase$(HeaderList.Item(i2))
	lenitem=len(hitem$)
	instrsep=instr(hitem$,":")
	
	'if  instr(hitem$,field) >0 then
	if  left$(hitem$,lenfield) =field then
		fieldidx=i2: exit for
	end if
	
next i2

if fieldidx =-1 then
	result=""
else
	result=trim$(mid$(HeaderList.Item(fieldidx),instrsep+1,lenitem-instrsep))
end if
end function

'*****************************************
Function GetMSGHeader( Source As String) As String
dim MSGHeader as qstringlist 'string
dim MSG as qstringlist

Source=replacesubstr$(Source,ht," ")
Source=replacesubstr$(Source,crlf+" ","")
Source=replacesubstr$(Source,";"+crlf,"; ")

MSGHeader.clear

MSG.text=Source
'print "------------- 136 GetMSGHeader Source=";Source
emptylineIDX=-1

emptylineIDX=MSG.IndexOf("")

if emptylineIDX=-1 then emptylineIDX=MSG.ItemCount-1

for i=0 to emptylineIDX-1
	MSGHeader.additems (MSG.item(i))
next i

result=MSGHeader.text

end function

'*****************************************
Function GetMSGBody( Source As String) As String 
dim MSGBody as qstringlist 'string
dim MSG as qstringlist

Source=replacesubstr$(Source,ht," ")
Source=replacesubstr$(Source,crlf+" ","") ' îñíîâíîé 
Source=replacesubstr$(Source,";"+crlf,"; ")

MSGBody.clear

MSG.text=Source
emptylineIDX=-1

emptylineIDX=MSG.IndexOf("")

if emptylineIDX=-1 then  emptylineIDX=1 

for i=emptylineIDX to MSG.itemcount-1
	MSGBody.additems (MSG.item(i))
next i

result=MSGBody.text

end function


'*****************************************
Function isKOI8( Red$ As String) As long
' ïðîâåðÿåò êîäèðîâêó ñòðîêè íà koi8
'îÏ×ÏÅ ÓÏÏÂÝÅÎÉÅ × ÇÏÓÔÅ×ÏÊ ËÎÉÇÅ 'diakin-ðÒÏÇÒÁÍÍÁ RQ Search and Replace - ÐÏÉÓË É ÚÁÍÅÎÁ Ô'.
'ïÔÏÐÌÅÎÉÅ, ×ÏÄÏÓÎÁÂÖÅÎÉÅ..

result=0
'if instr(Red$, "Ï×")>0 then result=1 '"koi8-r"
'if instr(Red$, "ÏÏ")>0 then result=1 '"koi8-r"
'if instr(Red$, "ÂÝ")>0 then result=1 '"koi8-r"
'if instr(Red$, "ÏÄ")>0 then result=1 '"koi8-r"
'if instr(Red$, "Ï×")>0 then result=1 '"koi8-r"
'if instr(Red$, "Ï×")>0 then result=1 '"koi8-r"

if instr(Red$, " × ")>0 then result=1 '"koi8-r"
'if instr(Red$, "ÏÇ")>0 then result=1 '"koi8-r"

'if instr(Red$, "ÐÏ")>0 then result=1 '"koi8-r"
if instr(Red$, "ÚÁ")>0 then result=1 '"koi8-r"


if instr(Red$, "ÄÙ")>0 then result=1 '"koi8-r"
if instr(Red$, "×Ù")>0 then result=1 '"koi8-r"
if instr(Red$, "ÔØ")>0 then result=1 '"koi8-r"
if instr(Red$, "ïÔ")>0 then result=1 '"koi8-r"

if instr(Red$, "ÂÉ")>0 then result=1 '"koi8-r"
if instr(Red$, "ÄÉ")>0 then result=1
if instr(Red$, "ÇÉ")>0 then result=1
if instr(Red$, "ËÉ")>0 then result=1
if instr(Red$, "ÌÉ")>0 then result=1
if instr(Red$, "ÍÉ")>0 then result=1
if instr(Red$, "ÐÉ")>0 then result=1
if instr(Red$, "ÒÉ")>0 then result=1
if instr(Red$, "ÔÉ")>0 then result=1
if instr(Red$, "ÖÉ")>0 then result=1
if instr(Red$, "ÏÉ")>0 then result=1 '"koi8-r"
if instr(Red$, " É ")>0 then result=1 '"koi8-r"

if instr(Red$, " É")>0 then result=1
if instr(Red$, " é ")>0 then result=1

if instr(Red$, "ÉÛ")>0 then result=1

if instr(Red$, "ÉÚ")>0 then result=1
if instr(Red$, "éÚ")>0 then result=1

if instr(Red$, "áé")>0 then result=1
if instr(Red$, "äé")>0 then result=1
if instr(Red$, "éé")>0 then result=1

if instr(Red$, "pÉ")>0 then result=1

if instr(Red$, "Ké")>0 then result=1

if instr(Red$, "ØÛ")>0 then result=1
if instr(Red$, "ÅÛ")>0 then result=1

if instr(Red$, "úÄ")>0 then result=1

if instr(Red$, "ÚÁ")>0 then result=1
if instr(Red$, "ÚÕ")>0 then result=1

if instr(Red$, "úÁ")>0 then result=1
if instr(Red$, "ÚÙ")>0 then result=1
if instr(Red$, "ÚÏ")>0 then result=1
if instr(Red$, "ÚÉ")>0 then result=1

if instr(Red$, "ÚÒ")>0 then result=1

end function

'*****************************************
' BASE64 encode
Function RQBASE64Encode(s As String) As String
Dim lenStr As Long, endPos As Long, lastChars As Long, l As Long, i As Long
dim cBASE64 as string
cBASE64=""
dim b64(63) As String
dim b256(255) As Long

For i = 0 To 63 Step 1
	b64(i) = Mid$(Base64Table, i + 1, 1)
	b256(Asc(b64(i))) = i
Next

lenStr = Len(s)
lastChars = lenStr Mod 3
endPos = lenStr - lastChars

For i = 1 To endPos Step 3
	l = CLng(AscB(Mid$(s, i, 1))) * 65536 + CLng(AscB(Mid$(s, i + 1, 1))) * 256 + CLng(AscB(Mid$(s, i + 2, 1)))
	cBASE64 = cBASE64 & b64(l \ 262144) & b64((l \ 4096) Mod 64) & _
	b64((l \ 64) Mod 64) & b64(l Mod 64)
Next

Select Case lastChars
Case 1
	l = CLng(AscB(Right$(s, 1))) * 16
	cBASE64 = cBASE64 & b64((l \ 64) Mod 64) & b64(l Mod 64) & "=="
Case 2
	l = CLng(AscB(Mid$(s, lenStr - 1, 1))) * 1024 + CLng(AscB(Right$(s, 1))) * 4
	cBASE64 = cBASE64 & b64((l \ 4096) Mod 64) & _
	b64((l \ 64) Mod 64) & b64(l Mod 64) & "="
End Select
result=cBASE64

End Function


'*****************************************
' BASE64 decode
Function RQBASE64Decode (stxt As String) As String
Dim lenStr As Long, endPos As Long, lastChars As Long, l As Long, i As Long
dim RQBASE64E as string
RQBASE64E=""
dim b64(63) As String
dim b256(255) As Long


For i = 0 To 63 Step 1
	b64(i) = Mid$(Base64Table, i + 1, 1)
	b256(Asc(b64(i))) = i
Next

lenStr = Len(stxt)
If Right$(stxt, 2) = "==" Then
	lenStr = lenStr - 2
Else
	If Right$(stxt, 1) = "=" Then lenStr = lenStr - 1
End If

lastChars = lenStr Mod 4
endPos = lenStr - lastChars
For i = 1 To endPos Step 4
	l=b256(Asc(Mid$(stxt,i,1)))*262144+b256(Asc(Mid$(stxt,i+1,1)))*4096+b256(Asc(Mid$(stxt,i+2,1)))*64+_
	b256(Asc(Mid$(stxt,i+3,1)))
	RQBASE64E = RQBASE64E + Chr$(l \ 65536) & Chr$((l \ 256) Mod 256) & Chr$(l Mod 256)
Next i

Select Case lastChars
Case 2
	l = b256(Asc(Mid$(stxt, lenStr - 1, 1))) * 1024 + b256(Asc(Mid$(stxt, lenStr, 1))) * 16
	RQBASE64E = RQBASE64E & Chr$(l \ 256)
Case 3
	l = (b256(Asc(Mid$(stxt, lenStr - 2, 1))) * 4096 + b256(Asc(Mid$(stxt, lenStr - 1, 1))) * 64 +_
	b256(Asc(Mid$(stxt, lenStr, 1)))) \ 4
	RQBASE64E = RQBASE64E & Chr$(l \ 256) & Chr$(l Mod 256)
End Select
result=RQBASE64E

End Function 


'*****************************************

'*****************************************
Function DecodeSubj( Subject As String) As String 
'print  "----------- DecodeSubj Subject=";Subject

Dim i As Integer 
Dim l As Integer 
Dim v As string
dim begpos as long ' 1st position of =?
dim begpos2 as long ' 2nd position of =?
dim endpos as long ' 1st position of ?=
dim endpos2 as long ' 2nd position of ?=
Dim decodedSubj$ As string


begpos=0
endpos=0

headerTxtConv$=""
result=""
encodedword$=""
pretext$=""
decodedSubj$=""

' åñëè çàãîëîâîê êîäèðîâàííûé - òî óäàëÿåì ïðîáåëû
if instr(Subject,"=?")>0 then 
	Subject=replacesubstr$(Subject,ht,"")
	Subject=replacesubstr$(Subject,crlf+" ","")
	Subject=replacesubstr$(Subject,";"+crlf,"; ")
	Subject=replacesubstr$(Subject,"?=        ","?=")
	Subject=replacesubstr$(Subject,"?=       ","?=")
	Subject=replacesubstr$(Subject,"?=      ","?=")
	Subject=replacesubstr$(Subject,"?=     ","?=")
	Subject=replacesubstr$(Subject,"?=    ","?=")
	Subject=replacesubstr$(Subject,"?=   ","?=")
	Subject=replacesubstr$(Subject,"?=  ","?=")
	Subject=replacesubstr$(Subject,"?= ","?=")
	'Subject=Subject-" "
else
	if isKOI8(Subject)>0 then ' ïðîâåðêà íà koi8
		Subject=RQConvertCodePage(Subject, cp_Koi, cp_Win)
	end if
	result=Subject
	exit function
end if

'!!!  encoded-word = "=?" charset "?" encoding "?" encoded-text "?="
'subj$="=?windows-1251?B?zvLi5bo9PDu?= =?windows-1251?B?4u7lIOjn7uHw4Obl7ejlKQ==?=
'        1            2 3           4   1            2 3                        4   
'Subj:" =?windows-1251?Q?=C8=ED=F4=EE=F0=EC=E0=F6=E8=FF_?==?windows-1251?Q?=EE=E1_?==?windows-1251?Q?=EE=EF=EB=E0=F2=E5_?==?windows-1251?Q?=F1=E5=F0=E2=E8=F1=E0_forexsignal?=.ru
'        1            2 3                               4  1            2 3       4  1   
begpos=instr(Subject,"=?")
textpos=1
lensubj=len(Subject)

while begpos>0 and begpos <lensubj
	
	spos1=instr(begpos+1,Subject,"?") ' 1 ïîçèöèÿ ? - íà÷àëî charset
	spos2=instr(spos1+1,Subject,"?") ' 2 ïîçèöèÿ ? - íà÷àëî ìåòîäà êîäèðîâàíèÿ encoding
	if spos2=0 then spos2=len(Subject)
	spos3=instr(spos2+1,Subject,"?") ' 3 ïîçèöèÿ ? - íà÷àëî encoded-text
	if spos3=0 then spos3=len(Subject)
	spos4=instr(spos3+1,Subject,"?=") ' 4 ïîçèöèÿ ? - êîíåö encoded-text
	if spos4=0 then spos4=len(Subject)
	
	pretext$=mid$(Subject,textpos,begpos-textpos)
	codepage$=lcase$(mid$(Subject,spos1+1,spos2-spos1-1))
	codeMode$=lcase$(mid$(Subject,spos2+1,1))
	
	begpos=instr(spos4,Subject,"=?") ' ñëåäóþùåå encodedword$
	if begpos=0 then begpos=len(Subject)
	
	textpos=spos4+2 'instr(spos4,Subject,"=?")
	
	encodedword$=mid$(Subject,spos3+1,spos4-spos3-1) ' äåêîäèðóåìàÿ ÷àñòü
	encodedword$=replacesubstr$(encodedword$,"_","=20") ' replace white spaces
	headerTxtConv$=""
	headerTxtConv$=field$(encodedword$,"=",1) '""
	if codeMode$="q" then ' quoted printable part
		HexCharCount=tally(encodedword$,"=")
		for ii=1 to HexCharCount
			HexChar2$=ucase$(field$(encodedword$,"=",ii+1))
			HexChar$=left$(HexChar2$,2)
			Ost1$=right$(HexChar2$,len(HexChar2$)-2)
			headerTxtConv$=headerTxtConv$+chr$(val(CONVBASE$(HexChar$, 16, 10)))+Ost1$
		next ii
		
	elseif codeMode$="b" then ' base64 part
		encodedword$=encodedword$-" "
		headerTxtConv$=RQBASE64Decode(encodedword$)
	else
		
	end if
	'----------
	Select case codepage$
		
	case "windows-1251"
		
	case "koi8-r"
		' print " 511 headerTxtConv$=";headerTxtConv$
		headerTxtConv$=RQConvertCodePage(headerTxtConv$, cp_Koi, cp_Win)
			if isKOI8(headerTxtConv$)>0 then
				headerTxtConv$=RQConvertCodePage(headerTxtConv$, cp_Koi, cp_Win)
			end if
		'cprint" 468 headerTxtConv$="+headerTxtConv$
		
	case "utf-8"
		headerTxtConv$=RQConvertCodePage(headerTxtConv$, cp_UTF8, cp_Win)
			if isKOI8(headerTxtConv$)>0 then
				headerTxtConv$=RQConvertCodePage(headerTxtConv$, cp_Koi, cp_Win)
			end if
		
	case "utf-7"
		headerTxtConv$=RQConvertCodePage(headerTxtConv$, cp_UTF7, cp_Win)
			if isKOI8(headerTxtConv$)>0 then
				headerTxtConv$=RQConvertCodePage(headerTxtConv$, cp_Koi, cp_Win)
			end if
		
	case else
		
	end select
	if pretext$-" "="" then pretext$=""
	decodedSubj$=decodedSubj$+pretext$+headerTxtConv$
	'print"460 decodedSubj$=";decodedSubj$
	
	
wend

begpos=len(Subject)
pretext$=mid$(Subject,textpos,begpos-textpos+1)
decodedSubj$=decodedSubj$+pretext$

if isKOI8(decodedSubj$)>0 then
	decodedSubj$=RQConvertCodePage(decodedSubj$, cp_Koi, cp_Win)
end if


result=decodedSubj$

End Function 

'*****************************************
Function IsEmail(wabMail As String) As long 
Dim I As Integer 
Dim Char As String 
Dim Cdot(1) As String 

zzq=Like(wabMail, "*@*.*")

If zzq=0 Then 
	IsEmail = False 
	goto exitfunc
End If

'--- split ---
DotCount=tally(wabMail, ".")
'diakin@narod.ru - 2 ÷àñòè 
redim Cdot(DotCount) As String '0,1

for i=0 to DotCount
	cdot(i)=field$(wabMail, ".",i+1)
next i
'--- end split ---
lendomen=Len(Cdot(UBound(Cdot)))

If lendomen<> 3 And lendomen<> 2 Then 
	IsEmail = False 
	Exit Function 
End If 

For I = 1 To lendomen Step 1 
	Char = Mid$(Cdot(UBound(Cdot)), I, 1) 
	If (LCase$(Char) > Chr$(122)) Or  (LCase$(Char) < Chr$(97)) Then 
		IsEmail = False 
		Exit Function 
	End If 
Next I 

brem 1
======
For I = 1 To Len(wabMail) Step 1 
	Char = Mid$(wabMail, I, 1) 
	If (LCase$(Char) <= Chr$(122) And LCase$(Char) >= Chr$(97)) _ 
	Or (Char >= Chr$(48) And Char <= Chr$(57)) _ 
	Or (Char = ".") _ 
	Or (Char = "@") _ 
	Or (Char = "-") _ 
	Or (Char = "_") Then 
	IsEmail = True 
Else 
	IsEmail = False 
	Exit Function 
End If

Next I 
===
erem

IsEmail = True
exitfunc:
End Function 

'*****************************************
Sub ExtractEMailFromWab(wabFile As String, EmailList as QStringlist)
Dim WABDog As Long, WABLeft As Long, WABRight As Long 
Dim WABTemp As String 
dim ie5 as long
dim SObCount as long
Dim WABEmail(1) As String 
dim WABData as string


WABData=LoadString(wabFile)
SObCount=tally(WABData,"@")
'print"SObCount=";SObCount
Pos1 = 1
wabPos=1

for ie5=0 to SObCount-1
	' íàõîäèì ñîáàêó @
	WABDog = InStr(wabPos, WABData, Chr$(0) & Chr$(64) & Chr$(0)) 
	' îò ñîáàêè íàõîäèì äâà Chr(0) ñïðàâà è ñëåâà
	WABLeft = RInStr(WABDog,WABData, Chr$(0) & Chr$(0))
	WABRight = InStr(WABDog, WABData, Chr$(0) & Chr$(0)) 
	
	'âûðåçàåì e-mail àäðåñ
	WABTemp = Mid$(WABData, WABLeft, WABRight - WABLeft)
	WABTemp = replaceSubStr$(WABTemp , Chr(0), "") 
	
	for i95=1 to 31 ' åñëè ñîäåðæàòñÿ íåïå÷àòíûå ñèìâîëû
		if instr(WABTemp, chr$(i95))>0 then
			'print"i95=";i95
			exit for
		end if
	next i95
	'if i95<31 then goto NextEml1
	
	if i95>31 then 'goto NextEml1
		
		
		WABTemp = WABTemp -chr$(0)
		wzz$=WABTemp
		
		zzz=IsEmail(wzz$)
		zz1= False
		
		If ( zzz= True) And ( zz1= False) Then 
			'Call WABAddEmail(WABTemp) 
			
			if instr(EmailList.text,wzz$)=0 then
				erow=UBound(WABEmail)
				ReDim WABEmail(erow + 1) As String 
				WABEmail(erow) = wzz$ 
				EmailList.additems wzz$
				infomsg$=EmailList.item(erow-1)
'call  AddClrString ("585:infomsg$="+(infomsg$), clred, LogEdit)
				doevents
			end if
			
		End If 
	End If 
	
	NextEml1: 
	wabPos = WABRight 
next ie5

End Sub 
