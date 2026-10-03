
$DEFINE FILE_ATTRIBUTE_READONLY  &H1
$DEFINE FILE_ATTRIBUTE_HIDDEN  &H2
$DEFINE FILE_ATTRIBUTE_SYSTEM  &H4
$DEFINE FILE_ATTRIBUTE_DIRECTORY  &H10
$DEFINE FILE_ATTRIBUTE_ARCHIVE  &H20
$DEFINE FILE_ATTRIBUTE_NORMAL  &H80
$DEFINE FILE_ATTRIBUTE_TEMPORARY  &H100
$DEFINE FILE_ATTRIBUTE_COMPRESSED  &H800

$DEFINE GENERIC_READ  &H80000000
$DEFINE FILE_SHARE_READ  &H1
$DEFINE OPEN_EXISTING  3
$DEFINE FILE_TYPE_CHAR  &H2
$DEFINE FILE_TYPE_DISK  &H1
$DEFINE FILE_TYPE_PIPE  &H3
$DEFINE FILE_TYPE_UNKNOWN  &H0



Type SECURITY_ATTRIBUTES
nLength As Long
lpSecurityDescriptor As Long
bInheritHandle As Long
End Type

'Declare Function GetFileSizeEx Lib "kernel32" (ByVal hFile As Long, lpFileSize As Currency) As Boolean

Declare Function GetFileAttributes Lib "kernel32" Alias "GetFileAttributesA"_
(ByVal lpFileName As String) As Long
Declare Function SetFileAttributes Lib "kernel32" Alias "SetFileAttributesA"_
(ByVal lpFileName As String, ByVal dwFileAttributes As Long) As Long

Declare Function CreateDirectory Lib "kernel32" Alias "CreateDirectoryA" _
(ByVal lpPathName As String, lpSecurityAttributes As SECURITY_ATTRIBUTES) As Long

fMsg35$="ReadOnly or hidden or system file! Change anyway?"



'---------- wininet ------------------
Const scUserAgent = "Test program"
Const INTERNET_OPEN_TYPE_DIRECT = 1
Const INTERNET_OPEN_TYPE_PROXY = 3
Const INTERNET_FLAG_RELOAD = &H80000000

Declare Function InternetOpen Lib "wininet" Alias "InternetOpenA" (_
sAgent As String,_
lAccessType As Long,  _
sProxyName As String,  _
sProxyBypass As String,  _
lFlags As Long_
) As Long

Declare Function InternetCloseHandle Lib "wininet"  Alias "InternetCloseHandle"  ( hInet As Long) As Integer

Declare Function InternetReadFile Lib "wininet"  Alias "InternetReadFile" ( _
hFile As Long,  _
byref sBuffer As String,  _
lNumBytesToRead As Long, _
byref lNumberOfBytesRead As Long_
) As Integer

Declare Function InternetOpenUrl Lib "wininet" Alias "InternetOpenUrlA" ( _
hInternetSession As Long,  _
lpszUrl As String,  _
lpszHeaders As String,  _
dwHeadersLength As Long,  _
dwFlags As Long,  _
dwContext As Long) As Long
'-------------------------------------


'# QUOTE : Returns a quoted string
function Quote (StringToQuote as string) as string
StringToQuote =  chr$(34) + StringToQuote + chr$(34)
result = replacesubstr$(stringtoquote, chr$(34) + chr$(34), chr$(34))
end function

'===============================================================================
'# STRIPPATH : Returns file path (without file name)
Function StripPath (fullname as string) as string
'print
'print "1 StripPath fullname=";fullname

