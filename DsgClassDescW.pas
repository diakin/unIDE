unit DsgClassDescW;

// ---------------------------------------------------------------------------
//  Запись описания классов (DsgClassDesc) по RTTI живых классов
//
//  Работает в Delphi 7-сборке unIDE: у неё есть настоящие классы VCL.
//  Свойства и события - из published-RTTI класса (GetPropList), типы
//  свойств - из описаний типов: значения перечислений, элементы наборов,
//  границы целых, параметры событий. Классы вложенных объектов (Font,
//  Constraints, Items) описываются следом - по ним идёт путь "Font.Style".
//
//  Умолчания и текст нового компонента получаются созданием экземпляра; это
//  делает Unit1 (DefaultsFor, DsgNewObjectText) и кладёт в описание сам.
// ---------------------------------------------------------------------------

interface

uses
  Classes, SysUtils, TypInfo, DsgClassDesc;

// Описать класс и всё, что нужно для его свойств. APage - страница палитры
// ('' - не с палитры). Уже описанный класс не переписывается, только
// получает страницу, если её не было.
function DsgDescribeClass(ABase: TDsgClassBase; AClass: TClass;
                          const APage: string): TDsgClassDesc;

// Объявление параметров события по RTTI: "Sender: TObject; var Key: Word";
// соседние параметры одного типа и вида - вместе, как у Delphi. AKind -
// 'procedure' / 'function', AResult - тип результата функции.
procedure DsgMethodParams(ATypeInfo: PTypeInfo; var AKind, AParams,
                          AResult: string);

implementation

function PropTypeOf(AProp: PPropInfo): PTypeInfo;
begin
  {$IFDEF FPC}
  Result := AProp^.PropType;
  {$ELSE}
  Result := AProp^.PropType^;
  {$ENDIF}
end;

function CompTypeOf(ASetType: PTypeInfo): PTypeInfo;
begin
  {$IFDEF FPC}
  Result := GetTypeData(ASetType)^.CompType;
  {$ELSE}
  Result := GetTypeData(ASetType)^.CompType^;
  {$ENDIF}
end;

function TypeNameOf(ATypeInfo: PTypeInfo): string;
begin
  Result := string(ATypeInfo^.Name);
end;

procedure DsgMethodParams(ATypeInfo: PTypeInfo; var AKind, AParams,
                          AResult: string);
var
  TypeRec: PTypeData;
  ParamPtr: PChar;
  ParamIdx: Integer;
  Flags: TParamFlags;
  ParamName, TypeName, Mode, Group, GroupKey, Key: string;
begin
  AKind := 'procedure';
  AParams := '';
  AResult := '';
  TypeRec := GetTypeData(ATypeInfo);
  ParamPtr := @TypeRec^.ParamList;
  Group := '';
  GroupKey := '';
  for ParamIdx := 0 to TypeRec^.ParamCount - 1 do
  begin
    Move(ParamPtr^, Flags, SizeOf(Flags));
    Inc(ParamPtr, SizeOf(Flags));
    ParamName := PShortString(ParamPtr)^;
    Inc(ParamPtr, Length(ParamName) + 1);
    TypeName := PShortString(ParamPtr)^;
    Inc(ParamPtr, Length(TypeName) + 1);
    {$IFDEF FPC}
    // FPC пишет в список и скрытый Self - в Delphi его нет
    if pfHidden in Flags then
      Continue;
    {$ENDIF}

    Mode := '';
    if pfVar in Flags then
      Mode := 'var '
    else if pfConst in Flags then
      Mode := 'const '
    else if pfOut in Flags then
      Mode := 'out ';
    if pfArray in Flags then
      TypeName := 'array of ' + TypeName;
    Key := Mode + '|' + TypeName;

    if (Group <> '') and (Key = GroupKey) then
      Group := Group + ', ' + ParamName
    else
    begin
      if Group <> '' then
      begin
        if AParams <> '' then
          AParams := AParams + '; ';
        AParams := AParams + Group + ': ' +
                   Copy(GroupKey, Pos('|', GroupKey) + 1, MaxInt);
      end;
      Group := Mode + ParamName;
      GroupKey := Key;
    end;
  end;
  if Group <> '' then
  begin
    if AParams <> '' then
      AParams := AParams + '; ';
    AParams := AParams + Group + ': ' +
               Copy(GroupKey, Pos('|', GroupKey) + 1, MaxInt);
  end;

  if TypeRec^.MethodKind = mkFunction then
  begin
    AKind := 'function';
    AResult := PShortString(ParamPtr)^;
  end;
end;

function TypeKeyOf(ABase: TDsgClassBase; ATypeInfo: PTypeInfo): string; forward;

procedure DescribeClassProps(ABase: TDsgClassBase; AClass: TClass;
                             ADesc: TDsgClassDesc);
var
  PropCount, PropIdx: Integer;
  PropList: PPropList;
  Prop: TDsgPropDesc;
  PropRec: PPropInfo;
  Parent: TClass;
