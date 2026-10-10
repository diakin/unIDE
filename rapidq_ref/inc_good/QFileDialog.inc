$IFNDEF __QFILEDIALOG_INC   ' inc2026: подключается только первая версия QFileDialog (QFileDialog.inc, QFileDialogDoc.inc или версия в RAPIDQ2.INC)
$DEFINE __QFILEDIALOG_INC
$DEFINE __QFILEDIALOG_INC_SA   ' inc2026: подключён отдельный файл QFileDialog - совпадающие объявления в RAPIDQ.INC / RAPIDQ2.INC пропустятся
'============================================================================================
'  Class QFILEDIAGLOG   an Open or Save sizeable file dialog box with overwrite warning
'  Version 1.0 
'  11/2004 original code adapted from RQDIALOG.INC by   BILL K  1-2003
'  by JohnK
'============================================================================================
'
' USAGE:  MYFILENAME$=RQSHOWDIALOG(MyCaption$, _                ' default is "Open" or "Save"
'                                  MyFilter$, _                 ' default is All Files
'                                  FilterIndex%, _              ' default is 0
'                                  MyInitialDirectory$, _       ' default is current directory
'                                  WantSaveDialog%, _           ' 1=Save  0=Open - default is Open 
'                                  NoOverwriteWarning%, _       ' default is 0
'                                  MyFormHandle&)               ' Form handle or 0 .. default is 0 - see below
' 
'    WantSaveDialog%=1 for a Save Dialog   =0 for an Open Dialog
'    NoOverwriteWarning%=1 for defeating the default warning when about to overwrite an existing file
'    MyFormHandle& = MyForm.Handle ( so that the dialog knows which form
'                                    to be modal to and where to locate)   =0 for nonmodal(not advised)
' 
'  EXAMPLE: FileName$=RQShowDialog("Save File","RQ Files|*.bas;*.rqb","C:\RapidQ",1,0,Form.Handle)

$IFNDEF _RQDIALOGINC
$DEFINE _RQDIALOGINC

CONST OFN_READONLY                 =  &H00000001  
CONST OFN_OVERWRITEPROMPT          =  &H00000002  'display the overwrite warning
CONST OFN_HIDEREADONLY             =  &H00000004  'hide the Open as Readonly checkbox
CONST OFN_NOCHANGEDIR              =  &H00000008  'return to original director if the user changed the directory while searching
CONST OFN_SHOWHELP                 =  &H00000010
CONST OFN_ENABLEHOOK               =  &H00000020
CONST OFN_ENABLETEMPLATE           =  &H00000040
CONST OFN_ENABLETEMPLATEHANDLE     =  &H00000080
CONST OFN_NOVALIDATE               =  &H00000100
CONST OFN_ALLOWMULTISELECT         =  &H00000200   'multiple file select, should have OFN_EXPLORER = 1 for long filenames
CONST OFN_EXTENSIONDIFFERENT       =  &H00000400
CONST OFN_PATHMUSTEXIST            =  &H00000800
CONST OFN_FILEMUSTEXIST            =  &H00001000
CONST OFN_CREATEPROMPT             =  &H00002000
CONST OFN_SHAREAWARE               =  &H00004000
CONST OFN_NOREADONLYRETURN         =  &H00008000
CONST OFN_NOTESTFILECREATE         =  &H00010000
CONST OFN_NOLONGNAMES              =  &H00040000
CONST OFN_EXPLORER                 =  &H00080000 'explorer like browser
CONST OFN_NODEREFERENCELINKS       =  &H00100000
CONST OFN_LONGNAMES                =  &H00200000

