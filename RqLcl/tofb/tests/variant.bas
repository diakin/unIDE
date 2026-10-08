$APPTYPE CONSOLE
' VARIANT and VARTYPE (datatypes.html, otherdetail.html), FORMAT$, INITARRAY
DECLARE FUNCTION Half (X AS VARIANT) AS VARIANT
DECLARE SUB SetText (X AS VARIANT)

DIM V1 AS VARIANT, V2 AS VARIANT
V1 = 101
V2 = "99.5"
PRINT V1+V2
V1 = "101"
V2 = 99.5
PRINT V1+V2

dim TstNum as variant
DEFDBL Number1
Number1=77.0
TstNum=Number1
VType = VARTYPE(TstNum)
print "VType0=" ,VType
Number1=77.01
TstNum=Number1
VType = VARTYPE(TstNum)
print "VType1=" ,VType
DIM myvariant(100) AS VARIANT
myvariant(1) = "G"
PRINT "VType2="; VARTYPE(myvariant(1)); " undefined="; VARTYPE(myvariant(2))

' to typed variables, comparisons, INC
N& = V2
S$ = V2
PRINT "long "; N&; " str "; S$
IF V2 > 50 THEN PRINT "gt"
IF V1 = "101" THEN PRINT "eq"
INC V2
INC V2, 2
PRINT "inc "; V2
PRINT "half "; Half(V2)
SetText V1
PRINT "byref "; V1
PRINT "mix "; V1 + 5; " "; 5 + V2

FUNCTION Half (X AS VARIANT) AS VARIANT
  Half = X / 2
END FUNCTION
SUB SetText (X AS VARIANT)
  X = "changed"
END SUB

' FORMAT$
A$ = FORMAT$("Location: %s %4d %-10.4g", "Any", 1234, 55.39)
PRINT "["; A$; "]"
PRINT FORMAT$("%d %d %0:d %d", 10, 20)
PRINT FORMAT$("%x %.4x %.3d %5s|%-5s|", 255, 255, -7, "ab", "ab")
PRINT FORMAT$("%f %.3f %n %e", 3.14159, 2.5, 1234567.891, 1234.5)
PRINT FORMAT$("100%%")

' INITARRAY
DIM A(1 TO 100) AS INTEGER
INITARRAY(A, 55, 234, 45, 99)
PRINT "init "; A(1); " "; A(2); " "; A(3); " "; A(4); " "; A(5)
DIM Names(3) AS STRING
INITARRAY Names, "a", "b", "c"
PRINT "names "; Names(0); Names(1); Names(2); "["; Names(3); "]"
DIM Grid(1, 1) AS DOUBLE
INITARRAY(Grid, 1.5, 2.5, 3.5, 4.5)
PRINT "grid "; Grid(0, 0); " "; Grid(1, 1)
' VARIANT fields of own component, as in QSpinEdit.inc
TYPE QSpinTest EXTENDS QOBJECT
  Value AS VARIANT
  MaxValue AS VARIANT
  Txt AS STRING
  SUB StepBy (ic AS DOUBLE)
    WITH This
      Inc(.Value, ic)
      IF .Value => .MaxValue THEN .Value = .MaxValue
      IF VarType(This.Value) = 0 THEN .Txt = "+" + str$(.Value)
      IF VarType(This.Value) = 1 THEN .Txt = "+" + strf$(.Value, 0, 4, 4)
    END WITH
  END SUB
END TYPE
DIM Spin AS QSpinTest
Spin.MaxValue = 10
Spin.StepBy 2
PRINT "spin "; Spin.Txt
Spin.StepBy 0.5
PRINT "spin "; Spin.Txt
Spin.StepBy 100
PRINT "spin "; Spin.Txt
PRINT "end"
