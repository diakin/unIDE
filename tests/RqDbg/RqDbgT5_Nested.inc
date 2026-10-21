' unIDE, тест отладчика RapidQ: вложенный include
$IFNDEF T5_NESTED_INC
$DEFINE T5_NESTED_INC

DECLARE FUNCTION NestedAdd (AddLeft AS INTEGER, AddRight AS INTEGER) AS INTEGER

FUNCTION NestedAdd (AddLeft AS INTEGER, AddRight AS INTEGER) AS INTEGER
  DIM AddSum AS INTEGER
  AddSum = AddLeft + AddRight
  NestedAdd = AddSum
END FUNCTION

$ENDIF
