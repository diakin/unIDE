' =====================================================================
' ArdCliHelpCore.inc - окно "Arduino Cli Help", общая часть трёх версий
' (Windows XP / ReactOS, Windows 7, последняя версия arduino-cli).
'
' Перед $INCLUDE этого файла главный модуль задаёт профиль:
'   AchProfileName$    - название профиля (в заголовке окна)
'   AchCfgName$        - имя файла настроек рядом с exe
'   AchAutoArgs$       - аргументы, добавляемые к каждой команде
'   AchFallbackOrigin$ - откуда взят встроенный список команд
'   AchNotes$          - текст кнопки Notes
'   AchWaitLimitSec    - предел ожидания одной команды, с
'   AchWarnX64         - 1: предупреждать о 64-разрядном exe
' После $INCLUDE главный модуль заполняет встроенные списки через
'   AchAddFallbackCmd / AchAddFallbackFlag и показывает AchForm.
'
' Все имена начинаются с Ach, чтобы файл можно было подключить
' в RQdebugger без пересечения с существующими ArdCli*.
' =====================================================================

DECLARE FUNCTION AchWinExecApi LIB "kernel32" ALIAS "WinExec" (ByVal lpCmdLine AS STRING, ByVal nCmdShow AS LONG) AS LONG
DECLARE FUNCTION AchCharToOemApi LIB "user32" ALIAS "CharToOemA" (ByVal lpszSrc AS STRING, ByRef lpszDst AS STRING) AS LONG
DECLARE FUNCTION AchSendMsgApi LIB "user32" ALIAS "SendMessageA" (ByVal hWnd AS LONG, ByVal Msg AS LONG, ByVal wParam AS LONG, ByVal lParam AS LONG) AS LONG

CONST AchEmExLimitText = &H435   ' EM_EXLIMITTEXT
CONST AchSwHide = 0              ' SW_HIDE
CONST AchClrCaption = &H00BDFF   ' оранжевый, как в RQdebugger
CONST AchClrList = &HF0F0F0
CONST AchClrCmdLine = &H80FFFF
CONST AchClrOutOk = &HD8F5D8
CONST AchClrOutErr = &HD0D0FF
CONST AchClrOutInfo = &HFFFFFF

DIM AchCrLf AS STRING
DIM AchQt AS STRING
DIM AchTab AS STRING
DIM AchBaseDir AS STRING
DIM AchTmpDir AS STRING
DIM AchCfgFile AS STRING
DIM AchCurrentCmd AS STRING
DIM AchFormCaption AS STRING

DIM AchBusy AS INTEGER
DIM AchStopRequest AS INTEGER
DIM AchShownOnce AS INTEGER
DIM AchLastRunOk AS INTEGER
DIM AchLastExitCode AS INTEGER
DIM AchRunCounter AS INTEGER
DIM AchApiRes AS LONG

DIM AchCmdNames AS QSTRINGLIST     ' имена команд левого списка
DIM AchCmdDescs AS QSTRINGLIST     ' описания команд левого списка
DIM AchSubNames AS QSTRINGLIST     ' имена подкоманд
DIM AchSubDescs AS QSTRINGLIST     ' описания подкоманд
DIM AchParsedCmds AS QSTRINGLIST   ' результат разбора --help: имя + TAB + описание
DIM AchParsedFlags AS QSTRINGLIST  ' результат разбора --help: строки флагов
DIM AchFlagTokens AS QSTRINGLIST   ' флаг для вставки (--format и т.п.), по пунктам комбобокса
DIM AchFallbackCmds AS QSTRINGLIST
DIM AchFallbackFlags AS QSTRINGLIST

AchCrLf = CHR$(13) + CHR$(10)
AchQt = CHR$(34)
AchTab = CHR$(9)
AchBaseDir = COMMAND$(0) - Application.ExeName
AchTmpDir = AchBaseDir + "ArdCliHelpTmp\"
AchCfgFile = AchBaseDir + AchCfgName$
AchFormCaption = "Arduino Cli Help - " + AchProfileName$
AchBusy = 0
AchStopRequest = 0
AchShownOnce = 0
AchRunCounter = 0

