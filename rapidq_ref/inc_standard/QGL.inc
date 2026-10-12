'Open GL wrapper, alpha release 1.0, JohnK, lots of help from FreeBasic Developers, and of course SGI


$IFNDEF __GL_inc
    $INCLUDE <\GL\gl.inc>
    $INCLUDE <GL\glu.inc>
$ENDIF

$IFNDEF __glwgl_inc
    declare function wglCreateContext lib "opengl32" alias "wglCreateContext" (BYVAL dw1 as long) as long
    declare sub wglDeleteContext lib "opengl32" alias "wglDeleteContext"(BYVAL dw1 as long)
    declare sub wglMakeCurrent lib "opengl32" alias "wglMakeCurrent"(BYVAL dw1 as long, BYVAL dw2 as long)
$ENDIF


$IFNDEF __WIN32API
' pixel builder
type PIXELFORMATDESCRIPTOR
     nSize           as word
     nVersion        as word
     dwFlags         as dword
     iPixelType      As Byte
     cColorBits      As Byte
     cRedBits        As Byte
     cRedShift       As Byte
     cGreenBits      As Byte
     cGreenShift     As Byte
     cBlueBits       As Byte
     cBlueShift      As Byte
     cAlphaBits      As Byte
     cAlphaShift     As Byte
     cAccumBits      As Byte
     cAccumRedBits   As Byte
     cAccumGreenBits As Byte
     cAccumBlueBits  As Byte
     cAccumAlphaBits As Byte
     cDepthBits      As Byte
     cStencilBits    As Byte
     cAuxBuffers     As Byte
     iLayerType      As Byte
     bReserved       As Byte
     dwLayerMask     as dword
     dwVisibleMask   as dword
     dwDamageMask    as dword
end type


' import gdi32.dll
declare function ChoosePixelFormat lib "gdi32" alias  "ChoosePixelFormat" (BYVAL dw1 as long, dw2 as PIXELFORMATDESCRIPTOR) as long
Declare Function SetPixelFormat Lib "gdi32" Alias "SetPixelFormat" (ByVal hDC As Long, ByVal n As Long, pcPixelFormatDescriptor As PIXELFORMATDESCRIPTOR) As Long
Declare Function SwapBuffers Lib "gdi32" Alias "SwapBuffers" (ByVal hDC As Long) As Long


  $IFNDEF __RQINC2					'rapidQ2 includes
    ' import user32.dll
    declare function GetDC lib "user32" alias "GetDC" (BYVAL dw1 as long) as long
    declare sub ReleaseDC lib "user32" alias "ReleaseDC" (BYVAL dw1 as long, BYVAL dw2 as long)
  $ENDIF   'rapidQ2.inc
$ENDIF   'windows inc

$DEFINE PFD_MAIN_PLANE      0
$DEFINE PFD_TYPE_RGBA       0
$DEFINE PFD_DOUBLEBUFFER    1
$DEFINE PFD_DRAW_TO_WINDOW  4
$DEFINE PFD_SUPPORT_OPENGL  &H20
$DEFINE PFD_DRAW_TO_BITMAP  &H00000008
$DEFINE PFD_SUPPORT_GDI     &H00000010
$DEFINE PFD_GENERIC_ACCELERATED     &H00001000
$DEFINE PFD_SUPPORT_DIRECTDRAW      &H00002000


'===========  The main object now... ===================

DIM QGLinternalBMP AS QBITMAPEX

TYPE QGL EXTENDS QOBJECT
  PRIVATE:
	OrigWidth 		AS INTEGER
	OrigHeight		AS INTEGER
    ParentHandle    AS LONG
    FPSTimer        AS QTIMER       'periodic update of Frames/sec
    FrameCount      AS DWORD        'this keeps track of Frames for FPS

  PUBLIC:
    RenderToBitMap  AS INTEGER      PROPERTY SET Set_RenderToBitmap
    Bitmap          AS QBITMAP      'for rendering to a bmp
    Width           AS INTEGER
    Height          AS INTEGER
    Front           AS GLdouble     'front and back clipping planes
    Back            AS GLdouble
	MipMap 			AS INTEGER
	FullScreen 		AS INTEGER  PROPERTY SET Set_FullScreen
	hDC 			AS LONG			'handle to device context (DC) in the parent window
    hBMP            AS LONG         'handle to BMP (device context handle)
	hglRC			AS LONG			'OpenGL specific -- rendering context (like a handle to DC)
    hGLRC_bmp          AS LONG         'OpenGL rendering context to bitmap
                                    'a rendering context is like a windows DC fix for OpenGL
    bpp             AS INTEGER      'bits per pixel of screen
    DepthBits       AS INTEGER
    StencilBits     AS INTEGER      'set the depth, stencil, and accum bit resolutions
    AccumBits       AS INTEGER      '
    FrameRate       AS SINGLE
    FOV             AS DOUBLE       'field of view
    AspectRatio     AS DOUBLE
    FogEnabled      AS INTEGER      PROPERTY SET Set_FogEnabled
    FogMode         AS INTEGER      PROPERTY SET Set_FogMode

'**************************************************************************
' Set OpenGL viewport using width and height of GL form  -- our drawing boundries
'**************************************************************************

