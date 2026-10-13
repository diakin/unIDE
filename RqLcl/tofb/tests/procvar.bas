' Неявная переменная в FUNCTION с именем SUB модуля (общий RQProc.inc:
' SUB II из CMD5.inc, FOR ii в eml.inc). Перевод: переменная ii_v.
' Ожидается: 6 и II
SUB II(s AS STRING)
  PRINT s
END SUB
FUNCTION Summa(n AS LONG) AS LONG
  r = 0
  FOR ii = 1 TO n
    r = r + ii
  NEXT ii
  Summa = r
END FUNCTION
PRINT Summa(3)
II "II"
