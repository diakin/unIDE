'=======================================================
' Type Objet
' Classe QVideo Version 1.3
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

const VD_CLOSE=0
const VD_PLAY=1
const VD_PAUSE=2
const VD_STOP=3

Declare Function ShowVideo Lib "user32" Alias "ShowWindow" (hwnd As Long,nCmdShow As Long) As Long
Declare Function mciSendVideo Lib "winmm.dll" Alias "mciSendStringA" (lpstrCommand As String,lpstrReturnString As long,uReturnLength As Long,hwndCallback As Long) As Long
Declare Function mciGetErrorVideo Lib "winmm.dll" Alias "mciGetErrorStringA" (dwError As Long,Byref lpstrBuffer As String,uLength As Long) As Long
Declare Function MoveVideo Lib "user32" Alias "MoveWindow" (hwnd As Long,x As integer,y As integer,nWidth As integer,nHeight As integer,bRepaint As Long) As Long
Declare Function SetForegroundVideo Lib "user32" Alias "SetForegroundWindow" (hwnd As Long) As Long
Declare Function GetVideoRect Lib "user32" Alias "GetWindowRect" (hwnd As Long,lpRect As QRECT) As Long
Declare Function VideoSetVolume Lib "Winmm" Alias "waveOutSetVolume" (wDeviceID as short,dwVolume as Long) as Short
Declare Sub event_change(position as long,timePos as long)

