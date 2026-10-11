object Form3: TForm3
  Left = 99
  Top = 85
  Width = 1322
  Height = 897
  Caption = 'INC Manager'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  ShowHint = True
  OnClose = FormClose
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object UiPanel1: TUiPanel
    Align = alRight
    Left = 476
    Top = 0
    Width = 640
    Height = 848
    Caption = 'UiPanel1'
    Color = 3157293
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 7976923
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentBackground = False
    ParentFont = False
    object Label1: TLabel
      Align = alTop
      Color = clTeal
      Alignment = taCenter
      AutoSize = False
      Left = 86
      Top = 20
      Width = 262
      Height = 23
      Caption = 'Список файлов inc c галками'
    end
    object lstIncFiles: TCheckListBox
      Align = alTop
      Left = 60
      Top = 60
      Width = 304
      Height = 418
      Hint = 'Щелчок - замечания по файлу слева; двойной щелчок - файл в редакторе'
      ItemHeight = 18
      Style = lbOwnerDrawFixed
      TabOrder = 1
      OnClick = lstIncFilesClick
      OnDblClick = lstIncFilesDblClick
      OnDrawItem = lstIncFilesDrawItem
    end
    object btnScan: TBitBtn
      Left = 143
      Top = 491
      Width = 96
      Height = 25
      Hint = 'Перечитать эталон и файлы с диска и проверить заново'
      Caption = 'Сканировать'
      TabOrder = 4
      OnClick = btnScanClick
    end
    object btnGuard: TBitBtn
      Left = 160
      Top = 446
      Width = 110
      Height = 25
      Hint = 'Защитный $IFNDEF в отмеченные файлы, где его нет (прежний текст - в .bak)'
      Caption = 'Защитный $IFNDEF'
      TabOrder = 5
      OnClick = btnGuardClick
    end
    object btnDemo: TBitBtn
      Left = 276
      Top = 446
      Width = 86
      Height = 25
      Hint = 'Программа, подключающая выбранный файл: найденная или новая'
      Caption = 'Демо'
      TabOrder = 6
      OnClick = btnDemoClick
    end
    object lblCount: TLabel
      Color = clNavy
      Left = 60
      Top = 534
      Width = 304
      Height = 28
      AutoSize = False
      WordWrap = True
    end
    object lblLegend: TLabel
      Color = clMaroon
      Align = alBottom
      Left = 60
      Top = 566
      Width = 304
      Height = 40
      AutoSize = False
      Caption = 'Значок: зелёный - совпадает с эталоном, жёлтый - эталон с тем же именем отличается, белый - в эталоне нет. Красное число - ошибки.'
      WordWrap = True
    end
  end
  object Panel2: TPanel
    Color = clBlue
    Align = alNone
    Left = 0
    Top = 0
    Width = 420
    Height = 859
    Caption = 'Panel2'
    object Panel1: TPanel
      Color = clGreen
      Align = alTop
      Left = 2
      Top = 4
      Width = 380
      Height = 537
      Caption = 'Выбор директории для поиска'
      object CheckListBox1: TCheckListBox
        Align = alClient
        Left = 594
        Top = 0
        Width = 495
        Height = 188
        ItemHeight = 16
        TabOrder = 2
        OnClickCheck = CheckListBox1ClickCheck
      end
      object Panel3: TPanel
        Align = alLeft
        Left = 0
        Top = 4
        Width = 284
        Height = 328
        Caption = 'Panel3'
        object DirectoryListBox1: TDirectoryListBox
          Align = alClient
          Left = 1
          Top = 42
          Width = 203
          Height = 285
          ItemHeight = 16
          TabOrder = 1
        end
        object UiPanel2: TUiPanel
          Align = alTop
          Left = 0
          Top = 0
          Width = 340
          Height = 41
          Caption = 'UiPanel2'
          Color = clPurple
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 7976923
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentBackground = False
          ParentFont = False
          object DriveComboBox1: TDriveComboBox
            Font.Size = 10
            Left = 2
            Top = 8
            Width = 108
            Height = 24
            DirList = DirectoryListBox1
            TabOrder = 0
          end
        end
      end
      object Panel4: TPanel
        Color = clTeal
        Align = alBottom
        Left = 356
        Top = 344
        Width = 468
        Height = 50
        Caption = 'Panel4'
        object BitBtn1: TBitBtn
          Left = 40
          Top = 0
          Width = 122
          Height = 25
          Caption = 'Добавить'
          TabOrder = 3
          OnClick = BitBtn1Click
        end
        object BitBtn2: TBitBtn
          Left = 178
          Top = 0
          Width = 116
          Height = 25
          Caption = 'Удалить из списка'
          TabOrder = 4
          OnClick = BitBtn2Click
        end
        object chkSubDirs: TCheckBox
          Left = 40
          Top = 30
          Width = 200
          Height = 17
          Caption = 'Искать и в подпапках'
          Checked = True
          State = cbChecked
          TabOrder = 5
          OnClick = chkSubDirsClick
        end
      end
    end
    object lblRef: TLabel
      Color = clGradientInactiveCaption
      Left = 326
      Top = 658
      Width = 340
      Height = 13
      AutoSize = False
    end
    object lblErrHead: TLabel
      Left = 4
      Top = 308
      Width = 378
      Height = 13
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lstErrors: TListBox
      Align = alBottom
      Left = 2
      Top = 326
      Width = 380
      Height = 154
      Hint = 'Двойной щелчок - строка в редакторе'
      ItemHeight = 13
      TabOrder = 3
      OnDblClick = lstErrorsDblClick
    end
    object btnRef: TBitBtn
      Left = 432
      Top = 568
      Width = 196
      Height = 60
      Hint = 'Папка эталонных inc (исходные файлы общих rapidqAllProc.inc и rapidqComponents.inc)'
      Caption = '...'
      TabOrder = 2
      OnClick = btnRefClick
    end
  end
  object Splitter1: TSplitter
    Align = alClient
    Color = clRed
    Left = 448
    Top = 114
    Height = 0
  end
end
