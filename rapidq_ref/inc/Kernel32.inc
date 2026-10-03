'KERNEL32.DLL Functions
'FILE ADDED: Release Version 1
'FILE UPDATED: Release Version 2

'Adapted for RapidQ by Bryn Mosher (bdmnky@hotmail.com)
'WIN32API RapidQ $Includes
'Home page - http://home.pacbell.net/brynm/
'RapidQ - http://www.basicguru.com/abc/rapidq/


'CopyFile()
	'Copies a file
	'EXAMPLE:
		'CopyFile ("C:\Old.File", "C:\New.File", 1) 'Will fail if C:\New.File exists

	Declare Function CopyFile Lib "kernel32.dll" Alias_
	 "CopyFileA" (lpExistingFileName As String,lpNewFileName As String,_
	 bFailIfExists As Long) As Long


'DeleteFile()
	'Deletes a file
	'EXAMPLE:
		'DeleteFile("C:\DeleteThis.File")

	Declare Function DeleteFile Lib "kernel32.dll" Alias_
	 "DeleteFileA" (lpFileName As String) As Long


'ExitProcess()
	'Kills current process with uExitCode errorlevel
	'EXAMPLE:
		'ExitProcess(23)

	Declare Function ExitProcess Lib "kernel32.dll" Alias_
	 "ExitProcess" (uExitCode As Long) as integer


'GetCommandLine()

	Declare Function GetCommandLine Lib "kernel32.dll" Alias_
	 "GetCommandLineA" As String


'GetComputerName()
	'Gets Computer Name
	'Pass VarPtr(lpBufferStringVar). Variable will now hold the data.
	'Wrapper is GetComputerName$ in NOTA.inc
	'EXAMPLE:
		'GetComputerName( VarPtr(StringVar$), VarPtr(LengthOfStringVar&) )

	Declare Function GetComputerName Lib "kernel32.dll" Alias_
	 "GetComputerNameA" (lpBuffer As Long, nSize As Long) As Long


'GetConsoleCP()

	Declare Function GetConsoleCP Lib "kernel32.dll" Alias_
	 "GetConsoleCP" As Long


'GetConsoleOutputCP()

	Declare Function GetConsoleOutputCP Lib "kernel32.dll" Alias_
	 "GetConsoleOutputCP" As Long


'GetCurrentProcess()

	Declare Function GetCurrentProcess Lib "kernel32.dll" Alias_
	 "GetCurrentProcess" As Long


'GetCurrentProcessID()

	Declare Function GetCurrentProcessId Lib "kernel32.dll" Alias_
	"GetCurrentProcessId" As Long


'GetCurrentThread()

	Declare Function GetCurrentThread Lib "kernel32.dll" Alias_
	 "GetCurrentThread" As Long


'GetCurrentThreadID()

	Declare Function GetCurrentThreadId Lib "kernel32.dll" Alias_
	 "GetCurrentThreadId" As Long


'GetDiskFreeSpace()

	Declare Function GetDiskFreeSpace Lib "kernel32.dll" Alias_
	 "GetDiskFreeSpaceA" (lpRootPathName As String,_
	 lpSectorsPerCluster As Long, lpBytesPerSector As Long,_
	 lpNumberOfFreeClusters As Long, lpTtoalNumberOfClusters As Long) As Long


'GetEnvironmentStrings()

	Declare Function GetEnvironmentStrings Lib "kernel32.dll" Alias_
	 "GetEnvironmentStringsA" As String


'GetLastError()

	Declare Function GetLastError Lib "kernel32.dll" Alias_
	 "GetLastError" As Long


'GetLogicalDrives()

	Declare Function GetLogicalDrives Lib "kernel32.dll" Alias_
	 "GetLogicalDrives" As Long


'GetOEMCP()

	Declare Function GetOEMCP Lib "kernel32.dll" Alias_
	 "GetOEMCP" As Long


'GetProcessHeap()

	Declare Function GetProcessHeap Lib "kernel32.dll" Alias_
	 "GetProcessHeap" As Long


'GetSystemDefaultLangID()

	Declare Function GetSystemDefaultLangID Lib "kernel32.dll" Alias_
	 "GetSystemDefaultLangID" As Integer


'GetSystemDefaultLCID()

	Declare Function GetSystemDefaultLCID Lib "kernel32.dll" Alias_
	 "GetSystemDefaultLCID" As Long


'GetTempPath()
	'Pass VarPtr(lpBufferStringVar). Variable will now hold the data.
	'Wrapper is GetTempPath$() in NOTA.inc
	'EXAMPLE:
		'GetTempPath( VarPtr(LengthOfStringVar&), VarPtr(StringVar$) )

	Declare Function GetTempPath Lib "kernel32.dll" Alias_
	 "GetTempPathA" (nBufferLength As Long, lpBuffer As long) As Long

'GetThreadLocale()

	Declare Function GetThreadLocale Lib "KERNEL32.dll" Alias_
	 "GetThreadLocale" As Long


'GetTickCount()

	Declare Function GetTickCount Lib "kernel32.dll" Alias_
	 "GetTickCount" As Long


'GetUserDefaultLangID()

	Declare Function GetUserDefaultLangID Lib "kernel32.dll" Alias_
	 "GetUserDefaultLangID" As Integer


'GetUserDefaultLCID()

	Declare Function GetUserDefaultLCID Lib "kernel32.dll" Alias_
	 "GetUserDefaultLCID" As Long


'GetVersion()

	Declare Function GetVersion Lib "kernel32.dll" Alias_
	 "GetVersion" As DWord


'GetVersionEx()
	'Gets Extended Version Information
	'I recomend you use the wrapper code in NOTA.Inc to call this -bm :)-~
	'When it works - bm :(-~
	'Use it to test Platform compatibility by using the value 
	'Set to accept long data instead of OsVersionInfo for VarPtr()

	Type OSVERSIONINFO
		dwOSVersionInfoSize As Long
		dwMajorVersion As Long
		dwMinorVersion As Long
		dwBuildNumber As Long
		dwPlatformId As Long
		'dwPlatformId = Value,Platform
		'VER_PLATFORM_WIN32s, Win32s on Windows 3.1. 
		'VER_PLATFORM_WIN32_WINDOWS, Win32 on Windows 95 or Windows 98. 
			'For Windows 95, dwMinorVersion is zero. 
			'For Windows 98, dwMinorVersion is greater than zero.
		'VER_PLATFORM_WIN32_NT, Win32 on Windows NT/Windows 2000.
		szCSDVersion As String * 255
	End Type

	Declare Function GetVersionEx Lib "kernel32.dll" Alias_
	 "GetVersionExA" (lpVersionInformation As long) As Long


'GetWindowsDirectory()
	'Gets Windows Directory
	'Pass VarPtr(lpBufferStringVarVar). Variable will now hold the data.
	'EXAMPLE:
		'GetWindowsDirectory( VarPtr(StringVar$), VarPtr(LengthOfStringVar&) )

	Declare Function GetWindowsDirectory Lib "kernel32.dll" Alias_
	 "GetWindowsDirectoryA" (lpBuffer As long, nSize As Long) As Long
