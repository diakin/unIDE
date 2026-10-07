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
'  Поле RqObj - объект в DLL; Handle - окно Windows (как в RapidQ).
'  Строки - в кодировке Windows (CP1251), как в исходниках RapidQ.
'  Ошибка (нет свойства, нет DLL) - окно с текстом от DLL.
' ---------------------------------------------------------------------------

#pragma once

#include once "rqstream.bi"
#include once "rqstrlist.bi"
#include once "rqreg.bi"

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
Type RqCallIntFn As Function stdcall (ByVal ObjPtr As Any Ptr, _
    ByVal MethodName As ZString Ptr, ByVal Value As Long) As Long
Type RqGetObjFn As Function stdcall (ByVal ObjPtr As Any Ptr, _
    ByVal PropName As ZString Ptr) As Any Ptr
Type RqGetHandleFn As Function stdcall (ByVal ObjPtr As Any Ptr) As Integer
Type RqGetItemStrFn As Function stdcall (ByVal ObjPtr As Any Ptr, _
    ByVal PropName As ZString Ptr, ByVal ItemIndex As Long, _
    ByVal Buffer As ZString Ptr, ByVal BufferLen As Long) As Long
Type RqSetItemStrFn As Function stdcall (ByVal ObjPtr As Any Ptr, _
    ByVal PropName As ZString Ptr, ByVal ItemIndex As Long, _
    ByVal Value As ZString Ptr) As Long
Type RqCallStrFn As Function stdcall (ByVal ObjPtr As Any Ptr, _
    ByVal MethodName As ZString Ptr, ByVal Value As ZString Ptr) As Long
Type RqGetCellFn As Function stdcall (ByVal ObjPtr As Any Ptr, _
    ByVal ColIdx As Long, ByVal RowIdx As Long, _
    ByVal Buffer As ZString Ptr, ByVal BufferLen As Long) As Long
Type RqSetCellFn As Function stdcall (ByVal ObjPtr As Any Ptr, _
    ByVal ColIdx As Long, ByVal RowIdx As Long, ByVal Value As ZString Ptr) As Long
Type RqGetItemIntFn As Function stdcall (ByVal ObjPtr As Any Ptr, _
    ByVal PropName As ZString Ptr, ByVal ItemIndex As Long) As Long
Type RqSetItemIntFn As Function stdcall (ByVal ObjPtr As Any Ptr, _
    ByVal PropName As ZString Ptr, ByVal ItemIndex As Long, ByVal Value As Long) As Long
Type RqCallExFn As Function stdcall (ByVal ObjPtr As Any Ptr, _
    ByVal MethodName As ZString Ptr, ByVal StrArg As ZString Ptr, _
    ByVal IntArg1 As Long, ByVal IntArg2 As Long, ByVal IntArg3 As Long, _
    ByVal Buffer As ZString Ptr, ByVal BufferLen As Long) As Long
Type RqEventArgs
    IntArgs(0 To 7) As Long
    StrArg As ZString Ptr
End Type
Type RqEventProcEx As Sub stdcall (ByVal UserPtr As Any Ptr, ByVal ObjPtr As Any Ptr, _
    ByVal EventId As Long, ByVal Args As RqEventArgs Ptr)
Type RqSetEventExFn As Function stdcall (ByVal ObjPtr As Any Ptr, _
    ByVal EventName As ZString Ptr, ByVal EventId As Long, _
    ByVal Handler As RqEventProcEx) As Long
Type RqCallIntsFn As Function stdcall (ByVal ObjPtr As Any Ptr, _
    ByVal MethodName As ZString Ptr, ByVal StrArg As ZString Ptr, _
    ByVal IntList As Long Ptr, ByVal IntCount As Long) As Long
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
Dim Shared RqCallInt As RqCallIntFn
Dim Shared RqGetObj As RqGetObjFn
Dim Shared RqGetHandle As RqGetHandleFn
Dim Shared RqGetItemStr As RqGetItemStrFn
Dim Shared RqSetItemStr As RqSetItemStrFn
Dim Shared RqCallStr As RqCallStrFn
Dim Shared RqGetCell As RqGetCellFn
Dim Shared RqSetCell As RqSetCellFn
Dim Shared RqGetItemInt As RqGetItemIntFn
Dim Shared RqSetItemInt As RqSetItemIntFn
Dim Shared RqCallEx As RqCallExFn
Dim Shared RqSetEventEx As RqSetEventExFn
Dim Shared RqCallInts As RqCallIntsFn
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
    RqCallInt = Cast(RqCallIntFn, DyLibSymbol(RqLclLib, "RqCallInt"))
    RqGetObj = Cast(RqGetObjFn, DyLibSymbol(RqLclLib, "RqGetObj"))
    RqGetHandle = Cast(RqGetHandleFn, DyLibSymbol(RqLclLib, "RqGetHandle"))
    RqGetItemStr = Cast(RqGetItemStrFn, DyLibSymbol(RqLclLib, "RqGetItemStr"))
    RqSetItemStr = Cast(RqSetItemStrFn, DyLibSymbol(RqLclLib, "RqSetItemStr"))
    RqCallStr = Cast(RqCallStrFn, DyLibSymbol(RqLclLib, "RqCallStr"))
    RqGetCell = Cast(RqGetCellFn, DyLibSymbol(RqLclLib, "RqGetCell"))
    RqSetCell = Cast(RqSetCellFn, DyLibSymbol(RqLclLib, "RqSetCell"))
    RqGetItemInt = Cast(RqGetItemIntFn, DyLibSymbol(RqLclLib, "RqGetItemInt"))
    RqSetItemInt = Cast(RqSetItemIntFn, DyLibSymbol(RqLclLib, "RqSetItemInt"))
    RqCallEx = Cast(RqCallExFn, DyLibSymbol(RqLclLib, "RqCallEx"))
    RqSetEventEx = Cast(RqSetEventExFn, DyLibSymbol(RqLclLib, "RqSetEventEx"))
    RqCallInts = Cast(RqCallIntsFn, DyLibSymbol(RqLclLib, "RqCallInts"))
    RqDoEventsProc = Cast(RqDoEventsFn, DyLibSymbol(RqLclLib, "RqDoEvents"))
    RqLastError = Cast(RqLastErrorFn, DyLibSymbol(RqLclLib, "RqLastError"))
    If (RqInit = 0) Or (RqCreate = 0) Or (RqSetInt = 0) Or (RqGetInt = 0) _
       Or (RqSetStr = 0) Or (RqGetStr = 0) Or (RqSetObj = 0) _
       Or (RqSetEvent = 0) Or (RqCall = 0) Or (RqDoEventsProc = 0) _
       Or (RqLastError = 0) Or (RqFree = 0) Or (RqDone = 0) _
       Or (RqCallInt = 0) Or (RqGetObj = 0) Or (RqGetHandle = 0) _
       Or (RqGetItemStr = 0) Or (RqSetItemStr = 0) Or (RqCallStr = 0) _
       Or (RqGetCell = 0) Or (RqSetCell = 0) Or (RqGetItemInt = 0) _
       Or (RqSetItemInt = 0) Or (RqCallEx = 0) Or (RqSetEventEx = 0) _
       Or (RqCallInts = 0) Then
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

' Текст последней ошибки DLL
Function RqLclLastError() As String
    Dim ErrText As String
    Dim ErrLen As Long
    If RqLastError = 0 Then Return ""
    ErrLen = RqLastError(0, 0)
    If ErrLen <= 0 Then Return ""
    ErrText = Space(ErrLen)
    RqLastError(StrPtr(ErrText), ErrLen + 1)
    Return ErrText
End Function

' Ошибка, которая в цикле повторилась бы много раз (ячейка вне таблицы):
' не окно, а как у QSTRINGLIST - Smart: предупреждение в лог, Compat:
' сообщение и конец программы
Sub RqLclClassError(ByRef What As String)
    RqRtClassError(What & ": " & RqLclLastError())
End Sub

Sub RqLclCallStr(ByVal ObjPtr As Any Ptr, ByRef MethodName As String, ByRef Value As String)
    If RqCallStr(ObjPtr, StrPtr(MethodName), StrPtr(Value)) = 0 Then RqLclShowError(MethodName)
End Sub

' Строка списка по номеру (с 0); ошибка - окно и ""
Function RqLclGetItem(ByVal ObjPtr As Any Ptr, ByRef PropName As String, ByVal ItemIndex As Long) As String
    Dim TextLen As Long
    Dim TextValue As String
    TextLen = RqGetItemStr(ObjPtr, StrPtr(PropName), ItemIndex, 0, 0)
    If TextLen < 0 Then
        RqLclShowError(PropName & "(" & ItemIndex & ")")
        Return ""
    End If
    If TextLen = 0 Then Return ""
    TextValue = Space(TextLen)
    RqGetItemStr(ObjPtr, StrPtr(PropName), ItemIndex, StrPtr(TextValue), TextLen + 1)
    Return TextValue
End Function

' DoEvents RapidQ
Sub DoEvents()
    RqLclEnsure()
    RqDoEventsProc()
End Sub

' ---------------------------------------------------------------------------
'  QFONT - шрифт: имя, размер, цвет, стили. Присваивается элементу:
'      Label.Font = Font
'  Элемент копирует значения шрифта, сам QFONT остаётся отдельным.
'  Control.Font - QFONT поверх шрифта элемента: Label.Font.Size = 12
'  сразу меняет элемент.
'  Font у элемента - функция ByRef, не свойство: у свойства FreeBASIC с
'  парой get/set нельзя писать Label.Font.Size = 12 (проверено, fbc 1.10.1).
' ---------------------------------------------------------------------------

Type QFONT
    RqObj As Any Ptr
    Declare Constructor()
    Declare Constructor(ByVal Existing As Any Ptr)
    Declare Operator Let(ByRef Value As QFONT)
    Declare Property Name() As String
    Declare Property Name(ByRef Value As String)
    Declare Property Size() As Long
    Declare Property Size(ByVal Value As Long)
    Declare Property Color() As Long
    Declare Property Color(ByVal Value As Long)
    Declare Property Charset() As Long
    Declare Property Charset(ByVal Value As Long)
    Declare Property Pitch() As Long
    Declare Property Pitch(ByVal Value As Long)
    Declare Property Handle() As Integer
    Declare Property Handle(ByVal Value As Integer)
    Declare Property FontCount() As Long
    Declare Property FontName(ByVal ItemIndex As Long) As String
    Declare Sub AddStyles(ByVal Style1 As Long, ByVal Style2 As Long = -1, _
        ByVal Style3 As Long = -1, ByVal Style4 As Long = -1)
    Declare Sub DelStyles(ByVal Style1 As Long, ByVal Style2 As Long = -1, _
        ByVal Style3 As Long = -1, ByVal Style4 As Long = -1)
End Type

Constructor QFONT()
    RqObj = RqLclNew("QFONT", @This)
End Constructor
' Обёртка над готовым шрифтом из DLL (Font элемента)
Constructor QFONT(ByVal Existing As Any Ptr)
    RqObj = Existing
End Constructor
' Font2 = Font1, Label.Font = Font1: значения копируются в шрифт слева
Operator QFONT.Let(ByRef Value As QFONT)
    If (@Value = @This) OrElse (Value.RqObj = RqObj) Then Exit Operator
    If RqObj = 0 Then
        RqObj = Value.RqObj
        Exit Operator
    End If
    If RqSetObj(RqObj, "Assign", Value.RqObj) = 0 Then RqLclShowError("QFONT =")
End Operator
Property QFONT.Name() As String
    Return RqLclGetStr(RqObj, "Name")
End Property
Property QFONT.Name(ByRef Value As String)
    RqLclSetStr(RqObj, "Name", Value)
End Property
Property QFONT.Size() As Long
    Return RqGetInt(RqObj, "Size")
End Property
Property QFONT.Size(ByVal Value As Long)
    RqLclSetInt(RqObj, "Size", Value)
End Property
Property QFONT.Color() As Long
    Return RqGetInt(RqObj, "Color")
End Property
Property QFONT.Color(ByVal Value As Long)
    RqLclSetInt(RqObj, "Color", Value)
End Property
Property QFONT.Charset() As Long
    Return RqGetInt(RqObj, "Charset")
End Property
Property QFONT.Charset(ByVal Value As Long)
    RqLclSetInt(RqObj, "Charset", Value)
End Property
Property QFONT.Pitch() As Long
    Return RqGetInt(RqObj, "Pitch")
End Property
Property QFONT.Pitch(ByVal Value As Long)
    RqLclSetInt(RqObj, "Pitch", Value)
End Property
' HFONT Windows
Property QFONT.Handle() As Integer
    Return RqGetHandle(RqObj)
End Property
Property QFONT.Handle(ByVal Value As Integer)
    If RqCallInt(RqObj, "SetHandle", Value) = 0 Then RqLclShowError("Handle")
End Property
' Число шрифтов в системе
Property QFONT.FontCount() As Long
    RqLclEnsure()
    Return RqCallInt(RqObj, "FontCount", 0)
End Property
' Имя шрифта системы по номеру, с 0
Property QFONT.FontName(ByVal ItemIndex As Long) As String
    Return RqLclGetItem(RqObj, "FontName", ItemIndex)
End Property
' Стили: fsBold 0, fsItalic 1, fsUnderline 2, fsStrikeOut 3. В RapidQ
' число параметров не ограничено, здесь - до четырёх (стилей всего четыре)
Sub QFONT.AddStyles(ByVal Style1 As Long, ByVal Style2 As Long = -1, _
        ByVal Style3 As Long = -1, ByVal Style4 As Long = -1)
    Dim StyleList(1 To 4) As Long = {Style1, Style2, Style3, Style4}
    For StyleIdx As Long = 1 To 4
        If StyleList(StyleIdx) >= 0 Then
            If RqCallInt(RqObj, "AddStyle", StyleList(StyleIdx)) = 0 Then RqLclShowError("AddStyles")
        End If
    Next
End Sub
Sub QFONT.DelStyles(ByVal Style1 As Long, ByVal Style2 As Long = -1, _
        ByVal Style3 As Long = -1, ByVal Style4 As Long = -1)
    Dim StyleList(1 To 4) As Long = {Style1, Style2, Style3, Style4}
    For StyleIdx As Long = 1 To 4
        If StyleList(StyleIdx) >= 0 Then
            If RqCallInt(RqObj, "DelStyle", StyleList(StyleIdx)) = 0 Then RqLclShowError("DelStyles")
        End If
    Next
