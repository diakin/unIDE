''
''
'' glu -- header translated with help of SWIG FB wrapper, some parts from
''
''
'' NOTICE: This file is part of the FreeBASIC Compiler package and can't
''         be included in other distributions without authorization.
''
''
''   Ported to RapidQ compatible code by JohnK Feb, 2006
''
'* Copyright (c) 2002 by Marcus Geelnard
'*
'* This file was converted from the MinGW32 GL/glu.h include file (using a
'* custom C parser / Visual Basic writer), which in turn is based on the
'* SGI OpenGL sample implementation glu.h include file.
'*************************************************************************
$ifndef __gl_bi

$DEFINE GLenum integer
$DEFINE GLboolean byte
$DEFINE GLbitfield integer
$DEFINE GLvoid long     'normally as any,but usually wants an address
$DEFINE GLbyte byte     'not signed!
$DEFINE GLshort short
$DEFINE GLint integer
$DEFINE GLubyte byte
$DEFINE GLushort word
$DEFINE GLuint dword
$DEFINE GLsizei integer
$DEFINE GLfloat single
$DEFINE GLclampf single     'clamped means 0-1.0
$DEFINE GLdouble double
$DEFINE GLclampd double
$endif

$IFNDEF __glu_inc
$DEFINE __glu_inc


'*************************************************************************
'* This bindings file is for GLU 1.3
'*************************************************************************

$DEFINE GLU_VERSION_1_1 1
$DEFINE GLU_VERSION_1_2 1
$DEFINE GLU_VERSION_1_3 1



'*************************************************************************
'* Constants
'*************************************************************************

' Extensions
$DEFINE GLU_EXT_object_space_tess   1
$DEFINE GLU_EXT_nurbs_tessellator   1

' Boolean
$DEFINE GLU_FALSE      0
$DEFINE GLU_TRUE       1

' StringName
$DEFINE GLU_VERSION   100800
$DEFINE GLU_EXTENSIONS    100801

' ErrorCode
$DEFINE GLU_INVALID_ENUM   100900
$DEFINE GLU_INVALID_VALUE   100901
$DEFINE GLU_OUT_OF_MEMORY   100902
$DEFINE GLU_INVALID_OPERATION   100904

' NurbsDisplay
' $DEFINE GLU_FILL   100012
$DEFINE GLU_OUTLINE_POLYGON   100240
$DEFINE GLU_OUTLINE_PATCH   100241

' NurbsCallback
$DEFINE GLU_NURBS_ERROR   100103
$DEFINE GLU_ERROR   100103
$DEFINE GLU_NURBS_BEGIN   100164
$DEFINE GLU_NURBS_BEGIN_EXT   100164
$DEFINE GLU_NURBS_VERTEX   100165
$DEFINE GLU_NURBS_VERTEX_EXT   100165
$DEFINE GLU_NURBS_NORMAL   100166
$DEFINE GLU_NURBS_NORMAL_EXT   100166
$DEFINE GLU_NURBS_COLOR   100167
$DEFINE GLU_NURBS_COLOR_EXT   100167
$DEFINE GLU_NURBS_TEXTURE_COORD   100168
$DEFINE GLU_NURBS_TEX_COORD_EXT   100168
$DEFINE GLU_NURBS_END   100169
$DEFINE GLU_NURBS_END_EXT   100169
$DEFINE GLU_NURBS_BEGIN_DATA   100170
$DEFINE GLU_NURBS_BEGIN_DATA_EXT   100170
$DEFINE GLU_NURBS_VERTEX_DATA   100171
$DEFINE GLU_NURBS_VERTEX_DATA_EXT   100171
$DEFINE GLU_NURBS_NORMAL_DATA   100172
$DEFINE GLU_NURBS_NORMAL_DATA_EXT   100172
$DEFINE GLU_NURBS_COLOR_DATA   100173
$DEFINE GLU_NURBS_COLOR_DATA_EXT   100173
$DEFINE GLU_NURBS_TEXTURE_COORD_DATA   100174
$DEFINE GLU_NURBS_TEX_COORD_DATA_EXT   100174
$DEFINE GLU_NURBS_END_DATA   100175
$DEFINE GLU_NURBS_END_DATA_EXT   100175

