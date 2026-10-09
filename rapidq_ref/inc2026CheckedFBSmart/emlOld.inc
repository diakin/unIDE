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
Msg=replacesubstr$(Msg,crlf+" "," ")
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
Msg=replacesubstr$(Msg,crlf+" "," ")
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
Function GetMsgBodyCodeMethod( MsgBody As String) As String
'Content-Transfer-Encoding: 8bit
dim i as long
Msg=replacesubstr$(Msg,ht," ")
Msg=replacesubstr$(Msg,crlf+" "," ")
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
Header=replacesubstr$(Header,crlf+" "," ")
Header=replacesubstr$(Header,";"+crlf,"; ")

'print"Header=";Header
' returm requared field value from message header
dim i as long
fieldidx=-1
dim HeaderList as QStringList
HeaderList.text=(Header)

if instr(Field,":")=0 then Field=Field+":"

field=lcase$(Field)'+":"

for i2=0 to HeaderList.Itemcount-1
	hitem$=lcase$(HeaderList.Item(i2))
	lenitem=len(hitem$)
	instrsep=instr(hitem$,":")
	if  instr(hitem$,field) >0 then
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
Source=replacesubstr$(Source,crlf+" "," ")
Source=replacesubstr$(Source,";"+crlf,"; ")

MSGHeader.text=""

MSG.text=Source
'print "------------- 136 GetMSGHeader Source=";Source
emptylineIDX=-1

emptylineIDX=MSG.IndexOf("")
'print " ------------- 139 GetMSGHeader  emptylineIDX=";emptylineIDX
if emptylineIDX=-1 then
	result=chg$(149)+"Err"+chg$(149)
	
else
	
for i=0 to emptylineIDX-1
	MSGHeader.additems (MSG.item(i))
	next i
	
	result=MSGHeader.text
end if

end function

'*****************************************
Function GetMSGBody( Source As String) As String 
dim MSGBody as qstringlist 'string
dim MSG as qstringlist

Source=replacesubstr$(Source,ht," ")
Source=replacesubstr$(Source,crlf+" "," ") ' основной 
Source=replacesubstr$(Source,";"+crlf,"; ")

MSGBody.text=""

MSG.text=Source
emptylineIDX=-1

emptylineIDX=MSG.IndexOf("")

if emptylineIDX=-1 then
	result=chg$(149)+"Err"+chg$(149)
	
else
	
	for i=emptylineIDX to MSG.itemcount-1
		MSGBody.additems (MSG.item(i))
	next i
	
	result=MSGBody.text
end if

end function


'*****************************************
Function isKOI8( Red$ As String) As long
' проверяет кодировку строки на koi8
result=0
if instr(Red$, "ДЩ")>0 then result=1 '"koi8-r"
if instr(Red$, "ЧЩ")>0 then result=1 '"koi8-r"
if instr(Red$, "ФШ")>0 then result=1 '"koi8-r"
if instr(Red$, "ДЩ")>0 then result=1 '"koi8-r"

if instr(Red$, "ВЙ")>0 then result=1 '"koi8-r"
if instr(Red$, "ДЙ")>0 then result=1
if instr(Red$, "ЗЙ")>0 then result=1
if instr(Red$, "ЛЙ")>0 then result=1
if instr(Red$, "МЙ")>0 then result=1
if instr(Red$, "НЙ")>0 then result=1
if instr(Red$, "РЙ")>0 then result=1
if instr(Red$, "ТЙ")>0 then result=1
if instr(Red$, "ФЙ")>0 then result=1
if instr(Red$, "ЦЙ")>0 then result=1

if instr(Red$, " Й")>0 then result=1
if instr(Red$, " й ")>0 then result=1

if instr(Red$, "ЪЙ")>0 then result=1
if instr(Red$, "ЙЫ")>0 then result=1

if instr(Red$, "ЙЪ")>0 then result=1
if instr(Red$, "йЪ")>0 then result=1

