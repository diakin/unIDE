
Public Const FILE_SHARE_READ = &H1
Public Const FILE_SHARE_WRITE = &H2
'Public Const FILE_ATTRIBUTE_READONLY = &H1
'Public Const FILE_ATTRIBUTE_HIDDEN = &H2
'Public Const FILE_ATTRIBUTE_SYSTEM = &H4
'Public Const FILE_ATTRIBUTE_DIRECTORY = &H10
'Public Const FILE_ATTRIBUTE_ARCHIVE = &H20
'Public Const FILE_ATTRIBUTE_NORMAL = &H80
'Public Const FILE_ATTRIBUTE_TEMPORARY = &H100
'Public Const FILE_ATTRIBUTE_COMPRESSED = &H800

Const QDIR_MAXWORD = &HFFFF
Const QDIR_INVALID_HANDLE_VALUE = -1
Const QDIR_FILE_ATTRIBUTE_ARCHIVE = &H20        ' "A"
Const QDIR_FILE_ATTRIBUTE_DIRECTORY = &H10      ' "D"
Const QDIR_FILE_ATTRIBUTE_HIDDEN = &H2          ' "H"
Const QDIR_FILE_ATTRIBUTE_NORMAL = &H80         ' "N"
Const QDIR_FILE_ATTRIBUTE_READONLY = &H1        ' "R"
Const QDIR_FILE_ATTRIBUTE_SYSTEM = &H4          ' "S"
Const QDIR_FILE_ATTRIBUTE_TEMPORARY = &H100     ' "T"
Const QDIR_FILE_ATTRIBUTE_COMPRESSED = &H800    ' "C"
'    NO ATTRIBUTE SET                      ' "0"  ' zero

' TYPE DEFINITIONS
' ----------------
Type QDIR_FILETIME
    lowDateTime As Long
    highDateTime As Long
End Type

Type QDIR_WIN32_FIND_DATA                '   WIN32 NAMES
    attributes As Long              '   dwFileAttributes As Long
                                    '   ftCreationTime As FILETIME
                                    '   ftLastAccessTime As FILETIME
                                    '   ftLastWriteTime As FILETIME
                                    '   RAPIDQ BUGS WITH NESTED TYPES so REPLACED BY ! No Differences
    creationLowDateTime As Long     '   ftCreationTime.dwLowDateTime As Long
    creationHighDateTime As Long    '   ftCreationTime.dwHighDateTime As Long
    lastAccessLowDateTime As Long   '   ftLastAccessTime.dwLowDateTime As Long
    lastAccessHighDateTime As Long  '   ftLastAccessTime.dwHighDateTime As Long
    lastWriteLowDateTime As Long    '   ftLastWriteTime.dwLowDateTime As Long
    lastWriteHighDateTime As Long   '   ftLastWriteTime.dwHighDateTime As Long
    fileSizeHigh As Long            '   nFileSizeHigh As Long
    fileSizeLow As Long             '   nFileSizeLow As Long
    dwReserved0 As Long
    dwReserved1 As Long
    cFileName As String * 260
    cAlternate As String * 14
End Type

Type QDIR_SYSTEMTIME
    year As Short  ' VB integer = RQ Short
    month As Short
    dayOfWeek As Short
    day As Short
    hour As Short
    minute As Short
    second As Short
    milliseconds As Short
    ' Extended
    DateTime As Double            ' The DateTime As A Number
    date As String * 10           ' Date as a String  mm/dd/yyyy
    dateEU As String * 10         ' EU date Foramt dd/mm/yyyy
    dateAlpha As String * 16      ' "ddd" "mmm" DD, yyyy
    dateAlphaEU As String * 15    ' "ddd" DD "mmm" yyyy
    time As String * 8            ' without ms  HH:MM:SS
    timems As String * 12         ' Time As a String  HH:MM:SS.iii
    strDayOfWeek As String * 3    ' day of the week as in Day(0 To 6) : "Mon", "Tue", "Wed", ... "Sun"
    nWeekDay As String * 1        ' "0", "1", "2", ... "6"
    strMonthOfYear As String * 3  ' day of the week as in Months(1 To 12) : "Jan", "Feb", ... "Dec"
End Type

' -------------------------------------------------------------
' ------------------------------------------------------------------------------------
' API, constANTES & TYPES DECLARATIONS FOR ChangeFileDateTime And ChangeFileAttributes
' ------------------------------------------------------------------------------------
'
' cft for Change_File_Time and to prevent double declaration of type ...
'
Type T_FILETIMEcft
    dwLowDateTime As Long
    dwHighDateTime As Long