' NurbsError
$DEFINE GLU_NURBS_ERROR1   100251
$DEFINE GLU_NURBS_ERROR2   100252
$DEFINE GLU_NURBS_ERROR3   100253
$DEFINE GLU_NURBS_ERROR4   100254
$DEFINE GLU_NURBS_ERROR5   100255
$DEFINE GLU_NURBS_ERROR6   100256
$DEFINE GLU_NURBS_ERROR7   100257
$DEFINE GLU_NURBS_ERROR8   100258
$DEFINE GLU_NURBS_ERROR9   100259
$DEFINE GLU_NURBS_ERROR10   100260
$DEFINE GLU_NURBS_ERROR11   100261
$DEFINE GLU_NURBS_ERROR12   100262
$DEFINE GLU_NURBS_ERROR13   100263
$DEFINE GLU_NURBS_ERROR14   100264
$DEFINE GLU_NURBS_ERROR15   100265
$DEFINE GLU_NURBS_ERROR16   100266
$DEFINE GLU_NURBS_ERROR17   100267
$DEFINE GLU_NURBS_ERROR18   100268
$DEFINE GLU_NURBS_ERROR19   100269
$DEFINE GLU_NURBS_ERROR20   100270
$DEFINE GLU_NURBS_ERROR21   100271
$DEFINE GLU_NURBS_ERROR22   100272
$DEFINE GLU_NURBS_ERROR23   100273
$DEFINE GLU_NURBS_ERROR24   100274
$DEFINE GLU_NURBS_ERROR25   100275
$DEFINE GLU_NURBS_ERROR26   100276
$DEFINE GLU_NURBS_ERROR27   100277
$DEFINE GLU_NURBS_ERROR28   100278
$DEFINE GLU_NURBS_ERROR29   100279
$DEFINE GLU_NURBS_ERROR30   100280
$DEFINE GLU_NURBS_ERROR31   100281
$DEFINE GLU_NURBS_ERROR32   100282
$DEFINE GLU_NURBS_ERROR33   100283
$DEFINE GLU_NURBS_ERROR34   100284
$DEFINE GLU_NURBS_ERROR35   100285
$DEFINE GLU_NURBS_ERROR36   100286
$DEFINE GLU_NURBS_ERROR37   100287

' NurbsProperty
$DEFINE GLU_AUTO_LOAD_MATRIX   100200
$DEFINE GLU_CULLING   100201
$DEFINE GLU_SAMPLING_TOLERANCE   100203
$DEFINE GLU_DISPLAY_MODE   100204
$DEFINE GLU_PARAMETRIC_TOLERANCE   100202
$DEFINE GLU_SAMPLING_METHOD   100205
$DEFINE GLU_U_STEP   100206
$DEFINE GLU_V_STEP   100207
$DEFINE GLU_NURBS_MODE   100160
$DEFINE GLU_NURBS_MODE_EXT   100160
$DEFINE GLU_NURBS_TESSELLATOR   100161
$DEFINE GLU_NURBS_TESSELLATOR_EXT   100161
$DEFINE GLU_NURBS_RENDERER   100162
$DEFINE GLU_NURBS_RENDERER_EXT   100162

' NurbsSampling
$DEFINE GLU_OBJECT_PARAMETRIC_ERROR   100208
$DEFINE GLU_OBJECT_PARAMETRIC_ERROR_EXT   100208
$DEFINE GLU_OBJECT_PATH_LENGTH   100209
$DEFINE GLU_OBJECT_PATH_LENGTH_EXT   100209
$DEFINE GLU_PATH_LENGTH   100215
$DEFINE GLU_PARAMETRIC_ERROR   100216
$DEFINE GLU_DOMAIN_DISTANCE   100217

' NurbsTrim
$DEFINE GLU_MAP1_TRIM_2   100210
$DEFINE GLU_MAP1_TRIM_3   100211

