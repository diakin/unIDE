object DlgWatch: TDlgWatch
  Left = 0
  Top = 0
  Caption = 'Watch List'
  ClientHeight = 260
  ClientWidth = 560
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesigned
  PixelsPerInch = 96
  TextHeight = 16
  object lblWhere: TLabel
    Left = 0
    Top = 240
    Width = 560
    Height = 20
    Align = alBottom
    AutoSize = False
    Layout = tlCenter
  end
  object lvWatch: TUiListView
    Left = 0
    Top = 0
    Width = 560
    Height = 240
    Align = alClient
    Columns = <
      item
        Caption = 'Выражение'
        Width = 140
      end
      item
        Caption = 'Значение'
        Width = 230
      end
      item
        Caption = 'Условие'
        Width = 80
      end
      item
        Caption = 'Тип'
        Width = 90
      end>
    GridLines = True
    HideSelection = False
    PopupMenu = pmWatch
    ReadOnly = True
    RowSelect = True
    TabOrder = 0
    ViewStyle = vsReport
  end
  object pmWatch: TUiPopupMenu
    Left = 40
    Top = 72
    object miWatchAdd: TMenuItem
      Caption = 'Добавить...'#9'Ins'
    end
    object miWatchEdit: TMenuItem
      Caption = 'Изменить...'#9'Enter'
    end
    object miWatchCond: TMenuItem
      Caption = 'Условие...'
    end
    object miWatchDelete: TMenuItem
      Caption = 'Удалить'#9'Del'
    end
    object miWatchDeleteAll: TMenuItem
      Caption = 'Удалить все'
    end
    object miWatchSep: TMenuItem
      Caption = '-'
    end
    object miWatchLocals: TMenuItem
      Caption = 'Добавить переменные процедуры'
    end
  end
end
