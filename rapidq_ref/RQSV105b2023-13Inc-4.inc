'$APPTYPE GUI


'  $INCLUDE "RichEdPopUp.inc"
'$INCLUDE "QColorDialog.inc"
'$Include "constants.inc"
'!!$include "QColorButton.inc"
'$include "QINI.inc" 

'$include "Object\QStatusBarEx.inc" 
'$include "Form.inc"
'$Include "constants.inc"


'!!!--- LangIniHeader ---
'$INCLUDE <LangIniHeader.inc>

LangVar$(35)=Langini.get("Copy filename to clipboard","Copy filename to clipboard")

cName$=Langini.get("Name","Name")
cPath$=Langini.get("Path","Path")
cYes$=Langini.get("Yes","Yes")
cClose$=Langini.get("Close","Close")
cCancel$=Langini.get("Cancel","Cancel")
cSize$=Langini.get("Size","Size")
cDate$=Langini.get("Date","Date")
cTime$=Langini.get("Time","Time")
cColor$=Langini.get("color","color")
cFileList$=Langini.get("FileList","FileList")
print 1051

LangVar$(27)=Langini.get("Load file list","Load file list")
LangVar$(104)=Langini.get("Verify file list","Verify file list")
LangVar$(30)=Langini.get("Save file list","Save file list")
LangVar$(36)=Langini.get("Delete file list","Delete file list")
LangVar$(24)=Langini.get("File","File")
LangVar$(87)=Langini.get("Case sensitives","Case sensitives")
LangVar$(12)=Langini.get("Close","Close")
LangVar$(112)=Langini.get("Col ","Col ")+" "
LangVar$(37)=Langini.get("Delete FileList","Delete File List")
LangVar$(20)=Langini.get("Directory Tree","Directory Tree")
LangVar$(10)=Langini.get("Disable Rem","Disable comments")
LangVar$(141)=Langini.get("Dos","Dos")
LangVar$(100)=Langini.get("DoubleClick - start this file","DoubleClick - start this file")
LangVar$(99)=Langini.get("DoubleClick ","DoubleClick")
LangVar$(39)=Langini.get("Exit","Exit")
LangVar$(127)=Langini.get("File not found ","File not found ")
LangVar$(9)=Langini.get("File","File")
LangVar$(90)=Langini.get("FileName","FileName")
LangVar$(7)=Langini.get("List of lines","List of lines")
LangVar$(28)=Langini.get("Load FileList","Load FileList")
LangVar$(26)=Langini.get("New","New")
LangVar$(17)=Langini.get("Non registered.","Non registered.")
LangVar$(103)=Langini.get("Open in notepad","Open in notepad")
LangVar$(113)=Langini.get("Pos ","Pos ")+" "
LangVar$(74)=Langini.get("Registration Code","Registration Code")
LangVar$(72)=Langini.get("Registration","Registration")
LangVar$(111)=Langini.get("Row ","Row ")
LangVar$(31)=Langini.get("Save FileList","Save FileList")
LangVar$(42)=Langini.get("SaveFile","SaveFile")
LangVar$(44)=Langini.get("SaveFileAs..","SaveFileAs..")
LangVar$(92)=Langini.get("Text","Text")
LangVar$(34)=Langini.get("Validate FileList","Validate FileList")
LangVar$(146)=Langini.get("OK","OK")
LangVar$(153)=Langini.get("OK?","OK?")
LangVar$(143)=Langini.get("Total","Total ")
LangVar$(106)=Langini.get("Total files","Total files")+" "
LangVar$(76)=Langini.get("Choose folder","Choose folder")
LangVar$(25)=Langini.get("Choose folders","Choose folders")
LangVar$(58)=Langini.get("Language","Language")
LangVar$(38)=Langini.get("Exit","Exit")
LangVar$(148)=Langini.get("Yes","Yes")
LangVar$(21)=Langini.get("Add to list","Add to list")
LangVar$(154)=Langini.get("Exit?","Exit?")
LangVar$(105)=Langini.get("Copy file name to clipboard","Copy file name to clipboard")
LangVar$(107)=Langini.get("Found","Found")+" "
LangVar$(51)=Langini.get("Settings","Settings")
LangVar$(77)=Langini.get("Start search","Start search")
LangVar$(149)=Langini.get("Set search pattern","Set search pattern")
LangVar$(144)=Langini.get("File not found","File not found ")
LangVar$(75)=Langini.get("About","About")
LangVar$(97)=Langini.get("Refresh string list","Refresh string list")
LangVar$(108)=Langini.get("Left","Left")
LangVar$(83)=Langini.get("Stop search","Stop search")
LangVar$(101)=Langini.get("Open in notepad","Open in notepad")
LangVar$(102)=Langini.get("Open folder","Open folder")
LangVar$(152)=Langini.get("Replace","Replace")
LangVar$(95)=Langini.get("Wordwrap","Wordwrap")
LangVar$(80)=Langini.get("Previous hit","Previous hit")
LangVar$(81)=Langini.get("Previous file","Previous file")
LangVar$(79)=Langini.get("Next hit","Next hit")
LangVar$(78)=Langini.get("Next file","Next file")
LangVar$(69)=Langini.get("Help","Help")
LangVar$(82)=Langini.get("Pause","Pause")
LangVar$(91)=Langini.get("View..","View..")
LangVar$(121)=Langini.get("Elapced","Elapced")+" "
LangVar$(55)=Langini.get("Case sensitives","Case sensitives")
LangVar$(43)=Langini.get("Save as..","Save as..")
LangVar$(68)=Langini.get("Save settings","Save settings")
LangVar$(41)=Langini.get("Save file","Save file")
LangVar$(96)=Langini.get("String list","String list")
LangVar$(70)=Langini.get("Help","Help")
LangVar$(179)=Langini.get("Lines","Lines")+" "
LangVar$(88)=Langini.get("Whole word","Whole word")
LangVar$(22)=Langini.get("Remove from list","Remove from list")
LangVar$(147)=Langini.get("Delete file","Delete file")
LangVar$(119)=Langini.get("Found files","Found files")
'print"107:LangVar$(119)=";LangVar$(119)


Msg13$=Langini.get("OK?","OK?")
Msg14$=Langini.get("Directory","Directory" )
Msg15$=Langini.get("already exists."," already exists. ")
Msg16$=Langini.get("Replace?","Replace?")


English$=Langini.get("English","English")
Russian$=Langini.get("Russian","Russian")

LangVar$(123)=Langini.get(" bytes"," bytes")
LangVar$(19)=Langini.get(" Register Now!"," Register Now!")
LangVar$(116)=Langini.get("files/sec"," files/sec")
LangVar$(50)=Langini.get("&Edit","&Edit")

'!!!--- end lang ---
dim trect as QREct
declare SUB FindTextSV (Sender as QButton)'

'--- Declarations ---
Declare Sub AddFilesBtnOnClick
Declare Sub Check1 (Key AS Word, Shift AS INTEGER)
Declare Sub FileListBoxWndProc (Hwnd as long, Msg as long, wParam as long, lParam as long)

Declare Sub convert(ip)
declare sub ShowLabelList(Col& , Row&, CanSelect&)'(Index&, Change AS BYTE)
Declare Sub SdlDrawCell(Col&, Row&, State&, Rect AS QRect, Sender AS QStringGrid)


Declare Sub TextOnlyOnClick
Declare Sub SearchCBoxOnDrawItem (Index%, State%, R AS QRect) 

