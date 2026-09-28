object DlgPickFolder: TDlgPickFolder
  Left = 0
  Top = 0
  Caption = 'Выбор папки'
  ClientHeight = 520
  ClientWidth = 760
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
  object pnlBottom: TPanel
    Left = 0
    Top = 448
    Width = 760
    Height = 72
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    object lblPath: TLabel
      Left = 8
      Top = 8
      Width = 94
      Height = 16
      Caption = 'Путь к проекту'
    end
    object edPath: TUiEdit
      Left = 8
      Top = 26
      Width = 562
      Height = 24
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
    end
    object btnOk: TUiButton
      Left = 578
      Top = 26
      Width = 84
      Height = 26
      Anchors = [akTop, akRight]
      Caption = 'OK'
      Default = True
      TabOrder = 2
    end
    object btnCancel: TUiButton
      Left = 668
      Top = 26
      Width = 84
      Height = 26
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
    end
  end
  object pnlDrive: TPanel
    Left = 0
    Top = 0
    Width = 760
    Height = 24
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object cmbDrive: TDriveComboBox
      Left = 0
      Top = 0
      Width = 760
      Anchors = [akLeft, akTop, akRight]
      DirList = lstDirs
      TabOrder = 0
    end
  end
  object lstDirs: TDirectoryListBox
    Left = 0
    Top = 22
    Width = 320
    Height = 426
    Align = alLeft
    FileList = lstFiles
    TabOrder = 2
  end
  object splDirs: TSplitter
    Left = 320
    Top = 22
    Width = 4
    Height = 426
  end
  object lstFiles: TFileListBox
    Left = 324
    Top = 22
    Width = 436
    Height = 426
    Align = alClient
    TabOrder = 3
  end
end
