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
  SysUtils, TypInfo, Controls, Graphics, Menus, ComCtrls, ExtCtrls, StdCtrls,
  Forms {$IFDEF FPC}, LCLProc, Windows{$ENDIF};

const
  MaxListItems = 30;   // длиннее - только число строк
  MaxSubDepth = 3;     // Font.Name - глубина 1; дальше не спускаемся

var
  Buf: TStringList;

{$IFDEF FPC}
// Строки LCL - UTF-8, а текст снимка разбирается как текст .dfm - в
// кодировке редактора (CP_ACP, FormDesigner: DsgAnsiToUtf8). Без перевода
// кириллица из снимка переводилась в UTF-8 второй раз (кракозябры в
// подписях и подсказках формы в конструкторе)
function SnapFromUtf8(const AText: string): string;
var
  WideText: WideString;
  AnsiLen: Integer;
begin
  Result := AText;
  if AText = '' then
    Exit;
  WideText := UTF8Decode(AText);
  AnsiLen := WideCharToMultiByte(CP_ACP, 0, PWideChar(WideText),
    Length(WideText), nil, 0, nil, nil);
  SetLength(Result, AnsiLen);
  if AnsiLen > 0 then
    WideCharToMultiByte(CP_ACP, 0, PWideChar(WideText), Length(WideText),
      PAnsiChar(Result), AnsiLen, nil, nil);
end;
{$ENDIF}

// Строка в записи .dfm: апострофы удваиваются, управляющие символы - #код.
// Под FPC строка приходит из LCL (UTF-8) и переводится в кодировку
// редактора (SnapFromUtf8)
function SnapQuote(const AStr: string): string;
var
  I: Integer;
  InQ: Boolean;
  Str: string;
begin
  Str := {$IFDEF FPC}SnapFromUtf8(AStr){$ELSE}AStr{$ENDIF};
  Result := '';
  InQ := False;
  for I := 1 to Length(Str) do
    if Str[I] < ' ' then
    begin
      if InQ then
      begin
        Result := Result + '''';
        InQ := False;
      end;
      Result := Result + '#' + IntToStr(Ord(Str[I]));
    end
    else
    begin
      if not InQ then
      begin
        Result := Result + '''';
        InQ := True;
      end;
      if Str[I] = '''' then
        Result := Result + ''''''
      else
        Result := Result + Str[I];
    end;
  if InQ then
    Result := Result + '''';
  if Result = '' then
    Result := '''''';
end;

procedure Emit(ALevel: Integer; const Str: string);
begin
  Buf.Add(StringOfChar(' ', ALevel * 2) + Str);
end;

// Имя компонента для ссылки: PopupMenu = FPopupMenu. Безымянный - по классу
function RefName(Obj: TObject): string;
begin
  if (Obj is TComponent) and (TComponent(Obj).Name <> '') then
    Result := TComponent(Obj).Name
  else
    Result := '(' + Obj.ClassName + ')';
end;

procedure WriteProps(AObj: TObject; ALevel: Integer; const APrefix: string;
  ADepth: Integer); forward;

// Одно свойство. Любое исключение при чтении - свойство пропускается:
// снимок не должен падать из-за одного капризного геттера.
procedure WriteProp(AObj: TObject; PropInf: PPropInfo; ALevel: Integer;
  const APrefix: string; ADepth: Integer);
var
  Nm, TypeNm, ValStr: string;
  Ord_: Integer;
  Meth: TMethod;
  Sub: TObject;
  SL: TStrings;
  I: Integer;
