'****************************************************************
'*  Derived from VFW.bas... VB32 wrapper for Win32 Video For Windows
'*                           functions.
'*  created:        1998 by Ray Mercer
'*
'*  last modified:  12/2/98 by Ray Mercer (added comments)
'*
'*  a Visual Basic translation of Microsoft's vfw.h file which is
'*  a part of the Win32 Platform SDK
'*
'*  Copyright (c) 1998 Ray Mercer.  All rights reserved.
'****************************************************************

$IFNDEF __VFW_INC
	$DEFINE __VFW_INC
$ENDIF

$IFNDEF TRUE
	$DEFINE TRUE 1
$ENDIF

$IFNDEF FALSE
	$DEFINE FALSE 0
$ENDIF



'//General WINAPI Declares
$IFNDEF __WIN32API       'windows inc loaded?
$IFNDEF __RQINC2         'RapidQ2.inc loaded?

$DEFINE WM_USER &H400
    'window styles for capture window
$DEFINE WS_OVERLAPPED       &H00000000
$DEFINE WS_CHILD            &H40000000
$DEFINE WS_MINIMIZE         &H20000000
$DEFINE WS_VISIBLE          &H10000000
$DEFINE WS_DISABLED         &H08000000
$DEFINE WS_MAXIMIZE         &H01000000
$DEFINE WS_CAPTION          &H00C00000     '/* WS_BORDER | WS_DLGFRAME  */
$DEFINE WS_BORDER           &H00800000
$DEFINE WS_DLGFRAME         &H00400000
$DEFINE WS_THICKFRAME       &H00040000
    'extended windows styles
$DEFINE WS_EX_DLGMODALFRAME     &H00000001
$DEFINE WS_EX_NOPARENTNOTIFY    &H00000004
$DEFINE WS_EX_TOPMOST           &H00000008
$DEFINE WS_EX_TRANSPARENT       &H00000020
$DEFINE WS_EX_TOOLWINDOW        &H00000080
$DEFINE WS_EX_WINDOWEDGE        &H00000100
$DEFINE WS_EX_CLIENTEDGE        &H00000200
$DEFINE WS_EX_STATICEDGE        &H00020000
$DEFINE WS_EX_APPWINDOW         &H00040000


'set windows position
$DEFINE SWP_NOSIZE             &H1
$DEFINE SWP_NOMOVE	           &H2
$DEFINE SWP_NOZORDER 	       &H4
$DEFINE SWP_NOACTIVATE 	       &H10
$DEFINE SWP_SHOWWINDOW 	       &H40
$DEFINE SWP_NOSENDCHANGING	   &H400  'Don't send WM_WINDOWPOSCHANGING */



Declare Function SendMessageAPI Lib "user32" Alias "SendMessageA" (ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, lParam As Long) As Long


'VFW "customized" File Dialogs
TYPE OPENFILENAME
	lStructSize 	AS DWORD	'Specifies the length, in bytes, of the structure. 
	hwndOwner 		AS LONG		'any valid window handle, or it can be NULL if the dialog box has no owner
	hInstance 		AS LONG		'for OFN_ENABLETEMPLATEHANDLE or ENABLETEMPLATE  flags
	lpstrFilter 	AS LONG		'pointer to string containing pairs of filter strings, ("*.TXT;*.DOC;*.BAK"), no spaces!
	lpstrCustomFilter AS LONG	'null or pointer to a pair of null-terminated filter strings for preserving the filter pattern chosen by the user
	nMaxCustFilter 	AS DWORD	'the size, in bytes of the buffer identified by lpstrCustomFilter
	nFilterIndex 	AS DWORD	'index of the currently selected filter in the File Types 
	lpstrFile 		AS LONG		'Pointer to string of the file name to initialize control,can be multple if OFN_ALLOWMULTISELECT  set, _
								'first char must be NULL if no initialization. Returns drive designator, path, file name, and extension of the selected file. 
	nMaxFile 		AS DWORD	'size in bytes of lpstrFile should be >256 chars
	lpstrFileTitle 	AS LONG		'Pointer to string that receives the file name and extension (without path information) of the selected file. This member can be NULL
	nMaxFileTitle 	AS DWORD	'size in bytes of lpstrFileTitle
	lpstrInitialDir AS LONG		'pointer to string containing directory, different effect on different OS versions!
	lpstrTitle 		AS LONG		'pointer to string containing title
	flags 			AS DWORD	'
	nFileOffset 	AS SHORT	'zero-based offset, number of chars  to the 1st character of the file name in lpstrFile (not path)
	nFileExtension 	AS SHORT	'zero-based offset, number of chars  to the 1st character of the file extension in lpstrFile (not path)
	lpstrDefExt 	AS LONG		'pointer to string to append as filename extension if the user fails to type an extension- only 3 characters are used, should not contain a period (.)
	lCustData 		AS LONG		'AS LPARM
	lpfnHook 		AS LONG		'AS LPOFNHOOKPROC, pointer to callback function
	lpTemplateName 	AS LONG		'pointer to string that names a dialog template resource in the module identified by the hInstance member
'#if (_WIN32_WINNT >= 0x0500)
'  void *        pvReserved;
'  DWORD         dwReserved;
'  DWORD         FlagsEx;
'#endif // (_WIN32_WINNT >= 0x0500)
END TYPE



$ENDIF		' __RQINC2


Declare Function DestroyWindow Lib "user32" Alias "DestroyWindow" (ByVal hwnd As Long) As Long


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


Type BITMAPINFO
   'bmiHeader As BITMAPINFOHEADER	'cant nest in RapidQ
    bmiHeader_biSize 			As DWORD'Specifies the number of bytes required by the structure.
    bmiHeader_biWidth 			As LONG	'Specifies the width of the bitmap, in pixels.
    bmiHeader_biHeight 			As LONG	'height, if positive, bitmap is bottom-up DIB (origin = lower left corner). If biHeight is negative,  bitmap is top-down DIB (origin = upper left corner)
    bmiHeader_biPlanes 			As WORD	'number of planes, must be set to 1
    bmiHeader_biBitCount 		As WORD	'number of bits per pixel, must be 1, 4, 8, 16, 24, or 32
    bmiHeader_biCompression 	As DWORD 'type of compression for a compressed bottom-up bitmap (top-down DIBs cannot be compressed)
											'BI_RGB	= An uncompressed format
											'BI_RLE8	= A run-length encoded (RLE) format for bitmaps with 8 bits per pixel.
											'BI_RLE4 = An RLE format for bitmaps with 4 bits per pixel.
											'BI_BITFIELDS =	not compressed and that the color table consists of three doubleword color masks(RGB) respectively, of each pixel, for 16- and 32-bits-per-pixel
    bmiHeader_biSizeImage 		As DWORD	'the size, in bytes, of the image, may be set to 0 for BI_RGB bitmaps.
    bmiHeader_biXPelsPerMeter 	As LONG		'horizontal resolution, in pixels per meter, of the target device for the bitmap. 
    bmiHeader_biYPelsPerMeter 	As LONG
    bmiHeader_biClrUsed 		As DWORD	'number of color indices in the color table actually used, if zero, the bitmap uses max of biBitCount
    bmiHeader_biClrImportant 	As DWORD	'number of color indices that are considered important for displaying the bitmap
	'bmiColors As RGBQUAD
    bmiColors_rgbBlue 			As Byte
    bmiColors_rgbGreen 			As Byte
    bmiColors_rgbRed 			As Byte
    bmiColors_rgbReserved 		As Byte
