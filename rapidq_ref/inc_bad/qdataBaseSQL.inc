'Desenvolvido por Alberto (from Brasil) (netmask@ig.com.br)'
'Vida longa aos programadores brasileiros. Viva a nossa amada patria'
'Nada disso seria poss?el sem a ajuda dos amigos do yahoogroups'
'Congratulations rapidq@yahoogroups.com'
'Thanks Regards Oscar'
'************************************************************'
''
''
'                       qDATABASE
'*** PROPERTIES ***
'qDATABASE.DriverStr
'qDATABASE.DataBaseName
'qDATABASE.TableCount
'qDATABASE.Table.Name(i)
'qDATABASE.Table.Type(i) = TABLE or VIEW
'qDATABASE.Table.RecCount(i)
'qDATABASE.Table.FieldCount(i)
'qDATABASE.Table.FieldName(i,ii) = (Table, Field)
'qDATABASE.Table.FieldType(i,ii) = (Table, Field)
'qDATABASE.Table.FieldSize(i,ii) = (Table, Field)
'qDATABASE.Table.DecDigits(i,ii) = (Table, Field)
'qDATABASE.Table.NullAV(i,ii) = (Table, Field)
'*** METHODS ***
'qDATABASE.GetDataBaseInfo(DataBasePath, DriverNumber) = 0 or dbMSACCESS / 1 or dbDBASE / 2 or dbPARADOX / 3 or dbEXCEL / 4 or dbTEXT
'qDATABASE.OpenDataBase(DataBasePath, DriverNumber) [Ok =  0]
'qDATABASE.GetSTMT
'qDATABASE.CloseDataBase
'************************************************************'
''
''
'                       qSQLTABLE
'*** PROPERTIES ***
'qSQLTABLE.strConnect
'qSQLTABLE.strSQL = Last SQL string
'qSQLTABLE.RecCount
'qSQLTABLE.FieldCount
'qSQLTABLE.FieldName(i)
'qSQLTABLE.PointerPosition
'qSQLTABLE.strData(i) <Data in Text Format>
'*** METHODS ***
'qSQLTABLE.DataBaseConnect(DataBasePath, DriverNumber) = 0 or dbMSACCESS / 1 or dbDBASE / 2 or dbPARADOX / 3 or dbEXCEL / 4 or dbTEXT
'qSQLTABLE.DataBaseExtends(qDATABASE.GetSTMT)
'qSQLTABLE.ExecSQL(SQL)
'qSQLTABLE.OpenSQL(SQL)
'qSQLTABLE.MoveFirst
'qSQLTABLE.MoveLast
'qSQLTABLE.MoveNext
'qSQLTABLE.MovePreview
'qSQLTABLE.SeekRec(RecNumber) <= Not Implemented
'qSQLTABLE.PointerPosition
'qSQLTABLE.CloseSQL <with OpenSQL>
'qSQLTABLE.CloseDataBase
'************************************************************'
'Driver Number:
     CONST dbMSACCESS = 0
     CONST dbDBASE = 1
     CONST dbPARADOX = 2
     CONST dbEXCEL = 3
     CONST dbTEXT = 4

     FUNCTION UseDriver(DN AS INTEGER, DBName AS STRING) AS STRING ' Err = -1
      DIM DriverN(5) AS STRING

      IF DN > 5 OR DN < 0 THEN UseDriver = "-1": EXIT FUNCTION

      DriverN(dbMSACCESS) = "DRIVER={Microsoft Access Driver (*.mdb)};DBQ="
      DriverN(dbDBASE) = "DRIVER={Microsoft dBase Driver (*.dbf)};DBQ="
      DriverN(dbPARADOX) = "DRIVER={Microsoft Paradox Driver (*.db )};DBQ="
      DriverN(dbEXCEL) = "DRIVER={Driver para o Microsoft Excel(*.xls)};DBQ="
      DriverN(dbTEXT) = "DRIVER={Microsoft Text Driver (*.txt; *.csv)};DBQ="

      UseDriver = DriverN(DN) + DBName + ";PWD=; UID=;"

     END FUNCTION
'************************************************************'


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
     CONST SQL_ATTR_CURSOR_TYPE = 6
     CONST SQL_CURSOR_KEYSET_DRIVEN = 1
     CONST SQL_FETCH_NEXT = 1
     CONST SQL_FETCH_PRIOR = 4
     CONST SQL_FETCH_FIRST = 2
     CONST SQL_FETCH_LAST = 3
     CONST SQL_FETCH_ABSOLUTE = 5
     CONST SQL_FETCH_RELATIVE = 6
     CONST SQL_FETCH_BOOKMARK = 8