End Type
'
Type T_SYSTEMTIMEcft
    wYear As Short  ' VB INTEGER ARE RQ SHORT
    wMonth As Short
    wDayOfWeek As Short
    wDay As Short
    wHour As Short
    wMinute As Short
    wSecond As Short
    wMilliseconds As Short
End Type
'
Const QDIR_GENERIC_WRITE = &H40000000
Const QDIR_OPEN_EXISTING = 3
Const QDIR_FILE_SHARE_READ = &H1
Const QDIR_FILE_SHARE_WRITE = &H2
'
Declare Function QDIR_SetFileTime Lib "kernel32" Alias "SetFileTime" (ByVal hFile As Long, _
                    lpCreationTime As T_FILETIMEcft, lpLastAccessTime As T_FILETIMEcft, _
                    lpLastWriteTime As T_FILETIMEcft) As Long

Declare Function QDIR_SystemTimeToFileTime Lib "kernel32" Alias "SystemTimeToFileTime" _
                    (lpSystemTime As T_SYSTEMTIMEcft, lpFileTime As T_FILETIMEcft) As Long

Declare Function QDIR_CreateFile Lib "kernel32" Alias "CreateFileA" (ByRef lpFileName As String, _
                    ByVal dwDesiredAccess As Long, ByVal dwShareMode As Long, _
                    ByVal lpSecurityAttributes As Long, ByVal dwCreationDisposition As Long, _
                    ByVal dwFlagsAndAttributes As Long, ByVal hTemplateFile As Long) As Long
Declare Function QDIR_CloseHandle Lib "kernel32" Alias "CloseHandle" (ByVal hObject As Long) As Long
Declare Function QDIR_SetFileAttributes Lib "kernel32" Alias "SetFileAttributesA" _
                    (ByRef lpFileName As String, ByVal dwFileAttributes As Long) As Long'
'
' -------------------------------------------------------------
declare    Functioni ChangeFileDateAndTime ( ... ) As Long

'Declare Function SetFileAttributes Lib "kernel32" Alias "SetFileAttributesA" (ByVal lpFileName As String, ByVal dwFileAttributes As Long) As Long

Dim sysdir$ as String, strSave as string

Declare Function GetWindowsDirectory Lib "kernel32" Alias "GetWindowsDirectoryA" (ByVal lpBuffer As String, ByVal nSize As Long) As Long
 strSave = String$(200, Chr$(0))

sysdir$ = Left$(strSave, GetWindowsDirectory(strSave, Len(strSave))) 
'--------------------------------

'-- ***********************************************************************'
'
        '= CHANGE FILE DATES and TIMES
        ' -------------------------
        Functioni ChangeFileDateAndTime ( ... ) As Long
            DefInt iHandle, N
            DefInt dateTime(1 To 6) = {1985, 8, 23, 22, 10, 12} ' YYYY, MM, DD, hh, mm, ss (08/23/1985 22:10:12)
            DefStr pathFileName, whichTimes, cftErr
            Dim bufferFileTime As T_FILETIMEcft
            Dim systemTime as T_SYSTEMTIMEcft
            ' Get String Parameters of the Functioni
            ' ---------------------------------
            cftErr = ""
            If ParamStrCount > 0 Then
                pathFileName = ParamStr$(1)
            Else
                cftErr = "No FileName Provided"
            End If    
            If cftErr <> "" Then Goto cftError
            If ParamStrCount > 1 Then whichTimes = ParamStr$(2)  ' Optional
            ' Open The File
            ' -------------
            iHandle = QDIR_CreateFile(pathFileName, QDIR_GENERIC_WRITE, (QDIR_FILE_SHARE_READ Or QDIR_FILE_SHARE_WRITE), _
                                0, QDIR_OPEN_EXISTING, 0, 0)
            If iHandle = 0 Then cftErr = "File Not Found":Goto cftError
            '
            ' Get Numeric Parameters of the Functioni
            ' ---------------------------------------
            cftErr = ""
            For N = 1 To 6
               If ParamValCount > N - 1 Then
                    dateTime(N) = ParamVal(N)
                Else
                    cftErr = Str$(N - 1) & " Numeric Param(s) Recieved, 6 Awaited"
                    Exit For
                End If
            Next N
            If cftErr <> "" Then Goto cftError
            '

            systemTime.wYear = dateTime(1)
            systemTime.wMonth = dateTime(2)
            'systemTime.wDayOfWeek = 0
            systemTime.wDay = dateTime(3)
            systemTime.wHour = dateTime(4)
            systemTime.wMinute = dateTime(5)
            systemTime.wSecond = dateTime(6)
            systemTime.wMilliseconds = 333       
            '

            ' set The New File Time On Disk
            ' -----------------------------
            QDIR_SystemTimeToFileTime (systemTime, bufferFileTime)
            If Instr(Ucase$(whichTimes), "CRE") Then
                If QDIR_SetFileTime (iHandle, bufferFileTime, 0, 0) <> 1 Then cftErr = "Problem in Writing CreationTime"
            End If    
            If cftErr <> "" Then Goto cftError
            '
            If Instr(Ucase$(whichTimes), "ACC") Then
                If QDIR_SetFileTime (iHandle, 0, bufferFileTime, 0) <> 1 Then cftErr = "Problem in Writing lastAccessTime"
            End If
            If cftErr <> "" Then Goto cftError
            '
            If (Instr(Ucase$(whichTimes), "WRI") or whichTimes = "") Then
                If QDIR_SetFileTime (iHandle, 0, 0, bufferFileTime) <> 1 Then cftErr = "Problem in Writing lastWriteTime"
            End If
            If cftErr <> "" Then Goto cftError
            '
            If iHandle Then QDIR_CloseHandle iHandle
            Result = 1 ' True
