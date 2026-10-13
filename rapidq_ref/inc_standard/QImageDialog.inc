$IFNDEF __QIMAGEDIALOG_INC   ' IncManager: include guard
$DEFINE __QIMAGEDIALOG_INC
'=======================================================
' Type Objet
' Classe QImageDialog version 1.1
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

Type ICONINFO_IMG
  fIcon as long
  xHotspot as long
  yHotspot as long
  hbmMask as long
  hbmColor as long
End Type

Type TBITMAP_IMG
  bmType As Long
  bmWidth As Long
  bmHeight As Long
  bmWidthBytes As Long
  bmPlanes As Integer
  bmBitsPixel As Integer
  bmBits As Long
End Type

Declare Function ImgDlgGetDrive Lib "kernel32" Alias "GetDriveTypeA" (nDrive As String) As Long
Declare function ImgDlgSetFocus LIB "USER32" ALIAS "SetFocus" (Handle as long) as long
Declare Function ImgDlgGetSystemDir Lib "kernel32" Alias "GetSystemDirectoryA" (lpBuffer As long,nSize As Long) As Long
Declare Function ImgDlgCreateDC Lib "gdi32" Alias "CreateCompatibleDC" (hdc As Long) As Long
Declare Function ImgDlgSelectObject Lib "gdi32" Alias "SelectObject" (hdc As Long,hObject As Long) As Long
Declare Function ImgDlgBitBlt Lib "gdi32" Alias "BitBlt" (hDestDC As Long,x As Long,y As Long,nWidth As Long,nHeight As Long,hSrcDC As Long,xSrc As Long,ySrc As Long,dwRop As Long) As Long
Declare Function ImgDlgDeleteDC Lib "gdi32" Alias "DeleteDC" (hdc As Long) As Long
Declare Function ImgDlgDeleteObject Lib "gdi32" Alias "DeleteObject" (hObject As Long) As Long
Declare Function ImgDlgDrawIcon Lib "user32" Alias "DrawIconEx" (hdc As Long,xLeft As Long,yTop As Long,hIcon As Long,cxWidth As Long,cyWidth As Long,istepIfAniCur As Long,hbrFlickerFreeDraw As Long,diFlags As Long) As Long
Declare Function ImgDlgExtractIcon Lib "shell32.dll" Alias "ExtractIconA" (hInst As Long,lpszExeFileName As String,nIconIndex As Long) As Long
Declare Function ImgDlgDestroyIcon Lib "user32" Alias "DestroyIcon" (hIcon As Long) As Long
Declare Function ImgDlgGetIconInfo Lib "user32" Alias "GetIconInfo" (hIcon As Long,piconinfo As ICONINFO_IMG) As Long
Declare Function ImgDlgGetObject Lib "gdi32" Alias "GetObjectA" (hObject As Long,nCount As Long, lpObject As TBITMAP_IMG) As Long
Declare Function ImgDlgLoadImage Lib "user32" Alias "LoadImageA" (hInst As Long,lpsz As String,dwImageType As Long,dwDesiredWidth As Long,dwDesiredHeight As Long,dwFlags As Long) As Long

Declare Function ImgDlgLoad Lib "NVIEWLIB" Alias "NViewLibLoad" (FileName As String,Progress As Integer) As Long
Declare Function ImgDlgSetLanguage Lib "NVIEWLIB" Alias "NViewLibSetLanguage" (Language As String) As Integer
Declare Function ImgDlgGetWidth Lib "NVIEWLIB" Alias "GetWidth" () As Integer
Declare Function ImgDlgGetHeight Lib "NVIEWLIB" Alias "GetHeight" () As Integer

