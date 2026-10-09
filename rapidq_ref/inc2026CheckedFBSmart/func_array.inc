'-- **************************************************************************'
function ARRAverage (Dat!() as single, MinEl  as integer, MaxEl as integer) as single
' calculate average value from function Dat1!()
defint  p
defsng ARMid!=0

FOR p = MinEl TO MaxEl:
	ARMid! = ARMid! + Dat!(p):
NEXT p

average! = ARMid! / (MaxEl-MinEl+1)

result=average!
END function
'-- **************************************************************************'
sub ARRAverageSubtract (Dat!() as single) 
' calculate and subtract average value from function Dat1!()
defint  p, Lmin1, Lmax1
Lmin1 = LBOUND(Dat!):Lmax1 = UBOUND(Dat!) 
defsng ARMid!=0
'print"ARRAverageSubtract Lmax1=";Lmax1
'print"ARRAverageSubtract Lmin1=";Lmin1

FOR p = Lmin1 TO Lmax1:
	ARMid! = ARMid! + Dat!(p):

NEXT p

average! = ARMid! / (Lmax1-LMin1+1)
'print"average!=";average!

FOR p = LMin1 TO Lmax1: 
Dat!(p) = Dat!(p) - average!: 
'print"Dat!(";p;")=";Dat!(p)
NEXT p
'print"end ----------"

END sub

'-- **************************************************************************'
FUNCTION ARRMax (Dat!() as single, MinEl  as integer, MaxEl as integer) as single
'find max element of array
defint  p
defsng ARMax!=Dat!(MinEl)
FOR p = MinEl TO MaxEl:
	IF Dat!(p) > ARMax! THEN ARMax! = Dat!(p):
NEXT p
result = ARMax!
END FUNCTION

'-- **************************************************************************'
FUNCTION ARRMin (Dat!() as single, MinEl  as integer, MaxEl as integer) as single 
'find min element of array
defint p
defsng ARMin!=Dat!(MinEl)
FOR p = MinEl TO MaxEl:
	IF Dat!(p) < ARMin! THEN ARMin! = Dat!(p):
NEXT p
result = ARMin!
END FUNCTION

'-- **************************************************************************'
FUNCTION ARRMaxEx (Dat!() as single, MinEl  as integer, MaxEl as integer,byref pointX!) as single
'print"ARRMaxEx MaxEl=";MaxEl
'print"ARRMaxEx MinEl=";MinEl
'find max abs element of array
defint  p
defsng ARMax!=(Dat!(MinEl))

'print"ARRMaxEx ARMax!=";ARMax!

FOR p = MinEl TO MaxEl-1:
	IF (Dat!(p)) > (ARMax!) THEN ARMax! = (Dat!(p)) :pointX!=p
'print"ARMax!=";ARMax!
'print"Dat!(";p;")=";Dat!(p)
NEXT p

result = ARMax!

END FUNCTION

'-- **************************************************************************'
FUNCTION ARRMinEx (Dat!() as single, MinEl  as integer, MaxEl as integer, byref pointX!) as single 
'find min element of array
defint p
defsng ARMin!=(Dat!(MinEl))
FOR p = MinEl TO MaxEl:
	IF (Dat!(p)) < ARMin! THEN ARMin! = (Dat!(p)): pointX!=p
NEXT p
result = ARMin!

END FUNCTION


'-- **************************************************************************'
FUNCTIONI FindMax (...) AS DOUBLE

DIM Largest AS DOUBLE
DIM I AS BYTE

Largest = ParamVal(1)

FOR I = 1 TO ParamValCount
	IF ParamVal(I) > Largest THEN
		''       print "ParamVal(",I,")=" ,ParamVal(I)
		Largest = ParamVal(I)
	END IF
NEXT

FindMax = Largest         ' or Result = Largest
END FUNCTIONI

'-- **************************************************************************'
sub ArrExtr (Dat!() as single, byref DatMin!, byref DatMax!) '' as single 
'find  maximum and minimum

defint  p
defint MaxEl,MinEl

MinEl=lbound(Dat!)
MaxEl=ubound(Dat!)

defsng ARMax!=Dat!(MinEl)
defsng ARMin!=Dat!(MinEl)

FOR p = MinEl TO MaxEl:
	IF Dat!(p) > ARMax! THEN ARMax! = Dat!(p):
	IF Dat!(p) < ARMin! THEN ARMin! = Dat!(p):
	
