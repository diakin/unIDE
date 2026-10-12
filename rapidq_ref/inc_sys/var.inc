' var.inc - отдельный inc, не входит в rapidqAllProc.inc /
' rapidqComponents.inc: переменные одной программы (klas, dopusk$, omega!, SubArcPath$ ...).
' Собран rapidq_ref/tools/build_inc.py из incOld/var.inc; повторы объявлений
' общих файлов - '~dup. Подключать в программе, которой он нужен.
$IFNDEF __SEP_VAR_INC
$DEFINE __SEP_VAR_INC
$INCLUDE "rapidqComponents.inc"
'============================================================================
'[build_inc] var.inc
'============================================================================

DIM klas(4) as integer
DIM dopusk$(4) as string
DIM dopsk!(40)  as single
DIM FZK!(7) as single
DIM SumNak!(1) as single
DIM SredNF!(1) as single 
DIM SredNFr!(1) as single 
DIM fzko!(7) as single 
DIM fzkoR!(7) as single 


const Kpogr as integer = 1296000 'число угл секунд в обороте   '
'defint pnt 
omega!=360 ' r-т для пересчета в градусы
CrdOrigin=30
UglR$="-"
Ugl$="-"
LostP=0

defstr tipOb$ = "\stan" '========================================================'
'DIM klas(4) as integer ' класс точности
'DIM dopusk$(4) as string 'допуск 
defsng DopNakop!,DopCikl! ' допуск на накопленную и на циклическую

defstr DATAP$,vreM$,stanok$, model$,Invent$,FIO$,koleso$, ZSt$ '!!! ------- архивные параметры --------------
defstr opisanie$ ,klas$

dim ZDatIn as integer 'число штрихов входного датчика с учетом к-та фаз'
dim ZDatOut as integer 'число штрихов выходного датчика с учетом к-та фаз '

defint PosOut,PosIn,ZDtOut,ZDtIn
defsng KoordIn,KoordInPriv,KoordOut ,deltaFiq' - в оборотах


DIM Pch!(1, 1) as  single 'передаточное число от вала (1 к 2)
DIM Pch1!(1) as  single 'передаточное число от вала (i к 1)


'!!!-------------------- lpod --------------
dim LPod as single  'ход  перемещение на котором дожна быть определена функция кинематической погрешности'
'-------------------

dim LpodEnd! as single 'реальное перемещение звена, LPod+ запас на фильтрацию и т.п.

dim ZDiskr as integer   'число штрихов датчика дискретизации приведенное (на одном обороте выходного вала ) ZDiskr= min( ZDtIn*Peredat, ZDtOut) 

'!!!------------ число точек для расчета масштаба графика исходя из перемещения 30 град---------------

dim NumPnt as integer   'основное число точек для показа на графике
dim Numbrd as integer       'запас по краям (число добавочных точек) для фильтрации
dim NumPntRs as integer 'число точек  передискретизированное к степени 2 для спектра

'----------------- число точек  для результатов измерений ----------
dim NumPnt1 as integer   'основное число точек для показа на графике
dim Numbrd1 as integer       'запас по краям (число добавочных точек) для фильтрации
dim NumPntRs1 as integer 'число точек  передискретизированное к степени 2 для спектра

dim NumPnt2 as integer   'основное число точек для показа на графике
dim Numbrd2 as integer       'запас по краям (число добавочных точек) для фильтрации
dim NumPntRs2 as integer 'число точек  передискретизированное к степени 2 для спектра

dim NumPnt3 as integer   'основное число точек для показа на графике
dim Numbrd3 as integer       'запас по краям (число добавочных точек) для фильтрации
dim NumPntRs3 as integer 'число точек  передискретизированное к степени 2 для спектра

dim NumPnt4 as integer   'основное число точек для показа на графике
dim Numbrd4 as integer       'запас по краям (число добавочных точек) для фильтрации
dim NumPntRs4 as integer 'число точек  передискретизированное к степени 2 для спектра

'------------------------------------------------------------------------'
dim NumPntF as integer '!!! расширенное число точек    NumBrd+NumPnt+NumBrd

'                        0123 01234567 0123
'                        0123 45678901 2345
'                                    1 1 11

