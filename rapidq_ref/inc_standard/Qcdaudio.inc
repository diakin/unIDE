$IFNDEF __QCDAUDIO_INC   ' IncManager: include guard
$DEFINE __QCDAUDIO_INC
'=======================================================
' Type Objet
' Classe QCdaudio
'=======================================================
$IFNDEF TRUE
  $DEFINE True 1
$ENDIF

$IFNDEF FALSE
  $DEFINE False 0
$ENDIF

$IFNDEF boolean
  $DEFINE boolean integer
$ENDIF

const CD_CLOSE=0
const CD_PLAY=1
const CD_PAUSE=2
const CD_STOP=3
    Declare Sub event_change(track as integer,time as string) ' inc2026: перенесено из-под $IFNDEF __WIN32API: шаблон события объявлен только здесь, а WINDOWS.INC (где __WIN32API определён) его не объявляет
$IFNDEF __WIN32API				   'windows 32 definitions
    Declare Function mciSendCdaudio Lib "winmm.dll" Alias "mciSendStringA" (lpstrCommand As String, lpstrReturnString As long, uReturnLength As Long, hwndCallback As Long) As Long
    Declare Function mciGetErrorCdaudio Lib "winmm.dll" Alias "mciGetErrorStringA" (dwError As Long,Byref lpstrBuffer As String,uLength As Long) As Long
$ENDIF

Type Qcdaudio extends Qobject
  '================================
  ' champs et proprietйs
  '================================
  Timer as QTIMER
  Time as string
  TrackTime as string
  TrackNumber as integer
  TimePosition as string
  Position as long
  State as integer
  AudioOpen as boolean
  Present as boolean
  Error as string
  CurrentTrack as Integer PROPERTY SET SetCurrentTrack
  OnChange as EVENT(event_change) 


  '====================================
  ' proprietй position track
  '====================================
  Property Set SetCurrentTrack(track as integer)
    dim Retval as integer
    dim RetString as string

    if Qcdaudio.AudioOpen then
      if track<1 then
        Qcdaudio.CurrentTrack=1
      else
        if track>Qcdaudio.TrackNumber then
          Qcdaudio.CurrentTrack=Qcdaudio.TrackNumber
        else
          Qcdaudio.CurrentTrack=track
        end if
      end if
      RetString=Space$(128)
      Retval=mciSendCdaudio("seek cdaudio to "+Str$(Qcdaudio.CurrentTrack),varptr(RetString),128,0)
      RetString=Space$(128)
      Retval=mciSendCdaudio("set cdaudio time format tmsf",varptr(RetString),128,0)
      RetString=Space$(128)
      Retval=mciSendCdaudio("status cdaudio length track "+Str$(Qcdaudio.CurrentTrack),varptr(RetString),128,0)
      if Retval=False then Qcdaudio.TrackTime=rtrim$(RetString)
    end if
  End Property

PRIVATE:

  '========================================
  ' Mйthode retourne le texte de l'erreur
  '========================================
  Function GetMciDescription(McierrNr As Long) As String
    dim Retval as Long
    dim RetString as String

    RetString=Space$(200)
    Retval=mciGetErrorCdaudio(McierrNr,RetString,200)
    if Retval then
      Qcdaudio.GetMciDescription=RTRIM$(RetString)
    else
      Qcdaudio.GetMciDescription=""
    end if
  End Function

  '====================================
  ' mйthode lecture position track
  '====================================
  Function GetTrack as integer
    dim Retval as integer
    dim RetString as string

    if Qcdaudio.AudioOpen then
      RetString=Space$(128)
      Retval=mciSendCdaudio("status cdaudio current track",varptr(RetString),128,0) ' inc2026: убран лишний + перед запятой (было "..."+, - у оператора + нет второго операнда)
      if Retval=False then Qcdaudio.GetTrack=val(RetString)
    end if
  End Function

  '====================================
  ' mйthode lecture position temps cd
  '====================================
  Function GetTimePosition as string
    dim Retval as integer
    dim RetString as string

    if Qcdaudio.AudioOpen then
      RetString=Space$(128)
      Retval=mciSendCdaudio("status cdaudio position",varptr(RetString),128,0) ' inc2026: убран лишний + перед запятой (было "..."+, - у оператора + нет второго операнда)
      if Retval=False then Qcdaudio.GetTimePosition=rtrim$(RetString)
    end if
  End Function

  '====================================
  ' mйthode lecture position ms cd
  '====================================
  Function GetPosition as long
    dim Retval as integer
    dim RetString as string

    if Qcdaudio.AudioOpen then
      RetString=Space$(128)
      Retval=mciSendCdaudio("set cdaudio time format ms",varptr(RetString),128,0)
      RetString=Space$(128)
      Retval=mciSendCdaudio("status cdaudio position",varptr(RetString),128,0) ' inc2026: убран лишний + перед запятой (было "..."+, - у оператора + нет второго операнда)
      if Retval=False then Qcdaudio.GetPosition=val(RetString)
      RetString=Space$(128)
      Retval=mciSendCdaudio("set cdaudio time format tmsf",varptr(RetString),128,0)
    end if
  End Function

  '====================================
  ' mйthode lecture mode cd
  '====================================
  Function GetMode as integer
    dim Retval as integer
    dim RetString as string

    if Qcdaudio.AudioOpen then
      RetString=Space$(128)
      Retval=mciSendCdaudio("status cdaudio mode",varptr(RetString),128,0)
      if instr(RetString,"stopped")>0 then Qcdaudio.GetMode=CD_STOP
      if instr(RetString,"playing")>0 then Qcdaudio.GetMode=CD_PLAY
      if instr(RetString,"paused")>0 then Qcdaudio.GetMode=CD_PAUSE
    end if
  End Function

