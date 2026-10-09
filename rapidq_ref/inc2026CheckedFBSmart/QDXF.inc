
     $TYPECHECK on
     DECLARE SUB dfBegin  ()
     DECLARE SUB dfCircle (Lay AS STRING ,EC AS STRING,xX AS DOUBLE,xY AS DOUBLE,xZ AS DOUBLE,xRadius AS DOUBLE)
     DECLARE SUB dfLine   (Lay AS STRING ,Lty AS STRING,EC AS STRING, xX1 AS DOUBLE, xY1 AS DOUBLE, xZ1 AS DOUBLE, xX2 AS DOUBLE, xY2 AS DOUBLE, xZ2 AS DOUBLE, xH AS DOUBLE)
     DECLARE SUB dfBeginPline (Lay AS STRING,EC AS STRING)
     DECLARE SUB dfPlVertex   (Lay AS STRING,EC AS STRING,X AS DOUBLE,Y AS DOUBLE,Z AS DOUBLE)
     DECLARE SUB dfEndPline   (Lay AS STRING,EC AS STRING)
     DECLARE SUB dfEnd    ()
     DECLARE SUB dfText (FileNum AS INTEGER,Lay  AS STRING, EC  AS STRING,X AS DOUBLE,Y AS DOUBLE, Z AS DOUBLE,TextDXF   AS STRING,HeightTxt AS DOUBLE,Factor AS DOUBLE,Angle AS DOUBLE,Alignh AS DOUBLE,Alignv AS DOUBLE,StyleTxt AS STRING)
     DECLARE SUB dfpoint (FileNum AS INTEGER, Lay AS STRING, EColor AS STRING, X AS DOUBLE,Y AS DOUBLE, Z AS DOUBLE)

     DIM DXFOUT AS QFILESTREAM
     DIM DXFNAME AS STRING
     DIM layer AS STRING
     DIM EColor AS STRING
     DIM LType AS STRING
     DIM TEXTDXF AS STRING
     DEFDBL x0,y0,z0,x1,x2,y1,y2,z1,z2,h,Radius,x,y,z
     DEFDBL HeightTxt,Factor,Angle,Alignh,Alignv
     DEFSTR StyleTXT
     DIM FileNum AS INTEGER


     SUB dfBegin()
'- Begin of header ------------------------------------------------------------

      DXFOUT.WriteLine ( "  0")
      DXFOUT.WriteLine ( "SECTION")
      DXFOUT.WriteLine ( "  2")
      DXFOUT.WriteLine ( "HEADER")
      DXFOUT.WriteLine ( "  999")
      DXFOUT.WriteLine ( "http://www.ualg.pt/est/adec/dxfortran/")
      DXFOUT.WriteLine ( "  0")
      DXFOUT.WriteLine ( "ENDSEC")

      DXFOUT.WriteLine ( "  0")
      DXFOUT.WriteLine ( "SECTION")
      DXFOUT.WriteLine ( "  2")
      DXFOUT.WriteLine ( "ENTITIES")

     END SUB
'
'+ End the DXF File.
'
     SUB dfEnd()

'- End of header ---------------------------------------------------------------

      DXFOUT.WriteLine ( "  0")
      DXFOUT.WriteLine ("ENDSEC")
      DXFOUT.WriteLine ("  0")
      DXFOUT.WriteLine ("EOF")

      dxfout.close


     END SUB
'
'Draw a circle with a center point and a radius
'

     SUB dfCircle (Layer AS STRING ,EColor AS STRING,X AS DOUBLE,Y AS DOUBLE,Z AS DOUBLE,Radius AS DOUBLE)

'- End of header ---------------------------------------------------------------
      DXFOUT.WriteLine ( "  0" )         '+ Begin of Circle
      DXFOUT.WriteLine ( "CIRCLE")       '
      DXFOUT.WriteLine ( "  8")          '+ Layer code
      DXFOUT.WriteLine (Layer)           '+ Layer's name

      IF UCASE$(EColor)="BYLAYER"  THEN

         ' Nothing to do if EntColr is bylayer
      ELSE
       DXFOUT.WriteLine (" 62")        '+ EntColr code
       DXFOUT.WriteLine (EColor)  '
      END IF

      DXFOUT.WriteLine (" 10")
      DXFOUT.WriteLine (STR$(X))
      DXFOUT.WriteLine (" 20")
      DXFOUT.WriteLine (STR$(Y))
      DXFOUT.WriteLine (" 30")
      DXFOUT.WriteLine (STR$(Z))
      DXFOUT.WriteLine (" 40" )
      DXFOUT.WriteLine (STR$(Radius))

     END SUB 'dfCircle