' --- процедуры и функции ---
DECLARE SUB AchFormShow
DECLARE SUB AchCmdListClick
DECLARE SUB AchSubListClick
DECLARE SUB AchFlagComboChange
DECLARE SUB AchRunClick
DECLARE SUB AchStopClick
DECLARE SUB AchVersionClick
DECLARE SUB AchRefreshClick
DECLARE SUB AchNotesClick
DECLARE SUB AchBrowseClick
DECLARE SUB AchCmdLineKeyPress (Key AS BYTE)
DECLARE SUB AchSetStatus (StatusText AS STRING)
DECLARE SUB AchSetBusyUi (BusyFlag AS INTEGER)
DECLARE SUB AchLoadCfg
DECLARE SUB AchSaveCfg
DECLARE SUB AchCheckExe
DECLARE SUB AchLoadCommands
DECLARE SUB AchParseHelp (HelpText AS STRING)
DECLARE SUB AchFillCmdList (SrcList AS QSTRINGLIST)
DECLARE SUB AchFillSubList (SrcList AS QSTRINGLIST)
DECLARE SUB AchFillFlags (SrcList AS QSTRINGLIST)
DECLARE SUB AchAddFallbackCmd (CmdName AS STRING, CmdDesc AS STRING)
DECLARE SUB AchAddFallbackFlag (FlagLine AS STRING)
DECLARE FUNCTION AchRunCli (CliArgs AS STRING, StageText AS STRING) AS STRING
DECLARE FUNCTION AchUtf8LineToAnsi (SrcLine AS STRING) AS STRING
DECLARE FUNCTION AchCodePointToAnsi (CodePoint AS LONG) AS STRING
DECLARE FUNCTION AchSkipEscape (SrcLine AS STRING, StartPos AS INTEGER) AS INTEGER
DECLARE FUNCTION AchToOem (SrcText AS STRING) AS STRING
DECLARE FUNCTION AchFlagToken (FlagLine AS STRING) AS STRING
DECLARE FUNCTION AchExeMachine (ExePath AS STRING) AS STRING
DECLARE FUNCTION AchShortText (SrcText AS STRING, MaxLen AS INTEGER) AS STRING
DECLARE FUNCTION AchFirstLine (SrcText AS STRING) AS STRING

' =====================================================================
CREATE AchForm AS QFORM
	Caption = AchFormCaption
	Width = 1000
	Height = 600
	Center
	OnShow = AchFormShow

	CREATE AchTopPanel AS QPANEL
		Align = alTop
		Height = 28
		BevelOuter = bvNone

		CREATE AchCliPathLabel AS QLABEL
			Align = alLeft
			Width = 95
			Caption = " arduino-cli.exe "
			Alignment = taCenter
		END CREATE

		CREATE AchNotesBtn AS QBUTTON
			Align = alRight
			Width = 60
			Caption = "Notes"
			OnClick = AchNotesClick
		END CREATE

		CREATE AchRefreshBtn AS QBUTTON
			Align = alRight
			Width = 80
			Caption = "Commands"
			OnClick = AchRefreshClick
		END CREATE

		CREATE AchVersionBtn AS QBUTTON
			Align = alRight
			Width = 60
			Caption = "Version"
			OnClick = AchVersionClick
		END CREATE

		CREATE AchBrowseBtn AS QBUTTON
			Align = alRight
			Width = 26
			Caption = "..."
			OnClick = AchBrowseClick
		END CREATE

		CREATE AchCliPathEdit AS QEDIT
			Align = alClient
			Text = ""
		END CREATE
	END CREATE

	CREATE AchStatusLabel AS QLABEL
		Align = alBottom
		Height = 20
		Caption = ""
		Transparent = 0
	END CREATE

	CREATE AchBottomPanel AS QPANEL
		Align = alBottom
		Height = 27
		Color = AchClrCmdLine
		BevelOuter = bvNone

		CREATE AchRunBtn AS QBUTTON
			Align = alRight
			Width = 60
			Caption = "Run"
			OnClick = AchRunClick
		END CREATE

		CREATE AchStopBtn AS QBUTTON
			Align = alRight
			Width = 50
			Caption = "Stop"
			Enabled = 0
			OnClick = AchStopClick
		END CREATE

		CREATE AchCmdLineEdit AS QEDIT
			Align = alClient
			Color = AchClrCmdLine
			Font.Name = "Arial"
			Font.Size = 10
			Font.Bold = 1
			Text = ""
			OnKeyPress = AchCmdLineKeyPress
		END CREATE
	END CREATE

	CREATE AchOutPanel AS QPANEL
		Align = alRight
		Width = 540
		BevelOuter = bvNone

		CREATE AchOutEdit AS QRICHEDIT
			Align = alClient
			PlainText = 1
			WordWrap = 0
			ScrollBars = 3
			HideScrollBars = 0
			HideSelection = 0
			ReadOnly = 1
			Font.Name = "Courier New"
			Font.Size = 9
			Color = AchClrOutInfo
		END CREATE
	END CREATE

	CREATE AchSplitter AS QSPLITTER
		Align = alRight
		Width = 5
		Cursor = crHSplit
		Color = &H00C000
	END CREATE

	CREATE AchLeftPanel AS QPANEL
		Align = alClient
		BevelOuter = bvNone

		CREATE AchFlagPanel AS QPANEL
			Align = alBottom
			Height = 48
			BevelOuter = bvNone

			CREATE AchFlagLabel AS QLABEL
				Align = alTop
				Height = 18
				Caption = "Arduino Cli flags"
				Alignment = taCenter
				Color = AchClrCaption
				Transparent = 0
				Font.Name = "Arial"
				Font.Size = 10
			END CREATE

			CREATE AchFlagCombo AS QCOMBOBOX
				Align = alTop
				Style = csDropDownList
				DropDownCount = 20
				Font.Name = "Courier New"
				Font.Size = 9
				OnChange = AchFlagComboChange
			END CREATE
		END CREATE

		CREATE AchCmdPanel AS QPANEL
			Align = alLeft
			Width = 150
			BevelOuter = bvNone

			CREATE AchCmdLabel AS QLABEL
				Align = alTop
				Height = 18
				Caption = "Arduino Cli commands"
				Alignment = taCenter
				Color = AchClrCaption
				Transparent = 0
				Font.Name = "Arial"
				Font.Size = 10
			END CREATE

			CREATE AchCmdList AS QLISTBOX
				Align = alClient
				Color = AchClrList
				Font.Size = 11
				OnClick = AchCmdListClick
			END CREATE
		END CREATE

		CREATE AchSubPanel AS QPANEL
			Align = alClient
			BevelOuter = bvNone

			CREATE AchSubLabel AS QLABEL
				Align = alTop
				Height = 18
				Caption = "Arduino Cli sub-commands"
				Alignment = taCenter
				Color = AchClrCaption
				Transparent = 0
				Font.Name = "Arial"
				Font.Size = 10
			END CREATE

			CREATE AchSubList AS QLISTBOX
				Align = alClient
				Color = AchClrList
				Font.Name = "Courier New"
				Font.Size = 9
				OnClick = AchSubListClick
			END CREATE
		END CREATE
	END CREATE
