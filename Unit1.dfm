object Form1: TForm1
  BorderIcons = [biSystemMenu, biMinimize, biMaximize]
  Left = 97
  Top = 242
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
      Height = 4
      Cursor = crVSplit
      Align = alBottom
      Color = $00CD6700
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
          'Runtime log'
          'Git log')
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
        object CompLogEdit: TEdLogView
          Left = 0
          Top = 0
          Width = 0
          Height = 105
          Align = alClient
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          ShowGutter = False
          TabOrder = 0
          TabStop = True
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
        object ErrLogEdit: TEdLogView
          Left = 0
          Top = 0
          Width = 0
          Height = 105
          Align = alClient
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -14
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          ShowGutter = False
          TabOrder = 0
          TabStop = True
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
        object LogEdit: TEdLogView
          Left = 0
          Top = 0
          Width = 0
          Height = 105
          Align = alClient
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -14
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          ShowGutter = False
          TabOrder = 0
          TabStop = True
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
        object RuntimeLog: TEdLogView
          Left = 0
          Top = 0
          Width = 0
          Height = 105
          Align = alClient
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -14
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          ShowGutter = False
          TabOrder = 0
          TabStop = True
        end
      end
      object pnlGitLog: TPanel
        Left = 0
        Top = 22
        Width = 0
        Height = 105
        Align = alClient
        BevelOuter = bvNone
        ParentBackground = False
        TabOrder = 5
        Visible = False
        object GitLogEdit: TEdLogView
          Left = 0
          Top = 0
          Width = 0
          Height = 105
          Align = alClient
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -14
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          ShowGutter = False
          TabOrder = 0
          TabStop = True
        end
      end
    end
    object FTabs: TUiTabControl
      Top = 0
      Height = 30
      MultiLine = True
      ParentFont = False
      Font.Name = 'Tahoma'
      Font.Size = 10
      Align = alTop
      OwnerDraw = True
      Style = tsButtons
      OnMouseDown = TabsMouseDown
      PopupMenu = FTabsPopup
    end
    object FLeftHost: TPanel
      BevelWidth = 0
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
      object FSubLabel: TLabel
        Align = alRight
        AutoSize = True
        Layout = tlCenter
        Transparent = False
        ParentColor = True
        ParentFont = True
        ShowAccelChar = False
        Cursor = crDefault
        ShowHint = True
        Visible = False
      end
    end
    object FFarSpacer: TPanel
      Visible = False
      BevelOuter = bvNone
      Caption = ''
      ParentBackground = False
      Color = clNavy
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
      end
      item
        Width = 70
      end
      item
        Style = psOwnerDraw
        Width = 250
      end>
    OnDrawPanel = StatusBar1DrawPanel
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
      Align = alLeft
      OnClick = MarksBoxClick
      OnDblClick = MarksBoxDblClick
      OnMouseDown = MarksBoxMouseDown
      OnPaint = MarksBoxPaint
    end
  end
  object RichEdit1: TEdHostEdit
    Left = 57
    Top = 8
    Width = 3000
    Height = 457
    Align = alLeft
    Color = clBtnShadow
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGray
    Font.Height = -15
    Font.Name = 'Source Code Pro'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
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
        object mNewText: TMenuItem
          Caption = 'Text File'
          OnClick = NewFileClick
          ShortCut = 0
          Hint = '.txt'
        end
        object mNewPascal: TMenuItem
          Caption = 'Pascal'
          ShortCut = 0
          object mNewPasApp: TMenuItem
            Caption = 'Application'
            OnClick = NewPasAppClick
            ShortCut = 0
          end
          object mNewPasForm: TMenuItem
            Caption = 'Form'
            OnClick = NewPasFormClick
            ShortCut = 0
          end
          object mNewPasUnit: TMenuItem
            Caption = 'Unit'
            OnClick = NewPasUnitClick
            ShortCut = 0
          end
          object mNewPasDataMod: TMenuItem
            Caption = 'Data Module'
            OnClick = NewPasDataModuleClick
            ShortCut = 0
          end
          object mNewPasFrame: TMenuItem
            Caption = 'Frame'
            OnClick = NewPasFrameClick
            ShortCut = 0
          end
          object mNewPasDll: TMenuItem
            Caption = 'DLL'
            OnClick = NewPasDllClick
            ShortCut = 0
          end
          object mNewPasConsole: TMenuItem
            Caption = 'Console Application'
            OnClick = NewPasConsoleClick
            ShortCut = 0
          end
          object mNewPasSep: TMenuItem
            Caption = '-'
            ShortCut = 0
          end
          object mNewPasOther: TMenuItem
            Caption = 'Other...'
            OnClick = NewPasOtherClick
            ShortCut = 0
          end
        end
        object mNewRq: TMenuItem
          Caption = 'RapidQ'
          ShortCut = 0
          object mNewRqApp: TMenuItem
            Caption = 'Application'
            OnClick = NewRqAppClick
            ShortCut = 0
          end
          object mNewRqForm: TMenuItem
            Caption = 'Form'
            OnClick = NewRqFormClick
            ShortCut = 0
          end
          object mNewRqInc: TMenuItem
            Caption = 'Include (.inc)'
            OnClick = NewRqIncClick
            ShortCut = 0
          end
          object mNewRqConsole: TMenuItem
            Caption = 'Console Application'
            OnClick = NewRqConsoleClick
            ShortCut = 0
          end
          object mNewRqCgi: TMenuItem
            Caption = 'CGI Application'
            OnClick = NewRqCgiClick
            ShortCut = 0
          end
          object mNewRqSep: TMenuItem
            Caption = '-'
            ShortCut = 0
          end
          object mNewRqOther: TMenuItem
            Caption = 'Other...'
            OnClick = NewRqOtherClick
            ShortCut = 0
          end
        end
        object mNewFb: TMenuItem
          Caption = 'FreeBASIC'
          ShortCut = 0
          object mNewFbConsole: TMenuItem
            Caption = 'Console Application'
            OnClick = NewFbConsoleClick
            ShortCut = 0
          end
          object mNewFbGui: TMenuItem
            Caption = 'GUI Application'
            OnClick = NewFbGuiClick
            ShortCut = 0
          end
          object mNewFbDll: TMenuItem
            Caption = 'DLL'
            OnClick = NewFbDllClick
            ShortCut = 0
          end
        end
        object mNewBasic: TMenuItem
          Caption = 'BASIC File'
          OnClick = NewFileClick
          ShortCut = 0
          Hint = '.bas'
        end
        object mNewCpp: TMenuItem
          Caption = 'C++ File'
          OnClick = NewFileClick
          ShortCut = 0
          Hint = '.cpp'
        end
        object mNewHtml: TMenuItem
          Caption = 'HTML File'
          OnClick = NewFileClick
          ShortCut = 0
          Hint = '.html'
        end
        object mNewSql: TMenuItem
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
      object EncMenu: TMenuItem
        Caption = '&Encoding'
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
      object mViewFmt: TMenuItem
        Caption = 'Просмотр по формату'
        Enabled = False
        OnClick = FmtViewClick
        ShortCut = 123
      end
      object FWv2ViewItem: TMenuItem
        Caption = 'Просмотр в WebView2 (Chromium)'
        OnClick = Wv2ViewClick
      end
      object FEdPreviewItem: TMenuItem
        Caption = 'Свой редактор - проба (0.7.3)'
        OnClick = EdPreviewClick
      end
      object FDsgDescItem: TMenuItem
        Caption = 'Описание классов Delphi 7 - записать и сверить (0.8)'
        OnClick = DsgDescWriteClick
      end
      object mViewSplitSep: TMenuItem
        Caption = '-'
      end
      object mViewSplitV: TMenuItem
        Caption = 'Разделить по вертикали'
        RadioItem = True
        OnClick = SplitVClick
      end
      object mViewSplitH: TMenuItem
        Caption = 'Разделить по горизонтали'
        RadioItem = True
        OnClick = SplitHClick
      end
      object mViewSplitOff: TMenuItem
        Caption = 'Без разделения'
        Checked = True
        RadioItem = True
        OnClick = SplitOffClick
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
        object mPrjTidyIni: TMenuItem
          Caption = 'Tidy editor.ini...'
          OnClick = TidyIniClick
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
      object mPrjMoveUnused: TMenuItem
        Caption = 'Move Unused Files...'
        Hint = 'Файлы сборки (.pas, .dfm, .dcu, .res и др.), которые .dpr не использует, - в папку unused рядом с .dpr'
        OnClick = MoveUnusedFilesClick
      end
      object mProjectFixPaths: TMenuItem
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
        Caption = 'Remove missing files from list'
        Hint = 'Убрать из списка окна, файлов которых нет на диске (с красным крестиком)'
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
    object FUtilMenu: TMenuItem
      Caption = 'Started Util'
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
    object RosMenu: TMenuItem
      Caption = 'ReactOS'
      AutoHotkeys = maManual
      object mRosRunImage: TMenuItem
        Caption = 'Run Image (QEMU)'
        OnClick = RosRunImageClick
      end
      object mRosRufusWrite: TMenuItem
        Caption = 'Write Image to USB (Rufus)...'
        OnClick = RufusWriteClick
      end
      object mRosSep1: TMenuItem
        Caption = '-'
      end
      object mRosInstallRosBE: TMenuItem
        Caption = 'Install RosBE 2.2.1 (reactosVG14)...'
        OnClick = RosInstallRosBEClick
      end
      object mRosInstall7Zip: TMenuItem
        OnClick = RosInstall7ZipClick
      end
      object mRosInstallQemu: TMenuItem
        OnClick = RosInstallQemuClick
      end
      object mRosInstallRufus: TMenuItem
        Caption = 'Install Rufus (tools\rufus)...'
        OnClick = RufusInstallClick
      end
      object mRosSep2: TMenuItem
        Caption = '-'
      end
      object mRosGitTerminal: TMenuItem
        Caption = 'Git Terminal (Git Bash)'
        OnClick = GitTerminalClick
      end
      object mRosGitInstall: TMenuItem
        OnClick = GitInstallClick
      end
      object mRosSep3: TMenuItem
        Caption = '-'
      end
      object mRosUpdatePciIds: TMenuItem
        Caption = 'Update pci.ids...'
        OnClick = RosUpdatePciIdsClick
      end
      object mRosGenPciInf: TMenuItem
        Caption = 'Generate System Devices INF...'
        OnClick = RosGenPciInfClick
      end
      object mRosSep4: TMenuItem
        Caption = '-'
      end
      object ToolsMenu: TMenuItem
        Caption = 'Download Build Tools'
        AutoHotkeys = maManual
      end
    end
    object RepoMenu: TMenuItem
      Caption = 'Repository'
      AutoHotkeys = maManual
      object mRepoSep1: TMenuItem
        Caption = '-'
        Hint = ''
      end
      object mRepoFetch: TMenuItem
        Caption = 'Fetch'
        Hint = 'git fetch --all --prune'
        OnClick = GitFetchClick
      end
      object mRepoPull: TMenuItem
        Caption = 'Pull'
        Hint = 'git pull (merge)'
        OnClick = GitPullClick
      end
      object mRepoPush: TMenuItem
        Caption = 'Push'
        Hint = 'git push (ветки на сервере нет - опубликовать)'
        OnClick = GitPushClick
      end
      object mRepoHistory: TMenuItem
        Caption = 'Commits history...'
        Hint = 'История коммитов текущей ветки'
        OnClick = GitHistoryClick
      end
      object mRepoSep2: TMenuItem
        Caption = '-'
        Hint = ''
      end
      object mRepoViewOnGitHub: TMenuItem
        Caption = 'View on GitHub'
        Hint = 'Страница репозитория в браузере'
        OnClick = GitViewOnGitHubClick
      end
      object mRepoExplorer: TMenuItem
        Caption = 'Show in Explorer'
        Hint = 'Папка репозитория в Проводнике'
        OnClick = GitExplorerClick
      end
      object mRepoSep3: TMenuItem
        Caption = '-'
        Hint = ''
      end
      object mRepoSep4: TMenuItem
        Caption = '-'
        Hint = ''
      end
      object mRepoNew: TMenuItem
        Caption = 'New Repository...'
        Hint = 'Создать репозиторий git в папке (git init)'
        OnClick = GitNewRepoClick
      end
      object mRepoAddLocal: TMenuItem
        Caption = 'Add Local Repository...'
        Hint = 'Выбрать папку с репозиторием - с ним работают панель Git и это меню'
        OnClick = GitAddRepoClick
      end
      object mRepoClone: TMenuItem
        Caption = 'Clone Repository...'
        Hint = 'Скачать репозиторий с GitHub (git clone)'
        OnClick = GitCloneClick
      end
      object mRepoUseProject: TMenuItem
        Caption = 'Use Repository of Current Project'
        Hint = 'Снова репозиторий открытого проекта (выбор вручную снимается)'
        OnClick = GitUseProjectRepoClick
      end
      object mRepoCreateProject: TMenuItem
        Caption = 'Create Project from Repository...'
        Hint = 'Проект unIDE на основе текущего репозитория: окно New Project с его папкой'
        OnClick = GitCreateProjectClick
      end
      object mRepoCommit: TMenuItem
        Caption = 'Commit...'
        Hint = 'Окно Commit: изменения, разница, заголовок и описание'
        OnClick = GitCommitClick
      end
      object mRepoGitBash: TMenuItem
        Caption = 'Open in Git Bash'
        Hint = 'Терминал Git Bash в папке репозитория'
        OnClick = GitBashClick
      end
      object mRepoSettings: TMenuItem
        Caption = 'Repository Settings...'
        Hint = 'Адрес remote origin (git remote set-url)'
        OnClick = GitRepoSettingsClick
      end
      object mRepoDelete: TMenuItem
        Caption = 'Delete Local Repository...'
        Hint = 'Папку текущего репозитория - в корзину (на сервере он остаётся)'
        OnClick = GitDeleteRepoClick
      end
    end
    object BranchMenu: TMenuItem
      Caption = 'Branch'
      AutoHotkeys = maManual
      object mBranchSep1: TMenuItem
        Caption = '-'
        Hint = ''
      end
      object mBranchSep2: TMenuItem
        Caption = '-'
        Hint = ''
      end
      object mBranchSep3: TMenuItem
        Caption = '-'
        Hint = ''
      end
      object mBranchViewOnGitHub: TMenuItem
        Caption = 'View Branch on GitHub'
        Hint = 'Ветка на GitHub в браузере'
        OnClick = GitViewBranchClick
      end
      object mBranchSep4: TMenuItem
        Caption = '-'
        Hint = ''
      end
      object mBranchNew: TMenuItem
        Caption = 'New Branch...'
        Hint = 'Новая ветка от текущего коммита и переход на неё (git checkout -b)'
        OnClick = GitNewBranchClick
      end
      object mBranchSwitch: TMenuItem
        Caption = 'Switch Branch...'
        Hint = 'Перейти на другую ветку (git checkout)'
        OnClick = GitSwitchBranchClick
      end
      object mBranchRename: TMenuItem
        Caption = 'Rename Branch...'
        Hint = 'Переименовать текущую ветку (git branch -m)'
        OnClick = GitRenameBranchClick
      end
      object mBranchDelete: TMenuItem
        Caption = 'Delete Branch...'
        Hint = 'Удалить локальную ветку (git branch -d)'
        OnClick = GitDeleteBranchClick
      end
      object mBranchDiscardAll: TMenuItem
        Caption = 'Discard All Changes...'
        Hint = 'Отменить все изменения: файлы - как в последнем коммите, новые - в корзину'
        OnClick = GitDiscardAllClick
      end
      object mBranchStash: TMenuItem
        Caption = 'Stash All Changes'
        Hint = 'Убрать все изменения (и новые файлы) в stash (git stash push -u)'
        OnClick = GitStashClick
      end
      object mBranchStashRestore: TMenuItem
        Caption = 'Restore Stash...'
        Hint = 'Вернуть изменения из stash (git stash pop)'
        OnClick = GitStashRestoreClick
      end
      object mBranchStashDrop: TMenuItem
        Caption = 'Drop Stash...'
        Hint = 'Удалить запись stash (git stash drop)'
        OnClick = GitStashDropClick
      end
      object mBranchHidden: TMenuItem
        Caption = 'Hidden Local Changes...'
        Hint = 'Файлы, чьи изменения скрыты (Ignore - скрыть свои изменения, skip-worktree): вернуть в список изменений'
        OnClick = GitHiddenClick
      end
      object mBranchTracked: TMenuItem
        Caption = 'Tracked but Ignored Files...'
        Hint = 'Файлы в репозитории, которые подходят под .gitignore: оставить (исключение в .gitignore) или убрать из репозитория (git rm --cached)'
        OnClick = GitTrackedClick
      end
      object mBranchUpdateFromDefault: TMenuItem
        Caption = 'Update from Default Branch'
        Hint = 'Влить в текущую ветку основную ветку сервера (git merge origin/<основная>)'
        OnClick = GitUpdateFromDefaultClick
      end
      object mBranchMerge: TMenuItem
        Caption = 'Merge into Current Branch...'
        Hint = 'Влить выбранную ветку в текущую (git merge)'
        OnClick = GitMergeClick
      end
      object mBranchMergeInto: TMenuItem
        Caption = 'Merge Current Branch Into...'
        Hint = 'Влить текущую ветку в другую (например mainTest в main) и отправить ту на сервер'
        OnClick = GitMergeIntoClick
      end
      object mBranchCompare: TMenuItem
        Caption = 'Compare Branches...'
        Hint = 'Сравнить две ветки: коммиты, которые есть только в одной из них, и разные файлы'
        OnClick = GitCompareClick
      end
      object mBranchUnmerged: TMenuItem
        Caption = 'Commits Not in Current Branch...'
        Hint = 'Коммиты всех веток, которых нет в текущей: перенести (cherry-pick), влить ветку, удалить ветку'
        OnClick = GitUnmergedClick
      end
      object mBranchPullRequest: TMenuItem
        Caption = 'Create Pull Request'
        Hint = 'Страница нового pull request для текущей ветки на GitHub'
        OnClick = GitPullRequestClick
      end
    end
    object mUtils: TMenuItem
      Caption = '&Utils'
      object mIncManager: TMenuItem
        Caption = 'IncManager...'
        OnClick = IncManagerClick
      end
      object mFindInc: TMenuItem
        Caption = 'Find inc file...'
        OnClick = FindIncClick
      end
      object mInstallPkg: TMenuItem
        Caption = 'Install Delphi 7 package (.dpk)...'
        OnClick = InstallPackageClick
      end
      object mLazPrep: TMenuItem
        Caption = 'Lazarus: prepare sources (UTF-8)'
        Hint = 'Исходники проекта из папки текущего файла - в папку laz в UTF-8 для сборки Lazarus (шаг 1.2)'
        OnClick = LazPrepClick
      end
      object mUtilsSep1: TMenuItem
        Caption = '-'
      end
      object mFar: TMenuItem
        Caption = 'unIDE FAR'
        ShortCut = 121
        OnClick = FarMenuClick
      end
    end
    object mOptions: TMenuItem
      Caption = '&Options'
      object mOptionsIde: TMenuItem
        Caption = 'IDE Options...'
        OnClick = mOptionsClick
      end
      object FHlViewItem: TMenuItem
        Caption = 'Highlighting'
        OnClick = HighlightMenuFill
      end
      object FFarColorsItem: TMenuItem
        Caption = 'unIDE FAR - Files highlighting...'
        OnClick = FarColorsClick
      end
      object FFarPaletteItem: TMenuItem
        Caption = 'unIDE FAR - Colors...'
        OnClick = FarPaletteClick
      end
    end
    object mHelp: TMenuItem
      Caption = '&Help'
      object mHelpUnide: TMenuItem
        Caption = '&unIDE manual'
        Hint = 'Руководство пользователя unIDE (unide_ref\help\unide.chm)'
        OnClick = mHelpUnideClick
      end
      object mHelpGit: TMenuItem
        Caption = '&Git'
        OnClick = mHelpGitClick
      end
      object mHelpQemu: TMenuItem
        Caption = '&QEMU'
        OnClick = mHelpQemuClick
      end
      object mHelpRosbe: TMenuItem
        Caption = 'Ros&BE'
        OnClick = mHelpRosbeClick
      end
      object mHelpRq: TMenuItem
        Caption = '&RapidQ'
        Hint = 'Справка RapidQ: rapidq_ref\help\rapidq.chm (F1 - по слову под кареткой)'
        object mHelpRqContents: TMenuItem
          Tag = 1
          Caption = '&Contents'
          OnClick = mHelpRqClick
        end
        object mHelpRqComps: TMenuItem
          Tag = 2
          Caption = 'Components (Appendix &A)'
          OnClick = mHelpRqClick
        end
        object mHelpRqCustom: TMenuItem
          Tag = 3
          Caption = 'Custom components (Appendix &B)'
          OnClick = mHelpRqClick
          Hint = 'Компоненты из rapidq_ref\inc (TYPE ... EXTENDS)'
        end
        object mHelpRqIndex: TMenuItem
          Tag = 4
          Caption = 'Keyword &index'
          OnClick = mHelpRqClick
        end
        object mHelpRqFuncs: TMenuItem
          Tag = 6
          Caption = 'Include &functions (Appendix D)'
          OnClick = mHelpRqClick
          Hint = 'Функции RQProc.inc: Windows API и процедуры старых inc, по файлам'
        end
        object mHelpWinApi: TMenuItem
          Tag = 7
          Caption = '&Windows API reference (Microsoft)'
          OnClick = mHelpRqClick
          Hint = 'https://learn.microsoft.com/en-us/windows/win32/api/ - в браузере'
        end
        object mHelpRqSep: TMenuItem
          Caption = '-'
        end
        object mHelpRqHtml: TMenuItem
          Tag = 5
          Caption = '&HTML pages in browser'
          OnClick = mHelpRqClick
          Hint = 'rapidq_ref\html_doc\contents.html - та же справка страницами HTML'
        end
      end
      object mHelpFb: TMenuItem
        Caption = '&FreeBASIC'
      end
      object mHelpSep: TMenuItem
        Caption = '-'
      end
      object mHelpAbout: TMenuItem
        Caption = '&About...'
        OnClick = mHelpClick
      end
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
  object FMemTimer: TTimer
    OnTimer = MemTimerTick
    Left = 48
    Top = 304
  end
  object FTabsPopup: TUiPopupMenu
    Left = 16
    Top = 264
    object FTabsReload: TMenuItem
      Caption = 'Перечитать файл с диска'
      OnClick = ReloadFileClick
      ShortCut = 0
    end
    object FHlTabItem: TMenuItem
      Caption = 'Подсветка'
      OnClick = HighlightMenuFill
    end
    object FTabsSep1: TMenuItem
      Caption = '-'
      ShortCut = 0
    end
    object FTabsClose: TMenuItem
      Caption = 'Закрыть вкладку'
      OnClick = CloseTabClick
      ShortCut = 0
    end
    object FTabsCloseOthers: TMenuItem
      Caption = 'Закрыть остальные вкладки'
      OnClick = CloseAllTabsClick
      ShortCut = 0
    end
    object FDelTabItem: TMenuItem
      Caption = 'Удалить файл (в Корзину)'
      OnClick = DeleteFileClick
    end
    object FTabsSep2: TMenuItem
      Caption = '-'
      ShortCut = 0
    end
    object FTabsToSplit: TMenuItem
      Caption = 'Во второй панели'
      OnClick = TabToSplitClick
      ShortCut = 0
    end
  end
  object FPopupMenu: TUiPopupMenu
    OnPopup = PopupMenuPopup
    Left = 16
    Top = 584
    object pmuFmtText: TMenuItem
      Caption = 'Как текст'
      RadioItem = True
      Visible = False
      OnClick = FmtModeClick
    end
    object pmuFmtFormat: TMenuItem
      Caption = 'По формату'#9'F12'
      RadioItem = True
      Visible = False
      OnClick = FmtModeClick
    end
    object pmuSepFmt: TMenuItem
      Caption = '-'
      Visible = False
    end
    object pmuSearch: TMenuItem
      Caption = 'Search {}'
      OnClick = SearchSelectedClick
    end
    object pmuMatchList: TMenuItem
      Caption = 'Список вхождений {}'
      OnClick = MatchListWordClick
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
    object pmuNoGuides: TMenuItem
      Caption = 'Очистить формат'
      Hint = 'Не рисовать вертикальные линии отступов в этой вкладке'
      OnClick = NoGuidesClick
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
  object FFmtPopup: TUiPopupMenu
    OnPopup = FmtPopupPopup
    Left = 16
    Top = 616
    object fmpText: TMenuItem
      Caption = 'Как текст'#9'F12'
      RadioItem = True
      OnClick = FmtModeClick
    end
    object fmpFormat: TMenuItem
      Caption = 'По формату'
      RadioItem = True
      OnClick = FmtModeClick
    end
    object fmpSep: TMenuItem
      Caption = '-'
    end
    object fmpCopy: TMenuItem
      Caption = 'Копировать'#9'Ctrl+C'
      OnClick = FmtCopyClick
    end
    object fmpSelectAll: TMenuItem
      Caption = 'Выделить всё'#9'Ctrl+A'
      OnClick = FmtSelectAllClick
    end
    object fmpIeSep: TMenuItem
      Caption = '-'
    end
    object fmpIeEdge: TMenuItem
      Caption = 'Режим IE 11 для этого файла'
      OnClick = FmtIeEdgeClick
    end
    object fmpWv2: TMenuItem
      Caption = 'Открыть в WebView2 (Chromium)'
      OnClick = Wv2ViewClick
    end
  end
  object FLogPopup: TUiPopupMenu
    OnPopup = LogPopupPopup
    Left = 16
    Top = 544
    object FLogUndo: TMenuItem
      Caption = '&Undo'#9'Ctrl+Z'
      Tag = 1
      OnClick = LogPopupClick
    end
    object FLogSep1: TMenuItem
      Caption = '-'
      Tag = 0
    end
    object FLogCut: TMenuItem
      Caption = 'Cu&t'#9'Ctrl+X'
      Tag = 2
      OnClick = LogPopupClick
    end
    object FLogCopy: TMenuItem
      Caption = '&Copy'#9'Ctrl+C'
      Tag = 3
      OnClick = LogPopupClick
    end
    object FLogPaste: TMenuItem
      Caption = '&Paste'#9'Ctrl+V'
      Tag = 4
      OnClick = LogPopupClick
    end
    object FLogDelete: TMenuItem
      Caption = '&Delete'#9'Del'
      Tag = 5
      OnClick = LogPopupClick
    end
    object FLogSep2: TMenuItem
      Caption = '-'
      Tag = 0
    end
    object FLogSelectAll: TMenuItem
      Caption = 'Select &All'#9'Ctrl+A'
      Tag = 6
      OnClick = LogPopupClick
    end
    object FLogSep3: TMenuItem
      Caption = '-'
      Tag = 0
    end
    object FLogSaveAll: TMenuItem
      Caption = 'Sa&ve all logs'
      Tag = 7
      OnClick = LogPopupClick
    end
  end
  object FToolbar: TPanel
    Align = alTop
    Height = 130
    BevelOuter = bvNone
    Color = 15790320
    object FLeftPanel: TPanel
      Width = 477
      Align = alLeft
      BevelOuter = bvNone
      object grpCompiler: TUiGroupBox
        Align = alBottom
        Caption = 'Project'
        Height = 98
        object pnlCompilerIn: TPanel
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
      Left = 477
      Align = alLeft
      Width = 267
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
        object cmbReplace: TUiComboBox
          Left = 4
          Top = 26
        end
        object BtnRepl: TUiButton
          Caption = 'Replace'
          Left = 160
          Top = 28
          Width = 54
          Height = 22
          OnClick = DoReplace
        end
        object BtnAll: TUiButton
          Caption = 'All'
          Left = 221
          Top = 29
          Width = 34
          Height = 22
          OnClick = DoReplaceAll
        end
        object UndoBtn: TUiButton
          Caption = 'Undo'
          Left = 10
          Top = 86
          Width = 250
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
          Top = 58
          Caption = 'Case'
          Left = 90
          Width = 44
          Height = 17
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
      Caption = ''
      object pnlPaletteIn: TPanel
        Align = alClient
        BevelOuter = bvNone
        ParentFont = True
        object FGitBar: TPanel
          Visible = False
          Align = alClient
          BevelOuter = bvNone
          Caption = ''
          ParentColor = True
          ParentFont = True
          PopupMenu = FGitCopyMenu
          object FGitBarButton1: TUiButton
            Caption = 'Fetch'
            Hint = 'git fetch: узнать, что нового на сервере (ветки и коммиты), рабочие файлы не меняются'
            ShowHint = True
            Left = 4
            Top = 1
            Width = 56
            Height = 22
            OnClick = GitFetchClick
          end
          object FGitBtnPull: TUiButton
            Caption = 'Pull'
            Hint = 'git pull: забрать изменения ветки с сервера и влить в текущую (merge). Красная - на сервере есть новые коммиты (после Fetch)'
            ShowHint = True
            Left = 64
            Top = 1
            Width = 56
            Height = 22
            OnClick = GitPullClick
          end
          object FGitBtnPush: TUiButton
            Caption = 'Push'
            Hint = 'git push: отправить коммиты текущей ветки на сервер (ветки там ещё нет - опубликовать). Красная - есть неотправленные коммиты'
            ShowHint = True
            Left = 124
            Top = 1
            Width = 56
            Height = 22
            OnClick = GitPushClick
          end
          object FGitBtnCommit: TUiButton
            Caption = 'Commit...'
            Hint = 'Окно Commit: изменённые файлы, разница, заголовок и описание коммита. Красная - есть незакоммиченные изменения: их нужно закоммитить, тогда Push отправит их на сервер'
            ShowHint = True
            Left = 184
            Top = 1
            Width = 72
            Height = 22
            OnClick = GitCommitClick
          end
          object FGitBarButton2: TUiButton
            Caption = 'Commits history...'
            Hint = 'История коммитов ветки: файлы и разница, Revert, ветка от коммита, коммит в отдельную папку'
            ShowHint = True
            Left = 260
            Top = 1
            Width = 112
            Height = 22
            OnClick = GitHistoryClick
          end
          object FGitBarButton3: TUiButton
            Caption = 'Refresh'
            Hint = 'Обновить сведения панели'
            ShowHint = True
            Left = 376
            Top = 1
            Width = 60
            Height = 22
            OnClick = GitRefreshClick
          end
          object FGitBarButton4: TUiButton
            Caption = 'Git Bash'
            Hint = 'Терминал Git Bash в папке репозитория'
            ShowHint = True
            Left = 440
            Top = 1
            Width = 66
            Height = 22
            OnClick = GitBashClick
          end
          object FGitBarButton5: TUiButton
            Caption = 'Compare...'
            Hint = 'Сравнить две ветки: коммиты, которые есть только в одной из них (с файлами и разницей), сводка - в Git log'
            ShowHint = True
            Left = 510
            Top = 1
            Width = 76
            Height = 22
            OnClick = GitCompareClick
          end
          object FGitBarButton6: TUiButton
            Caption = 'Merge Into...'
            Hint = 'Влить текущую ветку в другую (например mainTest в main) и отправить ту на сервер (git push)'
            ShowHint = True
            Left = 590
            Top = 1
            Width = 92
            Height = 22
            OnClick = GitMergeIntoClick
          end
          object FGitBarButton7: TUiButton
            Caption = 'Unmerged...'
            Hint = 'Коммиты всех веток, которых нет в текущей (например в mainTest), в одной таблице, цвет - по ветке. Перенести коммиты (cherry-pick), влить ветку целиком, удалить ветку'
            ShowHint = True
            Left = 686
            Top = 1
            Width = 88
            Height = 22
            OnClick = GitUnmergedClick
          end
          object FGitBarButton8: TUiButton
            Caption = 'Help'
            Hint = 'Справка: что делают кнопки и строки панели Git, меню Repository и Branch (git_ref\help\git.chm)'
            ShowHint = True
            Left = 778
            Top = 1
            Width = 50
            Height = 22
            OnClick = GitHelpClick
          end
          object FGitBtnRepo: TUiButton
            Caption = 'Repository...'
            Hint = 'Выбрать репозиторий: недавние, по открытому проекту, Add Local / Clone / New'
            ShowHint = True
            Left = 4
            Top = 1
            Width = 92
            Height = 22
            OnClick = GitRepoBtnClick
            Top = 25
          end
          object FGitLblRepo: TUiLabel
            AutoSize = True
            Left = 102
            Top = 27
            Caption = '-'
            ShowHint = True
            Font.Size = 10
            PopupMenu = FGitCopyMenu
          end
          object FGitEdPath: TUiEdit
            BorderStyle = bsNone
            ReadOnly = True
            AutoSize = False
            Font.Size = 10
            Left = 200
            Top = 27
            Width = 100
            Height = 18
            ShowHint = True
            OnDblClick = GitFieldDblClick
            PopupMenu = FGitCopyMenu
          end
          object FGitLblOrigin: TUiLabel
            AutoSize = True
            Left = 310
            Top = 27
            Caption = 'origin:'
            ShowHint = True
            Font.Size = 10
            PopupMenu = FGitCopyMenu
          end
          object FGitEdRemote: TUiEdit
            BorderStyle = bsNone
            ReadOnly = True
            AutoSize = False
            Font.Size = 10
            Left = 360
            Top = 27
            Width = 100
            Height = 18
            ShowHint = True
            OnDblClick = GitFieldDblClick
            PopupMenu = FGitCopyMenu
          end
          object FGitLblManual: TUiLabel
            AutoSize = True
            Left = 470
            Top = 27
            Caption = '(выбран вручную)'
            ShowHint = True
            Font.Size = 10
            PopupMenu = FGitCopyMenu
          end
          object FGitBarLabel1: TUiLabel
            AutoSize = True
            Left = 4
            Top = 51
            Caption = 'Branch:'
            ShowHint = True
            Font.Size = 10
          end
          object FGitCmbBranch: TUiComboBox
            Style = csDropDownList
            Font.Size = 10
            Left = 64
            Top = 47
            Width = 220
            Height = 21
            ShowHint = True
            OnKeyDown = GitBranchKeyDown
            PopupMenu = FGitCopyMenu
          end
          object FGitLblSync: TUiLabel
            AutoSize = True
            Left = 292
            Top = 51
            Caption = ''
            ShowHint = True
            Font.Size = 10
          end
          object FGitLblBuild: TUiLabel
            AutoSize = True
            Left = 4
            Top = 75
            Caption = ''
            ShowHint = True
            Font.Size = 10
          end
          object FGitLblHint: TUiLabel
            AutoSize = True
            Left = 300
            Top = 75
            Caption = ''
            ShowHint = True
            Font.Size = 10
          end
          object FGitLblStatus: TUiLabel
            AutoSize = True
            Left = 300
            Top = 75
            Caption = ''
            ShowHint = True
            Font.Size = 10
            Visible = False
            Cursor = crHandPoint
            OnClick = GitStatusClick
          end
          object FGitBtnConflicts: TUiButton
            Caption = 'Conflicts...'
            Hint = 'Файлы с конфликтом: список в Git log и окно разбора - слева текущая ветка, справа вливаемое, выбор по каждому конфликту, результат внизу'
            ShowHint = True
            Left = 4
            Top = 1
            Width = 84
            Height = 22
            OnClick = GitConflictsClick
            Top = 73
            TextColor = clRed
            Visible = False
          end
          object FGitBtnAutoResolve: TUiButton
            Caption = 'Auto-resolve'
            Hint = 'Разрешить конфликты, где обе стороны только добавили строки в одно место (в общей версии там ничего не было): оставить обе вставки - сначала текущей ветки, потом вливаемую. Остальные - с маркерами, вручную'
            ShowHint = True
            Left = 4
            Top = 1
            Width = 84
            Height = 22
            OnClick = GitAutoResolveClick
            Top = 73
            Visible = False
          end
          object FGitBtnContinue: TUiButton
            Caption = 'Continue'
            Hint = 'Конфликты исправлены и сохранены: отметить файлы (git add) и закончить - коммит слияния или git cherry-pick / revert --continue'
            ShowHint = True
            Left = 4
            Top = 1
            Width = 70
            Height = 22
            OnClick = GitContinueClick
            Top = 73
            Visible = False
          end
          object FGitBtnSkip: TUiButton
            Caption = 'Skip'
            Hint = ''
            ShowHint = True
            Left = 4
            Top = 1
            Width = 46
            Height = 22
            OnClick = GitSkipClick
            Top = 73
            Visible = False
          end
          object FGitBtnAbort: TUiButton
            Caption = 'Abort'
            Hint = ''
            ShowHint = True
            Left = 4
            Top = 1
            Width = 56
            Height = 22
            OnClick = GitAbortClick
            Top = 73
            Visible = False
          end
          object FGitBtnView: TUiButton
            Caption = 'View'
            Hint = 'Коммиты, которые не отправлены на сервер или не забраны с него: сравнение ветки с её веткой на сервере (файлы и разница)'
            ShowHint = True
            Left = 4
            Top = 1
            Width = 50
            Height = 22
            OnClick = GitViewSyncClick
            Top = 73
            Visible = False
          end
        end
      end
      object FPalTabs: TUiCaptionTabs
        Left = 8
        Top = 0
        Width = 100
        Height = 16
        Tabs.Strings = (
          'Components'
          'Git')
      end
    end
  end
  object FMenuBar: TUiMenuBar
    Menu = MainMenu1
  end
  object FRightPanel: TPanel
    BevelWidth = 0
    BevelOuter = bvNone
    Caption = ''
    Align = alRight
    object FSplitBar: TPanel
      BevelWidth = 0
      Color = $00D06800
      Caption = ''
      Width = 5
      BevelOuter = bvSpace
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
          object FObjNvBtn: TUiButton
            Top = 3
            Height = 24
            Width = 105
            Caption = 'Hide non-visual'
            ShowHint = True
            OnClick = DsgNonVisualClick
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
          object FObjPropsSheet: TTabSheet
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
          object FObjEventsSheet: TTabSheet
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
    object FRightBtnMin: TUiButton
      Caption = '_'
      Hint = 'Свернуть правую панель'
      ShowHint = True
      OnClick = RightPanelBtnClick
    end
    object FRightBtnRestore: TUiButton
      Caption = '[]'
      Hint = 'Развернуть правую панель до прежней ширины'
      ShowHint = True
      OnClick = RightPanelBtnClick
      Enabled = False
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
    object FDsgMenuGrpEdit: TMenuItem
      Caption = 'Edit'
      object FDsgMiUndo: TMenuItem
        Caption = 'Undo'
        ShortCut = 16474
        OnClick = DsgMenuClick
      end
      object FDsgMenuGrpEditSep: TMenuItem
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
    object FDsgMenuGrpControl: TMenuItem
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
    object FDsgMenuGrpMenu: TMenuItem
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
      object FDsgMenuGrpMenuSep1: TMenuItem
        Caption = '-'
        ShortCut = 0
        OnClick = DsgMenuClick
      end
      object FDsgMiItemSub: TMenuItem
        Caption = 'Create Submenu'#9'Ctrl+Right'
        ShortCut = 0
        OnClick = DsgMenuClick
      end
      object FDsgMenuGrpMenuSep2: TMenuItem
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
  object FLargeTimer: TTimer
    Left = 16
    Top = 16
    Enabled = False
    Interval = 30
    OnTimer = LargeTimerTick
  end
  object FObjCacheTimer: TTimer
    Left = 56
    Top = 16
    Enabled = False
    Interval = 1500
    OnTimer = ObjCacheTimerTick
  end
  object FObjPropsTimer: TTimer
    Left = 96
    Top = 16
    Enabled = False
    Interval = 300
    OnTimer = ObjPropsTimerTick
  end
  object FModPreviewTimer: TTimer
    Left = 136
    Top = 16
    Enabled = False
    OnTimer = ModPreviewTick
  end
  object FGitTimer: TTimer
    Left = 176
    Top = 16
    Enabled = False
    Interval = 300
    OnTimer = GitTimerTick
  end
  object FGitCopyMenu: TUiPopupMenu
    Left = 216
    Top = 16
    OnPopup = GitCopyMenuPopup
    object FGitMiCopySel: TMenuItem
      Caption = 'Копировать выделенное'
      OnClick = GitCopySelClick
    end
    object FGitMiCopySelSep: TMenuItem
      Caption = '-'
    end
    object FGitMiCopyPath: TMenuItem
      Caption = 'Copy Local Path'
      OnClick = GitCopyPathClick
    end
    object FGitMiCopyRemote: TMenuItem
      Caption = 'Copy origin URL'
      OnClick = GitCopyRemoteClick
    end
    object FGitMiCopyBranch: TMenuItem
      Caption = 'Copy Branch Name'
      OnClick = GitCopyBranchClick
    end
  end
  object FAuxTimer: TTimer
    Left = 256
    Top = 16
    Enabled = False
    OnTimer = AuxTimerTick
  end
  object FDsgIconPopup: TUiPopupMenu
    Left = 296
    Top = 16
    AutoHotkeys = maManual
  end
  object FDsgOtherTimer: TTimer
    Left = 336
    Top = 16
    Enabled = False
    Interval = 1500
    OnTimer = DsgOtherTimerTick
  end
  object FRqDbgTimer: TTimer
    Left = 376
    Top = 16
    Enabled = False
    Interval = 50
    OnTimer = RqDbgTimerTick
  end
  object FGitPollTimer: TTimer
    Left = 416
    Top = 16
    Enabled = False
    OnTimer = GitPollTick
  end
  object FSymHintTimer: TTimer
    Left = 456
    Top = 16
    Enabled = False
    OnTimer = SymHintTimerTick
  end
end
