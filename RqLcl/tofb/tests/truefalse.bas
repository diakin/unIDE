$APPTYPE CONSOLE
' TRUE / FALSE are not RapidQ words: without a definition they are undeclared
' variables (0); rapidq.inc has $define True 1 / $define False 0.
' Comparison gives -1. RapidQ output (2026-10-08) for the first five lines:
' 1:TRUE=0  2:(Not TRUE)=-1  2.1:Not TRUE=-1  3:False=0  4: Not False=-1
print"1:TRUE=";TRUE
print"2:(Not TRUE)=";(Not TRUE)
print"2.1:Not TRUE=";Not TRUE
print"3:False=";False
print"4: Not False=";Not  False
PRINT "cmp "; (2 > 1); " "; (2 < 1)
$define  False  0
$define True  1
' CONST after $define (RapidQ test 2026-10-08: PRINT False -> 0)
CONST False = 0: CONST True = 1
PRINT "const false "; False
DIM Flag AS INTEGER
DIM Box AS QCHECKBOX
Flag = TRUE
PRINT "true "; TRUE; " false "; FALSE; " flag "; Flag; " not true "; NOT TRUE
Box.Checked = TRUE
IF Box.Checked = TRUE THEN PRINT "checked = true" ELSE PRINT "checked <> true"
Box.Checked = FALSE
IF Box.Checked = FALSE THEN PRINT "checked = false"
IF (2 > 1) = TRUE THEN PRINT "cmp = true" ELSE PRINT "cmp <> true"