END CREATE

' =====================================================================
SUB AchFormShow
	' Повторный показ окна списки не трогает: в RQdebugger853-8
	' ArdCliHelpFormShow дописывал команды при каждом открытии.
	IF AchShownOnce = 1 THEN EXIT SUB
	AchShownOnce = 1
	AchApiRes = AchSendMsgApi(AchOutEdit.Handle, AchEmExLimitText, 0, 4194304)
	AchLoadCfg
	AchCheckExe
	AchLoadCommands
END SUB

' =====================================================================
SUB AchSetStatus (StatusText AS STRING)
	AchStatusLabel.Caption = " " + StatusText
END SUB

' =====================================================================
SUB AchSetBusyUi (BusyFlag AS INTEGER)
	AchRunBtn.Enabled = 1 - BusyFlag
	AchStopBtn.Enabled = BusyFlag
	AchCmdList.Enabled = 1 - BusyFlag
	AchSubList.Enabled = 1 - BusyFlag
	AchFlagCombo.Enabled = 1 - BusyFlag
	AchVersionBtn.Enabled = 1 - BusyFlag
	AchRefreshBtn.Enabled = 1 - BusyFlag
	AchBrowseBtn.Enabled = 1 - BusyFlag
END SUB

' =====================================================================
SUB AchLoadCfg
	DIM CfgList AS QSTRINGLIST
	DIM CfgPath AS STRING

	CfgPath = ""
	IF FILEEXISTS(AchCfgFile) THEN
		CfgList.LoadFromFile(AchCfgFile)
		IF CfgList.ItemCount > 0 THEN CfgPath = TRIM$(CfgList.Item(0))
	END IF

	IF CfgPath = "" THEN
		IF FILEEXISTS(AchBaseDir + "Arduino15\arduino-cli\arduino-cli.exe") THEN
			CfgPath = AchBaseDir + "Arduino15\arduino-cli\arduino-cli.exe"
		ELSEIF FILEEXISTS(AchBaseDir + "arduino-cli.exe") THEN
			CfgPath = AchBaseDir + "arduino-cli.exe"
		END IF
	END IF

	AchCliPathEdit.Text = CfgPath
END SUB

' =====================================================================
SUB AchSaveCfg
	DIM CfgList AS QSTRINGLIST
	CfgList.Clear
	CfgList.AddItems TRIM$(AchCliPathEdit.Text)
	CfgList.SaveToFile(AchCfgFile)
END SUB

' =====================================================================
SUB AchCheckExe
	DIM ExePath AS STRING
	DIM MachineName AS STRING

	ExePath = TRIM$(AchCliPathEdit.Text)
	IF ExePath = "" OR FILEEXISTS(ExePath) = 0 THEN
		AchForm.Caption = AchFormCaption
		AchSetStatus "arduino-cli.exe не найден. Укажите путь кнопкой с тремя точками справа от поля"
		EXIT SUB
	END IF

	MachineName = AchExeMachine(ExePath)
	AchForm.Caption = AchFormCaption + "   [exe: " + MachineName + "]"

	IF AchWarnX64 = 1 AND MachineName = "x64" THEN
		AchSetStatus "Указан 64-разрядный exe: на 32-разрядной Windows XP он не запустится"
	END IF
END SUB

' =====================================================================
SUB AchLoadCommands
	DIM HelpOut AS STRING

	AchSubList.Clear
	AchSubNames.Clear
	AchSubDescs.Clear
	AchCurrentCmd = ""

	HelpOut = AchRunCli("--help", "Список команд")
	AchParseHelp HelpOut

	IF AchParsedCmds.ItemCount > 0 THEN
		AchFillCmdList AchParsedCmds
		IF AchParsedFlags.ItemCount > 0 THEN
			AchFillFlags AchParsedFlags
		ELSE
			AchFillFlags AchFallbackFlags
		END IF
		AchOutEdit.Text = HelpOut
		AchOutEdit.Color = AchClrOutOk
		AchSetStatus "Команды прочитаны из вывода --help: " + LTRIM$(STR$(AchCmdNames.ItemCount))
	ELSE
		AchFillCmdList AchFallbackCmds
		AchFillFlags AchFallbackFlags
		IF HelpOut <> "" THEN
			AchOutEdit.Text = HelpOut
			AchOutEdit.Color = AchClrOutErr
		END IF
		IF AchLastRunOk = 1 THEN
			AchSetStatus "В выводе --help нет списка команд; показан встроенный список (" + AchFallbackOrigin$ + ")"
		END IF
	END IF
