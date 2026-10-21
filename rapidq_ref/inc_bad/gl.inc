'----------------------------------------------------------------------
'  GL.INC -- Part of the OpenGL32 API Includes for PB/DLL 6.0 Release 4
'  [gl.h, glu.h, glaux.h + wgl API]
'  Copyright 1999 sublevel6.
'  Portions copyright Silicon Graphics and Microsoft.
'
'  Release date: Saturday, December 11, 1999
'  Homepage:     http://ryme.future.easyspace.com/
'  E-Mail:       dinky@pmail.net (to Dinky)
'                angus_law@hotmail.com (to rYme)
'----------------------------------------------------------------------
'Converted for use in RapidQ by Kris Dawson
'email: cooldaddyk7@hotmail.com
'/*
'** Copyright 1996 Silicon Graphics, Inc.
'** All Rights Reserved.
'**
'** This is UNPUBLISHED PROPRIETARY SOURCE CODE of Silicon Graphics, Inc.;
'** the contents of this file may not be disclosed to third parties, copied or
'** duplicated in LONG form, in whole or in part, without the prior written
'** permission of Silicon Graphics, Inc.
'**
'** RESTRICTED RIGHTS LEGEND
'** Use, duplication or disclosure by the Government is subject to restrictions
'** as set forth in subdivision (c)(1)(ii) of the Rights in Technical Data
'** and Computer Software clause at DFARS 252.227-7013, and/or in similar or
'** successor clauses in the FAR, DOD or NASA FAR Supplement. Unpublished -
'** rights reserved under the Copyright Laws of the United States.
'*/

Const GL_INC                             = 1

Const GL_VERSION_1_1                     = 1

Const GL_ACCUM                           = &H0100
Const GL_LOAD                            = &H0101
Const GL_RETURN                          = &H0102
Const GL_MULT                            = &H0103
Const GL_ADD                             = &H0104

Const GL_NEVER                           = &H0200
Const GL_LESS                            = &H0201
Const GL_EQUAL                           = &H0202
Const GL_LEQUAL                          = &H0203
Const GL_GREATER                         = &H0204
Const GL_NOTEQUAL                        = &H0205
Const GL_GEQUAL                          = &H0206
Const GL_ALWAYS                          = &H0207

Const GL_CURRENT_BIT                     = &H00000001
Const GL_POINT_BIT                       = &H00000002
Const GL_LINE_BIT                        = &H00000004
Const GL_POLYGON_BIT                     = &H00000008
Const GL_POLYGON_STIPPLE_BIT             = &H00000010
Const GL_PIXEL_MODE_BIT                  = &H00000020
Const GL_LIGHTING_BIT                    = &H00000040
Const GL_FOG_BIT                         = &H00000080
Const GL_DEPTH_BUFFER_BIT                = &H00000100
Const GL_ACCUM_BUFFER_BIT                = &H00000200
Const GL_STENCIL_BUFFER_BIT              = &H00000400
Const GL_VIEWPORT_BIT                    = &H00000800
Const GL_TRANSFORM_BIT                   = &H00001000
Const GL_ENABLE_BIT                      = &H00002000
Const GL_COLOR_BUFFER_BIT                = &H00004000
Const GL_HINT_BIT                        = &H00008000
Const GL_EVAL_BIT                        = &H00010000
Const GL_LIST_BIT                        = &H00020000
Const GL_TEXTURE_BIT                     = &H00040000
Const GL_SCISSOR_BIT                     = &H00080000
Const GL_ALL_ATTRIB_BITS                 = &H000FFFFF

Const GL_POINTS                          = &H0000
Const GL_LINES                           = &H0001
Const GL_LINE_LOOP                       = &H0002
Const GL_LINE_STRIP                      = &H0003
Const GL_TRIANGLES                       = &H0004
Const GL_TRIANGLE_STRIP                  = &H0005
Const GL_TRIANGLE_FAN                    = &H0006
Const GL_QUADS                           = &H0007
Const GL_QUAD_STRIP                      = &H0008
Const GL_POLYGON                         = &H0009

Const GL_ZERO                            = 0
Const GL_ONE                             = 1
Const GL_SRC_COLOR                       = &H0300
Const GL_ONE_MINUS_SRC_COLOR             = &H0301
Const GL_SRC_ALPHA                       = &H0302
Const GL_ONE_MINUS_SRC_ALPHA             = &H0303
Const GL_DST_ALPHA                       = &H0304
Const GL_ONE_MINUS_DST_ALPHA             = &H0305

Const GL_DST_COLOR                       = &H0306
Const GL_ONE_MINUS_DST_COLOR             = &H0307
Const GL_SRC_ALPHA_SATURATE              = &H0308

Const GL_TRUE                            = 1
Const GL_FALSE                           = 0

Const GL_CLIP_PLANE0                     = &H3000
Const GL_CLIP_PLANE1                     = &H3001
Const GL_CLIP_PLANE2                     = &H3002
Const GL_CLIP_PLANE3                     = &H3003
Const GL_CLIP_PLANE4                     = &H3004
Const GL_CLIP_PLANE5                     = &H3005

Const GL_BYTE                            = &H1400
Const GL_UNSIGNED_BYTE                   = &H1401
Const GL_SHORT                           = &H1402
Const GL_UNSIGNED_SHORT                  = &H1403
Const GL_INT                             = &H1404
Const GL_UNSIGNED_INT                    = &H1405
Const GL_FLOAT                           = &H1406
Const GL_2_BYTES                         = &H1407
Const GL_3_BYTES                         = &H1408
Const GL_4_BYTES                         = &H1409
Const GL_DOUBLE                          = &H140A

Const GL_NONE                            = 0
Const GL_FRONT_LEFT                      = &H0400
Const GL_FRONT_RIGHT                     = &H0401
Const GL_BACK_LEFT                       = &H0402
Const GL_BACK_RIGHT                      = &H0403
Const GL_FRONT                           = &H0404
Const GL_BACK                            = &H0405
Const GL_LEFT                            = &H0406
Const GL_RIGHT                           = &H0407
Const GL_FRONT_AND_BACK                  = &H0408
Const GL_AUX0                            = &H0409
Const GL_AUX1                            = &H040A
Const GL_AUX2                            = &H040B
Const GL_AUX3                            = &H040C

Const GL_NO_ERROR                        = 0
Const GL_INVALID_ENUM                    = &H0500
Const GL_INVALID_VALUE                   = &H0501
Const GL_INVALID_OPERATION               = &H0502
Const GL_STACK_OVERFLOW                  = &H0503
Const GL_STACK_UNDERFLOW                 = &H0504
Const GL_OUT_OF_MEMORY                   = &H0505

Const GL_2D                              = &H0600
Const GL_3D                              = &H0601
Const GL_3D_COLOR                        = &H0602
Const GL_3D_COLOR_TEXTURE                = &H0603
Const GL_4D_COLOR_TEXTURE                = &H0604

Const GL_PASS_THROUGH_TOKEN              = &H0700
Const GL_POINT_TOKEN                     = &H0701
Const GL_LINE_TOKEN                      = &H0702
Const GL_POLYGON_TOKEN                   = &H0703
Const GL_BITMAP_TOKEN                    = &H0704
Const GL_DRAW_PIXEL_TOKEN                = &H0705
Const GL_COPY_PIXEL_TOKEN                = &H0706
Const GL_LINE_RESET_TOKEN                = &H0707

Const GL_EXP                             = &H0800
Const GL_EXP2                            = &H0801

Const GL_CW                              = &H0900
Const GL_CCW                             = &H0901

Const GL_COEFF                           = &H0A00
Const GL_ORDER                           = &H0A01
Const GL_DOMAIN                          = &H0A02

