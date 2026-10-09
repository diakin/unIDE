'
' ============================================================================
' QDIR   RAPIDQ EXTENDED COMPONENT       April 2004        By Jacques Philippe
'
'    SEARCH FOR MATCHING FILES IN DIRECTORY AND SUBDIRECTORIES
'    FILTERS ON EXTENSION, MUST_ATTRIBUTES and REJECTED_ATTRIBUTES 
'
' COMPONENT CODE                                                 Version 1.0.4
' ============================================================================
'
' $TYPECHECK ON
'
' -------------------------------------------------------------
' CONSTANTES DEFINITIONS
' ----------------------
Const QDIR_RQCR = Chr$(10)      ' avoid using $ESCAPECHARS ON IN COMPONENT
Const QDIR_BACKSLASH = Chr$(92)
'
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

Type QDIR_WIN32_FIND_DATA                            '   WIN32 NAMES
    attributes As Long                          '   dwFileAttributes As Long
                                                '   ftCreationTime As FILETIME
                                                '   ftLastAccessTime As FILETIME
                                                '   ftLastWriteTime As FILETIME
                                                '   RAPIDQ BUGS WITH NESTED TYPES so REPLACED BY ! No Differences
    creationLowDateTime As Long                 '   ftCreationTime.dwLowDateTime As Long
    creationHighDateTime As Long                '   ftCreationTime.dwHighDateTime As Long
    lastAccessLowDateTime As Long               '   ftLastAccessTime.dwLowDateTime As Long
    lastAccessHighDateTime As Long              '   ftLastAccessTime.dwHighDateTime As Long
    lastWriteLowDateTime As Long                '   ftLastWriteTime.dwLowDateTime As Long
    lastWriteHighDateTime As Long               '   ftLastWriteTime.dwHighDateTime As Long
    fileSizeHigh As Long                        '   nFileSizeHigh As Long
    fileSizeLow As Long                         '   nFileSizeLow As Long
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
' API DECLARATIONS
' ----------------
'
Declare Function QDIR_FindFirstFile Lib "kernel32" Alias "FindFirstFileA" (ByRef lpFileName As String, _
          ByRef lpFindFileData As QDIR_WIN32_FIND_DATA) As Long
Declare Function QDIR_FindClose Lib "kernel32" Alias "FindClose" (ByVal hFindFile As Long) As Long
Declare Function QDIR_FindNextFile Lib "kernel32" Alias "FindNextFileA" (ByVal hFindFile As Long, _
       lpFindFileData As QDIR_WIN32_FIND_DATA) As Long
Declare Function QDIR_FileTimeToLocalFileTime Lib "kernel32" Alias "FileTimeToLocalFileTime" _
             (lpFileTime As QDIR_FILETIME, lpLocalFileTime As QDIR_FILETIME) As Long
Declare Function QDIR_FileTimeToSystemTime Lib "kernel32" Alias "FileTimeToSystemTime" _
             (lpFileTime As QDIR_FILETIME, lpSystemTime As QDIR_SYSTEMTIME) As Long

