'HiLightDllv4.bas

'option explicit
#ifdef FB__WIN32
'$include: 'inc\win\kernel32.bi'
#endif
'$INCLUDE: 'crt.bi'


Type QPoint
Left As Long
Top As Long
End Type

type QRECT 
left As Long
top  As Long
right  As Long
bottom  As Long
End Type


TYPE  CHARRANGE 
cpMin   AS  long              
cpMax   AS  long              
END TYPE

flsel=-1



#define EM_SETBKGNDCOLOR  1091
#define WM_SETTEXT 12
'#define EM_POSFROMCHAR
'-- messages
#define WM_DESTORY  2
#define WM_PAINT  &HF

#define clBlack  0
'Private Const 
#define COLOR_BTNFACE  15

'-- BGR
#define clBlue  &HFF0000  '256
#define clLBlue  &HFFaa00  '256clLtBlue
#define clLtBlue  &HFFaa00  '256clLtBlue
#define clDBlue  &H800000 '128

#define clMaroon  &H808000

#define clGreen  &H00FF00
#define clDGreen  &H008000

#define clLRed  &H8080FF
#define clRed    &H0000FF
#define clDRed  &H000080

#define clPurple  &HFF00FF
#define clDPurple &h800080

#define clLMagenta  &HFF00FF
#define clMagenta &h800080

#define clSilver  &hc0c0c0
#define clGrey &h808080
#define clGray &h808080
#define clDGray &h808080
#define clDGrey &h808080
#define clWhite  &HFFFFFF

#define clAqua &hffff00
#define clLAqua &hfffff0

#define clyellow &h00ffff
#define clBrown &h008080
#define clOrange &h0080FF

#define  WM_COPY  769
#define  EM_EXGETSEL  1076


'-- Edit Control Messages
#define EM_EXLIMITTEXT  1077
#define EM_GETSEL  &HB0
#define EM_SETSEL  &HB1
#define EM_GETRECT  &HB2
#define EM_SETRECT  &HB3
#define EM_SETRECTNP  &HB4
#define EM_SCROLL  &HB5
#define EM_LINESCROLL  &HB6
#define EM_SCROLLCARET  &HB7
#define EM_GETMODIFY  &HB8
#define EM_SETMODIFY  &HB9
#define EM_GETLINECOUNT  &HBA
#define EM_LINEINDEX  &HBB
#define EM_SETHANDLE  &HBC
#define EM_GETHANDLE  &HBD
#define EM_GETTHUMB  &HBE
#define EM_LINELENGTH  &HC1
#define EM_REPLACESEL  &HC2
#define EM_GETLINE  &HC4
#define EM_LIMITTEXT  &HC5
#define EM_CANUNDO  &HC6
#define EM_UNDO  &HC7
#define EM_FMTLINES  &HC8
#define EM_LINEFROMCHAR  &HC9
#define EM_SETTABSTOPS  &HCB
#define EM_SETPASSWORDCHAR  &HCC
#define EM_EMPTYUNDOBUFFER  &HCD
#define EM_GETFIRSTVISIBLELINE  &HCE
#define EM_SETREADONLY  &HCF
#define EM_SETWORDBREAKPROC  &HD0
#define EM_GETWORDBREAKPROC  &HD1
#define EM_GETPASSWORDCHAR  &HD2
#define EM_CHARFROMPOS  &HD7
#define EM_POSFROMCHAR  &HD6
#define EM_GETSELTEXT  1086


' Background Modes
#define TRANSPARENT  1
#define OPAQUE  2
#define BKMODE_LAST  2

'-- EDITWORDBREAKPROC code values
#define WB_LEFT  0
#define WB_RIGHT  1
#define WB_ISDELIMITER  2


#define GWL_WNDPROC  (-4)
#define GWL_HWNDPARENT  (-8)

Declare Function TabbedTextOut Lib "user32" Alias "TabbedTextOutA" _
(ByVal hdc As Long, ByVal x As Long, ByVal y As Long, ByVal lpString As String, _
ByVal nCount As Long, ByVal nTabPositions As Long, lpnTabStopPositions As Long, ByVal nTabOrigin As Long) As Long


