unit FormSnapshot;

// ---------------------------------------------------------------------------
//  Снимок живой формы в текстовом формате .dfm
//
//  Даёт то, чего в .dfm нет: компоненты, созданные в коде (TPanel.Create
//  при старте), и их текущие значения. Текст понимает инспектор объектов
//  редактора - тот же разбор, что и для настоящего .dfm.
//
//  Почему не WriteComponent. Стандартная запись читает ВСЕ published
//  свойства, в том числе Lines у TRichEdit - построчно через EM_GETLINE. У
//  RichEdit 4.1 это пишет UTF-16 в однобайтовый буфер, то есть портит память,
//  а заодно тащит в снимок весь открытый текст. Здесь обход свой, через RTTI,
//  и у списков строк богатых редакторов берётся только их число.
//
//  Модуль самостоятельный: его можно подключить к любой своей программе и
//  писать снимок её форм в файл.
// ---------------------------------------------------------------------------

interface

uses
  Classes;

// Текст снимка: форма и всё, что лежит на ней, плюс её невизуальные
// компоненты и окна, которыми она владеет.
function FormSnapshotText(ARoot: TComponent): string;

type
  // Служебный элемент программы, которого нет в её коде и .dfm (например,
  // своя полоса прокрутки поверх полосы списка), - в снимок не пишется
  // вместе со всем, что под ним. Модуль о чужих классах не знает: программа,
  // у которой такие элементы есть, ставит сюда свою проверку. nil - пишется
  // всё.
  TFormSnapshotSkip = function(C: TComponent): Boolean;

var
  FormSnapshotSkip: TFormSnapshotSkip = nil;

implementation

uses
  SysUtils, TypInfo, Controls, Graphics, Menus, ComCtrls;

const
  MaxListItems = 30;   // длиннее - только число строк
  MaxSubDepth = 3;     // Font.Name - глубина 1; дальше не спускаемся

var
  Buf: TStringList;

// Строка в записи .dfm: апострофы удваиваются, управляющие символы - #код
function Q(const S: string): string;
var
  I: Integer;
  InQ: Boolean;
begin
  Result := '';
  InQ := False;
  for I := 1 to Length(S) do
    if S[I] < ' ' then
    begin
      if InQ then
      begin
        Result := Result + '''';
        InQ := False;
      end;
      Result := Result + '#' + IntToStr(Ord(S[I]));
    end
    else
    begin
      if not InQ then
      begin
        Result := Result + '''';
        InQ := True;
      end;
      if S[I] = '''' then
        Result := Result + ''''''
      else
        Result := Result + S[I];
    end;
  if InQ then
    Result := Result + '''';
  if Result = '' then
    Result := '''''';
end;

procedure Emit(ALevel: Integer; const S: string);
begin
  Buf.Add(StringOfChar(' ', ALevel * 2) + S);
end;

// Имя компонента для ссылки: PopupMenu = FPopupMenu. Безымянный - по классу
function RefName(C: TObject): string;
begin
  if (C is TComponent) and (TComponent(C).Name <> '') then
    Result := TComponent(C).Name
  else
    Result := '(' + C.ClassName + ')';
end;

procedure WriteProps(AObj: TObject; ALevel: Integer; const APrefix: string;
  ADepth: Integer); forward;

// Одно свойство. Любое исключение при чтении - свойство пропускается:
// снимок не должен падать из-за одного капризного геттера.
procedure WriteProp(AObj: TObject; P: PPropInfo; ALevel: Integer;
  const APrefix: string; ADepth: Integer);
var
  Nm, TypeNm, V: string;
  Ord_: Integer;
  M: TMethod;
  Sub: TObject;
  SL: TStrings;
  I: Integer;
