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
  FormStyle = fsStayOnTop
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
    Top = 48
    Width = 64
    Height = 18
    Caption = 'Файлы'
  end
  object lblMask: TLabel
    Left = 12
    Top = 158
    Width = 64
    Height = 18
    Caption = 'Маски'
  end
  object lblStatus: TLabel
    Left = 12
    Top = 214
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
    Top = 46
    Width = 428
    Height = 98
    Hint = 'Расширения файлов, в которых искать'
    Columns = 4
    ItemHeight = 16
    ShowHint = True
    TabOrder = 2
  end
  object btnExtAll: TUiButton
    Left = 12
    Top = 72
    Width = 62
    Height = 24
    Hint = 'Отметить все расширения'
    Caption = 'Все'
    ShowHint = True
    TabOrder = 3
  end
  object btnExtNone: TUiButton
    Left = 12
    Top = 100
    Width = 62
    Height = 24
    Hint = 'Снять все отметки'
    Caption = 'Снять'
    ShowHint = True
    TabOrder = 4
  end
  object edMask: TUiEdit
    Left = 80
    Top = 154
    Width = 428
    Height = 24
    Hint = 'Другие маски через ";" (readme*;*.txt). Маска вида *.txt при поиске уходит в список расширений'
    ShowHint = True
    TabOrder = 5
  end
  object chkSub: TUiCheckBox
    Left = 80
    Top = 186
    Width = 300
    Height = 21
    Caption = 'Во вложенных папках'
    TabOrder = 6
  end
  object btnOk: TUiButton
    Left = 332
    Top = 264
    Width = 84
    Height = 26
    Caption = 'Найти'
    Default = True
    TabOrder = 7
  end
  object btnCancel: TUiButton
    Left = 424
    Top = 264
    Width = 84
    Height = 26
    Cancel = True
    Caption = 'Закрыть'
    TabOrder = 8
  end
end
