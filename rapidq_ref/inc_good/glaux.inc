'--------------------------------------------------------------------------
'  GLAUX.INC -- Part of the OpenGL32 API Includes  for PB/DLL 6.0 Release 4
'  [gl.h, glu.h, glaux.h + wgl API]
'  Copyright 1999 sublevel6.
'  Portions copyright Silicon Graphics and Microsoft.
'
'  Release date: Saturday, December 11, 1999
'  Homepage:     http://ryme.future.easyspace.com/
'  E-Mail:       dinky@pmail.net (to Dinky)
'                angus_law@hotmail.com (to rYme)
'--------------------------------------------------------------------------
'Converted for use in RapidQ by Kris Dawson/2001
'Email: cooldaddyk7@hotmail.com
'/*
' * (c) Copyright 1993, Silicon Graphics, Inc.
' * All RIGHTS RESERVED
' * Permission To use, copy, modify, And distribute this software For
' * LONG purpose And without fee is hereby granted, provided that the above
' * copyright notice appear In All copies And that both the copyright notice
' * And this permission notice appear In supporting documentation, And that
' * the Name of Silicon Graphics, Inc. Not be used In advertising
' * Or publicity pertaining To distribution of the software without specific,
' * written prior permission.
' *
' * THE MATERIAL EMBODIED On THIS SOFTWARE IS PROVIDED To YOU "AS-IS"
' * And WITHOUT WARRANTY OF LONG KIND, EXPRESS, IMPLIED Or OTHERWISE,
' * INCLUDING WITHOUT LIMITATION, LONG WARRANTY OF MERCHANTABILITY Or
' * FITNESS For A PARTICULAR PURPOSE.  In NO EVENT SHALL SILICON
' * GRAPHICS, INC.  BE LIABLE To YOU Or LONGONE Else For LONG DIRECT,
' * SPECIAL, INCIDENTAL, INDIRECT Or CONSEQUENTIAL DAMAGES OF LONG
' * KIND, Or LONG DAMAGES WHATSOEVER, INCLUDING WITHOUT LIMITATION,
' * LOSS OF PROFIT, LOSS OF USE, SAVINGS Or REVENUE, Or THE CLAIMS OF
' * THIRD PARTIES, WHETHER Or Not SILICON GRAPHICS, INC.  HAS BEEN
' * ADVISED OF THE POSSIBILITY OF SUCH LOSS, HOWEVER CAUSED And On
' * LONG THEORY OF LIABILITY, ARISING OUT OF Or In CONNECTION With THE
' * POSSESSION, USE Or PERFORMANCE OF THIS SOFTWARE.
' *
' * US Government Users Restricted Rights
' * Use, duplication, Or disclosure by the Government is subject To
' * restrictions Set forth In FAR 52.227.19(c)(2) Or subparagraph
' * (c)(1)(ii) of the Rights In Technical Data And Computer Software
' * clause At DFARS 252.227-7013 And/Or In similar Or successor
' * clauses In the FAR Or the DOD Or NASA FAR Supplement.
' * Unpublished-- rights reserved under the copyright laws of the
' * United States.  Contractor/manufacturer is Silicon Graphics,
' * Inc., 2011 N.  Shoreline Blvd., Mountain View, CA 94039-7311.
' *
' * OpenGL(TM) is a trademark of Silicon Graphics, Inc.
' */

'#IFNDEF(GL_INC)
'  $INCLUDE "gl/gl.inc"
'#ENDIF

Const GLAUX_INC         = 1

Const AUX_RGB           = 0
Const AUX_RGBA          = AUX_RGB
Const AUX_INDEX         = 1
Const AUX_SINGLE        = 0
Const AUX_DOUBLE        = 2
Const AUX_DIRECT        = 0
Const AUX_INDIRECT      = 4

Const AUX_ACCUM         = 8
Const AUX_ALPHA         = 16
Const AUX_DEPTH24       = 32
Const AUX_STENCIL       = 64
Const AUX_AUX           = 128
Const AUX_DEPTH16       = 256
Const AUX_FIXED_332_PAL = 512
Const AUX_DEPTH         = AUX_DEPTH16

