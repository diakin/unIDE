Const IP_STATUS_BASE = 11000
Const IP_SUCCESS = 0
Const IP_BUF_TOO_SMALL = (11000 + 1)
Const IP_DEST_NET_UNREACHABLE = (11000 + 2)
Const IP_DEST_HOST_UNREACHABLE = (11000 + 3)
Const IP_DEST_PROT_UNREACHABLE = (11000 + 4)
Const IP_DEST_PORT_UNREACHABLE = (11000 + 5)
Const IP_NO_RESOURCES = (11000 + 6)
Const IP_BAD_OPTION = (11000 + 7)
Const IP_HW_ERROR = (11000 + 8)
Const IP_PACKET_TOO_BIG = (11000 + 9)
Const IP_REQ_TIMED_OUT = (11000 + 10)
Const IP_BAD_REQ = (11000 + 11)
Const IP_BAD_ROUTE = (11000 + 12)
Const IP_TTL_EXPIRED_TRANSIT = (11000 + 13)
Const IP_TTL_EXPIRED_REASSEM = (11000 + 14)
Const IP_PARAM_PROBLEM = (11000 + 15)
Const IP_SOURCE_QUENCH = (11000 + 16)
Const IP_OPTION_TOO_BIG = (11000 + 17)
Const IP_BAD_DESTINATION = (11000 + 18)
Const IP_ADDR_DELETED = (11000 + 19)
Const IP_SPEC_MTU_CHANGE = (11000 + 20)
Const IP_MTU_CHANGE = (11000 + 21)
Const IP_UNLOAD = (11000 + 22)
Const IP_ADDR_ADDED = (11000 + 23)
Const IP_GENERAL_FAILURE = (11000 + 50)
Const MAX_IP_STATUS = 11000 + 50
Const IP_PENDING = (11000 + 255)

$IFNDEF inet_addr
Declare FUNCTION inet_addr Lib "wsock32.dll" Alias "inet_addr"_
  (ByVal cp As String) As LONG
$ENDIF
Declare FUNCTION IcmpCreateFile Lib "icmp.dll" Alias "IcmpCreateFile" ()_
  As Long
Declare FUNCTION IcmpCloseHandle Lib "icmp.dll" Alias "IcmpCloseHandle"_
  (IcmpHandle As Long) As Long
Declare FUNCTION IcmpSendEcho Lib "icmp.dll" Alias "IcmpSendEcho"_
  (IcmpHandle As Long, DestinationAddress As Long, RequestData As String,_
  RequestSize As Integer, ptrRequestOptions As Long, ptrReplyBuffer As LONG,_
  ReplySize As Long, Timeout As Long) As Long

'Two structures -- ReqOpts and Reply -- are used in API calls and are
'implemented as arrays for tight, contiguous memory representation since
'type structures may not be stored contiguously by RapidQ basic.

Type QICMP Extends QObject
  TimeOut As LONG
  'ReqOpts are TTL, TOS, Flags, OptionsSize as bytes; ptrOptions as Long
  ReqOpts(7) As BYTE 
  EchoString As STRING
  Reply(0 to 70) As LONG
  '0 = Address that replied; 1 = Status (0 if echo OK); 2 = RoundTripTime in ms
  '3 = DataSize as integer and Reserved as integer; 4 = ptr to Data
  '5 = Options ; 6 = ptr to Options Data
  '7 - 70 = Data as string *256
  h As LONG
  constRUCTOR
    EchoString = "Echo This"
    TimeOut = 3500
    ReqOpts(0) = 255
    ReqOpts(1) = 0
    ReqOpts(2) = 0
    ReqOpts(3) = 0
    ReqOpts(4) = 0
    ReqOpts(5) = 0
    ReqOpts(6) = 0
    ReqOpts(7) = 0
  END constRUCTOR  

FUNCTION Ping(RemoteIP As String) AS LONG
DIM dwAddress As LONG, ret As LONG
Result = -1
IF qicmp.h = 0 THEN qicmp.h = IcmpCreateFile
IF qicmp.h = 0 THEN Exit Function
dwAddress = inet_addr(RemoteIP)
IF dwAddress = &HFFFFFFFF THEN Exit Function
For ret = 0 to 70: qicmp.Reply(ret) = 0: next ret