End Sub

' ---------------------------------------------------------------------------
'  QRECT - прямоугольник (OnDrawCell и рисование)
' ---------------------------------------------------------------------------

Type QRECT
    Left As Long
    Top As Long
    Right As Long
    Bottom As Long
End Type

' ---------------------------------------------------------------------------
'  QCONTROL - общее у всех элементов: положение, размер, видимость, Parent
' ---------------------------------------------------------------------------

Type QCONTROL
    RqObj As Any Ptr
    FontWrap As QFONT = QFONT(0)
    ' События с параметрами: обработчик и его вид по номеру события
    ' (RqEv...): 0 - Sub(), 1 - с параметрами, 2 - с параметрами и Sender,
    ' 3 - только Sender
    EventProcs(0 To 8) As Any Ptr
    EventKinds(0 To 8) As Long
    Declare Sub SetEventEx(ByVal EventId As Long, ByRef EventName As String, _
        ByVal Handler As Any Ptr, ByVal HandlerKind As Long)
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
    Declare Function Font() ByRef As QFONT
    Declare Property Handle() As Integer
    Declare Sub Show()
    Declare Sub Hide()
    Declare Sub Repaint()
    Declare Sub SetFocus()
End Type

Property QCONTROL.Left() As Long
    Return RqGetInt(RqObj, "Left")
End Property
Property QCONTROL.Left(ByVal Value As Long)
    RqLclSetInt(RqObj, "Left", Value)
End Property
Property QCONTROL.Top() As Long
    Return RqGetInt(RqObj, "Top")
End Property
Property QCONTROL.Top(ByVal Value As Long)
    RqLclSetInt(RqObj, "Top", Value)
End Property
Property QCONTROL.Width() As Long
    Return RqGetInt(RqObj, "Width")
End Property
Property QCONTROL.Width(ByVal Value As Long)
    RqLclSetInt(RqObj, "Width", Value)
End Property
Property QCONTROL.Height() As Long
    Return RqGetInt(RqObj, "Height")
End Property
Property QCONTROL.Height(ByVal Value As Long)
    RqLclSetInt(RqObj, "Height", Value)
End Property
Property QCONTROL.Visible() As Long
    Return RqGetInt(RqObj, "Visible")
End Property
Property QCONTROL.Visible(ByVal Value As Long)
    RqLclSetInt(RqObj, "Visible", Value)
End Property
Property QCONTROL.Enabled() As Long
    Return RqGetInt(RqObj, "Enabled")
End Property
Property QCONTROL.Enabled(ByVal Value As Long)
    RqLclSetInt(RqObj, "Enabled", Value)
End Property
Property QCONTROL.Color() As Long
    Return RqGetInt(RqObj, "Color")
End Property
Property QCONTROL.Color(ByVal Value As Long)
    RqLclSetInt(RqObj, "Color", Value)
End Property
Property QCONTROL.Hint() As String
    Return RqLclGetStr(RqObj, "Hint")
End Property
Property QCONTROL.Hint(ByRef Value As String)
    RqLclSetStr(RqObj, "Hint", Value)
End Property
Property QCONTROL.ShowHint() As Long
    Return RqGetInt(RqObj, "ShowHint")
End Property
Property QCONTROL.ShowHint(ByVal Value As Long)
    RqLclSetInt(RqObj, "ShowHint", Value)
End Property
Property QCONTROL.Parent(ByRef Value As QCONTROL)
    If RqSetObj(RqObj, "Parent", Value.RqObj) = 0 Then RqLclShowError("Parent")
End Property
' Шрифт элемента; Label.Font = Font копирует значения (QFONT.Let)
Function QCONTROL.Font() ByRef As QFONT
    FontWrap.RqObj = RqGetObj(RqObj, "Font")
    If FontWrap.RqObj = 0 Then RqLclShowError("Font")
    Return FontWrap
End Function
' Окно Windows (HWND)
Property QCONTROL.Handle() As Integer
    Return RqGetHandle(RqObj)
End Property
Sub QCONTROL.Show()
    RqLclCall(RqObj, "Show")
End Sub
Sub QCONTROL.Hide()
    RqLclCall(RqObj, "Hide")
End Sub
Sub QCONTROL.Repaint()
    RqLclCall(RqObj, "Repaint")
End Sub
Sub QCONTROL.SetFocus()
    RqLclCall(RqObj, "SetFocus")
End Sub

' Константы номеров событий с параметрами
Const RqEvKeyDown = 0
Const RqEvKeyUp = 1
Const RqEvKeyPress = 2
Const RqEvMouseDown = 3
Const RqEvMouseUp = 4
Const RqEvMouseMove = 5
Const RqEvSelectCell = 6
Const RqEvDrawCell = 7
Const RqEvSetEditText = 8

' Виды обработчиков для вызова (Sender - как QCONTROL: у элемента любого
' класса QCONTROL лежит в начале)
Type RqEvProcKeyDown As Sub(ByRef As Long, ByVal As Long)
Type RqEvProcKeyDownS As Sub(ByRef As Long, ByVal As Long, ByRef As QCONTROL)
Type RqEvProcKeyUp As Sub(ByRef As Long, ByVal As Long)
Type RqEvProcKeyUpS As Sub(ByRef As Long, ByVal As Long, ByRef As QCONTROL)
Type RqEvProcKeyPress As Sub(ByRef As Long)
Type RqEvProcKeyPressS As Sub(ByRef As Long, ByRef As QCONTROL)
Type RqEvProcMouseDown As Sub(ByVal As Long, ByVal As Long, ByVal As Long, ByVal As Long)
Type RqEvProcMouseDownS As Sub(ByVal As Long, ByVal As Long, ByVal As Long, ByVal As Long, ByRef As QCONTROL)
Type RqEvProcMouseUp As Sub(ByVal As Long, ByVal As Long, ByVal As Long, ByVal As Long)
Type RqEvProcMouseUpS As Sub(ByVal As Long, ByVal As Long, ByVal As Long, ByVal As Long, ByRef As QCONTROL)
Type RqEvProcMouseMove As Sub(ByVal As Long, ByVal As Long, ByVal As Long)
Type RqEvProcMouseMoveS As Sub(ByVal As Long, ByVal As Long, ByVal As Long, ByRef As QCONTROL)
Type RqEvProcSelectCell As Sub(ByVal As Long, ByVal As Long, ByRef As Long)
Type RqEvProcSelectCellS As Sub(ByVal As Long, ByVal As Long, ByRef As Long, ByRef As QCONTROL)
Type RqEvProcDrawCell As Sub(ByVal As Long, ByVal As Long, ByVal As Long, ByRef As QRECT)
Type RqEvProcDrawCellS As Sub(ByVal As Long, ByVal As Long, ByVal As Long, ByRef As QRECT, ByRef As QCONTROL)
Type RqEvProcSetEditText As Sub(ByVal As Long, ByVal As Long, ByVal As String)
Type RqEvProcSetEditTextS As Sub(ByVal As Long, ByVal As Long, ByVal As String, ByRef As QCONTROL)
Type RqEvProcPlain As Sub()
Type RqEvProcSender As Sub(ByRef As QCONTROL)

' Вызов обработчика события с параметрами (из DLL)
Private Sub RqLclEventEx stdcall (ByVal UserPtr As Any Ptr, ByVal ObjPtr As Any Ptr, _
        ByVal EventId As Long, ByVal Args As RqEventArgs Ptr)
    Dim CtlPtr As QCONTROL Ptr = UserPtr
    If (EventId < 0) OrElse (EventId > 8) Then Exit Sub
    Dim HandlerPtr As Any Ptr = CtlPtr->EventProcs(EventId)
    Dim HandlerKind As Long = CtlPtr->EventKinds(EventId)
    If HandlerPtr = 0 Then Exit Sub
    If HandlerKind = 0 Then
        Cast(RqEvProcPlain, HandlerPtr)()
        Exit Sub
    End If
    If HandlerKind = 3 Then
        Cast(RqEvProcSender, HandlerPtr)(*CtlPtr)
        Exit Sub
    End If
    Dim ArgList As Long Ptr = @(Args->IntArgs(0))
    Select Case EventId
    Case RqEvKeyDown
        If HandlerKind = 1 Then
            Cast(RqEvProcKeyDown, HandlerPtr)(ArgList[0], ArgList[1])
        Else
            Cast(RqEvProcKeyDownS, HandlerPtr)(ArgList[0], ArgList[1], *CtlPtr)
        End If
    Case RqEvKeyUp
        If HandlerKind = 1 Then
            Cast(RqEvProcKeyUp, HandlerPtr)(ArgList[0], ArgList[1])
        Else
            Cast(RqEvProcKeyUpS, HandlerPtr)(ArgList[0], ArgList[1], *CtlPtr)
        End If
    Case RqEvKeyPress
        If HandlerKind = 1 Then
            Cast(RqEvProcKeyPress, HandlerPtr)(ArgList[0])
        Else
            Cast(RqEvProcKeyPressS, HandlerPtr)(ArgList[0], *CtlPtr)
        End If
    Case RqEvMouseDown
        If HandlerKind = 1 Then
            Cast(RqEvProcMouseDown, HandlerPtr)(ArgList[0], ArgList[1], ArgList[2], ArgList[3])
        Else
            Cast(RqEvProcMouseDownS, HandlerPtr)(ArgList[0], ArgList[1], ArgList[2], ArgList[3], *CtlPtr)
        End If
    Case RqEvMouseUp
        If HandlerKind = 1 Then
            Cast(RqEvProcMouseUp, HandlerPtr)(ArgList[0], ArgList[1], ArgList[2], ArgList[3])
        Else
            Cast(RqEvProcMouseUpS, HandlerPtr)(ArgList[0], ArgList[1], ArgList[2], ArgList[3], *CtlPtr)
        End If
    Case RqEvMouseMove
        If HandlerKind = 1 Then
            Cast(RqEvProcMouseMove, HandlerPtr)(ArgList[0], ArgList[1], ArgList[2])
        Else
            Cast(RqEvProcMouseMoveS, HandlerPtr)(ArgList[0], ArgList[1], ArgList[2], *CtlPtr)
        End If
    Case RqEvSelectCell
        If HandlerKind = 1 Then
            Cast(RqEvProcSelectCell, HandlerPtr)(ArgList[0], ArgList[1], ArgList[2])
        Else
            Cast(RqEvProcSelectCellS, HandlerPtr)(ArgList[0], ArgList[1], ArgList[2], *CtlPtr)
        End If
    Case RqEvDrawCell
        Dim CellRect As QRECT
        CellRect.Left = ArgList[3] : CellRect.Top = ArgList[4]
        CellRect.Right = ArgList[5] : CellRect.Bottom = ArgList[6]
        If HandlerKind = 1 Then
            Cast(RqEvProcDrawCell, HandlerPtr)(ArgList[0], ArgList[1], ArgList[2], CellRect)
        Else
            Cast(RqEvProcDrawCellS, HandlerPtr)(ArgList[0], ArgList[1], ArgList[2], CellRect, *CtlPtr)
        End If
    Case RqEvSetEditText
        Dim EditText As String
        If Args->StrArg <> 0 Then EditText = *Args->StrArg
        If HandlerKind = 1 Then
            Cast(RqEvProcSetEditText, HandlerPtr)(ArgList[0], ArgList[1], EditText)
        Else
            Cast(RqEvProcSetEditTextS, HandlerPtr)(ArgList[0], ArgList[1], EditText, *CtlPtr)
        End If
    End Select
End Sub

' Обработчик события с параметрами: запомнить и подключить в DLL
Sub QCONTROL.SetEventEx(ByVal EventId As Long, ByRef EventName As String, _
        ByVal Handler As Any Ptr, ByVal HandlerKind As Long)
    EventProcs(EventId) = Handler
    EventKinds(EventId) = HandlerKind
    If RqSetEventEx(RqObj, EventName, EventId, @RqLclEventEx) = 0 Then RqLclShowError(EventName)
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
    Declare Property OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    Declare Property OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QFORM))
    Declare Property OnKeyDown(ByVal Handler As Sub())
    Declare Property OnKeyDown(ByVal Handler As Sub(ByRef Sender As QFORM))
    Declare Property OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    Declare Property OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QFORM))
    Declare Property OnKeyUp(ByVal Handler As Sub())
    Declare Property OnKeyUp(ByVal Handler As Sub(ByRef Sender As QFORM))
    Declare Property OnKeyPress(ByVal Handler As Sub(ByRef Key As Long))
    Declare Property OnKeyPress(ByVal Handler As Sub(ByRef Key As Long, ByRef Sender As QFORM))
    Declare Property OnKeyPress(ByVal Handler As Sub())
    Declare Property OnKeyPress(ByVal Handler As Sub(ByRef Sender As QFORM))
    Declare Property OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QFORM))
    Declare Property OnMouseDown(ByVal Handler As Sub())
    Declare Property OnMouseDown(ByVal Handler As Sub(ByRef Sender As QFORM))
    Declare Property OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QFORM))
    Declare Property OnMouseUp(ByVal Handler As Sub())
    Declare Property OnMouseUp(ByVal Handler As Sub(ByRef Sender As QFORM))
    Declare Property OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QFORM))
    Declare Property OnMouseMove(ByVal Handler As Sub())
    Declare Property OnMouseMove(ByVal Handler As Sub(ByRef Sender As QFORM))
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
    RqObj = RqLclNew("QFORM", @This)
End Constructor

' События с параметрами QFORM: обработчик с параметрами, с ними и Sender
' последним, только с Sender или без параметров
Property QFORM.OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    SetEventEx(RqEvKeyDown, "OnKeyDown", Cast(Any Ptr, Handler), 1)
End Property
Property QFORM.OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QFORM))
    SetEventEx(RqEvKeyDown, "OnKeyDown", Cast(Any Ptr, Handler), 2)
End Property
Property QFORM.OnKeyDown(ByVal Handler As Sub())
    SetEventEx(RqEvKeyDown, "OnKeyDown", Cast(Any Ptr, Handler), 0)
