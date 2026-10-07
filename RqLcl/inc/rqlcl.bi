' ---------------------------------------------------------------------------
'  rqlcl.bi - компоненты RapidQ (QFORM, QBUTTON, QLABEL, QEDIT) для
'  FreeBASIC поверх LCL. Прототип.
'
'  Компоненты живут в rqlcl32.dll (32 бит) или rqlcl64.dll (64 бит) -
'  DLL берётся по разрядности программы и ищется рядом с exe, затем по
'  обычным путям Windows. Загрузка - при создании первого объекта.
'
'  Как в RapidQ:
'      Dim Shared Form As QFORM
'      Dim Shared Button1 As QBUTTON
'      Sub Button1Click(ByRef Sender As QBUTTON)
'          Form.Caption = "Нажато"
'      End Sub
'      Button1.Parent = Form
'      Button1.Caption = "OK"
'      Button1.OnClick = @Button1Click    ' в FreeBASIC - с @
'      Form.ShowModal
'
'  Объекты объявляются глобально (Dim Shared) и живут до конца программы:
'  элементы уничтожает их форма, деструкторов у типов нет.
'  Строки - в кодировке Windows (CP1251), как в исходниках RapidQ.
'  Ошибка (нет свойства, нет DLL) - окно с текстом от DLL.
' ---------------------------------------------------------------------------

#pragma once

#ifdef __FB_64BIT__
    #define RQLCL_DLL "rqlcl64.dll"
#else
    #define RQLCL_DLL "rqlcl32.dll"
#endif

' Обработчик события на стороне программы: UserPtr - адрес объекта
' FreeBASIC (QBUTTON и т.д.), ObjPtr - объект в DLL
Type RqEventProc As Sub stdcall (ByVal UserPtr As Any Ptr, ByVal ObjPtr As Any Ptr)

Type RqInitFn As Function stdcall () As Long
Type RqDoneFn As Sub stdcall ()
Type RqCreateFn As Function stdcall (ByVal ClassName As ZString Ptr, _
    ByVal ParentObj As Any Ptr, ByVal UserPtr As Any Ptr) As Any Ptr
Type RqFreeFn As Sub stdcall (ByVal ObjPtr As Any Ptr)
Type RqSetIntFn As Function stdcall (ByVal ObjPtr As Any Ptr, _
    ByVal PropName As ZString Ptr, ByVal Value As Long) As Long
Type RqGetIntFn As Function stdcall (ByVal ObjPtr As Any Ptr, _
    ByVal PropName As ZString Ptr) As Long
Type RqSetStrFn As Function stdcall (ByVal ObjPtr As Any Ptr, _
    ByVal PropName As ZString Ptr, ByVal Value As ZString Ptr) As Long
Type RqGetStrFn As Function stdcall (ByVal ObjPtr As Any Ptr, _
    ByVal PropName As ZString Ptr, ByVal Buffer As ZString Ptr, _
    ByVal BufferLen As Long) As Long
Type RqSetObjFn As Function stdcall (ByVal ObjPtr As Any Ptr, _
    ByVal PropName As ZString Ptr, ByVal Value As Any Ptr) As Long
Type RqSetEventFn As Function stdcall (ByVal ObjPtr As Any Ptr, _
    ByVal EventName As ZString Ptr, ByVal Handler As RqEventProc) As Long
Type RqCallFn As Function stdcall (ByVal ObjPtr As Any Ptr, _
    ByVal MethodName As ZString Ptr) As Long
Type RqDoEventsFn As Sub stdcall ()
Type RqLastErrorFn As Function stdcall (ByVal Buffer As ZString Ptr, _
    ByVal BufferLen As Long) As Long

Dim Shared RqLclLib As Any Ptr
Dim Shared RqInit As RqInitFn
Dim Shared RqDone As RqDoneFn
Dim Shared RqCreate As RqCreateFn
Dim Shared RqFree As RqFreeFn
Dim Shared RqSetInt As RqSetIntFn
Dim Shared RqGetInt As RqGetIntFn
Dim Shared RqSetStr As RqSetStrFn
Dim Shared RqGetStr As RqGetStrFn
Dim Shared RqSetObj As RqSetObjFn
Dim Shared RqSetEvent As RqSetEventFn
Dim Shared RqCall As RqCallFn
Dim Shared RqDoEventsProc As RqDoEventsFn
Dim Shared RqLastError As RqLastErrorFn

