$TYPECHECK ON
'=============================================================================
'                       QAVI.inc  include file and Component
'                       for the RapidQ compiler by William Yu.
'
'  Version 1.0 by JohnK (John Kelly)
'   Use "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED
'
'  Code contributions By Ray Mercer:  Wind 32 declarations & code snippets
'     heavily modified for  RapidQ
'=============================================================================


'BITMAP for BMP pointer
$IFNDEF __RQINC2         'RapidQ2.inc loaded?
    Type TBITMAP     '24 bytes
      bmType 		AS LONG
      bmWidth 		AS LONG
      bmHeight 		AS LONG
      bmWidthBytes	AS LONG
      bmPlanes 		As WORD
      bmBitsPixel 	As WORD
      bmBits 		AS LONG
    End Type

  DECLARE FUNCTION GetCurrentObject Lib "gdi32" Alias "GetCurrentObject" (hdc AS LONG,uObjectType AS LONG) AS LONG
  DECLARE FUNCTION GetObject Lib "gdi32" Alias "GetObjectA" (hObject AS LONG,nCount AS LONG, lpObject AS TBITMAP) AS LONG

  FUNCTIONI UDTPTR(...) AS LONG
  	RESULT = ParamVal(1)
  END FUNCTION

  $DEFINE pf8bit  3
  $DEFINE pf24bit 6
  $DEFINE pf32bit 7
$ENDIF          'rapidq2 inc



$IFNDEF __WIN32API         'Windows.inc loaded?

Type BITMAPINFOHEADER '40 bytes
    biSize 			AS LONG			'Size of this header
    biWidth 		AS LONG			'Width of image (pixels)
    biHeight 		AS LONG			'Height of image (pixels)
    biPlanes 		As WORD			'Number of color planes
    biBitCount 		As WORD			'Pixel bit depth (bits per pixel)
    biCompression 	AS LONG			'Compression type
    biSizeImage 	AS LONG			'Size of image (can be 0)
    biXPelsPerMeter AS LONG			'pixels per meter
    biYPelsPerMeter AS LONG			'dimensions
    biClrUsed 		AS LONG			'Number of colors (can be 0)
    biClrImportant	AS LONG			'minimum number Important colors (can be 0)
End Type

' DIB color table identifiers 
$DEFINE DIB_RGB_COLORS 0&       ' color table in RGBs 
$DEFINE DIB_PAL_COLORS 1&       ' color table in palette indices 

' constants for the biCompression field 
$DEFINE  BI_RGB     0&
$DEFINE  BI_RLE8    1&
$DEFINE  BI_RLE4    2&
$DEFINE  BI_bitfields 3&


Declare Function mmioStringToFOURCC Lib "winmm.dll" Alias "mmioStringToFOURCCA" (ByVal sz As String, ByVal uFlags AS LONG) AS LONG 'returns fourcc
'note* functions that return MMRESULT return 0 on success
'Declare Function mmioOpen Lib "winmm.dll" Alias "mmioOpenA" (ByVal szFileName As String, ByRef lpmmioinfo As Any, ByVal dwOpenFlags AS LONG) AS LONG   'returns hmmio
'Declare Function mmioDescend Lib "winmm.dll" ALIAS "(ByVal hmmio AS LONG, ByRef lpck As MMCKINFO, ByRef lpckParent As Any, ByVal wFlags AS LONG) AS LONG   'MMRESULT           );
'Declare Function mmioRead Lib "winmm.dll" ALIAS "(ByVal hmmio AS LONG, ByVal pBuf AS LONG, ByVal lenBuf AS LONG) AS LONG 'returns num bytes read
'Declare Function mmioClose Lib "winmm.dll" ALIAS "(ByVal hmmio AS LONG, ByVal wFlags AS LONG) AS LONG   ' MMRESULT

'open file flags for AVIFileOpen
$DEFINE OF_READ             &H0
$DEFINE OF_WRITE            &H1
$DEFINE OF_READWRITE        &H00000002
$DEFINE OF_SHARE_COMPAT     &H00000000
$DEFINE OF_SHARE_EXCLUSIVE  &H00000010
$DEFINE OF_SHARE_DENY_WRITE &H20
$DEFINE OF_SHARE_DENY_READ  &H00000030
$DEFINE OF_SHARE_DENY_NONE  &H00000040
$DEFINE OF_PARSE            &H00000100
$DEFINE OF_DELETE           &H00000200
$DEFINE OF_VERIFY           &H00000400
$DEFINE OF_CANCEL           &H00000800
$DEFINE OF_CREATE           &H1000
$DEFINE OF_PROMPT           &H00002000
$DEFINE OF_EXIST            &H00004000
$DEFINE OF_REOPEN           &H00008000


$ENDIF          'windows inc



' *************************************************************************
' *
' *  AVIFile* Types (UDTS converted from C structs)
' *
' **************************************************************************

Type AVI_STREAM_INFO            'can't use original names...
    fccType         AS LONG
    fccHandler      AS LONG
    dwFlags         AS LONG
    dwCaps          AS LONG
    wPriority       As WORD
    wLanguage       As WORD
    dwScale         AS LONG
    dwRate          AS LONG
    dwStart         AS LONG
    dwLength        AS LONG
    dwInitialFrames AS LONG
    dwSuggestedBufferSize AS LONG
    dwQuality       AS LONG
    dwSampleSize    AS LONG
    Left            AS LONG
    Top             AS LONG
    Right           AS LONG
    Bottom          AS LONG
    dwEditCount     AS LONG
    dwFormatChangeCount AS LONG
    szName          As String * 64
