unit DsgClassDesc;

// ---------------------------------------------------------------------------
//  Описание классов палитры Delphi 7 как данные (план портирования, шаг 0.8)
//
//  Инспектор и конструктор форм берут сведения о классах Delphi из RTTI
//  живых классов VCL: список свойств и их типы, значения перечислений,
//  события и их объявления, умолчания, текст нового компонента. В сборке
//  Lazarus классов VCL нет, а одноимённые классы LCL отличаются, поэтому
//  те же сведения хранятся в файле. Файл записывает Delphi 7-сборка unIDE
//  (DsgClassDescW, пункт меню View), Lazarus-сборка его только читает.
//
//  Модуль без VCL/LCL и без TypInfo: только данные и запросы к ним.
//
//  Формат файла - строки "ключ значение":
//    class TButton                 начало класса
//    parents TButtonControl ...    предки по порядку, до TObject
//    unit StdCtrls                 модуль класса
//    page Standard                 страница палитры ('' - не с палитры)
//    prop Caption TCaption w       свойство: имя, тип, w - есть запись
//    default Width=75              умолчание, как его записал бы .dfm
//    new object Button1: TButton   строка текста нового компонента
//    end                           конец класса
//    type TAlign enum 0 6 alNone alTop ...
//    type TAnchors set TAnchorKind
//    type TColor integer -2147483648 2147483647
//    type TCaption string
//    type TFont class
//    type TNotifyEvent method procedure|Sender: TObject|
//  Одноимённые типы из разных модулей (TTabStyle в Tabs и ComCtrls) - с
//  ~2, ~3 после имени: type TTabStyle~2 enum ...; prop Style TTabStyle~2 w.
//  Строки, начинающиеся с ';', и пустые - пропускаются.
// ---------------------------------------------------------------------------

interface

uses
  Classes, SysUtils;

const
  // Место, с которым записан текст нового компонента; при выдаче
  // заменяется на настоящее (NewObjectText). Имя - DsgDescNewName.
  DsgDescNewLeft = 1013;
  DsgDescNewTop = 1019;

  DsgDescFileName = 'delphi7_classes.txt';

