unit RqComponents;

// ---------------------------------------------------------------------------
//  Описание компонентов RapidQ из файла ComponentAll.data (Component.data)
//
//  Формат файла (текст, по строке на запись):
//    # <номер> <КЛАСС> [EXTENDS <БАЗОВЫЙ>] * Properties * [примечание]
//                                                      - начало класса
//    '@source <файл> <строка>                          - где объявлен класс
//                                                        TYPE ... EXTENDS
//    Имя|ТИП|доступ|по умолчанию|вариант1|вариант2...  - свойство
//    * Methods                                         - дальше методы:
//    Имя|ТИП|доступ|аргументы
//    * Events                                          - дальше события:
//    Имя||(параметры)
//    * Defaults                                        - дальше значения
//    Имя=значение                                        по умолчанию из
//                                                        CONSTRUCTOR, и для
//                                                        свойств базового
//    * Constants                                       - после всех классов:
//    Имя=значение                                        константы RAPIDQ.INC
//                                                        (alBottom=2) - для
//                                                        перечислений, когда
//                                                        у варианта значения
//                                                        нет
//  Доступ: R - только чтение, W - только запись, RW - оба. Варианты - для
//  перечислений и логических (False|True); вариант бывает со значением:
//  bsSizeable=2, crHandPoint=-21 (из RAPIDQ.INC). <default> и <choose> у
//  цвета - "по умолчанию" и "выбрать". Строка из одного # - конец файла.
//  Строки, которые начинаются с ', - комментарии: до первого класса -
//  комментарии файла, после записи - её, после заголовка - класса. При
//  записи файла (RqSaveComponents) они сохраняются на своих местах.
//
//  Строки без | и записи, у которых имя не идентификатор (пояснения вроде
//  "NO Properties!||R|"), пропускаются.
//
//  Файлов бывает несколько редакций (Component.data, Component1.data): у
//  одной есть классы меню, у другой - DirectX. Основной загружается
//  RqLoadComponents, остальные добавляются RqMergeComponents - только
//  классы и члены классов, которых ещё нет; уже загруженное не меняется.
//
//  Классы программы - TYPE <Имя> EXTENDS <Базовый> ... END TYPE в её
//  исходнике и include-файлах - разбирает RqParseTypes:
//    поле "Имя AS Тип [PROPERTY SET Setter]"      - свойство (RW);
//    поле "OnX AS EVENT(Шаблон)"                  - новое событие;
//    SUB, SUBI, FUNCTION, FUNCTIONI               - методы;
//    присваивания в CONSTRUCTOR                   - значения по умолчанию
//                                                   (и для свойств базового);
//    PRIVATE: ... до PUBLIC: - не показывается; тела PROPERTY SET, EVENT
//    (обработчики событий базового класса) и DESTRUCTOR пропускаются,
//    WITH This ... END WITH - прозрачно.
//  Свойства такого класса - свои плюс всех базовых по цепочке
//  (RqClassChain).
//
//  Константы программы - CONST Имя = целое (RAPIDQ.INC: bsSizeable = 2,
//  crHandPoint = -21) - собирает RqParseConsts. По ним RqChoiceText
//  показывает число из снимка словом из списка вариантов свойства:
//  BorderStyle 2 -> bsSizeable.
//
//  Модуль самостоятельный: загрузка, поиск класса по имени, освобождение.
// ---------------------------------------------------------------------------

interface

uses
  Classes;

type
  // Свойство или метод
  TRqMember = class
  public
    Name, TypeName, Access: string;
    DefValue: string;    // свойство: значение по умолчанию; метод: аргументы
    Choices: TStringList;  // допустимые значения (пусто - любые); с числом -
                           // "bsSizeable=2"
    Comment: string;       // строки-комментарии после записи (#13#10 между)
    constructor Create;
    destructor Destroy; override;
    function CanRead: Boolean;
    function CanWrite: Boolean;
  end;

  TRqEvent = class
  public
    Name, Params: string;   // Params - "(Key AS WORD, Shift AS INTEGER)"
    Comment: string;        // строки-комментарии после записи
  end;

  TRqClass = class
  public
    Name: string;
    Num: Integer;          // номер класса в файле
    Note: string;          // примечание в строке заголовка
    Props, Methods, Events: TStringList;   // Objects - TRqMember / TRqEvent
    // Класс программы (TYPE ... EXTENDS): базовый, где объявлен, значения
    // по умолчанию из CONSTRUCTOR ("Height=26")
    IsCustom: Boolean;
    BaseName: string;
    SrcFile: string;
    SrcLine: Integer;       // строка TYPE, от нуля
    Defaults: TStringList;
    Comments: TStringList;  // строки-комментарии после заголовка
    constructor Create;
    destructor Destroy; override;
    function PropOf(const AName: string): TRqMember;
    function EventOf(const AName: string): TRqEvent;
  end;

