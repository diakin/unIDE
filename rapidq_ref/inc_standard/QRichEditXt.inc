$IFNDEF __QRICHEDITXT_INC   ' IncManager: include guard
$DEFINE __QRICHEDITXT_INC
'$Include "constants.inc"
const WM_USER = &H400

const    EM_AUTOURLDETECT            =WM_USER + 91

const    EM_CONVPOSITION             =WM_USER + 108
const    EM_SETLANGOPTIONS           =WM_USER + 120
const    EM_GETLANGOPTIONS           =WM_USER + 121
const    EM_GETIMECOMPMODE           =WM_USER + 122
const    EM_FINDTEXTW                =WM_USER + 123
const    EM_FINDTEXTEXW              =WM_USER + 124
const    EM_RECONVERSION             =WM_USER + 125
const    EM_SETIMEMODEBIAS           =WM_USER + 126  
const    EM_GETIMEMODEBIAS           =WM_USER + 127
const    EM_SETBIDIOPTIONS           =WM_USER + 200
const    EM_GETBIDIOPTIONS           =WM_USER + 201
const    EM_SETTYPOGRAPHYOPTIONS     =WM_USER + 202
const    EM_GETTYPOGRAPHYOPTIONS     =WM_USER + 203
const    EM_SETEDITSTYLE             =WM_USER + 204
const    EM_GETEDITSTYLE             =WM_USER + 205


const    EM_OUTLINE                  =WM_USER + 220
const    EM_GETSCROLLPOS             =WM_USER + 221
const    EM_SETSCROLLPOS             =WM_USER + 222
const    EM_SETFONTSIZE              =WM_USER + 223
const    EM_GETZOOM                  =WM_USER + 224
const    EM_SETZOOM                  =WM_USER + 225


const  WM_INPUTLANGCHANGEREQUEST=       &h0050
const  WM_INPUTLANGCHANGE  =            &h0051


const EM_CANPASTE = 1074
const EM_CANUNDO = 198
const EM_CHARFROMPOS = 215
const EM_DISPLAYBAND = 1075
const EM_EMPTYUNDOBUFFER = 205
const EM_EXGETSEL = 1076
const EM_EXLIMITTEXT = 1077
const EM_EXLINEFROMCHAR = 1078
const EM_EXSETSEL = 1079
const EM_FINDTEXT = 1080
const EM_FINDTEXTEX = 1103
const EM_FINDWORDBREAK = 1100
const EM_FMTLINES = 200
const EM_FORMATRANGE = 1081
const EM_GETCHARFORMAT = 1082
const EM_GETEVENTMASK = 1083
const EM_GETFIRSTVISIBLELINE = 206
const EM_GETHANDLE = 189
const EM_GETLIMITTEXT = 213
const EM_GETLINE = 196
const EM_GETLINECOUNT = 186
const EM_GETMARGINS = 212
const EM_GETMODIFY = 184
const EM_GETIMECOLOR = 1129
const EM_GETIMEOPTIONS = 1131
const EM_GETOPTIONS = 1102
const EM_GETOLEINTERFACE = 1084
const EM_GETPARAFORMAT = 1085
const EM_GETPASSWORDCHAR = 210
const EM_GETPUNCTUATION = 1125
const EM_GETRECT = 178
const EM_GETSEL = 176
const EM_GETSELTEXT = 1086
const EM_GETTEXTRANGE = 1099
const EM_GETTHUMB = 190
const EM_GETWORDBREAKPROC = 209
const EM_GETWORDBREAKPROCEX = 1104
const EM_GETWORDWRAPMODE = 1127
const EM_HIDESELECTION = 1087
const EM_LIMITTEXT = 197
const EM_LINEFROMCHAR = 201
const EM_LINEINDEX = 187
const EM_LINELENGTH = 193
const EM_LINESCROLL = 182
const EM_PASTESPECIAL = 1088
const EM_POSFROMCHAR = 214
const EM_REPLACESEL = 194
const EM_REQUESTRESIZE = 1089
const EM_SCROLL = 181
const EM_SCROLLCARET = 183
const EM_SELECTIONTYPE = 1090
const EM_SETBKGNDCOLOR = 1091
const EM_SETCHARFORMAT = 1092
const EM_SETEVENTMASK = 1093
const EM_SETHANDLE = 188
const EM_SETIMECOLOR = 1128
const EM_SETIMEOPTIONS = 1130
const EM_SETLIMITTEXT = 197
const EM_SETMARGINS = 211
const EM_SETMODIFY = 185
const EM_SETOLECALLBACK = 1094
const EM_SETOPTIONS = 1101
const EM_SETPARAFORMAT = 1095
const EM_SETPASSWORDCHAR = 204
const EM_SETPUNCTUATION = 1124
const EM_SETREADONLY = 207
const EM_SETRECT = 179
const EM_SETRECTNP = 180
const EM_SETSEL = 177
const EM_SETTABSTOPS = 203
const EM_SETTARGETDEVICE = 1096
const EM_SETWORDBREAKPROC = 208
const EM_SETWORDBREAKPROCEX = 1105
const EM_SETWORDWRAPMODE = 1126
const EM_STREAMIN = 1097
const EM_STREAMOUT = 1098
const EM_UNDO = 199






