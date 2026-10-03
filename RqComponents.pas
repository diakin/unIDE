unit RqComponents;

// ---------------------------------------------------------------------------
//  Описание компонентов RapidQ из файла Component.data
//
//  Формат файла (текст, по строке на запись):
//    # <номер> <КЛАСС> * Properties *  [примечание]   - начало класса
//    Имя|ТИП|доступ|по умолчанию|вариант1|вариант2...  - свойство
//    * Methods                                         - дальше методы:
//    Имя|ТИП|доступ|аргументы
//    * Events                                          - дальше события:
//    Имя||(параметры)
//  Доступ: R - только чтение, W - только запись, RW - оба. Варианты - для
//  перечислений и логических (False|True); <default> и <choose> у цвета -
//  "по умолчанию" и "выбрать". Строка из одного # - конец файла.
//
//  Строки без | и записи, у которых имя не идентификатор (пояснения вроде
//  "NO Properties!||R|"), пропускаются.
//
//  Файлов бывает несколько редакций (Component.data, Component1.data): у
//  одной есть классы меню, у другой - DirectX. Основной загружается
//  RqLoadComponents, остальные добавляются RqMergeComponents - только
//  классы и члены классов, которых ещё нет; уже загруженное не меняется.
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
    Choices: TStringList;  // допустимые значения (пусто - любые)
    constructor Create;
    destructor Destroy; override;
    function CanRead: Boolean;
    function CanWrite: Boolean;
  end;

  TRqEvent = class
  public
    Name, Params: string;   // Params - "(Key AS WORD, Shift AS INTEGER)"
  end;

  TRqClass = class
  public
    Name: string;
    Num: Integer;          // номер класса в файле
    Note: string;          // примечание в строке заголовка
    Props, Methods, Events: TStringList;   // Objects - TRqMember / TRqEvent
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
// Класс по имени без учёта регистра; nil - нет такого или не загружено
function RqFindClass(const AName: string): TRqClass;
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
  // Примечание - всё после имени без метки "* Properties" и звёздочек
  Rest := Trim(Copy(Rest, CharIdx, MaxInt));
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

// Разбор файла. AMerge = False - в пустой список; True - к загруженному:
// существующий класс дополняется недостающими членами. Результат - число
// добавленных классов, AMembers - число членов, добавленных к прежним.
function LoadComponentFile(const AFile: string; AMerge: Boolean;
                           var AMembers: Integer): Integer;
const
  SectProps = 0;
  SectMethods = 1;
  SectEvents = 2;
var
  Lines, Fields: TStringList;
  LineIdx, FieldIdx, Section, ClassIdx: Integer;
  Line: string;
  CurClass, Header: TRqClass;
  OldClass: Boolean;   // CurClass был загружен раньше - члены только новые
  Member: TRqMember;
  Event: TRqEvent;
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
    Section := SectProps;
    for LineIdx := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[LineIdx]);
      if Line = '' then
        Continue;
      if Line[1] = '#' then
      begin
        CurClass := nil;
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
      if CurClass = nil then
        Continue;
      if CompareText(Line, '* Methods') = 0 then
      begin
        Section := SectMethods;
        Continue;
      end;
      if CompareText(Line, '* Events') = 0 then
      begin
        Section := SectEvents;
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
  if RqClasses = nil then
    Exit;
  ClassIdx := RqClasses.IndexOf(AName);
  if ClassIdx >= 0 then
    Result := TRqClass(RqClasses.Objects[ClassIdx]);
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

end.