if instr(Red$, "бй")>0 then result=1
if instr(Red$, "дй")>0 then result=1
if instr(Red$, "йй")>0 then result=1

if instr(Red$, "pЙ")>0 then result=1

if instr(Red$, "Kй")>0 then result=1

if instr(Red$, "ШЫ")>0 then result=1
if instr(Red$, "ЕЫ")>0 then result=1

if instr(Red$, "ъД")>0 then result=1

if instr(Red$, "ЪБ")>0 then result=1
if instr(Red$, "ЪХ")>0 then result=1

if instr(Red$, "ъБ")>0 then result=1
if instr(Red$, "ЪЩ")>0 then result=1
if instr(Red$, "ЪП")>0 then result=1

if instr(Red$, "ЪТ")>0 then result=1

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
Function DecodeSubjOld( MSubject As String) As String 

Dim i As Integer 
Dim l As Integer 
Dim v As string
dim begpos as long ' 1st position of =?
dim begpos2 as long ' 2nd position of =?
dim endpos as long ' 1st position of ?=
dim endpos2 as long ' 2nd position of ?=
Dim decodedSubj$ As string

MSubject=replacesubstr$(MSubject,ht," ")
MSubject=replacesubstr$(MSubject,crlf+" "," ")
MSubject=replacesubstr$(MSubject,";"+crlf,"; ")

begpos=0
endpos=0
headerTxtConv$=""
result=""

if instr(MSubject,"=?")>0 then
	begcount=tally(MSubject,"=?") ' число декодируемых частей
	begpos=instr(MSubject,"=?")
	headerTxtConv$=mid$(MSubject,1,begpos-1)
	
	for j=1 to begcount ' "=?"
		' get encoded-words
		'headerTxtConv$=""
		spos1=instr(begpos+1,MSubject,"?") ' 1 позиция ? - начало charset
		spos2=instr(spos1+1,MSubject,"?") ' 2 позиция ? - начало метода кодирования encoding
		spos3=instr(spos2+1,MSubject,"?") ' 3 позиция ? - начало encoded-text
		spos4=instr(spos3+2,MSubject,"?=") ' 4 позиция ? - конец encoded-text
		' некодированная часть
		' начало spos4+2
		begpos2=instr(spos4+1,MSubject,"=?") ' next =?
		if begpos2=0 then begpos2=len(MSubject)+1
		posttext$=mid$(MSubject,spos4+2,begpos2-(spos4+2))
		
		' конец  begpos2-1
		encodedword$=mid$(MSubject,begpos,spos4-begpos) ' декодируемая часть
		
		' decode encoded-words
		codepage$=lcase$(field$(encodedword$,"?",2)) ' windows-1251
		
		codeMode$=lcase$(field$(encodedword$,"?",3)) ' Q 
		
		headerTxt$=field$(encodedword$,"?",4) '
		headerTxt$=replacesubstr$(headerTxt$,"_","=20") ' replace white spaces
		
		if codeMode$="q" then ' quoted printable part
			HexCharCount=tally(headerTxt$,"=")
			for ii=1 to HexCharCount
				HexChar2$=field$(headerTxt$,"=",ii+1)
				HexChar$=left$(HexChar2$,2)
				Ost1$=right$(HexChar2$,len(HexChar2$)-2)
				headerTxtConv$=headerTxtConv$+chr$(val(CONVBASE$(HexChar$, 16, 10)))+Ost1$
			next ii
			headerTxtConv$=headerTxtConv$+posttext$
			decodedSubj$=headerTxtConv$
			
		elseif codeMode$="b" then ' base64 part
			
			'print"====== 231 decodedSubj$=";decodedSubj$
			headerTxtConv$=headerTxtConv$+RQBASE64Decode(headerTxt$)+posttext$
			'print"====== 231 decodedSubj$=";decodedSubj$
		else
			
		end if
		begpos=begpos2
	next j
else
	decodedSubj$  =MSubject 'decodedSubj$ 
