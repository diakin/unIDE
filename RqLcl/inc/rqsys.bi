' ---------------------------------------------------------------------------
'  RqLcl: QOPENDIALOG, QSAVEDIALOG и глобальные объекты RapidQ
'  Application, Screen, Clipboard (документация RapidQ, Appendix A,
'  internal.html). Подключается из rqlcl.bi.
'
'  Глобальные объекты - переменные Application, Screen_v (Screen - слово
'  FreeBASIC; препроцессор переименовывает Screen в Screen_v), Clipboard.
'  Объект LCL берётся при первом обращении (до него DLL не загружается).
' ---------------------------------------------------------------------------

Declare Function RqLclGetModuleHandle Lib "kernel32" Alias "GetModuleHandleA" ( _
    ByVal ModuleName As ZString Ptr) As Any Ptr

' Метод, который возвращает значение (Execute, HasFormat): без окна ошибки
Function RqLclCallValue(ByVal ObjPtr As Any Ptr, ByRef MethodName As String) As Long
    Return RqCall(ObjPtr, StrPtr(MethodName))
End Function

' ---------------------------------------------------------------------------
'  QOPENDIALOG - окно выбора файла (TOpenDialog / TSaveDialog LCL); Filter "Текст|*.txt|Все|*.*", FilterIndex с 1
' ---------------------------------------------------------------------------

Type QOPENDIALOG
    RqObj As Any Ptr
    Declare Constructor()
    Declare Property Caption() As String
    Declare Property Caption(ByRef Value As String)
    Declare Property FileName() As String
    Declare Property FileName(ByRef Value As String)
    Declare Property Filter() As String
    Declare Property Filter(ByRef Value As String)
    Declare Property InitialDir() As String
    Declare Property InitialDir(ByRef Value As String)
    Declare Property FilterIndex() As Long
    Declare Property FilterIndex(ByVal Value As Long)
    ' 1 - файл выбран, 0 - отмена
    Declare Function Execute() As Long
End Type

Constructor QOPENDIALOG()
    RqObj = RqLclNew("QOPENDIALOG", @This)
End Constructor
Function QOPENDIALOG.Execute() As Long
    Return RqLclCallValue(RqObj, "Execute")
End Function
Property QOPENDIALOG.Caption() As String
    Return RqLclGetStr(RqObj, "Caption")
End Property
Property QOPENDIALOG.Caption(ByRef Value As String)
    RqLclSetStr(RqObj, "Caption", Value)
End Property
Property QOPENDIALOG.FileName() As String
    Return RqLclGetStr(RqObj, "FileName")
End Property
Property QOPENDIALOG.FileName(ByRef Value As String)
    RqLclSetStr(RqObj, "FileName", Value)
End Property
Property QOPENDIALOG.Filter() As String
    Return RqLclGetStr(RqObj, "Filter")
End Property
Property QOPENDIALOG.Filter(ByRef Value As String)
    RqLclSetStr(RqObj, "Filter", Value)
End Property
Property QOPENDIALOG.InitialDir() As String
    Return RqLclGetStr(RqObj, "InitialDir")
End Property
Property QOPENDIALOG.InitialDir(ByRef Value As String)
    RqLclSetStr(RqObj, "InitialDir", Value)
End Property
Property QOPENDIALOG.FilterIndex() As Long
    Return RqGetInt(RqObj, "FilterIndex")
End Property
Property QOPENDIALOG.FilterIndex(ByVal Value As Long)
    RqLclSetInt(RqObj, "FilterIndex", Value)
End Property

' ---------------------------------------------------------------------------
'  QSAVEDIALOG - окно выбора файла (TOpenDialog / TSaveDialog LCL); Filter "Текст|*.txt|Все|*.*", FilterIndex с 1
' ---------------------------------------------------------------------------

Type QSAVEDIALOG
    RqObj As Any Ptr
    Declare Constructor()
    Declare Property Caption() As String
    Declare Property Caption(ByRef Value As String)
    Declare Property FileName() As String
    Declare Property FileName(ByRef Value As String)
    Declare Property Filter() As String
    Declare Property Filter(ByRef Value As String)
    Declare Property InitialDir() As String
    Declare Property InitialDir(ByRef Value As String)
    Declare Property FilterIndex() As Long
    Declare Property FilterIndex(ByVal Value As Long)
    ' 1 - файл выбран, 0 - отмена
    Declare Function Execute() As Long