SUB ReSize(width AS INTEGER, height AS INTEGER)        'adjusts the viewport onResize
    IF height > 0 THEN 
        QGL.Height = height            'Prevent Divide By Zero error
        IF width > 0 THEN 
            QGL.width = width
            glViewport(0,0, width, height)   'viewport doesn't have to be whole form
        END IF
    END IF
'  *********   Calculate The Aspect Ratio Of The Window  ****************
	' The parameters are (view angle, aspect ration of the width to the height,closest camera distance before clipping
	' FOV deg in y-direction /Aspect Ratio =FOV in x-direction/ dist to Near clipping plane/ dist to far clipping Plane

	glMatrixMode GL_PROJECTION                     '' Select The Projection Matrix
	glLoadIdentity                                 '' Reset The Projection Matrix
	gluPerspective(QGL.FOV, (QGL.AspectRatio * width/height), QGL.Front, QGL.Back)
    glMatrixMode (GL_MODELVIEW)
END SUB




'**************************************************************************************************
'initalize the interface to windows:  
'   Run this at the Form.OnShow event and pass the Qform that will be drawn
'****************************************************************************************************
' 

FUNCTION Init(MainForm AS QFORM) AS INTEGER
    DIM pf 			AS PIXELFORMATDESCRIPTOR
	DIM Hresult		AS LONG

    RESULT = 0                              'returns TRUE on suceed
    QGL.ParentHandle = MainForm.Handle      'store this for closing
    IF QGL.Width = 0 THEN QGL.Width = MainForm.ClientWidth
    IF QGL.Height = 0 THEN QGL.Height = MainForm.ClientHeight
	QGL.hDC = GetDC(MainForm.Handle)		'global DC,don't free this hdc until the end of our program
    pf.nSize = SIZEOF(pf)
    pf.nVersion = 1
    pf.dwFlags = PFD_DRAW_TO_WINDOW OR _
                 PFD_SUPPORT_OPENGL OR _
                 PFD_DOUBLEBUFFER OR _              'don't add PFD_USE_GDI
                 PFD_GENERIC_ACCELERATED            'last flag probably won't work
    pf.dwLayerMask = PFD_MAIN_PLANE
    pf.iPixelType = PFD_TYPE_RGBA					'RGB and Alpha pixel type
	'color bitplanes in each color buffer. For RGBA pixel = size of the color buffer excluding the alpha
    IF QGL.bpp < 32 THEN pf.cColorBits = 24 ELSE  pf.cColorBits = QGL.bpp
    pf.cDepthBits = QGL.DepthBits           'Depthbits is ignored for RGBA, but we do it anyway		
    pf.cAccumBits = QGL.AccumBits           'No special bitplanes needed
    pf.cStencilBits = QGL.stencilBits
    pf.iLayerType = PFD_MAIN_PLANE

    Hresult = ChoosePixelFormat(QGL.hDC, pf)
    IF Hresult = 0 THEN	EXIT FUNCTION               'pixel format failed
    IF SetPixelFormat(QGL.hDC, Hresult, pf) = 0 THEN EXIT FUNCTION
    QGL.hglRC = wglCreateContext(QGL.hDC)			'create a rendering context from our hdc
    wglMakeCurrent (QGL.hDC, QGL.hglRC)				'make it the one drawn on
    RESULT = QGL.hDC
END FUNCTION



PROPERTY SET Set_RenderToBitmap(TheState AS INTEGER)
    DIM pf 			AS PIXELFORMATDESCRIPTOR
	DIM Hresult		AS LONG

    IF TheState = False THEN
    	IF QGL.hGLRC_bmp THEN 
  		    wglMakeCurrent (QGL.hDC, QGL.hglRC)
    		wglDeleteContext QGL.hGLRC_bmp
            QGL.Bitmap.Width = 0        'deallocate mem!
            QGL.Bitmap.Height = 0
        END IF
    ELSE
        IF QGL.Bitmap.Width = 0 THEN 
            QGL.Bitmap.Width = QGL.Width
            QGL.Bitmap.Height = QGL.Height
            IF QGL.bpp = 32 THEN 
                QGL.Bitmap.PixelFormat = pf32Bit 
            ELSE 
                QGL.bpp = 24
                QGL.Bitmap.PixelFormat = pf24Bit        'only support 24 bit or higher
            END IF
        END IF
        pf.nSize = SIZEOF(pf):              pf.nVersion = 1
        pf.dwFlags = PFD_SUPPORT_OPENGL OR _
                     PFD_SUPPORT_GDI OR _
                     PFD_DRAW_TO_BITMAP OR _
                     PFD_GENERIC_ACCELERATED            'last flag probably won't work
        pf.iPixelType = PFD_TYPE_RGBA					'RGB and Alpha pixel type
    	'color bitplanes in each color buffer. For RGBA pixel = size of the color buffer excluding the alpha
        pf.cColorBits = QGL.bpp
        pf.cDepthBits = QGL.DepthBits           'Depthbits is ignored for RGBA, but we do it anyway		
        pf.cAccumBits = QGL.AccumBits           'No special bitplanes needed
        pf.cStencilBits = QGL.stencilBits
        pf.iLayerType = PFD_MAIN_PLANE
        pf.dwLayerMask = PFD_MAIN_PLANE
    
        QGL.hBMP = QGL.Bitmap.handle
        Hresult = ChoosePixelFormat(QGL.hBMP, pf)
        IF (Hresult = 0) THEN
            Showmessage "Render to Bitmap Failed"        'pixel format failed
        ELSE
            IF SetPixelFormat(QGL.hBMP, Hresult, pf) <> 0 THEN
                QGL.hGLRC_bmp = wglCreateContext(QGL.hBMP)		'create a rendering context from bitmap handle
                wglMakeCurrent (QGL.hBMP, QGL.hGLRC_bmp)	     'set up a DIB context for openGL screen
            END IF
        END IF
    END IF
    QGL.RenderToBitmap = TheState
