unit FarHelp;

// ---------------------------------------------------------------------------
//  Справка (F1) для FAR unIDE / uniFAR - без окна: темы, строки, ссылки.
//  Рисует и принимает клавиши TFarView (UnFar).
//
//  Текст - в FarHelpText (ниже), разметка как в .hlf FAR Manager:
//    @Тема        - начало темы (имя для ссылок);
//    $Заголовок   - заголовок окна темы;
//    #текст#      - выделенный текст (подзаголовки, клавиши);
//    ~текст~@Тема@ - ссылка на тему.
//  В конце каждой темы, кроме Contents, добавляется ссылка на содержание.
//
//  Ходить по справке: стрелки, PgUp / PgDn, Home / End - прокрутка;
//  Tab / Shift+Tab - следующая / предыдущая ссылка; Enter - перейти;
//  Backspace, Alt+F1 - назад; F1, Shift+F1 - содержание.
// ---------------------------------------------------------------------------

// Free Pascal (uniFAR): исходник в кодировке Windows-1251 - строки с
// кириллицей в WideString без кракозябр. Delphi 7 эту строку пропускает
{$IFDEF FPC}{$MODE DELPHI}{$CODEPAGE CP1251}{$ENDIF}

interface

uses
  SysUtils;

const
  FarHelpContents = 'Contents';
  FarHelpPanels = 'Panels';
  FarHelpFiles = 'Files';
  FarHelpCmdLine = 'CmdLine';
  FarHelpTabs = 'Tabs';
  FarHelpDrives = 'Drives';
  FarHelpFind = 'Find';
  FarHelpViewer = 'Viewer';
  FarHelpEditor = 'Editor';
  FarHelpArchives = 'Archives';
  FarHelpFtp = 'Ftp';
  FarHelpFields = 'Fields';
  FarHelpOptions = 'Options';
  FarHelpKeys = 'HelpKeys';

type
  // Ссылка или выделенный текст в строке темы: строка, колонка (с 0),
  // длина; Topic - куда ведёт ссылка ('' - просто выделение)
  TFarHelpSpan = record
    Row: Integer;
    Col: Integer;
    Len: Integer;
    Topic: string;
  end;
  TFarHelpSpans = array of TFarHelpSpan;

  // Где были перед переходом по ссылке (Backspace - назад)
  TFarHelpPlace = record
    Topic: string;
    Top: Integer;
    Link: Integer;
  end;

  TFarHelp = class
  private
    FAll: array of WideString;      // весь текст справки (с разметкой)
    FTopic: string;
    FTitle: WideString;
    FLines: array of WideString;    // строки темы без разметки
    FLinks: TFarHelpSpans;          // ссылки темы по порядку
    FMarks: TFarHelpSpans;          // выделенный текст
    FTop: Integer;
    FLink: Integer;                 // выбранная ссылка (-1 - нет)
    FBack: array of TFarHelpPlace;
    procedure AddText(const ALine: WideString);
    procedure LoadText;
    function FindTopic(const ATopic: string): Integer;
    procedure ParseLine(const ARaw: WideString);
    procedure Load(const ATopic: string);
    function GetLine(AIndex: Integer): WideString;
    function GetLinkSpan(AIndex: Integer): TFarHelpSpan;
    function GetMarkSpan(AIndex: Integer): TFarHelpSpan;
  public
    constructor Create;
    // Открыть тему с начала; нет такой - содержание. История назад -
    // очищается (AKeepBack = False) или нет
    procedure Open(const ATopic: string; AKeepBack: Boolean);
    // Перейти по выбранной ссылке (или по ссылке AIndex), с историей
    procedure Follow(AIndex: Integer);
    function Back: Boolean;
    // Прокрутка на ADelta строк при ARows видимых строках
    procedure Scroll(ADelta, ARows: Integer);
    procedure GoHome;
    procedure GoEnd(ARows: Integer);
    // Следующая (ADir = 1) / предыдущая (-1) ссылка; видимых ссылок нет -
    // прокрутка на страницу
    procedure NextLink(ADir, ARows: Integer);
    // Ссылка в клетке (строка темы, колонка); -1 - нет
    function LinkAt(ARow, ACol: Integer): Integer;
    function MaxWidth: Integer;
    property Topic: string read FTopic;
    property Title: WideString read FTitle;
    property Top: Integer read FTop;
    property Link: Integer read FLink;
    function LineCount: Integer;
    function LinkCount: Integer;
    function MarkCount: Integer;
    property Lines[AIndex: Integer]: WideString read GetLine;
    property Links[AIndex: Integer]: TFarHelpSpan read GetLinkSpan;
    property Marks[AIndex: Integer]: TFarHelpSpan read GetMarkSpan;
  end;