End Property
Property QFORM.OnKeyDown(ByVal Handler As Sub(ByRef Sender As QFORM))
    SetEventEx(RqEvKeyDown, "OnKeyDown", Cast(Any Ptr, Handler), 3)
End Property
Property QFORM.OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    SetEventEx(RqEvKeyUp, "OnKeyUp", Cast(Any Ptr, Handler), 1)
End Property
Property QFORM.OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QFORM))
    SetEventEx(RqEvKeyUp, "OnKeyUp", Cast(Any Ptr, Handler), 2)
End Property
Property QFORM.OnKeyUp(ByVal Handler As Sub())
    SetEventEx(RqEvKeyUp, "OnKeyUp", Cast(Any Ptr, Handler), 0)
End Property
Property QFORM.OnKeyUp(ByVal Handler As Sub(ByRef Sender As QFORM))
    SetEventEx(RqEvKeyUp, "OnKeyUp", Cast(Any Ptr, Handler), 3)
End Property
Property QFORM.OnKeyPress(ByVal Handler As Sub(ByRef Key As Long))
    SetEventEx(RqEvKeyPress, "OnKeyPress", Cast(Any Ptr, Handler), 1)
End Property
Property QFORM.OnKeyPress(ByVal Handler As Sub(ByRef Key As Long, ByRef Sender As QFORM))
    SetEventEx(RqEvKeyPress, "OnKeyPress", Cast(Any Ptr, Handler), 2)
End Property
Property QFORM.OnKeyPress(ByVal Handler As Sub())
    SetEventEx(RqEvKeyPress, "OnKeyPress", Cast(Any Ptr, Handler), 0)
End Property
Property QFORM.OnKeyPress(ByVal Handler As Sub(ByRef Sender As QFORM))
    SetEventEx(RqEvKeyPress, "OnKeyPress", Cast(Any Ptr, Handler), 3)
End Property
Property QFORM.OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 1)
End Property
Property QFORM.OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QFORM))
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 2)
End Property
Property QFORM.OnMouseDown(ByVal Handler As Sub())
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 0)
End Property
Property QFORM.OnMouseDown(ByVal Handler As Sub(ByRef Sender As QFORM))
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 3)
End Property
Property QFORM.OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 1)
End Property
Property QFORM.OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QFORM))
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 2)
End Property
Property QFORM.OnMouseUp(ByVal Handler As Sub())
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 0)
End Property
Property QFORM.OnMouseUp(ByVal Handler As Sub(ByRef Sender As QFORM))
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 3)
End Property
Property QFORM.OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 1)
End Property
Property QFORM.OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QFORM))
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 2)
End Property
Property QFORM.OnMouseMove(ByVal Handler As Sub())
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 0)
End Property
Property QFORM.OnMouseMove(ByVal Handler As Sub(ByRef Sender As QFORM))
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 3)
End Property
Property QFORM.Caption() As String
    Return RqLclGetStr(RqObj, "Caption")
End Property
Property QFORM.Caption(ByRef Value As String)
    RqLclSetStr(RqObj, "Caption", Value)
End Property
Property QFORM.OnShow(ByVal Handler As Sub(ByRef Sender As QFORM))
    OnShowProc = Handler
    OnShowProcPlain = 0
    If RqSetEvent(RqObj, "OnShow", @QFORM_ShowEvent) = 0 Then RqLclShowError("OnShow")
End Property
' Обработчик без параметра Sender - как SUB ShowHandler в RapidQ
Property QFORM.OnShow(ByVal Handler As Sub())
    OnShowProcPlain = Handler
    OnShowProc = 0
    If RqSetEvent(RqObj, "OnShow", @QFORM_ShowEvent) = 0 Then RqLclShowError("OnShow")
End Property
Property QFORM.OnClose(ByVal Handler As Sub(ByRef Sender As QFORM))
    OnCloseProc = Handler
    OnCloseProcPlain = 0
    If RqSetEvent(RqObj, "OnClose", @QFORM_CloseEvent) = 0 Then RqLclShowError("OnClose")
End Property
' Обработчик без параметра Sender - как SUB CloseHandler в RapidQ
Property QFORM.OnClose(ByVal Handler As Sub())
    OnCloseProcPlain = Handler
    OnCloseProc = 0
    If RqSetEvent(RqObj, "OnClose", @QFORM_CloseEvent) = 0 Then RqLclShowError("OnClose")
End Property
Function QFORM.ShowModal() As Long
    Return RqCall(RqObj, "ShowModal")
End Function
Sub QFORM.Close()
    RqLclCall(RqObj, "Close")
End Sub
Sub QFORM.Center()
    RqLclCall(RqObj, "Center")
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
    Declare Property OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    Declare Property OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QBUTTON))
    Declare Property OnKeyDown(ByVal Handler As Sub())
    Declare Property OnKeyDown(ByVal Handler As Sub(ByRef Sender As QBUTTON))
    Declare Property OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    Declare Property OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QBUTTON))
    Declare Property OnKeyUp(ByVal Handler As Sub())
    Declare Property OnKeyUp(ByVal Handler As Sub(ByRef Sender As QBUTTON))
    Declare Property OnKeyPress(ByVal Handler As Sub(ByRef Key As Long))
    Declare Property OnKeyPress(ByVal Handler As Sub(ByRef Key As Long, ByRef Sender As QBUTTON))
    Declare Property OnKeyPress(ByVal Handler As Sub())
    Declare Property OnKeyPress(ByVal Handler As Sub(ByRef Sender As QBUTTON))
    Declare Property OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QBUTTON))
    Declare Property OnMouseDown(ByVal Handler As Sub())
    Declare Property OnMouseDown(ByVal Handler As Sub(ByRef Sender As QBUTTON))
    Declare Property OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QBUTTON))
    Declare Property OnMouseUp(ByVal Handler As Sub())
    Declare Property OnMouseUp(ByVal Handler As Sub(ByRef Sender As QBUTTON))
    Declare Property OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QBUTTON))
    Declare Property OnMouseMove(ByVal Handler As Sub())
    Declare Property OnMouseMove(ByVal Handler As Sub(ByRef Sender As QBUTTON))
End Type

Private Sub QBUTTON_ClickEvent stdcall (ByVal UserPtr As Any Ptr, ByVal ObjPtr As Any Ptr)
    Dim ButtonPtr As QBUTTON Ptr = UserPtr
    If ButtonPtr->OnClickProc <> 0 Then ButtonPtr->OnClickProc(*ButtonPtr)
    If ButtonPtr->OnClickProcPlain <> 0 Then ButtonPtr->OnClickProcPlain()
End Sub

Constructor QBUTTON()
    RqObj = RqLclNew("QBUTTON", @This)
End Constructor

' События с параметрами QBUTTON: обработчик с параметрами, с ними и Sender
' последним, только с Sender или без параметров
Property QBUTTON.OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    SetEventEx(RqEvKeyDown, "OnKeyDown", Cast(Any Ptr, Handler), 1)
End Property
Property QBUTTON.OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QBUTTON))
    SetEventEx(RqEvKeyDown, "OnKeyDown", Cast(Any Ptr, Handler), 2)
End Property
Property QBUTTON.OnKeyDown(ByVal Handler As Sub())
    SetEventEx(RqEvKeyDown, "OnKeyDown", Cast(Any Ptr, Handler), 0)
End Property
Property QBUTTON.OnKeyDown(ByVal Handler As Sub(ByRef Sender As QBUTTON))
    SetEventEx(RqEvKeyDown, "OnKeyDown", Cast(Any Ptr, Handler), 3)
End Property
Property QBUTTON.OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    SetEventEx(RqEvKeyUp, "OnKeyUp", Cast(Any Ptr, Handler), 1)
End Property
Property QBUTTON.OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QBUTTON))
    SetEventEx(RqEvKeyUp, "OnKeyUp", Cast(Any Ptr, Handler), 2)
End Property
Property QBUTTON.OnKeyUp(ByVal Handler As Sub())
    SetEventEx(RqEvKeyUp, "OnKeyUp", Cast(Any Ptr, Handler), 0)
End Property
Property QBUTTON.OnKeyUp(ByVal Handler As Sub(ByRef Sender As QBUTTON))
    SetEventEx(RqEvKeyUp, "OnKeyUp", Cast(Any Ptr, Handler), 3)
End Property
Property QBUTTON.OnKeyPress(ByVal Handler As Sub(ByRef Key As Long))
    SetEventEx(RqEvKeyPress, "OnKeyPress", Cast(Any Ptr, Handler), 1)
End Property
Property QBUTTON.OnKeyPress(ByVal Handler As Sub(ByRef Key As Long, ByRef Sender As QBUTTON))
    SetEventEx(RqEvKeyPress, "OnKeyPress", Cast(Any Ptr, Handler), 2)
End Property
Property QBUTTON.OnKeyPress(ByVal Handler As Sub())
    SetEventEx(RqEvKeyPress, "OnKeyPress", Cast(Any Ptr, Handler), 0)
End Property
Property QBUTTON.OnKeyPress(ByVal Handler As Sub(ByRef Sender As QBUTTON))
    SetEventEx(RqEvKeyPress, "OnKeyPress", Cast(Any Ptr, Handler), 3)
End Property
Property QBUTTON.OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 1)
End Property
Property QBUTTON.OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QBUTTON))
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 2)
End Property
Property QBUTTON.OnMouseDown(ByVal Handler As Sub())
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 0)
End Property
Property QBUTTON.OnMouseDown(ByVal Handler As Sub(ByRef Sender As QBUTTON))
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 3)
End Property
Property QBUTTON.OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 1)
End Property
Property QBUTTON.OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QBUTTON))
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 2)
End Property
Property QBUTTON.OnMouseUp(ByVal Handler As Sub())
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 0)
End Property
Property QBUTTON.OnMouseUp(ByVal Handler As Sub(ByRef Sender As QBUTTON))
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 3)
End Property
Property QBUTTON.OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 1)
End Property
Property QBUTTON.OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QBUTTON))
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 2)
End Property
Property QBUTTON.OnMouseMove(ByVal Handler As Sub())
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 0)
End Property
Property QBUTTON.OnMouseMove(ByVal Handler As Sub(ByRef Sender As QBUTTON))
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 3)
End Property
Property QBUTTON.Caption() As String
    Return RqLclGetStr(RqObj, "Caption")
End Property
Property QBUTTON.Caption(ByRef Value As String)
    RqLclSetStr(RqObj, "Caption", Value)
End Property
Property QBUTTON.OnClick(ByVal Handler As Sub(ByRef Sender As QBUTTON))
    OnClickProc = Handler
    OnClickProcPlain = 0
    If RqSetEvent(RqObj, "OnClick", @QBUTTON_ClickEvent) = 0 Then RqLclShowError("OnClick")
End Property
' Обработчик без параметра Sender - как SUB ClickHandler в RapidQ
Property QBUTTON.OnClick(ByVal Handler As Sub())
    OnClickProcPlain = Handler
    OnClickProc = 0
    If RqSetEvent(RqObj, "OnClick", @QBUTTON_ClickEvent) = 0 Then RqLclShowError("OnClick")
End Property
' Нажатие из программы, как щелчок мышью
Sub QBUTTON.Click()
    RqLclCall(RqObj, "Click")
End Sub

' ---------------------------------------------------------------------------
'  QLABEL
' ---------------------------------------------------------------------------

Type QLABEL Extends QCONTROL
    Declare Constructor()
    Declare Property Caption() As String
    Declare Property Caption(ByRef Value As String)
    Declare Property OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QLABEL))
    Declare Property OnMouseDown(ByVal Handler As Sub())
    Declare Property OnMouseDown(ByVal Handler As Sub(ByRef Sender As QLABEL))
    Declare Property OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QLABEL))
    Declare Property OnMouseUp(ByVal Handler As Sub())
    Declare Property OnMouseUp(ByVal Handler As Sub(ByRef Sender As QLABEL))
    Declare Property OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QLABEL))
    Declare Property OnMouseMove(ByVal Handler As Sub())
    Declare Property OnMouseMove(ByVal Handler As Sub(ByRef Sender As QLABEL))
End Type

Constructor QLABEL()
    RqObj = RqLclNew("QLABEL", @This)
End Constructor

' События с параметрами QLABEL: обработчик с параметрами, с ними и Sender
' последним, только с Sender или без параметров
Property QLABEL.OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 1)
End Property
Property QLABEL.OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QLABEL))
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 2)
End Property
Property QLABEL.OnMouseDown(ByVal Handler As Sub())
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 0)
End Property
Property QLABEL.OnMouseDown(ByVal Handler As Sub(ByRef Sender As QLABEL))
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 3)
End Property
Property QLABEL.OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 1)
End Property
Property QLABEL.OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QLABEL))
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 2)
End Property
Property QLABEL.OnMouseUp(ByVal Handler As Sub())
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 0)
End Property
Property QLABEL.OnMouseUp(ByVal Handler As Sub(ByRef Sender As QLABEL))
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 3)
End Property
Property QLABEL.OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 1)
End Property
Property QLABEL.OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QLABEL))
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 2)
End Property
Property QLABEL.OnMouseMove(ByVal Handler As Sub())
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 0)
End Property
Property QLABEL.OnMouseMove(ByVal Handler As Sub(ByRef Sender As QLABEL))
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 3)
End Property
Property QLABEL.Caption() As String
    Return RqLclGetStr(RqObj, "Caption")
End Property
Property QLABEL.Caption(ByRef Value As String)
    RqLclSetStr(RqObj, "Caption", Value)
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
    Declare Property OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    Declare Property OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QEDIT))
    Declare Property OnKeyDown(ByVal Handler As Sub())
    Declare Property OnKeyDown(ByVal Handler As Sub(ByRef Sender As QEDIT))
    Declare Property OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    Declare Property OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QEDIT))
    Declare Property OnKeyUp(ByVal Handler As Sub())
    Declare Property OnKeyUp(ByVal Handler As Sub(ByRef Sender As QEDIT))
    Declare Property OnKeyPress(ByVal Handler As Sub(ByRef Key As Long))
    Declare Property OnKeyPress(ByVal Handler As Sub(ByRef Key As Long, ByRef Sender As QEDIT))
    Declare Property OnKeyPress(ByVal Handler As Sub())
    Declare Property OnKeyPress(ByVal Handler As Sub(ByRef Sender As QEDIT))
    Declare Property OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QEDIT))
    Declare Property OnMouseDown(ByVal Handler As Sub())
    Declare Property OnMouseDown(ByVal Handler As Sub(ByRef Sender As QEDIT))
    Declare Property OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QEDIT))
    Declare Property OnMouseUp(ByVal Handler As Sub())
    Declare Property OnMouseUp(ByVal Handler As Sub(ByRef Sender As QEDIT))
    Declare Property OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QEDIT))
    Declare Property OnMouseMove(ByVal Handler As Sub())
    Declare Property OnMouseMove(ByVal Handler As Sub(ByRef Sender As QEDIT))
