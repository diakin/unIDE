'========================================================================
' GLFW - An OpenGL framework
' File:        glfw.bas
' Platform:    Visual Basic/Windows
' API version: 2.5
' Author:      Marcus Geelnard (marcus.geelnard at home.se)
' WWW:         http://glfw.sourceforge.net
'------------------------------------------------------------------------
' Copyright (c) 2002-2005 Marcus Geelnard
'
' This software is provided 'as-is', without any express or implied
' warranty. In no event will the authors be held liable for any damages
' arising from the use of this software.
'
' Permission is granted to anyone to use this software for any purpose,
' including commercial applications, and to alter it and redistribute it
' freely, subject to the following restrictions:
'
' 1. The origin of this software must not be misrepresented; you must not
'    claim that you wrote the original software. If you use this software
'    in a product, an acknowledgment in the product documentation would
'    be appreciated but is not required.
'
' 2. Altered source versions must be plainly marked as such, and must not
'    be misrepresented as being the original software.
'
' 3. This notice may not be removed or altered from any source
'    distribution.
'
' Marcus Geelnard
' marcus.geelnard at home.se
'------------------------------------------------------------------------
' $Id: glfw.bas,v 1.8 2005/03/14 21:19:15 marcus256 Exp $
'========================================================================

'========================================================================
'' parts of this header translated with help of SWIG FB wrapper)
''
''
$ifndef __glfw_inc
$DEFINE __glfw_inc

'' Copyright (c) 2002-2004 Marcus Geelnard
''
'' This software is provided 'as-is', without any express or implied
'' warranty. In no event will the authors be held liable for any damages
'' arising from the use of this software.
''
'' Permission is granted to anyone to use this software for any purpose,
'' including commercial applications, and to alter it and redistribute it
'' freely, subject to the following restrictions:
''
'' 1. The origin of this software must not be misrepresented; you must not
''    claim that you wrote the original software. If you use this software
''    in a product, an acknowledgment in the product documentation would
''    be appreciated but is not required.
''
'' 2. Altered source versions must be plainly marked as such, and must not
''    be misrepresented as being the original software.
''
'' 3. This notice may not be removed or altered from any source
''    distribution.
''
'' Marcus Geelnard
'' marcus.geelnard at home.se

'' note it is assumed that you are compiling on Windows 32 bit platform
'' all API calls are assumed to be STDCALL NOT cdecl
'IF WIN_32
'$define GLFWAPIENTRY stdcall
'$define GLFWCALL     stdcall
'$else
'$define GLFWAPIENTRY cdecl
'$define GLFWCALL     cdecl
''
''
''  This code was ported to RapidQ by JohnK

'========================================================================
' GLFW version
'========================================================================

$DEFINE GLFW_VERSION_MAJOR 2
$DEFINE GLFW_VERSION_MINOR 4
$DEFINE GLFW_VERSION_REVISION 2
'========================================================================
' Input handling definitions
'========================================================================
' Key and button state/action definitions
$DEFINE GLFW_RELEASE 0
$DEFINE GLFW_PRESS 1


