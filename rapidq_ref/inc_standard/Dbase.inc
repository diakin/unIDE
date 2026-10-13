$IFNDEF __DBASE_INC   ' IncManager: include guard
$DEFINE __DBASE_INC
$define  .F.    0
$define  .T.    not .F.

Struct dbcont
 memo AS BYTE
 updty AS BYTE
 updtm AS BYTE
 updtd AS BYTE
 nrecs AS LONG
 frecp AS WORD ' First record pointer
 recsize AS WORD
 filler AS STRING*20
end Struct

Struct flddef
 fname AS STRING*11
 ftype AS STRING*1
 filler AS STRING*4
 flen AS BYTE
 decimals AS BYTE
 fill2 AS STRING*14
end Struct

Struct fldinfo
 name as string*10
 owntype as string*1
 maxlen as byte
 decimals as byte
end Struct

 'Public
dim mStru as QmemoryStream, fldStr as QMemoryStream
dim h as dbCont, f as fldDef
dim openStr as QFileStream
dim openDbf as string*64

'*************
sub struinfo(id as string, thistype as string, _
             fullen as byte, point as byte)
'It must be called before of a table creation. Do a call for each field needed
dim u as fldinfo

u.name=id: u.owntype=thistype: u.maxlen=fullen: u.decimals=point
mStru.WriteUDT(u)
end sub
'-----------

function dbCreate( nameArch as string) as integer
'USES mStru

dim openStr as QFileStream
dim mstream as QMemoryStream

if mStru.size = 0 Then
  print "No information available.."
  Exit function
end if

'print "dbCreate() called..!!" + " Data ->" +Str$(mStru.size)+ "bytes."

if openStr.open(nameArch, fmCreate) = FALSE then
  result = FALSE
  exit function
end if

' Fill up "the dictionary"
dim now as STRING*10
now = DATE$

dim h as dbcont
dim thisfld as flddef
dim nflds as word
dim u as fldinfo 'Real info

h.memo    = &H03 'Let us assume there isn't memos
h.recsize = 0
h.nrecs   = 0
nflds     = mStru.size / sizeof(u)

mStru.position = 0
for i% = 1 to nflds
mStru.readUDT(u)
with thisfld
 .fname    = UCASE$(sz10Convert(u.name))
 .ftype    = u.owntype
 .flen     = u.maxlen
 .decimals = u.decimals
end with

if thisfld.ftype = "M" then
  'print "Memo field found.."
  h.memo = &H83 'NOTE ..
end if

'We cannot write toward openStr until h.memo is certain
mstream.writeUDT(thisfld) '
if thisfld.ftype = "C" then
  h.recsize = h.recsize + thisfld.flen + thisfld.decimals*256
else
  h.recsize = h.recsize + thisfld.flen
end if
next

'Dbf files have a delete caracter ,(*), as first byte of register stream
h.recsize = h.recsize + 1

if h.memo = &H83  then
  dbtCreate(ReplaceSubstr$(nameArch, "dbf", "dbt"))
end if

h.frecp = 32 * (1 + nflds) + 2 'Count bytes H&OD and H&00 too
h.updty = val( mid$(now, 9,2) )   ' "2003" -> "03"
h.updtm = val( mid$(now, 1,2) )
h.updtd = val( mid$(now, 4,2) )

with openStr
 'Header
 .writeUDT(h)

 ' Struct
 .copyFrom(mstream,0)

 ' Close bytes
 .writeNum(&H000D,2)
 .writeNum(&H1A,1)
end with

'ShowMessage "Ready.."

mstream.close
openStr.close 'Close the file

'mStru.size = 0 'Empty it
result = TRUE
end function
'---------------------------

function dbOpen(dbfArc as string, mode as integer) as integer
result = FALSE
'print dbfArc

if openStr.open(dbfArc, mode) = FALSE then
  print "It can't be open.. " + dbfArc
exit function
end if