'ODBC Declarations
     DECLARE FUNCTION SQLAllocEnv LIB "odbc32.dll" ALIAS "SQLAllocEnv"(env AS LONG) AS SHORT
     DECLARE FUNCTION SQLFreeEnv LIB "odbc32.dll" ALIAS "SQLFreeEnv"(BYVAL env AS LONG) AS SHORT
     DECLARE FUNCTION SQLAllocConnect LIB "odbc32.dll" ALIAS "SQLAllocConnect"(BYVAL env AS LONG, ldbc AS LONG) AS SHORT
     DECLARE FUNCTION SQLDrivers LIB "odbc32.dll" ALIAS "SQLDrivers"(BYVAL env AS LONG, BYVAL dir AS INTEGER, BYVAL descrip AS LONG, BYVAL bflen AS INTEGER, descriplen AS INTEGER, BYVAL attrib AS LONG, BYVAL bfattrlen AS INTEGER, attriblen AS INTEGER) AS SHORT
     DECLARE FUNCTION SQLDriverConnect LIB "odbc32.dll" ALIAS "SQLDriverConnect"(BYVAL ldbc AS LONG, BYVAL hWnd AS LONG, BYVAL szCSIn AS LONG, BYVAL cbCSIn AS INTEGER, BYVAL szCSOut AS LONG, BYVAL cbCSMax AS INTEGER, cbCSOut AS LONG, BYVAL f AS INTEGER) AS SHORT
     DECLARE FUNCTION SQLAllocStmt LIB "odbc32.dll" ALIAS "SQLAllocStmt"(BYVAL ldbc AS LONG, lStmt AS LONG) AS SHORT
     DECLARE FUNCTION SQLTables LIB "odbc32.dll" ALIAS "SQLTables"(BYVAL lStmt AS LONG, BYVAL q AS LONG, BYVAL cbq AS INTEGER, BYVAL o AS LONG, BYVAL cbo AS INTEGER, BYVAL t AS LONG, BYVAL cbt AS INTEGER, BYVAL tt AS LONG, BYVAL cbtt AS INTEGER) AS SHORT
     DECLARE FUNCTION SQLFetch LIB "odbc32.dll" ALIAS "SQLFetch"(BYVAL lStmt AS LONG) AS SHORT
     DECLARE FUNCTION SQLFetchScroll LIB "odbc32.dll" ALIAS "SQLFetchScroll"(BYVAL lStmt AS LONG, fOrnt AS SHORT, fOffSet AS INTEGER) AS SHORT
     DECLARE FUNCTION SQLGetData LIB "odbc32.dll" ALIAS "SQLGetData"(BYVAL lStmt AS LONG, BYVAL col AS INTEGER, BYVAL wConvType AS INTEGER, BYVAL lpbBuf AS LONG, BYVAL dwbuflen AS LONG, lpcbout AS LONG) AS SHORT
     DECLARE FUNCTION SQLCloseCursor LIB "odbc32.dll" ALIAS "SQLCloseCursor"(BYVAL lStmt AS LONG) AS SHORT
     DECLARE FUNCTION SQLFreeStmt LIB "odbc32.dll" ALIAS "SQLFreeStmt"(BYVAL lStmt AS LONG, BYVAL EndOption AS INTEGER) AS SHORT
     DECLARE FUNCTION SQLDisconnect LIB "odbc32.dll" ALIAS "SQLDisconnect"(BYVAL ldbc AS LONG) AS SHORT
     DECLARE FUNCTION SQLFreeConnect LIB "odbc32.dll" ALIAS "SQLFreeConnect"(BYVAL ldbc AS LONG) AS SHORT
     DECLARE FUNCTION SQLExecDirect LIB "odbc32.dll" ALIAS "SQLExecDirect"(BYVAL lStmt AS LONG, BYVAL sqlString AS LONG, BYVAL sqlstrlen AS LONG) AS SHORT
     DECLARE FUNCTION SQLNumResultCols LIB "odbc32.dll" ALIAS "SQLNumResultCols"(BYVAL lStmt AS LONG, NumCols AS LONG) AS SHORT
     DECLARE FUNCTION SQLDescribeCol LIB "odbc32.dll" ALIAS "SQLDescribeCol"(BYVAL lStmt AS LONG, BYVAL colnum AS INTEGER, BYVAL colname AS LONG, BYVAL Buflen AS INTEGER, colnamelen AS INTEGER, dtype AS INTEGER, dl AS LONG, ds AS INTEGER, n AS INTEGER) AS SHORT
     DECLARE FUNCTION SQLSetStmtAttr LIB "odbc32.dll" ALIAS "SQLSetStmtAttr"(BYVAL lStmt AS LONG, Attrib AS INTEGER, VlPtr AS INTEGER, sqlstrlen AS INTEGER) AS SHORT
     DECLARE FUNCTION DataTypeStr(DataTypeNum AS INTEGER) AS STRING

'--------------------------------------- BEGIN OBJECT qDATABASE'================
     TYPE qDATABASE EXTENDS QOBJECT