End Type


$ENDIF		'__WIN32API



'------------------------------------------------------------------
'  Messages which can be sent to an AVICAP window
'------------------------------------------------------------------
Public Const WM_CAP_START As Long = WM_USER

Public Const WM_CAP_GET_CAPSTREAMPTR As Long = WM_CAP_START + 1

Public Const WM_CAP_SET_CALLBACK_ERROR As Long = WM_CAP_START + 2
Public Const WM_CAP_SET_CALLBACK_STATUS As Long = WM_CAP_START + 3
Public Const WM_CAP_SET_CALLBACK_YIELD As Long = WM_CAP_START + 4
Public Const WM_CAP_SET_CALLBACK_FRAME As Long = WM_CAP_START + 5
Public Const WM_CAP_SET_CALLBACK_VIDEOSTREAM As Long = WM_CAP_START + 6
Public Const WM_CAP_SET_CALLBACK_WAVESTREAM As Long = WM_CAP_START + 7
Public Const WM_CAP_GET_USER_DATA As Long = WM_CAP_START + 8
Public Const WM_CAP_SET_USER_DATA As Long = WM_CAP_START + 9
    
Public Const WM_CAP_DRIVER_CONNECT As Long = WM_CAP_START + 10
Public Const WM_CAP_DRIVER_DISCONNECT As Long = WM_CAP_START + 11
Public Const WM_CAP_DRIVER_GET_NAME As Long = WM_CAP_START + 12
Public Const WM_CAP_DRIVER_GET_VERSION As Long = WM_CAP_START + 13
Public Const WM_CAP_DRIVER_GET_CAPS As Long = WM_CAP_START + 14

Public Const WM_CAP_FILE_SET_CAPTURE_FILE As Long = WM_CAP_START + 20
Public Const WM_CAP_FILE_GET_CAPTURE_FILE As Long = WM_CAP_START + 21
Public Const WM_CAP_FILE_ALLOCATE As Long = WM_CAP_START + 22
Public Const WM_CAP_FILE_SAVEAS As Long = WM_CAP_START + 23
Public Const WM_CAP_FILE_SET_INFOCHUNK As Long = WM_CAP_START + 24
Public Const WM_CAP_FILE_SAVEDIB As Long = WM_CAP_START + 25

Public Const WM_CAP_EDIT_COPY As Long = WM_CAP_START + 30

Public Const WM_CAP_SET_AUDIOFORMAT As Long = WM_CAP_START + 35
Public Const WM_CAP_GET_AUDIOFORMAT As Long = WM_CAP_START + 36

Public Const WM_CAP_DLG_VIDEOFORMAT As Long = WM_CAP_START + 41
Public Const WM_CAP_DLG_VIDEOSOURCE As Long = WM_CAP_START + 42
Public Const WM_CAP_DLG_VIDEODISPLAY As Long = WM_CAP_START + 43
Public Const WM_CAP_GET_VIDEOFORMAT As Long = WM_CAP_START + 44
Public Const WM_CAP_SET_VIDEOFORMAT As Long = WM_CAP_START + 45
Public Const WM_CAP_DLG_VIDEOCOMPRESSION As Long = WM_CAP_START + 46

Public Const WM_CAP_SET_PREVIEW As Long = WM_CAP_START + 50
Public Const WM_CAP_SET_OVERLAY As Long = WM_CAP_START + 51
Public Const WM_CAP_SET_PREVIEWRATE As Long = WM_CAP_START + 52
Public Const WM_CAP_SET_SCALE As Long = WM_CAP_START + 53
Public Const WM_CAP_GET_STATUS As Long = WM_CAP_START + 54
Public Const WM_CAP_SET_SCROLL As Long = WM_CAP_START + 55

Public Const WM_CAP_GRAB_FRAME As Long = WM_CAP_START + 60
Public Const WM_CAP_GRAB_FRAME_NOSTOP As Long = WM_CAP_START + 61

Public Const WM_CAP_SEQUENCE As Long = WM_CAP_START + 62
Public Const WM_CAP_SEQUENCE_NOFILE As Long = WM_CAP_START + 63
Public Const WM_CAP_SET_SEQUENCE_SETUP As Long = WM_CAP_START + 64
Public Const WM_CAP_GET_SEQUENCE_SETUP As Long = WM_CAP_START + 65
Public Const WM_CAP_SET_MCI_DEVICE As Long = WM_CAP_START + 66
Public Const WM_CAP_GET_MCI_DEVICE As Long = WM_CAP_START + 67
Public Const WM_CAP_STOP As Long = WM_CAP_START + 68
Public Const WM_CAP_ABORT As Long = WM_CAP_START + 69

Public Const WM_CAP_SINGLE_FRAME_OPEN As Long = WM_CAP_START + 70
Public Const WM_CAP_SINGLE_FRAME_CLOSE As Long = WM_CAP_START + 71
Public Const WM_CAP_SINGLE_FRAME As Long = WM_CAP_START + 72

Public Const WM_CAP_PAL_OPEN As Long = WM_CAP_START + 80
Public Const WM_CAP_PAL_SAVE As Long = WM_CAP_START + 81
Public Const WM_CAP_PAL_PASTE As Long = WM_CAP_START + 82
Public Const WM_CAP_PAL_AUTOCREATE As Long = WM_CAP_START + 83
Public Const WM_CAP_PAL_MANUALCREATE As Long = WM_CAP_START + 84

Public Const WM_CAP_SET_CALLBACK_CAPCONTROL As Long = WM_CAP_START + 85

' ------------------------------------------------------------------
'  VFW UDTS (from vfw.h)
' ------------------------------------------------------------------

Type VFWPOINT 		'strange name to avoid collision with other POINT UDTs
        x As Long
        y As Long
End Type

Type CAPDRIVERCAPS
    wDeviceIndex As Long                    '// Driver index in system.ini
    fHasOverlay As Long                     '// Can device overlay?
    fHasDlgVideoSource As Long              '// Has Video source dlg?
    fHasDlgVideoFormat As Long              '// Has Format dlg?
    fHasDlgVideoDisplay As Long             '// Has External out dlg?
    fCaptureInitialized As Long             '// Driver ready to capture?
    fDriverSuppliesPalettes As Long         '// Can driver make palettes?
    hVideoIn As Long                        '// Driver In channel
    hVideoOut As Long                       '// Driver Out channel
    hVideoExtIn As Long                     '// Driver Ext In channel
    hVideoExtOut As Long                    '// Driver Ext Out channel
End Type

Type CAPSTATUS
    uiImageWidth As Long                    '// Width of the image
    uiImageHeight As Long                   '// Height of the image
    fLiveWindow As Long                     '// Now Previewing video?
    fOverlayWindow As Long                  '// Now Overlaying video?
    fScale As Long                          '// Scale image to client?
