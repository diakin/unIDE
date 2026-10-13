$IFNDEF __ACE32_INC   ' IncManager: include guard
$DEFINE __ACE32_INC
'/*******************************************************************************
'* Source File  : ace32.bas
'* Copyright    : 1997-2002 Extended Systems, Inc.
'* Description  : This an Advantage Client Engine header file.  It contains the
'*                type definitions and prototypes for all the APIs for use
'*                with Visual Basic
'*******************************************************************************/

'/* Logical constants */
CONST ADS_FALSE = 0
CONST ADS_TRUE = 1

'/* This is for parameters to routines that accept a default setting */
CONST ADS_DEFAULT = 0

'/* character set types */
CONST ADS_ANSI = 1
CONST ADS_OEM = 2

'/* rights checking options */
CONST ADS_CHECKRIGHTS = 1
CONST ADS_IGNORERIGHTS = 2

'/* options for connecting to Advantage servers */
CONST ADS_INC_USERCOUNT = &H1
CONST ADS_STORED_PROC_CONN = &H2
CONST ADS_COMPRESS_ALWAYS = &H4
CONST ADS_COMPRESS_NEVER = &H8
CONST ADS_COMPRESS_INTERNET = &HC
CONST ADS_TABLE_PERM_READ = &H10
CONST ADS_TABLE_PERM_UPDATE = &H20
CONST ADS_TABLE_PERM_INSERT = &H40
CONST ADS_TABLE_PERM_DELETE = &H80
CONST ADS_REINDEX_ON_COLLATION_MISMATCH = &H100
CONST ADS_IGNORE_COLLATION_MISMATCH = &H200

'/* options for opening tables - can be ORed together */
CONST ADS_EXCLUSIVE = &H1
CONST ADS_READONLY = &H2
CONST ADS_SHARED = &H4
CONST ADS_CLIPPER_MEMOS = &H8

'/* Options for creating indexes - can be ORed together */
CONST ADS_ASCENDING = &H0
CONST ADS_UNIQUE = &H1
CONST ADS_COMPOUND = &H2
CONST ADS_CUSTOM = &H4
CONST ADS_DESCENDING = &H8
CONST ADS_USER_DEFINED = &H10

'/* Options for returning string values */
CONST ADS_NONE = &H0
CONST ADS_LTRIM = &H1
CONST ADS_RTRIM = &H2
CONST ADS_TRIM = &H3

'/* this is for passing null terminated strings */
' CONST ADS_NTS = ((UNSIGNED16) - 1)

'/* locking compatibility */
CONST ADS_COMPATIBLE_LOCKING = 0
CONST ADS_PROPRIETARY_LOCKING = 1

'/* settings for seeks */
CONST ADS_SOFTSEEK = &H1
CONST ADS_HARDSEEK = &H2
CONST ADS_SEEKGT = &H4

'/* data types for seeks (and scopes) */
CONST ADS_RAWKEY = 1   '/* no conversion performed on given data */
CONST ADS_STRINGKEY = 2   '/* data given as a string */
CONST ADS_DOUBLEKEY = 4   '/* data is a pointer to 8 byte double */

'/* For retrieving scope settings */
CONST ADS_TOP = 1
CONST ADS_BOTTOM = 2

'/* for calls that can optionally use filters */
CONST ADS_RESPECTFILTERS = &H1
CONST ADS_IGNOREFILTERS = &H2
CONST ADS_RESPECTSCOPES = &H3
'/*
' * This value is only used with GetRecordCount:  It can be ORed in with the
' * ignore filter value to force a read from the table header to get the most
' * current record count.
' */
CONST ADS_REFRESHCOUNT = &H4

'/* Server type constants */
CONST ADS_LOCAL_SERVER = &H1
CONST ADS_REMOTE_SERVER = &H2
CONST ADS_AIS_SERVER = &H4

'/* ACE handle types */
CONST ADS_CONNECTION = 1
CONST ADS_TABLE = 2
CONST ADS_INDEX_ORDER = 3
CONST ADS_STATEMENT = 4
CONST ADS_CURSOR = 5
CONST ADS_DICTIONARY_CONNECTION = 6
CONST ADS_DICTIONARY = 7

'/* ACE Cursor ReadOnly settings */
CONST ADS_CURSOR_READONLY = 1
CONST ADS_CURSOR_READWRITE = 2

'/* ACE Cursor CONSTrain settings */
CONST ADS_CONSTRAIN = 1
CONST ADS_NO_CONSTRAIN = 2

' Select Field Read settings
CONST ADS_READ_ALL_COLUMNS = 1
CONST ADS_READ_SELECT_COLUMNS = 2

'/* Disable server query optimization */
CONST ADS_NO_OPTIMIZATION = 1

'/* Data dictionary new contraint property validation options */
CONST ADS_NO_VALIDATE = 0             '/* Do not validate records against the new constraint */
CONST ADS_VALIDATE_NO_SAVE = 1        '/* Delete record not meeting the constraint from the table, no save */
CONST ADS_VALIDATE_WRITE_FAIL = 2     '/* Validate the records against the new constraint and overwrite
                                      '/* the fail table with records not meeting the constraint. */
CONST ADS_VALIDATE_APPEND_FAIL = 3    '/* Validate the records against the new constraint and append
                                      '/* the failed records into the fail table */
CONST ADS_VALIDATE_RETURN_ERROR = 4   '/* Validate the records against the new constraint and return
                                      '/* error if there is any record not meeting the constraint */

'/* Possible result values from AdsCompareBookmarks. */
CONST ADS_CMP_LESS = -1
CONST ADS_CMP_EQUAL = 0
CONST ADS_CMP_GREATER = 1

'/* Success return code */
CONST AE_SUCCESS = 0
CONST AE_ALLOCATION_FAILED = 5001
CONST AE_COMM_MISMATCH = 5002
CONST AE_DATA_TOO_LONG = 5003
CONST AE_FILE_NOT_FOUND = 5004
CONST AE_INSUFFICIENT_BUFFER = 5005
CONST AE_INVALID_BOOKMARK = 5006
CONST AE_INVALID_CALLBACK = 5007
CONST AE_INVALID_CENTURY = 5008
CONST AE_INVALID_DATEFORMAT = 5009
CONST AE_INVALID_DECIMALS = 5010
CONST AE_INVALID_EXPRESSION = 5011
CONST AE_INVALID_FIELDDEF = 5012
CONST AE_INVALID_FILTER_OPTION = 5013
CONST AE_INVALID_INDEX_HANDLE = 5014
CONST AE_INVALID_INDEX_NAME = 5015
CONST AE_INVALID_INDEX_ORDER_NAME = 5016
CONST AE_INVALID_INDEX_TYPE = 5017
CONST AE_INVALID_HANDLE = 5018
CONST AE_INVALID_OPTION = 5019
CONST AE_INVALID_PATH = 5020
CONST AE_INVALID_POINTER = 5021
CONST AE_INVALID_RECORD_NUMBER = 5022
CONST AE_INVALID_TABLE_HANDLE = 5023
CONST AE_INVALID_CONNECTION_HANDLE = 5024
CONST AE_INVALID_TABLETYPE = 5025
CONST AE_INVALID_WORKAREA = 5026
CONST AE_INVALID_CHARSETTYPE = 5027
CONST AE_INVALID_LOCKTYPE = 5028
CONST AE_INVALID_RIGHTSOPTION = 5029
CONST AE_INVALID_FIELDNUMBER = 5030
CONST AE_INVALID_KEY_LENGTH = 5031
CONST AE_INVALID_FIELDNAME = 5032
CONST AE_NO_DRIVE_CONNECTION = 5033
CONST AE_FILE_NOT_ON_SERVER = 5034
CONST AE_LOCK_FAILED = 5035
CONST AE_NO_CONNECTION = 5036
CONST AE_NO_FILTER = 5037
CONST AE_NO_SCOPE = 5038
CONST AE_NO_TABLE = 5039
CONST AE_NO_WORKAREA = 5040
CONST AE_NOT_FOUND = 5041
CONST AE_NOT_IMPLEMENTED = 5042
CONST AE_MAX_THREADS_EXCEEDED = 5043
CONST AE_START_THREAD_FAIL = 5044
CONST AE_TOO_MANY_INDEXES = 5045
CONST AE_TOO_MANY_TAGS = 5046
CONST AE_TRANS_OUT_OF_SEQUENCE = 5047
CONST AE_UNKNOWN_ERRCODE = 5048
CONST AE_UNSUPPORTED_LANGUAGE = 5049
CONST AE_NAME_TOO_LONG = 5050
CONST AE_DUPLICATE_ALIAS = 5051
CONST AE_TABLE_CLOSED_IN_TRANSACTION = 5053
CONST AE_PERMISSION_DENIED = 5054
CONST AE_STRING_NOT_FOUND = 5055
CONST AE_UNKNOWN_CHAR_SET = 5056
CONST AE_INVALID_OEM_CHAR_FILE = 5057
CONST AE_INVALID_MEMO_BLOCK_SIZE = 5058
CONST AE_NO_FILE_FOUND = 5059
CONST AE_NO_INF_LOCK = 5060
CONST AE_INF_FILE_ERROR = 5061
CONST AE_RECORD_NOT_LOCKED = 5062
CONST AE_ILLEGAL_COMMAND_DURING_TRANS = 5063
CONST AE_TABLE_NOT_SHARED = 5064
CONST AE_INDEX_ALREADY_OPEN = 5065
CONST AE_INVALID_FIELD_TYPE = 5066
CONST AE_TABLE_NOT_EXCLUSIVE = 5067
CONST AE_NO_CURRENT_RECORD = 5068
CONST AE_PRECISION_LOST = 5069
CONST AE_INVALID_DATA_TYPE = 5070
CONST AE_DATA_TRUNCATED = 5071
CONST AE_TABLE_READONLY = 5072
CONST AE_INVALID_RECORD_LENGTH = 5073
CONST AE_NO_ERROR_MESSAGE = 5074
CONST AE_INDEX_SHARED = 5075
CONST AE_INDEX_EXISTS = 5076
CONST AE_CYCLIC_RELATION = 5077
CONST AE_INVALID_RELATION = 5078
CONST AE_INVALID_DAY = 5079
CONST AE_INVALID_MONTH = 5080
CONST AE_CORRUPT_TABLE = 5081
CONST AE_INVALID_BINARY_OFFSET = 5082
CONST AE_BINARY_FILE_ERROR = 5083
CONST AE_INVALID_DELETED_BYTE_VALUE = 5084
CONST AE_NO_PENDING_UPDATE = 5085
CONST AE_PENDING_UPDATE = 5086
CONST AE_TABLE_NOT_LOCKED = 5087
CONST AE_CORRUPT_INDEX = 5088
CONST AE_AUTOOPEN_INDEX = 5089
CONST AE_SAME_TABLE = 5090
CONST AE_INVALID_IMAGE = 5091
CONST AE_COLLATION_SEQUENCE_MISMATCH = 5092
CONST AE_INVALID_INDEX_ORDER = 5093
CONST AE_TABLE_CACHED = 5094
CONST AE_INVALID_DATE = 5095
CONST AE_ENCRYPTION_NOT_ENABLED = 5096
CONST AE_INVALID_PASSWORD = 5097
CONST AE_TABLE_ENCRYPTED = 5098
CONST AE_SERVER_MISMATCH = 5099
CONST AE_INVALID_USERNAME = 5100
CONST AE_INVALID_VALUE = 5101
CONST AE_INVALID_CONTINUE = 5102
CONST AE_UNRECOGNIZED_VERSION = 5103
CONST AE_RECORD_ENCRYPTED = 5104
CONST AE_UNRECOGNIZED_ENCRYPTION = 5105
CONST AE_INVALID_SQLSTATEMENT_HANDLE = 5106
CONST AE_INVALID_SQLCURSOR_HANDLE = 5107
CONST AE_NOT_PREPARED = 5108
CONST AE_CURSOR_NOT_CLOSED = 5109
CONST AE_INVALID_SQL_PARAM_NUMBER = 5110
CONST AE_INVALID_SQL_PARAM_NAME = 5111
CONST AE_INVALID_COLUMN_NUMBER = 5112
CONST AE_INVALID_COLUMN_NAME = 5113
CONST AE_INVALID_READONLY_OPTION = 5114
CONST AE_IS_CURSOR_HANDLE = 5115
CONST AE_INDEX_EXPR_NOT_FOUND = 5116
CONST AE_NOT_DML = 5117
CONST AE_INVALID_CONSTRAIN_TYPE = 5118
CONST AE_INVALID_CURSORHANDLE = 5119
CONST AE_OBSOLETE_FUNCTION = 5120
CONST AE_TADSDATASET_GENERAL = 5121
CONST AE_UDF_OVERWROTE_BUFFER = 5122
CONST AE_INDEX_UDF_NOT_SET = 5123
CONST AE_CONCURRENT_PROBLEM = 5124
CONST AE_INVALID_DICTIONARY_HANDLE = 5125
CONST AE_INVALID_PROPERTY_ID = 5126
CONST AE_INVALID_PROPERTY = 5127
CONST AE_DICTIONARY_ALREADY_EXISTS = 5128
CONST AE_INVALID_FIND_HANDLE = 5129
CONST AE_DD_REQUEST_NOT_COMPLETED = 5130
CONST AE_INVALID_OBJECT_ID = 5131
CONST AE_INVALID_OBJECT_NAME = 5132
CONST AE_INVALID_PROPERTY_LENGTH = 5133
CONST AE_INVALID_KEY_OPTIONS = 5134
CONST AE_CONSTRAINT_VALIDATION_ERROR = 5135
CONST AE_INVALID_OBJECT_TYPE = 5136
CONST AE_NO_OBJECT_FOUND = 5137
CONST AE_PROPERTY_NOT_SET = 5138
CONST AE_NO_PRIMARY_KEY_EXISTS = 5139
CONST AE_LOCAL_CONN_DISABLED = 5140
CONST AE_RI_RESTRICT = 5141
CONST AE_RI_CASCADE = 5142
CONST AE_RI_FAILED = 5143
CONST AE_RI_CORRUPTED = 5144
CONST AE_RI_UNDO_FAILED = 5145
CONST AE_RI_RULE_EXISTS = 5146
CONST AE_COLUMN_CANNOT_BE_NULL = 5147
CONST AE_MIN_CONSTRAINT_VIOLATION = 5148
CONST AE_MAX_CONSTRAINT_VIOLATION = 5149
CONST AE_RECORD_CONSTRAINT_VIOLATION = 5150
CONST AE_CANNOT_DELETE_TEMP_INDEX = 5151
CONST AE_RESTRUCTURE_FAILED = 5152
CONST AE_INVALID_STATEMENT = 5153
CONST AE_STORED_PROCEDURE_FAILED = 5154
CONST AE_INVALID_DICTIONARY_FILE = 5155
CONST AE_NOT_MEMBER_OF_GROUP = 5156
CONST AE_ALREADY_MEMBER_OF_GROUP = 5157
CONST AE_INVALID_OBJECT_RIGHT = 5158
CONST AE_CANNOT_OPEN_DATABASE_TABLE = 5159
CONST AE_INVALID_CONSTRAINT = 5160
CONST AE_NOT_ADMINISTRATOR = 5161
CONST AE_NO_TABLE_ENCRYPTION_PASSWORD = 5162
CONST AE_TABLE_NOT_ENCRYPTED = 5163
CONST AE_INVALID_ENCRYPTION_VERSION = 5164
CONST AE_NO_STORED_PROC_EXEC_RIGHTS = 5165
CONST AE_DD_UNSUPPORTED_DEPLOYMENT = 5166
CONST AE_INFO_AUTO_CREATION_OCCURRED = 5168
CONST AE_INFO_COPY_MADE_BY_CLIENT = 5169
CONST AE_DATABASE_REQUIRES_NEW_SERVER = 5170
CONST AE_COLUMN_PERMISSION_DENIED = 5171
CONST AE_DATABASE_REQUIRES_NEW_CLIENT = 5172
CONST AE_INVALID_LINK_NUMBER = 5173
CONST AE_LINK_ACTIVATION_FAILED = 5174
CONST AE_INDEX_COLLATION_MISMATCH = 5175
CONST AE_ILLEGAL_USER_OPERATION = 5176

