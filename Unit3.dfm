object Form3: TForm3
  Left = 211
  Top = 214
  Width = 1180
  Height = 760
  Caption = 'INC Manager'
  Color = clBtnFace
  Constraints.MinHeight = 480
  Constraints.MinWidth = 800
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  ShowHint = True
  OnClose = FormClose
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object UiPanel1: TUiPanel
    Left = 712
    Top = 0
    Width = 452
    Height = 722
    Align = alRight
    BevelOuter = bvNone
    BorderWidth = 2
    Caption = ''
    TabOrder = 2
    object Label1: TLabel
      Left = 6
      Top = 6
      Width = 440
      Height = 22
      Align = alTop
      AutoSize = False
      Caption = 'Файлы inc из отмеченных папок'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      Layout = tlCenter
    end
    object lstIncFiles: TCheckListBox
      Left = 6
      Top = 28
      Width = 440
      Height = 586
      Hint = 'Щелчок - замечания по файлу слева; двойной щелчок - файл в редакторе; галка - участвует в защитном $IFNDEF'
      Align = alClient
      ItemHeight = 18
      Style = lbOwnerDrawFixed
      TabOrder = 0
      OnClick = lstIncFilesClick
      OnDblClick = lstIncFilesDblClick
      OnDrawItem = lstIncFilesDrawItem
    end
    object pnlFileBtns: TPanel
      Left = 6
      Top = 614
      Width = 440
      Height = 38
      Align = alBottom
      BevelOuter = bvNone
      Caption = ''
      TabOrder = 1
      object btnScan: TUiButton
        Left = 0
        Top = 7
        Width = 110
        Height = 25
        Hint = 'Перечитать эталон и файлы с диска и проверить заново'
        Caption = 'Сканировать'
        TabOrder = 0
        OnClick = btnScanClick
      end
      object btnGuard: TUiButton
        Left = 118
        Top = 7
        Width = 140
        Height = 25
        Hint = 'Защитный $IFNDEF в отмеченные файлы, где его нет (прежний текст - в .bak)'
        Caption = 'Защитный $IFNDEF'
        TabOrder = 1
        OnClick = btnGuardClick
      end
      object btnDemo: TUiButton
        Left = 266
        Top = 7
        Width = 110
        Height = 25
        Hint = 'Программа, подключающая выбранный файл: найденная или новая'
        Caption = 'Демо-программа'
        TabOrder = 2
        OnClick = btnDemoClick
      end
    end
    object lblCount: TLabel
      Left = 6
      Top = 652
      Width = 440
      Height = 32
      Align = alBottom
      AutoSize = False
      WordWrap = True
    end
    object lblLegend: TLabel
      Left = 6
      Top = 684
      Width = 440
      Height = 32
      Align = alBottom
      AutoSize = False
      Caption = 'Значок: зелёный - совпадает с эталоном, жёлтый - эталон с тем же именем отличается, белый - в эталоне нет. Красное число - ошибки.'
      WordWrap = True
    end
  end
  object Splitter1: TSplitter
    Left = 706
    Top = 0
    Width = 6
    Height = 722
    Align = alRight
    AutoSnap = False
    MinSize = 300
  end
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 706
    Height = 722
    Align = alClient
    BevelOuter = bvNone
    BorderWidth = 0
    Caption = ''
    TabOrder = 0
    object Panel1: TPanel
      UseDockManager = False
      Left = 1
      Top = 6
      Width = 694
      Height = 330
      Align = alTop
      BevelOuter = bvNone
      Caption = ''
      TabOrder = 0
      object lblFolders: TLabel
        Color = clBtnFace
        Left = 0
        Top = 0
        Width = 694
        Height = 22
        Align = alTop
        AutoSize = False
        Caption = 'Папки с вашими inc-файлами: выберите слева и нажмите "Добавить"; галка в списке - папка участвует'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        Layout = tlCenter
      end
      object Panel4: TPanel
        Left = 0
        Top = 292
        Width = 694
        Height = 38
        Align = alBottom
        BevelOuter = bvNone
        Caption = ''
        TabOrder = 2
        object BitBtn1: TUiButton
          Left = 0
          Top = 7
          Width = 110
          Height = 25
          Hint = 'Папку, выбранную в дереве, - в список'
          Caption = 'Добавить  >>'
          TabOrder = 0
          OnClick = BitBtn1Click
        end
        object BitBtn2: TUiButton
          Left = 118
          Top = 7
          Width = 130
          Height = 25
          Hint = 'Выбранную папку - из списка'
          Caption = 'Удалить из списка'
          TabOrder = 1
          OnClick = BitBtn2Click
        end
        object chkSubDirs: TCheckBox
          Left = 264
          Top = 11
          Width = 200
          Height = 17
          Caption = 'Искать и в подпапках'
          Checked = True
          State = cbChecked
          TabOrder = 2
          OnClick = chkSubDirsClick
        end
      end
      object Panel3: TPanel
        Left = 0
        Top = 22
        Width = 260
        Height = 270
        Align = alLeft
        BevelOuter = bvNone
        Caption = ''
        TabOrder = 0
        object UiPanel2: TUiPanel
          Left = 0
          Top = 0
          Width = 260
          Height = 28
          Align = alTop
          BevelOuter = bvNone
          Caption = ''
          TabOrder = 0
          object DriveComboBox1: TDriveComboBox
            Left = 0
            Top = 2
            Width = 260
            Height = 19
            Anchors = [akLeft, akTop, akRight]
            DirList = DirectoryListBox1
            TabOrder = 0
          end
        end
        object DirectoryListBox1: TDirectoryListBox
          Left = 0
          Top = 28
          Width = 260
          Height = 242
          Align = alClient
          ItemHeight = 16
          TabOrder = 1
        end
      end
      object Splitter2: TSplitter
        Left = 260
        Top = 22
        Width = 6
        Height = 270
        Align = alLeft
        AutoSnap = False
        MinSize = 120
      end
      object CheckListBox1: TCheckListBox
        Left = 266
        Top = 22
        Width = 428
        Height = 270
        Hint = 'Папки с вашими inc; галка - папка участвует в поиске'
        Align = alClient
        ItemHeight = 16
        TabOrder = 1
        OnClickCheck = CheckListBox1ClickCheck
      end
    end
    object pnlRef: TPanel
      Left = 6
      Top = 336
      Width = 694
      Height = 34
      Align = alTop
      BevelOuter = bvNone
      Caption = ''
      TabOrder = 1
      object lblRef: TLabel
        Left = 3
        Top = 10
        Width = 650
        Height = 13
        Anchors = [akLeft, akTop, akRight]
        AutoSize = False
      end
      object btnRef: TUiButton
        Left = 658
        Top = 5
        Width = 36
        Height = 25
        Hint = 'Папка эталонных inc (исходные файлы общих rapidqAllProc.inc и rapidqComponents.inc)'
        Anchors = [akTop, akRight]
        Caption = '...'
        TabOrder = 0
        OnClick = btnRefClick
      end
    end
    object lblErrHead: TLabel
      Color = clBtnFace
      Left = 6
      Top = 370
      Width = 694
      Height = 22
      Align = alTop
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      Layout = tlCenter
    end
    object lstErrors: TListBox
      Left = 6
      Top = 392
      Width = 694
      Height = 324
      Hint = 'Двойной щелчок - строка в редакторе'
      Align = alClient
      ItemHeight = 13
      TabOrder = 2
      OnDblClick = lstErrorsDblClick
    end
  end
end
