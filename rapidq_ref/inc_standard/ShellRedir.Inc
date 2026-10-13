$IFNDEF __SHELLREDIR_INC   ' IncManager: include guard
$DEFINE __SHELLREDIR_INC

' FileName ShellRedir.Inc
' ============================================================================
' SHELLREDIR    RAPIDQ FUNCTION     February 26, 2005               By Jacques
'
' Redirect the output of a Shell to ...                          Version 0.1.0
'
' Without warranty  :  sounds pretty good yet
' Translated from  VB  code at  :  http://www.visualbasicforum.com/t49495.html
' ============================================================================
'
Type RDR_SECURITY_ATTRIBUTES
   nLength As Long
   lpSecurityDescriptor As Long
   bInheritHandle As Long
End Type
'
Type RDR_PROCESS_INFORMATION
   hProcess As Long
   hThread As Long
   dwProcessId As Long
   dwThreadId As Long
End Type
'
Type RDR_STARTUPINFO
   cb As Long
   lpReserved As Long
   lpDesktop As Long
   lpTitle As Long
   dwX As Long
   dwY As Long
   dwXSize As Long
   dwYSize As Long
   dwXCountChars As Long
   dwYCountChars As Long
   dwFillAttribute As Long
   dwFlags As Long
   wShowWindow As Short
   cbReserved2 As Short
   lpReserved2 As Long
   hStdInput As Long
   hStdOutput As Long
   hStdError As Long
End Type
'
Type RDR_OVERLAPPED
     ternal As Long
     ternalHigh As Long
     offset As Long
     OffsetHigh As Long
     hEvent As Long
End Type
'
Const RDR_STARTF_USESHOWWINDOW = &H1
Const RDR_STARTF_USESTDHANDLES = &H100
Const RDR_SW_HIDE = 0
Const RDR_SW_SHOW = 5
'
Declare Function RDR_CreatePipe Lib "kernel32" Alias "CreatePipe" (phReadPipe As Long, phWritePipe As Long, _
                         lpPipeAttributes As RDR_SECURITY_ATTRIBUTES, ByVal nSize As Long) As Long
Declare Sub RDR_GetStartupInfo Lib "kernel32" Alias "GetStartupInfoA" (lpStartupInfo As RDR_STARTUPINFO)
Declare Function RDR_CreateProcess Lib "kernel32" Alias "CreateProcessA" (lpApplicationName As Long, _
                         lpCommandLine As Long, lpProcessAttributes As RDR_SECURITY_ATTRIBUTES, _
                         lpThreadAttributes As RDR_SECURITY_ATTRIBUTES, ByVal bInheritHandles As Long, _
                         ByVal dwCreationFlags As Long, lpEnvironment As Long, _
                         lpCurrentDriectory As Long, lpStartupInfo As RDR_STARTUPINFO, _
                         lpProcessInformation As RDR_PROCESS_INFORMATION) As Long
Declare Function RDR_SetWindowText Lib "user32" Alias "SetWindowTextA" (ByVal hwnd As Long, _
                         ByVal lpString As String) As Long
Declare Function RDR_ReadFile Lib "kernel32" Alias "ReadFile" (ByVal hFile As Long, lpBuffer As Long, _
                         ByVal nNumberOfBytesToRead As Long, lpNumberOfBytesRead As Long, _
                         lpOverlapped As RDR_OVERLAPPED) As Long
Declare Function RDR_SendMessage Lib "user32" Alias "SendMessageA" (ByVal hwnd As Long,_
                         ByVal wMsg As Long, ByVal wParam As Long, lParam As Long) As Long
