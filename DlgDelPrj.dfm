object DlgDelPrj: TDlgDelPrj
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Delete Projects'
  ClientHeight = 470
  ClientWidth = 640
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 16
  object lblTitle: TLabel
    Left = 12
    Top = 10
    Width = 616
    Height = 18
    Caption = 'Отметьте проекты для удаления'
  end
  object lblNote: TLabel
    Left = 12
    Top = 400
    Width = 616
    Height = 20
    AutoSize = False
    Caption = 'Проект без описания на диске в любом случае просто убирается из списка.'
    WordWrap = True
  end
  object lstDelPrj: TCheckListBox
    Left = 12
    Top = 32
    Width = 616
    Height = 270
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
  end
  object btnMark: TUiButton
    Tag = 1
    Left = 12
    Top = 308
    Width = 120
    Height = 26
    Caption = 'Отметить все'
    TabOrder = 1
  end
  object btnUnmark: TUiButton
    Left = 140
    Top = 308
    Width = 120
    Height = 26
    Caption = 'Снять все'
    TabOrder = 2
  end
  object rbPrj: TUiRadioButton
    Left = 12
    Top = 346
    Width = 616
    Height = 21
    Caption = 'Только описание проекта (.prj), файлы оставить'
    Checked = True
    TabOrder = 3
  end
  object rbAll: TUiRadioButton
    Left = 12
    Top = 372
    Width = 616
    Height = 21
    Caption = 'Папку проекта целиком - в корзину'
    TabOrder = 4
  end
  object btnDelPrj: TUiButton
    Left = 448
    Top = 432
    Width = 84
    Height = 26
    Caption = 'Удалить'
    Enabled = False
    ModalResult = 1
    TabOrder = 5
  end
  object btnCancel: TUiButton
    Left = 544
    Top = 432
    Width = 84
    Height = 26
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 6
  end
end
