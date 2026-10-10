'=======================================================
' Type Objet
' Classe QWave Version 1.3
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

const WV_CLOSE=0
const WV_PLAY=1
const WV_PAUSE=2
const WV_STOP=3
const WV_RECORD=4
const WV_MONO=1
const WV_STEREO=2
const WV_BIT8=8
const WV_BIT16=16
const WV_KHZ8=8000
const WV_KHZ11=11025
const WV_KHZ22=22050
const WV_KHZ44=44100

Declare Function mciSendWave Lib "winmm.dll" Alias "mciSendStringA" (lpstrCommand As String, lpstrReturnString As long, uReturnLength As Long, hwndCallback As Long) As Long
Declare Function mciGetErrorWave Lib "winmm.dll" Alias "mciGetErrorStringA" (dwError As Long,Byref lpstrBuffer As String,uLength As Long) As Long
Declare Function WaveSetVolume Lib "Winmm" Alias "waveOutSetVolume" (wDeviceID as short,dwVolume as Long) as Short
Declare Function GetShortPathWave Lib "kernel32" Alias "GetShortPathNameA" (lpszLongPath As String,lpszShortPath As long,lBuffer As Long) As Long
Declare Sub event_change(position as long)

Type QWave extends Qobject
  '================================
  ' champs et proprietйs
  '================================
  Timer as QTIMER
  Lenght as long
  State as integer
  FileOpen as boolean
  Error as string
  CurrentPos as Long PROPERTY SET SetCurrentPos
  Bits as integer PROPERTY SET SetBits
  Frequence as integer PROPERTY SET SetFrequence
  Mode as short PROPERTY SET SetMode
  Volume as integer PROPERTY SET SetVolume
  DeviceType as string
  OnChange as EVENT(event_change) 

  '====================================
  ' proprietй volume du mйdia
  '====================================
  Property Set SetVolume(volume as integer)
    dim vol as long

    if volume<=100 then
      QWave.volume=volume
      if volume>50 then
        if volume=100 then
          WaveSetVolume(0,&hffffffff)
        else
          vol=-((32767/50)*(100-volume)) 
          WaveSetVolume(0,vol+(vol*65536))
        end if
      else
        vol=(32767/50)*volume 
        WaveSetVolume(0,vol+(vol*65536))
      end if
    end if
  End Property

  '====================================
  ' proprietй position Wave
  '====================================
  Property Set SetCurrentPos(Position as long)
    dim Retval as integer
    dim RetString as string

    if QWave.FileOpen then
      if QWave.State=WV_STOP or QWave.State=WV_PAUSE then
        if Position<0 then
          QWave.CurrentPos=0
        else
          if Position>QWave.Lenght then
            QWave.CurrentPos=QWave.Lenght
          else
            QWave.CurrentPos=Position
          end if
        end if
        RetString=Space$(128)
        Retval=mciSendWave("seek sound to "+Str$(QWave.CurrentPos),varptr(RetString),128,0)
      end if
    end if
  End Property

  '=========================================
  ' proprietй nombre de bit du fichier Wave
  '=========================================
  Property Set SetBits(number as integer)
    dim Retval as integer
    dim RetString as string
    Dim alignement as integer
    Dim ByteRate as long

    if number=WV_BIT8 or number=WV_BIT16 then
      if QWave.FileOpen then
        if QWave.State=WV_STOP or QWave.State=WV_PAUSE then
          QWave.Bits=number
          alignement=((QWave.Bits/8)*QWave.Mode)
          ByteRate=(QWave.Frequence*QWave.Mode*(QWave.Bits/8))
          RetString=Space$(128)
          Retval=mciSendWave("set sound BitsPerSample "+Str$(QWave.Bits)+" channels "+str$(QWave.Mode)+" samplespersec "+str$(QWave.Frequence)+" alignment "+str$(alignement)+" bytespersec "+str$(ByteRate),varptr(RetString),128,0)
        end if
      end if
    end if
  End Property
  
  '=========================================
  ' proprietй frequence du fichier Wave
  '=========================================
  Property Set SetFrequence(freq as integer)
    dim Retval as integer
    dim RetString as string
    Dim alignement as integer
    Dim ByteRate as long

    if freq=WV_KHZ8 or freq=WV_KHZ11 or freq=WV_KHZ44 then
      if QWave.FileOpen then
        if QWave.State=WV_STOP or QWave.State=WV_PAUSE then
          QWave.Frequence=freq
          alignement=((QWave.Bits/8)*QWave.Mode)
          ByteRate=(QWave.Frequence*QWave.Mode*(QWave.Bits/8))
          RetString=Space$(128)
          Retval=mciSendWave("set sound BitsPerSample "+Str$(QWave.Bits)+" channels "+str$(QWave.Mode)+" samplespersec "+str$(QWave.Frequence)+" alignment "+str$(alignement)+" bytespersec "+str$(ByteRate),varptr(RetString),128,0)
        end if
      end if
    end if
  End Property

  '=========================================
  ' proprietй mode de sortie du fichier Wave
  '=========================================
  Property Set SetMode(number as short)
    dim Retval as integer
    dim RetString as string
    Dim alignement as integer
    Dim ByteRate as long

    if number=WV_MONO or number=WV_STEREO then
      if QWave.FileOpen then
        if QWave.State=WV_STOP or QWave.State=WV_PAUSE then
          QWave.Mode=number
          alignement=((QWave.Bits/8)*QWave.Mode)
          ByteRate=(QWave.Frequence*QWave.Mode*(QWave.Bits/8))
          RetString=Space$(128)
          Retval=mciSendWave("set sound BitsPerSample "+Str$(QWave.Bits)+" channels "+str$(QWave.Mode)+" samplespersec "+str$(QWave.Frequence)+" alignment "+str$(alignement)+" bytespersec "+str$(ByteRate),varptr(RetString),128,0)
        end if
      end if
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
    Retval=mciGetErrorWave(McierrNr,RetString,200)
    if Retval then
      QWave.GetMciDescription=RTRIM$(RetString)
    else
      QWave.GetMciDescription=""
    end if
  End Function

  '====================================
  ' mйthode lecture position Wave
  '====================================
  Function GetPosition as long
    dim Retval as integer
    dim RetString as string

    if Wave.FileOpen then
      RetString=Space$(128)
      Retval=mciSendWave("status sound position",varptr(RetString),128,0)
      if Retval=False then QWave.GetPosition=val(RetString)
    end if
  End Function

  '====================================
  ' mйthode lecture mode du media
  '====================================
  Function GetState as integer
    dim Retval as integer
    dim RetString as string

    if QWave.FileOpen then
      RetString=Space$(128)
      Retval=mciSendWave("status sound mode",varptr(RetString),128,0)
      if instr(RetString,"stopped")>0 then QWave.GetState=WV_STOP
      if instr(RetString,"playing")>0 then QWave.GetState=WV_PLAY
      if instr(RetString,"paused")>0 then QWave.GetState=WV_PAUSE
    end if
  End Function

