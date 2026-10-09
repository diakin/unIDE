''
''
'' Port of zlib include file from FreeBasic to RapidQ 
''-- header translated with help of SWIG FB wrapper
''  -JohnK
''
$ifndef __zlib_inc
$define __zlib_inc

'' zconf.bi
$define MAX_MEM_LEVEL 9
$define MAX_WBITS 15

$ifndef SEEK_SET
$define SEEK_SET 0
$define SEEK_CUR 1
$define SEEK_END 2
$endif

$define ZLIB_VERSION "1.2.2"
$define ZLIB_VERNUM &h1220
'this crashes
' $IFDEF WIN32        'we running windows?
'  $macro ZLIB_DLL zlibwapi.dll
' $ELSE
'  $macro ZLIB_DLL zlib.dll
' $ENDIF


type internal_state
	dummy as integer
end type

type z_stream
	next_in as long        'Byte ptr
	avail_in as long
	total_in as long
	next_out as long       'Byte ptr
	avail_out as long
	total_out as long
	msg as long            'byte ptr
	lpstate as long        'internal_state ptr
	zalloc as long         'alloc_func       'type alloc_func as function cdecl(byval as long, byval as long, byval as long) as long
	zfree as long          'free_func         'type free_func as sub cdecl(byval as long, byval as long)
	opaque as long
	data_type as integer
	adler as long
	reserved as long
end type
'type z_stream as z_stream_s
'type z_streamp as z_stream ptr

$define Z_NO_FLUSH 0
$define Z_PARTIAL_FLUSH 1
$define Z_SYNC_FLUSH 2
$define Z_FULL_FLUSH 3
$define Z_FINISH 4
$define Z_BLOCK 5
$define Z_OK 0
$define Z_STREAM_END 1
$define Z_NEED_DICT 2
$define Z_ERRNO (-1)
$define Z_STREAM_ERROR (-2)
$define Z_DATA_ERROR (-3)
$define Z_MEM_ERROR (-4)
$define Z_BUF_ERROR (-5)
$define Z_VERSION_ERROR (-6)
$define Z_NO_COMPRESSION 0
$define Z_BEST_SPEED 1
$define Z_BEST_COMPRESSION 9
$define Z_DEFAULT_COMPRESSION (-1)
$define Z_FILTERED 1
$define Z_HUFFMAN_ONLY 2
$define Z_RLE 3
$define Z_DEFAULT_STRATEGY 0
$define Z_BINARY 0
$define Z_ASCII 1
$define Z_UNKNOWN 2
$define Z_DEFLATED 8
$define Z_NULL 0


declare function zlibVersion Lib "zlibwapi.dll" alias "zlibVersion" () as string
declare function deflate Lib "zlibwapi.dll" alias "deflate" (strm as z_stream, byval flush as integer) as integer
declare function deflateEnd Lib "zlibwapi.dll" alias "deflateEnd" (strm as z_stream) as integer
declare function inflate Lib "zlibwapi.dll" alias "inflate" (strm as z_stream, byval flush as integer) as integer
declare function inflateEnd Lib "zlibwapi.dll" alias "inflateEnd" (strm as z_stream) as integer
declare function deflateSetDictionary Lib "zlibwapi.dll" alias "deflateSetDictionary" (strm as z_stream, byref dictionary as Byte, byval dictLength as Long) as integer
declare function deflateCopy Lib "zlibwapi.dll" alias "deflateCopy" (dest as z_stream, source as z_stream) as integer
declare function deflateReset Lib "zlibwapi.dll" alias "deflateReset" (strm as z_stream) as integer
declare function deflateParams Lib "zlibwapi.dll" alias "deflateParams" (strm as z_stream, byval level as integer, byval strategy as integer) as integer
declare function deflateBound Lib "zlibwapi.dll" alias "deflateBound" (strm as z_stream, byval sourceLen as long) as long
declare function deflatePrime Lib "zlibwapi.dll" alias "deflatePrime" (strm as z_stream, byval bits as integer, byval value as integer) as integer
declare function inflateSetDictionary Lib "zlibwapi.dll" alias "inflateSetDictionary" (strm as z_stream, byref dictionary as Byte, byval dictLength as Long) as integer
declare function inflateSync Lib "zlibwapi.dll" alias "inflateSync" (strm as z_stream) as integer
declare function inflateCopy Lib "zlibwapi.dll" alias "inflateCopy" (dest as z_stream, source as z_stream) as integer
declare function inflateReset Lib "zlibwapi.dll" alias "inflateReset" (strm as z_stream) as integer

'type in_func as function cdecl(byval as any ptr, byval as ubyte ptr ptr) as long
'type out_func as function cdecl(byval as any ptr, byval as ubyte ptr, byval as long) as integer

