
' --------------------------------------------------------------------
' QFtpClient OBJECT       January 2001             By Jacques Philippe
'
' ---------------------- EXTENDS QOBJECT -----------------------------
'
$ESCAPECHARS ON
$TYPECHECK ON
'
' ------------------ CONSTANTS & TYPES -------------------------------
'
Const QFTP_TRANSFER_TYPE_UNKNOWN = &H0
Const QFTP_TRANSFER_TYPE_ASCII = &H1
Const QFTP_TRANSFER_TYPE_BINARY = &H2

Const QFTP_INTERNET_DEFAULT_FTP_PORT = 21                       ' default for FTP servers
Const QFTP_INTERNET_SERVICE_FTP = 1
Const QFTP_INTERNET_FLAG_PASSIVE = &H8000000                    ' used for FTP connections
Const QFTP_INTERNET_OPEN_TYPE_PRECONFIG = 0                     ' use registry configuration
Const QFTP_INTERNET_OPEN_TYPE_DIRECT = 1                        ' direct to net
Const QFTP_INTERNET_OPEN_TYPE_PROXY = 3                         ' via named proxy
Const QFTP_INTERNET_OPEN_TYPE_PRECONFIG_WITH_NO_AUTOPROXY = 4   ' prevent using java/script/INS

Const QFTP_MAX_PATH = 260
Const QFTP_FILE_ATTRIBUTE_ARCHIVE = &H20        ' "A"
Const QFTP_FILE_ATTRIBUTE_DIRECTORY = &H10      ' "D"
Const QFTP_FILE_ATTRIBUTE_HIDDEN = &H2          ' "H"
Const QFTP_FILE_ATTRIBUTE_NORMAL = &H80         ' "N"
Const QFTP_FILE_ATTRIBUTE_READONLY = &H1        ' "R"
Const QFTP_FILE_ATTRIBUTE_SYSTEM = &H4          ' "S"
Const QFTP_FILE_ATTRIBUTE_TEMPORARY = &H100     ' "T"
Const QFTP_FILE_ATTRIBUTE_COMPRESSED = &H800    ' "C"

' --------------------------

Type QFTP_FILETIME
    LowDateTime As Long
    HighDateTime As Long
End Type

Type QFTP_WIN32_FIND_DATA
    FileAttributes As Long
'    ftCreationTime As FILETIME
'    ftLastAccessTime As FILETIME
'    ftLastWriteTime As FILETIME
'   RAPIDQ BUGS WITH NESTED TYPES, so REPLACED BY The 6 Following lines
    CreationTimeLow As Long
    CreationTimeHigh As Long
    LastAccessTimeLow As Long
    LastAccessTimeHigh As Long
    LastWriteTimeLow As Long
    LastWriteTimeHigh As Long
    nFileSizeHigh As Long
    nFileSizeLow As Long
    dwReserved0 As Long
    dwReserved1 As Long
    cFileName As String * QFTP_MAX_PATH
    cAlternate As String * 14
End Type

Type QFTP_SYSTEMTIME
    year As Short  ' VB integer = RQ Short
    month As Short
    dayOfWeek As Short
    day As Short
    hour As Short
    minute As Short
    second As Short
    milliseconds As Short
    ' extended (fossiles) 
    dateEU As String * 10          ' Date as a String  dd-mm-yyyy  
    dateUS As String * 10          ' Date as a String  mm-dd-yyyy       
    timems As String * 12          ' Time As a String  HH:MM:SS.iii
    time   As String * 8           ' HH:MM:SS
End Type

' ------------------ APIs --------------------------------------------

Declare Function QFTP_InternetCloseHandle Lib "wininet.dll" Alias "InternetCloseHandle" (ByVal hInet As Long) As Integer
' -------------------
Declare Function QFTP_InternetConnect Lib "wininet.dll" Alias "InternetConnectA" (ByVal hInternetSession As Long, _
        ByRef sServerName As String, ByVal nServerPort As Integer, ByRef sUserName As String, _
        ByRef sPassword As String, ByVal lService As Long, ByVal lFlags As Long, _
        ByVal lContext As Long) As Long