End Type

Private Sub QEDIT_ChangeEvent stdcall (ByVal UserPtr As Any Ptr, ByVal ObjPtr As Any Ptr)
    Dim EditPtr As QEDIT Ptr = UserPtr
    If EditPtr->OnChangeProc <> 0 Then EditPtr->OnChangeProc(*EditPtr)
    If EditPtr->OnChangeProcPlain <> 0 Then EditPtr->OnChangeProcPlain()
End Sub

Constructor QEDIT()
    RqObj = RqLclNew("QEDIT", @This)
End Constructor

' События с параметрами QEDIT: обработчик с параметрами, с ними и Sender
' последним, только с Sender или без параметров
Property QEDIT.OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    SetEventEx(RqEvKeyDown, "OnKeyDown", Cast(Any Ptr, Handler), 1)
End Property
Property QEDIT.OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QEDIT))
    SetEventEx(RqEvKeyDown, "OnKeyDown", Cast(Any Ptr, Handler), 2)
End Property
Property QEDIT.OnKeyDown(ByVal Handler As Sub())
    SetEventEx(RqEvKeyDown, "OnKeyDown", Cast(Any Ptr, Handler), 0)
End Property
Property QEDIT.OnKeyDown(ByVal Handler As Sub(ByRef Sender As QEDIT))
    SetEventEx(RqEvKeyDown, "OnKeyDown", Cast(Any Ptr, Handler), 3)
End Property
Property QEDIT.OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    SetEventEx(RqEvKeyUp, "OnKeyUp", Cast(Any Ptr, Handler), 1)
End Property
Property QEDIT.OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QEDIT))
    SetEventEx(RqEvKeyUp, "OnKeyUp", Cast(Any Ptr, Handler), 2)
End Property
Property QEDIT.OnKeyUp(ByVal Handler As Sub())
    SetEventEx(RqEvKeyUp, "OnKeyUp", Cast(Any Ptr, Handler), 0)
End Property
Property QEDIT.OnKeyUp(ByVal Handler As Sub(ByRef Sender As QEDIT))
    SetEventEx(RqEvKeyUp, "OnKeyUp", Cast(Any Ptr, Handler), 3)
End Property
Property QEDIT.OnKeyPress(ByVal Handler As Sub(ByRef Key As Long))
    SetEventEx(RqEvKeyPress, "OnKeyPress", Cast(Any Ptr, Handler), 1)
End Property
Property QEDIT.OnKeyPress(ByVal Handler As Sub(ByRef Key As Long, ByRef Sender As QEDIT))
    SetEventEx(RqEvKeyPress, "OnKeyPress", Cast(Any Ptr, Handler), 2)
End Property
Property QEDIT.OnKeyPress(ByVal Handler As Sub())
    SetEventEx(RqEvKeyPress, "OnKeyPress", Cast(Any Ptr, Handler), 0)
End Property
Property QEDIT.OnKeyPress(ByVal Handler As Sub(ByRef Sender As QEDIT))
    SetEventEx(RqEvKeyPress, "OnKeyPress", Cast(Any Ptr, Handler), 3)
End Property
Property QEDIT.OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 1)
End Property
Property QEDIT.OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QEDIT))
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 2)
End Property
Property QEDIT.OnMouseDown(ByVal Handler As Sub())
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 0)
End Property
Property QEDIT.OnMouseDown(ByVal Handler As Sub(ByRef Sender As QEDIT))
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 3)
End Property
Property QEDIT.OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 1)
End Property
Property QEDIT.OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QEDIT))
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 2)
End Property
Property QEDIT.OnMouseUp(ByVal Handler As Sub())
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 0)
End Property
Property QEDIT.OnMouseUp(ByVal Handler As Sub(ByRef Sender As QEDIT))
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 3)
End Property
Property QEDIT.OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 1)
End Property
Property QEDIT.OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QEDIT))
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 2)
End Property
Property QEDIT.OnMouseMove(ByVal Handler As Sub())
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 0)
End Property
Property QEDIT.OnMouseMove(ByVal Handler As Sub(ByRef Sender As QEDIT))
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 3)
End Property
Property QEDIT.Text() As String
    Return RqLclGetStr(RqObj, "Text")
End Property
Property QEDIT.Text(ByRef Value As String)
    RqLclSetStr(RqObj, "Text", Value)
End Property
Property QEDIT.OnChange(ByVal Handler As Sub(ByRef Sender As QEDIT))
    OnChangeProc = Handler
    OnChangeProcPlain = 0
    If RqSetEvent(RqObj, "OnChange", @QEDIT_ChangeEvent) = 0 Then RqLclShowError("OnChange")
End Property
' Обработчик без параметра Sender - как SUB ChangeHandler в RapidQ
Property QEDIT.OnChange(ByVal Handler As Sub())
    OnChangeProcPlain = Handler
    OnChangeProc = 0
    If RqSetEvent(RqObj, "OnChange", @QEDIT_ChangeEvent) = 0 Then RqLclShowError("OnChange")
End Property

' ---------------------------------------------------------------------------
'  QRICHEDIT - многострочный текст с форматированием (RichMemo LCL поверх
'  окна RichEdit Windows)
'      RichEdit.SelStart = Len(RichEdit.Text)
'      RichEdit.SelAttributes.Color = &hFF     ' атрибуты точки ввода
'      RichEdit.AddStrings "красная строка"
'  Позиции SelStart / SelLength - в символах окна RichEdit: перевод строки
'  в нём один символ, а в Text - два (CR LF).
' ---------------------------------------------------------------------------

Type QRICHEDIT Extends QCONTROL
    SelAttrWrap As QFONT = QFONT(0)
    OnChangeProc As Sub(ByRef Sender As QRICHEDIT)
    OnChangeProcPlain As Sub()
    Declare Constructor()
    Declare Property Text() As String
    Declare Property Text(ByRef Value As String)
    Declare Property Align() As Long
    Declare Property Align(ByVal Value As Long)
    Declare Property Alignment() As Long
    Declare Property Alignment(ByVal Value As Long)
    Declare Property BorderStyle() As Long
    Declare Property BorderStyle(ByVal Value As Long)
    Declare Property HideScrollBars() As Long
    Declare Property HideScrollBars(ByVal Value As Long)
    Declare Property HideSelection() As Long
    Declare Property HideSelection(ByVal Value As Long)
    Declare Property Line(ByVal LineIndex As Long) As String
    Declare Property Line(ByVal LineIndex As Long, ByRef Value As String)
    Declare Property LineCount() As Long
    Declare Property Modified() As Long
    Declare Property Modified(ByVal Value As Long)
    Declare Property PlainText() As Long
    Declare Property PlainText(ByVal Value As Long)
    Declare Property ReadOnly() As Long
    Declare Property ReadOnly(ByVal Value As Long)
    Declare Property ScrollBars() As Long
    Declare Property ScrollBars(ByVal Value As Long)
    Declare Function SelAttributes() ByRef As QFONT
    Declare Property SelLength() As Long
    Declare Property SelLength(ByVal Value As Long)
    Declare Property SelStart() As Long
    Declare Property SelStart(ByVal Value As Long)
    Declare Property SelText() As String
    Declare Property SelText(ByRef Value As String)
    Declare Property TabOrder() As Long
    Declare Property TabOrder(ByVal Value As Long)
    Declare Property Tag() As Long
    Declare Property Tag(ByVal Value As Long)
    Declare Property WantTabs() As Long
    Declare Property WantTabs(ByVal Value As Long)
    Declare Property WhereX() As Long
    Declare Property WhereY() As Long
    Declare Property WordWrap() As Long
    Declare Property WordWrap(ByVal Value As Long)
    Declare Property OnChange(ByVal Handler As Sub(ByRef Sender As QRICHEDIT))
    Declare Property OnChange(ByVal Handler As Sub())
    Declare Sub AddStrings Overload (ByRef Text1 As String)
    Declare Sub AddStrings Overload (ByRef Text1 As String, ByRef Text2 As String)
    Declare Sub AddStrings Overload (ByRef Text1 As String, ByRef Text2 As String, _
        ByRef Text3 As String)
    Declare Sub AddStrings Overload (ByRef Text1 As String, ByRef Text2 As String, _
        ByRef Text3 As String, ByRef Text4 As String)
    Declare Sub AddString(ByRef Text1 As String)
    Declare Sub Clear()
    Declare Sub CopyToClipboard()
    Declare Sub CutToClipboard()
    Declare Sub PasteFromClipboard()
    Declare Sub SelectAll()
    Declare Sub LoadFromFile(ByRef FileName As String)
    Declare Sub SaveToFile(ByRef FileName As String)
    Declare Sub LoadFromStream(ByRef Stream As RqStream)
    Declare Sub SaveToStream(ByRef Stream As RqStream)
    Declare Property OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    Declare Property OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QRICHEDIT))
    Declare Property OnKeyDown(ByVal Handler As Sub())
    Declare Property OnKeyDown(ByVal Handler As Sub(ByRef Sender As QRICHEDIT))
    Declare Property OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    Declare Property OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QRICHEDIT))
    Declare Property OnKeyUp(ByVal Handler As Sub())
    Declare Property OnKeyUp(ByVal Handler As Sub(ByRef Sender As QRICHEDIT))
    Declare Property OnKeyPress(ByVal Handler As Sub(ByRef Key As Long))
    Declare Property OnKeyPress(ByVal Handler As Sub(ByRef Key As Long, ByRef Sender As QRICHEDIT))
    Declare Property OnKeyPress(ByVal Handler As Sub())
    Declare Property OnKeyPress(ByVal Handler As Sub(ByRef Sender As QRICHEDIT))
    Declare Property OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QRICHEDIT))
    Declare Property OnMouseDown(ByVal Handler As Sub())
    Declare Property OnMouseDown(ByVal Handler As Sub(ByRef Sender As QRICHEDIT))
    Declare Property OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QRICHEDIT))
    Declare Property OnMouseUp(ByVal Handler As Sub())
    Declare Property OnMouseUp(ByVal Handler As Sub(ByRef Sender As QRICHEDIT))
    Declare Property OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QRICHEDIT))
    Declare Property OnMouseMove(ByVal Handler As Sub())
    Declare Property OnMouseMove(ByVal Handler As Sub(ByRef Sender As QRICHEDIT))
End Type

Private Sub QRICHEDIT_ChangeEvent stdcall (ByVal UserPtr As Any Ptr, ByVal ObjPtr As Any Ptr)
    Dim EditPtr As QRICHEDIT Ptr = UserPtr
    If EditPtr->OnChangeProc <> 0 Then EditPtr->OnChangeProc(*EditPtr)
    If EditPtr->OnChangeProcPlain <> 0 Then EditPtr->OnChangeProcPlain()
End Sub

Constructor QRICHEDIT()
    RqObj = RqLclNew("QRICHEDIT", @This)
End Constructor

' События с параметрами QRICHEDIT: обработчик с параметрами, с ними и Sender
' последним, только с Sender или без параметров
Property QRICHEDIT.OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    SetEventEx(RqEvKeyDown, "OnKeyDown", Cast(Any Ptr, Handler), 1)
End Property
Property QRICHEDIT.OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QRICHEDIT))
    SetEventEx(RqEvKeyDown, "OnKeyDown", Cast(Any Ptr, Handler), 2)
End Property
Property QRICHEDIT.OnKeyDown(ByVal Handler As Sub())
    SetEventEx(RqEvKeyDown, "OnKeyDown", Cast(Any Ptr, Handler), 0)
End Property
Property QRICHEDIT.OnKeyDown(ByVal Handler As Sub(ByRef Sender As QRICHEDIT))
    SetEventEx(RqEvKeyDown, "OnKeyDown", Cast(Any Ptr, Handler), 3)
End Property
Property QRICHEDIT.OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    SetEventEx(RqEvKeyUp, "OnKeyUp", Cast(Any Ptr, Handler), 1)
End Property
Property QRICHEDIT.OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QRICHEDIT))
    SetEventEx(RqEvKeyUp, "OnKeyUp", Cast(Any Ptr, Handler), 2)
End Property
Property QRICHEDIT.OnKeyUp(ByVal Handler As Sub())
    SetEventEx(RqEvKeyUp, "OnKeyUp", Cast(Any Ptr, Handler), 0)
End Property
Property QRICHEDIT.OnKeyUp(ByVal Handler As Sub(ByRef Sender As QRICHEDIT))
    SetEventEx(RqEvKeyUp, "OnKeyUp", Cast(Any Ptr, Handler), 3)
End Property
Property QRICHEDIT.OnKeyPress(ByVal Handler As Sub(ByRef Key As Long))
    SetEventEx(RqEvKeyPress, "OnKeyPress", Cast(Any Ptr, Handler), 1)
End Property
Property QRICHEDIT.OnKeyPress(ByVal Handler As Sub(ByRef Key As Long, ByRef Sender As QRICHEDIT))
    SetEventEx(RqEvKeyPress, "OnKeyPress", Cast(Any Ptr, Handler), 2)
End Property
Property QRICHEDIT.OnKeyPress(ByVal Handler As Sub())
    SetEventEx(RqEvKeyPress, "OnKeyPress", Cast(Any Ptr, Handler), 0)
End Property
Property QRICHEDIT.OnKeyPress(ByVal Handler As Sub(ByRef Sender As QRICHEDIT))
    SetEventEx(RqEvKeyPress, "OnKeyPress", Cast(Any Ptr, Handler), 3)
