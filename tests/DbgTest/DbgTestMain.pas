unit DbgTestMain;

// ---------------------------------------------------------------------------
//  Проверочный проект отладчика SyntaxHLClaude
//
//  Открыть DbgTest.dpr в SyntaxHLClaude, поставить точки (F5 или щелчок по
//  номеру строки) на строках с пометкой «ТОЧКА», запустить F9. Сборка с
//  точками - отладочная (-$D+ -GD -V), в логе после запуска должна быть
//  строка «Отладчик: TD32 - процедур ..., параметров и локальных ...».
//
//  1. Кнопка «Типы переменных» -> ТОЧКА 1 в TestAllTypes.
//     В окне Watch - пункт меню «Добавить переменные процедуры». Ожидаемые
//     значения написаны в комментариях справа от присваиваний. Отдельно
//     добавить (Ins): GlobalCount, GlobalText, GlobalCounter,
//     RecVal.Title, ObjVal.FCount, ObjVal.FName.
//
//  2. Кнопка «Шаги и вызовы» -> ТОЧКА 2 в btnStepsClick.
//     F8 на строке с Factorial - вызов проходится целиком, следующая
//     строка. F7 на строке с WithVarParam - заход в процедуру; там в Watch
//     AValue (var-параметр, 41), AText, AObj. F8 до конца процедуры -
//     возврат в btnStepsClick. Рекурсия: ТОЧКА 3 в Factorial, F8 на строке
//     с вызовом Factorial(ANum - 1) - остановка на следующей строке того же
//     уровня, а не в глубине рекурсии.
//
//  3. Кнопка «Цикл и Run to cursor» -> ТОЧКА 4 перед циклом.
//     Каретку на строку «ПОСЛЕ ЦИКЛА», F4 - остановка там, Sum = 5050.
//     Ещё раз: ТОЧКА 4, каретку на строку внутри цикла, F4 - остановка на
//     первом проходе, Step = 1; F4 ещё раз там же - Step = 2.
//
//  4. Кнопка «Объект и поля Self» -> ТОЧКА 5 в TCounter.Step.
//     Watch: FCount, FName, FKind, FItems (поля Self без «Self.»),
//     Self.FCount, ADelta. В btnObjectClick (ТОЧКА 6): Tag (свойство на
//     поле FTag, 77, тип «Integer (поле +12)»), edtName (объект TEdit),
//     Self (TFormDbgTest),
//     Counter.FName.
//     Вложенная процедура: ТОЧКА 7 в Inner - Watch InnerVar (5), OuterVar
//     читается через кадр Outer: 10 до строки, 15 после F8 (тип - «Integer
//     (кадр Outer)»).
//
//  5. Кнопка «Исключение» -> ТОЧКА 8, F8 через строку с raise - шаг
//     прерывается, программа идёт дальше, в логе исключение EDbgTest.
//     ТОЧКА 9 в except - остановка; Watch E - EDbgTest($...),
//     E.FMessage - текст исключения.
//
//  Поля предков из VCL и RTL (Tag -> FTag у TComponent, FMessage у
//  Exception) найдутся, только если их описание есть в TD32 этого exe:
//  модули VCL собраны без отладочной информации. «Нет поля» там - тоже
//  результат проверки, его стоит прислать.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls;

type
  TColorKind = (ckRed, ckGreen, ckBlue);
  TColorSet = set of TColorKind;
  TSmallRange = 1..100;

  TPointRec = record
    PosX: Integer;
    PosY: Integer;
    Title: string[20];
    Weight: Double;
  end;

  TCounter = class
  private
    FCount: Integer;
    FName: string;
    FKind: TColorKind;
    FItems: TColorSet;
    public
    constructor Create(const AName: string);
    procedure Step(ADelta: Integer);
    function Total: Integer;
  end;

  EDbgTest = class(Exception);

  TFormDbgTest = class(TForm)
    lblName: TLabel;
    edtName: TEdit;
    btnTypes: TButton;
    btnSteps: TButton;
    btnLoop: TButton;
    btnObject: TButton;
    btnException: TButton;
    memLog: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnTypesClick(Sender: TObject);
    procedure btnStepsClick(Sender: TObject);
    procedure btnLoopClick(Sender: TObject);
    procedure btnObjectClick(Sender: TObject);
    procedure btnExceptionClick(Sender: TObject);
    private
    FRunCount: Integer;
    procedure Report(const AText: string);
  end;

var
  FormDbgTest: TFormDbgTest;
  GlobalCount: Integer;          // после FormCreate: 7
  GlobalText: string;            // 'глобальная строка'
  GlobalCounter: TCounter;       // TCounter($...)

  implementation

  {$R *.dfm}

  // ---------------------------------------------------------------------------
  //  TCounter
  // ---------------------------------------------------------------------------

constructor TCounter.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
  FKind := ckGreen;
  FItems := [ckRed, ckBlue];
end;