END SUB

' =====================================================================
' Разбор справки arduino-cli (cobra): разделы "Available Commands:",
' "Flags:", "Global Flags:". Раздел заканчивается пустой строкой.
SUB AchParseHelp (HelpText AS STRING)
	DIM HelpLines AS QSTRINGLIST
	DIM LineText AS STRING
	DIM TrimLine AS STRING
	DIM SectionName AS STRING
	DIM CmdName AS STRING
	DIM CmdDesc AS STRING
	DIM i AS INTEGER

	AchParsedCmds.Clear
	AchParsedFlags.Clear
	IF HelpText = "" THEN EXIT SUB

	HelpLines.Text = HelpText
	SectionName = ""

	FOR i = 0 TO HelpLines.ItemCount - 1
		LineText = HelpLines.Item(i)
		TrimLine = TRIM$(LineText)
		IF TrimLine = "" THEN
			SectionName = ""
		ELSEIF LEFT$(LineText, 1) <> " " AND RIGHT$(TrimLine, 1) = ":" THEN
			SectionName = LCASE$(TrimLine)
		ELSEIF RIGHT$(SectionName, 9) = "commands:" THEN
			CmdName = FIELD$(TrimLine, " ", 1)
			CmdDesc = TRIM$(MID$(TrimLine, LEN(CmdName) + 1, LEN(TrimLine)))
			AchParsedCmds.AddItems CmdName + AchTab + CmdDesc
		ELSEIF RIGHT$(SectionName, 6) = "flags:" THEN
			IF LEFT$(TrimLine, 1) = "-" THEN AchParsedFlags.AddItems TrimLine
		END IF
	NEXT i
END SUB

' =====================================================================
SUB AchFillCmdList (SrcList AS QSTRINGLIST)
	DIM ItemText AS STRING
	DIM TabPos AS INTEGER
	DIM i AS INTEGER

	AchCmdList.Clear
	AchCmdNames.Clear
	AchCmdDescs.Clear

	FOR i = 0 TO SrcList.ItemCount - 1
		ItemText = SrcList.Item(i)
		TabPos = INSTR(ItemText, AchTab)
		IF TabPos > 0 THEN
			AchCmdNames.AddItems LEFT$(ItemText, TabPos - 1)
			AchCmdDescs.AddItems MID$(ItemText, TabPos + 1, LEN(ItemText))
		ELSE
			AchCmdNames.AddItems ItemText
			AchCmdDescs.AddItems ""
		END IF
		AchCmdList.AddItems AchCmdNames.Item(AchCmdNames.ItemCount - 1)
	NEXT i
END SUB

' =====================================================================
SUB AchFillSubList (SrcList AS QSTRINGLIST)
	DIM ItemText AS STRING
	DIM TabPos AS INTEGER
	DIM NameWidth AS INTEGER
	DIM i AS INTEGER

	AchSubList.Clear
	AchSubNames.Clear
	AchSubDescs.Clear

	FOR i = 0 TO SrcList.ItemCount - 1
		ItemText = SrcList.Item(i)
		TabPos = INSTR(ItemText, AchTab)
		IF TabPos > 0 THEN
			AchSubNames.AddItems LEFT$(ItemText, TabPos - 1)
			AchSubDescs.AddItems MID$(ItemText, TabPos + 1, LEN(ItemText))
		ELSE
			AchSubNames.AddItems ItemText
			AchSubDescs.AddItems ""
		END IF
	NEXT i

	NameWidth = 0
	FOR i = 0 TO AchSubNames.ItemCount - 1
		IF LEN(AchSubNames.Item(i)) > NameWidth THEN NameWidth = LEN(AchSubNames.Item(i))
	NEXT i

	FOR i = 0 TO AchSubNames.ItemCount - 1
		AchSubList.AddItems AchSubNames.Item(i) + SPACE$(NameWidth - LEN(AchSubNames.Item(i)) + 2) + AchSubDescs.Item(i)
	NEXT i
END SUB

' =====================================================================
SUB AchFillFlags (SrcList AS QSTRINGLIST)
	DIM FlagLine AS STRING
	DIM FlagToken AS STRING
	DIM IsDuplicate AS INTEGER
	DIM i AS INTEGER
	DIM j AS INTEGER

	AchFlagCombo.Clear
	AchFlagTokens.Clear
	AchFlagCombo.AddItems "(flags)"

	FOR i = 0 TO SrcList.ItemCount - 1
		FlagLine = TRIM$(SrcList.Item(i))
		FlagToken = AchFlagToken(FlagLine)
		IF FlagToken <> "" THEN
			IsDuplicate = 0
			FOR j = 0 TO AchFlagTokens.ItemCount - 1
				IF AchFlagTokens.Item(j) = FlagToken THEN IsDuplicate = 1
			NEXT j
			IF IsDuplicate = 0 THEN
				AchFlagTokens.AddItems FlagToken
				AchFlagCombo.AddItems FlagLine
			END IF
		END IF
	NEXT i

	AchFlagCombo.ItemIndex = 0
