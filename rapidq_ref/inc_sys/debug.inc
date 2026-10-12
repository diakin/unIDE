' debug.inc - отдельный inc, не входит в rapidqAllProc.inc /
' rapidqComponents.inc: при запуске создаёт окно отладки _DebugFORM.
' Собран rapidq_ref/tools/build_inc.py из incOld/debug.inc; повторы объявлений
' общих файлов - '~dup. Подключать в программе, которой он нужен.
$IFNDEF __SEP_DEBUG_INC
$DEFINE __SEP_DEBUG_INC
$INCLUDE "rapidqComponents.inc"
'============================================================================
'[build_inc] debug.inc
'============================================================================
'! --- вставляем процедуру дебаггера ----------'
'~inc $INCLUDE"RAPIDQ.INC"   ' уже в сборке или заменён выбранной версией
'~dup CONST WM_COPYDATA = &H4A   ' повтор, первое: constants.inc(161)
'~dup TYPE COPYDATASTRUCT    ' повтор, первое: WIN32API.INC(6234)
'~dup 	dwData AS LONG 
'~dup 	cbData AS LONG 
'~dup 	lpData AS LONG 
'~dup END TYPE 

DIM DataStruct AS COPYDATASTRUCT 
'~dup DECLARE FUNCTION FindWindow LIB "user32" ALIAS "FindWindowA" (ByVal lpClassName AS String, ByVal lpWindowName AS String) AS LONG    ' повтор, первое: User32.inc(17)

DEFSTR strSend, strRecv, AppName 
DEFInt flgRecv 
declare sub MsgHandler 
declare sub _DebugFormClose 
declare sub TimerOverDbg 
dim timerDbg as QTimer
TimerDBG.Interval = 300 
TimerDBG.Enabled = 1  
TimerDBG.OnTimer = TimerOverDbg 
'= ========================================'
SUB FormWndProc (Hwnd&, uMsg&, wParam&, lParam&) 
   IF uMsg& = WM_COPYDATA THEN 
      DIM MStream AS QMEMORYSTREAM 
      MStream.MemCopyFrom(lParam&, 12) 
      MStream.Position = 0 
      MStream.ReadUDT(DataStruct) 
      MStream.Close 
      strRecv = VARPTR$(DataStruct.lpData) 
      flgRecv=1
   END IF 
END SUB 
'= ========================================'
SUB SendData  
   DEFLNG wndhnd 
   wndhnd=Findwindow("TForm",AppName) 
   IF wndhnd=0 THEN 
      SHOWMESSAGE "Could not find "+AppName 
      EXIT SUB 
   END IF 
   DataStruct.lpData = VARPTR(strSend) 
   DataStruct.cbData = LEN(strSend) 
   SENDMESSAGE wndhnd, WM_COPYDATA, 0, DataStruct 
END SUB 
'= ========================================'
CREATE _DebugFORM AS QFORM 
	CAPTION="DebuggerWnd"
	left=1
	top=1  
	Width = 248 
	Height = 230 
	FormStyle = fsStayOnTop 
	BorderStyle=bsSizeToolWin 
	onClose=_DebugFormClose 
	CREATE _DebugEdit AS QRICHEDIT
		hideselection=0
		scrollbars=3
		top=2
		left=2
		width=_DebugFORM.clientwidth-2
		height=_DebugFORM.clientheight-2
	END CREATE 
END CREATE 
'== dbg1 == 

'-- ***************************************************************************************************
sub TimerOverDbg
if _DebugFORM.Visible=0 then _DebugFORM.Visible=1
end sub

'-- ***************************************************************************************************
sub MsgHandler
MsgHandlerStart=1
while   1=1
	select case  strRecv
	case "RunItOnClick"
		flgRecv=0
		exit while
	case "PauseOnClick"
		if flgRecv=1 then
			flgRecv=0
		end if
	case "ContinueOnClick"
		flgRecv=0
		exit while
	case "StepOverOnClick"
		if flgRecv=1  then
			flgRecv=0
			exit while
		end if
	case "StepInToOnClick"
		if flgRecv=1 then
			flgRecv=0
			exit while
		end if
	case  "RunToCursOnClick"
		strSend="RunToCursOnClick received"
	case   "AddWatchOnClick"
		strSend="AddWatchOnClick received"
	case    "DelWatchOnClick"
		strSend="DelWatchOnClick received"
	case     "DelAllWatchOnClick"
		strSend="DelAllWatchOnClick received"
	case      "ToggleBreakPointOnClick"
		strSend="ToggleBreakPointOnClick received"
	case  "ClearAllBreakPointsOnClick"
		strSend= "ClearAllBreakPointsOnClick received"
	case "FormCloseOnClick"
		end
		exit while
	case else
		exit while
	end select
	doevents
wend
strSend=_DebugEdit.Text
senddata
END SUB

'-- ***************************************************************************************************
sub  _DebugFormClose
flgRecv=1
strRecv="FormCloseOnClick"
_DebugForm.Close
end
end sub
$ENDIF ' __SEP_DEBUG_INC
