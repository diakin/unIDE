'
'' Copyright (c) Mark J. Kilgard, 1994, 1995, 1996, 1998. */
'
'' This program is freely distributable without licensing fees  and is
'   provided without guarantee or warrantee expressed or  implied. This
'   program is -not- in the public domain. */
'
'' Win32 has an annoying issue where there are multiple C run-time
'   libraries (CRTs).  If the executable is linked with a different CRT
'   from the GLUT DLL, the GLUT DLL will not share the same CRT static
'   data seen by the executable.  In particular, atexit callbacks registered
'   in the executable will not be called if GLUT calls its (different)
'   exit routine).  GLUT is typically built with the
'   "/MD" option (the CRT with multithreading DLL support), but the Visual
'   C++ linker default is "/ML" (the single threaded CRT).
'
'   One workaround to this issue is requiring users to always link with
'   the same CRT as GLUT is compiled with.  That requires users supply a
'   non-standard option.  GLUT 3.7 has its own built-in workaround where
'   the executable's "exit" function pointer is covertly passed to GLUT.
'   GLUT then calls the executable's exit function pointer to ensure that
'   any "atexit" calls registered by the application are called if GLUT
'   needs to exit.
'
'   Note that the __glut*WithExit routines should NEVER be called directly.
'   To avoid the atexit workaround, CONST GLUT_DISABLE_ATEXIT_HACK. */

''*
' GLUT API revision history:
' 
' GLUT_API_VERSION is updated to reflect incompatible GLUT
' API changes (interface changes, semantic changes, deletions,
' or additions).
' 
'' GLUT_API_VERSION=1  First public release of GLUT.  11/29/94 
'
' GLUT_API_VERSION=2  Added support for OpenGL/GLX multisampling,
' extension.  Supports new input devices like tablet, dial and button
' box, and Spaceball.  Easy to query OpenGL extensions.'
'
' GLUT_API_VERSION=3  glutMenuStatus added.
'
' GLUT_API_VERSION=4  glutInitDisplayString, glutWarpPointer,
' glutBitmapLength, glutStrokeLength, glutWindowStatusFunc, dynamic
' video resize subAPI, glutPostWindowRedisplay, glutKeyboardUpFunc,
' glutSpecialUpFunc, glutIgnoreKeyRepeat, glutSetKeyRepeat,
' glutJoystickFunc, glutForceJoystickFunc (NOT FINALIZED!).


'Variable conventions:
'GL Suffix		Data Type 	C-Type 			OpenGL Type
'b	 8-bit		integer		signed char		GLbyte
's	16-bit		integer		short			GLshort
'i	32-bit		integer		int or long		GLint, GLsizei
'f	32-bit 		float		float			GLfloat, GLclampf
'd	64-bit 		float		double			GLdouble, GLclampd
'ub	8-bit 		unsigned	unsigned char	GLubyte, GLboolean
'us	16-bit		unsigned 	unsigned short	GLushort
'ui	32-bit		unsigned	unsigned int	GLuint, GLenum, GLbitfield
''
''
''
'' OpenGL Utility Toolkit -- header translated with help of SWIG FB wrapper
''
'' NOTICE: This file is part of the FreeBASIC Compiler package and can't
''         be included in other distributions without authorization.
'' 
'' 'Modified for RapidQ by JohnK

$ifndef __glut_inc
$DEFINE __glut_inc

$include <GL/gl.inc>
$include <GL/glu.inc>

