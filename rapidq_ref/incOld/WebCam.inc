'
'***************************************************************************
' WebCam.dll is a Dynamic Linked Library written by me,
' John White <yoingco@btinternet.com>, for myself and
' any programming language that can utilize it.
' 
' Wrapped up into a custom component by JohnK
'
'***************************************************************************

Declare Function WEBCAM_OpenWindow Lib "webcam.dll" Alias "WEBCAM_OpenWindow" (parentWindow AS LONG) As Long
Declare Function WEBCAM_SetPreviewRate Lib "webcam.dll" Alias "WEBCAM_SetPreviewRate" (milliSecondRate AS LONG) As Long
Declare Function WEBCAM_PreviewOFF Lib "webcam.dll" Alias "WEBCAM_PreviewOFF" () As Long
Declare Function WEBCAM_PreviewON Lib "webcam.dll" Alias "WEBCAM_PreviewON" () As Long
Declare Function WEBCAM_PreviewScalingOFF Lib "webcam.dll" Alias "WEBCAM_PreviewScalingOFF" () As Long
Declare Function WEBCAM_PreviewScalingON Lib "webcam.dll" Alias "WEBCAM_PreviewScalingON" () As Long
Declare Function WEBCAM_OverlayOFF Lib "webcam.dll" Alias "WEBCAM_OverlayOFF" () As Long
Declare Function WEBCAM_OverlayON Lib "webcam.dll" Alias "WEBCAM_OverlayON" () As Long
Declare Function WEBCAM_Connect Lib "webcam.dll" Alias "WEBCAM_Connect" () As Long
Declare Function WEBCAM_IsConnected Lib "webcam.dll" Alias "WEBCAM_IsConnected" () As Long
Declare Function WEBCAM_GetConnectedName Lib "webcam.dll" Alias "WEBCAM_GetConnectedName" () As Long
Declare Function WEBCAM_GetConnectedVersion Lib "webcam.dll" Alias "WEBCAM_GetConnectedVersion" () As Long
Declare Function WEBCAM_CanItOverlay Lib "webcam.dll" Alias "WEBCAM_CanItOverlay" () As Long
Declare Function WEBCAM_GetIDNumber Lib "webcam.dll" Alias "WEBCAM_GetIDNumber" () As Long
Declare Function WEBCAM_Disconnect Lib "webcam.dll" Alias "WEBCAM_Disconnect" () As Long
Declare Function WEBCAM_GetCapabilities Lib "webcam.dll" Alias "WEBCAM_GetCapabilities" () As Long
Declare Function WEBCAM_GetInformation Lib "webcam.dll" Alias "WEBCAM_GetInformation" () As Long
Declare Function OPTION_SetOKMessage Lib "webcam.dll" Alias "OPTION_SetOKMessage" (showHide AS LONG) As Long
Declare Function OPTION_SetCaptureTimer Lib "webcam.dll" Alias "OPTION_SetCaptureTimer" (onOff AS LONG, time AS LONG) As Long
Declare Function OPTION_SetChunkID Lib "webcam.dll" Alias "OPTION_SetChunkID" (id AS LONG, textString AS STRING) As Long
Declare Function WEBCAM_GetCaptureOptions Lib "webcam.dll" Alias "WEBCAM_GetCaptureOptions" () As Long
Declare Function WEBCAM_SetCaptureFilesize Lib "webcam.dll" Alias "WEBCAM_SetCaptureFilesize" (fileSize AS LONG) As Long
Declare Function WEBCAM_SetCaptureFilename Lib "webcam.dll" Alias "WEBCAM_SetCaptureFilename" (fileName AS STRING) As Long
Declare Function WEBCAM_SetSaveFilename Lib "webcam.dll" Alias "WEBCAM_SetSaveFilename" (fileName AS STRING) As Long
Declare Function WEBCAM_GetCaptureStatus Lib "webcam.dll" Alias "WEBCAM_GetCaptureStatus" () As Long
Declare Function STATUS_GetImageWidth Lib "webcam.dll" Alias "STATUS_GetImageWidth" () As Long
Declare Function STATUS_GetImageHeight Lib "webcam.dll" Alias "STATUS_GetImageHeight" () As Long
Declare Function STATUS_IsPreviewON Lib "webcam.dll" Alias "STATUS_IsPreviewON" () As Long
Declare Function STATUS_IsOverlayON Lib "webcam.dll" Alias "STATUS_IsOverlayON" () As Long
Declare Function STATUS_IsPreviewScalingON Lib "webcam.dll" Alias "STATUS_IsPreviewScalingON" () As Long
Declare Function STATUS_IsUsingDefaultPalette Lib "webcam.dll" Alias "STATUS_IsUsingDefaultPalette" () As Long
Declare Function STATUS_IsAudioInstalled Lib "webcam.dll" Alias "STATUS_IsAudioInstalled" () As Long
Declare Function STATUS_DoesCaptureFileExist Lib "webcam.dll" Alias "STATUS_DoesCaptureFileExist" () As Long
Declare Function STATUS_IsCapturingNow Lib "webcam.dll" Alias "STATUS_IsCapturingNow" () As Long
Declare Function WEBCAM_StartCapturing Lib "webcam.dll" Alias "WEBCAM_StartCapturing" () As Long
Declare Function WEBCAM_StopCapturing Lib "webcam.dll" Alias "WEBCAM_StopCapturing" () As Long
Declare Function WEBCAM_AbortCapturing Lib "webcam.dll" Alias "WEBCAM_AbortCapturing" () As Long
Declare Function FRAME_Freeze Lib "webcam.dll" Alias "FRAME_Freeze" () As Long
Declare Function FRAME_Grab Lib "webcam.dll" Alias "FRAME_Grab" () As Long
Declare Function FRAME_CopyToClipboard Lib "webcam.dll" Alias "FRAME_CopyToClipboard" () As Long
Declare Function FRAME_CopyToDIB Lib "webcam.dll" Alias "FRAME_CopyToDIB" (fileName AS STRING) As Long
Declare Function PALETTE_FileToWebcam Lib "webcam.dll" Alias "PALETTE_FileToWebcam" (fileName AS STRING) As Long
Declare Function PALETTE_ClipboardToWebcam Lib "webcam.dll" Alias "PALETTE_ClipboardToWebcam" () As Long
Declare Function PALETTE_ManualCreate Lib "webcam.dll" Alias "PALETTE_ManualCreate" (createSend AS LONG, sampleColours AS LONG) As Long
Declare Function PALETTE_AutoCreate Lib "webcam.dll" Alias "PALETTE_AutoCreate" (sampleFrames AS LONG, sampleColours AS LONG) As Long
Declare Function PALETTE_SaveAsFile Lib "webcam.dll" Alias "PALETTE_SaveAsFile" (fileName AS STRING) As Long
Declare Function DIALOG_VideoCompression Lib "webcam.dll" Alias "DIALOG_VideoCompression" () As Long
Declare Function DIALOG_VideoDisplay Lib "webcam.dll" Alias "DIALOG_VideoDisplay" () As Long
Declare Function DIALOG_VideoFormat Lib "webcam.dll" Alias "DIALOG_VideoFormat" () As Long
Declare Function DIALOG_VideoSource Lib "webcam.dll" Alias "DIALOG_VideoSource" () As Long
Declare Function WEBCAM_CloseWindow Lib "webcam.dll" Alias "WEBCAM_CloseWindow" () As Long