type
  TDsgTypeKind = (dtkOther, dtkInteger, dtkChar, dtkWChar, dtkEnum,
                  dtkFloat, dtkString, dtkSet, dtkClass, dtkMethod,
                  dtkInt64, dtkVariant);

  TDsgTypeDesc = class
  public
    Key: string;                // имя в файле: TTabStyle, TTabStyle~2
    Name: string;               // имя типа: TTabStyle
    Tag: Pointer;               // для записи: откуда взят (PTypeInfo), в файл не идёт
    Kind: TDsgTypeKind;
    MinValue: Int64;            // целые и перечисления
    MaxValue: Int64;
    Values: TStringList;        // имена значений перечисления по порядку
    ElemType: string;           // набор - тип элемента
    MethodKind: string;         // событие - 'procedure' или 'function'
    MethodParams: string;       // "Sender: TObject; var Key: Word"
    MethodResult: string;       // тип результата функции
    constructor Create;
    destructor Destroy; override;
    // Номер значения перечисления по имени без учёта регистра; -1 - нет
    function ValueIndex(const AName: string): Integer;
  end;

  TDsgPropDesc = class
  public
    Name: string;
    TypeName: string;           // ключ типа (TDsgTypeDesc.Key)
    Writable: Boolean;
  end;

  TDsgClassDesc = class
  public
    Name: string;
    ModuleName: string;
    Page: string;
    Parents: TStringList;       // предки от ближнего к TObject
    Props: TStringList;         // имя -> TDsgPropDesc, порядок как в RTTI
    Defaults: TStringList;      // Имя=значение
    NewText: TStringList;       // object Button1: TButton ... end
    constructor Create;
    destructor Destroy; override;
    function FindProp(const AName: string): TDsgPropDesc;
  end;

  TDsgClassBase = class
  private
    FClasses: TStringList;      // по имени, без учёта регистра
    FTypes: TStringList;
    FOrder: TStringList;        // классы в порядке добавления
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;

    function AddClass(const AName: string): TDsgClassDesc;
    // AKey - имя типа, у второго одноимённого из другого модуля -
    // с ~2 и т.д.: TTabStyle в Tabs и в ComCtrls - разные типы
    function AddType(const AKey: string): TDsgTypeDesc;
    function FindClass(const AName: string): TDsgClassDesc;
    function FindType(const AKey: string): TDsgTypeDesc;
    function ClassCount: Integer;
    function ClassAt(AIndex: Integer): TDsgClassDesc;
    function TypeCount: Integer;
    function TypeAt(AIndex: Integer): TDsgTypeDesc;

    procedure SaveToStrings(AOut: TStrings);
    procedure SaveToFile(const AFile: string);
    // False - файла нет или в нём ошибка; AError - строка и причина
    function LoadFromStrings(ASrc: TStrings; var AError: string): Boolean;
    function LoadFromFile(const AFile: string; var AError: string): Boolean;

    // AClass - это AAncestor или его потомок
    function InheritsFromName(const AClass, AAncestor: string): Boolean;
    // Тип свойства по пути "Font.Style"; nil - нет такого свойства.
    // AWritable - у свойства есть запись.
    function PropType(const AClass, APath: string;
                      var AWritable: Boolean): TDsgTypeDesc;
    // События класса по алфавиту
    procedure EventNames(const AClass: string; AList: TStrings);
    // Событие для двойного щелчка: OnCreate, OnChange, OnClick, иначе
    // первое по алфавиту; '' - событий нет
    function DefaultEvent(const AClass: string): string;
    // "procedure Button1Click(Sender: TObject);"; '' - нет события
    function EventDecl(const AClass, AEvent, AMethod: string): string;
    // Текст object ... end нового компонента с именем и местом; '' - нет.
    // Свойства-даты (TDate, TTime, TDateTime - Date у TDateTimePicker)
    // получают текущее время, как у Delphi при установке компонента.
    function NewObjectText(const AClass, AName: string; X, Y: Integer): string;
    // Свойство AProp класса - дата или время
    function IsDateProp(const AClass, AProp: string): Boolean;
    // Значения свойств-дат в тексте object ... end заменены на "(дата)":
    // для сверки текстов, записанных в разное время
    function MaskDateLines(const AClass, AText: string): string;
  end;

function DsgTypeKindName(AKind: TDsgTypeKind): string;

// Имя типа по ключу: TTabStyle~2 -> TTabStyle
function DsgTypePlainName(const AKey: string): string;

// Имя, с которым записан текст нового компонента: класс без T и 1, как
// первое имя у DsgInsert (Button1). Такое же по длине, как обычное имя, -
// у TLabel с AutoSize от длины подписи зависит ширина.
function DsgDescNewName(const AClass: string): string;

implementation

function DsgTypePlainName(const AKey: string): string;
var
  MarkPos: Integer;
begin
  Result := AKey;
  MarkPos := Pos('~', Result);
  if MarkPos > 0 then
    Result := Copy(Result, 1, MarkPos - 1);
end;

function DsgDescNewName(const AClass: string): string;
begin
  Result := AClass;
  if (Length(Result) > 1) and (UpCase(Result[1]) = 'T') then
    Delete(Result, 1, 1);
  Result := Result + '1';
end;

const
  KindNames: array[TDsgTypeKind] of string = (
    'other', 'integer', 'char', 'wchar', 'enum', 'float', 'string', 'set',
    'class', 'method', 'int64', 'variant');

function DsgTypeKindName(AKind: TDsgTypeKind): string;
begin
  Result := KindNames[AKind];
end;

function KindOfName(const AName: string; var AKind: TDsgTypeKind): Boolean;
var
  KindIdx: TDsgTypeKind;
begin
  Result := False;
  for KindIdx := Low(TDsgTypeKind) to High(TDsgTypeKind) do
    if KindNames[KindIdx] = AName then
    begin
      AKind := KindIdx;
      Result := True;
      Exit;
    end;
end;

// Первое слово строки (до пробела) и остаток после одного пробела
procedure SplitWord(const ALine: string; var AWord, ARest: string);
var
  SpacePos: Integer;
