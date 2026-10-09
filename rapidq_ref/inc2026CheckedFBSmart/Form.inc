
'API Gude Window Placement example, adapted to RapidQ Basic
'Andrew Shelkovenko diakin@narod.ru 16.09.2004

' ShowWindow() Commands
Const SW_HIDE = 0
Const SW_SHOWNORMAL = 1
Const SW_NORMAL = 1
Const SW_SHOWMINIMIZED = 2
Const SW_SHOWMAXIMIZED = 3
Const SW_MAXIMIZE = 3
Const SW_SHOWNOACTIVATE = 4
Const SW_SHOW = 5
Const SW_MINIMIZE = 6
Const SW_SHOWMINNOACTIVE = 7
Const SW_SHOWNA = 8
Const SW_RESTORE = 9
Const SW_SHOWDEFAULT = 10
Const SW_MAX = 10

Public Const WPF_SETMINPOSITION = &H1
Public Const WPF_RESTORETOMAXIMIZED = &H2

const Form_wsMinimized=1

Private Type POINTAPI
        x As Long
        y As Long
End Type
Private Type RECT
        Left As Long
        Top As Long
        Right As Long
        Bottom As Long
End Type
Private Type WINDOWPLACEMENT
        Length As Long
        flags As Long
        showCmd As Long
        '-ptMinPosition As POINTAPI
         ptMinPosition_X As Long
         ptMinPosition_Y As Long

        '-ptMaxPosition As POINTAPI
         ptMaxPosition_X As Long
         ptMaxPosition_Y As Long

        '-rcNormalPosition As RECT
         rcNormalPosition_Left As Long     
         rcNormalPosition_Top As Long      
         rcNormalPosition_Right As Long    
         rcNormalPosition_Bottom As Long   
End Type

Private Declare Function GetWindowPlacement Lib "user32" Alias "GetWindowPlacement" _
 (ByVal hwnd As Long, lpwndpl As WINDOWPLACEMENT) As Long
Private Declare Function SetWindowPlacement Lib "user32" Alias "SetWindowPlacement" _
(ByVal hwnd As Long, lpwndpl As WINDOWPLACEMENT) As Long

Dim Rectan As RECT

dim      MinLeft As Long
dim      MinTop As Long

'-- ***********************************************************************'
Sub SetFormPos(hwnd as long, SetX as long, SetY as long)
    Dim WinEst As WINDOWPLACEMENT
    'Dim Punto As POINTAPI
    Dim rtn As Long
    'set the new min/max positions
    'Punto.x = 100'200
    'Punto.y = 100
    'initialize the structure
    WinEst.flags =WPF_SETMINPOSITION
    WinEst.Length = SIZEOF(WinEst)
    WinEst.showCmd =SW_MINIMIZE 'SW_RESTORE'SW_SHOWMINIMIZED'SW_HIDE'' SW_MINIMIZE
    WinEst.ptMinPosition_X =SetX' Punto.X 'set new MINIMIZED position'
    WinEst.ptMinPosition_Y =SetY' Punto.Y
    
    '- WinEst.rcNormalPosition = Rectan
     WinEst.rcNormalPosition_Left    =  Rectan.Left  '200'' set new normal position
     WinEst.rcNormalPosition_Top     =  Rectan.Top  '200'' 
     WinEst.rcNormalPosition_Right   =  Rectan.Right '250 ''
     WinEst.rcNormalPosition_Bottom  =  Rectan.Bottom'250'' 
    
    'set the new window placement (minimized)
    rtn = SetWindowPlacement(hwnd, WinEst) 
End Sub

'-- ***********************************************************************'
Sub GetFormPos (Sender as QForm)
    'Tip submitted by pyp99 (pyp99@hotmail.com)
    Dim WinEst As WINDOWPLACEMENT
    Dim rtn As Long
    WinEst.Length = SIZEOF(WinEst)
    'get the current window placement
    rtn = GetWindowPlacement(Sender.handle, WinEst)   
    'print "rtn=" ,rtn


    '-Rectan = WinEst.rcNormalPosition
    Rectan.Left = WinEst.rcNormalPosition_Left  
    Rectan.Top= WinEst.rcNormalPosition_Top  
    Rectan.Right= WinEst.rcNormalPosition_Right 
    Rectan.Bottom= WinEst.rcNormalPosition_Bottom 

   MinTop= WinEst.ptMinPosition_Y
   MinLeft=WinEst.ptMinPosition_X

    'print "Rectan.Right=" ,Rectan.Right
    'print "Rectan.Top=" ,Rectan.Top
    'print "Rectan.Bottom=" ,Rectan.Bottom
    
End Sub
 