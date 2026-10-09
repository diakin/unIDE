object DlgPathList: TDlgPathList
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Пути'
  ClientHeight = 356
  ClientWidth = 560
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
  object lblState: TLabel
    Left = 8
    Top = 220
    Width = 544
    Height = 16
    AutoSize = False
  end
  object lstPaths: TUiListBox
    Left = 8
    Top = 8
    Width = 544
    Height = 206
    ItemHeight = 13
    TabOrder = 0
    OnClick = lstPathsClick
  end
  object edPath: TUiEdit
    Left = 8
    Top = 242
    Width = 506
    Height = 21
    TabOrder = 1
  end
  object btnBrowse: TUiButton
    Left = 518
    Top = 241
    Width = 34
    Height = 25
    Caption = '...'
    TabOrder = 2
    OnClick = btnBrowseClick
  end
  object btnReplace: TUiButton
    Left = 8
    Top = 272
    Width = 80
    Height = 25
    Caption = 'Replace'
    TabOrder = 3
    OnClick = btnReplaceClick
  end
  object btnAdd: TUiButton
    Left = 92
    Top = 272
    Width = 80
    Height = 25
    Caption = 'Add'
    TabOrder = 4
    OnClick = btnAddClick
  end
  object btnDelete: TUiButton
    Left = 176
    Top = 272
    Width = 80
    Height = 25
    Caption = 'Delete'
    TabOrder = 5
    OnClick = btnDeleteClick
  end
  object btnDelInvalid: TUiButton
    Left = 260
    Top = 272
    Width = 110
    Height = 25
    Caption = 'Delete invalid'
    TabOrder = 6
    OnClick = btnDelInvalidClick
  end
  object btnUp: TUiButton
    Left = 412
    Top = 272
    Width = 68
    Height = 25
    Caption = 'Up'
    TabOrder = 7
    OnClick = btnUpClick
  end
  object btnDown: TUiButton
    Left = 484
    Top = 272
    Width = 68
    Height = 25
    Caption = 'Down'
    TabOrder = 8
    OnClick = btnDownClick
  end
  object btnOk: TUiButton
    Left = 388
    Top = 318
    Width = 80
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 9
  end
  object btnCancel: TUiButton
    Left = 472
    Top = 318
    Width = 80
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 10
  end
end