' ------------------------------------------------------------------------------------
' API, CONSTANTES & TYPES DECLARATIONS FOR ChangeFileDateTime And ChangeFileAttributes
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
' Template required for creating an Event ... HTML DOC CHAPTER 10-9
'
Declare Sub OnFileFound_EventTemplate '(Sender As QDir)
'
' -------------------------------------------------------------
' QOBJECT CREATION
' ----------------
'
Type QDir Extends QObject
    PUBLIC:
        ' Event - Truely Read Write
        OnFileFound As EVENT (OnFileFound_EventTemplate)  ' RW
        ' Find Files PРґrameters - Should Be Read Only
        fileName As string
        dosFileName As string
        path As String
        pathFileName As string
        size As Double
        WithDotsDirs As Long
        ' File Times - Should Be Read Only
        dateTime As Double    ' ???
        time As String
        timems As String
        date As String
        dateEU As String
        dateAlpha As String
        dateAlphaEU As string
        strDayOfWeek As string
        strMonthOfYear As String
        ' Attibutes - Should Be Read Only
        attributes As Long
        attributesAsString As String
        ' Text Month, WeekDay - Truely Read Write
        days(0 To 6) As String     ' RW
        months(1 To 12) As String  ' RW
        ' Date and Time Variable - Should Be Read Only
        creation As QDIR_SYSTEMTIME
        lastAccess As QDIR_SYSTEMTIME
        lastWrite As QDIR_SYSTEMTIME
        flagStop As Long
        flagShowFormStopDir As Long
        frmDirStop As QForm
        lblDirStop As QLabel
    PRIVATE:
        hSearch As Long   ' will be used to get file recursively with GetNextFile
        applicationPath As String   ' "As String" Added on 21oct2002, was missing
        filter As String        ' Ex *.Bas
        busy As Long
        fileStruct As QDIR_WIN32_FIND_DATA
        ' Attributes Parameters
        rejectedAttributes As String
        mustAttributes As String
        ' Date Time Variables
        fileTime As QDIR_FILETIME
        fileLocalTime As QDIR_FILETIME
        lstDir As QStringList
'
        Sub OnClic_frmDirStop
             QDir.flagStop = 1
        End Sub
'
    CONSTRUCTOR
        flagShowFormStopDir = 1
        flagStop = 0
        applicationPath = Command$(0) - Application.exeName
        OnFileFound = 0
        busy = 0
        WithDotsDirs = 1
        rejectedAttributes = ""
        mustAttributes = ""
        days(0) = "Sunday"     '"Dim"   ' May Be Changed days(0 To 6) is Public
        days(1) = "Monday"     '"Lun"
        days(2) = "Tuesday"    '"Mar"
        days(3) = "Wednesday"  '"Mer"
        days(4) = "Thursday"   '"Jeu"
        days(5) = "Friday"     '"Ven"
        days(6) = "Saturday"   '"Sam"
        months(1) = "January"           ' May be Changed  months(1 To 12) is Public
        months(2) = "February"
        months(3) = "March"
        months(4) = "April"
        months(5) = "May"
        months(6) = "June"
        months(7) = "July"
        months(8) = "August"
        months(9) = "September"
        months(10) = "October"
        months(11) = "November"
        months(12) = "December"
        frmDirStop.top = 40  
        frmDirStop.Left = 40  
        frmDirStop.Width = 400
        frmDirStop.Height = 200
        frmDirStop.Color = 0
        frmDirStop.Visible = 0
        frmDirStop.BorderStyle = 0 ' 0 bsNone, 1-4 bsSingle
'
        lblDirStop.Align = 5
        lblDirStop.Autosize = 0
        lblDirStop.Alignment = 2   ' taCenter
        lblDirStop.LabelStyle = 1  ' IsRaised
        lblDirStop.Layout = 2      ' tlCenter
        lblDirStop.Parent = QDir.frmDirStop
        lblDirStop.OnClick = QDir.OnClic_frmDirStop
        lblDirStop.Font.Color = &H60FF60
        lblDirStop.Font.Size = 16
        lblDirStop.Font.Bold = True
        lblDirStop.Caption = Chr$(10) & "CLIC  ME  TO  ABORT" & Chr$(10) & CHr$(10) & "  DIRECTORY  SCANNING" 
    END CONSTRUCTOR

' -------- PRIVATE TOOL FUNCTION---------------------------------------------

' *****************
    With QDir '*******  to the bottom of the file
' *****************

