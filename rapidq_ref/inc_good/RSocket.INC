''''''RSOCKET.INC''''''Copyright 2002,2003 Global Services
'''by doctorelectron@cwdom.dm  FreeWare,just give attribution if you use it!!
'''Last Updated: June 6,2003

Declare Function closesocket Lib "wsock32.dll" Alias "closesocket"_
  (S As LONG) As LONG
Declare Function connectx Lib "wsock32.dll" Alias "connect" (S As LONG,_
  sockaddr As LONG,namelen As INTEGER) As LONG
Declare Function gethostbyaddr Lib "wsock32.dll" Alias "gethostbyaddr"_
  (addr As LONG,length As LONG,protocol As LONG) As LONG
Declare Function gethostbyname Lib "wsock32.dll" Alias "gethostbyname"_
  (ByVal name As STRING) As LONG
Declare Function getpeernamex Lib "wsock32.dll" Alias "getpeername"_
  (S As LONG,ByVal name As LONG,namelen As LONG) As LONG
Declare Function htons Lib "wsock32.dll" Alias "htons" (hostshort As INTEGER)_
  As INTEGER
Declare Function inet_addr Lib "wsock32.dll" Alias "inet_addr"_
  (ByVal cp As STRING) As LONG
Declare Function inet_ntoa Lib "wsock32.dll" Alias "inet_ntoa"_
  (inaddr As LONG) As LONG
Declare Function ioctlsocket Lib "wsock32.dll" Alias "ioctlsocket"_
  (S As LONG,cmd As LONG,arg As LONG) As LONG
Declare Function selectx Lib "wsock32.dll" Alias "select" (nfds As LONG,_
  readfds As LONG,writefds As LONG,exceptfds As LONG,_
  timeout As LONG) As LONG
Declare Function shutdown Lib "wsock32.dll" Alias "shutdown"_
  (S As LONG,how As LONG) As LONG
Declare Function socket Lib "wsock32.dll" Alias "socket" (af As LONG,_
  type_specification As LONG,protocol As LONG) As LONG

Declare Function send Lib "wsock32.dll" Alias "send" (S As LONG,_
  buf As STRING,len As LONG,flags As LONG) As LONG
Declare Function recv Lib "wsock32.dll" Alias "recv" (S As LONG,_
  buf As STRING,len As LONG,flags As LONG) As LONG
DECLARE FUNCTION sendto Lib "wsock32.dll" Alias "sendto" (S As LONG,_
  buf As LONG,Len As LONG,flags As LONG,_
  ptrAddress As LONG,LenAddr As LONG) As LONG
DECLARE FUNCTION recvfrom Lib "wsock32.dll" Alias "recvfrom" (S As LONG,_
  buf As LONG,Len As LONG,flags As LONG,_
  ptrAddress As LONG,LenAddr As LONG) As LONG
Declare Sub CopyMemory Lib "kernel32.dll" Alias "RtlMoveMemory"_
  (hpvDest As LONG,hpvSource As LONG,cbCopy As LONG)




$IFNDEF __WIN32API 
Declare Function lstrlen Lib "kernel32.dll" Alias "lstrlenA"_
  (ByVal lpString As LONG) As LONG
Declare Function lstrcpy Lib "kernel32.dll" Alias "lstrcpyA"_
  (ByVal lpString1 As LONG,ByVal lpString2 As LONG) As LONG

$IFNDEF __RQINC2
Declare Function WSAGetLastError Lib "wsock32.dll" Alias "WSAGetLastError"_
  () As LONG

$ENDIF
$ENDIF

DIM arg As LONG,num As LONG,ptr1 As LONG,ptr2 As LONG
DIM bs(15&) As BYTE
DIM struc(0& to 3&) As LONG
DIM FD_SET(0& TO 1&) As LONG,TimeType(0& to 1&) As LONG
DIM str1 As STRING

TYPE RSocket Extends QSocket
 
FUNCTION GetPeerName(S As LONG) As STRING
  Result="": arg=16&
  num=getpeernamex(S,VARPTR(bs(0&)),VARPTR(arg))
  IF num<0& THEN Exit Function
  IF arg<1& THEN Exit Function
  Result=STR$(bs(4&))+"."+STR$(bs(5&))+"."+STR$(bs(6&))+"."+STR$(bs(7&))
END FUNCTION
    
FUNCTION AddrByName(strName As STRING) As STRING
  Result=""
  ptr1=gethostbyname(strName)
  If ptr1=0& Then Exit Function  'Can't get Host by Name
  CopyMemory @struc(0&),ptr1,16&
  If RIGHT$(hex$(struc(2&)),2&) <> "02" THEN	
    Exit Function	'A non-IP address was returned.
  Else
    CopyMemory @ptr2,struc(3&),4&
    CopyMemory @num,ptr2,4&
    ptr1=inet_ntoa(num)
    str1=Space$(lstrlen(ptr1))
    num=lstrcpy(VARPTR(str1),ptr1)
  End If
  Result=str1
END FUNCTION