implementation

constructor TFarHelp.Create;
begin
  inherited Create;
  FLink := -1;
  LoadText;
end;

procedure TFarHelp.AddText(const ALine: WideString);
begin
  SetLength(FAll, Length(FAll) + 1);
  FAll[High(FAll)] := ALine;
end;

function TFarHelp.GetLine(AIndex: Integer): WideString;
begin
  if (AIndex >= 0) and (AIndex <= High(FLines)) then
    Result := FLines[AIndex]
  else
    Result := '';
end;

function TFarHelp.GetLinkSpan(AIndex: Integer): TFarHelpSpan;
begin
  Result := FLinks[AIndex];
end;

function TFarHelp.GetMarkSpan(AIndex: Integer): TFarHelpSpan;
begin
  Result := FMarks[AIndex];
end;

function TFarHelp.LineCount: Integer;
begin
  Result := Length(FLines);
end;

function TFarHelp.LinkCount: Integer;
begin
  Result := Length(FLinks);
end;

function TFarHelp.MarkCount: Integer;
begin
  Result := Length(FMarks);
end;

function TFarHelp.MaxWidth: Integer;
var
  LineIdx: Integer;
begin
  Result := Length(FTitle) + 4;
  for LineIdx := 0 to High(FLines) do
    if Length(FLines[LineIdx]) > Result then
      Result := Length(FLines[LineIdx]);
end;

function TFarHelp.FindTopic(const ATopic: string): Integer;
var
  LineIdx: Integer;
  Name: WideString;
begin
  Result := -1;
  Name := '@' + WideString(ATopic);
  for LineIdx := 0 to High(FAll) do
    if FAll[LineIdx] = Name then
    begin
      Result := LineIdx;
      Exit;
    end;
end;

// Строка с разметкой: текст - в FLines, ссылки и выделение - в FLinks /
// FMarks
procedure TFarHelp.ParseLine(const ARaw: WideString);
var
  Text: WideString;
  CharPos, Stop, Row: Integer;
  Span: TFarHelpSpan;
  LinkText, TopicName: WideString;
begin
  Row := Length(FLines);
  Text := '';
  CharPos := 1;
  while CharPos <= Length(ARaw) do
  begin
    if ARaw[CharPos] = '~' then
    begin
      // ~текст~@Тема@
      Stop := CharPos + 1;
      while (Stop <= Length(ARaw)) and (ARaw[Stop] <> '~') do
        Inc(Stop);
      LinkText := Copy(ARaw, CharPos + 1, Stop - CharPos - 1);
      CharPos := Stop + 1;
      TopicName := '';
      if (CharPos <= Length(ARaw)) and (ARaw[CharPos] = '@') then
      begin
        Stop := CharPos + 1;
        while (Stop <= Length(ARaw)) and (ARaw[Stop] <> '@') do
          Inc(Stop);
        TopicName := Copy(ARaw, CharPos + 1, Stop - CharPos - 1);
        CharPos := Stop + 1;
      end;
      Span.Row := Row;
      Span.Col := Length(Text);
      Span.Len := Length(LinkText);
      Span.Topic := string(TopicName);
      SetLength(FLinks, Length(FLinks) + 1);
      FLinks[High(FLinks)] := Span;
      Text := Text + LinkText;
    end
    else if ARaw[CharPos] = '#' then
    begin
      // #выделенный текст#
      Stop := CharPos + 1;
      while (Stop <= Length(ARaw)) and (ARaw[Stop] <> '#') do
        Inc(Stop);
      Span.Row := Row;
      Span.Col := Length(Text);
      Span.Len := Stop - CharPos - 1;
      Span.Topic := '';
      SetLength(FMarks, Length(FMarks) + 1);
      FMarks[High(FMarks)] := Span;
      Text := Text + Copy(ARaw, CharPos + 1, Stop - CharPos - 1);
      CharPos := Stop + 1;
    end
    else
    begin
      Text := Text + ARaw[CharPos];
      Inc(CharPos);
    end;
  end;
  SetLength(FLines, Row + 1);
  FLines[Row] := Text;
