'-----------------------------------------------------------------
'
'  QFTPDirListView by Andrew Shelkovenko
'  based on 
'  QFTPCLIENT.INC by Jacques Philippe
'  and 
'  QDirListView.inc by Rene Saarsoo
'
'
'-----------------------------------------------------------------
'
' Long live the Rapid-Q!
'

' Icons for folders and unidentified files
$INCLUDE "RAPIDQ.INC"

$include "QFTPCLIENT.INC"

'dim Logedit AS QRICHEDIT
'Logedit.align=albottom
'Logedit.height=200
'Logedit.AddStrings "RichEdit1"
'Logedit.HideScrollBars=0
'Logedit.HideSelection=0
'Logedit.ScrollBars=3 'ssBoth = 3  
'Logedit.Wordwrap=0

'END CREATE
CREATE Form AS QFORM
	Caption = "Form1"
	Width = 640
	Height = 580
	Center
	
	'REATE MyFTP as QFTPDirListView
	'lign=alclient
	'ftp://diakin:5632fixxz@ftp.narod.ru
	'ost="ftp.narod.ru"
	'ser="diakin"
	'assword="5632fixx"
	
	'ND CREATE
	CREATE Logedit AS QRICHEDIT
		align=albottom
		height=200
		AddStrings "RichEdit1"
		HideScrollBars=0
		HideSelection=0
		ScrollBars=3 'ssBoth = 3  
		Wordwrap=0
		
	END CREATE
	
	
	
END CREATE
'Logedit.parent=Form


dim FtpClient as QFtpClient

'!!! There are problem - need to set full path to resources.  
$resource ICO_DIR_SMALL as "C:\bas\RapidQ\inc\dir_XP_small.ico"
$resource ICO_DIR_LARGE as "C:\bas\RapidQ\inc\dir_XP_large.ico"
$resource ICO_DEFAULTFILE_SMALL as "C:\bas\RapidQ\inc\default_small.ico"
$resource ICO_DEFAULTFILE_LARGE as "C:\bas\RapidQ\inc\default_large.ico"

' exclude it, if you have already declared this API-function
declare function SetFocus LIB "USER32" ALIAS "SetFocus" (Handle as long) as long

declare sub FileSelect_EventTemplate(Tag as integer)

'************************************************************************'
FUNCTION vidnum1$ (Num, dig%) as string
Num$=str$(Num)
pntPos=instr(Num$,".")
if pntPos=0 then digMax=0 else digMax=Len(Num$)-pntPos
if dig%>digMax then dig%=digMax 
vidnum$ = STR$((  CLNG(  abs(Num) * 10 ^ dig%) / 10 ^ dig%)*sgn(Num))
END FUNCTION
'

'************************************************************************'
type QFTPDirListView extends QListView
Host  as string property set Set_Host
User  as string property set Set_User
Password as string property set Set_Password

Directory as string property set Set_Directory
Filename as string
Mask as string property set Set_Mask
ShowRoot as integer property set Set_ShowRoot
LargeImageList as QImageList
SmallImageList as QImageList
ExtensionsList as QStringList
dlw_PopupMenu as QPopupMenu
dlw_Enter as QMenuItem
dlw_BackSpace as QMenuItem
OnFileSelect as event (FileSelect_EventTemplate)
ColumnsInitialized as integer
FilenameSize as integer property set Set_FilenameProp
FilenameType as integer property set Set_FilenameType
FilenameDate as integer property set Set_FilenameDate

'FtpClient as QFtpClient

'*****************************************
sub  FilenameProp 

end sub

'*****************************************
property set Set_Host (Host as string) 
QFTPDirListView.Host = Host
end property

'*****************************************
property set Set_User (User as string) 
QFTPDirListView.User = User
end property

'*****************************************
property set Set_Password (Password as string) 
QFTPDirListView.Password = Password
end property


'*****************************************
property set Set_FilenameProp (FilenameSize as integer) 
QFTPDirListView.FilenameSize = FilenameSize 
''  print "FilenameSize=", FilenameSize 
''    QFTPDirListView.Refresh
end property


