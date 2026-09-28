object DlgProgress: TDlgProgress
  Left = 468
  Top = 506
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Выполняется'
  ClientHeight = 104
  ClientWidth = 340
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
    Top = 12
    Width = 316
    Height = 13
    AutoSize = False
    Caption = 'Подготовка...'
  end
  object barProgress: TProgressBar
    Left = 12
    Top = 34
    Width = 316
    Height = 18
    TabOrder = 0
  end
  object btnStop: TUiButton
    Left = 238
    Top = 64
    Width = 90
    Height = 25
    Cancel = True
    Caption = 'Стоп'
    TabOrder = 1
  end
end
