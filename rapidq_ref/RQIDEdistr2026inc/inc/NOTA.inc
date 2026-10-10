'Network of the Apes RapidQ Include
'FILE ADDED: Release Version 1
'FILE UPDATED: Release Version 2

'WIN32API RapidQ $Includes
'Home page - http://home.pacbell.net/brynm/
'RapidQ - http://www.basicguru.com/abc/rapidq/

' These are useful functions that are used on NetWork Of The Apes
' Most are wrappers to API calls.
' All are written by Bryn Mosher (bdmnky@hotmail.com).
' See EOF for reserved words and values
' We must declare the functions in NOTA first to get dynamic values.
' The other API files do not require this

	Declare Function ApeDate as String
	Declare Function AsciiKrypt (bpmKryptLine$ as string, bpmKryptPass$ as string, bpmKryptMode& as integer) as string
	Declare Function CloseAppKey as string
	Declare Function CloseAppSysKey as string
	Declare Function CloseNOTASys as String
	Declare Function CloseNOTAUser as String
	Declare Function Die as long
	Declare Function DivBytes (bpmNumBytes& as double, bpmBytesFormat$ as string) as long
	Declare function DivMiliSecs$ (bpmDivTime& as long) as string
	Declare Function GetComputerName$ as String
	Declare Function GetFreeDrive (bpmDriveLetter$ as string) as long
	Declare Function GetLastError$ (bpmErrorFileName$ as string, bpmErrorCodeNumber& as long) as string
	Declare function GetTempPath$ as string
	Declare Function GetUserName$ as String
	Declare Function GetWindowsDirectory$ as string
	Declare Function KillIt as Long
	Declare Function LogEvent (bpmSeverity$ as String, bpmCategory$ as string, bpmEventText$ as string) as String
	Declare Function MakeMOTD as String
	Declare Function OpenAppKey as string
	Declare Function OpenAppSysKey as string
	Declare Function OpenNOTASys as String
	Declare Function OpenNOTAUser as String
	Declare Function ProgramName$ as string

' >>>>> RESERVED WORDS AND VALUES <<<<<<
	'NAME - (Readable/Writeable) - Description

	'ApeDate$  - (RW) - Formatted Date for NOTA
			Dim ApeDate$ as String : ApeDate$ = ApeDate()
	'AppKey - (RW) - The User Hive registry key for OpenAppKey().
			Dim AppKey as QRegistry : AppKey.RootKey = &H80000001
	'AppKeyString$ - The default registry path for *AppKey() functions.
			Dim AppKeyString$ as String : AppKeyString$ = ("Software\\NetWork_of_the_Apes\\Apps\\" + Left$( ProgramName$, (Len(ProgramName$) - 4) ) )
	'AppSysKey - (RW) - The User Hive registry key for OpenAppKey().
			Dim AppSysKey as QRegistry : AppSysKey.RootKey = &H80000002
	'AstronomicalUnit - (R) - 1 Astrononical Unit! The value of the semimajor axis
    'of the orbit of the Earth.
			const AstronomicalUnit = 149.59787E9
	'BPM3DMedia - (n/a) - User Defined Type for my 3D portfolio files
			Type BPM3DMedia
				Format as string * 8
				Name as string * 64
				Description as string * 256
			End type
	'HI - (R) - I use it.  Really
			const Hi = "Hi."
	'Julian1900  - (R) - 1900 Julian
			const Julian1900 = 2415020.0
	'Julian2000  - (R) - Y2K Julian
			const Julian2000 = 2451545.0
	'NOTA$  - (R) - NOTA String
			const NOTA$ = "NetWork_of_the_Apes"
	'NOTARegRoot$ - (R) - Root Registry Key
			const NOTARegRoot$ = "Software\\Network_Of_The_Apes"
	'NOTASys - (RW) - NOTA Local Machine Registry Key (I know I'm ignoring CONST)
			Dim NOTASys as QRegistry : NOTASys.RootKey = &H80000002
	'NOTAUser - (RW) - NOTA Current User Registry Key (I know I'm ignoring CONST)
			Dim NOTAUser as QRegistry : NOTAUser.RootKey = &H80000001
	'Pi - (R) - Pi of course.
			const Pi = 3.14159265358979323846
	'Planck - (R) - Planck's Constant
			const Planck = 6.62628e-34
	'SolarDay - (R) - 1 Solar Day in seconds
			const SolarDay = 86400.0
	'SpeedOfLight - (R) - Speed of light
			const SpeedOfLight = 299792458.0
	'TropicalYear - (R) - 1 tropical year in days
			const TropicalYear = 365.242198781

