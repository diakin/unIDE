'
' ============================================================================
' QDIR   EXTENDED  COMPONENT        March 2004             By Jacques Philippe
'
' CONSOLE TEST PROGRAM                                                 V 1.0.0
' ============================================================================
' Code Common To All Examples
' ---------------------------
'
$INCLUDE "QDir.Inc"
'
Declare Sub ShowFileParamsShortList
Declare Sub ShowFileParamsLongList
Declare Sub ChangeAttributes
'
$ESCAPECHARS ON
$TYPECHECK ON
$INCLUDE "RAPIDQ.INC"
'
'
'$DEFINE EXAMPLE_1             ' UnComment the example to RUN
'$DEFINE EXAMPLE_2             
'$DEFINE EXAMPLE_3
$DEFINE EXAMPLE_4             ' List Only Directories Without "." and ".."
'
' SHORT DOC  valid for ALL 4 Examples
' ---------
'
' path   : relative to the Application Directory and absolute path are accepted
'          directory separator maybe "\" or "/"
' filter : accept Wild Cards like "dir/*.ba?" ... 
'
' rejectedAttribites and mustAttributes maybe any of these letters in ANY
' order "ADHNRSTC0"
'
'
Dim myFile As QFileStream
Dim myDir As QDir
DefInt iCount
'
' ---------------------------------------------------------------------------------
$IFDEF EXAMPLE_1
$UNDEF EXAMPLE_2
$UNDEF EXAMPLE_3
$UNDEF EXAMPLE_4
' ---------------------------------------------------------------------------------
'
'    'EXAMPLE 1      SIMPLE DIR with Event myDir.OnFileFound 
'    '---------
    myFile.Open ("dirOut.txt", fmCreate)
        myDir.OnFileFound = ShowFileParamsLongList
        myDir.Dir ("C:/Rapid-Q/*", "D", "A")
        ' all files with archive attribute set in this directory
        ' Directories not listed
        ' Attributes : "ADHNRSTC0"
    myFile.Close
    Print "path    = ";myDir.path
    Print "EXAMPLE 1          FINISHED"
'
' ---------------------------------------------------------------------------------
$ENDIF
' ---------------------------------------------------------------------------------
$IFDEF EXAMPLE_2
$UNDEF EXAMPLE_3
$UNDEF EXAMPLE_4
' ---------------------------------------------------------------------------------
'
    ' EXAMPLE 2     RECURSIVE DIR SEARCH with Event  myDir.OnFileFound
    ' ---------
    iCount = 0
    myFile.Open ("dirOut.txt", fmCreate)
        myDir.OnFileFound = ShowFileParamsShortList
        myDir.Dirs ("c:\\Windows\\*.txt", "D", "")
        ' all files with extention ".txt" in directory Windows and sub directories
        ' Directories not listed
        ' Attributes : "ADHNRSTC0"
    myFile.Close
    Print "path    = ";myDir.path
    Print "EXAMPLE 2          FINISHED"
'
' ---------------------------------------------------------------------------------
$ENDIF
' ---------------------------------------------------------------------------------
$IFDEF EXAMPLE_3
$UNDEF EXAMPLE_4
' ---------------------------------------------------------------------------------
'   xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
'   !!!!!!!! WARNING : This will change Selected Files dates !!!!!!!!!
'   xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
'   To test this, create a directory c:/tmp/  and copy any file in it
    myFile.Open ("dirOut.txt", fmCreate)
        myDir.OnFileFound = ChangeAttributes
        myDir.Dir ("c:/tmp/*", "D", "")
        myDir.OnFileFound = ShowFileParamsLongList
        myDir.Dir ("c:/tmp/*", "D", "")        
    myFile.Close
    Print "path    = ";myDir.path
    Print "EXAMPLE 3          FINISHED"