'    ptScroll As VFWPOINT                    '// Scroll position
    ptScroll_x As Long
    ptScroll_y As Long
    fUsingDefaultPalette As Long            '// Using default driver palette?
    fAudioHardware As Long                  '// Audio hardware present?
    fCapFileExists As Long                  '// Does capture file exist?
    dwCurrentVideoFrame As Long             '// # of video frames cap'td
    dwCurrentVideoFramesDropped As Long     '// # of video frames dropped
    dwCurrentWaveSamples As Long            '// # of wave samples cap'td
    dwCurrentTimeElapsedMS As Long          '// Elapsed capture duration
    hPalCurrent As Long                     '// Current palette in use
    fCapturingNow As Long                   '// Capture in progress?
    dwReturn As Long                        '// Error value after any operation
    wNumVideoAllocated As Long              '// Actual number of video buffers
    wNumAudioAllocated As Long              '// Actual number of audio buffers
End Type

Public Const AVSTREAMMASTER_AUDIO As Long = 0  '/* Audio master (VFW 1.0, 1.1) */
Public Const AVSTREAMMASTER_NONE  As Long = 1  '/* No master */

Type CAPTUREPARMS
    dwRequestMicroSecPerFrame As Long       '// Requested capture rate
    fMakeUserHitOKToCapture As Long         '// Show "Hit OK to cap" dlg?
    wPercentDropForError As Long            '// Give error msg if > (10% default)
    fYield As Long                          '// Capture via background task?
    dwIndexSize As Long                     '// Max index size in frames (32K default)
    wChunkGranularity As Long               '// Junk chunk granularity (2K default)
    fUsingDOSMemory As Long                 '// Use DOS buffers? (obsolete)
    wNumVideoRequested As Long              '// # video buffers, If 0, autocalc
    fCaptureAudio As Long                   '// Capture audio?
    wNumAudioRequested As Long              '// # audio buffers, If 0, autocalc
    vKeyAbort As Long                       '// Virtual key causing abort
    fAbortLeftMouse As Long                 '// Abort on left mouse?
    fAbortRightMouse As Long                '// Abort on right mouse?
    fLimitEnabled As Long                   '// Use wTimeLimit?
    wTimeLimit As Long                      '// Seconds to capture
    fMCIControl As Long                     '// Use MCI video source?
    fStepMCIDevice As Long                  '// Step MCI device?
    dwMCIStartTime As Long                  '// Time to start in MS
    dwMCIStopTime As Long                   '// Time to stop in MS
    fStepCaptureAt2x As Long                '// Perform spatial averaging 2x
    wStepCaptureAverageFrames As Long       '// Temporal average n Frames
    dwAudioBufferSize As Long               '// Size of audio bufs (0 = default)
    fDisableWriteCache As Long              '// Attempt to disable write cache
    AVStreamMaster As Long                  '// Which stream controls length?
End Type
                                            

TYPE CAPINFOCHUNK
    fccInfoID As Long                       '// Chunk ID, "ICOP" for copyright
    lpData As Long                          '// pointer to data
    cbData As Long                          '// size of lpData
END TYPE

TYPE VIDEOHDR
    lpData As Long                          ' address of video buffer
    dwBufferLength As Long                  ' size, in bytes, of the Data buffer
    dwBytesUsed As Long                     ' Bytes actually used
    dwTimeCaptured As Long                  ' Milliseconds from start of stream
    dwUser As Long                          ' user-specific data
    dwFlags As Long                         ' VHDR_DONE 		Done bit 
											' VHDR_PREPARED 	Set if this header has been prepared  
											' VHDR_INQUEUE 	Reserved for driver  
											' VHDR_KEYFRAME 	Key Frame  
    dwReserved(3) As Long                   ' reserved; do not use
END TYPE



TYPE WAVEFORMATEX
	wFormatTag 	AS WORD
    nChannels 	AS WORD   
    nSamplesPerSec AS DWORD
    nAvgBytesPerSec AS DWORD
    nBlockAlign AS WORD
    wBitsPerSample AS WORD
    cbSize AS WORD
END TYPE


'// Capture Function Declares
Declare Function capCreateCaptureWindow Lib "avicap32.dll" Alias "capCreateCaptureWindowA" _
                                        (ByVal lpszWindowName As String, _
                                        ByVal dwStyle As Long, _
                                        ByVal x As Long, _
                                        ByVal y As Long, _
                                        ByVal nWidth As Long, _
                                        ByVal nHeight As Long, _
                                        ByVal hwndParent As Long, _
                                        ByVal nID As Long) As Long 'returns HWND

Declare Function capGetDriverDescription Lib "avicap32.dll" Alias "capGetDriverDescriptionA" _
                                        (ByVal dwDriverIndex As Long, _
                                        ByVal lpszName As String, _
                                        ByVal cbName As Long, _
                                        ByVal lpszVer As String, _
                                        ByVal cbVer As Long) As Long 'returns C BOOL



Declare Function GetOpenFileNamePreview Lib "msvfw32.dll" _
    Alias "GetOpenFileNamePreviewA" (filestruct As OPENFILENAME) As Long
PRIVATE Declare Function GetSaveFileNamePreview Lib "msvfw32.dll" _
    Alias "GetSaveFileNamePreviewA" (filestruct As OPENFILENAME) As Long



'// ------------------------------------------------------------------
'// IDs for status and error callbacks
'// ------------------------------------------------------------------

Public Const IDS_CAP_BEGIN As Long = 300              '/* "Capture Start" */
Public Const IDS_CAP_END As Long = 301                '/* "Capture End" */

Public Const IDS_CAP_INFO As Long = 401               '/* "%s" */
Public Const IDS_CAP_OUTOFMEM As Long = 402           '/* "Out of memory" */
Public Const IDS_CAP_FILEEXISTS As Long = 403         '/* "File '%s' exists -- overwrite it?" */
Public Const IDS_CAP_ERRORPALOPEN As Long = 404       '/* "Error opening palette '%s'" */
Public Const IDS_CAP_ERRORPALSAVE As Long = 405       '/* "Error saving palette '%s'" */
Public Const IDS_CAP_ERRORDIBSAVE As Long = 406       '/* "Error saving frame '%s'" */
Public Const IDS_CAP_DEFAVIEXT As Long = 407          '/* "avi" */
Public Const IDS_CAP_DEFPALEXT As Long = 408          '/* "pal" */
Public Const IDS_CAP_CANTOPEN As Long = 409           '/* "Cannot open '%s'" */
Public Const IDS_CAP_SEQ_MSGSTART As Long = 410       '/* "Select OK to start capture\nof video sequence\nto %s." */
Public Const IDS_CAP_SEQ_MSGSTOP As Long = 411        '/* "Hit ESCAPE or click to end capture" */
                
Public Const IDS_CAP_VIDEDITERR As Long = 412         '/* "An error occurred while trying to run VidEdit." */
Public Const IDS_CAP_READONLYFILE As Long = 413       '/* "The file '%s' is a read-only file." */
Public Const IDS_CAP_WRITEERROR As Long = 414         '/* "Unable to write to file '%s'.\nDisk may be full." */
Public Const IDS_CAP_NODISKSPACE As Long = 415        '/* "There is no space to create a capture file on the specified device." */
Public Const IDS_CAP_SETFILESIZE As Long = 416        '/* "Set File Size" */
Public Const IDS_CAP_SAVEASPERCENT As Long = 417      '/* "SaveAs: %2ld%%  Hit Escape to abort." */
                
Public Const IDS_CAP_DRIVER_ERROR As Long = 418       '/* Driver specific error message */

