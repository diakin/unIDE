object DlgListWnd: TDlgListWnd
  Left = 0
  Top = 0
  Caption = 'Модули и формы проекта'
  ClientHeight = 520
  ClientWidth = 1000
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
  object lblPath: TLabel
    Left = 0
    Top = 500
    Width = 1000
    Height = 20
    Align = alBottom
    AutoSize = False
    Layout = tlCenter
  end
  object lvList: TUiListView
    Left = 0
    Top = 0
    Width = 1000
    Height = 500
    Align = alClient
    GridLines = True
    HideSelection = False
    ReadOnly = True
    RowSelect = True
    TabOrder = 0
    ViewStyle = vsReport
  end
end