'/* Available OEM Languages (for Clipper compatibility) */
CONST ADS_LANG_USA = "USA"
CONST ADS_LANG_DANISH = "DANISH"
CONST ADS_LANG_DUTCH = "DUTCH"
CONST ADS_LANG_FINNISH = "FINNISH"
CONST ADS_LANG_FRENCH = "FRENCH"
CONST ADS_LANG_GERMAN = "GERMAN"
CONST ADS_LANG_GREEK437 = "GREEK437"
CONST ADS_LANG_GREEK851 = "GREEK851"
CONST ADS_LANG_ICELD850 = "ICELD850"
CONST ADS_LANG_ICELD861 = "ICELD861"
CONST ADS_LANG_ITALIAN = "ITALIAN"
CONST ADS_LANG_NORWEGN = "NORWEGN"
CONST ADS_LANG_PORTUGUE = "PORTUGUE"
CONST ADS_LANG_SPANISH = "SPANISH"
CONST ADS_LANG_SWEDISH = "SWEDISH"
CONST ADS_LANG_MAZOVIA = "MAZOVIA"
CONST ADS_LANG_PC_LATIN = "PC_LATIN"
CONST ADS_LANG_ISOLATIN = "ISOLATIN"
CONST ADS_LANG_RUSSIAN = "RUSSIAN"
CONST ADS_LANG_NTXCZ852 = "NTXCZ852"
CONST ADS_LANG_NTXCZ895 = "NTXCZ895"
CONST ADS_LANG_NTXSL852 = "NTXSL852"
CONST ADS_LANG_NTXSL895 = "NTXSL895"
CONST ADS_LANG_NTXHU852 = "NTXHU852"

'/* Supported file types */
CONST ADS_DATABASE_TABLE = ADS_DEFAULT
CONST ADS_NTX = 1
CONST ADS_CDX = 2
CONST ADS_ADT = 3

'/* for retrieving file names of tables */
CONST ADS_BASENAME = 1
CONST ADS_BASENAMEANDEXT = 2
CONST ADS_FULLPATHNAME = 3
CONST ADS_DATADICTIONARY_NAME = 4

'/* indication of bitmap filter optimization */
CONST ADS_OPTIMIZED_FULL = 1
CONST ADS_OPTIMIZED_PART = 2
CONST ADS_OPTIMIZED_NONE = 3

'/* Advantage Optimized Filter (AOF) filter resolution options */
CONST ADS_RESOLVE_IMMEDIATE = 1
CONST ADS_RESOLVE_DYNAMIC = 2

'/* Advantage Optimized Filter (AOF) customization options */
CONST ADS_AOF_ADD_RECORD = 1
CONST ADS_AOF_REMOVE_RECORD = 2
CONST ADS_AOF_TOGGLE_RECORD = 3

'/* Stored procedure or trigger type */
CONST ADS_STORED_PROC = 1

CONST ADS_MAX_USER_NAME = 50
CONST ADS_MAX_ADDRESS_SIZE = 30

'/* some maximum values used by the client */
'/* NOTE:  constants meant for string length exclude space for null terminator */
CONST ADS_MAX_DATEMASK = 12
CONST ADS_MAX_ERROR_LEN = 600
CONST ADS_MAX_INDEX_EXPR_LEN = 510 '/* this is only accurate for index expressions */
CONST ADS_MAX_KEY_LENGTH = 256     '/* maximum key value length */
CONST ADS_MAX_FIELD_NAME = 128
CONST ADS_MAX_DBF_FIELD_NAME = 10  '/* maximum length of field name in a DBF */
CONST ADS_MAX_INDEXES = 15         '/* physical index files, NOT index orders */
CONST ADS_MAX_PATH = 260
CONST ADS_MAX_TABLE_NAME = 255     '/* long file name */
CONST ADS_MAX_TAG_NAME = 128
CONST ADS_MAX_TAGS = 50            '/* maximum for CDX/ADI file */
CONST ADS_MAX_OBJECT_NAME = 200    '/* maximum length of DD object name */

'/* Valid range of page sizes for ADI indexes.  The default page size is 512
' * bytes.  Before using another page size, please read the section titled
' * "Index Page Size" in the Advantage Client Engine help file (ace.hlp) */
CONST ADS_MIN_ADI_PAGESIZE = 512
CONST ADS_MAX_ADI_PAGESIZE = 8192

'/* data types */
CONST ADS_TYPE_UNKNOWN = 0
CONST ADS_LOGICAL = 1          '/* 1 byte logical value */
CONST ADS_NUMERIC = 2          '/* DBF character style numeric */
CONST ADS_DATE = 3             '/* Date field.  With ADS_NTX and ADS_CDX,
                               ' * this is an 8 byte field of the form
                               ' * CCYYMMDD.  With ADS_ADT, it is a
                               ' * 4 byte Julian date. */
CONST ADS_STRING = 4           '/* Character data */
CONST ADS_MEMO = 5             '/* Variable length character data */
CONST ADS_BINARY = 6           '/* BLOB - any data */
CONST ADS_IMAGE = 7            '/* BLOB - bitmap */
CONST ADS_VARCHAR = 8          '/* variable length character field */
CONST ADS_COMPACTDATE = 9      '/* DBF date represented with 3 bytes */
CONST ADS_DOUBLE = 10          '/* IEEE 8 byte floating point */
CONST ADS_INTEGER = 11         '/* IEEE 4 byte signed long integer */

'/* the following are supported with the ADT file only */
CONST ADS_SHORTINT = 12        '/* IEEE 2 byte signed short integer */
CONST ADS_TIME = 13            '/* 4 byte long integer representing
                               ' * milliseconds since midnight */
CONST ADS_TIMESTAMP = 14       '/* 8 bytes.  High order 4 bytes are a
                               ' * long integer representing Julian date.
                               ' * Low order 4 bytes are a long integer
                               ' * representing milliseconds since
                               ' * midnight */
CONST ADS_AUTOINC = 15         '/* 4 byte auto-increment value */
CONST ADS_RAW = 16             '/* Untranslated data */
CONST ADS_CURDOUBLE = 17       '/* IEEE 8 byte floating point currency */

'/* Supported User Defined Function types to be used with AdsRegisterUDF */
CONST ADS_INDEX_UDF = 1

'/* Data dictionary properties related constants */
CONST ADS_DD_PROPERTY_NOT_AVAIL = &HFFFF
CONST ADS_DD_MAX_PROPERTY_LEN = &HFFFE
CONST ADS_DD_MAX_OBJECT_NAME_LEN = 200

CONST ADS_DD_TABLE_OBJECT = 1
CONST ADS_DD_RELATION_OBJECT = 2
CONST ADS_DD_INDEX_FILE_OBJECT = 3
CONST ADS_DD_FIELD_OBJECT = 4
CONST ADS_DD_COLUMN_OBJECT = 4
CONST ADS_DD_INDEX_OBJECT = 5
CONST ADS_DD_VIEW_OBJECT = 6
CONST ADS_DD_VIEW_OR_TABLE_OBJECT = 7
CONST ADS_DD_USER_OBJECT = 8
CONST ADS_DD_USER_GROUP_OBJECT = 9
CONST ADS_DD_PROCEDURE_OBJECT = 10
CONST ADS_DD_DATABASE_OBJECT = 11
CONST ADS_DD_LINK_OBJECT = 12
CONST ADS_DD_TABLE_VIEW_OR_LINK_OBJECT = 13

'/* Common properties numbers < 100 */
CONST ADS_DD_COMMENT = 1
CONST ADS_DD_VERSION = 2
CONST ADS_DD_USER_DEFINED_PROP = 3

'/* Database properties between 100 and 199 */
CONST ADS_DD_DEFAULT_TABLE_PATH = 100
CONST ADS_DD_ADMIN_PASSWORD = 101
CONST ADS_DD_TEMP_TABLE_PATH = 102
CONST ADS_DD_LOG_IN_REQUIRED = 103
CONST ADS_DD_VERIFY_ACCESS_RIGHTS = 104
CONST ADS_DD_ENCRYPT_TABLE_PASSWORD = 105
CONST ADS_DD_ENCRYPT_NEW_TABLE = 106
CONST ADS_DD_ENABLE_INTERNET = 107
CONST ADS_DD_INTERNET_SECURITY_LEVEL = 108
CONST ADS_DD_MAX_FAILED_ATTEMPTS = 109
CONST ADS_DD_ALLOW_ADSSYS_NET_ACCESS = 110
CONST ADS_DD_VERSION_MAJOR = 111
CONST ADS_DD_VERSION_MINOR = 112