' Keyboard key definitions: 8-bit ISO-8859-1 (Latin 1) encoding is used
' for printable keys (such as A-Z, 0-9 etc), and values above 256
' represent special (non-printable) keys (e.g. F1, Page Up etc).
$DEFINE GLFW_KEY_UNKNOWN -1
$DEFINE GLFW_KEY_SPACE 32
$DEFINE GLFW_KEY_SPECIAL 256
$DEFINE GLFW_KEY_ESC (256+1)
$DEFINE GLFW_KEY_F1 (256+2)
$DEFINE GLFW_KEY_F2 (256+3)
$DEFINE GLFW_KEY_F3 (256+4)
$DEFINE GLFW_KEY_F4 (256+5)
$DEFINE GLFW_KEY_F5 (256+6)
$DEFINE GLFW_KEY_F6 (256+7)
$DEFINE GLFW_KEY_F7 (256+8)
$DEFINE GLFW_KEY_F8 (256+9)
$DEFINE GLFW_KEY_F9 (256+10)
$DEFINE GLFW_KEY_F10 (256+11)
$DEFINE GLFW_KEY_F11 (256+12)
$DEFINE GLFW_KEY_F12 (256+13)
$DEFINE GLFW_KEY_F13 (256+14)
$DEFINE GLFW_KEY_F14 (256+15)
$DEFINE GLFW_KEY_F15 (256+16)
$DEFINE GLFW_KEY_F16 (256+17)
$DEFINE GLFW_KEY_F17 (256+18)
$DEFINE GLFW_KEY_F18 (256+19)
$DEFINE GLFW_KEY_F19 (256+20)
$DEFINE GLFW_KEY_F20 (256+21)
$DEFINE GLFW_KEY_F21 (256+22)
$DEFINE GLFW_KEY_F22 (256+23)
$DEFINE GLFW_KEY_F23 (256+24)
$DEFINE GLFW_KEY_F24 (256+25)
$DEFINE GLFW_KEY_F25 (256+26)
$DEFINE GLFW_KEY_UP (256+27)
$DEFINE GLFW_KEY_DOWN (256+28)
$DEFINE GLFW_KEY_LEFT (256+29)
$DEFINE GLFW_KEY_RIGHT (256+30)
$DEFINE GLFW_KEY_LSHIFT (256+31)
$DEFINE GLFW_KEY_RSHIFT (256+32)
$DEFINE GLFW_KEY_LCTRL (256+33)
$DEFINE GLFW_KEY_RCTRL (256+34)
$DEFINE GLFW_KEY_LALT (256+35)
$DEFINE GLFW_KEY_RALT (256+36)
$DEFINE GLFW_KEY_TAB (256+37)
$DEFINE GLFW_KEY_ENTER (256+38)
$DEFINE GLFW_KEY_BACKSPACE (256+39)
$DEFINE GLFW_KEY_INSERT (256+40)
$DEFINE GLFW_KEY_DEL (256+41)
$DEFINE GLFW_KEY_PAGEUP (256+42)
$DEFINE GLFW_KEY_PAGEDOWN (256+43)
$DEFINE GLFW_KEY_HOME (256+44)
$DEFINE GLFW_KEY_END (256+45)
$DEFINE GLFW_KEY_KP_0 (256+46)
$DEFINE GLFW_KEY_KP_1 (256+47)
$DEFINE GLFW_KEY_KP_2 (256+48)
$DEFINE GLFW_KEY_KP_3 (256+49)
$DEFINE GLFW_KEY_KP_4 (256+50)
$DEFINE GLFW_KEY_KP_5 (256+51)
$DEFINE GLFW_KEY_KP_6 (256+52)
$DEFINE GLFW_KEY_KP_7 (256+53)
$DEFINE GLFW_KEY_KP_8 (256+54)
$DEFINE GLFW_KEY_KP_9 (256+55)
$DEFINE GLFW_KEY_KP_DIVIDE (256+56)
$DEFINE GLFW_KEY_KP_MULTIPLY (256+57)
$DEFINE GLFW_KEY_KP_SUBTRACT (256+58)
$DEFINE GLFW_KEY_KP_ADD (256+59)
$DEFINE GLFW_KEY_KP_DECIMAL (256+60)
$DEFINE GLFW_KEY_KP_EQUAL (256+61)
$DEFINE GLFW_KEY_KP_ENTER (256+62)
$DEFINE GLFW_KEY_LAST (256+62)
$DEFINE GLFW_MOUSE_BUTTON_LEFT 0
$DEFINE GLFW_MOUSE_BUTTON_RIGHT 1
$DEFINE GLFW_MOUSE_BUTTON_MIDDLE 2
$DEFINE GLFW_MOUSE_BUTTON_LAST 2
$DEFINE GLFW_JOYSTICK_1 0
$DEFINE GLFW_JOYSTICK_2 1
$DEFINE GLFW_JOYSTICK_3 2
$DEFINE GLFW_JOYSTICK_4 3
$DEFINE GLFW_JOYSTICK_5 4
$DEFINE GLFW_JOYSTICK_6 5
$DEFINE GLFW_JOYSTICK_7 6
$DEFINE GLFW_JOYSTICK_8 7
$DEFINE GLFW_JOYSTICK_9 8
$DEFINE GLFW_JOYSTICK_10 9
$DEFINE GLFW_JOYSTICK_11 10
$DEFINE GLFW_JOYSTICK_12 11
$DEFINE GLFW_JOYSTICK_13 12
$DEFINE GLFW_JOYSTICK_14 13
$DEFINE GLFW_JOYSTICK_15 14
$DEFINE GLFW_JOYSTICK_16 15
$DEFINE GLFW_JOYSTICK_LAST 15
$DEFINE GLFW_WINDOW &h00010001
$DEFINE GLFW_FULLSCREEN &h00010002
$DEFINE GLFW_OPENED &h00020001
$DEFINE GLFW_ACTIVE &h00020002
$DEFINE GLFW_ICONIFIED &h00020003
$DEFINE GLFW_ACCELERATED &h00020004
$DEFINE GLFW_RED_BITS &h00020005
$DEFINE GLFW_GREEN_BITS &h00020006
$DEFINE GLFW_BLUE_BITS &h00020007
$DEFINE GLFW_ALPHA_BITS &h00020008
$DEFINE GLFW_DEPTH_BITS &h00020009
$DEFINE GLFW_STENCIL_BITS &h0002000A
$DEFINE GLFW_REFRESH_RATE &h0002000B
$DEFINE GLFW_ACCUM_RED_BITS &h0002000C
$DEFINE GLFW_ACCUM_GREEN_BITS &h0002000D
$DEFINE GLFW_ACCUM_BLUE_BITS &h0002000E
$DEFINE GLFW_ACCUM_ALPHA_BITS &h0002000F
$DEFINE GLFW_AUX_BUFFERS &h00020010
$DEFINE GLFW_STEREO &h00020011
$DEFINE GLFW_MOUSE_CURSOR &h00030001
$DEFINE GLFW_STICKY_KEYS &h00030002
$DEFINE GLFW_STICKY_MOUSE_BUTTONS &h00030003
$DEFINE GLFW_SYSTEM_KEYS &h00030004
$DEFINE GLFW_KEY_REPEAT &h00030005
$DEFINE GLFW_AUTO_POLL_EVENTS &h00030006
$DEFINE GLFW_WAIT &h00040001
$DEFINE GLFW_NOWAIT &h00040002
$DEFINE GLFW_PRESENT &h00050001
$DEFINE GLFW_AXES &h00050002
$DEFINE GLFW_BUTTONS &h00050003
$DEFINE GLFW_NO_RESCALE_BIT &h00000001
$DEFINE GLFW_ORIGIN_UL_BIT &h00000002
$DEFINE GLFW_BUILD_MIPMAPS_BIT &h00000004
$DEFINE GLFW_INFINITY 100000.0