Declare Function RqLclMessageBox Lib "user32" Alias "MessageBoxA" ( _
    ByVal WindowHandle As Any Ptr, ByVal Text As ZString Ptr, _
    ByVal Caption As ZString Ptr, ByVal Flags As ULong) As Long

' Сообщение об ошибке: окно (у GUI-программы консоли нет)
Sub RqLclShowError(ByRef What As String)
    Dim ErrText As String
    Dim ErrLen As Long
    If RqLastError <> 0 Then
        ErrLen = RqLastError(0, 0)
        ErrText = Space(ErrLen)
        If ErrLen > 0 Then RqLastError(StrPtr(ErrText), ErrLen + 1)
    End If
    RqLclMessageBox(0, What & Chr(13, 10) & ErrText, "RqLcl", &h10)
End Sub

' Загрузить DLL и найти функции; при ошибке - окно и конец программы
Sub RqLclEnsure()
    If RqLclLib <> 0 Then Exit Sub
    RqLclLib = DyLibLoad(RQLCL_DLL)
    If RqLclLib = 0 Then
        RqLclMessageBox(0, "Не найдена " & RQLCL_DLL & _
            " (положите её рядом с exe)", "RqLcl", &h10)
        End 1
    End If
    RqInit = Cast(RqInitFn, DyLibSymbol(RqLclLib, "RqInit"))
    RqDone = Cast(RqDoneFn, DyLibSymbol(RqLclLib, "RqDone"))
    RqCreate = Cast(RqCreateFn, DyLibSymbol(RqLclLib, "RqCreate"))
    RqFree = Cast(RqFreeFn, DyLibSymbol(RqLclLib, "RqFree"))
    RqSetInt = Cast(RqSetIntFn, DyLibSymbol(RqLclLib, "RqSetInt"))
    RqGetInt = Cast(RqGetIntFn, DyLibSymbol(RqLclLib, "RqGetInt"))
    RqSetStr = Cast(RqSetStrFn, DyLibSymbol(RqLclLib, "RqSetStr"))
    RqGetStr = Cast(RqGetStrFn, DyLibSymbol(RqLclLib, "RqGetStr"))
    RqSetObj = Cast(RqSetObjFn, DyLibSymbol(RqLclLib, "RqSetObj"))
    RqSetEvent = Cast(RqSetEventFn, DyLibSymbol(RqLclLib, "RqSetEvent"))
    RqCall = Cast(RqCallFn, DyLibSymbol(RqLclLib, "RqCall"))
    RqDoEventsProc = Cast(RqDoEventsFn, DyLibSymbol(RqLclLib, "RqDoEvents"))
    RqLastError = Cast(RqLastErrorFn, DyLibSymbol(RqLclLib, "RqLastError"))
    If (RqInit = 0) Or (RqCreate = 0) Or (RqSetInt = 0) Or (RqGetInt = 0) _
       Or (RqSetStr = 0) Or (RqGetStr = 0) Or (RqSetObj = 0) _
       Or (RqSetEvent = 0) Or (RqCall = 0) Or (RqDoEventsProc = 0) _
       Or (RqLastError = 0) Or (RqFree = 0) Or (RqDone = 0) Then
        RqLclMessageBox(0, "В " & RQLCL_DLL & " нет нужных функций " & _
            "(другая версия DLL?)", "RqLcl", &h10)
        End 1
    End If
    If RqInit() = 0 Then
        RqLclShowError("RqInit")
        End 1
    End If
End Sub

' Конец программы: окна и LCL освобождаются, пока программа жива, а не
' при выгрузке DLL в конце процесса
Private Sub RqLclShutdown() Destructor
    If (RqLclLib <> 0) AndAlso (RqDone <> 0) Then RqDone()
End Sub

' Объект класса RapidQ AClassName; UserPtr приходит в обработчики событий
Function RqLclNew(ByRef AClassName As String, ByVal UserPtr As Any Ptr) As Any Ptr
    Dim ObjPtr As Any Ptr
    RqLclEnsure()
    ObjPtr = RqCreate(StrPtr(AClassName), 0, UserPtr)
    If ObjPtr = 0 Then RqLclShowError("Создание " & AClassName)
    Return ObjPtr
End Function

Sub RqLclSetInt(ByVal ObjPtr As Any Ptr, ByRef PropName As String, ByVal Value As Long)
    If RqSetInt(ObjPtr, StrPtr(PropName), Value) = 0 Then RqLclShowError(PropName)
End Sub

