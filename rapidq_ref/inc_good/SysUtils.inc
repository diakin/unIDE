$DEFINE __RQSYSUTILS

Function ExtractFileName(File As String) As String
   Defint Sl,i
   If File = "" then Exit Function
   Sl = 0
   For i = 1 to Len(File)
       If File[i] = "\" then Sl = i
   Next i
   If Sl = 0 then
      Result = File
   Else
      Result = Mid$(File,Sl + 1,Len(File))
   End If
End Function

Function ExtractFilePath(File As String) As String
   Defint Sl,i
   If File = "" then Exit Function
   Sl = 0
   For i = 1 to Len(File)
       If File[i] = "\" then Sl = i
   Next i
   If Sl = 0 then
      Result = ""
   Else
      Result = Mid$(File,1,Sl -1)
   End If
End Function

Function ExtractFileExt(File As String) As String
   Defint Pt,i
   If File = "" then Exit Function
   Pt = 0
   For i = 1 to Len(File)
       If File[i] = "." then Pt = i
   Next i
   If Pt = 0 then
      Result = ""
   Else
      Result = Mid$(File,Pt + 1,Len(File))
   End If
End Function

Function DelFileExt(File As String) As String
   Defint Pt,i
   If File = "" then Exit Function
   Pt = 0
   For i = 1 to Len(File)
       If File[i] = "." then Pt = i
   Next i
   If Pt = 0 then
      Result = File
   Else
      Result = Mid$(File,1,Pt - 1)
   End If
End Function

Function ChangeFileExt(File As String,Ext As String) As String
   Defint Pt,i
   If File = "" then Exit Function
   Pt = 0
   For i = 1 to Len(File)
       If File[i] = "." then Pt = i
   Next i
   If Pt = 0 then
      If Len(File) > 0 then
         If InStr(Ext,".") then
            Result = File + Ext
         Else
            If Len(Ext) Then
               Result = File + "." + Ext
            Else
               Result = File  + Ext
            End If
         End If
      Else
         Result = File
      End If
   Else
      If InStr(Ext,".") then
         Result = Mid$(File,1,Pt -1) + Ext
      Else
         If Len(Ext) Then
            Result = Mid$(File,1,Pt -1) + "." + Ext
         Else
            Result = Mid$(File,1,Pt -1) + Ext
         End If
      End If
   End If
End Function

Function Trim$(s As String) As String
    Result = LTrim$(RTrim$(s)) -Chr$(10)-Chr$(13)
End Function

Function LoWord(Value As Long) As Integer
    If (Value And &H8000) = 0 Then
       Result = Value And &HFFFF
    Else
       Result = Value Or &HFFFF0000
    End If
End Function

Function HiWord(Value As Long) As Integer
    Result = (Value And  &HFFFF0000) \ &H10000
End Function

Function MakeLong(a As Word, b As Word) As Long
   Result = (a or b) shl 16
End Function

Function SysErrorMessage(Error As Integer) As String
     Dim Buffer As String
     Buffer = Space$(256)
     $IFDEF __WIN32API
     FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM, 0, Error, LANG_NEUTRAL, @Buffer, 200, 0)
     $ENDIF
     Result = RTrim$(Buffer)
End Function
