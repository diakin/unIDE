' TRM_RQDeclares.INC - отдельный inc, не входит в rapidqAllProc.inc /
' rapidqComponents.inc: своя DLL TRM.DLL.
' Собран rapidq_ref/tools/build_inc.py из incOld/TRM_RQDeclares.INC; повторы объявлений
' общих файлов убраны (build_removed.txt). Подключать в программе,
' которой он нужен.
$IFNDEF __SEP_TRM_RQDECLARES_INC
$DEFINE __SEP_TRM_RQDECLARES_INC
$INCLUDE "rapidqComponents.inc"
'============================================================================
'[build_inc] TRM_RQDeclares.INC
'============================================================================

' TRM_RQDeclares.INC - INCLUDE file for the Tsunami Record Manager - TRM.DLL

' EQUATES and DECLARES for 32-bit PowerBASIC compilers

' Version 2.5 ... 2003-04-15

 const CASE_SENSITIVE  = 1
 const NO_DUPLICATES   = 2
 const NO_COMPRESSION  = 4
 const BINARY_KEY      = 8
 const KEY_ONLY        = 4096
 const REBUILD_IDS     = 2

'--- String base API

' DECLARE FUNCTION trm_Accelerate        LIB "TRM.DLL" ALIAS "trm_Accelerate"        (FileHandle AS LONG, CacheSize AS LONG) AS LONG
' DECLARE FUNCTION trm_Close             LIB "TRM.DLL" ALIAS "trm_Close"             (FileHandle AS LONG) AS LONG
' DECLARE FUNCTION trm_CloseAll          LIB "TRM.DLL" ALIAS "trm_CloseAll"          () AS LONG
' DECLARE FUNCTION trm_Count             LIB "TRM.DLL" ALIAS "trm_Count"             (FileHandle AS LONG) AS LONG
' DECLARE FUNCTION trm_Create            LIB "TRM.DLL" ALIAS "trm_Create"            (PathFileName AS STRING, FileDef AS STRING, OverWrite AS LONG) AS LONG
' DECLARE FUNCTION trm_CurrKeyPos        LIB "TRM.DLL" ALIAS "trm_CurrKeyPos"        (FileHandle AS LONG) AS LONG
' DECLARE FUNCTION trm_Delete            LIB "TRM.DLL" ALIAS "trm_Delete"            (FileHandle AS LONG) AS LONG
' DECLARE FUNCTION trm_FileIsOpen        LIB "TRM.DLL" ALIAS "trm_FileIsOpen"        (FileHandle AS LONG) AS LONG
' DECLARE FUNCTION trm_FileSize          LIB "TRM.DLL" ALIAS "trm_FileSize"          (FileHandle AS LONG) AS LONG
' DECLARE FUNCTION trm_Flush             LIB "TRM.DLL" ALIAS "trm_Flush"             () AS LONG
' DECLARE FUNCTION trm_GetByKeyPos       LIB "TRM.DLL" ALIAS "trm_GetByKeyPos"       (FileHandle AS LONG, KeyPos AS LONG) AS STRING
' DECLARE FUNCTION trm_GetDirect         LIB "TRM.DLL" ALIAS "trm_GetDirect"         (FileHandle AS LONG, RecordPtr AS STRING) AS STRING
' DECLARE FUNCTION trm_GetEqual          LIB "TRM.DLL" ALIAS "trm_GetEqual"          (FileHandle AS LONG, KeyNo AS LONG, KeyVal AS STRING) AS STRING
' DECLARE FUNCTION trm_GetEqualOrGreater LIB "TRM.DLL" ALIAS "trm_GetEqualOrGreater" (FileHandle AS LONG, KeyNo AS LONG, KeyVal AS STRING) AS STRING
' DECLARE FUNCTION trm_GetEqualOrLess    LIB "TRM.DLL" ALIAS "trm_GetEqualOrLess"    (FileHandle AS LONG, KeyNo AS LONG, KeyVal AS STRING) AS STRING
' DECLARE FUNCTION trm_GetFileDef        LIB "TRM.DLL" ALIAS "trm_GetFileDef"        (FileHandle AS LONG) AS STRING
' DECLARE FUNCTION trm_GetFileVer        LIB "TRM.DLL" ALIAS "trm_GetFileVer"        (FileHandle AS LONG) AS STRING
' DECLARE FUNCTION trm_GetFirst          LIB "TRM.DLL" ALIAS "trm_GetFirst"          (FileHandle AS LONG, KeyNo AS LONG) AS STRING
' DECLARE FUNCTION trm_GetGreater        LIB "TRM.DLL" ALIAS "trm_GetGreater"        (FileHandle AS LONG, KeyNo AS LONG, KeyVal AS STRING) AS STRING
' DECLARE FUNCTION trm_GetLast           LIB "TRM.DLL" ALIAS "trm_GetLast"           (FileHandle AS LONG, KeyNo AS LONG) AS STRING
' DECLARE FUNCTION trm_GetLess           LIB "TRM.DLL" ALIAS "trm_GetLess"           (FileHandle AS LONG, KeyNo AS LONG, KeyVal AS STRING) AS STRING
' DECLARE FUNCTION trm_GetNext           LIB "TRM.DLL" ALIAS "trm_GetNext"           (FileHandle AS LONG) AS STRING
' DECLARE FUNCTION trm_GetPosition       LIB "TRM.DLL" ALIAS "trm_GetPosition"       (FileHandle AS LONG, Direction AS LONG) AS STRING
' DECLARE FUNCTION trm_GetPrev           LIB "TRM.DLL" ALIAS "trm_GetPrev"           (FileHandle AS LONG) AS STRING
' DECLARE FUNCTION trm_Insert            LIB "TRM.DLL" ALIAS "trm_Insert"            (FileHandle AS LONG, Record AS STRING) AS LONG
' DECLARE FUNCTION trm_Integrity         LIB "TRM.DLL" ALIAS "trm_Integrity"         (FileHandle AS LONG) AS LONG
' DECLARE FUNCTION trm_Open              LIB "TRM.DLL" ALIAS "trm_Open"              (PathFileName AS STRING, MultiUser AS LONG) AS LONG
' DECLARE FUNCTION trm_Rebuild           LIB "TRM.DLL" ALIAS "trm_Rebuild"           (PathFileName AS STRING, SaveFile AS STRING, FileDef AS STRING) AS LONG
' DECLARE FUNCTION trm_Recover           LIB "TRM.DLL" ALIAS "trm_Recover"           (PathFileName AS STRING, OutFile AS STRING, PageSize AS LONG, Compression AS LONG) AS LONG
' DECLARE FUNCTION trm_Result            LIB "TRM.DLL" ALIAS "trm_Result"            (FileHandle AS LONG) AS LONG
' DECLARE FUNCTION trm_SetKeyPath        LIB "TRM.DLL" ALIAS "trm_SetKeyPath"        (FileHandle AS LONG, KeyNo AS LONG) AS LONG
' DECLARE FUNCTION trm_StepFirst         LIB "TRM.DLL" ALIAS "trm_StepFirst"         (FileHandle AS LONG) AS STRING
' DECLARE FUNCTION trm_StepLast          LIB "TRM.DLL" ALIAS "trm_StepLast"          (FileHandle AS LONG) AS STRING
' DECLARE FUNCTION trm_StepNext          LIB "TRM.DLL" ALIAS "trm_StepNext"          (FileHandle AS LONG) AS STRING
' DECLARE FUNCTION trm_StepPrev          LIB "TRM.DLL" ALIAS "trm_StepPrev"          (FileHandle AS LONG) AS STRING
' DECLARE FUNCTION trm_TimeOut           LIB "TRM.DLL" ALIAS "trm_TimeOut"           (Limit AS LONG) AS LONG
' DECLARE FUNCTION trm_Update            LIB "TRM.DLL" ALIAS "trm_Update"            (FileHandle AS LONG, Record AS STRING) AS LONG
' DECLARE FUNCTION trm_Version           LIB "TRM.DLL" ALIAS "trm_Version"           () AS LONG

