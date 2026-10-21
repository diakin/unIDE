' ---------------------------------------------------------------------------
'  rqreg.bi - QREGISTRY RapidQ на FreeBASIC (без DLL), функции реестра
'  Windows из advapi32 (rapidq_ref/html_doc/qregistry.html). Поведение -
'  как у TRegistry Delphi, на котором сделан RapidQ:
'  - OpenKey("a\b") - от текущего ключа, OpenKey("\a\b") - от RootKey;
'  - ключ открывается на чтение и запись; в режиме Smart, если доступа на
'    запись нет (HKEY_LOCAL_MACHINE без прав администратора), - только на
'    чтение;
'  - ReadString у несуществующего значения - "", ReadInteger и ReadFloat -
'    ошибка (Smart: 0 и предупреждение);
'  - DeleteKey удаляет ключ вместе с подключами.
'  Функции, которые в RapidQ возвращают INTEGER-признак, возвращают 1 или 0.
' ---------------------------------------------------------------------------

#pragma once

#include once "rqrt.bi"

Declare Function RqRtRegOpenKeyEx Lib "advapi32" Alias "RegOpenKeyExA" ( _
    ByVal ParentKey As Any Ptr, ByVal SubKey As ZString Ptr, _
    ByVal Options As ULong, ByVal Access As ULong, _
    ByVal ResultKey As Any Ptr Ptr) As Long
Declare Function RqRtRegCreateKeyEx Lib "advapi32" Alias "RegCreateKeyExA" ( _
    ByVal ParentKey As Any Ptr, ByVal SubKey As ZString Ptr, _
    ByVal Reserved As ULong, ByVal ClassName As ZString Ptr, _
    ByVal Options As ULong, ByVal Access As ULong, _
    ByVal Security As Any Ptr, ByVal ResultKey As Any Ptr Ptr, _
    ByVal Disposition As ULong Ptr) As Long
Declare Function RqRtRegCloseKey Lib "advapi32" Alias "RegCloseKey" ( _
    ByVal KeyHandle As Any Ptr) As Long
Declare Function RqRtRegDeleteKey Lib "advapi32" Alias "RegDeleteKeyA" ( _
    ByVal ParentKey As Any Ptr, ByVal SubKey As ZString Ptr) As Long
Declare Function RqRtRegDeleteValue Lib "advapi32" Alias "RegDeleteValueA" ( _
    ByVal KeyHandle As Any Ptr, ByVal ValueName As ZString Ptr) As Long
Declare Function RqRtRegQueryValueEx Lib "advapi32" Alias "RegQueryValueExA" ( _
    ByVal KeyHandle As Any Ptr, ByVal ValueName As ZString Ptr, _
    ByVal Reserved As Any Ptr, ByVal ValueType As ULong Ptr, _
    ByVal DataBuf As Any Ptr, ByVal DataSize As ULong Ptr) As Long
Declare Function RqRtRegSetValueEx Lib "advapi32" Alias "RegSetValueExA" ( _
    ByVal KeyHandle As Any Ptr, ByVal ValueName As ZString Ptr, _
    ByVal Reserved As ULong, ByVal ValueType As ULong, _
    ByVal DataBuf As Any Ptr, ByVal DataSize As ULong) As Long
Declare Function RqRtRegEnumKeyEx Lib "advapi32" Alias "RegEnumKeyExA" ( _
    ByVal KeyHandle As Any Ptr, ByVal KeyIndex As ULong, _
    ByVal NameBuf As ZString Ptr, ByVal NameLen As ULong Ptr, _
    ByVal Reserved As Any Ptr, ByVal ClassBuf As ZString Ptr, _
    ByVal ClassLen As ULong Ptr, ByVal WriteTime As Any Ptr) As Long
Declare Function RqRtRegEnumValue Lib "advapi32" Alias "RegEnumValueA" ( _
    ByVal KeyHandle As Any Ptr, ByVal ValueIndex As ULong, _
    ByVal NameBuf As ZString Ptr, ByVal NameLen As ULong Ptr, _
    ByVal Reserved As Any Ptr, ByVal ValueType As ULong Ptr, _
    ByVal DataBuf As Any Ptr, ByVal DataSize As ULong Ptr) As Long