begin
  SpacePos := Pos(' ', ALine);
  if SpacePos = 0 then
  begin
    AWord := ALine;
    ARest := '';
  end
  else
  begin
    AWord := Copy(ALine, 1, SpacePos - 1);
    ARest := Copy(ALine, SpacePos + 1, MaxInt);
  end;
end;

// Слова через пробел - в список
procedure SplitWords(const AText: string; AList: TStrings);
var
  Rest, Item: string;
begin
  AList.Clear;
  Rest := Trim(AText);
  while Rest <> '' do
  begin
    SplitWord(Rest, Item, Rest);
    Rest := TrimLeft(Rest);
    if Item <> '' then
      AList.Add(Item);
  end;
end;

// Порядок имён как у GetPropList: CompareText
function CompareNames(AList: TStringList; AFirst, ASecond: Integer): Integer;
begin
  Result := CompareText(AList[AFirst], AList[ASecond]);
end;

function NewSortedList: TStringList;
begin
  Result := TStringList.Create;
  Result.Sorted := True;
  Result.Duplicates := dupIgnore;
  Result.CaseSensitive := False;
end;

{ TDsgTypeDesc }

constructor TDsgTypeDesc.Create;
begin
  inherited Create;
  Values := TStringList.Create;
end;

destructor TDsgTypeDesc.Destroy;
begin
  Values.Free;
  inherited Destroy;
end;

function TDsgTypeDesc.ValueIndex(const AName: string): Integer;
var
  ValIdx: Integer;
begin
  Result := -1;
  for ValIdx := 0 to Values.Count - 1 do
    if CompareText(Values[ValIdx], AName) = 0 then
    begin
      Result := ValIdx;
      Exit;
    end;
end;

{ TDsgClassDesc }

constructor TDsgClassDesc.Create;
begin
  inherited Create;
  Parents := TStringList.Create;
  Props := TStringList.Create;
  Defaults := TStringList.Create;
  NewText := TStringList.Create;
end;

destructor TDsgClassDesc.Destroy;
var
  PropIdx: Integer;
begin
  for PropIdx := 0 to Props.Count - 1 do
    Props.Objects[PropIdx].Free;
  Props.Free;
  Parents.Free;
  Defaults.Free;
  NewText.Free;
  inherited Destroy;
end;

function TDsgClassDesc.FindProp(const AName: string): TDsgPropDesc;
var
  PropIdx: Integer;
begin
  Result := nil;
  for PropIdx := 0 to Props.Count - 1 do
    if CompareText(Props[PropIdx], AName) = 0 then
    begin
      Result := TDsgPropDesc(Props.Objects[PropIdx]);
      Exit;
    end;
end;

{ TDsgClassBase }

constructor TDsgClassBase.Create;
begin
  inherited Create;
  FClasses := NewSortedList;
  FTypes := NewSortedList;
  FOrder := TStringList.Create;
end;

destructor TDsgClassBase.Destroy;
begin
  Clear;
  FClasses.Free;
  FTypes.Free;
  FOrder.Free;
  inherited Destroy;
end;

procedure TDsgClassBase.Clear;
var
  ItemIdx: Integer;
begin
  for ItemIdx := 0 to FClasses.Count - 1 do
    FClasses.Objects[ItemIdx].Free;
  for ItemIdx := 0 to FTypes.Count - 1 do
    FTypes.Objects[ItemIdx].Free;
  FClasses.Clear;
  FTypes.Clear;
  FOrder.Clear;
end;

function TDsgClassBase.AddClass(const AName: string): TDsgClassDesc;
begin
  Result := FindClass(AName);
  if Result <> nil then
    Exit;
  Result := TDsgClassDesc.Create;
  Result.Name := AName;
  FClasses.AddObject(AName, Result);
  FOrder.AddObject(AName, Result);
end;

function TDsgClassBase.AddType(const AKey: string): TDsgTypeDesc;
begin
  Result := FindType(AKey);
  if Result <> nil then
    Exit;
  Result := TDsgTypeDesc.Create;
  Result.Key := AKey;
  Result.Name := DsgTypePlainName(AKey);
  FTypes.AddObject(AKey, Result);
