unit ClrScheme;

// ---------------------------------------------------------------------------
//  Цветовая схема подсветки (.clr) - отдельным объектом
//
//  Всё, что задаёт схема: цвета элементов, маркеры комментариев и строк,
//  группы ключевых слов, операторов и отметки строк, форматы чисел, слова
//  подпрограмм и правила форматирования, порядок разделов файла. Разбор
//  файла (ParseClrFile) и запись (SaveClrSchemaTo) работают только с полями
//  схемы; к редактору они не обращаются. Что после них нужно редактору
//  (цвет шрифта, шаг табуляции, карты окон, перерисовка), делает
//  вызывающий - TForm1 с одноимёнными методами.
//
//  Цвет текста схемы - FTextFG. Раньше он жил в RichEdit1.Font.Color.
//
//  Темы. Цвета в заголовках разделов - основная тема (BaseThemeName). Для
//  других тем рядом с разделом - строки только с цветами, без данных:
//    • Operators $00D81CDD $00F9F9F9
//    ()*+,-./:;<=>@[]^{}
//    • Operators@Dark $0080C0FF $001E1E1E
//  Слова и маркеры у раздела одни на все темы. Выбрана тема (FTheme) - после
//  чтения файлов ApplyTheme кладёт её цвета поверх основных; раздела без
//  строки темы это не касается. При записи цвета выбранной темы уходят в её
//  строки, основные остаются основными, строки других тем - как были.
//
//  Вынесено из Unit1: поля и методы - с прежними именами, чтобы код
//  подсветки менялся только приставкой FScheme.
// ---------------------------------------------------------------------------

interface

uses
  SysUtils, Classes, Graphics;

const
  // Тема, цвета которой записаны в заголовках разделов без @
  BaseThemeName = 'Classic Windows';

  // Метка заголовка раздела в файле цветовой схемы (.clr): "•" и неразрывный
  // пробел (CP1251: 149, 160). Строка под заголовком, если это не другой
  // заголовок, - данные раздела; маркер берётся из неё как есть, с пробелами.
  // Метка есть только в файле: при чтении она отрезается, при записи
  // добавляется, в таблице настроек и в KeywordGroups[].Name её нет.
  // Строки без метки заголовками не считаются.
  SchemaHeadMark = #149#160;

type
  // Структура для хранения одного многострочного комментария
  // Пара маркеров блочного комментария. Первая пара живёт в полях
  // FBlockCommentStart/End и FBcFG/FBcBG - она есть всегда; здесь лежат
  // ДОПОЛНИТЕЛЬНЫЕ, из разделов BlockComment2, BlockComment3 и так далее.
  // Нужны языкам, где видов комментариев несколько: в FreeBASIC это /' '/
  // и /* */ в старом коде.
  TBcPair = record
    Name: string;
    StartMark: string;
    EndMark: string;
    FgColor: TColor;
    BgColor: TColor;
  end;
  // Структура для динамической группы ключевых слов
  TKeywordGroup = record
    Name: string;         // Имя секции, например 'Keywords3'
    Words: TStringList;   // Сам список слов
    FgColor: TColor;      // Цвет текста
    BgColor: TColor;      // Цвет фона
  end;
  // Группа операторов: свой набор символов и своя пара цветов. Разделы
  // схемы Operators, Operators2, Operators3, ... - имя раздела и есть имя
  // группы. Символ, попавший в две группы, будет нарисован цветом той, что
  // идёт в файле ниже: группы рисуются по порядку, одна поверх другой.
  TOpGroup = record
    Name: string;
    Chars: TSysCharSet;   // Строка данных раздела - набор символов
    FgColor: TColor;
    BgColor: TColor;
  end;
  // Группа отметки строк: свой список слов и своя пара цветов. Разделы
  // LineMark, LineMark2, ... Строка красится по САМОМУ ЛЕВОМУ слову отметки
  // в ней; если на одной позиции слово есть в двух группах, побеждает та,
  // что в файле выше.
  TMarkGroup = record
    Name: string;
    Words: TStringList;
    FgColor: TColor;
    BgColor: TColor;
  end;

  TClrScheme = class
  public
    // Цвет текста схемы (раздел Text); без раздела - FontColor из editor.ini
    FTextFG: TColor;
    // Ошибка в файле, из-за которой разбор остановился; '' - нет
    FLoadError: string;
    // Выбранная тема; '' - основная (цвета заголовков)
    FTheme: string;
    // Строки тем из файлов: Раздел@Тема=цвет цвет. Нужны и чтобы наложить
    // выбранную тему, и чтобы записать строки всех тем обратно.
    FThemeColors: TStringList;
    // Основные цвета разделов (Раздел=цвет цвет) - какими они прочитаны из
    // заголовков, до наложения темы. По ним пишутся заголовки, пока выбрана
    // другая тема.
    FBaseColors: TStringList;
    // Раздел Text текущей схемы: есть ли он и его цвет текста
    FSchemaHasText: Boolean;
    FSchemaTextFG: TColor;
    // Все символы, из которых состоят маркеры активной схемы, плюс #13 и #10.
    // Если правка их не задела, карту можно просто сдвинуть - см. TryShiftMap.
    FMarkerChars: TSysCharSet;
    FMaxMarkerLen: Integer;
    // ДИНАМИЧЕСКИЙ МАССИВ ГРУПП КЛЮЧЕВЫХ СЛОВ - ЕДИНСТВЕННЫЙ ИСТОЧНИК СЛОВ
    KeywordGroups: array of TKeywordGroup;
    // Группы операторов и группы отметки строк - устроены так же: сколько
    // разделов в схеме, столько и групп, имя раздела - имя группы
    OpGroups: array of TOpGroup;
    MarkGroups: array of TMarkGroup;
    // Динамические настройки активного языка
    FLineCommentMarker: string;
    // Строчный комментарий только в начале строки (до маркера - одни
    // пробелы и табуляции). В файле схемы - знак ^ перед маркером: ^;
    // Так устроен Inno Setup: ; в начале строки - комментарий, в середине -
    // разделитель параметров.
    FLineCommentAtStart: Boolean;
    FBlockCommentStart: string;
    FBlockCommentEnd: string;
    FStringMarker: string;
    // ДОПОЛНИТЕЛЬНЫЕ МАРКЕРЫ ЛИТЕРАЛОВ (разделы Strings2, Strings3 ...).
    // Основной лежит в FStringMarker и FStrFG/FStrBG. В JavaScript нужны
    // сразу три вида кавычек, и у каждой свой цвет. У пары используется
    // только StartMark: литерал закрывается тем же знаком, что открыт.
    FStrExtra: array of TBcPair;
    // Знак экранирования внутри литерала (раздел StrEscape): в C и
    // JavaScript это обратная косая. Пусто - экранирование удвоением
    // маркера, как в Паскале и Бейсике.
    FStrEscape: Char;
    // Какие формы записи чисел понимает активная схема (секция Digits)
    FNumHex0x: Boolean;      // 0x1F
    FNumHexAmp: Boolean;     // &H1F, &O17, &B1010 - BASIC
    FNumExp: Boolean;        // 1e5, 1.5E-3
    FNumSuffix: TSysCharSet; // хвост типа: 100L, 3.14f, 10&
    FPairFG, FPairBG: TColor;
    // ЦВЕТА СИНТАКСИСА ИЗ ФАЙЛА .CLR (цвета операторов - в OpGroups)
    FLcFG, FLcBG: TColor;
    FBcFG, FBcBG: TColor;
    // Дополнительные пары маркеров блочного комментария, см. TBcPair
    FBcExtra: array of TBcPair;
    FStrFG, FStrBG: TColor;
    FDgFG, FDgBG: TColor;
    // 5 настраиваемых уровней кастомных комментариев (индексы 1..5)
    FCustomFG: array[1..5] of TColor;
    FCustomBG: array[1..5] of TColor;
    // ОСНОВНОЙ ТЕКСТ. Цвет - RichEdit1.Font.Color, подложка под символами -
    // FTextBG; оба из раздела Text схемы, без него - из editor.ini (цвет -
    // FontColor, подложка - BGColor). Фон пустого места редактора -
    // RichEdit1.Color, всегда BGColor из editor.ini (см. SetEditorBG).
    FTextBG: TColor;
    FSubWords: TStringList;
    FSubEndWords: TStringList;
    // Слова, открывающие блок (раздел SubOpen схемы): begin, case, record,
    // try. Список не пуст - конец подпрограммы считается по вложенности
    // блоков, а не по первому слову строки: в Паскале тело кончается тем
    // end, который закрывает его begin, а не первым попавшимся end.
    FSubOpenWords: TStringList;
    // Слова, по которым видно, что тела у заголовка не будет (раздел
    // SubNoBody схемы): в Паскале forward и external. Встретилось такое
    // слово до начала тела - запись в списке кончается своей же строкой.
    FSubNoBodyWords: TStringList;
    // Слова, открывающие блок ТОЛЬКО в начале строки (раздел SubOpenFirst).
    // Нужны Бейсику: while открывает цикл в начале строки, но в хвосте
    // 'loop while x' ничего не открывает. Запись вида 'if=then' добавляет
    // условие на последнее слово строки: 'if x then' блок открывает, а
    // однострочное 'if x then y = 1' - нет.
    FSubOpenFirst: TStringList;
    // Модификаторы, которые пропускаются в начале строки при поиске первого
    // значащего слова (раздел SubSkip): Public, Private, Static. Нужны
    // Visual Basic и FreeBASIC, где пишут 'Public Sub Foo'. Declare в этот
    // список не входит: за ним тела нет, и открывать блок он не должен.
    FSubSkip: TStringList;
    // СЛОВА ДЛЯ ФОРМАТИРОВАНИЯ ОТСТУПАМИ (меню Format text).
    // FFmtOutdent - слова, которые пишутся на уровень левее своего блока
    //   (end, until, else, finally, except); глубину они сами не меняют,
    //   её двигают SubOpen и SubEnd.
    // FFmtSection - разделы объявлений (var, type, const, label): то, что
    //   под ними, идёт на уровень правее.
    // FFmtClass - class, object, interface: открывают блок, но только
    //   когда строка не кончается точкой с запятой. Иначе 'class function
    //   TForm1.Foo;' считалось бы открытием блока.
    FFmtOutdent: TStringList;
    FFmtSection: TStringList;
    FFmtClass: TStringList;
    // FFmtStmtEnd - слова, на которых оператор считается законченным
    //   (then, do, of, private, public): следующая строка - не продолжение
    FFmtStmtEnd: TStringList;
    // FFmtHang - слова, после которых идёт оператор без begin (then, do,
    //   else): строка под таким словом уходит на уровень правее
    FFmtHang: TStringList;
    // Знак переноса строки (раздел FmtContinue): в Бейсике это '_' в конце
    // строки. Список не пуст - продолжением считается ТОЛЬКО строка с этим
    // знаком; пуст - продолжение определяется по незаконченному оператору,
    // как в Паскале и C, где оператор кончается точкой с запятой.
    FFmtContinue: TStringList;
    // ЯЗЫКИ БЕЗ ЗНАКА КОНЦА ОПЕРАТОРА (AutoHotkey): оператор - строка.
    // FFmtHangFirst (раздел FmtHangFirst) - слова в начале строки, после
    //   которых один оператор идёт на уровень правее (if, loop, while без
    //   фигурной скобки). Слово с $ на конце (else$, try$) переносит, только
    //   когда оно в строке одно; иначе решает следующее слово: else if.
    // FFmtContinueFirst - начала строк-продолжений (',' '.' '||' 'and'):
    //   такая строка сохраняет свой сдвиг от начала оператора. В файле -
    //   через пробел: запятая здесь сама образец.
    // FFmtLabel - слова конца метки (return, exitapp). Раздел есть -
    //   метка 'Name:' и горячая клавиша '^a::' на верхнем уровне открывают
    //   уровень до такого слова, до следующей метки, директивы '#' или
    //   определения функции.
    FFmtHangFirst: TStringList;
    FFmtContinueFirst: TStringList;
    FFmtLabel: TStringList;
    // Способ разбора: по словам (procedure, sub) или по фигурным скобкам,
    // как в C и .ino - раздел SubStyle схемы
    FSubBraces: Boolean;
    // Разбор по тегам: SubStyle со значением tags. Уровень дают парные
    // <name> и </name>, см. ScanTags.
    FSubTags: Boolean;
    // Теги, которые ничего не открывают: br, img, meta (раздел TagVoid)
    FTagVoid: TStringList;
    // Слово, ниже которого искать подпрограммы (раздел SubScope схемы).
    // В Паскале это implementation: выше него лежат объявления интерфейса и
    // методы классов, тел у них нет. Слова в файле не оказалось - ищем с
    // начала, иначе у .dpr список стал бы пустым. Пусто - раздела в схеме
    // нет, ограничения тоже. На разбор по скобкам не влияет: там телом
    // считается только  { }, и объявление без тела не попадает в список само.
    FSubScope: string;
    // ЗАГОЛОВОК ТЕЛА ПОДПРОГРАММЫ (раздел SubBody схемы): строка из списка
    // FSubs и строка, на которую перешли из панели, красятся этой парой, а не
    // цветами LineMark. Так объявление в interface, которое ловится по словам
    // LineMark, отличается от начала самого тела. Раздела в схеме нет
    // (FSubBodyHasColors = False) - обе строки цветом LineMark, как раньше.
    FSubBodyFG: TColor;
    FSubBodyBG: TColor;
    FSubBodyHasColors: Boolean;
    // ИМЕНА КОМПОНЕНТОВ (раздел Components схемы): объекты формы из .dfm и
    // переменные, которым в тексте присваивается X := TКласс.Create(Self),
    // красятся этой парой. Раздела в схеме нет - подсветки нет.
    FCompFG: TColor;
    FCompBG: TColor;
    FCompHasColors: Boolean;
    // Разделы схемы в том порядке, в каком они лежат в файле .clr. По этому
    // списку окно настроек (Unit2) строит строки таблицы цветов, и по нему же
    // схема пишется обратно - см. ParseClrFile и SaveClrSchemaTo. Раздела нет
    // в файле - нет и строки в таблице, и в файл он не добавляется.
    //
    // FFileSections - разделы ОДНОГО файла, последнего разобранного. Схема
    // читается из двух файлов, и складывает из них общий список
    // LoadCustomClrSchema: порядок берётся у схемы расширения, разделы, что
    // есть только в •default•.clr, идут за ними.
    SchemaSections: TStringList;
    FFileSections: TStringList;

    constructor Create;
    destructor Destroy; override;
    // Цвета раздела по имени (Operators, Keywords2, LineComment, Text...);
    // False - раздела нет или у него нет цветов
    function  SectionColors(const AName: string; var AFg, ABg: TColor): Boolean;
    function  SetSectionColors(const AName: string; AFg, ABg: TColor): Boolean;
    // Цвета выбранной темы (FTheme) - поверх основных. После чтения всех
    // файлов схемы. Результат - сколько разделов получили цвета темы.
    function  ApplyTheme: Integer;
    function  IsCommentLine(const S: string): Boolean;
    // Строка данных раздела LineComment: маркер, с ^ впереди при
    // FLineCommentAtStart. Set разбирает её обратно (none не трогает -
    // это делает SchemaMarkerValue при чтении файла).
    function  LineCommentSchemeText: string;
    procedure SetLineCommentSchemeText(const S: string);
    // Маркер строчного комментария, найденный в AText на позиции MarkPos,
    // действительно открывает комментарий: без FLineCommentAtStart - всегда,
    // с ним - если левее, до начала строки (#13, #10 или начало AText),
    // стоят только пробелы и табуляции. Символ AText[MarkPos] не читается,
    // так что можно передать один префикс строки и MarkPos = Length + 1.
    function  LineCommentPosOk(const AText: string; MarkPos: Integer): Boolean;
    function  MarkersSig: string;
    function  BcStartMark(AKind: Integer): string;
    function  BcEndMark(AKind: Integer): string;
    procedure BcColors(AKind: Integer; var AFg, ABg: TColor);
    procedure BuildMarkerChars;
    // Раздел в таблице схемы, даже если в файле его нет (PairMark): строка
    // есть - цвет можно поменять, и при сохранении раздел допишется
    procedure EnsureSchemaSection(const AName: string);
    procedure ParseDigitFormats(const S: string);
    function  BuildDigitFormats: string;
    procedure SaveClrSchemaTo(const APath: string);
    procedure WriteSchemaSection(SL: TStringList; const AName: string);
    function  DefaultSectionOrder: TStringList;
    procedure ResetSchemaState(AFontColor, ABGColor: TColor);
    procedure ClearKeywordGroups;
    procedure ClearOpGroups;
    procedure ClearMarkGroups;
    function  OpGroupIndex(const AName: string): Integer;
    function  MarkGroupIndex(const AName: string): Integer;
    function  OpCharsStr(AIndex: Integer): string;
    // Нужна окну настроек: строка таблицы для BlockComment2 и дальше
    function  BcExtraIndex(const AName: string): Integer;
    function  StrExtraIndex(const AName: string): Integer;
    function  StrMark(AKind: Integer): string;
    procedure StrColors(AKind: Integer; var AFg, ABg: TColor);
    procedure SetOpChars(AIndex: Integer; const S: string);
    procedure ParseClrFile(const APath: string);
  end;

