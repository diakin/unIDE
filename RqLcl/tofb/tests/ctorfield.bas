$APPTYPE CONSOLE
' CONSTRUCTOR: a field named like a TYPE (QDrawFocus.inc: rect AS RECT,
' Rect.Right = 0 in the constructor) is the field, not the type
TYPE RECT
  Left AS LONG
  Right AS LONG
END TYPE

TYPE QHOLDER EXTENDS QOBJECT
  Rect AS RECT
  Count AS LONG
  CONSTRUCTOR
    Rect.Left = 3
    Rect.Right = 7
    Count = 2
  END CONSTRUCTOR
END TYPE

DIM Holder AS QHOLDER
PRINT "left "; Holder.Rect.Left
PRINT "right "; Holder.Rect.Right
PRINT "count "; Holder.Count
