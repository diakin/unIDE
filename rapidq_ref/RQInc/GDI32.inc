'GDI32.DLL Functions
'FILE ADDED: Release Version 3
'FILE UPDATED: Release Version 3

'Adapted for RapidQ by Bryn Mosher (bdmnky@hotmail.com)
'WIN32API RapidQ $Includes
'Home page - http://home.pacbell.net/brynm/
'RapidQ - http://www.basicguru.com/abc/rapidq/

'You aren't going to try to write a video driver in RapidQ
'are you?  Didn't think so.
'THANKS TO:
'Thomas Simers ("Echecero") <echecero@crosswinds.net> for
'some of the Create...Rgn calls.


'CombineRgn()
    'Combines regions into the main region for the form.
    'Used with other Rgn functions to control the form's
    'display shape.
	'FROM MSDN:
	'hrgnDest [in] Handle to a new region with dimensions defined by combining two other regions. 
		'(This region must exist before CombineRgn is called.) 
	'hrgnSrc1 [in] Handle to the first of two regions to be combined. 
	'hrgnSrc2 [in] Handle to the second of two regions to be combined. 
	'fnCombineMode [in] Specifies a mode indicating how the two regions will be combined.
		'This parameter can be one of the following values.
		'Value -  Description 
		'RGN_AND - Creates the intersection of the two combined regions. 
		'RGN_COPY - Creates a copy of the region identified by hrgnSrc1. 
		'RGN_DIFF - Combines the parts of hrgnSrc1 that are not part of hrgnSrc2. 
		'RGN_OR - Creates the union of two combined regions. 
		'RGN_XOR - Creates the union of two combined regions except for any overlapping areas. 
		'Return Values
	'The return value specifies the type of the resulting region. It can be one of the following values. 
		'Value Meaning 
		'NULLREGION - The region is empty. 
		'SIMPLEREGION - The region is a single rectangle. 
		'COMPLEXREGION - The region is more than a single rectangle. 
		'ERROR - No region is created.
	'NOTE: All of these constants are in WINDOWSAPI.INC.

    Declare Function CombineRgn Lib "gdi32.dll" Alias_
     "CombineRgn" (hrgnDest As Long, hrgnSrc1 As Long, hrgnSrc2 As Long,_
     fnCombineMode As Integer) AS Long


'CreateEllipticRgn()
    'Creates an eliptic region for the form.
    'Used with other Rgn functions to control the form's
    'display shape.

    Declare Function CreateEllipticRgn Lib "gdi32.dll" Alias_
     "CreateEllipticRgn" (X1 As Long,Y1 As Long,X2 As Long,Y2 As Long) As Long


'CreateRectRgn()
    'Creates an rectangle region for the form.
    'Used with other Rgn functions to control the form's
    'display shape.

	Declare Function CreateRectRgn Lib "gdi32.dll" Alias_
	 "CreateRectRgn" (X1 As Long, Y1 As Long, X2 As Long, Y2 As Long) As Long


'CreateRoundRectRgn()
    'Creates an rectangle region for the form with rounded
    'corners.
    'Used with other Rgn functions to control the form's
    'display shape.

    Declare Function CreateRoundRectRgn Lib "gdi32.dll" Alias_
     "CreateRoundRectRgn" (nLeftRect as integer, nTopRect as integer,_
     nRightRect as integer, nBottomRect as integer, nWidthEllipse as integer,_
     nHeightEllipse as integer) AS LONG