PRIVATE:
' ---------------------------------------------------------------------------
        Function CheckAttributes As Long        ' return 1 if file is Accepted
            If .rejectedAttributes <> "" Then
                        ' NO ATTRIBUTE SET                             "0"
               If (Instr(.rejectedAttributes, "0") and .fileStruct.attributes = 0) Then _
                                Result = 0:Exit Function ' False
                        ' Const QDIR_QDIR_FILE_ATTRIBUTE_ARCHIVE = &H20        ' "A"
               If (Instr(.rejectedAttributes, "A") and (.fileStruct.attributes And QDIR_FILE_ATTRIBUTE_ARCHIVE) > 0) Then _
                                Result = 0:Exit Function ' False
                        ' Const QDIR_FILE_ATTRIBUTE_DIRECTORY = &H10      ' "D"
               If (Instr(.rejectedAttributes, "D") and (.fileStruct.attributes And QDIR_FILE_ATTRIBUTE_DIRECTORY) > 0) Then _
                                Result = 0:Exit Function ' False
                        ' Const QDIR_FILE_ATTRIBUTE_HIDDEN = &H2          ' "H"
               If (Instr(.rejectedAttributes, "H") and (.fileStruct.attributes And QDIR_FILE_ATTRIBUTE_HIDDEN) > 0) Then _
                                Result = 0:Exit Function ' False
                        ' Const QDIR_FILE_ATTRIBUTE_NORMAL = &H80         ' "N"
               If (Instr(.rejectedAttributes, "N") and (.fileStruct.attributes And QDIR_FILE_ATTRIBUTE_NORMAL) > 0) Then _
                                Result = 0:Exit Function ' False
                        ' Const QDIR_FILE_ATTRIBUTE_READONLY = &H1        ' "R"
               If (Instr(.rejectedAttributes, "R") and (.fileStruct.attributes And QDIR_FILE_ATTRIBUTE_READONLY) > 0) Then _
                                Result = 0:Exit Function ' False
                        ' Const QDIR_FILE_ATTRIBUTE_SYSTEM = &H4          ' "S"
               If (Instr(.rejectedAttributes, "S") and (.fileStruct.attributes And QDIR_FILE_ATTRIBUTE_SYSTEM) > 0) Then _
                                Result = 0:Exit Function ' False
                        ' Const QDIR_FILE_ATTRIBUTE_TEMPORARY = &H100     ' "T"
               If (Instr(.rejectedAttributes, "T") and (.fileStruct.attributes And QDIR_FILE_ATTRIBUTE_TEMPORARY) > 0) Then _
                                Result = 0:Exit Function ' False
                        ' Const QDIR_FILE_ATTRIBUTE_COMPRESSED = &H800    ' "C"
               If (Instr(.rejectedAttributes, "C") and (.fileStruct.attributes And QDIR_FILE_ATTRIBUTE_COMPRESSED) > 0) Then _
                                Result = 0:Exit Function ' False
            End If
'
'            IF (Len(.mustAttributes) And (.fileStruct.attributes And QDIR_FILE_ATTRIBUTE_DIRECTORY) = 0)Then ' No Must Attributes For Directories
            IF .mustAttributes <> "" Then
                If (Instr(.mustAttributes, "0") And .fileStruct.attributes <> 0) Then _
                                Result = 0:Exit Function
                If (Instr(.mustAttributes, "A") And (.fileStruct.attributes And QDIR_FILE_ATTRIBUTE_ARCHIVE) = 0) Then _
                                Result = 0:Exit Function
                If (Instr(.mustAttributes, "D") And (.fileStruct.attributes And QDIR_FILE_ATTRIBUTE_DIRECTORY) = 0) Then _
                                Result = 0:Exit Function
                If (Instr(.mustAttributes, "H") And (.fileStruct.attributes And  QDIR_FILE_ATTRIBUTE_HIDDEN) = 0) Then _
                                Result = 0:Exit Function
                If (Instr(.mustAttributes, "N") And (.fileStruct.attributes And QDIR_FILE_ATTRIBUTE_NORMAL) = 0) Then _
                                Result = 0:Exit Function
                If (Instr(.mustAttributes, "R") And (.fileStruct.attributes And QDIR_FILE_ATTRIBUTE_READONLY) = 0) Then _
                                Result = 0:Exit Function
                If (Instr(.mustAttributes, "S") And (.fileStruct.attributes And QDIR_FILE_ATTRIBUTE_SYSTEM) = 0) Then _
                                Result = 0:Exit Function
                If (Instr(.mustAttributes, "T") And (.fileStruct.attributes And QDIR_FILE_ATTRIBUTE_TEMPORARY) = 0) Then _
                                Result = 0:Exit Function
                If (Instr(.mustAttributes, "C") And (.fileStruct.attributes And QDIR_FILE_ATTRIBUTE_COMPRESSED) = 0) Then _
                                Result = 0:Exit Function
            End If
            Result = 1 ' true  File Accepted
        End Function
