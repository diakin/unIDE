$APPTYPE CONSOLE
$TYPECHECK ON
DIM Font AS QFONT
DIM Form AS QFORM
DIM Label AS QLABEL
DIM Mem AS QMEMORYSTREAM
DIM N AS INTEGER
DIM S$ AS STRING

Font.Name = "Arial"
Font.Size = 12
Font.AddStyles(0, 1)
Label.Parent = Form
Label.Font = Font
PRINT "font "; Label.Font.Name; " "; Label.Font.Size

Mem.WriteLine("first")
Mem.WriteNum(1234, 4)
Mem.Position = 0
S$ = Mem.ReadLine
N = Mem.ReadNum(3)
PRINT "mem "; S$; " "; N; " size "; Mem.Size
IF Mem.Pointer <> 0 THEN PRINT "pointer ok"