' QuadricDrawStyle
$DEFINE GLU_POINT   100010
$DEFINE GLU_LINE   100011
$DEFINE GLU_FILL   100012
$DEFINE GLU_SILHOUETTE   100013

' QuadricCallback
' $DEFINE GLU_ERROR   100103

' QuadricNormal
$DEFINE GLU_SMOOTH   100000
$DEFINE GLU_FLAT   100001
$DEFINE GLU_NONE   100002

' QuadricOrientation
$DEFINE GLU_OUTSIDE   100020
$DEFINE GLU_INSIDE   100021

' TessCallback
$DEFINE GLU_TESS_BEGIN   100100
$DEFINE GLU_BEGIN   100100
$DEFINE GLU_TESS_VERTEX   100101
$DEFINE GLU_VERTEX   100101
$DEFINE GLU_TESS_END   100102
$DEFINE GLU_END   100102
$DEFINE GLU_TESS_ERROR   100103
$DEFINE GLU_TESS_EDGE_FLAG   100104
$DEFINE GLU_EDGE_FLAG   100104
$DEFINE GLU_TESS_COMBINE   100105
$DEFINE GLU_TESS_BEGIN_DATA   100106
$DEFINE GLU_TESS_VERTEX_DATA   100107
$DEFINE GLU_TESS_END_DATA   100108
$DEFINE GLU_TESS_ERROR_DATA   100109
$DEFINE GLU_TESS_EDGE_FLAG_DATA   100110
$DEFINE GLU_TESS_COMBINE_DATA   100111

' TessContour
$DEFINE GLU_CW   100120
$DEFINE GLU_CCW   100121
$DEFINE GLU_INTERIOR   100122
$DEFINE GLU_EXTERIOR   100123
$DEFINE GLU_UNKNOWN   100124

' TessProperty
$DEFINE GLU_TESS_WINDING_RULE   100140
$DEFINE GLU_TESS_BOUNDARY_ONLY   100141
$DEFINE GLU_TESS_TOLERANCE   100142

' TessError
$DEFINE GLU_TESS_ERROR1   100151
$DEFINE GLU_TESS_ERROR2   100152
$DEFINE GLU_TESS_ERROR3   100153
$DEFINE GLU_TESS_ERROR4   100154
$DEFINE GLU_TESS_ERROR5   100155
$DEFINE GLU_TESS_ERROR6   100156
$DEFINE GLU_TESS_ERROR7   100157
$DEFINE GLU_TESS_ERROR8   100158
$DEFINE GLU_TESS_MISSING_BEGIN_POLYGON   100151
$DEFINE GLU_TESS_MISSING_BEGIN_CONTOUR   100152
$DEFINE GLU_TESS_MISSING_END_POLYGON   100153
$DEFINE GLU_TESS_MISSING_END_CONTOUR   100154
$DEFINE GLU_TESS_COORD_TOO_LARGE   100155
$DEFINE GLU_TESS_NEED_COMBINE_CALLBACK   100156

' TessWinding
$DEFINE GLU_TESS_WINDING_ODD   100130
$DEFINE GLU_TESS_WINDING_NONZERO   100131
$DEFINE GLU_TESS_WINDING_POSITIVE   100132
$DEFINE GLU_TESS_WINDING_NEGATIVE   100133
$DEFINE GLU_TESS_WINDING_ABS_GEQ_TWO   100134

' Tesselation (misc)
$DEFINE GLU_TESS_MAX_COORD   1E+150

$DEFINE GLUnurbs  long              'type GLUnurbs as any
$DEFINE GLUquadric  long            'type GLUquadric as any
$DEFINE GLUtesselator  long         'type GLUtesselator as any
$DEFINE GLUnurbsObj long         'type GLUnurbsObj as GLUnurbs
$DEFINE GLUquadricObj long       'type GLUquadricObj as GLUquadric
$DEFINE GLUtesselatorObj long    'type GLUtesselatorObj as GLUtesselator
$DEFINE GLUtriangulatorObj long  'type GLUtriangulatorObj as GLUtesselator
'$DEFINE _GLUfuncptr long           'ptr to a function, total trouble in RQ


