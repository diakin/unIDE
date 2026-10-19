object DlgArdWait: TDlgArdWait
  Left = 0
  Top = 0
  BorderStyle = bsSizeToolWin
  Caption = 'Waiting...'
  ClientHeight = 372
  ClientWidth = 672
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsStayOnTop
  KeyPreview = True
  OldCreateOrder = False
  Position = poMainFormCenter
  ShowHint = True
  OnCloseQuery = FormCloseQuery
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 16
  object pbGauge: TPaintBox
    Left = 0
    Top = 0
    Width = 672
    Height = 22
    Align = alTop
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    OnPaint = pbGaugePaint
  end
  object btnStop: TUiButton
    Left = 0
    Top = 22
    Width = 672
    Height = 26
    Hint = 'Прервать arduino-cli'
    Align = alTop
    Caption = 'Stop'
    TabOrder = 0
    OnClick = btnStopClick
  end
  object memOut: TUiMemo
    Left = 0
    Top = 48
    Width = 672
    Height = 324
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 1
    WordWrap = False
  end
end