Declare Function RqRtRegQueryInfoKey Lib "advapi32" Alias "RegQueryInfoKeyA" ( _
    ByVal KeyHandle As Any Ptr, ByVal ClassBuf As ZString Ptr, _
    ByVal ClassLen As ULong Ptr, ByVal Reserved As Any Ptr, _
    ByVal SubKeyCount As ULong Ptr, ByVal MaxSubKeyLen As ULong Ptr, _
    ByVal MaxClassLen As ULong Ptr, ByVal ValueCount As ULong Ptr, _
    ByVal MaxValueNameLen As ULong Ptr, ByVal MaxValueLen As ULong Ptr, _
    ByVal SecurityLen As ULong Ptr, ByVal WriteTime As Any Ptr) As Long
Declare Function RqRtRegConnectRegistry Lib "advapi32" Alias "RegConnectRegistryA" ( _
    ByVal MachineName As ZString Ptr, ByVal RootHandle As Any Ptr, _
    ByVal ResultKey As Any Ptr Ptr) As Long

Const RqRtKeyRead = &h20019
Const RqRtKeyAllAccess = &hF003F
Const RqRtRegSz = 1
Const RqRtRegExpandSz = 2
Const RqRtRegBinary = 3
Const RqRtRegDword = 4

' Корневой ключ RapidQ (&H80000001 и т.д.) -> HKEY; в 64 битах - со знаком
Function RqRtRootHandle(ByVal RootValue As Long) As Any Ptr
    Return Cast(Any Ptr, CInt(RootValue))
End Function

' Удалить ключ с подключами (RegDeleteKey удаляет только пустой)
Function RqRtRegDeleteTree(ByVal ParentKey As Any Ptr, ByRef SubKey As String) As Long
    Dim KeyHandle As Any Ptr
    If RqRtRegOpenKeyEx(ParentKey, SubKey, 0, RqRtKeyAllAccess, @KeyHandle) <> 0 Then Return 0
    Dim NameBuf As ZString * 260
    Dim NameLen As ULong
    Do
        NameLen = 260
        ' всегда номер 0: удалённый подключ сдвигает остальные
        If RqRtRegEnumKeyEx(KeyHandle, 0, @NameBuf, @NameLen, 0, 0, 0, 0) <> 0 Then Exit Do
        If RqRtRegDeleteTree(KeyHandle, NameBuf) = 0 Then Exit Do
    Loop
    RqRtRegCloseKey(KeyHandle)
    Return IIf(RqRtRegDeleteKey(ParentKey, SubKey) = 0, 1, 0)
End Function

' Скопировать значения и подключи SourceKey в DestKey
Sub RqRtRegCopyTree(ByVal SourceKey As Any Ptr, ByVal DestKey As Any Ptr)
    Dim NameBuf As ZString * 16384
    Dim NameLen As ULong
    Dim ValueType As ULong
    Dim DataSize As ULong
    Dim ValueIdx As ULong = 0
    Do
        NameLen = 16384
        DataSize = 0
        If RqRtRegEnumValue(SourceKey, ValueIdx, @NameBuf, @NameLen, 0, @ValueType, 0, @DataSize) <> 0 Then Exit Do
        Dim DataBuf As String = Space(DataSize + 1)
        NameLen = 16384
        If RqRtRegEnumValue(SourceKey, ValueIdx, @NameBuf, @NameLen, 0, @ValueType, StrPtr(DataBuf), @DataSize) = 0 Then
            RqRtRegSetValueEx(DestKey, NameBuf, 0, ValueType, StrPtr(DataBuf), DataSize)
        End If
        ValueIdx += 1
    Loop
    Dim KeyIdx As ULong = 0
    Do
        NameLen = 260
        If RqRtRegEnumKeyEx(SourceKey, KeyIdx, @NameBuf, @NameLen, 0, 0, 0, 0) <> 0 Then Exit Do
        Dim ChildSource As Any Ptr
        Dim ChildDest As Any Ptr
        If RqRtRegOpenKeyEx(SourceKey, NameBuf, 0, RqRtKeyRead, @ChildSource) = 0 Then
            If RqRtRegCreateKeyEx(DestKey, NameBuf, 0, 0, 0, RqRtKeyAllAccess, 0, @ChildDest, 0) = 0 Then
                RqRtRegCopyTree(ChildSource, ChildDest)
                RqRtRegCloseKey(ChildDest)
            End If
            RqRtRegCloseKey(ChildSource)
        End If
        KeyIdx += 1
    Loop