end if

' приводим кодировку к Windows
'Function RQConvertCodePage(SourseString As String, inPage As long, outPage As long) As String
'$define cp_Win  1251
'$define cp_Dos  866
'$define cp_Koi  20866 
'$define cp_Iso  28595
'$define cp_UTF8 65001 
'$define cp_UTF7 65000 

'print " ----- 248 decodedSubj$=";decodedSubj$
'print " ----- 249 codepage$=";codepage$
decodedSubj$=headerTxtConv$

Select case codepage$
	
case "windows-1251"
	
case "koi8-r"
	decodedSubj$=RQConvertCodePage1(decodedSubj$, cp_Koi, cp_Win)
case "utf-8"
	decodedSubj$=RQConvertCodePage1(decodedSubj$, cp_UTF8, cp_Win)
case "utf-7"
	decodedSubj$=RQConvertCodePage1(decodedSubj$, cp_UTF7, cp_Win)
case else
	if isKOI8(decodedSubj$)=1 then
	else
	end if
end select

result=decodedSubj$

End Function 


'*****************************************
Function DecodeSubjOld1( Subject As String) As String 

Dim i As Integer 
Dim l As Integer 
Dim v As string
dim begpos as long ' 1st position of =?
dim begpos2 as long ' 2nd position of =?
dim endpos as long ' 1st position of ?=
dim endpos2 as long ' 2nd position of ?=
Dim decodedSubj$ As string

Subject=replacesubstr$(Subject,ht," ")
Subject=replacesubstr$(Subject,crlf+" "," ")
Subject=replacesubstr$(Subject,";"+crlf,"; ")

begpos=0
endpos=0

headerTxtConv$=""
result=""
encodedword$=""
pretext$=""
codepage$=""
decodedSubj$=""

'!!!  encoded-word = "=?" charset "?" encoding "?" encoded-text "?="
'subj$="=?windows-1251?B?zvLi5bo9PDu?= =?windows-1251?B?4u7lIOjn7uHw4Obl7ejlKQ==?=
'        1            2 3           4   1            2 3                        4   
'Subj:" =?windows-1251?Q?=C8=ED=F4=EE=F0=EC=E0=F6=E8=FF_?==?windows-1251?Q?=EE=E1_?==?windows-1251?Q?=EE=EF=EB=E0=F2=E5_?==?windows-1251?Q?=F1=E5=F0=E2=E8=F1=E0_forexsignal?=.ru
'        1            2 3                               4  1            2 3       4  1   
'[!! SPAM] =?koi8-r?B?7PX+++nqIPDv5OHy7+sg6yDw8uH65O7p6/U=?=

begpos=instr(Subject,"=?")
textpos=1

if begpos>0 then  Subject=Subject-" "
begpos=instr(Subject,"=?") ' повторно после удаления побелов