begin
  if P^.GetProc = nil then
    Exit;
  Nm := APrefix + P^.Name;
  if (APrefix = '') and (P^.Name = 'Name') then
    Exit; // имя уже стоит в заголовке object

  TypeNm := P^.PropType^^.Name;
  try
    case P^.PropType^^.Kind of
      tkInteger:
        begin
          Ord_ := GetOrdProp(AObj, P);
          if TypeNm = 'TColor' then
            V := ColorToString(TColor(Ord_))
          else if TypeNm = 'TCursor' then
            V := CursorToString(TCursor(Ord_))
          else if TypeNm = 'TShortCut' then
            V := Q(ShortCutToText(TShortCut(Ord_)))
          else
            V := IntToStr(Ord_);
          Emit(ALevel, Nm + ' = ' + V);
        end;

      tkChar, tkWChar:
        Emit(ALevel, Nm + ' = ' + Q(Chr(GetOrdProp(AObj, P))));

      tkEnumeration:
        Emit(ALevel, Nm + ' = ' + GetEnumProp(AObj, P));

      tkSet:
        Emit(ALevel, Nm + ' = ' + GetSetProp(AObj, P, True));

      tkFloat:
        Emit(ALevel, Nm + ' = ' + FloatToStr(GetFloatProp(AObj, P)));

      tkInt64:
        Emit(ALevel, Nm + ' = ' + IntToStr(GetInt64Prop(AObj, P)));

      tkString, tkLString, tkWString:
        Emit(ALevel, Nm + ' = ' + Q(GetStrProp(AObj, P)));

      tkMethod:
        begin
          M := GetMethodProp(AObj, P);
          if M.Code = nil then
            Exit;
          // Имя обработчика известно только у published-методов владельца
          V := '';
          if M.Data <> nil then
            V := TObject(M.Data).MethodName(M.Code);
          if V = '' then
            V := '(без имени)';
          Emit(ALevel, Nm + ' = ' + V);
        end;

      tkClass:
        begin
          Sub := GetObjectProp(AObj, P);
          if Sub = nil then
            Exit;

          if Sub is TComponent then
            // Ссылка на другой компонент - только имя
            Emit(ALevel, Nm + ' = ' + RefName(Sub))
          else if Sub is TStrings then
          begin
            SL := TStrings(Sub);
            // Текст богатого редактора не читаем вовсе - см. шапку модуля
            if (AObj is TCustomRichEdit) or (SL.Count > MaxListItems) then
              Emit(ALevel, Nm + ' = ' +
                   Q('(строк: ' + IntToStr(SL.Count) + ')'))
            else if SL.Count = 0 then
              Emit(ALevel, Nm + '.Strings = ()')
            else
            begin
              Emit(ALevel, Nm + '.Strings = (');
              for I := 0 to SL.Count - 1 do
                if I < SL.Count - 1 then
                  Emit(ALevel + 1, Q(SL[I]))
                else
                  Emit(ALevel + 1, Q(SL[I]) + ')');
            end;
          end
          else if Sub is TCollection then
            Emit(ALevel, Nm + ' = ' +
                 Q('(коллекция, элементов: ' +
                   IntToStr(TCollection(Sub).Count) + ')'))
          else if ADepth < MaxSubDepth then
            // Вложенный объект - Font, Constraints: его свойства через точку
            WriteProps(Sub, ALevel, Nm + '.', ADepth + 1);
        end;
    end;
  except
    // Свойство не читается в этом состоянии объекта - пропускаем
  end;
end;

procedure WriteProps(AObj: TObject; ALevel: Integer; const APrefix: string;
  ADepth: Integer);
var
  Info: PTypeInfo;
  Count, I: Integer;
  List: PPropList;
begin
  Info := AObj.ClassInfo;
  if Info = nil then
    Exit;
  Count := GetTypeData(Info)^.PropCount;
  if Count <= 0 then
    Exit;

  GetMem(List, Count * SizeOf(PPropInfo));
  try
    GetPropInfos(Info, List);
    for I := 0 to Count - 1 do
      WriteProp(AObj, List^[I], ALevel, APrefix, ADepth);
  finally
    FreeMem(List);
  end;
end;

// Объект со всем, что под ним. Вложенность - как в .dfm: контролы по
// Parent, пункты меню - по меню, а у корня ещё его невизуальные компоненты
// и окна, которыми он владеет.
procedure WriteObj(C: TComponent; ALevel: Integer; ARoot: TComponent);
var
  I: Integer;
  X: TComponent;
begin
  if (C <> ARoot) and Assigned(FormSnapshotSkip) and FormSnapshotSkip(C) then
    Exit;
  if C.Name <> '' then
    Emit(ALevel, 'object ' + C.Name + ': ' + C.ClassName)
  else
    Emit(ALevel, 'object ' + C.ClassName);

  WriteProps(C, ALevel + 1, '', 0);

  if C is TWinControl then
    for I := 0 to TWinControl(C).ControlCount - 1 do
      WriteObj(TWinControl(C).Controls[I], ALevel + 1, ARoot);

  if C is TMenu then
    for I := 0 to TMenu(C).Items.Count - 1 do
      WriteObj(TMenu(C).Items[I], ALevel + 1, ARoot)
  else if C is TMenuItem then
    for I := 0 to TMenuItem(C).Count - 1 do
      WriteObj(TMenuItem(C).Items[I], ALevel + 1, ARoot);

  if C = ARoot then
    for I := 0 to ARoot.ComponentCount - 1 do
    begin
      X := ARoot.Components[I];
      // Пункты меню уже выписаны под своим меню, контролы - под родителем
      if X is TMenuItem then
        Continue;
      if (X is TControl) and (TControl(X).Parent <> nil) then
        Continue;
      if X = ARoot then
        Continue;
      WriteObj(X, ALevel + 1, ARoot);
    end;

  Emit(ALevel, 'end');
end;

function FormSnapshotText(ARoot: TComponent): string;
begin
  Result := '';
  if ARoot = nil then
    Exit;

  Buf := TStringList.Create;
  try
    WriteObj(ARoot, 0, ARoot);
    Result := Buf.Text;
  finally
    FreeAndNil(Buf);
  end;
end;

end.
