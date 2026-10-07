Const FILE_ATTRIBUTE_READONLY = &H1
Const FILE_ATTRIBUTE_HIDDEN = &H2
Const FILE_ATTRIBUTE_SYSTEM = &H4
Const FILE_ATTRIBUTE_DIRECTORY = &H10
Const FILE_ATTRIBUTE_ARCHIVE = &H20
Const FILE_ATTRIBUTE_NORMAL = &H80
Const FILE_ATTRIBUTE_TEMPORARY = &H100
Const FILE_ATTRIBUTE_COMPRESSED = &H800

Type SECURITY_ATTRIBUTES
nLength As Long
lpSecurityDescriptor As Long
bInheritHandle As Long
End Type


Declare Function GetFileAttributes Lib "kernel32" Alias "GetFileAttributesA"_
(ByVal lpFileName As String) As Long
Declare Function SetFileAttributes Lib "kernel32" Alias "SetFileAttributesA"_
(ByVal lpFileName As String, ByVal dwFileAttributes As Long) As Long

Declare Function CreateDirectory Lib "kernel32" Alias "CreateDirectoryA" _
(ByVal lpPathName As String, lpSecurityAttributes As SECURITY_ATTRIBUTES) As Long



'# QUOTE : Returns a quoted string
function Quote (StringToQuote as string) as string
StringToQuote =  chr$(34) + StringToQuote + chr$(34)
result = replacesubstr$(stringtoquote, chr$(34) + chr$(34), chr$(34))
end function

