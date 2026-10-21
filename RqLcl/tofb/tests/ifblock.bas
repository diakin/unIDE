' Блок $IF / #if: условие не вычисляется, блок до #endif пропускается
' и #endif не закрывает внешний $IFDEF
$APPTYPE CONSOLE
$DEFINE AAA
$IFDEF AAA
#if 0
PRINT "skipped"
#endif
PRINT "inside"
$ENDIF
PRINT "end"
