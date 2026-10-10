' ============================================================== '
' QSHFileOperation component - version 1            January 2002 '
'                                                 Marcin Szafran '
' Implemented API SHFileOperation function.                      '
' Allows copy, rename, delete and move files and folders         '
' with wildcard and recursivly... and much more!                 '
' *****   BE   CAREFULL   WITH   DELETE   AND   RECURSE!   ***** '
' Thanks for Jacques Philippe for his help                       '
' ============================================================== '

'= QSHFileOperation methods description ==================

'--- Copying ---
'    .CopyEx: Copying with extended attributes
'      .Copy: Simple copying
' Usage ObjName.CopyEx("ExistingFileName(s)","SourceFileName(s)",flags,handle)
'       ObjName.Copy("ExistingFileName(s)","SourceFileName(s)")
' RQ keyword: - (none)

'--- Moving and Renaming ---
'    .MoveEx: Moving with extended attributes
'      .Move: Simple moving
'  .RenameEx: Renaming with extended attributes
'    .Rename: Simple renaming
' Usage ObjName.MoveEx("ExistingFileName(s)","SourceFileName(s)",flags,handle)
'       ObjName.Move("ExistingFileName(s)","SourceFileName(s)")
'       ObjName.RenameEx("ExistingFileName(s)","SourceFileName(s)",flags,handle)
'       ObjName.Rename("ExistingFileName(s)","SourceFileName(s)")
' RQ keyword: RENAME (does not work with dirs)

'--- Deleting ---
'  .DeleteEx: Deleting with deleting confirmation on/off and other extended attributes - enables delete to Recycle Bin
'    .Delete: Simple deleting with deleting confirmation on/off - enables delete to Recycle Bin
' Usage ObjName.DeleteEx("FileName(s)",to_Bin_on/off,confirm_on/off,flags,handle)
'       ObjName.Delete("FileName(s)",to_Bin_on/off,confirm_on/off)
' RQ keyword: KILL (does not work with dirs)

'= QSHFileOperation properties description ===============

' .DefaultFlagsEx: Setting default flags for methods with extended attributes (.MethodNameEx) - now = 0
'   .DefaultFlags: Setting default flags for simple methods (.MethodName)

$TYPECHECK ON

'= CONSTANTS =============================================

'--- Operations ---

Const foMove = &H1   ' Move the files specified in pFrom to the location specified in pTo
Const foCopy = &H2   ' Copy the files specified in the pFrom member to the location specified in the pTo member 
Const foDelete = &H3 ' Delete the files specified in pFrom
Const foRename = &H4 ' Rename the file specified in pFrom. You cannot use this flag to rename multiple files with a single function call. Use FO_MOVE instead

'--- Flags - should be set with OR operator if used more than one ---
'--- Constants names were changed to RapidQ kind --------------------

Const fofAllowUndo = &H40              ' Preserve Undo information, if possible. If pFrom does not contain fully qualified path and file names, this flag is ignored
Const fofConfirmMouse = &H2            ' Not currently used
Const fofFilesOnly = &H80              ' Perform the operation on files only if a wildcard file name (*.*) is specified
Const fofMultiDestFiles = &H1          ' The pTo member specifies multiple destination files (one for each source file) rather than one directory where all source files are to be depos
Const fofNoConnectedElements = &H2000  ' Do not move connected files as a group. Only move the specified files
Const fofNoConfirmation = &H10         ' Respond with "Yes to All" for any dialog box that is displayed
Const fofNoConfirmMkDir = &H200        ' Do not confirm the creation of a new directory if the operation requires one to be created
Const fofNoCopySecurityAttribs = &H800 ' Do not copy the security attributes of the file
Const fofNoErrorUI = &H400             ' Do not display a user interface if an error occurs
'Const fof_RecurseReparse =            ' Recurse into reparse points. The default is to not recurse
'Const fof_NoRecurseReparse =          ' Treat reparse points as objects, not containers. You must set _WIN32_WINNT to 5.01 or later to use this flag
Const fofNoRecursion = &H1000          ' Only operate in the local directory. Don't operate recursively into subdirectories
Const fofRenameOnCollision = &H8       ' Give the file being operated on a new name in a move, copy, or rename operation if a file with the target name already exists
Const fofSilent = &H4                  ' Do not display a progress dialog box
Const fofSimpleProgress = &H100        ' Display a progress dialog box but do not show the file names
'Const fofWantMappingHandle = &H20     ' If FOF_RENAMEONCOLLISION is specified and any files were renamed, assign a name mapping object containing their old and new names to the hNameMappings member
Const fofWantNukeWarning = &H4000      ' Send a warning if a file is being destroyed during a delete operation rather than recycled. This flag partially overrides FOF_NOCONFIRMATION

