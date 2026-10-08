object DlgTidyIni: TDlgTidyIni
  Left = 0
  Top = 0
  Caption = 'Tidy editor.ini'
  ClientHeight = 560
  ClientWidth = 900
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
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 76
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblInfo: TLabel
      Left = 8
      Top = 6
      Width = 884
      Height = 66
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = 
        'Scan: в выбранной папке и подпапках ищутся editor*.ini и ' +
        '*.prj; проекты, которых в editor.ini нет и у которых есть ' +
        'папка и главный файл, показываются справа, Add to editor.ini ' +
        'переносит отмеченные. Tidy and restart: проект и файлы ' +
        'сохраняются, editor.ini разбирается (editorNew.ini - этот ' +
        'компьютер, editorN.ini - другие, editorOLD.ini - записи с ' +
        'путями, которых нет), unIDE перезапускается; прежний ' +
        'editor.ini остаётся как editor_prev.ini.'
      WordWrap = True
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 516
    Width = 900
    Height = 44
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 3
    object btnAdd: TUiButton
      Left = 8
      Top = 9
      Width = 160
      Height = 26
      Caption = 'Add to editor.ini'
      TabOrder = 0
    end
    object btnTidy: TUiButton
      Left = 648
      Top = 9
      Width = 150
      Height = 26
      Anchors = [akTop, akRight]
      Caption = 'Tidy and restart'
      ModalResult = 1
      TabOrder = 1
    end
    object btnClose: TUiButton
      Left = 808
      Top = 9
      Width = 84
      Height = 26
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Close'
      ModalResult = 2
      TabOrder = 2
    end
  end
  object pnlDirs: TPanel
    Left = 0
    Top = 76
    Width = 320
    Height = 440
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 1
    object pnlDrive: TPanel
      Left = 0
      Top = 0
      Width = 320
      Height = 24
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      object cmbDrive: TDriveComboBox
        Left = 0
        Top = 0
        Width = 320
        Height = 22
        Anchors = [akLeft, akTop, akRight]
        DirList = lstDirs
        TabOrder = 0
      end
    end
    object lstDirs: TDirectoryListBox
      Left = 0
      Top = 24
      Width = 320
      Height = 348
      Align = alClient
      ItemHeight = 16
      TabOrder = 1
    end
    object pnlScan: TPanel
      Left = 0
      Top = 372
      Width = 320
      Height = 68
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 2
      object edPath: TUiEdit
        Left = 0
        Top = 6
        Width = 320
        Height = 24
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 0
      end
      object btnScan: TUiButton
        Left = 0
        Top = 36
        Width = 100
        Height = 26
        Caption = 'Scan'
        Default = True
        TabOrder = 1
      end
    end
  end
  object splDirs: TSplitter
    Left = 320
    Top = 76
    Width = 4
    Height = 440
  end
  object pnlFound: TPanel
    Left = 324
    Top = 76
    Width = 576
    Height = 440
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object lblFound: TLabel
      Left = 0
      Top = 0
      Width = 576
      Height = 20
      Align = alTop
      AutoSize = False
      Caption = '  Найденные проекты (отмеченные переносятся в editor.ini)'
      Layout = tlCenter
    end
    object lstFound: TCheckListBox
      Left = 0
      Top = 20
      Width = 576
      Height = 352
      Align = alClient
      ItemHeight = 16
      TabOrder = 0
    end
    object pnlFoundBtns: TPanel
      Left = 0
      Top = 372
      Width = 576
      Height = 68
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 1
      object btnMark: TUiButton
        Tag = 1
        Left = 0
        Top = 6
        Width = 120
        Height = 26
        Caption = 'Отметить все'
        TabOrder = 0
      end
      object btnUnmark: TUiButton
        Left = 128
        Top = 6
        Width = 120
        Height = 26
        Caption = 'Снять все'
        TabOrder = 1
      end
      object lblScan: TLabel
        Left = 0
        Top = 36
        Width = 570
        Height = 32
        Anchors = [akLeft, akTop, akRight]
        AutoSize = False
        WordWrap = True
      end
    end
  end
end