'                        0    NumBrd
'                                    NumPnt+NumBrd-1
'------------------------------------------------------------------------'
DEFBYTE prohod
'DeltaFi=0

dim NumGarm as integer ' число гармоник на графике  '

dim NPnt as integer                  


dim StToc as integer 'степень точности
dim kpnt#  as double

dim InputH as integer '    ;// 16 бит 2 байта  номер входа датчика входного звена
dim InputL as integer'' ;// 16 бит 2 байта  номер входа датчика выходного звена
dim Peredat as single '; // передаточное отношение
dim TipPeredat as single '; // передаточное отношение
dim Nfltr as integer ';//- число точек уcреднения (фильтрации)
dim PuskModeint as integer   '; //- режим пуска (ручной, по метке, по событию)
dim MoveModeint as integer   '; //- режим движения
dim NumCkl as integer ' - число циклов измерения (устаревш.)
dim TipDatIn as integer    ' число фаз датчика входного звена
dim TipDatOut as integer ' число фаз датчика выходного звена
dim Delz as integer ' коэффициент деления '

defstr RazmPogr=" угл.сек "
defstr RazmPod=" град. "

'!!! - -------------результаты  обработки ----------------------------------------'
defsng DMax1!, DMax2! ' максимальное абсолютное значение кин. погрешности прямой ход, обратный ход
defint Period ' число точек усреднения для выделения накопленной погрешности'
defsng Kin1!,Kin2!     ' вел-на кинематической погр.     = CLNG(FRazmah!(fDat1$) * 10) / 10 ' fDat$
defsng Fpr1!,Fpr2!     ' вел-на накоп. погp. Fpr    = CLNG(FRazmah!(FileNakop1$) * 10) / 10  '
defsng CikD1!,CikD2!   ' вел-на цикл. погp. Fpr    = CLNG(FRazmah!(CikDis1$) * 10) / 10
defsng ZazorMax! ' = CLNG(fAbsMax!(Zazor$, 1, -1) * 10) / 10
defsng ZazorMin! ' = CLNG(ARRMin!(Zazor!()) * 10) / 10
defsng ZNech!    ' зона нечувствительности
defsng DeltaFiMax, DeltaFiMin, NakopMax, NakopMin
defsng DRazmah1, DRazmah2, NRazmah1, NRazmah2, CRazmah1, CRazmah2 '- 

defsng Ugol(4) ' величина угла поворота в конце прохода
defsng Ugol1(4) ' величина угла поворота в конце прохода с учетом знака
defsng Nol(4)  ' значение нулевого положения при проходах
defsng Otkl(4) ' наибольшее отклонение кривой кинематической погрешности от нулевой точки при соответствующем проходе

defsng KPH ' величина угла поворота в конце прямого хода  1
defsng KHR ' величина угла поворота в конце реверса прямого хода  2
defsng KOH ' величина угла поворота в конце прямого хода  3
defsng KOR ' величина угла поворота в конце реверса прямого хода  4

defsng Ap ' наибольшее отклонение кривой кинематической погрешности ПХ от точки 0ПХ
defsng Apr ' наибольшее отклонение кривой кинематической погрешности ПХР от точки 0ПХ
defsng Ao ' наибольшее отклонение кривой кинематической погрешности ОХ от точки 0oХ
defsng Aor ' наибольшее отклонение кривой кинематической погрешности ОХР от точки 0oХ

defsng AMax ' максимальная погрешность отработки текущего угла

defsng ZIP ' величина зоны индикации при прямом ходе
defsng oZIO ' ноль  зоны индикации при обратном ходе
defsng ZIO ' величина зоны индикации при обратном ходе

'!!! ------- массивы функций ---------------------------
DIM Arg!(1) as single      ' текущее перемещение выходного звена ПХ

DIM Arg1(1) as single      ' текущее перемещение выходного звена ПХ
DIM Arg2(1) as single      ' текущее перемещение выходного звена реверс ПХ
DIM Arg3(1) as single      ' текущее перемещение выходного звена ОХ
DIM Arg4(1) as single      ' текущее перемещение выходного звена реверс ОХ