Const AUX_EXPOSE        = 1
Const AUX_CONFIG        = 2
Const AUX_DRAW          = 4
Const AUX_KEYEVENT      = 8
Const AUX_MOUSEDOWN     = 16
Const AUX_MOUSEUP       = 32
Const AUX_MOUSELOC      = 64

Const AUX_WINDOWX       = 0
Const AUX_WINDOWY       = 1
Const AUX_MOUSEX        = 0
Const AUX_MOUSEY        = 1
Const AUX_MOUSESTATUS   = 3
Const AUX_KEY           = 0
Const AUX_KEYSTATUS     = 1

Const AUX_LEFTBUTTON    = 1
Const AUX_RIGHTBUTTON   = 2
Const AUX_MIDDLEBUTTON  = 4
Const AUX_SHIFT         = 1
Const AUX_CONTROL       = 2


Const AUX_RETURN        = &H0D
Const AUX_ESCAPE        = &H1B
Const AUX_SPACE         = &H20
Const AUX_LEFT          = &H25
Const AUX_UP            = &H26
Const AUX_RIGHT         = &H27
Const AUX_DOWN          = &H28
Const AUX_A             = "A"
Const AUX_B             = "B"
Const AUX_C             = "C"
Const AUX_D             = "D"
Const AUX_E             = "E"
Const AUX_F             = "F"
Const AUX_G             = "G"
Const AUX_H             = "H"
Const AUX_I             = "I"
Const AUX_J             = "J"
Const AUX_K             = "K"
Const AUX_L             = "L"
Const AUX_M             = "M"
Const AUX_N             = "N"
Const AUX_O             = "O"
Const AUX_P             = "P"
Const AUX_Q             = "Q"
Const AUX_R             = "R"
Const AUX_S             = "S"
Const AUX_T             = "T"
Const AUX_U             = "U"
Const AUX_V             = "V"
Const AUX_W             = "W"
Const AUX_X             = "X"
Const AUX_Y             = "Y"
Const AUX_Z             = "Z"
Const AUX_sa            = "a"
Const AUX_sb            = "b"
Const AUX_sc            = "c"
Const AUX_sd            = "d"
Const AUX_se            = "e"
Const AUX_sf            = "f"
Const AUX_sg            = "g"
Const AUX_sh            = "h"
Const AUX_si            = "i"
Const AUX_sj            = "j"
Const AUX_sk            = "k"
Const AUX_sl            = "l"
Const AUX_sm            = "m"
Const AUX_sn            = "n"
Const AUX_so            = "o"
Const AUX_sp            = "p"
Const AUX_sq            = "q"
Const AUX_sr            = "r"
Const AUX_ss            = "s"
Const AUX_st            = "t"
Const AUX_su            = "u"
Const AUX_sv            = "v"
Const AUX_sw            = "w"
Const AUX_sx            = "x"
Const AUX_sy            = "y"
Const AUX_sz            = "z"
Const AUX_0             = "0"
Const AUX_1             = "1"
Const AUX_2             = "2"
Const AUX_3             = "3"
Const AUX_4             = "4"
Const AUX_5             = "5"
Const AUX_6             = "6"
Const AUX_7             = "7"
Const AUX_8             = "8"
Const AUX_9             = "9"

Const AUX_FD            = 1
Const AUX_COLORMAP      = 3
Const AUX_GREYSCALEMAP  = 4
Const AUX_FOGMAP        = 5
Const AUX_ONECOLOR      = 6

Const AUX_BLACK         = 0
Const AUX_RED           = 13
Const AUX_GREEN         = 14
Const AUX_YELLOW        = 15
Const AUX_BLUE          = 16
Const AUX_MAGENTA       = 17
Const AUX_CYAN          = 18
Const AUX_WHITE         = 19


'enum {
'    AUX_USE_ID = 1,
'    AUX_EXACT_MATCH,
'    'AUX_MINIMUM_CRITERIA
'};

