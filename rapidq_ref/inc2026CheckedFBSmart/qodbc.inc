$APPTYPE CONSOLE

'ODBC - Open DataBase Connectivity
'Basic Steps
'Connecting to the SQL Server DataBase for retrieving information from tables

' ODBC Variables and Constants
Const MAX_DATA_BUFFER = 255
Const SQL_SUCCESS = 0
Const SQL_SUCCESS_WITH_INFO = 1
Const SQL_ERROR = -1
Const SQL_NO_DATA_FOUND = 100
Const SQL_CLOSE = 0
Const SQL_DROP = 1
Const SQL_CHAR = 1
Const SQL_NUMERIC = 2
Const SQL_DECIMAL = 3
Const SQL_INTEGER = 4
Const SQL_SMALLINT = 5
Const SQL_FLOAT = 6
Const SQL_REAL = 7
Const SQL_DOUBLE = 8
Const SQL_VARCHAR = 12
Const SQL_DATA_SOURCE_NAME = 6
Const SQL_USER_NAME = 8

'ODBC Declarations
Declare Function SQLAllocEnv Lib "odbc32.dll" Alias "SQLAllocEnv"(env As Long) As Short
Declare Function SQLFreeEnv Lib "odbc32.dll" Alias "SQLFreeEnv"(ByVal env As Long) As Short
Declare Function SQLAllocConnect Lib "odbc32.dll" Alias "SQLAllocConnect"(ByVal env As Long, ldbc As Long) As Short
Declare Function SQLConnect Lib "odbc32.dll" Alias "SQLConnect"(ByVal ldbc As Long, ByVal Server As String, ByVal serverlen As Integer, ByVal uid As String, ByVal uidlen As Integer, ByVal pwd As String, ByVal pwdlen As Integer) As Short
Declare Function SQLDriverConnect Lib "odbc32.dll" Alias "SQLDriverConnect"(ByVal ldbc As Long, ByVal hWnd As Long, ByVal szCSIn As Long, ByVal cbCSIn As Integer, ByVal szCSOut As Long, ByVal cbCSMax As Integer, cbCSOut As Long, ByVal f As Integer) As Short
Declare Function SQLFreeConnect Lib "odbc32.dll" Alias "SQLFreeConnect"(ByVal ldbc As Long) As Short
Declare Function SQLDisconnect Lib "odbc32.dll" Alias "SQLDisconnect"(ByVal ldbc As Long) As Short
Declare Function SQLAllocStmt Lib "odbc32.dll" Alias "SQLAllocStmt"(ByVal ldbc As Long, lStmt As Long) As Short
Declare Function SQLFreeStmt Lib "odbc32.dll" Alias "SQLFreeStmt"(ByVal lStmt As Long, ByVal EndOption As Integer) As Short
Declare Function SQLTables Lib "odbc32.dll" Alias "SQLTables"(ByVal lStmt As Long, ByVal q As Long, ByVal cbq As Integer, ByVal o As Long, ByVal cbo As Integer, ByVal t As Long, ByVal cbt As Integer, ByVal tt As Long, ByVal cbtt As Integer) As Short
Declare Function SQLExecDirect Lib "odbc32.dll" Alias "SQLExecDirect"(ByVal lStmt As Long, ByVal sqlString As LONG, ByVal sqlstrlen As Long) As Short
Declare Function SQLNumResultCols Lib "odbc32.dll" Alias "SQLNumResultCols"(ByVal lStmt As Long, NumCols As Long) As Short
Declare Function SQLDescribeCol Lib "odbc32.dll" Alias "SQLDescribeCol"(ByVal lStmt As Long, ByVal colnum As Integer, ByVal colname As Long, ByVal Buflen As Integer, colnamelen As Integer, dtype As Integer, dl As Long, ds As Integer, n As Integer) As Short
Declare Function SQLFetch Lib "odbc32.dll" Alias "SQLFetch"(ByVal lStmt As Long) As Short
Declare Function SQLGetData Lib "odbc32.dll" Alias "SQLGetData"(ByVal lStmt As Long, ByVal col As Integer, ByVal wConvType As Integer, ByVal lpbBuf As Long, ByVal dwbuflen As Long, lpcbout As Long) As Short
Declare Function SQLGetInfo Lib "odbc32.dll" Alias "SQLGetInfo"(ByVal ldbc As Long, ByVal hWnd As Long, ByVal szInfo As String, ByVal cbInfoMax As Integer, cbInfoOut As Integer) As Short
Declare Function SQLError Lib "odbc32.dll" Alias "SQLError"(ByVal env As Long, ByVal ldbc As Long, ByVal lStmt As Long, ByVal SQLState As Long, NativeError As Long, ByVal Buffer As Long, ByVal Buflen As Integer, Outlen As Integer) As Short
Declare Function SQLCloseCursor Lib "odbc32.dll" Alias "SQLCloseCursor"(ByVal lStmt As Long) As Short
Declare Function SQLDrivers Lib "odbc32.dll" Alias "SQLDrivers"(ByVal env As Long, ByVal dir As Integer, ByVal descrip as Long, ByVal bflen as Integer, descriplen as Integer, ByVal attrib as Long, ByVal bfattrlen as Integer, attriblen as Integer) As Short

