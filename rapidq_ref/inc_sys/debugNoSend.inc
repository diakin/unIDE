' debugNoSend.inc - отдельный inc, не входит в rapidqAllProc.inc /
' rapidqComponents.inc: при запуске создаёт окно отладки _DebugFORM и таймер; вызывает senddata из debug.inc.
' Собран rapidq_ref/tools/build_inc.py из incOld/debugNoSend.inc; повторы объявлений
' общих файлов - '~dup. Подключать в программе, которой он нужен.
$IFNDEF __SEP_DEBUGNOSEND_INC
$DEFINE __SEP_DEBUGNOSEND_INC
$INCLUDE "rapidqComponents.inc"
'============================================================================
'[build_inc] debugNoSend.inc
'============================================================================
'! --- вставляем процедуру дебаггера ----------'
'~inc $INCLUDE"RAPIDQ.INC"   ' уже в сборке или заменён выбранной версией

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
$ENDIF ' __SEP_DEBUGNOSEND_INC
