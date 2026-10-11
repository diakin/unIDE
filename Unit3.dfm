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
    Height = 248
    Caption = 'Выбор директории для поиска'
    object DirectoryListBox1: TDirectoryListBox
      Left = 2
      Top = 8
      Width = 174
      Height = 188
      ItemHeight = 16
    end
    object BitBtn1: TBitBtn
      Left = 10
      Top = 204
      Width = 122
      Height = 25
      Caption = 'Добавить'
    end
    object BitBtn2: TBitBtn
      Left = 148
      Top = 204
      Width = 116
      Height = 25
      Caption = 'Удалить из списка'
    end
    object CheckListBox1: TCheckListBox
      Left = 184
      Top = 8
      Width = 188
      Height = 188
      ItemHeight = 16
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
end
