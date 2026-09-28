unit DfmMove;

// ---------------------------------------------------------------------------
//  «Перенести в .dfm»: разбор и перенос. Для каждого компонента дерева
//  объектов - можно ли перенести его из кода в .dfm и что станет с кодом;
//  отмеченные в окне разбора компоненты переносятся.
//
//  Переносится только то, в чём разбор уверен:
//    - компонент - поле формы или локальная переменная процедуры формы,
//      чьё имя в других местах модуля встречается только как своя
//      локальная переменная других процедур (при переносе она
//      становится published-полем с тем же именем, объявление из var
//      уходит). Если локальной переменной в процедуре по очереди создают
//      несколько компонентов (Sheet := TTabSheet.Create(Self) дважды),
//      каждый получает своё поле (FObjPagesSheet1, ...), а строка
//      создания становится «Sheet := FObjPagesSheet1;»; создаётся один
//      раз прямой строкой
//      X := TКласс.Create(Self): не другим конструктором (CreateNew,
//      CreatePalette), не в цикле, на прямом пути процедуры - в теле, в
//      begin ... end, в try ... finally, но не после then/else/do, не в
//      except, case, with и не после Exit (блоки определяются разбором
//      слов, не отступами);
//    - или создаётся по требованию: if X = nil then begin ... end; (или
//      if not Assigned(X)), где в блоке только создание полей формы и
//      их свойства. Блок уходит в .dfm целиком, вместе со строкой if;
//      всё, что создано в одном блоке, переносится только вместе. Таймер
//      пишется в .dfm с Enabled = False, контрол и пункт меню - с
//      Visible = False, если в коде после блока есть X.Enabled := True
//      (X.Visible := True, X.Show); иначе - «нет»;
//    - класс зарегистрирован в IDE: по нему проверяется, что свойство
//      published и его можно записать в .dfm;
//    - процедура, в которой он создаётся, - FormCreate или вызывается
//      ровно в одном месте и не назначена обработчиком (у создания по
//      требованию - любая);
//    - родитель - форма или компонент, который тоже будет в .dfm; у
//      контрола и пункта меню строка вложенности - в той же процедуре.
//  Строки X.Свойство := константа уходят в .dfm; X.OnСобытие := Метод -
//  тоже, метод переезжает в published-часть формы. ShortCut(Word('Z'),
//  [ssCtrl]) - тоже константа: в .dfm пишется числом. Ссылка на компонент
//  (X.PopupMenu := Y) уходит, если Y уже в .dfm или переносится сам; иначе
//  остаётся в коде. Вложенность в .dfm заменяет строки X.Parent := P,
//  X.PageControl := P и P.Add(X), P.Items.Add(X), P.Insert(N, X),
//  P.Items.Insert(N, X).
//  Остаются в коде и выполнятся после загрузки формы, как раньше
//  («частично»): вычисления, вызовы методов, свойства не published,
//  X.Name := ..., строки во вложенных блоках и после Exit, свойства, которые
//  в процедуре присваиваются больше одного раза (в том числе после then в
//  той же строке - важен порядок), ItemIndex и подобные, если выше
//  остаются строки этого компонента (Items.Add), операторы на несколько
//  строк. Комментарий // в конце строки разбору не мешает.
//  Целые значения из констант процедуры (const Row1 = 1) и переменных,
//  которым выше на прямом пути присвоены числа (X := 110, Inc(X, 49)),
//  считаются и пишутся в .dfm числом: Top := Row1 + 3 -> Top = 4. Помощник
//  может последней строкой сдвигать переменную процедуры (Inc(X, W + 3) в
//  MakeBtn): его вызов при переносе становится «Inc(X, 49);».
//  Свойства вложенного объекта после вызова его метода (X.Font.Assign(...);
//  X.Font.Style := ...) остаются в коде - важен порядок.
//  Помощник (X := MakeList(...)) может добавлять колонки списка: блоки
//  with Result.Columns.Add do begin Caption := ...; Width := ...; end, в
//  том числе в цикле for I := 0 to High(Массив) do по массивам-аргументам
//  ['A', 'B'], [100, 50]. В .dfm они пишутся коллекцией Columns = < ... >.
//  Процедура-создатель, которая отдаёт компонент через var-параметр
//  (MakeCmpButton(btnViewUnit, ...), ConfigureButton(btnOpen, ...)),
//  остаётся, и вызовы остаются: из неё уходят создание, родитель и
//  свойства, значения которых записываются в .dfm у каждого вызова
//  (аргументы, её константы, посчитанные переменные - Left := ALeft).
//  Строки, которые остаются (значок, сдвиг ALeft), выполняются при вызове,
//  как раньше. Свойство остаётся и тогда, когда выше него остаётся строка,
//  которая его трогает, передаёт компонент целиком или меняет имена из его
//  выражения. Раз строки уходят сразу для всех вызовов, вызовы переносятся
//  только все вместе, и каждое упоминание процедуры в модуле должно быть
//  таким вызовом. Места компонентов .dfm (btnCompileRun.Left), которые код
//  не меняет, в расчётах известны.
//  Процедура формы, которая создаёт компонент в своей локальной переменной
//  и вызывается несколько раз (AddLogPopupItem('&Undo'#9'Ctrl+Z', 1)): в её
//  теле только создание, свойства (можно с условием по параметрам: if ATag
//  <> 0 then It.OnClick := ...) и родитель. Каждый вызов становится своим
//  компонентом (FLogPopupItem1...), значения - из его аргументов; строки
//  вызовов и тела уходят, вызовы переносятся только все вместе.
//  Exit раньше создания не мешает, если это if (A = nil) or ... then Exit;
//  по компонентам .dfm, которые код не освобождает.
//  Цикл for с границами из констант (Low(Kinds) to High(Kinds)), в теле
//  которого пункт создаёт помощник (Sub := MakeItem(...);) и дальше только
//  Sub.Свойство := ...: развёртывается - каждый проход становится своим
//  компонентом (mNewItem1...), значения считаются по константам процедуры
//  (массивы, Copy, Pos, Length, + строк и чисел). Переменная Sub вне цикла
//  не используется; строки цикла уходят, проходы - только все вместе.
//  В блоке по требованию (if FDsgMenu = nil then begin ... end) могут быть
//  и локальная переменная, которой создают несколько пунктов (Grp - каждый
//  получает своё поле FDsgMenuGrp1...), и вызовы помощника (FDsgMiUndo :=
//  Item(Grp, ...); Item(Grp, '-', 0);). Владелец не форма (TMenuItem.Create(
//  FDsgMenu)) допускается, если он сам принадлежит форме и код не
//  обращается к его Components / ComponentCount / FindComponent: в .dfm
//  владельцем станет форма. Пунктам меню, созданного в том же блоке,
//  Visible = False не нужен. Локальные переменные после вложенных процедур
//  (var после function Item) тоже находятся.
//  P.Add(NewLine) - разделитель без имени - в .dfm становится пунктом «-» с
//  именем (P + Line + номер) и published-полем. Если процедура вынимает
//  пункты меню из .dfm (P.Remove(X)) и добавляет их заново вперемешку с
//  созданными, в .dfm пишется порядок, который получается после неё, а
//  строки Remove/Add уходят; созданные там пункты P переносятся только все
//  вместе.
//  Всё остальное - «нет», с причиной и строкой.
//
//  Перенос (DfmMoveApply): блоки object ... end - последними детьми
//  родителей, в порядке строк вложенности; строки кода, ушедшие в .dfm,
//  комментируются («// .dfm: ») или удаляются; поля перенесённых
//  компонентов - в published-часть класса с типом = классом из .dfm (по
//  типам published-полей форма находит классы объектов при загрузке);
//  обработчики - туда же. Тексты пишет IDE во вкладки; откат - «Отменить
//  перенос» (тексты до переноса хранятся, пока IDE открыта), файлы с диска
//  перед первым переносом копируются в .bak.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, ComCtrls,
  StdCtrls;

type
  TMoveKind = (mkInDfm, mkWhole, mkPartial, mkNo);

  // Строка кода, которая уходит в .dfm: создание, вложенность (Parent,
  // PageControl, P.Add(X)), свойство-константа, событие, ссылка на
  // компонент. Value - значение так, как его писать в .dfm; у вложенности
  // и ссылки - имя родителя или компонента. mlColumns - колонки списка
  // (Columns = < item ... end >): в Value строки «Свойство = значение»
  // через #10, колонки разделены строкой «-».
  TMoveLineKind = (mlCreate, mlNesting, mlProp, mlEvent, mlRef, mlColumns);
  TMoveLine = class
  public
    LineIndex: Integer;       // строка модуля, от нуля
    Kind: TMoveLineKind;
    PropName: string;
    Value: string;
  end;

  // Разбор одного компонента
  TMoveInfo = class
  public
    // TDfmNode - копия узла дерева объектов, принадлежит разбору: дерево
    // перестраивается (снимок, правка текста, другая форма) и освобождает
    // свои узлы, а окно разбора открыто дальше
    Node: TObject;
    Depth: Integer;           // уровень в дереве
    Title: string;            // Имя: Класс
    Kind: TMoveKind;
    Reason: string;           // коротко: почему «нет» или что останется
    CreateLine: Integer;      // строка создания, от нуля; -1 - нет
    Routine: string;          // процедура, в которой создаётся
    MoveLines: TStringList;   // строки кода, которые уйдут
    KeepLines: TStringList;   // строки, которые останутся, с причиной
    Handlers: TStringList;    // методы - в published-часть формы
    Notes: TStringList;       // прочие замечания
    // Пункты, которые этот компонент получает строкой X.Add(Y) (и
    // Items.Add, Insert): имя Y, в Objects - номер строки. Нужны, чтобы
    // найти пункты, которые остаются в коде: они встанут после пунктов из
    // .dfm, и порядок меню изменится.
    ChildAdds: TStringList;
    // Ссылки на компоненты: строки X.Свойство := Y, где свойство - объект
    // (PopupMenu, Menu, ActivePage). Имя Y, в Objects - номер строки.
    // Уйдёт ли строка в .dfm, решается после разбора всех компонентов.
    RefLines: TStringList;
    // Для самого переноса
    Items: TList;             // TMoveLine - строки, которые уходят в .dfm
    NestParent: string;       // родитель в .dfm по коду; '' - форма (Self)
    NestLine: Integer;        // строка вложенности (порядок среди соседей)
    Selected: Boolean;        // отмечен в окне для переноса
    // Вызов помощника без переменной (MakeItem(Self, P, ...);): узел
    // создан разбором и принадлежит ему, имя - новое, поле добавится при
    // переносе
    OwnsNode: Boolean;
    NewField: Boolean;
    // Проверки на nil в модуле (if X = nil, Assigned(X)): после переноса X
    // не бывает nil - строки для просмотра, в виде «N: текст»
    NilChecks: TStringList;
    // Из них - те, что могут выполниться, пока компонента ещё нет (до его
    // прежнего создания: раньше в той же процедуре, в том, что вызывается
    // до неё, в обработчиках событий, приходящих при загрузке формы; у
    // создания по требованию - все). Там nil был признаком «ещё не
    // создано», после переноса проверка пропустит код дальше. Такой
    // компонент не отмечается «Отметить всё возможное».
    NilRisk: TStringList;
    // Создаётся по требованию, в блоке if X = nil then begin ... end;:
    // строка if (она же номер группы - компоненты, созданные в одном таком
    // блоке, переносятся только вместе), X и строка end; блока. -1 - нет.
    LazyGroup: Integer;
    LazyGuard: string;
    LazyEnd: Integer;
    // Локальная переменная процедуры, которая при переносе станет
    // published-полем формы с тем же именем: строка её объявления, строка
    // слова var раздела и сколько имён в разделе. -1 - не локальная.
    LocalDecl: Integer;
    LocalVarLine: Integer;
    LocalSectionNames: Integer;
    // Локальная переменная, которой в процедуре по очереди создают
    // несколько компонентов (Sheet := TTabSheet.Create(Self) дважды):
    // каждый получает своё поле с новым именем, а строка создания
    // заменяется на Переменная := Поле; - дальше код работает как раньше.
    // CodeName - имя переменной в коде, ReuseEnd - строка следующего
    // присваивания ей (до неё строки X.... - этого компонента).
    ReusedLocal: Boolean;
    CodeName: string;
    ReuseEnd: Integer;
    // Чем заменить строку создания при переносе (без отступа): у
    // переменной с несколькими компонентами - «Sheet := FObjPagesSheet1;»,
    // у помощника со сдвигом - «Inc(X, 49);». '' - строка уходит.
    ReplaceText: string;
    // Меню, пункты которого процедура вынимает (P.Remove) и расставляет
    // заново: пункты, созданные в ней для P, переносятся только все
    // вместе, а порядок в .dfm записывается тот, что получается после неё.
    // OrderGroup - строка заголовка процедуры (номер группы), -1 - нет;
    // OrderEnd - строка её end.
    OrderGroup: Integer;
    OrderEnd: Integer;
    OrderParent: string;
    // Создаётся процедурой-создателем (MakeCmpButton(btnViewUnit, ...)):
    // строка её заголовка - номер группы, -1 - нет. Процедура остаётся, из
    // неё уходят создание и свойства сразу для всех вызовов - поэтому они
    // переносятся только все вместе.
    HelperGroup: Integer;
    HelperName: string;
    // Развёртка цикла for по константному массиву: аргументы вызова
    // помощника у этого прохода (уже посчитанные), переменная, в которую
    // цикл кладёт результат, и номер прохода - порядок среди соседей с той
    // же строкой вложенности. nil / '' - не развёртка.
    UnrollArgs: TStringList;
    UnrollVar: string;
    NestOrder: Integer;
    // Копии узлов-родителей, которых нет в списке разбора (корень снимка,
    // ссылки): на них указывает Parent копий; освобождаются с этим разбором
    ExtraNodes: TList;
    constructor Create;
    destructor Destroy; override;
  end;

// Разбор всех узлов дерева объектов (в порядке дерева). APasText - текст
// модуля формы, AFormClass - класс формы (TForm1). AList получает
// TMoveInfo - освободить вызывающему.
procedure DfmMoveAnalyze(ATree: TTreeView; const APasText, AFormClass: string;
  AList: TList);

// Перенос отмеченных (Selected) компонентов из AList: тексты модуля и .dfm
// до переноса -> ANewPas, ANewDfm. Строки кода, ушедшие в .dfm,
// комментируются (ADeleteLines - удаляются). Поля перенесённых компонентов
// и их обработчики событий переезжают в published-часть класса формы.
// Сами тексты во вкладки не пишутся. AReport - что сделано и
// предупреждения. Результат - сколько компонентов перенесено (0 - ничего).
// Отметки, которые перенести нельзя (родитель не отмечен и не в .dfm, имя
// уже занято в .dfm), снимаются - с причиной в AReport.
function DfmMoveApply(AList: TList; const APasText, ADfmText,
  AFormClass: string; ADeleteLines: Boolean; var ANewPas, ANewDfm: string;
  AReport: TStrings): Integer;

// Согласованность формы и модуля: каждому событию в .dfm - метод в
// published-части класса AFormClass, каждому объекту - published-поле
// (иначе при загрузке формы будет ошибка чтения или поле останется nil).
// AErrors - то, из-за чего форма не загрузится или код получит nil;
// AWarnings - то, что может сработать (класс зарегистрирован RegisterClass)
// или просто не видно из кода. True - ошибок нет.
function DfmCheckConsistency(const APasText, ADfmText, AFormClass: string;
  AErrors, AWarnings: TStrings): Boolean;

type
  // Встать в редакторе на строку модуля (от нуля)
  TDfmMoveGoLine = procedure(ALine: Integer) of object;
  // Текст файла из его вкладки (открывается, если закрыт)
  TDfmMoveGetText = function(const AFile: string): string of object;
  // Новые тексты модуля и .dfm - во вкладки, на диск - по Save
  TDfmMoveSetTexts = procedure(const APasFile, APasText, ADfmFile,
    ADfmText: string) of object;
  // Перенос или его откат сделан: перечитать дерево объектов и разбор
  TDfmMoveDone = procedure of object;

  // Что окну разбора нужно от IDE
  TDfmMoveHost = record
    GoLine: TDfmMoveGoLine;
    GetText: TDfmMoveGetText;
    SetTexts: TDfmMoveSetTexts;
    Done: TDfmMoveDone;
  end;

// Окно с результатом разбора. Немодальное: пока оно открыто, можно ходить
// по коду - щелчок по компоненту ставит редактор на строку его создания,
// щелчок по строке «N: ...» в подробностях - на строку N. «Сохранить...»
// пишет весь разбор в текстовый файл. «Перенести» переносит отмеченные
// компоненты, «Отменить перенос» возвращает тексты до последнего переноса
// этого модуля. Окно забирает AList себе (освободит при закрытии); прежнее
// такое окно закрывается. APasFile, ADfmFile - полные пути модуля и
// формы; APasText, ADfmText - их тексты, по которым сделан разбор.
procedure DfmMoveShowReport(AList: TList; const APasFile, ADfmFile,
  AFormClass, APasText, ADfmText: string; const AHost: TDfmMoveHost);

implementation

uses
  StrUtils, TypInfo, Dialogs, Menus, ObjParse, FormDesigner, UiTheme,
  UiButton, UiStdCtrls, UiEditCtrls, UiComCtrls, UiDialogs;

const
  // Номер сборки модуля: пишется в файл разбора рядом с датой, чтобы было
  // видно, какой версией DfmMove сделан разбор. Растёт с каждой правкой.
  DfmMoveBuild = 'b.20';

constructor TMoveInfo.Create;
begin
  inherited Create;
  CreateLine := -1;
  MoveLines := TStringList.Create;
  KeepLines := TStringList.Create;
  Handlers := TStringList.Create;
  Notes := TStringList.Create;
  ChildAdds := TStringList.Create;
  RefLines := TStringList.Create;
  Items := TList.Create;
  NilChecks := TStringList.Create;
  NilRisk := TStringList.Create;
  NestLine := -1;
  LazyGroup := -1;
  LazyEnd := -1;
  LocalDecl := -1;
  LocalVarLine := -1;
  ReuseEnd := -1;
  OrderGroup := -1;
  OrderEnd := -1;
  HelperGroup := -1;
end;

destructor TMoveInfo.Destroy;
var
  Index: Integer;
begin
  for Index := 0 to Items.Count - 1 do
    TObject(Items[Index]).Free;
  Items.Free;
  UnrollArgs.Free;
  if OwnsNode then
    Node.Free;
  if ExtraNodes <> nil then
  begin
    for Index := 0 to ExtraNodes.Count - 1 do
      TObject(ExtraNodes[Index]).Free;
    ExtraNodes.Free;
  end;
  NilRisk.Free;
  NilChecks.Free;
  RefLines.Free;
  ChildAdds.Free;
  Notes.Free;
  Handlers.Free;
  KeepLines.Free;
  MoveLines.Free;
  inherited Destroy;
end;

// ---------------------------------------------------------------------------
//  Разбор строк кода
// ---------------------------------------------------------------------------

function LeadSpacesOf(const S: string): Integer;
begin
  Result := 0;
  while (Result < Length(S)) and (S[Result + 1] = ' ') do
    Inc(Result);
end;

function IsIdentChar(C: Char): Boolean;
begin
  Result := C in ['A'..'Z', 'a'..'z', '0'..'9', '_'];
end;

// Есть ли в строке слово AWord (целиком, без учёта регистра), вне
// комментария //
function HasWord(const ALine, AWord: string): Boolean;
var
  Upper, W: string;
  P, Cut: Integer;
begin
  Result := False;
  Upper := UpperCase(ALine);
  Cut := Pos('//', Upper);
  if Cut > 0 then
    Upper := Copy(Upper, 1, Cut - 1);
  W := UpperCase(AWord);
  P := Pos(W, Upper);
  while P > 0 do
  begin
    if ((P = 1) or not IsIdentChar(Upper[P - 1])) and
       ((P + Length(W) > Length(Upper)) or
        not IsIdentChar(Upper[P + Length(W)])) then
    begin
      Result := True;
      Exit;
    end;
    P := PosEx(W, Upper, P + 1);
  end;
end;

// Строка без комментария // в конце; // внутри строки в кавычках ('http://')
// комментарием не считается
function StripComment(const ALine: string): string;
var
  Index: Integer;
  InQuote: Boolean;
begin
  Result := ALine;
  InQuote := False;
  for Index := 1 to Length(ALine) - 1 do
  begin
    if ALine[Index] = '''' then
      InQuote := not InQuote
    else if not InQuote and (ALine[Index] = '/') and
            (ALine[Index + 1] = '/') then
    begin
      Result := TrimRight(Copy(ALine, 1, Index - 1));
      Exit;
    end;
  end;
end;

// Строки объявления класса формы: заголовок и end; -1 - не нашлось
procedure FindClassDecl(ALines: TStrings; const AFormClass: string;
  var AFirst, ALast: Integer);
var
  Index: Integer;
  T: string;
begin
  AFirst := -1;
  ALast := -1;
  for Index := 0 to ALines.Count - 1 do
  begin
    T := UpperCase(Trim(ALines[Index]));
    if (Pos(UpperCase(AFormClass) + ' = CLASS', T) = 1) or
       (Pos(UpperCase(AFormClass) + '=CLASS', T) = 1) then
    begin
      AFirst := Index;
      Break;
    end;
  end;
  if AFirst < 0 then
    Exit;
  for Index := AFirst + 1 to ALines.Count - 1 do
    if UpperCase(Trim(ALines[Index])) = 'END;' then
    begin
      ALast := Index;
      Exit;
    end;
end;

// AName - поле класса формы (строка объявления с ним и двоеточием)
function IsFormField(ALines: TStrings; AFirst, ALast: Integer;
  const AName: string): Boolean;
var
  Index: Integer;
  T: string;
begin
  Result := False;
  if AFirst < 0 then
    Exit;
  for Index := AFirst + 1 to ALast - 1 do
  begin
    // Без комментария: скобки в нём - не признак метода
    T := Trim(StripComment(ALines[Index]));
    if (Pos(':', T) > 0) and (Pos('(', T) = 0) and HasWord(T, AName) and
       (Pos('PROCEDURE', UpperCase(T)) <> 1) and
       (Pos('FUNCTION', UpperCase(T)) <> 1) and
       (Pos('PROPERTY', UpperCase(T)) <> 1) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

// Строка реализации метода формы AMethod (procedure TForm1.AMethod); -1
function FindMethodImpl(ALines: TStrings; const AFormClass,
  AMethod: string): Integer;
var
  Index: Integer;
  T, Head: string;
begin
  Result := -1;
  Head := UpperCase(AFormClass + '.' + AMethod);
  for Index := 0 to ALines.Count - 1 do
  begin
    T := UpperCase(Trim(ALines[Index]));
    if ((Pos('PROCEDURE ', T) = 1) or (Pos('FUNCTION ', T) = 1) or
        (Pos('CONSTRUCTOR ', T) = 1)) and
       (Pos(Head, T) > 0) and
       not IsIdentChar((T + ' ')[Pos(Head, T) + Length(Head)]) then
    begin
      Result := Index;
      Exit;
    end;
  end;
end;

// Процедура формы, в которой стоит строка ALine: её имя, строка
// заголовка и строка end; закрывающего её тела
procedure EnclosingRoutine(ALines: TStrings; const AFormClass: string;
  ALine: Integer; var AName: string; var AHead, AEnd: Integer);
var
  Index, Dot, Stop: Integer;
  T: string;
begin
  AName := '';
  AHead := -1;
  AEnd := -1;
  for Index := ALine downto 0 do
  begin
    T := ALines[Index];
    if (LeadSpacesOf(T) = 0) and
       ((Pos('PROCEDURE ', UpperCase(T)) = 1) or
        (Pos('FUNCTION ', UpperCase(T)) = 1) or
        (Pos('CONSTRUCTOR ', UpperCase(T)) = 1)) then
    begin
      AHead := Index;
      Dot := Pos('.', T);
      if (Dot > 0) and
         (CompareText(Trim(Copy(T, Pos(' ', T) + 1, Dot - Pos(' ', T) - 1)),
                      AFormClass) = 0) then
      begin
        Stop := Dot + 1;
        while (Stop <= Length(T)) and IsIdentChar(T[Stop]) do
          Inc(Stop);
        AName := Copy(T, Dot + 1, Stop - Dot - 1);
      end;
      Break;
    end;
  end;
  if AHead < 0 then
    Exit;
  for Index := ALine to ALines.Count - 1 do
    if (LeadSpacesOf(ALines[Index]) = 0) and
       (UpperCase(Trim(ALines[Index])) = 'END;') then
    begin
      AEnd := Index;
      Exit;
    end;
end;

// Сколько раз метод формы вызывается и назначается обработчиком (вне
// своего объявления и заголовка реализации)
procedure CountUses(ALines: TStrings; const AMethod: string;
  var ACalls, AAssigns: Integer);
var
  Index, P: Integer;
  T, U: string;
begin
  ACalls := 0;
  AAssigns := 0;
  for Index := 0 to ALines.Count - 1 do
  begin
    T := Trim(ALines[Index]);
    U := UpperCase(T);
    if (Pos('PROCEDURE ', U) = 1) or (Pos('FUNCTION ', U) = 1) or
       (Pos('CONSTRUCTOR ', U) = 1) or (Pos('//', U) = 1) then
      Continue;
    if not HasWord(T, AMethod) then
      Continue;
    P := Pos(':=', T);
    if (P > 0) and HasWord(Copy(T, P + 2, MaxInt), AMethod) and
       (Pos('(', Copy(T, P + 2, MaxInt)) = 0) then
      Inc(AAssigns)
    else
      Inc(ACalls);
  end;
end;

// Значение - константа, которую можно записать в .dfm: число, строка в
// кавычках, True/False, имя вида alTop / clRed / fsBold, набор [..] из них
function IsLiteral(const AValue: string): Boolean;
var
  V, Item: string;
  Index, Tail: Integer;
  Parts: TStringList;
begin
  V := Trim(AValue);
  Result := False;
  if V = '' then
    Exit;
  // Число
  if (V[1] in ['0'..'9', '-', '$']) then
  begin
    for Index := 2 to Length(V) do
      if not (V[Index] in ['0'..'9', 'A'..'F', 'a'..'f', '.']) then
        Exit;
    Result := True;
    Exit;
  end;
  // Строка: 'abc', 'a'#13'b', 'Ctrl+Z'. Только части в кавычках и коды
  // #13, #$0D подряд; склейка через + вне кавычек - не константа.
  if V[1] in ['''', '#'] then
  begin
    Index := 1;
    while Index <= Length(V) do
      if V[Index] = '''' then
      begin
        // до закрывающей кавычки; '' внутри - одна кавычка
        Inc(Index);
        while True do
        begin
          if Index > Length(V) then
            Exit;             // строка не закрыта
          if V[Index] = '''' then
          begin
            if (Index < Length(V)) and (V[Index + 1] = '''') then
              Inc(Index, 2)
            else
              Break;
          end
          else
            Inc(Index);
        end;
        Inc(Index);
      end
      else if V[Index] = '#' then
      begin
        Inc(Index);
        Tail := Index;
        if (Index <= Length(V)) and (V[Index] = '$') then
        begin
          Inc(Index);
          while (Index <= Length(V)) and
                (V[Index] in ['0'..'9', 'A'..'F', 'a'..'f']) do
            Inc(Index);
        end
        else
          while (Index <= Length(V)) and (V[Index] in ['0'..'9']) do
            Inc(Index);
        if Index = Tail then
          Exit;               // # без кода
      end
      else
        Exit;                 // что-то вне кавычек: +, пробел, имя
    Result := True;
    Exit;
  end;
  if (CompareText(V, 'True') = 0) or (CompareText(V, 'False') = 0) then
  begin
    Result := True;
    Exit;
  end;
  // Набор
  if (V[1] = '[') and (V[Length(V)] = ']') then
  begin
    Parts := TStringList.Create;
    try
      Parts.CommaText := Copy(V, 2, Length(V) - 2);
      for Index := 0 to Parts.Count - 1 do
      begin
        Item := Trim(Parts[Index]);
        if (Item <> '') and not IsLiteral(Item) then
          Exit;
      end;
    finally
      Parts.Free;
    end;
    Result := True;
    Exit;
  end;
  // Значение перечисления: две-три строчные буквы и заглавная (alTop,
  // clBtnFace, bsNone, poScreenCenter, taCenter)
  Index := 1;
  while (Index <= Length(V)) and (V[Index] in ['a'..'z']) do
    Inc(Index);
  Result := (Index in [3, 4]) and (Index <= Length(V)) and
            (V[Index] in ['A'..'Z']);
  if Result then
    for Tail := Index to Length(V) do
      if not IsIdentChar(V[Tail]) then
      begin
        Result := False;
        Exit;
      end;
end;

// Аргументы вызова X.SetBounds(1, 2, 3, 4) - все константы
function CallArgsLiteral(const ACall: string): Boolean;
var
  Open, Close, Index: Integer;
  Args: TStringList;
begin
  Result := False;
  Open := Pos('(', ACall);
  Close := LastDelimiter(')', ACall);
  if (Open = 0) or (Close < Open) then
    Exit;
  Args := TStringList.Create;
  try
    Args.CommaText := Copy(ACall, Open + 1, Close - Open - 1);
    for Index := 0 to Args.Count - 1 do
      if not IsLiteral(Args[Index]) then
        Exit;
    Result := True;
  finally
    Args.Free;
  end;
end;

// Код клавиши по имени VK_... (для ShortCut(VK_F5, [])); -1 - не знаем
function VirtualKeyValue(const AName: string): Integer;
const
  KeyNames: array[0..27] of string = (
    'VK_F1', 'VK_F2', 'VK_F3', 'VK_F4', 'VK_F5', 'VK_F6', 'VK_F7', 'VK_F8',
    'VK_F9', 'VK_F10', 'VK_F11', 'VK_F12', 'VK_INSERT', 'VK_DELETE',
    'VK_HOME', 'VK_END', 'VK_PRIOR', 'VK_NEXT', 'VK_LEFT', 'VK_UP',
    'VK_RIGHT', 'VK_DOWN', 'VK_RETURN', 'VK_ESCAPE', 'VK_TAB', 'VK_BACK',
    'VK_SPACE', 'VK_APPS');
  KeyCodes: array[0..27] of Integer = (
    VK_F1, VK_F2, VK_F3, VK_F4, VK_F5, VK_F6, VK_F7, VK_F8,
    VK_F9, VK_F10, VK_F11, VK_F12, VK_INSERT, VK_DELETE,
    VK_HOME, VK_END, VK_PRIOR, VK_NEXT, VK_LEFT, VK_UP,
    VK_RIGHT, VK_DOWN, VK_RETURN, VK_ESCAPE, VK_TAB, VK_BACK,
    VK_SPACE, VK_APPS);
var
  KeyIndex: Integer;
begin
  Result := -1;
  for KeyIndex := Low(KeyNames) to High(KeyNames) do
    if CompareText(AName, KeyNames[KeyIndex]) = 0 then
    begin
      Result := KeyCodes[KeyIndex];
      Exit;
    end;
end;

// Значение ShortCut(Клавиша, [ssCtrl, ...]) из одних констант: клавиша -
// Word('Z'), Ord('Z'), число или VK_...; набор - из ssShift, ssCtrl, ssAlt.
// В .dfm сочетание пишется числом: ANumber (Ctrl+Z = 16474).
function ShortCutValue(const AValue: string; var ANumber: Integer): Boolean;
const
  ShiftBit = $2000;   // scShift из Menus
  CtrlBit = $4000;    // scCtrl
  AltBit = $8000;     // scAlt
var
  Value, Inner, KeyText, CharText, ShiftText, Item: string;
  Bracket, Open, Key, ErrorAt, ItemIndex: Integer;
  ShiftItems: TStringList;
begin
  Result := False;
  ANumber := 0;
  Value := Trim(AValue);
  if (CompareText(Copy(Value, 1, 9), 'ShortCut(') <> 0) or
     (Value[Length(Value)] <> ')') then
    Exit;
  Inner := Trim(Copy(Value, 10, Length(Value) - 10));
  // Набор - последний аргумент: [..] в конце
  Bracket := LastDelimiter('[', Inner);
  if (Bracket = 0) or (Inner[Length(Inner)] <> ']') then
    Exit;
  ShiftText := Copy(Inner, Bracket + 1, Length(Inner) - Bracket - 1);
  KeyText := TrimRight(Copy(Inner, 1, Bracket - 1));
  if (KeyText = '') or (KeyText[Length(KeyText)] <> ',') then
    Exit;
  KeyText := Trim(Copy(KeyText, 1, Length(KeyText) - 1));
  if KeyText = '' then
    Exit;

  // Клавиша
  Key := -1;
  if (CompareText(Copy(KeyText, 1, 5), 'Word(') = 0) or
     (CompareText(Copy(KeyText, 1, 4), 'Ord(') = 0) then
  begin
    Open := Pos('(', KeyText);
    CharText := Trim(Copy(KeyText, Open + 1, Length(KeyText) - Open - 1));
    if (KeyText[Length(KeyText)] = ')') and (Length(CharText) = 3) and
       (CharText[1] = '''') and (CharText[3] = '''') then
      Key := Ord(CharText[2]);
  end
  else if KeyText[1] in ['0'..'9', '$'] then
  begin
    Val(KeyText, Key, ErrorAt);
    if ErrorAt <> 0 then
      Key := -1;
  end
  else
    Key := VirtualKeyValue(KeyText);
  if (Key < 0) or (Key > $FF) then
    Exit;

  // Набор ssShift, ssCtrl, ssAlt
  ANumber := Key;
  ShiftItems := TStringList.Create;
  try
    ShiftItems.CommaText := ShiftText;
    for ItemIndex := 0 to ShiftItems.Count - 1 do
    begin
      Item := Trim(ShiftItems[ItemIndex]);
      if Item = '' then
        Continue;
      if CompareText(Item, 'ssShift') = 0 then
        ANumber := ANumber or ShiftBit
      else if CompareText(Item, 'ssCtrl') = 0 then
        ANumber := ANumber or CtrlBit
      else if CompareText(Item, 'ssAlt') = 0 then
        ANumber := ANumber or AltBit
      else
        Exit;
    end;
  finally
    ShiftItems.Free;
  end;
  Result := True;
end;

// «раз» или «раза» после числа: 1 раз, 2 раза, 5 раз, 22 раза
function TimesWord(ANumber: Integer): string;
begin
  if (ANumber mod 100 in [11..14]) or not (ANumber mod 10 in [2..4]) then
    Result := 'раз'
  else
    Result := 'раза';
end;

// Имя свойства как в .dfm: Name или Font.Size - идентификаторы через точку,
// без индексов и вызовов (Panels[1].Width, Items.Add - не свойство .dfm)
function IsPropPath(const APath: string): Boolean;
var
  Rest, Part: string;
  Dot: Integer;
begin
  Result := False;
  Rest := APath;
  repeat
    Dot := Pos('.', Rest);
    if Dot > 0 then
    begin
      Part := Copy(Rest, 1, Dot - 1);
      Delete(Rest, 1, Dot);
    end
    else
    begin
      Part := Rest;
      Rest := '';
    end;
    if not IsValidIdent(Part) then
      Exit;
  until Rest = '';
  Result := True;
end;

// Свойство APath (Caption, Font.Size) у класса AClass published и его можно
// записать: по RTTI - только published, у последней части пути нужен
// SetProc, промежуточные - свойства-объекты (Font). Результат - RTTI
// последней части пути; nil - не published или только для чтения.
function PublishedProp(AClass: TClass; const APath: string): PPropInfo;
var
  Rest, Part: string;
  Dot: Integer;
  Info: PPropInfo;
begin
  Result := nil;
  Rest := APath;
  while AClass <> nil do
  begin
    Dot := Pos('.', Rest);
    if Dot > 0 then
    begin
      Part := Copy(Rest, 1, Dot - 1);
      Delete(Rest, 1, Dot);
    end
    else
    begin
      Part := Rest;
      Rest := '';
    end;
    Info := GetPropInfo(AClass, Part);
    if Info = nil then
      Exit;
    if Rest = '' then
    begin
      if Info^.SetProc <> nil then
        Result := Info;
      Exit;
    end;
    if Info^.PropType^^.Kind <> tkClass then
      Exit;
    AClass := GetTypeData(Info^.PropType^)^.ClassType;
  end;
end;

// Строка - добавление в меню или список: P.Add(X), P.Items.Add(X),
// P.Insert(N, X), P.Items.Insert(N, X). AParent - P без .Items, AChild - X.
// ALine - без комментария и пробелов по краям.
function ParseAddLine(const ALine: string; var AParent, AChild: string): Boolean;
var
  Upper, Args: string;
  At, Open, Close: Integer;
  IsAdd: Boolean;
  Parts: TStringList;
begin
  Result := False;
  AParent := '';
  AChild := '';
  if (ALine = '') or (ALine[Length(ALine)] <> ';') then
    Exit;
  Upper := UpperCase(ALine);
  At := Pos('.ADD(', Upper);
  IsAdd := At > 0;
  if not IsAdd then
    At := Pos('.INSERT(', Upper);
  if At = 0 then
    Exit;
  AParent := Trim(Copy(ALine, 1, At - 1));
  if CompareText(Copy(AParent, Length(AParent) - 5, 6), '.Items') = 0 then
    Delete(AParent, Length(AParent) - 5, 6);
  if not IsValidIdent(AParent) then
    Exit;
  Open := PosEx('(', ALine, At);
  Close := LastDelimiter(')', ALine);
  // После скобки - только ;
  if (Open = 0) or (Close < Open) or
     (Trim(Copy(ALine, Close + 1, MaxInt)) <> ';') then
    Exit;
  Args := Copy(ALine, Open + 1, Close - Open - 1);
  Parts := TStringList.Create;
  try
    CodeSplitArgs(Args, Parts);
    if IsAdd then
    begin
      if Parts.Count <> 1 then
        Exit;
      AChild := Trim(Parts[0]);
    end
    else
    begin
      if Parts.Count <> 2 then
        Exit;
      AChild := Trim(Parts[1]);
    end;
  finally
    Parts.Free;
  end;
  Result := IsValidIdent(AChild);
end;

// Строка P.Remove(X); или P.Items.Remove(X); - AParent = P, AChild = X
function ParseRemoveLine(const ALine: string; var AParent, AChild: string): Boolean;
var
  Upper: string;
  At, Close: Integer;
begin
  Result := False;
  AParent := '';
  AChild := '';
  if (ALine = '') or (ALine[Length(ALine)] <> ';') then
    Exit;
  Upper := UpperCase(ALine);
  At := Pos('.REMOVE(', Upper);
  if At = 0 then
    Exit;
  AParent := Trim(Copy(ALine, 1, At - 1));
  if CompareText(Copy(AParent, Length(AParent) - 5, 6), '.Items') = 0 then
    Delete(AParent, Length(AParent) - 5, 6);
  Close := LastDelimiter(')', ALine);
  if (Close < At) or (Trim(Copy(ALine, Close + 1, MaxInt)) <> ';') then
    Exit;
  AChild := Trim(Copy(ALine, At + 8, Close - At - 8));
  Result := IsValidIdent(AParent) and IsValidIdent(AChild);
end;

// ---------------------------------------------------------------------------
//  Разбор компонентов
// ---------------------------------------------------------------------------

// Строка кода, уходящая в .dfm, - в разбор компонента
procedure AddMoveItem(Info: TMoveInfo; ALineIndex: Integer;
  AKind: TMoveLineKind; const APropName, AValue: string);
var
  Item: TMoveLine;
begin
  Item := TMoveLine.Create;
  Item.LineIndex := ALineIndex;
  Item.Kind := AKind;
  Item.PropName := APropName;
  Item.Value := AValue;
  Info.Items.Add(Item);
end;

// Константа из кода - так, как её пишет в .dfm Delphi: шестнадцатеричное
// число ($00F0F0F0) - десятичным, остальное (строки 'a'#9'b', числа,
// True, alTop, наборы [..]) - как есть
function DfmLiteral(const AValue: string): string;
var
  Number: Int64;
  ErrorAt: Integer;
begin
  Result := Trim(AValue);
  if (Result <> '') and (Result[1] = '$') then
  begin
    Val(Result, Number, ErrorAt);
    if ErrorAt = 0 then
      Result := IntToStr(Number);
  end;
end;

type
  TBoundsArgs = array[0..3] of string;

// Аргументы SetBounds(Left, Top, Width, Height)
function BoundsArgs(const ACall: string; var AArgs: TBoundsArgs): Boolean;
var
  Open, Close, Index: Integer;
  Parts: TStringList;
begin
  Result := False;
  Open := Pos('(', ACall);
  Close := LastDelimiter(')', ACall);
  if (Open = 0) or (Close < Open) then
    Exit;
  Parts := TStringList.Create;
  try
    CodeSplitArgs(Copy(ACall, Open + 1, Close - Open - 1), Parts);
    if Parts.Count <> 4 then
      Exit;
    for Index := 0 to 3 do
      AArgs[Index] := Trim(Parts[Index]);
    Result := True;
  finally
    Parts.Free;
  end;
end;

// Разбор компонента для переноса - пустой: строк, уходящих в .dfm, нет
procedure ClearMoveData(Info: TMoveInfo);
var
  Index: Integer;
begin
  for Index := 0 to Info.Items.Count - 1 do
    TObject(Info.Items[Index]).Free;
  Info.Items.Clear;
  Info.MoveLines.Clear;
  Info.KeepLines.Clear;
  Info.RefLines.Clear;
  Info.Handlers.Clear;
  Info.ChildAdds.Clear;
  Info.NestParent := '';
  Info.NestLine := -1;
end;

function LineRef(ALines: TStrings; AIndex: Integer): string;
begin
  Result := IntToStr(AIndex + 1) + ': ' + Trim(ALines[AIndex]);
end;

// Класс - окно: TForm и его наследники по имени (TForm, TFormX, TMyForm)
function IsFormClass(const AClassName: string): Boolean;
var
  Upper: string;
begin
  Upper := UpperCase(AClassName);
  Result := (Upper = 'TFORM') or (Pos('TFORM', Upper) = 1) or
            ((Length(Upper) > 4) and (Copy(Upper, Length(Upper) - 3, 4) = 'FORM'));
end;

// Первое слово строки кода заглавными: PROCEDURE, PRIVATE, END...
function FirstWordOf(const ALine: string): string;
var
  Code: string;
  Stop: Integer;
begin
  Code := UpperCase(Trim(StripComment(ALine)));
  Stop := 1;
  while (Stop <= Length(Code)) and IsIdentChar(Code[Stop]) do
    Inc(Stop);
  Result := Copy(Code, 1, Stop - 1);
end;

// ---------------------------------------------------------------------------
//  Помощники: функции, которые создают компонент (MakeItem)
// ---------------------------------------------------------------------------

// В строке-ключе есть APattern, и он не часть более длинного имени: перед
// ним и после него (если он с этого края начинается или кончается буквой)
// - не буква, не цифра, не _
function HasPattern(const AKey, APattern: string): Boolean;
var
  At, After: Integer;
begin
  Result := False;
  At := Pos(APattern, AKey);
  while At > 0 do
  begin
    After := At + Length(APattern);
    if ((At = 1) or not IsIdentChar(APattern[1]) or
        not IsIdentChar(AKey[At - 1])) and
       ((After > Length(AKey)) or
        not IsIdentChar(APattern[Length(APattern)]) or
        not IsIdentChar(AKey[After])) then
    begin
      Result := True;
      Exit;
    end;
    At := PosEx(APattern, AKey, At + 1);
  end;
end;

// Цепочки имён в строке кода (без комментария): A.B.C - одной строкой
// заглавными, по порядку. Строки в кавычках, числа и {...} пропускаются;
// имя после ']' или ')' с точкой (A[0].B, F(X).B) - член того, что слева,
// отдельной цепочкой не считается.
procedure ScanChains(const ACode: string; AChains: TStrings);
var
  At, Start: Integer;
  Chain: string;
  AfterClose: Boolean;
begin
  AChains.Clear;
  At := 1;
  AfterClose := False;
  while At <= Length(ACode) do
    case ACode[At] of
      '''':
        begin
          Inc(At);
          while (At <= Length(ACode)) and (ACode[At] <> '''') do
            Inc(At);
          Inc(At);
          AfterClose := False;
        end;
      '{':
        begin
          while (At <= Length(ACode)) and (ACode[At] <> '}') do
            Inc(At);
          Inc(At);
        end;
      '0'..'9', '#', '$':
        begin
          Inc(At);
          while (At <= Length(ACode)) and IsIdentChar(ACode[At]) do
            Inc(At);
          AfterClose := False;
        end;
      ']', ')':
        begin
          Inc(At);
          AfterClose := True;
        end;
      '.':
        begin
          Inc(At);
          // член результата: A[0].B - B пропускается
          if AfterClose then
            while (At <= Length(ACode)) and IsIdentChar(ACode[At]) do
              Inc(At);
        end;
      'A'..'Z', 'a'..'z', '_':
        begin
          Start := At;
          while (At <= Length(ACode)) and IsIdentChar(ACode[At]) do
            Inc(At);
          while (At < Length(ACode)) and (ACode[At] = '.') and
                (ACode[At + 1] in ['A'..'Z', 'a'..'z', '_']) do
          begin
            Inc(At);
            while (At <= Length(ACode)) and IsIdentChar(ACode[At]) do
              Inc(At);
          end;
          Chain := UpperCase(Copy(ACode, Start, At - Start));
          AChains.Add(Chain);
          AfterClose := False;
        end;
    else
      begin
        if not (ACode[At] in [' ', #9]) then
          AfterClose := False;
        Inc(At);
      end;
    end;
end;

// Первое имя цепочки (A.B.C -> A)
function ChainHead(const AChain: string): string;
begin
  if Pos('.', AChain) > 0 then
    Result := Copy(AChain, 1, Pos('.', AChain) - 1)
  else
    Result := AChain;
end;

// Целое выражение из чисел и имён со значениями в AValues (ИМЯ=число,
// имена заглавными), через + и -: Row1 + 3, X + 4, 110. Имя может быть
// с точкой (BTNCOMPILERUN.LEFT=6) - тогда оно ищется в AValues целиком.
// Скобки, умножение, вызовы - False.
function EvalIntExpr(const AExpr: string; AValues: TStrings;
  var AResult: Integer): Boolean;
var
  Text, Token: string;
  At, Start, Sign, Term: Integer;
  Expect: Boolean;     // ждём слагаемое (а не знак)
begin
  Result := False;
  AResult := 0;
  Text := Trim(AExpr);
  if Text = '' then
    Exit;
  At := 1;
  Sign := 1;
  Expect := True;
  while At <= Length(Text) do
  begin
    case Text[At] of
      ' ', #9:
        Inc(At);
      '+', '-':
        begin
          if Expect then
          begin
            // унарный знак
            if Text[At] = '-' then
              Sign := -Sign;
          end
          else
          begin
            if Text[At] = '-' then
              Sign := -1
            else
              Sign := 1;
            Expect := True;
          end;
          Inc(At);
        end;
      '0'..'9', '$':
        begin
          if not Expect then
            Exit;
          Start := At;
          Inc(At);
          while (At <= Length(Text)) and
                (Text[At] in ['0'..'9', 'A'..'F', 'a'..'f']) do
            Inc(At);
          Token := Copy(Text, Start, At - Start);
          // Десятичное - только цифры; $ - шестнадцатеричное
          if Token[1] <> '$' then
            for Term := 1 to Length(Token) do
              if not (Token[Term] in ['0'..'9']) then
                Exit;
          Term := StrToIntDef(Token, MaxInt);
          if Term = MaxInt then
            Exit;
          AResult := AResult + Sign * Term;
          Sign := 1;
          Expect := False;
        end;
      'A'..'Z', 'a'..'z', '_':
        begin
          if not Expect then
            Exit;
          Start := At;
          while (At <= Length(Text)) and IsIdentChar(Text[At]) do
            Inc(At);
          // Имя со свойством (A.Left) - одним именем
          while (At < Length(Text)) and (Text[At] = '.') and
                (Text[At + 1] in ['A'..'Z', 'a'..'z', '_']) do
          begin
            Inc(At);
            while (At <= Length(Text)) and IsIdentChar(Text[At]) do
              Inc(At);
          end;
          // Вызов, индекс - не константа
          if (At <= Length(Text)) and (Text[At] in ['.', '(', '[']) then
            Exit;
          Token := AValues.Values[UpperCase(Copy(Text, Start, At - Start))];
          if Token = '' then
            Exit;
          Term := StrToIntDef(Token, MaxInt);
          if Term = MaxInt then
            Exit;
          AResult := AResult + Sign * Term;
          Sign := 1;
          Expect := False;
        end;
    else
      Exit;
    end;
  end;
  Result := not Expect;
end;

type
  // Функция-помощник модуля и то, что она делает с созданным компонентом.
  // Переносится только простой: в теле лишь Result := TКласс.Create(...),
  // Result.Свойство := параметр или константа, Result.Parent := ... и
  // Родитель.Add(Result) / Insert. Значения свойств у каждого вызова - из
  // его аргументов.
  THelperInfo = class
  public
    Name, Cls: string;
    Params: TStringList;      // имена параметров по порядку
    Simple: Boolean;
    Problem: string;          // почему не простой
    OwnerExpr: string;        // владелец: параметр или Self
    NestExpr: string;         // родитель: параметр или имя; '' - нет
    PropNames: TStringList;   // свойства в порядке тела
    PropExprs: TStringList;   // их значения: параметр или константа
    // Колонки списка (with Result.Columns.Add do begin ... end): по строке
    // на блок, в ней «Свойство<#9>выражение» через #10. Objects = 1 - блок
    // в цикле for LoopVar := 0 to High(LoopArray) do: выражения вида
    // Массив[LoopVar] берут элемент массива-аргумента.
    Columns: TStringList;
    LoopVar, LoopArray: string;
    // Последняя строка помощника - Inc(Переменная, Выражение) по
    // переменной вызывающей процедуры (Inc(X, W + 3) в MakeBtn): после
    // каждого вызова X сдвигается. '' - нет.
    IncVar, IncExpr: string;
    // Процедура-создатель: компонент создаётся в ней и отдаётся через
    // var-параметр (MakeCmpButton(btnViewUnit, ...)). OutIdx - номер этого
    // параметра, -1 - обычная функция-помощник. Такая процедура при
    // переносе остаётся: из неё уходят создание, родитель и свойства, а
    // прочие строки (значок, сдвиг следующей кнопки) остаются.
    OutIdx: Integer;
    OutName: string;
    HdrLine, HeadEnd, BodyStart, BodyEnd: Integer;
    Nested: Boolean;          // вложена в процедуру формы (ConfigureButton)
    Stmts: TList;             // THelperStmt - операторы тела по порядку
    Consts: TStringList;      // её целые константы: ИМЯ=число
    LocalNames: TStringList;  // её локальные имена (заглавными)
    VarParams: TStringList;   // var/out-параметры (заглавными)
    // Сдвиг параметра (ALeft := ALeft + ABtn.Width + 1): его номер, -1 -
    // нет; выражение сдвига - в IncExpr
    IncParam: Integer;
    // Имена, которые встречаются в остающихся строках (заглавными): после
    // вызова их посчитанные значения у вызывающей процедуры не верны
    Clobbers: TStringList;
    // Условие свойства (if ATag <> 0 then It.OnClick := ...) - по строке на
    // свойство PropNames, '' - без условия
    PropConds: TStringList;
    // Процедура формы, которая создаёт компонент в своей локальной
    // переменной LocalName и вызывается несколько раз
    // (AddLogPopupItem('&Undo', 1)): каждый вызов - свой компонент. Строки
    // её тела (BodyLines, номера в Objects) уходят вместе со всеми
    // вызовами.
    LocalCreator: Boolean;
    LocalName: string;
    BodyLines: TList;
    constructor Create;
    destructor Destroy; override;
  end;

  // Оператор тела процедуры-создателя
  THelperStmtKind = (hsCreate, hsParent, hsProp, hsInc, hsOther);
  THelperStmt = class
  public
    Kind: THelperStmtKind;
    First, Last: Integer;     // строки модуля
    PropName, Expr: string;   // hsProp: Свойство := Выражение; hsParent -
                              // выражение родителя
    Chains: TStringList;      // цепочки имён оператора
    Moves: Boolean;           // уходит в .dfm (решает разбор группы)
    // Компонент целиком в операторе - только аргументом процедур, которые
    // не меняют его места и размеров (SetToolGlyph(ABtn, AKind)): его
    // Left, Top, Width, Height после оператора прежние
    BareSafe: Boolean;
    constructor Create;
    destructor Destroy; override;
  end;

constructor THelperStmt.Create;
begin
  inherited Create;
  Chains := TStringList.Create;
end;

destructor THelperStmt.Destroy;
begin
  Chains.Free;
  inherited Destroy;
end;

constructor THelperInfo.Create;
begin
  inherited Create;
  Params := TStringList.Create;
  PropNames := TStringList.Create;
  PropExprs := TStringList.Create;
  Columns := TStringList.Create;
  Stmts := TList.Create;
  Consts := TStringList.Create;
  LocalNames := TStringList.Create;
  VarParams := TStringList.Create;
  Clobbers := TStringList.Create;
  PropConds := TStringList.Create;
  BodyLines := TList.Create;
  OutIdx := -1;
  IncParam := -1;
  HdrLine := -1;
  HeadEnd := -1;
  BodyStart := -1;
  BodyEnd := -1;
end;

destructor THelperInfo.Destroy;
var
  Index: Integer;
begin
  for Index := 0 to Stmts.Count - 1 do
    TObject(Stmts[Index]).Free;
  Stmts.Free;
  Consts.Free;
  LocalNames.Free;
  VarParams.Free;
  Clobbers.Free;
  PropConds.Free;
  BodyLines.Free;
  Columns.Free;
  PropExprs.Free;
  PropNames.Free;
  Params.Free;
  inherited Destroy;
end;

procedure FreeHelpers(AHelpers: TList);
var
  Index: Integer;
begin
  for Index := 0 to AHelpers.Count - 1 do
    TObject(AHelpers[Index]).Free;
  AHelpers.Free;
end;

// Строка кода для поиска: без комментария, заглавными, без пробелов;
// между двумя словами - один пробел, чтобы слова не сливались
// (FreeAndNil ( X ) -> FREEANDNIL(X); if A then X.Free -> IF A THEN X.FREE)
function CodeKey(const ALine: string): string;
var
  From, Into: Integer;
  Code: string;
  Gap: Boolean;
begin
  Code := UpperCase(StripComment(ALine));
  SetLength(Result, Length(Code));
  Into := 0;
  Gap := False;
  for From := 1 to Length(Code) do
    if Code[From] in [' ', #9] then
      Gap := True
    else
    begin
      if Gap and (Into > 0) and IsIdentChar(Result[Into]) and
         IsIdentChar(Code[From]) then
      begin
        Inc(Into);
        Result[Into] := ' ';
      end;
      Gap := False;
      Inc(Into);
      Result[Into] := Code[From];
    end;
  SetLength(Result, Into);
end;

// Аргументы вызова верхнего уровня: запятые внутри строк, скобок ( ) и
// массивов [ ] не делят ("Tab, ['A', 'B'], [1, 2]" - три аргумента)
procedure SplitCallArgs(const AText: string; AArgs: TStrings);
var
  CharIndex, Depth: Integer;
  InQuote: Boolean;
  Current: string;
begin
  AArgs.Clear;
  Depth := 0;
  InQuote := False;
  Current := '';
  for CharIndex := 1 to Length(AText) do
  begin
    if AText[CharIndex] = '''' then
      InQuote := not InQuote;
    if not InQuote then
      case AText[CharIndex] of
        '(', '[':
          Inc(Depth);
        ')', ']':
          Dec(Depth);
        ',':
          if Depth = 0 then
          begin
            AArgs.Add(Trim(Current));
            Current := '';
            Continue;
          end;
      end;
    Current := Current + AText[CharIndex];
  end;
  if Trim(Current) <> '' then
    AArgs.Add(Trim(Current));
end;

// Имена через запятую (A, B, C) - в AList заглавными. False - не имена.
function SplitNameList(const AText: string; AList: TStrings): Boolean;
var
  Rest, Name: string;
  Comma: Integer;
begin
  Result := False;
  Rest := AText;
  repeat
    Comma := Pos(',', Rest);
    if Comma > 0 then
    begin
      Name := Trim(Copy(Rest, 1, Comma - 1));
      Delete(Rest, 1, Comma);
    end
    else
      Name := Trim(Rest);
    if not IsValidIdent(Name) then
      Exit;
    AList.Add(UpperCase(Name));
  until Comma = 0;
  Result := True;
end;

// Процедура-создатель (компонент отдаётся через var-параметр): заголовок,
// объявления и операторы тела. Операторы - по строкам, многострочный -
// одним (до ; при закрытых begin/end). Не разобралось - AHelper.Simple =
// False, причина - в Problem.
procedure ParseVarHelper(ALines: TStrings; AFact: TFactoryRec;
  AHelper: THelperInfo; AHeadEnd: Integer);
var
  Line, Depth, ChainIndex, Assign, CreateAt, Close, Value, Colon, Semi,
    StmtIndex, Other, Creates: Integer;
  Head, Code, Word, Section, Name, Expr, Lhs, Rhs, AddParent, AddChild,
    OutUpper, Key, Chain, ChainTail, Group: string;
  Stmt, OtherStmt: THelperStmt;
  Chains, CallArgs: TStringList;
  IsVar: Boolean;

  procedure Fail(const AText: string);
  begin
    AHelper.Simple := False;
    if AHelper.Problem = '' then
      AHelper.Problem := AText;
  end;

begin
  AHelper.OutIdx := AFact.OutIdx;
  AHelper.OutName := AFact.OutName;
  AHelper.HdrLine := AFact.HdrLine;
  AHelper.HeadEnd := AHeadEnd;
  AHelper.BodyEnd := AFact.EndLine;
  AHelper.Problem := '';
  AHelper.Simple := True;
  // Методы формы пишутся с начала строки, вложенные процедуры - с отступом
  AHelper.Nested := LeadSpacesOf(ALines[AFact.HdrLine]) > 0;
  OutUpper := UpperCase(AFact.OutName);

  // var- и out-параметры из заголовка
  Head := '';
  for Line := AFact.HdrLine to AHeadEnd do
    Head := Head + ' ' + Trim(StripComment(ALines[Line]));
  CreateAt := Pos('(', Head);
  Close := LastDelimiter(')', Head);
  if (CreateAt > 0) and (Close > CreateAt) then
  begin
    Code := Copy(Head, CreateAt + 1, Close - CreateAt - 1) + ';';
    repeat
      Semi := Pos(';', Code);
      Group := Trim(Copy(Code, 1, Semi - 1));
      Delete(Code, 1, Semi);
      IsVar := (CompareText(Copy(Group, 1, 4), 'var ') = 0) or
               (CompareText(Copy(Group, 1, 4), 'out ') = 0);
      if IsVar then
      begin
        Group := Trim(Copy(Group, 5, MaxInt));
        Colon := Pos(':', Group);
        if Colon > 0 then
          Group := Copy(Group, 1, Colon - 1);
        SplitNameList(Group, AHelper.VarParams);
      end;
    until Trim(Code) = '';
  end;

  // Тело
  AHelper.BodyStart := -1;
  for Line := AHeadEnd + 1 to AFact.EndLine - 1 do
    if FirstWordOf(ALines[Line]) = 'BEGIN' then
    begin
      AHelper.BodyStart := Line;
      Break;
    end;
  if AHelper.BodyStart < 0 then
  begin
    Fail('тело не найдено');
    Exit;
  end;

  // Объявления: целые константы - со значениями, прочее - локальные имена
  Section := '';
  for Line := AHeadEnd + 1 to AHelper.BodyStart - 1 do
  begin
    Code := Trim(StripComment(ALines[Line]));
    if Code = '' then
      Continue;
    Word := FirstWordOf(Code);
    if (Word = 'PROCEDURE') or (Word = 'FUNCTION') then
    begin
      Fail('в ней есть вложенные процедуры (строка ' + IntToStr(Line + 1) +
           ')');
      Exit;
    end;
    if (Word = 'CONST') or (Word = 'VAR') or (Word = 'TYPE') or
       (Word = 'LABEL') then
    begin
      Section := Word;
      Code := Trim(Copy(Code, Length(Word) + 1, MaxInt));
      if Code = '' then
        Continue;
    end;
    Assign := Pos('=', Code);
    Colon := Pos(':', Code);
    if (Section = 'CONST') and (Assign > 0) and
       ((Colon = 0) or (Colon > Assign)) and (Code[Length(Code)] = ';') and
       IsValidIdent(Trim(Copy(Code, 1, Assign - 1))) then
    begin
      Name := UpperCase(Trim(Copy(Code, 1, Assign - 1)));
      Expr := Trim(Copy(Code, Assign + 1, Length(Code) - Assign - 1));
      if EvalIntExpr(Expr, AHelper.Consts, Value) then
        AHelper.Consts.Values[Name] := IntToStr(Value)
      else
        AHelper.LocalNames.Add(Name);
      Continue;
    end;
    // var A, B: T; и типизированная константа (она изменяемая)
    if ((Section = 'VAR') or (Section = 'CONST')) and (Colon > 0) and
       (Code[Length(Code)] = ';') and
       SplitNameList(Copy(Code, 1, Colon - 1), AHelper.LocalNames) then
      Continue;
    Fail('объявление в строке ' + IntToStr(Line + 1) + ' не разобрано');
    Exit;
  end;

  // Операторы
  Chains := TStringList.Create;
  CallArgs := TStringList.Create;
  try
    Line := AHelper.BodyStart + 1;
    while Line <= AFact.EndLine - 1 do
    begin
      Code := Trim(StripComment(ALines[Line]));
      if Code = '' then
      begin
        Inc(Line);
        Continue;
      end;
      Stmt := THelperStmt.Create;
      AHelper.Stmts.Add(Stmt);
      Stmt.First := Line;
      Stmt.Kind := hsOther;
      Depth := 0;
      repeat
        Code := Trim(StripComment(ALines[Line]));
        if Code <> '' then
        begin
          ScanChains(Code, Chains);
          for ChainIndex := 0 to Chains.Count - 1 do
          begin
            Chain := Chains[ChainIndex];
            if (Chain = 'BEGIN') or (Chain = 'CASE') or (Chain = 'TRY') or
               (Chain = 'ASM') or (Chain = 'REPEAT') then
              Inc(Depth)
            else if (Chain = 'END') or (Chain = 'UNTIL') then
              Dec(Depth);
            Stmt.Chains.Add(Chain);
          end;
        end;
        Stmt.Last := Line;
        Inc(Line);
      until ((Depth <= 0) and (Code <> '') and (Code[Length(Code)] = ';')) or
            (Line > AFact.EndLine - 1);
      if Depth <> 0 then
      begin
        Fail('операторы в строках ' + IntToStr(Stmt.First + 1) + '..' +
             IntToStr(Stmt.Last + 1) + ' не разобраны (begin/end)');
        Exit;
      end;
      // Однострочный оператор: создание, родитель, свойство
      if Stmt.First <> Stmt.Last then
        Continue;
      Code := Trim(StripComment(ALines[Stmt.First]));
      if Code[Length(Code)] = ';' then
        Code := TrimRight(Copy(Code, 1, Length(Code) - 1));
      Assign := Pos(':=', Code);
      if (Assign > 0) and (Pos(':=', Copy(Code, Assign + 2, MaxInt)) = 0) then
      begin
        Lhs := Trim(Copy(Code, 1, Assign - 1));
        Rhs := Trim(Copy(Code, Assign + 2, MaxInt));
        if CompareText(Lhs, AFact.OutName) = 0 then
        begin
          // X := TКласс.Create(Владелец)
          CreateAt := Pos('.CREATE(', UpperCase(Rhs));
          if (CreateAt > 0) and (Rhs[Length(Rhs)] = ')') and
             IsValidIdent(Trim(Copy(Rhs, 1, CreateAt - 1))) then
          begin
            Stmt.Kind := hsCreate;
            Stmt.Expr := Trim(Copy(Rhs, 1, CreateAt - 1));
            SplitCallArgs(Copy(Rhs, CreateAt + 8, Length(Rhs) - CreateAt - 8),
                          CallArgs);
            if CallArgs.Count > 0 then
              AHelper.OwnerExpr := CallArgs[0];
          end;
        end
        else if CompareText(Copy(Lhs, 1, Length(AFact.OutName) + 1),
                            AFact.OutName + '.') = 0 then
        begin
          Name := Trim(Copy(Lhs, Length(AFact.OutName) + 2, MaxInt));
          if (CompareText(Name, 'Parent') = 0) or
             (CompareText(Name, 'PageControl') = 0) then
          begin
            Stmt.Kind := hsParent;
            Stmt.Expr := Rhs;
          end
          else if IsPropPath(Name) then
          begin
            Stmt.Kind := hsProp;
            Stmt.PropName := Name;
            Stmt.Expr := Rhs;
          end;
        end;
      end
      else if ParseAddLine(Code + ';', AddParent, AddChild) and
              (CompareText(AddChild, AFact.OutName) = 0) then
      begin
        Stmt.Kind := hsParent;
        Stmt.Expr := AddParent;
      end;
    end;

    if AHelper.Stmts.Count = 0 then
    begin
      Fail('тело пустое');
      Exit;
    end;

    // Последний оператор - сдвиг: V := V + E; V := V - E; Inc(V, E);
    // Dec(V, Имя). V - var-параметр или (у вложенной) переменная
    // процедуры, в которую она вложена.
    Stmt := THelperStmt(AHelper.Stmts[AHelper.Stmts.Count - 1]);
    if (Stmt.Kind = hsOther) and (Stmt.First = Stmt.Last) then
    begin
      Code := Trim(StripComment(ALines[Stmt.First]));
      if Code[Length(Code)] = ';' then
        Code := TrimRight(Copy(Code, 1, Length(Code) - 1));
      Name := '';
      Expr := '';
      Key := CodeKey(Code);
      Assign := Pos(':=', Code);
      if Assign > 0 then
      begin
        Lhs := Trim(Copy(Code, 1, Assign - 1));
        Rhs := Trim(Copy(Code, Assign + 2, MaxInt));
        if IsValidIdent(Lhs) and
           (CompareText(Copy(Rhs, 1, Length(Lhs)), Lhs) = 0) and
           (Length(Rhs) > Length(Lhs)) and
           not IsIdentChar(Rhs[Length(Lhs) + 1]) then
        begin
          ChainTail := Trim(Copy(Rhs, Length(Lhs) + 1, MaxInt));
          if (ChainTail <> '') and (ChainTail[1] = '+') then
          begin
            Name := Lhs;
            Expr := Trim(Copy(ChainTail, 2, MaxInt));
          end
          else if (ChainTail <> '') and (ChainTail[1] = '-') then
          begin
            Name := Lhs;
            Expr := '-' + Trim(Copy(ChainTail, 2, MaxInt));
          end;
        end;
      end
      else if ((Copy(Key, 1, 4) = 'INC(') or (Copy(Key, 1, 4) = 'DEC(')) and
              (Key[Length(Key)] = ')') then
      begin
        Rhs := Trim(Copy(Code, Pos('(', Code) + 1,
                         LastDelimiter(')', Code) - Pos('(', Code) - 1));
        SplitCallArgs(Rhs, CallArgs);
        if CallArgs.Count = 1 then
        begin
          Name := CallArgs[0];
          Expr := '1';
        end
        else if CallArgs.Count = 2 then
        begin
          Name := CallArgs[0];
          Expr := CallArgs[1];
        end;
        if (Name <> '') and (Copy(Key, 1, 3) = 'DEC') then
        begin
          if IsValidIdent(Expr) or (StrToIntDef(Expr, -1) >= 0) then
            Expr := '-' + Expr
          else
            Name := '';
        end;
      end;
      if IsValidIdent(Name) and (Expr <> '') then
      begin
        Other := AHelper.Params.IndexOf(Name);
        if (Other >= 0) and (Other <> AHelper.OutIdx) and
           (AHelper.VarParams.IndexOf(UpperCase(Name)) >= 0) then
        begin
          Stmt.Kind := hsInc;
          AHelper.IncParam := Other;
          AHelper.IncExpr := Expr;
        end
        else if (Other < 0) and AHelper.Nested and
                (AHelper.LocalNames.IndexOf(UpperCase(Name)) < 0) and
                (AHelper.Consts.IndexOfName(UpperCase(Name)) < 0) and
                (CompareText(Name, 'Result') <> 0) then
        begin
          Stmt.Kind := hsInc;
          AHelper.IncVar := Name;
          AHelper.IncExpr := Expr;
        end;
      end;
    end;

    // Проверки тела
    Creates := 0;
    for StmtIndex := 0 to AHelper.Stmts.Count - 1 do
    begin
      Stmt := THelperStmt(AHelper.Stmts[StmtIndex]);
      for ChainIndex := 0 to Stmt.Chains.Count - 1 do
      begin
        Chain := Stmt.Chains[ChainIndex];
        if (Chain = 'EXIT') or (Chain = 'RAISE') or (Chain = 'HALT') or
           (Chain = 'ABORT') or (Chain = 'GOTO') then
        begin
          Fail('в ней есть ' + LowerCase(Chain) + ' (строка ' +
               IntToStr(Stmt.First + 1) + ') - строки после него ' +
               'выполняются не всегда');
          Exit;
        end;
        // До создания компонент в ней не трогают
        if (Creates = 0) and (Stmt.Kind <> hsCreate) and
           (ChainHead(Chain) = OutUpper) then
        begin
          Fail(AFact.OutName + ' используется до создания, строка ' +
               IntToStr(Stmt.First + 1));
          Exit;
        end;
      end;
      if Stmt.Kind = hsCreate then
        Inc(Creates);
      // Присвоение самому компоненту или освобождение - не разбирается
      if Stmt.Kind = hsOther then
        for Line := Stmt.First to Stmt.Last do
        begin
          Key := CodeKey(ALines[Line]);
          if HasPattern(Key, OutUpper + ':=') or
             HasPattern(Key, 'FREEANDNIL(' + OutUpper + ')') or
             HasPattern(Key, OutUpper + '.FREE') then
          begin
            Fail(AFact.OutName + ' меняется или освобождается в строке ' +
                 IntToStr(Line + 1));
            Exit;
          end;
        end;
    end;
    if Creates <> 1 then
    begin
      Fail('в ней не одна строка ' + AFact.OutName + ' := TКласс.Create(...)');
      Exit;
    end;
    // Свойство, присвоенное дважды, остаётся в ней: важен порядок
    for StmtIndex := 0 to AHelper.Stmts.Count - 1 do
    begin
      Stmt := THelperStmt(AHelper.Stmts[StmtIndex]);
      if Stmt.Kind <> hsProp then
        Continue;
      for Other := StmtIndex + 1 to AHelper.Stmts.Count - 1 do
      begin
        OtherStmt := THelperStmt(AHelper.Stmts[Other]);
        if (OtherStmt.Kind = hsProp) and
           (CompareText(OtherStmt.PropName, Stmt.PropName) = 0) then
        begin
          Stmt.Kind := hsOther;
          OtherStmt.Kind := hsOther;
        end;
      end;
    end;
    // Имена из остающихся строк: у вызывающей процедуры их значения после
    // вызова не известны
    for StmtIndex := 0 to AHelper.Stmts.Count - 1 do
    begin
      Stmt := THelperStmt(AHelper.Stmts[StmtIndex]);
      if not (Stmt.Kind in [hsOther, hsInc]) then
        Continue;
      for ChainIndex := 0 to Stmt.Chains.Count - 1 do
      begin
        Name := ChainHead(Stmt.Chains[ChainIndex]);
        if (Name = OutUpper) or (AHelper.Params.IndexOf(Name) >= 0) or
           (AHelper.LocalNames.IndexOf(Name) >= 0) or
           (AHelper.Consts.IndexOfName(Name) >= 0) or
           (CompareText(Name, AHelper.IncVar) = 0) or
           (AHelper.Clobbers.IndexOf(Name) >= 0) then
          Continue;
        AHelper.Clobbers.Add(Name);
      end;
    end;
  finally
    CallArgs.Free;
    Chains.Free;
  end;
end;

// Помощники модуля (их находит ObjParse) с разбором тела
procedure CollectHelpers(ALines: TStrings; AHelpers: TList);
var
  Facts: TList;
  Index, Line, HeadEnd, BodyStart, Assign, CreateAt, Open, Close: Integer;
  Fact: TFactoryRec;
  Helper: THelperInfo;
  Head, Code, Upper, PropName, Expr, AddParent, AddChild, LoopKey,
    LoopVarName, LoopArrayName, ColumnText, IncText, IncName: string;
  BlockEnd, CommaAt: Integer;

  procedure Refuse(ALine: Integer; const ACode: string);
  begin
    Helper.Simple := False;
    Helper.Problem := 'в нём не только присваивания свойств: строка ' +
                      IntToStr(ALine + 1) + ': ' + ACode;
  end;

  // Блок колонки с строки AStart:
  //   with Result.Columns.Add do
  //   begin
  //     Caption := ...;
  //     Width := ...;
  //   end;
  // AText - «Свойство<#9>выражение» через #10, AEnd - строка end;
  function ColumnBlock(AStart: Integer; var AText: string;
    var AEnd: Integer): Boolean;
  const
    ColumnProps: array[0..7] of string = ('Caption', 'Width', 'Alignment',
      'AutoSize', 'MaxWidth', 'MinWidth', 'ImageIndex', 'Tag');
  var
    At, PropIndex, ColonAt: Integer;
    Key, Text, ColumnProp, ColumnExpr: string;
    Known: Boolean;
  begin
    Result := False;
    AText := '';
    AEnd := -1;
    At := AStart;
    while (At < Fact.EndLine) and (CodeKey(ALines[At]) = '') do
      Inc(At);
    if (At >= Fact.EndLine) or
       (CodeKey(ALines[At]) <> 'WITH RESULT.COLUMNS.ADD DO') then
      Exit;
    Inc(At);
    while (At < Fact.EndLine) and (CodeKey(ALines[At]) = '') do
      Inc(At);
    if (At >= Fact.EndLine) or (CodeKey(ALines[At]) <> 'BEGIN') then
      Exit;
    Inc(At);
    while At < Fact.EndLine do
    begin
      Key := CodeKey(ALines[At]);
      if Key = 'END;' then
      begin
        AEnd := At;
        Result := AText <> '';
        Exit;
      end;
      if Key <> '' then
      begin
        Text := Trim(StripComment(ALines[At]));
        ColonAt := Pos(':=', Text);
        if (ColonAt = 0) or (Text[Length(Text)] <> ';') then
          Exit;
        ColumnProp := Trim(Copy(Text, 1, ColonAt - 1));
        ColumnExpr := Trim(Copy(Text, ColonAt + 2, Length(Text) - ColonAt - 2));
        Known := False;
        for PropIndex := Low(ColumnProps) to High(ColumnProps) do
          if CompareText(ColumnProp, ColumnProps[PropIndex]) = 0 then
          begin
            ColumnProp := ColumnProps[PropIndex];
            Known := True;
          end;
        if not Known then
          Exit;
        if AText <> '' then
          AText := AText + #10;
        AText := AText + ColumnProp + #9 + ColumnExpr;
      end;
      Inc(At);
    end;
  end;

begin
  Facts := TList.Create;
  try
    CodeCollectFactories(ALines, Facts);
    for Index := 0 to Facts.Count - 1 do
    begin
      Fact := TFactoryRec(Facts[Index]);
      if Fact.Cls = '' then
        Continue;             // настройщик: сам ничего не создаёт
      Helper := THelperInfo.Create;
      AHelpers.Add(Helper);
      Helper.Name := Fact.Name;
      Helper.Cls := Fact.Cls;
      // Заголовок - до закрывающей скобки параметров
      Head := Trim(ALines[Fact.HdrLine]);
      HeadEnd := Fact.HdrLine;
      while (Pos(')', Head) = 0) and
            not ((Pos('(', Head) = 0) and (Pos(';', Head) > 0)) and
            (HeadEnd + 1 < ALines.Count) and (HeadEnd < Fact.HdrLine + 6) do
      begin
        Inc(HeadEnd);
        Head := Head + ' ' + Trim(ALines[HeadEnd]);
      end;
      CodeParamNames(Head, Helper.Params);
      if Fact.OutIdx >= 0 then
      begin
        ParseVarHelper(ALines, Fact, Helper, HeadEnd);
        Continue;
      end;
      BodyStart := -1;
      for Line := HeadEnd + 1 to Fact.EndLine - 1 do
        if FirstWordOf(ALines[Line]) = 'BEGIN' then
        begin
          BodyStart := Line;
          Break;
        end;
      if BodyStart < 0 then
      begin
        Helper.Problem := 'тело помощника не найдено';
        Continue;
      end;

      Helper.Simple := True;
      Line := BodyStart;
      while Line < Fact.EndLine - 1 do
      begin
        Inc(Line);
        Code := Trim(StripComment(ALines[Line]));
        if Code = '' then
          Continue;
        Upper := UpperCase(Code);
        Assign := Pos(':=', Code);
        // После Inc(X, ...) - ничего: сдвиг должен быть последним
        if Helper.IncVar <> '' then
        begin
          Refuse(Line, Code);
          Break;
        end;
        LoopKey := CodeKey(ALines[Line]);
        // Сдвиг переменной вызывающей процедуры: Inc(X, W + 3);
        if (Copy(LoopKey, 1, 4) = 'INC(') and
           (Copy(LoopKey, Length(LoopKey) - 1, 2) = ');') then
        begin
          IncText := Trim(Copy(Code, Pos('(', Code) + 1,
                               LastDelimiter(')', Code) - Pos('(', Code) - 1));
          CommaAt := Pos(',', IncText);
          if CommaAt > 0 then
          begin
            IncName := Trim(Copy(IncText, 1, CommaAt - 1));
            IncText := Trim(Copy(IncText, CommaAt + 1, MaxInt));
          end
          else
          begin
            IncName := IncText;
            IncText := '1';
          end;
          if not IsValidIdent(IncName) or
             (CompareText(IncName, 'Result') = 0) or
             (Helper.Params.IndexOf(IncName) >= 0) then
          begin
            Refuse(Line, Code);
            Break;
          end;
          Helper.IncVar := IncName;
          Helper.IncExpr := IncText;
          Continue;
        end;
        // Колонки списка: блок with Result.Columns.Add do, может быть в
        // цикле for I := 0 to High(Массив) do
        if (Copy(LoopKey, 1, 4) = 'FOR ') and
           (Pos(':=0 TO HIGH(', LoopKey) > 0) and
           (Copy(LoopKey, Length(LoopKey) - 2, 3) = ')DO') then
        begin
          LoopVarName := Copy(LoopKey, 5, Pos(':=', LoopKey) - 5);
          LoopArrayName := Copy(LoopKey, Pos('HIGH(', LoopKey) + 5, MaxInt);
          LoopArrayName := Copy(LoopArrayName, 1, Pos(')', LoopArrayName) - 1);
          if (Helper.LoopArray <> '') or not IsValidIdent(LoopVarName) or
             not IsValidIdent(LoopArrayName) or
             not ColumnBlock(Line + 1, ColumnText, BlockEnd) then
          begin
            Refuse(Line, Code);
            Break;
          end;
          Helper.LoopVar := LoopVarName;
          Helper.LoopArray := LoopArrayName;
          Helper.Columns.AddObject(ColumnText, TObject(1));
          Line := BlockEnd;
          Continue;
        end;
        if LoopKey = 'WITH RESULT.COLUMNS.ADD DO' then
        begin
          if not ColumnBlock(Line, ColumnText, BlockEnd) then
          begin
            Refuse(Line, Code);
            Break;
          end;
          Helper.Columns.AddObject(ColumnText, TObject(0));
          Line := BlockEnd;
          Continue;
        end;
        if (Assign > 0) and (Trim(Copy(Upper, 1, Assign - 1)) = 'RESULT') then
        begin
          // Result := TКласс.Create(Владелец);
          CreateAt := Pos('.CREATE(', Upper);
          Open := CreateAt + 7;
          Close := LastDelimiter(')', Code);
          if (CreateAt = 0) or (Close < Open) then
          begin
            Refuse(Line, Code);
            Break;
          end;
          Helper.OwnerExpr := Trim(Copy(Code, Open + 1, Close - Open - 1));
        end
        else if (Copy(Upper, 1, 7) = 'RESULT.') and (Assign > 0) and
                (Code[Length(Code)] = ';') then
        begin
          PropName := Trim(Copy(Code, 8, Assign - 8));
          Expr := Trim(Copy(Code, Assign + 2, Length(Code) - Assign - 2));
          if CompareText(PropName, 'Parent') = 0 then
            Helper.NestExpr := Expr
          else if IsPropPath(PropName) then
          begin
            Helper.PropNames.Add(PropName);
            Helper.PropExprs.Add(Expr);
            Helper.PropConds.Add('');
          end
          else
          begin
            Refuse(Line, Code);
            Break;
          end;
        end
        else if ParseAddLine(Code, AddParent, AddChild) and
                (CompareText(AddChild, 'Result') = 0) then
          Helper.NestExpr := AddParent
        else
        begin
          Refuse(Line, Code);
          Break;
        end;
      end;
      if Helper.Simple and (Helper.OwnerExpr = '') then
      begin
        Helper.Simple := False;
        Helper.Problem := 'в нём нет строки Result := TКласс.Create(...)';
      end;
    end;
  finally
    FreeFactories(Facts);
  end;
end;

// Значение выражения из тела помощника у данного вызова: параметр -
// аргумент вызова, иначе само выражение (константа, метод, компонент)
function HelperValue(AHelper: THelperInfo; AArgs: TStrings;
  const AExpr: string): string;
var
  At: Integer;
begin
  At := AHelper.Params.IndexOf(AExpr);
  if (At >= 0) and (At < AArgs.Count) then
    Result := Trim(AArgs[At])
  else
    Result := AExpr;
end;

// Строка ALine - вызов помощника: X := Помощник(...); или Помощник(...);
// (вызов может занимать несколько строк). AHelper, ALhs ('' - без
// переменной), аргументы, последняя строка вызова. False - не вызов.
function ParseHelperCall(ALines: TStrings; ALine: Integer; AHelpers: TList;
  var AHelper: THelperInfo; var ALhs: string; AArgs: TStrings;
  var ALast: Integer): Boolean;
var
  Code, Name, Call: string;
  Assign, Open, Index, Depth, CharIndex, Stop: Integer;
  InQuote: Boolean;
begin
  Result := False;
  AHelper := nil;
  ALhs := '';
  AArgs.Clear;
  ALast := ALine;
  Code := Trim(StripComment(ALines[ALine]));
  Open := Pos('(', Code);
  if Open = 0 then
    Exit;
  Assign := Pos(':=', Code);
  if (Assign > 0) and (Assign < Open) then
  begin
    ALhs := Trim(Copy(Code, 1, Assign - 1));
    if not IsValidIdent(ALhs) then
      Exit;
    Name := Trim(Copy(Code, Assign + 2, Open - Assign - 2));
  end
  else
    Name := Trim(Copy(Code, 1, Open - 1));
  if not IsValidIdent(Name) then
    Exit;
  for Index := 0 to AHelpers.Count - 1 do
    if CompareText(THelperInfo(AHelpers[Index]).Name, Name) = 0 then
    begin
      AHelper := THelperInfo(AHelpers[Index]);
      Break;
    end;
  if AHelper = nil then
    Exit;

  // Аргументы - до парной скобки
  Call := Copy(Code, Open + 1, MaxInt);
  repeat
    Depth := 1;
    InQuote := False;
    Stop := 0;
    for CharIndex := 1 to Length(Call) do
      if Call[CharIndex] = '''' then
        InQuote := not InQuote
      else if not InQuote then
        if Call[CharIndex] = '(' then
          Inc(Depth)
        else if Call[CharIndex] = ')' then
        begin
          Dec(Depth);
          if Depth = 0 then
          begin
            Stop := CharIndex;
            Break;
          end;
        end;
    if Stop > 0 then
      Break;
    if (ALast + 1 >= ALines.Count) or (ALast >= ALine + 6) then
      Exit;
    Inc(ALast);
    Call := Call + ' ' + Trim(StripComment(ALines[ALast]));
  until False;
  if Trim(Copy(Call, Stop + 1, MaxInt)) <> ';' then
    Exit;
  SplitCallArgs(Copy(Call, 1, Stop - 1), AArgs);
  Result := True;
end;

// Процедуры формы, которые создают компонент в своей локальной переменной
// и вызываются несколько раз (AddLogPopupItem('&Undo', 1)). В теле только:
// Локальная := TКласс.Create(Владелец); Локальная.Свойство := Выражение
// (можно с условием: if Условие then Локальная.Свойство := ...); родитель -
// Локальная.Parent := P, P.Add(Локальная), P.Items.Add(Локальная).
// Каждый вызов - свой компонент; значения - из аргументов вызова.
procedure CollectLocalCreators(ALines: TStrings; const AFormClass: string;
  AHelpers: TList);
var
  Line, HeadEnd, BodyStart, BodyEnd, At, Assign, CreateAt, Calls, Assigns,
    Colon, HelperIndex, StmtLine, NextLine, ThenAt: Integer;
  Key, Prefix, Name, Head, Code, Word, Lhs, Rhs, Cond, AddParent, AddChild,
    PropName, LocalName, ClassName, OwnerExpr, NestExpr, Rest: string;
  Helper: THelperInfo;
  Locals, CallArgs, PropNames, PropExprs, PropConds: TStringList;
  BodyLines: TList;
  Ok, Exists: Boolean;

  // Следующая строка с кодом после ALine (до BodyEnd); -1 - нет
  function NextCodeLine(ALine: Integer): Integer;
  begin
    Result := ALine + 1;
    while (Result < BodyEnd) and (Trim(StripComment(ALines[Result])) = '') do
      Inc(Result);
    if Result >= BodyEnd then
      Result := -1;
  end;

  // Строка ACode - Локальная.Свойство := Выражение; (не Parent). False - нет.
  function PropLine(const ACode: string; var AProp, AExpr: string): Boolean;
  var
    AssignAt: Integer;
    Left: string;
  begin
    Result := False;
    AssignAt := Pos(':=', ACode);
    if (AssignAt = 0) or (ACode[Length(ACode)] <> ';') or
       (Pos(':=', Copy(ACode, AssignAt + 2, MaxInt)) > 0) then
      Exit;
    Left := Trim(Copy(ACode, 1, AssignAt - 1));
    if CompareText(Copy(Left, 1, Length(LocalName) + 1), LocalName + '.') <> 0 then
      Exit;
    AProp := Copy(Left, Length(LocalName) + 2, MaxInt);
    AExpr := Trim(Copy(ACode, AssignAt + 2, Length(ACode) - AssignAt - 2));
    Result := IsPropPath(AProp) and (CompareText(AProp, 'Parent') <> 0) and
              not HasWord(AExpr, LocalName);
  end;

begin
  Prefix := 'PROCEDURE ' + UpperCase(AFormClass) + '.';
  Locals := TStringList.Create;
  CallArgs := TStringList.Create;
  PropNames := TStringList.Create;
  PropExprs := TStringList.Create;
  PropConds := TStringList.Create;
  BodyLines := TList.Create;
  try
    for Line := 0 to ALines.Count - 1 do
    begin
      if LeadSpacesOf(ALines[Line]) <> 0 then
        Continue;
      Key := CodeKey(ALines[Line]);
      if Copy(Key, 1, Length(Prefix)) <> Prefix then
        Continue;
      Code := Trim(StripComment(ALines[Line]));
      At := Pos('.', Code) + 1;
      Name := '';
      while (At <= Length(Code)) and IsIdentChar(Code[At]) do
      begin
        Name := Name + Code[At];
        Inc(At);
      end;
      if not IsValidIdent(Name) then
        Continue;
      Exists := False;
      for HelperIndex := 0 to AHelpers.Count - 1 do
        if CompareText(THelperInfo(AHelpers[HelperIndex]).Name, Name) = 0 then
          Exists := True;
      if Exists then
        Continue;
      // Вызывается несколько раз и не назначается обработчиком
      CountUses(ALines, Name, Calls, Assigns);
      if (Assigns > 0) or (Calls < 2) then
        Continue;
      // Заголовок
      Head := Code;
      HeadEnd := Line;
      while (Pos('(', Head) > 0) and (Pos(')', Head) = 0) and
            (HeadEnd + 1 < ALines.Count) and (HeadEnd < Line + 6) do
      begin
        Inc(HeadEnd);
        Head := Head + ' ' + Trim(StripComment(ALines[HeadEnd]));
      end;
      if (Head = '') or (Head[Length(Head)] <> ';') then
        Continue;
      // Объявления: только var с локальными переменными
      Locals.Clear;
      Ok := True;
      BodyStart := -1;
      for At := HeadEnd + 1 to ALines.Count - 1 do
      begin
        Code := Trim(StripComment(ALines[At]));
        if Code = '' then
          Continue;
        Word := FirstWordOf(Code);
        if (Word = 'BEGIN') and (LeadSpacesOf(ALines[At]) = 0) then
        begin
          BodyStart := At;
          Break;
        end;
        if Word = 'VAR' then
        begin
          Code := Trim(Copy(Code, 4, MaxInt));
          if Code = '' then
            Continue;
        end;
        Colon := Pos(':', Code);
        if (Colon = 0) or (Code[Length(Code)] <> ';') or
           not SplitNameList(Copy(Code, 1, Colon - 1), Locals) then
        begin
          Ok := False;
          Break;
        end;
      end;
      if not Ok or (BodyStart < 0) then
        Continue;
      BodyEnd := -1;
      for At := BodyStart + 1 to ALines.Count - 1 do
        if (LeadSpacesOf(ALines[At]) = 0) and
           (UpperCase(Trim(ALines[At])) = 'END;') then
        begin
          BodyEnd := At;
          Break;
        end;
      if BodyEnd < 0 then
        Continue;

      // Тело
      LocalName := '';
      ClassName := '';
      OwnerExpr := '';
      NestExpr := '';
      PropNames.Clear;
      PropExprs.Clear;
      PropConds.Clear;
      BodyLines.Clear;
      StmtLine := NextCodeLine(BodyStart);
      while Ok and (StmtLine >= 0) do
      begin
        Code := Trim(StripComment(ALines[StmtLine]));
        NextLine := NextCodeLine(StmtLine);
        if LocalName = '' then
        begin
          // Первым - создание в локальную переменную
          Assign := Pos(':=', Code);
          CreateAt := Pos('.CREATE(', UpperCase(Code));
          Lhs := Trim(Copy(Code, 1, Assign - 1));
          if (Assign = 0) or (CreateAt < Assign) or
             (Locals.IndexOf(UpperCase(Lhs)) < 0) or
             (Copy(Code, Length(Code) - 1, 2) <> ');') then
          begin
            Ok := False;
            Break;
          end;
          LocalName := Lhs;
          ClassName := Trim(Copy(Code, Assign + 2, CreateAt - Assign - 2));
          SplitCallArgs(Copy(Code, CreateAt + 8, Length(Code) - CreateAt - 9),
                        CallArgs);
          if not IsValidIdent(ClassName) or (CallArgs.Count <> 1) then
          begin
            Ok := False;
            Break;
          end;
          OwnerExpr := CallArgs[0];
          BodyLines.Add(TObject(StmtLine));
        end
        else if FirstWordOf(Code) = 'IF' then
        begin
          // if Условие then Локальная.Свойство := Выражение;
          ThenAt := Pos(' THEN', UpperCase(Code) + ' ');
          if ThenAt = 0 then
          begin
            Ok := False;
            Break;
          end;
          Cond := Trim(Copy(Code, 3, ThenAt - 3));
          Rest := Trim(Copy(Code, ThenAt + 5, MaxInt));
          BodyLines.Add(TObject(StmtLine));
          if Rest = '' then
          begin
            if NextLine < 0 then
            begin
              Ok := False;
              Break;
            end;
            StmtLine := NextLine;
            Rest := Trim(StripComment(ALines[StmtLine]));
            NextLine := NextCodeLine(StmtLine);
            BodyLines.Add(TObject(StmtLine));
          end;
          if (NextLine >= 0) and
             (FirstWordOf(ALines[NextLine]) = 'ELSE') then
            Ok := False
          else if (Cond = '') or HasWord(Cond, LocalName) or
                  not PropLine(Rest, PropName, Rhs) then
            Ok := False
          else
          begin
            PropNames.Add(PropName);
            PropExprs.Add(Rhs);
            PropConds.Add(Cond);
          end;
        end
        else if ParseAddLine(Code, AddParent, AddChild) and
                (CompareText(AddChild, LocalName) = 0) and (NestExpr = '') then
        begin
          NestExpr := AddParent;
          BodyLines.Add(TObject(StmtLine));
        end
        else if (CompareText(Copy(Code, 1, Length(LocalName) + 8),
                             LocalName + '.Parent:') = 0) or
                (CompareText(Copy(Code, 1, Length(LocalName) + 9),
                             LocalName + '.Parent :') = 0) then
        begin
          Assign := Pos(':=', Code);
          Rhs := Trim(Copy(Code, Assign + 2, Length(Code) - Assign - 2));
          if (NestExpr <> '') or not IsValidIdent(Rhs) or
             (Code[Length(Code)] <> ';') then
            Ok := False
          else
          begin
            NestExpr := Rhs;
            BodyLines.Add(TObject(StmtLine));
          end;
        end
        else if PropLine(Code, PropName, Rhs) then
        begin
          PropNames.Add(PropName);
          PropExprs.Add(Rhs);
          PropConds.Add('');
          BodyLines.Add(TObject(StmtLine));
        end
        else
          Ok := False;
        StmtLine := NextLine;
      end;
      if not Ok or (LocalName = '') or (NestExpr = '') then
        Continue;

      Helper := THelperInfo.Create;
      AHelpers.Add(Helper);
      Helper.Name := Name;
      Helper.Cls := ClassName;
      CodeParamNames(Head, Helper.Params);
      // var-параметры не разбираются: вызов мог бы что-то вернуть
      Helper.Simple := (Pos('VAR ', UpperCase(Head)) = 0) and
                       (Pos('OUT ', UpperCase(Head)) = 0);
      if not Helper.Simple then
        Helper.Problem := 'у неё var-параметры';
      Helper.LocalCreator := True;
      Helper.LocalName := LocalName;
      Helper.OwnerExpr := OwnerExpr;
      Helper.NestExpr := NestExpr;
      Helper.PropNames.Assign(PropNames);
      Helper.PropExprs.Assign(PropExprs);
      Helper.PropConds.Assign(PropConds);
      for At := 0 to BodyLines.Count - 1 do
        Helper.BodyLines.Add(BodyLines[At]);
      Helper.HdrLine := Line;
      Helper.HeadEnd := HeadEnd;
      Helper.BodyStart := BodyStart;
      Helper.BodyEnd := BodyEnd;
    end;
  finally
    BodyLines.Free;
    PropConds.Free;
    PropExprs.Free;
    PropNames.Free;
    CallArgs.Free;
    Locals.Free;
  end;
end;

// Условие свойства в процедуре-создателе у данного вызова: параметры -
// аргументы. Сравнение (=, <>, <, >, <=, >=) целых, строк в кавычках или с
// nil. 1 - выполняется, 0 - нет, -1 - не посчитать.
function HelperCondition(AHelper: THelperInfo; AArgs: TStrings;
  const ACond: string): Integer;
const
  Ops: array[0..5] of string = ('<>', '<=', '>=', '=', '<', '>');
var
  Text, Op, Left, Right: string;
  At, OpIndex, LeftValue, RightValue, Depth: Integer;
  InQuote, Known, Holds: Boolean;
  NoValues: TStringList;
begin
  Result := -1;
  Text := Trim(ACond);
  while (Length(Text) > 1) and (Text[1] = '(') and
        (Text[Length(Text)] = ')') do
    Text := Trim(Copy(Text, 2, Length(Text) - 2));
  // Оператор - первый вне кавычек и скобок
  Op := '';
  At := 1;
  InQuote := False;
  Depth := 0;
  while (At <= Length(Text)) and (Op = '') do
  begin
    if Text[At] = '''' then
      InQuote := not InQuote
    else if not InQuote then
      if Text[At] = '(' then
        Inc(Depth)
      else if Text[At] = ')' then
        Dec(Depth)
      else if Depth = 0 then
        for OpIndex := Low(Ops) to High(Ops) do
          if (Op = '') and (Copy(Text, At, Length(Ops[OpIndex])) = Ops[OpIndex]) then
            Op := Ops[OpIndex];
    if Op = '' then
      Inc(At);
  end;
  if Op = '' then
    Exit;
  Left := HelperValue(AHelper, AArgs, Trim(Copy(Text, 1, At - 1)));
  Right := HelperValue(AHelper, AArgs, Trim(Copy(Text, At + Length(Op), MaxInt)));
  Known := False;
  Holds := False;
  NoValues := TStringList.Create;
  try
    if EvalIntExpr(Left, NoValues, LeftValue) and
       EvalIntExpr(Right, NoValues, RightValue) then
    begin
      Known := True;
      if Op = '=' then Holds := LeftValue = RightValue
      else if Op = '<>' then Holds := LeftValue <> RightValue
      else if Op = '<' then Holds := LeftValue < RightValue
      else if Op = '>' then Holds := LeftValue > RightValue
      else if Op = '<=' then Holds := LeftValue <= RightValue
      else Holds := LeftValue >= RightValue;
    end
    else if ((Op = '=') or (Op = '<>')) and (Left <> '') and (Right <> '') and
            (Left[1] in ['''', '#']) and (Right[1] in ['''', '#']) and
            IsLiteral(Left) and IsLiteral(Right) then
    begin
      Known := True;
      Holds := (Left = Right) = (Op = '=');
    end
    else if ((Op = '=') or (Op = '<>')) and
            ((CompareText(Left, 'nil') = 0) or (CompareText(Right, 'nil') = 0)) and
            IsValidIdent(Left) and IsValidIdent(Right) then
    begin
      // метод или nil в аргументе
      Known := True;
      Holds := (CompareText(Left, Right) = 0) = (Op = '=');
    end;
  finally
    NoValues.Free;
  end;
  if Known then
    Result := Ord(Holds);
end;

// ---------------------------------------------------------------------------
//  Константные выражения (развёртка цикла по константному массиву)
// ---------------------------------------------------------------------------

type
  // Значение константного выражения: целое или строка
  TConstValue = record
    IsInt: Boolean;
    Int: Integer;
    Str: string;
  end;

// Значение для окружения выражений: 'I:5' или 'S:текст'
function ConstText(const AValue: TConstValue): string;
begin
  if AValue.IsInt then
    Result := 'I:' + IntToStr(AValue.Int)
  else
    Result := 'S:' + AValue.Str;
end;

// Строка - литералом Паскаля: 'It''s', #9 для управляющих знаков
function PascalQuote(const AText: string): string;
var
  Index: Integer;
  InQuote: Boolean;
begin
  Result := '';
  InQuote := False;
  for Index := 1 to Length(AText) do
    if Ord(AText[Index]) < 32 then
    begin
      if InQuote then
        Result := Result + '''';
      InQuote := False;
      Result := Result + '#' + IntToStr(Ord(AText[Index]));
    end
    else
    begin
      if not InQuote then
        Result := Result + '''';
      InQuote := True;
      if AText[Index] = '''' then
        Result := Result + ''''''
      else
        Result := Result + AText[Index];
    end;
  if InQuote then
    Result := Result + '''';
  if Result = '' then
    Result := '''''';
end;

// Константное выражение: целые и строки, + и -, скобки, элемент массива
// Имя[выражение], имена из AEnv (ИМЯ=I:число / S:строка; элементы -
// ИМЯ[номер]=..., границы - ИМЯ.LOW / ИМЯ.HIGH), функции Copy, Pos,
// Length, Low, High, IntToStr, UpperCase, LowerCase, Trim. False - что-то
// другое.
function EvalConstExpr(const AExpr: string; AEnv: TStrings;
  var AValue: TConstValue): Boolean;
var
  Text: string;
  At: Integer;
  Failed: Boolean;

  procedure SkipSpaces;
  begin
    while (At <= Length(Text)) and (Text[At] in [' ', #9]) do
      Inc(At);
  end;

  function Peek: Char;
  begin
    SkipSpaces;
    if At <= Length(Text) then
      Result := Text[At]
    else
      Result := #0;
  end;

  function MakeInt(AInt: Integer): TConstValue;
  begin
    Result.IsInt := True;
    Result.Int := AInt;
    Result.Str := '';
  end;

  function MakeStr(const AStr: string): TConstValue;
  begin
    Result.IsInt := False;
    Result.Int := 0;
    Result.Str := AStr;
  end;

  function FromEnv(const AName: string): TConstValue;
  var
    Raw: string;
  begin
    Result := MakeInt(0);
    if AEnv.IndexOfName(AName) < 0 then
    begin
      Failed := True;
      Exit;
    end;
    Raw := AEnv.Values[AName];
    if Copy(Raw, 1, 2) = 'I:' then
      Result := MakeInt(StrToIntDef(Copy(Raw, 3, MaxInt), 0))
    else if Copy(Raw, 1, 2) = 'S:' then
      Result := MakeStr(Copy(Raw, 3, MaxInt))
    else
      Failed := True;
  end;

  function ReadIdent: string;
  begin
    SkipSpaces;
    Result := '';
    while (At <= Length(Text)) and IsIdentChar(Text[At]) do
    begin
      Result := Result + UpCase(Text[At]);
      Inc(At);
    end;
  end;

  function ParseExpr: TConstValue;

    function Factor: TConstValue;
    var
      Name, Part: string;
      Code, Start: Integer;
      Args: array of TConstValue;
      Index: TConstValue;
    begin
      Result := MakeInt(0);
      if Failed then
        Exit;
      case Peek of
        '(':
          begin
            Inc(At);
            Result := ParseExpr;
            if Peek <> ')' then
              Failed := True
            else
              Inc(At);
          end;
        '-':
          begin
            Inc(At);
            Result := Factor;
            if not Result.IsInt then
              Failed := True
            else
              Result.Int := -Result.Int;
          end;
        '0'..'9', '$':
          begin
            Start := At;
            Inc(At);
            while (At <= Length(Text)) and
                  (Text[At] in ['0'..'9', 'A'..'F', 'a'..'f']) do
              Inc(At);
            Code := StrToIntDef(Copy(Text, Start, At - Start), MaxInt);
            if Code = MaxInt then
              Failed := True
            else
              Result := MakeInt(Code);
          end;
        '''', '#':
          begin
            Part := '';
            while not Failed and (At <= Length(Text)) and
                  (Text[At] in ['''', '#']) do
              if Text[At] = '''' then
              begin
                Inc(At);
                while True do
                begin
                  if At > Length(Text) then
                  begin
                    Failed := True;
                    Break;
                  end;
                  if Text[At] = '''' then
                  begin
                    if (At < Length(Text)) and (Text[At + 1] = '''') then
                    begin
                      Part := Part + '''';
                      Inc(At, 2);
                      Continue;
                    end;
                    Inc(At);
                    Break;
                  end;
                  Part := Part + Text[At];
                  Inc(At);
                end;
              end
              else
              begin
                Inc(At);
                Start := At;
                if (At <= Length(Text)) and (Text[At] = '$') then
                  Inc(At);
                while (At <= Length(Text)) and
                      (Text[At] in ['0'..'9', 'A'..'F', 'a'..'f']) do
                  Inc(At);
                Code := StrToIntDef(Copy(Text, Start, At - Start), -1);
                if (Code < 0) or (Code > 255) then
                  Failed := True
                else
                  Part := Part + Chr(Code);
              end;
            Result := MakeStr(Part);
          end;
        'A'..'Z', 'a'..'z', '_':
          begin
            Name := ReadIdent;
            if Peek = '(' then
            begin
              Inc(At);
              // Low(Массив), High(Массив) - по имени, не по значению
              if (Name = 'LOW') or (Name = 'HIGH') then
              begin
                Part := ReadIdent;
                if Peek <> ')' then
                begin
                  Failed := True;
                  Exit;
                end;
                Inc(At);
                Result := FromEnv(Part + '.' + Name);
                Exit;
              end;
              SetLength(Args, 0);
              if Peek <> ')' then
                repeat
                  SetLength(Args, Length(Args) + 1);
                  Args[High(Args)] := ParseExpr;
                  if Failed then
                    Exit;
                  if Peek = ',' then
                    Inc(At)
                  else
                    Break;
                until False;
              if Peek <> ')' then
              begin
                Failed := True;
                Exit;
              end;
              Inc(At);
              if (Name = 'COPY') and (Length(Args) = 3) and not Args[0].IsInt and
                 Args[1].IsInt and Args[2].IsInt then
                Result := MakeStr(Copy(Args[0].Str, Args[1].Int, Args[2].Int))
              else if (Name = 'POS') and (Length(Args) = 2) and
                      not Args[0].IsInt and not Args[1].IsInt then
                Result := MakeInt(Pos(Args[0].Str, Args[1].Str))
              else if (Name = 'LENGTH') and (Length(Args) = 1) and
                      not Args[0].IsInt then
                Result := MakeInt(Length(Args[0].Str))
              else if (Name = 'INTTOSTR') and (Length(Args) = 1) and
                      Args[0].IsInt then
                Result := MakeStr(IntToStr(Args[0].Int))
              else if (Name = 'UPPERCASE') and (Length(Args) = 1) and
                      not Args[0].IsInt then
                Result := MakeStr(UpperCase(Args[0].Str))
              else if (Name = 'LOWERCASE') and (Length(Args) = 1) and
                      not Args[0].IsInt then
                Result := MakeStr(LowerCase(Args[0].Str))
              else if (Name = 'TRIM') and (Length(Args) = 1) and
                      not Args[0].IsInt then
                Result := MakeStr(Trim(Args[0].Str))
              else
                Failed := True;
              Exit;
            end;
            if Peek = '[' then
            begin
              Inc(At);
              Index := ParseExpr;
              if Failed or not Index.IsInt or (Peek <> ']') then
              begin
                Failed := True;
                Exit;
              end;
              Inc(At);
              Result := FromEnv(Name + '[' + IntToStr(Index.Int) + ']');
              Exit;
            end;
            if Peek = '.' then
            begin
              Failed := True;
              Exit;
            end;
            Result := FromEnv(Name);
          end;
      else
        Failed := True;
      end;
    end;

  var
    Right: TConstValue;
    Op: Char;
  begin
    Result := Factor;
    while not Failed and (Peek in ['+', '-']) do
    begin
      Op := Peek;
      Inc(At);
      Right := Factor;
      if Failed then
        Break;
      if Result.IsInt and Right.IsInt then
      begin
        if Op = '+' then
          Result.Int := Result.Int + Right.Int
        else
          Result.Int := Result.Int - Right.Int;
      end
      else if (Op = '+') and not Result.IsInt and not Right.IsInt then
        Result.Str := Result.Str + Right.Str
      else
        Failed := True;
    end;
  end;

begin
  Text := AExpr;
  At := 1;
  Failed := False;
  AValue := ParseExpr;
  SkipSpaces;
  Result := not Failed and (At > Length(Text));
end;

// Константы процедуры с заголовком AHead (до её begin): простые
// (Имя = выражение) и массивы (Имя: array[A..B] of Тип = (...)) - в AEnv.
// Константы вложенных процедур не берутся.
procedure RoutineConstEnv(ALines: TStrings; AHead, ABodyStart: Integer;
  AEnv: TStrings);
var
  Line, Semi, Depth, CharIndex, Eq, Colon, Open, Close, DotDot, Item,
    LowBound, HighBound: Integer;
  Section, Word, Code, Decl, Name, TypeText, Items: string;
  InQuote: Boolean;
  Parts: TStringList;
  Value: TConstValue;
  Pending: string;
begin
  AEnv.Clear;
  Section := '';
  Pending := '';
  Parts := TStringList.Create;
  try
    for Line := AHead + 1 to ABodyStart - 1 do
    begin
      Code := Trim(StripComment(ALines[Line]));
      if Code = '' then
        Continue;
      Word := FirstWordOf(Code);
      if (Word = 'PROCEDURE') or (Word = 'FUNCTION') then
        Break;
      if (Word = 'CONST') or (Word = 'VAR') or (Word = 'TYPE') or
         (Word = 'LABEL') then
      begin
        Section := Word;
        Pending := '';
        Code := Trim(Copy(Code, Length(Word) + 1, MaxInt));
        if Code = '' then
          Continue;
      end;
      if Section <> 'CONST' then
        Continue;
      Pending := Pending + ' ' + Code;
      // Объявление кончается на ; вне кавычек и скобок
      repeat
        Depth := 0;
        InQuote := False;
        Semi := 0;
        for CharIndex := 1 to Length(Pending) do
        begin
          if Pending[CharIndex] = '''' then
            InQuote := not InQuote
          else if not InQuote then
            case Pending[CharIndex] of
              '(', '[': Inc(Depth);
              ')', ']': Dec(Depth);
              ';':
                if Depth = 0 then
                begin
                  Semi := CharIndex;
                  Break;
                end;
            end;
        end;
        if Semi = 0 then
          Break;
        Decl := Trim(Copy(Pending, 1, Semi - 1));
        Pending := Copy(Pending, Semi + 1, MaxInt);
        Eq := Pos('=', Decl);
        Colon := Pos(':', Decl);
        if Eq = 0 then
          Continue;
        if (Colon = 0) or (Colon > Eq) then
        begin
          // Имя = выражение
          Name := UpperCase(Trim(Copy(Decl, 1, Eq - 1)));
          if IsValidIdent(Name) and
             EvalConstExpr(Trim(Copy(Decl, Eq + 1, MaxInt)), AEnv, Value) then
            AEnv.Values[Name] := ConstText(Value);
          Continue;
        end;
        // Имя: array[A..B] of Тип = (элементы)
        Name := UpperCase(Trim(Copy(Decl, 1, Colon - 1)));
        TypeText := UpperCase(Trim(Copy(Decl, Colon + 1, Eq - Colon - 1)));
        Items := Trim(Copy(Decl, Eq + 1, MaxInt));
        Open := Pos('[', TypeText);
        Close := Pos(']', TypeText);
        DotDot := Pos('..', TypeText);
        if not IsValidIdent(Name) or (Copy(TypeText, 1, 5) <> 'ARRAY') or
           (Open = 0) or (Close < Open) or (DotDot < Open) or (DotDot > Close) or
           (Items = '') or (Items[1] <> '(') or (Items[Length(Items)] <> ')') then
          Continue;
        if not EvalConstExpr(Copy(TypeText, Open + 1, DotDot - Open - 1), AEnv,
                             Value) or not Value.IsInt then
          Continue;
        LowBound := Value.Int;
        if not EvalConstExpr(Copy(TypeText, DotDot + 2, Close - DotDot - 2), AEnv,
                             Value) or not Value.IsInt then
          Continue;
        HighBound := Value.Int;
        SplitCallArgs(Copy(Items, 2, Length(Items) - 2), Parts);
        if Parts.Count <> HighBound - LowBound + 1 then
          Continue;
        for Item := 0 to Parts.Count - 1 do
          if EvalConstExpr(Parts[Item], AEnv, Value) then
            AEnv.Values[Name + '[' + IntToStr(LowBound + Item) + ']'] :=
              ConstText(Value);
        AEnv.Values[Name + '.LOW'] := 'I:' + IntToStr(LowBound);
        AEnv.Values[Name + '.HIGH'] := 'I:' + IntToStr(HighBound);
      until False;
    end;
  finally
    Parts.Free;
  end;
end;

// Событие, которое может прийти, пока форма загружается из .dfm или ещё
// идёт FormCreate: размер, смена значения, рисование, показ. Из .dfm
// обработчик назначается раньше, чем код создаст и настроит то, к чему он
// обращается (Status2Resize берёт Panels[1], а панели добавляет FormCreate).
// Такие назначения остаются в коде - там же, где были.
function IsLoadTimeEvent(const AEvent: string): Boolean;
const
  Exact: array[0..9] of string = ('OnResize', 'OnCanResize',
    'OnConstrainedResize', 'OnChange', 'OnChanging', 'OnPaint', 'OnShow',
    'OnHide', 'OnMeasureItem', 'OnAlignPosition');
var
  Index: Integer;
begin
  Result := (CompareText(Copy(AEvent, 1, 6), 'OnDraw') = 0) or
            (CompareText(Copy(AEvent, 1, 12), 'OnCustomDraw') = 0) or
            (CompareText(Copy(AEvent, 1, 20), 'OnAdvancedCustomDraw') = 0);
  if not Result then
    for Index := Low(Exact) to High(Exact) do
      if CompareText(AEvent, Exact[Index]) = 0 then
      begin
        Result := True;
        Exit;
      end;
end;

// ---------------------------------------------------------------------------
//  Блоки кода: один проход по модулю. Для каждой строки - выполняется ли
//  она всегда, когда выполняется её процедура (Plain), и какой блок её
//  непосредственно содержит.
// ---------------------------------------------------------------------------

type
  TUnitScan = class
  public
    // Строка начинается в теле процедуры, вне условных частей: только
    // begin ... end, try ... finally ... end, и не после then/else/do
    Plain: array of Boolean;
    // Строка, где открыт самый внутренний блок вокруг начала строки; -1
    Inner: array of Integer;
    // Вид этого блока: M - тело процедуры, B - begin, C - begin после
    // then/else/do, T - try, F - finally, E - except, S - case, R - repeat,
    // A - asm
    InnerKind: array of Char;
    // У блока после then/else/do - строка, где стоит это слово; иначе -1
    InnerCond: array of Integer;
    // Для строки, где открыт блок, - строка его end (until); -1
    BlockEnd: array of Integer;
    // Строка begin тела процедуры, в котором стоит строка; -1 - вне тела
    BodyStart: array of Integer;
    // Строка начинает самостоятельный оператор: перед ней нет then, else
    // или do, к которым она относится
    StmtStart: array of Boolean;
    procedure Scan(ALines: TStrings);
  end;

procedure TUnitScan.Scan(ALines: TStrings);
var
  FrameKind: array of Char;
  FrameCond: array of Boolean;
  FrameLine, FrameCondLine: array of Integer;
  Depth, LineIndex, Level, CharPos, TextLen, WordStart: Integer;
  Pending, InBrace, InStar, LinePlain: Boolean;
  PendingLine: Integer;
  Text, UpperWord, HeadWord: string;
  PrevChar: Char;

  procedure Push(AKind: Char);
  begin
    if Depth >= Length(FrameKind) then
    begin
      SetLength(FrameKind, Depth + 16);
      SetLength(FrameCond, Depth + 16);
      SetLength(FrameLine, Depth + 16);
      SetLength(FrameCondLine, Depth + 16);
    end;
    if (AKind = 'B') and Pending then
      AKind := 'C';
    FrameKind[Depth] := AKind;
    FrameCond[Depth] := Pending;
    FrameLine[Depth] := LineIndex;
    if Pending then
      FrameCondLine[Depth] := PendingLine
    else
      FrameCondLine[Depth] := -1;
    Inc(Depth);
    Pending := False;
  end;

  procedure Pop;
  begin
    if Depth = 0 then
      Exit;
    Dec(Depth);
    BlockEnd[FrameLine[Depth]] := LineIndex;
    Pending := False;
  end;

  procedure HandleWord(const AWord: string);
  begin
    // Внутри asm - только его end
    if (Depth > 0) and (FrameKind[Depth - 1] = 'A') and (AWord <> 'END') then
      Exit;
    if AWord = 'BEGIN' then
    begin
      if Depth = 0 then
      begin
        Pending := False;
        Push('M');
      end
      else
        Push('B');
    end
    else if AWord = 'ASM' then
      Push('A')
    else if Depth = 0 then
      // Вне тела: end классов и записей, case вариантных записей
      Exit
    else if AWord = 'TRY' then
      Push('T')
    else if AWord = 'CASE' then
      Push('S')
    else if AWord = 'REPEAT' then
      Push('R')
    else if AWord = 'FINALLY' then
    begin
      if FrameKind[Depth - 1] = 'T' then
        FrameKind[Depth - 1] := 'F';
    end
    else if AWord = 'EXCEPT' then
    begin
      if FrameKind[Depth - 1] = 'T' then
        FrameKind[Depth - 1] := 'E';
    end
    else if AWord = 'UNTIL' then
    begin
      if FrameKind[Depth - 1] = 'R' then
        Pop;
    end
    else if AWord = 'END' then
      Pop
    else if (AWord = 'THEN') or (AWord = 'ELSE') or (AWord = 'DO') then
    begin
      Pending := True;
      PendingLine := LineIndex;
    end;
  end;

begin
  SetLength(Plain, ALines.Count);
  SetLength(Inner, ALines.Count);
  SetLength(InnerKind, ALines.Count);
  SetLength(InnerCond, ALines.Count);
  SetLength(BlockEnd, ALines.Count);
  SetLength(BodyStart, ALines.Count);
  SetLength(StmtStart, ALines.Count);
  Depth := 0;
  Pending := False;
  PendingLine := -1;
  InBrace := False;
  InStar := False;
  for LineIndex := 0 to ALines.Count - 1 do
  begin
    BlockEnd[LineIndex] := -1;
    Text := ALines[LineIndex];
    // Заголовок процедуры с начала строки или раздел модуля: всё, что
    // было открыто, закрыто (защита от ошибки разбора в чужом коде)
    if not InBrace and not InStar and (Text <> '') and (Text[1] <> ' ') then
    begin
      HeadWord := UpperCase(FirstWordOf(Text));
      if (HeadWord = 'PROCEDURE') or (HeadWord = 'FUNCTION') or
         (HeadWord = 'CONSTRUCTOR') or (HeadWord = 'DESTRUCTOR') or
         (HeadWord = 'CLASS') or
         (HeadWord = 'IMPLEMENTATION') or (HeadWord = 'INITIALIZATION') or
         (HeadWord = 'FINALIZATION') then
      begin
        Depth := 0;
        Pending := False;
      end;
    end;
    // Состояние на начало строки
    LinePlain := (Depth > 0) and not Pending and not InBrace and not InStar;
    for Level := 0 to Depth - 1 do
      if FrameCond[Level] or not (FrameKind[Level] in ['M', 'B', 'T', 'F']) then
        LinePlain := False;
    Plain[LineIndex] := LinePlain;
    StmtStart[LineIndex] := not Pending;
    if Depth > 0 then
    begin
      Inner[LineIndex] := FrameLine[Depth - 1];
      InnerKind[LineIndex] := FrameKind[Depth - 1];
      InnerCond[LineIndex] := FrameCondLine[Depth - 1];
      if FrameKind[0] = 'M' then
        BodyStart[LineIndex] := FrameLine[0]
      else
        BodyStart[LineIndex] := -1;
    end
    else
    begin
      BodyStart[LineIndex] := -1;
      Inner[LineIndex] := -1;
      InnerKind[LineIndex] := ' ';
      InnerCond[LineIndex] := -1;
    end;
    // Слова строки
    TextLen := Length(Text);
    CharPos := 1;
    PrevChar := ' ';
    while CharPos <= TextLen do
    begin
      if InBrace then
      begin
        if Text[CharPos] = '}' then
          InBrace := False;
        Inc(CharPos);
        Continue;
      end;
      if InStar then
      begin
        if (Text[CharPos] = '*') and (CharPos < TextLen) and
           (Text[CharPos + 1] = ')') then
        begin
          InStar := False;
          Inc(CharPos, 2);
        end
        else
          Inc(CharPos);
        Continue;
      end;
      case Text[CharPos] of
        '{':
          begin
            InBrace := True;
            Inc(CharPos);
          end;
        '(':
          if (CharPos < TextLen) and (Text[CharPos + 1] = '*') then
          begin
            InStar := True;
            Inc(CharPos, 2);
          end
          else
          begin
            PrevChar := '(';
            Inc(CharPos);
          end;
        '/':
          if (CharPos < TextLen) and (Text[CharPos + 1] = '/') then
            Break
          else
          begin
            PrevChar := '/';
            Inc(CharPos);
          end;
        '''':
          begin
            Inc(CharPos);
            while (CharPos <= TextLen) and (Text[CharPos] <> '''') do
              Inc(CharPos);
            Inc(CharPos);
            PrevChar := '''';
          end;
        ';':
          begin
            Pending := False;
            PrevChar := ';';
            Inc(CharPos);
          end;
        'A'..'Z', 'a'..'z', '_':
          begin
            WordStart := CharPos;
            while (CharPos <= TextLen) and IsIdentChar(Text[CharPos]) do
              Inc(CharPos);
            // После точки - член объекта (X.Enabled), не ключевое слово
            if PrevChar <> '.' then
            begin
              UpperWord := UpperCase(Copy(Text, WordStart, CharPos - WordStart));
              HandleWord(UpperWord);
            end;
            PrevChar := 'A';
          end;
        '0'..'9', '#', '$':
          begin
            while (CharPos <= TextLen) and
                  (IsIdentChar(Text[CharPos]) or (Text[CharPos] in ['#', '$'])) do
              Inc(CharPos);
            PrevChar := '0';
          end;
        ' ', #9:
          Inc(CharPos);
      else
        PrevChar := Text[CharPos];
        Inc(CharPos);
      end;
    end;
  end;
end;

// Класс AClass - AName или его наследник (по имени: сам тип в модуле может
// быть не виден)
function ClassIs(AClass: TClass; const AName: string): Boolean;
begin
  Result := False;
  while AClass <> nil do
  begin
    if CompareText(AClass.ClassName, AName) = 0 then
    begin
      Result := True;
      Exit;
    end;
    AClass := AClass.ClassParent;
  end;
end;

// Блок «по требованию» вокруг строки ALine:
//   if X = nil then            (или if not Assigned(X) then)
//   begin
//     ...
//   end;
// ALine стоит прямо в этом begin ... end. AGuard - X (заглавными), ACond -
// строка if, AOpen - строка begin, AEnd - строка end;.
function FindLazyBlock(AScan: TUnitScan; AKeys: TStrings; ALine: Integer;
  var AGuard: string; var ACond, AOpen, AEnd: Integer): Boolean;
var
  CondKey, Middle: string;
  Index: Integer;
begin
  Result := False;
  AGuard := '';
  AOpen := AScan.Inner[ALine];
  ACond := AScan.InnerCond[ALine];
  if (AOpen < 0) or (AScan.InnerKind[ALine] <> 'C') or (ACond < 0) or
     not AScan.StmtStart[ACond] then
    Exit;
  AEnd := AScan.BlockEnd[AOpen];
  if (AEnd < 0) or (AKeys[AEnd] <> 'END;') then
    Exit;
  // Условие сравнивается без пробелов вовсе
  CondKey := StringReplace(AKeys[ACond], ' ', '', [rfReplaceAll]);
  if AOpen = ACond then
  begin
    if Copy(CondKey, Length(CondKey) - 4, 5) <> 'BEGIN' then
      Exit;
    Delete(CondKey, Length(CondKey) - 4, 5);
  end
  else
  begin
    if AKeys[AOpen] <> 'BEGIN' then
      Exit;
    for Index := ACond + 1 to AOpen - 1 do
      if AKeys[Index] <> '' then
        Exit;
  end;
  if (Copy(CondKey, 1, 2) <> 'IF') or
     (Copy(CondKey, Length(CondKey) - 3, 4) <> 'THEN') then
    Exit;
  Middle := Copy(CondKey, 3, Length(CondKey) - 6);
  // if (X = nil) then
  if (Middle <> '') and (Middle[1] = '(') and (Middle[Length(Middle)] = ')') then
    Middle := Copy(Middle, 2, Length(Middle) - 2);
  if Copy(Middle, Length(Middle) - 3, 4) = '=NIL' then
    AGuard := Copy(Middle, 1, Length(Middle) - 4)
  else if (Copy(Middle, 1, 12) = 'NOTASSIGNED(') and
          (Middle[Length(Middle)] = ')') then
    AGuard := Copy(Middle, 13, Length(Middle) - 13);
  Result := (AGuard <> '') and IsValidIdent(AGuard);
end;

// Строки блока по требованию: создание полей формы (X := TКласс.Create,
// X := Помощник(...)), создание локальных переменных (Grp :=
// TMenuItem.Create(...)), вызовы помощников без переменной и строки X....
// этих полей и переменных. APartners - поля, созданные в блоке (как в
// тексте). False - в блоке есть другая строка, её номер - ABadLine.
function LazyBlockParts(ALines, AKeys: TStrings; AOpen, AEnd,
  AClassFirst, AClassLast: Integer; AHelpers: TList; APartners: TStrings;
  var ABadLine: Integer): Boolean;
var
  Index, Partner, Assign, CallLast, LineIndex: Integer;
  Code, Lhs, Key: string;
  Known: Boolean;
  Locals, CallArgs: TStringList;
  CallLines: array of Boolean;
  Helper: THelperInfo;
begin
  Result := False;
  APartners.Clear;
  Locals := TStringList.Create;
  CallArgs := TStringList.Create;
  try
    SetLength(CallLines, AEnd - AOpen + 1);
    for Index := 0 to High(CallLines) do
      CallLines[Index] := False;
    for Index := AOpen + 1 to AEnd - 1 do
    begin
      Code := StripComment(ALines[Index]);
      Assign := Pos(':=', Code);
      // Вызов помощника: Поле := Помощник(...); или Помощник(...);
      if ParseHelperCall(ALines, Index, AHelpers, Helper, Lhs, CallArgs,
                         CallLast) and Helper.Simple and
         (Helper.OutIdx < 0) and not Helper.LocalCreator then
      begin
        if Lhs <> '' then
        begin
          if not IsFormField(ALines, AClassFirst, AClassLast, Lhs) then
          begin
            ABadLine := Index;
            Exit;
          end;
          APartners.Add(Lhs);
        end;
        for LineIndex := Index to CallLast do
          if LineIndex < AEnd then
            CallLines[LineIndex - AOpen] := True;
        Continue;
      end;
      if (Assign > 0) and (CodeCreatePos(UpperCase(Code)) > 0) then
      begin
        Lhs := Trim(Copy(Code, 1, Assign - 1));
        if not IsValidIdent(Lhs) then
        begin
          ABadLine := Index;
          Exit;
        end;
        // Поле формы - участник блока; иначе - локальная переменная
        if IsFormField(ALines, AClassFirst, AClassLast, Lhs) then
          APartners.Add(Lhs)
        else if Locals.IndexOf(Lhs) < 0 then
          Locals.Add(Lhs);
      end;
    end;
    for Index := AOpen + 1 to AEnd - 1 do
    begin
      Key := AKeys[Index];
      if (Key = '') or CallLines[Index - AOpen] then
        Continue;
      Known := False;
      for Partner := 0 to APartners.Count + Locals.Count - 1 do
      begin
        if Partner < APartners.Count then
          Lhs := UpperCase(APartners[Partner])
        else
          Lhs := UpperCase(Locals[Partner - APartners.Count]);
        if (Copy(Key, 1, Length(Lhs) + 1) = Lhs + '.') or
           (Copy(Key, 1, Length(Lhs) + 2) = Lhs + ':=') then
        begin
          Known := True;
          Break;
        end;
      end;
      if not Known then
      begin
        ABadLine := Index;
        Exit;
      end;
    end;
    Result := True;
  finally
    CallArgs.Free;
    Locals.Free;
  end;
end;

// Присваивания свойствам AVarName в строке-ключе (где угодно в строке, в
// том числе после then): имена свойств заглавными - в ACounts, в Objects -
// сколько раз
procedure CountPropAssigns(const AKey, AVarName: string; ACounts: TStringList);
var
  At, After, Stop, Count: Integer;
  Prefix, PropName: string;
begin
  Prefix := UpperCase(AVarName) + '.';
  At := Pos(Prefix, AKey);
  while At > 0 do
  begin
    After := At + Length(Prefix);
    if (At = 1) or not IsIdentChar(AKey[At - 1]) then
    begin
      Stop := After;
      while (Stop <= Length(AKey)) and
            (IsIdentChar(AKey[Stop]) or (AKey[Stop] = '.')) do
        Inc(Stop);
      if Copy(AKey, Stop, 2) = ':=' then
      begin
        PropName := Copy(AKey, After, Stop - After);
        Count := ACounts.IndexOf(PropName);
        if Count < 0 then
          ACounts.AddObject(PropName, TObject(1))
        else
          ACounts.Objects[Count] := TObject(Integer(ACounts.Objects[Count]) + 1);
      end;
    end;
    At := PosEx(Prefix, AKey, After);
  end;
end;

// Строка класса - объявление полей "A, B: TТип;" и, может быть,
// комментарий //. ANames - имена, AType - тип, ATail - комментарий.
// False - это не поле (метод, свойство, слово видимости...).
function ParseFieldLine(const ALine: string; ANames: TStrings;
  var AType, ATail: string): Boolean;
var
  Colon, Cut, Comma, CharIndex: Integer;
  Text, Code, Left, Right, Word: string;
begin
  Result := False;
  Text := Trim(ALine);
  Cut := Pos('//', Text);
  if Cut > 0 then
  begin
    Code := TrimRight(Copy(Text, 1, Cut - 1));
    ATail := Copy(Text, Cut, MaxInt);
  end
  else
  begin
    Code := Text;
    ATail := '';
  end;
  Colon := Pos(':', Code);
  if (Colon = 0) or (Code[Length(Code)] <> ';') then
    Exit;
  Word := FirstWordOf(Code);
  if (Word = 'PROCEDURE') or (Word = 'FUNCTION') or (Word = 'PROPERTY') or
     (Word = 'CONSTRUCTOR') or (Word = 'DESTRUCTOR') or (Word = 'CLASS') then
    Exit;
  Left := Copy(Code, 1, Colon - 1);
  Right := Trim(Copy(Code, Colon + 1, Length(Code) - Colon - 1));
  // Тип - одно имя, можно с модулем через точку
  if Right = '' then
    Exit;
  for CharIndex := 1 to Length(Right) do
    if not (IsIdentChar(Right[CharIndex]) or (Right[CharIndex] = '.')) then
      Exit;
  ANames.Clear;
  repeat
    Comma := Pos(',', Left);
    if Comma > 0 then
    begin
      ANames.Add(Trim(Copy(Left, 1, Comma - 1)));
      Delete(Left, 1, Comma);
    end
    else
      ANames.Add(Trim(Left));
  until Comma = 0;
  for CharIndex := 0 to ANames.Count - 1 do
    if not IsValidIdent(ANames[CharIndex]) then
      Exit;
  AType := Right;
  Result := True;
end;

// Строка end; вложенной процедуры, чей заголовок - в строке AHead (с её
// собственными вложенными процедурами). -1 - не нашлось.
function NestedRoutineEnd(ALines: TStrings; AHead: Integer): Integer;
var
  Index, ChainIndex, Depth, Pending: Integer;
  Chains: TStringList;
  Chain: string;
begin
  Result := -1;
  Depth := 0;
  Pending := 0;
  Chains := TStringList.Create;
  try
    for Index := AHead to ALines.Count - 1 do
    begin
      ScanChains(StripComment(ALines[Index]), Chains);
      for ChainIndex := 0 to Chains.Count - 1 do
      begin
        Chain := Chains[ChainIndex];
        if ((Chain = 'PROCEDURE') or (Chain = 'FUNCTION')) and (Depth = 0) then
          Inc(Pending)
        else if (Chain = 'BEGIN') or (Chain = 'CASE') or (Chain = 'TRY') or
                (Chain = 'ASM') or (Chain = 'RECORD') then
          Inc(Depth)
        else if Chain = 'END' then
        begin
          Dec(Depth);
          if Depth = 0 then
          begin
            Dec(Pending);
            if Pending <= 0 then
            begin
              Result := Index;
              Exit;
            end;
          end;
        end;
      end;
    end;
  finally
    Chains.Free;
  end;
end;

// Объявление локальной переменной AName в разделах var процедуры, чей
// заголовок - строка AHead (до её begin или до первой вложенной процедуры).
// ADeclLine - строка с объявлением, AVarLine - строка слова var этого
// раздела, ANamesInSection - сколько всего имён объявлено в разделе.
// False - не нашлось.
function FindLocalDecl(ALines: TStrings; AHead: Integer; const AName: string;
  var ADeclLine, AVarLine, ANamesInSection: Integer): Boolean;
var
  Index, SectionVar, SectionNames, HeadEnd, Depth, CharIndex: Integer;
  Word, Code, DeclType, DeclTail: string;
  InVar, HeadDone: Boolean;
  Names: TStringList;

  // Раздел var закончился: если объявление в нём - запомнить
  function SectionDone: Boolean;
  begin
    Result := ADeclLine >= 0;
    if Result then
    begin
      AVarLine := SectionVar;
      ANamesInSection := SectionNames;
    end;
  end;

begin
  Result := False;
  ADeclLine := -1;
  AVarLine := -1;
  ANamesInSection := 0;
  InVar := False;
  SectionVar := -1;
  SectionNames := 0;
  // Заголовок может идти на несколько строк (параметры с var): разделы
  // процедуры - после его ; вне скобок
  HeadEnd := AHead;
  Depth := 0;
  for Index := AHead to ALines.Count - 1 do
  begin
    Code := StripComment(ALines[Index]);
    HeadDone := False;
    for CharIndex := 1 to Length(Code) do
      case Code[CharIndex] of
        '(': Inc(Depth);
        ')': Dec(Depth);
        ';':
          if Depth = 0 then
          begin
            HeadDone := True;
            Break;
          end;
      end;
    HeadEnd := Index;
    if HeadDone then
      Break;
  end;
  Names := TStringList.Create;
  try
    Index := HeadEnd;
    while Index + 1 < ALines.Count do
    begin
      Inc(Index);
      Code := Trim(StripComment(ALines[Index]));
      if (Code = '') or (Code[1] = '{') then
        Continue;
      Word := FirstWordOf(Code);
      if (Word = 'BEGIN') or (Word = 'ASM') then
      begin
        Result := SectionDone;
        Exit;
      end;
      // Вложенная процедура: её строки пропускаются, разделы var после неё
      // - тоже разделы этой процедуры
      if (Word = 'PROCEDURE') or (Word = 'FUNCTION') then
      begin
        if SectionDone then
        begin
          Result := True;
          Exit;
        end;
        InVar := False;
        Index := NestedRoutineEnd(ALines, Index);
        if Index < 0 then
          Exit;
        Continue;
      end;
      if (Word = 'CONST') or (Word = 'TYPE') or (Word = 'LABEL') or
         (Word = 'RESOURCESTRING') then
      begin
        if SectionDone then
        begin
          Result := True;
          Exit;
        end;
        InVar := False;
        Continue;
      end;
      if Word = 'VAR' then
      begin
        if SectionDone then
        begin
          Result := True;
          Exit;
        end;
        InVar := True;
        SectionVar := Index;
        SectionNames := 0;
        Code := Trim(Copy(Code, 4, MaxInt));
        if Code = '' then
          Continue;
      end;
      if not InVar then
        Continue;
      if ParseFieldLine(Code, Names, DeclType, DeclTail) then
      begin
        Inc(SectionNames, Names.Count);
        if Names.IndexOf(AName) >= 0 then
        begin
          // var A, B: T; в одной строке со словом var - не разбирается
          if (Index = SectionVar) and (Names.Count > 1) then
            Exit;
          ADeclLine := Index;
        end;
      end
      else
        // Что-то сложнее "A, B: TТип;" (массив, запись, значение) - раздел
        // считается непустым
        Inc(SectionNames, 2);
    end;
  finally
    Names.Free;
  end;
end;

// Слово AName в модуле вне строк AFirst..ALast встречается только в
// процедурах, где AName объявлена своей локальной переменной (там она
// закрывает поле формы с тем же именем, и смысл этих строк не меняется).
// False - есть другое место; его строка - в AOtherLine.
function NameFreeForField(ALines: TStrings; const AName: string;
  AFirst, ALast: Integer; var AOtherLine: Integer): Boolean;
var
  Index, Head, RoutineEnd, Scan, DeclLine, VarLine, SectionNames: Integer;
  Word: string;
begin
  Result := False;
  AOtherLine := -1;
  Index := 0;
  while Index < ALines.Count do
  begin
    if ((Index < AFirst) or (Index > ALast)) and
       HasWord(StripComment(ALines[Index]), AName) then
    begin
      // Процедура вокруг строки: заголовок с начала строки выше, её end;
      // - первый такой с начала строки после заголовка
      Head := -1;
      for Scan := Index downto 0 do
        if (ALines[Scan] <> '') and (ALines[Scan][1] <> ' ') then
        begin
          Word := FirstWordOf(ALines[Scan]);
          if (Word = 'PROCEDURE') or (Word = 'FUNCTION') or
             (Word = 'CONSTRUCTOR') or (Word = 'DESTRUCTOR') then
          begin
            Head := Scan;
            Break;
          end;
          // Раздел модуля или end; прежней процедуры - строка вне
          // процедуры. var, const, type с начала строки бывают и у самой
          // процедуры: у глобальных выше найдётся заголовок прежней
          // процедуры, но её end; окажется раньше строки.
          if (Word = 'IMPLEMENTATION') or (Word = 'INTERFACE') or
             (Word = 'INITIALIZATION') or (Word = 'FINALIZATION') or
             (Word = 'END') then
            Break;
        end;
      RoutineEnd := -1;
      if Head >= 0 then
        for Scan := Head + 1 to ALines.Count - 1 do
          if (LeadSpacesOf(ALines[Scan]) = 0) and
             (UpperCase(Trim(ALines[Scan])) = 'END;') then
          begin
            RoutineEnd := Scan;
            Break;
          end;
      if (Head < 0) or (RoutineEnd < Index) or
         not FindLocalDecl(ALines, Head, AName, DeclLine, VarLine,
                           SectionNames) then
      begin
        AOtherLine := Index;
        Exit;
      end;
      // Вся эта процедура проверена
      Index := RoutineEnd + 1;
      Continue;
    end;
    Inc(Index);
  end;
  Result := True;
end;

var
  // Размеры и места компонентов .dfm, которые код не меняет
  // (BTNCOMPILERUN.LEFT=6): на время разбора, иначе nil. По ним считается
  // CmpLeft := btnCompileRun.Left + btnCompileRun.Width + 10.
  GDfmIntValues: TStringList = nil;

// Убрать из значений имя и всё, что через точку от него (X, X.LEFT)
procedure RemoveName(AValues: TStrings; const AName: string);
var
  Index: Integer;
  Prefix: string;
begin
  Prefix := UpperCase(AName) + '.';
  for Index := AValues.Count - 1 downto 0 do
    if (CompareText(AValues.Names[Index], AName) = 0) or
       (CompareText(Copy(AValues.Names[Index], 1, Length(Prefix)),
                    Prefix) = 0) then
      AValues.Delete(Index);
end;

// Значения внутри процедуры-создателя перед оператором AStmtLimit у вызова
// с аргументами AArgs: ACaller - значения у вызывающей процедуры на строке
// вызова. Параметры - посчитанные аргументы, константы - свои; у вложенной
// видны и переменные той процедуры, у метода - только места компонентов
// .dfm (имена с точкой). Компонент (X.WIDTH) - по присвоениям до этого
// оператора; строки, которые остаются, делают упомянутое неизвестным.
procedure HelperScopeValues(AHelper: THelperInfo; AArgs, ACaller: TStrings;
  AStmtLimit: Integer; AValues: TStrings);
var
  Index, ChainIndex, Value, Other: Integer;
  Stmt: THelperStmt;
  OutUpper, Chain, Head: string;
begin
  AValues.Clear;
  for Index := 0 to ACaller.Count - 1 do
    if AHelper.Nested or (Pos('.', ACaller.Names[Index]) > 0) then
      AValues.Add(ACaller[Index]);
  for Index := 0 to AHelper.LocalNames.Count - 1 do
    RemoveName(AValues, AHelper.LocalNames[Index]);
  for Index := 0 to AHelper.Params.Count - 1 do
  begin
    RemoveName(AValues, AHelper.Params[Index]);
    if (Index <> AHelper.OutIdx) and (Index < AArgs.Count) and
       EvalIntExpr(AArgs[Index], ACaller, Value) then
      AValues.Values[UpperCase(AHelper.Params[Index])] := IntToStr(Value);
  end;
  for Index := 0 to AHelper.Consts.Count - 1 do
    AValues.Values[AHelper.Consts.Names[Index]] :=
      Copy(AHelper.Consts[Index], Pos('=', AHelper.Consts[Index]) + 1, MaxInt);
  OutUpper := UpperCase(AHelper.OutName);
  RemoveName(AValues, OutUpper);
  if AStmtLimit > AHelper.Stmts.Count then
    AStmtLimit := AHelper.Stmts.Count;
  for Index := 0 to AStmtLimit - 1 do
  begin
    Stmt := THelperStmt(AHelper.Stmts[Index]);
    case Stmt.Kind of
      hsProp:
        if EvalIntExpr(Stmt.Expr, AValues, Value) then
          AValues.Values[OutUpper + '.' + UpperCase(Stmt.PropName)] :=
            IntToStr(Value)
        else
          RemoveName(AValues, OutUpper + '.' + UpperCase(Stmt.PropName));
      hsOther, hsInc:
        for ChainIndex := 0 to Stmt.Chains.Count - 1 do
        begin
          Chain := Stmt.Chains[ChainIndex];
          Head := ChainHead(Chain);
          if AHelper.Consts.IndexOfName(Head) >= 0 then
            Continue;
          if (Head = OutUpper) and (Chain <> OutUpper) then
          begin
            // X.Font.Size - неизвестно всё X.FONT
            Chain := Copy(Chain, Length(OutUpper) + 2, MaxInt);
            RemoveName(AValues, OutUpper + '.' + ChainHead(Chain));
          end
          else if (Head = OutUpper) and Stmt.BareSafe then
          begin
            // Передан процедуре, которая место и размер не меняет
            for Other := AValues.Count - 1 downto 0 do
              if (CompareText(Copy(AValues.Names[Other], 1,
                                   Length(OutUpper) + 1), OutUpper + '.') = 0) and
                 (CompareText(AValues.Names[Other], OutUpper + '.LEFT') <> 0) and
                 (CompareText(AValues.Names[Other], OutUpper + '.TOP') <> 0) and
                 (CompareText(AValues.Names[Other], OutUpper + '.WIDTH') <> 0) and
                 (CompareText(AValues.Names[Other], OutUpper + '.HEIGHT') <> 0) then
                AValues.Delete(Other);
          end
          else
            RemoveName(AValues, Head);
        end;
    end;
  end;
end;

// Вызов процедуры-создателя в вызывающей процедуре: сдвиг параметра или
// переменной (ALeft := ALeft + ABtn.Width + 1) - посчитанным числом, если
// получается; var-аргументы и имена из остающихся строк - неизвестны.
procedure VarHelperCallEffect(AHelper: THelperInfo; AArgs, AValues: TStrings;
  APlain: Boolean);
var
  Scope: TStringList;
  Target: string;
  Delta, OldValue, Index, At: Integer;
  Known: Boolean;
begin
  Target := '';
  if (AHelper.IncParam >= 0) and (AHelper.IncParam < AArgs.Count) then
    Target := UpperCase(Trim(AArgs[AHelper.IncParam]))
  else if AHelper.IncVar <> '' then
    Target := UpperCase(AHelper.IncVar);
  if not IsValidIdent(Target) then
    Target := '';
  Known := False;
  OldValue := 0;
  if APlain and (Target <> '') and (AValues.Values[Target] <> '') then
  begin
    OldValue := StrToIntDef(AValues.Values[Target], 0);
    Scope := TStringList.Create;
    try
      HelperScopeValues(AHelper, AArgs, AValues, AHelper.Stmts.Count - 1,
                        Scope);
      Known := EvalIntExpr(AHelper.IncExpr, Scope, Delta);
    finally
      Scope.Free;
    end;
  end;
  for Index := 0 to AHelper.VarParams.Count - 1 do
  begin
    At := AHelper.Params.IndexOf(AHelper.VarParams[Index]);
    if (At >= 0) and (At < AArgs.Count) and (At <> AHelper.OutIdx) then
      RemoveName(AValues, Trim(AArgs[At]));
  end;
  for Index := 0 to AHelper.Clobbers.Count - 1 do
    RemoveName(AValues, AHelper.Clobbers[Index]);
  if Target <> '' then
  begin
    RemoveName(AValues, Target);
    if Known then
      AValues.Values[Target] := IntToStr(OldValue + Delta);
  end;
end;

// Известные целые значения на строке ALine процедуры, чей заголовок -
// AHead: её константы (const Row1 = 1;) и переменные, которым в теле до
// этой строки присваиваются числа, со сдвигами Inc/Dec и сдвигами из
// помощников (Inc(X, W + 3) в MakeBtn). Строки не на прямом пути процедуры
// (после then, в цикле) и присвоения, которые не посчитать, делают
// переменную неизвестной. Переменные, которые меняют вложенные процедуры
// (кроме таких помощников), неизвестны всегда. AValues - ИМЯ=число.
procedure RoutineIntValues(ALines, AKeys: TStrings; AScan: TUnitScan;
  AHelpers: TList; AHead, ALine: Integer; AValues: TStrings);
var
  Index, BodyStart, Value, Assign, CommaAt: Integer;
  Key, Word, Name, Expr, Code, CallLhs: string;
  InConst, NestedSeen: Boolean;
  Blocked, CallArgs, ParamValues: TStringList;
  Helper: THelperInfo;
  CallLast, ParamIndex, HelperIndex: Integer;
  Allowed: Boolean;
begin
  AValues.Clear;
  if (ALine < 0) or (ALine >= ALines.Count) then
    Exit;
  BodyStart := AScan.BodyStart[ALine];
  if (BodyStart < 0) or (AHead < 0) then
    Exit;
  Blocked := TStringList.Create;
  CallArgs := TStringList.Create;
  ParamValues := TStringList.Create;
  try
    // Места компонентов .dfm, которые код не меняет
    if GDfmIntValues <> nil then
      AValues.AddStrings(GDfmIntValues);
    // Константы - до тела и до первой вложенной процедуры (константы
    // вложенной - её собственные); присвоения во вложенных процедурах - в
    // Blocked
    InConst := False;
    NestedSeen := False;
    for Index := AHead + 1 to BodyStart - 1 do
    begin
      Code := Trim(StripComment(ALines[Index]));
      if Code = '' then
        Continue;
      Word := FirstWordOf(Code);
      if (Word = 'PROCEDURE') or (Word = 'FUNCTION') then
      begin
        InConst := False;
        NestedSeen := True;
      end;
      if (Word = 'VAR') or (Word = 'TYPE') or (Word = 'LABEL') then
        InConst := False;
      if (Word = 'CONST') and not NestedSeen then
      begin
        InConst := True;
        Code := Trim(Copy(Code, 6, MaxInt));
        if Code = '' then
          Continue;
      end;
      if InConst then
      begin
        Assign := Pos('=', Code);
        if (Assign > 0) and (Pos(':', Copy(Code, 1, Assign)) = 0) and
           (Code[Length(Code)] = ';') then
        begin
          Name := Trim(Copy(Code, 1, Assign - 1));
          Expr := Trim(Copy(Code, Assign + 1, Length(Code) - Assign - 1));
          if IsValidIdent(Name) and EvalIntExpr(Expr, AValues, Value) then
            AValues.Values[UpperCase(Name)] := IntToStr(Value);
        end;
        Continue;
      end;
      // Вложенная процедура что-то присваивает или сдвигает
      Key := AKeys[Index];
      Assign := Pos(':=', Key);
      Name := '';
      if Assign > 0 then
        Name := Copy(Key, 1, Assign - 1)
      else if (Copy(Key, 1, 4) = 'INC(') or (Copy(Key, 1, 4) = 'DEC(') then
      begin
        Name := Copy(Key, 5, MaxInt);
        CommaAt := Pos(',', Name);
        if CommaAt = 0 then
          CommaAt := Pos(')', Name);
        Name := Copy(Name, 1, CommaAt - 1);
      end;
      if (Name <> '') and IsValidIdent(Name) and
         (CompareText(Name, 'RESULT') <> 0) then
      begin
        Allowed := False;
        for HelperIndex := 0 to AHelpers.Count - 1 do
          if CompareText(THelperInfo(AHelpers[HelperIndex]).IncVar,
                         Name) = 0 then
            Allowed := True;
        if not Allowed then
          Blocked.Add(UpperCase(Name));
      end;
    end;

    // Тело до строки ALine
    for Index := BodyStart + 1 to ALine - 1 do
    begin
      Key := AKeys[Index];
      if Key = '' then
        Continue;
      // Вызов процедуры-создателя: сдвиг, var-аргументы
      if ParseHelperCall(ALines, Index, AHelpers, Helper, CallLhs, CallArgs,
                         CallLast) and (Helper.OutIdx >= 0) then
      begin
        VarHelperCallEffect(Helper, CallArgs, AValues, AScan.Plain[Index]);
        Continue;
      end;
      // Вызов помощника со сдвигом переменной
      if ParseHelperCall(ALines, Index, AHelpers, Helper, CallLhs, CallArgs,
                         CallLast) and (Helper.IncVar <> '') then
      begin
        Name := UpperCase(Helper.IncVar);
        ParamValues.Assign(AValues);
        for ParamIndex := 0 to Helper.Params.Count - 1 do
          if (ParamIndex < CallArgs.Count) and
             EvalIntExpr(CallArgs[ParamIndex], AValues, Value) then
            ParamValues.Values[UpperCase(Helper.Params[ParamIndex])] :=
              IntToStr(Value);
        if AScan.Plain[Index] and (AValues.Values[Name] <> '') and
           EvalIntExpr(Helper.IncExpr, ParamValues, Value) then
          AValues.Values[Name] :=
            IntToStr(StrToInt(AValues.Values[Name]) + Value)
        else if AValues.IndexOfName(Name) >= 0 then
          AValues.Delete(AValues.IndexOfName(Name));
        Continue;
      end;
      Assign := Pos(':=', Key);
      if Assign > 0 then
      begin
        Name := Copy(Key, 1, Assign - 1);
        if not IsValidIdent(Name) then
        begin
          // X.Left := ... - место X уже не то, что в .dfm
          RemoveName(AValues, Name);
          Continue;
        end;
        Expr := Copy(Key, Assign + 2, MaxInt);
        if (Expr <> '') and (Expr[Length(Expr)] = ';') then
          Delete(Expr, Length(Expr), 1);
        if AScan.Plain[Index] and EvalIntExpr(Expr, AValues, Value) then
          AValues.Values[Name] := IntToStr(Value)
        else if AValues.IndexOfName(Name) >= 0 then
          AValues.Delete(AValues.IndexOfName(Name));
        Continue;
      end;
      if ((Copy(Key, 1, 4) = 'INC(') or (Copy(Key, 1, 4) = 'DEC(')) and
         (Copy(Key, Length(Key) - 1, 2) = ');') then
      begin
        Expr := Copy(Key, 5, Length(Key) - 6);
        CommaAt := Pos(',', Expr);
        if CommaAt > 0 then
        begin
          Name := Copy(Expr, 1, CommaAt - 1);
          Expr := Copy(Expr, CommaAt + 1, MaxInt);
        end
        else
        begin
          Name := Expr;
          Expr := '1';
        end;
        if AScan.Plain[Index] and (AValues.Values[Name] <> '') and
           EvalIntExpr(Expr, AValues, Value) then
        begin
          if Copy(Key, 1, 3) = 'DEC' then
            Value := -Value;
          AValues.Values[Name] :=
            IntToStr(StrToInt(AValues.Values[Name]) + Value);
        end
        else if AValues.IndexOfName(Name) >= 0 then
          AValues.Delete(AValues.IndexOfName(Name));
      end;
    end;
    for Index := 0 to Blocked.Count - 1 do
      if AValues.IndexOfName(Blocked[Index]) >= 0 then
        AValues.Delete(AValues.IndexOfName(Blocked[Index]));
  finally
    ParamValues.Free;
    CallArgs.Free;
    Blocked.Free;
  end;
end;

// Свойство - номер среди пунктов, вкладок, страниц самого компонента
function IsIndexProp(const APropName: string): Boolean;
begin
  Result := (CompareText(APropName, 'ItemIndex') = 0) or
            (CompareText(APropName, 'TabIndex') = 0) or
            (CompareText(APropName, 'PageIndex') = 0) or
            (CompareText(APropName, 'ActivePageIndex') = 0);
end;

// Разбор одного компонента. HelperArgs - рабочий список для аргументов
// вызова помощника (создаёт и освобождает AnalyzeNode).
procedure AnalyzeNodeWith(Info: TMoveInfo; ALines, AKeys: TStrings;
  const AFormClass: string; AClassFirst, AClassLast: Integer;
  ANames: TStrings; AHelpers: TList; AScan: TUnitScan;
  HelperArgs: TStringList);
var
  Helper: THelperInfo;
  CallLast, FreeHead, FreeEnd: Integer;
  FreeRoutine: string;
  Node: TDfmNode;
  NodeClass: TPersistentClass;
  Line, Code, Upper, Lhs, Owner, Ctor, Rest, PropName, Value, Target,
    AddParent, AddChild, Guard, SwitchProp, SwitchOn, RemoveParent,
    RemoveChild: string;
  CreatePos, Open, Close, Index, Head, RoutineEnd, Calls, Assigns,
    Creates, Assign, OwnerAt, Count, KeyNumber, LazyCond, LazyOpen,
    LazyEnd, RangeFirst, RangeLast, BadLine, SwitchLine, OtherLine,
    ScopeFirst, ScopeLast, OtherAssigns, CallParen, SubDot,
    SubIndex: Integer;
  Deep, IsNesting, HasNesting, Lazy, SeenExit, ReAdded,
    AfterSubCall: Boolean;
  Partners: TStringList;
  Args4: TBoundsArgs;
  Args, PropCounts, SubCalls: TStringList;
  PropInfo: PPropInfo;

  // Родитель вложенности (Parent, PageControl, Add): форма или компонент из
  // дерева формы
  function InTree(const AName: string): Boolean;
  begin
    Result := (CompareText(AName, 'Self') = 0) or (ANames.IndexOf(AName) >= 0);
  end;

  // Родитель через переменную: Sheet := FObjPagesSheet1; выше в той же
  // процедуре, потом MakeView(Sheet) или X.Parent := Sheet. Имя не из
  // дерева - ищется ближайшее присваивание ему выше строки ALine (до
  // заголовка процедуры); справа - компонент из дерева: он и родитель.
  // Иначе - AName как есть.
  function ParentThrough(const AName: string; ALine: Integer): string;
  var
    At, AssignAt: Integer;
    Text, Right: string;
  begin
    Result := AName;
    if InTree(AName) or not IsValidIdent(AName) then
      Exit;
    for At := ALine - 1 downto Head + 1 do
    begin
      Text := Trim(StripComment(ALines[At]));
      AssignAt := Pos(':=', Text);
      if (AssignAt = 0) or
         (CompareText(Trim(Copy(Text, 1, AssignAt - 1)), AName) <> 0) then
        Continue;
      Right := Trim(Copy(Text, AssignAt + 2, MaxInt));
      if (Right <> '') and (Right[Length(Right)] = ';') then
        Delete(Right, Length(Right), 1);
      Right := Trim(Right);
      if IsValidIdent(Right) and InTree(Right) then
        Result := Right;
      Exit;
    end;
  end;

  // Сколько раз свойство присваивается в процедуре создания
  function AssignCount(const AProp: string): Integer;
  var
    At: Integer;
  begin
    At := PropCounts.IndexOf(UpperCase(AProp));
    if At >= 0 then
      Result := Integer(PropCounts.Objects[At])
    else
      Result := 0;
  end;

  // Целое значение выражения на строке ALine: константы процедуры и
  // посчитанные переменные (X после X := 110 и сдвигов MakeBtn)
  function IntValueAt(const AExpr: string; ALine: Integer;
    var AValue: Integer): Boolean;
  var
    Known: TStringList;
  begin
    Result := False;
    if Head < 0 then
      Exit;
    Known := TStringList.Create;
    try
      RoutineIntValues(ALines, AKeys, AScan, AHelpers, Head, ALine, Known);
      Result := EvalIntExpr(AExpr, Known, AValue);
    finally
      Known.Free;
    end;
  end;

  // Элементы массива-аргумента ['A', 'B'] или [1, 2]; False - не массив
  // констант
  function ArrayItems(const AArg: string; AItems: TStrings): Boolean;
  var
    Text: string;
    ItemIndex: Integer;
  begin
    Result := False;
    AItems.Clear;
    Text := Trim(AArg);
    if (Length(Text) < 2) or (Text[1] <> '[') or
       (Text[Length(Text)] <> ']') then
      Exit;
    SplitCallArgs(Copy(Text, 2, Length(Text) - 2), AItems);
    for ItemIndex := 0 to AItems.Count - 1 do
      if not IsLiteral(AItems[ItemIndex]) then
        Exit;
    Result := True;
  end;

  // Колонки у этого вызова помощника - текстом для mlColumns. False -
  // значение не константа или массивы разной длины (причина - в Reason).
  function HelperColumns(var AText: string; var ACount: Integer): Boolean;
  var
    SpecIndex, PairIndex, Element, ElementCount, Tab, Open: Integer;
    Pairs, LoopItems, ValueItems: TStringList;
    PairProp, PairExpr, ArrayName, IndexName, ColumnValue: string;
  begin
    Result := False;
    AText := '';
    ACount := 0;
    Pairs := TStringList.Create;
    LoopItems := TStringList.Create;
    ValueItems := TStringList.Create;
    try
      for SpecIndex := 0 to Helper.Columns.Count - 1 do
      begin
        Pairs.Text := StringReplace(Helper.Columns[SpecIndex], #10, #13#10,
                                    [rfReplaceAll]);
        ElementCount := 1;
        if Integer(Helper.Columns.Objects[SpecIndex]) = 1 then
        begin
          if not ArrayItems(HelperValue(Helper, HelperArgs, Helper.LoopArray),
                            LoopItems) then
          begin
            Info.Reason := Helper.Name + ': колонки в цикле по ' +
                           Helper.LoopArray + ' - аргумент не массив констант';
            Exit;
          end;
          ElementCount := LoopItems.Count;
        end;
        for Element := 0 to ElementCount - 1 do
        begin
          if AText <> '' then
            AText := AText + #10'-'#10;
          for PairIndex := 0 to Pairs.Count - 1 do
          begin
            Tab := Pos(#9, Pairs[PairIndex]);
            PairProp := Copy(Pairs[PairIndex], 1, Tab - 1);
            PairExpr := Copy(Pairs[PairIndex], Tab + 1, MaxInt);
            ColumnValue := '';
            // Массив[LoopVar] - элемент массива-аргумента
            Open := Pos('[', PairExpr);
            if (Integer(Helper.Columns.Objects[SpecIndex]) = 1) and
               (Open > 0) and (PairExpr[Length(PairExpr)] = ']') then
            begin
              ArrayName := Trim(Copy(PairExpr, 1, Open - 1));
              IndexName := Trim(Copy(PairExpr, Open + 1,
                                     Length(PairExpr) - Open - 1));
              if (CompareText(IndexName, Helper.LoopVar) <> 0) or
                 not ArrayItems(HelperValue(Helper, HelperArgs, ArrayName),
                                ValueItems) or
                 (ValueItems.Count <> ElementCount) then
              begin
                Info.Reason := Helper.Name + ': колонка ' + PairProp + ' := ' +
                               PairExpr + ' - массив не той длины или не ' +
                               'константы';
                Exit;
              end;
              ColumnValue := ValueItems[Element];
            end
            else
              ColumnValue := HelperValue(Helper, HelperArgs, PairExpr);
            if not IsLiteral(ColumnValue) then
            begin
              Info.Reason := Helper.Name + ': колонка ' + PairProp + ' := ' +
                             ColumnValue + ' - значение вычисляется';
              Exit;
            end;
            if PairIndex > 0 then
              AText := AText + #10;
            AText := AText + PairProp + ' = ' + DfmLiteral(ColumnValue);
          end;
          Inc(ACount);
        end;
      end;
      Result := True;
    finally
      ValueItems.Free;
      LoopItems.Free;
      Pairs.Free;
    end;
  end;

  // Вызов помощника: вложенность и свойства из его тела со значениями
  // аргументов; строки вызова уходят целиком. False - что-то из этого в
  // .dfm не записать (причина - в Info.Reason).
  function AddHelperItems: Boolean;
  var
    ItemIndex, LineIndex, KeyValue, ColumnCount: Integer;
    PropText, Value, Shown, ColumnsText: string;
    HelperProp: PPropInfo;
    IncValues: TStringList;
  begin
    Result := False;
    Shown := '';
    if Helper.NestExpr <> '' then
    begin
      Value := HelperValue(Helper, HelperArgs, Helper.NestExpr);
      if CompareText(Copy(Value, Length(Value) - 5, 6), '.Items') = 0 then
        Delete(Value, Length(Value) - 5, 6);
      Value := ParentThrough(Value, Node.CreateLine);
      if not InTree(Value) then
      begin
        Info.Reason := Helper.Name + ' добавляет в ' + Value + ', строка ' +
                       IntToStr(Node.CreateLine + 1) + ' - его нет в ' +
                       'дереве формы';
        Exit;
      end;
      if CompareText(Value, 'Self') = 0 then
        Info.NestParent := ''
      else
        Info.NestParent := Value;
      HasNesting := True;
      Shown := 'в ' + Value;
    end;
    for ItemIndex := 0 to Helper.PropNames.Count - 1 do
    begin
      PropText := Helper.PropNames[ItemIndex];
      // Свойство с условием (if ATag <> 0 then ...): у этого вызова
      if (ItemIndex < Helper.PropConds.Count) and
         (Helper.PropConds[ItemIndex] <> '') then
        case HelperCondition(Helper, HelperArgs,
                             Helper.PropConds[ItemIndex]) of
          0:
            Continue;
          1:
            ;
        else
          Info.Reason := Helper.Name + ': условие ' +
                         Helper.PropConds[ItemIndex] + ' у свойства ' +
                         PropText + ' - у этого вызова не посчитать';
          Exit;
        end;
      Value := HelperValue(Helper, HelperArgs, Helper.PropExprs[ItemIndex]);
      HelperProp := PublishedProp(NodeClass, PropText);
      if HelperProp = nil then
      begin
        Info.Reason := Helper.Name + ' ставит ' + PropText + ' - не ' +
                       'published, в .dfm не записать';
        Exit;
      end;
      if (Length(PropText) > 2) and (UpCase(PropText[1]) = 'O') and
         (UpCase(PropText[2]) = 'N') and (Pos('.', PropText) = 0) then
      begin
        // Событие: nil - не ставится, метод формы - в .dfm
        if CompareText(Value, 'nil') = 0 then
          Continue;
        if IsLoadTimeEvent(PropText) then
        begin
          Info.Reason := Helper.Name + ' ставит ' + PropText + ' - оно может ' +
                         'прийти при загрузке формы, до FormCreate; строку ' +
                         'помощника в коде не оставить';
          Exit;
        end;
        if not IsValidIdent(Value) or
           (FindMethodImpl(ALines, AFormClass, Value) < 0) then
        begin
          Info.Reason := Helper.Name + ': ' + PropText + ' := ' + Value +
                         ' - не метод формы';
          Exit;
        end;
        AddMoveItem(Info, Node.CreateLine, mlEvent, PropText, Value);
        if Info.Handlers.IndexOf(Value) < 0 then
          Info.Handlers.Add(Value);
      end
      else if HelperProp^.PropType^^.Kind = tkClass then
      begin
        if CompareText(Value, 'nil') = 0 then
          Continue;
        Info.Reason := Helper.Name + ' ставит ссылку ' + PropText + ' := ' +
                       Value + ' - перенос такого помощника не сделан';
        Exit;
      end
      else if ShortCutValue(Value, KeyValue) then
      begin
        AddMoveItem(Info, Node.CreateLine, mlProp, PropText,
                    IntToStr(KeyValue));
        Value := IntToStr(KeyValue);
      end
      else if IsLiteral(Value) then
        AddMoveItem(Info, Node.CreateLine, mlProp, PropText,
                    DfmLiteral(Value))
      // Целое из констант и посчитанных переменных: Top := Row1, Left := X
      else if (HelperProp^.PropType^^.Kind = tkInteger) and
              IntValueAt(Value, Node.CreateLine, KeyValue) then
      begin
        AddMoveItem(Info, Node.CreateLine, mlProp, PropText,
                    IntToStr(KeyValue));
        Value := Value + ' = ' + IntToStr(KeyValue);
      end
      else
      begin
        Info.Reason := Helper.Name + ': ' + PropText + ' := ' + Value +
                       ' - значение вычисляется, в .dfm не записать';
        Exit;
      end;
      if Shown <> '' then
        Shown := Shown + ', ';
      Shown := Shown + PropText + ' = ' + Value;
    end;
    // Колонки списка: блоки with Result.Columns.Add, в цикле - по
    // элементам массива-аргумента
    if Helper.Columns.Count > 0 then
    begin
      if PublishedProp(NodeClass, 'Columns') = nil then
      begin
        Info.Reason := Helper.Name + ' добавляет колонки, а у ' +
                       Node.ClassNm + ' нет published-свойства Columns';
        Exit;
      end;
      if not HelperColumns(ColumnsText, ColumnCount) then
        Exit;
      AddMoveItem(Info, Node.CreateLine, mlColumns, 'Columns', ColumnsText);
      if Shown <> '' then
        Shown := Shown + ', ';
      Shown := Shown + 'колонок: ' + IntToStr(ColumnCount);
    end;
    // Помощник сдвигает переменную процедуры (Inc(X, W + 3)): строка
    // вызова не уходит, а становится этим сдвигом с посчитанным числом -
    // код ниже по-прежнему видит X после вызова
    if Helper.IncVar <> '' then
    begin
      IncValues := TStringList.Create;
      try
        for ItemIndex := 0 to Helper.Params.Count - 1 do
          if (ItemIndex < HelperArgs.Count) and
             IntValueAt(HelperArgs[ItemIndex], Node.CreateLine, KeyValue) then
            IncValues.Values[UpperCase(Helper.Params[ItemIndex])] :=
              IntToStr(KeyValue);
        if not EvalIntExpr(Helper.IncExpr, IncValues, KeyValue) then
        begin
          Info.Reason := Helper.Name + ' сдвигает ' + Helper.IncVar + ' на ' +
                         Helper.IncExpr + ' - у этого вызова не посчитать';
          Exit;
        end;
      finally
        IncValues.Free;
      end;
      Info.ReplaceText := 'Inc(' + Helper.IncVar + ', ' +
                          IntToStr(KeyValue) + ');';
      Info.Notes.Add(Helper.Name + ' сдвигает ' + Helper.IncVar + ': строка ' +
                     IntToStr(Node.CreateLine + 1) + ' станет «' +
                     Info.ReplaceText + '».');
    end;
    // Строки вызова - уходят все
    for LineIndex := Node.CreateLine to CallLast do
    begin
      if LineIndex = Node.CreateLine then
        Info.MoveLines.Add(LineRef(ALines, LineIndex) + '   [' + Helper.Name +
                           ' - это сделает .dfm: ' + Shown + ']')
      else
        Info.MoveLines.Add(LineRef(ALines, LineIndex) + '   [продолжение ' +
                           'вызова]');
      AddMoveItem(Info, LineIndex, mlCreate, '', '');
    end;
    Info.NestLine := Node.CreateLine;
    Result := True;
  end;

  // Локальная переменная, которой создают несколько компонентов (Grp):
  // строка AIndex - строка другого из них (выше неё в той же процедуре или
  // в том же блоке по требованию есть другое создание этой переменной)
  function OtherInstanceLine(AIndex: Integer): Boolean;
  var
    Back, Low: Integer;
    BackCode: string;
  begin
    Result := False;
    if not Info.ReusedLocal then
      Exit;
    if Lazy then
      Low := LazyOpen
    else
      Low := Head;
    if (AIndex < Low) or (AIndex > ScopeLast) then
      Exit;
    for Back := AIndex - 1 downto Low do
    begin
      if Back = Node.CreateLine then
        Exit;
      BackCode := StripComment(ALines[Back]);
      if (Pos(':=', BackCode) > 0) and
         (CompareText(Trim(Copy(BackCode, 1, Pos(':=', BackCode) - 1)),
                      Node.VarName) = 0) and
         (CodeCreatePos(UpperCase(BackCode)) > 0) then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;

  // Пункт меню, само меню которого (TPopupMenu, TMainMenu) создаётся в
  // том же блоке по требованию: до его показа пунктов всё равно не видно,
  // Visible = False ему не нужен
  function MenuInSameBlock: Boolean;
  var
    Up: TDfmNode;
    UpClass: TPersistentClass;
  begin
    Result := False;
    Up := Node.Parent;
    while Up <> nil do
    begin
      UpClass := GetClass(Up.ClassNm);
      if (UpClass <> nil) and ClassIs(UpClass, 'TMenu') then
      begin
        Result := (Up.CreateLine > LazyCond) and (Up.CreateLine < LazyEnd);
        Exit;
      end;
      Up := Up.Parent;
    end;
  end;

  // Владелец AOwner - компонент этой формы (не окно), сам принадлежащий
  // форме; его Components / ComponentCount / FindComponent код не
  // использует. Тогда владелец-форма в .dfm ничего не меняет: пункт меню
  // и так уничтожается вместе с меню, а по списку компонентов владельца
  // его никто не ищет.
  function OwnerGoesToForm(const AOwner: string): Boolean;
  var
    At, LineIndex: Integer;
    OwnerNode: TDfmNode;
    OwnerUpper, OwnerCode: string;
  begin
    Result := False;
    if not IsValidIdent(AOwner) then
      Exit;
    At := ANames.IndexOf(AOwner);
    if (At < 0) or (ANames.Objects[At] = nil) then
      Exit;
    OwnerNode := TDfmNode(ANames.Objects[At]);
    if IsFormClass(OwnerNode.ClassNm) then
      Exit;
    // Сам принадлежит форме: он в .dfm или создан с владельцем Self
    if OwnerNode.IsRuntime or OwnerNode.FromCode then
    begin
      if (OwnerNode.CreateLine < 0) or (OwnerNode.CreateLine >= ALines.Count) then
        Exit;
      OwnerCode := UpperCase(StripComment(ALines[OwnerNode.CreateLine]));
      OwnerCode := StringReplace(OwnerCode, ' ', '', [rfReplaceAll]);
      if Pos('.CREATE(SELF)', OwnerCode) = 0 then
        Exit;
    end;
    OwnerUpper := UpperCase(AOwner);
    for LineIndex := 0 to AKeys.Count - 1 do
      if (Pos(OwnerUpper, AKeys[LineIndex]) > 0) and
         (HasPattern(AKeys[LineIndex], OwnerUpper + '.COMPONENTS') or
          HasPattern(AKeys[LineIndex], OwnerUpper + '.COMPONENTCOUNT') or
          HasPattern(AKeys[LineIndex], OwnerUpper + '.FINDCOMPONENT(') or
          HasPattern(AKeys[LineIndex], OwnerUpper + '.REMOVECOMPONENT(') or
          HasPattern(AKeys[LineIndex], OwnerUpper + '.INSERTCOMPONENT(') or
          HasPattern(AKeys[LineIndex], OwnerUpper + '.DESTROYCOMPONENTS')) then
        Exit;
    Result := True;
  end;

  // Строка AExitLine - Exit оператора if (A = nil) or (B = nil) ... then
  // Exit; (или not Assigned(A)), где все A, B - компоненты .dfm, которые код
  // не освобождает: после загрузки формы условие не выполняется
  function DfmNilGuardExit(AExitLine: Integer): Boolean;
  var
    First, At, ChainIndex, Unit_, NameAt: Integer;
    Text, Upper, Cond, Name: string;
    Chains: TStringList;
    GuardNode: TDfmNode;
  begin
    Result := False;
    // Начало оператора if - не дальше 6 строк выше
    First := -1;
    for At := AExitLine downto AExitLine - 6 do
    begin
      if At < 0 then
        Break;
      if FirstWordOf(ALines[At]) = 'IF' then
      begin
        First := At;
        Break;
      end;
      if (At < AExitLine) and
         (Copy(Trim(StripComment(ALines[At])),
               Length(Trim(StripComment(ALines[At]))), 1) = ';') then
        Exit;
    end;
    if First < 0 then
      Exit;
    Text := '';
    for At := First to AExitLine do
      Text := Text + ' ' + Trim(StripComment(ALines[At]));
    Text := Trim(Text);
    Upper := UpperCase(Text);
    if (Copy(Upper, 1, 3) <> 'IF ') and (Copy(Upper, 1, 3) <> 'IF(') then
      Exit;
    At := Pos(' THEN ', Upper);
    if (At = 0) or (CodeKey(Copy(Text, At + 6, MaxInt)) <> 'EXIT;') then
      Exit;
    Cond := Copy(Text, 3, At - 3);
    for At := 1 to Length(Cond) do
      if not (IsIdentChar(Cond[At]) or (Cond[At] in [' ', '(', ')', '='])) then
        Exit;
    Chains := TStringList.Create;
    try
      ScanChains(Cond, Chains);
      // Части через OR: ИМЯ NIL (с =) или NOT ASSIGNED ИМЯ
      ChainIndex := 0;
      Unit_ := 0;
      while ChainIndex < Chains.Count do
      begin
        if Unit_ > 0 then
        begin
          if Chains[ChainIndex] <> 'OR' then
            Exit;
          Inc(ChainIndex);
        end;
        if (ChainIndex + 2 < Chains.Count + 0) and
           (Chains[ChainIndex] = 'NOT') and
           (Chains[ChainIndex + 1] = 'ASSIGNED') then
        begin
          Name := Chains[ChainIndex + 2];
          Inc(ChainIndex, 3);
        end
        else if (ChainIndex + 1 < Chains.Count) and
                (Chains[ChainIndex + 1] = 'NIL') then
        begin
          Name := Chains[ChainIndex];
          Inc(ChainIndex, 2);
        end
        else
          Exit;
        Inc(Unit_);
        if not IsValidIdent(Name) then
          Exit;
        NameAt := ANames.IndexOf(Name);
        if (NameAt < 0) or (ANames.Objects[NameAt] = nil) then
          Exit;
        GuardNode := TDfmNode(ANames.Objects[NameAt]);
        if GuardNode.IsRuntime or GuardNode.FromCode then
          Exit;
        // Код его не освобождает
        for At := 0 to AKeys.Count - 1 do
          if (Pos(Name, AKeys[At]) > 0) and
             (HasPattern(AKeys[At], 'FREEANDNIL(' + Name + ')') or
              HasPattern(AKeys[At], Name + '.FREE') or
              HasPattern(AKeys[At], Name + '.DESTROY') or
              HasPattern(AKeys[At], Name + '.RELEASE') or
              HasPattern(AKeys[At], Name + ':=')) then
            Exit;
      end;
      // = должно быть у каждой части ИМЯ NIL
      Result := Unit_ > 0;
    finally
      Chains.Free;
    end;
  end;

  // Вызов процедуры-создателя: здесь - только родитель (он у каждого
  // вызова свой) и строки вызова, которые остаются. Какие строки самой
  // процедуры уходят в .dfm, решает разбор всех её вызовов вместе
  // (DfmMoveAnalyze).
  function AddVarHelperStub: Boolean;
  var
    StmtIndex, LineIndex, CountAt: Integer;
    Stmt: THelperStmt;
    Value: string;
  begin
    Result := False;
    for StmtIndex := 0 to Helper.Stmts.Count - 1 do
    begin
      Stmt := THelperStmt(Helper.Stmts[StmtIndex]);
      if Stmt.Kind = hsProp then
      begin
        // Свойство ставит и процедура: такие строки ниже вызова остаются
        // в коде - они выполняются после неё
        CountAt := PropCounts.IndexOf(UpperCase(Stmt.PropName));
        if CountAt < 0 then
          PropCounts.AddObject(UpperCase(Stmt.PropName), TObject(1))
        else
          PropCounts.Objects[CountAt] :=
            TObject(Integer(PropCounts.Objects[CountAt]) + 1);
        Continue;
      end;
      if Stmt.Kind <> hsParent then
        Continue;
      Value := HelperValue(Helper, HelperArgs, Stmt.Expr);
      if CompareText(Copy(Value, Length(Value) - 5, 6), '.Items') = 0 then
        Delete(Value, Length(Value) - 5, 6);
      Value := ParentThrough(Value, Node.CreateLine);
      if not InTree(Value) then
      begin
        Info.Reason := Helper.Name + ' ставит родителем ' + Value +
                       ' (строка ' + IntToStr(Stmt.First + 1) + ') - его ' +
                       'нет в дереве формы';
        Exit;
      end;
      if CompareText(Value, 'Self') = 0 then
        Info.NestParent := ''
      else
        Info.NestParent := Value;
      HasNesting := True;
    end;
    Info.HelperGroup := Helper.HdrLine;
    Info.HelperName := Helper.Name;
    for LineIndex := Node.CreateLine to CallLast do
      if LineIndex = Node.CreateLine then
        Info.KeepLines.Add(LineRef(ALines, LineIndex) + '   [вызов ' +
                           Helper.Name + ' остаётся - компонент она больше ' +
                           'не создаёт]')
      else
        Info.KeepLines.Add(LineRef(ALines, LineIndex) + '   [продолжение ' +
                           'вызова]');
    Info.NestLine := Node.CreateLine;
    Result := True;
  end;

begin
  Node := TDfmNode(Info.Node);

  if not Node.IsRuntime and not Node.FromCode then
  begin
    Info.Kind := mkInDfm;
    Info.Reason := 'уже в .dfm';
    Exit;
  end;
  Info.Kind := mkNo;
  if (Node.VarName = '') or (Node.CreateLine < 0) or
     (Node.CreateLine >= ALines.Count) then
  begin
    Info.Reason := 'в модуле формы не найдено, где создаётся';
    Exit;
  end;
  Info.CreateLine := Node.CreateLine;
  Line := ALines[Node.CreateLine];
  Code := StripComment(Line);
  Upper := UpperCase(Code);

  // Отдельное окно, созданное кодом: его место - своя форма со своим
  // .dfm, не .dfm этой формы
  if IsFormClass(Node.ClassNm) then
  begin
    Info.Reason := 'отдельное окно (' + Node.ClassNm + '), создаётся в ' +
                   'коде - в .dfm этой формы не переносится; можно сделать ' +
                   'ему свою форму с .dfm';
    Exit;
  end;

  CreatePos := CodeCreatePos(Upper);
  Helper := nil;
  CallLast := Node.CreateLine;
  if CreatePos <= 0 then
  begin
    // Помощник: X := MakeItem(...); или MakeItem(...); без переменной
    if not ParseHelperCall(ALines, Node.CreateLine, AHelpers, Helper, Lhs,
                           HelperArgs, CallLast) then
    begin
      Info.Reason := 'создаётся помощником, строка ' +
                     IntToStr(Node.CreateLine + 1);
      Exit;
    end;
    if not Helper.Simple then
    begin
      Info.Reason := 'создаётся помощником ' + Helper.Name + ', строка ' +
                     IntToStr(Node.CreateLine + 1) + ' - ' + Helper.Problem;
      Exit;
    end;
    if HelperArgs.Count <> Helper.Params.Count then
    begin
      Info.Reason := 'вызов ' + Helper.Name + ', строка ' +
                     IntToStr(Node.CreateLine + 1) + ' - аргументов не ' +
                     'столько, сколько параметров';
      Exit;
    end;
    // Процедура-создатель отдаёт компонент в var-аргумент
    if Helper.OutIdx >= 0 then
      Lhs := Trim(HelperArgs[Helper.OutIdx]);
    // Проход развёрнутого цикла: аргументы - посчитанные для него, результат
    // - в переменной цикла
    if Info.UnrollArgs <> nil then
    begin
      if HelperArgs.Count <> Info.UnrollArgs.Count then
      begin
        Info.Reason := 'вызов ' + Helper.Name + ' в цикле не разобрался';
        Exit;
      end;
      HelperArgs.Assign(Info.UnrollArgs);
      if CompareText(Lhs, Info.UnrollVar) = 0 then
        Lhs := '';
    end;
    if (Info.NewField and (Lhs <> '')) or
       (not Info.NewField and (CompareText(Lhs, Node.VarName) <> 0)) then
    begin
      Info.Reason := 'результат ' + Helper.Name + ' - не в ' + Node.VarName +
                     ', строка ' + IntToStr(Node.CreateLine + 1);
      Exit;
    end;
    Owner := HelperValue(Helper, HelperArgs, Helper.OwnerExpr);
  end
  else
  begin
    Assign := Pos(':=', Code);
    Lhs := '';
    if Assign > 0 then
      Lhs := Trim(Copy(Code, 1, Assign - 1));
    if CompareText(Lhs, Node.VarName) <> 0 then
    begin
      Info.Reason := 'создаётся не прямым присваиванием, строка ' +
                     IntToStr(Node.CreateLine + 1);
      Exit;
    end;

    // Конструктор: .dfm создаёт компонент только через Create(владелец)
    Open := PosEx('(', Code, CreatePos);
    Ctor := Trim(Copy(Code, CreatePos + 1, Open - CreatePos - 1));
    if CompareText(Ctor, 'Create') <> 0 then
    begin
      Info.Reason := 'создаётся конструктором ' + Ctor + ', строка ' +
                     IntToStr(Node.CreateLine + 1) + ' - .dfm создаёт ' +
                     'компонент только через Create(владелец)';
      Exit;
    end;

    // Владелец - первый аргумент конструктора
    Close := LastDelimiter(')', Code);
    Owner := '';
    if (Open > 0) and (Close > Open) then
    begin
      Args := TStringList.Create;
      try
        CodeSplitArgs(Copy(Code, Open + 1, Close - Open - 1), Args);
        if Args.Count > 0 then
          Owner := Trim(Args[0]);
      finally
        Args.Free;
      end;
    end;
  end;
  if (CompareText(Owner, 'Self') <> 0) and not OwnerGoesToForm(Owner) then
  begin
    OwnerAt := ANames.IndexOf(Owner);
    if (OwnerAt >= 0) and (ANames.Objects[OwnerAt] <> nil) and
       IsFormClass(TDfmNode(ANames.Objects[OwnerAt]).ClassNm) then
      Info.Reason := 'часть окна ' + Owner + ' (' +
                     TDfmNode(ANames.Objects[OwnerAt]).ClassNm + ', создаётся ' +
                     'в коде) - переносится вместе с этим окном в его ' +
                     'собственную форму, не в эту'
    else
      Info.Reason := 'владелец ' + Owner + ', а не эта форма (Self)';
    Exit;
  end;
  if CompareText(Owner, 'Self') <> 0 then
    Info.Notes.Add('Владелец в коде - ' + Owner + ', в .dfm - форма. ' +
                   'Уничтожается он всё равно вместе с ' + Owner +
                   ' (его пункты и дети); ' + Owner + '.Components в ' +
                   'модуле не используется.');
  // Где имя компонента значит именно его: во всём модуле; у локальной
  // переменной - только в её процедуре (в других это их свои локальные)
  ScopeFirst := 0;
  ScopeLast := ALines.Count - 1;
  if not Info.NewField and
     not IsFormField(ALines, AClassFirst, AClassLast, Node.VarName) then
  begin
    // Локальная переменная процедуры формы: может стать published-полем с
    // тем же именем, если это имя больше нигде в модуле не встречается -
    // иначе поле подменило бы собой глобальную переменную или совпало бы с
    // чужой локальной
    EnclosingRoutine(ALines, AFormClass, Node.CreateLine, FreeRoutine,
                     FreeHead, FreeEnd);
    if (FreeRoutine = '') or (FreeEnd < 0) or
       not FindLocalDecl(ALines, FreeHead, Node.VarName, Info.LocalDecl,
                         Info.LocalVarLine, Info.LocalSectionNames) then
    begin
      Info.LocalDecl := -1;
      Info.Reason := Node.VarName + ' - не поле формы и не локальная ' +
                     'переменная процедуры формы';
      Exit;
    end;
    if not NameFreeForField(ALines, Node.VarName, FreeHead, FreeEnd,
                            OtherLine) then
    begin
      Info.LocalDecl := -1;
      Info.Reason := Node.VarName + ' - локальная переменная ' + FreeRoutine +
                     ', а это имя есть и в строке ' + IntToStr(OtherLine + 1) +
                     ' вне процедур, где оно объявлено своей локальной: поле ' +
                     'с таким именем изменило бы смысл этой строки';
      Exit;
    end;
    ScopeFirst := FreeHead;
    ScopeLast := FreeEnd;
    Info.Notes.Add('Локальная переменная ' + Node.VarName + ' (строка ' +
                   IntToStr(Info.LocalDecl + 1) + ') станет published-' +
                   'полем формы с тем же именем; её объявление в var ' +
                   'уходит.');
  end;
  if (Info.UnrollArgs = nil) and CodeLineInLoop(ALines, Node.CreateLine) then
  begin
    Info.Reason := 'создаётся в цикле, строка ' + IntToStr(Node.CreateLine + 1);
    Exit;
  end;

  // Создание не на прямом пути процедуры: после then/else/do, в except,
  // case, with. Переносится только создание по требованию -
  // if X = nil then begin ... end; где в блоке только создание полей
  // формы и их свойства.
  Lazy := False;
  LazyCond := -1;
  LazyOpen := -1;
  LazyEnd := -1;
  // Проход развёрнутого цикла: путь проверен у строки for
  if not AScan.Plain[Node.CreateLine] and (Info.UnrollArgs = nil) then
  begin
    if ((Helper <> nil) and ((Helper.OutIdx >= 0) or Helper.LocalCreator)) or
       not FindLazyBlock(AScan, AKeys, Node.CreateLine, Guard, LazyCond,
                         LazyOpen, LazyEnd) then
    begin
      Info.Reason := 'внутри условного блока (if, case, except, with...), ' +
                     'строка ' + IntToStr(Node.CreateLine + 1) +
                     ' - проверить вручную';
      Exit;
    end;
    Partners := TStringList.Create;
    try
      if not LazyBlockParts(ALines, AKeys, LazyOpen, LazyEnd, AClassFirst,
                            AClassLast, AHelpers, Partners, BadLine) then
      begin
        Info.Reason := 'создаётся по требованию (строка ' +
                       IntToStr(LazyCond + 1) + ': ' +
                       Trim(StripComment(ALines[LazyCond])) + '), но в ' +
                       'блоке есть строка ' + IntToStr(BadLine + 1) +
                       ' не про созданные в нём поля формы: после ' +
                       'переноса блок не выполняется';
        Exit;
      end;
      if Partners.IndexOf(Guard) < 0 then
      begin
        Info.Reason := 'создаётся в блоке ' +
                       Trim(StripComment(ALines[LazyCond])) + ' (строка ' +
                       IntToStr(LazyCond + 1) + '), а проверяемое поле ' +
                       'в нём не создаётся - проверить вручную';
        Exit;
      end;
      Info.LazyGuard := Partners[Partners.IndexOf(Guard)];
    finally
      Partners.Free;
    end;
    Lazy := True;
    Info.LazyGroup := LazyCond;
    Info.LazyEnd := LazyEnd;
  end;

  // Сколько раз эту переменную создают (конструктором или помощником).
  // Заодно - присвоения ей не конструктором (у локальной, которой создают
  // несколько компонентов, их быть не должно).
  Creates := 0;
  OtherAssigns := 0;
  if not Info.NewField then
    for Index := ScopeFirst to ScopeLast do
    begin
      Code := StripComment(ALines[Index]);
      Assign := Pos(':=', Code);
      if (Assign = 0) or
         (CompareText(Trim(Copy(Code, 1, Assign - 1)), Node.VarName) <> 0) then
        Continue;
      Upper := UpperCase(Code);
      if CodeCreatePos(Upper) > 0 then
        Inc(Creates)
      else if (Helper <> nil) and
              (Pos(UpperCase(Helper.Name) + '(', Upper) > 0) then
        Inc(Creates)
      else
        Inc(OtherAssigns);
    end;
  if Creates > 1 then
  begin
    // Локальная переменная, которой по очереди создают несколько
    // компонентов прямым Create: у каждого - свои строки до следующего
    // присваивания переменной
    if (Info.LocalDecl < 0) or (Helper <> nil) or (OtherAssigns > 0) then
    begin
      Info.Reason := 'создаётся в ' + IntToStr(Creates) + ' местах';
      Exit;
    end;
    Info.ReusedLocal := True;
    Info.CodeName := Node.VarName;
    Info.ReuseEnd := ScopeLast;
    for Index := Node.CreateLine + 1 to ScopeLast do
    begin
      Code := StripComment(ALines[Index]);
      Assign := Pos(':=', Code);
      if (Assign > 0) and
         (CompareText(Trim(Copy(Code, 1, Assign - 1)), Node.VarName) = 0) then
      begin
        Info.ReuseEnd := Index;
        Break;
      end;
    end;
    Info.Notes.Add('Локальной переменной ' + Node.VarName + ' в ' +
                   'процедуре создаются ' + IntToStr(Creates) + ' ' +
                   'компонента: этот получит своё поле, строка создания ' +
                   'станет «' + Node.VarName + ' := поле;», переменная ' +
                   'остаётся.');
  end;

  // Освобождение вне FormDestroy: код создаёт компонент заново или
  // рассчитывает на nil, а из .dfm он второй раз не появится. Проверки на
  // nil - для просмотра: после переноса компонент есть всегда.
  if not Info.NewField then
  begin
    Upper := UpperCase(Node.VarName);
    for Index := ScopeFirst to ScopeLast do
    begin
      if (Index = Node.CreateLine) or (Pos(Upper, AKeys[Index]) = 0) then
        Continue;
      if HasPattern(AKeys[Index], 'FREEANDNIL(' + Upper + ')') or
         HasPattern(AKeys[Index], Upper + '.FREE') or
         HasPattern(AKeys[Index], Upper + '.RELEASE') or
         HasPattern(AKeys[Index], Upper + '.DESTROY') or
         HasPattern(AKeys[Index], Upper + ':=NIL') then
      begin
        EnclosingRoutine(ALines, AFormClass, Index, FreeRoutine, FreeHead,
                         FreeEnd);
        if CompareText(FreeRoutine, 'FormDestroy') = 0 then
          Continue;
        Info.NilChecks.Clear;
        Info.Reason := 'освобождается в коде, строка ' + IntToStr(Index + 1) +
                       ' - из .dfm второй раз он не появится';
        Exit;
      end;
      if Index = LazyCond then
        Continue;
      if HasPattern(AKeys[Index], Upper + '=NIL') or
         HasPattern(AKeys[Index], Upper + '<>NIL') or
         HasPattern(AKeys[Index], 'ASSIGNED(' + Upper + ')') then
        Info.NilChecks.Add(LineRef(ALines, Index));
    end;
  end;

  // Процедура, в которой создаётся
  EnclosingRoutine(ALines, AFormClass, Node.CreateLine, Info.Routine, Head,
                   RoutineEnd);
  if (Info.Routine = '') or (RoutineEnd < 0) then
  begin
    Info.Reason := 'создаётся не в методе формы';
    Exit;
  end;
  // Раньше в теле процедуры есть Exit: создание могло не выполниться, а
  // из .dfm компонент будет всегда. Кроме проверки компонентов .dfm на nil
  // (if (LogTabs = nil) or ... then Exit;): после загрузки формы они есть,
  // и этот Exit не выполняется.
  if not Lazy and (AScan.BodyStart[Node.CreateLine] >= 0) then
    for Index := AScan.BodyStart[Node.CreateLine] + 1 to Node.CreateLine - 1 do
      if HasWord(StripComment(ALines[Index]), 'Exit') and
         not DfmNilGuardExit(Index) then
      begin
        Info.Reason := 'раньше в ' + Info.Routine + ' есть Exit (строка ' +
                       IntToStr(Index + 1) + ') - создание может не ' +
                       'выполниться, а из .dfm компонент будет всегда';
        Exit;
      end;
  // Процедура, вызываемая много раз, создала бы его много раз. По
  // требованию - создаётся один раз, это решает проверка на nil.
  if not Lazy and
     (CompareText(Info.Routine, 'FormCreate') <> 0) and
     (CompareText(Info.Routine, 'Create') <> 0) then
  begin
    CountUses(ALines, Info.Routine, Calls, Assigns);
    if Assigns > 0 then
    begin
      Info.Reason := Info.Routine + ' - обработчик события, может ' +
                     'вызываться много раз';
      Exit;
    end;
    if Calls = 0 then
    begin
      Info.Reason := Info.Routine + ' нигде не вызывается';
      Exit;
    end;
    if Calls <> 1 then
    begin
      Info.Reason := Info.Routine + ' вызывается ' + IntToStr(Calls) + ' ' +
                     TimesWord(Calls);
      Exit;
    end;
    Info.Notes.Add('Создаётся в ' + Info.Routine +
                   ' - она вызывается в одном месте.');
  end;

  // Класс - из зарегистрированных в IDE: по нему проверяется, какие
  // свойства published
  NodeClass := GetClass(Node.ClassNm);
  if NodeClass = nil then
  begin
    Info.Reason := 'класс ' + Node.ClassNm + ' не зарегистрирован в IDE - ' +
                   'published-свойства не проверить, проверить вручную';
    Exit;
  end;
  // По требованию: из .dfm компонент появится уже при загрузке формы. Это
  // безопасно для таймера (выключен до первого включения), контрола и
  // пункта меню (скрыты до первого показа), меню и диалога (ничего не
  // делают, пока их не вызвали). Про прочие классы это не известно.
  if Lazy and not (ClassIs(NodeClass, 'TTimer') or
                   ClassIs(NodeClass, 'TControl') or
                   ClassIs(NodeClass, 'TMenuItem') or
                   ClassIs(NodeClass, 'TMenu') or
                   ClassIs(NodeClass, 'TCommonDialog')) then
  begin
    Info.Reason := 'создаётся по требованию (строка ' + IntToStr(LazyCond + 1) +
                   '); класс ' + Node.ClassNm + ' - не таймер, не контрол, ' +
                   'не меню и не диалог: что он делает, появившись при ' +
                   'загрузке формы, не известно - проверить вручную';
    Exit;
  end;
  // Строки, в которых разбираются свойства: у создания по требованию -
  // только блок if X = nil (то, что после него, выполняется каждый раз и
  // остаётся в коде), иначе - до конца процедуры
  if Lazy then
  begin
    RangeFirst := LazyOpen;
    RangeLast := LazyEnd;
    // Локальной переменной в блоке создают несколько компонентов (Grp):
    // строки этого - до следующего присваивания ей
    if Info.ReusedLocal and (Info.ReuseEnd < RangeLast) then
      RangeLast := Info.ReuseEnd;
  end
  else
  begin
    RangeFirst := Head;
    RangeLast := RoutineEnd;
    // Переменная, которой создают несколько компонентов: строки этого -
    // до следующего присваивания ей
    if Info.ReusedLocal and (Info.ReuseEnd < RangeLast) then
      RangeLast := Info.ReuseEnd;
  end;

  // Добавление в меню или список вне процедуры создания: после переноса
  // пункт добавился бы второй раз (в .dfm он уже вложен)
  if not Info.NewField then
  for Index := ScopeFirst to ScopeLast do
  begin
    if (Index >= RangeFirst) and (Index <= RangeLast) then
      Continue;
    if ParseAddLine(Trim(StripComment(ALines[Index])), AddParent, AddChild) and
       (CompareText(AddChild, Node.VarName) = 0) and
       not OtherInstanceLine(Index) then
    begin
      if Lazy then
        Info.Reason := 'добавляется в ' + AddParent + ' ещё и в строке ' +
                       IntToStr(Index + 1) + ', вне блока строки ' +
                       IntToStr(LazyCond + 1) + ' - после переноса ' +
                       'добавился бы второй раз'
      else
        Info.Reason := 'добавляется в ' + AddParent + ' ещё и в строке ' +
                       IntToStr(Index + 1) + ', вне ' + Info.Routine +
                       ' - после переноса добавился бы второй раз';
      Exit;
    end;
  end;

  HasNesting := False;
  PropCounts := TStringList.Create;
  SubCalls := TStringList.Create;
  try
    // Сколько раз присваивается каждое свойство: присвоенное несколько раз
    // остаётся в коде - в .dfm попало бы только последнее значение, а
    // порядок присваиваний может быть важен (Align := alNone, Top, Align :=
    // alBottom)
    // Считаются и присваивания после then в той же строке
    // (if A then X.Top := 5;): они тоже меняют свойство после .dfm
    for Index := CallLast + 1 to RangeLast - 1 do
      CountPropAssigns(AKeys[Index], Node.VarName, PropCounts);

    // Строки X.... после создания в той же процедуре
    if (Helper <> nil) and (Helper.OutIdx >= 0) then
    begin
      if not AddVarHelperStub then
      begin
        ClearMoveData(Info);
        Exit;
      end;
    end
    else if Helper <> nil then
    begin
      if not AddHelperItems then
      begin
        ClearMoveData(Info);
        Exit;
      end;
    end
    else
    begin
      Info.MoveLines.Add(LineRef(ALines, Node.CreateLine) + '   [создание - ' +
                         'это сделает .dfm]');
      AddMoveItem(Info, Node.CreateLine, mlCreate, '', '');
      Info.NestLine := Node.CreateLine;
    end;
    SeenExit := False;
    for Index := CallLast + 1 to RangeLast - 1 do
    begin
      Code := Trim(StripComment(ALines[Index]));
      if Code = '' then
        Continue;
      // Не на прямом пути процедуры (после then, в except, case...) или
      // после Exit - строка выполняется не всегда. В блоке по требованию
      // все строки - на его прямом пути (это проверено).
      Deep := (not Lazy and not AScan.Plain[Index]) or SeenExit;
      if HasWord(Code, 'Exit') then
        SeenExit := True;

      // Добавление в меню или список: P.Add(X), P.Items.Insert(N, X)...
      if ParseAddLine(Code, AddParent, AddChild) then
      begin
        if CompareText(AddChild, Node.VarName) = 0 then
        begin
          // Строка вложенности этого компонента. Остаться в коде она не
          // может: пункт, вложенный в .dfm, добавился бы второй раз.
          if Deep then
          begin
            Info.Reason := 'добавляется в ' + AddParent + ' внутри блока ' +
                           '(if, try...), строка ' + IntToStr(Index + 1) +
                           ' - проверить вручную';
            ClearMoveData(Info);
            Exit;
          end;
          AddParent := ParentThrough(AddParent, Index);
          if not InTree(AddParent) then
          begin
            Info.Reason := 'добавляется в ' + AddParent + ', строка ' +
                           IntToStr(Index + 1) + ' - его нет в дереве формы';
            ClearMoveData(Info);
            Exit;
          end;
          Info.MoveLines.Add(LineRef(ALines, Index) + '   [вложенность - ' +
                             'пунктом в .dfm]');
          AddMoveItem(Info, Index, mlNesting, '', AddParent);
          Info.NestParent := AddParent;
          Info.NestLine := Index;
          HasNesting := True;
          Continue;
        end;
        // Этот компонент - родитель: строка - вложенность ребёнка, она в
        // разборе ребёнка. Здесь - только запомнить, чей он родитель.
        if CompareText(AddParent, Node.VarName) = 0 then
        begin
          Info.ChildAdds.AddObject(AddChild, TObject(Index));
          Continue;
        end;
      end;

      if HasWord(Code, 'with') and HasWord(Code, Node.VarName) then
      begin
        Info.KeepLines.Add(LineRef(ALines, Index) + '   [with - разбор не ' +
                           'заходит внутрь]');
        Continue;
      end;
      if CompareText(Copy(Code, 1, Length(Node.VarName) + 1),
                     Node.VarName + '.') <> 0 then
        Continue;
      if Deep then
      begin
        Info.KeepLines.Add(LineRef(ALines, Index) + '   [внутри блока]');
        Continue;
      end;
      Rest := Copy(Code, Length(Node.VarName) + 2, MaxInt);
      if (Rest = '') or (Rest[Length(Rest)] <> ';') then
      begin
        Info.KeepLines.Add(LineRef(ALines, Index) + '   [оператор на ' +
                           'несколько строк]');
        Continue;
      end;
      Delete(Rest, Length(Rest), 1);
      Assign := Pos(':=', Rest);
      if Assign = 0 then
      begin
        // Вызов метода
        if (CompareText(Copy(Rest, 1, 9), 'SetBounds') = 0) and
           CallArgsLiteral(Rest) and BoundsArgs(Rest, Args4) then
        begin
          Info.MoveLines.Add(LineRef(ALines, Index));
          AddMoveItem(Info, Index, mlProp, 'Left', DfmLiteral(Args4[0]));
          AddMoveItem(Info, Index, mlProp, 'Top', DfmLiteral(Args4[1]));
          AddMoveItem(Info, Index, mlProp, 'Width', DfmLiteral(Args4[2]));
          AddMoveItem(Info, Index, mlProp, 'Height', DfmLiteral(Args4[3]));
        end
        else
        begin
          Info.KeepLines.Add(LineRef(ALines, Index) + '   [вызов метода]');
          // Вызов у вложенного объекта (Font.Assign(...)): его свойства
          // ниже должны остаться после вызова, в коде
          CallParen := Pos('(', Rest);
          if CallParen = 0 then
            CallParen := Length(Rest) + 1;
          SubDot := LastDelimiter('.', Copy(Rest, 1, CallParen - 1));
          if SubDot > 0 then
            SubCalls.Add(UpperCase(Copy(Rest, 1, SubDot)));
        end;
        Continue;
      end;
      PropName := Trim(Copy(Rest, 1, Assign - 1));
      Value := Trim(Copy(Rest, Assign + 2, MaxInt));
      // Имя в .dfm - это имя объекта в заголовке, оно же имя поля: иначе
      // форма не свяжет поле с компонентом. Своё Name код ставит после.
      if CompareText(PropName, 'Name') = 0 then
      begin
        Info.KeepLines.Add(LineRef(ALines, Index) + '   [в .dfm имя ' +
                           'объекта - имя поля ' + Node.VarName + ']');
        Continue;
      end;
      // Вложенность: у листа TPageControl - PageControl, у прочих - Parent.
      // Parent не published, но в .dfm его заменяет вложенность.
      IsNesting := (CompareText(PropName, 'Parent') = 0) or
                   (CompareText(PropName, 'PageControl') = 0);
      PropInfo := nil;
      if not IsNesting then
      begin
        // Сначала - можно ли это вообще записать в .dfm: эта причина
        // главная, даже если свойство присваивается несколько раз
        if not IsPropPath(PropName) then
        begin
          Info.KeepLines.Add(LineRef(ALines, Index) + '   [не свойство .dfm]');
          Continue;
        end;
        PropInfo := PublishedProp(NodeClass, PropName);
        if PropInfo = nil then
        begin
          Info.KeepLines.Add(LineRef(ALines, Index) + '   [не published - ' +
                             'в .dfm не записать]');
          Continue;
        end;
      end;
      // После вызова метода вложенного объекта (X.Font.Assign(...)) его
      // свойства (X.Font.Style) - только в коде: из .dfm они встали бы до
      // вызова, и вызов бы их затёр
      AfterSubCall := False;
      for SubIndex := 0 to SubCalls.Count - 1 do
        if Copy(UpperCase(PropName), 1, Length(SubCalls[SubIndex])) =
           SubCalls[SubIndex] then
          AfterSubCall := True;
      if AfterSubCall then
      begin
        Info.KeepLines.Add(LineRef(ALines, Index) + '   [после вызова ' +
                           'метода ' + Copy(PropName, 1,
                           Pos('.', PropName) - 1) + ' - важен порядок]');
        Continue;
      end;
      Count := AssignCount(PropName);
      if Count > 1 then
      begin
        Info.KeepLines.Add(LineRef(ALines, Index) + '   [присваивается ' +
                           IntToStr(Count) + ' ' + TimesWord(Count) +
                           ' - важен порядок]');
        Continue;
      end;
      // Номер выбранного пункта или вкладки зависит от пунктов: если выше
      // что-то из строк этого компонента остаётся в коде (Items.Add), в
      // .dfm номер встал бы раньше пунктов
      if IsIndexProp(PropName) and (Info.KeepLines.Count > 0) then
      begin
        Info.KeepLines.Add(LineRef(ALines, Index) + '   [зависит от строк ' +
                           'выше, которые остаются в коде]');
        Continue;
      end;
      if IsNesting then
      begin
        Target := ParentThrough(Value, Index);
        if InTree(Target) then
        begin
          Info.MoveLines.Add(LineRef(ALines, Index) + '   [родитель - ' +
                             'вложенностью в .dfm]');
          AddMoveItem(Info, Index, mlNesting, '', Target);
          if CompareText(Target, 'Self') = 0 then
            Info.NestParent := ''
          else
            Info.NestParent := Target;
          Info.NestLine := Index;
          HasNesting := True;
        end
        else
          Info.KeepLines.Add(LineRef(ALines, Index) + '   [родителя нет ' +
                             'в дереве формы]');
        Continue;
      end;
      if (Length(PropName) > 2) and (UpCase(PropName[1]) = 'O') and
         (UpCase(PropName[2]) = 'N') and (Pos('.', PropName) = 0) then
      begin
        // Событие: метод формы - в .dfm, иначе остаётся. События, которые
        // приходят при загрузке формы, тоже остаются.
        if IsLoadTimeEvent(PropName) then
          Info.KeepLines.Add(LineRef(ALines, Index) + '   [событие может ' +
                             'прийти при загрузке формы, до FormCreate]')
        else if IsValidIdent(Value) and
           (FindMethodImpl(ALines, AFormClass, Value) >= 0) then
        begin
          Info.MoveLines.Add(LineRef(ALines, Index));
          AddMoveItem(Info, Index, mlEvent, PropName, Value);
          if Info.Handlers.IndexOf(Value) < 0 then
            Info.Handlers.Add(Value);
        end
        else
          Info.KeepLines.Add(LineRef(ALines, Index) + '   [обработчик - не ' +
                             'метод формы]');
        Continue;
      end;
      // Ссылка на компонент (PopupMenu := FTabsPopup): уйдёт ли она,
      // зависит от того, будет ли Y в .dfm - решается после разбора всех
      if PropInfo^.PropType^^.Kind = tkClass then
      begin
        if IsValidIdent(Value) and (CompareText(Value, 'Self') <> 0) and
           (CompareText(Value, 'nil') <> 0) then
        begin
          Info.RefLines.AddObject(Value, TObject(Index));
          AddMoveItem(Info, Index, mlRef, PropName, Value);
        end
        else
          Info.KeepLines.Add(LineRef(ALines, Index) + '   [значение ' +
                             'вычисляется]');
        Continue;
      end;
      // Сочетание клавиш из констант - в .dfm числом
      if ShortCutValue(Value, KeyNumber) then
      begin
        Info.MoveLines.Add(LineRef(ALines, Index) + '   [в .dfm числом: ' +
                           IntToStr(KeyNumber) + ']');
        AddMoveItem(Info, Index, mlProp, PropName, IntToStr(KeyNumber));
        Continue;
      end;
      if IsLiteral(Value) then
      begin
        Info.MoveLines.Add(LineRef(ALines, Index));
        AddMoveItem(Info, Index, mlProp, PropName, DfmLiteral(Value));
      end
      // Целое из констант процедуры и посчитанных переменных: Row1 + 3
      else if (PropInfo^.PropType^^.Kind = tkInteger) and
              IntValueAt(Value, Index, KeyNumber) then
      begin
        Info.MoveLines.Add(LineRef(ALines, Index) + '   [в .dfm числом: ' +
                           IntToStr(KeyNumber) + ']');
        AddMoveItem(Info, Index, mlProp, PropName, IntToStr(KeyNumber));
      end
      else
        Info.KeepLines.Add(LineRef(ALines, Index) + '   [значение ' +
                           'вычисляется]');
    end;
  finally
    SubCalls.Free;
    PropCounts.Free;
  end;

  // Раньше него в этой процедуре в того же родителя добавляется пункт,
  // который останется в коде: из .dfm (его вынули и добавляют заново),
  // NewLine, локальный. После переноса такой пункт встанет ниже
  // перенесённого - порядок меню изменится. Созданные кодом компоненты
  // дерева здесь не считаются: их порядок проверяется по дереву.
  if Info.NestParent <> '' then
    for Index := RangeFirst + 1 to Node.CreateLine - 1 do
    begin
      Code := Trim(StripComment(ALines[Index]));
      if not ParseAddLine(Code, AddParent, AddChild) or
         (CompareText(AddParent, Info.NestParent) <> 0) or
         (CompareText(AddChild, Node.VarName) = 0) then
        Continue;
      OwnerAt := ANames.IndexOf(AddChild);
      if (OwnerAt >= 0) and (ANames.Objects[OwnerAt] <> nil) and
         TDfmNode(ANames.Objects[OwnerAt]).IsRuntime then
        Continue;
      // NewLine - разделитель без имени: при переносе он сам станет
      // пунктом .dfm (свой разбор в списке), порядок проверит StaysBefore
      if CompareText(AddChild, 'NewLine') = 0 then
        Continue;
      // Пункт из .dfm, вынутый раньше в этой же процедуре (P.Remove(X)) и
      // добавленный заново: это перестановка пунктов меню, её разбирает
      // DfmMoveAnalyze целиком (переносится вместе со всем меню)
      ReAdded := False;
      for OwnerAt := RangeFirst + 1 to Index - 1 do
        if ParseRemoveLine(Trim(StripComment(ALines[OwnerAt])), RemoveParent,
                           RemoveChild) and
           (CompareText(RemoveParent, AddParent) = 0) and
           (CompareText(RemoveChild, AddChild) = 0) then
          ReAdded := True;
      if ReAdded then
        Continue;
      ClearMoveData(Info);
      Info.Reason := 'раньше него в ' + Info.Routine + ' в ' + AddParent +
                     ' добавляется ' + AddChild + ' (строка ' +
                     IntToStr(Index + 1) + ') - он останется в коде и после ' +
                     'переноса встанет ниже';
      Exit;
    end;

  // Контрол или пункт меню без строки вложенности в этой процедуре: в .dfm
  // он лёг бы прямо в форму и стал бы виден там, где в коде его нет
  if not HasNesting and (NodeClass.InheritsFrom(TControl) or
                         NodeClass.InheritsFrom(TMenuItem)) then
  begin
    // Строка вложенности есть, но остаётся в коде - назвать её
    Target := '';
    for Index := 0 to Info.KeepLines.Count - 1 do
      if (Pos('.PARENT :=', UpperCase(Info.KeepLines[Index])) > 0) or
         (Pos('.PAGECONTROL :=', UpperCase(Info.KeepLines[Index])) > 0) then
      begin
        Target := Info.KeepLines[Index];
        Break;
      end;
    ClearMoveData(Info);
    if Target <> '' then
      Info.Reason := 'вложенность остаётся в коде (' + Target + ') - в ' +
                     '.dfm вложить некуда'
    else
      Info.Reason := 'родитель (Parent, Add) задаётся не в ' + Info.Routine +
                     ' - в .dfm вложить некуда, проверить вручную';
    Exit;
  end;

  if Lazy then
  begin
    // В блоке по требованию не должно оставаться строк: после переноса
    // X не nil и блок не выполняется
    if Info.KeepLines.Count > 0 then
    begin
      Target := Info.KeepLines[0];
      ClearMoveData(Info);
      Info.Reason := 'создаётся по требованию (строка ' +
                     IntToStr(LazyCond + 1) + '), а в блоке осталась бы ' +
                     'строка ' + Target + ' - после переноса блок не ' +
                     'выполняется';
      Exit;
    end;
    // Таймер из .dfm - выключен, контрол и пункт меню - скрыты: до
    // первого вызова их не было. Включает или показывает их код после
    // блока; если такого места нет - они работали с создания, и из .dfm
    // заработали бы уже при загрузке.
    SwitchProp := '';
    if ClassIs(NodeClass, 'TTimer') then
      SwitchProp := 'Enabled'
    else if ClassIs(NodeClass, 'TControl') or
            (ClassIs(NodeClass, 'TMenuItem') and not MenuInSameBlock) then
      SwitchProp := 'Visible';
    if SwitchProp <> '' then
    begin
      SwitchOn := '';
      for Index := 0 to Info.Items.Count - 1 do
        if CompareText(TMoveLine(Info.Items[Index]).PropName,
                       SwitchProp) = 0 then
          SwitchOn := TMoveLine(Info.Items[Index]).Value;
      if CompareText(SwitchOn, 'True') = 0 then
      begin
        ClearMoveData(Info);
        Info.Reason := 'создаётся по требованию (строка ' +
                       IntToStr(LazyCond + 1) + ') и в блоке ставится ' +
                       SwitchProp + ' := True - из .dfm он работал бы уже ' +
                       'с загрузки формы';
        Exit;
      end;
      if SwitchOn = '' then
      begin
        Upper := UpperCase(Node.VarName) + '.' + UpperCase(SwitchProp) +
                 ':=TRUE';
        SwitchLine := -1;
        for Index := 0 to AKeys.Count - 1 do
          if ((Index < LazyOpen) or (Index > LazyEnd)) and
             (HasPattern(AKeys[Index], Upper) or
              ((SwitchProp = 'Visible') and
               HasPattern(AKeys[Index], UpperCase(Node.VarName) + '.SHOW'))) then
          begin
            SwitchLine := Index;
            Break;
          end;
        if SwitchLine < 0 then
        begin
          ClearMoveData(Info);
          if SwitchProp = 'Enabled' then
            Info.Reason := 'создаётся по требованию (строка ' +
                           IntToStr(LazyCond + 1) + ') и работает с ' +
                           'создания, а строки ' + Node.VarName +
                           '.Enabled := True в коде нет - из .dfm таймер ' +
                           'пришлось бы или включить с загрузки, или он ' +
                           'не включится никогда'
          else
            Info.Reason := 'создаётся по требованию (строка ' +
                           IntToStr(LazyCond + 1) + ') и виден с ' +
                           'создания, а строки ' + Node.VarName +
                           '.Visible := True в коде нет - из .dfm его ' +
                           'пришлось бы или показать с загрузки, или он ' +
                           'не покажется никогда';
          Exit;
        end;
        // Первым в блоке объекта: до того, как .dfm задаст обработчики
        AddMoveItem(Info, Node.CreateLine, mlProp, SwitchProp, 'False');
        Info.Items.Move(Info.Items.Count - 1, 0);
        Info.Notes.Add('В .dfm ' + SwitchProp + ' = False: до первого ' +
                       'вызова его не было. ' + SwitchProp + ' := True - ' +
                       'в строке ' + IntToStr(SwitchLine + 1) + '.');
      end;
    end;
    // Строки самой проверки - у компонента, которого она проверяет
    if CompareText(Info.LazyGuard, Node.VarName) = 0 then
    begin
      Info.MoveLines.Add(LineRef(ALines, LazyCond) + '   [проверка на nil - ' +
                         'после переноса блок не нужен]');
      AddMoveItem(Info, LazyCond, mlCreate, '', '');
      if LazyOpen <> LazyCond then
      begin
        Info.MoveLines.Add(LineRef(ALines, LazyOpen) + '   [начало блока]');
        AddMoveItem(Info, LazyOpen, mlCreate, '', '');
      end;
      Info.MoveLines.Add(LineRef(ALines, LazyEnd) + '   [конец блока]');
      AddMoveItem(Info, LazyEnd, mlCreate, '', '');
    end;
    Info.Notes.Add('Создаётся по требованию (строка ' + IntToStr(LazyCond + 1) +
                   ': ' + Trim(StripComment(ALines[LazyCond])) + '). После ' +
                   'переноса он есть с загрузки формы; всё, что создаётся ' +
                   'в этом блоке, переносится только вместе.');
    Upper := '';
    for Index := 0 to AKeys.Count - 1 do
      if (Pos('COMPONENTCOUNT', AKeys[Index]) > 0) or
         (Pos('CONTROLCOUNT', AKeys[Index]) > 0) then
      begin
        Upper := IntToStr(Index + 1);
        Break;
      end;
    if Upper <> '' then
      Info.Notes.Add('В модуле есть обход Components/Controls (строка ' +
                     Upper + ' и др.): он теперь увидит ' + Node.VarName +
                     ' и до первого вызова.');
  end;

  if not Node.IsLive then
    Info.Notes.Add('Снимка нет: значения в .dfm будут только из строк кода ' +
                   '(Show live values даст точные).');
  if Info.NilChecks.Count > 0 then
  begin
    Info.Notes.Add('Проверки на nil - после переноса ' + Node.VarName +
                   ' есть всегда, просмотреть:');
    Info.Notes.AddStrings(Info.NilChecks);
  end;
  if Info.KeepLines.Count > 0 then
  begin
    Info.Kind := mkPartial;
    Info.Reason := 'останется строк: ' + IntToStr(Info.KeepLines.Count);
  end
  else
  begin
    Info.Kind := mkWhole;
    Info.Reason := '';
  end;
end;

// AKeys - строки модуля в виде CodeKey, по номерам ALines
procedure AnalyzeNode(Info: TMoveInfo; ALines, AKeys: TStrings;
  const AFormClass: string; AClassFirst, AClassLast: Integer;
  ANames: TStrings; AHelpers: TList; AScan: TUnitScan);
var
  HelperArgs: TStringList;
begin
  HelperArgs := TStringList.Create;
  try
    AnalyzeNodeWith(Info, ALines, AKeys, AFormClass, AClassFirst, AClassLast,
                    ANames, AHelpers, AScan, HelperArgs);
  finally
    HelperArgs.Free;
  end;
end;

// Порядок строк «N: ...» по номеру N - для CustomSort
function CompareLineRefs(AList: TStringList; AIndex1, AIndex2: Integer): Integer;
var
  Line1, Line2: Integer;
begin
  Line1 := StrToIntDef(Copy(AList[AIndex1], 1, Pos(':', AList[AIndex1]) - 1), 0);
  Line2 := StrToIntDef(Copy(AList[AIndex2], 1, Pos(':', AList[AIndex2]) - 1), 0);
  if Line1 < Line2 then
    Result := -1
  else if Line1 > Line2 then
    Result := 1
  else
    Result := 0;
end;

// ---------------------------------------------------------------------------
//  Проверки на nil, которые могут выполниться до создания компонента
// ---------------------------------------------------------------------------

type
  // Метод формы: где он в модуле и какие методы формы в нём вызываются
  TFormRoutine = class
  public
    Name: string;
    Head, EndLine: Integer;
    // У метода есть параметры: имя без скобок после него - не вызов, а
    // ссылка на метод (MakeBtn('Find', 46, Row1, DoFindNext))
    HasParams: Boolean;
    CallLines: array of Integer;    // строка вызова
    CallTargets: array of Integer;  // номер вызываемого в списке методов
    CallCount: Integer;
    procedure AddCall(ALine, ATarget: Integer);
  end;

procedure TFormRoutine.AddCall(ALine, ATarget: Integer);
begin
  if CallCount >= Length(CallLines) then
  begin
    SetLength(CallLines, CallCount + 16);
    SetLength(CallTargets, CallCount + 16);
  end;
  CallLines[CallCount] := ALine;
  CallTargets[CallCount] := ATarget;
  Inc(CallCount);
end;

// Событие, которое приходит при загрузке формы и во время FormCreate
// (изменение размеров, Change, отрисовка). OnShow и OnHide формы приходят
// после FormCreate - не считаются.
function IsInitEvent(const AEvent: string): Boolean;
begin
  Result := IsLoadTimeEvent(AEvent) and (CompareText(AEvent, 'OnShow') <> 0) and
            (CompareText(AEvent, 'OnHide') <> 0);
end;

// То же для события компонента класса AClassName. У вкладок (TTabControl,
// TPageControl) OnChange и OnChanging приходят только от пользователя:
// TabIndex и ActivePage из кода их не вызывают.
function IsInitEventOf(const AClassName, AEvent: string): Boolean;
var
  NodeClass: TPersistentClass;
begin
  Result := IsInitEvent(AEvent);
  if not Result then
    Exit;
  NodeClass := GetClass(AClassName);
  if (NodeClass <> nil) and ClassIs(NodeClass, 'TCustomTabControl') and
     ((CompareText(AEvent, 'OnChange') = 0) or
      (CompareText(AEvent, 'OnChanging') = 0)) then
    Result := False;
end;

// Методы формы AFormClass (в порядке модуля) и вызовы между ними. ANames -
// имена методов, в Objects - TFormRoutine. AInitHandlers получает методы,
// которые код назначает событиям загрузки (X.OnResize := Метод), в
// Objects - строка назначения.
procedure CollectFormRoutines(ALines: TStrings; const AFormClass: string;
  ARoutines: TList; ANames: TStringList; AInitHandlers, ATreeNames: TStrings);
var
  Index, LineIndex, CharPos, TextLen, WordStart, After, At, Target,
    ObjectAt: Integer;
  Text, Upper, Head, Word, Before, EventName, ObjectName, ObjectClass: string;
  Routine: TFormRoutine;
  PrevChar: Char;
begin
  Head := UpperCase(AFormClass) + '.';
  Index := 0;
  while Index < ALines.Count do
  begin
    Text := ALines[Index];
    if (Text <> '') and (Text[1] <> ' ') then
    begin
      Word := FirstWordOf(Text);
      if (Word = 'PROCEDURE') or (Word = 'FUNCTION') or
         (Word = 'CONSTRUCTOR') or (Word = 'DESTRUCTOR') then
      begin
        Upper := UpperCase(Trim(Copy(Trim(Text), Length(Word) + 1, MaxInt)));
        if Copy(Upper, 1, Length(Head)) = Head then
        begin
          Routine := TFormRoutine.Create;
          CharPos := Length(Head) + 1;
          WordStart := CharPos;
          while (CharPos <= Length(Upper)) and IsIdentChar(Upper[CharPos]) do
            Inc(CharPos);
          Routine.Name := Copy(Trim(Copy(Trim(Text), Length(Word) + 1,
                                           MaxInt)), WordStart,
                               CharPos - WordStart);
          Routine.Head := Index;
          Routine.HasParams := PosEx('(', Upper, CharPos) > 0;
          Routine.EndLine := ALines.Count - 1;
          for LineIndex := Index + 1 to ALines.Count - 1 do
            if (LeadSpacesOf(ALines[LineIndex]) = 0) and
               (UpperCase(Trim(ALines[LineIndex])) = 'END;') then
            begin
              Routine.EndLine := LineIndex;
              Break;
            end;
          ARoutines.Add(Routine);
          if ANames.IndexOf(Routine.Name) < 0 then
            ANames.AddObject(Routine.Name, Routine);
          Index := Routine.EndLine;
        end;
      end;
    end;
    Inc(Index);
  end;

  // Вызовы: слово - имя метода формы, не после точки (X.Refresh - метод
  // другого объекта), не справа от := (X.OnClick := Метод - назначение,
  // а не вызов) и, если у метода есть параметры, - со скобкой после имени
  // (без неё это ссылка на метод - аргумент или значение)
  for Index := 0 to ARoutines.Count - 1 do
  begin
    Routine := TFormRoutine(ARoutines[Index]);
    for LineIndex := Routine.Head + 1 to Routine.EndLine - 1 do
    begin
      Text := StripComment(ALines[LineIndex]);
      TextLen := Length(Text);
      CharPos := 1;
      PrevChar := ' ';
      while CharPos <= TextLen do
      begin
        case Text[CharPos] of
          '''':
            begin
              Inc(CharPos);
              while (CharPos <= TextLen) and (Text[CharPos] <> '''') do
                Inc(CharPos);
              Inc(CharPos);
              PrevChar := '''';
            end;
          '{':
            begin
              while (CharPos <= TextLen) and (Text[CharPos] <> '}') do
                Inc(CharPos);
              Inc(CharPos);
            end;
          'A'..'Z', 'a'..'z', '_':
            begin
              WordStart := CharPos;
              while (CharPos <= TextLen) and IsIdentChar(Text[CharPos]) do
                Inc(CharPos);
              Word := Copy(Text, WordStart, CharPos - WordStart);
              if PrevChar <> '.' then
              begin
                Target := ANames.IndexOf(Word);
                if Target >= 0 then
                begin
                  Before := TrimRight(Copy(Text, 1, WordStart - 1));
                  After := CharPos;
                  while (After <= TextLen) and (Text[After] in [' ', #9]) do
                    Inc(After);
                  if (Copy(Before, Length(Before) - 1, 2) = ':=') and
                     ((After > TextLen) or (Text[After] = ';')) then
                  begin
                    // Назначение обработчика: событие загрузки - запомнить
                    EventName := Trim(Copy(Before, 1, Length(Before) - 2));
                    At := LastDelimiter('.', EventName);
                    ObjectName := Copy(EventName, 1, At - 1);
                    ObjectName := Copy(ObjectName,
                                       LastDelimiter(' ;', ObjectName) + 1,
                                       MaxInt);
                    EventName := Copy(EventName, At + 1, MaxInt);
                    ObjectClass := '';
                    ObjectAt := ATreeNames.IndexOf(ObjectName);
                    if (ObjectAt >= 0) and
                       (ATreeNames.Objects[ObjectAt] <> nil) then
                      ObjectClass :=
                        TDfmNode(ATreeNames.Objects[ObjectAt]).ClassNm;
                    if IsInitEventOf(ObjectClass, EventName) then
                      AInitHandlers.AddObject(Word, TObject(LineIndex));
                  end
                  else if not TFormRoutine(ANames.Objects[Target]).HasParams or
                          ((After <= TextLen) and (Text[After] = '(')) then
                    Routine.AddCall(LineIndex,
                      ARoutines.IndexOf(ANames.Objects[Target]));
                end;
              end;
              PrevChar := 'A';
            end;
          ' ', #9:
            Inc(CharPos);
        else
          PrevChar := Text[CharPos];
          Inc(CharPos);
        end;
      end;
    end;
  end;
end;

// Номер метода формы, в котором стоит строка ALine; -1 - ни в каком
function RoutineAtLine(ARoutines: TList; ALine: Integer): Integer;
var
  Index: Integer;
begin
  Result := -1;
  for Index := 0 to ARoutines.Count - 1 do
    if (TFormRoutine(ARoutines[Index]).Head <= ALine) and
       (TFormRoutine(ARoutines[Index]).EndLine >= ALine) then
    begin
      Result := Index;
      Exit;
    end;
end;

// Номер строки из «N: текст» (от нуля); -1
function LineOfRef(const ARef: string): Integer;
begin
  Result := StrToIntDef(Copy(ARef, 1, Pos(':', ARef) - 1), 0) - 1;
end;

// Info.NilRisk: проверки на nil, которые могут выполниться до прежнего
// создания компонента. Окно «до создания»:
//   - путь вызовов от FormCreate до процедуры создания: в каждой процедуре
//     пути - строки до вызова следующей (в последней - до строки
//     создания) и всё, что вызывается в этих строках, со всеми вложенными
//     вызовами;
//   - обработчики событий загрузки: назначенные в .dfm - всегда, в коде -
//     если назначение само попадает в это окно; и всё, что вызывается из
//     них.
// Пути от FormCreate нет, создание по требованию или в этом окне
// вызывается Application.ProcessMessages (тогда может прийти любое
// событие) - рискованны все проверки. У каждой рискованной строки - как до
// неё доходит.
procedure FindNilRisks(Info: TMoveInfo; ALines: TStrings; ARoutines: TList;
  ANames: TStringList; AInitHandlers: TStrings);
var
  Index, Current, Limit, Target, CheckLine, Queued, Start, Handler,
    AssignLine: Integer;
  Parent, ParentLine, ViaRoutine, ViaLine: array of Integer;
  ViaHandler, Reached: array of Boolean;
  RangeFirst, RangeLast: array of Integer;
  RangeCount: Integer;
  Queue: array of Integer;
  QueueHead, QueueTail: Integer;
  Routine: TFormRoutine;
  Risky, Found, Added: Boolean;
  Chain: string;

  procedure Enqueue(ARoutine, AFrom, AFromLine: Integer; AHandler: Boolean);
  begin
    if (ARoutine < 0) or Reached[ARoutine] then
      Exit;
    Reached[ARoutine] := True;
    ViaRoutine[ARoutine] := AFrom;
    ViaLine[ARoutine] := AFromLine;
    ViaHandler[ARoutine] := AHandler;
    Queue[QueueTail] := ARoutine;
    Inc(QueueTail);
  end;

  // Всё, что вызывается из поставленного в очередь
  procedure Spread;
  var
    CallIndex: Integer;
    SpreadRoutine: TFormRoutine;
  begin
    while QueueHead < QueueTail do
    begin
      Current := Queue[QueueHead];
      Inc(QueueHead);
      SpreadRoutine := TFormRoutine(ARoutines[Current]);
      for CallIndex := 0 to SpreadRoutine.CallCount - 1 do
        Enqueue(SpreadRoutine.CallTargets[CallIndex], Current,
                SpreadRoutine.CallLines[CallIndex], False);
    end;
  end;

  // Строка ALine выполняется до создания: в строках пути или в
  // достигнутом методе
  function BeforeCreate(ALine: Integer): Boolean;
  var
    RangeIndex, At: Integer;
  begin
    At := RoutineAtLine(ARoutines, ALine);
    Result := (At >= 0) and Reached[At];
    for RangeIndex := 0 to RangeCount - 1 do
      if (ALine >= RangeFirst[RangeIndex]) and
         (ALine <= RangeLast[RangeIndex]) then
        Result := True;
  end;

begin
  Info.NilRisk.Clear;
  if Info.NilChecks.Count = 0 then
    Exit;
  Start := ANames.IndexOf('FormCreate');
  Target := ANames.IndexOf(Info.Routine);
  if (Info.LazyGroup >= 0) or (Start < 0) or (Target < 0) then
  begin
    for Index := 0 to Info.NilChecks.Count - 1 do
      if Info.LazyGroup >= 0 then
        Info.NilRisk.Add(Info.NilChecks[Index] + '   [до первого ' +
                         'выполнения блока по требованию]')
      else
        Info.NilRisk.Add(Info.NilChecks[Index] + '   [не найдено, как ' +
                         Info.Routine + ' вызывается из FormCreate]');
    Exit;
  end;
  Start := ARoutines.IndexOf(ANames.Objects[Start]);
  Target := ARoutines.IndexOf(ANames.Objects[Target]);

  SetLength(Parent, ARoutines.Count);
  SetLength(ParentLine, ARoutines.Count);
  SetLength(ViaRoutine, ARoutines.Count);
  SetLength(ViaLine, ARoutines.Count);
  SetLength(ViaHandler, ARoutines.Count);
  SetLength(Reached, ARoutines.Count);
  SetLength(Queue, ARoutines.Count);
  for Index := 0 to ARoutines.Count - 1 do
  begin
    Parent[Index] := -1;
    ParentLine[Index] := -1;
    Reached[Index] := False;
  end;

  // Путь FormCreate -> ... -> процедура создания (поиск в ширину)
  QueueHead := 0;
  QueueTail := 0;
  Enqueue(Start, -1, -1, False);
  Found := Start = Target;
  while not Found and (QueueHead < QueueTail) do
  begin
    Current := Queue[QueueHead];
    Inc(QueueHead);
    Routine := TFormRoutine(ARoutines[Current]);
    for Index := 0 to Routine.CallCount - 1 do
    begin
      Queued := Routine.CallTargets[Index];
      if (Queued < 0) or Reached[Queued] then
        Continue;
      Parent[Queued] := Current;
      ParentLine[Queued] := Routine.CallLines[Index];
      Enqueue(Queued, -1, -1, False);
      if Queued = Target then
      begin
        Found := True;
        Break;
      end;
    end;
  end;
  if not Found then
  begin
    for Index := 0 to Info.NilChecks.Count - 1 do
      Info.NilRisk.Add(Info.NilChecks[Index] + '   [не найдено, как ' +
                       Info.Routine + ' вызывается из FormCreate]');
    Exit;
  end;

  // Строки пути до вызова следующего и то, что в них вызывается
  SetLength(RangeFirst, ARoutines.Count + 1);
  SetLength(RangeLast, ARoutines.Count + 1);
  RangeCount := 0;
  for Index := 0 to ARoutines.Count - 1 do
    Reached[Index] := False;
  QueueHead := 0;
  QueueTail := 0;
  Current := Target;
  Limit := Info.CreateLine;
  while Current >= 0 do
  begin
    Routine := TFormRoutine(ARoutines[Current]);
    RangeFirst[RangeCount] := Routine.Head;
    RangeLast[RangeCount] := Limit - 1;
    Inc(RangeCount);
    for Index := 0 to Routine.CallCount - 1 do
      if Routine.CallLines[Index] < Limit then
        Enqueue(Routine.CallTargets[Index], Current,
                Routine.CallLines[Index], False);
    Limit := ParentLine[Current];
    Current := Parent[Current];
  end;
  Spread;

  // Обработчики событий загрузки: из .dfm (строка назначения -1) - сразу,
  // из кода - если назначение выполняется до создания. Назначенный
  // обработчик может вызвать то, где назначен следующий, - до
  // устойчивого состояния.
  repeat
    Added := False;
    for Handler := 0 to AInitHandlers.Count - 1 do
    begin
      Target := ANames.IndexOf(AInitHandlers[Handler]);
      if Target < 0 then
        Continue;
      Target := ARoutines.IndexOf(ANames.Objects[Target]);
      if Reached[Target] then
        Continue;
      AssignLine := Integer(AInitHandlers.Objects[Handler]);
      if (AssignLine < 0) or BeforeCreate(AssignLine) then
      begin
        Enqueue(Target, -1, AssignLine, True);
        Spread;
        Added := True;
      end;
    end;
  until not Added;

  // ProcessMessages до создания: в это время могут прийти любые события
  // (таймеры, щелчки, отрисовка) - их обработчики здесь не отследить
  for CheckLine := 0 to ALines.Count - 1 do
    if (Pos('PROCESSMESSAGES', UpperCase(ALines[CheckLine])) > 0) and
       HasWord(StripComment(ALines[CheckLine]), 'ProcessMessages') and
       BeforeCreate(CheckLine) then
    begin
      for Index := 0 to Info.NilChecks.Count - 1 do
        Info.NilRisk.Add(Info.NilChecks[Index] + '   [до создания ' +
                         'вызывается Application.ProcessMessages, строка ' +
                         IntToStr(CheckLine + 1) + ' - может прийти любое ' +
                         'событие]');
      Exit;
    end;

  for Index := 0 to Info.NilChecks.Count - 1 do
  begin
    CheckLine := LineOfRef(Info.NilChecks[Index]);
    Current := RoutineAtLine(ARoutines, CheckLine);
    Risky := False;
    Chain := '';
    for Target := 0 to RangeCount - 1 do
      if (CheckLine >= RangeFirst[Target]) and
         (CheckLine <= RangeLast[Target]) then
      begin
        Risky := True;
        Chain := 'раньше в ' + TFormRoutine(ARoutines[Current]).Name;
      end;
    if not Risky and (Current >= 0) and Reached[Current] then
    begin
      Risky := True;
      // Как дошли: цепочка вызывающих до строки пути или обработчика
      Chain := TFormRoutine(ARoutines[Current]).Name;
      Queued := Current;
      Limit := 0;
      while (Queued >= 0) and (Limit < 12) do
      begin
        if ViaHandler[Queued] then
        begin
          if ViaLine[Queued] < 0 then
            Chain := Chain + ' <- обработчик события загрузки из .dfm'
          else
            Chain := Chain + ' <- обработчик события загрузки, назначен ' +
                     'в строке ' + IntToStr(ViaLine[Queued] + 1);
          Break;
        end;
        if ViaRoutine[Queued] < 0 then
          Break;
        Chain := Chain + ' <- ' +
                 TFormRoutine(ARoutines[ViaRoutine[Queued]]).Name + ' (' +
                 IntToStr(ViaLine[Queued] + 1) + ')';
        Queued := ViaRoutine[Queued];
        Inc(Limit);
      end;
    end;
    if Risky then
      Info.NilRisk.Add(Info.NilChecks[Index] + '   [' + Chain + ']');
  end;
end;

// Копия узла дерева объектов - то, что нужно разбору и переносу. Parent -
// пока прежний, его заменяет вызывающий; детей и свойств у копии нет.
function CopyNodeData(ANode: TDfmNode): TDfmNode;
begin
  Result := TDfmNode.Create;
  Result.Name := ANode.Name;
  Result.ClassNm := ANode.ClassNm;
  Result.Line := ANode.Line;
  Result.EndLine := ANode.EndLine;
  Result.Parent := ANode.Parent;
  Result.IsSnap := ANode.IsSnap;
  Result.IsRuntime := ANode.IsRuntime;
  Result.IsLink := ANode.IsLink;
  Result.SnapRoot := ANode.SnapRoot;
  Result.VarName := ANode.VarName;
  Result.CreateLine := ANode.CreateLine;
  Result.FromCode := ANode.FromCode;
  Result.IsLive := ANode.IsLive;
end;

// Узлы разбора - свои копии вместо узлов дерева объектов, Parent - на
// копии же (у родителя вне списка - отдельная копия в ExtraNodes). Одному
// родителю - одна копия: соседи по-прежнему узнаются по равенству Parent.
procedure DetachFromTree(AList: TList);
var
  Originals, Copies: TList;
  Index, At: Integer;
  Info: TMoveInfo;
  Node, NodeCopy: TDfmNode;
begin
  Originals := TList.Create;
  Copies := TList.Create;
  try
    for Index := 0 to AList.Count - 1 do
    begin
      Info := TMoveInfo(AList[Index]);
      if Info.OwnsNode then
        Continue;
      Node := TDfmNode(Info.Node);
      NodeCopy := CopyNodeData(Node);
      Originals.Add(Node);
      Copies.Add(NodeCopy);
      Info.Node := NodeCopy;
      Info.OwnsNode := True;
    end;
    for Index := 0 to AList.Count - 1 do
    begin
      Info := TMoveInfo(AList[Index]);
      Node := TDfmNode(Info.Node);
      if Node.Parent = nil then
        Continue;
      At := Originals.IndexOf(Node.Parent);
      if At < 0 then
      begin
        NodeCopy := CopyNodeData(Node.Parent);
        NodeCopy.Parent := nil;
        if Info.ExtraNodes = nil then
          Info.ExtraNodes := TList.Create;
        Info.ExtraNodes.Add(NodeCopy);
        Originals.Add(Node.Parent);
        Copies.Add(NodeCopy);
        At := Copies.Count - 1;
      end;
      Node.Parent := TDfmNode(Copies[At]);
    end;
  finally
    Copies.Free;
    Originals.Free;
  end;
end;

const
  // Что меняет место и размер компонента (после имени, в виде CodeKey)
  GeometryPatterns: array[0..13] of string = ('.LEFT:=', '.TOP:=',
    '.WIDTH:=', '.HEIGHT:=', '.SETBOUNDS(', '.BOUNDSRECT:=', '.ALIGN:=',
    '.ANCHORS:=', '.AUTOSIZE:=', '.CLIENTWIDTH:=', '.CLIENTHEIGHT:=',
    '.PARENT:=', '.CONSTRAINTS.', '.SCALEBY(');
  GeometryProps: array[0..3] of string = ('Left', 'Top', 'Width', 'Height');

procedure DfmMoveAnalyze(ATree: TTreeView; const APasText, AFormClass: string;
  AList: TList);
var
  Lines, Keys, Names, CallArgs, NewNames: TStringList;
  Helpers: TList;
  Index, ClassFirst, ClassLast, Pass, Other, RefLine, CallLast, ParentAt,
    InsertAt: Integer;
  Info, ParentInfo, TargetInfo, MateInfo: TMoveInfo;
  Node: TDfmNode;
  Changed: Boolean;
  RefName, CallLhs, ParentName: string;
  Helper: THelperInfo;
  Scan: TUnitScan;
  Routines: TList;
  RoutineNames, InitHandlers, ReorderDone: TStringList;
  LineHead, LineEnd, Calls, Assigns: Integer;
  RoutineName, ReorderKey, ReorderProblem: string;
  ParentNode: TDfmNode;

  // Новое имя для компонента из вызова без переменной: родитель + класс +
  // номер (FTabsPopupItem1). Не занято ни в дереве, ни в модуле.
  function NewComponentName(const AParent, AClass: string): string;
  var
    Base: string;
    Number: Integer;
  begin
    Base := AClass;
    if (Base <> '') and (UpCase(Base[1]) = 'T') then
      Delete(Base, 1, 1);
    if CompareText(Copy(Base, 1, 2), 'Ui') = 0 then
      Delete(Base, 1, 2);
    if CompareText(Base, 'MenuItem') = 0 then
      Base := 'Item';
    Base := AParent + Base;
    Number := 1;
    while (Names.IndexOf(Base + IntToStr(Number)) >= 0) or
          (NewNames.IndexOf(Base + IntToStr(Number)) >= 0) or
          PasHasIdent(APasText, Base + IntToStr(Number)) do
      Inc(Number);
    Result := Base + IntToStr(Number);
    NewNames.Add(Result);
  end;

  // Разбор компонента с таким именем (переменной); nil - нет в дереве
  function FindInfo(const AName: string): TMoveInfo;
  var
    ItemIndex: Integer;
    Item: TMoveInfo;
  begin
    Result := nil;
    for ItemIndex := 0 to AList.Count - 1 do
    begin
      Item := TMoveInfo(AList[ItemIndex]);
      if (CompareText(TDfmNode(Item.Node).VarName, AName) = 0) or
         (CompareText(TDfmNode(Item.Node).Name, AName) = 0) then
      begin
        Result := Item;
        Exit;
      end;
    end;
  end;

  // Компонент с таким именем (переменной) переносится в .dfm
  function ChildMoves(const AName: string): Boolean;
  var
    Item: TMoveInfo;
  begin
    Item := FindInfo(AName);
    Result := (Item <> nil) and (Item.Kind in [mkWhole, mkPartial]);
  end;

  // Перестановка пунктов меню AParent (из .dfm) в процедуре, строки
  // AHead..AEnd: пункты .dfm вынимаются (Remove) и добавляются заново
  // вперемешку с созданными там же. В .dfm можно записать итоговый порядок,
  // если в процедуре с AParent делается только это. '' - можно, иначе -
  // почему нельзя.
  function CheckReorder(const AParent: string; AHead, AEnd: Integer): string;
  var
    LineIndex, At: Integer;
    Code, Key, UpperParent, OpParent, OpChild: string;
    Removed: TStringList;
    ItemNode: TDfmNode;
  begin
    Result := '';
    At := Names.IndexOf(AParent);
    if (At < 0) or (Names.Objects[At] = nil) or
       TDfmNode(Names.Objects[At]).IsRuntime then
    begin
      Result := 'пункты ' + AParent + ' переставляются в коде, а ' +
                AParent + ' сам создаётся кодом - такая перестановка не ' +
                'разбирается';
      Exit;
    end;
    UpperParent := UpperCase(AParent);
    Removed := TStringList.Create;
    try
      for LineIndex := 0 to Lines.Count - 1 do
      begin
        Key := Keys[LineIndex];
        if Pos(UpperParent, Key) = 0 then
          Continue;
        Code := Trim(StripComment(Lines[LineIndex]));
        // Вне процедуры: любые добавления, вынимания, вставки в AParent
        if (LineIndex < AHead) or (LineIndex > AEnd) then
        begin
          if (ParseAddLine(Code, OpParent, OpChild) or
              ParseRemoveLine(Code, OpParent, OpChild)) and
             (CompareText(OpParent, AParent) = 0) then
          begin
            Result := 'пункты ' + AParent + ' меняются ещё и в строке ' +
                      IntToStr(LineIndex + 1) + ', вне процедуры ' +
                      'перестановки';
            Exit;
          end;
          Continue;
        end;
        if HasPattern(Key, UpperParent + '.INSERT(') or
           HasPattern(Key, UpperParent + '.ITEMS.INSERT(') or
           HasPattern(Key, UpperParent + '.DELETE(') or
           HasPattern(Key, UpperParent + '.ITEMS.DELETE(') or
           HasPattern(Key, UpperParent + '.CLEAR') or
           HasPattern(Key, UpperParent + '.ITEMS.CLEAR') then
        begin
          Result := 'строка ' + IntToStr(LineIndex + 1) + ' (' + Code +
                    ') - такое изменение пунктов ' + AParent + ' в .dfm не ' +
                    'записать';
          Exit;
        end;
        if ParseRemoveLine(Code, OpParent, OpChild) and
           (CompareText(OpParent, AParent) = 0) then
        begin
          At := Names.IndexOf(OpChild);
          if not Scan.Plain[LineIndex] or (At < 0) or
             (Names.Objects[At] = nil) or
             TDfmNode(Names.Objects[At]).IsRuntime then
          begin
            Result := 'строка ' + IntToStr(LineIndex + 1) + ' (' + Code +
                      ') - вынимается не пункт .dfm или внутри условного ' +
                      'блока';
            Exit;
          end;
          Removed.Add(OpChild);
          Continue;
        end;
        if ParseAddLine(Code, OpParent, OpChild) and
           (CompareText(OpParent, AParent) = 0) then
        begin
          if not Scan.Plain[LineIndex] then
          begin
            Result := 'строка ' + IntToStr(LineIndex + 1) + ' (' + Code +
                      ') внутри условного блока';
            Exit;
          end;
          At := Removed.IndexOf(OpChild);
          if At >= 0 then
          begin
            Removed.Delete(At);
            Continue;
          end;
          if CompareText(OpChild, 'NewLine') = 0 then
            Continue;
          At := Names.IndexOf(OpChild);
          ItemNode := nil;
          if At >= 0 then
            ItemNode := TDfmNode(Names.Objects[At]);
          if (ItemNode <> nil) and ItemNode.IsRuntime and
             (ItemNode.Parent = TDfmNode(Names.Objects[Names.IndexOf(AParent)])) then
            Continue;
          Result := 'строка ' + IntToStr(LineIndex + 1) + ': в ' + AParent +
                    ' добавляется ' + OpChild + ' - он не переносится вместе ' +
                    'с меню';
          Exit;
        end;
      end;
      if Removed.Count > 0 then
        Result := AParent + '.Remove(' + Removed[0] + ') без добавления ' +
                  'обратно - пункт пропадает из меню, в .dfm так не записать';
    finally
      Removed.Free;
    end;
  end;

  // В строке-ключе AKey на позиции AAt - аргумент вызова: имя вызова
  // (без Self.) и номер аргумента. False - не внутри скобок вызова.
  function ArgCallAt(const AKey: string; AAt: Integer; var ACallName: string;
    var AArgIndex: Integer): Boolean;
  var
    Depth, Back, NameEnd: Integer;
  begin
    Result := False;
    Depth := 0;
    AArgIndex := 0;
    Back := AAt - 1;
    while Back >= 1 do
    begin
      if AKey[Back] in [')', ']'] then
        Inc(Depth)
      else if AKey[Back] in ['(', '['] then
      begin
        if Depth = 0 then
          Break;
        Dec(Depth);
      end
      else if (AKey[Back] = ',') and (Depth = 0) then
        Inc(AArgIndex);
      Dec(Back);
    end;
    if (Back < 1) or (AKey[Back] <> '(') then
      Exit;
    NameEnd := Back - 1;
    Back := NameEnd;
    while (Back >= 1) and (IsIdentChar(AKey[Back]) or (AKey[Back] = '.')) do
      Dec(Back);
    ACallName := Copy(AKey, Back + 1, NameEnd - Back);
    if Copy(ACallName, 1, 5) = 'SELF.' then
      Delete(ACallName, 1, 5);
    Result := ACallName <> '';
  end;

  // Вызов ACall (имя без точки) с компонентом аргументом номер AArgIndex
  // его места и размеры не меняет: в теле процедуры нет присвоений
  // Параметр.Left, .Width... и параметр дальше не передаётся
  function CallKeepsGeometry(const ACall: string; AArgIndex: Integer): Boolean;
  var
    LineIndex, Found, HeadLast, Indent, PatternIndex: Integer;
    Key, Head, ParamUpper, ClassUpper: string;
    ParamList: TStringList;
  begin
    Result := False;
    if (ACall = 'ASSIGNED') or (ACall = 'FREEANDNIL') then
    begin
      Result := ACall = 'ASSIGNED';
      Exit;
    end;
    if not IsValidIdent(ACall) then
      Exit;
    ClassUpper := UpperCase(AFormClass);
    Found := -1;
    for LineIndex := 0 to Keys.Count - 1 do
    begin
      if (LineIndex >= ClassFirst) and (LineIndex <= ClassLast) then
        Continue;
      Key := Keys[LineIndex];
      if (Pos('PROCEDURE ' + ClassUpper + '.' + ACall + '(', Key) = 1) or
         (Pos('FUNCTION ' + ClassUpper + '.' + ACall + '(', Key) = 1) or
         (Pos('PROCEDURE ' + ACall + '(', Key) = 1) or
         (Pos('FUNCTION ' + ACall + '(', Key) = 1) then
      begin
        if Found >= 0 then
          Exit;               // несколько с таким именем - не разбирается
        Found := LineIndex;
      end;
    end;
    if Found < 0 then
      Exit;
    Head := '';
    HeadLast := Found;
    repeat
      Head := Head + ' ' + Trim(StripComment(Lines[HeadLast]));
      Inc(HeadLast);
    until (Pos(')', Head) > 0) or (HeadLast >= Lines.Count) or
          (HeadLast > Found + 6);
    ParamList := TStringList.Create;
    try
      CodeParamNames(Head, ParamList);
      if AArgIndex >= ParamList.Count then
        Exit;
      ParamUpper := UpperCase(ParamList[AArgIndex]);
    finally
      ParamList.Free;
    end;
    Indent := LeadSpacesOf(Lines[Found]);
    for LineIndex := HeadLast to Lines.Count - 1 do
    begin
      Key := Keys[LineIndex];
      if (Key = 'END;') and (LeadSpacesOf(Lines[LineIndex]) = Indent) then
        Break;
      if not HasPattern(Key, ParamUpper) then
        Continue;
      for PatternIndex := Low(GeometryPatterns) to High(GeometryPatterns) do
        if HasPattern(Key, ParamUpper + GeometryPatterns[PatternIndex]) then
          Exit;
      if HasPattern(Key, 'WITH ' + ParamUpper) or
         HasPattern(Key, '(' + ParamUpper + ')') or
         HasPattern(Key, '(' + ParamUpper + ',') or
         HasPattern(Key, ',' + ParamUpper + ')') or
         HasPattern(Key, ',' + ParamUpper + ',') then
        Exit;
    end;
    Result := True;
  end;

  // Места и размеры компонента .dfm AName код не меняет: нет присвоений
  // Left, Width..., with, а процедуры, которым он передаётся, их не
  // меняют
  function GeometryStable(const AName: string): Boolean;
  var
    LineIndex, PatternIndex, At, ArgIndex: Integer;
    Key, Upper, CallName: string;
  begin
    Result := False;
    Upper := UpperCase(AName);
    for LineIndex := 0 to Keys.Count - 1 do
    begin
      Key := Keys[LineIndex];
      if not HasPattern(Key, Upper) then
        Continue;
      for PatternIndex := Low(GeometryPatterns) to High(GeometryPatterns) do
        if HasPattern(Key, Upper + GeometryPatterns[PatternIndex]) then
          Exit;
      if HasPattern(Key, 'WITH ' + Upper) then
        Exit;
      // Аргументом вызова: F(X) / F(A, X, B)
      At := Pos(Upper, Key);
      while At > 0 do
      begin
        if (At > 1) and (Key[At - 1] in ['(', ',']) and
           (At + Length(Upper) <= Length(Key)) and
           (Key[At + Length(Upper)] in [')', ',']) then
        begin
          if not ArgCallAt(Key, At, CallName, ArgIndex) or
             not CallKeepsGeometry(CallName, ArgIndex) then
            Exit;
        end;
        At := PosEx(Upper, Key, At + 1);
      end;
    end;
    Result := True;
  end;

  // Процедуры-создатели: где компонент передан целиком, меняется ли его
  // место (THelperStmt.BareSafe)
  procedure MarkBareSafe;
  var
    HelperIndex, StmtIndex, LineIndex, At, ArgIndex: Integer;
    VarHelper: THelperInfo;
    Stmt: THelperStmt;
    Key, OutUpper, CallName: string;
    Safe: Boolean;
  begin
    for HelperIndex := 0 to Helpers.Count - 1 do
    begin
      VarHelper := THelperInfo(Helpers[HelperIndex]);
      if VarHelper.OutIdx < 0 then
        Continue;
      OutUpper := UpperCase(VarHelper.OutName);
      for StmtIndex := 0 to VarHelper.Stmts.Count - 1 do
      begin
        Stmt := THelperStmt(VarHelper.Stmts[StmtIndex]);
        if not (Stmt.Kind in [hsOther, hsInc]) then
          Continue;
        Safe := True;
        for LineIndex := Stmt.First to Stmt.Last do
        begin
          Key := Keys[LineIndex];
          At := Pos(OutUpper, Key);
          while Safe and (At > 0) do
          begin
            if ((At = 1) or not IsIdentChar(Key[At - 1])) and
               ((At + Length(OutUpper) > Length(Key)) or
                not IsIdentChar(Key[At + Length(OutUpper)])) and
               ((At + Length(OutUpper) > Length(Key)) or
                (Key[At + Length(OutUpper)] <> '.')) then
              // целиком: только аргументом процедуры, которая место не
              // меняет
              Safe := (At > 1) and (Key[At - 1] in ['(', ',']) and
                      (At + Length(OutUpper) <= Length(Key)) and
                      (Key[At + Length(OutUpper)] in [')', ',']) and
                      ArgCallAt(Key, At, CallName, ArgIndex) and
                      CallKeepsGeometry(CallName, ArgIndex);
            At := PosEx(OutUpper, Key, At + 1);
          end;
        end;
        Stmt.BareSafe := Safe;
      end;
    end;
  end;

  // Цикл for по константному массиву, в теле которого пункт создаёт
  // помощник: Sub := MakeItem(Self, mNew, Copy(Kinds[I], ...), ...);
  // Sub.Hint := ...; Каждый проход - свой компонент .dfm (mNewItem1...),
  // значения посчитаны по элементам массива. Строки цикла уходят, проходы
  // переносятся только все вместе.
  procedure UnrollConstLoops;
  var
    ForLine, BodyOpen, BodyEnd, CallLine, CallLast, StmtLine, PassValue,
      LineIndex, ArgIndex, ParentAt, InsertAt, Other, AssignAt, LoopHead,
      LoopEnd, LocalDecl, LocalVarLine, LocalNames, ToAt, DoAt, Calls,
      Assigns, KeyNumber, PassIndex: Integer;
    Code, Upper, LoopVar, LowText, HighText, RoutineName, CallLhs,
      ParentName, PropName, PropExpr, Reason, NamesText, ArgText, Shown: string;
    Env, PassEnv, Args, PassArgs, PropNames, PropExprs, PropLines: TStringList;
    LoopHelper: THelperInfo;
    Value, LowValue, HighValue: TConstValue;
    Members: TList;
    Member, ParentInfo, SubInfo: TMoveInfo;
    NewNode: TDfmNode;
    MemberClass: TPersistentClass;
    MemberProp: PPropInfo;

    // Выражение прохода - литералом; не посчитать и зависит от переменной
    // цикла - False
    function PassText(const AExpr: string; var AText: string): Boolean;
    begin
      Result := True;
      if EvalConstExpr(AExpr, PassEnv, Value) then
      begin
        if Value.IsInt then
          AText := IntToStr(Value.Int)
        else
          AText := PascalQuote(Value.Str);
      end
      else if HasWord(AExpr, LoopVar) then
        Result := False
      else
        AText := Trim(AExpr);
    end;

    // Узлы дерева - создание в этом цикле
    procedure SetSubReasons(const AText: string);
    var
      SubIndex: Integer;
    begin
      for SubIndex := 0 to AList.Count - 1 do
      begin
        SubInfo := TMoveInfo(AList[SubIndex]);
        if (SubInfo.Kind = mkNo) and (SubInfo.UnrollArgs = nil) and
           (TDfmNode(SubInfo.Node).CreateLine = CallLine) then
          SubInfo.Reason := AText;
      end;
    end;

  begin
    Env := TStringList.Create;
    PassEnv := TStringList.Create;
    Args := TStringList.Create;
    PassArgs := TStringList.Create;
    PropNames := TStringList.Create;
    PropExprs := TStringList.Create;
    PropLines := TStringList.Create;
    Members := TList.Create;
    try
      for ForLine := 0 to Lines.Count - 1 do
      begin
        if Copy(Keys[ForLine], 1, 4) <> 'FOR ' then
          Continue;
        Code := Trim(StripComment(Lines[ForLine]));
        Upper := UpperCase(Code);
        AssignAt := Pos(':=', Upper);
        ToAt := Pos(' TO ', Upper);
        DoAt := 0;
        if Copy(Upper, Length(Upper) - 2, 3) = ' DO' then
          DoAt := Length(Upper) - 2
        else if Copy(Upper, Length(Upper) - 8, 9) = ' DO BEGIN' then
          DoAt := Length(Upper) - 8;
        if (AssignAt = 0) or (ToAt < AssignAt) or (DoAt < ToAt) then
          Continue;
        LoopVar := Trim(Copy(Code, 4, AssignAt - 4));
        LowText := Trim(Copy(Code, AssignAt + 2, ToAt - AssignAt - 2));
        HighText := Trim(Copy(Code, ToAt + 4, DoAt - ToAt - 4));
        if not IsValidIdent(LoopVar) or not Scan.Plain[ForLine] or
           (Scan.BodyStart[ForLine] < 0) or CodeLineInLoop(Lines, ForLine) then
          Continue;
        EnclosingRoutine(Lines, AFormClass, ForLine, RoutineName, LoopHead,
                         LoopEnd);
        if (RoutineName = '') or (LoopEnd < 0) then
          Continue;
        RoutineConstEnv(Lines, LoopHead, Scan.BodyStart[ForLine], Env);
        if not EvalConstExpr(LowText, Env, LowValue) or not LowValue.IsInt or
           not EvalConstExpr(HighText, Env, HighValue) or
           not HighValue.IsInt or (HighValue.Int < LowValue.Int) or
           (HighValue.Int - LowValue.Int > 63) then
          Continue;

        // Тело: begin ... end или один оператор
        BodyOpen := -1;
        if DoAt = Length(Upper) - 8 then
          BodyOpen := ForLine
        else
        begin
          StmtLine := ForLine + 1;
          while (StmtLine < LoopEnd) and (Keys[StmtLine] = '') do
            Inc(StmtLine);
          if Keys[StmtLine] = 'BEGIN' then
            BodyOpen := StmtLine;
        end;
        if BodyOpen >= 0 then
        begin
          BodyEnd := Scan.BlockEnd[BodyOpen];
          CallLine := BodyOpen + 1;
        end
        else
        begin
          BodyEnd := -1;
          CallLine := ForLine + 1;
        end;
        while (CallLine < LoopEnd) and (Keys[CallLine] = '') do
          Inc(CallLine);
        if not ParseHelperCall(Lines, CallLine, Helpers, LoopHelper, CallLhs,
                               Args, CallLast) or
           not LoopHelper.Simple or (LoopHelper.OutIdx >= 0) or
           LoopHelper.LocalCreator or (LoopHelper.NestExpr = '') or
           (LoopHelper.IncVar <> '') or not IsValidIdent(CallLhs) then
          Continue;
        if BodyOpen < 0 then
          BodyEnd := CallLast;
        if (BodyEnd <= CallLast - Ord(BodyOpen < 0)) and (BodyOpen >= 0) then
          Continue;

        // Дальше в теле - только CallLhs.Свойство := Выражение;
        Reason := '';
        PropNames.Clear;
        PropExprs.Clear;
        PropLines.Clear;
        if BodyOpen >= 0 then
          for StmtLine := CallLast + 1 to BodyEnd - 1 do
          begin
            Code := Trim(StripComment(Lines[StmtLine]));
            if Code = '' then
              Continue;
            AssignAt := Pos(':=', Code);
            if (AssignAt = 0) or (Code[Length(Code)] <> ';') or
               (CompareText(Copy(Code, 1, Length(CallLhs) + 1),
                            CallLhs + '.') <> 0) then
            begin
              Reason := 'в теле цикла строка ' + IntToStr(StmtLine + 1) +
                        ' - не свойство ' + CallLhs;
              Break;
            end;
            PropName := Trim(Copy(Code, Length(CallLhs) + 2,
                                  AssignAt - Length(CallLhs) - 2));
            PropExpr := Trim(Copy(Code, AssignAt + 2,
                                  Length(Code) - AssignAt - 2));
            if not IsPropPath(PropName) or HasWord(PropExpr, CallLhs) then
            begin
              Reason := 'в теле цикла строка ' + IntToStr(StmtLine + 1) +
                        ' - не разобрать';
              Break;
            end;
            PropNames.Add(PropName);
            PropExprs.Add(PropExpr);
            PropLines.Add(IntToStr(StmtLine));
          end;
        // CallLhs - локальная переменная, вне цикла не используется
        if (Reason = '') and
           not FindLocalDecl(Lines, LoopHead, CallLhs, LocalDecl, LocalVarLine,
                             LocalNames) then
          Reason := CallLhs + ' - не локальная переменная ' + RoutineName;
        if Reason = '' then
          for LineIndex := LoopHead + 1 to LoopEnd do
            if ((LineIndex < ForLine) or (LineIndex > BodyEnd)) and
               (LineIndex <> LocalDecl) and
               HasWord(StripComment(Lines[LineIndex]), CallLhs) then
            begin
              Reason := CallLhs + ' используется и вне цикла, строка ' +
                        IntToStr(LineIndex + 1);
              Break;
            end;
        // Процедура выполняется один раз
        if (Reason = '') and (CompareText(RoutineName, 'FormCreate') <> 0) and
           (CompareText(RoutineName, 'Create') <> 0) then
        begin
          CountUses(Lines, RoutineName, Calls, Assigns);
          if Assigns > 0 then
            Reason := RoutineName + ' - обработчик события, может ' +
                      'вызываться много раз'
          else if Calls <> 1 then
            Reason := RoutineName + ' вызывается ' + IntToStr(Calls) + ' ' +
                      TimesWord(Calls);
        end;

        // Проходы
        Members.Clear;
        NamesText := '';
        PassIndex := 0;
        if Reason = '' then
          for PassValue := LowValue.Int to HighValue.Int do
          begin
            PassEnv.Assign(Env);
            PassEnv.Values[UpperCase(LoopVar)] := 'I:' + IntToStr(PassValue);
            PassArgs.Clear;
            for ArgIndex := 0 to Args.Count - 1 do
            begin
              if not PassText(Args[ArgIndex], ArgText) then
              begin
                Reason := 'аргумент ' + Args[ArgIndex] + ' не посчитать';
                Break;
              end;
              PassArgs.Add(ArgText);
            end;
            if Reason <> '' then
              Break;
            ParentName := HelperValue(LoopHelper, PassArgs, LoopHelper.NestExpr);
            if CompareText(Copy(ParentName, Length(ParentName) - 5, 6),
                           '.Items') = 0 then
              Delete(ParentName, Length(ParentName) - 5, 6);
            ParentAt := Names.IndexOf(ParentName);
            if ParentAt < 0 then
            begin
              Reason := 'родителя ' + ParentName + ' нет в дереве формы';
              Break;
            end;
            NewNode := TDfmNode.Create;
            NewNode.ClassNm := LoopHelper.Cls;
            NewNode.CreateLine := CallLine;
            NewNode.IsRuntime := True;
            NewNode.FromCode := True;
            NewNode.Parent := TDfmNode(Names.Objects[ParentAt]);
            NewNode.VarName := NewComponentName(ParentName, LoopHelper.Cls);
            Member := TMoveInfo.Create;
            Members.Add(Member);
            Member.Node := NewNode;
            Member.OwnsNode := True;
            Member.NewField := True;
            Member.Title := NewNode.VarName + ': ' + NewNode.ClassNm;
            Member.UnrollArgs := TStringList.Create;
            Member.UnrollArgs.Assign(PassArgs);
            Member.UnrollVar := CallLhs;
            Member.NestOrder := PassIndex;
            Inc(PassIndex);
            AnalyzeNode(Member, Lines, Keys, AFormClass, ClassFirst, ClassLast,
                        Names, Helpers, Scan);
            if not (Member.Kind in [mkWhole, mkPartial]) then
            begin
              Reason := Member.Reason;
              Break;
            end;
            // Свойства из тела цикла
            MemberClass := GetClass(NewNode.ClassNm);
            Shown := '';
            for ArgIndex := 0 to PropNames.Count - 1 do
            begin
              PropName := PropNames[ArgIndex];
              LineIndex := StrToInt(PropLines[ArgIndex]);
              MemberProp := nil;
              if MemberClass <> nil then
                MemberProp := PublishedProp(MemberClass, PropName);
              if (MemberProp = nil) or
                 not PassText(PropExprs[ArgIndex], PropExpr) then
              begin
                Reason := CallLhs + '.' + PropName + ' (строка ' +
                          IntToStr(LineIndex + 1) + ') - не записать в .dfm';
                Break;
              end;
              if (Length(PropName) > 2) and (UpCase(PropName[1]) = 'O') and
                 (UpCase(PropName[2]) = 'N') and (Pos('.', PropName) = 0) then
              begin
                if IsLoadTimeEvent(PropName) or not IsValidIdent(PropExpr) or
                   (FindMethodImpl(Lines, AFormClass, PropExpr) < 0) then
                begin
                  Reason := CallLhs + '.' + PropName + ' := ' + PropExpr +
                            ' - не записать в .dfm';
                  Break;
                end;
                AddMoveItem(Member, LineIndex, mlEvent, PropName, PropExpr);
                if Member.Handlers.IndexOf(PropExpr) < 0 then
                  Member.Handlers.Add(PropExpr);
              end
              else if MemberProp^.PropType^^.Kind = tkClass then
              begin
                Reason := CallLhs + '.' + PropName + ' - ссылка, в цикле не ' +
                          'разбирается';
                Break;
              end
              else if ShortCutValue(PropExpr, KeyNumber) then
                AddMoveItem(Member, LineIndex, mlProp, PropName,
                            IntToStr(KeyNumber))
              else if IsLiteral(PropExpr) then
                AddMoveItem(Member, LineIndex, mlProp, PropName,
                            DfmLiteral(PropExpr))
              else
              begin
                Reason := CallLhs + '.' + PropName + ' := ' + PropExpr +
                          ' - значение вычисляется';
                Break;
              end;
              if Shown <> '' then
                Shown := Shown + ', ';
              Shown := Shown + PropName + ' = ' + PropExpr;
            end;
            if Reason <> '' then
              Break;
            // Строки цикла - уходят
            for LineIndex := ForLine to BodyEnd do
              if (Keys[LineIndex] <> '') and
                 ((LineIndex < CallLine) or (LineIndex > CallLast)) then
              begin
                AddMoveItem(Member, LineIndex, mlCreate, '', '');
                if LineIndex = ForLine then
                  Member.MoveLines.Add(LineRef(Lines, LineIndex) + '   [цикл ' +
                                       'развёрнут: проход ' + LoopVar + ' = ' +
                                       IntToStr(PassValue) + ']')
                else if PropLines.IndexOf(IntToStr(LineIndex)) >= 0 then
                  Member.MoveLines.Add(LineRef(Lines, LineIndex) + '   [у ' +
                                       'этого прохода: ' + Shown + ']')
                else
                  Member.MoveLines.Add(LineRef(Lines, LineIndex) + '   [строка ' +
                                       'цикла]');
              end;
            Member.HelperGroup := ForLine;
            Member.HelperName := 'цикла for в ' + RoutineName + ' (строка ' +
                                 IntToStr(ForLine + 1) + ')';
            if NamesText <> '' then
              NamesText := NamesText + ', ';
            NamesText := NamesText + NewNode.VarName;
          end;

        if (Reason = '') and (Members.Count > 0) then
        begin
          // В дерево - под родителем, по порядку проходов
          ParentInfo := nil;
          InsertAt := AList.Count;
          for Other := 0 to AList.Count - 1 do
            if TMoveInfo(AList[Other]).Node =
               TDfmNode(TMoveInfo(Members[0]).Node).Parent then
            begin
              ParentInfo := TMoveInfo(AList[Other]);
              InsertAt := Other + 1;
              while (InsertAt < AList.Count) and
                    (TMoveInfo(AList[InsertAt]).Depth > ParentInfo.Depth) do
                Inc(InsertAt);
              Break;
            end;
          if ParentInfo = nil then
            Reason := 'родителя нет в списке разбора';
        end;
        if Reason <> '' then
        begin
          for Other := 0 to Members.Count - 1 do
          begin
            Member := TMoveInfo(Members[Other]);
            if NewNames.IndexOf(TDfmNode(Member.Node).VarName) >= 0 then
              NewNames.Delete(NewNames.IndexOf(TDfmNode(Member.Node).VarName));
            Member.Free;
          end;
          Members.Clear;
          SetSubReasons('создаётся в цикле for (строка ' + IntToStr(ForLine + 1) +
                        ') по константам - развернуть нельзя: ' + Reason);
          Continue;
        end;
        for Other := 0 to Members.Count - 1 do
        begin
          Member := TMoveInfo(Members[Other]);
          Member.Depth := ParentInfo.Depth + 1;
          Member.Notes.Add('Цикл for (строка ' + IntToStr(ForLine + 1) + ') ' +
                           'по константам развёрнут: у каждого прохода - свой ' +
                           'компонент .dfm (' + NamesText + ') с посчитанными ' +
                           'значениями; строки цикла уходят, проходы ' +
                           'переносятся только все вместе.');
          Member.Notes.Add('После переноса ' + LoopVar + ', ' + CallLhs +
                           ' и константы цикла в ' + RoutineName + ' могут ' +
                           'остаться без использования - Delphi скажет об ' +
                           'этом подсказкой.');
          AList.Insert(InsertAt + Other, Member);
        end;
        Members.Clear;
        SetSubReasons('создаётся в цикле for (строка ' + IntToStr(ForLine + 1) +
                      ') по константам - цикл развёртывается: ' + NamesText);
      end;
    finally
      for Other := 0 to Members.Count - 1 do
        TObject(Members[Other]).Free;
      Members.Free;
      PropLines.Free;
      PropExprs.Free;
      PropNames.Free;
      PassArgs.Free;
      Args.Free;
      PassEnv.Free;
      Env.Free;
    end;
  end;

  // Процедура AHelper создаёт компонент в своей локальной переменной, и
  // каждый её вызов переносится своим компонентом. Её тело уходит из кода
  // вместе с вызовами - поэтому они переносятся только все вместе, и каждое
  // упоминание процедуры в модуле должно быть таким вызовом.
  procedure ResolveLocalCreator(AHelper: THelperInfo);
  var
    Group: TList;
    MemberIndex, LineIndex, BodyIndex, RefCount, FirstOther: Integer;
    Mate, Failed: TMoveInfo;
    Reason, NamesText: string;
    Listed: Boolean;
  begin
    Group := TList.Create;
    try
      for MemberIndex := 0 to AList.Count - 1 do
        if TMoveInfo(AList[MemberIndex]).HelperGroup = AHelper.HdrLine then
          Group.Add(AList[MemberIndex]);
      if Group.Count = 0 then
        Exit;
      RefCount := 0;
      FirstOther := -1;
      for LineIndex := 0 to Lines.Count - 1 do
      begin
        if ((LineIndex >= AHelper.HdrLine) and
            (LineIndex <= AHelper.HeadEnd)) or
           ((LineIndex >= ClassFirst) and (LineIndex <= ClassLast)) then
          Continue;
        if not HasWord(StripComment(Lines[LineIndex]), AHelper.Name) then
          Continue;
        Inc(RefCount);
        Listed := False;
        for MemberIndex := 0 to Group.Count - 1 do
          if TMoveInfo(Group[MemberIndex]).CreateLine = LineIndex then
            Listed := True;
        if not Listed and (FirstOther < 0) then
          FirstOther := LineIndex;
      end;
      Reason := '';
      if (RefCount <> Group.Count) or (FirstOther >= 0) then
      begin
        Reason := AHelper.Name + ' упоминается в ' + IntToStr(RefCount) +
                  ' строках, а переносимых вызовов - ' + IntToStr(Group.Count);
        if FirstOther >= 0 then
          Reason := Reason + ' (например, строка ' + IntToStr(FirstOther + 1) +
                    ')';
        Reason := Reason + ': её тело уходит вместе с вызовами, поэтому ' +
                  'переносятся только все вместе';
      end
      else
      begin
        Failed := nil;
        for MemberIndex := 0 to Group.Count - 1 do
          if not (TMoveInfo(Group[MemberIndex]).Kind in [mkWhole, mkPartial]) then
          begin
            Failed := TMoveInfo(Group[MemberIndex]);
            Break;
          end;
        if Failed <> nil then
          Reason := 'вызов ' + AHelper.Name + ' ' + Failed.Title +
                    ' не переносится (' + Failed.Reason + ') - вызовы ' +
                    'переносятся только все вместе';
      end;
      if Reason <> '' then
      begin
        for MemberIndex := 0 to Group.Count - 1 do
        begin
          Mate := TMoveInfo(Group[MemberIndex]);
          if not (Mate.Kind in [mkWhole, mkPartial]) then
            Continue;
          ClearMoveData(Mate);
          Mate.Kind := mkNo;
          Mate.Reason := Reason;
        end;
        Exit;
      end;
      NamesText := '';
      for MemberIndex := 0 to Group.Count - 1 do
      begin
        Mate := TMoveInfo(Group[MemberIndex]);
        if NamesText <> '' then
          NamesText := NamesText + ', ';
        NamesText := NamesText + TDfmNode(Mate.Node).VarName;
        for BodyIndex := 0 to AHelper.BodyLines.Count - 1 do
        begin
          LineIndex := Integer(AHelper.BodyLines[BodyIndex]);
          AddMoveItem(Mate, LineIndex, mlCreate, '', '');
          Mate.MoveLines.Add(LineRef(Lines, LineIndex) + '   [тело ' +
                             AHelper.Name + ' - уходит вместе со всеми ' +
                             'вызовами]');
        end;
        Mate.Notes.Add(AHelper.Name + ' создаёт пункт в локальной ' +
                       'переменной ' + AHelper.LocalName + ' и вызывается ' +
                       IntToStr(Group.Count) + ' раз: каждый вызов - свой ' +
                       'компонент .dfm, строки вызовов и тела процедуры ' +
                       'уходят. Переносятся только все вызовы вместе; сама ' +
                       'процедура остаётся пустой.');
      end;
      // Узел дерева - создание в теле процедуры: что с ним будет
      for MemberIndex := 0 to AList.Count - 1 do
      begin
        Mate := TMoveInfo(AList[MemberIndex]);
        if (Mate.Kind = mkNo) and (Mate.HelperGroup < 0) and
           (TDfmNode(Mate.Node).CreateLine > AHelper.BodyStart) and
           (TDfmNode(Mate.Node).CreateLine < AHelper.BodyEnd) then
          Mate.Reason := 'создаётся в ' + AHelper.Name + ', которая ' +
                         'вызывается ' + IntToStr(Group.Count) + ' ' +
                         TimesWord(Group.Count) + ': переносятся её вызовы - ' +
                         NamesText;
      end;
    finally
      Group.Free;
    end;
  end;

  // GDfmIntValues: Left, Top, Width, Height компонентов .dfm без
  // выравнивания и привязок, которые код не меняет
  procedure CollectDfmIntValues;
  var
    ItemIndex, PropIndex, At, Value: Integer;
    DfmNode: TDfmNode;
    Blocked: Boolean;
    PropName: string;
  begin
    for ItemIndex := 0 to ATree.Items.Count - 1 do
    begin
      if ATree.Items[ItemIndex].Data = nil then
        Continue;
      DfmNode := TDfmNode(ATree.Items[ItemIndex].Data);
      if (DfmNode.Name = '') or DfmNode.IsRuntime or DfmNode.FromCode or
         DfmNode.IsSnap or DfmNode.IsLive or DfmNode.IsLink or
         (DfmNode.Parent = nil) then
        Continue;
      Blocked := False;
      for PropIndex := 0 to DfmNode.PropN.Count - 1 do
      begin
        PropName := DfmNode.PropN[PropIndex];
        if (CompareText(PropName, 'Align') = 0) or
           (CompareText(PropName, 'Anchors') = 0) or
           (CompareText(PropName, 'AutoSize') = 0) or
           (CompareText(Copy(PropName, 1, 12), 'Constraints.') = 0) then
          Blocked := True;
      end;
      if Blocked or not GeometryStable(DfmNode.Name) then
        Continue;
      for PropIndex := Low(GeometryProps) to High(GeometryProps) do
      begin
        At := DfmNode.PropN.IndexOf(GeometryProps[PropIndex]);
        if (At < 0) or (At >= DfmNode.PropV.Count) then
          Continue;
        Value := StrToIntDef(Trim(DfmNode.PropV[At]), MaxInt);
        if Value <> MaxInt then
          GDfmIntValues.Values[UpperCase(DfmNode.Name + '.' +
                               GeometryProps[PropIndex])] := IntToStr(Value);
      end;
    end;
  end;

  // Процедура-создатель AHelper: она остаётся, а создание, родитель и
  // свойства уходят из неё в .dfm - сразу для всех вызовов. Поэтому
  // строка уходит, только если её значение записывается в .dfm у каждого
  // вызова, и вызовы переносятся только все вместе.
  procedure ResolveVarHelper(AHelper: THelperInfo);
  var
    Group, MemberArgs, MemberValues, MemberItems: TList;
    MemberIndex, StmtIndex, ChainIndex, LineIndex, RefCount, CallHead,
      CallEnd, FirstOther, DoneCount: Integer;
    Mate, Failed: TMoveInfo;
    Stmt: THelperStmt;
    Args, Caller, Scope, Mentioned, Touched, ExprChains: TStringList;
    AllMentioned, Moves: Boolean;
    Text, CallRoutine, Chain, Head, OutUpper, DfmValue, PropUpper,
      KeptText, MovedText: string;
    MateClass: TPersistentClass;
    MateProp: PPropInfo;
    Kind: TMoveLineKind;
    CallHelper: THelperInfo;

    procedure FailGroup(const AReason: string);
    var
      FailIndex: Integer;
      FailInfo: TMoveInfo;
    begin
      for FailIndex := 0 to Group.Count - 1 do
      begin
        FailInfo := TMoveInfo(Group[FailIndex]);
        if not (FailInfo.Kind in [mkWhole, mkPartial]) then
          Continue;
        ClearMoveData(FailInfo);
        FailInfo.Kind := mkNo;
        FailInfo.Reason := AReason;
      end;
    end;

    // Значение строки AStmt у вызова AIndex для .dfm; False - не записать
    function StmtValue(AIndex: Integer; AStmt: THelperStmt;
      AStmtIndex: Integer; var AKind: TMoveLineKind;
      var AValue: string): Boolean;
    var
      ExprUpper: string;
      Number: Integer;
    begin
      Result := False;
      AKind := mlProp;
      AValue := HelperValue(AHelper, TStringList(MemberArgs[AIndex]),
                            AStmt.Expr);
      ExprUpper := UpperCase(Trim(AStmt.Expr));
      MateClass := GetClass(TDfmNode(TMoveInfo(Group[AIndex]).Node).ClassNm);
      if MateClass = nil then
        Exit;
      MateProp := PublishedProp(MateClass, AStmt.PropName);
      if MateProp = nil then
        Exit;
      if AHelper.LocalNames.IndexOf(ExprUpper) >= 0 then
        Exit;
      if (Length(AStmt.PropName) > 2) and (UpCase(AStmt.PropName[1]) = 'O') and
         (UpCase(AStmt.PropName[2]) = 'N') and (Pos('.', AStmt.PropName) = 0) then
      begin
        // Событие: nil - в .dfm его нет, метод формы - в .dfm
        if IsLoadTimeEvent(AStmt.PropName) then
          Exit;
        if CompareText(AValue, 'nil') = 0 then
        begin
          AKind := mlCreate;
          AValue := '';
          Result := True;
          Exit;
        end;
        if IsValidIdent(AValue) and
           (FindMethodImpl(Lines, AFormClass, AValue) >= 0) then
        begin
          AKind := mlEvent;
          Result := True;
        end;
        Exit;
      end;
      if MateProp^.PropType^^.Kind = tkClass then
        Exit;
      if ShortCutValue(AValue, Number) then
      begin
        AValue := IntToStr(Number);
        Result := True;
        Exit;
      end;
      if (AHelper.Consts.IndexOfName(ExprUpper) < 0) and IsLiteral(AValue) then
      begin
        AValue := DfmLiteral(AValue);
        Result := True;
        Exit;
      end;
      if MateProp^.PropType^^.Kind = tkInteger then
      begin
        HelperScopeValues(AHelper, TStringList(MemberArgs[AIndex]),
                          TStringList(MemberValues[AIndex]), AStmtIndex, Scope);
        if EvalIntExpr(AStmt.Expr, Scope, Number) then
        begin
          AValue := IntToStr(Number);
          Result := True;
        end;
      end;
    end;

  begin
    Group := TList.Create;
    MemberArgs := TList.Create;
    MemberValues := TList.Create;
    MemberItems := TList.Create;
    Scope := TStringList.Create;
    Mentioned := TStringList.Create;
    Touched := TStringList.Create;
    ExprChains := TStringList.Create;
    try
      for MemberIndex := 0 to AList.Count - 1 do
        if TMoveInfo(AList[MemberIndex]).HelperGroup = AHelper.HdrLine then
          Group.Add(AList[MemberIndex]);
      if Group.Count = 0 then
        Exit;

      // Все упоминания процедуры - разбираемые вызовы
      RefCount := 0;
      FirstOther := -1;
      for LineIndex := 0 to Lines.Count - 1 do
      begin
        if ((LineIndex >= AHelper.HdrLine) and
            (LineIndex <= AHelper.HeadEnd)) or
           ((LineIndex >= ClassFirst) and (LineIndex <= ClassLast)) then
          Continue;
        if not HasWord(StripComment(Lines[LineIndex]), AHelper.Name) then
          Continue;
        Inc(RefCount);
        Moves := False;
        for MemberIndex := 0 to Group.Count - 1 do
          if TMoveInfo(Group[MemberIndex]).CreateLine = LineIndex then
            Moves := True;
        if not Moves and (FirstOther < 0) then
          FirstOther := LineIndex;
      end;
      if (RefCount <> Group.Count) or (FirstOther >= 0) then
      begin
        Text := AHelper.Name + ' упоминается в ' + IntToStr(RefCount) +
                ' строках, а вызовов с компонентом из дерева - ' +
                IntToStr(Group.Count);
        if FirstOther >= 0 then
          Text := Text + ' (например, строка ' + IntToStr(FirstOther + 1) + ')';
        FailGroup(Text + ': из неё уходит создание сразу для всех вызовов, ' +
                  'поэтому переносятся только все вместе');
        Exit;
      end;

      // Все вызовы переносятся
      Failed := nil;
      for MemberIndex := 0 to Group.Count - 1 do
        if not (TMoveInfo(Group[MemberIndex]).Kind in [mkWhole, mkPartial]) then
        begin
          Failed := TMoveInfo(Group[MemberIndex]);
          Break;
        end;
      if Failed <> nil then
      begin
        FailGroup('через ' + AHelper.Name + ' создаётся и ' + Failed.Title +
                  ', а он не переносится (' + Failed.Reason + ') - вызовы ' +
                  AHelper.Name + ' переносятся только все вместе');
        Exit;
      end;

      // Аргументы и значения у каждого вызова
      for MemberIndex := 0 to Group.Count - 1 do
      begin
        Mate := TMoveInfo(Group[MemberIndex]);
        Args := TStringList.Create;
        MemberArgs.Add(Args);
        Caller := TStringList.Create;
        MemberValues.Add(Caller);
        ParseHelperCall(Lines, Mate.CreateLine, Helpers, CallHelper, Text,
                        Args, LineIndex);
        EnclosingRoutine(Lines, AFormClass, Mate.CreateLine, CallRoutine,
                         CallHead, CallEnd);
        RoutineIntValues(Lines, Keys, Scan, Helpers, CallHead, Mate.CreateLine,
                         Caller);
      end;

      // Какие строки уходят: создание и родитель - всегда (иначе вызовы не
      // переносятся), свойство - если записывается у всех вызовов
      for StmtIndex := 0 to AHelper.Stmts.Count - 1 do
      begin
        Stmt := THelperStmt(AHelper.Stmts[StmtIndex]);
        Stmt.Moves := Stmt.Kind in [hsCreate, hsParent, hsProp];
        if Stmt.Kind <> hsProp then
          Continue;
        for MemberIndex := 0 to Group.Count - 1 do
          if not StmtValue(MemberIndex, Stmt, StmtIndex, Kind, DfmValue) then
          begin
            Stmt.Moves := False;
            Break;
          end;
      end;
      // Порядок: свойство уходит в .dfm (встанет до всего в процедуре),
      // только если строки выше, которые остаются, его не трогают, не
      // передают компонент целиком и не меняют имён из его выражения
      OutUpper := UpperCase(AHelper.OutName);
      AllMentioned := False;
      for StmtIndex := 0 to AHelper.Stmts.Count - 1 do
      begin
        Stmt := THelperStmt(AHelper.Stmts[StmtIndex]);
        if Stmt.Kind = hsParent then
        begin
          if AllMentioned or (Mentioned.IndexOf('PARENT') >= 0) then
          begin
            FailGroup(AHelper.Name + ': родитель ставится в строке ' +
                      IntToStr(Stmt.First + 1) + ', а выше остаётся строка ' +
                      'с компонентом - порядок не сохранить');
            Exit;
          end;
          Continue;
        end;
        if Stmt.Kind = hsCreate then
          Continue;
        PropUpper := UpperCase(ChainHead(Stmt.PropName));
        if Stmt.Moves then
        begin
          ScanChains(Stmt.Expr, ExprChains);
          if AllMentioned or (Mentioned.IndexOf(PropUpper) >= 0) then
            Stmt.Moves := False
          else
            for ChainIndex := 0 to ExprChains.Count - 1 do
              if Touched.IndexOf(ChainHead(ExprChains[ChainIndex])) >= 0 then
                Stmt.Moves := False;
        end;
        if Stmt.Moves then
          Continue;
        if Stmt.Kind = hsProp then
        begin
          Mentioned.Add(PropUpper);
          Continue;
        end;
        for ChainIndex := 0 to Stmt.Chains.Count - 1 do
        begin
          Chain := Stmt.Chains[ChainIndex];
          Head := ChainHead(Chain);
          if Head = OutUpper then
          begin
            if Chain = OutUpper then
              AllMentioned := True
            else
              Mentioned.Add(ChainHead(Copy(Chain, Length(OutUpper) + 2,
                                           MaxInt)));
          end
          else if AHelper.Consts.IndexOfName(Head) < 0 then
            Touched.Add(Head);
        end;
      end;

      // Строки у каждого вызова: уходящие - в Items (перед строками
      // вызывающей процедуры), остающиеся - в KeepLines
      KeptText := '';
      MovedText := '';
      for StmtIndex := 0 to AHelper.Stmts.Count - 1 do
      begin
        Stmt := THelperStmt(AHelper.Stmts[StmtIndex]);
        if Stmt.Moves then
        begin
          if MovedText <> '' then
            MovedText := MovedText + ', ';
          MovedText := MovedText + IntToStr(Stmt.First + 1);
        end
        else
        begin
          if KeptText <> '' then
            KeptText := KeptText + ', ';
          if Stmt.First = Stmt.Last then
            KeptText := KeptText + IntToStr(Stmt.First + 1)
          else
            KeptText := KeptText + IntToStr(Stmt.First + 1) + '-' +
                        IntToStr(Stmt.Last + 1);
        end;
      end;
      for MemberIndex := 0 to Group.Count - 1 do
      begin
        Mate := TMoveInfo(Group[MemberIndex]);
        MemberItems.Clear;
        DoneCount := Mate.Items.Count;
        for StmtIndex := 0 to AHelper.Stmts.Count - 1 do
        begin
          Stmt := THelperStmt(AHelper.Stmts[StmtIndex]);
          if not Stmt.Moves then
          begin
            for LineIndex := Stmt.First to Stmt.Last do
              if LineIndex = Stmt.First then
                Mate.KeepLines.Add(LineRef(Lines, LineIndex) + '   [остаётся ' +
                                   'в ' + AHelper.Name + ']')
              else
                Mate.KeepLines.Add(LineRef(Lines, LineIndex) + '   [...]');
            Continue;
          end;
          case Stmt.Kind of
            hsCreate:
              begin
                AddMoveItem(Mate, Stmt.First, mlCreate, '', '');
                Mate.MoveLines.Add(LineRef(Lines, Stmt.First) + '   [' +
                                   AHelper.Name + ': создание - это сделает ' +
                                   '.dfm]');
              end;
            hsParent:
              begin
                if Mate.NestParent = '' then
                  AddMoveItem(Mate, Stmt.First, mlNesting, '', 'Self')
                else
                  AddMoveItem(Mate, Stmt.First, mlNesting, '', Mate.NestParent);
                Mate.MoveLines.Add(LineRef(Lines, Stmt.First) + '   [' +
                                   AHelper.Name + ': родитель - вложенностью ' +
                                   'в .dfm]');
              end;
            hsProp:
              begin
                StmtValue(MemberIndex, Stmt, StmtIndex, Kind, DfmValue);
                AddMoveItem(Mate, Stmt.First, Kind, Stmt.PropName, DfmValue);
                if Kind = mlEvent then
                begin
                  if Mate.Handlers.IndexOf(DfmValue) < 0 then
                    Mate.Handlers.Add(DfmValue);
                  Mate.MoveLines.Add(LineRef(Lines, Stmt.First) + '   [' +
                                     AHelper.Name + ': ' + Stmt.PropName +
                                     ' = ' + DfmValue + ']');
                end
                else if Kind = mlCreate then
                  Mate.MoveLines.Add(LineRef(Lines, Stmt.First) + '   [' +
                                     AHelper.Name + ': ' + Stmt.PropName +
                                     ' = nil - в .dfm не пишется]')
                else
                  Mate.MoveLines.Add(LineRef(Lines, Stmt.First) + '   [' +
                                     AHelper.Name + ': ' + Stmt.PropName +
                                     ' = ' + DfmValue + ']');
              end;
          end;
        end;
        // Новые пункты - в начало: .dfm задаёт их раньше строк после вызова
        for LineIndex := DoneCount to Mate.Items.Count - 1 do
          MemberItems.Add(Mate.Items[LineIndex]);
        for LineIndex := Mate.Items.Count - 1 downto DoneCount do
          Mate.Items.Delete(LineIndex);
        for LineIndex := MemberItems.Count - 1 downto 0 do
          Mate.Items.Insert(0, MemberItems[LineIndex]);
        Mate.Notes.Add(AHelper.Name + ' остаётся и вызывается как раньше, ' +
                       'но компонент больше не создаёт: из неё уходят строки ' +
                       MovedText + ' - сразу для всех ' +
                       IntToStr(Group.Count) + ' вызовов, поэтому они ' +
                       'переносятся только все вместе.');
        if KeptText <> '' then
          Mate.Notes.Add('В ' + AHelper.Name + ' остаются строки ' + KeptText +
                         ': они выполняются при вызове, как раньше.');
      end;
    finally
      for MemberIndex := 0 to MemberArgs.Count - 1 do
        TObject(MemberArgs[MemberIndex]).Free;
      for MemberIndex := 0 to MemberValues.Count - 1 do
        TObject(MemberValues[MemberIndex]).Free;
      ExprChains.Free;
      Touched.Free;
      Mentioned.Free;
      Scope.Free;
      MemberItems.Free;
      MemberValues.Free;
      MemberArgs.Free;
      Group.Free;
    end;
  end;

begin
  Lines := TStringList.Create;
  Keys := TStringList.Create;
  Names := TStringList.Create;
  CallArgs := TStringList.Create;
  NewNames := TStringList.Create;
  Helpers := TList.Create;
  Scan := TUnitScan.Create;
  Routines := TList.Create;
  RoutineNames := TStringList.Create;
  InitHandlers := TStringList.Create;
  try
    Lines.Text := APasText;
    for Index := 0 to Lines.Count - 1 do
      Keys.Add(CodeKey(Lines[Index]));
    Scan.Scan(Lines);
    FindClassDecl(Lines, AFormClass, ClassFirst, ClassLast);
    CollectHelpers(Lines, Helpers);
    CollectLocalCreators(Lines, AFormClass, Helpers);
    MarkBareSafe;
    // Имена всех узлов дерева - возможные родители и владельцы
    for Index := 0 to ATree.Items.Count - 1 do
      if ATree.Items[Index].Data <> nil then
      begin
        Node := TDfmNode(ATree.Items[Index].Data);
        if Node.Name <> '' then
          Names.AddObject(Node.Name, Node);
        if (Node.VarName <> '') and (Names.IndexOf(Node.VarName) < 0) then
          Names.AddObject(Node.VarName, Node);
      end;
    GDfmIntValues := TStringList.Create;
    CollectDfmIntValues;

    for Index := 0 to ATree.Items.Count - 1 do
    begin
      if ATree.Items[Index].Data = nil then
        Continue;
      Node := TDfmNode(ATree.Items[Index].Data);
      if Node.IsLink or Node.SnapRoot then
        Continue;
      Info := TMoveInfo.Create;
      Info.Node := Node;
      Info.Depth := ATree.Items[Index].Level;
      if Node.Name <> '' then
        Info.Title := Node.Name + ': ' + Node.ClassNm
      else if Node.VarName <> '' then
        Info.Title := Node.VarName + ': ' + Node.ClassNm
      else
        Info.Title := Node.ClassNm;
      AnalyzeNode(Info, Lines, Keys, AFormClass, ClassFirst, ClassLast, Names,
                  Helpers, Scan);
      AList.Add(Info);
    end;

    // Процедуры-создатели: что из них уходит - по всем вызовам вместе
    for Index := 0 to Helpers.Count - 1 do
    begin
      Helper := THelperInfo(Helpers[Index]);
      if (Helper.OutIdx >= 0) and Helper.Simple then
        ResolveVarHelper(Helper);
    end;

    // Вызовы помощников без переменной (MakeItem(Self, P, ...);): в
    // дереве их нет. Переносимые - в список под родителем, с новым именем;
    // остальные не показываются, как и раньше.
    for Index := 0 to Lines.Count - 1 do
    begin
      if not ParseHelperCall(Lines, Index, Helpers, Helper, CallLhs, CallArgs,
                             CallLast) then
        Continue;
      if (CallLhs <> '') or not Helper.Simple or (Helper.NestExpr = '') or
         (Helper.OutIdx >= 0) then
        Continue;
      ParentName := HelperValue(Helper, CallArgs, Helper.NestExpr);
      if CompareText(Copy(ParentName, Length(ParentName) - 5, 6),
                     '.Items') = 0 then
        Delete(ParentName, Length(ParentName) - 5, 6);
      ParentAt := Names.IndexOf(ParentName);
      if ParentAt < 0 then
        Continue;
      // Локальная переменная, которой создают несколько компонентов
      // (Grp): родитель - созданный ей последним перед вызовом
      ParentNode := TDfmNode(Names.Objects[ParentAt]);
      for Other := 0 to ATree.Items.Count - 1 do
        if (ATree.Items[Other].Data <> nil) and
           (CompareText(TDfmNode(ATree.Items[Other].Data).VarName,
                        ParentName) = 0) and
           (TDfmNode(ATree.Items[Other].Data).CreateLine >= 0) and
           (TDfmNode(ATree.Items[Other].Data).CreateLine < Index) and
           ((ParentNode.CreateLine < 0) or (ParentNode.CreateLine >= Index) or
            (TDfmNode(ATree.Items[Other].Data).CreateLine >
             ParentNode.CreateLine)) then
          ParentNode := TDfmNode(ATree.Items[Other].Data);
      ParentInfo := nil;
      for Other := 0 to AList.Count - 1 do
        if TMoveInfo(AList[Other]).Node = ParentNode then
        begin
          ParentInfo := TMoveInfo(AList[Other]);
          InsertAt := Other + 1;
          while (InsertAt < AList.Count) and
                (TMoveInfo(AList[InsertAt]).Depth > ParentInfo.Depth) do
            Inc(InsertAt);
          Break;
        end;
      if ParentInfo = nil then
        Continue;
      Node := TDfmNode.Create;
      Node.ClassNm := Helper.Cls;
      Node.CreateLine := Index;
      Node.IsRuntime := True;
      Node.FromCode := True;
      Node.Parent := ParentNode;
      Info := TMoveInfo.Create;
      Info.Node := Node;
      Info.OwnsNode := True;
      Info.NewField := True;
      Info.Depth := ParentInfo.Depth + 1;
      Node.VarName := NewComponentName(ParentName, Helper.Cls);
      Info.Title := Node.VarName + ': ' + Node.ClassNm;
      AnalyzeNode(Info, Lines, Keys, AFormClass, ClassFirst, ClassLast, Names,
                  Helpers, Scan);
      if Info.Kind = mkNo then
      begin
        NewNames.Delete(NewNames.IndexOf(Node.VarName));
        Info.Free;
        Continue;
      end;
      Info.Notes.Add('Вызов без переменной: при переносе объект получит ' +
                     'имя ' + Node.VarName + ' и published-поле.');
      if Helper.LocalCreator then
      begin
        Info.HelperGroup := Helper.HdrLine;
        Info.HelperName := Helper.Name;
      end;
      AList.Insert(InsertAt, Info);
    end;

    // Процедуры, создающие компонент в локальной переменной: вызовы - только
    // все вместе, с ними уходит и тело
    for Index := 0 to Helpers.Count - 1 do
    begin
      Helper := THelperInfo(Helpers[Index]);
      if Helper.LocalCreator and Helper.Simple then
        ResolveLocalCreator(Helper);
    end;

    // Циклы for по константному массиву - по проходам
    UnrollConstLoops;

    // Разделители NewLine (P.Add(NewLine)): пункт без имени, созданный
    // функцией Menus. В .dfm - пункт с Caption = '-', с именем и
    // published-полем. Остаётся в списке и при «нет»: по нему соседи
    // проверяют порядок.
    for Index := 0 to Lines.Count - 1 do
    begin
      if not ParseAddLine(Trim(StripComment(Lines[Index])), ParentName,
                          CallLhs) or
         (CompareText(CallLhs, 'NewLine') <> 0) then
        Continue;
      ParentAt := Names.IndexOf(ParentName);
      if (ParentAt < 0) or (Names.Objects[ParentAt] = nil) then
        Continue;
      ParentInfo := nil;
      InsertAt := AList.Count;
      for Other := 0 to AList.Count - 1 do
        if TMoveInfo(AList[Other]).Node = Names.Objects[ParentAt] then
        begin
          ParentInfo := TMoveInfo(AList[Other]);
          InsertAt := Other + 1;
          while (InsertAt < AList.Count) and
                (TMoveInfo(AList[InsertAt]).Depth > ParentInfo.Depth) do
            Inc(InsertAt);
          Break;
        end;
      if ParentInfo = nil then
        Continue;
      Node := TDfmNode.Create;
      Node.ClassNm := 'TMenuItem';
      Node.CreateLine := Index;
      Node.IsRuntime := True;
      Node.FromCode := True;
      Node.Parent := TDfmNode(Names.Objects[ParentAt]);
      Info := TMoveInfo.Create;
      Info.Node := Node;
      Info.OwnsNode := True;
      Info.NewField := True;
      Info.Depth := ParentInfo.Depth + 1;
      // Имя: родитель + Line + номер (mProjectLine1)
      Node.VarName := NewComponentName(ParentName, 'TLine');
      Info.Title := Node.VarName + ': TMenuItem';
      Info.CreateLine := Index;
      Info.Kind := mkNo;
      EnclosingRoutine(Lines, AFormClass, Index, Info.Routine, LineHead,
                       LineEnd);
      if (Info.Routine = '') or (LineEnd < 0) then
        Info.Reason := 'NewLine не в методе формы'
      else if not Scan.Plain[Index] then
        Info.Reason := 'NewLine внутри условного блока (if, case...), ' +
                       'строка ' + IntToStr(Index + 1)
      else if CodeLineInLoop(Lines, Index) then
        Info.Reason := 'NewLine в цикле, строка ' + IntToStr(Index + 1)
      else
      begin
        Calls := 1;
        Assigns := 0;
        if (CompareText(Info.Routine, 'FormCreate') <> 0) and
           (CompareText(Info.Routine, 'Create') <> 0) then
          CountUses(Lines, Info.Routine, Calls, Assigns);
        if Assigns > 0 then
          Info.Reason := Info.Routine + ' - обработчик события, может ' +
                         'вызываться много раз'
        else if Calls <> 1 then
          Info.Reason := Info.Routine + ' вызывается ' + IntToStr(Calls) +
                         ' ' + TimesWord(Calls)
        else
        begin
          Info.Kind := mkWhole;
          Info.MoveLines.Add(LineRef(Lines, Index) + '   [разделитель - ' +
                             'пунктом «-» в .dfm]');
          AddMoveItem(Info, Index, mlNesting, '', ParentName);
          AddMoveItem(Info, Index, mlProp, 'Caption', '''-''');
          Info.NestParent := ParentName;
          Info.NestLine := Index;
          Info.Notes.Add('NewLine (строка ' + IntToStr(Index + 1) + ') - ' +
                         'разделитель без имени; в .dfm - пункт «-» с ' +
                         'именем ' + Node.VarName + ' и published-полем.');
        end;
      end;
      AList.Insert(InsertAt, Info);
    end;

    // Перестановка пунктов меню из .dfm (P.Remove(X) ... P.Add(X)): всё,
    // что процедура создаёт для P, - одна группа; итоговый порядок пишется
    // в .dfm при переносе
    ReorderDone := TStringList.Create;
    try
      for Index := 0 to Lines.Count - 1 do
      begin
        if not ParseRemoveLine(Trim(StripComment(Lines[Index])), ParentName,
                               CallLhs) then
          Continue;
        EnclosingRoutine(Lines, AFormClass, Index, RoutineName, LineHead,
                         LineEnd);
        if (RoutineName = '') or (LineEnd < 0) then
          Continue;
        ReorderKey := UpperCase(ParentName) + '|' + IntToStr(LineHead);
        if ReorderDone.IndexOf(ReorderKey) >= 0 then
          Continue;
        ReorderDone.Add(ReorderKey);
        ParentAt := Names.IndexOf(ParentName);
        if ParentAt < 0 then
          Continue;
        ParentNode := TDfmNode(Names.Objects[ParentAt]);
        ReorderProblem := CheckReorder(ParentName, LineHead, LineEnd);
        for Other := 0 to AList.Count - 1 do
        begin
          Info := TMoveInfo(AList[Other]);
          Node := TDfmNode(Info.Node);
          if (Node.Parent <> ParentNode) or not Node.IsRuntime or
             (Info.CreateLine < LineHead) or (Info.CreateLine > LineEnd) then
            Continue;
          if ReorderProblem <> '' then
          begin
            if Info.Kind in [mkWhole, mkPartial] then
            begin
              ClearMoveData(Info);
              Info.Kind := mkNo;
              Info.Reason := ReorderProblem;
            end;
            Continue;
          end;
          Info.OrderGroup := LineHead;
          Info.OrderEnd := LineEnd;
          Info.OrderParent := ParentName;
          if Info.Kind in [mkWhole, mkPartial] then
            Info.Notes.Add(RoutineName + ' вынимает пункты ' + ParentName +
                           ' из .dfm и расставляет заново: в .dfm пишется ' +
                           'итоговый порядок, строки Remove/Add уходят. ' +
                           'Пункты, созданные там для ' + ParentName +
                           ', переносятся только все вместе.');
        end;
      end;
    finally
      ReorderDone.Free;
    end;

    // Родитель не переносится - и ребёнку некуда (до устойчивого состояния)
    for Pass := 1 to 10 do
    begin
      Changed := False;
      for Index := 0 to AList.Count - 1 do
      begin
        Info := TMoveInfo(AList[Index]);
        if not (Info.Kind in [mkWhole, mkPartial]) then
          Continue;
        Node := TDfmNode(Info.Node);
        if Node.Parent = nil then
          Continue;
        ParentInfo := nil;
        for Other := 0 to AList.Count - 1 do
          if TMoveInfo(AList[Other]).Node = Node.Parent then
          begin
            ParentInfo := TMoveInfo(AList[Other]);
            Break;
          end;
        if (ParentInfo <> nil) and (ParentInfo.Kind = mkNo) then
        begin
          Info.Kind := mkNo;
          Info.Reason := 'родитель ' + ParentInfo.Title +
                         ' не переносится';
          Changed := True;
        end;
      end;
      if not Changed then
        Break;
    end;

    // Пункты, которые остаются в коде (P.Add(X) у непереносимого X):
    // после загрузки формы они добавятся после пунктов из .dfm, и порядок
    // пунктов у P изменится. Строка остаётся у родителя с пометкой.
    for Index := 0 to AList.Count - 1 do
    begin
      Info := TMoveInfo(AList[Index]);
      if not (Info.Kind in [mkWhole, mkPartial]) then
        Continue;
      for Other := 0 to Info.ChildAdds.Count - 1 do
        if not ChildMoves(Info.ChildAdds[Other]) then
          Info.KeepLines.Add(LineRef(Lines,
            Integer(Info.ChildAdds.Objects[Other])) + '   [' +
            Info.ChildAdds[Other] + ' остаётся в коде - встанет после ' +
            'пунктов из .dfm, порядок изменится]');
    end;

    // Ссылки на компоненты (X.PopupMenu := Y): в .dfm - если Y уже там или
    // переносится сам, иначе строка остаётся в коде. Разбираются и у
    // компонентов «нет» - для подробностей «что ушло бы с родителем».
    for Index := 0 to AList.Count - 1 do
    begin
      Info := TMoveInfo(AList[Index]);
      for Other := 0 to Info.RefLines.Count - 1 do
      begin
        RefName := Info.RefLines[Other];
        RefLine := Integer(Info.RefLines.Objects[Other]);
        TargetInfo := FindInfo(RefName);
        if (TargetInfo <> nil) and (TargetInfo.Kind = mkInDfm) then
          Info.MoveLines.Add(LineRef(Lines, RefLine) + '   [ссылка на ' +
                             RefName + ' - он уже в .dfm]')
        else if (TargetInfo <> nil) and
                (TargetInfo.Kind in [mkWhole, mkPartial]) then
          Info.MoveLines.Add(LineRef(Lines, RefLine) + '   [ссылка на ' +
                             RefName + ' - он тоже переносится]')
        else
          Info.KeepLines.Add(LineRef(Lines, RefLine) + '   [ссылка на ' +
                             RefName + ' - его нет в .dfm]');
      end;
    end;

    // Создание по требованию: в блоке if X = nil не должно остаться строк
    // (ссылка на компонент, который не переносится, осталась бы в блоке,
    // а он после переноса не выполняется), и всё, что создаётся в блоке,
    // переносится вместе. Снятие одного снимает и детей - до устойчивого
    // состояния.
    for Pass := 1 to 20 do
    begin
      Changed := False;
      // Перестановка меню: пункты группы - только все вместе
      for Index := 0 to AList.Count - 1 do
      begin
        Info := TMoveInfo(AList[Index]);
        if (Info.OrderGroup < 0) or not (Info.Kind in [mkWhole, mkPartial]) then
          Continue;
        for Other := 0 to AList.Count - 1 do
        begin
          MateInfo := TMoveInfo(AList[Other]);
          if (MateInfo <> Info) and (MateInfo.OrderGroup = Info.OrderGroup) and
             (CompareText(MateInfo.OrderParent, Info.OrderParent) = 0) and
             not (MateInfo.Kind in [mkWhole, mkPartial]) then
          begin
            Info.Kind := mkNo;
            Info.Reason := Info.Routine + ' переставляет пункты ' +
                           Info.OrderParent + ' - они переносятся только все ' +
                           'вместе, а ' + MateInfo.Title + ' не переносится';
            Changed := True;
            Break;
          end;
        end;
      end;
      // Вызовы процедуры-создателя - только все вместе
      for Index := 0 to AList.Count - 1 do
      begin
        Info := TMoveInfo(AList[Index]);
        if (Info.HelperGroup < 0) or not (Info.Kind in [mkWhole, mkPartial]) then
          Continue;
        for Other := 0 to AList.Count - 1 do
        begin
          MateInfo := TMoveInfo(AList[Other]);
          if (MateInfo <> Info) and (MateInfo.HelperGroup = Info.HelperGroup) and
             not (MateInfo.Kind in [mkWhole, mkPartial]) then
          begin
            ClearMoveData(Info);
            Info.Kind := mkNo;
            Info.Reason := 'вместе с ним (' + Info.HelperName + ') ' +
                           'создаётся ' + MateInfo.Title + ', а он не ' +
                           'переносится - они переносятся только все вместе';
            Changed := True;
            Break;
          end;
        end;
      end;
      for Index := 0 to AList.Count - 1 do
      begin
        Info := TMoveInfo(AList[Index]);
        if (Info.LazyGroup < 0) or not (Info.Kind in [mkWhole, mkPartial]) then
          Continue;
        if Info.KeepLines.Count > 0 then
        begin
          Info.Kind := mkNo;
          Info.Reason := 'создаётся по требованию (строка ' +
                         IntToStr(Info.LazyGroup + 1) + '), а в блоке ' +
                         'осталась бы строка ' + Info.KeepLines[0] +
                         ' - после переноса блок не выполняется';
          Changed := True;
          Continue;
        end;
        for Other := 0 to AList.Count - 1 do
        begin
          MateInfo := TMoveInfo(AList[Other]);
          if (MateInfo <> Info) and (MateInfo.LazyGroup = Info.LazyGroup) and
             not (MateInfo.Kind in [mkWhole, mkPartial]) then
          begin
            Info.Kind := mkNo;
            Info.Reason := 'создаётся по требованию вместе с ' +
                           MateInfo.Title + ' (строка ' +
                           IntToStr(Info.LazyGroup + 1) + '), а он не ' +
                           'переносится';
            Changed := True;
            Break;
          end;
        end;
      end;
      for Index := 0 to AList.Count - 1 do
      begin
        Info := TMoveInfo(AList[Index]);
        if not (Info.Kind in [mkWhole, mkPartial]) then
          Continue;
        Node := TDfmNode(Info.Node);
        if Node.Parent = nil then
          Continue;
        for Other := 0 to AList.Count - 1 do
          if (TMoveInfo(AList[Other]).Node = Node.Parent) and
             (TMoveInfo(AList[Other]).Kind = mkNo) then
          begin
            Info.Kind := mkNo;
            Info.Reason := 'родитель ' + TMoveInfo(AList[Other]).Title +
                           ' не переносится';
            Changed := True;
            Break;
          end;
      end;
      if not Changed then
        Break;
    end;

    // Итог: строки по порядку в модуле, вердикт по оставшимся строкам
    for Index := 0 to AList.Count - 1 do
    begin
      Info := TMoveInfo(AList[Index]);
      Info.MoveLines.CustomSort(CompareLineRefs);
      Info.KeepLines.CustomSort(CompareLineRefs);
      if not (Info.Kind in [mkWhole, mkPartial]) then
        Continue;
      if Info.KeepLines.Count > 0 then
      begin
        Info.Kind := mkPartial;
        Info.Reason := 'останется строк: ' + IntToStr(Info.KeepLines.Count);
      end
      else
      begin
        Info.Kind := mkWhole;
        Info.Reason := '';
      end;
    end;

    // Проверки на nil, которые могут выполниться до прежнего создания.
    // Обработчики событий загрузки - из дерева (.dfm и код) и из
    // назначений в коде.
    for Index := 0 to ATree.Items.Count - 1 do
      if ATree.Items[Index].Data <> nil then
      begin
        Node := TDfmNode(ATree.Items[Index].Data);
        for Other := 0 to Node.EvN.Count - 1 do
          if (Other < Node.EvV.Count) and
             IsInitEventOf(Node.ClassNm, Node.EvN[Other]) and
             not Node.FromCode then
            InitHandlers.AddObject(Node.EvV[Other], TObject(-1));
      end;
    CollectFormRoutines(Lines, AFormClass, Routines, RoutineNames,
                        InitHandlers, Names);
    for Index := 0 to AList.Count - 1 do
    begin
      Info := TMoveInfo(AList[Index]);
      if not (Info.Kind in [mkWhole, mkPartial]) then
        Continue;
      FindNilRisks(Info, Lines, Routines, RoutineNames, InitHandlers);
      if Info.NilRisk.Count = 0 then
        Continue;
      RefName := '';
      for Other := 0 to Info.NilRisk.Count - 1 do
      begin
        if RefName <> '' then
          RefName := RefName + ', ';
        RefName := RefName + IntToStr(LineOfRef(Info.NilRisk[Other]) + 1);
      end;
      if Info.Reason <> '' then
        Info.Reason := Info.Reason + '; ';
      if Info.NilRisk.Count = 1 then
        Info.Reason := Info.Reason + 'проверить: проверка на nil до ' +
                       'создания (строка ' + RefName + ')'
      else
        Info.Reason := Info.Reason + 'проверить: проверка на nil до ' +
                       'создания (строки ' + RefName + ')';
      Info.Notes.Add('Проверки на nil, которые могут выполниться, пока ' +
                     Info.Title + ' ещё не был создан (там nil значил ' +
                     '«ещё не создан»; после переноса он есть с загрузки ' +
                     'формы, и код за проверкой пойдёт дальше). ' +
                     '«Отметить всё возможное» его не отмечает:');
      Info.Notes.AddStrings(Info.NilRisk);
    end;

    // Окно разбора немодальное и живёт дольше дерева объектов: дальше
    // разбор держит только свои копии узлов
    DetachFromTree(AList);

    // Переменная, которой создают несколько компонентов: каждому - своё
    // имя (родитель + переменная + номер, FObjPagesSheet1), дети - к нему.
    // Имя меняется у копии узла: дерево объектов его не видит.
    for Index := 0 to AList.Count - 1 do
    begin
      Info := TMoveInfo(AList[Index]);
      if not Info.ReusedLocal then
        Continue;
      Info.LocalDecl := -1;     // переменная остаётся
      Node := TDfmNode(Info.Node);
      RefName := NewComponentName(Info.NestParent, 'T' + Info.CodeName);
      for Other := 0 to AList.Count - 1 do
      begin
        MateInfo := TMoveInfo(AList[Other]);
        if (TDfmNode(MateInfo.Node).Parent = Node) and
           (CompareText(MateInfo.NestParent, Info.CodeName) = 0) then
        begin
          // Вызов без переменной получил имя по переменной (GrpItem1) -
          // теперь по полю родителя (FDsgMenuGrp1Item1)
          if MateInfo.NewField and (MateInfo.UnrollArgs = nil) and
             (CompareText(Copy(TDfmNode(MateInfo.Node).VarName, 1,
                               Length(Info.CodeName)), Info.CodeName) = 0) then
          begin
            if NewNames.IndexOf(TDfmNode(MateInfo.Node).VarName) >= 0 then
              NewNames.Delete(NewNames.IndexOf(TDfmNode(MateInfo.Node).VarName));
            TDfmNode(MateInfo.Node).VarName :=
              NewComponentName(RefName, TDfmNode(MateInfo.Node).ClassNm);
            MateInfo.Title := TDfmNode(MateInfo.Node).VarName + ': ' +
                              TDfmNode(MateInfo.Node).ClassNm;
            for InsertAt := 0 to MateInfo.Notes.Count - 1 do
              if Pos('Вызов без переменной', MateInfo.Notes[InsertAt]) = 1 then
                MateInfo.Notes[InsertAt] := 'Вызов без переменной: при ' +
                  'переносе объект получит имя ' +
                  TDfmNode(MateInfo.Node).VarName + ' и published-поле.';
          end;
          MateInfo.NestParent := RefName;
          for InsertAt := 0 to MateInfo.Items.Count - 1 do
            if (TMoveLine(MateInfo.Items[InsertAt]).Kind = mlNesting) and
               (CompareText(TMoveLine(MateInfo.Items[InsertAt]).Value,
                            Info.CodeName) = 0) then
              TMoveLine(MateInfo.Items[InsertAt]).Value := RefName;
        end;
      end;
      Node.VarName := RefName;
      Info.Title := RefName + ': ' + Node.ClassNm + ' (в коде - ' +
                    Info.CodeName + ')';
      // В блоке по требованию уходят все строки - замена не нужна
      if Info.LazyGroup >= 0 then
        Info.Notes.Add('В .dfm - ' + RefName + '; строка создания уходит ' +
                       'вместе с блоком по требованию.')
      else
      begin
        Info.ReplaceText := Info.CodeName + ' := ' + RefName + ';';
        Info.Notes.Add('В .dfm - ' + RefName + ', строка ' +
                       IntToStr(Info.CreateLine + 1) + ' станет «' +
                       Info.CodeName + ' := ' + RefName + ';».');
      end;
    end;
  finally
    for Index := 0 to Routines.Count - 1 do
      TObject(Routines[Index]).Free;
    Routines.Free;
    RoutineNames.Free;
    InitHandlers.Free;
    Scan.Free;
    FreeHelpers(Helpers);
    GDfmIntValues.Free;
    GDfmIntValues := nil;
    NewNames.Free;
    CallArgs.Free;
    Names.Free;
    Keys.Free;
    Lines.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  Перенос
// ---------------------------------------------------------------------------

// Разбор компонента по имени (переменной или имени в .dfm); nil - нет
function FindInfoByName(AList: TList; const AName: string): TMoveInfo;
var
  Index: Integer;
  Item: TMoveInfo;
begin
  Result := nil;
  if AName = '' then
    Exit;
  for Index := 0 to AList.Count - 1 do
  begin
    Item := TMoveInfo(AList[Index]);
    if (CompareText(TDfmNode(Item.Node).VarName, AName) = 0) or
       (CompareText(TDfmNode(Item.Node).Name, AName) = 0) then
    begin
      Result := Item;
      Exit;
    end;
  end;
end;

// Имя компонента в .dfm: у лежащего там - его имя, у переносимого - имя
// поля (по нему форма при загрузке заполняет поле)
function DfmNameOf(Info: TMoveInfo): string;
begin
  if (Info.Kind = mkInDfm) and (TDfmNode(Info.Node).Name <> '') then
    Result := TDfmNode(Info.Node).Name
  else
    Result := TDfmNode(Info.Node).VarName;
end;

// Имя корня формы из первой строки .dfm: object Form1: TForm1 -> Form1
function DfmRootName(const AText: string): string;
var
  Lines: TStringList;
  Index, Colon, Space: Integer;
  Head: string;
begin
  Result := '';
  Lines := TStringList.Create;
  try
    Lines.Text := AText;
    for Index := 0 to Lines.Count - 1 do
    begin
      Head := Trim(Lines[Index]);
      if Head = '' then
        Continue;
      Space := Pos(' ', Head);
      Colon := Pos(':', Head);
      if (Space > 0) and (Colon > Space) then
        Result := Trim(Copy(Head, Space + 1, Colon - Space - 1));
      Exit;
    end;
  finally
    Lines.Free;
  end;
end;

// Объект с таким именем есть в тексте .dfm
function DfmHasObject(const AText, AName: string): Boolean;
var
  First, Last: Integer;
begin
  Result := (AName <> '') and DfmObjectRange(AText, AName, First, Last);
end;

// Контрол или пункт меню - у него важен порядок среди соседей. Отдельные
// окна (TForm), невизуальные и классы, не известные IDE (свои служебные
// вроде TUiGlyph, которые в списки контролов и пунктов не входят), - нет.
function OrderMatters(Info: TMoveInfo): Boolean;
var
  NodeClass: TPersistentClass;
begin
  Result := False;
  if IsFormClass(TDfmNode(Info.Node).ClassNm) then
    Exit;
  NodeClass := GetClass(TDfmNode(Info.Node).ClassNm);
  Result := (NodeClass <> nil) and (NodeClass.InheritsFrom(TControl) or
            NodeClass.InheritsFrom(TMenuItem));
end;

// Сосед (тот же родитель в дереве), который создаётся кодом раньше
// компонента AIndex и остаётся в коде: после переноса он встанет уже после
// перенесённого - порядок пунктов меню или выравнивание изменятся. nil -
// такого нет. «Раньше» - по строке создания в модуле; у соседа без
// известной строки создания (пункты, которые код добавляет потом, при
// перестройке меню) порядок не известен - он не учитывается. У самого
// компонента строки нет - по порядку дерева объектов.
function StaysBefore(AList: TList; AIndex: Integer): TMoveInfo;
var
  Index: Integer;
  Info, Other: TMoveInfo;
  Earlier: Boolean;
begin
  Result := nil;
  Info := TMoveInfo(AList[AIndex]);
  if not OrderMatters(Info) then
    Exit;
  for Index := 0 to AList.Count - 1 do
  begin
    if Index = AIndex then
      Continue;
    Other := TMoveInfo(AList[Index]);
    if (TDfmNode(Other.Node).Parent <> TDfmNode(Info.Node).Parent) or
       Other.Selected or (Other.Kind = mkInDfm) or not OrderMatters(Other) then
      Continue;
    if Info.CreateLine >= 0 then
      Earlier := (Other.CreateLine >= 0) and
                 (Other.CreateLine < Info.CreateLine)
    else
      Earlier := Index < AIndex;
    if Earlier then
    begin
      Result := Other;
      Exit;
    end;
  end;
end;

// Невизуальный компонент формы (таймер, меню, диалог): в конструкторе он -
// значок на месте Left/Top из .dfm. Пункты меню значков не имеют, классы,
// не известные IDE, не угадываются.
function IsIconClass(const AClassName: string): Boolean;
var
  NodeClass: TPersistentClass;
begin
  NodeClass := GetClass(AClassName);
  Result := (NodeClass <> nil) and not NodeClass.InheritsFrom(TControl) and
            not NodeClass.InheritsFrom(TMenuItem);
end;

// Места значков, которые уже есть в .dfm: Left и Top невизуальных
// компонентов формы (детей корня), строками «Left,Top»
procedure CollectIconPlaces(const ADfmText: string; APlaces: TStrings);
var
  Lines: TStringList;
  Index, Colon, IconLeft, IconTop: Integer;
  Text, ClassText: string;
  InIcon: Boolean;
begin
  Lines := TStringList.Create;
  try
    Lines.Text := ADfmText;
    InIcon := False;
    IconLeft := -1;
    IconTop := -1;
    for Index := 0 to Lines.Count - 1 do
    begin
      Text := Lines[Index];
      if LeadSpacesOf(Text) = 2 then
      begin
        Text := Trim(Text);
        if (Copy(Text, 1, 7) = 'object ') or
           (Copy(Text, 1, 10) = 'inherited ') then
        begin
          Colon := Pos(':', Text);
          ClassText := Trim(Copy(Text, Colon + 1, MaxInt));
          InIcon := (Colon > 0) and IsIconClass(ClassText);
          IconLeft := -1;
          IconTop := -1;
        end
        else if (Text = 'end') and InIcon then
        begin
          if (IconLeft >= 0) and (IconTop >= 0) then
            APlaces.Add(IntToStr(IconLeft) + ',' + IntToStr(IconTop));
          InIcon := False;
        end;
      end
      else if InIcon and (LeadSpacesOf(Text) = 4) then
      begin
        Text := Trim(Text);
        if Copy(Text, 1, 7) = 'Left = ' then
          IconLeft := StrToIntDef(Copy(Text, 8, MaxInt), -1)
        else if Copy(Text, 1, 6) = 'Top = ' then
          IconTop := StrToIntDef(Copy(Text, 7, MaxInt), -1);
      end;
    end;
  finally
    Lines.Free;
  end;
end;

// Свободное место для нового значка: по сетке с шагом 40 от 16,16, не
// ближе 32 точек к занятым. Место сразу записывается в занятые.
procedure NextIconPlace(APlaces: TStrings; var ALeft, ATop: Integer);
var
  Index, Comma, PlaceLeft, PlaceTop: Integer;
  Busy: Boolean;
begin
  ATop := 16;
  repeat
    ALeft := 16;
    while ALeft <= 616 do
    begin
      Busy := False;
      for Index := 0 to APlaces.Count - 1 do
      begin
        Comma := Pos(',', APlaces[Index]);
        PlaceLeft := StrToIntDef(Copy(APlaces[Index], 1, Comma - 1), 0);
        PlaceTop := StrToIntDef(Copy(APlaces[Index], Comma + 1, MaxInt), 0);
        if (Abs(PlaceLeft - ALeft) < 32) and (Abs(PlaceTop - ATop) < 32) then
        begin
          Busy := True;
          Break;
        end;
      end;
      if not Busy then
      begin
        APlaces.Add(IntToStr(ALeft) + ',' + IntToStr(ATop));
        Exit;
      end;
      Inc(ALeft, 40);
    end;
    Inc(ATop, 40);
  until False;
end;

// Создание по требованию: чего не хватает, чтобы перенести Info вместе с
// его блоком if X = nil. '' - всё в порядке (или Info не по требованию):
// отмечены все, кто создаётся в том же блоке, и ссылки из блока ведут на
// компоненты из .dfm или отмеченные (строка, оставшаяся в блоке, после
// переноса не выполнится).
function LazyMissing(AList: TList; Info: TMoveInfo): string;
var
  Index: Integer;
  Mate, Target: TMoveInfo;
  Item: TMoveLine;
begin
  Result := '';
  // Вызовы процедуры-создателя: все отмечены
  if Info.HelperGroup >= 0 then
    for Index := 0 to AList.Count - 1 do
    begin
      Mate := TMoveInfo(AList[Index]);
      if (Mate <> Info) and (Mate.HelperGroup = Info.HelperGroup) and
         not Mate.Selected then
      begin
        Result := 'строки ' + Info.HelperName + ' уходят сразу для всех, ' +
                  'а ' + Mate.Title + ' не отмечен';
        Exit;
      end;
    end;
  // Перестановка меню: все пункты группы отмечены
  if Info.OrderGroup >= 0 then
    for Index := 0 to AList.Count - 1 do
    begin
      Mate := TMoveInfo(AList[Index]);
      if (Mate <> Info) and (Mate.OrderGroup = Info.OrderGroup) and
         (CompareText(Mate.OrderParent, Info.OrderParent) = 0) and
         not Mate.Selected then
      begin
        Result := Info.Routine + ' переставляет пункты ' + Info.OrderParent +
                  ' - они переносятся только все вместе, а ' + Mate.Title +
                  ' не отмечен';
        Exit;
      end;
    end;
  if Info.LazyGroup < 0 then
    Exit;
  for Index := 0 to AList.Count - 1 do
  begin
    Mate := TMoveInfo(AList[Index]);
    if (Mate <> Info) and (Mate.LazyGroup = Info.LazyGroup) and
       not Mate.Selected then
    begin
      Result := 'в том же блоке (строка ' + IntToStr(Info.LazyGroup + 1) +
                ') создаётся ' + Mate.Title + ', он не отмечен';
      Exit;
    end;
  end;
  for Index := 0 to Info.Items.Count - 1 do
  begin
    Item := TMoveLine(Info.Items[Index]);
    if Item.Kind <> mlRef then
      Continue;
    Target := FindInfoByName(AList, Item.Value);
    if (Target = nil) or not ((Target.Kind = mkInDfm) or
       (Target.Selected and (Target.Kind in [mkWhole, mkPartial]))) then
    begin
      Result := 'ссылка ' + Item.PropName + ' := ' + Item.Value +
                ' (строка ' + IntToStr(Item.LineIndex + 1) + ') осталась ' +
                'бы в блоке по требованию - ' + Item.Value + ' не переносится';
      Exit;
    end;
  end;
end;

// Отметки для переноса: всё «целиком» (AWithPartial - и «частично»), у
// чьих родителей тоже отметка или они в .dfm, и перед кем среди соседей не
// остаётся в коде контрол или пункт меню (иначе порядок изменится).
// Созданные в одном блоке по требованию - только все вместе.
procedure SelectPossible(AList: TList; AWithPartial: Boolean);
var
  Index: Integer;
  Info, UpInfo: TMoveInfo;
  Changed: Boolean;
begin
  for Index := 0 to AList.Count - 1 do
  begin
    Info := TMoveInfo(AList[Index]);
    Info.Selected := ((Info.Kind = mkWhole) or
                      (AWithPartial and (Info.Kind = mkPartial))) and
                     (Info.NilRisk.Count = 0);
  end;
  repeat
    Changed := False;
    for Index := 0 to AList.Count - 1 do
    begin
      Info := TMoveInfo(AList[Index]);
      if not Info.Selected then
        Continue;
      UpInfo := FindInfoByName(AList, Info.NestParent);
      if ((UpInfo <> nil) and (UpInfo.Kind <> mkInDfm) and
          not UpInfo.Selected) or (StaysBefore(AList, Index) <> nil) or
         (LazyMissing(AList, Info) <> '') then
      begin
        Info.Selected := False;
        Changed := True;
      end;
    end;
  until not Changed;
end;

// Порядок переноса - по строкам вложенности: это порядок создания, а
// значит, и порядок пунктов меню, и Z-порядок контролов
function CompareNestLine(Item1, Item2: Pointer): Integer;
begin
  Result := TMoveInfo(Item1).NestLine - TMoveInfo(Item2).NestLine;
  // Проходы развёрнутого цикла - одна строка, порядок - по проходам
  if Result = 0 then
    Result := TMoveInfo(Item1).NestOrder - TMoveInfo(Item2).NestOrder;
end;

// Текст из строк с тем же концом, что у исходного: был без перевода строки
// в конце - и остаётся без него
function TextLikeOrig(ALines: TStrings; const AOrig: string): string;
begin
  Result := ALines.Text;
  if (AOrig = '') or not (AOrig[Length(AOrig)] in [#13, #10]) then
    while (Result <> '') and (Result[Length(Result)] in [#13, #10]) do
      SetLength(Result, Length(Result) - 1);
end;

// Слово видимости: с него начинается новая секция класса
function IsSectionWord(const AWord: string): Boolean;
begin
  Result := (AWord = 'PRIVATE') or (AWord = 'PROTECTED') or
            (AWord = 'PUBLIC') or (AWord = 'PUBLISHED') or
            (AWord = 'STRICT');
end;

// Строка ALine класса (заголовок - AFirst) лежит в published-части: в
// первой секции (до первого слова видимости) или после published
function IsPublishedLine(ALines: TStrings; AFirst, ALine: Integer): Boolean;
var
  Index: Integer;
  Word, Section: string;
begin
  Section := '';
  for Index := AFirst + 1 to ALine do
  begin
    Word := FirstWordOf(ALines[Index]);
    if IsSectionWord(Word) then
      Section := Word;
  end;
  Result := (Section = '') or (Section = 'PUBLISHED');
end;

// Строка объявления поля AName в классе (AFirst..ALast): "A, B: TТип;" и,
// может быть, комментарий //. ANames - все имена этой строки, AType - тип,
// ATail - комментарий. -1 - не нашлось.
function FindFieldDecl(ALines: TStrings; AFirst, ALast: Integer;
  const AName: string; ANames: TStrings; var AType, ATail: string): Integer;
var
  Index: Integer;
begin
  Result := -1;
  for Index := AFirst + 1 to ALast - 1 do
    if ParseFieldLine(ALines[Index], ANames, AType, ATail) and
       (ANames.IndexOf(AName) >= 0) then
    begin
      Result := Index;
      Exit;
    end;
end;

// Объявление метода AName в классе: первая и последняя строки (заголовок
// бывает на нескольких строках). False - не нашлось.
function FindMethodDecl(ALines: TStrings; AFirst, ALast: Integer;
  const AName: string; var AStart, AStop: Integer): Boolean;
var
  Index, Stop, CharIndex, Depth, NameEnd: Integer;
  Code, Word, Rest: string;
begin
  Result := False;
  for Index := AFirst + 1 to ALast - 1 do
  begin
    Code := Trim(StripComment(ALines[Index]));
    Word := FirstWordOf(Code);
    if (Word <> 'PROCEDURE') and (Word <> 'FUNCTION') then
      Continue;
    Rest := Trim(Copy(Code, Length(Word) + 1, MaxInt));
    NameEnd := 1;
    while (NameEnd <= Length(Rest)) and IsIdentChar(Rest[NameEnd]) do
      Inc(NameEnd);
    if CompareText(Copy(Rest, 1, NameEnd - 1), AName) <> 0 then
      Continue;
    Depth := 0;
    for Stop := Index to ALast - 1 do
    begin
      Code := TrimRight(StripComment(ALines[Stop]));
      for CharIndex := 1 to Length(Code) do
        if Code[CharIndex] = '(' then
          Inc(Depth)
        else if Code[CharIndex] = ')' then
          Dec(Depth);
      if (Depth <= 0) and (Code <> '') and (Code[Length(Code)] = ';') then
      begin
        AStart := Index;
        AStop := Stop;
        Result := True;
        Exit;
      end;
    end;
    Exit;
  end;
end;

// Поля перенесённых компонентов и их обработчики - в published-часть
// класса формы. Тип поля - класс из .dfm: при загрузке форма ищет класс
// объекта среди типов своих published-полей (TStatusBar у поля не даст
// найти TUiStatusBar из .dfm).
procedure PublishInClass(ALines: TStrings; const AFormClass: string;
  AOrder: TList; AHandlers, AReport: TStrings;
  var AFieldCount, AMethodCount: Integer);
var
  First, Last, Index, Line, Start, Stop, Insert, Indent, Rest: Integer;
  Names, AddFields, AddMethods: TStringList;
  Info: TMoveInfo;
  FieldName, FieldType, NewType, Tail, Word, Pad, Joined: string;
begin
  AFieldCount := 0;
  AMethodCount := 0;
  Names := TStringList.Create;
  AddFields := TStringList.Create;
  AddMethods := TStringList.Create;
  try
    // Поля
    for Index := 0 to AOrder.Count - 1 do
    begin
      Info := TMoveInfo(AOrder[Index]);
      FieldName := TDfmNode(Info.Node).VarName;
      NewType := TDfmNode(Info.Node).ClassNm;
      // Вызов помощника без переменной: поля ещё нет
      if Info.NewField then
      begin
        AddFields.Add(FieldName + ': ' + NewType + ';');
        AReport.Add('Поле ' + FieldName + ': ' + NewType + ' добавлено ' +
                    '(создаётся без переменной, строка ' +
                    IntToStr(Info.CreateLine + 1) + ').');
        Inc(AFieldCount);
        Continue;
      end;
      // Была локальной переменной: поля тоже нет, объявление в var уже
      // убрано (у переменной, которой создают несколько компонентов, - не
      // убирается, поле у компонента своё)
      if Info.ReusedLocal then
      begin
        AddFields.Add(FieldName + ': ' + NewType + ';');
        if Info.ReplaceText <> '' then
          AReport.Add('Поле ' + FieldName + ': ' + NewType + ' добавлено; ' +
                      'строка ' + IntToStr(Info.CreateLine + 1) + ' теперь ' +
                      Info.CodeName + ' := ' + FieldName + ';')
        else
          AReport.Add('Поле ' + FieldName + ': ' + NewType + ' добавлено ' +
                      '(в коде - ' + Info.CodeName + ', строка ' +
                      IntToStr(Info.CreateLine + 1) + ' уходит вместе с ' +
                      'блоком).');
        Inc(AFieldCount);
        Continue;
      end;
      if Info.LocalDecl >= 0 then
      begin
        AddFields.Add(FieldName + ': ' + NewType + ';');
        AReport.Add('Поле ' + FieldName + ': ' + NewType + ' добавлено ' +
                    '(была локальная переменная ' + Info.Routine + ').');
        Inc(AFieldCount);
        Continue;
      end;
      FindClassDecl(ALines, AFormClass, First, Last);
      if (First < 0) or (Last < 0) then
      begin
        AReport.Add('Объявление класса ' + AFormClass + ' не найдено - ' +
                    'поля и обработчики объявить в published вручную.');
        Exit;
      end;
      Line := FindFieldDecl(ALines, First, Last, FieldName, Names, FieldType,
                            Tail);
      if Line < 0 then
      begin
        AReport.Add('Поле ' + FieldName + ' в классе не найдено - объявить ' +
                    'в published вручную: ' + FieldName + ': ' + NewType + ';');
        Continue;
      end;
      if IsPublishedLine(ALines, First, Line) and
         (CompareText(FieldType, NewType) = 0) then
        Continue;
      if CompareText(FieldType, NewType) <> 0 then
        AReport.Add('Поле ' + FieldName + ': тип ' + FieldType + ' заменён ' +
                    'на ' + NewType + ' - класс объекта из .dfm должен быть ' +
                    'типом published-поля.');
      // Имя - из своей строки: одно имя - строка уходит целиком (с
      // комментарием), несколько - остаются прочие
      Pad := StringOfChar(' ', LeadSpacesOf(ALines[Line]));
      if Names.Count = 1 then
      begin
        ALines.Delete(Line);
        if Tail <> '' then
          AddFields.Add(FieldName + ': ' + NewType + '; ' + Tail)
        else
          AddFields.Add(FieldName + ': ' + NewType + ';');
      end
      else
      begin
        Names.Delete(Names.IndexOf(FieldName));
        Joined := Names[0];
        for Rest := 1 to Names.Count - 1 do
          Joined := Joined + ', ' + Names[Rest];
        Joined := Pad + Joined + ': ' + FieldType + ';';
        if Tail <> '' then
          Joined := Joined + ' ' + Tail;
        ALines[Line] := Joined;
        AddFields.Add(FieldName + ': ' + NewType + ';');
      end;
      Inc(AFieldCount);
    end;

    // Обработчики событий
    for Index := 0 to AHandlers.Count - 1 do
    begin
      FindClassDecl(ALines, AFormClass, First, Last);
      if (First < 0) or (Last < 0) then
        Break;
      if not FindMethodDecl(ALines, First, Last, AHandlers[Index], Start,
                            Stop) then
      begin
        AReport.Add('Обработчик ' + AHandlers[Index] + ': объявление в ' +
                    'классе не найдено - проверить вручную.');
        Continue;
      end;
      if IsPublishedLine(ALines, First, Start) then
        Continue;
      for Line := Start to Stop do
        if Line = Start then
          AddMethods.Add(Trim(ALines[Line]))
        else
          AddMethods.Add('  ' + Trim(ALines[Line]));
      for Line := Stop downto Start do
        ALines.Delete(Line);
      Inc(AMethodCount);
    end;

    FindClassDecl(ALines, AFormClass, First, Last);
    if (First < 0) or (Last < 0) then
      Exit;
    // Отступ - как у первой строки первой секции
    Indent := LeadSpacesOf(ALines[First]) + 2;
    for Line := First + 1 to Last - 1 do
      if Trim(ALines[Line]) <> '' then
      begin
        Indent := LeadSpacesOf(ALines[Line]);
        Break;
      end;
    Pad := StringOfChar(' ', Indent);

    // Поля - после полей первой секции, перед её методами
    if AddFields.Count > 0 then
    begin
      Insert := Last;
      for Line := First + 1 to Last do
      begin
        Word := FirstWordOf(ALines[Line]);
        if (Word = 'PROCEDURE') or (Word = 'FUNCTION') or
           (Word = 'CONSTRUCTOR') or (Word = 'DESTRUCTOR') or
           (Word = 'PROPERTY') or (Word = 'CLASS') or (Word = 'END') or
           IsSectionWord(Word) then
        begin
          Insert := Line;
          Break;
        end;
      end;
      while (Insert - 1 > First) and (Trim(ALines[Insert - 1]) = '') do
        Dec(Insert);
      for Line := AddFields.Count - 1 downto 0 do
        ALines.Insert(Insert, Pad + AddFields[Line]);
    end;

    // Методы - в конец первой секции
    if AddMethods.Count > 0 then
    begin
      FindClassDecl(ALines, AFormClass, First, Last);
      Insert := Last;
      for Line := First + 1 to Last do
      begin
        Word := FirstWordOf(ALines[Line]);
        if (Word = 'END') or IsSectionWord(Word) then
        begin
          Insert := Line;
          Break;
        end;
      end;
      while (Insert - 1 > First) and (Trim(ALines[Insert - 1]) = '') do
        Dec(Insert);
      for Line := AddMethods.Count - 1 downto 0 do
        ALines.Insert(Insert, Pad + AddMethods[Line]);
    end;
  finally
    AddMethods.Free;
    AddFields.Free;
    Names.Free;
  end;
end;

function DfmMoveApply(AList: TList; const APasText, ADfmText,
  AFormClass: string; ADeleteLines: Boolean; var ANewPas, ANewDfm: string;
  AReport: TStrings): Integer;
var
  Lines, ObjText, Handlers, Receivers, Summary, IconPlaces: TStringList;
  Remove: array of Boolean;
  Replace: array of string;
  Order: TList;
  Index, LineIndex, LineCount, FieldCount, MethodCount: Integer;
  Info, ParentInfo: TMoveInfo;
  ParentNode: TDfmNode;
  Changed, ParentOk: Boolean;
  RootName, Dfm, Before, ParentName, DeclType, DeclTail, DeclText,
    ReorderKey: string;
  DeclNames, Reorders: TStringList;

  // Имя родителя в .dfm: форма, объект .dfm или переносимый компонент
  function ParentDfmName(AInfo: TMoveInfo): string;
  var
    UpInfo: TMoveInfo;
  begin
    if AInfo.NestParent = '' then
      Result := RootName
    else
    begin
      UpInfo := FindInfoByName(AList, AInfo.NestParent);
      if UpInfo <> nil then
        Result := DfmNameOf(UpInfo)
      else
        Result := AInfo.NestParent;
    end;
  end;

  // Родитель тоже переносится: компонент ляжет в его блок
  function ParentMoves(AInfo: TMoveInfo): Boolean;
  var
    UpInfo: TMoveInfo;
  begin
    UpInfo := FindInfoByName(AList, AInfo.NestParent);
    Result := (UpInfo <> nil) and UpInfo.Selected and (UpInfo.Kind <> mkInDfm);
  end;

  // Блок object ... end компонента и его переносимых детей (с отступом
  // AIndent); строки кода, ушедшие в него, - в Remove
  procedure BuildObject(AInfo: TMoveInfo; AIndent: Integer);
  var
    Pad: string;
    ItemIndex, IconLeft, IconTop, ColumnLine: Integer;
    HasPlace: Boolean;
    Item: TMoveLine;
    Target, Child: TMoveInfo;
    ColumnLines: TStringList;
  begin
    Pad := StringOfChar(' ', AIndent);
    ColumnLines := TStringList.Create;
    try
    ObjText.Add(Pad + 'object ' + TDfmNode(AInfo.Node).VarName + ': ' +
                TDfmNode(AInfo.Node).ClassNm);
    // Невизуальный в корне формы: место значка в конструкторе, иначе все
    // такие значки легли бы в 0,0 друг на друга
    if (AIndent = 0) and (AInfo.NestParent = '') and
       IsIconClass(TDfmNode(AInfo.Node).ClassNm) then
    begin
      HasPlace := False;
      for ItemIndex := 0 to AInfo.Items.Count - 1 do
        if (CompareText(TMoveLine(AInfo.Items[ItemIndex]).PropName,
                        'Left') = 0) or
           (CompareText(TMoveLine(AInfo.Items[ItemIndex]).PropName,
                        'Top') = 0) then
          HasPlace := True;
      if not HasPlace then
      begin
        NextIconPlace(IconPlaces, IconLeft, IconTop);
        ObjText.Add(Pad + '  Left = ' + IntToStr(IconLeft));
        ObjText.Add(Pad + '  Top = ' + IntToStr(IconTop));
      end;
    end;
    for ItemIndex := 0 to AInfo.Items.Count - 1 do
    begin
      Item := TMoveLine(AInfo.Items[ItemIndex]);
      case Item.Kind of
        mlCreate, mlNesting:
          Remove[Item.LineIndex] := True;
        mlProp:
          begin
            ObjText.Add(Pad + '  ' + Item.PropName + ' = ' + Item.Value);
            Remove[Item.LineIndex] := True;
          end;
        mlColumns:
          begin
            // Columns = <
            //   item
            //     Caption = 'Name'
            //   end>
            ColumnLines.Text := StringReplace(Item.Value, #10, #13#10,
                                              [rfReplaceAll]);
            ObjText.Add(Pad + '  ' + Item.PropName + ' = <');
            ObjText.Add(Pad + '    item');
            for ColumnLine := 0 to ColumnLines.Count - 1 do
              if ColumnLines[ColumnLine] = '-' then
              begin
                ObjText.Add(Pad + '    end');
                ObjText.Add(Pad + '    item');
              end
              else
                ObjText.Add(Pad + '      ' + ColumnLines[ColumnLine]);
            ObjText.Add(Pad + '    end>');
            Remove[Item.LineIndex] := True;
          end;
        mlEvent:
          begin
            ObjText.Add(Pad + '  ' + Item.PropName + ' = ' + Item.Value);
            Remove[Item.LineIndex] := True;
            if Handlers.IndexOf(Item.Value) < 0 then
              Handlers.Add(Item.Value);
          end;
        mlRef:
          begin
            Target := FindInfoByName(AList, Item.Value);
            if (Target <> nil) and
               ((Target.Kind = mkInDfm) or
                (Target.Selected and (Target.Kind in [mkWhole, mkPartial]))) then
            begin
              ObjText.Add(Pad + '  ' + Item.PropName + ' = ' +
                          DfmNameOf(Target));
              Remove[Item.LineIndex] := True;
            end
            else
              AReport.Add(AInfo.Title + ': строка ' +
                          IntToStr(Item.LineIndex + 1) + ' (' + Item.PropName +
                          ' := ' + Item.Value + ') остаётся в коде - ' +
                          Item.Value + ' не переносится.');
          end;
      end;
    end;
    // Дети - в порядке строк вложенности (Order уже упорядочен)
    for ItemIndex := 0 to Order.Count - 1 do
    begin
      Child := TMoveInfo(Order[ItemIndex]);
      if (Child <> AInfo) and (Child.NestParent <> '') and
         (FindInfoByName(AList, Child.NestParent) = AInfo) then
        BuildObject(Child, AIndent + 2);
    end;
    ObjText.Add(Pad + 'end');
    finally
      ColumnLines.Free;
    end;
  end;

  // Меню AParent из .dfm, пункты которого процедура (строки AHead..AEnd)
  // вынимает и расставляет заново: его дети в .dfm - в итоговом порядке.
  // Порядок - как после процедуры: пункты .dfm по строкам Remove/Add,
  // переносимые пункты - по строкам вложенности. Строки Remove/Add пунктов
  // .dfm уходят из кода. '' - объекта AParent в .dfm нет.
  function ReorderedDfm(const ADfm, AParent: string; AHead, AEnd: Integer): string;
  var
    DfmLines, Sequence, Blocks: TStringList;
    ParentFirst, ParentLast, ChildIndent, LineIndex, FirstChild, BlockFirst,
      BlockLast, ItemIndex, At, Colon, Space: Integer;
    Text, OpParent, OpChild, ChildName: string;
    Item: TMoveInfo;
  begin
    Result := '';
    if not DfmObjectRange(ADfm, AParent, ParentFirst, ParentLast) then
      Exit;
    DfmLines := TStringList.Create;
    Sequence := TStringList.Create;
    Blocks := TStringList.Create;
    try
      DfmLines.Text := ADfm;
      ChildIndent := LeadSpacesOf(DfmLines[ParentFirst]) + 2;
      // Дети AParent в .dfm: имя, в Objects - строка заголовка
      FirstChild := ParentLast;
      for LineIndex := ParentFirst + 1 to ParentLast - 1 do
      begin
        Text := DfmLines[LineIndex];
        if LeadSpacesOf(Text) <> ChildIndent then
          Continue;
        Text := Trim(Text);
        if (Copy(Text, 1, 7) <> 'object ') and
           (Copy(Text, 1, 10) <> 'inherited ') and
           (Copy(Text, 1, 7) <> 'inline ') then
          Continue;
        Space := Pos(' ', Text);
        Colon := Pos(':', Text);
        if Colon <= Space then
          Continue;
        ChildName := Trim(Copy(Text, Space + 1, Colon - Space - 1));
        Blocks.AddObject(ChildName, TObject(LineIndex));
        Sequence.Add(ChildName);
        if LineIndex < FirstChild then
          FirstChild := LineIndex;
      end;
      // Порядок после процедуры
      for LineIndex := AHead to AEnd do
      begin
        Text := Trim(StripComment(Lines[LineIndex]));
        if ParseRemoveLine(Text, OpParent, OpChild) and
           (CompareText(OpParent, AParent) = 0) and
           (Blocks.IndexOf(OpChild) >= 0) then
        begin
          At := Sequence.IndexOf(OpChild);
          if At >= 0 then
            Sequence.Delete(At);
          Remove[LineIndex] := True;
        end
        else if ParseAddLine(Text, OpParent, OpChild) and
                (CompareText(OpParent, AParent) = 0) and
                (Blocks.IndexOf(OpChild) >= 0) then
        begin
          if Sequence.IndexOf(OpChild) < 0 then
            Sequence.Add(OpChild);
          Remove[LineIndex] := True;
        end;
        for ItemIndex := 0 to Order.Count - 1 do
        begin
          Item := TMoveInfo(Order[ItemIndex]);
          if (Item.NestLine = LineIndex) and
             (CompareText(Item.NestParent, AParent) = 0) and
             (Item.OrderGroup = AHead) then
            Sequence.AddObject(TDfmNode(Item.Node).VarName, Item);
        end;
      end;
      // Текст: всё до первого ребёнка, дети по порядку, end и дальше
      ObjText.Clear;
      for LineIndex := 0 to FirstChild - 1 do
        ObjText.Add(DfmLines[LineIndex]);
      for ItemIndex := 0 to Sequence.Count - 1 do
        if Sequence.Objects[ItemIndex] <> nil then
          BuildObject(TMoveInfo(Sequence.Objects[ItemIndex]), ChildIndent)
        else
        begin
          BlockFirst := Integer(Blocks.Objects[Blocks.IndexOf(Sequence[ItemIndex])]);
          BlockLast := BlockFirst + 1;
          while (BlockLast < ParentLast) and
                not ((LeadSpacesOf(DfmLines[BlockLast]) = ChildIndent) and
                     (Trim(DfmLines[BlockLast]) = 'end')) do
            Inc(BlockLast);
          for LineIndex := BlockFirst to BlockLast do
            ObjText.Add(DfmLines[LineIndex]);
        end;
      for LineIndex := ParentLast to DfmLines.Count - 1 do
        ObjText.Add(DfmLines[LineIndex]);
      Result := ObjText.Text;
      ObjText.Clear;
    finally
      Blocks.Free;
      Sequence.Free;
      DfmLines.Free;
    end;
  end;

begin
  Result := 0;
  ANewPas := APasText;
  ANewDfm := ADfmText;
  RootName := DfmRootName(ADfmText);
  if (RootName = '') or (DfmRootClass(ADfmText) = '') then
  begin
    AReport.Add('Форма - не текстовый .dfm: перенос невозможен.');
    Exit;
  end;

  Lines := TStringList.Create;
  ObjText := TStringList.Create;
  Handlers := TStringList.Create;
  Receivers := TStringList.Create;
  Summary := TStringList.Create;
  IconPlaces := TStringList.Create;
  DeclNames := TStringList.Create;
  Reorders := TStringList.Create;
  Order := TList.Create;
  try
    CollectIconPlaces(ADfmText, IconPlaces);
    Lines.Text := APasText;
    SetLength(Remove, Lines.Count);
    for LineIndex := 0 to Lines.Count - 1 do
      Remove[LineIndex] := False;

    // 1. Отметки: только «целиком» и «частично», имя в .dfm свободно
    for Index := 0 to AList.Count - 1 do
    begin
      Info := TMoveInfo(AList[Index]);
      if not Info.Selected then
        Continue;
      if not (Info.Kind in [mkWhole, mkPartial]) then
        Info.Selected := False
      else if DfmHasObject(ADfmText, TDfmNode(Info.Node).VarName) then
      begin
        Info.Selected := False;
        AReport.Add(Info.Title + ': не переносится - в .dfm уже есть ' +
                    'объект с именем ' + TDfmNode(Info.Node).VarName + '.');
      end;
    end;

    // 2. Родитель - форма, объект .dfm или тоже переносимый
    repeat
      Changed := False;
      for Index := 0 to AList.Count - 1 do
      begin
        Info := TMoveInfo(AList[Index]);
        if not Info.Selected or (Info.NestParent = '') then
          Continue;
        ParentInfo := FindInfoByName(AList, Info.NestParent);
        if ParentInfo = nil then
          ParentOk := DfmHasObject(ADfmText, Info.NestParent)
        else if ParentInfo.Kind = mkInDfm then
          ParentOk := DfmHasObject(ADfmText, DfmNameOf(ParentInfo))
        else
          ParentOk := ParentInfo.Selected;
        if not ParentOk then
        begin
          Info.Selected := False;
          Changed := True;
          AReport.Add(Info.Title + ': не переносится - родитель ' +
                      Info.NestParent + ' не отмечен и не лежит в .dfm.');
        end;
      end;
      // Создание по требованию: блок переносится только целиком
      for Index := 0 to AList.Count - 1 do
      begin
        Info := TMoveInfo(AList[Index]);
        if not Info.Selected then
          Continue;
        Before := LazyMissing(AList, Info);
        if Before <> '' then
        begin
          Info.Selected := False;
          Changed := True;
          AReport.Add(Info.Title + ': не переносится - ' + Before + '.');
        end;
      end;
    until not Changed;

    for Index := 0 to AList.Count - 1 do
      if TMoveInfo(AList[Index]).Selected then
        Order.Add(AList[Index]);
    if Order.Count = 0 then
    begin
      AReport.Add('Переносить нечего: не отмечено ни одного компонента.');
      Exit;
    end;
    Order.Sort(CompareNestLine);

    // 3. .dfm: верхние из переносимых - последними детьми своих родителей,
    // в порядке строк вложенности; их дети - внутри их блоков
    Dfm := ADfmText;
    for Index := 0 to Order.Count - 1 do
    begin
      Info := TMoveInfo(Order[Index]);
      ParentName := ParentDfmName(Info);
      if Receivers.IndexOf(ParentName) < 0 then
        Receivers.Add(ParentName);
      if ParentMoves(Info) then
        Continue;
      // Пункт меню, которое процедура переставляет: встанет на своё место
      // при перестройке всего меню ниже
      if Info.OrderGroup >= 0 then
      begin
        ReorderKey := Info.OrderParent + '|' + IntToStr(Info.OrderGroup) +
                      '|' + IntToStr(Info.OrderEnd);
        if Reorders.IndexOf(ReorderKey) < 0 then
          Reorders.AddObject(ReorderKey, Info);
        Continue;
      end;
      ObjText.Clear;
      BuildObject(Info, 0);
      Before := Dfm;
      Dfm := DfmInsertObject(Dfm, ParentName, ObjText.Text);
      if Dfm = Before then
      begin
        AReport.Add('Ошибка: в .dfm не найден объект ' + ParentName +
                    ' - перенос не выполнен.');
        Exit;
      end;
    end;

    // Меню, пункты которых процедура переставляет: весь блок меню - заново,
    // в итоговом порядке
    for Index := 0 to Reorders.Count - 1 do
    begin
      Info := TMoveInfo(Reorders.Objects[Index]);
      Before := ReorderedDfm(Dfm, Info.OrderParent, Info.OrderGroup,
                             Info.OrderEnd);
      if Before = '' then
      begin
        AReport.Add('Ошибка: в .dfm не найден объект ' + Info.OrderParent +
                    ' - перенос не выполнен.');
        Exit;
      end;
      Dfm := Before;
      AReport.Add('Меню ' + Info.OrderParent + ': порядок пунктов в .dfm - ' +
                  'как после ' + Info.Routine + ', строки Remove/Add его ' +
                  'пунктов из .dfm уходят из кода.');
    end;

    // 4. Предупреждения: у родителя остаётся в коде контрол или пункт
    // меню, который сейчас создаётся раньше перенесённого - после переноса
    // он встанет после него. По одному на родителя.
    for Index := 0 to AList.Count - 1 do
    begin
      Info := TMoveInfo(AList[Index]);
      if not Info.Selected then
        Continue;
      ParentInfo := StaysBefore(AList, Index);
      if ParentInfo = nil then
        Continue;
      ParentNode := TDfmNode(Info.Node).Parent;
      if ParentNode = nil then
        Continue;
      if ParentNode.Name <> '' then
        ParentName := ParentNode.Name
      else
        ParentName := ParentNode.VarName;
      if Receivers.IndexOf('!' + ParentName) >= 0 then
        Continue;
      Receivers.Add('!' + ParentName);
      AReport.Add('Внимание: у ' + ParentName + ' порядок изменится - ' +
                  ParentInfo.Title + ' остаётся в коде и сейчас создаётся ' +
                  'раньше ' + Info.Title + '; после переноса он встанет ' +
                  'после перенесённых. Проверить порядок пунктов и ' +
                  'выравнивание (или отметить и его).');
    end;

    // Проверки на nil у переносимых: после переноса компонент есть всегда
    for Index := 0 to Order.Count - 1 do
    begin
      Info := TMoveInfo(Order[Index]);
      if Info.NilChecks.Count = 0 then
        Continue;
      Before := '';
      for LineIndex := 0 to Info.NilChecks.Count - 1 do
      begin
        if Before <> '' then
          Before := Before + ', ';
        Before := Before + Copy(Info.NilChecks[LineIndex], 1,
                                Pos(':', Info.NilChecks[LineIndex]) - 1);
      end;
      AReport.Add('Просмотреть: ' + Info.Title + ' проверяется на nil ' +
                  '(строки ' + Before + ') - после переноса он есть всегда.');
    end;
    // Из них - те, что могут выполниться до прежнего создания
    for Index := 0 to Order.Count - 1 do
    begin
      Info := TMoveInfo(Order[Index]);
      if Info.NilRisk.Count = 0 then
        Continue;
      Before := '';
      for LineIndex := 0 to Info.NilRisk.Count - 1 do
      begin
        if Before <> '' then
          Before := Before + ', ';
        Before := Before + IntToStr(LineOfRef(Info.NilRisk[LineIndex]) + 1);
      end;
      AReport.Add('Внимание: ' + Info.Title + ' - проверки на nil, которые ' +
                  'могут выполниться до его прежнего создания (строки ' +
                  Before + '): там nil значил «ещё не создан», после ' +
                  'переноса код за проверкой пойдёт дальше. Проверить ' +
                  'вручную.');
    end;

    // Локальные переменные, ставшие полями: объявление в var - прочь
    // (одно имя в строке - строка уходит, как строки кода; несколько -
    // строка остаётся без этого имени). Раздел var без единого имени - тоже
    // прочь: пустой var не компилируется.
    for Index := 0 to Order.Count - 1 do
    begin
      Info := TMoveInfo(Order[Index]);
      if Info.LocalDecl < 0 then
        Continue;
      DeclText := Trim(StripComment(Lines[Info.LocalDecl]));
      if Info.LocalDecl = Info.LocalVarLine then
        DeclText := Trim(Copy(DeclText, 4, MaxInt));
      if not ParseFieldLine(DeclText, DeclNames, DeclType, DeclTail) or
         (DeclNames.IndexOf(TDfmNode(Info.Node).VarName) < 0) then
      begin
        AReport.Add('Внимание: объявление ' + TDfmNode(Info.Node).VarName +
                    ' в строке ' + IntToStr(Info.LocalDecl + 1) + ' не ' +
                    'разобралось - убрать его из var вручную, иначе ' +
                    'локальная переменная закроет поле.');
        Continue;
      end;
      DeclTail := '';
      if Pos('//', Lines[Info.LocalDecl]) > 0 then
        DeclTail := Copy(Lines[Info.LocalDecl],
                         Pos('//', Lines[Info.LocalDecl]), MaxInt);
      if DeclNames.Count = 1 then
      begin
        if (Info.LocalDecl = Info.LocalVarLine) and
           (Info.LocalSectionNames > 1) then
          // var X: T; и дальше ещё объявления - остаётся слово var
          Lines[Info.LocalDecl] :=
            StringOfChar(' ', LeadSpacesOf(Lines[Info.LocalDecl])) + 'var'
        else
          Remove[Info.LocalDecl] := True;
        if (Info.LocalSectionNames = 1) and (Info.LocalVarLine >= 0) then
          Remove[Info.LocalVarLine] := True;
      end
      else
      begin
        DeclNames.Delete(DeclNames.IndexOf(TDfmNode(Info.Node).VarName));
        DeclText := DeclNames[0];
        for LineIndex := 1 to DeclNames.Count - 1 do
          DeclText := DeclText + ', ' + DeclNames[LineIndex];
        DeclText := StringOfChar(' ', LeadSpacesOf(Lines[Info.LocalDecl])) +
                    DeclText + ': ' + DeclType + ';';
        if DeclTail <> '' then
          DeclText := DeclText + ' ' + DeclTail;
        Lines[Info.LocalDecl] := DeclText;
      end;
    end;

    // Переменная, которой создают несколько компонентов: строка создания
    // не уходит, а берёт компонент из поля
    SetLength(Replace, Lines.Count);
    for LineIndex := 0 to Lines.Count - 1 do
      Replace[LineIndex] := '';
    for Index := 0 to Order.Count - 1 do
    begin
      Info := TMoveInfo(Order[Index]);
      if Info.ReplaceText <> '' then
        Replace[Info.CreateLine] :=
          StringOfChar(' ', LeadSpacesOf(Lines[Info.CreateLine])) +
          Info.ReplaceText;
    end;

    // 5. .pas: строки, ушедшие в .dfm
    LineCount := 0;
    for LineIndex := Lines.Count - 1 downto 0 do
      if Remove[LineIndex] and (Replace[LineIndex] <> '') then
      begin
        Inc(LineCount);
        // Прежняя строка - комментарием на своей строке выше, не в конце
        // новой: создание в хвостовом комментарии разбор кода принял бы за
        // создание
        if not ADeleteLines then
          Lines.Insert(LineIndex, StringOfChar(' ',
                       LeadSpacesOf(Lines[LineIndex])) + '// .dfm: ' +
                       TrimLeft(Lines[LineIndex]));
        Lines[LineIndex + Ord(not ADeleteLines)] := Replace[LineIndex];
      end
      else if Remove[LineIndex] then
      begin
        Inc(LineCount);
        if ADeleteLines then
          Lines.Delete(LineIndex)
        else
          Lines[LineIndex] := StringOfChar(' ', LeadSpacesOf(Lines[LineIndex])) +
                              '// .dfm: ' + TrimLeft(Lines[LineIndex]);
      end;

    // 6. Поля и обработчики - в published
    PublishInClass(Lines, AFormClass, Order, Handlers, AReport, FieldCount,
                   MethodCount);

    Summary.Add('Переносится компонентов: ' + IntToStr(Order.Count));
    if ADeleteLines then
      Summary.Add('Строк кода удаляется: ' + IntToStr(LineCount))
    else
      Summary.Add('Строк кода закомментировано (// .dfm:): ' +
                  IntToStr(LineCount));
    Summary.Add('Полей перенесено в published: ' + IntToStr(FieldCount));
    Summary.Add('Обработчиков перенесено в published: ' +
                IntToStr(MethodCount));
    for Index := Summary.Count - 1 downto 0 do
      AReport.Insert(0, Summary[Index]);

    ANewPas := TextLikeOrig(Lines, APasText);
    ANewDfm := Dfm;
    Result := Order.Count;
  finally
    Order.Free;
    Reorders.Free;
    DeclNames.Free;
    IconPlaces.Free;
    Summary.Free;
    Receivers.Free;
    Handlers.Free;
    ObjText.Free;
    Lines.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  Согласованность формы и модуля
// ---------------------------------------------------------------------------

function DfmCheckConsistency(const APasText, ADfmText, AFormClass: string;
  AErrors, AWarnings: TStrings): Boolean;
var
  Pas, Dfm, Names, PubTypes, Owners: TStringList;
  First, Last, Index, Colon, FieldLine, Start, Stop, Eq: Integer;
  Text, Rest, ObjName, ObjClass, FieldType, Tail, EventName, Method,
    Where: string;
  IsRoot: Boolean;

  function IsHeader(const AText: string; var ARest: string): Boolean;
  begin
    Result := True;
    if Copy(AText, 1, 7) = 'object ' then
      ARest := Trim(Copy(AText, 8, MaxInt))
    else if Copy(AText, 1, 10) = 'inherited ' then
      ARest := Trim(Copy(AText, 11, MaxInt))
    else if Copy(AText, 1, 7) = 'inline ' then
      ARest := Trim(Copy(AText, 8, MaxInt))
    else
      Result := False;
  end;

  function CurrentOwner: string;
  begin
    if Owners.Count > 0 then
      Result := Owners[Owners.Count - 1]
    else
      Result := '';
  end;

begin
  Pas := TStringList.Create;
  Dfm := TStringList.Create;
  Names := TStringList.Create;
  PubTypes := TStringList.Create;
  Owners := TStringList.Create;
  try
    Pas.Text := APasText;
    Dfm.Text := ADfmText;
    FindClassDecl(Pas, AFormClass, First, Last);
    if (First < 0) or (Last < 0) then
    begin
      AErrors.Add('Объявление класса ' + AFormClass + ' в модуле не найдено.');
      Result := False;
      Exit;
    end;

    // Типы published-полей: по ним форма находит классы объектов .dfm
    for Index := First + 1 to Last - 1 do
      if ParseFieldLine(Pas[Index], Names, FieldType, Tail) and
         IsPublishedLine(Pas, First, Index) and
         (PubTypes.IndexOf(FieldType) < 0) then
        PubTypes.Add(FieldType);

    IsRoot := True;
    for Index := 0 to Dfm.Count - 1 do
    begin
      Text := Trim(Dfm[Index]);
      Where := ' (строка .dfm ' + IntToStr(Index + 1) + ')';
      if IsHeader(Text, Rest) then
      begin
        Colon := Pos(':', Rest);
        if Colon > 0 then
        begin
          ObjName := Trim(Copy(Rest, 1, Colon - 1));
          ObjClass := Trim(Copy(Rest, Colon + 1, MaxInt));
        end
        else
        begin
          ObjName := '';
          ObjClass := Rest;
        end;
        Owners.Add(ObjName);
        if IsRoot then
        begin
          IsRoot := False;       // сама форма - её поле не нужно
          Continue;
        end;
        if ObjName = '' then
          Continue;
        FieldLine := FindFieldDecl(Pas, First, Last, ObjName, Names,
                                   FieldType, Tail);
        if FieldLine < 0 then
        begin
          if PubTypes.IndexOf(ObjClass) < 0 then
            AWarnings.Add(ObjName + ': ' + ObjClass + Where + ' - поля в ' +
              'классе нет, и ' + ObjClass + ' - не тип ни одного ' +
              'published-поля: при загрузке класс найдётся, только если он ' +
              'зарегистрирован (RegisterClass)')
          else
            AWarnings.Add(ObjName + ': ' + ObjClass + Where + ' - поля в ' +
              'классе нет: из кода к объекту не обратиться');
        end
        else if not IsPublishedLine(Pas, First, FieldLine) then
          AErrors.Add(ObjName + ': ' + ObjClass + Where + ' - поле объявлено ' +
            'не в published (строка модуля ' + IntToStr(FieldLine + 1) +
            '): при загрузке оно останется nil')
        else if (CompareText(FieldType, ObjClass) <> 0) and
                (PubTypes.IndexOf(ObjClass) < 0) then
          AErrors.Add(ObjName + ': ' + ObjClass + Where + ' - поле объявлено ' +
            'как ' + FieldType + ', а ' + ObjClass + ' - не тип ни одного ' +
            'published-поля: при загрузке будет EClassNotFound, если класс ' +
            'не зарегистрирован (RegisterClass)');
        Continue;
      end;
      // Элемент коллекции и конец объекта или элемента
      if Text = 'item' then
      begin
        Owners.Add(CurrentOwner);
        Continue;
      end;
      if (Text = 'end') or (Text = 'end>') or (Copy(Text, 1, 4) = 'end>') then
      begin
        if Owners.Count > 0 then
          Owners.Delete(Owners.Count - 1);
        Continue;
      end;
      // Событие: OnClick = Метод
      Eq := Pos(' = ', Text);
      if (Eq > 3) and (Copy(Text, 1, 2) = 'On') and (Text[3] in ['A'..'Z']) then
      begin
        EventName := Copy(Text, 1, Eq - 1);
        Method := Trim(Copy(Text, Eq + 3, MaxInt));
        if not IsValidIdent(EventName) or not IsValidIdent(Method) then
          Continue;
        if not FindMethodDecl(Pas, First, Last, Method, Start, Stop) then
          AErrors.Add(CurrentOwner + '.' + EventName + ' = ' + Method + Where +
            ' - метода ' + Method + ' в классе ' + AFormClass + ' нет')
        else if not IsPublishedLine(Pas, First, Start) then
          AErrors.Add(CurrentOwner + '.' + EventName + ' = ' + Method + Where +
            ' - метод объявлен не в published (строка модуля ' +
            IntToStr(Start + 1) + '): при загрузке формы будет ошибка ' +
            'чтения (Invalid property value)');
      end;
    end;
    Result := AErrors.Count = 0;
  finally
    Owners.Free;
    PubTypes.Free;
    Names.Free;
    Dfm.Free;
    Pas.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  Окно результата
// ---------------------------------------------------------------------------

const
  KindNames: array[TMoveKind] of string =
    ('в .dfm', 'целиком', 'частично', 'нет');

type
  // Тексты до и после переноса - для «Отменить перенос». Живут, пока
  // открыта IDE; откатываются по одному, последний первым.
  TMoveUndoStep = class
  public
    PasFile, DfmFile: string;
    OldPas, OldDfm, NewPas, NewDfm: string;
    Report: string;           // что сделано - показать в новом окне разбора
    Shown: Boolean;
  end;

  TMoveReportForm = class(TForm)
  public
    List: TList;
    View: TUiListView;
    Details: TUiMemo;
    Summary: TUiLabel;
    ChkDelete: TUiCheckBox;
    BtnMove, BtnUndo: TUiButton;
    GoLine: TDfmMoveGoLine;
    Host: TDfmMoveHost;
    UnitFile: string;       // модуль формы: полный путь
    DfmFile: string;        // форма: полный путь
    FormClass: string;
    PasText, DfmText: string;   // тексты, по которым сделан разбор
    FillingChecks: Boolean; // отметки ставит код - OnChange не разбирать
    // Согласованность формы и модуля (DfmCheckConsistency) на момент разбора
    ConsistErrors, ConsistWarnings: TStringList;
    destructor Destroy; override;
    procedure ShowConsistency;
    procedure ViewChange(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure SetSelected(Info: TMoveInfo; AValue: Boolean);
    procedure ShowChecks;
    procedure MoveClick(Sender: TObject);
    procedure UndoClick(Sender: TObject);
    procedure SelectAllClick(Sender: TObject);
    procedure ViewSelect(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure ViewClick(Sender: TObject);
    procedure ViewDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure ViewDrawSubItem(Sender: TCustomListView; Item: TListItem;
      SubItem: Integer; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure DetailsClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure CloseBtnClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure Jump(ALine: Integer);
  end;

var
  ReportForm: TMoveReportForm = nil;   // открытое окно разбора
  UndoSteps: TList = nil;              // TMoveUndoStep
  BackedUp: TStringList = nil;         // файлы, для которых уже сделан .bak

// Тексты совпадают, не считая #13 и переводов строки в конце: редактор
// может хранить переводы строк иначе, чем их записали
function SameBody(const A, B: string): Boolean;

  function Squeeze(const S: string): string;
  var
    From, Into, Stop: Integer;
  begin
    SetLength(Result, Length(S));
    Into := 0;
    for From := 1 to Length(S) do
      if S[From] <> #13 then
      begin
        Inc(Into);
        Result[Into] := S[From];
      end;
    Stop := Into;
    while (Stop > 0) and (Result[Stop] = #10) do
      Dec(Stop);
    SetLength(Result, Stop);
  end;

begin
  Result := (A = B) or (Squeeze(A) = Squeeze(B));
end;

// Последний перенос модуля APasFile, который ещё можно откатить; nil - нет
function LastUndoStep(const APasFile: string): TMoveUndoStep;
var
  Index: Integer;
begin
  Result := nil;
  if UndoSteps = nil then
    Exit;
  for Index := UndoSteps.Count - 1 downto 0 do
    if CompareText(TMoveUndoStep(UndoSteps[Index]).PasFile, APasFile) = 0 then
    begin
      Result := TMoveUndoStep(UndoSteps[Index]);
      Exit;
    end;
end;

procedure FreeUndoSteps;
var
  Index: Integer;
begin
  if UndoSteps <> nil then
  begin
    for Index := 0 to UndoSteps.Count - 1 do
      TObject(UndoSteps[Index]).Free;
    FreeAndNil(UndoSteps);
  end;
  FreeAndNil(BackedUp);
end;

destructor TMoveReportForm.Destroy;
var
  Index: Integer;
begin
  if ReportForm = Self then
    ReportForm := nil;
  // Строки списка ссылаются на разборы (Data). Список уничтожается позже,
  // в inherited Destroy, и при этом ещё может прислать уведомления
  // (смена состояния, отрисовка) - к тому времени разборы и их узлы уже
  // освобождены. Поэтому сначала отключить обработчики и очистить строки,
  // пока разборы живы, и только потом освобождать разборы.
  FillingChecks := True;
  if View <> nil then
  begin
    View.OnChange := nil;
    View.OnSelectItem := nil;
    View.OnClick := nil;
    View.OnCustomDrawItem := nil;
    View.OnCustomDrawSubItem := nil;
    View.Items.BeginUpdate;
    try
      View.Items.Clear;
    finally
      View.Items.EndUpdate;
    end;
  end;
  ConsistErrors.Free;
  ConsistErrors := nil;
  ConsistWarnings.Free;
  ConsistWarnings := nil;
  if List <> nil then
  begin
    for Index := 0 to List.Count - 1 do
      TObject(List[Index]).Free;
    List.Free;
    List := nil;
  end;
  inherited Destroy;
end;

procedure TMoveReportForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
  // Окно уйдёт позже (Release): новое окно разбора его уже не трогает
  if ReportForm = Self then
    ReportForm := nil;
end;

// Отметки в списке - по Selected разборов; в строке итога - сколько отмечено
procedure TMoveReportForm.ShowChecks;
var
  Index, Count: Integer;
  Info: TMoveInfo;
  Counts: array[TMoveKind] of Integer;
  Kind: TMoveKind;
begin
  for Kind := Low(TMoveKind) to High(TMoveKind) do
    Counts[Kind] := 0;
  Count := 0;
  FillingChecks := True;
  try
    for Index := 0 to View.Items.Count - 1 do
    begin
      Info := TMoveInfo(View.Items[Index].Data);
      if Info = nil then
        Continue;
      Inc(Counts[Info.Kind]);
      if View.Items[Index].Checked <> Info.Selected then
        View.Items[Index].Checked := Info.Selected;
      if Info.Selected then
        Inc(Count);
    end;
  finally
    FillingChecks := False;
  end;
  Summary.Caption := Format('  Целиком: %d   Частично: %d   Нет: %d   ' +
    'Уже в .dfm: %d      Отмечено для переноса: %d', [Counts[mkWhole],
    Counts[mkPartial], Counts[mkNo], Counts[mkInDfm], Count]);
  if (ConsistErrors <> nil) and (ConsistErrors.Count > 0) then
    Summary.Caption := Summary.Caption + Format('      Форма и модуль не ' +
      'согласованы: %d', [ConsistErrors.Count]);
end;

// Отметка компонента. Отмечен - отмечаются и родители (без них ему в .dfm
// некуда лечь); снят - снимаются дети.
procedure TMoveReportForm.SetSelected(Info: TMoveInfo; AValue: Boolean);
var
  UpInfo, Mate: TMoveInfo;
  Index, MateIndex: Integer;
  Changed: Boolean;
  Group: TList;
begin
  if AValue then
  begin
    // Созданные в одном блоке по требованию отмечаются вместе
    Group := TList.Create;
    try
      Group.Add(Info);
      if (Info.LazyGroup >= 0) or (Info.OrderGroup >= 0) or
         (Info.HelperGroup >= 0) then
        for Index := 0 to List.Count - 1 do
        begin
          Mate := TMoveInfo(List[Index]);
          if (Mate <> Info) and
             (((Info.LazyGroup >= 0) and (Mate.LazyGroup = Info.LazyGroup)) or
              ((Info.HelperGroup >= 0) and
               (Mate.HelperGroup = Info.HelperGroup)) or
              ((Info.OrderGroup >= 0) and
               (Mate.OrderGroup = Info.OrderGroup) and
               (CompareText(Mate.OrderParent, Info.OrderParent) = 0))) then
            Group.Add(Mate);
        end;
      // Родители - сначала проверить, что их можно перенести
      for MateIndex := 0 to Group.Count - 1 do
      begin
        Mate := TMoveInfo(Group[MateIndex]);
        if not (Mate.Kind in [mkWhole, mkPartial]) then
        begin
          Details.Lines.Text := Info.Title + ': не отмечается - вместе с ' +
                                'ним создаётся ' + Mate.Title + ', он не ' +
                                'переносится (' + Mate.Reason + ').';
          Exit;
        end;
        UpInfo := FindInfoByName(List, Mate.NestParent);
        while (UpInfo <> nil) and (UpInfo.Kind <> mkInDfm) do
        begin
          if not (UpInfo.Kind in [mkWhole, mkPartial]) then
          begin
            Details.Lines.Text := Info.Title + ': не отмечается - родитель ' +
                                  UpInfo.Title + ' не переносится (' +
                                  UpInfo.Reason + ').';
            Exit;
          end;
          UpInfo := FindInfoByName(List, UpInfo.NestParent);
        end;
      end;
      for MateIndex := 0 to Group.Count - 1 do
      begin
        Mate := TMoveInfo(Group[MateIndex]);
        Mate.Selected := True;
        UpInfo := FindInfoByName(List, Mate.NestParent);
        while (UpInfo <> nil) and (UpInfo.Kind <> mkInDfm) do
        begin
          UpInfo.Selected := True;
          UpInfo := FindInfoByName(List, UpInfo.NestParent);
        end;
      end;
    finally
      Group.Free;
    end;
  end
  else
  begin
    Info.Selected := False;
    // Снять детей снятого и всех из его блока по требованию
    repeat
      Changed := False;
      for Index := 0 to List.Count - 1 do
      begin
        UpInfo := TMoveInfo(List[Index]);
        if not UpInfo.Selected then
          Continue;
        Mate := FindInfoByName(List, UpInfo.NestParent);
        if ((UpInfo.NestParent <> '') and (Mate <> nil) and
            not Mate.Selected and (Mate.Kind <> mkInDfm)) or
           (((UpInfo.LazyGroup >= 0) or (UpInfo.OrderGroup >= 0) or
             (UpInfo.HelperGroup >= 0)) and
            (LazyMissing(List, UpInfo) <> '')) then
        begin
          UpInfo.Selected := False;
          Changed := True;
        end;
      end;
    until not Changed;
  end;
end;

// Галочку поставили или сняли. У «нет» и «в .dfm» её не бывает.
procedure TMoveReportForm.ViewChange(Sender: TObject; Item: TListItem;
  Change: TItemChange);
var
  Info, Other: TMoveInfo;
begin
  if FillingChecks or (csDestroying in ComponentState) or
     (Change <> ctState) or (Item = nil) or (Item.Data = nil) then
    Exit;
  Info := TMoveInfo(Item.Data);
  if Item.Checked = Info.Selected then
    Exit;
  if Item.Checked and not (Info.Kind in [mkWhole, mkPartial]) then
  begin
    ShowChecks;
    Exit;
  end;
  SetSelected(Info, Item.Checked);
  ShowChecks;
  // Отметили то, перед чем в коде остаётся сосед, или что проверяется
  // на nil до прежнего создания - сразу сказать
  if Info.Selected and (Info.NilRisk.Count > 0) then
  begin
    Details.Lines.Clear;
    Details.Lines.Add('Внимание: ' + Info.Title + ' проверяется на nil в ' +
                      'коде, который может выполниться до его прежнего ' +
                      'создания. После переноса он есть с загрузки формы, ' +
                      'и код за проверкой пойдёт дальше - проверить эти ' +
                      'строки:');
    Details.Lines.AddStrings(Info.NilRisk);
  end;
  if Info.Selected then
  begin
    Other := StaysBefore(List, List.IndexOf(Info));
    if Other <> nil then
      Details.Lines.Text := 'Внимание: ' + Other.Title + ' остаётся в коде ' +
        'и сейчас создаётся раньше ' + Info.Title + '. После переноса он ' +
        'встанет после перенесённых - порядок пунктов меню или ' +
        'выравнивание изменятся. Можно отметить и его.';
  end;
end;

// Несогласованности формы и модуля - в нижнюю часть окна
procedure TMoveReportForm.ShowConsistency;
var
  Text: TStringList;
begin
  Text := TStringList.Create;
  try
    if ConsistErrors.Count > 0 then
    begin
      Text.Add('Форма и модуль не согласованы - при загрузке формы будет ' +
               'ошибка или поле останется nil. Перенос закрыт, пока это ' +
               'не исправлено:');
      Text.AddStrings(ConsistErrors);
    end;
    if ConsistWarnings.Count > 0 then
    begin
      if Text.Count > 0 then
        Text.Add('');
      Text.Add('Просмотреть:');
      Text.AddStrings(ConsistWarnings);
    end;
    if Text.Count > 0 then
      Details.Lines.Assign(Text);
  finally
    Text.Free;
  end;
end;

// «Отметить всё возможное»: «целиком» и «частично» без смены порядка
procedure TMoveReportForm.SelectAllClick(Sender: TObject);
var
  Index, Count: Integer;
begin
  SelectPossible(List, True);
  ShowChecks;
  Count := 0;
  for Index := 0 to List.Count - 1 do
    if TMoveInfo(List[Index]).Selected then
      Inc(Count);
  Details.Lines.Text := 'Отмечено всё, что можно перенести без смены ' +
    'порядка: ' + IntToStr(Count) + '.'#13#10'Остальные «целиком» и ' +
    '«частично» не отмечены: их родитель не переносится или раньше них ' +
    'в коде остаётся сосед.';
end;

// «Перенести»: отмеченные компоненты - в .dfm, тексты - во вкладки
procedure TMoveReportForm.MoveClick(Sender: TObject);
var
  CurPas, CurDfm, NewPas, NewDfm, Bak: string;
  Report: TStringList;
  Count, Index: Integer;
  Step: TMoveUndoStep;
  Files: array[0..1] of string;
begin
  if not Assigned(Host.GetText) or not Assigned(Host.SetTexts) then
    Exit;
  // Форма и модуль уже расходятся - перенос добавил бы к этому свои правки
  if ConsistErrors.Count > 0 then
  begin
    ShowConsistency;
    ShowMessage('Форма и модуль не согласованы (' +
                IntToStr(ConsistErrors.Count) + '). Перенос не выполняется, ' +
                'пока это не исправлено - список в нижней части окна.');
    Exit;
  end;
  // Разбор сделан по прежним текстам: номера строк в нём - их
  CurPas := Host.GetText(UnitFile);
  CurDfm := Host.GetText(DfmFile);
  if not SameBody(CurPas, PasText) or not SameBody(CurDfm, DfmText) then
  begin
    ShowMessage('Модуль или форма изменились после разбора. Разбор будет ' +
                'сделан заново - затем повторите перенос.');
    Close;
    if Assigned(Host.Done) then
      Host.Done;
    Exit;
  end;

  Report := TStringList.Create;
  try
    Count := DfmMoveApply(List, PasText, DfmText, FormClass,
                          ChkDelete.Checked, NewPas, NewDfm, Report);
    ShowChecks;     // перенос мог снять отметки, которые нельзя выполнить
    Details.Lines.Assign(Report);
    if Count = 0 then
    begin
      ShowMessage('Перенос не выполнен - причина в нижней части окна.');
      Exit;
    end;
    if MessageDlg('Перенести в .dfm компонентов: ' + IntToStr(Count) + '?' +
                  #13#10'Что будет сделано и предупреждения - в нижней ' +
                  'части окна.'#13#10#13#10'Тексты пишутся во вкладки, на ' +
                  'диск - по Save. Файлы с диска копируются в .bak.',
                  mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      Exit;

    // Копии файлов с диска - один раз за работу IDE, до первой записи
    if BackedUp = nil then
      BackedUp := TStringList.Create;
    Bak := '';
    Files[0] := UnitFile;
    Files[1] := DfmFile;
    for Index := 0 to 1 do
      if FileExists(Files[Index]) and (BackedUp.IndexOf(Files[Index]) < 0) then
        if CopyFile(PChar(Files[Index]), PChar(Files[Index] + '.bak'),
                    False) then
        begin
          BackedUp.Add(Files[Index]);
          Bak := Bak + #13#10 + Files[Index] + '.bak';
        end
        else
          Report.Add('Копию ' + Files[Index] + '.bak сделать не удалось.');

    if UndoSteps = nil then
      UndoSteps := TList.Create;
    Step := TMoveUndoStep.Create;
    Step.PasFile := UnitFile;
    Step.DfmFile := DfmFile;
    Step.OldPas := PasText;
    Step.OldDfm := DfmText;
    Step.NewPas := NewPas;
    Step.NewDfm := NewDfm;
    Step.Report := Report.Text;
    UndoSteps.Add(Step);
    Host.SetTexts(UnitFile, NewPas, DfmFile, NewDfm);
    if Bak <> '' then
      ShowMessage('Перенесено компонентов: ' + IntToStr(Count) + '.' +
                  #13#10#13#10'Копии файлов с диска:' + Bak + #13#10#13#10 +
                  'Вернуть тексты до переноса - «Отменить перенос» в окне ' +
                  'разбора.')
    else
      ShowMessage('Перенесено компонентов: ' + IntToStr(Count) + '.' +
                  #13#10#13#10'Вернуть тексты до переноса - «Отменить ' +
                  'перенос» в окне разбора.');
  finally
    Report.Free;
  end;
  Close;
  if Assigned(Host.Done) then
    Host.Done;
end;

// «Отменить перенос»: модуль и форма - к текстам до последнего переноса
procedure TMoveReportForm.UndoClick(Sender: TObject);
var
  Step: TMoveUndoStep;
  Msg: string;
begin
  Step := LastUndoStep(UnitFile);
  if (Step = nil) or not Assigned(Host.SetTexts) then
    Exit;
  if not SameBody(Host.GetText(Step.PasFile), Step.NewPas) or
     not SameBody(Host.GetText(Step.DfmFile), Step.NewDfm) then
    Msg := 'После переноса модуль или форма менялись. Откат вернёт тексты ' +
           'до переноса, эти правки пропадут.'#13#10#13#10'Продолжить?'
  else
    Msg := 'Вернуть модуль и форму к текстам до последнего переноса?';
  if MessageDlg(Msg, mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;
  Host.SetTexts(Step.PasFile, Step.OldPas, Step.DfmFile, Step.OldDfm);
  UndoSteps.Remove(Step);
  Step.Free;
  Close;
  if Assigned(Host.Done) then
    Host.Done;
end;

procedure TMoveReportForm.CloseBtnClick(Sender: TObject);
begin
  Close;
end;

// Строка в редакторе; фокус - обратно сюда, по списку ходят дальше
procedure TMoveReportForm.Jump(ALine: Integer);
begin
  if (ALine < 0) or not Assigned(GoLine) then
    Exit;
  GoLine(ALine);
  if Visible and CanFocus then
    SetFocus;
end;

// Щелчок по компоненту - строка его создания
procedure TMoveReportForm.ViewClick(Sender: TObject);
begin
  if not (csDestroying in ComponentState) and (View.Selected <> nil) and
     (View.Selected.Data <> nil) then
  begin
    Jump(TMoveInfo(View.Selected.Data).CreateLine);
    if View.CanFocus then
      View.SetFocus;
  end;
end;

// Уже в .dfm - серым: их переносить не нужно
procedure TMoveReportForm.ViewDrawItem(Sender: TCustomListView; Item: TListItem;
  State: TCustomDrawState; var DefaultDraw: Boolean);
begin
  if (csDestroying in ComponentState) or (Item.Data = nil) then
    Exit;
  if TMoveInfo(Item.Data).Kind = mkInDfm then
    Sender.Canvas.Font.Color := UiThemeColor('OffText');
end;

procedure TMoveReportForm.ViewDrawSubItem(Sender: TCustomListView;
  Item: TListItem; SubItem: Integer; State: TCustomDrawState;
  var DefaultDraw: Boolean);
begin
  ViewDrawItem(Sender, Item, State, DefaultDraw);
end;

// Щелчок по строке подробностей вида «1234: текст» - строка 1234
procedure TMoveReportForm.DetailsClick(Sender: TObject);
var
  Row, Colon, Number: Integer;
  Text: string;
begin
  Row := Details.Perform(EM_LINEFROMCHAR, Details.SelStart, 0);
  if (Row < 0) or (Row >= Details.Lines.Count) then
    Exit;
  Text := Details.Lines[Row];
  Colon := Pos(':', Text);
  if Colon < 2 then
    Exit;
  Number := StrToIntDef(Trim(Copy(Text, 1, Colon - 1)), 0);
  if Number > 0 then
    Jump(Number - 1);
end;

// Подробности одного компонента - строками в AText
procedure InfoDetails(Info: TMoveInfo; AText: TStrings);
begin
  AText.Add(Info.Title + ' - ' + KindNames[Info.Kind]);
  if Info.Reason <> '' then
    AText.Add(Info.Reason);
  if Info.Routine <> '' then
    AText.Add('Создаётся в ' + Info.Routine + ', строка ' +
              IntToStr(Info.CreateLine + 1));
  // У «нет» строки бывают, когда не переносится родитель: тогда это то,
  // что ушло бы в .dfm вместе с ним
  if Info.MoveLines.Count > 0 then
  begin
    AText.Add('');
    if Info.Kind = mkNo then
      AText.Add('Ушли бы в .dfm вместе с родителем:')
    else
      AText.Add('Уйдут из кода в .dfm:');
    AText.AddStrings(Info.MoveLines);
  end;
  if Info.KeepLines.Count > 0 then
  begin
    AText.Add('');
    if Info.Kind = mkNo then
      AText.Add('Остались бы в коде:')
    else
      AText.Add('Останутся в коде (выполнятся после загрузки формы):');
    AText.AddStrings(Info.KeepLines);
  end;
  if Info.Handlers.Count > 0 then
  begin
    AText.Add('');
    if Info.Kind = mkNo then
      AText.Add('Обработчики - понадобились бы в published-части формы:')
    else
      AText.Add('Обработчики - объявить в published-части формы:');
    AText.AddStrings(Info.Handlers);
  end;
  if Info.Notes.Count > 0 then
  begin
    AText.Add('');
    AText.AddStrings(Info.Notes);
  end;
end;

procedure TMoveReportForm.ViewSelect(Sender: TObject; Item: TListItem;
  Selected: Boolean);
var
  Text: TStringList;
begin
  if not Selected or (csDestroying in ComponentState) or (Item = nil) or
     (Item.Data = nil) then
    Exit;
  Text := TStringList.Create;
  try
    InfoDetails(TMoveInfo(Item.Data), Text);
    Details.Lines.Assign(Text);
  finally
    Text.Free;
  end;
end;

// Весь разбор - в текстовый файл: итог, список в порядке дерева, затем
// подробности всего, что не лежит в .dfm. Файл предлагается рядом с
// модулем (если известен путь), имя - <модуль>_dfm_analysis.txt.
procedure TMoveReportForm.SaveClick(Sender: TObject);
var
  Dlg: TSaveDialog;
  Text: TStringList;
  Index: Integer;
  Info: TMoveInfo;
  Counts: array[TMoveKind] of Integer;
  Kind: TMoveKind;
  Line: string;
begin
  Dlg := TSaveDialog.Create(nil);
  Text := TStringList.Create;
  try
    Dlg.Title := 'Сохранить разбор';
    Dlg.Filter := 'Текст (*.txt)|*.txt|Все файлы (*.*)|*.*';
    Dlg.DefaultExt := 'txt';
    if ExtractFilePath(UnitFile) <> '' then
      Dlg.InitialDir := ExtractFilePath(UnitFile);
    Dlg.FileName := ChangeFileExt(ExtractFileName(UnitFile), '') +
                    '_dfm_analysis.txt';
    Dlg.Options := Dlg.Options + [ofOverwritePrompt];
    if not Dlg.Execute then
      Exit;

    for Kind := Low(TMoveKind) to High(TMoveKind) do
      Counts[Kind] := 0;
    for Index := 0 to List.Count - 1 do
      Inc(Counts[TMoveInfo(List[Index]).Kind]);
    Text.Add('Перенести в .dfm - разбор');
    Text.Add('Модуль: ' + UnitFile);
    Text.Add('Дата: ' + DateTimeToStr(Now));
    Text.Add('Сборка: ' + DfmMoveBuild);
    Text.Add(Format('Целиком: %d   Частично: %d   Нет: %d   Уже в .dfm: %d',
      [Counts[mkWhole], Counts[mkPartial], Counts[mkNo], Counts[mkInDfm]]));
    if (ConsistErrors.Count > 0) or (ConsistWarnings.Count > 0) then
    begin
      Text.Add('');
      Text.Add('=== Согласованность формы и модуля ===');
      if ConsistErrors.Count > 0 then
      begin
        Text.Add('Ошибки:');
        Text.AddStrings(ConsistErrors);
      end;
      if ConsistWarnings.Count > 0 then
      begin
        Text.Add('Просмотреть:');
        Text.AddStrings(ConsistWarnings);
      end;
    end;
    Text.Add('');
    Text.Add('=== Список ===');
    for Index := 0 to List.Count - 1 do
    begin
      Info := TMoveInfo(List[Index]);
      Line := StringOfChar(' ', Info.Depth * 4) + Info.Title + '  [' +
              KindNames[Info.Kind] + ']';
      if Info.Reason <> '' then
        Line := Line + '  ' + Info.Reason;
      Text.Add(Line);
    end;
    Text.Add('');
    Text.Add('=== Подробности (кроме уже лежащих в .dfm) ===');
    for Index := 0 to List.Count - 1 do
    begin
      Info := TMoveInfo(List[Index]);
      if Info.Kind = mkInDfm then
        Continue;
      Text.Add('');
      Text.Add('--------------------------------------------------------');
      InfoDetails(Info, Text);
    end;
    Text.SaveToFile(Dlg.FileName);
    ShowMessage('Разбор сохранён:'#13#10 + Dlg.FileName);
  finally
    Text.Free;
    Dlg.Free;
  end;
end;

procedure DfmMoveShowReport(AList: TList; const APasFile, ADfmFile,
  AFormClass, APasText, ADfmText: string; const AHost: TDfmMoveHost);
var
  Form: TMoveReportForm;
  Column: TListColumn;
  Item: TListItem;
  Info: TMoveInfo;
  Index: Integer;
  BtnClose, BtnSave, BtnSelectAll: TUiButton;
  Step: TMoveUndoStep;
begin
  // Прежнее окно разбора - закрыть: в нём разбор старого текста
  if ReportForm <> nil then
    ReportForm.Free;
  Form := TMoveReportForm.CreateNew(Application);
  ReportForm := Form;
  try
    Form.List := AList;
    Form.Host := AHost;
    Form.GoLine := AHost.GoLine;
    Form.UnitFile := APasFile;
    Form.DfmFile := ADfmFile;
    Form.FormClass := AFormClass;
    Form.PasText := APasText;
    Form.DfmText := ADfmText;
    Form.ConsistErrors := TStringList.Create;
    Form.ConsistWarnings := TStringList.Create;
    DfmCheckConsistency(APasText, ADfmText, AFormClass, Form.ConsistErrors,
                        Form.ConsistWarnings);
    Form.OnClose := Form.FormClose;
    Form.FormStyle := fsStayOnTop;
    Form.Caption := 'Перенести в .dfm - разбор: ' + ExtractFileName(APasFile);
    Form.Position := poScreenCenter;
    if Application.MainForm <> nil then
      Form.Font := Application.MainForm.Font;
    Form.Color := UiThemeColor('Window.BG');
    Form.Font.Color := UiThemeColor('Window.Text');
    Form.Width := 980;
    Form.Height := 640;

    // Отметки по умолчанию: всё «целиком», что можно перенести без смены
    // порядка
    SelectPossible(AList, False);

    Form.Summary := TUiLabel.Create(Form);
    Form.Summary.Parent := Form;
    Form.Summary.Align := alTop;
    Form.Summary.Height := 22;
    Form.Summary.Layout := tlCenter;

    // Кнопки внизу
    BtnClose := TUiButton.Create(Form);
    BtnClose.Parent := Form;
    BtnClose.Caption := 'Закрыть';
    BtnClose.Cancel := True;
    BtnClose.OnClick := Form.CloseBtnClick;
    BtnClose.Anchors := [akRight, akBottom];
    BtnClose.SetBounds(Form.ClientWidth - 12 - 90, Form.ClientHeight - 34,
                       90, 25);
    Form.BtnMove := TUiButton.Create(Form);
    Form.BtnMove.Parent := Form;
    Form.BtnMove.Caption := 'Перенести';
    Form.BtnMove.ShowHint := True;
    Form.BtnMove.Hint := 'Отмеченные компоненты - в .dfm; строки кода - ' +
                         'закомментировать или удалить';
    Form.BtnMove.Anchors := [akRight, akBottom];
    Form.BtnMove.SetBounds(BtnClose.Left - 8 - 90, BtnClose.Top, 90, 25);
    Form.BtnMove.OnClick := Form.MoveClick;
    Form.BtnUndo := TUiButton.Create(Form);
    Form.BtnUndo.Parent := Form;
    Form.BtnUndo.Caption := 'Отменить перенос';
    Form.BtnUndo.ShowHint := True;
    Form.BtnUndo.Hint := 'Вернуть модуль и форму к текстам до последнего ' +
                         'переноса';
    Form.BtnUndo.Anchors := [akRight, akBottom];
    Form.BtnUndo.SetBounds(Form.BtnMove.Left - 8 - 120, BtnClose.Top, 120, 25);
    Form.BtnUndo.OnClick := Form.UndoClick;
    Form.BtnUndo.Enabled := LastUndoStep(APasFile) <> nil;
    BtnSave := TUiButton.Create(Form);
    BtnSave.Parent := Form;
    BtnSave.Caption := 'Сохранить...';
    BtnSave.ShowHint := True;
    BtnSave.Hint := 'Весь разбор - в текстовый файл';
    BtnSave.Anchors := [akLeft, akBottom];
    BtnSave.SetBounds(8, BtnClose.Top, 100, 25);
    BtnSave.OnClick := Form.SaveClick;
    Form.ChkDelete := TUiCheckBox.Create(Form);
    Form.ChkDelete.Parent := Form;
    Form.ChkDelete.Caption := 'Удалять строки кода (иначе - закомментировать)';
    Form.ChkDelete.Checked := False;
    Form.ChkDelete.Anchors := [akLeft, akBottom];
    Form.ChkDelete.SetBounds(BtnSave.Left + BtnSave.Width + 12,
                             BtnClose.Top + 4, 290, 17);
    BtnSelectAll := TUiButton.Create(Form);
    BtnSelectAll.Parent := Form;
    BtnSelectAll.Caption := 'Отметить всё возможное';
    BtnSelectAll.ShowHint := True;
    BtnSelectAll.Hint := '«Целиком» и «частично» - кроме тех, у кого ' +
                         'родитель не переносится или порядок изменится';
    BtnSelectAll.Anchors := [akLeft, akBottom];
    BtnSelectAll.SetBounds(Form.ChkDelete.Left + Form.ChkDelete.Width + 8,
                           BtnClose.Top, 160, 25);
    BtnSelectAll.OnClick := Form.SelectAllClick;

    Form.Details := TUiMemo.Create(Form);
    Form.Details.Parent := Form;
    Form.Details.ReadOnly := True;
    Form.Details.ScrollBars := ssBoth;
    Form.Details.WordWrap := False;
    Form.Details.Font.Name := 'Courier New';
    Form.Details.Anchors := [akLeft, akRight, akBottom];
    Form.Details.SetBounds(8, Form.ClientHeight - 42 - 200,
                           Form.ClientWidth - 16, 200);

    Form.View := TUiListView.Create(Form);
    Form.View.Parent := Form;
    Form.View.ViewStyle := vsReport;
    Form.View.ReadOnly := True;
    Form.View.RowSelect := True;
    Form.View.HideSelection := False;
    Form.View.Checkboxes := True;
    Form.View.Anchors := [akLeft, akTop, akRight, akBottom];
    Form.View.SetBounds(8, 26, Form.ClientWidth - 16,
                        Form.Details.Top - 8 - 26);
    Column := Form.View.Columns.Add;
    Column.Caption := 'Компонент';
    Column.Width := 320;
    Column := Form.View.Columns.Add;
    Column.Caption := 'Перенос';
    Column.Width := 80;
    Column := Form.View.Columns.Add;
    Column.Caption := 'Почему / что останется';
    Column.Width := 460;

    for Index := 0 to AList.Count - 1 do
    begin
      Info := TMoveInfo(AList[Index]);
      Item := Form.View.Items.Add;
      Item.Caption := StringOfChar(' ', Info.Depth * 4) + Info.Title;
      Item.SubItems.Add(KindNames[Info.Kind]);
      Item.SubItems.Add(Info.Reason);
      Item.Checked := Info.Selected;
      Item.Data := Info;
    end;
    Form.ShowChecks;
    Form.View.OnSelectItem := Form.ViewSelect;
    Form.View.OnClick := Form.ViewClick;
    Form.View.OnChange := Form.ViewChange;
    Form.View.OnCustomDrawItem := Form.ViewDrawItem;
    Form.View.OnCustomDrawSubItem := Form.ViewDrawSubItem;
    Form.Details.OnClick := Form.DetailsClick;
    if Form.View.Items.Count > 0 then
      Form.View.Items[0].Selected := True;

    // Только что был перенос этого модуля - что сделано, внизу окна.
    // Несогласованности формы и модуля важнее - они поверх.
    Step := LastUndoStep(APasFile);
    if (Step <> nil) and not Step.Shown then
    begin
      Step.Shown := True;
      Form.Details.Lines.Text := 'Последний перенос:'#13#10 + Step.Report;
    end;
    Form.ShowConsistency;

    Form.Show;
  except
    Form.Free;
    raise;
  end;
end;

initialization

finalization
  FreeUndoSteps;

end.