NEXT p
DatMax!=ARMax!
'print "DatMax=" ,DatMax!
DatMin!=ARMin!
'print "DatMin=" ,DatMin!

END SUB

'**********************************************************************
sub ArrAbsExtrN (Dat!() as single, byref _AbsDatMax!, N as int) 
defint  p
defint MaxEl,MinEl

MinEl=lbound(Dat!)+N
'print "ArrAbsExtr sub MinEl=" ,MinEl
MaxEl=ubound(Dat!)
'print "ArrAbsExtr sub MaxEl=" ,MaxEl

defsng ARMax!=Dat!(MinEl)
defsng ARMin!=Dat!(MinEl)
_AbsDatMax!=ARMax!
FOR p = MinEl TO MaxEl:
	IF abs(Dat!(p)) >  _AbsDatMax! THEN  _AbsDatMax! = abs(Dat!(p))
NEXT p
'print "sub _AbsDatMax!=" ,_AbsDatMax!

END SUB


'**********************************************************************
sub ArrAbsExtr (Dat!() as single, byref _AbsDatMax!) 
defint  p
defint MaxEl,MinEl

MinEl=lbound(Dat!)
'print "ArrAbsExtr sub MinEl=" ,MinEl
MaxEl=ubound(Dat!)
'print "ArrAbsExtr sub MaxEl=" ,MaxEl

defsng ARMax!=Dat!(MinEl)
defsng ARMin!=Dat!(MinEl)
_AbsDatMax!=ARMax!
FOR p = MinEl TO MaxEl:
	IF abs(Dat!(p)) >  _AbsDatMax! THEN  _AbsDatMax! = abs(Dat!(p))
NEXT p
'print "sub _AbsDatMax!=" ,_AbsDatMax!

END SUB

'**********************************************************************
sub ArrAbsMaxEx (Dat!() as single, MinEl  as integer, MaxEl as integer,byref _AbsDatMax!,byref pointX!) 
defint  p
'defint MaxEl,MinEl

'MinEl=lbound(Dat!)
'print "sub MinEl=" ,MinEl
'MaxEl=ubound(Dat!)
'print "sub MaxEl=" ,MaxEl

defsng ARMax!=Dat!(MinEl)
defsng ARMin!=Dat!(MinEl)
_AbsDatMax!=abs(ARMax!)
FOR p = MinEl TO MaxEl:
	IF abs(Dat!(p)) >  _AbsDatMax! THEN  _AbsDatMax! = abs(Dat!(p)):pointX!=p
NEXT p
'print "sub _AbsDatMax!=" ,_AbsDatMax!

END SUB
'**********************************************************************
sub ArrAbsMinEx (Dat!() as single, MinEl  as integer, MaxEl as integer,byref _AbsDatMin!,byref pointX!) 
defint  p
'defint MaxEl,MinEl

'MinEl=lbound(Dat!)
'print "sub MinEl=" ,MinEl
'MaxEl=ubound(Dat!)
'print "sub MaxEl=" ,MaxEl

defsng ARMax!=Dat!(MinEl)
defsng ARMin!=Dat!(MinEl)
_AbsDatMin!=abs(ARMax!)
FOR p = MinEl TO MaxEl:
	IF abs(Dat!(p)) <  _AbsDatMin! THEN  _AbsDatMin! = abs(Dat!(p)):pointX!=p
NEXT p

END SUB

'-- **********************************************************************
Sub ArrRaznost (Dat1!() as single , Dat2!() as single, Raznost!() as single) '' as single'' MinEl??, MaxEl??)
Lmin1 = LBOUND(Dat1!):Lmax1 = UBOUND(Dat1!) 
'print "Lmax1=" ,Lmax1
'print "Lmin1=" ,Lmin1

Lmin2 = LBOUND(Dat2!) : Lmax2 = UBOUND(Dat2!)
'print "Lmax2=" ,Lmax2
'print "Lmin2=" ,Lmin2

if Lmin2 <> Lmin1 or Lmax1 <> Lmax2 then 
'showMessage ( "ArrRaznost error: Arrays size mismatch"+lf+"Lmin1="+str$(Lmin1)+" Lmax1="+str$(Lmax1)+lf+"Lmin2="+str$(Lmin2)+" Lmax2="+str$(Lmax2) ) 
'exit sub
end if

REDIM Raznost!(Lmin1 to Lmax1) as single

FOR i = Lmin1 TO Lmax1: 
	Raznost!(i) = Dat1!(i) - Dat2!(i): 
	'print "Raznost!(",i, ") =" ,Raznost!(i)