End Type

'for use with AVIFIleInfo
Type AVI_FILE_INFO          '108 bytes?
    dwMaxBytesPerSecond     AS LONG
    dwFlags                 AS LONG
    dwCaps                  AS LONG
    dwStreams               AS LONG
    dwSuggestedBufferSize   AS LONG
    dwWidth                 AS LONG
    dwHeight                AS LONG
    dwScale                 AS LONG
    dwRate                  AS LONG
    dwLength                AS LONG
    dwEditCount             AS LONG
    szFileType              As String * 64
End Type


Type AVI_COMPRESS_OPTIONS
    fccType AS LONG            ' stream type, for consistency 
    fccHandler AS LONG         ' compressor 
    dwKeyFrameEvery AS LONG    ' keyframe rate 
    dwQuality AS LONG          ' compress quality 0-10,000 
    dwBytesPerSecond AS LONG   ' bytes per second 
    dwFlags AS LONG            ' flags... see below 
    lpFormat AS LONG           ' save format 
    cbFormat AS LONG
    lpParms AS LONG            ' compressor options 
    cbParms AS LONG
    dwInterleaveEvery AS LONG  ' for non-video streams only 
End Type

Declare Function VideoForWindowsVersion Lib "msvfw32.dll" ALIAS "VideoForWindowsVersion"() AS LONG
Declare Sub AVIFileInit Lib "avifil32.dll" ALIAS "AVIFileInit"()
'note! - the ppfile argument is ByRef because it is a pointer to a pointer :-)
Declare Function AVIFileOpen Lib "avifil32.dll" ALIAS "AVIFileOpen"(ByRef ppfile AS LONG, ByVal szFile As String, ByVal uMode AS LONG, ByVal pclsidHandler AS LONG) AS LONG  'HRESULT
Declare Function AVIFileInfo Lib "avifil32.dll" ALIAS "AVIFileInfo"(ByVal pfile AS LONG, pfi As AVI_FILE_INFO, ByVal lSize AS LONG) AS LONG 'HRESULT
Declare Function AVIFileCreateStream Lib "avifil32.dll" Alias "AVIFileCreateStreamA" (ByVal pfile AS LONG, Byref ppavi AS LONG, ByRef psi As AVI_STREAM_INFO) AS LONG

' must pass a pointer to the AVI_COMPRESS_OPTIONS UDT (last parameter) ByRef
' use the internal function longVar = UDTPTR(UDT) then pass LongVar ByRef
' this will give you a pointer to a pointer to an (array of) UDT
Declare Function AVISaveOptions Lib "avifil32.dll" ALIAS "AVISaveOptions"(ByVal hWnd AS LONG, _
                                                        ByVal uiFlags AS LONG, _
                                                        ByVal nStreams AS LONG, _
                                                        ByRef ppavi AS LONG, _
                                                        ByRef ppOptions AS LONG) AS LONG 'TRUE if user pressed OK, False if cancel, or error if error
'This is actually the AVISaveV function aliased to be called as AVISave from VB because
'AVISave seems to be compiled using CDECL calling convention ;-(
'ALSO - see note above AVISaveOptions declare - this function also requires a pointer to a pointer to (an array of) UDT
Declare Function AVISave Lib "avifil32.dll" Alias "AVISaveVA" (ByVal szFile As String, _
                                                                        ByVal pclsidHandler AS LONG, _
                                                                        ByVal lpfnCallback AS LONG, _
                                                                        ByVal nStreams AS LONG, _
                                                                        ByRef ppaviStream AS LONG, _
                                                                        ByRef ppCompOptions AS LONG) AS LONG
'See note above AVISaveOptions declare - this function also requires a pointer to a pointer to (an array of) UDT
Declare Function AVISaveOptionsFree Lib "avifil32.dll" ALIAS "AVISaveOptionsFree"(ByVal nStreams AS LONG, _
                                                        ByRef ppOptions AS LONG) AS LONG

Declare Function AVIMakeCompressedStream Lib "avifil32.dll" ALIAS "AVIMakeCompressedStream"(ByRef ppsCompressed AS LONG, _
                                                                ByVal psSource AS LONG, _
                                                                ByRef lpOptions As AVI_COMPRESS_OPTIONS, _
                                                                ByVal pclsidHandler AS LONG) AS LONG '

Declare Function AVIStreamSetFormat Lib "avifil32.dll" ALIAS "AVIStreamSetFormat"(ByVal pavi AS LONG, _
                                                                ByVal lPos AS LONG, _
                                                                lpFormat As BITMAPINFOHEADER, _ 'LONG, _
                                                                ByVal cbFormat AS LONG) AS LONG

Declare Function AVIStreamWrite Lib "avifil32.dll" ALIAS "AVIStreamWrite"(ByVal pavi AS LONG, _
                                                        ByVal lStart AS LONG, _
                                                        ByVal lSamples AS LONG, _
                                                        ByVal lpBuffer AS LONG, _
                                                        ByVal cbBuffer AS LONG, _
                                                        ByVal dwFlags AS LONG, _
                                                        ByVal plSampWritten AS LONG, _
                                                        ByVal plBytesWritten AS LONG) AS LONG
