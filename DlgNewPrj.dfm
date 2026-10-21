object DlgNewPrj: TDlgNewPrj
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'New Project'
  ClientHeight = 560
  ClientWidth = 760
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pcMain: TUiPageControl
    Left = 8
    Top = 8
    Width = 744
    Height = 506
    ActivePage = tsProject
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 0
    object tsProject: TTabSheet
      Caption = 'Project'
      object lblName: TLabel
        Left = 12
        Top = 16
        Caption = 'Имя проекта'
      end
      object lblDir: TLabel
        Left = 12
        Top = 48
        Caption = 'Папка проекта'
      end
      object lblType: TLabel
        Left = 12
        Top = 108
        Caption = 'Тип проекта'
      end
      object edName: TUiEdit
        Left = 110
        Top = 12
        Width = 310
        TabOrder = 0
      end
      object edDir: TUiEdit
        Left = 110
        Top = 44
        Width = 576
        TabOrder = 1
      end
      object btnBrowse: TUiButton
        Left = 692
        Top = 43
        Width = 30
        Height = 23
        Caption = '...'
        TabOrder = 2
        ModalResult = 4
      end
      object chkBase: TUiCheckBox
        Left = 110
        Top = 76
        Width = 310
        Height = 17
        Caption = 'На базе существующего проекта'
        TabOrder = 3
      end
      object cbType: TUiComboBox
        Left = 110
        Top = 104
        Width = 310
        Style = csDropDownList
        TabOrder = 4
        Items.Strings = (
          'RapidQ Basic'
          'Delphi'
          'Lazarus'
          'FreeBASIC'
          'Visual Basic'
          'Arduino'
          'C project'
          'CPP project'
          'Go'
          'Python'
          'Rust'
          'WebSite'
          'ReactOS')
        OnChange = cbTypeChange
      end
      object grpRqInc: TUiGroupBox
        Left = 12
        Top = 140
        Width = 710
        Height = 118
        Caption = 'Папка inc (RapidQ)'
        TabOrder = 5
        object rbIncSys: TUiRadioButton
          Left = 12
          Top = 22
          Width = 680
          Height = 17
          Caption = 'Системные (новые): RQProc.inc, RQControls.inc'
          TabOrder = 0
          OnClick = rbIncClick
        end
        object rbIncUser: TUiRadioButton
          Left = 12
          Top = 44
          Width = 680
          Height = 17
          Caption = 'Пользовательские (старые): inc, с которыми писалась программа'
          TabOrder = 1
          OnClick = rbIncClick
        end
        object edIncPath: TUiEdit
          Left = 12
          Top = 70
          Width = 640
          TabOrder = 2
        end
        object btnIncBrowse: TUiButton
          Left = 660
          Top = 69
          Width = 30
          Height = 23
          Caption = '...'
          TabOrder = 3
          OnClick = btnIncBrowseClick
        end
        object lblIncNote: TLabel
          Left = 12
          Top = 96
          Caption = 'Пути - из настроек компилятора RapidQ; свой путь в поле - только для этого проекта'
        end
      end
    end
    object tsOptions: TTabSheet
      Caption = 'Project options'
      ImageIndex = 1
      object pcOptions: TUiPageControl
        Left = 0
        Top = 0
        Width = 736
        Height = 478
        ActivePage = tsForms
        Align = alClient
        TabOrder = 0
        object tsForms: TTabSheet
          Caption = 'Forms'
          object lblMainForm: TLabel
            Left = 8
            Top = 12
            Caption = 'Main form:'
          end
          object cbMainForm: TUiComboBox
            Left = 90
            Top = 8
            Width = 260
            Style = csDropDownList
            TabOrder = 0
            OnChange = cbMainFormChange
          end
          object lblAutoForms: TLabel
            Left = 8
            Top = 40
            Caption = 'Auto-create forms:'
          end
          object lbAutoForms: TUiListBox
            Left = 8
            Top = 58
            Width = 310
            Height = 320
            ItemHeight = 13
            TabOrder = 1
          end
          object btnFormToAvail: TUiButton
            Left = 330
            Top = 110
            Width = 50
            Height = 23
            Caption = '>'
            TabOrder = 2
            OnClick = btnFormMoveClick
          end
          object btnAllToAvail: TUiButton
            Left = 330
            Top = 140
            Width = 50
            Height = 23
            Caption = '>>'
            TabOrder = 3
            OnClick = btnFormMoveClick
          end
          object btnFormToAuto: TUiButton
            Left = 330
            Top = 190
            Width = 50
            Height = 23
            Caption = '<'
            TabOrder = 4
            OnClick = btnFormMoveClick
          end
          object btnAllToAuto: TUiButton
            Left = 330
            Top = 220
            Width = 50
            Height = 23
            Caption = '<<'
            TabOrder = 5
            OnClick = btnFormMoveClick
          end
          object lblAvailForms: TLabel
            Left = 392
            Top = 40
            Caption = 'Available forms:'
          end
          object lbAvailForms: TUiListBox
            Left = 392
            Top = 58
            Width = 310
            Height = 320
            ItemHeight = 13
            TabOrder = 6
          end
          object lblFormsNote: TLabel
            Left = 8
            Top = 386
            Width = 700
            Height = 40
            AutoSize = False
            Caption = 'Список форм и главная форма записываются в .dpr (Application.CreateForm). Главная форма - первая в списке Auto-create forms.'
            WordWrap = True
          end
        end
        object tsApplication: TTabSheet
          Caption = 'Application'
          ImageIndex = 1
          object grpAppSettings: TUiGroupBox
            Left = 8
            Top = 8
            Width = 712
            Height = 130
            Caption = 'Application settings'
            TabOrder = 0
            object lblTitle: TLabel
              Left = 12
              Top = 24
              Caption = 'Title:'
            end
            object edTitle: TUiEdit
              Left = 90
              Top = 20
              Width = 420
              TabOrder = 0
            end
            object lblHelpFile: TLabel
              Left = 12
              Top = 56
              Caption = 'Help file:'
            end
            object edHelpFile: TUiEdit
              Left = 90
              Top = 52
              Width = 420
              TabOrder = 1
            end
            object btnHelpBrowse: TUiButton
              Left = 516
              Top = 51
              Width = 30
              Height = 23
              Caption = '...'
              TabOrder = 2
              OnClick = btnHelpBrowseClick
            end
            object lblIcon: TLabel
              Left = 12
              Top = 92
              Caption = 'Icon:'
            end
            object imgIcon: TImage
              Left = 90
              Top = 82
              Width = 32
              Height = 32
              Center = True
            end
            object btnLoadIcon: TUiButton
              Left = 140
              Top = 86
              Width = 100
              Height = 25
              Caption = 'Load Icon...'
              TabOrder = 3
              OnClick = btnLoadIconClick
            end
          end
          object lblAppNote: TLabel
            Left = 8
            Top = 146
            Width = 712
            Height = 40
            AutoSize = False
            Caption = 'Title и Help file записываются в .dpr (Application.Title, Application.HelpFile), значок - в .res проекта (MAINICON).'
            WordWrap = True
          end
        end
        object tsCompiler: TTabSheet
          Caption = 'Compiler'
          ImageIndex = 2
          object grpCodeGen: TUiGroupBox
            Left = 8
            Top = 8
            Width = 350
            Height = 112
            Caption = 'Code generation'
            TabOrder = 0
            object chkOptimization: TUiCheckBox
              Left = 12
              Top = 20
              Width = 260
              Height = 17
              Caption = 'Optimization'
              TabOrder = 0
            end
            object chkStackFrames: TUiCheckBox
              Left = 12
              Top = 40
              Width = 260
              Height = 17
              Caption = 'Stack frames'
              TabOrder = 1
            end
            object chkSafeDivide: TUiCheckBox
              Left = 12
              Top = 60
              Width = 260
              Height = 17
              Caption = 'Pentium-safe FDIV'
              TabOrder = 2
            end
            object lblAlign: TLabel
              Left = 12
              Top = 86
              Caption = 'Record field alignment'
            end
            object cbAlign: TUiComboBox
              Left = 150
              Top = 82
              Width = 60
              Style = csDropDownList
              TabOrder = 3
              Items.Strings = (
                '1'
                '2'
                '4'
                '8')
            end
          end
          object grpRuntimeErr: TUiGroupBox
            Left = 8
            Top = 126
            Width = 350
            Height = 84
            Caption = 'Runtime errors'
            TabOrder = 1
            object chkRangeCheck: TUiCheckBox
              Left = 12
              Top = 20
              Width = 260
              Height = 17
              Caption = 'Range checking'
              TabOrder = 0
            end
            object chkIoCheck: TUiCheckBox
              Left = 12
              Top = 40
              Width = 260
              Height = 17
              Caption = 'I/O checking'
              TabOrder = 1
            end
            object chkOverflowCheck: TUiCheckBox
              Left = 12
              Top = 60
              Width = 260
              Height = 17
              Caption = 'Overflow checking'
              TabOrder = 2
            end
          end
          object grpDebugging: TUiGroupBox
            Left = 8
            Top = 216
            Width = 350
            Height = 124
            Caption = 'Debugging'
            TabOrder = 2
            object chkDebugInfo: TUiCheckBox
              Left = 12
              Top = 20
              Width = 260
              Height = 17
              Caption = 'Debug information'
              TabOrder = 0
            end
            object chkLocalSymbols: TUiCheckBox
              Left = 12
              Top = 40
              Width = 260
              Height = 17
              Caption = 'Local symbols'
              TabOrder = 1
            end
            object chkReferenceInfo: TUiCheckBox
              Left = 12
              Top = 60
              Width = 260
              Height = 17
              Caption = 'Reference info'
              TabOrder = 2
              OnClick = chkReferenceInfoClick
            end
            object chkDefinitionsOnly: TUiCheckBox
              Left = 30
              Top = 80
              Width = 240
              Height = 17
              Caption = 'Definitions only'
              TabOrder = 3
            end
            object chkAssertions: TUiCheckBox
              Left = 12
              Top = 100
              Width = 260
              Height = 17
              Caption = 'Assertions'
              TabOrder = 4
            end
          end
          object grpSyntax: TUiGroupBox
            Left = 366
            Top = 8
            Width = 354
            Height = 166
            Caption = 'Syntax options'
            TabOrder = 3
            object chkStrictVar: TUiCheckBox
              Left = 12
              Top = 20
              Width = 260
              Height = 17
              Caption = 'Strict var-strings'
              TabOrder = 0
            end
            object chkCompleteBool: TUiCheckBox
              Left = 12
              Top = 40
              Width = 260
              Height = 17
              Caption = 'Complete boolean eval'
              TabOrder = 1
            end
            object chkExtendedSyntax: TUiCheckBox
              Left = 12
              Top = 60
              Width = 260
              Height = 17
              Caption = 'Extended syntax'
              TabOrder = 2
            end
            object chkTypedAddress: TUiCheckBox
              Left = 12
              Top = 80
              Width = 260
              Height = 17
              Caption = 'Typed @ operator'
              TabOrder = 3
            end
            object chkOpenParams: TUiCheckBox
              Left = 12
              Top = 100
              Width = 260
              Height = 17
              Caption = 'Open parameters'
              TabOrder = 4
            end
            object chkHugeStrings: TUiCheckBox
              Left = 12
              Top = 120
              Width = 260
              Height = 17
              Caption = 'Huge strings'
              TabOrder = 5
            end
            object chkWritableConst: TUiCheckBox
              Left = 12
              Top = 140
              Width = 260
              Height = 17
              Caption = 'Assignable typed constants'
              TabOrder = 6
            end
          end
          object lblCompilerNote: TLabel
            Left = 8
            Top = 350
            Width = 712
            Height = 44
            AutoSize = False
            Caption = 'При сборке в unIDE эти ключи передаются dcc32 (-$A..-$Z). Отладочная сборка (точки останова, F7/F8/F4) добавляет к ним -$D+ -$L+ -$O- -$W+.'
            WordWrap = True
          end
        end
        object tsMessages: TTabSheet
          Caption = 'Compiler Messages'
          ImageIndex = 3
          object grpMsgGeneral: TUiGroupBox
            Left = 8
            Top = 8
            Width = 712
            Height = 46
            Caption = 'General'
            TabOrder = 0
            object chkShowHints: TUiCheckBox
              Left = 12
              Top = 20
              Width = 170
              Height = 17
              Caption = 'Show hints'
              TabOrder = 0
            end
            object chkShowWarnings: TUiCheckBox
              Left = 200
              Top = 20
              Width = 170
              Height = 17
              Caption = 'Show warnings'
              TabOrder = 1
            end
          end
          object grpWarnings: TUiGroupBox
            Left = 8
            Top = 60
            Width = 712
            Height = 340
            Caption = 'Warnings'
            TabOrder = 1
            object clbWarnings: TCheckListBox
              Left = 12
              Top = 20
              Width = 688
              Height = 308
              ItemHeight = 13
              TabOrder = 0
            end
          end
        end
        object tsLinker: TTabSheet
          Caption = 'Linker'
          ImageIndex = 4
          object grpMapFile: TUiGroupBox
            Left = 8
            Top = 8
            Width = 350
            Height = 106
            Caption = 'Map file'
            TabOrder = 0
            object rbMapOff: TUiRadioButton
              Left = 12
              Top = 20
              Width = 200
              Height = 17
              Caption = 'Off'
              TabOrder = 0
            end
            object rbMapSegments: TUiRadioButton
              Left = 12
              Top = 40
              Width = 200
              Height = 17
              Caption = 'Segments'
              TabOrder = 1
            end
            object rbMapPublics: TUiRadioButton
              Left = 12
              Top = 60
              Width = 200
              Height = 17
              Caption = 'Publics'
              TabOrder = 2
            end
            object rbMapDetailed: TUiRadioButton
              Left = 12
              Top = 80
              Width = 200
              Height = 17
              Caption = 'Detailed'
              TabOrder = 3
            end
          end
          object grpExeOptions: TUiGroupBox
            Left = 366
            Top = 8
            Width = 354
            Height = 106
            Caption = 'EXE and DLL options'
            TabOrder = 1
            object chkConsoleApp: TUiCheckBox
              Left = 12
              Top = 20
              Width = 320
              Height = 17
              Caption = 'Generate console application'
              TabOrder = 0
            end
            object chkTd32Info: TUiCheckBox
              Left = 12
              Top = 40
              Width = 320
              Height = 17
              Caption = 'Include TD32 debug info'
              TabOrder = 1
            end
            object chkRemoteSymbols: TUiCheckBox
              Left = 12
              Top = 60
              Width = 320
              Height = 17
              Caption = 'Include remote debug symbols'
              TabOrder = 2
            end
          end
          object grpMemory: TUiGroupBox
            Left = 8
            Top = 120
            Width = 712
            Height = 56
            Caption = 'Memory sizes'
            TabOrder = 2
            object lblMinStack: TLabel
              Left = 12
              Top = 26
              Caption = 'Min stack size:'
            end
            object edMinStack: TUiEdit
              Left = 100
              Top = 22
              Width = 110
              TabOrder = 0
            end
            object lblMaxStack: TLabel
              Left = 236
              Top = 26
              Caption = 'Max stack size:'
            end
            object edMaxStack: TUiEdit
              Left = 324
              Top = 22
              Width = 110
              TabOrder = 1
            end
            object lblImageBase: TLabel
              Left = 460
              Top = 26
              Caption = 'Image base:'
            end
            object edImageBase: TUiEdit
              Left = 530
              Top = 22
              Width = 110
              TabOrder = 2
            end
          end
          object grpExeDescr: TUiGroupBox
            Left = 8
            Top = 182
            Width = 712
            Height = 56
            Caption = 'EXE Description'
            TabOrder = 3
            object edExeDescription: TUiEdit
              Left = 12
              Top = 22
              Width = 688
              TabOrder = 0
            end
          end
          object lblLinkerNote: TLabel
            Left = 8
            Top = 248
            Width = 712
            Height = 56
            AutoSize = False
            Caption = 'При сборке в unIDE используются Map file (-GS/-GP/-GD), TD32 debug info (-V), remote debug symbols (-VR), Memory sizes (-$M, -K). Generate console application и EXE Description читает среда Delphi 7; dcc32 тип программы берёт из {$APPTYPE} в .dpr.'
            WordWrap = True
          end
        end
        object tsDirectories: TTabSheet
          Caption = 'Directories/Conditionals'
          ImageIndex = 5
          object grpDirs: TUiGroupBox
            Left = 8
            Top = 8
            Width = 712
            Height = 196
            Caption = 'Directories'
            TabOrder = 0
            object lblOutputDir: TLabel
              Left = 12
              Top = 26
              Caption = 'Output directory:'
            end
            object edOutputDir: TUiEdit
              Left = 150
              Top = 22
              Width = 520
              TabOrder = 0
            end
            object btnOutputDir: TUiButton
              Left = 676
              Top = 21
              Width = 26
              Height = 23
              Caption = '...'
              TabOrder = 1
              Tag = 1
              OnClick = btnDirBrowseClick
            end
            object lblUnitOutputDir: TLabel
              Left = 12
              Top = 54
              Caption = 'Unit output directory:'
            end
            object edUnitOutputDir: TUiEdit
              Left = 150
              Top = 50
              Width = 520
              TabOrder = 2
            end
            object btnUnitOutputDir: TUiButton
              Left = 676
              Top = 49
              Width = 26
              Height = 23
              Caption = '...'
              TabOrder = 3
              Tag = 2
              OnClick = btnDirBrowseClick
            end
            object lblSearchPath: TLabel
              Left = 12
              Top = 82
              Caption = 'Search path:'
            end
            object edSearchPath: TUiEdit
              Left = 150
              Top = 78
              Width = 520
              TabOrder = 4
            end
            object btnSearchPath: TUiButton
              Left = 676
              Top = 77
              Width = 26
              Height = 23
              Caption = '...'
              TabOrder = 5
              Tag = 3
              OnClick = btnDirBrowseClick
            end
            object lblDebugSourceDirs: TLabel
              Left = 12
              Top = 110
              Caption = 'Debug source path:'
            end
            object edDebugSourceDirs: TUiEdit
              Left = 150
              Top = 106
              Width = 520
              TabOrder = 6
            end
            object btnDebugSourceDirs: TUiButton
              Left = 676
              Top = 105
              Width = 26
              Height = 23
              Caption = '...'
              TabOrder = 7
              Tag = 4
              OnClick = btnDirBrowseClick
            end
            object lblBplOutputDir: TLabel
              Left = 12
              Top = 138
              Caption = 'BPL output directory:'
            end
            object edBplOutputDir: TUiEdit
              Left = 150
              Top = 134
              Width = 520
              TabOrder = 8
            end
            object btnBplOutputDir: TUiButton
              Left = 676
              Top = 133
              Width = 26
              Height = 23
              Caption = '...'
              TabOrder = 9
              Tag = 5
              OnClick = btnDirBrowseClick
            end
            object lblDcpOutputDir: TLabel
              Left = 12
              Top = 166
              Caption = 'DCP output directory:'
            end
            object edDcpOutputDir: TUiEdit
              Left = 150
              Top = 162
              Width = 520
              TabOrder = 10
            end
            object btnDcpOutputDir: TUiButton
              Left = 676
              Top = 161
              Width = 26
              Height = 23
              Caption = '...'
              TabOrder = 11
              Tag = 6
              OnClick = btnDirBrowseClick
            end
          end
          object grpConditionals: TUiGroupBox
            Left = 8
            Top = 210
            Width = 712
            Height = 52
            Caption = 'Conditionals'
            TabOrder = 1
            object lblConditionals: TLabel
              Left = 12
              Top = 24
              Caption = 'Conditional defines:'
            end
            object edConditionals: TUiEdit
              Left = 150
              Top = 20
              Width = 552
              TabOrder = 0
            end
          end
          object grpAliases: TUiGroupBox
            Left = 8
            Top = 268
            Width = 712
            Height = 52
            Caption = 'Aliases'
            TabOrder = 2
            object lblUnitAliases: TLabel
              Left = 12
              Top = 24
              Caption = 'Unit aliases:'
            end
            object edUnitAliases: TUiEdit
              Left = 150
              Top = 20
              Width = 552
              TabOrder = 0
            end
          end
          object lblDirsNote: TLabel
            Left = 8
            Top = 328
            Width = 712
            Height = 56
            AutoSize = False
            Caption = 'При сборке в unIDE используются Search path и Conditional defines. Папки для exe и .dcu unIDE берёт из настроек инструмента (IDE Options - Compilers - Delphi); Output directory и Unit output directory отсюда читает среда Delphi 7.'
            WordWrap = True
          end
        end
        object tsVersion: TTabSheet
          Caption = 'Version Info'
          ImageIndex = 6
          object chkIncludeVer: TUiCheckBox
            Left = 8
            Top = 8
            Width = 400
            Height = 17
            Caption = 'Include version information in project'
            TabOrder = 0
            OnClick = chkIncludeVerClick
          end
          object grpVerNumber: TUiGroupBox
            Left = 8
            Top = 30
            Width = 712
            Height = 86
            Caption = 'Module version number'
            TabOrder = 1
            object lblMajor: TLabel
              Left = 12
              Top = 18
              Caption = 'Major version'
            end
            object edMajor: TUiEdit
              Left = 12
              Top = 34
              Width = 80
              TabOrder = 0
              OnChange = edVerNumberChange
            end
            object udMajor: TUiUpDown
              Left = 92
              Top = 34
              Width = 16
              Height = 21
              Associate = edMajor
              Max = 32767
              TabOrder = 1
              Thousands = False
            end
            object lblMinor: TLabel
              Left = 130
              Top = 18
              Caption = 'Minor version'
            end
            object edMinor: TUiEdit
              Left = 130
              Top = 34
              Width = 80
              TabOrder = 2
              OnChange = edVerNumberChange
            end
            object udMinor: TUiUpDown
              Left = 210
              Top = 34
              Width = 16
              Height = 21
              Associate = edMinor
              Max = 32767
              TabOrder = 3
              Thousands = False
            end
            object lblRelease: TLabel
              Left = 248
              Top = 18
              Caption = 'Release'
            end
            object edRelease: TUiEdit
              Left = 248
              Top = 34
              Width = 80
              TabOrder = 4
              OnChange = edVerNumberChange
            end
            object udRelease: TUiUpDown
              Left = 328
              Top = 34
              Width = 16
              Height = 21
              Associate = edRelease
              Max = 32767
              TabOrder = 5
              Thousands = False
            end
            object lblBuild: TLabel
              Left = 366
              Top = 18
              Caption = 'Build'
            end
            object edBuild: TUiEdit
              Left = 366
              Top = 34
              Width = 80
              TabOrder = 6
              OnChange = edVerNumberChange
            end
            object udBuild: TUiUpDown
              Left = 446
              Top = 34
              Width = 16
              Height = 21
              Associate = edBuild
              Max = 32767
              TabOrder = 7
              Thousands = False
            end
            object chkAutoInc: TUiCheckBox
              Left = 12
              Top = 62
              Width = 260
              Height = 17
              Caption = 'Auto-increment build number'
              TabOrder = 8
            end
          end
          object grpModAttr: TUiGroupBox
            Left = 8
            Top = 122
            Width = 350
            Height = 82
            Caption = 'Module attributes'
            TabOrder = 2
            object chkVerDebug: TUiCheckBox
              Left = 12
              Top = 18
              Width = 150
              Height = 17
              Caption = 'Debug build'
              TabOrder = 0
            end
            object chkVerPreRelease: TUiCheckBox
              Left = 12
              Top = 38
              Width = 150
              Height = 17
              Caption = 'Pre-release'
              TabOrder = 1
            end
            object chkVerDll: TUiCheckBox
              Left = 12
              Top = 58
              Width = 150
              Height = 17
              Caption = 'DLL'
              TabOrder = 2
            end
            object chkVerSpecial: TUiCheckBox
              Left = 176
              Top = 18
              Width = 150
              Height = 17
              Caption = 'Special build'
              TabOrder = 3
            end
            object chkVerPrivate: TUiCheckBox
              Left = 176
              Top = 38
              Width = 150
              Height = 17
              Caption = 'Private build'
              TabOrder = 4
            end
          end
          object grpLanguage: TUiGroupBox
            Left = 366
            Top = 122
            Width = 354
            Height = 82
            Caption = 'Language'
            TabOrder = 3
            object lblLocaleId: TLabel
              Left = 12
              Top = 22
              Width = 300
              AutoSize = False
              Caption = 'Locale ID:'
            end
            object cbLocale: TUiComboBox
              Left = 12
              Top = 44
              Width = 330
              Style = csDropDownList
              TabOrder = 0
              DropDownCount = 20
              OnChange = cbLocaleChange
            end
          end
          object lvVerKeys: TUiListView
            Left = 8
            Top = 210
            Width = 712
            Height = 162
            Columns = <
              item
              Caption = 'Key'
              Width = 200
              end
              item
              Caption = 'Value'
              Width = 480
              end>
            HideSelection = False
            ReadOnly = True
            RowSelect = True
            TabOrder = 4
            ViewStyle = vsReport
            OnSelectItem = lvVerKeysSelectItem
          end
          object lblVerKey: TLabel
            Left = 8
            Top = 384
            Caption = 'Key'
          end
          object edVerKey: TUiEdit
            Left = 34
            Top = 380
            Width = 170
            TabOrder = 5
          end
          object lblVerValue: TLabel
            Left = 214
            Top = 384
            Caption = 'Value'
          end
          object edVerValue: TUiEdit
            Left = 248
            Top = 380
            Width = 300
            TabOrder = 6
          end
          object btnVerKeySet: TUiButton
            Left = 556
            Top = 379
            Width = 78
            Height = 23
            Caption = 'Set'
            TabOrder = 7
            OnClick = btnVerKeySetClick
          end
          object btnVerKeyDel: TUiButton
            Left = 640
            Top = 379
            Width = 80
            Height = 23
            Caption = 'Delete'
            TabOrder = 8
            OnClick = btnVerKeyDelClick
          end
        end
        object tsPackages: TTabSheet
          Caption = 'Packages'
          ImageIndex = 7
          object grpDesignPkgs: TUiGroupBox
            Left = 8
            Top = 8
            Width = 712
            Height = 252
            Caption = 'Design packages'
            TabOrder = 0
            object clbDesignPkgs: TCheckListBox
              Left = 12
              Top = 20
              Width = 688
              Height = 204
              ItemHeight = 13
              TabOrder = 0
              OnClick = clbDesignPkgsClick
            end
            object lblPkgPath: TLabel
              Left = 12
              Top = 230
              Width = 688
              AutoSize = False
              Caption = ''
            end
          end
          object grpRuntimePkgs: TUiGroupBox
            Left = 8
            Top = 266
            Width = 712
            Height = 76
            Caption = 'Runtime packages'
            TabOrder = 1
            object chkUsePackages: TUiCheckBox
              Left = 12
              Top = 22
              Width = 260
              Height = 17
              Caption = 'Build with runtime packages'
              TabOrder = 0
            end
            object edRuntimePkgs: TUiEdit
              Left = 12
              Top = 44
              Width = 688
              TabOrder = 1
            end
          end
          object lblPkgNote: TLabel
            Left = 8
            Top = 350
            Width = 712
            Height = 44
            AutoSize = False
            Caption = 'Design packages - список среды Delphi 7 из реестра; снятые галки записываются в .dof ([Excluded Packages]). Build with runtime packages при сборке в unIDE передаётся dcc32 ключом -LU.'
            WordWrap = True
          end
        end
      end
    end
  end
  object btnOk: TUiButton
    Left = 586
    Top = 524
    Width = 80
    Height = 25
    Caption = 'OK'
    TabOrder = 1
    Anchors = [akRight, akBottom]
    Default = True
    ModalResult = 1
  end
  object btnCancel: TUiButton
    Left = 672
    Top = 524
    Width = 80
    Height = 25
    Caption = 'Cancel'
    TabOrder = 2
    Anchors = [akRight, akBottom]
    Cancel = True
    ModalResult = 2
  end
end
