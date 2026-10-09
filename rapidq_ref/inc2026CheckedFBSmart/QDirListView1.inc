'-----------------------------------------------------------------
'
'  QDirListView
'
'  An Customized QListView For Displaing Files and Folders
'
'  by Rene Saarsoo
'
'-----------------------------------------------------------------
' not well-commented and needs some work, but is fully-functional :)
' All Suggestions and Bug-Reports are welcome to  nene@hot.ee
'
' Long live the Rapid-Q!
'

' Icons for folders and unidentified files
'curpath$=CurDir$
'print"curpath$=";curpath$

$resource ICO_DIR_SMALL as "C:\bas\RapidQ\inc\dir_XP_small.ico"
$resource ICO_DIR_LARGE as "C:\bas\RapidQ\inc\dir_XP_large.ico"
$resource ICO_DEFAULTFILE_SMALL as "C:\bas\RapidQ\inc\default_small.ico"
$resource ICO_DEFAULTFILE_LARGE as "C:\bas\RapidQ\inc\default_large.ico"

' exclude it, if you have already declared this API-function
declare function SetFocus LIB "USER32" ALIAS "SetFocus" (Handle as long) as long

declare sub FileSelect_EventTemplate(Tag as integer)

'-- ************************************************************************'
'FUNCTION vidnum$ (Num, dig%) as string
'Num$=str$(Num)
'pntPos=instr(Num$,".")
'if pntPos=0 then digMax=0 else digMax=Len(Num$)-pntPos
'if dig%>digMax then dig%=digMax 
'vidnum$ = STR$((  CLNG(  abs(Num) * 10 ^ dig%) / 10 ^ dig%)*sgn(Num))
'END FUNCTION
'

type QDirListView extends QListView
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
FilenameType as integer 'property set Set_FilenameProp
FilenameDate as integer 'property set Set_FilenameProp

sub  FilenameProp 

end sub

property set Set_FilenameProp (FilenameSize as integer) 
QDirListView.FilenameSize = FilenameSize 
''  print "FilenameSize=", FilenameSize 
''    QDirListView.Refresh
end property

'-- ************************************************************************'
sub SetItemImage (Extension as string)
QDirListView.Item(QDirListView.ItemCount - 1).ImageIndex = 1
for i = 2 to QDirListView.ExtensionsList.ItemCount - 1
	if lcase$(Extension) = QDirListView.ExtensionsList.Item(i) then
		QDirListView.Item(QDirListView.ItemCount - 1).ImageIndex = i
		exit for
	end if
next i
end sub

'-- ************************************************************************'
sub AddFileProperties (Extension as string)
dim SizeString as string
'print "SizeString=",SizeString 

if FileRec.Size/1024 >= 1 then
	''      SizeString = str$(int(FileRec.Size / 1024)) + " KB"
	SizeString = vidnum$ (FileRec.Size/ 1024, 1)+ " KB"
else
	SizeString = vidnum$ (FileRec.Size, 0)+ " B"
end if
QDirListView.AddSubItem (QDirListView.ItemCount - 1, SizeString )
QDirListView.AddSubItem (QDirListView.ItemCount - 1, ucase$(Extension) + " File")
dim FirstSplitter as integer
dim Month as string
FirstSplitter = instr(FileRec.Date, "-", 0)
Month = left$(FileRec.Date, FirstSplitter - 1)
if len(Month) = 1 then Month = "0" + Month
dim Day as string
Day = left$(right$(FileRec.Date, len(FileRec.Date) - FirstSplitter), _
instr(right$(FileRec.Date, len(FileRec.Date) - FirstSplitter), "-", 0) - 1)
dim Year as string
Year = right$(FileRec.Date, 4)

QDirListView.AddSubItem (QDirListView.ItemCount - 1, Day+"."+Month+"."+Year + " " +FileRec.Time)

end sub

'-- ************************************************************************'
sub LoadDirectories
dim File as string
File = ""
File = Dir$(QDirListView.Directory + "*.*", faDirectory)
do
File = Dir$
if File = "" then
	exit do
else
	if File = "."  then
	end if
	
	if File = ".." and QDirListView.ShowRoot = FALSE then
	else
		
		if DirExists(QDirListView.Directory + File) then
			QDirListView.AddItems File
		end if
		
	end if
	
end if
loop
end sub

'-- ************************************************************************'
sub LoadFiles
dim File as string
dim i as integer
File = ""
i = 0

do
i = i + 1
if i = 1 then
	File = Dir$(QDirListView.Directory + QDirListView.Mask, 0)
else
	File = Dir$
end if
if File = "" then
	exit do
else
	dim Extension as string
	Extension = ""
	dim PontPlace as integer
	
	QDirListView.AddItems File
	
	PointPlace = instr(File, ".", 0)
	
	if PointPlace > 0 then
		Extension = right$( File, instr(reverse$(File), ".", 0) - 1 )
		QDirListView.SetItemImage (Extension)
	else
		QDirListView.Item(QDirListView.ItemCount - 1).ImageIndex = 1
	end if
	QDirListView.AddFileProperties (Extension)
	
