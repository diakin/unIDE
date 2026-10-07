' version 09-06-2022 !!!!!

'$include "C:\BAS\RAPIDQ\RQIDE\testinc.inc"
$define cp_Win  1251
$define cp_Dos  866
$define cp_Koi  20866 
$define cp_Iso  28595
$define cp_UTF8 65001 
$define cp_UTF7 65000 

$define cp_CentralEuropean_DOS 852
$define cp_CentralEuropean_Windows 1250
$define cp_CentralEuropean_ISO 28592
$define cp_Cyrillic_DOS 866
$define cp_Cyrillic_Windows 1251
$define cp_Cyrillic_ISO 28595
$define cp_Cyrillic_KOI8-R 20866
$define cp_Ukrainian_KOI8-RU 21866
$define cp_Latin3_ISO 28593
$define cp_Western 1252
$define cp_Baltic_Windows 1257
$define cp_Baltic_ISO 28594
$define cp_Greek_Windows 1253
$define cp_Greek_ISO 28597
$define cp_Turkish 1254
$define cp_Arabic_Windows 1256
$define cp_Arabic_ISO 28596
$define cp_Hebrew_DOS 862
$define cp_Hebrew_Windows 1255

$define CP_NIL    (-1)
$define CP_SYMBOL   42
$define CP_OEM_437   437
$define CP_THAI    874
$define CP_JAPAN   932
$define CP_CHINA   936
$define CP_KOREA   949
$define CP_TAIWAN   950
$define CP_EASTEUROPE  1250
$define CP_RUSSIAN   1251
$define CP_WESTEUROPE  1252
$define CP_GREEK   1253
$define CP_TURKISH   1254
$define CP_HEBREW   1255
$define CP_ARABIC   1256
$define CP_BALTIC   1257
$define CP_JOHAB   1361
$define CP_MAC_ROMAN  10000
$define CP_MAC_JAPAN  10001
$define CP_MAC_GREEK  10006
$define CP_MAC_CYRILLIC  10007
$define CP_MAC_LATIN2  10029
$define CP_MAC_TURKISH  10081
$define CP_UTF8    65001



'--------------------------- Custom functions --------------------------
'$IFNDEF CharToOem
Declare Function CharToOem Lib "user32" Alias "CharToOemA" _
(ByVal lpszSrc As String, ByVal lpszDst As String) as Long
'$ENDIF


'$IFNDEF OemToChar
Declare Function OemToChar Lib "user32" Alias "OemToCharA" _
(ByVal lpszSrc As String, ByVal lpszDst As String) As Long
'$ENDIF

Declare Function CharLower Lib "user32" Alias "CharLowerA" (ByVal lpsz As String) As String
Declare Function CharUpper Lib "user32" Alias "CharUpperA" (ByVal lpsz As String) As String


'*****************************************
Declare Function MultiByteToWideChar Lib "kernel32" alias "MultiByteToWideChar" _
( CodePage As Long,  dwFlags As Long, _
lpMultiByteStr As Long,  cchMultiByte As Long, _
lpWideCharStr As Long, _
cchWideChar As Long) As Long

Declare Function WideCharToMultiByte Lib "kernel32" alias "WideCharToMultiByte" _
( CodePage As Long,  dwFlags As Long, _
lpWideCharStr As Long,  cchWideChar As Long, lpMultiByteStr As Long, _
cchMultiByte As Long,  lpDefaultChar As long,  lpUsedDefaultChar As Long) As Long

'*****************************************
Declare Function MultiByteToWideChar1 Lib "kernel32" alias "MultiByteToWideChar" _
( CodePage As Long,  dwFlags As Long, _
lpMultiByteStr As long,  cchMultiByte As Long, _
lpWideCharStr As Long, _
cchWideChar As Long) As Long

Declare Function WideCharToMultiByte1 Lib "kernel32" alias "WideCharToMultiByte" _
( CodePage As Long,  dwFlags As Long, _
lpWideCharStr As long,  cchWideChar As Long, lpMultiByteStr As Long, _
cchMultiByte As Long,  lpDefaultChar As long,  lpUsedDefaultChar As Long) As Long



'-- ****************************************'
function LCaseApi(  SrcTxt as string ) as string
tmp$=SrcTxt+"-"
l=len(SrcTxt)
result=CharLower(left$(tmp$,l))
end function

'-- ****************************************'
function UCaseApi(  SrcTxt as string ) as string
tmp$=SrcTxt+"-"
l=len(SrcTxt)
result=CharUpper(left$(tmp$,l))
end function

'-- *****************************************'
FUNCTION vidnum$ (Num, dig%) as string
'Andrew Shelkovenko dec 2003
'A  function that returns the string representation of  of a rounded numeric expression.
'Syntax: vidnum$ (numeric-expression, dig%) 
'Num$ = vidnum$ (999999.2366666666, 4)
'Return  999999.2367 
'Num$ = vidnum$ (-0.236, 4)
'Return  -0.236
'Num$ =vidnum$ (-12389.236, -2)
'Return -12400
'Details:
'dig% - number of significant digits 

Num$=str$(Num)
pntPos=instr(Num$,".")
if pntPos=0 then 
	digMax=0
else
	digMax=Len(Num$)-pntPos
end if

if dig%>digMax then dig%=digMax 
vidnum$ = STR$((  CLNG(  abs(Num) * 10 ^ dig%) / 10 ^ dig%)*sgn(Num))
END FUNCTION
'
'-- **************************************************************************'
function   Hex2Dec (HexStr as string) as string