'*****************************************
property set Set_FilenameType (FilenameType as integer) 
QFTPDirListView.FilenameType = FilenameType 
''  print "FilenameSize=", FilenameSize 
''    QFTPDirListView.Refresh
end property

'*****************************************
property set Set_FilenameDate (FilenameDate as integer) 
QFTPDirListView.FilenameDate = FilenameDate 
''  print "FilenameSize=", FilenameSize 
''    QFTPDirListView.Refresh
end property


'************************************************************************'
sub SetItemImage (Extension as string)
QFTPDirListView.Item(QFTPDirListView.ItemCount - 1).ImageIndex = 1
for i = 2 to QFTPDirListView.ExtensionsList.ItemCount - 1
	if lcase$(Extension) = QFTPDirListView.ExtensionsList.Item(i) then
		QFTPDirListView.Item(QFTPDirListView.ItemCount - 1).ImageIndex = i
		exit for
	end if
next i
end sub

'************************************************************************'
sub AddFileProperties (Extension as string)
dim SizeString as string
'print "SizeString=",SizeString 

'FtpClient.fileDate
'FtpClient.fileSize
'FtpClient.fileTime
'FtpClient.fileAttributesAsString

if FtpClient.fileSize/1024 >= 1 then
print"174      FtpClient.fileSize=";FtpClient.fileSize
	''      SizeString = str$(int(FileRec.Size / 1024)) + " KB"
	SizeString = vidnum$ (FtpClient.fileSize/ 1024, 1)+ " KB"
else
	SizeString = vidnum$ (FtpClient.fileSize, 0)+ " B"
end if
QFTPDirListView.AddSubItem (QFTPDirListView.ItemCount - 1, SizeString )
QFTPDirListView.AddSubItem (QFTPDirListView.ItemCount - 1, ucase$(Extension) + " File")
dim FirstSplitter as integer
dim Month as string

FirstSplitter = instr(FtpClient.fileDate, "-", 0)
print"FtpClient.fileDate=";FtpClient.fileDate
Month = left$(FtpClient.fileDate, FirstSplitter - 1)

if len(Month) = 1 then Month = "0" + Month
dim Day as string
Day = left$(right$(FtpClient.fileDate, len(FtpClient.fileDate) - FirstSplitter), _
instr(right$(FtpClient.fileDate, len(FtpClient.fileDate) - FirstSplitter), "-", 0) - 1)
dim Year as string
Year = right$(FtpClient.fileDate, 4)

QFTPDirListView.AddSubItem (QFTPDirListView.ItemCount - 1, Day+"."+Month+"."+Year + " " +FtpClient.fileTime)

end sub

'************************************************************************'
sub LoadDirectories
'Dim myFtp As QFtpClient
With QFTPDirListView
	DefStr sFile
		call  AddClrString ("138:.host="+QFTPDirListView.host, clred, LogEdit)
	If FtpClient.Connect (.host, .user, .password) Then
	HostDir$=FtpClient.GetDir
	call  AddClrString ("196:HostDir$="+(HostDir$), clred, LogEdit)
		sFile = FtpClient.FindFirstFile (HostDir$+"*.*")
		While sFile <> ""
			If Instr(FtpClient.fileAttributesAsString, "D") = 0 Then  ' reject directories
call  AddClrString ("203:FtpClient.fileName="+(FtpClient.fileName), clred, LogEdit)
call  AddClrString ("203:FtpClient.fileSize="+str$(FtpClient.fileSize), clred, LogEdit)
call  AddClrString ("203:FtpClient.fileDate="+(FtpClient.fileDate), clred, LogEdit)
call  AddClrString ("203:FtpClient.fileTime="+(FtpClient.fileTime), clred, LogEdit)
call  AddClrString ("203:FtpClient.fileAttributesAsString="+(FtpClient.fileAttributesAsString), clred, LogEdit)
				
			End If
			'-- добавляем в лист ---------
			if sFile = "."  then
			end if
			
			if sFile = ".." and QFTPDirListView.ShowRoot = FALSE then
			else
				
				'if DirExists(QFTPDirListView.Directory + sFile) then
				QFTPDirListView.AddItems sFile
				'end if
				
			end if
			
			sFile = FtpClient.FindNextFile
		Wend   
		Print FtpClient.errorMsg
		Print "End Of Directory"
		FtpClient.Close
	Else
		Print FtpClient.errorMsg
		FtpClient.Close
	End If
