' unIDE, отладчик RapidQ: $INCLUDE-файлы под отладкой.
'
' Файлы: RqDbgT5_Include.bas (главный), RqDbgT5_Lib.inc (подключён
' сюда), RqDbgT5_Nested.inc (подключён в RqDbgT5_Lib.inc и ещё раз ниже).
'
' Что пробовать:
'   1. Вкладка Includes справа, двойной щелчок по RqDbgT5_Lib.inc - на
'      вкладке файла после имени видно "« RqDbgT5_Include.bas". С этой
'      вкладки Compile/Run собирают RqDbgT5_Include.bas.
'   2. Точка останова (F5) в RqDbgT5_Lib.inc, в SUB LibCount; F9 с любой
'      вкладки; кнопка "Run lib" - остановка в RqDbgT5_Lib.inc, в Watch -
'      CountIdx, CountTo, LibCalls.
'   3. F7 по строкам LibCount - заход в NestedAdd (RqDbgT5_Nested.inc
'      открывается сам, вкладка тоже с пометкой главного файла), выход
'      обратно в RqDbgT5_Lib.inc.
'   4. F8 на строке "LibCount(3)" в ButtonClick - вызов целиком, без
'      захода в include.
'   5. Точка только в RqDbgT5_Nested.inc (в главном и в Lib точек нет) -
'      программа всё равно собирается под отладчиком и встаёт в
'      NestedAdd.
'   6. Watch: NestedAdd(MainTotal, LibCalls) - FUNCTION из include в
'      выражении (LibTwice не годится: она меняет LibCalls).
'   7. Ошибка компиляции в include (например, лишнее слово в строке
'      RqDbgT5_Lib.inc) при отладочной сборке - в логе имя и строка
'      RqDbgT5_Lib.inc, а не копии.
'   8. Без точек и без F7/F8/F4 - обычная сборка, include как есть.

$INCLUDE "RqDbgT5_Lib.inc"
' Второй раз: в отладочной копии - комментарий "уже вставлен выше";
' в самом файле повтор отсекает $IFNDEF
$INCLUDE "RqDbgT5_Nested.inc"

DECLARE SUB ButtonClick

DIM MainTotal AS INTEGER

CREATE MainForm AS QFORM
  Caption = "RqDbgT5 Include"
  Width = 320
  Height = 140
  Center
  CREATE InfoLabel AS QLABEL
    Left = 10
    Top = 10
    Width = 280
    Caption = "-"
  END CREATE
  CREATE LibButton AS QBUTTON
    Left = 10
    Top = 50
    Width = 120
    Caption = "Run lib"
    OnClick = ButtonClick
  END CREATE
END CREATE

SUB ButtonClick
  LibCount(3)
  MainTotal = LibTwice(LibCalls)
  InfoLabel.Caption = "calls" + STR$(LibCalls) + ", twice" + STR$(MainTotal)
END SUB

' --- главная часть ---
MainTotal = NestedAdd(2, 3)
InfoLabel.Caption = "2 + 3 =" + STR$(MainTotal)
MainForm.ShowModal
