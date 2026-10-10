'-----------------------------------------------------------------------
'  GLU.INC -- Part of the OpenGL32 API Includes for PB/DLL 6.0 Release 4
'  [gl.h, glu.h, glaux.h + wgl API]
'  Copyright 1999 sublevel6.
'  Portions copyright Silicon Graphics and Microsoft.
'
'  Release date: Saturday, December 11, 1999
'  Homepage:     http://ryme.future.easyspace.com/
'  E-Mail:       dinky@pmail.net (to Dinky)
'                angus_law@hotmail.com (to rYme)
'-----------------------------------------------------------------------
'Converted for use in RapidQ by Kris Dawson
'email: cooldaddyk7@hotmail.com
'/*
'** Copyright 1991-1993, Silicon Graphics, Inc.
'** All Rights Reserved.
'** 
'** This is UNPUBLISHED PROPRIETARY SOURCE CODE of Silicon Graphics, Inc.;
'** the contents of this file may not be disclosed to third parties, copied or
'** duplicated in LONG form, in whole or in part, without the prior written
'** permission of Silicon Graphics, Inc.
'** 
'** RESTRICTED RIGHTS LEGEND:
'** Use, duplication or disclosure by the Government is subject to restrictions
'** as set forth in subdivision (c)(1)(ii) of the Rights in Technical Data
'** and Computer Software clause at DFARS 252.227-7013, and/or in similar or
'** successor clauses in the FAR, DOD or NASA FAR Supplement. Unpublished -
'** rights reserved under the Copyright Laws of the United States.
'*/

#IFNDEF(Const GL_INC)
  $INCLUDE "gl/gl.inc"
#ENDIF

Const GLU_INC                         = 1

Const GLU_VERSION_1_1                 = 1
Const GLU_VERSION_1_2                 = 1

Const GLU_INVALID_ENUM                = 100900
Const GLU_INVALID_VALUE               = 100901
Const GLU_OUT_OF_MEMORY               = 100902
Const GLU_INCOMPATIBLE_GL_VERSION     = 100903

Const GLU_VERSION                     = 100800
Const GLU_EXTENSIONS                  = 100801

Const GLU_TRUE                        = GL_TRUE
Const GLU_FALSE                       = GL_FALSE

Const GLU_SMOOTH                      = 100000
Const GLU_FLAT                        = 100001
Const GLU_NONE                        = 100002

Const GLU_POINT                       = 100010
Const GLU_LINE                        = 100011
Const GLU_FILL                        = 100012
Const GLU_SILHOUETTE                  = 100013

Const GLU_OUTSIDE                     = 100020
Const GLU_INSIDE                      = 100021

'GLOBAL GLU_TESS_MAX_COORD AS DOUBLE
'GLU_TESS_MAX_COORD              = 1.0e150

Const GLU_TESS_WINDING_RULE           = 100140
Const GLU_TESS_BOUNDARY_ONLY          = 100141
Const GLU_TESS_TOLERANCE              = 100142

Const GLU_TESS_WINDING_ODD            = 100130
Const GLU_TESS_WINDING_NONZERO        = 100131
Const GLU_TESS_WINDING_POSITIVE       = 100132
Const GLU_TESS_WINDING_NEGATIVE       = 100133
Const GLU_TESS_WINDING_ABS_GEQ_TWO    = 100134

Const GLU_TESS_BEGIN                  = 100100
Const GLU_TESS_VERTEX                 = 100101
Const GLU_TESS_END                    = 100102
Const GLU_TESS_ERROR                  = 100103
Const GLU_TESS_EDGE_FLAG              = 100104
Const GLU_TESS_COMBINE                = 100105

Const GLU_TESS_BEGIN_DATA             = 100106

Const GLU_TESS_VERTEX_DATA            = 100107

Const GLU_TESS_END_DATA               = 100108
Const GLU_TESS_ERROR_DATA             = 100109

Const GLU_TESS_EDGE_FLAG_DATA         = 100110

Const GLU_TESS_COMBINE_DATA           = 100111