'___________________________________________
const WM_CUT = 768
const WM_COPY = 769
const WM_COPYDATA = 74
const WM_PASTE = 770
const WM_CLEAR = 771
const WM_CHAR = 258

'------------- /* Extended edit style masks */
const	SES_EMULATESYSEDIT		=1
const SES_BEEPONMAXTEXT			=2
const	SES_EXTENDBACKCOLOR		=4
const SES_MAPCPS				=8
const SES_EMULATE10				=16
const	SES_USECRLF				=32
const SES_USEAIMM				=64
const SES_NOIME					=128

const SES_ALLOWBEEPS			=256
const SES_UPPERCASE				=512
const	SES_LOWERCASE			=1024
const SES_NOINPUTSEQUENCECHK	=2048
const SES_BIDI					=4096
const SES_SCROLLONKILLFOCUS		=8192
const	SES_XLTCRCRLFTOCR		=16384


'-------- /* Options for EM_SETLANGOPTIONS and EM_GETLANGOPTIONS */

const IMF_AUTOKEYBOARD		= &h0001
const IMF_AUTOFONT			= &h0002
const IMF_IMECANCELCOMPLETE	= &h0004	' // high completes comp string when aborting, low cancels.
const IMF_IMEALWAYSSENDNOTIFY = &h0008
const IMF_AUTOFONTSIZEADJUST	= &h0010
const IMF_UIFONTS				= &h0020
const IMF_DUALFONT			= &h0080

'!!!======================================================================================================================'
Type Point
        Left As Long
        Top As Long
End Type
'------------------------ RichEditWndProc ------------------------------

DECLARE FUNCTION SetWindowLong LIB "user32" ALIAS "SetWindowLongA" (ByVal hWnd AS LONG, ByVal nIndex AS LONG, ByVal dwNewLong AS LONG) AS LONG

Declare Function HideCaret Lib "user32" ALIAS "HideCaret" (ByVal hwnd As Long) As Long
Declare Function ShowCaret Lib "user32" ALIAS  "ShowCaret" (ByVal hwnd As Long) As Long

Declare Function CallWindowProc Lib "user32" Alias "CallWindowProcA" _
 (ByVal lpPrevWndFunc As Long, ByVal hWnd As Long, ByVal Msg As Long, ByVal wParam As Long, _
  ByVal lParam As Long) As Long

