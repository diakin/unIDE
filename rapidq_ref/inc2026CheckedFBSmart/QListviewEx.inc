$typecheck on
$optimize on

defint lx, ly, ix, iy

type Qlistviewex extends Qlistview
ParentPanel as qpanel
Header as qpanel
ColHeader(100) as Qcoolbtn
csv as qstringlist
csvFile as string
Separator as string
Columns_count as integer
FlatHeaders as integer

constructor
   with parentpanel
   .borderstyle = 0
   .bevelouter = 0
   end with

   with header
   .parent = Qlistviewex.parentpanel
   .height = 20
   .align = 1
   .bevelouter = 0
   .borderstyle = 0
   end with

Columns_Count = 0
separator = ";"
showcolumnheaders = 0
FlatHeaders = 1
end constructor
'============================================================
function FieldsCount as integer
result = tally(Qlistviewex.csv.item(0), Qlistviewex.Separator) + 1
end function
'============================================================|
'Clear method is very slow if you use a lot of items,        |
'expecially if you select the last ones.                     |
Sub FastClear
defint oldviewstyle,oldfontsize
oldfontsize = Qlistviewex.font.size
oldviewstyle = Qlistviewex.viewstyle
    with QlistviewEx
    .viewstyle = 1
    .font.size = 1
    .clear
    .font.size = oldfontsize
    .viewstyle = oldviewstyle
    end with
end sub
'============================================================|
'Loading can be done ONLY from the CSV stringlist, so if you |
'want to load data from a File o a Qfilestream or            |
'Qmemorystream you'll have pass data to CSV and then call    |
'the load load function                                      |

sub load
QListviewEx.fastclear

dim field as string
qlistviewex.sorttype = 0
ly = Qlistviewex.csv.itemcount


for lx = 0 to (ly - 1)
    with qlistviewex
    field = field$(.CSV.item(lx), .separator, 1)
    if field = "" then field = "-"

    .additems field
    iy = .fieldscount

       for ix = 2 to iy
       field = field$(.CSV.item(lx), .separator, ix)
       if field = "" then field = "-"
       .addsubitem (lx, field)
       next
   end with
next
end sub
'============================================================|
sub loadfromcsvfile
QlistviewEx.csv.loadfromfile(QlistviewEx.csvFile)
QlistviewEx.load
end sub
'============================================================|
'Call this function passing a column header caption as       |
'variable                                                    |

sub sortby (Criterium as string)
iy = QlistviewEx.Fieldscount
ly = QlistviewEx.Itemcount

   for ix = 0 to (iy - 1)

   if QlistviewEx.column(ix).caption = Criterium then

   if ix = 0 then
   QlistviewEx.sorttype = 2
   exit sub
   end if


   with QlistviewEx
      .sorttype = 0
      lx = 0
      do
      swap (.item(lx).caption, .subitem(lx, ix - 1))
      inc(lx)
      loop until lx = (ly)

      .sorttype = 2
      .sorttype = 0

      lx = 0
      do
      swap (.item(lx).caption, .subitem(lx, ix - 1))
      inc(lx)
      loop until lx = (ly)
   end with

   End if
   next
end sub
'============================================================|
'This sub can exclude unwanted items from list. You'll have  |
'to pass the column number (the first column is number 0) and|
'the string contained in the items you want to remove.       |
' ** Note ** it's NOT case sensitive                         |

Sub Exclude (Column as integer, Criterium as string)
Criterium = ucase$(criterium)

  if column = 0 then
  with QlistviewEx
  lx = 0
  ly = .itemcount
  do
    if ucase$(.item(lx).caption) = Criterium then
    .delitems(lx)
    dec(lx)
    dec(ly)
    end if
  inc(lx)
  loop until lx = ly
  end with
  else
  with QlistviewEx
  lx = 0
  ly = .itemcount
  do
    if ucase$(.subitem(lx, Column - 1)) = Criterium then
    .delitems(lx)
    dec(lx)
    dec(ly)
    end if
  inc(lx)
  loop until lx = ly
  end with
  end if
end sub
'============================================================|
'Called when user clicks on a column header                 |

