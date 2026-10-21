' ---------------------------------------------------------------------------
'  RqLcl: QSOCKET - сокеты TCP/IP (Winsock, ws2_32.dll), без DLL RqLcl.
'  Подключается из rqlcl.bi.
'
'  Номер сокета - Long (MySocket - результат последнего Open / Connect);
'  ошибка - -1. Transferred - байт после последнего Read / Write (ошибка
'  -1, соединение закрыто - 0).
'  Type, Peek - слова FreeBASIC; препроцессор: Socket.Type -> Socket.Type_v,
'  Socket.Peek -> Socket.Peek_v.
'  WriteLine посылает строку и Chr(10); ReadLine читает до Chr(10) и
'  убирает Chr(13) в конце.
' ---------------------------------------------------------------------------

Type RqWsSockAddrIn
    sin_family As Short
    sin_port As UShort
    sin_addr As ULong
    sin_zero(0 To 7) As UByte
End Type

Type RqWsHostEnt
    h_name As ZString Ptr
    h_aliases As ZString Ptr Ptr
    h_addrtype As Short
    h_length As Short
    h_addr_list As ULong Ptr Ptr
End Type

Type RqWsFdSet
    fd_count As ULong
    fd_array(0 To 63) As UInteger
End Type

Type RqWsTimeVal
    tv_sec As Long
    tv_usec As Long
End Type

Declare Function RqWsStartup Lib "ws2_32" Alias "WSAStartup" (ByVal Version As UShort, ByVal WsData As Any Ptr) As Long
Declare Function RqWsSocket Lib "ws2_32" Alias "socket" (ByVal AddrFamily As Long, ByVal SockType As Long, ByVal SockProto As Long) As UInteger
Declare Function RqWsBind Lib "ws2_32" Alias "bind" (ByVal Sock As UInteger, ByVal SockAddr As Any Ptr, ByVal AddrLen As Long) As Long
Declare Function RqWsListen Lib "ws2_32" Alias "listen" (ByVal Sock As UInteger, ByVal Backlog As Long) As Long
Declare Function RqWsAccept Lib "ws2_32" Alias "accept" (ByVal Sock As UInteger, ByVal SockAddr As Any Ptr, ByVal AddrLen As Long Ptr) As UInteger
Declare Function RqWsConnect Lib "ws2_32" Alias "connect" (ByVal Sock As UInteger, ByVal SockAddr As Any Ptr, ByVal AddrLen As Long) As Long
Declare Function RqWsCloseSocket Lib "ws2_32" Alias "closesocket" (ByVal Sock As UInteger) As Long
Declare Function RqWsRecv Lib "ws2_32" Alias "recv" (ByVal Sock As UInteger, ByVal Buffer As Any Ptr, ByVal BufLen As Long, ByVal RecvFlags As Long) As Long
Declare Function RqWsSend Lib "ws2_32" Alias "send" (ByVal Sock As UInteger, ByVal Buffer As Any Ptr, ByVal BufLen As Long, ByVal SendFlags As Long) As Long
Declare Function RqWsSelect Lib "ws2_32" Alias "select" (ByVal FdCount As Long, ByVal ReadSet As Any Ptr, ByVal WriteSet As Any Ptr, ByVal ExceptSet As Any Ptr, ByVal TimeOut As Any Ptr) As Long
Declare Function RqWsGetHostName Lib "ws2_32" Alias "gethostname" (ByVal HostName As ZString Ptr, ByVal NameLen As Long) As Long
Declare Function RqWsGetHostByName Lib "ws2_32" Alias "gethostbyname" (ByVal HostName As ZString Ptr) As RqWsHostEnt Ptr
Declare Function RqWsInetAddr Lib "ws2_32" Alias "inet_addr" (ByVal AddrText As ZString Ptr) As ULong
Declare Function RqWsInetNtoa Lib "ws2_32" Alias "inet_ntoa" (ByVal Addr As ULong) As ZString Ptr
Declare Function RqWsHtons Lib "ws2_32" Alias "htons" (ByVal HostShort As UShort) As UShort
Declare Function RqWsGetPeerName Lib "ws2_32" Alias "getpeername" (ByVal Sock As UInteger, ByVal SockAddr As Any Ptr, ByVal AddrLen As Long Ptr) As Long
Declare Function RqWsAsyncSelect Lib "ws2_32" Alias "WSAAsyncSelect" (ByVal Sock As UInteger, ByVal WndHandle As Any Ptr, ByVal MsgNum As ULong, ByVal EventMask As Long) As Long