End Property
Property QRICHEDIT.OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 1)
End Property
Property QRICHEDIT.OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QRICHEDIT))
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 2)
End Property
Property QRICHEDIT.OnMouseDown(ByVal Handler As Sub())
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 0)
End Property
Property QRICHEDIT.OnMouseDown(ByVal Handler As Sub(ByRef Sender As QRICHEDIT))
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 3)
End Property
Property QRICHEDIT.OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 1)
End Property
Property QRICHEDIT.OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QRICHEDIT))
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 2)
End Property
Property QRICHEDIT.OnMouseUp(ByVal Handler As Sub())
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 0)
End Property
Property QRICHEDIT.OnMouseUp(ByVal Handler As Sub(ByRef Sender As QRICHEDIT))
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 3)
End Property
Property QRICHEDIT.OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 1)
End Property
Property QRICHEDIT.OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QRICHEDIT))
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 2)
End Property
Property QRICHEDIT.OnMouseMove(ByVal Handler As Sub())
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 0)
End Property
Property QRICHEDIT.OnMouseMove(ByVal Handler As Sub(ByRef Sender As QRICHEDIT))
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 3)
End Property
Property QRICHEDIT.Text() As String
    Return RqLclGetStr(RqObj, "Text")
End Property
Property QRICHEDIT.Text(ByRef Value As String)
    RqLclSetStr(RqObj, "Text", Value)
End Property
Property QRICHEDIT.Align() As Long
    Return RqGetInt(RqObj, "Align")
End Property
Property QRICHEDIT.Align(ByVal Value As Long)
    RqLclSetInt(RqObj, "Align", Value)
End Property
Property QRICHEDIT.Alignment() As Long
    Return RqGetInt(RqObj, "Alignment")
End Property
Property QRICHEDIT.Alignment(ByVal Value As Long)
    RqLclSetInt(RqObj, "Alignment", Value)
End Property
Property QRICHEDIT.BorderStyle() As Long
    Return RqGetInt(RqObj, "BorderStyle")
End Property
Property QRICHEDIT.BorderStyle(ByVal Value As Long)
    RqLclSetInt(RqObj, "BorderStyle", Value)
End Property
Property QRICHEDIT.HideScrollBars() As Long
    Return RqGetInt(RqObj, "HideScrollBars")
End Property
Property QRICHEDIT.HideScrollBars(ByVal Value As Long)
    RqLclSetInt(RqObj, "HideScrollBars", Value)
End Property
Property QRICHEDIT.HideSelection() As Long
    Return RqGetInt(RqObj, "HideSelection")
End Property
Property QRICHEDIT.HideSelection(ByVal Value As Long)
    RqLclSetInt(RqObj, "HideSelection", Value)
End Property
' Строка с номером LineIndex (с 0)
Property QRICHEDIT.Line(ByVal LineIndex As Long) As String
    Return RqLclGetItem(RqObj, "Line", LineIndex)
End Property
Property QRICHEDIT.Line(ByVal LineIndex As Long, ByRef Value As String)
    If RqSetItemStr(RqObj, "Line", LineIndex, StrPtr(Value)) = 0 Then
        RqLclShowError("Line(" & LineIndex & ")")
    End If
End Property
Property QRICHEDIT.LineCount() As Long
    Return RqGetInt(RqObj, "LineCount")
End Property
Property QRICHEDIT.Modified() As Long
    Return RqGetInt(RqObj, "Modified")
End Property
Property QRICHEDIT.Modified(ByVal Value As Long)
    RqLclSetInt(RqObj, "Modified", Value)
End Property
' 1 - LoadFromFile / SaveToFile и потоки - обычный текст, не RTF
Property QRICHEDIT.PlainText() As Long
    Return RqGetInt(RqObj, "PlainText")
End Property
Property QRICHEDIT.PlainText(ByVal Value As Long)
    RqLclSetInt(RqObj, "PlainText", Value)
End Property
Property QRICHEDIT.ReadOnly() As Long
    Return RqGetInt(RqObj, "ReadOnly")
End Property
Property QRICHEDIT.ReadOnly(ByVal Value As Long)
    RqLclSetInt(RqObj, "ReadOnly", Value)
End Property
Property QRICHEDIT.ScrollBars() As Long
    Return RqGetInt(RqObj, "ScrollBars")
End Property
Property QRICHEDIT.ScrollBars(ByVal Value As Long)
    RqLclSetInt(RqObj, "ScrollBars", Value)
End Property
' Атрибуты выделения: изменение свойств - сразу на выделение (только
' изменённое свойство; без выделения - точка ввода)
' RichEdit.SelAttributes = Font - значения шрифта выделению (QFONT.Let)
Function QRICHEDIT.SelAttributes() ByRef As QFONT
    SelAttrWrap.RqObj = RqGetObj(RqObj, "SelAttributes")
    If SelAttrWrap.RqObj = 0 Then RqLclShowError("SelAttributes")
    Return SelAttrWrap
End Function
Property QRICHEDIT.SelLength() As Long
    Return RqGetInt(RqObj, "SelLength")
End Property
Property QRICHEDIT.SelLength(ByVal Value As Long)
    RqLclSetInt(RqObj, "SelLength", Value)
End Property
Property QRICHEDIT.SelStart() As Long
    Return RqGetInt(RqObj, "SelStart")
End Property
Property QRICHEDIT.SelStart(ByVal Value As Long)
    RqLclSetInt(RqObj, "SelStart", Value)
End Property
Property QRICHEDIT.SelText() As String
    Return RqLclGetStr(RqObj, "SelText")
End Property
' Замена выделения; курсор - после вставленного
Property QRICHEDIT.SelText(ByRef Value As String)
    RqLclSetStr(RqObj, "SelText", Value)
End Property
Property QRICHEDIT.TabOrder() As Long
    Return RqGetInt(RqObj, "TabOrder")
End Property
Property QRICHEDIT.TabOrder(ByVal Value As Long)
    RqLclSetInt(RqObj, "TabOrder", Value)
End Property
Property QRICHEDIT.Tag() As Long
    Return RqGetInt(RqObj, "Tag")
End Property
Property QRICHEDIT.Tag(ByVal Value As Long)
    RqLclSetInt(RqObj, "Tag", Value)
End Property
Property QRICHEDIT.WantTabs() As Long
    Return RqGetInt(RqObj, "WantTabs")
End Property
Property QRICHEDIT.WantTabs(ByVal Value As Long)
    RqLclSetInt(RqObj, "WantTabs", Value)
End Property
' Позиция курсора: столбец и строка (с 0)
Property QRICHEDIT.WhereX() As Long
    Return RqGetInt(RqObj, "WhereX")
End Property
Property QRICHEDIT.WhereY() As Long
    Return RqGetInt(RqObj, "WhereY")
End Property
Property QRICHEDIT.WordWrap() As Long
    Return RqGetInt(RqObj, "WordWrap")
End Property
Property QRICHEDIT.WordWrap(ByVal Value As Long)
    RqLclSetInt(RqObj, "WordWrap", Value)
End Property
Property QRICHEDIT.OnChange(ByVal Handler As Sub(ByRef Sender As QRICHEDIT))
    OnChangeProc = Handler
    OnChangeProcPlain = 0
    If RqSetEvent(RqObj, "OnChange", @QRICHEDIT_ChangeEvent) = 0 Then RqLclShowError("OnChange")
End Property
' Обработчик без параметра Sender
Property QRICHEDIT.OnChange(ByVal Handler As Sub())
    OnChangeProcPlain = Handler
    OnChangeProc = 0
    If RqSetEvent(RqObj, "OnChange", @QRICHEDIT_ChangeEvent) = 0 Then RqLclShowError("OnChange")
End Property
' Строки в конец, каждая - новой строкой. В RapidQ число параметров не
' ограничено, здесь - до четырёх
Sub QRICHEDIT.AddStrings(ByRef Text1 As String)
    RqLclCallStr(RqObj, "AddStrings", Text1)
End Sub
Sub QRICHEDIT.AddStrings(ByRef Text1 As String, ByRef Text2 As String)
    RqLclCallStr(RqObj, "AddStrings", Text1)
    RqLclCallStr(RqObj, "AddStrings", Text2)
End Sub
Sub QRICHEDIT.AddStrings(ByRef Text1 As String, ByRef Text2 As String, _
        ByRef Text3 As String)
    RqLclCallStr(RqObj, "AddStrings", Text1)
    RqLclCallStr(RqObj, "AddStrings", Text2)
    RqLclCallStr(RqObj, "AddStrings", Text3)
End Sub
Sub QRICHEDIT.AddStrings(ByRef Text1 As String, ByRef Text2 As String, _
        ByRef Text3 As String, ByRef Text4 As String)
    RqLclCallStr(RqObj, "AddStrings", Text1)
    RqLclCallStr(RqObj, "AddStrings", Text2)
    RqLclCallStr(RqObj, "AddStrings", Text3)
    RqLclCallStr(RqObj, "AddStrings", Text4)
End Sub
' Как в примере документации RapidQ
Sub QRICHEDIT.AddString(ByRef Text1 As String)
    RqLclCallStr(RqObj, "AddStrings", Text1)
End Sub
Sub QRICHEDIT.Clear()
    RqLclCall(RqObj, "Clear")
End Sub
Sub QRICHEDIT.CopyToClipboard()
    RqLclCall(RqObj, "CopyToClipboard")
End Sub
Sub QRICHEDIT.CutToClipboard()
    RqLclCall(RqObj, "CutToClipboard")
End Sub
Sub QRICHEDIT.PasteFromClipboard()
    RqLclCall(RqObj, "PasteFromClipboard")
End Sub
Sub QRICHEDIT.SelectAll()
    RqLclCall(RqObj, "SelectAll")
End Sub
' RTF (файл начинается с {\rtf) или обычный текст; PlainText = 1 - всегда
' обычный текст
Sub QRICHEDIT.LoadFromFile(ByRef FileName As String)
    RqLclCallStr(RqObj, "LoadFromFile", FileName)
End Sub
' RTF; PlainText = 1 - обычный текст
Sub QRICHEDIT.SaveToFile(ByRef FileName As String)
    RqLclCallStr(RqObj, "SaveToFile", FileName)
End Sub
' Из потока - от текущей позиции до конца
Sub QRICHEDIT.LoadFromStream(ByRef Stream As RqStream)
    Dim DataLen As Long = Stream.Size - Stream.Position
    Dim StreamText As String
    If DataLen > 0 Then
        StreamText = Space(DataLen)
        DataLen = Stream.ReadBuf(StrPtr(StreamText), DataLen)
        StreamText = Mid(StreamText, 1, DataLen)   ' Left - свойство QCONTROL
    End If
    RqLclSetStr(RqObj, "RichText", StreamText)
End Sub
' В поток с текущей позиции
Sub QRICHEDIT.SaveToStream(ByRef Stream As RqStream)
    Dim StreamText As String = RqLclGetStr(RqObj, "RichText")
    If Len(StreamText) > 0 Then Stream.WriteBuf(StrPtr(StreamText), Len(StreamText))
End Sub

' ---------------------------------------------------------------------------
'  QSTRINGGRID - таблица строк (TStringGrid LCL)
'  Cell(Col, Row) - функция; запись - SetCell(Col, Row, Значение): у
'  свойства FreeBASIC только один индекс. Препроцессор переводит
'  Grid.Cell(c, r) = x в Grid.SetCell(c, r, x).
'  Ячейка вне таблицы: Smart - "" и предупреждение в лог, Compat - конец
'  программы.
'  Пока нет: ColumnStyle, ColumnList, TabStops, OnEllipsisClick,
'  OnListDropDown, Draw, CopyRect, StretchDraw, TextRect.
' ---------------------------------------------------------------------------

