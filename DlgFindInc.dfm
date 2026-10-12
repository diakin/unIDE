object DlgFindInc: TDlgFindInc
  Left = 300
  Top = 200
  Width = 780
  Height = 560
  Caption = 'Поиск inc-файла'
  Color = clBtnFace
  Constraints.MinHeight = 400
  Constraints.MinWidth = 640
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
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 772
    Height = 66
    Align = alTop
    BevelOuter = bvNone
    Caption = ''
    TabOrder = 0
    object lblName: TLabel
      Left = 8
      Top = 12
      Width = 60
      Height = 13
      Caption = 'Имя файла:'
    end
    object lblFolder: TLabel
      Left = 8
      Top = 42
      Width = 700
      Height = 13
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
    end
    object edName: TUiEdit
      Left = 76
      Top = 8
      Width = 260
      Height = 21
      Hint = 'Имя inc-файла, например QColorDialog10.inc; Enter - найти'
      TabOrder = 0
      OnKeyPress = edNameKeyPress
    end
    object btnFind: TUiButton
      Left = 344
      Top = 6
      Width = 90
      Height = 25
      Hint = 'Найти все копии файла; во время поиска - остановить'
      Caption = 'Найти'
      TabOrder = 1
      OnClick = btnFindClick
    end
    object chkAllDrives: TUiCheckBox
      Left = 446
      Top = 10
      Width = 180
      Height = 17
      Hint = 'Все локальные диски; без галки - папка, выбранная кнопкой "..."'
      Caption = 'Все локальные диски'
      TabOrder = 2
      OnClick = chkAllDrivesClick
    end
    object btnFolder: TUiButton
      Left = 728
      Top = 37
      Width = 36
      Height = 23
      Hint = 'Папка, в которой искать'
      Anchors = [akTop, akRight]
      Caption = '...'
      TabOrder = 3
      OnClick = btnFolderClick
    end
  end
  object lblFound: TLabel
    Left = 0
    Top = 66
    Width = 772
    Height = 20
    Align = alTop
    AutoSize = False
    Caption = '  Найденные копии'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
    Layout = tlCenter
  end
  object lstFound: TListBox
    Left = 0
    Top = 86
    Width = 772
    Height = 180
    Hint = 'Щелчок - сведения о копии ниже; двойной щелчок - открыть в редакторе'
    Align = alTop
    ItemHeight = 18
    Style = lbOwnerDrawFixed
    TabOrder = 1
    OnClick = lstFoundClick
    OnDblClick = lstFoundDblClick
    OnDrawItem = lstFoundDrawItem
  end
  object Splitter1: TSplitter
    Left = 0
    Top = 266
    Width = 772
    Height = 5
    Cursor = crVSplit
    Align = alTop
    AutoSnap = False
    MinSize = 60
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 434
    Width = 772
    Height = 92
    Align = alBottom
    BevelOuter = bvNone
    Caption = ''
    TabOrder = 3
    object lblTarget: TLabel
      Left = 8
      Top = 10
      Width = 700
      Height = 13
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
    end
    object lblStatus: TLabel
      Left = 8
      Top = 68
      Width = 756
      Height = 13
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
    end
    object btnTarget: TUiButton
      Left = 728
      Top = 5
      Width = 36
      Height = 23
      Hint = 'Папка, куда копировать (по умолчанию - папка inc проекта)'
      Anchors = [akTop, akRight]
      Caption = '...'
      TabOrder = 0
      OnClick = btnTargetClick
    end
    object btnCopy: TUiButton
      Left = 8
      Top = 34
      Width = 230
      Height = 25
      Hint = 'Выбранную копию - в папку inc проекта; нет защитного $IFNDEF - он ставится в копию'
      Caption = 'Копировать в папку inc проекта'
      TabOrder = 1
      OnClick = btnCopyClick
    end
    object btnOpen: TUiButton
      Left = 246
      Top = 34
      Width = 160
      Height = 25
      Caption = 'Открыть в редакторе'
      TabOrder = 2
      OnClick = btnOpenClick
    end
  end
  object pnlInfo: TPanel
    Left = 0
    Top = 271
    Width = 772
    Height = 163
    Align = alClient
    BevelOuter = bvNone
    Caption = ''
    TabOrder = 2
    object lblHead: TLabel
      Left = 0
      Top = 0
      Width = 772
      Height = 20
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
      Left = 0
      Top = 20
      Width = 772
      Height = 143
      Hint = 'Двойной щелчок - строка в редакторе'
      Align = alClient
      ItemHeight = 13
      TabOrder = 0
      OnDblClick = lstErrorsDblClick
    end
  end
end
