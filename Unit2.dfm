object Form2: TForm2
  Left = 499
  Top = 269
  Caption = 'IDE Options'
  ClientHeight = 568
  ClientWidth = 620
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnClose = Form2Close
  OnCloseQuery = Form2CloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = Form2ResizeOrShow
  OnShow = Form2ResizeOrShow
  PixelsPerInch = 96
  TextHeight = 13
  object pcOptions: TUiPageControl
    Left = 0
    Top = 0
    Width = 620
    Height = 568
    ActivePage = tsColorScheme
    Align = alClient
    MultiLine = True
    TabOrder = 0
    OnChange = OptionsPageChange
    object tsColorScheme: TTabSheet
      Caption = 'Color Scheme'
      object pnlTheme: TPanel
        Left = 0
        Top = 0
        Width = 612
        Height = 58
        BevelOuter = bvNone
        TabOrder = 0
        Align = alTop
        object lblTheme: TPanel
          Left = 10
          Top = 5
          Width = 80
          Height = 21
          BevelOuter = bvNone
          Caption = 'Color Schem'
          Color = clBtnFace
          ParentBackground = False
          TabOrder = 0
        end
        object cmbTheme: TUiComboBox
          Left = 90
          Top = 5
          Width = 140
          Height = 21
          ItemHeight = 13
          TabOrder = 1
          Color = clWindow
          ParentShowHint = False
          ShowHint = True
          Hint = 'Тема. Имя новой - ввести здесь и нажать Add или Enter'
          OnChange = cmbThemeChange
          OnKeyPress = cmbThemeKeyPress
        end
        object btnThemeAdd: TUiButton
          Left = 234
          Top = 4
          Width = 40
          Height = 23
          Caption = 'Add'
          TabOrder = 2
          OnClick = btnThemeAddClick
        end
        object btnThemeDel: TUiButton
          Left = 276
          Top = 4
          Width = 50
          Height = 23
          Caption = 'Delete'
          TabOrder = 3
          OnClick = btnThemeDelClick
        end
        object pnlThemeSpacer: TPanel
          Left = 326
          Top = 4
          Width = 16
          Height = 23
          BevelOuter = bvNone
          TabOrder = 4
        end
        object rbIdeLight: TUiRadioButton
          Left = 10
          Top = 35
          Width = 75
          Height = 17
          Caption = 'IDE Light'
          TabOrder = 5
          TextColor = clRed
          OnClick = rbIdeModeClick
        end
        object rbIdeDark: TUiRadioButton
          Left = 91
          Top = 35
          Width = 75
          Height = 17
          Caption = 'IDE Dark'
          TabOrder = 6
          TextColor = clBlue
          OnClick = rbIdeModeClick
        end
        object rbIdeCustom: TUiRadioButton
          Left = 172
          Top = 35
          Width = 62
          Height = 17
          Caption = 'Custom'
          TabOrder = 7
          OnClick = rbIdeModeClick
        end
        object cmbIdeCustom: TUiComboBox
          Left = 236
          Top = 33
          Width = 140
          Height = 21
          ItemHeight = 13
          TabOrder = 8
          ParentShowHint = False
          ShowHint = True
          Hint = 'Своя тема IDE. Имя новой - ввести здесь и нажать Add'
          OnChange = cmbIdeCustomChange
        end
        object btnIdeCustomAdd: TUiButton
          Left = 380
          Top = 32
          Width = 40
          Height = 23
          Caption = 'Add'
          TabOrder = 9
          ParentShowHint = False
          ShowHint = True
          Hint = 'Новая своя тема IDE - копия цветов текущего режима'
          OnClick = btnIdeCustomAddClick
        end
        object btnIdeCustomDel: TUiButton
          Left = 422
          Top = 32
          Width = 40
          Height = 23
          Caption = 'Del'
          TabOrder = 10
          ParentShowHint = False
          ShowHint = True
          Hint = 'Удалить выбранную свою тему IDE'
          OnClick = btnIdeCustomDelClick
        end
      end
      object pnlGroupActions: TPanel
        Left = 0
        Top = 58
        Width = 612
        Height = 72
        BevelOuter = bvNone
        TabOrder = 1
        Align = alTop
        object cmbGroupType: TUiComboBox
          Left = 10
          Top = 8
          Width = 110
          Height = 24
          Style = csDropDownList
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          ItemHeight = 16
          TabOrder = 0
          OnChange = cmbGroupTypeChange
          Items.Strings = (
            'Keywords'
            'Operators'
            'Line comment'
            'Block comment'
            'String'
            'Brackets'
            'Line Mark')
        end
        object btnAddGroup: TUiButton
          Left = 126
          Top = 7
          Width = 80
          Height = 26
          Caption = 'Add Group'
          TabOrder = 1
          OnClick = btnAddGroupClick
        end
        object btnDeleteGroup: TUiButton
          Left = 212
          Top = 7
          Width = 90
          Height = 26
          Caption = 'Delete Group'
          TabOrder = 2
          OnClick = btnDeleteGroupClick
        end
        object btnRestoreDefaults: TUiButton
          Left = 308
          Top = 7
          Width = 105
          Height = 26
          Caption = 'Restore Defaults'
          TabOrder = 3
          OnClick = btnRestoreDefaultsClick
        end
        object btnEditDefault: TUiButton
          Left = 419
          Top = 7
          Width = 95
          Height = 26
          Caption = 'Edit Default'
          TabOrder = 4
          OnClick = btnEditDefaultClick
        end
        object btnOpenClr: TUiButton
          Left = 10
          Top = 39
          Width = 100
          Height = 26
          Caption = 'Open clr file'
          TabOrder = 5
          ParentShowHint = False
          ShowHint = True
          Hint = 'Открыть файл текущей схемы в редакторе'
          OnClick = btnOpenClrClick
        end
        object btnSelectSchema: TUiButton
          Left = 116
          Top = 39
          Width = 110
          Height = 26
          Caption = 'Select scheme'
          TabOrder = 6
          ParentShowHint = False
          ShowHint = True
          Hint = 'Взять данные другой схемы за основу; Save запишет их в схему текущего расширения'
          OnClick = btnSelectSchemaClick
        end
      end
      object pnlBottom: TPanel
        Left = 0
        Top = 472
        Width = 612
        Height = 42
        BevelOuter = bvNone
        TabOrder = 2
        Align = alBottom
        object btnOK: TUiButton
          Left = 10
          Top = 7
          Width = 80
          Height = 28
          Caption = 'Save'
          TabOrder = 0
          OnClick = ButtonClick1
        end
        object btnCancel: TUiButton
          Left = 100
          Top = 7
          Width = 80
          Height = 28
          Caption = 'Exit'
          TabOrder = 1
          OnClick = ButtonClick1
        end
      end
      object MemoSchemaDetails: TUiMemo
        Left = 0
        Top = 372
        Width = 612
        Height = 100
        Align = alBottom
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Courier New'
        Font.Style = []
        ParentFont = False
        ScrollBars = ssVertical
        TabOrder = 3
        OnChange = MemoSchemaDetailsChange
      end
      object Grid: TStringGrid
        Left = 0
        Top = 130
        Width = 612
        Height = 242
        Align = alClient
        ColCount = 4
        DefaultRowHeight = 22
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goDrawFocusSelected]
        TabOrder = 4
        OnDblClick = GridDblClick
        OnDrawCell = GridDrawCell
        OnSelectCell = GridSelectCell
        OnTopLeftChanged = GridTopLeftChanged
        object btnBaseColors: TUiButton
          Left = 4
          Top = 4
          Width = 70
          Height = 18
          Caption = 'Base colors'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -9
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          ParentShowHint = False
          ShowHint = True
          Hint = 'Цвета текста - из настроек редактора (Editor Options)'
          TabOrder = 0
          TabStop = False
          Visible = False
          OnClick = btnBaseColorsClick
        end
      end
    end
    object tsEdOptions: TTabSheet
      Caption = 'Editor Options'
      object grpEditorOptions: TUiGroupBox
        Left = 0
        Top = 0
        Width = 612
        Height = 40
        Caption = ' Editor options '
        TabOrder = 0
        Align = alTop
        object chkUseHighlight: TUiCheckBox
          Left = 5
          Top = 16
          Width = 105
          Height = 17
          Caption = 'Syntax HiLight'
          TabOrder = 0
          Checked = True
          OnClick = chkUseHighlightClick
        end
        object chkShowSpaces: TUiCheckBox
          Left = 110
          Top = 16
          Width = 90
          Height = 17
          Caption = 'Show spaces'
          TabOrder = 1
          ParentShowHint = False
          ShowHint = True
          Hint = 'Показывать пробелы и табуляции знаками'
          OnClick = chkShowSpacesClick
        end
        object lblTabWidth: TLabel
          Left = 292
          Top = 18
          Caption = 'Tab'
        end
        object cmbTabWidth: TUiComboBox
          Left = 318
          Top = 14
          Width = 45
          Height = 21
          Style = csDropDownList
          ItemHeight = 13
          TabOrder = 2
          OnChange = cmbTabWidthChange
          Items.Strings = (
            '2'
            '3'
            '4'
            '6'
            '8')
        end
        object chkShowLineNumbers: TUiCheckBox
          Left = 373
          Top = 16
          Width = 125
          Height = 17
          Caption = 'Show line numbers'
          TabOrder = 3
          Checked = True
          OnClick = chkShowLineNumbersClick
        end
        object btnFontChange: TUiButton
          Left = 505
          Top = 11
          Width = 90
          Height = 24
          Caption = 'Font Change'
          TabOrder = 4
          OnClick = btnFontChangeClick
        end
      end
      object grpIndent: TUiGroupBox
        Left = 0
        Top = 40
        Width = 612
        Height = 40
        Caption = ' Indent hilight '
        TabOrder = 1
        Align = alTop
        object lblIndent: TLabel
          Left = 6
          Top = 18
          Caption = 'Indent'
        end
        object cmbIndentKind: TUiComboBox
          Left = 46
          Top = 14
          Width = 62
          Height = 21
          Style = csDropDownList
          ItemHeight = 13
          TabOrder = 0
          ParentShowHint = False
          ShowHint = True
          Hint = 'Чем Format text делает отступы; none - не делать вовсе'
          OnChange = cmbIndentKindChange
          Items.Strings = (
            'spaces'
            'tab'
            'none')
        end
        object cmbIndentSize: TUiComboBox
          Left = 112
          Top = 14
          Width = 45
          Height = 21
          Style = csDropDownList
          ItemHeight = 13
          TabOrder = 1
          ParentShowHint = False
          ShowHint = True
          Hint = 'Символов в одном уровне отступа'
          OnChange = cmbIndentSizeChange
          Items.Strings = (
            '1'
            '2'
            '3'
            '4'
            '6'
            '8')
        end
        object chkHotTabHighlight: TUiCheckBox
          Left = 173
          Top = 16
          Width = 60
          Height = 17
          Caption = 'HiLight'
          TabOrder = 2
          OnClick = chkHotTabHighlightClick
        end
        object edtPale: TUiEdit
          Left = 241
          Top = 14
          Width = 32
          Height = 21
          TabOrder = 3
          ParentShowHint = False
          ShowHint = True
          Hint = 'Бледность полос отступа, %'
          Text = '50'
          OnChange = edtPaleChange
        end
        object udPale: TUiUpDown
          Left = 273
          Top = 14
          Width = 16
          Height = 21
          Associate = edtPale
          Max = 100
          Increment = 5
          Position = 50
          TabOrder = 4
        end
      end
      object lblIndentHint: TLabel
        Left = 0
        Top = 484
        Width = 612
        Height = 30
        Align = alBottom
        Alignment = taCenter
        AutoSize = False
        Caption = 'Настройки отступа применятся к тексту только после Format text'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clRed
        Font.Height = -21
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        Layout = tlCenter
        Visible = False
      end
      object grpEditorColors: TUiGroupBox
        Left = 0
        Top = 80
        Width = 612
        Height = 40
        Caption = ' Editor colors '
        TabOrder = 2
        Align = alTop
        object lblEditorColor: TLabel
          Left = 6
          Top = 18
          Caption = 'Editor color'
        end
        object pnlEditorFG: TPanel
          Left = 0
          Top = 13
          Width = 24
          Height = 20
          Cursor = crHandPoint
          ParentShowHint = False
          ShowHint = True
          Hint = 'Цвет текста (FontColor в editor.ini); раздел Text схемы его перекрывает'
          BevelOuter = bvLowered
          Caption = 'FG'
          ParentBackground = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 0
          OnClick = ColorSwatchClick
        end
        object pnlEditorBG: TPanel
          Left = 0
          Top = 13
          Width = 24
          Height = 20
          Cursor = crHandPoint
          ParentShowHint = False
          ShowHint = True
          Hint = 'Фон редактора (BGColor в editor.ini)'
          BevelOuter = bvLowered
          Caption = 'BG'
          ParentBackground = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 1
          OnClick = ColorSwatchClick
        end
        object lblGutterColor: TLabel
          Left = 140
          Top = 18
          Caption = 'Gutter color'
        end
        object pnlGutterFG: TPanel
          Left = 0
          Top = 13
          Width = 24
          Height = 20
          Cursor = crHandPoint
          ParentShowHint = False
          ShowHint = True
          Hint = 'Цвет номеров строк (GutterFG в editor.ini)'
          BevelOuter = bvLowered
          Caption = 'FG'
          ParentBackground = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 2
          OnClick = ColorSwatchClick
        end
        object pnlGutterBG: TPanel
          Left = 0
          Top = 13
          Width = 24
          Height = 20
          Cursor = crHandPoint
          ParentShowHint = False
          ShowHint = True
          Hint = 'Фон панели номеров строк (GutterBG в editor.ini)'
          BevelOuter = bvLowered
          Caption = 'BG'
          ParentBackground = False
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 3
          OnClick = ColorSwatchClick
        end
      end
      object grpEdMargin: TUiGroupBox
        Left = 0
        Top = 120
        Width = 612
        Height = 72
        Caption = ' Margin and gutter '
        TabOrder = 3
        Align = alTop
        object chkEdRightMargin: TUiCheckBox
          Left = 8
          Top = 18
          Width = 140
          Height = 20
          Caption = 'Visible right margin'
          TabOrder = 0
          OnClick = EdOptionClick
        end
        object lblEdRightMargin: TLabel
          Left = 152
          Top = 21
          Caption = 'Right margin:'
        end
        object cmbEdRightMargin: TUiComboBox
          Left = 228
          Top = 16
          Width = 56
          Height = 21
          ItemHeight = 13
          TabOrder = 1
          ParentShowHint = False
          ShowHint = True
          Hint = 'Столбец линии правого поля (можно ввести число)'
          OnChange = EdOptionClick
          Items.Strings = (
            '40'
            '60'
            '72'
            '80'
            '100'
            '120'
            '132'
            '200')
        end
        object chkEdGutter: TUiCheckBox
          Left = 298
          Top = 18
          Width = 110
          Height = 20
          Caption = 'Visible gutter'
          TabOrder = 2
          ParentShowHint = False
          ShowHint = True
          Hint = 'Полоса слева от текста: номера строк, закладки, точки останова'
          OnClick = EdOptionClick
        end
        object lblEdGutterWidth: TLabel
          Left = 412
          Top = 21
          Caption = 'Gutter width:'
        end
        object cmbEdGutterWidth: TUiComboBox
          Left = 486
          Top = 16
          Width = 64
          Height = 21
          ItemHeight = 13
          TabOrder = 3
          ParentShowHint = False
          ShowHint = True
          Hint = 'Ширина полосы в точках; Auto - по числу цифр номеров строк'
          OnChange = EdOptionClick
          Items.Strings = (
            'Auto'
            '20'
            '30'
            '40'
            '50'
            '60'
            '80')
        end
        object lblEdTextIndent: TLabel
          Left = 8
          Top = 45
          Caption = 'Text indent:'
        end
        object cmbEdTextIndent: TUiComboBox
          Left = 82
          Top = 40
          Width = 56
          Height = 21
          ItemHeight = 13
          TabOrder = 4
          ParentShowHint = False
          ShowHint = True
          Hint = 'Отступ текста от полосы номеров слева, в точках (0 - без отступа)'
          OnChange = EdOptionClick
          Items.Strings = (
            '0'
            '2'
            '3'
            '5'
            '8'
            '10'
            '15')
        end
      end
      object grpEdInsight: TUiGroupBox
        Left = 0
        Top = 168
        Width = 612
        Height = 226
        Caption = ' Code Insight '
        TabOrder = 4
        Align = alTop
        object chkEdCompletion: TUiCheckBox
          Left = 8
          Top = 18
          Width = 200
          Height = 20
          Caption = 'Code completion'
          TabOrder = 0
          ParentShowHint = False
          ShowHint = True
          Hint = 'Список имён после точки (с задержкой); Ctrl+Space - всегда'
          OnClick = EdOptionClick
        end
        object chkEdParams: TUiCheckBox
          Left = 8
          Top = 40
          Width = 200
          Height = 20
          Caption = 'Code parameters'
          TabOrder = 1
          ParentShowHint = False
          ShowHint = True
          Hint = 'Параметры подпрограммы после "(" (с задержкой); Ctrl+Shift+Space - всегда'
          OnClick = EdOptionClick
        end
        object chkEdTipEval: TUiCheckBox
          Left = 212
          Top = 18
          Width = 220
          Height = 20
          Caption = 'Tooltip expression evaluation'
          TabOrder = 2
          ParentShowHint = False
          ShowHint = True
          Hint = 'Значение под мышью, пока программа стоит в отладчике'
          OnClick = EdOptionClick
        end
        object chkEdTipSymbol: TUiCheckBox
          Left = 212
          Top = 40
          Width = 220
          Height = 20
          Caption = 'Tooltip symbol insight'
          TabOrder = 3
          ParentShowHint = False
          ShowHint = True
          Hint = 'Объявление имени под мышью (Pascal)'
          OnClick = EdOptionClick
        end
        object lblEdDelay: TLabel
          Left = 446
          Top = 21
          Caption = 'Delay:'
        end
        object cmbEdDelay: TUiComboBox
          Left = 486
          Top = 16
          Width = 80
          Height = 21
          Style = csDropDownList
          ItemHeight = 13
          TabOrder = 4
          OnChange = EdOptionClick
        end
        object lblEdInsightColors: TLabel
          Left = 8
          Top = 68
          Caption = 'CodeInsight Colors'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object btnEdDefaultColors: TUiButton
          Left = 446
          Top = 194
          Width = 120
          Height = 24
          Caption = 'Default colors'
          TabOrder = 5
          ParentShowHint = False
          ShowHint = True
          Hint = 'Цвета по умолчанию; фон - как у редактора'
          OnClick = EdDefaultColorsClick
        end
      end
    end
    object tsIdeColors: TTabSheet
      Caption = 'IDE colors and Fonts'
      object pnlUiBottom: TPanel
        Left = 0
        Top = 480
        Width = 612
        Height = 34
        BevelOuter = bvNone
        TabOrder = 0
        Align = alBottom
        object btnUiDefaults: TUiButton
          Left = 6
          Top = 4
          Width = 140
          Height = 25
          Caption = 'Вернуть умолчания'
          TabOrder = 0
          OnClick = btnUiDefaultsClick
        end
        object lblUiHint: TLabel
          Left = 156
          Top = 9
          Caption = 'Двойной щелчок - выбор цвета или шрифта. Цвета - в IDE.clr, шрифты - в editor.ini, сразу.'
        end
      end
      object UiGrid: TStringGrid
        Left = 0
        Top = 0
        Width = 612
        Height = 480
        Align = alClient
        ColCount = 2
        DefaultRowHeight = 20
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRowSelect]
        TabOrder = 1
        OnDblClick = UiGridDblClick
        OnDrawCell = UiGridDrawCell
        ColWidths = (
          300
          200)
      end
    end
    object tsCompilers: TTabSheet
      Caption = 'Compilers'
      object lstCompTypes: TUiListBox
        Left = 0
        Top = 0
        Width = 130
        Height = 514
        Align = alLeft
        ItemHeight = 13
        Items.Strings = (
          'RapidQ Basic'
          'Delphi'
          'FreeBASIC'
          'Visual Basic'
          'Arduino'
          'C project'
          'CPP project'
          'WebSite')
        TabOrder = 0
        OnClick = lstCompTypesClick
      end
      object pnlCompPage: TPanel
        Left = 130
        Top = 0
        Width = 482
        Height = 514
        BevelOuter = bvNone
        TabOrder = 1
        Align = alClient
      end
      object cbTool: TUiComboBox
        Left = 142
        Top = 8
        Width = 180
        Height = 21
        Style = csDropDownList
        ItemHeight = 13
        TabOrder = 2
        OnChange = cbToolChange
      end
      object btnToolAdd: TUiButton
        Left = 328
        Top = 7
        Width = 60
        Height = 23
        Caption = 'Add'
        TabOrder = 3
        OnClick = btnToolAddClick
      end
      object btnToolDel: TUiButton
        Left = 394
        Top = 7
        Width = 60
        Height = 23
        Caption = 'Delete'
        TabOrder = 4
        OnClick = btnToolDelClick
      end
      object btnToolFind: TUiButton
        Left = 460
        Top = 7
        Width = 90
        Height = 23
        Caption = 'Find installed'
        TabOrder = 5
        OnClick = btnToolFindClick
      end
      object btnDelphiImport: TUiButton
        Left = 556
        Top = 7
        Width = 110
        Height = 23
        Caption = 'Взять из Delphi'
        TabOrder = 6
        ParentShowHint = False
        ShowHint = True
        Hint = 'Library path и Browsing path из Environment Options этой Delphi (реестр); свои пути остаются в конце'
        Visible = False
        OnClick = btnDelphiImportClick
      end
      object btnArdImport: TUiButton
        Left = 556
        Top = 7
        Width = 140
        Height = 23
        Caption = 'Импорт из RQdb.ini'
        TabOrder = 7
        ParentShowHint = False
        ShowHint = True
        Hint = 'Пути Arduino из RQdb.ini RQdebugger (раздел [Arduino]) и Additional URLs из AdditURLEdit.txt'
        Visible = False
        OnClick = btnArdImportClick
      end
    end
    object tsArduino: TTabSheet
      Caption = 'Arduino'
      object pcArduino: TUiPageControl
        Left = 0
        Top = 0
        Width = 612
        Height = 514
        ActivePage = tsArdSettings
        Align = alClient
        TabOrder = 0
        object tsArdSettings: TTabSheet
          Caption = 'Settings'
          object pnlArdTop: TPanel
            Left = 0
            Top = 0
            Width = 604
            Height = 406
            BevelOuter = bvNone
            TabOrder = 0
            Align = alTop
            OnResize = ArdTopResize
            object lblArdWarnings: TLabel
              Left = 8
              Top = 282
              Caption = 'Warnings'
            end
            object cbArdWarnings: TUiComboBox
              Left = 80
              Top = 278
              Width = 100
              Height = 21
              Style = csDropDownList
              ItemHeight = 13
              TabOrder = 0
              ParentShowHint = False
              ShowHint = True
              Hint = 'Уровень предупреждений gcc (--warnings)'
              OnChange = ArdOptionChange
              Items.Strings = (
                'none'
                'default'
                'more'
                'all')
            end
            object lblArdLogLevel: TLabel
              Left = 220
              Top = 282
              Caption = 'Log level'
            end
            object cbArdLogLevel: TUiComboBox
              Left = 290
              Top = 278
              Width = 100
              Height = 21
              Style = csDropDownList
              ItemHeight = 13
              TabOrder = 1
              ParentShowHint = False
              ShowHint = True
              Hint = 'Сообщения этого уровня и выше пишутся в лог (--log-level)'
              OnChange = ArdOptionChange
              Items.Strings = (
                'trace'
                'debug'
                'info'
                'warn'
                'error'
                'fatal'
                'panic')
            end
            object lblArdVerbose: TLabel
              Left = 8
              Top = 310
              Caption = 'Show verbose output during'
            end
            object chkArdCompileVerbose: TUiCheckBox
              Left = 200
              Top = 308
              Width = 110
              Height = 17
              Caption = 'Compilation'
              TabOrder = 2
              OnClick = ArdOptionChange
            end
            object chkArdUploadVerbose: TUiCheckBox
              Left = 320
              Top = 308
              Width = 90
              Height = 17
              Caption = 'Upload'
              TabOrder = 3
              OnClick = ArdOptionChange
            end
            object chkArdVerifyAfterUpload: TUiCheckBox
              Left = 8
              Top = 332
              Width = 200
              Height = 17
              Caption = 'Verify code after upload'
              TabOrder = 4
              OnClick = ArdOptionChange
            end
            object chkArdExportBinaries: TUiCheckBox
              Left = 220
              Top = 332
              Width = 190
              Height = 17
              Caption = 'Export compiled binary'
              TabOrder = 5
              ParentShowHint = False
              ShowHint = True
              Hint = 'compile -e: .hex / .bin - в папку скетча'
              OnClick = ArdOptionChange
            end
            object chkArdSaveBeforeBuild: TUiCheckBox
              Left = 8
              Top = 356
              Width = 340
              Height = 17
              Caption = 'Save sketch when verifying or uploading'
              TabOrder = 6
              OnClick = ArdOptionChange
            end
            object lblArdUrls: TLabel
              Left = 8
              Top = 384
              Caption = 'Additional Boards Manager URLs (по одному в строке; в arduino-cli уходят только адреса http(s))'
            end
          end
          object pnlArdBottom: TPanel
            Left = 0
            Top = 456
            Width = 604
            Height = 34
            BevelOuter = bvNone
            TabOrder = 1
            Align = alBottom
            object btnArdImportRq: TUiButton
              Left = 8
              Top = 5
              Width = 160
              Height = 24
              Caption = 'Импорт из RQdb.ini'
              TabOrder = 0
              ParentShowHint = False
              ShowHint = True
              Hint = 'Пути Arduino из RQdb.ini RQdebugger (раздел [Arduino]) и Additional URLs из AdditURLEdit.txt'
              OnClick = btnArdImportClick
            end
          end
          object memArdUrls: TUiMemo
            Left = 0
            Top = 406
            Width = 604
            Height = 50
            Align = alClient
            ScrollBars = ssBoth
            TabOrder = 2
            WordWrap = False
            OnChange = ArdUrlsChange
          end
        end
        object tsArdNetwork: TTabSheet
          Caption = 'Network'
          object rbArdProxyNone: TUiRadioButton
            Left = 8
            Top = 12
            Width = 300
            Height = 17
            Caption = 'No proxy'
            TabOrder = 0
            OnClick = ArdNetChange
          end
          object rbArdProxyAuto: TUiRadioButton
            Left = 8
            Top = 38
            Width = 300
            Height = 17
            Caption = 'Auto-detect proxy settings'
            TabOrder = 1
            OnClick = ArdNetChange
          end
          object chkArdProxyAutoUrl: TUiCheckBox
            Left = 30
            Top = 64
            Width = 260
            Height = 17
            Caption = 'Automatic proxy configuration URL:'
            TabOrder = 2
            OnClick = ArdNetChange
          end
          object edArdProxyAutoUrl: TUiEdit
            Left = 50
            Top = 88
            Width = 400
            Height = 21
            TabOrder = 3
            OnChange = ArdNetChange
          end
          object rbArdProxyManual: TUiRadioButton
            Left = 8
            Top = 122
            Width = 300
            Height = 17
            Caption = 'Manual proxy configuration'
            TabOrder = 4
            OnClick = ArdNetChange
          end
          object pnlArdProxyType: TPanel
            Left = 44
            Top = 148
            Width = 260
            Height = 24
            BevelOuter = bvNone
            TabOrder = 5
            object rbArdProxyHttp: TUiRadioButton
              Left = 6
              Top = 2
              Width = 80
              Height = 17
              Caption = 'HTTP'
              TabOrder = 0
              OnClick = ArdNetChange
            end
            object rbArdProxySocks: TUiRadioButton
              Left = 100
              Top = 2
              Width = 90
              Height = 17
              Caption = 'SOCKS'
              TabOrder = 1
              OnClick = ArdNetChange
            end
          end
          object lblArdProxyHost: TLabel
            Left = 50
            Top = 184
            Caption = 'Host name:'
          end
          object edArdProxyHost: TUiEdit
            Left = 180
            Top = 180
            Width = 270
            Height = 21
            TabOrder = 6
            OnChange = ArdNetChange
          end
          object lblArdProxyPort: TLabel
            Left = 50
            Top = 212
            Caption = 'Port number:'
          end
          object edArdProxyPort: TUiEdit
            Left = 180
            Top = 208
            Width = 80
            Height = 21
            TabOrder = 7
            OnChange = ArdNetChange
          end
          object lblArdProxyUser: TLabel
            Left = 50
            Top = 240
            Caption = 'Username:'
          end
          object edArdProxyUser: TUiEdit
            Left = 180
            Top = 236
            Width = 200
            Height = 21
            TabOrder = 8
            OnChange = ArdNetChange
          end
          object lblArdProxyPassword: TLabel
            Left = 50
            Top = 268
            Caption = 'Password:'
          end
          object edArdProxyPassword: TUiEdit
            Left = 180
            Top = 264
            Width = 200
            Height = 21
            TabOrder = 9
            PasswordChar = '*'
            OnChange = ArdNetChange
          end
          object lblArdNetNote: TLabel
            Left = 8
            Top = 300
            Width = 520
            Height = 48
            AutoSize = False
            Caption = 'Настройки хранятся в editor.ini ([Compiler.Arduino], пароль - открытым текстом). В arduino-cli пока не передаются.'
            WordWrap = True
          end
        end
        object tsArdCfg: TTabSheet
          Caption = 'Cli config file'
          object pnlArdCfgTop: TPanel
            Left = 0
            Top = 0
            Width = 604
            Height = 34
            BevelOuter = bvNone
            TabOrder = 0
            Align = alTop
            object btnArdCfgReload: TUiButton
              Left = 8
              Top = 5
              Width = 110
              Height = 24
              Caption = 'Перечитать'
              TabOrder = 0
              OnClick = ArdCfgLoadClick
            end
            object btnArdCfgWrite: TUiButton
              Left = 124
              Top = 5
              Width = 190
              Height = 24
              Caption = 'Записать пути в yaml'
              TabOrder = 1
              ParentShowHint = False
              ShowHint = True
              Hint = 'arduino-cli config set: directories.data = Cli Data Path, directories.downloads = Cli Downloads Path, directories.user = Sketch path. Нет файла - сначала config init'
              OnClick = ArdCfgWriteClick
            end
            object lblArdCfgState: TLabel
              Left = 324
              Top = 9
            end
          end
          object memArdCfg: TUiMemo
            Left = 0
            Top = 34
            Width = 604
            Height = 456
            Align = alClient
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -12
            Font.Name = 'Courier New'
            Font.Style = []
            ParentFont = False
            ReadOnly = True
            ScrollBars = ssBoth
            TabOrder = 1
            WordWrap = False
          end
        end
      end
    end
    object tsPrefs: TTabSheet
      Caption = 'Preferences'
      object grpPrefAutosave: TUiGroupBox
        Left = 8
        Top = 8
        Width = 290
        Height = 72
        Caption = ' Autosave options '
        TabOrder = 0
        object chkPrefAutoEditor: TUiCheckBox
          Left = 12
          Top = 20
          Width = 270
          Height = 20
          Caption = 'Editor files'
          TabOrder = 0
          ParentShowHint = False
          ShowHint = True
          Hint = 'Изменённые файлы сохраняются без вопроса перед сборкой и запуском, при смене проекта и при выходе (файлы без имени - по-прежнему с вопросом)'
          OnClick = EnvOptionClick
        end
        object chkPrefAutoDesktop: TUiCheckBox
          Left = 12
          Top = 44
          Width = 270
          Height = 20
          Caption = 'Project desktop'
          TabOrder = 1
          ParentShowHint = False
          ShowHint = True
          Hint = 'Состав проекта (окна, вкладки, закладки) сохраняется (editor.ini, раздел проекта) без вопроса при закрытии проекта и выходе'
          OnClick = EnvOptionClick
        end
      end
      object grpPrefCompiling: TUiGroupBox
        Left = 306
        Top = 8
        Width = 290
        Height = 96
        Caption = ' Compiling and running '
        TabOrder = 1
        object chkPrefProgress: TUiCheckBox
          Left = 12
          Top = 20
          Width = 270
          Height = 20
          Caption = 'Show compiler progress'
          TabOrder = 0
          ParentShowHint = False
          ShowHint = True
          Hint = 'Окно хода сборки: файл, строки, ошибки, предупреждения; при ошибках остаётся до OK'
          OnClick = EnvOptionClick
        end
        object chkPrefMinimize: TUiCheckBox
          Left = 12
          Top = 44
          Width = 270
          Height = 20
          Caption = 'Minimize on run'
          TabOrder = 1
          ParentShowHint = False
          ShowHint = True
          Hint = 'Среда сворачивается, пока работает запущенная программа (без отладчика), и разворачивается, когда она закроется'
          OnClick = EnvOptionClick
        end
        object chkPrefHideDsg: TUiCheckBox
          Left = 12
          Top = 68
          Width = 270
          Height = 20
          Caption = 'Hide designers on run'
          TabOrder = 2
          ParentShowHint = False
          ShowHint = True
          Hint = 'Формы конструктора прячутся, пока работает запущенная программа'
          OnClick = EnvOptionClick
        end
      end
    end
    object tsDesigner: TTabSheet
      Caption = 'Designer'
      object grpDsgGrid: TUiGroupBox
        Left = 8
        Top = 8
        Width = 290
        Height = 128
        Caption = ' Grid options '
        TabOrder = 0
        object chkDsgGrid: TUiCheckBox
          Left = 12
          Top = 20
          Width = 270
          Height = 20
          Caption = 'Display grid'
          TabOrder = 0
          OnClick = EnvOptionClick
        end
        object chkDsgSnap: TUiCheckBox
          Left = 12
          Top = 44
          Width = 270
          Height = 20
          Caption = 'Snap to grid'
          TabOrder = 1
          OnClick = EnvOptionClick
        end
        object lblDsgGridSize: TLabel
          Left = 30
          Top = 70
          Caption = 'Grid size'
        end
        object lblDsgGridX: TLabel
          Left = 40
          Top = 94
          Width = 12
          Height = 16
          Caption = 'X'
        end
        object edDsgGridX: TUiEdit
          Left = 54
          Top = 90
          Width = 50
          Height = 24
          TabOrder = 2
          Text = '2'
          OnChange = EnvGridChange
        end
        object udDsgGridX: TUiUpDown
          Left = 104
          Top = 90
          Width = 16
          Height = 24
          Associate = edDsgGridX
          Min = 2
          Max = 128
          Position = 2
          TabOrder = 3
        end
        object lblDsgGridY: TLabel
          Left = 140
          Top = 94
          Width = 12
          Height = 16
          Caption = 'Y'
        end
        object edDsgGridY: TUiEdit
          Left = 154
          Top = 90
          Width = 50
          Height = 24
          TabOrder = 4
          Text = '2'
          OnChange = EnvGridChange
        end
        object udDsgGridY: TUiUpDown
          Left = 204
          Top = 90
          Width = 16
          Height = 24
          Associate = edDsgGridY
          Min = 2
          Max = 128
          Position = 2
          TabOrder = 5
        end
      end
      object grpDsgModule: TUiGroupBox
        Left = 8
        Top = 144
        Width = 290
        Height = 48
        Caption = ' Module creation options '
        TabOrder = 1
        object chkDsgAutoCreate: TUiCheckBox
          Left = 12
          Top = 20
          Width = 270
          Height = 20
          Caption = 'Auto create forms & data modules'
          TabOrder = 0
          ParentShowHint = False
          ShowHint = True
          Hint = 'New Form вписывает в .dpr Application.CreateForm новой формы'
          OnClick = EnvOptionClick
        end
      end
      object grpDsgOptions: TUiGroupBox
        Left = 306
        Top = 8
        Width = 290
        Height = 128
        Caption = ' Options '
        TabOrder = 2
        object chkDsgCaptions: TUiCheckBox
          Left = 12
          Top = 20
          Width = 270
          Height = 20
          Caption = 'Show component captions'
          TabOrder = 0
          ParentShowHint = False
          ShowHint = True
          Hint = 'Имена невизуальных компонентов под их значками'
          OnClick = EnvOptionClick
        end
        object chkDsgHints: TUiCheckBox
          Left = 12
          Top = 44
          Width = 270
          Height = 20
          Caption = 'Show designer hints'
          TabOrder = 1
          ParentShowHint = False
          ShowHint = True
          Hint = 'Подсказка «Имя: Класс» над компонентом под мышью'
          OnClick = EnvOptionClick
        end
        object chkDsgExtHints: TUiCheckBox
          Left = 30
          Top = 68
          Width = 252
          Height = 20
          Caption = 'Show extended control hints'
          TabOrder = 2
          ParentShowHint = False
          ShowHint = True
          Hint = 'В подсказке - место, размер, Tab Stop и Tab Order'
          OnClick = EnvOptionClick
        end
      end
    end
    object tsEnvVars: TTabSheet
      Caption = 'Environment Variables'
      object grpEnvSystem: TUiGroupBox
        Left = 8
        Top = 8
        Width = 590
        Height = 210
        Caption = ' System variables '
        TabOrder = 0
        object lvEnvSystem: TUiListView
          Left = 12
          Top = 20
          Width = 566
          Height = 150
          Columns = <
            item
              Caption = 'Variable'
              Width = 180
            end
            item
              Caption = 'Value'
              Width = 360
            end>
          HideSelection = False
          ReadOnly = True
          RowSelect = True
          TabOrder = 0
          ViewStyle = vsReport
          OnDblClick = EnvOverrideClick
        end
        object btnEnvOverride: TUiButton
          Left = 478
          Top = 176
          Width = 100
          Height = 26
          Caption = 'Add Override...'
          TabOrder = 1
          OnClick = EnvOverrideClick
        end
      end
      object grpEnvUser: TUiGroupBox
        Left = 8
        Top = 224
        Width = 590
        Height = 200
        Caption = ' User overrides '
        TabOrder = 1
        ParentShowHint = False
        ShowHint = True
        Hint = 'Подмены ставятся в окружение среды: их видят пути компиляторов ($(VAR), %VAR%) и все программы, которые среда запускает. %VAR% в значении раскрывается по системным переменным.'
        object lvEnvUser: TUiListView
          Left = 12
          Top = 20
          Width = 566
          Height = 140
          Columns = <
            item
              Caption = 'Variable'
              Width = 180
            end
            item
              Caption = 'Value'
              Width = 360
            end>
          HideSelection = False
          ReadOnly = True
          RowSelect = True
          TabOrder = 0
          ViewStyle = vsReport
          OnDblClick = EnvEditClick
        end
        object btnEnvNew: TUiButton
          Left = 266
          Top = 166
          Width = 100
          Height = 26
          Caption = 'New...'
          TabOrder = 1
          OnClick = EnvNewClick
        end
        object btnEnvEdit: TUiButton
          Left = 372
          Top = 166
          Width = 100
          Height = 26
          Caption = 'Edit...'
          TabOrder = 2
          OnClick = EnvEditClick
        end
        object btnEnvDelete: TUiButton
          Left = 478
          Top = 166
          Width = 100
          Height = 26
          Caption = 'Delete'
          TabOrder = 3
          OnClick = EnvDeleteClick
        end
      end
    end
  end
  object ColorDlg: TUiColorDialog
    Options = [cdFullOpen, cdAnyColor]
    Left = 560
    Top = 4
  end
  object FontDlg: TUiFontDialog
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    Options = [fdAnsiOnly, fdFixedPitchOnly]
    Left = 588
    Top = 4
  end
  object FSchemaMenu: TUiPopupMenu
    Left = 532
    Top = 4
  end
end
