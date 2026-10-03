'Math-Expression Evaluator
'Updated: Sept. 10, 2001
'This source code is simply extracted (with minor modifications) from the source code of QEDTukak 1.52 
'originally written by Achilles B.Mina.
'
'You can use this file as a module in your program for the evaluation of
'user-entered mathematical expressions (like i.e. sin(.1)^2-3e2*ln(tan(.1*PI))).
'Simply call the function "EvaluateExpression(MathString$, DRGMode)" from your main program:
'MathString$ is the string to be evaluated (passed BYREF) 
'DRGMode=0 for deg, DRGMode=1 for rad, DRGMode=2 for grad
'The global variable "EvaluateErrorFlag" can be used for error checking
'Have a look at eval_tst.qb as a simple example)

$TYPECHECK ON

' Public
DEFBYTE EvaluateErrorFlag          '0:no error, 1:syntax error, 2:division by zero, 3:result undefined


' Private
DIM MathString$(1 TO 36) AS STRING
DEFSTR formula$, math$
DEFDBL CMode, CModeN, EvaluateAnswer

' Declare Sub routines
DECLARE FUNCTION EvaluateExpression (BYREF MathString$ AS STRING, DRGMode AS BYTE) AS DOUBLE
DECLARE SUB CheckSyntax
DECLARE SUB ExpSolver
DECLARE SUB Functions(par1 AS INTEGER, mathval$ AS STRING)
DECLARE SUB ExpSolverEdit
DECLARE SUB changeE
DECLARE SUB CheckE(newstring$ AS STRING)
DECLARE SUB DoInPrecision(value AS DOUBLE, value$ AS STRING)


MathString$(1) = "sin"
MathString$(2) = "cos"
MathString$(3) = "tan"
MathString$(4) = "cot"
MathString$(5) = "sec"
MathString$(6) = "csc"
MathString$(7) = "sqrt"
MathString$(8) = "log"
MathString$(9) = "ln"
MathString$(10) = "asin"
MathString$(11) = "acos"
MathString$(12) = "atan"
MathString$(13) = "acot"
MathString$(14) = "asec"
MathString$(15) = "acsc"
MathString$(16) = "sinh"
MathString$(17) = "cosh"
MathString$(18) = "tanh"
MathString$(19) = "coth"
MathString$(20) = "sech"
MathString$(21) = "csch"
MathString$(22) = "asinh"
MathString$(23) = "acosh"
MathString$(24) = "atanh"
MathString$(25) = "acoth"
MathString$(26) = "asech"
MathString$(27) = "acsch"
MathString$(28) = "inv"
MathString$(29) = "exp"
MathString$(30) = "abs"
MathString$(31) = "int"
MathString$(32) = "frac"
MathString$(33) = "floor"
MathString$(34) = "ceil"
MathString$(35) = "cbrt"
MathString$(36) = "sqr"

FUNCTION EvaluateExpression (BYREF MathString$ AS STRING, DRGMode AS BYTE) AS DOUBLE
 EvaluateErrorFlag=0
 formula$ = MathString$
 IF DRGMode = 0 THEN 
   CMode = 57.2957795130824                  'converts to degrees
   CModeN = 0.0174532925199433               'converts to radians
 ELSEIF DRGMode = 2 THEN 
   CMode = 63.6619772367584                  'converts to grad
   CModeN =0.0157079632679489                'converts to radians
 ELSE
   CMode =1
   CModeN =1
 END IF
 CheckSyntax
 IF EvaluateErrorFlag=0 THEN ExpSolverEdit 
 IF EvaluateErrorFlag=0 THEN 
   EvaluateExpression = EvaluateAnswer
 ELSE
   EvaluateExpression = 0
 END IF
END FUNCTION