// Имя темы для FTheme: основная тема и пустое имя - ''
function ThemeKey(const AName: string): string;
// Строка - заголовок раздела (с меткой SchemaHeadMark)
function IsSchemaHead(const S: string): Boolean;
function SchemaMarkerValue(const S: string): string;
function  IsKeywordSection(const AName: string): Boolean;
function  SplitMarkers(const S: string; var AStart, AEnd: string): Boolean;
procedure SetWordsByComma(List: TStringList; const S: string;
                          ATrimEdges: Boolean = False);
function  WordsByComma(List: TStringList): string;
procedure SetWordsBySpace(List: TStringList; const S: string);
function  WordsBySpace(List: TStringList): string;

implementation

function ThemeKey(const AName: string): string;
begin
  Result := Trim(AName);
  if CompareText(Result, BaseThemeName) = 0 then
    Result := '';
end;

constructor TClrScheme.Create;
begin
  inherited Create;
  FThemeColors := TStringList.Create;
  FThemeColors.CaseSensitive := False;
  FBaseColors := TStringList.Create;
  FBaseColors.CaseSensitive := False;
  FTextFG := clBlack;
  FTextBG := TColor($00F9F9F9);
  // Слова отметки строк - без учёта регистра, для быстрого IndexOf
  FSubWords := TStringList.Create;
  FSubWords.Sorted := True;
  FSubWords.Duplicates := dupIgnore;
  FSubWords.CaseSensitive := False;
  FSubEndWords := TStringList.Create;
  FSubEndWords.CaseSensitive := False;
  FSubOpenWords := TStringList.Create;
  FSubOpenWords.Sorted := True;
  FSubOpenWords.Duplicates := dupIgnore;
  FSubOpenWords.CaseSensitive := False;
  FSubNoBodyWords := TStringList.Create;
  FSubNoBodyWords.Sorted := True;
  FSubNoBodyWords.Duplicates := dupIgnore;
  FSubNoBodyWords.CaseSensitive := False;
  // Не Sorted: записи здесь с условием, порядок перебора свой
  FTagVoid := TStringList.Create;
  FTagVoid.Sorted := True;
  FTagVoid.Duplicates := dupIgnore;
  FTagVoid.CaseSensitive := False;
  FSubOpenFirst := TStringList.Create;
  FSubOpenFirst.CaseSensitive := False;
  FSubSkip := TStringList.Create;
  FSubSkip.Sorted := True;
  FSubSkip.Duplicates := dupIgnore;
  FSubSkip.CaseSensitive := False;
  FFmtOutdent := TStringList.Create;
  FFmtOutdent.Sorted := True;
  FFmtOutdent.Duplicates := dupIgnore;
  FFmtOutdent.CaseSensitive := False;
  FFmtSection := TStringList.Create;
  FFmtSection.Sorted := True;
  FFmtSection.Duplicates := dupIgnore;
  FFmtSection.CaseSensitive := False;
  FFmtClass := TStringList.Create;
  FFmtClass.Sorted := True;
  FFmtClass.Duplicates := dupIgnore;
  FFmtClass.CaseSensitive := False;
  FFmtStmtEnd := TStringList.Create;
  FFmtStmtEnd.Sorted := True;
  FFmtStmtEnd.Duplicates := dupIgnore;
  FFmtStmtEnd.CaseSensitive := False;
  FFmtHang := TStringList.Create;
  FFmtHang.Sorted := True;
  FFmtHang.Duplicates := dupIgnore;
  FFmtHang.CaseSensitive := False;
  FFmtContinue := TStringList.Create;
  FFmtContinue.Sorted := True;
  FFmtContinue.Duplicates := dupIgnore;
  FFmtContinue.CaseSensitive := False;
  FFmtHangFirst := TStringList.Create;
  FFmtHangFirst.Sorted := True;
  FFmtHangFirst.Duplicates := dupIgnore;
  FFmtHangFirst.CaseSensitive := False;
  FFmtContinueFirst := TStringList.Create;
  FFmtContinueFirst.Sorted := True;
  FFmtContinueFirst.Duplicates := dupIgnore;
  FFmtContinueFirst.CaseSensitive := False;
  FFmtLabel := TStringList.Create;
  FFmtLabel.Sorted := True;
  FFmtLabel.Duplicates := dupIgnore;
  FFmtLabel.CaseSensitive := False;

  FSubBodyFG := clNone;
  FSubBodyBG := clYellow;
  FSubBodyHasColors := False;
  FCompFG := clNone;
  FCompBG := clNone;
  FCompHasColors := False;

  // Порядок разделов схемы - заполняется при чтении .clr
  SchemaSections := TStringList.Create;
  FFileSections := TStringList.Create;