Public Const IDS_CAP_WAVE_OPEN_ERROR As Long = 419    '/* "Error: Cannot open the wave input device.\nCheck sample size, frequency, and channels." */
Public Const IDS_CAP_WAVE_ALLOC_ERROR As Long = 420   '/* "Error: Out of memory for wave buffers." */
Public Const IDS_CAP_WAVE_PREPARE_ERROR As Long = 421 '/* "Error: Cannot prepare wave buffers." */
Public Const IDS_CAP_WAVE_ADD_ERROR As Long = 422     '/* "Error: Cannot add wave buffers." */
Public Const IDS_CAP_WAVE_SIZE_ERROR As Long = 423    '/* "Error: Bad wave size." */
                
Public Const IDS_CAP_VIDEO_OPEN_ERROR As Long = 424   '/* "Error: Cannot open the video input device." */
Public Const IDS_CAP_VIDEO_ALLOC_ERROR As Long = 425  '/* "Error: Out of memory for video buffers." */
Public Const IDS_CAP_VIDEO_PREPARE_ERROR As Long = 426 '/* "Error: Cannot prepare video buffers." */
Public Const IDS_CAP_VIDEO_ADD_ERROR As Long = 427    '/* "Error: Cannot add video buffers." */
Public Const IDS_CAP_VIDEO_SIZE_ERROR As Long = 428   '/* "Error: Bad video size." */
                
Public Const IDS_CAP_FILE_OPEN_ERROR As Long = 429    '/* "Error: Cannot open capture file." */
Public Const IDS_CAP_FILE_WRITE_ERROR As Long = 430   '/* "Error: Cannot write to capture file.  Disk may be full." */
Public Const IDS_CAP_RECORDING_ERROR As Long = 431    '/* "Error: Cannot write to capture file.  Data rate too high or disk full." */
Public Const IDS_CAP_RECORDING_ERROR2 As Long = 432   '/* "Error while recording" */
Public Const IDS_CAP_AVI_INIT_ERROR As Long = 433     '/* "Error: Unable to initialize for capture." */
Public Const IDS_CAP_NO_FRAME_CAP_ERROR As Long = 434 '/* "Warning: No frames captured.\nConfirm that vertical sync interrupts\nare configured and enabled." */
Public Const IDS_CAP_NO_PALETTE_WARN As Long = 435    '/* "Warning: Using default palette." */
Public Const IDS_CAP_MCI_CONTROL_ERROR As Long = 436  '/* "Error: Unable to access MCI device." */
Public Const IDS_CAP_MCI_CANT_STEP_ERROR As Long = 437 '/* "Error: Unable to step MCI device." */
Public Const IDS_CAP_NO_AUDIO_CAP_ERROR As Long = 438 '/* "Error: No audio data captured.\nCheck audio card settings." */
Public Const IDS_CAP_AVI_DRAWDIB_ERROR As Long = 439  '/* "Error: Unable to draw this data format." */
Public Const IDS_CAP_COMPRESSOR_ERROR As Long = 440   '/* "Error: Unable to initialize compressor." */
Public Const IDS_CAP_AUDIO_DROP_ERROR As Long = 441   '/* "Error: Audio data was lost during capture, reduce capture rate." */
                
'/* status string IDs */
Public Const IDS_CAP_STAT_LIVE_MODE As Long = 500      '/* "Live window" */
Public Const IDS_CAP_STAT_OVERLAY_MODE As Long = 501   '/* "Overlay window" */
Public Const IDS_CAP_STAT_CAP_INIT As Long = 502       '/* "Setting up for capture - Please wait" */
Public Const IDS_CAP_STAT_CAP_FINI As Long = 503       '/* "Finished capture, now writing frame %ld" */
Public Const IDS_CAP_STAT_PALETTE_BUILD As Long = 504  '/* "Building palette map" */
Public Const IDS_CAP_STAT_OPTPAL_BUILD As Long = 505   '/* "Computing optimal palette" */
Public Const IDS_CAP_STAT_I_FRAMES As Long = 506       '/* "%d frames" */
Public Const IDS_CAP_STAT_L_FRAMES As Long = 507       '/* "%ld frames" */
Public Const IDS_CAP_STAT_CAP_L_FRAMES As Long = 508   '/* "Captured %ld frames" */
Public Const IDS_CAP_STAT_CAP_AUDIO As Long = 509      '/* "Capturing audio" */
Public Const IDS_CAP_STAT_VIDEOCURRENT As Long = 510   '/* "Captured %ld frames (%ld dropped) %d.%03d sec." */
Public Const IDS_CAP_STAT_VIDEOAUDIO As Long = 511     '/* "Captured %d.%03d sec.  %ld frames (%ld dropped) (%d.%03d fps).  %ld audio bytes (%d,%03d sps)" */
Public Const IDS_CAP_STAT_VIDEOONLY As Long = 512      '/* "Captured %d.%03d sec.  %ld frames (%ld dropped) (%d.%03d fps)" */


'Translations of C- "Message Cracker" Macros to VB (declared in vfw.h)
' to disable Callbacks, set lpProc to 0
Function capSetCallbackOnError(ByVal hCapWnd As Long, ByVal lpProc As Long) As Long' Boolean
   capSetCallbackOnError = SendMessageAPI(hCapWnd, WM_CAP_SET_CALLBACK_ERROR, 0&, lpProc)
End Function
Function capSetCallbackOnStatus(ByVal hCapWnd As Long, ByVal lpProc As Long) As Long' Boolean
   capSetCallbackOnStatus = SendMessageAPI(hCapWnd, WM_CAP_SET_CALLBACK_STATUS, 0&, lpProc)
End Function
Function capSetCallbackOnYield(ByVal hCapWnd As Long, ByVal lpProc As Long) As Long' Boolean
   capSetCallbackOnYield = SendMessageAPI(hCapWnd, WM_CAP_SET_CALLBACK_YIELD, 0&, lpProc)
End Function
Function capSetCallbackOnFrame(ByVal hCapWnd As Long, ByVal lpProc As Long) As Long' Boolean
   capSetCallbackOnFrame = SendMessageAPI(hCapWnd, WM_CAP_SET_CALLBACK_FRAME, 0&, lpProc)
End Function
Function capSetCallbackOnVideoStream(ByVal hCapWnd As Long, ByVal lpProc As Long) As Long' Boolean
   capSetCallbackOnVideoStream = SendMessageAPI(hCapWnd, WM_CAP_SET_CALLBACK_VIDEOSTREAM, 0&, lpProc)
End Function
	'Proper CallBack Function template:
	' use for capSetCallbackOnFrame  OR capSetCallbackOnVideoStream
	'FUNCTION capVideoStreamCallback(hCapWnd AS LONG, lpVHdr AS VIDEOHDR) AS LONG
	'...
	'END FUNCTION

	'IF capSetCallbackOnFrame(hCapWnd, CODEPTR(capVideoStreamCallback) = 0 THEN 'flag error


Function capSetCallbackOnWaveStream(ByVal hCapWnd As Long, ByVal lpProc As Long) As Long' Boolean
   capSetCallbackOnWaveStream = SendMessageAPI(hCapWnd, WM_CAP_SET_CALLBACK_WAVESTREAM, 0&, lpProc)
End Function
Function capSetCallbackOnCapControl(ByVal hCapWnd As Long, ByVal lpProc As Long) As Long' Boolean
   capSetCallbackOnCapControl = SendMessageAPI(hCapWnd, WM_CAP_SET_CALLBACK_CAPCONTROL, 0&, lpProc)