end;

function TDsgClassBase.FindClass(const AName: string): TDsgClassDesc;
var
  ItemIdx: Integer;
begin
  Result := nil;
  if FClasses.Find(AName, ItemIdx) then
    Result := TDsgClassDesc(FClasses.Objects[ItemIdx]);
end;

function TDsgClassBase.FindType(const AKey: string): TDsgTypeDesc;
var
  ItemIdx: Integer;
begin
  Result := nil;
  if FTypes.Find(AKey, ItemIdx) then
    Result := TDsgTypeDesc(FTypes.Objects[ItemIdx]);
end;

function TDsgClassBase.ClassCount: Integer;
begin
  Result := FOrder.Count;
end;

function TDsgClassBase.ClassAt(AIndex: Integer): TDsgClassDesc;
begin
  Result := TDsgClassDesc(FOrder.Objects[AIndex]);
end;

function TDsgClassBase.TypeCount: Integer;
begin
  Result := FTypes.Count;
end;

function TDsgClassBase.TypeAt(AIndex: Integer): TDsgTypeDesc;
begin
  Result := TDsgTypeDesc(FTypes.Objects[AIndex]);
end;

procedure TDsgClassBase.SaveToStrings(AOut: TStrings);
var
  ClsIdx, ItemIdx: Integer;
  Cls: TDsgClassDesc;
  Prop: TDsgPropDesc;
  Typ: TDsgTypeDesc;
  Line: string;
begin
  AOut.Clear;
  AOut.Add('; unIDE: описание классов Delphi 7 для инспектора и конструктора');
  AOut.Add('; форм. Записано Delphi 7-сборкой unIDE, View - "Описание классов');
  AOut.Add('; Delphi 7". Формат - в начале DsgClassDesc.pas.');
  for ClsIdx := 0 to ClassCount - 1 do
  begin
    Cls := ClassAt(ClsIdx);
    AOut.Add('');
    AOut.Add('class ' + Cls.Name);
    if Cls.Parents.Count > 0 then
    begin
      Line := 'parents';
      for ItemIdx := 0 to Cls.Parents.Count - 1 do
        Line := Line + ' ' + Cls.Parents[ItemIdx];
      AOut.Add(Line);
    end;
    if Cls.ModuleName <> '' then
      AOut.Add('unit ' + Cls.ModuleName);
    if Cls.Page <> '' then
      AOut.Add('page ' + Cls.Page);
    for ItemIdx := 0 to Cls.Props.Count - 1 do
    begin
      Prop := TDsgPropDesc(Cls.Props.Objects[ItemIdx]);
      Line := 'prop ' + Prop.Name + ' ' + Prop.TypeName;
      if Prop.Writable then
        Line := Line + ' w';
      AOut.Add(Line);
    end;
    for ItemIdx := 0 to Cls.Defaults.Count - 1 do
      AOut.Add('default ' + Cls.Defaults[ItemIdx]);
    for ItemIdx := 0 to Cls.NewText.Count - 1 do
      AOut.Add('new ' + Cls.NewText[ItemIdx]);
    AOut.Add('end');
  end;

  AOut.Add('');
  for ItemIdx := 0 to TypeCount - 1 do
  begin
    Typ := TypeAt(ItemIdx);
    Line := 'type ' + Typ.Key + ' ' + KindNames[Typ.Kind];
    case Typ.Kind of
      dtkInteger, dtkInt64:
        Line := Line + ' ' + IntToStr(Typ.MinValue) + ' ' +
                IntToStr(Typ.MaxValue);
      dtkEnum:
      begin
        Line := Line + ' ' + IntToStr(Typ.MinValue) + ' ' +
                IntToStr(Typ.MaxValue);
        for ClsIdx := 0 to Typ.Values.Count - 1 do
          Line := Line + ' ' + Typ.Values[ClsIdx];
      end;
      dtkSet:
        Line := Line + ' ' + Typ.ElemType;
      dtkMethod:
        Line := Line + ' ' + Typ.MethodKind + '|' + Typ.MethodParams + '|' +
                Typ.MethodResult;
    end;
    AOut.Add(Line);
  end;
