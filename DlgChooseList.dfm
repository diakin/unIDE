object DlgChooseList: TDlgChooseList
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Выбор'
  ClientHeight = 260
  ClientWidth = 380
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
  object lblPrompt: TLabel
    Left = 12
    Top = 12
    Width = 356
    Height = 20
    AutoSize = False
    Caption = 'Выберите строку'
    WordWrap = True
  end
  object lstItems: TUiListBox
    Left = 12
    Top = 38
    Width = 356
    Height = 172
    TabOrder = 0
  end
  object btnOk: TUiButton
    Left = 188
    Top = 220
    Width = 84
    Height = 26
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object btnCancel: TUiButton
    Left = 280
    Top = 220
    Width = 84
    Height = 26
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
end
