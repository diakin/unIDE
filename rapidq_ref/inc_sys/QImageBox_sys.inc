' QImageBox_sys.inc - отдельный inc, не входит в rapidqAllProc.inc /
' rapidqComponents.inc: своя DLL NVIEWLIB (nviewlib.dll).
' Собран rapidq_ref/tools/build_inc.py из incOld/QImageBox.inc; повторы объявлений
' общих файлов убраны (build_removed.txt). Подключать в программе,
' которой он нужен.
$IFNDEF __SEP_QIMAGEBOX_INC
$DEFINE __SEP_QIMAGEBOX_INC
$INCLUDE "rapidqComponents.inc"
'============================================================================
'[build_inc] QImageBox.inc
'============================================================================
'=======================================================
' Type Objet
' Classe QImageBox version 1.0
'=======================================================
$IFNDEF TRUE
$ENDIF

$IFNDEF FALSE
$ENDIF

$IFNDEF boolean
$ENDIF

Type ICONINFO_IMGBOX
  fIcon as long
  xHotspot as long
  yHotspot as long
  hbmMask as long
  hbmColor as long
End Type

Type TBITMAP_IMGBOX
  bmType As Long
  bmWidth As Long
  bmHeight As Long
  bmWidthBytes As Long
  bmPlanes As Integer
  bmBitsPixel As Integer
  bmBits As Long
End Type

Declare Function ImgBoxGetSystemDir Lib "kernel32" Alias "GetSystemDirectoryA" (lpBuffer As long,nSize As Long) As Long
Declare Function ImgBoxCreateDC Lib "gdi32" Alias "CreateCompatibleDC" (hdc As Long) As Long
Declare Function ImgBoxSelectObject Lib "gdi32" Alias "SelectObject" (hdc As Long,hObject As Long) As Long
Declare Function ImgBoxBitBlt Lib "gdi32" Alias "BitBlt" (hDestDC As Long,x As Long,y As Long,nWidth As Long,nHeight As Long,hSrcDC As Long,xSrc As Long,ySrc As Long,dwRop As Long) As Long
Declare Function ImgBoxDeleteDC Lib "gdi32" Alias "DeleteDC" (hdc As Long) As Long
Declare Function ImgBoxDeleteObject Lib "gdi32" Alias "DeleteObject" (hObject As Long) As Long
Declare Function ImgBoxDrawIcon Lib "user32" Alias "DrawIconEx" (hdc As Long,xLeft As Long,yTop As Long,hIcon As Long,cxWidth As Long,cyWidth As Long,istepIfAniCur As Long,hbrFlickerFreeDraw As Long,diFlags As Long) As Long
Declare Function ImgBoxExtractIcon Lib "shell32.dll" Alias "ExtractIconA" (hInst As Long,lpszExeFileName As String,nIconIndex As Long) As Long
Declare Function ImgBoxDestroyIcon Lib "user32" Alias "DestroyIcon" (hIcon As Long) As Long
Declare Function ImgBoxGetIconInfo Lib "user32" Alias "GetIconInfo" (hIcon As Long,piconinfo As ICONINFO_IMGBOX) As Long
Declare Function ImgBoxGetObject Lib "gdi32" Alias "GetObjectA" (hObject As Long,nCount As Long, lpObject As TBITMAP_IMGBOX) As Long
Declare Function ImgBoxLoadImage Lib "user32" Alias "LoadImageA" (hInst As Long,lpsz As String,dwImageType As Long,dwDesiredWidth As Long,dwDesiredHeight As Long,dwFlags As Long) As Long

Declare Function ImgBoxLoad Lib "NVIEWLIB" Alias "NViewLibLoad" (FileName As String,Progress As Integer) As Long
Declare Function ImgBoxSetLanguage Lib "NVIEWLIB" Alias "NViewLibSetLanguage" (Language As String) As Integer
Declare Function ImgBoxGetWidth Lib "NVIEWLIB" Alias "GetWidth" () As Integer
Declare Function ImgBoxGetHeight Lib "NVIEWLIB" Alias "GetHeight" () As Integer

