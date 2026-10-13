$IFNDEF __QXLS_INC   ' IncManager: include guard
$DEFINE __QXLS_INC
'QXLS.INC by Doctor Electron  Copyright 2002,2003 Global Services
'Last Modified: June 9, 2003
'These functions read all sheets in multiple Excel .xls files.

'R value masks
CONST xRKby100&=&H1   '0=value not changed
CONST xRKInteger&=&H2 '0=floating-point
CONST xRKEncoded&=&HFFFFFFFC

'Error Codes
'CONST xNULL=0
'CONST xDIVby0=&H7
'CONST xVALUE=&HF
'CONST xRK=&H17
'CONST xNAME=&H1D
'CONST xNUM=&H24
'CONST xNA=&H2A

'Record Codes-WorkBook
CONST xBOF??=&H809
CONST xEOF??=&HA
CONST xFILEPASS??=&H2F
CONST xPASSWORD??=&H13
CONST xBOUNDSHEET??=&H85
CONST xSST??=&HFC
CONST xCONTINUE??=&H3C
'Record Codes-WorkSheets
CONST xINDEX??=&H20B
CONST xDIMENSIONS??=&H200
CONST xROW??=&H208
CONST xDBCELL??=&HD7
CONST xWINDOW2??=&H23E
CONST xSELECTION??=&H1D
'Record Codes-Cells
CONST xARRAY??=&H221
CONST xBLANK??=&H201
CONST xBOOLERR??=&H205
CONST xFORMULA??=&H206
CONST xLABEL??=&H204
CONST xLABELSST??=&HFD
CONST xNUMBER??=&H203
CONST xMULBLANK??=&HBE
CONST xMULRK??=&HBD
CONST xRK??=&H27E
CONST xRSTRING??=&HD6
CONST xSHRFMLA??=&HBC
CONST xSTRING??=&H207

'P table columns
CONST pOFFSET&=0&
CONST pSHEET&=1&
CONST pDIMENSIONS&=2&
CONST pminROW&=3&
CONST pmaxROW&=4&
CONST pminCOL&=5&
CONST pmaxCOL&=6&
CONST pLENGTH&=7&
CONST NumVars&=7&

'Program 0-based dimension constants
CONST MaxBooks&=7&
CONST MaxSheets&=15&  
CONST MaxBytes&=4095&
CONST MaxSST&=255&

Declare FUNCTION xlsOPEN As LONG
Declare FUNCTION xlsREAD(s As LONG, row As LONG, col As LONG) As STRING
Declare FUNCTION xlsSHEETNAME(s As LONG) As STRING
Declare FUNCTION xlsMINROW(s As LONG) As LONG
Declare FUNCTION xlsMAXROW(s As LONG) As LONG
Declare FUNCTION xlsMINCOL(s As LONG) As LONG
Declare FUNCTION xlsMAXCOL(s As LONG) As LONG
Declare FUNCTION xlsSHEETLENGTH(s As LONG) As LONG
Declare FUNCTION xlsNUMBERSHEETS As LONG
Declare FUNCTION xlsCLOSE As LONG
Declare FUNCTION B2W(index As LONG) As WORD
Declare FUNCTION RK2str As STRING
Declare FUNCTION StrRecLen As LONG
Declare FUNCTION xlsSAVE(file As STRING) As LONG
Declare FUNCTION xlsWRITE(s As LONG, row As LONG, col As LONG, value As STRING) As LONG

Declare SUB ReadOLEFile
Declare SUB GetRecord
Declare SUB GetData
Declare SUB ClearBookData
'Declare SUB Uncorrupt
'Declare SUB RemoveTrash
Declare SUB ShiftBook(ptr As LONG, nbytes As LONG)
Declare SUB SheetPointers(s As LONG, nbytes As LONG)
Declare SUB ChangeValue(ptr As LONG, blen As LONG, nbytes As LONG)
Declare SUB FillFile(value As LONG, amt As LONG)
Declare SUB PrintSheetNames
Declare SUB PrintSSTRecords

'Stratch variables
Dim xB1 As BYTE, xB2 As BYTE
DIM buf(MaxBytes&) As Byte
DIM xCode As WORD, xLength As WORD, sCode As WORD, sLength As WORD, xFinish As WORD
DIM xType As LONG, xFormat As WORD, xIntegrity As WORD
DIM i As LONG, j As LONG, k As LONG, xEnd As LONG, xTmp As LONG
DIM xPosition As LONG, xNext As Long, wPosition As LONG 
DIM ptrINDEX As LONG, ptrINDEXEnd As LONG
DIM ptrDB As LONG, ptrDBOffset As LONG, ptrROW As LONG, ptrData As LONG
DIM RK As LONG, xInt As LONG, xUnicode As LONG
DIM xIEEE As DOUBLE 
DIM s$ As STRING, sERR As STRING
DIM F As QFileStream, F2 As QFileStream
'WorkBook specific
DIM b As Long                 'This is the workbook index
DIM M(MaxBooks&) As QMemoryStream
DIM FileSpec(MaxBooks&) As STRING
DIM P(MaxBooks&,MaxSheets&,NumVars&) As LONG
DIM SST(MaxBooks&,MaxSST&,2) As LONG  'unique string block data
DIM tSST(MaxBooks&) As LONG    'n unique strings
DIM nSST(MaxBooks&) As WORD    'n blocks of strings in SST 
DIM nSheets(MaxBooks&) As WORD 'n sheets according to BOUNDSHEET records
DIM nSR(MaxBooks&) As WORD     'n sheets read
DIM SheetName(MaxBooks&,MaxSheets&) As STRING
  