Type QVideo extends Qobject
  '================================
  ' champs et proprietйs
  '================================
  Timer as QTIMER
  Lenght as long
  LenghtTime as long
  State as integer
  Handle as long
  FileOpen as boolean
  Error as string
  Parent as long
  BorderStyle as integer
  ImgWidth as short
  ImgHeight as short
  Left as short PROPERTY SET SetLeft
  Top as short PROPERTY SET SetTop
  Width as short PROPERTY SET SetWidth
  Height as short PROPERTY SET SetHeight
  CurrentFrame as Long PROPERTY SET SetCurrentFrame
  AudioOff as boolean PROPERTY SET SetAudioOff
  Caption as string PROPERTY SET SetCaption
  WindowState as integer PROPERTY SET SetWindowState
  Volume as integer PROPERTY SET SetVolume
  OnChange as EVENT(event_change) 

  '====================================
  ' proprietй volume du media
  '====================================
  Property Set SetVolume(volume as integer)
    dim vol as long

    if volume<=100 then
      QVideo.volume=volume
      if volume>50 then
        if volume=100 then
          VideoSetVolume(0,&hffffffff)
        else
          vol=-((32767/50)*(100-volume)) 
          VideoSetVolume(0,vol+(vol*65536))
        end if
      else
        vol=(32767/50)*volume 
        VideoSetVolume(0,vol+(vol*65536))
      end if
    end if
  End Property

  '====================================
  ' proprietй affichage image du media
  '====================================
  Property Set SetCurrentFrame(frame as long)
    dim Retval as integer
    dim RetString as string

    if QVideo.FileOpen then
      if QVideo.State=VD_STOP or QVideo.State=VD_PAUSE then
        if frame<0 then
          QVideo.CurrentFrame=0
        else
          if frame>QVideo.Lenght then
            QVideo.CurrentFrame=QVideo.Lenght
          else
            QVideo.CurrentFrame=frame
          end if
        end if
        RetString=Space$(128)
        Retval=mciSendVideo("seek MEDIA to "+Str$(QVideo.CurrentFrame),varptr(RetString),128,0)
      end if
    end if
  End Property

  '====================================
  ' proprietй position x image du media
  '====================================
  Property Set SetLeft(left as short)
    if QVideo.FileOpen=True and QVideo.handle<>0 then
      QVideo.Left=left
      if QVideo.Parent=0 then SetForegroundVideo(QVideo.handle)
      MoveVideo(QVideo.handle,QVideo.Left,QVideo.Top,QVideo.Width,QVideo.Height,true)
    end if
  End Property

  '====================================
  ' proprietй position y image du media
  '====================================
  Property Set SetTop(top as short)
    if QVideo.FileOpen=True and QVideo.handle<>0 then
      QVideo.Top=top
      if QVideo.Parent=0 then SetForegroundVideo(QVideo.handle)
      MoveVideo(QVideo.handle,QVideo.Left,QVideo.Top,QVideo.Width,QVideo.Height,true)
    end if
  End Property

  '====================================
  ' proprietй largeur image du media
  '====================================
  Property Set SetWidth(width as short)
    if QVideo.FileOpen=True and QVideo.handle<>0 then
      QVideo.Width=width
      if QVideo.Parent=0 then SetForegroundVideo(QVideo.handle)
      MoveVideo(QVideo.handle,QVideo.Left,QVideo.Top,QVideo.Width,QVideo.Height,true)
    end if
  End Property

  '====================================
  ' proprietй hauteur image du media
  '====================================
  Property Set SetHeight(height as short)
    if QVideo.FileOpen=True and QVideo.handle<>0 then
      QVideo.Height=height
      if QVideo.Parent=0 then SetForegroundVideo(QVideo.handle)
      MoveVideo(QVideo.handle,QVideo.Left,QVideo.Top,QVideo.Width,QVideo.Height,true)
    end if
  End Property

  '====================================
  ' proprietй sans son du media
  '====================================
  PROPERTY SET SetAudioOff(audio as boolean)
    dim Retval as integer
    dim RetString as string

    if QVideo.FileOpen then
      RetString=Space$(128)
      if audio then
        Retval=mciSendVideo("set MEDIA audio all off",varptr(RetString),128,0)
      else
        Retval=mciSendVideo("set MEDIA audio all on",varptr(RetString),128,0)
      end if
    end if
  End Property

  '====================================
  ' proprietй caption du media
  '====================================
  PROPERTY SET SetCaption(caption as string)
    dim Retval as integer
    dim RetString as string

    QVideo.Caption=caption
    if QVideo.FileOpen=True and QVideo.Parent=0 then
      RetString=Space$(128)
      Retval=mciSendVideo("window MEDIA text "+caption,varptr(RetString),128,0)
    end if
  END PROPERTY
 
  '====================================
  ' proprietй etat fenetre du media
  '====================================
  PROPERTY SET SetWindowState(WindowState as integer)
    dim state as short

    if QVideo.FileOpen=True and QVideo.Parent=0 then
      if WindowState>-1 and WindowState<3 then
        if WindowState=0 then state=1
        if WindowState=1 then state=2
        if WindowState=2 then state=3
        QVideo.WindowState=WindowState
        ShowVideo(QVideo.handle,state)
      else
        QVideo.WindowState=0
      end if
    end if
  END PROPERTY