''            print " File Date and/or Time  changed: " & pathFileName & "    " & cftErr

            Exit Functioni
cftError:
            Result = 0 ' False
            If iHandle Then QDIR_CloseHandle iHandle
            'ShowMessage ("While Changing File Date and/or Time : " & QDIR_RQCR & "    " & cftErr)
''            print "While Changing File Date and/or Time : " & pathFileName & "    " & cftErr
        End Functioni
'
' ----------------------------------------------------------------------------
'
        ' CHANGE FILE ATTRIBUTES
        ' ----------------------
        Function ChangeFileAttributes (sPathFileName As string, attributesAsString As String) As Long
            DefInt iAttributes
            DefStr pathFileName
            pathFileName = sPathFileName   
            print "ChangeFileAttributes pathFileName=" ,pathFileName
            iAttributes = 0
            attributesAsString = UCASE$(AttributesAsString)
            If Instr(attributesAsString, "A") Then iAttributes = iAttributes + QDIR_FILE_ATTRIBUTE_ARCHIVE
            If Instr(attributesAsString, "D") Then iAttributes = iAttributes + QDIR_FILE_ATTRIBUTE_DIRECTORY
            If Instr(attributesAsString, "H") Then iAttributes = iAttributes + QDIR_FILE_ATTRIBUTE_HIDDEN
            If Instr(attributesAsString, "N") Then iAttributes = iAttributes + QDIR_FILE_ATTRIBUTE_NORMAL
            If Instr(attributesAsString, "R") Then iAttributes = iAttributes + QDIR_FILE_ATTRIBUTE_READONLY
            If Instr(attributesAsString, "S") Then iAttributes = iAttributes + QDIR_FILE_ATTRIBUTE_SYSTEM
            If Instr(attributesAsString, "T") Then iAttributes = iAttributes + QDIR_FILE_ATTRIBUTE_TEMPORARY
            If Instr(attributesAsString, "C") Then iAttributes = iAttributes + QDIR_FILE_ATTRIBUTE_COMPRESSED
            Result = QDIR_SetFileAttributes (pathFileName, iAttributes) 
            print "Result SetFileAttributes  "+pathFileName +"=" ,Result

        End Function
'
' ----------------------------------------------------------------------------


'ChangeFileAttributes ("c:/tmp/" , "HA" ) ' change dirECTORY attrib to hidden, archiev
'ChangeFileAttributes ("c:/tmp/123" , "HA" ) ' change dirECTORY attrib to hidden, archiev

''                                    y   m  d   h   min sec
'ChangeFileDateAndTime("c:/tmp/123", 1980, 1, 11, 11, 11, 11,  "ACCESS Write CREATION") ' working'

'ChangeFileDateAndTime("c:/tmp*", 1980, 1, 11, 11, 11, 11,  "ACCESS Write CREATION")   ' not working'
  