Sub RqLclSetStr(ByVal ObjPtr As Any Ptr, ByRef PropName As String, ByRef Value As String)
    If RqSetStr(ObjPtr, StrPtr(PropName), StrPtr(Value)) = 0 Then RqLclShowError(PropName)
End Sub

Function RqLclGetStr(ByVal ObjPtr As Any Ptr, ByRef PropName As String) As String
    Dim TextLen As Long
    Dim TextValue As String
    TextLen = RqGetStr(ObjPtr, StrPtr(PropName), 0, 0)
    If TextLen <= 0 Then Return ""
    TextValue = Space(TextLen)
    RqGetStr(ObjPtr, StrPtr(PropName), StrPtr(TextValue), TextLen + 1)
    Return TextValue
End Function

Sub RqLclCall(ByVal ObjPtr As Any Ptr, ByRef MethodName As String)
    If RqCall(ObjPtr, StrPtr(MethodName)) = 0 Then RqLclShowError(MethodName)
End Sub

' DoEvents RapidQ
Sub DoEvents()
    RqLclEnsure()
    RqDoEventsProc()
End Sub

' ---------------------------------------------------------------------------
'  QCONTROL - общее у всех элементов: положение, размер, видимость, Parent
' ---------------------------------------------------------------------------

Type QCONTROL
    Handle As Any Ptr
    Declare Property Left() As Long
    Declare Property Left(ByVal Value As Long)
    Declare Property Top() As Long
    Declare Property Top(ByVal Value As Long)
    Declare Property Width() As Long
    Declare Property Width(ByVal Value As Long)
    Declare Property Height() As Long
    Declare Property Height(ByVal Value As Long)
    Declare Property Visible() As Long
    Declare Property Visible(ByVal Value As Long)
    Declare Property Enabled() As Long
    Declare Property Enabled(ByVal Value As Long)
    Declare Property Color() As Long
    Declare Property Color(ByVal Value As Long)
    Declare Property Hint() As String
    Declare Property Hint(ByRef Value As String)
    Declare Property ShowHint() As Long
    Declare Property ShowHint(ByVal Value As Long)
    Declare Property Parent(ByRef Value As QCONTROL)
    Declare Sub Show()
    Declare Sub Hide()
    Declare Sub Repaint()
    Declare Sub SetFocus()
End Type

Property QCONTROL.Left() As Long
    Return RqGetInt(Handle, "Left")
End Property
Property QCONTROL.Left(ByVal Value As Long)
    RqLclSetInt(Handle, "Left", Value)
End Property
Property QCONTROL.Top() As Long
    Return RqGetInt(Handle, "Top")
End Property
Property QCONTROL.Top(ByVal Value As Long)
    RqLclSetInt(Handle, "Top", Value)
End Property
Property QCONTROL.Width() As Long
    Return RqGetInt(Handle, "Width")
End Property
Property QCONTROL.Width(ByVal Value As Long)
    RqLclSetInt(Handle, "Width", Value)
End Property
Property QCONTROL.Height() As Long
    Return RqGetInt(Handle, "Height")
End Property
Property QCONTROL.Height(ByVal Value As Long)
    RqLclSetInt(Handle, "Height", Value)
End Property
Property QCONTROL.Visible() As Long
    Return RqGetInt(Handle, "Visible")
End Property
Property QCONTROL.Visible(ByVal Value As Long)
    RqLclSetInt(Handle, "Visible", Value)
End Property
Property QCONTROL.Enabled() As Long
    Return RqGetInt(Handle, "Enabled")
End Property
Property QCONTROL.Enabled(ByVal Value As Long)
    RqLclSetInt(Handle, "Enabled", Value)
End Property
Property QCONTROL.Color() As Long
    Return RqGetInt(Handle, "Color")
End Property
Property QCONTROL.Color(ByVal Value As Long)
    RqLclSetInt(Handle, "Color", Value)
End Property
Property QCONTROL.Hint() As String
    Return RqLclGetStr(Handle, "Hint")
End Property
Property QCONTROL.Hint(ByRef Value As String)
    RqLclSetStr(Handle, "Hint", Value)
End Property
Property QCONTROL.ShowHint() As Long
    Return RqGetInt(Handle, "ShowHint")
End Property
Property QCONTROL.ShowHint(ByVal Value As Long)
    RqLclSetInt(Handle, "ShowHint", Value)
End Property
Property QCONTROL.Parent(ByRef Value As QCONTROL)
    If RqSetObj(Handle, "Parent", Value.Handle) = 0 Then RqLclShowError("Parent")
