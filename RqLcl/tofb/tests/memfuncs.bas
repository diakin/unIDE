$APPTYPE CONSOLE
' VARPTR, VARPTR$, MEMCPY, MEMSET, MEMCMP (examples from otherdetail.html),
' SENDMESSAGE, POSTMESSAGE, KILLMESSAGE, SHELL(command, showCMD), QUICKSORT
TYPE TRec
  A AS LONG
  B AS SHORT
END TYPE
CONST WM_SETTEXT = &HC
CONST WM_GETTEXT = &HD
CONST WM_GETTEXTLENGTH = &HE
CONST WM_CHAR = &H102

DEFINT I=90, J=10
'-- After MEMCPY, I should equal 10
MEMCPY(VARPTR(I), VARPTR(J), SIZEOF(INTEGER))
PRINT "memcpy "; I
DIM IntArray(1 TO 10) AS INTEGER
FOR K = 1 TO 10 : IntArray(K) = K : NEXT
MEMSET(VARPTR(IntArray(1)), 0, 10*SIZEOF(INTEGER))
PRINT "memset "; IntArray(1); " "; IntArray(10)
DEFINT N1=10, N2=10, N3=11
A% = MEMCMP(VARPTR(N1), VARPTR(N2), SIZEOF(INTEGER))
B% = MEMCMP(VARPTR(N1), VARPTR(N3), SIZEOF(INTEGER))
PRINT "memcmp "; A%; " "; B%

' string: VARPTR - address of the characters
S$ = SPACE$(5)
T$ = "hello"
MEMCPY VARPTR(S$), VARPTR(T$), 5
PRINT "str ["; S$; "]"
PRINT "varptr$ "; VARPTR$(VARPTR(T$))
DIM Addr AS LONG
Addr = VARPTR(T$)
PRINT "varptr$ long "; VARPTR$(Addr)

' record and array element
DIM R AS TRec
R.A = 77
X& = 0
MEMCPY(VARPTR(X&), VARPTR(R), 4)
PRINT "record "; X&
DIM Names(3) AS STRING
Names(2) = "two"
PRINT "string element "; VARPTR$(VARPTR(Names(2)))

' SENDMESSAGE / POSTMESSAGE / KILLMESSAGE
CREATE Form AS QFORM
  Caption = "mem"
  CREATE Edit1 AS QEDIT
    Text = ""
  END CREATE
END CREATE
SENDMESSAGE Edit1.Handle, WM_SETTEXT, 0, "abc"
PRINT "settext "; Edit1.Text
Len1 = SENDMESSAGE(Edit1.Handle, WM_GETTEXTLENGTH, 0, 0)
PRINT "length "; Len1
Buf$ = SPACE$(10)
Got& = SENDMESSAGE(Edit1.Handle, WM_GETTEXT, 10, VARPTR(Buf$))
PRINT "gettext "; LEFT$(Buf$, Got&)
SendMessage(Edit1.Handle, WM_SETTEXT, 0, "")
POSTMESSAGE Edit1.Handle, WM_CHAR, 65, 0
DOEVENTS
PRINT "post ["; Edit1.Text; "]"
POSTMESSAGE Edit1.Handle, WM_CHAR, 66, 0
KILLMESSAGE Edit1.Handle, WM_CHAR
DOEVENTS
PRINT "kill ["; Edit1.Text; "]"

' SHELL(command, showCMD): process ID, does not wait
PID = SHELL("cmd /c exit", 0)
IF PID > 0 THEN PRINT "shell pid ok" ELSE PRINT "shell pid 0"
' SHELL command: waits
SHELL "cmd /c echo x> shellout.txt"
PRINT "shell wait "; FILEEXISTS("shellout.txt")
KILL "shellout.txt"

' QUICKSORT
DIM Words(4) AS STRING
Words(0) = "pear" : Words(1) = "apple" : Words(2) = "fig"
Words(3) = "Banana" : Words(4) = "kiwi"
QUICKSORT(Words(0), Words(4), ASCEND)
PRINT "words "; Words(0); " "; Words(1); " "; Words(2); " "; Words(3); " "; Words(4)
DIM Nums(9) AS INTEGER
FOR K = 0 TO 9 : Nums(K) = (K * 7) MOD 10 : NEXT
QUICKSORT Nums(0), Nums(9), DESCEND
Line$ = ""
FOR K = 0 TO 9 : Line$ = Line$ + STR$(Nums(K)) + " " : NEXT
PRINT "desc "; Line$
FOR K = 0 TO 9 : Nums(K) = 9 - K : NEXT
QUICKSORT(Nums(2), Nums(6), ASCEND)
Line$ = ""
FOR K = 0 TO 9 : Line$ = Line$ + STR$(Nums(K)) + " " : NEXT
PRINT "part "; Line$
DIM Vals(3) AS DOUBLE
Vals(0) = 2.5 : Vals(1) = -1 : Vals(2) = 3.25 : Vals(3) = 0
QUICKSORT(Vals(0), Vals(3), ASCEND)
PRINT "double "; Vals(0); " "; Vals(1); " "; Vals(2); " "; Vals(3)
DIM Grid(1, 2) AS LONG
Grid(0, 0) = 6 : Grid(0, 1) = 5 : Grid(0, 2) = 4
Grid(1, 0) = 3 : Grid(1, 1) = 2 : Grid(1, 2) = 1
QUICKSORT(Grid(0, 0), Grid(1, 2), ASCEND)
PRINT "grid "; Grid(0, 0); Grid(0, 1); Grid(0, 2); Grid(1, 0); Grid(1, 1); Grid(1, 2)
' SIZEOF of RapidQ types: INTEGER = LONG = 4 bytes (FreeBASIC Integer in 64 bit - 8)
PRINT "sizeof "; SIZEOF(INTEGER); " "; SIZEOF(LONG); " "; SIZEOF(WORD); " "; SIZEOF(DWORD); " "; SIZEOF(BYTE); " "; SIZEOF(SHORT); " "; SIZEOF(DOUBLE)
PRINT "end"