DIM ArgIdeal1!(1) as single ' заданное текущее перемещение выходного звена 
DIM ArgIdeal2!(1) as single ' заданное текущее перемещение выходного звена 
DIM ArgIdeal3!(1) as single ' заданное текущее перемещение выходного звена 
DIM ArgIdeal4!(1) as single ' заданное текущее перемещение выходного звена 

' ArgIdeal!(i)=Ni*360/ (peredat*P)
' Ni - число импульсов на данный момент
' peredat - передаточное отношение привода
' P - число импульсов на 1 оборот шагового двигателя

DIM DeltaFi(1)  as single   ' значения функции погрешности ПХ

defint bpnt1,bpnt2,bpnt3,bpnt4 ' начальные точки функций

DIM DeltaFiD(1)  as single   ' значения функции погрешности в функции точек полного перемещения
DIM DeltaFiR(1) as single   ' значения функции погрешности в функции точек полного перемещения

dim DeltaFiDList as QStringList 
dim DeltaFiRList as QStringList 

DIM DeltaFi1(1)  as single   ' значения функции погрешности ПХ
DIM DeltaFi2(1) as single   ' значения функции погрешности реверс ПХ
DIM DeltaFi3(1) as single   ' значения функции погрешности ОХ
DIM DeltaFi4(1) as single   ' значения функции погрешности реверс ОХ

DIM Veloc1(1)  as single   ' значения функции погрешности ПХ
DIM Veloc2(1) as single   ' значения функции погрешности реверс ПХ
DIM Veloc3(1) as single   ' значения функции погрешности ОХ
DIM Veloc4(1) as single   ' значения функции погрешности реверс ОХ


DIM Nakop1(1) as single ' значения функции накопленной погрешности при  прямом ходе
DIM Nakop2(1) as single ' значения функции накопленной погрешности при  обратном ходе
DIM Nakop3(1) as single ' значения функции накопленной погрешности при  обратном ходе
DIM Nakop4(1) as single ' значения функции накопленной погрешности при  обратном ходе

DIM CikDis1(1) as single ' значения функции циклической погрешности при  прямом ходе
DIM CikDis2(1) as single ' значения функции циклической погрешности при  обратном ходе
DIM CikDis3(1) as single ' значения функции циклической погрешности при  обратном ходе
DIM CikDis4(1) as single ' значения функции циклической погрешности при  обратном ходе

DIM Ogib1u(1) as single ' значения функции огибающей циклической погрешности при  прямом ходе
DIM Ogib1d(1) as single ' значения функции огибающей циклической погрешности при  обратном ходе

DIM Ogib2u(1) as single ' значения функции огибающей циклической погрешности при  прямом ходе
DIM Ogib2d(1) as single ' значения функции огибающей циклической погрешности при  обратном ходе

DIM Ogib3u(1) as single ' значения функции огибающей циклической погрешности при  прямом ходе
DIM Ogib3d(1) as single ' значения функции огибающей циклической погрешности при  обратном ходе

DIM Ogib4u(1) as single ' значения функции огибающей циклической погрешности при  прямом ходе
DIM Ogib4d(1) as single ' значения функции огибающей циклической погрешности при  обратном ходе

DIM DeltaFiRS(1) as single ' значения функции погрешности  передискретизированые
DIM DeltaFiRS2(1) as single ' значения функции погрешности  передискретизированые при  обратном ходе
DIM DeltaFiRS3(1) as single ' значения функции погрешности  передискретизированые при  обратном ходе
DIM DeltaFiRS4(1) as single ' значения функции погрешности  передискретизированые при  обратном ходе

DIM DeltaFiDbl(1) as single ' удвоенная по длине функция (проходы 2-3) для вычисления спектра
'DeltaFiDbl
DIM Nakop1RS(1) as single ' значения функции накопленной погрешности  передискретизированые при  прямом ходе
DIM Nakop2RS(1) as single ' значения функции накопленной погрешности  передискретизированые при  обратном ходе
DIM Nakop3RS(1) as single ' значения функции накопленной погрешности  передискретизированые при  обратном ходе
DIM Nakop4RS(1) as single ' значения функции накопленной погрешности  передискретизированые при  обратном ходе