' ---------------------------------------------------------------------------
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
' ---------------------------------------------------------------------------
        ' Extract The FileName From the FileStructure
        ' -------------------------------------------
        Function ExtractFilename As String
            DefInt iPtr
            iPtr = Instr (.fileStruct.cFilename, Chr$(0))
            Result = Left$(.fileStruct.cFilename, iPtr - 1)
        End Function

        ' Extract the DOS FileName From the FileStructure
        ' -----------------------------------------------
        Function ExtractDosFilename As String
            DefInt iPtr
            iPtr = Instr (.fileStruct.cAlternate, Chr$(0))
            Result = Left$(.fileStruct.cAlternate, iPtr - 1)
        End Function
' ---------------------------------------------------------------------------
        ' Format Elements of Date and Time
        ' --------------------------------
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
' ---------------------------------------------------------------------------
        ' Build Date And Time
        ' -------------------
        Sub ConvertTimeToStrings (iSystemTime As QDIR_SYSTEMTIME)
            iSystemTime.dateEU = .ElementDateTimeFormat(iSystemTime.Day) & "/" _
                              & .ElementDateTimeFormat(iSystemTime.Month) & "/" _
                                      & .YearFormat(iSystemTime.Year)               ' dd/mm/yyyy
            iSystemTime.date = .ElementDateTimeFormat(iSystemTime.Month) & "/" _
                             & .ElementDateTimeFormat(iSystemTime.Day) & "/" _
                             & .YearFormat(iSystemTime.Year)                         ' mm/dd/yyyy
            iSystemTime.timems = .ElementDateTimeFormat(iSystemTime.Hour) & ":" _
                             & .ElementDateTimeFormat(iSystemTime.Minute) & ":" _
                             & .ElementDateTimeFormat(iSystemTime.Second)  & "." _
                             & .MsFormat(iSystemTime.Milliseconds)
            iSystemTime.Time = Left$(iSystemTime.timems, 8)
            iSystemTime.nWeekDay = Str$(iSystemTime.DayOfWeek)
            iSystemTime.strDayOfWeek = Left$(.days(iSystemTime.DayOfWeek), 3)
            iSystemTime.strMonthOfYear = Left$(.months(iSystemTime.Month), 3)
            iSystemTime.dateAlphaEU = iSystemTime.strDayOfWeek & " " _
                             & .ElementDateTimeFormat(iSystemTime.Day) & " "  _
                             & iSystemTime.strMonthOfYear & " " _
                             & .YearFormat(iSystemTime.Year)
            iSystemTime.dateAlpha = iSystemTime.strDayOfWeek & " " _
                             & iSystemTime.strMonthOfYear & " "_
                             & .ElementDateTimeFormat(iSystemTime.Day) & ", "  _
                             & .YearFormat(iSystemTime.Year)
        End sub
