'=======================================================
' Type Objet
' Classe QFormEx
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

const WM_DROPFILES=&H233
const GWL_HWNDPARENT=-8
const GWL_WNDPROC=-4
const HWND_DESKTOP=0

const NIM_ADD=0
const NIM_DELETE=2
const NIM_MESSAGE=1
const NIM_ICON=2
const NIM_TIP=4
const WM_TRAYICON=&H590
const WM_LBUTTONDBLCLK=&H203
const WM_RBUTTONUP=&H205
const WM_SYSCOMMAND=&H112
const SC_MINIMIZE=61472


TYPE TPOINT
  X AS LONG
  Y AS LONG
END TYPE


Declare Function CallWindowProc Lib "user32.dll" Alias "CallWindowProcA" (lpPrevWndFunc As Long, hwnd As Long, Msg As Long, wParam As Long, lParam As Long) As Long
Declare Function SetWindowLong Lib "user32" Alias "SetWindowLongA" (hwnd As Long,nIndex As Long,dwNewLong As Long) As Long
DECLARE SUB DragAcceptFiles LIB "SHELL32" ALIAS "DragAcceptFiles" (hWnd AS LONG,Accept AS LONG)
DECLARE SUB DragFinish LIB "SHELL32" ALIAS "DragFinish" (hDrop AS LONG)
DECLARE FUNCTION DragQueryFile LIB "SHELL32" ALIAS "DragQueryFileA" (hDrop AS LONG,iFile AS LONG,lpszFile AS LONG,cch AS LONG) AS LONG
DECLARE FUNCTION DragQueryPoint LIB "SHELL32" ALIAS "DragQueryPoint" (hDrop AS LONG,lppt AS TPOINT) AS LONG
DECLARE SUB Shell_NotifyIcon LIB "shell32" ALIAS "Shell_NotifyIconA" (dwMessage AS LONG,niData AS QNOTIFYICONDATA)

Declare Sub OnDrag_eventTemplate(file as string)
Declare Sub OnTrayClick_eventTemplate
Declare Sub OnTrayDblClick_eventTemplate
Declare Sub OnMinimise_eventTemplate

Type QFormEx extends QFORM
  PRIVATE:
    TrayIcon as QNOTIFYICONDATA
    pOldProc AS LONG
    flagWinProc as boolean
    flagTrayIcon as boolean
  PUBLIC:
    DragZone as QRect
    DragEnable as boolean PROPERTY SET SetDragEnable
    DeskBar as boolean PROPERTY SET SetDeskBar
    OnDrag as EVENT(OnDrag_eventTemplate)
    OnTrayClick as EVENT(OnTrayClick_eventTemplate)
    OnTrayDblClick as EVENT(OnTrayDblClick_eventTemplate)
    OnMinimise as EVENT(OnMinimise_eventTemplate)

  PRIVATE:
  '============================================
  ' Procédure winproc de la fenetre
  '============================================
  FUNCTION WindowProc (hwnd AS LONG, uMsg AS LONG, wParam AS LONG, lParam AS LONG) AS LONG
    dim Point AS TPOINT
    dim i as integer
    dim File as string    
    dim Count as integer
    dim Length as integer

   SELECT CASE uMsg
     CASE WM_DROPFILES
       DragQueryPoint(wParam,Point)
       if Point.X >= QFormEx.DragZone.Left AND Point.Y >= QFormEx.DragZone.Top and _
          Point.X < QFormEx.DragZone.Right AND Point.Y < QFormEx.DragZone.Bottom then
           Count=DragQueryFile(wParam,&HFFFFFFFF,VARPTR(File),0)
           FOR i=0 to Count-1
              Length=DragQueryFile(wParam,i,0,0)
              File=space$(Length+1)
              DragQueryFile(wParam,i,VARPTR(File),Length+1)
              if QFormEx.OnDrag<>0 then CALLFUNC(QFormEx.OnDrag,File)
           next
       end if
       DragFinish(wParam)
     CASE WM_SYSCOMMAND
        IF wParam=SC_MINIMIZE and QFormEx.flagTrayIcon=true THEN
          if QFormEx.OnMinimise<>0 then CALLFUNC QFormEx.OnMinimise
        else
          QFormEx.WindowProc=CallWindowProc(QFormEx.pOldProc,hwnd,uMsg,wParam,lParam)
        End if
     CASE WM_TRAYICON
      IF uMsg=WM_TRAYICON THEN
        IF (lParam AND &HFFFF)=WM_RBUTTONUP THEN
          if QFormEx.OnTrayClick<>0 then CALLFUNC QFormEx.OnTrayClick
        ELSEIF (lParam AND &HFFFF)=WM_LBUTTONDBLCLK THEN
          if QFormEx.OnTrayDblClick<>0 then CALLFUNC QFormEx.OnTrayDblClick
        END IF
      END IF
     CASE ELSE
       QFormEx.WindowProc=CallWindowProc(QFormEx.pOldProc,hwnd,uMsg,wParam,lParam)
     END SELECT
  End Function

  PUBLIC:
  '============================================
  ' Proprieté Acceptation de dépose fichier
  '============================================
  PROPERTY SET SetDragEnable(flag as boolean)
    DragAcceptFiles(QFormEx.Handle,flag)
    if QFormEx.flagWinProc=false then
      QFormEx.pOldProc=SetWindowLong(QFormEx.handle,GWL_WNDPROC,CODEPTR(QFormEx.WindowProc))
      QFormEx.flagWinProc=true
    end if
  END PROPERTY

  '=============================================================================
  ' Proprieté Application dans barre outil bureau lors de la reduction fenetre
  '=============================================================================
  PROPERTY SET SetDeskBar(flag as boolean)
    if flag then
      setwindowlong(QFormEx.handle,GWL_HWNDPARENT,HWND_DESKTOP)
      setwindowlong(application.handle,GWL_HWNDPARENT,QFormEx.handle)
    end if
  END PROPERTY

  '=============================================
  ' Méthode AddTrayIcon
  '=============================================
  Sub AddTrayIcon
    QFormEx.TrayIcon.hWnd=QFormEx.Handle
    QFormEx.TrayIcon.uID=Application.hInstance
    QFormEx.TrayIcon.uFlags=NIM_MESSAGE OR NIM_ICON OR NIM_TIP
    QFormEx.TrayIcon.uCallBackMessage=WM_TRAYICON
    QFormEx.TrayIcon.hIcon=Application.Icon
    QFormEx.TrayIcon.szTip=Application.Title+CHR$(0)
    Shell_NotifyIcon(NIM_ADD,QFormEx.TrayIcon)
    if QFormEx.flagWinProc=false then
      QFormEx.pOldProc=SetWindowLong(QFormEx.handle,GWL_WNDPROC,CODEPTR(QFormEx.WindowProc))
      QFormEx.flagWinProc=true
    end if
    QFormEx.flagTrayIcon=true
  End Sub

  '=============================================
  ' Méthode DelTrayIcon
  '=============================================
  Sub DelTrayIcon
    Shell_NotifyIcon(NIM_DELETE,QFormEx.TrayIcon)
    QFormEx.flagTrayIcon=false
  End Sub
End Type


      