$define #define $define

#define fbUseSystem           0

#define fbFirstJan1           1
#define fbFirstFourDays       2
#define fbFirstFullWeek       3

#define fbSunday              1
#define fbMonday              2
#define fbTuesday             3
#define fbWednesday           4
#define fbThursday            5
#define fbFriday              6
#define fbSaturday            7


'--- Declarations ---
'*****************************************
function ReadVarFromMemory2 (adrr as long, vart as long ) as  variant 'double 
' read N bytes from address "adrr" ad return
' vart is vartype from rapidQ.inc
'CONST Num_BYTE   = 1            '-- ie. PRINT File.ReadNum(Num_SINGLE)
'CONST Num_SHORT  = 2
'CONST Num_WORD   = 3
'CONST Num_LONG   = 4
'CONST Num_DWORD  = 5
'CONST Num_SINGLE = 6
'CONST Num_DOUBLE = 8

DIM Mem AS QMemoryStream
dim resltbyte as byte ' 1 byte
dim resltshort as short ' 2 byte
dim resltword as word ' 2 byte
dim resltlong as long ' 4 byte
dim resltdword as dword ' 4 byte
dim resltsingle as single ' 4 byte
dim resltdouble as double ' 8 byte


Select case vart
case Num_BYTE
	'Mem.Position = 0
	'Mem.MemCopyFrom (adrr, 1)
	'Mem.Position = 0
	'Mem.Read (resltbyte)
	ReadVarFromMemory=-1 ' resltbyte
	Mem.Close
	
case Num_SHORT
	Mem.Position = 0
	Mem.MemCopyFrom (adrr, 2)
	Mem.Position = 0
	Mem.Read (resltshort)
	ReadVarFromMemory=resltshort
	Mem.Close
	
case Num_WORD
	Mem.Position = 0
	Mem.MemCopyFrom (adrr, 2)
	Mem.Position = 0
	Mem.Read (resltword)
	ReadVarFromMemory=resltword
	Mem.Close
	
case Num_LONG
	Mem.Position = 0
	Mem.MemCopyFrom (adrr, 4)
	Mem.Position = 0
	Mem.Read (resltlong)
	ReadVarFromMemory=resltlong
	Mem.Close
	
case Num_DWORD
	Mem.Position = 0
	Mem.MemCopyFrom (adrr, 4)
	Mem.Position = 0
	Mem.Read (resltdword)
	ReadVarFromMemory=resltdword
	Mem.Close
	
case Num_SINGLE
	Mem.Position = 0
	Mem.MemCopyFrom (adrr, 4)
	Mem.Position = 0
	Mem.Read (resltsingle)
	ReadVarFromMemory=resltsingle
	Mem.Close
	
	
case Num_DOUBLE
	Mem.Position = 0
	Mem.MemCopyFrom (adrr, 8)
	Mem.Position = 0
	Mem.Read (resltDOUBLE)
	ReadVarFromMemory=resltDOUBLE
	Mem.Close
	
case else
end select

end function


'*****************************************
declare function DateSerial Lib "fbDate.dll" Alias "FBDATESERIAL@12" _
( year1 as integer,  month1 as integer,  day1 as integer) as integer 

'A date serial is a number that holds a date and time value in the same format used by PDS or VBDOS. 
'The value is a count of the days from 0:00 AM of December 30,1899; it's mainly used for easy counting 
'of the time between two dates


'*****************************************
declare function fbTimeSerial1 Lib "fbDate.dll" Alias "FBTIMESERIAL@12" _
(  hour1 as integer,  minute1 as integer,  second1 as integer) as  long 'double 
'Gets the date serial representation of a time.

function TimeSerial (hour1 as integer, minute1 as integer, second1 as integer) as  long ' double 
' this function lets to return double type value from  the dll function
'CONST Num_BYTE   = 1            
'CONST Num_SHORT  = 2
'CONST Num_WORD   = 3
'CONST Num_LONG   = 4
'CONST Num_DWORD  = 5
'CONST Num_SINGLE = 6
'CONST Num_DOUBLE = 8

dim sertimeptr as long
sertimeptr=fbTimeSerial1(hour1, minute1, second1)
sertime=ReadVarFromMemory (sertimeptr, Num_DOUBLE ) 
TimeSerial=sertime
end function


'*****************************************
declare function DateValue  Lib "fbDate.dll" Alias "FBDATEVALUE@4" _
 (  s as string ) as integer  
'Gets the date serial representation of a date expressed as a String.

'*****************************************
declare function fbTimeValue1 Lib "fbDate.dll" Alias "FBTIMEVALUE@4" _
( s as string ) as long 'double  
'Gets the date serial representation of a time expressed as a String.

function TimeValue (s as string) as double 
dim sertimeptr as long