Declare Function SendMessageA LIB "user32" Alias "SendMessageA" _
(ByVal hwnd As Integer, ByVal wMsg As Integer, ByVal wParam As Integer,  byref lParam As any ) As Integer

Declare Function GetDC Lib "user32" Alias "GetDC"(ByVal hWnd As Long) As Long

Declare Function ReleaseDC Lib "user32" Alias "ReleaseDC" _
(ByVal hwnd As Long, ByVal hdc As Long) As Long

Declare Function SetBkMode Lib "gdi32" Alias "SetBkMode" (ByVal hdc As Long, ByVal nBkMode As Long) As Long
Declare Function TextOut Lib "gdi32" Alias "TextOutA" (ByVal hdc As Long, ByVal x As Long, ByVal y As Long, byref lpString As any, ByVal nCount As Long) As Long

Declare Function SelectObject Lib "gdi32" Alias "SelectObject" (ByVal hdc As Long, ByVal hObject As Long) As Long
Declare Function SetTextColor Lib "gdi32" Alias "SetTextColor" (ByVal hdc As Long, ByVal crColor As Long) As Long

Declare Function FillRect Lib "user32" Alias "FillRect" _ 
(ByVal hdc As Long, lpRect As QRect, ByVal hBrush As Long) As Long

Declare Function GetBkColor Lib "gdi32" Alias "GetBkColor" (ByVal hdc As Long) As Long
Declare Function SetBkColor Lib "gdi32" Alias "SetBkColor" (ByVal hdc As Long, ByVal crColor As Long) As Long

Declare Function DrawText Lib "user32" Alias "DrawTextA" _
(ByVal hdc As Long, ByVal lpStr As String, ByVal nCount As Long, _
lpRect As QRECT, ByVal wFormat As Long) As Long

Declare Function CreateSolidBrush Lib "gdi32" Alias "CreateSolidBrush" (ByVal crColor As Long) As Long

'declare function HiLight  alias "HiLight" (byval RhWnd as long, byval HiLiteFontHandle as long) as long
'declare function HiLight  alias "HiLight" (byval RhWnd as long, byval HiLiteFontHandle as long, byval  ptrKeyList As byte ptr, byval hthl as long) as long
'declare function HiLight  alias "HiLight" (byval RhWnd as long, byval HiLiteFontHandle as long,byval HiLiteFontBoldHandle as long, byval  ptrKeyList As byte ptr, byval hthl as long) as long

declare function HiLight  alias "HiLight" (byval RhWnd as long, byval HiLiteFontHandle as long, ptrHLClrs as long ptr, byval  ptrKeyList As byte ptr, byval hthl as long) as long

' ---$include: 'DllMain.bi'
'-- *****************************************************************************************************************
Function HiLight (byval RhWnd as long, byval HiLiteFontHandle as long, ptrHLClrs as long ptr,  byval ptrKeyList As byte ptr, byval hthl as long) as long export

DIM xp As long Ptr:  xp = @ptrHLClrs : DIM HiLiteColors(0 to 15) AS long : MEMCPY(@HiLiteColors(0), xp, 16 * SIZEOF(long))
'DIM xp As Single Ptr:  xp = @lpxr : DIM xr(n) AS SINGLE : MEMCPY(@xr(0), xp, n * SIZEOF(SINGLE))

'print "ptrKeyList="; ptrKeyList
'dim hBrush as long
'hBrush = CreateSolidBrush(clLBlue)

dim VisPoint as QPoint
dim VisPoint1 as QPoint
dim VisRect as QRect

dim VisRectPtr as QRect ptr
VisRectPtr=@VisRect

dim CHARRANGE1 as CHARRANGE
dim CHARRANGEPtr as CHARRANGE ptr
CHARRANGEPtr=@CHARRANGE1



dim hdc as integer '-- device handle'
dim previous_background_mode as long,rgbPrev as long
dim Curent as integer 
dim result1 as integer ,kk as long,RemFlg as long,RemPos as long,RemPos1 as long
dim bgcolor as long

dim keyListText as string
'keyListText=LoadString ("keyword.lst")
keyListText=string$(3048,"-")
'print "1 keyListText=" ;len(keyListText)
keyListText= *ptrKeyList

