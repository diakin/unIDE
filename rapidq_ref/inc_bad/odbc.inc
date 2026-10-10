'ODBC - Open DataBase Connectivity
'Basic Steps
'Connecting to the SQL Server DataBase for retrieving information from tables

' ODBC Variables and Constants
     CONST MAX_DATA_BUFFER = 255
     CONST SQL_SUCCESS = 0
     CONST SQL_SUCCESS_WITH_INFO = 1
     CONST SQL_ERROR = -1
     CONST SQL_NO_DATA_FOUND = 100
     CONST SQL_CLOSE = 0
     CONST SQL_DROP = 1
     CONST SQL_CHAR = 1
     CONST SQL_NUMERIC = 2
     CONST SQL_DECIMAL = 3
     CONST SQL_INTEGER = 4
     CONST SQL_SMALLINT = 5
     CONST SQL_FLOAT = 6
     CONST SQL_REAL = 7
     CONST SQL_DOUBLE = 8
     CONST SQL_VARCHAR = 12
     CONST SQL_DATA_SOURCE_NAME = 6
     CONST SQL_USER_NAME = 8

'ODBC Declarations
     DECLARE FUNCTION SQLAllocEnv LIB "odbc32.dll" ALIAS "SQLAllocEnv"(env AS LONG) AS SHORT
     DECLARE FUNCTION SQLFreeEnv LIB "odbc32.dll" ALIAS "SQLFreeEnv"(ByVal env AS LONG) AS SHORT
     DECLARE FUNCTION SQLAllocConnect LIB "odbc32.dll" ALIAS "SQLAllocConnect"(ByVal env AS LONG, ldbc AS LONG) AS SHORT
     DECLARE FUNCTION SQLConnect LIB "odbc32.dll" ALIAS "SQLConnect"(ByVal ldbc AS LONG, ByVal Server AS STRING, ByVal serverlen AS INTEGER, ByVal uid AS STRING, ByVal uidlen AS INTEGER, ByVal pwd AS STRING, ByVal pwdlen AS INTEGER) AS SHORT
     DECLARE FUNCTION SQLDriverConnect LIB "odbc32.dll" ALIAS "SQLDriverConnect"(ByVal ldbc AS LONG, ByVal hWnd AS LONG, ByVal szCSIn AS LONG, ByVal cbCSIn AS INTEGER, ByVal szCSOut AS LONG, ByVal cbCSMax AS INTEGER, cbCSOut AS LONG, ByVal f AS INTEGER) AS SHORT
     DECLARE FUNCTION SQLFreeConnect LIB "odbc32.dll" ALIAS "SQLFreeConnect"(ByVal ldbc AS LONG) AS SHORT
     DECLARE FUNCTION SQLDisconnect LIB "odbc32.dll" ALIAS "SQLDisconnect"(ByVal ldbc AS LONG) AS SHORT
     DECLARE FUNCTION SQLAllocStmt LIB "odbc32.dll" ALIAS "SQLAllocStmt"(ByVal ldbc AS LONG, lStmt AS LONG) AS SHORT
     DECLARE FUNCTION SQLFreeStmt LIB "odbc32.dll" ALIAS "SQLFreeStmt"(ByVal lStmt AS LONG, ByVal EndOption AS INTEGER) AS SHORT
     DECLARE FUNCTION SQLTables LIB "odbc32.dll" ALIAS "SQLTables"(ByVal lStmt AS LONG, ByVal q AS LONG, ByVal cbq AS INTEGER, ByVal o AS LONG, ByVal cbo AS INTEGER, ByVal t AS LONG, ByVal cbt AS INTEGER, ByVal tt AS LONG, ByVal cbtt AS INTEGER) AS SHORT
     DECLARE FUNCTION SQLExecDirect LIB "odbc32.dll" ALIAS "SQLExecDirect"(ByVal lStmt AS LONG, ByVal sqlString AS LONG, ByVal sqlstrlen AS LONG) AS SHORT
     DECLARE FUNCTION SQLNumResultCols LIB "odbc32.dll" ALIAS "SQLNumResultCols"(ByVal lStmt AS LONG, NumCols AS LONG) AS SHORT
     DECLARE FUNCTION SQLDescribeCol LIB "odbc32.dll" ALIAS "SQLDescribeCol"(ByVal lStmt AS LONG, ByVal colnum AS INTEGER, ByVal colname AS LONG, ByVal Buflen AS INTEGER, colnamelen AS INTEGER, dtype AS INTEGER, dl AS LONG, ds AS INTEGER, n AS INTEGER) AS SHORT
     DECLARE FUNCTION SQLFetch LIB "odbc32.dll" ALIAS "SQLFetch"(ByVal lStmt AS LONG) AS SHORT
     DECLARE FUNCTION SQLGetData LIB "odbc32.dll" ALIAS "SQLGetData"(ByVal lStmt AS LONG, ByVal col AS INTEGER, ByVal wConvType AS INTEGER, ByVal lpbBuf AS LONG, ByVal dwbuflen AS LONG, lpcbout AS LONG) AS SHORT
     DECLARE FUNCTION SQLGetInfo LIB "odbc32.dll" ALIAS "SQLGetInfo"(ByVal ldbc AS LONG, ByVal hWnd AS LONG, ByVal szInfo AS STRING, ByVal cbInfoMax AS INTEGER, cbInfoOut AS INTEGER) AS SHORT
     DECLARE FUNCTION SQLError LIB "odbc32.dll" ALIAS "SQLError"(ByVal env AS LONG, ByVal ldbc AS LONG, ByVal lStmt AS LONG, ByVal SQLState AS LONG, NativeError AS LONG, ByVal Buffer AS LONG, ByVal Buflen AS INTEGER, Outlen AS INTEGER) AS SHORT
     DECLARE FUNCTION SQLCloseCursor LIB "odbc32.dll" ALIAS "SQLCloseCursor"(ByVal lStmt AS LONG) AS SHORT
     DECLARE FUNCTION SQLDrivers LIB "odbc32.dll" ALIAS "SQLDrivers"(ByVal env AS LONG, ByVal dir AS INTEGER, ByVal descrip AS LONG, ByVal bflen AS INTEGER, descriplen AS INTEGER, ByVal attrib AS LONG, ByVal bfattrlen AS INTEGER, attriblen AS INTEGER) AS SHORT

     TYPE qODBC EXTENDS QOBJECT

      glEnv AS LONG
      glDbc AS LONG
      glStmt AS LONG
      sSQL AS STRING
      SQLRet AS SHORT
      sConnect AS STRING
      DriverCount AS INTEGER
      Driver(100) AS STRING
      TableCount AS INTEGER
      Table(100) AS STRING
      FieldCount AS INTEGER
      Field.Name(100) AS STRING
      Field.TypeNum(100) AS INTEGER
      Field.TypeStr(100) AS STRING
      Field.Size(100) AS INTEGER
      Field.DecDigits(100) AS INTEGER
      Field.Nullav(100) AS INTEGER
      Field.Data(100) AS STRING


      SUB ODBCInit
       DIM iStatus AS SHORT

  '1. Allocate ODBC Environment Handle
       SQLRet = SQLAllocEnv(VARPTR(qODBC.glEnv))
       IF SQLRet <> SQL_SUCCESS THEN
        MESSAGEBOX("Unable to initialize ODBC API drivers!", "Error", 0)
       ELSE
   '2. Allocate ODBC Database Handle
        SQLRet=SQLAllocConnect(qODBC.glEnv, VARPTR(qODBC.glDbc))
        IF SQLRet<> SQL_SUCCESS THEN
         MESSAGEBOX("Could not allocate memory for connection Handle!", "Error", 0)
     ' Free the Environment
         iStatus = SQLFreeEnv(qODBC.glEnv)
         IF iStatus = SQL_ERROR THEN
          MESSAGEBOX("Error Freeing Environment From ODBC Drivers", "Error", 0)
         END IF
        ELSE
     '2.1 Get Drivers
         DIM dir AS INTEGER
         DIM descrip AS STRING * MAX_DATA_BUFFER
         DIM descriplen AS INTEGER
         DIM attrib AS STRING * MAX_DATA_BUFFER
         DIM attriblen AS INTEGER

         dir=2'First
         SQLRet=0
         qODBC.DriverCount=0
         WHILE SQLRet=SQL_SUCCESS
          IF SQLRet=SQL_SUCCESS THEN qODBC.DriverCount++
          SQLRet=SQLDrivers(qODBC.glEnv, dir, VARPTR(descrip),MAX_DATA_BUFFER, VARPTR(descriplen), VARPTR(attrib), MAX_DATA_BUFFER, VARPTR(attriblen))
          dir =1'Next
          qODBC.Driver(qODBC.DriverCount)=LEFT$(descrip,descriplen)
         WEND
        END IF
       END IF
      END SUB

      SUB Connect (sConn AS STRING)
       qODBC.sConnect=sConn
  'Connect using the sConnect string - SQLDriverConnect
       DIM sResult AS STRING * 256
       DIM iSize AS INTEGER

       SQLRet = SQLDriverConnect(qODBC.glDbc, 0&, VARPTR(qODBC.sConnect), LEN(qODBC.sConnect), VARPTR(sResult), 255, VARPTR(iSize), 1)
       IF SQLRet < 0 THEN
        MESSAGEBOX("Could not establish connection to ODBC driver!", "Error", 0)
       ELSE
    '4. Allocate ODBC Statement Handle
        SQLRet=SQLAllocStmt(qODBC.glDbc, VARPTR(qODBC.glStmt))
        IF SQLRet<> SQL_SUCCESS THEN
         MESSAGEBOX("Could not allocate memory for a statement handle!", "Error", 0)
        ELSE
     '4.1 Get tables
         DIM tPerform AS LONG
         DIM catalog AS STRING * 0
         DIM schema AS STRING * 0
         DIM tablename AS STRING * 0
         DIM tabletype AS STRING * 5
         DIM iTable AS INTEGER
         DIM tData AS STRING * MAX_DATA_BUFFER
         DIM tOutLen AS LONG

         qODBC.TableCount=0
         tabletype="TABLE"
         SQLRet=SQLTables(qODBC.glStmt, VARPTR(catalog), 0, VARPTR(schema),0, VARPTR(tablename),0, VARPTR(tabletype),5)
         IF SQLRet<> SQL_SUCCESS THEN
          MESSAGEBOX("Could not get Tables!", "Error", 0)
         ELSE
          tPerform = SQL_SUCCESS
          WHILE tPerform = SQL_SUCCESS
           tPerform = SQLFetch(qODBC.glStmt)		' Get the next row of data
           IF tPerform = 65535 OR tPerform = SQL_ERROR THEN
            EXIT WHILE
           ELSE
            IF tPerform = SQL_SUCCESS OR tPerform = SQL_SUCCESS_WITH_INFO THEN
             qODBC.TableCount++
             FOR iTable = 1 TO 3
              iStatus = SQLGetData(qODBC.glStmt, iTable, 1, VARPTR(tData), MAX_DATA_BUFFER, VARPTR(tOutLen))
             NEXT
             qODBC.Table(qODBC.TableCount) = LEFT$(tData, tOutlen) ' tOutlen = -1 if no data or Null data
            END IF
           END IF
          WEND
      'close cursor of tables query
          tPerform = SQLCloseCursor(qODBC.glStmt)
         END IF
        END IF
       END IF
      END SUB

      SUB Query(sSQL AS STRING)
  '5. Execute ODBC Statement - SQLExecDirect
       qODBC.sSQL=sSQL
       DIM lRet AS LONG, lErrNo AS LONG
       DIM iLen AS INTEGER
       DIM sSQLState AS STRING * MAX_DATA_BUFFER
       DIM sErrorMsg AS STRING * MAX_DATA_BUFFER
       DIM sMsg AS STRING


       qODBC.SQLRet=SQLExecDirect(qODBC.glStmt, VARPTR(qODBC.sSQL), LEN(qODBC.sSQL))
       IF qODBC.SQLRet <> SQL_SUCCESS AND qODBC.SQLRet <> SQL_SUCCESS_WITH_INFO THEN
        'Also Check for ODBC Error message - SQLError
        sMsg = "Error Executing SQL Statement" & CHR$(13) & CHR$(10)
        sMsg = sMsg & "ODBC State = " & Trim$(LEFT$(sSQLState, INSTR(sSQLState, CHR$(0)) - 1)) & CHR$(13) & CHR$(10)
        sMsg = sMsg & "ODBC Error Message = " & LEFT$(sErrorMsg, iLen)
        MESSAGEBOX(sMsg, "Error", 0)
       END IF

       DIM bPerform AS LONG
       DIM NumCols AS INTEGER

    'Get number of columns
       bPerform = SQLNumResultCols (qODBC.glStmt, VARPTR(NumCols))
       IF bPerform <> SQL_SUCCESS THEN
        MESSAGEBOX("Could not get columns quantity!", "Error", 0)
       ELSE
        qODBC.FieldCount= NumCols
       END IF

    'Get column descriptor
       DIM icolnum AS INTEGER
       DIM colname AS STRING * MAX_DATA_BUFFER
       DIM colnamelen AS INTEGER
       DIM dtype AS INTEGER
       DIM colsize AS LONG
       DIM decdigits AS INTEGER
       DIM nullav AS INTEGER

       FOR icolnum = 1 TO qODBC.FieldCount
        bPerform = SQLDescribeCol(qODBC.glStmt, icolnum, VARPTR(colname), MAX_DATA_BUFFER, VARPTR(colnamelen), VARPTR(dtype), VARPTR(colsize), VARPTR(decdigits), VARPTR(nullav))
        IF bPerform <> SQL_SUCCESS THEN
         MESSAGEBOX("Could not get column descriptor!", "Error", 0)
        ELSE
         SELECT CASE dtype
         CASE 1
          tipo$= "CHAR"
         CASE 2
          tipo$=" NUMERIC"
         CASE 3
          tipo$="DECIMAL"
         CASE 4
          tipo$="INTEGER"
         CASE 5
          tipo$="SMALLINT"
         CASE 6
          tipo$="FLOAT"
         CASE 7
          tipo$="REAL"
         CASE 8
          tipo$="DOUBLE"
         CASE 9
          tipo$="DATE"
         CASE 10
          tipo$="TIME"
         CASE 11
          tipo$="TIMESTAMP"
         CASE 12
          tipo$="VARCHAR"
         CASE 65535
          tipo$="LONGVARCHAR"
         CASE 65534
          tipo$="BINARY"
         CASE 65533
          tipo$="VARBINARY"
         CASE 65532
          tipo$="LONGVARBINARY"
         CASE 65531
          tipo$="BIGINT"
         CASE 65530
          tipo$="TINYINT"
         CASE 65529
          tipo$="BIT"
         CASE 65456
          tipo$="TYPE_DRIVER_START"
         CASE ELSE
          tipo$="UNKNOWN TYPE"
         END SELECT
         qODBC.Field.Name(icolnum)=LEFT$(colname,colnamelen)
         qODBC.Field.TypeNum(icolnum)=dtype
         qODBC.Field.TypeStr(icolnum)=tipo$
         qODBC.Field.TypeNum(icolnum)=dtype
         qODBC.Field.Size(icolnum)=colsize
         qODBC.Field.DecDigits(icolnum)=decdigits
         qODBC.Field.Nullav(icolnum)=nullav
        END IF
       NEXT
      END SUB

      SUB CloseQuery
    'Close cursor of query
       bPerform = SQLCloseCursor(qODBC.glStmt)
      END SUB

      FUNCTION GetRecord AS INTEGER
   '6. Fetch one row of results from executed ODBC Statement - SQLFetch
    'Code in Step 7.

    '7. Get the Data in each field of the Fetched row - SQLGetData

       DIM bPerform AS LONG
       DIM iColumn AS INTEGER
       DIM sData AS STRING * MAX_DATA_BUFFER
       DIM lOutLen AS LONG
       DIM campo AS STRING
       DIM iStatus AS LONG

       bPerform = SQLFetch(qODBC.glStmt)		' Get the next row of data
       IF bPerform = 65535 OR bPerform = SQL_ERROR THEN
        Result= 0
       ELSE
        IF bPerform = SQL_SUCCESS OR bPerform = SQL_SUCCESS_WITH_INFO THEN
         Result = 1
         FOR iColumn = 1 TO qODBC.FieldCount
          iStatus = SQLGetData(qODBC.glStmt, iColumn, 1, VARPTR(sData), MAX_DATA_BUFFER, VARPTR(lOutLen))
            ' lOutlen = length of the valid data in sData
          campo = LEFT$(sData, lOutlen) ' lOutlen = -1 if no data or Null data
             ' Add the Field Data to Correponding Data Display Controls for this row
          qODBC.Field.Data(iColumn)= campo
         NEXT
        ELSE
         Result= 0
        END IF
       END IF
      END FUNCTION

      SUB CloseDB
       DIM bPerform AS SHORT
       DIM iStatus AS SHORT

    'Release the ODBC Statement Handle
       bPerform = SQLFreeStmt(qODBC.glStmt, SQL_DROP)

    '8. Release the ODBC Statement Handle - SQLFreeSTmt
    'Code in Step 7.
    '***********************************************************************
    'The steps 9 - 11 are for Disconnecting from the SQL Server DataBase
    '***********************************************************************
    '9. Disconnect from ODBC Database - SQLDisconnect
       iStatus = SQLDisconnect(qODBC.glDbc)
      END SUB

      SUB CloseODBC
       DIM iStatus AS SHORT
    '10. Release the ODBC Database Handle - SQLFreeConnect
       iStatus = SQLFreeConnect(qODBC.glDbc)

    '11. Release the ODBC Environment Handle - SQLFreeEnv
       iStatus = SQLFreeEnv(qODBC.glEnv)
      END SUB
     END TYPE

     DIM myDB AS qODBC
     DIM sSQL AS STRING

     myDB.ODBCInit