'--- Pointer based API's
 
' DECLARE FUNCTION trm                   LIB "TRM.DLL" ALIAS "trm"                   (Op AS LONG, File AS LONG, DataPtr AS LONG, DataLen AS LONG, KeyPtr AS LONG, KeyLen AS LONG, KeyNo AS LONG) AS LONG
 DECLARE FUNCTION trm_udt               LIB "TRM.DLL" ALIAS "trm_udt"                (CmdTsu AS LONG) AS LONG

'--- Pointer based API UDT type 
 
 TYPE TRMtype
    op      AS LONG  ' Tsunami operation number
    file    AS LONG  ' Tsunami file handle
    dataptr AS LONG  ' Address of data buffer
    datalen AS LONG  ' Length of data buffer
    keyptr  AS LONG  ' Address of key buffer
    keylen  AS LONG  ' Length of key buffer
    keyno   AS LONG  ' Key number
 END TYPE

 TYPE TRMdKey
      FDef    as String * 93  'Definition key is stored here for processing multiple keys
      PageSize AS Byte         'Byte 1 = Chr(PageSize) ; 1 - 8 Ascii value 
      Compress AS Byte         'Byte 2 = Chr(Compress) : #True or #False 
      Segments AS Byte         'Byte 3 = Chr(Segments) ; 1 - 128 Ascii value 
      SegName  AS String * 25  'Byte 4 - 28 = Description ; a 25 byte description of the key 
         KeyNo    AS Byte      'Byte 29 = Chr(KeyNo) ; 1 - 128 Ascii value 
         KeyPos   AS Word      'Byte 30 - 31 = Chr(KeyPos Mod 256)+ Chr(KeyPos / 256) ; key position in string 1 - 65535 
         KeyLen   AS Byte      'Byte 32 = Chr(KeyLen) ; 1 - 255 Ascii value 
         KeyFlags AS Byte      'Byte 33 = Chr(KeyFlags) : a bit mask created by adding possible flag values 
 END TYPE
 
 const  Tsu_Accelerate        = 32
 const  Tsu_Close             =  1
 const  Tsu_CloseAll          = 28
 const  Tsu_Count             = 17
 const  Tsu_Create            = 14
 const  Tsu_CurrKeyPos        = 45
 const  Tsu_Delete            =  4
 const  Tsu_FileIsOpen        = 16
 const  Tsu_FileSize          = 18
 const  Tsu_Flush             = 29
 const  Tsu_GetByKeyPos       = 44
 const  Tsu_GetDirect         = 23
 const  Tsu_GetEqual          =  5
 const  Tsu_GetEqualOrGreater =  9
 const  Tsu_GetEqualOrLess    = 11
 const  Tsu_GetFileDef        = 36
 const  Tsu_GetFileVer        = 25
 const  Tsu_GetFirst          = 12
 const  Tsu_GetGreater        =  8
 const  Tsu_GetLast           = 13
 const  Tsu_GetLess           = 10
 const  Tsu_GetNext           =  6
 const  Tsu_GetPosition       = 22
 const  Tsu_GetPrev           =  7
 const  Tsu_Insert            =  2
 const  Tsu_Integrity         = 37
 const  Tsu_Open              =  0
 const  Tsu_Rebuild           = 38
 const  Tsu_Recover           = 39
 const  Tsu_SetKeyPath        = 30
 const  Tsu_StepFirst         = 33
 const  Tsu_StepLast          = 34
 const  Tsu_StepNext          = 24
 const  Tsu_StepPrev          = 35
 const  Tsu_TimeOut           = 31
 const  Tsu_Update            =  3
 const  Tsu_Version           = 26
  
$ENDIF ' __SEP_TRM_RQDECLARES_INC
