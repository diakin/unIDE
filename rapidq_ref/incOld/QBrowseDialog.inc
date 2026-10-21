'================= QBrowseDialog =======================

' A little easier to use than QDirTree when all you 
' want is the name of a folder...

' It has familiar properties:

' Caption is the string that appears in the title bar
' Title is the string that appears over the treeview
' InitialDir is the folder that is hilighted on startup
' Directory is the folder that was selected

' Like QOpenDialog, QSaveDialog, and QColorDialog, you
' DIM or CREATE it in code. To show the dialog, call
' <Name>.Execute. If the user presses "OK", the function
' returns 1. If the user presses "Cancel" or closes the
' Dialog, the result is 0. This Dialog also returns
' virtual folders like the Recycle Bin and Fonts folder,
' although in name only (you can't access these folders
' by path). Use it in good health!

' Psyclops ·)



TYPE BROWSEINFO                  ' structure to pass to the API
    hWndOwner      AS LONG       ' remove icon from taskbar
    pIDLRoot       AS LONG       ' first visible folder (0 for Desktop)
    pszDisplayName AS LONG       ' buffer for folder name (not path!)
    lpszTitle      AS LONG       ' buffer for Title string
    ulFlags        AS LONG       ' ???
    lpfnCallback   AS LONG       ' pointer to window proc
    lParam         AS LONG       ' pointer to InitialDir
    iImage         AS LONG       ' ???
END TYPE

const BIF_RETURNONLYFSDIRS = 1          ' only select folders
'const MAX_PATH             = 260        ' buffer length
const BFFM_INITIALIZED     = 1          ' for the hook
const BFFM_SETSELECTIONA   = &H466      ' sets InitialDir

DECLARE SUB CoTaskMemFree LIB "Ole32" ALIAS "CoTaskMemFree"(hMem AS LONG)          ' clear pidList from memory
DECLARE FUNCTION SHBrowseForFolder LIB "Shell32" ALIAS "SHBrowseForFolder"_        ' the API!
                 (lpbi AS BROWSEINFO) AS LONG
DECLARE FUNCTION SHGetPathFromIDList LIB "Shell32" ALIAS "SHGetPathFromIDList"_    ' changes result of API to string
                 (pidList AS LONG, lpBuffer AS STRING) AS LONG
DECLARE FUNCTION GetWindowRect1 LIB "User32" Alias "GetWindowRect"_                 ' for centering
                 (hWnd AS LONG, lpRect AS QRECT) AS LONG
DECLARE FUNCTION MoveWindow1 LIB "User32" ALIAS "MoveWindow"_                       ' same as above
                 (hWnd AS LONG, x AS LONG, y AS LONG,nWidth AS LONG,_
                  nHeight AS LONG, bRepaint AS LONG) AS LONG
DECLARE FUNCTION SetWindowText1 LIB "user32" ALIAS "SetWindowTextA"_                ' sets titlebar caption
                 (hWnd AS LONG, ByRef lpString AS STRING) AS LONG
                 
TYPE QBROWSEDIALOG EXTENDS QOBJECT
    WITH QBROWSEDIALOG
    
        Caption    AS STRING
        Title      AS STRING
        InitialDir AS STRING
        Directory  AS STRING
        X          AS STRING
        
        FUNCTION BrowseHook(hWnd AS LONG, uMsg AS LONG, lParam AS LONG, lpData AS LONG) AS LONG
            IF uMsg = BFFM_INITIALIZED THEN                           ' Dialog is done drawing
                DIM R AS QRECT
                GetWindowRect1(hWnd, R)
                MoveWindow1 (hWnd, (Screen.Width-(R.Right-R.Left))/2, (Screen.Height-(R.Bottom-R.Top))/2,_
                           (R.Right-R.Left), (R.Bottom-R.Top), 0)     ' center it
                SendMessage(hWnd, BFFM_SETSELECTIONA, 1, lpData)      ' set InitialDir
                IF LEN(.Caption) THEN                                 ' if caption, set it  
                    SetWindowText1(hWnd, .Caption)                     ' otherwise use default
                END IF                                                ' ("Browse for folder")
            END IF
        END FUNCTION
       
        FUNCTION Execute AS LONG
            DIM BI AS BROWSEINFO                                      ' DIM our structure
            DIM pidl AS LONG                                          ' result of API
            DIM sPath AS STRING*MAX_PATH                              ' result string
            DIM xPath AS STRING*MAX_PATH                              ' Virtual Folder result
            .InitialDir = .InitialDir + CHR$(0)                       ' add null terminator
            BI.hWndOwner = Application.Handle
            BI.pszDisplayName = VARPTR(xPath)
            BI.lpszTitle = VARPTR(This.Title)
            BI.lpfnCallback = CODEPTR(This.BrowseHook)
            BI.lParam = VARPTR(This.InitialDir)
            pidl = SHBrowseForFolder(BI)                                  ' do it!
            IF pidl THEN                                                  ' if API succeeds,
                IF SHGetPathFromIDList(pidl, sPath) THEN                  ' check for path string
                    .Directory = LEFT$(sPath, INSTR(sPath, CHR$(0))-1)    ' if yes, knock off null terminator
                ELSE                                                      ' or else
                    .Directory = LEFT$(xPath, INSTR(xPath, CHR$(0))-1)    ' get name string (Virual Folders)
                END IF
                CoTaskMemFree pidl                                        ' free memory 
                Result = 1                                                ' success!
            ELSE
                Result = 0                                                ' failure :(
            END IF
        END FUNCTION
    

        
    END WITH
END TYPE