Type qODBC EXTENDS Qobject

  glEnv As Long
  glDbc As Long
  glStmt as LONG
  sSQL As String
  SQLRet As Short
  sConnect as String
  DriverCount as Integer
  Driver(100) as String
  TableCount as integer
  Table(100) as String
  FieldCount as Integer
  Field.Name(100) as String
  Field.TypeNum(100) as integer
  Field.TypeStr(100) as string
  Field.Size(100) as Integer
  Field.DecDigits(100) as Integer
  Field.Nullav(100) as Integer
  Field.Data(100) as String


 Sub ODBCInit
   DIM iStatus As Short

  '1. Allocate ODBC Environment Handle
  SQLRet = SQLAllocEnv(VARPTR(qODBC.glEnv))
  If SQLRet <> SQL_SUCCESS Then
	MessageBox("Unable to initialize ODBC API drivers!", "Error", 0)
  Else
   '2. Allocate ODBC Database Handle
   SQLRet=SQLAllocConnect(qODBC.glEnv, VARPTR(qODBC.glDbc))
   If SQLRet<> SQL_SUCCESS Then
     MessageBox("Could not allocate memory for connection Handle!", "Error", 0)
     ' Free the Environment
     iStatus = SQLFreeEnv(qODBC.glEnv)
     If iStatus = SQL_ERROR Then
	  MessageBox("Error Freeing Environment From ODBC Drivers", "Error", 0)
     End If
   Else
     '2.1 Get Drivers
    Dim dir as Integer
    Dim descrip as STRING * MAX_DATA_BUFFER
    Dim descriplen as Integer
    Dim attrib as STRING * MAX_DATA_BUFFER
    Dim attriblen as Integer

    dir=2'First
    SQLRet=0
    qODBC.DriverCount=0
    While SQLRet=SQL_SUCCESS
     If SQLRet=SQL_SUCCESS then qODBC.DriverCount++
     SQLRet=SQLDrivers(qODBC.glEnv, dir, VARPTR(descrip),MAX_DATA_BUFFER, VARPTR(descriplen), VARPTR(attrib), MAX_DATA_BUFFER, VARPTR(attriblen))
     dir =1'Next
     qODBC.Driver(qODBC.DriverCount)=Left$(descrip,descriplen)
    Wend
   End If
  End if
 End Sub

 Sub Connect (sConn as String)
   qODBC.sConnect=sConn
  'Connect using the sConnect string - SQLDriverConnect
   DIM sResult As String * 256
   DIM iSize As Integer

   SQLRet = SQLDriverConnect(qODBC.glDbc, 0&, VARPTR(qODBC.sConnect), Len(qODBC.sConnect), VARPTR(sResult), 255, VARPTR(iSize), 1)
      If SQLRet < 0 Then
    MessageBox("Could not establish connection to ODBC driver!", "Error", 0)
   Else
    '4. Allocate ODBC Statement Handle
    SQLRet=SQLAllocStmt(qODBC.glDbc, VARPTR(qODBC.glStmt))
    If SQLRet<> SQL_SUCCESS Then
      MessageBox("Could not allocate memory for a statement handle!", "Error", 0)
    Else
     '4.1 Get tables
     Dim tPerform As Long
     Dim catalog As String * 0
     Dim schema As String * 0
     Dim tablename As String * 0
     Dim tabletype As String * 5
     Dim iTable as integer
     Dim tData As String * MAX_DATA_BUFFER
     Dim tOutLen As Long

     qODBC.TableCount=0
     tabletype="TABLE"
     SQLRet=SQLTables(qODBC.glStmt, VARPTR(catalog), 0, VARPTR(schema),0, VARPTR(tablename),0, VARPTR(tabletype),5)
     If SQLRet<> SQL_SUCCESS Then
      MessageBox("Could not get Tables!", "Error", 0)
     Else
      tPerform = SQL_SUCCESS
      While tPerform = SQL_SUCCESS
       tPerform = SQLFetch(qODBC.glStmt)		' Get the next row of data
       If tPerform = 65535 or tPerform = SQL_ERROR then
           Exit While
       Else
	  If tPerform = SQL_SUCCESS or tPerform = SQL_SUCCESS_WITH_INFO THEN
    	    qODBC.TableCount++
	    For iTable = 1 to 3
            iStatus = SQLGetData(qODBC.glStmt, iTable, 1, VARPTR(tData), MAX_DATA_BUFFER, VARPTR(tOutLen))
          Next
          qODBC.Table(qODBC.TableCount) = Left$(tData, tOutlen) ' tOutlen = -1 if no data or Null data
	  End If
       End If
      Wend
      'close cursor of tables query
      tPerform = SQLCloseCursor(qODBC.glStmt)
     End If
    End If
   End If
 End Sub

 Sub Query(sSQL as string)
  '5. Execute ODBC Statement - SQLExecDirect
    qODBC.sSQL=sSQL
    Dim lRet As Long, lErrNo As Long
    Dim iLen As Integer
    Dim sSQLState As String * MAX_DATA_BUFFER
    Dim sErrorMsg As String * MAX_DATA_BUFFER
    Dim sMsg As String


    qODBC.SQLRet=SQLExecDirect(qODBC.glStmt, VARPTR(qODBC.sSQL), Len(qODBC.sSQL))
    If qODBC.SQLRet <> SQL_SUCCESS and qODBC.SQLRet <> SQL_SUCCESS_WITH_INFO Then
        'Also Check for ODBC Error message - SQLError
        lRet = SQLError(glEnv, gldbc, glStmt, VARPTR(sSQLState), VARPTR(lErrNo), VARPTR(sErrorMsg), MAX_DATA_BUFFER, VARPTR(iLen))
        sMsg = "Error Executing SQL Statement" & Chr$(13) & Chr$(10)
        sMsg = sMsg & "ODBC State = " & Trim$(Left$(sSQLState, InStr(sSQLState, Chr$(0)) - 1)) & Chr$(13) & Chr$(10)
        sMsg = sMsg & "ODBC Error Message = " & Left$(sErrorMsg, iLen)
        MessageBox(sMsg, "Error", 0)
    End If

    Dim bPerform As Long
    Dim NumCols As Integer

    'Get number of columns
    bPerform = SQLNumResultCols (qODBC.glStmt, VARPTR(NumCols))
    If bPerform <> SQL_SUCCESS Then
        MessageBox("Could not get columns quantity!", "Error", 0)
        End
    Else
        qODBC.FieldCount= NumCols
    End if

    'Get column descriptor
    Dim icolnum as Integer
    Dim colname as String * MAX_DATA_BUFFER
    Dim colnamelen as Integer
    Dim dtype as Integer
    Dim colsize as Long
    Dim decdigits as Integer
    Dim nullav as Integer

    For icolnum = 1 to qODBC.FieldCount
      bPerform = SQLDescribeCol(qODBC.glStmt, icolnum, VARPTR(colname), MAX_DATA_BUFFER, VARPTR(colnamelen), VARPTR(dtype), VARPTR(colsize), VARPTR(decdigits), VARPTR(nullav))
      If bPerform <> SQL_SUCCESS Then
        MessageBox("Could not get column descriptor!", "Error", 0)
      Else
    	 Select case dtype
    	   case 1
		tipo$= "CHAR"
	   case 2
		tipo$=" NUMERIC"
	   case 3
		tipo$="DECIMAL"
	   case 4
		tipo$="INTEGER"
	   case 5
		tipo$="SMALLINT"
	   case 6
		tipo$="FLOAT"
	   case 7
		tipo$="REAL"
	   case 8
		tipo$="DOUBLE"
	   case 9
		tipo$="DATE"
	   case 10
		tipo$="TIME"
	   case 11
		tipo$="TIMESTAMP"
	   case 12
		tipo$="VARCHAR"
	   case 65535
		tipo$="LONGVARCHAR"
	   case 65534
		tipo$="BINARY"
	   case 65533
		tipo$="VARBINARY"
	   case 65532
		tipo$="LONGVARBINARY"
	   case 65531
		tipo$="BIGINT"
	   case 65530
		tipo$="TINYINT"
	   case 65529
		tipo$="BIT"
	   case 65456
		tipo$="TYPE_DRIVER_START"
	   case else
		tipo$="UNKNOWN TYPE"
	 End select
        qODBC.Field.Name(icolnum)=Left$(colname,colnamelen)
        qODBC.Field.TypeNum(icolnum)=dtype
        qODBC.Field.TypeStr(icolnum)=tipo$
        qODBC.Field.TypeNum(icolnum)=dtype
        qODBC.Field.Size(icolnum)=colsize
        qODBC.Field.DecDigits(icolnum)=decdigits
        qODBC.Field.Nullav(icolnum)=nullav
     End if
    Next
  End Sub

  Sub CloseQuery
    'Close cursor of query
    bPerform = SQLCloseCursor(qODBC.glStmt)
  End Sub

  Function GetRecord as Integer
   '6. Fetch one row of results from executed ODBC Statement - SQLFetch
    'Code in Step 7.

    '7. Get the Data in each field of the Fetched row - SQLGetData

    Dim bPerform As Long
    Dim iColumn as Integer
    Dim sData As String * MAX_DATA_BUFFER
    Dim lOutLen As Long
    Dim campo As String
    Dim iStatus as Long

    bPerform = SQLFetch(qODBC.glStmt)		' Get the next row of data
    If bPerform = 65535 or bPerform = SQL_ERROR then
      Result= 0
    Else
     If bPerform = SQL_SUCCESS or bPerform = SQL_SUCCESS_WITH_INFO THEN
       Result = 1
    	 For iColumn = 1 to qODBC.FieldCount
          iStatus = SQLGetData(qODBC.glStmt, iColumn, 1, VARPTR(sData), MAX_DATA_BUFFER, VARPTR(lOutLen))
            ' lOutlen = length of the valid data in sData
        	campo = Left$(sData, lOutlen) ' lOutlen = -1 if no data or Null data
             ' Add the Field Data to Correponding Data Display Controls for this row
            qODBC.Field.Data(iColumn)= campo
       Next
      Else
        Result= 0
     	End If
     End If
  End Function

  Sub CloseDB
    Dim bPerform As Short
    Dim iStatus As Short

    'Release the ODBC Statement Handle
    bPerform = SQLFreeStmt(qODBC.glStmt, SQL_DROP)

    '8. Release the ODBC Statement Handle - SQLFreeSTmt
    'Code in Step 7.
    '***********************************************************************
    'The steps 9 - 11 are for Disconnecting from the SQL Server DataBase
    '***********************************************************************
    '9. Disconnect from ODBC Database - SQLDisconnect
    iStatus = SQLDisconnect(qODBC.glDbc)
  End Sub

  Sub CloseODBC
    Dim iStatus As Short
    '10. Release the ODBC Database Handle - SQLFreeConnect
    iStatus = SQLFreeConnect(qODBC.glDbc)

    '11. Release the ODBC Environment Handle - SQLFreeEnv
    iStatus = SQLFreeEnv(qODBC.glEnv)
  End Sub
