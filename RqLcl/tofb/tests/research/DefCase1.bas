' Вопрос: различает ли $DEFINE RapidQ регистр букв.
' rapidq2.inc: $DEFINE TRANSPARENT 1, а ниже поле "Transparent AS INTEGER"
' и "This.Transparent = TheValue" - если $DEFINE регистр не различает, там
' получается "1 AS INTEGER".
' Ожидание: регистр различается - 1 0 0; не различается - 1 1 1.
$APPTYPE CONSOLE
$DEFINE TRANSPARENT 1
PRINT "TRANSPARENT="; TRANSPARENT
PRINT "Transparent="; Transparent
PRINT "transparent="; transparent
INPUT "Enter", Answer$