Dim Shared RqWsReady As Long

' Winsock - один раз за программу
Sub RqWsEnsure()
    If RqWsReady Then Exit Sub
    Dim WsData(0 To 511) As UByte
    If RqWsStartup(&h0202, @WsData(0)) = 0 Then RqWsReady = 1
End Sub

' Готов ли сокет к чтению (без ожидания): 1 / 0
Function RqWsReadable(ByVal Sock As Long) As Long
    Dim ReadSet As RqWsFdSet
    Dim WaitTime As RqWsTimeVal
    ReadSet.fd_count = 1
    ReadSet.fd_array(0) = Cast(UInteger, Sock)
    If RqWsSelect(0, @ReadSet, 0, 0, @WaitTime) > 0 Then Return 1
    Return 0
End Function

' Адрес по имени или "1.2.3.4"; нет - &hFFFFFFFF
Function RqWsResolve(ByRef HostName As String) As ULong
    Dim Addr As ULong = RqWsInetAddr(StrPtr(HostName))
    If Addr <> &hFFFFFFFFul Then Return Addr
    Dim HostPtr As RqWsHostEnt Ptr = RqWsGetHostByName(StrPtr(HostName))
    If HostPtr = 0 Then Return &hFFFFFFFFul
    If HostPtr->h_addr_list = 0 OrElse HostPtr->h_addr_list[0] = 0 Then Return &hFFFFFFFFul
    Return *(HostPtr->h_addr_list[0])
End Function

' ---------------------------------------------------------------------------
'  QSOCKET
' ---------------------------------------------------------------------------

Type QSOCKET
    Family As Long = 2           ' AF_INET
    Type_v As Long = 1           ' SOCK_STREAM
    Protocol As Long = 0         ' IPPROTO_IP
    LParam As Long = &h10        ' FD_CONNECT
    WMessage As Long = 0
    Tag As Long
    MySocket As Long = -1
    Transferred As Long
    ParentHandle As Any Ptr
    Declare Property Parent(ByRef Value As QCONTROL)
    Declare Sub AsyncNotify(ByVal Sock As Long)
    Declare Function Open(ByVal PortNum As Long) As Long
    Declare Function Connect(ByRef ServerName As String, ByVal PortNum As Long) As Long
    Declare Function Accept(ByVal Sock As Long) As Long
    Declare Sub Close(ByVal Sock As Long)
    Declare Function ConnectionReady(ByVal Sock As Long) As Long
    Declare Function IsServerReady(ByVal Sock As Long) As Long
    Declare Function IsClientReady(ByVal Sock As Long, ByVal ClientSock As Long) As Long
    Declare Function GetHostName() As String
    Declare Function GetHostIP() As String
    Declare Function GetPeerName(ByVal Sock As Long) As String
    Declare Function RecvText(ByVal Sock As Long, ByVal NumBytes As Long, ByVal RecvFlags As Long) As String
    Declare Function Read(ByVal Sock As Long, ByVal NumBytes As Long) As String
    ' Peek - слово FreeBASIC; препроцессор: Socket.Peek -> Socket.Peek_v
    Declare Function Peek_v(ByVal Sock As Long, ByVal NumBytes As Long) As String
    Declare Function ReadByte(ByVal Sock As Long) As Long
    Declare Function ReadLine(ByVal Sock As Long) As String
    Declare Sub Write(ByVal Sock As Long, ByRef Message As String, ByVal NumBytes As Long)
    Declare Sub WriteByte(ByVal Sock As Long, ByVal ByteValue As Long)
    Declare Function WriteLine(ByVal Sock As Long, ByRef Message As String) As Long
