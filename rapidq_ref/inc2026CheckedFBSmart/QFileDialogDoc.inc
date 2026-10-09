'$typecheck on
'============================================================================================
'  Class QFILEDIAGLOG   an Open or Save sizeable file dialog box with overwrite warning
'  Version 1.0 
'  11/2004 original code adapted from RQDIALOG.INC by   BILL K  1-2003
'  by JohnK
'============================================================================================
' USAGE:  MYFILENAME$=RQSHOWDIALOG(MyCaption$, _                ' default is "Open" or "Save"
'                                  MyFilter$, _                 ' default is All Files
'                                  FilterIndex%, _              ' default is 0
'                                  MyInitialDirectory$, _       ' default is current directory
'                                  WantSaveDialog%, _           ' 1=Save  0=Open - default is Open 
'                                  NoOverwriteWarning%, _       ' default is 0
'                                  MyFormHandle&)               ' Form handle or 0 .. default is 0 - see below
' 
'    WantSaveDialog%=1 for a Save Dialog   =0 for an Open Dialog
'    NoOverwriteWarning%=1 for defeating the default warning when about to overwrite an existing file
'    MyFormHandle& = MyForm.Handle ( so that the dialog knows which form
'                                    to be modal to and where to locate)   =0 for nonmodal(not advised)
' 
'  EXAMPLE: FileName$=RQShowDialog("Save File","RQ Files|*.bas;*.rqb","C:\RapidQ",1,0,Form.Handle)
'
$IFNDEF _RQDIALOGINC
$DEFINE _RQDIALOGINC

CONST OFN_READONLY                 =  &H00000001  
CONST OFN_OVERWRITEPROMPT          =  &H00000002  'display the overwrite warning
CONST OFN_HIDEREADONLY             =  &H00000004  'hide the Open as Readonly checkbox
CONST OFN_NOCHANGEDIR              =  &H00000008  'return to original director if the user changed the directory while searching
CONST OFN_SHOWHELP                 =  &H00000010
CONST OFN_ENABLEHOOK               =  &H00000020
CONST OFN_ENABLETEMPLATE           =  &H00000040
CONST OFN_ENABLETEMPLATEHANDLE     =  &H00000080
CONST OFN_NOVALIDATE               =  &H00000100
CONST OFN_ALLOWMULTISELECT         =  &H00000200   'multiple file select, should have OFN_EXPLORER = 1 for long filenames
CONST OFN_EXTENSIONDIFFERENT       =  &H00000400
CONST OFN_PATHMUSTEXIST            =  &H00000800
CONST OFN_FILEMUSTEXIST            =  &H00001000
CONST OFN_CREATEPROMPT             =  &H00002000
CONST OFN_SHAREAWARE               =  &H00004000
CONST OFN_NOREADONLYRETURN         =  &H00008000
CONST OFN_NOTESTFILECREATE         =  &H00010000
CONST OFN_NOLONGNAMES              =  &H00040000
CONST OFN_EXPLORER                 =  &H00080000 'explorer like browser
CONST OFN_NODEREFERENCELINKS       =  &H00100000
CONST OFN_LONGNAMES                =  &H00200000



'Error codes from CommDlgExtendedError
Public Const CDERR_DIALOGFAILURE = &HFFFF
Public Const CDERR_GENERALCODES = &H0
Public Const CDERR_STRUCTSIZE = &H1
Public Const CDERR_INITIALIZATION = &H2
Public Const CDERR_NOTEMPLATE = &H3
Public Const CDERR_NOHINSTANCE = &H4
Public Const CDERR_LOADSTRFAILURE = &H5
Public Const CDERR_FINDRESFAILURE = &H6
Public Const CDERR_LOADRESFAILURE = &H7
Public Const CDERR_LOCKRESFAILURE = &H8
Public Const CDERR_MEMALLOCFAILURE = &H9
Public Const CDERR_MEMLOCKFAILURE = &HA
Public Const CDERR_NOHOOK = &HB
Public Const CDERR_REGISTERMSGFAIL = &HC