declare sub gluBeginCurve LIB "glu32.dll" ALIAS "gluBeginCurve" (byref nurb as GLUnurbs)
declare sub gluBeginPolygon LIB "glu32.dll" ALIAS "gluBeginPolygon" (byref tess as GLUtesselator)
declare sub gluBeginSurface LIB "glu32.dll" ALIAS "gluBeginSurface" (byref nurb as GLUnurbs)
declare sub gluBeginTrim LIB "glu32.dll" ALIAS "gluBeginTrim" (byref nurb as GLUnurbs)

declare function gluBuild1DMipmapLevels LIB "glu32.dll" ALIAS "gluBuild1DMipmapLevels" (byval target as GLenum, byval internalFormat as GLint, byval width as GLsizei, byval format as GLenum, byval type as GLenum, byval level as GLint, byval base as GLint, byval max as GLint, byval lpDdata as long) as GLint
declare function gluBuild1DMipmaps LIB "glu32.dll" ALIAS "gluBuild1DMipmaps" (byval target as GLenum, byval internalFormat as GLint, byval width as GLsizei, byval format as GLenum, byval type as GLenum, byval lpDdata as long) as GLint
declare function gluBuild2DMipmapLevels LIB "glu32.dll" ALIAS "gluBuild2DMipmapLevels" (byval target as GLenum, byval internalFormat as GLint, byval width as GLsizei, byval height as GLsizei, byval format as GLenum, byval type as GLenum, byval level as GLint, byval base as GLint, byval max as GLint, byval lpDdata as long) as GLint
declare function gluBuild2DMipmaps LIB "glu32.dll" ALIAS "gluBuild2DMipmaps" (byval target as GLenum, byval internalFormat as GLint, byval width as GLsizei, byval height as GLsizei, byval format as GLenum, byval type as GLenum, byval lpData as long) as GLint
declare function gluBuild3DMipmapLevels LIB "glu32.dll" ALIAS "gluBuild3DMipmapLevels" (byval target as GLenum, byval internalFormat as GLint, byval width as GLsizei, byval height as GLsizei, byval depth as GLsizei, byval format as GLenum, byval type as GLenum, byval level as GLint, byval base as GLint, byval max as GLint, byval lpDdata as long) as GLint
declare function gluBuild3DMipmaps LIB "glu32.dll" ALIAS "gluBuild3DMipmaps" (byval target as GLenum, byval internalFormat as GLint, byval width as GLsizei, byval height as GLsizei, byval depth as GLsizei, byval format as GLenum, byval type as GLenum, byval lpDdata as long) as GLint

declare function gluCheckExtension LIB "glu32.dll" ALIAS "gluCheckExtension" (extName as STRING, extString as STRING) as GLboolean
declare sub gluDeleteNurbsRenderer LIB "glu32.dll" ALIAS "gluDeleteNurbsRenderer" (byref nurb as GLUnurbs)
declare sub gluDeleteQuadric LIB "glu32.dll" ALIAS "gluDeleteQuadric" (quad as GLUquadric)
declare sub gluDeleteTess LIB "glu32.dll" ALIAS "gluDeleteTess" (byref tess as GLUtesselator)
declare sub gluEndCurve LIB "glu32.dll" ALIAS "gluEndCurve" (byref nurb as GLUnurbs)
declare sub gluEndPolygon LIB "glu32.dll" ALIAS "gluEndPolygon" (byref tess as GLUtesselator)
declare sub gluEndSurface LIB "glu32.dll" ALIAS "gluEndSurface" (byref nurb as GLUnurbs)
declare sub gluEndTrim LIB "glu32.dll" ALIAS "gluEndTrim" (byref nurb as GLUnurbs)
declare function gluErrorString LIB "glu32.dll" ALIAS "gluErrorString" (byval error as GLenum) as long
declare sub gluGetNurbsProperty LIB "glu32.dll" ALIAS "gluGetNurbsProperty" (byref nurb as GLUnurbs, byval property as GLenum, byref data as GLfloat)
declare function gluGetString LIB "glu32.dll" ALIAS "gluGetString" (byval name as GLenum) as long
declare sub gluLoadSamplingMatrices LIB "glu32.dll" ALIAS "gluLoadSamplingMatrices" (byref nurb as GLUnurbs, byref model as GLfloat, byref perspective as GLfloat, byref view as GLint)