// Загрузить описание из AFile (прежнее освобождается). Результат - число
// классов; файла нет или не читается - 0.
function RqLoadComponents(const AFile: string): Integer;
// Добавить из AFile классы, которых нет, и свойства, методы, события, которых
// нет у уже загруженных классов. Результат - число добавленных классов,
// AMembers - число членов, добавленных к прежним классам.
function RqMergeComponents(const AFile: string; var AMembers: Integer): Integer;
// Класс по имени без учёта регистра: сначала классы программы, потом
// описание из файла; nil - нет такого
function RqFindClass(const AName: string): TRqClass;
// Классы программы: TYPE ... EXTENDS из текста ALines файла AFile. Класс,
// который уже есть среди классов программы, второй раз не добавляется.
// Результат - число добавленных.
function RqParseTypes(ALines: TStrings; const AFile: string): Integer;
procedure RqClearCustom;
function RqCustomCount: Integer;
// Константы: CONST Имя = целое (десятичное или &H) из текста ALines.
// Константа, которая уже есть, не меняется. Результат - число добавленных.
function RqParseConsts(ALines: TStrings): Integer;
procedure RqClearConsts;
function RqConstCount: Integer;
function RqConstValue(const AName: string; var AValue: Integer): Boolean;
// Константы программы (RqParseConsts) - и в описание, раздел * Constants:
// сборка ComponentAll.data
procedure RqKeepConstsInData;
// Имена констант с приставкой APrefix и заглавной буквой после неё
// (cl -> clRed, clBtnFace), из программы и из описания, по алфавиту
procedure RqConstNames(const APrefix: string; AList: TStrings);
// Значение свойства AMember словом из его вариантов: AValue - число из
// снимка. Варианта с таким значением нет, или у свойства нет вариантов
// перечисления - AValue как есть. Значение варианта - константа программы
// (RqParseConsts); ни одной константы из вариантов не найдено - номер
// варианта в списке. False|True - 0 и не 0. Среди вариантов значения нет
// (у QSPLITTER в Align только alTop|alLeft) - константа с той же
// приставкой из строчных букв (al) и тем же значением, если она одна.
function RqChoiceText(AMember: TRqMember; const AValue: string): string;
// Класс и его базовые до корня - в AChain (первый - сам класс). Цикл и
// неизвестный базовый обрывают цепочку.
procedure RqClassChain(const AName: string; AChain: TList);
// Имя варианта без значения: "bsSizeable=2" -> bsSizeable
function RqChoiceName(const AChoice: string): string;
// Записать загруженное описание в AFile в том же формате
procedure RqSaveComponents(const AFile: string);
// Классы программы (RqParseTypes) - вызывающему: список "имя - класс",
// владеет им вызывающий; у модуля список становится пустым
function RqTakeCustom: TStringList;
// Класс - в описание (после загруженных). Класс с таким именем уже есть -
// False, класс не берётся.
function RqAddClass(AClass: TRqClass): Boolean;
// Комментарии файла - строки до первого класса
function RqHeaderComments: TStringList;
// Убрать из описания классы TYPE ... EXTENDS (перед их новой сборкой)
procedure RqDropCustomClasses;
// Значение по умолчанию свойства AName по цепочке: CONSTRUCTOR ближайшего
// класса, иначе запись описания. AMember - найденная запись (nil - нет).
function RqDefaultOf(AChain: TList; const AName: string;
                     var AMember: TRqMember): string;
function RqClassCount: Integer;
function RqClassAt(AIndex: Integer): TRqClass;
procedure RqFreeComponents;

var
  RqComponentFile: string = '';   // основной файл, '' - не загружено
  RqMergedFiles: string = '';     // добавленные к нему, через "; "

implementation

uses
  SysUtils;

var
  RqClasses: TStringList = nil;   // имена классов, Objects - TRqClass
  RqFileComments: TStringList = nil;   // комментарии до первого класса
  RqCustom: TStringList = nil;    // классы программы, Objects - TRqClass
  RqConsts: TStringList = nil;    // константы программы, Objects - значение
  RqDataConsts: TStringList = nil;   // константы из описания (* Constants)

constructor TRqMember.Create;
begin
  inherited Create;
  Choices := TStringList.Create;
end;

destructor TRqMember.Destroy;
begin
  Choices.Free;
  inherited Destroy;
end;

function TRqMember.CanRead: Boolean;
begin
  Result := Pos('R', UpperCase(Access)) > 0;
end;

function TRqMember.CanWrite: Boolean;
begin
  Result := Pos('W', UpperCase(Access)) > 0;
end;

constructor TRqClass.Create;
begin
  inherited Create;
  Props := TStringList.Create;
  Methods := TStringList.Create;
  Events := TStringList.Create;
  Defaults := TStringList.Create;
  Comments := TStringList.Create;
  SrcLine := -1;
end;

destructor TRqClass.Destroy;
var
  ItemIdx: Integer;
begin
  for ItemIdx := 0 to Props.Count - 1 do
    Props.Objects[ItemIdx].Free;
  for ItemIdx := 0 to Methods.Count - 1 do
    Methods.Objects[ItemIdx].Free;
  for ItemIdx := 0 to Events.Count - 1 do
    Events.Objects[ItemIdx].Free;
  Comments.Free;
  Defaults.Free;
  Events.Free;
  Methods.Free;
  Props.Free;
  inherited Destroy;
end;

function TRqClass.PropOf(const AName: string): TRqMember;
var
  ItemIdx: Integer;
begin
  ItemIdx := Props.IndexOf(AName);
  if ItemIdx >= 0 then
    Result := TRqMember(Props.Objects[ItemIdx])
  else
    Result := nil;
end;

function TRqClass.EventOf(const AName: string): TRqEvent;
var
  ItemIdx: Integer;
begin
  ItemIdx := Events.IndexOf(AName);
  if ItemIdx >= 0 then
    Result := TRqEvent(Events.Objects[ItemIdx])
  else
    Result := nil;
end;

procedure RqFreeComponents;
var
  ClassIdx: Integer;
begin
  if RqClasses <> nil then
  begin
    for ClassIdx := 0 to RqClasses.Count - 1 do
      RqClasses.Objects[ClassIdx].Free;
    FreeAndNil(RqClasses);
  end;
  if RqFileComments <> nil then
    RqFileComments.Clear;
  if RqDataConsts <> nil then
    RqDataConsts.Clear;
  RqComponentFile := '';
  RqMergedFiles := '';
end;

// Поля строки через |
procedure SplitBars(const ALine: string; AFields: TStrings);
var
  Rest: string;
  BarPos: Integer;
begin
  AFields.Clear;
  Rest := ALine;
  BarPos := Pos('|', Rest);
  while BarPos > 0 do
  begin
    AFields.Add(Trim(Copy(Rest, 1, BarPos - 1)));
    Delete(Rest, 1, BarPos);
    BarPos := Pos('|', Rest);
  end;
  AFields.Add(Trim(Rest));
end;

// Имя члена класса - идентификатор, возможно с точкой (Field.Name у
// QMYSQL). Запись вроде "NO Properties!||R|" (у
// QOLEOBJECT в Component1.data) - пояснение, не свойство.
function IsIdent(const AName: string): Boolean;
var
  CharIdx: Integer;
begin
  Result := AName <> '';
  for CharIdx := 1 to Length(AName) do
    if not (AName[CharIdx] in ['A'..'Z', 'a'..'z', '0'..'9', '_', '.']) then
    begin
      Result := False;
      Exit;
    end;
end;

// Заголовок класса "# 6 QOVALBTN * Properties  примечание *"
function ParseHeader(const ALine: string; AClass: TRqClass): Boolean;
const
  PropMark = 'Properties';
var
  Rest, NumText: string;
  CharIdx: Integer;