' -------------------
Declare Function QFTP_InternetOpen Lib "wininet.dll" Alias "InternetOpenA" (ByRef sAgent As String, _
        ByVal lAccessType As Long, ByRef sProxyName As String, ByRef sProxyBypass As String, _
        ByVal lFlags As Long) As Long
' -------------------
Declare Function QFtpSetCurrentDirectory Lib "wininet.dll" Alias "FtpSetCurrentDirectoryA" _
        (ByVal hFtpSession As Long, ByRef lpszDirectory As String) As Long
' -------------------
Declare Function QFtpGetCurrentDirectory Lib "wininet.dll" Alias "FtpGetCurrentDirectoryA" _
        (ByVal hFtpSession As Long, ByRef lpszCurrentDirectory As String, _
        ByRef lpdwCurrentDirectory As Long) As Long
' -------------------
Declare Function QFtpCreateDirectory Lib "wininet.dll" Alias "FtpCreateDirectoryA" _
       (ByVal hFtpSession As Long, ByRef lpszDirectory As String) As Long
' -------------------
Declare Function QFtpRemoveDirectory Lib "wininet.dll" Alias "FtpRemoveDirectoryA" _
        (ByVal hFtpSession As Long, ByRef lpszDirectory As String) As Long
' -------------------
Declare Function QFtpDeleteFile Lib "wininet.dll" Alias "FtpDeleteFileA" (ByVal hFtpSession As Long, _
        ByRef lpszFileName As String) As Long
' -------------------
Declare Function QFtpRenameFile Lib "wininet.dll" Alias "FtpRenameFileA" (ByVal hFtpSession As Long, _
        ByRef lpszExisting As String, ByRef lpszNew As String) As Long
' -------------------
Declare Function QFtpGetFile Lib "wininet.dll" Alias "FtpGetFileA" (ByVal hConnect As Long, _
        ByRef lpszRemoteFile As String, ByRef lpszNewFile As String, ByVal fFailIfExists As Long, _
        ByVal dwFlagsAndAttributes As Long, ByVal dwFlags As Long, ByRef dwContext As Long) As Long
' -------------------
Declare Function QFtpPutFile Lib "wininet.dll" Alias "FtpPutFileA" (ByVal hConnect As Long, _
        ByRef lpszLocalFile As String, ByRef lpszNewRemoteFile As String, ByVal dwFlags As Long, _
        ByVal dwContext As Long) As Long
' -------------------
Declare Function QFTP_InternetGetLastResponseInfo Lib "wininet.dll" Alias "InternetGetLastResponseInfoA" _
        (ByRef lpdwError As Long, ByRef lpszBuffer As String, ByRef lpdwBufferLength As Long) As Long
' -------------------
Declare Function QFtpFindFirstFile Lib "wininet.dll" Alias "FtpFindFirstFileA" _
        (ByVal hFtpSession As Long, ByRef lpszSearchFile As String, lpFindFileData As Long, _
        ByVal dwFlags As Long, ByVal dwContent As Long) As Long
' -------------------
Declare Function QFTP_InternetFindNextFile Lib "wininet.dll" Alias "InternetFindNextFileA" _
        (ByVal hFind As Long, lpvFindData As QFTP_WIN32_FIND_DATA) As Long
' -------------------
Declare Function QFTP_GetLastError Lib "kernel32" Alias "GetLastError" () As Long
' -------------------
Const QFTP_PassiveConnection As Long = 1 ' True
' -------------------
' -- FILE TIME APIs -
Declare Function QFTP_FileTimeToLocalFileTime Lib "kernel32" Alias "FileTimeToLocalFileTime" _
             (lpFileTime As QFTP_FILETIME, lpLocalFileTime As QFTP_FILETIME) As Long
' -------------------
Declare Function QFTP_FileTimeToSystemTime Lib "kernel32" Alias "FileTimeToSystemTime" _
             (lpFileTime As QFTP_FILETIME, lpSystemTime As QFTP_SYSTEMTIME) As Long

