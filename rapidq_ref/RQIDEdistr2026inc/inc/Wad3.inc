'***************************************************************************
'WAD3.INC (c)07/2003 by Christian Tandler,
'
'[HMK]St@neCold
'E-Mail: stonecold@csgui.de
'HP    : http://www.csgui.de
'
'WAD-Functions for Rapid-Q
'This library realize a basicly WAD3-Texture support for Rapid-Q
'
'I've written this code for my program CsWAD, a program to change the spraylogo in
'Counterstrike. The program uses this functions to show a preview of textures
'of WAD3-Files and save them as a BMP-File.
'You can download this little nice program and other CS-Tools at: http://www.csgui.de
'
'
'Place this file into the Include-Folder of RapidQ and
'Insert into your code with: $INCLUDE "WAD3.INC"
'
'You can use this code free of charge but at your own risk!
'Send comments and suggestions to stonecold@csgui.de
'Last change: 07/23/2003
'
'Many thank's to DrkShadow for some code snippets, documentations and support!
'*****************************************************************************


'DEFINES
$DEFINE __WAD3


'DECLARE FUNCTIONS
DECLARE Function GetWADInfo$(sFName AS STRING) AS STRING
DECLARE Function GetWADLump$(sFName AS STRING, LIndex AS INTEGER, sDFile AS STRING) AS STRING

'constANTS
const LSIZE_MAX = 15360                           'max. lump-size for pldecal's


'*** FUNCTIONS *******************************************************************
'GetWADInfo$
'Returning infos about the  WAD3-File and the included lumps
'Parameter: sFName: string, specify the WAD3-File
'Return: string
'
'Return string:
's#f#a#l1#l2#ln
'# : field separator
's : sum of all lump sizes
'f : version flag: -1: no WAD-File, 0:File-Error, 1:v1, 2:v2, 3:v3 (only v3 is readable!)
'a : number of lumps
'l1...ln: lump infos
'e.g. fieldnumber for the lump with index i is i+2 (Field$()-Function)

'content of l1...ln:
'n:g:k:x:y:c
': : field separator
'n : name of the lump
'g : size of lump in byte (uncompressed)
'k : compressed (0-no, 1-yes (lz))
'x : width in pixel
'y : height in pixel
'c : number of colors (in most cases 256)

'Example of return string for 'bigbrother.wad': 87304#3#2#bb:43652:0:288:112:256#bb1:43652:0:288:112:256#
'This is a WAD3-File, containing 2 lumps (bb and bb1), each with 43652bytes and 288*112pixel and 256 colors

Function GetWADInfo$(sFName AS STRING) AS STRING

  DIM wfile AS QFILESTREAM
  DIM serg AS STRING
  DIM sbuf AS STRING
  DIM slump AS STRING
  DIM ibuf AS INTEGER
  DIM i AS INTEGER
  DIM k AS INTEGER
  DIM lmpend AS INTEGER
  DIM lgsum AS INTEGER
  DIM ipsize AS INTEGER
  DIM ncolor AS INTEGER
  DIM i_type AS INTEGER
  DIM pmerk AS LONG
  DIM lloff AS LONG
  DIM ltoff AS LONG
  DIM lcoff AS LONG
  DIM x AS LONG
  DIM y AS LONG
  
  i_type = 0
  slump = Space$(64)                                          'preserve some space...
  sbuf = Space$(16)
  serg = Space$(4182)
  IF wfile.Open(sFName,fmOpenRead) = 0 THEN                   'no file
    serg = "0#0#"
  ELSE
    sbuf = RTrim$(wfile.ReadStr(4))                           'identifier
    IF UCase$(Left$(sbuf,3)) <> "WAD" THEN
      serg = "0#-1#"
    ELSE
      serg = Right$(sbuf,1) + "#"                             'version
      lmpend = wfile.ReadNum(2)                               'number of lumps (dword!, read only 2 byte)
      serg = serg + Str$(lmpend) + "#"
      sbuf = wfile.ReadBinStr(2)                              '2 bytes rest
      lloff = wfile.ReadNum(4)                                'offset to lumptable
      lgsum = 0                                               'sum of lump sizes
      FOR i = 1 TO lmpend
        wfile.Seek(lloff + ((i - 1) * 32),0)                  'lumptable + index of lump (one lumptable = 32byte)
        ltoff = wfile.ReadNum(4)                              'offset to texturtable
        ibuf = wfile.ReadNum(4)                               'size
        lgsum = lgsum + ibuf
        slump = Str$(ibuf) + ":"
        sbuf = wfile.ReadBinStr(4)                            'jump 4byte
        i_type = wfile.ReadNum(1)                             'type: 66-Special, 67-Normal
        ibuf = wfile.ReadNum(1)                               'compression type (0-no, 1-LZ)
        slump = slump + Str$(ibuf) + ":"
        sbuf = wfile.ReadBinStr(2)                            'jump 2byte
        pmerk = wfile.Position                                'remember position
        k = 0
        WHILE wfile.ReadNum(1) > 0                            'search end of string
          k = k + 1
        WEND
        wfile.Position = pmerk                                'return and...
        sbuf = RTrim$(wfile.ReadStr(k))                       'read name of lump
        serg = serg + sbuf + ":"
        wfile.Seek(ltoff,0)                                   'to texturtable
        IF i_type = 67 THEN                                   'normal... 
          sbuf = wfile.ReadBinStr(16)                         'jump 16byte
        END IF                                                'type 66: no name!
        x = wfile.ReadNum(4)                                  'width(x)
        slump = slump + Str$(x) + ":"
        y = wfile.ReadNum(4)                                  'height(y)
        slump = slump + Str$(y) + ":"
        IF i_type = 67 THEN                                   'normal... 
          sbuf = wfile.ReadBinStr(16)                         'jump 16byte (level offsets)
        END IF                                                'type 66: no MIP-Table!
        IF i_type = 67 THEN                                   'normal... 
          lcoff = (x * y) + (x * y / 4) + (x * y / 16) + (x * y / 64)  'offset to colortable
        ELSE
          lcoff = (x * y)
        END IF
        wfile.Seek(lcoff,1)                                   'to colortable
        ncolor = wfile.ReadNum(2)                             'palette size = colors
        slump = slump + Str$(ncolor)        
        serg = serg + slump + "#"
      NEXT
      serg = Str$(lgsum) + "#" + serg
    END IF
    wfile.Close
  END IF
  GetWADInfo$ = serg                                          'return the string
