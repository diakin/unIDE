'v2 :)
'added speedlbl as qlabel, similar to stategauge
'added speed function
TYPE Qdownload extends qobject
file as string                                      '    /Path/File.ext
server as string                                    '    www.server.dom
port as integer                                     '    Port: 80



outdevice as integer                                '    Outdevice:   1 = qdownload.outvar (Default)
                                                    '                 2 = qdownload.filestream


statedevice as integer                              '    Statedevice: 1 = qdownload.state (Default)
                                                    '                 2 = qdownload.stategauge

outvar as string                                    '    String containing downloaded file
outfile as string                                   '    File downloaded data will be saved in
                                                    '    Specify Path and Filename!

state as integer                                    '    State of Download in Percent
stategauge as qgauge                                '    State as qgauge
                                                    '    Properties are your job!
                                                    '    qdownload.stategauge.parent = form etc.!

speedlbl as qlabel


laststringerror as string                           '    Errortext output
lasterror as integer                                '    Error Number 

size as integer                                     '    Size of File, retreived during download


				    	    '    Loop Variable

Constructor                                         
port = 80                                           '    Defaultport is set 80 (HTTP)
outdevice = 1                                       '    Default for outfile is qdownload.outvar
statedevice = 1                                     '    Default for state is qdownload.state
stategauge.height = 20
stategauge.width = 200
end constructor


'This Function checks for an internet connection, and returns either True or False

FUNCTION check AS LONG
 DIM Registry AS QRegistry 

 Registry.RootKey = &H80000002 
 Registry.OpenKey("System\CurrentControlSet\Services\RemoteAccess", 0) 
with qdownload
 IF Registry.ReadBinary("Remote Connection", -1) = 1 THEN 
  .check = True 
 ELSE 
  .check = False
 END IF 
end with
END  FUNCTION


'This Function calculates the state in percent of any given process

function percent(now as long, complete as long) as integer
with qdownload
.percent = round(now*100/complete)
end with
end function

'This Function calculates the speed in B of any given process

function speed(now$ as string, before$ as string, complete as long) as integer
dim sec as integer
sec=val(field$(now$,":",3))+val(field$(now$,":",2))*60+val(field$(now$,":",1))*3600-val(field$(before$,":",3))-val(field$(before$,":",2))*60-val(field$(before$,":",1))*3600
with qdownload
.speed = round(complete/sec)
end with
end function

'This Function GETs a file from a HTTP Server and/or returns an errorcode if necessary

function leechfile as long
with qdownload
.leechfile=False
dim sock as qsocket                'The Socket
dim socknum as integer             'The Socket handle
 
dim downstate as integer           'Reading Header (1) or Body(2) 
downstate = 1
dim content$ as string             'Downloaded File in current state 
dim Llo as integer 

'Error checking section 
 
if .server="" then 
.laststringerror = "No Server Specified"
.lasterror = 1
exit function
end if

if .port = 0 then 
.laststringerror = "No Serverport Specified"
.lasterror = 2
exit function
end if

if .file = "" then
.laststringerror = "No File Specified"
.lasterror = 3
exit function
end if

if .outdevice = 2 and .outfile="" then
.laststringerror = "No Outputfile Specified"
.lasterror = 4
exit function
end if


'Now let's connect
socknum = sock.connect (.server, .port)

'error checking
if socknum = -1 then
select case .check
case True
.laststringerror = "No Connection to specified host could be established"
.lasterror = 5
case False
.laststringerror = "You are not connected to the internet"
.lasterror = 6
end select
exit function
end if 

'sending HTTP request and error checking
if sock.writeline (socknum, "GET /"+.file+" HTTP/1.0") = False then
select case .check
case True
 select case sock.transferred
 case is < 0
  .laststringerror = "Connection closed by peer"
  .lasterror = 7
  sock.close(socknum)
 case else
  .laststringerror = "No idea what's wrong"
  .lasterror = 8
  sock.close(socknum)
 end select
case False
.laststringerror = "You are not connected to the internet"
.lasterror = 6
end select
exit function
end if

if sock.writeline (socknum, "") = False then
select case .check
case True
 select case sock.transferred
 case is < 0
  .laststringerror = "Connection closed by peer"
  .lasterror = 7
  sock.close(socknum)
 case else
  .laststringerror = "No idea what's wrong"
  .lasterror = 8
  sock.close(socknum)
 end select
case False
.laststringerror = "You are not connected to the internet"
.lasterror = 6
end select
exit function
end if


'The Download
dim i as integer
dim bf$ as string
bf$=time$    ' start time
do
  if downstate  = 1 then                        'Header reading section
   content$=sock.readline(socknum)
     if mid$(content$, 1, 12)="HTTP/1.0 404" then
        .lasterror = 11
        .laststringerror = "The Server doesn't know the file"
        sock.close(socknum)
        exit function
     end if
     if mid$(content$, 1, 12)="HTTP/1.1 404" then
        .lasterror = 11
        .laststringerror = "The Server doesn't know the file"
        sock.close(socknum)
        exit function
     end if


   dim info$ as string
   info$ = left$(content$,15)
   if  info$ = "Content-Length:" then
    .size=val(right$(content$, len(content$)-16))
    if .size=0 then
       .lasterror = 9
       .laststringerror = "Filesize couldn't be determined, or file is 0 bytes long"
       sock.close(socknum)
     exit function     
    end if 
   end if

   if len(content$)=1 then                     'Header Ready, entering body-reading section
    downstate = 2                        
    content$=""    
   end if
  else                                         'Body reading section
   content$ = content$+sock.Read(socknum, 32000) 
   select case .statedevice
   case 2
   .stategauge.position = .percent(len(content$), .size)
   .speedlbl.caption=str$(.speed(time$,bf$,len(content$)))+" B/s"
   case else
   .state = .percent(len(content$), .size)
   end select
  end if
loop until sock.transferred = 0
sock.close(socknum)


'error checking
if not .size=len(content$) then
.lasterror = 10
.laststringerror = "A transmission error has occured, retry"
exit function
end if




'Saving to File or to .outvar 
select case .outdevice
case 2
dim outputfile as qfilestream
outputfile.open (.outfile, fmCreate)
outputfile.write (content$)
outputfile.close
case else
.outvar = content$
end select

'That's it, thanks
.leechfile=True
end with
end function


end type