Declare Function AVIStreamReadFormat Lib "avifil32.dll" ALIAS "AVIStreamReadFormat"(ByVal pAVIStream AS LONG, _
                                                                ByVal lPos AS LONG, _
                                                                ByVal lpFormatBuf AS LONG, _
                                                                ByRef sizeBuf AS LONG) AS LONG

Declare Function AVIStreamRead Lib "avifil32.dll" ALIAS "AVIStreamRead"(ByVal pAVIStream AS LONG, _
                                                            ByVal lStart AS LONG, _
                                                            ByVal lSamples AS LONG, _
                                                            ByVal lpBuffer AS LONG, _
                                                            ByVal cbBuffer AS LONG, _
                                                            ByRef pBytesWritten AS LONG, _
                                                            ByRef pSamplesWritten AS LONG) AS LONG
Declare Function AVIStreamGetFrameOpen Lib "avifil32.dll" ALIAS "AVIStreamGetFrameOpen"(ByVal pAVIStream AS LONG, ByVAL lpbih AS LONG) AS LONG 'BITMAPINFOHEADER) AS LONG 'returns pointer to GETFRAME object on success (or NULL on error)
Declare Function AVIStreamGetFrame Lib "avifil32.dll" ALIAS "AVIStreamGetFrame"(ByVal pGetFrameObj AS LONG, _
                                                                ByVal lPos AS LONG) AS LONG 'returns pointer to packed DIB on success (or NULL on error)
Declare Function AVIStreamGetFrameClose Lib "avifil32.dll" ALIAS "AVIStreamGetFrameClose"(ByVal pGetFrameObj AS LONG) AS LONG ' returns zero on success (error number) after calling this function the GETFRAME object pointer is invalid

                                                            
Declare Function AVIFileGetStream Lib "avifil32.dll" ALIAS "AVIFileGetStream"(ByVal pfile AS LONG, ByRef ppaviStream AS LONG, ByVal fccType AS LONG, ByVal lParam AS LONG) AS LONG
Declare Function AVIMakeFileFromStreams Lib "avifil32.dll" ALIAS "AVIMakeFileFromStreams"(ByRef ppfile AS LONG, ByVal nStreams AS LONG, ByVal pAVIStreamArray AS LONG) AS LONG

Declare Function AVIStreamInfo Lib "avifil32.dll" ALIAS "AVIStreamInfo"(ByVal pAVIStream AS LONG, ByRef psi As AVI_STREAM_INFO, ByVal lSize AS LONG) AS LONG
Declare Function AVIStreamStart Lib "avifil32.dll" ALIAS "AVIStreamStart"(ByVal pavi AS LONG) AS LONG
Declare Function AVIStreamLength Lib "avifil32.dll" ALIAS "AVIStreamLength"(ByVal pavi AS LONG) AS LONG
Declare Function AVIStreamRelease Lib "avifil32.dll" ALIAS "AVIStreamRelease"(ByVal pavi AS LONG) AS LONG 'ULONG
Declare Function AVIStreamClose Lib "avifil32.dll" ALIAS "AVIStreamRelease" (ByVal pavi AS LONG) AS LONG 'ULONG
Declare Function AVIFileRelease Lib "avifil32.dll" ALIAS "AVIFileRelease"(ByVal pfile AS LONG) AS LONG
Declare Function AVIFileClose Lib "avifil32.dll" Alias "AVIFileRelease" (ByVal pfile AS LONG) AS LONG
Declare Sub AVIFileExit Lib "avifil32.dll" ALIAS "AVIFileExit"()

'***************************************************************************
' *
' *  Clipboard routines
' *
' **************************************************************************
Declare Function AVIMakeStreamFromClipboard Lib "avifil32.dll" ALIAS "AVIMakeStreamFromClipboard"(ByVal cfFormat AS LONG, ByVal hGlobal AS LONG, ByRef ppstream AS LONG) AS LONG
Declare Function AVIPutFileOnClipboard Lib "avifil32.dll" ALIAS "AVIPutFileOnClipboard"(ByVal pAVIFile AS LONG) AS LONG
Declare Function AVIGetFromClipboard Lib "avifil32.dll" ALIAS "AVIGetFromClipboard"(ByRef ppAVIFile AS LONG) AS LONG
Declare Function AVIClearClipboard Lib "avifil32.dll" ALIAS "AVIClearClipboard"() AS LONG

' *************************************************************************
' *
' *  AVIFile* Constants (converted from C defines)
' *
' **************************************************************************
'FROM WINERROR.H
' Const SEVERITY_ERROR    AS LONG = &H80000000
' Const FACILITY_ITF      AS LONG = &H40000
' Const AVIERR_BASE       AS LONG = &H4000
'MAKE_SCODE(SEVERITY_ERROR, FACILITY_ITF, 0x4000 + error)
'#define MAKE_AVIERR(error)  MAKE_SCODE(sev,fac,code) \ ((SCODE) (((unsigned long)(sev)<<31) | ((unsigned long)(fac)<<16) | ((unsigned long)(code))) )


