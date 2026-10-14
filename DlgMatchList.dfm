object DlgMatchList: TDlgMatchList
  Left = 0
  Top = 0
  Caption = 'Match list'
  ClientHeight = 400
  ClientWidth = 413
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object grdMatches: TStringGrid
    Left = 0
    Top = 0
    Width = 413
    Height = 374
    Align = alClient
    ColCount = 3
    DefaultDrawing = False
    DefaultRowHeight = 18
    FixedCols = 0
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect, goThumbTracking]
    TabOrder = 0
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 374
    Width = 413
    Height = 26
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object chkDisableRem: TUiCheckBox
      Left = 6
      Top = 4
      Width = 160
      Hint = 'Не показывать строки-комментарии'
      Caption = 'Disable comments'
      ShowHint = True
      TabOrder = 0
    end
  end
end