Const GL_CURRENT_COLOR                   = &H0B00
Const GL_CURRENT_INDEX                   = &H0B01
Const GL_CURRENT_NORMAL                  = &H0B02
Const GL_CURRENT_TEXTURE_COORDS          = &H0B03
Const GL_CURRENT_RASTER_COLOR            = &H0B04
Const GL_CURRENT_RASTER_INDEX            = &H0B05
Const GL_CURRENT_RASTER_TEXTURE_COORDS   = &H0B06
Const GL_CURRENT_RASTER_POSITION         = &H0B07
Const GL_CURRENT_RASTER_POSITION_VALID   = &H0B08
Const GL_CURRENT_RASTER_DISTANCE         = &H0B09
Const GL_POINT_SMOOTH                    = &H0B10
Const GL_POINT_SIZE                      = &H0B11
Const GL_POINT_SIZE_RANGE                = &H0B12
Const GL_POINT_SIZE_GRANULARITY          = &H0B13
Const GL_LINE_SMOOTH                     = &H0B20
Const GL_LINE_WIDTH                      = &H0B21
Const GL_LINE_WIDTH_RANGE                = &H0B22
Const GL_LINE_WIDTH_GRANULARITY          = &H0B23
Const GL_LINE_STIPPLE                    = &H0B24
Const GL_LINE_STIPPLE_PATTERN            = &H0B25
Const GL_LINE_STIPPLE_REPEAT             = &H0B26
Const GL_LIST_MODE                       = &H0B30
Const GL_MAX_LIST_NESTING                = &H0B31
Const GL_LIST_BASE                       = &H0B32
Const GL_LIST_INDEX                      = &H0B33
Const GL_POLYGON_MODE                    = &H0B40
Const GL_POLYGON_SMOOTH                  = &H0B41
Const GL_POLYGON_STIPPLE                 = &H0B42
Const GL_EDGE_FLAG                       = &H0B43
Const GL_CULL_FACE                       = &H0B44
Const GL_CULL_FACE_MODE                  = &H0B45
Const GL_FRONT_FACE                      = &H0B46
Const GL_LIGHTING                        = &H0B50
Const GL_LIGHT_MODEL_LOCAL_VIEWER        = &H0B51
Const GL_LIGHT_MODEL_TWO_SIDE            = &H0B52
Const GL_LIGHT_MODEL_AMBIENT             = &H0B53
Const GL_SHADE_MODEL                     = &H0B54
Const GL_COLOR_MATERIAL_FACE             = &H0B55
Const GL_COLOR_MATERIAL_PARAMETER        = &H0B56
Const GL_COLOR_MATERIAL                  = &H0B57
Const GL_FOG                             = &H0B60
Const GL_FOG_INDEX                       = &H0B61
Const GL_FOG_DENSITY                     = &H0B62
Const GL_FOG_START                       = &H0B63
Const GL_FOG_END                         = &H0B64
Const GL_FOG_MODE                        = &H0B65
Const GL_FOG_COLOR                       = &H0B66
Const GL_DEPTH_RANGE                     = &H0B70
Const GL_DEPTH_TEST                      = &H0B71
Const GL_DEPTH_WRITEMASK                 = &H0B72
Const GL_DEPTH_CLEAR_VALUE               = &H0B73
Const GL_DEPTH_FUNC                      = &H0B74
Const GL_ACCUM_CLEAR_VALUE               = &H0B80
Const GL_STENCIL_TEST                    = &H0B90
Const GL_STENCIL_CLEAR_VALUE             = &H0B91
Const GL_STENCIL_FUNC                    = &H0B92
Const GL_STENCIL_VALUE_MASK              = &H0B93
Const GL_STENCIL_FAIL                    = &H0B94
Const GL_STENCIL_PASS_DEPTH_FAIL         = &H0B95
Const GL_STENCIL_PASS_DEPTH_PASS         = &H0B96
Const GL_STENCIL_REF                     = &H0B97
Const GL_STENCIL_WRITEMASK               = &H0B98
Const GL_MATRIX_MODE                     = &H0BA0
Const GL_NORMALIZE                       = &H0BA1
Const GL_VIEWPORT                        = &H0BA2
Const GL_MODELVIEW_STACK_DEPTH           = &H0BA3
Const GL_PROJECTION_STACK_DEPTH          = &H0BA4
Const GL_TEXTURE_STACK_DEPTH             = &H0BA5
Const GL_MODELVIEW_MATRIX                = &H0BA6
Const GL_PROJECTION_MATRIX               = &H0BA7
Const GL_TEXTURE_MATRIX                  = &H0BA8
Const GL_ATTRIB_STACK_DEPTH              = &H0BB0
Const GL_CLIENT_ATTRIB_STACK_DEPTH       = &H0BB1
Const GL_ALPHA_TEST                      = &H0BC0
Const GL_ALPHA_TEST_FUNC                 = &H0BC1
Const GL_ALPHA_TEST_REF                  = &H0BC2
Const GL_DITHER                          = &H0BD0
Const GL_BLEND_DST                       = &H0BE0
Const GL_BLEND_SRC                       = &H0BE1
Const GL_BLEND                           = &H0BE2
Const GL_LOGIC_OP_MODE                   = &H0BF0
Const GL_INDEX_LOGIC_OP                  = &H0BF1
Const GL_COLOR_LOGIC_OP                  = &H0BF2
Const GL_AUX_BUFFERS                     = &H0C00
Const GL_DRAW_BUFFER                     = &H0C01
Const GL_READ_BUFFER                     = &H0C02
Const GL_SCISSOR_BOX                     = &H0C10
Const GL_SCISSOR_TEST                    = &H0C11
Const GL_INDEX_CLEAR_VALUE               = &H0C20
Const GL_INDEX_WRITEMASK                 = &H0C21
Const GL_COLOR_CLEAR_VALUE               = &H0C22
Const GL_COLOR_WRITEMASK                 = &H0C23
Const GL_INDEX_MODE                      = &H0C30
Const GL_RGBA_MODE                       = &H0C31
Const GL_DOUBLEBUFFER                    = &H0C32
Const GL_STEREO                          = &H0C33
Const GL_RENDER_MODE                     = &H0C40
Const GL_PERSPECTIVE_CORRECTION_HINT     = &H0C50
Const GL_POINT_SMOOTH_HINT               = &H0C51
Const GL_LINE_SMOOTH_HINT                = &H0C52
Const GL_POLYGON_SMOOTH_HINT             = &H0C53
Const GL_FOG_HINT                        = &H0C54
Const GL_TEXTURE_GEN_S                   = &H0C60
Const GL_TEXTURE_GEN_T                   = &H0C61
Const GL_TEXTURE_GEN_R                   = &H0C62
Const GL_TEXTURE_GEN_Q                   = &H0C63
Const GL_PIXEL_MAP_I_TO_I                = &H0C70
Const GL_PIXEL_MAP_S_TO_S                = &H0C71
Const GL_PIXEL_MAP_I_TO_R                = &H0C72
Const GL_PIXEL_MAP_I_TO_G                = &H0C73
Const GL_PIXEL_MAP_I_TO_B                = &H0C74
Const GL_PIXEL_MAP_I_TO_A                = &H0C75
Const GL_PIXEL_MAP_R_TO_R                = &H0C76
Const GL_PIXEL_MAP_G_TO_G                = &H0C77
Const GL_PIXEL_MAP_B_TO_B                = &H0C78
Const GL_PIXEL_MAP_A_TO_A                = &H0C79
Const GL_PIXEL_MAP_I_TO_I_SIZE           = &H0CB0
Const GL_PIXEL_MAP_S_TO_S_SIZE           = &H0CB1
Const GL_PIXEL_MAP_I_TO_R_SIZE           = &H0CB2
Const GL_PIXEL_MAP_I_TO_G_SIZE           = &H0CB3
Const GL_PIXEL_MAP_I_TO_B_SIZE           = &H0CB4
Const GL_PIXEL_MAP_I_TO_A_SIZE           = &H0CB5
Const GL_PIXEL_MAP_R_TO_R_SIZE           = &H0CB6
Const GL_PIXEL_MAP_G_TO_G_SIZE           = &H0CB7
Const GL_PIXEL_MAP_B_TO_B_SIZE           = &H0CB8
Const GL_PIXEL_MAP_A_TO_A_SIZE           = &H0CB9
Const GL_UNPACK_SWAP_BYTES               = &H0CF0
Const GL_UNPACK_LSB_FIRST                = &H0CF1
Const GL_UNPACK_ROW_LENGTH               = &H0CF2
Const GL_UNPACK_SKIP_ROWS                = &H0CF3
Const GL_UNPACK_SKIP_PIXELS              = &H0CF4
Const GL_UNPACK_ALIGNMENT                = &H0CF5
Const GL_PACK_SWAP_BYTES                 = &H0D00
Const GL_PACK_LSB_FIRST                  = &H0D01
Const GL_PACK_ROW_LENGTH                 = &H0D02
Const GL_PACK_SKIP_ROWS                  = &H0D03
Const GL_PACK_SKIP_PIXELS                = &H0D04
Const GL_PACK_ALIGNMENT                  = &H0D05
Const GL_MAP_COLOR                       = &H0D10
Const GL_MAP_STENCIL                     = &H0D11
Const GL_INDEX_SHIFT                     = &H0D12
Const GL_INDEX_OFFSET                    = &H0D13
Const GL_RED_SCALE                       = &H0D14
Const GL_RED_BIAS                        = &H0D15
Const GL_ZOOM_X                          = &H0D16
Const GL_ZOOM_Y                          = &H0D17
Const GL_GREEN_SCALE                     = &H0D18
Const GL_GREEN_BIAS                      = &H0D19
Const GL_BLUE_SCALE                      = &H0D1A
Const GL_BLUE_BIAS                       = &H0D1B
Const GL_ALPHA_SCALE                     = &H0D1C
Const GL_ALPHA_BIAS                      = &H0D1D
Const GL_DEPTH_SCALE                     = &H0D1E
Const GL_DEPTH_BIAS                      = &H0D1F
Const GL_MAX_EVAL_ORDER                  = &H0D30
Const GL_MAX_LIGHTS                      = &H0D31
Const GL_MAX_CLIP_PLANES                 = &H0D32
Const GL_MAX_TEXTURE_SIZE                = &H0D33
Const GL_MAX_PIXEL_MAP_TABLE             = &H0D34
Const GL_MAX_ATTRIB_STACK_DEPTH          = &H0D35
Const GL_MAX_MODELVIEW_STACK_DEPTH       = &H0D36
Const GL_MAX_NAME_STACK_DEPTH            = &H0D37
Const GL_MAX_PROJECTION_STACK_DEPTH      = &H0D38
Const GL_MAX_TEXTURE_STACK_DEPTH         = &H0D39
Const GL_MAX_VIEWPORT_DIMS               = &H0D3A
Const GL_MAX_CLIENT_ATTRIB_STACK_DEPTH   = &H0D3B
Const GL_SUBPIXEL_BITS                   = &H0D50
Const GL_INDEX_BITS                      = &H0D51
Const GL_RED_BITS                        = &H0D52
Const GL_GREEN_BITS                      = &H0D53
Const GL_BLUE_BITS                       = &H0D54
Const GL_ALPHA_BITS                      = &H0D55
Const GL_DEPTH_BITS                      = &H0D56
Const GL_STENCIL_BITS                    = &H0D57
Const GL_ACCUM_RED_BITS                  = &H0D58
Const GL_ACCUM_GREEN_BITS                = &H0D59
Const GL_ACCUM_BLUE_BITS                 = &H0D5A
Const GL_ACCUM_ALPHA_BITS                = &H0D5B
Const GL_NAME_STACK_DEPTH                = &H0D70
Const GL_AUTO_NORMAL                     = &H0D80
Const GL_MAP1_COLOR_4                    = &H0D90
Const GL_MAP1_INDEX                      = &H0D91
Const GL_MAP1_NORMAL                     = &H0D92
Const GL_MAP1_TEXTURE_COORD_1            = &H0D93
Const GL_MAP1_TEXTURE_COORD_2            = &H0D94
Const GL_MAP1_TEXTURE_COORD_3            = &H0D95
Const GL_MAP1_TEXTURE_COORD_4            = &H0D96
Const GL_MAP1_VERTEX_3                   = &H0D97
Const GL_MAP1_VERTEX_4                   = &H0D98
Const GL_MAP2_COLOR_4                    = &H0DB0
Const GL_MAP2_INDEX                      = &H0DB1
Const GL_MAP2_NORMAL                     = &H0DB2
Const GL_MAP2_TEXTURE_COORD_1            = &H0DB3
Const GL_MAP2_TEXTURE_COORD_2            = &H0DB4
Const GL_MAP2_TEXTURE_COORD_3            = &H0DB5
Const GL_MAP2_TEXTURE_COORD_4            = &H0DB6
Const GL_MAP2_VERTEX_3                   = &H0DB7
Const GL_MAP2_VERTEX_4                   = &H0DB8
Const GL_MAP1_GRID_DOMAIN                = &H0DD0
Const GL_MAP1_GRID_SEGMENTS              = &H0DD1
Const GL_MAP2_GRID_DOMAIN                = &H0DD2
Const GL_MAP2_GRID_SEGMENTS              = &H0DD3
Const GL_TEXTURE_1D                      = &H0DE0
Const GL_TEXTURE_2D                      = &H0DE1
Const GL_FEEDBACK_BUFFER_POINTER         = &H0DF0
Const GL_FEEDBACK_BUFFER_SIZE            = &H0DF1
Const GL_FEEDBACK_BUFFER_TYPE            = &H0DF2
Const GL_SELECTION_BUFFER_POINTER        = &H0DF3
Const GL_SELECTION_BUFFER_SIZE           = &H0DF4

Const GL_TEXTURE_WIDTH                   = &H1000
Const GL_TEXTURE_HEIGHT                  = &H1001
Const GL_TEXTURE_INTERNAL_FORMAT         = &H1003
Const GL_TEXTURE_BORDER_COLOR            = &H1004
Const GL_TEXTURE_BORDER                  = &H1005

Const GL_DONT_CARE                       = &H1100
Const GL_FASTEST                         = &H1101
Const GL_NICEST                          = &H1102

Const GL_LIGHT0                          = &H4000
Const GL_LIGHT1                          = &H4001
Const GL_LIGHT2                          = &H4002
Const GL_LIGHT3                          = &H4003
Const GL_LIGHT4                          = &H4004
Const GL_LIGHT5                          = &H4005
Const GL_LIGHT6                          = &H4006
Const GL_LIGHT7                          = &H4007

Const GL_AMBIENT                         = &H1200
Const GL_DIFFUSE                         = &H1201
Const GL_SPECULAR                        = &H1202
Const GL_POSITION                        = &H1203
Const GL_SPOT_DIRECTION                  = &H1204
Const GL_SPOT_EXPONENT                   = &H1205
Const GL_SPOT_CUTOFF                     = &H1206
Const GL_CONSTANT_ATTENUATION            = &H1207
Const GL_LINEAR_ATTENUATION              = &H1208
Const GL_QUADRATIC_ATTENUATION           = &H1209

Const GL_COMPILE                         = &H1300
Const GL_COMPILE_AND_EXECUTE             = &H1301

Const GL_CLEAR                           = &H1500
Const GL_AND                             = &H1501
Const GL_AND_REVERSE                     = &H1502
Const GL_COPY                            = &H1503
Const GL_AND_INVERTED                    = &H1504
Const GL_NOOP                            = &H1505
Const GL_XOR                             = &H1506
Const GL_OR                              = &H1507
Const GL_NOR                             = &H1508
Const GL_EQUIV                           = &H1509
Const GL_INVERT                          = &H150A
Const GL_OR_REVERSE                      = &H150B
Const GL_COPY_INVERTED                   = &H150C
Const GL_OR_INVERTED                     = &H150D
Const GL_NAND                            = &H150E
Const GL_SET                             = &H150F

Const GL_EMISSION                        = &H1600
Const GL_SHININESS                       = &H1601
Const GL_AMBIENT_AND_DIFFUSE             = &H1602
Const GL_COLOR_INDEXES                   = &H1603

Const GL_MODELVIEW                       = &H1700
Const GL_PROJECTION                      = &H1701
Const GL_TEXTURE                         = &H1702

Const GL_COLOR                           = &H1800
Const GL_DEPTH                           = &H1801
Const GL_STENCIL                         = &H1802

Const GL_COLOR_INDEX                     = &H1900
Const GL_STENCIL_INDEX                   = &H1901
Const GL_DEPTH_COMPONENT                 = &H1902
Const GL_RED                             = &H1903
Const GL_GREEN                           = &H1904
Const GL_BLUE                            = &H1905
Const GL_ALPHA                           = &H1906
Const GL_RGB                             = &H1907
Const GL_RGBA                            = &H1908
Const GL_LUMINANCE                       = &H1909
Const GL_LUMINANCE_ALPHA                 = &H190A

