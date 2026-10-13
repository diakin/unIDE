$IFNDEF __MATH_INC   ' IncManager: include guard
$DEFINE __MATH_INC
CONST rqPI = 3.141592654           '(This is PI)
CONST rqE = 2.718281828            '(This is e)
CONST rqh = 6.62620 * 10 ^ (-34)   '(J*S: Planck const.)
CONST rqc = 2.997925 * 10 ^ 8      '(m/s: velocity of light in vacuum)
'-------------------------------------------------------------------------------
'   ACOSH() returns the hyperbolic areacosine of x
'-------------------------------------------------------------------------------
Function ACOSH(value AS DOUBLE) AS DOUBLE
  SELECT CASE value
   CASE IS < 1
    MessageBox("Invalid Argument .", "ACOSH - Error", 0)
   CASE IS >= 1
    ACOSH =  ( LOG (value + SQR( value ^ 2 - 1 )))
  END SELECT
End Function
'-------------------------------------------------------------------------------
'   ACOT() returns the arccotangent of x
'-------------------------------------------------------------------------------
Function ACOT(value AS DOUBLE) AS DOUBLE
 ACOT = ((rqPI / 2) - ATAN (value))
End Function
'-------------------------------------------------------------------------------
'   ACOTH() returns the hyperbolic areacotangent of x
'-------------------------------------------------------------------------------
Function ACOTH(value AS DOUBLE) AS DOUBLE
 SELECT CASE ABS (value)
  CASE IS > 1
   ACOTH =  (LOG((value + 1) / (value - 1)) * 0.5)
  CASE ELSE
   MessageBox("ERROR: Invalid Argument .", "ACOTH - Error", 0)
 END SELECT
End Function
'-------------------------------------------------------------------------------
'   ACOSEC() returns the arccosecans of x
'-------------------------------------------------------------------------------
Function ACOSEC(value AS DOUBLE) AS DOUBLE
 SELECT CASE ABS (value)
  CASE IS < 1
   MessageBox("Invalid Argument .", "ACOSEC - Error", 0)
  CASE ELSE
   ACOSEC =  (ASIN(1/value))
  END SELECT
End Function
'-------------------------------------------------------------------------------
'   ACOSECH() returns the hyperbolic arccosecans of x
'-------------------------------------------------------------------------------
Function ACOSECH(value AS DOUBLE) AS DOUBLE
 SELECT CASE ABS(value)
  CASE = 0
   MessageBox("Invalid Argument .", "ACOSECH - Error", 0)
  CASE ELSE
   ACOSECH =  (ASINH(1 / value))
 END SELECT
End Function
'-------------------------------------------------------------------------------
'   ADDZ() returns the sum of two complex numbers
'-------------------------------------------------------------------------------
Function ADDZ(Z()AS DOUBLE ) AS DOUBLE
    re1 = Z(0): im1 = Z(1) : re2 = Z(2) : im2 = Z(3)
    Z(0) = re1 + re2
    Z(1) = im1 + im2
    Z(2) = 0
    Z(3) = 0
    ADDZ = Z()
End Function
'-------------------------------------------------------------------------------
'   ASINH() returns the hyperbolic areasine of x
'-------------------------------------------------------------------------------
Function ASINH(value AS DOUBLE) AS DOUBLE
 ASINH = LOG (value + (SQR(value * value + 1)))
End Function
'-------------------------------------------------------------------------------
'   ASEC() returns the arccosecans of x
'-------------------------------------------------------------------------------
Function ASEC(value AS DOUBLE) AS DOUBLE
 SELECT CASE ABS (value)
  CASE IS < 1
    MessageBox("ERROR:Invalid Argument .", "ASEC - Error", 0)
  CASE ELSE
   ASEC =  (rqPI / 2 - ASIN( 1 / value))
 END SELECT
End Function
'-------------------------------------------------------------------------------
'   ASECH() returns the hyperbolic arccosecans of x
'-------------------------------------------------------------------------------
Function ASECH(value AS DOUBLE) AS DOUBLE
 SELECT CASE ABS (value)
  CASE IS > 1
   MessageBox("ERROR:Invalid Argument .", "ASECH - Error", 0)
  CASE IS <= 0
   MessageBox("ERROR:Invalid Argument .", "ASECH - Error", 0)
  CASE ELSE
   ASECH = (ACOSH(1 / value))
 END SELECT
