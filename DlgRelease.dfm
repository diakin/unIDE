object DlgRelease: TDlgRelease
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Release files'
  ClientHeight = 500
  ClientWidth = 760
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
    Width = 736
    Height = 18
    AutoSize = False
    Caption = 'Что положить в Release вместе с exe'
  end
  object lblNote: TLabel
    Left = 12
    Top = 404
    Width = 736
    Height = 44
    AutoSize = False
    Caption = 'Список найден по именам файлов в исходниках проекта. Отмечено то, что есть на диске и что программа читает. Файлы, которые она только пишет, не отмечены. Выбор запоминается в описании проекта.'
    WordWrap = True
  end
  object lstFiles: TCheckListBox
    Left = 12
    Top = 32
    Width = 736
    Height = 330
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
  end
  object btnMark: TUiButton
    Tag = 1
    Left = 12
    Top = 370
    Width = 120
    Height = 26
    Caption = 'Отметить все'
    TabOrder = 1
    OnClick = btnMarkClick
  end
  object btnUnmark: TUiButton
    Left = 140
    Top = 370
    Width = 120
    Height = 26
    Caption = 'Снять все'
    TabOrder = 2
    OnClick = btnMarkClick
  end
  object btnOk: TUiButton
    Left = 568
    Top = 462
    Width = 84
    Height = 26
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 3
  end
  object btnCancel: TUiButton
    Left = 664
    Top = 462
    Width = 84
    Height = 26
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 4
  end
end
