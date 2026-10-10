'----------------------------------------------------------------------
'       APIDATE.INC   by Pasquale Battistelli   04 2001
'----------------------------------------------------------------------
' usage : LASTDAYM([date_string]) 
'          date_string is string that allows this only format: "MM-DD-YYYY"
'          This function returns a string with the last day of month
'
'         WEEKDAY([date_string]) 
'          This function returns a integer number from 1 to 7 that means from 
'          Monday to Sunday

TYPE SYSTEMTIME
    wYear As word
    wMonth As word
    wDayOfWeek As word
    wDay As word
    wHour As word
    wMinute As word
    wSecond As word
    wMilliseconds As word
END TYPE   
Declare function GetDateFormat Lib "kernel32" Alias "GetDateFormatA" _
(ByVal Locale As Long,_
 ByVal dwFlags As Long,_
  lpDate As SYSTEMTIME,_
   ByVal lpFormat As String,_
    ByVal lpDateStr As long,_
     ByVal cchDate As Long) As Long
Declare Function GetLocaleInfo Lib "kernel32" Alias "GetLocaleInfoA" _
(ByVal Locale As Long, _
 ByVal LCType As Long, _
  ByVal lpLCData As long, _
   ByVal cchData As Long) As Long
Declare function lastdayM(datum$ as string)as string
declare function weekday(datum$ as string)as integer
Function lastdayM(datum$ as string)
    Dim pBuffer As String , last As SYSTEMTIME
    last.wYear=val(field$(datum$,"-",3))
    last.wmonth=val(field$(datum$,"-",1))
    last.wDay = 28
    pbuffer="Init"
    while len(pBuffer)<>0
        pBuffer = String$(255, 0)
        GetDateFormat( ByVal 0&, 0, last, "ddd", Varptr(pBuffer), Len(pBuffer))
        pBuffer = Left$(pBuffer, InStr(1, pBuffer, Chr$(0)) - 1)
        last.wDay=last.wDay+1 
    wend
    lastdaym=str$(last.wmonth)+"-"+str$(last.wDay-2)+"-"+str$(last.wyear)
End function
Function weekday(datum$ as string)as integer
    dim wdm(1 to 7) as string*3,b as string
    for i=49 to 55 'giorni short
        b=string$(3,0)  
        r=getlocaleinfo(ByVal 0&, i  ,varptr(b),len(b))
        wdm(i-48)=b
    next
    Dim pBuffer As String , last As SYSTEMTIME
    last.wYear=val(field$(datum$,"-",3))
    last.wmonth=val(field$(datum$,"-",1))
    last.wDay = val(field$(datum$,"-",2))
    pbuffer="Init"
    pBuffer = String$(255, 0)
    GetDateFormat( ByVal 0&, 0, last, "ddd", Varptr(pBuffer), Len(pBuffer))
    pBuffer = Left$(pBuffer, InStr(1, pBuffer, Chr$(0)) - 1)
    for i=1 to 7
        if wdm(i)=pbuffer then exit for
    next
    weekday=i
end function

'print lastdaym("02-01-2500") 
'print weekday("4-6-1753") 'date$)
'while inkey$="":wend
