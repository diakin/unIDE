object DlgAskDisk: TDlgAskDisk
  Left = 527
  Top = 308
  BorderStyle = bsDialog
  Caption = 'Файл изменён на диске'
  ClientHeight = 170
  ClientWidth = 620
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
  object lblInfo: TLabel
    Left = 12
    Top = 10
    Width = 596
    Height = 90
    AutoSize = False
    Caption = 'Файл изменён на диске другой программой:'
    WordWrap = True
  end
  object chkSame: TUiCheckBox
    Left = 12
    Top = 104
    Width = 400
    Height = 21
    Caption = 'Так же для остальных изменённых файлов'
    TabOrder = 0
  end
  object btnReload: TUiButton
    Left = 12
    Top = 134
    Width = 140
    Height = 26
    Caption = 'Перечитать'
    ModalResult = 6
    TabOrder = 1
  end
  object btnMerge: TUiButton
    Left = 161
    Top = 134
    Width = 140
    Height = 26
    Caption = 'Слить'
    ModalResult = 8
    TabOrder = 2
  end
  object btnNewTab: TUiButton
    Left = 310
    Top = 134
    Width = 140
    Height = 26
    Caption = 'В новую вкладку'
    ModalResult = 4
    TabOrder = 3
  end
  object btnKeep: TUiButton
    Left = 459
    Top = 134
    Width = 140
    Height = 26
    Cancel = True
    Caption = 'Оставить окно'
    ModalResult = 7
    TabOrder = 4
  end
end