PUBLIC:

      DriverStr AS STRING
      DataBaseName AS STRING
      TableCount AS INTEGER
      Table.Name(150) AS STRING
      Table.TYPE(150) AS STRING
      Table.RecCount(150) AS INTEGER
      Table.FieldCount(150) AS INTEGER
      Table.FieldName(150,255) AS STRING
      Table.FieldType(150,255) AS STRING
      Table.FieldSize(150,255) AS INTEGER
      Table.DecDigits(150,255) AS INTEGER
      Table.NullAV(150,255) AS INTEGER

PRIVATE:
      GLENV AS LONG
      GLDBC AS LONG
      GLSTMT AS LONG
'-------------------------------------------------------------------------------'
      FUNCTION ODBCInit  AS STRING ' Ok = 0
       DIM iStatus AS SHORT
       DIM SQLRET AS SHORT
       DIM Res AS STRING

       Res = "0"

      '1. Allocate ODBC Environment Handle
       SQLRet = SQLAllocEnv(VARPTR(qDATABASE.glEnv))
       IF SQLRet <> SQL_SUCCESS THEN
        Res = "Error: Unable to initialize ODBC API drivers!"
       ELSE
        '2. Allocate ODBC Database Handle
        SQLRet=SQLAllocConnect(qDATABASE.glEnv, VARPTR(qDATABASE.glDbc))
        IF SQLRet<> SQL_SUCCESS THEN
         Res = "Error: Could not allocate memory for connection Handle!"
          ' Free the Environment
         iStatus = SQLFreeEnv(qDATABASE.glEnv)
         IF iStatus = SQL_ERROR THEN
          Res = "Error Freeing Environment From ODBC Drivers"
         END IF
        END IF
       END IF

       qDATABASE.ODBCInit = Res
      END FUNCTION
'-------------------------------------------------------------------------------'
      SUB CloseODBC
       DIM iStatus AS SHORT

       iStatus = SQLFreeConnect(qDATABASE.glDbc)
       iStatus = SQLFreeEnv(qDATABASE.glEnv)
      END SUB
'-------------------------------------------------------------------------------'
      FUNCTION Connect (DB_Name AS STRING, DriverNumber AS INTEGER) AS STRING 'Ok = 0
       DIM SQLRET AS SHORT
       DIM Res AS STRING

       Res = "0"

       qDATABASE.DataBaseName=DB_Name
       qDATABASE.DriverStr=UseDriver(DriverNumber, DB_Name)
       IF qDATABASE.DriverStr <> "-1" THEN
        'Connect using the string - SQLDriverConnect
        DIM sResult AS STRING * 256
        DIM iSize AS INTEGER

        SQLRet = SQLDriverConnect(qDATABASE.glDbc, 0&, VARPTR(qDATABASE.DriverStr), LEN(qDATABASE.DriverStr), VARPTR(sResult), 255, VARPTR(iSize), 1)
        IF SQLRet < 0 THEN
         Res = "Error: Could not establish connection to ODBC driver!"
        ELSE
          '4. Allocate ODBC Statement Handle
         SQLRet=SQLAllocStmt(qDATABASE.glDbc, VARPTR(qDATABASE.glStmt))
         IF SQLRet<> SQL_SUCCESS THEN
          Res = "Error: Could not allocate memory for a statement handle!"
         ELSE
          SQLSetStmtAttr(qDATABASE.glStmt, SQL_ATTR_CURSOR_TYPE, SQL_CURSOR_KEYSET_DRIVEN, 0)
            '4.1 Get tables
          DIM tPerform AS LONG
          DIM catalog AS STRING * 0
          DIM schema AS STRING * 0
          DIM tablename AS STRING * 0
          DIM tabletype AS STRING * 5
          DIM iTable AS INTEGER
          DIM tData AS STRING * MAX_DATA_BUFFER
          DIM tOutLen AS LONG
          DIM NumCols AS INTEGER
          DIM IStatus AS INTEGER

          qDATABASE.TableCount=-1

          tabletype="TABLE"
          SQLRet=SQLTables(qDATABASE.glStmt, VARPTR(catalog), 0, VARPTR(schema),0, VARPTR(tablename),0, VARPTR(tabletype),5)
          IF SQLRet<> SQL_SUCCESS THEN
           Res = "Error: Could not get Tables!"
          ELSE
           tPerform = SQL_SUCCESS
           WHILE tPerform = SQL_SUCCESS
            tPerform = SQLFetch(qDATABASE.glStmt) ' Get the next row of data
            IF tPerform = 65535 OR tPerform = SQL_ERROR THEN
             EXIT WHILE
            ELSE
             IF tPerform = SQL_SUCCESS OR tPerform = SQL_SUCCESS_WITH_INFO THEN
              qDATABASE.TableCount++
              FOR iTable = 1 TO 3
               iStatus = SQLGetData(qDATABASE.glStmt, iTable, 1, VARPTR(tData), MAX_DATA_BUFFER, VARPTR(tOutLen))
              NEXT
              qDATABASE.Table.Name(qDATABASE.TableCount) = LEFT$(tData, tOutlen) ' tOutlen = -1 if no data or Null data
              qDATABASE.Table.TYPE(qDATABASE.TableCount) = "TABLE"
             END IF
            END IF
           WEND
              'close cursor of tables query
           tPerform = SQLCloseCursor(qDATABASE.glStmt)
          END IF

          tabletype="VIEW"
          SQLRet=SQLTables(qDATABASE.glStmt, VARPTR(catalog), 0, VARPTR(schema),0, VARPTR(tablename),0, VARPTR(tabletype),5)
          IF SQLRet = SQL_SUCCESS THEN
           tPerform = SQL_SUCCESS
           WHILE tPerform = SQL_SUCCESS
            tPerform = SQLFetch(qDATABASE.glStmt) ' Get the next row of data
            IF tPerform = 65535 OR tPerform = SQL_ERROR THEN
             EXIT WHILE
            ELSE
             IF tPerform = SQL_SUCCESS OR tPerform = SQL_SUCCESS_WITH_INFO THEN
              qDATABASE.TableCount++
              FOR iTable = 1 TO 3
               iStatus = SQLGetData(qDATABASE.glStmt, iTable, 1, VARPTR(tData), MAX_DATA_BUFFER, VARPTR(tOutLen))
              NEXT
              qDATABASE.Table.Name(qDATABASE.TableCount) = LEFT$(tData, tOutlen) ' tOutlen = -1 if no data or Null data
              qDATABASE.Table.TYPE(qDATABASE.TableCount)  = "VIEW"
             END IF
            END IF
           WEND
              'close cursor of tables query
           tPerform = SQLCloseCursor(qDATABASE.glStmt)
          END IF
          qDATABASE.TableCount++
         END IF
        END IF
       ELSE
        Res = "Driver Number Error "
       END IF
       qDATABASE.Connect = Res
      END FUNCTION
