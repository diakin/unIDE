'============================================================================
' Subject: STANDARD MESSAGE DIALOG FUNCTION     Date: 05-03-00 (21:33)
' Author:  Jernej Simoncic                      Code: RAPIDQ
' Origin:  jernej.simoncic@guest.arnes.si     Packet: RAPIDQ.ABC
' .inc version and some modifications by Marcin Szafran, jm_sz@poczta.onet.pl
'============================================================================

'Shows standard Message Dialog, with buttons in local language (unlike RapidQ's
'MessageDlg, which always shows English buttons)
'
'Usage: [button& =] MsgDlg text$, title$, buttons&
'
' Thanks to RapidQ, you can use it as Sub or Function.
'
' button&   Returns clicked button
' text$     Text to display in message box
' buttons&  Select which buttons and icons to display and which button is
'           default.
' title$    Message box title
'
'buttons& values (you can combine them):
' value   description
' 0       Display OK button only.
' 1       Display OK and Cancel buttons.
' 2       Display Abort, Retry, and Ignore buttons.
' 3       Display Yes, No, and Cancel buttons.
' 4       Display Yes and No buttons.
' 5       Display Retry and Cancel buttons.
' 16      Display Critical Message icon.
' 32      Display Warning Query icon.
' 48      Display Warning Message icon.
' 64      Display Information Message icon.
' 0       First button is default.
' 256     Second button is default.
' 512     Third button is default.
' 768     Fourth button is default.
'
'So here are constans (if you'd like them)
'
const bOK = 0 		' of course you do not need to use it
const bOKCan = 1
const bAbRetIg = 2
const bYesNoCan = 3
const bYesNo = 4
const bRetCan = 5
const iCritMsg = 16
const iWarnQuery = 32
const iWarnMsg = 48
const iInfMsg = 64
const dFst = 0		' of course you do not need to use it
const dSec = 256
const dTrd = 512
const dFth = 768
'
'button& values
' 1   OK
' 2   Cancel
' 3   Abort
' 4   Retry
' 5   Ignore
' 6   Yes
' 7   No
'
Declare Function MsgDlg (MsgDlgText As String, MsgDlgTitle As String, MsgDlgButtons As Long) As Long
Declare Function MDlg Lib "user32" Alias "MessageBoxA" (ByVal hwnd As Long, ByVal lpText As String, ByVal lpCaption As String, ByVal wType As Long) As Long

Function MsgDlg (MsgDlgText As String, MsgDlgTitle As String, MsgDlgButtons As Long) As Long
    Result = MDlg (Form.Handle,MsgDlgText,MsgDlgTitle,MsgDlgButtons)
End Function

' And here are exemples
'
' MsgDlg ("Just example","",2)
' MsgDlg ("Just example","",bAbRetIg)
' MsgDlg ("It's just example","RapidQ",1+32+256)
' MsgDlg ("It's just example","RapidQ",bOKCan+iWarnQuery+dSec)
' MsgDlg ("Component 'MsgDlg', by Jernej Simoncic","About...",64)
' MsgDlg ("'MsgDlg', by Jernej Simoncic + Marcin Szafran","About...",iInfMsg)
'
' by Jernej Simoncic
' .inc version + modifications by Marcin Szafran
'
  