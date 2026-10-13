$ESCAPECHARS ON

'ChangeFileExt:
'Returns: String
'Parameters:
'FileName (String): Name of file with old extention
'NewExt (String): New extention. This must include the leading ".".

'Information:
'Author: Taj Morton
'Email: tmorton at linuxmail dot org.
'License: Public Domain

'Description:
'Changes the extention of FileName to NewExt. For example:
'ChangeFileExt("File.bas", ".inc")
'returns File.inc. This function does not delete the old string,
'instead, it simply returns a new one with the extention.
'You must include the leading "." for it to be added, as it is not
'done by the function.

FUNCTION ChangeFileExt(FileName as String, NewExt as STRING) as STRING
	DIM Returns as STRING
	DIM CurrentExt as String
	DIM CurrentExtLoc as INTEGER
	DIM FileNoExt as STRING
	
	CurrentExtLoc = RInStr(FileName, ".")
	CurrentExt = MID$(FileName, CurrentExtLoc, LEN(FileName))
	FileNoExt = DELETE$(FileName, CurrentExtLoc, LEN(FileName))
	
	Result = INSERT$(NewExt, FileNoExt, LEN(FileName))
	ChangeFileExt = Result
END FUNCTION

'ExtractFileName:
'Returns: String
'Parameters:
'FileName (String): File with full path

'Information:
'Author: Taj Morton
'Email: tmorton at linuxmail dot org.
'License: Public Domain

'Description:
'ExtractFileName takes a file name with a path and returns only
'the file name. For example:
'ExtractFileName("C:\\Program Files\\AFile.bas")
'returns AFile.bas. You can use either two back-slashes or a single
'forward slash (/) for folder seperators.
'Both forward and back-slashes are supported by Windows.
'The back-slash takes procedure over the forward slash.
'Note that ExtractFileName does _not_ check the validity of the path passed.
'You must check yourself.

FUNCTION ExtractFileName(FileName as STRING) AS STRING
	DIM Length as INTEGER
	DIM Result as STRING
	
	Length = RInStr(FileName, "\\") OR RInStr(FileName, "/")
	Result = MID$(FileName, Length+1, LEN(FileName) - Length + 1)
	ExtractFileName = Result
END FUNCTION

'ExtractFilePath
'Returns: String
'Parameters:
'FileName (String): File with full path

'Information:
'Author: Taj Morton
'Email: tmorton at linuxmail dot org.
'License: Public Domain

'Description:
'ExtractFilePath takes string with full path and returns a string
'with only the path. For example:
'ExtractFilePath("C:\\Program Files\\AProgram.bas")
'returns C:\Program Files (the \\'s are for RQ and back-slashes).
'ExtractFilePath also takes forward-slashes (/). Window's supports
'these as well. 
'The back-slash takes procedure over the forward slash.
'Note that ExtractFilePath does _not_ test the validity
'of the passed name. You must check it yourself. Even if the name is
'invalid, the path will be returned. For example, if C:/ProgramErrorFiles/AFile.txt
'is passed, C:/ProgramErrorFiles will be returned.

FUNCTION ExtractFilePath(FileName as STRING) AS STRING
	DIM Length as INTEGER
	DIM Result as STRING
	
	Length = RInStr(FileName, "\\") OR RInStr(FileName, "/")
	Result = MID$(FileName, 0, Length)
	ExtractFilePath = Result
END FUNCTION

'ChangeFileName
'Returns: String
'Parameters:
'FileName (String): File with full path
'NewName (String): Text that will replace old file name

'Information:
'Author: Taj Morton
'Email: tmorton at linuxmail dot org.
'License: Public Domain

'Description:
'ChangeFileName takes a file name with full path and file and a new name.
'It replaces the current filename (in FileName) and replaces it with NewName.
'ChangeFileName does not actually change FileName, instead it returns a new
'string which contains the new name.
'Note that ChangeFileName does not check the validity of FileName
'or the new result. You must do it yourself (if you want). ChangeFileName
'takes both the back-slash and forward slash to serperate folder and file names.
'You can use either \\ or /. Both are supported by Windows.
'The back-slash takes procedure over the forward slash.

FUNCTION ChangeFileName(FileName as STRING, NewName as STRING) AS STRING
	DIM FileNameLoc as INTEGER
	DIM Result as STRING
	DIM PathNoName AS STRING
	
	PathNoName = ExtractFilePath(FileName)
	Result = PathNoName+NewName
	ChangeFileName = Result
END FUNCTION

'ChangeFilePath
'Returns: String
'Parameters:
'FileName (String): File with full path
'NewPath (String): New path that will replace the path in FileName

'Information:
'Author: Taj Morton
'Email: tmorton at linuxmail dot org.
'License: Public Domain

'Description:
'ChangeFilePath takes FileName and replaces the path with NewPath.
'It does not change FileName to have the new path, instead, it returns
'a string which has the new path. It's up to you to take the correct
'action. Also, old or new path and names' are not checked for validity,
'you must do it yourself.
'You may use either the \\ or the / to seperate your paths. Windows supports
'both. 

FUNCTION ChangeFilePath(FileName as STRING, NewPath as STRING) AS STRING
	DIM Result AS STRING
	DIM FileNoPath AS STRING
	
	FileNoPath = ExtractFileName(FileName)
	
	Result = NewPath+FileNoPath
	ChangeFilePath = Result
END FUNCTION  