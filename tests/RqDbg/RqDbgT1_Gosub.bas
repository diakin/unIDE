' unIDE, отладчик RapidQ: тест 1 - GOSUB на метку внутри SUB/FUNCTION.
'
' Что проверяем:
'   1. GOSUB на метку внутри SUB и RETURN из неё компилируются и работают.
'   2. В блоке после метки видны параметры и локальные переменные SUB
'      (в том числе локальный массив и строка).
'   3. То же внутри FUNCTION.
'   4. GOSUB из тела FOR внутри IF: после RETURN цикл продолжается
'      с того же места (счётчик и сумма не сбиваются).
'   5. Рекурсия: в каждом вызове видны переменные своего уровня.
'   6. Одинаковое имя метки в двух разных SUB (если не соберётся -
'      закомментировать SUB SameLabelB и её вызов, и сообщить).
'
' Результат печатается в консоль и пишется в RqDbgT1.log рядом с exe.
' Ожидаемые значения указаны в строках "expect".

$APPTYPE CONSOLE

DIM LogFile AS QFILESTREAM

DECLARE SUB LogLine (LogText AS STRING)
DECLARE SUB TestParams (ParamNum AS INTEGER, ParamText AS STRING)
DECLARE FUNCTION TestFunc (ParamNum AS INTEGER) AS INTEGER
DECLARE SUB TestLoop
DECLARE SUB TestRecurse (Depth AS INTEGER)
DECLARE SUB SameLabelA
DECLARE SUB SameLabelB

SUB LogLine (LogText AS STRING)
  PRINT LogText
  LogFile.WriteLine(LogText)
END SUB

' --- 1, 2: параметры, локальные, массив ---
SUB TestParams (ParamNum AS INTEGER, ParamText AS STRING)
  DIM LocalNum AS INTEGER
  DIM LocalText AS STRING
  DIM LocalArr(5) AS INTEGER
  LocalNum = ParamNum * 2
  LocalText = ParamText + "-local"
  LocalArr(3) = 33
  GOSUB DbgVarsTestParams
  LocalNum = LocalNum + 1
  GOSUB DbgVarsTestParams
  LogLine("TestParams: after RETURN, LocalNum=" + STR$(LocalNum))
  LogLine("  expect: after RETURN, LocalNum= 15")
  EXIT SUB
DbgVarsTestParams:
  LogLine("TestParams: ParamNum=" + STR$(ParamNum) + " ParamText=" + ParamText + " LocalNum=" + STR$(LocalNum) + " LocalText=" + LocalText + " LocalArr(3)=" + STR$(LocalArr(3)))
  RETURN
END SUB

' --- 3: FUNCTION ---
FUNCTION TestFunc (ParamNum AS INTEGER) AS INTEGER
  DIM FuncLocal AS INTEGER
  FuncLocal = ParamNum + 100
  GOSUB DbgVarsTestFunc
  TestFunc = FuncLocal
  EXIT FUNCTION
DbgVarsTestFunc:
  LogLine("TestFunc: ParamNum=" + STR$(ParamNum) + " FuncLocal=" + STR$(FuncLocal))
  RETURN
END FUNCTION

' --- 4: GOSUB из цикла внутри IF ---
SUB TestLoop
  DIM LoopIdx AS INTEGER
  DIM SumVal AS INTEGER
  DIM GosubCount AS INTEGER
  SumVal = 0
  FOR LoopIdx = 1 TO 10
    SumVal = SumVal + LoopIdx
    IF (LoopIdx MOD 3) = 0 THEN
      GOSUB DbgVarsTestLoop
    END IF
  NEXT
  LogLine("TestLoop: end LoopIdx=" + STR$(LoopIdx) + " SumVal=" + STR$(SumVal) + " GosubCount=" + STR$(GosubCount))
  LogLine("  expect: SumVal= 55 GosubCount= 3, lines above for LoopIdx 3, 6, 9")
  EXIT SUB
DbgVarsTestLoop:
  GosubCount = GosubCount + 1
  LogLine("TestLoop: LoopIdx=" + STR$(LoopIdx) + " SumVal=" + STR$(SumVal))
  RETURN
END SUB

' --- 5: рекурсия ---
SUB TestRecurse (Depth AS INTEGER)
  DIM LevelText AS STRING
  LevelText = "level" + STR$(Depth)
  IF Depth < 3 THEN TestRecurse(Depth + 1)
  GOSUB DbgVarsTestRecurse
  EXIT SUB
DbgVarsTestRecurse:
  LogLine("TestRecurse: Depth=" + STR$(Depth) + " LevelText=" + LevelText)
  RETURN
END SUB

' --- 6: одна и та же метка в двух SUB ---
SUB SameLabelA
  DIM NameA AS STRING
  NameA = "A"
  GOSUB DbgVarsSame
  EXIT SUB
DbgVarsSame:
  LogLine("SameLabelA: NameA=" + NameA)
  RETURN
END SUB

SUB SameLabelB
  DIM NameB AS STRING
  NameB = "B"
  GOSUB DbgVarsSame
  EXIT SUB
DbgVarsSame:
  LogLine("SameLabelB: NameB=" + NameB)
  RETURN
END SUB

' --- главная часть ---
DIM FuncResult AS INTEGER
DIM WaitKey AS STRING

LogFile.Open("RqDbgT1.log", 65535)
LogLine("RqDbgT1 start")

TestParams(7, "txt")
LogLine("  expect: ParamNum= 7 ParamText=txt LocalNum= 14, then LocalNum= 15; LocalText=txt-local LocalArr(3)= 33")

FuncResult = TestFunc(5)
LogLine("TestFunc result=" + STR$(FuncResult))
LogLine("  expect: ParamNum= 5 FuncLocal= 105, result= 105")

TestLoop

TestRecurse(1)
LogLine("  expect: Depth= 3 level 3, then 2, then 1")

SameLabelA
SameLabelB
LogLine("  expect: NameA=A, NameB=B")

LogLine("RqDbgT1 end")
LogFile.Close
INPUT "Enter - exit", WaitKey