NEXT i

END SUB
'-- **********************************************************************
Sub ArrRaznostR (Dat1!() as single , Dat2!() as single) '' as single'' MinEl??, MaxEl??)
Lmin1 = LBOUND(Dat1!):Lmax1 = UBOUND(Dat1!) 
Lmin2 = LBOUND(Dat2!) : Lmax2 = UBOUND(Dat2!)

if Lmin2 <> Lmin1 or Lmax1 <> Lmax2 then showMessage ( "ArrRaznostR. Arrays size mismatch" ): exit sub
FOR i = Lmin1 TO Lmax1: 
	Dat1!(i) = Dat1!(i) - Dat2!(i): 
	'print "Raznost!(",i, ") =" ,Raznost!(i)
NEXT i

END SUB
'**********************************************************************
Sub ArrSum (Dat1!() as single , Dat2!() as single, SumA!() as single) 
Lmin1 = LBOUND(Dat1!):Lmax1 = UBOUND(Dat1!) 
Lmin2 = LBOUND(Dat2!) : Lmax2 = UBOUND(Dat2!)
if Lmin2 <> Lmin1 or Lmax1 <> Lmax2 then showMessage ( "ArrSum. Arrays size mismatch" ): exit sub



REDIM SumA!(Lmin1 to Lmax1) as single
FOR i = Lmin1 TO Lmax1: SumA!(i) = Dat1!(i) + Dat2!(i): NEXT i
END SUB
'**********************************************************************

'**********************************************************************
Sub ArrSumR (Dat1!() as single , Dat2!() as single) 
Lmin1 = LBOUND(Dat1!):Lmax1 = UBOUND(Dat1!) 
Lmin2 = LBOUND(Dat2!) : Lmax2 = UBOUND(Dat2!)
if Lmin2 <> Lmin1 or Lmax1 <> Lmax2 then showMessage ( "ArrSumR. Arrays size mismatch" ): exit sub

FOR i = Lmin1 TO Lmax1: Dat1!(i) = Dat1!(i) + Dat2!(i): NEXT i
END SUB
'**********************************************************************


'-- **********************************************************************
SUB kTArray (Dat1!() as single, kt! as single, Dat2!() as single)
'multiply array to const and save result in new array
Lmin1 = LBOUND(Dat1!):Lmax1 = UBOUND(Dat1!) 

REDIM Dat2!(Lmin1 to Lmax1) as single
FOR i = Lmin1 to Lmax1: Dat2!(i) = Dat1!(i) * kt!: NEXT i
END SUB

'-- **********************************************************************
SUB kTArrayR (Dat1!() as single, kt! as single)
'multiply array to const
Lmin1 = LBOUND(Dat1!):Lmax1 = UBOUND(Dat1!) 
FOR i = Lmin1 to Lmax1: Dat1!(i) = Dat1!(i) * kt!: NEXT i
END SUB


'-- **********************************************************************
SUB Nakopl (F!() as single, Nakop!() as single, period as Word)
'-----------------------------
'Calculate average on moving window (interval) of function
''F() - function array
'Nakop!() - moving average
'period - number of moving window points - (max 65535) must be odd number!
'-----------------------------
defint Lmin1,Lmax1
Lmin1 = LBOUND(F!): ' for example =0
'print "Lmin1=" ,Lmin1

Lmax1 = UBOUND(F!)  ' for example =56
'print "Lmax1=" ,Lmax1

REDIM Nakop!(0 to period-1) as single'!!! from 0  !!!' 

defsng Summ!
defint ibeg,iend, NumPnt

'0  0  0   1         2         3         4         5  5  5
'012345678901234567890123456789012345678901234567890123456
'|||||||||||||||||||||||||||||||||||||||||||||||||||||||||    -numbers of function points     F!() 
'|||||||                                           |||||||    - moving window  period points
'   ^ibeg=3                                           ^iend=53
'000+++++++++++++++++++++++++++++++++++++++++++++++++++000    - averaged function  Nakop!()
'|||^|||
'calculate average on 7 points  Nakop!(3)= ( f(0)+f(1)+...f(6) )/7 =f(0)/7+f(1)/7+ ...f(6)/7
' |||^|||
'  |||^|||
'   |||^|||
'then first point f(0)/7  deleted, next f(7)/7 point added. Nakop!(4)=Nakop!(3)- f(0)/7 + f(7)/7