'
' ---------------------------------------------------------------------------------
$ENDIF
' ---------------------------------------------------------------------------------
$IFDEF EXAMPLE_4
' ---------------------------------------------------------------------------------
'
    ' EXAMPLE 4    List Only the Directories Of Windows without "." and ".."
    ' ---------
    iCount = 0
    myFile.Open ("dirOut.txt", fmCreate)
        myDir.OnFileFound = ShowFileParamsShortList
        myDir.WithDotsDirs = False      ' "." and ".." are not returned (only for version 0.0.4)
'        myDir.Dirs ("c:\\Windows\\*", "", "D")
        myDir.Dirs ("c:\\Music\\*.mp3", "D", "")   
        ' all files with extention ".txt" in directory Windowsand sub directories
        ' Directories not listed
        ' Attributes : "ADHNRSTC0"
    myFile.Close
    Print "path    = ";myDir.path
    Print "EXAMPLE 2          FINISHED"
'
' ---------------------------------------------------------------------------------
$ENDIF
' ---------------------------------------------------------------------------------
Goto EXITCONSOLE
' ---------------------------------------------------------------------------------
'
' Redate files to Sat  Jan 01/02/1982 01:02:03
' and set the archive, readonly and compressed attributes
Sub ChangeAttributes
        myDir.ChangeFileDateAndTime (myDir.pathFilename, 1982, 1, 2, 1, 2, 3, "cre acc wri")
        myDir.ChangeFileAttributes (myDir.pathFileName, "ARC")
End Sub
'
' Print Routines
' -------------
Sub ShowFileParamsShortList
    DefStr sLine
    sLine = Space$(9)
    With myDir
        sLine = Replace$ (sLine, .AttributesAsString, 1)
        sLine = sLine &  .pathFileName & "  " & StrF$(.Size,ffFixed, 18, 0)
        Print sline
        myFile.WriteLine (sLine)
    End With
End Sub
'
Sub ShowFileParamsLongList
    DefStr sLine
    With myDir
        sLine = ""
        sLine =         "\n          FileName = " & .fileName
        sLine = sLine & "\n           DosName = " & .dosFileName
        sLine = sLine & "\n            path\\ = " & .path
        sLine = sLine & "\n    path\\fileName = " & .pathFileName
        sLine = sLine & "\n              Size = " & Strf$(.Size, ffFixed, 18, 0)
        sLine = sLine & "\n         Attributs = " & Str$(.Attributes)
        sLine = sLine & "\n     Attr_AsString = " & .AttributesAsString
        sLine = sLine & "\n      CreationTime = " & Strf$(.creation.DateTime, ffFixed, 18, 0)
        sLine = sLine & "\n                or = " & .creation.strDayOfWeek & " " & .creation.strMonthOfYear & " " & .creation.date _
                                                        & " " & .creation.time & " WeekDay#=" & .creation.nWeekDay
        sLine = sLine & "\n    LastAccessTime = " & Strf$(.lastAccess.DateTime, ffFixed, 18, 0)
        sLine = sLine & "\n                or = " & .lastAccess.strDayOfWeek & " " & .lastAccess.strMonthOfYear & " " & .lastAccess.date _
                                                        & " " & .lastAccess.time & " WeekDay#=" & .lastAccess.nWeekDay
        sLine = sLine & "\n     LastWriteTime = " & Strf$(.DateTime, ffFixed, 18, 0)
        sLine = sLine & "\n                or = " & .strDayOfWeek & " " & .strMonthOfYear & " " & .date _
                                                        & " " & .time & " WeekDay#=" & .lastWrite.nWeekDay
        sLine = sLine & "\n              Time = " & .Time
        sLine = sLine & "\n              Date = " & .date
        sLine = sLine & "\n            DateEU = " & .dateEU
        sLine = sLine & "\n         DateAlpha = " & .dateAlpha
        sLine = sLine & "\n       DateAlphaEU = " & .dateAlphaEU
        Print sline
        myFile.WriteLine (sLine)
    End With
End sub
' ---------------------------------------------------------------------------------
' EXIT CONSOLE
' ------------
EXITCONSOLE:
DefStr sExit
Input "\n\n                    CR to QUIT \n\n", sExit
Application.Terminate
End
' ---------------------------------------------------------------------------------
'