Type QSTRINGGRID Extends QCONTROL
    Declare Constructor()
    Declare Function Cell(ByVal ColIdx As Long, ByVal RowIdx As Long) As String
    Declare Sub SetCell(ByVal ColIdx As Long, ByVal RowIdx As Long, ByRef Value As String)
    Declare Property ColWidths(ByVal ColIdx As Long) As Long
    Declare Property ColWidths(ByVal ColIdx As Long, ByVal Value As Long)
    Declare Property RowHeights(ByVal RowIdx As Long) As Long
    Declare Property RowHeights(ByVal RowIdx As Long, ByVal Value As Long)
    Declare Property Align() As Long
    Declare Property Align(ByVal Value As Long)
    Declare Property BorderStyle() As Long
    Declare Property BorderStyle(ByVal Value As Long)
    Declare Property Col() As Long
    Declare Property Col(ByVal Value As Long)
    Declare Property ColCount() As Long
    Declare Property ColCount(ByVal Value As Long)
    Declare Property DefaultColWidth() As Long
    Declare Property DefaultColWidth(ByVal Value As Long)
    Declare Property DefaultRowHeight() As Long
    Declare Property DefaultRowHeight(ByVal Value As Long)
    Declare Property EditorMode() As Long
    Declare Property EditorMode(ByVal Value As Long)
    Declare Property FixedColor() As Long
    Declare Property FixedColor(ByVal Value As Long)
    Declare Property FixedCols() As Long
    Declare Property FixedCols(ByVal Value As Long)
    Declare Property FixedRows() As Long
    Declare Property FixedRows(ByVal Value As Long)
    Declare Property GridHeight() As Long
    Declare Property GridLineWidth() As Long
    Declare Property GridLineWidth(ByVal Value As Long)
    Declare Property GridWidth() As Long
    Declare Property LeftCol() As Long
    Declare Property LeftCol(ByVal Value As Long)
    Declare Property Row() As Long
    Declare Property Row(ByVal Value As Long)
    Declare Property RowCount() As Long
    Declare Property RowCount(ByVal Value As Long)
    Declare Property ScrollBars() As Long
    Declare Property ScrollBars(ByVal Value As Long)
    Declare Property Separator() As String
    Declare Property Separator(ByRef Value As String)
    Declare Property TabOrder() As Long
    Declare Property TabOrder(ByVal Value As Long)
    Declare Property Tag() As Long
    Declare Property Tag(ByVal Value As Long)
    Declare Property TopRow() As Long
    Declare Property TopRow(ByVal Value As Long)
    Declare Property VisibleColCount() As Long
    Declare Property VisibleRowCount() As Long
    Declare Sub AddOptions(ByVal Option1 As Long, ByVal Option2 As Long = -1, _
        ByVal Option3 As Long = -1, ByVal Option4 As Long = -1, _
        ByVal Option5 As Long = -1, ByVal Option6 As Long = -1)
    Declare Sub DelOptions(ByVal Option1 As Long, ByVal Option2 As Long = -1, _
        ByVal Option3 As Long = -1, ByVal Option4 As Long = -1, _
        ByVal Option5 As Long = -1, ByVal Option6 As Long = -1)
    Declare Sub DeleteCol(ByVal ColIdx As Long)
    Declare Sub DeleteRow(ByVal RowIdx As Long)
    Declare Sub InsertCol(ByVal ColIdx As Long)
    Declare Sub InsertRow(ByVal RowIdx As Long)
    Declare Sub SwapCols(ByVal Col1 As Long, ByVal Col2 As Long)
    Declare Sub SwapRows(ByVal Row1 As Long, ByVal Row2 As Long)
    Declare Sub LoadFromFile(ByRef FileName As String, ByVal RowOffset As Long = 0, _
        ByVal ColOffset As Long = 0, ByVal MaxRows As Long = 0)
    Declare Sub SaveToFile(ByRef FileName As String, ByVal RowOffset As Long = 0, _
        ByVal ColOffset As Long = 0, ByVal MaxRows As Long = 0)
    Declare Sub LoadFromStream(ByRef Stream As RqStream, ByVal RowOffset As Long = 0, _
        ByVal ColOffset As Long = 0, ByVal MaxRows As Long = 0)
    Declare Sub SaveToStream(ByRef Stream As RqStream, ByVal RowOffset As Long = 0, _
        ByVal ColOffset As Long = 0, ByVal MaxRows As Long = 0)
    Declare Function TextWidth(ByRef Text1 As String) As Long
    Declare Function TextHeight(ByRef Text1 As String) As Long
    Declare Sub FillRect(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, _
        ByVal Y2 As Long, ByVal FillColor As Long)
    Declare Sub TextOut(ByVal X1 As Long, ByVal Y1 As Long, ByRef Text1 As String, _
        ByVal TextColor As Long, ByVal BackColor As Long = -1)
    Declare Sub Line(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, _
        ByVal Y2 As Long, ByVal LineColor As Long)
    Declare Sub Rectangle(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, _
        ByVal Y2 As Long, ByVal LineColor As Long)
    Declare Sub RoundRect(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, _
        ByVal Y2 As Long, ByVal X3 As Long, ByVal Y3 As Long, ByVal FillColor As Long)
    Declare Sub Circle(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, _
        ByVal Y2 As Long, ByVal LineColor As Long, ByVal FillFlag As Long)
    Declare Sub Pset(ByVal X1 As Long, ByVal Y1 As Long, ByVal PixelColor As Long)
    Declare Sub Paint(ByVal X1 As Long, ByVal Y1 As Long, ByVal FillColor As Long, _
        ByVal BorderColor As Long)
    Declare Sub DrawInts(ByRef MethodName As String, ByRef Text1 As String, _
        IntList() As Long)
    ' служебное
    Declare Sub CallInts(ByRef MethodName As String, ByVal IntArg1 As Long, _
        ByVal IntArg2 As Long = 0)
    Declare Sub OptionList(ByRef MethodName As String, ByVal Option1 As Long, _
        ByVal Option2 As Long, ByVal Option3 As Long, ByVal Option4 As Long, _
        ByVal Option5 As Long, ByVal Option6 As Long)
    Declare Property OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    Declare Property OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QSTRINGGRID))
    Declare Property OnKeyDown(ByVal Handler As Sub())
    Declare Property OnKeyDown(ByVal Handler As Sub(ByRef Sender As QSTRINGGRID))
    Declare Property OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    Declare Property OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QSTRINGGRID))
    Declare Property OnKeyUp(ByVal Handler As Sub())
    Declare Property OnKeyUp(ByVal Handler As Sub(ByRef Sender As QSTRINGGRID))
    Declare Property OnKeyPress(ByVal Handler As Sub(ByRef Key As Long))
    Declare Property OnKeyPress(ByVal Handler As Sub(ByRef Key As Long, ByRef Sender As QSTRINGGRID))
    Declare Property OnKeyPress(ByVal Handler As Sub())
    Declare Property OnKeyPress(ByVal Handler As Sub(ByRef Sender As QSTRINGGRID))
    Declare Property OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QSTRINGGRID))
    Declare Property OnMouseDown(ByVal Handler As Sub())
    Declare Property OnMouseDown(ByVal Handler As Sub(ByRef Sender As QSTRINGGRID))
    Declare Property OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QSTRINGGRID))
    Declare Property OnMouseUp(ByVal Handler As Sub())
    Declare Property OnMouseUp(ByVal Handler As Sub(ByRef Sender As QSTRINGGRID))
    Declare Property OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QSTRINGGRID))
    Declare Property OnMouseMove(ByVal Handler As Sub())
    Declare Property OnMouseMove(ByVal Handler As Sub(ByRef Sender As QSTRINGGRID))
    Declare Property OnSelectCell(ByVal Handler As Sub(ByVal Col As Long, ByVal Row As Long, ByRef CanSelect As Long))
    Declare Property OnSelectCell(ByVal Handler As Sub(ByVal Col As Long, ByVal Row As Long, ByRef CanSelect As Long, ByRef Sender As QSTRINGGRID))
    Declare Property OnSelectCell(ByVal Handler As Sub())
    Declare Property OnSelectCell(ByVal Handler As Sub(ByRef Sender As QSTRINGGRID))
    Declare Property OnDrawCell(ByVal Handler As Sub(ByVal Col As Long, ByVal Row As Long, ByVal State As Long, ByRef R As QRECT))
    Declare Property OnDrawCell(ByVal Handler As Sub(ByVal Col As Long, ByVal Row As Long, ByVal State As Long, ByRef R As QRECT, ByRef Sender As QSTRINGGRID))
    Declare Property OnDrawCell(ByVal Handler As Sub())
    Declare Property OnDrawCell(ByVal Handler As Sub(ByRef Sender As QSTRINGGRID))
    Declare Property OnSetEditText(ByVal Handler As Sub(ByVal Col As Long, ByVal Row As Long, ByVal Value As String))
    Declare Property OnSetEditText(ByVal Handler As Sub(ByVal Col As Long, ByVal Row As Long, ByVal Value As String, ByRef Sender As QSTRINGGRID))
    Declare Property OnSetEditText(ByVal Handler As Sub())
    Declare Property OnSetEditText(ByVal Handler As Sub(ByRef Sender As QSTRINGGRID))
End Type

Constructor QSTRINGGRID()
    RqObj = RqLclNew("QSTRINGGRID", @This)
End Constructor

' События с параметрами QSTRINGGRID: обработчик с параметрами, с ними и Sender
' последним, только с Sender или без параметров
Property QSTRINGGRID.OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    SetEventEx(RqEvKeyDown, "OnKeyDown", Cast(Any Ptr, Handler), 1)
End Property
Property QSTRINGGRID.OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QSTRINGGRID))
    SetEventEx(RqEvKeyDown, "OnKeyDown", Cast(Any Ptr, Handler), 2)
End Property
Property QSTRINGGRID.OnKeyDown(ByVal Handler As Sub())
    SetEventEx(RqEvKeyDown, "OnKeyDown", Cast(Any Ptr, Handler), 0)
End Property
Property QSTRINGGRID.OnKeyDown(ByVal Handler As Sub(ByRef Sender As QSTRINGGRID))
    SetEventEx(RqEvKeyDown, "OnKeyDown", Cast(Any Ptr, Handler), 3)
End Property
Property QSTRINGGRID.OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    SetEventEx(RqEvKeyUp, "OnKeyUp", Cast(Any Ptr, Handler), 1)
End Property
Property QSTRINGGRID.OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QSTRINGGRID))
    SetEventEx(RqEvKeyUp, "OnKeyUp", Cast(Any Ptr, Handler), 2)
End Property
Property QSTRINGGRID.OnKeyUp(ByVal Handler As Sub())
    SetEventEx(RqEvKeyUp, "OnKeyUp", Cast(Any Ptr, Handler), 0)
End Property
Property QSTRINGGRID.OnKeyUp(ByVal Handler As Sub(ByRef Sender As QSTRINGGRID))
    SetEventEx(RqEvKeyUp, "OnKeyUp", Cast(Any Ptr, Handler), 3)
End Property
Property QSTRINGGRID.OnKeyPress(ByVal Handler As Sub(ByRef Key As Long))
    SetEventEx(RqEvKeyPress, "OnKeyPress", Cast(Any Ptr, Handler), 1)
End Property
Property QSTRINGGRID.OnKeyPress(ByVal Handler As Sub(ByRef Key As Long, ByRef Sender As QSTRINGGRID))
    SetEventEx(RqEvKeyPress, "OnKeyPress", Cast(Any Ptr, Handler), 2)
End Property
Property QSTRINGGRID.OnKeyPress(ByVal Handler As Sub())
    SetEventEx(RqEvKeyPress, "OnKeyPress", Cast(Any Ptr, Handler), 0)
End Property
Property QSTRINGGRID.OnKeyPress(ByVal Handler As Sub(ByRef Sender As QSTRINGGRID))
    SetEventEx(RqEvKeyPress, "OnKeyPress", Cast(Any Ptr, Handler), 3)
End Property
Property QSTRINGGRID.OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 1)
End Property
Property QSTRINGGRID.OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QSTRINGGRID))
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 2)
End Property
Property QSTRINGGRID.OnMouseDown(ByVal Handler As Sub())
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 0)
End Property
Property QSTRINGGRID.OnMouseDown(ByVal Handler As Sub(ByRef Sender As QSTRINGGRID))
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 3)
End Property
Property QSTRINGGRID.OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 1)
End Property
Property QSTRINGGRID.OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QSTRINGGRID))
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 2)
End Property
Property QSTRINGGRID.OnMouseUp(ByVal Handler As Sub())
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 0)
End Property
Property QSTRINGGRID.OnMouseUp(ByVal Handler As Sub(ByRef Sender As QSTRINGGRID))
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 3)
End Property
Property QSTRINGGRID.OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 1)
End Property
Property QSTRINGGRID.OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QSTRINGGRID))
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 2)
End Property
Property QSTRINGGRID.OnMouseMove(ByVal Handler As Sub())
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 0)
End Property
Property QSTRINGGRID.OnMouseMove(ByVal Handler As Sub(ByRef Sender As QSTRINGGRID))
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 3)
End Property
Property QSTRINGGRID.OnSelectCell(ByVal Handler As Sub(ByVal Col As Long, ByVal Row As Long, ByRef CanSelect As Long))
    SetEventEx(RqEvSelectCell, "OnSelectCell", Cast(Any Ptr, Handler), 1)
End Property
Property QSTRINGGRID.OnSelectCell(ByVal Handler As Sub(ByVal Col As Long, ByVal Row As Long, ByRef CanSelect As Long, ByRef Sender As QSTRINGGRID))
    SetEventEx(RqEvSelectCell, "OnSelectCell", Cast(Any Ptr, Handler), 2)
End Property
Property QSTRINGGRID.OnSelectCell(ByVal Handler As Sub())
    SetEventEx(RqEvSelectCell, "OnSelectCell", Cast(Any Ptr, Handler), 0)
End Property
Property QSTRINGGRID.OnSelectCell(ByVal Handler As Sub(ByRef Sender As QSTRINGGRID))
    SetEventEx(RqEvSelectCell, "OnSelectCell", Cast(Any Ptr, Handler), 3)
End Property
Property QSTRINGGRID.OnDrawCell(ByVal Handler As Sub(ByVal Col As Long, ByVal Row As Long, ByVal State As Long, ByRef R As QRECT))
    SetEventEx(RqEvDrawCell, "OnDrawCell", Cast(Any Ptr, Handler), 1)
End Property
Property QSTRINGGRID.OnDrawCell(ByVal Handler As Sub(ByVal Col As Long, ByVal Row As Long, ByVal State As Long, ByRef R As QRECT, ByRef Sender As QSTRINGGRID))
    SetEventEx(RqEvDrawCell, "OnDrawCell", Cast(Any Ptr, Handler), 2)
End Property
Property QSTRINGGRID.OnDrawCell(ByVal Handler As Sub())
    SetEventEx(RqEvDrawCell, "OnDrawCell", Cast(Any Ptr, Handler), 0)
End Property
Property QSTRINGGRID.OnDrawCell(ByVal Handler As Sub(ByRef Sender As QSTRINGGRID))
    SetEventEx(RqEvDrawCell, "OnDrawCell", Cast(Any Ptr, Handler), 3)
End Property
Property QSTRINGGRID.OnSetEditText(ByVal Handler As Sub(ByVal Col As Long, ByVal Row As Long, ByVal Value As String))
    SetEventEx(RqEvSetEditText, "OnSetEditText", Cast(Any Ptr, Handler), 1)
End Property
Property QSTRINGGRID.OnSetEditText(ByVal Handler As Sub(ByVal Col As Long, ByVal Row As Long, ByVal Value As String, ByRef Sender As QSTRINGGRID))
    SetEventEx(RqEvSetEditText, "OnSetEditText", Cast(Any Ptr, Handler), 2)
End Property
Property QSTRINGGRID.OnSetEditText(ByVal Handler As Sub())
    SetEventEx(RqEvSetEditText, "OnSetEditText", Cast(Any Ptr, Handler), 0)
End Property
Property QSTRINGGRID.OnSetEditText(ByVal Handler As Sub(ByRef Sender As QSTRINGGRID))
    SetEventEx(RqEvSetEditText, "OnSetEditText", Cast(Any Ptr, Handler), 3)
End Property

Function QSTRINGGRID.Cell(ByVal ColIdx As Long, ByVal RowIdx As Long) As String
    Dim TextLen As Long
    Dim TextValue As String
    TextLen = RqGetCell(RqObj, ColIdx, RowIdx, 0, 0)
    If TextLen < 0 Then
        RqLclClassError("QSTRINGGRID.Cell")
        Return ""
    End If
    If TextLen = 0 Then Return ""
    TextValue = Space(TextLen)
    RqGetCell(RqObj, ColIdx, RowIdx, StrPtr(TextValue), TextLen + 1)
    Return TextValue
End Function

Sub QSTRINGGRID.SetCell(ByVal ColIdx As Long, ByVal RowIdx As Long, ByRef Value As String)
    If RqSetCell(RqObj, ColIdx, RowIdx, StrPtr(Value)) = 0 Then RqLclClassError("QSTRINGGRID.Cell")