end;

destructor TClrScheme.Destroy;
begin
  ClearKeywordGroups;
  ClearMarkGroups;
  FSubWords.Free;
  FSubEndWords.Free;
  FSubOpenWords.Free;
  FSubNoBodyWords.Free;
  FSubOpenFirst.Free;
  FTagVoid.Free;
  FSubSkip.Free;
  FFmtOutdent.Free;
  FFmtSection.Free;
  FFmtClass.Free;
  FFmtStmtEnd.Free;
  FFmtHang.Free;
  FFmtContinue.Free;
  FFmtHangFirst.Free;
  FFmtContinueFirst.Free;
  FFmtLabel.Free;
  SchemaSections.Free;
  FFileSections.Free;
  FThemeColors.Free;
  FBaseColors.Free;
  inherited;
end;

function TClrScheme.SectionColors(const AName: string;
                                  var AFg, ABg: TColor): Boolean;
var
  I, G: Integer;
begin
  Result := False;
  G := -1;
  if AName = '' then
    Exit;
  if IsKeywordSection(AName) then
  begin
    for I := 0 to High(KeywordGroups) do
      if (KeywordGroups[I].Words <> nil) and (KeywordGroups[I].Name = AName) then
      begin
        AFg := KeywordGroups[I].FgColor;
        ABg := KeywordGroups[I].BgColor;
        Result := True;
        Exit;
      end;
  end
  else if (Length(AName) >= 9) and (Copy(AName, 1, 9) = 'Operators') then
  begin
    G := OpGroupIndex(AName);
    if G >= 0 then
    begin
      AFg := OpGroups[G].FgColor;
      ABg := OpGroups[G].BgColor;
      Result := True;
    end;
  end
  else if AName = 'LineComment' then
  begin
    AFg := FLcFG;
    ABg := FLcBG;
    Result := True;
  end
  else if AName = 'BlockComment' then
  begin
    AFg := FBcFG;
    ABg := FBcBG;
    Result := True;
  end
  else if (Length(AName) > 12) and (Copy(AName, 1, 12) = 'BlockComment') then
  begin
    G := BcExtraIndex(AName);
    if G >= 0 then
    begin
      AFg := FBcExtra[G].FgColor;
      ABg := FBcExtra[G].BgColor;
      Result := True;
    end;
  end
  else if AName = 'Strings' then
  begin
    AFg := FStrFG;
    ABg := FStrBG;
    Result := True;
  end
  else if (Length(AName) > 7) and (Copy(AName, 1, 7) = 'Strings') then
  begin
    G := StrExtraIndex(AName);
    if G >= 0 then
    begin
      AFg := FStrExtra[G].FgColor;
      ABg := FStrExtra[G].BgColor;
      Result := True;
    end;
  end
  else if AName = 'Digits' then
  begin
    AFg := FDgFG;
    ABg := FDgBG;
    Result := True;
  end
  else if AName = 'Text' then
  begin
    AFg := FTextFG;
    ABg := FTextBG;
    Result := True;
  end
  else if AName = 'PairMark' then
  begin
    AFg := FPairFG;
    ABg := FPairBG;
    Result := True;
  end
  else if (Length(AName) >= 8) and (Copy(AName, 1, 8) = 'LineMark') then
  begin
    G := MarkGroupIndex(AName);
    if G >= 0 then
    begin
      AFg := MarkGroups[G].FgColor;
      ABg := MarkGroups[G].BgColor;
      Result := True;
    end;
  end
  else if AName = 'SubBody' then
  begin
    AFg := FSubBodyFG;
    ABg := FSubBodyBG;
    Result := True;
  end
  else if AName = 'Components' then
  begin
    AFg := FCompFG;
    ABg := FCompBG;
    Result := True;
  end
  else if (Length(AName) > 6) and (Copy(AName, 1, 6) = 'CUSTOM') then
  begin
    G := StrToIntDef(Copy(AName, 7, 1), 0);
    if (G >= 1) and (G <= 5) then
    begin
      AFg := FCustomFG[G];
      ABg := FCustomBG[G];
      Result := True;
    end;
  end;
end;

// Те же разделы, что в SectionColors. Флаги "у раздела есть цвета"
// (FSchemaHasText, FSubBodyHasColors, FCompHasColors) ставятся, как их
// ставит разбор заголовка.
function TClrScheme.SetSectionColors(const AName: string;
                                     AFg, ABg: TColor): Boolean;
var
  I, G: Integer;
begin
  Result := False;
  G := -1;
  if AName = '' then
    Exit;
  if IsKeywordSection(AName) then
  begin
    for I := 0 to High(KeywordGroups) do
      if (KeywordGroups[I].Words <> nil) and (KeywordGroups[I].Name = AName) then
      begin
        KeywordGroups[I].FgColor := AFg;
        KeywordGroups[I].BgColor := ABg;
        Result := True;
        Exit;
      end;
  end
  else if (Length(AName) >= 9) and (Copy(AName, 1, 9) = 'Operators') then
  begin
    G := OpGroupIndex(AName);
    if G >= 0 then
    begin
      OpGroups[G].FgColor := AFg;
      OpGroups[G].BgColor := ABg;
      Result := True;
    end;
  end
  else if AName = 'LineComment' then
  begin
    FLcFG := AFg;
    FLcBG := ABg;
    Result := True;
  end
  else if AName = 'BlockComment' then
  begin
    FBcFG := AFg;
    FBcBG := ABg;
    Result := True;
  end
  else if (Length(AName) > 12) and (Copy(AName, 1, 12) = 'BlockComment') then
  begin
    G := BcExtraIndex(AName);
    if G >= 0 then
    begin
      FBcExtra[G].FgColor := AFg;
      FBcExtra[G].BgColor := ABg;
      Result := True;
    end;
  end
  else if AName = 'Strings' then
  begin
    FStrFG := AFg;
    FStrBG := ABg;
    Result := True;
  end
  else if (Length(AName) > 7) and (Copy(AName, 1, 7) = 'Strings') then
  begin
    G := StrExtraIndex(AName);
    if G >= 0 then
    begin
      FStrExtra[G].FgColor := AFg;
      FStrExtra[G].BgColor := ABg;
      Result := True;
    end;
  end
  else if AName = 'Digits' then
  begin
    FDgFG := AFg;
    FDgBG := ABg;
    Result := True;
  end
  else if AName = 'Text' then
  begin
    FTextFG := AFg;
    FTextBG := ABg;
    FSchemaHasText := True;
    FSchemaTextFG := FTextFG;
    Result := True;
  end
  else if AName = 'PairMark' then
  begin
    FPairFG := AFg;
    FPairBG := ABg;
    Result := True;
  end
  else if (Length(AName) >= 8) and (Copy(AName, 1, 8) = 'LineMark') then
  begin
    G := MarkGroupIndex(AName);
    if G >= 0 then
    begin
      MarkGroups[G].FgColor := AFg;
      MarkGroups[G].BgColor := ABg;
      Result := True;
    end;
  end
  else if AName = 'SubBody' then
  begin
    FSubBodyFG := AFg;
    FSubBodyBG := ABg;
    FSubBodyHasColors := True;
    Result := True;
  end
  else if AName = 'Components' then
  begin
    FCompFG := AFg;
    FCompBG := ABg;
    FCompHasColors := True;
    Result := True;
  end
  else if (Length(AName) > 6) and (Copy(AName, 1, 6) = 'CUSTOM') then
  begin
    G := StrToIntDef(Copy(AName, 7, 1), 0);
    if (G >= 1) and (G <= 5) then
    begin
      FCustomFG[G] := AFg;
      FCustomBG[G] := ABg;
      Result := True;
    end;
  end;
end;

// "цвет цвет" -> два цвета; False - не разобралось
function SplitColorPair(const S: string; var AFg, ABg: TColor): Boolean;
var
  P: Integer;
  T: string;
begin
  Result := False;
  T := Trim(S);
  P := Pos(' ', T);
  if P = 0 then
    Exit;
  try
    AFg := StringToColor(Trim(Copy(T, 1, P - 1)));
    ABg := StringToColor(Trim(Copy(T, P + 1, MaxInt)));
    Result := True;
  except
    // не цвет - строку темы пропускаем
  end;
end;

function TClrScheme.ApplyTheme: Integer;
var
  I, P: Integer;
  Key: string;
  Fg, Bg: TColor;
begin
  Result := 0;
  if FTheme = '' then
    Exit;
  for I := 0 to FThemeColors.Count - 1 do
  begin
    Key := FThemeColors.Names[I];
    P := Pos('@', Key);
    if (P <= 1) or (CompareText(Copy(Key, P + 1, MaxInt), FTheme) <> 0) then
      Continue;
    if SplitColorPair(Copy(FThemeColors[I], Length(FThemeColors.Names[I]) + 2, MaxInt), Fg, Bg) then
      if SetSectionColors(Copy(Key, 1, P - 1), Fg, Bg) then
        Inc(Result);
  end;
end;

// Строка файла схемы - заголовок раздела (с меткой SchemaHeadMark)?
function IsSchemaHead(const S: string): Boolean;
begin
  Result := Copy(S, 1, Length(SchemaHeadMark)) = SchemaHeadMark;
end;

// Значение маркера из строки данных: слово none - маркера нет
function SchemaMarkerValue(const S: string): string;
begin
  if CompareText(S, 'none') = 0 then
    Result := ''
  else
    Result := S;
end;

// Имя раздела - группа ключевых слов (Keywords1, Keywords2, ...)?
function IsKeywordSection(const AName: string): Boolean;
begin
  Result := (Length(AName) >= 8) and (Copy(AName, 1, 8) = 'Keywords');
end;

// Обратно: образцы через запятую. Образец с пробелом по краю берётся в
// кавычки - иначе в файле схемы этот край не отличить от отступа
// Образцы через пробел - для списков, где запятая сама образец
// (FmtContinueFirst)
procedure SetWordsBySpace(List: TStringList; const S: string);
var
  P, Start: Integer;
