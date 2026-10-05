object DlgArdCli: TDlgArdCli
  Left = 0
  Top = 0
  Caption = 'Arduino CLI Help'
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
  ShowHint = True
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 16
  object splHelp: TSplitter
    Left = 465
    Top = 0
    Width = 5
    Height = 462
    Cursor = crHSplit
    Align = alRight
  end
  object lblStatus: TLabel
    Left = 0
    Top = 462
    Width = 1000
    Height = 24
    Align = alBottom
    AutoSize = False
    Layout = tlCenter
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 486
    Width = 1000
    Height = 34
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    object edCmdLine: TUiEdit
      Left = 4
      Top = 5
      Width = 816
      Height = 24
      Hint = 'Аргументы arduino-cli (без пути к exe); Enter - выполнить'
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
      OnKeyDown = edCmdLineKeyDown
    end
    object btnRun: TUiButton
      Left = 826
      Top = 4
      Width = 80
      Height = 26
      Hint = 'Выполнить строку команды'
      Anchors = [akTop, akRight]
      Caption = 'Run'
      TabOrder = 1
      OnClick = btnRunClick
    end
    object btnStop: TUiButton
      Left = 912
      Top = 4
      Width = 80
      Height = 26
      Hint = 'Прервать команду'
      Anchors = [akTop, akRight]
      Caption = 'Stop'
      TabOrder = 2
      OnClick = btnStopClick
    end
  end
  object pnlHelp: TPanel
    Left = 470
    Top = 0
    Width = 530
    Height = 462
    Align = alRight
    BevelOuter = bvNone
    TabOrder = 1
    object memHelp: TUiMemo
      Left = 0
      Top = 0
      Width = 530
      Height = 462
      Align = alClient
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Courier New'
      Font.Style = []
      HideSelection = False
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssBoth
      TabOrder = 0
      WordWrap = False
    end
  end
  object pnlLeft: TPanel
    Left = 0
    Top = 0
    Width = 465
    Height = 462
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object pnlFlags: TPanel
      Left = 0
      Top = 430
      Width = 465
      Height = 32
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 0
      object cbFlags: TUiComboBox
        Left = 4
        Top = 4
        Width = 457
        Height = 24
        Hint = 'Флаги arduino-cli: выбранный дописывается в строку команды'
        Anchors = [akLeft, akTop, akRight]
        Style = csDropDownList
        DropDownCount = 16
        ItemHeight = 16
        TabOrder = 0
        OnChange = cbFlagsChange
      end
    end
    object pnlCmds: TPanel
      Left = 0
      Top = 0
      Width = 150
      Height = 430
      Align = alLeft
      BevelOuter = bvNone
      TabOrder = 1
      object lblCmds: TLabel
        Left = 0
        Top = 0
        Width = 150
        Height = 22
        Align = alTop
        Alignment = taCenter
        AutoSize = False
        Caption = 'Arduino Cli commands'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        Layout = tlCenter
      end
      object lbCmds: TUiListBox
        Left = 0
        Top = 22
        Width = 150
        Height = 408
        Align = alClient
        ItemHeight = 16
        TabOrder = 0
        OnClick = lbCmdsClick
      end
    end
    object pnlSubs: TPanel
      Left = 150
      Top = 0
      Width = 315
      Height = 430
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 2
      object lblSubs: TLabel
        Left = 0
        Top = 0
        Width = 315
        Height = 22
        Align = alTop
        Alignment = taCenter
        AutoSize = False
        Caption = 'Arduino Cli sub-commands'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        Layout = tlCenter
      end
      object lbSubs: TUiListBox
        Left = 0
        Top = 22
        Width = 315
        Height = 408
        Align = alClient
        ItemHeight = 16
        TabOrder = 0
        OnClick = lbSubsClick
      end
    end
  end
end
