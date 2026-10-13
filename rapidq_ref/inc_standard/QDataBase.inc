$IFNDEF __QDATABASE_INC   ' IncManager: include guard
$DEFINE __QDATABASE_INC
'=======================================================
' Type Objet
' Classe QDataBase version 1.0
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

Type TDbHeader
  RecordCount as string*8
  RecordLen as string*8
End Type

Const ErrDbCreate=1
Const ErrDbOpen=2
Const ErrDbFile=3
Const ErrDbIndex=4
Const ErrDbRecordEmpty=5
Const ErrDbRecordSize=6

Declare Sub OnSearch_eventTemplate(index as long)

Type QDataBase extends QObject
  Private:
    Mem as QMemoryStream
    File as QFileStream
    DbInfo as TDbHeader
    RecordFormat as string
    RecordLen as long
    Offset as long
  Public:
    OnSearch as EVENT(OnSearch_eventTemplate)
    FileName as string Property Set SetFileName
    RecordSize as long Property Set SetRecordSize
    RecordCount as long Property Set SetRecordCount
    FieldCount as long Property Set SetFieldCount
    Error as integer Property Set SetError

  Private:

  Property Set SetFileName(filename as string)
    'read only
  End Property

  Property Set SetRecordSize(recordsize as long)
    'read only
  End Property

  Property Set SetRecordCount(recordcount as long)
    'read only
  End Property

  Property Set SetFieldCount(fieldcount as long)
    'read only
  End Property

  Property Set SetError(error as long)
    'read only
  End Property

  '=====================================================
  ' mйthode retourne la taille en byte d'un record
  '=====================================================
  Function GetRecordSize(Record as string) as long
    defstr buffer=space$(1)
    defint index=0
    
    while buffer<>""
      index++
      buffer=field$(Record,",",index)
      if buffer<>"" then
        result=result+val(field$(buffer,":",2))
      end if
    wend
  End Function

  '=====================================================
  ' mйthode retourne le nombre de champs
  '=====================================================
  Function GetFieldCount(Record as string) as long
    if tally(Record,",")<>0 then result=tally(Record,",")+1
  End Function

  Public:

  '=====================================================
  ' mйthode retourne le nom d'un champ par son index
  '=====================================================
  Function GetFieldName(index as long) as string
    dim buffer as string
    
    if index<=this.FieldCount and this.FieldCount>0 then
      buffer=field$(this.RecordFormat,",",index)
      if buffer<>"" then result=field$(buffer,":",1)
    end if
  End Function
  
  '=====================================================
  ' mйthode retourne l'index champ par son nom
  '=====================================================
  Function GetFieldIndex(name as string) as long
    defstr buffer=space$(1)
    defint index=0
    
    while buffer<>""
      index++
      buffer=field$(this.RecordFormat,",",index)
      if instr(LCase$(buffer),LCase$(name))>0 then result=index
    wend
  End Function
 
  '=====================================================
  ' mйthode retourne la taille d'un champ par son index
  '=====================================================      
  Function GetFieldSize(index as long) as long
    dim buffer as string
    
    if index<=this.FieldCount and this.FieldCount>0 then
      buffer=field$(this.RecordFormat,",",index)
      if buffer<>"" then result=val(field$(buffer,":",2))
    end if
  End Function
  
  '=====================================================
  ' mйthode retourne йtat ouvert de la base
  '=====================================================      
  Function IsOpen() as boolean
    if this.FileName<>"" then
      if FileExists(this.FileName) then
        result=true
      else
        result=false
      end if
    else
      result=false
    end if
  End Function

  '=====================================================
  ' mйthode crйation base
  '=====================================================      
  Function Create(FileName as string,RecordFormat as string) as boolean
    if Len(RecordFormat)=0 then
      this.error=ErrDbRecordEmpty
      result=false
      exit function
    end if
    this.RecordCount=0
    this.RecordLen=Len(RecordFormat)
    This.DbInfo.RecordCount=str$(this.RecordCount)
    This.DbInfo.RecordLen=str$(this.RecordLen)
    if this.File.Open(FileName,65535) then
      this.file.writestr(This.DbInfo.RecordCount,8)
      this.file.writestr(This.DbInfo.RecordLen,8)
      this.file.writestr(RecordFormat,Len(RecordFormat))
      this.File.Close
      this.RecordFormat=RecordFormat
      this.Offset=16+Len(this.RecordFormat)
      this.RecordSize=this.GetRecordSize(RecordFormat)
      this.FieldCount=this.GetFieldCount(RecordFormat)
      this.FileName=FileName
      this.error=0
      result=true
    else
      this.error=ErrDbCreate
      result=false
    end if
  End Function
  
  '=====================================================
  ' mйthode ouverture base
  '=====================================================      
  Function Open(FileName as string) as boolean
    if FileExists(FileName) then
      if this.File.Open(FileName,0) then
        this.RecordCount=val(this.File.readstr(8))
        this.RecordLen=val(this.File.readstr(8))
        this.RecordFormat=rtrim$(this.File.readstr(this.RecordLen))
        this.File.Close
        this.Offset=16+Len(this.RecordFormat)
        this.RecordSize=this.GetRecordSize(this.RecordFormat)
        this.FieldCount=This.GetFieldCount(this.RecordFormat)
        this.FileName=FileName
        this.error=0
        result=true
      else
        this.error=ErrDbOpen
        result=false
      end if
    else
      this.error=ErrDbFile
      result=false
    end if
  End Function
  
  '=====================================================
  ' mйthode fermeture base
  '=====================================================
  Sub Close
    this.error=0
    this.RecordCount=0
    this.RecordLen=0
    this.RecordFormat=""
    this.Offset=0
    this.RecordSize=0
    this.FieldCount=0
    this.FileName=""
  End Sub

  '=====================================================
  ' mйthode ajout record
  '=====================================================
  Function AddRecord(record as string) as boolean    
    if this.IsOpen=false or Len(record)=0 or Len(record)<>this.RecordSize then
      if this.IsOpen=false then this.error=ErrDbOpen
      if Len(record)=0 then this.error=ErrDbRecordEmpty
      if Len(record)<>this.RecordSize then this.error=ErrDbRecordSize
      result=false
      Exit Function
    end if
    if this.File.Open(this.FileName,1) then
      this.File.seek(0,0)
      this.RecordCount++
      this.DbInfo.RecordCount=str$(this.RecordCount)
      this.file.writestr(This.DbInfo.RecordCount,8)
      this.File.seek(0,2)
      this.file.writestr(record,this.RecordSize)
      this.file.close
      this.error=0
      result=true
    else
      this.error=ErrDbOpen
      result=false
    end if
  End Function
  
  '=====================================================
  ' mйthode ajout record udt
  '=====================================================
  Function AddRecordUdt(record as long) as boolean
    dim buffer as string
    
    if this.IsOpen=false or record=0 then
      if this.IsOpen=false then this.error=ErrDbOpen
      if record=0 then this.error=ErrDbRecordEmpty
      result=false
      Exit Function
    end if
    this.Mem.Size=this.RecordSize
    this.Mem.Position=0
    this.Mem.MemCopyFrom(record,this.RecordSize)
    this.Mem.Position=0
    buffer=this.Mem.Readstr(this.RecordSize)
    this.Mem.Size=0
    this.Mem.close
    if this.File.Open(this.FileName,1) then
      this.File.seek(0,0)
      this.RecordCount++
      this.DbInfo.RecordCount=str$(this.RecordCount)
      this.file.writestr(This.DbInfo.RecordCount,8)
      this.File.seek(0,2)
      this.file.writestr(buffer,this.RecordSize)
      this.file.close
      this.error=0
      result=true
    else
      this.error=ErrDbOpen
      result=false
    end if
  End Function

  '=====================================================
  ' mйthode modifie record
  '=====================================================
  Function SaveRecord(index as long,record as string) as boolean
    dim pointer as long
    
    if this.IsOpen=false or Len(record)=0 or Len(record)<>this.RecordSize then
      if this.IsOpen=false then this.error=ErrDbOpen
      if Len(record)=0 then this.error=ErrDbRecordEmpty
      if Len(record)<>this.RecordSize then this.error=ErrDbRecordSize
      result=false
      Exit Function
    end if
    if index>0 and index<=this.RecordCount then
      pointer=this.offset+(this.RecordSize*(index-1))
      if this.File.Open(this.FileName,1) then
        this.File.seek(pointer,0)
        this.file.writestr(record,this.RecordSize)
        this.file.close
        this.error=0
        result=true
      else
        this.error=ErrDbOpen
        result=false
      end if
    else
      this.error=ErrDbIndex
      result=false
    end if
  End Function

  '=====================================================
  ' mйthode modifie record udt
  '=====================================================
  Function SaveRecordUdt(index as long,record as long) as boolean
    dim pointer as long
    dim buffer as string
    
    if this.IsOpen=false or record=0 then
      if this.IsOpen=false then this.error=ErrDbOpen
      if record=0 then this.error=ErrDbRecordEmpty
      result=false
      Exit Function
    end if
    if index>0 and index<=this.RecordCount then
      pointer=this.offset+(this.RecordSize*(index-1))
      this.Mem.Size=this.RecordSize
      this.Mem.Position=0
      this.Mem.MemCopyFrom(record,this.RecordSize)
      this.Mem.Position=0
      buffer=this.Mem.Readstr(this.RecordSize)
      this.Mem.Size=0
      this.Mem.close
      if this.File.Open(this.FileName,1) then
        this.File.seek(pointer,0)
        this.file.writestr(buffer,this.RecordSize)
        this.file.close
        this.error=0
        result=true
      else
        this.error=ErrDbOpen
        result=false
      end if
    else
      this.error=ErrDbIndex
      result=false
    end if
  End Function
    
  '=====================================================
  ' mйthode lit record
  '=====================================================
  Function GetRecord(index as long,byref record as string) as boolean
    dim pointer as long
    dim buffer as string
    
    if this.IsOpen=false then
      this.error=ErrDbOpen
      result=false
      Exit Function
    end if
    if index>0 and index<=this.RecordCount then
      pointer=this.offset+(this.RecordSize*(index-1))
      if this.File.Open(this.FileName,0) then
        this.File.seek(pointer,0)
        buffer=this.file.readstr(this.RecordSize)
        record=left$(buffer,this.RecordSize)
        this.file.close
        this.error=0
        result=true
      else
        this.error=ErrDbOpen
        result=false
      end if
    else
      this.error=ErrDbIndex
      result=false
    end if
  End Function ' inc2026: было End Sub у Function GetRecord (строка 352)

  '=====================================================
  ' mйthode lit record udt
  '=====================================================
  Function GetRecordUdt(index as long,record as long) as boolean
    dim pointer as long
    dim buffer as string
    
    if this.IsOpen=false or record=0 then
      if this.IsOpen=false then this.error=ErrDbOpen
      if record=0 then this.error=ErrDbRecordEmpty
      result=false
      Exit Function
    end if
    if index>0 and index<=this.RecordCount then
      pointer=this.offset+(this.RecordSize*(index-1))
      if this.File.Open(this.FileName,0) then
        this.File.seek(pointer,0)
        buffer=this.file.readstr(this.RecordSize)
        buffer=left$(buffer,this.RecordSize)
        this.file.close
        this.Mem.Size=this.RecordSize
        this.Mem.Position=0
        this.Mem.writestr(buffer,this.RecordSize)
        this.Mem.Position=0
        this.Mem.MemCopyTo(record,this.RecordSize)
        this.Mem.size=0
        this.Mem.close
        this.error=0
        result=true
      else
        this.error=ErrDbOpen
        result=false
      end if
    else
      this.error=ErrDbIndex
      result=false
    end if
  End Function ' inc2026: было End Sub у Function GetRecordUdt (строка 383)

  '=====================================================
  ' mйthode supprime record par son index
  '=====================================================
  Function DelRecord(index as long) as boolean
    dim i as integer    
    dim buffer as string

    if this.IsOpen=false then
      this.error=ErrDbOpen
      result=false
      Exit Function
    end if
    if index>0 and index<=this.RecordCount then
      if this.File.Open(this.FileName,0) then
        this.Mem.CopyFrom(this.File,this.file.size)
        this.file.close
        this.Mem.seek(this.offset,0)
        if this.File.Open(this.FileName,65535) then
          this.DbInfo.RecordCount=str$(this.RecordCount-1)
          this.DbInfo.RecordLen=str$(this.RecordLen)
          this.file.writestr(This.DbInfo.RecordCount,8)
          this.file.writestr(This.DbInfo.RecordLen,8)
          this.file.writestr(this.RecordFormat,Len(this.RecordFormat))
          for i=1 to this.RecordCount 
            if index<>i then
              this.file.writestr(this.Mem.readstr(this.RecordSize),this.RecordSize)
            else
              buffer=this.Mem.readstr(this.RecordSize)
            end if
          next i
          this.RecordCount--
          this.file.close
          this.Mem.size=0
          this.Mem.close
          this.error=0
          result=true
        else
          this.error=ErrDbCreate
          result=false
        end if
      else
        this.error=ErrDbOpen
        result=false
      end if
    else
      this.error=ErrDbIndex
      result=false
    end if
  End Function

  '=====================================================
  ' mйthode recherche chaine dans record
  '=====================================================
  Function SearchByRecord(name as string) as boolean
    dim i as integer    
    dim index as integer    
    dim buffer as string
    defint count=0
    defstr found=""

    if this.IsOpen=false then
      this.error=ErrDbOpen
      result=false
      Exit Function
    end if
    if this.File.Open(this.FileName,0) then
      this.File.seek(this.offset,0)
      for i=1 to this.RecordCount
        buffer=this.File.readstr(this.RecordSize)
        if instr(LCase$(buffer),LCase$(name))>0 then
          found=found+str$(i)+","
          count++
        end if
      next i
      this.file.close
      if count>0 then
        found=left$(found,len(found)-1)
        for i=1 to count
          index=val(field$(found,",",i))
          if this.OnSearch<>0 then CALLFUNC(this.OnSearch,index)
        next i
        this.error=0
        result=true
      else
        this.error=0
        result=false
      end if
    else
      this.error=ErrDbOpen
      result=false
    end if
  End Function

  '=====================================================
  ' mйthode recherche chaine dans champs
  '=====================================================
  Function SearchByField(name as string,fieldIndex as long) as boolean
    dim i as integer    
    dim j as integer    
    dim index as integer    
    dim buffer as string
    defint count=0
    defstr found=""
    defint pointer=0
    defint size=0

    if this.IsOpen=false then
      this.error=ErrDbOpen
      result=false
      Exit Function
    end if
    if fieldIndex>1 then
      for j=1 to fieldIndex-1
        pointer=pointer+this.GetFieldSize(j)
      next j
    end if
    size=this.GetFieldSize(fieldIndex)
    if this.File.Open(this.FileName,0) then
      this.File.seek(this.offset,0)
      for i=1 to this.RecordCount
        buffer=this.File.readstr(this.RecordSize)
        buffer=mid$(buffer,pointer+1,size) ' inc2026: pointer+1 вместо pointer: pointer - сумма размеров предыдущих полей (строки 530-535, отсчёт с 0), а MID$ считает позицию с 1 (документация MID$: MID$("Hello",3,2) = "ll"); было - текст поля со сдвигом на символ влево, у первого поля MID$(...,0,...)
        if instr(LCase$(buffer),LCase$(name))>0 then
          found=found+str$(i)+","
          count++
        end if
      next i
      this.file.close
      if count>0 then
        found=left$(found,len(found)-1)
        for i=1 to count
          index=val(field$(found,",",i))
          if this.OnSearch<>0 then CALLFUNC(this.OnSearch,index)
        next i
        this.error=0
        result=true
      else
        this.error=0
        result=false
      end if
    else
      this.error=ErrDbOpen
      result=false
    end if
  End Function

  '=====================================================
  ' mйthode recherche par opйrateur dans champs
  '=====================================================
  Function SearchByRequest(operator as string,value as string,bNum as boolean,fieldIndex as long) as boolean
    dim i as integer    
    dim j as integer    
    dim index as integer    
    dim buffer as string
    defint count=0
    defstr found=""
    defint pointer=0
    defint size=0

    if this.IsOpen=false then
      this.error=ErrDbOpen
      result=false
      Exit Function
    end if
    if fieldIndex>1 then
      for j=1 to fieldIndex-1
        pointer=pointer+this.GetFieldSize(j)
      next j
    end if
    size=this.GetFieldSize(fieldIndex)
    if this.File.Open(this.FileName,0) then
      this.File.seek(this.offset,0)
      for i=1 to this.RecordCount
        buffer=this.File.readstr(this.RecordSize)
        buffer=mid$(buffer,pointer+1,size) ' inc2026: pointer+1 вместо pointer: pointer - сумма размеров предыдущих полей (строки 583-588, отсчёт с 0), а MID$ считает позицию с 1 (документация MID$: MID$("Hello",3,2) = "ll"); было - текст поля со сдвигом на символ влево, у первого поля MID$(...,0,...)
        buffer=ltrim$(rtrim$(buffer))
        operator=ltrim$(rtrim$(operator))
        select case operator
          case "<"
            if bNum then
              if val(buffer)<val(value) then
                found=found+str$(i)+","
                count++
              end if
            else
              if buffer<value then
                found=found+str$(i)+","
                count++
              end if
            end if
          case ">"
            if bNum then
              if val(buffer)>val(value) then
                found=found+str$(i)+","
                count++
              end if
            else
              if buffer>value then
                found=found+str$(i)+","
                count++
              end if
            end if
          case "="
            if bNum then
              if val(buffer)=val(value) then
                found=found+str$(i)+","
                count++
              end if
            else
              if buffer=value then
                found=found+str$(i)+","
                count++
              end if
            end if
          case "<="
            if bNum then
              if val(buffer)<=val(value) then
                found=found+str$(i)+","
                count++
              end if
            else
              if buffer<=value then
                found=found+str$(i)+","
                count++
              end if
            end if
          case ">="
            if bNum then
              if val(buffer)>=val(value) then
                found=found+str$(i)+","
                count++
              end if
            else
              if buffer>=value then
                found=found+str$(i)+","
                count++
              end if
            end if
          case "<>"
            if bNum then
              if val(buffer)<>val(value) then
                found=found+str$(i)+","
                count++
              end if
            else
              if buffer<>value then
                found=found+str$(i)+","
                count++
              end if
            end if
        end select
      next i
      this.file.close
      if count>0 then
        found=left$(found,len(found)-1)
        for i=1 to count
          index=val(field$(found,",",i))
          if this.OnSearch<>0 then CALLFUNC(this.OnSearch,index)
        next i
        this.error=0
        result=true
      else
        this.error=0
        result=false
      end if
    else
      this.error=ErrDbOpen
      result=false
    end if
  End Function

  Constructor
    Close
  End Constructor
End Type
$ENDIF   ' IncManager: __QDATABASE_INC
