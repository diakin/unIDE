'******************************************************
'*     QLibrary.Inc - Common Routines & Functions     *
'******************************************************


'******************************************************
'*       String Functions & Subroutines               *
'******************************************************
Function Trim$ (Datum As String) As String
   Result = LTrim$(RTrim$(Datum))
End Function

FunctionI CatStr$ (...) As String
   Dim I As Byte

   Result = ParamStr$(1)
   For I = 2 to ParamStrCount
      Result = Result + ParamStr$(I)
   Next I
End FunctionI

Function Equ$(String1 As String, String2 As String, Exact As Byte) As Integer
   If Exact = True Then
      If Trim$(String1) = Trim$(String2) Then
         Result = True
      Else
         Result = False
      End If
   Else
      If Trim$(UCase$(String1)) = Trim$(UCase$(String2)) Then
         Result = True
      Else
         Result = False
      End If
   End If
End Function

'******************************************************
'*         File Functions & Subroutines               *
'******************************************************
Function AddPath$ (Path As String, File As String) As String
   AddPath$ = Path + "\" + File
End Function

'****************************
'* RapidQ Keyword Extension *
'****************************

Type RQConst Extends QStringList
   FileId      As String
   Initialized As Byte
   
   Sub Initialize
      Dim RQ_Idx          As Integer
      Dim Buffer          As QStringList
      Dim StrLength       As Integer
      Dim Point           As Byte
      Dim StrLine         As String
      Dim StrWord         As String
      Dim StrValue        As String
      Dim Entry           As String
      Dim Tmp             As String
      Dim R As Integer, G As Integer, B As Integer
                 
      With RQConst
         .Initialized = True
         .Clear
         Buffer.LoadFromFile(.FileId)
         RQ_Idx = 0
         While RQ_Idx < Buffer.ItemCount-1
            StrLine = Trim$(Buffer.Item(RQ_Idx))
            If InStr(StrLine,"CONST") > 0 And Left$(StrLine,1) <> "'" Then
               StrLine   = Trim$(ReplaceSubStr$(StrLine,"CONST",""))
               StrLength = Len(StrLine)
               Point     = InStr(StrLine,"=") + 1
               StrWord   = Trim$(Left$(StrLine,Point - 2))
               StrValue  = Trim$(Mid$(StrLine,Point,StrLength - Point + 1))
               If InStr(StrValue,"'") > 0 Then
                  StrLength = Len(StrValue)
                  Point     = InStr(StrValue,"'") 
                  StrValue  = Trim$(Left$(StrValue,Point-1))
               End If
               If InStr(StrValue,"&H") > 0 Then
                  StrLine  = StrValue
                  StrValue = Trim$(ReplaceSubStr$(StrValue,"&H",""))
                  StrValue = ConvBase$(StrValue,16,10)
               End If
               If InStr(StrValue,"RGB") > 0 Then
                  StrValue = ReplaceSubStr$(StrValue,"RGB(","")
                  StrValue = ReplaceSubStr$(StrValue,")",",")
                  StrValue = Trim$(StrValue)
                  R        = Val(Trim$(Field$(StrValue,",",1)))
                  G        = Val(Trim$(Field$(StrValue,",",2)))
                  B        = Val(Trim$(Field$(StrValue,",",3)))
                  StrValue = Trim$(Str$(RGB(R,G,B)))
               End If
               Entry = StrWord + ";" + StrValue 
               .AddItems Entry
            End If
            Inc RQ_Idx
         Wend
      End With
   End Sub
      
   Function ValueOf(Entry As String) As Long
      Dim Idx As Integer
      Dim StrWord As String
      Dim StrValue As Long
      
      Entry = Trim$(Entry)
      With RQConst
         If .Initialized = False Then
            .Initialize
         End If
         Idx = 0
         While Idx < .ItemCount
            StrWord  = Field$(.Item(Idx),";",1)
            StrValue = Val(Field$(.Item(Idx),";",2))
            If Equ$(StrWord,Entry,False) = True Then
               Result = StrValue
               Idx    = .ItemCount
            End If
            Inc Idx
         Wend
      End With
   End Function
   
   Constructor:
      Initialized = False
      FileId      = "RapidQ.Inc"
   End Constructor
End Type