SUB CheckSyntax
  DEFBYTE x
  DEFSHORT posops, startmath, wherepi
  DEFSTR math$, mathchar$, errmath$, oldmathchar$, ops$, afterendpar$
  formula$ = LCASE$(REPLACESUBSTR$(formula$," ",""))
  formula$ = REPLACESUBSTR$(formula$,"pi","3.14159265358979")
  changeE
  math$ = ""
  startmath = 0
  errmath$ = ""
  mathchar$ = ""       
  IF TALLY(formula$,")(") <> 0 THEN
    MessageDlg("Invalid -> ')('. Please correct syntax.", mtError, mbOK, 0)
    EvaluateErrorFlag = 1
    EXIT SUB
  END IF    
  IF TALLY(formula$,"(") <> TALLY(formula$,")") THEN
    MessageDlg("Missing parenthesis. Please correct syntax.", mtError, mbOK, 0)
    EvaluateErrorFlag = 1
    EXIT SUB
  ELSE
    DO     
      INC startmath
      oldmathchar$ = mathchar$
      mathchar$ = MID$(formula$,startmath,1)
      SELECT CASE mathchar$
        CASE "e"
          SELECT CASE oldmathchar$
            CASE "","^","c","s","-","+","*","/","\"
              math$ = math$ + mathchar$
              errmath$ = math$
          END SELECT
        CASE "a","b","c","f","g","h","i","l","n","o","p","q","r","s","t","v","x"              
          math$ = math$ + mathchar$
          errmath$ = errmath$ + mathchar$
          SELECT CASE oldmathchar$
            CASE "0" TO "9"
              MessageDlg(errmath$ + " is invalid. Please correct syntax.", mtError, mbOK, 0)
              EvaluateErrorFlag = 1
              EXIT SUB
          END SELECT            
        CASE "d","j","k","m","u","w","y","z"
          errmath$ = errmath$ + mathchar$
          FOR x = 1 TO 5
            ops$ = MID$("+-*/^",x,1)
            posops = RINSTR(errmath$,ops$)
            IF posops <> 0 THEN EXIT FOR
          NEXT x
          errmath$ = RIGHT$(errmath$,LEN(errmath$)-posops)
          MessageDlg(errmath$ + "?" + " Please correct syntax.", mtError, mbOK, 0)
          EvaluateErrorFlag = 1
          EXIT SUB
        CASE ")"
          afterendpar$ = MID$(formula$,startmath+1,1)
          SELECT CASE afterendpar$
            CASE "0" TO "9"
              MessageDlg(")"+ afterendpar$ + " is invalid." + " Please correct syntax.", mtError, mbOK, 0)
              EvaluateErrorFlag = 1
              EXIT SUB
          END SELECT            
        CASE "("
          SELECT CASE oldmathchar$
            CASE "0" TO "9"
              MessageDlg(oldmathchar$ + "( is invalid." + " Please correct syntax.", mtError, mbOK, 0)
              EvaluateErrorFlag = 1
              EXIT SUB
          END SELECT               
          IF math$ <> "" THEN
            FOR x = 1 TO 36
              IF math$ = MathString$(x) THEN 
                math$ = ""
              END IF
            NEXT x
            IF math$ <> "" AND math$ <> "pi" THEN      'if there's a match, skip this
              MessageDlg(errmath$ + "?" + " Please correct syntax.", mtError, mbOK, 0)
              EvaluateErrorFlag = 1
              EXIT SUB
            END IF
          END IF
        CASE "0" TO "9"
          errmath$ = errmath$ + mathchar$
          SELECT CASE oldmathchar$
            CASE "a" TO "d", "f" TO "z"
              FOR x = 1 TO 5
                ops$ = MID$("+-*/^",x,1)
                posops = RINSTR(errmath$,ops$)
                IF posops <> 0 THEN EXIT FOR
              NEXT x
              errmath$ = RIGHT$(errmath$,LEN(errmath$)-posops)
              MessageDlg(errmath$ + "?" + " Please correct syntax.", mtError, mbOK, 0)
              EvaluateErrorFlag = 1
              EXIT SUB
          END SELECT
        CASE "+","-","*","/","^"
          IF (math$ <> "" AND math$ <> "pi") AND (INSTR(math$,"(") = 0 OR INSTR(math$,")") = 0) THEN
            FOR x = 1 TO 5
              ops$ = MID$("+-*/^",x,1)
              posops = RINSTR(errmath$,ops$)
              IF posops <> 0 THEN EXIT FOR
            NEXT x
            math$ = RIGHT$(math$,LEN(math$)-posops)
            MessageDlg("Missing parenthesis. Please correct syntax.", mtError, mbOK, 0)
            EvaluateErrorFlag = 1
            EXIT SUB
          END IF              
      END SELECT    
    LOOP UNTIL startmath = LEN(formula$)
  END IF
END SUB