$define AVIERR_UNSUPPORTED      &H80044065  'MAKE_AVIERR(101)
$define AVIERR_BADFORMAT        &H80044066
$define AVIERR_MEMORY           &H80044067
$define AVIERR_INTERNAL         &H80044068
$define AVIERR_BADFLAGS         &H80044069
$define AVIERR_BADPARAM         &H8004406A
$define AVIERR_BADSIZE          &H8004406B
$define AVIERR_BADHANDLE        &H8004406C  'MAKE_AVIERR(108)
$define AVIERR_FILEREAD         &H8004406D  'MAKE_AVIERR(109)
$define AVIERR_FILEWRITE        &H8004406E  'MAKE_AVIERR(110)
$define AVIERR_FILEOPEN         &H8004406F  'MAKE_AVIERR(111)
$define AVIERR_COMPRESSOR       &H80044070  'MAKE_AVIERR(112)
$define AVIERR_NOCOMPRESSOR     &H80044071  'MAKE_AVIERR(113)
$define AVIERR_READONLY         &H80044072  'MAKE_AVIERR(114)
$define AVIERR_NODATA           &H80044073  'MAKE_AVIERR(115)
$define AVIERR_BUFFERTOOSMALL   &H80044074  'MAKE_AVIERR(116)
$define AVIERR_CANTCOMPRESS     &H80044075  'MAKE_AVIERR(117)
CONST AVIERR_USERABORT      =  -2147204922
$DEFINE AVIERR_OK               0&
$DEFINE AVIERR_NoDecompressor   &H2

' Flags for dwFlags
$DEFINE AVIFILEINFO_HASINDEX         &H10
$DEFINE AVIFILEINFO_MUSTUSEINDEX     &H20
$DEFINE AVIFILEINFO_ISINTERLEAVED    &H100
$DEFINE AVIFILEINFO_WASCAPTUREFILE   &H10000
$DEFINE AVIFILEINFO_COPYRIGHTED      &H20000

' Flags for dwCaps
$DEFINE AVIFILECAPS_CANREAD          &H1
$DEFINE AVIFILECAPS_CANWRITE         &H2
$DEFINE AVIFILECAPS_ALLKEYFRAMES     &H10
$DEFINE AVIFILECAPS_NOCOMPRESSION    &H20

'
' Defines for the dwFlags field of the AVICOMPRESSOPTIONS struct
' Each of these flags determines if the appropriate field in the structure
' (dwInterleaveEvery, dwBytesPerSecond, and dwKeyFrameEvery) is payed
' attention to.  See the autodoc in avisave.c for details.
'
$DEFINE AVICOMPRESSF_INTERLEAVE  &H1           ' interleave
$DEFINE AVICOMPRESSF_DATARATE    &H2           ' use a data rate
$DEFINE AVICOMPRESSF_KEYFRAMES   &H4           ' use keyframes
$DEFINE AVICOMPRESSF_VALID       &H8           ' has valid data?

$DEFINE AVIIF_KEYFRAME      &H10

'Stream types for use in VB (translated from C macros)
Const streamtypeVIDEO       AS LONG = 1935960438 'equivalent to: mmioStringToFOURCC("vids", 0&)
Const streamtypeAUDIO       AS LONG = 1935963489 'equivalent to: mmioStringToFOURCC("auds", 0&)
Const streamtypeMIDI        AS LONG = 1935960429 'equivalent to: mmioStringToFOURCC("mids", 0&)
Const streamtypeTEXT        AS LONG = 1937012852 'equivalent to: mmioStringToFOURCC("txts", 0&)

' For GetFrame::SetFormat - use the best format for the display
$DEFINE AVIGETFRAMEF_BESTDISPLAYFMT  1

' defines for uiFlags for dialog box (AVISaveOptions)
$DEFINE ICMF_CHOOSE_KEYFRAME           &H1     ' show KeyFrame Every box
$DEFINE ICMF_CHOOSE_DATARATE           &H2     ' show DataRate box
$DEFINE ICMF_CHOOSE_PREVIEW            &H4     ' allow expanded preview dialog
$DEFINE ICMF_CHOOSE_ALLCOMPRESSORS     &H8     ' don't only show those that
                                                              ' can handle the input format
                                                              ' or input data


    '===========================================
    '  Read / write  AVI files in RapidQ
    '===========================================

Type QAVI EXTENDS Qobject
  '================================
  ' Properties
  '================================
PRIVATE:
    Retrn           AS LONG
    pAVIFile        AS LONG           'pointer to AVI File (PAVIFILE handle)
    pAVIStream      AS LONG           'pointer to AVI stream interface (PAVISTREAM handle)
    pAVICompress    AS LONG           'pointer to compression handle
    FileInfo        As AVI_FILE_INFO  'file info struct
    StreamInfo      As AVI_STREAM_INFO 'stream struct
    SampleWritten   AS LONG             'returns 1 if sample (frame) was written

PUBLIC:
    NumFrames       AS LONG           'number of frames /counter in video stream
    FirstFrame      AS LONG           'position of the first video frame
    Error           AS STRING         'did you say problems?
    ShowError       AS INTEGER        'Flag to show messages automatically
    Width           AS LONG
    Height          AS LONG
    Left            AS LONG
    Right           AS LONG
    Top             AS LONG
    Bottom          AS LONG
    FPS             AS LONG
    FileType        AS STRING           'string showing AVI file type header
    Quality         AS LONG             'compression quality 0 - 100000, with 10000 = best
    bpp             AS LONG             'bits per pixel, either 8 or 24
    SampleSize      AS LONG             'Frame size in bytes
    FramesWritten   AS LONG             'when creating keep track, let user know total output
    BytesWritten    AS LONG             'amount of memory written in each frame (= bitmap size if completed)
    ShowDialog      AS INTEGER          'show windows compression, options dialog box
    UseCompression  AS INTEGER          'get a compression stream


    '======================================================
    '  Error handling to shut down library & release memory
    '======================================================