Const GLU_TESS_ERROR1                 = 100151
Const GLU_TESS_ERROR2                 = 100152
Const GLU_TESS_ERROR3                 = 100153
Const GLU_TESS_ERROR4                 = 100154
Const GLU_TESS_ERROR5                 = 100155
Const GLU_TESS_ERROR6                 = 100156
Const GLU_TESS_ERROR7                 = 100157
Const GLU_TESS_ERROR8                 = 100158

Const GLU_TESS_MISSING_BEGIN_POLYGON  = GLU_TESS_ERROR1
Const GLU_TESS_MISSING_BEGIN_CONTOUR  = GLU_TESS_ERROR2
Const GLU_TESS_MISSING_END_POLYGON    = GLU_TESS_ERROR3
Const GLU_TESS_MISSING_END_CONTOUR    = GLU_TESS_ERROR4
Const GLU_TESS_COORD_TOO_LARGE        = GLU_TESS_ERROR5
Const GLU_TESS_NEED_COMBINE_CALLBACK  = GLU_TESS_ERROR6

Const GLU_AUTO_LOAD_MATRIX            = 100200
Const GLU_CULLING                     = 100201
Const GLU_SAMPLING_TOLERANCE          = 100203
Const GLU_DISPLAY_MODE                = 100204
Const GLU_PARAMETRIC_TOLERANCE        = 100202
Const GLU_SAMPLING_METHOD             = 100205
Const GLU_U_STEP                      = 100206
Const GLU_V_STEP                      = 100207

Const GLU_PATH_LENGTH                 = 100215
Const GLU_PARAMETRIC_ERROR            = 100216
Const GLU_DOMAIN_DISTANCE             = 100217

Const GLU_MAP1_TRIM_2                 = 100210
Const GLU_MAP1_TRIM_3                 = 100211

Const GLU_OUTLINE_POLYGON             = 100240
Const GLU_OUTLINE_PATCH               = 100241

Const GLU_NURBS_ERROR1                = 100251
Const GLU_NURBS_ERROR2                = 100252
Const GLU_NURBS_ERROR3                = 100253
Const GLU_NURBS_ERROR4                = 100254
Const GLU_NURBS_ERROR5                = 100255
Const GLU_NURBS_ERROR6                = 100256
Const GLU_NURBS_ERROR7                = 100257
Const GLU_NURBS_ERROR8                = 100258
Const GLU_NURBS_ERROR9                = 100259
Const GLU_NURBS_ERROR10               = 100260
Const GLU_NURBS_ERROR11               = 100261
Const GLU_NURBS_ERROR12               = 100262
Const GLU_NURBS_ERROR13               = 100263
Const GLU_NURBS_ERROR14               = 100264
Const GLU_NURBS_ERROR15               = 100265
Const GLU_NURBS_ERROR16               = 100266
Const GLU_NURBS_ERROR17               = 100267
Const GLU_NURBS_ERROR18               = 100268
Const GLU_NURBS_ERROR19               = 100269
Const GLU_NURBS_ERROR20               = 100270
Const GLU_NURBS_ERROR21               = 100271
Const GLU_NURBS_ERROR22               = 100272
Const GLU_NURBS_ERROR23               = 100273
Const GLU_NURBS_ERROR24               = 100274
Const GLU_NURBS_ERROR25               = 100275
Const GLU_NURBS_ERROR26               = 100276
Const GLU_NURBS_ERROR27               = 100277
Const GLU_NURBS_ERROR28               = 100278
Const GLU_NURBS_ERROR29               = 100279
Const GLU_NURBS_ERROR30               = 100280
Const GLU_NURBS_ERROR31               = 100281
Const GLU_NURBS_ERROR32               = 100282
Const GLU_NURBS_ERROR33               = 100283
Const GLU_NURBS_ERROR34               = 100284
Const GLU_NURBS_ERROR35               = 100285
Const GLU_NURBS_ERROR36               = 100286
Const GLU_NURBS_ERROR37               = 100287


Const GLU_CW                          = 100120
Const GLU_CCW                         = 100121
Const GLU_INTERIOR                    = 100122
Const GLU_EXTERIOR                    = 100123
Const GLU_UNKNOWN                     = 100124

