unit ReleaseBuild;

// ---------------------------------------------------------------------------
//  Build Release: какие файлы, кроме exe, нужны программе при работе
//
//  Ответ ищется в исходниках проекта (*.pas, *.dpr, *.inc, *.dfm) двумя
//  способами.
//
//  1. От файловой операции к имени - основной. Находятся вызовы, которые
//     работают с файлами: Reset / Rewrite / Append (имя - из AssignFile той
//     же файловой переменной выше по тексту), FileExists, LoadFromFile,
//     SaveToFile, LoadLibrary, TIniFile.Create, TFileStream.Create,
//     ShellExecute, FindFirst, CopyFile ..., объявления external 'x.dll' и
//     свойства .dfm TableName / FileName. Аргумент вычисляется: строки в
//     кавычках и их склейка, Application.ExeName и ParamStr(0) (сам exe),
//     ExtractFilePath / ExtractFileDir / ChangeFileExt /
//     IncludeTrailingPathDelimiter от них, GetCurrentDir и GetDir(0, X) -
//     папка exe; имена констант и переменных, которым где-то в исходниках
//     присвоено такое выражение. Из операции же видно, читает код файл или
//     только пишет.
//  2. От строки к имени - запасной: строки в кавычках, похожие на имя
//     файла или папки, которые не привязались ни к одной операции. Что код
//     с ними делает, неизвестно.
//
//  Всё это разбор текста, а не выполнение программы: имя из поля ввода или
//  собранное в цикле так не вычислить. Поэтому итог - список с галками в
//  окне DlgRelease, а решение за пользователем. Места в исходниках, где
//  имена найдены (и операции, где имя вычислить не удалось), вызывающий
//  пишет в лог строками "Файл.pas(строка) ..." - по двойному щелчку
//  редактор открывает файл на этой строке.
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
    Uses_: TRelUses;   // что код с ним делает; пусто - неизвестно
    ByOp: Boolean;     // найдено по файловой операции (способ 1)
    IsDir: Boolean;    // папка
    // Места: строки "полный путь файла"#9"номер строки"#9"что там"
    Places: TStringList;
    constructor Create;
    destructor Destroy; override;
    // Первое место коротко: "UnitB.pas:217"
    function Where: string;
  end;

// Имена из исходников в папке ADir (вложенные папки не смотрятся). AItems -
// имя от папки exe (у папки - без хвостовой '\') и TRelRef в Objects;
// освобождает объекты вызывающий (FreeRelRefs). AUnresolved - файловые
// операции, у которых имя вычислить не удалось, строками
// "путь"#9"строка"#9"текст операции".
procedure ScanReleaseRefs(const ADir: string; AItems: TStringList;
                          AUnresolved: TStrings);
procedure FreeRelRefs(AItems: TStringList);

// Расширение из тех, что бывают у файлов данных программы (.dll, .ini,
// .cfg, .db ...)
function IsDataExt(const AExt: string): Boolean;

// Место из TRelRef.Places или AUnresolved - по частям
procedure SplitPlace(const APlace: string; var AFile: string;
                     var ALine: Integer; var ANote: string);

implementation

uses
  SysUtils;

const
  // Метка "папка exe" в вычисленном значении. #1 в именах файлов не бывает.
  ExeDirMark = #1;
  ExeFileMark = #2;
  MaxDepth = 6;        // вложенность подстановки констант и переменных
  MaxJoin = 6;         // сколько строк склеивать под аргументы операции

  // Исходники и файлы сборки - в релиз не идут никогда
  SourceExts = ',.pas,.dfm,.dpr,.dpk,.inc,.dof,.res,.rc,.dcu,.dcp,.bpl,' +
               '.lpr,.lfm,.lpi,.pp,.map,.drc,.~pas,.~dfm,.ddp,.dsk,';
  // Типичные файлы данных программы
  DataExts = ',.dll,.exe,.ini,.cfg,.dat,.db,.px,.xg0,.yg0,.mb,.val,.txt,' +
             '.csv,.xml,.json,.pdf,.chm,.hlp,.clr,.bmp,.ico,.jpg,.png,' +
             '.gif,.wav,.lng,.mnu,.fft,.htm,.html,.rtf,.ocx,.sys,';

type
  // Файловая операция: имя вызова, номер аргумента с именем, что делает.
  // Kind: 0 - обычный вызов; 1 - метод (перед именем точка: SL.LoadFromFile);
  // 2 - Reset / Rewrite / Append: аргумент - файловая переменная, имя - из
  // её AssignFile; 3 - TFileStream.Create: чтение или запись по режиму
  // (второй аргумент).
  TOpDef = record
    Name: string;
    Arg: Integer;
    Uses_: TRelUses;
    Kind: Integer;
  end;