Const AUX_USE_ID = 1 ' ?
Const AUX_EXACT_MATCH = 2 ' ?
Const AUX_MINIMUM_CRITERIA = 3 ' ?

TYPE AUX_EVENTREC
  event    AS LONG
  ndata(3) AS LONG
END TYPE

TYPE AUX_RGBImageRec
  sizeX AS LONG
  sizeY AS LONG
  nData AS LONG 
END TYPE


DECLARE SUB auxInitDisplayMode           LIB "rqglaux.dll" ALIAS "auxInitDisplayMode"       (BYVAL a AS DWORD)
DECLARE SUB auxInitPosition              LIB "rqglaux.dll" ALIAS "auxInitPosition"          (BYVAL a AS LONG, BYVAL b AS LONG, BYVAL c AS LONG, BYVAL d AS LONG)
DECLARE FUNCTION auxInitWindow           LIB "rqglaux.dll" ALIAS "auxInitWindowA"           (a AS STRING) AS DWORD
DECLARE SUB auxCloseWindow               LIB "rqglaux.dll" ALIAS "auxCloseWindow"           ()
DECLARE SUB auxQuit                      LIB "rqglaux.dll" ALIAS "auxQuit"                  ()
DECLARE SUB auxSwapBuffers               LIB "rqglaux.dll" ALIAS "auxSwapBuffers"           ()
DECLARE SUB auxMainLoop                  LIB "rqglaux.dll" ALIAS "auxMainLoop"              (BYVAL a AS LONG)
DECLARE SUB auxExposeFunc                LIB "rqglaux.dll" ALIAS "auxExposeFunc"            (BYVAL a AS LONG)
DECLARE SUB auxReshapeFunc               LIB "rqglaux.dll" ALIAS "auxReshapeFunc"           (BYVAL a AS LONG)
DECLARE SUB auxIdleFunc                  LIB "rqglaux.dll" ALIAS "auxIdleFunc"              (BYVAL a AS LONG)
DECLARE SUB auxKeyFunc                   LIB "rqglaux.dll" ALIAS "auxKeyFunc"               (BYVAL a AS LONG, BYVAL b AS LONG)
DECLARE SUB auxMouseFunc                 LIB "rqglaux.dll" ALIAS "auxMouseFunc"             (BYVAL a AS LONG, BYVAL b AS LONG, BYVAL c AS LONG)
DECLARE FUNCTION auxGetColorMapSize      LIB "rqglaux.dll" ALIAS "auxGetColorMapSize"       () AS LONG
DECLARE SUB auxGetMouseLoc               LIB "rqglaux.dll" ALIAS "auxGetMouseLoc"           (a AS LONG, b AS LONG)
DECLARE SUB auxSetOneColor               LIB "rqglaux.dll" ALIAS "auxSetOneColor"           (BYVAL a AS LONG, BYVAL b AS SINGLE, BYVAL c AS SINGLE, BYVAL d AS SINGLE)
DECLARE SUB auxSetFogRamp                LIB "rqglaux.dll" ALIAS "auxSetFogRamp"            (BYVAL a AS LONG, BYVAL b AS LONG)
DECLARE SUB auxSetGreyRamp               LIB "rqglaux.dll" ALIAS "auxSetGreyRamp"           ()
DECLARE SUB auxSetRGBMap                 LIB "rqglaux.dll" ALIAS "auxSetRGBMap"             (BYVAL a AS LONG, b AS SINGLE)
DECLARE FUNCTION auxRGBImageLoad         LIB "rqglaux.dll" ALIAS "auxRGBImageLoadA"         (a AS STRING) AS LONG
DECLARE FUNCTION auxDIBImageLoad         LIB "rqglaux.dll" ALIAS "auxDIBImageLoadA"         (a AS STRING) AS LONG
DECLARE SUB auxCreateFont                LIB "rqglaux.dll" ALIAS "auxCreateFont"            ()
DECLARE SUB auxDrawStr                   LIB "rqglaux.dll" ALIAS "auxDrawStrA"              (a AS STRING)
DECLARE SUB auxWireSphere                LIB "rqglaux.dll" ALIAS "auxWireSphere"            (BYVAL a AS DOUBLE)
DECLARE SUB auxSolidSphere               LIB "rqglaux.dll" ALIAS "auxSolidSphere"           (BYVAL a AS DOUBLE)
DECLARE SUB auxWireCube                  LIB "rqglaux.dll" ALIAS "auxWireCube"              (BYVAL a AS DOUBLE)
DECLARE SUB auxSolidCube                 LIB "rqglaux.dll" ALIAS "auxSolidCube"             (BYVAL a AS DOUBLE)
DECLARE SUB auxWireBox                   LIB "rqglaux.dll" ALIAS "auxWireBox"               (BYVAL a AS DOUBLE, BYVAL b AS DOUBLE, BYVAL c AS DOUBLE)
DECLARE SUB auxSolidBox                  LIB "rqglaux.dll" ALIAS "auxSolidBox"              (BYVAL a AS DOUBLE, BYVAL b AS DOUBLE, BYVAL c AS DOUBLE)
DECLARE SUB auxWireTorus                 LIB "rqglaux.dll" ALIAS "auxWireTorus"             (BYVAL a AS DOUBLE, BYVAL b AS DOUBLE)
DECLARE SUB auxSolidTorus                LIB "rqglaux.dll" ALIAS "auxSolidTorus"            (BYVAL a AS DOUBLE, BYVAL b AS DOUBLE)
DECLARE SUB auxWireCylinder              LIB "rqglaux.dll" ALIAS "auxWireCylinder"          (BYVAL a AS DOUBLE, BYVAL b AS DOUBLE)
DECLARE SUB auxSolidCylinder             LIB "rqglaux.dll" ALIAS "auxSolidCylinder"         (BYVAL a AS DOUBLE, BYVAL b AS DOUBLE)
DECLARE SUB auxWireIcosahedron           LIB "rqglaux.dll" ALIAS "auxWireIcosahedron"       (BYVAL a AS DOUBLE)
DECLARE SUB auxSolidIcosahedron          LIB "rqglaux.dll" ALIAS "auxSolidIcosahedron"      (BYVAL a AS DOUBLE)
DECLARE SUB auxWireOctahedron            LIB "rqglaux.dll" ALIAS "auxWireOctahedron"        (BYVAL a AS DOUBLE)
DECLARE SUB auxSolidOctahedron           LIB "rqglaux.dll" ALIAS "auxSolidOctahedron"       (BYVAL a AS DOUBLE)
DECLARE SUB auxWireTetrahedron           LIB "rqglaux.dll" ALIAS "auxWireTetrahedron"       (BYVAL a AS DOUBLE)
DECLARE SUB auxSolidTetrahedron          LIB "rqglaux.dll" ALIAS "auxSolidTetrahedron"      (BYVAL a AS DOUBLE)
DECLARE SUB auxWireDodecahedron          LIB "rqglaux.dll" ALIAS "auxWireDodecahedron"      (BYVAL a AS DOUBLE)
DECLARE SUB auxSolidDodecahedron         LIB "rqglaux.dll" ALIAS "auxSolidDodecahedron"     (BYVAL a AS DOUBLE)
DECLARE SUB auxWireCone                  LIB "rqglaux.dll" ALIAS "auxWireCone"              (BYVAL a AS DOUBLE, BYVAL b AS DOUBLE)
DECLARE SUB auxSolidCone                 LIB "rqglaux.dll" ALIAS "auxSolidCone"             (BYVAL a AS DOUBLE, BYVAL b AS DOUBLE)
DECLARE SUB auxWireTeapot                LIB "rqglaux.dll" ALIAS "auxWireTeapot"            (BYVAL a AS DOUBLE)
DECLARE SUB auxSolidTeapot               LIB "rqglaux.dll" ALIAS "auxSolidTeapot"           (BYVAL a AS DOUBLE)
DECLARE FUNCTION auxGetHWND              LIB "rqglaux.dll" ALIAS "auxGetHWND"               () AS LONG
DECLARE FUNCTION auxGetHDC               LIB "rqglaux.dll" ALIAS "auxGetHDC"                () AS LONG
DECLARE FUNCTION auxGetHGLRC             LIB "rqglaux.dll" ALIAS "auxGetHGLRC"              () AS LONG
DECLARE SUB auxInitDisplayModePolicy     LIB "rqglaux.dll" ALIAS "auxInitDisplayModePolicy" (BYVAL a AS DWORD)
DECLARE FUNCTION auxInitDisplayModeID    LIB "rqglaux.dll" ALIAS "auxInitDisplayModeID"     (BYVAL a AS LONG) AS DWORD
DECLARE FUNCTION auxGetDisplayModePolicy LIB "rqglaux.dll" ALIAS "auxGetDisplayModePolicy"  () AS DWORD
DECLARE FUNCTION auxGetDisplayModeID     LIB "rqglaux.dll" ALIAS "auxGetDisplayModeID"      () AS LONG
DECLARE FUNCTION auxGetDisplayMode       LIB "rqglaux.dll" ALIAS "auxGetDisplayMode"        () AS DWORD