END SUB

' =====================================================================
' "-h, --help   help for board"        -> "--help"
' "    --format string   The output..." -> "--format"
FUNCTION AchFlagToken (FlagLine AS STRING) AS STRING
	DIM LongPos AS INTEGER
	DIM TailText AS STRING

	LongPos = INSTR(FlagLine, "--")
	IF LongPos > 0 THEN
		TailText = MID$(FlagLine, LongPos, LEN(FlagLine))
		Result = FIELD$(TailText, " ", 1)
	ELSE
		Result = REPLACESUBSTR$(FIELD$(TRIM$(FlagLine), " ", 1), ",", "")
	END IF
END FUNCTION

' =====================================================================
SUB AchAddFallbackCmd (CmdName AS STRING, CmdDesc AS STRING)
	AchFallbackCmds.AddItems CmdName + AchTab + CmdDesc
END SUB

' =====================================================================
SUB AchAddFallbackFlag (FlagLine AS STRING)
	AchFallbackFlags.AddItems FlagLine
END SUB

' =====================================================================
SUB AchCmdListClick
	DIM SelIdx AS INTEGER
	DIM HelpOut AS STRING

	IF AchBusy = 1 THEN EXIT SUB
	SelIdx = AchCmdList.ItemIndex
	IF SelIdx < 0 OR SelIdx >= AchCmdNames.ItemCount THEN EXIT SUB

	AchCurrentCmd = AchCmdNames.Item(SelIdx)
	AchCmdLineEdit.Text = AchCurrentCmd + " "

	HelpOut = AchRunCli(AchCurrentCmd + " --help", "Справка")
	IF AchLastRunOk = 0 THEN EXIT SUB

	AchOutEdit.Text = HelpOut
	AchOutEdit.Color = AchClrOutOk
	AchParseHelp HelpOut
	AchFillSubList AchParsedCmds
	IF AchParsedFlags.ItemCount > 0 THEN AchFillFlags AchParsedFlags

	AchSetStatus AchCurrentCmd + " - " + AchCmdDescs.Item(SelIdx) + "   (подкоманд: " + LTRIM$(STR$(AchSubNames.ItemCount)) + ")"
END SUB

' =====================================================================
SUB AchSubListClick
	DIM SelIdx AS INTEGER
	DIM FullCmd AS STRING
	DIM HelpOut AS STRING

	IF AchBusy = 1 THEN EXIT SUB
	SelIdx = AchSubList.ItemIndex
	IF SelIdx < 0 OR SelIdx >= AchSubNames.ItemCount THEN EXIT SUB
	IF AchCurrentCmd = "" THEN EXIT SUB

	FullCmd = AchCurrentCmd + " " + AchSubNames.Item(SelIdx)
	AchCmdLineEdit.Text = FullCmd + " "

	HelpOut = AchRunCli(FullCmd + " --help", "Справка")
	IF AchLastRunOk = 0 THEN EXIT SUB

	AchOutEdit.Text = HelpOut
	AchOutEdit.Color = AchClrOutOk
	AchParseHelp HelpOut
	IF AchParsedFlags.ItemCount > 0 THEN AchFillFlags AchParsedFlags

	AchSetStatus FullCmd + " - " + AchSubDescs.Item(SelIdx)
END SUB

' =====================================================================
SUB AchFlagComboChange
	DIM SelIdx AS INTEGER
	DIM FlagToken AS STRING
	DIM LineText AS STRING

	SelIdx = AchFlagCombo.ItemIndex
	IF SelIdx <= 0 THEN EXIT SUB
	IF SelIdx - 1 >= AchFlagTokens.ItemCount THEN EXIT SUB

	FlagToken = AchFlagTokens.Item(SelIdx - 1)
	LineText = RTRIM$(AchCmdLineEdit.Text)
	IF INSTR(" " + LineText + " ", " " + FlagToken + " ") = 0 THEN
		AchCmdLineEdit.Text = LineText + " " + FlagToken + " "
	END IF
	AchCmdLineEdit.SelStart = LEN(AchCmdLineEdit.Text)
	AchFlagCombo.ItemIndex = 0
END SUB

' =====================================================================
SUB AchCmdLineKeyPress (Key AS BYTE)
	IF Key = 13 THEN AchRunClick
END SUB