FUNCTION NameByAddr(strIP As STRING) As STRING
  Result=""
  num=inet_addr(strIP)
  IF num=&HFFFFFFFF THEN Exit Function
  ptr1=gethostbyaddr(@num,4&,2&)
  If ptr1=0& Then
    Exit Function    'Could not get name for the IP
  Else
    CopyMemory @struc(0&),ptr1,16&
    str1=Space$(lstrlen(struc(0&)))
    num=lstrcpy(VARPTR(str1),struc(0&))
    Result=RTRIM$(str1)
  End If
END FUNCTION

FUNCTION S As LONG
  Result=socket(RSocket.Family,RSocket.Type,RSocket.Protocol)
END FUNCTION

FUNCTION Close(S As LONG) As LONG
  Result=closesocket(S)
END FUNCTION

FUNCTION NonBlock(S As LONG) As LONG
  arg=1&: Result=ioctlsocket(S,&H8004667E,@arg)
END FUNCTION

FUNCTION Block(S As LONG) As LONG
  arg=0&: Result=ioctlsocket(S,&H8004667E,@arg)
END FUNCTION
                
FUNCTION Connect(S As LONG,Remote As STRING,Port As INTEGER) As LONG 
  Result=-1&
  Struc(0)=RSocket.Family  
  num=htons(Port)
  ptr1=VARPTR(Struc(0))+2&
  CopyMemory ptr1,VARPTR(num),2& 
  struc(1&)=inet_addr(Remote)
  IF struc(1&)=&HFFFFFFFF THEN Exit Function
  struc(2&)=0&: struc(3&)=0&
  Result=connectx(S,VARPTR(struc(0&)),16&)
END FUNCTION

FUNCTION IsConnected(S As LONG,Secs As LONG) As LONG
  Result=-1&
  FD_SET(0)=1&: FD_SET(1)=S: arg=0&: TimeType(0&)=Secs: TimeType(1&)=0&
  num=selectx(0&,arg,arg,VARPTR(FD_SET(0&)),VARPTR(TimeType(0&)))
  IF FD_SET(0&)=1& THEN EXIT FUNCTION
  FD_SET(0&)=1&: FD_SET(1&)=S
  Result=selectx(0&,arg,VARPTR(FD_SET(0&)),arg,VARPTR(TimeType(0&)))
END FUNCTION

FUNCTION EndConnection(S As LONG) As LONG
  Result=shutdown(S,2&)
END FUNCTION    

FUNCTION LastError As STRING
  arg=WSAGetLastError
  Select Case arg
  Case 10004&: Result="Interrupted system call."
  Case 10009&: Result="Bad socket number."
  Case 10013&: Result="Permission Denied."
  Case 10014&: Result="Bad Address."
  Case 10022&: Result="Invalid Argument."
  Case 10024&: Result="Too many sockets."
  Case 10035&: Result="Operation would block."
  Case 10036&: Result="Operation now in progress."
  Case 10037&: Result="Operation already in progress."
  Case 10038&: Result="Socket operation on nonsocket."
  Case 10039&: Result="Destination address required."
  Case 10040&: Result="Message too long."
  Case 10041&: Result="Protocol wrong type for socket."
  Case 10042&: Result="Protocol not available."
  Case 10043&: Result="Protocol not supported."
  Case 10044&: Result="Socket type not supported."
  Case 10045&: Result="Operation not supported on socket."
  Case 10046&: Result="Protocol family not supported."
  Case 10047&: Result="Address family not supported by protocol family."
  Case 10048&: Result="Address already in use."
  Case 10049&: Result="Can't assign requested address."
  Case 10050&: Result="Network is down."
  Case 10051&: Result="Network is unreachable."
  Case 10052&: Result="Network dropped connection."
  Case 10053&: Result="Software caused connection abort."
  Case 10054&: Result="Connection reset by peer."
  Case 10055&: Result="No buffer space available."
  Case 10056&: Result="Socket is already connected."
  Case 10057&: Result="Socket is not connected."
  Case 10058&: Result="Can't send after socket shutdown."
  Case 10059&: Result="Too many references: can't splice."
  Case 10060&: Result="Connection timed out."
  Case 10061&: Result="Connection refused."
  Case 10062&: Result="Too many levels of symbolic links."
  Case 10063&: Result="File name too long."
  Case 10064&: Result="Host is down."
  Case 10065&: Result="No route to host."
  Case 10066&: Result="Directory not empty."
  Case 10067&: Result="Too many processes."
  Case 10068&: Result="Too many users."
  Case 10069&: Result="Disk quota exceeded."
  Case 10070&: Result="Stale NFS file handle."
  Case 10071&: Result="Too many levels of remote in path."
  Case 10091&: Result="Network subsystem is unusable."
  Case 10092&: Result="Winsock DLL cannot support this application."
  Case 10093&: Result="Winsock not initialized."
  Case 10101&: Result="Disconnect."
  Case 11001&: Result="Host not found."
  Case 11002&: Result="Nonauthoritative host not found."
  Case 11003&: Result="Nonrecoverable error."
  Case 11004&: Result="Valid name,no data record of requested type."
  Case Else:  Result="Unknown error."
  End Select
  Result=str$(arg)+" "+Result
END FUNCTION

FUNCTION WriteLine(S As LONG,str As STRING) As LONG
str1=str+CHR$(13?)+CHR$(10?)
Result=send(S,str1,len(str1),0&)
END FUNCTION

END TYPE