End With


end sub

'************************************************************************'
sub LoadFiles
dim File as string
dim i as integer
File = ""
i = 0

do
i = i + 1
if i = 1 then
	File = Dir$(QFTPDirListView.Directory + QFTPDirListView.Mask, 0)
else
	File = Dir$
end if
if File = "" then
	exit do
else
	dim Extension as string
	Extension = ""
	dim PontPlace as integer
	
	QFTPDirListView.AddItems File
	
	PointPlace = instr(File, ".", 0)
	
	if PointPlace > 0 then
		Extension = right$( File, instr(reverse$(File), ".", 0) - 1 )
		QFTPDirListView.SetItemImage (Extension)
	else
		QFTPDirListView.Item(QFTPDirListView.ItemCount - 1).ImageIndex = 1
	end if
	QFTPDirListView.AddFileProperties (Extension)
	
end if
loop
end sub

'************************************************************************'
sub Refresh
if QFTPDirListView.checkboxes=1 then QFTPDirListViewcheckboxes=1 else QFTPDirListViewcheckboxes=0
QFTPDirListView.checkboxes=0

QFTPDirListView.Clear
QFTPDirListView.LoadDirectories
QFTPDirListView.LoadFiles
QFTPDirListView.ViewStyle = QFTPDirListView.ViewStyle + 1   ' SomeHow we manage with
QFTPDirListView.ViewStyle = QFTPDirListView.ViewStyle - 1   ' changing the style
' to make items fully wisible
' ( without "..." at the end )
if ColumnsInitialized = FALSE then
	QFTPDirListView.ClearColumns
	QFTPDirListView.AddColumns "Name"
	
	QFTPDirListView.Column(0).Width =QFTPDirListView.Width-50' 150
	'print "zzzzzzzzFilenameSize=",QFTPDirListView.FilenameSize
	
	
	if  QFTPDirListView.FilenameSize =1 then 
		'print "gggggggggFilenameSize=",QFTPDirListView.FilenameSize
		
		QFTPDirListView.AddColumns "Size"
		QFTPDirListView.Column(0).Width = 150
		QFTPDirListView.Column(1).Width = 60
		
	end if
	
	if QFTPDirListView.FilenameType =1 then 
		QFTPDirListView.AddColumns "Type"
		QFTPDirListView.Column(0).Width = 150
		QFTPDirListView.Column(1).Width = 60
		QFTPDirListView.Column(2).Width = 60
		
	end if
	
	if QFTPDirListView.FilenameDate =1  then 
		QFTPDirListView.AddColumns "Date Modified"
		QFTPDirListView.Column(0).Width = 150
		QFTPDirListView.Column(1).Width = 60
		QFTPDirListView.Column(2).Width = 60
		QFTPDirListView.Column(3).Width = 100
		
	end if
	
	
	ColumnsInitialized = TRUE
end if
QFTPDirListView.Visible = false     ' Whith this we manage to repaint the control.
QFTPDirListView.Visible = true      ' Otherwise it would stay messed-up ( You can Try :) )
SetFocus(QFTPDirListView.Handle)    ' Focus was lost on hiding, so we set it back.
if QFTPDirListViewcheckboxes=1 then QFTPDirListView.checkboxes=1 else QFTPDirListView.checkboxes=0

end sub

