unit IncCheck;

// ---------------------------------------------------------------------------
//  Проверка своих inc-файлов пользователя (INC Manager, Unit3):
//    - сравнение с эталоном - исходными inc, из которых собраны общие
//      rapidqAllProc.inc и rapidqComponents.inc (rapidq_ref\incOld);
//    - ошибки, которые уже встречались и исправлены в эталоне (суффиксы
//      чисел из C, директивы без $, CONST без =, незакрытые блоки ...), и
//      имена, которые есть и в общих inc (при подключении вместе - "already
//      defined");
//    - защитный $IFNDEF в начале файла;
//    - демо-программа, подключающая файл.
//  Без VCL: проверяется и вне редактора.
// ---------------------------------------------------------------------------

interface

uses
  SysUtils, Classes;

type
  TIncStatus = (isUnknown,  // не проверялся
                isSame,     // совпадает с эталоном (зелёный)
                isChanged,  // эталон с тем же именем есть, текст другой
                isNew);     // эталона нет - кандидат в хранилище

  // Ход долгой работы: AText - что делается; ACancel := True - прервать
  TIncProgress = procedure(const AText: string; var ACancel: Boolean) of object;
  // Найден файл (IncFindOnDisk) - полный путь
  TIncFound = procedure(const AFile: string) of object;

  TIncFileInfo = class
  public
    FileName: string;
    Status: TIncStatus;
    RefFile: string;        // эталон: совпавший по тексту или по имени
    Guard: string;          // защитный $IFNDEF в файле ('' - нет)
    RefGuard: string;       // защитный $IFNDEF эталона ('' - нет)
    Errors: Integer;        // сообщений уровня "ошибка"
    // Сообщения: текст; Objects - номер строки файла (с 1, 0 - без строки)
    Messages: TStringList;
    constructor Create(const AFileName: string);
    destructor Destroy; override;
    procedure AddMsg(ALine: Integer; AIsError: Boolean; const AText: string);
  end;

  // Эталон: файлы папки ARefDir по имени и по тексту, имена из общих inc
  TIncRefIndex = class
  private
    FRefDir: string;
    FSysDir: string;
    FNames: TStringList;    // ИМЯ.INC, Objects - индекс в FPaths
    FHashes: TStringList;   // ключ текста, Objects - индекс в FPaths
    FPaths: TStringList;
    FDefined: TStringList;  // имя, определённое в общих inc = файл
  public
    constructor Create;
    destructor Destroy; override;
    // AProgress - ход по файлам (может быть nil). False - прервано.
    function Load(const ARefDir, ASysDir: string;
                  AProgress: TIncProgress): Boolean;
    function FindByName(const AFileName: string): string;
    function FindByText(const ANormText: string): string;
    // Файл общих inc, где определено имя ('' - нигде)
    function DefinedIn(const AName: string): string;
    function RefCount: Integer;
    function DefinedCount: Integer;
    property RefDir: string read FRefDir;
    property SysDir: string read FSysDir;
  end;

// Файлы с расширением AExt ('.inc') в папке (и в подпапках при ASub) -
// полными путями в AList (nil - только счёт). Обход останавливается на
// AMax файлах. Результат - число найденных.
function FindFilesExt(const ADir, AExt: string; ASub: Boolean;
                      AList: TStrings; AMax: Integer): Integer;

// Строка без комментария: ACode - с содержимым строк "...", ABlank -
// строки заменены пробелами (для поиска ключевых слов). Обе без пробелов
// по краям.
procedure IncSplitLine(const ALine: string; var ACode, ABlank: string);

// Текст для сравнения с эталоном: без пустых строк, пробелов по краям,
// регистра и строк защитного $IFNDEF, поставленных при сведении (inc2026)
// или INC Manager
function IncNormalize(ALines: TStrings): string;

// Защитный $IFNDEF файла: первые две строки кода - $IFNDEF X и $DEFINE X.
// Результат - X или ''.
function IncFindGuard(ALines: TStrings): string;

// Имя защиты для файла: у эталона она есть - та же (тогда свой файл и
// общие inc друг друга исключают), иначе __ИМЯ_INC
function IncGuardName(AInfo: TIncFileInfo): string;

// Сравнение с эталоном и проверка файла; заполняет AInfo
procedure IncCheckFile(AInfo: TIncFileInfo; ARef: TIncRefIndex);

// Защитный $IFNDEF в начало и $ENDIF в конец файла. Прежний текст - в
// <файл>.bak (если такого ещё нет; ABackup = False - без него: файл - свежая
// копия). False - не поставлен, причина в AError.
function IncAddGuard(const AFile, AGuard: string; var AError: string;
                     ABackup: Boolean = True): Boolean;

// Имя папки содержит "inc" (inc, Include, MyIncs ...)
function IncDirName(const ADirName: string): Boolean;
// В пути к файлу есть папка с "inc" в имени
function IncPathInIncDir(const AFilePath: string): Boolean;

// Файлы с именем AName (без учёта регистра) в папках ARoots с подпапками -
// полными путями в AList. Служебные папки Windows пропускаются. В каждой
// папке подпапки с "inc" в имени обходятся первыми. AProgress - ход по
// папкам (nil - без него). AOnFound - сразу по каждому найденному файлу.
// False - прервано.
function IncFindOnDisk(const AName: string; ARoots, AList: TStrings;
                       AProgress: TIncProgress; ASkip: TStrings = nil;
                       AOnFound: TIncFound = nil): Boolean;

// То же для нескольких имён сразу: ANames - имена файлов в верхнем регистре,
// Sorted = True. Найденные - в AList полными путями.
function IncFindNamesOnDisk(ANames: TStringList; ARoots, AList: TStrings;
                            AProgress: TIncProgress; ASkip: TStrings = nil;
                            AOnFound: TIncFound = nil): Boolean;

// Программы .bas, подключающие файл ($INCLUDE "имя"), в папках AFolders
// (с подпапками при ASub). Результат - число найденных.
function IncFindDemos(const AIncFile: string; AFolders: TStrings;
                      ASub: Boolean; AList: TStrings): Integer;

// Новая демо-программа <имя>_demo.bas рядом с файлом: форма и по объекту
// каждого класса файла. Уже есть - не переписывается. Результат - путь,
// '' - не создана (причина в AError).
function IncMakeDemo(const AIncFile: string; var AError: string): string;

const
  IncStatusNames: array[TIncStatus] of string =
    ('не проверен', 'совпадает с эталоном', 'отличается от эталона',
     'нет в эталоне');

implementation

// Хеш текста (TextKey) считается с переполнением
{$Q-}{$R-}