begin
  Result := False;
  Rest := Trim(Copy(ALine, 2, MaxInt));
  CharIdx := 1;
  while (CharIdx <= Length(Rest)) and (Rest[CharIdx] in ['0'..'9']) do
    Inc(CharIdx);
  NumText := Copy(Rest, 1, CharIdx - 1);
  if NumText = '' then
    Exit;
  Rest := Trim(Copy(Rest, CharIdx, MaxInt));
  CharIdx := 1;
  while (CharIdx <= Length(Rest)) and (Rest[CharIdx] > ' ') do
    Inc(CharIdx);
  AClass.Name := Copy(Rest, 1, CharIdx - 1);
  if AClass.Name = '' then
    Exit;
  AClass.Num := StrToIntDef(NumText, -1);
  Rest := Trim(Copy(Rest, CharIdx, MaxInt));
  // "EXTENDS Базовый" - класс, объявленный TYPE ... EXTENDS
  if CompareText(Copy(Rest, 1, 8), 'EXTENDS ') = 0 then
  begin
    Rest := Trim(Copy(Rest, 9, MaxInt));
    CharIdx := 1;
    while (CharIdx <= Length(Rest)) and (Rest[CharIdx] > ' ') do
      Inc(CharIdx);
    AClass.BaseName := Copy(Rest, 1, CharIdx - 1);
    AClass.IsCustom := AClass.BaseName <> '';
    Rest := Trim(Copy(Rest, CharIdx, MaxInt));
  end;
  // Примечание - всё после имени без метки "* Properties" и звёздочек
  while (Rest <> '') and (Rest[1] in ['*', ' ']) do
    Delete(Rest, 1, 1);
  if CompareText(Copy(Rest, 1, Length(PropMark)), PropMark) = 0 then
    Delete(Rest, 1, Length(PropMark));
  while (Rest <> '') and (Rest[1] in ['*', ' ', '-']) do
    Delete(Rest, 1, 1);
  while (Rest <> '') and (Rest[Length(Rest)] in ['*', ' ']) do
    Delete(Rest, Length(Rest), 1);
  AClass.Note := Rest;
  Result := True;
end;

// Целое из текста: "2", "-21", "&H8000000F". False - не целое.
function ParseBasicInt(const AText: string; var AValue: Integer): Boolean;
var
  Txt: string;
  Negative: Boolean;
  CharIdx, Digit: Integer;
  Acc: Int64;
begin
  Result := False;
  Txt := Trim(AText);
  Negative := (Txt <> '') and (Txt[1] = '-');
  if Negative then
    Txt := Trim(Copy(Txt, 2, MaxInt));
  if Txt = '' then
    Exit;
  Acc := 0;
  if UpperCase(Copy(Txt, 1, 2)) = '&H' then
  begin
    if Length(Txt) = 2 then
      Exit;
    for CharIdx := 3 to Length(Txt) do
    begin
      case Txt[CharIdx] of
        '0'..'9': Digit := Ord(Txt[CharIdx]) - Ord('0');
        'A'..'F': Digit := Ord(Txt[CharIdx]) - Ord('A') + 10;
        'a'..'f': Digit := Ord(Txt[CharIdx]) - Ord('a') + 10;
      else
        Exit;
      end;
      Acc := Acc * 16 + Digit;
      if Acc > $FFFFFFFF then
        Exit;
    end;
    // &H8000000F - 32 бита со знаком, как у LONG
    if Acc > $7FFFFFFF then
      Acc := Acc - $100000000;
  end
  else
    for CharIdx := 1 to Length(Txt) do
    begin
      if not (Txt[CharIdx] in ['0'..'9']) then
        Exit;
      Acc := Acc * 10 + Ord(Txt[CharIdx]) - Ord('0');
      if Acc > $7FFFFFFF then
        Exit;
    end;
  if Negative then
    Acc := -Acc;
  AValue := Integer(Acc);
  Result := True;
end;

// Разбор файла. AMerge = False - в пустой список; True - к загруженному:
// существующий класс дополняется недостающими членами. Результат - число
// добавленных классов, AMembers - число членов, добавленных к прежним.
function LoadComponentFile(const AFile: string; AMerge: Boolean;
                           var AMembers: Integer): Integer;