End Property
Sub QCONTROL.Show()
    RqLclCall(Handle, "Show")
End Sub
Sub QCONTROL.Hide()
    RqLclCall(Handle, "Hide")
End Sub
Sub QCONTROL.Repaint()
    RqLclCall(Handle, "Repaint")
End Sub
Sub QCONTROL.SetFocus()
    RqLclCall(Handle, "SetFocus")
End Sub

' ---------------------------------------------------------------------------
'  QFORM
' ---------------------------------------------------------------------------

Type QFORM Extends QCONTROL
    OnShowProc As Sub(ByRef Sender As QFORM)
    OnShowProcPlain As Sub()
    OnCloseProc As Sub(ByRef Sender As QFORM)
    OnCloseProcPlain As Sub()
    Declare Constructor()
    Declare Property Caption() As String
    Declare Property Caption(ByRef Value As String)
    Declare Property OnShow(ByVal Handler As Sub(ByRef Sender As QFORM))
    Declare Property OnShow(ByVal Handler As Sub())
    Declare Property OnClose(ByVal Handler As Sub(ByRef Sender As QFORM))
    Declare Property OnClose(ByVal Handler As Sub())
    Declare Function ShowModal() As Long
    Declare Sub Close()
    Declare Sub Center()
End Type

Private Sub QFORM_ShowEvent stdcall (ByVal UserPtr As Any Ptr, ByVal ObjPtr As Any Ptr)
    Dim FormPtr As QFORM Ptr = UserPtr
    If FormPtr->OnShowProc <> 0 Then FormPtr->OnShowProc(*FormPtr)
    If FormPtr->OnShowProcPlain <> 0 Then FormPtr->OnShowProcPlain()
End Sub

Private Sub QFORM_CloseEvent stdcall (ByVal UserPtr As Any Ptr, ByVal ObjPtr As Any Ptr)
    Dim FormPtr As QFORM Ptr = UserPtr
    If FormPtr->OnCloseProc <> 0 Then FormPtr->OnCloseProc(*FormPtr)
    If FormPtr->OnCloseProcPlain <> 0 Then FormPtr->OnCloseProcPlain()
End Sub

Constructor QFORM()
    Handle = RqLclNew("QFORM", @This)
End Constructor
Property QFORM.Caption() As String
    Return RqLclGetStr(Handle, "Caption")
End Property
Property QFORM.Caption(ByRef Value As String)
    RqLclSetStr(Handle, "Caption", Value)
End Property
Property QFORM.OnShow(ByVal Handler As Sub(ByRef Sender As QFORM))
    OnShowProc = Handler
    OnShowProcPlain = 0
    If RqSetEvent(Handle, "OnShow", @QFORM_ShowEvent) = 0 Then RqLclShowError("OnShow")
End Property
' Обработчик без параметра Sender - как SUB ShowHandler в RapidQ
Property QFORM.OnShow(ByVal Handler As Sub())
    OnShowProcPlain = Handler
    OnShowProc = 0
    If RqSetEvent(Handle, "OnShow", @QFORM_ShowEvent) = 0 Then RqLclShowError("OnShow")
End Property
Property QFORM.OnClose(ByVal Handler As Sub(ByRef Sender As QFORM))
    OnCloseProc = Handler
    OnCloseProcPlain = 0
    If RqSetEvent(Handle, "OnClose", @QFORM_CloseEvent) = 0 Then RqLclShowError("OnClose")
End Property
' Обработчик без параметра Sender - как SUB CloseHandler в RapidQ
Property QFORM.OnClose(ByVal Handler As Sub())
    OnCloseProcPlain = Handler
    OnCloseProc = 0
    If RqSetEvent(Handle, "OnClose", @QFORM_CloseEvent) = 0 Then RqLclShowError("OnClose")
End Property
Function QFORM.ShowModal() As Long
    Return RqCall(Handle, "ShowModal")
End Function
Sub QFORM.Close()
    RqLclCall(Handle, "Close")
End Sub
Sub QFORM.Center()
    RqLclCall(Handle, "Center")
End Sub

' ---------------------------------------------------------------------------
'  QBUTTON
' ---------------------------------------------------------------------------

