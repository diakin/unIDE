' Суффиксы чисел ?, ??, ??? (BYTE, WORD, DWORD) и INC перед ELSE (QXLS.INC).
' Ожидается: 5 7 65535 1
DIM n AS LONG, w AS WORD
w = 5??
n = 7?
PRINT w; " "; n; " "; &HFFFF???
n = 0
IF n < 3 THEN INC(n) ELSE n = 9
PRINT n
