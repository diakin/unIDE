' MYSQL.INC  -- Include file for MySQL programs


$IFNDEF __MYSQLINC

$DEFINE __MYSQLINC

'------------------------ QMYSQL Variables --------------------------
'-- Field.Flag
const Not_Null_Flag       = 1
const Pri_Key_Flag        = 2
const Unique_Key_Flag     = 4
const Multiple_Key_Flag   = 8
const Blob_Key_Flag       = 16
const Unsigned_Key_Flag   = 32
const ZeroFill_Flag       = 64
const Binary_Flag         = 128
const Enum_Flag           = 256
const Auto_Increment_Flag = 512
const TimeStamp_Flag      = 1024
const Set_Flag            = 2048
const Part_Key_Flag       = 16384
const Group_Flag          = 32768
const Unique_Flag         = 65536

'-- Field.Type
const Field_Type_Decimal   = 0
const Field_Type_Tiny      = 1
const Field_Type_Short     = 2
const Field_Type_Long      = 3
const Field_Type_Float     = 4
const Field_Type_Double    = 5
const Field_Type_Null      = 6
const Field_Type_TimeStamp = 7
const Field_Type_LongLong  = 8
const Field_Type_Int24     = 9
const Field_Type_Date      = 10
const Field_Type_Time      = 11
const Field_Type_DateTime  = 12
const Field_Type_Year      = 13
const Field_Type_NewDate   = 14
const Field_Type_Enum      = 247
const Field_Type_Set       = 248
const Field_Type_TinyBlob  = 249
const Field_Type_MediumBlobk = 250
const Field_Type_LongBlob  = 251
const Field_Type_Blob      = 252
const Field_Type_VarString = 253
const Field_Type_String    = 254

'-- Refresh options
const Refresh_Grant       = 1         '' Refresh grant tables
const Refresh_Log         = 2         '' Start on new log file
const Refresh_Table       = 4         '' Close all tables
const Refresh_Hosts       = 8         '' Flush host cache
const Refresh_Status      = 16        '' Flush status variables
const Refresh_Fast        = 32768     '' Intern flag


$ENDIF ' __MYSQLINC
  