type GLFWvidmode
	Width      as integer
	Height     as integer
	RedBits    as integer
	BlueBits   as integer
	GreenBits  as integer
end type

type GLFWimage
	Width      as integer
	Height     as integer
	Format     as integer
	BytesPerPixel as integer
	Data       as long		'ubyte ptr (in array)
end type

$DEFINE GLFWthread integer
$DEFINE GLFWmutex long	'as any ptr
$DEFINE GLFWcond long	'as any ptr
'  Function pointers not implemented in RapidQ, use built-in native event handlers instead
'type GLFWwindowsizefun as sub (byval as integer, byval as integer)                  'Form.OnResize
'type GLFWmousebuttonfun as sub (byval as integer, byval as integer)                 'Form.OnMouseDown
'type GLFWmouseposfun as sub (byval as integer, byval as integer)                    'Form.OnMouseMove
'type GLFWmousewheelfun as sub (byval as integer)                                    'FormEx.OnMouseWheel
'type GLFWkeyfun as sub (byval as integer, byval as integer)                         'Form.OnKeyDown
'type GLFWcharfun as sub (byval as integer, byval as integer)                        'Form.OnKeyDown
'type GLFWthreadfun as sub (byval as any ptr)                                        'Timer.OnTimer

declare function glfwInit LIB "glfw.dll" ALIAS "glfwInit" () as integer
declare sub glfwTerminate LIB "glfw.dll" ALIAS "glfwTerminate" ()
declare sub glfwGetVersion LIB "glfw.dll" ALIAS "glfwGetVersion" (byref major as integer, byref minor as integer, byref rev as integer)
declare function glfwOpenWindow LIB "glfw.dll" ALIAS "glfwOpenWindow" (byval width as integer, byval height as integer, byval redbits as integer, byval greenbits as integer, byval bluebits as integer, byval alphabits as integer, byval depthbits as integer, byval stencilbits as integer, byval mode as integer) as integer
declare sub glfwOpenWindowHint LIB "glfw.dll" ALIAS "glfwOpenWindowHint" (byval target as integer, byval hint as integer)
declare sub glfwCloseWindow LIB "glfw.dll" ALIAS "glfwCloseWindow" ()
declare sub glfwSetWindowTitle LIB "glfw.dll" ALIAS "glfwSetWindowTitle" (byval title as string)
declare sub glfwGetWindowSize LIB "glfw.dll" ALIAS "glfwGetWindowSize" (byref width as integer, byref height as integer)
declare sub glfwSetWindowSize LIB "glfw.dll" ALIAS "glfwSetWindowSize" (byval width as integer, byval height as integer)
declare sub glfwSetWindowPos LIB "glfw.dll" ALIAS "glfwSetWindowPos" (byval x as integer, byval y as integer)
declare sub glfwIconifyWindow LIB "glfw.dll" ALIAS "glfwIconifyWindow" ()
declare sub glfwRestoreWindow LIB "glfw.dll" ALIAS "glfwRestoreWindow" ()
declare sub glfwSwapBuffers LIB "glfw.dll" ALIAS "glfwSwapBuffers" ()
declare sub glfwSwapInterval LIB "glfw.dll" ALIAS "glfwSwapInterval" (byval interval as integer)
declare function glfwGetWindowParam LIB "glfw.dll" ALIAS "glfwGetWindowParam" (byval param as integer) as integer