PRIVATE:

  '========================================
  ' Mйthode retourne le texte de l'erreur
  '========================================
  Function GetMciDescription(McierrNr As Long) As String
    dim Retval as Long
    dim RetString as String

    RetString=Space$(200)
    Retval=mciGetErrorVideo(McierrNr,RetString,200)
    if Retval then
      QVideo.GetMciDescription=RTRIM$(RetString)
    else
      QVideo.GetMciDescription=""
    end if
  End Function

  '========================================
  ' Mйthode dimension du mйdia
  '========================================
  Sub GetDimension
    dim rect as QRECT

    GetVideoRect(QVideo.handle,Rect)
    QVideo.width=rect.right-rect.left
    QVideo.height=rect.bottom-rect.top
  End Sub

  '==================================
  ' mйthode position du media
  '==================================
  Function GetPosition as long
    dim Retval as integer
    dim RetString as string

    if QVideo.FileOpen then
      RetString=Space$(128)
      Retval=mciSendVideo("status MEDIA position",varptr(RetString),128,0)
      if Retval=False then QVideo.GetPosition=val(RetString)
    end if
  End Function

  '========================================
  ' Mйthode dimension du mйdia
  '========================================
  Sub GetImgDimension(mediadim as string)
    dim sPos As long
    dim ePos As long
    dim left as short
    dim top as short

    ePos=instr(,mediadim," ")
    left=Val(Mid$(mediadim,1,ePos))
    sPos=ePos+1
    ePos=instr(sPos,mediadim," ")
    top=Val(Mid$(mediadim,sPos,ePos-sPos))
    sPos=ePos+1
    ePos=instr(sPos,mediadim," ")
    QVideo.ImgWidth=Val(Mid$(mediadim,sPos,ePos-sPos))
    sPos=ePos+1
    QVideo.ImgHeight=Val(Mid$(mediadim,sPos,Len(mediadim)-sPos))
  End Sub

  '====================================
  ' mйthode lecture mode du media
  '====================================
  Function GetMode as integer
    dim Retval as integer
    dim RetString as string

    if QVideo.FileOpen then
      RetString=Space$(128)
      Retval=mciSendVideo("status MEDIA mode",varptr(RetString),128,0)
      if instr(RetString,"stopped")>0 then QVideo.GetMode=VD_STOP
      if instr(RetString,"playing")>0 then QVideo.GetMode=VD_PLAY
      if instr(RetString,"paused")>0 then QVideo.GetMode=VD_PAUSE
    end if
  End Function

