' ObjectToolbox API for Rapid-Q! Version 1.1.
'
' About
' ---------------
' ObjectToolbox is a library that provides useful functions and subs for manipulating objects and
' retrieving information about them.
' 
' Release Notes
' --------------
' o Code is provided as-is.
' o ObjectToolbox is designed for Windows, not Linux/Unix.
'
'
' This package includes:
' ===============================================================================
' - TypeOf, a function which returns a string representation of the type
' of object the given handle identifies.

'
' Usage Notes:
' --------------
' You can't pass objects by name (by reference) to TypeOf, only their handles. I hope to provide a
' workaround for this, though.
' 
' GDI object handles may be implemented for the next version of TypeOf().
'
' Updates:
' --------------
' TypeOf now recognizes QMenuItems


$IfNDef __OBJECT_TOOLBOX_USED
 $Define __OBJECT_TOOLBOX_USED

REM [This section contains the TypeOf function and all other code related to it]
REM ------------------------------------------------------------------------------------------------------
' Not a local function (See below). The underscore denotes this as an API call.
Declare Function ObjectToolbox_GetClassName lib "user32" alias "GetClassNameA" _
(ByVal hWnd as long, ByRef lpClassName as string, ByVal nMaxCount as long) as long

' Returns the win32 class name for an object, as opposed to Rapid-Q's predetermined component name
Function ObjectToolbox.TypeOfA(Object as long) as string
'ShowMessage "Called ObjectToolbox.TypeOfA"
Dim StrBuf as string, StrPtr as string, StrLen as long
StrBuf=Space$(256): StrLen=Len(StrBuf)
StrLen=ObjectToolbox_GetClassName(Object, StrBuf, StrLen)
StrPtr=Left$(StrBuf, StrLen)
 Result=StrPtr
End Function

' Returns Rapid-Q's definition of the class name Object identifies
Function ObjectToolbox.TypeOf(Object as long) as string
'ShowMessage "Called ObjectToolbox.TypeOf"
Dim StrBuf as string, StrPtr as string, StrLen as long
StrBuf=Space$(256): StrLen=Len(StrBuf)
StrLen=ObjectToolbox_GetClassName(Object, StrBuf, StrLen)
StrPtr=Left$(StrBuf, StrLen)
 
 If Left$(StrPtr, 1)="T" Then
  ' Let's convert the first character from 'T' to 'Q'
  StrPtr=Replace$(StrPtr, "Q", 1)

 ' Now get rid of the 's' at the end (we don't need it)
   If Right$(StrPtr, 1)="s" Then
    StrPtr=Left$(StrPtr, Len(StrPtr)-1)
   End If
 End If
 
 ' Now let's analyze the class name and convert, if necessary
 If StrPtr="QBitBtn" Then
  StrPtr="QButton"
 ElseIf StrPtr="QApplication" Then
  StrPtr="Application"
 ElseIf StrPtr="#32768" Then
  StrPtr="QMenuItem"
 End If
 
 Result=StrPtr
End Function

' A new way of doing things :)
Functioni TypeOf(...) as string
Dim ptr1 as integer, lpfn1 as long, lpfn2 as long, bGetNative as byte
ptr1=ParamVal(1): bGetNative=ParamVal(2)

 Bind lpfn1 to ObjectToolbox.TypeOf
 Bind lpfn2 to ObjectToolbox.TypeOfA

 If ParamValCount=1 Then
  CallFunc lpfn1, ptr1
 ElseIf ParamValCount=2 and bGetNative=1 Then
  CallFunc lpfn2, ptr1
 End If

' Frees the pointers, I think 
 lpfn1=0: lpfn2=0
End Functioni

' Overview
' ---------
' TypeOf() only works on GUI components, not virtual ones (interfaces) like GDI objects
' such as QBitMap, QCanvas, QFont, and Printer.
'
' QCoolBtn is a canvas-type object, so the above rules apply to it as well.
' QDirTree dosen't have a GUI handle; oddly, it's a GDI object :p
' If you test a QFont, TypeOf may return a current class running in Windows, or nothing at all.
REM ----------------------------------------------------------------------------------------------------
REM [End TypeOf() code section]

$EndIf  