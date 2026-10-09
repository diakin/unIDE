'=======================================================
' Type Objet
' Classe QRun Version 1.1
'=======================================================
$IFNDEF TRUE
  $DEFINE True 1
$ENDIF

$IFNDEF FALSE
  $DEFINE False 0
$ENDIF

$IFNDEF boolean
  $DEFINE boolean integer
$ENDIF

$IFNDEF __WIN32API

Declare Function Run_FindExecutable Lib "shell32.dll" Alias "FindExecutableA" (lpFile As String,lpDirectory As String, ByRef lpResult As String) As Long
Declare Function Run_ShellExecute Lib "shell32.dll" Alias "ShellExecuteA" (hwnd As Long,lpOperation As String,lpFile As String,lpParameters As String,lpDirectory As String,nShowCmd As Long) As Long
Declare Function Run_GetTextLenght Lib "user32" Alias "GetWindowTextLengthA" (hwnd As Long) As Long
Declare Function Run_GetText LIB "User32" Alias "GetWindowTextA" (hwnd As Long,ByRef lpString As String,cch As Long) As Long
Declare Function Run_GetClassName Lib "User32" Alias "GetClassNameA" (hwnd As Long,ByRef lpClassName As String,nMaxCount As Long) As Long
Declare Function Run_IsWindowVisible LIB "user32" Alias "IsWindowVisible" (hwnd As Long) As Long
Declare Function Run_GetDesktopWindow Lib "user32" Alias "GetDesktopWindow" () As Long
Declare Function Run_GetWindow Lib "user32" Alias "GetWindow" (hwnd As Long,wCmd As Long) As Long
Declare Function Run_FindWindowEx Lib "user32" Alias "FindWindowExA" (hWnd1 As Long,hWnd2 As Long,lpsz1 As String,lpsz2 As String) As Long
Declare Function Run_WindowFromPoint Lib "user32" Alias "WindowFromPoint" (xPoint As long,yPoint As long) As Long
Declare Function Run_SetWindowPos Lib "user32" Alias "SetWindowPos" (hwnd As Long,hWndInsertAfter As Long,x As Long,y As Long,cx As Long,cy As Long,wFlags As Long) As Long


' ShowWindow() Commands
$DEFINE SW_HIDE      0
$DEFINE SW_SHOWNORMAL      1
$DEFINE SW_NORMAL      1
$DEFINE SW_SHOWMINIMIZED      2
$DEFINE SW_SHOWMAXIMIZED      3
$DEFINE SW_MAXIMIZE      3
$DEFINE SW_SHOWNOACTIVATE      4
$DEFINE SW_SHOW      5
$DEFINE SW_MINIMIZE      6
$DEFINE SW_SHOWMINNOACTIVE      7
$DEFINE SW_SHOWNA      8
$DEFINE SW_RESTORE      9
$DEFINE SW_SHOWDEFAULT      10
$DEFINE SW_MAX      10

$ENDIF

$DEFINE RUN_HWNDNEXT      2
$DEFINE RUN_CHILD      5

Declare Sub OnEnumWindows_eventTemplate(handle as Long,name as string,ClassName as string)
Declare Sub OnEnumFromPoint_eventTemplate(handle as Long,name as string,ClassName as string)

