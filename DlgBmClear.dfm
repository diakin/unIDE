object DlgBmClear: TDlgBmClear
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Clear Bookmarks'
  ClientHeight = 420
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
    AutoSize = False
    Caption = 'Отметьте закладки для удаления'
  end
  object lblCount: TLabel
    Left = 12
    Top = 388
    Width = 300
    Height = 18
    AutoSize = False
  end
  object lstBm: TCheckListBox
    Left = 12
    Top = 32
    Width = 616
    Height = 300
    ItemHeight = 16
    TabOrder = 0
    OnClickCheck = lstBmClickCheck
  end
  object btnMark: TUiButton
    Left = 12
    Top = 342
    Width = 130
    Height = 26
    Caption = 'Отметить все'
    TabOrder = 1
    OnClick = btnMarkClick
  end
  object btnUnmark: TUiButton
    Left = 150
    Top = 342
    Width = 130
    Height = 26
    Caption = 'Снять все'
    TabOrder = 2
    OnClick = btnUnmarkClick
  end
  object btnMarkMissing: TUiButton
    Left = 288
    Top = 342
    Width = 200
    Height = 26
    Caption = 'Отметить несуществующие'
    TabOrder = 3
    OnClick = btnMarkMissingClick
  end
  object btnDelete: TUiButton
    Left = 412
    Top = 384
    Width = 104
    Height = 26
    Caption = 'Удалить'
    Default = True
    ModalResult = 1
    TabOrder = 4
  end
  object btnCancel: TUiButton
    Left = 524
    Top = 384
    Width = 104
    Height = 26
    Cancel = True
    Caption = 'Отмена'
    ModalResult = 2
    TabOrder = 5
  end
end