Const GLU_BEGIN                       = GLU_TESS_BEGIN
Const GLU_VERTEX                      = GLU_TESS_VERTEX
Const GLU_END                         = GLU_TESS_END
Const GLU_ERROR                       = GLU_TESS_ERROR
Const GLU_EDGE_FLAG                   = GLU_TESS_EDGE_FLAG


DECLARE FUNCTION gluErrorString      LIB "glu32.dll" ALIAS "gluErrorString"          (BYVAL errCode AS DWORD) AS LONG
DECLARE FUNCTION gluGetString        LIB "glu32.dll" ALIAS "gluGetString"            (BYVAL nname AS DWORD) AS LONG
DECLARE SUB gluOrtho2D               LIB "glu32.dll" ALIAS "gluOrtho2D"              (BYVAL nleft AS DOUBLE, BYVAL nright AS DOUBLE, BYVAL nbottom AS DOUBLE, BYVAL ntop AS DOUBLE)
DECLARE SUB gluPerspective           LIB "glu32.dll" ALIAS "gluPerspective"          (BYVAL fovy AS DOUBLE, BYVAL aspect AS DOUBLE, BYVAL zNear AS DOUBLE, BYVAL zFar AS DOUBLE)
DECLARE SUB gluPickMatrix            LIB "glu32.dll" ALIAS "gluPickMatrix"           (BYVAL x AS DOUBLE, BYVAL y AS DOUBLE, BYVAL nwidth AS DOUBLE, BYVAL nheight AS DOUBLE, viewport AS LONG)
DECLARE SUB gluLookAt                LIB "glu32.dll" ALIAS "gluLookAt"               (BYVAL eyex AS DOUBLE, BYVAL eyey AS DOUBLE, BYVAL eyez AS DOUBLE, BYVAL centerx AS DOUBLE, BYVAL centery AS DOUBLE, BYVAL centerz AS DOUBLE, BYVAL upx AS DOUBLE, BYVAL upy AS DOUBLE, BYVAL upz AS DOUBLE)
DECLARE FUNCTION gluProject          LIB "glu32.dll" ALIAS "gluProject"              (BYVAL objx AS DOUBLE, BYVAL objy AS DOUBLE, BYVAL objz AS DOUBLE, BYVAL modelMatrix AS DOUBLE, BYVAL projMatrix AS DOUBLE, BYVAL viewport AS LONG, winx AS DOUBLE, winy AS DOUBLE, winz AS DOUBLE) AS LONG
DECLARE FUNCTION gluUnProject        LIB "glu32.dll" ALIAS "gluUnProject"            (BYVAL winx AS DOUBLE,BYVAL winy AS DOUBLE, BYVAL winz AS DOUBLE, modelMatrix AS LONG, projMatrix AS LONG, viewport AS LONG, objx AS DOUBLE, objy AS DOUBLE, objz AS DOUBLE) AS LONG
DECLARE FUNCTION gluScaleImage       LIB "glu32.dll" ALIAS "gluScaleImage"           (BYVAL nformat AS DWORD, BYVAL widthin AS LONG,BYVAL heightin AS LONG, BYVAL typein AS DWORD, datain AS LONG, BYVAL widthout AS LONG, BYVAL heightout AS LONG, BYVAL typeout AS DWORD, dataout AS LONG) AS LONG
DECLARE FUNCTION gluBuild1DMipmaps   LIB "glu32.dll" ALIAS "gluBuild1DMipmaps"       (BYVAL ntarget AS DWORD, BYVAL components AS LONG, BYVAL nwidth AS LONG, BYVAL nformat AS DWORD, BYVAL ntype AS DWORD, ndata AS LONG) AS LONG
DECLARE FUNCTION gluBuild2DMipmaps   LIB "glu32.dll" ALIAS "gluBuild2DMipmaps"       (BYVAL ntarget AS DWORD, BYVAL components AS LONG, BYVAL nwidth AS LONG, BYVAL nheight AS LONG, BYVAL nformat AS DWORD, BYVAL ntype AS DWORD, ndata AS LONG) AS LONG
DECLARE FUNCTION gluNewQuadric       LIB "glu32.dll" ALIAS "gluNewQuadric"           () AS LONG
DECLARE SUB gluDeleteQuadric         LIB "glu32.dll" ALIAS "gluDeleteQuadric"        (BYVAL state AS LONG)
DECLARE SUB gluQuadricNormals        LIB "glu32.dll" ALIAS "gluQuadricNormals"       (BYVAL quadObject AS LONG, BYVAL normals AS DWORD)
DECLARE SUB gluQuadricTexture        LIB "glu32.dll" ALIAS "gluQuadricTexture"       (BYVAL quadObject AS LONG, textureCoords AS LONG)
DECLARE SUB gluQuadricOrientation    LIB "glu32.dll" ALIAS "gluQuadricOrientation"   (BYVAL quadObject AS LONG, BYVAL orientation AS DWORD)
DECLARE SUB gluQuadricDrawStyle      LIB "glu32.dll" ALIAS "gluQuadricDrawStyle"     (BYVAL quadObject AS LONG, BYVAL drawStyle AS DWORD)
DECLARE SUB gluCylinder              LIB "glu32.dll" ALIAS "gluCylinder"             (BYVAL qobj AS LONG, BYVAL baseRadius AS DOUBLE, BYVAL topRadius AS DOUBLE, BYVAL nheight AS DOUBLE, BYVAL slices AS LONG, BYVAL stacks AS LONG)
DECLARE SUB gluDisk                  LIB "glu32.dll" ALIAS "gluDisk"                 (BYVAL qobj AS LONG, BYVAL innerRadius AS DOUBLE, BYVAL outerRadius AS DOUBLE, BYVAL slices AS LONG, BYVAL loops AS LONG)
DECLARE SUB gluPartialDisk           LIB "glu32.dll" ALIAS "gluPartialDisk"          (BYVAL qobj AS LONG, BYVAL innerRadius AS DOUBLE, BYVAL outerRadius AS DOUBLE, BYVAL slices AS LONG, BYVAL loops AS LONG, BYVAL startAngle AS DOUBLE, BYVAL sweepAngle AS DOUBLE)
DECLARE SUB gluSphere                LIB "glu32.dll" ALIAS "gluSphere"               (BYVAL qobj AS LONG, BYVAL radius AS DOUBLE, BYVAL slices AS LONG, BYVAL stacks AS LONG)
DECLARE SUB gluQuadricCallback       LIB "glu32.dll" ALIAS "gluQuadricCallback"      (BYVAL qobj AS LONG, BYVAL which AS DWORD, BYVAL nfn AS LONG)
DECLARE FUNCTION gluNewTess          LIB "glu32.dll" ALIAS "gluNewTess"              () AS LONG
DECLARE SUB gluDeleteTess            LIB "glu32.dll" ALIAS "gluDeleteTess"           (BYVAL tess AS LONG)
DECLARE SUB gluTessBeginPolygon      LIB "glu32.dll" ALIAS "gluTessBeginPolygon"     (BYVAL tess AS LONG, polygon_data AS LONG)
DECLARE SUB gluTessBeginContour      LIB "glu32.dll" ALIAS "gluTessBeginContour"     (BYVAL tess AS LONG)
DECLARE SUB gluTessVertex            LIB "glu32.dll" ALIAS "gluTessVertex"           (BYVAL tess AS LONG, coords AS LONG, ndata AS LONG)
DECLARE SUB gluTessEndContour        LIB "glu32.dll" ALIAS "gluTessEndContour"       (BYVAL tess AS LONG)
DECLARE SUB gluTessEndPolygon        LIB "glu32.dll" ALIAS "gluTessEndPolygon"       (BYVAL tess AS LONG)
DECLARE SUB gluTessProperty          LIB "glu32.dll" ALIAS "gluTessProperty"         (BYVAL tess AS LONG, BYVAL which AS DWORD, BYVAL value AS DOUBLE)
DECLARE SUB gluTessNormal            LIB "glu32.dll" ALIAS "gluTessNormal"           (BYVAL tess AS LONG, BYVAL x AS DOUBLE, BYVAL y AS DOUBLE, BYVAL z AS DOUBLE)
DECLARE SUB gluTessCallback          LIB "glu32.dll" ALIAS "gluTessCallback"         (BYVAL tess AS LONG, BYVAL which AS DWORD, BYVAL nfn AS LONG)
DECLARE SUB gluGetTessProperty       LIB "glu32.dll" ALIAS "gluGetTessProperty"      (BYVAL tess AS LONG, BYVAL which AS DWORD, value AS DOUBLE)
DECLARE FUNCTION gluNewNurbsRenderer LIB "glu32.dll" ALIAS "gluNewNurbsRenderer"     () AS LONG
DECLARE SUB gluDeleteNurbsRenderer   LIB "glu32.dll" ALIAS "gluDeleteNurbsRenderer"  (BYVAL nobj AS LONG)
DECLARE SUB gluBeginSurface          LIB "glu32.dll" ALIAS "gluBeginSurface"         (BYVAL nobj AS LONG)
DECLARE SUB gluBeginCurve            LIB "glu32.dll" ALIAS "gluBeginCurve"           (BYVAL nobj AS LONG)
DECLARE SUB gluEndCurve              LIB "glu32.dll" ALIAS "gluEndCurve"             (BYVAL nobj AS LONG)
DECLARE SUB gluEndSurface            LIB "glu32.dll" ALIAS "gluEndSurface"           (BYVAL nobj AS LONG)
DECLARE SUB gluBeginTrim             LIB "glu32.dll" ALIAS "gluBeginTrim"            (BYVAL nobj AS LONG)
DECLARE SUB gluEndTrim               LIB "glu32.dll" ALIAS "gluEndTrim"              (BYVAL nobj AS LONG)
DECLARE SUB gluPwlCurve              LIB "glu32.dll" ALIAS "gluPwlCurve"             (BYVAL nobj AS LONG, BYVAL ncount AS LONG, narray AS LONG, BYVAL stride AS LONG, BYVAL ntype AS DWORD)
DECLARE SUB gluNurbsCurve            LIB "glu32.dll" ALIAS "gluNurbsCurve"           (BYVAL nobj AS LONG, BYVAL nknots AS LONG, knot AS LONG, BYVAL stride AS LONG, ctlarray AS LONG, BYVAL order AS LONG, BYVAL ntype AS DWORD)
DECLARE SUB gluNurbsSurface          LIB "glu32.dll" ALIAS "gluNurbsSurface"         (BYVAL nobj AS LONG, BYVAL sknot_count AS LONG, BYVAL sknot AS LONG PTR, BYVAL tknot_count AS LONG, tknot AS LONG, BYVAL s_stride AS LONG, BYVAL t_stride AS LONG, ctlarray AS LONG, BYVAL sorder AS LONG, BYVAL torder AS LONG, BYVAL ntype AS DWORD)
DECLARE SUB gluLoadSamplingMatrices  LIB "glu32.dll" ALIAS "gluLoadSamplingMatrices" (BYVAL nobj AS LONG, modelMatrix AS LONG, projMatrix AS LONG, viewport AS LONG)
DECLARE SUB gluNurbsProperty         LIB "glu32.dll" ALIAS "gluNurbsProperty"        (BYVAL nobj AS LONG, BYVAL property AS DWORD, value AS LONG)
DECLARE SUB gluGetNurbsProperty      LIB "glu32.dll" ALIAS "gluGetNurbsProperty"     (BYVAL nobj AS LONG, BYVAL property AS DWORD, value AS LONG)
DECLARE SUB gluNurbsCallback         LIB "glu32.dll" ALIAS "gluNurbsCallback"        (BYVAL nobj AS LONG, BYVAL which AS DWORD, BYVAL nfn AS LONG)
DECLARE SUB gluBeginPolygon          LIB "glu32.dll" ALIAS "gluBeginPolygon"         (BYVAL tess AS LONG)
DECLARE SUB gluNextContour           LIB "glu32.dll" ALIAS "gluNextContour"          (BYVAL tess AS LONG, BYVAL ntype AS DWORD)
DECLARE SUB gluEndPolygon            LIB "glu32.dll" ALIAS "gluEndPolygon"           (BYVAL tess AS LONG)