' =====================================================================
SUB AchRunClick
	DIM ArgsText AS STRING
	DIM FirstWord AS STRING
	DIM OutText AS STRING

	IF AchBusy = 1 THEN EXIT SUB
	ArgsText = TRIM$(AchCmdLineEdit.Text)

	' если в строке набрано "arduino-cli ..." или полный путь к exe - убираем его
	FirstWord = LCASE$(FIELD$(ArgsText, " ", 1))
	IF RIGHT$(FirstWord, 15) = "arduino-cli.exe" OR FirstWord = "arduino-cli" THEN
		ArgsText = TRIM$(MID$(ArgsText, LEN(FirstWord) + 1, LEN(ArgsText)))
	END IF

	IF ArgsText = "" THEN
		AchSetStatus "Строка команды пуста"
		EXIT SUB
	END IF

	AchSaveCfg
	OutText = AchRunCli(ArgsText, "Выполнение")
	IF AchLastRunOk = 0 THEN EXIT SUB

	IF OutText = "" THEN OutText = "(arduino-cli ничего не вывел)"
	AchOutEdit.Text = OutText
	IF AchLastExitCode = 0 THEN
		AchOutEdit.Color = AchClrOutOk
	ELSE
		AchOutEdit.Color = AchClrOutErr
	END IF
	AchSetStatus "Готово: " + AchShortText(ArgsText, 70) + "   код завершения " + LTRIM$(STR$(AchLastExitCode))
END SUB

' =====================================================================
SUB AchStopClick
	AchStopRequest = 1
END SUB

' =====================================================================
SUB AchVersionClick
	DIM OutText AS STRING

	IF AchBusy = 1 THEN EXIT SUB
	OutText = AchRunCli("version", "Версия")
	IF AchLastRunOk = 0 THEN EXIT SUB

	AchOutEdit.Text = OutText
	AchOutEdit.Color = AchClrOutInfo
	AchSetStatus AchShortText(AchFirstLine(OutText), 120)
END SUB

' =====================================================================
SUB AchRefreshClick
	IF AchBusy = 1 THEN EXIT SUB
	AchSaveCfg
	AchCheckExe
	AchLoadCommands
END SUB

' =====================================================================
SUB AchNotesClick
	AchOutEdit.Text = AchNotes$
	AchOutEdit.Color = AchClrOutInfo
END SUB

' =====================================================================
SUB AchBrowseClick
	DIM OpenDlg AS QOPENDIALOG

	IF AchBusy = 1 THEN EXIT SUB
	OpenDlg.Filter = "arduino-cli*.exe|arduino-cli*.exe|*.exe|*.exe"
	OpenDlg.FilterIndex = 1
	IF OpenDlg.Execute THEN
		AchCliPathEdit.Text = OpenDlg.FileName
		AchSaveCfg
		AchCheckExe
		AchLoadCommands
	END IF
END SUB