DEFLNG WebCamDLLPresent = 0		'signal the WebCam DLL is present
WEBCAM_AbortCapturing			'need to invoke at least one call to load the library
WebCamDLLPresent = LIBRARYINST("webcam.dll")		'now check it is present
IF WebCamDLLPresent = 0 THEN
		ShowMessage "webCam.DLL not found, video capture disabled"
END IF


CONST CREATE_PALETTE=1
CONST PALETTE_TO_WEBCAM=0


DECLARE SUB OnFrame_EventTemplate(hCapWnd AS LONG, lpVHdr AS LONG)'VIDEOHDR)' AS LONG


TYPE QWebCam EXTENDS QOBJECT

PUBLIC:
	ImageHeight	AS LONG
	ImageWidth	AS LONG
	FramesDropped  AS LONG
	Preview		AS LONG
	Tag			AS LONG		'for createWindow function
	sts 		AS BYTE		'status flag
    OnFrame 	AS LONG		'doesnt work ->EVENT(OnFrame_EventTemplate)

CONSTRUCTOR
	ImageHeight = 0		'set these by GetStatus
	ImageWidth	= 0
	FramesDropped = 0
	Preview		= True		
	Tag			= 0
	sts			= 0
END CONSTRUCTOR



FUNCTION CamInit(Form AS QFORM) AS LONG			'Create Cap Window, init the web cam
	DIM rtn AS LONG

	IF This.sts THEN EXIT FUNCTION		'been here before? Then don't run
	IF WebCamDLLPresent THEN
		rtn=WEBCAM_OpenWindow(Form.Handle)	'Open Capture (Child) Window for WebCam
		IF rtn THEN
			This.sts = 1					'status code 1 = window open
			rtn=WEBCAM_Connect				'Connect the WebCam Driver.
		END IF
		IF rtn=1 THEN
	 		WEBCAM_GetCapabilities			'These next two calls MUST be called,
			WEBCAM_GetCaptureOptions		'otherwise the WebCam will not work properly
			rtn=WEBCAM_IsConnected			'Check if WebCam connected to its Driver.
		END IF
		IF rtn=1 THEN
			This.sts=2
			WEBCAM_SetPreviewRate(1)
			rtn=WEBCAM_CanItOverlay 	'can WebCam support Direct Hardware mode or use software emulation
			IF rtn=1 THEN
				WEBCAM_OverlayON		'Overlay automatically turns of preview mode
				This.sts=4
			ELSE
				WEBCAM_PreviewON		'WEBCAM_PreviewScalingON
				This.sts=3
			END IF
		END IF
		IF rtn = 0 THEN ShowMessage("Could not connect to Camera")
		RESULT = rtn
