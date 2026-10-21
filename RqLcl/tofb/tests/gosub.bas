' GOSUB/RETURN: module level, SUB, FUNCTION, loop, recursion, same label in
' two SUBs, nested GOSUB, single-line IF, statement after GOSUB on the line.
$APPTYPE CONSOLE

DECLARE SUB TestParams (ParamNum AS INTEGER, ParamText AS STRING)
DECLARE FUNCTION TestFunc (ParamNum AS INTEGER) AS INTEGER
DECLARE SUB TestLoop
DECLARE SUB TestRecurse (Depth AS INTEGER)
DECLARE SUB SameLabelA
DECLARE SUB SameLabelB
DECLARE SUB TestNested
DECLARE SUB TestInlineIf (FlagNum AS INTEGER)

SUB TestParams (ParamNum AS INTEGER, ParamText AS STRING)
  DIM LocalNum AS INTEGER
  DIM LocalArr(5) AS INTEGER
  LocalNum = ParamNum * 2
  LocalArr(3) = 33
  GOSUB ShowVars
  LocalNum = LocalNum + 1
  GOSUB ShowVars
  PRINT "params after: "; LocalNum
  EXIT SUB
ShowVars:
  PRINT "params: "; ParamNum; " "; ParamText; " "; LocalNum; " "; LocalArr(3)
  RETURN
END SUB

FUNCTION TestFunc (ParamNum AS INTEGER) AS INTEGER
  DIM FuncLocal AS INTEGER
  FuncLocal = ParamNum + 100
  GOSUB ShowFunc
  TestFunc = FuncLocal
  EXIT FUNCTION
ShowFunc:
  PRINT "func: "; FuncLocal
  FuncLocal = FuncLocal + 1
  RETURN
END FUNCTION

SUB TestLoop
  DIM LoopIdx AS INTEGER
  DIM SumVal AS INTEGER
  DIM GosubCount AS INTEGER
  FOR LoopIdx = 1 TO 10
    SumVal = SumVal + LoopIdx
    IF (LoopIdx MOD 3) = 0 THEN
      GOSUB InLoop
    END IF
  NEXT
  PRINT "loop: "; SumVal; " "; GosubCount
  EXIT SUB
InLoop:
  GosubCount = GosubCount + 1
  PRINT "loop at "; LoopIdx; " sum "; SumVal
  RETURN
END SUB

SUB TestRecurse (Depth AS INTEGER)
  DIM LevelText AS STRING
  LevelText = "level" + CHR$(48 + Depth)
  IF Depth < 3 THEN TestRecurse(Depth + 1)
  GOSUB ShowLevel
  EXIT SUB
ShowLevel:
  PRINT "recurse: "; Depth; " "; LevelText
  RETURN
END SUB

SUB SameLabelA
  GOSUB SameName
  EXIT SUB
SameName:
  PRINT "same: A"
  RETURN
END SUB

SUB SameLabelB
  GOSUB SameName
  EXIT SUB
SameName:
  PRINT "same: B"
  RETURN
END SUB

SUB TestNested
  GOSUB Outer
  PRINT "nested: done"
  EXIT SUB
Outer:
  PRINT "nested: outer 1"
  GOSUB Inner
  PRINT "nested: outer 2"
  RETURN
Inner:
  PRINT "nested: inner"
  RETURN
END SUB

SUB TestInlineIf (FlagNum AS INTEGER)
  IF FlagNum = 1 THEN GOSUB Mark1
  IF FlagNum = 1 THEN PRINT "inline: no" ELSE GOSUB Mark2
  PRINT "inline: end "; FlagNum
  EXIT SUB
Mark1:
  PRINT "inline: mark1"
  RETURN
Mark2:
  PRINT "inline: mark2"
  RETURN
END SUB

DIM ModCount AS INTEGER
DIM FuncRes AS INTEGER

PRINT "start"
GOSUB ModLabel
GOSUB ModLabel : PRINT "module: after second"
TestParams(7, "txt")
FuncRes = TestFunc(5)
PRINT "func result: "; FuncRes
TestLoop
TestRecurse(1)
SameLabelA
SameLabelB
TestNested
TestInlineIf(1)
TestInlineIf(2)
PRINT "end "; ModCount
END

ModLabel:
  ModCount = ModCount + 1
  PRINT "module: "; ModCount
  RETURN
