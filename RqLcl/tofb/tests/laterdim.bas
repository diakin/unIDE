' Неявная переменная в FUNCTION, DIM с тем же именем - ниже по тексту.
' Перевод: в FUNCTION своя локальная (Dim i), DIM i модуля - отдельно.
' Ожидается: 3 и 5
FUNCTION wd(s AS STRING) AS LONG
  FOR i = 1 TO 3
    wd = i
  NEXT
END FUNCTION
DIM i AS LONG
i = 5
PRINT wd("a")
PRINT i