End Sub

Type QREGISTRY
    RootValue As Long = -2147483647      ' &H80000001, HKEY_CURRENT_USER
    RootHandle As Any Ptr                ' после RegistryConnect - свой
    KeyHandle As Any Ptr
    KeyPath As String
    Declare Destructor()
    Declare Property RootKey() As Long
    Declare Property RootKey(ByVal Value As Long)
    Declare Property CurrentKey() As Integer
    Declare Property CurrentPath() As String
    Declare Property HasSubKeys() As Long
    Declare Property KeyItemCount() As Long
    Declare Property ValueItemCount() As Long
    Declare Function GetDataSize(ByRef ValueName As String = "") As Long
    Declare Function GetDataType(ByRef ValueName As String = "") As Long
    Declare Sub CloseKey()
    Declare Function CreateKey(ByRef KeyName As String) As Long
    Declare Function DeleteKey(ByRef KeyName As String) As Long
    Declare Function DeleteValue(ByRef ValueName As String) As Long
    Declare Function KeyExists(ByRef KeyName As String) As Long
    Declare Function KeyItem(ByVal ItemIndex As Long) As String
    Declare Function MoveKey(ByRef OldName As String, ByRef NewName As String, _
        ByVal DeleteOld As Long) As Long
    Declare Function OpenKey(ByRef KeyName As String, ByVal CanCreate As Long) As Long
    Declare Function ReadBinary(ByRef ValueName As String, ByVal ByteIndex As Long) As UByte
    Declare Function ReadFloat(ByRef ValueName As String) As Double
    Declare Function ReadInteger(ByRef ValueName As String) As Long
    Declare Function ReadString(ByRef ValueName As String) As String
    Declare Function RegistryConnect(ByRef ComputerName As String) As Long
    Declare Function RenameValue(ByRef OldName As String, ByRef NewName As String) As Long
    Declare Function ValueExists(ByRef ValueName As String) As Long
    Declare Function ValueItem(ByVal ItemIndex As Long) As String
    Declare Sub WriteBinary(ByRef ValueName As String, Buffer() As UByte, ByVal DataSize As Long)
    Declare Sub WriteFloat(ByRef ValueName As String, ByVal Value As Double)
    Declare Sub WriteInteger(ByRef ValueName As String, ByVal Value As Long)
    Declare Sub WriteString(ByRef ValueName As String, ByRef Value As String)
    ' служебное
    Declare Function BaseHandle(ByRef KeyName As String, ByRef SubPath As String) As Any Ptr
    Declare Function ReadRaw(ByRef ValueName As String, ByRef ValueType As ULong, _
        ByRef DataBuf As String) As Long
    Declare Sub WriteError(ByRef What As String, ByRef ValueName As String)
End Type

Destructor QREGISTRY()
    CloseKey()
End Destructor

' Ключ, от которого считать путь KeyName: "\..." - от корня, иначе от
' текущего. SubPath - путь без начального "\".
Function QREGISTRY.BaseHandle(ByRef KeyName As String, ByRef SubPath As String) As Any Ptr
    Dim RootPtr As Any Ptr = RootHandle
    If RootPtr = 0 Then RootPtr = RqRtRootHandle(RootValue)
    If Left(KeyName, 1) = "\" Then
        SubPath = Mid(KeyName, 2)
        Return RootPtr
    End If
    SubPath = KeyName
    If KeyHandle <> 0 Then Return KeyHandle
    Return RootPtr
End Function

Property QREGISTRY.RootKey() As Long
    Return RootValue
End Property

Property QREGISTRY.RootKey(ByVal Value As Long)
    CloseKey()
    If RootHandle <> 0 Then RqRtRegCloseKey(RootHandle)
    RootHandle = 0
    RootValue = Value
End Property

Property QREGISTRY.CurrentKey() As Integer
    Return CInt(KeyHandle)
End Property

Property QREGISTRY.CurrentPath() As String
    Return KeyPath
End Property

Property QREGISTRY.HasSubKeys() As Long
    Return IIf(KeyItemCount > 0, 1, 0)
End Property

Property QREGISTRY.KeyItemCount() As Long
    Dim SubKeyCount As ULong
    If KeyHandle = 0 Then Return 0
    If RqRtRegQueryInfoKey(KeyHandle, 0, 0, 0, @SubKeyCount, 0, 0, 0, 0, 0, 0, 0) <> 0 Then Return 0
    Return SubKeyCount