DIM CikDis1RS(1) as single ' значения функции циклической погрешности  передискретизированые при  прямом ходе
DIM CikDis2RS(1) as single ' значения функции циклической погрешности  передискретизированые при  обратном ходе
DIM CikDis3RS(1) as single ' значения функции циклической погрешности  передискретизированые при  обратном ходе
DIM CikDis4RS(1) as single ' значения функции циклической погрешности  передискретизированые при  обратном ходе

DIM Ogib1uRS(1) as single ' значения функции огибающей циклической  передискретизированые погрешности при  прямом ходе
DIM Ogib1dRS(1) as single ' значения функции огибающей циклической  передискретизированые погрешности при  обратном ходе

DIM Ogib2uRS(1) as single ' значения функции огибающей циклической  передискретизированые погрешности при  прямом ходе
DIM Ogib2dRS(1) as single ' значения функции огибающей циклической  передискретизированые погрешности при  обратном ходе

DIM Ogib3uRS(1) as single ' значения функции огибающей циклической  передискретизированые погрешности при  прямом ходе
DIM Ogib3dRS(1) as single ' значения функции огибающей циклической  передискретизированые погрешности при  обратном ходе

DIM Ogib4uRS(1) as single ' значения функции огибающей циклической  передискретизированые погрешности при  прямом ходе
DIM Ogib4dRS(1) as single ' значения функции огибающей циклической  передискретизированые погрешности при  обратном ходе

dim Spectr (1) as single   ' спектр


'defsng Kin1! '= CLNG(FRazmah!(fDat1$) * 10) / 10 ' fDat$
'defsng Fpr1! '= CLNG(FRazmah!(FileNakop1$) * 10) / 10  'вел-на накоп. погp. Fpr
'defsng CikD1! '= CLNG(FRazmah!(CikDis1$) * 10) / 10

'defsng Kin2! '= CLNG(FRazmah!(fDat2$) * 10) / 10 ' fDat$
'defsng Fpr2! '= CLNG(FRazmah!(FileNakop2$) * 10) / 10  'вел-на накоп. погp. Fpr
'defsng CikD2! '= CLNG(FRazmah!(CikDis2$) * 10) / 10

'defsng ZazorMax! '= CLNG(fAbsMax!(Zazor$, 1, -1) * 10) / 10

'CikD1! = rondo!((fSred!(Ogib1u$) - fSred!(Ogib1d$)), 1)

' мгновенной  местной кин погр
'REDIM LocCikDisRew!(NumPntF), LocCikDis!(NumPntF)

'FOR i = 1 TO NumPntF - 1
'LocCikDis!(i) = InterMax!(i) - InterMin!(i)
'LocCikDisRew!(i) = InterMaxRew!(i) - InterMinRew!(i)
'Locl! = Locl! + LocCikDis!(i)' накопление для суммы
'LocRew! = LocRew! + LocCikDisRew!(i)
'          StepX = Xstep# * i
'NEXT i

' средней  местной кинематической погрешности
'LocCik! = Locl! / NumPnt: LocCikRew! = LocRew! / NumPnt

'!!! - ------------ графики -----------------------------------------
defstr NameGraf$ ' 
defsng DatGraf!(1) ' массив с текущим графиком

'!!!- ------------ обработка -----------------------------------------
DIM gamp!(1) as single
defsng gampp!

'!!!- ------------ архивы -----------------------------------------
'.rzm - файлы с расширенным числом точек для последующей фильтрации
'.rdt - файлы с  точек соответствующим Lpod! для вывода графика
'.pzm - исходный файл посл. доступа формата "номер точки, значение ф-ции"

defstr  ArcNum '- номер текущего архива
defstr  ProvNum$ '- номер текущей проверки (которых 12 штук)

defstr  ArcPath$ '- путь текущего  архива

'defstr  ArcP1$ '-   синоним- путь текущего  архива

defstr NSObr$ '- направление вращения стола'


dim SubArcPath$(12) as string
SubArcPath$(1)="\Z_NU_M"
SubArcPath$(2)="\Z_NU_R"
SubArcPath$(3)="\Z_+45_M" 
SubArcPath$(4)="\Z_+45_r"
SubArcPath$(5)="\Z_-45_M"
SubArcPath$(6)="\Z_-45_r"