' ---------------------------------------------------------------------------
        ' Get Times, Size, Names, Attributes of File
        ' ------------------------------------------
        Sub GetFileDatas
            DefStr sTmp
            .fileName = .ExtractFileName
            .dosFileName = .ExtractDosFileName
            .pathFileName = .path & .fileName
            ' file size
            .size = .RQdwXdw(.fileStruct.fileSizeHigh, .fileStruct.fileSizeLow)
            ' GET AND COMPUTE VARIOUS FILE TIMES
            ' ----------------------------------
            ' FILE CREATION TIME
            ' ------------------
            .creation.DateTime = .RQdwXdw(.fileStruct.creationHighDateTime, _
                                                    .fileStruct.creationLowDateTime)
            ' Copy Time LONGS in a QDIR_FILETIME  Type
            .fileTime.lowDateTime = .fileStruct.creationLowDateTime
            .fileTime.highDateTime = .fileStruct.creationHighDateTime

            QDIR_FileTimeToLocalFileTime(.fileTime, .fileLocalTime)
            QDIR_FileTimeToSystemTime(.fileLocalTime, .creation)

            .ConvertTimeToStrings (QDir.creation)

            ' FILE LAST ACCESS TIME
            ' ---------------------
            .lastAccess.DateTime = .RQdwXdw(.fileStruct.lastAccessHighDateTime, _
                                                .fileStruct.lastAccessLowDateTime)
            ' Copy Time LONGS in a QDIR_FILETIME  Type
            .fileTime.lowDateTime = .fileStruct.lastAccessLowDateTime
            .fileTime.highDateTime = .fileStruct.lastAccessHighDateTime

            QDIR_FileTimeToLocalFileTime(.fileTime, .fileLocalTime)
            QDIR_FileTimeToSystemTime(.fileLocalTime, .lastAccess)

            .ConvertTimeToStrings (QDir.lastAccess)

            ' FILE LAST WRITE TIME
            ' --------------------
            .lastWrite.DateTime = .RQdwXdw(.fileStruct.lastWriteHighDateTime, _
                                                .fileStruct.lastWriteLowDateTime)
            ' Copy Time LONGS in a QDIR_FILETIME  Type
            .fileTime.lowDateTime = .fileStruct.lastWriteLowDateTime
            .fileTime.highDateTime = .fileStruct.lastWriteHighDateTime

            QDIR_FileTimeToLocalFileTime(.fileTime, .fileLocalTime)
            QDIR_FileTimeToSystemTime(.fileLocalTime, .lastWrite)

            .ConvertTimeToStrings (QDir.lastWrite)

            ' Set Component FILE TIME propreties for to last write time
            ' ----------------------------------------------------------
            .dateTime = .lastWrite.DateTime
            .date = .lastWrite.date
            .dateEU = .lastWrite.dateEU
            .dateAlpha = .lastWrite.dateAlpha
            .dateAlphaEU = .lastWrite.dateAlphaEU
            .time = .lastWrite.time
            .timems = .lastWrite.timems
            .strDayOfWeek = .lastWrite.strDayOfWeek
            .strMonthOfYear = .lastWrite.strMonthOfYear

            ' file attributes
            ' ---------------
            .attributes = .fileStruct.Attributes
            'Const QDIR_FILE_ATTRIBUTE_ARCHIVE = &H20        ' "A"
            'Const QDIR_FILE_ATTRIBUTE_DIRECTORY = &H10      ' "D"
            'Const QDIR_FILE_ATTRIBUTE_HIDDEN = &H2          ' "H"
            'Const QDIR_FILE_ATTRIBUTE_NORMAL = &H80         ' "N"
            'Const QDIR_FILE_ATTRIBUTE_READONLY = &H1        ' "R"
            'Const QDIR_FILE_ATTRIBUTE_SYSTEM = &H4          ' "S"
            'Const QDIR_FILE_ATTRIBUTE_TEMPORARY = &H100     ' "T"
            'Const QDIR_FILE_ATTRIBUTE_COMPRESSED = &H800    ' "C"
            '  NO ATTRIBUTE SET                         ' "0"
            sTmp = ""
            If .attributes and QDIR_FILE_ATTRIBUTE_ARCHIVE    Then sTmp = sTmp & "A"
            If .attributes and QDIR_FILE_ATTRIBUTE_DIRECTORY  Then sTmp = sTmp & "D"
            If .attributes and QDIR_FILE_ATTRIBUTE_HIDDEN     Then sTmp = sTmp & "H"
            If .attributes and QDIR_FILE_ATTRIBUTE_NORMAL     Then sTmp = sTmp & "N"
            If .attributes and QDIR_FILE_ATTRIBUTE_READONLY   Then sTmp = sTmp & "R"
            If .attributes and QDIR_FILE_ATTRIBUTE_SYSTEM     Then sTmp = sTmp & "S"
            If .attributes and QDIR_FILE_ATTRIBUTE_TEMPORARY  Then sTmp = sTmp & "T"
            If .attributes and QDIR_FILE_ATTRIBUTE_COMPRESSED Then sTmp = sTmp & "C"
            If sTmp = "" Then sTmp = "0"
            .attributesAsString = sTmp
        End Sub