'/* Table properties between 200 and 299 */
CONST ADS_DD_TABLE_VALIDATION_EXPR = 200
CONST ADS_DD_TABLE_VALIDATION_MSG = 201
CONST ADS_DD_TABLE_PRIMARY_KEY = 202
CONST ADS_DD_TABLE_AUTO_CREATE = 203
CONST ADS_DD_TABLE_TYPE = 204
CONST ADS_DD_TABLE_PATH = 205
CONST ADS_DD_TABLE_FIELD_COUNT = 206
CONST ADS_DD_TABLE_RI_GRAPH = 207
CONST ADS_DD_TABLE_OBJ_ID = 208
CONST ADS_DD_TABLE_IS_RI_PARENT = 210
CONST ADS_DD_TABLE_RELATIVE_PATH = 211
CONST ADS_DD_TABLE_CHAR_TYPE = 212
CONST ADS_DD_TABLE_DEFAULT_INDEX = 213
CONST ADS_DD_TABLE_ENCRYPTION = 214
CONST ADS_DD_TABLE_MEMO_BLOCK_SIZE = 215
CONST ADS_DD_TABLE_PERMISSION_LEVEL = 216

'/* Field properties between 300 - 399 */
CONST ADS_DD_FIELD_DEFAULT_VALUE = 300
CONST ADS_DD_FIELD_CAN_NULL = 301
CONST ADS_DD_FIELD_MIN_VALUE = 302
CONST ADS_DD_FIELD_MAX_VALUE = 303
CONST ADS_DD_FIELD_VALIDATION_MSG = 304
CONST ADS_DD_FIELD_DEFINITION = 305
CONST ADS_DD_FIELD_TYPE = 306
CONST ADS_DD_FIELD_LENGTH = 307
CONST ADS_DD_FIELD_DECIMAL = 308

'/* Index tag properties between 400 - 499 */
CONST ADS_DD_INDEX_FILE_NAME = 400
CONST ADS_DD_INDEX_EXPRESSION = 401
CONST ADS_DD_INDEX_CONDITION = 402
CONST ADS_DD_INDEX_OPTIONS = 403
CONST ADS_DD_INDEX_KEY_LENGTH = 404
CONST ADS_DD_INDEX_KEY_TYPE = 405

'/* RI properties between 500-599 */
CONST ADS_DD_RI_PARENT_GRAPH = 500
CONST ADS_DD_RI_PRIMARY_TABLE = 501
CONST ADS_DD_RI_PRIMARY_INDEX = 502
CONST ADS_DD_RI_FOREIGN_TABLE = 503
CONST ADS_DD_RI_FOREIGN_INDEX = 504
CONST ADS_DD_RI_UPDATERULE = 505
CONST ADS_DD_RI_DELETERULE = 506
CONST ADS_DD_RI_NO_PKEY_ERROR = 507
CONST ADS_DD_RI_CASCADE_ERROR = 508

'/* User properties between 600-699 */
CONST ADS_DD_USER_GROUP_NAME = 600

'/* View properties between 700-749 */
CONST ADS_DD_VIEW_STMT = 700
CONST ADS_DD_VIEW_STMT_LEN = 701

'/* Stored procedure properties 800-899 */
CONST ADS_DD_PROC_INPUT = 800
CONST ADS_DD_PROC_OUTPUT = 801
CONST ADS_DD_PROC_DLL_NAME = 802
CONST ADS_DD_PROC_DLL_FUNCTION_NAME = 803
CONST ADS_DD_PROC_INVOKE_OPTION = 804

'/* Index file properties 900-999 */
CONST ADS_DD_INDEX_FILE_PATH = 900
CONST ADS_DD_INDEX_FILE_PAGESIZE = 901

'/* Object rights properties 1001 - 1099 .  They can be used
' * with either user or user group objects. */
CONST ADS_DD_TABLES_RIGHTS = 1001
CONST ADS_DD_VIEWS_RIGHTS = 1002
CONST ADS_DD_PROCS_RIGHTS = 1003
CONST ADS_DD_OBJECTS_RIGHTS = 1004
CONST ADS_DD_FREE_TABLES_RIGHTS = 1005

'/* User Properties 1101 - 1199 */
CONST ADS_DD_USER_PASSWORD = 1101
CONST ADS_DD_USER_GROUP_MEMBERSHIP = 1102
CONST ADS_DD_USER_BAD_LOGINS = 1103

'/* User group Properties 1201 - 1299 */
'/* None at this moment. */

'/* Link properties 1301 - 1399 */
CONST ADS_DD_LINK_PATH = 1300
CONST ADS_DD_LINK_OPTIONS = 1301
CONST ADS_DD_LINK_USERNAME = 1302

CONST ADS_DD_LEVEL_0 = 0
CONST ADS_DD_LEVEL_1 = 1
CONST ADS_DD_LEVEL_2 = 2

'/* Referential Integrity (RI) update and delete rules */
CONST ADS_DD_RI_CASCADE = 1
CONST ADS_DD_RI_RESTRICT = 2
CONST ADS_DD_RI_SETNULL = 3
CONST ADS_DD_RI_SETDEFAULT = 4

'/* Default Field Value Options */
CONST ADS_DD_DFV_UNKNOWN = 1
CONST ADS_DD_DFV_NONE = 2
CONST ADS_DD_DFV_VALUES_STORED = 3

'/* Supported permissions in the data dictionary */
CONST ADS_PERMISSION_READ = &H1
CONST ADS_PERMISSION_UPDATE = &H2
CONST ADS_PERMISSION_EXECUTE = &H4
CONST ADS_PERMISSION_INHERIT = &H8
CONST ADS_PERMISSION_INSERT = &H10
CONST ADS_PERMISSION_DELETE = &H20
CONST ADS_PERMISSION_LINK_ACCESS = &H40

'/* Link DD options */
CONST ADS_LINK_GLOBAL = &H1
CONST ADS_LINK_AUTH_ACTIVE_USER = &H2
CONST ADS_LINK_PATH_IS_STATIC = &H4

'/* Table permission verification levels.
' * level 1 is all columns searchable, even those without permission.
' * level 2 is default. Permission to the column is required to search or filter on a column.
' * level 3 is most restricted. Only static SQL cursor is allowed. */
CONST ADS_DD_TABLE_PERMISSION_LEVEL_1 = 1
CONST ADS_DD_TABLE_PERMISSION_LEVEL_2 = 2
CONST ADS_DD_TABLE_PERMISSION_LEVEL_3 = 3

