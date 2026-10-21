' test.bas : qspintext component test program
' Mesut Akcan

$apptype gui
'$typecheck on
$option level 3

$include "qspintext2.inc"

declare sub frm_click (a as short)

create form as qform
    create label1 as qlabel
        caption = "Number (-10 to 125):" 
        top = 10
    end create
    create stx as Qspintext
        left = 100
        top  = 8
        max  = 125
        min  = - 10
        value= - 3
''        initial
        OnChange1=frm_click
    end create
''    onclick = frm_click
end create

form.showmodal

sub frm_click (a as short)
    showmessage "Qspintext.value=" + str$(stx.value)
end sub
