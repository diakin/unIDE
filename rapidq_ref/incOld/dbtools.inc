'/1
function sz10Convert(text as string) as string
s$ = Left$(Rtrim$(text),10)
result = insert$(Chr$(0), s$, Len(s$)+1)
end function

'/2
function sz10Unconvert(s as string) as string
result = Left$( s, INSTR(s, Chr$(0))-1 )
end function

'/3
function dtos(date as string) as string
  ' "mm/dd/yyyy" or "mm-dd-yyyy" -> "yyyymmdd"
  result = MID$(date,7,4)+MID$(date, 1, 2)+MID$(date, 4, 2)
end function     

'/4
function stod(dtos$ as string) as string
  ' "mm/dd/yyyy"
  result = MID$(dtos$,5,2)+"/"+MID$(dtos$,7,2)+"/"+MID$(dtos$,1,4)
end function     

'/
function pad(s as string, width as byte) as string
  result = Left$( s + space$(width), width)
end function

'/
function floatVal( number as string) as single
result = 0

number = LTRIM$(RTRIM$(number))
if Len(number) = 0  or  Val(number) = 0   then
  exit function
end if
  
point? = instr(number, ".")

if point? > 0  then
  decimal$ = Mid$(number, point?+1)
  result = Val( Mid$(number, 1, point?-1) )+Val(decimal$)/10 ^ Len(decimal$)

else
  result = Val(number)
end if
end function     

'_________________________________________
  
$define  .F.   0
$define  .T.   not .F.

const fmCreate = 65535
const fmOpenRead = 0
const fmOpenWrite = 1
const fmOpenReadWrite = 2
  