PRIVATE:
FUNCTION CheckAVIError () AS LONG           'error handler, close file streams if there is an error
  RESULT = 0
  IF QAVI.Retrn  <> AVIERR_OK THEN 
    RESULT = 1
    If (QAVI.pAVIStream <> 0) Then AVIStreamRelease(QAVI.pAVIStream)
    If (QAVI.pAVICompress <> 0) Then AVIStreamRelease(QAVI.pAVICompress)
    If (QAVI.pAVIfile <> 0) Then AVIFileClose(QAVI.pAVIfile)
    AVIFileExit
    SELECT CASE QAVI.Retrn
        CASE  AVIERR_UNSUPPORTED
            QAVI.Error ="unsupported"
        CASE  AVIERR_BADFORMAT
            QAVI.Error ="bad format"
        CASE  AVIERR_BADFLAGS
            QAVI.Error ="bad flags"
        CASE  AVIERR_BADPARAM
            QAVI.Error ="bad parameters"
        CASE  AVIERR_MEMORY
            QAVI.Error ="out of memory"
        CASE  AVIERR_INTERNAL
            QAVI.Error ="internal error'
        CASE  AVIERR_BADSIZE
            QAVI.Error ="bad size"
        CASE  AVIERR_BADHANDLE
            QAVI.Error ="bad handle"
        CASE  AVIERR_FILEREAD, AVIERR_FILEWRITE, AVIERR_FILEOPEN, AVIERR_READONLY, AVIERR_NODATA 
            QAVI.Error ="file read/write error or no data"
        CASE  AVIERR_COMPRESSOR, AVIERR_NOCOMPRESSOR, AVIERR_CANTCOMPRESS
            QAVI.Error ="bad compression or codec"
        CASE  AVIERR_BUFFERTOOSMALL
            QAVI.Error ="buffer too small"
        CASE  AVIERR_USERABORT
            QAVI.Error ="user aborted"
        CASE  AVIERR_NoDecompressor
            QAVI.Error ="No suitable decompressor found for this video stream"
        END SELECT
    QAVI.Error = "AVI Function: " + QAVI.Error
    IF QAVI.ShowError THEN SHOWMESSAGE QAVI.Error
  END IF
END SUB


    '====================================================================
    '  Get pointer to the bitmap data
    '====================================================================

FUNCTION BMPpointer(TheBitmap AS QBITMAP) AS LONG
    DIM hBM		        AS LONG
    DIM hObj	        AS LONG
    DIM Binfo           AS TBITMAP

    RESULT = 0
    IF TheBitmap.Width > 0 AND TheBitmap.Height > 0 THEN       'forget null bitmap
        'handle to bitmap in Device context, 7 =OBJ_BITMAP
        hBM = GetCurrentObject(TheBitmap.Handle, 7):    IF hBM = 0 THEN EXIT FUNCTION
        hObj = GetObject(hBM, SIZEOF(BInfo), BInfo): IF hObj = 0 THEN EXIT FUNCTION
        RESULT = BInfo.bmBits
    END IF
END FUNCTION



PUBLIC:

    '====================================================================
    '  Close File, release memory and COM interface, close library
    '====================================================================

FUNCTION CloseAVIFile() AS LONG
    WITH QAVI
        IF .pAVIStream THEN AVIStreamRelease (.pAVIStream)
        IF .pAVICompress THEN AVIStreamRelease (.pAVICompress)
        If .pAVIfile  THEN AVIFileClose(.pAVIfile)
        AVIFileExit   ' releases AVIFile library
        .pAVIStream = 0
        .pAVICompress = 0
        .pAVIfile = 0
    END WITH
    RESULT = 1
END FUNCTION



    '======================================================
    '  Create File, open library, set options, & allocate memory
    '======================================================

FUNCTION CreateAVIFile(szFile As STRING, TheWidth AS INTEGER, TheHeight AS INTEGER, Bpp AS INTEGER, fps AS INTEGER) AS LONG
    Dim opts        As AVI_COMPRESS_OPTIONS
    Dim pOpts       AS LONG
    Dim BI          As BITMAPINFOHEADER
    DIM DialogForm  AS QFORM

    MEMSET(opts, 0, SizeOf(opts))       'clear mem
    MEMSET(BI, 0, SizeOf(BI))
    QAVI.FramesWritten = 0
    RESULT = 0                          'failed = 0

    AVIFileInit                         ' opens AVIFile library
    '   Open the file for writing
     QAVI.Retrn = AVIFileOpen(QAVI.pAVIFile, szFile, OF_WRITE Or OF_CREATE, 0&)
         IF QAVI.CheckAVIError THEN EXIT FUNCTION

    If QAVI.fps > 60 Then QAVI.fps = 60   'do some error checking
    '   Fill in the header for the video stream
    With QAVI.StreamInfo
        .fccType = streamtypeVIDEO  'mmioStringToFOURCC("vids", 0&)               ' stream type video
        .fccHandler =  mmioStringToFOURCC("DIB ", 0&)           '"DIB " Device independent bitmap 0&= default AVI handler
        .dwScale = 1
        .dwRate = fps                                           ' fps
        .dwStart = 0
        .dwQuality = QAVI.Quality                              'compression quality 0 - 10000
        .dwLength =  QAVI.numFrames                            'number of frames, can be 0
        .dwSampleSize = TheWidth * TheHeight * bpp/8            'can be non-zero for fixed size frames
        .dwSuggestedBufferSize = TheWidth * TheHeight * bpp/8   ' size of one frame pixels
        ' rectangle for stream
        IF QAVI.Top THEN .Top = QAVI.Top ELSE .Top = 0&  
        IF QAVI.Left THEN .Left = QAVI.Left ELSE .Left = 0&  
        IF QAVI.Right THEN .Right = QAVI.Right ELSE .Right = TheWidth 
        IF QAVI.Bottom THEN .Bottom = QAVI.Bottom ELSE .Bottom = TheHeight  
    End With