result = left$(fullname, rinstr(fullname, "\"))

'print "2 StripPath fullname=";fullname
'print

end function

'===============================================================================
'# STRIPFILENAME : Returns file name (without path)
Function StripFileName (fullname as string) as string
result = right$(fullname, len(fullname) - rinstr(fullname, "\"))
end function


'===============================================================================
'# GetFileNameNoPath : Returns file name (without path)
Function GetFileNameNoPath (fullname as string) as string
result = right$(fullname, len(fullname) - rinstr(fullname, "\"))
end function



'===============================================================================
'# STRIPFILEEXT : Returns file extension (like ".exe", ".html" etc.)
Function StripFileExt (fullname as string) as string
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
'*****************************************
function bsPath (fullname as string) as string
'backslashedPath
'fullname = replacesubstr$(fullname, "\\", "\")
result = replacesubstr$(fullname, "/", "\")
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

'if fileexists (FileName)>0 then 
if	fileStr.open (FileName,0)=-1  then 'fmOpenRead 
	
	result=fileStr.size
	fileStr.close
else
	result=-1
end if

END FUNCTION
'-- *****************************************************'
FUNCTION SaveString(ss$ as STRING ,FileName as STRING  ) AS integer
result=0

if FileName="" then showmessage ("FUNCTION SaveString. Wrong FileName="+FileName):exit function
DIM fileStr as QFileStream

if fileStr.open (FileName,65535 )=-1 then 'fmCreate'
	result=-1
	FileStr.WriteBinStr(ss$, len(ss$)) 
	FileStr.Close
	result=1
else
	'ShowMessage ("SaveString error: Access denied "+FileName)
	result=-2
end if
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
	if fileStr.open (FileName,65535 )=-1 then 'fmCreate'
		result=-1
		FileStr.WriteBinStr(ss$, len(ss$)) 
		FileStr.Close
	else
		'ShowMessage ("SaveStringEx error: Access denied "+FileName)
		result=-2
		exit function
	end if
	
elseif mode=1 or mode=2 then
	if fileexists(FileName)=0 then md=65535:crl="" else md=2:crl$=crlf 'showmessage ("FUNCTION SaveString. Can't open File="+FileName):exit function
	if fileStr.open (FileName,md )=-1 then  'fmOpenReadWrite = 2
		fileStr.Position=fileStr.size
		result=-1
		if mode=1 then FileStr.WriteStr(ss$, len(ss$)) else FileStr.WriteStr(crl$+ss$, len(crl$+ss$))
		FileStr.Close
	else
		'ShowMessage ("SaveStringEx error: Access denied "+FileName)
		result=-2
		exit function
		
	end if
else
end if

result=1

END FUNCTION
'-- *****************************************************'
FUNCTION CheckFileWr (FileName as STRING  ) AS long
result=0
DIM fileStr as QFileStream
'fmOpenWrite = 1
if fileStr.open (FileName,1 )=-1 then
	result=-1
	FileStr.Close
end if

END FUNCTION

'******************************'
FUNCTION LoadString(FileName as STRING  ) AS string
DIM fileStr as QFileStream
result="0"
'fmOpenRead = 0
if fileStr.open (FileName,0 )=-1 then'fmCreate'
	result="-1"
	result=FileStr.ReadBinStr( FileStr.size) 
	FileStr.Close
	'result=1
end if

END FUNCTION

'-- *****************************************************'
FUNCTION LoadBinString(FileName as STRING , n as long ) AS string
'print"FileName=";FileName
DIM fileStr as QFileStream
result="0"
res$="0"
'print"res1$=";res$
'fmOpenRead = 0
if fileStr.open (FileName,0 )=-1 then'fmRead'
	if n=-1 then n=FileStr.size
	if n>FileStr.size then n=FileStr.size
	result="-1"
	res$="-1"
	result=FileStr.ReadBinStr( n) 
	FileStr.Close
	'result=1
end if
'print"res2$=";res$
END FUNCTION

'-- *****************************************************'
FUNCTION LoadString1(FileName as STRING  ) AS string
DIM fileStr as QFileStream
result="0"
'fmOpenRead = 0
if fileStr.open (FileName,0 )=-1 then'fmRead'
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
	if FileSrc.size=0 then FileSrc.close: goto SubDirCopynextj1
	
	NewFileName$=FileNames(j)-DirSrc$
	NewFileName$=DirDst$+NewFileName$
	'print "NewFileName$=" ,NewFileName$
	if FileDst.Open(NewFileName$, fmCreate) =-1 then
		FileDst.CopyFrom  (FileSrc, 0)''
		FileSrc.close''
		FileDst.close
	else
		ShowMessage ("SubDirCopy error: Access denied "+NewFileName$)
		
	end if
	SubDirCopynextj1:
next j

end sub

'-- *****************************************************'
function fSubDirCopy (DirSrc$, DirDst$, mask$) as long '- -----------------------------------'
'Andrew Shelkovenko dec 2003
'Copy DirSrc$ directory with full subdir structure and files (by mask$) to DirDst$
'DiaMsg$="Начало копирования.."

dim FileSrc as QFileStream
dim FileDst as QFileStream
dim i as long

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

SubDir(0)=DirSrc$

sss1:
for i=NSD1 to Nsd2 'current level sudirs'
	SubDirname$=dir$(SubDir(i)+mask, faDirectory)
	while    SubDirname$ <>""
		if FileRec.Size =0 and SubDirname$<> "." and SubDirname$<> ".." then ''
			attr=GetFileAttributes(SubDir(d2)+SubDirname$) 
			If (attr And FILE_ATTRIBUTE_DIRECTORY)=0 Then goto fSubDirCopynodir1
			inc adddir
			inc NumDir 'add subdir'
			if NumDir=ArrNumDir then ArrNumDir=ArrNumDir+300: redim SubDir(ArrNumDir) as string:'DiaMsg$="‘Є ­ЁагҐ¬ Ї®¤¤ЁаҐЄв®аЁЁ "+SubDir(NumDir) 'SubDirname$
			SubDir(NumDir)=SubDir(i)+SubDirname$+"\"
		else
		end if
		fSubDirCopynodir1:
		SubDirname$=dir$
		doevents:if stops1=1 then stops1=0: exit function
	wend
	
	'DiaMsg$="Всего поддиректорий " +str$(NumDir)
	
	'search files in current subdirectory
	Fn$=dir$(SubDir(i)+mask$,faAnyFile-faDirectory) ':-)
	attr=GetFileAttributes(SubDir(d2)+Fn$) 
	
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

for i1=0 to i-1
	NewSubDir$=SubDir(i1)-DirSrc$
	NewSubDir$=DirDst$+NewSubDir$
	MKSubDir (NewSubDir$)
next i1
result=-3

for j=1 to NumFiles
	
	FileSrc.Open(FileNames(j), fmOpenRead) 
	if FileSrc.size=0 then 
		FileSrc.close: 
		goto fSubDirCopynextj
	end if
	
	NewFileName1$=FileNames(j)-DirSrc$
	NewFileName$=DirDst$+NewFileName1$
	
	if FileDst.Open(NewFileName$, fmCreate) =-1 then
		
		FileDst.CopyFrom  (FileSrc, 0)''
		FileSrc.close''
		FileDst.close
	else
		ShowMessage ("fSubDirCopy error: Access denied "+NewFileName$)
		
	end if
	
	fSubDirCopynextj:
	doevents
next j

result=j-1

end function

fdefaultChkAttr=0
fAttrChg=0

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
if right$(DirDst$,1)<>"\" then DirDst$=DirDst$+"\"

if direxists(DirDst$) =0 then 
	showmessage ("DirCopy Error: Can't create folder "+DirDst$)
	exit function
end if 

FileName$ = DIR$(DirSrc$+mask$, 0) '-- Get first file 

while    FileName$ <>""
	if fileexists(DirDst$+FileName$) =0 then goto DCcreate:
	fOldfa=GetFileAttributes (DirDst$+FileName$) 
	fzas=FILE_ATTRIBUTE_READONLY or FILE_ATTRIBUTE_HIDDEN or FILE_ATTRIBUTE_SYSTEM
	
	if (fOldfa and fzas) >0 then
		if fdefaultChkAttr=0 then 
			frzm24=MessageDlg("DirCopy "+fMsg35$+"  "+DirDst$+FileName$, mtWarning, mbYes OR mbNo OR mbAll, 0)
			IF rzm24 = mrNo THEN
				fAttrChg=0
				goto DirCopyExitSub:
			elseif frzm24 = mrYes then 
				SetFileAttributes (DirDst$+FileName$,FILE_ATTRIBUTE_NORMAL)
				fAttrChg=1
			elseif frzm24 = mrAll then 
				fdefaultChkAttr=1
				SetFileAttributes (DirDst$+FileName$,FILE_ATTRIBUTE_NORMAL) 
				fAttrChg=1
			END IF
			
		else
			SetFileAttributes (DirDst$+FileName$,FILE_ATTRIBUTE_NORMAL) 
			fAttrChg=1
		end if
	else
		
	end if
	DCcreate:
	FileSrc.Open(DirSrc$+filename$, fmOpenRead) 
	if FileDst.Open(DirDst$ +filename$, fmCreate) =-1 then
		FileDst.CopyFrom  (FileSrc, 0)
		FileDst.close
	else
		'result=0
		ShowMessage ("DirCopy error: Access denied "+DirDst$ +filename$)
		
	end if
	FileSrc.close
	SetFileAttributes (DirDst$+FileName$,fOldfa) 

	FileName$ = DIR$ '-- Get next file
	inc NumFIles
	DiaMsg$="DirCopy copied= "+str$(NumFIles) +" files"
'print"DiaMsg$=";DiaMsg$
doevents
wend
'print "DirCopy copied= "+str$(NumFIles) +" files
result=NumFIles
DirCopyExitSub:
end function

'-- ***********************************************************************'
sub FileCopy (FileSrc$, FileDst$) '- -----------------------------------'
'Andrew Shelkovenko dec 2003
'Copy FileSrc$ to FileDst$
' if path dest is not exists - create it.

dim FileSrc as QFileStream
dim FileDst as QFileStream

dr$=StripPath (FileDst$) 
'print "dr$=" ,dr$

'MKDIR dr$ 'StripPath (FileDst$)

if dr$<>"" then
	MKSubDir dr$
	if DIREXISTS(dr$ ) =0 then showmessage ("FileCopy Can't create directory "+dr$ ): 'exit sub
end if

if FileSrc.Open(FileSrc$, fmOpenRead) =-1 then
	if FileDst.Open(FileDst$, fmCreate) =-1 then
		FileDst.CopyFrom  (FileSrc, 0)

		FileDst.close
		FileSrc.close
	else
		'print  "Can't create "+FileDst$
	end if
else
	'print  "File not found "+FileSrc$
end if

end sub
'-- ***********************************************************************'
function fFileCopy (FileSrc$, FileDst$) as long '- -----------------------------------'
'print " fFileCopy FileSrc$=";FileSrc$
'Andrew Shelkovenko dec 2003
'Copy FileSrc$ to FileDst$
result=0
dim FileSrc as QFileStream
dim FileDst as QFileStream

'if Filesize(FileDst$)=0 then 
'end if

dr$=StripPath (FileDst$) 
'print "2 fFileCopy FileDst$=";FileDst$
'print " fFileCopy dr$=";dr$

if dr$<>"" then
	if DIREXISTS(dr$ ) =0 then MKSubDir dr$
	if DIREXISTS(dr$ ) =0 then result=-1: exit function 'showmessage ("FileCopy Can't create directory "+dr$ ): '
end if
result=-2
if FileSrc.Open(FileSrc$, fmOpenRead) =-1 then
	result=-3
	if FileDst.Open(FileDst$, fmCreate) =-1 then
		result=-4
		FileDst.CopyFrom  (FileSrc, 0)
		FileSrc.close
		FileDst.close
		result=1
	else
	ShowMessage ("fFileCopy error: Can't create file "+FileDst$)
	
	end if
else
	ShowMessage ("fFileCopy error: Can't open file "+FileSrc$)

end if
end function

'-- ***********************************************************************'
sub KillFiles (FileName$) 
'Andrew Shelkovenko  diakin@narod.ru  apr 2004
'Kill files in FileName$ by mask
'for example KillFiles "C:\BAS\RAPIDQ\tmp\*.tmp"

FName$ =StripPath (FileName$)+ DIR$(FileName$, 0 ) '-- Get first file

while STRIPFILENAME (FName$) <>""
	kill FName$
	
	if fileexists (StripPath (FileName$)+FName$)>0 then ShowMessage ("KillFiles Can't kill file "+FName$)
	FName$ = StripPath (FileName$)+DIR$ '-- Get next file
wend
end sub

'-- *****************************************************'
sub KillSubDir (DirSrc$, mask$) 
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

s1:
for i=NSD1 to Nsd2 'current level sudirs'
	SubDirname$=dir$(SubDir(i)+mask, faDirectory)
print"SubDirname$=";SubDirname$

	while    SubDirname$ <>""
		if FileRec.Size =0 and SubDirname$<> "." and SubDirname$<> ".." then ''
			inc adddir
			inc NumDir 'add subdir'
			if NumDir=ArrNumDir then ArrNumDir=ArrNumDir+300: redim SubDir(ArrNumDir) as string
			subDir(NumDir)=SubDir(i)+SubDirname$+"\"
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

dim doevnt
doevnt=-99
doevnt=LostP

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
	if doevnt=-1 then doevents
next k
io2RndFile2.close
io2Rndtmp.close
'print "io2Rnd completed"
END SUB

'-- **********************************************'
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
dim io2Rndtxt as QfileStream


dim io2RndList as QSTRINGLIST 
dim ioNumPnt as int
dim i0 as int
dim pnt as single
needtoWrite=0
dim doevnt
doevnt=-99
doevnt=LostP

if fileexists (io$)=0 then showmessage ("io2RndInter File not found "+io$): exit sub
if FileSize(io$)<1 then showmessage ("io2RndInter Zero size file "+io$): LostP=-99: exit sub

io2RndList.LoadFromFile (io$)
io2RndList.text=replacesubstr$(io2RndList.text,crlfcrlf,crlf)

ArgName$=FullPathNoExt(rndf$)+"Arg"+STRIPFILEEXT(rndf$)
ioutName$=FullPathNoExt(rndf$)+".io2"
txtOutName$=FullPathNoExt(rndf$)+".txt"


print"io2RndInter1 ArgName$=";ArgName$

io2RndFile2.Open(rndf$, fmCreate)   
io2RndArg.Open(ArgName$, fmCreate)   
io2io.Open(ioutName$, fmCreate)   

pntOld = 0: AdatOld! = 0: LostP = 1: j=0: i0=0
i0=val(Field$(io2RndList.Item(0),",", 1))
'print"i0=";i0

aaa$=""
bzz=io2RndList.ItemCount-1

while aaa$="" and bzz>0
	aaa$=io2RndList.Item(bzz)
	dec bzz 
wend

iend=val(Field$(aaa$,",", 1))
print"io2RndInter1 iend=";iend

if iend> 10* bzz then 
showmessage "Некорректные данные в архиве "+FullPathNoExt(rndf$)
iend= bzz
end if

if iend>i0 then
	io2stp=1
elseif iend<i0 then
	io2stp=-1
else
	'showmessage ("io2RndInter Begin point= EndPoint")
showmessage "Некорректные данные в архиве "+FullPathNoExt(rndf$)
end if

for k=0 to io2RndList.ItemCount-1
'Gauge.Position=cint(k/(bzz-1) *100)
	if k> kold+250 then
		locate 1,10
		print"io2RndInter1 k=";k
		kold=k
	end if
	
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
		goto io2RndInterexitsub
	end if
	
	ex1:
	if iend>i0 then
		inc i0
	elseif iend<i0 then
		dec i0
	else
		'showmessage ("io2RndInter Begin point= EndPoint")
		goto io2RndInterexitsub
	end if
	if doevnt=-1 then doevents
next k
io2RndInterexitsub:

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
	'ShowMessage ("ioAverage:File "+io$ +" not found")
	exit sub
end if

if InputList.ItemCount<5 then 
	'ShowMessage ("ioAverage:Data not found")
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

'*****************************************
function DownLoadURL (sUrl as string, dFileName as string) as long
'print"sUrl=";sUrl
' скачивает файл с заданного sURL и сохраняет под именем dFileName
'возвращает число скачанных байт TotalReadBytes или -1 в случае ошибки

Dim hOpen As Long, hFile As Long, sBuffer As String, ReadBytes As Long, TotalReadBytes As Long
defint sBufferSize=2048
filetxt$=""

'Create a buffer for the file we're going to download
sBuffer = Space(sBufferSize)+"<<<"


'Create an internet connection
hOpen = InternetOpen(scUserAgent, INTERNET_OPEN_TYPE_DIRECT, vbNullString, vbNullString, 0)
'print"hOpen=";hOpen
'Open the url

hFile = InternetOpenUrl(hOpen, sURL, vbNullString, 0&, INTERNET_FLAG_RELOAD, ByVal 0&)
'print"hFile=";hFile

'Read the first 1000 bytes of the file
zzz=InternetReadFile (hFile, sBuffer, sBufferSize, ReadBytes)
filetxt$=left$(sBuffer,ReadBytes)
TotalReadBytes=ReadBytes


while ReadBytes>0
	'print"ReadBytes=";ReadBytes
	'print"zzz=";zzz
	'clean up
	'Show our file
	'PRINT sBuffer
	zzz=InternetReadFile (hFile, sBuffer, sBufferSize, ReadBytes)
	filetxt$=filetxt$+left$(sBuffer,ReadBytes)
	TotalReadBytes=TotalReadBytes+ReadBytes
wend

InternetCloseHandle (hFile)
InternetCloseHandle (hOpen)

zzj=savestring(filetxt$,dFileName)

DownLoadURL=TotalReadBytes

End Sub

  