end;

procedure TFarHelp.Load(const ATopic: string);
var
  First, LineIdx: Integer;
begin
  First := FindTopic(ATopic);
  if First < 0 then
    First := FindTopic(FarHelpContents);
  SetLength(FLines, 0);
  SetLength(FLinks, 0);
  SetLength(FMarks, 0);
  FTitle := '';
  FTop := 0;
  FLink := -1;
  if First < 0 then
    Exit;
  FTopic := string(Copy(FAll[First], 2, MaxInt));
  LineIdx := First + 1;
  while (LineIdx <= High(FAll)) and
        ((FAll[LineIdx] = '') or (FAll[LineIdx][1] <> '@')) do
  begin
    if (FAll[LineIdx] <> '') and (FAll[LineIdx][1] = '$') then
      FTitle := Copy(FAll[LineIdx], 2, MaxInt)
    else
      ParseLine(FAll[LineIdx]);
    Inc(LineIdx);
  end;
  // Пустые строки в конце не нужны
  while (Length(FLines) > 0) and (FLines[High(FLines)] = '') do
    SetLength(FLines, Length(FLines) - 1);
  if FTopic <> FarHelpContents then
  begin
    ParseLine('');
    ParseLine(' ~Содержание~@' + FarHelpContents + '@');
  end;
end;

procedure TFarHelp.Open(const ATopic: string; AKeepBack: Boolean);
begin
  if not AKeepBack then
    SetLength(FBack, 0);
  Load(ATopic);
end;

procedure TFarHelp.Follow(AIndex: Integer);
var
  Place: TFarHelpPlace;
begin
  if AIndex < 0 then
    AIndex := FLink;
  if (AIndex < 0) or (AIndex > High(FLinks)) then
    Exit;
  if FLinks[AIndex].Topic = '' then
    Exit;
  Place.Topic := FTopic;
  Place.Top := FTop;
  Place.Link := AIndex;
  SetLength(FBack, Length(FBack) + 1);
  FBack[High(FBack)] := Place;
  Load(FLinks[AIndex].Topic);
end;

function TFarHelp.Back: Boolean;
var
  Place: TFarHelpPlace;
begin
  Result := Length(FBack) > 0;
  if not Result then
    Exit;
  Place := FBack[High(FBack)];
  SetLength(FBack, Length(FBack) - 1);
  Load(Place.Topic);
  FTop := Place.Top;
  if Place.Link <= High(FLinks) then
    FLink := Place.Link;
end;

procedure TFarHelp.Scroll(ADelta, ARows: Integer);
var
  MaxTop: Integer;
begin
  MaxTop := Length(FLines) - ARows;
  if MaxTop < 0 then
    MaxTop := 0;
  FTop := FTop + ADelta;
  if FTop > MaxTop then
    FTop := MaxTop;
  if FTop < 0 then
    FTop := 0;
  // Выбранная ссылка ушла из окна - выбора нет
  if (FLink >= 0) and ((FLinks[FLink].Row < FTop) or
     (FLinks[FLink].Row >= FTop + ARows)) then
    FLink := -1;
end;

procedure TFarHelp.GoHome;
begin
  FTop := 0;
  FLink := -1;
end;

procedure TFarHelp.GoEnd(ARows: Integer);
begin
  Scroll(Length(FLines), ARows);
end;

procedure TFarHelp.NextLink(ADir, ARows: Integer);
var
  LinkIdx: Integer;
