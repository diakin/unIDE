$INCLUDE "RapidQ.inc"
ffsize=FileSize("C:\BAS\RAPIDQ\RQIDE\diametr1.frw")
print"ffsize=";ffsize

InputFile$ =LoadString("C:\BAS\RAPIDQ\RQIDE\diametr1.frw")
print"InputFile$=";InputFile$
print"len InputFile=";len(InputFile$)

zzz=SaveString (InputFile$,"C:\BAS\RAPIDQ\RQIDE\diametr1.frw")
print"zzz=";zzz


  