while begpos>0 and begpos<len(Subject)
	
	spos1=instr(begpos+1,Subject,"?") ' 1 позиция ? - начало charset
	spos2=instr(spos1+1,Subject,"?") ' 2 позиция ? - начало метода кодирования encoding
	spos3=instr(spos2+1,Subject,"?") ' 3 позиция ? - начало encoded-text
	'spos4=instr(spos3+2,Subject,"?=") ' 4 позиция ? - конец encoded-text
	spos4=instr(spos3+1,Subject,"?=") ' 4 позиция ? - конец encoded-text
	
	pretext$=mid$(Subject,textpos,begpos-textpos)
	codepage$=lcase$(mid$(Subject,spos1+1,spos2-spos1-1))
	codeMode$=lcase$(mid$(Subject,spos2+1,1))
	
	begpos=instr(spos4,Subject,"=?") ' следующее encodedword$
	
	if begpos=0 then begpos=len(Subject) ' !!! 
	
	textpos=spos4+2 'instr(spos4,Subject,"=?")
	
	encodedword$=mid$(Subject,spos3+1,spos4-spos3-1) ' декодируемая часть
	
	encodedword$=replacesubstr$(encodedword$,"_","=20") ' replace white spaces
	headerTxtConv$=""
	headerTxtConv$=field$(encodedword$,"=",1) '""
	if codeMode$="q" then ' quoted printable part
		HexCharCount=tally(encodedword$,"=")
		for ii=1 to HexCharCount
			HexChar2$=field$(encodedword$,"=",ii+1)
			HexChar$=left$(HexChar2$,2)
			Ost1$=right$(HexChar2$,len(HexChar2$)-2)
			headerTxtConv$=headerTxtConv$+chr$(val(CONVBASE$(HexChar$, 16, 10)))+Ost1$
		next ii
		
	elseif codeMode$="b" then ' base64 part
		
		headerTxtConv$=RQBASE64Decode(encodedword$)
	else
		
	end if
	'----------
	Select case codepage$
	case "windows-1251"
		
	case "koi8-r"
		headerTxtConv$=RQConvertCodePage(headerTxtConv$, cp_Koi, cp_Win)
		
	case "utf-8"
		headerTxtConv$=RQConvertCodePage(headerTxtConv$, cp_UTF8, cp_Win)
		
	case "utf-7"
		headerTxtConv$=RQConvertCodePage(headerTxtConv$, cp_UTF7, cp_Win)
		
	case else
		
	end select
	
	decodedSubj$=decodedSubj$+pretext$+headerTxtConv$
	
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
Function DecodeSubj1( Subject As String) As String 

Dim i As Integer 
Dim l As Integer 
Dim v As string
dim begpos as long ' 1st position of =?
dim begpos2 as long ' 2nd position of =?
dim endpos as long ' 1st position of ?=
dim endpos2 as long ' 2nd position of ?=
Dim decodedSubj$ As string

Subject=replacesubstr$(Subject,ht," ")
Subject=replacesubstr$(Subject,crlf+" "," ")
Subject=replacesubstr$(Subject,";"+crlf,"; ")

begpos=0
endpos=0

headerTxtConv$=""
result=""
encodedword$=""
pretext$=""
codepage$=""
decodedSubj$=""

'!!!  encoded-word = "=?" charset "?" encoding "?" encoded-text "?="
'subj$="=?windows-1251?B?zvLi5bo9PDu?= =?windows-1251?B?4u7lIOjn7uHw4Obl7ejlKQ==?=
'        1            2 3           4   1            2 3                        4   
'Subj:" =?windows-1251?Q?=C8=ED=F4=EE=F0=EC=E0=F6=E8=FF_?==?windows-1251?Q?=EE=E1_?==?windows-1251?Q?=EE=EF=EB=E0=F2=E5_?==?windows-1251?Q?=F1=E5=F0=E2=E8=F1=E0_forexsignal?=.ru
'        1            2 3                               4  1            2 3       4  1   
'[!! SPAM] =?koi8-r?B?7PX+++nqIPDv5OHy7+sg6yDw8uH65O7p6/U=?=

begpos=instr(Subject,"=?")
textpos=1

if begpos>0 then  Subject=Subject-" "
begpos=instr(Subject,"=?") ' повторно после удаления побелов

