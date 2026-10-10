TYPE Qdownload EXTENDS QOBJECT
	File AS STRING                                      '    /Path/File.ext
	Server AS STRING                                    '    www.server.dom
	Port AS INTEGER                                     '    Port: 80
	Outdevice AS INTEGER                                '    Outdevice:   1 = qdownload.outvar (Default)
                                                        '                 2 = qdownload.filestream
	Statedevice AS INTEGER                              '    Statedevice: 1 = qdownload.state (Default)
	                                                    '                 2 = qdownload.stategauge
	Outvar AS STRING                                    '    String containing downloaded file
	Outfile AS STRING                                   '    File downloaded data will be saved in
	                                                    '    Specify Path and Filename!
	State AS INTEGER                                    '    State of Download in Percent
	Stategauge as qgauge                                '    State as qgauge
	                                                    '    Properties are your job!
	                                                    '    qdownload.stategauge.parent = form etc.!
	LastStringError AS STRING                           '    Errortext output
	LastError AS INTEGER                                '    Error Number 
	Size AS INTEGER                                     '    Size of File, retreived during download

				    	    '    Loop Variable

CONSTRUCTOR
	Port = 80                                           '    Defaultport is set 80 (HTTP)
	OutDevice = 1                                       '    Default for outfile is qdownload.outvar
	StateDevice = 1                                     '    Default for state is qdownload.state
	StateGauge.height = 20
	StateGauge.width = 200
END CONSTRUCTOR




'***********************************************************************************
'This Function checks for an internet connection, and returns either True or False
'***********************************************************************************
FUNCTION check AS LONG
 	DIM Registry AS QRegistry 

 	Registry.RootKey = &H80000002 
 	Registry.OpenKey("System\CurrentControlSet\Services\RemoteAccess", 0) 
	
	WITH Qdownload
 	IF Registry.ReadBinary("Remote Connection", -1) = 1 THEN 
  		.check = True 
 	ELSE 
  		.check = False
 	END IF 
	END WITH
END  FUNCTION


'***********************************************************************************
'This Function calculates the state in percent of any given process
'***********************************************************************************
FUNCTION percent(now as long, complete as long) AS INTEGER
	with qdownload
	.percent = int(now/(complete/100))
	end with
end FUNCTION


'***********************************************************************************
'This Function GETs a file from a HTTP Server and/or returns an errorcode if necessary
'***********************************************************************************
FUNCTION leechfile AS LONG
with qdownload
	.leechfile=False
	dim sock as qsocket                'The Socket
	dim socknum AS INTEGER             'The Socket handle
 
	dim downstate AS INTEGER           'Reading Header (1) or Body(2) 
	downstate = 1
	dim content$ AS STRING             'Downloaded File in current state 
	dim Llo AS INTEGER 

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



'***********************************************************************************
'The Download
'***********************************************************************************
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


   dim info$ AS STRING
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

'   select case .statedevice
'   case 2
'   .stategauge.position = .percent(len(content$), .size)
'   case else
'   .state = .percent(len(content$), .size)
'   end select
	end if
	loop until sock.transferred = 0
sock.close(socknum)



'error checking
	if not .size=len(content$) then
		.lasterror = 10
		.laststringerror = "A transmission error has occured, retry"
		exit function
	end if



'***********************************************************************************
'Saving to File or to .outvar 
'***********************************************************************************
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
END FUNCTION
END TYPE