sub columnclick (hcapt as qcoolbtn)
Qlistviewex.sortby (hcapt.caption)
end sub

'============================================================|
'You'll have to call this sub every time you want to update  |
'QlistviewEx layout (so every time you change column caption,|
'width, etc...                                               |
sub draw
    With qlistviewex
    .parent = Qlistviewex.parentpanel
    .align = 5
    .viewstyle = 3
    .gridlines = 1
    end with

ix = 0
iy = Qlistviewex.Columns_Count
if iy = 0 then exit sub
do
 With qlistviewex
 .ColHeader(ix).caption = .column(ix).caption
 .ColHeader(ix).width = .column(ix).width
 if  ix = 0 then .ColHeader(ix).width = .column(ix).width + 2
 .colheader(ix).parent = .header
 .colheader(ix).align = 3
 .colheader(ix).flat = .Flatheaders
 .colheader(ix).onclick = Qlistviewex.columnclick
  end with
inc(ix)
loop until ix = iy
end sub
'============================================================|
'Use this to add columns, istead of the addcolumns method.   |
'Just pass columns names in a single string, separated by  a |
'"/" (See example)                                           |

sub addcol (coltoadd as string)
lx = 0
ly = (tally(coltoadd, "/") + 1)
do
 with QlistviewEx
 .addcolumns field$(coltoadd, "/", lx + 1)
 .Columns_count = (.Columns_count + 1)
 end with
inc(lx)
loop until lx = ly
QlistviewEx.draw
end sub

'============================================================|
' Update CSV Qstringlist with data contained in Qlistviewex. |
sub updatecsv
dim stringtoadd as string
lx = 0
ly = QlistviewEx.itemcount
iy = QlistviewEx.Fieldscount - 1
QlistviewEx.csv.clear
do
with QlistviewEx
stringtoadd = .item(lx).caption

  ix = 0
  do
  stringtoadd = stringtoadd + .separator + .subitem(lx, ix)
  inc(ix)
  loop until ix = iy
stringtoadd = replacesubstr$(stringtoadd, (.separator + "-" + .separator), _
(.separator + .separator))

.csv.additems stringtoadd
end with
inc(lx)
loop until lx = ly
end sub
'============================================================|
sub filter (Column as integer, criterium  as string)
criterium = ucase$(criterium)
lx = 0
ly = QlistviewEx.itemcount
do
  with QlistviewEx
       select case column
       case 0
          if ucase$(.item(lx).caption) = criterium then
          else
          .delitems(lx)
          dec(lx)
          dec(ly)
          end if
       case else
          if ucase$(.subitem(lx, column - 1)) = criterium then
          else
          .delitems(lx)
          dec(lx)
          dec(ly)
          end if
       end select
  end with
inc(lx)
loop until lx = ly
end sub

'============================================================|
sub SaveToCsvFile
    With QlistviewEx
    .updateCSV
    .csv.savetofile (.csvfile)
    end with
end sub
'============================================================|
sub SaveToFileAs
Dim ulvexdlg as Qsavedialog
if ulvexdlg.execute then
   with QlistviewEx
   .csv.savetofile (ulvexdlg.filename)
   end with
end if
end sub
'============================================================|
sub DirectSaveAs
Dim dsavedlg as Qsavedialog
dim tempfsstring as string
if dsavedlg.execute then
   dim Direct_Save_FS as qfilestream
   Direct_Save_FS.open(dsavedlg.filename, 65535)
      with QlistviewEx
      lx = 0
      ly = .itemcount
      do
      tempfsstring = ""
      tempfsstring = .item(lx).caption

         iy = .fieldscount - 1
         ix = 0
         do
         tempfsstring = tempfsstring + .separator + .subitem(lx, ix)
         inc(ix)
         loop until ix = iy

      Direct_Save_FS.writeline(tempfsstring)
      inc(lx)
      loop until lx = ly
      end with
   Direct_Save_FS.close
end if
end sub
'============================================================|

end type

' |                               |
' |   QlistviewEx Component by    |
' |                               |

' ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~|
' | Dreadsoft® Corporation        |
' | (manco un diritto riservato)  |
' | http://dreadsoft.too.it       |
' | dreadsoft@yahoo.it            |
' |~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  