End Function
'-------------------------------------------------------------------------------
'   ATANH() returns the hyperbolic areatangent of x
'-------------------------------------------------------------------------------
Function ATANH(value AS DOUBLE) AS DOUBLE
 SELECT CASE ABS(value)
  CASE IS < 1
   ATANH = (LOG((1 + value) / (1 - value)) * 0.5)
  CASE 0
   ATANH = 1
  CASE ELSE
   MessageBox("ERROR:Invalid Argument .", "ATANH - Error", 0)
 END SELECT
End Function
'--------------------------------------------------------------------------------
'   CONJZ() returns the conjugated complex number of a complex number
'--------------------------------------------------------------------------------
Function CONJZ(Z()AS DOUBLE ) AS DOUBLE
    re = Z(0): im = Z(1)
    Z(1) = im * (-1)
    CONJZ = Z()
End Function
'-------------------------------------------------------------------------------
'   COSEC() returns the cosecans of x
'-------------------------------------------------------------------------------
Function COSEC(value AS DOUBLE) AS DOUBLE
 COSEC = 1 / SIN(value)
End Function
'-------------------------------------------------------------------------------
'   COSECH() returns the hyperbolic cosecans of x
'-------------------------------------------------------------------------------
Function COSECH(value AS DOUBLE) AS DOUBLE
 COSECH = (2 / (EXP(value) - EXP(value * -1)))
End Function
'-------------------------------------------------------------------------------
'   COSH() returns the hyperbolic cosine of x
'-------------------------------------------------------------------------------
Function COSH(value AS DOUBLE) AS DOUBLE
 COSH = (0.5 * (EXP(value) + EXP(value * -1)))
 IF value = 0 THEN COSH = 1
End Function
'--------------------------------------------------------------------------------
'   COSZ() returns the cosine of a complex number
'--------------------------------------------------------------------------------
Function COSZ(Z()AS DOUBLE ) AS DOUBLE
    re = Z(0): im = Z(1)
    Z(0) = COS(re) * COSH(im)
    Z(1) = SIN(re) * SINH(im)
    COSZ = Z()
End Function
'--------------------------------------------------------------------------------
'   COSHZ() sine of a complex number
'--------------------------------------------------------------------------------
Function COSHZ(Z()AS DOUBLE ) AS DOUBLE
    re = Z(0): im = Z(1)
    Z(0) = COSH(re) * COS(im)
    Z(1) = SINH(re) * SIN(im)
    COSHZ = Z()
End Function
'-------------------------------------------------------------------------------
'   COT() returns the cotangent of x
'-------------------------------------------------------------------------------
Function COT(value AS DOUBLE) AS DOUBLE
 COT = 1 / TAN(value)
End Function
'-------------------------------------------------------------------------------
'   COTH() returns the hyperbolic cotangent of x
'-------------------------------------------------------------------------------
Function COTH(value AS DOUBLE) AS DOUBLE
 SELECT CASE value
  CASE 0
   MessageBox("ERROR: Invalid Argument .", "COTH - Error", 0)
  CASE ELSE
   COTH = COSH(value) / SINH(value)
  END SELECT
End Function
'-------------------------------------------------------------------------------
'   DEG2RAD() returns radians instead of degrees
'-------------------------------------------------------------------------------
Function DEG2RAD(value AS DOUBLE) AS DOUBLE
 DEG2RAD = value * 0.017453
End Function
'--------------------------------------------------------------------------------
'   DIVZ() returns the quotient of two complex numbers
'--------------------------------------------------------------------------------
'   DIVZ() = Z1 / Z2
Function DIVZ(Z()AS DOUBLE ) AS DOUBLE
    re1 = Z(0): im1 = Z(1) : re2 = Z(2) : im2 = Z(3)
    Z(0) = (req * re2 + im1 * im2) / (re2*re2 + im2*im2)
    Z(1) = (-re1 * im2 + re2 * im1) / (re2 * re2 + im2 * im2)
    Z(2) = 0
    Z(3) = 0
    DIVZ = Z()
End Function
'--------------------------------------------------------------------------------
'   EVEN() returns "1" (= true) if a number is even, else "0"
'--------------------------------------------------------------------------------
Function EVEN(value AS INTEGER ) AS INTEGER
   IF FRAC(value / 2) = 0 THEN
    EVEN = 1
   ELSE
    EVEN = 0
   END IF
End Function
'--------------------------------------------------------------------------------
'    EXPZ() returns the exponential value of a complex number (= e^z)
'--------------------------------------------------------------------------------
Function EXPZ(Z()AS DOUBLE ) AS DOUBLE
    re = Z(0): im = Z(1) : a = Z(3)
    Z(0) = EXP(re) * COS (im)
    Z(1) = EXP(re) * SIN (im)
    EXPZ = Z()