' ---------------------------------------------------------------------------
' -------- PUBLIC METHODS ---------------------------------------------------
' ---------------------------------------------------------------------------
     PUBLIC:
        '
        ' DIR   SIMPLE DIR
        ' ----------------
        Sub Dir (sPathFilter As String, sRejectedAttributes As String, sMustAttributes As string)
            DefStr aPathFilter, pathFilter
            DefInt iPtr, hTmp, iFileFound
            If .busy = 0 Then
                .busy = 1
                .flagStop = 0
                If .flagShowFormStopDir <> 0 Then .frmDirStop.Show
                .rejectedAttributes = Ucase$(sRejectedAttributes)   ' "ADHNRSTC0"
                .mustAttributes = Ucase$(sMustAttributes)
                ' format the pathfilter
                pathFilter = sPathFilter
                ' allow "/" as directory separator in the pathFilter
                pathFilter = ReplaceSubstr$(pathFilter, "/", Chr$(92))
                ' delete a "\" ahead of pathFilter (= error)
                If Left$(pathFilter, 1) = QDIR_BACKSLASH Then pathFilter = Mid$(pathFilter, 2)
                ' Extract or Compose the path
                iPtr = RInstr(pathFilter, QDIR_BACKSLASH)
                .path = Left$(pathFilter, iPtr)
                .filter = Mid$(pathFilter, iptr + 1)
                If Instr(pathFilter, ":") = 0 Then .path = .applicationPath & .path
                ' Scans the files
                hTmp = QDIR_FindFirstFile (pathFilter, .fileStruct)
                If hTmp <> -1 Then   ' pathfilter does not exist
                    iFileFound = hTmp
                    While iFileFound <> 0
                        If .CheckAttributes <> 0 Then
                            .GetFileDatas
                            If .WithDotsDirs = 1 Then
                                CallFunc .OnFileFound
                            Else
                                If (.fileName <> "." and .fileName <> "..") Then CallFunc .OnFileFound
                            End If
                        End If
                        iFileFound = QDIR_FindNextFile (hTmp, .fileStruct)
                        If .flagStop <> 0 Then Exit While
                        DoEvents
                    Wend
                'Else
                '    ShowMessage ("QDIR ERROR : DIRECTORY DOES NOT EXIST\nOR INVALID FILTER")
                End If
                .frmDirStop.Visible = 0
                QDIR_FindClose (hTmp)
                .busy = 0
            Else
                ShowMessage ("QDIR ERROR : QDIR ALREADY SEARCHING,\nPROGRAMMER SHOULD HAVE CREATE ANOTHER QDIR")
            End If
        End sub