'-------------------------------------------------------------------------------'
      SUB CloseDB
       DIM iStatus AS SHORT
       iStatus = SQLDisconnect(qDATABASE.glDbc)
      END SUB
'-------------------------------------------------------------------------------'
      FUNCTION GetTableInfo AS STRING ' Ok = 0
       DIM i AS INTEGER
       DIM sSQL AS STRING
       DIM SQLRet AS SHORT
       DIM bPerform AS LONG
       DIM NumCols AS INTEGER
       DIM NumRec AS INTEGER
       DIM Res AS STRING

       Res = "0"

       FOR i = 0 TO qDATABASE.TableCount - 1
        sSQL = "SELECT * FROM [" + qDATABASE.Table.Name(i) + "]"
        SQLRet=SQLExecDirect(qDATABASE.glStmt, VARPTR(sSQL), LEN(sSQL))
        IF SQLRet <> SQL_SUCCESS AND SQLRet <> SQL_SUCCESS_WITH_INFO THEN
         qDATABASE.GetTableInfo = "Error: Table Error"
         EXIT FUNCTION
        END IF

        bPerform = SQLNumResultCols (qDATABASE.glStmt, VARPTR(NumCols))
        IF bPerform <> SQL_SUCCESS THEN
         qDATABASE.GetTableInfo = "Error: Could not get columns quantity!"
         bPerform = SQLCloseCursor(qDATABASE.glStmt)
         EXIT FUNCTION
        ELSE
         qDATABASE.Table.FieldCount(i) = NumCols
        END IF

        NumRec = -1
        bPerform = SQL_SUCCESS
        WHILE bPerform = SQL_SUCCESS
         NumRec++
         bPerform = SQLFetch(qDATABASE.glStmt)
        WEND
        IF NumRec> 0 THEN qDATABASE.Table.RecCount(i) = NumRec ELSE qDATABASE.Table.RecCount(i) = 0

        DIM icolnum AS INTEGER
        DIM colname AS STRING * MAX_DATA_BUFFER
        DIM colnamelen AS INTEGER
        DIM dtype AS INTEGER
        DIM colsize AS LONG
        DIM decdigits AS INTEGER
        DIM nullav AS INTEGER

        FOR icolnum = 1 TO NumCols
         bPerform = SQLDescribeCol(qDATABASE.glStmt, icolnum, VARPTR(colname), MAX_DATA_BUFFER, VARPTR(colnamelen), VARPTR(dtype), VARPTR(colsize), VARPTR(decdigits), VARPTR(nullav))
         IF bPerform <> SQL_SUCCESS THEN
          qDATABASE.GetTableInfo = "Error: Could not get column descriptor!"
          bPerform = SQLCloseCursor(qDATABASE.glStmt)
          EXIT FUNCTION
         END IF
         qDATABASE.Table.FieldName(i,icolnum)=LEFT$(colname,colnamelen)
         qDATABASE.Table.FieldType(i,icolnum)=DataTypeStr(dtype)
         qDATABASE.Table.FieldSize(i,icolnum)=colsize
         qDATABASE.Table.DecDigits(i,icolnum)=decdigits
         qDATABASE.Table.NullAV(i,icolnum)=nullav
        NEXT icolnum

        bPerform = SQLCloseCursor(qDATABASE.glStmt)
       NEXT i
       bPerform = SQLFreeStmt(qDATABASE.glStmt, SQL_DROP)
       qDATABASE.GetTableInfo = Res
      END FUNCTION