'      create the stream
    QAVI.Retrn = AVIFileCreateStream(QAVI.pAVIfile, QAVI.pAVIStream, QAVI.StreamInfo)
        IF QAVI.CheckAVIError THEN EXIT FUNCTION
'  ------   if you create a stream you must set pixel format for AVI stream    ------------------
     With BI
         .biBitCount = Bpp
         .biClrImportant = 0&
         .biClrUsed = 0&
        IF bpp = 8 THEN
         .biCompression = BI_RLE8       '8 bit RLE
        ELSE
         .biCompression = BI_RGB        'no compression
        END IF
         .biHeight = TheHeight
         .biWidth = TheWidth
         .biPlanes = 1
         .biSize = SIZEOF(BI)
         .biSizeImage = (TheHeight * TheWidth * bpp\8 ) 'can be set to 0 for BI_RGB compression
         .biXPelsPerMeter = 0&
         .biYPelsPerMeter = 0&
     End With
    
    'set the format of the compressed stream
    QAVI.Retrn = AVIStreamSetFormat(QAVI.pAVIStream, 0&, BI, SIZEOF(BI))
        IF QAVI.CheckAVIError THEN EXIT FUNCTION
    ' ----------------------------------------------


'   ------------------------------------------------------------------------------------
    'user sets compression options, this part is tricky, work in progress
'   --------------------------------------------------------------------------------------
    IF QAVI.UseCompression THEN
         WITH Opts
             .fccType =  mmioStringToFOURCC("vids", 0&)
             .fccHandler = mmioStringToFOURCC("RLE ", 0&) '0&      ' compressor run length encoded
             .dwKeyFrameEvery = 0&              'used only if the AVICOMPRESSF_KEYFRAMES flag set
             .dwQuality = QAVI.Quality          'compress quality 0-10,000 
             .dwBytesPerSecond = 0&             'used only if the AVICOMPRESSF_DATARATE flag is set
             .dwFlags = AVICOMPRESSF_VALID      'see docs
             .lpFormat = 0&                     'Pointer to a structure defining the data format. For an audio stream, this is an LPWAVEFORMAT 
             .cbFormat=0&                       'Size, in bytes, of the data referenced by lpFormat
             .lpParms =0&                       'internal compressor options 
             .cbParms=0&
             .dwInterleaveEvery=0&              'only if the AVICOMPRESSF_INTERLEAVE flag is set.
         END WITH
    '     'make compressed stream
        QAVI.Retrn = AVIMakeCompressedStream(QAVI.pAVICompress, QAVI.pAVIStream, Opts, 0&)
            IF QAVI.CheckAVIError THEN EXIT FUNCTION
        IF QAVI.pAVICompress THEN QAVI.UseCompression = 1       'crashes
    END IF



'   ------------------------------------------------------------------------------------
    'get compression options from the user dialog, API requires a pointer to a UDT pointer
'   --------------------------------------------------------------------------------------

    IF QAVI.ShowDialog THEN 
         pOpts = UDTPTR(opts)
         IF  AVISaveOptions(DialogForm.Handle, _
                            ICMF_CHOOSE_KEYFRAME Or ICMF_CHOOSE_DATARATE Or ICMF_CHOOSE_ALLCOMPRESSORS, _
                            1, _
                            QAVI.pAVIStream, _
                            pOpts) <> 1 Then  'returns TRUE if User presses OK, FALSE if Cancel, or error code
            AVISaveOptionsFree(1, pOpts)
            QAVI.Retrn = AVIERR_USERABORT
            QAVI.CheckAVIError
        END IF
        IF (Opts.fccHandler <>  mmioStringToFOURCC("DIB ", 0&)) THEN
            QAVI.UseCompression = 1
            QAVI.Retrn = AVIMakeCompressedStream(QAVI.pAVICompress, QAVI.pAVIStream, Opts, 0&)
        END IF
        AVISaveOptionsFree(1, pOpts)
        QAVI.Retrn = AVIStreamSetFormat(QAVI.pAVIStream, 0&, BI, SIZEOF(BI))
            IF QAVI.CheckAVIError THEN EXIT FUNCTION
    END IF      'show dialog

    QAVI.Width = TheWidth           'worked, now save them
    QAVI.Height = TheHeight
    QAVI.bpp = bpp
    RESULT = 1
END SUB



    '======================================================
    '  Get info from AVI File, set QAVI properties
    '======================================================