End Property

Property QREGISTRY.ValueItemCount() As Long
    Dim ValueCount As ULong
    If KeyHandle = 0 Then Return 0
    If RqRtRegQueryInfoKey(KeyHandle, 0, 0, 0, 0, 0, 0, @ValueCount, 0, 0, 0, 0) <> 0 Then Return 0
    Return ValueCount
End Property

' Размер данных значения; нет значения - -1
Function QREGISTRY.GetDataSize(ByRef ValueName As String = "") As Long
    Dim DataSize As ULong
    If RqRtRegQueryValueEx(KeyHandle, ValueName, 0, 0, 0, @DataSize) <> 0 Then Return -1
    Return DataSize
End Function

' Тип значения (REG_SZ 1, REG_BINARY 3, REG_DWORD 4...); нет значения - 0
Function QREGISTRY.GetDataType(ByRef ValueName As String = "") As Long
    Dim ValueType As ULong
    If RqRtRegQueryValueEx(KeyHandle, ValueName, 0, @ValueType, 0, 0) <> 0 Then Return 0
    Return ValueType
End Function

Sub QREGISTRY.CloseKey()
    If KeyHandle <> 0 Then RqRtRegCloseKey(KeyHandle)
    KeyHandle = 0
    KeyPath = ""
End Sub

Function QREGISTRY.CreateKey(ByRef KeyName As String) As Long
    Dim SubPath As String
    Dim ParentKey As Any Ptr = BaseHandle(KeyName, SubPath)
    Dim NewKey As Any Ptr
    If RqRtRegCreateKeyEx(ParentKey, SubPath, 0, 0, 0, RqRtKeyAllAccess, 0, @NewKey, 0) <> 0 Then Return 0
    RqRtRegCloseKey(NewKey)
    Return 1
End Function

Function QREGISTRY.DeleteKey(ByRef KeyName As String) As Long
    Dim SubPath As String
    Dim ParentKey As Any Ptr = BaseHandle(KeyName, SubPath)
    Return RqRtRegDeleteTree(ParentKey, SubPath)
End Function

Function QREGISTRY.DeleteValue(ByRef ValueName As String) As Long
    Return IIf(RqRtRegDeleteValue(KeyHandle, ValueName) = 0, 1, 0)
End Function

Function QREGISTRY.KeyExists(ByRef KeyName As String) As Long
    Dim SubPath As String
    Dim ParentKey As Any Ptr = BaseHandle(KeyName, SubPath)
    Dim TestKey As Any Ptr
    If RqRtRegOpenKeyEx(ParentKey, SubPath, 0, RqRtKeyRead, @TestKey) <> 0 Then Return 0
    RqRtRegCloseKey(TestKey)
    Return 1
End Function

' Имя подключа текущего ключа по номеру (с 0); нет - ""
Function QREGISTRY.KeyItem(ByVal ItemIndex As Long) As String
    Dim NameBuf As ZString * 260
    Dim NameLen As ULong = 260
    If KeyHandle = 0 Then Return ""
    If RqRtRegEnumKeyEx(KeyHandle, ItemIndex, @NameBuf, @NameLen, 0, 0, 0, 0) <> 0 Then Return ""
    Return NameBuf
End Function

' Копия ключа OldName со значениями и подключами под именем NewName;
' DeleteOld <> 0 - старый удаляется
Function QREGISTRY.MoveKey(ByRef OldName As String, ByRef NewName As String, _
        ByVal DeleteOld As Long) As Long
    Dim OldPath As String
    Dim NewPath As String
    Dim OldParent As Any Ptr = BaseHandle(OldName, OldPath)
    Dim NewParent As Any Ptr = BaseHandle(NewName, NewPath)
    Dim SourceKey As Any Ptr
    Dim DestKey As Any Ptr
    If RqRtRegOpenKeyEx(OldParent, OldPath, 0, RqRtKeyRead, @SourceKey) <> 0 Then Return 0
    If RqRtRegCreateKeyEx(NewParent, NewPath, 0, 0, 0, RqRtKeyAllAccess, 0, @DestKey, 0) <> 0 Then
        RqRtRegCloseKey(SourceKey)
        Return 0
    End If
    RqRtRegCopyTree(SourceKey, DestKey)
    RqRtRegCloseKey(DestKey)
    RqRtRegCloseKey(SourceKey)
    If DeleteOld Then RqRtRegDeleteTree(OldParent, OldPath)
    Return 1
