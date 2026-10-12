' var2008.inc - отдельный inc, не входит в rapidqAllProc.inc /
' rapidqComponents.inc: переменные одной программы (Kpogr, DDelKol!, tipOb$ ...).
' Собран rapidq_ref/tools/build_inc.py из incOld/var2008.inc; повторы объявлений
' общих файлов - '~dup. Подключать в программе, которой он нужен.
$IFNDEF __SEP_VAR2008_INC
$DEFINE __SEP_VAR2008_INC
$INCLUDE "rapidqComponents.inc"
'============================================================================
'[build_inc] var2008.inc
'============================================================================
' C:\BAS\RAPIDQ\INC\var2008.inc
' ShowWindow() Commands
'~dup Const SW_HIDE=0   ' повтор, первое: Form.inc(6)
'~dup Const SW_SHOWNORMAL=1   ' повтор, первое: Form.inc(7)
'~dup Const SW_NORMAL=1   ' повтор, первое: Form.inc(8)
'~dup Const SW_SHOWMINIMIZED=2   ' повтор, первое: Form.inc(9)
'~dup Const SW_SHOWMAXIMIZED=3   ' повтор, первое: Form.inc(10)
'~dup Const SW_MAXIMIZE=3   ' повтор, первое: Form.inc(11)
'~dup Const SW_SHOWNOACTIVATE=4   ' повтор, первое: Form.inc(12)
'~dup Const SW_SHOW=5   ' повтор, первое: Form.inc(13)
'~dup Const SW_MINIMIZE=6   ' повтор, первое: Form.inc(14)
'~dup Const SW_SHOWMINNOACTIVE=7   ' повтор, первое: Form.inc(15)
'~dup Const SW_SHOWNA=8   ' повтор, первое: Form.inc(16)
'~dup Const SW_RESTORE=9   ' повтор, первое: Form.inc(17)
'~dup Const SW_SHOWDEFAULT=10   ' повтор, первое: Form.inc(18)
'~dup Const SW_MAX=10   ' повтор, первое: Form.inc(19)

const Kpogr as integer = 1296000 'число угл секунд в обороте   '
'defint pnt 

defsng DDelKol!
defsng ZubStep

defstr tipOb$ = "\stan" 

'!!! --- допуски ----
DIM klas(4) as integer
DIM dopusk$(4) as string
DIM dopsk!(40)  as single
defsng Asum!,A123!,A456!
defsng DopKin!,DopNakop!,DopCikl!,DopZub!
'---------------------

defstr DATAP$,vreM$,stanok$, model$,Invent$,FIO$,koleso$, ZSt$ '------- архивные параметры --------------
defstr opisanie$ ,klas$

dim ZDatIn as double 'as integer 'число штрихов входного датчика с учетом к-та фаз'
dim ZDatOut as double 'single 'integer 'число штрихов выходного датчика с учетом к-та фаз '

dim LPod as single  'ход  перемещение на котором дожна быть определена функция кинематической погрешности'
dim LpodEnd! as single 'реальное перемещение звена, LPod+ запас на фильтрацию и т.п.
dim ZDiskr as integer ' число штрихов датчика дискретизации на одном обороте выходного вала ZDiskr= min( ZDtIn*Peredat, ZDtOut) 
' после расчета числа точек в нем хранится число отсчетов

dim ZDiskrVozm as integer ' максимально возможное число отсчетов исходя из числа штрихов датчика и передаточного отношения

dim NumPnt as integer    'основное число точек для измерения
dim Numbrd as integer   'запас по краям (число добавочных точек) для фильтрации
dim NumPntRs as integer  'число точек  передискретизированное к степени 2 для спектра

Dim FrMax as single ' максимальная частота вращения звена в кинематической схеме для фильтрации ВЧ шума
Dim frmin as single ' максимальная частота вращения звена в кинематической схеме для выделения накопленной

'------------------------------------------------------------------------'
dim NumPntF as integer ' расширенное число точек    NumBrd+NumPnt+NumBrd

'                        0123 01234567 0123
'                        0123 45678901 2345
'                                    1 1 11