'declare function inflateBack Lib "zlibwapi.dll" alias "inflateBack" (strm as z_stream, byval in as in_func, byval in_desc as any ptr, byval out as out_func, byval out_desc as any ptr) as integer
declare function inflateBackEnd Lib "zlibwapi.dll" alias "inflateBackEnd" (strm as z_stream) as integer
declare function zlibCompileFlags Lib "zlibwapi.dll" alias "zlibCompileFlags" () as long
declare function compress Lib "zlibwapi.dll" alias "compress" (lpDestBuff as Long, byref destLen as long, lpSourceBuff as Long, byval sourceLen as long) as integer
declare function compress2 Lib "zlibwapi.dll" alias "compress2" (lpDestBuff as Long, byref destLen as long, lpSourceBuff as Long, byval sourceLen as long, byval level as integer) as integer
declare function compressBound Lib "zlibwapi.dll" alias "compressBound" (byval sourceLen as long) as long
declare function uncompress Lib "zlibwapi.dll" alias "uncompress" (lpDestBuff as Long, byref destLen as long, lpSourceBuff as Long, byval sourceLen as long) as integer

$define gzFile DWORD

declare function gzopen Lib "zlibwapi.dll" alias "gzopen" (path as string, mode as string) as gzFile
declare function gzdopen Lib "zlibwapi.dll" alias "gzdopen" (byval fd as integer, byval mode as string) as gzFile
declare function gzsetparams Lib "zlibwapi.dll" alias "gzsetparams" (byval file as gzFile, byval level as integer, byval strategy as integer) as integer
declare function gzread Lib "zlibwapi.dll" alias "gzread" (byval file as gzFile, byval buf as long, byval len as long) as integer
declare function gzwrite Lib "zlibwapi.dll" alias "gzwrite" (byval file as gzFile, byval buf as long, byval len as long) as integer
declare function gzprintf Lib "zlibwapi.dll" alias "gzprintf" (byval file as gzFile, byval format as string, ...) as integer
declare function gzputs Lib "zlibwapi.dll" alias "gzputs" (byval file as gzFile, byval s as string) as integer
declare function gzgets Lib "zlibwapi.dll" alias "gzgets" (byval file as gzFile, byval buf as string, byval len as integer) as string
declare function gzputc Lib "zlibwapi.dll" alias "gzputc" (byval file as gzFile, byval c as integer) as integer
declare function gzgetc Lib "zlibwapi.dll" alias "gzgetc" (byval file as gzFile) as integer
declare function gzungetc Lib "zlibwapi.dll" alias "gzungetc" (byval c as integer, byval file as gzFile) as integer
declare function gzflush Lib "zlibwapi.dll" alias "gzflush" (byval file as gzFile, byval flush as integer) as integer
declare function gzseek Lib "zlibwapi.dll" alias "gzseek" (byval file as gzFile, byval offset as integer, byval whence as integer) as integer
declare function gzrewind Lib "zlibwapi.dll" alias "gzrewind" (byval file as gzFile) as integer
declare function gztell Lib "zlibwapi.dll" alias "gztell" (byval file as gzFile) as integer
declare function gzeof Lib "zlibwapi.dll" alias "gzeof" (byval file as gzFile) as integer
declare function gzclose Lib "zlibwapi.dll" alias "gzclose" (byval file as gzFile) as integer
declare function gzerror Lib "zlibwapi.dll" alias "gzerror" (byval file as gzFile, byref lperrnum as long) as string
declare sub gzclearerr Lib "zlibwapi.dll" alias "gzclearerr" (byval file as gzFile)
declare function adler32 Lib "zlibwapi.dll" alias "adler32" (byval adler as long, byval lpBuf as long, byval len as long) as long
declare function crc32 Lib "zlibwapi.dll" alias "crc32" (byval crc as long, byval lpBuf as long, byval len as long) as long
declare function deflateInit Lib "zlibwapi.dll" alias "deflateInit_" (strm as z_stream, byval level as integer, byval version as string, byval stream_size as integer) as integer
declare function inflateInit Lib "zlibwapi.dll" alias "inflateInit_" (strm as z_stream, byval version as string, byval stream_size as integer) as integer
declare function deflateInit2 Lib "zlibwapi.dll" alias "deflateInit2_" (strm as z_stream, byval level as integer, byval method as integer, byval windowBits as integer, byval memLevel as integer, byval strategy as integer, byval version as string, byval stream_size as integer) as integer
declare function inflateInit2 Lib "zlibwapi.dll" alias "inflateInit2_" (strm as z_stream, byval windowBits as integer, byval version as string, byval stream_size as integer) as integer
declare function inflateBackInit Lib "zlibwapi.dll" alias "inflateBackInit_" (strm as z_stream, byval windowBits as integer, byref window as Byte, byval version as string, byval stream_size as integer) as integer

declare function zError Lib "zlibwapi.dll" alias "zError" (byval z as integer) as string
declare function inflateSyncPoint Lib "zlibwapi.dll" alias "inflateSyncPoint" (z as z_stream) as integer
declare function get_crc_table Lib "zlibwapi.dll" alias "get_crc_table" () as long

$endif