'-------------------------------------------------------------------------------'

PUBLIC:
      FUNCTION GetDataBaseInfo(DatabasePath AS STRING, DriverNum AS INTEGER ) AS STRING
       DIM Res AS STRING
       Res = "0"

       Res = qDATABASE.ODBCInit
       IF Res <> "0" THEN
        qDATABASE.GetDataBaseInfo = Res
        EXIT FUNCTION
       END IF

       Res = qDATABASE.Connect (DatabasePath, DriverNum)
       IF Res <> "0" THEN
        qDATABASE.GetDataBaseInfo = Res
        qDATABASE.CloseODBC
        EXIT FUNCTION
       END IF

       Res = qDATABASE.GetTableInfo
       IF Res <> "0" THEN
        qDATABASE.GetDataBaseInfo = Res
        qDATABASE.CloseDB
        qDATABASE.CloseODBC
        EXIT FUNCTION
       END IF

       qDATABASE.CloseDB
       qDATABASE.CloseODBC

       qDATABASE.GetDataBaseInfo = Res
      END FUNCTION

      FUNCTION OpenDataBase(DatabasePath AS STRING, DriverNum AS INTEGER ) AS STRING
       DIM Res AS STRING

       Res = qDATABASE.ODBCInit
       IF Res <> "0" THEN
        qDATABASE.OpenDataBase = Res
        EXIT FUNCTION
       END IF

       Res = qDATABASE.Connect (DatabasePath, DriverNum)
       IF Res <> "0" THEN
        qDATABASE.OpenDataBase = Res
        qDATABASE.CloseODBC
        EXIT FUNCTION
       END IF

       Res = qDATABASE.GetTableInfo
       IF Res <> "0" THEN
        qDATABASE.OpenDataBase = Res
        qDATABASE.CloseDB
        qDATABASE.CloseODBC
        EXIT FUNCTION
       END IF

       qDATABASE.OpenDataBase = "0"
      END FUNCTION

      SUB CloseDataBase
       qDATABASE.CloseDB
       qDATABASE.CloseODBC
      END SUB

      FUNCTION GetSTMT() AS LONG
       DIM nSTMT AS LONG
       DIM SQLRET AS SHORT

       SQLRet=SQLAllocStmt(qDATABASE.glDbc, VARPTR(nSTMT))
       IF SQLRet <> SQL_SUCCESS THEN
        nSTMT = -1
       ELSE
        SQLSetStmtAttr(nSTMT, SQL_ATTR_CURSOR_TYPE, SQL_CURSOR_KEYSET_DRIVEN, 0)
       END IF
       qDATABASE.GetSTMT = nSTMT
      END FUNCTION
     END TYPE

     FUNCTION DataTypeStr(DataTypeNum AS INTEGER) AS STRING
      SELECT CASE DataTypeNum
      CASE 1
       DataTypeStr = "CHAR"
      CASE 2
       DataTypeStr = " NUMERIC"
      CASE 3
       DataTypeStr = "DECIMAL"
      CASE 4
       DataTypeStr = "INTEGER"
      CASE 5
       DataTypeStr = "SMALLINT"
      CASE 6
       DataTypeStr = "FLOAT"
      CASE 7
       DataTypeStr = "REAL"
      CASE 8
       DataTypeStr = "DOUBLE"
      CASE 9
       DataTypeStr = "DATE"
      CASE 10
       DataTypeStr = "TIME"
      CASE 11
       DataTypeStr = "TIMESTAMP"
      CASE 12
       DataTypeStr = "VARCHAR"
      CASE 65535
       DataTypeStr = "LONGVARCHAR"
      CASE 65534
       DataTypeStr = "BINARY"
      CASE 65533
       DataTypeStr = "VARBINARY"
      CASE 65532
       DataTypeStr = "LONGVARBINARY"
      CASE 65531
       DataTypeStr = "BIGINT"
      CASE 65530
       DataTypeStr = "TINYINT"
      CASE 65529
       DataTypeStr = "BIT"
      CASE 65456
       DataTypeStr = "TYPE_DRIVER_START"
      CASE ELSE
       DataTypeStr = "UNKNOWN TYPE"
      END SELECT
     END FUNCTION
'--------------------------------------- END OBJECT qDATABASE' =================