End Function

Function capSetUserData(ByVal hCapWnd As Long, ByVal lUser As Long) As Long' Boolean
   capSetUserData = SendMessageAPI(hCapWnd, WM_CAP_SET_USER_DATA, 0&, lUser)
End Function
Function capGetUserData(ByVal hCapWnd As Long) As Long
   capGetUserData = SendMessageAPI(hCapWnd, WM_CAP_GET_USER_DATA, 0&, 0&)
End Function

Function capDriverConnect(ByVal hCapWnd As Long, ByVal i As Long) As Long' Boolean
'	i = 0&
   capDriverConnect = SendMessageAPI(hCapWnd, WM_CAP_DRIVER_CONNECT, i, 0&)
End Function

Function capDriverDisconnect(ByVal hCapWnd As Long) As Long' Boolean
   capDriverDisconnect = SendMessageAPI(hCapWnd, WM_CAP_DRIVER_DISCONNECT, 0&, 0&)
End Function

Function capDriverGetName(ByVal hCapWnd As Long) As String
   'returns driver name as VB string
   Dim szBuffer As String
   
   szBuffer = String$(128, 0)
   Call SendMessageAPI(hCapWnd, WM_CAP_DRIVER_GET_NAME, 128, szBuffer)
   capDriverGetName = Left$(szBuffer, InStr(szBuffer, CHR$(0)) - 1)
End Function

Function capDriverGetVersion(ByVal hCapWnd As Long) As String
   'returns version as VB string
   Dim szBuffer As String
   Dim retVal As Long' Boolean
   
   szBuffer = String$(128, 0)
   retVal = SendMessageAPI(hCapWnd, WM_CAP_DRIVER_GET_VERSION, 128, szBuffer)
    If 0 <> retVal Then
        capDriverGetVersion = Left$(szBuffer, InStr(szBuffer, CHR$(0)) - 1)
    End If
End Function

Function capDriverGetCaps(hCapWnd As Long, Caps As CAPDRIVERCAPS, lSize AS LONG) As Long' Boolean
   'fills CAPDRIVERCAPS UDT
   capDriverGetCaps = SendMessageAPI(hCapWnd, WM_CAP_DRIVER_GET_CAPS, lSize, Caps)
End Function

Function capFileSetCaptureFile(ByVal hCapWnd As Long, lpSzFileName As Long) As Long	'ByVal FilePath As String) As Long
   capFileSetCaptureFile = SendMessageAPI(hCapWnd, WM_CAP_FILE_SET_CAPTURE_FILE, 0&, lpSzFileName)
End Function

Function capFileGetCaptureFile(ByVal hCapWnd As Long) As String
   'returns full path of capture file as VB string
   Dim szBuffer As String
   Dim retVal As Long' Boolean

   szBuffer = String$(128, 0)
   retVal = SendMessageAPI(hCapWnd, WM_CAP_FILE_GET_CAPTURE_FILE, 128, szBuffer)
    If retVal Then
        capFileGetCaptureFile = Left$(szBuffer, InStr(szBuffer, CHR$(0)) - 1)
    End If
End Function

Function capFileAlloc(ByVal hCapWnd As Long, ByVal dwSize As Long) As Long' Boolean
   capFileAlloc = SendMessageAPI(hCapWnd, WM_CAP_FILE_ALLOCATE, 0&, dwSize)
End Function

Function capFileSaveAs(ByVal hCapWnd As Long, ByVal lpSzFilePath As Long) As Long' Boolean
   capFileSaveAs = SendMessageAPI(hCapWnd, WM_CAP_FILE_SAVEAS, 0&, lpSzFilePath)
End Function

Function capFileSetInfoChunk(ByVal hCapWnd As Long, ByRef InfChunk As CAPINFOCHUNK) As Long' Boolean
   capFileSetInfoChunk = SendMessageAPI(hCapWnd, WM_CAP_FILE_SET_INFOCHUNK, 0&, InfChunk)
End Function

Function capFileSaveDIB(ByVal hCapWnd As Long, ByVal lpSzFileName As Long) As Long
   capFileSaveDIB = SendMessageAPI(hCapWnd, WM_CAP_FILE_SAVEDIB, 0&, lpSzFileName)
End Function

Function capEditCopy(ByVal hCapWnd As Long) As Long' Boolean
   capEditCopy = SendMessageAPI(hCapWnd, WM_CAP_EDIT_COPY, 0&, 0&)
End Function

Function capSetAudioFormat(ByVal hCapWnd As Long, ByRef wavFormat As WAVEFORMATEX, ByVal WavFormatSize As Long) As Long' Boolean
   capSetAudioFormat = SendMessageAPI(hCapWnd, WM_CAP_SET_AUDIOFORMAT, WavFormatSize, wavFormat)
End Function

Function capSetAudioFormatAsArray(ByVal hCapWnd As Long, ByVal wavFormat As Long, ByVal WavFormatSize As Long) As Long' Boolean
   capSetAudioFormatAsArray = SendMessageAPI(hCapWnd, WM_CAP_SET_AUDIOFORMAT, WavFormatSize, wavFormat)
End Function

Function capGetAudioFormat(ByVal hCapWnd As Long, ByRef wavFormat As WAVEFORMATEX, ByVal WavFormatSize As Long) As Long
   capGetAudioFormat = SendMessageAPI(hCapWnd, WM_CAP_GET_AUDIOFORMAT, WavFormatSize, wavFormat)
End Function

Function capGetAudioFormatAsArray(ByVal hCapWnd As Long, ByVal wavFormat As Long, ByVal WavFormatSize As Long) As Long
   capGetAudioFormatAsArray = SendMessageAPI(hCapWnd, WM_CAP_GET_AUDIOFORMAT, WavFormatSize, wavFormat)
End Function

Function capGetAudioFormatSize(ByVal hCapWnd As Long) As Long
   capGetAudioFormatSize = SendMessageAPI(hCapWnd, WM_CAP_GET_AUDIOFORMAT, 0&, 0&)
End Function

Function capDlgVideoFormat(ByVal hCapWnd As Long) As Long' Boolean
   capDlgVideoFormat = SendMessageAPI(hCapWnd, WM_CAP_DLG_VIDEOFORMAT, 0&, 0&)
End Function

Function capDlgVideoSource(ByVal hCapWnd As Long) As Long' Boolean
   capDlgVideoSource = SendMessageAPI(hCapWnd, WM_CAP_DLG_VIDEOSOURCE, 0&, 0&)
End Function

Function capDlgVideoDisplay(ByVal hCapWnd As Long) As Long' Boolean
   capDlgVideoDisplay = SendMessageAPI(hCapWnd, WM_CAP_DLG_VIDEODISPLAY, 0&, 0&)
End Function

Function capDlgVideoCompression(ByVal hCapWnd As Long) As Long' Boolean
   capDlgVideoCompression = SendMessageAPI(hCapWnd, WM_CAP_DLG_VIDEOCOMPRESSION, 0&, 0&)
End Function

Function capGetVideoFormat(ByVal hCapWnd As Long, ByRef BmpFormat As BITMAPINFO, ByVal CapFormatSize As Long) As Long
   capGetVideoFormat = SendMessageAPI(hCapWnd, WM_CAP_GET_VIDEOFORMAT, CapFormatSize, BmpFormat)