END PROPERTY



'**************************************************************************
'   Properly exit from the program and release device context (DC)
'   only at program end.
'**************************************************************************

SUB Close()       'must run at end to free resources
    IF QGL.FullScreen THEN
    	QGL.bpp = Screen.GetPixelDepth
    	Screen.SetResolution(QGL.OrigWidth, QGL.OrigHeight, QGL.bpp, 0)
    END IF

	IF QGL.hGLRC_bmp THEN 
		wglDeleteContext QGL.hGLRC_bmp
    END IF

	IF QGL.hglRC THEN 
		wglMakeCurrent 0, 0
		wglDeleteContext QGL.hglRC
        IF QGL.hDC THEN ReleaseDC QGL.ParentHandle, QGL.hDC
    END IF
END SUB


SUB Flip
    SwapBuffers QGL.hDC                   ' flip the screen | inc2026: QGL.hDC вместо GL.hDC: внутри TYPE QGL к своим полям везде обращение через QGL. (строки 147, 243); GL - имя переменной программы, работало только при DIM GL AS QGL (c_qgl.html, Notes)
    QGL.FrameCount++
    IF QGL.FrameCount > 32767 THEN QGL.FrameCount = 1
END SUB


PROPERTY SET Set_FullScreen(GoFull AS INTEGER)
    IF QGL.Width > 319 AND QGL.Height > 239 THEN
	IF GoFull = True THEN
    	QGL.bpp = Screen.GetPixelDepth
       	IF Screen.SetResolution(QGL.Width, QGL.Height, QGL.bpp, 0) <> DISP_CHANGE_SUCCESSFUL THEN    'failed, menus, statusbar...
          SELECT CASE QGL.Width
               CASE IS < 641
                   Screen.SetResolution(640, 480, QGL.bpp, 0)
               CASE IS < 801 ' inc2026: CASE IS < вместо CASE <: сравнение в CASE по документации через IS (conditions.html), как в строке 261; CASE > 5 без IS RapidQ не считает сравнением (тест в RAPIDQ_RULES.md)
                   Screen.SetResolution(800, 600, QGL.bpp, 0)
               CASE ELSE
                   Screen.SetResolution(1024, 768, QGL.bpp, 0)
           END SELECT
        END IF
    ELSE
    	QGL.bpp = Screen.GetPixelDepth
    	Screen.SetResolution(QGL.OrigWidth, QGL.OrigHeight, QGL.bpp, 0)
	END IF
   	QGL.FullScreen = GoFull
    END IF
END PROPERTY




PRIVATE:
FUNCTION GL_GenerateTexture() AS LONG
	DIM tex AS GLuint
    DIM ClrBits AS GLint
	DIM format AS GLenum
    DIM NotBMP  As INTEGER

    RESULT = 0 
	'texture ok size?, powers of 2?
	IF(QGLinternalBMP.Width < 2) OR (QGLinternalBMP.Height < 2) THEN EXIT FUNCTION
'	IF(QGLinternalBMP.Width AND (QGLinternalBMP.Width-1)) OR _
'      (QGLinternalBMP.Height AND (QGLinternalBMP.Height-1)) THEN EXIT FUNCTION

	'generate and bind the texture, openGl keeps track
	glGenTextures 1, tex
	glBindTexture GL_TEXTURE_2D, tex
	'' Swap R and B so we can use the GL_RGBA texture format?
    SELECT CASE QGLinternalBMP.PixelFormat 
        CASE pf32Bit
            ClrBits = 4
            format = GL_BGRA            'typical GL_RGBA  but we are in windows
        CASE pf24bit
            ClrBits = 3
            format = GL_BGR             'typical GL_RGB but we are in windows
        CASE pf16bit
            QGLinternalBMP.PixelFormat = pf24bit
            ClrBits = 3
            format = GL_BGR             'typical GL_RGB but we are in windows
        CASE pf8bit                     'only 24 bit supported...
'            ClrBits = 1
'            format = GL_COLOR_INDEX
            QGLinternalBMP.PixelFormat = pf24bit
            ClrBits = 3
            format = GL_BGR             'typical GL_RGB but we are in windows
    END SELECT

	IF QGL.MipMap THEN
