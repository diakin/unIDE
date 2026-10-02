object DlgIconEdit: TDlgIconEdit
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Palette Icons'
  ClientHeight = 468
  ClientWidth = 760
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lblScript: TLabel
    Left = 208
    Top = 10
    Width = 320
    Height = 13
    AutoSize = False
    Caption = 'Скрипт значка: команда на строку'
  end
  object pbPreview: TPaintBox
    Left = 538
    Top = 28
    Width = 214
    Height = 248
    OnMouseMove = pbPreviewMouseMove
    OnPaint = pbPreviewPaint
  end
  object lblState: TLabel
    Left = 208
    Top = 284
    Width = 320
    Height = 13
    AutoSize = False
  end
  object lblCoords: TLabel
    Left = 538
    Top = 284
    Width = 214
    Height = 13
    AutoSize = False
  end
  object lblHelp: TLabel
    Left = 208
    Top = 306
    Width = 544
    Height = 112
    AutoSize = False
    WordWrap = True
  end
  object lstIcons: TUiListBox
    Left = 8
    Top = 8
    Width = 190
    Height = 452
    ItemHeight = 13
    TabOrder = 0
    OnClick = lstIconsClick
  end
  object memScript: TUiMemo
    Left = 208
    Top = 28
    Width = 320
    Height = 248
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 1
    WordWrap = False
    OnChange = memScriptChange
  end
  object btnColor: TUiButton
    Left = 208
    Top = 430
    Width = 90
    Height = 26
    Caption = 'Цвет...'
    TabOrder = 2
    OnClick = btnColorClick
  end
  object btnThemeInk: TUiButton
    Left = 304
    Top = 430
    Width = 110
    Height = 26
    Caption = 'Цвет темы (@)'
    TabOrder = 3
    OnClick = btnThemeInkClick
  end
  object btnBuiltin: TUiButton
    Left = 420
    Top = 430
    Width = 100
    Height = 26
    Caption = 'Встроенный'
    TabOrder = 4
    OnClick = btnBuiltinClick
  end
  object btnApply: TUiButton
    Left = 560
    Top = 430
    Width = 90
    Height = 26
    Caption = 'Применить'
    TabOrder = 5
    OnClick = btnApplyClick
  end
  object btnClose: TUiButton
    Left = 656
    Top = 430
    Width = 96
    Height = 26
    Cancel = True
    Caption = 'Закрыть'
    ModalResult = 2
    TabOrder = 6
  end
end
