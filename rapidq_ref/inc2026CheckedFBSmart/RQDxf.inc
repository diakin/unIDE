$typecheck on
Declare SUB dfBegin  ()
Declare SUB dfCircle (Lay as string ,EC as string,xX as Double,xY as Double,xZ as Double,xRadius as Double)
Declare SUB dfLine   (Lay as string ,Lty as string,EC as string, xX1 as Double, xY1 as Double, xZ1 as Double, xX2 as Double, xY2 as Double, xZ2 as Double, xH as Double)
Declare SUB dfBeginPline (Lay AS STRING,EC AS STRING)
Declare SUB dfPlVertex   (Lay AS STRING,EC AS STRING,X AS DOUBLE,Y AS DOUBLE,Z AS DOUBLE)
Declare SUB dfEndPline   (Lay AS STRING,EC AS STRING)
Declare SUB dfEnd    ()
declare sub dfText (FileNum as integer,Lay  AS STRING, EC  AS STRING,X AS DOUBLE,Y AS DOUBLE, Z AS DOUBLE,TextDXF   AS STRING,HeightTxt as double,Factor as double,Angle as double,Alignh as double,Alignv as double,StyleTxt as string)
declare SUB dfpoint (FileNum as integer, Lay as string, EColor as string, X AS DOUBLE,Y AS DOUBLE, Z AS DOUBLE)

DIM DXFOUT AS QFILESTREAM
DIM DXFNAME AS STRING
dim layer as string
dim EColor as string
dim LType as string
dim TEXTDXF as string
defdbl x0,y0,z0,x1,x2,y1,y2,z1,z2,h,Radius,x,y,z
defdbl HeightTxt,Factor,Angle,Alignh,Alignv
defstr StyleTXT
dim FileNum As Integer


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

 end SUB
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


 end SUB
'
'Draw a circle with a center point and a radius
'

SUB dfCircle (Layer as string ,EColor as string,X as Double,Y as Double,Z as Double,Radius as Double)

'- End of header ---------------------------------------------------------------
      DXFOUT.WriteLine ( "  0" )         '+ Begin of Circle
      DXFOUT.WriteLine ( "CIRCLE")       '
      DXFOUT.WriteLine ( "  8")          '+ Layer code
      DXFOUT.WriteLine (Layer)           '+ Layer's name
      
      if uCase$(EColor)="BYLAYER"  then
     
         ' Nothing to do if EntColr is bylayer
      else
         DXFOUT.WriteLine (" 62")        '+ EntColr code
         DXFOUT.WriteLine (EColor)  '
      end if

      DXFOUT.WriteLine (" 10")
      DXFOUT.WriteLine (str$(X))
      DXFOUT.WriteLine (" 20")
      DXFOUT.WriteLine (str$(Y))
      DXFOUT.WriteLine (" 30")
      DXFOUT.WriteLine (str$(Z))
      DXFOUT.WriteLine (" 40" )
      DXFOUT.WriteLine (str$(Radius))

end SUB 'dfCircle

'
'+ Draw a line in DXF format.
'
SUB dfLine  (Layer as string,Ltype as string,EColor as string, X1 as double, Y1 as double, Z1 as double, X2 as double, Y2 as double, Z2 as double, H as double)
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


      if (Ucase$(EColor)="BYLAYER") then
      
      else
         DXFOUT.WriteLine (" 62")        '+ EntColr code
         DXFOUT.WriteLine (EColor)
      end if

      DXFOUT.WriteLine ( " 39")        '+ THICKNESS OF THE LINE (3D)
      DXFOUT.WriteLine (str$(H))           '


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

 end SUB
'+ Begin of a polyline
'
SUB dfBeginPline (Layer AS STRING,EColor AS STRING)

      DXFOUT.WriteLine ("  0")            '+ Begin of polyline
      DXFOUT.WriteLine ("POLYLINE")       '
      DXFOUT.WriteLine ("  8")            '+ Layer Code
      DXFOUT.WriteLine (Layer)            '+ Layer's name
      if (ucase$(EColOr)="BYLAYER") then
      else
         DXFOUT.WriteLine (" 62")        '+ EntColr code
         DXFOUT.WriteLine (EColor)         '
      end if
      DXFOUT.WriteLine ( " 66")            '
      DXFOUT.WriteLine ( "    1")          '
      DXFOUT.WriteLine ( "  0")            '
end SUB 'dfBeginPline