End Function

Function capGetVideoFormatSize(ByVal hCapWnd As Long) As Long
   capGetVideoFormatSize = SendMessageAPI(hCapWnd, WM_CAP_GET_VIDEOFORMAT, 0&, 0&)
End Function

Function capSetVideoFormat(ByVal hCapWnd As Long, ByRef BmpFormat As BITMAPINFO, ByVal CapFormatSize As Long) As Long' Boolean
   capSetVideoFormat = SendMessageAPI(hCapWnd, WM_CAP_SET_VIDEOFORMAT, CapFormatSize, BmpFormat)
End Function

Function capPreview(ByVal hCapWnd As Long, ByVal f As Long) As Long' Boolean
   capPreview = SendMessageAPI(hCapWnd, WM_CAP_SET_PREVIEW, f, 0&) 'convert the VB Boolean to a C BOOL with the - sign
End Function

Function capPreviewRate(ByVal hCapWnd As Long, ByVal wMS As Long) As Long' Boolean
   capPreviewRate = SendMessageAPI(hCapWnd, WM_CAP_SET_PREVIEWRATE, wMS, 0&)
End Function

Function capOverlay(ByVal hCapWnd As Long, ByVal f As Long) As Long' Boolean
   capOverlay = SendMessageAPI(hCapWnd, WM_CAP_SET_OVERLAY, -(f), 0&)
End Function

Function capPreviewScale(ByVal hCapWnd As Long, ByVal f As Long) As Long' Boolean
   capPreviewScale = SendMessageAPI(hCapWnd, WM_CAP_SET_SCALE, -(f), 0&)
End Function

Function capGetStatus(ByVal hCapWnd As Long, ByRef capStat As CAPSTATUS, wSize AS LONG) As Long' Boolean
   capGetStatus = SendMessageAPI(hCapWnd, WM_CAP_GET_STATUS, wSize, capStat)
End Function

Function capSetScrollPos(ByVal hCapWnd As Long, ByRef pt As VFWPOINT) As Long' Boolean
   capSetScrollPos = SendMessageAPI(hCapWnd, WM_CAP_SET_SCROLL, 0&, pt)
End Function

Function capGrabFrame(ByVal hCapWnd As Long) As Long' Boolean
   capGrabFrame = SendMessageAPI(hCapWnd, WM_CAP_GRAB_FRAME, 0&, 0&)
End Function

Function capGrabFrameNoStop(ByVal hCapWnd As Long) As Long' Boolean
   capGrabFrameNoStop = SendMessageAPI(hCapWnd, WM_CAP_GRAB_FRAME_NOSTOP, 0&, 0&)
End Function

Function capCaptureSequence(ByVal hCapWnd As Long) As Long' Boolean
   capCaptureSequence = SendMessageAPI(hCapWnd, WM_CAP_SEQUENCE, 0&, 0&)
End Function

Function capCaptureSequenceNoFile(ByVal hCapWnd As Long) As Long' Boolean
   capCaptureSequenceNoFile = SendMessageAPI(hCapWnd, WM_CAP_SEQUENCE_NOFILE, 0&, 0&)
End Function

Function capCaptureStop(ByVal hCapWnd As Long) As Long' Boolean
   capCaptureStop = SendMessageAPI(hCapWnd, WM_CAP_STOP, 0&, 0&)
End Function

Function capCaptureAbort(ByVal hCapWnd As Long) As Long' Boolean
   capCaptureAbort = SendMessageAPI(hCapWnd, WM_CAP_ABORT, 0&, 0&)
End Function

Function capCaptureSingleFrameOpen(ByVal hCapWnd As Long) As Long' Boolean
   capCaptureSingleFrameOpen = SendMessageAPI(hCapWnd, WM_CAP_SINGLE_FRAME_OPEN, 0&, 0&)
End Function

Function capCaptureSingleFrameClose(ByVal hCapWnd As Long) As Long' Boolean
   capCaptureSingleFrameClose = SendMessageAPI(hCapWnd, WM_CAP_SINGLE_FRAME_CLOSE, 0&, 0&)
End Function

Function capCaptureSingleFrame(ByVal hCapWnd As Long) As Long' Boolean
   capCaptureSingleFrame = SendMessageAPI(hCapWnd, WM_CAP_SINGLE_FRAME, 0&, 0&)
End Function

Function capCaptureGetSetup(ByVal hCapWnd As Long, ByRef capParms As CAPTUREPARMS, S AS LONG) As Long' Boolean
   capCaptureGetSetup = SendMessageAPI(hCapWnd, WM_CAP_GET_SEQUENCE_SETUP, S, capParms)
End Function

Function capCaptureSetSetup(ByVal hCapWnd As Long, capParms As CAPTUREPARMS,  S AS LONG) As Long' Boolean
   capCaptureSetSetup = SendMessageAPI(hCapWnd, WM_CAP_SET_SEQUENCE_SETUP, S, capParms)
End Function

Function capSetMCIDeviceName(ByVal hCapWnd As Long, ByVal lpDeviceName As Long) As Long' Boolean
   'DeviceName = DeviceName & Chr$(0) 'null-terminate the string just to be safe
   capSetMCIDeviceName = SendMessageAPI(hCapWnd, WM_CAP_SET_MCI_DEVICE, 0&, lpDeviceName)
End Function

Function capGetMCIDeviceName(ByVal hCapWnd As Long) As String
   'returns device name as VB string (default name is "")
   Dim dwSize As Long
   Dim szBuffer As String
   
   dwSize = 128 'MCISTRING_MAX
   szBuffer = String$(dwSize, 0)
   Call SendMessageAPI(hCapWnd, WM_CAP_GET_MCI_DEVICE, dwSize, szBuffer)
   capGetMCIDeviceName = Left$(szBuffer, InStr(szBuffer, CHR$(0)) - 1)
End Function

Function capPaletteOpen(ByVal hCapWnd As Long, ByVal lpSzFilePath As LONG) As Long' Boolean
   capPaletteOpen = SendMessageAPI(hCapWnd, WM_CAP_PAL_OPEN, 0&, lpSzFilePath)
End Function

Function capPaletteSave(ByVal hCapWnd As Long, ByVal lpSzFilePath As LONG) As Long' Boolean
   capPaletteSave = SendMessageAPI(hCapWnd, WM_CAP_PAL_SAVE, 0&, lpSzFilePath)
End Function

Function capPalettePaste(ByVal hCapWnd As Long) As Long' Boolean
   capPalettePaste = SendMessageAPI(hCapWnd, WM_CAP_PAL_PASTE, 0&, 0&)
End Function

Function capPaletteAuto(ByVal hCapWnd As Long, ByVal iFrames As Long, ByVal iColors As Long) As Long' Boolean
   IF iColors < 257 THEN     'iColors should not be greater than 256
      capPaletteAuto = SendMessageAPI(hCapWnd, WM_CAP_PAL_AUTOCREATE, iFrames, iColors)
   ELSE
     ShowMessage "Error in Color num -- capPaletteAuto"
   END IF
End Function

Function capPaletteManual(ByVal hCapWnd As Long, ByVal f As Long, ByVal iColors As Long) As Long' Boolean
   IF iColors < 257 THEN       'iColors should not be greater than 256
     capPaletteManual = SendMessageAPI(hCapWnd, WM_CAP_PAL_MANUALCREATE, -(f), iColors)
   ELSE
     ShowMessage "Error in Color num -- capPaletteAuto"
   END IF