'''''Main Routines
FUNCTION xlsOPEN
Result=-1&: xFinish=0??: sERR=""
IF (b<0&) OR (b>MaxBooks&) THEN sERR="Book out of range": Exit Function
ClearBookData
IF FILEEXISTS(FileSpec(b))<=0& THEN sERR="File not found": Exit Function
ReadOLEFile
IF sERR<>"" THEN Goto OpenFail
M(b).Position=0&
FindBOF:
'GetRecord
xCode=M(b).ReadNum(2&): xLength=M(b).ReadNum(2&): xNext=M(b).Position+xLength
IF xCode=xBOF?? THEN
  xNext=M(b).Position-4&
  IF xNext>0& THEN Call ShiftBook(0&,-xNext): xNext=0&
  P(b,0&,0&)=0&: Goto NextParse
ELSE
  M(b).Position=M(b).Position+&H3C
  IF M(b).Position<M(b).Size THEN Goto FindBOF   
  sERR="BOF not found": Goto OpenFail
END IF
NextOpen:
xPosition=M(b).Position  ': GetRecord
xCode=M(b).ReadNum(2&): xLength=M(b).ReadNum(2&): xNext=M(b).Position+xLength
SELECT CASE xCode
CASE xBOF??
  GetData
  IF B2W(0&)<>&H600 THEN sERR="Not BIFF8 file": Goto OpenFail
  IF B2W(2&)<>5?? THEN
    IF nSR(b)<MaxSheets& THEN INC(nSR(b)) ELSE sERR="Too many sheets": Goto OpenFail
    IF xPosition<>P(b,nSR(b),0&) THEN sERR="File format read error": Goto OpenFail
  END IF
  P(b,nSR(b),pOFFSET&)=xPosition
CASE xEOF??
  P(b,nSR(b),pLENGTH&)=M(b).Position-P(b,nSR(b),pOFFSET&)
  IF nSR(b)=nSheets(b) THEN xFinish=1?? 'accounted for all BOUNDSHEETs
' WorkBook Globals
CASE xFILEPASS??
  IF xLength<>0?? THEN sERR="File password required": Goto OpenFail
CASE xPASSWORD??
  IF xLength<>2?? THEN sERR="Password required": Goto OpenFail
CASE xBOUNDSHEET??
  IF nSheets(b)<MaxSheets& THEN INC(nSheets(b)) ELSE sERR="Too many sheets": Goto OpenFail
  P(b,nSheets(b),pSHEET&)=xPosition: GetData
  MEMCPY(VARPTR(P(b,nSheets(b),pOFFSET&)),VARPTR(buf(0&)),4&)
  k=buf(6&)+(256& * buf(7&))+7&: s$=""
  FOR i=8& to k: s$=s$+CHR$(buf(i)): NEXT i
  SheetName(b,nSheets(b))=s$
CASE xSST??
  IF SST(b,0&,0&)<>0& THEN sERR="Multiple SST records": Goto OpenFail
  SST(b,0&,0&)=xPosition+12&
  M(b).Position=M(b).Position+4&: tSST(b)=M(b).ReadNum(4&) 'Total SST strings
  nSST(b)=0&: j=0&: k=0&
  IF tSST(b)=0& THEN Goto CheckSSTtotal
  CountStrings:
'  xTmp=StrRecLen
   sLength=M(b).ReadNum(2&): xTmp=sLength
   sCode=0??: sCode=M(b).ReadNum(1&)
   IF (sCode AND 1)>0?? THEN sLength=2??*sLength: xTmp=sLength 'String not compressed
   IF (sCode AND 8)>0?? THEN xTmp=M(b).ReadNum(2&): xTmp=sLength+4&*xTmp 'RichString
   IF (sCode AND 4)>0?? THEN i=M(b).ReadNum(4&): xTmp=xTmp+i  'Far East
'
  M(b).Position=M(b).Position+xTmp: INC(k)
  IF j+k>=tSST(b) THEN Goto EndofBlock
  IF M(b).Position<xNext THEN Goto CountStrings
  EndofBlock:
  xTmp=0&
  'Check if some lamer wrote a string across records.  Thus...
  IF M(b).Position>xNext THEN xTmp=M(b).Position-xNext+1
  SST(b,nSST(b),1&)=k: SST(b,nSST(b),2&)=M(b).Position: j=j+k: k=0&
  IF j>=tSST(b) THEN Goto CheckSSTTotal
  IF M(b).Position>P(b,1&,0&) THEN Goto CheckSSTTotal
  M(b).Position=xNext ': GetRecord
  xCode=M(b).ReadNum(2&): xLength=M(b).ReadNum(2&): xNext=M(b).Position+xLength
  IF xCode=xCONTINUE?? THEN 
    IF nSST(b)=MaxSST& THEN sERR="MaxSST& too small": Goto OpenFail
    INC(nSST(b)): M(b).Position=M(b).Position+xTmp  'ptr to 1st in record
    SST(b,nSST(b),0&)=M(b).Position: Goto CountStrings
  END IF
  CheckSSTTotal:
  IF j<>tSST(b) THEN sERR="SST total mismatch "+STR$(j)+" "+STR$(tSST(b))+" at "+HEX$(M(b).Position): Goto OpenFail
  IF xIntegrity=0& THEN xNext=P(b,1&,pOFFSET&)-4& '->next EOF
' WorkSheet Data  
CASE xDIMENSIONS??
  P(b,nSR(b),pDIMENSIONS&)=xPosition
  P(b,nSR(b),pminROW&)=M(b).ReadNum(4&): P(b,nSR(b),pmaxROW&)=M(b).ReadNum(4&)
  P(b,nSR(b),pminCOL&)=M(b).ReadNum(2&): P(b,nSR(b),pmaxCOL&)=M(b).ReadNum(2&)
  IF xIntegrity=1& THEN Goto NextParse
  IF nSR(b)<nSheets(b) THEN xNext=P(b,nSR(b)+1&,pOFFSET&)-4&: Goto NextParse 'Next BOF-4
  i=P(b,0&,1&)
  IF (i>4096&) AND (i>M(b).Position) THEN xNext=P(b,0&,1&)-4&  'BIFF8 length-4
END SELECT
NextParse:
M(b).Position=xNext
IF xFinish=1?? Then Goto OpenDone 
IF M(b).Position<(M(b).Size-4&) Then Goto NextOpen
sERR="Unexpected end of file"
OpenFail:
'ClearBookData
M(b).Close: Exit Function
OpenDone:
Result=nSR(b)
END FUNCTION

FUNCTION xlsSAVE(file As STRING) As LONG
DIM FAT(4&) As LONG
Result=-1&: sERR=""
IF FILEEXISTS(file)<=0& THEN F.Open(file,fmCreate) ELSE F.Open(file,2&)
IF FILEEXISTS("qxls.dat")<=0& THEN ExtractResource(Resource(1&),"qxls.dat"):DoEvents
F2.Open("qxls.dat",0&)
M(b).Position=0&: F.Position=0&
F.CopyFrom(F2,80&): FillFile(-1&,&H200) 'OLE header
FAT(0&)=P(b,0&,1&)  'file length
For i=0& to FAT(0&)-1& Step 8&
xiEEE=M(b).ReadNum(8&):F.WriteNum(xiEEE,8&): NEXT i
IF FAT(0&)>&H1000 THEN Call FillFile(0&,&H200) ELSE Call FillFile(0&,&H1000)
FAT(1&)=F.Position: i=1&: xPosition=(F.Position-&H200)\&H200 'ptr to FAT
WriteFATentry:
IF i<xPosition THEN F.WriteNum(i,4&): INC(i): Goto WriteFATentry
F.WriteNum(-2&,4&)
j=(F.Position-FAT(1&))\&H200+1& '# of FAT sectors
j=j+(j+2&)\128&
For i=1& to j: F.WriteNum(-3&,4&): NEXT i
CheckFATCount:
k=(F.Position-FAT(1&))\&H200+1&
IF k>j THEN F.WriteNum(-3&,4&): xTmp=F.Position
F.WriteNum(-2&,4&): FillFile(-1&,&H200)
FAT(4&)=(F.Position-FAT(1&))\&H200  'final update of # FAT sectors
IF FAT(4&)>k THEN F.Position=xTmp: j=k-1&: Goto CheckFATCount
xInt=(F.Position-&H200)\&H200     'ptr to DIR
xTmp=F.Position: F2.Position=&H50
F.CopyFrom(F2,512&) 'ole directory
IF FAT(0&)<&H1000 THEN i=&H1000 ELSE i=FAT(0&)
F.Position=xTmp+&HF8: F.WriteNum(i,4&) 'length
F.Position=&H2C: F.WriteNum(FAT(4&),4&) 'put # of FAT sectors
F.Position=&H30: F.WriteNum(xInt,4&)   'put DIR ptr
F.Position=&H4C: i=xPosition: xNext=&H200
WriteFATindex:
F.WriteNum(i,4&): INC(i)
IF F.Position<>xNext THEN Goto FATindexDone
IF F.Position=&H200 THEN
  F.Position=&H44: F.WriteNum(xInt+1&,4&)
  F.Position=(xInt+2&)*&H200: xNext=F.Position+&H1FC 
ELSE
  j=(F.Position+4&)\&H200-1&: F.WriteNum(j,4&): xNext=F.Position+&H1FC
END IF
FATindexDone:
IF i<xInt THEN Goto WriteFATindex
FillFile(-1&,&H200)  
IF FAT(4&)>109& THEN i=(FAT(4&)-109&)\128&+1&: F.Position=&H48: F.WriteNum(i,4&)
Result=F.Size
F.Close: F2.Close
END FUNCTION

FUNCTION xlsREAD(s As LONG, row As LONG, col As LONG) As STRING
DIM r As WORD, c As WORD, strindex As WORD
Result="": sERR=""
IF (b>MaxBooks&) OR (s>nSR(b)) THEN sERR="Book or sheet index too big": Exit Function
IF (row<P(b,s,pminROW&)) OR (row>=P(b,s,pmaxROW&)) THEN sERR="Row out of bounds": Exit Function
IF (col<0&) OR (col>255&) THEN sERR="Col out of bounds": Exit Function
M(b).Position=P(b,s,pOFFSET&)+20&     'index record
xEnd=P(b,s,pOFFSET&)+P(b,s,pLENGTH&)  'end of sheet
'Find row block
'GetRecord
GetIndexRecord:
xCode=M(b).ReadNum(2&): xLength=M(b).ReadNum(2&): xNext=M(b).Position+xLength
ptrINDEXEnd=xNext
IF xCode=xINDEX?? THEN Goto CheckIndex
M(b).Position=xNext
IF xNext<xEnd THEN Goto GetIndexRecord ELSE sERR="Index not found": Exit Function '&H208
CheckIndex:
i=M(b).Readnum(4&)
IF i<>0& THEN sERR="Bad Index record format": Exit Function
i=M(b).Readnum(4&)
IF i<>P(b,s,pminROW&) THEN sERR="Index and Dimensions disagree": Exit Function
j=M(b).Readnum(4&)
IF j<>P(b,s,pmaxROW&) THEN sERR="Index and Dimensions disagree": Exit Function
j=4& * ((row-i)\32&)+4&
IF j+12&>xLength THEN sERR="Index record too short": Exit Function
ptrINDEX=M(b).Position+j: M(b).Position=ptrINDEX: i=M(b).ReadNum(4&)
IF i<0& THEN sERR="Neg index pointer": Exit Function
IF i>xEnd THEN sERR="Bad index pointer": Exit Function
M(b).Position=i: xEnd=i
'GetRecord
xCode=M(b).ReadNum(2&): xLength=M(b).ReadNum(2&): xNext=M(b).Position+xLength
IF xCode<>xDBCELL?? THEN sERR="DBCell not found": Exit Function
ptrDBOffset=M(b).Position: xTmp=xNext: GetData
MEMCPY(VARPTR(i),VARPTR(buf(0&)),4&) 'neg offset to first cell data record
j=xEnd-i+20&: k=0&: i=0&: M(b).Position=j-20&
GetRowRecord:
ptrROW=M(b).Position
'GetRecord
xCode=M(b).ReadNum(2&): xLength=M(b).ReadNum(2&): xNext=M(b).Position+xLength
IF xCode<>xROW?? THEN sERR="Row record not found": Exit Function
k=k+buf(2&*i+4&)+256& * buf(2&*i+5&): r=M(b).ReadNum(4&)
IF r<row THEN M(b).Position=xNext: INC(i): Goto GetRowRecord
ptrDB=xEnd+10&+2&*i
IF ptrDB>=xTmp THEN ptrDB=0&
IF r>row THEN sERR="Row not defined": Exit Function
i=j+k: M(b).Position=i: xPosition=i
IF (i<ptrROW) OR (i>xEnd) THEN sERR="No cell record": Exit Function
NextRead:
xPosition=M(b).Position
'GetRecord
xCode=M(b).ReadNum(2&): xLength=M(b).ReadNum(2&): xNext=M(b).Position+xLength
SELECT CASE xCODE
  CASE xSTRING??, xARRAY??, xSHRFMLA??, &H4BC, xCONTINUE??
  Goto KeepMoving
END SELECT
GetData: r=buf(0&)+256&*buf(1&)
IF r<>row THEN sERR="Col not found/defined": Exit Function
c=buf(2&)+256&*buf(3&)
IF c>col THEN Exit Function  'columns to left were blank/not defined
IF (c<col) AND (xCode<>xMULRK??) THEN Goto KeepMoving
xFormat=buf(4&)+256&*buf(5&): wPosition=xPosition
CellType:
SELECT CASE xCode
CASE xLABELSST??
  strindex=buf(6&)+256&*buf(7&): k=0&: i=0&
  FindSSTRecord:
  j=k: k=k+SST(b,i,1&)
  IF strindex<k THEN Goto FindString
  IF i<nSST(b) THEN INC(i): Goto FindSSTRecord
  sERR="Index>no. strings": Exit Function
  FindString:
  M(b).Position=SST(b,i,0&): xNext=SST(b,i,2&)
  SSTString:
'  xTmp=StrRecLen
   sLength=M(b).ReadNum(2&): xTmp=sLength
   sCode=0&: sCode=M(b).ReadNum(1&)
   IF (sCode AND 1??)>0& THEN sLength=2??*sLength: xTmp=sLength 'String not compressed
   IF (sCode AND 8??)>0& THEN xTmp=M(b).ReadNum(2&): xTmp=sLength+4&*xTmp 'RichString
   IF (sCode AND 4??)>0& THEN i=M(b).ReadNum(4&): xTmp=xTmp+i  'Far East
'
  IF j<>strindex THEN Goto NextSSTEntry
  GetUnicodeNow:
  xUnicode=M(b).Position+M(b).Pointer: s$=""
  FOR i=1& to sLength
  'Check if string written across a CONTINUE record
  IF M(b).Position=xNext THEN M(b).Position=M(b).Position+5
  xB1=M(b).ReadNum(1&)
  'for 16-bit char and NOT (Far East OR Rich Text), get odd bytes only 
  IF sCode=1?? THEN
    xB2=M(b).ReadNum(1&): INC(i)
    SELECT CASE xB2
    CASE 4? 'RUSSIAN
    IF xB1=1? THEN j=167& ELSE j=176&
    IF xB1=81? THEN j=103&
    xB1=xB1+j
    END SELECT
  END IF
  s$=s$+CHR$(xB1)
  NEXT i
  Result=s$: xType=-1&: Exit Function
  NextSSTEntry:
  INC(j): M(b).Position=M(b).Position+xTmp
  IF M(b).Position>P(b,1&,pOFFSET&) THEN sERR="SST read error": Exit Function
  Goto SSTString
CASE xRK??, &H7E
  MEMCPY(VARPTR(RK),VARPTR(buf(6&)),4&)
  Result=RK2str: Exit Function
CASE xNUMBER??
  xIEEEnumber:
  MEMCPY(VARPTR(xIEEE),VARPTR(buf(6&)),8&)
  Result=STR$(xIEEE): xType=4&: Exit Function
CASE xMULRK??
  IF c>col THEN Goto KeepMoving
  i=6&  'first RK in buf
  NextMULRK:
  IF (c<col) AND (i+6<xLength) THEN INC(c): i=i+6&: Goto NextMULRK
  IF c=col THEN
    MEMCPY(VARPTR(RK),VARPTR(buf(i)),4&): ptrData=xPosition+i+4&
    Result=RK2str: Exit Function
  END IF
CASE xBLANK??
  sERR="#BLANK": Exit Function
CASE xLABEL??
  M(b).Position=xPosition+10&: xTmp=StrRecLen: Goto GetUnicodeNow
CASE xBOOLERR??
  sERR="#BOOLERR": Exit Function
CASE xFORMULA??, &H6, &H406
  xTmp=buf(12&)+256&*buf(13&): sERR="#FORMULA"
  IF (buf(6&)=0&) AND (xTmp=&HFFFF) THEN 
    M(b).Position=xNext  'Return value in next record
'    GetRecord
    xCode=M(b).ReadNum(2&): xLength=M(b).ReadNum(2&): xNext=M(b).Position+xLength
    GetData
    SELECT CASE xCODE
      CASE xARRAY??, xSHRFMLA??, &H4BC
      M(b).Position=xNext ': GetRecord
      xCode=M(b).ReadNum(2&): xLength=M(b).ReadNum(2&): xNext=M(b).Position+xLength
      GetData: Goto CellType
    END SELECT
    Goto CellType
  END IF
  IF (buf(6&)=1?) AND (xTmp=&HFFFF) THEN Result=STR$(buf(8&)): xType=2&: Exit Function
  Goto xIEEEnumber 
CASE xMULBLANK??
CASE xSTRING??
  sLength=buf(0&)+256&*buf(1&): s$=""
  FOR i=1& to sLength: s$=s$+CHR$(buf(i+2&)): NEXT i
  Result=s$: xType=-1&: Exit Function
CASE xWINDOW2??: Exit Function
CASE xSELECTION??: Exit Function
CASE xDBCELL??: sERR="Cell not found": Exit Function
CASE xRSTRING??: sERR="#RSTRING obsolete in BIFF8": Exit Function
CASE ELSE
  sERR="#"+RIGHT$(HEX$(xCode),4&)+" unexpected record code": Exit Function
END SELECT
KeepMoving:
M(b).Position=xNext
IF M(b).Position<=xEnd-4& THEN Goto NextRead
END FUNCTION

FUNCTION xlsWRITE(s As LONG, row As LONG, col As LONG, value As STRING) As LONG
DIM wr As LONG, wc As LONG, ws As LONG, wInt As LONG
DIM wType As LONG, wLength AS WORD
DIM xSingle As SINGLE
DIM r$ As STRING
Result=-1&: sERR=""
IF row>P(b,s,pMaxROW&) THEN sERR="Row not found": Exit Function
wr=row: wc=col: ws=s: wType=-1&: wLength=LEN(value)
IF wLength=0 THEN wType=-2&: Goto MakeRecord  'null string->BLANK
FOR i=1& to wLength: s$=MID$(value,i,1&)
IF (s$>"9") OR (s$<"-") OR (s$="\") THEN Goto MakeRecord
NEXT i
s$=value: i=TALLY(s$,".")
IF i>1& THEN Goto MakeRecord
j=TALLY(s$,"-")
IF j>1& then Goto MakeRecord
IF (j>0&) AND (LEFT$(s$,1&)<>"-") THEN Goto MakeRecord '"-" not first char
wType=4&: xIEEE=VAL(s$)
IF (wlength-i-j)>6& THEN Goto MakeRecord
IF (xIEEE>536870911.0#) OR (xIEEE<-536870912.0#) THEN Goto NotInteger
IF i=0& THEN wInt=INT(xIEEE): wType=2&: Goto MakeRecord
IF INSTR(1&,s$,".")<wLength-2& THEN Goto NotInteger
IF (xIEEE>5368709.11#) OR (xIEEE<-5368709.12#) THEN Goto NotInteger
wInt=INT(xIEEE*100#): wType=3&: Goto MakeRecord 'x 100

NotInteger:
IF (xIEEE<-(1.5E-45)) OR (xIEEE>(3.4E+38)) THEN Goto MakeRecord
xSingle=xIEEE
IF (xSingle AND &HC0000000)=0& THEN wType=0& 

MakeRecord:
'Check if record already there
ptrINDEXEnd=0&: ptrINDEX=0&: ptrDBOffset=0&: ptrROW=0&: ptrDB=0&: ptrData=0&: wPosition=0&
r$=xlsREAD(ws, wr, wc)  'if record exists, xPosition to xNext-1 is field
IF (r$="") AND (LEFT$(sERR,1&)<>"#") THEN xLength=0 ELSE xLength=xLength+4
MEMSET(VARPTR(buf(0&)),0&,4&)
buf(4&)=wr MOD 256&: buf(5&)=wr\256&: buf(6&)=wc MOD 256&: buf(7&)=wc\256&
IF xFormat=0& THEN xFormat=&HF
buf(8&)=xFormat MOD 256&: buf(9&)=xFormat\256&
SELECT CASE wType
  CASE -2&: buf(0&)=1?: buf(1&)=2?: buf(2&)=6?
  CASE -1&: buf(0&)=4?: buf(1&)=2?
    buf(10&)=wLength MOD 256&: buf(11&)=wLength\256&: buf(12&)=0?
    buf(2&)=(9&+wLength) MOD 256&: buf(3&)=(9&+wLength)\256&
    FOR i=1& to wLength: buf(12&+i)=ASC(MID$(value,i,1&)): NEXT i
  CASE 0&, 1&, 2&, 3&: buf(0&)=xRK??: buf(1&)=2?: buf(2&)=10?
    IF wType=1& THEN xSingle=100.0!*xSingle
    IF (wType AND 2&)>0& THEN RK=wInt SHL 2& ELSE MEMCPY(VARPTR(RK),VARPTR(xIEEE)+4&,4&)   
    RK=(RK AND xRKEncoded&) OR wType
    MEMCPY(VARPTR(buf(10&)),VARPTR(RK),4&) 
  CASE 4&: buf(0&)=xNUMBER??: buf(1&)=2?: buf(2&)=14?: MEMCPY(VARPTR(buf(10&)),VARPTR(xIEEE),8&) 
END SELECT
wLength=4??+buf(2&)+256??*buf(3&)
wInt=wLength-xLength
IF wInt=0 THEN Goto xPutNew
IF xCode=xMULRK?? THEN M(b).Position=ptrData: M(b).WriteNum(RK,4&): Goto xWriteDone
SELECT CASE sERR
  CASE "Row not defined","Col out of bounds": Exit Function
  CASE ELSE: wPosition=xPosition
END SELECT

'Update column data
IF wc<P(b,ws,pminCOL&) THEN
  P(b,ws,pminCOL&)=wc: xTmp=P(b,ws,pDIMENSIONS&)+12&
  M(b).Position=xTmp: M(b).WriteNum(wc,2&)
END IF
IF wc>P(b,ws,pmaxCOL&)-1& THEN
  P(b,ws,pmaxCOL&)=wc+1&: xTmp=P(b,ws,pDIMENSIONS&)+14&
  M(b).Position=xTmp: M(b).WriteNum(wc+1&,2&)
END IF
IF ptrROW=0& THEN Goto FileLength
M(b).Position=ptrROW+6&: sCode=M(b).ReadNum(2&)
IF wc<sCode THEN M(b).Position=ptrROW+6&: M(b).WriteNum(wc,2&)
M(b).Position=ptrROW+8&: sCode=M(b).ReadNum(2&)
IF wc>=sCode THEN M(b).Position=ptrROW+8&: M(b).WriteNum(wc+1&,2&)

FileLength:
P(b,0&,1&)=P(b,0&,1&)+wInt
ChangeValue(P(b,ws,pOFFSET&)+36&,4&,wInt) 'change ptr needed by Excel
UpdateINDEX:
ChangeValue(ptrINDEX,4&,wInt): ptrINDEX=ptrINDEX+4&
IF ptrINDEX<ptrINDEXEnd THEN Goto UpdateINDEX
SheetPointers(ws,wInt)
ChangeValue(ptrDBOffset,4&,wInt)
IF ptrDB>0& THEN ChangeValue(ptrDB,2&,wInt)

IF wInt>0& THEN ShiftBook(wPosition,wInt) ELSE ShiftBook(wPosition+wLength,wInt)
xPutNew:
MEMCPY(wPosition+M(b).Pointer,VARPTR(buf(0&)),wLength)
xWriteDone:
IF wLength>0& THEN sERR=""
Result=wLength
END FUNCTION

SUB SheetPointers(s As LONG, nbytes As LONG)
i=s+1&: j=nbytes
CheckSheetNumber:
IF i>nSR(b) THEN Exit Sub
ChangeValue(P(b,i,pSHEET&)+4&,4&,j)
M(b).Position=P(b,i,pOFFSET&)+20&
'GetRecord
xCode=M(b).ReadNum(2&): xLength=M(b).ReadNum(2&): xNext=M(b).Position+xLength
k=P(b,i,pOFFSET&)+36&
UpdateINDEX2:
ChangeValue(k,4&,j): k=k+4&
IF k<xNext THEN Goto UpdateINDEX2
P(b,i,pOFFSET&)=P(b,i,pOFFSET&)+j: P(b,i,pDIMENSIONS&)=P(b,i,pDIMENSIONS&)+j 
INC(i): Goto CheckSheetNumber
END SUB

SUB ChangeValue(ptr As LONG, blen As LONG, nbytes As LONG)
M(b).Position=ptr: xTmp=M(b).ReadNum(blen)
xTmp=xTmp+nbytes
M(b).Position=ptr: M(b).WriteNum(xTmp,blen) 
END SUB

FUNCTION xlsSHEETNAME(s As LONG) As STRING
Result=SheetName(b,s) 
END FUNCTION

FUNCTION xlsMINROW(s As LONG) As LONG
Result=P(b,s,pminROW&)
END FUNCTION

FUNCTION xlsMAXROW(s As LONG) As LONG
Result=P(b,s,pmaxROW&)-1&
END FUNCTION

FUNCTION xlsMINCOL(s As LONG) As LONG
Result=P(b,s,pminCOL&)
END FUNCTION

FUNCTION xlsMAXCOL(s As LONG) As LONG
Result=P(b,s,pmaxCOL&)-1&
END FUNCTION

FUNCTION xlsSHEETLENGTH(s As LONG) As LONG
Result=P(b,s,pLENGTH&)
END FUNCTION

FUNCTION xlsNUMBERSHEETS
Result=nSR(b)
END FUNCTION

FUNCTION xlsCLOSE
Result=-1&
IF (b<0&) OR (b>MaxBooks&) THEN Exit Function
M(b).Close: ClearBookData: Result=b
END FUNCTION

'''''Supporting routines
SUB GetRecord
xCode=M(b).ReadNum(2&): xLength=M(b).ReadNum(2&): xNext=M(b).Position+xLength
END SUB

