' Есть ли в RapidQ встроенные QTHREAD и Rect1 (rc.exe в общем inc: "Usertype
' QTHREAD already used", "Identifier RECT1 already used" - других объявлений нет).
' Собрать rc.exe без $INCLUDE. Если QTHREAD встроенный - строка DIM t
' соберётся; если нет - "Unknown type QTHREAD". Строку с Rect1 - отдельно.
DIM t AS QTHREAD
PRINT "QTHREAD ok"
'DIM Rect1 AS LONG
'PRINT "Rect1 ok"