End Type

Constructor QSAVEDIALOG()
    RqObj = RqLclNew("QSAVEDIALOG", @This)
End Constructor
Function QSAVEDIALOG.Execute() As Long
    Return RqLclCallValue(RqObj, "Execute")
End Function
Property QSAVEDIALOG.Caption() As String
    Return RqLclGetStr(RqObj, "Caption")
End Property
Property QSAVEDIALOG.Caption(ByRef Value As String)
    RqLclSetStr(RqObj, "Caption", Value)
End Property
Property QSAVEDIALOG.FileName() As String
    Return RqLclGetStr(RqObj, "FileName")
End Property
Property QSAVEDIALOG.FileName(ByRef Value As String)
    RqLclSetStr(RqObj, "FileName", Value)
End Property
Property QSAVEDIALOG.Filter() As String
    Return RqLclGetStr(RqObj, "Filter")
End Property
Property QSAVEDIALOG.Filter(ByRef Value As String)
    RqLclSetStr(RqObj, "Filter", Value)
End Property
Property QSAVEDIALOG.InitialDir() As String
    Return RqLclGetStr(RqObj, "InitialDir")
End Property
Property QSAVEDIALOG.InitialDir(ByRef Value As String)
    RqLclSetStr(RqObj, "InitialDir", Value)
End Property
Property QSAVEDIALOG.FilterIndex() As Long
    Return RqGetInt(RqObj, "FilterIndex")
End Property
Property QSAVEDIALOG.FilterIndex(ByVal Value As Long)
    RqLclSetInt(RqObj, "FilterIndex", Value)
End Property

' ---------------------------------------------------------------------------
'  QAPPLICATION - глобальный объект Application (TApplication LCL); ExeName - имя exe без пути
' ---------------------------------------------------------------------------

Type QAPPLICATION
    RqObj As Any Ptr
    Declare Function Obj() As Any Ptr
    Declare Property ExeName() As String
    Declare Property Title() As String
    Declare Property Title(ByRef Value As String)
    Declare Property HelpFile() As String
    Declare Property HelpFile(ByRef Value As String)
    Declare Property HintColor() As Long
    Declare Property HintColor(ByVal Value As Long)
    Declare Property HintPause() As Long
    Declare Property HintPause(ByVal Value As Long)
    Declare Property HintHidePause() As Long
    Declare Property HintHidePause(ByVal Value As Long)
    Declare Property HintShortPause() As Long
    Declare Property HintShortPause(ByVal Value As Long)
    Declare Property ShowHint() As Long
    Declare Property ShowHint(ByVal Value As Long)
    Declare Property Icon(ByRef Value As String)
    Declare Property Handle() As Integer
    Declare Property hInstance() As Integer
    Declare Sub Terminate()
    Declare Sub Minimize()
    Declare Sub Restore()
    Declare Property IcoHandle(ByVal Value As Long)
    ' Дескриптор значка программы (HICON), 0 - нет. Чтение Icon в числовом
    ' присваивании (QFormEx: hIcon = Application.Icon) переводится сюда
    Declare Property IconHandle() As Long
    Declare Sub HelpCommand(ByVal Command As Long, ByVal HelpData As Long)
    Declare Sub HelpContext(ByVal Context As Long)
    Declare Sub HelpJump(ByRef JumpID As String)
End Type

Function QAPPLICATION.Obj() As Any Ptr
    If RqObj = 0 Then RqObj = RqLclNew("QAPPLICATION", 0)
    Return RqObj
End Function
' Значок программы - ресурс $RESOURCE с файлом .ico
Property QAPPLICATION.IcoHandle(ByVal Value As Long)
    RqLclSetInt(Obj(), "IcoHandle", Value)
End Property
Property QAPPLICATION.IconHandle() As Long
    Return RqGetInt(Obj(), "IconHandle")
End Property
' Справка HelpFile: HelpCommand - WinHelp (команда, данные); HelpContext и
' HelpJump - у файла .chm через HtmlHelp, у остальных через WinHelp
Sub QAPPLICATION.HelpCommand(ByVal Command As Long, ByVal HelpData As Long)
    If RqCallEx(Obj(), "HelpCommand", 0, Command, HelpData, 0, 0, 0) = 0 Then RqLclClassError("Application.HelpCommand")