SUB GetData
Dim kmax As WORD
IF xLength=0?? THEN Exit SUB
kmax=MaxBytes&
IF kmax>xLength-1?? THEN kmax=xLength-1??
FOR i=0& to kmax: buf(i)=M(b).ReadNum(1&): Next i
END SUB

FUNCTION RK2str
xType=RK AND &H3
IF (RK AND xRKInteger&)>0& THEN   
  xInt=RK SHR 2&
  IF RK<0& THEN xInt=xInt OR &HC0000000
  IF (RK AND xRKby100&)>0& THEN RK2str=STR$(xInt/100&) ELSE RK2Str=STR$(xInt)
  Exit Function
ELSE
  MEMSET(VARPTR(xIEEE),0&,8&)
  xInt=(RK AND xRKEncoded&)
  MEMCPY(VARPTR(xIEEE)+4&,VARPTR(xInt),4&)
  IF (RK AND xRKby100&)>0& THEN RK2str=STR$(xIEEE/100.0#) ELSE RK2Str=STR$(xIEEE)
  Exit Function
END IF
END FUNCTION

FUNCTION StrRecLen 'returns bytes from ptr to next record
DIM kk As LONG 
sLength=M(b).ReadNum(2&): kk=sLength
sCode=0??: sCode=M(b).ReadNum(1&)
IF (sCode AND 1??)>0& THEN sLength=2??*sLength: kk=sLength 'String not compressed
IF (sCode AND 8??)>0& THEN kk=M(b).ReadNum(2&): kk=sLength+4&*kk 'RichString
IF (sCode AND 4??)>0& THEN i=M(b).ReadNum(4&): kk=kk+i  'Far East
StrRecLen=kk
END FUNCTION

FUNCTION B2W(index As LONG) AS WORD
B2W=buf(index)+256??*buf(index+1&)
END FUNCTION

SUB ClearBookData
nSheets(b)=0&: nSR(b)=0& : tSST(b)=0&: nSST(b)=0& 
FOR i=0& to MaxSST&
For j=0& to 2&: SST(b,i,j)=0&: NEXT j
NEXT i
FOR i=0& to MaxSheets&
SheetName(b,i)=""
FOR j=0& to NumVars&: P(b,i,j)=0&: NEXT j
NEXT i
END SUB

'This uses OLE FAT to read file.  The code is not yet optimized.
SUB ReadOLEFile
DIM FATlen As LONG, DIRptr As LONG, FATindex As LONG, FATptr As LONG
DIM BB As LONG, NextFAT As LONG, ptrFATindex As LONG, EndFATindex As LONG
DIM WBptr As LONG, FATseg As LONG
F.Open(FileSpec(b),fmOpenRead)
F.Position=&H1E: i=F.ReadNum(2&): BB=2&^i  'size of big block sectors
F.Position=&H2C: FATlen=F.ReadNum(4&)
F.Position=&H30: i=F.ReadNum(4&): DIRptr=i*BB+BB
F.Position=&H44: FATindex=F.ReadNum(4&): INC(FATindex)
'IF FATindex>0& THEN FATindex=FATindex*BB+BB 'FAT index exceeds OLE header
M(b).Position=0&: ptrFATindex=&H4C: EndFATindex=BB 

'Find Workbook entry
WBptr=DIRptr
F.Position=DIRptr+&H74: xInt=F.ReadNum(4&) 'may be offset into FAT
IF (xInt<0&) OR (xInt>32&) THEN xInt=0&    'but only if it is positive and not too big
FOR j=1& to 3&: WBptr=WBptr+&H80
F.Position=WBptr: i=F.ReadNum(4&)
IF i=&H6F0057 THEN Goto FoundWBptr
NEXT j
sERR="Workbook OLE directory entry not found": Exit Sub
FoundWBptr:
F.Position=WBptr+&H74: j=F.ReadNum(4&)
IF j<=0& THEN j=xInt   'use the right offset into FAT
P(b,0&,1&)=F.ReadNum(4&) 'BIFF8 size

FOR k=1& to FATlen  'do a FAT sector
'next we switch to FAT index extension, if applicable
IF ptrFATindex>=EndFATindex THEN
  ptrFATindex=FATindex*BB  'end of OLE header or FAT index sector
  EndFATindex=ptrFATindex+BB
  F.Position=EndFATindex-4&: FATindex=F.ReadNum(4&): INC(FATindex)
END IF  

F.Position=ptrFATindex: i=F.ReadNum(4&): ptrFATindex=ptrFATindex+4&
IF i<0& THEN sERR="Bad FAT index": Exit Sub
FATptr=i*BB+BB: xNext=FATptr+BB: FATseg=FATptr
IF k=1& THEN FATptr=FATseg+j*4& 'offset into FAT

IF ptrFATindex=EndFATindex THEN NextFAT=FATindex ELSE NextFAT=F.ReadNum(4&): INC(NextFAT)
j=0& 

GetFATPointer:
IF FATptr>=xNext THEN Goto NextFATSector
F.Position=FATptr: i=F.ReadNum(4&): FATptr=FATptr+4&
IF j=0 THEN j=i-1&

IF i=NextFAT THEN i=j+1&: Goto LoadSector
SELECT CASE i
CASE &HFFFFFFFF: j=0&: Goto GetFATPointer
CASE &HFFFFFFFE  '-2 is EOF marker, but you read one more sector of user data
  IF M(b).Size<2048& THEN  'this because short OLE-generated files have bad DIRptr
    i=F.ReadNum(4&): j=i-1&: Goto LoadSector
  END IF
CASE &HFFFFFFFD: j=0&: Goto GetFATPointer 'inserted garbage; skip it
CASE &HFFFFFFFC: j=0&: Goto GetFATPointer
END SELECT

LoadSector:
INC(j): F.Position=j*&H200: M(b).CopyFrom(F,&H200)
IF i=-2& THEN Goto LoadDone 'EOF
IF i<>j THEN i=(i*4) MOD BB: FATptr=FATseg+i: j=0&
Goto GetFATPointer

NextFATSector:
NEXT k

LoadDone:
P(b,0&,2&)=M(b).Size: F.Close
IF P(b,0&,2&)<P(b,0&,1&) THEN sERR="All BIFF8 data not loaded"
END SUB

'The following two subs are replaced by ReadOLEFile
'MS Excel corrupts certain files (to prevent access?) which we now undo
'SUB Uncorrupt
'xTmp=M(b).Pointer
'MEMCPY(VARPTR(buf(0&)),xTmp+&H800,&H800)
'MEMCPY(xTmp+&H800,xTmp+&H1000,&H1000)
'MEMCPY(xTmp+&H1800,VARPTR(buf(0&)),&H800)
'END SUB

'MS Excel may put trash bytes (to prevent access?) which we now remove
'SUB RemoveTrash
'DIM memptr As LONG
'memptr=0&: j=0&
'IF xNext<>&H1000 THEN memptr=xNext-&H2000
'TrashCycle:
'SELECT CASE j MOD 4&
'  CASE 0&: memptr=memptr+&H10000: xB2=&H81
'  CASE 1&: memptr=memptr+&H10000
'    IF xNext=&H1000 THEN xB2=&HFD ELSE xB2=&H01
'  CASE 2&:  xB2=&H81
'    IF xNext=&H1000 THEN memptr=memptr+&HF800 ELSE memptr=memptr+&H10000
'  CASE 3&: memptr=memptr+&H10000: xB2=&H01
'END SELECT
'IF memptr>M(b).Size THEN Exit SUB
'M(b).Position=memptr: xB1=M(b).ReadNum(1&)
'IF xB1=xB2 THEN ShiftBook(memptr,-512&) ELSE Exit SUB
'INC(j): Goto TrashCycle
'END SUB

SUB FillFile(value As LONG, amt As LONG)
FillFileDone:
IF (F.Position-&H200) MOD amt=0& THEN Exit Sub
F.WriteNum(value,4&): Goto FillFileDone
END SUB

SUB ShiftBook(ptr As LONG, nbytes As LONG)
DIM mfrom As LONG, mdest As LONG
IF nbytes<0& THEN
  mdest=M(b).Pointer+ptr: mfrom=mdest-nbytes
  MEMCPY(mdest,mfrom,M(b).Size-(ptr-nbytes)+1&)
  M(b).Size=M(b).Size+nbytes
ELSE  
  mfrom=M(b).Size-1&: M(b).Size=M(b).Size+nbytes: mdest=M(b).Size-1&
  MoveByteUp: 'this is a slow way to do it and should be improved
  MEMCPY(M(b).Pointer+mdest,M(b).Pointer+mfrom,1&): DEC(mdest): DEC(mfrom)    
  IF mfrom>=ptr THEN Goto MoveByteUp
END IF
END SUB

'Utility routines to display internal data
SUB PrintSheetNames   'For CONSOLE application
For i=0& to nSheets(b): Print SheetName(b,i)
For j=0& to NumVars&: PRINT " "+RIGHT$(HEX$(P(b,i,j)),7&);: NEXT j
PRINT: NEXT i
END SUB

SUB PrintSSTRecords
PRINT "No. SST blocks=";STR$(nSST(b)+1&);" Strings in SST=";STR$(tSST(b))
For j=0& to nSST(b): PRINT STR$(SST(b,j,1&))+" ";: Next j
PRINT
END SUB
$ENDIF   ' IncManager: __QXLS_INC