'                        0    NumBrd
'                                    NumPnt+NumBrd-1
'
'
'
dim NumPntGraf as integer ' число точек на графике для просмотра функции - на весь ход.
NumPntGraf=2048
dim NPnt as integer                  
dim NPr as integer   ' Np=5*imax - 5 точек на макс оборотную в кинематике.
'------------------------------------------------------------------------'

dim NumGarm as integer ' число гармоник на графике  '


dim StToc as integer 'степень точности

dim kpnt#  as double

dim InputH as integer '      ;// 16 бит 2 байта  номер входа датчика входного звена
dim InputL as integer''    ;// 16 бит 2 байта  номер входа датчика выходного звена

dim Peredat as single  ';  // передаточное отношение
dim TipPeredat as single  ';  // передаточное отношение

dim Nfltr as integer   '; //  - число точек уcреднения (фильтрации)

dim PuskModeint as integer   '; //- режим пуска (ручной, по метке, по событию)
dim MoveModeint as integer   '; //- режим движения
dim NumCkl as integer ' - число циклов измерения (устаревш.)


dim TipDatIn as integer    ' число фаз датчика входного звена
dim TipDatOut as integer ' число фаз датчика выходного звена
dim Delz as integer ' коэффициент деления '

defstr RazmPogr=" угл.сек "
defstr RazmPogrMkm="мкМ "
defstr RazmPod=" об. "

'- ------------- обработка ----------------------------------------'
defsng DMax1!, DMax2! ' максимальное абсолютное значение кин. погрешности прямой ход, обратный ход

defint Period ' число точек усреднения для выделения накопленной погрешности'
defsng Kin1!,Kin2!     ' вел-на кинематической погр.     = CLNG(FRazmah!(fDat1$) * 10) / 10 ' fDat$
defsng Fpr1!,Fpr2!     ' вел-на накоп. погp. Fpr    = CLNG(FRazmah!(FileNakop1$) * 10) / 10  '
defsng Fpr1Nakop!,Fpr2Nakop!     ' вел-на накоп. погp. Fpr    = CLNG(FRazmah!(FileNakop1$) * 10) / 10  '
defsng CikD1!,CikD2!   ' вел-на цикл. погp. Fpr    = CLNG(FRazmah!(CikDis1$) * 10) / 10
defsng ZazorMax! ' = CLNG(fAbsMax!(Zazor$, 1, -1) * 10) / 10
defsng ZazorMin! ' = CLNG(ARRMin!(Zazor!()) * 10) / 10
defsng ZNech!    ' зона нечувствительности

defsng Fzz!, FzzR!

defsng DeltaFiMax, DeltaFiMin, NakopMax, NakopMin
defsng DeltaFi2Max, DeltaFi2Min, Nakop2MaxR, Nakop2MinR

defsng DRazmah1, DRazmah2, NRazmah1, NRazmah2, CRazmah1, CRazmah2 '- 

DIM Nakop1(1) as single ' значения функции накопленной погрешности при  прямом ходе
DIM Nakop2(1) as single ' значения функции накопленной погрешности при  обратном ходе

DIM CikDis1(1) as single ' значения функции циклической погрешности при  прямом ходе
DIM CikDis2(1) as single ' значения функции циклической погрешности при  обратном ходе

dim Zazor!(1) as single ' 
dim Zaznak!(1) as single ' 

DIM FZK!(7) as single
DIM SumNak!(1) as single
DIM SredNF!(1) as single 
DIM SredNFr!(1) as single 
DIM fzko!(7) as single 
DIM fzkoR!(7) as single 



DIM Ogib1u(1) as single ' значения функции огибающей циклической погрешности при  прямом ходе
DIM Ogib1d(1) as single ' значения функции огибающей циклической погрешности при  обратном ходе

DIM Ogib2u(1) as single ' значения функции огибающей циклической погрешности при  прямом ходе
DIM Ogib2d(1) as single ' значения функции огибающей циклической погрешности при  обратном ходе


DIM Arg!(1) as single      ' значения аргумента
DIM Arg2!(1) as single      ' значения аргумента

'DIM DeltaFi(1) as single   ' значения функции погрешности

