'=======================================================
' Type Objet
' Classe QDriveCombobox
'=======================================================
$IFNDEF __WIN32API				   'windows 32 definitions
   Declare Function GetDriveType Lib "kernel32" Alias "GetDriveTypeA" (nDrive As String) As Long
$ENDIF

TYPE QDriveComboBox EXTENDS QComboBox
  '=========================================
  ' mйthode reception des lecteurs prйsents
  '=========================================
  SUB GetDrives
   dim ASC_A as integer
   dim ASC_Z as integer
   dim i as integer
   dim name as string
   
   ASC_A=65
   ASC_Z=ASC_A+25
   for i=ASC_A to ASC_Z
     if GetDriveType(Chr$(i)&":\")<>1 then
       name=chr$(i)+":\"
       QDriveComboBox.AddItems name
     end if
   next i
   QDriveComboBox.ItemIndex=0
  END SUB
  
  SUB AddItems
  END SUB
  
  SUB DelItems
  END SUB
  
  SUB Clear
  END SUB
  '-- Default values
  CONSTRUCTOR
  END CONSTRUCTOR
END TYPE  
