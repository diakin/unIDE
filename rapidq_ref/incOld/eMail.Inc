' eMail.Inc
' ==========
' Usage:
' ReturnCode& = eMail ( Recipients$, Subject$, Message$, Attachments$ )
'
' Recipients$ > Multiple recipients separated by ';', Name and address by ':'
' 	To sent a CC precede the name by '>'
' 	To sent a BCC precede the name by '<'
' Attachments$ > Multiple attachments separated by ';'
'
' Examples:
' eMRetCode& = (":me@myserver.com", "eMail.inc", "Does it work ?", "c:\autoexec.bat")
' eMRetCode& = ("You:you@ys.net;>Me:me@myserver.com", "CcTest", "", "")

Const MAPI_USER_ABORT = 1
Const MAPI_E_FAILURE = 2
Const MAPI_E_LOGIN_FAILURE = 3
Const MAPI_E_INSUFFICIENT_MEMORY = 5
Const MAPI_E_TOO_MANY_FILES = 9
Const MAPI_E_TOO_MANY_RECIPIENTS = 10
Const MAPI_E_ATTACHMENT_NOT_FOUND = 11
Const MAPI_E_ATTACHMENT_OPEN_FAILURE = 12
Const MAPI_E_UNKNOWN_RECIPIENT = 14
Const MAPI_E_TEXT_TOO_LARGE = 18
Const MAPI_E_AMBIGUOUS_RECIPIENT = 21

Type MapiRecip
	iReserved As Long
	iRecipClass As Long
	lpszName As Long
	lpszAddress As Long
	iEIDSize As Long
	lpEntryID As Long
End Type

Type MapiFile
	iReserved As Long
	iFlags As Long
	iPosition As Long
	lpszPathName As Long
	lpszFileName As Long
	lpFileType As Long
End Type

Type MapiMessage 
	iReserved as Long 
	lpszSubject as Long 
	lpszNoteText as Long 
	lpszMessageType as Long 
	lpszDateReceived as Long 
	lpszConversationID as Long 
	iFlags as Long 
	lpOriginator as Long
	iRecipCount as Long 
	lpRecips As Long
	iFileCount as Long
	lpFiles As Long
End Type

Declare Function MAPISendMail Lib "MAPI32.DLL" Alias "MAPISendMail" _
(iSession As Long, iParam As Long, lpMapiMessage As MapiMessage, _
iFlags As Long, iReserved As Long) As Long 

Function eMail (eRecipients As String, eSubject As String, _
eMessage As String, eAttachments As String) As Long

DefLng mmRecCnt=0, mmRecIns=1, mmRecPtr
DefLng mmAttCnt=0, mmAttIns=1, mmAttPtr, mmAttPos
DefStr mmRecips, mmAttach, mmSubject, mmMessage

DIM mmM1 As QMemoryStream
DIM mmM2 As QMemoryStream
Dim gRecip As MapiRecip
Dim gFile As MapiFile
Dim rMessage As MapiMessage

mmRecips = Chr$(0)+ReplaceSubstr$(eRecipients,";",Chr$(0))
mmRecips = ReplaceSubstr$(mmRecips,":",Chr$(0)+"smtp:")
mmAttach = Chr$(0)+ReplaceSubstr$(eAttachments,";",Chr$(0))
mmSubject = eSubject
mmMessage = eMessage

gRecip.iReserved  = 0
gRecip.iEIDSize = 0
gRecip.lpEntryID = 0
gFile.iReserved = 0
gFile.iFlags = 0
gFile.lpszFileName = 0
gFile.lpFileType = 0
rMessage.iReserved = 0
rMessage.lpszSubject = VarPtr(mmSubject)
rMessage.lpszNotetext = VarPtr(mmMessage)
rMessage.lpszMessageType = 0
rMessage.lpszDatereceived = 0
rMessage.lpszConversationID = 0
rMessage.iFlags = 0
rMessage.lpOriginator = 0

If mmRecips<>Chr$(0) Then
mmRecPtr = VarPtr(mmRecips)
While mmRecIns
Select Case Mid$(mmRecips,mmRecIns+1,1)
Case ">"
	gRecip.iRecipClass = 2
	mmRecIns++
Case "<"
	gRecip.iRecipClass = 3
	mmRecIns++
Case Else 
	gRecip.iRecipClass = 1
End Select
gRecip.lpszName = mmRecPtr+mmRecIns
mmRecIns = Instr(mmRecIns+1,mmRecips,Chr$(0))
gRecip.lpszAddress = mmRecPtr+mmRecIns
mmM1.WriteUDT(gRecip)
mmRecCnt++
mmRecIns = Instr(mmRecIns+1,mmRecips,Chr$(0))
Wend
rMessage.lpRecips = mmM1.Pointer
End If
rMessage.iRecipCount = mmRecCnt

If mmAttach<>Chr$(0) Then
mmAttPtr = VarPtr(mmAttach)
mmAttPos = Len(mmMessage)-1
While mmAttIns
gFile.iPosition = mmAttPos
gFile.lpszPathName = mmAttPtr+mmAttIns
mmM2.WriteUDT(gFile)
mmAttPos++
mmAttCnt++
mmAttIns = Instr(mmAttIns+1,mmAttach,Chr$(0))
Wend
rMessage.lpFiles = mmM2.Pointer
End If
rMessage.iFileCount = mmAttCnt

eMail = MAPISendMail(0, 0, rMessage, 0, 0)
End Function