ret = IcmpSendEcho(qicmp.h, dwAddress, qicmp.EchoString, Len(qicmp.EchoString),_
  VARPTR(qicmp.ReqOpts(0)), VARPTR(qicmp.Reply(0)), 284, qicmp.TimeOut)
IF ret = 1 THEN Result = qicmp.Reply(2)
END FUNCTION

FUNCTION ReplyAddress as String
Dim str As STRING, str1 As STRING
Result = ""
IF qicmp.Reply(0) = 0 THEN Exit Function
str = HEX$(qicmp.Reply(0))
str1 = CONVBASE$(MID$(str,7,2),16,10)
IF str1 = "" THEN str1 = "0"
Result = str1+"."
str1 = CONVBASE$(MID$(str,5,2),16,10)
IF str1 = "" THEN str1 = "0"
Result = Result+str1+"."
str1 = CONVBASE$(MID$(str,3,2),16,10)
IF str1 = "" THEN str1 = "0"
Result = Result+str1+"."
str1 = CONVBASE$(MID$(str,1,2),16,10)
IF str1 = "" THEN str1 = "0"
Result = Result+str1
END FUNCTION

FUNCTION ReplyStatus As String
Dim msg As String
Select Case qicmp.Reply(1)
  Case IP_SUCCESS:               msg = "ip success"
  Case IP_BUF_TOO_SMALL:         msg = "ip buf too_small"
  Case IP_DEST_NET_UNREACHABLE:  msg = "ip dest net unreachable"
  Case IP_DEST_HOST_UNREACHABLE: msg = "ip dest host unreachable"
  Case IP_DEST_PROT_UNREACHABLE: msg = "ip dest prot unreachable"
  Case IP_DEST_PORT_UNREACHABLE: msg = "ip dest port unreachable"
  Case IP_NO_RESOURCES:          msg = "ip no resources"
  Case IP_BAD_OPTION:            msg = "ip bad option"
  Case IP_HW_ERROR:              msg = "ip hw_error"
  Case IP_PACKET_TOO_BIG:        msg = "ip packet too_big"
  Case IP_REQ_TIMED_OUT:         msg = "ip req timed out"
  Case IP_BAD_REQ:               msg = "ip bad req"
  Case IP_BAD_ROUTE:             msg = "ip bad route"
  Case IP_TTL_EXPIRED_TRANSIT:   msg = "ip ttl expired transit"
  Case IP_TTL_EXPIRED_REASSEM:   msg = "ip ttl expired reassem"
  Case IP_PARAM_PROBLEM:         msg = "ip param_problem"
  Case IP_SOURCE_QUENCH:         msg = "ip source quench"
  Case IP_OPTION_TOO_BIG:        msg = "ip option too_big"
  Case IP_BAD_DESTINATION:       msg = "ip bad destination"
  Case IP_ADDR_DELETED:          msg = "ip addr deleted"
  Case IP_SPEC_MTU_CHANGE:       msg = "ip spec mtu change"
  Case IP_MTU_CHANGE:            msg = "ip mtu_change"
  Case IP_UNLOAD:                msg = "ip unload"
  Case IP_ADDR_ADDED:            msg = "ip addr added"
  Case IP_GENERAL_FAILURE:       msg = "ip general failure"
  Case IP_PENDING:               msg = "ip pending"
  Case Else:                     msg = "unknown  msg returned"
END Select
Result = msg
END FUNCTION

FUNCTION ReplyData As STRING
IF qicmp.Reply(2)>0 THEN Result = VARPTR$(qicmp.Reply(4)) ELSE Result=""
END FUNCTION

FUNCTION ReplyTTL AS LONG
Dim str As STRING
str = HEX$(qicmp.Reply(5))
Result= VAL(CONVBASE$(MID$(str,7,2),16,10))
END FUNCTION

FUNCTION CloseHandle As LONG
IF qicmp.h <= 0 THEN Result = -1 ELSE Result = IcmpCloseHandle(qicmp.h)
END FUNCTION

END TYPE
  