End Function

Function QREGISTRY.OpenKey(ByRef KeyName As String, ByVal CanCreate As Long) As Long
    Dim SubPath As String
    Dim ParentKey As Any Ptr = BaseHandle(KeyName, SubPath)
    Dim NewKey As Any Ptr
    Dim OpenResult As Long
    If CanCreate Then
        OpenResult = RqRtRegCreateKeyEx(ParentKey, SubPath, 0, 0, 0, RqRtKeyAllAccess, 0, @NewKey, 0)
    Else
        OpenResult = RqRtRegOpenKeyEx(ParentKey, SubPath, 0, RqRtKeyAllAccess, @NewKey)
    End If
#ifndef RQ_COMPAT
    ' Нет прав на запись (ERROR_ACCESS_DENIED) - открыть на чтение
    If OpenResult = 5 Then
        OpenResult = RqRtRegOpenKeyEx(ParentKey, SubPath, 0, RqRtKeyRead, @NewKey)
    End If
#endif
    If OpenResult <> 0 Then Return 0
    Dim NewPath As String
    If (Left(KeyName, 1) <> "\") AndAlso (KeyPath <> "") Then
        NewPath = KeyPath & "\" & SubPath
    Else
        NewPath = SubPath
    End If
    CloseKey()
    KeyHandle = NewKey
    KeyPath = NewPath
    Return 1
End Function

' Значение целиком: 1 - есть
Function QREGISTRY.ReadRaw(ByRef ValueName As String, ByRef ValueType As ULong, _
        ByRef DataBuf As String) As Long
    Dim DataSize As ULong
    DataBuf = ""
    If RqRtRegQueryValueEx(KeyHandle, ValueName, 0, @ValueType, 0, @DataSize) <> 0 Then Return 0
    If DataSize = 0 Then Return 1
    DataBuf = Space(DataSize)
    If RqRtRegQueryValueEx(KeyHandle, ValueName, 0, @ValueType, StrPtr(DataBuf), @DataSize) <> 0 Then Return 0
    DataBuf = Mid(DataBuf, 1, DataSize)
    Return 1
End Function

' Байт номер ByteIndex (с 0) двоичного значения; нет - 0
Function QREGISTRY.ReadBinary(ByRef ValueName As String, ByVal ByteIndex As Long) As UByte
    Dim ValueType As ULong
    Dim DataBuf As String
    If ReadRaw(ValueName, ValueType, DataBuf) = 0 Then
        RqRtClassError("QREGISTRY.ReadBinary: Failed to get data for '" & ValueName & "'")
        Return 0
    End If
    If (ByteIndex < 0) OrElse (ByteIndex >= Len(DataBuf)) Then Return 0
    Return DataBuf[ByteIndex]
End Function

Function QREGISTRY.ReadFloat(ByRef ValueName As String) As Double
    Dim ValueType As ULong
    Dim DataBuf As String
    If (ReadRaw(ValueName, ValueType, DataBuf) = 0) OrElse (Len(DataBuf) <> 8) Then
        RqRtClassError("QREGISTRY.ReadFloat: Invalid data type for '" & ValueName & "'")
        Return 0
    End If
    Return *Cast(Double Ptr, StrPtr(DataBuf))
End Function

Function QREGISTRY.ReadInteger(ByRef ValueName As String) As Long
    Dim ValueType As ULong
    Dim DataBuf As String
    If ReadRaw(ValueName, ValueType, DataBuf) = 0 Then
        RqRtClassError("QREGISTRY.ReadInteger: Failed to get data for '" & ValueName & "'")
        Return 0
    End If
    If (ValueType <> RqRtRegDword) OrElse (Len(DataBuf) < 4) Then
        RqRtClassError("QREGISTRY.ReadInteger: Invalid data type for '" & ValueName & "'")
        Return 0
    End If
    Return *Cast(Long Ptr, StrPtr(DataBuf))
End Function

' Строковое значение; нет значения - ""
Function QREGISTRY.ReadString(ByRef ValueName As String) As String
    Dim ValueType As ULong
    Dim DataBuf As String
    If ReadRaw(ValueName, ValueType, DataBuf) = 0 Then Return ""
    If Len(DataBuf) = 0 Then Return ""
    If (ValueType <> RqRtRegSz) AndAlso (ValueType <> RqRtRegExpandSz) Then
        RqRtClassError("QREGISTRY.ReadString: Invalid data type for '" & ValueName & "'")
        Return ""
    End If
    ' до первого нуля
    Dim ZeroPos As Long = InStr(DataBuf, Chr(0))
    If ZeroPos > 0 Then DataBuf = Mid(DataBuf, 1, ZeroPos - 1)
    Return DataBuf
End Function

Function QREGISTRY.RegistryConnect(ByRef ComputerName As String) As Long
    Dim RemoteRoot As Any Ptr
    If RqRtRegConnectRegistry(ComputerName, RqRtRootHandle(RootValue), @RemoteRoot) <> 0 Then Return 0
    CloseKey()
    If RootHandle <> 0 Then RqRtRegCloseKey(RootHandle)
    RootHandle = RemoteRoot
    Return 1
End Function

Function QREGISTRY.RenameValue(ByRef OldName As String, ByRef NewName As String) As Long
    Dim ValueType As ULong
    Dim DataBuf As String
    If ReadRaw(OldName, ValueType, DataBuf) = 0 Then Return 0
    If RqRtRegSetValueEx(KeyHandle, NewName, 0, ValueType, StrPtr(DataBuf), Len(DataBuf)) <> 0 Then Return 0
    RqRtRegDeleteValue(KeyHandle, OldName)
    Return 1
End Function

Function QREGISTRY.ValueExists(ByRef ValueName As String) As Long
    Return IIf(RqRtRegQueryValueEx(KeyHandle, ValueName, 0, 0, 0, 0) = 0, 1, 0)
End Function

Function QREGISTRY.ValueItem(ByVal ItemIndex As Long) As String
    Dim NameBuf As ZString * 16384
    Dim NameLen As ULong = 16384
    If KeyHandle = 0 Then Return ""
    If RqRtRegEnumValue(KeyHandle, ItemIndex, @NameBuf, @NameLen, 0, 0, 0, 0) <> 0 Then Return ""
    Return NameBuf
End Function

Sub QREGISTRY.WriteError(ByRef What As String, ByRef ValueName As String)
    RqRtClassError("QREGISTRY." & What & ": Failed to set data for '" & ValueName & "'")
End Sub

Sub QREGISTRY.WriteBinary(ByRef ValueName As String, Buffer() As UByte, ByVal DataSize As Long)
    Dim ItemTotal As Long = UBound(Buffer) - LBound(Buffer) + 1
    If DataSize > ItemTotal Then DataSize = ItemTotal
    If DataSize < 0 Then DataSize = 0
    If RqRtRegSetValueEx(KeyHandle, ValueName, 0, RqRtRegBinary, @Buffer(LBound(Buffer)), DataSize) <> 0 Then
        WriteError("WriteBinary", ValueName)
    End If
End Sub

' Как TRegistry.WriteFloat: 8 байт Double, тип REG_BINARY
Sub QREGISTRY.WriteFloat(ByRef ValueName As String, ByVal Value As Double)
    If RqRtRegSetValueEx(KeyHandle, ValueName, 0, RqRtRegBinary, @Value, 8) <> 0 Then
        WriteError("WriteFloat", ValueName)
    End If
End Sub

Sub QREGISTRY.WriteInteger(ByRef ValueName As String, ByVal Value As Long)
    If RqRtRegSetValueEx(KeyHandle, ValueName, 0, RqRtRegDword, @Value, 4) <> 0 Then
        WriteError("WriteInteger", ValueName)
    End If
End Sub

Sub QREGISTRY.WriteString(ByRef ValueName As String, ByRef Value As String)
    ' с завершающим нулём; у пустой строки StrPtr = 0
    Dim ZeroText As ZString * 1
    Dim DataPtr As Any Ptr = StrPtr(Value)
    If Len(Value) = 0 Then DataPtr = @ZeroText
    If RqRtRegSetValueEx(KeyHandle, ValueName, 0, RqRtRegSz, DataPtr, Len(Value) + 1) <> 0 Then
        WriteError("WriteString", ValueName)
    End If
End Sub