Type QImageBox Extends QScrollbox
  Private:
    Image as QImage
    Bitmap as QBitmap
    ClientWidth as integer
    ClientHeight as integer
    Path as string
    DllName as string
    info as ICONINFO_IMGBOX
    infoBmp as TBITMAP_IMGBOX
  Public:
    Language as string
    Progress as boolean
    FileName as string Property Set SetFileName
    ImgWidth as integer Property Set SetImgWidth
    ImgHeight as integer Property Set SetImgHeight

  Private:  
  '=================================================
  ' Mйthode retourne le rapport en pourcentage
  '=================================================
  function Ratio(Value1 as double,Value2 as double) as double
    Result=((Value1-Value2)*100)/Value1
  end function
  
  '=================================================
  ' Mйthode affiche l'image avec la rйduction
  '=================================================
  Sub ShowImage
    defint reduction=100
    defint reduction1=100
    defint reduction2=100
    
    this.ImgWidth=this.bitmap.width
    this.ImgHeight=this.bitmap.height
    if this.bitmap.Width>this.ClientWidth or this.bitmap.Height>this.ClientHeight then
      if this.bitmap.Width>this.ClientWidth then
        reduction1=100-this.Ratio(this.bitmap.Width,this.ClientWidth)
      end if
      if this.bitmap.Height>this.ClientHeight then
        reduction2=100-this.Ratio(this.bitmap.Height,this.ClientHeight)
      end if
      if reduction1<reduction2 then
        reduction=reduction1
      else
        reduction=reduction2
      end if
      if reduction1=reduction2 then reduction=reduction1
    end if
    this.Image.left=int((this.Width-((this.bitmap.Width*reduction)/100))/2)
    this.Image.top=int((this.Height-((this.bitmap.Height*reduction)/100))/2)
    this.Image.Width=int(this.bitmap.Width*(reduction/100))
    this.Image.Height=int(this.bitmap.Height*(reduction/100))
    this.Image.bmp=this.bitmap.bmp
    this.Image.visible=true
  End Sub
      
  '=================================================
  ' Mйthode retourne la prйsence de la dll
  '=================================================
  Function DllExist() as boolean
    dim lpBuffer as string
    dim SystemDir as string
    dim size as short
    
    if FileExists(this.Path+this.DllName) then
      result=true
    else
      lpBuffer=Space$(260)
      size=ImgBoxGetSystemDir(Varptr(lpBuffer),260)
      SystemDir=Left$(lpBuffer,size)
      if FileExists(SystemDir+"\"+this.DllName) then
        result=true
      else
        result=false
      end if
    end if    
  End Function
  
  '==================================================
  ' Mйthode ouvre les fichiers au format graphique
  ' de la dll
  '==================================================
  Sub LoadOtherImage(FileName as string)
    dim hDC as integer
    dim hBitmap as integer
    dim hOldBitmap as integer

    hBitmap=ImgBoxLoad(FileName,This.progress)
    if hBitmap<>0 then
      this.bitmap.pixelformat=6
      this.bitmap.width=ImgBoxGetWidth()
      this.bitmap.height=ImgBoxGetHeight()
      hDC=ImgBoxCreateDC(this.bitmap.handle)
      hOldBitmap=ImgBoxSelectObject(hDC,hBitmap)
      ImgBoxBitBlt(this.bitmap.handle,0,0,this.bitmap.width,this.bitmap.height,hDC,0,0,&HCC0020)
      ImgBoxSelectObject(hDC,hOldBitmap)
      ImgBoxDeleteDC(hDC)
      ImgBoxDeleteObject(hBitmap)
    end if    
  End Sub

  '=================================================
  ' Mйthode ouvre les fichiers icone et curseur
  '=================================================
  Sub LoadIcon(FileName as string)
    dim hIcon as long
    
    if instr(lcase$(FileName),".ico")>0 then
      hIcon=ImgBoxLoadImage(0,FileName,1,0,0,&H10)
      if hIcon<>0 then
        ImgBoxGetIconInfo(hIcon,this.info)
        ImgBoxGetObject(this.info.hbmColor,SIZEOF(this.infoBmp),this.infoBmp)
        this.bitmap.pixelformat=6
        this.bitmap.width=this.infoBmp.bmWidth
        this.bitmap.height=this.infoBmp.bmHeight
        this.bitmap.fillRect(0,0,this.bitmap.width,this.bitmap.height,this.color)
        ImgBoxDrawIcon(this.bitmap.handle,0,0,hIcon,0,0,0,0,&h3)
        ImgBoxDestroyIcon(hIcon)
      end if
    else
      hIcon=ImgBoxExtractIcon(0,FileName,0)
      if hIcon<>0 then
        this.bitmap.pixelformat=6
        this.bitmap.width=32
        this.bitmap.height=32
        this.bitmap.fillRect(0,0,32,32,this.color)
        ImgBoxDrawIcon(this.bitmap.handle,0,0,hIcon,32,32,0,0,&h3)
        ImgBoxDestroyIcon(hIcon)
      end if
    end if
  End Sub
  
  '=================================================
  ' Mйthode Retourne l'extension valide d'un
  ' fichier prise en compte par la dll
  '=================================================
  Function DllFormat(FileName as string) as boolean
    if instr(LCase$(FileName),".gif")>0 then
      result=true 
    elseif instr(LCase$(FileName),".jpg")>0 then
      result=true 
    elseif instr(LCase$(FileName),".jif")>0 then
      result=true 
    elseif instr(LCase$(FileName),".dib")>0 then
      result=true 
    elseif instr(LCase$(FileName),".rle")>0 then
      result=true 
    elseif instr(LCase$(FileName),".tga")>0 then
      result=true 
    elseif instr(LCase$(FileName),".pcx")>0 then
      result=true 
    else
      result=false
    end if
  End Function
        
  Public:              
  '=================================================
  ' Proprietй largeur image
  '=================================================
  Property Set SetImgWidth(width as integer)
  'read only
  End Property
  
  '=================================================
  ' Proprietй hauteur image
  '=================================================
  Property Set SetImgHeight(height as integer)
  'read only
  End Property
  
  '=================================================
  ' Proprietй nom fichier image
  '=================================================
  Property Set SetFileName(filename as string)
    if filename<>"" then
      this.filename=filename
      if instr(LCase$(filename),".bmp")>0 then
        this.bitmap.bmp=filename
        this.ShowImage
      elseif instr(LCase$(filename),".ico")>0 or _
             instr(LCase$(filename),".ani")>0 or _
             instr(LCase$(filename),".cur")>0 then
        this.LoadIcon(filename)
        this.ShowImage
      elseif this.DllFormat(filename) then
        if this.DllExist() then
      	  if this.Language<>"" then ImgBoxSetLanguage(this.Language)
          this.LoadOtherImage(filename)
          this.ShowImage
        else
          this.ImgWidth=0
          this.ImgHeight=0
          this.Image.visible=false
        end if
      else
        this.ImgWidth=0
        this.ImgHeight=0
        this.Image.visible=false
      end if
    else
      this.ImgWidth=0
      this.ImgHeight=0
    end if
  End Property
                  
  '=================================================
  ' Evenement redimenssion image
  '=================================================
  Event OnResize
    This.ClientWidth=This.Width-10
    This.ClientHeight=This.Height-10
    if This.FileName<>"" then This.ShowImage
  End Event
    
  Constructor
    AutoScroll=False
    HorzVisible=False
    VertVisible=False
    ClientWidth=This.Width-10
    ClientHeight=This.Height-10
    Image.Parent=This
    Image.Visible=False
    Image.stretch=true
    Path=left$(command$(0),rinstr(command$(0),"\"))
    DllName="Nviewlib.dll"
  End Constructor
End Type

$ENDIF ' __SEP_QIMAGEBOX_INC