$DEFINE GLUT_API_VERSION 3
$DEFINE GLUT_XLIB_IMPLEMENTATION 15
$DEFINE GLUT_RGB 0
$DEFINE GLUT_RGBA 0
$DEFINE GLUT_INDEX 1
$DEFINE GLUT_SINGLE 0
$DEFINE GLUT_DOUBLE 2
$DEFINE GLUT_ACCUM 4
$DEFINE GLUT_ALPHA 8
$DEFINE GLUT_DEPTH 16
$DEFINE GLUT_STENCIL 32
$DEFINE GLUT_MULTISAMPLE 128
$DEFINE GLUT_STEREO 256
$DEFINE GLUT_LUMINANCE 512
$DEFINE GLUT_LEFT_BUTTON 0
$DEFINE GLUT_MIDDLE_BUTTON 1
$DEFINE GLUT_RIGHT_BUTTON 2
$DEFINE GLUT_DOWN 0
$DEFINE GLUT_UP 1
$DEFINE GLUT_KEY_F1 1
$DEFINE GLUT_KEY_F2 2
$DEFINE GLUT_KEY_F3 3
$DEFINE GLUT_KEY_F4 4
$DEFINE GLUT_KEY_F5 5
$DEFINE GLUT_KEY_F6 6
$DEFINE GLUT_KEY_F7 7
$DEFINE GLUT_KEY_F8 8
$DEFINE GLUT_KEY_F9 9
$DEFINE GLUT_KEY_F10 10
$DEFINE GLUT_KEY_F11 11
$DEFINE GLUT_KEY_F12 12
$DEFINE GLUT_KEY_LEFT 100
$DEFINE GLUT_KEY_UP 101
$DEFINE GLUT_KEY_RIGHT 102
$DEFINE GLUT_KEY_DOWN 103
$DEFINE GLUT_KEY_PAGE_UP 104
$DEFINE GLUT_KEY_PAGE_DOWN 105
$DEFINE GLUT_KEY_HOME 106
$DEFINE GLUT_KEY_END 107
$DEFINE GLUT_KEY_INSERT 108
$DEFINE GLUT_LEFT 0
$DEFINE GLUT_ENTERED 1
$DEFINE GLUT_MENU_NOT_IN_USE 0
$DEFINE GLUT_MENU_IN_USE 1
$DEFINE GLUT_NOT_VISIBLE 0
$DEFINE GLUT_VISIBLE 1
$DEFINE GLUT_HIDDEN 0
$DEFINE GLUT_FULLY_RETAINED 1
$DEFINE GLUT_PARTIALLY_RETAINED 2
$DEFINE GLUT_FULLY_COVERED 3
$DEFINE GLUT_RED 0
$DEFINE GLUT_GREEN 1
$DEFINE GLUT_BLUE 2
$DEFINE GLUT_WINDOW_X 100
$DEFINE GLUT_WINDOW_Y 101
$DEFINE GLUT_WINDOW_WIDTH 102
$DEFINE GLUT_WINDOW_HEIGHT 103
$DEFINE GLUT_WINDOW_BUFFER_SIZE 104
$DEFINE GLUT_WINDOW_STENCIL_SIZE 105
$DEFINE GLUT_WINDOW_DEPTH_SIZE 106
$DEFINE GLUT_WINDOW_RED_SIZE 107
$DEFINE GLUT_WINDOW_GREEN_SIZE 108
$DEFINE GLUT_WINDOW_BLUE_SIZE 109
$DEFINE GLUT_WINDOW_ALPHA_SIZE 110
$DEFINE GLUT_WINDOW_ACCUM_RED_SIZE 111
$DEFINE GLUT_WINDOW_ACCUM_GREEN_SIZE 112
$DEFINE GLUT_WINDOW_ACCUM_BLUE_SIZE 113
$DEFINE GLUT_WINDOW_ACCUM_ALPHA_SIZE 114
$DEFINE GLUT_WINDOW_DOUBLEBUFFER 115
$DEFINE GLUT_WINDOW_RGBA 116
$DEFINE GLUT_WINDOW_PARENT 117
$DEFINE GLUT_WINDOW_NUM_CHILDREN 118
$DEFINE GLUT_WINDOW_COLORMAP_SIZE 119
$DEFINE GLUT_WINDOW_NUM_SAMPLES 120
$DEFINE GLUT_WINDOW_STEREO 121
$DEFINE GLUT_WINDOW_CURSOR 122
$DEFINE GLUT_SCREEN_WIDTH 200
$DEFINE GLUT_SCREEN_HEIGHT 201
$DEFINE GLUT_SCREEN_WIDTH_MM 202
$DEFINE GLUT_SCREEN_HEIGHT_MM 203
$DEFINE GLUT_MENU_NUM_ITEMS 300
$DEFINE GLUT_DISPLAY_MODE_POSSIBLE 400
$DEFINE GLUT_INIT_WINDOW_X 500
$DEFINE GLUT_INIT_WINDOW_Y 501
$DEFINE GLUT_INIT_WINDOW_WIDTH 502
$DEFINE GLUT_INIT_WINDOW_HEIGHT 503
$DEFINE GLUT_INIT_DISPLAY_MODE 504
$DEFINE GLUT_ELAPSED_TIME 700
$DEFINE GLUT_WINDOW_FORMAT_ID 123
$DEFINE GLUT_HAS_KEYBOARD 600
$DEFINE GLUT_HAS_MOUSE 601
$DEFINE GLUT_HAS_SPACEBALL 602
$DEFINE GLUT_HAS_DIAL_AND_BUTTON_BOX 603
$DEFINE GLUT_HAS_TABLET 604
$DEFINE GLUT_NUM_MOUSE_BUTTONS 605
$DEFINE GLUT_NUM_SPACEBALL_BUTTONS 606
$DEFINE GLUT_NUM_BUTTON_BOX_BUTTONS 607
$DEFINE GLUT_NUM_DIALS 608
$DEFINE GLUT_NUM_TABLET_BUTTONS 609
$DEFINE GLUT_DEVICE_IGNORE_KEY_REPEAT 610
$DEFINE GLUT_DEVICE_KEY_REPEAT 611
$DEFINE GLUT_HAS_JOYSTICK 612
$DEFINE GLUT_OWNS_JOYSTICK 613
$DEFINE GLUT_JOYSTICK_BUTTONS 614
$DEFINE GLUT_JOYSTICK_AXES 615
$DEFINE GLUT_JOYSTICK_POLL_RATE 616
$DEFINE GLUT_OVERLAY_POSSIBLE 800
$DEFINE GLUT_LAYER_IN_USE 801
$DEFINE GLUT_HAS_OVERLAY 802
$DEFINE GLUT_TRANSPARENT_INDEX 803
$DEFINE GLUT_NORMAL_DAMAGED 804
$DEFINE GLUT_OVERLAY_DAMAGED 805
$DEFINE GLUT_VIDEO_RESIZE_POSSIBLE 900
$DEFINE GLUT_VIDEO_RESIZE_IN_USE 901
$DEFINE GLUT_VIDEO_RESIZE_X_DELTA 902
$DEFINE GLUT_VIDEO_RESIZE_Y_DELTA 903
$DEFINE GLUT_VIDEO_RESIZE_WIDTH_DELTA 904
$DEFINE GLUT_VIDEO_RESIZE_HEIGHT_DELTA 905
$DEFINE GLUT_VIDEO_RESIZE_X 906
$DEFINE GLUT_VIDEO_RESIZE_Y 907
$DEFINE GLUT_VIDEO_RESIZE_WIDTH 908
$DEFINE GLUT_VIDEO_RESIZE_HEIGHT 909
$DEFINE GLUT_NORMAL 0
$DEFINE GLUT_OVERLAY 1
$DEFINE GLUT_ACTIVE_SHIFT 1
$DEFINE GLUT_ACTIVE_CTRL 2
$DEFINE GLUT_ACTIVE_ALT 4
$DEFINE GLUT_CURSOR_RIGHT_ARROW 0
$DEFINE GLUT_CURSOR_LEFT_ARROW 1
$DEFINE GLUT_CURSOR_INFO 2
$DEFINE GLUT_CURSOR_DESTROY 3
$DEFINE GLUT_CURSOR_HELP 4
$DEFINE GLUT_CURSOR_CYCLE 5
$DEFINE GLUT_CURSOR_SPRAY 6
$DEFINE GLUT_CURSOR_WAIT 7
$DEFINE GLUT_CURSOR_TEXT 8
$DEFINE GLUT_CURSOR_CROSSHAIR 9
$DEFINE GLUT_CURSOR_UP_DOWN 10
$DEFINE GLUT_CURSOR_LEFT_RIGHT 11
$DEFINE GLUT_CURSOR_TOP_SIDE 12
$DEFINE GLUT_CURSOR_BOTTOM_SIDE 13
$DEFINE GLUT_CURSOR_LEFT_SIDE 14
$DEFINE GLUT_CURSOR_RIGHT_SIDE 15
$DEFINE GLUT_CURSOR_TOP_LEFT_CORNER 16
$DEFINE GLUT_CURSOR_TOP_RIGHT_CORNER 17
$DEFINE GLUT_CURSOR_BOTTOM_RIGHT_CORNER 18
$DEFINE GLUT_CURSOR_BOTTOM_LEFT_CORNER 19
$DEFINE GLUT_CURSOR_INHERIT 100
$DEFINE GLUT_CURSOR_NONE 101
$DEFINE GLUT_CURSOR_FULL_CROSSHAIR 102