end;

procedure TDsgClassBase.SaveToFile(const AFile: string);
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    SaveToStrings(Lines);
    Lines.SaveToFile(AFile);
  finally
    Lines.Free;
  end;
end;

function TDsgClassBase.LoadFromStrings(ASrc: TStrings;
  var AError: string): Boolean;
var
  LineIdx, BarPos: Integer;
  Line, Key, Rest, Name, Head: string;
  Cls: TDsgClassDesc;
  Typ: TDsgTypeDesc;
  Prop: TDsgPropDesc;
  Words: TStringList;
  Kind: TDsgTypeKind;
  LineNo: Integer;

  procedure Fail(const AWhy: string);
  begin
    AError := Format('строка %d: %s', [LineNo, AWhy]);
  end;

begin
  Result := False;
  AError := '';
  Clear;
  Cls := nil;
  Words := TStringList.Create;
  try
    for LineIdx := 0 to ASrc.Count - 1 do
    begin
      LineNo := LineIdx + 1;
      Line := ASrc[LineIdx];
      // Текст нового компонента - как есть, с ведущими пробелами
      if (Cls <> nil) and (Copy(Line, 1, 4) = 'new ') then
      begin
        Cls.NewText.Add(Copy(Line, 5, MaxInt));
        Continue;
      end;
      Line := TrimRight(Line);
      if (Line = '') or (Line[1] = ';') then
        Continue;
      SplitWord(Line, Key, Rest);

      if Key = 'class' then
      begin
        if Cls <> nil then
        begin
          Fail('нет end у класса ' + Cls.Name);
          Exit;
        end;
        Cls := AddClass(Trim(Rest));
      end
      else if Key = 'type' then
      begin
        SplitWords(Rest, Words);
        if (Words.Count < 2) or not KindOfName(Words[1], Kind) then
        begin
          Fail('не разобран тип');
          Exit;
        end;
        Typ := AddType(Words[0]);
        Typ.Kind := Kind;
        case Kind of
          dtkInteger, dtkInt64, dtkEnum:
          begin
            if Words.Count < 4 then
            begin
              Fail('у типа ' + Words[0] + ' нет границ');
              Exit;
            end;
            Typ.MinValue := StrToInt64Def(Words[2], 0);
            Typ.MaxValue := StrToInt64Def(Words[3], 0);
            if Kind = dtkEnum then
              while Words.Count > 4 do
              begin
                Typ.Values.Add(Words[4]);
                Words.Delete(4);
              end;
          end;
          dtkSet:
            if Words.Count > 2 then
              Typ.ElemType := Words[2];
          dtkMethod:
          begin
            // После вида - "procedure|параметры|результат" целиком
            SplitWord(Rest, Name, Rest);
            SplitWord(Rest, Head, Rest);
            BarPos := Pos('|', Rest);
            if BarPos = 0 then
            begin
              Fail('у события ' + Name + ' нет параметров');
              Exit;
            end;
            Typ.MethodKind := Copy(Rest, 1, BarPos - 1);
            Rest := Copy(Rest, BarPos + 1, MaxInt);
            BarPos := Pos('|', Rest);
            if BarPos = 0 then
              BarPos := Length(Rest) + 1;
            Typ.MethodParams := Copy(Rest, 1, BarPos - 1);
            Typ.MethodResult := Copy(Rest, BarPos + 1, MaxInt);
          end;
        end;
      end
      else if Cls = nil then
      begin
        Fail('"' + Key + '" вне класса');
        Exit;
      end
      else if Key = 'end' then
        Cls := nil
      else if Key = 'parents' then
        SplitWords(Rest, Cls.Parents)
      else if Key = 'unit' then
        Cls.ModuleName := Trim(Rest)
      else if Key = 'page' then
        Cls.Page := Trim(Rest)
      else if Key = 'prop' then
      begin
        SplitWords(Rest, Words);
        if Words.Count < 2 then
        begin
          Fail('у свойства нет типа');
          Exit;
        end;
        Prop := TDsgPropDesc.Create;
        Prop.Name := Words[0];
        Prop.TypeName := Words[1];
        Prop.Writable := (Words.Count > 2) and (Words[2] = 'w');
        Cls.Props.AddObject(Prop.Name, Prop);
      end
      else if Key = 'default' then
        Cls.Defaults.Add(Rest)
      else
      begin
        Fail('неизвестный ключ "' + Key + '"');
        Exit;
      end;
    end;
    if Cls <> nil then
    begin
      AError := 'нет end у класса ' + Cls.Name;
      Exit;
    end;
    Result := True;
  finally
    Words.Free;
  end;
