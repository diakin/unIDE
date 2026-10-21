object DlgFifDisk: TDlgFifDisk
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Find In Files'
  ClientHeight = 300
  ClientWidth = 520
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
  object lblDir: TLabel
    Left = 12
    Top = 16
    Width = 60
    Height = 18
    Caption = 'Папки'
  end
  object lblExt: TLabel
    Left = 12
    Top = 74
    Width = 64
    Height = 18
    Caption = 'Маски'
  end
  object lblMask: TLabel
    Left = 12
    Top = 184
    Width = 66
    Height = 18
    Caption = 'Доп. маски'
  end
  object lblStatus: TLabel
    Left = 12
    Top = 216
    Width = 496
    Height = 40
    AutoSize = False
    WordWrap = True
  end
  object edDir: TUiEdit
    Left = 80
    Top = 12
    Width = 390
    Height = 24
    TabOrder = 0
  end
  object btnBrowse: TUiButton
    Left = 476
    Top = 11
    Width = 32
    Height = 26
    Caption = '...'
    TabOrder = 1
  end
  object lstExt: TCheckListBox
    Left = 80
    Top = 72
    Width = 428
    Height = 98
    Hint = 'Расширения файлов, в которых искать'
    Columns = 4
    ItemHeight = 16
    ShowHint = True
    TabOrder = 3
  end
  object btnExtAll: TUiButton
    Left = 12
    Top = 76
    Width = 62
    Height = 24
    Hint = 'Отметить все расширения'
    Caption = 'Все'
    ShowHint = True
    TabOrder = 4
  end
  object btnExtNone: TUiButton
    Left = 12
    Top = 104
    Width = 62
    Height = 24
    Hint = 'Снять все отметки'
    Caption = 'Снять'
    ShowHint = True
    TabOrder = 5
  end
  object btnExtDelete: TUiButton
    Left = 12
    Top = 132
    Width = 62
    Height = 24
    Hint = 'Удалить отмеченные маски из списка'
    Caption = 'Удалить'
    ShowHint = True
    TextColor = clRed
    TabOrder = 6
  end
  object edMask: TUiEdit
    Left = 84
    Top = 180
    Width = 336
    Height = 24
    Hint = 'Другие маски через ";" (readme*;*.txt). Add - маски вида *.txt и .txt в список масок выше; при поиске такие маски уходят туда сами'
    ShowHint = True
    TabOrder = 7
  end
  object btnMaskAdd: TUiButton
    Left = 428
    Top = 179
    Width = 80
    Height = 26
    Hint = 'Добавить маски вида *.txt из поля в список масок'
    Caption = 'Add'
    ShowHint = True
    TabOrder = 8
  end
  object chkSub: TUiCheckBox
    Left = 80
    Top = 42
    Width = 300
    Height = 21
    Caption = 'Во вложенных папках'
    TabOrder = 2
  end
  object btnOk: TUiButton
    Left = 332
    Top = 264
    Width = 84
    Height = 26
    Caption = 'Найти'
    Default = True
    TabOrder = 9
  end
  object btnCancel: TUiButton
    Left = 424
    Top = 264
    Width = 84
    Height = 26
    Cancel = True
    Caption = 'Закрыть'
    TabOrder = 10
  end
end