DECLARE FUNCTION AdsAddCustomKey Lib "ACE32.DLL" ALIAS "AdsAddCustomKey" (ByVal hIndex As Long) As Long
DECLARE FUNCTION AdsAppendRecord Lib "ACE32.DLL" ALIAS "AdsAppendRecord" (ByVal hTable As Long) As Long
DECLARE FUNCTION AdsApplicationExit Lib "ACE32.DLL" ALIAS "AdsApplicationExit" () As Long
DECLARE FUNCTION AdsAtBOF Lib "ACE32.DLL" ALIAS "AdsAtBOF" (ByVal hTable As Long, pbBof As Integer) As Long
DECLARE FUNCTION AdsAtEOF Lib "ACE32.DLL" ALIAS "AdsAtEOF" (ByVal hTable As Long, pbEof As Integer) As Long
DECLARE FUNCTION AdsBeginTransaction Lib "ACE32.DLL" ALIAS "AdsBeginTransaction" (ByVal hConnect As Long) As Long
DECLARE FUNCTION AdsBinaryToFile Lib "ACE32.DLL" ALIAS "AdsBinaryToFile" (ByVal hTable As Long, ByVal pucFldName As String, ByVal pucFileName As String) As Long
DECLARE FUNCTION AdsCacheOpenTables Lib "ACE32.DLL" ALIAS "AdsCacheOpenTables" (ByVal usOpen As Integer) As Long
DECLARE FUNCTION AdsCacheOpenCursors Lib "ACE32.DLL" ALIAS "AdsCacheOpenCursors" (ByVal usOpen As Integer) As Long
DECLARE FUNCTION AdsCacheRecords Lib "ACE32.DLL" ALIAS "AdsCacheRecords" (ByVal hTable As Long, ByVal usNumRecords As Integer) As Long
DECLARE FUNCTION AdsCancelUpdate Lib "ACE32.DLL" ALIAS "AdsCancelUpdate" (ByVal hTable As Long) As Long
DECLARE FUNCTION AdsCheckExistence Lib "ACE32.DLL" ALIAS "AdsCheckExistence" (ByVal hConnect As Long, ByVal pucFileName As String, pusOnDisk As Integer) As Long
DECLARE FUNCTION AdsClearAllScopes Lib "ACE32.DLL" ALIAS "AdsClearAllScopes" (ByVal hTable As Long) As Long
DECLARE FUNCTION AdsClearDefault Lib "ACE32.DLL" ALIAS "AdsClearDefault" () As Long
DECLARE FUNCTION AdsClearFilter Lib "ACE32.DLL" ALIAS "AdsClearFilter" (ByVal hTable As Long) As Long
DECLARE FUNCTION AdsClearRelation Lib "ACE32.DLL" ALIAS "AdsClearRelation" (ByVal hTableParent As Long) As Long
DECLARE FUNCTION AdsClearScope Lib "ACE32.DLL" ALIAS "AdsClearScope" (ByVal hIndex As Long, ByVal usScopeOption As Integer) As Long
DECLARE FUNCTION AdsCloneTable Lib "ACE32.DLL" ALIAS "AdsCloneTable" (ByVal hTable As Long, phClone As Long) As Long
DECLARE FUNCTION AdsCloseAllIndexes Lib "ACE32.DLL" ALIAS "AdsCloseAllIndexes" (ByVal hTable As Long) As Long
DECLARE FUNCTION AdsCloseAllTables Lib "ACE32.DLL" ALIAS "AdsCloseAllTables" () As Long
DECLARE FUNCTION AdsCloseIndex Lib "ACE32.DLL" ALIAS "AdsCloseIndex" (ByVal hIndex As Long) As Long
DECLARE FUNCTION AdsCloseTable Lib "ACE32.DLL" ALIAS "AdsCloseTable" (ByVal hTable As Long) As Long
DECLARE FUNCTION AdsCommitTransaction Lib "ACE32.DLL" ALIAS "AdsCommitTransaction" (ByVal hConnect As Long) As Long
DECLARE FUNCTION AdsConnect Lib "ACE32.DLL" ALIAS "AdsConnect" (ByVal pucServerName As String, phConnect As Long) As Long
DECLARE FUNCTION AdsConnect26 Lib "ACE32.DLL" ALIAS "AdsConnect26" (ByVal pucServerName As String, ByVal usServerTypes As Integer, phConnect As Long) As Long
DECLARE FUNCTION AdsConnect60 Lib "ACE32.DLL" ALIAS "AdsConnect60" (ByVal pucServerName As String, ByVal usServerTypes As Integer, ByVal pucUserName As String, ByVal pucPassword As String, ByVal ulOptions As Long, phConnect As Long) As Long
DECLARE FUNCTION AdsContinue Lib "ACE32.DLL" ALIAS "AdsContinue" (ByVal hTable As Long, pbFound As Integer) As Long
DECLARE FUNCTION AdsConvertTable Lib "ACE32.DLL" ALIAS "AdsConvertTable" (ByVal hObj As Long, ByVal usFilterOption As Integer, ByVal pucFile As String, ByVal usTableType As Integer) As Long
DECLARE FUNCTION AdsCopyTable Lib "ACE32.DLL" ALIAS "AdsCopyTable" (ByVal hObj As Long, ByVal usFilterOption As Integer, ByVal pucFile As String) As Long
DECLARE FUNCTION AdsCopyTableContents Lib "ACE32.DLL" ALIAS "AdsCopyTableContents" (ByVal hObjFrom As Long, ByVal hTableTo As Long, ByVal usFilterOption As Integer) As Long
DECLARE FUNCTION AdsCopyTableStructure Lib "ACE32.DLL" ALIAS "AdsCopyTableStructure" (ByVal hTable As Long, ByVal pucFile As String) As Long
DECLARE FUNCTION AdsCreateIndex Lib "ACE32.DLL" ALIAS "AdsCreateIndex" (ByVal hObj As Long, ByVal pucFileName As String, ByVal pucTag As String, ByVal pucExpr As String, ByVal pucCondition As String, ByVal pucWhile As String, ByVal ulOptions As Long, phIndex As Long) As Long
DECLARE FUNCTION AdsCreateIndex61 Lib "ACE32.DLL" ALIAS "AdsCreateIndex61" (ByVal hObj As Long, ByVal pucFileName As String, ByVal pucTag As String, ByVal pucExpr As String, ByVal pucCondition As String, ByVal pucWhile As String, ByVal ulOptions As Long, ByVal ulPageSize As Long, phIndex As Long) As Long
DECLARE FUNCTION AdsCreateTable Lib "ACE32.DLL" ALIAS "AdsCreateTable" (ByVal hConnection As Long, ByVal pucName As String, ByVal pucAlias As String, ByVal usTableType As Integer, ByVal usCharType As Integer, ByVal usLockType As Integer, ByVal usCheckRights As Integer, ByVal usMemoSize As Integer, ByVal pucFields As String, phTable As Long) As Long
DECLARE FUNCTION AdsDDCreate Lib "ACE32.DLL" ALIAS "AdsDDCreate" (ByVal pucDictionaryPath As String, ByVal usEncrypt As Integer, ByVal pucDescription As String, phDictionary As Long) As Long
DECLARE FUNCTION AdsDDCreateRefIntegrity Lib "ACE32.DLL" ALIAS "AdsDDCreateRefIntegrity" (ByVal hDictionary As Long, ByVal pucRIName As String, ByVal pucFailTable As String, ByVal pucParentTableName As String, ByVal pucParentTagName As String, ByVal pucChildTableName As String, ByVal pucChildTagName As String, ByVal usUpdateRule As Integer, ByVal usDeleteRule As Integer) As Long
DECLARE FUNCTION AdsDDCreateRefIntegrity62 Lib "ACE32.DLL" ALIAS "AdsDDCreateRefIntegrity62" (ByVal hDictionary As Long, ByVal pucRIName As String, ByVal pucFailTable As String, ByVal pucParentTableName As String, ByVal pucParentTagName As String, ByVal pucChildTableName As String, ByVal pucChildTagName As String, ByVal usUpdateRule As Integer, ByVal usDeleteRule As Integer, ByVal pucNoPrimaryError As String, ByVal pucCascadeError As String) As Long
DECLARE FUNCTION AdsDDRemoveRefIntegrity Lib "ACE32.DLL" ALIAS "AdsDDRemoveRefIntegrity" (ByVal hDictionary As Long, ByVal pucRefName As String) As Long
DECLARE FUNCTION AdsDDGetDatabaseProperty Lib "ACE32.DLL" ALIAS "AdsDDGetDatabaseProperty" (ByVal hObject As Long, ByVal usPropertyID As Integer, pvProperty, pusPropertyLen As Integer) As Long
DECLARE FUNCTION AdsDDGetFieldProperty Lib "ACE32.DLL" ALIAS "AdsDDGetFieldProperty" (ByVal hObject As Long, ByVal pucTableName As String, ByVal pucFieldName As String, ByVal usPropertyID As Integer, pvProperty, pusPropertyLen As Integer) As Long
DECLARE FUNCTION AdsDDGetIndexFileProperty Lib "ACE32.DLL" ALIAS "AdsDDGetIndexFileProperty" (ByVal hObject As Long, ByVal pucTableName As String, ByVal pucIndexFileName As String, ByVal usPropertyID As Integer, pvProperty, pusPropertyLen As Integer) As Long
DECLARE FUNCTION AdsDDGetIndexProperty Lib "ACE32.DLL" ALIAS "AdsDDGetIndexProperty" (ByVal hObject As Long, ByVal pucTableName As String, ByVal pucIndexFileName As String, ByVal usPropertyID As Integer, pvProperty, pusPropertyLen As Integer) As Long
DECLARE FUNCTION AdsDDGetTableProperty Lib "ACE32.DLL" ALIAS "AdsDDGetTableProperty" (ByVal hObject As Long, ByVal pucTableName As String, ByVal usPropertyID As Integer, pvProperty, pusPropertyLen As Integer) As Long
DECLARE FUNCTION AdsDDGetUserGroupProperty Lib "ACE32.DLL" ALIAS "AdsDDGetUserGroupProperty" (ByVal hObject As Long, ByVal pucUserGroupName As String, ByVal usPropertyID As Integer, pvProperty, pusPropertyLen As Integer) AS LONG
DECLARE FUNCTION AdsDDGetUserProperty Lib "ACE32.DLL" ALIAS "AdsDDGetUserProperty" (ByVal hObject As Long, ByVal pucUserName As String, ByVal usPropertyID As Integer, pvProperty, pusPropertyLen As Integer) As Long
DECLARE FUNCTION AdsDDGetViewProperty Lib "ACE32.DLL" ALIAS "AdsDDGetViewProperty" (ByVal hObject As Long, ByVal pucViewName As String, ByVal usPropertyID As Integer, pvProperty, pusPropertyLen As Integer) As Long
DECLARE FUNCTION AdsDDGetProcedureProperty Lib "ACE32.DLL" ALIAS "AdsDDGetProcedureProperty" (ByVal hObject As Long, ByVal pucProcName As String, ByVal usPropertyID As Integer, pvProperty, pusPropertyLen As Integer) As Long
DECLARE FUNCTION AdsDDGetRefIntegrityProperty Lib "ACE32.DLL" ALIAS "AdsDDGetRefIntegrityProperty" (ByVal hObject As Long, ByVal pucRefName As String, ByVal usPropertyID As Integer, ByVal pucProperty As String, pusPropertyLen As Integer) As Long
DECLARE FUNCTION AdsDDSetDatabaseProperty Lib "ACE32.DLL" ALIAS "AdsDDSetDatabaseProperty" (ByVal hDictionary As Long, ByVal usPropertyID As Integer, pvProperty, ByVal usPropertyLen As Integer) As Long
DECLARE FUNCTION AdsDDSetFieldProperty Lib "ACE32.DLL" ALIAS "AdsDDSetFieldProperty" (ByVal hDictionary As Long, ByVal pucTableName As String, ByVal pucFieldName As String, ByVal usPropertyID As Integer, pvProperty, ByVal usPropertyLen As Integer, ByVal usValidateOption As Integer, ByVal pucFailTable As String) As Long
DECLARE FUNCTION AdsDDSetTableProperty Lib "ACE32.DLL" ALIAS "AdsDDSetTableProperty" (ByVal hDictionary As Long, ByVal pucTableName As String, ByVal usPropertyID As Integer, pvProperty, ByVal usPropertyLen As Integer, ByVal usValidateOption As Integer, ByVal pucFailTable As String) As Long
DECLARE FUNCTION AdsDDSetUserGroupProperty Lib "ACE32.DLL" ALIAS "AdsDDSetUserGroupProperty" (ByVal hDictionary As Long, ByVal pucUserGroupName As String, ByVal usPropertyID As Integer, pvProperty, ByVal usPropertyLen As Integer) As Long
DECLARE FUNCTION AdsDDSetUserProperty Lib "ACE32.DLL" ALIAS "AdsDDSetUserProperty" (ByVal hDictionary As Long, ByVal pucUserName As String, ByVal usPropertyID As Integer, pvProperty, ByVal usPropertyLen As Integer) As Long
DECLARE FUNCTION AdsDDSetObjectAccessRights Lib "ACE32.DLL" ALIAS "AdsDDSetObjectAccessRights" (ByVal hDictionary As Long, ByVal pucObjectName As String, ByVal pucAccessorName As String, ByVal pucAllowedAccess As String) As Long
DECLARE FUNCTION AdsDDAddTable Lib "ACE32.DLL" ALIAS "AdsDDAddTable" (ByVal hDictionary As Long, ByVal pucTableName As String, ByVal pucTablePath As String, ByVal usTableType As Integer, ByVal usCharType As Integer, ByVal pucIndexFiles As String, ByVal pucComment As String) As Long
DECLARE FUNCTION AdsDDAddView Lib "ACE32.DLL" ALIAS "AdsDDAddView" (ByVal hDictionary As Long, ByVal pucName As String, ByVal pucComments As String, ByVal pucSQL As String) As Long
DECLARE FUNCTION AdsDDAddIndexFile Lib "ACE32.DLL" ALIAS "AdsDDAddIndexFile" (ByVal hDictionary As Long, ByVal pucTableName As String, ByVal pucIndexFilePath As String, ByVal pucComment As String) As Long
DECLARE FUNCTION AdsDDCreateUser Lib "ACE32.DLL" ALIAS "AdsDDCreateUser" (ByVal hDictionary As Long, ByVal pucGroupName As String, ByVal pucUserName As String, ByVal pucPassword As String, ByVal pucDescription As String) As Long
DECLARE FUNCTION AdsDDAddUserToGroup Lib "ACE32.DLL" ALIAS "AdsDDAddUserToGroup" (ByVal hDictionary As Long, ByVal pucGroupName As String, ByVal pucUserName As String) As Long
DECLARE FUNCTION AdsDDRemoveUserFromGroup Lib "ACE32.DLL" ALIAS "AdsDDRemoveUserFromGroup" (ByVal hDictionary As Long, ByVal pucGroupName As String, ByVal pucUserName As String) As Long
DECLARE FUNCTION AdsDDDeleteUser Lib "ACE32.DLL" ALIAS "AdsDDDeleteUser" (ByVal hDictionary As Long, ByVal pucUserName As String) As Long
DECLARE FUNCTION AdsDDCreateUserGroup Lib "ACE32.DLL" ALIAS "AdsDDCreateUserGroup" (ByVal hDictionary As Long, ByVal pucGroupName As String, ByVal pucDescription As String) As Long
DECLARE FUNCTION AdsDDDeleteUserGroup Lib "ACE32.DLL" ALIAS "AdsDDDeleteUserGroup" (ByVal hDictionary As Long, ByVal pucGroupName As String) As Long
DECLARE FUNCTION AdsDDDeleteIndex Lib "ACE32.DLL" ALIAS "AdsDDDeleteIndex" (ByVal hDictionary As Long, ByVal pucTableName As String, ByVal pucIndexName As String) As Long
DECLARE FUNCTION AdsDDRemoveIndexFile Lib "ACE32.DLL" ALIAS "AdsDDRemoveIndexFile" (ByVal hDictionary As Long, ByVal pucTableName As String, ByVal pucIndexFileName As String, ByVal usDeleteFile As Integer) As Long
DECLARE FUNCTION AdsDDRemoveTable Lib "ACE32.DLL" ALIAS "AdsDDRemoveTable" (ByVal hObject As Long, ByVal pucTableName As String, ByVal usDeleteFile As Integer) As Long
DECLARE FUNCTION AdsDDRemoveView Lib "ACE32.DLL" ALIAS "AdsDDRemoveView" (ByVal hDictionary As Long, ByVal pucName As String) As Long
DECLARE FUNCTION AdsDDFindFirstObject Lib "ACE32.DLL" ALIAS "AdsDDFindFirstObject" (ByVal hObject As Long, ByVal usFindObjectType As Integer, ByVal pucParentName As String, ByVal pucObjectName As String, pusObjectNameLen As Integer, phFindHandle As Long) As Long
DECLARE FUNCTION AdsDDFindNextObject Lib "ACE32.DLL" ALIAS "AdsDDFindNextObject" (ByVal hObject As Long, ByVal hFindHandle As Long, ByVal pucObjectName As String, pusObjectNameLen As Integer) As Long
DECLARE FUNCTION AdsDDFindClose Lib "ACE32.DLL" ALIAS "AdsDDFindClose" (ByVal hObject As Long, ByVal hFindHandle As Long) As Long
DECLARE FUNCTION AdsDDGetPermissions Lib "ACE32.DLL" ALIAS "AdsDDGetPermissions" (ByVal hDBConn As Long, ByVal pucGrantee As String, ByVal usObjectType As Integer, ByVal pucObjectName As String, ByVal pucParentName As String, ByVal usGetInherited As Integer, pulPermissions As Long ) As Long
DECLARE FUNCTION AdsDDGrantPermission Lib "ACE32.DLL" ALIAS "AdsDDGrantPermission" (ByVal hAdminConn As Long, ByVal usObjectType As Integer, ByVal pucObjectName As String, ByVal pucParentName As String, ByVal pucGrantee As String, ByVal ulPermissions As Integer ) As Long
DECLARE FUNCTION AdsDDRevokePermission Lib "ACE32.DLL" ALIAS "AdsDDRevokePermission" (ByVal hAdminConn As Long, ByVal usObjectType As Integer, ByVal pucObjectName As String, ByVal pucParentName As String, ByVal pucGrantee As String, ByVal ulPermissions As Integer ) As Long
DECLARE FUNCTION AdsDDGetLinkProperty Lib "ACE32.DLL" ALIAS "AdsDDGetLinkProperty" (ByVal hConnect As Long, ByVal pucLinkName As String, ByVal usPropertyID As Integer, pvProperty, pusPropertyLen As Integer ) As Long
DECLARE FUNCTION AdsDDCreateLink Lib "ACE32.DLL" ALIAS "AdsDDCreateLink" (ByVal hDBConn As Long, ByVal pucLinkAlias As String, ByVal pucLinkedDDPath As String, ByVal pucUserName As String, ByVal pucPassword As String, ByVal ulOptions As Long ) As Long
DECLARE FUNCTION AdsDDDropLink Lib "ACE32.DLL" ALIAS "AdsDDDropLink" (ByVal hDBConn As Long, ByVal pucLinkedDD As String, ByVal usDrop As Integer ) As Long
DECLARE FUNCTION AdsDecryptRecord Lib "ACE32.DLL" ALIAS "AdsDecryptRecord" (ByVal hTable As Long) As Long
DECLARE FUNCTION AdsDecryptTable Lib "ACE32.DLL" ALIAS "AdsDecryptTable" (ByVal hTable As Long) As Long
DECLARE FUNCTION AdsDeleteCustomKey Lib "ACE32.DLL" ALIAS "AdsDeleteCustomKey" (ByVal hIndex As Long) As Long
DECLARE FUNCTION AdsDeleteIndex Lib "ACE32.DLL" ALIAS "AdsDeleteIndex" (ByVal hIndex As Long) As Long
DECLARE FUNCTION AdsDeleteRecord Lib "ACE32.DLL" ALIAS "AdsDeleteRecord" (ByVal hTable As Long) As Long
DECLARE FUNCTION AdsDisableEncryption Lib "ACE32.DLL" ALIAS "AdsDisableEncryption" (ByVal hTable As Long) As Long
DECLARE FUNCTION AdsDisableLocalConnections Lib "ACE32.DLL" ALIAS "AdsDisableLocalConnections" () As Long
DECLARE FUNCTION AdsDisconnect Lib "ACE32.DLL" ALIAS "AdsDisconnect" (ByVal hConnect As Long) As Long
DECLARE FUNCTION AdsEnableEncryption Lib "ACE32.DLL" ALIAS "AdsEnableEncryption" (ByVal hTable As Long, ByVal pucPassword As String) As Long
DECLARE FUNCTION AdsEncryptRecord Lib "ACE32.DLL" ALIAS "AdsEncryptRecord" (ByVal hTable As Long) As Long
DECLARE FUNCTION AdsEncryptTable Lib "ACE32.DLL" ALIAS "AdsEncryptTable" (ByVal hTable As Long) As Long
DECLARE FUNCTION AdsEvalLogicalExpr Lib "ACE32.DLL" ALIAS "AdsEvalLogicalExpr" (ByVal hTable As Long, ByVal pucExpr As String, pbResult As Integer) As Long
DECLARE FUNCTION AdsEvalNumericExpr Lib "ACE32.DLL" ALIAS "AdsEvalNumericExpr" (ByVal hTable As Long, ByVal pucExpr As String, pdResult As Double) As Long
DECLARE FUNCTION AdsEvalStringExpr Lib "ACE32.DLL" ALIAS "AdsEvalStringExpr" (ByVal hTable As Long, ByVal pucExpr As String, ByVal pucResult As String, pusLen As Integer) As Long
DECLARE FUNCTION AdsEvalTestExpr Lib "ACE32.DLL" ALIAS "AdsEvalTestExpr" (ByVal hTable As Long, ByVal pucExpr As String, pusType As Integer) As Long
DECLARE FUNCTION AdsExtractKey Lib "ACE32.DLL" ALIAS "AdsExtractKey" (ByVal hIndex As Long, ByVal pucKey As String, pusLen As Integer) As Long
DECLARE FUNCTION AdsFailedTransactionRecovery Lib "ACE32.DLL" ALIAS "AdsFailedTransactionRecovery" (ByVal pucServer As String) As Long
DECLARE FUNCTION AdsFileToBinary Lib "ACE32.DLL" ALIAS "AdsFileToBinary" (ByVal hTable As Long, ByVal pucFldName As String, ByVal usBinaryType As Integer, ByVal pucFileName As String) As Long
DECLARE FUNCTION AdsFindConnection Lib "ACE32.DLL" ALIAS "AdsFindConnection" (ByVal pucServerName As String, phConnect As Long) As Long
DECLARE FUNCTION AdsFindConnection25 Lib "ACE32.DLL" ALIAS "AdsFindConnection25" (ByVal pucServerName As String, phConnect As Long) As Long
DECLARE FUNCTION AdsGetAllIndexes Lib "ACE32.DLL" ALIAS "AdsGetAllIndexes" (ByVal hTable As Long, ahIndex As Long, pusArrayLen As Integer) As Long
DECLARE FUNCTION AdsGetAllLocks Lib "ACE32.DLL" ALIAS "AdsGetAllLocks" (ByVal hTable As Long, aulLocks As Long, pusArrayLen As Integer) As Long
DECLARE FUNCTION AdsGetAllTables Lib "ACE32.DLL" ALIAS "AdsGetAllTables" (ahTable As Long, pusArrayLen As Integer) As Long
DECLARE FUNCTION AdsGetBinary Lib "ACE32.DLL" ALIAS "AdsGetBinary" (ByVal hTable As Long, ByVal pucFldName As String, ByVal ulOffset As Long, ByVal pucBuf As String, pulLen As Long) As Long
DECLARE FUNCTION AdsGetBinaryLength Lib "ACE32.DLL" ALIAS "AdsGetBinaryLength" (ByVal hTable As Long, ByVal pucFldName As String, pulLength As Long) As Long
DECLARE FUNCTION AdsGetBookmark Lib "ACE32.DLL" ALIAS "AdsGetBookmark" (ByVal hTable As Long, phBookmark As Long) As Long
DECLARE FUNCTION AdsGetCollationLang Lib "ACE32.DLL" ALIAS "AdsGetCollationLang" (ByVal pucLang As String, pusLen As Integer) As Long
DECLARE FUNCTION AdsGetConnectionType Lib "ACE32.DLL" ALIAS "AdsGetConnectionType" (ByVal hConnect As Long, pusConnectType As Integer) As Long
DECLARE FUNCTION AdsGetDate Lib "ACE32.DLL" ALIAS "AdsGetDate" (ByVal hTable As Long, ByVal pucFldName As String, ByVal pucBuf As String, pusLen As Integer) As Long
DECLARE FUNCTION AdsGetDateFormat Lib "ACE32.DLL" ALIAS "AdsGetDateFormat" (ByVal pucFormat As String, pusLen As Integer) As Long
DECLARE FUNCTION AdsGetDecimals Lib "ACE32.DLL" ALIAS "AdsGetDecimals" (pusDecimals As Integer) As Long
DECLARE FUNCTION AdsGetDefault Lib "ACE32.DLL" ALIAS "AdsGetDefault" (ByVal pucDefault As String, pusLen As Integer) As Long
DECLARE FUNCTION AdsGetDeleted Lib "ACE32.DLL" ALIAS "AdsGetDeleted" (pbUseDeleted As Integer) As Long
DECLARE FUNCTION AdsGetDouble Lib "ACE32.DLL" ALIAS "AdsGetDouble" (ByVal hTable As Long, ByVal pucFldName As String, pdValue As Double) As Long
DECLARE FUNCTION AdsGetEpoch Lib "ACE32.DLL" ALIAS "AdsGetEpoch" (pusCentury As Integer) As Long
DECLARE FUNCTION AdsGetErrorString Lib "ACE32.DLL" ALIAS "AdsGetErrorString" (ByVal ulErrCode As Long, ByVal pucBuf As String, pusBufLen As Integer) As Long
DECLARE FUNCTION AdsGetExact Lib "ACE32.DLL" ALIAS "AdsGetExact" (pbExact As Integer) As Long
DECLARE FUNCTION AdsGetExact22 Lib "ACE32.DLL" ALIAS "AdsGetExact22" (ByVal hObj As Long, pbExact As Integer) As Long
DECLARE FUNCTION AdsGetField Lib "ACE32.DLL" ALIAS "AdsGetField" (ByVal hTable As Long, ByVal pucFldName As String, ByVal pucBuf As String, pulLen As Long, ByVal usOption As Integer) As Long
DECLARE FUNCTION AdsGetFieldDecimals Lib "ACE32.DLL" ALIAS "AdsGetFieldDecimals" (ByVal hTable As Long, ByVal pucFldName As String, pusDecimals As Integer) As Long
DECLARE FUNCTION AdsGetFieldLength Lib "ACE32.DLL" ALIAS "AdsGetFieldLength" (ByVal hTable As Long, ByVal pucFldName As String, pulLength As Long) As Long
DECLARE FUNCTION AdsGetFieldName Lib "ACE32.DLL" ALIAS "AdsGetFieldName" (ByVal hTable As Long, ByVal usFld As Integer, ByVal pucName As String, pusBufLen As Integer) As Long
DECLARE FUNCTION AdsGetFieldNum Lib "ACE32.DLL" ALIAS "AdsGetFieldNum" (ByVal hTable As Long, ByVal pucFldName As String, pusNum As Integer) As Long
DECLARE FUNCTION AdsGetFieldOffset Lib "ACE32.DLL" ALIAS "AdsGetFieldOffset" (ByVal hTable As Long, ByVal pucFldName As String, pulOffset As Long) As Long
DECLARE FUNCTION AdsGetFieldType Lib "ACE32.DLL" ALIAS "AdsGetFieldType" (ByVal hTable As Long, ByVal pucFldName As String, pusType As Integer) As Long
DECLARE FUNCTION AdsGetFilter Lib "ACE32.DLL" ALIAS "AdsGetFilter" (ByVal hTable As Long, ByVal pucFilter As String, pusLen As Integer) As Long
DECLARE FUNCTION AdsGetHandleLong Lib "ACE32.DLL" ALIAS "AdsGetHandleLong" (ByVal hObj As Long, pulVal As Long) As Long
DECLARE FUNCTION AdsGetHandleType Lib "ACE32.DLL" ALIAS "AdsGetHandleType" (ByVal hObj As Long, pusType As Integer) As Long
DECLARE FUNCTION AdsGetHandleByExpression Lib "ACE32.DLL" ALIAS "AdsGetHandleByExpression" (ByVal hTable As Long, ByVal pucExpr As String, ByVal ulDescending As Long, pulVal As Long) As Long
DECLARE FUNCTION AdsGetIndexCondition Lib "ACE32.DLL" ALIAS "AdsGetIndexCondition" (ByVal hIndex As Long, ByVal pucExpr As String, pusLen As Integer) As Long
DECLARE FUNCTION AdsGetIndexExpr Lib "ACE32.DLL" ALIAS "AdsGetIndexExpr" (ByVal hIndex As Long, ByVal pucExpr As String, pusLen As Integer) As Long
DECLARE FUNCTION AdsGetIndexFilename Lib "ACE32.DLL" ALIAS "AdsGetIndexFilename" (ByVal hIndex As Long, ByVal usOption As Integer, ByVal pucName As String, pusLen As Integer) As Long
DECLARE FUNCTION AdsGetIndexHandle Lib "ACE32.DLL" ALIAS "AdsGetIndexHandle" (ByVal hTable As Long, ByVal pucIndexOrder As String, phIndex As Long) As Long
DECLARE FUNCTION AdsGetIndexHandleByOrder Lib "ACE32.DLL" ALIAS "AdsGetIndexHandleByOrder" (ByVal hTable As Long, ByVal usIndexOrder As Integer, phIndex As Long) As Long
DECLARE FUNCTION AdsGetIndexHandleByExpr Lib "ACE32.DLL" ALIAS "AdsGetIndexHandleByExpr" (ByVal hTable As Long, ByVal pucExpr As String, ByVal ulDescending As Long, phIndex As Long) As Long
DECLARE FUNCTION AdsGetIndexName Lib "ACE32.DLL" ALIAS "AdsGetIndexName" (ByVal hIndex As Long, ByVal pucName As String, pusLen As Integer) As Long
DECLARE FUNCTION AdsGetIndexOrderByHandle Lib "ACE32.DLL" ALIAS "AdsGetIndexOrderByHandle" (ByVal hhIndex As Long, pusIndexOrder As Integer) As Long
DECLARE FUNCTION AdsGetJulian Lib "ACE32.DLL" ALIAS "AdsGetJulian" (ByVal hTable As Long, ByVal pucFldName As String, plDate As Long) As Long
DECLARE FUNCTION AdsGetKeyCount Lib "ACE32.DLL" ALIAS "AdsGetKeyCount" (ByVal hIndex As Long, ByVal usFilterOption As Integer, pulCount As Long) As Long
DECLARE FUNCTION AdsGetKeyNum Lib "ACE32.DLL" ALIAS "AdsGetKeyNum" (ByVal hIndex As Long, ByVal usFilterOption As Integer, pulKey As Long) As Long
DECLARE FUNCTION AdsGetKeyLength Lib "ACE32.DLL" ALIAS "AdsGetKeyLength" (ByVal hIndex As Long, pusKeyLength As Integer) As Long
DECLARE FUNCTION AdsGetKeyType Lib "ACE32.DLL" ALIAS "AdsGetKeyType" (ByVal hIndex As Long, pusKeyType As Integer) As Long
DECLARE FUNCTION AdsGetLastError Lib "ACE32.DLL" ALIAS "AdsGetLastError" (pulErrCode As Long, ByVal pucBuf As String, pusBufLen As Integer) As Long
DECLARE FUNCTION AdsGetLastTableUpdate Lib "ACE32.DLL" ALIAS "AdsGetLastTableUpdate" (ByVal hTable As Long, ByVal pucDate As String, pusDateLen As Integer) As Long
DECLARE FUNCTION AdsGetLogical Lib "ACE32.DLL" ALIAS "AdsGetLogical" (ByVal hTable As Long, ByVal pucFldName As String, pbValue As Integer) As Long
DECLARE FUNCTION AdsGetLong Lib "ACE32.DLL" ALIAS "AdsGetLong" (ByVal hTable As Long, ByVal pucFldName As String, plValue As Long) As Long
DECLARE FUNCTION AdsGetMemoLength Lib "ACE32.DLL" ALIAS "AdsGetMemoLength" (ByVal hTable As Long, ByVal pucFldName As String, pulLength As Long) As Long
DECLARE FUNCTION AdsGetMemoDataType Lib "ACE32.DLL" ALIAS "AdsGetMemoDataType" (ByVal hTable As Long, ByVal pucFldName As String, pusType As Integer) As Long
DECLARE FUNCTION AdsGetMilliseconds Lib "ACE32.DLL" ALIAS "AdsGetMilliseconds" (ByVal hTable As Long, ByVal pucFldName As String, plTime As Long) As Long
DECLARE FUNCTION AdsGetNumFields Lib "ACE32.DLL" ALIAS "AdsGetNumFields" (ByVal hTable As Long, pusCount As Integer) As Long
DECLARE FUNCTION AdsGetNumIndexes Lib "ACE32.DLL" ALIAS "AdsGetNumIndexes" (ByVal hTable As Long, pusNum As Integer) As Long
DECLARE FUNCTION AdsGetNumLocks Lib "ACE32.DLL" ALIAS "AdsGetNumLocks" (ByVal hTable As Long, pulNum As Long) As Long
DECLARE FUNCTION AdsGetNumOpenTables Lib "ACE32.DLL" ALIAS "AdsGetNumOpenTables" (pusNum As Integer) As Long
DECLARE FUNCTION AdsGetRecord Lib "ACE32.DLL" ALIAS "AdsGetRecord" (ByVal hTable As Long, ByVal pucRec As String, pulLen As Long) As Long
DECLARE FUNCTION AdsGetRecordCount Lib "ACE32.DLL" ALIAS "AdsGetRecordCount" (ByVal hTable As Long, ByVal usFilterOption As Integer, pulCount As Long) As Long
DECLARE FUNCTION AdsGetRecordNum Lib "ACE32.DLL" ALIAS "AdsGetRecordNum" (ByVal hTable As Long, ByVal usFilterOption As Integer, pulRec As Long) As Long
DECLARE FUNCTION AdsGetRecordLength Lib "ACE32.DLL" ALIAS "AdsGetRecordLength" (ByVal hTable As Long, pulLength As Long) As Long
DECLARE FUNCTION AdsGetRelKeyPos Lib "ACE32.DLL" ALIAS "AdsGetRelKeyPos" (ByVal hIndex As Long, pdPos As Double) As Long
DECLARE FUNCTION AdsGetScope Lib "ACE32.DLL" ALIAS "AdsGetScope" (ByVal hIndex As Long, ByVal usScopeOption As Integer, ByVal pucScope As String, pusBufLen As Integer) As Long
DECLARE FUNCTION AdsGetSearchPath Lib "ACE32.DLL" ALIAS "AdsGetSearchPath" (ByVal pucPath As String, pusLen As Integer) As Long
DECLARE FUNCTION AdsGetServerName Lib "ACE32.DLL" ALIAS "AdsGetServerName" (ByVal hConnect As Long, ByVal pucName As String, pusLen As Integer) As Long
DECLARE FUNCTION AdsGetServerTime Lib "ACE32.DLL" ALIAS "AdsGetServerTime" (ByVal hConnect As Long, ByVal pucDateBuf As String, pusDateBufLen As Integer, plTime As Long, ByVal pucTimeBuf As String, pusTimeBufLen As Integer) As Long
DECLARE FUNCTION AdsGetShort Lib "ACE32.DLL" ALIAS "AdsGetShort" (ByVal hTable As Long, ByVal pucFldName As String, psValue As Integer) As Long
DECLARE FUNCTION AdsGetString Lib "ACE32.DLL" ALIAS "AdsGetString" (ByVal hTable As Long, ByVal pucFldName As String, ByVal pucBuf As String, pulLen As Long, ByVal usOption As Integer) As Long
DECLARE FUNCTION AdsGetTableAlias Lib "ACE32.DLL" ALIAS "AdsGetTableAlias" (ByVal hTable As Long, ByVal pucAlias As String, pusLen As Integer) As Long
DECLARE FUNCTION AdsGetTableCharType Lib "ACE32.DLL" ALIAS "AdsGetTableCharType" (ByVal hTable As Long, pusCharType As Integer) As Long
DECLARE FUNCTION AdsGetTableConnection Lib "ACE32.DLL" ALIAS "AdsGetTableConnection" (ByVal hTable As Long, phConnect As Long) As Long
DECLARE FUNCTION AdsGetTableFilename Lib "ACE32.DLL" ALIAS "AdsGetTableFilename" (ByVal hTable As Long, ByVal usOption As Integer, ByVal pucName As String, pusLen As Integer) As Long
DECLARE FUNCTION AdsGetTableHandle Lib "ACE32.DLL" ALIAS "AdsGetTableHandle" (ByVal pucName As String, phTable As Long) As Long
DECLARE FUNCTION AdsGetTableHandle25 Lib "ACE32.DLL" ALIAS "AdsGetTableHandle25" (ByVal hConnect As Long, ByVal pucName As String, phTable As Long) As Long
DECLARE FUNCTION AdsGetTableLockType Lib "ACE32.DLL" ALIAS "AdsGetTableLockType" (ByVal hTable As Long, pusLockType As Integer) As Long
DECLARE FUNCTION AdsGetTableMemoSize Lib "ACE32.DLL" ALIAS "AdsGetTableMemoSize" (ByVal hTable As Long, pusMemoSize As Integer) As Long
DECLARE FUNCTION AdsGetTableOpenOptions Lib "ACE32.DLL" ALIAS "AdsGetTableOpenOptions" (ByVal hTable As Long, pulOptions As Long) As Long
DECLARE FUNCTION AdsGetTableRights Lib "ACE32.DLL" ALIAS "AdsGetTableRights" (ByVal hTable As Long, pusRights As Integer) As Long
DECLARE FUNCTION AdsGetTableType Lib "ACE32.DLL" ALIAS "AdsGetTableType" (ByVal hTable As Long, pusType As Integer) As Long
DECLARE FUNCTION AdsGetTime Lib "ACE32.DLL" ALIAS "AdsGetTime" (ByVal hTable As Long, ByVal pucFldName As String, ByVal pucBuf As String, pusLen As Integer) As Long
DECLARE FUNCTION AdsGetVersion Lib "ACE32.DLL" ALIAS "AdsGetVersion" (pulMajor As Long, pulMinor As Long, ByVal pucLetter As String, ByVal pucDesc As String, pusDescLen As Integer) As Long
DECLARE FUNCTION AdsGotoBookmark Lib "ACE32.DLL" ALIAS "AdsGotoBookmark" (ByVal hTable As Long, ByVal hBookmark As Long) As Long
DECLARE FUNCTION AdsGotoBottom Lib "ACE32.DLL" ALIAS "AdsGotoBottom" (ByVal hObj As Long) As Long
DECLARE FUNCTION AdsGotoRecord Lib "ACE32.DLL" ALIAS "AdsGotoRecord" (ByVal hTable As Long, ByVal ulRec As Long) As Long
DECLARE FUNCTION AdsGotoTop Lib "ACE32.DLL" ALIAS "AdsGotoTop" (ByVal hObj As Long) As Long
DECLARE FUNCTION AdsImageToClipboard Lib "ACE32.DLL" ALIAS "AdsImageToClipboard" (ByVal hTable As Long, ByVal pucFldName As String) As Long
DECLARE FUNCTION AdsInTransaction Lib "ACE32.DLL" ALIAS "AdsInTransaction" (ByVal hConnect As Long, pbInTrans As Integer) As Long
DECLARE FUNCTION AdsIsEmpty Lib "ACE32.DLL" ALIAS "AdsIsEmpty" (ByVal hTable As Long, ByVal pucFldName As String, pbEmpty As Integer) As Long
DECLARE FUNCTION AdsIsExprValid Lib "ACE32.DLL" ALIAS "AdsIsExprValid" (ByVal hTable As Long, ByVal pucExpr As String, pbValid As Integer) As Long
DECLARE FUNCTION AdsIsFound Lib "ACE32.DLL" ALIAS "AdsIsFound" (ByVal hObj As Long, pbFound As Integer) As Long
DECLARE FUNCTION AdsIsIndexCompound Lib "ACE32.DLL" ALIAS "AdsIsIndexCompound" (ByVal hIndex As Long, pbCompound As Integer) As Long
DECLARE FUNCTION AdsIsIndexCustom Lib "ACE32.DLL" ALIAS "AdsIsIndexCustom" (ByVal hIndex As Long, pbCustom As Integer) As Long
DECLARE FUNCTION AdsIsIndexDescending Lib "ACE32.DLL" ALIAS "AdsIsIndexDescending" (ByVal hIndex As Long, pbDescending As Integer) As Long
DECLARE FUNCTION AdsIsIndexUnique Lib "ACE32.DLL" ALIAS "AdsIsIndexUnique" (ByVal hIndex As Long, pbUnique As Integer) As Long
DECLARE FUNCTION AdsIsRecordDeleted Lib "ACE32.DLL" ALIAS "AdsIsRecordDeleted" (ByVal hTable As Long, pbDeleted As Integer) As Long
DECLARE FUNCTION AdsIsRecordEncrypted Lib "ACE32.DLL" ALIAS "AdsIsRecordEncrypted" (ByVal hTable As Long, pbEncrypted As Integer) As Long
DECLARE FUNCTION AdsIsRecordLocked Lib "ACE32.DLL" ALIAS "AdsIsRecordLocked" (ByVal hTable As Long, ByVal ulRec As Long, pbLocked As Integer) As Long
DECLARE FUNCTION AdsIsRecordVisable Lib "ACE32.DLL" ALIAS "AdsIsRecordVisable" (ByVal hTable As Long, pbVisable As Integer) As Long
DECLARE FUNCTION AdsIsServerLoaded Lib "ACE32.DLL" ALIAS "AdsIsServerLoaded" (ByVal pucServer As String, pbLoaded As Integer) As Long
DECLARE FUNCTION AdsIsTableEncrypted Lib "ACE32.DLL" ALIAS "AdsIsTableEncrypted" (ByVal hTable As Long, pbEncrypted As Integer) As Long
DECLARE FUNCTION AdsIsTableLocked Lib "ACE32.DLL" ALIAS "AdsIsTableLocked" (ByVal hTable As Long, pbLocked As Integer) As Long
DECLARE FUNCTION AdsLocate Lib "ACE32.DLL" ALIAS "AdsLocate" (ByVal hTable As Long, ByVal pucExpr As String, ByVal bForward As Integer, pbFound As Integer) As Long
DECLARE FUNCTION AdsLockRecord Lib "ACE32.DLL" ALIAS "AdsLockRecord" (ByVal hTable As Long, ByVal ulRec As Long) As Long
DECLARE FUNCTION AdsLockTable Lib "ACE32.DLL" ALIAS "AdsLockTable" (ByVal hTable As Long) As Long
DECLARE FUNCTION AdsLookupKey Lib "ACE32.DLL" ALIAS "AdsLookupKey" (ByVal hIndex As Long, ByVal pucKey As String, ByVal usKeyLen As Integer, ByVal usDataType As Integer, pbFound As Integer) As Long
DECLARE FUNCTION AdsNullTerminateStrings Lib "ACE32.DLL" ALIAS "AdsNullTerminateStrings" (ByVal bNullTerminate As Integer) As Long
DECLARE FUNCTION AdsOpenIndex Lib "ACE32.DLL" ALIAS "AdsOpenIndex" (ByVal hTable As Long, ByVal pucName As String, ahIndex As Long, pusArrayLen As Integer) As Long
DECLARE FUNCTION AdsOpenTable Lib "ACE32.DLL" ALIAS "AdsOpenTable" (ByVal hConnect As Long, ByVal pucName As String, ByVal pucAlias As String, ByVal usTableType As Integer, ByVal usCharType As Integer, ByVal usLockType As Integer, ByVal usCheckRights As Integer, ByVal ulOptions As Long, phTable As Long) As Long
DECLARE FUNCTION AdsPackTable Lib "ACE32.DLL" ALIAS "AdsPackTable" (ByVal hTable As Long) As Long
DECLARE FUNCTION AdsRecallRecord Lib "ACE32.DLL" ALIAS "AdsRecallRecord" (ByVal hTable As Long) As Long
DECLARE FUNCTION AdsRefreshRecord Lib "ACE32.DLL" ALIAS "AdsRefreshRecord" (ByVal hTable As Long) As Long
DECLARE FUNCTION AdsClearProgressCallback Lib "ACE32.DLL" ALIAS "AdsClearProgressCallback" () As Long

