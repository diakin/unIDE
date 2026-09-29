unit ReleaseBuild;

// ---------------------------------------------------------------------------
//  Build Release: какие файлы, кроме exe, нужны программе при работе
//
//  Ответ ищется в исходниках проекта: имена файлов, которые встречаются в
//  строках кода и .dfm - 'EBalanс.cfg', 'Lusbapi.dll', TableName =
//  'ArchTable1.db', 'schemes\'. По строке, где имя стоит, и нескольким
//  следующим видно, что код с файлом делает:
//    - читает (Reset, LoadFromFile, FileExists, LoadLibrary, external,
//      TableName, ShellExecute, TIniFile.Create ...) - файл нужен;
//    - только пишет (Rewrite, SaveToFile, FileCreate, fmCreate ...) -
//      файл программа создаёт сама, в релиз он не нужен.
//  Это разбор текста, а не выполнение программы: имя, собранное из
//  частей, так не найти, поэтому окно выбора (DlgRelease) показывает всё
//  найденное с галками, а решение остаётся за пользователем.
// ---------------------------------------------------------------------------

interface

uses
  Classes;

type
  TRelUse = (ruRead, ruWrite);
  TRelUses = set of TRelUse;

  // Что известно об одном имени из исходников
  TRelRef = class
  public
    Uses_: TRelUses;   // что код с ним делает; пусто - не понять
    Where: string;     // первое место: "UnitB.pas:217"
    Count: Integer;    // сколько раз встретилось
    IsDir: Boolean;    // папка: имя кончалось на '\' или без расширения
  end;

// Имена файлов и папок из строк исходников в папке ADir (*.pas, *.dpr,
// *.inc, *.dfm; вложенные папки не смотрятся). AItems - имя (как в коде,
// без ведущей '\'; у папки без хвостовой '\') и TRelRef в Objects;
// владеет объектами вызывающий (FreeRelRefs). Имена без расширения
// попадают в список только как папки - проверять, есть ли такая папка,
// дело вызывающего.
procedure ScanReleaseRefs(const ADir: string; AItems: TStringList);
procedure FreeRelRefs(AItems: TStringList);

// Расширение из тех, что бывают у файлов данных программы (.dll, .ini,
// .cfg, .db ...): такое имя показывается, даже если файла не нашлось -
// значит, его не хватает рядом с exe
function IsDataExt(const AExt: string): Boolean;

implementation

uses
  SysUtils;

const
  // Исходники и файлы сборки - в релиз не идут никогда
  SourceExts = ',.pas,.dfm,.dpr,.dpk,.inc,.dof,.cfg~,.res,.rc,.dcu,.dcp,' +
               '.bpl,.lpr,.lfm,.lpi,.pp,.map,.drc,.~pas,.~dfm,.ddp,.dsk,';
  // Типичные файлы данных программы
  DataExts = ',.dll,.exe,.ini,.cfg,.dat,.db,.px,.xg0,.yg0,.mb,.val,.txt,' +
             '.csv,.xml,.json,.pdf,.chm,.hlp,.clr,.bmp,.ico,.jpg,.png,' +
             '.gif,.wav,.lng,.mnu,.fft,.htm,.html,.rtf,.ocx,.sys,';

  // Слова в строке с именем (и в следующих), по которым видно чтение
  ReadWords: array[0..17] of string = (
    'RESET(', 'LOADFROMFILE', 'FILEEXISTS', 'LOADLIBRARY', 'EXTERNAL',
    'TABLENAME', 'SHELLEXECUTE', 'FMOPENREAD', 'FILEOPEN', 'READSTRING',
    'READINTEGER', 'READBOOL', 'READFLOAT', 'TINIFILE.CREATE',
    'TMEMINIFILE.CREATE', 'FINDFIRST', 'DIRECTORYEXISTS', 'READSECTION');
  // ... и запись
  WriteWords: array[0..9] of string = (
    'REWRITE(', 'SAVETOFILE', 'FILECREATE', 'FMCREATE', 'APPEND(',
    'WRITESTRING', 'WRITEINTEGER', 'WRITEBOOL', 'DELETEFILE',
    'FORCEDIRECTORIES');
  // Сколько строк после строки с именем ещё смотреть: AssignFile с
  // именем, а Reset / Rewrite - строкой ниже
  LookAhead = 3;

