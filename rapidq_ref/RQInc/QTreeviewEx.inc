$typecheck on
$include "fileops.inc"

type QtreeviewEx extends Qtreeview

function getparent (i as integer) as integer
Dim startlevel as integer
startlevel = QtreeviewEx.item(i).level
if startlevel = 0 then result = -1
if i = -1 then result = i
do
if QtreeviewEx.item(i).level < startlevel then Exit do
dec(i)
loop until i = -1
result = i
end function
'_______________________________________________________________________________
function getindex(from as integer, itemtext as string) as integer
dim i as integer
i = From
do
if QtreeviewEx.item(i).text = itemtext then exit do
inc(i)
loop until i = QtreeviewEx.itemcount
if i = QtreeviewEx.itemcount then i = -1
result = i
end function
'_______________________________________________________________________________
function strgetparent(itemtext as string) as integer
dim i as integer
with QtreeviewEx
     i = .getindex(0, itemtext)
     i = .getparent(i)
     result = i
end with
end function
'_______________________________________________________________________________
Function getchildrenlist (i as integer) as string
if QtreeviewEx.item(i).haschildren = 0 then result = ""
dim startlevel as integer
dim templist as string
templist = ""
startlevel = QtreeviewEx.item(i).level + 1
inc(i)
do
if QtreeviewEx.item(i).level = startlevel then
templist = templist + QtreeviewEx.item(i).text + ","
elseif QtreeviewEx.item(i).level < startlevel then
exit do
end if
inc(i)
loop until i = QtreeviewEx.itemcount
result = left$(templist, len(templist) - 1)
end function
'_______________________________________________________________________________
sub addchildto (startfrom as integer, itemtext as string, childtext as string)
with QtreeviewEx
.addchilditems (.getindex(startfrom, itemtext), childtext)
end with
end sub
'_______________________________________________________________________________
function Branchlength (i as integer) as integer
defint startlevel, x, y
with qtreeviewex
if .item(i).haschildren = 0 then
    result = 1
else
    startlevel = .item(i).level
    x = i + 1
    y = .itemcount
    if x = y then result = 0

        do
        if .item(x).level <= startlevel then
            exit do
        else
            inc(x)
        end if
        loop until x = y
result = x - i
end if
end with
end function
'_______________________________________________________________________________
sub MoveDown (i as integer)
defint x,y, startlevel, destindex, howmany
dim sl as qstringlist

with QtreeviewEx
x = i + 1
y = .itemcount
if i = y then exit sub

startlevel = .item(i).level

do
if .item(x).level = startlevel then
    destindex = x + .branchlength(x) - 1
    exit do
elseif .item(x).level < startlevel then
    exit sub
end if
inc(x)
loop until x = y

.savetofile (homedir + "tmp_tree.tv")
end with

with sl
.loadfromfile (homedir + "tmp_tree.tv")

howmany = Qtreeviewex.branchlength(i)

x = 0
do
if destindex = y then
    .additems .item(i)
    .delitems(i)
else
    .insertitem (destindex + 1, .item(i)) ' inc2026: .item(i) вместо .item(i).text: внутри WITH sl это QStringList, Item - массив строк (qstringlist.html), у строки нет .text; так же строки 117 и 212
    .delitems(i)
end if
inc(x)
loop until x = howmany

.savetofile (homedir + "tmp_tree.tv")
end with

Qtreeviewex.loadfromfile (homedir + "tmp_tree.tv")
Qtreeviewex.itemindex = i + Qtreeviewex.branchlength(i)
kill(homedir + "tmp_tree.tv")
end sub
'_______________________________________________________________________________
sub MoveUp (i as integer)
defint x,y, startlevel, destindex

with QtreeviewEx
if i = 0 then exit sub
startlevel = .item(i).level
x = i - 1

do
if .item(x).level = startlevel then
    destindex = x
    exit do
elseif .item(x).level < startlevel then
    exit sub
end if
dec(x)
loop until x = -1
.movedown(destindex)
.itemindex = destindex
end with
end sub
'_______________________________________________________________________________
sub IncLevel (i as integer)
defint x,y, startlevel
dim sl as qstringlist

startlevel = QtreeviewEx.item(i).level
x = i
if i = 0 then exit sub

with QtreeviewEx
do
if .item(x).level = startlevel then
    exit do
elseif .item(x).level > startlevel then
    exit sub
end if
dec(x)
loop until x = -1

.savetofile (homedir + "tmp_tree.tv")
end with

    with sl
    .loadfromfile (homedir + "tmp_tree.tv")

    x = 0
    y = QtreeviewEx.branchlength(i)
    do
    .item(x + i) = chr$(9) + .item(x + i)
    inc(x)
    loop until x = y

    .savetofile (homedir + "tmp_tree.tv")
    end with

QtreeviewEx.loadfromfile (homedir + "tmp_tree.tv")
QtreeviewEx.itemindex = i
kill (homedir + "tmp_tree.tv")
end sub
'_______________________________________________________________________________
sub DecLevel (i as integer)
defint x,y, parentindex

dim sl as qstringlist
with QtreeviewEx
if .item(i).level = 0 then exit sub
parentindex = .getparent(i)
y = .branchlength(i)

.savetofile (homedir + "tmp_tree.tv")
end with

with sl
.loadfromfile (homedir + "tmp_tree.tv")

x = 0
do
.insertitem(parentindex + x, right$(.item(i + x), len(.item(i + x)) - 1))
.delitems(i + x + 1)
inc(x)
loop until x = y

.savetofile (homedir + "tmp_tree.tv")
end with

QtreeviewEx.loadfromfile (homedir + "tmp_tree.tv")
QtreeviewEx.itemindex = parentindex - 1
kill (homedir + "tmp_tree.tv")

end sub
end type
'===============================================================================
  