const
  Ops: array[0..21] of TOpDef = (
    (Name: 'RESET';              Arg: 0; Uses_: [ruRead];          Kind: 2),
    (Name: 'REWRITE';            Arg: 0; Uses_: [ruWrite];         Kind: 2),
    (Name: 'APPEND';             Arg: 0; Uses_: [ruWrite];         Kind: 2),
    (Name: 'FILEEXISTS';         Arg: 0; Uses_: [ruRead];          Kind: 0),
    (Name: 'DIRECTORYEXISTS';    Arg: 0; Uses_: [ruRead];          Kind: 0),
    (Name: 'FILEOPEN';           Arg: 0; Uses_: [ruRead];          Kind: 0),
    (Name: 'LOADLIBRARY';        Arg: 0; Uses_: [ruRead];          Kind: 0),
    (Name: 'FINDFIRST';          Arg: 0; Uses_: [ruRead];          Kind: 0),
    (Name: 'SHELLEXECUTE';       Arg: 2; Uses_: [ruRead];          Kind: 0),
    (Name: 'WINEXEC';            Arg: 0; Uses_: [ruRead];          Kind: 0),
    (Name: 'LOADFROMFILE';       Arg: 0; Uses_: [ruRead];          Kind: 1),
    (Name: 'SAVETOFILE';         Arg: 0; Uses_: [ruWrite];         Kind: 1),
    (Name: 'FILECREATE';         Arg: 0; Uses_: [ruWrite];         Kind: 0),
    (Name: 'DELETEFILE';         Arg: 0; Uses_: [ruWrite];         Kind: 0),
    (Name: 'FORCEDIRECTORIES';   Arg: 0; Uses_: [ruWrite];         Kind: 0),
    (Name: 'CREATEDIR';          Arg: 0; Uses_: [ruWrite];         Kind: 0),
    (Name: 'COPYFILE';           Arg: 0; Uses_: [ruRead];          Kind: 0),
    (Name: 'COPYFILE';           Arg: 1; Uses_: [ruWrite];         Kind: 0),
    (Name: 'TINIFILE.CREATE';    Arg: 0; Uses_: [ruRead, ruWrite]; Kind: 0),
    (Name: 'TMEMINIFILE.CREATE'; Arg: 0; Uses_: [ruRead, ruWrite]; Kind: 0),
    (Name: 'TREGISTRYINIFILE.CREATE'; Arg: 0; Uses_: [];           Kind: -1),
    (Name: 'TFILESTREAM.CREATE'; Arg: 0; Uses_: [];                Kind: 3));

type
  // Один файл исходников: строки без комментариев (строки в кавычках на
  // месте, длина и номера строк как в файле) и они же прописными
  TSrcFile = class
  public
    Path: string;
    IsDfm: Boolean;
    Clean: TStringList;
    Upper: TStringList;
    constructor Create;
    destructor Destroy; override;
  end;

  // Где стоит присваивание - для выбора ближайшего
  TSymPlace = class
  public
    FileIdx: Integer;
    Line: Integer;
  end;

  TScanner = class
  private
    FFiles: TList;          // TSrcFile
    // ИМЯ=выражение, по строке на присваивание; Objects - TSymPlace
    FSymbols: TStringList;
    FItems: TStringList;
    FUnresolved: TStrings;
    FDepth: Integer;
    // Откуда вычисляется выражение: из присваиваний одного имени берётся
    // ближайшее выше в том же файле - у Dir, S, FN их по всей программе
    // десятки
    FCtxFile: Integer;
    FCtxLine: Integer;
    procedure AddSymbol(const AName, AExpr: string; AFile, ALine: Integer);
    procedure LoadFiles(const ADir: string);
    procedure CollectSymbols;
    procedure ScanOps;
    procedure ScanDfm(F: TSrcFile);
    procedure ScanLiterals;
    function Eval(const AExpr: string; var AValue: string): Boolean;
    function EvalIdent(const AName: string; var AValue: string): Boolean;
    function OpArgs(F: TSrcFile; ALine, APos: Integer; AArgs: TStrings;
                    var AText: string): Boolean;
    function AssignedName(F: TSrcFile; ALine: Integer;
                          const AVar: string): string;
    procedure AddName(const AValue: string; AUses: TRelUses; AByOp: Boolean;
                      F: TSrcFile; ALine: Integer; const ANote: string);
  public
    constructor Create(AItems: TStringList; AUnresolved: TStrings);
    destructor Destroy; override;
    procedure Run(const ADir: string);
  end;

{ TRelRef }

constructor TRelRef.Create;
begin
  inherited Create;
  Places := TStringList.Create;
end;

destructor TRelRef.Destroy;
begin
  Places.Free;
  inherited;
end;

function TRelRef.Where: string;
var
  Fn, Note: string;
  Ln: Integer;
begin
  Result := '';
  if Places.Count = 0 then
    Exit;
  SplitPlace(Places[0], Fn, Ln, Note);
  Result := ExtractFileName(Fn) + ':' + IntToStr(Ln);
end;

procedure SplitPlace(const APlace: string; var AFile: string;
                     var ALine: Integer; var ANote: string);
var
  P1, P2: Integer;
  Rest: string;