Const GL_BITMAP                          = &H1A00

Const GL_POINT                           = &H1B00
Const GL_LINE                            = &H1B01
Const GL_FILL                            = &H1B02

Const GL_RENDER                          = &H1C00
Const GL_FEEDBACK                        = &H1C01
Const GL_SELECT                          = &H1C02

Const GL_FLAT                            = &H1D00
Const GL_SMOOTH                          = &H1D01

Const GL_KEEP                            = &H1E00
Const GL_REPLACE                         = &H1E01
Const GL_INCR                            = &H1E02
Const GL_DECR                            = &H1E03

Const GL_VENDOR                          = &H1F00
Const GL_RENDERER                        = &H1F01
Const GL_VERSION                         = &H1F02
Const GL_EXTENSIONS                      = &H1F03

Const GL_S                               = &H2000
Const GL_T                               = &H2001
Const GL_R                               = &H2002
Const GL_Q                               = &H2003

Const GL_MODULATE                        = &H2100
Const GL_DECAL                           = &H2101

Const GL_TEXTURE_ENV_MODE                = &H2200
Const GL_TEXTURE_ENV_COLOR               = &H2201

Const GL_TEXTURE_ENV                     = &H2300

Const GL_EYE_LINEAR                      = &H2400
Const GL_OBJECT_LINEAR                   = &H2401
Const GL_SPHERE_MAP                      = &H2402

Const GL_TEXTURE_GEN_MODE                = &H2500
Const GL_OBJECT_PLANE                    = &H2501
Const GL_EYE_PLANE                       = &H2502

Const GL_NEAREST                         = &H2600
Const GL_LINEAR                          = &H2601

Const GL_NEAREST_MIPMAP_NEAREST          = &H2700
Const GL_LINEAR_MIPMAP_NEAREST           = &H2701
Const GL_NEAREST_MIPMAP_LINEAR           = &H2702
Const GL_LINEAR_MIPMAP_LINEAR            = &H2703

Const GL_TEXTURE_MAG_FILTER              = &H2800
Const GL_TEXTURE_MIN_FILTER              = &H2801
Const GL_TEXTURE_WRAP_S                  = &H2802
Const GL_TEXTURE_WRAP_T                  = &H2803

Const GL_CLAMP                           = &H2900
Const GL_REPEAT                          = &H2901

Const GL_CLIENT_PIXEL_STORE_BIT          = &H00000001
Const GL_CLIENT_VERTEX_ARRAY_BIT         = &H00000002
Const GL_CLIENT_ALL_ATTRIB_BITS          = &HFFFFFFFF

Const GL_POLYGON_OFFSET_FACTOR           = &H8038
Const GL_POLYGON_OFFSET_UNITS            = &H2A00
Const GL_POLYGON_OFFSET_POINT            = &H2A01
Const GL_POLYGON_OFFSET_LINE             = &H2A02
Const GL_POLYGON_OFFSET_FILL             = &H8037

Const GL_ALPHA4                          = &H803B
Const GL_ALPHA8                          = &H803C
Const GL_ALPHA12                         = &H803D
Const GL_ALPHA16                         = &H803E
Const GL_LUMINANCE4                      = &H803F
Const GL_LUMINANCE8                      = &H8040
Const GL_LUMINANCE12                     = &H8041
Const GL_LUMINANCE16                     = &H8042
Const GL_LUMINANCE4_ALPHA4               = &H8043
Const GL_LUMINANCE6_ALPHA2               = &H8044
Const GL_LUMINANCE8_ALPHA8               = &H8045
Const GL_LUMINANCE12_ALPHA4              = &H8046
Const GL_LUMINANCE12_ALPHA12             = &H8047
Const GL_LUMINANCE16_ALPHA16             = &H8048
Const GL_INTENSITY                       = &H8049
Const GL_INTENSITY4                      = &H804A
Const GL_INTENSITY8                      = &H804B
Const GL_INTENSITY12                     = &H804C
Const GL_INTENSITY16                     = &H804D
Const GL_R3_G3_B2                        = &H2A10
Const GL_RGB4                            = &H804F
Const GL_RGB5                            = &H8050
Const GL_RGB8                            = &H8051
Const GL_RGB10                           = &H8052
Const GL_RGB12                           = &H8053
Const GL_RGB16                           = &H8054
Const GL_RGBA2                           = &H8055
Const GL_RGBA4                           = &H8056
Const GL_RGB5_A1                         = &H8057
Const GL_RGBA8                           = &H8058
Const GL_RGB10_A2                        = &H8059
Const GL_RGBA12                          = &H805A
Const GL_RGBA16                          = &H805B
Const GL_TEXTURE_RED_SIZE                = &H805C
Const GL_TEXTURE_GREEN_SIZE              = &H805D
Const GL_TEXTURE_BLUE_SIZE               = &H805E
Const GL_TEXTURE_ALPHA_SIZE              = &H805F
Const GL_TEXTURE_LUMINANCE_SIZE          = &H8060
Const GL_TEXTURE_INTENSITY_SIZE          = &H8061
Const GL_PROXY_TEXTURE_1D                = &H8063
Const GL_PROXY_TEXTURE_2D                = &H8064

Const GL_TEXTURE_PRIORITY                = &H8066
Const GL_TEXTURE_RESIDENT                = &H8067
Const GL_TEXTURE_BINDING_1D              = &H8068
Const GL_TEXTURE_BINDING_2D              = &H8069

Const GL_VERTEX_ARRAY                    = &H8074
Const GL_NORMAL_ARRAY                    = &H8075
Const GL_COLOR_ARRAY                     = &H8076
Const GL_INDEX_ARRAY                     = &H8077
Const GL_TEXTURE_COORD_ARRAY             = &H8078
Const GL_EDGE_FLAG_ARRAY                 = &H8079
Const GL_VERTEX_ARRAY_SIZE               = &H807A
Const GL_VERTEX_ARRAY_TYPE               = &H807B
Const GL_VERTEX_ARRAY_STRIDE             = &H807C
Const GL_NORMAL_ARRAY_TYPE               = &H807E
Const GL_NORMAL_ARRAY_STRIDE             = &H807F
Const GL_COLOR_ARRAY_SIZE                = &H8081
Const GL_COLOR_ARRAY_TYPE                = &H8082
Const GL_COLOR_ARRAY_STRIDE              = &H8083
Const GL_INDEX_ARRAY_TYPE                = &H8085
Const GL_INDEX_ARRAY_STRIDE              = &H8086
Const GL_TEXTURE_COORD_ARRAY_SIZE        = &H8088
Const GL_TEXTURE_COORD_ARRAY_TYPE        = &H8089
Const GL_TEXTURE_COORD_ARRAY_STRIDE      = &H808A
Const GL_EDGE_FLAG_ARRAY_STRIDE          = &H808C
Const GL_VERTEX_ARRAY_POINTER            = &H808E
Const GL_NORMAL_ARRAY_POINTER            = &H808F
Const GL_COLOR_ARRAY_POINTER             = &H8090
Const GL_INDEX_ARRAY_POINTER             = &H8091
Const GL_TEXTURE_COORD_ARRAY_POINTER     = &H8092
Const GL_EDGE_FLAG_ARRAY_POINTER         = &H8093
Const GL_V2F                             = &H2A20
Const GL_V3F                             = &H2A21
Const GL_C4UB_V2F                        = &H2A22
Const GL_C4UB_V3F                        = &H2A23
Const GL_C3F_V3F                         = &H2A24
Const GL_N3F_V3F                         = &H2A25
Const GL_C4F_N3F_V3F                     = &H2A26
Const GL_T2F_V3F                         = &H2A27
Const GL_T4F_V4F                         = &H2A28
Const GL_T2F_C4UB_V3F                    = &H2A29
Const GL_T2F_C3F_V3F                     = &H2A2A
Const GL_T2F_N3F_V3F                     = &H2A2B
Const GL_T2F_C4F_N3F_V3F                 = &H2A2C
Const GL_T4F_C4F_N3F_V4F                 = &H2A2D

Const GL_EXT_vertex_array                = 1
Const GL_EXT_bgra                        = 1
Const GL_EXT_paletted_texture            = 1
Const GL_WIN_swap_hint                   = 1
Const GL_WIN_draw_range_elements         = 1

Const GL_VERTEX_ARRAY_EXT                = &H8074
Const GL_NORMAL_ARRAY_EXT                = &H8075
Const GL_COLOR_ARRAY_EXT                 = &H8076
Const GL_INDEX_ARRAY_EXT                 = &H8077
Const GL_TEXTURE_COORD_ARRAY_EXT         = &H8078
Const GL_EDGE_FLAG_ARRAY_EXT             = &H8079
Const GL_VERTEX_ARRAY_SIZE_EXT           = &H807A
Const GL_VERTEX_ARRAY_TYPE_EXT           = &H807B
Const GL_VERTEX_ARRAY_STRIDE_EXT         = &H807C
Const GL_VERTEX_ARRAY_COUNT_EXT          = &H807D
Const GL_NORMAL_ARRAY_TYPE_EXT           = &H807E
Const GL_NORMAL_ARRAY_STRIDE_EXT         = &H807F
Const GL_NORMAL_ARRAY_COUNT_EXT          = &H8080
Const GL_COLOR_ARRAY_SIZE_EXT            = &H8081
Const GL_COLOR_ARRAY_TYPE_EXT            = &H8082
Const GL_COLOR_ARRAY_STRIDE_EXT          = &H8083
Const GL_COLOR_ARRAY_COUNT_EXT           = &H8084
Const GL_INDEX_ARRAY_TYPE_EXT            = &H8085
Const GL_INDEX_ARRAY_STRIDE_EXT          = &H8086
Const GL_INDEX_ARRAY_COUNT_EXT           = &H8087
Const GL_TEXTURE_COORD_ARRAY_SIZE_EXT    = &H8088
Const GL_TEXTURE_COORD_ARRAY_TYPE_EXT    = &H8089
Const GL_TEXTURE_COORD_ARRAY_STRIDE_EXT  = &H808A
Const GL_TEXTURE_COORD_ARRAY_COUNT_EXT   = &H808B
Const GL_EDGE_FLAG_ARRAY_STRIDE_EXT      = &H808C
Const GL_EDGE_FLAG_ARRAY_COUNT_EXT       = &H808D
Const GL_VERTEX_ARRAY_POINTER_EXT        = &H808E
Const GL_NORMAL_ARRAY_POINTER_EXT        = &H808F
Const GL_COLOR_ARRAY_POINTER_EXT         = &H8090
Const GL_INDEX_ARRAY_POINTER_EXT         = &H8091
Const GL_TEXTURE_COORD_ARRAY_POINTER_EXT = &H8092
Const GL_EDGE_FLAG_ARRAY_POINTER_EXT     = &H8093
Const GL_DOUBLE_EXT                      = GL_DOUBLE

Const GL_BGR_EXT                         = &H80E0
Const GL_BGRA_EXT                        = &H80E1

Const GL_COLOR_TABLE_FORMAT_EXT          = &H80D8
Const GL_COLOR_TABLE_WIDTH_EXT           = &H80D9
Const GL_COLOR_TABLE_RED_SIZE_EXT        = &H80DA
Const GL_COLOR_TABLE_GREEN_SIZE_EXT      = &H80DB
Const GL_COLOR_TABLE_BLUE_SIZE_EXT       = &H80DC
Const GL_COLOR_TABLE_ALPHA_SIZE_EXT      = &H80DD
Const GL_COLOR_TABLE_LUMINANCE_SIZE_EXT  = &H80DE
Const GL_COLOR_TABLE_INTENSITY_SIZE_EXT  = &H80DF

Const GL_COLOR_INDEX1_EXT                = &H80E2
Const GL_COLOR_INDEX2_EXT                = &H80E3
Const GL_COLOR_INDEX4_EXT                = &H80E4
Const GL_COLOR_INDEX8_EXT                = &H80E5
Const GL_COLOR_INDEX12_EXT               = &H80E6
Const GL_COLOR_INDEX16_EXT               = &H80E7