' ++++++++++++++++++++++++++++++++++++++
Type QFtpClient Extends QObject   ' +++++++++++++++++++++++++++++++++++
' ++++++++++++++++++++++++++++++++++++++
' ---------------------------------------------------------------------
' PROPRETIES
' ----------
    PUBLIC:
        ' All
        ftpHandle As Long Property Set setFtpHandle ' Read Only
        errorMsg As String Property Set setErrorMsg ' Read Only
        ' Open
        Agent As String
        OpenType As Long
        ProxyName As String
        ProxyByPass As String
        Open_dwFlags As Long
        ' Connect
        FtpPort As Long
        InternetService As Long
        InternetFlag As Long    ' a function of Internet Service
        Connect_dwContext As Long
        ' Put
        FtpTransferType As Long
        Put_dwContext As Long
        ' Get
        FlagsAndAttributes As Long
        Get_dwContext As Long
        ' FindFirstFile
        findfirst_dwFlags As Long
        findFirst_dwContext As Long
        WIN32_FIND_DATA As QFTP_WIN32_FIND_DATA
        hFind As Long  ' allows recursive search 
        ' Find Files
        fileName As string
        dosFileName As string
        fileSize As Double
        fileTime As String
        fileTimems As String
        fileDate As String
        fileDateEU As String
        fileDateTime As Double
        fileAttributes As Long
        fileAttributesAsString As String
    PRIVATE:
        hOpen As Long
        tfileTime As QFTP_FILETIME
        fileLocalTime As QFTP_FILETIME
        lastWriteTime As QFTP_SYSTEMTIME
' ---------------------------------------------------------------------
' CONSTRUCTOR
' -----------
    Constructor ' initialises propreties
        ' Important Ones
        Agent = "FTP Object for RAPIDQ"
        ' Open
        OpenType = QFTP_INTERNET_OPEN_TYPE_PRECONFIG
        ProxyName = ""
        ProxyByPass = ""
        Open_dwFlags = 0
        ' Connect
        FtpPort = QFTP_INTERNET_DEFAULT_FTP_PORT
        InternetService = QFTP_INTERNET_SERVICE_FTP
        Connect_dwContext = 0
        ' Put
        FtpTransferType = QFTP_TRANSFER_TYPE_UNKNOWN
        Put_dwContext = 0
        ' Get
        FlagsAndAttributes = 0 'For more information on QFTP_FILE_ATTRIBUTE_* attributes, see CreateFile in the Platform SDK.
        Get_dwContext = 0
        ' FindFirst
        findFirst_dwFlags = 0
        findFirst_dwContext = 0
    End Constructor
' ---------------------------------------------------------------------
' METHODS
' -------

