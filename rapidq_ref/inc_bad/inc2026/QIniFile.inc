'coded by Nastase Eodor (2008)

$IFNDEF __RQSYSUTILS
$Include "SysUtils.inc"
$ENDIF

$IFNDEF __WIN32API
Declare Function GetWindowsDirectory Lib "kernel32" Alias "GetWindowsDirectoryA" (ByVal lpBuffer As Long, ByVal nSize As Long) As Long
$ENDIF

Type QIniFile Extends QstringList
     Private:
     WindowsDir As String
     Name       As String
     Public:
     File       As String
     
     With This

     
     Public:
     Sub CreateFile(Dir As String)
         .Clear
         .Name = IIf(ExtractFileName(Dir) <> "",ExtractFileName(Dir),"")
         .File = ""
         If ExtractFilePath(Dir) = "" Then
            .File = .WindowsDir & .Name
         Else
            .File = IIf(.Name = "",Dir & .Name,Dir)
         End If
         If FileExists(.File) Then
            .LoadFromFile .File
         Else
            .SaveToFile .File
         End If
     End Sub

     Function SectionExists(Section$) As Integer
         DefInt i
         Result = -1
         For i = 0 To .ItemCount -1
             If .Item(i) <> "" Then
                If .Item(i)[1] = "[" Then
                   If UCase$(.Item(i) -"[" - "]") = UCase$(Section$) Then
                      Result = i
                      Exit For
                   End If
                End If
             End If
         Next i
     End Function
     
     Function KeyExists(Section$,Key$) As Integer
         DefInt i,k
         Result = -1
         i = .SectionExists(Section$)
         If i <> -1 Then
            For k = i +1 To .ItemCount -1
                If .Item(k) <> "" Then
                   If .Item(k)[1] = "[" Then Exit For
                   If UCase$(Field$(.Item(k),"=",1)) = UCase$(Key$) Then
                      Result = k
                      Exit For
                   End If
                End If
            Next k
         End If
     End Function

     Private:
     
     Function GetSectionEnd(Section$) As Integer
         DefInt i
         DefStr s
         Result = .ItemCount -1
         i = .SectionExists(Section$)
         If i <> -1 Then
            Do
               i++
               If i < .ItemCount Then
                  If .Item(i) <> "" Then s = .Item(i)[1]
               End If
            Loop Until s = "[" Or i = .ItemCount
            Result = i
         End If
     End Function
     
     Public:

     Sub WriteInteger(Section$,Key$,Value&)
         DefInt i,k
         If .SectionExists(Section$) <> -1 Then
            k = .KeyExists(Section$,Key$)
            If k <> -1 Then
               .Item(k) = Format$("%s=%d",Key$,Value&)
            Else
               i = .GetSectionEnd(Section$)
               If i = .ItemCount Then
                 .AddItems Format$("%s=%d",Key$,Value&)
               Else
                 .InsertItem i,Format$("%s=%d",Key$,Value&)
               End If
            End If
         Else
            .AddItems Format$("[%s]",Section$)
            .AddItems Format$("%s=%d",Key$,Value&)
         End If
         .SaveToFile .File
     End Sub
     
     Sub WriteFloat(Section$,Key$,Value#)
         DefInt i,k
         If .SectionExists(Section$) <> -1 Then
            k = .KeyExists(Section$,Key$)
            If k <> -1 Then
               .Item(k) = Format$("%s=%g",Key$,Value#)
            Else
               i = .GetSectionEnd(Section$)
               If i = .ItemCount Then
                 .AddItems Format$("%s=%g",Key$,Value#)
               Else
                 .InsertItem i,Format$("%s=%g",Key$,Value#)
               End If
            End If
         Else
            .AddItems Format$("[%s]",Section$)
            .AddItems Format$("%s=%g",Key$,Value#)
         End If
         .SaveToFile .File
     End Sub
     
     Sub WriteString(Section$,Key$,Value$)
         DefInt i,k
         If .SectionExists(Section$) <> -1 Then
            k = .KeyExists(Section$,Key$)
            If k <> -1 Then
               .Item(k) = Format$("%s=%s",Key$,Value$)
            Else
               i = .GetSectionEnd(Section$)
               If i = .ItemCount Then
                 .AddItems Format$("%s=%s",Key$,Value$)
               Else
                 .InsertItem i,Format$("%s=%s",Key$,Value$)
               End If
            End If
         Else
            .AddItems Format$("[%s]",Section$)
            .AddItems Format$("%s=%s",Key$,Value$)
         End If
         .SaveToFile .File
     End Sub
     
     Function ReadInteger(Section$,Key$,Inplace&) As Integer
         DefInt i
         Result = Inplace&
         i = .KeyExists(Section$,Key$)
         If i <> -1 Then Result = Val(Field$(.Item(i),"=",2))
     End Function
     
     Function ReadFloat(Section$,Key$,Inplace#) As Double
         DefInt i
         Result = Inplace#
         i = .KeyExists(Section$,Key$)
         If i <> -1 Then Result = Val(Field$(.Item(i),"=",2))
     End Function
     
     Function ReadString(Section$,Key$,Inplace$) As String
         DefInt i
         Result = Inplace$
         i = .KeyExists(Section$,Key$)
         If i <> -1 Then Result = Field$(.Item(i),"=",2)
     End Function
     
     Sub ReadSection(Section$,Buffer As QStringList)
         DefInt s,es,i
         s  = .SectionExists(Section$)
         If s <> -1 Then
            es = .GetSectionEnd(Section$)
            Buffer.Clear
            For i = s +1 To es -1
              Buffer.AddItems .Item(i)
            Next i
         End If
     End Sub
     
     Sub ReadSections(Buffer As QStringList)
         DefInt i
         Buffer.Clear
         For i = 0 To .ItemCount -1
             If LTrim$(.Item(i)) <> "" Then
                If LTrim$(.Item(i))[1] = "[" Then
                   Buffer.AddItems .Item(i)
                End If
              End If
         Next i
     End Sub
     
     Sub GetWindowsDir
         DefStr lpBuffer = Space$(260)
         DefShort Size
         Size = GetWindowsDirectory(VarPtr(lpBuffer),260)
         .WindowsDir = Left$(lpBuffer,Size) + "\"
     End Sub
     
     End With
     
     Constructor
     GetWindowsDir
     Name = ChangeFileExt(Application.ExeName,".ini")
     End Constructor
End Type
