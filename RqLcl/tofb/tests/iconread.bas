$INCLUDE "RAPIDQ.INC"
DIM F AS QFORM
DIM H AS LONG
DIM S AS STRING
H = F.Icon
S = F.Icon
H = Application.Icon
SHOWMESSAGE "H=" + STR$(H) + "  S=[" + S + "]  len=" + STR$(LEN(S))
