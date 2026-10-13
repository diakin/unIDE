$IFNDEF __DBT_INC   ' IncManager: include guard
$DEFINE __DBT_INC
' Uses rapidQ.inc

'Allocates blocks of 512 bytes
const   FORCE_UPDATE = -1
dim blockCount AS LONG, currentRecID AS LONG
dim fs AS QFILESTREAM, __s AS STRING

'*
sub dbtCreate( dbtArch as string)
dim streamEx as QMemorystream

'print "Creating memo table.." ; dbtArch

if fs.open(dbtArch, fmCreate) = FALSE then
 'showMessage("Create fail ..  "+dbtArch)
 print "Create fail ..  "+dbtArch
 end
end if    

streamEx.writeNUM(1,4)
streamEx.size = 512      'Reserve rest

fs.CopyFrom(streamEx, 0)
fs.close
'print "Memo done!!"
end sub


sub dbtClose
 fs.close
 blockCount = 0
 __s = ""
end sub

'*
sub dbtOpen(dbtArch as string,  mode as integer)
if fs.open(dbtArch, mode) = FALSE THEN
  'showMessage("It can't be open  " + dbtArch)
  print "It can't be open  " + dbtArch
  END
end if

blockCount = fs.readNUM(4)           '<- First four bytes
currentRecID = -1
end sub

'*
private sub readRecord
Eom = 0   'End of record
__s = ""

while Eom=0
  __s = __s + fs.readSTR(512)
  Eom = INSTR(__s, Chr$(&H1A))
wend
end sub

'*
function MemoAppend(text as string) as integer
dim streamEx as QMemorystream

if Len(text) = 0  THEN
   exit function
end if
   
fs.position = fs.size

if blockCount = 1 THEN
  streamEx.WriteNUM(&H001A, 2)
  streamEx.size = 512

  fs.copyFrom(streamEx, 0)  'Fill the block
  inc blockCount
  
else
  streamEx.size = blockCount*512 - fs.position  
  fs.copyFrom(streamEx, 0)    'Reach next block  

end if

result = blockCount      'info to send toward the dbf routines

'Write it
'print "About to write" & text
fs.write(text)
fs.writeNUM(&H1A, 1)

'Update info
inc blockCount, 1+Len(text) / 512
fs.position = 0
fs.writeNUM(blockCount, 4)
end function


'*
function Memoget(n as long) as string
'n is the identifier of requested record ("pointer")
if n < 0  or n > blockCount  THEN
   exit function
end if

currentRecID = n      'Remember    

fs.position = n*512   'Beginning of data
readRecord            ' Uses __s 
result = Left$( __s, INSTR(__s, Chr$(&H1A))-1 )
end function

'*
function memoUpdate(newtext as string) as long
'If the number of 512-byte-blocks to be occupied with the received text is >
'than original number of blocks, then the text will be recorded at end of
'file, and the original record will remains in "place" but without any reference
'to it. Otherwise the original record is used but the end of text mark will be 
'updated.

n& = currentRecID     'This number is a "pointer"!!
'print "Memoupdate....."; "  Current pointer "; n&
if n& = -1  then
  goto leave
end if

'Old contents was saved to __s
l&      = Len(__s)
blocks% = l&/512
rest%   = l& mod 512

fs.position = n&*512    'Begin of record
select case Len(newText)
case is <= l&
   fs.write(newText)
   fs.writeNUM(&H1A, 1)

case else
   select case 1+Len(newtext) / 512
   case blocks%
     select case Len(newtext) mod 512
     case is > 0       'It doesn't fill the block
       fs.write(newText)
       fs.writeNUM(&H1A, 1)

     case 0  
       n& = MemoAppend(newtext)
     end select  

   case else
     n& = MemoAppend(newtext)
   end select  
end select   

currentRecID = -1   'Reset

leave:
result = n&     'Block count
end function

   
$ENDIF   ' IncManager: __DBT_INC
