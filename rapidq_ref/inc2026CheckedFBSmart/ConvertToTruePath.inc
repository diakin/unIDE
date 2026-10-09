'/* Start Of Code */
Const SHGFI_DISPLAYNAME = &H200

Type SHFILEINFO_UDT
  hIcon As Long
  iIcon As Integer
  dwAttributes As DWord
  szDisplayName As String * 260
  szTypeName As String * 80
End Type

Dim SFI As SHFILEINFO_UDT

Declare Function SHGetFileInfo Lib "shell32" Alias "SHGetFileInfoA" _
        (ByVal pszPath As String, ByVal dwFileAttributes As Long, _
         ByVal psfi As Long, ByVal cbFileInfo As Long, _
         ByVal uFlags As Long) As Dword

'Declare Function ConvertToTruePath(ByVal sPath As String) As String

'*****************************************
Function ConvertToTruePath(ByVal sPath As String) As String
  ' Parse... breaks the string parameter down to individual folders
  Dim DirParser As QStringlist : DirParser.Clear : DirParser.Parse(sPath, "\")
  Dim RootDir As String : RootDir = DirParser.Item(0) & "\"
  Dim SubFolderPath As String : SubFolderPath = ""
  Dim TruePath As String : TruePath = ""
  Dim Index As Long : Index = 0

  If DirParser.ItemCount > 1 Then
    For Index = 1 To (DirParser.ItemCount-1)
      SubFolderPath = SubFolderPath & DirParser.Item(Index) & "\"
      SFI.szDisplayName = String$(260, Chr$(0))
      SHGetFileInfo(RootDir & SubFolderPath, 0, SFI, SizeOf(SFI), SHGFI_DISPLAYNAME)
      TruePath = TruePath & Left$(SFI.szDisplayName, Instr(SFI.szDisplayName, Chr$(0))-1) & "\"
    Next Index
  End If

  Result = (RootDir & TruePath)
End Function