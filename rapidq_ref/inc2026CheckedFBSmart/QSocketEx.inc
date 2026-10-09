$IFNDEF QSOCKET_INC
$DEFINE QSOCKET_INC
'
' QSocketEx - Extends QSocket Component, d_homans, JohnK
' Some added functionality + bug fix to getpeername()
' Code insiration RSOCKET.INC Copyright 2002,2003 Global Services
'               doctorelectron@cwdom.dm  June 6,2003
'
' FILE DATE: 03/06/2007
' NOTES: Without delving into the mechanics of winsock32.dll,
'        (looking at RSocket.inc) there appears to be ONE internal
'        structure that points to a lot of the info about a socket
'        connection. The size of this structure is 16 bytes.
'        The functions below take a copy of this structure
'        and copies the data into either an array of 16 bytes, or an
'        array of 4 longs, whichever is convenient to extract that
'        data.  Code below has been hacked from RSocket.inc and
'        hopefully made a little clearer.
'        Also, have removed the EXIT FUNCTION calls inside some of
'        the code just in case people are still using old rapidq libs
'        with inherent memory leaks etc.
'        Added a new FUNCTION WriteBinData&() which binds WASGetLastError()
'        tightly to the QSocket SUB Write() and the result of the last
'        error, returned to the calling function.
'
DECLARE FUNCTION getpeernamex Lib "wsock32.dll" ALIAS "getpeername" (Skt AS long, ByVal lpSocAddr AS long, namelen AS long) AS long
DECLARE FUNCTION gethostbyaddr Lib "wsock32.dll" ALIAS "gethostbyaddr" (addr AS long,length AS long, protocol AS long) AS long
DECLARE FUNCTION gethostbyname Lib "wsock32.dll" ALIAS "gethostbyname" (ByVal name AS string) AS long
DECLARE FUNCTION shutdown Lib "wsock32.dll" Alias "shutdown"(S As LONG,how As LONG) As LONG

DECLARE FUNCTION inet_addr Lib "wsock32.dll" ALIAS "inet_addr" (ByVal cp AS string) AS long
DECLARE FUNCTION inet_ntoa Lib "wsock32.dll" ALIAS "inet_ntoa" (inaddr AS long) AS long                                                   
DECLARE FUNCTION htons Lib "wsock32.dll" ALIAS "htons" (hostshort AS integer) AS integer
DECLARE FUNCTION ioctlsocket Lib "wsock32.dll" ALIAS "ioctlsocket"(ByVal s As Long, ByVal cmd As Long, argp As Long) As Long
'select is a reserved BASIC word
DECLARE FUNCTION SocketSelect Lib "wsock32.dll" Alias "select" (nfds As LONG, readfds As LONG, writefds As LONG, exceptfds As LONG, timeout As LONG) As LONG


' Some extras                                       
$IFNDEF __RQINC2
    DECLARE FUNCTION WSAGetLastError Lib "wsock32.dll" ALIAS "WSAGetLastError"() AS long
$ENDIF

$IFNDEF __WIN32API 
    DECLARE FUNCTION lstrlen Lib "kernel32.dll" ALIAS "lstrlenA" (ByVal lpString AS long) AS long
    DECLARE FUNCTION lstrcpy Lib "kernel32.dll" ALIAS "lstrcpyA" _
                                       (ByVal lpString1 AS long, ByVal lpString2 AS long) AS long
$ENDIF


TYPE sockaddr_in                    'this is for TCP/IP
    sin_family      AS SHORT
    sin_port        AS WORD         'ushort
    sin_addr        AS LONG         'address of a struct
    sin_zero        AS STRING * 8   'char    sin_zero[8];
END TYPE

'this is a dynamically allocated structure, we will implement with QMEMORYSTREAM
' TYPE fd_set
'     fd_count        AS DWORD                            'u_int how many sockets SET?
'     lpfd_array      AS STRING * 256 * SIZEOF(INTEGER)   'fd_array[FD_SETSIZE] array of SOCKET handles
' END TYPE


$DEFINE FIONBIO  &H8004667E                'needed for block/nonblock
$DEFINE FD_READ         &H01               ' Define flags for WSAAsyncSelect() call.
$DEFINE FD_WRITE        &H02
$DEFINE FD_OOB          &H04
$DEFINE FD_ACCEPT       &H08
$DEFINE FD_CONNECT      &H10
$DEFINE FD_CLOSE        &H20
$DEFINE SD_SEND         &H02
DEFINT SOCKET_ERROR =   -1


TYPE QSocketEx Extends QSocket
Public:

FUNCTION GetPeerName(SockNum AS integer) AS string      ' Override bad Qsocket fn..
    DIM buf(0 TO 15) AS BYTE                ' buf simulates sockaddr_in struct
    DEFINT length=16                                                ' Length of buf
    DEFINT ret = getpeernamex(SockNum, VARPTR(buf(0)),VARPTR(length))
    IF ret < 0 OR length < 1 THEN                                   ' Not sure why length is tested here
        Result=""                                                   ' Unknown!
    ELSE
        Result=STR$(buf(4))+"."+STR$(buf(5))+"."+STR$(buf(6))+"."+STR$(buf(7))
    END IF
END FUNCTION



FUNCTION NameByAddr(strIP AS string) AS string
    DIM IPval AS long
    DIM lpStruc AS long
    DIM buf(0 TO 3) AS long
    DIM tstr AS string
    
    Result=""
    IPval=inet_addr(strIP)                                          ' Convert strIP to a long
    IF IPval <> -1 THEN
        lpStruc = gethostbyaddr(VARPTR(IPval), SIZEOF(long), QSocketEx.Protocol)
        IF lpStruc<>0 THEN
            MEMCPY(VARPTR(buf(0)),lpStruc,16)                      ' Copy sock internal structure                     
            tstr=SPACE$(lstrlen(buf(0)))                            ' Local buffer for peer name
            lstrcpy(VARPTR(tstr),buf(0))                            ' Get the peer name
            Result=RTRIM$(tstr)
        END IF
    END IF
END FUNCTION



FUNCTION AddrByName(strName AS string) AS string
    DIM lpStruc AS long
    DIM lpData AS long
    DIM DataVal AS long
    DIM buf(0 TO 3) AS long
    DIM tstr AS string
    
    Result=""
    lpStruc=gethostbyname(strName)
    IF lpStruc<>0 THEN                                              ' Got Host by Name ok?
        MEMCPY(VARPTR(buf(0)),lpStruc,16)                           ' Copy data to our local buf
        IF RIGHT$(HEX$(buf(2)),2)="02" THEN                         ' An IP address was returned (??)
            MEMCPY(VARPTR(lpData),buf(3),4)                         ' Get the ptr to the data
            MEMCPY(VARPTR(DataVal),lpData,4)                        ' Get the data
            lpData=inet_ntoa(DataVal)                               ' Re-use lpData variable
            tstr=SPACE$(lstrlen(lpData))                            ' Local buffer for IP addr
            lstrcpy(VARPTR(tstr),lpData)                            ' Get the IP address
            Result=tstr
        END IF
    END IF
END FUNCTION


FUNCTION IsConnected(SockNum As LONG, TimeOutSecs As LONG) As LONG
    DEFLNG FD_Set(1) = {1, SockNum}                 'if >1 socket, we would keep adding
    DEFLNG timeval(1) = {TimeOutSecs, 0}            'timeval struct

    Result=-1&
    IF 1 = SocketSelect(0&, 0&, 0&, VARPTR(FD_Set(0)), VARPTR(timeval(0&))) THEN EXIT FUNCTION
    FD_Set(0) = 1
    FD_Set(1) = SockNum
    RESULT = SocketSelect(0&, 0&, VARPTR(FD_Set(0)), 0&, VARPTR(timeval(0&)))

'     DEFLNG lpTimeVal = MyFD_Set.Pointer + MyFD_Set.Position 'tag onto the end!
'     MyFD_Set.Write(TimeOutSecs)
'     fd_count = 0
'     MyFD_Set.Write(fd_count)                                're-use var
'     'this checks for connection errors...
'     fd_count = SocketSelect(0&, 0&, 0&, MyFD_Set.Pointer, lpTimeVal)
'     IF (fd_count = SOCKET_ERROR) OR (fd_count = 0) THEN
'          RESULT = 0
'          EXIT FUNCTION
'      END IF
'     'this checks if we can write, if so we are connected
'     MyFD_Set.Position = 0
'     fd_count = 1
'     MyFD_Set.Write(fd_count)                                        'reload MyFD_Set.fd_count !!
'     MyFD_Set.Write(SockNum)                                         'if more than one, we would keep adding
'     RESULT = SocketSelect(0&, 0&, MyFD_Set.Pointer, 0&, lpTimeVal)
END FUNCTION



SUB WriteLine(SockNum AS integer, Str As STRING) As LONG            'overwrite old method
    DEFSTR OutStr = Str + CHR$(13) + CHR$(10)                       'some servers require cr lf
    QSocketEx.Write(SockNum, OutStr, LEN(OutStr))
    OutStr = ""                                                     'dealloc
END SUB


FUNCTION WriteEx(SockNum AS integer, Message AS string, NumBytes AS integer) AS long
    QSocketEx.Write(SockNum, Message, NumBytes)                     ' Call the QSocket SUB
    RESULT= WSAGetLastError()                                       ' Returns 0 if OK
END FUNCTION


FUNCTION ShutDown(SockNum AS integer) As LONG
    RESULT = shutdown(SockNum, 2&)
END FUNCTION  

