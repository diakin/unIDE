' Есть ли в RapidQ встроенные QTHREAD и Rect1 (rc.exe в общем inc: "Usertype
' QTHREAD already used", "Identifier RECT1 already used" - других объявлений нет).
' Собрать rc.exe без $INCLUDE. Если QTHREAD встроенный - строка DIM t
' соберётся; если нет - "Unknown type QTHREAD". Строку с Rect1 - отдельно.
DIM t AS QTHREAD
PRINT "QTHREAD ok"
'DIM Rect1 AS LONG
'PRINT "Rect1 ok"
'
' Результат rc.exe 2026-10-11 (автор):
'  - DIM t AS QTHREAD без $INCLUDE собирается: QTHREAD - встроенный класс
'    (в документации и ComponentAll.data его нет). Второй DIM t AS QTHREAD -
'    "Identifier T already used".
'  - При запуске печатается первая строка, затем окно "Can't find library :"
'    с текстом следующей строковой константы ("DIM t AS QTHREAD="), и
'    программа останавливается - встроенный QTHREAD, похоже, не доделан.
'  - DIM Rect1 AS LONG собирается: Rect1 не встроенное имя.