begin
  if List = nil then
    Exit;
  List.Clear;
  Start := 1;
  for P := 1 to Length(S) + 1 do
    if (P > Length(S)) or (S[P] = ' ') or (S[P] = #9) then
    begin
      if P > Start then
        List.Add(Copy(S, Start, P - Start));
      Start := P + 1;
    end;
end;

function WordsBySpace(List: TStringList): string;
var
  I: Integer;
begin
  Result := '';
  if List = nil then
    Exit;
  for I := 0 to List.Count - 1 do
  begin
    if I > 0 then
      Result := Result + ' ';
    Result := Result + List[I];
  end;
end;

function WordsByComma(List: TStringList): string;
var
  I: Integer;
  Item: string;
begin
  Result := '';
  if List = nil then
    Exit;
  for I := 0 to List.Count - 1 do
  begin
    Item := List[I];
    if (Item <> '') and ((Item[1] = ' ') or (Item[Length(Item)] = ' ')) then
      Item := '"' + Item + '"';
    if I > 0 then
      Result := Result + ',';
    Result := Result + Item;
  end;
end;

// Список образцов из строки: разделитель - ТОЛЬКО запятая. CommaText здесь
// не годится: он режет ещё и по пробелам, из-за чего "end sub" распадалось
// на два образца.
//
// Пробелы образца НЕ снимаются, ни внутри, ни по краям: 'sub' и 'sub ' -
// разные образцы. Исключение - ATrimEdges: его просят разделы, где
// сверяется целое слово, там края смысла не имеют. Если же образец взят в кавычки, берётся то, что между
// ними, а пробелы вокруг кавычек отбрасываются - так пишутся образцы, у
// которых край должен быть пробелом, и так же их писали старые схемы
// ("end sub","end function"). Пустой образец и образец из одних пробелов
// пропускаются: иначе лишняя запятая в конце строки дала бы образец,
// совпадающий с чем угодно.
procedure SetWordsByComma(List: TStringList; const S: string;
  ATrimEdges: Boolean = False);
var
  P, Start: Integer;
  Item, Bare: string;
begin
  if List = nil then
    Exit;
  List.Clear;
  Start := 1;
  for P := 1 to Length(S) + 1 do
    if (P > Length(S)) or (S[P] = ',') then
    begin
      Item := Copy(S, Start, P - Start);
      Start := P + 1;

      Bare := Trim(Item);
      if Bare = '' then
        Continue;
      if (Length(Bare) >= 2) and (Bare[1] = '"') and
         (Bare[Length(Bare)] = '"') then
        Item := Copy(Bare, 2, Length(Bare) - 2);

      // Разделы, где сверяется ЦЕЛОЕ слово, просят снять края: пробел там
      // ничего не задаёт, а образец делает несовпадающим ни с чем, молча.
      // Значимы края только в LineMark - там ищется подстрока.
      if ATrimEdges then
        Item := Trim(Item);

      if Item <> '' then
        List.Add(Item);
    end;
end;

// Два маркера блочного комментария из строки данных: всё до первого
// пробела и всё после него. Разбирать через DelimitedText нельзя: там
// кавычка служебная, и питоновское """ """ превращается в пустую строку.
// False - маркеров не два или стоит none: блочных комментариев нет.
function SplitMarkers(const S: string; var AStart, AEnd: string): Boolean;
var
  P: Integer;
  T: string;
begin
  Result := False;
  AStart := '';
  AEnd := '';

  T := Trim(S);
  if (T = '') or (CompareText(T, 'none') = 0) then
    Exit;

  P := Pos(' ', T);
  if P <= 1 then
    Exit;

  AStart := Copy(T, 1, P - 1);
  AEnd := Trim(Copy(T, P + 1, Length(T)));
  Result := AEnd <> '';
  if not Result then
  begin
    AStart := '';
    AEnd := '';
  end;
end;

// Разделы файла схемы - поверх текущего состояния
procedure TClrScheme.ParseClrFile(const APath: string);
var
  Lines: TStringList;
  I: Integer;
  HeaderStr, TokensStr: string;
  ParamSL: TStringList;
  OpStr, CIdx, K: Integer;
  GroupIdx: Integer; // Переменная для индексации динамических групп ключевых слов
  HasData, Handled: Boolean;
  DataStr, S, SecName: string;
  FgC, BgC: TColor;
begin
  // Список разделов - этого файла и только его: он заполняется заново даже
  // тогда, когда файла нет. Иначе в нём остались бы разделы прошлого файла.
  if FFileSections <> nil then
    FFileSections.Clear;
  FLoadError := '';

  if not FileExists(APath) then
    Exit;

  // =====================================================================
  // ГЛАВНЫЙ ЦИКЛ ПАРСЕРА ФАЙЛА КОНФИГУРАЦИИ СХЕМЫ
  // =====================================================================
  Lines := TStringList.Create;
  ParamSL := TStringList.Create;
  try
    Lines.LoadFromFile(APath);

    // Заголовок раздела начинается с SchemaHeadMark - так строку данных с
    // заголовком не спутать, даже если в маркере есть пробелы
    I := 0;
    while I < Lines.Count do
    begin
      // --- Заголовок (без метки) и строка данных под ним
      if not IsSchemaHead(Lines[I]) then
      begin
        Inc(I); // не заголовок: пустая строка или лишние данные
        Continue;
      end;
      HeaderStr := Trim(Copy(Lines[I], Length(SchemaHeadMark) + 1, MaxInt));
      // Данных может не быть вовсе - следом сразу другой заголовок
      HasData := (I + 1 < Lines.Count) and not IsSchemaHead(Lines[I + 1]);
      if HasData then
        DataStr := Lines[I + 1]
      else
        DataStr := '';

      // Автоматически разбиваем строку заголовка по пробелам
      ParamSL.DelimitedText := HeaderStr;

      // Имя раздела запоминаем СРАЗУ: разбор BlockComment ниже переписывает
      // ParamSL маркерами, и ParamSL[0] там уже не имя раздела
      if ParamSL.Count >= 1 then
        SecName := ParamSL[0]
      else
        SecName := '';

      // Строка темы: Раздел@Тема цвет цвет - только запоминаем; наложит её
      // ApplyTheme, когда все файлы схемы прочитаны. Данных у неё нет.
      if (Pos('@', SecName) > 1) and (ParamSL.Count >= 3) then
      begin
        FThemeColors.Values[SecName] := ParamSL[1] + ' ' + ParamSL[2];
        Inc(I);
        Continue;
      end;

      // -------------------------------------------------------------------
      // Разделы без цветов: список подпрограмм для правой панели.
      // SubList - слова, с которых начинается объявление; SubEnd - слова,
      // которыми оно кончается. Слова с пробелом внутри - в кавычках:
      //   "end sub","end function"
      // -------------------------------------------------------------------
      if (ParamSL.Count >= 1) and
         ((ParamSL[0] = 'SubList') or (ParamSL[0] = 'SubEnd') or
          (ParamSL[0] = 'SubStyle') or (ParamSL[0] = 'SubScope') or
          (ParamSL[0] = 'SubOpen') or (ParamSL[0] = 'SubNoBody') or
          (ParamSL[0] = 'SubOpenFirst') or (ParamSL[0] = 'SubSkip') or
          (ParamSL[0] = 'TagVoid') or (ParamSL[0] = 'StrEscape') or
          (ParamSL[0] = 'FmtOutdent') or (ParamSL[0] = 'FmtSection') or
          (ParamSL[0] = 'FmtClass') or (ParamSL[0] = 'FmtStmtEnd') or
          (ParamSL[0] = 'FmtHang') or (ParamSL[0] = 'FmtContinue') or
          (ParamSL[0] = 'FmtHangFirst') or (ParamSL[0] = 'FmtContinueFirst') or
          (ParamSL[0] = 'FmtLabel')) then
      begin
        Handled := True;
        if ParamSL[0] = 'SubList' then
          SetWordsByComma(FSubWords, DataStr, True)
        else if ParamSL[0] = 'SubStyle' then
        begin
          // braces - функции как в C: имя, скобки и тело в { };
          // tags - вложенность по парным тегам, как в HTML
          FSubBraces := CompareText(Trim(DataStr), 'braces') = 0;
          FSubTags := CompareText(Trim(DataStr), 'tags') = 0;
        end
        else if ParamSL[0] = 'TagVoid' then
          // Теги без содержимого: уровня не дают
          SetWordsByComma(FTagVoid, DataStr, True)
        else if ParamSL[0] = 'StrEscape' then
        begin
          // Знак экранирования внутри литерала: обратная косая в C и
          // JavaScript. Пусто - экранирование удвоением маркера.
          S := Trim(DataStr);
          if S = '' then
            FStrEscape := #0
          else
            FStrEscape := S[1];
        end
        else if ParamSL[0] = 'SubScope' then
          // Слово, ниже которого искать: в Паскале implementation
          FSubScope := Trim(DataStr)
        else if ParamSL[0] = 'SubOpen' then
          // Слова открытия блока: с ними конец считается по вложенности
          SetWordsByComma(FSubOpenWords, DataStr, True)
        else if ParamSL[0] = 'SubNoBody' then
          // Слова, после которых тела не будет: forward, external
          SetWordsByComma(FSubNoBodyWords, DataStr, True)
        else if ParamSL[0] = 'SubSkip' then
          // Модификаторы начала строки: Public, Private, Static
          SetWordsByComma(FSubSkip, DataStr, True)
        else if ParamSL[0] = 'SubOpenFirst' then
          // Открывают блок только в начале строки; 'слово=хвост' добавляет
          // условие на последнее слово строки
          SetWordsByComma(FSubOpenFirst, DataStr, True)
        else if ParamSL[0] = 'FmtOutdent' then
          SetWordsByComma(FFmtOutdent, DataStr, True)
        else if ParamSL[0] = 'FmtSection' then
          SetWordsByComma(FFmtSection, DataStr, True)
        else if ParamSL[0] = 'FmtClass' then
          SetWordsByComma(FFmtClass, DataStr, True)
        else if ParamSL[0] = 'FmtStmtEnd' then
          SetWordsByComma(FFmtStmtEnd, DataStr, True)
        else if ParamSL[0] = 'FmtHang' then
          SetWordsByComma(FFmtHang, DataStr, True)
        else if ParamSL[0] = 'FmtContinue' then
          SetWordsByComma(FFmtContinue, DataStr, True)
        else if ParamSL[0] = 'FmtHangFirst' then
          SetWordsByComma(FFmtHangFirst, DataStr, True)
        else if ParamSL[0] = 'FmtContinueFirst' then
          SetWordsBySpace(FFmtContinueFirst, DataStr)
        else if ParamSL[0] = 'FmtLabel' then
          SetWordsByComma(FFmtLabel, DataStr, True)
        else
          SetWordsByComma(FSubEndWords, DataStr, True);
        if FFileSections.IndexOf(SecName) < 0 then
          FFileSections.Add(SecName);
        if Handled and HasData then
          Inc(I);
        Inc(I);
        Continue;
      end;

      Handled := ParamSL.Count >= 3;
      if Handled then
      begin
        // -----------------------------------------------------------------
        // ГРУППЫ КЛЮЧЕВЫХ СЛОВ: Keywords1, Keywords2, ...
        // -----------------------------------------------------------------
        if (Length(ParamSL[0]) >= 8) and (Copy(ParamSL[0], 1, 8) = 'Keywords') then
        begin
          SetLength(KeywordGroups, Length(KeywordGroups) + 1);
          GroupIdx := High(KeywordGroups);

          KeywordGroups[GroupIdx].Name := ParamSL[0];
          KeywordGroups[GroupIdx].FgColor := StringToColor(ParamSL[1]);
          KeywordGroups[GroupIdx].BgColor := StringToColor(ParamSL[2]);

          // Список слов для быстрого бинарного поиска
          KeywordGroups[GroupIdx].Words := TStringList.Create;
          KeywordGroups[GroupIdx].Words.Sorted := True;
          KeywordGroups[GroupIdx].Words.Duplicates := dupIgnore;
          KeywordGroups[GroupIdx].Words.CaseSensitive := False;
          KeywordGroups[GroupIdx].Words.CommaText := DataStr;
        end
        // -----------------------------------------------------------------
        // ОПЕРАТОРЫ: строка данных - набор символов
        // -----------------------------------------------------------------
        else if (Length(ParamSL[0]) >= 9) and
                (Copy(ParamSL[0], 1, 9) = 'Operators') then
        begin
          // Раздел с таким именем уже читался (например, из •default•.clr) -
          // обновляем ту же группу, а не заводим вторую
          GroupIdx := OpGroupIndex(ParamSL[0]);
          if GroupIdx < 0 then
          begin
            SetLength(OpGroups, Length(OpGroups) + 1);
            GroupIdx := High(OpGroups);
            OpGroups[GroupIdx].Name := ParamSL[0];
          end;
          OpGroups[GroupIdx].FgColor := StringToColor(ParamSL[1]);
          OpGroups[GroupIdx].BgColor := StringToColor(ParamSL[2]);
          if HasData then
          begin
            TokensStr := Trim(DataStr);
            OpGroups[GroupIdx].Chars := [];
            for OpStr := 1 to Length(TokensStr) do
              Include(OpGroups[GroupIdx].Chars, TokensStr[OpStr]);
          end;
        end
        // -----------------------------------------------------------------
        // СТРОЧНЫЙ КОММЕНТАРИЙ (//)
        // -----------------------------------------------------------------
        else if ParamSL[0] = 'LineComment' then
        begin
          FLcFG := StringToColor(ParamSL[1]);
          FLcBG := StringToColor(ParamSL[2]);
          // Маркер - строка целиком, как есть. Пустая или none - строчных
          // комментариев в языке нет; RebuildCommentRangeMap их не ищет.
          // ^ перед маркером - комментарий только в начале строки (^; у
          // Inno Setup), см. FLineCommentAtStart
          SetLineCommentSchemeText(SchemaMarkerValue(DataStr));
        end
        // -----------------------------------------------------------------
        // БЛОЧНЫЙ КОММЕНТАРИЙ: два маркера через пробел
        // -----------------------------------------------------------------
        else if (Length(ParamSL[0]) > 12) and
                (Copy(ParamSL[0], 1, 12) = 'BlockComment') then
        begin
          // Дополнительная пара маркеров: BlockComment2 и дальше
          GroupIdx := -1;
          for K := 0 to High(FBcExtra) do
            if FBcExtra[K].Name = ParamSL[0] then
            begin
              GroupIdx := K;
              Break;
            end;
          if GroupIdx < 0 then
          begin
            SetLength(FBcExtra, Length(FBcExtra) + 1);
            GroupIdx := High(FBcExtra);
            FBcExtra[GroupIdx].Name := ParamSL[0];
          end;
          FBcExtra[GroupIdx].FgColor := StringToColor(ParamSL[1]);
          FBcExtra[GroupIdx].BgColor := StringToColor(ParamSL[2]);

          SplitMarkers(DataStr, FBcExtra[GroupIdx].StartMark,
                       FBcExtra[GroupIdx].EndMark);
        end
        else if ParamSL[0] = 'BlockComment' then
        begin
          FBcFG := StringToColor(ParamSL[1]);
          FBcBG := StringToColor(ParamSL[2]);

          // Пустая строка данных и none - блочных комментариев в языке нет
          if not SplitMarkers(DataStr, FBlockCommentStart, FBlockCommentEnd) then
            if (Trim(DataStr) <> '') and
               (CompareText(Trim(DataStr), 'none') <> 0) then
            begin
              // Сообщение показывает вызывающий (TForm1.ParseClrFile)
              FLoadError := 'Schema error! "BlockComment" section expects ' +
                            'both start and end markers (e.g. "/* */").';
              Break;
            end;
        end
        // -----------------------------------------------------------------
        // СТРОКОВЫЕ ЛИТЕРАЛЫ ('...')
        // -----------------------------------------------------------------
        else if (Length(ParamSL[0]) > 7) and
                (Copy(ParamSL[0], 1, 7) = 'Strings') then
        begin
          // Дополнительный маркер литерала: Strings2 и дальше
          GroupIdx := StrExtraIndex(ParamSL[0]);
          if GroupIdx < 0 then
          begin
            SetLength(FStrExtra, Length(FStrExtra) + 1);
            GroupIdx := High(FStrExtra);
            FStrExtra[GroupIdx].Name := ParamSL[0];
          end;
          FStrExtra[GroupIdx].FgColor := StringToColor(ParamSL[1]);
          FStrExtra[GroupIdx].BgColor := StringToColor(ParamSL[2]);
          FStrExtra[GroupIdx].StartMark := SchemaMarkerValue(DataStr);
          FStrExtra[GroupIdx].EndMark := FStrExtra[GroupIdx].StartMark;
        end
        else if ParamSL[0] = 'Strings' then
        begin
          FStrFG := StringToColor(ParamSL[1]);
          FStrBG := StringToColor(ParamSL[2]);
          // Как у строчного комментария: как есть, пустая или none - строк нет
          FStringMarker := SchemaMarkerValue(DataStr);
        end
        // -----------------------------------------------------------------
        // ЧИСЛА (Digits): строка данных - формы записи
        // -----------------------------------------------------------------
        else if ParamSL[0] = 'Digits' then
        begin
          FDgFG := StringToColor(ParamSL[1]);
          FDgBG := StringToColor(ParamSL[2]);
          if HasData then
            ParseDigitFormats(Trim(DataStr));
        end
        // -----------------------------------------------------------------
        // ОСНОВНОЙ ТЕКСТ: Text <цвет текста> <подложка под символами>
        // Цвет перекрывает FontColor из editor.ini.
        // -----------------------------------------------------------------
        else if (ParamSL[0] = 'Text') or (ParamSL[0] = 'Font') then
        begin
          // Фон пустого места (RichEdit1.Color) схема не трогает - он из
          // editor.ini; второй цвет раздела - подложка под символами
          if ParamSL[0] = 'Text' then
          begin
            FTextFG := StringToColor(ParamSL[1]);
            FTextBG := StringToColor(ParamSL[2]);
          end
          else
          begin
            // Прежний раздел Font <размер> <цвет> [<фон>] - из него только
            // цвета; размер и имя шрифта общие и лежат в editor.ini
            FTextFG := StringToColor(ParamSL[2]);
            if ParamSL.Count >= 4 then
              FTextBG := StringToColor(ParamSL[3]);
          end;
          FSchemaHasText := True;
          FSchemaTextFG := FTextFG;
          // Цвет шрифта редактора и геометрию строк под него ставит
          // вызывающий (TForm1.ParseClrFile) - по FSchemaHasText

        end
        // -----------------------------------------------------------------
        // УРОВНИ КОММЕНТАРИЕВ CUSTOM1 .. CUSTOM5
        // -----------------------------------------------------------------
        // -----------------------------------------------------------------
        // ОТМЕТКА СТРОК: LineMark <цвет текста или clNone> <фон строки>,
        // строка данных - слова через запятую
        // -----------------------------------------------------------------
        else if ParamSL[0] = 'PairMark' then
        begin
          // Цвета пары под кареткой: скобка со скобкой, тег с тегом
          FPairFG := StringToColor(ParamSL[1]);
          FPairBG := StringToColor(ParamSL[2]);
        end
        else if (Length(ParamSL[0]) >= 8) and
                (Copy(ParamSL[0], 1, 8) = 'LineMark') then
        begin
          GroupIdx := MarkGroupIndex(ParamSL[0]);
          if GroupIdx < 0 then
          begin
            SetLength(MarkGroups, Length(MarkGroups) + 1);
            GroupIdx := High(MarkGroups);
            MarkGroups[GroupIdx].Name := ParamSL[0];
            MarkGroups[GroupIdx].Words := TStringList.Create;
            MarkGroups[GroupIdx].Words.Sorted := True;
            MarkGroups[GroupIdx].Words.Duplicates := dupIgnore;
            MarkGroups[GroupIdx].Words.CaseSensitive := False;
          end;
          MarkGroups[GroupIdx].FgColor := StringToColor(ParamSL[1]);
          MarkGroups[GroupIdx].BgColor := StringToColor(ParamSL[2]);
          SetWordsByComma(MarkGroups[GroupIdx].Words, DataStr);
        end
        // Заголовок тела подпрограммы: только цвета, строки данных нет
        else if ParamSL[0] = 'SubBody' then
        begin
          FSubBodyFG := StringToColor(ParamSL[1]);
          FSubBodyBG := StringToColor(ParamSL[2]);
          FSubBodyHasColors := True;
        end
        // Имена компонентов: только цвета, список собирается сам
        else if ParamSL[0] = 'Components' then
        begin
          FCompFG := StringToColor(ParamSL[1]);
          FCompBG := StringToColor(ParamSL[2]);
          FCompHasColors := True;
        end
        else if (Length(ParamSL[0]) > 6) and (Copy(ParamSL[0], 1, 6) = 'CUSTOM') then
        begin
          CIdx := StrToIntDef(Copy(ParamSL[0], 7, 1), 0);
          if (CIdx >= 1) and (CIdx <= 5) then
          begin
            FCustomFG[CIdx] := StringToColor(ParamSL[1]);
            FCustomBG[CIdx] := StringToColor(ParamSL[2]);
          end;
        end
        else
          Handled := False; // неизвестный раздел - его строку не трогаем
      end;

      // Раздел разобран - запоминаем его место в файле. Устаревшее имя Font
      // пишется как Text: раздел тот же самый.
      if Handled then
      begin
        if SecName = 'Font' then
          SecName := 'Text';
        if FFileSections.IndexOf(SecName) < 0 then
          FFileSections.Add(SecName);
        // Основные цвета раздела - до наложения темы
        if SectionColors(SecName, FgC, BgC) then
          FBaseColors.Values[SecName] := ColorToString(FgC) + ' ' +
                                         ColorToString(BgC);
      end;

      // Строка данных известного раздела разобрана - перешагиваем её
      if Handled and HasData then
        Inc(I);
      Inc(I);
    end;
  finally
    // Блок гарантированно выполнится при любых ошибках, память чиста!
    ParamSL.Free;
    Lines.Free;
  end;

end;

// Состояние схемы - к встроенным умолчаниям; группы ключевых слов - пустые
procedure TClrScheme.ResetSchemaState(AFontColor, ABGColor: TColor);
var
  GroupIdx, CIdx: Integer;
begin
  // Разделов нет, пока их не прочитает ParseClrFile
  if SchemaSections <> nil then
    SchemaSections.Clear;
  // Строки тем и основные цвета - только из файлов, прочитанных после сброса
  FThemeColors.Clear;
  FBaseColors.Clear;

  // Списка подпрограмм и отметки строк нет, пока их не задаст схема
  if FSubWords <> nil then
    FSubWords.Clear;
  if FSubEndWords <> nil then
    FSubEndWords.Clear;
  if FSubOpenWords <> nil then
    FSubOpenWords.Clear;
  if FSubNoBodyWords <> nil then
    FSubNoBodyWords.Clear;
  if FSubOpenFirst <> nil then
    FSubOpenFirst.Clear;
  if FSubSkip <> nil then
    FSubSkip.Clear;
  if FFmtOutdent <> nil then
    FFmtOutdent.Clear;
  if FFmtSection <> nil then
    FFmtSection.Clear;
  if FFmtClass <> nil then
    FFmtClass.Clear;
  if FFmtStmtEnd <> nil then
    FFmtStmtEnd.Clear;
  if FFmtHang <> nil then
    FFmtHang.Clear;
  if FFmtContinue <> nil then
    FFmtContinue.Clear;
  if FFmtHangFirst <> nil then
    FFmtHangFirst.Clear;
  if FFmtContinueFirst <> nil then
    FFmtContinueFirst.Clear;
  if FFmtLabel <> nil then
    FFmtLabel.Clear;
  FSubBraces := False;
  FSubTags := False;
  if FTagVoid <> nil then
    FTagVoid.Clear;
  FSubScope := '';
  ClearMarkGroups;
  FPairFG := clNone;
  FPairBG := $0080FFFF;
  FSubBodyFG := clNone;
  FSubBodyBG := clYellow;
  FSubBodyHasColors := False;
  FCompFG := clNone;
  FCompBG := clNone;
  FCompHasColors := False;

  // =====================================================================
  // ОЧИСТКА ДИНАМИЧЕСКИХ ГРУПП КЛЮЧЕВЫХ СЛОВ
  // =====================================================================
  // Перед загрузкой новой схемы обязательно освобождаем память старых TStringList
  for GroupIdx := 0 to High(KeywordGroups) do
  begin
    if KeywordGroups[GroupIdx].Words <> nil then
      KeywordGroups[GroupIdx].Words.Free;
  end;
  SetLength(KeywordGroups, 0); // Обнуляем динамический массив
  ClearOpGroups;

  // =====================================================================
  // ИНИЦИАЛИЗАЦИЯ БЕЗОПАСНЫХ ДЕФОЛТНЫХ ЗНАЧЕНИЙ (НА СЛУЧАЙ ОТСУТСТВИЯ ФАЙЛА)
  // =====================================================================
  for CIdx := 1 to 5 do
  begin
    FCustomFG[CIdx] := $00FF80FF; // Розово-фиолетовый по умолчанию
    FCustomBG[CIdx] := clRed;      // Красный фон по умолчанию
  end;

  // Базовые цвета - из editor.ini; раздел Text схемы перекроет цвет текста
  // и подложку под ним. Фон пустого места - всегда BGColor. Раньше схема
  // без цветового раздела оставляла цвета от предыдущей схемы.
  // Сбрасываются ДО умолчаний ниже: фоны элементов берутся из FTextBG.
  // Цвет текста и фон пустого места редактору ставит вызывающий
  // (TForm1.ResetSchemaState) - по FTextFG и своему BGColor
  FTextFG := AFontColor;
  FTextBG := ABGColor;
  FSchemaHasText := False;

  // Безопасные дефолты синтаксиса
  FLineCommentMarker := '//';
  FLineCommentAtStart := False;
  FBlockCommentStart := '/*';
  FBlockCommentEnd := '*/';
  SetLength(FBcExtra, 0);
  // Одна группа операторов по умолчанию - на случай схемы без раздела
  SetLength(OpGroups, 1);
  OpGroups[0].Name := 'Operators';
  OpGroups[0].Chars := ['+', '-', '*', '/', '=', '<', '>', '(', ')', '[', ']', '{', '}', '.', ',', ';', ':', '@', '^'];
  OpGroups[0].FgColor := $00D81CDD;
  OpGroups[0].BgColor := FTextBG;

  FLcFG := clGreen;        FLcBG := FTextBG;
  FBcFG := $00008000;      FBcBG := FTextBG;
  FDgFG := clRed;          FDgBG := clWhite;
  FStringMarker := '''';  FStrFG := $00008CFF;   FStrBG := FTextBG;
  SetLength(FStrExtra, 0);
  FStrEscape := #0;
  ParseDigitFormats(''); // формы записи чисел по умолчанию
  BuildMarkerChars;      // набор опасных символов - под эти умолчания

end;

// Один раздел схемы - в строки файла: заголовок с меткой SchemaHeadMark и,
// у большинства разделов, строка данных под ним. Раздел, которому в текущем
// состоянии ничего не отвечает (удалённая группа ключевых слов, незнакомое
// имя), не пишется вовсе.
procedure TClrScheme.WriteSchemaSection(SL: TStringList; const AName: string);
var
  I, G, CIdx: Integer;
begin
  if AName = '' then
    Exit;

  // ГРУППЫ КЛЮЧЕВЫХ СЛОВ - ищем по имени: после удаления групп имена идут
  // не подряд, и номер в имени уже не равен индексу в массиве
  if IsKeywordSection(AName) then
  begin
    G := -1;
    for I := 0 to High(KeywordGroups) do
      if (KeywordGroups[I].Words <> nil) and (KeywordGroups[I].Name = AName) then
      begin
        G := I;
        Break;
      end;
    if G < 0 then
      Exit;
    SL.Add(SchemaHeadMark + AName + ' ' +
           ColorToString(KeywordGroups[G].FgColor) + ' ' +
           ColorToString(KeywordGroups[G].BgColor));
    SL.Add(KeywordGroups[G].Words.CommaText);
  end
  // ОПЕРАТОРЫ: строка данных - набор символов, собранный обратно из множества
  else if (Length(AName) >= 9) and (Copy(AName, 1, 9) = 'Operators') then
  begin
    G := OpGroupIndex(AName);
    if G < 0 then
      Exit;
    SL.Add(SchemaHeadMark + AName + ' ' + ColorToString(OpGroups[G].FgColor) +
           ' ' + ColorToString(OpGroups[G].BgColor));
    SL.Add(OpCharsStr(G));
  end
  // Маркер - строкой как есть: заголовки помечены SchemaHeadMark, так что
  // пробелы в маркере разбору не мешают, а пустая строка означает, что
  // строчных комментариев в языке нет
  else if AName = 'LineComment' then
  begin
    SL.Add(SchemaHeadMark + 'LineComment ' + ColorToString(FLcFG) + ' ' +
           ColorToString(FLcBG));
    SL.Add(LineCommentSchemeText);
  end
  else if AName = 'BlockComment' then
  begin
    SL.Add(SchemaHeadMark + 'BlockComment ' + ColorToString(FBcFG) + ' ' +
           ColorToString(FBcBG));
    SL.Add(FBlockCommentStart + ' ' + FBlockCommentEnd);
  end
  // Дополнительные пары маркеров: BlockComment2 и дальше
  else if (Length(AName) > 12) and (Copy(AName, 1, 12) = 'BlockComment') then
  begin
    G := -1;
    for I := 0 to High(FBcExtra) do
      if FBcExtra[I].Name = AName then
      begin
        G := I;
        Break;
      end;
    if G < 0 then
      Exit;
    SL.Add(SchemaHeadMark + AName + ' ' + ColorToString(FBcExtra[G].FgColor) +
           ' ' + ColorToString(FBcExtra[G].BgColor));
    if FBcExtra[G].StartMark = '' then
      SL.Add('none')
    else
      SL.Add(FBcExtra[G].StartMark + ' ' + FBcExtra[G].EndMark);
  end
  else if AName = 'Strings' then
  begin
    SL.Add(SchemaHeadMark + 'Strings ' + ColorToString(FStrFG) + ' ' +
           ColorToString(FStrBG));
    SL.Add(FStringMarker);
  end
  // Дополнительные маркеры литералов: Strings2 и дальше
  else if (Length(AName) > 7) and (Copy(AName, 1, 7) = 'Strings') then
  begin
    G := StrExtraIndex(AName);
    if G < 0 then
      Exit;
    SL.Add(SchemaHeadMark + AName + ' ' + ColorToString(FStrExtra[G].FgColor) +
           ' ' + ColorToString(FStrExtra[G].BgColor));
    if FStrExtra[G].StartMark = '' then
      SL.Add('none')
    else
      SL.Add(FStrExtra[G].StartMark);
  end
  else if AName = 'StrEscape' then
  begin
    SL.Add(SchemaHeadMark + 'StrEscape');
    if FStrEscape = #0 then
      SL.Add('')
    else
      SL.Add(FStrEscape);
  end
  // Список допустимых форм записи чисел. Строка обязательна: загрузчик
  // сдвигается на неё через Inc(I), пустота сломала бы разбор файла.
  else if AName = 'Digits' then
  begin
    SL.Add(SchemaHeadMark + 'Digits ' + ColorToString(FDgFG) + ' ' +
           ColorToString(FDgBG));
    SL.Add(BuildDigitFormats);
  end
  // УРОВНИ КОММЕНТАРИЕВ CUSTOM1 .. CUSTOM5
  else if (Length(AName) > 6) and (Copy(AName, 1, 6) = 'CUSTOM') then
  begin
    CIdx := StrToIntDef(Copy(AName, 7, 1), 0);
    if (CIdx < 1) or (CIdx > 5) then
      Exit;
    SL.Add(SchemaHeadMark + AName + ' ' + ColorToString(FCustomFG[CIdx]) +
           ' ' + ColorToString(FCustomBG[CIdx]));
    SL.Add(StringOfChar('!', CIdx));
  end
  // Разделы без цветов: слова начала и конца объявления и способ разбора
  else if AName = 'SubList' then
  begin
    SL.Add(SchemaHeadMark + 'SubList');
    SL.Add(WordsByComma(FSubWords));
  end
  else if AName = 'SubEnd' then
  begin
    SL.Add(SchemaHeadMark + 'SubEnd');
    SL.Add(WordsByComma(FSubEndWords));
  end
  else if AName = 'SubOpen' then
  begin
    SL.Add(SchemaHeadMark + 'SubOpen');
    SL.Add(WordsByComma(FSubOpenWords));
  end
  else if AName = 'SubNoBody' then
  begin
    SL.Add(SchemaHeadMark + 'SubNoBody');
    SL.Add(WordsByComma(FSubNoBodyWords));
  end
  else if AName = 'SubOpenFirst' then
  begin
    SL.Add(SchemaHeadMark + 'SubOpenFirst');
    SL.Add(WordsByComma(FSubOpenFirst));
  end
  else if AName = 'SubSkip' then
  begin
    SL.Add(SchemaHeadMark + 'SubSkip');
    SL.Add(WordsByComma(FSubSkip));
  end
  else if AName = 'FmtOutdent' then
  begin
    SL.Add(SchemaHeadMark + 'FmtOutdent');
    SL.Add(WordsByComma(FFmtOutdent));
  end
  else if AName = 'FmtSection' then
  begin
    SL.Add(SchemaHeadMark + 'FmtSection');
    SL.Add(WordsByComma(FFmtSection));
  end
  else if AName = 'FmtClass' then
  begin
    SL.Add(SchemaHeadMark + 'FmtClass');
    SL.Add(WordsByComma(FFmtClass));
  end
  else if AName = 'FmtStmtEnd' then
  begin
    SL.Add(SchemaHeadMark + 'FmtStmtEnd');
    SL.Add(WordsByComma(FFmtStmtEnd));
  end
  else if AName = 'FmtHang' then
  begin
    SL.Add(SchemaHeadMark + 'FmtHang');
    SL.Add(WordsByComma(FFmtHang));
  end
  else if AName = 'FmtContinue' then
  begin
    SL.Add(SchemaHeadMark + 'FmtContinue');
    SL.Add(WordsByComma(FFmtContinue));
  end
  else if AName = 'FmtHangFirst' then
  begin
    SL.Add(SchemaHeadMark + 'FmtHangFirst');
    SL.Add(WordsByComma(FFmtHangFirst));
  end
  else if AName = 'FmtContinueFirst' then
  begin
    SL.Add(SchemaHeadMark + 'FmtContinueFirst');
    SL.Add(WordsBySpace(FFmtContinueFirst));
  end
  else if AName = 'FmtLabel' then
  begin
    SL.Add(SchemaHeadMark + 'FmtLabel');
    SL.Add(WordsByComma(FFmtLabel));
  end
  else if AName = 'SubStyle' then
  begin
    SL.Add(SchemaHeadMark + 'SubStyle');
    if FSubBraces then
      SL.Add('braces')
    else if FSubTags then
      SL.Add('tags')
    else
      SL.Add('words');
  end
  else if AName = 'TagVoid' then
  begin
    SL.Add(SchemaHeadMark + 'TagVoid');
    SL.Add(WordsByComma(FTagVoid));
  end
  else if AName = 'SubScope' then
  begin
    SL.Add(SchemaHeadMark + 'SubScope');
    SL.Add(FSubScope);
  end
  else if AName = 'PairMark' then
    SL.Add(SchemaHeadMark + 'PairMark ' + ColorToString(FPairFG) + ' ' +
           ColorToString(FPairBG))
  // Отметка строк: цвета нужны и без списка слов - ими подсвечивается строка,
  // на которую перешли из списка подпрограмм
  else if (Length(AName) >= 8) and (Copy(AName, 1, 8) = 'LineMark') then
  begin
    G := MarkGroupIndex(AName);
    if G < 0 then
      Exit;
    SL.Add(SchemaHeadMark + AName + ' ' +
           ColorToString(MarkGroups[G].FgColor) + ' ' +
           ColorToString(MarkGroups[G].BgColor));
    SL.Add(WordsByComma(MarkGroups[G].Words));
  end
  // Заголовок тела подпрограммы: только цвета, строки данных у раздела нет
  else if AName = 'SubBody' then
    SL.Add(SchemaHeadMark + 'SubBody ' + ColorToString(FSubBodyFG) + ' ' +
           ColorToString(FSubBodyBG))
  // Имена компонентов: только цвета, список строится по .dfm и тексту
  else if AName = 'Components' then
    SL.Add(SchemaHeadMark + 'Components ' + ColorToString(FCompFG) + ' ' +
           ColorToString(FCompBG))
  // Основной текст: цвет (перекрывает FontColor из editor.ini) и подложка под
  // символами. Фон пустого места в схему не пишется - он в editor.ini.
  // Строки данных у раздела нет. Имя и размер шрифта - тоже в editor.ini.
  else if AName = 'Text' then
    SL.Add(SchemaHeadMark + 'Text ' + ColorToString(FTextFG) +
           ' ' + ColorToString(FTextBG));
end;

// Текущее состояние схемы - в файл APath (схема расширения или
// •default•.clr)
procedure TClrScheme.SaveClrSchemaTo(const APath: string);
var
  SL, Order: TStringList;
  ClrPath: string;
  I, N0: Integer;

  // Раздел AName записан в SL начиная со строки AHead. Выбрана не основная
  // тема - заголовку возвращаются основные цвета, а цвета темы уходят в её
  // строку (если они другие или строка уже была). Затем - строки всех тем
  // этого раздела.
  procedure WriteThemeLines(SL: TStringList; const AName: string;
                            AHead: Integer);
  var
    K: Integer;
    Fg, Bg: TColor;
    Cur, Base, Key: string;
  begin
    if not SectionColors(AName, Fg, Bg) then
      Exit;
    Cur := ColorToString(Fg) + ' ' + ColorToString(Bg);
    if FTheme = '' then
      FBaseColors.Values[AName] := Cur
    else
    begin
      Base := FBaseColors.Values[AName];
      if Base = '' then
        Base := Cur;           // раздел появился уже под темой
      SL[AHead] := SchemaHeadMark + AName + ' ' + Base;
      Key := AName + '@' + FTheme;
      if (Cur <> Base) or (FThemeColors.IndexOfName(Key) >= 0) then
        FThemeColors.Values[Key] := Cur;
    end;
    for K := 0 to FThemeColors.Count - 1 do
      if CompareText(Copy(FThemeColors.Names[K], 1, Length(AName) + 1),
                     AName + '@') = 0 then
        SL.Add(SchemaHeadMark + FThemeColors.Names[K] + ' ' +
               Copy(FThemeColors[K], Length(FThemeColors.Names[K]) + 2, MaxInt));
  end;

begin
  ClrPath := APath;

  SL := TStringList.Create;
  Order := nil;
  try
    // Разделы пишутся в том порядке, в каком были прочитаны из файла, и
    // только те, что в нём были. Пусто в SchemaSections - схема пишется
    // впервые, порядок берём встроенный.
    if (SchemaSections <> nil) and (SchemaSections.Count > 0) then
      Order := SchemaSections
    else
      Order := DefaultSectionOrder;

    for I := 0 to Order.Count - 1 do
    begin
      N0 := SL.Count;
      WriteSchemaSection(SL, Order[I]);
      if SL.Count > N0 then
        WriteThemeLines(SL, Order[I], N0);
    end;

    // Сохраняем файл схемы на диск
    SL.SaveToFile(ClrPath);
  finally
    // DefaultSectionOrder отдаёт СВОЙ список - его и освобождаем; сам
    // SchemaSections живёт до закрытия программы
    if (Order <> nil) and (Order <> SchemaSections) then
      Order.Free;
    SL.Free;
  end;

  // Карты окон, карта комментариев и перерисовка - у вызывающего
  // (TForm1.SaveClrSchemaTo)
end;

// Порядок разделов для схемы, которой на диске ещё не было: в SchemaSections
// пусто, а записать её всё равно нужно. Тот же порядок, каким схемы писались
// до того, как порядок стал браться из файла. Список создаётся здесь -
// освобождает его вызывающий.
function TClrScheme.DefaultSectionOrder: TStringList;
var
  I: Integer;
begin
  Result := TStringList.Create;
  for I := 0 to High(KeywordGroups) do
    if KeywordGroups[I].Words <> nil then
      Result.Add(KeywordGroups[I].Name);
  for I := 0 to High(OpGroups) do
    Result.Add(OpGroups[I].Name);
  Result.Add('LineComment');
  Result.Add('BlockComment');
  for I := 0 to High(FBcExtra) do
    Result.Add(FBcExtra[I].Name);
  Result.Add('Strings');
  for I := 0 to High(FStrExtra) do
    Result.Add(FStrExtra[I].Name);
  if FStrEscape <> #0 then
    Result.Add('StrEscape');
  Result.Add('Digits');
  for I := 1 to 5 do
    Result.Add('CUSTOM' + IntToStr(I));
  if FSubWords.Count > 0 then
    Result.Add('SubList');
  if FSubEndWords.Count > 0 then
    Result.Add('SubEnd');
  if FSubOpenWords.Count > 0 then
    Result.Add('SubOpen');
  if FSubNoBodyWords.Count > 0 then
    Result.Add('SubNoBody');
  if FSubOpenFirst.Count > 0 then
    Result.Add('SubOpenFirst');
  if FSubSkip.Count > 0 then
    Result.Add('SubSkip');
  if FFmtOutdent.Count > 0 then
    Result.Add('FmtOutdent');
  if FFmtSection.Count > 0 then
    Result.Add('FmtSection');
  if FFmtClass.Count > 0 then
    Result.Add('FmtClass');
  if FFmtStmtEnd.Count > 0 then
    Result.Add('FmtStmtEnd');
  if FFmtHang.Count > 0 then
    Result.Add('FmtHang');
  if FFmtContinue.Count > 0 then
    Result.Add('FmtContinue');
  if FFmtHangFirst.Count > 0 then
    Result.Add('FmtHangFirst');
  if FFmtContinueFirst.Count > 0 then
    Result.Add('FmtContinueFirst');
  if FFmtLabel.Count > 0 then
    Result.Add('FmtLabel');
  if FSubBraces or FSubTags then
    Result.Add('SubStyle');
  if FTagVoid.Count > 0 then
    Result.Add('TagVoid');
  if FSubScope <> '' then
    Result.Add('SubScope');
  Result.Add('PairMark');
  for I := 0 to High(MarkGroups) do
    Result.Add(MarkGroups[I].Name);
  if FSubBodyHasColors then
    Result.Add('SubBody');
  if FCompHasColors then
    Result.Add('Components');
  Result.Add('Text');
end;

procedure TClrScheme.EnsureSchemaSection(const AName: string);
var
  FgC, BgC: TColor;
begin
  if SchemaSections.IndexOf(AName) < 0 then
    SchemaSections.Add(AName);
  if (FBaseColors.IndexOfName(AName) < 0) and
     SectionColors(AName, FgC, BgC) then
    FBaseColors.Values[AName] := ColorToString(FgC) + ' ' + ColorToString(BgC);
end;

procedure TClrScheme.BuildMarkerChars;
var
  K: Integer;

  procedure AddMarker(const S: string);
  var
    K: Integer;
  begin
    for K := 1 to Length(S) do
      Include(FMarkerChars, S[K]);
    if Length(S) > FMaxMarkerLen then
      FMaxMarkerLen := Length(S);
  end;

begin
  FMarkerChars := [#13, #10];
  FMaxMarkerLen := 1;

  AddMarker(FLineCommentMarker);
  AddMarker(FBlockCommentStart);
  AddMarker(FBlockCommentEnd);
  for K := 0 to High(FBcExtra) do
  begin
    AddMarker(FBcExtra[K].StartMark);
    AddMarker(FBcExtra[K].EndMark);
  end;
  AddMarker(FStringMarker);
  for K := 0 to High(FStrExtra) do
    AddMarker(FStrExtra[K].StartMark);
end;

// Собирает набор "опасных" символов активной схемы.
//
// Правка, не задевшая ни одного из них, ГАРАНТИРОВАННО не могла ни создать,
// ни разрушить комментарий или литерал - значит карту достаточно сдвинуть.
// Переводы строки тоже здесь: строчный комментарий кончается именно ими, и
// удаление перевода строки склеивает строки, меняя разметку.
// Подпись маркеров активной схемы. По ней видно, надо ли перестраивать
// карту комментариев после смены схемы: маркеры те же - карта верна.
// Дополнительные пары блочных комментариев входят сюда наравне с основной.
function TClrScheme.MarkersSig: string;
var
  I: Integer;
begin
  Result := LineCommentSchemeText + #0 + FBlockCommentStart + #0 +
            FBlockCommentEnd + #0 + FStringMarker;
  for I := 0 to High(FBcExtra) do
    Result := Result + #0 + FBcExtra[I].StartMark + #0 + FBcExtra[I].EndMark;
  for I := 0 to High(FStrExtra) do
    Result := Result + #0 + FStrExtra[I].StartMark;
  Result := Result + #0 + FStrEscape;
end;

// Вторая строка секции Digits в .clr описывает, какие формы записи чисел
// понимает язык. Раньше там стояла заглушка Digits_Auto_Processing - она
// по-прежнему принимается и означает поведение по умолчанию.
//
// Распознаются токены через пробел:
//   0x        шестнадцатеричный литерал в стиле C: 0x1F
//   &H        шестнадцатеричный/восьмеричный/двоичный в стиле BASIC: &H1F &O17 &B1010
//   exp       экспонента: 1e5, 1.5E-3
//   suffix=.. хвостовые символы типа: suffix=LlUuFf&%!#
procedure TClrScheme.ParseDigitFormats(const S: string);
var
  SL: TStringList;
  K, M: Integer;
  Tok, Suf: string;
begin
  // Поведение по умолчанию - десятичные числа и C-шный 0x
  FNumHex0x := True;
  FNumHexAmp := False;
  FNumExp := False;
  FNumSuffix := [];

  if (Trim(S) = '') or (CompareText(Trim(S), 'Digits_Auto_Processing') = 0) then
    Exit; // старый формат файла, оставляем умолчания

  // Строка задана явно - дальше включаем только то, что в ней перечислено
  FNumHex0x := False;

  SL := TStringList.Create;
  try
    SL.Delimiter := ' ';
    SL.DelimitedText := S;
    for K := 0 to SL.Count - 1 do
    begin
      Tok := LowerCase(Trim(SL[K]));
      if Tok = '0x' then
        FNumHex0x := True
      else if Tok = '&h' then
        FNumHexAmp := True
      else if Tok = 'exp' then
        FNumExp := True
      else if Copy(Tok, 1, 7) = 'suffix=' then
      begin
        // Регистр суффиксов важен, поэтому берём из исходной строки
        Suf := Copy(Trim(SL[K]), 8, Length(SL[K]));
        for M := 1 to Length(Suf) do
          Include(FNumSuffix, Suf[M]);
      end;
    end;
  finally
    SL.Free;
  end;
end;

function TClrScheme.BuildDigitFormats: string;
var
  Suf: string;
  C: Char;
begin
  Result := '';
  if FNumHex0x then
    Result := Result + '0x ';
  if FNumHexAmp then
    Result := Result + '&H ';
  if FNumExp then
    Result := Result + 'exp ';

  Suf := '';
  for C := #33 to #126 do
    if C in FNumSuffix then
      Suf := Suf + C;
  if Suf <> '' then
    Result := Result + 'suffix=' + Suf;

  Result := Trim(Result);
  if Result = '' then
    Result := 'dec'; // только десятичные; строка не должна быть пустой
end;

procedure TClrScheme.ClearKeywordGroups;
var
  GroupIdx: Integer;
begin
  for GroupIdx := 0 to High(KeywordGroups) do
    if KeywordGroups[GroupIdx].Words <> nil then
      KeywordGroups[GroupIdx].Words.Free;
  SetLength(KeywordGroups, 0);
end;

// Группы операторов: память под наборы символов не выделяется, достаточно
// обнулить массив
procedure TClrScheme.ClearOpGroups;
begin
  SetLength(OpGroups, 0);
end;

// Группы отметки строк: у каждой свой список слов, его надо освободить
procedure TClrScheme.ClearMarkGroups;
var
  I: Integer;
begin
  for I := 0 to High(MarkGroups) do
    if MarkGroups[I].Words <> nil then
      MarkGroups[I].Words.Free;
  SetLength(MarkGroups, 0);
end;

// Группа по имени раздела; -1 - такой группы нет
function TClrScheme.OpGroupIndex(const AName: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(OpGroups) do
    if CompareText(OpGroups[I].Name, AName) = 0 then
    begin
      Result := I;
      Exit;
    end;
end;

function TClrScheme.MarkGroupIndex(const AName: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(MarkGroups) do
    if CompareText(MarkGroups[I].Name, AName) = 0 then
    begin
      Result := I;
      Exit;
    end;
end;

// Набор символов группы операторов строкой - для файла схемы и для таблицы
function TClrScheme.OpCharsStr(AIndex: Integer): string;
var
  I: Integer;
begin
  Result := '';
  if (AIndex < 0) or (AIndex > High(OpGroups)) then
    Exit;
  for I := 0 to 255 do
    if Chr(I) in OpGroups[AIndex].Chars then
      Result := Result + Chr(I);
end;

// Обратно: строка - в набор символов группы
procedure TClrScheme.SetOpChars(AIndex: Integer; const S: string);
var
  I: Integer;
begin
  if (AIndex < 0) or (AIndex > High(OpGroups)) then
    Exit;
  OpGroups[AIndex].Chars := [];
  for I := 1 to Length(S) do
    if S[I] > ' ' then
      Include(OpGroups[AIndex].Chars, S[I]);
end;

// Дополнительная пара по имени раздела; -1 - такой нет
function TClrScheme.BcExtraIndex(const AName: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(FBcExtra) do
    if CompareText(FBcExtra[I].Name, AName) = 0 then
    begin
      Result := I;
      Exit;
    end;
end;

// Маркеры и цвета пары по её номеру: 0 - основная, дальше дополнительные
function TClrScheme.BcStartMark(AKind: Integer): string;
begin
  if AKind <= 0 then
    Result := FBlockCommentStart
  else if AKind <= Length(FBcExtra) then
    Result := FBcExtra[AKind - 1].StartMark
  else
    Result := '';
end;

function TClrScheme.BcEndMark(AKind: Integer): string;
begin
  if AKind <= 0 then
    Result := FBlockCommentEnd
  else if AKind <= Length(FBcExtra) then
    Result := FBcExtra[AKind - 1].EndMark
  else
    Result := '';
end;

procedure TClrScheme.BcColors(AKind: Integer; var AFg, ABg: TColor);
begin
  if (AKind >= 1) and (AKind <= Length(FBcExtra)) then
  begin
    AFg := FBcExtra[AKind - 1].FgColor;
    ABg := FBcExtra[AKind - 1].BgColor;
  end
  else
  begin
    AFg := FBcFG;
    ABg := FBcBG;
  end;
end;

// Дополнительный маркер литерала по имени раздела; -1 - такого нет
function TClrScheme.StrExtraIndex(const AName: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(FStrExtra) do
    if CompareText(FStrExtra[I].Name, AName) = 0 then
    begin
      Result := I;
      Exit;
    end;
end;

// Маркер и цвета литерала по номеру: 0 - основной, дальше дополнительные
function TClrScheme.StrMark(AKind: Integer): string;
begin
  if AKind <= 0 then
    Result := FStringMarker
  else if AKind <= Length(FStrExtra) then
    Result := FStrExtra[AKind - 1].StartMark
  else
    Result := '';
end;

procedure TClrScheme.StrColors(AKind: Integer; var AFg, ABg: TColor);
begin
  if (AKind >= 1) and (AKind <= Length(FStrExtra)) then
  begin
    AFg := FStrExtra[AKind - 1].FgColor;
    ABg := FStrExtra[AKind - 1].BgColor;
  end
  else
  begin
    AFg := FStrFG;
    ABg := FStrBG;
  end;
end;

// Строка целиком закомментирована: первый непробельный текст - маркер
// строчного комментария активной схемы
function TClrScheme.IsCommentLine(const S: string): Boolean;
var
  T: string;
begin
  Result := False;
  if FLineCommentMarker = '' then
    Exit;
  T := TrimLeft(S);
  Result := (T <> '') and
            (AnsiCompareText(Copy(T, 1, Length(FLineCommentMarker)),
                             FLineCommentMarker) = 0);
end;

function TClrScheme.LineCommentSchemeText: string;
begin
  if FLineCommentAtStart and (FLineCommentMarker <> '') then
    Result := '^' + FLineCommentMarker
  else
    Result := FLineCommentMarker;
end;

// ^ только как приставка к непустому маркеру: одиночный ^ остаётся
// маркером как есть
procedure TClrScheme.SetLineCommentSchemeText(const S: string);
begin
  if (Length(S) > 1) and (S[1] = '^') then
  begin
    FLineCommentAtStart := True;
    FLineCommentMarker := Copy(S, 2, MaxInt);
  end
  else
  begin
    FLineCommentAtStart := False;
    FLineCommentMarker := S;
  end;
end;

function TClrScheme.LineCommentPosOk(const AText: string;
  MarkPos: Integer): Boolean;
var
  CharIdx: Integer;
begin
  Result := True;
  if not FLineCommentAtStart then
    Exit;
  CharIdx := MarkPos - 1;
  if CharIdx > Length(AText) then
    CharIdx := Length(AText);
  while CharIdx >= 1 do
  begin
    case AText[CharIdx] of
      #13, #10:
        Exit;
      ' ', #9:
        Dec(CharIdx);
    else
      Result := False;
      Exit;
    end;
  end;
end;

end.