DECLARE FUNCTION SendMessageApi LIB "user32.dll" ALIAS "SendMessageA" (hWnd AS LONG, Msg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG

Declare Function GetDC Lib "user32" Alias "GetDC"(ByVal hWnd As Long) As Long
Declare Function SetBkMode Lib "gdi32" Alias "SetBkMode" (ByVal hdc As Long, ByVal nBkMode As Long) As Long
Declare Function TextOut Lib "gdi32" Alias "TextOutA" (ByVal hdc As Long, ByVal x As Long, ByVal y As Long, ByVal lpString As String, ByVal nCount As Long) As Long

Declare Function SelectObject Lib "gdi32" Alias "SelectObject" (ByVal hdc As Long, ByVal hObject As Long) As Long
Declare Function SetTextColor Lib "gdi32" Alias "SetTextColor" (ByVal hdc As Long, ByVal crColor As Long) As Long

declare FUNCTION RichEditWndProc_EventTemplate (hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
declare SUB FormWndProc (hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG) 

DIM M AS QMEMORYSTREAM
defint FIRSTVISIBLELINE,LastVISIBLELINE

defint FirstChar

dim VisRect as QRect
dim VisPoint as Point
dim VisPoint1 as Point


TYPE QRichEdit_xt EXTENDS QRichEdit
private:
Tmr AS QTIMER '- initilization timer
OldWndProc AS LONG
WndProc AS EVENT(RichEditWndProc_EventTemplate)
KeyList as Qstringlist  '  keywords list
ScrollPoint as Point

PUBLIC:
HandleDC as integer 

HiLight  as integer PROPERTY SET Set_HiLight
KeyListName as string PROPERTY SET Set_KeyListName ' filename of keywords list
AUTOURLDETECT as integer PROPERTY SET Set_AUTOURLDETECT
LIMITTEXT as integer PROPERTY SET Set_LIMITTEXT
AUTOFONT  as integer PROPERTY SET Set_AUTOFONT
SCROLLPOS as integer PROPERTY SET Set_SCROLLPOS

with this

PROPERTY SET Set_SCROLLPOS (SCROLLPOS as integer)

.SCROLLPOS=SCROLLPOS 
print "SCROLLPOS=" ,.SCROLLPOS
print "EM_SETSCROLLPOS=" ,EM_SETSCROLLPOS

.ScrollPoint.Top=.SCROLLPOS

print SendMessageApi (.handle, EM_SETSCROLLPOS, 0, .ScrollPoint )
END PROPERTY SET



PROPERTY SET Set_AUTOFONT (AUTOFONT  as integer)
.AUTOFONT=AUTOFONT

END PROPERTY SET


PROPERTY SET Set_LIMITTEXT (LIMITTEXT as integer )
if LIMITTEXT> 65535*32 then LIMITTEXT=65535*32
.LIMITTEXT=LIMITTEXT
print ".LIMITTEXT=" ,.LIMITTEXT

END PROPERTY SET



PROPERTY SET Set_AUTOURLDETECT (AUTOURLDETECT as integer )
             .AUTOURLDETECT=AUTOURLDETECT 
             print ".AUTOURLDETECT=" ,.AUTOURLDETECT

END PROPERTY SET

PROPERTY SET Set_KeyListName  (KeyListName as string)
            .KeyListName=KeyListName 
            print "KeyListName=" ,.KeyListName

END PROPERTY SET

        PROPERTY SET Set_HiLight(HiLight AS integer)
            .HiLight = HiLight 
            print "HiLight=" ,HiLight
            if .HiLight =1 then
            end if
        END PROPERTY SET



        FUNCTION Proc(hWnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG 
            
            IF hWnd = .Handle THEN
                Result = CallWindowProc(.OldWndProc, hWnd, uMsg, wParam, lParam)  

 if .HiLight=0 then goto noHiLi 
  SELECT CASE uMsg
  CASE  WM_PAINT '---- <--------------------------------------
print "RichEdit WM_PAINT=",WM_PAINT
'HideCaret hWnd

'hdc=GetDC(hWnd) : print "hdc=" ,hdc
'print "proc .HandleDC=",.HandleDC
hdc=.HandleDC
'__ Set the bitmap's backmode to transparent
previous_background_mode=SetBkMode (hDC, TRANSPARENT) 
'previous_background_mode=SetBkMode (hDC, OPAQUE) 
'__ select font
Curent = SelectObject(hdc, HiLiteFont.Handle)
rgbPrev = SetTextColor(hdc, HiLiteFont.color)

'__ Get visible rect

    M.WriteUDT(VisRect)
result= SendMessageAPI (hWnd,EM_GETRECT,0,M.Pointer)
    M.Position = 0
    M.ReadUDT(VisRect)
    M.Position = 0
'print "Rect.Left=",VisRect.Left, " Rect.top=",VisRect.top
'print "Rect.Right=",VisRect.Right, " Rect.Bottom=",VisRect.Bottom

'__ Get point structure (may be not needed)
VisPoint.Left=VisRect.Left
VisPoint.Top=VisRect.Top
    M.Position = 0
    M.WriteUDT(VisPoint)
    M.Position = 0
'__Get char index from begin 
lchar=SendMessageAPI (hWnd,EM_CHARFROMPOS,0,M.Pointer)
'__ get first visible line 
 line_number= SendMessageAPI (hWnd,EM_LINEFROMCHAR,lchar,0 )
'__ Hehe, more easy (get first visible line )
FIRSTVISIBLELINE= SendMessageAPI (hWnd,EM_GETFIRSTVISIBLELINE,0,0) 
'print "FIRSTVISIBLELINE=" ,FIRSTVISIBLELINE
FirstChar=SendMessageAPI (hWnd,EM_LINEINDEX,line_number,0) 

VisPoint.Left=VisRect.Right
VisPoint.Top=VisRect.Bottom
    M.Position = 0
    M.WriteUDT(VisPoint)
    M.Position = 0
Lastchar=SendMessageAPI (hWnd,EM_CHARFROMPOS,0,M.Pointer)'addr_rect 
'print "Lastchar=" ,Lastchar

'__ get LastVISIBLELINE 
LastVISIBLELINE=SendMessageAPI (hWnd,EM_LINEFROMCHAR,Lastchar,0 )
'print "LastVISIBLELINE=" ,LastVISIBLELINE
'bas2Html '-<<<<<<<<<<<<<<<<<<<<<<<<'

DEFINT useEscapes = FALSE

    DIM i       AS LONG
    DIM j       AS LONG
    DIM quote   AS BYTE
    DIM ch      AS STRING * 1
    DIM token   AS STRING
'----------	
dim CurPos  AS LONG  '-- позиция текущего символа относительно начала файла
dim StrPos  AS LONG  '-- позиция первого символа текущей строки относительно начала файла

StrPos=FirstChar
CurPos=0
j=0
i=0

RhWnd=RichEdit.Handle 
'print "RhWnd=" ,RhWnd
'-- файл уже считан в richedit. Используем массив richedit.line()    
FOR i =FIRSTVISIBLELINE  TO  LastVISIBLELINE  '- перебираем по строкам
	quote = FALSE
	token = ""
	FOR j = 1 TO len(richedit.line(i)) '- разбираем строку посимвольно
		CurPos=j +StrPos   '- текущий символ от начала первой видимой строки.
		ch = richedit.line(i)[j]       '- массив символов строки 
		IF instr("+-=<>()\/^&*[]:;?,' "+chr$(34)+chr$(9), ch) THEN  '- символ - знак
        	IF ch = chr$(34) THEN        '--- ------- если кавычка -----------
				token = ""
				kk=0
'-------------------------
SendMessageAPI (rhWnd,EM_POSFROMCHAR, VisPoint1,CurPos-1)
rgbPrev = SetTextColor(hdc, clGreen)
TextOut(hdc, VisPoint1.left, VisPoint1.top, ch, len(ch))
'-------------------------
                FOR j = j+1 TO len(richedit.line(i)) '---   начало строкового
					CurPos=j +StrPos
                    ch = richedit.line(i)[j] 
					IF ch = chr$(34) THEN  '--- ------- если кавычка -----------
						
'-------------------------
SendMessageAPI (rhWnd,EM_POSFROMCHAR, VisPoint1,CurPos-1)
rgbPrev = SetTextColor(hdc, clGreen)                         
TextOut(hdc, VisPoint1.left, VisPoint1.top, ch, len(ch))
'-------------------------
                    	kk=1
                    	EXIT FOR
					ELSEif ch="'" then
					RemFlg=1
					kk=1
					exit for
					else
                    	IF ch = "<" THEN
							token = token +ch'' "&lt;" '- левая угловая скобка
						ELSE
							token = token + ch
						END IF
                	END IF
                NEXT
            	'--- конец определения строкового
'-------------------------
SendMessageAPI (rhWnd,EM_POSFROMCHAR,VisPoint1,CurPos-len(token)-kk)
rgbPrev = SetTextColor(hdc, clOrange)
'previous_background_mode=SetBkMode (hDC, clGreen) 
TextOut(hdc, VisPoint1.left, VisPoint1.top, token, len(token))
'-------------------------
if RemFlg=1 then RemFlg=0 : goto RemF

'*                	fOut.write("<font color=\"990000\">"+token+"</font>") '--- записываем строковое
                
                ELSEIF ch = "'" THEN '-- комментарий ---------------
                	RemF:
                	'--- запоминаем позицию начала комментария'
                	RemPos=CurPos-1 
''                	print "RemPos=" ,RemPos
                	IF token <> "" THEN '- если перед комментарием был токен, то проверяем, является ли он ключевым словом
                        if instr(.keyList.Text,ucase$(token))>0 then
'*                        	fOut.write("<font color=\"aa00AA\"><b>"+token+"</b></font>")'- подсвечиваем
'-------------------------
SendMessageAPI (rhWnd,EM_POSFROMCHAR,VisPoint1,CurPos-len(token)-1)
rgbPrev = SetTextColor(hdc, clPurple)
TextOut(hdc, VisPoint1.left, VisPoint1.top, token, len(token))
'-------------------------
                        ELSE
'*                        	fOut.write(token)  '- не подсвечиваем
                    	END IF
                	END IF
                	token = ""   '- начинаем новый токен - комментарий
                	rempos1=instr(richedit.line(i),"'")
					token =mid$(richedit.line(i),RemPos1, len(richedit.line(i))-RemPos1+1) 
'					print "token=" ,token
					j=j+len(token)
					CurPos=j +StrPos
'---- комментарий ---------------
'*                	fOut.write("<font color=\"007700\"><i>"+token+"</i></font>")
'-------------------------
SendMessageAPI (rhWnd,EM_POSFROMCHAR,VisPoint1,RemPos)
rgbPrev = SetTextColor(hdc, clDGreen)
TextOut(hdc, VisPoint1.left, VisPoint1.top, token, len(token))
'-------------------------
                	ch = ""
                ELSEIF ch = chr$(9) THEN '---- tab  !!!!!!!!!!!! replaced by 4 spaces in source
                ELSEIF token <> "" THEN
                        if instr(.keyList.Text,ucase$(token))>0 then
'*'                    	fOut.write("<font color=\"0000AA\"><b>"+token+"</b></font>")
'-------------------------
SendMessageAPI (rhWnd,EM_POSFROMCHAR,VisPoint1,CurPos-len(token)-1)
rgbPrev = SetTextColor(hdc, clBlue)

TextOut(hdc, VisPoint1.left, VisPoint1.top, token, len(token))
'-------------------------
                     ELSE
'*'                   	fOut.write(token)
                	END IF
                END IF

                IF ch = "<" THEN
'-------------------------
SendMessageAPI (rhWnd,EM_POSFROMCHAR,VisPoint1,CurPos-1)
rgbPrev = SetTextColor(hdc, clDRed)
TextOut(hdc, VisPoint1.left, VisPoint1.top, ch, len(ch))
'-------------------------
'*'                	fOut.write("&lt;")
                ELSEIF instr("+-=<>\/^&*:", ch) THEN
'-------------------------
SendMessageAPI (rhWnd,EM_POSFROMCHAR,VisPoint1,CurPos-1)
rgbPrev = SetTextColor(hdc, &H9E5CFF)
TextOut(hdc, VisPoint1.left, VisPoint1.top, ch, len(ch))
'-------------------------
                ELSEIF instr("()[]", ch) THEN
'-------------------------
SendMessageAPI (rhWnd,EM_POSFROMCHAR,VisPoint1,CurPos-1)
rgbPrev = SetTextColor(hdc, &H790097)
TextOut(hdc, VisPoint1.left, VisPoint1.top, ch, len(ch))
'-------------------------
                ELSE
''                	fOut.write(ch)
                END IF
            	token = ""
            ELSE
            	token = token + ch
        	END IF
        NEXT j
        IF token <> "" THEN
            if instr(.keyList.Text,ucase$(token))>0 then
'-------------------------
SendMessageAPI (rhWnd,EM_POSFROMCHAR,VisPoint1,CurPos-len(token))
rgbPrev = SetTextColor(hdc, &H0000DA)
TextOut(hdc, VisPoint1.left, VisPoint1.top, token, len(token))
'-------------------------
'*'                fOut.write("<font color=\"000099\"><b>"+token+"</b></font>")
            ELSE
'*'                fOut.write(token)
            END IF
        END IF
            	StrPos=StrPos+len(richedit.line(i))+2'StrPos+j 
    NEXT i

print "end bas2Html"
END SELECT
noHiLi:                
IF .WndProc>0 THEN CALLFUNC(.WndProc, hWnd, uMsg, wParam, lParam) '- если есть пользовательская функция, то вызывается и она
            

  END IF
        END FUNCTION

        EVENT Tmr.OnTimer
.ScrollPoint.Top=.SCROLLPOS

SendMessageApi .handle, EM_SETSCROLLPOS, 0, .ScrollPoint

                if .HiLight=1 then 
                .KeyList.LoadFromFile(.KeyListName)
                end if

                if .AUTOFONT=0 then ' inc2026: .AUTOFONT вместо AUTOFONT: без точки внутри WITH THIS это необъявленная переменная (0), условие всегда истинно; соседние проверки - .HiLight, .AUTOURLDETECT (строки 492, 501)
SendMessageApi .handle, EM_SETLANGOPTIONS, 0, SendMessageApi(.handle, EM_GETLANGOPTIONS, 0, 0) & -IMF_AUTOFONT 

                end if

                if .AUTOURLDETECT=1 then
                 print "SendMessageApi(em_AUTOURLDETECT) =",SendMessageApi ( .handle,em_AUTOURLDETECT,1,0)
                end if
                 SendMessageAPI .handle,EM_EXLIMITTEXT,0,.LIMITTEXT
                .HandleDC=GetDC (This.Handle) 
                .OldWndProc = SetWindowLong(This.Handle, GWL_WNDPROC, CODEPTR(This.Proc))
                .Tmr.Enabled = 0
        END EVENT

    
        CONSTRUCTOR
            SCROLLPOS=1
            LIMITTEXT=65535*32
            AUTOFONT=0 
            HiLight=0
''            AUTOURLDETECT=0
            Tmr.Interval = 1
        END CONSTRUCTOR
    
    END WITH

END TYPE
$ENDIF   ' IncManager: __QRICHEDITXT_INC
