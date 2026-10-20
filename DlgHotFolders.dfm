object DlgHotFolders: TDlgHotFolders
  Left = 416
  Top = 251
  Caption = 'Directory Tree - папки для поиска потерянных файлов'
  ClientHeight = 450
  ClientWidth = 640
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object pnlBottom: TPanel
    Left = 0
    Top = 412
    Width = 640
    Height = 38
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    object btnOk: TUiButton
      Left = 442
      Top = 7
      Width = 90
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'OK'
      Default = True
      ModalResult = 1
      TabOrder = 1
    end
    object btnCancel: TUiButton
      Left = 540
      Top = 7
      Width = 90
      Height = 25
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Отмена'
      ModalResult = 2
      TabOrder = 0
    end
  end
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 640
    Height = 38
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 1
    object btnAdd: TUiButton
      Left = 10
      Top = 7
      Width = 130
      Height = 25
      Caption = 'Добавить в список'
      TabOrder = 0
    end
    object btnDel: TUiButton
      Left = 148
      Top = 7
      Width = 130
      Height = 25
      Caption = 'Удалить из списка'
      TabOrder = 1
    end
    object lblNote: TLabel
      Left = 290
      Top = 13
      Width = 340
      Height = 13
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      ParentShowHint = False
      ShowHint = True
    end
  end
  object pnlPath: TPanel
    Left = 0
    Top = 38
    Width = 640
    Height = 21
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 2
    object edPath: TUiEdit
      Left = 0
      Top = 0
      Width = 640
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
    end
  end
  object tvFolders: TUiTreeView
    Left = 0
    Top = 58
    Width = 310
    Height = 354
    Align = alLeft
    HideSelection = False
    ReadOnly = True
    TabOrder = 3
  end
  object splFolders: TSplitter
    Left = 310
    Top = 58
    Width = 4
    Height = 354
  end
  object lstFolders: TCheckListBox
    Left = 314
    Top = 58
    Width = 326
    Height = 354
    Align = alClient
    TabOrder = 4
  end
end
