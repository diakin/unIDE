'************************************************************************************************
'*																
'*	QXpTheme by Nicolas Tillet http://www.membres.lycos.fr/ntillet86     du 10/2003             	
'*																
'************************************************************************************************




	CREATE manifest AS QSTRINGLIST  
		additems "<?xml version="+CHR$(34)+"1.0"+CHR$(34)+" encoding="+CHR$(34)+"UTF-8"+CHR$(34)+" standalone="+CHR$(34)+"yes"+CHR$(34)+"?>"
		additems "<assembly xmlns="+CHR$(34)+"urn:schemas-microsoft-com:asm.v1"+CHR$(34)+" manifestVersion="+CHR$(34)+"1.0"+CHR$(34)+">"
		additems "<assemblyIdentity"
		additems "version = "+CHR$(34)+"1.0.0.0"+CHR$(34)+""
		additems "processorArchitecture = "+CHR$(34)+"X86"+CHR$(34)+""
		additems "name = "+CHR$(34)+"[].[].[]"+CHR$(34)+""
		additems "type="+CHR$(34)+"win32"+CHR$(34)+""
		additems "/>"
		additems "<description></description>"
		additems "<dependency>"
		additems "<dependentAssembly>"
		additems "<assemblyIdentity"
		additems "type="+CHR$(34)+"win32"+CHR$(34)+""
		additems "name = "+CHR$(34)+"Microsoft.Windows.Common-Controls"+CHR$(34)+""
		additems "version = "+CHR$(34)+"6.0.0.0"+CHR$(34)+""
		additems "processorArchitecture = "+CHR$(34)+"X86"+CHR$(34)+""
		additems "publicKeyToken = "+CHR$(34)+"6595b64144ccf1df"+CHR$(34)+""
		additems "language = "+CHR$(34)+"*"+CHR$(34)+"" 
		additems "/>"                  	
		additems "</dependentAssembly>"                  	
		additems "</dependency>"                  	
		additems "</assembly>"                  	
	END CREATE 
	IF FILEEXISTS(Command$ (0)+".manifest")=0 THEN 
		manifest.SaveToFile(Command$ (0)+".manifest")
		RUN Command$ (0) 
		Application.Terminate
	END IF 