END FUNCTION




SUB ShowDialogBox(TheBoxNum)		'get info button
	IF WebCamDLLPresent THEN
		IF TheBoxNum THEN WEBCAM_StopCapturing
		SELECT CASE TheBoxNum
		CASE 1
			DIALOG_VideoCompression
		CASE 2
			DIALOG_VideoDisplay
		CASE 3
			DIALOG_VideoFormat
		CASE 4
			DIALOG_VideoSource
		END SELECT
	END IF
END SUB


SUB StartCapture
	IF  STATUS_IsCapturingNow THEN EXIT SUB
	WEBCAM_StartCapturing
	IF WEBCAM_CanItOverlay THEN	WEBCAM_OverlayON
END SUB

SUB PreviewOff
	WEBCAM_PreviewScalingOFF
	WEBCAM_PreviewOFF
END SUB

SUB PreviewOn
	WEBCAM_PreviewON
END SUB


SUB StopCapture
	IF STATUS_IsCapturingNow THEN
	    This.PreviewOff
		WEBCAM_StopCapturing
	END IF
END SUB


SUB CleanUp
	IF This.sts=4 THEN WEBCAM_OverlayOFF
	IF This.sts=3 THEN WEBCAM_PreviewOFF
	IF This.sts>1 THEN WEBCAM_Disconnect
	IF This.sts>0 THEN WEBCAM_CloseWindow
END SUB


SUB SelectSource
	DIALOG_VideoSource
END SUB

FUNCTION GrabFrameToClipBoard() AS LONG
	DIM i as integer
	DIM T as single
	DIM info AS TBITMAP
	dim rtn as long
	Dim hBitmap as long
	DIM Bitmap1 AS QBITMAP

	This.PreviewOFF
	FRAME_Grab					'slow, about7.5 hz
	FRAME_CopyToClipboard		'fast

    IF clipboard.hasformat(CF_BITMAP) then		
      clipboard.open
      hBitmap=clipboard.GetAsHandle(CF_BITMAP)
      clipboard.close
	else
		showmessage "Clipboard is not in a valid format"
	end if

	RESULT = GetObject(Bitmap1.Handle,SIZEOF(info),info)
	RESULT = GetObject(hBitmap,SIZEOF(info),info)
	This.PreviewON
END FUNCTION



FUNCTION CopyFrameToFile(TheFileName AS STRING) AS LONG
	This.PreviewOFF
	FRAME_Grab					'slow, about7.5 hz
	RESULT = FRAME_CopyToDIB(TheFileName) ' Save with/out an extension (.jpg, etc)
END FUNCTION


END TYPE