begin
  if Length(FLinks) = 0 then
  begin
    Scroll(ADir * ARows, ARows);
    Exit;
  end;
  if FLink < 0 then
  begin
    // Первая (последняя) ссылка в окне
    if ADir > 0 then
    begin
      for LinkIdx := 0 to High(FLinks) do
        if FLinks[LinkIdx].Row >= FTop then
        begin
          FLink := LinkIdx;
          Break;
        end;
    end
    else
      for LinkIdx := High(FLinks) downto 0 do
        if FLinks[LinkIdx].Row < FTop + ARows then
        begin
          FLink := LinkIdx;
          Break;
        end;
    if FLink < 0 then
      FLink := 0;
  end
  else
    FLink := (FLink + ADir + Length(FLinks)) mod Length(FLinks);
  // Ссылка - в окно
  if FLinks[FLink].Row < FTop then
    FTop := FLinks[FLink].Row
  else if FLinks[FLink].Row >= FTop + ARows then
    FTop := FLinks[FLink].Row - ARows + 1;
  if FTop < 0 then
    FTop := 0;
end;

function TFarHelp.LinkAt(ARow, ACol: Integer): Integer;
var
  LinkIdx: Integer;
begin
  Result := -1;
  for LinkIdx := 0 to High(FLinks) do
    if (FLinks[LinkIdx].Row = ARow) and (ACol >= FLinks[LinkIdx].Col) and
       (ACol < FLinks[LinkIdx].Col + FLinks[LinkIdx].Len) then
    begin
      Result := LinkIdx;
      Exit;
    end;
end;

// ---------------------------------------------------------------------------
//  Текст справки. Строки - не длиннее 74 символов: окно справки не шире
//  78 клеток
// ---------------------------------------------------------------------------

