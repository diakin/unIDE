$IFNDEF __QWININI_INC   ' IncManager: include guard
$DEFINE __QWININI_INC
'Usage:
'       first call to Ini.load([Path/FileName.ini]) Function. Parameter optional
'       to get Values call to ini.Get(Section, Key, default-value) Fuction
'       to write Values call to Ini.Write(Section, Key,Value) Function

'$TypeCheck on

Declare Function GetPrivateProfileString Lib "Kernel32" Alias "GetPrivateProfileStringA" _ 
(lpApplicationName As String, lpKeyName As String, _ 
lpDefault As String, lpReturnedString As long, nSize As Long, lpFileName As String) As Long 

Declare Function WritePrivateProfileString Lib "Kernel32" Alias "WritePrivateProfileStringA" _ 
(ByVal lpApplicationName$, ByVal lpKeyName As String, lpString As String, ByVal lpFileName$) As Long 

Declare Function GetPrivateProfileSection Lib "kernel32" Alias "GetPrivateProfileSectionA" _
(lpAppName As String, lpReturnedString As Long, nSize As Long, lpFileName As String) As Long

TYPE QINI EXTENDS QObject

    File as String
    Section as String
    Key as STRING
    Value as String

    'Find for application.ini Retorn 1 if success 
    'Opcional parameter path of ini file
    'Ini.File content the ini file 

    Functioni Load (...) as integer
        Result  = 0
        With QINI
           if ParamStr$(1)  =  ""  then
              .File = REPLACESUBSTR$(Command$(0), ".EXE", ".INI")
           else
             .File = ParamStr$(1)
           end if
           if FileExists(.File) then
              Result = 1 
           end IF
       end With
    End Function

   'Function to GET information from an INI File
   'Parameter Seccion, Key and default value 
   'Return the value of key
   'Fill Ini.Secttion, ini.key and ini.value

    Function Get(sSection As String, sKey As String, sDefault As String) As String
      Dim LpBuffer as string, iLenght as short, a as short
      lpBuffer = Space$(260)
      With QINI
         if .File = "" then result = "": exit Function
         iLenght = GetPrivateProfileString(sSection, sKey, sDefault, varPTR(lpBuffer), 250, .File)
         if Ilenght then
            .Section = sSection
            .Key = sKey
            .Value = Left$(lpBuffer, ilenght)
            a = instr(.Value,";")
            if a then .Value = ltrim$(rtrim$(left$(.Value,a-1)))
            Result = .Value
          Else
            .Value = sDefault
            Result = .Value
         end if
      end With
    End Function
    
    'Sub  to WRITE information to an INI File
    'Parameters Seccion,Key and value
    'Fill Ini.Section, ini.Key and ini.Value
    'Return no zero if sucess
 
    Function Write(sSection as string, sKey as string, sValue as string) as long
      Dim a as long
      With QINI
         if .File = "" then result = 0: exit Function
         a = WritePrivateProfileString (sSection, sKey, sValue, .File)
         if a <> 0 then
            .Section = sSection
            .Key = sKey
            .Value = sValue
         end if
         Result = a
      end With
    end Function

    Function GetSection (sSection as string) as string
      Dim LpBuffer as string, iLenght as integer, a as integer
      lpBuffer = Space$(1000)
      With QIni
        iLenght = GetPrivateProfileSection (sSection, varPTR(lpBuffer), 1000, .File)
        'showmessage str$(iLenght)
        if Ilenght then
            .Section = sSection
            .Key = ""
            .Value = Left$(lpBuffer, ilenght)
            Result = .Value
         Else
            .Value = ""
            Result = .Value
         end if
      End With
    end Function

  constRUCTOR
    File = ""
    Section = ""
    Key = ""
    Value = ""
  END constRUCTOR

End TYPE
Dim Ini as QIni
  
$ENDIF   ' IncManager: __QWININI_INC
