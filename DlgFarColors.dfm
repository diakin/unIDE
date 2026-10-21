object DlgFarColors: TDlgFarColors
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'unIDE FAR - Files highlighting'
  ClientHeight = 480
  ClientWidth = 480
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object grdColors: TDrawGrid
    Left = 8
    Top = 8
    Width = 464
    Height = 340
    ColCount = 4
    DefaultDrawing = False
    DefaultRowHeight = 20
    FixedCols = 0
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRowSelect]
    ScrollBars = ssVertical
    TabOrder = 0
    OnDrawCell = grdColorsDrawCell
    OnKeyDown = grdColorsKeyDown
    OnMouseDown = grdColorsMouseDown
  end
  object lblHint: TLabel
    Left = 8
    Top = 354
    Width = 464
    Height = 30
    AutoSize = False
    Caption =
      'Щелчок по цвету - выбрать цвет, правый щелчок по фону - фон пане' +
      'ли. Пробел - вкл / выкл, Enter - цвет текста, Shift+Enter - цвет' +
      ' фона, Del - удалить.'
    WordWrap = True
  end
  object lblExt: TLabel
    Left = 8
    Top = 395
    Width = 100
    Height = 13
    Caption = 'Новое расширение:'
  end
  object edExt: TUiEdit
    Left = 116
    Top = 392
    Width = 120
    Height = 21
    TabOrder = 1
    OnKeyPress = edExtKeyPress
  end
  object btnAdd: TUiButton
    Left = 244
    Top = 390
    Width = 110
    Height = 25
    Caption = 'Добавить'
    TabOrder = 2
    OnClick = btnAddClick
  end
  object btnDelete: TUiButton
    Left = 362
    Top = 390
    Width = 110
    Height = 25
    Caption = 'Удалить'
    TabOrder = 3
    OnClick = btnDeleteClick
  end
  object btnOk: TUiButton
    Left = 284
    Top = 440
    Width = 90
    Height = 28
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 4
  end
  object btnCancel: TUiButton
    Left = 382
    Top = 440
    Width = 90
    Height = 28
    Cancel = True
    Caption = 'Отмена'
    ModalResult = 2
    TabOrder = 5
  end
end