'NOTE: The following functions are not callable from Visual Basic
'DECLARE FUNCTION AdsRegisterProgressCallback Lib "ACE32.DLL" ALIAS "" (lpfnCallback as long)(ByVal usPercent as Integer ) ) as Long
'DECLARE FUNCTION AdsRegisterCallbackFunction Lib "ACE32.DLL" ALIAS "" (lpfnCallback as long)(ByVal usPercent as Integer, ByVal ulCallbackID as Long ) as Long
'DECLARE FUNCTION AdsClearCallbackFunction Lib "ACE32.DLL" ALIAS "" () As Long

DECLARE FUNCTION AdsReindex Lib "ACE32.DLL" ALIAS "AdsReindex" (ByVal hTable As Long) As Long
DECLARE FUNCTION AdsReindex61 Lib "ACE32.DLL" ALIAS "AdsReindex61" (ByVal hTable As Long, ByVal ulPageSize As Long) As Long
DECLARE FUNCTION AdsRollbackTransaction Lib "ACE32.DLL" ALIAS "AdsRollbackTransaction" (ByVal hConnect As Long) As Long
DECLARE FUNCTION AdsSeek Lib "ACE32.DLL" ALIAS "AdsSeek" (ByVal hIndex As Long, ByVal pucKey As String, ByVal usKeyLen As Integer, ByVal usDataType As Integer, ByVal usSeekType As Integer, pbFound As Integer) As Long
DECLARE FUNCTION AdsSeekLast Lib "ACE32.DLL" ALIAS "AdsSeekLast" (ByVal hIndex As Long, ByVal pucKey As String, ByVal usKeyLen As Integer, ByVal usDataType As Integer, pbFound As Integer) As Long
DECLARE FUNCTION AdsSetBinary Lib "ACE32.DLL" ALIAS "AdsSetBinary" (ByVal hTable As Long, ByVal pucFldName As String, ByVal usBinaryType As Integer, ByVal ulTotalLength As Long, ByVal ulOffset As Long, ByVal pucBuf As String, ByVal ulLen As Long) As Long
DECLARE FUNCTION AdsSetCollationLang Lib "ACE32.DLL" ALIAS "AdsSetCollationLang" (ByVal pucLang As String) As Long
DECLARE FUNCTION AdsSetDate Lib "ACE32.DLL" ALIAS "AdsSetDate" (ByVal hObj As Long, ByVal pucFldName As String, ByVal pucValue As String, ByVal usLen As Integer) As Long
DECLARE FUNCTION AdsSetDateFormat Lib "ACE32.DLL" ALIAS "AdsSetDateFormat" (ByVal pucFormat As String) As Long
DECLARE FUNCTION AdsSetDecimals Lib "ACE32.DLL" ALIAS "AdsSetDecimals" (ByVal usDecimals As Integer) As Long
DECLARE FUNCTION AdsSetDefault Lib "ACE32.DLL" ALIAS "AdsSetDefault" (ByVal pucDefault As String) As Long
DECLARE FUNCTION AdsShowDeleted Lib "ACE32.DLL" ALIAS "AdsShowDeleted" (ByVal bShowDeleted As Integer) As Long
DECLARE FUNCTION AdsSetDouble Lib "ACE32.DLL" ALIAS "AdsSetDouble" (ByVal hObj As Long, ByVal pucFldName As String, ByVal dValue As Double) As Long
DECLARE FUNCTION AdsSetEmpty Lib "ACE32.DLL" ALIAS "AdsSetEmpty" (ByVal hObj As Long, ByVal pucFldName As String) As Long
DECLARE FUNCTION AdsSetEpoch Lib "ACE32.DLL" ALIAS "AdsSetEpoch" (ByVal usCentury As Integer) As Long
DECLARE FUNCTION AdsSetExact Lib "ACE32.DLL" ALIAS "AdsSetExact" (ByVal bExact As Integer) As Long
DECLARE FUNCTION AdsSetExact22 Lib "ACE32.DLL" ALIAS "AdsSetExact22" (ByVal hObj As Long, ByVal bExact As Integer) As Long
DECLARE FUNCTION AdsSetField Lib "ACE32.DLL" ALIAS "AdsSetField" (ByVal hObj As Long, ByVal pucFldName As String, ByVal pucBuf As String, ByVal ulLen As Long) As Long
DECLARE FUNCTION AdsSetFilter Lib "ACE32.DLL" ALIAS "AdsSetFilter" (ByVal hTable As Long, ByVal pucFilter As String) As Long
DECLARE FUNCTION AdsSetHandleLong Lib "ACE32.DLL" ALIAS "AdsSetHandleLong" (ByVal hObj As Long, ByVal ulVal As Long) As Long
DECLARE FUNCTION AdsSetJulian Lib "ACE32.DLL" ALIAS "AdsSetJulian" (ByVal hObj As Long, ByVal pucFldName As String, ByVal lDate As Long) As Long
DECLARE FUNCTION AdsSetLogical Lib "ACE32.DLL" ALIAS "AdsSetLogical" (ByVal hObj As Long, ByVal pucFldName As String, ByVal bValue As Integer) As Long
DECLARE FUNCTION AdsSetLong Lib "ACE32.DLL" ALIAS "AdsSetLong" (ByVal hObj As Long, ByVal pucFldName As String, ByVal lValue As Long) As Long
DECLARE FUNCTION AdsSetMilliseconds Lib "ACE32.DLL" ALIAS "AdsSetMilliseconds" (ByVal hObj As Long, ByVal pucFldName As String, ByVal lTime As Long) As Long
DECLARE FUNCTION AdsSetRecord Lib "ACE32.DLL" ALIAS "AdsSetRecord" (ByVal hObj As Long, ByVal pucRec As String, ByVal ulLen As Long) As Long
DECLARE FUNCTION AdsSetRelation Lib "ACE32.DLL" ALIAS "AdsSetRelation" (ByVal hTableParent As Long, ByVal hIndexChild As Long, ByVal pucExpr As String) As Long
DECLARE FUNCTION AdsSetRelKeyPos Lib "ACE32.DLL" ALIAS "AdsSetRelKeyPos" (ByVal hIndex As Long, ByVal dPos As Double) As Long
DECLARE FUNCTION AdsSetScope Lib "ACE32.DLL" ALIAS "AdsSetScope" (ByVal hIndex As Long, ByVal usScopeOption As Integer, ByVal pucScope As String, ByVal usScopeLen As Integer, ByVal usDataType As Integer) As Long
DECLARE FUNCTION AdsSetScopedRelation Lib "ACE32.DLL" ALIAS "AdsSetScopedRelation" (ByVal hTableParent As Long, ByVal hIndexChild As Long, ByVal pucExpr As String) As Long
DECLARE FUNCTION AdsSetSearchPath Lib "ACE32.DLL" ALIAS "AdsSetSearchPath" (ByVal pucPath As String) As Long
DECLARE FUNCTION AdsSetServerType Lib "ACE32.DLL" ALIAS "AdsSetServerType" (ByVal usServerOptions As Integer) As Long
DECLARE FUNCTION AdsSetShort Lib "ACE32.DLL" ALIAS "AdsSetShort" (ByVal hObj As Long, ByVal pucFldName As String, ByVal sValue As Integer) As Long
DECLARE FUNCTION AdsSetString Lib "ACE32.DLL" ALIAS "AdsSetString" (ByVal hObj As Long, ByVal pucFldName As String, ByVal pucBuf As String, ByVal ulLen As Long) As Long
DECLARE FUNCTION AdsSetTime Lib "ACE32.DLL" ALIAS "AdsSetTime" (ByVal hObj As Long, ByVal pucFldName As String, ByVal pucValue As String, ByVal usLen As Integer) As Long
DECLARE FUNCTION AdsShowError Lib "ACE32.DLL" ALIAS "AdsShowError" (ByVal pucTitle As String) As Long
DECLARE FUNCTION AdsSkip Lib "ACE32.DLL" ALIAS "AdsSkip" (ByVal hObj As Long, ByVal lRecs As Long) As Long
DECLARE FUNCTION AdsThreadExit Lib "ACE32.DLL" ALIAS "AdsThreadExit" () As Long
DECLARE FUNCTION AdsUnlockRecord Lib "ACE32.DLL" ALIAS "AdsUnlockRecord" (ByVal hTable As Long, ByVal ulRec As Long) As Long
DECLARE FUNCTION AdsUnlockTable Lib "ACE32.DLL" ALIAS "AdsUnlockTable" (ByVal hTable As Long) As Long
'/* AdsVerifyPassword is obsolete, retained for backward compatibility.
' * Use AdsIsEncryptionEnabled instead. */
DECLARE FUNCTION AdsVerifyPassword Lib "ACE32.DLL" ALIAS "AdsVerifyPassword" (ByVal hTable As Long, pusIsValid As Integer) As Long
DECLARE FUNCTION AdsIsEncryptEnabled Lib "ACE32.DLL" ALIAS "AdsIsEncryptEnabled" (ByVal hTable As Long, pusIsValid As Integer) As Long
DECLARE FUNCTION AdsWriteAllRecords Lib "ACE32.DLL" ALIAS "AdsWriteAllRecords" () As Long
DECLARE FUNCTION AdsWriteRecord Lib "ACE32.DLL" ALIAS "AdsWriteRecord" (ByVal hTable As Long) As Long
DECLARE FUNCTION AdsZapTable Lib "ACE32.DLL" ALIAS "AdsZapTable" (ByVal hTable As Long) As Long
DECLARE FUNCTION AdsSetAOF Lib "ACE32.DLL" ALIAS "AdsSetAOF" (ByVal hTable As Long, ByVal pucFilter As String, ByVal usResolve As Integer) As Long
DECLARE FUNCTION AdsEvalAOF Lib "ACE32.DLL" ALIAS "AdsEvalAOF" (ByVal hTable As Long, ByVal pucFilter As String, pusOptLevel As Integer) As Long
DECLARE FUNCTION AdsClearAOF Lib "ACE32.DLL" ALIAS "AdsClearAOF" (ByVal hTable As Long) As Long
DECLARE FUNCTION AdsRefreshAOF Lib "ACE32.DLL" ALIAS "AdsRefreshAOF" (ByVal hTable As Long) As Long
DECLARE FUNCTION AdsGetAOF Lib "ACE32.DLL" ALIAS "AdsGetAOF" (ByVal hTable As Long, ByVal pucFilter As String, pusLen As Integer) As Long
DECLARE FUNCTION AdsGetAOFOptLevel Lib "ACE32.DLL" ALIAS "AdsGetAOFOptLevel" (ByVal hTable As Long, pusOptLevel As Integer, ByVal pucNonOpt As String, pusLen As Integer) As Long
DECLARE FUNCTION AdsIsRecordInAOF Lib "ACE32.DLL" ALIAS "AdsIsRecordInAOF" (ByVal hTable As Long, ByVal ulRecord As Long, pusIsInAOF As Integer) As Long
DECLARE FUNCTION AdsCustomizeAOF Lib "ACE32.DLL" ALIAS "AdsCustomizeAOF" (ByVal hTable As Long, ByVal ulNumRecords As Long, pulRecords As Long, ByVal usOption As Integer) As Long
DECLARE FUNCTION AdsInitRawKey Lib "ACE32.DLL" ALIAS "AdsInitRawKey" (ByVal hIndex As Long) As Long
DECLARE FUNCTION AdsBuildRawKey Lib "ACE32.DLL" ALIAS "AdsBuildRawKey" (ByVal hIndex As Long, ByVal pucKey As String, pusLen As Integer) As Long
DECLARE FUNCTION AdsCreateSQLStatement Lib "ACE32.DLL" ALIAS "AdsCreateSQLStatement" (ByVal hConnect As Long, phStatement As Long) As Long
DECLARE FUNCTION AdsPrepareSQL Lib "ACE32.DLL" ALIAS "AdsPrepareSQL" (ByVal hStatement As Long, ByVal pucSQL As String) As Long
DECLARE FUNCTION AdsExecuteSQL Lib "ACE32.DLL" ALIAS "AdsExecuteSQL" (ByVal hStatement As Long, phCursor As Long) As Long
DECLARE FUNCTION AdsExecuteSQLDirect Lib "ACE32.DLL" ALIAS "AdsExecuteSQLDirect" (ByVal hStatement As Long, ByVal pucSQL As String, phCursor As Long) As Long
DECLARE FUNCTION AdsCloseSQLStatement Lib "ACE32.DLL" ALIAS "AdsCloseSQLStatement" (ByVal hStatement As Long) As Long
DECLARE FUNCTION AdsStmtSetTableRights Lib "ACE32.DLL" ALIAS "AdsStmtSetTableRights" (ByVal hStatement As Long, ByVal usCheckRights As Integer) As Long
DECLARE FUNCTION AdsStmtSetTableReadOnly Lib "ACE32.DLL" ALIAS "AdsStmtSetTableReadOnly" (ByVal hStatement As Long, ByVal usReadOnly As Integer) As Long
DECLARE FUNCTION AdsStmtSetTableLockType Lib "ACE32.DLL" ALIAS "AdsStmtSetTableLockType" (ByVal hStatement As Long, ByVal usLockType As Integer) As Long
DECLARE FUNCTION AdsStmtSetTableCharType Lib "ACE32.DLL" ALIAS "AdsStmtSetTableCharType" (ByVal hStatement As Long, ByVal usCharType As Integer) As Long
DECLARE FUNCTION AdsStmtSetTableType Lib "ACE32.DLL" ALIAS "AdsStmtSetTableType" (ByVal hStatement As Long, ByVal usTableType As Integer) As Long
DECLARE FUNCTION AdsStmtCONSTrainUpdates Lib "ACE32.DLL" ALIAS "AdsStmtCONSTrainUpdates" (ByVal hStatement As Long, ByVal usCONSTrain As Integer) As Long
DECLARE FUNCTION AdsStmtEnableEncryption Lib "ACE32.DLL" ALIAS "AdsStmtEnableEncryption" (ByVal hStatement As Long, ByVal pucPassword As String) As Long
DECLARE FUNCTION AdsStmtDisableEncryption Lib "ACE32.DLL" ALIAS "AdsStmtDisableEncryption" (ByVal hStatement As Long) As Long
DECLARE FUNCTION AdsStmtSetTablePassword Lib "ACE32.DLL" ALIAS "AdsStmtSetTablePassword" (ByVal hStatement As Long, ByVal pucTableName As String, ByVal pucPassword As String) As Long
DECLARE FUNCTION AdsStmtClearTablePasswords Lib "ACE32.DLL" ALIAS "AdsStmtClearTablePasswords" (ByVal hStatement As Long) As Long
DECLARE FUNCTION AdsStmtReadAllColumns Lib "ACE32.DLL" ALIAS "AdsStmtReadAllColumns" (ByVal hStatement As Long, ByVal usReadColumns As Integer) As Long
DECLARE FUNCTION AdsClearSQLParams Lib "ACE32.DLL" ALIAS "AdsClearSQLParams" (ByVal hStatement As Long) As Long
DECLARE FUNCTION AdsSetTimeStamp Lib "ACE32.DLL" ALIAS "AdsSetTimeStamp" (ByVal hObj As Long, ByVal pucFldName As String, ByVal pucBuf As String, ByVal ulLen As Long) As Long