'--------------------------------------- BEGIN OBJECT qSQLTABLE'================
     TYPE qSQLTABLE EXTENDS QOBJECT

PUBLIC:
      strConnect AS STRING
      strSQL AS STRING
      RecCount AS INTEGER
      FieldCount AS INTEGER
      FieldName(255) AS STRING
      strData(255) AS STRING
      PointerPosition AS INTEGER

PRIVATE:
      GLENV AS LONG
      GLDBC AS LONG
      GLSTMT AS LONG
      EXTENDS AS SHORT

'-------------------------------------------------------------------------------'
      FUNCTION ODBCInit AS STRING ' Ok = 0
       DIM iStatus AS SHORT
       DIM SQLRET AS SHORT
       DIM Res AS STRING

       Res = "0"
      '1. Allocate ODBC Environment Handle
       SQLRet = SQLAllocEnv(VARPTR(qSQLTABLE.glEnv))
       IF SQLRet <> SQL_SUCCESS THEN
        Res = "Error: Unable to initialize ODBC API drivers!"
       ELSE
        '2. Allocate ODBC Database Handle
        SQLRet=SQLAllocConnect(qSQLTABLE.glEnv, VARPTR(qSQLTABLE.glDbc))
        IF SQLRet<> SQL_SUCCESS THEN
         Res = "Error: Could not allocate memory for connection Handle!"
          ' Free the Environment
         iStatus = SQLFreeEnv(qSQLTABLE.glEnv)
         IF iStatus = SQL_ERROR THEN
          Res = "Error Freeing Environment From ODBC Drivers"
         END IF
        END IF
       END IF
       qSQLTABLE.ODBCInit = Res
      END FUNCTION
'-------------------------------------------------------------------------------'
      SUB CloseODBC
       IF qSQLTABLE.EXTENDS = 1 THEN EXIT SUB
       DIM iStatus AS SHORT

       iStatus = SQLFreeConnect(qSQLTABLE.glDbc)
       iStatus = SQLFreeEnv(qSQLTABLE.glEnv)
      END SUB
'-------------------------------------------------------------------------------'
      FUNCTION Connect (DB_Name AS STRING, DriverNumber AS INTEGER) AS STRING ' Ok = 0
       DIM SQLRET AS SHORT
       DIM Res AS STRING

       Res = "0"

       qSQLTABLE.strConnect=UseDriver(DriverNumber, DB_Name)
       IF qSQLTABLE.strConnect <> "-1" THEN
          'Connect using the string - SQLDriverConnect
        DIM sResult AS STRING * 256
        DIM iSize AS INTEGER

        SQLRet = SQLDriverConnect(qSQLTABLE.glDbc, 0&, VARPTR(qSQLTABLE.strConnect), LEN(qSQLTABLE.strConnect), VARPTR(sResult), 255, VARPTR(iSize), 1)
        IF SQLRet < 0 THEN MESSAGEBOX("Could not establish connection to ODBC driver!", "Error", 0)

        SQLRet=SQLAllocStmt(qSQLTABLE.glDbc, VARPTR(qSQLTABLE.glStmt))
        IF SQLRet<> SQL_SUCCESS THEN MESSAGEBOX("Could not allocate memory for a statement handle!", "Error", 0)

        SQLSetStmtAttr(qSQLTABLE.glStmt, SQL_ATTR_CURSOR_TYPE, SQL_CURSOR_KEYSET_DRIVEN, 0)
       ELSE
        Res = "Driver Number Error "
       END IF
       qSQLTABLE.Connect = Res
      END FUNCTION
'-------------------------------------------------------------------------------'

      SUB CloseDB
       DIM bPerform AS SHORT
       DIM iStatus AS SHORT

       bPerform = SQLFreeStmt(qSQLTABLE.glStmt, SQL_DROP)
       IF qSQLTABLE.EXTENDS = 1 THEN EXIT SUB
       iStatus = SQLDisconnect(qSQLTABLE.glDbc)
      END SUB
'-------------------------------------------------------------------------------'
      FUNCTION GetData() AS STRING 'Ok = 0
       IF qSQLTABLE.FieldCount < 1 THEN
        qSQLTABLE.GetData = "Error: Column Count"
        EXIT FUNCTION
       END IF

       DIM iStatus AS SHORT
       DIM sData AS STRING * MAX_DATA_BUFFER
       DIM lOutLen AS LONG
       DIM stData AS STRING

       DIM i AS INTEGER

       IF qSQLTABLE.RecCount > 0 THEN
        FOR i = 1 TO qSQLTABLE.FieldCount
         iStatus = SQLGetData(qSQLTABLE.glStmt, i, 1, VARPTR(sData), MAX_DATA_BUFFER, VARPTR(lOutLen))
         stData=""
         stData = LEFT$(sData, lOutlen) ' lOutlen = -1 if no data or Null data
         qSQLTABLE.strData(i) = stData
        NEXT i
       ELSE
        FOR i = 1 TO qSQLTABLE.FieldCount
         qSQLTABLE.strData(i) = ""
        NEXT i
       END IF
       qSQLTABLE.GetData = "0"
      END FUNCTION