End Sub

Property QSTRINGGRID.ColWidths(ByVal ColIdx As Long) As Long
    Return RqGetItemInt(RqObj, "ColWidths", ColIdx)
End Property
Property QSTRINGGRID.ColWidths(ByVal ColIdx As Long, ByVal Value As Long)
    If RqSetItemInt(RqObj, "ColWidths", ColIdx, Value) = 0 Then RqLclClassError("QSTRINGGRID.ColWidths")
End Property
Property QSTRINGGRID.RowHeights(ByVal RowIdx As Long) As Long
    Return RqGetItemInt(RqObj, "RowHeights", RowIdx)
End Property
Property QSTRINGGRID.RowHeights(ByVal RowIdx As Long, ByVal Value As Long)
    If RqSetItemInt(RqObj, "RowHeights", RowIdx, Value) = 0 Then RqLclClassError("QSTRINGGRID.RowHeights")
End Property
Property QSTRINGGRID.Align() As Long
    Return RqGetInt(RqObj, "Align")
End Property
Property QSTRINGGRID.Align(ByVal Value As Long)
    RqLclSetInt(RqObj, "Align", Value)
End Property
Property QSTRINGGRID.BorderStyle() As Long
    Return RqGetInt(RqObj, "BorderStyle")
End Property
Property QSTRINGGRID.BorderStyle(ByVal Value As Long)
    RqLclSetInt(RqObj, "BorderStyle", Value)
End Property
Property QSTRINGGRID.Col() As Long
    Return RqGetInt(RqObj, "Col")
End Property
Property QSTRINGGRID.Col(ByVal Value As Long)
    RqLclSetInt(RqObj, "Col", Value)
End Property
Property QSTRINGGRID.ColCount() As Long
    Return RqGetInt(RqObj, "ColCount")
End Property
Property QSTRINGGRID.ColCount(ByVal Value As Long)
    RqLclSetInt(RqObj, "ColCount", Value)
End Property
Property QSTRINGGRID.DefaultColWidth() As Long
    Return RqGetInt(RqObj, "DefaultColWidth")
End Property
Property QSTRINGGRID.DefaultColWidth(ByVal Value As Long)
    RqLclSetInt(RqObj, "DefaultColWidth", Value)
End Property
Property QSTRINGGRID.DefaultRowHeight() As Long
    Return RqGetInt(RqObj, "DefaultRowHeight")
End Property
Property QSTRINGGRID.DefaultRowHeight(ByVal Value As Long)
    RqLclSetInt(RqObj, "DefaultRowHeight", Value)
End Property
Property QSTRINGGRID.EditorMode() As Long
    Return RqGetInt(RqObj, "EditorMode")
End Property
Property QSTRINGGRID.EditorMode(ByVal Value As Long)
    RqLclSetInt(RqObj, "EditorMode", Value)
End Property
Property QSTRINGGRID.FixedColor() As Long
    Return RqGetInt(RqObj, "FixedColor")
End Property
Property QSTRINGGRID.FixedColor(ByVal Value As Long)
    RqLclSetInt(RqObj, "FixedColor", Value)
End Property
Property QSTRINGGRID.FixedCols() As Long
    Return RqGetInt(RqObj, "FixedCols")
End Property
Property QSTRINGGRID.FixedCols(ByVal Value As Long)
    RqLclSetInt(RqObj, "FixedCols", Value)
End Property
Property QSTRINGGRID.FixedRows() As Long
    Return RqGetInt(RqObj, "FixedRows")
End Property
Property QSTRINGGRID.FixedRows(ByVal Value As Long)
    RqLclSetInt(RqObj, "FixedRows", Value)
End Property
Property QSTRINGGRID.GridHeight() As Long
    Return RqGetInt(RqObj, "GridHeight")
End Property
Property QSTRINGGRID.GridLineWidth() As Long
    Return RqGetInt(RqObj, "GridLineWidth")
End Property
Property QSTRINGGRID.GridLineWidth(ByVal Value As Long)
    RqLclSetInt(RqObj, "GridLineWidth", Value)
End Property
Property QSTRINGGRID.GridWidth() As Long
    Return RqGetInt(RqObj, "GridWidth")
End Property
Property QSTRINGGRID.LeftCol() As Long
    Return RqGetInt(RqObj, "LeftCol")
End Property
Property QSTRINGGRID.LeftCol(ByVal Value As Long)
    RqLclSetInt(RqObj, "LeftCol", Value)
End Property
Property QSTRINGGRID.Row() As Long
    Return RqGetInt(RqObj, "Row")
End Property
Property QSTRINGGRID.Row(ByVal Value As Long)
    RqLclSetInt(RqObj, "Row", Value)
End Property
Property QSTRINGGRID.RowCount() As Long
    Return RqGetInt(RqObj, "RowCount")
End Property
Property QSTRINGGRID.RowCount(ByVal Value As Long)
    RqLclSetInt(RqObj, "RowCount", Value)
End Property
Property QSTRINGGRID.ScrollBars() As Long
    Return RqGetInt(RqObj, "ScrollBars")
End Property
Property QSTRINGGRID.ScrollBars(ByVal Value As Long)
    RqLclSetInt(RqObj, "ScrollBars", Value)
End Property
Property QSTRINGGRID.TabOrder() As Long
    Return RqGetInt(RqObj, "TabOrder")
End Property
Property QSTRINGGRID.TabOrder(ByVal Value As Long)
    RqLclSetInt(RqObj, "TabOrder", Value)
End Property
Property QSTRINGGRID.Tag() As Long
    Return RqGetInt(RqObj, "Tag")
End Property
Property QSTRINGGRID.Tag(ByVal Value As Long)
    RqLclSetInt(RqObj, "Tag", Value)
End Property
Property QSTRINGGRID.TopRow() As Long
    Return RqGetInt(RqObj, "TopRow")
End Property
Property QSTRINGGRID.TopRow(ByVal Value As Long)
    RqLclSetInt(RqObj, "TopRow", Value)
End Property
Property QSTRINGGRID.VisibleColCount() As Long
    Return RqGetInt(RqObj, "VisibleColCount")
End Property
Property QSTRINGGRID.VisibleRowCount() As Long
    Return RqGetInt(RqObj, "VisibleRowCount")
End Property
' Разделитель ячеек в LoadFromFile / SaveToFile (по умолчанию - Tab)
Property QSTRINGGRID.Separator() As String
    Return RqLclGetStr(RqObj, "Separator")
End Property
Property QSTRINGGRID.Separator(ByRef Value As String)
    RqLclSetStr(RqObj, "Separator", Value)
End Property

Sub QSTRINGGRID.CallInts(ByRef MethodName As String, ByVal IntArg1 As Long, _
        ByVal IntArg2 As Long = 0)
    If RqCallEx(RqObj, MethodName, 0, IntArg1, IntArg2, 0, 0, 0) = 0 Then
        RqLclClassError("QSTRINGGRID." & MethodName)
    End If
End Sub

Sub QSTRINGGRID.OptionList(ByRef MethodName As String, ByVal Option1 As Long, _
        ByVal Option2 As Long, ByVal Option3 As Long, ByVal Option4 As Long, _
        ByVal Option5 As Long, ByVal Option6 As Long)
    Dim OptionArr(1 To 6) As Long = {Option1, Option2, Option3, Option4, Option5, Option6}
    For ArgIdx As Long = 1 To 6
        If (ArgIdx > 1) AndAlso (OptionArr(ArgIdx) = -1) Then Exit For
        CallInts(MethodName, OptionArr(ArgIdx))
    Next
End Sub

' goFixedVertLine 0 ... goThumbTracking 14, до шести за вызов
Sub QSTRINGGRID.AddOptions(ByVal Option1 As Long, ByVal Option2 As Long = -1, _
        ByVal Option3 As Long = -1, ByVal Option4 As Long = -1, _
        ByVal Option5 As Long = -1, ByVal Option6 As Long = -1)
    OptionList("AddOptions", Option1, Option2, Option3, Option4, Option5, Option6)
End Sub
Sub QSTRINGGRID.DelOptions(ByVal Option1 As Long, ByVal Option2 As Long = -1, _
        ByVal Option3 As Long = -1, ByVal Option4 As Long = -1, _
        ByVal Option5 As Long = -1, ByVal Option6 As Long = -1)
    OptionList("DelOptions", Option1, Option2, Option3, Option4, Option5, Option6)
End Sub
Sub QSTRINGGRID.DeleteCol(ByVal ColIdx As Long)
    CallInts("DeleteCol", ColIdx)
End Sub
Sub QSTRINGGRID.DeleteRow(ByVal RowIdx As Long)
    CallInts("DeleteRow", RowIdx)
End Sub
Sub QSTRINGGRID.InsertCol(ByVal ColIdx As Long)
    CallInts("InsertCol", ColIdx)
End Sub
Sub QSTRINGGRID.InsertRow(ByVal RowIdx As Long)
    CallInts("InsertRow", RowIdx)
End Sub
Sub QSTRINGGRID.SwapCols(ByVal Col1 As Long, ByVal Col2 As Long)
    CallInts("SwapCols", Col1, Col2)
End Sub
Sub QSTRINGGRID.SwapRows(ByVal Row1 As Long, ByVal Row2 As Long)
    CallInts("SwapRows", Row1, Row2)
End Sub

' Строка файла - строка таблицы с RowOffset, ячейки через Separator - с
' ColOffset; MaxRows - не больше строк (0 - все). RowCount = RowOffset +
' число строк файла.
Sub QSTRINGGRID.LoadFromFile(ByRef FileName As String, ByVal RowOffset As Long = 0, _
        ByVal ColOffset As Long = 0, ByVal MaxRows As Long = 0)
    If RqCallEx(RqObj, "LoadFromFile", StrPtr(FileName), RowOffset, ColOffset, MaxRows, 0, 0) = 0 Then
        RqLclClassError("QSTRINGGRID.LoadFromFile")
    End If
End Sub
Sub QSTRINGGRID.SaveToFile(ByRef FileName As String, ByVal RowOffset As Long = 0, _
        ByVal ColOffset As Long = 0, ByVal MaxRows As Long = 0)
    If RqCallEx(RqObj, "SaveToFile", StrPtr(FileName), RowOffset, ColOffset, MaxRows, 0, 0) = 0 Then
        RqLclClassError("QSTRINGGRID.SaveToFile")
    End If
End Sub
' Из потока - от текущей позиции до конца
Sub QSTRINGGRID.LoadFromStream(ByRef Stream As RqStream, ByVal RowOffset As Long = 0, _
        ByVal ColOffset As Long = 0, ByVal MaxRows As Long = 0)
    Dim DataLen As Long = Stream.Size - Stream.Position
    Dim StreamText As String
    If DataLen > 0 Then
        StreamText = Space(DataLen)
        DataLen = Stream.ReadBuf(StrPtr(StreamText), DataLen)
        StreamText = Mid(StreamText, 1, DataLen)
    End If
    If RqCallEx(RqObj, "LoadFromText", StrPtr(StreamText), RowOffset, ColOffset, MaxRows, 0, 0) = 0 Then
        RqLclClassError("QSTRINGGRID.LoadFromStream")
    End If
End Sub
Sub QSTRINGGRID.SaveToStream(ByRef Stream As RqStream, ByVal RowOffset As Long = 0, _
        ByVal ColOffset As Long = 0, ByVal MaxRows As Long = 0)
    Dim TextLen As Long = RqCallEx(RqObj, "SaveToText", 0, RowOffset, ColOffset, MaxRows, 0, 0)
    If TextLen < 0 Then
        RqLclClassError("QSTRINGGRID.SaveToStream")
        Exit Sub
    End If
    If TextLen = 0 Then Exit Sub
    Dim StreamText As String = Space(TextLen)
    RqCallEx(RqObj, "SaveToText", 0, RowOffset, ColOffset, MaxRows, StrPtr(StreamText), TextLen + 1)
    Stream.WriteBuf(StrPtr(StreamText), TextLen)
End Sub
Function QSTRINGGRID.TextWidth(ByRef Text1 As String) As Long
    Return RqCallEx(RqObj, "TextWidth", StrPtr(Text1), 0, 0, 0, 0, 0)
End Function
Function QSTRINGGRID.TextHeight(ByRef Text1 As String) As Long
    Return RqCallEx(RqObj, "TextHeight", StrPtr(Text1), 0, 0, 0, 0, 0)
End Function

' Рисование на таблице - обычно в OnDrawCell; координаты - в окне таблицы
' (прямоугольник ячейки - параметр R / Rect обработчика)
Sub QSTRINGGRID.DrawInts(ByRef MethodName As String, ByRef Text1 As String, _
        IntList() As Long)
    If RqCallInts(RqObj, MethodName, StrPtr(Text1), @IntList(0), UBound(IntList) + 1) = 0 Then
        RqLclClassError("QSTRINGGRID." & MethodName)
    End If
End Sub
Sub QSTRINGGRID.FillRect(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, _
        ByVal Y2 As Long, ByVal FillColor As Long)
    Dim IntList(0 To 4) As Long = {X1, Y1, X2, Y2, FillColor}
    DrawInts("FillRect", "", IntList())
End Sub
' BackColor = -1 - фон прозрачный
Sub QSTRINGGRID.TextOut(ByVal X1 As Long, ByVal Y1 As Long, ByRef Text1 As String, _
        ByVal TextColor As Long, ByVal BackColor As Long = -1)
    Dim IntList(0 To 3) As Long = {X1, Y1, TextColor, BackColor}
    DrawInts("TextOut", Text1, IntList())
End Sub
Sub QSTRINGGRID.Line(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, _
        ByVal Y2 As Long, ByVal LineColor As Long)
    Dim IntList(0 To 4) As Long = {X1, Y1, X2, Y2, LineColor}
    DrawInts("Line", "", IntList())
End Sub
Sub QSTRINGGRID.Rectangle(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, _
        ByVal Y2 As Long, ByVal LineColor As Long)
    Dim IntList(0 To 4) As Long = {X1, Y1, X2, Y2, LineColor}
    DrawInts("Rectangle", "", IntList())
