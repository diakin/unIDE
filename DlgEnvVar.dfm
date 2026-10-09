object DlgEnvVar: TDlgEnvVar
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Variable'
  ClientHeight = 128
  ClientWidth = 460
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poOwnerFormCenter
  PixelsPerInch = 96
  TextHeight = 13
  object lblName: TLabel
    Left = 12
    Top = 16
    Width = 100
    Height = 16
    AutoSize = False
    Caption = 'Variable Name:'
  end
  object lblValue: TLabel
    Left = 12
    Top = 50
    Width = 100
    Height = 16
    AutoSize = False
    Caption = 'Variable Value:'
  end
  object edName: TUiEdit
    Left = 120
    Top = 12
    Width = 328
    Height = 21
    TabOrder = 0
  end
  object edValue: TUiEdit
    Left = 120
    Top = 46
    Width = 328
    Height = 21
    TabOrder = 1
  end
  object btnOk: TUiButton
    Left = 262
    Top = 88
    Width = 90
    Height = 28
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 2
  end
  object btnCancel: TUiButton
    Left = 358
    Top = 88
    Width = 90
    Height = 28
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
  end
end
