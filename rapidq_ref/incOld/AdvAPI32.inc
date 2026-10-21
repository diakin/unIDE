'ADVAPI32.DLL Functions
'FILE ADDED: Release Version 1
'FILE UPDATED: Release Version 1

'Adapted for RapidQ by Bryn Mosher (bdmnky@hotmail.com)
'WIN32API RapidQ $Includes 
'Home page - http://home.pacbell.net/brynm/
'RapidQ - http://www.basicguru.com/abc/rapidq/


'GetUserName()
	'Use the NOTD.inc function GetUserName$ to return a string value :)

	Declare Function GetUserName Lib "advapi32.dll" Alias_
	 "GetUserNameA" (lpBuffer As long, nSize As Long) As Long

