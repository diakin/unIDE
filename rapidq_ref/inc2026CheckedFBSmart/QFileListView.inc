'=======================================================
' Type Objet
' Classe QFileListView version 1.1
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

$IFNDEF __WIN32API				   'windows 32 definitions
Type SHFILEINFO
    hIcon As Long                      '  out: icon
    iIcon As integer                   '  out: icon index
    dwAttributes As dword              '  out: SFGAO_ flags
    szDisplayName As String * 260      '  out: display name (or path)
    szTypeName As String * 80          '  out: type name
End Type


Const SHGFI_DISPLAYNAME    = &H200
Const SHGFI_TYPENAME       = &H400
Const SHGFI_SYSICONINDEX   = &H4000
Const SHGFI_LARGEICON      = &H0
Const SHGFI_SMALLICON      = &H1
Const SHGFI_ICON           = &H100

Const LVM_FIRST            = &H1000
Const LVM_SETIMAGELIST     = (LVM_FIRST + 3)
Const LVM_GETBKIMAGEA      = (LVM_FIRST + 69)
Const LVM_SETITEMPOSITION  = (LVM_FIRST + 15)
Const LVM_SETBKIMAGEA      = (LVM_FIRST + 68)
Const LVBKIF_SOURCE_URL    = 2
Const LVBKIF_STYLE_NORMAL  = &H0
Const LVSIL_NORMAL         = 0
Const LVSIL_SMALL          = 1


Declare Function SHGetFileInfoFileListView Lib "shell32.dll" Alias "SHGetFileInfoA" (pszPath As String,dwFileAttributes As Long,psfi As SHFILEINFO,cbFileInfo As Long,uFlags As Long) As Dword
Declare Function DestroyIconFileListView Lib "user32" Alias "DestroyIcon" (ByVal hIcon As Long) As Long
declare function SetFocusFileListView Lib "user32" Alias "SetFocus" (Handle as long) as long
$ENDIF

declare sub FileSelect_EventTemplate(File as string)
declare sub FileChange_EventTemplate(File as string)

