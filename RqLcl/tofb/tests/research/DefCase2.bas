' То же, что в rapidq2.inc (QFormEx): $DEFINE TRANSPARENT и поле Transparent.
' Компилируется ли, и что печатает (ожидание - 7).
$APPTYPE CONSOLE
$DEFINE TRANSPARENT 1
TYPE TDefCase EXTENDS QOBJECT
  Transparent AS INTEGER
END TYPE
DIM DefObj AS TDefCase
DefObj.Transparent = 7
PRINT DefObj.Transparent
INPUT "Enter", Answer$