'
'+ Draw a line in DXF format.
'
     SUB dfLine  (Layer AS STRING,Ltype AS STRING,EColor AS STRING, X1 AS DOUBLE, Y1 AS DOUBLE, Z1 AS DOUBLE, X2 AS DOUBLE, Y2 AS DOUBLE, Z2 AS DOUBLE, H AS DOUBLE)
' Description:
'   Draw a line in the in the file <FileNum> in the layer <Layer>
' and in the EntColr <EntColr> with coordenates of 1st note (X1, Y1),
' and the 2nd node coordenate (X2, Y2) and with the height <H>

      DXFOUT.WriteLine ( "  0")
      DXFOUT.WriteLine ( "LINE")
      DXFOUT.WriteLine ( "  8")
      DXFOUT.WriteLine (Layer)
      DXFOUT.WriteLine ( "  6")
      DXFOUT.WriteLine (Ltype)


      IF (UCASE$(EColor)="BYLAYER") THEN

      ELSE
       DXFOUT.WriteLine (" 62")        '+ EntColr code
       DXFOUT.WriteLine (EColor)
      END IF

      DXFOUT.WriteLine ( " 39")        '+ THICKNESS OF THE LINE (3D)
      DXFOUT.WriteLine (STR$(H))           '


      DXFOUT.WriteLine (" 10")        '+ Begin of line coordenate X1
      DXFOUT.WriteLine (STR$( X1))          '
      DXFOUT.WriteLine (" 20")        '+ Begin of line coordenate Y1
      DXFOUT.WriteLine (STR$( Y1))         '
      DXFOUT.WriteLine (" 30")        '+ Begin of line coordenate Z1
      DXFOUT.WriteLine (STR$( Z1))          '
      DXFOUT.WriteLine (" 11")        '+ End of line coordenate Y2
      DXFOUT.WriteLine (STR$( X2))          '
      DXFOUT.WriteLine (" 21")        '+ End of line coordenate Y2
      DXFOUT.WriteLine (STR$( Y2))          '
      DXFOUT.WriteLine (" 31")        '+ End of line coordenate Z2
      DXFOUT.WriteLine (STR$( Z2))          '

     END SUB
'+ Begin of a polyline
'
     SUB dfBeginPline (Layer AS STRING,EColor AS STRING)

      DXFOUT.WriteLine ("  0")            '+ Begin of polyline
      DXFOUT.WriteLine ("POLYLINE")       '
      DXFOUT.WriteLine ("  8")            '+ Layer Code
      DXFOUT.WriteLine (Layer)            '+ Layer's name
      IF (UCASE$(EColOr)="BYLAYER") THEN
      ELSE
       DXFOUT.WriteLine (" 62")        '+ EntColr code
       DXFOUT.WriteLine (EColor)         '
      END IF
      DXFOUT.WriteLine ( " 66")            '
      DXFOUT.WriteLine ( "    1")          '
      DXFOUT.WriteLine ( "  0")            '
     END SUB 'dfBeginPline

     SUB dfEndPline (Layer AS STRING,  EColOr AS STRING)

      DXFOUT.WriteLine ("SEQEND")    '
      DXFOUT.WriteLine ("  8")       '+ Layer's code
      DXFOUT.WriteLine (Layer) '+ Layer's name
      IF (UCASE$(EColor)="BYLAYER") THEN
      ELSE
       DXFOUT.WriteLine (" 62")        '+ EntColr code
       DXFOUT.WriteLine (EColor)  '
      END IF
     END SUB

     SUB dfPlVertex (Layer AS STRING,ECoLOr AS STRING,X AS DOUBLE,Y AS DOUBLE,Z AS DOUBLE)
' Description:
'   Vertex of the polyline in the file <FileNum> in the layer <Layer>,
' with the EntColr <EntColr> and coordenates (X,Y,Z).
'
'- End of header ---------------------------------------------------------------

      DXFOUT.WriteLine ("VERTEX")   '
      DXFOUT.WriteLine ("  8")      '+ Layer's code
      DXFOUT.WriteLine (Layer)'+ Layer's name
      IF (UCASE$(EColOr)="BYLAYER") THEN
      ELSE
       DXFOUT.WriteLine (" 62")        '+ EntColr code
       DXFOUT.WriteLine (EColor)  '
      END IF
      DXFOUT.WriteLine (" 10")       '+ Code of the coordenate X of the polyline vertex
      DXFOUT.WriteLine (STR$(X))              '+ Coordenate X of the vertex
      DXFOUT.WriteLine (" 20")       '+ Code of the coordenate Y of the polyline vertex
      DXFOUT.WriteLine (STR$(Y))             '+ Coordenate Y of the vertex
      DXFOUT.WriteLine (" 30")       '+ Code of the coordenate Z of the polyline vertex
      DXFOUT.WriteLine (STR$(Z))              '+ Coordenate Z of the vertex
      DXFOUT.WriteLine ("  0")        '
     END SUB 'dfPlVertex

     SUB dfText (FileNum,Layer, EntColr,X,Y, Z,Text,Height,Factor,Angle,Alignh,Alignv,Style)
