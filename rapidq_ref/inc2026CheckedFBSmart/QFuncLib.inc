'===============================================
' Functions library
'===============================================
Const P_I=acos(-1)


'===============================================
' Return the short name of file
'===============================================
Function GetFileName(file as string) as string
 result=RIGHT$(file,Len(file)-RINSTR(file,"\"))
End Function

'===============================================
' Return the path name of file
'===============================================
Function GetPathName(file as string) as string
  result=LEFT$(file,RINSTR(file,"\")-1)
End Function

'===============================================
' Return the extension of file
'===============================================
Function GetFileExt(file as string) as string
  result=RIGHT$(file,Len(file)-RINSTR(file,"."))
End Function

'===============================================
' Return the n word in a string expression
'===============================================
Function Word$(s as string,index as integer) as string
  dim stemp as string
  dim i as integer
  dim flagSpace as integer
  
  stemp=""
  for i=1 to len(s)
    if mid$(s,i,1)<>space$(1) then
      stemp=stemp+mid$(s,i,1)
      flagSpace=0
    else
      if flagSpace=0 then stemp=stemp+space$(1)
      flagSpace=1
    end if
  next i
  stemp=ltrim$(rtrim$(stemp))
  result=Field$(stemp," ",index)
End Function

'==================================================
' Return the number of word in a string
'==================================================
function GetWordCount(s as String) as integer
  dim flagStop as integer
  dim counter as integer

  counter=1
  flagStop=0
  while flagStop=0
    if Word$(s,counter)<>"" then
      counter=counter+1
    else
      flagStop=1
    end if
  wend
  result=counter-1
end function

'====================================================
' Return a string with remove char
'====================================================
function RemoveChar$(s as string,char as string) as string
  dim source as string  

  if s<>"" then
    source=s
    while instr(source,char)<>0
      source=left$(source,instr(source,char)-1)+mid$(source,instr(source,char)+len(char))
    wend
    result=source
  end if
end function

'====================================================
' Return a string without space to start and to end
'====================================================
Function Trim_$(s as string) as string
  Result=LTRIM$(RTRIM$(s))
End Function

'======================================================
' Return ratio
'======================================================
function Ratio(Value1 as double,Value2 as double) as double
  Result=((Value1-Value2)*100)/Value1
end function

'========================================
' Return radian value
'========================================
function GetRadian(degrees as double) as double
  Result=degrees*(Pi/180)
end function

'==========================================
' Return degrees value
'==========================================
function GetDegrees(radian as double) as double
  Result=radian*(180/Pi)
end function

'===================================
' Return distance
'===================================
function Distance(x as double,y as double) as double
  Result=SQR(x^2+y^2)
end function

'===================================
' Return surface
'===================================
function Surface(Width as double,Height as double) as double
  Result=Width*Height
end function

'===================================
' Return blue value of color
'===================================
function GetBlue(Color as long) as long
    Result=int(Color/65536)
end function

'===================================
' Return red value of color
'===================================
function GetRed(Color as long) as long
    dim blue as long
    dim green as long     

    blue=int(Color/65536)
    green=int((Color-(blue*65536))/256)
    Result=int(Color-(blue*65536)-(green*256))
end function

'===================================
' Return green value of color
'===================================
function GetGreen(Color as long) as long
    dim blue as long

    blue=int(Color/65536)
    Result=int((Color-(blue*65536))/256)
end function

'==========================================
' Return Dec from bin
'==========================================
function BinToDec(bin as string)as long
  dim bit as integer
  dim i as integer
  dim value as integer
  
  bin=REVERSE$(bin)
  bit=1
  value=0
  for i=1 to len(bin)
    if mid$(bin,i,1)="1" then value=value+bit
    bit=bit*2
  next i
  result=value
end function

'=============================================
' Return Dec from hex
'=============================================
function HexToDec(hex as string)as long
  dim bit as long
  dim valbit as integer
  dim i as integer
  dim value as integer
  
  hex=REVERSE$(hex)
  bit=1
  value=0
  for i=1 to len(hex)
    if mid$(hex,i,1)="A" then
      value=value+(10*bit)
    elseif mid$(hex,i,1)="B" then
      value=value+(11*bit)
    elseif mid$(hex,i,1)="C" then
      value=value+(12*bit)
    elseif mid$(hex,i,1)="D" then
      value=value+(13*bit)
    elseif mid$(hex,i,1)="E" then
      value=value+(14*bit)
    elseif mid$(hex,i,1)="F" then
      value=value+(15*bit)
    else
      value=value+(val(mid$(hex,i,1))*bit)
    end if
    if (bit*16)<2147483647 then bit=bit*16
  next i
  result=value
end function