openStr.ReadUDT(h)
if h.memo = &H03 or h.memo = &H83 then
else
  print "Invalid file format.."
  exit function
end if

if h.memo = &H83  then
  dbtOpen(ReplaceSubstr$(dbfArc, "dbf", "dbt"), mode)
end if
  
'Defines.
openDbf = dbfArc

'Ignore CHR$(&H0D) + CHR$(0)
fldstr.CopyFrom(openStr, h.frecp-SizeOf(h)-2) 	'Fields descriptor
openStr.position = h.frecp 						'Ready for read

result = TRUE
end function

'-------------------------

sub dbClose
if h.memo = 0 then
exit sub
end if

if h.memo = &H83  then
  dbtClose
end if  

openStr.close
h.memo = 0 'A utility flag

'Shrink
fldStr.size = 0
openDbf = ""
end sub


function hasMemo() as integer 'Very low level (it isn't a "standard" one.)
result = (h.memo = &H083)
end function

function dataOffset() as integer 'Idem
result = h.frecp
end function


sub dbgotop
openStr.position = h.frecp
end sub


sub dbgoto(n as long)
if n > h.nrecs  then   n = h.nrecs
if n < 1  then  n=1

openStr.position = (n-1) * (h.recsize) + h.frecp
end sub


function recno() as long
result = 0

if (openStr.position - h.frecp) < 0  then  exit function
result = 1+(openStr.position - h.frecp)/h.recsize
end function


sub dbSkip(n as long)
here& = openStr.position
there& = openStr.position + n * h.recsize

if there& < h.frecp then
  openStr.position = h.frecp : exit sub
end if
if there& > openStr.size then
  openStr.position = openStr.size-1 : exit sub
end if

'Then.. go
openStr.position = there&
end sub


sub dbgobottom
openStr.position = h.frecp + iif(h.nrecs = 0, 0, h.nrecs-1) * h.recsize
end sub


function bof() as integer
result = (openStr.position = h.frecp)
end function


function eof() as integer
here& = openStr.position
openStr.Read(i?) 'A lookahead
openStr.position = here&

result = ( i? = &H1A)
end function


function recsize() as word
result = h.recsize
end function


function reccount() as long 'Also named lastrec()
result = h.nrecs
end function


function fCount() as integer
result = fldStr.size / sizeOf(f)
end function


sub dbAppend
if openstr.size = 0  then
  exit sub
end if  

openStr.position = openStr.size - 1
openStr.writeStr(string$(recsize(), 32), recsize())
openStr.WriteNUM(&H1A, 1)

'Update
h.nrecs = h.nrecs + 1

h.updty = val( mid$(date$, 9,2) )     
h.updtm = val( mid$(date$, 1,2) )
h.updtd = val( mid$(date$, 4,2) )

openStr.position = 0
openStr.writeUDT(h)
dbgoBottom
end sub

'*
sub dbZap
dim auxStr as QMemoryStream

openStr.position = 0
h.nrecs=0    'NOTE
h.updty = val( mid$(date$, 9,2) )
h.updtm = val( mid$(date$, 1,2) )
h.updtd = val( mid$(date$, 4,2) )

openStr.writeUDT(h)

openStr.position = 0
auxStr.CopyFrom(openStr, h.frecp)
auxStr.WriteNUM(&H1A, 1)

openStr.close
KILL openDbf

openStr.open(OpenDbf, fmCreate)
openStr.CopyFrom(auxStr, 0)

openStr.position = openStr.size - 1

if h.memo = &H83  then
  dbtClose
  dbt$ = ReplaceSubstr$(openDbf, "dbf", "dbt")

  KILL dbt$
  dbtCreate(dbt$)
  dbtOpen(dbt$, fmOpenReadWrite)
end if  
end sub 

'*
function fieldGet( i as word) as variant
result = ""
if i <= 0 or i > fCount()  then  exit function

pos& = openStr.position     'Return point

