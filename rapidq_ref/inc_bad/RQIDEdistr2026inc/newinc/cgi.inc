' ---------------------------------------------------------------------------------------------------------------
' CGI.INC version 1.0  
' By Nick Ruisi
' Acknowledgements to Kevin O'Brien (Author of CGI4VB) for the idea
'
' 
'----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
dim pairs (2,256) as string,CgiValue as string,rawp(256) as string, strTitle as string, newBlock$ as string  
dim strpointer(256) as integer, x as integer,r as integer

dim CGI_Accept            As String
dim CGI_AuthType          As String
dim CGI_ContentLength     As String
dim CGI_ContentType       As String
dim CGI_Cookie            As String
dim CGI_GatewayInterface  As String
dim CGI_PathInfo          As String
dim CGI_PathTranslated    As String
dim CGI_QueryString       As String
dim CGI_Referer           As String
dim CGI_RemoteAddr        As String
dim CGI_RemoteHost        As String
dim CGI_RemoteIdent       As String
dim CGI_RemoteUser        As String
dim CGI_RequestMethod     As String
dim CGI_ScriptName        As String
dim CGI_ServerSoftware    As String
dim CGI_ServerName        As String
dim CGI_ServerPort        As String
dim CGI_ServerProtocol    As String
dim CGI_UserAgent         As String
dim lContentLength As Long

defint d

'--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub SendFooter (void)
    print "</BODY></HTML>"
end sub
'----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub SendB (strData as string)
    print strData;
end sub
'---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub SendHeader(strTitle as string)
    print "Status: 200 OK"
    print "Content-Type:text/html"
    print chr$(13)
    print "<!DOCTYPE HTML PUBLIC ";chr$(34);"-//IETF//DTD HTML//EN";chr$(34);">"
    print "<HTML>"
    print "<HEAD><TITLE>";strTitle;"</TITLE></HEAD>"
    print "<BODY>"
end sub
'-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function GetCgiValue (Param as string) as string
  for i = 1 to 256
    if pairs(0, i) = Param then
      GetCgiValue = pairs(1, i)
      exit function
    end if
  next i
end function
'------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub InitCgi(void)

CGI_Accept = ENVIRON$("HTTP_ACCEPT")
CGI_AuthType = ENVIRON$("AUTH_TYPE")
CGI_ContentLength = ENVIRON$("CONTENT_LENGTH")
CGI_ContentType = ENVIRON$("CONTENT_TYPE")
CGI_Cookie = ENVIRON$("HTTP_COOKIE")
CGI_GatewayInterface = ENVIRON$("GATEWAY_INTERFACE")
CGI_PathInfo = ENVIRON$("PATH_INFO")
CGI_PathTranslated =ENVIRON$("PATH_TRANSLATED")
CGI_QueryString = ENVIRON$("QUERY_STRING")
CGI_Referer = ENVIRON$("HTTP_REFERER")
CGI_RemoteAddr = ENVIRON$("REMOTE_ADDR")
CGI_RemoteHost = ENVIRON$("REMOTE_HOST")
CGI_RemoteIdent = ENVIRON$("REMOTE_IDENT")
CGI_RemoteUser = ENVIRON$("REMOTE_USER")
CGI_RequestMethod = ENVIRON$("REQUEST_METHOD")
CGI_ScriptName = ENVIRON$("SCRIPT_NAME")
CGI_ServerSoftware = ENVIRON$("SERVER_SOFTWARE")
CGI_ServerName = ENVIRON$("SERVER_NAME")
CGI_ServerPort = ENVIRON$("SERVER_PORT")
CGI_ServerProtocol = ENVIRON$("SERVER_PROTOCOL")
CGI_UserAgent = ENVIRON$("HTTP_USER_AGENT")
lContentLength = VAL(CGI_ContentLength)
'    
'
' parse the data sent from the form, extracting fields from the & separator
'
  if CGI_REQUESTMETHOD = "POST" then
    ContentLen = VAL(ENVIRON$("CONTENT_LENGTH"))
    CGI_QUERYSTRING = GET$(ContentLen)
  end if
  qslength = len(CGI_QUERYSTRING)
  x=1    
  newBlock$ = ""
  for i = 1 to qslength
    kar$ = mid$(CGI_QUERYSTRING, i, 1)
    select case kar$ 
           case "&"
           rawp(x) = newBlock$
           newBlock$ = ""
           x = x + 1
	case "+"
        newBlock$ = newBlock$ + " "  ' substitute space for the plus sign
   case "%"   
if mid$(CGI_QUERYSTRING,i,3)="%3A" then
        newBlock$ = newBlock$ + ":"
	d=2
	elseif mid$(CGI_QUERYSTRING,i,3)="%2F" then
	newBlock$ = newBlock$ + "/"
	d=2
	end if 
	case else
	if d>0 then d=d-1:goto 5
       newBlock$ = newBlock$ + kar$
5      end select
next i   
rawp(x) = newBlock$
'
' plug both sides of the equal sign (name and value) into the pairs array
'
  for r = 1 to x
    linelength = len(rawp(r))
    for g = 1 to linelength 
      kar$ = Mid$(rawp(r), g, 1)
      if kar$ = "=" then 
        pairs(0, r) = Mid$(rawp(r), 1, g-1)
        pairs(1, r) = Mid$(rawp(r), g+1, len(rawp(r))-g)
	exit for
      end if 
    next g 
  next r

end sub

' ------------------------------------------------------------------------------------------------------------------------------------------------------------------
  