End Function





'*********************************************************************************
'*****  
'*****  
'*****    Custom video Cam capture component based on vfw API calls
'*****        John Kelly , 2/2005
'*****  
'*********************************************************************************



TYPE QWebCam EXTENDS QOBJECT

PUBLIC:
	hCapWnd			AS LONG		'our capture window frame (not parent)
	CamNum			AS LONG		'in case more than one camera & driver, index 0 - 9
	Left			AS LONG
	Top				AS LONG
	Width			AS LONG
	Height			AS LONG
	Overlay			AS LONG
	Init 			AS LONG
    FrameBuffers    AS LONG     'max number of requested frame buffers
	ImageHeight		AS LONG		PROPERTY SET SetImageHeight
	ImageWidth		AS LONG		PROPERTY SET SetImageWidth
	BitCount		AS WORD		PROPERTY SET SetBitCount
	Preview			AS LONG		PROPERTY SET SetPreview
	Capture 		AS LONG		PROPERTY SET SetCapture         'to file or each frame buffer
	FrameInterval	AS WORD		'Interval, in milliseconds, between frames are captured and displayed
	FramesDropped	AS LONG
	Caption			AS STRING
	Tag				AS LONG		'window ID from createWindow function
	FormStyle		AS LONG
	'This is an Event but Function pointers don't give absolute address so this doesnt work ->EVENT(OnFrame_EventTemplate)
    OnFrame 		AS LONG		PROPERTY SET SetOnFrame





FUNCTION CamInit(Form AS QFORM) AS LONG			'Create Cap Window, init the web cam
	DIM rtn AS LONG
	DIM	DriverCaps	AS CAPDRIVERCAPS
	DIM MyCapParms	AS CAPTUREPARMS


	IF This.Init THEN EXIT FUNCTION		'been here before? Then don't run

	'**** use capCapture from vfw.inc  ******
	WITH This
	.hCapWnd = capCreateCaptureWindow(.Caption, .FormStyle, .Left, .Top, .Width, .Height, Form.Handle, .tag)
	IF .hCapWnd = 0 THEN
		ShowMessage("Could not create capture window")
		RESULT = 0
		EXIT FUNCTION
	END IF

	' Get the current streaming video parms, and reset with user values
	capCaptureGetSetup(.hCapWnd, MyCapParms, sizeof(MyCapParms))
	MyCapParms.dwRequestMicroSecPerFrame = .FrameInterval '3333 = 30 frames per second
	MyCapParms.fYield = true                      ' capture in background/allow processing
	MyCapParms.wNumVideoRequested = This.FrameBuffers  ' max number of video frame buffs - just a guess
	MyCapParms.fCaptureAudio = false                   ' don't capture audio
	MyCapParms.AVStreamMaster = AVSTREAMMASTER_NONE ' no audio/video syncing

    'set up the driver and capture
    IF capCaptureSetSetup(.hCapWnd, MyCapParms, sizeof(MyCapParms)) = 0 THEN ShowMessage "Set setup failed"
	'capCaptureGetSetup(.hCapWnd, MyCapParms, sizeof(MyCapParms))	'to check if values set...

    'connect
	rtn = capDriverConnect (.hCapWnd, .CamNum)
	IF rtn THEN 
		capDriverGetCaps(.hCapWnd, DriverCaps, sizeof (DriverCaps))
		.Init = DriverCaps.fCaptureInitialized
		.CamNum = DriverCaps.wDeviceIndex	'reset Connect?
		.Overlay = DriverCaps.fHasOverlay
		IF .Overlay THEN .Overlay = capOverlay(.hCapWnd, True)		'auto turn on Overlay
		IF .Preview THEN
			capPreviewRate(.hCapWnd, .FrameInterval)
			.Preview = capPreview(.hCapWnd, True)
		END IF
		IF (.OnFrame <> 0) THEN
			IF capSetCallbackOnFrame(This.hCapWnd, This.OnFrame) = 0 THEN ShowMessage "Frame Callback Error"
		END IF
	ElSE
		ShowMessage("Could not connect to Camera")
	END IF
	END WITH
	RESULT = rtn
END FUNCTION



SUB SetOnFrame(TheCallBackAddr AS LONG)		'pass in 0 to turn off callback
	This.OnFrame = TheCallBackAddr
	IF This.Init THEN
		IF capSetCallbackOnFrame(This.hCapWnd, This.OnFrame) = 0 THEN ShowMessage "Frame Callback Error"
	END IF
END SUB



FUNCTION SetImageHeight (TheImageHeight AS LONG) AS LONG
	DIM VideoFormat AS BITMAPINFO
	DIM SzbmpInfo AS DWORD: SzbmpInfo = SIZEOF(VideoFormat)

	IF TheImageHeight > 0 THEN
		This.ImageHeight =  TheImageHeight
		IF This.Init THEN
			SzbmpInfo = capGetVideoFormat(This.hCapWnd, VideoFormat, SzbmpInfo)
			IF SzbmpInfo = 0 THEN RESULT = 0: EXIT FUNCTION		'crashed!
			VideoFormat.bmiHeader_biSize = SzbmpInfo
			VideoFormat.bmiHeader_biHeight = TheImageHeight		'if positive, bitmap is bottom-up DIB (origin = lower left corner). If biHeight is negative,  bitmap is top-down DIB (origin = upper left corner)
			IF capSetVideoFormat(This.hCapWnd, VideoFormat, SzbmpInfo) THEN
				This.ImageHeight =  TheImageHeight
				RESULT =  TheImageHeight
			END IF
		END IF
	END IF
END FUNCTION


SUB SetImageWidth (TheImageWidth AS LONG) AS LONG
	DIM VideoFormat AS BITMAPINFO
	DIM SzbmpInfo AS DWORD: SzbmpInfo = SIZEOF(VideoFormat)

	IF TheImageWidth > 0 THEN
		This.ImageWidth =  TheImageWidth
		IF This.Init THEN
			SzbmpInfo = capGetVideoFormat(This.hCapWnd, VideoFormat, SzbmpInfo)
			IF SzbmpInfo = 0 THEN RESULT = 0: EXIT SUB		'crashed!
			VideoFormat.bmiHeader_biSize = SzbmpInfo
			VideoFormat.bmiHeader_biWidth = TheImageWidth
			IF capSetVideoFormat(This.hCapWnd, VideoFormat, SzbmpInfo) THEN
				This.ImageWidth =  TheImageWidth
				RESULT =  TheImageWidth
			END IF
		END IF
	END IF
END SUB



FUNCTION SetBitCount (TheBitCount AS WORD) AS WORD
	DIM VideoFormat AS BITMAPINFO
	DIM SzbmpInfo AS DWORD: SzbmpInfo = SIZEOF(VideoFormat)

	RESULT = 0
	IF TheBitCount > 0 THEN
		'This.BitCount =  TheBitCount
		IF This.Init THEN
			SzbmpInfo = capGetVideoFormat(This.hCapWnd, VideoFormat, SzbmpInfo)
			IF SzbmpInfo = 0 THEN RESULT = 0: EXIT FUNCTION		'crashed!
			VideoFormat.bmiHeader_biSize = SzbmpInfo
			VideoFormat.bmiHeader_biBitCount = TheBitCount
			IF capSetVideoFormat(This.hCapWnd, VideoFormat, SzbmpInfo) THEN
				This.BitCount =  TheBitCount
				RESULT =  TheBitCount
			END IF
		END IF
	END IF
