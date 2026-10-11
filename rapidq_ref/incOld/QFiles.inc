'QFILES.INC by Doctor Electron  Copyright 2002 Global Services
'Last Modified: Dec 20, 2002    Comments to: doctorelectron@cwdom.dm

'These routines were written to allow indexed access (fNum) to files.
'Use GetFileNum Function first to get fNum to be used in all other calls.
'If GetFileNum < 0 then you don't have an available fNum "file handle."

Declare SUB fINITIALIZE
Declare FUNCTION GetFileNum() As LONG
Declare SUB fOPEN(fNum As LONG, fName$ AS STRING, fHow AS LONG)
Declare SUB fCLOSE(fNum As LONG)
Declare SUB fPOSITION(fNum As LONG, fPosition As LONG)
Declare SUB fWRITELINE(fNum As LONG, fString As STRING)
Declare FUNCTION fSIZE(fNum As LONG) As LONG
Declare FUNCTION fREADBINSTR(fNum As LONG, fBytes As LONG) As STRING

const MaxQFiles=8

Dim qf1 As QFileStream
Dim qf2 As QFileStream
Dim qf3 As QFileStream
Dim qf4 As QFileStream
Dim qf5 As QFileStream
Dim qf6 As QFileStream
Dim qf7 As QFileStream
Dim qf8 As QFileStream
Dim qfn(1 to MaxQFiles) As Byte  'keeps track of which qfiles are open
DIM qfi As LONG

SUB fINITIALIZE  'call this to initialize at program start
For qfi=1 to MaxQFiles: qfn(qfi)=0: Next qfi
END SUB

FUNCTION GetFileNum() As LONG
Result=-1
FOR qfi=1 to MaxQFiles
IF qfn(qfi)=0 THEN Result=qfi: Exit Function
NEXT qfi
END FUNCTION

SUB fOPEN(fNum As LONG, fName$ AS STRING, fHow AS LONG)
qfi=fHow
IF FILEEXISTS(fName$)=0 THEN qfi=fmcreate
SELECT CASE fNum
CASE 1: qf1.OPEN(fName$,qfi)
CASE 2: qf2.OPEN(fName$,qfi)
CASE 3: qf3.OPEN(fName$,qfi)
CASE 4: qf4.OPEN(fName$,qfi)
CASE 5: qf5.OPEN(fName$,qfi)
CASE 6: qf6.OPEN(fName$,qfi)
CASE 7: qf7.OPEN(fName$,qfi)
CASE 8: qf8.OPEN(fName$,qfi)
END SELECT
qfn(fNum)=1
END SUB

SUB fCLOSE(fNum As LONG)
SELECT CASE fNum
CASE 1: qf1.CLOSE
CASE 2: qf2.CLOSE
CASE 3: qf3.CLOSE
CASE 4: qf4.CLOSE
CASE 5: qf5.CLOSE
CASE 6: qf6.CLOSE
CASE 7: qf7.CLOSE
CASE 8: qf8.CLOSE
END SELECT
qfn(fNum)=0: DoEvents
END SUB

SUB fPOSITION(fNum As LONG, fPosition As LONG)
SELECT CASE fNum
CASE 1: qf1.Position=fPosition
CASE 2: qf2.Position=fPosition
CASE 3: qf3.Position=fPosition
CASE 4: qf4.Position=fPosition
CASE 5: qf5.Position=fPosition
CASE 6: qf6.Position=fPosition
CASE 7: qf7.Position=fPosition
CASE 8: qf8.Position=fPosition
END SELECT
END SUB

FUNCTION fSIZE(fNum As LONG) As LONG
SELECT CASE fNum
CASE 1: Result=qf1.Size
CASE 2: Result=qf2.Size
CASE 3: Result=qf3.Size
CASE 4: Result=qf4.Size
CASE 5: Result=qf5.Size
CASE 6: Result=qf6.Size
CASE 7: Result=qf7.Size
CASE 8: Result=qf8.Size
END SELECT
END FUNCTION

FUNCTION fReadBinStr(fNum As LONG, fBytes As LONG) As STRING
SELECT CASE fNum
CASE 1: Result=qf1.ReadBinStr(fBytes)
CASE 2: Result=qf2.ReadBinStr(fBytes)
CASE 3: Result=qf3.ReadBinStr(fBytes)
CASE 4: Result=qf4.ReadBinStr(fBytes)
CASE 5: Result=qf5.ReadBinStr(fBytes)
CASE 6: Result=qf6.ReadBinStr(fBytes)
CASE 7: Result=qf7.ReadBinStr(fBytes)
CASE 8: Result=qf8.ReadBinStr(fBytes)
END SELECT
DoEvents
END FUNCTION

SUB fWriteLine(fNum As LONG, fString As STRING)
SELECT CASE fNum
CASE 1: qf1.WriteLine(fString)
CASE 2: qf2.WriteLine(fString)
CASE 3: qf3.WriteLine(fString)
CASE 4: qf4.WriteLine(fString)
CASE 5: qf5.WriteLine(fString)
CASE 6: qf6.WriteLine(fString)
CASE 7: qf7.WriteLine(fString)
CASE 8: qf8.WriteLine(fString)
END SELECT
DoEvents
END SUB

'Add other QFileStream properties and methods here as you need them.
'These routines look ugly, but are a workaround to access files by index.  