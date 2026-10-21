$APPTYPE CONSOLE
' $RESOURCE (chapter 8): BMPHandle of QCOOLBTN and QBUTTON, Form.ICOHandle,
' RESOURCE(n), RESOURCECOUNT, EXTRACTRESOURCE; the same name twice
$RESOURCE Red_BMP AS "res\red16.bmp"
$RESOURCE Green_ICO AS "./res/green16.ico"
$RESOURCE Note_TXT AS <res/note.txt>
$RESOURCE Red_BMP AS "res\other.bmp"
DIM Line$ AS STRING
CREATE Form AS QFORM
  Caption = "Resources"
  ICOHandle = Green_ICO
  CREATE Cool1 AS QCOOLBTN
    BMPHandle = Red_BMP
    Spacing = 3
  END CREATE
  CREATE Btn1 AS QBUTTON
    Top = 40
    BMPHandle = Red_BMP
    Spacing = 2
  END CREATE
END CREATE
PRINT "count "; RESOURCECOUNT; " first "; (RESOURCE(0) = Red_BMP); " third "; (RESOURCE(2) = Note_TXT)
PRINT "spacing "; Cool1.Spacing; Btn1.Spacing
EXTRACTRESOURCE(Note_TXT, "note_out.txt")
OPEN "note_out.txt" FOR INPUT AS #1
LINE INPUT #1, Line$
CLOSE #1
PRINT "extracted: "; Line$
KILL "note_out.txt"