' If the pFrom or pTo members are unqualified names, the current directories are taken from the global current drive and directory settings 
' If pFrom is set to a file name, deleting the file with FO_DELETE will not move it to the Recycle Bin, even if the FOF_ALLOWUNDO flag is set. You must use a full path name

'= DECLARATIONS ==========================================

Type SHFILEOPSTRUCT
    hwnd As Long                       ' Window handle to the dialog box to display information about the status of the file operation
    wFunc As Long                      ' Value that indicates which operation to perform (foMove, foCopy, foDelete, foRename)
    pFrom As Long                      ' Address of a buffer to specify one or more source file names. These names must be fully qualified paths. Standard DOS wild cards, such as "*", are permitted in the file-name position
    pTo As Long                        ' Address of a buffer to contain the name of the destination file or directory. This parameter must be set to NULL if it is not used. Like pFrom, the pTo member is also a double-NULL terminated string and is handled in much the same way
    fFlags As Integer                  ' Flags that control the file operation
    fAnyOperationsAborted As Long      ' Value that receives TRUE if the user aborted any file operations before they were completed, or FALSE otherwise
    hNameMappings As Long              ' A handle to a name mapping object containing the old and new names of the renamed files. This member is used only if the fFlags member includes the FOF_WANTMAPPINGHANDLE flag
    lpszProgressTitle As Long          ' Address of a string to use as the title of a progress dialog box. This member is used only if fFlags includes the FOF_SIMPLEPROGRESS flag. Does not work - don't know why... Tested almost everything :-(
End Type

' Some flags need higher than 4.0 versions of shell32.dll. For more informations about SHFileOperation and SHFILEOPSTRUCT see:
' http://msdn.microsoft.com/library/default.asp?url=/library/en-us/shellcc/platform/Shell/functions/SHFileOperation.asp
' and http://msdn.microsoft.com/library/default.asp?url=/library/en-us/shellcc/platform/Shell/Structures/SHFILEOPSTRUCT.asp

Declare Function SHFileOperation Lib "shell32.dll" _
          Alias "SHFileOperationA" (lpFileOp As SHFILEOPSTRUCT) As Long

Dim lpFileOp As SHFILEOPSTRUCT

DefStr SHfoFrom, dSHfoFrom, SHfoTo, dSHfoTo

'= QSHFILEOPERATION COMPONENT ============================

Type QSHFileOperation Extends QObject

Private:
'TempString As String

Sub ClearSHFileOperationStructure
    '--- Clear structure
    lpFileOp.hwnd = 0
    lpFileOp.wFunc = 0
    lpFileOp.pFrom = 0
    lpFileOp.pTo = 0
    lpFileOp.fFlags = 0
    'lpFileOp.fAnyOperationsAborted = 0
    'lpFileOp.hNameMappings = 0
    'lpFileOp.lpszProgressTitle = 0
End Sub

Public:
DefaultFlagsEx As Integer
DefaultFlags As Integer

Constructor
    DefaultFlagsEx = 0
    DefaultFlags = fofRenameOnCollision
End Constructor

' I hope that parameters names are clear

Function CopyEx (dSHfoFrom As String, dSHfoTo As String, _
                 SHfoFlags As Integer, SHfoHandle As Long) As Long

    SHfoFrom = dSHfoFrom & Chr$(0)
    SHfoTo = dSHfoTo & Chr$(0)
        QSHFileOperation.ClearSHFileOperationStructure
        '--- Fill structure
        lpFileOp.hwnd = SHfoHandle
        lpFileOp.wFunc = foCopy
        lpFileOp.pFrom = VarPtr(SHfoFrom)
        lpFileOp.pTo = VarPtr(SHfoTo)
        lpFileOp.fFlags = QSHFileOperation.DefaultFlagsEx OR SHfoFlags
        'lpFileOp.fAnyOperationsAborted =
        'lpFileOp.hNameMappings =
        'lpFileOp.lpszProgressTitle = VarPtr(dSHfoProgressTitle)
    Result = SHFileOperation(lpFileOp)
End Function

Function Copy (dSHfoFrom As String, dSHfoTo As String) As Long
    SHfoFrom = dSHfoFrom & Chr$(0)
    SHfoTo = dSHfoTo & Chr$(0)
        QSHFileOperation.ClearSHFileOperationStructure
        '--- Fill structure
        lpFileOp.wFunc = foCopy
        lpFileOp.pFrom = VarPtr(SHfoFrom)
        lpFileOp.pTo = VarPtr(SHfoTo)
        lpFileOp.fFlags = QSHFileOperation.DefaultFlags
    Result = SHFileOperation(lpFileOp)
End Function

Function MoveEx (dSHfoFrom As String, dSHfoTo As String, _
                 SHfoFlags As Integer, SHfoHandle As Long) As Long
    SHfoFrom = dSHfoFrom & Chr$(0)
    SHfoTo = dSHfoTo & Chr$(0)
        QSHFileOperation.ClearSHFileOperationStructure
        '--- Fill structure
        lpFileOp.hwnd = SHfoHandle
        lpFileOp.wFunc = foMove
        lpFileOp.pFrom = VarPtr(SHfoFrom)
        lpFileOp.pTo = VarPtr(SHfoTo)
        lpFileOp.fFlags = QSHFileOperation.DefaultFlagsEx OR SHfoFlags
        'lpFileOp.fAnyOperationsAborted =
        'lpFileOp.hNameMappings =
        'lpFileOp.lpszProgressTitle = VarPtr(dSHfoProgressTitle)
    Result = SHFileOperation(lpFileOp)
End Function

Function Move (dSHfoFrom As String, dSHfoTo As String) As Long
    SHfoFrom = dSHfoFrom & Chr$(0)
    SHfoTo = dSHfoTo & Chr$(0)
        QSHFileOperation.ClearSHFileOperationStructure
        '--- Fill structure
        lpFileOp.wFunc = foMove
        lpFileOp.pFrom = VarPtr(SHfoFrom)
        lpFileOp.pTo = VarPtr(SHfoTo)
        lpFileOp.fFlags = QSHFileOperation.DefaultFlags
    Result = SHFileOperation(lpFileOp)
End Function

Function RenameEx (dSHfoFrom As String, dSHfoTo As String, _
                   SHfoFlags As Integer, SHfoHandle As Long) As Long
    SHfoFrom = dSHfoFrom & Chr$(0)
    SHfoTo = dSHfoTo & Chr$(0)
        QSHFileOperation.ClearSHFileOperationStructure
        '--- Fill structure
        lpFileOp.hwnd = SHfoHandle
        lpFileOp.wFunc = foRename
        lpFileOp.pFrom = VarPtr(SHfoFrom)
        lpFileOp.pTo = VarPtr(SHfoTo)
        lpFileOp.fFlags = QSHFileOperation.DefaultFlagsEx OR SHfoFlags
        'lpFileOp.fAnyOperationsAborted =
        'lpFileOp.hNameMappings =
        'lpFileOp.lpszProgressTitle = VarPtr(dSHfoProgressTitle)
    Result = SHFileOperation(lpFileOp)
End Function

Function Rename (dSHfoFrom As String, dSHfoTo As String) As Long
    SHfoFrom = dSHfoFrom & Chr$(0)
    SHfoTo = dSHfoTo & Chr$(0)
        QSHFileOperation.ClearSHFileOperationStructure
        '--- Fill structure
        lpFileOp.wFunc = foRename
        lpFileOp.pFrom = VarPtr(SHfoFrom)
        lpFileOp.pTo = VarPtr(SHfoTo)
        lpFileOp.fFlags = QSHFileOperation.DefaultFlags
    Result = SHFileOperation(lpFileOp)
End Function

Function DeleteEx (dSHfoFrom As String, SHfoToBin As Integer, SHConfirm As Integer, _
                   SHfoFlags As Integer, SHfoHandle As Long) As Long
    SHfoFrom = dSHfoFrom & Chr$(0)
        QSHFileOperation.ClearSHFileOperationStructure
        '--- Fill structure
        lpFileOp.hwnd = SHfoHandle
        lpFileOp.wFunc = foDelete
        lpFileOp.pFrom = VarPtr(SHfoFrom)
        lpFileOp.fFlags = QSHFileOperation.DefaultFlagsEx OR SHfoFlags OR (fofAllowUndo * SHfoToBin) OR (fofNoConfirmation * ABS(SHConfirm - 1))
        'lpFileOp.fAnyOperationsAborted =
        'lpFileOp.hNameMappings =
        'lpFileOp.lpszProgressTitle = VarPtr(dSHfoProgressTitle)
    Result = SHFileOperation(lpFileOp)
End Function

Function Delete (dSHfoFrom As String, SHfoToBin As Integer, SHConfirm As Integer) As Long
    SHfoFrom = dSHfoFrom & Chr$(0)
        QSHFileOperation.ClearSHFileOperationStructure
        '--- Fill structure
        lpFileOp.wFunc = foDelete
        lpFileOp.pFrom = VarPtr(SHfoFrom)
        lpFileOp.fFlags = QSHFileOperation.DefaultFlags OR (fofAllowUndo * SHfoToBin) OR (fofNoConfirmation * ABS(SHConfirm - 1))
    Result = SHFileOperation(lpFileOp)
End Function

End Type

$TYPECHECK OFF

'= END =================================================== 