'************************************************************************'
sub ChangeDirUp
QFTPDirListView.Directory = left$(QFTPDirListView.Directory, _
len(QFTPDirListView.Directory) - _
instr(mid$(reverse$(QFTPDirListView.Directory), 2), "\", 0)  )
QFTPDirListView.refresh
end sub

'************************************************************************'
sub ChangeDir
if QFTPDirListView.Item(QFTPDirListView.ItemIndex).Caption = ".." then
	QFTPDirListView.ChangeDirUp
else
	QFTPDirListView.Directory = QFTPDirListView.FileName + "\"
	QFTPDirListView.refresh
end if
end sub

'************************************************************************'
sub TryToChangeDirOrMakeEvent
if QFTPDirListView.FileName > "" then
	if DirExists(QFTPDirListView.FileName) then
		QFTPDirListView.ChangeDir
	else
		CallFunc(QFTPDirListView.OnFileSelect, 0)
	end if
end if
end sub



'*****************************************
event OnChange
if QFTPDirListView.ItemIndex >= 0 then
	QFTPDirListView.FileName = QFTPDirListView.Directory + QFTPDirListView.Item(QFTPDirListView.ItemIndex).Caption
else
	QFTPDirListView.FileName = ""
end if
end event

'*****************************************
event OnDblClick
QFTPDirListView.TryToChangeDirOrMakeEvent
end event

'*****************************************
event dlw_Enter.OnClick
QFTPDirListView.TryToChangeDirOrMakeEvent
end event

'*****************************************
event dlw_BackSpace.OnClick
QFTPDirListView.ChangeDirUp
end event



'*****************************************
property set Set_Directory (Dir as string)
if right$(Dir, 1) = "\" then
	QFTPDirListView.Directory = Dir
else
	QFTPDirListView.Directory = Dir + "\"
end if
QFTPDirListView.Refresh
end property

'*****************************************
property set Set_ShowRoot (RootSet as integer)
QFTPDirListView.ShowRoot = RootSet
QFTPDirListView.Refresh
end property

'*****************************************
property set Set_Mask (MaskSet as string)
QFTPDirListView.Mask = MaskSet
QFTPDirListView.Refresh
end property


''  property set Set_FilenameProp (FilenameSize as integer) 
''    QFTPDirListView.FilenameSize = FilenameSize 
''    print "FilenameSize=", FilenameSize 
''    QFTPDirListView.Refresh
''  end property


' FilenameSize as integer property set FilenameProp''
' FilenameType as integer property set FilenameProp
' FilenameDate as integer property set FilenameProp

'*****************************************
constructor
Width = 400
Height = 138
'Directory = left$(Command$(0), len(Command$(0)) - len(APPLICATION.ExeName) )
Filename = ""
Mask = "*.*"
ShowRoot =TRUE' FALSE
ReadOnly = TRUE
ColumnsInitialized = FALSE
LargeImageList.Width = 32
LargeImageList.Height = 32
ExtensionsList.AddItems "<dir>"
SmallImageList.AddICOHandle ICO_DIR_SMALL
LargeImageList.AddICOHandle ICO_DIR_LARGE
ExtensionsList.AddItems "<dir>"
SmallImageList.AddICOHandle ICO_DEFAULTFILE_SMALL
LargeImageList.AddICOHandle ICO_DEFAULTFILE_LARGE
LargeImages = QFTPDirListView.LargeImageList
SmallImages = QFTPDirListView.SmallImageList
dlw_Enter.ShortCut = "Enter"
dlw_Enter.Visible = FALSE
dlw_BackSpace.ShortCut = "BkSp"
dlw_BackSpace.Visible = FALSE
dlw_PopupMenu.AddItems(QFTPDirListView.dlw_Enter, QFTPDirListView.dlw_BackSpace)
PopUpMenu = QFTPDirListView.dlw_PopUpMenu
FilenameSize =1
FilenameType =1
FilenameDate =1

end constructor
end type
'----------- end object------------------

dim MyFTP as QFTPDirListView
MyFTP.align=alclient
'ftp://diakin:5632fixxz@ftp.narod.ru
MyFTP.host="ftp.narod.ru"
MyFTP.user="diakin"
MyFTP.password="5632fixx"
'MyFTP.GridLines=1
MyFTP.ViewStyle=1

'CONST vsIcon = 0         '-- View Style: Full sized icon, text on bottom
'CONST vsSmallIcon = 1    '-- Small icons, text aligned to the right
'CONST vsList = 2         '-- Same as above (nevermind this)
'CONST vsReport = 3       '-- Each item appears on its own line with information

'ND CREATE

MyFTP.parent=Form
MyFTP.LoadDirectories
Form.ShowModal  