PUBLIC:

  '=================================
  ' mйthode fermeture fichier media
  '=================================
  Sub Close
    dim Retval as integer
    dim RetString as string

    QVideo.Timer.enabled=False
    RetString=Space$(128)
    Retval=mciSendVideo("stop MEDIA",varptr(RetString),128,0)
    RetString=Space$(128)
    Retval=mciSendVideo("close MEDIA",varptr(RetString),128,0)
    QVideo.FileOpen=False
    QVideo.Lenght=0
    QVideo.LenghtTime=0
    QVideo.Left=0
    QVideo.Top=0
    QVideo.Width=0
    QVideo.Height=0
    QVideo.ImgWidth=0
    QVideo.ImgHeight=0
    QVideo.CurrentFrame=0
    QVideo.State=VD_CLOSE
  End Sub

  '=================================
  ' mйthode ouverture fichier media
  '=================================
  Function Open(FileName as string) as boolean
    Dim Retval as Integer
    Dim RetString as String
    Dim FlagOpen as integer
    Dim Style as string

    if FileName<>"" then
      RetString=Space$(128)
      if QVideo.Parent<>0 then
        Retval=mciSendVideo("open "+FileName+" alias MEDIA parent "+ Str$(QVideo.Parent)+" style child",varptr(RetString),128,0)
      else
        if QVideo.BorderStyle=0 then Style="popup"
        if QVideo.BorderStyle<>0 then Style="overlapped"
        Retval=mciSendVideo("open "+FileName+" alias MEDIA style "+Style,varptr(RetString),128,0)
      end if
      if Retval=False then
        if QVideo.Parent=0 then
          if QVideo.caption<>"" then
            RetString=Space$(128)
            Retval=mciSendVideo("window MEDIA text "+QVideo.caption,varptr(RetString),128,0)
          else
            RetString=Space$(128)
            Retval=mciSendVideo("info MEDIA window text",varptr(RetString),128,0)
            if Retval=False then QVideo.Caption=RetString
          end if
        end if
        RetString=Space$(128)
        Retval=mciSendVideo("set MEDIA time format milliseconds",varptr(RetString),128,0)
        RetString=Space$(128)
        Retval=mciSendVideo("status MEDIA length",varptr(RetString),128,0)
        if Retval=False then QVideo.LenghtTime=Val(RetString)/1000
        RetString=Space$(128)
        Retval=mciSendVideo("set MEDIA time format frames",varptr(RetString),128,0)
        RetString=Space$(128)
        Retval=mciSendVideo("status MEDIA length",varptr(RetString),128,0)
        if Retval=False then
          QVideo.Lenght=Val(RetString)
          RetString=Space$(128)
          Retval=mciSendVideo("where MEDIA source",varptr(RetString),128,0)
          if Retval=False then
            QVideo.GetImgDimension(RetString)
            RetString=Space$(128)
            Retval=mciSendVideo("status MEDIA window handle",varptr(RetString),128,0)
            if Retval=False then
              QVideo.handle=val(RetString)
              if QVideo.Parent<>0 then
                QVideo.Width=QVideo.ImgWidth
                QVideo.Height=QVideo.ImgHeight
              else
                QVideo.GetDimension
              end if
              QVideo.State=VD_STOP
              QVideo.CurrentFrame=0
              QVideo.FileOpen=True
              QVideo.Open=True
              FlagOpen=True
            end if
          end if
        end if
      else
        QVideo.Error=QVideo.GetMciDescription(Retval)
      end if
      if FlagOpen=False then QVideo.Close
    end if
  End Function

  '=================================
  ' mйthode affichage media
  '=================================
  Sub Show
    dim Retval as integer
    dim RetString as string

    if QVideo.FileOpen then
      if QVideo.Parent=0 then SetForegroundVideo(QVideo.handle)
      RetString=Space$(128)
      Retval=mciSendVideo("window MEDIA state show",varptr(RetString),128,0)
    end if
  End Sub

  '==================================
  ' mйthode lecture du media
  '==================================
  Sub Play
    dim Retval as integer
    dim RetString as String

    if QVideo.FileOpen then
      QVideo.Timer.enabled=True
      if QVideo.Parent=0 then SetForegroundVideo(QVideo.handle)
      RetString = Space$(128)
      Retval=mciSendVideo("play MEDIA from "+Str$(QVideo.CurrentFrame),varptr(RetString),128,0)
      if Retval=False then QVideo.State=VD_PLAY
    end if
  End Sub

  '==================================
  ' mйthode arret du media
  '==================================
  Sub Stop
    dim Retval as integer
    dim RetString as string

    if QVideo.FileOpen then
      RetString=Space$(128)
      Retval=mciSendVideo("stop MEDIA",varptr(RetString),128,0)
      if Retval=False then
         QVideo.Timer.enabled=False
         QVideo.State=VD_STOP
        QVideo.CurrentFrame=0
        RetString=Space$(128)
        Retval=mciSendVideo("seek MEDIA to start",varptr(RetString),128,0)
      end if
    end if
  End Sub

  '==================================
  ' mйthode pause du media
  '==================================
  Sub Pause
    dim Retval as integer
    dim RetString as string

    if QVideo.FileOpen=true and QVideo.State=VD_PLAY then
      RetString=Space$(128)
      Retval=mciSendVideo("pause MEDIA",varptr(RetString),128,0)
      if Retval=False then
        QVideo.State=VD_PAUSE
        QVideo.Timer.enabled=False
        QVideo.CurrentFrame=QVideo.GetPosition
      end if
    end if
  End Sub

  '=======================================
  ' йvenement changementposition du media
  '=======================================
  Event Timer.OnTimer
    dim currentTime as long

    QVideo.currentFrame=QVideo.GetPosition
    currentTime=int(QVideo.currentFrame*(QVideo.LenghtTime/QVideo.Lenght))
    QVideo.State=QVideo.GetMode
    if QVideo.State=VD_STOP then QVideo.Stop
    if QVideo.OnChange<>0 then CALLFUNC(QVideo.OnChange,QVideo.currentFrame,currentTime)
  End Event

  Constructor
    State=VD_CLOSE
    Timer.interval=1000
    Timer.enabled=False
  End Constructor
End Type