declare sub glutInit LIB "glut32.dll" ALIAS "glutInit" (byref argcp as integer, byref argv as byte ptr)
declare sub glutInitDisplayMode LIB "glut32.dll" ALIAS "glutInitDisplayMode" (byval mode as uinteger)
declare sub glutInitDisplayString LIB "glut32.dll" ALIAS "glutInitDisplayString" (byval string as string)
declare sub glutInitWindowPosition LIB "glut32.dll" ALIAS "glutInitWindowPosition" (byval x as integer, byval y as integer)
declare sub glutInitWindowSize LIB "glut32.dll" ALIAS "glutInitWindowSize" (byval width as integer, byval height as integer)
declare sub glutMainLoop LIB "glut32.dll" ALIAS "glutMainLoop" ()
declare function glutCreateWindow LIB "glut32.dll" ALIAS "glutCreateWindow" (byval title as string) as integer
declare function glutCreateSubWindow LIB "glut32.dll" ALIAS "glutCreateSubWindow" (byval win as integer, byval x as integer, byval y as integer, byval width as integer, byval height as integer) as integer
declare sub glutDestroyWindow LIB "glut32.dll" ALIAS "glutDestroyWindow" (byval win as integer)
declare sub glutPostRedisplay LIB "glut32.dll" ALIAS "glutPostRedisplay" ()
declare sub glutPostWindowRedisplay LIB "glut32.dll" ALIAS "glutPostWindowRedisplay" (byval win as integer)
declare sub glutSwapBuffers LIB "glut32.dll" ALIAS "glutSwapBuffers" ()
declare function glutGetWindow LIB "glut32.dll" ALIAS "glutGetWindow" () as integer
declare sub glutSetWindow LIB "glut32.dll" ALIAS "glutSetWindow" (byval win as integer)
declare sub glutSetWindowTitle LIB "glut32.dll" ALIAS "glutSetWindowTitle" (byval title as string)
declare sub glutSetIconTitle LIB "glut32.dll" ALIAS "glutSetIconTitle" (byval title as string)
declare sub glutPositionWindow LIB "glut32.dll" ALIAS "glutPositionWindow" (byval x as integer, byval y as integer)
declare sub glutReshapeWindow LIB "glut32.dll" ALIAS "glutReshapeWindow" (byval width as integer, byval height as integer)
declare sub glutPopWindow LIB "glut32.dll" ALIAS "glutPopWindow" ()
declare sub glutPushWindow LIB "glut32.dll" ALIAS "glutPushWindow" ()
declare sub glutIconifyWindow LIB "glut32.dll" ALIAS "glutIconifyWindow" ()
declare sub glutShowWindow LIB "glut32.dll" ALIAS "glutShowWindow" ()
declare sub glutHideWindow LIB "glut32.dll" ALIAS "glutHideWindow" ()
declare sub glutFullScreen LIB "glut32.dll" ALIAS "glutFullScreen" ()
declare sub glutSetCursor LIB "glut32.dll" ALIAS "glutSetCursor" (byval cursor as integer)
declare sub glutWarpPointer LIB "glut32.dll" ALIAS "glutWarpPointer" (byval x as integer, byval y as integer)
declare sub glutEstablishOverlay LIB "glut32.dll" ALIAS "glutEstablishOverlay" ()
declare sub glutRemoveOverlay LIB "glut32.dll" ALIAS "glutRemoveOverlay" ()
declare sub glutUseLayer LIB "glut32.dll" ALIAS "glutUseLayer" (byval layer as GLenum)
declare sub glutPostOverlayRedisplay LIB "glut32.dll" ALIAS "glutPostOverlayRedisplay" ()
declare sub glutPostWindowOverlayRedisplay LIB "glut32.dll" ALIAS "glutPostWindowOverlayRedisplay" (byval win as integer)
declare sub glutShowOverlay LIB "glut32.dll" ALIAS "glutShowOverlay" ()
declare sub glutHideOverlay LIB "glut32.dll" ALIAS "glutHideOverlay" ()
declare function glutCreateMenu LIB "glut32.dll" ALIAS "glutCreateMenu" (byval func as sub(byval as integer)) as integer
declare sub glutDestroyMenu LIB "glut32.dll" ALIAS "glutDestroyMenu" (byval menu as integer)
declare function glutGetMenu LIB "glut32.dll" ALIAS "glutGetMenu" () as integer
declare sub glutSetMenu LIB "glut32.dll" ALIAS "glutSetMenu" (byval menu as integer)
declare sub glutAddMenuEntry LIB "glut32.dll" ALIAS "glutAddMenuEntry" (byval label as string, byval value as integer)
declare sub glutAddSubMenu LIB "glut32.dll" ALIAS "glutAddSubMenu" (byval label as string, byval submenu as integer)
declare sub glutChangeToMenuEntry LIB "glut32.dll" ALIAS "glutChangeToMenuEntry" (byval item as integer, byval label as string, byval value as integer)
declare sub glutChangeToSubMenu LIB "glut32.dll" ALIAS "glutChangeToSubMenu" (byval item as integer, byval label as string, byval submenu as integer)
declare sub glutRemoveMenuItem LIB "glut32.dll" ALIAS "glutRemoveMenuItem" (byval item as integer)
declare sub glutAttachMenu LIB "glut32.dll" ALIAS "glutAttachMenu" (byval button as integer)
declare sub glutDetachMenu LIB "glut32.dll" ALIAS "glutDetachMenu" (byval button as integer)
declare sub glutDisplayFunc LIB "glut32.dll" ALIAS "glutDisplayFunc" (byval func as sub cdecl())
declare sub glutReshapeFunc LIB "glut32.dll" ALIAS "glutReshapeFunc" (byval func as sub cdecl(byval as integer, byval as integer))
declare sub glutKeyboardFunc LIB "glut32.dll" ALIAS "glutKeyboardFunc" (byval func as sub cdecl(byval as ubyte, byval as integer, byval as integer))
declare sub glutMouseFunc LIB "glut32.dll" ALIAS "glutMouseFunc" (byval func as sub cdecl(byval as integer, byval as integer, byval as integer, byval as integer))
declare sub glutMotionFunc LIB "glut32.dll" ALIAS "glutMotionFunc" (byval func as sub cdecl(byval as integer, byval as integer))
declare sub glutPassiveMotionFunc LIB "glut32.dll" ALIAS "glutPassiveMotionFunc" (byval func as sub cdecl(byval as integer, byval as integer))
declare sub glutEntryFunc LIB "glut32.dll" ALIAS "glutEntryFunc" (byval func as sub(byval as integer))
declare sub glutVisibilityFunc LIB "glut32.dll" ALIAS "glutVisibilityFunc" (byval func as sub cdecl(byval as integer))
declare sub glutIdleFunc LIB "glut32.dll" ALIAS "glutIdleFunc" (byval func as sub cdecl())
declare sub glutTimerFunc LIB "glut32.dll" ALIAS "glutTimerFunc" (byval millis as uinteger, byval func as sub cdecl(byval as integer), byval value as integer)
declare sub glutMenuStateFunc LIB "glut32.dll" ALIAS "glutMenuStateFunc" (byval func as sub cdecl(byval as integer))
declare sub glutSpecialFunc LIB "glut32.dll" ALIAS "glutSpecialFunc" (byval func as sub cdecl(byval as integer, byval as integer, byval as integer))
declare sub glutSpaceballMotionFunc LIB "glut32.dll" ALIAS "glutSpaceballMotionFunc" (byval func as sub cdecl(byval as integer, byval as integer, byval as integer))
declare sub glutSpaceballRotateFunc LIB "glut32.dll" ALIAS "glutSpaceballRotateFunc" (byval func as sub cdecl(byval as integer, byval as integer, byval as integer))
declare sub glutSpaceballButtonFunc LIB "glut32.dll" ALIAS "glutSpaceballButtonFunc" (byval func as sub cdecl(byval as integer, byval as integer))
declare sub glutButtonBoxFunc LIB "glut32.dll" ALIAS "glutButtonBoxFunc" (byval func as sub cdecl(byval as integer, byval as integer))
declare sub glutDialsFunc LIB "glut32.dll" ALIAS "glutDialsFunc" (byval func as sub cdecl(byval as integer, byval as integer))
declare sub glutTabletMotionFunc LIB "glut32.dll" ALIAS "glutTabletMotionFunc" (byval func as sub cdecl(byval as integer, byval as integer))
declare sub glutTabletButtonFunc LIB "glut32.dll" ALIAS "glutTabletButtonFunc" (byval func as sub cdecl(byval as integer, byval as integer, byval as integer, byval as integer))
declare sub glutMenuStatusFunc LIB "glut32.dll" ALIAS "glutMenuStatusFunc" (byval func as sub(byval as integer, byval as integer, byval as integer))
declare sub glutOverlayDisplayFunc LIB "glut32.dll" ALIAS "glutOverlayDisplayFunc" (byval func as sub cdecl())
declare sub glutWindowStatusFunc LIB "glut32.dll" ALIAS "glutWindowStatusFunc" (byval func as sub cdecl(byval as integer))
declare sub glutKeyboardUpFunc LIB "glut32.dll" ALIAS "glutKeyboardUpFunc" (byval func as sub cdecl(byval as ubyte, byval as integer, byval as integer))
declare sub glutSpecialUpFunc LIB "glut32.dll" ALIAS "glutSpecialUpFunc" (byval func as sub cdecl(byval as integer, byval as integer, byval as integer))
declare sub glutJoystickFunc LIB "glut32.dll" ALIAS "glutJoystickFunc" (byval func as sub cdecl(byval as uinteger, byval as integer, byval as integer, byval as integer), byval pollInterval as integer)
declare sub glutSetColor LIB "glut32.dll" ALIAS "glutSetColor" (byval as integer, byval red as GLfloat, byval green as GLfloat, byval blue as GLfloat)
declare function glutGetColor LIB "glut32.dll" ALIAS "glutGetColor" (byval ndx as integer, byval component as integer) as GLfloat
declare sub glutCopyColormap LIB "glut32.dll" ALIAS "glutCopyColormap" (byval win as integer)
declare function glutGet LIB "glut32.dll" ALIAS "glutGet" (byval type as GLenum) as integer
declare function glutDeviceGet LIB "glut32.dll" ALIAS "glutDeviceGet" (byval type as GLenum) as integer
declare function glutExtensionSupported LIB "glut32.dll" ALIAS "glutExtensionSupported" (byval name as string) as integer
declare function glutGetModifiers LIB "glut32.dll" ALIAS "glutGetModifiers" () as integer
declare function glutLayerGet LIB "glut32.dll" ALIAS "glutLayerGet" (byval type as GLenum) as integer
declare sub glutBitmapCharacter LIB "glut32.dll" ALIAS "glutBitmapCharacter" (byref font as any ptr, byval character as integer)
declare function glutBitmapWidth LIB "glut32.dll" ALIAS "glutBitmapWidth" (byref font as any ptr, byval character as integer) as integer
declare sub glutStrokeCharacter LIB "glut32.dll" ALIAS "glutStrokeCharacter" (byref font as any ptr, byval character as integer)
declare function glutStrokeWidth LIB "glut32.dll" ALIAS "glutStrokeWidth" (byref font as any ptr, byval character as integer) as integer
declare function glutBitmapLength LIB "glut32.dll" ALIAS "glutBitmapLength" (byref font as any ptr, lpstring as STRING) as integer
declare function glutStrokeLength LIB "glut32.dll" ALIAS "glutStrokeLength" (byref font as any ptr, lpString as STRING) as integer
declare sub glutWireSphere LIB "glut32.dll" ALIAS "glutWireSphere" (byval radius as GLdouble, byval slices as GLint, byval stacks as GLint)
declare sub glutSolidSphere LIB "glut32.dll" ALIAS "glutSolidSphere" (byval radius as GLdouble, byval slices as GLint, byval stacks as GLint)
declare sub glutWireCone LIB "glut32.dll" ALIAS "glutWireCone" (byval base as GLdouble, byval height as GLdouble, byval slices as GLint, byval stacks as GLint)
declare sub glutSolidCone LIB "glut32.dll" ALIAS "glutSolidCone" (byval base as GLdouble, byval height as GLdouble, byval slices as GLint, byval stacks as GLint)
declare sub glutWireCube LIB "glut32.dll" ALIAS "glutWireCube" (byval size as GLdouble)
declare sub glutSolidCube LIB "glut32.dll" ALIAS "glutSolidCube" (byval size as GLdouble)
declare sub glutWireTorus LIB "glut32.dll" ALIAS "glutWireTorus" (byval innerRadius as GLdouble, byval outerRadius as GLdouble, byval sides as GLint, byval rings as GLint)
declare sub glutSolidTorus LIB "glut32.dll" ALIAS "glutSolidTorus" (byval innerRadius as GLdouble, byval outerRadius as GLdouble, byval sides as GLint, byval rings as GLint)
declare sub glutWireDodecahedron LIB "glut32.dll" ALIAS "glutWireDodecahedron" ()
declare sub glutSolidDodecahedron LIB "glut32.dll" ALIAS "glutSolidDodecahedron" ()
declare sub glutWireTeapot LIB "glut32.dll" ALIAS "glutWireTeapot" (byval size as GLdouble)
declare sub glutSolidTeapot LIB "glut32.dll" ALIAS "glutSolidTeapot" (byval size as GLdouble)
declare sub glutWireOctahedron LIB "glut32.dll" ALIAS "glutWireOctahedron" ()
declare sub glutSolidOctahedron LIB "glut32.dll" ALIAS "glutSolidOctahedron" ()
declare sub glutWireTetrahedron LIB "glut32.dll" ALIAS "glutWireTetrahedron" ()
declare sub glutSolidTetrahedron LIB "glut32.dll" ALIAS "glutSolidTetrahedron" ()
declare sub glutWireIcosahedron LIB "glut32.dll" ALIAS "glutWireIcosahedron" ()
declare sub glutSolidIcosahedron LIB "glut32.dll" ALIAS "glutSolidIcosahedron" ()
declare function glutVideoResizeGet LIB "glut32.dll" ALIAS "glutVideoResizeGet" (byval param as GLenum) as integer
declare sub glutSetupVideoResizing LIB "glut32.dll" ALIAS "glutSetupVideoResizing" ()
declare sub glutStopVideoResizing LIB "glut32.dll" ALIAS "glutStopVideoResizing" ()
declare sub glutVideoResize LIB "glut32.dll" ALIAS "glutVideoResize" (byval x as integer, byval y as integer, byval width as integer, byval height as integer)
declare sub glutVideoPan LIB "glut32.dll" ALIAS "glutVideoPan" (byval x as integer, byval y as integer, byval width as integer, byval height as integer)
declare sub glutReportErrors LIB "glut32.dll" ALIAS "glutReportErrors" ()