'===============================================================================
'# STRIPPATH : Returns file path (without file name)
Function StripPath (fullname as string) as string
result = left$(fullname, rinstr(fullname, "\"))
end function

'===============================================================================
'# STRIPFILENAME : Returns file name (without path)
Function StripFileName (fullname as string) as string
result = right$(fullname, len(fullname) - rinstr(fullname, "\"))
end function

'===============================================================================
'# STRIPFILEEXT : Returns file extension (like ".exe", ".html" etc.)
Function StripFileExt (fullname as string) as string
fullname=StripFileName(fullname)
if instr(fullname,".")=0 then 
	result =""
else
	result = right$(fullname, len(fullname) - rinstr(fullname, ".") + 1)
end if
end function

'===============================================================================
'# FILENAMENOEXT : Returns file name without extension
function FileNameNoExt(fullname as string) as string
fullname = right$(fullname, len(fullname) - rinstr(fullname, "\"))
result = left$(fullname, rinstr(fullname, ".") - 1)
end function

'===============================================================================
'# FULLPATHNOEXT : Returns full path without file extension
function FullPathNoExt(fullname as string) as string
result = left$(fullname, rinstr(fullname, ".") - 1)
end function

'===============================================================================
'# C_Style : Returns "slashed" path from a "backslashed" one
function C_Style (fullname as string) as string
fullname = replacesubstr$(fullname, "\\", "\")
result = replacesubstr$(fullname, "\", "/")
end function

'===============================================================================
'# SYSDIR : Retrieves windows shell directories

'-------------------------|
' Allowed values for dir  |
'-----------------------------------------------------------------------------|
' Desktop                 | Templates               | AppData                 |
' Start Menu              | Programs                | Startup                 |
' Fonts                   | SendTo                  | Recent                  |
' Favorites               | Cache                   | Cookies                 |
' History                 | NetHood                 | Personal                |
' PrintHood               | Local AppData           | My Pictures             |
' Administrative Tools    |                         |                         |
'-----------------------------------------------------------------------------|

function SysDir (dir as string) as string
DIM fo_reg AS QRegistry
fo_reg.RootKey = &H80000001
fo_reg.openkey ("Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders", 0)
result = fo_reg.readstring(dir) + "\"
end function

'===============================================================================
'# HOMEDIR : The folder where the application is

function homedir() as string
result = left$(command$(0), rinstr(command$(0), "\"))
end function

'===============================================================================
'# BROWSEFORFOLDERS : Returns the selected folder

function BrowseForFolders (initialdir as string, wincapt as string) as string
dim bff_form as qform
with bff_form
	.height = 400
	.center
	.caption = wincapt
	.delbordericons 2
end with
dim bff_tree as qdirtree
with bff_tree
	.parent = bff_form
	.align = 5
end with
if bff_form.caption = "" then bff_form.caption = "Select folder"
if direxists(initialdir) then
	bff_tree.directory = initialdir
else
	bff_tree.directory = curdir$
end if
bff_form.showmodal
result = bff_tree.directory
end function

'===============================================================================
'# BROWSEFORFILE : Returns the selected folder

Function BrowseForFile (caption as string, filter as string, _
initialdir as string) as string

dim bff_od as qopendialog
with bff_od
	.caption = caption
	.filter = filter
	.initialdir = initialdir
	
	if .execute then
		result = .filename
	end if
end with

end function

'_=============================================================================

$ESCAPECHARS ON

'ChangeFileExt:
'Returns: String
'Parameters:
'FileName (String): Name of file with old extention
'NewExt (String): New extention. This must include the leading ".".

'Information:
'Author: Taj Morton
'Email: tmorton at linuxmail dot org.
'License: Public Domain

'Description:
'Changes the extention of FileName to NewExt. For example:
'ChangeFileExt("File.bas", ".inc")
'returns File.inc. This function does not delete the old string,
'instead, it simply returns a new one with the extention.
'You must include the leading "." for it to be added, as it is not
'done by the function.

FUNCTION ChangeFileExt(FileName as String, NewExt as STRING) as STRING
DIM Returns as STRING
DIM CurrentExt as String
DIM CurrentExtLoc as INTEGER
DIM FileNoExt as STRING

CurrentExtLoc = RInStr(FileName, ".")
CurrentExt = MID$(FileName, CurrentExtLoc, LEN(FileName))
FileNoExt = DELETE$(FileName, CurrentExtLoc, LEN(FileName))

Result = INSERT$(NewExt, FileNoExt, LEN(FileName))
ChangeFileExt = Result
END FUNCTION

'ExtractFileName:
'Returns: String
'Parameters:
'FileName (String): File with full path

'Information:
'Author: Taj Morton
'Email: tmorton at linuxmail dot org.
'License: Public Domain

'Description:
'ExtractFileName takes a file name with a path and returns only
'the file name. For example:
'ExtractFileName("C:\\Program Files\\AFile.bas")
'returns AFile.bas. You can use either two back-slashes or a single
'forward slash (/) for folder seperators.
'Both forward and back-slashes are supported by Windows.
'The back-slash takes procedure over the forward slash.
'Note that ExtractFileName does _not_ check the validity of the path passed.
'You must check yourself.

FUNCTION ExtractFileName(FileName as STRING) AS STRING
DIM Length as INTEGER
DIM Result as STRING

Length = RInStr(FileName, "\\") OR RInStr(FileName, "/")
Result = MID$(FileName, Length+1, LEN(FileName) - Length + 1)
ExtractFileName = Result
END FUNCTION

'ExtractFilePath
'Returns: String
'Parameters:
'FileName (String): File with full path

'Information:
'Author: Taj Morton
'Email: tmorton at linuxmail dot org.
'License: Public Domain

'Description:
'ExtractFilePath takes string with full path and returns a string
'with only the path. For example:
'ExtractFilePath("C:\\Program Files\\AProgram.bas")
'returns C:\Program Files (the \\'s are for RQ and back-slashes).
'ExtractFilePath also takes forward-slashes (/). Window's supports
'these as well. 
'The back-slash takes procedure over the forward slash.
'Note that ExtractFilePath does _not_ test the validity
'of the passed name. You must check it yourself. Even if the name is
'invalid, the path will be returned. For example, if C:/ProgramErrorFiles/AFile.txt
'is passed, C:/ProgramErrorFiles will be returned.

'-- *****************************************************'
FUNCTION ExtractFilePath(FileName as STRING) AS STRING
DIM Length as INTEGER
DIM Result as STRING

Length = RInStr(FileName, "\\") OR RInStr(FileName, "/")
Result = MID$(FileName, 0, Length)
ExtractFilePath = Result
END FUNCTION

'ChangeFileName
'Returns: String
'Parameters:
'FileName (String): File with full path
'NewName (String): Text that will replace old file name

'Information:
'Author: Taj Morton
'Email: tmorton at linuxmail dot org.
'License: Public Domain

'Description:
'ChangeFileName takes a file name with full path and file and a new name.
'It replaces the current filename (in FileName) and replaces it with NewName.
'ChangeFileName does not actually change FileName, instead it returns a new
'string which contains the new name.
'Note that ChangeFileName does not check the validity of FileName
'or the new result. You must do it yourself (if you want). ChangeFileName
'takes both the back-slash and forward slash to serperate folder and file names.
'You can use either \\ or /. Both are supported by Windows.
'The back-slash takes procedure over the forward slash.

'-- *****************************************************'
FUNCTION ChangeFileName(FileName as STRING, NewName as STRING) AS STRING
DIM FileNameLoc as INTEGER
DIM Result as STRING
DIM PathNoName AS STRING

PathNoName = ExtractFilePath(FileName)
Result = PathNoName+NewName
ChangeFileName = Result
END FUNCTION

'ChangeFilePath
'Returns: String
'Parameters:
'FileName (String): File with full path
'NewPath (String): New path that will replace the path in FileName

'Information:
'Author: Taj Morton
'Email: tmorton at linuxmail dot org.
'License: Public Domain

'Description:
'ChangeFilePath takes FileName and replaces the path with NewPath.
'It does not change FileName to have the new path, instead, it returns
'a string which has the new path. It's up to you to take the correct
'action. Also, old or new path and names' are not checked for validity,
'you must do it yourself.
'You may use either the \\ or the / to seperate your paths. Windows supports
'both. 

'-- *****************************************************'
FUNCTION ChangeFilePath(FileName as STRING, NewPath as STRING) AS STRING
DIM Result AS STRING
DIM FileNoPath AS STRING

FileNoPath = ExtractFileName(FileName)

Result = NewPath+FileNoPath
ChangeFilePath = Result
END FUNCTION
$ESCAPECHARS Off

'-- *****************************************************'
FUNCTION FileSize(FileName as STRING) AS integer
DIM fileStr as QFileStream

if fileexists (FileName)>0 then 
	fileStr.open (FileName,0)
	result=fileStr.size
	fileStr.close
else
	result=-1
end if

END FUNCTION
'-- *****************************************************'
FUNCTION SaveString(ss$ as STRING ,FileName as STRING  ) AS integer
'print"FileName=";FileName
'print"ss$=";ss$
result=0

if FileName="" then showmessage ("FUNCTION SaveString. Wrong FileName="+FileName):exit function
DIM fileStr as QFileStream
fileStr.open (FileName,65535 ) 'fmCreate'
result=-1
FileStr.WriteStr(ss$, len(ss$)) 
FileStr.Close
result=1
END FUNCTION

'-- *****************************************************'
FUNCTION SaveStringEx(ss$ as STRING ,FileName as STRING, mode as integer  ) AS integer
' save string SS$ to file FileName. 
'Mode=0 - overwrite, 
'Mode=1 - append string ss$ to file FileName
'Mode=2 - append  crlf+ss$ to file FileName

result=0

if FileName="" then showmessage ("FUNCTION SaveString. Wrong FileName="+FileName):exit function

DIM fileStr as QFileStream

if mode=0 then
	result=0
	fileStr.open (FileName,65535 ) 'fmCreate'
	result=-1
	FileStr.WriteStr(ss$, len(ss$)) 
	FileStr.Close
elseif mode=1 or mode=2 then
	if fileexists(FileName)=0 then md=65535:crl="" else md=2:crl$=crlf 'showmessage ("FUNCTION SaveString. Can't open File="+FileName):exit function
	fileStr.open (FileName,md ) 'fmOpenReadWrite = 2
	fileStr.Position=fileStr.size
	result=-1
	if mode=1 then FileStr.WriteStr(ss$, len(ss$)) else FileStr.WriteStr(crl$+ss$, len(crl$+ss$))
	FileStr.Close
else
end if

result=1

END FUNCTION

'-- *****************************************************'
FUNCTION LoadString(FileName as STRING  ) AS string
DIM fileStr as QFileStream
result="0"
'fmOpenRead = 0
if fileStr.open (FileName,0 ) then'fmCreate'
	result="-1"
	result=FileStr.ReadStr( FileStr.size) 
	FileStr.Close
	'result=1
end if

END FUNCTION

'_==============================================================


'-- *****************************************************'

function MKSubDir (DirDst$) as short
'Andrew Shelkovenko dec 2003, jul 2004
'Create DirDst$ directory with full subdir structure
'----------------------------------------------
'print "MKSubDir DirDst$="; DirDst$
result=0
dim DirDst1$ as string
DirDst1$=string$(len(DirDst$),"a") 
'chartooem DirDst$,DirDst1$ 
DirDst1$=DirDst$ 

if right$(DirDst1$,1)<>BkSl then DirDst1$=DirDst1$+BkSl 
z1=instr(DirDst1$,BkSl)
z2=0
while z1>0
	SubDirDst$=left$(DirDst1$,z1 )
	if DIREXISTS(SubDirDst$)=0 then MKDIR SubDirDst$ :'print "MKSubDir SubDirDst$=" ,SubDirDst$
	z2=z1+1
	z1=instr(z2,DirDst1$,BkSl)
wend

result=1
end function

'-- *****************************************************'
sub SubDirCopy (DirSrc$, DirDst$, mask$) '- -----------------------------------'
'Andrew Shelkovenko dec 2003
'Copy DirSrc$ directory with full subdir structure and files (by mask$) to DirDst$
dim FileSrc as QFileStream
dim FileDst as QFileStream

'Index=0
NumFiles=0
defint nsd1, nsd2
defstr mask
nsd1=0:nsd2=0
NumDir=0
ArrNumDir=500
dim SubDir(500) as string

ArrNumFil=500
dim FileNames (500) as string
mask="*.*"
if right$(DirSrc$,1)<> BkSl then DirSrc$=DirSrc$+BkSl
if right$(DirDst$,1)<> BkSl then DirDst$=DirDst$+BkSl
SubDir(0)=DirSrc$

sss1:
for i=NSD1 to Nsd2 'current level sudirs'
	'print "374 SubDir(",i,")=",SubDir(i)
	SubDirname$=dir$(SubDir(i)+mask, faDirectory)
	
	while    SubDirname$ <>""
		if FileRec.Size =0 and SubDirname$<> "." and SubDirname$<> ".." then ''
			inc adddir
			inc NumDir 'add subdir'
			if NumDir=ArrNumDir then ArrNumDir=ArrNumDir+300: redim SubDir(ArrNumDir) as string
			SubDir(NumDir)=SubDir(i)+SubDirname$+"\"
			'print "383 SubDir(", NumDir, ")=",SubDir(NumDir)
		else
		end if
		SubDirname$=dir$
		doevents:if stops1=1 then stops1=0: exit sub
	wend
	
	'search files in current subdirectory
	Fn$=dir$(SubDir(i)+mask$,faAnyFile-faDirectory) ':-)
	while Fn$ <>""
		if  Fn$<> "." and Fn$<> ".."  then 'and FileRec.Size <>0'
			inc NumFiles
			if NumFiles=ArrNumFil then ArrNumFil=ArrNumFil+300: redim FileNames(ArrNumFil) as string:'print "redim FileNames"
			FileNames(NumFiles)=SubDir(i)+Fn$
			'print "FileNames(",NumFiles,")=" ,FileNames(NumFiles)
			
		else
		end if
		Fn$=dir$
	wend
next i

if adddir>0 then
	NSD1=NSD2+1       
	NSD2=NSD2+adddir  
	adddir=0
	goto sss1 'repeat with new sub level 
else
end if

' got subdirs list in SubDir(i) array and file list with full path in FileNames(j)
' now create subdirs structure with new path

for i1=0 to i-1
	NewSubDir$=SubDir(i1)-DirSrc$
	NewSubDir$=DirDst$+NewSubDir$
	MKSubDir (NewSubDir$)
next i1

for j=1 to NumFiles
	FileSrc.Open(FileNames(j), fmOpenRead) 
	if FileSrc.size=0 then FileSrc.close: goto nextj1
	
	NewFileName$=FileNames(j)-DirSrc$
	NewFileName$=DirDst$+NewFileName$
	'print "NewFileName$=" ,NewFileName$
	FileDst.Open(NewFileName$, fmCreate) 
	FileDst.CopyFrom  (FileSrc, 0)''
	FileSrc.close''
	FileDst.close
	nextj1:
next j

end sub

'-- *****************************************************'
function fSubDirCopy (DirSrc$, DirDst$, mask$) as long '- -----------------------------------'
'Andrew Shelkovenko dec 2003
'Copy DirSrc$ directory with full subdir structure and files (by mask$) to DirDst$
'DiaMsg$="Начало копирования.."

dim FileSrc as QFileStream
dim FileDst as QFileStream

result=-1
'Index=0
NumFiles=0
defint nsd1, nsd2
defstr mask
nsd1=0:nsd2=0
NumDir=0
ArrNumDir=500
dim SubDir(500) as string

ArrNumFil=500
dim FileNames (500) as string
mask="*.*"
if right$(DirSrc$,1)<> BkSl then DirSrc$=DirSrc$+BkSl
'print "DirSrc$="; DirSrc$
if right$(DirDst$,1)<> BkSl then DirDst$=DirDst$+BkSl
'print "DirDst$="; DirDst$

SubDir(0)=DirSrc$

sss1:
for i=NSD1 to Nsd2 'current level sudirs'
	'print "374 SubDir(",i,")=",SubDir(i)
	SubDirname$=dir$(SubDir(i)+mask, faDirectory)
	
	while    SubDirname$ <>""
		if FileRec.Size =0 and SubDirname$<> "." and SubDirname$<> ".." then ''
			inc adddir
			inc NumDir 'add subdir'
			if NumDir=ArrNumDir then ArrNumDir=ArrNumDir+300: redim SubDir(ArrNumDir) as string:'DiaMsg$="‘Є ­ЁагҐ¬ Ї®¤¤ЁаҐЄв®аЁЁ "+SubDir(NumDir) 'SubDirname$
			SubDir(NumDir)=SubDir(i)+SubDirname$+"\"
			'print "383 SubDir(", NumDir, ")=",SubDir(NumDir)
			'DiaMsg$="Сканируем поддиректории "+SubDir(NumDir) 'SubDirname$
		else
		end if
		SubDirname$=dir$
		doevents:if stops1=1 then stops1=0: exit function
	wend
	
	'DiaMsg$="Всего поддиректорий " +str$(NumDir)
	
	'search files in current subdirectory
	Fn$=dir$(SubDir(i)+mask$,faAnyFile-faDirectory) ':-)
	while Fn$ <>""
		if  Fn$<> "." and Fn$<> ".."  then 'and FileRec.Size <>0'
			inc NumFiles
			if NumFiles=ArrNumFil then ArrNumFil=ArrNumFil+300: redim FileNames(ArrNumFil) as string:'DiaMsg$=str$(NumFiles)
			FileNames(NumFiles)=SubDir(i)+Fn$
			'print "FileNames(",NumFiles,")=" ,FileNames(NumFiles)
			'DiaMsg$="Сканируем файлы "+FileNames(NumFiles)
		else
		end if
		Fn$=dir$
	wend
next i
result=-2

if adddir>0 then
	NSD1=NSD2+1       
	NSD2=NSD2+adddir  
	adddir=0
	goto sss1 'repeat with new sub level 
else
end if

' got subdirs list in SubDir(i) array and file list with full path in FileNames(j)
' now create subdirs structure with new path

'DiaMsg$="Создаем директории... "
for i1=0 to i-1
	NewSubDir$=SubDir(i1)-DirSrc$
	NewSubDir$=DirDst$+NewSubDir$
	MKSubDir (NewSubDir$)
	'DiaMsg$="Создали директорию "+NewSubDir$
next i1
result=-3

'DiaMsg$="Копируем файлы..."

for j=1 to NumFiles
	'DiaMsg$="Пытаемся открыть файл "+FileNames(j)
	'DiaMsg$="Try to open file "+NewFileName$
	
	FileSrc.Open(FileNames(j), fmOpenRead) 
	'DiaMsg$="Открыли "+FileNames(j) +" размер=" +str$( FileSrc.size)
	'print "opened " +FileNames(j)
	
	'print "FileSrc.size=" ,FileSrc.size
	
	
	if FileSrc.size=0 then 
		FileSrc.close: 
		'print "zerosize closed " +FileNames(j): 
		goto nextj
	end if
	
	NewFileName1$=FileNames(j)-DirSrc$
	NewFileName$=DirDst$+NewFileName1$
	
	'print "NewFileName$=" ,NewFileName$
	'DiaMsg$="Пытаемся создать файл "+NewFileName1$
	'DiaMsg$="Try to create file "+NewFileName$
	
	FileDst.Open(NewFileName$, fmCreate) 
	'DiaMsg$="Пытаемся скопировать файл " +FileNames(j) +" в "+NewFileName1$
	'print "DiaMsg$=" ,DiaMsg$
	'DiaMsg$="Try to copy "
	
	FileDst.CopyFrom  (FileSrc, 0)''
	FileSrc.close''
	FileDst.close
	'DiaMsg$="Copied "+str$(j) + " from "+ str$(NumFiles)+" = "+ NewFileName$
	DiaMsg$="Скопировано файлов "+str$(j)'FileNames(j) '+" в "+NewFileName$
	
	nextj:
	doevents
next j

result=j-1
'DiaMsg$="Всего скопировано файлов"+ str$(result) + " из "+ str$(NumFiles)

end function

'-- ***********************************************************************'
function DirCopy (DirSrc$, DirDst$, mask$) as long   
'print "DirCopy mask$=" ,mask$
'print "DirCopy DirDst$=" ,DirDst$
'print "DirCopy DirSrc$=" ,DirSrc$
'Andrew Shelkovenko dec 2003
'Copy files (by mask$) from DirSrc$ to DirDst$
result=0
dim FileSrc as QFileStream
dim FileDst as QFileStream
defint NumFIles
NumFIles=0
'MKDIR DirDst$
rz=MKSubDir (DirDst$)
if right$(DirSrc$,1)<>"\" then DirSrc$=DirSrc$+"\"

if direxists(DirDst$) =0 then 
	showmessage ("DirCopy Error: Can't create folder "+DirDst$)
	exit function
end if 
'print "DirCopy DirSrc$+mask$=" ,DirSrc$+mask$

FileName$ = DIR$(DirSrc$+mask$, 0) '-- Get first file 
'print "DirCopy FileName$=" ,FileName$

while    FileName$ <>""
	FileSrc.Open(DirSrc$+filename$, fmOpenRead) 
	FileDst.Open(DirDst$ +"\"+filename$, fmCreate) 
	FileDst.CopyFrom  (FileSrc, 0)
	FileSrc.close
	FileDst.close
	FileName$ = DIR$ '-- Get next file
	inc NumFIles
wend
'print "DirCopy copied= "+str$(NumFIles) +" files
result=NumFIles
end function

'-- ***********************************************************************'
sub FileCopy (FileSrc$, FileDst$) '- -----------------------------------'
'Andrew Shelkovenko dec 2003
'Copy FileSrc$ to FileDst$
' if path dest is not exists - create it.

if FileSrc$=FileDst$ then 
	ShowMessage ("FileCopy:Can't copy file onto itself - "+ FileDst$)
	exit sub
end if

dim FileSrc as QFileStream
dim FileDst as QFileStream

dr$=StripPath (FileDst$) 
'print "dr$=" ,dr$

'MKDIR dr$ 'StripPath (FileDst$)

if dr$<>"" then
	MKSubDir dr$
	if DIREXISTS(dr$ ) =0 then showmessage ("FileCopy Can't create directory "+dr$ ): 'exit sub
end if

FileSrc.Open(FileSrc$, fmOpenRead) 
FileDst.Open(FileDst$, fmCreate) 

FileDst.CopyFrom  (FileSrc, 0)
FileSrc.close
FileDst.close
'print "FileCopy (";FileSrc$, FileDst$;") done" 
end sub

'*****************************************
function fFileCopy (FileSrc$, FileDst$) '- -----------------------------------'
'Andrew Shelkovenko dec 2003
'Copy FileSrc$ to FileDst$
' if path dest is not exists - create it.
result=0
	if Filesize(FileSrc$)=0 then exit sub

if FileSrc$=FileDst$ then 
	'ShowMessage ("FileCopy:Can't copy file onto itself - "+ FileDst$)
	result=-1
	exit sub
end if

dim FileSrc as QFileStream
dim FileDst as QFileStream

dr$=StripPath (FileDst$) 

if dr$<>"" then
	'MKSubDir dr$
	if DIREXISTS(dr$ ) =0 then result=-2: exit sub
	''showmessage ("FileCopy Can't create directory "+dr$ ): 'exit sub
end if
result=-3
FileSrc.Open(FileSrc$, fmOpenRead) 
result=-4
FileDst.Open(FileDst$, fmCreate) 

FileDst.CopyFrom  (FileSrc, 0)
result=-5
FileSrc.close
FileDst.close
'print "FileCopy (";FileSrc$, FileDst$;") done" 
result=1

end sub


'-- ***********************************************************************'
sub KillFiles (FileName$) 
'Andrew Shelkovenko  diakin@narod.ru  apr 2004
'Kill files in FileName$
' for example KillFiles "C:\BAS\RAPIDQ\tmp\*.tmp"

FName$ =StripPath (FileName$)+ DIR$(FileName$, 0 ) '-- Get first file
'print " -------------------  FName$=" ,FName$

while STRIPFILENAME (FName$) <>""
	kill FName$
	'print "killed FName$=" ,FName$
	
	if fileexists (StripPath (FileName$)+FName$)>0 then ShowMessage ("KillFiles Can't kill file "+FName$)
	'print "Can't kill file "+FName$
	
	FName$ = StripPath (FileName$)+DIR$ '-- Get next file
wend
end sub

'-- *****************************************************'
sub KillSubDir (DirSrc$, mask$) '- -----------------------------------'

'print "-- KillSubDir DirSrc$=",DirSrc$

'Andrew Shelkovenko diakin@narod.ru may 2004
'Kill files by mask$ in all subdirs in DirSrc$ directory and kill all empty subdirs and DirSrc$ (if empty)
'So.. if mask$="*.*" then  kill DirSrc$ with all subdirs and files

dim FileSrc as QFileStream

'Index=0
NumFiles=0
defint nsd1, nsd2
defstr mask
nsd1=0:nsd2=0
NumDir=0
ArrNumDir=500
dim SubDir(500) as string

ArrNumFil=500
dim FileNames (500) as string
mask="*.*" 
if right$(DirSrc$,1)<>BkSl then SubDir(0)=DirSrc$+BkSl else SubDir(0)=DirSrc$

'print "BkSl=" ,BkSl

'print "SubDir(0)=" ,SubDir(0)

s1:
for i=NSD1 to Nsd2 'current level sudirs'
	'print "KillSubDir SubDir(",i,")=",SubDir(i)
	SubDirname$=dir$(SubDir(i)+mask, faDirectory)
	'print "-- KillSubDir SubDirname$=",SubDirname$ 
	while    SubDirname$ <>""
		if FileRec.Size =0 and SubDirname$<> "." and SubDirname$<> ".." then ''
			inc adddir
			inc NumDir 'add subdir'
			if NumDir=ArrNumDir then ArrNumDir=ArrNumDir+300: redim SubDir(ArrNumDir) as string
			subDir(NumDir)=SubDir(i)+SubDirname$+"\"
			'print "--KillSubDir SubDir(", NumDir, ")=",SubDir(NumDir)
		else
		end if
		SubDirname$=dir$
		doevents:if stops1=1 then stops1=0: exit sub
	wend
	
	'search files in current subdirectory
	Fn$=dir$(SubDir(i)+mask$,faAnyFile-faDirectory) ':-)
	while Fn$ <>""
		if  Fn$<> "." and Fn$<> ".."  then 'and FileRec.Size <>0'
			kill SubDir(i)+Fn$
			'print "-- KillSubDir kill ",SubDir(i)+Fn$
		else
		end if
		Fn$=dir$
	wend
next i

if adddir>0 then
	NSD1=NSD2+1       
	NSD2=NSD2+adddir  
	adddir=0
	goto s1 'repeat with new sub level 
else
end if


for i1=i-1 to 1 step -1 
	RMDIR SubDir(i1)
	'print "-- KillSubDir RMDIR SubDir(",i1,")=", SubDir(i1)
next i1

END SUB

'-- ***********************************************************************'
SUB io2Rnd (fsrc$, fdst$)
'--------------------------------
'convert text file with single value strings to binary
' for example
'17.78091
'16.64166

'fsrc$ - source file  fdst$ - dest. file
'data type - single

'CONST fmCreate = 65535
'CONST fmOpenRead = 0
'CONST fmOpenWrite = 1
'CONST fmOpenReadWrite = 2

dim FileSourse as QFileStream
dim FileDest as QFileStream
defsng ValSrc

FileSourse.Open (fsrc$, 2 )'fmOpenReadWrite'
FileDest.Open   (fdst$, 65535 )  'fmOpenReadWrite'

WHILE NOT FileSourse.EOF
	ValSrc$=FileSourse.ReadLine : 'print "ValSrc$=" ,ValSrc$
	ValSrc=val(ValSrc$) :         'print "ValSrc=" ,ValSrc
	FileDest.Write (ValSrc)
wend

FileSourse.CLOSE  
FileDest.CLOSE 

END SUB


'-- ***********************************************************************'
SUB Rnd2io (fsrc$, fdst$)
'--------------------------------
'convert  binary file with single type value data to  text file with single type value strings
' i.e
'17.78091
'16.64166
'19.87037

'CONST fmCreate = 65535
'CONST fmOpenRead = 0
'CONST fmOpenWrite = 1
'CONST fmOpenReadWrite = 2

'CONST Num_BYTE = 1 
'CONST Num_SHORT = 2
'CONST Num_WORD = 3
'CONST Num_LONG = 4
'CONST Num_DWORD = 5
'CONST Num_SINGLE = 6
'CONST Num_DOUBLE = 8

dim FileSourse as QFileStream
dim FileDest as QFileStream

defsng ValSrc

FileSourse.Open (fsrc$, 2 )        'fmOpenReadWrite'
FileDest.Open   (fdst$, 65535 )    'fmOpenCreate'

ie = FileSourse.size/4: 'print "ie=" ,ie

for i=0 to ie-1
	ValSrc=FileSourse.ReadNum(6) :'print "ValSrc=" ,ValSrc
	ValSrc$=str$(ValSrc):   'print "ValSrc$=" ,ValSrc$
	FileDest.WriteLine (ValSrc$)
next i

FileSourse.CLOSE  
FileDest.CLOSE 

END SUB

'-- ***********************************************************************'
SUB io2RndPV (fsrc$, fdst$)
'--------------------------------
'convert text file with single value strings to binary
' for example
'17.78091
'16.64166

'fsrc$ - source file  fdst$ - dest. file
'data type - single

'CONST fmCreate = 65535
'CONST fmOpenRead = 0
'CONST fmOpenWrite = 1
'CONST fmOpenReadWrite = 2

dim FileSourse as QFileStream
dim FileDest as QFileStream
defsng ValSrc

FileSourse.Open (fsrc$, 2 )'fmOpenReadWrite'
FileDest.Open   (fdst$, 65535 )  'fmOpenReadWrite'

WHILE NOT FileSourse.EOF
	ValSrc$=FileSourse.ReadLine : 'print "ValSrc$=" ,ValSrc$
	ValSrc=val(ValSrc$) :         'print "ValSrc=" ,ValSrc
	FileDest.Write (ValSrc)
wend

FileSourse.CLOSE  
FileDest.CLOSE 

END SUB


'-- ***********************************************************************'
SUB io2RndInter (io$, rndf$, LostP)
'convert text file with the two-fields per string "point,data" format
' to binary format with interpolation of missed points
'---- for example -----
' 0,17.78091 
' 1,16.64166
'     points 2,3 is missed
' 4,19.87037  
' 5,16.64123 
'------------------------------------
'io$   - source text file
'rndf$ - destination binary file
'LostP - return number of missed points (use @LostP )
' call io2RndInter (io$, rndf$, @LostP)
'------------------------------------
dim io2RndFile2 as QfileStream
dim io2Rndtmp as QfileStream
dim io2RndList as QSTRINGLIST 
dim ioNumPnt as int
dim i0 as int

defsng pnt
if fileexists (io$)=0 then showmessage ("io2RndInter File not found "+io$):exit sub
if FileSize(io$)<1 then showmessage ("io2RndInter Zero size file "+io$):LostP=-99:exit sub

io2RndList.LoadFromFile (io$)
ArgName$=FullPathNoExt(rndf$)+"Arg"+STRIPFILEEXT(rndf$)
io2RndFile2.Open(rndf$, fmCreate)   
io2Rndtmp.Open(ArgName$, fmCreate)   

pntOld = 0: AdatOld! = 0: LostP = 1:j=0: i0=0
i0=val(Field$(io2RndList.Item(0),",", 1))

for k=0 to io2RndList.ItemCount-1
	pnt=val(Field$(io2RndList.Item(k),",", 1))
	Adat!=val( Field$(io2RndList.Item(k),",", 2) )
	IF pnt = i0 THEN
		io2RndFile2.WriteNum(Adat!,Num_SINGLE )
		'io2Rndtmp.WriteLine (str$(pnt)+" "+str$(Adat!) )
		io2Rndtmp.WriteNum (pnt,Num_SINGLE)
		pntOld = pnt: AdatOld! = Adat!
	elseif pnt < i0 then
		io2RndFile2.WriteNum(Adat!,Num_SINGLE )
		'io2Rndtmp.WriteLine (str$(i0)+" "+str$(Adat!) )
		io2Rndtmp.WriteNum (pnt,Num_SINGLE)
		pntOld = i0: AdatOld! = Adat!
	else
		IF pnt <> pntOld THEN ki! = (Adat! - AdatOld!) / (pnt - pntOld) ELSE GOTO ex1
		FOR j = i0 TO pnt - 1
			LostP = LostP + 1
			Adat1! = AdatOld! + ki!
			io2RndFile2.WriteNum(Adat1!,Num_SINGLE )
			'io2Rndtmp.WriteLine (str$(j)+" "+str$(Adat1!) )
			io2Rndtmp.WriteNum (j,Num_SINGLE)
			AdatOld! = Adat1!
		NEXT j
		AdatOld! = Adat!: pntOld = pnt:
		'io2Rndtmp.WriteLine (str$(pnt)+" "+str$(Adat!) )
		io2Rndtmp.WriteNum (pnt,Num_SINGLE)
		io2RndFile2.WriteNum(Adat!,Num_SINGLE )
		i0 = j
	END IF
	ex1:
	inc i0
next k
io2RndFile2.close
io2Rndtmp.close
'print "io2Rnd completed"
END SUB

'-- ***********************************************************************'
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
dim io2RndArg as QfileStream
dim io2io as QfileStream


dim io2RndList as QSTRINGLIST 
dim ioNumPnt as int
dim i0 as int
dim pnt as single
needtoWrite=0

if fileexists (io$)=0 then showmessage ("io2RndInter File not found "+io$): exit sub
if FileSize(io$)<1 then showmessage ("io2RndInter Zero size file "+io$): LostP=-99: exit sub

io2RndList.LoadFromFile (io$)
io2RndList.text=replacesubstr$(io2RndList.text,crlf+crlf,crlf)
ArgName$=FullPathNoExt(rndf$)+"Arg"+STRIPFILEEXT(rndf$)
ioutName$=FullPathNoExt(rndf$)+".io2"
'print"ArgName$=";ArgName$

io2RndFile2.Open(rndf$, fmCreate)   
io2RndArg.Open(ArgName$, fmCreate)   
io2io.Open(ioutName$, fmCreate)   

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
			io2RndArg.Position=io2RndArg.Position-4
			io2RndFile2.WriteNum(AdatOld!,Num_SINGLE ) ' усредняем
			io2RndArg.WriteNum (pntOld,Num_SINGLE)
			io2io.WriteLine (str$(pntOld)+","+str$(AdatOld!))
			
			'call  AddClrString ("pnt old="+str$(pntold)+" "+str$(AdatOld!) , clred, LogEdit)
			needtoWrite=0
		end if
		io2RndFile2.WriteNum(Adat!,Num_SINGLE )
		io2RndArg.WriteNum (pnt,Num_SINGLE)
		io2io.WriteLine (str$(pnt)+","+str$(Adat!))
		
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
					io2RndArg.WriteNum (j,Num_SINGLE)
					io2io.WriteLine (str$(j)+","+str$(Adat!))
					AdatOld! = Adat1!
				NEXT j
				AdatOld! = Adat!: pntOld = pnt:
				'io2RndArg.WriteLine (str$(pnt)+" "+str$(Adat!) )
				io2RndArg.WriteNum (pnt,Num_SINGLE)
				io2RndFile2.WriteNum(Adat!,Num_SINGLE )
				io2io.WriteLine (str$(pnt)+","+str$(Adat!))
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
					io2RndArg.WriteNum (j,Num_SINGLE)
					io2io.WriteLine (str$(j)+","+str$(Adat1!))
					AdatOld! = Adat1!
				NEXT j
				AdatOld! = Adat!: pntOld = pnt:
				'io2RndArg.WriteLine (str$(pnt)+" "+str$(Adat!) )
				io2RndArg.WriteNum (pnt,Num_SINGLE)
				io2RndFile2.WriteNum(Adat!,Num_SINGLE )
				io2io.WriteLine (str$(pnt)+","+str$(Adat!))
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
io2RndArg.close
io2io.close
END SUB

'***********************************************
sub ioAverage (io$, outf$, bpnt as integer)
' процедура обработки файла формата точка, данные, когда на каждую точку приходится несколько отсчетов
dim InputList as QSTRINGLIST 
dim OutPutList as QSTRINGLIST 
InputList.clear
OutPutList.clear
if fileExists (io$)> 0 and FileSize(io$)>0 then
	InputList.LoadFromFile (io$)
else
	ShowMessage ("File "+io$ +" not found")
	exit sub
end if

if InputList.ItemCount<5 then 
	ShowMessage ("Data not found")
	exit sub
end if 

pntOld=1
newpnt=1
ep=0


for k=0 to InputList.ItemCount-1
	a$=InputList.item (k)
	pnt=val(Field$(InputList.Item(k),",", 1)):
	Adat!=val( Field$(InputList.Item(k),",", 2)):
	
	if k=0 then pntOld=pnt:bpnt=pnt
	
	if pnt=pntOld then
		Aver=Aver+Adat!:'RQDebug("строка 37",0,"k", k, "pnt",pnt,"Adat!",Adat!,"ep",ep,"Aver",Aver)
		inc ep
	else
		if ep=0 then ep=1
		Aver=Aver/ep:'RQDebug("строка 41",0,"k", k, "pnt",pnt,"Adat!",Adat!,"ep",ep,"Aver",Aver)
		OutPutList.AddItems  str$(pntOld)+","+str$(Aver)
		inc newpnt
		'RQDebug("k", k, "pnt",pnt,"Adat!",Adat!,"Aver",Aver)
		Aver=Adat!
		pntOld=pnt
		ep=1
	end if
	
next k
Aver=Aver/ep:'RQDebug("строка 41",0,"k", k, "pnt",pnt,"Adat!",Adat!,"ep",ep,"Aver",Aver)
OutPutList.AddItems  str$(pntOld)+","+str$(Aver)

OutPutList.SaveToFile (outf$)
end sub

'-------------------------------------------------------------------'
'-- ***********************************************************************'
function ChDirOEM (PathDst$) as short 
'print "ChDirOEM PathDst$=" ,PathDst$
result=0
dim PathDst1$ as string
PathDst1$=string$(len(PathDst$),"a") 
chartooem PathDst$,PathDst1$ 
'print "ChDirOEM PathDst$=" ,PathDst$
'print "ChDirOEM PathDst1$=" ,PathDst1$

CHDIR  PathDst1$ 
result=1
end function

'-------------------------------------------------------------------'
'-- ***********************************************************************'
function MkDirOEM (PathDst$) as short
result=0
dim PathDst1$ as string
'print "MkDirOEM PathDst$=" ,PathDst$
PathDst1$=string$(len(PathDst$),"a") 
chartooem PathDst$,PathDst1$ 
'print "MkDirOEM PathDst$=" ,PathDst$
'print "MkDirOEM PathDst1$=" ,PathDst1$
MkDIR  PathDst1$ 
result=1
end function