FUNCTION GetAVIFileInfo(szFile As STRING) AS LONG

    RESULT = 0                              'failed = 0
    AVIFileInit                             ' opens AVIFile library
    WITH QAVI
    .Retrn = AVIFileOpen(.pAVIFile, szFile, OF_SHARE_DENY_WRITE, 0&)
        IF .CheckAVIError THEN EXIT FUNCTION
    'Get the first available video stream (PAVISTREAM)
    .Retrn = AVIFileGetStream(.pAVIFile, .pAVIStream, streamtypeVIDEO, 0&)
        IF .CheckAVIError THEN EXIT FUNCTION
    'get the starting position of the stream (some streams may not start simultaneously)
    .firstFrame = AVIStreamStart(.pAVIStream)     'this function returns -1 on error
        IF .firstFrame = -1 Then .Retrn = AVIERR_BADPARAM: .CheckAVIError :  EXIT FUNCTION
    'get the length of video stream in frames
    .NumFrames = AVIStreamLength(.pAVIStream)              ' this function returns -1 on error
         If .NumFrames = -1 Then .Retrn = AVIERR_BADPARAM: .CheckAVIError :  EXIT FUNCTION
     'get file info struct 
    .Retrn = AVIFileInfo(.pAVIFile, .FileInfo, SizeOf(QAVI.FileInfo))
        IF .CheckAVIError THEN EXIT FUNCTION
     'get stream info struct
    .Retrn = AVIStreamInfo(.pAVIStream, .StreamInfo, SizeOf(QAVI.streamInfo))
        IF .CheckAVIError THEN EXIT FUNCTION
        .Width = .FileInfo.dwWidth
        .Height = .FileInfo.dwHeight
        .FileType = .FileInfo.szFileType
        .FPS = .StreamInfo.dwRate\.StreamInfo.dwScale
        .Quality = .StreamInfo.dwQuality
        .Left = .StreamInfo.Left
        .Top = .StreamInfo.Top
        .Right = .StreamInfo.Right
        .Bottom = .StreamInfo.Bottom
        .SampleSize = .StreamInfo.dwSampleSize
    END WITH
    RESULT = 1
' With FileInfo  .dwMaxBytesPerSecond, .dwFlags, .dwCaps, .dwStreams, .dwSuggestedBufferSize, .dwWidth
'    dwHeight, .dwScale , .dwRate , .dwLength, .dwEditCount
' With StreamInfo   .fccType,  .fccHandler, .dwFlags, .dwCaps, .wPriority, .wLanguage, .dwScale, .dwRate, .dwStart
'     .dwLength, .dwInitialFrames, .dwSuggestedBufferSize, .dwQuality, .dwSampleSize    )
 END SUB




    '======================================================
    '  Get frame from AVI file store in BMP
    '======================================================

FUNCTION AVItoBMP(szFile AS STRING, TheBMP AS QBITMAP, FrameNum AS INTEGER) AS LONG
    Dim pGetFrameObj As Long            'pointer to GetFrame interface
    Dim pDIB         As Long             'pointer to packed DIB in memory
    Dim bih          As BITMAPINFOHEADER 'infoheader to pass to GetFrame functions
    DIM BMPPointer   AS LONG
    Dim i            As Long


    RESULT = 0                      'failed = 0
    WITH QAVI
    IF .pAVIFile = 0 THEN 
        .GetAVIFileInfo(szFile)     'opens AVIFile library, gets all the info
    ELSE
        .Retrn = AVIFileOpen(.pAVIFile, szFile, OF_SHARE_DENY_WRITE, 0&)
            IF .CheckAVIError THEN EXIT FUNCTION
        'Get the first available video stream (PAVISTREAM)
        .Retrn = AVIFileGetStream(.pAVIFile, .pAVIStream, streamtypeVIDEO, 0&)
            IF .CheckAVIError THEN EXIT FUNCTION
        'get the starting position of the stream (some streams may not start simultaneously)
        .firstFrame = AVIStreamStart(.pAVIStream)     'this function returns -1 on error
            IF .firstFrame = -1 Then .Retrn = AVIERR_BADPARAM: .CheckAVIError :  EXIT FUNCTION
        'get the length of video stream in frames
        .NumFrames = AVIStreamLength(.pAVIStream)              ' this function returns -1 on error
             If .NumFrames = -1 Then .Retrn = AVIERR_BADPARAM: .CheckAVIError :  EXIT FUNCTION
         'get file info struct 
        .Retrn = AVIFileInfo(.pAVIFile, .FileInfo, SizeOf(QAVI.FileInfo))
            IF .CheckAVIError THEN EXIT FUNCTION
         'get stream info struct
        .Retrn = AVIStreamInfo(.pAVIStream, .StreamInfo, SizeOf(QAVI.streamInfo))
            IF .CheckAVIError THEN EXIT FUNCTION
        IF .CheckAVIError THEN EXIT FUNCTION
        .Width = .FileInfo.dwWidth
        .Height = .FileInfo.dwHeight
'        .FileType = .FileInfo.szFileType
'        .FPS = .StreamInfo.dwRate\.StreamInfo.dwScale
'        .Quality = .StreamInfo.dwQuality
'        .Left = .StreamInfo.Left
'        .Top = .StreamInfo.Top
'        .Right = .StreamInfo.Right
'        .Bottom = .StreamInfo.Bottom
'        .SampleSize = .StreamInfo.dwSampleSize
    END IF

    IF (QAVI.StreamInfo.fccHandler =  mmioStringToFOURCC("DIB ", 0&))  THEN    'set attributes to 24 bit 
        bih.biBitCount = 24
        QAVI.Bpp = 24
        bih.biClrImportant = 0
        bih.biClrUsed = 0
        bih.biCompression = BI_RGB
        bih.biHeight = QAVI.StreamInfo.Bottom - QAVI.StreamInfo.Top
        bih.biPlanes = 1
        bih.biSize = SIZEOF(bih)'40
        bih.biWidth = QAVI.StreamInfo.Right - QAVI.StreamInfo.Left
        bih.biXPelsPerMeter = 0
        bih.biYPelsPerMeter = 0