FUNCTION AUX_WIND_IS_RGB(BYVAL x AS LONG) AS LONG
  'FUNCTION = ((x AND AUX_INDEX) = 0)
END FUNCTION

FUNCTION AUX_WIND_IS_INDEX(BYVAL x AS LONG) AS LONG
  'FUNCTION = ((x AND AUX_INDEX) <> 0)
END FUNCTION

FUNCTION AUX_WIND_IS_SINGLE(BYVAL x AS LONG) AS LONG
  'FUNCTION = ((x AND AUX_DOUBLE) = 0)
END FUNCTION

FUNCTION AUX_WIND_IS_DOUBLE(BYVAL x AS LONG) AS LONG
  'FUNCTION = ((x AND AUX_DOUBLE) <> 0)
END FUNCTION

FUNCTION AUX_WIND_IS_INDIRECT(BYVAL x AS LONG) AS LONG
  'FUNCTION = ((x AND AUX_INDIRECT) <> 0)
END FUNCTION

FUNCTION AUX_WIND_IS_DIRECT(BYVAL x AS LONG) AS LONG
  'FUNCTION = ((x AND AUX_INDIRECT) = 0)
END FUNCTION

FUNCTION AUX_WIND_HAS_ACCUM(BYVAL x AS LONG) AS LONG
  'FUNCTION = ((x AND AUX_ACCUM) <> 0)