' >>> END RESERVED WORDS AND VALUES <<<


'ApeDate()
	'Returns NOTA Formatted Date
	'EXAMPLE:
		'GoodDate$ = ApeDate

	Function ApeDate
		dim bpmtDate$ as String
		bpmtDate$ = Delete$(DATE$,3,1)
		bpmtDate$ = Delete$(bpmtDate$,5,1)
		if Right$(Date$,4) = "2000" then
			bpmtDate$ = ( Delete$(bpmtDate$,5,4) + "2K" )
		end if
		Result = bpmTDate$
	end Function


'AsciiKrypt()
	'Encrypts or decrypts a line of text
	'bpmKryptMode& = "1" set the flag for encrypting the data (scramble them eggs)
	'bpmKryptMode& = "0" set the flag for decrypting the data (unscramble)
	'thanks to Scott (SandDune@maine.rr.com) for the tutorial code
	'EXAMPLE:
		'AsciiKrypt ("Text to be encrypted", "Password", 1)
		'AsciiKrypt ("Text to be decrypted", "Password", 0)

	'EXTRA EXAMPLE:
	'As a strange bonus, this function can be called with the mode bit backwards like this:
		'AsciiKrypt ("Text to be encrypted", "Password", 0)
		'AsciiKrypt ("Text to be decrypted", "Password", 1)

	Function AsciiKrypt (bpmKryptLine$ as string, bpmKryptPass$ as string, bpmKryptMode& as integer)
		dim bpmKryptLen# as integer
		Dim bpmKryptLoop# as integer
		dim bpmKryptNewLine$ as String
		Dim bpmKryptScram# as integer
		dim bpmKryptChar$ as String
		dim bpmKrypted$ as string
		dim bpmKryptNewChar$ as String
		Dim bpmKryptAscii# as integer
		dim bpmKryptPassLen# as integer
		bpmKryptPassLen# = len(bpmKryptPass$)
		bpmKryptLen# = len(bpmKryptLine$) ' get the length of the line to do
		bpmKrypted$ = ""  ' initialize a new line to create
		for bpmKryptLoop# = 1 to bpmKryptLen#
			bpmKryptChar$ = mid$(bpmKryptLine$, bpmKryptLoop#, 1)
			bpmKryptAscii# = asc(bpmKryptChar$)
			bpmKryptScram# = bpmKryptLoop# mod bpmKryptPassLen#
			if bpmKryptMode& = "1" then
				bpmKryptAscii# = bpmKryptAscii# + asc( mid$(bpmKryptPass$, bpmKryptScram#, 1) )
				else
					bpmKryptAscii# = bpmKryptAscii# - asc( mid$(bpmKryptPass$, bpmKryptScram#, 1) )
			end if
			bpmKryptNewChar$ = chr$(bpmKryptAscii#)
			bpmKrypted$ = bpmKrypted$ + bpmKryptNewChar$
		next
		AsciiKrypt = bpmKrypted$
	end Function


'CloseAppKey()
	'Closes Software\Network_Of_The_apes\[YourAppsName]
	'Returns Value "LastOpened" 
	'EXAMPLE:
		'TimeOpened$ = CloseAppKey

	Function CloseAppKey
		CloseAppKey = AppKey.ReadString("LastOpened")
		AppKey.CloseKey
	End function


'CloseAppSysKey()
	'Closes Software\Network_Of_The_apes\[YourAppsName]
	'Returns Value "LastOpened" 
	'EXAMPLE:
		'TimeOpened$ = CloseAppSysKey

	Function CloseAppSysKey
		CloseAppSysKey = AppSysKey.ReadString("LastOpened")
		AppSysKey.CloseKey
	End function


'CloseNOTASys()
	'Closes HKLM NOTA Registry Key
	'Returns Value "LastOpened"
	'EXAMPLE:
		'TimeOpened$ = CloseNOTASys

	Function CloseNOTASys
		CloseNOTASys = NOTASys.ReadString("LastOpened")
		NOTASys.CloseKey
	End function


'CloseNOTAUser()
	'Closes HKCU NOTA Registry Key
	'Returns Value "LastOpened"
	'EXAMPLE:
		'TimeOpened$ = CloseNOTAUser

	Function CloseNOTAUser
		CloseNOTAUser = NOTAUser.ReadString("LastOpened")
		NOTAUser.CloseKey
	END Function


'Die()
	'Kills the program with exit code 9999
	'EXAMPLE:
		'If Exit& = 1 then
		'	Die
		'end if

	Function Die
		ExitProcess(9999)
	End Function


'DivBytes()
	'converts bytes to KB, MB, GB, TB
	'EXAMPLE:
		'DivBytes (36626545, MB)

	Function DivBytes (bpmNumBytes& as double, bpmBytesFormat$ as string) as long
		Dim bpmErrFormat& as integer
		dim bpmCheckSize$ as string
		bpmErrFormat& = 0
		if bpmNumBytes& < 1024 then
			DivBytes = bpmNumBytes&
			else
			if UCase$(bpmBytesFormat$) = "KB" then
				DivBytes = (bpmNumBytes& / 1024)
				bpmErrFormat& = 1
			end if
			if UCase$(bpmBytesFormat$) = "MB" then
				DivBytes = ( (bpmNumBytes& / 1024) / 1024 )
				bpmErrFormat& = 1
			end if
			if UCase$(bpmBytesFormat$) = "GB" then
				DivBytes = ( ( (bpmNumBytes& / 1024) / 1024 ) /1024 )
				bpmErrFormat& = 1
			end if
			if UCase$(bpmBytesFormat$) = "TB" then
				DivBytes = ( ( ( (bpmNumBytes& / 1024) / 1024 ) /1024 ) / 1024 )
				bpmErrFormat& = 1
			end if
			if bpmErrFormat& = 0 then
				DivBytes = 0
			end if
		end if
	end function


'DivMiliSecs$()
	'Converts miliseconds to Days:Hours:Minutes:Seconds format
	'EXAMPLE:
		'LegibleTime$ = DivMiliSecs$(2323564)

	function DivMiliSecs$
		Dim bpmDivRemainder& as Long
		dim bpmDivDays$ as string
		dim bpmDivhours$ as string
		dim bpmDivMinutes$ as string
		dim bpmDivSeconds$ as string
		bpmDivRemainder& = bpmDivTime&
		bpmDivDays$ = "00"
		bpmDivHours$ = "00"
		bpmDivMinutes$ = "00"
		bpmDivSeconds$ = "00"
		'Quick sheck for lame data	
		if bpmDivRemainder& < 1000 then
			DivMiliSecs$ = ( "00:00:00:00." + str$(bpmDivRemainder&) )
			end 
		end if
		'Get Days
		If bpmDivRemainder& > 86400000 then
			bpmDivDays$ = Str$( Fix(bpmDivRemainder& / 86400000) )
			If Len(bpmDivDays$) = 1 then
				bpmDivDays$ = "0" + bpmDivDays$
			end if
			bpmDivRemainder& = ( bpmDivRemainder& - ( Val(bpmDivDays$) * 86400000) )
		end if
		'Get Hours
		If bpmDivRemainder& > 3600000 then
			bpmDivHours$ = Str$( Fix(bpmDivRemainder& / 3600000) )
			If Len(bpmDivHours$) = 1 then
				bpmDivHours$ = "0" + bpmDivHours$
			end if
			bpmDivRemainder& = ( bpmDivRemainder& - ( Val(bpmDivHours$) * 3600000) )
		end if
		'Get Minutess
		If bpmDivRemainder& > 60000 then
			bpmDivMinutes$ = Str$( Fix(bpmDivRemainder& / 60000) )
			If Len(bpmDivMinutes$) = 1 then
				bpmDivMinutes$ = "0" + bpmDivMinutes$
			end if
			bpmDivRemainder& = ( bpmDivRemainder& - ( Val(bpmDivMinutes$) * 60000) )
		end if
		'Get Seconds
		If bpmDivRemainder& > 1000 then
			bpmDivSeconds$ = Str$( Fix(bpmDivRemainder& / 1000) )
			If Len(bpmDivSeconds$) = 1 then
				bpmDivSeconds$ = "0" + bpmDivSeconds$
			end if
			bpmDivRemainder& = ( bpmDivRemainder& - ( Val(bpmDivSeconds$) * 1000) )
		end if
		'write final version
		DivMiliSecs$ = ( bpmDivDays$ + ":" + bpmDivhours$ + ":" +_
		 bpmDivMinutes$ + ":" + bpmDivSeconds$ + "." + Str$(bpmDivRemainder&) )
	end function


'GetComputerName$()
	'Gets Computer Name
	'Wraps GetComputerName() in kernel32.dll
	'EXAMPLE:
	'	? GetComputerName$
	'EXTRA EXAMPLE:
	'An interesting usage will use the network path of the name as a folder, thus accesing network resources:
	'	dim MakeSelection as QOpenDialog
	'	MakeSelection.Filter = "Plain text files|*.txt|All Files|*.*"
	'	MakeSelection.InitialDir = ("\\\\" + GetComputerName$)
	'	if MakeSelection.Execute then
	'		showmessage MakeSelection.FileName
	'		else
	'			ShowMessage "Open file failed."
	'	end if

	Function GetComputerName$
		dim bpmMachineName$ as string
		dim bpmMachineNameLength& as long
		bpmMachineName$ = Space$(200)
		bpmMachineNameLength& = 200
		GetComputerName( VarPtr(bpmMachineName$), VarPtr(bpmMachineNameLength&) )
		GetComputerName$ = Left$(bpmMachineName$, bpmMachineNameLength&)
	end function


'GetFreeDrive()
	'Returns number of free bytes for drive letter
	'Only pass drive letter! (ie: 'c' not 'c:\')
	'It will return 0 if the passed letter is invalid
	'or the drive doesn't exist.
	'Wraps GetDiskFreeSpace in Kernel32.dll
	'EXAMPLE:
		'GetFreeDrive("C")

	Function GetFreeDrive (bpmDriveLetter$ as string) as long
		if LEN(bpmDriveLetter$) > 1 then
			GetFreeDrive = 0
			else
				If DirExists( (bpmDriveLetter$ + ":\\") ) then
					dim bpmNumberOfFreeClusters& as long
					dim bpmSectorsPerCluster& as long
					dim bpmBytesPerSector& as long
					Dim bpmTotalNumberOfClusters& as long
					Dim bpmTotalFree& as long
					bpmNumberOfFreeClusters& = VarPtr(bpmNumberOfFreeClusters&)
					bpmSectorsPerCluster& = VarPtr(bpmSectorsPerCluster&)
					bpmBytesPerSector& = VarPtr(bpmBytesPerSector&)
					bpmTotalNumberOfClusters& = VarPtr(bpmTotalNumberOfClusters&)
					GetDiskFreeSpace( (bpmDriveLetter$ + ":\\"), bpmSectorsPerCluster&,_
					 bpmBytesPerSector&,	bpmNumberOfFreeClusters&, bpmTotalNumberOfClusters& )
					GetFreeDrive = ( bpmNumberOfFreeClusters& * bpmSectorsPerCluster& * bpmBytesPerSector&)
					else
						GetFreeDrive = 0
				end if
		end if
	end function


'GetLastError$()
	'Gets the text for the last API error
	'NOTE: you must call GetLastError to get the Error Code first.
	'If the Error Code = 0 nothing will happen.
	'If you leave this in your final app, you must include the Error Code file.
	'The ErrorFile path defaults to the app path, but may be specified. 
	'EXAMPLE:
		'dim Error& as long
		'copyFile("bob","guido",0)
		'Error& = GetLastError
		'ShowMessage ( GetLastError$("NT4SP6ErrList.txt", Error&) )

	Function GetLastError$
		dim bpmLookUpError$ as string
		bpmLookUpError$ = "No error match found"
		if mid$(bpmErrorFileName$,2,2) = ":\\" then
			bpmErrorFileName$ = bpmErrorFileName$
			else
				if mid$(bpmErrorFileName$,1,1) = chr$(92) then
					if FileExists(Left$(CurDir$,2) + "\\" + bpmErrorFileName$) then
							bpmErrorFileName$ = ( Left$(CurDir$,2) + "\\" + bpmErrorFileName$)
						else
							if FileExists(CurDir$ + "\\" + bpmErrorFileName$) then
								bpmErrorFileName$ = (CurDir$ + "\\" + bpmErrorFileName$)
								else
									GetLastError$ = ("GetLastError$ Error!\n" + bpmErrorFileName$ + "\n Error file not found.  See syntax in NOTA.inc.")
							end if
					end if
				end if
		end if
		if bpmErrorCodeNumber& = 0 then
			GetLastError$ = "ErrorCode = 0 'No Error.'"
			end
		end if
		dim bpmErrorFile as QFileStream
		if fileExists(bpmErrorFileName$) then
			bpmErrorFile.open(bpmErrorFileName$,0)
			dim bpmErrorTemp$ as string
			dim bpmErrorWaldo& as long
			dim bpmErrorHex$ as string
			for bpmErrorWaldo&  = 0 to bpmErrorFile.LineCount
				bpmErrorTemp$ = bpmErrorFile.Readline
				if Val( Mid$( bpmErrorTemp$, 1, INSTR(bpmErrorTemp$, "\t") ) ) = bpmErrorCodeNumber& then
					bpmErrorTemp$ = Right$( bpmErrorTemp$, ( len(bpmErrorTemp$) - instr(bpmErrorTemp$, "\t") ) )
					bpmErrorHex$ = Mid$( bpmErrorTemp$, 1, ( INSTR(bpmErrorTemp$, "\t") - 1 ) )
					bpmErrorWaldo& = bpmErrorFile.LineCount
					bpmErrorTemp$ = Right$( bpmErrorTemp$, ( len(bpmErrorTemp$) - instr(bpmErrorTemp$, "\t") ) )
					bpmLookUpError$ = (bpmErrorTemp$ + "\nERRORCODE:" + str$(bpmErrorCodeNumber&) + "  HEX:" + bpmErrorHex$)
				end if
			next
			Else
				GetLastError$ = ("GetLastError$ Error!\n" + bpmErrorFileName$ + "\n Error file not found.  See syntax in NOTA.inc.")
				end
		end if
		bpmErrorFile.Close
		GetLastError$ = bpmLookUpError$
	End Function


'GetTempPath$()
	'Gets Temporary folder path
	'Wraps GetTempPath() in kernel32.dll
	'EXAMPLE:
		'? "Temp is ";GetTempPath$

	Function GetTempPath$
		dim bpmLengthOfTemp& as long
		dim bpmTempPath$ as string
		bpmTempPath$ = Space$(200)
		bpmLengthOfTemp& = 200
		GetTempPath( VarPtr(bpmLengthOfTemp&), VarPtr(bpmTempPath$) )
		bpmTempPath$ = RTrim$(bpmTempPath$)
		if RIGHT$( bpmTempPath$, ( Len(bpmTempPath$) - 2 ) ) = "\\" then
			bpmLengthOfTemp& = ( Len(bpmTempPath$) - 2 )
			else
				bpmLengthOfTemp& = ( Len(bpmTempPath$) - 1 )
		end if
		GetTempPath$ = Left$(bpmTempPath$, bpmLengthOfTemp&)
	end Function


'GetUserName$()
	'Gets User Name by wrapping GetUserName() in advapi32.inc
	'EXAMPLE:
		'User$ = GetUserName$

	Function GetUserName$
		Dim bpmGetUserVar$ as string
		Dim bpmGetUserLength& as long
		bpmGetUserVar$ = Space$(200)
		bpmGetUserLength& = 200
		GetUserName( VarPtr(bpmGetUserVar$), VarPtr(bpmGetUserLength&) )
		GetUserName$ = Left$(bpmGetUserVar$, (bpmGetUserLength& - 1) )
	end function


'GetWindowsDirectory$()
	'Returns Windows Directory
	'Wraps GetWindowsDirectory in Kernel32.dll
	'EXAMPLE:
		'? GetWindowsDirectory$

	Function GetWindowsDirectory$
		Dim bpmWinDir$ as string
		Dim bpmWinDirLength& as long
		dim bpmReturnLength& as long
		bpmWinDirLength& = 200
		bpmWinDir$ = Space$(200)
		bpmReturnLength& = GetWindowsDirectory( VarPtr(bpmWinDir$), VarPtr(bpmWinDirLength&) )
		GetWindowsDirectory$ = Left$(bpmWinDir$, bpmReturnLength&)
	end function


'KillIt()
	'my own, dont ask why

	Function KillIt
		Application.Terminate
	End Function


'LogEvent()
	'Logs an event in the WinNT Event log using RKTool LogEvent.EXE
	'EXAMPLE:
		'LogEvent("i", "2323", "Information event 2323")

	Function LogEvent (bpmSeverity$ as String, bpmCategory$ as string, bpmEventText$ as string)
		Logevent = STR$( shell( ("LOGEVENT.EXE -s " + bpmSeverity$ + " -c " + bpmCategory$ + " \"" + bpmEventText$ + "\"") ) )
	end Function


'MakeMOTD()
	'Creates a new MOTD text file
	'Returns MOTD's path and opens the MOTD
	'EXAMPLE:
		'WhereIsTheMOTD$ = MakeMOTD

	Function MakeMOTD 
		Dim bpmMOTDRoot$ as string
		Dim bpmKey as QRegistry
		bpmKey.RootKey = &H80000002
		bpmKey.OpenKey ("Software\\Network_Of_The_Apes", 1)
		if bpmKey.ValueExists("MOTDRoot") = 0 then
			bpmKey.WriteString("MOTDRoot","C:")
			bpmMOTDRoot$ = "C:"
			else
				bpmMOTDRoot$ = bpmKey.ReadString("MOTDRoot")
		end if
		bpmKey.CloseKey
		if FileExists( (bpmMOTDRoot$ + "\\MOTD_" + ApeDate$ + ".txt") ) = 0 then
			dim bpmMOTDFile as QfileStream
			bpmMOTDFile.Open( (bpmMOTDRoot$ + "\\MOTD_" + ApeDate$ + ".txt"), 65535 )
			bpmMOTDFile.WriteLine("(((((((((((((((((((((((((((((((((NETWORK OF THE APES)))))))))))))))))))))))))))))))))")
			bpmMOTDFile.WriteLine("MESSAGE OF THE DAY")
			bpmMOTDFile.WriteLine( (Date$ + "  " +  Time$) )
			bpmMOTDFile.WriteLine("-------------------------------------------------------------------------------------")
			bpmMOTDFile.WriteLine("")
			bpmMOTDFile.WriteLine("")
			bpmMOTDFile.WriteLine("")
			bpmMOTDFile.WriteLine("  bm :)-~")
			bpmMOTDFile.WriteLine("")
			bpmMOTDFile.WriteLine("-------------------------------------------------------------------------------------")
			bpmMOTDFile.WriteLine( ("For previous messages of the day look at " + bpmMOTDRoot$ + "\\MOTD_LOG.TXT.") )
			bpmMOTDFile.Close
		end if
		Shell ("NotePad.EXE " + bpmMOTDRoot$ + "\\MOTD_" + ApeDate$ + ".txt")
		MakeMOTD = (bpmMOTDRoot$ + "\\MOTD_" + ApeDate$ + ".txt")
	End Function


'OpenAppKey()
	'Opens Software\Network_Of_The_apes\Apps\[YourAppsName]
	'Returns Value "LastOpened"
	'EXAMPLE:
		'WriteTime$ = OpenAppKey
		'CloseAppKey
	'EXTRA EXAMPLE:
	'To overwrite the Key name use, overwrite AppKeyString$.
	'	AppKeyString$ = "Software\\[The key you want]"
		'WriteTime$ = OpenAppKey
		'CloseAppKey

	Function OpenAppKey
		AppKey.OpenKey(AppKeyString$, 1)
		AppKey.WriteString( "LastOpened", (Date$ + "  " + Time$) )
		OpenAppKey = AppKey.ReadString("LastOpened")
	End Function


'OpenAppSysKey()
	'Opens Software\Network_Of_The_apes\Apps\[YourAppsName]
	'Returns Value "LastOpened"
	'EXAMPLE:
		'WriteTime$ = OpenAppSysKey
		'CloseAppSysKey
	'EXTRA EXAMPLE:
	'To overwrite the Key name use, overwrite AppKeyString$.
	'	AppKeyString$ = "Software\\[The key you want]"
		'WriteTime$ = OpenAppSysKey
		'CloseAppSysKey

	Function OpenAppSysKey
		AppSysKey.OpenKey(AppKeyString$, 1)
		AppSysKey.WriteString( "LastOpened", (Date$ + "  " + Time$) )
		OpenAppSysKey = AppSysKey.ReadString("LastOpened")
	End Function


'OpenNOTASys()
	'Opens HKLM NOTA Registry Key
	'Returns Value "LastOpened"
	'EXAMPLE:
		'WriteTime$ = OpenNOTASys
		'CloseNOTASys

	Function OpenNOTASys
		NOTASys.OpenKey("Software\\Network_Of_The_Apes", 1)
		NOTASys.WriteString( "LastOpened", (Date$ + "  " + Time$) )
		OpenNOTASys = NOTASys.ReadString("LastOpened")
	End Function


'OpenNOTAUser()
	'Opens HKCU NOTA Registry Key
	'Returns Value "LastOpened"
	'EXAMPLE:
		'WriteTime$ = OpenNOTAUser
		'CloseNOTAUser

	Function OpenNOTAUser
		NOTAUser.OpenKey("Software\\Network_Of_The_Apes", 1)
		NOTAUser.WriteString( "LastOpened", (Date$ + "  " + Time$) )
		OpenNOTAUser = NOTAUser.ReadString("LastOpened")
	End Function


'ProgramName$()
	'Gets the program's name
	'EXAMPLE
		'? ProgramName$

	Function ProgramName$
		dim bpmTheProgram$ as string
		dim bpmProgramLength& as integer
		dim bpmWaldoNumber& as integer
		bpmTheProgram$ = Command$(0)
		bpmProgramLength& = len(bpmTheProgram$)
		for bpmWaldoNumber& = 0 to bpmProgramLength&
			if mid$(bpmTheProgram$, (bpmProgramLength& - bpmWaldoNumber&), 1) = "\\" then
				bpmTheProgram$ = right$( bpmTheProgram$, bpmWaldoNumber&)
				bpmWaldoNumber& = bpmProgramLength&
				else
			end if
		next
		ProgramName$ = bpmTheProgram$
	end function