End Sub
Sub QAPPLICATION.HelpContext(ByVal Context As Long)
    If RqCallEx(Obj(), "HelpContext", 0, Context, 0, 0, 0, 0) = 0 Then RqLclClassError("Application.HelpContext")
End Sub
Sub QAPPLICATION.HelpJump(ByRef JumpID As String)
    If RqCallEx(Obj(), "HelpJump", StrPtr(JumpID), 0, 0, 0, 0, 0) = 0 Then RqLclClassError("Application.HelpJump")
End Sub
Property QAPPLICATION.Icon(ByRef Value As String)
    RqLclSetStr(Obj(), "Icon", Value)
End Property
' hInstance программы
Property QAPPLICATION.Handle() As Integer
    Return Cast(Integer, RqLclGetModuleHandle(0))
End Property
' Application.hInstance - в документации (qapplication.html) нет, у
' Handle сказано "hInstance of the application"; в rapidq2.inc (QFormEx,
' QImageEx) - Application.hInstance. Значение - как у Handle
Property QAPPLICATION.hInstance() As Integer
    Return Cast(Integer, RqLclGetModuleHandle(0))
End Property
' Конец программы: окна закрываются (ShowModal возвращается), следующий
' DoEvents заканчивает программу
Sub QAPPLICATION.Terminate()
    RqLclTerminated = 1
    RqLclCall(Obj(), "Terminate")
End Sub
Sub QAPPLICATION.Minimize()
    RqLclCall(Obj(), "Minimize")
End Sub
Sub QAPPLICATION.Restore()
    RqLclCall(Obj(), "Restore")
End Sub
Property QAPPLICATION.ExeName() As String
    Return RqLclGetStr(Obj(), "ExeName")
End Property
Property QAPPLICATION.Title() As String
    Return RqLclGetStr(Obj(), "Title")
End Property
Property QAPPLICATION.Title(ByRef Value As String)
    RqLclSetStr(Obj(), "Title", Value)
End Property
Property QAPPLICATION.HelpFile() As String
    Return RqLclGetStr(Obj(), "HelpFile")
End Property
Property QAPPLICATION.HelpFile(ByRef Value As String)
    RqLclSetStr(Obj(), "HelpFile", Value)
End Property
Property QAPPLICATION.HintColor() As Long
    Return RqGetInt(Obj(), "HintColor")
End Property
Property QAPPLICATION.HintColor(ByVal Value As Long)
    RqLclSetInt(Obj(), "HintColor", Value)
End Property
Property QAPPLICATION.HintPause() As Long
    Return RqGetInt(Obj(), "HintPause")
End Property
Property QAPPLICATION.HintPause(ByVal Value As Long)
    RqLclSetInt(Obj(), "HintPause", Value)
End Property
Property QAPPLICATION.HintHidePause() As Long
    Return RqGetInt(Obj(), "HintHidePause")
End Property
Property QAPPLICATION.HintHidePause(ByVal Value As Long)
    RqLclSetInt(Obj(), "HintHidePause", Value)
End Property
Property QAPPLICATION.HintShortPause() As Long
    Return RqGetInt(Obj(), "HintShortPause")
End Property
Property QAPPLICATION.HintShortPause(ByVal Value As Long)
    RqLclSetInt(Obj(), "HintShortPause", Value)
End Property
Property QAPPLICATION.ShowHint() As Long
    Return RqGetInt(Obj(), "ShowHint")
End Property
Property QAPPLICATION.ShowHint(ByVal Value As Long)
    RqLclSetInt(Obj(), "ShowHint", Value)
End Property

' ---------------------------------------------------------------------------
'  QSCREEN - глобальный объект Screen: размер экрана, положение мыши, общий курсор
' ---------------------------------------------------------------------------

Type QSCREEN
    RqObj As Any Ptr
    Declare Function Obj() As Any Ptr
    Declare Property Width() As Long
    Declare Property Height() As Long
    Declare Property MouseX() As Long
    Declare Property MouseY() As Long
    Declare Property Cursor() As Long
    Declare Property Cursor(ByVal Value As Long)
End Type

Function QSCREEN.Obj() As Any Ptr
    If RqObj = 0 Then RqObj = RqLclNew("QSCREEN", 0)
    Return RqObj