$DEFINE GLUT_KEY_REPEAT_OFF 0
$DEFINE GLUT_KEY_REPEAT_ON 1
$DEFINE GLUT_KEY_REPEAT_DEFAULT 2
$DEFINE GLUT_JOYSTICK_BUTTON_A 1
$DEFINE GLUT_JOYSTICK_BUTTON_B 2
$DEFINE GLUT_JOYSTICK_BUTTON_C 4
$DEFINE GLUT_JOYSTICK_BUTTON_D 8

declare sub glutIgnoreKeyRepeat LIB "glut32.dll" ALIAS "glutIgnoreKeyRepeat" (byval ignore as integer)
declare sub glutSetKeyRepeat LIB "glut32.dll" ALIAS "glutSetKeyRepeat" (byval repeatMode as integer)
declare sub glutForceJoystickFunc LIB "glut32.dll" ALIAS "glutForceJoystickFunc" ()

$DEFINE GLUT_GAME_MODE_ACTIVE 0
$DEFINE GLUT_GAME_MODE_POSSIBLE 1
$DEFINE GLUT_GAME_MODE_WIDTH 2
$DEFINE GLUT_GAME_MODE_HEIGHT 3
$DEFINE GLUT_GAME_MODE_PIXEL_DEPTH 4
$DEFINE GLUT_GAME_MODE_REFRESH_RATE 5
$DEFINE GLUT_GAME_MODE_DISPLAY_CHANGED 6

declare sub glutGameModeString LIB "glut32.dll" ALIAS "glutGameModeString" (byval string as string)
declare function glutEnterGameMode LIB "glut32.dll" ALIAS "glutEnterGameMode" () as integer
declare sub glutLeaveGameMode LIB "glut32.dll" ALIAS "glutLeaveGameMode" ()
declare function glutGameModeGet LIB "glut32.dll" ALIAS "glutGameModeGet" (byval mode as GLenum) as integer

$endif