declare function gluNewNurbsRenderer LIB "glu32.dll" ALIAS "gluNewNurbsRenderer" () as long
declare function gluNewQuadric LIB "glu32.dll" ALIAS "gluNewQuadric" () as GLUquadricObj
declare function gluNewTess LIB "glu32.dll" ALIAS "gluNewTess" () as long
declare sub gluNextContour LIB "glu32.dll" ALIAS "gluNextContour" (byref tess as GLUtesselator, byval type as GLenum)
declare sub gluNurbsCallback LIB "glu32.dll" ALIAS "gluNurbsCallback" (byref nurb as GLUnurbs, byval which as GLenum, byval CallBackFunc as Long)
declare sub gluNurbsCallbackData LIB "glu32.dll" ALIAS "gluNurbsCallbackData" (byref nurb as GLUnurbs, byref userData as GLvoid)
declare sub gluNurbsCallbackDataEXT LIB "glu32.dll" ALIAS "gluNurbsCallbackDataEXT" (byref nurb as GLUnurbs, byref userData as GLvoid)
declare sub gluNurbsCurve LIB "glu32.dll" ALIAS "gluNurbsCurve" (byref nurb as GLUnurbs, byval knotCount as GLint, byref knots as GLfloat, byval stride as GLint, byref control as GLfloat, byval order as GLint, byval type as GLenum)
declare sub gluNurbsProperty LIB "glu32.dll" ALIAS "gluNurbsProperty" (byref nurb as GLUnurbs, byval property as GLenum, byval value as GLfloat)
declare sub gluNurbsSurface LIB "glu32.dll" ALIAS "gluNurbsSurface" (byref nurb as GLUnurbs, byval sKnotCount as GLint, byref sKnots as GLfloat, byval tKnotCount as GLint, byref tKnots as GLfloat, byval sStride as GLint, byval tStride as GLint, byref control as GLfloat, byval sOrder as GLint, byval tOrder as GLint, byval type as GLenum)

declare sub gluPwlCurve LIB "glu32.dll" ALIAS "gluPwlCurve" (byref nurb as GLUnurbs, byval count as GLint, byref data as GLfloat, byval stride as GLint, byval type as GLenum)
declare sub gluQuadricCallback LIB "glu32.dll" ALIAS "gluQuadricCallback" (quad as GLUquadric, byval which as GLenum, byval CallBackFunc as Long)
declare sub gluQuadricDrawStyle LIB "glu32.dll" ALIAS "gluQuadricDrawStyle" (quad as GLUquadric, byval draw as GLenum)
declare sub gluQuadricNormals LIB "glu32.dll" ALIAS "gluQuadricNormals" (quad as GLUquadric, byval normal as GLenum)
declare sub gluQuadricOrientation LIB "glu32.dll" ALIAS "gluQuadricOrientation" (quad as GLUquadric, byval orientation as GLenum)
declare sub gluQuadricTexture LIB "glu32.dll" ALIAS "gluQuadricTexture" (quad as GLUquadric, byval texture as GLboolean)
declare function gluScaleImage LIB "glu32.dll" ALIAS "gluScaleImage" (byval format as GLenum, byval wIn as GLsizei, byval hIn as GLsizei, byval typeIn as GLenum, byref dataIn as long, byval wOut as GLsizei, byval hOut as GLsizei, byval typeOut as GLenum, byref dataOut as GLvoid) as GLint
declare sub gluTessBeginContour LIB "glu32.dll" ALIAS "gluTessBeginContour" (byref tess as GLUtesselator)
declare sub gluTessBeginPolygon LIB "glu32.dll" ALIAS "gluTessBeginPolygon" (byref tess as GLUtesselator, byref data as GLvoid)
declare sub gluTessCallback LIB "glu32.dll" ALIAS "gluTessCallback" (byref tess as GLUtesselator, byval which as GLenum, byval CallBackFunc as Long)
declare sub gluTessEndContour LIB "glu32.dll" ALIAS "gluTessEndContour" (byref tess as GLUtesselator)
declare sub gluTessEndPolygon LIB "glu32.dll" ALIAS "gluTessEndPolygon" (byref tess as GLUtesselator)
declare sub gluTessNormal LIB "glu32.dll" ALIAS "gluTessNormal" (byref tess as GLUtesselator, byval valueX as GLdouble, byval valueY as GLdouble, byval valueZ as GLdouble)
declare sub gluTessProperty LIB "glu32.dll" ALIAS "gluTessProperty" (byref tess as GLUtesselator, byval which as GLenum, byval data as GLdouble)
declare sub gluTessVertex LIB "glu32.dll" ALIAS "gluTessVertex" (lptess as GLUtesselator, lpLocation as long, lpData as GLvoid)