SUB ExpSolverEdit
DEFBYTE reformatted, formulaL, par1, par2, operator, preoperator, postoperator, start, x, y, i
DEFSTR betweenpars$, pivotoperator$, operator$, oldstring$, newstring$, checkback$
DEFDBL preopnumber, postopnumber, newstring
  FOR i = 1 TO 1000
    DO
      reformatted = 0
      formulaL = LEN(formula$)
      par1 = RINSTR(formulaL,formula$,"(")
      par2 = INSTR(par1,formula$,")")
      IF par1 = 0 OR par2 = 0 THEN
        betweenpars$ = formula$
      ELSE
        betweenpars$ = MID$(formula$,par1+1,(par2-1)-par1)
      END IF
      IF INSTR(betweenpars$,"^") <> 0 THEN
        pivotoperator$ = "^"
        operator = INSTR(betweenpars$,"^")      
      ELSEIF INSTR(betweenpars$,"*") <> 0 THEN
        pivotoperator$ = "*"
        operator = INSTR(betweenpars$,"*")
      ELSEIF INSTR(betweenpars$,"/") <> 0 THEN
        pivotoperator$ = "/"
        operator = INSTR(betweenpars$,"/")
      ELSEIF (INSTR(betweenpars$,"+") <> 0 OR INSTR(betweenpars$,"-") <> 0) THEN 'AND INSTR(betweenpars$,"E") = 0 THEN
        IF MID$(betweenpars$,1,1) = "-" THEN 
          start = 2
        ELSE
          start = 1
        END IF
        IF (TALLY(betweenpars$,"-") = 1 AND TALLY(betweenpars$,"+") = 0) AND MID$(betweenpars$,1,1) = "-" THEN
          checkback$ = MID$(formula$,par1-1,1)
          SELECT CASE checkback$
            CASE "c","g","h","l","n","p","r","s","t","v"
              Functions(par1,betweenpars$)
            CASE ELSE
              formula$ = DELETE$(formula$,par1,1)
              formula$ = DELETE$(formula$,par2-1,1) 
          END SELECT
          IF formula$ = betweenpars$ THEN
            EvaluateAnswer = VAL(formula$)
            EXIT SUB
          END IF
          reformatted = 1
        ELSE
          FOR y = start TO LEN(betweenpars$)
            operator$ = MID$(betweenpars$,y,1)
            SELECT CASE operator$
              CASE "+","-"
                operator = y
                pivotoperator$ = MID$(betweenpars$,operator,1)
                EXIT FOR
            END SELECT
          NEXT x
        END IF
      ELSE
        checkback$ = MID$(formula$,par1-1,1)
        SELECT CASE checkback$
          CASE "c","g","h","l","n","p","r","s","t","v"
            Functions(par1,betweenpars$)
          CASE ELSE
            formula$ = DELETE$(formula$,par1,1)
            formula$ = DELETE$(formula$,par2-1,1) 
        END SELECT
        IF formula$ = betweenpars$ THEN
          EvaluateAnswer = VAL(formula$)
          EXIT SUB
        END IF
        reformatted = 1
      END IF
      formula$ = REPLACESUBSTR$(formula$,"--","+")
    LOOP UNTIL reformatted = 0
    x = operator
    DO
      INC x
      IF x >= LEN(betweenpars$) THEN
        postoperator = x
        EXIT DO
      END IF  
      operator$ = MID$(betweenpars$,x,1)
      SELECT CASE operator$
        CASE "+","*","/","^"
          postoperator = x - 1
          EXIT DO
        CASE "-"
          IF x <> operator + 1 THEN
            postoperator = x - 1
            EXIT DO
          END IF
      END SELECT
    LOOP
    x = operator
    DO
      DEC x
      IF x <= 1 THEN
       preoperator = 1
       EXIT DO
      END IF
      operator$ = MID$(betweenpars$,x,1)
      SELECT CASE operator$
        CASE "+","-","*","/","^"
          preoperator = x + 1
          EXIT DO
      END SELECT
    LOOP
    preopnumber = VAL(MID$(betweenpars$,preoperator,(operator-1)-(preoperator-1)))
    postopnumber = VAL(MID$(betweenpars$,operator+1,postoperator-operator))
    oldstring$ = MID$(formula$,par1+preoperator,postoperator-(preoperator-1))
    SELECT CASE pivotoperator$
      CASE "^"
        newstring = preopnumber ^ postopnumber
      CASE "*"
        newstring = preopnumber * postopnumber
      CASE "/"
        IF postopnumber = 0 THEN
          MessageDlg("Can't divide by zero. Please correct entry.", mtError, mbOK, 0)
          EvaluateErrorFlag = 2
          EXIT SUB
        END IF
        newstring = preopnumber / postopnumber
      CASE "+"
        newstring = preopnumber + postopnumber
      CASE "-"
        newstring = preopnumber - postopnumber            
    END SELECT
    DoInPrecision(newstring,@newstring$)
    CheckE(@newstring$)
    formula$ = REPLACESUBSTR$(formula$,oldstring$,newstring$)
  NEXT x