END Function


'GetWADLump$
'Read the data of a lump from a WAD3-File given by index and write it as
'a BMP-File, wich is given as destination (without extension!)
'If the destination is an empty string, it will be create a file with the name of lump
'The extension of the destination file is always .BMP
'
'Parameters:  sFName: string, the name of the WAD3 sourcefile
'             LIndex: int, the index of lump (p.e. explored with GetWADInfo$...)
'             sDFile: string, the destination filename or an empty string
'
'Return: if all OK: the filename of the bmp-file
'               "0": the index of lump doesn't exist
'              "-1": the WAD-file was not found
'              "-2": the file isn't a WAD3-File
'              "-3": can't open the WAD-File
'
Function GetWADLump$(sFName AS STRING, LIndex AS INTEGER, sDFile AS STRING) AS STRING

  DIM wfile AS QFILESTREAM
  DIM bfile AS QFILESTREAM
  DIM serg AS STRING
  DIM sbuf AS STRING
  DIM i AS INTEGER
  DIM k AS INTEGER
  DIM i_type AS INTEGER
  DIM pmerk AS LONG
  DIM lloff AS LONG
  DIM ltoff AS LONG
  DIM lpoff AS LONG
  DIM llidx AS LONG
  DIM l_anz AS INTEGER
  DIM l_size AS LONG
  DIM l_psize AS INTEGER
  DIM l_comp AS INTEGER
  DIM l_name AS STRING
  DIM l_width AS LONG
  DIM l_height AS LONG
  DIM l_data AS STRING
  DIM l_bdata AS STRING
  DIM l_pdata AS STRING
  DIM sBFile AS STRING
  DIM b_size AS LONG
  DIM b_offs AS LONG
  DIM bRed AS STRING
  DIM bGrn AS STRING
  DIM bBlu AS STRING
  
  i_type = 0
  llidx = LIndex  
  sbuf = Space$(1024)
  IF wfile.Open(sFName,fmOpenRead) = 0 THEN                   'no file
    serg = "-1"
  ELSE
    sbuf = RTrim$(wfile.ReadStr(4))                           'identifier
    IF UCase$(sbuf) <> "WAD3" THEN
      serg = "-2"
    ELSE
      l_anz = wfile.ReadNum(2)                                'no. of lumps (dword!, read only 2bytes)
      IF l_anz < llidx THEN                                   'index not found
        serg = "0"
      ELSE
        sbuf = wfile.ReadBinStr(2)                            'rest
        lloff = wfile.ReadNum(4)                              'offset to lumptable
        wfile.Seek(lloff + ((llidx - 1) * 32),0)              'lumptable + index of lump (one lumptable = 32bytes)
        ltoff = wfile.ReadNum(4)                              'offset to texturtable
        l_size = wfile.ReadNum(4)                             'size
        sbuf = wfile.ReadBinStr(4)                            'jump 4bytes
        i_type = wfile.ReadNum(1)                             'type: 66-special, 67-normal
        l_comp = wfile.ReadNum(1)                             'compressio type (0-no, 1-LZ)
        sbuf = wfile.ReadBinStr(2)                            'jump 2bytes
        pmerk = wfile.Position                                'remember position
        k = 0
        WHILE wfile.ReadNum(1) > 0                            'search the end of string
          k = k + 1
        WEND
        wfile.Position = pmerk                                'return and...
        l_name = RTrim$(wfile.ReadStr(k))                     'read the lumpname
        wfile.Seek(ltoff,0)                                   'to texturtable
        IF i_type = 67 THEN                                   'normal... 
          sbuf = wfile.ReadBinStr(16)                         'jump 16bytes
        END IF                                                'if type 66, no name!
        l_width = wfile.ReadNum(4)                            'width(x)
        l_height = wfile.ReadNum(4)                           'height(y)
        IF i_type = 67 THEN                                   'normal... 
          sbuf = wfile.ReadBinStr(16)                         'jump 16bytes (level-offsets)
        END IF                                                'if type 66 no MIP-Table!
        l_data = Space$(l_width * l_height)                   'create the buffer
        l_data = wfile.ReadBinStr(l_width * l_height)         'reading level1-data
        IF i_type = 67 THEN                                   'normal... 
          lpoff = (l_width * l_height / 4) + (l_width * l_height / 16) + (l_width * l_height / 64)   'offset to palette
          wfile.Seek(lpoff,1)                                 'to palette
        END IF
        l_psize = wfile.ReadNum(2)                            'size of palette
        l_pdata = Space$(l_psize * 3)                         'create buffer5 for palette
        l_pdata = wfile.ReadBinStr(l_psize * 3)               'reading palette (RGB)
        l_name = ReplaceSubstr$(l_name,"{","")                'delete the special characters
        l_name = ReplaceSubstr$(l_name,"!","")
        l_name = ReplaceSubstr$(l_name,"+","")
        l_name = ReplaceSubstr$(l_name,"-","")
        IF sDFile = "" THEN
          sBFile = l_name + ".bmp"
        ELSE
          sBFile = sDFile + ".bmp"
        END IF
        bfile.Open(sBFile,fmCreate)                           'create the bmp-file
        bfile.WriteBinStr("BM",2)                             'identifier
        b_size = 54 + (l_psize * 4) + (l_width * l_height)    'bmp-size (header+palette(colors*4)+rawsize)
        bfile.WriteNum(b_size,4)
        bfile.WriteNum(0,4)                                   'reserve
        b_offs = 54 + (l_psize * 4)                           'offset to raw-data (header+palette)
        bfile.WriteNum(b_offs,4)
        bfile.WriteNum(40,4)                                  'headersize
        bfile.WriteNum(l_width,4)                             'width
        bfile.WriteNum(l_height,4)                            'height
        bfile.WriteNum(1,2)                                   'planes
        SELECT CASE l_psize                                   'bit/pix, palette size = colors
          CASE 32
            bfile.WriteNum(1,2)                               '1bit/pix = b/w
          CASE 64
            bfile.WriteNum(2,2)                               '2bit/pix = 4F
          CASE 128
            bfile.WriteNum(4,2)                               '4bit/pix = 16F
          CASE 256
            bfile.WriteNum(8,2)                               '8bit/pix = 256F
          CASE 65536
            bfile.WriteNum(16,2)                              '16bit/pix = 65536F(HiColor) - not used in wad-files!
          CASE 16777216
            bfile.WriteNum(24,2)                              '24bit/pix = 16777216(24Bit-TrueColor) - not used!
          CASE ELSE
            bfile.WriteNum(32,2)                              '32bit/pix = 32Bit-TrueColor - not used!
        END SELECT
        bfile.WriteNum(l_comp,4)                              'compression - no
        bfile.WriteNum(l_width * l_height,4)                  'raw-size
        bfile.WriteNum(2846,4)                                'h-res (2846dpm = 72dpi)
        bfile.WriteNum(2846,4)                                'v-res
        bfile.WriteNum(l_psize,4)                             'colors
        bfile.WriteNum(l_psize,4)                             'used colors
        FOR i = 0 to l_psize - 1                              'write palette
          bRed = Mid$(l_pdata,(i * 3) + 1,1)
          bGrn = Mid$(l_pdata,(i * 3) + 2,1)
          bBlu = Mid$(l_pdata,(i * 3) + 3,1)
          bfile.WriteBinStr(bBlu,1)                           'rgb to bgr-translation!
          bfile.WriteBinStr(bGrn,1)
          bfile.WriteBinStr(bRed,1)
          bfile.WriteNum(0,1)                                 'fillbyte
        NEXT
        l_data = Reverse$(l_data)                             'flip bmp vertical! (i don't know why, but it's ok...)
        l_bdata = ""
        FOR i = 0 TO l_height - 1                             'and mirror!
          sbuf = Reverse$(Mid$(l_data,(i * l_width) + 1,l_width))   'row after row
          l_bdata = l_bdata + sbuf
        NEXT
        bfile.WriteBinStr(l_bdata,l_width * l_height)         'write raw-data
        bfile.Close
        serg = sBFile                                         'bmp-file is ready!
      END IF
    END IF
    wfile.Close
  END IF
  GetWADLump$ = serg                                          'return string
END Function

'EOF
  