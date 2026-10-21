
'************************************************************************************************
'*   Automatically generate a manifest file for XP style buttons common controls             
'*   based on code QXpTheme by Nicolas Tillet http://www.membres.lycos.fr/ntillet86
' *   code addition by robin_q_master 
' *   added Paul ludgates xpGroupBox component
'*  Modified for RQ2 by JohnK,  4/2006
'************************************************************************************************
'
'usage  
' $XP_MANIFEST
' XPButton(MyQbutton.Handle, <option>)
'

$IFNDEF __WIN32API   'for windows 32 API calls/constants
$IFNDEF __RQINC2   ' & rapidQ2
$DEFINE GWL_STYLE   &HFFFFFFF0      '-16
DECLARE FUNCTION SetWindowLong LIB "user32" ALIAS "SetWindowLongA" (hWnd AS LONG,nIndex AS LONG, dwNewLong AS LONG) AS LONG
DECLARE FUNCTION GetWindowLong LIB "USER32" ALIAS "GetWindowLongA" (hwnd AS LONG, type AS LONG) AS LONG
TYPE OSVERSIONINFO  
dwOSVersionInfoSize  As Long  
dwMajorVersion    As Long  
dwMinorVersion    As Long  
dwBuildNumber    As Long  
dwPlatformId    As Long  
szCSDVersion    As String * 128  
END TYPE  
Declare Function GetVersionEx Lib "kernel32.dll" Alias "GetVersionExA" (lpVersionInformation As OSVERSIONINFO) As Long  
$ENDIF
$ENDIF

$DEFINE fbmNormal  0
$DEFINE fbmDefault  1
$DEFINE fbmFixTo3CheckBox  6
$DEFINE fbmFixToGroupBox  7
$DEFINE fbmLeftAlign  &H100
$DEFINE fbmRightAlign  &H200
$DEFINE fbmTopAlign  &H400
$DEFINE fbmBottomAlign  &H800
$DEFINE fbmShowOnClick &HA

SUBI XPButton(...)      'btnHandle AS LONG)
DEFINT btnHandle = ParamVal(1)
DEFINT opt = fbmNormal
IF ParamValCount > 1 THEN opt = ParamVal(2)
SetWindowLong(btnHandle, GWL_STYLE, (GetWindowLong(btnHandle, GWL_STYLE) XOR 11) + opt)
END SUBI




SUB $XP_MANIFEST
DIM rtn     AS LONG
DIM OSV  AS OSVERSIONINFO
OSV.dwOSVersionInfoSize = SIZEOF(OSV)  
GetVersionEx(OSV)
IF (OSV.dwMajorVersion => 5 AND OSV.dwMinorVersion > 0 ) THEN
	IF FILEEXISTS(Command$(0)+".manifest")=0 THEN     'no manifest file, so generate it
		CREATE gRQ2_manifest AS QSTRINGLIST  
			additems "<?xml version="+CHR$(34)+"1.0"+CHR$(34)+" encoding="+CHR$(34)+"UTF-8"+CHR$(34)+" standalone="+CHR$(34)+"yes"+CHR$(34)+"?>"
			additems "<assembly xmlns="+CHR$(34)+"urn:schemas-microsoft-com:asm.v1"+CHR$(34)+" manifestVersion="+CHR$(34)+"1.0"+CHR$(34)+">"
			additems "<assemblyIdentity"
			additems "version = "+CHR$(34)+"1.0.0.0"+CHR$(34)+""
			additems "processorArchitecture = "+CHR$(34)+"X86"+CHR$(34)+""
			additems "name = "+CHR$(34)+"[].[].[]"+CHR$(34)+""
			additems "type="+CHR$(34)+"win32"+CHR$(34)+""
			additems "/>"
			additems "<description></description>"
			additems "<dependency>"
			additems "<dependentAssembly>"
			additems "<assemblyIdentity"
			additems "type="+CHR$(34)+"win32"+CHR$(34)+""
			additems "name = "+CHR$(34)+"Microsoft.Windows.Common-Controls"+CHR$(34)+""
			additems "version = "+CHR$(34)+"6.0.0.0"+CHR$(34)+""
			additems "processorArchitecture = "+CHR$(34)+"X86"+CHR$(34)+""
			additems "publicKeyToken = "+CHR$(34)+"6595b64144ccf1df"+CHR$(34)+""
			additems "language = "+CHR$(34)+"*"+CHR$(34)+"" 
			additems "/>"                   
			additems "</dependentAssembly>"                   
			additems "</dependency>"                   
			additems "</assembly>"                   
		END CREATE 
		gRQ2_manifest.SaveToFile(Command$(0)+".manifest")
		gRQ2_manifest.Clear
	END IF 
END IF 
END SUB



TYPE XpGroupBox EXTENDS QPANEL
Public:
Caption AS STRING
BorderColor  AS LONG
CaptionColor AS LONG
LunaDetect   AS LONG
Private:
Canvas AS QCANVAS
EVENT Canvas.OnPaint
DEFLNG BtnFace = GetSysColor(15)
DIM BC AS LONG
IF XpGroupBox.LunaDetect THEN  ' adjust border color to suit btnface
	IF BtnFace = &HE3DFE0 THEN   ' silver theme
		BC = &H5C7777
	ELSE                         ' blue or olive theme
		BC = &HBFD0D0
	END IF
ELSE
	BC = XpGroupBox.BorderColor
END IF
DEFLNG Yadj = XpGroupBox.Canvas.TextHeight("Xp") / 2
XpGroupBox.Canvas.Line(2,Yadj,XpGroupBox.Width-3,Yadj,BC)
XpGroupBox.Canvas.Line(1,Yadj+1,2,Yadj+1,BC)
XpGroupBox.Canvas.Line(XpGroupBox.Width-3,Yadj+1,XpGroupBox.Width-2,Yadj+1,BC)
XpGroupBox.Canvas.Line(0,Yadj+2,1,Yadj+2,BC)
XpGroupBox.Canvas.Line(XpGroupBox.Width-2,Yadj+2,XpGroupBox.Width-1,Yadj+2,BC)
XpGroupBox.Canvas.Line(0,XpGroupBox.Height-3,1,XpGroupBox.Height-3,BC)
XpGroupBox.Canvas.Line(XpGroupBox.Width-2,XpGroupBox.Height-3,XpGroupBox.Width-1,XpGroupBox.Height-3,BC)
XpGroupBox.Canvas.Line(1,XpGroupBox.Height-2,2,XpGroupBox.Height-2,BC)
XpGroupBox.Canvas.Line(XpGroupBox.Width-3,XpGroupBox.Height-2,XpGroupBox.Width-2,XpGroupBox.Height-2,BC)
XpGroupBox.Canvas.Line(2,XpGroupBox.Height-1,XpGroupBox.Width-3,XpGroupBox.Height-1,BC)
XpGroupBox.Canvas.Line(0,Yadj+3,0,XpGroupBox.Height-4,BC)
XpGroupBox.Canvas.Line(XpGroupBox.Width-1,Yadj+3,XpGroupBox.Width-1,XpGroupBox.Height-4,BC)
XpGroupBox.Canvas.TextOut(7,0,XpGroupBox.Caption,XpGroupBox.CaptionColor,BtnFace)
END EVENT
CONSTRUCTOR
BevelWidth    = 0
BorderColor   = &HBFD0D0
CaptionColor  = &HD54600
LunaDetect    = 1
Canvas.Parent = XpGroupBox
Canvas.Align  = 5   'alClient
END CONSTRUCTOR
END TYPE


