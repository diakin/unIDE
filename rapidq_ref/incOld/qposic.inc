' Based on Qspintext component for Rapid-Q by Mesut Akcan http://kaynak.cjb.net
' ver : 1.00
' 22.02.2004 
'http://www.diakin.narod.ru/RQDP/index.html - Rapid-Q documentation Project

$typecheck on

declare sub OnChangePos (a as single)

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
        width=80 : height=80
''      color=&HC694A4

        sbv.kind=1
        sbv.top=0 : 
        sbv.left=16
        sbv.width=18
        sbv.PageSize=1
        sbv.height=49

        sbh.kind=0
        sbh.top=16 : 
        sbh.left=0
        sbh.width=50
        sbh.PageSize=1
        sbh.height=17

        btn.top=16
        btn.left=16
        btn.width=17
        btn.height=17
        btn.color=&H0070FF
        btn.BMP  = "reset.bmp"

        btnUndo.top=0
        btnUndo.left=0
        btnUndo.width=16
        btnUndo.height=16
        btnUndo.color=&H0070FF
        btnUndo.BMP  = "Undo1.bmp"
        btnUndo.Tag=101

        btnRedo.top=33
        btnRedo.left=35
        btnRedo.width=15
        btnRedo.height=16
        btnRedo.color=&H0070FF
        btnRedo.BMP  = "Redo1.bmp"
        btnRedo.Tag=102

        btnAllUp.top=0
        btnAllUp.left=35
        btnAllUp.width=15
        btnAllUp.height=16
        btnAllUp.color=&H0070FF
        btnAllUp.BMP  = "AllUp.bmp"
        btnAllUp.Spacing=0
        btnAllUp.Tag=103

        btnAllDn.top=33
        btnAllDn.left=0
        btnAllDn.width=16
        btnAllDn.height=16
        btnAllDn.color=&H0070FF
        btnAllDn.BMP  = "AllDn.bmp"
        btnAllDn.Tag=104

        bevelouter=1
    end constructor

    
end type  