End Type

' Форма для WMessage (сообщения Winsock о событиях сокета)
Property QSOCKET.Parent(ByRef Value As QCONTROL)
    ParentHandle = Cast(Any Ptr, Value.Handle)
End Property
' WMessage <> 0 и Parent: события сокета (LParam) - сообщением WMessage
' форме (WSAAsyncSelect; сокет становится неблокирующим)
Sub QSOCKET.AsyncNotify(ByVal Sock As Long)
    If (WMessage <> 0) AndAlso (ParentHandle <> 0) Then
        RqWsAsyncSelect(Cast(UInteger, Sock), ParentHandle, WMessage, LParam)
    End If
End Sub
' Сервер TCP на порту PortNum: сокет или -1
Function QSOCKET.Open(ByVal PortNum As Long) As Long
    RqWsEnsure()
    MySocket = -1
    Dim Sock As UInteger = RqWsSocket(Family, Type_v, Protocol)
    If Sock = Cast(UInteger, -1) Then Return -1
    Dim SockAddr As RqWsSockAddrIn
    SockAddr.sin_family = Family
    SockAddr.sin_port = RqWsHtons(PortNum)
    SockAddr.sin_addr = 0
    If (RqWsBind(Sock, @SockAddr, SizeOf(SockAddr)) <> 0) OrElse (RqWsListen(Sock, 5) <> 0) Then
        RqWsCloseSocket(Sock)
        Return -1
    End If
    MySocket = Cast(Long, Sock)
    AsyncNotify(MySocket)
    Return MySocket
End Function
' Соединение с сервером: сокет или -1
Function QSOCKET.Connect(ByRef ServerName As String, ByVal PortNum As Long) As Long
    RqWsEnsure()
    MySocket = -1
    Dim Addr As ULong = RqWsResolve(ServerName)
    If Addr = &hFFFFFFFFul Then Return -1
    Dim Sock As UInteger = RqWsSocket(Family, Type_v, Protocol)
    If Sock = Cast(UInteger, -1) Then Return -1
    Dim SockAddr As RqWsSockAddrIn
    SockAddr.sin_family = Family
    SockAddr.sin_port = RqWsHtons(PortNum)
    SockAddr.sin_addr = Addr
    If RqWsConnect(Sock, @SockAddr, SizeOf(SockAddr)) <> 0 Then
        RqWsCloseSocket(Sock)
        Return -1
    End If
    MySocket = Cast(Long, Sock)
    AsyncNotify(MySocket)
    Return MySocket
End Function
Function QSOCKET.Accept(ByVal Sock As Long) As Long
    Dim ClientSock As UInteger = RqWsAccept(Cast(UInteger, Sock), 0, 0)
    If ClientSock = Cast(UInteger, -1) Then Return -1
    Return Cast(Long, ClientSock)
End Function
Sub QSOCKET.Close(ByVal Sock As Long)
    RqWsCloseSocket(Cast(UInteger, Sock))
End Sub
' Есть ли клиент, ждущий Accept: 1 / 0
Function QSOCKET.ConnectionReady(ByVal Sock As Long) As Long
    Return RqWsReadable(Sock)
End Function
' Пришли ли данные: 1 / 0
Function QSOCKET.IsServerReady(ByVal Sock As Long) As Long
    Return RqWsReadable(Sock)
End Function
Function QSOCKET.IsClientReady(ByVal Sock As Long, ByVal ClientSock As Long) As Long
    Return RqWsReadable(ClientSock)