declare function glfwGetVideoModes LIB "glfw.dll" ALIAS "glfwGetVideoModes" (list as GLFWvidmode, byval maxcount as integer) as integer
declare sub glfwGetDesktopMode LIB "glfw.dll" ALIAS "glfwGetDesktopMode" (mode as GLFWvidmode)
declare sub glfwPollEvents LIB "glfw.dll" ALIAS "glfwPollEvents" ()
declare function glfwGetKey LIB "glfw.dll" ALIAS "glfwGetKey" (byval key as integer) as integer
declare function glfwGetMouseButton LIB "glfw.dll" ALIAS "glfwGetMouseButton" (byval button as integer) as integer
declare sub glfwGetMousePos LIB "glfw.dll" ALIAS "glfwGetMousePos" (byref xpos as integer, byref ypos as integer)
declare sub glfwSetMousePos LIB "glfw.dll" ALIAS "glfwSetMousePos" (byval xpos as integer, byval ypos as integer)
declare function glfwGetMouseWheel LIB "glfw.dll" ALIAS "glfwGetMouseWheel" () as integer
declare sub glfwSetMouseWheel LIB "glfw.dll" ALIAS "glfwSetMouseWheel" (byval pos as integer)


declare function glfwGetJoystickParam LIB "glfw.dll" ALIAS "glfwGetJoystickParam" (byval joy as integer, byval param as integer) as integer
declare function glfwGetJoystickPos LIB "glfw.dll" ALIAS "glfwGetJoystickPos" (byval joy as integer, byref pos as single, byval numaxes as integer) as integer
declare function glfwGetJoystickButtons LIB "glfw.dll" ALIAS "glfwGetJoystickButtons" (byval joy as integer, byref buttons as BYTE, byval numbuttons as integer) as integer
declare function glfwGetTime LIB "glfw.dll" ALIAS "glfwGetTime" () as double
declare sub glfwSetTime LIB "glfw.dll" ALIAS "glfwSetTime" (byval time as double)
declare sub glfwSleep LIB "glfw.dll" ALIAS "glfwSleep" (byval time as double)
declare function glfwExtensionSupported LIB "glfw.dll" ALIAS "glfwExtensionSupported" (byval extension as string) as integer
declare function glfwGetProcAddress LIB "glfw.dll" ALIAS "glfwGetProcAddress" (byval procname as string) as long		'any ptr
declare sub glfwGetGLVersion LIB "glfw.dll" ALIAS "glfwGetGLVersion" (byref major as integer, byref minor as integer, byref rev as integer)