End Sub
Sub QSTRINGGRID.RoundRect(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, _
        ByVal Y2 As Long, ByVal X3 As Long, ByVal Y3 As Long, ByVal FillColor As Long)
    Dim IntList(0 To 6) As Long = {X1, Y1, X2, Y2, X3, Y3, FillColor}
    DrawInts("RoundRect", "", IntList())
End Sub
Sub QSTRINGGRID.Circle(ByVal X1 As Long, ByVal Y1 As Long, ByVal X2 As Long, _
        ByVal Y2 As Long, ByVal LineColor As Long, ByVal FillFlag As Long)
    Dim IntList(0 To 5) As Long = {X1, Y1, X2, Y2, LineColor, FillFlag}
    DrawInts("Circle", "", IntList())
End Sub
Sub QSTRINGGRID.Pset(ByVal X1 As Long, ByVal Y1 As Long, ByVal PixelColor As Long)
    Dim IntList(0 To 2) As Long = {X1, Y1, PixelColor}
    DrawInts("Pset", "", IntList())
End Sub
Sub QSTRINGGRID.Paint(ByVal X1 As Long, ByVal Y1 As Long, ByVal FillColor As Long, _
        ByVal BorderColor As Long)
    Dim IntList(0 To 3) As Long = {X1, Y1, FillColor, BorderColor}
    DrawInts("Paint", "", IntList())
End Sub

' ---------------------------------------------------------------------------
'  QDIRTREE - дерево папок (TShellTreeView LCL)
'  Directory - выбранная папка, без "\" в конце (кроме корня диска).
'  FastLoad, ReadOnStart, AddDriveTypes / DelDriveTypes - запоминаются, на
'  дерево не влияют (LCL читает папки по мере раскрытия и показывает все
'  диски).
' ---------------------------------------------------------------------------

Type QDIRTREE Extends QCONTROL
    OnChangeProc As Sub(ByRef Sender As QDIRTREE)
    OnChangeProcPlain As Sub()
    Declare Constructor()
    Declare Property Directory() As String
    Declare Property Directory(ByRef Value As String)
    Declare Property InitialDir() As String
    Declare Property InitialDir(ByRef Value As String)
    Declare Property Align() As Long
    Declare Property Align(ByVal Value As Long)
    Declare Property BorderStyle() As Long
    Declare Property BorderStyle(ByVal Value As Long)
    Declare Property FastLoad() As Long
    Declare Property FastLoad(ByVal Value As Long)
    Declare Property HideSelection() As Long
    Declare Property HideSelection(ByVal Value As Long)
    Declare Property ReadOnly() As Long
    Declare Property ReadOnly(ByVal Value As Long)
    Declare Property ReadOnStart() As Long
    Declare Property ReadOnStart(ByVal Value As Long)
    Declare Property TabOrder() As Long
    Declare Property TabOrder(ByVal Value As Long)
    Declare Property Tag() As Long
    Declare Property Tag(ByVal Value As Long)
    Declare Property OnChange(ByVal Handler As Sub(ByRef Sender As QDIRTREE))
    Declare Property OnChange(ByVal Handler As Sub())
    Declare Sub AddDirTypes(ByVal DirType As Long)
    Declare Sub DelDirTypes(ByVal DirType As Long)
    Declare Sub AddDriveTypes(ByVal DriveType As Long)
    Declare Sub DelDriveTypes(ByVal DriveType As Long)
    Declare Sub FullCollapse()
    Declare Sub FullExpand()
    Declare Sub Reload()
    Declare Sub CallInt1(ByRef MethodName As String, ByVal IntArg1 As Long)
    Declare Property OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    Declare Property OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QDIRTREE))
    Declare Property OnKeyDown(ByVal Handler As Sub())
    Declare Property OnKeyDown(ByVal Handler As Sub(ByRef Sender As QDIRTREE))
    Declare Property OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    Declare Property OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QDIRTREE))
    Declare Property OnKeyUp(ByVal Handler As Sub())
    Declare Property OnKeyUp(ByVal Handler As Sub(ByRef Sender As QDIRTREE))
    Declare Property OnKeyPress(ByVal Handler As Sub(ByRef Key As Long))
    Declare Property OnKeyPress(ByVal Handler As Sub(ByRef Key As Long, ByRef Sender As QDIRTREE))
    Declare Property OnKeyPress(ByVal Handler As Sub())
    Declare Property OnKeyPress(ByVal Handler As Sub(ByRef Sender As QDIRTREE))
    Declare Property OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QDIRTREE))
    Declare Property OnMouseDown(ByVal Handler As Sub())
    Declare Property OnMouseDown(ByVal Handler As Sub(ByRef Sender As QDIRTREE))
    Declare Property OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QDIRTREE))
    Declare Property OnMouseUp(ByVal Handler As Sub())
    Declare Property OnMouseUp(ByVal Handler As Sub(ByRef Sender As QDIRTREE))
    Declare Property OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    Declare Property OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QDIRTREE))
    Declare Property OnMouseMove(ByVal Handler As Sub())
    Declare Property OnMouseMove(ByVal Handler As Sub(ByRef Sender As QDIRTREE))
End Type

Private Sub QDIRTREE_ChangeEvent stdcall (ByVal UserPtr As Any Ptr, ByVal ObjPtr As Any Ptr)
    Dim TreePtr As QDIRTREE Ptr = UserPtr
    If TreePtr->OnChangeProc <> 0 Then TreePtr->OnChangeProc(*TreePtr)
    If TreePtr->OnChangeProcPlain <> 0 Then TreePtr->OnChangeProcPlain()
End Sub

Constructor QDIRTREE()
    RqObj = RqLclNew("QDIRTREE", @This)
End Constructor

' События с параметрами QDIRTREE: обработчик с параметрами, с ними и Sender
' последним, только с Sender или без параметров
Property QDIRTREE.OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    SetEventEx(RqEvKeyDown, "OnKeyDown", Cast(Any Ptr, Handler), 1)
End Property
Property QDIRTREE.OnKeyDown(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QDIRTREE))
    SetEventEx(RqEvKeyDown, "OnKeyDown", Cast(Any Ptr, Handler), 2)
End Property
Property QDIRTREE.OnKeyDown(ByVal Handler As Sub())
    SetEventEx(RqEvKeyDown, "OnKeyDown", Cast(Any Ptr, Handler), 0)
End Property
Property QDIRTREE.OnKeyDown(ByVal Handler As Sub(ByRef Sender As QDIRTREE))
    SetEventEx(RqEvKeyDown, "OnKeyDown", Cast(Any Ptr, Handler), 3)
End Property
Property QDIRTREE.OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long))
    SetEventEx(RqEvKeyUp, "OnKeyUp", Cast(Any Ptr, Handler), 1)
End Property
Property QDIRTREE.OnKeyUp(ByVal Handler As Sub(ByRef Key As Long, ByVal Shift As Long, ByRef Sender As QDIRTREE))
    SetEventEx(RqEvKeyUp, "OnKeyUp", Cast(Any Ptr, Handler), 2)
End Property
Property QDIRTREE.OnKeyUp(ByVal Handler As Sub())
    SetEventEx(RqEvKeyUp, "OnKeyUp", Cast(Any Ptr, Handler), 0)
End Property
Property QDIRTREE.OnKeyUp(ByVal Handler As Sub(ByRef Sender As QDIRTREE))
    SetEventEx(RqEvKeyUp, "OnKeyUp", Cast(Any Ptr, Handler), 3)
End Property
Property QDIRTREE.OnKeyPress(ByVal Handler As Sub(ByRef Key As Long))
    SetEventEx(RqEvKeyPress, "OnKeyPress", Cast(Any Ptr, Handler), 1)
End Property
Property QDIRTREE.OnKeyPress(ByVal Handler As Sub(ByRef Key As Long, ByRef Sender As QDIRTREE))
    SetEventEx(RqEvKeyPress, "OnKeyPress", Cast(Any Ptr, Handler), 2)
End Property
Property QDIRTREE.OnKeyPress(ByVal Handler As Sub())
    SetEventEx(RqEvKeyPress, "OnKeyPress", Cast(Any Ptr, Handler), 0)
End Property
Property QDIRTREE.OnKeyPress(ByVal Handler As Sub(ByRef Sender As QDIRTREE))
    SetEventEx(RqEvKeyPress, "OnKeyPress", Cast(Any Ptr, Handler), 3)
End Property
Property QDIRTREE.OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 1)
End Property
Property QDIRTREE.OnMouseDown(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QDIRTREE))
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 2)
End Property
Property QDIRTREE.OnMouseDown(ByVal Handler As Sub())
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 0)
End Property
Property QDIRTREE.OnMouseDown(ByVal Handler As Sub(ByRef Sender As QDIRTREE))
    SetEventEx(RqEvMouseDown, "OnMouseDown", Cast(Any Ptr, Handler), 3)
End Property
Property QDIRTREE.OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 1)
End Property
Property QDIRTREE.OnMouseUp(ByVal Handler As Sub(ByVal Button As Long, ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QDIRTREE))
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 2)
End Property
Property QDIRTREE.OnMouseUp(ByVal Handler As Sub())
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 0)
End Property
Property QDIRTREE.OnMouseUp(ByVal Handler As Sub(ByRef Sender As QDIRTREE))
    SetEventEx(RqEvMouseUp, "OnMouseUp", Cast(Any Ptr, Handler), 3)
End Property
Property QDIRTREE.OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long))
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 1)
End Property
Property QDIRTREE.OnMouseMove(ByVal Handler As Sub(ByVal X As Long, ByVal Y As Long, ByVal Shift As Long, ByRef Sender As QDIRTREE))
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 2)
End Property
Property QDIRTREE.OnMouseMove(ByVal Handler As Sub())
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 0)
End Property
Property QDIRTREE.OnMouseMove(ByVal Handler As Sub(ByRef Sender As QDIRTREE))
    SetEventEx(RqEvMouseMove, "OnMouseMove", Cast(Any Ptr, Handler), 3)
End Property
Property QDIRTREE.Directory() As String
    Return RqLclGetStr(RqObj, "Directory")
End Property
Property QDIRTREE.Directory(ByRef Value As String)
    RqLclSetStr(RqObj, "Directory", Value)
End Property
Property QDIRTREE.InitialDir() As String
    Return RqLclGetStr(RqObj, "InitialDir")
End Property
Property QDIRTREE.InitialDir(ByRef Value As String)
    RqLclSetStr(RqObj, "InitialDir", Value)
End Property
Property QDIRTREE.Align() As Long
    Return RqGetInt(RqObj, "Align")
End Property
Property QDIRTREE.Align(ByVal Value As Long)
    RqLclSetInt(RqObj, "Align", Value)
End Property
Property QDIRTREE.BorderStyle() As Long
    Return RqGetInt(RqObj, "BorderStyle")
End Property
Property QDIRTREE.BorderStyle(ByVal Value As Long)
    RqLclSetInt(RqObj, "BorderStyle", Value)
End Property
Property QDIRTREE.FastLoad() As Long
    Return RqGetInt(RqObj, "FastLoad")
End Property
Property QDIRTREE.FastLoad(ByVal Value As Long)
    RqLclSetInt(RqObj, "FastLoad", Value)
End Property
Property QDIRTREE.HideSelection() As Long
    Return RqGetInt(RqObj, "HideSelection")
End Property
Property QDIRTREE.HideSelection(ByVal Value As Long)
    RqLclSetInt(RqObj, "HideSelection", Value)
End Property
Property QDIRTREE.ReadOnly() As Long
    Return RqGetInt(RqObj, "ReadOnly")
End Property
Property QDIRTREE.ReadOnly(ByVal Value As Long)
    RqLclSetInt(RqObj, "ReadOnly", Value)
End Property
Property QDIRTREE.ReadOnStart() As Long
    Return RqGetInt(RqObj, "ReadOnStart")
End Property
Property QDIRTREE.ReadOnStart(ByVal Value As Long)
    RqLclSetInt(RqObj, "ReadOnStart", Value)
End Property
Property QDIRTREE.TabOrder() As Long
    Return RqGetInt(RqObj, "TabOrder")
End Property
Property QDIRTREE.TabOrder(ByVal Value As Long)
    RqLclSetInt(RqObj, "TabOrder", Value)
End Property
Property QDIRTREE.Tag() As Long
    Return RqGetInt(RqObj, "Tag")
End Property
Property QDIRTREE.Tag(ByVal Value As Long)
    RqLclSetInt(RqObj, "Tag", Value)
End Property
Property QDIRTREE.OnChange(ByVal Handler As Sub(ByRef Sender As QDIRTREE))
    OnChangeProc = Handler
    OnChangeProcPlain = 0
    If RqSetEvent(RqObj, "OnChange", @QDIRTREE_ChangeEvent) = 0 Then RqLclShowError("OnChange")
End Property
' Обработчик без параметра Sender
Property QDIRTREE.OnChange(ByVal Handler As Sub())
    OnChangeProcPlain = Handler
    OnChangeProc = 0
    If RqSetEvent(RqObj, "OnChange", @QDIRTREE_ChangeEvent) = 0 Then RqLclShowError("OnChange")
End Property
Sub QDIRTREE.CallInt1(ByRef MethodName As String, ByVal IntArg1 As Long)
    If RqCallEx(RqObj, MethodName, 0, IntArg1, 0, 0, 0, 0) = 0 Then
        RqLclShowError(MethodName)
    End If
End Sub
' dtReadOnly 0, dtHidden 1, dtSystem 2, dtNormal 3, dtAll 4: 1, 2, 4 -
' показывать скрытые папки
Sub QDIRTREE.AddDirTypes(ByVal DirType As Long)
    CallInt1("AddDirTypes", DirType)
End Sub
Sub QDIRTREE.DelDirTypes(ByVal DirType As Long)
    CallInt1("DelDirTypes", DirType)
End Sub
Sub QDIRTREE.AddDriveTypes(ByVal DriveType As Long)
    CallInt1("AddDriveTypes", DriveType)
End Sub
Sub QDIRTREE.DelDriveTypes(ByVal DriveType As Long)
    CallInt1("DelDriveTypes", DriveType)
End Sub
Sub QDIRTREE.FullCollapse()
    CallInt1("FullCollapse", 0)
End Sub
' Медленно: читает все папки всех дисков
Sub QDIRTREE.FullExpand()
    CallInt1("FullExpand", 0)
End Sub
Sub QDIRTREE.Reload()
    CallInt1("Reload", 0)
End Sub