' QSocket, you can set them Blocking or not blocking 
' Blocking: On read operation, the socket is blocked until data arrives (can be blocked forever)
' NonBlocking: On Read operation, if there is nothing, Read returns nothing (="")

FUNCTION NonBlock(hSocket As LONG) As LONG
    DefInt arg=1
    Result=ioctlsocket(hSocket, FIONBIO, VarPtr(arg))
END FUNCTION
'
FUNCTION Block(hSocket As LONG) As LONG
    DefInt arg=0
    Result = ioctlsocket(hSocket, FIONBIO, VarPtr(arg))
END FUNCTION
'


'' Reading a couple of pages at the MSDN site before getting bored suggests that
' you can't trust this call, and anything returned may or may not be relevant to
' what you want or need to know!
' With SINGLE connections, it probably tells the truth.
'
FUNCTION LastError() AS string
    DEFSTR tstr = "'
    DEFINT res = WSAGetLastError()                                  ' Call the function
    Select Case res                                                 ' Convert to error string
        Case 10004&: tstr="Interrupted system call."
        Case 10009&: tstr="Bad socket number."
        Case 10013&: tstr="Permission Denied."
        Case 10014&: tstr="Bad Address."
        Case 10022&: tstr="Invalid Argument."
        Case 10024&: tstr="Too many sockets."
        Case 10035&: tstr="Operation would block."
        Case 10036&: tstr="Operation now in progress."
        Case 10037&: tstr="Operation already in progress."
        Case 10038&: tstr="Socket operation on nonsocket."
        Case 10039&: tstr="Destination address required."
        Case 10040&: tstr="Message too long."
        Case 10041&: tstr="Protocol wrong type for socket."
        Case 10042&: tstr="Protocol not available."
        Case 10043&: tstr="Protocol not supported."
        Case 10044&: tstr="Socket type not supported."
        Case 10045&: tstr="Operation not supported on socket."
        Case 10046&: tstr="Protocol family not supported."
        Case 10047&: tstr="Address family not supported by protocol family."
        Case 10048&: tstr="Address already in use."
        Case 10049&: tstr="Cannot assign requested address."
        Case 10050&: tstr="Network is down."
        Case 10051&: tstr="Network is unreachable."
        Case 10052&: tstr="Network dropped connection."
        Case 10053&: tstr="Software caused connection abort."
        Case 10054&: tstr="Connection reset by peer."
        Case 10055&: tstr="No buffer space available."
        Case 10056&: tstr="Socket is already connected."
        Case 10057&: tstr="Socket is not connected."
        Case 10058&: tstr="Cannot send after socket shutdown."
        Case 10059&: tstr="Too many references: cannot splice."
        Case 10060&: tstr="Connection timed out."
        Case 10061&: tstr="Connection refused."
        Case 10062&: tstr="Too many levels of symbolic links."
        Case 10063&: tstr="File name too long."
        Case 10064&: tstr="Host is down."
        Case 10065&: tstr="No route to host."
        Case 10066&: tstr="Directory not empty."
        Case 10067&: tstr="Too many processes."
        Case 10068&: tstr="Too many users."
        Case 10069&: tstr="Disk quota exceeded."
        Case 10070&: tstr="Stale NFS file handle."
        Case 10071&: tstr="Too many levels of remote in path."
        Case 10091&: tstr="Network subsystem is unusable."
        Case 10092&: tstr="Winsock DLL cannot support this application."
        Case 10093&: tstr="Winsock not initialized."
        Case 10101&: tstr="Disconnect."
        Case 11001&: tstr="Host not found."
        Case 11002&: tstr="Nonauthoritative host not found."
        Case 11003&: tstr="Nonrecoverable error."
        Case 11004&: tstr="Valid name,no data record of requested type."
        Case 0: tstr="Success"
        Case Else:  tstr="Unknown error."
    End Select
    Result=str$(res)+": "+tstr
END FUNCTION

'
' Do not see a need for any other additions to Qsocket from Rsocket
'CONST MAX_SOCKETS=16                                               ' An array of sockets?

'Private:
'     SktIndex(0 TO MAX_SOCKETS-1) AS integer                       ' An array of sockets? No -> KISS

'Public:
'FUNCTION RegisterSocket() AS integer                               ' Create/register multiple sockets..
'DIM i AS integer                                                   ' .. (the S fn in RSocket.inc)..
'                                                                   ' ..would need to set the parms of..
'    Result=-1                                                      ' ..each new socket
'    FOR i=0 TO MAX_SOCKETS-1
'        IF SktIndex(i)=0 THEN
'            WITH QSocketEx
'            SktIndex(i)=socket(.Family, .Type, .Protocol)
'            END WITH
'            Result=i                                               ' Return index into a socket array
'            EXIT FOR
'        END IF
'    NEXT i
'END FUNCTION


    CONSTRUCTOR
        Tag =0
END TYPE



$ENDIF