'Error codes from CommDlgExtendedError
Public Const CDERR_DIALOGFAILURE = &HFFFF
Public Const CDERR_GENERALCODES = &H0
Public Const CDERR_STRUCTSIZE = &H1
Public Const CDERR_INITIALIZATION = &H2
Public Const CDERR_NOTEMPLATE = &H3
Public Const CDERR_NOHINSTANCE = &H4
Public Const CDERR_LOADSTRFAILURE = &H5
Public Const CDERR_FINDRESFAILURE = &H6
Public Const CDERR_LOADRESFAILURE = &H7
Public Const CDERR_LOCKRESFAILURE = &H8
Public Const CDERR_MEMALLOCFAILURE = &H9
Public Const CDERR_MEMLOCKFAILURE = &HA
Public Const CDERR_NOHOOK = &HB
Public Const CDERR_REGISTERMSGFAIL = &HC

TYPE OPENFILENAME
lStructSize  AS DWORD 'Specifies the length, in bytes, of the structure. 
hwndOwner   AS LONG  'any valid window handle, or it can be NULL if the dialog box has no owner
hInstance   AS LONG  'for OFN_ENABLETEMPLATEHANDLE or ENABLETEMPLATE  flags
lpstrFilter  AS LONG  'pointer to string containing pairs of filter strings, ("*.TXT;*.DOC;*.BAK"), no spaces!
lpstrCustomFilter AS LONG 'null or pointer to a pair of null-terminated filter strings for preserving the filter pattern chosen by the user
nMaxCustFilter  AS DWORD 'the size, in bytes of the buffer identified by lpstrCustomFilter
nFilterIndex  AS DWORD 'index of the currently selected filter in the File Types 
lpstrFile   AS LONG  'Pointer to string of the file name to initialize control,can be multple if OFN_ALLOWMULTISELECT  set, _
'first char must be NULL if no initialization. Returns drive designator, path, file name, and extension of the selected file. 
nMaxFile   AS DWORD 'size in bytes of lpstrFile should be >256 chars
lpstrFileTitle  AS LONG  'Pointer to string that receives the file name and extension (without path information) of the selected file. This member can be NULL
nMaxFileTitle  AS DWORD 'size in bytes of lpstrFileTitle
lpstrInitialDir AS LONG  'pointer to string containing directory, different effect on different OS versions!
lpstrTitle   AS LONG  'pointer to string containing title
flags    AS DWORD '
nFileOffset  AS SHORT 'zero-based offset, number of chars  to the 1st character of the file name in lpstrFile (not path)
nFileExtension  AS SHORT 'zero-based offset, number of chars  to the 1st character of the file extension in lpstrFile (not path)
lpstrDefExt  AS LONG  'pointer to string to append as filename extension if the user fails to type an extension- only 3 characters are used, should not contain a period (.)
lCustData   AS LONG  'AS LPARM
lpfnHook   AS LONG  'AS LPOFNHOOKPROC, pointer to callback function
lpTemplateName  AS LONG  'pointer to string that names a dialog template resource in the module identified by the hInstance member
'#if (_WIN32_WINNT >= 0x0500)
'  void *        pvReserved;
'  DWORD         dwReserved;
'  DWORD         FlagsEx;
'#endif // (_WIN32_WINNT >= 0x0500)
END TYPE

DECLARE FUNCTION GetSaveFileName LIB "COMDLG32" ALIAS "GetSaveFileNameA" (pOpenfilename AS OPENFILENAME) AS LONG
DECLARE FUNCTION GetOpenFileName LIB "COMDLG32" ALIAS "GetOpenFileNameA" (pOpenfilename AS OPENFILENAME) AS LONG
Declare Function CommDlgExtendedError Lib "comdlg32.dll" Alias "CommDlgExtendedError" () As Long


$DEFINE fdOpen  0
$DEFINE fdSave  1
CONST fdStrTerm$ = CHR$(0) + CHR$(0)
CONST fdMaxFiles = 256

