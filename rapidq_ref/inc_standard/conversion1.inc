$IFNDEF __CONVERSION1_INC   ' IncManager: include guard
$DEFINE __CONVERSION1_INC
'--------------------------- Custom functions --------------------------
Declare Function CharToOem Lib "user32" Alias "CharToOemA" _
(ByVal lpszSrc As String, ByVal lpszDst As String) as Long

Declare Function OemToChar Lib "user32" Alias "OemToCharA" _
(ByVal lpszSrc As String, ByVal lpszDst As String) As Long

Declare Function CharLower Lib "user32" Alias "CharLowerA" (ByVal lpsz As String) As String
Declare Function CharUpper Lib "user32" Alias "CharUpperA" (ByVal lpsz As String) As String

'-- **************************** **********************************************'
function LCaseApi(  SrcTxt as string ) as string
tmp$=SrcTxt+"-"
l=len(SrcTxt)
result=CharLower(left$(tmp$,l))
end function

'-- **************************************************************************'
function UCaseApi(  SrcTxt as string ) as string
tmp$=SrcTxt+"-"
l=len(SrcTxt)
result=CharUpper(left$(tmp$,l))
end function

'-- **************************************************************************'
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
function AddChrBefore(NumStr as string , Dlina as integer, chr as string) as string
'Andrew Shelkovenko dec 2003
'A function that pre-padd string with chr to required Length 
'print AddChrBefore("-387.35" , 10, "=")  
'==-0387.35

diM kolvo as integer
kolvo =Dlina-Len(NumStr)
if   kolvo<0 theN AddChrBefore="String too long"
if   kolvo=0 theN AddChrBefore=NumStr: exit function
AddChrBefore= STRING$(kolvo, chr)+ NumStr
end function
 

'-- **************************************************************************'
function Add0Before(NumStr as string , Dlina as integer) as string
'Andrew Shelkovenko dec 2003
'A function that pre-padd string with 0's to required Length 
'print Add0Before("-387.35" , 8)  
'-0387.35


diM kolvo as integer
kolvo =Dlina-Len(NumStr)
if   kolvo<0 theN Add0Before="String too long"
if   kolvo=0 theN Add0Before=NumStr: exit function

Add0Before	= STRING$(kolvo, "0")+ NumStr

end function

'-- **************************************************************************'
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
	if val(poz$)> LenB then ShowMessage( "ReOrder index outbound input string"):exit FUNCTION
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
ShowMessage "Can't to write BYTE.Wrong parameter type - Num_BYTE": exit funCTION
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
ShowMessage "Can't to write BYTE.Wrong parameter type - Num_BYTE": exit funCTION

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

TimeString=Hr$+":"+Min$+":"+Sec$+"   "

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

sub Ob2Grad (obor as single,  SecFull as integer, SecMnt as integer,  Grad as integer,  Mint as integer,  Sec as integer,  Ugl$ as string)
'convert value of revolutions to degree of arc
'obor - value of revolutions (input)
'SecFull - Full secounds of arc in value of revolutions
'Grad - degrees of arc 
'Mint - minutes of arc
'Sec - Secounds of arc
'Ugl$ - string repres. of value of revolutions in {arc degrees, minutes, secounds} format
'SecMnt -secounds of arc in {arc degrees, secounds format} representation of the revolutions value(, i.e. Grad,SecMnt)

SecFull=obor*360*60*60
sign=sgn(obor)
obor=abs(obor)
Grad=fix(obor*360)'+val(Edit18.text)'

Mint=fix((obor*360-Grad)*60)

Sec=round((((obor*360-Grad)*60)-Mint)*60)

if sec=60 then 
	sec=0
	inc mint
	if mint=60 then
		mint=0
		inc grad
	end if
end if

SecMnt=round((obor*360-Grad)*3600)

if sgn(SecFull)=-1 then zn$="-" else zn$=""

Ugl$=zn$+str$(abs(Grad))+"°"+str$(abs(Mint))+"'"+str$(abs(Sec))+qt

end sub
'*********************************************************************
              
$ENDIF   ' IncManager: __CONVERSION1_INC
