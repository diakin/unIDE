object DlgFifDisk: TDlgFifDisk
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Find In Files - на диске'
  ClientHeight = 150
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
    Caption = 'Папка'
  end
  object lblMask: TLabel
    Left = 12
    Top = 50
    Width = 60
    Height = 18
    Caption = 'Маски'
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
    ModalResult = 4
    TabOrder = 1
  end
  object edMask: TUiEdit
    Left = 80
    Top = 46
    Width = 428
    Height = 24
    Hint = 'Через точку с запятой: *.pas;*.dpr;*.inc'
    ShowHint = True
    TabOrder = 2
  end
  object chkSub: TUiCheckBox
    Left = 80
    Top = 80
    Width = 300
    Height = 21
    Caption = 'Во вложенных папках'
    TabOrder = 3
  end
  object btnOk: TUiButton
    Left = 332
    Top = 114
    Width = 84
    Height = 26
    Caption = 'Найти'
    Default = True
    ModalResult = 1
    TabOrder = 4
  end
  object btnCancel: TUiButton
    Left = 424
    Top = 114
    Width = 84
    Height = 26
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 5
  end
end