SUB dfEndPline (Layer AS STRING,  EColOr AS STRING)

      DXFOUT.WriteLine ("SEQEND")    '
      DXFOUT.WriteLine ("  8")       '+ Layer's code
      DXFOUT.WriteLine (Layer) '+ Layer's name
      if (uCASE$(EColor)="BYLAYER") then
      else
         DXFOUT.WriteLine (" 62")        '+ EntColr code
         DXFOUT.WriteLine (EColor)  '
      end if
 end SUB

SUB dfPlVertex (Layer AS STRING,ECoLOr AS STRING,X AS DOUBLE,Y AS DOUBLE,Z AS DOUBLE)
' Description:
'   Vertex of the polyline in the file <FileNum> in the layer <Layer>,
' with the EntColr <EntColr> and coordenates (X,Y,Z).
'
'- End of header ---------------------------------------------------------------

      DXFOUT.WriteLine ("VERTEX")   '
      DXFOUT.WriteLine ("  8")      '+ Layer's code
      DXFOUT.WriteLine (Layer)'+ Layer's name
      if (ucase$(EColOr)="BYLAYER") then
      else
         DXFOUT.WriteLine (" 62")        '+ EntColr code
         DXFOUT.WriteLine (EColor)  '
      end if
      DXFOUT.WriteLine (" 10")       '+ Code of the coordenate X of the polyline vertex
      DXFOUT.WriteLine (sTR$(X))              '+ Coordenate X of the vertex
      DXFOUT.WriteLine (" 20")       '+ Code of the coordenate Y of the polyline vertex
      DXFOUT.WriteLine (STR$(Y))             '+ Coordenate Y of the vertex
      DXFOUT.WriteLine (" 30")       '+ Code of the coordenate Z of the polyline vertex
      DXFOUT.WriteLine (sTR$(Z))              '+ Coordenate Z of the vertex
      DXFOUT.WriteLine ("  0")        '
 end SUB 'dfPlVertex

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
      if (EColor="BYLAYER") then
      else
         DXFOUT.WriteLine (" 62")        '+ EntColr code
         DXFOUT.WriteLine ( RTRIM$(EColor))  '
      end if
      DXFOUT.WriteLine (" 10")           '+ X code coordenate of the text.
      DXFOUT.WriteLine (str$(x))               '+ X coordenate.
      DXFOUT.WriteLine (" 20")           '+ Y code coordenate of the text.
      DXFOUT.WriteLine (str$(y))               '+ Y coordenate.
      DXFOUT.WriteLine (" 30")           '+ Z code coordenate of the text.
      DXFOUT.WriteLine (str$(z))                '+ Z coordenate.
      DXFOUT.WriteLine (" 40")
      DXFOUT.WriteLine (str$(HeightTxt))
      DXFOUT.WriteLine ( " 41")
      DXFOUT.WriteLine (STR$(Factor))              '+ Scale Factor
      DXFOUT.WriteLine ("  1")
      DXFOUT.WriteLine ( textDXF)
      DXFOUT.WriteLine ( " 50")
      DXFOUT.WriteLine ( str$(Angle))
      DXFOUT.WriteLine ( "  7")
      DXFOUT.WriteLine ( RTRIM$(styleTxt))
      DXFOUT.WriteLine ( " 72")
      DXFOUT.WriteLine (str$(alignh))
      DXFOUT.WriteLine ( " 11")
      DXFOUT.WriteLine (str$( X))
      DXFOUT.WriteLine (" 21")
      DXFOUT.WriteLine ( str$(Y))                '+ Height / 2.0 (Removed in version 0.2)
      DXFOUT.WriteLine (" 73")
      DXFOUT.WriteLine (str$( alignv))
 End SUB 'dfText
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

      if (UCASE$(EColor)="BYLAYER" )  then
         ' Nothing to do if EntColr is bylayer
      else
         DXFOUT.WriteLine (" 62")        '+ EntColr code
         DXFOUT.WriteLine (RTRIM$(EColor))  '
      end if

      DXFOUT.WriteLine (" 10")           '+ Point codes
      DXFOUT.WriteLine (str$(X))               '
      DXFOUT.WriteLine (" 20")           '
      DXFOUT.WriteLine (str$(Y))               '
      DXFOUT.WriteLine (" 30")           '
      DXFOUT.WriteLine (str$(Z))               '
 end SUB 'dfpoint

  