'=======================================================
' Type Objet
' Classe QTreeViewEx version 1.1
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

Declare Sub OnEnumChildItems_eventTemplate(index as integer,text as string,Node as integer)


Type QTreeViewEx Extends QTreeView
  OnEnumChildItems as EVENT(OnEnumChildItems_eventTemplate)
          
  '==========================================
  ' mйthode retourne l'index nom de l'item
  '==========================================
  Function IndexOf(name as string) as integer
    dim i as integer
    
    if name<>"" then
      result=-1
      for i=0 to this.ItemCount-1
        if this.item(i).text=name then
          result=i
          exit for
        end if
      next i
    else
      result=-1
    end if
  End Function
  
  '=============================================
  ' mйthode retourne le nom du noeud d'un index
  '=============================================
  Function GetNameNode(index as integer) as string
    dim i as integer
    
    if index>-1 and index<=this.ItemCount-1 then
      for i=index to 0 step -1
        if this.item(i).count>0 and this.item(i).level<this.item(index).level then
          result=this.item(i).text
          exit for
        end if
      next i
    end if
  End Function

  '=============================================
  ' mйthode retourne l'index noeud d'un index
  '=============================================
  Function GetIndexNode(index as integer) as integer
    dim i as integer
    
    if index>-1 and index<=this.ItemCount-1 then
      result=-1
      for i=index to 0 step -1
        if this.item(i).count>0 and this.item(i).level<this.item(index).level then
          result=i
          exit for
        end if
      next i
    else
      result=-1
    end if
  End Function
      
  '=============================================
  ' mйthode retourne l'etat noeud d'un index
  '=============================================
  Function IsNode(index as integer) as boolean
    if index>-1 and index<=this.ItemCount-1 then
      result=Abs(this.item(index).count>0)
    end if
  End Function
    
  '=============================================
  ' mйthode retourne le nombre de niveaux
  '=============================================
  Function GetLevelCount() as integer
    dim i as integer
    defint level=0
    
    for i=0 to this.ItemCount-1
      if this.item(i).level>level then level=this.item(i).level
    next i
    result=level
  End Function
    
  '=============================================
  ' mйthode enumйration des items noeud
  '=============================================
  Sub EnumChildItems(index as integer)
    dim i as integer
  
    if this.IsNode(index) then
      for i=index+1 to this.ItemCount-1
        if this.GetIndexNode(i)=index then
          if this.OnEnumChildItems<>0 then CALLFUNC(this.OnEnumChildItems,i,this.item(i).text,index)
        end if
      next i
    end if
  End Sub
End Type
