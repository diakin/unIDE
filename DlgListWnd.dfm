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
  object pnlPreview: TPanel
    Left = 580
    Top = 0
    Width = 420
    Height = 500
    Align = alRight
    BevelOuter = bvNone
    TabOrder = 1
    object imgPreview: TImage
      Left = 0
      Top = 0
      Width = 420
      Height = 480
      Align = alClient
      Center = True
    end
    object lblPreview: TLabel
      Left = 0
      Top = 480
      Width = 420
      Height = 20
      Align = alBottom
      Alignment = taCenter
      AutoSize = False
      Layout = tlCenter
    end
  end
  object splPreview: TSplitter
    Left = 576
    Top = 0
    Width = 4
    Height = 500
    Align = alRight
  end
  object lvList: TUiListView
    Left = 0
    Top = 0
    Width = 576
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
