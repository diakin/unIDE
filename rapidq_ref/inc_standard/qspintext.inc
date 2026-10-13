$IFNDEF __QSPINTEXT_INC   ' IncManager: include guard
$DEFINE __QSPINTEXT_INC
' Qspintext component for Rapid-Q by Mesut Akcan
' ver : 1.01
' 7 July 2000, update : 7 Sept. 2000 
' http://kaynak.cjb.net
' http://makcan.virtualave.net
' makcan@softhome.net
'$typecheck on
'-----------------
'Updated 20.04.04  Andrew Shelkovenko diakin@narod.ru
' OnChange event added



DECLARE SUB QspintextOnChange (vl AS long)

type Qspintext extends qpanel

OnChange AS EVENT (QspintextOnChange)
public:    
    max as long
    min as long
    value as long
    bgcolor as long
    fontcolor as long
    ed as qedit
    sb as qscrollbar

    sub initial
        with Qspintext 
            .sb.max=.min * -1
            .sb.min=.max * -1
            .sb.position=.value* -1
            .ed.text=str$(.value)
            .ed.parent=Qspintext
            .sb.parent=Qspintext

        .sb.kind=1
        .sb.width=18
        .sb.top=2 : 
        .sb.height=18 

        .ed.top=3
        .ed.left=2 
        .ed.height=16 : 
        .ed.borderstyle=0
        .ed.width=Qspintext.width - 22
       '' print "ed.width=",.ed.width

        .sb.left= .ed.width+.ed.left+2
        .ed.color=.bgcolor 'clBlue'.color
        .ed.font.color=.fontcolor
        end with
    end sub
    
''    event OnClick
''    CALLFUNC(Qspintext.OnChange,vl)
''    end event

    event sb.onchange
        dim p as long

        with Qspintext
            p=.sb.position * -1
            .value=p
            .ed.text=str$(.value)
            vl=p
''        Qspintext.ed.color=Qspintext.bgcolor '&H0000FF
'''        Qspintext.color=Qspintext.bgcolor '&H0000FF

            CALLFUNC(.OnChange,vl)
  
        end with
    end event
    
    event ed.onchange
''        Qspintext.sb.position=val(Qspintext.ed.text) * -1
''        vl=Qspintext.sb.position
''        CALLFUNC(Qspintext.OnChange1,vl)
    end event
    
    event ed.onkeydown (key as word, shift as integer)
        dim p as long
        p=Qspintext.sb.position

        if key=38 then 
        dec p : 
        Qspintext.sb.position = p  ' up
        Qspintext.ed.color=Qspintext.bgcolor '&H0000FF

        elseif key=40 then  
        inc p : 
        Qspintext.sb.position = p  ' dw
        vl=Qspintext.sb.position
        Qspintext.ed.color=Qspintext.bgcolor '&H0000FF
        Qspintext.color=Qspintext.bgcolor

        elseif key=13 then 
        Qspintext.sb.position=val(Qspintext.ed.text) * -1
        Qspintext.ed.color=Qspintext.bgcolor '&H0000FF
        Qspintext.color=Qspintext.bgcolor
        CALLFUNC(Qspintext.OnChange,vl)
        else
  ''      Qspintext.ed.color=&H0000FF
        Qspintext.color=&H0000FF
         end if


    
    end event
    
    constructor 
        'initial
        width=50 : height=22
        sb.kind=1
        sb.width=18
        sb.top=2 : 
        sb.height=18 

        ed.top=3
        ed.left=2 
        ed.height=16 : 
        ed.borderstyle=0
        ed.width=Qspintext.width - 22

        sb.left= Qspintext.ed.width+Qspintext.ed.left+2
        ed.color=-2147483648'Qspintext.bgcolor
        bgcolor=-2147483643'-2147483647'-2147483648
        fontcolor=0
        bevelouter=1

    end constructor


end type
$ENDIF   ' IncManager: __QSPINTEXT_INC