procedure TCounter.Step(ADelta: Integer);
begin
  FCount := FCount + ADelta;          // ТОЧКА 5: FCount до шага, ADelta = 3
  if FCount > 10 then
    FKind := ckBlue;
end;

function TCounter.Total: Integer;
begin
  Result := FCount * 2;
end;

// ---------------------------------------------------------------------------
//  Процедуры проверки
// ---------------------------------------------------------------------------

procedure TestAllTypes(AForm: TFormDbgTest);
var
  IntVal: Integer;
  CardVal: Cardinal;
  ByteVal: Byte;
  ShortVal: ShortInt;
  WordVal: Word;
  Int64Val: Int64;
  CharVal: Char;
  WideVal: WideChar;
  BoolVal: Boolean;
  SingleVal: Single;
  DoubleVal: Double;
  ExtVal: Extended;
  CurrVal: Currency;
  AnsiVal: string;
  EmptyVal: string;
  ShortStr: ShortString;
  PCharVal: PChar;
  PtrVal: Pointer;
  RecVal: TPointRec;
  ArrVal: array[0..4] of Integer;
  EnumVal: TColorKind;
  SetVal: TColorSet;
  RangeVal: TSmallRange;
  ObjVal: TCounter;
  NilObj: TCounter;
  ClassVal: TClass;
  Marker: Integer;
begin
  IntVal := -12345;                    // -12345
  CardVal := 4000000000;               // 4000000000
  ByteVal := 200;                      // 200
  ShortVal := -100;                    // -100
  WordVal := 65000;                    // 65000
  Int64Val := 123456789012;            // 123456789012
  CharVal := 'Z';                      // 'Z'
  WideVal := 'W';                      // 'W'
  BoolVal := True;                     // True
  SingleVal := 1.5;                    // 1.5
  DoubleVal := 3.25;                   // 3.25
  ExtVal := 2.75;                      // 2.75
  CurrVal := 12.34;                    // 12.34 (Currency - может быть числом *10000)
  AnsiVal := 'Привет, отладчик';       // 'Привет, отладчик'
  EmptyVal := '';                      // ''
  ShortStr := 'короткая';              // 'короткая'
  PCharVal := 'строка PChar';          // 'строка PChar'
  PtrVal := @IntVal;                   // $ адрес
  RecVal.PosX := 10;                   // RecVal: (PosX: 10; PosY: 20;
  RecVal.PosY := 20;                   //   Title: 'точка'; Weight: 0.5)
  RecVal.Title := 'точка';
  RecVal.Weight := 0.5;
  ArrVal[0] := 1;                      // ArrVal: (1, 4, 9, 16, 25)
  ArrVal[1] := 4;
  ArrVal[2] := 9;
  ArrVal[3] := 16;
  ArrVal[4] := 25;
  EnumVal := ckBlue;                   // ckBlue
  SetVal := [ckRed, ckBlue];           // [ckRed, ckBlue]
  RangeVal := 42;                      // 42
  ObjVal := TCounter.Create('объект'); // TCounter($...)
  NilObj := nil;                       // nil
  ClassVal := TCounter;                // TCounter

  Marker := IntVal + ByteVal;          // ТОЧКА 1
  AForm.Report(Format('Типы: %d %s %s', [Marker, AnsiVal, ShortStr]));
  // %u: Cardinal больше MaxInt через %d вышел бы отрицательным
  AForm.Report(Format('%u %d %d %d', [CardVal, ShortVal, WordVal,
                      Int64Val]) + ' ' + CharVal + string(WideVal));
  if BoolVal and (PtrVal <> nil) and (NilObj = nil) and (ClassVal <> nil) and
     (EnumVal in SetVal) and (RangeVal > 0) and (PCharVal <> nil) and
     (EmptyVal = '') then
    AForm.Report(FloatToStr(SingleVal + DoubleVal + ExtVal + CurrVal +
                            RecVal.Weight + ArrVal[4]));
  ObjVal.Free;
end;

procedure WithVarParam(var AValue: Integer; const AText: string;
                       AObj: TCounter);
begin
  AValue := AValue + 1;                // F7 сюда: AValue = 41 до строки
  AObj.Step(1);
  if AText <> '' then
    AValue := AValue * 2;              // AValue = 84 после строки
end;

function Factorial(ANum: Integer): Integer;
begin
  if ANum <= 1 then
  begin
    Result := 1;
    Exit;
  end;
  Result := Factorial(ANum - 1);       // ТОЧКА 3: F8 - не вглубь рекурсии
  Result := Result * ANum;             // сюда же, ANum тот же
end;

procedure Outer(AForm: TFormDbgTest);
var
  OuterVar: Integer;

  procedure Inner;
  var
    InnerVar: Integer;
  begin
    InnerVar := 5;
    OuterVar := OuterVar + InnerVar;   // ТОЧКА 7: InnerVar = 5, OuterVar = 10 (15 после F8)
  end;

begin
  OuterVar := 10;
  Inner;
  AForm.Report('Outer: ' + IntToStr(OuterVar));   // 15
