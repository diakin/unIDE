'=======================================================================|
'Fileops is a set functions to manipulate file names and paths.         |
'  QUOTE - Returns a quoted string                                      |
'  STRIPPATH - Returns file path (without file name)                    |
'  STIPFILENAME - Returns file name (without path)                      |
'  STRIPFILEEXT - Returns file extension (like ".exe", ".html" etc.)    |
'  FILENAMENOEXT - Returns file name without extension                  |
'  FULLPATHNOEXT - Returns full path without file extension             |
'  BROWSEFORFOLDERS : Returns the selected folder                       |
'  BROWSEFORFILE : Uses opendialog, returns file name                   |
'=======================================================================|


$IFNDEF __FILEOPS_INC
$DEFINE __FILEOPS_INC

    
    '===============================================================================
    '# QUOTE : Returns a quoted string
FUNCTION Quote(StringToQuote AS STRING) AS STRING
    StringToQuote = CHR$(34) + StringToQuote + CHR$(34)
    Result = REPLACESUBSTR$(stringtoquote , CHR$(34) + CHR$(34) , CHR$(34))
END FUNCTION

    '===============================================================================
    '# STRIPPATH : Returns file path (without file name)
FUNCTION StripPath(fullname AS STRING) AS STRING
    Result = LEFT$(fullname , rinstr(fullname , "\"))
END FUNCTION

    '===============================================================================
    '# STRIPFILENAME : Returns file name (without path)
FUNCTION StripFileName(fullname AS STRING) AS STRING
    Result = RIGHT$(fullname , LEN(fullname) - rinstr(fullname , "\"))
END FUNCTION

    '===============================================================================
    '# STRIPFILEEXT : Returns file extension (like ".exe", ".html" etc.)
FUNCTION StripFileExt(fullname AS STRING) AS STRING
    Result = RIGHT$(fullname , LEN(fullname) - rinstr(fullname , ".") + 1)
END FUNCTION

    '===============================================================================
    '# FILENAMENOEXT : Returns file name without extension
FUNCTION FileNameNoExt(fullname AS STRING) AS STRING
    fullname = RIGHT$(fullname , LEN(fullname) - rinstr(fullname , "\"))
    Result = LEFT$(fullname , rinstr(fullname , ".") - 1)
END FUNCTION

    '===============================================================================
    '# FULLPATHNOEXT : Returns full path without file extension
FUNCTION FullPathNoExt(fullname AS STRING) AS STRING
    Result = LEFT$(fullname , rinstr(fullname , ".") - 1)
END FUNCTION

    '===============================================================================
    '# C_Style : Returns "slashed" path from a "backslashed" one
FUNCTION C_Style(fullname AS STRING) AS STRING
    fullname = REPLACESUBSTR$(fullname , "\\" , "\")
    Result = REPLACESUBSTR$(fullname , "\" , "/")
END FUNCTION


    '===============================================================================
    '# SYSDIR : Retrieves windows shell directories
    '-------------------------|
    'Allowed values for dir  |
    '----------------------------------------------------------------------------|
    'Desktop                 | Templates               | AppData                 |
    'Start Menu              | Programs                | Startup                 |
    'Fonts                   | SendTo                  | Recent                  |
    'Favorites               | Cache                   | Cookies                 |
    'History                 | NetHood                 | Personal                |
    'PrintHood               | Local AppData           | My Pictures             |
    'Administrative Tools    |                         |                         |
    '----------------------------------------------------------------------------|
FUNCTION SysDir(dir AS STRING) AS STRING
    DIM fo_reg AS QREGISTRY
    fo_reg.RootKey = &H80000001
    fo_reg.openkey("Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" , 0)
    Result = fo_reg.readstring(dir) + "\"
END FUNCTION

    '===============================================================================
    '# HOMEDIR : The folder where the application is
FUNCTION homedir() AS STRING
    Result = LEFT$(Command$(0) , rinstr(Command$(0) , "\"))
END FUNCTION



    '===============================================================================
    '# SAVEFILEAS : Uses Savedialog, returns file name
FUNCTION SaveFileAs (Caption as string, Filter as string, _
    initialdir as string) as string
    Dim SF as Qsavedialog
    with SF
    .caption = Caption
        if direxists(initialdir) then
            .initialdir = initialdir
        else
            .initialdir = curdir$
        end if
        .filter = filter
        if .execute then
            if fileexists(.filename) then
                if Messagedlg( "File " + .filename + _
                " already exists. Overwrite ?", 0, 1 or 2, 0) = 6 then
                Result = .Filename
                end if
            else
            Result = .Filename
            end if
        end if
    end with
END FUNCTION



'===============================================================================
'# BROWSEFORFOLDERS : Returns the selected folder
FUNCTION BrowseForFolders(InitialDir AS STRING , wincapt AS STRING) AS STRING
    DIM bff_form AS QFORM
    WITH bff_form
        .Height = 400
        .Center
        .Caption = wincapt
        .DelBorderIcons 2
    END WITH
    DIM bff_tree AS QDIRTREE
    WITH bff_tree
        .Parent = bff_form
        .Align = 5
    END WITH
    IF bff_form.Caption = "" THEN bff_form.Caption = "Select folder"
    IF DIREXISTS(InitialDir) THEN
        bff_tree.Directory = InitialDir
    ELSE
        bff_tree.Directory = CurDir$
    END IF
    bff_form.ShowModal
    Result = bff_tree.Directory
END FUNCTION

'===============================================================================
'# BROWSEFORFILE : Uses opendialog, returns file name
FUNCTION BrowseForFile(Caption AS STRING , Filter AS STRING , _
        InitialDir AS STRING) AS STRING

    DIM bff_od AS QOPENDIALOG
    WITH bff_od
        .Caption = Caption
        .Filter = Filter
        .InitialDir = InitialDir

        IF .Execute THEN
            result =.FileName
        END IF
    END WITH
END FUNCTION


$ENDIF


' *** Sample test code ***
' DECLARE SUB file_operations
' 
' CREATE form AS QFORM
'     Center
'     Width = 500
'     CREATE fl AS QFILELISTBOX
'         Align = 3
'         OnDblClick = file_operations
'     END CREATE
'     CREATE re AS QRICHEDIT
'         Align = 5
'         Font.Name = "Courier new"
'         Wordwrap = 0
'     END CREATE
'     ShowModal
' END CREATE
' 
' SUB file_operations
'     re.Clear
'     DIM sta AS STRING
'     sta = fl.FileName
'     re.AddStrings "ORIGINAL FILE NAME" + CHR$(9) + sta , _
'         "QUOTED FILE NAME" + CHR$(9) + quote(sta) , _
'         "FILE PATH" + CHR$(9) + CHR$(9) + StripPath(sta) , _
'         "FILE NAME" + CHR$(9) + CHR$(9) + stripfilename(sta) , _
'         "FILE EXTENSION" + CHR$(9) + stripfileext(sta) , _
'         "WITHOUT EXTENSION" + CHR$(9) + filenamenoext(sta) , _
'         "FULL NAME (NO EXT)" + CHR$(9) + fullpathnoext(sta)
' END SUB

'*** end sample test code ***