End Function
Property QSCREEN.Width() As Long
    Return RqGetInt(Obj(), "Width")
End Property
Property QSCREEN.Height() As Long
    Return RqGetInt(Obj(), "Height")
End Property
Property QSCREEN.MouseX() As Long
    Return RqGetInt(Obj(), "MouseX")
End Property
Property QSCREEN.MouseY() As Long
    Return RqGetInt(Obj(), "MouseY")
End Property
Property QSCREEN.Cursor() As Long
    Return RqGetInt(Obj(), "Cursor")
End Property
Property QSCREEN.Cursor(ByVal Value As Long)
    RqLclSetInt(Obj(), "Cursor", Value)
End Property

' ---------------------------------------------------------------------------
'  QCLIPBOARD - глобальный объект Clipboard (буфер обмена; текст в кодировке Windows)
' ---------------------------------------------------------------------------

Type QCLIPBOARD
    RqObj As Any Ptr
    Declare Function Obj() As Any Ptr
    Declare Property Text() As String
    Declare Property Text(ByRef Value As String)
    Declare Property FormatCount() As Long
    Declare Sub Clear()
    Declare Sub Open()
    Declare Sub Close()
    Declare Function HasFormat(ByVal FormatNum As Long) As Long
    Declare Function GetAsText(ByVal TextLen As Long = -1) As String
    Declare Sub SetAsText(ByRef Value As String)
    Declare Property Format(ByVal FormatIdx As Long) As Long
    Declare Function GetAsHandle(ByVal FormatNum As Long) As Long
    Declare Sub SetAsHandle(ByVal FormatNum As Long, ByVal DataHandle As Long)
End Type

Function QCLIPBOARD.Obj() As Any Ptr
    If RqObj = 0 Then RqObj = RqLclNew("QCLIPBOARD", 0)
    Return RqObj
End Function
' Format(i) - номер i-го формата в буфере (0 .. FormatCount - 1)
Property QCLIPBOARD.Format(ByVal FormatIdx As Long) As Long
    Dim FormatNum As Long = RqGetItemInt(Obj(), "Format", FormatIdx)
    If FormatNum = 0 Then RqLclCheckError("Clipboard.Format")
    Return FormatNum
End Property
' Данные формата - описатель Windows (GetClipboardData); 0 - нет
Function QCLIPBOARD.GetAsHandle(ByVal FormatNum As Long) As Long
    Return RqCallEx(Obj(), "GetAsHandle", 0, FormatNum, 0, 0, 0, 0)
End Function
' Буфер очищается, описатель переходит Windows (SetClipboardData)
Sub QCLIPBOARD.SetAsHandle(ByVal FormatNum As Long, ByVal DataHandle As Long)
    If RqCallEx(Obj(), "SetAsHandle", 0, FormatNum, DataHandle, 0, 0, 0) = 0 Then RqLclClassError("Clipboard.SetAsHandle")
End Sub
Sub QCLIPBOARD.Clear()
    RqLclCall(Obj(), "Clear")
End Sub
Sub QCLIPBOARD.Open()
    RqLclCall(Obj(), "Open")
End Sub
Sub QCLIPBOARD.Close()
    RqLclCall(Obj(), "Close")
End Sub
' Формат Windows (CF_TEXT = 1...): 0 - нет
Function QCLIPBOARD.HasFormat(ByVal FormatNum As Long) As Long
    Return RqCallInt(Obj(), "HasFormat", FormatNum)
End Function
Function QCLIPBOARD.GetAsText(ByVal TextLen As Long = -1) As String
    Dim TextValue As String = RqLclGetStr(Obj(), "Text")
    If TextLen >= 0 Then Return Left(TextValue, TextLen)
    Return TextValue
End Function
Sub QCLIPBOARD.SetAsText(ByRef Value As String)
    RqLclSetStr(Obj(), "Text", Value)
End Sub
Property QCLIPBOARD.Text() As String
    Return RqLclGetStr(Obj(), "Text")
End Property
Property QCLIPBOARD.Text(ByRef Value As String)
    RqLclSetStr(Obj(), "Text", Value)
End Property
Property QCLIPBOARD.FormatCount() As Long
    Return RqGetInt(Obj(), "FormatCount")
End Property

Dim Shared Application As QAPPLICATION
Dim Shared Screen_v As QSCREEN
Dim Shared Clipboard As QCLIPBOARD