' =====================================================================
' Запуск arduino-cli через временный .bat: вывод (stdout и stderr) - в файл,
' код завершения - во второй файл-маркер. Окно консоли скрыто,
' программа ждёт маркер, не блокируя окно (DOEVENTS).
' Возвращает вывод, переведённый из UTF-8 в 1251, строки через CRLF.
FUNCTION AchRunCli (CliArgs AS STRING, StageText AS STRING) AS STRING
	DIM CliPath AS STRING
	DIM RunTag AS STRING
	DIM OutFile AS STRING
	DIM MarkFile AS STRING
	DIM BatFile AS STRING
	DIM BatText AS STRING
	DIM BatList AS QSTRINGLIST
	DIM OutList AS QSTRINGLIST
	DIM MarkList AS QSTRINGLIST
	DIM ExecRes AS LONG
	DIM StartTime AS DOUBLE
	DIM ElapsedSec AS DOUBLE
	DIM WaitState AS INTEGER
	DIM i AS INTEGER

	Result = ""
	AchLastRunOk = 0
	AchLastExitCode = -1

	IF AchBusy = 1 THEN
		AchSetStatus "Предыдущая команда ещё выполняется"
		EXIT FUNCTION
	END IF

	CliPath = TRIM$(AchCliPathEdit.Text)
	IF CliPath = "" OR FILEEXISTS(CliPath) = 0 THEN
		AchSetStatus "arduino-cli.exe не найден: " + CliPath
		EXIT FUNCTION
	END IF

	IF DIREXISTS(AchTmpDir) = 0 THEN MKDIR AchTmpDir
	IF DIREXISTS(AchTmpDir) = 0 THEN
		AchSetStatus "Не удалось создать папку " + AchTmpDir
		EXIT FUNCTION
	END IF

	' у каждого запуска свои файлы: процесс, ожидание которого прервано
	' кнопкой Stop, может ещё держать файлы прошлого запуска
	AchRunCounter = AchRunCounter + 1
	RunTag = LTRIM$(STR$(AchRunCounter))
	OutFile = AchTmpDir + "achout" + RunTag + ".txt"
	MarkFile = AchTmpDir + "achdone" + RunTag + ".txt"
	BatFile = AchTmpDir + "achrun" + RunTag + ".bat"
	IF FILEEXISTS(OutFile) THEN KILL OutFile
	IF FILEEXISTS(MarkFile) THEN KILL MarkFile

	' ">файл echo ..." - перенаправление впереди, иначе "1>" в конце
	' строки cmd принял бы за перенаправление потока 1
	BatText = "@echo off" + AchCrLf + _
		"set ARDUINO_LOCALE=en" + AchCrLf + _
		AchQt + CliPath + AchQt + " " + CliArgs + AchAutoArgs$ + _
		" >" + AchQt + OutFile + AchQt + " 2>&1" + AchCrLf + _
		">" + AchQt + MarkFile + AchQt + " echo %errorlevel%" + AchCrLf

	' cmd.exe читает .bat в OEM-кодировке консоли
	BatList.Text = AchToOem(BatText)
	BatList.SaveToFile(BatFile)

	AchBusy = 1
	AchStopRequest = 0
	AchSetBusyUi 1

	ExecRes = AchWinExecApi("cmd.exe /c " + AchQt + BatFile + AchQt, AchSwHide)
	IF ExecRes <= 31 THEN
		AchBusy = 0
		AchSetBusyUi 0
		AchSetStatus "Не удалось запустить cmd.exe (WinExec вернул " + LTRIM$(STR$(ExecRes)) + ")"
		EXIT FUNCTION
	END IF

	StartTime = TIMER
	WaitState = 0
	WHILE FILEEXISTS(MarkFile) = 0
		DOEVENTS
		SLEEP 0.1
		ElapsedSec = TIMER - StartTime
		IF ElapsedSec < 0 THEN ElapsedSec = ElapsedSec + 86400
		AchStatusLabel.Caption = " " + StageText + ": " + AchShortText(CliArgs, 60) + "   " + LTRIM$(STR$(INT(ElapsedSec))) + " с"
		IF AchStopRequest = 1 THEN WaitState = 2 : EXIT WHILE
		IF ElapsedSec > AchWaitLimitSec THEN WaitState = 1 : EXIT WHILE
	WEND

	IF WaitState > 0 THEN
		AchBusy = 0
		AchSetBusyUi 0
		IF WaitState = 1 THEN
			AchSetStatus "Ожидание прекращено через " + LTRIM$(STR$(AchWaitLimitSec)) + " с; arduino-cli может продолжать работу. Вывод: " + OutFile
		ELSE
			AchSetStatus "Ожидание прервано кнопкой Stop; arduino-cli может продолжать работу. Вывод: " + OutFile
		END IF
		EXIT FUNCTION
	END IF

	SLEEP 0.2

	MarkList.LoadFromFile(MarkFile)
	IF MarkList.ItemCount > 0 THEN AchLastExitCode = VAL(TRIM$(MarkList.Item(0)))

	IF FILEEXISTS(OutFile) THEN
		OutList.LoadFromFile(OutFile)
		FOR i = 0 TO OutList.ItemCount - 1
			OutList.Item(i) = AchUtf8LineToAnsi(OutList.Item(i))
		NEXT i
		Result = OutList.Text
		KILL OutFile
	END IF
	KILL MarkFile
	IF FILEEXISTS(BatFile) THEN KILL BatFile

	AchBusy = 0
	AchSetBusyUi 0
	AchLastRunOk = 1
	AchSetStatus StageText + ": код завершения " + LTRIM$(STR$(AchLastExitCode))
END FUNCTION

' =====================================================================
' Строка UTF-8 -> 1251. Кириллица, Ё/ё, кавычки, тире, многоточие
' переводятся; остальные символы вне 1251 - "?". Байты, которые не
' складываются в последовательность UTF-8, остаются как есть.
' Цветовые escape-последовательности (ESC [ ... m) удаляются.
FUNCTION AchUtf8LineToAnsi (SrcLine AS STRING) AS STRING
	DIM OutText AS STRING
	DIM LineLen AS INTEGER
	DIM BytePos AS INTEGER
	DIM LeadByte AS INTEGER
	DIM NextByte AS INTEGER
	DIM ExtraCount AS INTEGER
	DIM SeqOk AS INTEGER
	DIM CodePoint AS LONG
	DIM j AS INTEGER

	OutText = ""
	LineLen = LEN(SrcLine)
	BytePos = 1

	WHILE BytePos <= LineLen
		LeadByte = ASC(MID$(SrcLine, BytePos, 1))
		IF LeadByte = 27 THEN
			BytePos = AchSkipEscape(SrcLine, BytePos)
		ELSEIF LeadByte = 13 THEN
			BytePos = BytePos + 1
		ELSEIF LeadByte < 128 THEN
			OutText = OutText + CHR$(LeadByte)
			BytePos = BytePos + 1
		ELSE
			ExtraCount = 0
			CodePoint = 0
			IF (LeadByte AND &HE0) = &HC0 THEN
				ExtraCount = 1
				CodePoint = LeadByte AND &H1F
			ELSEIF (LeadByte AND &HF0) = &HE0 THEN
				ExtraCount = 2
				CodePoint = LeadByte AND &H0F
			ELSEIF (LeadByte AND &HF8) = &HF0 THEN
				ExtraCount = 3
				CodePoint = LeadByte AND &H07
			END IF

			SeqOk = 0
			IF ExtraCount > 0 AND BytePos + ExtraCount <= LineLen THEN
				SeqOk = 1
				FOR j = 1 TO ExtraCount
					NextByte = ASC(MID$(SrcLine, BytePos + j, 1))
					IF (NextByte AND &HC0) <> &H80 THEN
						SeqOk = 0
					ELSE
						CodePoint = CodePoint * 64 + (NextByte AND &H3F)
					END IF
				NEXT j
			END IF

			IF SeqOk = 1 THEN
				OutText = OutText + AchCodePointToAnsi(CodePoint)
				BytePos = BytePos + ExtraCount + 1
			ELSE
				OutText = OutText + CHR$(LeadByte)
				BytePos = BytePos + 1
			END IF
		END IF
	WEND

	Result = OutText