END FUNCTION

FUNCTION AUX_WIND_HAS_ALPHA(BYVAL x AS LONG) AS LONG
  'FUNCTION = ((x AND AUX_ALPHA) <> 0)
END FUNCTION

FUNCTION AUX_WIND_HAS_DEPTH(BYVAL x AS LONG) AS LONG
 ' FUNCTION = ((x AND (AUX_DEPTH24 OR AUX_DEPTH16)) <> 0)
END FUNCTION

FUNCTION AUX_WIND_HAS_STENCIL(BYVAL x AS LONG) AS LONG
  'FUNCTION = ((x AND AUX_STENCIL) <> 0)
END FUNCTION

FUNCTION AUX_WIND_USES_FIXED_332_PAL(BYVAL x AS LONG) AS LONG
  'FUNCTION = ((x AND AUX_FIXED_332_PAL) <> 0)
END FUNCTION


DIM auxRGBMap() AS SINGLE

FUNCTION AUX_SETCOLOR(BYVAL x AS LONG, BYVAL y AS LONG) AS LONG
  DIM auxRGBMap(19, 2)

  IF AUX_WIND_IS_RGB(x) THEN
    glColor3fv auxRGBMap(y, 0)
  ELSE
    glIndexf y
  END IF
  'FUNCTION = 0 ' fvck knows what it should return
END FUNCTION