Type QBUTTON Extends QCONTROL
    OnClickProc As Sub(ByRef Sender As QBUTTON)
    OnClickProcPlain As Sub()
    Declare Constructor()
    Declare Property Caption() As String
    Declare Property Caption(ByRef Value As String)
    Declare Property OnClick(ByVal Handler As Sub(ByRef Sender As QBUTTON))
    Declare Property OnClick(ByVal Handler As Sub())
    Declare Sub Click()
End Type

Private Sub QBUTTON_ClickEvent stdcall (ByVal UserPtr As Any Ptr, ByVal ObjPtr As Any Ptr)
    Dim ButtonPtr As QBUTTON Ptr = UserPtr
    If ButtonPtr->OnClickProc <> 0 Then ButtonPtr->OnClickProc(*ButtonPtr)
    If ButtonPtr->OnClickProcPlain <> 0 Then ButtonPtr->OnClickProcPlain()
End Sub

Constructor QBUTTON()
    Handle = RqLclNew("QBUTTON", @This)
End Constructor
Property QBUTTON.Caption() As String
    Return RqLclGetStr(Handle, "Caption")
End Property
Property QBUTTON.Caption(ByRef Value As String)
    RqLclSetStr(Handle, "Caption", Value)
End Property
Property QBUTTON.OnClick(ByVal Handler As Sub(ByRef Sender As QBUTTON))
    OnClickProc = Handler
    OnClickProcPlain = 0
    If RqSetEvent(Handle, "OnClick", @QBUTTON_ClickEvent) = 0 Then RqLclShowError("OnClick")
End Property
' Обработчик без параметра Sender - как SUB ClickHandler в RapidQ
Property QBUTTON.OnClick(ByVal Handler As Sub())
    OnClickProcPlain = Handler
    OnClickProc = 0
    If RqSetEvent(Handle, "OnClick", @QBUTTON_ClickEvent) = 0 Then RqLclShowError("OnClick")
End Property
' Нажатие из программы, как щелчок мышью
Sub QBUTTON.Click()
    RqLclCall(Handle, "Click")
End Sub

' ---------------------------------------------------------------------------
'  QLABEL
' ---------------------------------------------------------------------------

Type QLABEL Extends QCONTROL
    Declare Constructor()
    Declare Property Caption() As String
    Declare Property Caption(ByRef Value As String)
End Type

Constructor QLABEL()
    Handle = RqLclNew("QLABEL", @This)
End Constructor
Property QLABEL.Caption() As String
    Return RqLclGetStr(Handle, "Caption")
End Property
Property QLABEL.Caption(ByRef Value As String)
    RqLclSetStr(Handle, "Caption", Value)
End Property

' ---------------------------------------------------------------------------
'  QEDIT
' ---------------------------------------------------------------------------

Type QEDIT Extends QCONTROL
    OnChangeProc As Sub(ByRef Sender As QEDIT)
    OnChangeProcPlain As Sub()
    Declare Constructor()
    Declare Property Text() As String
    Declare Property Text(ByRef Value As String)
    Declare Property OnChange(ByVal Handler As Sub(ByRef Sender As QEDIT))
    Declare Property OnChange(ByVal Handler As Sub())
End Type

Private Sub QEDIT_ChangeEvent stdcall (ByVal UserPtr As Any Ptr, ByVal ObjPtr As Any Ptr)
    Dim EditPtr As QEDIT Ptr = UserPtr
    If EditPtr->OnChangeProc <> 0 Then EditPtr->OnChangeProc(*EditPtr)
    If EditPtr->OnChangeProcPlain <> 0 Then EditPtr->OnChangeProcPlain()
End Sub

Constructor QEDIT()
    Handle = RqLclNew("QEDIT", @This)
End Constructor
Property QEDIT.Text() As String
    Return RqLclGetStr(Handle, "Text")
End Property
Property QEDIT.Text(ByRef Value As String)
    RqLclSetStr(Handle, "Text", Value)
End Property
Property QEDIT.OnChange(ByVal Handler As Sub(ByRef Sender As QEDIT))
    OnChangeProc = Handler
    OnChangeProcPlain = 0
    If RqSetEvent(Handle, "OnChange", @QEDIT_ChangeEvent) = 0 Then RqLclShowError("OnChange")
End Property
' Обработчик без параметра Sender - как SUB ChangeHandler в RapidQ
Property QEDIT.OnChange(ByVal Handler As Sub())
    OnChangeProcPlain = Handler
    OnChangeProc = 0
    If RqSetEvent(Handle, "OnChange", @QEDIT_ChangeEvent) = 0 Then RqLclShowError("OnChange")
End Property
