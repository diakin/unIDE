' Тест CopyMode (2026-10-11): что принимает RapidQ -
'   номера 0..14 (документация qbitmap.html: cmSrcCopy = 10)
'   или коды растровых операций Windows (rapidq2.inc, Lance 2002:
'   cmSrcCopy = &HCC0020)?
' Без $INCLUDE: значения заданы числами, чтобы не зависеть от inc.
'
' Ряд 1 - CopyMode = номер 0..14, ряд 2 - CopyMode = код Windows той же
' операции. Источник - красный квадрат с синей серединой, фон ячейки
' зелёный. Если операция сработала, в ячейке видно (для обоих рядов одно и
' то же):
'   0 Blackness  - чёрный          10 SrcCopy   - красный, синяя середина
'   1 DstInvert  - лиловый         12 SrcInvert - жёлтый, голубая середина
'   4 NotSrcCopy - голубой, жёлтая середина
'   9 SrcAnd     - чёрный целиком  13 SrcPaint  - жёлтый, голубая середина
'                                  14 Whiteness - белый
' Кнопка "Прочитать" пишет в список, что CopyMode отдаёт после записи.
' Пришлите снимок окна.

DIM ModeNames(14) AS STRING
DIM RopCodes(14) AS LONG
DIM Src AS QBITMAP
DIM ReadBmp AS QBITMAP
DIM DstRect AS QRECT
DIM SrcRect AS QRECT

ModeNames(0) = "Blackness"   : RopCodes(0) = &H42
ModeNames(1) = "DstInvert"   : RopCodes(1) = &H550009
ModeNames(2) = "MergeCopy"   : RopCodes(2) = &HC000CA
ModeNames(3) = "MergePaint"  : RopCodes(3) = &HBB0226
ModeNames(4) = "NotSrcCopy"  : RopCodes(4) = &H330008
ModeNames(5) = "NotSrcErase" : RopCodes(5) = &H1100A6
ModeNames(6) = "PatCopy"     : RopCodes(6) = &HF00021
ModeNames(7) = "PatInvert"   : RopCodes(7) = &H5A0049
ModeNames(8) = "PatPaint"    : RopCodes(8) = &HFB0A09
ModeNames(9) = "SrcAnd"      : RopCodes(9) = &H8800C6
ModeNames(10) = "SrcCopy"    : RopCodes(10) = &HCC0020
ModeNames(11) = "SrcErase"   : RopCodes(11) = &H440328
ModeNames(12) = "SrcInvert"  : RopCodes(12) = &H660046
ModeNames(13) = "SrcPaint"   : RopCodes(13) = &HEE0086
ModeNames(14) = "Whiteness"  : RopCodes(14) = &HFF0062

Src.Width = 30
Src.Height = 30
Src.FillRect(0, 0, 30, 30, &H0000FF)
Src.FillRect(8, 8, 22, 22, &HFF0000)
ReadBmp.Width = 10
ReadBmp.Height = 10

DECLARE SUB CanvasPaint (Sender AS QCANVAS)
DECLARE SUB ReadClick (Sender AS QBUTTON)

CREATE Form AS QFORM
  Caption = "Тест CopyMode"
  Width = 660
  Height = 470
  Center
  CREATE Canv AS QCANVAS
    Left = 0
    Top = 0
    Width = 652
    Height = 152
    OnPaint = CanvasPaint
  END CREATE
  CREATE ReadBtn AS QBUTTON
    Caption = "Прочитать"
    Left = 6
    Top = 158
    Width = 100
    OnClick = ReadClick
  END CREATE
  CREATE ResList AS QLISTBOX
    Left = 6
    Top = 188
    Width = 640
    Height = 245
  END CREATE
END CREATE

SUB CanvasPaint (Sender AS QCANVAS)
  DIM ColIdx AS INTEGER
  DIM CellX AS INTEGER
  Sender.FillRect(0, 0, Sender.Width, Sender.Height, &HC0C0C0)
  Sender.TextOut(6, 4, "Ряд 1: CopyMode = номер 0..14 (документация qbitmap.html)", 0, &HC0C0C0)
  Sender.TextOut(6, 78, "Ряд 2: CopyMode = код Windows (rapidq2.inc)", 0, &HC0C0C0)
  SrcRect.Left = 0
  SrcRect.Top = 0
  SrcRect.Right = 30
  SrcRect.Bottom = 30
  FOR ColIdx = 0 TO 14
    CellX = 6 + ColIdx * 42
    Sender.FillRect(CellX, 24, CellX + 30, 54, &H00FF00)
    Sender.CopyMode = ColIdx
    DstRect.Left = CellX
    DstRect.Top = 24
    DstRect.Right = CellX + 30
    DstRect.Bottom = 54
    Sender.CopyRect(DstRect, Src, SrcRect)
    Sender.FillRect(CellX, 98, CellX + 30, 128, &H00FF00)
    Sender.CopyMode = RopCodes(ColIdx)
    DstRect.Top = 98
    DstRect.Bottom = 128
    Sender.CopyRect(DstRect, Src, SrcRect)
    Sender.TextOut(CellX + 6, 58, STR$(ColIdx), 0, &HC0C0C0)
    Sender.TextOut(CellX + 6, 132, STR$(ColIdx), 0, &HC0C0C0)
  NEXT ColIdx
END SUB

SUB ReadClick (Sender AS QBUTTON)
  DIM ModeIdx AS INTEGER
  DIM NumRead AS LONG
  DIM RopRead AS LONG
  ResList.Clear
  FOR ModeIdx = 0 TO 14
    ReadBmp.CopyMode = ModeIdx
    NumRead = ReadBmp.CopyMode
    ReadBmp.CopyMode = RopCodes(ModeIdx)
    RopRead = ReadBmp.CopyMode
    ResList.AddItems STR$(ModeIdx) + " " + ModeNames(ModeIdx) + ":  записали " + STR$(ModeIdx) + _
      " - прочитали " + STR$(NumRead) + ";  записали &H" + HEX$(RopCodes(ModeIdx)) + _
      " - прочитали &H" + HEX$(RopRead)
  NEXT ModeIdx
END SUB

Form.ShowModal