const
  SectProps = 0;
  SectMethods = 1;
  SectEvents = 2;
  SectDefaults = 3;
  SectConsts = 4;
  SourceTag = '''@source ';
var
  Lines, Fields: TStringList;
  LineIdx, FieldIdx, Section, ClassIdx, SpacePos, EqPos, ConstValue: Integer;
  Line, SrcText: string;
  CurClass, Header: TRqClass;
  OldClass: Boolean;   // CurClass был загружен раньше - члены только новые
  Member, LastMember: TRqMember;
  Event, LastEvent: TRqEvent;
  Target: TStringList;
begin
  Result := 0;
  AMembers := 0;
  if (AFile = '') or not FileExists(AFile) then
    Exit;
  if RqClasses = nil then
  begin
    RqClasses := TStringList.Create;
    RqClasses.CaseSensitive := False;
  end;
  Lines := TStringList.Create;
  Fields := TStringList.Create;
  try
    try
      Lines.LoadFromFile(AFile);
    except
      Exit;
    end;
    CurClass := nil;
    OldClass := False;
    LastMember := nil;
    LastEvent := nil;
    Section := SectProps;
    if RqFileComments = nil then
      RqFileComments := TStringList.Create;
    for LineIdx := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[LineIdx]);
      if Line = '' then
        Continue;
      // Комментарий: до классов - файла; '@source - где объявлен класс;
      // после записи - её; после заголовка - класса. При дополнении
      // (AMerge) комментарии не берутся.
      if Line[1] = '''' then
      begin
        if AMerge then
          Continue;
        if CurClass = nil then
          RqFileComments.Add(Line)
        else if CompareText(Copy(Line, 1, Length(SourceTag)), SourceTag) = 0 then
        begin
          SrcText := Trim(Copy(Line, Length(SourceTag) + 1, MaxInt));
          SpacePos := LastDelimiter(' ', SrcText);
          if SpacePos > 0 then
          begin
            CurClass.SrcFile := Trim(Copy(SrcText, 1, SpacePos - 1));
            CurClass.SrcLine := StrToIntDef(Copy(SrcText, SpacePos + 1,
                                                 MaxInt), 0) - 1;
          end
          else
            CurClass.SrcFile := SrcText;
        end
        else if LastMember <> nil then
        begin
          if LastMember.Comment <> '' then
            LastMember.Comment := LastMember.Comment + #13#10;
          LastMember.Comment := LastMember.Comment + Line;
        end
        else if LastEvent <> nil then
        begin
          if LastEvent.Comment <> '' then
            LastEvent.Comment := LastEvent.Comment + #13#10;
          LastEvent.Comment := LastEvent.Comment + Line;
        end
        else
          CurClass.Comments.Add(Line);
        Continue;
      end;
      if Line[1] = '#' then
      begin
        CurClass := nil;
        LastMember := nil;
        LastEvent := nil;
        Header := TRqClass.Create;
        if not ParseHeader(Line, Header) then
        begin
          Header.Free;   // "#" в конце файла и прочее
          Continue;
        end;
        Section := SectProps;
        ClassIdx := -1;
        if AMerge then
          ClassIdx := RqClasses.IndexOf(Header.Name);
        if ClassIdx >= 0 then
        begin
          CurClass := TRqClass(RqClasses.Objects[ClassIdx]);
          OldClass := True;
          Header.Free;
        end
        else
        begin
          CurClass := Header;
          OldClass := False;
          RqClasses.AddObject(CurClass.Name, CurClass);
          Inc(Result);
        end;
        Continue;
      end;
      if CompareText(Line, '* Constants') = 0 then
      begin
        Section := SectConsts;
        CurClass := nil;
        LastMember := nil;
        LastEvent := nil;
        Continue;
      end;
      // Константы: "alBottom=2"
      if Section = SectConsts then
      begin
        EqPos := Pos('=', Line);
        if (EqPos > 1) and ParseBasicInt(Copy(Line, EqPos + 1, MaxInt),
                                         ConstValue) then
        begin
          if RqDataConsts = nil then
          begin
            RqDataConsts := TStringList.Create;
            RqDataConsts.CaseSensitive := False;
            RqDataConsts.Sorted := True;
            RqDataConsts.Duplicates := dupIgnore;
          end;
          RqDataConsts.AddObject(Trim(Copy(Line, 1, EqPos - 1)),
                                 TObject(ConstValue));
        end;
        Continue;
      end;
      if CurClass = nil then
        Continue;
      if CompareText(Line, '* Methods') = 0 then
      begin
        Section := SectMethods;
        LastMember := nil;
        LastEvent := nil;
        Continue;
      end;
      if CompareText(Line, '* Events') = 0 then
      begin
        Section := SectEvents;
        LastMember := nil;
        LastEvent := nil;
        Continue;
      end;
      if CompareText(Line, '* Defaults') = 0 then
      begin
        Section := SectDefaults;
        LastMember := nil;
        LastEvent := nil;
        Continue;
      end;
      // Значения по умолчанию: "Height=26"
      if Section = SectDefaults then
      begin
        if (Pos('=', Line) > 1) and
           (not OldClass or (CurClass.Defaults.IndexOfName(
              Trim(Copy(Line, 1, Pos('=', Line) - 1))) < 0)) then
          CurClass.Defaults.Add(Line);
        Continue;
      end;
      if Pos('|', Line) = 0 then
        Continue;   // пояснение, не запись

      SplitBars(Line, Fields);
      if not IsIdent(Fields[0]) then
        Continue;
      if Section = SectEvents then
      begin
        if OldClass and (CurClass.Events.IndexOf(Fields[0]) >= 0) then
          Continue;
        Event := TRqEvent.Create;
        Event.Name := Fields[0];
        // "OnClose||(BYREF Action AS INTEGER)": параметры - третье поле
        if Fields.Count >= 3 then
          Event.Params := Fields[2];
        CurClass.Events.AddObject(Event.Name, Event);
        LastEvent := Event;
        if OldClass then
          Inc(AMembers);
        Continue;
      end;

      if Section = SectMethods then
        Target := CurClass.Methods
      else
        Target := CurClass.Props;
      if OldClass and (Target.IndexOf(Fields[0]) >= 0) then
        Continue;
      Member := TRqMember.Create;
      Member.Name := Fields[0];
      if Fields.Count >= 2 then
        Member.TypeName := Fields[1];
      if Fields.Count >= 3 then
        Member.Access := Fields[2];
      if Fields.Count >= 4 then
        Member.DefValue := Fields[3];
      for FieldIdx := 4 to Fields.Count - 1 do
        if Fields[FieldIdx] <> '' then
          Member.Choices.Add(Fields[FieldIdx]);
      Target.AddObject(Member.Name, Member);
      LastMember := Member;
      if OldClass then
        Inc(AMembers);
    end;
  finally
    Fields.Free;
    Lines.Free;
  end;
end;

function RqLoadComponents(const AFile: string): Integer;
var
  Members: Integer;
begin
  RqFreeComponents;
  Result := LoadComponentFile(AFile, False, Members);
  if Result > 0 then
    RqComponentFile := AFile;
end;

function RqMergeComponents(const AFile: string; var AMembers: Integer): Integer;
begin
  AMembers := 0;
  Result := 0;
  if RqClasses = nil then
    Exit;
  Result := LoadComponentFile(AFile, True, AMembers);
  if (Result > 0) or (AMembers > 0) then
  begin
    if RqMergedFiles <> '' then
      RqMergedFiles := RqMergedFiles + '; ';
    RqMergedFiles := RqMergedFiles + AFile;
  end;
end;

function RqFindClass(const AName: string): TRqClass;
var
  ClassIdx: Integer;
begin
  Result := nil;
  if RqCustom <> nil then
  begin
    ClassIdx := RqCustom.IndexOf(AName);
    if ClassIdx >= 0 then
    begin
      Result := TRqClass(RqCustom.Objects[ClassIdx]);
      Exit;
    end;
  end;
  if RqClasses = nil then
    Exit;
  ClassIdx := RqClasses.IndexOf(AName);
  if ClassIdx >= 0 then
    Result := TRqClass(RqClasses.Objects[ClassIdx]);
end;

procedure RqClearCustom;
var
  ClassIdx: Integer;
begin
  if RqCustom = nil then
    Exit;
  for ClassIdx := 0 to RqCustom.Count - 1 do
    RqCustom.Objects[ClassIdx].Free;
  RqCustom.Clear;
end;

