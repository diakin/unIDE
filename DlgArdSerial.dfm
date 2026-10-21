object DlgArdSerial: TDlgArdSerial
  Left = 0
  Top = 0
  Caption = 'Serial Monitor'
  ClientHeight = 460
  ClientWidth = 820
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  ShowHint = True
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 16
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 820
    Height = 34
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object edSend: TUiEdit
      Left = 4
      Top = 5
      Width = 726
      Height = 24
      Hint = 'Текст для отправки в порт; Enter - отправить'
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
      OnKeyDown = edSendKeyDown
    end
    object btnSend: TUiButton
      Left = 736
      Top = 4
      Width = 80
      Height = 26
      Hint = 'Отправить текст с выбранным окончанием строки'
      Anchors = [akTop, akRight]
      Caption = 'Send'
      TabOrder = 1
      OnClick = btnSendClick
    end
  end
  object memOut: TUiMemo
    Left = 0
    Top = 34
    Width = 820
    Height = 392
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    HideSelection = False
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 1
    WordWrap = False
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 426
    Width = 820
    Height = 34
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object lblState: TLabel
      Left = 250
      Top = 9
      Width = 50
      Height = 16
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      ShowAccelChar = False
    end
    object chkAutoscroll: TUiCheckBox
      Left = 4
      Top = 8
      Width = 100
      Height = 20
      Hint = 'Прокручивать вывод к последней строке'
      Caption = 'Autoscroll'
      TabOrder = 0
      OnClick = OptionChange
    end
    object chkTimestamp: TUiCheckBox
      Left = 110
      Top = 8
      Width = 135
      Height = 20
      Hint = 'Время прихода в начале каждой строки'
      Caption = 'Show timestamp'
      TabOrder = 1
      OnClick = OptionChange
    end
    object cbLineEnd: TUiComboBox
      Left = 306
      Top = 5
      Width = 140
      Height = 24
      Hint = 'Что дописывается к отправляемому тексту'
      Anchors = [akTop, akRight]
      Style = csDropDownList
      ItemHeight = 16
      TabOrder = 2
      OnChange = OptionChange
    end
    object cbBaud: TUiComboBox
      Left = 452
      Top = 5
      Width = 120
      Height = 24
      Hint = 'Скорость порта'
      Anchors = [akTop, akRight]
      Style = csDropDownList
      DropDownCount = 16
      ItemHeight = 16
      TabOrder = 3
      OnChange = cbBaudChange
    end
    object btnClear: TUiButton
      Left = 578
      Top = 4
      Width = 110
      Height = 26
      Hint = 'Очистить поле вывода'
      Anchors = [akTop, akRight]
      Caption = 'Clear output'
      TabOrder = 4
      OnClick = btnClearClick
    end
    object btnOpen: TUiButton
      Left = 694
      Top = 4
      Width = 122
      Height = 26
      Hint = 'Закрыть или открыть порт'
      Anchors = [akTop, akRight]
      Caption = 'Close'
      TabOrder = 5
      OnClick = btnOpenClick
    end
  end
  object tmrRead: TTimer
    Enabled = False
    Interval = 30
    OnTimer = tmrReadTimer
    Left = 24
    Top = 64
  end
end