'NOTE: The following functions are not callable from Visual Basic
'DECLARE FUNCTION AdsClearSQLAbortFunc Lib "ACE32.DLL" ALIAS "" () as Long
'DECLARE FUNCTION AdsRegisterSQLAbortFunc Lib "ACE32.DLL" ALIAS "" (UNSIGNED32 (WINAPI *lpfnCallback)() ) as Long
'DECLARE FUNCTION AdsRegisterUDF Lib "ACE32.DLL" ALIAS "" (ByVal hObj As Long, ByVal usLen As Integer, UNSIGNED32 (WINAPI *lpfnUDF)() ) as Long

DECLARE FUNCTION AdsGetNumParams Lib "ACE32.DLL" ALIAS "AdsGetNumParams" (ByVal hStatement As Long, pusNumParams As Integer) As Long
DECLARE FUNCTION AdsGetLastAutoinc Lib "ACE32.DLL" ALIAS "AdsGetLastAutoinc" (ByVal hObj As Long, pulAutoIncVal As Long) As Long
DECLARE FUNCTION AdsIsIndexUserDefined Lib "ACE32.DLL" ALIAS "AdsIsIndexUserDefined" (ByVal hIndex As Long, pbUserDefined As Integer) As Long
DECLARE FUNCTION AdsFindClose Lib "ACE32.DLL" ALIAS "AdsFindClose" (ByVal hConnect As Long, ByVal lHandle As Long) As Long
DECLARE FUNCTION AdsFindFirstTable Lib "ACE32.DLL" ALIAS "AdsFindFirstTable" (ByVal hConnect As Long, ByVal pucFileMask As String, ByVal pucFirstFile As String, pusFileLen As Integer, plHandle As Long) As Long
DECLARE FUNCTION AdsFindNextTable Lib "ACE32.DLL" ALIAS "AdsFindNextTable" (ByVal hConnect As Long, ByVal lHandle As Long, ByVal pucFileName As String, pusFileLen As Integer) As Long
DECLARE FUNCTION AdsFindFirstTable62 Lib "ACE32.DLL" ALIAS "AdsFindFirstTable62" (ByVal hConnect As Long, ByVal pucFileMask As String, ByVal pucFirstDD As String, pusDDLen As Integer, ByVal pucFirstFile As String, pusFileLen As Integer, plHandle As Long) As Long
DECLARE FUNCTION AdsFindNextTable62 Lib "ACE32.DLL" ALIAS "AdsFindNextTable62" (ByVal hConnect As Long, ByVal lHandle As Long, ByVal pucDDName As String, pusDDLen As Integer, ByVal pucFileName As String, pusFileLen As Integer) As Long
DECLARE FUNCTION AdsRestructureTable Lib "ACE32.DLL" ALIAS "AdsRestructureTable" (ByVal hObj As Long, ByVal pucName As String, ByVal pucAlias As String, ByVal usTableType As Integer, ByVal usCharType As Integer, ByVal usLockType As Integer, ByVal usCheckRights As Integer, ByVal pucAddFields As String, ByVal pucDeleteFields As String, ByVal pucChangeFields As String) As Long
DECLARE FUNCTION AdsGetSQLStatementHandle Lib "ACE32.DLL" ALIAS "AdsGetSQLStatementHandle" (ByVal hCursor As Long, phStmt As Long) As Long
DECLARE FUNCTION AdsGetSQLStatement Lib "ACE32.DLL" ALIAS "AdsGetSQLStatement" (ByVal hStmt As Long, ByVal pucSQL As String, pusLen As Integer) As Long
DECLARE FUNCTION AdsGetBookmark60 Lib "ACE32.DLL" ALIAS "AdsGetBookmark60" (ByVal hObj As Long, ByVal pucBookmark As String, pulLength As Long) As Long
DECLARE FUNCTION AdsGetBookmarkLength Lib "ACE32.DLL" ALIAS "AdsGetBookmarkLength" (ByVal hObj As Long, pulLength As Long) As Long
DECLARE FUNCTION AdsCompareBookmarks Lib "ACE32.DLL" ALIAS "AdsCompareBookmarks" (pucBookmark1 As String, ByVal pucBookmark2 As String, plResult As Long) As Long
DECLARE FUNCTION AdsGotoBookmark60 Lib "ACE32.DLL" ALIAS "AdsGotoBookmark60" (ByVal hObj As Long, ByVal pucBookmark As String) As Long
DECLARE FUNCTION AdsFlushFileBuffers Lib "ACE32.DLL" ALIAS "AdsFlushFileBuffers" (ByVal hTable As Long) As Long
DECLARE FUNCTION AdsDDDeployDatabase Lib "ACE32.DLL" ALIAS "AdsDDDeployDatabase" (ByVal pucDestination As String, ByVal pucDestinationPassword As String, ByVal pucSource As String, ByVal pucSourcePassword As String, ByVal ulServerType As Long, ByVal ulValidateOptions As Long, ByVal usBackupFiles As Integer, ByVal ulOptions As Long) As Long
DECLARE FUNCTION AdsVerifySQL Lib "ACE32.DLL" ALIAS "AdsVerifySQL" (ByVal hStatement As Long, ByVal pucSQL As String) As Long
DECLARE FUNCTION AdsGetActiveLinkInfo Lib "ACE32.DLL" ALIAS "AdsGetActiveLinkInfo" (ByVal hDBConn As Long, ByVal usLinkNum As Integer, ByVal pucLinkInfo As String, pusBufferLen As Integer ) As Long
DECLARE FUNCTION AdsGetNumActiveLinks Lib "ACE32.DLL" ALIAS "AdsGetNumActiveLinks" (ByVal hDBConn As Long, pusNumLinks As Integer ) As Long
DECLARE FUNCTION AdsEnableUniqueEnforcement Lib "ACE32.DLL" ALIAS "AdsEnableUniqueEnforcement" (ByVal hConnect As Long ) As Long
DECLARE FUNCTION AdsDisableUniqueEnforcement Lib "ACE32.DLL" ALIAS "AdsDisableUniqueEnforcement" (ByVal hConnect As Long ) As Long
DECLARE FUNCTION AdsEnableRI Lib "ACE32.DLL" ALIAS "AdsEnableRI" (ByVal hConnect As Long ) As Long
DECLARE FUNCTION AdsDisableRI Lib "ACE32.DLL" ALIAS "AdsDisableRI" (ByVal hConnect As Long ) As Long
DECLARE FUNCTION AdsEnableAutoIncEnforcement Lib "ACE32.DLL" ALIAS "AdsEnableAutoIncEnforcement" (ByVal hConnect As Long ) As Long
DECLARE FUNCTION AdsDisableAutoIncEnforcement Lib "ACE32.DLL" ALIAS "AdsDisableAutoIncEnforcement" (ByVal hConnect As Long ) As Long
'/* EOF */

$ENDIF   ' IncManager: __ACE32_INC