End Function
'-------------------------------------------------------------------------------
'   FAC() returns the factorial of the integer x
'-------------------------------------------------------------------------------
Function FAC(value AS LONG) AS LONG
 SELECT CASE value
  CASE IS < 13
   N = value
   value = 1
    For I = 1 to N
     value = value * I
    NEXT I
   FAC = value
  CASE IS > 12
   MessageBox("ERROR: Invalid Argument . Argument must <= 12!", "FAC - Error", 0)
 END SELECT
End Function
'-------------------------------------------------------------------------------
'   GCD() returns the greatest common denominator of two integers
'   based on the Euclidean algorithm
'-------------------------------------------------------------------------------
Function GCD(value1 AS DOUBLE, value2 AS DOUBLE ) AS LONG
  ERROR% = 0
  SELECT CASE value1
   CASE IS <> INT(value1) 'Integer check
    ERROR% = 1
   CASE 0                 'ZERO check
    ERROR% = 2
  END SELECT
  SELECT CASE value2
   CASE IS <> INT(value2) 'Integer check
    ERROR% = 1
   CASE 0                 'ZERO Check
    ERROR% = 2
  END SELECT
  SELECT CASE ERROR%
   CASE 0
    value1 = ABS(value1) : value2 = ABS(value2)    'Euclidean algorithm
     DO
      Res = value1 - value2 * INT(value1/value2)
      IF Res = 0 THEN GCD = value2
      value1 = value2
      value2 = Res
     LOOP UNTIL Res = 0
   CASE 1
     GCD = 0
     MessageBox("Invalid Argument (no INTEGER).", "GCD - Error", 0)
   CASE 2
     GCD = 0
     MessageBox("Invalid Argument (ZERO).", "GCD - Error", 0)
  END SELECT
End Function
'--------------------------------------------------------------------------------
'   INVZ() returns the reciprocal value of a complex number
'--------------------------------------------------------------------------------
' INVZ(Z) = 1/Z
Function INVZ(Z()AS DOUBLE ) AS DOUBLE
    re = Z(0): im = Z(1)
    Z(0) =  re / ( re * re + im * im)
    Z(1) =  im / ( re * re + im * im)
    INVZ = Z()
End Function
'--------------------------------------------------------------------------------
'     LOGZ() returns the natural logarithm of a complex number
'--------------------------------------------------------------------------------
Function LOGZ(Z()AS DOUBLE ) AS DOUBLE
    re = Z(0): im = Z(1)
    Z(0) =  LOG (re / ( re * re + im * im))
    Z(1) =  im / ( re * re + im * im)
    LOGZ = Z()
End Function
'--------------------------------------------------------------------------------
'    LOG10() returns the base 10 log of x
'--------------------------------------------------------------------------------
 Function LOG10(value AS DOUBLE) AS DOUBLE
'  LOG10 = (LOG (value) * LOG(10 * rqE))
  LOG10 = LOG (value)/LOG(10)

 End Function
'--------------------------------------------------------------------------------
'     LOG10Z() returns the 10-th logarithm of z (base is 10)
'--------------------------------------------------------------------------------
Function LOG10Z(Z()AS DOUBLE ) AS DOUBLE
    re = Z(0): im = Z(1)
    Z(0) =  LOG (re / ( re * re + im * im))/ LOG (10)
    Z(1) =  im / ( re * re + im * im) / LOG (10)
    LOG10Z = Z()
End Function
'--------------------------------------------------------------------------------
'     LOGAZ() returns the a-th logarithm of z (base is a)
'--------------------------------------------------------------------------------
Function LOGAZ(Z()AS DOUBLE ) AS DOUBLE
    re = Z(0): im = Z(1) : a = Z(3)
    Z(0) =  LOG (re / ( re * re + im * im))/ LOG (a)
    Z(1) =  im / ( re * re + im * im) / LOG (a)
    LOGAZ = Z()
End Function
'--------------------------------------------------------------------------------
'    MAGZ() returns the absolute value of a complex number
'--------------------------------------------------------------------------------
Function MAGZ(Z()AS DOUBLE ) AS DOUBLE
    re = Z(0): im = Z(1)
    Z(0) = SQR( re * re + im * im)   '= |Z|
    Z(1) = 0
    MAGZ = Z()
End Function
'--------------------------------------------------------------------------------
'    MULZ() returns the product of two complex numbers
'--------------------------------------------------------------------------------
Function MULZ(Z()AS DOUBLE ) AS DOUBLE
    re1 = Z(0): im1 = Z(1) : re2 = Z(2) : im2 = Z(3)
    Z(0) = re1 * re2 - im1 * im2
    Z(1) = re1 * im2 + re2 * im1
    Z(2) = 0
    Z(3) = 0
    MULZ = Z()
