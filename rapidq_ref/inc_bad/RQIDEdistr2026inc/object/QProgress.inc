'=======================================================
' Type Objet
' Classe QProgress
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

CONST PG_CHILD=&H40000000
CONST PG_VISIBLE=&H10000000
Const PG_USER=&H400
Const PBM_SETRANGE=PG_USER + 1
Const PBM_SETPOS=PG_USER + 2
Const PBM_SETSTEP=PG_USER + 4
 
DECLARE FUNCTION CreateBar LIB "USER32" ALIAS "CreateWindowExA" (ExStyle&,ClassName$,WindowName$,Style&,X&,Y&,Width&,Height&,WndParent&,hMenu&,hInstance&,Param&) AS LONG
Declare Function MoveBar Lib "user32" Alias "MoveWindow" (hwnd As Long,x As integer,y As integer,nWidth As integer,nHeight As integer,bRepaint As Long) As Long
Declare Function ShowBar Lib "user32" Alias "ShowWindow" (hwnd As Long,nCmdShow As Long) As Long

Type QProgress EXTENDS QOBJECT
    PRIVATE:
      Range As Long
      Increment As Long
      resolution as integer
    PUBLIC:
      Parent as integer PROPERTY SET SetParent
      value as long PROPERTY SET SetValue
      left as short PROPERTY SET SetLeft
      Top as short PROPERTY SET SetTop
      Width as short PROPERTY SET SetWidth
      Height as short PROPERTY SET SetHeight
      Visible as boolean PROPERTY SET SetVisible
      Handle as integer
    
    PROPERTY SET SetVisible(visible as boolean)
      QProgress.visible=visible
      if visible=0 then
        ShowBar(QProgress.Handle,0)
      else
        ShowBar(QProgress.Handle,5)
      end if
    END PROPERTY

    PROPERTY SET SetLeft(left as short)
      QProgress.Left=left
      MoveBar(QProgress.Handle,QProgress.Left,QProgress.Top,QProgress.Width,QProgress.Height,true)
    END PROPERTY

    PROPERTY SET SetTop(top as short)
      QProgress.Top=top
      MoveBar(QProgress.Handle,QProgress.Left,QProgress.Top,QProgress.Width,QProgress.Height,true)
    END PROPERTY

    PROPERTY SET SetWidth(width as short)
      QProgress.Width=width
      MoveBar(QProgress.Handle,QProgress.Left,QProgress.Top,QProgress.Width,QProgress.Height,true)
    END PROPERTY

    PROPERTY SET SetHeight(height as short)
      QProgress.Height=height
      MoveBar(QProgress.Handle,QProgress.Left,QProgress.Top,QProgress.Width,QProgress.Height,true)
    END PROPERTY
            
    PROPERTY SET SetParent(parent as integer)
      QProgress.Parent = parent
      'QProgress.Handle = CreateBar(0,"msctls_progress32","",PG_CHILD Or PG_VISIBLE,QProgress.left,QProgress.top,QProgress.width,QProgress.height,QProgress.Parent,0,Application.hInstance,0)
      QProgress.Handle = CreateBar(0,"msctls_progress32","",PG_CHILD Or PG_VISIBLE,QProgress.left,QProgress.top,QProgress.width,QProgress.height,QProgress.Parent,0,0,0)
      QProgress.visible=1
      'Set the range of the progress bar.
      '(Minimum range = low word, Maximum range = high word).
      QProgress.Range = &H5014
      SendMessage(QProgress.Handle, PBM_SETRANGE, 0, QProgress.Range * &H10000)
      'Set the value of the highlight increment.
      QProgress.Increment = QProgress.Range/100
      SendMessage(QProgress.Handle, PBM_SETSTEP, QProgress.Increment, 0)
      QProgress.resolution=QProgress.Range/100
    END PROPERTY

    PROPERTY SET SetValue(value as long)
      QProgress.value =value*QProgress.resolution
     'Set ProgressBar every Time this Sub Is called
      SendMessage(QProgress.Handle,PBM_SETPOS,QProgress.value,0) 
    END PROPERTY
    
    CONSTRUCTOR
    Left=0
    Top=0
    Width=100
    Height=20
    END CONSTRUCTOR
End Type

