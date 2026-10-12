' ======================================= '
'  About QSavePlus
' ======================================= '
'-- QSavePlus is extends from QSaveDialog ,
'-- 1) If don't found any extension or found unusual extension in FileName,
'-- will show Add Extension Confirm Dialog.
'-- 2) Plus directory and FileName Checking.
'-- 3) show Confirm Dialog before save exist file.
'-- This code only test on Win98.

' Author : Suchart Chokphichitchai
' E-mail  : dragon_html@yahoo.com
' My skillfull about English Language is very weak.
' If you don't understand the description,
' or you found bug of this code.
' Please contact me to modify it.

'$TYPECHECK ON
$ESCAPECHARS ON

' ======================================= '
'  const
' ======================================= '
const dot = "."  :const Quo$ = chr$(39)

const false = 0  :const true = 1

'const mtWarning = 0 :const mtConfirmation = 3

'const mbYes = 1  :const mbNo = 2
'const mbOK = 4  :const mbCancel = 8

'const mrYes = 6  :const mrNo = 7
'const mrCancel = 2 :const mrOK = 1

Function delMark$( s as string ) As String
s=replaceSubstr$(s," ","")
s=replaceSubstr$(s,"\t","")
delMark$=replaceSubstr$(s,"*.","")
End Function

' ======================================= '
'  OBJECT Extends
' ======================================= '

TYPE QSaveplus Extends QSaveDialog
Private:
saveDialogRet AS INTEGER
goOut AS INTEGER

Function item( i as integer ) As String
' Result example '
'-- item(1)="*.*"
'-- item(2)="*.js"
'-- item(3)="*.php3;*.php"
Result = Field$( QSaveplus.Filter, "|", i*2 )
End Function
Function itemCount As Integer
' Result example ' ( value of number of all item )
'-- itemCount = 7
Result = Tally(QSaveplus.Filter,"|")\2
End Function
Function extCount( i as integer ) As Integer
' Result example ' ( value of number of extension in one item)
'-- extCount(1) = 1 [ *.* ]
'-- extCount(2) = 1 [ *.js ]
'-- extCount(3) = 2 [ *.php3;*.php ]
Result = Tally( QSaveplus.item( i ), "*." )
End Function
Function ext( t as Integer, i as integer ) As String
dim e as string
' Result example '
'-- ext(3,1) = "php3"
'-- ext(3,2) = "php"
e = Field$( QSaveplus.item( t ), ";", i )
Result = delMark$( e )
End Function
Function Exten$ As String
' Result example '
'-- if FilterIndex = 4
'--   Exten$ = "pl"
'-- if FilterIndex = 2
'--   Exten$ = "js"
Result = QSaveplus.ext( QSaveplus.FilterIndex, 1 )
End Function
Function DirExist As Integer
dim fileDir$ AS string
dim BslPos as integer
' Result example '
'-- if dir of FileName is exist.
'-- DirExist=1
'-- if dir of FileName is not exist.
'-- DirExist=0
BslPos = RINSTR(QSaveplus.Filename,"\\")
fileDir$ = Delete$(QSaveplus.Filename, BslPos+1, len(QSaveplus.Filename)-BslPos)
'ShowMessage "DirName="+fileDir$
Result = DirExists(fileDir$)
End Function
Function NoExten As INTEGER
dim FileLC$ as string
dim EachExt$ as string
dim FoundExt as integer
dim cou as integer
' Result example '
'-- if FilterIndex = 2
'--   if not found extension (Ex. c:\abc )
'--   or if found unusual extension. (Ex. c:\abc.ss)
'--     NoExten=1
'--   but if found usual extension. (Ex c:\abc.js)
'--     NoExten=0
FoundExt=False
FileLC$ = LCASE$(QSaveplus.FileName)
FOR cou = 1 TO QSaveplus.ExtCount( QSaveplus.FilterIndex ) '-- EXTCOUNT
	EachExt$ = dot+LCASE$( QSaveplus.Ext( QSaveplus.FilterIndex, cou ) ) '-- EXT
	'  ShowMessage "right str= "+Right$(FileLC$,LEN(EachExt$))+_
	'  "\r\extension"+str$(cou)+"= "+EachExt$
	IF Right$(FileLC$,LEN(EachExt$)) = EachExt$ THEN
		FoundExt = True
		exit for
	END IF
NEXT
IF FoundExt = False THEN
	Result = True
ELSE
	Result = False
END IF
End Function
Function PlusExt As String
' Result example '
'-- if FilterIndex=2
'--   if FileName="c:\abc."
'--     add only "js"
'--   if FileName="c:\abc"
'--     add ".js"
IF right$(QSaveplus.Filename,1) = dot THEN
	Result = QSaveplus.Filename+QSavePlus.Exten$
ELSE
	Result = QSaveplus.Filename+dot+QSavePlus.Exten$
END IF
End Function
Function Validname As INTEGER
' Result example '
'-- if found ">" in FileName
'--  Validname=0
IF instr(QSaveplus.Filename,">") <> 0 THEN
	Result = False
ELSE
	Result = True
END IF
End Function
Sub goOutTrue
'-- go out the loop. by set goOut=1
QSavePlus.goOut = True
END Sub
Sub FileExistDlg
'-- if FileName is exist, show Confirm Dialog.
IF fileExists(QSaveplus.Filename) THEN
	'-- FileName is exist.
	IF MESSAGEDLG(Quo$+QSaveplus.FileName+Quo$+_
	" already exists.\r\nDo you want to replace it?",_
	mtConfirmation, mbYes OR mbNo, 0) = mrYes THEN
	'-- if select Yes
	QSavePlus.goOutTrue