const
  MaxFilesWalk = 20000;
  MaxClashMsgs = 30;

  // Встроенные классы rc.exe (Component.data, кроме QCOLORDIALOG: его
  // описывают inc, и rc.exe TYPE QCOLORDIALOG принимает) и QTHREAD - он не описан в
  // документации, но занят: TYPE QTHREAD даёт "Usertype QTHREAD already
  // used" (RqLcl\RAPIDQ_RULES.md)
  BuiltinClasses: array[0..55] of string = (
    'QFORM', 'QEDIT', 'QRICHEDIT', 'QLABEL', 'QBUTTON', 'QCOOLBTN',
    'QOVALBTN', 'QCHECKBOX', 'QRADIOBUTTON', 'QPANEL', 'QTABCONTROL',
    'QCOMBOBOX', 'QLISTBOX', 'QGROUPBOX', 'QSCROLLBOX', 'QSCROLLBAR',
    'QSTRINGGRID', 'QLISTVIEW', 'QDIRTREE', 'QFILELISTBOX', 'QTREEVIEW',
    'QOUTLINE', 'QGAUGE', 'QTRACKBAR', 'QHEADER', 'QSTATUSBAR', 'QCANVAS',
    'QIMAGE', 'QOLECONTAINER', 'QSPLITTER', 'QBITMAP', 'QIMAGELIST',
    'QSTRINGLIST', 'QTIMER', 'QSOCKET', 'QFILESTREAM', 'QMEMORYSTREAM',
    'QFONT', 'QMYSQL', 'QOLEOBJECT', 'QREGISTRY', 'QOPENDIALOG',
    'QSAVEDIALOG', 'QFONTDIALOG', 'QDXTIMER', 'QDXSOUND',
    'QDXSCREEN', 'QDXIMAGELIST', 'QD3DFACE', 'QD3DMESHBUILDER', 'QD3DFRAME',
    'QD3DLIGHT', 'QD3DTEXTURE', 'QD3DVECTOR', 'QD3DWRAP', 'QTHREAD');

type
  // Открытый блок для проверки END
  TIncBlock = record
    Kind: string;   // SUB, FUNCTION, TYPE, CREATE, $IF ...
    Line: Integer;
  end;

function IsBuiltinClass(const AName: string): Boolean;
var
  ClassIdx: Integer;
begin
  Result := False;
  for ClassIdx := Low(BuiltinClasses) to High(BuiltinClasses) do
    if CompareText(BuiltinClasses[ClassIdx], AName) = 0 then
    begin
      Result := True;
      Exit;
    end;
end;

function IsWordCh(ACh: Char): Boolean;
begin
  Result := ACh in ['A'..'Z', 'a'..'z', '0'..'9', '_', '$', '%', '&', '#',
                    '!', '@'];
end;

// Первое слово строки (до пробела, "(", "=", ":" или ",")
function FirstWord(const S: string): string;
var
  Pos1: Integer;