PUBLIC:

  '=================================
  ' mйthode fermeture media cd
  '=================================
  Sub Close
    dim Retval as integer
    dim RetString as string

    Qcdaudio.Timer.enabled=False
    RetString=Space$(128)
    Retval=mciSendCdaudio("stop cdaudio",varptr(RetString),128,0)
    RetString=Space$(128)
    Retval=mciSendCdaudio("close cdaudio",varptr(RetString),128,0)
    Qcdaudio.AudioOpen=False
    Qcdaudio.Time=""
    Qcdaudio.TrackTime=""
    Qcdaudio.TimePosition=""
    Qcdaudio.Position=0
    Qcdaudio.TrackNumber=0
    Qcdaudio.CurrentTrack=0
    Qcdaudio.State=CD_CLOSE
  End Sub

  '====================================
  ' mйthode ouverture cd
  '====================================
  Function Open as boolean
    Dim Retval as Integer
    Dim RetString as String
    Dim FlagOpen as boolean

    Qcdaudio.Close
    RetString=Space$(128)
    Retval=mciSendCdaudio("open cdaudio",varptr(RetString),128,0)
    if Retval=False then
      RetString=Space$(19)
      Retval=mciSendCdaudio("status cdaudio media present",varptr(RetString),19,0)
      if instr(RetString,"true")>0 then
        Qcdaudio.Present=True
        RetString=Space$(128)
        Retval=mciSendCdaudio("status cdaudio number of tracks",varptr(RetString),128,0)
        if Retval=False then
          Qcdaudio.TrackNumber=val(RetString)
          RetString=Space$(128)
          Retval=mciSendCdaudio("set cdaudio time format tmsf",varptr(RetString),128,0)
          RetString=Space$(128)
          Retval=mciSendCdaudio("status cdaudio length",varptr(RetString),128,0)
          if Retval=False then
            Qcdaudio.Time=rtrim$(RetString)
            Qcdaudio.State=CD_STOP
            Qcdaudio.CurrentTrack=1
            Qcdaudio.AudioOpen=True
            Qcdaudio.Open=True
            FlagOpen=True
          end if
        end if
      end if
    else
      Qcdaudio.Error=Qcdaudio.GetMciDescription(Retval)
    end if
    if FlagOpen=False then Qcdaudio.Close
  End Function

  '==================================
  ' mйthode lecture cdaudio
  '==================================
  Sub Play
    dim Retval as integer
    dim RetString as String

    if Qcdaudio.AudioOpen then
      Qcdaudio.Timer.enabled=True
      RetString = Space$(128)
      if Qcdaudio.State=CD_PAUSE then
        Retval=mciSendCdaudio("play cdaudio from "+Qcdaudio.TimePosition,varptr(RetString),128,0)
      else
        Retval=mciSendCdaudio("play cdaudio from "+Str$(Qcdaudio.CurrentTrack),varptr(RetString),128,0)
      end if
      if Retval=False then Qcdaudio.State=CD_PLAY
    end if
  End Sub

  '==================================
  ' mйthode arret lecture cd
  '==================================
  Sub Stop
    dim Retval as integer
    dim RetString as string

    if Qcdaudio.AudioOpen then
      RetString=Space$(128)
      Retval=mciSendCdaudio("stop cdaudio",varptr(RetString),128,0)
      if Retval=False then
        Qcdaudio.Timer.enabled=False
        Qcdaudio.State=CD_STOP
        Qcdaudio.CurrentTrack=1
        RetString=Space$(128)
        Retval=mciSendCdaudio("seek cdaudio to start",varptr(RetString),128,0)
      end if
    end if
  End Sub

  '==================================
  ' mйthode pause lecture cd
  '==================================
  Sub Pause
    dim Retval as integer
    dim RetString as string

    if Qcdaudio.AudioOpen=true and Qcdaudio.State=CD_PLAY then
      RetString=Space$(128)
      Retval=mciSendCdaudio("pause cdaudio",varptr(RetString),128,0)
      if Retval=False then
        Qcdaudio.State=CD_PAUSE
        Qcdaudio.Timer.enabled=False
        Qcdaudio.CurrentTrack=Qcdaudio.GetTrack
        Qcdaudio.TimePosition=Qcdaudio.GetTimePosition
      end if
    end if
  End Sub

  '====================================
  ' mйthode ejection cd
  '====================================
  Sub Eject
    dim Retval as integer
    dim RetString as string

    Qcdaudio.stop
    Qcdaudio.close
    RetString=Space$(128)
    Retval=mciSendCdaudio("set cdaudio door open",varptr(RetString),128,0) ' inc2026: убран лишний + перед запятой (было "..."+, - у оператора + нет второго операнда)
    Qcdaudio.Present=False
  End Sub  

  '===============================================
  ' йvenement changementposition du cd
  '===============================================
  Event Timer.OnTimer
    Qcdaudio.currentTrack=Qcdaudio.GetTrack
    Qcdaudio.TimePosition=Qcdaudio.GetTimePosition
    Qcdaudio.State=Qcdaudio.GetMode
    if Qcdaudio.State=CD_STOP then Qcdaudio.Stop
    CALLFUNC(Qcdaudio.OnChange,Qcdaudio.currentTrack,Qcdaudio.TimePosition)
  End Event

  Constructor
    State=CD_CLOSE
    Timer.interval=1000
    Timer.enabled=False
  End Constructor
End Type
$ENDIF   ' IncManager: __QCDAUDIO_INC