begin
  if PropInf^.GetProc = nil then
    Exit;
  Nm := APrefix + PropInf^.Name;
  if (APrefix = '') and (PropInf^.Name = 'Name') then
    Exit; // имя уже стоит в заголовке object

  TypeNm := PropInf^.PropType{$IFNDEF FPC}^{$ENDIF}^.Name;
  try
    case PropInf^.PropType{$IFNDEF FPC}^{$ENDIF}^.Kind of
      tkInteger:
        begin
          Ord_ := GetOrdProp(AObj, PropInf);
          if TypeNm = 'TColor' then
            ValStr := ColorToString(TColor(Ord_))
          else if TypeNm = 'TCursor' then
            ValStr := CursorToString(TCursor(Ord_))
          else if TypeNm = 'TShortCut' then
            ValStr := SnapQuote(ShortCutToText(TShortCut(Ord_)))
          else
            ValStr := IntToStr(Ord_);
          Emit(ALevel, Nm + ' = ' + ValStr);
        end;

      tkChar, tkWChar:
        Emit(ALevel, Nm + ' = ' + SnapQuote(Chr(GetOrdProp(AObj, PropInf))));

      tkEnumeration{$IFDEF FPC}, tkBool{$ENDIF}:
        Emit(ALevel, Nm + ' = ' + GetEnumProp(AObj, PropInf));

      tkSet:
        Emit(ALevel, Nm + ' = ' + GetSetProp(AObj, PropInf, True));

      tkFloat:
        Emit(ALevel, Nm + ' = ' + FloatToStr(GetFloatProp(AObj, PropInf)));

      tkInt64:
        Emit(ALevel, Nm + ' = ' + IntToStr(GetInt64Prop(AObj, PropInf)));

      // FPC: string - tkAString, Boolean - tkBool
      tkString, tkLString, tkWString{$IFDEF FPC}, tkAString, tkUString{$ENDIF}:
        Emit(ALevel, Nm + ' = ' + SnapQuote(GetStrProp(AObj, PropInf)));

      tkMethod:
        begin
          Meth := GetMethodProp(AObj, PropInf);
          if Meth.Code = nil then
            Exit;
          // Имя обработчика известно только у published-методов владельца
          ValStr := '';
          if Meth.Data <> nil then
            ValStr := TObject(Meth.Data).MethodName(Meth.Code);
          if ValStr = '' then
            ValStr := '(без имени)';
          Emit(ALevel, Nm + ' = ' + ValStr);
        end;

      tkClass:
        begin
          Sub := GetObjectProp(AObj, PropInf);
          if Sub = nil then
            Exit;

          if Sub is TComponent then
            // Ссылка на другой компонент - только имя
            Emit(ALevel, Nm + ' = ' + RefName(Sub))
          else if Sub is TStrings then
          begin
            SL := TStrings(Sub);
            // Текст богатого редактора не читаем вовсе - см. шапку модуля
            if {$IFNDEF FPC}(AObj is TCustomRichEdit) or{$ENDIF}
               (SL.Count > MaxListItems) then
              Emit(ALevel, Nm + ' = ' +
                   SnapQuote('(строк: ' + IntToStr(SL.Count) + ')'))
            else if SL.Count = 0 then
              Emit(ALevel, Nm + '.Strings = ()')
            else
            begin
              Emit(ALevel, Nm + '.Strings = (');
              for I := 0 to SL.Count - 1 do
                if I < SL.Count - 1 then
                  Emit(ALevel + 1, SnapQuote(SL[I]))
                else
                  Emit(ALevel + 1, SnapQuote(SL[I]) + ')');
            end;
          end
          else if Sub is TCollection then
            Emit(ALevel, Nm + ' = ' +
                 SnapQuote('(коллекция, элементов: ' +
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

// Внутренняя часть контрола: без имени, владелец - сам родитель, а родитель
// не контейнер (полосы прокрутки TEdView, кнопки составных контролов). В
// .dfm её нет и быть не должно - её создаёт конструктор родителя.
//
// Так же - часть составного компонента не из VCL: без имени, владелец -
// безымянный компонент своего модуля (палитра TDsgPalette: её вкладки,
// прокрутка и кнопки строятся по списку компонентов, а не кодом формы).
function IsInnerPart(AChild: TControl; AParent: TWinControl;
                     ARoot: TComponent): Boolean;
const
  VclUnits: array[0..9] of string = ('Controls', 'StdCtrls', 'ExtCtrls',
    'ComCtrls', 'Forms', 'Menus', 'Buttons', 'Grids', 'CheckLst', 'Tabs');
var
  OwnerUnit: string;
  UnitIdx: Integer;
begin
  Result := False;
  if (AParent = ARoot) or (AChild.Name <> '') or (AChild.Owner = nil) or
     (AChild.Owner = ARoot) then
    Exit;
  if (AChild.Owner = AParent) and
     not (AParent is TCustomPanel) and
     not (AParent is TCustomGroupBox) and
     not (AParent is TScrollingWinControl) and
     not (AParent is TTabSheet) then
  begin
    Result := True;
    Exit;
  end;
  if AChild.Owner.Name <> '' then
    Exit;
  OwnerUnit := string(GetTypeData(AChild.Owner.ClassInfo)^.UnitName);
  for UnitIdx := Low(VclUnits) to High(VclUnits) do
    if CompareText(OwnerUnit, VclUnits[UnitIdx]) = 0 then
      Exit;
  Result := True;
end;

// Объект со всем, что под ним. Вложенность - как в .dfm: контролы по
// Parent, пункты меню - по меню, а у корня ещё его невизуальные компоненты
// и окна, которыми он владеет.
procedure WriteObj(Comp: TComponent; ALevel: Integer; ARoot: TComponent);
var
  I: Integer;
  Comp2: TComponent;
begin
  if (Comp <> ARoot) and Assigned(FormSnapshotSkip) and FormSnapshotSkip(Comp) then
    Exit;
  if Comp.Name <> '' then
    Emit(ALevel, 'object ' + Comp.Name + ': ' + Comp.ClassName)
  else
    Emit(ALevel, 'object ' + Comp.ClassName);

  WriteProps(Comp, ALevel + 1, '', 0);

  if Comp is TWinControl then
    for I := 0 to TWinControl(Comp).ControlCount - 1 do
      if not IsInnerPart(TWinControl(Comp).Controls[I], TWinControl(Comp), ARoot) then
        WriteObj(TWinControl(Comp).Controls[I], ALevel + 1, ARoot);

  if Comp is TMenu then
    for I := 0 to TMenu(Comp).Items.Count - 1 do
      WriteObj(TMenu(Comp).Items[I], ALevel + 1, ARoot)
  else if Comp is TMenuItem then
    for I := 0 to TMenuItem(Comp).Count - 1 do
      WriteObj(TMenuItem(Comp).Items[I], ALevel + 1, ARoot);

  if Comp = ARoot then
    for I := 0 to ARoot.ComponentCount - 1 do
    begin
      Comp2 := ARoot.Components[I];
      // Пункты меню уже выписаны под своим меню, контролы - под родителем
      if Comp2 is TMenuItem then
        Continue;
      if (Comp2 is TControl) and (TControl(Comp2).Parent <> nil) then
        Continue;
      if Comp2 = ARoot then
        Continue;
      WriteObj(Comp2, ALevel + 1, ARoot);
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