Type QRun EXTENDS QObject
  OnEnumWindows as EVENT(OnEnumWindows_eventTemplate)
  OnEnumFromPoint as EVENT(OnEnumWindows_eventTemplate)

  '=============================================================
  ' Méthode trouvant le nom et chemin de l'application associé
  '=============================================================
  Function FindApplication(FileName as string) as string
    dim ExeName as string
    dim value as long
    
    ExeName=space$(255)
    value=Run_FindExecutable(FileName,"",ExeName)
    if value>32 then
      result=rtrim$(ExeName)
    else
      result=""
    end if
  End Function
  
  '=============================================================
  ' Méthode éxecution d'un fichier associé ou application
  '=============================================================
  Sub FileRun(FileName as string,cmdShow as short)
    Run_ShellExecute(0,"open",FileName,"","",cmdShow)
  End Sub
  
  '=============================================================
  ' Méthode éxecution application avec ouverture fichier
  '=============================================================
  Sub ExeRun(ExeName as string,Param as string,cmdShow as short)
    dim path as string
    
    path=LEFT$(ExeName,RINSTR(ExeName,"\")-1)
    Run_ShellExecute(0,"open",ExeName,Param,path,cmdShow)
  End Sub
  
  '=============================================================
  ' Méthode énumeration de toutes les fenetres de l'ecran
  '=============================================================
  Function EnumWindow(All as boolean) as boolean
    dim size as integer
    dim buffer as string
    dim name as string
    dim ClassName as string
    dim handle as long

    handle=Run_GetWindow(Run_GetDesktopWindow(),RUN_CHILD)
    result=handle<>0
    while handle<>0 
      if All or Run_IsWindowVisible(handle) then
        size=Run_GetTextLenght(handle)
        buffer=Space$(size)+chr$(0)
        size=Run_GetText(handle,buffer,Len(buffer))
        name=Left$(buffer,size)
        if name<>"" then
          buffer=Space$(255)
          size=Run_GetClassName(handle,buffer,255)
          if size>0 then
            ClassName=Left$(buffer,size)
          else
            ClassName=""
          end if
          if this.OnEnumWindows<>0 then CALLFUNC(this.OnEnumWindows,handle,name,ClassName)
        end if
      end if
      handle=Run_GetWindow(handle,RUN_HWNDNEXT)
    wend 
  End Function

  '=============================================================
  ' Méthode trouve le handle enfant par son nom et sa classe
  '=============================================================
  Function FindChild(handle as long,class as string,name as string) as long
    result=Run_FindWindowEx(handle,0,class,name)
  End Function

  '=============================================================
  ' Méthode énumeration de la fenetre a la position x,y
  '=============================================================
  Function EnumFromPoint(x as long,y as long) as boolean
    dim size as integer
    dim buffer as string
    dim name as string
    dim ClassName as string
    dim handle as long

    handle=Run_WindowFromPoint(x,y)
    result=handle<>0
    size=Run_GetTextLenght(handle)
    buffer=Space$(size)+chr$(0)
    size=Run_GetText(handle,buffer,Len(buffer))
    name=Left$(buffer,size)
    if name<>"" then
      buffer=Space$(255)
      size=Run_GetClassName(handle,buffer,255)
      if size>0 then
        ClassName=Left$(buffer,size)
      else
        ClassName=""
      end if
      if this.OnEnumFromPoint<>0 then CALLFUNC(this.OnEnumFromPoint,handle,name,ClassName)
    end if
  End Function

  '=============================================================
  ' Méthode fermeture fenetre
  '=============================================================
  Sub Close(handle as long)
    SendMessage handle,&H10,0,0
  End Sub

  '=============================================================
  ' Méthode met la fenetre en icone
  '=============================================================
  Sub Minimize(handle as long)
    SendMessage handle,&H112,&HF020,0
  End Sub

  '=============================================================
  ' Méthode met la fenetre en taille maxi
  '=============================================================
  Sub Maximize(handle as long)
    SendMessage handle,&H112,&HF030,0
  End Sub

  '=============================================================
  ' Méthode restore l'etat de la fenetre
  '=============================================================
  Sub Restore(handle as long)
    SendMessage handle,&H112,&HF120,0
  End Sub

  '=============================================================
  ' Méthode met le focus sur la fenetre
  '=============================================================
  Sub SetFocus(handle as long)
    SendMessage handle,&H7,0,0
  End Sub

  '=============================================================
  ' Méthode met la fenetre en avant plan des autres
  '=============================================================
  Sub SetTopMost(handle as long,flag as boolean)
    dim index as integer

    if flag then
      index=-1
    else
      index=-2
    end if
    Run_SetWindowPos Handle,index,0,0,0,0,&H3 
  End Sub
End Type