end;

function TDsgClassBase.LoadFromFile(const AFile: string;
  var AError: string): Boolean;
var
  Lines: TStringList;
begin
  Result := False;
  Clear;
  if not FileExists(AFile) then
  begin
    AError := 'нет файла ' + AFile;
    Exit;
  end;
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(AFile);
    Result := LoadFromStrings(Lines, AError);
  finally
    Lines.Free;
  end;
end;

function TDsgClassBase.InheritsFromName(const AClass,
  AAncestor: string): Boolean;
var
  Cls: TDsgClassDesc;
begin
  Result := CompareText(AClass, AAncestor) = 0;
  if Result then
    Exit;
  Cls := FindClass(AClass);
  Result := (Cls <> nil) and (Cls.Parents.IndexOf(AAncestor) >= 0);
end;

function TDsgClassBase.PropType(const AClass, APath: string;
  var AWritable: Boolean): TDsgTypeDesc;
var
  Rest, Part: string;
  DotPos: Integer;
  Cls: TDsgClassDesc;
  Prop: TDsgPropDesc;
  Typ: TDsgTypeDesc;
begin
  Result := nil;
  AWritable := False;
  Cls := FindClass(AClass);
  Rest := APath;
  while (Cls <> nil) and (Rest <> '') do
  begin
    DotPos := Pos('.', Rest);
    if DotPos > 0 then
    begin
      Part := Copy(Rest, 1, DotPos - 1);
      Rest := Copy(Rest, DotPos + 1, MaxInt);
    end
    else
    begin
      Part := Rest;
      Rest := '';
    end;

    Prop := Cls.FindProp(Part);
    if Prop = nil then
      Exit;
    Typ := FindType(Prop.TypeName);
    if Rest = '' then
    begin
      Result := Typ;
      AWritable := Prop.Writable;
      Exit;
    end;
    // Середина пути - только вложенный объект (Font, Constraints)
    if (Typ = nil) or (Typ.Kind <> dtkClass) then
      Exit;
    Cls := FindClass(Typ.Name);
  end;
end;

procedure TDsgClassBase.EventNames(const AClass: string; AList: TStrings);
var
  Cls: TDsgClassDesc;
  Typ: TDsgTypeDesc;
  PropIdx: Integer;
  Sorted: TStringList;
begin
  AList.Clear;
  Cls := FindClass(AClass);
  if Cls = nil then
    Exit;
  Sorted := TStringList.Create;
  try
    for PropIdx := 0 to Cls.Props.Count - 1 do
    begin
      Typ := FindType(TDsgPropDesc(Cls.Props.Objects[PropIdx]).TypeName);
      if (Typ <> nil) and (Typ.Kind = dtkMethod) then
        Sorted.Add(Cls.Props[PropIdx]);
    end;
    Sorted.CustomSort(CompareNames);
    AList.Assign(Sorted);
  finally
    Sorted.Free;
  end;
end;

function TDsgClassBase.DefaultEvent(const AClass: string): string;
const
  Pref: array[0..2] of string = ('OnCreate', 'OnChange', 'OnClick');
var
  PrefIdx: Integer;
  Events: TStringList;
begin
  Result := '';
  Events := TStringList.Create;
  try
    EventNames(AClass, Events);
    for PrefIdx := Low(Pref) to High(Pref) do
      if Events.IndexOf(Pref[PrefIdx]) >= 0 then
      begin
        Result := Pref[PrefIdx];
        Exit;
      end;
    if Events.Count > 0 then
      Result := Events[0];
  finally
    Events.Free;
  end;
