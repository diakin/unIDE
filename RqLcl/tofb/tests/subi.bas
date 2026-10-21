$APPTYPE CONSOLE
' SUBI / FUNCTIONI (документация RapidQ, глава 9) и методы SUBI своих компонентов
DECLARE FUNCTIONI CountAll (...) AS INTEGER

SUBI TestSUBI (...)
  PRINT "String Parameters: "; ParamStrCount
  FOR I = 1 TO ParamStrCount
    PRINT I;" "; ParamStr$(I)
  NEXT I
  PRINT "Numeric Parameters: "; ParamValCount
  FOR I = 1 TO ParamValCount
    PRINT I;" "; ParamVal(I)
  NEXT I
END SUBI

FUNCTIONI FindMax (...) AS DOUBLE
  DIM Largest AS DOUBLE
  DIM I AS BYTE
  Largest = -999999999999
  FOR I = 1 TO ParamValCount
    IF ParamVal(I) > Largest THEN
      Largest = ParamVal(I)
    END IF
  NEXT
  FindMax = Largest ' or Result = Largest
END FUNCTIONI

FUNCTIONI CountAll (...) AS INTEGER
  Result = ParamStrCount + ParamValCount
END FUNCTIONI

' Как QtabControlEx.inc и QDebug в rapidq.inc
TYPE QTabsY EXTENDS QTABCONTROL
  TabCnt AS INTEGER
  SUB Add(s AS STRING)
    Super.AddTabs s
    This.TabCnt = This.TabCnt + 1
  END SUB
  SUBI AddTabs(...)
    DIM i AS INTEGER
    FOR i = 1 TO ParamStrCount
      This.Add ParamStr$(i)
    NEXT i
  END SUBI
END TYPE

TYPE QLog EXTENDS QObject
  Lines AS INTEGER
  SUB PrintStr(S AS STRING)
    This.Lines = This.Lines + 1
    PRINT "log: "; S
  END SUB
  SUBI Print(...)
    DIM Whole AS STRING
    DIM i AS INTEGER
    FOR i = 1 TO ParamStrCount
      Whole = Whole + ParamStr$(i) + " "
    NEXT i
    FOR i = 1 TO ParamValCount
      Whole = Whole + STR$(ParamVal(i)) + " "
    NEXT i
    This.PrintStr(Whole)
  END SUBI
  FUNCTIONI Sum(...) AS DOUBLE
    DIM i AS INTEGER
    DIM Total AS DOUBLE
    FOR i = 1 TO ParamValCount
      Total = Total + ParamVal(i)
    NEXT i
    Result = Total
  END FUNCTIONI
  SUB Test
    This.Print("inside", 1)
  END SUB
END TYPE

DIM Name$ AS STRING
DIM Count AS INTEGER
DIM Logger AS QLog
DIM Tabs AS QTabsY
Name$ = "Yeah..."
Count = 9876
TestSUBI "Hello", 1234, "Hmmm", Name$, Count, 1*2*3*4, UCASE$("Last one")
TestSUBI
PRINT "Largest number is: "; FindMax(523, 12.4, 602, 45, -1200)
PRINT "Largest number is: "; FindMax(523, 12.4, FindMax(602, 45, -1200))
PRINT "Count: "; CountAll("a", 2, "c"); " "; CountAll()
Logger.Print "a", 2, "b"
Logger.Print
Logger.Test
PRINT "Sum: "; Logger.Sum(1, 2, 3.5); " lines "; Logger.Lines
IF Logger.Sum(1, 1) = 2 THEN PRINT "sum ok"
Tabs.AddTabs "One", "Two", "Three", "Four", "Five"
PRINT "tabs "; Tabs.TabCount; " "; Tabs.TabCnt; " "; Tabs.Tab(4)