TYPE QFILEDIALOG EXTENDS QOBJECT
  PRIVATE:
     tmpFileName    AS STRING
     tmpFilter      AS STRING
     tmpFileTitle   AS STRING  'output string
     OFN            AS OPENFILENAME

  PUBLIC:
     Parent         AS LONG   'Parent form handle, can be NULL
     Caption        AS STRING  ' default is "Open" or "Save"
     Filter         AS STRING  '*.*
     FilterIndex    AS INTEGER  '0 based
     InitialDir     AS STRING
     Mode           AS INTEGER  'enum fdOpen = Open (default),  fdSave = save,
     WarnIfOverWrite AS INTEGER  'warning to overwrite?
     Filename       AS STRING
     FileTitle      AS STRING
     DefaultExt     AS STRING
     MultiSelect    AS INTEGER
     SelCount       AS INTEGER
     NoChangeDir    AS INTEGER
     Files(fdMaxFiles) AS STRING

 CONSTRUCTOR
     Parent   = 0                   'Parent form handle, can be NULL
     Caption   = "Open" + STRING$(243, 0)
     Filter   = "All Files|*.*" + STRING$(243, 0)
     FilterIndex  = 0
     InitialDir  = STRING$(256, 0)  'allocate a fixed memory
     Mode   = 0                     'enum 0 = Open (default), 1 = save,
     WarnIfOverWrite = 1            'warning to overwrite?
     Filename  = STRING$(1024, 0)   'allocate memory only once!
     tmpFileName  = STRING$(1024, 0)
     DefaultExt  = STRING$(256,  0)  'no default extension
     MultiSelect  = 0
     SelCount   = 0
     NoChangeDir  = 0
 END CONSTRUCTOR


 FUNCTION Execute() AS LONG
  DIM FndSpace1  AS INTEGER
  DIM FndSpace2  AS INTEGER
  DIM StrLenth  AS INTEGER
  DIM MyHresult  AS LONG   'return result


  WITH QFILEDIALOG
     .OFN.lStructSize = SIZEOF(QFILEDIALOG.OFN)
     .OFN.hwndOwner = .Parent
     .OFN.hInstance = 0
     'file filter string, ends wtih 2 null chars
     IF RIGHT$(.Filter, 2) <> fdStrTerm$ THEN .Filter = .Filter + fdStrTerm$ ' inc2026: было pdfStrTerm$ (нигде не объявлена, пустая строка), стало fdStrTerm$ (CONST в строке 100); в старой версии inc/old/QFileDialogDoc.inc константа называлась pdfStrTerm$, при переименовании эта строка осталась прежней
     .tmpFilter = REPLACESUBSTR$(.Filter, "|", CHR$(0)) 'set up for API delimiter
     .OFN.lpstrFilter = VARPTR(QFILEDIALOG.tmpFilter) 'use temp filter for conditioning
     .OFN.nFilterIndex = .FilterIndex

     IF .FileName = "" THEN 
         .tmpFileName = String$(1024,0)     'max 1024 chars for file input names
     ELSE
          .tmpFileName = .FileName
         ' buffer with null and make string large just in case multiple select (must be > 256)
        IF LEN(.FileName) < 1024 THEN .tmpFileName = .tmpFileName + String$(1024-LEN(.FileName),0)
     END IF

     .OFN.lpstrFile = VARPTR(QFILEDIALOG.tmpFileName)  'set pointer to input filename
     .OFN.nMaxFile = LEN(.tmpFileName)   'num chars to expect
     .tmpFileTitle = String$(1024,0)       'string that gets the result,without path
     .OFN.nMaxFileTitle = 1024        'set length
     .OFN.lpstrFileTitle = VARPTR(QFILEDIALOG.tmpFileTitle) 'set pointers
     IF .InitialDir <> "" THEN
          .OFN.lpstrInitialDir = VARPTR(QFILEDIALOG.InitialDir)  
     ELSE
          .OFN.lpstrInitialDir = 0&
     END IF
    
     .OFN.lpstrTitle = VARPTR(QFILEDIALOG.Caption)
     IF .DefaultExt <> "" THEN .OFN.lpstrDefExt = VARPTR(QFILEDIALOG.DefaultExt)
     IF .WarnIfOverWrite THEN
         .OFN.flags =OFN_HIDEREADONLY OR OFN_OVERWRITEPROMPT
     ELSE
         .OFN.flags =OFN_HIDEREADONLY
     END IF
     IF .MultiSelect THEN .OFN.flags = .OFN.flags OR OFN_ALLOWMULTISELECT OR OFN_EXPLORER
     IF .NoChangeDir THEN .OFN.flags = .OFN.flags OR OFN_NOCHANGEDIR
    
     SELECT CASE .Mode
       CASE = fdOpen
           MyHresult = GetOpenFileName(.OFN)
       CASE = fdSave
          MyHresult = GetSaveFileName(.OFN) 'runs dialog box
       CASE ELSE
          ShowMessage "Invalid Mode in FileDialog"
     END SELECT
    
    
     IF MyHresult <> 0 THEN        'returns 0 on CANCEL
      '  .tmpFileName = STRING$(.OFN.nMaxFile, 0)  'can't reallocate string memory!
        MEMCPY(VARPTR(QFILEDIALOG.tmpFileName), .OFN.lpstrFile, .OFN.nMaxFile) 'get string
        StrLenth = INSTR(QFILEDIALOG.tmpFileName, fdStrTerm$)  'find null terminator
        .FileTitle = STRING$(.OFN.nMaxFileTitle, 32)    'allocate
        MEMCPY(VARPTR(QFILEDIALOG.FileTitle), .OFN.lpstrFileTitle, .OFN.nMaxFileTitle) ' inc2026: было .OFN.nMaxFile, стало .OFN.nMaxFileTitle: копируется буфер имени без пути (lpstrFileTitle), его размер nMaxFileTitle (строки 170-171, 203); nMaxFile - размер другого буфера (строка 169)
        .FileTitle = LEFT$(QFILEDIALOG.FileTitle, (INSTR(QFILEDIALOG.FileTitle, fdStrTerm$))-1)
    
      IF .MultiSelect THEN
           .tmpFileName = LEFT$(.tmpFileName, StrLenth)
           .tmpFileName = REPLACESUBSTR$(.tmpFileName, CHR$(0), CHR$(255)) 'prevent string termination
           FndSpace1 = 1:  FndSpace2 = 0
           .SelCount = -1        'for 0 indexing
          DO
             FndSpace2 = INSTR(FndSpace1, .tmpFileName, CHR$(255))  'null doesn't work, trick w/chr 255
             IF FndSpace2 = 0 THEN
                EXIT DO
             ELSE
               .SelCount++
               .Files(.SelCount) = MID$(.tmpFileName, FndSpace1, (FndSpace2 - FndSpace1))
               FndSpace1 = FndSpace2 + 1
               IF .SelCount > fdMaxFiles THEN EXIT DO  'too many files
            END IF
          LOOP UNTIL FndSpace2 >= StrLenth

           .FileName = ""
           FOR FndSpace1 = 1 TO StrLenth - 1     'strip out null terminators
              FndSpace2 = ASC(MID$(.tmpFileName,FndSpace1, 1))
              IF (FndSpace2 <> 0) AND (FndSpace2 <> 255) THEN .FileName = .FileName + CHR$(FndSpace2)
           NEXT FndSpace1
           IF .SelCount = 0 THEN     'just one file selected in multiselect
            .Files(1) = .FileTitle    'keep compatibile with multiselect
            .Files(0) = .FileName - .FileTitle '0 index is path
            .SelCount = 1      'need to update file was picked
           END IF
           IF RIGHT$(.Files(0),1) <>"\" THEN .Files(0)= .Files(0) + "\"
    
      ELSE
          .FileName = LEFT$(.tmpFileName, StrLenth-1)  'take out extra null char
      END IF

      END IF
    
     RESULT = MyHresult
   END WITH
  END FUNCTION

END TYPE
$ENDIF ' _RQDIALOGINC
$ENDIF  ' inc2026: __QFILEDIALOG_INC
