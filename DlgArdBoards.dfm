object DlgArdBoards: TDlgArdBoards
  Left = 0
  Top = 0
  Caption = 'Board Manager'
  ClientHeight = 640
  ClientWidth = 980
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
  object pnlViews: TPanel
    Left = 0
    Top = 0
    Width = 980
    Height = 32
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object btnAllCores: TUiButton
      Left = 4
      Top = 4
      Width = 120
      Height = 24
      Hint = 'Все платформы: установленные и из индекса'
      Caption = 'All cores list'
      TabOrder = 0
      OnClick = btnAllCoresClick
    end
    object btnInstCores: TUiButton
      Left = 128
      Top = 4
      Width = 140
      Height = 24
      Hint = 'Только установленные платформы (core list)'
      Caption = 'Installed cores list'
      TabOrder = 1
      OnClick = btnInstCoresClick
    end
    object btnAllBoards: TUiButton
      Left = 272
      Top = 4
      Width = 120
      Height = 24
      Hint = 'Все известные платы (board search)'
      Caption = 'All boards list'
      TabOrder = 2
      OnClick = btnAllBoardsClick
    end
    object btnInstBoards: TUiButton
      Left = 396
      Top = 4
      Width = 140
      Height = 24
      Hint = 'Платы установленных платформ'
      Caption = 'Installed boards list'
      TabOrder = 3
      OnClick = btnInstBoardsClick
    end
    object btnRefresh: TUiButton
      Left = 540
      Top = 4
      Width = 140
      Height = 24
      Hint = 'Прочитать списки заново: core list, core search, board search'
      Caption = 'Refresh Board List'
      TabOrder = 4
      OnClick = btnRefreshClick
    end
    object btnCoreOps: TUiButton
      Left = 696
      Top = 4
      Width = 140
      Height = 24
      Hint = 'Операции с платформами'
      Caption = 'Core operations...'
      TabOrder = 5
      OnClick = btnCoreOpsClick
    end
  end
  object pnlFilter: TPanel
    Left = 0
    Top = 32
    Width = 980
    Height = 28
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object edFilter: TUiEdit
      Left = 0
      Top = 2
      Width = 760
      Height = 24
      Hint =
        'С галкой Filter - показывать строки, где есть этот текст; без неё' +
        ' - выбранная платформа для Install core'
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
      OnChange = edFilterChange
    end
    object chkFilter: TUiCheckBox
      Left = 768
      Top = 4
      Width = 80
      Height = 20
      Anchors = [akTop, akRight]
      Caption = 'Filter'
      TabOrder = 1
      OnClick = chkFilterClick
    end
    object btnInstallCore: TUiButton
      Left = 852
      Top = 2
      Width = 124
      Height = 24
      Hint = 'Установить выбранную платформу (core install)'
      Anchors = [akTop, akRight]
      Caption = 'Install core'
      TabOrder = 2
      OnClick = btnInstallCoreClick
    end
  end
  object pnlSelect: TPanel
    Left = 0
    Top = 60
    Width = 980
    Height = 28
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 2
    object edSelBoard: TUiEdit
      Left = 0
      Top = 2
      Width = 848
      Height = 24
      Hint = 'Выбранная плата: FQBN/имя/платформа'
      Anchors = [akLeft, akTop, akRight]
      ReadOnly = True
      TabOrder = 0
    end
    object btnSelectBoard: TUiButton
      Left = 852
      Top = 2
      Width = 124
      Height = 24
      Hint = 'Плата (FQBN), для которой собирается скетч'
      Anchors = [akTop, akRight]
      Caption = 'Select board'
      TabOrder = 1
      OnClick = btnSelectBoardClick
    end
  end
  object pcMain: TUiPageControl
    Left = 0
    Top = 88
    Width = 980
    Height = 254
    ActivePage = tsCores
    Align = alClient
    TabOrder = 3
    object tsCores: TTabSheet
      Caption = 'Core list'
      object splCores: TSplitter
        Left = 560
        Top = 0
        Width = 5
        Height = 223
        Cursor = crHSplit
      end
      object lvCores: TUiListView
        Left = 0
        Top = 0
        Width = 560
        Height = 223
        Align = alLeft
        Columns = <
          item
            Caption = '#'
            Width = 40
          end
          item
            Caption = 'Board group name'
            Width = 220
          end
          item
            Caption = 'Installed'
            Width = 90
          end
          item
            Caption = 'Latest'
            Width = 70
          end
          item
            Caption = 'PlatformID (Core)'
            Width = 130
          end>
        GridLines = True
        HideSelection = False
        ReadOnly = True
        RowSelect = True
        TabOrder = 0
        ViewStyle = vsReport
        OnSelectItem = lvCoresSelectItem
      end
      object lvCoreBoards: TUiListView
        Left = 565
        Top = 0
        Width = 407
        Height = 223
        Align = alClient
        Columns = <
          item
            Caption = '#'
            Width = 40
          end
          item
            Caption = 'Board name'
            Width = 200
          end
          item
            Caption = 'FQBN'
            Width = 200
          end
          item
            Caption = 'PlatformID (Core)'
            Width = 130
          end>
        GridLines = True
        HideSelection = False
        ReadOnly = True
        RowSelect = True
        TabOrder = 1
        ViewStyle = vsReport
        OnSelectItem = lvBoardSelectItem
      end
    end
    object tsBoards: TTabSheet
      Caption = 'Board list'
      ImageIndex = 1
      object lvBoards: TUiListView
        Left = 0
        Top = 0
        Width = 972
        Height = 223
        Align = alClient
        Columns = <
          item
            Caption = '#'
            Width = 50
          end
          item
            Caption = 'Board name'
            Width = 300
          end
          item
            Caption = 'FQBN'
            Width = 260
          end
          item
            Caption = 'PlatformID (Core)'
            Width = 200
          end>
        GridLines = True
        HideSelection = False
        ReadOnly = True
        RowSelect = True
        TabOrder = 0
        ViewStyle = vsReport
        OnSelectItem = lvBoardSelectItem
      end
    end
    object tsUrls: TTabSheet
      Caption = '3rd-party-boards list'
      ImageIndex = 2
      object lblUrls: TLabel
        Left = 0
        Top = 0
        Width = 972
        Height = 22
        Align = alTop
        AutoSize = False
        Caption =
          'Additional Boards Manager URLs - по одному адресу в строке (http' +
          's://.../package_..._index.json)'
        Layout = tlCenter
      end
      object memUrls: TUiMemo
        Left = 0
        Top = 22
        Width = 972
        Height = 169
        Align = alClient
        ScrollBars = ssBoth
        TabOrder = 0
        WordWrap = False
      end
      object pnlUrlsButtons: TPanel
        Left = 0
        Top = 191
        Width = 972
        Height = 32
        Align = alBottom
        BevelOuter = bvNone
        TabOrder = 1
        object btnUrlsSave: TUiButton
          Left = 4
          Top = 4
          Width = 100
          Height = 24
          Hint = 'Записать адреса в editor.ini'
          Caption = 'Save'
          TabOrder = 0
          OnClick = btnUrlsSaveClick
        end
        object btnUrlsIndex: TUiButton
          Left = 112
          Top = 4
          Width = 180
          Height = 24
          Hint = 'Записать адреса и обновить индекс платформ (core update-index)'
          Caption = 'Save and update index'
          TabOrder = 1
          OnClick = btnUrlsIndexClick
        end
      end
    end
    object tsLog: TTabSheet
      Caption = 'Log'
      ImageIndex = 3
      object memLog: TUiMemo
        Left = 0
        Top = 0
        Width = 972
        Height = 223
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Courier New'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 0
        WordWrap = False
      end
    end
  end
  object splFiles: TSplitter
    Left = 0
    Top = 342
    Width = 980
    Height = 5
    Cursor = crVSplit
    Align = alBottom
  end
  object pnlFiles: TPanel
    Left = 0
    Top = 347
    Width = 980
    Height = 265
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 4
    object splProgr: TSplitter
      Left = 300
      Top = 0
      Width = 5
      Height = 265
      Cursor = crHSplit
    end
    object splPlatf: TSplitter
      Left = 715
      Top = 0
      Width = 5
      Height = 265
      Cursor = crHSplit
      Align = alRight
    end
    object pnlProgr: TPanel
      Left = 0
      Top = 0
      Width = 300
      Height = 265
      Align = alLeft
      BevelOuter = bvNone
      TabOrder = 0
      object lblProgr: TLabel
        Left = 0
        Top = 0
        Width = 300
        Height = 22
        Align = alTop
        Alignment = taCenter
        AutoSize = False
        Caption = 'programmers.txt'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        Layout = tlCenter
      end
      object memProgr: TUiMemo
        Left = 0
        Top = 22
        Width = 300
        Height = 243
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Courier New'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 0
        WordWrap = False
      end
    end
    object pnlPlatf: TPanel
      Left = 720
      Top = 0
      Width = 260
      Height = 265
      Align = alRight
      BevelOuter = bvNone
      TabOrder = 1
      object lblPlatf: TLabel
        Left = 0
        Top = 0
        Width = 260
        Height = 22
        Align = alTop
        Alignment = taCenter
        AutoSize = False
        Caption = 'platform.txt'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        Layout = tlCenter
      end
      object memPlatf: TUiMemo
        Left = 0
        Top = 22
        Width = 260
        Height = 243
        Align = alClient
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Courier New'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 0
        WordWrap = False
      end
    end
    object pnlBoardsTxt: TPanel
      Left = 305
      Top = 0
      Width = 410
      Height = 265
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 2
      object lblBoardsTxt: TLabel
        Left = 0
        Top = 0
        Width = 410
        Height = 22
        Align = alTop
        Alignment = taCenter
        AutoSize = False
        Caption = 'boards.txt'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        Layout = tlCenter
      end
      object memBoardsTxt: TUiMemo
        Left = 0
        Top = 22
        Width = 410
        Height = 243
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
  end
  object pnlStatus: TPanel
    Left = 0
    Top = 612
    Width = 980
    Height = 28
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 5
    object lblStatus: TLabel
      Left = 0
      Top = 0
      Width = 900
      Height = 28
      Align = alClient
      AutoSize = False
      Layout = tlCenter
    end
    object btnStop: TUiButton
      Left = 900
      Top = 0
      Width = 80
      Height = 28
      Hint = 'Прервать команду arduino-cli'
      Align = alRight
      Caption = 'Stop'
      TabOrder = 0
      OnClick = btnStopClick
    end
  end
  object pmCoreOps: TUiPopupMenu
    Left = 840
    Top = 8
    object miCoreDownload: TMenuItem
      Caption = 'Download Core'
      Hint = 'Скачать платформу без установки (core download)'
      OnClick = miCoreDownloadClick
    end
    object miCoreInstall: TMenuItem
      Caption = 'Install selected Core'
      Hint = 'Установить платформу (core install)'
      OnClick = miCoreInstallClick
    end
    object miCoreUninstall: TMenuItem
      Caption = 'Uninstall Core'
      Hint = 'Удалить платформу (core uninstall)'
      OnClick = miCoreUninstallClick
    end
    object miCoreSearch: TMenuItem
      Caption = 'Search Core'
      Hint = 'Поиск платформ по словам из поля фильтра (core search)'
      OnClick = miCoreSearchClick
    end
    object miCoreUpdateIndex: TMenuItem
      Caption = 'Updates index'
      Hint = 'Обновить индекс платформ (core update-index)'
      OnClick = miCoreUpdateIndexClick
    end
    object miCoreUpgrade: TMenuItem
      Caption = 'Upgrade platforms'
      Hint = 'Обновить выбранную установленную платформу или все (core upgrade)'
      OnClick = miCoreUpgradeClick
    end
  end
end
