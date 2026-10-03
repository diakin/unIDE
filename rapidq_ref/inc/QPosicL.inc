' Based on Qspintext component for Rapid-Q by Mesut Akcan http://kaynak.cjb.net
' ver : 1.00
' 22.02.2004 
'http://www.diakin.narod.ru/RQDP/index.html - Rapid-Q documentation Project

'$typecheck on

declare sub OnChangePos (a as single)
defstr BmpPath ="C:\BAS\RAPIDQ\inc\"

type QPosicL extends qpanel

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
        with QposicL 
            .sbv.max=.minv * -1
            .sbv.min=.maxv * -1
            .sbv.parent=QposicL
            
            .sbh.max=.maxh '* -1
            .sbh.min=.minh '* -1
           .sbh.parent=QposicL


            .btn.parent=QposicL
            .btnUndo.parent=QposicL
            .btnRedo.parent=QposicL
            .btnAllUp.parent=QposicL
            .btnAllDn.parent=QposicL

        .sbv.kind=0

        .sbv.top=0 : 
        .sbv.left=.height/3'
        .sbv.width=.height/2+1
        .sbv.PageSize=1
        .sbv.height=.height/3+1'
        .sbv.Position=.valuev
        
        .sbh.kind=0

        .sbh.top=.height/3 
        .sbh.left=.height/3'
        .sbh.width=.height/2+1
        .sbh.PageSize=1
        .sbh.height=.height/3+1
        .sbh.Position=.valueh

        .btn.top=.height/3'
        .btn.left=.height/3'
        .btn.width=.height/3+2
        .btn.height=.height/3+1
        .btn.color=&H0070FF
        .btn.BMP  ="MaxFast.bmp"'' BmpPath+"reset.bmp"

        .btnUndo.top=0
        .btnUndo.left=0
        .btnUndo.width=.height/3
        .btnUndo.height=.height/3
        .btnUndo.color=&H0070FF
        .btnUndo.BMP  =BmpPath+ "Undo1.bmp"
        .btnUndo.Tag=101

        .btnRedo.top=.height/3*2+1
        .btnRedo.left=.height/3*2+2
        .btnRedo.width=.height/3-1
        .btnRedo.height=.height/3
        .btnRedo.color=&H0070FF
        .btnRedo.BMP  =BmpPath+ "Redo1.bmp"
        .btnRedo.Tag=102

        .btnAllUp.top=0
        .btnAllUp.left=.height/3*2+2
        .btnAllUp.width=.height/3-1
        .btnAllUp.height=.height/3
        .btnAllUp.color=&H0070FF
        .btnAllUp.BMP  =BmpPath+ "AllUp.bmp"
        .btnAllUp.Spacing=0
        .btnAllUp.Tag=103

        .btnAllDn.top=.height/3*2+1
        .btnAllDn.left=0
        .btnAllDn.width=.height/3
        .btnAllDn.height=.height/3
        .btnAllDn.color=&H0070FF
        .btnAllDn.BMP  =BmpPath+ "AllDn.bmp"
        .btnAllDn.Tag=104
 
        end with
    end sub


    event sbh.onchange
        with QposicL
          .valueh=.sbh.position
if .supress=0 then  CALLFUNC(.OnChange,1)
        end with
    end event

    event sbv.onchange
''        dim pv as short
        with QposicL
''            pv=.sbv.position  * -1
            .valuev=.sbv.position  * -1
if .supress=0 then CALLFUNC(.OnChange,1)
        end with
    end event

    event btn.onclick
          QposicL.valueh=1
          QposicL.valuev=1
          QposicL.sbh.position=1
          QposicL.sbv.position=1
        CALLFUNC (QposicL.OnChange, 1)
    end event


    event btnUndo.onclick
        CALLFUNC(QposicL.OnChange, 1)
    end event

    event btnRedo.onclick
        CALLFUNC(QposicL.OnChange,1)
    end event

    event btnAllDn.onclick
        QposicL.supress=1
        dec   QposicL.sbh.position
        QposicL.supress=0
        inc   QposicL.sbv.position
 
    end event

    event btnAllUp.onclick
''        QposicL.supress=1
''        inc   QposicL.sbh.position
''        QposicL.supress=0
''        dec   QposicL.sbv.position

    end event

    event btnAllUp.OnMouseDown
        QposicL.supress=1
        inc   QposicL.sbh.position
        QposicL.supress=0
        dec   QposicL.sbv.position

    end event
    
    constructor 
        width=100 : height=100
''      color=&HC694A4

        sbv.kind=1
        sbv.top=0 : 
        sbv.left=QposicL.height/3'
        sbv.width=QposicL.height/3+2
        sbv.PageSize=1
        sbv.height=QposicL.height'
        sbv.LargeChange=10

        sbh.kind=0
        sbh.top=QposicL.height/3 
        sbh.left=0
        sbh.width=QposicL.height+1
        sbh.PageSize=1
        sbh.height=QposicL.height/3+1
        sbh.LargeChange=10

        btn.top=QposicL.height/3'
        btn.left=QposicL.height/3'
        btn.width=QposicL.height/3+1
        btn.height=QposicL.height/3+1
        btn.color=&H0070FF
        btn.BMP  =BmpPath+ "reset.bmp"

        btnUndo.top=0
        btnUndo.left=0
        btnUndo.width=QposicL.height/3
        btnUndo.height=QposicL.height/3
        btnUndo.color=&H0070FF
        btnUndo.BMP  =BmpPath+ "Undo1.bmp"
        btnUndo.Tag=101

        btnRedo.top=QposicL.height/3*2+1
        btnRedo.left=QposicL.height/3*2+3
        btnRedo.width=QposicL.height/3-1
        btnRedo.height=QposicL.height/3
        btnRedo.color=&H0070FF
        btnRedo.BMP  =BmpPath+ "Redo1.bmp"
        btnRedo.Tag=102

        btnAllUp.top=0
        btnAllUp.left=QposicL.height/3*2+3
        btnAllUp.width=QposicL.height/3-1
        btnAllUp.height=QposicL.height/3
        btnAllUp.color=&H0070FF
        btnAllUp.BMP  =BmpPath+ "AllUp.bmp"
        btnAllUp.Spacing=0
        btnAllUp.Tag=103

        btnAllDn.top=QposicL.height/3*2+1
        btnAllDn.left=0
        btnAllDn.width=QposicL.height/3
        btnAllDn.height=QposicL.height/3
        btnAllDn.color=&H0070FF
        btnAllDn.BMP  =BmpPath+ "AllDn.bmp"
        btnAllDn.Tag=104

        bevelouter=1
    end constructor

    
end type  