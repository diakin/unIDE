object DlgProgress: TDlgProgress
  Left = 468
  Top = 506
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Выполняется'
  ClientHeight = 132
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
  object lblStage: TLabel
    Left = 12
    Top = 10
    Width = 736
    Height = 44
    AutoSize = False
    Caption = 'Подготовка...'
  end
  object barProgress: TProgressBar
    Left = 12
    Top = 62
    Width = 736
    Height = 18
    TabOrder = 0
  end
  object btnStop: TUiButton
    Left = 658
    Top = 92
    Width = 90
    Height = 25
    Cancel = True
    Caption = 'Стоп'
    TabOrder = 1
  end
end
