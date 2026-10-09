'This loads the other Windows API includes
'FILE ADDED: Release Version 1
'FILE UPDATED: Release Version 3

'Adapted for RapidQ by Bryn Mosher (bdmnky@hotmail.com)
'WIN32API RapidQ $Includes
'Home page - http://home.pacbell.net/brynm/
'RapidQ - http://www.basicguru.com/abc/rapidq/

'NOTE:
'This file should only contain "$include"s and constant values.
'See EOF for usage.

'AdvAPI32.dll Functions
$include "AdvAPI32.inc"

'GDI32.dll Functions
$include "GDI32.inc"

'Kernel32.DLL Functions
$include "Kernel32.inc"

'Shell32.dll Functions
$include "Shell32.inc"

'User32.DLL Functions
$include "User32.inc"

'WinMM.dll Functions
$Include "WinMM.Inc"

' >>>>> RESERVED WORDS AND VALUES <<<<<<
'NOTE: These are only MS created constants. NO USER VALUES!
'      ALL are READ ONLY!  I know these don't have names
'      and deviate from my standard format.  Sorry.
'      The following Functions have their constants with them:
'			GetSystemMetrics
'		Here are the miscellany constants
		Const COMPLEXREGION = 3
		Const ERROR = 0
		Const MCI_PUT = &H842
		Const MCI_WAIT = &H2&
		Const NULLREGION = 1
		Const RGN_AND = 1
		Const RGN_COPY = 5
		Const RGN_DIFF = 4
		Const RGN_ERROR = 0
		Const RGN_MAX = 5
		Const RGN_MIN = 1
		Const RGN_OR = 2
		Const RGN_XOR = 3
		Const SIMPLEREGION = 2

' >>> END RESERVED WORDS AND VALUES <<<


'Usage:
'Use the following line at the begining of your
'program code to load all of the WIN32 API includes:

'	$Include "WindowsAPI.inc"

'Each include file noted with *DLL above represents a
'.DLL in your system directory.  If you only want 
'access to one of those at a time, just include it's 
'file.  For Example:

'	$Include "Kernel32.inc"  'Only encompases kernel32.dll functions

'If you don't know what a function does, search for 
'the name of the function at msdn.microsoft.com or 
'your favorite Windows API website.  The 
'documentation for each function is not part of the 
'includes.

'This is a project in progress, so don't expect 
'everything to work.  Some entries are there, but have
'yet to be adapted to RapidQ's VarPtr() methods to get 
'good return values.

'NOTE: The file NOTA.Inc is my home network include.  
'It has my own functions and some handy wrappers to 
'API calls.  If you include NOTA.inc, include 
'WindowsAPI.inc first to avoid missing function 
'errors. For example:

'	$Include "RapidQ.Inc"
'	$Include "WindowsAPI.inc"
'	$Include "NOTA.inc"