'
' ---------------------------------------------------------------------------
        '
        ' DIR /S  Recursive DIR
        ' ---------------------
        Sub Dirs (sPathFilter As String, sRejectedAttributes As String, sMustAttributes As String)
            DefStr aPathFilter, pathFilter
            DefInt iPtr, hTmp, iFileFound, iLstDirIndex, N
            If .busy = 0 Then
                .busy = 1
                .flagStop = 0
                If .flagShowFormStopDir <> 0 Then .frmDirStop.Show
                .rejectedAttributes = Ucase$(sRejectedAttributes)   ' "ADHNRSTC0"
                .mustAttributes = Ucase$(sMustAttributes)
                ' format the pathfilter
                pathFilter = sPathFilter
                ' allow "/" as directory separator in the pathFilter
                pathFilter = ReplaceSubstr$(pathFilter, "/", Chr$(92))
                ' delete a "\" ahead of pathFilter (= error)
                If Left$(pathFilter, 1) = QDIR_BACKSLASH Then pathFilter = Mid$(pathFilter, 2)
                ' Extract or Compose the path
                iPtr = RInstr(pathFilter, QDIR_BACKSLASH)
                .path = Left$(pathFilter, iPtr)
                .filter = Mid$(pathFilter, iptr + 1)
                If Instr(pathFilter, ":") = 0 Then .path = .applicationPath & .path
                ' Scans Directories
                .lstDir.Additems (.path)
                iLstDirIndex = 0
                While .lstDir.ItemCount > iLstDirIndex
                    .path = .lstDir.Item(iLstDirIndex)
                    pathFilter = .path & "*.*"
                    ' Scan Sub Directories To Store them in LstDir
                    ' ---------------------------------------------
                    hTmp = QDIR_FindFirstFile (pathFilter, .fileStruct)
                    If hTmp <> -1 Then   ' pathfilter does not exist
                        iFileFound = hTmp
                        N = 1
                        While iFileFound <> 0                   
                            If (.fileStruct.attributes And QDIR_FILE_ATTRIBUTE_DIRECTORY) <> 0 Then
                                iPtr = Instr (.fileStruct.cFilename, Chr$(0))
                                .fileName = Left$(.fileStruct.cFilename, iPtr - 1)
                                Select Case .fileName
                                    Case "."
                                        ' Do Nothing
                                    Case ".."
                                        ' Do Nothing
                                    Case Else
                                        .lstDir.InsertItem (iLstDirIndex + N, .path & .filename & QDIR_BACKSLASH)
'                                        ShowMessage (.lstDir.Item(iLstDirIndex + N))    
                                        Inc (N)
                                End Select
                            End If
                            iFileFound = QDIR_FindNextFile (hTmp, .fileStruct)
                            If .flagStop <> 0 Then Exit While
                            DoEvents
                        Wend                    
                    End If
                    QDIR_FindClose (hTmp)
                    ' Scans Files in Directory
                    ' ------------------------
                    pathFilter = .path & .filter
                    hTmp = QDIR_FindFirstFile (pathFilter, .fileStruct)
                    If (hTmp <> -1 And .flagStop = 0 ) Then   ' pathfilter does not exist
                        iFileFound = hTmp
                        While iFileFound <> 0
                            If .CheckAttributes <> 0 Then
                                .GetFileDatas
                                If .WithDotsDirs = 1 Then
                                    CallFunc .OnFileFound
                                Else
                                    If (.fileName <> "." and .fileName <> "..") Then CallFunc .OnFileFound
                                End If
                            End If
                            iFileFound = QDIR_FindNextFile (hTmp, .fileStruct)
                            DoEvents
                        Wend
                    'Else
                    '    ShowMessage ("QDIR ERROR : DIRECTORY DOES NOT EXIST\nOR INVALID FILTER")
                    End If
                    QDIR_FindClose (hTmp)
                    If .flagStop <> 0 Then Exit While
                    Inc(iLstDirIndex)
                    DoEvents
                Wend
                .frmDirStop.Visible = 0
                .lstDir.Clear
                .busy = 0
            Else
                ShowMessage ("QDIR ERROR : QDIR ALREADY SEARCHING,\nPROGRAMMER SHOULD HAVE CREATE ANOTHER QDIR")
            End If
        End Sub
' ---------------------------------------------------------------------------
'
        ' CHANGE FILE DATES and TIMES
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
            If iHandle = QDIR_INVALID_HANDLE_VALUE Then cftErr = "File Not Found":Goto cftError ' inc2026: QDIR_INVALID_HANDLE_VALUE вместо 0: CreateFile при ошибке возвращает INVALID_HANDLE_VALUE = -1, а не 0 (константа объявлена в строке 20 и не использовалась), иначе ненайденный файл не обнаруживался
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
            Exit Functioni
cftError:
            Result = 0 ' False
            If iHandle Then QDIR_CloseHandle iHandle
            ShowMessage ("While Changing File Date and/or Time : " & QDIR_RQCR & "    " & cftErr)
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
        End Function
'
' ----------------------------------------------------------------------------
'
' *****************
    End With  ' *******
' *****************
End Type
'
' $TYPECHECK OFF
'
' =============================================================================
'