' ****************
With QFtpClient   ' On To The End
' ****************
' ---------------------------------------------------------------------
PRIVATE:
    ' TOOLS FUNCTIONS
    ' -----------------
        ' Convert a Dw To A Double
        ' ------------------------ 
        Function  DwToDbl (iDw As Long) As Double
            DefDbl dwTmp, dbl2exp31
            dwTmp = iDw
            dbl2exp31 = 2147483648   ' 2^31
            If dwTmp < 0 Then        ' Bit 31, Integer bit sign is set
                dwTmp = dwTmp SHL 1  ' get rid of bit 31
                dwTmp = dwTmp SHR 1  
                Result = dbl2exp31  +  dwTmp  ' add the value of bit 31
            Else
                Result = dwTmp
            End If
        End Function

        ' multiplie a dw x dw in a Double   dw x dw = dbl
        ' -----------------------------------------------
        Function RQdwXdw (dwHigh As Long, dwLow As Long) As Double
            DefDbl dbl2exp32
            dbl2exp32 = 4294967296   ' 2^32
            Result = .dwToDbl(dwLow) + (dbl2exp32 * .dwToDbl(dwHigh))
        End Function


        Function ElementDateTimeFormat (data As SHort) As String  ' "1/1/2001  1:1:1.1" > "01/01/2001 01:01:01.1" 
            If data < 10 Then  Result = "0" & Str$(data):Exit Function
            Result = Str$(Data)
        End Function

        Function MsFormat (data As Short) As String
            If data < 10 Then Result = "00" & Str$(Data):Exit Function
            If data < 100 Then Result = "0" & Str$(Data):Exit Function
            Result = Str$(data)
        End Function

            Function YearFormat (data As Short) As String
            If data < 10 Then Result = "000" & Str$(Data):Exit Function
            If data < 100 Then Result = "00" & Str$(Data):Exit Function
            If data < 1000 Then Result = "0" & Str$(Data):Exit Function
            Result = Str$(data)
        End Function
    
        ' iSystemTime  allows to convert Other File Times
        Sub ConvertTimeToStrings (iSystemTime As QFTP_SYSTEMTIME)
            iSystemTime.dateEU = .ElementDateTimeFormat(iSystemTime.Day) & "/" _  
                       & .ElementDateTimeFormat(iSystemTime.Month) & "/" _
                       & .YearFormat(iSystemTime.Year)                         ' dd/mm/yyyy
           .fileDateEU = iSystemTime.dateEU
            iSystemTime.dateUS = .ElementDateTimeFormat(iSystemTime.Month) & "/" _
                       & .ElementDateTimeFormat(iSystemTime.Day) & "/" _
                       & .YearFormat(iSystemTime.Year)                         ' mm/dd/yyyy
            .fileDate = iSystemTime.dateUS
            iSystemTime.timeMs = .ElementDateTimeFormat(iSystemTime.Hour) & ":" _
                       & .ElementDateTimeFormat(iSystemTime.Minute) & ":" _
                       & .ElementDateTimeFormat(iSystemTime.Second)  & "." _
                       & .MsFormat(iSystemTime.Milliseconds)                   ' HH:MM:SS.mmm
            .fileTimems = iSystemTime.timeMs
            iSystemTime.time =  Left$(iSystemTime.timeMs, 8)                   ' HH:MM:SS
            .fileTime = iSystemTime.time
        End Sub
' ---------------------------------------------------------------------
PRIVATE:
    ' ftpHandle is Read Only
    ' ----------------------
    Property Set setFtpHandle(value as Long)
    End Property

    ' errorMsg is Read Only
    ' ---------------------
    Property Set setErrorMsg(value as String)
    End Property
  ' Note : the compiler detects any write Attempt. If Public, it is compiled
  '        but at runtime an assignment of the variable has no effect so READ ONLY
' ---------------------------------------------------------------------
PUBLIC:
'   READMESSAGE
'   ----------_
    Function ReadMessage As string
        DefInt iTmp, lenBuf, iErr, iPtr
        DefStr sErr
        sErr = String$(4096, Chr$(0))
        lenBuf = 4095
        iTmp = QFTP_InternetGetLastResponseInfo (iErr, sErr, lenBuf)
        If iTmp Then
            iPtr = Instr (sErr, Chr$(0))
            Result = Left$(sErr, iPtr - 1)
        Else
            Result = ""
        End If
    End Function
' ---------------------------------------------------------------------
'   OPEN & CONNECT
'   --------------
    Function Connect (sRemoteServer as String, sLogin as String, sPassword As String) As Long
        DefStr remoteServer, login, password
        remoteServer= sRemoteServer
        login = sLogin
        passWord = sPassword
        .hOpen = QFTP_InternetOpen(.Agent, .OpenType, .ProxyName, .ProxyByPass, .Open_dwFlags)
        If .hOpen = 0 Then
            .ErrorMsg = "*** Error Cannot Open FTP : \n" & .ReadMessage
            .ftpHandle = 0
            Result = 0
            Exit Function
        End If
    
        If .InternetService = QFTP_INTERNET_SERVICE_FTP Then 
            .InternetFlag = QFTP_INTERNET_FLAG_PASSIVE
        Else
            .InternetFlag = 0
        End If
        .ftpHandle = QFTP_InternetConnect(.hOpen, remoteServer, .FtpPort, login, passWord, _
                    .InternetService, .InternetFlag, .Connect_dwContext)
        If .ftpHandle = 0 Then
            .ErrorMsg = "*** Error Cannot Connect Server : \n" & .ReadMessage
        Else
            .ErrorMsg = "*** OK Connected"
        End If
        Result = .ftpHandle
    End Function