end;

function TDsgClassBase.EventDecl(const AClass, AEvent,
  AMethod: string): string;
var
  Writable: Boolean;
  Typ: TDsgTypeDesc;
begin
  Result := '';
  Typ := PropType(AClass, AEvent, Writable);
  if (Typ = nil) or (Typ.Kind <> dtkMethod) then
    Exit;
  if Typ.MethodKind = 'function' then
    Result := 'function ' + AMethod
  else
    Result := 'procedure ' + AMethod;
  if Typ.MethodParams <> '' then
    Result := Result + '(' + Typ.MethodParams + ')';
  if Typ.MethodKind = 'function' then
    Result := Result + ': ' + Typ.MethodResult;
  Result := Result + ';';
end;

// Имя свойства из строки "  Date = 46327.17" верхнего уровня объекта;
// '' - строка не такая
function DateLineProp(const ALine: string): string;
var
  EqPos: Integer;
begin
  Result := '';
  if (Length(ALine) < 3) or (Copy(ALine, 1, 2) <> '  ') or
     (ALine[3] = ' ') then
    Exit;
  EqPos := Pos(' = ', ALine);
  if EqPos > 0 then
    Result := Trim(Copy(ALine, 1, EqPos - 1));
end;

// Дата числом, как в .dfm: дробная часть через точку
function DateText(AValue: TDateTime): string;
var
  CharIdx: Integer;
begin
  Result := FloatToStr(AValue);
  for CharIdx := 1 to Length(Result) do
    if Result[CharIdx] = ',' then
      Result[CharIdx] := '.';
end;

function TDsgClassBase.IsDateProp(const AClass, AProp: string): Boolean;
var
  Cls: TDsgClassDesc;
  Prop: TDsgPropDesc;
  TypeName: string;
begin
  Result := False;
  if AProp = '' then
    Exit;
  Cls := FindClass(AClass);
  if Cls = nil then
    Exit;
  Prop := Cls.FindProp(AProp);
  if Prop = nil then
    Exit;
  TypeName := DsgTypePlainName(Prop.TypeName);
  Result := (CompareText(TypeName, 'TDate') = 0) or
            (CompareText(TypeName, 'TTime') = 0) or
            (CompareText(TypeName, 'TDateTime') = 0);
end;

function TDsgClassBase.MaskDateLines(const AClass, AText: string): string;
var
  Lines: TStringList;
  LineIdx: Integer;
  PropName: string;
begin
  Lines := TStringList.Create;
  try
    Lines.Text := AText;
    for LineIdx := 0 to Lines.Count - 1 do
    begin
      PropName := DateLineProp(Lines[LineIdx]);
      if IsDateProp(AClass, PropName) then
        Lines[LineIdx] := '  ' + PropName + ' = (дата)';
    end;
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

function TDsgClassBase.NewObjectText(const AClass, AName: string;
  X, Y: Integer): string;
var
  Cls: TDsgClassDesc;
  Lines: TStringList;
  LineIdx: Integer;
  Line: string;
begin
  Result := '';
  Cls := FindClass(AClass);
  if (Cls = nil) or (Cls.NewText.Count = 0) then
    Exit;
  Lines := TStringList.Create;
  try
    for LineIdx := 0 to Cls.NewText.Count - 1 do
    begin
      Line := Cls.NewText[LineIdx];
      if IsDateProp(AClass, DateLineProp(Line)) then
        Line := '  ' + DateLineProp(Line) + ' = ' + DateText(Now)
      else if Line = '  Left = ' + IntToStr(DsgDescNewLeft) then
        Line := '  Left = ' + IntToStr(X)
      else if Line = '  Top = ' + IntToStr(DsgDescNewTop) then
        Line := '  Top = ' + IntToStr(Y)
      else
        Line := StringReplace(Line, DsgDescNewName(AClass), AName,
                              [rfReplaceAll]);
      Lines.Add(Line);
    end;
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

end.