END FUNCTION

' =====================================================================
FUNCTION AchCodePointToAnsi (CodePoint AS LONG) AS STRING
	IF CodePoint >= &H410 AND CodePoint <= &H44F THEN
		Result = CHR$(CodePoint - &H410 + &HC0)
		EXIT FUNCTION
	END IF

	SELECT CASE CodePoint
	CASE &H401
		Result = CHR$(&HA8)
	CASE &H451
		Result = CHR$(&HB8)
	CASE &HA0
		Result = " "
	CASE &HA9, &HAB, &HB0, &HBB
		Result = CHR$(CodePoint)
	CASE &H2013, &H2014
		Result = "-"
	CASE &H2018, &H2019
		Result = "'"
	CASE &H201C, &H201D
		Result = CHR$(34)
	CASE &H2022
		Result = CHR$(&H95)
	CASE &H2026
		Result = "..."
	CASE &H2116
		Result = CHR$(&HB9)
	CASE &HFEFF
		Result = ""
	CASE ELSE
		Result = "?"
	END SELECT
END FUNCTION

' =====================================================================
' Пропуск ESC [ ... <буква>; возвращает позицию следующего символа.
FUNCTION AchSkipEscape (SrcLine AS STRING, StartPos AS INTEGER) AS INTEGER
	DIM PosIdx AS INTEGER
	DIM CharCode AS INTEGER

	PosIdx = StartPos + 1
	IF MID$(SrcLine, PosIdx, 1) = "[" THEN
		PosIdx = PosIdx + 1
		WHILE PosIdx <= LEN(SrcLine)
			CharCode = ASC(MID$(SrcLine, PosIdx, 1))
			PosIdx = PosIdx + 1
			IF CharCode >= 64 AND CharCode <= 126 THEN EXIT WHILE
		WEND
	END IF
	Result = PosIdx
END FUNCTION

' =====================================================================
FUNCTION AchToOem (SrcText AS STRING) AS STRING
	DIM OemBuf AS STRING
	DIM ApiRes AS LONG

	IF LEN(SrcText) = 0 THEN
		Result = ""
		EXIT FUNCTION
	END IF
	OemBuf = SPACE$(LEN(SrcText) + 1)
	ApiRes = AchCharToOemApi(SrcText, OemBuf)
	Result = LEFT$(OemBuf, LEN(SrcText))
END FUNCTION

' =====================================================================
' Разрядность exe по полю Machine заголовка PE.
FUNCTION AchExeMachine (ExePath AS STRING) AS STRING
	DIM PeFile AS QFILESTREAM
	DIM OffsetBytes AS STRING
	DIM HeadBytes AS STRING
	DIM PeOffset AS LONG
	DIM MachineCode AS LONG

	Result = "?"
	PeFile.Open(ExePath, 0)          ' 0 = fmOpenRead
	IF PeFile.Size < 64 THEN
		PeFile.Close
		EXIT FUNCTION
	END IF

	PeFile.Position = 60
	OffsetBytes = PeFile.ReadStr(4)
	PeOffset = ASC(MID$(OffsetBytes, 1, 1)) + ASC(MID$(OffsetBytes, 2, 1)) * 256 + ASC(MID$(OffsetBytes, 3, 1)) * 65536
	IF PeOffset < 64 OR PeOffset + 6 > PeFile.Size THEN
		PeFile.Close
		EXIT FUNCTION
	END IF

	PeFile.Position = PeOffset
	HeadBytes = PeFile.ReadStr(6)
	PeFile.Close
	IF LEFT$(HeadBytes, 2) <> "PE" THEN EXIT FUNCTION

	MachineCode = ASC(MID$(HeadBytes, 5, 1)) + ASC(MID$(HeadBytes, 6, 1)) * 256
	SELECT CASE MachineCode
	CASE &H14C
		Result = "x86"
	CASE &H8664
		Result = "x64"
	CASE &HAA64
		Result = "ARM64"
	CASE ELSE
		Result = "machine &H" + HEX$(MachineCode)
	END SELECT
END FUNCTION

' =====================================================================
FUNCTION AchShortText (SrcText AS STRING, MaxLen AS INTEGER) AS STRING
	IF LEN(SrcText) > MaxLen THEN
		Result = LEFT$(SrcText, MaxLen) + "..."
	ELSE
		Result = SrcText
	END IF
END FUNCTION

' =====================================================================
FUNCTION AchFirstLine (SrcText AS STRING) AS STRING
	DIM LineEnd AS INTEGER
	LineEnd = INSTR(SrcText, CHR$(13))
	IF LineEnd > 0 THEN
		Result = LEFT$(SrcText, LineEnd - 1)
	ELSE
		Result = SrcText
	END IF
END FUNCTION