' ---------------------------------------------------------------------
'   CLOSE FTP SESSION
'   -----------------
    Function Close as Long
            .ErrorMsg = "*** OK Closed "
            ' close the FTP connection
            If .ftpHandle Then
                 .ftpHandle = QFTP_InternetCloseHandle (.ftpHandle)
            Else
                 .ErrorMsg = "*** Cannot Close FTP : \n" & .ReadMessage
            End If
            ' close the internet connection   
            If .hOpen Then
                .hopen = QFTP_InternetCloseHandle (.hOpen)
            Else
                .ErrorMsg = .ErrorMsg & "   \nCannot Close hOpen : \n" & .ReadMessage
            End If
            ' Close Find Session 
            If .hFind Then .hFind = QFTP_InternetCloseHandle (.hFind)            

            Result = .ftpHandle * .hOpen ' ???? must equal 1 ????
            .ErrorMsg = .ErrorMsg & " (Total = " & Str$(Result) & ")" 
    End Function
' ---------------------------------------------------------------------
'    GET CURRENT DIRECTORY
'    ---------------------
    Function GetDir As String
        DefStr bufferDirPath
        DefInt bufferDirLen, iTmp
        BufferDirPath = STring$ (QFTP_MAX_PATH, Chr$(0))
        BufferDirLen = Len(BufferDirPath)
        iTmp = QFtpGetCurrentDirectory (.ftpHandle, bufferDirPath, bufferDirLen)
        If iTmp = 0 Then
            .ErrorMsg = "*** Error Getting Current Directory : \n" & .ReadMessage
            Result = ""
        Else
            .ErrorMsg = "*** OK Directory Retrieved"
            Result = Left$(bufferDirPath, Instr(bufferDirPath, Chr$(0)) - 1)
        End If
    End Function
' ---------------------------------------------------------------------
'    MAKE DIRECTORY
'    --------------
    Function MakeDir (sNewDirectory As String) As Long
        DefStr newDirectory
        newDirectory = sNewDirectory
        Result = QFtpCreateDirectory (.ftpHandle, newDirectory)
        If  Result = 0 Then
                .ErrorMsg = "*** Error Creating Current Directory : \n" & .ReadMessage
        Else
           .ErrorMsg = "*** OK Directory Created"
        End If
    End Function
' ---------------------------------------------------------------------
'   SET CURRENT DIRECTORY
'   ---------------------
    Function SetDir (sNewDirectory As String) As Long
        DefStr newDirectory
        newDirectory = sNewDirectory
        Result = QFtpSetCurrentDirectory (.ftpHandle, newDirectory)
        If  Result = 0 Then
            .ErrorMsg = "*** Error Setting Current Directory : \n" & .ReadMessage
        Else
            .ErrorMsg = "*** OK Directory Set"
        End If
    End Function
' ---------------------------------------------------------------------
'   REMOVE DIRECTORY
'   ----------------
    Function RemoveDir (sDelDirectory As String) As Long
        DefStr delDirectory
        delDirectory = sDelDirectory
        Result = QFtpRemoveDirectory (.ftpHandle, delDirectory)
        If  Result = 0 Then
            .ErrorMsg = "*** Error Removing Directory : \n" & .ReadMessage
        Else
            .ErrorMsg = "*** OK Directory Removed"
        End If
    End Function
