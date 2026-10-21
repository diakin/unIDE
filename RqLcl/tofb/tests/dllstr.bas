' STRING parameters of DECLARE ... LIB: RapidQ passes a pointer to the
' string (documentation, chapter 9).
$APPTYPE CONSOLE
DECLARE FUNCTION StrLength LIB "kernel32" ALIAS "lstrlenA" (Text AS STRING) AS LONG
DECLARE FUNCTION CopyText LIB "kernel32" ALIAS "lstrcpyA" (Dest AS STRING, BYVAL Source AS STRING) AS LONG
DIM Buf AS STRING
DIM Word$
Word$ = "hello"
PRINT "len literal "; StrLength("abc")
PRINT "len var "; StrLength(Word$)
PRINT "len expr "; StrLength(Word$ + "!!")
Buf = SPACE$(10)
CopyText(Buf, "xyz")
PRINT "buf len "; LEN(Buf); " zero at "; INSTR(Buf, CHR$(0)); " text "; LEFT$(Buf, 3)
