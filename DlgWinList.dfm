object DlgWinList: TDlgWinList
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'Закрыть окна'
  ClientHeight = 460
  ClientWidth = 700
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object pnlRoot: TPanel
    Left = 0
    Top = 0
    Width = 700
    Height = 460
    Align = alClient
    BorderWidth = 3
    TabOrder = 0
    object pnlCaption: TPanel
      Left = 4
      Top = 4
      Width = 692
      Height = 22
      Align = alTop
      BevelOuter = bvNone
      Caption = 'Закрыть окна'
      Color = clBtnShadow
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindow
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
    end
    object pnlButtons: TPanel
      Left = 4
      Top = 416
      Width = 692
      Height = 40
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 1
      object btnAll: TUiButton
        Left = 8
        Top = 8
        Width = 110
        Height = 25
        Caption = 'Отметить все'
        TabOrder = 0
      end
      object btnOk: TUiButton
        Left = 466
        Top = 8
        Width = 140
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Закрыть отмеченные'
        Default = True
        ModalResult = 1
        TabOrder = 2
      end
      object btnCancel: TUiButton
        Left = 614
        Top = 8
        Width = 78
        Height = 25
        Anchors = [akTop, akRight]
        Cancel = True
        Caption = 'Отмена'
        ModalResult = 2
        TabOrder = 1
      end
    end
    object lstWindows: TCheckListBox
      Left = 4
      Top = 26
      Width = 692
      Height = 390
      Align = alClient
      BorderStyle = bsNone
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
    end
  end
end