sertimeptr=fbTimeValue1 (s)
sertime=ReadVarFromMemory (sertimeptr, Num_DOUBLE ) 
TimeValue=sertime
end function


'*****************************************
declare function IsDate Lib "fbDate.dll" Alias "FBISDATE@4" _
( s as string ) as integer  
'Tests if a String can be converted to a date serial.

'*****************************************
declare function Year Lib "fbDate.dll" Alias "FBYEAR@8" _
(serial as double ) as integer  
'Gets the year from a date serial

'*****************************************
declare function Month Lib "fbDate.dll" Alias "FBMONTH@8" _
(serial as double ) as integer  
'Gets the month of the year from a date serial

'*****************************************
declare function Day Lib "fbDate.dll" Alias "FBDAY@8" _
 (  serial as double ) as integer  
'Gets the day  from a date serial

'*****************************************
declare function Weekday Lib "fbDate.dll" Alias "FBWEEKDAY@12" _
(  serial as double,  FirstDayOfWeek as integer ) as integer 
'Gets the weekday name of its integer representation.

'*****************************************
declare function Hour  Lib "fbDate.dll" Alias "FBHOUR@8" _
( serial as double ) as integer  
'Gets the hour of the day from a date serial.

'*****************************************
declare function Minute Lib "fbDate.dll" Alias "FBMINUTE@8" _
(  serial as double ) as integer  
'Gets the minutes of the hour from a date serial

'*****************************************
declare function Second Lib "fbDate.dll" Alias "FBSECOND@8" _
(  serial as double ) as integer  
'Gets the seconds of the hour from a date serial.

'*****************************************
declare function fbNow1  Lib "fbDate.dll" Alias "FBNOW@0" ( ) as long ' double  
'Gets a date serial of the current date and time

function Now () as double
dim sertimeptr as long
sertimeptr=fbNow1()
sertime=ReadVarFromMemory (sertimeptr, Num_DOUBLE ) 
Now=sertime

end function

'*****************************************
declare function fbDateAdd1 Lib "fbDate.dll" Alias "FBDATEADD@12" _
(interval as string,  byref number as double,  byref serial as double ) as long 'double 
'Gets the result of a time interval added to a date serial.
number1#=number
serial1#=serial
function DateAdd (interval as string,  number as double,  serial as double ) as double
dim sertimeptr as long
sertimeptr=fbDateAdd1(interval,  number1#,  serial1# )
sertime=ReadVarFromMemory (sertimeptr, Num_DOUBLE ) 
DateAdd=sertime

end function


'*****************************************
declare function DatePart  Lib "fbDate.dll" Alias "FBDATEPART@16" _
          (  interval as string, _
             byref serial as double, _ ' rq pass double correctly byref only!
             FirstDayOfWeek as integer , _
             FirstDayOfYear as integer  ) as integer  
'Gets a time interval from a date serial.
'interval string indicating which part of the date is required is specified as follows:
'yyyy years 
'q quarter(three months) 
'm months 
'w weekday 
'ww week of the year 
'y day of the year 
'd day of the month 
'h hours 
'n minutes 
's seconds 



'*****************************************
declare function DateDiff   Lib "fbDate.dll" Alias "FBDATEDIFF@20" _
          (  interval as string, _
             byref serial1 as double, _
             byref serial2 as double, _
             FirstDayOfWeek as integer , _
             FirstDayOfYear as integer  ) as integer  

'Gets a time interval between two date serials

'*****************************************
declare function fbMonthName1 Lib "fbDate.dll" Alias "FBMONTHNAME@8" _
(month1 as integer,  abbreviate as integer  ) as long 'string  
'Gets the month name of its integer representation.
'the number of the month of the year - 1:January through 12:December
'flag to indicate that name should be abbreviated - true, false


function MonthName (month1 as integer,  abbreviate as integer ) as string
dim sertimeptr as long
sertimeptr=fbMonthName1(month1,  abbreviate)
'print"167 fbMonthName func sertimeptr=";sertimeptr
MonthName=varptr$(sertimeptr) ' ReadVarFromMemory (sertimeptr, Num_DOUBLE ) 
end function


'*****************************************
declare function fbWeekdayName1   Lib "fbDate.dll" Alias "FBWEEKDAYNAME@12" _
          (  weekday1 as integer, _ 'the number of the day of the week
             abbreviate as integer,  _
             FirstDayOfWeek1 as integer ) as long 'string  
'Gets the name of a week day from its integral representation

function WeekdayName  (  weekday1 as integer, _ 
             abbreviate as integer,  _
             FirstDayOfWeek1 as integer ) as string  
dim sertimeptr as long
sertimeptr=fbWeekdayName1(weekday1,  abbreviate,  FirstDayOfWeek1 )
WeekdayName=varptr$(sertimeptr) ' ReadVarFromMemory (sertimeptr, Num_DOUBLE ) 

end function


'----- end code --------------