Type QImageDialog Extends QObject
  Private:
    Form as QForm
    Label1 as Qlabel
    Label2 as QLabel
    Drive as QCombobox
    DirList AS QFileListbox
    FileList AS QFileListbox
    Name AS QEdit
    FileType AS QCombobox
    BtOpen AS QButton
    BtCancel AS QButton
    ScrollBox1 AS QScrollbox
    Image as QImage
    Bitmap as QBitmap
    Open as integer
    PopupMenu as QPopupMenu
    EnterKey as QMenuItem
    BoxWidth as integer
    BoxHeight as integer
    Path as string
    DllName as string
    info as ICONINFO_IMG
    infoBmp as TBITMAP_IMG
  Public:
    FileName as string Property Set SetFileName
    Caption as string Property Set SetCaption
    Filter as string Property Set SetFilter
    FilterIndex as Integer Property Set SetFilterIndex
    InitialDir as string
    DlgCaption(4) as string
    ErrorLanguage as string
    MultiSelect as boolean Property Set SetMultiSelect
    SelCount as integer Property Set SetSelCount
    Selected as QStringList

  Private:
  '======================================================
  ' Mйthode retourne le nombre de filtre type de fichier
  '======================================================
  Function FilterCount(Filter as string) as integer
    dim count as integer
    dim flag as boolean
    
    flag=false
    count=0
    while flag=false
      count++
      if Field$(Filter,"|",count)="" then flag=true
    wend
    result=count-1
  End Function

  '=================================================
  ' Mйthode retourne l'index champs
  '=================================================
  Function GetField(name as string,Filter as string) as integer
    dim i as integer
    
    if name<>"" and Filter<>"" then
      for i=1 to This.FilterCount(This.Filter)
        if Field$(Filter,"|",i)=name then
          result=i
          exit for
        end if
      next i
    else
      result=0
    end if
  End Function

  '=================================================
  ' Mйthode initialise les lecteurs prйsents
  '=================================================
  Sub GetDrives
   dim ASC_A as integer
   dim ASC_Z as integer
   dim i as integer
   dim name as string
   
   ASC_A=65
   ASC_Z=ASC_A+25
   This.Drive.Clear
   for i=ASC_A to ASC_Z
     if ImgDlgGetDrive(Chr$(i)&":\")<>1 then
       name=chr$(i)+":\"
       This.Drive.AddItems name
     end if
   next i
   for i=0 to This.Drive.ItemCount-1
     if instr(UCase$(This.Drive.Item(i)),UCase$(this.DirList.drive+":\"))>0 then
       this.Drive.ItemIndex=i
       exit for
     end if
   next i
  End Sub

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
    
    if this.bitmap.Width>this.BoxWidth or this.bitmap.Height>this.BoxHeight then
      if this.bitmap.Width>this.BoxWidth then
        reduction1=100-this.Ratio(this.bitmap.Width,this.BoxWidth)
      end if
      if this.bitmap.Height>this.BoxHeight then
        reduction2=100-this.Ratio(this.bitmap.Height,this.BoxHeight)
      end if
      if reduction1<reduction2 then
        reduction=reduction1
      else
        reduction=reduction2
      end if
      if reduction1=reduction2 then reduction=reduction1
    end if
    this.Image.left=int((this.ScrollBox1.Width-((this.bitmap.Width*reduction)/100))/2)
    this.Image.top=int((this.ScrollBox1.Height-((this.bitmap.Height*reduction)/100))/2)
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
      size=ImgDlgGetSystemDir(Varptr(lpBuffer),260)
      SystemDir=Left$(lpBuffer,size)
      if FileExists(SystemDir+"\"+this.DllName) then
        result=true
      else
        result=false
      end if
    end if    
  End Function
  
  '=================================================
  ' Mйthode retourne le repertoire formatй
  '=================================================
  Function GetFormatDir(directory as string) as string
    if rinstr(directory,"\")=len(directory) then
      result=directory
    else
      result=directory+"\"
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

    hBitmap=ImgDlgLoad(FileName,false)
    if hBitmap<>0 then
      this.bitmap.pixelformat=6
      this.bitmap.width=ImgDlgGetWidth()
      this.bitmap.height=ImgDlgGetHeight()
      hDC=ImgDlgCreateDC(this.bitmap.handle)
      hOldBitmap=ImgDlgSelectObject(hDC,hBitmap)
      ImgDlgBitBlt(this.bitmap.handle,0,0,this.bitmap.width,this.bitmap.height,hDC,0,0,&HCC0020)
      ImgDlgSelectObject(hDC,hOldBitmap)
      ImgDlgDeleteDC(hDC)
      ImgDlgDeleteObject(hBitmap)
    end if    
  End Sub

  '=================================================
  ' Mйthode ouvre les fichiers icone et curseur
  '=================================================
  Sub LoadIcon(FileName as string)
    dim hIcon as long
    
    if instr(lcase$(FileName),".ico")>0 then
      hIcon=ImgDlgLoadImage(0,FileName,1,0,0,&H10)
      if hIcon<>0 then
        ImgDlgGetIconInfo(hIcon,this.info)
        ImgDlgGetObject(this.info.hbmColor,SIZEOF(this.infoBmp),this.infoBmp)
        this.bitmap.pixelformat=6
        this.bitmap.width=this.infoBmp.bmWidth
        this.bitmap.height=this.infoBmp.bmHeight
        this.bitmap.fillRect(0,0,this.bitmap.width,this.bitmap.height,this.ScrollBox1.color)
        ImgDlgDrawIcon(this.bitmap.handle,0,0,hIcon,0,0,0,0,&h3)
        ImgDlgDestroyIcon(hIcon)
      end if
    else
      hIcon=ImgDlgExtractIcon(0,FileName,0)
      if hIcon<>0 then
        this.bitmap.pixelformat=6
        this.bitmap.width=32
        this.bitmap.height=32
        this.bitmap.fillRect(0,0,32,32,this.ScrollBox1.color)
        ImgDlgDrawIcon(this.bitmap.handle,0,0,hIcon,32,32,0,0,&h3)
        ImgDlgDestroyIcon(hIcon)
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
  
  '=================================================
  ' Mйthode change l'etat curseur
  '=================================================
  Sub WaitCursor(flag as boolean)
    dim value as integer
    
    if flag then
      value=-11
    else
      value=0
    end if
    this.Form.cursor=value
    this.Drive.cursor=value
    this.DirList.cursor=value
    this.FileList.cursor=value
    this.FileType.cursor=value
    this.BtOpen.cursor=value
    this.BtCancel.cursor=value
    this.ScrollBox1.cursor=value
    this.Image.cursor=value
  End Sub
      
  Public:
  '=================================================
  ' Proprietй dйfinition filtre type de fichier
  '=================================================
  Property Set SetFilter(filter as string)
    dim i as integer
    
    This.Filter=filter
    This.FileType.Clear
    if filter<>"" then
      for i=1 to This.FilterCount(This.Filter) step 2
        This.FileType.AddItems Field$(This.Filter,"|",i)
      next i
    end if
  End Property

  '=================================================
  ' Proprietй index filtre type de fichier
  '=================================================
  Property Set SetFilterIndex(FilterIndex as integer)
    dim i as integer
    
    if This.FileType.ItemCount>0 then
      This.FilterIndex=FilterIndex
      This.FileType.ItemIndex=FilterIndex-1
    end if
  End Property
        
  '=================================================
  ' Proprietй titre boite de dialogue
  '=================================================
  Property Set SetCaption(caption as string)
    This.Caption=caption
    This.Form.Caption=caption
  End Property
  
  '=================================================
  ' Proprietй sйlection multiple fichiers
  '=================================================
  Property Set SetMultiSelect(select as boolean)
    This.FileList.MultiSelect=select
    This.MultiSelect=select
  End Property

  '=================================================
  ' Proprietй nombre de fichiers sйlectionnйs
  '=================================================
  Property Set SetSelCount(count as integer)
    'Read only
  End Property
  
  '=================================================
  ' Proprietй nom fichier
  '=================================================
  Property Set SetFileName(filename as string)
   if instr(filename,"\")>0 then
     this.name.text=RIGHT$(filename,Len(filename)-RINSTR(filename,"\"))
     if DirExists(LEFT$(filename,RINSTR(filename,"\"))) then
       this.DirList.Directory=LEFT$(filename,RINSTR(filename,"\"))
       this.FileList.Directory=LEFT$(filename,RINSTR(filename,"\"))
     end if
   else
     this.name.text=filename
   end if
  End Property
    
  '=================================================
  ' Mйthode ouverture boite de dialogue
  '=================================================
  Function Execute() as boolean
    This.Label1.Caption=this.DlgCaption(1)
    This.Label2.Caption=this.DlgCaption(2)
    This.BtOpen.Caption=this.DlgCaption(3)
    This.BtCancel.Caption=this.DlgCaption(4)
    This.Open=False
    This.GetDrives
    if This.InitialDir<>"" then
      if DirExists(This.InitialDir) then
        this.DirList.Directory=This.InitialDir
        this.FileList.Directory=This.InitialDir
      end if
    else
      this.DirList.Directory=CurDir$
      this.FileList.Directory=CurDir$
    end if
    if This.FileType.ItemCount>0 then
      This.FileType.ItemIndex=This.FilterIndex-1
      This.FileList.Mask=Field$(This.Filter,"|",This.GetField(This.FileType.Item(This.FilterIndex-1),This.Filter)+1)
    end if
    ImgDlgSetFocus(This.Name.Handle) 
    This.Form.ShowModal
    Result=This.Open
  End Function
    
  '=================================================
  ' Evenement double click sur liste repertoires
  '=================================================
  Event DirList.OnDblClick
    ChDir(this.DirList.Item(this.DirList.ItemIndex)-"["-"]")
    this.DirList.Directory=CurDir$
    this.FileList.Directory=CurDir$
    this.Image.visible=false
    This.Name.Text=""
  End Event

  '=================================================
  ' Evenement changement sйlection lecteurs
  '=================================================
  Event Drive.OnChange
    this.DirList.Directory=this.Drive.item(this.Drive.itemindex)
    this.FileList.Directory=this.Drive.item(this.Drive.itemindex)
    this.Image.visible=false
    This.Name.Text=""
  End Event

  '=================================================
  ' Evenement changement sйlection type de fichiers
  '=================================================
  Event FileType.OnChange
    This.FilterIndex=This.FileType.ItemIndex+1
    This.FileList.Mask=Field$(This.Filter,"|",This.GetField(This.FileType.Item(This.FilterIndex-1),This.Filter)+1)
    This.FileList.Update
  End Event
  
  '=================================================
  ' Evenement click liste fichiers
  '=================================================
  Event FileList.OnClick
    This.Name.Text=RIGHT$(This.FileList.FileName,Len(This.FileList.FileName)-RINSTR(This.FileList.FileName,"\"))
    if instr(LCase$(This.FileList.FileName),".bmp")>0 then
      This.WaitCursor(true)
      this.bitmap.bmp=This.FileList.FileName
      this.ShowImage
      This.WaitCursor(false)
    elseif instr(LCase$(This.FileList.FileName),".ico")>0 or _
           instr(LCase$(This.FileList.FileName),".ani")>0 or _
           instr(LCase$(This.FileList.FileName),".cur")>0 then
      this.LoadIcon(This.FileList.FileName)
      this.ShowImage
    elseif this.DllFormat(This.FileList.FileName) then
      if this.DllExist() then
      	if this.ErrorLanguage<>"" then ImgDlgSetLanguage(this.ErrorLanguage)
        This.WaitCursor(true)
        this.LoadOtherImage(This.FileList.FileName)
        this.ShowImage
        This.WaitCursor(false)
      else
        this.Image.visible=false
      end if
    else
      this.Image.visible=false
    end if
  End Event
  
  '=================================================
  ' Evenement click sur bouton ouvrir
  '=================================================
  Event BtOpen.OnClick
    dim i as integer
    
    if This.Name.Text<>"" then
      This.Open=True
      This.FileName=This.GetFormatDir(this.FileList.Directory)+This.Name.Text
      if this.FileList.SelCount>1 then
      	this.SelCount=this.FileList.SelCount
      	This.Selected.Clear
        for i=0 to this.FileList.ItemCount-1
          if this.FileList.Selected(i) then
            This.Selected.AddItems(This.GetFormatDir(this.FileList.Directory)+this.FileList.Item(i))
          end if
        next i
      end if
      This.Form.ModalResult=1
    end if
  End Event

  '=================================================
  ' Evenement click sur bouton annuler
  '=================================================
  Event BtCancel.OnClick
    This.Form.ModalResult=1
  End Event

  '=================================================
  ' Evenement entrer sur liste repertoires
  '=================================================
  Event EnterKey.OnClick
    ChDir(this.DirList.Item(this.DirList.ItemIndex)-"["-"]")
    this.DirList.Directory=CurDir$
    this.FileList.Directory=CurDir$
    this.Image.visible=false
    This.Name.Text=""
  End Event
              
  Constructor
    DlgCaption(1)="File name:"
    DlgCaption(2)="File type:"
    DlgCaption(3)="Open"
    DlgCaption(4)="Cancel"
    FilterIndex=1
    Form.Caption="Open"
    Form.Width=422
    Form.Height=325
    Form.Center
    Form.borderstyle=3
    Label1.parent=this.form
    Label1.Caption=this.DlgCaption(1)
    Label1.Left=5
    Label1.Top=245
    Label1.AutoSize=True
    Label2.parent=this.form
    Label2.Caption=this.DlgCaption(2)
    Label2.Left=5
    Label2.Top=272
    Label2.AutoSize=True
    Drive.parent=this.form
    Drive.TabOrder=1
    Drive.Style=2
    Drive.Left=5
    Drive.Top=5
    DirList.parent=this.form
    DirList.Left=5
    DirList.Top=30
    DirList.Height=100
    DirList.ShowIcons = True
    DirList.AddFileTypes(4)
    DirList.DelFileTypes(6) 
    DirList.TabOrder=2
    FileList.parent=this.form
    FileList.Left=5
    FileList.Top=135
    FileList.Height=100
    FileList.TabOrder=3
    Name.parent=this.form
    Name.Left=106
    Name.Top=242
    Name.Width=217
    Name.TabOrder=4
    FileType.parent=this.form
    FileType.Style=2
    FileType.Left=106
    FileType.Top=270
    FileType.Width=217
    FileType.TabOrder=5
    BtOpen.parent=this.form
    BtOpen.Caption=this.DlgCaption(3)
    BtOpen.Left=334
    BtOpen.Top=242
    BtOpen.Height=22
    BtOpen.TabOrder=6
    BtCancel.parent=this.form
    BtCancel.Caption=this.DlgCaption(4)
    BtCancel.Left=334
    BtCancel.Top=270
    BtCancel.Height=22
    BtCancel.TabOrder=7
    ScrollBox1.parent=this.form
    ScrollBox1.Left=158
    ScrollBox1.Top=5
    ScrollBox1.Width=250
    ScrollBox1.Height=230
    BoxWidth=220
    BoxHeight=220
    Image.Parent=This.ScrollBox1
    Image.Visible=False
    Image.stretch=true
    EnterKey.ShortCut="Enter"
    EnterKey.Visible=False
    PopupMenu.AddItems(This.EnterKey)
    DirList.PopupMenu=This.PopUpMenu
    Path=left$(command$(0),rinstr(command$(0),"\"))
    DllName="Nviewlib.dll"
  End Constructor
End Type
$ENDIF   ' IncManager: __QIMAGEDIALOG_INC