END IF
ELSE
	'-- FileName is not exist.
	QSavePlus.goOutTrue
END IF '-- if not cancel
END Sub
Public:
Function Execute2 AS Integer
dim mrValue as integer
QSavePlus.goOut = False
Do
'-- Execute and keep value in saveDialogRet.
QSavePlus.saveDialogRet = QSaveplus.Execute

IF QSavePlus.saveDialogRet = False THEN '-- Click Cancel button.
	QSavePlus.goOutTrue
ELSE '-- Click Save button.
	IF QSavePlus.Validname = True THEN '-- FileName is valid.
		IF QSavePlus.dirExist = False THEN ' === Directory of FileName is not exist. === '
			MESSAGEDLG(QSaveplus.Filename+_
			"\r\nPath does not exist."+_
			"\r\nPlease verify the correct path was given.",_
			mtWarning, mbOK, 0)
			QSaveplus.Filename=CurDir$+"\\*."+QSavePlus.Exten$
		ELSEIF QSavePlus.NoExten = True THEN ' === No extension or False extension. === '
			IF QSaveplus.FilterIndex = 1 THEN '-- FilterIndex is "All Files"
				QSavePlus.FileExistDlg
			ELSE '-- FilterIndex is not "All Files", Select add extension or not.
				mrValue=MESSAGEDLG(QSaveplus.FileName+_
				"\r\nThere is no file extension in the file name."+_
				"\r\nDo you want to add '"+QSavePlus.Exten$+"' extension automatically?",_
				mtConfirmation, mbYes OR mbNo OR mbCancel, 0)
				IF (mrValue = mrYes) OR (mrValue = mrNo) THEN
					IF mrValue = mrYes THEN
						QSaveplus.Filename = QSavePlus.PlusExt
					END IF
					QSavePlus.FileExistDlg
				END IF
			END IF
		ELSE ' === Found usual extension of Filter. === '
			QSavePlus.FileExistDlg
		END IF
	ELSE '-- FileName is invalid.
		MESSAGEDLG(QSaveplus.Filename+_
		"\r\nThe above file name is invalid.",_
		mtWarning, mbOK, 0)
	END IF
END IF '-- saveDialogRet
Loop Until QSavePlus.goOut = True
Result = QSavePlus.saveDialogRet
END Function
END TYPE
' - - - - - - - - - - - - - - - - - - - - End QSavePlus - - - - - - - - - - - - - - - - - - - - '


' ======================================= '
'  EXAMPLE
' ======================================= '

DECLARE SUB formClick
CREATE form AS QFORM
	CREATE R AS QRichEdit
		Text="abc\r\n123"
	END CREATE
	Center
	OnClick = formClick
END CREATE

CREATE saveDlg AS QSaveplus
	Filter = _
	"All Files (*.*)"     + "|*.*|"+_
	"JavaScript (*.js)"    + "|*.js|"+_
	"PHP (*.php3,*.php)"   + "|*.php3;*.php|"+_
	"Perl (*.pl,*.pm,*.cgi)"   + "|*.pl;*.pm;*.cgi|"+_
	"Rapid-Q BASIC (*.rq,*.bas)" + "|*.rq;*.bas|"+_
	"Html (*.html,*.htm)"    + "|*.html;*.htm|"+_
	"Text (*.txt)"      + "|*.txt|"
	'-- it can change to other extension.
	
	'  Compatible Filter. '
	' 1)  [ Filter 1 ]  must be only [ All Files |*.*| ]
	' Ex:
	'  " Javascript |*.js|" ...Not OK
	'  " All Files |*.*|"  ...OK
	'  " All Files |*.*| Javascript |*.js|"  ...OK
	' 2) It must not have blank-ascii or tab-ascii at end of extension.
	' Ex:
	'  " All Files |*.* | " ...Not OK
	'  " All Files |*.* | " ...Not OK
	'  " All Files |  *.*|"  ...OK
	'  " All Files |*.*|"  ...OK
	'  " All Files |*.*| PHP |*.php3;*.php   |"  ...Not OK
	'  " All Files |*.*| PHP |*.php3   ;*.php|"  ...Not OK
	'  " All Files |*.*| PHP |   *.php3;   *.php|"  ...OK
	' 3) Positions of |-ascii only must be last of each text.
	' Ex:
	'  " All Files |*.*"  ...Not OK ( Don't have |-ascii at end of *.* )
	'  "| All Files |*.*|"  ...Not OK ( Have |-ascii at begin of " All Files" )
	'  "| All Files |*.*"  ...Not OK ( Don't have |-ascii at end of *.* , and Have |-ascii at begin of " All Files" )
	'  " All Files |*.*|"  ...OK
	'  " All Files |*.*| JavaScript |*.js"  ...Not OK ( Don't have |-ascii at end of *.js )
	'  "| All Files |*.*| JavaScript |*.js|"  ...Not OK ( Have |-ascii at begin of " All Files" )
	'  "| All Files |*.*| JavaScript |*.js"  ...Not OK ( Don't have |-ascii at end of *.js , and Have |-ascii at begin of " All Files" )
	'  " All Files |*.*| JavaScript |*.js|"  ...OK
END CREATE


SUB formClick
IF saveDlg.Execute2 = 1 THEN
	ShowMessage "Save File.. "+saveDlg.FileName
	'-- when you sure that all code is not dangerous.
	'-- and you want to save file really, delete ' of below line
	' r.savetofile( saveDlg.FileName )
ELSE
	ShowMessage "No Save"
END IF
END SUB

form.ShowModal  
