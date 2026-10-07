object Form1: TForm1
  BorderIcons = [biSystemMenu, biMinimize, biMaximize]
  Left = 99
  Top = 210
  Width = 1407
  Height = 910
  Caption = 'Form1 current'
  Color = 10944511
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  Position = poDesktopCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object RichEdit1: TRichEdit
    Left = 57
    Top = 8
    Width = 3000
    Height = 457
    Align = alLeft
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    Color = clBtnShadow
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGray
    Font.Height = -15
    Font.Name = 'Source Code Pro'
    Font.Style = []
    HideSelection = False
    HideScrollBars = False
    ParentFont = False
    PlainText = True
    ScrollBars = ssBoth
    TabOrder = 0
    WantTabs = True
    WordWrap = False
  end
  object pnlMain: TPanel
    Left = 3057
    Top = 0
    Width = 0
    Height = 457
    Align = alClient
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 1
    object Splitter1: TSplitter
      Left = 0
      Top = 324
      Width = 0
      Height = 6
      Cursor = crVSplit
      Align = alBottom
      Color = clSkyBlue
      ParentColor = False
    end
    object Panel2: TPanel
      Left = 0
      Top = 305
      Width = 0
      Height = 19
      Align = alBottom
      BevelOuter = bvNone
      ParentBackground = False
      TabOrder = 0
      object FStatus2: TUiStatusBar
        SizeGrip = False
        ShowHint = True
        Hint = 'Клик по пути копирует его в буфер обмена'
        OnMouseDown = Status2MouseDown
      end
    end
    object pnlLog: TPanel
      Left = 0
      Top = 330
      Width = 0
      Height = 127
      Align = alBottom
      BevelOuter = bvNone
      ParentBackground = False
      TabOrder = 1
      object LogTabs: TUiTabControl
        Left = 0
        Top = 0
        Width = 0
        Height = 22
        Align = alTop
        TabOrder = 0
        Tabs.Strings = (
          'Compilation log'
          'Error log'
          'HiLite log'
          'Runtime log')
        TabIndex = 0
      end
      object pnlCompLog: TPanel
        Left = 0
        Top = 22
        Width = 0
        Height = 105
        Align = alClient
        BevelOuter = bvNone
        ParentBackground = False
        TabOrder = 1
        object CompLogEdit: TRichEdit
          Left = 0
          Top = 0
          Width = 0
          Height = 105
          Align = alClient
          BorderStyle = bsNone
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          ScrollBars = ssBoth
          TabOrder = 0
          WordWrap = False
        end
      end
      object pnlErrLog: TPanel
        Left = 0
        Top = 22
        Width = 0
        Height = 105
        Align = alClient
        BevelOuter = bvNone
        ParentBackground = False
        TabOrder = 3
        Visible = False
        object ErrLogEdit: TRichEdit
          Left = 0
          Top = 0
          Width = 0
          Height = 105
          Align = alClient
          BorderStyle = bsNone
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -14
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          ScrollBars = ssBoth
          TabOrder = 0
          WordWrap = False
        end
      end
      object pnlHiLog: TPanel
        Left = 0
        Top = 22
        Width = 0
        Height = 105
        Align = alClient
        BevelOuter = bvNone
        ParentBackground = False
        TabOrder = 2
        Visible = False
        object LogEdit: TRichEdit
          Left = 0
          Top = 0
          Width = 0
          Height = 105
          Align = alClient
          BorderStyle = bsNone
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -14
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          ScrollBars = ssBoth
          TabOrder = 0
          WordWrap = False
        end
      end
      object pnlRunLog: TPanel
        Left = 0
        Top = 22
        Width = 0
        Height = 105
        Align = alClient
        BevelOuter = bvNone
        ParentBackground = False
        TabOrder = 4
        Visible = False
        object RuntimeLog: TRichEdit
          Left = 0
          Top = 0
          Width = 0
          Height = 105
          Align = alClient
          BorderStyle = bsNone
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -14
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          ScrollBars = ssBoth
          TabOrder = 0
          WordWrap = False
        end
      end
    end
    object FTabs: TUiTabControl
      Top = 0
      Height = 30
      ParentFont = False
      Font.Name = 'Tahoma'
      Font.Size = 10
      Align = alTop
      OwnerDraw = True
      OnMouseDown = TabsMouseDown
      PopupMenu = FTabsPopup
    end
    object FLeftHost: TPanel
      BevelOuter = bvNone
      Caption = ''
      Align = alClient
      object FEditHost: TPanel
        BevelOuter = bvNone
        Caption = ''
        Align = alClient
      end
      object FHBar: TPanel
        BevelOuter = bvNone
        Align = alBottom
        object FHScroll: TUiScrollBar
          Kind = sbHorizontal
        end
      end
      object FVScroll: TUiScrollBar
        Kind = sbVertical
        Align = alRight
      end
    end
    object FDeclPanel: TPanel
      Height = 22
      Align = alTop
      BevelOuter = bvNone
      Alignment = taLeftJustify
      ParentBackground = False
      ParentFont = False
      Font.Name = 'Tahoma'
      Font.Size = 9
      Cursor = crHandPoint
      ShowHint = True
      OnClick = DeclPanelClick
      OnDblClick = DeclPanelClick
      object FBusyPanel: TPanel
        Visible = False
        BevelOuter = bvLowered
        Alignment = taLeftJustify
        ParentBackground = False
        ParentFont = False
        Font.Name = 'Tahoma'
        Font.Height = -12
        Font.Style = [fsBold]
      end
    end
  end
  object StatusBar1: TUiStatusBar
    Left = 0
    Top = 457
    Width = 3057
    Height = 19
    Panels = <
      item
        Width = 80
      end
      item
        Width = 80
      end
      item
        Width = 110
      end
      item
        Width = 100
      end
      item
        Width = 50
      end>
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 57
    Height = 457
    Align = alLeft
    BevelOuter = bvNone
    Color = clMaroon
    ParentBackground = False
    TabOrder = 3
    object PaintBox1: TPaintBox
      Left = 0
      Top = 0
      Width = 45
      Height = 457
      Align = alLeft
      Color = 16642785
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Source Code Pro'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      OnPaint = PaintBox1Paint
    end
    object MarksBox: TPaintBox
      Left = 45
      Top = 0
      Width = 12
      Height = 457
      Align = alClient
      OnClick = MarksBoxClick
      OnDblClick = MarksBoxDblClick
      OnMouseDown = MarksBoxMouseDown
      OnPaint = MarksBoxPaint
    end
  end
  object OpenDialog1: TOpenDialog
    Left = 16
    Top = 504
  end
  object SaveDialog1: TSaveDialog
    Left = 16
    Top = 224
  end
  object MainMenu1: TMainMenu
    Left = 16
    Top = 424
    object mFile: TMenuItem
      Caption = '&File'
      object mNew: TMenuItem
        Caption = '&New'
        ShortCut = 0
        object mNewItem1: TMenuItem
          Caption = 'Text File'
          OnClick = NewFileClick
          ShortCut = 0
          Hint = '.txt'
        end
        object mNewItem2: TMenuItem
          Caption = 'Pascal Unit'
          OnClick = NewFileClick
          ShortCut = 0
          Hint = '.pas'
        end
        object mNewItem3: TMenuItem
          Caption = 'BASIC File'
          OnClick = NewFileClick
          ShortCut = 0
          Hint = '.bas'
        end
        object mNewItem4: TMenuItem
          Caption = 'C++ File'
          OnClick = NewFileClick
          ShortCut = 0
          Hint = '.cpp'
        end
        object mNewItem5: TMenuItem
          Caption = 'HTML File'
          OnClick = NewFileClick
          ShortCut = 0
          Hint = '.html'
        end
        object mNewItem6: TMenuItem
          Caption = 'SQL Script'
          OnClick = NewFileClick
          ShortCut = 0
          Hint = '.sql'
        end
      end
      object mOpen: TMenuItem
        Caption = '&Open...'
        OnClick = N2Click
      end
      object mReopen: TMenuItem
        Caption = '&Reopen'
        ShortCut = 0
        AutoHotkeys = maManual
      end
      object mSave: TMenuItem
        Caption = '&Save'
        OnClick = N3Click
      end
      object mSaveAs: TMenuItem
        Caption = 'SaveFileAs...'
        OnClick = SaveAsClick
        ShortCut = 0
      end
      object mSepPrj: TMenuItem
        Caption = '-'
        ShortCut = 0
      end
      object mNewProject: TMenuItem
        Caption = 'NewProject'
        OnClick = NewProjectClick
        ShortCut = 0
      end
      object mOpenPrjFile: TMenuItem
        Caption = 'OpenPrjFile'
        OnClick = OpenPrjFileClick
        ShortCut = 0
        Hint = 'Открыть .prj текущего проекта в редакторе'
      end
      object mFilePrjFolder: TMenuItem
        Caption = 'OpenProjectFolder'
        OnClick = OpenProjectFolderClick
        ShortCut = 0
      end
      object mSaveProject: TMenuItem
        Caption = 'SaveProject'
        OnClick = SaveProjectClick
        ShortCut = 24659
      end
      object mSaveProjectAs: TMenuItem
        Caption = 'SaveProjectAs...'
        OnClick = SaveProjectAsClick
        ShortCut = 0
      end
      object mSepExit: TMenuItem
        Caption = '-'
        ShortCut = 0
      end
      object mExit: TMenuItem
        Caption = '&Exit'
      end
    end
    object mEdit: TMenuItem
      Caption = '&Edit'
      object mUndo: TMenuItem
        Caption = '&Undo'
        ShortCut = 16474
        OnClick = EditClickEvent
      end
      object mRedo: TMenuItem
        Caption = '&Redo'
        ShortCut = 24666
        OnClick = EditClickEvent
      end
      object mSep1: TMenuItem
        Caption = '-'
      end
      object mCut: TMenuItem
        Caption = 'Cu&t'
        ShortCut = 16472
        OnClick = EditClickEvent
      end
      object mCopy: TMenuItem
        Caption = '&Copy'
        ShortCut = 16451
        OnClick = EditClickEvent
      end
      object mPaste: TMenuItem
        Caption = '&Paste'
        ShortCut = 16470
        OnClick = EditClickEvent
      end
      object mDelete: TMenuItem
        Caption = '&Delete'#9'Del'
        ShortCut = 0
        OnClick = EditClickEvent
      end
      object mSep2: TMenuItem
        Caption = '-'
      end
      object mSelectAll: TMenuItem
        Caption = 'Select &All'
        ShortCut = 16449
        OnClick = EditClickEvent
      end
      object mSepFind: TMenuItem
        Caption = '-'
        ShortCut = 0
      end
      object mFind: TMenuItem
        Caption = '&Find'
        OnClick = FindPanelClick
        ShortCut = 16454
      end
      object mUndoReplace: TMenuItem
        Caption = 'Отменить массовую замену'
        OnClick = UndoReplaceAllClick
        ShortCut = 0
      end
    end
    object mView: TMenuItem
      Caption = '&View'
      object mViewUnits: TMenuItem
        Caption = 'Просмотр модулей'
        OnClick = ShowModulesClick
      end
      object mViewForms: TMenuItem
        Caption = 'Просмотр форм'
        OnClick = ShowFormsClick
      end
      object mViewSnap: TMenuItem
        Caption = 'Снимок формы редактора'
        OnClick = SnapshotOwnFormClick
      end
      object DsgItem: TMenuItem
        Caption = 'Конструктор формы'
        OnClick = DesignFormClick
      end
      object mViewIcons: TMenuItem
        Caption = 'Palette Icons...'
      end
    end
    object mProject: TMenuItem
      Caption = '&Project'
      OnClick = mProjectClick
      object mPrjManage: TMenuItem
        Caption = 'Manage Projects'
        object mPrjScan: TMenuItem
          Caption = 'Scan projects folder'
          OnClick = ScanProjectsFolderClick
        end
        object mPrjDeleteWrong: TMenuItem
          Caption = 'Delete wrong projects names'
          OnClick = DeleteWrongProjectsClick
        end
      end
      object mProjectLine1: TMenuItem
        Caption = '-'
      end
      object mPrjNew: TMenuItem
        Caption = 'New Project'
        OnClick = NewProjectClick
      end
      object mPrjOpen: TMenuItem
        Caption = 'Open Project'
        OnClick = OpenProjectClick
      end
      object mPrjReopen: TMenuItem
        Caption = 'Reopen Project'
        OnClick = ReopenProjectClick
      end
      object mPrjClose: TMenuItem
        Caption = 'Close Project'
        OnClick = CloseProjectClick
      end
      object mPrjProps: TMenuItem
        Caption = 'Project Properties...'
        OnClick = ProjectPropsClick
      end
      object mPrjDelete: TMenuItem
        Caption = 'Delete Projects...'
        OnClick = DeleteProjectClick
      end
      object mProjectLine2: TMenuItem
        Caption = '-'
      end
      object mPrjAdd: TMenuItem
        Caption = 'Add to project'
        OnClick = AddToProjectClick
      end
      object mPrjFolder: TMenuItem
        Caption = 'Open Project Folder'
        OnClick = OpenProjectFolderClick
      end
      object mProjectItem1: TMenuItem
        Caption = 'Fix paths after move'
        OnClick = FixPathsAfterMoveClick
      end
      object mPrjRelease: TMenuItem
        Caption = 'Build Release'
        OnClick = BuildReleaseClick
      end
      object mPrjReleaseFiles: TMenuItem
        Caption = 'Release files...'
        OnClick = ReleaseFilesClick
      end
      object mPrjSep: TMenuItem
        Caption = '-'
      end
    end
    object mFormatText: TMenuItem
      Caption = 'Format &text'
      OnClick = mFormatTextClick
    end
    object mWindows: TMenuItem
      Caption = '&Windows'
      object mWinClose: TMenuItem
        Caption = 'Close Window'
        OnClick = CloseCurrentWindowClick
      end
      object mWinDeleteDisabled: TMenuItem
        Caption = 'Delete disabled Windows'
      end
      object mWinCheckNames: TMenuItem
        Caption = 'Check wrong file names'
        OnClick = CheckWrongNamesClick
        Hint = 'Сверить пути открытых файлов с диском'
      end
      object mWinFindDisabled: TMenuItem
        Caption = 'Find lost files...'
        OnClick = TryFindDisabledClick
      end
      object mWinHotFolders: TMenuItem
        Caption = 'Search folders...'
        OnClick = HotFoldersClick
        Hint = 'Задать папки, в которых искать потерянные файлы'
      end
      object mWinDelList: TMenuItem
        Caption = 'Del WinList...'
        OnClick = DelWinListClick
        Hint = 'Отметить несколько окон галочками и закрыть разом'
      end
      object mWinSep: TMenuItem
        Caption = '-'
      end
    end
    object mBookmarks: TMenuItem
      Caption = '&Bookmarks'
      object mBmAdd: TMenuItem
        Caption = 'Add BookMark'
        OnClick = BmAddClick
      end
      object mBmDelete: TMenuItem
        Caption = 'Delete BookMark'
        OnClick = BmDeleteClick
      end
      object mBmSet: TMenuItem
        Caption = 'Set BookMark'
        OnClick = BmSetClick
        Hint = 'Переставить последнюю закладку на текущую строку'
      end
      object mBmSort: TMenuItem
        Caption = 'Sort BookMark'
        OnClick = BmSortClick
      end
      object mBmDelMissing: TMenuItem
        Caption = 'Delete Missing BookMarks'
        OnClick = BmDelMissingClick
        Hint = 'Удалить закладки, строк которых в файле больше нет'
      end
      object mBmClear: TMenuItem
        Caption = 'Clear List...'
        OnClick = BmClearClick
        Hint = 'Список закладок с галками: удалить отмеченные'
      end
      object mBmSep: TMenuItem
        Caption = '-'
      end
    end
    object mLastBM: TMenuItem
      Caption = 'LastBM'
      OnClick = LastBMClick
      Hint = 'Вернуться к предыдущей закладке'
    end
    object mHotBM: TMenuItem
      Caption = 'Hot Bookmarks'
      Hint = 'Закреплённые и 8 последних посещённых закладок всех вкладок'
      object mHotBmNone: TMenuItem
        Caption = '(посещённых закладок нет)'
        Enabled = False
      end
    end
    object mArduino: TMenuItem
      Caption = '&Arduino'
      object mArdBoards: TMenuItem
        Caption = 'Board Manager...'
        OnClick = mArdBoardsClick
        Hint = 'Платформы и платы arduino-cli (core, board)'
      end
      object mArdLibs: TMenuItem
        Caption = 'Library Manager...'
        OnClick = mArdLibsClick
        Hint = 'Библиотеки Arduino (library_index.json, lib)'
      end
      object mArdSep: TMenuItem
        Caption = '-'
      end
      object mArdCli: TMenuItem
        Caption = 'Arduino CLI Help...'
        OnClick = mArdCliClick
        Hint = 'Команды arduino-cli и их справка'
      end
    end
    object mOptions: TMenuItem
      Caption = '&Options'
      OnClick = mOptionsClick
    end
    object mHelp: TMenuItem
      Caption = '&Help'
      OnClick = mHelpClick
    end
  end
  object FontDialog1: TFontDialog
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold, fsItalic]
    Options = [fdEffects, fdWysiwyg]
    Left = 16
    Top = 464
  end
  object FDiskTimer: TTimer
    Interval = 2000
    OnTimer = DiskTimerTick
    Left = 16
    Top = 384
  end
  object FStatusTimer: TTimer
    Interval = 100
    Enabled = False
    OnTimer = StatusTimerTick
    Left = 16
    Top = 336
  end
  object FMapTimer: TTimer
    Interval = 150
    Enabled = False
    OnTimer = MapTimerTick
    Left = 16
    Top = 304
  end
  object FTabsPopup: TUiPopupMenu
    Left = 16
    Top = 264
    object FTabsPopupItem1: TMenuItem
      Caption = 'Перечитать файл с диска'
      OnClick = ReloadFileClick
      ShortCut = 0
    end
    object FTabsPopupItem2: TMenuItem
      Caption = '-'
      ShortCut = 0
    end
    object FTabsPopupItem3: TMenuItem
      Caption = 'Закрыть вкладку'
      OnClick = CloseTabClick
      ShortCut = 0
    end
    object FTabsPopupItem4: TMenuItem
      Caption = 'Закрыть остальные вкладки'
      OnClick = CloseAllTabsClick
      ShortCut = 0
    end
  end
  object FPopupMenu: TUiPopupMenu
    OnPopup = PopupMenuPopup
    Left = 16
    Top = 584
    object pmuSearch: TMenuItem
      Caption = 'Search {}'
      OnClick = SearchSelectedClick
    end
    object pmuSepSearch: TMenuItem
      Caption = '-'
    end
    object pmuDebug: TMenuItem
      Caption = 'Debug (RuntimeLog)'
      OnClick = DebugLineClick
    end
    object pmuSepDebug: TMenuItem
      Caption = '-'
    end
    object pmuRunToCursor: TMenuItem
      Caption = 'Run to cursor'#9'F4'
      OnClick = RunToCursorClick
    end
    object pmuAddWatch: TMenuItem
      Caption = 'Add watch'#9'Ctrl+F5'
      OnClick = AddWatchClick
    end
    object pmuBreakCond: TMenuItem
      Caption = 'Breakpoint condition...'
      OnClick = BreakCondClick
    end
    object pmuSepRun: TMenuItem
      Caption = '-'
    end
    object pmuUndo: TMenuItem
      Caption = '&Undo'
      ShortCut = 16474
      OnClick = EditClickEvent
    end
    object pmuRedo: TMenuItem
      Caption = '&Redo'
      ShortCut = 24666
      OnClick = EditClickEvent
    end
    object pmuSep1: TMenuItem
      Caption = '-'
    end
    object pmuCut: TMenuItem
      Caption = 'Cu&t'
      ShortCut = 16472
      OnClick = EditClickEvent
    end
    object pmuCopy: TMenuItem
      Caption = '&Copy'
      ShortCut = 16451
      OnClick = EditClickEvent
    end
    object pmuPaste: TMenuItem
      Caption = '&Paste'
      ShortCut = 16470
      OnClick = EditClickEvent
    end
    object pmuDelete: TMenuItem
      Caption = '&Delete'#9'Del'
      ShortCut = 0
      OnClick = EditClickEvent
    end
    object pmuSep2: TMenuItem
      Caption = '-'
    end
    object pmuSelectAll: TMenuItem
      Caption = 'Select &All'
      ShortCut = 16449
      OnClick = EditClickEvent
    end
    object pmuSepClear: TMenuItem
      Caption = '-'
    end
    object pmuClear: TMenuItem
      Caption = 'Clear'
      OnClick = ClearAllClick
    end
    object pmuSepCase: TMenuItem
      Caption = '-'
    end
    object pmuUpper: TMenuItem
      Caption = 'To UpperCase {}'
      OnClick = CaseConvertClick
    end
    object pmuLower: TMenuItem
      Caption = 'To LowerCase {}'
      OnClick = CaseConvertClick
    end
  end
  object FLogPopup: TUiPopupMenu
    OnPopup = LogPopupPopup
    Left = 16
    Top = 544
    object FLogPopupItem1: TMenuItem
      Caption = '&Undo'#9'Ctrl+Z'
      Tag = 1
      OnClick = LogPopupClick
    end
    object FLogPopupItem2: TMenuItem
      Caption = '-'
      Tag = 0
    end
    object FLogPopupItem3: TMenuItem
      Caption = 'Cu&t'#9'Ctrl+X'
      Tag = 2
      OnClick = LogPopupClick
    end
    object FLogPopupItem4: TMenuItem
      Caption = '&Copy'#9'Ctrl+C'
      Tag = 3
      OnClick = LogPopupClick
    end
    object FLogPopupItem5: TMenuItem
      Caption = '&Paste'#9'Ctrl+V'
      Tag = 4
      OnClick = LogPopupClick
    end
    object FLogPopupItem6: TMenuItem
      Caption = '&Delete'#9'Del'
      Tag = 5
      OnClick = LogPopupClick
    end
    object FLogPopupItem7: TMenuItem
      Caption = '-'
      Tag = 0
    end
    object FLogPopupItem8: TMenuItem
      Caption = 'Select &All'#9'Ctrl+A'
      Tag = 6
      OnClick = LogPopupClick
    end
  end
  object FToolbar: TPanel
    Align = alTop
    Height = 130
    BevelOuter = bvNone
    Color = 15790320
    object FLeftPanel: TPanel
      Width = 408
      Align = alLeft
      BevelOuter = bvNone
      object grpCompiler: TUiGroupBox
        Color = clPurple
        Align = alBottom
        Caption = 'Project'
        Height = 98
        object pnlCompilerIn: TPanel
          Color = clTeal
          Align = alTop
          BevelOuter = bvNone
          ParentFont = True
          Height = 33
          object btnCompileRun: TUiIconButton
            Left = 122
            Top = 0
            Width = 34
            Height = 34
            Hint = 'Собрать проект dcc32 и запустить, если без ошибок'
            ShowHint = True
            OnClick = btnCompileRunClick
          end
          object btnViewUnit: TUiIconButton
            Left = 2
            Top = 0
            Width = 34
            Height = 34
            Hint = 'View Unit - список модулей'
            ShowHint = True
            OnClick = ShowModulesClick
          end
          object btnViewForm: TUiIconButton
            Left = 42
            Top = 0
            Width = 34
            Height = 34
            Hint = 'View Form - список форм'
            ShowHint = True
            OnClick = ShowFormsClick
          end
          object btnNewForm: TUiIconButton
            Left = 82
            Top = 0
            Width = 34
            Height = 34
            Hint = 'New Form - новая форма'
            ShowHint = True
            OnClick = NewFormClick
          end
          object btnPause: TUiIconButton
            Left = 159
            Top = 0
            Width = 34
            Height = 34
            Hint = 'Program pause - остановить программу там, где она сейчас'
            ShowHint = True
            OnClick = ProgramPauseClick
          end
          object btnProgReset: TUiIconButton
            Left = 194
            Top = 0
            Width = 34
            Height = 34
            Hint = 'Program reset - остановить запущенную программу'
            ShowHint = True
            OnClick = ProgramResetClick
          end
          object btnTraceInto: TUiIconButton
            Left = 229
            Top = 0
            Width = 34
            Height = 34
            Hint = 'Trace into (F7)'
            ShowHint = True
            OnClick = TraceIntoClick
          end
          object btnStepOver: TUiIconButton
            Left = 264
            Top = 0
            Width = 34
            Height = 34
            Hint = 'Step over (F8)'
            ShowHint = True
            OnClick = StepOverClick
          end
          object btnArdVerify: TUiIconButton
            Left = 2
            Top = 0
            Width = 34
            Height = 34
            Hint = 'Verify - собрать скетч (arduino-cli compile)'
            ShowHint = True
            Visible = False
            OnClick = ArdVerifyClick
          end
          object btnArdUpload: TUiIconButton
            Left = 37
            Top = 0
            Width = 34
            Height = 34
            Hint = 'Upload - собрать скетч и загрузить в плату'
            ShowHint = True
            Visible = False
            OnClick = ArdUploadClick
          end
        end
        object pnlBuildKind: TPanel
          Align = alClient
          BevelOuter = bvNone
          ParentFont = True
          object cmbBuildKind: TUiComboBox
            Left = 8
            Top = 24
            Width = 96
            Style = csDropDownList
            ShowHint = True
            OnChange = cmbBuildKindChange
            Height = 21
          end
          object lblBuildTarget: TUiLabel
            Left = 8
            Top = 8
            Width = 129
            Height = 13
            Anchors = [akLeft, akTop, akRight]
            AutoSize = False
            ShowHint = True
          end
          object cmbArdPort: TUiComboBox
            Left = 110
            Top = 24
            Width = 160
            Height = 21
            Style = csDropDownList
            ShowHint = True
            Hint = 'Плата на USB, с которой работать (порт для Upload и Serial Monitor)'
            Visible = False
            OnChange = cmbArdPortChange
          end
          object cmbFbKind: TUiComboBox
            Left = 110
            Top = 24
            Width = 76
            Height = 21
            Style = csDropDownList
            ShowHint = True
            Hint = 'Вид результата FreeBASIC: GUI, Console, DLL'
            Visible = False
            OnChange = cmbFbBuildChange
          end
          object cmbRqComp: TUiComboBox
            Left = 110
            Top = 24
            Width = 84
            Height = 21
            Style = csDropDownList
            ShowHint = True
            Hint = 'Чем собирать программу RapidQ: rc.exe или FreeBASIC (Smart, Compat)'
            Visible = False
            OnChange = cmbRqCompChange
          end
          object cmbFbBits: TUiComboBox
            Left = 190
            Top = 24
            Width = 44
            Height = 21
            Style = csDropDownList
            ShowHint = True
            Hint = 'Разрядность FreeBASIC: 32 или 64 бит'
            Visible = False
            OnChange = cmbFbBuildChange
          end
        end
      end
      object pnlToolbarIn: TPanel
        Color = clGreen
        Align = alTop
        BevelOuter = bvNone
        ParentFont = True
        Height = 32
        object btnOpen: TUiIconButton
          Left = 2
          Top = 1
          Width = 34
          Height = 34
          Hint = 'Открыть файл'
          ShowHint = True
          OnClick = ToolbarButtonClickEvent
        end
        object btnSave: TUiIconButton
          Left = 37
          Top = 1
          Width = 34
          Height = 34
          Hint = 'Сохранить файл'
          ShowHint = True
          OnClick = ToolbarButtonClickEvent
        end
        object btnSavePrj: TUiIconButton
          Left = 72
          Top = 1
          Width = 34
          Height = 34
          Hint = 'Сохранить проект'
          ShowHint = True
          OnClick = ToolbarButtonClickEvent
        end
        object btnUndo: TUiIconButton
          Left = 117
          Top = 1
          Width = 34
          Height = 34
          Hint = 'Отменить'
          ShowHint = True
          OnClick = ToolbarButtonClickEvent
        end
        object btnCut: TUiIconButton
          Left = 152
          Top = 1
          Width = 34
          Height = 34
          Hint = 'Вырезать'
          ShowHint = True
          OnClick = ToolbarButtonClickEvent
        end
        object btnCopy: TUiIconButton
          Left = 187
          Top = 1
          Width = 34
          Height = 34
          Hint = 'Копировать'
          ShowHint = True
          OnClick = ToolbarButtonClickEvent
        end
        object btnPaste: TUiIconButton
          Left = 222
          Top = 1
          Width = 34
          Height = 34
          Hint = 'Вставить'
          ShowHint = True
          OnClick = ToolbarButtonClickEvent
        end
      end
    end
    object grpSearch: TUiGroupBox
      Align = alLeft
      Width = 344
      Caption = 'Search and replace'
      object pnlSearchIn: TPanel
        Align = alClient
        BevelOuter = bvNone
        ParentFont = True
        object cmbFind: TUiComboBox
          Left = 4
        end
        object BtnPrev: TUiButton
          Caption = '<-Find'
          Left = 110
          Top = 1
          Width = 46
          Height = 22
          OnClick = DoFindPrev
        end
        object BtnNext: TUiButton
          Caption = 'Find->'
          Left = 159
          Top = 1
          Width = 46
          Height = 22
          OnClick = DoFindNext
        end
        object chkList: TUiCheckBox
          Top = 4
          Width = 40
          Caption = 'List'
        end
        object cmbReplace: TUiComboBox
          Left = 4
          Top = 26
        end
        object BtnRepl: TUiButton
          Caption = 'Replace'
          Left = 110
          Top = 25
          Width = 54
          Height = 22
          OnClick = DoReplace
        end
        object BtnAll: TUiButton
          Caption = 'All'
          Left = 167
          Top = 25
          Width = 34
          Height = 22
          OnClick = DoReplaceAll
        end
        object UndoBtn: TUiButton
          Caption = 'Undo'
          Left = 204
          Top = 25
          Width = 46
          Height = 22
          OnClick = UndoReplaceAllClick
          ParentFont = False
          ShowHint = True
          Hint = 'Отменить массовую замену (All)'
        end
        object cmbMode: TUiComboBox
          Left = 8
          Top = 56
          Style = csDropDownList
          Width = 72
          Height = 21
        end
        object chkCase: TUiCheckBox
          Top = 56
          Caption = 'Case'
          Left = 88
          Width = 44
          Height = 17
        end
        object btnFindInFiles: TUiButton
          Top = 56
          Height = 22
          Caption = 'Find In Files'
          OnClick = FindInFilesClick
          Left = 136
          Width = 77
        end
        object cmbScope: TUiComboBox
          Top = 56
          Style = csDropDownList
          Left = 224
          Width = 80
          Height = 21
        end
      end
    end
    object grpPalette: TUiGroupBox
      Align = alClient
      Caption = 'Components'
      object pnlPaletteIn: TPanel
        Align = alClient
        BevelOuter = bvNone
        ParentFont = True
      end
    end
  end
  object FMenuBar: TUiMenuBar
    Menu = MainMenu1
  end
  object FRightPanel: TPanel
    BevelOuter = bvNone
    Caption = ''
    Align = alRight
    object FSplitBar: TPanel
      Caption = ''
      Width = 5
      BevelOuter = bvRaised
      Cursor = crHSplit
      Align = alLeft
      OnMouseDown = SplitBarMouseDown
      OnMouseMove = SplitBarMouseMove
      OnMouseUp = SplitBarMouseUp
    end
    object FRightPages: TUiPageControl
      Align = alClient
      ActivePage = FTabSubList
      object FTabSubList: TTabSheet
        Caption = 'SubList'
        object lvSubList: TUiListView
          Align = alClient
          ViewStyle = vsReport
          ReadOnly = True
          RowSelect = True
          HideSelection = False
          Columns = <
            item
              Caption = 'Name'
              Width = 180
            end
            item
              Caption = 'Begin'
              Width = 50
            end
            item
              Caption = 'End'
              Width = 50
            end>
          OnDblClick = SubListDblClick
          ParentFont = False
          Font.Name = 'Tahoma'
          Font.Height = -15
        end
      end
      object FTabObjects: TTabSheet
        Caption = 'Objects'
        object FObjSource: TLabel
          Align = alBottom
          Caption = ''
          OnClick = ObjSourceClick
        end
        object BtnPnl: TPanel
          Top = 0
          Height = 30
          BevelOuter = bvNone
          Align = alTop
          object FObjSnapBtn: TUiButton
            Left = 4
            Top = 3
            Height = 24
            Width = 115
            Caption = 'Show live values'
            ShowHint = True
            OnClick = ObjSnapBtnClick
          end
          object FObjDsgBtn: TUiButton
            Top = 3
            Height = 24
            Width = 85
            Caption = 'Design form'
            ShowHint = True
            Hint = 'Открыть форму в визуальном конструкторе'
            OnClick = DesignFormClick
          end
          object FObjDsgShowBtn: TUiButton
            Top = 3
            Height = 24
            Width = 75
            Caption = 'Hide form'
            Enabled = False
            ShowHint = True
            Hint = 'Спрятать или показать окно конструктора, не закрывая его'
            OnClick = DsgShowHideClick
          end
          object FObjMoveBtn: TUiButton
            Top = 3
            Height = 24
            Width = 110
            Caption = 'Перенести в .dfm'
            ShowHint = True
            OnClick = ObjMoveClick
          end
        end
        object FObjTree: TUiTreeView
          Height = 220
          Align = alTop
          ReadOnly = True
          HideSelection = False
          OnClick = ObjTreeClick
        end
        object Split: TSplitter
          Height = 4
          Align = alTop
        end
        object FObjHeader: TPanel
          Height = 22
          Align = alTop
          BevelOuter = bvLowered
          Alignment = taLeftJustify
          Caption = ''
        end
        object FObjPages: TUiPageControl
          Align = alClient
          object FObjPagesSheet1: TTabSheet
            Caption = 'Properties'
            object FObjProps: TUiListView
              Align = alClient
              ViewStyle = vsReport
              ReadOnly = True
              RowSelect = True
              GridLines = True
              HideSelection = False
              Columns = <
                item
                  Caption = 'Свойство'
                  Width = 120
                end
                item
                  Caption = 'Значение'
                  Width = 180
                end
                item
                  Caption = 'Строка кода'
                  Width = 80
                end>
              OnClick = ObjPropsClick
              OnDblClick = ObjPropsDblClick
              OnKeyDown = ObjPropsKeyDown
              object FObjEdit: TUiEdit
                Visible = False
                OnKeyDown = ObjEditKeyDown
                OnExit = ObjEditExit
                Left = 128
                Top = 0
                Width = 72
                Height = 21
              end
              object FObjCombo: TUiComboBox
                Visible = False
                DropDownCount = 16
                OnKeyDown = ObjEditKeyDown
                OnExit = ObjEditExit
                Left = 264
                Top = 0
                Width = 41
                Height = 21
              end
              object FObjSetList: TCheckListBox
                Visible = False
                OnKeyDown = ObjEditKeyDown
                OnExit = ObjEditExit
                Left = 208
                Top = 0
                Width = 41
                Height = 24
                OnClick = FObjSetListClick
              end
            end
          end
          object FObjPagesSheet2: TTabSheet
            Caption = 'Events'
            object FObjEvents: TUiListView
              Align = alClient
              ViewStyle = vsReport
              ReadOnly = True
              RowSelect = True
              GridLines = True
              HideSelection = False
              Columns = <
                item
                  Caption = 'Свойство'
                  Width = 120
                end
                item
                  Caption = 'Значение'
                  Width = 180
                end>
              OnDblClick = ObjEventsDblClick
            end
          end
        end
      end
      object FTabCode: TTabSheet
        Caption = 'Code'
        object FCodeTree: TUiTreeView
          Align = alClient
          ReadOnly = True
          HideSelection = False
          OnClick = CodeTreeClick
        end
      end
      object FTabIncludes: TTabSheet
        Caption = 'Includes'
        object FIncTree: TUiTreeView
          Align = alClient
          ReadOnly = True
          HideSelection = False
        end
      end
    end
  end
  object FObjRefreshTimer: TTimer
    Left = 88
    Top = 224
    Enabled = False
    Interval = 100
    OnTimer = ObjRefreshRetryTick
  end
  object FDsgJumpTimer: TTimer
    Left = 136
    Top = 232
    Enabled = False
    Interval = 150
    OnTimer = DsgJumpTimerTick
  end
  object FBusyHide: TTimer
    Left = 176
    Top = 232
    Enabled = False
    OnTimer = BusyHideTick
  end
  object FRunTimer: TTimer
    Left = 224
    Top = 232
    Enabled = False
    Interval = 500
    OnTimer = RunTimerTick
  end
  object FOwnCaretTimer: TTimer
    Left = 464
    Top = 368
    Enabled = False
    OnTimer = OwnCaretTick
  end
  object FDsgMenu: TUiPopupMenu
    Left = 264
    Top = 240
    AutoHotkeys = maManual
    object FDsgMenuGrp1: TMenuItem
      Caption = 'Edit'
      object FDsgMiUndo: TMenuItem
        Caption = 'Undo'
        ShortCut = 16474
        OnClick = DsgMenuClick
      end
      object FDsgMenuGrp1Item1: TMenuItem
        Caption = '-'
        ShortCut = 0
        OnClick = DsgMenuClick
      end
      object FDsgMiCut: TMenuItem
        Caption = 'Cut'
        ShortCut = 16472
        OnClick = DsgMenuClick
      end
      object FDsgMiCopy: TMenuItem
        Caption = 'Copy'
        ShortCut = 16451
        OnClick = DsgMenuClick
      end
      object FDsgMiPaste: TMenuItem
        Caption = 'Paste'
        ShortCut = 16470
        OnClick = DsgMenuClick
      end
      object FDsgMiDelete: TMenuItem
        Caption = 'Delete'
        ShortCut = 46
        OnClick = DsgMenuClick
      end
    end
    object FDsgMenuGrp2: TMenuItem
      Caption = 'Control'
      object FDsgMiFront: TMenuItem
        Caption = 'Bring to Front'
        ShortCut = 0
        OnClick = DsgMenuClick
      end
      object FDsgMiBack: TMenuItem
        Caption = 'Send to Back'
        ShortCut = 0
        OnClick = DsgMenuClick
      end
    end
    object FDsgMiRename: TMenuItem
      Caption = 'Rename Component...'
      OnClick = DsgMenuClick
    end
    object FDsgMiReplace: TMenuItem
      Caption = 'Replace Components...'
      OnClick = DsgMenuClick
    end
    object FDsgMiCopyNames: TMenuItem
      Caption = 'Copy Component Names'
      OnClick = DsgMenuClick
    end
    object FDsgMenuGrpAlign: TMenuItem
      Caption = 'Align'
      object FDsgMiAlignLeft: TMenuItem
        Caption = 'Left Edges'
        OnClick = DsgMenuClick
      end
      object FDsgMiAlignRight: TMenuItem
        Caption = 'Right Edges'
        OnClick = DsgMenuClick
      end
      object FDsgMiAlignTop: TMenuItem
        Caption = 'Tops'
        OnClick = DsgMenuClick
      end
      object FDsgMiAlignBottom: TMenuItem
        Caption = 'Bottoms'
        OnClick = DsgMenuClick
      end
      object FDsgMenuGrpAlignSep: TMenuItem
        Caption = '-'
      end
      object FDsgMiAlignWidth: TMenuItem
        Caption = 'Same Width'
        OnClick = DsgMenuClick
      end
      object FDsgMiAlignHeight: TMenuItem
        Caption = 'Same Height'
        OnClick = DsgMenuClick
      end
    end
    object FDsgMenuGrp3: TMenuItem
      Caption = 'Menu'
      object FDsgMiItemIns: TMenuItem
        Caption = 'Insert'#9'Ins'
        ShortCut = 0
        OnClick = DsgMenuClick
      end
      object FDsgMiItemDel: TMenuItem
        Caption = 'Delete'#9'Del'
        ShortCut = 0
        OnClick = DsgMenuClick
      end
      object FDsgMenuGrp3Item1: TMenuItem
        Caption = '-'
        ShortCut = 0
        OnClick = DsgMenuClick
      end
      object FDsgMiItemSub: TMenuItem
        Caption = 'Create Submenu'#9'Ctrl+Right'
        ShortCut = 0
        OnClick = DsgMenuClick
      end
      object FDsgMenuGrp3Item2: TMenuItem
        Caption = '-'
        ShortCut = 0
        OnClick = DsgMenuClick
      end
      object FDsgMiMenuSelect: TMenuItem
        Caption = 'Select Menu...'
        ShortCut = 0
        OnClick = DsgMenuClick
      end
      object FDsgMiMenuEdit: TMenuItem
        Caption = 'Edit Menu...'
        ShortCut = 0
        OnClick = DsgMenuClick
      end
      object FDsgMiMenuSave: TMenuItem
        Caption = 'Save As Template...'
        ShortCut = 0
        OnClick = DsgMenuClick
      end
      object FDsgMiMenuWizard: TMenuItem
        Caption = 'Insert From Template...'
        ShortCut = 0
        OnClick = DsgMenuClick
      end
      object FDsgMiMenuDelTpl: TMenuItem
        Caption = 'Delete Templates...'
        ShortCut = 0
        OnClick = DsgMenuClick
      end
      object FDsgMiMenuRes: TMenuItem
        Caption = 'Insert From Resource...'
        ShortCut = 0
        OnClick = DsgMenuClick
      end
    end
    object FDsgMiLiveSep: TMenuItem
      Caption = '-'
    end
    object FDsgMiLiveView: TMenuItem
      Caption = 'Show .dfm values'
      OnClick = DsgMenuClick
    end
  end
end