' Description:
'   DXFOUT.WriteLine text to the file <FileNum>, EntColr <EntColr> and with the
' coordenates (X,Y). The message is stored in the variable <Text>,
' with de height <Height>, angle <Angle> and horizontal aligned with <Alignh),
' and vertical aligned with <alignv>:
' - Align left   : <Alignh> = 0         - Align none   : <Alignv> = 0
' - Align center : <Alignh> = 1         - Align bottom : <Alignv> = 1
' - Align right  : <Alignh> = 2         - Align middle : <Alignv> = 2

      DXFOUT.WriteLine ("  0")
      DXFOUT.WriteLine ("TEXT")
      DXFOUT.WriteLine ("  8")
      DXFOUT.WriteLine (RTRIM$(Layer))
      IF (EColor="BYLAYER") THEN
      ELSE
       DXFOUT.WriteLine (" 62")        '+ EntColr code
       DXFOUT.WriteLine ( RTRIM$(EColor))  '
      END IF
      DXFOUT.WriteLine (" 10")           '+ X code coordenate of the text.
      DXFOUT.WriteLine (STR$(x))               '+ X coordenate.
      DXFOUT.WriteLine (" 20")           '+ Y code coordenate of the text.
      DXFOUT.WriteLine (STR$(y))               '+ Y coordenate.
      DXFOUT.WriteLine (" 30")           '+ Z code coordenate of the text.
      DXFOUT.WriteLine (STR$(z))                '+ Z coordenate.
      DXFOUT.WriteLine (" 40")
      DXFOUT.WriteLine (STR$(HeightTxt))
      DXFOUT.WriteLine ( " 41")
      DXFOUT.WriteLine (STR$(Factor))              '+ Scale Factor
      DXFOUT.WriteLine ("  1")
      DXFOUT.WriteLine ( textDXF)
      DXFOUT.WriteLine ( " 50")
      DXFOUT.WriteLine ( STR$(Angle))
      DXFOUT.WriteLine ( "  7")
      DXFOUT.WriteLine ( RTRIM$(styleTxt))
      DXFOUT.WriteLine ( " 72")
      DXFOUT.WriteLine (STR$(alignh))
      DXFOUT.WriteLine ( " 11")
      DXFOUT.WriteLine (STR$( X))
      DXFOUT.WriteLine (" 21")
      DXFOUT.WriteLine ( STR$(Y))                '+ Height / 2.0 (Removed in version 0.2)
      DXFOUT.WriteLine (" 73")
      DXFOUT.WriteLine (STR$( alignv))
     END SUB 'dfText
'
     SUB dfpoint (FileNum, Layer, EColor, X,Y, Z)
'
' Description:
'
' Draw a 2D or 3D Point in the in the file <FileNum> in the layer <Layer>
' and in the EntColr <EntColr> with coordenates (X,Y,Z).
'
      DXFOUT.WriteLine ("  0")          '+ Begin of 3DFace
      DXFOUT.WriteLine ("POINT")        '
      DXFOUT.WriteLine ("  8")          '+ Layer code
      DXFOUT.WriteLine (RTRIM$(Layer))    '  Layer's name

      IF (UCASE$(EColor)="BYLAYER" )  THEN
         ' Nothing to do if EntColr is bylayer
      ELSE
       DXFOUT.WriteLine (" 62")        '+ EntColr code
       DXFOUT.WriteLine (RTRIM$(EColor))  '
      END IF

      DXFOUT.WriteLine (" 10")           '+ Point codes
      DXFOUT.WriteLine (STR$(X))               '
      DXFOUT.WriteLine (" 20")           '
      DXFOUT.WriteLine (STR$(Y))               '
      DXFOUT.WriteLine (" 30")           '
      DXFOUT.WriteLine (STR$(Z))               '
     END SUB 'dfpoint