fldStr.position = 0
null$ = openStr.readStr(1)     'Skip this flag

for j__ = 1 to i
 fldStr.readUDT(f)

 select case f.ftype
 case "C"
   __lon = f.flen + 256 * f.decimals
 case else
   __lon = f.flen
 end select

 'Advance (or get it)
 __r$ = OpenStr.ReadStr(__lon)
next

select case f.ftype
case "C"
  result = __r$
case "D"
  result = stod(__r$)
case "N"
  result = floatVal(__r$)
case "M"
  'A pointer to register into dbt archive
  result = ""
  if Val(__r$) > 0  then
    result = memoget( Val(__r$) ) 
  end if  
case "L"
  'Logical
  result = IIF( __r$ = "F", .F., .T.)
end select
  
openStr.position= pos&
end function

'**
' This call is tricky (Variant parameters doesn't accept constants)
sub fieldput(index as word, $value as string, #value as single )
 ' print "Second parameter  "; #value 
 if index <= 0 or index > fCount()  then  exit sub
  
 pos& = openStr.position
 fldStr.position = 0
 lon?? = 0

 null$ = openStr.ReadStr(1)     'This byte is the "delete" flag ("*")
 __j=0
 do
  ' Find it
  inc(__j)
  fldStr.ReadUDT(f)    
 
  select case f.ftype
  case "C"
    lon?? = f.flen + 256 * f.decimals
  case else
    lon?? = f.flen
    
    if f.ftype = "M" and #value = FORCE_UPDATE then
       currentRecID = Val( openStr.readStr(lon??) )  'See dbt.inc
       openStr.position = openStr.position - lon??
    end if    
  end select
  
  if __j = index  then  exit do
  openStr.position = openStr.position + lon??
 loop

 select case f.ftype
 case "C"
  'Justificar a la izquierda
   __s$ = Format$("%-"+Str$(f.flen + 256 * f.decimals)+"s", $value)
 case "D"
   __s$ = Format$("%"+Str$(f.flen)+"s", dtos($value))  ' Must be 8
   'print __s$
 case "N"
  'format$("%12.2f", 567812.34)
   __s$ = Format$("%"+Str$(f.flen-f.decimals-1)+"."+Str$(f.decimals)+"f", #value)
 case "M"
  __s$ = Format$("%10d", memoUpdate($value))  
 case "L"
  __s$ = IIf(#value = .F., "F", "T")
 end select

 openStr.Write(__s$)
 openStr.position = pos&
end sub

'*
'
function fieldname(i as word) as string
result = ""
if i <= 0 or i > fCount()  then  exit function

fldstr.position = (i-1) * SizeOf(f)
fldstr.readUDT(f)

result = sz10Unconvert(f.fname)
end function

'*
'
function fieldpos(fldname as string) as integer
result = 0
j__% = 1

fldstr.position = 0
do
 fldstr.readUDT(f)
  
 if sz10Uncovert(f.fname)= name  then
    result = j__%
    exit do
 end if

 inc(j__%)
loop
end function

'*
'
function TypeOf( fnum as word) as string
result = "U"

if fnum <= 0 or fnum > fCount()  then  exit function
fldStr.position = (fnum - 1) * sizeOf(f)
result = f.ftype
end function

'*
'
function DecimalsOf( fnum as word ) as integer
result = 0

if fnum <= 0 or fnum > fCount()  then  exit function
fldStr.position = (fnum - 1) * sizeOf(f)
fldstr.ReadUDT(f)
result = f.decimals
end function

'*
'
function LengthOf( fnum as word ) as integer
result = 0

if fnum <= 0 or fnum > fCount()  then  exit function
fldStr.position = (fnum - 1) * sizeOf(f)
fldstr.ReadUDT(f)

select case f.ftype
case "C"
  result = f.flen + 256 * f.decimals
case else
  result = f.flen
end select
end function

'dbBuffer always point to first byte of current record
sub Delete
   pos& = openStr.position
   openStr.WriteStr("*", 1)
   openStr.position = pos&
end sub

sub Recall
  pos& = openStr.position
  openStr.WriteStr(" ", 1)
  openStr.position = pos&
end sub
 
function dbDeleted as integer
  pos& = openStr.position
  c$   = openStr.ReadStr(1)
  openStr.position = pos&
   
  result = ( c$ = "*" )
end function  

'*
sub dbPack
'It doesn't take argument, current stream is on target
'No memos until multitable management becomes
dim buf as QMemorystream

openStr.position = h.frecp            'We can use here "low level" operations

count& = 0
while not eof()
  if not dbDeleted()  then
	buf.WriteBinStr(openStr.ReadBinStr(h.recsize), h.recsize)  'Save it
	inc count&
  else
    dbSkip 1
  end if
wend

openStr.position = h.frecp       
openStr.copyFrom(buf, 0)         'Overwrite
openStr.WriteNUM(&H1A, 1)        'Eof mark

'Update info
openStr.position = 0
h.nrecs = count&    'NOTE
h.updty = val( mid$(date$, 9,2) )
h.updtm = val( mid$(date$, 1,2) )
h.updtd = val( mid$(date$, 4,2) )

openStr.writeUDT(h)
openStr.position = h.frecp
end sub


  	
'*****
function dblocate(key as variant) as integer
'It looks for all the fields at the pointed record
result = .F.
current& = recno()
keyType? = Vartype(key)

dim fvalue as variant
for i% = 1 to fCount()
  fvalue = fieldget(i%)

  if Vartype(fvalue) = keyType?  then
    select case keyType?
    case 2        'String
      If len(key) > len(fvalue)  then
        exit function
      end if  

      if INSTR( UCASE$(fvalue), UCASE$(key)) > 0  then
        result = .T.
        exit for             'Found
      end if  
    
    case 0,1
      if key = fvalue  then
        result = .T.  
        exit for             'Found
      end if  
    end select
  end if
next  

dbgoto(current&)     'Reset to beginning of register
end function


'*
'
function dbscan(key as variant, fname as string, mode as integer) as integer
'It looks for the suitable field at the pointed record
result = .F.
dim value as variant

ftype = typeOf( fname )
value = fieldget( fieldpos(fname) )

select case mode
case 0                 'Equality
  select case ftype
  case "N", "D"         'Exact
    if key = value  then
      result = .T.
    end if
  case "C"               'It could be inexact
    If len(key) > len(value)  then
      exit function
    end if  
       
    if UCASE$(MID$(value, 1, Len(key))) = UCASE$(Key) then
      result = .T.
    end if  
  end select  
case else
end select   

end function

'A simple example
sub dbCopyto(targetFileName as string, sourceFieldName as string, thisValue as variant)
'Remember.. openStr is the source. It cannot be touched.
'No memos until Qdbase (or something alike..)
dim tmpStr as QFileStream

if not tmpStr.open(targetFileName, fmcreate)  then
  print "Cannot create target table " + targetFileName
  exit sub
end if  

pos& = openStr.position        'Remember
openStr.position = 0 

tmpStr.CopyFrom(openStr, h.frecp)

count& = 0
openStr.position = h.frecp      'Be sure
while not eof()
if dbScan(thisValue, sourceFieldname, 0)  then
	tmpStr.WriteBinStr(openStr.ReadBinStr(h.recsize), h.recsize)
	inc count&
else
	dbSkip 1
end if
wend

'Update target header
tmpStr.position = 0
dim head as dbCont

head.nrecs = count&
head.updty = val( mid$(date$, 9,2) )
head.updtm = val( mid$(date$, 1,2) )
head.updtd = val( mid$(date$, 4,2) )
tmpStr.WriteUDT(head)
tmpStr.close            'Done

openStr.position = pos&
end sub
  
$ENDIF   ' IncManager: __DBASE_INC