procedure TFarHelp.LoadText;
begin
  AddText('@Contents');
  AddText('$Справка');
  AddText(' #Содержание#');
  AddText('');
  AddText('   ~Панели файлов~@Panels@');
  AddText('   ~Операции с файлами~@Files@');
  AddText('   ~Командная строка~@CmdLine@');
  AddText('   ~Вкладки папок~@Tabs@');
  AddText('   ~Меню дисков~@Drives@');
  AddText('   ~Поиск файлов (Alt+F7)~@Find@');
  AddText('   ~Просмотр (F3)~@Viewer@');
  AddText('   ~Редактор (F4)~@Editor@');
  AddText('   ~Архивы~@Archives@');
  AddText('   ~FTP~@Ftp@');
  AddText('   ~Поля ввода в окнах~@Fields@');
  AddText('   ~Настройки (F9)~@Options@');
  AddText('   ~Как пользоваться справкой~@HelpKeys@');
  AddText('');
  AddText(' F1 открывает справку о том месте, где вы сейчас: о панелях,');
  AddText(' просмотре, редакторе, поиске, FTP или архиве.');

  AddText('@Panels');
  AddText('$Панели файлов');
  AddText(' #Курсор и выделение#');
  AddText('   #Стрелки, Home, End#     курсор');
  AddText('   #PgUp, PgDn#             курсор на страницу');
  AddText('   #Ins#                    выделить файл под курсором');
  AddText('   #Shift+стрелки#          выделение');
  AddText('   #Shift+PgUp, Shift+PgDn, Shift+Home, Shift+End# - то же');
  AddText('');
  AddText(' #Папки#');
  AddText('   #Enter, Ctrl+PgDn#       войти в папку');
  AddText('   #Ctrl+PgUp#              в папку выше');
  AddText('   #Ctrl+\#                 в корень диска');
  AddText('   #Tab#                    другая панель');
  AddText('   #Ctrl+R#                 перечитать панель');
  AddText('   #Alt+F12#                история папок (Del - убрать папку)');
  AddText('   #Alt+F1, Alt+F2#         ~меню дисков~@Drives@ левой / правой панели');
  AddText(' Панели следят за своими папками и перечитываются сами.');
  AddText('');
  AddText(' #Enter на файле#');
  AddText('   exe, com, bat, cmd выполняются, как команда (вывод - под');
  AddText('   панелями); остальные файлы открываются программой по');
  AddText('   ассоциации. #Shift+Enter# - открыть в отдельном окне (папку -');
  AddText('   в Проводнике). Архив раскрывается в панели, см. ~Архивы~@Archives@.');
  AddText('');
  AddText(' #Сортировка#');
  AddText('   #Ctrl+F3# имя, #Ctrl+F4# расширение, #Ctrl+F5# время записи,');
  AddText('   #Ctrl+F6# размер, #Ctrl+F7# без сортировки, #Ctrl+F8# время');
  AddText('   создания, #Ctrl+F9# время доступа. Повтор - обратный порядок.');
  AddText('   #Ctrl+F12# - меню сортировки, #Shift+F12# - выделенные первыми.');
  AddText('   Буква сортировки - в левом верхнем углу панели.');
  AddText('');
  AddText(' #Размеры#');
  AddText('   #Ctrl+Up, Ctrl+Down#     панели короче / длиннее');
  AddText('   #Ctrl+Left, Ctrl+Right#  граница между панелями (при пустой');
  AddText('                          командной строке)');
  AddText('   #Ctrl+O#                 спрятать / показать панели');
  AddText('');
  AddText(' #F10# - выход. Операции с файлами - в разделе ~Операции с файлами~@Files@.');

  AddText('@Files');
  AddText('$Операции с файлами');
  AddText('   #F3#            просмотр файла (~Просмотр~@Viewer@)');
  AddText('   #F3# на папке   размер папки (выделенных папок); Esc - прервать');
  AddText('   #F4#            файл в редактор (~Редактор~@Editor@)');
  AddText('   #Shift+F4#      редактор по имени файла; нет файла - создаётся');
  AddText('   #F5#            копировать выделенное в папку другой панели');
  AddText('   #Shift+F5#      копировать только файл под курсором');
  AddText('   #F6#            перенести или переименовать выделенное');
  AddText('   #Shift+F6#      переименовать файл под курсором');
  AddText('   #F7#            создать папку');
  AddText('   #F8, Del#       удалить выделенное в корзину');
  AddText('   #Shift+F8#      удалить только файл под курсором');
  AddText('   #Shift+Del#     удалить мимо корзины');
  AddText('   #Ctrl+A#        атрибуты и время файлов и папок');
  AddText('   #Shift+F1#      упаковать выделенное в архив (~Архивы~@Archives@)');
  AddText('');
  AddText(' Нет выделенных файлов - операция идёт с файлом под курсором.');
  AddText('');
  AddText(' Файл уже есть в папке назначения (F5, F6) - окно #Warning#:');
  AddText(' размер и время нового и существующего файла. #Overwrite# -');
  AddText(' заменить, #Skip# - пропустить, #Rename# - другое имя, #Append# -');
  AddText(' дописать в конец, #Cancel# или #Esc# - ничего не делать.');
  AddText(' #Remember choice# - тот же ответ для остальных файлов. Все вопросы');
  AddText(' задаются до начала копирования.');
  AddText('');
  AddText(' #Буфер обмена#');
  AddText('   #Ctrl+Ins#      имя файла под курсором');
  AddText('   #Ctrl+F#        полный путь файла под курсором - в командную');
  AddText('                 строку и в буфер');
  AddText('   #Ctrl+[, Ctrl+]# путь левой / правой панели - в командную');
  AddText('                 строку и в буфер');
  AddText('   #Щелчок по заголовку панели# - путь этой панели в буфер,');
  AddText('                 #по приглашению перед командной строкой# -');
  AddText('                 путь активной панели в буфер');

  AddText('@CmdLine');
  AddText('$Командная строка');
  AddText(' Буквы, набранные на панелях, попадают в командную строку.');
  AddText(' #Enter# выполняет команду через cmd.exe в папке активной панели,');
  AddText(' вывод виден под панелями (#Ctrl+O# - весь вывод).');
  AddText('');
  AddText('   #Esc, Ctrl+Y#           очистить строку');
  AddText('   #Ctrl+E, Ctrl+X#        история команд: старше / новее');
  AddText('   #Ctrl+S, Ctrl+D#        каретка влево / вправо');
  AddText('   #Ctrl+Left, Ctrl+Right# каретка на слово');
  AddText('   #Ctrl+V, Shift+Ins#     вставить из буфера');
  AddText('   #Ctrl+Enter#            имя файла под курсором');
  AddText('   #Ctrl+F#                полный путь файла под курсором');
  AddText('   #Ctrl+[, Ctrl+]#        путь левой / правой панели');
  AddText('   #Ctrl+Break#            прервать команду');
  AddText('');
  AddText(' Свои команды: #cd# папка, #X:# (смена диска), #cls#. Если папки для');
  AddText(' cd нет, берётся папка выше.');
  AddText(' Пока строка не пуста, Del и Backspace правят её, файлы не');
  AddText(' удаляются.');

  AddText('@Tabs');
  AddText('$Вкладки папок');
  AddText(' Строка вкладок над панелями (в uniFAR). Самая левая вкладка -');
  AddText(' папка активной панели, за ней - ваш список вкладок.');
  AddText('');
  AddText(' #Добавить вкладку#: перейдите в папку, нажмите #Alt+Left# (или');
  AddText(' #Alt+Right#) - курсор встанет на левую вкладку, затем #Enter#.');
  AddText(' Папка станет первой в списке.');
  AddText('');
  AddText('   #Alt+Left, Alt+Right#   на вкладки и по ним; панель сразу');
  AddText('                         показывает папку вкладки');
  AddText('   #Left, Right#           по вкладкам (уже в режиме вкладок)');
  AddText('   #Home, End#             первая / последняя вкладка');
  AddText('   #Enter#                 остаться в папке вкладки');
  AddText('   #Del#                   убрать вкладку из списка');
  AddText('   #Esc#                   выйти из вкладок');
  AddText('');
  AddText(' #Мышь#: вкладка под мышью показывает свою папку, щелчок - остаться');
  AddText(' в ней, мышь ушла без щелчка - панель возвращается. Крестик на');
  AddText(' вкладке убирает её.');
  AddText('');
  AddText(' Список хранится в uniFAR.ini, раздел [FolderTabs]. При первом');
  AddText(' запуске в него берутся последние папки истории (Alt+F12).');
  AddText(' [uniFAR] FolderTabs=0 - без вкладок.');

  AddText('@Drives');
  AddText('$Меню дисков');
  AddText(' #Alt+F1# - диск левой панели, #Alt+F2# - правой. Другая панель на');
  AddText(' этом диске - в её папку, иначе - в последнюю папку на диске.');
  AddText('');
  AddText(' В меню: буква, тип, файловая система, метка, размер, свободно,');
  AddText(' диск и раздел, модель. Ниже - тома без буквы и физические диски.');
  AddText(' Пункт #FTP# открывает список адресов FTP (~FTP~@Ftp@).');
  AddText('');
  AddText('   #Стрелки# - выбрать, #Enter# - перейти, #Esc# - закрыть');

  AddText('@Find');
  AddText('$Поиск файлов');
  AddText(' #Alt+F7# - окно Find file: маски, текст, кодовая страница текста');
  AddText(' (cp1251, cp866, UTF-8, UTF-16), регистр, слово целиком, искать ли');
  AddText(' папки, где искать (с подпапками, только в папке, весь диск).');
  AddText(' У полей Masks и Text - список прежних значений (#Ctrl+Down#).');
  AddText('');
  AddText(' #Окно найденного#');
  AddText('   #Стрелки, PgUp, PgDn#   по списку');
  AddText('   #Enter, Go to#          панель на найденный файл');
  AddText('   #F3#                    просмотр файла');
  AddText('   #F4, Edit#              файл в редактор');
  AddText('   #New search#            новый поиск');
  AddText('   #Ctrl+Break#            остановить поиск');
  AddText('   #Esc, F10#              остановить, потом закрыть');
  AddText(' После выхода из просмотра или редактора окно найденного');
  AddText(' возвращается с тем же списком.');
  AddText('');
  AddText(' Правка полей окна - ~Поля ввода в окнах~@Fields@.');

  AddText('@Viewer');
  AddText('$Просмотр (F3)');
  AddText('   #Стрелки, PgUp, PgDn#   прокрутка');
  AddText('   #Home, End#             начало / конец файла');
  AddText('   #Left, Right#           сдвиг вбок (без переноса строк)');
  AddText('   #Ctrl+Left, Ctrl+Right# сдвиг на 20 колонок');
  AddText('   #F2#                    перенос строк / без переноса');
  AddText('   #F4#                    hex / текст');
  AddText('   #F5#                    на всю ширину / в панели');
  AddText('   #F6#                    этот файл в редактор');
  AddText('   #F7#                    поиск, #Shift+F7# - следующий');
  AddText('   #F8#                    кодировка: ANSI, OEM, UTF-8, UTF-16');
  AddText('   #Alt+F8#                перейти: смещение (12345, 0x3039)');
  AddText('                         или процент (50%)');
  AddText('   #Ctrl+R#                перечитать файл');
  AddText('   #Tab, Ctrl+Tab#         в другую панель');
  AddText('   #F3, F10, Esc#          закрыть');
  AddText('');
  AddText(' Файл читается по частям, так смотрятся и очень большие файлы.');

  AddText('@Editor');
  AddText('$Редактор (F4)');
  AddText('   #F2#                    записать');
  AddText('   #Shift+F2#              записать как');
  AddText('   #F5#                    на всю ширину / в панели');
  AddText('   #F7#                    поиск, #Shift+F7# - следующий');
  AddText('   #Shift+F8#              кодировка записи (ANSI, UTF-8, UTF-8');
  AddText('                         с BOM, UTF-16)');
  AddText('   #Alt+F8#                перейти на строку');
  AddText('   #F10, Esc#              закрыть');
  AddText('');
  AddText(' #Правка#');
  AddText('   #Shift+стрелки#, мышь   выделение');
  AddText('   #Ctrl+A#                выделить всё');
  AddText('   #Ctrl+C, Ctrl+Ins#      копировать');
  AddText('   #Ctrl+X, Shift+Del#     вырезать');
  AddText('   #Ctrl+V, Shift+Ins#     вставить');
  AddText('   #Ctrl+Z#                отменить, #Ctrl+Shift+Z# - вернуть');
  AddText('   #Ctrl+Y#                удалить строку');
  AddText('   #Ctrl+Backspace#        удалить слово слева');
  AddText('   #Ctrl+Del#              удалить слово справа');
  AddText('   #Ctrl+Up, Ctrl+Down#    прокрутка без каретки');
  AddText('   #Ctrl+Tab#              в другую панель');
  AddText('');
  AddText(' Подсветка - по схеме .clr из папки schemes.');

  AddText('@Archives');
  AddText('$Архивы');
  AddText(' Архивы открываются через 7-Zip (tools\7zip рядом с программой;');
  AddText(' если его нет, программа предложит скачать).');
  AddText('');
  AddText('   #Enter# на архиве       раскрыть архив в панели');
  AddText('   #Ctrl+PgDn#             раскрыть как архив любой файл');
  AddText('   #..# в корне архива     выйти из архива');
  AddText('   #F5# из архива          распаковать выбранное в папку другой');
  AddText('                         панели');
  AddText('   #Enter# на файле        распаковать во временную папку и');
  AddText('                         открыть');
  AddText('   #Shift+F1#              упаковать выделенное (ZIP или 7z,');
  AddText('                         степень сжатия)');
  AddText('');
  AddText(' Архив в архиве (.tar в .gz) открывается так же. Пароль');
  AddText(' спрашивается. Другие операции внутри архива пока не делаются.');

  AddText('@Ftp');
  AddText('$FTP');
  AddText(' Пункт #FTP# в меню дисков (Alt+F1 / Alt+F2) - список адресов');
  AddText(' (Host, Home, User).');
  AddText('');
  AddText(' #Список адресов#');
  AddText('   #Enter#                 войти на сервер');
  AddText('   #Shift+F4#              новый адрес');
  AddText('   #F4#                    изменить адрес');
  AddText('   #F8, Del#               удалить адрес');
  AddText('   #Ctrl+Ins, Ctrl+C#      адреса в буфер строкой');
  AddText('                         ftp://user:pass@host:port/папка');
  AddText('   #Shift+Ins, Ctrl+V#     добавить адреса из буфера');
  AddText('   #F5#                    записать адреса в файлы на другой');
  AddText('                         панели (по файлу на адрес)');
  AddText('   #F5# на файл адреса     с другой панели - добавить адрес');
  AddText('                         (файлы FTP-плагина FAR - без пароля)');
  AddText('');
  AddText(' Пароль хранится зашифрованным (DPAPI). Из FAR удобнее всего');
  AddText(' переносить адрес через Alt+Shift+Ins в FAR и Shift+Ins здесь.');
  AddText('');
  AddText(' #Папки сервера#: #Enter#, #..#, #Ctrl+R# - как на диске. Файлы:');
  AddText(' #F3#, #F4#, #F5#, #F6#, #F7#, #F8#. После записи в редакторе (F2)');
  AddText(' файл отправляется на сервер.');

  AddText('@Fields');
  AddText('$Поля ввода в окнах');
  AddText(' В окнах с несколькими полями (Alt+F7, Shift+F1, FTP):');
  AddText('   #Shift+стрелки, Shift+Home, Shift+End#, мышь - выделение');
  AddText('   #Ctrl+Left, Ctrl+Right#   по словам');
  AddText('   #Ctrl+A#                  выделить всё');
  AddText('   #Ctrl+C, Ctrl+Ins#        копировать (ничего не выделено -');
  AddText('                           всё поле; из пароля - нет)');
  AddText('   #Ctrl+X, Shift+Del#       вырезать');
  AddText('   #Ctrl+V, Shift+Ins#       вставить (первую строку)');
  AddText('   #Ctrl+Z#                  отменить последнюю правку');
  AddText('   #Ctrl+Backspace#          удалить слово слева');
  AddText('   #Ctrl+Del#                удалить слово справа');
  AddText('   #Ctrl+Y#                  очистить поле');
  AddText('');
  AddText(' #Список прежних значений# (стрелка справа у поля):');
  AddText(' #Ctrl+Down#, #Alt+Down# или щелчок - открыть; #Enter# - выбрать,');
  AddText(' #Del# - убрать значение, #Esc# - закрыть.');

  AddText('@Options');
  AddText('$Настройки (F9)');
  AddText(' #F9# - меню Options:');
  AddText('   #Themes#                темы оформления');
  AddText('   #Colors#                цвет каждого элемента окна');
  AddText('   #Files highlighting#    раскраска файлов по расширению');
  AddText('   #Save setup#            записать настройки (#Shift+F9#)');
  AddText('');
  AddText(' #Files highlighting#: #Enter, F4# - изменить, #Ins# - добавить,');
  AddText(' #Del# - удалить, #пробел# - вкл/выкл, #Ctrl+Up/Down# - порядок.');
  AddText('');
  AddText(' Настройки хранятся в uniFAR.ini рядом с программой (в unIDE -');
  AddText(' в editor.ini).');

  AddText('@HelpKeys');
  AddText('$Как пользоваться справкой');
  AddText('   #Стрелки, PgUp, PgDn#   прокрутка');
  AddText('   #Home, End#             начало / конец темы');
  AddText('   #Tab, Shift+Tab#        следующая / предыдущая ссылка');
  AddText('   #Enter#                 перейти по ссылке');
  AddText('   #Backspace, Alt+F1#     назад');
  AddText('   #F1, Shift+F1#          содержание');
  AddText('   #Esc, F10#              закрыть справку');
  AddText('');
  AddText(' Мышью: щелчок по ссылке - перейти, колесо - прокрутка, щелчок');
  AddText(' вне окна - закрыть.');
end;

end.
