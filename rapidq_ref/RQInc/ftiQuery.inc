$IFNDEF FTIQUERY_INC
$DEFINE FTIQUERY_INC
$ENDIF

' Warranties: None. This code is provided AS-IS.
' Developed on the Windows 98 SE platform.
' Version: 1.6.1!
' 
' Dependencies: 
' ftiExtractFileName
' ftiExtractProgNane
' ftiExtractProgPath
'
' Description:
' A cool include file that uses the registry to retrieve information on
'any file extension/type!

'Several constants have been defined that are used to retrieve this
'information, they are:

'
' Note(s):
' I'm going to try to put some of the code that reads the registry into
' a function, to reduce the file size.
'
' ftiClassName:
' queries the class name of the specified filetype
'
' ftiDefCommand:
' queries the value of the "shell/open/command" sub key
' of the parent program (module), the default command
'
' ftiContentType:
' queries the content type of the specified file type
' 
' ftiQueryDefault:
' queries the integrity of the registered file extension 
' (helps to see if there are any errors in the registry ;) )
'
' ftiProgramCommand:
' queries the parent (module) of the specified file type
'
' ftiDefaultIcon:
' queries the icon for the specified file type
'
' New updates:
'*****************************
' ftiProgramName:
' gets the actual file name of the parent of the specified file type
'
' ftiProgramExt:
' Gets the extension of the parent program. Later on I want to enable
' queries for the file extension.
'
' ftiProgramPath:
' Gets the actual program path.
'
' ** end of description *******************************************
' Special precautions:
' Whatever you do, DON'T turn the $escapechars preprocessor 
' directive ON! Doing so may result in incorrect registry
' settings, and/or may cause Windows to CRASH (not being able to boot 
' up Windows sounds about right).
'
' When you enter the first string argument of the GetFileTypeInfo function,
' make sure that you do not have 2 or more forward/backward slashes beside each other.
' Instead, enter the first argument like this: "C:/blah/files";
' not like this: "C:///blah//files".
' 
' Of course, you wouldn't actually have paths like that,
' that is, unless Windows was playing dominoes with your ASCII character set at the time :P
'
' Known bugs:
'  None actually, unless you consider the forward/backward slash problem a bug ;)
' You should be fine if you just obey the special rule.
'
' Usage:
'
' function:
' GetFileTypeInfo(FileType, ftiQueryValue)
'
' FileType: string
' ftiQueryValue: integer
'
' FileType can be a file extension, file name, path and file name,
' or even a dot with a file extension; basically anything as long as
' you obey the special rule defined in the Special precautions
' section. I'm trying to fix this =)
'
' ftiQueryValue is any of the several constants defined in the
' Description section.
'
' If an error occurs in reading the registry, GetFileTypeInfo will return -1.
' If you get a return value of one, that value is TRUE.
' If you get a return value of zero, that value is FALSE.

$ESCAPECHARS OFF

' File type info queries
const ftiClassName=1
const ftiDefCommand=2
const ftiContentType=3
const ftiQueryDefault=4
const ftiProgramCommand=5 ' makes more sense
const ftiDefaultIcon=6
const ftiProgramName=7 ' gets the actual program name
const ftiProgramExt=8 ' gets the extenstion of the program 
const ftiProgramPath=9 

function ftiExtractFileName(ptf$) as string
' trim the path
a$=ltrim$(rtrim$(ptf$))