DIM DeltaFi1(1) as single   ' значения функции погрешности
DIM DeltaFi2(1) as single   ' значения функции погрешности при обратном ходе


DIM DeltaFiRS(1) as single ' значения функции погрешности  передискретизированые
DIM DeltaFiRS2(1) as single ' значения функции погрешности  передискретизированые при  обратном ходе

DIM Nakop1RS(1) as single ' значения функции накопленной погрешности  передискретизированые при  прямом ходе
DIM Nakop2RS(1) as single ' значения функции накопленной погрешности  передискретизированые при  обратном ходе

DIM CikDis1RS(1) as single ' значения функции циклической погрешности  передискретизированые при  прямом ходе
DIM CikDis2RS(1) as single ' значения функции циклической погрешности  передискретизированые при  обратном ходе

DIM Ogib1uRS(1) as single ' значения функции огибающей циклической  передискретизированые погрешности при  прямом ходе
DIM Ogib1dRS(1) as single ' значения функции огибающей циклической  передискретизированые погрешности при  обратном ходе

DIM Ogib2uRS(1) as single ' значения функции огибающей циклической  передискретизированые погрешности при  прямом ходе
DIM Ogib2dRS(1) as single ' значения функции огибающей циклической  передискретизированые погрешности при  обратном ходе


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
'- ------------ графики -----------------------------------------
defstr NameGraf$ ' 
defsng DatGraf!(1) ' массив с текущим графиком

'- ------------ обработка -----------------------------------------
DIM gamp!(1) as single
defsng gampp!

'- ------------ архивы -----------------------------------------
'.rzm - файлы с расширенным числом точек для последующей фильтрации
'.rdt - файлы с  точек соответствующим Lpod! для вывода графика
'.pzm - исходный файл посл. доступа формата "номер точки, значение ф-ции"

defstr  ArcNum '- номер текущего архива
defstr  ArcPath$ '- путь текущего  архива
'defstr  ArcP1$ '-   синоним- путь текущего  архива

defstr NSObr$ '- направление вращения стола'

'--- кинематическая погрешность ----

defstr fIzm1$  '  - DELTAFI1.pzm - исходные результаты измерений при прямом ходе   (текстовый файл  формата pnt,dat!)
defstr fIzm2$  '  - DELTAFI2.pzm - исходные результаты измерений при обратном ходе (текстовый файл  формата pnt,dat!)

defstr fPrIzm1$  '  - DELTAFI1.izm - результаты измерений с восстановлением числа точек при прямом ходе (бинарный файл dat!)
defstr fPrIzm2$  '  - DELTAFI2.izm - результаты измерений с восстановлением числа точек при обратном ходе (бинарный файл dat!)

defstr fNzm1$  '  - DELTAFI1.nzm - нормализованный файл измерений для показа  при прямом ходе (без запаса на фильтрацию dat!)
defstr fNzm2$  '  - DELTAFI2.nzm - нормализованный файл измерений для показа  при обратном ходе (без запаса на фильтрацию dat!)
'--- 

'--- накопленная погрешность ----
defstr fNak1$  '= ArcP1$ + "\nakop1.pzm"
defstr fNak2$  '= ArcP1$ + "\nakop2.pzm"

'--- циклическая погрешность ----
defstr fCik1$ '= ArcP1$ + "\CikDis1.pzm": 
defstr fCik2$ '= ArcP1$ + "\CikDis2.pzm":

'--- огибающая  циклической погрешности ----
defstr fOgib1u$ '= ArcP1$ + "\Ogib1u.pzm": '- верхняя
defstr fOgib1d$ '= ArcP1$ + "\Ogib1d.pzm":  - нижняя

defstr fOgib2u$ '= ArcP1$ + "\Ogib2u.pzm": 
defstr fOgib2d$ '= ArcP1$ + "\Ogib2d.pzm":
'--- 

defstr fZazor$ '= ArcP1$ + "\zazor.pzm"               

defstr Fdiagnoz$ '= ArcP1$ + "\diagnoz"
defstr FSpectr$  'ArcP1$ + "\spectr.fft" 'скопировать из рабочей директории в архив'











$ENDIF ' __SEP_VAR2008_INC