end if
loop
end sub

'-- ************************************************************************'
sub Refresh
if QDirListView.checkboxes=1 then QDirListViewcheckboxes=1 else QDirListViewcheckboxes=0
QDirListView.checkboxes=0

QDirListView.Clear
QDirListView.LoadDirectories
QDirListView.LoadFiles
QDirListView.ViewStyle = QDirListView.ViewStyle + 1   ' SomeHow we manage with
QDirListView.ViewStyle = QDirListView.ViewStyle - 1   ' changing the style
' to make items fully wisible
' ( without "..." at the end )
if ColumnsInitialized = FALSE then
	QDirListView.ClearColumns
	QDirListView.AddColumns "Name"
	
	QDirListView.Column(0).Width =QDirListView.Width-50' 150
	'print "zzzzzzzzFilenameSize=",QDirListView.FilenameSize
	
	
	if  QDirListView.FilenameSize =1 then 
		'print "gggggggggFilenameSize=",QDirListView.FilenameSize
		
		QDirListView.AddColumns "Size"
		QDirListView.Column(0).Width = 150
		QDirListView.Column(1).Width = 60
		
	end if
	
	if QDirListView.FilenameType =1 then 
		QDirListView.AddColumns "Type"
		QDirListView.Column(0).Width = 150
		QDirListView.Column(1).Width = 60
		QDirListView.Column(2).Width = 60
		
	end if
	
	if QDirListView.FilenameDate =1  then 
		QDirListView.AddColumns "Date Modified"
		QDirListView.Column(0).Width = 150
		QDirListView.Column(1).Width = 60
		QDirListView.Column(2).Width = 60
		QDirListView.Column(3).Width = 100
		
	end if
	
	
	ColumnsInitialized = TRUE
end if
QDirListView.Visible = false     ' Whith this we manage to repaint the control.
QDirListView.Visible = true      ' Otherwise it would stay messed-up ( You can Try :) )
SetFocus(QDirListView.Handle)    ' Focus was lost on hiding, so we set it back.
if QDirListViewcheckboxes=1 then QDirListView.checkboxes=1 else QDirListView.checkboxes=0

end sub

'-- ************************************************************************'
sub ChangeDirUp
QDirListView.Directory = left$(QDirListView.Directory, _
len(QDirListView.Directory) - _
instr(mid$(reverse$(QDirListView.Directory), 2), "\", 0)  )
QDirListView.refresh
end sub

'-- ************************************************************************'
sub ChangeDir
if QDirListView.Item(QDirListView.ItemIndex).Caption = ".." then
	QDirListView.ChangeDirUp
else
	QDirListView.Directory = QDirListView.FileName + "\"
	QDirListView.refresh
end if
end sub

'-- ************************************************************************'
sub TryToChangeDirOrMakeEvent
if QDirListView.FileName > "" then
	if DirExists(QDirListView.FileName) then
		QDirListView.ChangeDir
	else
		CallFunc(QDirListView.OnFileSelect, 0)
	end if
end if
end sub



event OnChange
if QDirListView.ItemIndex >= 0 then
	QDirListView.FileName = QDirListView.Directory + QDirListView.Item(QDirListView.ItemIndex).Caption
else
	QDirListView.FileName = ""
end if
end event

event OnDblClick
QDirListView.TryToChangeDirOrMakeEvent
end event

event dlw_Enter.OnClick
QDirListView.TryToChangeDirOrMakeEvent
end event

event dlw_BackSpace.OnClick
QDirListView.ChangeDirUp
end event


property set Set_Directory (Dir as string)
if right$(Dir, 1) = "\" then
	QDirListView.Directory = Dir
else
	QDirListView.Directory = Dir + "\"
end if
QDirListView.Refresh
end property

property set Set_ShowRoot (RootSet as integer)
QDirListView.ShowRoot = RootSet
QDirListView.Refresh
end property

property set Set_Mask (MaskSet as string)
QDirListView.Mask = MaskSet
QDirListView.Refresh
end property


''  property set Set_FilenameProp (FilenameSize as integer) 
''    QDirListView.FilenameSize = FilenameSize 
''    print "FilenameSize=", FilenameSize 
''    QDirListView.Refresh
''  end property


' FilenameSize as integer property set FilenameProp''
' FilenameType as integer property set FilenameProp
' FilenameDate as integer property set FilenameProp


constructor
Width = 400
Height = 138
Directory = left$(Command$(0), len(Command$(0)) - len(APPLICATION.ExeName) )
Filename = ""
Mask = "*.*"
ShowRoot = FALSE
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
LargeImages = QDirListView.LargeImageList
SmallImages = QDirListView.SmallImageList
dlw_Enter.ShortCut = "Enter"
dlw_Enter.Visible = FALSE
dlw_BackSpace.ShortCut = "BkSp"
dlw_BackSpace.Visible = FALSE
dlw_PopupMenu.AddItems(QDirListView.dlw_Enter, QDirListView.dlw_BackSpace)
PopUpMenu = QDirListView.dlw_PopUpMenu
FilenameSize =1
FilenameType =0
FilenameDate =0

end constructor
end type