END FUNCTION



FUNCTION GetStatus() AS LONG
	DIM CapStats	AS CAPSTATUS

	WITH This
	RESULT = 0
	IF capGetStatus(.hCapWnd, CapStats, SIZEOF(CapStats)) THEN
		.ImageHeight = CapStats.uiImageHeight
		.ImageWidth	= CapStats.uiImageWidth
		.FramesDropped = CapStats.dwCurrentVideoFramesDropped
		.Overlay = CapStats.fOverlayWindow
		.Preview = CapStats.fLiveWindow
		RESULT = True
	END IF
	END WITH
END FUNCTION



SUB ShowDialogBox(TheBoxNum)		'get info button
	DIM WasCapturing	AS LONG
	DIM	DriverCaps	    AS CAPDRIVERCAPS

 	WasCapturing = False	
 	IF TheBoxNum THEN 
 		IF This.Capture THEN 
 			WasCapturing = True
 			This.Capture = False
 		END IF
 
        IF This.Init = False THEN
            capDriverGetCaps(This.hCapWnd, DriverCaps, sizeof (DriverCaps))
        END IF

ShowMessage str$(DriverCaps.fHasDlgVideoFormat)
'ShowMessage str$(DriverCaps.fHasDlgVideoSource)
'ShowMessage str$(DriverCaps.fHasDlgVideoDisplay)

	' Video source Dialog box
		SELECT CASE TheBoxNum
		CASE 1
'            IF DriverCaps.fHasDlgVideoFormat THEN capDlgVideoFormat(This.hCapWnd)
            capDlgVideoFormat(This.hCapWnd)
		CASE 2
            IF DriverCaps.fHasDlgVideoSource THEN capDlgVideoSource(This.hCapWnd)
		CASE 3
            IF DriverCaps.fHasDlgVideoDisplay THEN capDlgVideoDisplay(This.hCapWnd)
		CASE ELSE
            capDlgVideoCompression(This.hCapWnd)
		END SELECT
'       IF WasCapturing THEN This.Capture = True
	END IF
END SUB



SUB SetCapture(TheCaptureFlag AS LONG)
	WITH This
	.Capture = TheCaptureFlag
	IF .Init THEN
		IF .Capture THEN 
			.Capture = capCaptureSequenceNoFile(.hCapWnd)
			IF .Overlay THEN .Overlay = capOverlay(.hCapWnd, True)		'auto turn on Overlay
		ELSE
			IF .Overlay THEN .Overlay = capOverlay(.hCapWnd, False)		'auto turn off Overlay
			capCaptureStop(.hCapWnd)
		END IF
	END IF
	END WITH
END SUB



SUB SetPreview(ThePreviewFlag AS LONG)
	This.Preview = ThePreviewFlag
	IF This.Init THEN 
		IF This.Preview THEN
			capPreview(This.hCapWnd, True)
		ELSE
			capPreview(This.hCapWnd, 0&)
		END IF
	END IF
END SUB




SUB CleanUp
	WITH This
	IF .Init THEN 
		capPreview(.hCapWnd, 0&)
		capSetCallbackOnFrame(.hCapWnd, 0&)	'turn off callback
		capCaptureStop(.hCapWnd)
'		IF .Capture THEN capCaptureStop(.hCapWnd)
		capDriverDisconnect(.hCapWnd)
		DestroyWindow(.hCapWnd)
		.Init = False
	END IF
	END WITH
END SUB






FUNCTION GrabFrameToClipBoard() AS LONG
	DIM i as integer
	DIM T as single
	DIM info AS TBITMAP
	dim rtn as long
	Dim hBitmap as long
	DIM Bitmap1 AS QBITMAP

	capEditCopy(This.hCapWnd)
    IF clipboard.hasformat(CF_BITMAP) then		
      clipboard.open
      hBitmap=clipboard.GetAsHandle(CF_BITMAP)
      clipboard.close
	else
		showmessage "Cliboard is not in a valid format"
	end if

	RESULT = GetObject(Bitmap1.Handle,SIZEOF(info),info)
	RESULT = GetObject(hBitmap,SIZEOF(info),info)
END FUNCTION



FUNCTION SaveFrameToFile(TheFileName AS STRING) AS Long
	DIM TmpStr 	AS STRING

	TmpStr = TheFileName				'RQ does not pass the string pointer to function!!
	capGrabFrameNoStop(This.hCapWnd)
	RESULT = capFileSaveDIB(This.hCapWnd, VARPTR(TmpStr))	' need this to send pointer
END FUNCTION



SUB ReSize(TheForm AS QFORM)
    Dim retVal As LONG
    Dim capStats As CAPSTATUS
    
    'Get the capture window attributes
    retVal = capGetStatus(This.hCapWnd, CapStats, SIZEOF(CapStats))
    If retVal Then
        'Resize the parent form to fit
        Call SetWindowPos(TheForm.Handle, _
                    0&, _
                    0&, _
                    0&, _
                    This.ImageWidth + (TheForm.Width - TheForm.ClientWidth), _
                    This.ImageHeight + (TheForm.Height - TheForm.ClientHeight),_
                    SWP_NOMOVE Or SWP_NOZORDER Or SWP_NOSENDCHANGING)
'        'Resize the capture window to format size
        Call SetWindowPos(This.hCapWnd, _
                    0&, _
                    0&, _
                    0&, _
                    This.ImageWidth, _
                    This.ImageHeight, _
                    SWP_NOMOVE Or SWP_NOZORDER Or SWP_NOSENDCHANGING)
		capPreviewScale(This.hCapWnd, True)
    End If
End Sub



CONSTRUCTOR
	CamNum			= 0
	Left			= 0
	Top				= 0
	Width			= 240
	Height			= 200
	OverLay			= 0
	Init			= 0
    FrameBuffers    = 4
	ImageHeight 	= This.SetImageHeight(This.Height)		'set these by GetStatus
	ImageWidth		= This.SetImageWidth(This.Width)
	Capture 		= 0
	FrameInterval	= 16	'16 ms or about 60 Hz
	FramesDropped	= 0
	Preview			= True		
	Caption			= "video"
	Tag				= 0
	FormStyle		= WS_CHILD OR WS_VISIBLE
END CONSTRUCTOR


END TYPE




SUB AddThisStuff

'	capDriverGetCaps(ghWndCap, &CapDrvCaps, sizeof (CAPDRIVERCAPS))

	' Video source Dialog box
'	if (CapDrvCaps.fHasDlgVideoSource) THEN capDlgVideoSource(ghWndCap)

	' Video format dialog box.
'	if (CapDrvCaps.fHasDlgVideoFormat) THEN capDlgVideoFormat(ghWndCap)


	' Are there new image dimensions?
'	capGetStatus(ghWndCap, &CapStatus, sizeof (CAPSTATUS))

	' If so, notify the parent of a size change.

	' Video source Dialog box
'	if (CapDrvCaps.fHasDlgVideoDisplay THEN capDlgVideoDisplay(ghWndCap)


END SUB