'print "2 keyListText=" ;len(keyListText)

'"DIM CREATE"
dim _crlf as byte
_crlf=2

if hthl =0 then 
	hthl =0
	_crlf=1
elseif hthl =1 then
	hthl =1
	_crlf=1
	
elseif hthl =2 then
	hthl =0
	_crlf=2
	
elseif hthl =3 then
	hthl =1
	_crlf=2
	
else
end if

'print"hthl=";hthl
'print"crlf=";_crlf

DIM i       AS LONG
DIM j       AS LONG , j1 as long
DIM quote   AS BYTE
DIM ch      AS STRING'' * 1
DIM token   AS STRING
'----------
dim CurPos  AS LONG  '-- char pos  from file beginning  
dim StrPos  AS LONG  '-- firs char in current line  position   (from file beginning)   

dim lchar   AS LONG  
dim line_number   AS LONG  ,LINELENGTH  AS LONG 
dim  FirstChar  AS LONG  
dim  LastChar  AS LONG  
dim  FIRSTVISIBLELINE  AS LONG  
dim  LastVISIBLELINE  AS LONG  
dim  richeditline as string
dim rline as byte ptr

richeditline=string$(2,"-")
rline=sadd (richeditline)

hdc=GetDC(RhWnd) : 'print "hdc=" ,hdc

'__ Set the bitmap's backmode to transparent
'previous_background_mode=SetBkMode (hDC, TRANSPARENT) 
previous_background_mode=SetBkMode (hDC, OPAQUE) 


'__ select font
Curent = SelectObject(hdc, HiLiteFontHandle)
SetTextColor(hdc, HiLiteColors(9)) '&H00ffFF текст цветом фона
SetBkColor(hdc,HiLiteColors(0))

'__ Get visible rect

result1= SendMessageA (rhWnd,EM_GETRECT,0,  VisRect)

'__ Get point structure (may be not needed)
VisPoint.Left=VisRect.Left
VisPoint.Top=VisRect.Top

'__Get char index from begin 
lchar=SendMessageA (rhWnd,EM_CHARFROMPOS,0,VisPoint)

'__ get first visible line 
line_number= SendMessageA (rhWnd,EM_LINEFROMCHAR,byval lchar,0 )

'__ Hehe, more easy (get first visible line )
FIRSTVISIBLELINE= SendMessageA (rhWnd,EM_GETFIRSTVISIBLELINE,0,0)
FirstChar=SendMessageA (rhWnd,EM_LINEINDEX,byval line_number,0) 

VisPoint.Left=VisRect.Right
VisPoint.Top=VisRect.Bottom
Lastchar=SendMessageA (rhWnd,EM_CHARFROMPOS,0, VisPoint)'addr_rect 

'__ get LastVISIBLELINE 
LastVISIBLELINE=SendMessageA (rhWnd,EM_LINEFROMCHAR,byval Lastchar,0 )


SendMessageA (rhWnd,EM_EXGETSEL, byval 0, byval @CHARRANGE1)
'SendMessageA (rhWnd,EM_POSFROMCHAR, byval @VisPoint,byval CHARRANGE1.cpMin)

lensel=CHARRANGE1.cpMax-CHARRANGE1.cpMin
'print"296:lensel=";lensel


StrPos=FirstChar
CurPos=0
j=0
i=0
flDigit=-1

'print"343:CHARRANGE1.cpMin=";CHARRANGE1.cpMin
'print"343:CHARRANGE1.cpMax=";CHARRANGE1.cpMax