Declare Sub SearchCBoxOnchange
Declare Sub DeleteFromFilelistClick
Declare Sub CopyFileTo
Declare Sub CopyFile2FolderClick
DECLARE FUNCTION SendMessageApi1 LIB "user32" ALIAS "SendMessageA" (hWnd AS LONG, Msg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG

Declare Sub ChoosDirOnclick
Declare Sub LangChoose (Sender as QMenuItem)

'!!! ---- Resource -----
$RESOURCE OpenList AS "ico\ListOpen.bmp"
$RESOURCE SaveList AS "ico\ListSave.bmp"
$RESOURCE NotBook_BMP AS "ico\Note03.bmp"
'$RESOURCE Folder_BMP AS "ico\Folder.bmp"
$RESOURCE Folder_BMP AS "ico\Open.bmp"

$RESOURCE DeleteFromList_BMP AS "ico\DelList.bmp"
'$RESOURCE DeleteFromList_BMP AS "ico\stringgridDelRow.bmp"
'$RESOURCE DeleteList_BMP AS "ico\stringgridClear.bmp"

$RESOURCE DeleteList_BMP AS "ico\dellist1.bmp"
$RESOURCE Folder_BMP AS "ico\Folder.bmp"



$RESOURCE refresh AS "ico\refresh.bmp"
$RESOURCE sOpen AS "ico\sOpen.bmp"
$RESOURCE StartSearch AS "ico\run1.bmp"
$RESOURCE NextFile AS "ico\icon3038.bmp"
$RESOURCE NextHit AS "ico\icon3037.bmp"
$RESOURCE PrevHit AS "ico\icon3039.bmp"
$RESOURCE PrevFile AS "ico\icon3036.bmp"
'$RESOURCE PauseSearch AS "icon3058.bmp"
$RESOURCE StopSearch AS "ico\icon2775.bmp"
$RESOURCE DelHotDir AS "ico\minus.bmp"
$RESOURCE AddHotDir AS "ico\plus.bmp"
'C:\@0CD\00000\bestPRG\Icons\Actions\Binos1.ico

$RESOURCE Zvon AS "ico\Zvon.wav"
'$OPTION ICON "ico\eye.ico"
'$INCLUDE "RichEdPopUp.inc"

'Application.HintPause=100
'Application.HintColor =&H7AFF59'' &H00FF00

'$INCLUDE "RichEdPopUp.inc"
'$include "Object\QINI.inc" 
print 18889
'!!!-------- TimerSVs ------------
DIM TimerSV2 AS QTimer
DIM TimerSV3 AS QTimer
DIM TimerSV4 AS QTimer
'!!! TimerSV4.Enabled =0  - отключение проверки регистрации

declare sub TimerOverSV3 
TimerSV3.Interval = 450 
TimerSV3.Enabled = 0 'True 
TimerSV3.OnTimer = TimerOverSV3 


declare sub TimerOverSV2 
TimerSV2.Interval = 350 
TimerSV2.Enabled =0' 1 'True 
TimerSV2.OnTimer = TimerOverSV2 



'!!!-----------  регистрация ----------------------'
defstr vdr$  'признак того, что юзер нажал кнопку ОК регистрации кода
defstr bRg$  'регистрационный код
defstr SDrFile$'=chr$(102)+chr$(108)+chr$(46)+chr$(100)+chr$(98)
sad$=chr$(102)+chr$(108)+chr$(46)+chr$(100)+chr$(98) 'fl.db
'print"213:sad$=";sad$
defint rd
SDrFile$=sad$

qwer44=1
qwer22=0


'systemDir$
Dim systemDir$ As String, Ret As Long
'Create a buffer
'--systemDir$ = Space(255)
'Get the system directory

'--Ret = GetSystemDirectory(systemDir$, 255)

'Remove all unnecessary chr$(0)'s
systemDir$ =SysDir ("Fonts")  '--Left$(systemDir$, Ret)
systemDir$ =REPLACESUBSTR$(systemDir$,"Fonts","system32")
if right$(systemDir$,1)<> "\" then  systemDir$=systemDir$+ "\"
'Show the windows directory


declare function CrpStr1 (Strng1 as string, key as integer) as string
declare function CrpStr (Strng1 as string, key as integer) as string
declare function StrCrp (Strng2 as string, key as integer) as string
rgdir$=systemDir$'SysDir ("AppData") 
'SDrFile$=rgdir$+chr$(144)+chr$(108)+chr$(46)+chr$(100)+chr$(98) '- признак зарегистрированной версии  
' rq32.ini
SDrFile$=rgdir$+chr$(114)+chr$(113)+chr$(51)+chr$(50)+chr$(46)+chr$(105)+chr$(110)+chr$(105)
'SDrFile$=C:\WINDOWS\system32\rq32.ini
'print "SDrFile$=" ,SDrFile$

declare sub RegCode

dim ARg$(1) as string
dim cRg$(1) as string

defint once=0
defint RerInst=0 'повторная  установка'
dim secFile as QFileStream
dim secFile1 as QFileStream
dim secFile2 as QFileStream

dim CrpStr1Arr(100) as string
AStr$=""
defint AscStr1,AscStr2,AscStr3,AscStr4,AscStr5

'''if fileExists (SDrFile$) and filesize(SDrFile$)>0 then 
'secFile.Open  (SDrFile$, fmRead) 
secFileStr$="-" 'secFile.ReadLine 
secFileStr1$=field$(secFileStr$,chr$(132),2) 'код' 
secFileStr2$=field$(secFileStr$,chr$(132),3) 'имя 
secFileStr3$="-"
'secFile.Close
'secFileStr3$=CrpStr1(secFileStr2$, rd) ' код из имени
'end if


'!!! ---------



'!!!---------- register -------------
qwer22=0
qwer44=1
timerе1=0
timerе1Old=0
timerе2=0
timerе2Old=0


'LangIni.Section=chr$(82)+chr$(101)+chr$(103)+chr$(105)+chr$(115)+chr$(116)+chr$(101)+chr$(114) '"Register" '!!! -------------



defint FileEditLen, Modiflg1, NeedSubRefresh1 'размер текста изменился
'!!defstr RichRow1,  RichCol1, RichRow2,  RichCol2, RichRow3,  RichCol3

'--- Declarations ---
Declare Sub RtfFilOnClick
Declare Sub checkNestedDirs
Declare Sub CopyFileNAmeClick
Declare Sub OpenItemFolderClick
Declare Sub OpenIntextEditClick
declare sub SrcEditOnKeyDown (Key AS WORD, Shift AS INTEGER)
declare sub SrcEditOnKeyUp (Key AS WORD, Shift AS INTEGER)

declare sub RichEditOnMouseDown
declare sub  R2Change
Declare Sub refreshList
Declare Sub ListGridDrawCell (Col%, Row%, State%, R AS QRect)
Declare Sub ListSelectCell(Col% , Row%, CanSelect%, Sender AS QStringGrid)  

Declare Sub ListChBoxClick
ListCreatedFlg=0 '!!! Флаг что список строк создан

declare sub register

'Declare Function ShellExecute lib "shell32" alias "ShellExecuteA" _
'(ByVal hWnd as long, ByVal lpOperation as string, ByVal lpFile as string, ByVal lpParameters as integer, _
'ByVal lpDirectory as string, ByVal nShowCmd as integer) as long

declare sub   OKiButtonClick
declare sub  cancelButtonClick


Declare Sub SearchInF
Declare Sub OnFileListPopUp

DECLARE FUNCTION GetFocus1 Lib "user32" Alias "GetFocus"() AS LONG
DECLARE FUNCTION Setfocus1 Lib "user32" Alias "SetFocus"(hwnd As Long) AS LONG

declare sub AboutClick
Declare Sub HelpEnglish
declare sub Help2
declare sub Help3
declare SUB AboutFrmMouseMove  (X%, Y%, Shift%) 
declare sub AboutLabel1DblClick (X%, Y%, Shift%,sender as  QLabel)
declare sub AboutLabel1MouseMove (X%, Y%, Shift%,sender as  QLabel )
Declare Sub LabelNag2Click
Declare Sub NagPanelOnMouseMove (X%, Y%, Shift%)


declare sub StopS
'StopS1=0
'declare sub VisDir(Button%, X%, Y%, Shift%)
'declare sub ChangeDirectory
'----------------------------'
startonceFlg=0
'print"343:startonceFlg=";startonceFlg

'--------------------------------------
ScreenWidth=Screen.Width
ScreenHeight=Screen.Height


StartPath$ = COMMAND$(0)-Application.ExeName    

'!!!-- settings ----------
dim RQASIni as QINI
RQASIni.FileName=StartPath$+"RQAS.ini" 
print"355:StartPath$=";StartPath$


'-------------------------------------------------------------

defint ButtonSize1, ExplorerExist
ButtonSize=30
defint  NumFiles, NumProv, NumOst, NumTime, StopS1
NumFiles=0 'всего проверяемых файлов 
NumProv=0  'число проверенных файлов 
NumOst=0   'осталось проверить

NumHit=0   'найдено файлов
adddir=0
TimeOst=0
speed=0
TimeBeg=0
FNameLabelcaption$=""


defstr docsgn ' сигнатура документа
defstr StartDir1, CurList, cFileName

declare sub Main
declare SUB DrawCell (Col%, Row%, State%, Rect AS QRect, Sender AS QStringGrid)
declare SUB SelectCell (Col% , Row%, CanSelect%,Sender AS QStringGrid)
declare sub exitProg


declare sub SaveIni '=====
declare sub LoadIni

declare sub SaveIni1 '===== ' LangVar$(7)=List of lines
declare sub LoadIni1

declare sub SaveFileSV
declare sub SaveAsSV

declare Sub btnClickSV (Sender as Qbutton)
declare sub BtnAddHotDirClick 
declare sub BtnDelHotDirClick (Col%, Row%, CanSelect%)
declare sub DirTreeFormSVResize
declare  SUB CheckSV(key AS BYTE)               
declare sub StartFile
declare sub FileClickSV
DECLARE SUB FileLoadSV (filename$) ' загрузка файла через файл-лист

DECLARE SUB OpenFile ' загрузка единичного файла через меню

declare sub SaveFileList 
declare sub LoadFileList 
declare sub ValidFileList
declare sub DelFileList 

declare sub CodAutoOnClick  
declare sub CodWin1251OnClick 
declare sub CodDosOnClick
declare sub Koi8OnClick
declare sub EMailBugOnClick

declare sub CodRBOnClick (Sender as QMenuItem) ' LangVar$(9)=File

declare sub NextFileOnCl
declare sub            NextHitOnCl
declare sub            PrevHitOnCl
declare sub            PrevFileOnCl

declare sub ChBoxWrapClick
declare sub ChBoxPlainTxtClick
declare sub ChBoxHTMLClick


'declare function TimeString (TimSec as integer) as string
' LangVar$(10)=Disable Rem
declare function  LCaseR1$ (Cases$) as string
declare function  UCaseR1$ (Cases$) as string
declare function  FileNameParse$ (cFileName) as string


DIM Object AS QOLEOBJECT

DIM SaveDialog1 AS QSaveDialog
DIM OpenDialog1 AS QOpenDialog

dim Font1 as QFont
dim Font2 as QFont

Font1.Name = "Tahoma"
Font1.Color=cldb
Font1.size=10

Font2.Name = "Lucida"
Font2.Color=clDRed


DIM FileIni AS QFileStream ' файл инициализации
DIM FileBak AS QFileStream:
DIM FileName AS QFileStream: ' текущий файл
DIM FileList AS QFileStream: ' файллист



DIM Timer1SV AS QTimer
dim dateR1 as string
dateR=mid$(date$, 4,3)+ mid$(date$, 1,3)+mid$(date$, 7,4)
declare sub TimerOverSV 
Timer1SV.Interval = 100 
Timer1SV.Enabled = 0 'True 
print"462:Timer1SV.Enabled=";Timer1SV.Enabled
Timer1SV.OnTimer = TimerOverSV 

CREATE SettingsForm AS QFORM
	Caption = LangVar$(51) ' LangVar$(51)=Settings
	Width = 300
	Height = 440
	left=700
	top=220
	'Center
	'OnClose=FrmMinimized
	FormStyle = fsStayOnTop
	BorderStyle=bsSizeToolWin 
	DelBorderIcons  (biMinimize , biMaximized , biSystemMenu )
	CREATE MaskBoxNo AS QComboBox '==== маска
		Text = "*.gif *.jpg, *.bmp, *.pcx, *.png, *.ico, *.exe, *.com, *.dll,*.bin, *.obj,  *.zip, *.rar,*.arj, *.cab, *.pak, *.chm, *.dbx"
		'".BMP",".ICO",".jpg",".gif",".pcx",".exe",".dll" ,".bin",".obj",".zip",".rar",".arj",".tif",".pak",".cab",".chm"
		
		Left =4 
		Top = 52
		TabOrder = 2
		Width =245 ' LangVar$(90)=FileName
		''                OnChange=check1
		'AddItems "*.gif *.jpg, *.exe, *.com, *.dll, *.bmp, *.pcx, *.png, *.zip, *.rar"
		'visible=0
		
	END CREATE
	
	CREATE ChBoxYes AS QCHECKBOX
		Caption = "Files only"
		Left =4
		Top = 4'34'125
		Width =150
		font.color=clDBlue
		checked=true
		'OnClick = CBoxLogClick
		'visible=0
	END CREATE
	
	CREATE ChBoxNo AS QCHECKBOX
		Caption = "Exclude files "
		Left =4
		Top = 54'125
		Width =150
		font.color=clDBlue
		checked=true
		'OnClick = CBoxLogClick
		'visible=0
		
	END CREATE
	
end create

print"RQSV 515:="

CREATE SearchListForm1 AS QFORM
	Caption = LangVar$(7) ' LangVar$(7)=List of lines
	Width = 300
	Height = 440
	left=700
	top=220
	'Center
	'OnClose=FrmMinimized
	FormStyle = fsStayOnTop
	BorderStyle=bsSizeToolWin 
	DelBorderIcons  (biMinimize , biMaximized , biSystemMenu )
	
	CREATE SEarchListGrid1 AS QSTRINGGRID
		'Left = 5
		'Top = 5
		'height=400
		'width=650
		align=alclient
		FixedRows = 1 
		FixedCols = 1 
		ColCount = 3'4 
		RowCount = 2 
		DefaultColWidth = 80
		DefaultRowHeight = 26
		enabled=true
		AddOptions=goThumbTracking, goDrawFocusSelected, goColSizing
		cell(0,0) = "Line N":
		cell(1,0) = LangVar$(9): ' LangVar$(9)=File
		colWidths(0)=40' номер
		colWidths(1)=0' файл
		colWidths(2)=550 'поиск'
		'colWidths(3)=-1 'index файла из списка
		'OnDrawCell = ListGridDrawCell
		OnSelectCell = ListSelectCell
	END CREATE
	
	CREATE PanelSEarchList1 AS QPANEL
		height=30
		align=alBottom'alclient
		CREATE DisRemBtn1 AS QCheckBox
			Caption = LangVar$(10) ' LangVar$(10)=Disable Rem
			Left = 4
			Top = 4
			VISIBLE=0
			'OnClick=DisRemBtnOnClick
		END CREATE
		CREATE LinesLabel AS QLABEL
			Caption = "Lines"
			Left = 80
			Top = 4
			Transparent = 1
		END CREATE
		
	END CREATE
	
END CREATE


print"668:="

CREATE AboutFrm AS QFORM     '=========== AboutFrm ==========================='
	Caption =cAbout$ ' "О программе"     
	Width = 380  : Height = 190     
	Center 
	'FormStyle = fsStayOnTop
	'color=&HA9C99F
	OnMouseMove= AboutFrmMouseMove 
	
	CREATE AboutLabel1 AS QLABEL ' LangVar$(17)=Non registered.
		Left = 16:Top = 4:
		'Align=alCenter
		Transparent = 1
		Width = 50
		'font.name="Comic Sans MS"
		font.size=12
		font.color=cldb
		Caption =RQversion$+ "    "+RQversionDate$ +chr$(10)
		Tag=80
		hint= "http://mira.xeno.ru/"
		ShowHint=True
		OnClick = AboutLabel1DblClick: 
		OnDblClick = AboutLabel1DblClick
		OnMouseMove = AboutLabel1MouseMove
		Cursor=crHandPoint
	END CREATE
	
	CREATE AboutLabel2 AS QLABEL
		Left = 16:Top = 30:
		Transparent = 1
		Width = 50
		'font.name="Comic Sans MS"
		font.size=12
		font.color=cldb
		Caption =   "Andrew Shelkovenko diakin@narod.ru             " 
		Tag=81
		hint= "mailto:diakin@narod.ru"         
		ShowHint=True
		OnClick = AboutLabel1DblClick: 
		OnDblClick = AboutLabel1DblClick
		OnMouseMove = AboutLabel1MouseMove
		Cursor=crHandPoint
	END CREATE
	' LangVar$(20)=Directory Tree
	CREATE AboutLabel3 AS QLABEL
		Left = 5:Top = 130:
		Transparent = 1
		Width = 50
		font.name="Comic Sans MS"
		font.size=8
		font.color=clDPurple
		OnClick = AboutLabel1DblClick: 
		OnDblClick = AboutLabel1DblClick
		OnMouseMove = AboutLabel1MouseMove
		
		Caption =  "Special thanks to William Yu for Rapid-Q Basic programming language"
		Tag=82
		
	END CREATE
	
END CREATE

print 640

CREATE DirTreeFormSV AS QForm
	Caption = LangVar$(20) ' LangVar$(20)=Directory Tree
	Center
	top=60
	left=50
	height=450
	Width =640    
	FormStyle = fsStayOnTop
	'OnResize=DirTreeFormSVResize
	AutoScroll=false
	KeyPreview = 1        'this line does the trick
	'' OnKeyPress = CheckDir 
	color=&h9E8865
	
	CREATE DirTreeSV AS QDirTree
		''            Align=center
		top=60
		Left = 4
		'InitialDir = "c:\temp"
		Width =DirTreeFormSV.ClientWidth/2
		Height =DirTreeFormSV.ClientHeight -65
		''          OnChange =ChangeDirectory1
		TabOrder=1
		ShowHint=false
		''            font=font
		font.color=clRed
		
	END CREATE
	CREATE SelDirGrid AS QSTRINGGRID          ' LangVar$(24)=&Файл
		Top = 60:
		Height =DirTreeFormSV.ClientHeight -65
		Left = DirTreeFormSV.ClientWidth/2+10 ' LangVar$(25)=Выбор папок для поиска
		Width = 300'DirTreeFormSV.ClientWidth/2-20 ' LangVar$(26)=New
		TabOrder = 8         
		ColCount = 2 :RowCount =1
		Row = 0:col=1         
		DefaultColWidth =  16
		DefaultRowHeight = 16         
		FixedCols = 0 : FixedRows = 0
		colWidths(0)=17' ' LangVar$(27)=&Загрузить список файлов
		colWidths(1)=DirTreeFormSV.ClientWidth/2-50 ' LangVar$(28)=Load FileList
		
		OnDrawCell = DrawCell         
		OnSelectCell = SelectCell         
		'OnSetEditText = StringGrid1SetEditText     
		color=clSilver  
		ShowHint=1
		Separator="-----|"+lf ' LangVar$(30)=&Сохранить список файлов
	END CREATE ' LangVar$(31)=Save FileList
	
	CREATE BtnAddHotDir1 AS QBUTTON         
		Caption = LangVar$(21)          ' LangVar$(21)=Добавить в список 
		Left =4'' 350         
		Top = 14          ' 
		Width =120 ' ButtonSize ' 
		'Height = ButtonSize
		OnClick = BtnAddHotDirClick
		Spacing=1
		''            bmpHandle = AddHotDir
		' 
	END CREATE ' 
	
	CREATE BtnDelHotDir1 AS QBUTTON         
		Caption = LangVar$(22)          ' LangVar$(22)=Удалить из списка
		Left =140'' 480
		Top = 14         
		Width = 120             'ButtonSize         
		'             Height = ButtonSize     
		OnClick = BtnDelHotDirClick
		Spacing=1 ' 
		''             bmpHandle = DelHotDir '
	END CREATE
	CREATE OKDir AS QBUTTON         
		Caption ="Copy file" '
		Left =380'' 480
		Top = 14         
		Width = 120             'ButtonSize         
		'             Height = ButtonSize     
		OnClick = CopyFileTo
		Spacing=1 ' 
		enabled=1
		'visible=0
		''             bmpHandle = DelHotDir '
	END CREATE
	
	CREATE LabelDir AS QLABEL
		Caption = "":
		Left = 4:Top = 40:
		Transparent = 0
		Width = DirTreeFormSV.ClientWidth-15
		Height =15 ' 
		color=&hC1B597'&hE1D2C9 ' 
		Autosize=0
		
		''            OnClick = Label1Click: 
		''           OnDblClick = Label1DblClick
		''          OnMouseMove = Label1MouseMove
	END CREATE ' 
	' 
END CREATE 'dirform'

print" RQSV 739:=";

'- -----------------------------------------------------------------'
CREATE MainForm AS QFORM
	Caption = "RQ Advanced Search"
	Width =Screen.Width-5 ' е
	Height =Screen.Height*0.88 ' 
	KeyPreview = 1        'this line does the trick
	OnKeyPress = Check
	OnKeyDown = Check1 ' (Key AS Word, Shift AS INTEGER)
	Font.size=8
	WindowState=wsMaximized 
	AutoScroll=0
	'WndProc=FileListBoxWndProc
	' 
	'    Font.AddStyles=fsBold ' 
	''    OnClose=FrmClose
	'-- --------------------------------------------------'
	CREATE MainMenu1 AS QMainMenu
		CREATE FileMenu1 AS QMenuItem
			Caption = LangVar$(24) ' LangVar$(24)=&Файл
			'visible=1
			CREATE ChoosDir  AS QMenuItem
				Caption = LangVar$(25) ' LangVar$(25)=Выбор папок для поиска
				Hint = LangVar$(26) ' LangVar$(26)=New
				onclick=ChoosDirOnclick
				'visible=0
			END CREATE
			CREATE BreakItem1SV AS QMenuItem
				Caption = "-"
				'visible=0
			END CREATE
			CREATE OpenListMnu AS QMenuItem
				Caption = LangVar$(27) ' LangVar$(27)=&Загрузить список файлов
				Hint = LangVar$(28) ' LangVar$(28)=Load FileList
				OnClick=LoadFileList
				ShortCut="Ctrl+O"
				''   Checked=true
				'visible=0
				
			END CREATE
			CREATE SaveListMnu AS QMenuItem
				Caption = LangVar$(30) ' LangVar$(30)=&Сохранить список файлов
				Hint = LangVar$(31) ' LangVar$(31)=Save FileList
				OnClick=SaveFileList
				ShortCut="Ctrl+S"
				'visible=0
			END CREATE
			CREATE ValidateFileList AS QMenuItem
				Caption = LangVar$(104) ' LangVar$(104)=&Проверить актуальность списка ' LangVar$(51)=Настройки
				Hint = LangVar$(34) ' LangVar$(34)=Validate FileList
				OnClick=ValidFileList
				ShortCut="Ctrl+V"
				'visible=0
			END CREATE
			CREATE DeleteFileList AS QMenuItem
				Caption = LangVar$(36) ' LangVar$(36)=&Удалить список
				Hint = LangVar$(37) ' LangVar$(37)=Delete FileList
				OnClick=DelFileList
				ShortCut="Ctrl-Del"
				'visible=0
			END CREATE
			
			CREATE REmoveItemFromFileList AS QMenuItem
				Caption = LangVar$(22) ' LangVar$(36)=&Удалить список
				Hint = LangVar$(22) ' LangVar$(37)=Delete FileList
				OnClick=DeleteFromFilelistClick
				'ShortCut="Del"
				'visible=0
			END CREATE
			
			CREATE BreakItem AS QMenuItem
				Caption = "-"
				'visible=0
			END CREATE
			CREATE ExitItem1 AS QMenuItem
				Caption = LangVar$(38) ' LangVar$(38)=Выход
				Hint = LangVar$(39) ' LangVar$(39)=Exit
				ShortCut="Alt+X"
				OnClick=  exitProg ' LangVar$(55)=С учетом регистра
				'visible=0
			END CREATE
			CREATE BreakItem2SV AS QMenuItem
				Caption = "-"
				'visible=0
			END CREATE
			CREATE OpenFileMnu AS QMenuItem
				Caption ="Open File" ' LangVar$(41) ' LangVar$(41)=Сохранить файл
				Hint ="Open File" ' LangVar$(42) ' LangVar$(42)=SaveFile
				OnClick=OpenFile
				'ShortCut="Ctrl+O"
				'visible=0
			END CREATE
			
			CREATE SaveItemF AS QMenuItem
				Caption = LangVar$(41) ' LangVar$(41)=Сохранить файл
				Hint = LangVar$(42) ' LangVar$(42)=SaveFile
				OnClick=SaveFile
				ShortCut="Alt+S"
				'visible=0
			END CREATE
			CREATE SaveItemAs AS QMenuItem
				Caption = LangVar$(43) ' LangVar$(43)=Сохранить как ..
				Hint = LangVar$(44) ' LangVar$(44)=SaveFileAs..
				OnClick=SaveAsSV
				''      ShortCut="Alt+X"
				'visible=0 ' LangVar$(58)=Выбор языка
			END CREATE
			CREATE OpenIntextEdit AS QMenuItem
				Caption = LangVar$(101) ' LangVar$(101)=Открыть в текстовом редакторе
				Hint = LangVar$(103) ' LangVar$(103)=Open in notepad
				OnClick=OpenIntextEditClick
				''      ShortCut="Alt+S"
				'visible=1
			END CREATE
			CREATE OpenItemFolder AS QMenuItem
				Caption = LangVar$(102) ' LangVar$(102)=Открыть папку с файлом
				Hint = LangVar$(103) ' LangVar$(103)=Open in notepad
				OnClick=OpenItemFolderClick
				''      ShortCut="Alt+S"
				'visible=1
			END CREATE
			CREATE CopyFileNAmeMnu AS QMENUITEM
				Caption = LangVar$(35) ' LangVar$(35)=Копировать имя файла в буфер
				OnClick=CopyFileNAmeClick
				'visible=1
				
			END CREATE
			
		END CREATE
		
		CREATE EditMenu1 AS QMenuItem
			Caption = LangVar$(50) ' LangVar$(50)=&Edit
			visible=0'1
			Enabled=false
			
			'' disable=1
		END CREATE
		''     CREATE ProjectIt AS QMenuItem
		''        Caption = "Project"
		''        Hint = "Project"
		''        OnClick=OpenProject
		''      END CREATE
		
		''   CREATE SearchMenu AS QMenuItem
		''     Caption = "&Search"
		''   END CREATE
		
		CREATE Setup AS QMenuItem
			Caption = LangVar$(51) ' LangVar$(51)=Настройки
			''     OnClick=SaveIni  
			visible=1
			CREATE FileTipYes AS QMenuItem
				Caption = "Тип проверяемых файлов"
				''     OnClick=SaveIni  
				visible=0
			END CREATE
			CREATE FileTipNo AS QMenuItem
				Caption = "Тип исключаемых файлов"
				''     OnClick=SaveIni  
				visible=0
			END CREATE
			CREATE TextOnlyMnu AS QMenuItem
				Caption = "Text files only"
				OnClick=TextOnlyOnClick 
				checked=1 
				visible=0
			END CREATE
			CREATE CaseTip AS QMenuItem
				Caption = LangVar$(55) ' LangVar$(55)=С учетом регистра
				
				''     OnClick=SaveIni  
				visible=0
			END CREATE
			CREATE ArcFil AS QMenuItem
				Caption = "Проверять в архивах"
				''     OnClick=SaveIni
				visible=0
			END CREATE
			CREATE RtfFil AS QMenuItem
				Caption = "Search in RTF files"
				OnClick=RtfFilOnClick
				'visible=0
				Checked=0
			END CREATE
			CREATE LangMnu AS QMenuItem
				Caption = LangVar$(58) ' LangVar$(58)=Выбор языка ' LangVar$(68)=Сохранить настройки
				'OnClick=LangChoose
				visible=0
				CREATE LangMnuEn AS QMenuItem
					Caption = "English"
					OnClick=LangChoose
					visible=1 ' LangVar$(69)=Помощь
					RadioItem=1
					checked=1 ' LangVar$(70)=Справка
					
					
				END CREATE
				CREATE LangMnuRu AS QMenuItem
					Caption = "Russian"
					OnClick=LangChoose
					visible=1
					RadioItem=1
					checked=0 ' LangVar$(72)=Registration
					
				END CREATE
				
			END CREATE
			
		END CREATE
		
		CREATE CodTable AS QMenuItem ' LangVar$(74)=Registration Code
			Caption ="Encoding" '"Искать в кодировке"
			'RadioItem=true
			visible=1
			'CREATE CodAuto AS QMenuItem
			'Caption = "Автоматически"
			'OnClick=CodRBOnClick ' CodAutoOnClick   ' LangVar$(75)=О программе
			'checked=true
			'RadioItem=true
			'END CREATE
			CREATE CodWin1251Mnu AS QMenuItem
				Caption = "ANSI (Windows)"
				OnClick= CodRBOnClick ' CodWin1251OnClick 
				Checked=1
				'RadioItem=true
				''               checked=true
			END CREATE
			CREATE CodDosMnu AS QMenuItem
				Caption = "OEM (Dos)"
				OnClick=CodRBOnClick ' CodDosOnClick
				Checked=0
				'RadioItem=true
				''              checked=true
			END CREATE
			CREATE Koi8Mnu AS QMenuItem
				Caption = "Koi8r"
				OnClick=CodRBOnClick ' Koi8OnClick
				Checked=0
				'RadioItem=true
			END CREATE
			CREATE UTF8mnu AS QMenuItem ' LangVar$(76)=Выбор каталогов
				Caption = "UTF8"
				OnClick=CodRBOnClick ' Koi8OnClick
				Checked=0
				'RadioItem=true
			END CREATE
			CREATE UnicodMnu AS QMenuItem
				Caption = "Unicode"
				OnClick=CodRBOnClick ' Koi8OnClick
				Checked=0
				'RadioItem=true
				visible=0
			END CREATE
			CREATE EMailBug AS QMenuItem
				Caption = "EMail Bug"
				OnClick=CodRBOnClick ' EMailBugOnClick
				'RadioItem=true
				visible=0
			END CREATE
			CREATE HTMLUnicode AS QMenuItem
				Caption = "HTML Unicode"
				OnClick=CodRBOnClick ' EMailBugOnClick
				'RadioItem=true
				visible=0
			END CREATE
			
		END CREATE
		
		CREATE SaveGrid AS QMenuItem
			Caption = LangVar$(68) ' LangVar$(68)=Сохранить настройки
			OnClick=SaveIni1   ' LangVar$(77)=Начать поиск файлов
			'visible=0
		END CREATE
		
		CREATE Help1SV AS QMenuItem
			Caption = LangVar$(69) ' LangVar$(69)=Помощь
			CREATE HelpMain AS QMenuItem
				Caption = LangVar$(70) ' LangVar$(70)=Справка
				OnClick=Help2
			END CREATE
			CREATE HelpEnSV AS QMenuItem
				Caption = "Help (English)"
				OnClick=HelpEnglish
				visible=1 ' LangVar$(78)=Показать следующий файл
			END CREATE
			CREATE HelpReadMe AS QMenuItem
				Caption = "ReadMe"
				OnClick=Help3
			END CREATE
			
			CREATE HelpAboutSV AS QMenuItem
				Caption = LangVar$(75) ' LangVar$(75)=О программе
				OnClick=AboutClick
			END CREATE
		END CREATE
		
	END CREATE
	'-- --------------------------------------------------'
	CREATE ControlPanel AS QPANEL
		Width = MAinForm.Width-10
		Height =93' ' LangVar$(80)=Показать предыдущее совпадение
		'color=clred 
		
		
		CREATE DirBtn1 AS QButton
			Caption = ""
			Left =3
			Top = 3
			Spacing=2
			Width = ButtonSize
			Height = ButtonSize
			tag=22
			''      OnClick=FindTextSV'' Search1
			OnClick = btnClickSV ' LangVar$(81)=Показать предыдущий файл
			bmpHandle = sOpen
			hint=LangVar$(76) ' LangVar$(76)=Выбор каталогов
			ShowHint=1
		END CREATE
		CREATE SearchLbl AS QLabel         
			Left = 35         
			Top = 7         
			Width = 340 '385         
			''              Height = 99
			Font.name="Courier New"
			caption="Search"
		END CREATE
		
		CREATE SearchCBoxSV AS QCOMBOBOX         
			Text = ""         
			Left = 35         
			Top = 7         
			Width = 340 '385         
			''              Height = 99
			Font.name="FixedSys"
			DropDownCount = 9         
			'Sorted = 1      
			color=&HDCD7C3 
			onchange=SearchCBoxOnchange
			'OnDrawItem=SearchCBoxOnDrawItem  'SUB (Index%, State%, R AS QRect) 
			'style=csOwnerDrawVariable 'csOwnerDrawFixed 
			
			''             TabOrder = 10      ' LangVar$(82)=Приостановить поиск
		END CREATE
		CREATE StartSearchBtn AS QButton ' кнопка GO Начать поиск файлов
			Caption = ""
			Left =535
			Top = 3
			Spacing=2
			Width = ButtonSize+5
			Height = ButtonSize+10
			tag=0
			''      OnClick=FindTextSV'' Search1
			OnClick = btnClickSV
			hint=LangVar$(77) ' LangVar$(77)=Начать поиск файлов
			ShowHint=1
			bmpHandle = StartSearch
		END CREATE
		CREATE AddFilPan AS QPANEL
			Left = 730
			Top = 1
			'Caption = "Panel1"
			TabOrder = 8
			color=clr
			Width = ButtonSize+105
			Height = ButtonSize+10
			
			
			
			
			CREATE AddFilesBtn AS QBUTTON
				Caption = "Add found files"
				Left = 1
				Top = 1
				Left =5
				Top = 5
				Spacing=2
				font.size=10
				font.bold=1
				Width = ButtonSize+95
				Height = ButtonSize
				OnClick=AddFilesBtnOnClick
			visible=0
			END CREATE
			
		END CREATE
		
		CREATE NextFileBtn AS QButton ' LangVar$(83)=Остановить поиск
			Caption = ""
			Left =570
			Top = 3
			Spacing=2
			Width = ButtonSize
			Height = ButtonSize
			tag=22
			OnClick=NextFileOnCl
			hint=LangVar$(78) ' LangVar$(78)=Показать следующий файл
			ShowHint=1
			bmpHandle = NextFile
		END CREATE
		CREATE NextHitBtn AS QButton
			Caption = ""
			Left =600
			Top = 3
			Spacing=2
			Width = ButtonSize
			Height = ButtonSize
			tag=21
			OnClick=NextHitOnCl
			hint=LangVar$(79) ' LangVar$(79)=Показать следующее совпадение
			ShowHint=1
			bmpHandle =NextHit
		END CREATE
		CREATE PrevHitBtn AS QButton
			Caption = ""
			Left =630
			Top = 3
			Spacing=2
			Width = ButtonSize
			Height = ButtonSize
			tag=22
			OnClick=PrevHitOnCl
			hint=LangVar$(80) ' LangVar$(80)=Показать предыдущее совпадение
			ShowHint=1
			bmpHandle = PrevHit
		END CREATE
		CREATE PrevFileBtn AS QButton
			Caption = ""
			Left =660
			Top = 3
			Spacing=2
			Width = ButtonSize
			Height = ButtonSize
			tag=22
			OnClick=PrevFileOnCl
			hint=LangVar$(81) ' LangVar$(81)=Показать предыдущий файл
			ShowHint=1
			bmpHandle = PrevFile
		END CREATE
		CREATE PauseBtn AS QButton
			Caption = ""
			Left =690 ' LangVar$(87)=C учетом регистра 
			Top = 3
			Spacing=2
			Width = ButtonSize
			Height = ButtonSize
			tag=22
			''      OnClick=FindTextSV'' Search1
			hint=LangVar$(82) ' LangVar$(82)=Приостановить поиск
			ShowHint=1
			'bmpHandle = PauseSearch
			visible=0 ' LangVar$(88)=Только целые слова 
		END CREATE
		CREATE StopSearchBtn AS QButton
			Caption = ""
			Left =690'720
			Top = 1
			Spacing=2
			Width = ButtonSize+5
			Height = ButtonSize+10
			tag=22
			''      OnClick=FindTextSV'' Search1
			OnClick = StopS
			'BMP = "c:\BAS\RAPIDQ\STRP\sOpen.bmp"
			hint=LangVar$(83) ' LangVar$(83)=Остановить поиск
			ShowHint=1
			bmpHandle = StopSearch
		END CREATE
		CREATE MaskBoxYes AS QComboBox '==== маска
			Text = "*.*"
			Left = 4 '110
			Top = 35
			TabOrder = 2
			Width =245'168
			''               OnChange=check1
			'AddItems "*.txt", "*.*htm*", "*.", "*.*", "*.ctl"
			Font.name="Courier New"
			Font.size=9'10
			
		END CREATE
		CREATE ToolBar1 AS QPANEL
			Left = 3 '110
			Top = 58
			Width =246
			Height=18
			'Caption = "Panel1"
			'color=&HE9E9DF
			BorderStyle=bpNone
			BevelOuter  =bvnone
			BevelInner =bvnone
			ShowHint=1
			Create cmdOpenList AS QCOOLBTN
				Align = 3
				BMPHandle = OpenList
				Flat = 1
				Hint = "Open List"
				OnClick =LoadFileList ' Save_Click
				Width = 25
			End Create
			Create cmdSaveList AS QCOOLBTN
				Align = 3
				BMPHandle = SaveList
				Flat = 1
				Hint = "Save List"
				OnClick =SaveFileList ' Save_Click
				Width = 25
			End Create
			'Create Bar0 AS QCOOLBTN
			'Align = 3
			'Enabled = 0
			'Flat = 0
			'Width = 3
			'End Create
			
			Create cmdDelFromList AS QCOOLBTN
				Align = 3
				BMPHandle = DeleteFromList_BMP
				Flat = 1
				Hint = "Remove file from list"
				OnClick =DeleteFromFilelistClick  ' Save_Click
				Width = 25
			End Create
			
			Create cmdDelList AS QCOOLBTN
				Align = 3
				BMPHandle = DeleteList_BMP
				Flat = 1
				Hint = "Delete list"
				OnClick =DelFileList ' Save_Click
				Width = 25
			End Create
			'Create Bar10 AS QCOOLBTN
			'Align = 3
			'Enabled = 0
			'Flat = 0
			'Width = 3
			'End Create
			
			Create cmdNote AS QCOOLBTN
				Align = 3
				BMPHandle = NotBook_BMP
				Flat = 1
				Hint = "Open in NotePad"
				OnClick = OpenIntextEditClick
				Width = 25
			End Create
			
			Create cmdFolder AS QCOOLBTN
				Align = 3
				BMPHandle = Folder_BMP
				Flat = 1
				Hint = "Open Folder"
				OnClick =OpenItemFolderClick ' Open_Click
				Width = 25
			End Create
			
			
			
			Create cmdUndo1 AS QCOOLBTN
				Align = 3
				'BMPHandle = Undo_BMP
				Flat = 1
				Hint = "Undo"
				'OnClick = RichEditUndo
				Width = 25
			End Create
			
			
			Create cmdCut1 AS QCOOLBTN
				Align = 3
				'BMPHandle = Cut_BMP
				Flat = 1
				Hint = "Cut"
				'OnClick = RichEditCut
				Width = 25
			End Create
			
			Create cmdCopy1 AS QCOOLBTN
				Align = 3
				'BMPHandle = Copy_BMP
				Flat = 1
				Hint = "Copy"
				'OnClick = RichEditCopy
				Width = 25
			End Create
			
			Create cmdPaste1 AS QCOOLBTN
				Align = 3
				'BMPHandle = Paste_BMP
				Flat = 1
				Hint = "Paste"
				'OnClick = RichEditPaste
				Width = 25
			End Create
			
			
		END CREATE
		
		CREATE ChBoxCase AS QCHECKBOX
			Caption = LangVar$(87) ' LangVar$(87)=C учетом регистра 
			Left =MaskBoxYes.Left+MaskBoxYes.Width+5 ' 180'250
			Top = 32'125
			Width =125
			font.color=clDBlue
			checked=1 'false ' LangVar$(91)=Просмотр..
			'OnClick = CBoxLogClick
		END CREATE
		
		CREATE ChBoxWholeW AS QCHECKBOX
			Caption = LangVar$(88) ' LangVar$(88)=Только целые слова  ' LangVar$(92)=Text
			Left =MaskBoxYes.Left+MaskBoxYes.Width+5 '
			Top = 47'125
			Width =125
			font.color=clDBlue
			checked=false
			'OnClick = CBoxLogClick
			visible=1
		END CREATE
		
		CREATE ChBoxArc AS QCHECKBOX
			Caption = "Check archieves"
			Left =MaskBoxYes.Left+MaskBoxYes.Width+5 
			Top = 61'125
			Width =125
			font.color=clDBlue
			checked=true
			visible=1
			'OnClick = CBoxLogClick
		END CREATE
		
		''        CREATE LabelV AS QLABEL
		''    Caption = "-- Вид --":
		''    Left = 420:Top = 44:
		''    Transparent = 0
		''    Width = 50
		''    Height =15
		''     Angle=90
		''     Autosize=true
		''     Font = Font
		' LangVar$(95)=Переносить слова 
		'OnClick = Label1Click: 
		'OnDblClick = Label1DblClick
		'OnMouseMove = Label1MouseMove
		''    END CREATE
		
		
		CREATE CurFileLabel AS QLABEL
			Caption = LangVar$(90) ' LangVar$(90)=FileName
			Left = 5'40 ' LangVar$(96)=Список строк 
			Top = 60
			Transparent = 1
			autosize=1
			visible=0
		END CREATE
		
		
		''    CREATE ChBoxPlainTxt AS QCHECKBOX
		''        Caption = "Только текст "
		''        Left =450
		''        Top = 55'125
		''        Width =150
		''        font.color=clDRed
		''        checked=true
		''        OnClick = ChBoxPlainTxtClick
		''    END CREATE
		' LangVar$(97)=Обновить список строк
		''    CREATE ChBoxHTML AS QCHECKBOX
		''        Caption = "HTML код "
		''       Left =550
		''       Top = 55'125
		''       Width =150
		''       font.color=clDRed
		''       checked=true
		''       OnClick = ChBoxHTMLClick
		''   END CREATE
		
		
		CREATE Panel1 AS QGroupBox'' QPANEL         
			Left =SearchCBoxSV.Left+SearchCBoxSV.Width+5 ' 423         
			Height = 75
			Width = 150
			Top = 1         
			Caption = LangVar$(91)      ' LangVar$(91)=Просмотр..
			TabOrder = 6     
			'color= clSilver
			
			CREATE RBPlainTxt AS QRADIOBUTTON          ' LangVar$(99)=DoubleClick 
				Caption = LangVar$(92)          ' LangVar$(92)=Text
				Left = 5         
				Top = 15
				Width = 40       
				TabOrder = 51     
				Checked=true
				OnClick=ChBoxHTMLClick
			END CREATE
			' LangVar$(100)=DoubleClick - start this file
			CREATE RBRtf AS QRADIOBUTTON         
				Caption = "RTF"         
				Left =RBPlainTxt.Left+RBPlainTxt.Width+ 5         
				Top =RBPlainTxt.top ' 36         
				Width = 40        
				TabOrder = 52     
				OnClick=ChBoxHTMLClick
			END CREATE
			
			CREATE RBasFormat AS QRADIOBUTTON         
				Caption = "HTML"     
				Left =RBRtf.Left+RBRtf.Width+ 5         
				Top =RBRtf.top ' 36         
				'Left = 5         
				'Top = 54         
				Width = 50        
				TabOrder = 53     
				OnClick=ChBoxHTMLClick
			END CREATE
			CREATE ChBoxWrap AS QCHECKBOX
				Caption = LangVar$(95) ' LangVar$(95)=Переносить слова 
				Left =5 ' 540
				Top =RBRtf.top +17 ' 37'125
				Width =135
				font.color=clDRed
				'checked=true
				OnClick = ChBoxWrapClick
			END CREATE
			CREATE ListOfSearchChBoxSV AS QCHECKBOX
				Caption = LangVar$(96) ' LangVar$(96)=Список строк 
				Left =5 ' 540
				Top =ChBoxWrap.top +20 ' 37'125
				Width =100'35
				font.color=clDRed
				'checked=true
				OnClick = ListChBoxClick
			END CREATE
			CREATE ListOfSearchBtn AS QCoolBtn
				Caption = ""
				Left =ListOfSearchChBoxSV.left+ListOfSearchChBoxSV.width+3
				Top = ChBoxWrap.top +17
				Spacing=2
				Width =22 ' ButtonSize
				Height =22 ' ButtonSize
				tag=21
				OnClick=refreshList
				hint=LangVar$(97) ' LangVar$(97)=Обновить список строк
				ShowHint=1
				bmpHandle =refresh
				Flat=1
			END CREATE
			
			
		END CREATE
		
		CREATE SearchInFound AS QCHECKBOX
			Caption = "Искать в найденном "
			Left =Panel1.Left+Panel1.Width+5 ' 180'250
			Top = 40'125
			Width =125
			font.color=clDBlue
			checked=false
			'OnClick = CBoxLogClick
			visible=0
		END CREATE
		
		CREATE FNameLabel AS QLABEL '"FNameLabel"'
			Caption =LangVar$(99)'' + FileEdit.Item(ItemIndex) ' LangVar$(99)=DoubleClick  ' LangVar$(101)=Открыть в текстовом редакторе
			Left =4 
			Top =78
			Width = mainform.width
			Autosize=false
			color=clYellow
			font.color=clDRed'REd
			OnDblClick=StartFile
			ShowHint=true ' LangVar$(102)=Открыть папку с файлом
			Hint=LangVar$(100) ' LangVar$(100)=DoubleClick - start this file ' LangVar$(103)=Open in notepad
		END CREATE
	END CREATE
	
	CREATE FilesPanel AS QPANEL
		top=95 ' LangVar$(104)=&Проверить актуальность списка
		Width = MAinForm.Width-10
		Height =MAinForm.ClientHeight-100
		color=cldg
		
		
		CREATE FileEditPanel AS QPANEL
			'color=clred ' LangVar$(105)=Копировать имя файла в буфер
			align=alclient 'alright'
			'Width = MAinForm.Width-228
			
			CREATE FileEdit AS QRICHEDIT '=== просмотр файлов
				align=alclient
				ScrollBars = 3
				font.color=0
				font.size=10
				'font.name="Courier New"
				HideSelection=false
				TabOrder=11
				color=clWindow 'clW 
				'Plaintext=true
				OnMouseDown=RichEditOnMouseDown
				OnKeyDown=SrcEditOnKeyDown
				OnKeyUp=SrcEditOnKeyUp
				'readonly=1
				
			END CREATE
			CREATE Explorer AS QOLECONTAINER
				align=alclient
				visible=false
			END CREATE ' LangVar$(106)=Всего файлов 
		END CREATE
		
		CREATE SplitterV22 AS QSPLITTER '-- Note position
			Align =    alLeft 'alright' alClient ''        '-- Fill middle
			Cursor = crHSplit
			'Height = 5
			Width = 5
			color=clGreen ' LangVar$(107)=Найдено 
			'OnMoved=SplitterV2Moved
		END CREATE
		
		CREATE FileListPanel1 AS QPANEL
			align=alLeft ' alCLient '
			Width = MAinForm.Width*0.3
			color=clred
			' LangVar$(108)=Осталось 
			'CREATE FileListBoxPanel AS QPANEL
			'align=alclient
			'color=clb
			CREATE FileListBox AS QListBox '=== список файлов =====
				align=alClient
				color=&HF2FFE7  'clWindow '
				Font=Font1
				OnClick=FileClickSV  ' FileClick FileLoadSV
				tag=32
				TopIndex=5
				'style=lbOwnerDrawFixed  ' LangVar$(109)=Прошло 00:00:00
				ItemHeight=22
				MultiSelect=1
				'WndProc=FileListBoxWndProc ' SUB (Hwnd%, Msg%, wParam%, lParam%) 
				'Columns=3
				
				'BorderStyle=1'0'bsSizeToolWin '3'1
				'Columns=2
				CREATE FileListPopUp AS QPOPUPMENU
					OnPopup=OnFileListPopUp
					CREATE OpenInTxtEdit AS QMENUITEM
						Caption = LangVar$(101) ' LangVar$(101)=Открыть в текстовом редакторе ' LangVar$(110)=Осталось 00:00:00
						'Hint = "Open in notepad"
						OnClick=OpenIntextEditClick
						''      ShortCut="Alt+S"
						'visible=1
					END CREATE
					
					CREATE OpenItemFolderPOP AS QMENUITEM
						Caption = LangVar$(102) ' LangVar$(102)=Открыть папку с файлом
						Hint = LangVar$(103) ' LangVar$(103)=Open in notepad
						OnClick=OpenItemFolderClick
					END CREATE
					
					CREATE ValidFile AS QMENUITEM
						Caption = LangVar$(104) ' LangVar$(104)=&Проверить актуальность списка
						'Hint = "Validate FileList"
						OnClick=ValidFileList
						'ShortCut="Ctrl+V" копировать полное имя файла в буфер
					END CREATE
					
					CREATE CopyFileNAme AS QMENUITEM
						Caption = LangVar$(105) ' LangVar$(105)=Копировать имя файла в буфер
						OnClick=CopyFileNAmeClick
					END CREATE
					CREATE DeleteFromFilelist AS QMENUITEM
						Caption = "Delete from filelist"
						OnClick=DeleteFromFilelistClick
						'ShortCut="Del"
					END CREATE
					CREATE CopyFile2Folder AS QMENUITEM
						Caption = "Copy File to Folder"
						OnClick=CopyFile2FolderClick
					END CREATE
					
				END CREATE
			END CREATE
			
			
		END CREATE 'FileListPanel
		' LangVar$(112)=Row  ' LangVar$(113)=Row  ' LangVar$(111)=Row 
		CREATE LogEditPanel AS QPANEL
			align= albottom
			height=280
			
			create PanelLog AS QPanel
				height=60
				width=210
				align=alleft
				borderstyle= bvLowered
				color=&h4B4646'&hBFF3C1'&h6A282A
				
				CREATE LogLabel1 AS QLABEL '"Всего файлов'
					Caption = LangVar$(106)+str$(NumFiles) ' LangVar$(106)=Всего файлов 
					Left =4
					Top = 25-21
					Autosize=1
					font.color=clYellow 'LtBlue
				END CREATE
				
				CREATE LogLabel2 AS QLABEL '"Проверено "
					Caption = LangVar$(107)+str$(NumProv) ' LangVar$(107)=Найдено 
					Left =4
					Top = 40-21
					Autosize=1
					font.color=clGreen
				END CREATE
				
				
				CREATE LogLabel3 AS QLABEL'"Осталось "+str$(NumProv)+" файлов"'
					Caption = LangVar$(108)+str$(NumProv) ' LangVar$(108)=Осталось 
					Left = 4 +110
					Top =  25-21
					Autosize=1
					font.color=clRed'&h7E7AFF'clPurple'' Yellow
					'        Width = 48
					''        Height = 21 NumOst
					visible=0
				END CREATE
				
				CREATE LogLabel4 AS QLABEL'"Прошло "+str$(NumTime)'
					Caption = LangVar$(109) ' LangVar$(109)=Прошло 00:00:00
					Left =4
					Top = 55-21
					Autosize=1
					font.color=clYellow 'LtBlue
				END CREATE
				CREATE LogLabel5 AS QLABEL '"Осталось 00:00:00"'
					Caption = LangVar$(110) ' LangVar$(110)=Осталось 00:00:00
					Left =4+94
					Top = 55-21
					Autosize=1
					font.color=clLBlue
					visible=1
				END CREATE
				CREATE LogLabel6 AS QLABEL '"Осталось 00:00:00"'
					Caption = LangVar$(110) ' LangVar$(110)=Осталось 00:00:00
					Left =4+94
					Top = 55
					'Autosize=1
					color=clo
					font.color=0'clLBlue
					visible=0
				END CREATE
				
			END CREATE '=== панель лога
			
			CREATE LogEditSV AS QRICHEDIT '=== просмотр файлов
				align=alclient
				Wordwrap=false
				'color=&hdBf6f6'clDBlue'
				ScrollBars = 3
				'Font.Color=clGreen'clRed
				HideSelection=false
				'TabOrder=111
			END CREATE
			
			CREATE TmpRichEdit AS QRICHEDIT
				visible=0
			END CREATE
			
			
		END CREATE
		
	END CREATE ' !!!--- filesPanel
	
	create  StatusBarSV AS QSTATUSBAREX 'QStatusBar
		AddPanels LangVar$(112), "Col ", LangVar$(113),"Asc ", "EOL ","" ' LangVar$(112)=Row  ' LangVar$(113)=Row  ' LangVar$(111)=Row 
		Panel(0).Width = 105
		Panel(1).Width = 60  
		Panel(2).Width = 120  
		Panel(3).Width = 45  
		Panel(4).Width = 100  
		'Panel(4).Width = 135  
		Panel(5).Width = 800  
		'Panel(0).Alignment = taCenter
		'AddOptPanel PanelSt,5 
	END CREATE
	
END CREATE '=== форма'  

'!!! ---Insert your initialization code here ===================
'FileListBox.WndProc=FileListBoxWndProc
'= ====================================='
'!!! = ======= директория запуска программы ================
'DirTreeSV.InitialDir=curdir$ '- директория запуска программы
StartDir=curdir$
print"1731:StartDir=";StartDir

'OpenDialog.InitialDir=StartDir
'!OpenDialog.Filter = "File list *.lst|*.lst|All Files *.*|*.*|"

'SaveDialog.InitialDir=StartDir
SaveDialog.Filter = "File list *.lst|*.lst|All Files*.*|*.*|"


defint MaskBoxYesHnd, MaskBoxNoHnd,SearchCBoxHnd 


'!!!  инициализация настроек

if prjfindFlg=0 then LoadIni1
'SelDirGrid.Repaint

if ChBoxWrap.checked=true   then
	FileEdit.Wordwrap=true 
else
	FileEdit.Wordwrap=false
end if

'- ----------------------------------------
'100         50   1500   1534

' Timer1SV.Enabled =1
'print"1860:Timer1SV.Enabled=";Timer1SV.Enabled

declare sub TimerOverSV4 
TimerSV4.Interval = 600 
TimerSV4.Enabled =0 '1 'True 
TimerSV4.OnTimer = TimerOverSV4

'TimerSV3.Enabled = 1
vdr$ = "111"


'MainForm.ShowModal
'===============================================================

'*****************************************
SUB TimerOverSV 
' Timer1SV.Interval = 400 
if DirTreeFormSV.Visible=1 then
	SelDirGrid.Left = DirTreeFormSV.ClientWidth/2+10
	SelDirGrid.Width = DirTreeFormSV.ClientWidth/2-20
	SelDirGrid.Height =DirTreeFormSV.ClientHeight -65
	SelDirGrid.colWidths(1)=DirTreeFormSV.ClientWidth/2-50
	labeldir.Width = DirTreeFormSV.ClientWidth-10
end if

if startonceFlg=0 then
	'!!! - определяем хэндлы комбобоксов
	'?????? а можно ли устанавливать фокус если форма не отрисована??
	
	Setfocus(MaskBoxYes.handle):  MaskBoxYesHnd = GetFocus()
	'call  AddClrString ("1787:MaskBoxYesHnd="+str$(MaskBoxYesHnd), clred, LogEditSV)
	Setfocus(MaskBoxNo.handle):     MaskBoxNoHnd = GetFocus()
	'call  AddClrString ("1789:MaskBoxNoHnd="+str$(MaskBoxNoHnd), clred, LogEditSV)
	Setfocus(SearchCBoxSV.handle):     SearchCBoxHnd = GetFocus()
	'call  AddClrString ("1791:SearchCBoxHnd="+str$(SearchCBoxHnd), clred, LogEditSV)
	
	startonceFlg=1
end if

zzz=GetfOCUS()

if zzz=FileListBox.handle then
	'REmoveItemFromFileList.ShortCut="Del"
else
	'REmoveItemFromFileList.ShortCut=""
end if

if ScreenWidth<>Screen.Width or ScreenHeight<>Screen.Height then
	ScreenWidth=Screen.Width
	ScreenHeight=Screen.Height
	
	MAinForm.Width =ScreenWidth-5
	MAinForm.Height =ScreenHeight*0.88
	
end if

FilesPanel.Width = MAinForm.Width-10
FilesPanel.Height =MAinForm.ClientHeight-100
ControlPanel.Width = MAinForm.Width-10

FNameLabel.Width = ControlPanel.width-7
'FileEditPanel.Width =FilesPanel.Width- FileListPanel.Width

'' RichRow1=str$(FileListBox.WhereY+1)
'' RichCol1=str$(FileListBox.WhereX+1)
'LogLabel1.Caption = "Всего файлов "+str$(NumFiles)
TimerOverSV2

MainForm.Caption = RQversion$+"                              "+dateR+"   "+Time$
END SUB

print"1929:MainForm.Caption=";MainForm.Caption

'*****************************************
Sub btnClickSV (Sender as Qbutton)
'LogEditSV.addstring "1831:btnClickSV="
'call  AddClrString ("1832:btnClickSV=", clred, LogEditSV)
Select Case Sender.Tag
Case 0
	if SearchInFound.checked=0 then
		'call  AddClrString ("1836:Main="+str$(Main), clred, LogEditSV)
		Call Main    ' GO Start Начать поиск файлов!!!
	else
		'call  AddClrString ("1839:SearchInF="+str$(SearchInF), clred, LogEditSV)
		call SearchInF
		
	end if
	''        Case 1: Call     ChangeDirectory                        ' New
	''        Case 21: Call FindTextSV (Sender )
Case 22:    
	DirTreeFormSV.show:
	DirTreeSV.InitialDir = CurDir$
	'Case 3: Call  MaskChange                     ' Delete
	
End Select
End Sub

'*****************************************
sub Main '===== ' GO Start Начать поиск файлов!!!
'call  AddClrString ("1855:Main=", clred, LogEditSV)
DIM TmpFileSL AS QStringList
DIM fileStr as QFileStream

'LogEditSV.Clear
FileEdit.Clear
FileListBox.Clear 'список файлов, содержащих

NumFiles=0 'всего проверяемых файлов 
call  AddClrString ("1864:NumFiles="+str$(NumFiles), 0, LogEditSV)
NumProv=0  'число проверенных файлов 
NumOst=0   'осталось проверить
NumHit=0   'найдено файлов
adddir=0

SearchCBoxText$=replacesubstr$(SearchCBoxSV.Text,chr$(183)," ") 'chr$(149)
'call  AddClrString ("1871:SearchCBoxText$="+(SearchCBoxText$), clred, LogEditSV)
TimerSV3.Enabled = 1

'kill "filelist"
if ChBoxCase.Checked =true then
	SSR$= (SearchCBoxText$)
	
else
	SSR$=CharLower (SearchCBoxText$) ' 
	call  AddClrString ("1880:SSR$="+(SSR$), clb, LogEditSV)
	'SearchCBoxSV.Text=SSR$
end if

lenssr=len(ssr$) ' сохраняем исходный образец поиска 
ssrOrig$=ssr$+"----"
ssrOrig$=left$(ssrOrig$,lenssr)

goto nxxx
'!!! --- подготавливаем образцы поиска в заданных кодировках ---

nxxx:


timeBeg=timer
print"1897:timeBeg=";timeBeg


with SelDirGrid ' таблица со списком директорий, где искать
	'.Cell(1, si)=
	for si=0 to .RowCount-1 ' перебираем по списку директорий из DirTreeSV.
		if .Cell(0, si)="1" then
			'' FindInDir$=chr$(34)+ .Cell(1, si)+chr$(34) '+ MaskBoxYes.text'
			FindInDir$= .Cell(1, si)
			call  AddClrString ("1903:FindInDir$="+(FindInDir$), cldred, LogEditSV)
			
		else
			goto  nextSel
		end if
		'- godirs --------- поиск файлов в поддиректориях ---------
		
		defint nsd1, nsd2
		defstr mask
		nsd1=0: nsd2=0: NumDir=0: ArrNumDir=500
		dim SubDir(0) as string
		IniDir$ =FindInDir$ 
		'mask="*"
		mask="*.*"
		
		SubDir(0)=IniDir$
		
		2155:
		for i=NSD1 to Nsd2 'перебираем по директориям текущего уровня'
			SubDirname$=dir$(SubDir(i)+mask, faDirectory or faReadOnly or faHidden  or faSysFile)
			
			while    SubDirname$ <>""
				if FileRec.Size =0 and SubDirname$<> "." and SubDirname$<> ".." then ' наверное директория
					attr=GetFileAttributes(SubDir(d)+SubDirname$) 
					SubDirN$=SubDirname$
					If (attr And FILE_ATTRIBUTE_DIRECTORY)=0 Then goto nodir  ' нет
					
					inc adddir
					inc NumDir 'добавляем субдиректорию'
					if NumDir=ArrNumDir then ArrNumDir=ArrNumDir+300: redim SubDir(ArrNumDir) as string
					SubDir(NumDir)=SubDir(i)+SubDirname$+"\"
					'call  AddClrString ("1934:SubDir("+str$(NumDir)+")="+(SubDir(NumDir)), clred, LogEditSV)
					'LogEditSV.AddStrings "SubDir(NumDir)="+ SubDir(NumDir)
				else
				end if
				nodir:
				SubDirname$=dir$
				doevents:if stops1=1 then stops1=0: exit sub
			wend
			
			'search files in current subdirectory
			' разбираем MaskBoxYes.Text с несколькими маскамиif instr(secFileStr3$ ,RegStringGrid.cell(0, 0)  )=0 then 
			'if instr(secFileStr3$ ,RegStringGrid.cell(0, 0)  )=0 then 
			'MaskCount=1
			'else
			'MaskCount=tally(MaskBoxYes.Text,";")+1
			'end if
			
			MaskCount=tally(MaskBoxYes.Text,";")+1
			for midx=1 to MaskCount
				doevents:if stops1=1 then stops1=0: exit sub
				curMask$=field$(MaskBoxYes.Text,";",midx) ' LangVar$(106)=Всего файлов 
				'call  AddClrString ("1955:curMask$="+(curMask$), clb, LogEditSV) ' LangVar$(119)=Найдено
				if curMask$=""  then exit for ' LangVar$(108)=Осталось 
				'!Fn$=dir$(SubDir(i)+curMask$,faAnyFile not faDirectory) ':-)  ' LangVar$(121)=Прошло 
				Fn$=dir$(SubDir(i)+curMask$,0) ':-)  ' LangVar$(121)=Прошло 
				
				while Fn$ <>"" '= ===================' ' LangVar$(108)=Осталось 
					
					fn1$=SubDir(i)+Fn$ 'имя найденного файла '
					FileRecSize=FileRec.Size
					if FileRec.Size=0 then goto nocheckfile
					
					'attr=GetFileAttributes(SubDir(i)+Fn$) 
					'attrch=attr And FILE_ATTRIBUTE_DIRECTORY
					
					if  Fn$<> "." and Fn$<> ".." and( (attrch)=0)  then 'and  FILEEXISTS(fn1$)<>0
						inc NumFiles
						FNameLabelcaption$=fn1$+" "+str$(FileRec.Size)+" bytes"
						'call  AddClrString ("1972:FNameLabelcaption$="+(FNameLabelcaption$), clred, LogEditSV)
						'файл найден!!! добавляем его в список ! 
						
						doevents:if stops1=1 then stops1=0: exit sub 'while
						
						'FNameLabel.caption=fn1$+" "+str$(FileRec.Size)+" bytes"
						'goto nocheckfile
						MaskFN$=lcase$(STRIPFILEEXT(fn$))' ! маски которые не надо проверять
						if instr(MaskBoxNo.text,MaskFN$)>0   then goto nocheckfile
						
						'call  AddClrString ("1982:MaskFN$="+(MaskFN$), clred, LogEditSV)
						Signature$=LoadBinString(fn1$ , 256)
						
						if TextOnlyMnu.checked=0 then
							'!!!! TmpFileSLtext$=Replacesubstr(TmpFileSLtext$,chr$(0), chr$(176))
						else
							
							'!if instr(Signature$,chr$(0))>0 then binaryf=1: goto nocheckfile else binaryf=0
						end if
						'call  AddClrString ("1991:Signature$="+(left$(Signature$,5)), clred, LogEditSV)
						
						'!!! --- проверка файла на доступ ---
						if Signature$="0"  then
							call  AddClrString ("1995: Can't open file "+fn1$, clr, LogEditSV)
							goto nocheckfile
						end if
						
						'if instr(MaskBoxNo.text,STRIPFILEEXT(fn1$))>0   then goto nocheckfile 'or instr(MaskBoxYes.text,STRIPFILEEXT(fn1$))=0
						
						'!!! ------  Здесь вставим операцию обработки найденных файлов ----------'
						if RtfFil.checked=1  and  instr(Signature$,"{\rtf")>0 then
							if CheckFileWr (fn1$)<>-1 then
								call  AddClrString ("2004: Can't open file "+fn1$, clr, LogEditSV)
								goto nocheckfile
							end if
							TmpRichEdit.LoadFromFile (fn1$)
							TmpFileSLtext$=TmpRichEdit.text
							'result1= SendMessageAPI (TmpRichEdit.handle,EM_EXLIMITTEXT,0,65535*32)
							
						else
							'call  AddClrString ("2012: Загружаем файл "+(fn1$)+"   size="+str$(FileRec.Size), clred, LogEditSV)
							
							TmpFileSLtext$=loadbinstring(fn1$,FileRec.Size)
							'call  AddClrString ("2015: Loaded... ", clred, LogEditSV)
							
							if TextOnlyMnu.checked=0 then  
								'call  AddClrString ("2018: Заменяем zero символы... ", clred, LogEditSV)
								'TmpFileSLtext$=Replacesubstr$(TmpFileSLtext$,chr$(0), chr$(176))
								'call  AddClrString ("2020: Заменены... ", clred, LogEditSV)
							end if
						end if
						TmpFileSLtextCP$=TmpFileSLtext$ ' сохраняем копию 
						'call  AddClrString ("2024:TmpFileSLtextCP$="+left$(TmpFileSLtextCP$,40), clred, LogEditSV)
						
						'!!! ---------------- ищем вхождение -----------------'
						
						searchSSR:
						
						for ip=0 to CodTable.count-1 ' codePcount-1 ' !!!--- перебираем по кодировкам --- 
							TmpFileSLtext$=TmpFileSLtextCP$ ' восстанавливаем файл из копии
							call convert(ip)
							if ChBoxCase.Checked =true then
								
							else
								TmpFileSLtext$=CharLower (TmpFileSLtext$+"+") ' 
							end if
							
							if NoSearch=1 then NoSearch=0: goto nxtbl3:
							'ssr$=CPssr(ip)
							bzzz=instr(TmpFileSLtext$, ssr$) ' первая позиция
							
							if ssr$="" then 
								bzzz=1
								FileListBox.AddItems  fn1$ +chr$(160)+codp$+chr$(160)+str$(FileRec.Size) +chr$(160)+FileRec.Date+chr$(160)+FileRec.Time
								inc NumHit
								goto nxtbl3 'nocheckfile
							end if
							
							'call  AddClrString ("2050:bzzz="+str$(bzzz), clb, LogEditSV)
							doevents:if stops1=1 then stops1=0: exit sub 'while
							
							while bzzz>0
								doevents:if stops1=1 then stops1=0: exit sub 'while
								
								
								if bzzz>0 or ssr$="" then  
									if ChBoxWholeW.checked=1 then ' если только целые слова 
										'call  AddClrString ("2059:bzzz="+str$(bzzz), clred, LogEditSV)
										ezzz=bzzz+len(ssr$)-1 ' последняя позиция
										b0$=TmpFileSLtext$[bzzz-1]
										'call  AddClrString ("2062:b0$="+(b0$), cla, LogEditSV)
										e0$=TmpFileSLtext$[ezzz+1]
										'call  AddClrString ("2064:e0$="+(e0$), cla, LogEditSV)
										if (instr(noletter$, b0$)>0 ) and instr(noletter$,e0$ )>0 then '' это целое слово
											FileListBox.AddItems  fn1$ +chr$(160)+codp$ ' Fn$ если просто имя файла, то не находит без пути
											inc NumHit
											'goto nocheckfile:
											exit while
										else 
											
										end if
									else
										FileListBox.AddItems  fn1$ +chr$(160)+codp$
										inc NumHit
										'call  AddClrString ("2076:NumHit="+str$(NumHit), clred, LogEditSV)
										'goto nocheckfile:
										AlreadyFound=1
										exit while
									end if
								else
									
									
								end if
								'LogEditSV.AddStrings  ssr$
								'bzzz=instr(ezzz,TmpFileSLtext$,ssr$) 
								'call  AddClrString ("2087:bzzz="+str$(bzzz), clg, LogEditSV)
								'ezzz=bzzz+len(ssr$)-1
								'call  AddClrString ("2089:ezzz="+str$(ezzz), clg, LogEditSV)
								
								'-- если первая позиция - не целое слово, то ищем следующее вхождение и проверяем на целое слово
							wend
							nxtbl3:     
							if AlreadyFound=1 then AlreadyFound=0 : exit for ' уже нашли по другим кодировкам не перебираем
							'!!! ---  проверяем другие кодировки --------
						next ip
					else
						'LogEditSV.AddStrings "Не найден файл"+FNameS$
					end if
					
					nocheckfile:
					Fn$=dir$
					'call  AddClrString ("2103:Fn$="+(Fn$), clred, LogEditSV)
				wend '= ==================='
			next midx ' next mask idx
			'speed1=NumProv/((Timer-TimeBeg)+1)
			speed1=NumFiles/((Timer-TimeBeg)+1)
			Speed = round(speed1)
			NumOst=NumFiles - NumProv
			''        TimeOst=NumOst/Speed1
			TimeOst1$=TimeString(TimeOst)
			'!LogLabel1.Caption = LangVar$(106)+str$(NumFiles) ' LangVar$(106)=Всего файлов 
			'!LogLabel2.Caption = LangVar$(119)+str$(NumHit)+"   "+str$(Speed)+LangVar$(116) ' LangVar$(116)=" файлов/с " ' LangVar$(116)=Найдено  ' LangVar$(119)=Найдено
			'!LogLabel3.Caption = LangVar$(108)+str$(NumOst) ' LangVar$(108)=Осталось 
			'!LogLabel4.Caption = LangVar$(121)+TimeString(Timer-TimeBeg)+"  "+ ' LangVar$(121)=Прошло 
			'!LogLabel5.Caption = LangVar$(108) +TimeOst1$+"   " ' LangVar$(108)=Осталось 
			'LogLabel6.Caption = SubDirN$
			'call  AddClrString ("2118:SubDirN$="+(SubDirN$), clred, LogEditSV)
			
		next i
		
		if adddir>0 then
			NSD1=NSD2+1 'начальный номер директорий очередного уровня вложенности'
			NSD2=NSD2+adddir ''конечный номер директорий очередного уровня вложенности'
			adddir=0
			goto 2155 'повторяем с новым уровнем
		else
		end if
		
		'- --------------------------------------------------------------------'
		'e1:
		nextSel:
	next si
	
end with   

'!!!!PLAYWAV Zvon, SND_ASYNC 
'call  AddClrString ("2138:PLAYWAV=", clred, LogEditSV)
If FileListBox.ItemCount>0 then
	LogLabel3.Caption =LangVar$(107)+str$(FileListBox.ItemCount)'+" файлов" ' LangVar$(107)=Найдено 
	FileListBox.ItemIndex=0
	cFileName=field$(FileListBox.Item(FileListBox.ItemIndex),chr$(160),1)
	'call  AddClrString ("2143:cFileName="+(cFileName), clred, LogEditSV)
	if fileexists(cFileName)>0 then
		call FileLoadSV (cFileName)
	end if
else
	LogLabel3.Caption ="No files found"
end if
call  AddClrString ("2150: Search complete", clb, LogEditSV)
LogLabel1.Caption = LangVar$(106)+str$(NumFiles) ' LangVar$(106)=Всего файлов 
LogLabel2.Caption = LangVar$(119)+" "+str$(NumHit)+"   "+str$(Speed)+LangVar$(116) ' LangVar$(116)=" файлов/с " ' LangVar$(116)=Найдено  ' LangVar$(119)=Найдено
LogLabel3.Caption = LangVar$(108)+str$(NumOst) ' LangVar$(108)=Осталось 
LogLabel4.Caption = LangVar$(121)+TimeString(Timer-TimeBeg)+"  "+ ' LangVar$(121)=Прошло 
LogLabel5.Caption = "Search complete" 'LangVar$(108) +" "+TimeOst1$+"   " ' LangVar$(108)=Осталось 
FNameLabel.caption=FNameLabelcaption$

TimerSV3.Enabled = 0

if instr(MaskBoxYes.Text,"*")>0 or instr(MaskBoxYes.Text,"?")>0 then sortflg=0

if sortflg=0 then goto nosrt33

' сортируем полученый список файлов
' перебираем по дизабленным окнам - по маскам  !

dim Tmpflist as QStringList
Tmpflist.clear


MaskCount=tally(MaskBoxYes.Text,";")+1
print"2175:MaskCount=";MaskCount
'call  AddClrString ("2172:MaskCount="+str$(MaskCount), clred, LogEditSV)
for msidx=1 to MaskCount
	'doevents:if stops1=1 then stops1=0: exit sub
	curMask$=Lcase$(field$(MaskBoxYes.Text,";",msidx)) ' LangVar$(106)=Всего файлов 
'call  AddClrString ("2176:curMask$="+(curMask$), clred, LogEdit)

'call  AddClrString ("2178:FileListBox.ItemCount="+str$(FileListBox.ItemCount), clm, LogEdit)
	
	' перебираем по списку файлов и сортируем его!
	for ixx=0 to FileListBox.ItemCount-1
			'call  AddClrString ("2182:Item("+str$(ixx)+")="+(FileListBox.Item(ixx)), cldg, LogEditSV)
		
		if instr( Lcase$(FileListBox.Item(ixx)),curMask$)>0  then
			Tmpflist.AddItems FileListBox.Item(ixx)
			
		else
			
		end if
		
	next ixx
	
next msidx


FileListBox.clear
call  AddClrString ("2197:Tmpflist.ItemCount="+str$(Tmpflist.ItemCount), cllb, LogEditSV)

for ixx=0 to Tmpflist.ItemCount-1
	
	FileListBox.AddItems Tmpflist.Item(ixx)
	
next ixx

nosrt33:
sortflg=0 
end sub 


'*****************************************
sub BtnAddHotDirClick

with SelDirGrid
	'call  AddClrString ("2214:.RowCount="+str$(.RowCount), clb, LogEditSV)
	
	for i=1 to .RowCount-2
		if .Cell(1, i)="" then .DeleteRow (i) :'call  AddClrString ("1147:.RowCount="+str$(.RowCount), clred, LogEditSV)
		
	next i
	
	for i=0 to .RowCount-1
		if DirTreeSV.Directory =.Cell(1, i) then jz=99
	next i
	if jz <>99 then  
		.Cell(1,.RowCount-1 )=DirTreeSV.Directory 'RowCount-1'
		.InsertRow(.RowCount-1) 
		.swapRows (.RowCount-2,.RowCount-1 )
		if   .RowCount>1  then    .row=.RowCount-2:.col=1
		.Repaint
	else
		jz=0
		
	end if
	
	call SaveIni1
	
end with

end sub

'*****************************************
sub BtnDelHotDirClick (Col%, Row%, CanSelect% ) '-- -------------------'
with SelDirGrid
	if  .RowCount>1 then    .DeleteRow (.Row) else exit sub
	
	if .row=.RowCount-1 and .RowCount>1 then 
		.Row=.Row-1
	elseif .RowCount=2  then
		.Row=0
	else 
	end if
	
	'.cell(1, .RowCount-1)=str$(.row)
	.Repaint
end with

end sub


'*****************************************
SUB DrawCell (Col%, Row%, State%, Rect AS QRect, Sender AS QStringGrid)

with Sender
	
	if Row%=.Row  and (Col%=.Col and Col%>0 ) then
		.FillRect(Rect.Left, Rect.Top, Rect.Left+.ColWidths(Col%), Rect.Top+.RowHeights(Row%), &hE1D2C9)
		.TextOut(Rect.Left+2, Rect.Top+2, .Cell(Col%, Row%), Clr2, -1)
	end if
	
	if  col%=0  then 
		.FillRect(Rect.Left, Rect.Top, Rect.Left+.ColWidths(Col%), Rect.Top+.RowHeights(Row%), clSilver)
		.Rectangle(Rect.Left+.ColWidths(Col%)/6, Rect.Top+.RowHeights(Row%)/6, Rect.Left+.ColWidths(Col%)/6*5, Rect.Top+.RowHeights(Row%)/6*5, 0)
		
		if .Cell(0, Row%)="1" then
			.Line(Rect.Left+.ColWidths(Col%)/6, Rect.Top+.RowHeights(Row%)/6*2-1, Rect.Left+.ColWidths(Col%)/2, Rect.Top+.RowHeights(Row%)/6*4-1, clRed)
			.Line(Rect.Left+.ColWidths(Col%)/6, Rect.Top+.RowHeights(Row%)/6*2, Rect.Left+.ColWidths(Col%)/2, Rect.Top+.RowHeights(Row%)/6*4, clRed)
			.Line(Rect.Left+.ColWidths(Col%)/2, Rect.Top+.RowHeights(Row%)/6*4-1, Rect.Left+.ColWidths(Col%)/6*5, Rect.Top+.RowHeights(Row%)/6-1, clRed)
			.Line(Rect.Left+.ColWidths(Col%)/2, Rect.Top+.RowHeights(Row%)/6*4, Rect.Left+.ColWidths(Col%)/6*5, Rect.Top+.RowHeights(Row%)/6, clRed)
		else
			.FillRect(Rect.Left, Rect.Top, Rect.Left+.ColWidths(Col%), Rect.Top+.RowHeights(Row%), clSilver)
			.Rectangle(Rect.Left+.ColWidths(Col%)/6, Rect.Top+.RowHeights(Row%)/6, Rect.Left+.ColWidths(Col%)/6*5, Rect.Top+.RowHeights(Row%)/6*5, 0)
		end if
		
	else
	end if
	''  .Hint=.Cell(1, .Row)
	LabelDir.Caption=.Cell(1, .Row)
	'DirTreeSV.Directory=LabelDir.caption
	
end with

END SUB '-- -------------------'

'*****************************************
SUB  SelectCell (Col% , Row%, CanSelect%,Sender AS QStringGrid) '-- -------'
with sender
	if  col%=0  and Row%<.RowCount-1 then 
		if .Cell(0, Row%)="1" then .Cell(0, Row%)="0" else .Cell(0, Row%)="1"
	end if
	
	'.Repaint
	checkNestedDirs
	.Repaint
	LabelDir.Caption=.Cell(1, Row%)
	DirTreeSV.Directory=LabelDir.caption
end with

END  SUB '-- -------------------'
'*****************************************
sub DirTreeFormSVResize
DirTreeSV.Width =DirTreeFormSV.ClientWidth/2
DirTreeSV.Height =DirTreeFormSV.ClientHeight -65
end sub


'*****************************************
sub  StopS '-- ------------------------'
StopS1=1
TimerSV3.Enabled = 0
end sub

function  LCaseR1$ (Cases$) as string
for i= 192 to 223
	Cases$=ReplaceSubStr$(Cases$, chr$(i), chr$(i+32))
next 
LCaseR1$=Cases$
end function

function UCaseR1$ (Cases$) as string
for i= 224 to 255
	Cases$=ReplaceSubStr$(Cases$, chr$(i), chr$(i-32))
next
UCaseR1$=Cases$
end function

function  FileNameParse$ (FileName$) as string
FileNameParse$=right$(FileName$,instr(REVERSE$(FileName$), "\") )
end function

'*****************************************
sub SaveIni1 

' сохраняем таблицу  hot директорий   комбинированным способом - число строк в ini  и таблицу в файл
RQASIni.section="DirList"
RQASIni.write("DirsCount",str$(SelDirGrid.RowCount))
' call  AddClrString ("2346:SelDirGrid.RowCount="+str$(SelDirGrid.RowCount), clred, LogEditSV)

SelDirGrid.savetofile (StartPath$+"dirs.tab",0,0,SelDirGrid.RowCount)
' call  AddClrString ("2349:StartPath$+dirs.tab="+StartPath$+"dirs.tab", clred, LogEditSV)


RQASIni.section="Editor"

'RQASIni.write("BGColor",str$(FileEdit.Color))
RQASIni.write("FontColor",str$(FileEdit.Font.Color))
RQASIni.write("FontSize",str$(FileEdit.Font.Size))
RQASIni.write("FontName",(FileEdit.Font.Name))
'RQASIni.write("BGColor",str$(FileEdit.Color))

'RQASIni.section="FileListBox"

'RQASIni.write("BGColor",str$(FileEdit.Color)) ' - цвет файл listbox
'RQASIni.write("FontColor",str$(FileEdit.Font.Color)) ' - расстояние между строк listbox
'RQASIni.write("FontSize",str$(FileEdit.Font.Size))
'RQASIni.write("FontName",(FileEdit.Font.Name))


'- цвет listbox
RQASIni.section="Options"
RQASIni.write("Exclude Ext",MaskBoxNo.text) ' - список расширений файлов-исключений
RQASIni.write("Include Ext",MaskBoxYes.text) ' - список расширений 
RQASIni.write("CaseSensitive",str$(ChBoxCase.Checked)) 
RQASIni.write("WordWrap",str$(ChBoxWrap.Checked)) 
RQASIni.write("TextFileExt",str$(ChBoxWrap.Checked)) '- список расширений текстовых файлов

RQASIni.write("MaskBoxYesItemCount",str$(MaskBoxYes.ItemCount))

for i=0 to MaskBoxYes.ItemCount-1
	RQASIni.write("MaskBoxYes"+str$(i),MaskBoxYes.Item (i)) ' - список расширений файлов-исключений
next i


end sub '=--      

'*****************************************
sub LoadIni1 '==--                  
RQASIni.section="DirList"

SelDirGrid.RowCount=val(RQASIni.get("DirsCount","32"))
'call  AddClrString ("2390:SelDirGrid.RowCount="+str$(SelDirGrid.RowCount), clred, LogEditSV)

SelDirGrid.LoadFromfile (StartPath$+"dirs.tab",0,0,SelDirGrid.RowCount-1)
'call  AddClrString ("2393:StartPath$+dirs.tab="+StartPath$+"dirs.tab", clred, LogEditSV)


RQASIni.section="Editor"

'RQASIni.write("BGColor",str$(FileEdit.Color))
FileEdit.Font.Color =val(RQASIni.get("FontColor",clsilver))
FileEdit.Font.Size=val(RQASIni.get("FontSize","10"))
FileEdit.Font.Name=RQASIni.get("FontName","Courier")

'RQASIni.write("BGColor",str$(FileEdit.Color))

'RQASIni.section="FileListBox"

'RQASIni.write("BGColor",str$(FileEdit.Color)) ' - цвет файл listbox
'RQASIni.write("FontColor",str$(FileEdit.Font.Color)) ' - расстояние между строк listbox
'RQASIni.write("FontSize",str$(FileEdit.Font.Size))
'RQASIni.write("FontName",(FileEdit.Font.Name))


'- цвет listbox
RQASIni.section="Options" ' LangVar$(127)=File not found 
MaskBoxNo.text=RQASIni.get("Exclude Ext","*.gif *.jpg, *.bmp, *.pcx, *.png, *.ico, *.exe, *.com, *.dll,*.bin, *.obj,  *.zip, *.rar,*.arj, *.cab, *.pak, *.chm, *.dbx")
MaskBoxyes.text=RQASIni.get("Include Ext","*.*")
ChBoxCase.Checked=val(RQASIni.get("CaseSensitive","0"))
ChBoxWrap.Checked=val(RQASIni.get("WordWrap","0"))

MaskBoxYesItemCount=val(RQASIni.get("MaskBoxYesItemCount","1"))
' call  AddClrString ("2421:MaskBoxYes.ItemCount="+str$(MaskBoxYes.ItemCount), clred, LogEditSV)

for i=0 to MaskBoxYesItemCount-1
	MaskBoxYesItem$=RQASIni.get("MaskBoxYes"+str$(i),"")
	if MaskBoxYesItem$ <>"" then MaskBoxYes.AddItems(MaskBoxYesItem$)
	'RQASIni.write("MaskBoxYes"+str$(i),MaskBoxYes.Item (i)) ' - список расширений файлов-исключений
next i


end sub '=--      

'*****************************************
SUB CheckSV(key AS BYTE)
'call  AddClrString ("2434:key="+str$(key), clred, LogEditSV)
'' MaskBoxYesHnd, MaskBoxNoHnd 
Handle = GetFocus():
'call  AddClrString ("2437:Handle="+str$(Handle), clred, LogEditSV)
'call  AddClrString ("2438:FileListBox.handle="+str$(FileListBox.handle), clred, LogEditSV)
'call  AddClrString ("2439:SearchCBoxHnd="+str$(SearchCBoxHnd), clred, LogEditSV)
IF key = 13 THEN  
	select case handle
	case MaskBoxYesHnd
		'call  AddClrString ("2443:MaskBoxYesHnd="+str$(MaskBoxYesHnd), clred, LogEditSV)
		for i=0 to MaskBoxYes.ItemCount-1
			if MaskBoxYes.Text=MaskBoxYes.Item(i) then goto 123
		next
		
		MaskBoxYes.AddItems  MaskBoxYes.Text: 'sound 100, 1
		
	case MaskBoxNoHnd 
		'call  AddClrString ("2451:MaskBoxNoHnd="+str$(MaskBoxNoHnd), clred, LogEditSV)
		for i=0 to MaskBoxNo.ItemCount-1
			if MaskBoxNo.Text=MaskBoxNo.Item(i) then goto 123
		next
		MaskBoxNo.AddItems  MaskBoxNo.Text: 'sound 100, 1
	case SearchCBoxHnd
		SearchCBoxText$=replacesubstr$(SearchCBoxSV.Text,chr$(183)," ") 'chr$(149)
		for i=0 to SearchCBoxSV.ItemCount-1
			
			if SearchCBoxSV.Text=SearchCBoxSV.Item(i) then goto 123
		next
		SearchCBoxSV.AddItems  SearchCBoxSV.Text: 'sound 100, 1
		
	case else
	end select
elseif key=VK_DELETE then
	'call  AddClrString ("2467:VK_DELETE ="+str$(VK_DELETE ), clb, LogEditSV)
	select case handle
	case FileListBox.handle
		DeleteFromFilelistClick
	case else
	end select
	
else
end if

123
'MaskBoxYes.mask=MaskBoxYes.Text
end sub 

'*****************************************
sub StartFile

RUN "Start "+chr$(34)+FileListBox.Item(ItemIndex)+chr$(34)
end sub

'*****************************************
sub FileClickSV
'zzz=FileListBox.handle
'call  AddClrString ("2490:FileListBox.handle="+str$(FileListBox.handle), clred, LogEditSV)
'zzz=FileListPanel.handle
'call  AddClrString ("2492:FileListPanel.handle="+str$(FileListPanel.handle), clred, LogEditSV)
'xxx = GetFocus()
'call  AddClrString ("2494: GetFocusxxx="+str$(xxx), clred, LogEditSV)
'cFileName=FileListBox.Item(FileListBox.ItemIndex)
cFileName=field$(FileListBox.Item(FileListBox.ItemIndex),chr$(160),1)

FileLoadSV (cFileName)
'REmoveItemFromFileList.ShortCut="Del"


end sub


'*****************************************
sub FileLoadSV (filename$)'=================='
'call  AddClrString ("2507:FileListBox.ItemIndex="+str$(FileListBox.ItemIndex), clred, LogEditSV)
'if FileListBox.ItemIndex < 1 then exit sub

'cFileName=FileListBox.Item(FileListBox.ItemIndex)
cFileName=filename$
call  AddClrString ("2512:cFileName="+(cFileName), clred, LogEditSV)
if fileexists(cFileName)=0 then 
	Showmessage (LangVar$(127)+cFileName) ' LangVar$(127)=File not found 
	exit sub
end if

'cFileName=lcase$(cFileName)

'FileEdit.clear

FileName.Open(cFileName, fmOpenRead)
filen$=vidnum$(FileName.Size, 0)+LangVar$(123) ' /1024 ' LangVar$(123)= bytes
docsgn=FileName.ReadBinStr(6)
FileName.close ' LangVar$(124)= bytes

FNameLabel.Caption = cFileName+"  " +filen$
'-- --------------------'
'LogEditSV.AddStrings " cFileName=" +cFileName+"----"
'LogEditSV.AddStrings "сигнатура="+docsgn

' Определяем формат файла'%PDF - 

if ExplorerExist=1 then  Explorer.Free: ExplorerExist=0:Explorer.visible=false
'c!REATE Explorer AS QOLECONTAINER
'mask$=chr$(34)+FileListBox.Item(FileListBox.ItemIndex)+chr$(34)

if instr (docsgn, "РП")=-10 then 
	LogEditSV.AddStrings "'2582: Word Doc '"
	
	if RBRtf.checked=true or RBPlainTxt.checked=true then
		
		Object.CreateObject("Word.Basic")
		Object.fileOpen(cFileName)
		Object.EditSelectAll
		Object.EditCopy
		FileEdit.clear ' LangVar$(141)=Dos
		FileEdit.PasteFromClipboard
		if RBPlainTxt.checked=true then 
			FileEdit.Plaintext=true
		else
			FileEdit.Plaintext=false
		end if
		
		Object.FileExit
		Object.free
		exit sub
		
	elseif RBasFormat.checked=true then
		'---------------------'
		Explorer.visible=true
		Explorer.CreateObject("Shell.Explorer.1")
		Explorer.Navigate(cFileName)
		'---------------------'
		ExplorerExist=1
	end if
	
elseif instr (docsgn, "%PDF")=-10 then 
	'LogEditSV.AddStrings "'документ Adobe Acrobat'"
	'---------------------'
	Explorer.visible=true
	Explorer.CreateObject("Shell.Explorer.1")
	Explorer.Navigate(cFileName)
	'---------------------'
	ExplorerExist=1
else  'для любых других форматов'
	LogEditSV.AddStrings "'2620: No Word Doc'"
	if RBasFormat.checked=true   then 'and instr(cFileName,".htm")>0
		if instr(cFileName,".htm")>0 and instr(cFileName,".txt")>0 then
		else
			FileCopy (cFileName, cFileName+".htm")
			cFileName=cFileName+".htm"
			' call  AddClrString ("2583:cFileName="+(cFileName), cldg, LogEditSV)
			
		end if
		
		'---------------------'
		Explorer.visible=true
		Explorer.CreateObject("Shell.Explorer.1")
		Explorer.Navigate(cFileName)
		kill cFileName+".htm"
		'---------------------'
		ExplorerExist=1
	else 'RBRtf.checked=true or RBPlainTxt.checked=true if    then
		
		if RBPlainTxt.checked=true then 
			FileEdit.Plaintext=true
		else
			FileEdit.Plaintext=false
		end if
		
		FileEdit.LoadFromFile (cFileName)
		call  AddClrString ("2603:cFileName="+(cFileName), cldb, LogEditSV)
		
		
		'----- определяем кодировку -----
		codP$="Win"
		chNum=0
		for j=0 to 11 'TALLY'
			chNum=chNum+tally(FileEdit.text, chr$(j+240))
		next j
		if chNum>len(FileEdit.text)/20 then
			'LogEditSV.AddStrings " hit=" +str$(chNum)+" len="+str$(len(FileEdit.text))+" len/40="+str$(len(FileEdit.text)/40) :
			codP$="Win"
			goto exit1
		else
		end if
		
		for i=0 to 48
			if instr(FileEdit.text, chr$(i+128))>0  then
				'print FileEdit.text
				rt$=FileEdit.text
				OemToChar rt$, rt$
				FileEdit.text=rt$
				codP$=LangVar$(141) ' LangVar$(141)=Dos
				exit for
			else ' LangVar$(143)=Всего 
				codP$="Win"
			end if
		next i
		
		exit1:
		FNameLabel.Caption = cFileName+"  " +filen$ '+" "+codP$
		'exit sub
		
	end if
	' LangVar$(144)=Не найден файл 
end if
'if FileListBox.TopIndex<1 then FileListBox.TopIndex=1

'call  AddClrString ("2641:FileListBox.TopIndex="+str$(FileListBox.TopIndex), clred, LogEditSV)

if ListOfSearchChBoxSV.checked=1 then 
	ListCreatedFlg=0 :''ListChBoxClick ' LangVar$(106)=Всего файлов 
	refreshList
end if ' LangVar$(146)=Все в порядке

qwq = SendMessageAPI (FileEdit.handle,EM_EXLIMITTEXT,0,65535*32)

end  sub

'*****************************************
sub ChBoxWrapClick

IF ChBoxWrap.Checked THEN ' LangVar$(148)=Удалить файл  ' LangVar$(147)=Удалить файл 
	FileEdit.Wordwrap=true
else
	FileEdit.Wordwrap=false
END IF

end sub 

'*****************************************
sub SaveFileList 

'OpenDialog.InitialDir=StartDir
'OpenDialog.Filter = "Формат списков *.lst|*.lst|All Files *.*|*.*"

SaveDialog.InitialDir=StartDir
SaveDialog.Filter = "File list *.lst|*.lst|All Files*.*|*.*"

SearchCBoxText$=replacesubstr$(SearchCBoxSV.Text,chr$(183)," ") 'chr$(149)

if SearchCBoxSV.Text="" or SearchCBoxSV.Text=chr$(183) then 
	SaveDialog.FileName="file"+time$-":"+".lst"
else
	SaveDialog.FileName=SearchCBoxText$+".lst"
end if

'05-02-2006

'"Sorry. Register please for file saving"
'call  AddClrString ("2683:asc(c)="+str$(asc("c")), clred, LogEditSV)
'call  AddClrString ("2684:czs="+str$(czs), clred, LogEditSV)


IF SaveDialog.Execute THEN
	IF FileExists(SaveDialog.FileName) <> FALSE THEN 
		IF MessageBox(Msg16$+chr$(10)+SaveDialog.FileName +" ?", Msg13$, 1) = 1 THEN
		else
			exit sub
		END IF
	END IF
	
	FileListBox.InsertItem (0,replacesubstr$(SearchCBoxSV.Text,chr$(183)," "))
	
	FileListBox.SaveToFile (SaveDialog.FileName)
	call  AddClrString ("2698: File List saved to "+(SaveDialog.FileName), cldg, LogEditSV)
	CurList=SaveDialog.FileName
	FileListBox.DelItems (0)
	
END IF
exitfilesave:
end sub 

'*****************************************
sub LoadFileList 
OpenDialog.InitialDir=StartDir
OpenDialog.Filter = "File list *.lst|*.lst|All Files *.*|*.*"

IF OpenDialog.Execute THEN
	FileListBox.LoadFromFile (OpenDialog.FileName)
	CurList=OpenDialog.FileName
	'call  AddClrString ("2714:CurList="+(CurList), clred, LogEditSV)
	'FileListBox.ItemIndex=1
	'SearchCBoxSV.Text=FileListBox.Item(0) 'FILENAMENOEXT(CurList)
	SearchCBoxSV.Text=field$(FileListBox.Item(0),chr$(160),1)
	
	FileListBox.DelItems (0)
	cFileName=FileListBox.Item(1)
	FileLoadSV (cFileName)
	
END IF
ValidFileList
'SearchCBoxSV.text=CurList
LogLabel1.Caption =LangVar$(143)+str$(FileListBox.ItemCount)'+" файлов" ' LangVar$(143)=Всего 

end sub 

'*****************************************
sub ValidFileList

for i=0 to FileListBox.ItemCount-1
	FNameLabel.caption=FileListBox.Item(i)
	
	IF FileExists(FileListBox.Item(i)) = FALSE THEN
		''        FileName.Open(FNames$, fmOpenRead)   
		LogEditSV.AddStrings LangVar$(144)+FileListBox.Item(i) ' LangVar$(144)=Не найден файл 
		errF=1
		FileListBox.DelItems (i)
		dec i
		'FileListBox.Item(i)=chr$(135)+"--- "+FileListBox.Item(i)
		
		' call  AddClrString ("2744:FileListBox.ItemCount="+str$(FileListBox.ItemCount), clred, LogEditSV)
	else
		''  LogEditSV.AddStrings "Файл "+FileListBox.Item(i) +" в норме"
	end if
	LogLabel1.Caption = LangVar$(106)+str$(FileListBox.ItemCount) ' LangVar$(106)=Всего файлов 
next i
if errF=0 then LogEditSV.AddStrings LangVar$(146) ' LangVar$(146)=Все в порядке
end sub 

'*****************************************
sub DelFileList 

''    ShowMessage "2756"+CurList+" ?"
IF MessageBox(LangVar$(36)+" " +CurList+" ? ", LangVar$(130),1)=1 THEN ' LangVar$(148)=Удалить файл  ' LangVar$(147)=Удалить файл  ' LangVar$(130)=Да
	kill CurList
	
else
	
END IF

end sub 

'*****************************************
sub CodAutoOnClick  

'with CodAutoMnu
	'if .checked=true then 
		'.checked=false
	'else ' LangVar$(149)=Не задан образец для поиска 
		'.checked=true
	'end if
'end with
end sub 

'*****************************************
sub CodWin1251OnClick 
with CodWin1251Mnu
	if .checked=true then 
		.checked=false
	else
		.checked=true
	end if
end with
end sub 

'*****************************************
sub CodDosOnClick
with CodDosMnu
	if .checked=true then 
		.checked=false
	else
		.checked=true
	end if
end with
end sub 

'*****************************************
sub Koi8OnClick
with Koi8Mnu
	if .checked=true then 
		.checked=false
	else
		.checked=true
	end if
end with
end sub 

'*****************************************
sub EMailBugOnClick
with EMailBugMnu
	if checked=true then 
		checked=false
	else
		checked=true
	end if
end with

end sub 

'*****************************************
sub CodRBOnClick  (Sender AS QMENUITEM)
if Sender.Checked = 1 then Sender.Checked = 0 else Sender.Checked = 1

'if CodAuto.checked  then

'elseif CodWin1251.checked then

'elseif CodDos.checked then

'elseif Koi8.checked then

'elseif EMailBug.checked then

'else

'end if


end sub 

'*****************************************
SUB FindTextSV (Sender as QButton)'
begsrch:
if SearchCBoxSV.Text="" then   
	SearchStr$="" 
	showmessage (LangVar$(149)) ' LangVar$(149)=Не задан образец для поиска 
	exit sub
else 
	SearchStr$=replacesubstr$(SearchCBoxSV.Text,chr$(183)," ") 'SearchCBoxSV.Text
	
END IF

'- ----------- приводим к верхнему регистру --------'     
if ChBoxCase.Checked =0 then
	UFileEditText$=UCASE$(FileEdit.Text)
	USearchStr$=UCASE$(SearchStr$)
	UFileEditSelText$=UCASE$(FileEdit.SelText)
	
else
	UFileEditText$=(FileEdit.Text)
	USearchStr$=(SearchStr$)
	UFileEditSelText$=(FileEdit.SelText)
	
end if

'call  AddClrString ("2869:USearchStr$="+(USearchStr$), clred, LogEditSV)

'if INSTR(UFileEditText$, USearchStr$)=0 then goto NextFil

select case Sender.tag
	
case 21 'Поиск вперед в RightText
	if INSTR(UFileEditText$, USearchStr$)=0 then goto NextFil
	
	if UFileEditSelText$=USearchStr$ then FileEdit.SelStart=FileEdit.SelStart +FileEdit.SelLength+1
	FileEdit.SelStart = INSTR(FileEdit.SelStart, UFileEditText$, USearchStr$)-1
	IF FileEdit.SelStart > 0 THEN
		FileEdit.SelLength = LEN(SearchStr$)
		FileEdit.SelAttributes.Color =clBlue
	ELSEif FileEdit.SelStart=Len (FileEdit.Text) then
		'SHOWMESSAGE (SearchStr$+"2884")
	END IF
	
	if FileEdit.SelStart=Len (FileEdit.Text) then
		
		NextFil:
		NextFileOnCl
		if FileListBox.ItemIndex=FileListBox.ItemCount-1 then exit sub
		goto begsrch 
		''    sound 1000, 1
		''    SHOWMESSAGE ("2894"+chr$(10)+ SearchStr$+chr$(10)+ "> окончен")
		''  FileEdit.SelStart=0
		
	END IF
	
case 22 'Поиск назад
	if INSTR(UFileEditText$, USearchStr$)=0 then goto PrevFil
	
	if UFileEditSelText$=USearchStr$ then FileEdit.SelStart=FileEdit.SelStart -1
	FileEdit.SelStart = rINSTR(FileEdit.SelStart, UFileEditText$, USearchStr$)-1
	IF FileEdit.SelStart > 0 THEN
		FileEdit.SelLength = LEN(SearchStr$)
		FileEdit.SelAttributes.Color =clBlue
	ELSEif FileEdit.SelStart=1 then 'Len (FileEdit.Text)
		'SHOWMESSAGE (SearchStr$+"2908")
	END IF
	if FileEdit.SelStart=Len (FileEdit.Text) then
		
		PrevFil:
		PrevFileOnCl
		if FileListBox.ItemIndex=0 then exit sub '
		FileEdit.SelStart=Len (FileEdit.Text)-1
		goto begsrch 
		' LangVar$(153)=Перезаписать файл ' LangVar$(152)=Перезаписать файл
	END IF
	
case else
end select
'' RichRow1=str$(FileEdit.WhereY+1)
'' RichCol1=str$(FileEdit.WhereX+1)
'RichX1.Caption= RichRow1+":"+RichCol1

R2Change

END SUB

'*****************************************
sub NextFileOnCl
if FileListBox.ItemIndex<FileListBox.ItemCount-1 then
	FileListBox.ItemIndex=FileListBox.ItemIndex+1
	cFileName=field$(FileListBox.Item(FileListBox.ItemIndex),chr$(160),1) ' FileListBox.Item(FileListBox.ItemIndex)
	FileLoadSV (cFileName)
else
	
end if

END SUB
'*****************************************
sub   PrevFileOnCl
if FileListBox.ItemIndex>0 then
	FileListBox.ItemIndex=FileListBox.ItemIndex-1
	cFileName=field$(FileListBox.Item(FileListBox.ItemIndex),chr$(160),1) ' FileListBox.Item(FileListBox.ItemIndex)
	FileLoadSV (cFileName)
else
	
end if
END SUB

'*****************************************
sub   NextHitOnCl
'LogEditSV.AddStrings "Поиск вперед "
call FindTextSV (NextHitBtn )' ' LangVar$(153)=Завершить работу? ' LangVar$(154)=Завершить работу?

END SUB

'*****************************************
sub   PrevHitOnCl
'LogEditSV.AddStrings "Поиск назад"
call FindTextSV (PrevHitBtn )'
END SUB


'*****************************************
sub ChBoxPlainTxtClick
if ChBoxPlainTxt.Checked=true then
	FileEdit.Plaintext=true
else
	FileEdit.Plaintext=false
end if

'Explorer.visible=true

END SUB

'*****************************************
sub ChBoxHTMLClick
if RBPlainTxt.checked=true then 
	FileEdit.Plaintext=true
	Explorer.visible=false
	FileEdit.enabled=1 
	'cFileName=FileListBox.Item(FileListBox.ItemIndex)
	FileLoadSV (cFileName)
	
	'FileLoadSV (FileListBox.Item(FileListBox.ItemIndex))
elseif RBRtf.checked=true then
	FileEdit.Plaintext=false
	'FileEdit.enabled=0
	FileLoadSV (cFileName)
	'FileLoadSV (FileListBox.Item(FileListBox.ItemIndex))
elseif RBasFormat.checked=true then
	FileLoadSV (cFileName)
	'FileLoadSV (FileListBox.Item(FileListBox.ItemIndex))
end if

END SUB

'*****************************************
sub SaveFileSV '-- ------------------------'
'FileListBox.Item(FileListBox.ItemIndex)

IF MessageBox(LangVar$(153)+chr$(10)+cFileName +" ?", LangVar$(133), 1) = 1 THEN ' LangVar$(153)=Перезаписать файл ' LangVar$(152)=Перезаписать файл ' LangVar$(106)=Всего файлов  ' LangVar$(133)=Все правильно?
	FileEdit.Plaintext=true
	FileEdit.SaveToFile (cFileName)
else
	exit sub
END IF
END SUB

'*****************************************
sub SaveAsSV
SaveDialog.InitialDir=DirTreeSV.Directory
'SaveDialog.Filter ="Picture files *.BMP;*.ICO;*.jpg;*.gif;*.pcx|*.BMP;*.ICO;*.jpg;*.gif;*.pcx| _
SaveDialog.Filter ="All Files *.*|*.*| _
Html Files *.*htm*;*.js;*.vbs;*.css|*.*htm*;*.js;*.vbs;*.css| _
Txt Files  *.txt;*.doc;*.rtf;*.ini|*.txt;*.doc;*.rtf;*.ini| _
Bas Files  *.bas;*.rqb|*.bas;*.rqb|"

SaveDialog.FileName=cFileName 'FileListBox.Item(FileListBox.ItemIndex)

'call  AddClrString ("3023:SaveDialog.Filter="+str$(SaveDialog.Filter), clred, LogEditSV)

SaveDialog.FilterIndex = 2    '' Use "All Files" as our default
IF SaveDialog.Execute THEN
	IF FileExists(SaveDialog.FileName) <> FALSE THEN 
		IF MessageBox("Replace file"+chr$(10)+SaveDialog.FileName +" ?", "OK?", 1) = 1 THEN
		else
			exit sub
		END IF
	END IF
	FileName.Open(SaveDialog.FileName, fmCreate) 
	for i=0 to FileEdit.LineCount-1
		FileName.WriteLine (FileEdit.Line(i))
	next
	FileName.Close
ELSE
END IF
DirTreeSV.Reload
end sub

'*****************************************
sub exitProg
IF MessageBox(LangVar$(153), LangVar$(133), 1) = 1 THEN ' LangVar$(153)=Завершить работу? ' LangVar$(154)=Завершить работу? ' LangVar$(133)=Все правильно?
	end
else
	exit sub
END IF

end sub

'*****************************************
Sub OnFileListPopUp

End Sub 

'*****************************************
Sub SearchInF
'call ValidFileList

DIM TmpFileSL AS QStringList

for i=0 to FileListBox.ItemCount-1
	FNameLabel.caption=field$(FileListBox.Item(I),chr$(160),1) ' FileListBox.Item(i)
	
	TmpFileSL.LoadFromFile (field$(FileListBox.Item(I),chr$(160),1))
	
	'- ----------- приводим к нижнему регистру --------'     
	if ChBoxCase.Checked =true then
		SSR$=replacesubstr$(SearchCBoxSV.Text,chr$(183)," ") '(SearchCBoxSV.Text)
		
	else
		TmpFileSL.text=CharLower(TmpFileSL.text)
		SSR$=CharLower (replacesubstr$(SearchCBoxSV.Text,chr$(183)," "))
		'SearchCBoxSV.Text=SSR$
	end if
	
	if instr(TmpFileSL.text, ssr$)=0  then  
		FileListBox.DelItems  (i) ' Fn$ если просто имя файла, то не находит без пути
		dec i
		'inc NumHit
	end if
	'LogEditSV.AddStrings  ssr$
	doevents:if stops1=1 then stops1=0: exit sub 'while
	'------------------------'
	LogLabel1.Caption = LangVar$(106)+str$(FileListBox.ItemCount) ' LangVar$(106)=Всего файлов 
	
next i


End Sub 

'*******************************************************'
sub AboutClick
	AboutLabel3.top=130 ' NagPanel.top+5
	

AboutFrm.ShowModal
'exit sub
'ShowMessage "3101" +chr$(10)+ _
'"Andrew Shelkovenko diakin@narod.ru             " +chr$(10)+ chr$(10)+ _
'"Special thanks to William Yu  for Rapid-Q Basic programming language"
end sub

'-- ************************************************************************'
sub Help2
'print "Start "+left$(  Command$(0), rinstr(      Command$(0), "\"    )     )+ "help\rqsr_help.htm" 
'RUN "Start "+left$(  Command$(0), rinstr(      Command$(0), "\"    )     )+ "help\rqsr_help.htm"

helppath$=left$(Command$(0), rinstr(Command$(0),"\"))+ "help\index.htm"
'call  AddClrString ("3112:helppath$="+(helppath$), clred, LogEditSV)
if instr(helppath$, " ")>0 then helppath$=qt+helppath$+qt
'PID = ShellExecute(MainFORM.HANDLE, "Open", helppath$, "", "", 1)
PID =SHELL("Start "+helppath$, 0)

end sub

'-- ************************************************************************'
sub Help3
'call AddClrString ( "3121"+left$(Command$(0), rinstr(Command$(0), "\"))+ "readme.txt", clred, LogEditSV)   
readmepath$=left$(Command$(0), rinstr(Command$(0),"\"))+ "readme.txt"

'call  AddClrString ("3124"+(readmepath$), clred, LogEditSV)
if instr(readmepath$, " ")>0 then readmepath$=qt+readmepath$+qt
'PID = ShellExecute(MainFORM.HANDLE, "Open", readmepath$, "", "", 1)
PID = SHELL("Start "+readmepath$, 0)
end sub

'*****************************************
Sub HelpEnglish
helppath$=left$(Command$(0), rinstr(Command$(0),"\"))+ "helpE\index.htm"
'call  AddClrString ("3133:helppath$="+(helppath$), clred, LogEditSV)
if instr(helppath$, " ")>0 then helppath$=qt+helppath$+qt
'PID = ShellExecute(MainForm.HANDLE, "Open", helppath$, "", "", 1)
PID = SHELL("Start "+helppath$, 0)

End Sub                    

'*****************************************
SUB AboutFrmMouseMove  (X%, Y%, Shift%) 

if AboutLabel1.font.color <> cldb then AboutLabel1.font.color=cldb
if AboutLabel2.font.color <> cldb then AboutLabel2.font.color=cldb
'NagPanel.color=clSilver


end sub

'-- ***********************************************************************'
sub AboutLabel1MouseMove (X%, Y%, Shift%,sender as  QLabel)

with sender 
	
	select case .tag
		
	case 80
		
		AboutLabel1.font.color=clBlue
		AboutLabel2.font.color=cldb
	case 81
		
		AboutLabel2.font.color=clBlue
		AboutLabel1.font.color=cldb
	case else
	end select
end with

end sub


'*****************************************
sub AboutLabel1DblClick (X%, Y%, Shift%,sender as  QLabel)
with sender 
	'call AddClrString ( "3175"+str$(.tag), clred, LogEditSV)   
	select case .tag
	case 80
		'PID = ShellExecute(MainForm.HANDLE, "Open", "http://mira.xeno.ru/rqsr.html", "", "", 1)
	case 81
		
		DEFINT hWnd11'' = FindWindow(0, "RQSR")
		'hWnd11 = FindWindow(0&, "from user RQ Search and Replace")
		'IF hWnd11 <> 0 THEN
		'ShowMessage ("3184")
		'SetForegroundWindow(hWnd11)
		'ShowWindow(hWnd11, 1)
		'exit sub
		'END IF
		
		PID = ShellExecute(MainForm.HANDLE, "Open", "mailto:diakin@narod.ru?subject=from user RQ Advanced Search", "", "", 1)
	case 82
		PID = ShellExecute(MainForm.HANDLE, "Open", "http://mira.xeno.ru/rqsr.html", "", "", 1)
	case 85
		PID = ShellExecute(MainForm.HANDLE, "Open", "https://www.plimus.com/jsp/buynow.jsp?contractId=1651600", "", "", 1)
		
	case else
	end select
end with
end sub

'*****************************************
Sub NagPanelOnMouseMove (X%, Y%, Shift%)

' NagPanel.color=&HE1E2E6 
End Sub 
'*****************************************
Sub LabelNag2Click
End Sub 

'-- **************************************************************************'
sub   OKiButtonClick  ' регистрация
end sub
'-- **************************************************************************'
sub  cancelButtonClick
end sub

'-- **************************************************************************'
sub register
end sub

'*****************************************
function StrCrp (Strng2 as string, keys as integer) as string
dim ChrStr5 as string
dim ChrStr6 as string 
ChrStr5=""
ChrStr6=""

a=len (Strng2 ) 

for i=1 to len (Strng2 ) step 3
	q2$=""
	for j=1 to 3
		q2$=q2$+Strng2[i+j-1] 
	next j
	
	ChrStr5=chr$((val(q2$)+14)/2-keys) 
	ChrStr6=ChrStr6+ChrStr5 
next i
result=ChrStr6
end function
'-- **************************************************************************'
sub RegCode 
end sub

'-- **************************************************************************'
function CrpStr1 (Strng1 as string, keys as integer) as string
AscStr=0

for i=1 to len (Strng1 )
	AscStr=3.8765*AscStr/i+((keys+qwer22)* asc(Strng1[i])* asc(Strng1[i])*qwer44) 
	'AscStr=3.8765*AscStr/i+((keys)* asc(Strng1[i])* asc(Strng1[i])) 
	AscStr1=4.8765*AscStr/i+(keys* asc(Strng1[i])* asc(Strng1[i])) 
	AscStr2=2.8765*AscStr/i+(keys* asc(Strng1[i])* asc(Strng1[i])) 
	AscStr3=5.8765*AscStr/i+(keys* asc(Strng1[i])* asc(Strng1[i])) 
	AscStr4=4.65*AscStr/i+(keys* asc(Strng1[i])* asc(Strng1[i])) 
	AscStr5=7.65*AscStr/i+(keys* asc(Strng1[i])* asc(Strng1[i])) 
	'CrpStr1Arr(i)=
next i
AStr$=str$( AscStr )-"." 
azs$=left$(AStr$ ,9 ) 
result=azs$ 'left$(AStr$ ,8 ) 

end function

'-- **************************************************************************'
function CrpStr (Strng1 as string, keys as integer) as string
dim ChrStr3 as string
dim ChrStr4 as string
ChrStr3=""
ChrStr4=""
for i=1 to len (Strng1 )
	ChrStr3=str$ (asc(Strng1[i])) 
	ChrStr3=Add0Before(ChrStr3, 3)
	ChrStr3=str$( 2* (val(ChrStr3)+keys)-14)
	ChrStr4=ChrStr4+ChrStr3  
next i
result=ChrStr4
end function

'*****************************************
SUB TimerOverSV4

end sub
'--*************************************
SUB TimerOverSV3 
'-----------------------------------'
LogLabel6.Caption = str$(Timer)

LogLabel1.Caption = LangVar$(106)+str$(NumFiles) ' LangVar$(106)=Всего файлов 
LogLabel2.Caption = LangVar$(119)+" "+str$(NumHit)+"   "+str$(Speed)+LangVar$(116) ' LangVar$(116)=" файлов/с " ' LangVar$(116)=Найдено  ' LangVar$(119)=Найдено
LogLabel3.Caption = LangVar$(108)+str$(NumOst) ' LangVar$(108)=Осталось 
LogLabel4.Caption = LangVar$(121)+TimeString(Timer-TimeBeg)+"  "+ ' LangVar$(121)=Прошло 
LogLabel5.Caption = LangVar$(108) +TimeOst1$+"   " ' LangVar$(108)=Осталось 
FNameLabel.caption=FNameLabelcaption$
end sub

'--**************************************************
SUB TimerOverSV2 


if  SDC=1   then '1'and DiaMsgOld$ <> DiaMsg$
	if stops1=1 then 
		SDC=0:
		Logfilname$=StartDir+"\"+FileNameNoExt(PrjFileName)+Date$+"_"+Timeg$+".log
		Logfilname$=Logfilname$-"-"
		'if MainMenuItem(64).checked=true then LogSListFile.SaveToFile (Logfilname$)
	end if
	'LogStatusBar.Panel(0).caption =DiaMsg$
	'call  AddClrString ("3309:DiaMsg$="+(DiaMsg$), clred, LogEditSV)
else
end if

end sub

'--**************************************************
Sub ListChBoxClick

if ListOfSearchChBoxSV.checked=1 then
	refreshList
	SearchListForm1.Show
	doevents
	if ListCreatedFlg=0 then
		'call refreshList
		
	else
	end if
	
else
	SearchListForm1.Close
end if

End Sub       

'--**************************************************
Sub ListSelectCell(Col% , Row%, CanSelect%, Sender AS QStringGrid)  
ChBoxWrap.checked=0
LineN=val(SEarchListGrid1.cell(0,Row%))-1
'cFileName=SEarchListGrid1.cell(1,Row%)
'FileListBox.ItemIndex=val(SEarchListGrid1.cell(3,Row%))
'call FileLoadSV
FileEdit.selstart=len(FileEdit.text)-5
FileEdit.selstart=FileEdit.GetLINEIdx(LineN)
NextHitOnCl
'FileEdit.SelLength=1


'cFileName=FileListBox.Item(FileListBox.ItemIndex)

'FileEdit.selstart=FileEdit.GetLineIdx(FileEdit.LineCount-1)
'FileEdit.selstart=FileEdit.GetLineIdx(LineN-1)
R2Change
End Sub   ' LangVar$(179)=Строк  

'--**************************************************
Sub ListGridDrawCell (Col%, Row%, State%, Rect AS QRect)
exit sub ' почему-то выскакивает ошибка !!!
if ListGridReady=0 then exit sub

with SEarchListGrid1
	if col%=2 and row% >0 then 
		sscel$=SEarchListGrid1.cell(Col%, Row%)
		'call  AddClrString ("3362", clb, LogEditSV)
		'call  AddClrString ("3363:sscel$="+(sscel$), clred, LogEditSV)
		if mid$(sscel$,1,1)="'" then 
			'if sscel$[1]="'" then
			'.FillRect(Rect.Left, Rect.Top, Rect.Left+.ColWidths(0), Rect.Top+.RowHeights(Row%),clgrey )
			.FillRect(Rect.Left, Rect.Top, Rect.Left+.ColWidths(Col%), Rect.Top+.RowHeights(Row%), clgrey)
			.TextOut(Rect.Left+2, Rect.Top+2, .Cell(Col%, Row%), Clr, -1)
		end if
	end if
end with

End Sub           

'*****************************************
Sub refreshList ' перебираем по файлам и ищем в них строки, содержащие искомое слово.

Index=1
'call ValidFileList
SEarchListGrid1.rowCount=2

DIM TmpFile AS QStringList
DIM TmpFileSL AS QStringList

for i=0 to SEarchListGrid1.rowCount-1
	SEarchListGrid1.cell(2,Index)=""
	SEarchListGrid1.cell(1,Index)="" ' LangVar$(112)=Col 
	SEarchListGrid1.cell(0,Index)="" 
	
next i

SearchListForm1.Show
ListCreatedFlg=1
'SEarchListGrid1.rowCount=2

'for i=0 to FileListBox.ItemCount-1
'!!! ------  Здесь вставим операцию обработки найденных файлов ----------'
'FNameLabel.caption=FileListBox.Item(i)
FNameLabel.caption=field$(FileListBox.Item(FileListBox.ItemIndex),chr$(160),1) ' FileListBox.Item(FileListBox.ItemIndex)

TmpFile.LoadFromFile (FNameLabel.caption)

'- ----------- приводим к нижнему регистру --------'     
if ChBoxCase.Checked =true then
	TmpFileSL.text=(TmpFile.text)
	SSR$=replacesubstr$(SearchCBoxSV.Text,chr$(183)," ") ' (SearchCBoxSV.Text)
	'SearchCBoxSV.Text=SSR$
	
else
	TmpFileSL.text=CharLower(TmpFile.text)
	SSR$=CharLower (replacesubstr$(SearchCBoxSV.Text,chr$(183)," "))
	'SearchCBoxSV.Text=SSR$
end if

bzzz=instr(TmpFileSL.text, ssr$) ' первая позиция
'call  AddClrString ("3416:ssr$="+(ssr$), cldg, LogEditSV)

if bzzz>0  then  
	' в файле присутствует искомое слово
	for j=0 to TmpFileSL.ItemCount-1 ' перебираем по строкам 
		'добавляем строку в таблицу
		bzzz=instr(TmpFileSL.item(j), ssr$)
		if bzzz>0  then 
			'SEarchListGrid1.rowCount=SEarchListGrid1.rowCount+1
			SEarchListGrid1.cell(2,Index)=trim$(TmpFile.Item(j))-ht ' строка 
			SEarchListGrid1.cell(1,Index)=FNameLabel.caption ' имя файла 
			SEarchListGrid1.cell(0,Index)=Str$(j+1) ' номер строки 
			'SEarchListGrid1.cell(3,Index)=Str$(i) ' index файла из списка 
			
			if SEarchListGrid1.rowCount=Index then SEarchListGrid1.rowCount=SEarchListGrid1.rowCount+1
			inc Index
			
			LinesLabel.Caption = LangVar$(179)+str$(Index-1) ' LangVar$(179)=Строк  
			
		end if
		doevents: if stops1=1 then stops1=0: exit sub 'while
		
	next j
else
end if

'LogEditSV.AddStrings  ssr$
doevents:if stops1=1 then stops1=0: exit sub 'while
'------------------------'
ListCreatedFlg=1

End Sub 
'-- ************************************************************************'
sub R2Change

RichRow1=str$(FileEdit.WhereY+1)
RichCol1=str$(FileEdit.WhereX+1)

if FileEdit.SelStart+1< len(FileEdit.Text) then 
	pos1=FileEdit.SelStart+1
else
	pos1=FileEdit.SelStart
end if

char1$ = str$(asc(mid$(FileEdit.Text, pos1,1)))
'RichX1.Caption= RichRow1+":"+RichCol1 +"    "+char1$
'RichX1.Font.Color=clBlue
FileEditLen1=len (FileEdit.text)

'FileEdit.SelStart=CursWin(WindowsIndex) 

''    AddPanels "Строка ", "Столбец ", "Код символа","Номер символа в тексте"
StatusBarSV.Panel(0).caption = "Row "+RichRow1+":"+  str$(FileEdit.LineCount)
StatusBarSV.Panel(1).caption = LangVar$(112)+RichCol1   ' LangVar$(112)=Col 
StatusBarSV.Panel(3).caption = "Asc "+char1$
StatusBarSV.Panel(2).caption = LangVar$(113)+str$(pos1)+":"+  str$(FileEditLen1)

if FileEditLen<>FileEdit.LineCount then 'FileEditLen1 только при изменении числа строк
	FileEditLen=FileEdit.LineCount
	Modiflg=1
end if
END SUB
'AddPanels "Row ", "Col ", LangVar$(113),"Asc ", "EOL ",""  

'-- ************************************************************************'
sub RichEditOnMouseDown
R2Change
END SUB

'-- ************************************************************************'
sub SrcEditOnKeyDown (Key AS WORD, Shift AS INTEGER)


end sub                                                              

'-- ************************************************************************'
sub SrcEditOnKeyUp (Key AS WORD, Shift AS INTEGER)


R2Change

end sub                                                              
'*****************************************
Sub ChoosDirOnclick
DirTreeFormSV.show:
DirTreeSV.InitialDir = CurDir$

End Sub 

'*****************************************
Sub OpenIntextEditClick
run "notepad.exe " +field$(FileListBox.Item(FileListBox.ItemIndex),chr$(160),1) ' FileListBox.Item(FileListBox.ItemIndex)
End Sub

'*****************************************
Sub OpenItemFolderClick
run "explorer.exe " + strippath(field$(FileListBox.Item(FileListBox.ItemIndex),chr$(160),1))

End Sub 
'*****************************************
Sub CopyFileNAmeClick
Clipboard.text=field$(FileListBox.Item(FileListBox.ItemIndex),chr$(160),1) ' FileListBox.Item(FileListBox.ItemIndex)

End Sub 

'*****************************************
Sub checkNestedDirs
with SelDirGrid ' таблица со списком директорий, где искать
	for sj=0 to .RowCount-1 ' перебираем по списку директорий из DirTreeSV.
		if .Cell(0, sj)<>"1" then goto  nextsj
		
		for si=0 to .RowCount-1 ' перебираем по списку директорий из DirTreeSV.
			if .Cell(0, si)="1" then
				celli$=.Cell(1, si)
				cellj$=.Cell(1, sj)
				if instr(.Cell(1, sj),.Cell(1, si))>0 and .Cell(1, sj)<>.Cell(1, si) then .Cell(0, sj)="0"
			else
				goto  nextsi
			end if
			
			
			nextSi:
		next si
		nextSj:
	next sj
	
end with   

End Sub 

sub h111h

end sub
'*****************************************
Sub LangChoose (Sender as QMenuItem)
Sender.checked=1
'LangIni.FileName=StartPath$+"lang\lang.ini"
'LangIni.Section="Language"
'Langini.write("default",Sender.caption)
ShowMessage (LangReload$)


End Sub 
'*****************************************
Sub DeleteFromFilelistClick
'call  AddClrString ("3561:FileListBox.SelCount="+str$(FileListBox.SelCount), clred, LogEditSV)

FileListBoxItemCount=FileListBox.ItemCount
'call  AddClrString ("3564:FileListBox.ItemCount="+str$(FileListBox.ItemCount), clred, LogEditSV)

for i=0 to FileListBoxItemCount-1
	'all  AddClrString ("3567:FileListBox.Item("+str$(i)+")="+(FileListBox.Item(i)), clred, LogEditSV)
	if i>=FileListBoxItemCount then  exit for
	
	if FileListBox.Selected(i)=1 then
		
		FileListBox.DelItems (i)
		kk=i
		'dec i
		dec FileListBoxItemCount
	else
	end if
	
next i

'call  AddClrString ("3581:kk="+str$(kk), clred, LogEditSV)

if kk<= FileListBox.ItemCount-1 then
	FileListBox.Selected(kk)=1
else
	FileListBox.Selected(FileListBox.ItemCount-1)=1
end if

End Sub 
'*****************************************
Sub CopyFile2FolderClick ' в popupmenu

if DirTreeFormSV.visible=0 then  DirTreeFormSV.show
FileNameToCopy$=field$(FileListBox.Item(FileListBox.ItemIndex),chr$(160),1) ' FileListBox.Item(FileListBox.ItemIndex)
if FileNameToCopy$ <> "" then OKDir.enabled=1 else OKDir.enabled=0


'FileNameToCopy$ = ""
End Sub 
'*****************************************
Sub CopyFileTo ' нажали кнопку copyfile

FileNameToCopy$=field$(FileListBox.Item(FileListBox.ItemIndex),chr$(160),1) ' FileListBox.Item(FileListBox.ItemIndex)


'call  AddClrString ("3606:FileNameToCopy$="+(FileNameToCopy$), clred, LogEditSV)
'if FileNameToCopy$ <> "" then OKDir.enabled=1 else OKDir.enabled=0

if fileexists(FileNameToCopy$) <> 0 then
	
	dfname$=DirTreeSV.Directory+StripFileName (FileNameToCopy$)
	call  AddClrString ("3612: Copied to "+(dfname$), clred, LogEditSV)
	
	FileCopy (FileNameToCopy$, dfname$)
	FileNameToCopy$ = ""
	'strippath(FileListBox.Item(FileListBox.ItemIndex))
	
else
	Showmessage "3619: File not exists "+FileNameToCopy$
end if

'OKDir.visible=0
'DirTreeFormSV.close 

End Sub 
'*****************************************
sub OpenFile 
OpenDialog.InitialDir=StartDir
OpenDialog.Filter ="All Files *.*|*.*| _
Html Files *.*htm*;*.js;*.vbs;*.css|*.*htm*;*.js;*.vbs;*.css| _
Txt Files  *.txt;*.doc;*.rtf;*.ini|*.txt;*.doc;*.rtf;*.ini| _
Bas Files  *.bas;*.rqb|*.bas;*.rqb|"

IF OpenDialog.Execute THEN
	'FileListBox.LoadFromFile (OpenDialog.FileName)
	'CurList=OpenDialog.FileName
	'call  AddClrString ("3637:CurList="+(CurList), clred, LogEditSV)
	'FileListBox.ItemIndex=1
	'SearchCBoxSV.Text=FileListBox.Item(0) 'FILENAMENOEXT(CurList)
	'FileListBox.DelItems (0)
	cFileName=OpenDialog.FileName
	FileLoadSV (cFileName)
	
	'FileLoadSV (OpenDialog.FileName)
	
END IF
'ValidFileList
'SearchCBoxSV.text=CurList
'LogLabel1.Caption =LangVar$(143)+str$(FileListBox.ItemCount)'+" файлов" ' LangVar$(143)=Всего 

end sub 
'*****************************************

Sub SearchCBoxOnchange

dim ret as long
DefInt wParam, lParam

ret =SendMessageAPI (SearchCBoxHnd, EM_GETSEL, VarPtr(wParam), VarPtr(lParam))
''print "ret=",hex$(ret)
bSelStart=ret AND &HFFFF
bSelMax=(ret AND &HFFFF0000) SHR 16
'bSelLength=.SelMax-.SelStart

'DefInt wParam, lParam
'DefStr sSelText
'If QRDX_SendMessage (.handle, 176, VarPtr(wParam), VarPtr(lParam)) <> - 1 Then


SearchCBoxSV.Text=replacesubstr$(SearchCBoxSV.Text," ",chr$(183)) ' 
selpos=bSelStart'len(SearchCBoxSV.Text)
qwq = SendMessageAPI (SearchCBoxHnd,EM_SETSEL,selpos,selpos)

'EM_SETSEL  
'wParam = (WPARAM) (INT) nStart;    // starting position 
'lParam = (LPARAM) (INT) nEnd;      // ending position 



'call  AddClrString ("3680:SearchCBoxOnchange=", clred, LogEditSV)
'call SearchCBoxOnDrawItem (0, 1, R ) 
'SearchCBoxSV.Repaint
'SearchCBoxSV.AddItems  SearchCBoxSV.Text
'SearchCBoxSV.Text= SearchCBoxSV.Item (0)
'SearchCBoxSV.Text= SearchCBoxSV.Item(SearchCBoxSV.ItemCount-1)
'call  AddClrString ("3686:SearchCBoxSV.ItemCount-1="+str$(SearchCBoxSV.ItemCount-1), clred, LogEditSV)

End Sub 
'*****************************************
Sub SearchCBoxOnDrawItem (Index%, State%, R AS QRect) 
'call  AddClrString ("3691:SearchCBoxOnDrawItem="+str$(SearchCBoxOnDrawItem), clred, LogEditSV)
'dim trect as QREct

'TWidth=50'SearchCBoxSV.TextWidth(SearchCBoxSV.Text)
'call  AddClrString ("3695:TWidth="+str$(TWidth), clred, LogEditSV)
'THeight=SearchCBoxSV.TextHeight(SearchCBoxSV.Text)
'THeight=SearchCBoxSV.Height 

'call  AddClrString ("3699:THeight="+str$(THeight), clred, LogEditSV)
'trect.left=1
'trect.top=1
'trect.Right =TWidth
'call  AddClrString ("3703:trect.Right="+str$(trect.Right), clred, LogEditSV)
'trect.bottom =THeight

'SearchCBoxSV.TextRect (R,5,5,SearchCBoxSV.Text, clb, clw)
'call  AddClrString ("3707:SearchCBoxSV.Text="+(SearchCBoxSV.Text), clred, LogEditSV)

'SearchCBoxSV.TextOut  (1, 1, SearchCBoxSV.Text, clb, clw)

End Sub 
'*****************************************
Sub TextOnlyOnClick
if TextOnlyMnu.checked=0 then TextOnlyMnu.checked=1 else TextOnlyMnu.checked=0

End Sub 
'*****************************************
Sub RtfFilOnClick
if RtfFil.checked=0 then RtfFil.checked=1 else RtfFil.checked=0

End Sub 
'*****************************************
Sub convert(ip)
'call  AddClrString ("3724:ip="+str$(ip), clred, LogEditSV)

Select case ip
case 0 ' windows
	if CodWin1251Mnu.checked=0 then
		NoSearch=1
	else
		NoSearch=0
		'call  AddClrString ("3732:NoSearch="+str$(NoSearch), clred, LogEditSV)
		codP$="Win"
	end if
case 1 ' dos
	if CodDosMnu.checked=1 then
		'call  AddClrString ("3737:TmpFileSLtext$,="+left$(TmpFileSLtext$,200), cldg, LogEditSV)
		oemtochar TmpFileSLtext$,TmpFileSLtext$
		'call  AddClrString ("3739:TmpFileSLtext$,="+left$(TmpFileSLtext$,200), cldg, LogEditSV)
		
	else
		NoSearch=1
	end if
	codP$="Dos"
	
case 2 ' koi
	if Koi8Mnu.checked=1 then
		'call ansi2koi(TmpFileSLtext$)
		call koi2ansi (TmpFileSLtext$)
		'call  AddClrString ("3750:TmpFileSLtext$="+(TmpFileSLtext$), clred, LogEditSV)
	else
		NoSearch=1
	end if
	codP$="Koi8"
case 3 ' utf8
	if UTF8mnu.checked=1 then
		call ConvertCP( TmpFileSLtext$ , CP_UTF8 ,CP_ACP ,  TmpFileSLtext$)
		'call  AddClrString ("3758:TmpFileSLtext$="+(TmpFileSLtext$), cldb, LogEditSV)
		TmpFileSLtext$=left$(TmpFileSLtext$,instr(TmpFileSLtext$,chr$(0))-1)
		'call  AddClrString ("3760:TmpFileSLtext$="+(TmpFileSLtext$), cldg, LogEditSV)
	else
		
		NoSearch=1
	end if
	codP$="UTF8"
case 4 ' unicode
	NoSearch=1
	
case 5
	NoSearch=1
	
case else
	NoSearch=1
	
end select
'call  AddClrString ("3776:end select=", clred, LogEditSV)

End Sub 

'*****************************************
Sub FileListBoxWndProc (Hwnd as long, Msg as long, wParam as long, lParam as long)
'call  AddClrString ("3782:Hwnd="+str$(Hwnd), clred, LogEditSV)
'call  AddClrString ("3783:Msg="+str$(Msg), clred, LogEditSV)
'call  AddClrString ("3784:WM_KILLFOCUS="+str$(WM_KILLFOCUS), clred, LogEditSV)
'if Msg%=WM_KILLFOCUS then REmoveItemFromFileList.ShortCut=""

End Sub 
'*****************************************
Sub Check1  (Key AS Word, Shift AS INTEGER)
'call  AddClrString ("3790:Key="+str$(Key), clp, LogEditSV)
Handle = GetFocus():
'call  AddClrString ("3792:Handle="+str$(Handle), clred, LogEditSV)
'call  AddClrString ("3793:FileListBox.handle="+str$(FileListBox.handle), clred, LogEditSV)
'call  AddClrString ("3794:VK_DELETE ="+str$(VK_DELETE ), clb, LogEditSV)

if key=VK_DELETE then
	select case handle
	case FileListBox.handle
		DeleteFromFilelistClick
	case else
	end select
end if 
End Sub 