end;

// ---------------------------------------------------------------------------
//  Форма
// ---------------------------------------------------------------------------

procedure TFormDbgTest.FormCreate(Sender: TObject);
begin
  Tag := 77;
  GlobalCount := 7;
  GlobalText := 'глобальная строка';
  GlobalCounter := TCounter.Create('глобальный');
end;

procedure TFormDbgTest.FormDestroy(Sender: TObject);
begin
  FreeAndNil(GlobalCounter);
end;

procedure TFormDbgTest.Report(const AText: string);
begin
  memLog.Lines.Add(AText);
end;

procedure TFormDbgTest.btnTypesClick(Sender: TObject);
begin
  Inc(FRunCount);
  TestAllTypes(Self);
end;

//  2. Кнопка «Шаги и вызовы» -> ТОЧКА 2 в btnStepsClick.
//     F8 на строке с Factorial - вызов проходится целиком, следующая
//     строка. F7 на строке с WithVarParam - заход в процедуру; там в Watch
//     AValue (var-параметр, 41), AText, AObj. F8 до конца процедуры -
//     возврат в btnStepsClick. Рекурсия: ТОЧКА 3 в Factorial, F8 на строке
//     с вызовом Factorial(ANum - 1) - остановка на следующей строке того же
//     уровня, а не в глубине рекурсии.      
       
//  2. Кнопка «Шаги и вызовы» -> ТОЧКА 2 в btnStepsClick.
//     F8 на строке с Factorial - вызов проходится целиком, следующая
//     строка. F7 на строке с WithVarParam - заход в процедуру; там в Watch
//     AValue (var-параметр, 41), AText, AObj. F8 до конца процедуры -
//     возврат в btnStepsClick. Рекурсия: ТОЧКА 3 в Factorial, F8 на строке
//     с вызовом Factorial(ANum - 1) - остановка на следующей строке того же
//     уровня, а не в глубине рекурсии.

//  2. Кнопка «Шаги и вызовы» -> ТОЧКА 2 в btnStepsClick.
//     F8 на строке с Factorial - вызов проходится целиком, следующая
//     строка. F7 на строке с WithVarParam - заход в процедуру; там в Watch
//     AValue (var-параметр, 41), AText, AObj. F8 до конца процедуры -
//     возврат в btnStepsClick. Рекурсия: ТОЧКА 3 в Factorial, F8 на строке
//     с вызовом Factorial(ANum - 1) - остановка на следующей строке того же
//     уровня, а не в глубине рекурсии.            

//  2. Кнопка «Шаги и вызовы» -> ТОЧКА 2 в btnStepsClick.
//     F8 на строке с Factorial - вызов проходится целиком, следующая
//     строка. F7 на строке с WithVarParam - заход в процедуру; там в Watch
//     AValue (var-параметр, 41), AText, AObj. F8 до конца процедуры -
//     возврат в btnStepsClick. Рекурсия: ТОЧКА 3 в Factorial, F8 на строке
//     с вызовом Factorial(ANum - 1) - остановка на следующей строке того же
//     уровня, а не в глубине рекурсии.


procedure TFormDbgTest.btnStepsClick(Sender: TObject);
var
  FactValue, VarValue: Integer;
begin
  FactValue := 0;                      // ТОЧКА 2
  FactValue := Factorial(5);           // F8: следующая строка, FactValue = 120
  VarValue := 41;
  WithVarParam(VarValue, edtName.Text, GlobalCounter);   // F7: заход
  Report(Format('Шаги: %d %d', [FactValue, VarValue]));  // VarValue = 84
end;

procedure TFormDbgTest.btnLoopClick(Sender: TObject);
var
  Step, Sum: Integer;
begin
  Sum := 0;                            // ТОЧКА 4
  for Step := 1 to 100 do
    Sum := Sum + Step;                 // внутри цикла: F4 сюда
  Report('Цикл: ' + IntToStr(Sum));    // ПОСЛЕ ЦИКЛА: F4 сюда, Sum = 5050
end;

procedure TFormDbgTest.btnObjectClick(Sender: TObject);
var
  Counter: TCounter;
begin
  Counter := TCounter.Create(edtName.Text);
  try
    Counter.Step(3);                   // ТОЧКА 6: Tag, edtName, Self, Counter.FName
    Counter.Step(10);
    Report('Объект: ' + IntToStr(Counter.Total));   // 26
    Outer(Self);
  finally
    Counter.Free;
  end;
end;

procedure TFormDbgTest.btnExceptionClick(Sender: TObject);
var
  Value: Integer;
begin
  Value := 1;                          // ТОЧКА 8
  try
    if Value > 0 then
      raise EDbgTest.Create('проверочное исключение');
    Value := 2;
  except
    on E: EDbgTest do
      Report('Исключение: ' + E.Message);   // ТОЧКА 9: E - EDbgTest($...)
  end;
  Report('После исключения: ' + IntToStr(Value));   // 1
end;

end.