End Function
'--------------------------------------------------------------------------------
'    NORZ() returns the normal form of a complex value
'--------------------------------------------------------------------------------
' Z = x + iy = re + i*im   =   r*e^i*theta
Function NORZ(Z()AS DOUBLE ) AS DOUBLE
    re = Z(0): im = Z(1)
    Z(0) = SQR( re * re + im * im)    ' = r = value
    Z(1) = ATAN (im / re)             ' = theta = argument
    NORZ = Z()                        'Z() = (r,theta)
End Function
'--------------------------------------------------------------------------------
'   ODD() returns "1" (=true) if a number(INTEGER) is odd
'--------------------------------------------------------------------------------
Function ODD_math(value AS INTEGER ) AS INTEGER
   IF FRAC( value / 2 ) <> 0 THEN
      ODD_math = 1
    ELSE
      ODD_math = 0
   END IF
End Function
'--------------------------------------------------------------------------------
'   POLZ() returns Z IN the polar coordinate system
'--------------------------------------------------------------------------------
' Transformation from    z = x + iy     to     z = r*cos((phi) + r*i*sin(phi)
Function POLZ(Z()AS DOUBLE ) AS DOUBLE
    re = Z(0): im = Z(1)
    Z(0) = SQR( re * re + im * im) * COS(ATAN (im / re))
    Z(1) = SQR( re * re + im * im) * SIN(ATAN (im / re))
    POLZ = Z()
End Function
'--------------------------------------------------------------------------------
'    POWZ() returns the power n  of a complex number = (x+iy)^n = z^n
'--------------------------------------------------------------------------------
 Function POWZ(Z()AS DOUBLE ) AS DOUBLE
    re = Z(0): im = Z(1) : expo = Z(2)
     Z(0) =(SQR( re * re + im * im)) ^ expo * COS(expo * ATAN (im / re) )
     Z(1) =(SQR( re * re + im * im)) ^ expo * SIN(expo * ATAN (im / re) )
     Z(2) = 0
    POWZ = Z()
End Function
'--------------------------------------------------------------------------------
'   RAD2DEG() returns degrees instead of radians
'--------------------------------------------------------------------------------
Function RAD2DEG(value AS DOUBLE) AS DOUBLE
 RAD2DEG = value / 0.017453
End Function
'--------------------------------------------------------------------------------
'   SEC() returns the secans of x
'--------------------------------------------------------------------------------
Function SEC(value AS DOUBLE) AS DOUBLE
 SEC = 1 / COS(value)
End Function
'--------------------------------------------------------------------------------
'   SECH() returns the hyperbolic secans of x
'--------------------------------------------------------------------------------
Function SECH(value AS DOUBLE) AS DOUBLE
 SECH = (2 / (EXP(value) + EXP(value * -1)))
' SECH = 1/ COSH (value)
End Function
'--------------------------------------------------------------------------------
'   SINH() returns the hyperbolic sine of x
'--------------------------------------------------------------------------------
Function SINH(value AS DOUBLE) AS DOUBLE
 SINH = (0.5 * (EXP(value) - EXP(value * -1)))
  IF value = 0 THEN SINH = 0
End Function
'--------------------------------------------------------------------------------
'   SINZ() sine of a complex number
'--------------------------------------------------------------------------------
Function SINZ(Z()AS DOUBLE ) AS DOUBLE
    re = Z(0): im = Z(1)
    Z(0) = SIN(re) * COSH(im)
    Z(1) = COS(re) * SINH(im)
    SINZ = Z()
End Function
'--------------------------------------------------------------------------------
'   SINHZ() sine of a complex number
'--------------------------------------------------------------------------------
Function SINHZ(Z()AS DOUBLE ) AS DOUBLE
    re = Z(0): im = Z(1)
    Z(0) = SINH(re) * COS(im)
    Z(1) = COSH(re) * SIN(im)
    SINHZ = Z()
End Function
'--------------------------------------------------------------------------------
'   SQRZ() returns the square root of acomplex number
'--------------------------------------------------------------------------------
Function SQRZ(Z()AS DOUBLE ) AS DOUBLE
    re = Z(0): im = Z(1)
    Z(0) = ((re + SQR(re * re + im * im)) * 0.5) ^ 0.5
    Z(1) = (((re * -1) + SQR(re * re + im * im)) * 0.5) ^ 0.5
    SQRZ = Z()
