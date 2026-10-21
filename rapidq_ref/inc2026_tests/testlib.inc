' testlib.inc - общие процедуры тестовых программ rapidq_ref/inc2026_tests
'
' Каждая тестовая программа test_<файл>.bas:
'   $INCLUDE "testlib.inc"      (из папки inc2026_tests)
'   $INCLUDE "<файл компонента>" (из inc2026: в rc.exe папка inc2026 должна быть в путях include)
' Результаты: окно со списком строк и файл <имя теста>.log рядом с программой.
'   OK    - значение совпало с ожидаемым
'   FAIL  - не совпало (в строке - полученное и ожидаемое значение)
'   INFO  - значение без ожидаемого, для просмотра
'   LOOK  - что нужно проверить глазами на форме
' Тест пишет итог в .log при закрытии окна результатов.

DIM TestLogList AS QSTRINGLIST
DIM TestCheckCount AS INTEGER
DIM TestFailCount AS INTEGER
DIM TestProgName AS STRING
TestCheckCount = 0
TestFailCount = 0
TestProgName = "test"

DECLARE SUB TestResultClose

CREATE TestResultForm AS QFORM
    Caption = "inc2026 test"
    Width = 640
    Height = 420
    Center
    OnClose = TestResultClose
    CREATE TestResultBox AS QLISTBOX
        Align = 5
    END CREATE
END CREATE

SUB TestLog (MsgText AS STRING)
    TestLogList.AddItems MsgText
    TestResultBox.AddItems MsgText
END SUB

SUB TestInfo (InfoName AS STRING, InfoValue AS STRING)
    TestLog "INFO  " + InfoName + " = " + InfoValue
END SUB

SUB TestLook (LookText AS STRING)
    TestLog "LOOK  " + LookText
END SUB

SUB TestCheck (CheckName AS STRING, GotValue AS STRING, ExpectValue AS STRING)
    TestCheckCount = TestCheckCount + 1
    IF GotValue = ExpectValue THEN
        TestLog "OK    " + CheckName + " = " + GotValue
    ELSE
        TestFailCount = TestFailCount + 1
        TestLog "FAIL  " + CheckName + " = " + GotValue + "  (ожидалось " + ExpectValue + ")"
    END IF
END SUB

SUB TestCheckNum (CheckName AS STRING, GotNum AS DOUBLE, ExpectNum AS DOUBLE)
    TestCheck CheckName, STR$(GotNum), STR$(ExpectNum)
END SUB

SUB TestBegin (ProgName AS STRING)
    TestProgName = ProgName
    TestResultForm.Caption = "inc2026 test: " + ProgName
    TestLog "Тест " + ProgName + "  " + DATE$ + " " + TIME$
END SUB

SUB TestSave
    TestLog "Итого: проверок " + STR$(TestCheckCount) + ", ошибок " + STR$(TestFailCount)
    TestLogList.SaveToFile TestProgName + ".log"
END SUB

SUB TestResultClose
    TestSave
END SUB
