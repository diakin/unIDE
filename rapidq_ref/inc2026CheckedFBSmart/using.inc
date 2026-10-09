'OUTPUT FORMATTING with USING$ FUNCTIONI
DECLARE FUNCTIONI USING$(...) as string
$TYPECHECK ON
$escapechars on


'all the following constants belong to the FUNCTION
'..unfortunately RAPIDQ doesn't allow to define local constants.
const SGNNO%=0:const SGNFRONT%=1:const SGNBACK%=2
'               123456789012 Repeated backslash because of ESCAPECHARS
const symbols$="#.,-+^*$&! \\"
const signs$="- +"
const log10=2.302585

'change these constants to suit your local needs
const thou$="."
const dec$=","
const curr$="$"
const fill$="*"

FUNCTIONI USING$(...)
   'More or less accurate port of the QBasic formatting function USING
   
   'Antoni Gual agual@eic.ictnet.es 3/6/00
   'SYNTAX:    A$=USING$(FORMATTING_STRING, LIST OF STRING AND NUMERIC VALUES)
   
   
   'Some characters in the formatting string indicate the format the rest of parameters must have:
   
   'NUMBER FORMATTING
   '#    digit 
   '.    decimal separator
   ',    (before.) thousands separator
   '+    sign position
   '$$   LEADING currency sign 
   '**   FILL LEADING SPACES WITH *
   '^^^^ 4 ^s after a valid numeric format displays value in exp value (keep place for exponent)
   '     If the format is too small for the number, the number is displayed unformatted, 
   '     preceeded by a % 
   
   'TEXT FORMATTING
   '&    entire string
   '!    only first letter
   '\  \ only (num of spaces+2) chars. Double backslashes if you have ESCAPECHARS ON
   '-    prefixing any format symbol, prints it   
   
   'This function is to use while William works to implement VB's FORMAT$. At his work pace, a day or two! ;)
   'Not bundled to PRINT or LPRINT, it simply returns a string you can use as you want!
   'Formatting string does'nt need to be the first parameter (courtesy of RapidQ double stack of params)
   ' , but must be the first string.
   'After reaching Format string's end, the function will return unformatted numeric values and strings separed by spaces
   '   Note that in this case the strings will go after numbers (also courtesy of RapidQ)
   'Displays local decimal, thousands, and currency  simbols, as stated in constS (It does'nt read from Windows)

   
   'a lot of vars!
   DIM FORMAT$ as string,OUTPUT$ as string ,a$ as string
   dim ipart$ as string, fpart$ as string,epart$ as string,spart$ as string   
   DIM valcount% as integer,strcount% as integer, innum% as integer,THOU% as integer,expo% as integer
   dim DECPOS% as integer,SIGN% as integer,PAD% as integer,currency% as integer
   DIM SKIP% as integer,oom% as integer,decplaces% as integer,totplaces% as integer
   dim i% as integer, xx% as integer,num# as double,b# as double
   dim ptr% as integer,f$ as string,i$ as string,places% as integer
   dim pad$ as string,j% as integer,k% as integer,neg% as integer
   DIM INSTRING% as integer,backslash% as integer
   
   
   output$=""
   valcount%=1:strcount%=1
   'get format string
   if paramstrcount then
      format$=paramstr$(1)
      inc strcount%
      output$=""
      ptr%=1
      gosub reset
     'parsing format string loop
      while ptr%=<len(format$)
         a$=mid$(format$,ptr%,1)
         xx%=instr(symbols$,a$)
         if  xx% and (skip%=0) then
            select case xx%
            case 1 '#
               inc innum%
            case 2 '.
               inc innum%: DECPOS%=innum%
            case 3 ',
               if innum% and (decpos%=0)then :inc innum%:thou%=1: else: gosub buildoutput:end if
            case 4 '-
               if innum% then inc innum%:sign%=sgnback%  else  skip%=1
            case 5 '+   
               inc innum%: sign%=sgnfront%
            case 7 '*
               inc pad%
               if pad%=2 then inc innum%,2
            case 6 '^
               inc expo%
             
            case 8 '$
               inc currency%
               if currency%=2 then inc innum%,2
            case 9 '&
               instring%=-1
            case 10 '!
               inc instring%
            case 12 '\
               inc instring%:inc backslash%
            case 11 'space
               if backslash%=1 then :inc instring%,1 :else :gosub buildoutput :end if
            end select   
         else
            gosub buildoutput
         end if
         inc ptr%
      wend
      a$="":gosub buildoutput
   end if
   'output the remaining numeric values and strings separed by spaces and exit
   'CAUTION!: RapidQ FUNCTIONI doesn't preserve the relative position of strings  and values in 
   'the parameter list!..So I decided strings will go after numbers!
   for i%=valcount% to paramvalcount:output$=output$+" "+ str$(paramval(i%)):next
   for i%=strcount% to paramstrcount:output$=output$+" "+paramstr$(i%):next
   using$=output$
exit functioni