begin
  Parent := AClass.ClassParent;
  while Parent <> nil do
  begin
    ADesc.Parents.Add(Parent.ClassName);
    Parent := Parent.ClassParent;
  end;
  if AClass.ClassInfo <> nil then
    ADesc.ModuleName := string(GetTypeData(AClass.ClassInfo)^.UnitName);

  if AClass.ClassInfo = nil then
    Exit;
  PropCount := GetPropList(AClass.ClassInfo, tkAny, nil);
  if PropCount <= 0 then
    Exit;
  GetMem(PropList, PropCount * SizeOf(PPropInfo));
  try
    GetPropList(AClass.ClassInfo, tkAny, PropList);  // по алфавиту, и события
    for PropIdx := 0 to PropCount - 1 do
    begin
      PropRec := PropList^[PropIdx];
      Prop := TDsgPropDesc.Create;
      Prop.Name := string(PropRec^.Name);
      Prop.Writable := PropRec^.SetProc <> nil;
      ADesc.Props.AddObject(Prop.Name, Prop);
    end;
    // Типы - после того как список свойств готов: описание типа-класса
    // добавляет в базу другие классы
    for PropIdx := 0 to PropCount - 1 do
      TDsgPropDesc(ADesc.Props.Objects[PropIdx]).TypeName :=
        TypeKeyOf(ABase, PropTypeOf(PropList^[PropIdx]));
  finally
    FreeMem(PropList);
  end;
end;

procedure DescribeType(ABase: TDsgClassBase; ATypeInfo: PTypeInfo;
                       Typ: TDsgTypeDesc);
var
  TypeRec: PTypeData;
  ValIdx: Integer;
  ElemInfo: PTypeInfo;
  SubClass: TClass;
  SubDesc: TDsgClassDesc;
  Kind, Params, ResType: string;
begin
  TypeRec := GetTypeData(ATypeInfo);
  case ATypeInfo^.Kind of
    tkInteger:
    begin
      Typ.Kind := dtkInteger;
      Typ.MinValue := TypeRec^.MinValue;
      Typ.MaxValue := TypeRec^.MaxValue;
    end;
    tkChar:
      Typ.Kind := dtkChar;
    tkWChar:
      Typ.Kind := dtkWChar;
    tkEnumeration{$IFDEF FPC}, tkBool{$ENDIF}:
    begin
      Typ.Kind := dtkEnum;
      Typ.MinValue := TypeRec^.MinValue;
      Typ.MaxValue := TypeRec^.MaxValue;
      for ValIdx := TypeRec^.MinValue to TypeRec^.MaxValue do
        Typ.Values.Add(GetEnumName(ATypeInfo, ValIdx));
    end;
    tkFloat:
      Typ.Kind := dtkFloat;
    tkString, tkLString, tkWString {$IFDEF FPC}, tkAString, tkUString{$ENDIF}:
      Typ.Kind := dtkString;
    tkSet:
    begin
      Typ.Kind := dtkSet;
      ElemInfo := CompTypeOf(ATypeInfo);
      if ElemInfo <> nil then
      begin
        Typ.ElemType := TypeKeyOf(ABase, ElemInfo);
      end;
    end;
    tkClass:
    begin
      Typ.Kind := dtkClass;
      SubClass := TypeRec^.ClassType;
      if (SubClass <> nil) and (ABase.FindClass(SubClass.ClassName) = nil) then
      begin
        SubDesc := ABase.AddClass(SubClass.ClassName);
        DescribeClassProps(ABase, SubClass, SubDesc);
      end;
    end;
    tkMethod:
    begin
      Typ.Kind := dtkMethod;
      DsgMethodParams(ATypeInfo, Kind, Params, ResType);
      Typ.MethodKind := Kind;
      Typ.MethodParams := Params;
      Typ.MethodResult := ResType;
    end;
    tkInt64:
    begin
      Typ.Kind := dtkInt64;
      Typ.MinValue := TypeRec^.MinInt64Value;
      Typ.MaxValue := TypeRec^.MaxInt64Value;
    end;
    tkVariant:
      Typ.Kind := dtkVariant;
  else
    Typ.Kind := dtkOther;
  end;
end;

// Ключ типа в описании. Один и тот же тип (тот же PTypeInfo) - тот же
// ключ; одноимённый тип из другого модуля (TTabStyle в Tabs и ComCtrls,
// TCanResizeEvent в Controls и ExtCtrls) - с ~2, ~3.
function TypeKeyOf(ABase: TDsgClassBase; ATypeInfo: PTypeInfo): string;
var
  Typ: TDsgTypeDesc;
  BaseName: string;
  Number: Integer;
begin
  Result := '';
  if ATypeInfo = nil then
    Exit;
  BaseName := TypeNameOf(ATypeInfo);
  Result := BaseName;
  Number := 1;
  Typ := ABase.FindType(Result);
  while (Typ <> nil) and (Typ.Tag <> ATypeInfo) do
  begin
    Inc(Number);
    Result := BaseName + '~' + IntToStr(Number);
    Typ := ABase.FindType(Result);
  end;
  if Typ <> nil then
    Exit;
  Typ := ABase.AddType(Result);
  Typ.Tag := ATypeInfo;
  DescribeType(ABase, ATypeInfo, Typ);
end;

function DsgDescribeClass(ABase: TDsgClassBase; AClass: TClass;
                          const APage: string): TDsgClassDesc;
begin
  Result := ABase.FindClass(AClass.ClassName);
  if Result = nil then
  begin
    Result := ABase.AddClass(AClass.ClassName);
    DescribeClassProps(ABase, AClass, Result);
  end;
  if (Result.Page = '') and (APage <> '') then
    Result.Page := APage;
end;

end.