'        bih.biSizeImage = (QAVI.Width * QAVI.Height * 3) 'calculate total size of RGBQUAD scanlines (DWORD aligned)
        bih.biSizeImage = (((bih.biWidth * 3) + 3) And &HFFFC) * bih.biHeight 'calculate total size of RGBQUAD scanlines (DWORD aligned)
        TheBMP.PixelFormat = pf24bit
        'init AVISTreamGetFrame* functions and create GETFRAME object, tell AVIStream API what format we expect and input stream
        pGetFrameObj = AVIStreamGetFrameOpen(.pAVIStream, 0&)'UDTPTR(bih)) 'force function to return 24bit DIBS
    ELSE
        QAVI.Bpp = 8
        TheBMP.PixelFormat = pf8bit
        pGetFrameObj = AVIStreamGetFrameOpen(.pAVIStream, AVIGETFRAMEF_BESTDISPLAYFMT) 'Let API pick the best format
    END IF
    If pGetFrameObj = 0 Then .Retrn = AVIERR_NoDecompressor: .CheckAVIError:  EXIT FUNCTION

    IF (FrameNum <= .NumFrames) AND (FrameNum >= 0) THEN        'FOR i = .FirstFrame TO (.NumFrames - 1) + .FirstFrame  :next i
        pDIB = AVIStreamGetFrame(pGetFrameObj, FrameNum)
        DIM Binfo           AS TBITMAP
        DIM hBM AS INTEGER, hObj AS INTEGER
        TheBMP.Width = .Width
        TheBMP.Height = .Height
        'handle to bitmap in Device context, 7 =OBJ_BITMAP
        hBM = GetCurrentObject(TheBMP.Handle, 7):    IF hBM = 0 THEN EXIT FUNCTION
        hObj = GetObject(hBM, SIZEOF(BInfo), BInfo): IF hObj = 0 THEN EXIT FUNCTION
        BMPPointer = BInfo.bmBits

        IF .Bpp = 24 THEN
            pDIB = pDIB + SIZEOF(bih)  'returns pointer to BITMAPINFOHEADER and packed DIB
        ELSE
            pDIB = pDIB + 1024 + SIZEOF(bih)   'returns pointer to BITMAPINFOHEADER and packed DIB
        END IF
        MEMCPY(BMPPointer, pDIB, (.Height * .Width * .Bpp/8))
    ELSE

        .Retrn = AVIERR_BADPARAM
        .CheckAVIError
    END IF

    END WITH
    RESULT = 1
END SUB    


    '======================================================
    '  Sequential store of Bitmap to AVI file 8 and 24 bit/pixel only
    '======================================================

FUNCTION BMPtoAVIFile(TheBmp As QBITMAP) AS LONG        'may need to pass QForm.Handle
    DIM BMPPointer      AS LONG
    DEFLNG cbBuffer = QAVI.Width * QAVI.Height * (QAVI.Bpp\8)

    RESULT = 0
    WITH QAVI
    BMPPointer = .BMPpointer(TheBMP)

'   Now write out each video frame
    IF .pAVICompress THEN
        .Retrn = AVIStreamWrite(.pAVICompress, _
                          .FramesWritten, 1, _
                          BMPPointer, cbBuffer, _
                          AVIIF_KEYFRAME, @QAVI.SampleWritten, @QAVI.BytesWritten)
        IF .CheckAVIError THEN EXIT FUNCTION
    ELSE
        .Retrn = AVIStreamWrite(.pAVIStream, _ 
                          .FramesWritten, 1, _
                          BMPPointer, cbBuffer, _ 
                          AVIIF_KEYFRAME, @QAVI.SampleWritten, @QAVI.BytesWritten)
        IF .CheckAVIError THEN EXIT FUNCTION
    END IF
    .FramesWritten += .SampleWritten '1
    END WITH
    RESULT = 1
END FUNCTION


    '======================================================
    '    clear memory for new instance of QAVI
    '======================================================

SUB New()
    WITH QAVI
        .Retrn       = 0&
        .pAVIFile    = 0&
        .pAVIStream  = 0&
        .pAVICompress  = 0&
        MEMSET(QAVI.FileInfo, 0, SizeOf(QAVI.FileInfo))         'need full reference
        MEMSET(QAVI.StreamInfo, 0, SizeOf(QAVI.StreamInfo))
        .numFrames   = 0&
        .firstFrame  = 0&
        .NumFrames = 0&
        .Error       = ""
        .ShowError   = 0
        .Width       = 0&
        .Height      = 0&
        .ShowDialog  = 0
        .UseCompression =0
        .Quality     = 10000
        .bpp         = 24
        .FramesWritten = 0&
        .SampleWritten =0&
        .BytesWritten  =0&
    END WITH
END SUB


CONSTRUCTOR
    New
END CONSTRUCTOR

END TYPE        'QAVI



  