' ---------------------------------------------------------------------
'   UPLOAD A FILE File
'   ------------------
    Function PutFile (sLocalFileName As String, sRemoteFileName As String) As Long
        DefStr localFileName, remoteFileName
        localFileName = sLocalFileName
        remoteFileName = sRemoteFileName     
        If remoteFileName = "" Then remoteFileName = localFileName
        Result = QFtpPutFile (.ftpHandle, localFileName, remoteFileName, _
                                    .FtpTransferType, .Put_dwContext)
        If Result = 0 Then
            .ErrorMsg = "*** Error Uploading File : \n" & .ReadMessage
        Else
            .ErrorMsg = "*** OK File Uploaded"
        End If
    End Function
' ---------------------------------------------------------------------
'   DOWNLOAD A FILE
'   ---------------
    Function GetFile (sRemoteFileName As String, sLocalFileName As String, _
                     iflagOverwrite As Long) As Long
        DefStr localFileName, remoteFileName
        DefInt flagOverWrite, i
        localFileName = sLocalFileName
        remoteFileName = sRemoteFileName             
        If iflagOverwrite Then
            flagOverWrite = 0
        Else
            flagOverWrite = 1
        End If
        Result = QFtpGetFile (.ftpHandle, remoteFileName, localFileName, _
                 flagOverWrite, .FlagsAndAttributes, .FtpTransferType, .Get_dwContext)
 ' always returns ZERO ????
 '       ShowMessage ("IncResult=" & Str$(Result))
	If Result = 0 Then
            .ErrorMsg = "*** Error Downloading File : \n" & .ReadMessage
	Else
            .ErrorMsg = "*** OK File Downloaded"
	End If
    End Function
' ---------------------------------------------------------------------
'   RENAME/MOVE a FILE (no overwrite)
'   ------------------
    Function Rename (sOldName as String, sNewName as String) as Long
            DefStr oldName, newName
            oldName = sOldName
            newName = sNewName
            Result = QFtpRenameFile (.ftpHandle, oldName, newName)
            If Result = 0 Then
                .ErrorMsg = "*** Error Renaming File : \n" & .ReadMessage
            Else
                .ErrorMsg = "*** OK File Renamed"
            End If
    End Function
' ---------------------------------------------------------------------
'   DELETE a FILE (dont work)
'   -------------
    Function Delete (sRemoteFileName As String) As Long
            DefStr remoteFileName
            remoteFileName = sRemoteFileName
            Result = QFtpDeleteFile (.ftpHandle, remoteFileName)
            If Result = 0 Then
                .ErrorMsg = "*** Error Deleting File : \n" & .ReadMessage
            Else
                .ErrorMsg = "*** OK File Deleted"
            End If
    End Function