Type QFileListView extends QListView
  Private:
    ColumnsInitialized as boolean
    FI As SHFILEINFO
  Public:
    Filename as string property set SetFileName
    ColumnCaption(4) as string
    Directory as string property set SetDirectory
    Mask as string property set SetMask
    OnFileSelect as event (FileSelect_EventTemplate)
    OnFileChange as event (FileChange_EventTemplate)

  Private:
  
  '=================================================
  ' Méthode retourne le repertoire formaté
  '=================================================
  Function GetFormatDir(directory as string) as string
    if rinstr(directory,"\")=len(directory) then
      result=directory
    else
      result=directory+"\"
    end if
  End Function      

  '========================================
  ' Méthode retourne le nombre d'extension
  '========================================
  Function ExtCount(Extension as string) as integer
    dim count as integer
    dim flag as boolean
    
    flag=false
    count=0
    while flag=false
      count++
      if Field$(Extension,";",count)="" then flag=true
    wend
    result=count-1
  End Function

  '========================================
  ' Méthode ajout détails de fichier
  '========================================
  Sub AddFileProperties
    dim SizeString as string
    dim Month as string
    dim Day as string
    dim Year as string
    dim Hours as string
    dim Minute as string
    
    if FileRec.Size/1024>=1 then
      SizeString=str$(int(FileRec.Size/1024))+" KB"
    else
      SizeString="1 KB"
    end if
    this.AddSubItem(this.ItemCount-1,SizeString)
    this.AddSubItem(this.ItemCount-1,this.FI.szTypeName)
    Month=Field$(FileRec.Date,"-",1)
    if len(Month)=1 then Month="0"+Month
    Day=Field$(FileRec.Date,"-",2)
    if len(Day)=1 then Day="0"+Day
    Year=Field$(FileRec.Date,"-",3)
    Hours=Field$(FileRec.Time,":",1)
    if len(Hours)=1 then Hours="0"+Hours
    Minute=Field$(FileRec.Time,":",2)
    if len(Minute)=1 then Minute="0"+Minute
    this.AddSubItem (this.ItemCount-1,Day+"/"+Month+"/"+Year+space$(2)+Hours+":"+Minute)
  End Sub

  '================================================
  ' Méthode affichage des fichiers type du masque
  '================================================
  Sub LoadFiles(Mask as string)
    dim File as string
    dim i as integer
    
    File=Dir$(This.GetFormatDir(this.Directory)+Mask,0)
    if File<>"" then
      this.AddItems File
      if instr(File,".",0)>0 then
        SHGetFileInfoFileListView(This.GetFormatDir(This.Directory)+File,0,this.FI,sizeof(this.FI),SHGFI_DISPLAYNAME Or SHGFI_TYPENAME or SHGFI_ICON)
        this.Item(this.ItemCount-1).ImageIndex=this.FI.iIcon
        DestroyIconFileListView this.FI.hIcon
      end if
      this.AddFileProperties
      while File<>""
        File=Dir$
        if File<>"" then
          this.AddItems File
          if instr(File,".",0)>0 then
            SHGetFileInfoFileListView(This.GetFormatDir(This.Directory)+File,0,this.FI,sizeof(this.FI),SHGFI_DISPLAYNAME Or SHGFI_TYPENAME or SHGFI_ICON)
            this.Item(this.ItemCount-1).ImageIndex=this.FI.iIcon
            DestroyIconFileListView this.FI.hIcon
          end if
          this.AddFileProperties
        end if
      wend
    end if
  End Sub

  '========================================
  ' Méthode affichage fichier
  '========================================
  Sub Load
    dim count as integer
    dim i as integer
    dim mask as string
    
    count=this.ExtCount(this.mask)
    if count>0 then
      for i=1 to count
        mask=Field$(this.mask,";",i)
        this.LoadFiles(mask)
      next i
    else
      this.LoadFiles(this.mask)
    end if
  End Sub
  
  Public:

  '========================================
  ' Méthode actualisation de la liste
  '========================================
  Sub Refresh
    dim himlLarge as dword
    dim himlSmall as dword
      
    this.Clear
    this.SortType=0
    himlLarge=SHGetFileInfoFileListView("c:\",0,this.FI,sizeof(this.FI),SHGFI_SYSICONINDEX or SHGFI_LARGEICON)
    himlSmall=SHGetFileInfoFileListView("c:\",0,this.FI,sizeof(this.FI),SHGFI_SYSICONINDEX or SHGFI_SMALLICON)
    sendmessage This.handle,LVM_SETIMAGELIST,LVSIL_NORMAL,himlLarge
    sendmessage This.handle,LVM_SETIMAGELIST,LVSIL_SMALL,himlSmall
    this.Load
    if this.ColumnsInitialized=false then
      this.ClearColumns
      this.AddColumns this.ColumnCaption(1),this.ColumnCaption(2),this.ColumnCaption(3),this.ColumnCaption(4)
      this.Column(0).Width=150
      this.Column(1).Width=80
      this.Column(2).Width=80
      this.Column(3).Width=120
      this.ColumnsInitialized=true
    end if
    this.SortType=2
  End Sub

  '========================================
  ' Méthode focus sur controle
  '========================================
  Sub SetFocus
    SetFocusFileListView(this.Handle)
  End Sub
  
  '========================================
  ' Evenement double click
  '========================================
  Event OnDblClick
    if this.OnFileSelect<>0 then CallFunc(this.OnFileSelect,this.FileName)
  End Event

  '========================================
  ' Evenement pression touche clavier
  '========================================
  Event OnKeyPress(Key as byte)
    if Key=13 and this.FileName<>"" then
      if this.OnFileSelect<>0 then CallFunc(this.OnFileSelect,this.FileName)
    end if
  End Event

  '========================================
  ' Evenement changement selection
  '========================================
  Event OnChange
    if this.ItemIndex>=0 then
      this.FileName=This.GetFormatDir(this.Directory)+this.Item(this.ItemIndex).Caption
      if this.OnFileChange<>0 then CallFunc(this.OnFileChange,this.FileName)
    else
      this.FileName=""
    end if
  End Event
      
  '========================================
  ' Proprieté repertoire
  '========================================
  property set SetDirectory (Dir as string)
    if DirExists(Dir) then
      this.Directory=Dir
      this.Refresh
    end if
  end property

  '========================================
  ' Proprieté masque extension fichier
  '========================================
  Property set SetMask(MaskSet as string)
    this.Mask=MaskSet
    this.Refresh
  End Property
  
  '========================================
  ' Proprieté nom fichier
  '========================================
  Property set SetFileName(filename as string)
    'read only
  End Property
  
  constructor
    Width=400
    Height=200
    Directory=CurDir$
    Filename=""
    Mask="*.*"
    ReadOnly=true
    ColumnsInitialized=false
    ColumnCaption(1)="Name"
    ColumnCaption(2)="Size"
    ColumnCaption(3)="Type"
    ColumnCaption(4)="Modified"
  end constructor
End Type