'following declarations are needed because RQ can't pass a DOUBLE byval, must split into 2 longs...
' also all byrefs must be converted to LONG values so lpXXX means pass the pointer!

declare sub gluCylinder_API LIB "glu32.dll" ALIAS "gluCylinder"_
    (lpQuad as GLUquadric, base1 as long, base2 as long, _
    top as long, top2 as long, height1 as long, height2 as long, _
    slices as GLint, stacks as GLint)
    SUB gluCylinder (lpQuad as GLUquadric, base as GLdouble, top as GLdouble, height as GLdouble, slices as GLint, stacks as GLint)
        DEFDBL d:   DEFINT i(5)
        d = base: MemCpy (VarPtr(i(0)), VarPtr(d), 8)
        d = top: MemCpy (VarPtr(i(2)), VarPtr(d), 8)
        d = height: MemCpy (VarPtr(i(4)), VarPtr(d), 8)
        gluCylinder_API(lpQuad, i(0), i(1), i(2), i(3), i(4), i(5), slices, stacks)
    END SUB

declare sub gluSphere_API LIB "glu32.dll" ALIAS "gluSphere" (lpQuad as GLUquadric, radius as long, rad2 as long, slices as GLint, stacks as GLint)
    SUB gluSphere (lpQuad as GLUquadric, radius as GLdouble, slices as GLint, stacks as GLint)
        DEFDBL d:   DEFINT i(1)
        d = radius: MemCpy (VarPtr(i(0)), VarPtr(d), 8)
        gluSphere_API (lpQuad, i(0), i(1), slices, stacks)
    END SUB

declare sub gluDisk_API LIB "glu32.dll" ALIAS "gluDisk" (lpquad as Long, inner1 as Long, inner2 as Long, outer1 as Long, outer2 as Long, byval slices as GLint, byval loops as GLint)
    sub gluDisk (lpquad as Long, inner as GLdouble,  outer as GLdouble, slices as GLint, loops as GLint)
        DEFDBL d:   DEFINT i(3)
        d = inner: MemCpy (VarPtr(i(0)), VarPtr(d), 8)
        d = outer: MemCpy (VarPtr(i(2)), VarPtr(d), 8)
        gluDisk_API (lpquad, i(0), i(1), i(2), i(3), slices, loops)
     end sub

declare sub gluPartialDisk_API LIB "glu32.dll" ALIAS "gluPartialDisk" (lpQuad as Long, inner1 as Long, inner2 as Long, outer1 as Long, outer2 as Long, byval slices as GLint, byval loops as GLint, byval start as GLdouble, byval sweep as GLdouble)
    Sub gluPartialDisk (lpQuad as Long, inner as GLdouble, outer as GLdouble, slices as GLint, loops as GLint, byval start as GLdouble, sweep as GLdouble)
        DEFDBL d:   DEFINT i(3)
        d = inner: MemCpy (VarPtr(i(0)), VarPtr(d), 8)
        d = outer: MemCpy (VarPtr(i(2)), VarPtr(d), 8)
        gluDisk_API (lpquad, i(0), i(1), i(2), i(3), slices, loops)
        gluPartialDisk_API (lpquad, i(0), i(1), i(2), i(3), slices, loops, start, sweep)
    end sub

