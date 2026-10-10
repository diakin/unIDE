'=======================================================
' Type Objet
' Classe QFileListView version 1.0
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

declare function SetFocusFileListView LIB "USER32" ALIAS "SetFocus" (Handle as long) as long

declare sub FileSelect_EventTemplate(File as string)
declare sub FileChange_EventTemplate(File as string)

Type QFileListView extends QListView
  Private:
    ColumnsInitialized as boolean
  Public:
    Filename as string property set SetFileName
    LargeImageList as QImageList
    SmallImageList as QImageList
    ExtensionsList as QStringList
    ColumnCaption(4) as string
    Directory as string property set SetDirectory
    Mask as string property set SetMask
    Color as long property set SetColor
    OnFileSelect as event (FileSelect_EventTemplate)
    OnFileChange as event (FileChange_EventTemplate)

  Private:

  '========================================
  ' Mйthode affectation icone
  '========================================
  Sub SetItemImage (Extension as string)
    dim i as integer
    
    this.Item(this.ItemCount-1).ImageIndex=0
    for i=0 to this.ExtensionsList.ItemCount-1
      if lcase$(Extension)=this.ExtensionsList.Item(i) then
        this.Item(this.ItemCount-1).ImageIndex=i+1
        exit for
      end if
    next i
  End Sub

  '========================================
  ' Mйthode ajout dйtails de fichier
  '========================================
  Sub AddFileProperties (Extension as string)
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
    this.AddSubItem(this.ItemCount-1,ucase$(Extension))
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

  '========================================
  ' Mйthode retourne le nombre d'extension
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

  '================================================
  ' Mйthode affichage des fichiers type du masque
  '================================================
  Sub LoadFiles(Mask as string)
    dim File as string
    dim i as integer
    dim Extension as string
    
    File=Dir$(this.Directory+"\"+Mask,0)
    if File<>"" then
      Extension=""
      this.AddItems File
      if instr(File,".",0)>0 then
        Extension=right$(File,instr(reverse$(File),".",0)-1)
        this.SetItemImage(Extension)
      else
        this.Item(this.ItemCount-1).ImageIndex=0
      end if
      this.AddFileProperties (Extension)
      while File<>""
        File=Dir$
        if File<>"" then
          Extension=""
          this.AddItems File
          if instr(File,".",0)>0 then
            Extension=right$(File,instr(reverse$(File),".",0)-1)
            this.SetItemImage (Extension)
          else
            this.Item(this.ItemCount-1).ImageIndex=0
          end if
          this.AddFileProperties (Extension)
        end if
      wend
    end if
  End Sub

  '========================================
  ' Mйthode affichage fichier
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
  ' Mйthode actualisation de la liste
  '========================================
  Sub Refresh
    this.Clear
    this.Load
    if this.ColumnsInitialized=false then
      this.ClearColumns
      this.AddColumns this.ColumnCaption(1),this.ColumnCaption(2),this.ColumnCaption(3),this.ColumnCaption(4)
      this.Column(0).Width=150
      this.Column(1).Width=60
      this.Column(2).Width=60
      this.Column(3).Width=120
      this.ColumnsInitialized=true
    end if
  End Sub

  '========================================
  ' Mйthode focus sur controle
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
      this.FileName=this.Directory+"\"+this.Item(this.ItemIndex).Caption
      if this.OnFileChange<>0 then CallFunc(this.OnFileChange,this.FileName)
    else
      this.FileName=""
    end if
  End Event
    
  '========================================
  ' Proprietй couleur
  '========================================
  Property set SetColor(color as long)
    super.color=color
    this.color=color
    this.LargeImageList.bkcolor=color
    this.SmallImageList.bkcolor=color
  End Property
  
  '========================================
  ' Proprietй repertoire
  '========================================
  property set SetDirectory (Dir as string)
    if DirExists(Dir) then
      this.Directory=Dir
      this.Refresh
    end if
  end property

  '========================================
  ' Proprietй masque extension fichier
  '========================================
  Property set SetMask(MaskSet as string)
    this.Mask=MaskSet
    this.Refresh
  End Property
  
  '========================================
  ' Proprietй nom fichier
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
    LargeImageList.Width=32
    LargeImageList.Height=32
    LargeImageList.bkcolor=super.color
    SmallImageList.bkcolor=super.color
    LargeImageList.masked=false
    SmallImageList.masked=false
    LargeImages=This.LargeImageList
    SmallImages=this.SmallImageList
  end constructor
End Type
