'=======================================================
' Type Objet
' Classe QMidi Version 1.2
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

const MD_CLOSE=0
const MD_PLAY=1
const MD_PAUSE=2
const MD_STOP=3

Declare Function mciSendMidi Lib "winmm.dll" Alias "mciSendStringA" (lpstrCommand As String, lpstrReturnString As long, uReturnLength As Long, hwndCallback As Long) As Long
Declare Function mciGetErrorMidi Lib "winmm.dll" Alias "mciGetErrorStringA" (dwError As Long,Byref lpstrBuffer As String,uLength As Long) As Long
Declare Function MidiSetVolume Lib "Winmm" Alias "waveOutSetVolume" (wDeviceID as short,dwVolume as Long) as Short
Declare Sub event_change(position as long)

Type QMidi extends Qobject
  '================================
  ' champs et proprietés
  '================================
  Timer as QTIMER
  Lenght as long
  State as integer
  FileOpen as boolean
  Error as string
  CurrentFrame as Long PROPERTY SET SetCurrentFrame
  Volume as integer PROPERTY SET SetVolume
  OnChange as EVENT(event_change) 

  '====================================
  ' proprieté volume du media
  '====================================
  Property Set SetVolume(volume as integer)
    dim vol as long

    if volume<=100 then
      QMidi.volume=volume
      if volume>50 then
        if volume=100 then
          MidiSetVolume(0,&hffffffff)
        else
          vol=-((32767/50)*(100-volume)) 
          MidiSetVolume(0,vol+(vol*65536))
        end if
      else
        vol=(32767/50)*volume 
        MidiSetVolume(0,vol+(vol*65536))
      end if
    end if
  End Property

  '====================================
  ' proprieté position séquence
  '====================================
  Property Set SetCurrentFrame(frame as long)
    dim Retval as integer
    dim RetString as string

    if QMidi.FileOpen then
      if QMidi.State=MD_STOP or QMidi.State=MD_PAUSE then
        if frame<0 then
          QMidi.CurrentFrame=0
        else
          if frame>QMidi.Lenght then
            QMidi.CurrentFrame=QMidi.Lenght
          else
            QMidi.CurrentFrame=frame
          end if
        end if
        RetString=Space$(128)
        Retval=mciSendMidi("seek MEDIA to "+Str$(QMidi.CurrentFrame),varptr(RetString),128,0)
      end if
    end if
  End Property

PRIVATE:

  '========================================
  ' Méthode retourne le texte de l'erreur
  '========================================
  Function GetMciDescription(McierrNr As Long) As String
    dim Retval as Long
    dim RetString as String

    RetString=Space$(200)
    Retval=mciGetErrorMidi(McierrNr,RetString,200)
    if Retval then
      QMidi.GetMciDescription=RTRIM$(RetString)
    else
      QMidi.GetMciDescription=""
    end if
  End Function

  '====================================
  ' méthode lecture position séquence
  '====================================
  Function GetPosition as long
    dim Retval as integer
    dim RetString as string

    if QMidi.FileOpen then
      RetString=Space$(128)
      Retval=mciSendMidi("status MEDIA position",varptr(RetString),128,0)
      if Retval=False then QMidi.GetPosition=val(RetString)
    end if
  End Function

  '====================================
  ' méthode lecture mode du media
  '====================================
  Function GetMode as integer
    dim Retval as integer
    dim RetString as string

    if QMidi.FileOpen then
      RetString=Space$(128)
      Retval=mciSendMidi("status MEDIA mode",varptr(RetString),128,0)
      if instr(RetString,"stopped")>0 then QMidi.GetMode=MD_STOP
      if instr(RetString,"playing")>0 then QMidi.GetMode=MD_PLAY
      if instr(RetString,"paused")>0 then QMidi.GetMode=MD_PAUSE
    end if
  End Function

PUBLIC:

  '=================================
  ' méthode fermeture fichier midi
  '=================================
  Sub Close
    dim Retval as integer
    dim RetString as string

    QMidi.Timer.enabled=False
    RetString=Space$(128)
    Retval=mciSendMidi("stop MEDIA",varptr(RetString),128,0)
    RetString=Space$(128)
    Retval=mciSendMidi("close MEDIA",varptr(RetString),128,0)
    QMidi.FileOpen=False
    QMidi.Lenght=0
    QMidi.CurrentFrame=0
    QMidi.State=MD_CLOSE
  End Sub

  '====================================
  ' méthode ouverture fichier midi
  '====================================
  Function Open(FileName as string) as boolean
    Dim Retval as Integer
    Dim RetString as String
    Dim FlagOpen as boolean

    if FileName<>"" then
      RetString=Space$(128)
      Retval=mciSendMidi("open "+FileName+" type sequencer alias MEDIA",varptr(RetString),128,0)
      if Retval=False then
        RetString=Space$(128)
        Retval=mciSendMidi("set MEDIA time format milliseconds",varptr(RetString),128,0)
        RetString=Space$(128)
        Retval=mciSendMidi("status MEDIA length",varptr(RetString),128,0)
        if Retval=False then
          QMidi.Lenght=Val(RetString)
          QMidi.State=MD_STOP
          QMidi.CurrentFrame=0
          QMidi.FileOpen=True
          QMidi.Open=True
          FlagOpen=True
        end if
      else
        QMidi.Error=QMidi.GetMciDescription(Retval)
      end if
      if FlagOpen=False then QMidi.Close
    end if
  End Function

  '==================================
  ' méthode lecture fichier midi
  '==================================
  Sub Play
    dim Retval as integer
    dim RetString as String

    if QMidi.FileOpen then
      QMidi.Timer.enabled=True
      RetString = Space$(128)
      Retval=mciSendMidi("play MEDIA from "+Str$(QMidi.CurrentFrame),varptr(RetString),128,0)
      if Retval=False then QMidi.State=MD_PLAY
    end if
  End Sub

  '==================================
  ' méthode arret fichier midi
  '==================================
  Sub Stop
    dim Retval as integer
    dim RetString as string

    if QMidi.FileOpen then
      RetString=Space$(128)
      Retval=mciSendMidi("stop MEDIA",varptr(RetString),128,0)
      if Retval=False then
        QMidi.Timer.enabled=False
        QMidi.State=MD_STOP
        QMidi.CurrentFrame=0
        RetString=Space$(128)
        Retval=mciSendMidi("seek MEDIA to start",varptr(RetString),128,0)
      end if
    end if
  End Sub

  '==================================
  ' méthode pause 
  '==================================
  Sub Pause
    dim Retval as integer
    dim RetString as string

    if QMidi.FileOpen=true and QMidi.State=MD_PLAY then
      RetString=Space$(128)
      Retval=mciSendMidi("pause MEDIA",varptr(RetString),128,0)
      if Retval=False then
        QMidi.State=MD_PAUSE
        QMidi.Timer.enabled=False
        QMidi.CurrentFrame=QMidi.GetPosition
      end if
    end if
  End Sub

  '===============================================
  ' évenement changementposition du fichier midi
  '===============================================
  Event Timer.OnTimer
    QMidi.currentFrame=QMidi.GetPosition
    QMidi.State=QMidi.GetMode
    if QMidi.State=MD_STOP then QMidi.Stop
    if QMidi.OnChange<>0 then CALLFUNC(QMidi.OnChange,QMidi.currentFrame)
  End Event

  Constructor
    State=MD_CLOSE
    Timer.interval=1000
    Timer.enabled=False
  End Constructor
End Type
      