End Type


Dim myDB as qODBC
Dim sSQL as String

myDB.ODBCInit
PRINT "There are = ";myDB.DriverCount;" Installed Drivers"
FOR I = 1 TO myDB.DriverCount
   PRINT i;":";myDB.Driver(I)
NEXT
' Change the Driver and Database information in your Connexion String
sCon$ = "DRIVER={Microsoft Access Driver (*.mdb)};DBQ=adodemo.mdb;PWD=;UID=admin;"
myDB.Connect(sCon$)
PRINT "There are =";myDB.TableCount;" Tables"
FOR I = 1 TO myDB.TableCount
   PRINT i;": ";myDB.Table(I)
   q$="select * from "+ myDB.Table(I)
   myDB.Query(q$)
   Print " There are ";myDB.FieldCount;" Columns"
   For y=1 to myDB.FieldCount
       PRINT "  Field ";y;" :";myDB.Field.Name(y)
       PRINT "   TypeNum : ";myDB.Field.TypeNum(y)
       PRINT "   TypeStr : ";myDB.Field.TypeStr(y)
       PRINT "   TypeNum : ";myDB.Field.Size(y)
       PRINT "   DecDigits : ";myDB.Field.DecDigits(y)
       PRINT "   NullAvail : ";myDB.Field.Nullav(y)
   Next
   myDB.CloseQuery
NEXT

' Change Query String to fit your needs, here are some examples
'  sSQL = "insert into nummesa (nummesa) values("+STR$(MESA&[IP])+")"
sSQL = "select codigo,monto_contrato from obras where monto_contrato > 40 order by monto_contrato"
'  sSQL = "create table datos (LE CHAR(10) NULL, LM INTEGER, MONTO NUMERIC)"

myDB.Query(sSQL)
Print " There are ";myDB.FieldCount;" Columns"
For y=1 to myDB.FieldCount
   PRINT myDB.Field.Name(y);" ";
Next
PRINT
I=1
WHILE myDB.GetRecord = 1
 PRINT I;" : ";
 For y=1 to myDB.FieldCount
     PRINT myDB.Field.Data(y);" ";
 Next
 print
 I++
WEND
myDB.CloseQuery
myDB.CloseDB
myDB.CloseODBC
PRINT "FINISH"

End

