$IFNDEF __QDRIVECOMBOBOX_INC   ' inc2026: подключается только первая версия QDriveComboBox (QDriveCombobox.inc или версия в RAPIDQ2.INC)
$DEFINE __QDRIVECOMBOBOX_INC
$DEFINE __QDRIVECOMBOBOX_INC_SA   ' inc2026: подключён отдельный файл QDriveComboBox - совпадающие объявления в RAPIDQ.INC / RAPIDQ2.INC пропустятся
'=======================================================
' Type Objet
' Classe QDriveCombobox
'=======================================================
$IFNDEF __RQINC2
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
       Super.AddItems name ' inc2026: Super.AddItems вместо QDriveComboBox.AddItems: в типе объявлен свой пустой SUB AddItems (строка 31), он скрывает унаследованный метод (глава 10.3: "you won't be able to access the inherited one... you must explicitly call the SUPER class"), и GetDrives ничего не добавлял; так же super.AddTabs в QtabControlEx.inc строка 40
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

$ENDIF      'component added to RapidQ2.inc
$ENDIF  ' inc2026: __QDRIVECOMBOBOX_INC