' ---------------------------------------------------------------------
PRIVATE:
'   GET FILE INFO      get the last Find File Size, time, Timems, Date,
'   -------------                    DateEU, AttributeStr, Attributes
    Sub GetFileInfos
        DefStr sTmp
        .FileName = Left$(.WIN32_FIND_DATA.cFileName, _
                                    Instr(.WIN32_FIND_DATA.cFileName, Chr$(0)) - 1)
        .dosFileName = Left$(.WIN32_FIND_DATA.cAlternate, _
                                    Instr(.WIN32_FIND_DATA.cAlternate, Chr$(0)) - 1)
        .fileSize = .rqdwxdw (.WIN32_FIND_DATA.nFileSizeHigh, .WIN32_FIND_DATA.nFileSizeLow)

        ' Copy Time LONGS in a QFTP_FILETIME  Type
        .tfileTime.lowDateTime = .WIN32_FIND_DATA.lastWritetimeLow
        .tfileTime.highDateTime = .WIN32_FIND_DATA.lastWriteTimeHigh

        QFTP_FileTimeToLocalFileTime(.tfileTime, .fileLocalTime) ' API
        QFTP_FileTimeToSystemTime(.fileLocalTime, .lastWriteTime) ' API

        .ConvertTimeToStrings (QFtpClient.lastWriteTime) ' Time, TimeMs, Date, DateEU

        .fileDateTime = .rqdwXdw(.WIN32_FIND_DATA.lastWritetimeHigh, _
                                                 .WIN32_FIND_DATA.lastWriteTimeLow)
        .fileAttributes = .WIN32_FIND_DATA.FileAttributes
        
        'Const QFTP_FILE_ATTRIBUTE_ARCHIVE = &H20        ' "A"
        'Const QFTP_FILE_ATTRIBUTE_DIRECTORY = &H10      ' "D"
        'Const QFTP_FILE_ATTRIBUTE_HIDDEN = &H2          ' "H"
        'Const QFTP_FILE_ATTRIBUTE_NORMAL = &H80         ' "N"
        'Const QFTP_FILE_ATTRIBUTE_READONLY = &H1        ' "R"
        'Const QFTP_FILE_ATTRIBUTE_SYSTEM = &H4          ' "S"
        'Const QFTP_FILE_ATTRIBUTE_TEMPORARY = &H100     ' "T"
        'Const QFTP_FILE_ATTRIBUTE_COMPRESSED = &H800    ' "C"
        sTmp = ""
        If .fileAttributes and QFTP_FILE_ATTRIBUTE_ARCHIVE    Then sTmp = sTmp & "A"
        If .fileAttributes and QFTP_FILE_ATTRIBUTE_DIRECTORY  Then sTmp = sTmp & "D"
        If .fileAttributes and QFTP_FILE_ATTRIBUTE_HIDDEN     Then sTmp = sTmp & "H"
        If .fileAttributes and QFTP_FILE_ATTRIBUTE_NORMAL     Then sTmp = sTmp & "N"
        If .fileAttributes and QFTP_FILE_ATTRIBUTE_READONLY   Then sTmp = sTmp & "R"
        If .fileAttributes and QFTP_FILE_ATTRIBUTE_SYSTEM     Then sTmp = sTmp & "S"
        If .fileAttributes and QFTP_FILE_ATTRIBUTE_TEMPORARY  Then sTmp = sTmp & "T"
        If .fileAttributes and QFTP_FILE_ATTRIBUTE_COMPRESSED Then sTmp = sTmp & "C"
        .fileAttributesAsString = sTmp
    End Sub
' ---------------------------------------------------------------------
PUBLIC:
'   FIND FIRST FILE
'   ---------------
    Function FindFirstFile (sfilter As String) As String
            DefStr filter
            filter = sFilter
            .WIN32_FIND_DATA.cFileName = String$(QFTP_MAX_PATH, Chr$(0))
            .WIN32_FIND_DATA.cAlternate = String$(14, Chr$(0))
            .hFind = QFtpFindFirstFile (.ftpHandle, filter, .WIN32_FIND_DATA, _
                         .findFirst_dwFlags, .findFirst_dwContext)
            If .hFind = 0 Then
                .ErrorMsg = "*** No Matching File : \n" & .ReadMessage
                Result = "" 
            Else
                QFtpClient.ErrorMsg = "*** OK First File Found"
                .GetFileInfos
                Result = .fileName
            End If
    End Function
' ---------------------------------------------------------------------
'   FIND NEXT FILE
'   --------------
    Function FindNextFile As String
            DefInt iTmp
            .WIN32_FIND_DATA.cFileName = String$(QFTP_MAX_PATH, Chr$(0))
            .WIN32_FIND_DATA.cAlternate = String$(14, Chr$(0))
            iTmp = QFTP_InternetFindNextFile (.hFind, .WIN32_FIND_DATA)
            If iTmp = 0 Then
                .ErrorMsg = "*** No More Matching File : \n" & .ReadMessage
                Result = ""
                QFTP_InternetCloseHandle .hFind
            Else
                QFtpClient.ErrorMsg = "*** OK Next File Found"
                .GetFileInfos
                Result = .fileName
            End If
    End Function

' *********
End With   ' Start at METHODS
' *********

' ++++++++++++
End Type   '+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
' ++++++++++++
$ESCAPECHARS OFF
$TYPECHECK OFF

' ------------------ END EXTEND QOBJECT -------------------------------
