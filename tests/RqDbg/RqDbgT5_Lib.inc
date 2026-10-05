' unIDE, тест отладчика RapidQ: include с SUB и FUNCTION
$INCLUDE "RqDbgT5_Nested.inc"

DECLARE SUB LibCount (CountTo AS INTEGER)
DECLARE FUNCTION LibTwice (LibArg AS INTEGER) AS INTEGER

DIM LibCalls AS INTEGER

SUB LibCount (CountTo AS INTEGER)
  DIM CountIdx AS INTEGER
  FOR CountIdx = 1 TO CountTo
    LibCalls = LibCalls + NestedAdd(CountIdx, 1)
  NEXT
END SUB

FUNCTION LibTwice (LibArg AS INTEGER) AS INTEGER
  LibCalls = LibCalls + 1
  LibTwice = LibArg * 2
END FUNCTION