DEFdbl numb
defdbl number
DEFBYTE x,length, y
number = 0
length = LEN(HexStr)
FOR x = 1 TO length
	y = length - x
	
	digit$ = UCASE$(MID$(HexStr,x,1))
	SELECT CASE digit$
	CASE "A"
		numb = 10 * 16^y
	CASE "B"
		numb = 11 * 16^y
	CASE "C"
		numb = 12 * 16^y
	CASE "D"
		numb = 13 * 16^y
	CASE "E"
		numb = 14 * 16^y
	CASE "F"
		numb = 15 * 16^y
	CASE ELSE
		numb = VAL(LCASE$(digit$)) * 16^y
	END SELECT
	number = number + numb
	qw:
NEXT

if number>10^6 then 
	n1=fix(number/1000000) 
	n2=(number-n1*1000000)    
	NumNul=6-len(str$(n2)) 
	TrNul$=string$(NumNul, "0")
	
	Dec$ = STR$(n1)+TrNul$+str$(n2)
	
else
	Dec$ = STR$(number)
end if
Hex2Dec=Dec$

END function

'-- **************************************************************************'
function dectoHex (Dec as string) as string
defdbl ost, ch
defstr HexVal$
HexVal$=""
ost=0: ch=0
Dec#=val(Dec)
sign=sgn(Dec#)
Dec#=abs(Dec#)
WHILE  Dec# >= 16#
	ch=FIX(Dec# / 16#)
	ost = Dec#-ch*16#
	
	Dec#=ch
	select case ost
	case is <10
		Hexdig$=str$(ost)
	case 10
		Hexdig$="A"
	case 11
		Hexdig$="B"
	case 12
		Hexdig$="C"
	case 13
		Hexdig$="D"
	case 14
		Hexdig$="E"
	case 15
		Hexdig$="F"
	case 15
		Hexdig$="10"
		
	case else
	end select
	
	HexVal$ =Hexdig$  + HexVal$: 
	
wend

select case Dec#
	
case is <10
	Hexdig$=str$(Dec#)
case 10
	Hexdig$="A"
case 11
	Hexdig$="B"
case 12
	Hexdig$="C"
case 13
	Hexdig$="D"
case 14
	Hexdig$="E"
case 15
	Hexdig$="F"
case 15
	Hexdig$="10"
	
case else
end select

HexVal$ =Hexdig$  + HexVal$: 
if sign=-1 then signn$="-" else signn$=""
if HexVal$="0" then HexVal$="00"
dectoHex=signn$+ HexVal$
END function

'-- **************************************************************************'
function AddChrBefore(NumStr as string , Dlina as int, chr1 as string) as string
'Andrew Shelkovenko dec 2003
'A function that pre-padd string with chr to required Length 
'print AddChrBefore("-387.35" , 10, "=")  
'==-0387.35

diM kolvo as int
kolvo =Dlina-Len(NumStr)
'showmessage (NumStr)
if   kolvo<0 theN AddChrBefore="String too long"
if   kolvo=0 theN AddChrBefore=NumStr: exit function
AddChrBefore= STRING$(kolvo, chr1)+ NumStr
'call  AddClrString ("259:AddChrBefore="+str$(AddChrBefore), clred, LogEdit)
end function

'-- **************************************************************************'
function AddChrAfter(NumStr as string , Dlina as int, chr1 as string) as string
'Andrew Shelkovenko Mar 2008
'A function that pre-padd string with chr1 to required Length 
'print AddChrBefore("-387.35" , 10, "=")  
'==-0387.35

diM kolvo as int
kolvo =Dlina-Len(NumStr)
if   kolvo<0 theN AddChrBefore="String too long"
if   kolvo=0 theN AddChrBefore=NumStr: exit function
AddChrAfter=  NumStr+STRING$(kolvo, chr1)
end function


'-- **************************************************************************'
function Add0Before(NumStr as string , Dlina as int) as string
'Andrew Shelkovenko dec 2003
'A function that pre-padd string with 0's to required Length 
'print Add0Before("-387.35" , 8)  
'-0387.35


diM kolvo as int
kolvo =Dlina-Len(NumStr)
if   kolvo<0 theN Add0Before="String too long"
if   kolvo=0 theN Add0Before=NumStr: exit function

Add0Before = STRING$(kolvo, "0")+ NumStr

end function

'-- ***********************************
FUNCTION ByteReOrder (ByteStr$,ReOrder$ ) as string
'Andrew Shelkovenko dec 2003
' A function that reorder bytes in string.
'ByteStr$ - Sourse string
'ReOrder$ - new byte order

'ReOrder$="21342"
'old position - 2, new position - 1
'old position - 1, new position - 2
'old position - 3, new position - 3
'old position - 4, new position - 4
'old position - 2, new position - 5

~tmp$=""

LenB=Len(ByteStr$)
LenR=Len(ReOrder$)

for i=1 to LenB
	poz$=ReOrder$[i]
	if val(poz$)> LenB then ShowMessage( "ByteReOrder: ReOrder index outbound input string"):exit FUNCTION
	if i<= LenR then
		byt$=ByteStr$[val(poz$)]
	else
		byt$=ByteStr$[i]
	end if
	~tmp$=~tmp$+byt$
next

ByteReOrder=~tmp$

end FUNCTION

'-- **************************************************************************'
FUNCTION CByteNum (ByteStr$,Num_Type as short ) as variant
'print"CByteNum ByteStr$=";ByteStr$
'Andrew Shelkovenko dec 2003
'' converts   number of Num_Type type to bytes sequence.
'Num_Type can be next value:
'const Num_SHORT = 2
'const Num_WORD = 3
'const Num_LONG = 4
'const Num_DWORD = 5
'const Num_SINGLE = 6
'const Num_DOUBLE = 8


DIM M AS QMemoryStream
select case Num_Type
case Num_BYTE
	ShowMessage "CByteNum: Can't to write BYTE.Wrong parameter type - Num_BYTE": exit funCTION
case  Num_SHORT: M.Write (ByteStr$):m.Position=0:CByteNum=m.ReadNum(Num_SHORT)
case  Num_WORD:  M.Write (ByteStr$):m.Position=0:CByteNum=m.ReadNum(Num_WORD)
case  Num_LONG:  M.Write (ByteStr$):m.Position=0:CByteNum=m.ReadNum(Num_LONG)
case  Num_DWORD: M.Write (ByteStr$):m.Position=0:CByteNum=m.ReadNum(Num_DWORD)
case  Num_SINGLE:M.Write (ByteStr$):m.Position=0:CByteNum=m.ReadNum(Num_SINGLE)
case  Num_DOUBLE:M.Write (ByteStr$):m.Position=0:CByteNum=m.ReadNum(Num_DOUBLE)
	
case else
	M.Write (ByteStr$):m.Position=0:CByteNum=m.ReadNum(Num_DOUBLE)
end select

M.Close

end funCTION

'-- **************************************************************************'
FUNCTION CNumByte (Num, Num_Type as short) as string
'Andrew Shelkovenko dec 2003

'converts bytes sequence to  number of Num_Type type  
'Num_Type can be next value:
'const Num_SHORT = 2
'const Num_WORD = 3
'const Num_LONG = 4
'const Num_DWORD = 5
'const Num_SINGLE = 6
'const Num_DOUBLE = 8


DIM M AS QMemoryStream

select case Num_Type
case Num_BYTE
	dim N1 as BYTE 
	ShowMessage "CNumByte: Can't to write BYTE.Wrong parameter type - Num_BYTE": exit funCTION
	
case  Num_SHORT: DEFSHORT N2:N2=Num:M.Write(N2):M.Position=0:CNumByte=M.ReadBinStr(sizeOf(N2))
case  Num_WORD:  DEFWORD  N3:N3=Num:M.Write(N3):M.Position=0:CNumByte=M.ReadBinStr(sizeOf(N3))
case  Num_LONG:  DEFLNG   N4:N4=Num:M.Write(N4):M.Position=0:CNumByte=M.ReadBinStr(sizeOf(N4))
case  Num_DWORD: DEFDWORD N5:N5=Num:M.Write(N5):M.Position=0:CNumByte=M.ReadBinStr(sizeOf(N5))
case  Num_SINGLE:DEFSNG   N6:N6=Num:M.Write(N6):M.Position=0:CNumByte=M.ReadBinStr(sizeOf(N6))
case  Num_DOUBLE:DEFDBL   N7:N7=Num:M.Write(N7):M.Position=0:CNumByte=M.ReadBinStr(sizeOf(N7))
	
case else
	dim N8 as DOUBLE:N8=Num:
	M.Write(N8):
	M.Position=0:CNumByte=M.ReadBinStr(sizeOf(N8)):M.Close                                         
end select
M.Close
end funCTION

'-- **************************************************************************'

' LIKE Function - pattern matching routine for Rapid-Q by William Yu
' This emulates the VB LIKE operator.
' Thanks to Thomas Binder for the original C code
'
' ?   Any single character.
' *   Zero or more characters.
' #   Any single digit (0-9).
' [charlist]  Any single character in charlist.
' [!charlist] Any single character not in charlist.
'
' A group of one or more characters (charlist) enclosed in brackets ([ ])
' can be used to match any single character in string and can include almost
' any character code, including digits.
'
' Note:   To match the special characters left bracket ([), question
' mark (?), number sign (#), and asterisk (*), enclose them in brackets.
' The right bracket (]) can't be used within a group to match itself, but
' it can be used outside a group as an individual character.
'
' By using a hyphen (-) to separate the upper and lower bounds of the range,
' charlist can specify a range of characters. For example, [A-Z] results in
' a match if the corresponding character position in string contains any
' uppercase letters in the range A-Z. Multiple ranges are included within
' the brackets without delimiters.


DECLARE FUNCTION Like(ParseString AS STRING, Pattern AS STRING) AS INTEGER
DECLARE FUNCTION IsDigit(S AS STRING) AS INTEGER

const INVERT = "!"       '-- Some like ^ or ~ instead, whatever you want

'-- **************************************************************************'
FUNCTION IsDigit(S AS STRING) AS INTEGER
IF S >= "0" AND S <= "9" THEN
	IsDigit = 1
ELSE
	IsDigit = 0
END IF
END FUNCTION


'-- **************************************************************************'
FUNCTION IsDigitsOnly(S AS STRING) AS INTEGER

for i=1 to len(s)
	
	IF S[i] >= "0" AND S[i] <= "9" THEN
		IsDigitsOnly = 1
	ELSE
		IsDigitsOnly = 0
		exit for
	END IF
next

END FUNCTION


'-- **************************************************************************'
FUNCTION Like(ParseString AS STRING, Pattern AS STRING) AS INTEGER
DIM prev AS INTEGER, matched AS INTEGER, reverse AS INTEGER

WHILE Pattern <> ""
	SELECT CASE MID$(Pattern, 1, 1)
	CASE "?"
		IF ParseString = "" THEN
			Like = 0
			EXIT FUNCTION
		END IF
	CASE "#"
		IF IsDigit(MID$(ParseString, 1, 1)) = 0 THEN
			Like = 0
			EXIT FUNCTION
		END IF
	CASE "*"
		DO
		Pattern = MID$(Pattern, 2, LEN(Pattern)-1)
		LOOP UNTIL MID$(Pattern, 1, 1) <> "*"
		IF Pattern = "" THEN
			Like = 1
			EXIT FUNCTION
		END IF
		WHILE ParseString <> ""
			IF Like(ParseString, Pattern) THEN
				Like = 1
				EXIT FUNCTION
			END IF
			IF ParseString <> "" THEN
				ParseString = MID$(ParseString, 2, LEN(ParseString)-1)
			END IF
		WEND
		Like = 0
		EXIT FUNCTION
	CASE "["
		reverse = (MID$(Pattern, 2, 1) = INVERT)
		IF reverse THEN
			Pattern = MID$(Pattern, 2, LEN(Pattern)-1)
		END IF
		prev = 256: matched = 0
		DO
		Pattern = MID$(Pattern, 2, LEN(Pattern)-1)
		IF (Pattern <> "") AND (esc <> 0 OR MID$(Pattern, 1, 1) <> "]") THEN
			IF MID$(Pattern, 1, 1) = "-" THEN
				Pattern = MID$(Pattern, 2, LEN(Pattern)-1)
				IF Pattern = "" THEN
					Like = 0
					EXIT FUNCTION
				END IF
				matched = matched OR (MID$(ParseString, 1, 1) <= MID$(Pattern, 1, 1) AND ASC(MID$(ParseString, 1, 1)) >= prev)
			ELSE
				matched = matched OR (MID$(ParseString, 1, 1) = MID$(Pattern, 1, 1))
			END IF
			prev = ASC(MID$(Pattern, 1, 1))
		ELSE
			EXIT DO
		END IF
		esc = 0
		LOOP
		IF (prev = 256 OR MID$(Pattern, 1, 1) <> "]" OR ABS(matched) = ABS(reverse)) THEN
			Like = 0
			EXIT FUNCTION
		END IF
	CASE ELSE
		IF MID$(ParseString, 1, 1) <> MID$(Pattern, 1, 1) THEN
			Like = 0
			EXIT FUNCTION
		END IF
	END SELECT
	ParseString = MID$(ParseString, 2, LEN(ParseString)-1)
	Pattern = MID$(Pattern, 2, LEN(Pattern)-1)
WEND

Like = ABS(LEN(ParseString) = 0)
END FUNCTION

'-- Test code
'print "Like('24','##')=", Like("24","##")

'?"Like(aBBBa, a*a)=", Like("aBBBa","a*a")
'?Like("F","[!A-Z]")
'?Like("a2a","a#a")
'?Like("aM5b","a[A-GL-P]#[!c-e]")
'?Like("BAT123khg","B?T*")
'?Like("CAT123khg","B?T*")

'?Like("Combine(10, 20) = 30", "*(*?,*?)*=*#")
'-- **************************************************************************'
function SecTime (cTime$ as string) as integer 
TimeHH=val (field$(cTime$, ":",1)) 
TimeMM=val (field$(cTime$, ":",2)) 
TimeSS=val (field$(cTime$, ":",3)) 
result=TimeHH*3600+TimeMM*60+TimeSS 
end function


'-- **************************************************************************'
function DayDate (cDate$ as string) as integer 

MM=val (field$(cDate$, "-",1)) 
Day=val (field$(cDate$, "-",2)) 
Year=val (field$(cDate$, "-",3)) 

result=365*(Year)+30*(MM)+(Day) 
end function

'-- **************************************************************************'
function TimeString (TimSec as integer) as string

Hr%=TimSec/3600
SecMin=TimSec-Hr%*3600
Min%=(SecMin)/60
Sec%=SecMin-Min%*60

Hr$=Right$("0"+str$(Hr%), 2)
Min$=Right$("0"+str$(Min%), 2)
Sec$=Right$("0"+str$(Sec%), 2)

TimeString=Hr$+":"+Min$+":"+Sec$'+"   "

end function

'-- *********************************************************************'
Function GetWord (Oper$ as string, getV$ as string) as long
'Old! Use GetVarPos!!!

'return variable  position in checked string
'getV$ - variable name 
'Oper$ - checked string
'if getV$ commented,  or quoted (just text, not varname)  - return error code
result=-1 ' error
defstr Lsep$="()[]=><, :+-*\/;"
defstr Rsep$="()[]=><, :'+-*\/;"

Oper$=lcase$(Oper$)
getV$=lcase$(getV$)

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


'NumQT=tally(Oper$, qt)
'NumRem=tally(Oper$, "'")
'CharPos=instr(Oper$, getC$)


'*****************************************
'sub Ob2Grad (obor as single,   SecFull as integer, byref  SecMnt as integer,  byref  Grad as integer,  byref  Mint as integer,  byref Sec1 as integer, byref  Ugl$ as string)
sub Ob2Grad (obor as single,   SecFull as integer, SecMnt as integer,  Grad as integer,  Mint as integer,  Sec1 as integer,  byref Ugl$ as string)
'convert value of revolutions to degree of arc
'obor - value of revolutions (input)
'SecFull - Full secounds of arc in value of revolutions
'Grad - degrees of arc 
'Mint - minutes of arc
'Sec1 - Secounds of arc
'Ugl$ - string repres. of value of revolutions in {arc degrees, minutes, secounds} format
'SecMnt -secounds of arc in {arc degrees, secounds format} representation of the revolutions value(, i.e. Grad,SecMnt)

SecFull=obor*360*60*60
sign=sgn(obor)
obor=abs(obor)
Grad=fix(obor*360)'+val(Edit18.text)'

Mint=fix((obor*360-Grad)*60)

Sec1=round((((obor*360-Grad)*60)-Mint)*60)

if sec1=60 then 
	sec1=0
	inc mint
	if mint=60 then
		mint=0
		inc grad
	end if
end if

SecMnt=round((obor*360-Grad)*3600)

if sgn(SecFull)=-1 then zn$="-" else zn$=""

Ugl$=zn$+str$(abs(Grad))+chr$(176)+str$(abs(Mint))+"'"+str$(abs(Sec1))+qt

end sub

'*****************************************
sub Grad2Sec ( Ugl$ as string, byref obor as single,  byref SecFull as integer, byref  SecMnt as integer,_
byref  Grad as integer,  byref  Mint as integer,  byref  Sec1 as integer )

'convert value of revolutions to degree of arc
'obor - value of revolutions (input)
'SecFull - Full secounds of arc in value of revolutions
'Grad - degrees of arc 
'Mint - minutes of arc
'Sec1 - Secounds of arc
'Ugl$ - string repres. of value of revolutions in {arc degrees, minutes, secounds} format
'SecMnt -secounds of arc in {arc degrees, secounds format} representation of the revolutions value(, i.e. Grad,SecMnt)

if Ugl$[1]="-" then znak=-1 else znak=1

Ugl$=Ugl$-"-"

gradpos=instr(Ugl$,chr$(176))
GradU=val(left$(Ugl$,gradpos-1))
Grad=GradU*znak
'print"Grad=";Grad

mintpos=instr(Ugl$,chr$(39))
mintU=val(mid$(Ugl$,gradpos+1,mintpos- gradpos ))
mint=mintU*znak
'print"mint=";mint

secpos=instr(Ugl$,qt)
secU=val(mid$(Ugl$,mintpos+1,secpos -mintpos ))
sec1=secU*znak
'print"sec=";sec

SecFull=(GradU*3600+mintU*60+secU)*znak
'print"SecFull=";SecFull

obor=SecFull/3600/360
'print"obor=";obor

SecMnt=mint*60+sec1
'print"SecMnt=";SecMnt
end sub

'*****************************************
function Ugl2Sec (Ugl$ as string) as integer
if Ugl$[1]="-" then znak=-1 else znak=1

Ugl$=Ugl$-"-"

gradpos=instr(Ugl$,chr$(176))
GradU=val(left$(Ugl$,gradpos-1))

mintpos=instr(Ugl$,chr$(39))
mintU=val(mid$(Ugl$,gradpos+1,mintpos- gradpos ))

secpos=instr(Ugl$,qt)
secU=val(mid$(Ugl$,mintpos+1,secpos -mintpos ))

SecFull=(GradU*3600+mintU*60+secU)*znak
'print"SecFull=";SecFull

Ugl2Sec=SecFull

end function

'*****************************************
function Sec2Ugl (SecFull as long) as string

if sgn(SecFull)=-1 then zn$="-" else zn$=""
SecFull=abs(SecFull)
'print"SecFull=";SecFull

Grad=SecFull\3600 ' число целых градусов
'print"Grad=";Grad
gradSec=Grad*3600 ' число секунд в целых градусах
'print"gradSec=";gradSec

ostminSec=SecFull-gradSec ' число сек в дробной части градусов - минутах и сек
'print"ostminSec=";ostminSec

mint=ostminSec\60 ' целое число минут
'print"mint=";mint
mintsec=mint*60 ' число секунд в целых минутах
'print"mintsec=";mintsec
sec1 =ostminSec- mintsec ' остаток чистых секунд
'print"sec1=";sec1


Sec2Ugl=zn$+str$((Grad))+chr$(176)+str$((Mint))+"'"+str$((Sec1))+qt



end function

'*********************************************************************
function sadd(InpStr as string) as long
'Returns the memory offset of the string data in the string variable
' use as pointer to the string variable
DIM Mem AS QMemoryStream
Mem.Write InpStr
Mem.Position = 0
sadd=Mem.Pointer
end function

'*********************************************************************
function Cutleft(a as string, n as long)  as string
'return string without first n chars
result= mid$(a,n+1,len(a)-n+1)
end function

'*********************************************************************
function CutRight(a as string, n as long)  as string
'return string without first n chars
result= mid$(a,1,len(a)-n)
end function

'-- ************************************************************************'
function delTags (HTMLtext as string) as string 
string1$=HTMLtext

string1$=REPLACESUBSTR$(string1$,"       " , " "  )
string1$=REPLACESUBSTR$(string1$,"      " , " "  )
string1$=REPLACESUBSTR$(string1$,"     " , " "  )
string1$=REPLACESUBSTR$(string1$,"    " , " "  )
string1$=REPLACESUBSTR$(string1$,"   " , " "  )
string1$=REPLACESUBSTR$(string1$,"  " , " "  )


string1$=REPLACESUBSTR$(string1$,">"+crlf, ">"+"~~~" )
string1$=REPLACESUBSTR$(string1$,". ", "."+crlf )

string1$=REPLACESUBSTR$(string1$,"<br>", crlf )
STRING1$=REPLACESUBSTR$(STRING1$,"<BR>", crlf )

string1$=REPLACESUBSTR$(string1$,"</p>", crlf )
STRING1$=REPLACESUBSTR$(STRING1$,"</P>", crlf )

string1$=REPLACESUBSTR$(string1$,"</tr>", crlf )
STRING1$=REPLACESUBSTR$(STRING1$,"</TR>", crlf)

string1$=REPLACESUBSTR$(string1$,"</td>", " " )
STRING1$=REPLACESUBSTR$(STRING1$,"</TD>", " " )

string1$=REPLACESUBSTR$(string1$,"<td>", "" )

string1$=REPLACESUBSTR$(string1$,"</FONT>", "" )

string1$=REPLACESUBSTR$(string1$,"<P>", "" )

'z0=ftally (string1$, "<")
z0Old=z0

z1=instr(string1$, "<")
z2=instr(string1$, ">")

while z1>0 and z2>0 
	if z2>z1 then 
		string1$=delete$(string1$, z1, z2-z1+1) '+chr$(10) 
	else
		'<a class="small" target="_top" href="/default.asp">MSDN Home</a>&nbsp;>&nbsp;
		string1$=delete$(string1$, z2, 1)
	end if
	z1=instr( string1$, "<")
	z2=instr( string1$, ">")
	'dec z0
	inc z0
	
wend

string1$=REPLACESUBSTR$(string1$,"   " , " "  )
string1$=REPLACESUBSTR$(string1$,"  " , " "  )
string1$=REPLACESUBSTR$(string1$,chr$(9)+chr$(9)+chr$(9) , " "  )
string1$=REPLACESUBSTR$(string1$,chr$(9)+chr$(9) , " "  )
string1$=REPLACESUBSTR$(string1$,chr$(9), " "  )

string1$=REPLACESUBSTR$(string1$,"~~~",crlf )

string1$=REPLACESUBSTR$(string1$,"&quot;" , qt  )
string1$=REPLACESUBSTR$(string1$,"&gt;" , ">"  )
string1$=REPLACESUBSTR$(string1$,"&lt;" , "<"  )
string1$=REPLACESUBSTR$(string1$,"&nbsp;" , " "  )


string1$=REPLACESUBSTR$(string1$,crlf+crlf+crlf+crlf+crlf , crlf  )
string1$=REPLACESUBSTR$(string1$,crlf+crlf+crlf+crlf , crlf  )
string1$=REPLACESUBSTR$(string1$,crlf+crlf+crlf , crlf  )
string1$=REPLACESUBSTR$(string1$,crlf+crlf , crlf  )

string1$=REPLACESUBSTR$(string1$,cr+cr+cr+cr+cr , cr  )
string1$=REPLACESUBSTR$(string1$,cr+cr+cr+cr , cr  )
string1$=REPLACESUBSTR$(string1$,cr+cr+cr , cr  )
string1$=REPLACESUBSTR$(string1$,cr+cr , cr  )

string1$=REPLACESUBSTR$(string1$,lf+lf+lf+lf+lf , lf  )
string1$=REPLACESUBSTR$(string1$,lf+lf+lf+lf , lf  )
string1$=REPLACESUBSTR$(string1$,lf+lf+lf, lf  )
string1$=REPLACESUBSTR$(string1$,lf+lf, lf  )

result=string1$

end function

'*****************************************
Function RQConvertCodePage (SourseString As String, inPage As long, outPage As long) As String
'print "1159 RQConvertCodePage SourseString=";SourseString
'$define cp_Win  1251
'$define cp_Dos  866
'$define cp_Koi  20866 
'$define cp_Iso  28595
'$define cp_UTF8 65001 
'$define cp_UTF7 65000 


Dim LenSourseString As Long
LenSourseString = Len(SourseString)
'print "1170 RQConvertCodePage  LenSourseString=";LenSourseString

Dim str1 As String
Dim str2 As String
Dim RetStrLong As Long

dim tmp as string 
tmp=SourseString
ptrtmp&=varptr(tmp)

str1 = String$(LenSourseString * 4, chr$(0))
str2 = String$(LenSourseString * 4, chr$(0))

ptrstr1&=varptr(str1)
ptrstr2&=varptr(str2)

RetStrLong = MultiByteToWideChar(inPage, 0, tmp, LenSourseString, 0&, 0)
'print"RetStrLong=";RetStrLong
RetStrLong = MultiByteToWideChar(inPage, 0, tmp,LenSourseString , ptrstr1&, RetStrLong)
'print"RetStrLong=";RetStrLong
RetStrLong2 = WideCharToMultiByte(outPage, 0, ptrstr1&, RetStrLong, str2, LenSourseString * 2, ByVal 0&, 0) ' str2
'print"RetStrLong2=";RetStrLong2

RQConvertCodePage = Left$(str2, RetStrLong2)
End Function

'*****************************************
Function RQConvertCodePage1 (SourseStringPtr As long, inPage As long, outPage As long) As String
'print "1159 RQConvertCodePage SourseString=";SourseString
'$define cp_Win  1251
'$define cp_Dos  866
'$define cp_Koi  20866 
'$define cp_Iso  28595
'$define cp_UTF8 65001 
'$define cp_UTF7 65000 


Dim LenSourseString As Long
LenSourseString = Len(varptr$(SourseStringPtr))
'print "1170 RQConvertCodePage3  LenSourseString=";LenSourseString

Dim str1 As String
Dim str2 As String
Dim RetStrLong As Long

str1 = String$(LenSourseString * 4, chr$(0))'+String$(LenSourseString * 4, chr$(0))
str2 = String$(LenSourseString * 4, chr$(0))'+String$(LenSourseString * 4, chr$(0))

ptrstr1&=varptr(str1)
ptrstr2&=varptr(str2)

'RetStrLong = MultiByteToWideChar2(inPage, 0, SourseStringPtr, LenSourseString , 0&, 0)
RetStrLong = MultiByteToWideChar1(inPage, 0, SourseStringPtr, -1 , 0&, 0)
'print"RetStrLong0=";RetStrLong
RetStrLong = MultiByteToWideChar1(inPage, 0, SourseStringPtr,-1, ptrstr1&, RetStrLong)
'print"RetStrLong1=";RetStrLong
RetStrLong2 = WideCharToMultiByte1(outPage, 0, ptrstr1&, RetStrLong, str2, LenSourseString * 4, ByVal 0&, 0) ' str2
'print"RetStrLong2=";RetStrLong2

RQConvertCodePage1 = Left$(str2, RetStrLong2)
End Function

'*****************************************
Function ConvertCodePage2 (SourseString As String, inPage As long, outPage As long) As String

Dim LenSourseString As Long
LenSourseString = Len(SourseString)

Dim str1 As String
Dim str2 As String
Dim RetStrLong As Long

dim tmp as string 
tmp=SourseString
ptrtmp&=varptr(tmp)

str1 = String$(LenSourseString * 4, chr$(0))
str2 = String$(LenSourseString * 4, chr$(0))

ptrstr1&=varptr(str1)
ptrstr2&=varptr(str2)

RetStrLong = MultiByteToWideChar(inPage, 0, tmp, LenSourseString, 0&, 0)
RetStrLong = MultiByteToWideChar(inPage, 0, tmp, RetStrLong, ptrstr1&, LenSourseString)
'print"RetStrLong =";RetStrLong 
RetStrLong2 = WideCharToMultiByte(outPage, 0, ptrstr1&, RetStrLong, str2, LenSourseString * 4, ByVal 0&, 0) ' str2
'print"RetStrLong2 =";RetStrLong2 

ConvertCodePage = Left$(str2, RetStrLong2)
End Function


'*****************************************
FUNCTION RC4 (key AS STRING, str AS STRING) AS STRING
DIM stateTable(256) AS BYTE, randomIndex AS BYTE
DIM i AS LONG, j AS LONG, k AS LONG, n AS LONG

result = ""

n = LEN(key)
IF 0 < n THEN
	FOR i = 0 TO 255
		stateTable(i) = i
	NEXT
	
	j = 0
	FOR i = 0 TO 255
		k = (i MOD n) + 1
		j = (j + stateTable(i) + ASC(key[k])) AND 255
		SWAP stateTable(i), stateTable(j)
	NEXT
	
	j = 0
	n = LEN(str)
	FOR k = 1 TO n
		i = k AND 255
		j = (j + stateTable(i)) AND 255
		randomIndex = (stateTable(i) + stateTable(j)) AND 255
		SWAP stateTable(i), stateTable(j)
		
		result = result & CHR$(ASC(str[k]) XOR stateTable(randomIndex))
	NEXT
END IF
END FUNCTION



'-- ************************************************************************'
function BGR2HtmlColor (BGRColor as long) as string
'hexColor$=HEX$(BGRColor) 
hexColor$=MID$( HEX$(BGRColor),3,6) 
result="#"+MID$( hexColor$,5,2) +MID$( hexColor$,3,2) +MID$( hexColor$,1,2) 
end function

'-- ************************************************************************'
function HtmlColor2BGR (HtmlColor as string) as long
HtmlColor$=mid$(trim$(ucase$(HtmlColor)),2,6) 
HtmlColor$=MID$( HtmlColor$,5,2) +MID$( HtmlColor$,3,2) +MID$( HtmlColor$,1,2) 
HtmlColor$=CONVBASE$(HtmlColor$,16,10)
result=val(HtmlColor$)
end function


'*****************************************
FUNCTION STRL$ (value AS long) AS STRING
tmp$=STRF$(value, ffFixed, 11, 18)
if instr(tmp$,".")>0 then decSep$="."
if instr(tmp$,",")>0 then decSep$=","

STRL$ = field$(STRF$(value, ffFixed, 11, 18),decSep$,1)

END FUNCTION

brem 0
--- кодовые страницы -------
      037 IBM EBCDIC - U.S./Canada 
      437 OEM - United States 
      500 IBM EBCDIC - International 
      708 Arabic - ASMO 708 
      709 Arabic - ASMO 449+, BCON V4 
      710 Arabic - Transparent Arabic 
      720 Arabic - Transparent ASMO 
      737 OEM - Greek (formerly 437G) 
      775 OEM - Baltic 
      850 OEM - Multilingual Latin I 
      852 OEM - Latin II 
      855 OEM - Cyrillic (primarily Russian) 
      857 OEM - Turkish 
      858 OEM - Multlingual Latin I + Euro symbol 
      860 OEM - Portuguese 
      861 OEM - Icelandic 
      862 OEM - Hebrew 
      863 OEM - Canadian-French 
      864 OEM - Arabic 
      865 OEM - Nordic 
      866 OEM - Russian 
      869 OEM - Modern Greek 
      870 IBM EBCDIC - Multilingual/ROECE (Latin-2) 
      874 ANSI/OEM - Thai (same as 28605, ISO 8859-15) 
      875 IBM EBCDIC - Modern Greek 
      932 ANSI/OEM - Japanese, Shift-JIS 
      936 ANSI/OEM - Simplified Chinese (PRC, Singapore) 
      949 ANSI/OEM - Korean (Unified Hangeul Code) 
      950 ANSI/OEM - Traditional Chinese (Taiwan; Hong Kong SAR, PRC) 
      1026 IBM EBCDIC - Turkish (Latin-5) 
      1047 IBM EBCDIC - Latin 1/Open System 
      1140 IBM EBCDIC - U.S./Canada (037 + Euro symbol) 
      1141 IBM EBCDIC - Germany (20273 + Euro symbol) 
      1142 IBM EBCDIC - Denmark/Norway (20277 + Euro symbol) 
      1143 IBM EBCDIC - Finland/Sweden (20278 + Euro symbol) 
      1144 IBM EBCDIC - Italy (20280 + Euro symbol) 
      1145 IBM EBCDIC - Latin America/Spain (20284 + Euro symbol) 
      1146 IBM EBCDIC - United Kingdom (20285 + Euro symbol) 
      1147 IBM EBCDIC - France (20297 + Euro symbol) 
      1148 IBM EBCDIC - International (500 + Euro symbol) 
      1149 IBM EBCDIC - Icelandic (20871 + Euro symbol) 
      1200 Unicode UCS-2 Little-Endian (BMP of ISO 10646) 
      1201 Unicode UCS-2 Big-Endian 
      1250 ANSI - Central European 
      1251 ANSI - Cyrillic 
      1252 ANSI - Latin I 
      1253 ANSI - Greek 
      1254 ANSI - Turkish 
      1255 ANSI - Hebrew 
      1256 ANSI - Arabic 
      1257 ANSI - Baltic 
      1258 ANSI/OEM - Vietnamese 
      1361 Korean (Johab) 
      10000 MAC - Roman 
      10001 MAC - Japanese 
      10002 MAC - Traditional Chinese (Big5) 
      10003 MAC - Korean 
      10004 MAC - Arabic 
      10005 MAC - Hebrew 
      10006 MAC - Greek I 
      10007 MAC - Cyrillic 
      10008 MAC - Simplified Chinese (GB 2312) 
      10010 MAC - Romania 
      10017 MAC - Ukraine 
      10021 MAC - Thai 
      10029 MAC - Latin II 
      10079 MAC - Icelandic 
      10081 MAC - Turkish 
      10082 MAC - Croatia 
      12000 Unicode UCS-4 Little-Endian 
      12001 Unicode UCS-4 Big-Endian 
      20000 CNS - Taiwan 
      20001 TCA - Taiwan 
      20002 Eten - Taiwan 
      20003 IBM5550 - Taiwan 
      20004 TeleText - Taiwan 
      20005 Wang - Taiwan 
      20105 IA5 IRV International Alphabet No. 5 (7-bit) 
      20106 IA5 German (7-bit) 
      20107 IA5 Swedish (7-bit) 
      20108 IA5 Norwegian (7-bit) 
      20127 US-ASCII (7-bit) 
      20261 T.61 
      20269 ISO 6937 Non-Spacing Accent 
      20273 IBM EBCDIC - Germany 
      20277 IBM EBCDIC - Denmark/Norway 
      20278 IBM EBCDIC - Finland/Sweden 
      20280 IBM EBCDIC - Italy 
      20284 IBM EBCDIC - Latin America/Spain 
      20285 IBM EBCDIC - United Kingdom 
      20290 IBM EBCDIC - Japanese Katakana Extended 
      20297 IBM EBCDIC - France 
      20420 IBM EBCDIC - Arabic 
      20423 IBM EBCDIC - Greek 
      20424 IBM EBCDIC - Hebrew 
      20833 IBM EBCDIC - Korean Extended 
      20838 IBM EBCDIC - Thai 
      20866 Russian - KOI8-R 
      20871 IBM EBCDIC - Icelandic 
      20880 IBM EBCDIC - Cyrillic (Russian) 
      20905 IBM EBCDIC - Turkish 
      20924 IBM EBCDIC - Latin-1/Open System (1047 + Euro symbol) 
      20932 JIS X 0208-1990 & 0121-1990 
      20936 Simplified Chinese (GB2312) 
      21025 IBM EBCDIC - Cyrillic (Serbian, Bulgarian) 
      21027 Extended Alpha Lowercase 
      21866 Ukrainian (KOI8-U) 
      28591 ISO 8859-1 Latin I 
      28592 ISO 8859-2 Central Europe 
      28593 ISO 8859-3 Latin 3 
      28594 ISO 8859-4 Baltic 
      28595 ISO 8859-5 Cyrillic 
      28596 ISO 8859-6 Arabic 
      28597 ISO 8859-7 Greek 
      28598 ISO 8859-8 Hebrew 
      28599 ISO 8859-9 Latin 5 
      28605 ISO 8859-15 Latin 9 
      29001 Europa 3 
      38598 ISO 8859-8 Hebrew 
      50220 ISO 2022 Japanese with no halfwidth Katakana 
      50221 ISO 2022 Japanese with halfwidth Katakana 
      50222 ISO 2022 Japanese JIS X 0201-1989 
      50225 ISO 2022 Korean 
      50227 ISO 2022 Simplified Chinese 
      50229 ISO 2022 Traditional Chinese 
      50930 Japanese (Katakana) Extended 
      50931 US/Canada and Japanese 
      50933 Korean Extended and Korean 
      50935 Simplified Chinese Extended and Simplified Chinese 
      50936 Simplified Chinese 
      50937 US/Canada and Traditional Chinese 
      50939 Japanese (Latin) Extended and Japanese 
      51932 EUC - Japanese 
      51936 EUC - Simplified Chinese 
      51949 EUC - Korean 
      51950 EUC - Traditional Chinese 
      52936 HZ-GB2312 Simplified Chinese 
      54936 Windows XP: GB18030 Simplified Chinese (4 Byte) 
      57002 ISCII Devanagari 
      57003 ISCII Bengali 
      57004 ISCII Tamil 
      57005 ISCII Telugu 
      57006 ISCII Assamese 
      57007 ISCII Oriya 
      57008 ISCII Kannada 
      57009 ISCII Malayalam 
      57010 ISCII Gujarati 
      57011 ISCII Punjabi 
      65000 Unicode UTF-7 
      65001 Unicode UTF-8 
erem