brem 0
================
typedef struct tagOFN { 
DWORD         lStructSize; 
'Определяет длину структуры, в байтах.
'Windows NT 4.0: В приложении, которое компилировано с WINVER и _WIN32_WINNT> = 0x0500, для этого члена структуры используется 
'OPENFILENAME_SIZE_VERSION_400.
'Windows 2000/XP: Для этого параметра используется sizeof (OPENFILENAME).

HWND          hwndOwner; 
'Дескриптор окна, которое владеет блоком диалога. Этот член может быть любым допустимым дескриптором окна или может иметь значение ПУСТО (NULL), 
'если у диалогового окна нет владельца.

HINSTANCE     hInstance; 
'Если в члене Flags установлен флажок OFN_ENABLETEMPLATEHANDLE, hInstance является дескриптором объекта памяти, 
'содержащего шаблон диалогового окна. Если установлен флажок OFN_ENABLETEMPLATE, hInstance дескриптор модуля, именованного в члене 
'структуры lpTemplateName, который содержит шаблон диалогового окна. Если ни один флаг не установлен, этот член игнорируется. 
'Если установлен флажок OFN_EXPLORER, система использует заданный шаблон для создания диалогового окна, которое является дочерним блоком 
'диалога в стиле Проводника по умолчанию. Если флажок OFN_EXPLORER не установлен, система использует шаблон для создания диалогового окна 
'в старом стиле, который заменяет блок диалога по умолчанию.

LPCTSTR       lpstrFilter; 
'Указатель на буфер, содержащий пары строк фильтров с нулевым символом в конце. Последняя строка в буфере должна быть завершена двумя 
'символами ПУСТО (NULL).
'Первая строка в каждой паре - информационная строка, которая описывает фильтр (например, Текстовые файлы (Text Files)), 
'а вторая строка определяет модель фильтра (например, "*.TXT"). Чтобы определить модели сложного фильтра для отдельной информационной 
'строки, используйте точку с запятой, чтобы отделять их (например, " *.TXT; *.DOC; *.BAK "). Строка модели может быть комбинацией 
'допустимых символов имени файла и звездочки (*) в качестве группового символа. Не включайте пробелы в строку модели.

'Операционная система не изменяет порядок фильтров. Она показывает их в комбинированном блоке Типы файлов (File Types), по порядку 
'определяемому в члене lpstrFilter.
'Если lpstrFilter имеет значение ПУСТО (NULL), диалоговое окно не показывает каких-либо фильтров.

LPTSTR        lpstrCustomFilter; 
'Указатель на статический буфер, который содержит пару строк фильтра с нулевым символом в конце для сохранения модели фильтра, 
'выбранного пользователем. Первая строка - информирующая вас строка, которая описывает пользовательский фильтр, а вторая строка - 
'модель фильтра, выбранного пользователем. Первый раз, когда ваша прикладная программа создает диалоговое окно, вы определяете первую строку, 
'которая может быть любой непустой строкой. Когда пользователь выбирает файл, диалоговое окно копирует текущую модель фильтра во вторую строку.
'Сохраняемая модель фильтра может быть одной из моделей, определяемых в буфере lpstrFilter, или это может быть модель фильтра, 
'введенная с клавиатуры пользователем. Система использует строки, чтобы инициализировать определяемый пользователем фильтр файла, 
'в следующий раз, когда создается диалоговое окно. Если член nFilterIndex нулевой, диалоговое окно использует этот пользовательский фильтр.
'Если этот член имеет значение ПУСТО (NULL), диалоговое окно не сохраняет определяемые пользователем модели фильтра.

'Если этот член структуры - не ПУСТО (NULL), значение члена nMaxCustFilter должно определять размер, в TCHARs, буфера lpstrCustomFilter. 
'Для версии ANSI - это число байтов; для версии Unicode - это число символов.


DWORD         nMaxCustFilter; 
Определяет размер, в TCHARs, буфера, идентифицированного членом lpstrCustomFilter. Для версии ANSI - это число байтов; 
для версии Unicode - это число символов. Этот буфер должен быть, по крайней мере, длиной 40 символов. Если lpstrCustomFilter имеет 
значение ПУСТО (NULL) или указывает на пустую (NULL) строку, этот элемент игнорируется.

DWORD         nFilterIndex; 
'Определяет индекс текущего выбранного фильтра в органе управления Типы файлов (File Types). Буфер, указанный членом lpstrFilter, содержит пары 
'строк, которые задают фильтры. Первая пара строк имеет индексное значение 1, вторая пара 2, и так далее. Индекс нуля указывает на то, 
'что пользовательский фильтр определен при помощи lpstrCustomFilter. Вы можете определить индекс при вводе данных, чтобы обозначить 
'начальное описание  и модель фильтра для диалогового окна. Когда пользователь выбирает файл, член nFilterIndex возвращает значение индекса 
'текущего отображаемого фильтра. Если член nFilterIndex нулевой и lpstrCustomFilter имеет значение ПУСТО (NULL), система использует первый 
'фильтр в буфере lpstrFilter. Если все три члена нулевые или имеют значение ПУСТО (NULL), система не использует какой-либо фильтр и не 
'показывает какие-либо файлы в окне списка файлов диалогового окна. 

LPTSTR        lpstrFile; 
'Указатель на буфер, который содержит имя файла, используемое, чтобы инициализировать поле редактирования 
'Имя файла (File Name). Первый символ этого буфера должен быть ПУСТО (NULL), если в инициализации нет необходимости. 
'Когда функция GetOpenFileName или GetSaveFileName успешно возвращает значение, этот буфер содержит буквенный идентификатор диска, \
'путь, имя и расширение выбранного файла.

'Если установлен флажок OFN_ALLOWMULTISELECT и пользователь выбирает несколько файлов, буфер содержит текущий каталог, сопровождаемый 
'выбранными именами файлов. В диалоговых окнах в стиле Проводника, каталог и строки имен файлов отделяются значением ПУСТО (NULL), 
'с дополнительным символом ПУСТО (NULL) после последнего имени файла. В диалоговых окнах старого стиля, строки отделяются пробелами и 
'функция использует короткие имена для имен файлов с пробелами. Вы можете использовать функцию FindFirstFile, чтобы преобразовывать длинные 
'и короткие имена файлов. Если пользователь выбирает только один файл, строка lpstrFile не имеет разделителя между путем и именем файла.

'Если буфер слишком маленький, функция возвращает значение ЛОЖЬ (FALSE), а функция CommDlgExtendedError возвращает значение FNERR_BUFFERTOOSMALL. 
'В данном случае, первые два байта буфера lpstrFile содержат требуемый размер его, в байтах или символах.


DWORD         nMaxFile; 
Определяет размер буфера, в TCHARs, указанного членом lpstrFile. Для версии ANSI - это число байтов; для версии Unicode - это число символов. 
Буфер должен быть достаточно большим, чтобы сохранить путь и символьную строку или  строки имени файла, включая символ завершения 
строки ('0').Функции GetOpenFileName и GetSaveFileName возвращают значение ЛОЖЬ (FALSE), если буфер слишком маленький, чтобы 
содержать информацию о файле. Буфер должен быть по крайней мере длиной 256 символов.


LPTSTR        lpstrFileTitle; 
Указатель на буфер, который принимает имя файла и расширение (без информации о пути) выбранного файла. Этот элемент может быть значением ПУСТО (NULL).


DWORD         nMaxFileTitle; 
Определяет размер буфера, в  TCHARs, указанного элементом lpstrFileTitle. Для версии ANSI - это число байтов; для версии Unicode - это число символов. Этот элемент игнорируется, если lpstrFileTitle имеет значение ПУСТО (NULL).

LPCTSTR       lpstrInitialDir; 
'Указатель на строку, которая может определить начальный каталог. Алгоритм выбора начального каталога на различных платформах происходит по разному.
'Windows 2000/XP:

'Если lpstrFile содержит путь, этот путь - начальный каталог.
'Или же, член lpstrInitialDir задает начальный каталог.
'Или же, если приложение раньше использовало диалоговое окно Открыть (Open) или Сохранить Как (Save As), последний по времени использования  путь, выбирается как начальный каталог. Однако, если приложение не запускается в течение длительного времени, его сохраненный выбранный путь сбрасывается.
'Если член lpstrInitialDir - ПУСТО (NULL), а текущий каталог содержит какие-либо файлы типа, заданного фильтром, начальный каталог становиться текущим каталогом.
'Или же, начальный каталог -  каталог личных файлов текущего пользователя.
'Или же, начальный каталог - папка Рабочий стол (Desktop).


LPCTSTR       lpstrTitle; 
Указатель на строку, которая будет помещена в области заголовка диалогового окна. Если этот элемент имеет значение ПУСТО (NULL), система использует заданный по умолчанию заголовок (то есть Сохранить как (Save As) или Открыть (Open).


DWORD         Flags; 
http://www.vsokovikov.narod.ru/New_MSDN_API/Com_dlg_lib/str_openfilename.htm 

WORD          nFileOffset; 
'Определяет отсчитываемое от нуля, в TCHARs, смещение от начала пути до имени файла в строке, указанной элементом lpstrFile. Для версии ANSI - это число байтов; для версии Unicode - это число символов. Например, если lpstrFile указывает на следующую строку, "c:\dir1\dir2\file.ext", этот член содержит значение 13, чтобы обозначить смещение строки "file.ext". Если пользователь выбирает больше, чем один файл, nFileOffset - смещение до первого имени файла.

WORD          nFileExtension; 
Определяет отсчитываемое от нуля, в TCHARs,  смещение от начала пути до расширения имени файла в строке, указанной элементом lpstrFile. Для версии ANSI - это число байтов; для версии Unicode - это число символов.  Например, если lpstrFile указывает на следующую строку, "c:\dir1\dir2\file.ext", этот член содержит значение 18. Если пользователь не вводил с клавиатуры расширение и lpstrDefExt имеет значение ПУСТО (NULL), этот член определяет смещение, которое завершается символом нуля. Если пользователь ввел с клавиатуры "." в качестве последнего символа в имени файла, этот член определяется как нуль.

LPCTSTR       lpstrDefExt; 
Указатель на буфер, который содержит заданное по умолчанию расширение. Функции GetOpenFileName и GetSaveFileName это расширение добавляют в конец имени файла, если пользователь не выполнил ввода расширения с клавиатуры. Эта строка может быть любой длины, но добавляются только первые три символа. Строка не должна содержать точку (.). Если этот элемент имеет значение ПУСТО (NULL), а пользователь не выполняет ввода расширения с клавиатуры , в конец имени файла никакого расширения не добавляется.

LPARAM        lCustData; 
Определяет заданные программой данные, которые система пересылает фильтр (hook) - процедуре, идентифицированной членом lpfnHook. Когда система отправляет сообщение WM_INITDIALOG фильтр (hook) - процедуре, параметр сообщения lParam - указатель на структуру OPENFILENAME, определяемую, когда создавалось диалоговое окно. Фильтр-процедура (hook) может использовать этот указатель, чтобы получить значение элемента lCustData.

LPOFNHOOKPROC lpfnHook; 
Указатель на фильтр (hook) - процедуру. Этот член игнорируется, если член Flags не включает в себя флажок OFN_ENABLEHOOK.

LPCTSTR       lpTemplateName; 
Указатель на строку с символом нуля в конце, которая именует ресурс шаблона блока диалога в модуле, идентифицированном членом hInstance. Для пронумерованных ресурсов диалогового окна, это может быть значение, возвращенное макрокомандой MAKEINTRESOURCE. Этот член игнорируется, если в члене Flags не установлен флажок OFN_ENABLETEMPLATE. Если установлен флажок OFN_EXPLORER, система использует заданный шаблон, чтобы создать диалоговое окно, которое является дочерним для заданного по умолчанию диалогового окна в стиле Проводника. Если флажок OFN_EXPLORER не установлен, система использует шаблон, чтобы создать блок диалога старого стиля, которое заменяет заданное по умолчанию диалоговое окно.

#if (_WIN32_WINNT >= 0x0500)
void *        pvReserved;
DWORD         dwReserved;
DWORD         FlagsEx;
'Windows 2000/XP: Установка битов флажка, которые Вы можете использовать, чтобы инициализировать диалоговое окно. В настоящее время, этот член структуры может быть нулем или нижеследующим флажком.
'Флажок	Назначение
'OFN_EX_NOPLACESBAR	Если этот флажок устанавливается, панель мест не показывается на экране. Если этот флажок не установлен,  диалоговые окна в стиле Проводника включают панель мест, содержащую изображения обычно используемых папок, типа Фавориты (Favorites) и Рабочий стол (Desktop).



#endif    // (_WIN32_WINNT >= 0x0500)
} OPENFILENAME, *LPOPENFILENAME;

================
erem 


TYPE OPENFILENAME
lStructSize  AS DWORD 'Specifies the length, in bytes, of the structure. 
hwndOwner   AS LONG  'any valid window handle, or it can be NULL if the dialog box has no owner
hInstance   AS LONG  'for OFN_ENABLETEMPLATEHANDLE or ENABLETEMPLATE  flags

lpstrFilter  AS LONG  'pointer to string containing pairs of filter strings, ("*.TXT;*.DOC;*.BAK"), no spaces!

lpstrCustomFilter AS LONG 'null or pointer to a pair of null-terminated filter strings for preserving the filter pattern chosen by the user

nMaxCustFilter  AS DWORD 'the size, in bytes of the buffer identified by lpstrCustomFilter
nFilterIndex  AS DWORD 'index of the currently selected filter in the File Types 
lpstrFile   AS LONG  'Pointer to string of the file name to initialize control,can be multple if OFN_ALLOWMULTISELECT  set, _
'first char must be NULL if no initialization. Returns drive designator, path, file name, and extension of the selected file. 
nMaxFile   AS DWORD 'size in bytes of lpstrFile should be >256 chars
lpstrFileTitle  AS LONG  'Pointer to string that receives the file name and extension (without path information) of the selected file. This member can be NULL
nMaxFileTitle  AS DWORD 'size in bytes of lpstrFileTitle
lpstrInitialDir AS LONG  'pointer to string containing directory, different effect on different OS versions!
lpstrTitle   AS LONG  'pointer to string containing title
flags    AS DWORD '
nFileOffset  AS SHORT 'zero-based offset, number of chars  to the 1st character of the file name in lpstrFile (not path)
nFileExtension  AS SHORT 'zero-based offset, number of chars  to the 1st character of the file extension in lpstrFile (not path)
lpstrDefExt  AS LONG  'pointer to string to append as filename extension if the user fails to type an extension- only 3 characters are used, should not contain a period (.)
lCustData   AS LONG  'AS LPARM
lpfnHook   AS LONG  'AS LPOFNHOOKPROC, pointer to callback function
lpTemplateName  AS LONG  'pointer to string that names a dialog template resource in the module identified by the hInstance member
'#if (_WIN32_WINNT >= 0x0500)
'  void *        pvReserved;
'  DWORD         dwReserved;
'  DWORD         FlagsEx;
'#endif // (_WIN32_WINNT >= 0x0500)
END TYPE

DECLARE FUNCTION GetSaveFileName LIB "COMDLG32" ALIAS "GetSaveFileNameA" (pOpenfilename AS OPENFILENAME) AS LONG
DECLARE FUNCTION GetOpenFileName LIB "COMDLG32" ALIAS "GetOpenFileNameA" (pOpenfilename AS OPENFILENAME) AS LONG
Declare Function CommDlgExtendedError Lib "comdlg32.dll" Alias "CommDlgExtendedError" () As Long


CONST qfdOpen = 0
CONST qfdSave = 1
CONST pdfStrTerm$ = CHR$(0) + CHR$(0)
CONST qfdMaxFiles = 1000

TYPE QFILEDIALOG EXTENDS QOBJECT
PRIVATE:
tmpFileName  AS STRING
tmpFilter  AS STRING
tmpFileTitle AS STRING  'output string
OFN    AS OPENFILENAME

PUBLIC:
Parent   AS LONG   'Parent form handle, can be NULL
Caption   AS STRING  ' default is "Open" or "Save"
Filter   AS STRING  '*.*
FilterIndex  AS INTEGER  '0 based
InitialDir  AS STRING
Mode   AS INTEGER  'enum qfdOpen = Open (default),  qfdSave = save,
WarnIfOverWrite AS INTEGER  'warning to overwrite?
Filename  AS STRING
FileTitle  AS STRING
DefaultExt  AS STRING
MultiSelect  AS INTEGER
SelCount   AS INTEGER
NoChangeDir  AS INTEGER
Files(qfdMaxFiles) AS STRING

CONSTRUCTOR
Parent   = 0   'Parent form handle, can be NULL
Caption   = "Open"
Filter   = "All Files|*.*" + pdfStrTerm$
FilterIndex  = 0
InitialDir  = ""
Mode   = 0  'enum 0 = Open (default), 1 = save,
WarnIfOverWrite = 1  'warning to overwrite?
Filename  = ""
MultiSelect  = 0
SelCount   = 0
NoChangeDir  = 0
END CONSTRUCTOR


FUNCTION Execute() AS LONG
DIM FndSpace1  AS INTEGER
DIM FndSpace2  AS INTEGER
DIM StrLenth  AS INTEGER
DIM MyHresult  AS LONG   'return result

WITH QFILEDIALOG
	.OFN.lStructSize = SIZEOF(QfileDialog.OFN)
	.OFN.hwndOwner = .Parent
	.OFN.hInstance = 0
	
	'file filter string
	IF RIGHT$(.Filter, 2) <> pdfStrTerm$ THEN .Filter = .Filter + pdfStrTerm$
	.tmpFilter = REPLACESUBSTR$(.Filter, "|", CHR$(0)) 
	' .tmpFilter = REPLACESUBSTR$(.Filter, " ","")  'no spaces
	.OFN.lpstrFilter = VARPTR(QfileDialog.tmpFilter)
	.OFN.nFilterIndex = .FilterIndex
	
	IF .FileName = "" THEN 
		.tmpFileName = String$(1024,0)
		.OFN.nMaxFile = 1024
	ELSE
		.tmpFileName = .FileName
		IF LEN(.FileName) < 1024 THEN .tmpFileName = .tmpFileName + String$(1024-LEN(.FileName),0) ' must be > 256
		.OFN.nMaxFile = LEN(.tmpFileName)+1
	END IF
	
	.OFN.lpstrFile = VARPTR(QfileDialog.tmpFileName)
	.tmpFileTitle = String$(1024,0)    'string that gets the result,without path
	.OFN.nMaxFileTitle = 1024'LEN(.tmpFileTitle)
	.OFN.lpstrFileTitle = VARPTR(QfileDialog.tmpFileTitle)
	.OFN.lpstrInitialDir = VARPTR(QfileDialog.InitialDir)
	.OFN.lpstrTitle = VARPTR(QfileDialog.Caption)
	IF .DefaultExt <> "" THEN .OFN.lpstrDefExt = VARPTR(QfileDialog.DefaultExt)
	
	IF .WarnIfOverWrite THEN
		.OFN.flags =OFN_HIDEREADONLY OR OFN_OVERWRITEPROMPT
	ELSE
		.OFN.flags =OFN_HIDEREADONLY
	END IF
	IF .MultiSelect THEN .OFN.flags = .OFN.flags OR OFN_ALLOWMULTISELECT OR OFN_EXPLORER
	IF .NoChangeDir THEN .OFN.flags = .OFN.flags OR OFN_NOCHANGEDIR
	
	
	IF .Mode = qfdOpen THEN
		MyHresult = GetOpenFileName(QfileDialog.OFN)
	ELSE
		IF .Mode = qfdSave THEN
			MyHresult = GetSaveFileName(QfileDialog.OFN)
		ELSE
			ShowMessage "Invalid Mode in FileDialog"
		END IF
	END IF
	
	IF MyHresult <> 0 THEN        'returns 0 on CANCEL
		'.tmpFileName = STRING$(.OFN.nMaxFile, 32)  'allocate string memory
		'.FileName = STRING$(.OFN.nMaxFile, 32)   'allocate string memory in case
		MEMCPY(VARPTR(QfileDialog.tmpFileName), QfileDialog.OFN.lpstrFile, QfileDialog.OFN.nMaxFile) 'get string
		StrLenth = (INSTR(QfileDialog.tmpFileName, pdfStrTerm$))
		.tmpFileName = LEFT$(QfileDialog.tmpFileName, StrLenth-1)
		.FileName = .tmpFileName
		IF .MultiSelect THEN
			.tmpFileName = REPLACESUBSTR$(.tmpFileName, CHR$(0), CHR$(2))    'prevent string termination
			FndSpace1 = 1:  FndSpace2 = 0
			.SelCount = -1        'for 0 indexing
			DO
			FndSpace2 = INSTR(FndSpace1, .tmpFileName, CHR$(2))  'null doesn't work, trick w/chr 2
			IF FndSpace2 = 0 THEN
				EXIT DO
			ELSE
				.SelCount++
				.Files(.SelCount) = MID$(.tmpFileName, FndSpace1, (FndSpace2 - FndSpace1))
				FndSpace1 = FndSpace2 + 1
				IF .SelCount > qfdMaxFiles THEN EXIT DO  'too many files
			END IF
			LOOP UNTIL FndSpace2 >= StrLenth
		ELSE
			.FileTitle = STRING$(.OFN.nMaxFileTitle, 32)  'allocate
			MEMCPY(VARPTR(QfileDialog.FileTitle), QfileDialog.OFN.lpstrFileTitle, QfileDialog.OFN.nMaxFile)
			.FileTitle = LEFT$(.FileTitle, (INSTR(.FileTitle, pdfStrTerm$))-1)
		END IF
	END IF
	RESULT = MyHresult
END WITH
END FUNCTION

END TYPE
$ENDIF ' _RQDIALOGINC



'dim i as integer
'DIM fDialog as qfiledialog
'fDialog.Caption = "QfileDialog test"
'fDialog.FileName= "test.txt"
'fDialog.InitialDir = "C:\RapidQ"
'fDialog.MultiSelect = 1
'IF fDialog.Execute THEN
'IF fDialog.MultiSelect THEN'
' for i = 0 to fDialog.SelCount
' ShowMessage fDialog.Files(i) 'string #0 is the directory
' next i
'ELSE
' ShowMessage "file name & path =" + fDialog.FileName
' ShowMessage "file name no path =" + fDialog.FileTitle
'END IF
'END IF