NumPnt=Lmax1-Lmin1+1  '57 elements in array (0 to 56)
NumInterval=NumPnt-1  '56 intevals
ibeg = (period-1) / 2 'starting point of moving window on F!()
iend = NumInterval - ibeg  'end point point of moving window on F!()
Summ! = 0:


'calculate average in starting point  
FOR j = Lmin1 TO Lmin1+(period-1):     Summ! = Summ! + F!(j): NEXT j 'cumulative value'
Nakop!(ibeg) = Summ! / period:  'average in starting point
'print
Summ! = 0:
FOR j = Lmin1 TO ibeg-1: Nakop!(j) =Nakop!(ibeg): next '!!! loosed points  in start '   F!(j)


''calculate average in end point  
FOR j = Lmin1+NumPnt - period  TO Lmin1+NumPnt-1: Summ! = Summ! + F!(j): NEXT j
Nakop!(iend) = Summ! / period: 'calculate average

FOR j = iend+1 TO NumPnt: Nakop!(j) =Nakop!(iend): next ' loosed points in finish' F!(j)


FOR i = Lmin1+ibeg + 1 TO Lmin1+iend - 1
	Nakop!(i) = Nakop!(i-1) + (    F!(i+Lmin1+ibeg)  -  F!(Lmin1+i-ibeg-1)   ) / period
	'                              ^  4  3           4  3
	'if i>43000 and i<50000 then
	'print "i+Lmin1+ibeg=",i+Lmin1+ibeg,"           Nakop!(i-1)=" ,Nakop!(i-1)
	'print "------------------------------"
	
	'end if
	
NEXT i

END SUB
'-- **********************************************************************
sub ARRAddConst (Dat!() as single, const! as single) 
defint  p, Lmin1, Lmax1
Lmin1 = LBOUND(Dat!):Lmax1 = UBOUND(Dat!) 

FOR p = Lmin1 TO Lmax1:
	Dat!(p) = const! + Dat!(p):
NEXT p
END SUB

'-- **********************************************************************
SUB ArrReSample (Dat1() AS SINGLE, Dat2() AS SINGLE, npt)
'------------------
'resample data series Dat1() to  Dat2!() with new points number npt, using linear interpolation

Lmin1 = LBOUND(Dat1): Lmax1 = UBOUND(Dat1)
'print "ArrReSample Lmax1=" ,Lmax1
'print "ArrReSample Lmin1=" ,Lmin1
Lmin2 = LBOUND(Dat2): Lmax2 = UBOUND(Dat2)

ipt = Lmax1 - Lmin1+1 '--- 11-0+1=12  число точек в исходном массиве
kti = npt / ipt       '--- 36/12=3  отношение нового числа точек к старому
'print "ArrReSample kti=" ,kti
j1 = 0  'current new point
j1old = 0 'previous new points

Dat2(Lmin2) = Dat1(Lmin1) '--- in first point functions is equal

FOR i = 1 TO ipt-1 '---  11 points  1 ... 11
	deltaD1 = (Dat1(i) - Dat1(i - 1)) / kti  ' increment of a function in the new current interval for linear interpolation
	ostFunc=Dat1(i-1)-deltaD1*drob-Dat2(j1old)
	
	jz = i * kti '--- =3
	j=FIX(jz) '--- absolute new point number'
	drob=jz-j '--- fraction
	j1 = j - j1old '--- new points number in current interval  
	FOR k = 1 TO j1
		Dat2(j1old + k) = deltaD1 * k +Dat2(j1old) +ostFunc
		'print "ArrReSample Dat2(",j1old + k,") =" ,ArrReSample Dat2(j1old + k)
		
	NEXT k
	j1old = j1 + j1old
NEXT i

END SUB

'--**************************************************************************************** 
SUB OgibF (Dat1() AS SINGLE, OgibUp() AS SINGLE, OgibDn() AS SINGLE)
Lmin1 = LBOUND(Dat1): Lmax1 = UBOUND(Dat1)
'print "Lmax1=" ,Lmax1: print "Lmin1=" ,Lmin1
redim OgibUp(Lmax1) AS SINGLE
redim OgibDn(Lmax1) AS SINGLE

OgibUp(Lmin1)=Dat1(Lmin1)
OgibDn(Lmin1)=Dat1(Lmin1)
ku=Lmin1
kd=Lmin1 '0'

' search max and min