'     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT)
'     glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT)

		gluBuild2DMipmaps(GL_TEXTURE_2D, ClrBits,_
				QGLinternalBMP.Width, QGLinternalBMP.Height,_
				format,GL_UNSIGNED_BYTE,_
				QGLinternalBMP.Pointer)

    	glTexParameteri GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, QGL.MipMap
    	glTexParameteri GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR     'choose better option
    ELSE
        glTexImage2D(GL_TEXTURE_2D, 0, ClrBits,_
				QGLinternalBMP.Width, QGLinternalBMP.Height,_
				0, format, GL_UNSIGNED_BYTE,_
				QGLinternalBMP.Pointer)
        glTexParameteri GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST      'GL_LINEAR is smoother but slower
        glTexParameteri GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST
    END IF

	RESULT = tex
END FUNCTION


PUBLIC:

FUNCTION CreateTextureFromFile(ImgFileName as string) AS LONG
    RESULT = 0 
	IF FILEEXISTS(ImgFileName) = False THEN	EXIT FUNCTION
    IF INSTR(UCASE$(ImgFileName), ".JPG") OR _
       INSTR(UCASE$(ImgFileName), ".TGA") OR _
       INSTR(UCASE$(ImgFileName), ".GIF") OR _
       INSTR(UCASE$(ImgFileName), ".PCX") AND NViewLibPresent THEN
        	QGLinternalBMP.LoadOtherImage(ImgFileName, 0,"")
    ELSE
        	QGLinternalBMP.LoadFromFile(ImgFileName)
    END IF
    RESULT = QGL.GL_GenerateTexture
END FUNCTION


FUNCTION CreateTextureFromBitMap(ImgBMP as QBITMAP) AS LONG
    RESULT = 0 
	IF ImgBMP.Width > 1 AND ImgBMP.Height > 1 THEN 
        QGLinternalBMP.Width = ImgBMP.Width
        QGLinternalBMP.Height = ImgBMP.Height
        QGLinternalBMP.PixelFormat = ImgBMP.PixelFormat
        QGLinternalBMP.Draw(0, 0, ImgBMP.BMP)
        RESULT = QGL.GL_GenerateTexture
    END IF
END FUNCTION



'*********  Fog property, affects whole scene  *******************
PROPERTY SET Set_FogEnabled(theState AS INTEGER)
    IF theState THEN glEnable(GL_FOG) ELSE glDisable(GL_FOG)
    QGL.FogEnabled = theState
END PROPERTY

PROPERTY SET Set_FogMode(theMode AS INTEGER)
 	glFogi GL_FOG_MODE, theMode                       ' Mode = GL_LINEAR, GL_EXP, GL_EXP2
    QGL.FogMode = theMode
END PROPERTY