begin
  Pos1 := 1;
  while (Pos1 <= Length(S)) and not (S[Pos1] in [' ', #9, '(', '=', ':', ',']) do
    Inc(Pos1);
  Result := Copy(S, 1, Pos1 - 1);
end;

// Остаток строки после первого слова, без пробелов слева
function AfterWord(const S: string): string;
begin
  Result := TrimLeft(Copy(S, Length(FirstWord(S)) + 1, Length(S)));
end;

// Строка начинается словом AWord (за ним пробел, конец строки или "(")
function StartsWord(const S, AWord: string): Boolean;
begin
  Result := (CompareText(Copy(S, 1, Length(AWord)), AWord) = 0) and
            ((Length(S) = Length(AWord)) or
             (S[Length(AWord) + 1] in [' ', #9, '(', ':']));
end;

// Имя после ключевого слова: "SUB Foo(...)" -> Foo
function NameAfter(const S, AKeyword: string): string;
begin
  Result := FirstWord(TrimLeft(Copy(S, Length(AKeyword) + 1, Length(S))));
end;

// "TYPE Имя AS Тип" - однострочный синоним типа (FreeBASIC), без END TYPE
function IsTypeAlias(const AUp: string): Boolean;
begin
  Result := StartsWord(TrimLeft(AfterWord(AfterWord(AUp))), 'AS');
end;

// Операторы строки через ":" (строки уже заменены пробелами - двоеточий
// в них нет): "SUB Foo: END SUB" - два оператора
procedure SplitStatements(const ABlank: string; AList: TStrings);
var
  Rest: string;
  ColonPos: Integer;
begin
  AList.Clear;
  Rest := ABlank;
  repeat
    ColonPos := Pos(':', Rest);
    if ColonPos = 0 then
    begin
      if Trim(Rest) <> '' then
        AList.Add(Trim(Rest));
      Break;
    end;
    if Trim(Copy(Rest, 1, ColonPos - 1)) <> '' then
      AList.Add(Trim(Copy(Rest, 1, ColonPos - 1)));
    Rest := Copy(Rest, ColonPos + 1, MaxInt);
  until False;
end;

function FindFilesExt(const ADir, AExt: string; ASub: Boolean;
                      AList: TStrings; AMax: Integer): Integer;
var
  Found: Integer;

  procedure Walk(const ADirPath: string);
  var
    SR: TSearchRec;
  begin
    if Found >= AMax then
      Exit;
    // Маска *.inc по коротким именам находит и file.inc~ - расширение
    // сверяется ещё раз
    if FindFirst(ADirPath + '*' + AExt, faAnyFile, SR) = 0 then
    try
      repeat
        if ((SR.Attr and faDirectory) = 0) and
           (CompareText(ExtractFileExt(SR.Name), AExt) = 0) then
        begin
          if AList <> nil then
            AList.Add(ADirPath + SR.Name);
          Inc(Found);
          if Found >= AMax then
            Exit;
        end;
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
    if not ASub then
      Exit;
    if FindFirst(ADirPath + '*', faDirectory, SR) = 0 then
    try
      repeat
        if ((SR.Attr and faDirectory) <> 0) and (SR.Name <> '.') and
           (SR.Name <> '..') then
          Walk(ADirPath + SR.Name + PathDelim);
        if Found >= AMax then
          Exit;
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
  end;

begin
  Found := 0;
  if (ADir <> '') and DirectoryExists(ADir) then
    Walk(IncludeTrailingPathDelimiter(ADir));
  Result := Found;
end;

procedure IncSplitLine(const ALine: string; var ACode, ABlank: string);
var
  CharIdx: Integer;
  InStr: Boolean;
  Code, Blank: string;
begin
  Code := ALine;
  Blank := ALine;
  InStr := False;
  for CharIdx := 1 to Length(ALine) do
  begin
    if ALine[CharIdx] = '"' then
      InStr := not InStr
    else if InStr then
      Blank[CharIdx] := ' '
    else if ALine[CharIdx] = '''' then
    begin
      Code := Copy(ALine, 1, CharIdx - 1);
      Blank := Copy(Blank, 1, CharIdx - 1);
      Break;
    end;
  end;
  ACode := Trim(Code);
  ABlank := Trim(Blank);
  if StartsWord(ABlank, 'REM') then
  begin
    ACode := '';
    ABlank := '';
  end;
end;

// Строка защитного $IFNDEF, поставленная при сведении или INC Manager
function IsAddedGuardLine(const ALine: string): Boolean;
var
  Code, Blank, Up: string;
begin
  Result := False;
  Up := UpperCase(ALine);
  if (Pos('INC2026', Up) = 0) and (Pos('INCMANAGER', Up) = 0) then
    Exit;
  IncSplitLine(ALine, Code, Blank);
  Code := UpperCase(Code);
  Result := (Code = '$ENDIF') or
            ((StartsWord(Code, '$IFNDEF') or StartsWord(Code, '$DEFINE')) and
             (Copy(AfterWord(Code), 1, 2) = '__'));
end;

function IncNormalize(ALines: TStrings): string;
var
  LineIdx: Integer;
  Line: string;
  Parts: TStringList;
begin
  Parts := TStringList.Create;
  try
    for LineIdx := 0 to ALines.Count - 1 do
    begin
      Line := Trim(ALines[LineIdx]);
      if (Line = '') or IsAddedGuardLine(Line) then
        Continue;
      Parts.Add(UpperCase(Line));
    end;
    Result := Parts.Text;
  finally
    Parts.Free;
  end;
end;

// Ключ текста для поиска совпадений: FNV-1a и длина
function TextKey(const S: string): string;
var
  Hash: Cardinal;
  CharIdx: Integer;
begin
  Hash := 2166136261;
  for CharIdx := 1 to Length(S) do
  begin
    Hash := Hash xor Ord(S[CharIdx]);
    Hash := Hash * 16777619;
  end;
  Result := IntToHex(Hash, 8) + ':' + IntToStr(Length(S));
end;

function IncFindGuard(ALines: TStrings): string;
var
  LineIdx: Integer;
  Code, Blank, First: string;
begin
  Result := '';
  First := '';
  for LineIdx := 0 to ALines.Count - 1 do
  begin
    IncSplitLine(ALines[LineIdx], Code, Blank);
    if Code = '' then
      Continue;
    if First = '' then
    begin
      if not StartsWord(Code, '$IFNDEF') then
        Exit;
      First := FirstWord(AfterWord(Code));
      if First = '' then
        Exit;
    end
    else
    begin
      // $DEFINE X без значения: "$IFNDEF TRUE / $DEFINE True 1" - не
      // защита файла, а константа
      if StartsWord(Code, '$DEFINE') and
         (CompareText(FirstWord(AfterWord(Code)), First) = 0) and
         (Trim(AfterWord(AfterWord(Code))) = '') then
        Result := First;
      Exit;
    end;
  end;
end;

// Имена, определённые на уровне файла: CONST, TYPE, SUB/FUNCTION вне
// классов, DECLARE, $DEFINE, DIM и CREATE вне процедур. ANames: ИМЯ, Objects
// - номер строки (с 1). Имена защиты (__X) не считаются.
procedure IncDefinedNames(ALines: TStrings; ANames: TStrings);
var
  LineIdx, TypeDepth, ProcDepth, StmtIdx: Integer;
  Code, Blank, Up: string;
  InBrem: Boolean;
  Stmts: TStringList;

  procedure AddName(const AName: string);
  begin
    if (AName = '') or (Copy(AName, 1, 2) = '__') then
      Exit;
    ANames.AddObject(UpperCase(AName), TObject(LineIdx + 1));
  end;

  // Один оператор строки (Up - без строк, в верхнем регистре)
  procedure DoStatement(const Up: string);
  var
    Name, Kw: string;
  begin
    Kw := FirstWord(Up);
    if (Kw = 'END') then
    begin
      Kw := FirstWord(AfterWord(Up));
      if Kw = 'TYPE' then
      begin
        if TypeDepth > 0 then
          Dec(TypeDepth);
      end
      else if (Kw = 'SUB') or (Kw = 'FUNCTION') or (Kw = 'SUBI') or
              (Kw = 'FUNCTIONI') then
      begin
        if ProcDepth > 0 then
          Dec(ProcDepth);
      end;
      Exit;
    end;
    if Kw = 'TYPE' then
    begin
      if TypeDepth = 0 then
        AddName(NameAfter(Up, 'TYPE'));
      if not IsTypeAlias(Up) then
        Inc(TypeDepth);
    end
    else if (Kw = 'SUB') or (Kw = 'FUNCTION') or (Kw = 'SUBI') or
            (Kw = 'FUNCTIONI') then
    begin
      if (TypeDepth = 0) and (ProcDepth = 0) then
      begin
        Name := NameAfter(Up, Kw);
        // FUNCTION Foo$ и Foo - одно имя
        if (Name <> '') and (Name[Length(Name)] in ['$', '%', '&', '#', '!']) then
          SetLength(Name, Length(Name) - 1);
        AddName(Name);
      end;
      Inc(ProcDepth);
    end
    else if (TypeDepth > 0) or (ProcDepth > 0) then
      Exit
    else if Kw = 'CONST' then
      AddName(NameAfter(Up, 'CONST'))
    else if Kw = 'DECLARE' then
    begin
      Name := AfterWord(Up);
      Kw := FirstWord(Name);
      if (Kw = 'SUB') or (Kw = 'FUNCTION') or (Kw = 'SUBI') or
         (Kw = 'FUNCTIONI') then
      begin
        Name := NameAfter(Name, Kw);
        if (Name <> '') and (Name[Length(Name)] in ['$', '%', '&', '#', '!']) then
          SetLength(Name, Length(Name) - 1);
        AddName(Name);
      end;
    end
    else if Kw = '$DEFINE' then
      AddName(NameAfter(Up, '$DEFINE'))
    else if (Kw = 'DIM') or (Kw = 'CREATE') then
      AddName(NameAfter(Up, Kw));
  end;

begin
  Stmts := TStringList.Create;
  try
    TypeDepth := 0;
    ProcDepth := 0;
    InBrem := False;
    for LineIdx := 0 to ALines.Count - 1 do
    begin
      IncSplitLine(ALines[LineIdx], Code, Blank);
      Up := UpperCase(Blank);
      if Up = '' then
        Continue;
      if InBrem then
      begin
        if StartsWord(Up, 'EREM') then
          InBrem := False;
        Continue;
      end;
      if StartsWord(Up, 'BREM') then
      begin
        InBrem := True;
        Continue;
      end;
      SplitStatements(UpperCase(Blank), Stmts);
      for StmtIdx := 0 to Stmts.Count - 1 do
        DoStatement(Stmts[StmtIdx]);
    end;
  finally
    Stmts.Free;
  end;
end;

{ TIncFileInfo }

constructor TIncFileInfo.Create(const AFileName: string);
begin
  inherited Create;
  FileName := AFileName;
  Messages := TStringList.Create;
end;

destructor TIncFileInfo.Destroy;
begin
  Messages.Free;
  inherited;
end;

procedure TIncFileInfo.AddMsg(ALine: Integer; AIsError: Boolean;
                              const AText: string);
var
  Prefix: string;
begin
  if AIsError then
  begin
    Prefix := 'ошибка: ';
    Inc(Errors);
  end
  else
    Prefix := '';
  if ALine > 0 then
    Messages.AddObject(Format('стр. %d: %s%s', [ALine, Prefix, AText]),
                       TObject(ALine))
  else
    Messages.AddObject(Prefix + AText, TObject(0));
end;

{ TIncRefIndex }

constructor TIncRefIndex.Create;
begin
  inherited Create;
  FNames := TStringList.Create;
  FNames.Sorted := True;
  FNames.Duplicates := dupIgnore;
  FHashes := TStringList.Create;
  FHashes.Sorted := True;
  FHashes.Duplicates := dupIgnore;
  FPaths := TStringList.Create;
  FDefined := TStringList.Create;
  FDefined.Sorted := True;
  FDefined.Duplicates := dupIgnore;
end;

destructor TIncRefIndex.Destroy;
begin
  FDefined.Free;
  FPaths.Free;
  FHashes.Free;
  FNames.Free;
  inherited;
end;

function TIncRefIndex.Load(const ARefDir, ASysDir: string;
                           AProgress: TIncProgress): Boolean;
var
  Files, Lines, Names: TStringList;
  FileIdx, PathIdx, NameIdx: Integer;
  Cancel: Boolean;
begin
  Result := False;
  Cancel := False;
  FRefDir := ARefDir;
  FSysDir := ASysDir;
  FNames.Clear;
  FHashes.Clear;
  FPaths.Clear;
  FDefined.Clear;
  Files := TStringList.Create;
  Lines := TStringList.Create;
  Names := TStringList.Create;
  try
    FindFilesExt(ARefDir, '.inc', False, Files, MaxFilesWalk);
    for FileIdx := 0 to Files.Count - 1 do
    begin
      if Assigned(AProgress) then
      begin
        AProgress(Format('Эталон: %d из %d - %s',
                         [FileIdx + 1, Files.Count,
                          ExtractFileName(Files[FileIdx])]), Cancel);
        if Cancel then
          Exit;
      end;
      PathIdx := FPaths.Add(Files[FileIdx]);
      FNames.AddObject(UpperCase(ExtractFileName(Files[FileIdx])),
                       TObject(PathIdx));
      try
        Lines.LoadFromFile(Files[FileIdx]);
      except
        Lines.Clear;
      end;
      FHashes.AddObject(TextKey(IncNormalize(Lines)), TObject(PathIdx));
    end;

    // Имена общих inc - для повторов при подключении вместе
    Files.Clear;
    FindFilesExt(ASysDir, '.inc', False, Files, MaxFilesWalk);
    for FileIdx := 0 to Files.Count - 1 do
    begin
      if Assigned(AProgress) then
      begin
        AProgress('Имена общих inc: ' + ExtractFileName(Files[FileIdx]),
                  Cancel);
        if Cancel then
          Exit;
      end;
      try
        Lines.LoadFromFile(Files[FileIdx]);
      except
        Lines.Clear;
      end;
      Names.Clear;
      IncDefinedNames(Lines, Names);
      for NameIdx := 0 to Names.Count - 1 do
        FDefined.Add(Names[NameIdx] + '=' + ExtractFileName(Files[FileIdx]));
    end;
    Result := True;
  finally
    Names.Free;
    Lines.Free;
    Files.Free;
  end;
end;

function TIncRefIndex.FindByName(const AFileName: string): string;
var
  Idx: Integer;
begin
  Result := '';
  if FNames.Find(UpperCase(ExtractFileName(AFileName)), Idx) then
    Result := FPaths[Integer(FNames.Objects[Idx])];
end;

function TIncRefIndex.FindByText(const ANormText: string): string;
var
  Idx: Integer;
begin
  Result := '';
  if FHashes.Find(TextKey(ANormText), Idx) then
    Result := FPaths[Integer(FHashes.Objects[Idx])];
end;

function TIncRefIndex.DefinedIn(const AName: string): string;
var
  Idx: Integer;
  Key: string;
begin
  Result := '';
  Key := UpperCase(AName) + '=';
  // Строки "ИМЯ=файл" отсортированы: первая с этим началом - после Find
  FDefined.Find(Key, Idx);
  if (Idx < FDefined.Count) and
     (Copy(FDefined[Idx], 1, Length(Key)) = Key) then
    Result := Copy(FDefined[Idx], Length(Key) + 1, MaxInt);
end;

function TIncRefIndex.RefCount: Integer;
begin
  Result := FPaths.Count;
end;

function TIncRefIndex.DefinedCount: Integer;
begin
  Result := FDefined.Count;
end;

function IncGuardName(AInfo: TIncFileInfo): string;
var
  Base: string;
  CharIdx: Integer;
begin
  if AInfo.Guard <> '' then
  begin
    Result := AInfo.Guard;
    Exit;
  end;
  if AInfo.RefGuard <> '' then
  begin
    Result := AInfo.RefGuard;
    Exit;
  end;
  Base := UpperCase(ChangeFileExt(ExtractFileName(AInfo.FileName), ''));
  for CharIdx := 1 to Length(Base) do
    if not (Base[CharIdx] in ['A'..'Z', '0'..'9', '_']) then
      Base[CharIdx] := '_';
  Result := '__' + Base + '_INC';
end;

// Проверки текста файла: строки, блоки, имена из общих inc
procedure CheckLines(AInfo: TIncFileInfo; ALines: TStrings;
                     ARef: TIncRefIndex);
var
  Blocks: array of TIncBlock;
  BlockCount, LineIdx, CharIdx, NumStart, NameIdx, Clashes: Integer;
  Code, Blank, Up, Kw, Kw2, Name, Arg, IncName, DefFile, ClashList: string;
  InBrem: Boolean;
  Names, Stmts: TStringList;
  StmtIdx: Integer;
  StUp, StKw: string;

  procedure Push(const AKind: string);
  begin
    if BlockCount >= Length(Blocks) then
      SetLength(Blocks, BlockCount + 32);
    Blocks[BlockCount].Kind := AKind;
    Blocks[BlockCount].Line := LineIdx + 1;
    Inc(BlockCount);
  end;

  // END <AKind>: закрывает верхний блок того же вида
  procedure Close(const AKind, AShown: string);
  var
    Top: string;
  begin
    if BlockCount = 0 then
    begin
      AInfo.AddMsg(LineIdx + 1, True, AShown + ' без начала блока');
      Exit;
    end;
    Top := Blocks[BlockCount - 1].Kind;
    if Top <> AKind then
      AInfo.AddMsg(LineIdx + 1, True, AShown + ' закрывает ' + Top +
                   ' (стр. ' + IntToStr(Blocks[BlockCount - 1].Line) + ')');
    Dec(BlockCount);
  end;

  function IncludeFound(const AName: string): Boolean;
  var
    Dir: string;
  begin
    Dir := ExtractFilePath(AInfo.FileName);
    Result := FileExists(AName) or FileExists(Dir + AName) or
              ((ARef.SysDir <> '') and
               FileExists(IncludeTrailingPathDelimiter(ARef.SysDir) + AName)) or
              ((ARef.RefDir <> '') and
               FileExists(IncludeTrailingPathDelimiter(ARef.RefDir) + AName));
  end;

begin
  BlockCount := 0;
  SetLength(Blocks, 32);
  InBrem := False;
  Stmts := TStringList.Create;
  try
    for LineIdx := 0 to ALines.Count - 1 do
    begin
      IncSplitLine(ALines[LineIdx], Code, Blank);
      Up := UpperCase(Blank);
      if Up = '' then
        Continue;
      if InBrem then
      begin
        if StartsWord(Up, 'EREM') then
          InBrem := False;
        Continue;
      end;
      if StartsWord(Up, 'BREM') then
      begin
        InBrem := True;
        Continue;
      end;
      Kw := FirstWord(Up);

      // Директива без $
      if (Kw = 'DEFINE') or (Kw = 'UNDEF') or (Kw = 'IFDEF') or
         (Kw = 'IFNDEF') or (Kw = 'ENDIF') or (Kw = 'INCLUDE') then
        AInfo.AddMsg(LineIdx + 1, True, Kw + ' без $ - нужно $' + Kw);

      // Числа с суффиксом из C (880U, 10L) и 0x-запись
      CharIdx := 1;
      while CharIdx <= Length(Up) do
      begin
        if (Up[CharIdx] in ['0'..'9']) and
           ((CharIdx = 1) or not IsWordCh(Up[CharIdx - 1])) then
        begin
          NumStart := CharIdx;
          if (Up[CharIdx] = '0') and (CharIdx < Length(Up)) and
             (Up[CharIdx + 1] = 'X') then
          begin
            AInfo.AddMsg(LineIdx + 1, True, 'запись 0x из C - в RapidQ &H');
            Inc(CharIdx, 2);
            while (CharIdx <= Length(Up)) and IsWordCh(Up[CharIdx]) do
              Inc(CharIdx);
            Continue;
          end;
          while (CharIdx <= Length(Up)) and (Up[CharIdx] in ['0'..'9', '.']) do
            Inc(CharIdx);
          if (CharIdx <= Length(Up)) and (Up[CharIdx] in ['U', 'L']) and
             ((CharIdx = Length(Up)) or not IsWordCh(Up[CharIdx + 1]) or
              (Up[CharIdx + 1] in ['U', 'L'])) then
            AInfo.AddMsg(LineIdx + 1, True, 'число ' +
                         Copy(Code, NumStart, CharIdx - NumStart + 1) +
                         '...: суффикс U/L из C, в RapidQ его нет');
          while (CharIdx <= Length(Up)) and IsWordCh(Up[CharIdx]) do
            Inc(CharIdx);
          Continue;
        end;
        Inc(CharIdx);
      end;

      // ";" вне строк (кроме PRINT): комментарий ассемблера или C
      if (Pos(';', Up) > 0) and (Pos('PRINT', Up) = 0) then
        AInfo.AddMsg(LineIdx + 1, True, '";" вне строки - в RapidQ ' +
                     'комментарий начинается с ''');

      if Kw = 'CONST' then
      begin
        if Pos('=', Up) = 0 then
          AInfo.AddMsg(LineIdx + 1, True, 'CONST без =');
      end
      else if (Kw = '$OPTION') and (Pos('TRAPALL', Up) > 0) then
        AInfo.AddMsg(LineIdx + 1, False, '$OPTION INKEY$ TRAPALL меняет ' +
                     'поведение всей программы, которая подключит файл')
      else if (Kw = '$DEFINE') or (Kw = '$UNDEF') then
      begin
        Arg := NameAfter(Up, Kw);
        if IsBuiltinClass(Arg) then
          AInfo.AddMsg(LineIdx + 1, True, Kw + ' ' + Arg + ' переопределяет ' +
                       'встроенный класс - ломает и другие inc, и программу')
        else if (Kw = '$UNDEF') and (Copy(Arg, 1, 2) <> '__') then
          AInfo.AddMsg(LineIdx + 1, False, '$UNDEF ' + Arg + ' убирает имя ' +
                       'и для файлов, подключённых раньше');
      end
      else if Kw = 'TYPE' then
      begin
        Arg := NameAfter(Up, 'TYPE');
        if IsBuiltinClass(Arg) then
          AInfo.AddMsg(LineIdx + 1, True, 'TYPE ' + Arg + ': имя встроенного ' +
                       'класса rc.exe ("Usertype ' + Arg + ' already used")');
      end
      else if Kw = '$INCLUDE' then
      begin
        IncName := Trim(AfterWord(Code));
        if (IncName <> '') and (IncName[1] in ['"', '<']) then
          IncName := Copy(IncName, 2, Length(IncName) - 2);
        if (IncName <> '') and not IncludeFound(IncName) then
          AInfo.AddMsg(LineIdx + 1, False, '$INCLUDE "' + IncName +
                       '": файл не найден ни рядом, ни в общих, ни в эталоне');
      end;

      // Блоки - по операторам строки: "SUB Foo: END SUB", "END WITH : END SUB"
      SplitStatements(Up, Stmts);
      for StmtIdx := 0 to Stmts.Count - 1 do
      begin
        StUp := Stmts[StmtIdx];
        // PRIVATE TYPE, PUBLIC SUB (код из VB) - по слову за ними
        StKw := FirstWord(StUp);
        if (StKw = 'PRIVATE') or (StKw = 'PUBLIC') then
        begin
          StUp := AfterWord(StUp);
          StKw := FirstWord(StUp);
        end;
        if StKw = 'END' then
        begin
          Kw2 := FirstWord(AfterWord(StUp));
          if (Kw2 = 'SUB') or (Kw2 = 'SUBI') then
            Close('SUB', 'END ' + Kw2)
          else if (Kw2 = 'FUNCTION') or (Kw2 = 'FUNCTIONI') then
            Close('FUNCTION', 'END ' + Kw2)
          else if (Kw2 = 'TYPE') or (Kw2 = 'CREATE') or (Kw2 = 'WITH') or
                  (Kw2 = 'SELECT') or (Kw2 = 'CONSTRUCTOR') or
                  (Kw2 = 'EVENT') or (Kw2 = 'PROPERTY') then
            Close(Kw2, 'END ' + Kw2);
        end
        else if (StKw = 'SUB') or (StKw = 'SUBI') then
          Push('SUB')
        else if (StKw = 'FUNCTION') or (StKw = 'FUNCTIONI') then
          Push('FUNCTION')
        else if (StKw = 'TYPE') and IsTypeAlias(StUp) then
          // однострочный синоним - блока нет
        else if (StKw = 'TYPE') or (StKw = 'CREATE') or (StKw = 'WITH') or
                (StKw = 'CONSTRUCTOR') or (StKw = 'EVENT') then
          Push(StKw)
        else if (StKw = 'SELECT') and (FirstWord(AfterWord(StUp)) = 'CASE') then
          Push('SELECT')
        else if (StKw = 'PROPERTY') and (FirstWord(AfterWord(StUp)) = 'SET') then
          Push('PROPERTY')
        else if (StKw = '$IFDEF') or (StKw = '$IFNDEF') or (StKw = '$IF') then
          Push('$IF')
        else if StKw = '$ENDIF' then
          Close('$IF', '$ENDIF');
      end;
    end;
    for LineIdx := BlockCount - 1 downto 0 do
      if Blocks[LineIdx].Kind = '$IF' then
        AInfo.AddMsg(Blocks[LineIdx].Line, True, 'нет $ENDIF')
      else
        AInfo.AddMsg(Blocks[LineIdx].Line, True, 'нет END ' +
                     Blocks[LineIdx].Kind);
  finally
    Stmts.Free;
  end;

  // Имена, которые есть и в общих inc. Файлу, совпавшему с эталоном или
  // отличающемуся от него, они и должны совпадать - для него только итог.
  if ARef.DefinedCount = 0 then
    Exit;
  Names := TStringList.Create;
  try
    IncDefinedNames(ALines, Names);
    Clashes := 0;
    ClashList := '';
    for NameIdx := 0 to Names.Count - 1 do
    begin
      DefFile := ARef.DefinedIn(Names[NameIdx]);
      if DefFile = '' then
        Continue;
      Inc(Clashes);
      if AInfo.Status = isNew then
      begin
        if Clashes <= MaxClashMsgs then
          AInfo.AddMsg(Integer(Names.Objects[NameIdx]), False,
                       Names[NameIdx] + ' есть и в ' + DefFile +
                       ': при подключении вместе - "already defined"');
      end
      else if Clashes <= 5 then
      begin
        if ClashList <> '' then
          ClashList := ClashList + ', ';
        ClashList := ClashList + Names[NameIdx];
      end;
    end;
    if (AInfo.Status = isNew) and (Clashes > MaxClashMsgs) then
      AInfo.AddMsg(0, False, Format('и ещё имён, которые есть в общих ' +
                                    'inc: %d', [Clashes - MaxClashMsgs]));
    if (AInfo.Status <> isNew) and (Clashes > 0) then
    begin
      if Clashes > 5 then
        ClashList := ClashList + ' ...';
      if (AInfo.Guard <> '') and (AInfo.Guard = AInfo.RefGuard) then
        AInfo.AddMsg(0, False, Format('имён из общих inc: %d (%s) - защита ' +
                     '%s та же, что в общих inc: вместе подключится один ' +
                     'из файлов', [Clashes, ClashList, AInfo.Guard]))
      else
        AInfo.AddMsg(0, False, Format('имён из общих inc: %d (%s) - при ' +
                     'подключении вместе с общими будет "already defined"; ' +
                     'защитный $IFNDEF %s исключит повтор',
                     [Clashes, ClashList, IncGuardName(AInfo)]));
    end;
  finally
    Names.Free;
  end;
end;

// Исправления эталона (строки с "inc2026:"), которых нет в файле. Номер
// строки в файле - по ближайшей предыдущей строке эталона, найденной в нём.
procedure CheckRefFixes(AInfo: TIncFileInfo; ALines, ARefLines: TStrings);
var
  UserNorm: TStringList;
  RefIdx, UserIdx, LastFound, Shown, Hidden: Integer;
  Line, Up, Code, Blank, Note: string;
  Fixed: Boolean;
begin
  UserNorm := TStringList.Create;
  try
    for UserIdx := 0 to ALines.Count - 1 do
    begin
      IncSplitLine(ALines[UserIdx], Code, Blank);
      UserNorm.Add(UpperCase(Code));
    end;
    LastFound := -1;
    Shown := 0;
    Hidden := 0;
    for RefIdx := 0 to ARefLines.Count - 1 do
    begin
      Line := ARefLines[RefIdx];
      IncSplitLine(Line, Code, Blank);
      Up := UpperCase(Code);
      if Pos('INC2026:', UpperCase(Line)) = 0 then
      begin
        // Опорная строка для номера: первая такая же после прошлой
        if Up <> '' then
          for UserIdx := LastFound + 1 to UserNorm.Count - 1 do
            if UserNorm[UserIdx] = Up then
            begin
              LastFound := UserIdx;
              Break;
            end;
        Continue;
      end;
      if IsAddedGuardLine(Line) then
        Continue;
      // Исправленная строка есть в файле на том же месте (сразу за
      // опорной, с запасом в пару строк) - исправление уже сделано
      if Up <> '' then
      begin
        Fixed := False;
        for UserIdx := LastFound + 1 to LastFound + 3 do
          if (UserIdx >= 0) and (UserIdx < UserNorm.Count) and
             (UserNorm[UserIdx] = Up) then
          begin
            Fixed := True;
            LastFound := UserIdx;
            Break;
          end;
        if Fixed then
          Continue;
      end;
      Note := Copy(Line, Pos('INC2026:', UpperCase(Line)) + 8, MaxInt);
      Note := Trim(Note);
      if Shown >= 40 then
      begin
        Inc(Hidden);
        Continue;
      end;
      Inc(Shown);
      AInfo.AddMsg(LastFound + 2, True, 'в эталоне исправлено (' +
                   ExtractFileName(AInfo.RefFile) + ', стр. ' +
                   IntToStr(RefIdx + 1) + '): ' + Note);
    end;
    if Hidden > 0 then
      AInfo.AddMsg(0, True, Format('и ещё исправлений эталона: %d', [Hidden]));
  finally
    UserNorm.Free;
  end;
end;

procedure IncCheckFile(AInfo: TIncFileInfo; ARef: TIncRefIndex);
var
  Lines, RefLines: TStringList;
  Norm, ByText, ByName: string;
begin
  AInfo.Messages.Clear;
  AInfo.Errors := 0;
  AInfo.Status := isUnknown;
  AInfo.RefFile := '';
  AInfo.Guard := '';
  AInfo.RefGuard := '';
  Lines := TStringList.Create;
  RefLines := TStringList.Create;
  try
    try
      Lines.LoadFromFile(AInfo.FileName);
    except
      on E: Exception do
      begin
        AInfo.AddMsg(0, True, 'не прочитан: ' + E.Message);
        Exit;
      end;
    end;
    AInfo.Guard := IncFindGuard(Lines);
    Norm := IncNormalize(Lines);
    ByText := ARef.FindByText(Norm);
    // Ключ совпал - сверяем сам текст
    if ByText <> '' then
    begin
      RefLines.LoadFromFile(ByText);
      if IncNormalize(RefLines) <> Norm then
        ByText := '';
    end;
    ByName := ARef.FindByName(AInfo.FileName);
    if ByText <> '' then
    begin
      AInfo.Status := isSame;
      AInfo.RefFile := ByText;
    end
    else if ByName <> '' then
    begin
      AInfo.Status := isChanged;
      AInfo.RefFile := ByName;
      RefLines.LoadFromFile(ByName);
    end
    else
      AInfo.Status := isNew;
    if AInfo.RefFile <> '' then
      AInfo.RefGuard := IncFindGuard(RefLines);

    if AInfo.Status = isSame then
    begin
      if CompareText(ExtractFileName(AInfo.RefFile),
                     ExtractFileName(AInfo.FileName)) <> 0 then
        AInfo.AddMsg(0, False, 'совпадает с эталоном ' +
                     ExtractFileName(AInfo.RefFile) + ' (другое имя файла)');
      // Ошибки эталон уже прошёл - проверять нечего, кроме защиты
    end
    else
    begin
      if AInfo.Status = isChanged then
        CheckRefFixes(AInfo, Lines, RefLines);
      CheckLines(AInfo, Lines, ARef);
    end;
    if AInfo.Guard = '' then
      AInfo.AddMsg(0, False, 'нет защитного $IFNDEF (шаг 4: ' +
                   IncGuardName(AInfo) + ')')
    else if (AInfo.RefGuard <> '') and
            (CompareText(AInfo.Guard, AInfo.RefGuard) <> 0) then
      AInfo.AddMsg(0, False, 'защита ' + AInfo.Guard + ' не та, что в ' +
                   'эталоне (' + AInfo.RefGuard + '): с общими inc ' +
                   'подключатся оба файла');
  finally
    RefLines.Free;
    Lines.Free;
  end;
end;

function IncAddGuard(const AFile, AGuard: string; var AError: string;
                     ABackup: Boolean): Boolean;
var
  Stream: TFileStream;
  Text, Orig, Eol, Backup: string;
  Lines: TStringList;
begin
  Result := False;
  AError := '';
  Lines := TStringList.Create;
  try
    try
      Stream := TFileStream.Create(AFile, fmOpenRead or fmShareDenyWrite);
      try
        SetLength(Text, Stream.Size);
        if Stream.Size > 0 then
          Stream.ReadBuffer(Text[1], Stream.Size);
      finally
        Stream.Free;
      end;
    except
      on E: Exception do
      begin
        AError := E.Message;
        Exit;
      end;
    end;
    Orig := Text;
    Lines.Text := Text;
    if IncFindGuard(Lines) <> '' then
    begin
      AError := 'защита уже есть: ' + IncFindGuard(Lines);
      Exit;
    end;
    if Pos(#13#10, Text) > 0 then
      Eol := #13#10
    else if Pos(#10, Text) > 0 then
      Eol := #10
    else
      Eol := #13#10;
    if (Text <> '') and not (Text[Length(Text)] in [#13, #10]) then
      Text := Text + Eol;
    // Комментарий латиницей: файл бывает и в UTF-8, и в Windows-1251
    Text := '$IFNDEF ' + AGuard + '   '' IncManager: include guard' + Eol +
            '$DEFINE ' + AGuard + Eol +
            Text +
            '$ENDIF   '' IncManager: ' + AGuard + Eol;

    // Прежний текст - рядом; уже лежащий .bak не трогаем: в нём оригинал
    Backup := AFile + '.bak';
    try
      if ABackup and not FileExists(Backup) then
      begin
        Stream := TFileStream.Create(Backup, fmCreate);
        try
          if Length(Orig) > 0 then
            Stream.WriteBuffer(Orig[1], Length(Orig));
        finally
          Stream.Free;
        end;
      end;
      Stream := TFileStream.Create(AFile, fmCreate);
      try
        Stream.WriteBuffer(Text[1], Length(Text));
      finally
        Stream.Free;
      end;
    except
      on E: Exception do
      begin
        AError := E.Message;
        Exit;
      end;
    end;
    Result := True;
  finally
    Lines.Free;
  end;
end;

// Имя папки содержит "inc" (inc, Include, MyIncs ...) - там ищем первыми
function IncDirName(const ADirName: string): Boolean;
begin
  Result := Pos('INC', UpperCase(ADirName)) > 0;
end;

// В пути к файлу есть папка с "inc" в имени
function IncPathInIncDir(const AFilePath: string): Boolean;
var
  Rest, Part: string;
  SepPos: Integer;
begin
  Result := False;
  Rest := ExtractFilePath(AFilePath);
  while Rest <> '' do
  begin
    SepPos := Pos(PathDelim, Rest);
    if SepPos = 0 then
    begin
      Part := Rest;
      Rest := '';
    end
    else
    begin
      Part := Copy(Rest, 1, SepPos - 1);
      Delete(Rest, 1, SepPos);
    end;
    if (Part <> '') and (Pos(':', Part) = 0) and IncDirName(Part) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

function IncFindNamesOnDisk(ANames: TStringList; ARoots, AList: TStrings;
                            AProgress: TIncProgress; ASkip: TStrings;
                            AOnFound: TIncFound): Boolean;
var
  NameIdx: Integer;
  Cancel: Boolean;

  // Папки, где своих inc не бывает, а файлов - сотни тысяч
  function SkipDir(const ADirName: string): Boolean;
  begin
    Result := (CompareText(ADirName, 'Windows') = 0) or
              (CompareText(ADirName, '$Recycle.Bin') = 0) or
              (CompareText(ADirName, 'System Volume Information') = 0) or
              (CompareText(ADirName, 'RECYCLER') = 0) or
              (CompareText(ADirName, 'WinSxS') = 0);
  end;

  procedure Walk(const ADirPath: string);
  var
    SR: TSearchRec;
    IncDirs, OtherDirs: TStringList;
    DirIdx: Integer;
  begin
    if Cancel then
      Exit;
    // Папка уже просмотрена раньше (ASkip: пути в верхнем регистре со \)
    if (ASkip <> nil) and (ASkip.IndexOf(UpperCase(ADirPath)) >= 0) then
      Exit;
    if Assigned(AProgress) then
    begin
      AProgress('Поиск: ' + ADirPath, Cancel);
      if Cancel then
        Exit;
    end;
    // Сначала файлы этой папки, потом подпапки: с "inc" в имени - первыми
    IncDirs := TStringList.Create;
    OtherDirs := TStringList.Create;
    try
      if FindFirst(ADirPath + '*', faAnyFile, SR) = 0 then
      try
        repeat
          if (SR.Name = '.') or (SR.Name = '..') then
            Continue;
          if (SR.Attr and faDirectory) <> 0 then
          begin
            if SkipDir(SR.Name) then
              Continue;
            if IncDirName(SR.Name) then
              IncDirs.Add(ADirPath + SR.Name + PathDelim)
            else
              OtherDirs.Add(ADirPath + SR.Name + PathDelim);
          end
          else if ANames.Find(UpperCase(SR.Name), NameIdx) then
          begin
            AList.Add(ADirPath + SR.Name);
            if Assigned(AOnFound) then
              AOnFound(ADirPath + SR.Name);
          end;
        until FindNext(SR) <> 0;
      finally
        FindClose(SR);
      end;
      for DirIdx := 0 to IncDirs.Count - 1 do
      begin
        Walk(IncDirs[DirIdx]);
        if Cancel then
          Exit;
      end;
      for DirIdx := 0 to OtherDirs.Count - 1 do
      begin
        Walk(OtherDirs[DirIdx]);
        if Cancel then
          Exit;
      end;
    finally
      IncDirs.Free;
      OtherDirs.Free;
    end;
  end;

var
  RootIdx: Integer;
begin
  Cancel := False;
  for RootIdx := 0 to ARoots.Count - 1 do
  begin
    if DirectoryExists(ARoots[RootIdx]) then
      Walk(IncludeTrailingPathDelimiter(ARoots[RootIdx]));
    if Cancel then
      Break;
  end;
  Result := not Cancel;
end;

function IncFindOnDisk(const AName: string; ARoots, AList: TStrings;
                       AProgress: TIncProgress; ASkip: TStrings;
                       AOnFound: TIncFound): Boolean;
var
  Names: TStringList;
begin
  Names := TStringList.Create;
  try
    Names.Sorted := True;
    Names.Add(UpperCase(AName));
    Result := IncFindNamesOnDisk(Names, ARoots, AList, AProgress, ASkip,
                                 AOnFound);
  finally
    Names.Free;
  end;
end;

function IncFindDemos(const AIncFile: string; AFolders: TStrings;
                      ASub: Boolean; AList: TStrings): Integer;
var
  Files, Lines: TStringList;
  FolderIdx, FileIdx, LineIdx: Integer;
  Name, Code, Blank, Arg: string;
begin
  Result := 0;
  Name := ExtractFileName(AIncFile);
  Files := TStringList.Create;
  Lines := TStringList.Create;
  try
    Files.Sorted := True;
    Files.Duplicates := dupIgnore;
    // Сначала папка самого файла - демо обычно рядом
    FindFilesExt(ExtractFilePath(AIncFile), '.bas', False, Files, 5000);
    for FolderIdx := 0 to AFolders.Count - 1 do
      FindFilesExt(AFolders[FolderIdx], '.bas', ASub, Files, 5000);
    for FileIdx := 0 to Files.Count - 1 do
    begin
      try
        Lines.LoadFromFile(Files[FileIdx]);
      except
        Continue;
      end;
      for LineIdx := 0 to Lines.Count - 1 do
      begin
        IncSplitLine(Lines[LineIdx], Code, Blank);
        if not StartsWord(Code, '$INCLUDE') then
          Continue;
        Arg := Trim(AfterWord(Code));
        if (Arg <> '') and (Arg[1] in ['"', '<']) then
          Arg := Copy(Arg, 2, Length(Arg) - 2);
        if CompareText(ExtractFileName(Arg), Name) = 0 then
        begin
          AList.Add(Files[FileIdx]);
          Inc(Result);
          Break;
        end;
      end;
    end;
  finally
    Lines.Free;
    Files.Free;
  end;
end;

function IncMakeDemo(const AIncFile: string; var AError: string): string;
var
  Lines, Demo, ClassNames, FormClasses, Procs: TStringList;
  LineIdx, TypeDepth, ClassIdx: Integer;
  Code, Blank, Up, Kw, Name, Parent, IncName, FormName: string;
begin
  Result := '';
  AError := '';
  IncName := ExtractFileName(AIncFile);
  Result := ChangeFileExt(AIncFile, '') + '_demo.bas';
  if FileExists(Result) then
    Exit;
  Lines := TStringList.Create;
  Demo := TStringList.Create;
  ClassNames := TStringList.Create;
  FormClasses := TStringList.Create;
  Procs := TStringList.Create;
  try
    try
      Lines.LoadFromFile(AIncFile);
    except
      on E: Exception do
      begin
        AError := E.Message;
        Result := '';
        Exit;
      end;
    end;
    // Классы (TYPE X EXTENDS Y) и процедуры уровня файла
    TypeDepth := 0;
    for LineIdx := 0 to Lines.Count - 1 do
    begin
      IncSplitLine(Lines[LineIdx], Code, Blank);
      Up := UpperCase(Blank);
      Kw := FirstWord(Up);
      if Kw = 'TYPE' then
      begin
        if TypeDepth = 0 then
        begin
          Name := NameAfter(Code, 'TYPE');
          Parent := UpperCase(AfterWord(AfterWord(Code)));
          if StartsWord(Parent, 'EXTENDS') then
          begin
            Parent := NameAfter(Parent, 'EXTENDS');
            if Parent = 'QFORM' then
              FormClasses.Add(Name)
            else
              ClassNames.Add(Name);
          end;
        end;
        if not IsTypeAlias(Up) then
          Inc(TypeDepth);
      end
      else if (Kw = 'END') and (FirstWord(AfterWord(Up)) = 'TYPE') then
      begin
        if TypeDepth > 0 then
          Dec(TypeDepth);
      end
      else if (TypeDepth = 0) and ((Kw = 'SUB') or (Kw = 'FUNCTION') or
              (Kw = 'SUBI') or (Kw = 'FUNCTIONI')) then
        Procs.Add(NameAfter(Code, Kw));
    end;

    if FormClasses.Count > 0 then
      FormName := FormClasses[0]
    else
      FormName := 'QFORM';
    Demo.Add('''   Демо-программа для ' + IncName);
    Demo.Add('''   Создана INC Manager ' + FormatDateTime('yyyy-mm-dd', Now) +
             '. Подключает только этот файл: если ему нужны');
    Demo.Add('''   другие inc (RAPIDQ.INC, WIN32API.INC ...) - добавьте их ' +
             'выше.');
    if Procs.Count > 0 then
    begin
      Demo.Add('''   Процедуры и функции файла (вызовы с параметрами - ' +
               'добавьте сами):');
      for ClassIdx := 0 to Procs.Count - 1 do
        Demo.Add('''     ' + Procs[ClassIdx]);
    end;
    Demo.Add('');
    Demo.Add('$APPTYPE GUI');
    Demo.Add('$INCLUDE "' + IncName + '"');
    Demo.Add('');
    Demo.Add('CREATE DemoForm AS ' + FormName);
    Demo.Add('  Caption = "Demo: ' + IncName + '"');
    Demo.Add('  Width = 480');
    Demo.Add('  Height = 320');
    Demo.Add('  CREATE DemoLabel AS QLABEL');
    Demo.Add('    Left = 8');
    Demo.Add('    Top = 8');
    Demo.Add('    Caption = "' + IncName + ': ' +
             IntToStr(ClassNames.Count + FormClasses.Count) + ' class(es), ' +
             IntToStr(Procs.Count) + ' sub/function(s)"');
    Demo.Add('  END CREATE');
    for ClassIdx := 0 to ClassNames.Count - 1 do
    begin
      Demo.Add('  CREATE Demo' + IntToStr(ClassIdx + 1) + ' AS ' +
               ClassNames[ClassIdx]);
      Demo.Add('  END CREATE');
    end;
    Demo.Add('END CREATE');
    Demo.Add('');
    Demo.Add('DemoForm.Center');
    Demo.Add('DemoForm.ShowModal');
    try
      Demo.SaveToFile(Result);
    except
      on E: Exception do
      begin
        AError := E.Message;
        Result := '';
      end;
    end;
  finally
    Procs.Free;
    FormClasses.Free;
    ClassNames.Free;
    Demo.Free;
    Lines.Free;
  end;
end;

end.