FOR i = Lmin1+1 TO Lmax1 - 1
	
	IF (Dat1(i)-Dat1(i-1))>0.08 AND Dat1(i) >= Dat1(i + 1) THEN
		OgibUp(i)=Dat1(i)
		'- intrerpolation'
		kti=( OgibUp(i)-OgibUp(ku) )/(i-ku)
		 for ik=ku+1 to i-1
			OgibUp(ik)=kti*(ik-ku)+OgibUp(ku)
		 next ik
		ku=i
	ELSEif Dat1(i) < Dat1(i - 1) AND Dat1(i) <= Dat1(i + 1) then
		OgibDn(i)=Dat1(i)
		'- intrerpolation'
		kti=( OgibDn(i)-OgibDn(kd) )/(i-kd)
		 for ik=kd+1 to i-1
			OgibDn(ik)=kti*(ik-kd)+OgibDn(kd)
		 next ik
		kd=i
	END IF
	
NEXT i

END SUB

'--**************************************************************************************** 
SUB OgibFNew (Dat1() AS SINGLE, OgibUp() AS SINGLE, OgibDn() AS SINGLE)
Lmin1 = LBOUND(Dat1): Lmax1 = UBOUND(Dat1)
'print "Lmax1=" ,Lmax1: print "Lmin1=" ,Lmin1
redim OgibUp(Lmax1) AS SINGLE
redim OgibDn(Lmax1) AS SINGLE

dim DatMax(512) AS SINGLE
dim DatMin(512) AS SINGLE

OgibUp(Lmin1)=Dat1(Lmin1)
OgibDn(Lmin1)=Dat1(Lmin1)
ku=Lmin1
kd=Lmin1 '0'

' search max and min
mm=0

FOR i = Lmin1+1 TO Lmax1 - 1
	
	IF (Dat1(i)-Dat1(i-1))>0.08 AND Dat1(i) >= Dat1(i + 1) THEN
		mm=mm+1
		DatMax(mm)=Dat1(i)
		OgibUp(i)=Dat1(i)
		'- intrerpolation'
		kti=( OgibUp(i)-OgibUp(ku) )/(i-ku)
		 for ik=ku+1 to i-1
			OgibUp(ik)=kti*(ik-ku)+OgibUp(ku)
		 next ik
		ku=i
	ELSEif Dat1(i) < Dat1(i - 1) AND Dat1(i) <= Dat1(i + 1) then
		OgibDn(i)=Dat1(i)
		'- intrerpolation'
		kti=( OgibDn(i)-OgibDn(kd) )/(i-kd)
		 for ik=kd+1 to i-1
			OgibDn(ik)=kti*(ik-kd)+OgibDn(kd)
		 next ik
		kd=i
	END IF
	
NEXT i

END SUB


'--**************************************************************************************** 
SUB  cutPoints (Dat!() as single, cutPnt as integer)
NumPoint = UBOUND(Dat!)

for i=CutPnt to NumPoint-CutPnt-1
	Dat!(i-CutPnt)=Dat!(i)
	'print "Dat!(",i-CutPnt,")=",Dat!(i-CutPnt)
next i

END SUB


'--**************************************************************************************** 
sub ReversX1(Dat!() as single)
NumPoint = UBOUND(Dat!)
for i=0 to NumPoint-1
	ddi=Dat!(i)
	ddj=Dat!(NumPoint-1-i)
	Dat!(i)=ddi
	Dat!(NumPoint-1-i)=ddj

	'swap Dat!(i),Dat!(NumPoint-1-i)
next i


end sub
'--**************************************************************************************** 
SUB DelIncline (Dat!() as single)
' убирает наклон из функции, т.е начальная и конечная точки равны 0
Npt = UBOUND(Dat!)
kt!=(Dat!(Npt-1)-Dat!(0))/(Npt-1)
DIM Incline!(Npt-1) as single
for i=0 to Npt-1
Dat!(i)=Dat!(i)-kt!*i
next i



end sub

'--**************************************************************************************** 
'Sub ArrConcat(Dat1!() as single,Dat2!() as single, FullDat as single)

'END SUB

''--**************************************************************************************** 
'SUB SynNak (Dat!(), period, Snak!())
'Npt = UBOUND(Dat!)
'REDIM Snak!(period) as single

'FOR k = 1 TO period
	'FOR i = k TO CINT(Npt / period) * period STEP period
		'Snak!(k) = Snak!(k) + Dat!(i)
	'NEXT i
	
'NEXT k

'CALL kTArrayr(Snak!(), 1/CINT(Npt/period))

'END SUB