SubArcPath$(7)="\Y_NU_M"
SubArcPath$(8)="\Y_NU_R"
SubArcPath$(9)="\Y_+45_M"
SubArcPath$(10)="\Y_+45_r"
SubArcPath$(11)="\Y_-45_M"
SubArcPath$(12)="\Y_-45_r"


'!!!---файлы -  ----

defstr fIzm1$= "DELTAFI1.pzm" '- исходные результаты измерений, прямой ход (текстовый файл  формата pnt,dat!)
defstr fIzm2$="DELTAFI2.pzm" '- исходные результаты измерений, реверс прямого хода  (текстовый файл  формата pnt,dat!)
defstr fIzm3$="DELTAFI3.pzm" '- исходные результаты измерений, обратный ход (текстовый файл  формата pnt,dat!)
defstr fIzm4$="DELTAFI4.pzm" '- исходные результаты измерений, реверс обратного хода (текстовый файл  формата pnt,dat!)

'-- если есть несколько отсчетов на точку - усредняем их.
defstr fIzn1$= "DELTAFI1.pzn" '- исходные результаты измерений, прямой ход (текстовый файл  формата pnt,dat!)
defstr fIzn2$="DELTAFI2.pzn" '- исходные результаты измерений, реверс прямого хода  (текстовый файл  формата pnt,dat!)
defstr fIzn3$="DELTAFI3.pzn" '- исходные результаты измерений, обратный ход (текстовый файл  формата pnt,dat!)
defstr fIzn4$="DELTAFI4.pzn" '- исходные результаты измерений, реверс обратного хода (текстовый файл  формата pnt,dat!)

defstr fPrIzm1$="DELTAFI1.izm" '- результаты измерений с восстановлением числа точек при прямом ходе (бинарный файл dat!)
defstr fPrIzm2$="DELTAFI2.izm" '- результаты измерений с восстановлением числа точек при обратном ходе (бинарный файл dat!)
defstr fPrIzm3$="DELTAFI3.izm" '- результаты измерений с восстановлением числа точек при прямом ходе (бинарный файл dat!)
defstr fPrIzm4$="DELTAFI4.izm" ' - результаты измерений с восстановлением числа точек при обратном ходе (бинарный файл dat!)

defstr fNzm1$="DELTAFI1.nzm"' - нормализованный файл измерений для показа  при прямом ходе (без запаса на фильтрацию dat!)
defstr fNzm2$="DELTAFI2.nzm"' - нормализованный файл измерений для показа  при обратном ходе (без запаса на фильтрацию dat!)
defstr fNzm3$="DELTAFI3.nzm"' - нормализованный файл измерений для показа  при прямом ходе (без запаса на фильтрацию dat!)
defstr fNzm4$="DELTAFI4.nzm"' - нормализованный файл измерений для показа  при обратном ходе (без запаса на фильтрацию dat!)
'--- 

'!!!--- накопленная погрешность ----
defstr fNak1$  = "nakop1.pzm"
defstr fNak2$  = "nakop2.pzm"
defstr fNak3$  = "nakop1.pzm"
defstr fNak4$  ="nakop2.pzm"

'--- циклическая погрешность ----
defstr fCik1$ ="CikDis1.pzm": 
defstr fCik2$ ="CikDis2.pzm":
defstr fCik3$ ="CikDis1.pzm": 
defstr fCik4$ ="CikDis2.pzm":

'--- огибающая  циклической погрешности ----
defstr fOgib1u$ ="Ogib1u.pzm": '- верхняя
defstr fOgib1d$ ="Ogib1d.pzm":  '- нижняя

defstr fOgib2u$ = "Ogib2u.pzm": 
defstr fOgib2d$ = "Ogib2d.pzm":

defstr fOgib3u$ = "Ogib2u.pzm": 
defstr fOgib3d$ = "Ogib2d.pzm":

defstr fOgib4u$ = "Ogib2u.pzm": 
defstr fOgib4d$ ="Ogib2d.pzm":
'--- 

defstr fZazor$ ="zazor.pzm"               

defstr Fdiagnoz$ ="diagnoz"
defstr FSpectr$ = "spectr.fft" 'скопировать из рабочей директории в архив'

defstr UgolDat$="Ugol.Dat" ' файл с величинами угловых перемещений в заданных точках                        

$ENDIF ' __SEP_VAR_INC