while begpos>0 and begpos<len(Subject)
	
	spos1=instr(begpos+1,Subject,"?") ' 1 позиция ? - начало charset
	spos2=instr(spos1+1,Subject,"?") ' 2 позиция ? - начало метода кодирования encoding
	spos3=instr(spos2+1,Subject,"?") ' 3 позиция ? - начало encoded-text
	spos4=instr(spos3+2,Subject,"?=") ' 4 позиция ? - конец encoded-text
	
	pretext$=mid$(Subject,textpos,begpos-textpos)
	codepage$=lcase$(mid$(Subject,spos1+1,spos2-spos1-1))
	codeMode$=lcase$(mid$(Subject,spos2+1,1))
	
	begpos=instr(spos4,Subject,"=?") ' следующее encodedword$
	
	'if begpos=0 then begpos=len(Subject) ' !!! 
	
	textpos=spos4+2 'instr(spos4,Subject,"=?")
	
	encodedword$=mid$(Subject,spos3+1,spos4-spos3-1) ' декодируемая часть
	
	encodedword$=replacesubstr$(encodedword$,"_","=20") ' replace white spaces
	headerTxtConv$=""
	headerTxtConv$=field$(encodedword$,"=",1) '""
	if codeMode$="q" then ' quoted printable part
		HexCharCount=tally(encodedword$,"=")
		for ii=1 to HexCharCount
			HexChar2$=field$(encodedword$,"=",ii+1)
			HexChar$=left$(HexChar2$,2)
			Ost1$=right$(HexChar2$,len(HexChar2$)-2)
			headerTxtConv$=headerTxtConv$+chr$(val(CONVBASE$(HexChar$, 16, 10)))+Ost1$
		next ii
		
	elseif codeMode$="b" then ' base64 part
		
		headerTxtConv$=RQBASE64Decode(encodedword$)
	else
		
	end if
	'----------
	Select case codepage$
	case "windows-1251"
		
	case "koi8-r"
		headerTxtConv$=RQConvertCodePage1(varptr(headerTxtConv$), cp_Koi, cp_Win)
		
	case "utf-8"
		headerTxtConv$=RQConvertCodePage1(varptr(headerTxtConv$), cp_UTF8, cp_Win)
		
	case "utf-7"
		headerTxtConv$=RQConvertCodePage1(varptr(headerTxtConv$), cp_UTF7, cp_Win)
		
	case else
		
	end select
	
	decodedSubj$=decodedSubj$+pretext$+headerTxtConv$
	
wend

begpos=len(Subject)
pretext$=mid$(Subject,textpos,begpos-textpos+1)

decodedSubj$=decodedSubj$+pretext$

if isKOI8(decodedSubj$)>0 then
	decodedSubj$=RQConvertCodePage1(varptr(decodedSubj$), cp_Koi, cp_Win)
end if

result=decodedSubj$

End Function 

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

' если заголовок кодированный - то удаляем пробелы
if instr(Subject,"=?")>0 then 
	Subject=replacesubstr$(Subject,ht," ")
	Subject=replacesubstr$(Subject,crlf+" "," ")
	Subject=replacesubstr$(Subject,";"+crlf,"; ")
	'Subject=Subject-" "
else
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
	
	spos1=instr(begpos+1,Subject,"?") ' 1 позиция ? - начало charset
	spos2=instr(spos1+1,Subject,"?") ' 2 позиция ? - начало метода кодирования encoding
	spos3=instr(spos2+1,Subject,"?") ' 3 позиция ? - начало encoded-text
	'spos4=instr(spos3+2,Subject,"?=") ' 4 позиция ? - конец encoded-text
	spos4=instr(spos3+1,Subject,"?=") ' 4 позиция ? - конец encoded-text
	
	pretext$=mid$(Subject,textpos,begpos-textpos)
	codepage$=lcase$(mid$(Subject,spos1+1,spos2-spos1-1))
	codeMode$=lcase$(mid$(Subject,spos2+1,1))
	
	begpos=instr(spos4,Subject,"=?") ' следующее encodedword$
	
	if begpos=0 then begpos=len(Subject)
	
	textpos=spos4+2 'instr(spos4,Subject,"=?")
	
	encodedword$=mid$(Subject,spos3+1,spos4-spos3-1) ' декодируемая часть
	
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
		'cprint" 468 headerTxtConv$="+headerTxtConv$
		
	case "utf-8"
		headerTxtConv$=RQConvertCodePage(headerTxtConv$, cp_UTF8, cp_Win)
		
	case "utf-7"
		headerTxtConv$=RQConvertCodePage(headerTxtConv$, cp_UTF7, cp_Win)
		
	case else
		
	end select
	
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
