object Form3: TForm3
  Left = 576
  Top = 251
  Width = 712
  Height = 624
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
  object Panel1: TPanel
    Left = 2
    Top = 4
    Width = 380
    Height = 272
    Caption = 'Выбор директории для поиска'
    object DriveComboBox1: TDriveComboBox
      Left = 2
      Top = 8
      Width = 174
      Height = 19
      DirList = DirectoryListBox1
      TabOrder = 0
    end
    object DirectoryListBox1: TDirectoryListBox
      Left = 2
      Top = 32
      Width = 174
      Height = 164
      ItemHeight = 16
      TabOrder = 1
    end
    object BitBtn1: TBitBtn
      Left = 10
      Top = 204
      Width = 122
      Height = 25
      Caption = 'Добавить'
      TabOrder = 3
      OnClick = BitBtn1Click
    end
    object BitBtn2: TBitBtn
      Left = 148
      Top = 204
      Width = 116
      Height = 25
      Caption = 'Удалить из списка'
      TabOrder = 4
      OnClick = BitBtn2Click
    end
    object CheckListBox1: TCheckListBox
      Left = 184
      Top = 8
      Width = 188
      Height = 188
      ItemHeight = 16
      TabOrder = 2
      OnClickCheck = CheckListBox1ClickCheck
    end
    object chkSubDirs: TCheckBox
      Left = 10
      Top = 240
      Width = 200
      Height = 17
      Caption = 'Искать и в подпапках'
      Checked = True
      State = cbChecked
      TabOrder = 5
      OnClick = chkSubDirsClick
    end
  end
  object lblRef: TLabel
    Left = 4
    Top = 284
    Width = 340
    Height = 13
    AutoSize = False
  end
  object btnRef: TBitBtn
    Left = 350
    Top = 280
    Width = 30
    Height = 21
    Hint = 'Папка эталонных inc (исходные файлы общих rapidqAllProc.inc и rapidqComponents.inc)'
    Caption = '...'
    TabOrder = 2
    OnClick = btnRefClick
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
    Left = 2
    Top = 326
    Width = 380
    Height = 258
    Hint = 'Двойной щелчок - строка в редакторе'
    ItemHeight = 13
    TabOrder = 3
    OnDblClick = lstErrorsDblClick
  end
  object Label1: TLabel
    Alignment = taCenter
    AutoSize = False
    Left = 418
    Top = 0
    Width = 262
    Height = 36
    Caption = 'Список файлов inc c галками'
  end
  object lstIncFiles: TCheckListBox
    Left = 392
    Top = 40
    Width = 304
    Height = 436
    Hint = 'Щелчок - замечания по файлу слева; двойной щелчок - файл в редакторе'
    ItemHeight = 18
    Style = lbOwnerDrawFixed
    TabOrder = 1
    OnClick = lstIncFilesClick
    OnDblClick = lstIncFilesDblClick
    OnDrawItem = lstIncFilesDrawItem
  end
  object btnScan: TBitBtn
    Left = 392
    Top = 484
    Width = 96
    Height = 25
    Hint = 'Перечитать эталон и файлы с диска и проверить заново'
    Caption = 'Сканировать'
    TabOrder = 4
    OnClick = btnScanClick
  end
  object btnGuard: TBitBtn
    Left = 494
    Top = 484
    Width = 110
    Height = 25
    Hint = 'Защитный $IFNDEF в отмеченные файлы, где его нет (прежний текст - в .bak)'
    Caption = 'Защитный $IFNDEF'
    TabOrder = 5
    OnClick = btnGuardClick
  end
  object btnDemo: TBitBtn
    Left = 610
    Top = 484
    Width = 86
    Height = 25
    Hint = 'Программа, подключающая выбранный файл: найденная или новая'
    Caption = 'Демо'
    TabOrder = 6
    OnClick = btnDemoClick
  end
  object lblCount: TLabel
    Left = 392
    Top = 514
    Width = 304
    Height = 28
    AutoSize = False
    WordWrap = True
  end
  object lblLegend: TLabel
    Left = 392
    Top = 546
    Width = 304
    Height = 40
    AutoSize = False
    Caption = 'Значок: зелёный - совпадает с эталоном, жёлтый - эталон с тем же именем отличается, белый - в эталоне нет. Красное число - ошибки.'
    WordWrap = True
  end
end