'-------------------------------------------------------------------------------'
PUBLIC:
      FUNCTION DataBaseConnect(DatabasePath AS STRING, DriverNum AS INTEGER) AS STRING
       DIM Res AS STRING

       Res = qSQLTABLE.ODBCInit
       IF Res <>"0" THEN
        qSQLTABLE.DataBaseConnect = Res
        EXIT FUNCTION
       END IF

       Res = qSQLTABLE.Connect (DatabasePath, DriverNum)
       IF Res <>"0" THEN
        qSQLTABLE.DataBaseConnect = Res
        qSQLTABLE.CloseODBC
        EXIT FUNCTION
       END IF

       qSQLTABLE.EXTENDS = 0
       qSQLTABLE.DataBaseConnect = "0"

      END FUNCTION
'-------------------------------------------------------------------------------'
      FUNCTION DataBaseExtends(DBSTMT AS LONG) AS STRING
       IF DBSTMT <> -1 THEN
        qSQLTABLE.GLSTMT = DBSTMT
        qSQLTABLE.EXTENDS = 1
        qSQLTABLE.DataBaseExtends = "0"
       ELSE
        qSQLTABLE.DataBaseExtends = "qDATABASE Error: Could not allocate memory for a statement handle!"
       END IF
      END FUNCTION
'-------------------------------------------------------------------------------'
      FUNCTION ExecSQL(xSQL AS STRING) AS STRING
       DIM sMsg AS STRING
       DIM SQLRET AS SHORT
       DIM bPerform AS LONG
       DIM Res AS STRING

       Res = "0"

       qSQLTABLE.strSQL = xSQL

       SQLRet=SQLExecDirect(qSQLTABLE.glStmt, VARPTR(qSQLTABLE.strSQL), LEN(qSQLTABLE.strSQL))
       IF SQLRet <> SQL_SUCCESS AND SQLRet <> SQL_SUCCESS_WITH_INFO THEN
        Res = "Error: SQL Execute Error or SQL Syntax Error"
       END IF

       bPerform = SQLCloseCursor(qSQLTABLE.glStmt)
       qSQLTABLE.ExecSQL = Res

      END FUNCTION
'-------------------------------------------------------------------------------'
      FUNCTION OpenSQL(sSQL AS STRING) AS STRING
       DIM SQLRET AS SHORT
       DIM bPerform AS LONG
       DIM NumCols AS INTEGER
       DIM NumRec AS INTEGER

       qSQLTABLE.strSQL = sSQL

       SQLRet = SQLExecDirect(qSQLTABLE.glStmt, VARPTR(qSQLTABLE.strSQL), LEN(qSQLTABLE.strSQL))
       IF SQLRet <> SQL_SUCCESS AND SQLRet <> SQL_SUCCESS_WITH_INFO THEN
        qSQLTABLE.OpenSQL = "Error: SQL Execute Error or SQL Syntax Error"
        qSQLTABLE.RecCount = 0
        qSQLTABLE.PointerPosition = -1
        qSQLTABLE.GetData()
        EXIT FUNCTION
       END IF

       bPerform = SQLNumResultCols (qSQLTABLE.glStmt, VARPTR(NumCols))
       IF bPerform <> SQL_SUCCESS THEN
        qSQLTABLE.OpenSQL = "SQL Error: Could not get columns quantity!"
        qSQLTABLE.RecCount = 0
        qSQLTABLE.PointerPosition = -1
        qSQLTABLE.GetData()
        EXIT FUNCTION
       END IF
       qSQLTABLE.FieldCount = NumCols

       DIM icolnum AS INTEGER
       DIM colname AS STRING * MAX_DATA_BUFFER
       DIM colnamelen AS INTEGER
       DIM dtype AS INTEGER
       DIM colsize AS LONG
       DIM decdigits AS INTEGER
       DIM nullav AS INTEGER


       FOR icolnum = 1 TO NumCols
        bPerform = SQLDescribeCol(qSQLTABLE.glStmt, icolnum, VARPTR(colname), MAX_DATA_BUFFER, VARPTR(colnamelen), VARPTR(dtype), VARPTR(colsize), VARPTR(decdigits), VARPTR(nullav))
        IF bPerform <> SQL_SUCCESS THEN
         qSQLTABLE.OpenSQL = "SQL Error: Could not get column descriptor!"
         qSQLTABLE.RecCount = 0
         qSQLTABLE.PointerPosition = -1
         qSQLTABLE.GetData()
         EXIT FUNCTION
        END IF
        qSQLTABLE.FieldName(icolnum) = LEFT$(colname,colnamelen)
       NEXT icolnum

       NumRec = -1
       bPerform = SQL_SUCCESS
       WHILE bPerform = SQL_SUCCESS
        NumRec++
        bPerform = SQLFetch(qSQLTABLE.glStmt)
       WEND
       qSQLTABLE.RecCount = NumRec

       IF NumRec >0 THEN
        bPerform = SQLFetchScroll(qSQLTABLE.glStmt, SQL_FETCH_FIRST, 0)
        IF bPerform <> SQL_SUCCESS AND bPerform <> SQL_SUCCESS_WITH_INFO THEN
         qSQLTABLE.OpenSQL = "SQL Error: Table Start Error!"
         qSQLTABLE.RecCount = 0
         qSQLTABLE.PointerPosition = -1
         qSQLTABLE.GetData()
         EXIT FUNCTION
        END IF
       END IF

       qSQLTABLE.PointerPosition = 0
       qSQLTABLE.GetData()
       qSQLTABLE.OpenSQL = "0"

      END FUNCTION