begin
  P1 := Pos(#9, APlace);
  AFile := Copy(APlace, 1, P1 - 1);
  Rest := Copy(APlace, P1 + 1, MaxInt);
  P2 := Pos(#9, Rest);
  ALine := StrToIntDef(Copy(Rest, 1, P2 - 1), 0);
  ANote := Copy(Rest, P2 + 1, MaxInt);
end;

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

function IsIdChar(C: Char): Boolean;
begin
  Result := C in ['A'..'Z', 'a'..'z', '0'..'9', '_'];
end;

{ TSrcFile }

constructor TSrcFile.Create;
begin
  inherited Create;
  Clean := TStringList.Create;
  Upper := TStringList.Create;
end;

destructor TSrcFile.Destroy;
begin
  Upper.Free;
  Clean.Free;
  inherited;
end;

// Строка без комментариев: // до конца строки, { } и (* *) - пробелами,
// строки в кавычках остаются. AState - незакрытый многострочный
// комментарий: 0 - нет, 1 - { }, 2 - (* *).
function CleanLine(const ALine: string; var AState: Integer;
                   AIsDfm: Boolean): string;
var
  I, N: Integer;
  InStr: Boolean;
begin
  Result := ALine;
  if AIsDfm then
    Exit;
  N := Length(Result);
  I := 1;
  InStr := False;
  while I <= N do
  begin
    if AState = 1 then
    begin
      if Result[I] = '}' then
        AState := 0;
      Result[I] := ' ';
      Inc(I);
      Continue;
    end;
    if AState = 2 then
    begin
      if (Result[I] = '*') and (I < N) and (Result[I + 1] = ')') then
      begin
        AState := 0;
        Result[I] := ' ';
        Inc(I);
      end;
      Result[I] := ' ';
      Inc(I);
      Continue;
    end;
    if InStr then
    begin
      if Result[I] = '''' then
        InStr := False;
      Inc(I);
      Continue;
    end;
    case Result[I] of
      '''':
        InStr := True;
      '/':
        if (I < N) and (Result[I + 1] = '/') then
        begin
          while I <= N do
          begin
            Result[I] := ' ';
            Inc(I);
          end;
          Break;
        end;
      '{':
        begin
          AState := 1;
          Result[I] := ' ';
        end;
      '(':
        if (I < N) and (Result[I + 1] = '*') then
        begin
          AState := 2;
          Result[I] := ' ';
          Inc(I);
          Result[I] := ' ';
        end;
    end;
    Inc(I);
  end;
end;

// Строка похожа на имя файла или папки. ADir - папка: имя кончалось '\'
// или расширения нет вовсе. Отсекается то, что именем быть не может:
// маски, форматы чисел ('0.00'), адреса почты и сайтов, суффиксы, которые
// приклеиваются к имени ('_gr.jpg', '.ini').
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
    if S[I] in ['*', '?', '<', '>', '|', '"', ':', '@', '%', #9, #1, #2] then
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
    // Слово без расширения - кандидат в папки ('schemes'); фразы - нет
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
  if (Length(S) > Length(Ext)) and (S[Length(S) - Length(Ext)] = ' ') then
    Exit;
  AName := S;
  Result := True;
end;

// Значение строки Паскаля с позиции AI: 'abc''d'#13#10'e'. AI - за ней.
function ReadPasString(const S: string; var AI: Integer;
                       var AValue: string): Boolean;
var
  N: Integer;
  Num: string;
begin
  Result := False;
  AValue := '';
  N := Length(S);
  while AI <= N do
  begin
    if S[AI] = '''' then
    begin
      Inc(AI);
      while AI <= N do
      begin
        if S[AI] = '''' then
        begin
          if (AI < N) and (S[AI + 1] = '''') then
          begin
            AValue := AValue + '''';
            Inc(AI, 2);
            Continue;
          end;
          Break;
        end;
        AValue := AValue + S[AI];
        Inc(AI);
      end;
      if AI > N then
        Exit;   // строка не закрыта
      Inc(AI);
      Result := True;
    end
    else if S[AI] = '#' then
    begin
      Inc(AI);
      Num := '';
      while (AI <= N) and (S[AI] in ['0'..'9']) do
      begin
        Num := Num + S[AI];
        Inc(AI);
      end;
      if Num = '' then
        Exit;
      AValue := AValue + Chr(StrToIntDef(Num, 32) and $FF);
      Result := True;
    end
    else
      Break;
  end;
end;

// Аргументы вызова с открывающей скобки AI: на верхнем уровне, по
// запятым. AI - за закрывающей скобкой.
function SplitArgs(const S: string; var AI: Integer; AArgs: TStrings): Boolean;
var
  Depth, N, Start: Integer;
  InStr: Boolean;
begin
  Result := False;
  AArgs.Clear;
  N := Length(S);
  if (AI > N) or (S[AI] <> '(') then
    Exit;
  Inc(AI);
  Start := AI;
  Depth := 0;
  InStr := False;
  while AI <= N do
  begin
    if InStr then
    begin
      if S[AI] = '''' then
        InStr := False;
    end
    else
      case S[AI] of
        '''':
          InStr := True;
        '(', '[':
          Inc(Depth);
        ')', ']':
          if Depth = 0 then
          begin
            AArgs.Add(Trim(Copy(S, Start, AI - Start)));
            Inc(AI);
            Result := True;
            Exit;
          end
          else
            Dec(Depth);
        ',':
          if Depth = 0 then
          begin
            AArgs.Add(Trim(Copy(S, Start, AI - Start)));
            Start := AI + 1;
          end;
      end;
    Inc(AI);
  end;
end;

{ TScanner }

constructor TScanner.Create(AItems: TStringList; AUnresolved: TStrings);
begin
  inherited Create;
  FFiles := TList.Create;
  FSymbols := TStringList.Create;
  FItems := AItems;
  FUnresolved := AUnresolved;
end;

destructor TScanner.Destroy;
var
  I: Integer;
begin
  for I := 0 to FFiles.Count - 1 do
    TObject(FFiles[I]).Free;
  FFiles.Free;
  for I := 0 to FSymbols.Count - 1 do
    FSymbols.Objects[I].Free;
  FSymbols.Free;
  inherited;
end;

procedure TScanner.LoadFiles(const ADir: string);
const
  Masks: array[0..3] of string = ('*.pas', '*.dpr', '*.inc', '*.dfm');
var
  M, I, State: Integer;
  SR: TSearchRec;
  F: TSrcFile;
  Raw: TStringList;
begin
  Raw := TStringList.Create;
  try
    for M := Low(Masks) to High(Masks) do
      if FindFirst(ADir + Masks[M], faAnyFile and not faDirectory, SR) = 0 then
      try
        repeat
          // Маска по коротким именам находит и x.pas~ - сверяем ещё раз
          if CompareText(ExtractFileExt(SR.Name),
                         ExtractFileExt(Masks[M])) <> 0 then
            Continue;
          try
            Raw.LoadFromFile(ADir + SR.Name);
          except
            Continue;   // файл занят - без него
          end;
          F := TSrcFile.Create;
          F.Path := ADir + SR.Name;
          F.IsDfm := CompareText(ExtractFileExt(SR.Name), '.dfm') = 0;
          State := 0;
          for I := 0 to Raw.Count - 1 do
            F.Clean.Add(CleanLine(Raw[I], State, F.IsDfm));
          F.Upper.Text := AnsiUpperCase(F.Clean.Text);
          // AnsiUpperCase не меняет длину строки, а Text у пустого файла -
          // пустая строка: число строк сверяем
          while F.Upper.Count < F.Clean.Count do
            F.Upper.Add('');
          FFiles.Add(F);
        until FindNext(SR) <> 0;
      finally
        FindClose(SR);
      end;
  finally
    Raw.Free;
  end;
end;

procedure TScanner.AddSymbol(const AName, AExpr: string; AFile,
                             ALine: Integer);
var
  Pl: TSymPlace;
begin
  Pl := TSymPlace.Create;
  Pl.FileIdx := AFile;
  Pl.Line := ALine;
  FSymbols.AddObject(AName + '=' + AExpr, Pl);
end;

// Присваивания и константы, из которых может сложиться имя файла:
//   X := <выражение>;     const X = <выражение>;     GetDir(0, X);
//   Result := <выражение> в функции - под именем функции
//   (SettingsFileName: Result := ExtractFilePath(...) + 'editor.ini').
// Берутся только выражения со строкой в кавычках или с тем, что даёт
// папку exe, - остальное к именам файлов отношения не имеет.
procedure TScanner.CollectSymbols;
var
  I, J, P, K, E: Integer;
  F: TSrcFile;
  S, U, Name, Expr, CurFunc, T: string;
begin
  for I := 0 to FFiles.Count - 1 do
  begin
    F := TSrcFile(FFiles[I]);
    if F.IsDfm then
      Continue;
    CurFunc := '';
    for J := 0 to F.Clean.Count - 1 do
    begin
      S := F.Clean[J];
      U := F.Upper[J];

      // Заголовок функции: её Result дальше - значение самой функции
      T := TrimLeft(U);
      if Copy(T, 1, 9) = 'FUNCTION ' then
      begin
        T := Trim(Copy(T, 10, MaxInt));
        P := 1;
        while (P <= Length(T)) and (IsIdChar(T[P]) or (T[P] = '.')) do
          Inc(P);
        CurFunc := Copy(T, 1, P - 1);
        P := LastDelimiter('.', CurFunc);
        if P > 0 then
          CurFunc := Copy(CurFunc, P + 1, MaxInt);
      end
      else if (Copy(T, 1, 10) = 'PROCEDURE ') or
              (Copy(T, 1, 12) = 'CONSTRUCTOR ') or
              (Copy(T, 1, 11) = 'DESTRUCTOR ') then
        CurFunc := '';

      // GetDir(0, X) - текущая папка, при запуске это папка exe
      P := Pos('GETDIR(', U);
      if P > 0 then
      begin
        K := Pos(',', Copy(U, P, MaxInt));
        E := Pos(')', Copy(U, P, MaxInt));
        if (K > 0) and (E > K) then
        begin
          Name := Trim(Copy(U, P + K, E - K - 1));
          if Name <> '' then
            AddSymbol(Name, ExeDirMark, I, J);
        end;
      end;

      // X := выражение;   или   X = выражение;
      P := Pos(':=', S);
      if P = 0 then
      begin
        P := Pos('=', S);
        if (P = 0) or (Pos('''', S) = 0) then
          Continue;
        K := P;
        E := P + 1;
      end
      else
      begin
        K := P;
        E := P + 2;
      end;
      Name := Trim(Copy(U, 1, K - 1));
      // Левая часть - одно имя, можно через точку (FormB.MyDir)
      if Name = '' then
        Continue;
      P := Length(Name);
      while (P > 0) and (IsIdChar(Name[P]) or (Name[P] = '.')) do
        Dec(P);
      if P > 0 then
        Continue;
      P := LastDelimiter('.', Name);
      if P > 0 then
        Name := Copy(Name, P + 1, MaxInt);
      Expr := Copy(S, E, MaxInt);
      // До точки с запятой; нет её - присваивание переносится, добираем
      // следующие строки
      K := J + 1;
      while (Pos(';', Expr) = 0) and (K < F.Clean.Count) and (K <= J + 3) do
      begin
        Expr := Expr + ' ' + F.Clean[K];
        Inc(K);
      end;
      if Pos(';', Expr) > 0 then
        Expr := Copy(Expr, 1, Pos(';', Expr) - 1);
      Expr := Trim(Expr);
      U := AnsiUpperCase(Expr);
      if (Pos('''', Expr) > 0) or (Pos('EXENAME', U) > 0) or
         (Pos('PARAMSTR(0)', StringReplace(U, ' ', '', [rfReplaceAll])) > 0) or
         (Pos('GETCURRENTDIR', U) > 0) then
      begin
        if (Name = 'RESULT') and (CurFunc <> '') then
          AddSymbol(CurFunc, Expr, I, J)
        else
          AddSymbol(Name, Expr, I, J);
      end;
    end;
  end;
end;

// Значение имени константы, переменной или функции. Порядок присваиваний:
// сначала ближайшее выше в том же файле, потом остальные в этом файле,
// потом в других. Берётся первое, которое удалось вычислить.
function TScanner.EvalIdent(const AName: string; var AValue: string): Boolean;
var
  I, Pass, Best, BestLine: Integer;
  Key: string;
  Pl: TSymPlace;
  Tried: TList;
  SaveFile, SaveLine: Integer;

  function Try_(AIdx: Integer): Boolean;
  begin
    Result := False;
    Tried.Add(Pointer(AIdx));
    if FSymbols.ValueFromIndex[AIdx] = ExeDirMark then
    begin
      AValue := ExeDirMark;
      Result := True;
      Exit;
    end;
    Pl := TSymPlace(FSymbols.Objects[AIdx]);
    FCtxFile := Pl.FileIdx;
    FCtxLine := Pl.Line;
    Result := Eval(FSymbols.ValueFromIndex[AIdx], AValue);
    FCtxFile := SaveFile;
    FCtxLine := SaveLine;
  end;

begin
  Result := False;
  if FDepth >= MaxDepth then
    Exit;
  Key := AnsiUpperCase(AName);
  SaveFile := FCtxFile;
  SaveLine := FCtxLine;
  Tried := TList.Create;
  Inc(FDepth);
  try
    // Ближайшее выше в том же файле
    Best := -1;
    BestLine := -1;
    for I := 0 to FSymbols.Count - 1 do
      if FSymbols.Names[I] = Key then
      begin
        Pl := TSymPlace(FSymbols.Objects[I]);
        if (Pl.FileIdx = SaveFile) and (Pl.Line <= SaveLine) and
           (Pl.Line > BestLine) then
        begin
          Best := I;
          BestLine := Pl.Line;
        end;
      end;
    if (Best >= 0) and Try_(Best) then
    begin
      Result := True;
      Exit;
    end;
    // Остальные: сначала этот файл, потом другие
    for Pass := 1 to 2 do
      for I := 0 to FSymbols.Count - 1 do
        if (FSymbols.Names[I] = Key) and (Tried.IndexOf(Pointer(I)) < 0) then
        begin
          Pl := TSymPlace(FSymbols.Objects[I]);
          if (Pl.FileIdx = SaveFile) <> (Pass = 1) then
            Continue;
          if Try_(I) then
          begin
            Result := True;
            Exit;
          end;
        end;
  finally
    Dec(FDepth);
    Tried.Free;
    FCtxFile := SaveFile;
    FCtxLine := SaveLine;
  end;
end;

// Выражение из строк, склеек '+', имён и функций пути. Метки: ExeDirMark -
// папка exe, ExeFileMark - полное имя exe. False - в выражении есть то,
// что по тексту не вычислить.
function TScanner.Eval(const AExpr: string; var AValue: string): Boolean;
var
  S, Part, Id, UId, V: string;
  I, N, P: Integer;
  Args: TStringList;

  function EvalArg(AIdx: Integer; var AV: string): Boolean;
  begin
    Result := (AIdx < Args.Count) and Eval(Args[AIdx], AV);
  end;

begin
  Result := False;
  AValue := '';
  S := Trim(AExpr);
  N := Length(S);
  I := 1;
  Args := TStringList.Create;
  try
    while True do
    begin
      while (I <= N) and (S[I] = ' ') do
        Inc(I);
      if I > N then
        Exit;
      Part := '';
      if S[I] in ['''', '#'] then
      begin
        if not ReadPasString(S, I, Part) then
          Exit;
      end
      else if S[I] = '(' then
      begin
        if not SplitArgs(S, I, Args) or (Args.Count <> 1) or
           not Eval(Args[0], Part) then
          Exit;
      end
      else if IsIdChar(S[I]) then
      begin
        P := I;
        while (I <= N) and (IsIdChar(S[I]) or (S[I] = '.')) do
          Inc(I);
        Id := Copy(S, P, I - P);
        UId := AnsiUpperCase(Id);
        while (I <= N) and (S[I] = ' ') do
          Inc(I);
        if (I <= N) and (S[I] = '(') then
        begin
          // Вызов функции
          if not SplitArgs(S, I, Args) then
            Exit;
          P := LastDelimiter('.', UId);
          if P > 0 then
            UId := Copy(UId, P + 1, MaxInt);
          if (UId = 'PARAMSTR') and (Args.Count = 1) and
             (Trim(Args[0]) = '0') then
            Part := ExeFileMark
          else if (UId = 'EXTRACTFILEPATH') or (UId = 'EXTRACTFILEDIR') then
          begin
            if not EvalArg(0, V) then
              Exit;
            if V = ExeFileMark then
              Part := ExeDirMark
            else
              Part := ExtractFilePath(V);
          end
          else if (UId = 'INCLUDETRAILINGPATHDELIMITER') or
                  (UId = 'INCLUDETRAILINGBACKSLASH') or
                  (UId = 'EXCLUDETRAILINGPATHDELIMITER') or
                  (UId = 'EXCLUDETRAILINGBACKSLASH') or
                  (UId = 'TRIM') or (UId = 'LOWERCASE') or
                  (UId = 'ANSILOWERCASE') or (UId = 'UPPERCASE') or
                  (UId = 'ANSIUPPERCASE') or (UId = 'EXPANDFILENAME') or
                  (UId = 'PCHAR') or (UId = 'PANSICHAR') or
                  (UId = 'STRING') or (UId = 'ANSISTRING') then
          begin
            if not EvalArg(0, Part) then
              Exit;
          end
          else if UId = 'CHANGEFILEEXT' then
          begin
            if not EvalArg(0, V) or not EvalArg(1, Part) then
              Exit;
            if V = ExeFileMark then
              Part := ExeDirMark + ExeFileMark + Part   // <exe без расш.>+ext
            else
              Part := ChangeFileExt(V, Part);
          end
          else if (UId = 'GETCURRENTDIR') or (UId = 'GETCURRENTDIRECTORY') then
            Part := ExeDirMark
          // Своя функция без аргументов - по её Result (SettingsFileName())
          else if ((Args.Count = 0) or
                   ((Args.Count = 1) and (Trim(Args[0]) = ''))) and
                  EvalIdent(UId, Part) then
            // значение - в Part
          else
            Exit;   // своя функция с аргументами - по тексту не вычислить
        end
        else if (UId = 'APPLICATION.EXENAME') then
          Part := ExeFileMark
        else if UId = 'GETCURRENTDIR' then
          Part := ExeDirMark
        else if not EvalIdent(Id, Part) then
        begin
          // Имя через точку (FormB.MyDir) - по последней части
          P := LastDelimiter('.', Id);
          if (P = 0) or not EvalIdent(Copy(Id, P + 1, MaxInt), Part) then
            Exit;
        end;
      end
      else
        Exit;

      AValue := AValue + Part;
      while (I <= N) and (S[I] = ' ') do
        Inc(I);
      if I > N then
      begin
        Result := True;
        Exit;
      end;
      if S[I] <> '+' then
        Exit;
      Inc(I);
    end;
  finally
    Args.Free;
  end;
end;

// Аргументы вызова, у которого имя стоит в строке ALine до позиции APos
// (APos - на символе после имени). Вызов может переноситься - добираются
// следующие строки. AText - текст вызова для лога.
function TScanner.OpArgs(F: TSrcFile; ALine, APos: Integer; AArgs: TStrings;
                         var AText: string): Boolean;
var
  S: string;
  K, I: Integer;
begin
  S := Copy(F.Clean[ALine], APos, MaxInt);
  for K := ALine + 1 to ALine + MaxJoin do
    if K < F.Clean.Count then
      S := S + ' ' + F.Clean[K];
  I := 1;
  while (I <= Length(S)) and (S[I] = ' ') do
    Inc(I);
  Result := SplitArgs(S, I, AArgs);
  AText := Trim(Copy(S, 1, I - 1));
end;

// Имя файла у файловой переменной AVar: ближайший AssignFile(AVar, ...)
// выше строки ALine в том же файле. '' - не нашлось или не вычислилось.
function TScanner.AssignedName(F: TSrcFile; ALine: Integer;
                               const AVar: string): string;
var
  J, P: Integer;
  Args: TStringList;
  Txt, V: string;
begin
  Result := '';
  Args := TStringList.Create;
  try
    for J := ALine downto 0 do
    begin
      P := Pos('ASSIGNFILE', F.Upper[J]);
      if P = 0 then
        P := Pos('ASSIGN(', F.Upper[J]);
      if P = 0 then
        Continue;
      while (P <= Length(F.Upper[J])) and (F.Upper[J][P] <> '(') do
        Inc(P);
      if not OpArgs(F, J, P, Args, Txt) or (Args.Count < 2) or
         (AnsiUpperCase(Args[0]) <> AVar) then
        Continue;
      if Eval(Args[1], V) then
        Result := V
      else
        Result := #0 + Args[1];   // есть AssignFile, но имя не вычислить
      Exit;
    end;
  finally
    Args.Free;
  end;
end;

// Вычисленное значение - в список имён от папки exe. Абсолютный путь
// (C:\...) - не файл программы, пропускается.
procedure TScanner.AddName(const AValue: string; AUses: TRelUses;
                           AByOp: Boolean; F: TSrcFile; ALine: Integer;
                           const ANote: string);
var
  V, Name: string;
  IsDir: Boolean;
  Idx, P: Integer;
  Ref: TRelRef;
begin
  V := AValue;
  // <папка exe><exe>.ext - файл с именем самого exe (ChangeFileExt)
  P := Pos(ExeDirMark + ExeFileMark, V);
  if P = 1 then
    V := '<exe>' + Copy(V, 3, MaxInt)
  else if (V <> '') and (V[1] = ExeDirMark) then
    V := Copy(V, 2, MaxInt)
  else if (Pos(':', V) > 0) or (Copy(V, 1, 2) = '\\') then
    Exit;
  if Pos(ExeDirMark, V) + Pos(ExeFileMark, V) > 0 then
    Exit;
  // Маска в FindFirst - имеется в виду папка
  if (Pos('*', V) > 0) or (Pos('?', V) > 0) then
  begin
    V := ExtractFilePath(V);
    if V = '' then
      Exit;
  end;
  if Copy(V, 1, 5) = '<exe>' then
  begin
    Name := V;
    IsDir := False;
  end
  else if not FileLikeName(V, Name, IsDir) then
    Exit;

  Idx := FItems.IndexOf(Name);
  if Idx < 0 then
  begin
    Ref := TRelRef.Create;
    Ref.IsDir := IsDir;
    Idx := FItems.AddObject(Name, Ref);
  end;
  Ref := TRelRef(FItems.Objects[Idx]);
  Ref.Uses_ := Ref.Uses_ + AUses;
  if AByOp then
    Ref.ByOp := True;
  Ref.Places.Add(F.Path + #9 + IntToStr(ALine + 1) + #9 + ANote);
end;

procedure TScanner.ScanOps;
var
  I, J, K, P, Q, A: Integer;
  F: TSrcFile;
  U, Txt, V, Note, Arg0: string;
  Args: TStringList;
  Use: TRelUses;
  Ok: Boolean;
begin
  Args := TStringList.Create;
  try
    for I := 0 to FFiles.Count - 1 do
    begin
      F := TSrcFile(FFiles[I]);
      if F.IsDfm then
      begin
        ScanDfm(F);
        Continue;
      end;
      for J := 0 to F.Upper.Count - 1 do
      begin
        U := F.Upper[J];

        // external 'x.dll'
        P := Pos('EXTERNAL', U);
        if (P > 0) and ((P = 1) or not IsIdChar(U[P - 1])) then
        begin
          Q := P + 8;
          while (Q <= Length(U)) and (U[Q] = ' ') do
            Inc(Q);
          if (Q <= Length(U)) and (U[Q] = '''') and
             ReadPasString(F.Clean[J], Q, V) then
            AddName(V, [ruRead], True, F, J, 'external');
        end;

        for K := Low(Ops) to High(Ops) do
        begin
          P := Pos(Ops[K].Name, U);
          while P > 0 do
          begin
            Q := P + Length(Ops[K].Name);
            Ok := ((P = 1) or not IsIdChar(U[P - 1])) and
                  ((Q > Length(U)) or not IsIdChar(U[Q]));
            // Метод - только через точку (SL.LoadFromFile), процедура
            // Reset / Append - только без неё (SL.Append - метод списка)
            if Ok and (Ops[K].Kind = 1) then
              Ok := (P > 1) and (U[P - 1] = '.');
            if Ok and (Ops[K].Kind = 2) then
              Ok := (P = 1) or (U[P - 1] <> '.');
            if Ok then
            begin
              while (Q <= Length(U)) and (U[Q] = ' ') do
                Inc(Q);
              Ok := (Q <= Length(U)) and (U[Q] = '(') and
                    OpArgs(F, J, Q, Args, Txt) and (Args.Count > Ops[K].Arg);
            end;
            if Ok and (Ops[K].Kind >= 0) then
            begin
              Note := Copy(F.Clean[J], P, Length(Ops[K].Name)) + Txt;
              if Length(Note) > 80 then
                Note := Copy(Note, 1, 77) + '...';
              Use := Ops[K].Uses_;
              Arg0 := Args[Ops[K].Arg];
              if Ops[K].Kind = 3 then
              begin
                // TFileStream.Create(имя, режим)
                if (Args.Count > 1) and
                   (Pos('FMCREATE', AnsiUpperCase(Args[1])) > 0) then
                  Use := [ruWrite]
                else
                  Use := [ruRead];
              end;
              FCtxFile := I;
              FCtxLine := J;
              if Ops[K].Kind = 2 then
              begin
                V := AssignedName(F, J, AnsiUpperCase(Trim(Arg0)));
                A := Ord((V <> '') and (V[1] <> #0));
              end
              else
                A := Ord(Eval(Arg0, V));
              if A = 1 then
                AddName(V, Use, True, F, J, Note)
              // Не вычислилось. В лог - только если в вызове есть строка в
              // кавычках: имя из параметра или поля ввода (FindFirst(ADir +
              // Mask)) к файлам программы не относится
              else if (FUnresolved <> nil) and (Pos('''', Note) > 0) then
                FUnresolved.Add(F.Path + #9 + IntToStr(J + 1) + #9 + Note);
            end;
            // Следующее вхождение в той же строке
            Q := Pos(Ops[K].Name, Copy(U, P + 1, MaxInt));
            if Q > 0 then
              P := P + Q
            else
              P := 0;
          end;
        end;
      end;
    end;
  finally
    Args.Free;
  end;
end;

// .dfm: имя файла в свойстве компонента - TableName, FileName,
// DatabaseName - его читают
procedure TScanner.ScanDfm(F: TSrcFile);
const
  Props: array[0..2] of string = ('TABLENAME', 'FILENAME', 'DATABASENAME');
var
  J, K, P, Q: Integer;
  U, V: string;
begin
  for J := 0 to F.Upper.Count - 1 do
  begin
    U := TrimLeft(F.Upper[J]);
    for K := Low(Props) to High(Props) do
      if Copy(U, 1, Length(Props[K])) = Props[K] then
      begin
        P := Pos('=', F.Clean[J]);
        if P = 0 then
          Continue;
        Q := P + 1;
        while (Q <= Length(F.Clean[J])) and (F.Clean[J][Q] = ' ') do
          Inc(Q);
        if ReadPasString(F.Clean[J], Q, V) then
          AddName(V, [ruRead], True, F, J, Trim(F.Clean[J]));
      end;
  end;
end;

// Способ 2: строки в кавычках, похожие на имена, которых операции не дали
procedure TScanner.ScanLiterals;
var
  I, J, P, N: Integer;
  F: TSrcFile;
  S, V, Name: string;
  IsDir: Boolean;
  Idx: Integer;
begin
  for I := 0 to FFiles.Count - 1 do
  begin
    F := TSrcFile(FFiles[I]);
    for J := 0 to F.Clean.Count - 1 do
    begin
      S := F.Clean[J];
      N := Length(S);
      P := 1;
      while P <= N do
      begin
        if S[P] <> '''' then
        begin
          Inc(P);
          Continue;
        end;
        if not ReadPasString(S, P, V) then
          Break;
        if not FileLikeName(V, Name, IsDir) then
          Continue;
        Idx := FItems.IndexOf(Name);
        if (Idx >= 0) and TRelRef(FItems.Objects[Idx]).ByOp then
          Continue;   // уже найдено по операции
        AddName(V, [], False, F, J, 'строка в кавычках');
      end;
    end;
  end;
end;

procedure TScanner.Run(const ADir: string);
begin
  FItems.Sorted := True;
  FItems.CaseSensitive := False;
  FItems.Duplicates := dupIgnore;
  LoadFiles(IncludeTrailingPathDelimiter(ADir));
  CollectSymbols;
  ScanOps;
  ScanLiterals;
end;

procedure ScanReleaseRefs(const ADir: string; AItems: TStringList;
                          AUnresolved: TStrings);
var
  Sc: TScanner;
begin
  Sc := TScanner.Create(AItems, AUnresolved);
  try
    Sc.Run(ADir);
  finally
    Sc.Free;
  end;
end;

end.
