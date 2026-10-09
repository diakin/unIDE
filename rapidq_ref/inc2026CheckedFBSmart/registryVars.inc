CONST fmCreate = 65535
CONST fmOpenRead = 0
CONST fmOpenWrite = 1
CONST fmOpenReadWrite = 2
CONST False = 0
CONST True  = 1

'/
'--*****************************************************'
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

'
type varInfo
    name as string*32
    strVal  as string*20
    primitive as byte
    end type

'Publics
dim varBuf as qMemoryStream

'-----------------
subi putMe(...)
dim thisVar as varInfo

if ParamValCount+ParamStrCount <> 3 then
  print "Incorrect number of parameter(s).."  :  END
end if
  
if paramStrCount = 2  then
  thisVar.name   = paramSTR$(1)
  thisVar.strVal = paramSTR$(2)
  thisVar.primitive = paramVal(1)
  
elseif ParamValCount = 2 then
  thisVar.name   = paramSTR$(1)
  thisVar.strVal = Str$(paramVAL(1))
  thisVar.primitive = paramVAL(2)
  
else
  print "Expected (string, string, int) or (string, single, int) .."
end if    

varBuf.writeUDT(thisVar)
end subi

'----------
function getMe(clave as string) as variant
dim thisVar as varInfo
count% = varBuf.size / sizeOf(thisVar)

if count% = 0  then
  result = ""  
  exit function
end if  

r$ = ""
p% = 0
j% = 1

size%  = varBuf.size
varBuf.position = 0       'Start
while varBuf.position < size%
  varBuf.readUDT(thisVar)
  
  if clave = RTrim$(thisVar.name) then
    r$ = thisVar.strVal
    p% = 10     'Any
    exit while
  end if
  
  inc j%
    if j% > count%  then
    exit while
  end if    
wend

if p% > 0  then
  select case thisVar.primitive
  case 0
    result = r$
  case 1   
    result = floatVal(r$)
  case else
    'Other possible primitives    
  end select
else
   result = ""  'Guess it..
end if	
end function

'-------
sub closeit()
  varBuf.close
end sub  

'-----------
sub saveTofile( filename )
dim file as qfilestream

if file.open( filename, fmCreate) == FALSE  then
  print "Cannot create file  " + filename
end if

file.CopyFrom(varBuf, 0)
file.close
end sub

'-----------
sub loadFromfile( filename )
dim file as qfilestream

if file.open( filename, fmOpenReadWrite) == FALSE  then
  print "Cannot open file  " + filename
end if

varBuf.size = 0        'KILL
varBuf.position = 0
varBuf.CopyFrom(file, 0)

file.close
end sub
