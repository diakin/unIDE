' Based on Qspintext component for Rapid-Q by Mesut Akcan http://kaynak.cjb.net
' ver : 1.00
' 22.02.2004 
'http://www.diakin.narod.ru/RQDP/index.html - Rapid-Q documentation Project

'$typecheck on

declare sub OnChangePos (a as single)

$RESOURCE reset AS "C:\_F\bas\rapidq\RQIDE\inc\reset.bmp"   'full path for using $RESOURCE  
$RESOURCE Undo1 AS "C:\_F\bas\rapidq\RQIDE\inc\Undo1.bmp"   ' C:\_F\bas\rapidq\RQIDE\inc\reset.bmp 
$RESOURCE Redo1 AS "C:\_F\bas\rapidq\RQIDE\inc\Redo1.bmp"   
$RESOURCE AllUp AS "C:\_F\bas\rapidq\RQIDE\inc\AllUp.bmp"   
$RESOURCE AllDn AS "C:\_F\bas\rapidq\RQIDE\inc\AllDn.bmp"   

type Qposic extends qpanel

OnChange AS EVENT (OnChangePos)

  PRIVATE:
    sbv as qscrollbar
    sbh as qscrollbar
    
    btn as qbutton'qovalbtn

    btnUndo as qbutton'qovalbtn
    btnRedo as qbutton'qovalbtn
    btnAllUp as qbutton'qovalbtn
    btnAllDn as qbutton'qovalbtn

    supress as integer
  PUBLIC:
''    UsePopup AS boolean PROPERTY SET Set_Popup

    maxv as short 
    minv as short
    valuev as short

    maxh as short
    minh as short
    valueh as short
    
''    height as short
''    width as short

    sub initial
        with Qposic 
            .sbv.max=.minv * -1
            .sbv.min=.maxv * -1
            .sbv.parent=Qposic
            
            .sbh.max=.maxh '* -1
            .sbh.min=.minh '* -1
            .sbh.parent=Qposic

            .btn.parent=Qposic
            .btnUndo.parent=Qposic
            .btnRedo.parent=Qposic
            .btnAllUp.parent=Qposic
            .btnAllDn.parent=Qposic
        .sbv.kind=1
        .sbv.top=0 : 
        .sbv.left=Qposic.height/3'
        .sbv.width=Qposic.height/3+2
        .sbv.PageSize=1
        .sbv.height=Qposic.height'

        .sbh.kind=0
        .sbh.top=Qposic.height/3 
        .sbh.left=0
        .sbh.width=Qposic.height+1
        .sbh.PageSize=1
        .sbh.height=Qposic.height/3+1

        .btn.top=Qposic.height/3'
        .btn.left=Qposic.height/3'
        .btn.width=Qposic.height/3+2
        .btn.height=Qposic.height/3+1
        .btn.color=&H0070FF
        .btn.bmpHandle = reset

        .btnUndo.top=0
        .btnUndo.left=0
        .btnUndo.width=Qposic.height/3
        .btnUndo.height=Qposic.height/3
        .btnUndo.color=&H0070FF
''        .btnUndo.BMP  = "Undo1.bmp"
        .btnUndo.bmpHandle = Undo1

        .btnUndo.Tag=101

        .btnRedo.top=Qposic.height/3*2+1
        .btnRedo.left=Qposic.height/3*2+2
        .btnRedo.width=Qposic.height/3-1
        .btnRedo.height=Qposic.height/3
        .btnRedo.color=&H0070FF
''        .btnRedo.BMP  = "Redo1.bmp"
        .btnRedo.bmpHandle = Redo1
        .btnRedo.Tag=102

        .btnAllUp.top=0
        .btnAllUp.left=Qposic.height/3*2+2
        .btnAllUp.width=Qposic.height/3-1
        .btnAllUp.height=Qposic.height/3
        .btnAllUp.color=&H0070FF
        .btnAllUp.bmpHandle = AllUp