declare function glfwCreateCond LIB "glfw.dll" ALIAS "glfwCreateCond" () as GLFWcond
declare sub glfwDestroyCond LIB "glfw.dll" ALIAS "glfwDestroyCond" (byval cond as GLFWcond)
declare sub glfwWaitCond LIB "glfw.dll" ALIAS "glfwWaitCond" (byval cond as GLFWcond, byval mutex as GLFWmutex, byval timeout as double)
declare sub glfwSignalCond LIB "glfw.dll" ALIAS "glfwSignalCond" (byval cond as GLFWcond)
declare sub glfwBroadcastCond LIB "glfw.dll" ALIAS "glfwBroadcastCond" (byval cond as GLFWcond)
declare function glfwGetNumberOfProcessors LIB "glfw.dll" ALIAS "glfwGetNumberOfProcessors" () as integer

' Enable/disable functions
declare sub glfwEnable LIB "glfw.dll" ALIAS "glfwEnable" (byval token as integer)
declare sub glfwDisable LIB "glfw.dll" ALIAS "glfwDisable" (byval token as integer)

' Image/texture I/O support
declare function glfwReadImage LIB "glfw.dll" ALIAS "glfwReadImage" (byval name as string, img as GLFWimage, byval flags as integer) as integer
declare sub glfwFreeImage LIB "glfw.dll" ALIAS "glfwFreeImage" (img as GLFWimage)
declare function glfwLoadTexture2D LIB "glfw.dll" ALIAS "glfwLoadTexture2D" (byval name as string, byval flags as integer) as integer


'declare sub glfwSetWindowSizeCallback LIB "glfw.dll" ALIAS "glfwSetWindowSizeCallback" (byval cbfun as GLFWwindowsizefun)
'declare sub glfwSetMouseButtonCallback LIB "glfw.dll" ALIAS "glfwSetMouseButtonCallback" (byval cbfun as GLFWmousebuttonfun)
'declare sub glfwSetMousePosCallback LIB "glfw.dll" ALIAS "glfwSetMousePosCallback" (byval cbfun as GLFWmouseposfun)
'declare sub glfwSetMouseWheelCallback LIB "glfw.dll" ALIAS "glfwSetMouseWheelCallback" (byval cbfun as GLFWmousewheelfun)
'declare sub glfwSetKeyCallback LIB "glfw.dll" ALIAS "glfwSetKeyCallback" (byval cbfun as GLFWkeyfun)
'declare sub glfwSetCharCallback LIB "glfw.dll" ALIAS "glfwSetCharCallback" (byval cbfun as GLFWcharfun)
'Threads, use QTimer instead
'declare function glfwCreateThread LIB "glfw.dll" ALIAS "glfwCreateThread" (byval fun as GLFWthreadfun, byval arg as any ptr) as GLFWthread
'declare sub glfwDestroyThread LIB "glfw.dll" ALIAS "glfwDestroyThread" (byval ID as GLFWthread)
'declare function glfwWaitThread LIB "glfw.dll" ALIAS "glfwWaitThread" (byval ID as GLFWthread, byval waitmode as integer) as integer
'declare function glfwGetThreadID LIB "glfw.dll" ALIAS "glfwGetThreadID" () as GLFWthread
'declare function glfwCreateMutex LIB "glfw.dll" ALIAS "glfwCreateMutex" () as GLFWmutex
'declare sub glfwDestroyMutex LIB "glfw.dll" ALIAS "glfwDestroyMutex" (byval mutex as GLFWmutex)
'declare sub glfwLockMutex LIB "glfw.dll" ALIAS "glfwLockMutex" (byval mutex as GLFWmutex)
'declare sub glfwUnlockMutex LIB "glfw.dll" ALIAS "glfwUnlockMutex" (byval mutex as GLFWmutex)


$endif
