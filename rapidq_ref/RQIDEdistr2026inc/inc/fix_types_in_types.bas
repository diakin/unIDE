'
' ---- Start RapidQ Code ----
'
' -----------------------------------------------------------------------------
' Replaces all Types in Type in ... Windows.Inc       June 5th, 2007    Jacques
' -----------------------------------------------------------------------------
''pre cmd tiny run enc opt exe con kill nobk diricon 'output upx
''pre end
Cls ' Set RQPC Console Patch
'
$ESCAPECHARS ON
$TYPECHECK ON
$INCLUDE "RAPIDQ.INC"
'
DefStr sFileInc = "my include file"    ' set the file to smurf
'
DefInt i, N, P, iTypeCount = 0, iMsg
DefInt iCount, iModif = 0, iTotModif = 0
DefStr sLine, sLine2, sTypeName, sName, sType2, sOut, sTmp
Dim slIn As QStringList
Dim slOut As QStringList
Dim slType As QStringList
slIn.LoadFromFile (sFileInc)
'
' FORMAT FILE LINES:  Tab >> " " and only single space
With slIn
     .LoadFromFile (sFileInc)
     For i = 0 To .ItemCount - 1
         sLine = .Item(i)
         sLine = ReplaceSubStr$(sLine, Chr$(9), " ")
         While Instr(sLine, "  ") <> ""
             sLine = ReplaceSubStr$(sLine, "  ", " ")
         Wend
         .Item(i) = sLine
     Next i
End With
Print "\nFORMAT FILE FINISHED\n"
'
slOut.Clear
slOut.AddList (slIn)
' ============
Do
' ============
iTypeCount = 0
iModif = 0
iTotModif = 0
'
For i = 0 To slIn.ItemCount - 1
     sLine = slIn.Item(i)
     If UCase$(Field$(sLine, " ", 1)) = "TYPE" Then
         Inc iTypeCount
         sTypeName  =  UCase$(Field$(sLine, " ", 2))
         If Left$(sTypeName, 1) = "_" Then sTypeName =  Mid$(sTypeName, 2)
         slType.Clear
         Inc i
         sLine = slIn.Item(i)
         While (Left$(sLine, 1) = " " or sLine = "")
             If (LTrim$(sLine) <> "" And Left$(LTrim$(sLine), 1) <> "'") Then slType.AddItems sLine
             Inc i
             If i = slIn.ItemCount Then Exit While
             sLine = slIn.Item(i)
         Wend
         iCount = 0
         For N = 0 To slOut.ItemCount - 1
             sLine2 = slOut.Item(N)
             If UCase$(Field$(sLine2, " ", 1)) = "TYPE" Then
                 sType2 = Field$(sLine2, " ", 2)
                 Inc N
                 sLine2 = slOut.Item(N)
                 While (sLine2 = "" Or Left$(sLine2, 1) = " ")
                     If sLine2 <> "" Then
                         If Ucase$(Field$(sLine2, " ", 4)) = sTypeName Then
                             sName = Field$(sLine2, " ", 2)
                             slOut.delItems(N)
                             slOut.InsertItem (N, "   ' Start " & sName & " As " & sTypeName)
                             For P = 0 To slType.ItemCount - 1
                                 Inc N
                                 slOut.InsertItem(N, " " & sName & "_" & LTrim$(slType.Item(P)))
                             Next P
                             Inc N
                             slOut.InsertItem (N, "   ' End   " & sName & " As " & sTypeName)
                             Inc iModif
                             Inc iCount
                         End If
                     End If
                     Inc N
                     If N = slOut.ItemCount Then Exit While
                     sLine2 = slOut.Item(N)
                 Wend
             End If
         Next N
         iTotModif = iTotModif + iCount
         sTmp = "At Line: " & Str$(i) & "   Type  \"" & sTypeName & "\"  Replaced  " & Str$(iCount) & "  times"
         Print sTmp
         sOut = sOut & "\n" & sTmp
     End If
     SetConsoleTitle (sTypeName & "  at Line: " & Str$(i))
Next i
'
sTmp = "\nTotal Type Count: " & Str$(iTypeCount) _
      & "\nTotal Modif Count: " & Str$(iTotModif) _
    & "\n\n     ****  FINISHED ****\n"
Print sTmp
'
slIn.Clear
slIn.AddList (slOut)
'
iMsg = MessageDlg(sTmp & "\n\n  You should rescan until Total_Modif_Count = 0" _
                    & "\n\n\n\n?? Do you want to scan that file one more time ??", mtInformation, mbYes OR mbNo, 0)
' ====================
Loop Until iMsg = 7'IDNO
' ====================
'
slOut.SaveToFile (sFileInc)
' -------------------------------------------------------------
' EXIT CONSOLE
' ------------
DefStr sExit
Input "\n\n                    CR to QUIT \n\n", sExit
Application.Terminate
' -----------------------------------------------------------------------------
'
' ---- End   RapidQ Code ----
'