' less coding; change all back slashes to forward slashes
a$=ReplaceSubStr$(a$,"\","/")
For i=1 to len(a$)
' now look for the token
 if Mid$(a$,i,1)="/" then
 ' go to the last position
  i++
   s=i
   ' get the file name
   b$=Mid$(a$,s,len(a$))
 end if
Next i

Function ftiExtractProgPath(rawcmd$) as string
p$=rawcmd$
p$=ReplaceSubStr$(p$,"\","/")

For i=1 to len(p$)
 if Mid$(p$,i,1)="/" then
   i++
  ends=i-1
  mymid$=Mid$(p$,1,ends)-CHR$(34)
  result=mymid$
    end if
Next i  
End Function

' finally, return the file name minus the quotes (if there are any), and it's ready to go :)
result=ReplaceSubStr$(b$,CHR$(34),"")
end function

function ftiExtractProgName(rawcmd$) as string
p$=rawcmd$
p$=ReplaceSubStr$(p$,"\","/")

For i=1 to len(p$)
 if Mid$(p$,i,1)="/" then
   i++
  starts=i 
  ends=InStr(starts,p$," ")
  lenstr=ends-starts
  mymid$=Mid$(p$,starts,lenstr)-CHR$(34)
  result=mymid$
  end if
Next i
end function

function GetFileTypeInfo(filetype as string, QueryValue as integer) as variant
if QueryValue=0 then QueryValue=1

Dim RegKey as QRegistry, iTemp as integer, filext as string
defstr ContentType$, FileClassName$, AssociatedCommand$, ParentName$
defstr szTmpName$
defint iProgramLen, iTmpLen, icoNotInFileClass, icoInClass1, icoInClass2

HKEY_CLASSES_ROOT=&H80000000
filext$=ltrim$(rtrim$(FileType))

if InStr(filext$,".") then
iTemp=InStr(filext$,".")+1
filext$=Mid$(filext$,iTemp,len(filext$))
 elseif InStr(filext$,"\") then
 iTemp=InStr(filext$,"\")+1
filext$=Mid$(filext$,iTemp,len(filext$))
elseif InStr(filext$,"/") then
iTemp=InStr(filext$,"/")+1
filext$=Mid$(filext$,iTemp,len(filext$))
 end if 
 
RegKey.RootKey=HKEY_CLASSES_ROOT

Select Case QueryValue

Case 1 ' get file class name
if RegKey.OpenKey("\."+filext$,0)=0 then
result=-1
else
 FileClassName$=RegKey.ReadString("")
result=FileClassName$
end if

Case 2 ' get associated command
RegKey.OpenKey("\."+filext$,0)
FileClassName$=RegKey.ReadString("")
RegKey.CloseKey
If RegKey.OpenKey("\"+FileClassName$+"\shell\open\command",0) then
AssociatedCommand$=RegKey.ReadString("")
result=AssociatedCommand$
else
result=-1
 end if
 
 Case 3 ' get content type
 if RegKey.OpenKey("\."+filext$,0)=0 then
 result=-1
 elseif RegKey.ReadString("Content Type")="" then
 result=-1
 else
  ContentType$=RegKey.ReadString("Content Type")
  result=ContentType$
  end if
  
 Case 4 ' is it default?
  if RegKey.OpenKey("\."+filext$,0)=0 then
  result=-1
  else
  if RegKey.ReadString("")="" then
  result=0
  else
   result=1
   end if
  end if
  
    Case 5 ' get the associated program command
  If RegKey.OpenKey("\."+filext$,0)=0 then
  result=-1
  else
   if RegKey.ReadString("")="" then
   result=-1
   elseif RegKey.ReadString("")<>"" then
   FileClassName$=RegKey.ReadString("")
   RegKey.CloseKey
   if RegKey.OpenKey("\"+FileClassName$+"\shell\open\command",0)=0 then
   result=-1
   else
   if RegKey.ReadString("")="" then
   result=-1
   else
   ProgramName$=RegKey.ReadString("")
   ProgramName$=ftiExtractFileName(ProgramName$)
    if ProgramName$="" then
    result="There is an error in your registry setttings:"+CHR$(13)+ _
    "The file class name: "+FileClassName$+" has been registered incorrectly."
    else
    result=ProgramName$
   end if
  end if
   end if
   end if
   
   
   ' Gets the icon for the specified filetype! 
     'If it's not found in the first class, it searches the second class.
     'If not found in the second class, it returns -1. 
   Case 6 
   if RegKey.OpenKey("\."+filext$+"\DefaultIcon",0) then
DefaultIcon$=RegKey.ReadString("")
IcoInClass1=1
result=DefaultIcon$
else
IcoInClass1=0
end if

if IcoInClass1=0 then
 if RegKey.OpenKey("\."+filext$,0)=0 then
result=-1
else
 if RegKey.ReadString("")="" then
 result=-1
 else
 FileClassName$=RegKey.ReadString("")
 RegKey.CloseKey
if RegKey.OpenKey("\"+FileClassName$+"\DefaultIcon",0)=0 then
result=-1
else
DefaultIcon$=RegKey.ReadString("")
 result=DefaultIcon$
 end if
end if
 end if
end if
 end if
 
 Case 7
 If RegKey.OpenKey("\."+filext$,0)=0 then
  result=-1
  else
   if RegKey.ReadString("")="" then
   result=-1
   elseif RegKey.ReadString("")<>"" then
   FileClassName$=RegKey.ReadString("")
   RegKey.CloseKey
   if RegKey.OpenKey("\"+FileClassName$+"\shell\open\command",0)=0 then
   result=-1
   else
   if RegKey.ReadString("")="" then
   result=-1
   else
   ProgramName$=RegKey.ReadString("")
   ProgramName$=ftiExtractProgName(ProgramName$)
    if ProgramName$="" then
    result="There is an error in your registry setttings:"+CHR$(13)+ _
    "The file class name: "+FileClassName$+" has been registered incorrectly."
    else
    result=ProgramName$
   end if
  end if
   end if
   end if
 end if
 
 Case 8
 If RegKey.OpenKey("\."+filext$,0)=0 then
  result=-1
  else
   if RegKey.ReadString("")="" then
   result=-1
   elseif RegKey.ReadString("")<>"" then
   FileClassName$=RegKey.ReadString("")
   RegKey.CloseKey
   if RegKey.OpenKey("\"+FileClassName$+"\shell\open\command",0)=0 then
   result=-1
   else
   if RegKey.ReadString("")="" then
   result=-1
   else
   ProgramName$=RegKey.ReadString("")
   ProgramName$=ftiExtractProgName(ProgramName$)
  ProgExt$=Mid$(ProgramName$,InStr(ProgramName$,".")+1,len(ProgramName$))
    
    if ProgramName$="" then
    result="There is an error in your registry setttings:"+CHR$(13)+ _
    "The file class name: "+FileClassName$+" has been registered incorrectly."
    else
    result=ProgExt$
   end if
  end if
   end if
   end if
 end if
 
 Case 9
 If RegKey.OpenKey("\."+filext$,0)=0 then
  result=-1
  else
   if RegKey.ReadString("")="" then
   result=-1
   elseif RegKey.ReadString("")<>"" then
   FileClassName$=RegKey.ReadString("")
   RegKey.CloseKey
   if RegKey.OpenKey("\"+FileClassName$+"\shell\open\command",0)=0 then
   result=-1
   else
   if RegKey.ReadString("")="" then
   result=-1
   else
   ProgramName$=RegKey.ReadString("")
   ProgramName$=ftiExtractProgPath(ProgramName$)
   
    if ProgramName$="" then
    result="There is an error in your registry setttings:"+CHR$(13)+ _
    "The file class name: "+FileClassName$+" has been registered incorrectly."
    else
    result=ProgramName$
   end if
  end if
   end if
   end if
  end if
  
   Case else
   result="Error: Query value "+str$(QueryValue)+" does not exist."
 End Select
end function  