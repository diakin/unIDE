object DlgArdLibs: TDlgArdLibs
  Left = 0
  Top = 0
  Caption = 'Library Manager'
  ClientHeight = 600
  ClientWidth = 900
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
  object splLibs: TSplitter
    Left = 360
    Top = 60
    Width = 5
    Height = 380
    Cursor = crHSplit
  end
  object splLog: TSplitter
    Left = 0
    Top = 440
    Width = 900
    Height = 5
    Cursor = crVSplit
    Align = alBottom
  end
  object pnlJson: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 30
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblJson: TLabel
      Left = 0
      Top = 0
      Width = 660
      Height = 30
      Align = alClient
      AutoSize = False
      Caption = 'library_index.json'
      Layout = tlCenter
    end
    object btnUpdateIdx: TUiButton
      Left = 660
      Top = 0
      Width = 140
      Height = 30
      Hint = 'Обновить индекс библиотек (lib update-index) и прочитать его'
      Align = alRight
      Caption = 'Update Lib Idx'
      TabOrder = 0
      OnClick = btnUpdateIdxClick
    end
    object btnStop: TUiButton
      Left = 800
      Top = 0
      Width = 100
      Height = 30
      Hint = 'Прервать команду arduino-cli или чтение индекса'
      Align = alRight
      Caption = 'StopIt !'
      TabOrder = 1
      OnClick = btnStopClick
    end
  end
  object pnlFilter: TPanel
    Left = 0
    Top = 30
    Width = 900
    Height = 30
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object lblType: TLabel
      Left = 6
      Top = 7
      Width = 32
      Height = 16
      Caption = 'Type'
    end
    object lblTopic: TLabel
      Left = 192
      Top = 7
      Width = 34
      Height = 16
      Caption = 'Topic'
    end
    object lblSearch: TLabel
      Left = 420
      Top = 7
      Width = 43
      Height = 16
      Caption = 'Search'
    end
    object lblCount: TLabel
      Left = 760
      Top = 7
      Width = 134
      Height = 16
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      AutoSize = False
    end
    object cbType: TUiComboBox
      Left = 44
      Top = 3
      Width = 140
      Height = 24
      Hint = 'Тип библиотеки (поле types индекса)'
      Style = csDropDownList
      DropDownCount = 12
      ItemHeight = 16
      TabOrder = 0
      OnChange = FilterChange
    end
    object cbTopic: TUiComboBox
      Left = 232
      Top = 3
      Width = 180
      Height = 24
      Hint = 'Тема библиотеки (поле category индекса)'
      Style = csDropDownList
      DropDownCount = 12
      ItemHeight = 16
      TabOrder = 1
      OnChange = FilterChange
    end
    object edSearch: TUiEdit
      Left = 470
      Top = 3
      Width = 280
      Height = 24
      Hint = 'Часть имени библиотеки'
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 2
      OnChange = FilterChange
    end
  end
  object lvLibs: TUiListView
    Left = 0
    Top = 60
    Width = 360
    Height = 380
    Align = alLeft
    Columns = <
      item
        Caption = '#'
        Width = 55
      end
      item
        Caption = 'Library name'
        Width = 200
      end
      item
        Caption = 'Version'
        Width = 80
      end>
    GridLines = True
    HideSelection = False
    OwnerData = True
    ReadOnly = True
    RowSelect = True
    TabOrder = 2
    ViewStyle = vsReport
    OnData = lvLibsData
    OnSelectItem = lvLibsSelectItem
  end
  object pnlRight: TPanel
    Left = 365
    Top = 60
    Width = 535
    Height = 380
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 3
    object memDetails: TUiMemo
      Left = 0
      Top = 0
      Width = 535
      Height = 320
      Align = alClient
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
    end
    object pnlCmd: TPanel
      Left = 0
      Top = 320
      Width = 535
      Height = 60
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 1
      object cbLibCmd: TUiComboBox
        Left = 0
        Top = 0
        Width = 535
        Height = 24
        Hint = 'Команда arduino-cli lib'
        Anchors = [akLeft, akTop, akRight]
        Style = csDropDownList
        DropDownCount = 12
        ItemHeight = 16
        TabOrder = 0
      end
      object pnlCmdArgs: TPanel
        Left = 0
        Top = 24
        Width = 535
        Height = 36
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 1
        object lblLibName: TLabel
          Left = 6
          Top = 10
          Width = 200
          Height = 16
          AutoSize = False
          Caption = 'name'
        end
        object chkVersion: TUiCheckBox
          Left = 212
          Top = 8
          Width = 170
          Height = 20
          Hint = 'Команде deps, download, install - имя@версия'
          Caption = 'version'
          TabOrder = 0
        end
        object btnRunCmd: TUiButton
          Left = 405
          Top = 0
          Width = 130
          Height = 36
          Hint = 'Выполнить команду для выбранной библиотеки'
          Align = alRight
          Caption = 'Run ClibCmd'
          TabOrder = 1
          OnClick = btnRunCmdClick
        end
      end
    end
  end
  object memLog: TUiMemo
    Left = 0
    Top = 445
    Width = 900
    Height = 155
    Align = alBottom
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 4
    WordWrap = False
  end
end