END SUB

SUB Functions(par1 AS INTEGER,mathval$ AS STRING)
  DEFBYTE i
  DEFINT startmath
  DEFSTR mathchar$, oldval$, outformold$, insertval$, outform$
  DEFDBL insertval
  startmath = par1
  insertval$ = ""
  DO        
    DEC startmath
    mathchar$ = MID$(formula$,startmath,1)
    SELECT CASE mathchar$
      CASE "+","-","*","/","^","("
        EXIT DO
      CASE "a","b","c","e","f","g","h","i","l","n","o","p","q","r","s","t","v","x"
        math$ = mathchar$ + math$
    END SELECT        
  LOOP UNTIL startmath <= 1
  FOR i = 1 TO 36
    IF math$ = MathString$(i) THEN
      math$ = ""
      oldval$ = MathString$(i) + "(" + mathval$ + ")"
      SELECT CASE i
        CASE 1
          insertval = SIN(VAL(mathval$)*CModeN)
        CASE 2
          insertval = COS(VAL(mathval$)*CModeN)
        CASE 3
          insertval = TAN(VAL(mathval$)*CModeN)
        CASE 4
          insertval = 1/(TAN(VAL(mathval$)*CModeN))
        CASE 5
          insertval = 1/(COS(VAL(mathval$)*CModeN))
        CASE 6
          insertval = 1/(SIN(VAL(mathval$)*CModeN))
        CASE 7
          insertval = SQR(VAL(mathval$))
        CASE 8
          insertval = LOG(VAL(mathval$))/LOG(10)
        CASE 9
          insertval = LOG(VAL(mathval$))
        CASE 10
          IF VAL(mathval$) > 1 THEN
            outformold$ = outform$  
            outform$ = "undefined"
            EvaluateErrorFlag = 3
          ELSEIF VAL(mathval$) = 1 THEN
            IF CMode = 1 THEN
              insertval = 1.5707963267949
            ELSE
              insertval = 90
            END IF           
          ELSE
            insertval = ATN(VAL(mathval$)/SQR(-VAL(mathval$)*VAL(mathval$) +1))*CMode
          END IF  
        CASE 11
          IF VAL(mathval$) > 1 THEN
            outformold$ = outform$  
            outform$ = "undefined"
            EvaluateErrorFlag = 3
          ELSEIF VAL(mathval$) = 0 THEN
            IF CMode = 1 THEN
              insertval = 1.5707963267949
            ELSE
              insertval = 90
            END IF
          ELSEIF VAL(mathval$) = 1 THEN
            insertval = 0                                 
          ELSE        
            insertval = (-ATN(VAL(mathval$)/SQR(-VAL(mathval$)*VAL(mathval$) +1)) + 1.570796)*CMode
          END IF          
        CASE 12
          insertval = ATN(VAL(mathval$))*CMode
        CASE 13
          insertval = (-ATN(VAL(mathval$)) + 1.570796)*CMode
        CASE 14
          IF VAL(mathval$) = 0 THEN
            outformold$ = outform$  
            outform$ = "undefined"
            EvaluateErrorFlag = 3
          ELSE        
            insertval = (ATN(SQR(VAL(mathval$)*VAL(mathval$) -1)) + (SGN(VAL(mathval$)) -1)*1.570796)*CMode
          END IF
        CASE 15
          IF VAL(mathval$) = 0 THEN
            outformold$ = outform$  
            outform$ = "undefined"       
            EvaluateErrorFlag = 3
          ELSEIF VAL(mathval$) = 1 THEN
            IF CMode = 1 THEN
              insertval = 1.5707963267949
            ELSE
              insertval = 90
            END IF 
          ELSE  
            insertval = (ATN(1/SQR(VAL(mathval$)*VAL(mathval$) -1)) + (SGN(VAL(mathval$)) -1)*1.570796)*CMode
          END IF  
        CASE 16
          insertval = (EXP(VAL(mathval$)) - EXP(-VAL(mathval$)))/2
        CASE 17
          insertval = (EXP(VAL(mathval$)) + EXP(-VAL(mathval$)))/2
        CASE 18
          insertval = -EXP(-VAL(mathval$)) /(EXP(VAL(mathval$)) + EXP(-VAL(mathval$)))*2 + 1
        CASE 19
          insertval = EXP(-VAL(mathval$))/(EXP(VAL(mathval$)) - EXP(-VAL(mathval$)))*2 + 1
        CASE 20
          insertval = 2/(EXP(VAL(mathval$)) + EXP(-VAL(mathval$)))
        CASE 21
          insertval = 2/(EXP(VAL(mathval$)) - EXP(-VAL(mathval$)))
        CASE 22
          insertval = LOG(VAL(mathval$) + SQR(VAL(mathval$)*VAL(mathval$) + 1))
        CASE 23
          insertval = LOG(VAL(mathval$) + SQR(VAL(mathval$)*VAL(mathval$) - 1))
        CASE 24
          insertval = LOG((1 + VAL(mathval$))/(1 - VAL(mathval$)))/2
        CASE 25
          insertval = LOG((VAL(mathval$) + 1)/(VAL(mathval$) - 1))/2
        CASE 26
          insertval = LOG((SGN(VAL(mathval$))*SQR(-VAL(mathval$)*VAL(mathval$) + 1) + 1)/VAL(mathval$))
        CASE 27
          insertval = LOG((SGN(VAL(mathval$))*SQR(VAL(mathval$)*VAL(mathval$) + 1) + 1)/VAL(mathval$))
        CASE 28
          insertval = 1/VAL(mathval$)
        CASE 29
          insertval = EXP(VAL(mathval$))
        CASE 30
          insertval = ABS(VAL(mathval$))
        CASE 31
          insertval = INT(VAL(mathval$))
        CASE 32
          insertval = FRAC(VAL(mathval$))
        CASE 33
          insertval = FLOOR(VAL(mathval$))
        CASE 34
          insertval = CEIL(VAL(mathval$))
        CASE 35
          insertval = VAL(mathval$)^(1/3)
        CASE 36
          insertval = VAL(mathval$)^2
      END SELECT
      DoInPrecision(insertval,@insertval$)
    END IF
  NEXT i
  CheckE(@insertval$)
  formula$ = REPLACESUBSTR$(formula$,oldval$,insertval$)
