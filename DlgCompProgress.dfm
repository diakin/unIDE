object DlgCompProgress: TDlgCompProgress
  Left = 420
  Top = 300
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Ход сборки'
  ClientHeight = 318
  ClientWidth = 600
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnClose = FormClose
  PixelsPerInch = 96
  TextHeight = 13
  object lblProgram: TLabel
    Left = 12
    Top = 10
    Width = 576
    Height = 16
    AutoSize = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    ShowAccelChar = False
  end
  object lblLine: TLabel
    Left = 12
    Top = 176
    Width = 576
    Height = 16
    AutoSize = False
    ParentShowHint = False
    ShowAccelChar = False
    ShowHint = True
  end
  object lblPercent: TLabel
    Left = 12
    Top = 222
    Width = 576
    Height = 16
    AutoSize = False
    ShowAccelChar = False
  end
  object lblCounts: TLabel
    Left = 12
    Top = 242
    Width = 576
    Height = 16
    AutoSize = False
    ShowAccelChar = False
  end
  object lstStages: TUiListBox
    Left = 12
    Top = 32
    Width = 576
    Height = 136
    Style = lbOwnerDrawFixed
    ItemHeight = 22
    TabOrder = 0
    TabStop = False
    OnDrawItem = lstStagesDrawItem
  end
  object barProgress: TProgressBar
    Left = 12
    Top = 198
    Width = 576
    Height = 18
    TabOrder = 1
  end
  object chkAutoClose: TUiCheckBox
    Left = 12
    Top = 282
    Width = 330
    Height = 20
    Caption = 'Закрывать окно после удачной сборки'
    Checked = True
    TabOrder = 2
  end
  object btnStop: TUiButton
    Left = 400
    Top = 278
    Width = 90
    Height = 26
    Caption = 'Стоп'
    TabOrder = 3
    OnClick = btnStopClick
  end
  object btnClose: TUiButton
    Left = 498
    Top = 278
    Width = 90
    Height = 26
    Cancel = True
    Caption = 'Скрыть'
    TabOrder = 4
    OnClick = btnCloseClick
  end
  object tmrTick: TTimer
    Enabled = False
    Interval = 150
    OnTimer = tmrTickTimer
    Left = 300
    Top = 120
  end
  object tmrClose: TTimer
    Enabled = False
    Interval = 1200
    OnTimer = tmrCloseTimer
    Left = 340
    Top = 120
  end
end
