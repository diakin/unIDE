' unIDE, отладчик RapidQ: программа для проверки этапа 1 (точки останова,
' F7 Trace into, F8 Step over, F4 Run to cursor, F9 Run, Ctrl+F2 Reset).
'
' Что пробовать:
'   1. F7 до запуска - остановка на первом операторе (строка с DIM
'      пропускается: у объявлений кода нет).
'   2. F8 по главной части: вызов CalcSum проходится целиком, остановка на
'      следующей строке.
'   3. F7 на строке с вызовом CalcSum - заход внутрь, шаги по циклу FOR,
'      выход обратно на строку после вызова.
'   4. Строка "FOR ... : ... : NEXT" в одну строку - F7/F8 проходят её за
'      один шаг.
'   5. Точка останова (F5) в ButtonClick, F9 - окно программы, кнопка
'      "Step here" - остановка в обработчике; пока программа стоит, её
'      окно не отвечает.
'   6. F4 на строке после SELECT CASE - Run to cursor.
'   7. Точка на строке DIM или комментария - серая, не срабатывает.
'   8. Ctrl+F2 на остановке - программа снимается, строка остановки
'      пропадает.
'   9. Watch (Ctrl+F5 на имени): на остановке в CalcSum - LimitVal,
'      SumIdx (локальные) и TotalVal (глобальная); в Square - BaseVal;
'      в главной части - LoopIdx, ShortSum. Мышь над именем на остановке -
'      подсказка со значением. В окне Watch пункт Locals добавляет
'      параметры и локальные текущей SUB.
'  10. Выражения в Watch (добавить до сборки, затем Compile & Run):
'      SumIdx * 2 и LimitVal + TotalVal - на остановке в CalcSum;
'      InfoLabel.Caption, MainForm.Width, Square(3) - на любой остановке;
'      Nope + 1 - пояснение "не найдено". Выражение, добавленное после
'      сборки, покажет значение после пересборки.

DECLARE SUB CalcSum (LimitVal AS INTEGER)
DECLARE FUNCTION Square (BaseVal AS INTEGER) AS INTEGER
DECLARE SUB ButtonClick

DIM TotalVal AS INTEGER
DIM ClickCount AS INTEGER
DIM LoopIdx AS INTEGER
DIM ShortSum AS INTEGER

CREATE MainForm AS QFORM
  Caption = "RqDbgT4 Debug"
  Width = 320
  Height = 140
  Center
  CREATE InfoLabel AS QLABEL
    Left = 10
    Top = 10
    Width = 280
    Caption = "-"
  END CREATE
  CREATE StepButton AS QBUTTON
    Left = 10
    Top = 50
    Width = 120
    Caption = "Step here"
    OnClick = ButtonClick
  END CREATE
END CREATE

SUB CalcSum (LimitVal AS INTEGER)
  DIM SumIdx AS INTEGER
  TotalVal = 0
  FOR SumIdx = 1 TO LimitVal
    TotalVal = TotalVal + Square(SumIdx)
  NEXT
  IF TotalVal > 100 THEN EXIT SUB
  TotalVal = TotalVal + 1
END SUB

FUNCTION Square (BaseVal AS INTEGER) AS INTEGER
  Square = BaseVal * BaseVal
END FUNCTION

SUB ButtonClick
  ClickCount = ClickCount + 1
  InfoLabel.Caption = "clicks: " + STR$(ClickCount)
  IF ClickCount > 2 THEN InfoLabel.Caption = InfoLabel.Caption + " (more than 2)"
  SELECT CASE ClickCount
  CASE 1
    InfoLabel.Caption = InfoLabel.Caption + ", first"
  CASE 2
    InfoLabel.Caption = InfoLabel.Caption + ", second"
  CASE ELSE
    InfoLabel.Caption = InfoLabel.Caption + ", next"
  END SELECT
  GOSUB ShowTotal
  EXIT SUB
ShowTotal:
  InfoLabel.Caption = InfoLabel.Caption + ", total" + STR$(TotalVal)
  RETURN
END SUB

' --- главная часть ---
CalcSum(3)
InfoLabel.Caption = "sum of squares 1..3 =" + STR$(TotalVal)
ShortSum = 0
FOR LoopIdx = 1 TO 5: ShortSum = ShortSum + LoopIdx: NEXT
InfoLabel.Caption = InfoLabel.Caption + ", 1..5 =" + STR$(ShortSum)
MainForm.ShowModal