'declare sub gluGetTessProperty_API LIB "glu32.dll" ALIAS "gluGetTessProperty" (byref tess as GLUtesselator, byval which as GLenum, byref data as GLdouble)
declare sub gluGetTessProperty_API LIB "glu32.dll" ALIAS "gluGetTessProperty" (lptess as GLUtesselator, byval which as GLenum, lpDoubledata as long)


declare sub gluLookAt_API LIB "glu32.dll" ALIAS "gluLookAt" (eyeX as long, eyeY as long, byval eyeZ as long, byval centerX as long, byval centerY as long, byval centerZ as long, byval upX as long, byval upY as long, byval upZ as long, eyeX2 as long, eyeY2 as long, byval eyeZ2 as long, byval centerX2 as long, byval centerY2 as long, byval centerZ2 as long, byval upX2 as long, byval upY2 as long, byval upZ2 as long)
    SUB gluLookAt(eyeX as GLdouble, eyeY as GLdouble, eyeZ as GLdouble, centerX as GLdouble, centerY as GLdouble, byval centerZ as GLdouble, byval upX as GLdouble, byval upY as GLdouble, byval upZ as GLdouble)
        DEFDBL d:   DEFINT i(17)
        d = eyeX: MemCpy (VarPtr(i(0)), VarPtr(d), 8)
        d = eyeY: MemCpy (VarPtr(i(2)), VarPtr(d), 8)
        d = eyeZ: MemCpy (VarPtr(i(4)), VarPtr(d), 8)
        d = centerX: MemCpy (VarPtr(i(6)), VarPtr(d), 8)
        d = centerY: MemCpy (VarPtr(i(8)), VarPtr(d), 8)
        d = centerZ: MemCpy (VarPtr(i(10)), VarPtr(d), 8)
        d = upX: MemCpy (VarPtr(i(12)), VarPtr(d), 8)
        d = upY: MemCpy (VarPtr(i(14)), VarPtr(d), 8)
        d = upZ: MemCpy (VarPtr(i(16)), VarPtr(d), 8)
        gluLookAt_API(i(0), i(1), i(2), i(3), i(4), i(5), i(6), i(7), i(8), i(9), i(10), i(11), i(12), i(13), i(14), i(15), i(16),i(17))
    END SUB


declare sub gluOrtho2D_API LIB "glu32.dll" ALIAS "gluOrtho2D" (left as long, right as long, bottom as long, top as long, left2 as long, right2 as long, bottom2 as long, top2 as long)
    SUB gluOrtho2D(left as GLdouble, right as GLdouble, bottom as GLdouble, top as GLdouble)
        DEFDBL d:   DEFINT i(7)
        d = left: MemCpy (VarPtr(i(0)), VarPtr(d), 8)
        d = right: MemCpy (VarPtr(i(2)), VarPtr(d), 8)
        d = bottom: MemCpy (VarPtr(i(4)), VarPtr(d), 8)
        d = top: MemCpy (VarPtr(i(6)), VarPtr(d), 8)
        gluOrtho2D_API(i(0), i(1), i(2), i(3), i(4), i(5), i(6), i(7))
    END SUB

declare sub gluPerspective_API LIB "glu32.dll" ALIAS "gluPerspective" (fovy1 as long,fovy2 as long, aspect1 as long, aspect2 as long, zNear1 as long, zNear2 as long, zFar1 as long, zFar2 as long)
    SUB gluPerspective(fovy as GLdouble, aspect as GLdouble, zNear as GLdouble, zFar as GLdouble)
        DEFDBL d:   DEFINT i(7)
        d = fovy: MemCpy (VarPtr(i(0)), VarPtr(d), 8)
        d = aspect: MemCpy (VarPtr(i(2)), VarPtr(d), 8)
        d = zNear: MemCpy (VarPtr(i(4)), VarPtr(d), 8)
        d = zFar: MemCpy (VarPtr(i(6)), VarPtr(d), 8)
        gluPerspective_API(i(0), i(1), i(2), i(3), i(4), i(5), i(6), i(7))
    END SUB