Declare Function RDR_CloseHandle Lib "kernel32" Alias "CloseHandle" (ByVal hObject As Long) As Long
'
Const RDR_BUFFER_SIZE = 1024
'
Declare Sub ShellRedirCallBack (Text As String)
DefInt ptrShellRedirCallBack
Bind ptrShellRedirCallBack To ShellRedirCallBack
'
Function ShellRedir (CommandLine As String) As String
     Dim tPipeAttributes As RDR_SECURITY_ATTRIBUTES
     Dim tProcessAttributes As RDR_SECURITY_ATTRIBUTES
     Dim tThreadAttributes As RDR_SECURITY_ATTRIBUTES
     Dim tProcessInformation As RDR_PROCESS_INFORMATION
     Dim tStartupInformation As RDR_STARTUPINFO
     DefInt hPipeRead, hPipeWrite, nbrByteRead, hProcess
     Dim sBit As String * RDR_BUFFER_SIZE
     DefStr sTextOut = ""
     DefStr sCommandLine = CommandLine
     DefStr sNull = ""
     DefStr sConsoleTitle = "RAPIDQ SHELLREDIR CONSOLE"
     tPipeAttributes.nLength = SizeOf(tPipeAttributes)
     tPipeAttributes.lpSecurityDescriptor = 0
     tPipeAttributes.bInheritHandle = -1
     tProcessAttributes.nLength = SizeOf(tProcessAttributes)
     tThreadAttributes.nLength = SizeOf(tThreadAttributes)
     If RDR_CreatePipe(Varptr(hPipeRead), VarPtr(hPipeWrite), tPipeAttributes, 0) <> 0 Then
         RDR_GetStartupInfo tStartupInformation
         tStartupInformation.cb = SizeOf(tStartupInformation)
         tStartupInformation.hStdOutput = hPipeWrite
         tStartupInformation.hStdError = hPipeWrite
         tStartupInformation.dwFlags = RDR_STARTF_USESHOWWINDOW Or RDR_STARTF_USESTDHANDLES
         tStartupInformation.wShowWindow = RDR_SW_HIDE  ' RDR_SW_SHOW
         tStartupInformation.lpTitle = VARPTR(sConsoleTitle)
         hProcess = RDR_CreateProcess(VarPtr(sNull), VarPtr(sCommandLine), tProcessAttributes, _
                             tThreadAttributes, -1, 0, 0, VarPtr(sNull), tStartupInformation, tProcessInformation)
         If hProcess <> 0 Then
             Do
                 If RDR_ReadFile(hPipeRead, VarPtr(sBit), RDR_BUFFER_SIZE, VarPtr(nbrByteRead), 0) <> 0 Then
                     sTextOut = sTextOut & Left$(sBit, nbrByteRead)
                     CallFunc (ptrShellRedirCallBack, Left$(sBit, nbrByteRead))
                     DoEvents
                 Else
                     RDR_CloseHandle tProcessInformation.hThread
                     RDR_CloseHandle tProcessInformation.hProcess
                     Exit Do
                 End If
                 RDR_CloseHandle hPipeWrite
             Loop
             RDR_CloseHandle hPipeWrite
             RDR_CloseHandle hPipeRead
         Else
             RDR_CloseHandle hPipeWrite
             RDR_CloseHandle hPipeRead
             sTextOut = Chr$(10) & Chr$(10) & "   *** CANT CREATE PROCESS   FOR " & Chr$(34) & sCommandLine & Chr$(34) & Chr$(10) & Chr$(10)
             CallFunc (ptrShellRedirCallBack, sTextOut)
         End If
     Else
         sTextOut = Chr$(10) & Chr$(10) & "   *** CANT CREATE PIPE   FOR " & Chr$(34) & sCommandLine & Chr$(34) & Chr$(10) & Chr$(10)
         CallFunc (ptrShellRedirCallBack, sTextOut)
     End If
     Result = sTextOut
End Function
' ==================================================================================
' End ShellRedir.Inc



' ---- DOCUMENTATION ----
' Example :
' -------
' $Include <ShellRedir.Inc> ' On top of your code
'
' ...
'
' Sub ShellRedirCallBack (Text As String) ' MUST be any where in your code after the $Include
' ' You recieve here the output of the shell ' if not
' ' it may be sent in multiple strings
' ' In example rchWin.Text = rchWin.Text & text
' End Sub
'
' ...
'
' ' Shelling : will only return when finished
' DefStr sTmp = ShellRedir (PathFileExt & Commandline) ' sTmp is the output string too
' ShowMessage (sTmp) ' another way to get the Shellredir output string
' ----------------------------------------------------------------------------
' Best Demo
' ---------
' $Include <ShellRedir.inc>
'
' Sub ShellRedirCallBack (Text As String)
' Print Text;
' End Sub
'
' DefStr sTmp = ShellRedir ("ping -n 10 -w 100 www.google.com")
' ShowMessage (sTmp)
' '---- EXIT CONSOLE
' DefStr sExit
' Input " CR to QUIT", sExit
' Application.Terminate
' End

' -----------------------------------------------------------------------------
' IDE RAPIDQ CONSOLE the PatheFile.Bas is received as argument(1) of Command Line
' ------------------
' $Include "Functions\ShellRedir.Inc"
' $Escapechars On
'
' Sub ShellRedirCallBack (Text As String)
' Print Text;
' End Sub
'
' DefStr sLibDir = "-lc:\\Rapid-Q\\Libs"
' DefStr sIncDir = "-ic:\\Rapid-Q\\Includes"
' DefStr sRcExeDir = "c:\\Rapid-Q\\Rc.Exe "
'
' If Command$(1) &lt;&gt; "" Then ' ready for long name path and spaces in path
' DefStr sShell = "\"" & sRcExeDir & "\" \"" & sIncDir & "\" \"" & sLibDir & "\" \"" & Command$(1) & "\""
' ShellReDir (sShell)
' End If
' ' ---- EXIT CONSOLE
' DefStr sExit
' Input " CR to QUIT", sExit
' Application.Terminate
' End
'

' IDE RAPIDQ GUI the PatheFile.Bas is received as argument(1) of Command Line
' --------------
' $INCLUDE <RapidQ.inc>
' $Include <ShellRedir.inc>
' $Escapechars On
' Create frmRQIDE As QForm
' Caption = "RQIDE_GUI"
' Center
' Width = 600
' Height = 400
' Font.Size = 10
' Font.Name = "courier"
' Create rchText As QRichEdit
' align = 5
' End Create
' End Create
' Sub ShellRedirCallBack (Text As String)
' rchText.Text = rchText & Text
' End Sub
' DefStr sLibDir = "-lc:\\Rapid-Q\\Libs"
' DefStr sIncDir = "-ic:\\Rapid-Q\\Includes"
' DefStr sRcExeDir = "c:\\Rapid-Q\\Rc.Exe "
' If Command$(1) <> "" Then ' ready for long name path and spaces in path
' frmRQIDE.Caption = "RQIDE : Compiling \"" & Command$(1) & "\""
' DefStr sShell = "\"" & sRcExeDir & "\" \"" & sIncDir & "\" \"" & sLibDir & "\" \"" & Command$(1) & "\""
' ShellReDir (sShell)
' End If
' frmRQIDE.Visible = False
' frmRQIDE.ShowModal
' Application.Terminate
' End
$ENDIF   ' IncManager: __SHELLREDIR_INC