function RqCustomCount: Integer;
begin
  if RqCustom = nil then
    Result := 0
  else
    Result := RqCustom.Count;
end;

// Строка без комментария (' вне кавычек, REM в начале), без пробелов по
// краям
function StripBasicComment(const ALine: string): string;
var
  CharIdx: Integer;
  InQuote: Boolean;
begin
  Result := ALine;
  InQuote := False;
  for CharIdx := 1 to Length(ALine) do
    if ALine[CharIdx] = '"' then
      InQuote := not InQuote
    else if (ALine[CharIdx] = '''') and not InQuote then
    begin
      Result := Copy(ALine, 1, CharIdx - 1);
      Break;
    end;
  Result := Trim(Result);
  if (UpperCase(Copy(Result, 1, 3)) = 'REM') and
     ((Length(Result) = 3) or (Result[4] <= ' ')) then
    Result := '';
end;

// Первое слово строки заглавными, ARest - остаток без пробелов по краям.
// Слово - до пробела, "(" или ":".
function FirstWordOf(const AText: string; var ARest: string): string;
var
  WordEnd: Integer;
begin
  WordEnd := 1;
  while (WordEnd <= Length(AText)) and (AText[WordEnd] > ' ') and
        (AText[WordEnd] <> '(') and (AText[WordEnd] <> ':') do
    Inc(WordEnd);
  Result := UpperCase(Copy(AText, 1, WordEnd - 1));
  ARest := Trim(Copy(AText, WordEnd, MaxInt));
end;

// Имя в начале текста: буквы, цифры, _ . и суффиксы типа % $ & ! #
function LeadingName(const AText: string): string;
var
  CharIdx: Integer;
begin
  CharIdx := 1;
  while (CharIdx <= Length(AText)) and
        (AText[CharIdx] in ['A'..'Z', 'a'..'z', '0'..'9', '_', '.', '%', '$',
                            '&', '!', '#']) do
    Inc(CharIdx);
  Result := Copy(AText, 1, CharIdx - 1);
end;

// Поле типа: "Имя[(размер)] AS Тип [хвост]". AIsArray - с размером.
function ParseField(const AStmt: string; var AName, AType, ATail: string;
                    var AIsArray: Boolean): Boolean;
var
  Rest, Word: string;
  Depth, CharIdx: Integer;
begin
  Result := False;
  AName := LeadingName(AStmt);
  if (AName = '') or not (AName[1] in ['A'..'Z', 'a'..'z', '_']) then
    Exit;
  Rest := TrimLeft(Copy(AStmt, Length(AName) + 1, MaxInt));
  AIsArray := (Rest <> '') and (Rest[1] = '(');
  if AIsArray then
  begin
    Depth := 0;
    CharIdx := 1;
    repeat
      if Rest[CharIdx] = '(' then
        Inc(Depth)
      else if Rest[CharIdx] = ')' then
        Dec(Depth);
      Inc(CharIdx);
    until (Depth = 0) or (CharIdx > Length(Rest));
    Rest := TrimLeft(Copy(Rest, CharIdx, MaxInt));
  end;
  Word := FirstWordOf(Rest, Rest);
  if Word <> 'AS' then
    Exit;
  AType := LeadingName(Rest);
  if AType = '' then
    Exit;
  ATail := Trim(Copy(Rest, Length(AType) + 1, MaxInt));
  Result := True;
end;

// Операторы строки без комментария, разделённые ":" вне кавычек:
// "SUB X_Click: .OnTop: END SUB" - три оператора
procedure SplitColons(const ALine: string; AParts: TStrings);
var
  CharIdx, StartPos: Integer;
  InQuote: Boolean;
  Part: string;
begin
  AParts.Clear;
  InQuote := False;
  StartPos := 1;
  for CharIdx := 1 to Length(ALine) + 1 do
    if (CharIdx <= Length(ALine)) and (ALine[CharIdx] = '"') then
      InQuote := not InQuote
    else if (CharIdx > Length(ALine)) or
            ((ALine[CharIdx] = ':') and not InQuote) then
    begin
      Part := Trim(Copy(ALine, StartPos, CharIdx - StartPos));
      if Part <> '' then
        AParts.Add(Part);
      StartPos := CharIdx + 1;
    end;
end;

function RqParseTypes(ALines: TStrings; const AFile: string): Integer;
var
  LineIdx, PartIdx, AddedCount: Integer;
  CurClass: TRqClass;
  BodyKind: string;
  IsPublic: Boolean;
  Parts: TStringList;

  procedure FinishClass;
  begin
    if RqCustom.IndexOf(CurClass.Name) >= 0 then
      CurClass.Free
    else
    begin
      RqCustom.AddObject(CurClass.Name, CurClass);
      Inc(AddedCount);
    end;
    CurClass := nil;
  end;

  // Один оператор строки ALine
  procedure ProcessStmt(AStmt: string; ALine: Integer);
  var
    Word, Rest, FieldName, FieldType, Tail, Second: string;
    IsArray: Boolean;
    Member: TRqMember;
    Event: TRqEvent;
    EqPos: Integer;
  begin
    Word := FirstWordOf(AStmt, Rest);

    if CurClass = nil then
    begin
      // TYPE Имя EXTENDS Базовый; TYPE без EXTENDS - запись, не класс
      if Word <> 'TYPE' then
        Exit;
      FieldName := LeadingName(Rest);
      Second := FirstWordOf(TrimLeft(Copy(Rest, Length(FieldName) + 1,
                                          MaxInt)), Tail);
      if (FieldName = '') or (Second <> 'EXTENDS') then
        Exit;
      CurClass := TRqClass.Create;
      CurClass.IsCustom := True;
      CurClass.Name := FieldName;
      CurClass.BaseName := LeadingName(Tail);
      CurClass.SrcFile := AFile;
      CurClass.SrcLine := ALine;
      CurClass.Num := -1;
      BodyKind := '';
      IsPublic := True;
      Exit;
    end;

    if Word = 'END' then
    begin
      Second := FirstWordOf(Rest, Tail);
      if Second = 'TYPE' then
      begin
        FinishClass;
        Exit;
      end;
      // Конец тела: END SUB, END PROPERTY, END CONSTRUCTOR... Тело SUB
      // и FUNCTION закрывает любое из END SUB / FUNCTION: в исходниках
      // встречается FUNCTION ... END SUB (QAVI.inc), и компилятор его
      // принимает
      if (BodyKind <> '') and
         ((Second = BodyKind) or
          (((BodyKind = 'SUB') or (BodyKind = 'FUNCTION')) and
           ((Second = 'SUB') or (Second = 'SUBI') or
            (Second = 'FUNCTION') or (Second = 'FUNCTIONI')))) then
        BodyKind := '';
      Exit;
    end;

    if BodyKind <> '' then
    begin
      // Присваивания конструктора - значения по умолчанию
      if BodyKind = 'CONSTRUCTOR' then
      begin
        EqPos := Pos('=', AStmt);
        FieldName := LeadingName(AStmt);
        if (FieldName <> '') and (EqPos > 0) and
           (Trim(Copy(AStmt, Length(FieldName) + 1,
                      EqPos - Length(FieldName) - 1)) = '') then
          CurClass.Defaults.Values[FieldName] :=
            Trim(Copy(AStmt, EqPos + 1, MaxInt));
      end;
      Exit;
    end;

    if (Word = 'SUB') or (Word = 'SUBI') or (Word = 'FUNCTION') or
       (Word = 'FUNCTIONI') then
    begin
      if Word = 'SUBI' then
        BodyKind := 'SUB'
      else if Word = 'FUNCTIONI' then
        BodyKind := 'FUNCTION'
      else
        BodyKind := Word;
      FieldName := LeadingName(Rest);
      if IsPublic and (FieldName <> '') and
         (CurClass.Methods.IndexOf(FieldName) < 0) then
      begin
        Member := TRqMember.Create;
        Member.Name := FieldName;
        Member.TypeName := Word;
        Member.DefValue := Trim(Copy(Rest, Length(FieldName) + 1, MaxInt));
        CurClass.Methods.AddObject(Member.Name, Member);
      end;
      Exit;
    end;
    if (Word = 'PROPERTY') or (Word = 'CONSTRUCTOR') or
       (Word = 'DESTRUCTOR') or (Word = 'EVENT') then
    begin
      BodyKind := Word;
      Exit;
    end;
    if (Word = 'PUBLIC') or (Word = 'PRIVATE') or (Word = 'PROTECTED') then
    begin
      IsPublic := Word = 'PUBLIC';
      Exit;
    end;
    if Word = 'WITH' then
      Exit;
    if Word = 'DIM' then
      AStmt := Rest;

    if not ParseField(AStmt, FieldName, FieldType, Tail, IsArray) or
       not IsPublic then
      Exit;
    if UpperCase(FieldType) = 'EVENT' then
    begin
      if CurClass.Events.IndexOf(FieldName) >= 0 then
        Exit;
      Event := TRqEvent.Create;
      Event.Name := FieldName;
      Event.Params := Tail;   // шаблон обработчика: (Event_Change)
      CurClass.Events.AddObject(Event.Name, Event);
      Exit;
    end;
    if CurClass.Props.IndexOf(FieldName) >= 0 then
      Exit;
    Member := TRqMember.Create;
    Member.Name := FieldName;
    if IsArray then
      Member.TypeName := 'ARRAY of ' + UpperCase(FieldType)
    else
      Member.TypeName := UpperCase(FieldType);
    Member.Access := 'RW';
    CurClass.Props.AddObject(Member.Name, Member);
  end;

begin
  AddedCount := 0;
  if RqCustom = nil then
  begin
    RqCustom := TStringList.Create;
    RqCustom.CaseSensitive := False;
  end;
  CurClass := nil;
  BodyKind := '';
  IsPublic := True;
  Parts := TStringList.Create;
  try
    for LineIdx := 0 to ALines.Count - 1 do
    begin
      // Быстрый отсев вне TYPE: нужна только строка со словом TYPE
      if (CurClass = nil) and
         (Pos('TYPE', UpperCase(ALines[LineIdx])) = 0) then
        Continue;
      SplitColons(StripBasicComment(ALines[LineIdx]), Parts);
      for PartIdx := 0 to Parts.Count - 1 do
      begin
        // REM после двоеточия - комментарий до конца строки
        if (UpperCase(Copy(Parts[PartIdx], 1, 3)) = 'REM') and
           ((Length(Parts[PartIdx]) = 3) or (Parts[PartIdx][4] <= ' ')) then
          Break;
        ProcessStmt(Parts[PartIdx], LineIdx);
      end;
    end;
    // Файл кончился внутри TYPE - то, что успели разобрать, тоже класс
    if CurClass <> nil then
      FinishClass;
  finally
    Parts.Free;
  end;
  Result := AddedCount;
end;

function RqParseConsts(ALines: TStrings): Integer;
var
  LineIdx, PartIdx, EqPos, ConstValue: Integer;
  Parts: TStringList;
  Word, Rest, ConstName: string;
begin
  Result := 0;
  if RqConsts = nil then
  begin
    RqConsts := TStringList.Create;
    RqConsts.CaseSensitive := False;
    RqConsts.Sorted := True;
    RqConsts.Duplicates := dupIgnore;
  end;
  Parts := TStringList.Create;
  try
    for LineIdx := 0 to ALines.Count - 1 do
    begin
      if Pos('CONST', UpperCase(ALines[LineIdx])) = 0 then
        Continue;
      SplitColons(StripBasicComment(ALines[LineIdx]), Parts);
      for PartIdx := 0 to Parts.Count - 1 do
      begin
        Word := FirstWordOf(Parts[PartIdx], Rest);
        if Word <> 'CONST' then
          Continue;
        ConstName := LeadingName(Rest);
        EqPos := Pos('=', Rest);
        if (ConstName = '') or (EqPos = 0) or
           (Trim(Copy(Rest, Length(ConstName) + 1,
                      EqPos - Length(ConstName) - 1)) <> '') then
          Continue;
        if not ParseBasicInt(Copy(Rest, EqPos + 1, MaxInt), ConstValue) then
          Continue;
        if RqConsts.IndexOf(ConstName) >= 0 then
          Continue;
        RqConsts.AddObject(ConstName, TObject(ConstValue));
        Inc(Result);
      end;
    end;
  finally
    Parts.Free;
  end;
end;

procedure RqClearConsts;
begin
  if RqConsts <> nil then
    RqConsts.Clear;
end;

function RqConstCount: Integer;
begin
  if RqConsts = nil then
    Result := 0
  else
    Result := RqConsts.Count;
end;

// Сначала константы программы, потом из описания (* Constants)
function RqConstValue(const AName: string; var AValue: Integer): Boolean;
var
  ConstIdx: Integer;
begin
  Result := False;
  if RqConsts <> nil then
  begin
    ConstIdx := RqConsts.IndexOf(AName);
    if ConstIdx >= 0 then
    begin
      AValue := Integer(RqConsts.Objects[ConstIdx]);
      Result := True;
      Exit;
    end;
  end;
  if RqDataConsts <> nil then
  begin
    ConstIdx := RqDataConsts.IndexOf(AName);
    if ConstIdx >= 0 then
    begin
      AValue := Integer(RqDataConsts.Objects[ConstIdx]);
      Result := True;
    end;
  end;
end;

procedure RqConstNames(const APrefix: string; AList: TStrings);
var
  Names: TStringList;
  ListIdx, ConstIdx: Integer;
  ConstList: TStringList;
  ConstName: string;
begin
  Names := TStringList.Create;
  try
    Names.Sorted := True;
    Names.Duplicates := dupIgnore;
    Names.CaseSensitive := False;
    for ListIdx := 0 to 1 do
    begin
      if ListIdx = 0 then
        ConstList := RqConsts
      else
        ConstList := RqDataConsts;
      if ConstList = nil then
        Continue;
      for ConstIdx := 0 to ConstList.Count - 1 do
      begin
        ConstName := ConstList[ConstIdx];
        if (CompareText(Copy(ConstName, 1, Length(APrefix)), APrefix) = 0) and
           (Length(ConstName) > Length(APrefix)) and
           (ConstName[Length(APrefix) + 1] in ['A'..'Z']) then
          Names.Add(ConstName);
      end;
    end;
    AList.AddStrings(Names);
  finally
    Names.Free;
  end;
end;

procedure RqKeepConstsInData;
var
  ConstIdx: Integer;
begin
  if RqConsts = nil then
    Exit;
  if RqDataConsts = nil then
  begin
    RqDataConsts := TStringList.Create;
    RqDataConsts.CaseSensitive := False;
    RqDataConsts.Sorted := True;
    RqDataConsts.Duplicates := dupIgnore;
  end;
  for ConstIdx := 0 to RqConsts.Count - 1 do
    RqDataConsts.AddObject(RqConsts[ConstIdx], RqConsts.Objects[ConstIdx]);
end;

function RqChoiceName(const AChoice: string): string;
var
  EqPos: Integer;
begin
  EqPos := Pos('=', AChoice);
  if EqPos > 0 then
    Result := Copy(AChoice, 1, EqPos - 1)
  else
    Result := AChoice;
end;

// Значение варианта: записанное в файле ("bsSizeable=2"), иначе константа
// программы. False - не известно.
function ChoiceValueOf(const AChoice: string; var AValue: Integer): Boolean;
var
  EqPos: Integer;
begin
  EqPos := Pos('=', AChoice);
  if EqPos > 0 then
    Result := ParseBasicInt(Copy(AChoice, EqPos + 1, MaxInt), AValue)
  else
    Result := RqConstValue(AChoice, AValue);
end;

function RqChoiceText(AMember: TRqMember; const AValue: string): string;
var
  Number, ChoiceIdx, ChoiceValue, CharIdx, ListIdx: Integer;
  ConstList: TStringList;
  AnyConst: Boolean;
  Prefix, Found, FirstName: string;
begin
  Result := AValue;
  if (AMember = nil) or (AMember.Choices.Count = 0) or
     not ParseBasicInt(AValue, Number) then
    Exit;
  // <default>|<choose> у цвета и подобные - не перечисление
  for ChoiceIdx := 0 to AMember.Choices.Count - 1 do
    if Copy(AMember.Choices[ChoiceIdx], 1, 1) = '<' then
      Exit;
  if (AMember.Choices.Count = 2) and
     (CompareText(RqChoiceName(AMember.Choices[0]), 'False') = 0) and
     (CompareText(RqChoiceName(AMember.Choices[1]), 'True') = 0) then
  begin
    if Number = 0 then
      Result := RqChoiceName(AMember.Choices[0])
    else
      Result := RqChoiceName(AMember.Choices[1]);
    Exit;
  end;
  AnyConst := False;
  for ChoiceIdx := 0 to AMember.Choices.Count - 1 do
    if ChoiceValueOf(AMember.Choices[ChoiceIdx], ChoiceValue) then
    begin
      AnyConst := True;
      if ChoiceValue = Number then
      begin
        Result := RqChoiceName(AMember.Choices[ChoiceIdx]);
        Exit;
      end;
    end;
  if not AnyConst then
  begin
    if (Number >= 0) and (Number < AMember.Choices.Count) then
      Result := RqChoiceName(AMember.Choices[Number]);
    Exit;
  end;
  // Приставка вариантов - строчные буквы в начале, одна у всех
  FirstName := RqChoiceName(AMember.Choices[0]);
  CharIdx := 1;
  while (CharIdx <= Length(FirstName)) and (FirstName[CharIdx] in ['a'..'z']) do
    Inc(CharIdx);
  Prefix := Copy(FirstName, 1, CharIdx - 1);
  if (Prefix = '') or (CharIdx > Length(FirstName)) then
    Exit;
  for ChoiceIdx := 1 to AMember.Choices.Count - 1 do
    if Copy(AMember.Choices[ChoiceIdx], 1, Length(Prefix)) <> Prefix then
      Exit;
  // Константы с этой приставкой и этим значением - из программы и из
  // описания; одно имя в обоих списках - одна константа
  Found := '';
  for ListIdx := 0 to 1 do
  begin
    if ListIdx = 0 then
      ConstList := RqConsts
    else
      ConstList := RqDataConsts;
    if ConstList = nil then
      Continue;
    for ChoiceIdx := 0 to ConstList.Count - 1 do
      if (Copy(ConstList[ChoiceIdx], 1, Length(Prefix)) = Prefix) and
         (Length(ConstList[ChoiceIdx]) > Length(Prefix)) and
         (ConstList[ChoiceIdx][Length(Prefix) + 1] in ['A'..'Z']) and
         (Integer(ConstList.Objects[ChoiceIdx]) = Number) and
         (CompareText(ConstList[ChoiceIdx], Found) <> 0) then
      begin
        if Found <> '' then
          Exit;   // двум константам одно значение - какая из них, неясно
        Found := ConstList[ChoiceIdx];
      end;
  end;
  if Found <> '' then
    Result := Found;
end;

procedure RqClassChain(const AName: string; AChain: TList);
const
  MaxDepth = 20;
var
  Cls: TRqClass;
  Next: string;
begin
  AChain.Clear;
  Next := AName;
  while (Next <> '') and (AChain.Count < MaxDepth) do
  begin
    Cls := RqFindClass(Next);
    if (Cls = nil) or (AChain.IndexOf(Cls) >= 0) then
      Break;
    AChain.Add(Cls);
    if Cls.IsCustom then
      Next := Cls.BaseName
    else
      Next := '';
  end;
end;

function RqDefaultOf(AChain: TList; const AName: string;
                     var AMember: TRqMember): string;
var
  ClassIdx: Integer;
  Cls: TRqClass;
  Found: Boolean;
begin
  Result := '';
  AMember := nil;
  Found := False;
  for ClassIdx := 0 to AChain.Count - 1 do
  begin
    Cls := TRqClass(AChain[ClassIdx]);
    if not Found and (Cls.Defaults.IndexOfName(AName) >= 0) then
    begin
      Result := Cls.Defaults.Values[AName];
      Found := True;
    end;
    if AMember = nil then
      AMember := Cls.PropOf(AName);
  end;
  if not Found and (AMember <> nil) then
    Result := AMember.DefValue;
end;

function RqHeaderComments: TStringList;
begin
  if RqFileComments = nil then
    RqFileComments := TStringList.Create;
  Result := RqFileComments;
end;

function RqTakeCustom: TStringList;
begin
  if RqCustom = nil then
  begin
    RqCustom := TStringList.Create;
    RqCustom.CaseSensitive := False;
  end;
  Result := RqCustom;
  RqCustom := TStringList.Create;
  RqCustom.CaseSensitive := False;
end;

function RqAddClass(AClass: TRqClass): Boolean;
begin
  if RqClasses = nil then
  begin
    RqClasses := TStringList.Create;
    RqClasses.CaseSensitive := False;
  end;
  Result := RqClasses.IndexOf(AClass.Name) < 0;
  if Result then
    RqClasses.AddObject(AClass.Name, AClass);
end;

procedure RqDropCustomClasses;
var
  ClassIdx: Integer;
begin
  if RqClasses = nil then
    Exit;
  for ClassIdx := RqClasses.Count - 1 downto 0 do
    if TRqClass(RqClasses.Objects[ClassIdx]).IsCustom then
    begin
      RqClasses.Objects[ClassIdx].Free;
      RqClasses.Delete(ClassIdx);
    end;
end;

procedure RqSaveComponents(const AFile: string);
var
  Output: TStringList;
  ClassIdx, ItemIdx: Integer;
  Cls: TRqClass;
  Head, Line: string;

  procedure AddMember(AMember: TRqMember; AWithChoices: Boolean);
  var
    ChoiceIdx: Integer;
  begin
    Line := AMember.Name + '|' + AMember.TypeName + '|' + AMember.Access +
            '|' + AMember.DefValue;
    if AWithChoices then
      for ChoiceIdx := 0 to AMember.Choices.Count - 1 do
        Line := Line + '|' + AMember.Choices[ChoiceIdx];
    Output.Add(Line);
    if AMember.Comment <> '' then
      Output.Add(AMember.Comment);
  end;

begin
  Output := TStringList.Create;
  try
    if RqFileComments <> nil then
      Output.AddStrings(RqFileComments);
    if RqClasses <> nil then
      for ClassIdx := 0 to RqClasses.Count - 1 do
      begin
        Cls := TRqClass(RqClasses.Objects[ClassIdx]);
        Head := '# ' + IntToStr(ClassIdx) + ' ' + Cls.Name;
        if Cls.IsCustom then
          Head := Head + ' EXTENDS ' + Cls.BaseName;
        Head := Head + ' * Properties *';
        if Cls.Note <> '' then
          Head := Head + ' ' + Cls.Note;
        Output.Add(Head);
        if Cls.SrcFile <> '' then
          Output.Add('''@source ' + Cls.SrcFile + ' ' +
                     IntToStr(Cls.SrcLine + 1));
        Output.AddStrings(Cls.Comments);
        for ItemIdx := 0 to Cls.Props.Count - 1 do
          AddMember(TRqMember(Cls.Props.Objects[ItemIdx]), True);
        Output.Add('* Methods');
        for ItemIdx := 0 to Cls.Methods.Count - 1 do
          AddMember(TRqMember(Cls.Methods.Objects[ItemIdx]), False);
        Output.Add('* Events');
        for ItemIdx := 0 to Cls.Events.Count - 1 do
        begin
          Output.Add(TRqEvent(Cls.Events.Objects[ItemIdx]).Name + '||' +
                     TRqEvent(Cls.Events.Objects[ItemIdx]).Params);
          if TRqEvent(Cls.Events.Objects[ItemIdx]).Comment <> '' then
            Output.Add(TRqEvent(Cls.Events.Objects[ItemIdx]).Comment);
        end;
        if Cls.Defaults.Count > 0 then
        begin
          Output.Add('* Defaults');
          Output.AddStrings(Cls.Defaults);
        end;
      end;
    if (RqDataConsts <> nil) and (RqDataConsts.Count > 0) then
    begin
      Output.Add('* Constants');
      for ItemIdx := 0 to RqDataConsts.Count - 1 do
        Output.Add(RqDataConsts[ItemIdx] + '=' +
                   IntToStr(Integer(RqDataConsts.Objects[ItemIdx])));
    end;
    Output.Add('#');
    Output.SaveToFile(AFile);
  finally
    Output.Free;
  end;
end;

function RqClassCount: Integer;
begin
  if RqClasses = nil then
    Result := 0
  else
    Result := RqClasses.Count;
end;

function RqClassAt(AIndex: Integer): TRqClass;
begin
  Result := TRqClass(RqClasses.Objects[AIndex]);
end;

initialization

finalization
  RqFreeComponents;
  RqClearCustom;
  FreeAndNil(RqCustom);
  FreeAndNil(RqConsts);
  FreeAndNil(RqFileComments);
  FreeAndNil(RqDataConsts);

end.