END SUB

SUB DoInPrecision(value AS DOUBLE, value$ AS STRING)
  value$ = FORMAT$("%g",value)
END SUB

SUB changeE
  DEFBYTE posE, x
  DEFSTR E$
  x = 0
  DO
    INC x
    E$ = MID$(formula$,x,1)
    IF E$ = "" THEN
      EXIT SUB
    ELSEIF E$ = "e" THEN
      posE = x
      INC x
      E$ = MID$(formula$,x,1)  
      SELECT CASE E$
        CASE "0" TO "9"
          formula$ = DELETE$(formula$,posE,1)
          formula$ = INSERT$("*10^",formula$,posE)
        CASE "-"
          formula$ = DELETE$(formula$,posE,2)
          formula$ = INSERT$("*1/10^",formula$,posE)
        CASE "c","i","x"
        CASE ELSE
          SHOWMESSAGE "Syntax error."
          EvaluateErrorFlag = 1
          EXIT SUB
      END SELECT
    END IF
  LOOP                  
END SUB

SUB CheckE(newstring$ AS STRING)
  DEFSTR powerEnd$, oldbase$, checkneg$, base$, power$, newbase$
  DEFBYTE whereE, whereDot, x, move, powerEnd
  DEFSHORT power
  whereE = INSTR(newstring$,"E")
  x = whereE
  IF whereE = 0 THEN
    EXIT SUB
  ELSE
    whereDot = RINSTR(whereE,newstring$,".")
    IF whereDot < 2 THEN whereDot = 2      'since in scientific format
    DO
      INC x
      IF x >= LEN(newstring$) THEN
        powerEnd = x
        EXIT DO
      END IF  
      powerEnd$ = MID$(newstring$,x,1)
      SELECT CASE powerEnd$
        CASE "+","*","/",")"
          powerEnd = x - 1
          EXIT DO
        CASE "-"
          IF x <> whereE + 1 THEN
            powerEnd = x - 1
            EXIT DO
          END IF
      END SELECT
    LOOP
    oldbase$ = LEFT$(newstring$,whereE-1)
    base$ = REPLACESUBSTR$(oldbase$,".","")
    power$ = MID$(newstring$,whereE+1,powerEnd-whereE)
    power = VAL(power$)
    IF power => 14 THEN EXIT SUB
    checkneg$ = LEFT$(power$,1)
    IF checkneg$ = "-" THEN
      move = ABS(power)
      newbase$ = "." + STRING$(move-(whereDot-1),"0") + base$
    END IF
    newstring$ = newbase$
  END IF
END SUB
  