declare sub gluPickMatrix_API LIB "glu32.dll" ALIAS "gluPickMatrix" (x1 as LONG, x2 as LONG, y1 as LONG,y2 as LONG, delX1 as LONG, delX2 as LONG, delY as LONG, delY2 as LONG, lpViewport as GLint)
    SUB gluPickMatrix (x as DOUBLE, y as DOUBLE, delX as DOUBLE, delY as DOUBLE, Viewport as LONG)
        DEFDBL d:   DEFINT i(7)
        d = x: MemCpy (VarPtr(i(0)), VarPtr(d), 8)
        d = y: MemCpy (VarPtr(i(2)), VarPtr(d), 8)
        d = delX: MemCpy (VarPtr(i(4)), VarPtr(d), 8)
        d = delY: MemCpy (VarPtr(i(6)), VarPtr(d), 8)
        gluPickMatrix_API(i(0), i(1), i(2), i(3), i(4), i(5), i(6), i(7), Viewport)
    END SUB

declare function gluProject_API LIB "glu32.dll" ALIAS "gluProject" _
    (objX as LONG, ob2 as LONG, objY as LONG, objY2 as LONG, objZ as LONG, objz2 as LONG,_
    lpmodel as LONG, lpproj as LONG, lpView as LONG, _
    lpWinX as LONG, lpWinY as LONG, lpWinZ as LONG) as GLint
    function gluProject (objX as GLdouble, objY as GLdouble, objZ as GLdouble, lpModel as long, lpProj as long, lpView as long, lpWinX as LONG, lpWinY as LONG, lpWinZ as LONG) as GLint
        DEFDBL d:   DEFINT i(5)
        d = objX: MemCpy (VarPtr(i(0)), VarPtr(d), 8)
        d = objY: MemCpy (VarPtr(i(2)), VarPtr(d), 8)
        d = objZ: MemCpy (VarPtr(i(4)), VarPtr(d), 8)
        RESULT = gluProject_API(i(0), i(1), i(2), i(3), i(4), i(5), lpModel, lpProj, lpView, lpWinX, lpWinY, lpWinZ)
    END FUNCTION

declare function gluUnProject_API LIB "glu32.dll" ALIAS "gluUnProject" _
    (winX as LONG, winX2 as LONG, winY as LONG, winY2 as LONG, winZ as LONG, winz2 as LONG,_
     lpmodel as LONG, lpproj as LONG, lpview as GLint, _
     lpobjX as long, lpobjY as long, lpobjZ as long) as GLint
    function gluUnProject (winX as GLdouble, winY as GLdouble, winZ as GLdouble, lpModel as long, lpProj as long, lpView as long, lpObjX as LONG, lpObjY as LONG, lpObjZ as LONG) as GLint
        DEFDBL d:   DEFINT i(5)
        d = WinX: MemCpy (VarPtr(i(0)), VarPtr(d), 8)
        d = WinY: MemCpy (VarPtr(i(2)), VarPtr(d), 8)
        d = WinZ: MemCpy (VarPtr(i(4)), VarPtr(d), 8)
        RESULT = gluUnProject_API(i(0), i(1), i(2), i(3), i(4), i(5), lpmodel, lpproj, lpview, lpObjX, lpObjY, lpObjZ)
    END FUNCTION

'declare function gluUnProject4 LIB "glu32.dll" ALIAS "gluUnProject4" (byval winX as GLdouble, byval winY as GLdouble, byval winZ as GLdouble, byval clipW as GLdouble, byref model as GLdouble, byref proj as GLdouble, byref view as GLint, byval nearVal as GLdouble, byval farVal as GLdouble, byref objX as GLdouble, byref objY as GLdouble, byref objZ as GLdouble, byref objW as GLdouble) as GLint
$ENDIF
