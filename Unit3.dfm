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
    Height = 512
    ItemHeight = 16
    TabOrder = 1
  end
  object lblCount: TLabel
    Left = 392
    Top = 560
    Width = 304
    Height = 13
    AutoSize = False
  end
end