function InList(const AList, AExt: string): Boolean;
begin
  Result := (AExt <> '') and (Pos(',' + LowerCase(AExt) + ',', AList) > 0);
end;

function IsDataExt(const AExt: string): Boolean;
begin
  Result := InList(DataExts, AExt);
end;

procedure FreeRelRefs(AItems: TStringList);
var
  I: Integer;
begin
  for I := 0 to AItems.Count - 1 do
    AItems.Objects[I].Free;
  AItems.Clear;
end;

// Строка похожа на имя файла или папки. ADir - папка: имя кончалось '\'
// или расширения нет вовсе. Отсекается то, что именем быть не может:
// маски, пути с диском, форматы чисел ('0.00'), адреса почты и сайтов,
// суффиксы, которые приклеиваются к имени ('_gr.jpg', '.ini').
function FileLikeName(const AText: string; var AName: string;
                      var ADir: Boolean): Boolean;
var
  S, Ext: string;
  I: Integer;
  HasLetter: Boolean;
begin
  Result := False;
  S := Trim(AText);
  while (S <> '') and (S[1] in ['\', '/']) do
    Delete(S, 1, 1);
  if (S = '') or (Length(S) > 100) then
    Exit;
  for I := 1 to Length(S) do
    if S[I] in ['*', '?', '<', '>', '|', '"', ':', '@', '%', #9] then
      Exit;
  if (Pos('//', S) > 0) or (S[1] in ['.', '_', ' ']) then
    Exit;

  ADir := S[Length(S)] in ['\', '/'];
  if ADir then
  begin
    while (S <> '') and (S[Length(S)] in ['\', '/']) do
      Delete(S, Length(S), 1);
    if S = '' then
      Exit;
    AName := S;
    Result := True;
    Exit;
  end;

  Ext := ExtractFileExt(S);
  if Ext = '' then
  begin
    // Слово без расширения - кандидат в папки ('schemes'). Только одно
    // слово без пробелов: фразы и подписи папками не бывают.
    for I := 1 to Length(S) do
      if not (S[I] in ['A'..'Z', 'a'..'z', '0'..'9', '_', '-', '\', '/']) then
        Exit;
    ADir := True;
    AName := S;
    Result := True;
    Exit;
  end;

  // Расширение: 1-5 знаков, хотя бы одна буква ('0.00' - не файл)
  if (Length(Ext) < 2) or (Length(Ext) > 6) then
    Exit;
  HasLetter := False;
  for I := 2 to Length(Ext) do
    if Ext[I] in ['A'..'Z', 'a'..'z'] then
      HasLetter := True
    else if not (Ext[I] in ['0'..'9']) then
      Exit;
  if not HasLetter or InList(SourceExts, Ext) then
    Exit;
  // Пробел перед расширением - фраза с точкой, а не имя
  if (Length(S) > Length(Ext)) and (S[Length(S) - Length(Ext)] = ' ') then
    Exit;
  AName := S;
  Result := True;
end;

// Строки в кавычках из строки исходника ALine. Комментарии (//, { },
// (* *)) пропускаются; AState - незакрытый многострочный комментарий:
// 0 - нет, 1 - { }, 2 - (* *).
procedure LineLiterals(const ALine: string; var AState: Integer;
                       ALits: TStrings; AIsDfm: Boolean);
var
  I, N: Integer;
  Lit: string;
begin
  ALits.Clear;
  I := 1;
  N := Length(ALine);
  while I <= N do
  begin
    if AState = 1 then
    begin
      if ALine[I] = '}' then
        AState := 0;
      Inc(I);
      Continue;
    end;
    if AState = 2 then
    begin
      if (ALine[I] = '*') and (I < N) and (ALine[I + 1] = ')') then
      begin
        AState := 0;
        Inc(I);
      end;
      Inc(I);
      Continue;
    end;

    case ALine[I] of
      '''':
        begin
          // Строка; '' внутри - одна кавычка
          Lit := '';
          Inc(I);
          while I <= N do
          begin
            if ALine[I] = '''' then
            begin
              if (I < N) and (ALine[I + 1] = '''') then
              begin
                Lit := Lit + '''';
                Inc(I, 2);
                Continue;
              end;
              Break;
            end;
            Lit := Lit + ALine[I];
            Inc(I);
          end;
          ALits.Add(Lit);
        end;
      '/':
        if not AIsDfm and (I < N) and (ALine[I + 1] = '/') then
          Exit;
      '{':
        if not AIsDfm then
          AState := 1;
      '(':
        if not AIsDfm and (I < N) and (ALine[I + 1] = '*') then
        begin
          AState := 2;
          Inc(I);
        end;
    end;
    Inc(I);
  end;
end;

// Чтение и запись по строке AIdx и LookAhead следующим
function LineUses(ALines: TStrings; AIdx: Integer; AIsDfm: Boolean): TRelUses;
var
  J, K: Integer;
  U: string;
begin
  Result := [];
  // В .dfm имя файла в свойстве (TableName, FileName) - его читают
  if AIsDfm then
  begin
    Result := [ruRead];
    Exit;
  end;
  for J := AIdx to AIdx + LookAhead do
  begin
    if J >= ALines.Count then
      Break;
    U := UpperCase(ALines[J]);
    for K := Low(ReadWords) to High(ReadWords) do
      if Pos(ReadWords[K], U) > 0 then
        Include(Result, ruRead);
    for K := Low(WriteWords) to High(WriteWords) do
      if Pos(WriteWords[K], U) > 0 then
        Include(Result, ruWrite);
    // Что нашлось в самой строке с именем - главное; дальше смотрим,
    // только если там ничего нет (AssignFile, Reset - строкой ниже)
    if Result <> [] then
      Break;
  end;
end;

procedure ScanFile(const AFile: string; AItems: TStringList);
var
  SL, Lits: TStringList;
  I, K, Idx, State: Integer;
  Name: string;
  IsDir, IsDfm: Boolean;
  Ref: TRelRef;
begin
  IsDfm := CompareText(ExtractFileExt(AFile), '.dfm') = 0;
  SL := TStringList.Create;
  Lits := TStringList.Create;
  try
    try
      SL.LoadFromFile(AFile);
    except
      Exit;   // файл занят - без него
    end;
    State := 0;
    for I := 0 to SL.Count - 1 do
    begin
      LineLiterals(SL[I], State, Lits, IsDfm);
      for K := 0 to Lits.Count - 1 do
      begin
        if not FileLikeName(Lits[K], Name, IsDir) then
          Continue;
        Idx := AItems.IndexOf(Name);
        if Idx < 0 then
        begin
          Ref := TRelRef.Create;
          Ref.Where := ExtractFileName(AFile) + ':' + IntToStr(I + 1);
          Ref.IsDir := IsDir;
          Idx := AItems.AddObject(Name, Ref);
        end;
        Ref := TRelRef(AItems.Objects[Idx]);
        Inc(Ref.Count);
        Ref.Uses_ := Ref.Uses_ + LineUses(SL, I, IsDfm);
      end;
    end;
  finally
    Lits.Free;
    SL.Free;
  end;
end;

procedure ScanReleaseRefs(const ADir: string; AItems: TStringList);
const
  Masks: array[0..3] of string = ('*.pas', '*.dpr', '*.inc', '*.dfm');
var
  M: Integer;
  SR: TSearchRec;
  Dir: string;
begin
  AItems.Sorted := True;
  AItems.CaseSensitive := False;
  AItems.Duplicates := dupIgnore;
  Dir := IncludeTrailingPathDelimiter(ADir);
  for M := Low(Masks) to High(Masks) do
    if FindFirst(Dir + Masks[M], faAnyFile and not faDirectory, SR) = 0 then
    try
      repeat
        // Маска по коротким именам находит и x.pas~ - сверяем ещё раз
        if CompareText(ExtractFileExt(SR.Name),
                       ExtractFileExt(Masks[M])) = 0 then
          ScanFile(Dir + SR.Name, AItems);
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
end;

end.