Const GL_MAX_ELEMENTS_VERTICES_WIN       = &H80E8
Const GL_MAX_ELEMENTS_INDICES_WIN        = &H80E9

Const GL_PHONG_WIN                       = &H80EA 
Const GL_PHONG_HINT_WIN                  = &H80EB 

Const GL_FOG_SPECULAR_TEXTURE_WIN        = &H80EC

Const GL_LOGIC_OP                        = GL_INDEX_LOGIC_OP
Const GL_TEXTURE_COMPONENTS              = GL_TEXTURE_INTERNAL_FORMAT


DECLARE SUB glAccum                    LIB "opengl32.dll" ALIAS "glAccum"                  (BYVAL op AS DWORD, BYVAL value AS SINGLE)
DECLARE SUB glAlphaFunc                LIB "opengl32.dll" ALIAS "glAlphaFunc"              (BYVAL func AS DWORD, BYVAL ref AS SINGLE)
DECLARE FUNCTION glAreTexturesResident LIB "opengl32.dll" ALIAS "glAreTexturesResident"    (BYVAL n AS LONG, textures AS DWORD, residences AS LONG) AS BYTE
DECLARE SUB glArrayElement             LIB "opengl32.dll" ALIAS "glArrayElement"           (BYVAL i AS LONG)
DECLARE SUB glBegin                    LIB "opengl32.dll" ALIAS "glBegin"                  (BYVAL mode AS DWORD)
DECLARE SUB glBindTexture              LIB "opengl32.dll" ALIAS "glBindTexture"            (BYVAL ntarget AS DWORD, BYVAL texture AS DWORD)
DECLARE SUB glBitmap                   LIB "opengl32.dll" ALIAS "glBitmap"                 (BYVAL nwidth AS LONG, BYVAL height AS LONG, BYVAL xorig AS SINGLE, BYVAL yorig AS SINGLE, BYVAL xmove AS SINGLE, BYVAL ymove AS SINGLE, nbitmap AS LONG)
DECLARE SUB glBlendFunc                LIB "opengl32.dll" ALIAS "glBlendFunc"              (BYVAL sfactor AS DWORD, BYVAL dfactor AS DWORD)
DECLARE SUB glCallList                 LIB "opengl32.dll" ALIAS "glCallList"               (BYVAL list AS DWORD)
DECLARE SUB glCallLists                LIB "opengl32.dll" ALIAS "glCallLists"              (BYVAL n AS LONG, BYVAL ntype AS DWORD, lists AS LONG)
DECLARE SUB glClear                    LIB "opengl32.dll" ALIAS "glClear"                  (BYVAL mask AS DWORD)
DECLARE SUB glClearAccum               LIB "opengl32.dll" ALIAS "glClearAccum"             (BYVAL red AS SINGLE, BYVAL green AS SINGLE, BYVAL blue AS SINGLE, BYVAL alpha AS SINGLE)
DECLARE SUB glClearColor               LIB "opengl32.dll" ALIAS "glClearColor"             (BYVAL red AS SINGLE, BYVAL green AS SINGLE, BYVAL blue AS SINGLE, BYVAL alpha AS SINGLE)
DECLARE SUB glClearDepth               LIB "opengl32.dll" ALIAS "glClearDepth"             (BYVAL depth AS DOUBLE)
DECLARE SUB glClearIndex               LIB "opengl32.dll" ALIAS "glClearIndex"             (BYVAL c AS SINGLE)
DECLARE SUB glClearStencil             LIB "opengl32.dll" ALIAS "glClearStencil"           (BYVAL s AS LONG)
DECLARE SUB glClipPlane                LIB "opengl32.dll" ALIAS "glClipPlane"              (BYVAL plane AS DWORD, equation AS LONG)
DECLARE SUB glColor3b                  LIB "opengl32.dll" ALIAS "glColor3b"                (BYVAL red AS BYTE, BYVAL green AS BYTE, BYVAL blue AS BYTE)
DECLARE SUB glColor3bv                 LIB "opengl32.dll" ALIAS "glColor3bv"               (v AS LONG)
DECLARE SUB glColor3d                  LIB "opengl32.dll" ALIAS "glColor3d"                (BYVAL red AS DOUBLE, BYVAL green AS DOUBLE, BYVAL blue AS DOUBLE)
DECLARE SUB glColor3dv                 LIB "opengl32.dll" ALIAS "glColor3dv"               (v AS LONG)
DECLARE SUB glColor3f                  LIB "opengl32.dll" ALIAS "glColor3f"                (BYVAL red AS SINGLE, BYVAL green AS SINGLE, BYVAL blue AS SINGLE)
DECLARE SUB glColor3fv                 LIB "opengl32.dll" ALIAS "glColor3fv"               (v AS LONG)
DECLARE SUB glColor3i                  LIB "opengl32.dll" ALIAS "glColor3i"                (BYVAL red AS LONG, BYVAL green AS LONG, BYVAL blue AS LONG)
DECLARE SUB glColor3iv                 LIB "opengl32.dll" ALIAS "glColor3iv"               (v AS LONG)
DECLARE SUB glColor3s                  LIB "opengl32.dll" ALIAS "glColor3s"                (BYVAL red AS INTEGER, BYVAL green AS INTEGER, BYVAL blue AS INTEGER)
DECLARE SUB glColor3sv                 LIB "opengl32.dll" ALIAS "glColor3sv"               (v AS LONG)
DECLARE SUB glColor3ub                 LIB "opengl32.dll" ALIAS "glColor3ub"               (BYVAL red AS BYTE, BYVAL green AS BYTE, BYVAL blue AS BYTE)
DECLARE SUB glColor3ubv                LIB "opengl32.dll" ALIAS "glColor3ubv"              (v AS LONG)
DECLARE SUB glColor3ui                 LIB "opengl32.dll" ALIAS "glColor3ui"               (BYVAL red AS DWORD, BYVAL green AS DWORD, BYVAL blue AS DWORD)
DECLARE SUB glColor3uiv                LIB "opengl32.dll" ALIAS "glColor3uiv"              (v AS LONG)
DECLARE SUB glColor3us                 LIB "opengl32.dll" ALIAS "glColor3us"               (BYVAL red AS WORD, BYVAL green AS WORD, BYVAL blue AS WORD)
DECLARE SUB glColor3usv                LIB "opengl32.dll" ALIAS "glColor3usv"              (v AS LONG)
DECLARE SUB glColor4b                  LIB "opengl32.dll" ALIAS "glColor4b"                (BYVAL red AS BYTE, BYVAL green AS BYTE, BYVAL blue AS BYTE, BYVAL alpha AS BYTE)
DECLARE SUB glColor4bv                 LIB "opengl32.dll" ALIAS "glColor4bv"               (v AS LONG)
DECLARE SUB glColor4d                  LIB "opengl32.dll" ALIAS "glColor4d"                (BYVAL red AS DOUBLE, BYVAL green AS DOUBLE, BYVAL blue AS DOUBLE, BYVAL alpha AS DOUBLE)
DECLARE SUB glColor4dv                 LIB "opengl32.dll" ALIAS "glColor4dv"               (v AS LONG)
DECLARE SUB glColor4f                  LIB "opengl32.dll" ALIAS "glColor4f"                (BYVAL red AS SINGLE, BYVAL green AS SINGLE, BYVAL blue AS SINGLE, BYVAL alpha AS SINGLE)
DECLARE SUB glColor4fv                 LIB "opengl32.dll" ALIAS "glColor4fv"               (v AS LONG)
DECLARE SUB glColor4i                  LIB "opengl32.dll" ALIAS "glColor4i"                (BYVAL red AS LONG, BYVAL green AS LONG, BYVAL blue AS LONG, BYVAL alpha AS LONG)
DECLARE SUB glColor4iv                 LIB "opengl32.dll" ALIAS "glColor4iv"               (v AS LONG)
DECLARE SUB glColor4s                  LIB "opengl32.dll" ALIAS "glColor4s"                (BYVAL red AS INTEGER, BYVAL green AS INTEGER, BYVAL blue AS INTEGER, BYVAL alpha AS INTEGER)
DECLARE SUB glColor4sv                 LIB "opengl32.dll" ALIAS "glColor4sv"               (v AS LONG)
DECLARE SUB glColor4ub                 LIB "opengl32.dll" ALIAS "glColor4ub"               (BYVAL red AS BYTE, BYVAL green AS BYTE, BYVAL blue AS BYTE, BYVAL alpha AS BYTE)
DECLARE SUB glColor4ubv                LIB "opengl32.dll" ALIAS "glColor4ubv"              (v AS LONG)
DECLARE SUB glColor4ui                 LIB "opengl32.dll" ALIAS "glColor4ui"               (BYVAL red AS DWORD, BYVAL green AS DWORD, BYVAL blue AS DWORD, BYVAL alpha AS DWORD)
DECLARE SUB glColor4uiv                LIB "opengl32.dll" ALIAS "glColor4uiv"              (v AS LONG)
DECLARE SUB glColor4us                 LIB "opengl32.dll" ALIAS "glColor4us"               (BYVAL red AS WORD, BYVAL green AS WORD, BYVAL blue AS WORD, BYVAL alpha AS WORD)
DECLARE SUB glColor4usv                LIB "opengl32.dll" ALIAS "glColor4usv"              (v AS LONG)
DECLARE SUB glColorMask                LIB "opengl32.dll" ALIAS "glColorMask"              (BYVAL red AS BYTE, BYVAL green AS BYTE, BYVAL blue AS BYTE, BYVAL alpha AS BYTE)
DECLARE SUB glColorMaterial            LIB "opengl32.dll" ALIAS "glColorMaterial"          (BYVAL face AS DWORD, BYVAL mode AS DWORD)
DECLARE SUB glColorPointer             LIB "opengl32.dll" ALIAS "glColorPointer"           (BYVAL lsize AS LONG, BYVAL ntype AS DWORD, BYVAL stride AS LONG, pointer AS LONG)
DECLARE SUB glCopyPixels               LIB "opengl32.dll" ALIAS "glCopyPixels"             (BYVAL x AS LONG, BYVAL y AS LONG, BYVAL nwidth AS LONG, BYVAL height AS LONG, BYVAL ntype AS DWORD)
DECLARE SUB glCopyTexImage1D           LIB "opengl32.dll" ALIAS "glCopyTexImage1D"         (BYVAL ntarget AS DWORD, BYVAL level AS LONG, BYVAL internalFormat AS DWORD, BYVAL x AS LONG, BYVAL y AS LONG, BYVAL nwidth AS LONG, BYVAL border AS LONG)
DECLARE SUB glCopyTexImage2D           LIB "opengl32.dll" ALIAS "glCopyTexImage2D"         (BYVAL ntarget AS DWORD, BYVAL level AS LONG, BYVAL internalFormat AS DWORD, BYVAL x AS LONG, BYVAL y AS LONG, BYVAL nwidth AS LONG, BYVAL height AS LONG, BYVAL border AS LONG)
DECLARE SUB glCopyTexSubImage1D        LIB "opengl32.dll" ALIAS "glCopyTexSubImage1D"      (BYVAL ntarget AS DWORD, BYVAL level AS LONG, BYVAL xoffset AS LONG, BYVAL x AS LONG, BYVAL y AS LONG, BYVAL nwidth AS LONG)
DECLARE SUB glCopyTexSubImage2D        LIB "opengl32.dll" ALIAS "glCopyTexSubImage2D"      (BYVAL ntarget AS DWORD, BYVAL level AS LONG, BYVAL xoffset AS LONG, BYVAL yoffset AS LONG, BYVAL x AS LONG, BYVAL y AS LONG, BYVAL nwidth AS LONG, BYVAL height AS LONG)
DECLARE SUB glCullFace                 LIB "opengl32.dll" ALIAS "glCullFace"               (BYVAL mode AS DWORD)
DECLARE SUB glDeleteLists              LIB "opengl32.dll" ALIAS "glDeleteLists"            (BYVAL list AS DWORD, BYVAL range AS LONG)
DECLARE SUB glDeleteTextures           LIB "opengl32.dll" ALIAS "glDeleteTextures"         (BYVAL n AS LONG, textures AS LONG)
DECLARE SUB glDepthFunc                LIB "opengl32.dll" ALIAS "glDepthFunc"              (BYVAL func AS DWORD)
DECLARE SUB glDepthMask                LIB "opengl32.dll" ALIAS "glDepthMask"              (BYVAL flag AS BYTE)
DECLARE SUB glDepthRange               LIB "opengl32.dll" ALIAS "glDepthRange"             (BYVAL zNear AS DOUBLE, BYVAL zFar AS DOUBLE)
DECLARE SUB glDisable                  LIB "opengl32.dll" ALIAS "glDisable"                (BYVAL cap AS DWORD)
DECLARE SUB glDisableClientState       LIB "opengl32.dll" ALIAS "glDisableClientState"     (BYVAL narray AS DWORD)
DECLARE SUB glDrawArrays               LIB "opengl32.dll" ALIAS "glDrawArrays"             (BYVAL mode AS DWORD, BYVAL first AS LONG, BYVAL count AS LONG)
DECLARE SUB glDrawBuffer               LIB "opengl32.dll" ALIAS "glDrawBuffer"             (BYVAL mode AS DWORD)
DECLARE SUB glDrawElements             LIB "opengl32.dll" ALIAS "glDrawElements"           (BYVAL mode AS DWORD, BYVAL count AS LONG, BYVAL ntype AS DWORD, indices AS LONG)
DECLARE SUB glDrawPixels               LIB "opengl32.dll" ALIAS "glDrawPixels"             (BYVAL nwidth AS LONG, BYVAL height AS LONG, BYVAL nformat AS DWORD, BYVAL ntype AS DWORD, npixels AS LONG)
DECLARE SUB glEdgeFlag                 LIB "opengl32.dll" ALIAS "glEdgeFlag"               (BYVAL flag AS BYTE)
DECLARE SUB glEdgeFlagPointer          LIB "opengl32.dll" ALIAS "glEdgeFlagPointer"        (BYVAL stride AS LONG, pointer AS LONG)
DECLARE SUB glEdgeFlagv                LIB "opengl32.dll" ALIAS "glEdgeFlagv"              (flag AS BYTE)
DECLARE SUB glEnable                   LIB "opengl32.dll" ALIAS "glEnable"                 (BYVAL cap AS DWORD)
DECLARE SUB glEnableClientState        LIB "opengl32.dll" ALIAS "glEnableClientState"      (BYVAL narray AS DWORD)
DECLARE SUB glEnd                      LIB "opengl32.dll" ALIAS "glEnd"                    ()
DECLARE SUB glEndList                  LIB "opengl32.dll" ALIAS "glEndList"                ()
DECLARE SUB glEvalCoord1d              LIB "opengl32.dll" ALIAS "glEvalCoord1d"            (BYVAL u AS DOUBLE)
DECLARE SUB glEvalCoord1dv             LIB "opengl32.dll" ALIAS "glEvalCoord1dv"           (u AS DOUBLE)
DECLARE SUB glEvalCoord1f              LIB "opengl32.dll" ALIAS "glEvalCoord1f"            (BYVAL u AS SINGLE)
DECLARE SUB glEvalCoord1fv             LIB "opengl32.dll" ALIAS "glEvalCoord1fv"           (u AS SINGLE)
DECLARE SUB glEvalCoord2d              LIB "opengl32.dll" ALIAS "glEvalCoord2d"            (BYVAL u AS DOUBLE, BYVAL v AS DOUBLE)
DECLARE SUB glEvalCoord2dv             LIB "opengl32.dll" ALIAS "glEvalCoord2dv"           (u AS LONG)
DECLARE SUB glEvalCoord2f              LIB "opengl32.dll" ALIAS "glEvalCoord2f"            (BYVAL u AS SINGLE, BYVAL v AS SINGLE)
DECLARE SUB glEvalCoord2fv             LIB "opengl32.dll" ALIAS "glEvalCoord2fv"           (u AS LONG)
DECLARE SUB glEvalMesh1                LIB "opengl32.dll" ALIAS "glEvalMesh1"              (BYVAL mode AS DWORD, BYVAL i1 AS LONG, BYVAL i2 AS LONG)
DECLARE SUB glEvalMesh2                LIB "opengl32.dll" ALIAS "glEvalMesh2"              (BYVAL mode AS DWORD, BYVAL i1 AS LONG, BYVAL i2 AS LONG, BYVAL j1 AS LONG, BYVAL j2 AS LONG)
DECLARE SUB glEvalPoint1               LIB "opengl32.dll" ALIAS "glEvalPoint1"             (BYVAL i AS LONG)
DECLARE SUB glEvalPoint2               LIB "opengl32.dll" ALIAS "glEvalPoint2"             (BYVAL i AS LONG, BYVAL j AS LONG)
DECLARE SUB glFeedbackBuffer           LIB "opengl32.dll" ALIAS "glFeedbackBuffer"         (BYVAL lsize AS LONG, BYVAL ntype AS DWORD, buffer AS LONG)
DECLARE SUB glFinish                   LIB "opengl32.dll" ALIAS "glFinish"                 ()
DECLARE SUB glFlush                    LIB "opengl32.dll" ALIAS "glFlush"                  ()
DECLARE SUB glFogf                     LIB "opengl32.dll" ALIAS "glFogf"                   (BYVAL pname AS DWORD, BYVAL param AS SINGLE)
DECLARE SUB glFogfv                    LIB "opengl32.dll" ALIAS "glFogfv"                  (BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glFogi                     LIB "opengl32.dll" ALIAS "glFogi"                   (BYVAL pname AS DWORD, BYVAL param AS LONG)
DECLARE SUB glFogiv                    LIB "opengl32.dll" ALIAS "glFogiv"                  (BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glFrontFace                LIB "opengl32.dll" ALIAS "glFrontFace"              (BYVAL mode AS DWORD)
DECLARE SUB glFrustum                  LIB "opengl32.dll" ALIAS "glFrustum"                (BYVAL nleft AS DOUBLE, BYVAL nright AS DOUBLE, BYVAL bottom AS DOUBLE, BYVAL top AS DOUBLE, BYVAL zNear AS DOUBLE, BYVAL zFar AS DOUBLE)
DECLARE FUNCTION glGenLists            LIB "opengl32.dll" ALIAS "glGenLists"               (BYVAL range AS LONG) AS DWORD
DECLARE SUB glGenTextures              LIB "opengl32.dll" ALIAS "glGenTextures"            (BYVAL n AS LONG, textures AS LONG)
DECLARE SUB glGetBooleanv              LIB "opengl32.dll" ALIAS "glGetBooleanv"            (BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glGetClipPlane             LIB "opengl32.dll" ALIAS "glGetClipPlane"           (BYVAL plane AS DWORD, equation AS LONG)
DECLARE SUB glGetDoublev               LIB "opengl32.dll" ALIAS "glGetDoublev"             (BYVAL pname AS DWORD, params AS LONG)
DECLARE FUNCTION glGetError            LIB "opengl32.dll" ALIAS "glGetError"               () AS DWORD
DECLARE SUB glGetFloatv                LIB "opengl32.dll" ALIAS "glGetFloatv"              (BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glGetIntegerv              LIB "opengl32.dll" ALIAS "glGetIntegerv"            (BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glGetLightfv               LIB "opengl32.dll" ALIAS "glGetLightfv"             (BYVAL light AS DWORD, BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glGetLightiv               LIB "opengl32.dll" ALIAS "glGetLightiv"             (BYVAL light AS DWORD, BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glGetMapdv                 LIB "opengl32.dll" ALIAS "glGetMapdv"               (BYVAL ntarget AS DWORD, BYVAL query AS DWORD, v AS LONG)
DECLARE SUB glGetMapfv                 LIB "opengl32.dll" ALIAS "glGetMapfv"               (BYVAL ntarget AS DWORD, BYVAL query AS DWORD, v AS LONG)
DECLARE SUB glGetMapiv                 LIB "opengl32.dll" ALIAS "glGetMapiv"               (BYVAL ntarget AS DWORD, BYVAL query AS DWORD, v AS LONG)
DECLARE SUB glGetMaterialfv            LIB "opengl32.dll" ALIAS "glGetMaterialfv"          (BYVAL face AS DWORD, BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glGetMaterialiv            LIB "opengl32.dll" ALIAS "glGetMaterialiv"          (BYVAL face AS DWORD, BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glGetPixelMapfv            LIB "opengl32.dll" ALIAS "glGetPixelMapfv"          (BYVAL map AS DWORD, values AS LONG)
DECLARE SUB glGetPixelMapuiv           LIB "opengl32.dll" ALIAS "glGetPixelMapuiv"         (BYVAL map AS DWORD, values AS LONG)
DECLARE SUB glGetPixelMapusv           LIB "opengl32.dll" ALIAS "glGetPixelMapusv"         (BYVAL map AS DWORD, values AS LONG)
DECLARE SUB glGetPointerv              LIB "opengl32.dll" ALIAS "glGetPointerv"            (BYVAL pname AS DWORD, params AS LONG) ' pass a pointer to a bunch of data (GLvoid* *params)
DECLARE SUB glGetPolygonStipple        LIB "opengl32.dll" ALIAS "glGetPolygonStipple"      (mask AS LONG)
DECLARE FUNCTION glGetString           LIB "opengl32.dll" ALIAS "glGetString"              (BYVAL nname AS DWORD) AS LONG  ' (pointer to STRING...)
DECLARE SUB glGetTexEnvfv              LIB "opengl32.dll" ALIAS "glGetTexEnvfv"            (BYVAL ntarget AS DWORD, BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glGetTexEnviv              LIB "opengl32.dll" ALIAS "glGetTexEnviv"            (BYVAL ntarget AS DWORD, BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glGetTexGendv              LIB "opengl32.dll" ALIAS "glGetTexGendv"            (BYVAL ncoord AS DWORD, BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glGetTexGenfv              LIB "opengl32.dll" ALIAS "glGetTexGenfv"            (BYVAL ncoord AS DWORD, BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glGetTexGeniv              LIB "opengl32.dll" ALIAS "glGetTexGeniv"            (BYVAL ncoord AS DWORD, BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glGetTexImage              LIB "opengl32.dll" ALIAS "glGetTexImage"            (BYVAL ntarget AS DWORD, BYVAL level AS LONG, BYVAL nformat AS DWORD, BYVAL ntype AS DWORD, npixels AS LONG)
DECLARE SUB glGetTexLevelParameterfv   LIB "opengl32.dll" ALIAS "glGetTexLevelParameterfv" (BYVAL ntarget AS DWORD, BYVAL level AS LONG, BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glGetTexLevelParameteriv   LIB "opengl32.dll" ALIAS "glGetTexLevelParameteriv" (BYVAL ntarget AS DWORD, BYVAL level AS LONG, BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glGetTexParameterfv        LIB "opengl32.dll" ALIAS "glGetTexParameterfv"      (BYVAL ntarget AS DWORD, BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glGetTexParameteriv        LIB "opengl32.dll" ALIAS "glGetTexParameteriv"      (BYVAL ntarget AS DWORD, BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glHint                     LIB "opengl32.dll" ALIAS "glHint"                   (BYVAL ntarget AS DWORD, BYVAL mode AS DWORD)
DECLARE SUB glIndexMask                LIB "opengl32.dll" ALIAS "glIndexMask"              (BYVAL mask AS DWORD)
DECLARE SUB glIndexPointer             LIB "opengl32.dll" ALIAS "glIndexPointer"           (BYVAL ntype AS DWORD, BYVAL stride AS LONG, pointer AS LONG)
DECLARE SUB glIndexd                   LIB "opengl32.dll" ALIAS "glIndexd"                 (BYVAL c AS DOUBLE)
DECLARE SUB glIndexdv                  LIB "opengl32.dll" ALIAS "glIndexdv"                (c AS DOUBLE)
DECLARE SUB glIndexf                   LIB "opengl32.dll" ALIAS "glIndexf"                 (BYVAL c AS SINGLE)
DECLARE SUB glIndexfv                  LIB "opengl32.dll" ALIAS "glIndexfv"                (c AS SINGLE)
DECLARE SUB glIndexi                   LIB "opengl32.dll" ALIAS "glIndexi"                 (BYVAL c AS LONG)
DECLARE SUB glIndexiv                  LIB "opengl32.dll" ALIAS "glIndexiv"                (c AS LONG)
DECLARE SUB glIndexs                   LIB "opengl32.dll" ALIAS "glIndexs"                 (BYVAL c AS INTEGER)
DECLARE SUB glIndexsv                  LIB "opengl32.dll" ALIAS "glIndexsv"                (c AS INTEGER)
DECLARE SUB glIndexub                  LIB "opengl32.dll" ALIAS "glIndexub"                (BYVAL c AS BYTE)
DECLARE SUB glIndexubv                 LIB "opengl32.dll" ALIAS "glIndexubv"               (c AS BYTE)
DECLARE SUB glInitNames                LIB "opengl32.dll" ALIAS "glInitNames"              ()
DECLARE SUB LONGerleavedArrays         LIB "opengl32.dll" ALIAS "LONGerleavedArrays"       (BYVAL nformat AS DWORD, BYVAL stride AS LONG, pointer AS LONG)
DECLARE FUNCTION glIsEnabled           LIB "opengl32.dll" ALIAS "glIsEnabled"              (BYVAL cap AS DWORD) AS BYTE
DECLARE FUNCTION glIsList              LIB "opengl32.dll" ALIAS "glIsList"                 (BYVAL list AS DWORD) AS BYTE
DECLARE FUNCTION glIsTexture           LIB "opengl32.dll" ALIAS "glIsTexture"              (BYVAL texture AS DWORD) AS BYTE
DECLARE SUB glLightModelf              LIB "opengl32.dll" ALIAS "glLightModelf"            (BYVAL pname AS DWORD, BYVAL param AS SINGLE)
DECLARE SUB glLightModelfv             LIB "opengl32.dll" ALIAS "glLightModelfv"           (BYVAL pname AS DWORD, params AS SINGLE)
DECLARE SUB glLightModeli              LIB "opengl32.dll" ALIAS "glLightModeli"            (BYVAL pname AS DWORD, BYVAL param AS LONG)
DECLARE SUB glLightModeliv             LIB "opengl32.dll" ALIAS "glLightModeliv"           (BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glLightf                   LIB "opengl32.dll" ALIAS "glLightf"                 (BYVAL light AS DWORD, BYVAL pname AS DWORD, BYVAL param AS SINGLE)
DECLARE SUB glLightfv                  LIB "opengl32.dll" ALIAS "glLightfv"                (BYVAL light AS DWORD, BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glLighti                   LIB "opengl32.dll" ALIAS "glLighti"                 (BYVAL light AS DWORD, BYVAL pname AS DWORD, BYVAL param AS LONG)
DECLARE SUB glLightiv                  LIB "opengl32.dll" ALIAS "glLightiv"                (BYVAL light AS DWORD, BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glLineStipple              LIB "opengl32.dll" ALIAS "glLineStipple"            (BYVAL factor AS LONG, BYVAL pattern AS WORD)
DECLARE SUB glLineWidth                LIB "opengl32.dll" ALIAS "glLineWidth"              (BYVAL nwidth AS SINGLE)
DECLARE SUB glListBase                 LIB "opengl32.dll" ALIAS "glListBase"               (BYVAL nbase AS DWORD)
DECLARE SUB glLoadIdentity             LIB "opengl32.dll" ALIAS "glLoadIdentity"           ()
DECLARE SUB glLoadMatrixd              LIB "opengl32.dll" ALIAS "glLoadMatrixd"            (m AS LONG)
DECLARE SUB glLoadMatrixf              LIB "opengl32.dll" ALIAS "glLoadMatrixf"            (m AS LONG)
DECLARE SUB glLoadName                 LIB "opengl32.dll" ALIAS "glLoadName"               (BYVAL nname AS DWORD)
DECLARE SUB glLogicOp                  LIB "opengl32.dll" ALIAS "glLogicOp"                (BYVAL opcode AS DWORD)
DECLARE SUB glMap1d                    LIB "opengl32.dll" ALIAS "glMap1d"                  (BYVAL ntarget AS DWORD, BYVAL u1 AS DOUBLE, BYVAL u2 AS DOUBLE, BYVAL stride AS LONG, BYVAL order AS LONG, npoints AS LONG)
DECLARE SUB glMap1f                    LIB "opengl32.dll" ALIAS "glMap1f"                  (BYVAL ntarget AS DWORD, BYVAL u1 AS SINGLE, BYVAL u2 AS SINGLE, BYVAL stride AS LONG, BYVAL order AS LONG, npoints AS LONG)
DECLARE SUB glMap2d                    LIB "opengl32.dll" ALIAS "glMap2d"                  (BYVAL ntarget AS DWORD, BYVAL u1 AS DOUBLE, BYVAL u2 AS DOUBLE, BYVAL ustride AS LONG, BYVAL uorder AS LONG, BYVAL v1 AS DOUBLE, BYVAL v2 AS DOUBLE, BYVAL vstride AS LONG, BYVAL vorder AS LONG, npoints AS LONG)
DECLARE SUB glMap2f                    LIB "opengl32.dll" ALIAS "glMap2f"                  (BYVAL ntarget AS DWORD, BYVAL u1 AS SINGLE, BYVAL u2 AS SINGLE, BYVAL ustride AS LONG, BYVAL uorder AS LONG, BYVAL v1 AS SINGLE, BYVAL v2 AS SINGLE, BYVAL vstride AS LONG, BYVAL vorder AS LONG, npoints AS LONG)
DECLARE SUB glMapGrid1d                LIB "opengl32.dll" ALIAS "glMapGrid1d"              (BYVAL un AS LONG, BYVAL u1 AS DOUBLE, BYVAL u2 AS DOUBLE)
DECLARE SUB glMapGrid1f                LIB "opengl32.dll" ALIAS "glMapGrid1f"              (BYVAL un AS LONG, BYVAL u1 AS SINGLE, BYVAL u2 AS SINGLE)
DECLARE SUB glMapGrid2d                LIB "opengl32.dll" ALIAS "glMapGrid2d"              (BYVAL un AS LONG, BYVAL u1 AS DOUBLE, BYVAL u2 AS DOUBLE, BYVAL vn AS LONG, BYVAL v1 AS DOUBLE, BYVAL v2 AS DOUBLE)
DECLARE SUB glMapGrid2f                LIB "opengl32.dll" ALIAS "glMapGrid2f"              (BYVAL un AS LONG, BYVAL u1 AS SINGLE, BYVAL u2 AS SINGLE, BYVAL vn AS LONG, BYVAL v1 AS SINGLE, BYVAL v2 AS SINGLE)
DECLARE SUB glMaterialf                LIB "opengl32.dll" ALIAS "glMaterialf"              (BYVAL face AS DWORD, BYVAL pname AS DWORD, BYVAL param AS SINGLE)
DECLARE SUB glMaterialfv               LIB "opengl32.dll" ALIAS "glMaterialfv"             (BYVAL face AS DWORD, BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glMateriali                LIB "opengl32.dll" ALIAS "glMateriali"              (BYVAL face AS DWORD, BYVAL pname AS DWORD, BYVAL param AS LONG)
DECLARE SUB glMaterialiv               LIB "opengl32.dll" ALIAS "glMaterialiv"             (BYVAL face AS DWORD, BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glMatrixMode               LIB "opengl32.dll" ALIAS "glMatrixMode"             (BYVAL mode AS DWORD)
DECLARE SUB glMultMatrixd              LIB "opengl32.dll" ALIAS "glMultMatrixd"            (m AS LONG)
DECLARE SUB glMultMatrixf              LIB "opengl32.dll" ALIAS "glMultMatrixf"            (m AS LONG)
DECLARE SUB glNewList                  LIB "opengl32.dll" ALIAS "glNewList"                (BYVAL list AS DWORD, BYVAL mode AS DWORD)
DECLARE SUB glNormal3b                 LIB "opengl32.dll" ALIAS "glNormal3b"               (BYVAL nx AS BYTE, BYVAL ny AS BYTE, BYVAL nz AS BYTE)
DECLARE SUB glNormal3bv                LIB "opengl32.dll" ALIAS "glNormal3bv"              (v AS LONG)
DECLARE SUB glNormal3d                 LIB "opengl32.dll" ALIAS "glNormal3d"               (BYVAL nx AS DOUBLE, BYVAL ny AS DOUBLE, BYVAL nz AS DOUBLE)
DECLARE SUB glNormal3dv                LIB "opengl32.dll" ALIAS "glNormal3dv"              (v AS LONG)
DECLARE SUB glNormal3f                 LIB "opengl32.dll" ALIAS "glNormal3f"               (BYVAL nx AS SINGLE, BYVAL ny AS SINGLE, BYVAL nz AS SINGLE)
DECLARE SUB glNormal3fv                LIB "opengl32.dll" ALIAS "glNormal3fv"              (v AS LONG)
DECLARE SUB glNormal3i                 LIB "opengl32.dll" ALIAS "glNormal3i"               (BYVAL nx AS LONG, BYVAL ny AS LONG, BYVAL nz AS LONG)
DECLARE SUB glNormal3iv                LIB "opengl32.dll" ALIAS "glNormal3iv"              (v AS LONG)
DECLARE SUB glNormal3s                 LIB "opengl32.dll" ALIAS "glNormal3s"               (BYVAL nx AS INTEGER, BYVAL ny AS INTEGER, BYVAL nz AS INTEGER)
DECLARE SUB glNormal3sv                LIB "opengl32.dll" ALIAS "glNormal3sv"              (v AS LONG)
DECLARE SUB glNormalPointer            LIB "opengl32.dll" ALIAS "glNormalPointer"          (BYVAL ntype AS DWORD, BYVAL stride AS LONG, pointer AS LONG)
DECLARE SUB glOrtho                    LIB "opengl32.dll" ALIAS "glOrtho"                  (BYVAL nleft AS DOUBLE, BYVAL nright AS DOUBLE, BYVAL bottom AS DOUBLE, BYVAL top AS DOUBLE, BYVAL zNear AS DOUBLE, BYVAL zFar AS DOUBLE)
DECLARE SUB glPassThrough              LIB "opengl32.dll" ALIAS "glPassThrough"            (BYVAL token AS SINGLE)
DECLARE SUB glPixelMapfv               LIB "opengl32.dll" ALIAS "glPixelMapfv"             (BYVAL map AS DWORD, BYVAL mapsize AS LONG, values AS LONG)
DECLARE SUB glPixelMapuiv              LIB "opengl32.dll" ALIAS "glPixelMapuiv"            (BYVAL map AS DWORD, BYVAL mapsize AS LONG, values AS LONG)
DECLARE SUB glPixelMapusv              LIB "opengl32.dll" ALIAS "glPixelMapusv"            (BYVAL map AS DWORD, BYVAL mapsize AS LONG, values AS LONG)
DECLARE SUB glPixelStoref              LIB "opengl32.dll" ALIAS "glPixelStoref"            (BYVAL pname AS DWORD, BYVAL param AS SINGLE)
DECLARE SUB glPixelStorei              LIB "opengl32.dll" ALIAS "glPixelStorei"            (BYVAL pname AS DWORD, BYVAL param AS LONG)
DECLARE SUB glPixelTransferf           LIB "opengl32.dll" ALIAS "glPixelTransferf"         (BYVAL pname AS DWORD, BYVAL param AS SINGLE)
DECLARE SUB glPixelTransferi           LIB "opengl32.dll" ALIAS "glPixelTransferi"         (BYVAL pname AS DWORD, BYVAL param AS LONG)
DECLARE SUB glPixelZoom                LIB "opengl32.dll" ALIAS "glPixelZoom"              (BYVAL xfactor AS SINGLE, BYVAL yfactor AS SINGLE)
DECLARE SUB glPointSize                LIB "opengl32.dll" ALIAS "glPointSize"              (BYVAL lsize AS SINGLE)
DECLARE SUB glPolygonMode              LIB "opengl32.dll" ALIAS "glPolygonMode"            (BYVAL face AS DWORD, BYVAL mode AS DWORD)
DECLARE SUB glPolygonOffset            LIB "opengl32.dll" ALIAS "glPolygonOffset"          (BYVAL factor AS SINGLE, BYVAL nunits AS SINGLE)
DECLARE SUB glPolygonStipple           LIB "opengl32.dll" ALIAS "glPolygonStipple"         (mask AS LONG)
DECLARE SUB glPopAttrib                LIB "opengl32.dll" ALIAS "glPopAttrib"              ()
DECLARE SUB glPopClientAttrib          LIB "opengl32.dll" ALIAS "glPopClientAttrib"        ()
DECLARE SUB glPopMatrix                LIB "opengl32.dll" ALIAS "glPopMatrix"              ()
DECLARE SUB glPopName                  LIB "opengl32.dll" ALIAS "glPopName"                ()
DECLARE SUB glPrioritizeTextures       LIB "opengl32.dll" ALIAS "glPrioritizeTextures"     (BYVAL n AS LONG, textures AS DWORD, priorities AS LONG)
DECLARE SUB glPushAttrib               LIB "opengl32.dll" ALIAS "glPushAttrib"             (BYVAL mask AS DWORD)
DECLARE SUB glPushClientAttrib         LIB "opengl32.dll" ALIAS "glPushClientAttrib"       (BYVAL mask AS DWORD)
DECLARE SUB glPushMatrix               LIB "opengl32.dll" ALIAS "glPushMatrix"             ()
DECLARE SUB glPushName                 LIB "opengl32.dll" ALIAS "glPushName"               (BYVAL nname AS DWORD)
DECLARE SUB glRasterPos2d              LIB "opengl32.dll" ALIAS "glRasterPos2d"            (BYVAL x AS DOUBLE, BYVAL y AS DOUBLE)
DECLARE SUB glRasterPos2dv             LIB "opengl32.dll" ALIAS "glRasterPos2dv"           (v AS LONG)
DECLARE SUB glRasterPos2f              LIB "opengl32.dll" ALIAS "glRasterPos2f"            (BYVAL x AS SINGLE, BYVAL y AS SINGLE)
DECLARE SUB glRasterPos2fv             LIB "opengl32.dll" ALIAS "glRasterPos2fv"           (v AS LONG)
DECLARE SUB glRasterPos2i              LIB "opengl32.dll" ALIAS "glRasterPos2i"            (BYVAL x AS LONG, BYVAL y AS LONG)
DECLARE SUB glRasterPos2iv             LIB "opengl32.dll" ALIAS "glRasterPos2iv"           (v AS LONG)
DECLARE SUB glRasterPos2s              LIB "opengl32.dll" ALIAS "glRasterPos2s"            (BYVAL x AS INTEGER, BYVAL y AS INTEGER)
DECLARE SUB glRasterPos2sv             LIB "opengl32.dll" ALIAS "glRasterPos2sv"           (v AS LONG)
DECLARE SUB glRasterPos3d              LIB "opengl32.dll" ALIAS "glRasterPos3d"            (BYVAL x AS DOUBLE, BYVAL y AS DOUBLE, BYVAL z AS DOUBLE)
DECLARE SUB glRasterPos3dv             LIB "opengl32.dll" ALIAS "glRasterPos3dv"           (v AS LONG)
DECLARE SUB glRasterPos3f              LIB "opengl32.dll" ALIAS "glRasterPos3f"            (BYVAL x AS SINGLE, BYVAL y AS SINGLE, BYVAL z AS SINGLE)
DECLARE SUB glRasterPos3fv             LIB "opengl32.dll" ALIAS "glRasterPos3fv"           (v AS LONG)
DECLARE SUB glRasterPos3i              LIB "opengl32.dll" ALIAS "glRasterPos3i"            (BYVAL x AS LONG, BYVAL y AS LONG, BYVAL z AS LONG)
DECLARE SUB glRasterPos3iv             LIB "opengl32.dll" ALIAS "glRasterPos3iv"           (v AS LONG)
DECLARE SUB glRasterPos3s              LIB "opengl32.dll" ALIAS "glRasterPos3s"            (BYVAL x AS INTEGER, BYVAL y AS INTEGER, BYVAL z AS INTEGER)
DECLARE SUB glRasterPos3sv             LIB "opengl32.dll" ALIAS "glRasterPos3sv"           (v AS LONG)
DECLARE SUB glRasterPos4d              LIB "opengl32.dll" ALIAS "glRasterPos4d"            (BYVAL x AS DOUBLE, BYVAL y AS DOUBLE, BYVAL z AS DOUBLE, BYVAL w AS DOUBLE)
DECLARE SUB glRasterPos4dv             LIB "opengl32.dll" ALIAS "glRasterPos4dv"           (v AS LONG)
DECLARE SUB glRasterPos4f              LIB "opengl32.dll" ALIAS "glRasterPos4f"            (BYVAL x AS SINGLE, BYVAL y AS SINGLE, BYVAL z AS SINGLE, BYVAL w AS SINGLE)
DECLARE SUB glRasterPos4fv             LIB "opengl32.dll" ALIAS "glRasterPos4fv"           (v AS LONG)
DECLARE SUB glRasterPos4i              LIB "opengl32.dll" ALIAS "glRasterPos4i"            (BYVAL x AS LONG, BYVAL y AS LONG, BYVAL z AS LONG, BYVAL w AS LONG)
DECLARE SUB glRasterPos4iv             LIB "opengl32.dll" ALIAS "glRasterPos4iv"           (v AS LONG)
DECLARE SUB glRasterPos4s              LIB "opengl32.dll" ALIAS "glRasterPos4s"            (BYVAL x AS INTEGER, BYVAL y AS INTEGER, BYVAL z AS INTEGER, BYVAL w AS INTEGER)
DECLARE SUB glRasterPos4sv             LIB "opengl32.dll" ALIAS "glRasterPos4sv"           (v AS LONG)
DECLARE SUB glReadBuffer               LIB "opengl32.dll" ALIAS "glReadBuffer"             (BYVAL mode AS DWORD)
DECLARE SUB glReadPixels               LIB "opengl32.dll" ALIAS "glReadPixels"             (BYVAL x AS LONG, BYVAL y AS LONG, BYVAL nwidth AS LONG, BYVAL height AS LONG, BYVAL format AS DWORD, BYVAL ntype AS DWORD, npixels AS LONG)
DECLARE SUB glRectd                    LIB "opengl32.dll" ALIAS "glRectd"                  (BYVAL x1 AS DOUBLE, BYVAL y1 AS DOUBLE, BYVAL x2 AS DOUBLE, BYVAL y2 AS DOUBLE)
DECLARE SUB glRectdv                   LIB "opengl32.dll" ALIAS "glRectdv"                 (v1 AS LONG, v2 AS LONG)
DECLARE SUB glRectf                    LIB "opengl32.dll" ALIAS "glRectf"                  (BYVAL x1 AS SINGLE, BYVAL y1 AS SINGLE, BYVAL x2 AS SINGLE, BYVAL y2 AS SINGLE)
DECLARE SUB glRectfv                   LIB "opengl32.dll" ALIAS "glRectfv"                 (v1 AS LONG, v2 AS LONG)
DECLARE SUB glRecti                    LIB "opengl32.dll" ALIAS "glRecti"                  (BYVAL x1 AS LONG, BYVAL y1 AS LONG, BYVAL x2 AS LONG, BYVAL y2 AS LONG)
DECLARE SUB glRectiv                   LIB "opengl32.dll" ALIAS "glRectiv"                 (v1 AS LONG, v2 AS LONG)
DECLARE SUB glRects                    LIB "opengl32.dll" ALIAS "glRects"                  (BYVAL x1 AS INTEGER, BYVAL y1 AS INTEGER, BYVAL x2 AS INTEGER, BYVAL y2 AS INTEGER)
DECLARE SUB glRectsv                   LIB "opengl32.dll" ALIAS "glRectsv"                 (v1 AS LONG, v2 AS LONG)
DECLARE FUNCTION glRenderMode          LIB "opengl32.dll" ALIAS "glRenderMode"             (BYVAL mode AS DWORD) AS LONG
DECLARE SUB glRotated                  LIB "opengl32.dll" ALIAS "glRotated"                (BYVAL angle AS DOUBLE, BYVAL x AS DOUBLE, BYVAL y AS DOUBLE, BYVAL z AS DOUBLE)
DECLARE SUB glRotatef                  LIB "opengl32.dll" ALIAS "glRotatef"                (BYVAL angle AS SINGLE, BYVAL x AS SINGLE, BYVAL y AS SINGLE, BYVAL z AS SINGLE)
DECLARE SUB glScaled                   LIB "opengl32.dll" ALIAS "glScaled"                 (BYVAL x AS DOUBLE, BYVAL y AS DOUBLE, BYVAL z AS DOUBLE)
DECLARE SUB glScalef                   LIB "opengl32.dll" ALIAS "glScalef"                 (BYVAL x AS SINGLE, BYVAL y AS SINGLE, BYVAL z AS SINGLE)
DECLARE SUB glScissor                  LIB "opengl32.dll" ALIAS "glScissor"                (BYVAL x AS LONG, BYVAL y AS LONG, BYVAL nwidth AS LONG, BYVAL height AS LONG)
DECLARE SUB glSelectBuffer             LIB "opengl32.dll" ALIAS "glSelectBuffer"           (BYVAL lsize AS LONG, buffer AS DWORD)
DECLARE SUB glShadeModel               LIB "opengl32.dll" ALIAS "glShadeModel"             (BYVAL mode AS DWORD)
DECLARE SUB glStencilFunc              LIB "opengl32.dll" ALIAS "glStencilFunc"            (BYVAL func AS DWORD, BYVAL ref AS LONG, BYVAL mask AS DWORD)
DECLARE SUB glStencilMask              LIB "opengl32.dll" ALIAS "glStencilMask"            (BYVAL mask AS DWORD)
DECLARE SUB glStencilOp                LIB "opengl32.dll" ALIAS "glStencilOp"              (BYVAL fail AS DWORD, BYVAL zfail AS DWORD, BYVAL zpass AS DWORD)
DECLARE SUB glTexCoord1d               LIB "opengl32.dll" ALIAS "glTexCoord1d"             (BYVAL s AS DOUBLE)
DECLARE SUB glTexCoord1dv              LIB "opengl32.dll" ALIAS "glTexCoord1dv"            (v AS DOUBLE)
DECLARE SUB glTexCoord1f               LIB "opengl32.dll" ALIAS "glTexCoord1f"             (BYVAL s AS SINGLE)
DECLARE SUB glTexCoord1fv              LIB "opengl32.dll" ALIAS "glTexCoord1fv"            (v AS SINGLE)
DECLARE SUB glTexCoord1i               LIB "opengl32.dll" ALIAS "glTexCoord1i"             (BYVAL s AS LONG)
DECLARE SUB glTexCoord1iv              LIB "opengl32.dll" ALIAS "glTexCoord1iv"            (v AS LONG)
DECLARE SUB glTexCoord1s               LIB "opengl32.dll" ALIAS "glTexCoord1s"             (BYVAL s AS INTEGER)
DECLARE SUB glTexCoord1sv              LIB "opengl32.dll" ALIAS "glTexCoord1sv"            (v AS INTEGER)
DECLARE SUB glTexCoord2d               LIB "opengl32.dll" ALIAS "glTexCoord2d"             (BYVAL s AS DOUBLE, BYVAL t AS DOUBLE)
DECLARE SUB glTexCoord2dv              LIB "opengl32.dll" ALIAS "glTexCoord2dv"            (v AS LONG)
DECLARE SUB glTexCoord2f               LIB "opengl32.dll" ALIAS "glTexCoord2f"             (BYVAL s AS SINGLE, BYVAL t AS SINGLE)
DECLARE SUB glTexCoord2fv              LIB "opengl32.dll" ALIAS "glTexCoord2fv"            (v AS LONG)
DECLARE SUB glTexCoord2i               LIB "opengl32.dll" ALIAS "glTexCoord2i"             (BYVAL s AS LONG, BYVAL t AS LONG)
DECLARE SUB glTexCoord2iv              LIB "opengl32.dll" ALIAS "glTexCoord2iv"            (v AS LONG)
DECLARE SUB glTexCoord2s               LIB "opengl32.dll" ALIAS "glTexCoord2s"             (BYVAL s AS INTEGER, BYVAL t AS INTEGER)
DECLARE SUB glTexCoord2sv              LIB "opengl32.dll" ALIAS "glTexCoord2sv"            (v AS LONG)
DECLARE SUB glTexCoord3d               LIB "opengl32.dll" ALIAS "glTexCoord3d"             (BYVAL s AS DOUBLE, BYVAL t AS DOUBLE, BYVAL r AS DOUBLE)
DECLARE SUB glTexCoord3dv              LIB "opengl32.dll" ALIAS "glTexCoord3dv"            (v AS LONG)
DECLARE SUB glTexCoord3f               LIB "opengl32.dll" ALIAS "glTexCoord3f"             (BYVAL s AS SINGLE, BYVAL t AS SINGLE, BYVAL r AS SINGLE)
DECLARE SUB glTexCoord3fv              LIB "opengl32.dll" ALIAS "glTexCoord3fv"            (v AS LONG)
DECLARE SUB glTexCoord3i               LIB "opengl32.dll" ALIAS "glTexCoord3i"             (BYVAL s AS LONG, BYVAL t AS LONG, BYVAL r AS LONG)
DECLARE SUB glTexCoord3iv              LIB "opengl32.dll" ALIAS "glTexCoord3iv"            (v AS LONG)
DECLARE SUB glTexCoord3s               LIB "opengl32.dll" ALIAS "glTexCoord3s"             (BYVAL s AS INTEGER, BYVAL t AS INTEGER, BYVAL r AS INTEGER)
DECLARE SUB glTexCoord3sv              LIB "opengl32.dll" ALIAS "glTexCoord3sv"            (v AS LONG)
DECLARE SUB glTexCoord4d               LIB "opengl32.dll" ALIAS "glTexCoord4d"             (BYVAL s AS DOUBLE, BYVAL t AS DOUBLE, BYVAL r AS DOUBLE, BYVAL q AS DOUBLE)
DECLARE SUB glTexCoord4dv              LIB "opengl32.dll" ALIAS "glTexCoord4dv"            (v AS LONG)
DECLARE SUB glTexCoord4f               LIB "opengl32.dll" ALIAS "glTexCoord4f"             (BYVAL s AS SINGLE, BYVAL t AS SINGLE, BYVAL r AS SINGLE, BYVAL q AS SINGLE)
DECLARE SUB glTexCoord4fv              LIB "opengl32.dll" ALIAS "glTexCoord4fv"            (v AS LONG)
DECLARE SUB glTexCoord4i               LIB "opengl32.dll" ALIAS "glTexCoord4i"             (BYVAL s AS LONG, BYVAL t AS LONG, BYVAL r AS LONG, BYVAL q AS LONG)
DECLARE SUB glTexCoord4iv              LIB "opengl32.dll" ALIAS "glTexCoord4iv"            (v AS LONG)
DECLARE SUB glTexCoord4s               LIB "opengl32.dll" ALIAS "glTexCoord4s"             (BYVAL s AS INTEGER, BYVAL t AS INTEGER, BYVAL r AS INTEGER, BYVAL q AS INTEGER)
DECLARE SUB glTexCoord4sv              LIB "opengl32.dll" ALIAS "glTexCoord4sv"            (v AS LONG)
DECLARE SUB glTexCoordPointer          LIB "opengl32.dll" ALIAS "glTexCoordPointer"        (BYVAL lsize AS LONG, BYVAL ntype AS DWORD, BYVAL stride AS LONG, pointer AS LONG)
DECLARE SUB glTexEnvf                  LIB "opengl32.dll" ALIAS "glTexEnvf"                (BYVAL ntarget AS DWORD, BYVAL pname AS DWORD, BYVAL param AS SINGLE)
DECLARE SUB glTexEnvfv                 LIB "opengl32.dll" ALIAS "glTexEnvfv"               (BYVAL ntarget AS DWORD, BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glTexEnvi                  LIB "opengl32.dll" ALIAS "glTexEnvi"                (BYVAL ntarget AS DWORD, BYVAL pname AS DWORD, BYVAL param AS LONG)
DECLARE SUB glTexEnviv                 LIB "opengl32.dll" ALIAS "glTexEnviv"               (BYVAL ntarget AS DWORD, BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glTexGend                  LIB "opengl32.dll" ALIAS "glTexGend"                (BYVAL ncoord AS DWORD, BYVAL pname AS DWORD, BYVAL param AS DOUBLE)
DECLARE SUB glTexGendv                 LIB "opengl32.dll" ALIAS "glTexGendv"               (BYVAL ncoord AS DWORD, BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glTexGenf                  LIB "opengl32.dll" ALIAS "glTexGenf"                (BYVAL ncoord AS DWORD, BYVAL pname AS DWORD, BYVAL param AS SINGLE)
DECLARE SUB glTexGenfv                 LIB "opengl32.dll" ALIAS "glTexGenfv"               (BYVAL ncoord AS DWORD, BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glTexGeni                  LIB "opengl32.dll" ALIAS "glTexGeni"                (BYVAL ncoord AS DWORD, BYVAL pname AS DWORD, BYVAL param AS LONG)
DECLARE SUB glTexGeniv                 LIB "opengl32.dll" ALIAS "glTexGeniv"               (BYVAL ncoord AS DWORD, BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glTexImage1D               LIB "opengl32.dll" ALIAS "glTexImage1D"             (BYVAL ntarget AS DWORD, BYVAL level AS LONG, BYVAL internalformat AS LONG, BYVAL nwidth AS LONG, BYVAL border AS LONG, BYVAL format AS DWORD, BYVAL ntype AS DWORD, npixels AS LONG)
DECLARE SUB glTexImage2D               LIB "opengl32.dll" ALIAS "glTexImage2D"             (BYVAL ntarget AS DWORD, BYVAL level AS LONG, BYVAL internalformat AS LONG, BYVAL nwidth AS LONG, BYVAL height AS LONG, BYVAL border AS LONG, BYVAL format AS DWORD, BYVAL ntype AS DWORD, npixels AS LONG)
DECLARE SUB glTexParameterf            LIB "opengl32.dll" ALIAS "glTexParameterf"          (BYVAL ntarget AS DWORD, BYVAL pname AS DWORD, BYVAL param AS SINGLE)
DECLARE SUB glTexParameterfv           LIB "opengl32.dll" ALIAS "glTexParameterfv"         (BYVAL ntarget AS DWORD, BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glTexParameteri            LIB "opengl32.dll" ALIAS "glTexParameteri"          (BYVAL ntarget AS DWORD, BYVAL pname AS DWORD, BYVAL param AS LONG)
DECLARE SUB glTexParameteriv           LIB "opengl32.dll" ALIAS "glTexParameteriv"         (BYVAL ntarget AS DWORD, BYVAL pname AS DWORD, params AS LONG)
DECLARE SUB glTexSubImage1D            LIB "opengl32.dll" ALIAS "glTexSubImage1D"          (BYVAL ntarget AS DWORD, BYVAL level AS LONG, BYVAL xoffset AS LONG, BYVAL nwidth AS LONG, BYVAL format AS DWORD, BYVAL ntype AS DWORD, npixels AS LONG)
DECLARE SUB glTexSubImage2D            LIB "opengl32.dll" ALIAS "glTexSubImage2D"          (BYVAL ntarget AS DWORD, BYVAL level AS LONG, BYVAL xoffset AS LONG, BYVAL yoffset AS LONG, BYVAL nwidth AS LONG, BYVAL height AS LONG, BYVAL format AS DWORD, BYVAL ntype AS DWORD, npixels AS LONG)
DECLARE SUB glTranslated               LIB "opengl32.dll" ALIAS "glTranslated"             (BYVAL x AS DOUBLE, BYVAL y AS DOUBLE, BYVAL z AS DOUBLE)
DECLARE SUB glTranslatef               LIB "opengl32.dll" ALIAS "glTranslatef"             (BYVAL x AS SINGLE, BYVAL y AS SINGLE, BYVAL z AS SINGLE)
DECLARE SUB glVertex2d                 LIB "opengl32.dll" ALIAS "glVertex2d"               (BYVAL x AS DOUBLE, BYVAL y AS DOUBLE)
DECLARE SUB glVertex2dv                LIB "opengl32.dll" ALIAS "glVertex2dv"              (v AS LONG)
DECLARE SUB glVertex2f                 LIB "opengl32.dll" ALIAS "glVertex2f"               (BYVAL x AS SINGLE, BYVAL y AS SINGLE)
DECLARE SUB glVertex2fv                LIB "opengl32.dll" ALIAS "glVertex2fv"              (v AS LONG)
DECLARE SUB glVertex2i                 LIB "opengl32.dll" ALIAS "glVertex2i"               (BYVAL x AS LONG, BYVAL y AS LONG)
DECLARE SUB glVertex2iv                LIB "opengl32.dll" ALIAS "glVertex2iv"              (v AS LONG)
DECLARE SUB glVertex2s                 LIB "opengl32.dll" ALIAS "glVertex2s"               (BYVAL x AS INTEGER, BYVAL y AS INTEGER)
DECLARE SUB glVertex2sv                LIB "opengl32.dll" ALIAS "glVertex2sv"              (v AS LONG)
DECLARE SUB glVertex3d                 LIB "opengl32.dll" ALIAS "glVertex3d"               (BYVAL x AS DOUBLE, BYVAL y AS DOUBLE, BYVAL z AS DOUBLE)
DECLARE SUB glVertex3dv                LIB "opengl32.dll" ALIAS "glVertex3dv"              (v AS LONG)
DECLARE SUB glVertex3f                 LIB "opengl32.dll" ALIAS "glVertex3f"               (BYVAL x AS SINGLE, BYVAL y AS SINGLE, BYVAL z AS SINGLE)
DECLARE SUB glVertex3fv                LIB "opengl32.dll" ALIAS "glVertex3fv"              (v AS LONG)
DECLARE SUB glVertex3i                 LIB "opengl32.dll" ALIAS "glVertex3i"               (BYVAL x AS LONG, BYVAL y AS LONG, BYVAL z AS LONG)
DECLARE SUB glVertex3iv                LIB "opengl32.dll" ALIAS "glVertex3iv"              (v AS LONG)
DECLARE SUB glVertex3s                 LIB "opengl32.dll" ALIAS "glVertex3s"               (BYVAL x AS INTEGER, BYVAL y AS INTEGER, BYVAL z AS INTEGER)
DECLARE SUB glVertex3sv                LIB "opengl32.dll" ALIAS "glVertex3sv"              (v AS LONG)
DECLARE SUB glVertex4d                 LIB "opengl32.dll" ALIAS "glVertex4d"               (BYVAL x AS DOUBLE, BYVAL y AS DOUBLE, BYVAL z AS DOUBLE, BYVAL w AS DOUBLE)
DECLARE SUB glVertex4dv                LIB "opengl32.dll" ALIAS "glVertex4dv"              (v AS LONG)
DECLARE SUB glVertex4f                 LIB "opengl32.dll" ALIAS "glVertex4f"               (BYVAL x AS SINGLE, BYVAL y AS SINGLE, BYVAL z AS SINGLE, BYVAL w AS SINGLE)
DECLARE SUB glVertex4fv                LIB "opengl32.dll" ALIAS "glVertex4fv"              (v AS LONG)
DECLARE SUB glVertex4i                 LIB "opengl32.dll" ALIAS "glVertex4i"               (BYVAL x AS LONG, BYVAL y AS LONG, BYVAL z AS LONG, BYVAL w AS LONG)
DECLARE SUB glVertex4iv                LIB "opengl32.dll" ALIAS "glVertex4iv"              (v AS LONG)
DECLARE SUB glVertex4s                 LIB "opengl32.dll" ALIAS "glVertex4s"               (BYVAL x AS INTEGER, BYVAL y AS INTEGER, BYVAL z AS INTEGER, BYVAL w AS INTEGER)
DECLARE SUB glVertex4sv                LIB "opengl32.dll" ALIAS "glVertex4sv"              (v AS LONG)
DECLARE SUB glVertexPointer            LIB "opengl32.dll" ALIAS "glVertexPointer"          (BYVAL lsize AS LONG, BYVAL ntype AS DWORD, BYVAL stride AS LONG, pointer AS LONG)
DECLARE SUB glViewport                 LIB "opengl32.dll" ALIAS "glViewport"               (BYVAL x AS LONG, BYVAL y AS LONG, BYVAL nwidth AS LONG, BYVAL height AS LONG)