SUB FogColor(R#, G#, B#)
    DEFSNG fogColor(0 to 3) = {R#, G#,B#, 1.0}         '' Fog Color, alpha always 1?
 	glFogfv GL_FOG_COLOR, fogColor(0)                  '' Set Fog Color
END SUB

SUB SetFogParams (Start#, End#, Density#) 
 	glFogf GL_FOG_DENSITY, Density#                    '' How Dense Will The Fog Be
 	glHint GL_FOG_HINT, GL_DONT_CARE                   '' Fog Hint Value
 	glFogf GL_FOG_START, Start#                        '' Fog Start Depth
 	glFogf GL_FOG_END, End#                            '' Fog End Depth
END SUB




PRIVATE:

SUB FPSTimerOver        'this keeps track of Frames/sec
    QGL.FrameRate = QGL.FrameCount  '/QGL.FPSTimer.Interval, which is 1 sec
    QGL.FrameCount = 0
END SUB


CONSTRUCTOR
    hDC         = 0
    hglRC       = 0
    hBMP        = 0
    hGLRC_bmp   = 0
	FullScreen = False
	OrigWidth = Screen.Width
	OrigHeight = Screen.Height
    bpp         = 24
    DepthBits   = 8
    StencilBits = 16
    AccumBits   = 0
    Front       = 0.1
    Back        = 500.0
    FOV         = 60.0
    AspectRatio = 1.0       'equal width/height ratio in scaling
    FPSTimer.Enabled = True
    FPSTimer.OnTimer = QGL.FPSTimerOver
    FPSTimer.Interval = 1000
    FogEnabled  = False
    FogMode     = GL_EXP
END CONSTRUCTOR
			 
END TYPE



'**************************************************************
'**************************************************************
'           MD2 (quake) animations
'**************************************************************
'**************************************************************


TYPE MD2Header                               ' file Header data
   ident            AS INTEGER
   version          AS INTEGER
   skinwidth        AS INTEGER                  ' Width of skin texture (pixels)
   skinheight       AS INTEGER                  ' Height of skin texture (pixels)
   framesize        AS INTEGER
    ' Number of different components
   num_skins        AS INTEGER                   ' Skins
   num_xyz          AS INTEGER                   ' Vertices (x, y, z)
   num_st           AS INTEGER                   ' Texture coordinates (s, t)
   num_tris         AS INTEGER                   ' Triangles
   num_glcmds       AS INTEGER                   ' GL Commands (which we aren't going to use)
   num_frames       AS INTEGER                   ' Frames (transform matrices)
    ' File offset of different components
   ofs_skins        AS INTEGER                   ' Skins
   ofs_st           AS INTEGER                   ' Texture coordinates (s,t)
   ofs_tris         AS INTEGER                   ' Triangles
   ofs_frames       AS INTEGER                   ' Frames
   ofs_glcmds       AS INTEGER                   ' GL Commands (which we aren't going to use)
   ofs_end          AS INTEGER                   ' End of file
END TYPE


' 'These values are set at the max allowed MD2 specs, or dynamically allocate these after loading
$DEFINE MD2_MAX_VERTICES 1024   '2048
$DEFINE MD2_MAX_TRIANGLES 2048  '4096
$DEFINE MD2_MAX_FRAMES 256      '512
$DEFINE MD2_MAX_TEXT_COORD 1024 '2048
$DEFINE MD2_MAX_ANIMATIONS 1024


TYPE QMD2model EXTENDS QMEMORYSTREAM
    TheModel                                     AS MD2Header
    vertex(MD2_MAX_FRAMES, MD2_MAX_VERTICES, 2)  AS BYTE         'each byte is rescaled by Frame
    normal(MD2_MAX_FRAMES, MD2_MAX_VERTICES)     AS BYTE        'index into table of normal 
    TexCoord(MD2_MAX_TEXT_COORD, 1)              AS SINGLE      'actual values in SHORT
    indexXYZ(MD2_MAX_TRIANGLES, 2)               AS SHORT       'index to which vertex
    indexST(MD2_MAX_TRIANGLES, 2)                AS SHORT       'index for texture coord
    Frame_Scale(MD2_MAX_FRAMES, 2)               AS SINGLE
    Frame_Translate(MD2_MAX_FRAMES, 2)           AS SINGLE
    Frame_Name(MD2_MAX_FRAMES)                   AS STRING * 16
    skins(32)                                    AS GLint       'texture ID's for OpenGL bindTexture
    'individual render frame specific
    StartFrame                                   AS INTEGER
    CurrentFrame                                 AS INTEGER     'for updating animation
    MaxFrame                                     AS INTEGER     'of single frames
    'animation list specific
    AnimationFrame(MD2_MAX_ANIMATIONS)           AS GLint       'array of Displaylist handles
    MaxAnimationFrame                            AS INTEGER     'highest display List index
    KeyFrame(MD2_MAX_FRAMES)                     AS SHORT       'special locations in animation 
    KeyFrameIndex                                AS SHORT
    'fluffy stuff
    Position                                     AS QD3DVECTOR  'set our 3D position
    Rotation                                     As QD3DVECTOR  'set the rotation angle in degs for each axis
    Scale                                        As QD3DVECTOR  'set scaling for each axis
    hDC                                          AS LONG        'set handle for device context for auto flipping

    'frames per second counters
    FPSTimer             AS QTIMER                                'do background timing
    FPS                  AS SINGLE  PROPERTY SET MD2_Set_FPS      'animation can be too fast
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' Functions
''''''''''''''''''''''
' LoadMD2 model, Input:  a MD2 Header structure, this allows multiple 3D objects

SUB LoadMD2File (TheFileName AS STRING)
    DIM theFileDir$         AS STRING
    DIM TheFile             AS QFILESTREAM
    DIM i                   AS INTEGER
    DIM j                   AS INTEGER
    DIM TempStr             AS STRING
    DIM OpenDialog 		    AS QOPENDIALOG		'open file dialog

    IF TheFileName = "" THEN
	openDialog.Caption = "select a Quake model "
    openDialog.filter = "*.MD2 (quake)|*.MD2"
        IF openDialog.execute THEN
    		theFileDir$ = OpenDialog.InitialDir	
    		theFileName = UCASE$(OpenDialog.FileName)
    	END IF
    END IF

    ' Open file, if it exists then load it up
    IF FILEEXISTS(theFileDir$ + theFileName) THEN
        TheFile.Open(theFileDir$ + theFileName, fmOpenRead)
    ELSE
        ShowMessage "Failed to open " + TheFileName
        EXIT SUB            'be sure to compile with the latest fixed libs
    END IF

    TheFile.ReadUDT(This.TheModel)

WITH THIS
    '-------------------------------------------------------------
    'load the 'skins', which are texures from bitmap files
    '-------------------------------------------------------------
'    REDIM SMD2_skins(TheModel.num_skins)           'crashes
    IF .TheModel.num_skins > 0 THEN
    TheFile.Seek(.TheModel.ofs_skins, soFromBeginning)   'position in the file with offset in .TheModel.ofs_skins | inc2026: Seek(смещение, откуда): по документации QFILESTREAM.Seek (Position%, From%) (qfilestream.html) - аргументы были переставлены
         for i = 0 to .TheModel.num_skins - 1                    ' Load all texture files
             TempStr = TheFile.ReadStr(64)                      ' Read texture name
             TempStr = RTRIM$(REPLACESUBSTR$(TempStr, "/","\"))       'condition it
             TempStr = LEFT$(TempStr,INSTR(TempStr, CHR$(0))-1)
            IF FileExists(theFileDir$ + tempStr) = False THEN
                theFileDir$ = ""                                'not in directory
                IF FileExists(tempStr) = False THEN
                    tempStr = LEFT$(TheFileName, INSTR(TheFileName, ".MD2")-1) + ".bmp"  'next shot
                IF FileExists(tempStr) = False THEN
                    tempStr = LEFT$(tempStr, INSTR(tempStr, ".bmp")-1) + ".jpg"  'last shot
                END IF
                END IF
            END IF
            This.skins(i) = GL.CreateTextureFromFile(theFileDir$ + tempStr)  'Load texture
            if This.skins(i) = 0 then
             ShowMessage "Failed to load texture: " + theFileDir$ + tempStr
'                 end
             end if
         next i
     ELSE
         tempStr = LEFT$(TheFileName, INSTR(TheFileName, ".MD2")-1) + ".bmp"  'next shot
         This.skins(0) =  GL.CreateTextureFromFile(tempStr)
     END IF

    '-------------------------------------------------------------
    'get Texture coordinates (s, t)
    '-------------------------------------------------------------
    IF .TheModel.num_st > MD2_MAX_TEXT_COORD THEN         Showmessage "Err: Too many tex coords"
    TheFile.Seek(.TheModel.ofs_st, soFromBeginning)      ' Seek to texture coordinates | inc2026: Seek(смещение, откуда): по документации QFILESTREAM.Seek (Position%, From%) (qfilestream.html) - аргументы были переставлены
    for i = 0 to .TheModel.num_st - 1
        This.TexCoord(i, 0) = (TheFile.ReadNum(num_WORD))/(1.0* QGLinternalBMP.Width)
        This.TexCoord(i, 1) = (TheFile.ReadNum(num_WORD))/(-1.0 * QGLinternalBMP.Height)
    next i

    '-------------------------------------------------------------
    'get model triangles, indexes to all vertices
    '-------------------------------------------------------------
    IF .TheModel.num_tris > MD2_MAX_TRIANGLES THEN Showmessage "Err: Too many triangles"
    TheFile.Seek(.TheModel.ofs_tris, soFromBeginning)           ' Seek to triangles | inc2026: Seek(смещение, откуда): по документации QFILESTREAM.Seek (Position%, From%) (qfilestream.html) - аргументы были переставлены
    for i = 0 to .TheModel.num_tris - 1          ' Load triangles
        TheFile.LoadArray(This.indexXYZ(i, 0), 3)
        TheFile.LoadArray(This.indexST(i, 0), 3)
    next i

    '-------------------------------------------------------------
    'get model frames, which are basically 4x4 matrices and all their vertices & normals
    '-------------------------------------------------------------
    IF .TheModel.num_frames > MD2_MAX_FRAMES THEN 
        Showmessage "Err: Too many frames"
        .MaxFrame = MD2_MAX_FRAMES
    ELSE
        .MaxFrame = .TheModel.num_frames
    END IF

    IF .TheModel.num_xyz > MD2_MAX_VERTICES THEN Showmessage "Err: Too many verts"
    TempStr = ""
    TheFile.Seek(.TheModel.ofs_frames, soFromBeginning)         ' Seek to frames | inc2026: Seek(смещение, откуда): по документации QFILESTREAM.Seek (Position%, From%) (qfilestream.html) - аргументы были переставлены
    for i = 0 to .TheModel.num_frames - 1                        ' Load each animation frame
        TheFile.LoadArray(This.Frame_Scale(i,0), 3)
        TheFile.LoadArray(This.Frame_Translate(i,0), 3)
        .Frame_Name(i)= TheFile.ReadStr(16)             'a char string with terminating 0's
        .Frame_Name(i)= LTRIM$(RTRIM$((LEFT$(This.Frame_Name(i), INSTR(This.Frame_Name(i), CHR$(0))-1))))    'trim off zero chars

        IF TempStr <> LEFT$(This.Frame_Name(i), 3) THEN
            TempStr = LEFT$(This.Frame_Name(i),3)
'        IF TempStr <> This.Frame_Name(i) - STR$(VAL(This.Frame_Name(i))) THEN
'            TempStr = This.Frame_Name(i) - STR$(VAL(This.Frame_Name(i)))
            .KeyFrameIndex++
            .KeyFrame(.KeyFrameIndex) = i                   'keep track of unique frames by name
        END IF

        FOR j = 0 to .TheModel.num_xyz - 1                   ' Read vertices
            TheFile.LoadArray(This.vertex(i,j,0) ,3)         'get 3D coord of vertices
            TheFile.LoadArray(This.normal(i,j) ,  1)         'an indexes to normal table
        NEXT j
    next i
    TheFile.Close
END WITH

END SUB


PRIVATE:

SUB DoTransformations
    WITH THIS
    IF (.Scale.x <> 1.0) OR (.Scale.y <> 1.0) OR (.Scale.z <> 1.0) THEN
        glScalef(This.Scale.x, This.Scale.y, This.Scale.z)
    END IF

    IF (.Position.x <> 0.0) OR (.Position.y <> 0.0) OR (.Position.z <> 0.0) THEN
        glTranslatef (This.Position.x, This.Position.y, This.Position.z)
    END IF

    IF (.Rotation.x <> 0.0) OR (.Rotation.y <> 0.0) OR (.Rotation.z <> 0.0) THEN
        glRotatef (This.Rotation.x, 1, 0, 0)
        glRotatef (This.Rotation.y, 0, 1, 0)
        glRotatef (This.Rotation.z, 0, 0, 1)
    END IF
    END WITH
END SUB


PUBLIC:

SUB SetPosition (X AS SINGLE, Y AS SINGLE, Z AS SINGLE)        'like Qd3dFrame
    This.Position.x = x
    This.Position.y = y
    This.Position.z = z
'    This.DoTransformations
END SUB


SUB SetRotation (X AS SINGLE, Y AS SINGLE, Z AS SINGLE)
    This.Rotation.x = x
    This.Rotation.y = y
    This.Rotation.z = z
'    This.DoTransformations
END SUB


SUB SetScale (X AS SINGLE, Y AS SINGLE, Z AS SINGLE)        'like Qd3dFrame
    This.Scale.x = x
    This.Scale.y = y
    This.Scale.z = z
'    This.DoTransformations
END SUB



''''''''''''''''''
    ' Draw an interpolated MD2 frame
    ' Expects:
    '   theModel        = pointer to model
    '   theFrameNum     = index of first frame
    '   theFrameNum2    = index of the second frame
    '   theFrameFactor = 0 to draw the first frame, 1 to draw the second frame, or a value between 0 and 1
    '   theSkin         = skin to use

SUB DrawMD2 (theFrameNum AS INTEGER, theFrameNum2 AS INTEGER, theFrameFactor AS SINGLE, theSkin AS INTEGER)
    DIM i as integer, i2 as integer, i3 as integer
    DIM tempVec(2)      AS SINGLE
    DIM PartFrame       AS SINGLE

    This.DoTransformations
    glBindTexture (GL_TEXTURE_2D, This.skins(theSkin))
    ' Apply model scaling
     glMatrixMode (GL_MODELVIEW)
     glPushMatrix 

     glRotatef( -90, 1, 0, 0 )
     glRotatef( -90, 0, 0, 1 )
     PartFrame = 1.0 - theFrameFactor           'get the remaining portion of frame
    'linear interpolate position between frames
     tempVec(0) = This.Frame_translate(TheFrameNum, 0) * PartFrame + This.Frame_translate(TheFrameNum2, 0) * theFrameFactor
     tempVec(1) = This.Frame_translate(TheFrameNum, 1) * PartFrame + This.Frame_translate(TheFrameNum2, 1) * theFrameFactor
     tempVec(2) = This.Frame_translate(TheFrameNum, 2) * PartFrame + This.Frame_translate(TheFrameNum2, 2) * theFrameFactor
     glTranslatef (tempVec (0), tempVec (1), tempVec (2))

     'linear interpolate scale between frames
     tempVec(0) = This.Frame_scale(TheFrameNum, 0) * PartFrame + This.Frame_scale(TheFrameNum2, 0) * theFrameFactor
     tempVec(1) = This.Frame_scale(TheFrameNum, 1) * PartFrame + This.Frame_scale(TheFrameNum2, 1) * theFrameFactor
     tempVec(2) = This.Frame_scale(TheFrameNum, 2) * PartFrame + This.Frame_scale(TheFrameNum2, 2) * theFrameFactor
     glScalef (tempVec (0), tempVec (1), tempVec (2))

    ' Render each triangle
     glBegin (GL_TRIANGLES)
        for i = 0 to This.TheModel.num_tris - 1
            for i2 = 0 to 2
'                glNormal3fv (This.Frames(TheFrameNum).verts (This.tris(i).index_xyz (i2)).normal * (1 - theFrameFactor) + This.Frames(TheFrameNum2).verts (This.tris(i).index_xyz (i2)).normal * theFrameFactor)
                glTexCoord2fv(This.TexCoord(This.indexST(i,i2),0))
                tempVec(0) = This.Vertex(theFrameNum2, This.indexXYZ(i, i2), 0) * theFrameFactor + _
                              This.Vertex(theFrameNum, This.indexXYZ(i, i2), 0) * PartFrame
                tempVec(1) = This.Vertex(theFrameNum2, This.indexXYZ(i, i2), 1) * theFrameFactor + _
                              This.Vertex(theFrameNum, This.indexXYZ(i, i2), 1) * PartFrame
                tempVec(2) = This.Vertex(theFrameNum2, This.indexXYZ(i, i2), 2) * theFrameFactor + _
                              This.Vertex(theFrameNum, This.indexXYZ(i, i2), 2) * PartFrame
                glVertex3fv(tempVec(0))
            next i2
        next i
    glEnd
    glPopMatrix                         ' Restore modelview matrix
    glMatrixMode (GL_MODELVIEW)
END SUB



FUNCTION CreateAnimationSet(FirstFrame AS INTEGER, LastFrame AS INTEGER, FrameFactor AS SINGLE) AS LONG
    DIM i as integer, NumFrame as integer
    DIM FrameStep as single

    WITH THIS
    .StartFrame = .MaxAnimationFrame    'start from last animation index
    NumFrame = FirstFrame               'set our Frame counter
    FrameStep = FrameFactor             'and the portion to next frame

    DO
        .AnimationFrame(.MaxAnimationFrame) = glGenLists(1)    'allow seperate lists by start index
        glNewList( .AnimationFrame(.MaxAnimationFrame), GL_COMPILE)
        This.DrawMD2 (NumFrame, NumFrame + 1, FrameStep, This.skins(1))
        glEndList
        .MaxAnimationFrame++                                    'next list index
        IF .MaxAnimationFrame > MD2_MAX_ANIMATIONS THEN EXIT DO 'out of room
        FrameStep = FrameStep + FrameFactor                     'next part of animation
        IF FrameStep > 1.0 THEN FrameStep = 1.0: NumFrame++     'if finished to next frame, increment
    LOOP UNTIL (NumFrame >= LastFrame)
    RESULT = .StartFrame                                      'return start number of animation
    END WITH
END FUNCTION



SUB Animate
    static i as integer

    IF i <> This.CurrentFrame THEN
        This.DoTransformations
        glCallList(This.AnimationFrame(This.CurrentFrame))
        i = This.CurrentFrame
        IF This.hDC <> 0 THEN SwapBuffers This.hDC
    END IF
END SUB


SUB MD2_Set_FPS(TheFramesPerSecond AS SINGLE)
    IF TheFramesPerSecond > 0.0 THEN 
        This.FPS = TheFramesPerSecond
        This.FPSTimer.Interval = INT(1000/This.FPS)     'timer units in ms
        IF This.FPSTimer.Enabled = 0 THEN This.FPSTimer.Enabled = 1
    ELSE
        This.FPSTimer.Enabled = 0
    END IF
END SUB


SUB FPSTimerOver
    This.CurrentFrame++
    if This.CurrentFrame >= This.MaxAnimationFrame then This.CurrentFrame = This.StartFrame ' inc2026: >= вместо => (в документации только >=, operators.html)
END SUB


SUB New()
    WITH THIS
    .hDC = 0
    .FPSTimer.Enabled = 0
    .FPSTimer.OnTimer = This.FPSTimerOver
    .StartFrame = 0
    .CurrentFrame = 0
    .MaxFrame= 0
    .MaxAnimationFrame = 0
    .KeyFrameIndex = 0
    .Position.x = 0.0
    .Position.y = 0.0
    .Position.z = 0.0
    .Rotation.x = 0.0
    .Rotation.y = 0.0
    .Rotation.z = 0.0
    .Scale.x = 1.0
    .Scale.y = 1.0
    .Scale.z = 1.0
    END WITH
END SUB


SUB Clear
    DIM i AS INTEGER

    WITH THIS
    IF .MaxAnimationFrame > 0 THEN glDeleteLists(.AnimationFrame(0), .MaxAnimationFrame + 1)
      .New
      MEMSET(VARPTR(This.vertex(0,0,0)), 0, (MD2_MAX_FRAMES * MD2_MAX_VERTICES * 2))
      MEMSET(VARPTR(This.normal(0,0)), 0, (MD2_MAX_FRAMES * MD2_MAX_VERTICES))
      MEMSET(VARPTR(This.TexCoord(0,0)), 0, (MD2_MAX_TEXT_COORD * 2 * SIZEOF(SINGLE)))
      MEMSET(VARPTR(This.indexXYZ(0, 0)), 0, (MD2_MAX_TRIANGLES* 3 * SIZEOF(SHORT)))
      MEMSET(VARPTR(This.indexST(0 ,0)), 0, (MD2_MAX_TRIANGLES* 3 * SIZEOF(SHORT)))
      MEMSET(VARPTR(This.Frame_Scale(0, 0)), 0, (MD2_MAX_FRAMES* 3 * SIZEOF(SINGLE)))
      MEMSET(VARPTR(This.Frame_Translate(0, 0)), 0, (MD2_MAX_FRAMES* 3 * SIZEOF(SINGLE)))
      MEMSET(VARPTR(This.Frame_Name(0)), 0,(MD2_MAX_FRAMES * 16))
      MEMSET(VARPTR(This.skins(0)), 0, (32 * SIZEOF(GLint)))
    END WITH
END SUB



SUB CalcMD2Normals
'     DIM i As INTEGER, i2 As INTEGER, i3 As INTEGER
'DIM tempNormal(2)   AS SINGLE
'DIM tempTriangle(2,2) AS SINGLE

'     ' Note: The MD2 file format stores normals as indexed lookups into some normal table.
'     ' I cannot find this table, so I will simply recalculate them.
' 
'     ' Calculate for all frames
'     for i3 = 0 to theModel.num_frames - 1
'         for i = 0 to theModel.num_tris - 1
'             for i2 = 0 to 2
'                 tempTriangle (i2) = theFrame.verts (Stris(i).index_xyz (i2)).v
'             next
' 
'             ' Calculate normal as cross product between edges 0-1 and 0-2
'             tempNormal = Normalize (-CrossProduct (tempTriangle (1) - tempTriangle (0), tempTriangle (2) - tempTriangle (0)))
' 
'             ' Add new normal to normals at ALL vertices of the triangle.
'             ' This will have an averaging effect over vertices that are shared between multiple triangles
'             for i2 = 0 to 2
'                 theFrame.verts (Stris(i).index_xyz (i2)).normal = theFrame.verts (Stris(i).index_xyz (i2)).normal + tempNormal
'             next
'         next
' 
'         ' Normalise all normals
'         for i = 0 to theModel.num_xyz - 1
'             theFrame.verts (i).normal = Normalize (theFrame.verts (i).normal)
'         next
'     next
END SUB


CONSTRUCTOR
    New
END CONSTRUCTOR

END TYPE