PUBLIC:

  '=================================
  ' mйthode fermeture fichier Wave
  '=================================
  Sub Close
    dim Retval as integer
    dim RetString as string

    QWave.Timer.enabled=False
    RetString=Space$(128)
    Retval=mciSendWave("stop sound",varptr(RetString),128,0)
    RetString=Space$(128)
    Retval=mciSendWave("close sound",varptr(RetString),128,0)
    QWave.FileOpen=False
    QWave.Lenght=0
    QWave.CurrentPos=0
    QWave.State=WV_CLOSE
  End Sub

  '====================================
  ' mйthode ouverture fichier Wave
  '====================================
  Function Open(FileName as string) as boolean
    Dim Retval as Integer
    Dim RetString as String
    Dim FlagOpen as boolean
    Dim lenFilename as Integer
    Dim filePath as string

    if FileName<>"" then
      filePath=STRING$(256,0)
      lenFilename=GetShortPathWave(FileName,VARPTR(filePath),255)
      FileName=LEFT$(filePath,lenFilename)
      RetString=Space$(128)
      if QWave.DeviceType<>"" then
        Retval=mciSendWave("open "+FileName+" type "+QWave.DeviceType+" alias sound",varptr(RetString),128,0)
      else
        Retval=mciSendWave("open "+FileName+" type waveaudio alias sound",varptr(RetString),128,0)
      end if
      if Retval=False then
        RetString=Space$(128)
        Retval=mciSendWave("set sound time format milliseconds",varptr(RetString),128,0)
        RetString=Space$(128)
        Retval=mciSendWave("status sound length",varptr(RetString),128,0)
        if Retval=False then
          QWave.Lenght=Val(RetString)
          RetString=Space$(128)
          Retval=mciSendWave("status sound bitspersample",varptr(RetString),128,0)
          if Retval=False then QWave.Bits=Val(RetString)
          RetString=Space$(128)
          Retval=mciSendWave("status sound samplespersec",varptr(RetString),128,0)
          if Retval=False then QWave.Frequence=Val(RetString)
          RetString=Space$(128)
          Retval=mciSendWave("status sound channels",varptr(RetString),128,0)
          if Retval=False then QWave.Mode=Val(RetString)
          QWave.State=WV_STOP
          QWave.CurrentPos=0
          QWave.FileOpen=True
          QWave.Open=True
          FlagOpen=True
        end if
      else
        QWave.Error=QWave.GetMciDescription(Retval)
      end if
      if FlagOpen=False then QWave.Close
    end if
  End Function

  '==================================
  ' mйthode lecture fichier Wave
  '==================================
  Sub Play
    dim Retval as integer
    dim RetString as String

    if QWave.FileOpen then
      QWave.Timer.enabled=True
      RetString = Space$(128)
      Retval=mciSendWave("play sound from "+Str$(QWave.CurrentPos),varptr(RetString),128,0)
      if Retval=False then QWave.State=WV_PLAY
    end if
  End Sub

  '==================================
  ' mйthode arret fichier Wave
  '==================================
  Sub Stop
    dim Retval as integer
    dim RetString as string

    if QWave.FileOpen then
      RetString=Space$(128)
      Retval=mciSendWave("stop sound",varptr(RetString),128,0)
      if Retval=False then
        RetString=Space$(128)
        Retval=mciSendWave("status sound length",varptr(RetString),128,0)
        if Retval=False then QWave.Lenght=Val(RetString)
        QWave.Timer.enabled=False
        QWave.State=WV_STOP
        QWave.CurrentPos=0
        RetString=Space$(128)
        Retval=mciSendWave("seek sound to start",varptr(RetString),128,0)
      end if
    end if
  End Sub

  '==================================
  ' mйthode pause 
  '==================================
  Sub Pause
    dim Retval as integer
    dim RetString as string

    if QWave.FileOpen=true and QWave.State=WV_PLAY then
      RetString=Space$(128)
      Retval=mciSendWave("pause sound",varptr(RetString),128,0)
      if Retval=False then
        QWave.State=WV_PAUSE
        QWave.Timer.enabled=False
        QWave.CurrentPos=QWave.GetPosition
      end if
    end if
  End Sub

  '==================================
  ' mйthode new,nouveau fichier wave
  '==================================
  Sub New
    dim Retval as integer
    dim RetString as string
    Dim FlagOpen as boolean

    if QWave.FileOpen=false then
      RetString=Space$(128)
      Retval=mciSendWave("open new type waveaudio alias sound",varptr(RetString),128,0)
      if Retval=False then
        RetString=Space$(128)
        Retval=mciSendWave("set sound time format milliseconds",varptr(RetString),128,0)
        RetString=Space$(128)
        Retval=mciSendWave("status sound bitspersample",varptr(RetString),128,0)
        if Retval=False then QWave.Bits=Val(RetString)
        RetString=Space$(128)
        Retval=mciSendWave("status sound samplespersec",varptr(RetString),128,0)
        if Retval=False then QWave.Frequence=Val(RetString)
        RetString=Space$(128)
        Retval=mciSendWave("status sound channels",varptr(RetString),128,0)
        if Retval=False then QWave.Mode=Val(RetString)
        QWave.State=WV_STOP
        QWave.Timer.enabled=False
        QWave.CurrentPos=0
        QWave.FileOpen=True
        FlagOpen=True
      end if
      if FlagOpen=False then QWave.Close
    end if
  End Sub

  '==================================
  ' mйthode record 
  '==================================
  Sub Record
    dim Retval as integer
    dim RetString as string

    if QWave.FileOpen=true and (QWave.State=WV_STOP or QWave.State=WV_PAUSE) then
      RetString=Space$(128)
      Retval=mciSendWave("record sound to "+str$(QWave.Lenght),varptr(RetString),128,0)
      if Retval=False then
        QWave.State=WV_RECORD
        QWave.Timer.enabled=True
      end if
    end if
  End Sub

  '==================================
  ' mйthode save
  '==================================
  Function Save(FileName as string) as boolean
    dim Retval as integer
    dim RetString as string

    if FileName<>"" then
      if QWave.FileOpen=true and QWave.State=WV_STOP then
        RetString=Space$(128)
        Retval=mciSendWave("save sound "+FileName,varptr(RetString),128,0)
        if Retval=False then QWave.Save=True
      end if
    end if
  End Function

  '==================================
  ' mйthode delete 
  '==================================
  Sub Delete(pos1 as long,pos2 as long)
    dim Retval as integer
    dim RetString as string

    if QWave.FileOpen=true and QWave.State=WV_STOP then
      if pos2>QWave.lenght then pos2=QWave.lenght
      if pos1<0 then pos1=0
      RetString=Space$(128)
      Retval=mciSendWave("delete sound from "+str$(pos1)+" to "+str$(pos2),varptr(RetString),128,0)
      if Retval=False then
        RetString=Space$(128)
        Retval=mciSendWave("status sound length",varptr(RetString),128,0)
        if Retval=False then QWave.Lenght=Val(RetString)
      end if
    end if
  End Sub

  '===============================================
  ' йvenement changementposition du fichier Wave
  '===============================================
  Event Timer.OnTimer
    QWave.CurrentPos=QWave.GetPosition
    QWave.State=QWave.GetState
    if QWave.State=WV_STOP then QWave.Stop
    if QWave.OnChange<>0 then CALLFUNC(QWave.OnChange,QWave.CurrentPos)
  End Event

  Constructor
    State=WV_CLOSE
    Timer.interval=1000
    Timer.enabled=False
  End Constructor
End Type