End Function
Function QSOCKET.GetHostName() As String
    RqWsEnsure()
    Dim NameBuf As ZString * 256
    If RqWsGetHostName(@NameBuf, 256) <> 0 Then Return ""
    Return NameBuf
End Function
Function QSOCKET.GetHostIP() As String
    Dim HostAddr As ULong = RqWsResolve(GetHostName())
    If HostAddr = &hFFFFFFFFul Then Return ""
    Return *RqWsInetNtoa(HostAddr)
End Function
' Адрес IP собеседника
Function QSOCKET.GetPeerName(ByVal Sock As Long) As String
    Dim SockAddr As RqWsSockAddrIn
    Dim AddrLen As Long = SizeOf(SockAddr)
    If RqWsGetPeerName(Cast(UInteger, Sock), @SockAddr, @AddrLen) <> 0 Then Return ""
    Return *RqWsInetNtoa(SockAddr.sin_addr)
End Function
Function QSOCKET.RecvText(ByVal Sock As Long, ByVal NumBytes As Long, ByVal RecvFlags As Long) As String
    If NumBytes <= 0 Then
        Transferred = 0
        Return ""
    End If
    Dim Buffer As String = Space(NumBytes)
    Transferred = RqWsRecv(Cast(UInteger, Sock), StrPtr(Buffer), NumBytes, RecvFlags)
    If Transferred <= 0 Then Return ""
    Return Mid(Buffer, 1, Transferred)
End Function
' До NumBytes байт (ждёт, пока что-то придёт)
Function QSOCKET.Read(ByVal Sock As Long, ByVal NumBytes As Long) As String
    Return RecvText(Sock, NumBytes, 0)
End Function
' Как Read, но данные остаются в сокете (MSG_PEEK)
Function QSOCKET.Peek_v(ByVal Sock As Long, ByVal NumBytes As Long) As String
    Return RecvText(Sock, NumBytes, 2)
End Function
Function QSOCKET.ReadByte(ByVal Sock As Long) As Long
    Dim ByteText As String = RecvText(Sock, 1, 0)
    If Len(ByteText) = 0 Then Return 0
    Return Asc(ByteText)
End Function
Function QSOCKET.ReadLine(ByVal Sock As Long) As String
    Dim LineText As String
    Dim ByteValue As UByte
    Dim Total As Long
    Do
        If RqWsRecv(Cast(UInteger, Sock), @ByteValue, 1, 0) <> 1 Then
            If Total = 0 Then Total = -1
            Exit Do
        End If
        Total += 1
        If ByteValue = 10 Then Exit Do
        LineText &= Chr(ByteValue)
    Loop
    Transferred = Total
    If Right(LineText, 1) = Chr(13) Then LineText = Mid(LineText, 1, Len(LineText) - 1)
    Return LineText
End Function
' NumBytes байт из Message (не больше длины строки)
Sub QSOCKET.Write(ByVal Sock As Long, ByRef Message As String, ByVal NumBytes As Long)
    If NumBytes > Len(Message) Then NumBytes = Len(Message)
    If NumBytes <= 0 Then
        Transferred = 0
        Exit Sub
    End If
    Transferred = RqWsSend(Cast(UInteger, Sock), StrPtr(Message), NumBytes, 0)
End Sub
Sub QSOCKET.WriteByte(ByVal Sock As Long, ByVal ByteValue As Long)
    Dim OneByte As UByte = ByteValue
    Transferred = RqWsSend(Cast(UInteger, Sock), @OneByte, 1, 0)
End Sub
' Строка и Chr(10); результат - число посланных байт, ошибка - 0
' (Transferred - -1)
Function QSOCKET.WriteLine(ByVal Sock As Long, ByRef Message As String) As Long
    Dim LineText As String = Message & Chr(10)
    Transferred = RqWsSend(Cast(UInteger, Sock), StrPtr(LineText), Len(LineText), 0)
    If Transferred <= 0 Then Return 0
    Return Transferred
End Function
