$APPTYPE CONSOLE
A$ = FIELD$("John&Doe&555-1234", "&", 2)
PRINT "1 "; A$
PRINT "2 "; REPLACESUBSTR$("abcdefgabcdefg", "abc", "99")
PRINT "3 "; INSERT$("hi", "Hello", 3); " "; DELETE$("Hello world", 2, 3); " "; REPLACE$("Hello", "Jwer", 1)
PRINT "4 "; REVERSE$("Hello"); " "; CONVBASE$("FFD", 16, 2); " "; HEX$(123)
PRINT "5 "; RINSTR("Hello World", "l"); " "; TALLY("abcdefghijklmnabc", "abc"); " "; ROUND(3.49); " "; ROUND(3.50)
PRINT "6 "; CEIL(66.2); " "; FLOOR(66.7); " "; FRAC(342.97)
IF FILEEXISTS("C:\windows\win.ini") THEN PRINT "7 win.ini yes" ELSE PRINT "7 win.ini no"
IF DIREXISTS("C:\windows") THEN PRINT "8 dir yes"
n% = INSTR("Hello", "ll") : PRINT "9 "; n%
