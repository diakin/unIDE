' Qspintext component for Rapid-Q by Mesut Akcan
' ver : 1.01
' 7 July 2000, update : 7 Sept. 2000 
' http://kaynak.cjb.net
' http://makcan.virtualave.net
' makcan@softhome.net
'$typecheck on


DECLARE SUB QspintextOnChange (vl AS short)

type Qspintext extends qpanel

OnChange1 AS EVENT (QspintextOnChange)
    
    max as short
    min as short
    value as short
    ed as qedit
    sb as qscrollbar

    sub initial
        with Qspintext 
            .sb.max=.min * -1
            .sb.min=.max * -1
            .ed.text=str$(.value)
            .ed.parent=Qspintext
            .sb.parent=Qspintext
        end with
    end sub
    
    constructor 
        width=50 : height=22
        sb.kind=1
        sb.width=18
        sb.top=2 : ed.top=3
        ed.left=2 
        ed.height=16 : sb.height=18 
        sb.left=Qspintext.width - 20
        ed.borderstyle=0
        ed.width=Qspintext.width - 22
        bevelouter=1

    end constructor
    event OnClick
    CALLFUNC(.OnChange1,vl)
    end event

    event sb.onchange
        dim p as short

        with Qspintext
            p=.sb.position * -1
            .ed.text=str$(p)
            .value=p
            vl=p
    ''        CALLFUNC(.OnChange1,vl)
  
        end with
    end event
    
    event ed.onchange
        Qspintext.sb.position=val(Qspintext.ed.text) * -1
        vl=Qspintext.sb.position
''        CALLFUNC(.OnChange1,vl)

    end event
    
    event ed.onkeydown (key as word, shift as integer)
        dim p as short
        p=Qspintext.sb.position
        if key=38 then p--  ' up
        if key=40 then p++  ' dw
        Qspintext.sb.position = p
        vl=Qspintext.sb.position
 ''       CALLFUNC(.OnChange1,vl)

    end event


end type