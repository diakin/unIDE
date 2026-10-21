'!!!---language -----
dim LangList as QStringList
dim LangIni as QINI
dim LangVar$ (128) as string

LangIni.FileName=StartPath$+"lang\lang.ini" '"C:\BAS\RAPIDQ\RQSR_SRC\CurVer\lang\lang.ini" '

LangIniFileName$=LangIni.FileName
'print"LangIniFileName$=";LangIniFileName$

LangIni.Section="Language" 

LangFileName$=Langini.get("default","english")+".lng"
'print"LangFileName$=";LangFileName$
'!!! --- считываем данные из файла языка ---

LangIni.FileName="lang\"+LangFileName$
LangIni.Section="Language" '!!! -------------

'English$=Langini.get("English","English")
'Russian$=Langini.get("Russian","Russian")