FOR i =FIRSTVISIBLELINE  TO LastVISIBLELINE  '-   count visible lines !
	quote = FALSE
	token = ""
	ch =""
	
	FirstChar=SendMessageA (byval rhWnd,EM_LINEINDEX, i,0) '!! первый символ i-той строки  
	LINELENGTH =SendMessageA (byval rhWnd,EM_LINELENGTH ,byval FirstChar,0) 
	
	if LINELENGTH >0 then 
		richeditline=string$(LINELENGTH,"-") ' create buffer
		rline=sadd (richeditline)
	else
		richeditline=""
		rline=sadd (richeditline)
		goto nexti
	end if
	SendMessageA (rhWnd,EM_GETLINE, byval i, byval rline)
	novFlag=0
	
	'! пропускаем подсветку выделения 
	'lensel=CHARRANGE1.cpMax-CHARRANGE1.cpMin
	'print"289:CHARRANGE1.cpMin=";CHARRANGE1.cpMin
	'print"289:CHARRANGE1.cpMax=";CHARRANGE1.cpMax
	
	'print"========= 330:FirstChar=";FirstChar
	
	' if FirstChar>= CHARRANGE1.cpMin  and (FirstChar +len(richeditline)) <= CHARRANGE1.cpMax then
	'goto nexti
	'end if
	
	
	
	' print"richeditline=";richeditline
	
	FOR j = 1 TO len(richeditline) '- '-  chars in the current line i ! 
		Curent = SelectObject(hdc, HiLiteFontHandle)
		CurPos=j +StrPos   '-  
		ch = mid$(richeditline,j,1) ' получили символ
		
		' если позиция символа попадает в диапазон выделения, то не подсвечиваем его !
		if CurPos>= CHARRANGE1.cpMin and CurPos <= CHARRANGE1.cpMax then
			
			flsel=1 ' здесь флаг только взводится!!!!
			'print"351:flsel=";flsel
		end if
		
		IF instr("+-=<>(){}\/^&*[]:;?,.#!@$%~`_' "+chr$(34)+chr$(9), ch) >0 THEN  ' если разделитель токена ! 
			
			' то надо подсветить предыдущий токен !!!!
			IF token <> "" THEN '- if token before - hilite it! 
				if flsel<>1 then
					
					if instr(keyListText,ucase$(token))>0 and flsel=0 then ' если токен входит в кейлист !
						'-------------------------
						SendMessageA (rhWnd,EM_POSFROMCHAR,byval @VisPoint1,byval CurPos-len(token)-1)
						SetTextColor(hdc,  HiLiteColors(1)) ' clPurple) '''фиолет   HiLiteColors(2) 
						TextOut(hdc,  byval VisPoint1.left,  byval VisPoint1.top,  byval token,  byval len(token))
						'-------------------------
					ELSEif flDigit=1   and flsel=0  then' если у токена  был флаг цифры !
						'-------------------------
						SendMessageA (rhWnd,EM_POSFROMCHAR,byval @VisPoint1,byval CurPos-len(token)-1)
						SetTextColor(hdc, HiLiteColors(8) ) ' clPurple) '''фиолет   !!!
						TextOut(hdc,  byval VisPoint1.left,  byval VisPoint1.top,  byval token,  byval len(token))
						'-------------------------
						flDigit=-1
						
					ELSE
						flDigit=-1
					END IF
				END IF
				
				token = "" ' очищаем токен  !!
				flDigit=-1
			END IF
			
			
			IF ch = chr$(34) THEN        '--- ------- if quote ----------- !
				token = ""
				kk=0
				
				if flsel=0 or lensel=0 then
					
					'------------------------- hilite first quot ---!
					SendMessageA (rhWnd,EM_POSFROMCHAR,byval  @VisPoint1,byval CurPos-1)
					SetTextColor(hdc, HiLiteColors(5) ) ' clPurple) '''фиолет   
					TextOut(hdc,  byval VisPoint1.left,  byval VisPoint1.top,  byval ch,  byval len(ch))
				end if
				
				'-------------------------
				FOR j1 = j+1 TO len(richeditline) '---  from begin string type to eol
					CurPos=j1 +StrPos
					
					' если позиция символа попадает в диапазон выделения, то не подсвечиваем его !
					if CurPos>= CHARRANGE1.cpMin and CurPos <= CHARRANGE1.cpMax then
						
						flsel=1 ' здесь флаг только взводится!!!!
					end if
					
					
					ch = mid$(richeditline,j1,1) 
					
					IF ch = chr$(34) THEN  '--- ------- if last quote -----------!
						if flsel=0 or lensel=0 then
							'-------------------------
							SendMessageA (rhWnd,EM_POSFROMCHAR, @VisPoint1, byval CurPos-1)
							SetTextColor(hdc, HiLiteColors(5) ) 'clPurple)                         
							TextOut(hdc,  byval VisPoint1.left,  byval VisPoint1.top, byval ch,  byval len(ch))
						END IF
						'-------------------------
						kk=1
						EXIT FOR
					else
						token = token +ch'' store quote token!
					END IF
				NEXT j1
				j=j1 ' correct cursor position !!!
				'---  end string type
				
				if flsel=0 or lensel=0 then
					
					'------------------------- hilite quote token !!
					SendMessageA (byval rhWnd,EM_POSFROMCHAR,byval @VisPoint,byval CurPos-len(token)-kk)
					SetTextColor(hdc, HiLiteColors(7) ) 'clOrange)
					'TextOut(hdc, VisPoint.left, VisPoint.top, byval token,  byval len(token))
					TabbedTextOut (hdc, VisPoint.left, VisPoint.top, token,-1,0,0,0)
				END IF
				
				'-------------------------
				token = "" ' подсветили строковый токен и обнулили его
				ch = ""
				'flsel=0 ' сбрасываем флаг !!
				
				
			ELSEIF ch = "'" THEN '-- comment ---------------!
				
				RemF:
				
				RemPos=CurPos  '---first pos of comment
				'token = ""   '- new token - comment
				
				rempos1= j '=instr(richeditline,"'")  
				
				token =mid$(richeditline,RemPos1)'  from rempos1 to end of line !, len(richeditline)-RemPos1+1)  
				j=j+len(token)
				CurPos=j +StrPos ' это же конец строки
				
				' если позиция символа попадает в диапазон выделения, то не подсвечиваем его !
				'if RemPos <= CHARRANGE1.cpMin and CurPos <= CHARRANGE1.cpMax then
				if RemPos <= CHARRANGE1.cpMin and lensel>0 then
					
					flsel=1 ' здесь флаг только взводится!!!!
				end if
				
				
				
				if flsel=0 or lensel=0 then ' подсвечиваем !!
					
					'-------------------------
					SendMessageA (byval rhWnd,EM_POSFROMCHAR, byval @VisPoint1, byval RemPos-1)
					if instr(token,"!!!!!")>0 then
						SetTextColor( byval hdc, &H83FFFF ) 'clred)
					elseif instr(token,"!!!!")>0 then
						SetTextColor( byval hdc, &HAE59FF ) 'clred)
					elseif instr(token,"!!!")>0 then
						SetTextColor( byval hdc, HiLiteColors(8) ) 'clred)
					elseif instr(token,"!!")>0 then
						SetTextColor( byval hdc, &H00B3FF ) 'clo
					elseif instr(token,"!")>0 then
						SetTextColor( byval hdc, &HD7E400 ) 'cla
					else
						SetTextColor( byval hdc, HiLiteColors(6) ) 'clDGreen)
					end if
					
					TextOut( byval hdc,  byval VisPoint1.left,  byval VisPoint1.top, byval token,  byval len(token))
				end if
				
				flsel=0
				ch = ""
				exit for
				
				
			ELSEIF ch = "/" THEN ' подсветка сишного комментария !
				ch1$ = mid$(richeditline,j+1,1)       
				if ch1$ = "/" then goto RemF:
				
			ELSEIF ch = chr$(9) THEN '---- tab  !!! !!!!!!!!!!!! replaced by 4 spaces in source
				if hthl =0 then goto noht
				bgcolor= GetBkColor(hDC)
				rgbPrev = SetTextColor(hdc, bgcolor)
				previous_background_mode=SetBkMode (byval hDC, byval OPAQUE) 
				SendMessageA (rhWnd,EM_POSFROMCHAR, byval @VisPoint1, byval CurPos-1)
				SetBkColor(hdc,HiLiteColors(15))
				TextOut(hdc, byval VisPoint1.left+2, byval VisPoint1.top, byval ch, byval len(ch))
				SetBkColor(hdc,HiLiteColors(0))
				noht:
				ch = ""
				
			elseIF instr("+-=<>\/^&*[]:;?,.$@", ch) THEN ' скобки кавычки !
				
				if flsel=0 or lensel=0 then ' подсвечиваем !!
					
					'-------------------------
					SendMessageA (rhWnd,EM_POSFROMCHAR, byval @VisPoint, byval CurPos-1)
					SetTextColor(hdc, HiLiteColors(2) ) 'clBlue)
					TextOut(hdc, VisPoint.left, VisPoint.top, byval ch, len(ch))
				end if
				'-------------------------
			ELSEIF instr("()[]{}", ch) THEN
				if flsel=0 or lensel=0 then ' подсвечиваем !!
					'-------------------------
					SendMessageA (rhWnd,EM_POSFROMCHAR, byval @VisPoint, byval CurPos-1)
					SetTextColor(hdc, HiLiteColors(3) ) 'clBlue)
					TextOut(hdc, VisPoint.left, VisPoint.top, byval ch, len(ch))
				end if
				
				'ELSEIF len(token) > 1 THEN '!! нашли конец токена и подсвечиваем его
			ELSEIF token <> "" THEN
				
			END IF
			
			token = "" '!!!!<<<<<<<<<<<<<<<<<<<<<<<<
			'flsel=0
		ELSEif instr("0123456789", ch)>0  THEN '!  value and novFlag=0
			
			if flDigit=-1 then flDigit=1
			
			IF flDigit=1 THEN 
			ELSE
				flDigit=0
				
			END IF
			token = token + ch
			
		ELSE
			token = token + ch
			flDigit=0
		END IF
		nextj:
	NEXT j
	
	
	IF len(token) > 0 and (flsel=0  or lensel=0) THEN  ' строка кончилась !!!!!
		
		if instr(keyListText,ucase$(token))>0  then
			
			'-------------------------
			SendMessageA (rhWnd,EM_POSFROMCHAR, byval @VisPoint,byval CurPos-len(token))
			SetTextColor(hdc, HiLiteColors(1) ) 'clblue)
			TextOut(hdc, VisPoint.left, VisPoint.top, byval token, byval len(token))
			'token = ""
			
			'-------------------------
			'*'                fOut.write("<font color=\"000099\"><b>"+token+"</b></font>")
			
			ELSEIF ucase$(token)="SHL" or ucase$(token)="SHR" or ucase$(token)="MOD" or ucase$(token)="INV" _
		or ucase$(token)="NOT" or ucase$(token)="AND" or ucase$(token)="OR" or ucase$(token)="XOR"  THEN 
			'!!------------------------- operators ------
			SendMessageA (rhWnd,EM_POSFROMCHAR, byval @VisPoint,byval CurPos-len(token))
			SetTextColor(hdc, HiLiteColors(3) ) 'clDPurple)
			TextOut(hdc, VisPoint.left, VisPoint.top, byval token, byval len(token))
			'token = ""
			
		ELSEif flDigit=1 then
			'-------------------------
			SendMessageA (rhWnd,EM_POSFROMCHAR, byval @VisPoint,byval CurPos-len(token))
			SetTextColor(hdc, HiLiteColors(8) ) 'clDPurple)
			TextOut(hdc, VisPoint.left, VisPoint.top, byval token, byval len(token))
			'-------------------------
			flDigit=-1
			
		ELSE
			'ELSEIF instr("0123456789", token)>0 THEN 
			'*'                fOut.write(token)
		END IF
	else
		'print ch
		'if ch=chr$(13) then print "chr$(13)"
		'if ch=chr$(10) then print "chr$(10)"
	END IF
	nexti:
	StrPos=StrPos+len(richeditline)+_crlf 'StrPos+j 
NEXT i

SendMessageA (rhWnd,EM_EXGETSEL, byval 0, byval @CHARRANGE1)
'SendMessageA (rhWnd,EM_POSFROMCHAR, byval @VisPoint,byval CHARRANGE1.cpMin)

lensel=CHARRANGE1.cpMax-CHARRANGE1.cpMin
'print"589:CHARRANGE1.cpMin=";CHARRANGE1.cpMin
'print"589:CHARRANGE1.cpMax=";CHARRANGE1.cpMax


ReleaseDC(rhWnd, hDC)
END function