End Function
'-------------------------------------------------------------------------------
'   SUBZ() returns the difference of two complex numbers
'-------------------------------------------------------------------------------
Function SUBZ(Z()AS DOUBLE ) AS DOUBLE
    re1 = Z(0): im1 = Z(1) : re2 = Z(2) : im2 = Z(3)
    Z(0) = re1 - re2
    Z(1) = im1 - im2
    Z(2) = 0
    Z(3) = 0
    SUBZ = Z()
End Function
'--------------------------------------------------------------------------------
'   TANH() returns the hyperbolic tangent of x
'--------------------------------------------------------------------------------
Function TANH(value AS DOUBLE) AS DOUBLE
    TANH = SINH(value) / COSH(value)
    IF value = 0 THEN TANH = 0
End Function
'--------------------------------------------------------------------------------
'   TANZ() returns the tangent of a complex number
'--------------------------------------------------------------------------------
Function TANZ(Z()AS DOUBLE ) AS DOUBLE
    re1 = Z(0): im1 = Z(1)
    Z(0) =  SIN(2 * re) / (COS(2 * re) + COSH(2 * im))
    Z(1) =  SINH(2 * im) / (COS(2 * re) + COSH(2 * im))
    TANZ = Z()
End Function
'MaxInt,MinInt
Const MaxInt = 2147483647
Const MinInt =-2147483648
'---------------------------------------------------------------------
' FindMax (int1,int2..intN as integer)
'---------------------------------------------------------------------
FunctionI FindMax_math (...) as Double
     Dim Largest as Double
     Dim I as BYTE
     Largest = -999999999999
     For I = 1 TO ParamValCount
       If ParamVal(I) > Largest Then
          Largest = ParamVal(I)
       End If
     Next
     FindMax_math = Largest         ' or Result = Largest
End FunctionI
'---------------------------------------------------------------------
' FindMin (int1,int2..intN as integer)
'---------------------------------------------------------------------
FunctionI FindMin_math (...) as Double
     Dim Largest as Double
     Dim I as BYTE
     Largest = 999999999999
     For I = 1 TO ParamValCount
       If ParamVal(I) < Largest Then
          Largest = ParamVal(I)
       End If
     Next
     FindMin_math = Largest         ' or Result = Largest
End FunctionI
'---------------------------------------------------------------------
' MinValue (Array() of double)
'---------------------------------------------------------------------
Function MinValue(AData() as Double) as Double
Dim I as Integer
  Result = AData(LBound(AData))
  For I = LBound(AData) + 1 to UBound(AData)-1
    If Result > AData(I) Then
      Result = AData(I)
    End If
  Next I
End Function
'---------------------------------------------------------------------
' MaxValue (Array() of double)
'---------------------------------------------------------------------
Function MaxValue(AData() as Double) as Double
Dim I as Integer
  Result = AData(LBound(AData))
  For I = LBound(AData) + 1 to UBound(AData)-1
    If Result < AData(I) Then
      Result = AData(I)
    End If
  Next I
End Function
'---------------------------------------------------------------------
' MinIntValue (Array() of integer)
'---------------------------------------------------------------------
Function MinIntValue(AData() as Integer) as Integer
Dim I as Integer
  Result = AData(LBound(AData))
  For I = LBound(AData) + 1 to UBound(AData)-1
    If Result > AData(I) Then
      Result = AData(I)
    End If
  Next I
End Function
'---------------------------------------------------------------------
' MaxIntValue (Array() of integer)
'---------------------------------------------------------------------
Function MaxIntValue(AData() as Integer) as Integer
Dim I as Integer
  Result = AData(LBound(AData))
  For I = LBound(AData) + 1 to UBound(AData)-1
    If Result < AData(I) Then
      Result = AData(I)
    End If
  Next I
End Function
'---------------------------------------------------------------------
' Power (base,exponent)
'---------------------------------------------------------------------
Function Power(Base as Double, Exponent as Double) as Double
If Int(Exponent) <> Exponent then
   MessageBox("Error : Invalid floating point operation.","Power - Invalid Exponent",0)
   Exit Function
End If
  If Exponent = 0.0 Then
    Result = 1.0               '{ n**0 = 1 }
  ElseIf (Base = 0.0) and (Exponent > 0.0) Then
    Result = 0.0               '{ 0**n = 0, n > 0 }
  ElseIf (Frac(Exponent) = 0.0) and (Abs(Exponent) <= MaxInt) then
    Result = Base^Int(Fix(Exponent))
  else
    Result = Exp(Exponent * Log(Base))
  End If
End Function

$ENDIF   ' IncManager: __MATH_INC