'-------------------------------------------------------------------------------'
      FUNCTION MoveFirst AS STRING
       DIM bPerform AS LONG
       IF qSQLTABLE.PointerPosition > 0 THEN
        bPerform = SQLFetchScroll(qSQLTABLE.glStmt, SQL_FETCH_FIRST, 0)
        IF bPerform <> SQL_SUCCESS AND bPerform <> SQL_SUCCESS_WITH_INFO THEN
         qSQLTABLE.MoveFirst = "MoveFirst: Table SCROLL Error!"
         EXIT FUNCTION
        END IF
        qSQLTABLE.PointerPosition = 0
        qSQLTABLE.GetData()
       END IF
       qSQLTABLE.MoveFirst = "0"
      END FUNCTION
'-------------------------------------------------------------------------------'
      FUNCTION MoveLast AS STRING
       DIM bPerform AS LONG
       IF qSQLTABLE.PointerPosition < qSQLTABLE.RecCount - 1 THEN
        bPerform = SQLFetchScroll(qSQLTABLE.glStmt, SQL_FETCH_LAST, 0)
        IF bPerform <> SQL_SUCCESS AND bPerform <> SQL_SUCCESS_WITH_INFO THEN
         qSQLTABLE.MoveLast = "MoveLast: Table SCROLL Error!"
         EXIT FUNCTION
        END IF
        qSQLTABLE.PointerPosition = qSQLTABLE.RecCount - 1
        qSQLTABLE.GetData()
       END IF
       qSQLTABLE.MoveLast = "0"
      END FUNCTION
'-------------------------------------------------------------------------------'
      FUNCTION MoveNext AS STRING
       DIM bPerform AS LONG
       IF qSQLTABLE.PointerPosition < qSQLTABLE.RecCount - 1 THEN
        bPerform = SQLFetchScroll(qSQLTABLE.glStmt, SQL_FETCH_NEXT, 0)
        IF bPerform <> SQL_SUCCESS AND bPerform <> SQL_SUCCESS_WITH_INFO THEN
         qSQLTABLE.MoveNext = "MoveNext: Table SCROLL Error!"
         EXIT FUNCTION
        END IF
        qSQLTABLE.PointerPosition = qSQLTABLE.PointerPosition + 1
        qSQLTABLE.GetData()
       END IF
       qSQLTABLE.MoveNext = "0"
      END FUNCTION
'-------------------------------------------------------------------------------'
      FUNCTION MovePreview AS STRING
       DIM bPerform AS LONG
       IF qSQLTABLE.PointerPosition > 0 THEN
        bPerform = SQLFetchScroll(qSQLTABLE.glStmt, SQL_FETCH_PRIOR, 0)
        IF bPerform <> SQL_SUCCESS AND bPerform <> SQL_SUCCESS_WITH_INFO THEN
         qSQLTABLE.MovePreview = "MovePreview: Table SCROLL Error!"
         EXIT FUNCTION
        END IF
        qSQLTABLE.PointerPosition = qSQLTABLE.PointerPosition - 1
        qSQLTABLE.GetData()
       END IF
       qSQLTABLE.MovePreview = "0"
      END FUNCTION
'-------------------------------------------------------------------------------'
      SUB CloseSQL
       DIM bPerform AS LONG
       DIM i AS INTEGER


       bPerform = SQLCloseCursor(qSQLTABLE.glStmt)
       qSQLTABLE.strSQL=""

       FOR i = 1 TO qSQLTABLE.FieldCount
        qSQLTABLE.FieldName(i)=""
        qSQLTABLE.strData(i)=""
       NEXT i

       qSQLTABLE.FieldCount=0
      END SUB
'-------------------------------------------------------------------------------'
      SUB CloseDataBase
       qSQLTABLE.CloseDB
       qSQLTABLE.CloseODBC
      END SUB
'-------------------------------------------------------------------------------'

     END TYPE
'--------------------------------------- END OBJECT qSQLTABLE' ====================

