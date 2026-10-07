$APPTYPE CONSOLE
' TRUE = 1, FALSE = 0 as in RapidQ; Boolean properties read 1 / 0
DIM Flag AS INTEGER
DIM Box AS QCHECKBOX
Flag = TRUE
PRINT "true "; TRUE; " false "; FALSE; " flag "; Flag
Box.Checked = TRUE
IF Box.Checked = TRUE THEN PRINT "checked = true" ELSE PRINT "checked <> true"
Box.Checked = FALSE
IF Box.Checked = FALSE THEN PRINT "checked = false"
PRINT "sum "; TRUE + TRUE