''        .btnAllUp.BMP  = "AllUp.bmp"
        .btnAllUp.Spacing=0
        .btnAllUp.Tag=103

        .btnAllDn.top=Qposic.height/3*2+1
        .btnAllDn.left=0
        .btnAllDn.width=Qposic.height/3
        .btnAllDn.height=Qposic.height/3
        .btnAllDn.color=&H0070FF
        .btnAllDn.bmpHandle = AllDn
''        .btnAllDn.BMP  = "AllDn.bmp"
        .btnAllDn.Tag=104
 
        end with
    end sub


    event sbh.onchange
        with Qposic
          .valueh=.sbh.position
if .supress=0 then  CALLFUNC(.OnChange,1)
        end with
    end event

    event sbv.onchange
''        dim pv as short
        with Qposic
''            pv=.sbv.position  * -1
            .valuev=.sbv.position  * -1
if .supress=0 then CALLFUNC(.OnChange,1)
        end with
    end event

    event btn.onclick
          Qposic.valueh=1
          Qposic.valuev=1
          Qposic.sbh.position=1
          Qposic.sbv.position=1
        CALLFUNC (Qposic.OnChange, 1)
    end event


    event btnUndo.onclick
        CALLFUNC(Qposic.OnChange, 1)
    end event

    event btnRedo.onclick
        CALLFUNC(Qposic.OnChange,1)
    end event

    event btnAllDn.onclick
        Qposic.supress=1
        dec   Qposic.sbh.position
        Qposic.supress=0
        inc   Qposic.sbv.position
 
    end event

    event btnAllUp.onclick
''        Qposic.supress=1
''        inc   Qposic.sbh.position
''        Qposic.supress=0
''        dec   Qposic.sbv.position

    end event

    event btnAllUp.OnMouseDown
        Qposic.supress=1
        inc   Qposic.sbh.position
        Qposic.supress=0
        dec   Qposic.sbv.position

    end event
    
    constructor 

        
        width=100 : height=100
''      color=&HC694A4

        sbv.kind=1
        sbv.top=0 : 
        sbv.left=Qposic.height/3'
        sbv.width=Qposic.height/3+2
        sbv.PageSize=1
        sbv.height=Qposic.height'
        sbv.LargeChange=10

        sbh.kind=0
        sbh.top=Qposic.height/3 
        sbh.left=0
        sbh.width=Qposic.height+1
        sbh.PageSize=1
        sbh.height=Qposic.height/3+1
        sbh.LargeChange=10

        btn.top=Qposic.height/3'
        btn.left=Qposic.height/3'
        btn.width=Qposic.height/3+1
        btn.height=Qposic.height/3+1
        btn.color=&H0070FF
''        btn.BMP  = "reset.bmp"
        btn.bmpHandle = reset

        btnUndo.top=0
        btnUndo.left=0
        btnUndo.width=Qposic.height/3
        btnUndo.height=Qposic.height/3
        btnUndo.color=&H0070FF
''        btnUndo.BMP  = "Undo1.bmp"
        btnUndo.bmpHandle = Undo1
        btnUndo.Tag=101

        btnRedo.top=Qposic.height/3*2+1
        btnRedo.left=Qposic.height/3*2+3
        btnRedo.width=Qposic.height/3-1
        btnRedo.height=Qposic.height/3
        btnRedo.color=&H0070FF
''        btnRedo.BMP  = "Redo1.bmp"
        btnRedo.bmpHandle = Redo1
        btnRedo.Tag=102

        btnAllUp.top=0
        btnAllUp.left=Qposic.height/3*2+3
        btnAllUp.width=Qposic.height/3-1
        btnAllUp.height=Qposic.height/3
        btnAllUp.color=&H0070FF
''        btnAllUp.BMP  = "AllUp.bmp"
       btnAllUp.bmpHandle = AllUp

        btnAllUp.Spacing=0
        btnAllUp.Tag=103

        btnAllDn.top=Qposic.height/3*2+1
        btnAllDn.left=0
        btnAllDn.width=Qposic.height/3
        btnAllDn.height=Qposic.height/3
        btnAllDn.color=&H0070FF
''        btnAllDn.BMP  = "AllDn.bmp"
        btnAllDn.bmpHandle = AllDn

        btnAllDn.Tag=104

        bevelouter=1
    end constructor

    
end type  