'This GOSUB adds to the output$ string a "dumb" char  directly from format string or a parameter correctly formatted
buildoutput:
   'a formatted string must be included
   '?expo%, A$,innum%,instring%,
   if instring% then
      if strcount%<=paramstrcount then
         'non formatted string
         if instring%=-1 then 
            ipart$=paramstr$(strcount%)
         'fixed length string
         else 
            ipart$=left$(Paramstr$(strcount%)+space$(instring%),instring%)
         end if
         output$=output$+ipart$
         inc strcount%
      end if
   'a numeric value must be SHOWN
   elseif  innum% then
      'if it was an isolated plus sign, print +
      if sign%=innum% then
          output$=output$+"+"
      'if it was an isolated dot, print dot    
      elseif decpos%=1 and innum%=1 then
         output$=output$+"."
      else
         'is there any numeric param?
         if valcount%=<paramvalcount then
            num#=(paramval(valcount%))
            if num# then oom%=round(log(abs(num#))/log10)+1 else  oom%=0
            fpart$="":epart$="":spart$=""
            'sign processing
            if sign%=1 then
               spart$=mid$(signs$,sgn(num#)+2,1)
               dec innum%:dec decpos%:if decpos%<0 then decpos%=0
            else
               if num#<0 then neg%=1  
            end if   
            num#=abs(num#)
            totplaces%=iif(decpos%,decpos%-1,innum%)
            places%=totplaces%-(thou%*((totplaces%-1)\ 3) )-(currency%>0)
            decplaces%=iif (decpos%,innum%-decpos%,0) 
            'exponential format
            if expo%=4 then
               j%=oom%-places%
               if num# then k%=oom%-places% else k%=0
               if j%>0 then dec j%:inc K%
               epart$="E"+MID$(SIGNS$,SGN(k%)+2,1)+right$("00"+ltrim$(str$(ABS(k%))),2)
               num#=num#/(10^j%)
               '?oom%," ",j%," ",num#," ",places%," ",Totplaces%
            end if
            'round the number
            b#=10^decplaces%
            num#=fix(num#*b#+0.5*sgn(num#))/b#
            i$=ltrim$(str$(fix(num#))) 
            '?oom%," ",len(i$)," ", places%," ",totplaces%," ",innum%," ",decpos%," ",decplaces%
            'see if enough place 
            if len(i$)>places% then  
               spart$="":epart$=""
               ipart$="%"+str$(paramval(valcount%))
            else
               'integer part
               pad$=iif(pad%=2,fill$," ")
               'loop to build int part separing figures by thousands separator
               ipart$=string$(totplaces%,pad$)
               j%=iif (decpos%,decpos%-1,innum%):k%=len(i$)
               for  i% =1 to len(i$) 
                  if thou% then if i%>1 and ((i% mod 3) =1) then ipart$= replace$(ipart$,thou$,j%):dec j%
                  ipart$=replace$(ipart$,mid$(i$,k%,1),j%)
                  dec j%:dec k% 
               next
               if currency% then ipart$=replace$(ipart$,curr$,j%):dec j%           
               if sign%=0 and neg%=1 then ipart$=replace$(ipart$,"-",j%)
               'build frac part
               if decplaces% then
                  b#=10^decplaces%  'this rounding is to avoid a bug in RapidQ          
                  num#=fix(frac(abs(num#))*b#+0.5*sgn(num#))/b#
                  F$=mid$(str$(num#),3)
                  fpart$=dec$+left$(f$+string$(decplaces%,"0"),decplaces%)   
               end if
            end if
            '? spart$,"|",ipart$,"|",fpart$,"|",epart$
            output$=output$+spart$+ipart$+fpart$+epart$
            inc valcount%
         end if
      end if
   'started to parse as padding format but numeric format did'nt follow 
   elseif pad%=1 then
      output$=output$+"*"
   'started to parse as currency format but numeric format did'nt follow 
   elseif currency%=1 then
      output$=output$+"$"
   'started to parse as exponential but had not the correct number of ^ or numeric format not there 
   elseif expo% then
      output$=output$+string$(expo%,"^")
   end if
   'as GOSUB was called when a dumb char ended formatting string, output this dumb char. 
   output$=output$+a$  
   '?output$
reset:
   'Reset all conters and return to parsing loop
   a$=""
   backslash%=0:pad%=0
   innum%=0
   DECPOS%=0:THOU%=0:SIGN%=0:PAD%=0:currency%=0:expo%=0
   instring%=0
   skip%=0
return
end functioni

$escapechars on
print using$("! can tell you This is a & Test&","Idiot","silly",", Is'nt?")
PRINT USING$("This -\a is a fake format-!",111,"hello")
dim frm$ as string
frm$= "+##  \\    \\ , FOB,   cost  $$,####.##  each. +#,###.#^^^^ "  
print using$(frm$,2,"apples",0.2,-1) 
print using$(frm$,34,"cars",1010,345678907)
print using$(frm$,0,"cars",0,0)
print using$(frm$,-3,"Computers",-345.6,0.000023)
?"Press any key..":do:loop until len(inkey$)  