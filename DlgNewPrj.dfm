object DlgNewPrj: TDlgNewPrj
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'New Project'
  ClientHeight = 182
  ClientWidth = 760
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object lblName: TLabel
    Left = 12
    Top = 16
    Width = 64
    Height = 13
    Caption = 'Имя проекта'
  end
  object lblDir: TLabel
    Left = 12
    Top = 48
    Width = 75
    Height = 13
    Caption = 'Папка проекта'
  end
  object lblType: TLabel
    Left = 12
    Top = 108
    Width = 63
    Height = 13
    Caption = 'Тип проекта'
  end
  object edName: TUiEdit
    Left = 110
    Top = 12
    Width = 310
    TabOrder = 0
  end
  object edDir: TUiEdit
    Left = 110
    Top = 44
    Width = 595
    TabOrder = 1
  end
  object btnBrowse: TUiButton
    Left = 710
    Top = 43
    Width = 30
    Height = 23
    Caption = '...'
    ModalResult = 4
    TabOrder = 2
  end
  object chkBase: TUiCheckBox
    Left = 110
    Top = 76
    Width = 310
    Caption = 'На базе существующего проекта'
    TabOrder = 3
  end
  object cbType: TUiComboBox
    Left = 110
    Top = 104
    Width = 310
    Style = csDropDownList
    TabOrder = 4
    Items.Strings = (
      'RapidQ Basic'
      'Delphi'
      'Lazarus'
      'FreeBASIC'
      'Visual Basic'
      'Arduino'
      'C project'
      'CPP project'
      'Go'
      'Python'
      'Rust'
      'WebSite')
  end
  object btnOk: TUiButton
    Left = 574
    Top = 144
    Width = 80
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 5
  end
  object btnCancel: TUiButton
    Left = 660
    Top = 144
    Width = 80
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 6
  end
end