'************
'* QIniFile *
'************
Type QIniFile Extends QObject
   Public:
      Name      As String
      Lines     As QStringList
      LineCount As Integer
      
   Sub ClearEnding
      Dim LinesIdx As Integer
      Dim StrWord As String
      
      If (QIniFile.Lines.ItemCount-1) => 0 Then
         LinesIdx = QIniFile.Lines.ItemCount-1
         StrWord  = QIniFile.Lines.Item(LinesIdx)
         While Empty$(StrWord) = True
            QIniFile.Lines.DelItems LinesIdx
            If LinesIdx > 0 Then
               Dec LinesIdx
               StrWord = QIniFile.Lines.Item(LinesIdx)
            Else
               StrWord = "*"
            End If
         Wend
      End If
   End Sub

   Function AddBrackets$(Datum As String) As String
      Datum = Trim$(Datum)
      If InStr(Datum,"[") = 0 Then               
         Result = "[" + Datum
      End If
      If InStr(Datum,"]") <> Len(Datum) Then
         Result = Result + "]"
      End If
   End Function
         
   Function ReadEntry (Section As String, KeyWord As String) As String
      Dim StrLength As Integer
      Dim Point     As Byte
      Dim StrLine   As String
      Dim StrWord   As String
      Dim Bracket   As String
      Dim LinesIdx  As Integer
      
      Section  = QIniFile.AddBrackets$(Section)
      QIniFile.Lines.Clear
      If FileExists(QIniFile.Name) = True Then
         KeyWord = Trim$(KeyWord)
         QIniFile.Lines.LoadFromFile(QIniFile.Name)
         QIniFile.Lines.AddItems " "
         LinesIdx = 0
         While LinesIdx < QIniFile.Lines.ItemCount-1
            StrWord = Trim$(QIniFile.Lines.Item(LinesIdx))
            If Equ$(StrWord,Section,False) Then
               Inc LinesIdx
               StrLine = Trim$(QIniFile.Lines.Item(LinesIdx))
               Bracket = Left$(StrLine,1)
               While Bracket <> "[" And LinesIdx < QIniFile.Lines.ItemCount-1
                  StrWord    = Trim$(Field$(StrLine,"=",1))
                  StrLength  = Len(StrLine)
                  If Equ$(StrWord,KeyWord,False) Then
                     Point    = InStr(StrLine,"=") + 1
                     Result   = Mid$(StrLine,Point,StrLength - Point + 1)
                     LinesIdx = QIniFile.Lines.ItemCount 
                  Else
                     Inc LinesIdx
                     StrLine = Trim$(QIniFile.Lines.Item(LinesIdx))
                     Bracket = Left$(StrLine,1)
                  End If
                Wend
            Else
               Inc LinesIdx
            End If
         Wend
      End If
      QIniFile.ClearEnding
      QIniFile.LineCount = QIniFile.Lines.ItemCount
   End Function
   
   Sub ReadSection (Section As String)
      Dim StrLength As Integer
      Dim Point     As Byte
      Dim StrLine   As String
      Dim StrWord   As String
      Dim Bracket   As String
      Dim LinesIdx  As Integer
      Dim Buffer    As QStringList

      Section = QIniFile.AddBrackets$(Section)
      QIniFile.Lines.Clear
      If FileExists(QIniFile.Name) Then
         Buffer.LoadFromFile(QIniFile.Name)
         Buffer.AddItems " "
         LinesIdx = 0
         While LinesIdx < Buffer.ItemCount-1
            StrWord = Left$(Trim$(Buffer.Item(LinesIdx)),Len(Section))
            If Equ$(StrWord,Section,False) Then
               Inc LinesIdx
               StrLine = Buffer.Item(LinesIdx)
               Bracket = Left$(StrLine,1)
               While Bracket <> "[" And LinesIdx < Buffer.ItemCount-1
                  QIniFile.Lines.AddItems StrLine 
                  Inc LinesIdx
                  StrLine = Buffer.Item(LinesIdx)
                  Bracket = Left$(StrLine,1)                      
               Wend
               LinesIdx = Buffer.ItemCount
            Else
               Inc LinesIdx
            End If
         Wend
      End If
      QIniFile.LineCount = QIniFile.Lines.ItemCount
   End Sub
   
   Sub WriteEntry (Section As String, KeyWord As String, KeyEntry As String) 
      Dim StrLength As Integer
      Dim StrLine   As String
      Dim StrWord   As String
      Dim Point     As Byte
      Dim Bracket   As String
      Dim LinesIdx  As Integer
      Dim Fin       As Byte

      KeyWord  = Trim$(KeyWord)
      KeyEntry = Trim$(KeyEntry)
      Section  = QIniFile.AddBrackets$(Section)
      QIniFile.Lines.Clear
      If FileExists(QIniFile.Name) Then
         QIniFile.Lines.LoadFromFile(QIniFile.Name)
         QIniFile.Lines.AddItems " "
         LinesIdx = 0
         While LinesIdx < QIniFile.Lines.ItemCount-1
            StrWord = Left$(Trim$(QIniFile.Lines.Item(LinesIdx)),Len(Section))
            If Equ$(StrWord,Section,False) Then
               Inc LinesIdx
               StrLine = Trim$(QIniFile.Lines.Item(LinesIdx))
               Bracket = Left$(StrLine,1)
               While Bracket <> "[" And LinesIdx < QIniFile.Lines.ItemCount-1
                  StrLength = Len(StrLine)
                  StrWord   = Trim$(Field$(StrLine,"=",1))
                  If Equ$(StrWord,KeyWord,False) Then
                     Point   = InStr(StrLine,"=") + 1
                     StrWord = Mid$(StrLine,Point,StrLength - Point + 1)
                     StrLine = CatStr$(KeyWord," = ",KeyEntry)
                     QIniFile.Lines.DelItems(LinesIdx)
                     QIniFile.Lines.InsertItem(LinesIdx,StrLine)
                     Fin      = True 
                     LinesIdx = QIniFile.Lines.ItemCount 
                  Else
                     Inc LinesIdx
                     StrLine = QIniFile.Lines.Item(LinesIdx)
                     Bracket = Left$(Trim$(StrLine),1)
                  End If
                Wend
                If Fin <> True Then
                   QIniFile.ClearEnding
                   QIniFile.Lines.AddItems CatStr$(KeyWord,"=",KeyEntry)
                   Fin = True
                End If
            Else
               Inc LinesIdx
            End If
         Wend
      End If
      If Fin <> True Then
         QIniFile.ClearEnding
         QIniFile.Lines.AddItems " "
         QIniFile.Lines.AddItems Section
         QIniFile.Lines.AddItems CatStr$(KeyWord,"=",KeyEntry)
      End If
      QIniFile.Lines.SaveToFile(QIniFile.Name)
      QIniFile.LineCount = QIniFile.Lines.ItemCount
   End Sub
   
   Sub WriteSection (Section As String,SectionList As QStringList)
      Dim StrLength As Integer
      Dim Point     As Byte
      Dim StrLine   As String
      Dim StrWord   As String
      Dim Bracket   As String
      Dim LinesIdx  As Integer
      Dim Buffer    As QStringList

      QIniFile.Lines.Clear
      Point   = False
      Section = QIniFile.AddBrackets$(Section)
      If FileExists(QIniFile.Name) Then
         Buffer.LoadFromFile(QIniFile.Name)
         Buffer.AddItems " "
         LinesIdx = 0
         While LinesIdx < Buffer.ItemCount -1
            StrLine = Buffer.Item(LinesIdx)
            StrWord = Left$(Trim$(Buffer.Item(LinesIdx)),Len(Section))
            If Equ$(StrWord,Section,False) Then
               Point   = LinesIdx
               Inc LinesIdx
               StrLine = Buffer.Item(LinesIdx)
               Bracket = Left$(StrLine,1)
               While Bracket <> "[" AND LinesIdx < Buffer.ItemCount-1
                  Inc LinesIdx
                  StrLine = Buffer.Item(LinesIdx)
                  Bracket = Left$(StrLine,1)                      
               Wend
            Else
               QIniFile.Lines.AddItems StrLine
               Inc LinesIdx
            End If
         Wend
      End If
      SectionList.InsertItem(0,Section)
      If Point > False Then
         For LinesIdx = 0 To SectionList.Itemcount-1
            StrLine = SectionList.Item(LinesIdx)
            QIniFile.Lines.InsertItem(Point,StrLine)
            Inc Point
         Next LinesIdx
      Else
         QIniFile.Lines.AddItems " "
         Point = QIniFile.Lines.ItemCount
         QIniFile.Lines.AddList SectionList
      End If
      QIniFile.ClearEnding
      QIniFile.Lines.SaveToFile(QIniFile.Name)
      QIniFile.LineCount = QIniFile.Lines.ItemCount
   End Sub

   Sub Edit
      Dim CurName As String
      Dim Editor  As String
 
      CurName        = QIniFile.Name
      QIniFile.Name  = "QLibrary.Ini"
      Editor         = QIniFile.ReadEntry("QIniFile","TextEditor")
      QIniFile.Name  = CurName
      Editor         = CatStr$(Editor," ",QIniFile.Name)
      Shell Editor
      QIniFile.LineCount = 0
   End Sub
End Type

'------------------------------------------------------
'$EndIf '<---- End QLibrary definition check
'------------------------------------------------------    
