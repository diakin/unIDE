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
    procedure ScanDfm(SrcFile: TSrcFile);
    procedure ScanLiterals;
    function Eval(const AExpr: string; var AValue: string): Boolean;
    function EvalIdent(const AName: string; var AValue: string): Boolean;
    function OpArgs(SrcFile: TSrcFile; ALine, APos: Integer; AArgs: TStrings;
                    var AText: string): Boolean;
    function AssignedName(SrcFile: TSrcFile; ALine: Integer;
                          const AVar: string): string;
    procedure AddName(const AValue: string; AUses: TRelUses; AByOp: Boolean;
                      SrcFile: TSrcFile; ALine: Integer; const ANote: string);
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

function IsIdChar(CharVal: Char): Boolean;
begin
  Result := CharVal in ['A'..'Z', 'a'..'z', '0'..'9', '_'];
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
  Idx, Num: Integer;
  InStr: Boolean;
begin
  Result := ALine;
  if AIsDfm then
    Exit;
  Num := Length(Result);
  Idx := 1;
  InStr := False;
  while Idx <= Num do
  begin
    if AState = 1 then
    begin
      if Result[Idx] = '}' then
        AState := 0;
      Result[Idx] := ' ';
      Inc(Idx);
      Continue;
    end;
    if AState = 2 then
    begin
      if (Result[Idx] = '*') and (Idx < Num) and (Result[Idx + 1] = ')') then
      begin
        AState := 0;
        Result[Idx] := ' ';
        Inc(Idx);
      end;
      Result[Idx] := ' ';
      Inc(Idx);
      Continue;
    end;
    if InStr then
    begin
      if Result[Idx] = '''' then
        InStr := False;
      Inc(Idx);
      Continue;
    end;
    case Result[Idx] of
      '''':
        InStr := True;
      '/':
        if (Idx < Num) and (Result[Idx + 1] = '/') then
        begin
          while Idx <= Num do
          begin
            Result[Idx] := ' ';
            Inc(Idx);
          end;
          Break;
        end;
      '{':
        begin
          AState := 1;
          Result[Idx] := ' ';
        end;
      '(':
        if (Idx < Num) and (Result[Idx + 1] = '*') then
        begin
          AState := 2;
          Result[Idx] := ' ';
          Inc(Idx);
          Result[Idx] := ' ';
        end;
    end;
    Inc(Idx);
  end;
end;

// Строка похожа на имя файла или папки. ADir - папка: имя кончалось '\'
// или расширения нет вовсе. Отсекается то, что именем быть не может:
// маски, форматы чисел ('0.00'), адреса почты и сайтов, суффиксы, которые
// приклеиваются к имени ('_gr.jpg', '.ini').
function FileLikeName(const AText: string; var AName: string;
                      var ADir: Boolean): Boolean;
var
  Str, Ext: string;
  I: Integer;
  HasLetter: Boolean;
begin
  Result := False;
  Str := Trim(AText);
  while (Str <> '') and (Str[1] in ['\', '/']) do
    Delete(Str, 1, 1);
  if (Str = '') or (Length(Str) > 100) then
    Exit;
  for I := 1 to Length(Str) do
    if Str[I] in ['*', '?', '<', '>', '|', '"', ':', '@', '%', #9, #1, #2] then
      Exit;
  if (Pos('//', Str) > 0) or (Str[1] in ['.', '_', ' ']) then
    Exit;

  ADir := Str[Length(Str)] in ['\', '/'];
  if ADir then
  begin
    while (Str <> '') and (Str[Length(Str)] in ['\', '/']) do
      Delete(Str, Length(Str), 1);
    if Str = '' then
      Exit;
    AName := Str;
    Result := True;
    Exit;
  end;

  Ext := ExtractFileExt(Str);
  if Ext = '' then
  begin
    // Слово без расширения - кандидат в папки ('schemes'); фразы - нет
    for I := 1 to Length(Str) do
      if not (Str[I] in ['A'..'Z', 'a'..'z', '0'..'9', '_', '-', '\', '/']) then
        Exit;
    ADir := True;
    AName := Str;
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
  if (Length(Str) > Length(Ext)) and (Str[Length(Str) - Length(Ext)] = ' ') then
    Exit;
  AName := Str;
  Result := True;
end;

// Значение строки Паскаля с позиции AI: 'abc''d'#13#10'e'. AI - за ней.
function ReadPasString(const Str: string; var AI: Integer;
                       var AValue: string): Boolean;
var
  Num2: Integer;
  Num: string;
begin
  Result := False;
  AValue := '';
  Num2 := Length(Str);
  while AI <= Num2 do
  begin
    if Str[AI] = '''' then
    begin
      Inc(AI);
      while AI <= Num2 do
      begin
        if Str[AI] = '''' then
        begin
          if (AI < Num2) and (Str[AI + 1] = '''') then
          begin
            AValue := AValue + '''';
            Inc(AI, 2);
            Continue;
          end;
          Break;
        end;
        AValue := AValue + Str[AI];
        Inc(AI);
      end;
      if AI > Num2 then
        Exit;   // строка не закрыта
      Inc(AI);
      Result := True;
    end
    else if Str[AI] = '#' then
    begin
      Inc(AI);
      Num := '';
      while (AI <= Num2) and (Str[AI] in ['0'..'9']) do
      begin
        Num := Num + Str[AI];
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
function SplitArgs(const Str: string; var AI: Integer; AArgs: TStrings): Boolean;
var
  Depth, Num, Start: Integer;
  InStr: Boolean;
begin
  Result := False;
  AArgs.Clear;
  Num := Length(Str);
  if (AI > Num) or (Str[AI] <> '(') then
    Exit;
  Inc(AI);
  Start := AI;
  Depth := 0;
  InStr := False;
  while AI <= Num do
  begin
    if InStr then
    begin
      if Str[AI] = '''' then
        InStr := False;
    end
    else
      case Str[AI] of
        '''':
          InStr := True;
        '(', '[':
          Inc(Depth);
        ')', ']':
          if Depth = 0 then
          begin
            AArgs.Add(Trim(Copy(Str, Start, AI - Start)));
            Inc(AI);
            Result := True;
            Exit;
          end
          else
            Dec(Depth);
        ',':
          if Depth = 0 then
          begin
            AArgs.Add(Trim(Copy(Str, Start, AI - Start)));
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
  SrcFile: TSrcFile;
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
          SrcFile := TSrcFile.Create;
          SrcFile.Path := ADir + SR.Name;
          SrcFile.IsDfm := CompareText(ExtractFileExt(SR.Name), '.dfm') = 0;
          State := 0;
          for I := 0 to Raw.Count - 1 do
            SrcFile.Clean.Add(CleanLine(Raw[I], State, SrcFile.IsDfm));
          SrcFile.Upper.Text := AnsiUpperCase(SrcFile.Clean.Text);
          // AnsiUpperCase не меняет длину строки, а Text у пустого файла -
          // пустая строка: число строк сверяем
          while SrcFile.Upper.Count < SrcFile.Clean.Count do
            SrcFile.Upper.Add('');
          FFiles.Add(SrcFile);
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
  I, J, CharPos, Idx3, EndPos: Integer;
  SrcFile: TSrcFile;
  Str, UpStr, Name, Expr, CurFunc, Txt: string;
begin
  for I := 0 to FFiles.Count - 1 do
  begin
    SrcFile := TSrcFile(FFiles[I]);
    if SrcFile.IsDfm then
      Continue;
    CurFunc := '';
    for J := 0 to SrcFile.Clean.Count - 1 do
    begin
      Str := SrcFile.Clean[J];
      UpStr := SrcFile.Upper[J];

      // Заголовок функции: её Result дальше - значение самой функции
      Txt := TrimLeft(UpStr);
      if Copy(Txt, 1, 9) = 'FUNCTION ' then
      begin
        Txt := Trim(Copy(Txt, 10, MaxInt));
        CharPos := 1;
        while (CharPos <= Length(Txt)) and (IsIdChar(Txt[CharPos]) or (Txt[CharPos] = '.')) do
          Inc(CharPos);
        CurFunc := Copy(Txt, 1, CharPos - 1);
        CharPos := LastDelimiter('.', CurFunc);
        if CharPos > 0 then
          CurFunc := Copy(CurFunc, CharPos + 1, MaxInt);
      end
      else if (Copy(Txt, 1, 10) = 'PROCEDURE ') or
              (Copy(Txt, 1, 12) = 'CONSTRUCTOR ') or
              (Copy(Txt, 1, 11) = 'DESTRUCTOR ') then
        CurFunc := '';

      // GetDir(0, X) - текущая папка, при запуске это папка exe
      CharPos := Pos('GETDIR(', UpStr);
      if CharPos > 0 then
      begin
        Idx3 := Pos(',', Copy(UpStr, CharPos, MaxInt));
        EndPos := Pos(')', Copy(UpStr, CharPos, MaxInt));
        if (Idx3 > 0) and (EndPos > Idx3) then
        begin
          Name := Trim(Copy(UpStr, CharPos + Idx3, EndPos - Idx3 - 1));
          if Name <> '' then
            AddSymbol(Name, ExeDirMark, I, J);
        end;
      end;

      // X := выражение;   или   X = выражение;
      CharPos := Pos(':=', Str);
      if CharPos = 0 then
      begin
        CharPos := Pos('=', Str);
        if (CharPos = 0) or (Pos('''', Str) = 0) then
          Continue;
        Idx3 := CharPos;
        EndPos := CharPos + 1;
      end
      else
      begin
        Idx3 := CharPos;
        EndPos := CharPos + 2;
      end;
      Name := Trim(Copy(UpStr, 1, Idx3 - 1));
      // Левая часть - одно имя, можно через точку (FormB.MyDir)
      if Name = '' then
        Continue;
      CharPos := Length(Name);
      while (CharPos > 0) and (IsIdChar(Name[CharPos]) or (Name[CharPos] = '.')) do
        Dec(CharPos);
      if CharPos > 0 then
        Continue;
      CharPos := LastDelimiter('.', Name);
      if CharPos > 0 then
        Name := Copy(Name, CharPos + 1, MaxInt);
      Expr := Copy(Str, EndPos, MaxInt);
      // До точки с запятой; нет её - присваивание переносится, добираем
      // следующие строки
      Idx3 := J + 1;
      while (Pos(';', Expr) = 0) and (Idx3 < SrcFile.Clean.Count) and (Idx3 <= J + 3) do
      begin
        Expr := Expr + ' ' + SrcFile.Clean[Idx3];
        Inc(Idx3);
      end;
      if Pos(';', Expr) > 0 then
        Expr := Copy(Expr, 1, Pos(';', Expr) - 1);
      Expr := Trim(Expr);
      UpStr := AnsiUpperCase(Expr);
      if (Pos('''', Expr) > 0) or (Pos('EXENAME', UpStr) > 0) or
         (Pos('PARAMSTR(0)', StringReplace(UpStr, ' ', '', [rfReplaceAll])) > 0) or
         (Pos('GETCURRENTDIR', UpStr) > 0) then
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
  Str, Part, Id, UId, ValStr: string;
  Idx, Num, CharPos: Integer;
  Args: TStringList;

  function EvalArg(AIdx: Integer; var AV: string): Boolean;
  begin
    Result := (AIdx < Args.Count) and Eval(Args[AIdx], AV);
  end;

begin
  Result := False;
  AValue := '';
  Str := Trim(AExpr);
  Num := Length(Str);
  Idx := 1;
  Args := TStringList.Create;
  try
    while True do
    begin
      while (Idx <= Num) and (Str[Idx] = ' ') do
        Inc(Idx);
      if Idx > Num then
        Exit;
      Part := '';
      if Str[Idx] in ['''', '#'] then
      begin
        if not ReadPasString(Str, Idx, Part) then
          Exit;
      end
      else if Str[Idx] = '(' then
      begin
        if not SplitArgs(Str, Idx, Args) or (Args.Count <> 1) or
           not Eval(Args[0], Part) then
          Exit;
      end
      else if IsIdChar(Str[Idx]) then
      begin
        CharPos := Idx;
        while (Idx <= Num) and (IsIdChar(Str[Idx]) or (Str[Idx] = '.')) do
          Inc(Idx);
        Id := Copy(Str, CharPos, Idx - CharPos);
        UId := AnsiUpperCase(Id);
        while (Idx <= Num) and (Str[Idx] = ' ') do
          Inc(Idx);
        if (Idx <= Num) and (Str[Idx] = '(') then
        begin
          // Вызов функции
          if not SplitArgs(Str, Idx, Args) then
            Exit;
          CharPos := LastDelimiter('.', UId);
          if CharPos > 0 then
            UId := Copy(UId, CharPos + 1, MaxInt);
          if (UId = 'PARAMSTR') and (Args.Count = 1) and
             (Trim(Args[0]) = '0') then
            Part := ExeFileMark
          else if (UId = 'EXTRACTFILEPATH') or (UId = 'EXTRACTFILEDIR') then
          begin
            if not EvalArg(0, ValStr) then
              Exit;
            if ValStr = ExeFileMark then
              Part := ExeDirMark
            else
              Part := ExtractFilePath(ValStr);
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
            if not EvalArg(0, ValStr) or not EvalArg(1, Part) then
              Exit;
            if ValStr = ExeFileMark then
              Part := ExeDirMark + ExeFileMark + Part   // <exe без расш.>+ext
            else
              Part := ChangeFileExt(ValStr, Part);
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
          CharPos := LastDelimiter('.', Id);
          if (CharPos = 0) or not EvalIdent(Copy(Id, CharPos + 1, MaxInt), Part) then
            Exit;
        end;
      end
      else
        Exit;

      AValue := AValue + Part;
      while (Idx <= Num) and (Str[Idx] = ' ') do
        Inc(Idx);
      if Idx > Num then
      begin
        Result := True;
        Exit;
      end;
      if Str[Idx] <> '+' then
        Exit;
      Inc(Idx);
    end;
  finally
    Args.Free;
  end;
end;

// Аргументы вызова, у которого имя стоит в строке ALine до позиции APos
// (APos - на символе после имени). Вызов может переноситься - добираются
// следующие строки. AText - текст вызова для лога.
function TScanner.OpArgs(SrcFile: TSrcFile; ALine, APos: Integer; AArgs: TStrings;
                         var AText: string): Boolean;
var
  Str: string;
  K, Idx: Integer;
begin
  Str := Copy(SrcFile.Clean[ALine], APos, MaxInt);
  for K := ALine + 1 to ALine + MaxJoin do
    if K < SrcFile.Clean.Count then
      Str := Str + ' ' + SrcFile.Clean[K];
  Idx := 1;
  while (Idx <= Length(Str)) and (Str[Idx] = ' ') do
    Inc(Idx);
  Result := SplitArgs(Str, Idx, AArgs);
  AText := Trim(Copy(Str, 1, Idx - 1));
end;

// Имя файла у файловой переменной AVar: ближайший AssignFile(AVar, ...)
// выше строки ALine в том же файле. '' - не нашлось или не вычислилось.
function TScanner.AssignedName(SrcFile: TSrcFile; ALine: Integer;
                               const AVar: string): string;
var
  J, CharPos: Integer;
  Args: TStringList;
  Txt, ValStr: string;
begin
  Result := '';
  Args := TStringList.Create;
  try
    for J := ALine downto 0 do
    begin
      CharPos := Pos('ASSIGNFILE', SrcFile.Upper[J]);
      if CharPos = 0 then
        CharPos := Pos('ASSIGN(', SrcFile.Upper[J]);
      if CharPos = 0 then
        Continue;
      while (CharPos <= Length(SrcFile.Upper[J])) and (SrcFile.Upper[J][CharPos] <> '(') do
        Inc(CharPos);
      if not OpArgs(SrcFile, J, CharPos, Args, Txt) or (Args.Count < 2) or
         (AnsiUpperCase(Args[0]) <> AVar) then
        Continue;
      if Eval(Args[1], ValStr) then
        Result := ValStr
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
                           AByOp: Boolean; SrcFile: TSrcFile; ALine: Integer;
                           const ANote: string);
var
  ValStr, Name: string;
  IsDir: Boolean;
  Idx, CharPos: Integer;
  Ref: TRelRef;
begin
  ValStr := AValue;
  // <папка exe><exe>.ext - файл с именем самого exe (ChangeFileExt)
  CharPos := Pos(ExeDirMark + ExeFileMark, ValStr);
  if CharPos = 1 then
    ValStr := '<exe>' + Copy(ValStr, 3, MaxInt)
  else if (ValStr <> '') and (ValStr[1] = ExeDirMark) then
    ValStr := Copy(ValStr, 2, MaxInt)
  else if (Pos(':', ValStr) > 0) or (Copy(ValStr, 1, 2) = '\\') then
    Exit;
  if Pos(ExeDirMark, ValStr) + Pos(ExeFileMark, ValStr) > 0 then
    Exit;
  // Маска в FindFirst - имеется в виду папка
  if (Pos('*', ValStr) > 0) or (Pos('?', ValStr) > 0) then
  begin
    ValStr := ExtractFilePath(ValStr);
    if ValStr = '' then
      Exit;
  end;
  if Copy(ValStr, 1, 5) = '<exe>' then
  begin
    Name := ValStr;
    IsDir := False;
  end
  else if not FileLikeName(ValStr, Name, IsDir) then
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
  Ref.Places.Add(SrcFile.Path + #9 + IntToStr(ALine + 1) + #9 + ANote);
end;

procedure TScanner.ScanOps;
var
  I, J, K, CharPos, QuotePos, Num1: Integer;
  SrcFile: TSrcFile;
  UpStr, Txt, ValStr, Note, Arg0: string;
  Args: TStringList;
  Use: TRelUses;
  Ok: Boolean;
begin
  Args := TStringList.Create;
  try
    for I := 0 to FFiles.Count - 1 do
    begin
      SrcFile := TSrcFile(FFiles[I]);
      if SrcFile.IsDfm then
      begin
        ScanDfm(SrcFile);
        Continue;
      end;
      for J := 0 to SrcFile.Upper.Count - 1 do
      begin
        UpStr := SrcFile.Upper[J];

        // external 'x.dll'
        CharPos := Pos('EXTERNAL', UpStr);
        if (CharPos > 0) and ((CharPos = 1) or not IsIdChar(UpStr[CharPos - 1])) then
        begin
          QuotePos := CharPos + 8;
          while (QuotePos <= Length(UpStr)) and (UpStr[QuotePos] = ' ') do
            Inc(QuotePos);
          if (QuotePos <= Length(UpStr)) and (UpStr[QuotePos] = '''') and
             ReadPasString(SrcFile.Clean[J], QuotePos, ValStr) then
            AddName(ValStr, [ruRead], True, SrcFile, J, 'external');
        end;

        for K := Low(Ops) to High(Ops) do
        begin
          CharPos := Pos(Ops[K].Name, UpStr);
          while CharPos > 0 do
          begin
            QuotePos := CharPos + Length(Ops[K].Name);
            Ok := ((CharPos = 1) or not IsIdChar(UpStr[CharPos - 1])) and
                  ((QuotePos > Length(UpStr)) or not IsIdChar(UpStr[QuotePos]));
            // Метод - только через точку (SL.LoadFromFile), процедура
            // Reset / Append - только без неё (SL.Append - метод списка)
            if Ok and (Ops[K].Kind = 1) then
              Ok := (CharPos > 1) and (UpStr[CharPos - 1] = '.');
            if Ok and (Ops[K].Kind = 2) then
              Ok := (CharPos = 1) or (UpStr[CharPos - 1] <> '.');
            if Ok then
            begin
              while (QuotePos <= Length(UpStr)) and (UpStr[QuotePos] = ' ') do
                Inc(QuotePos);
              Ok := (QuotePos <= Length(UpStr)) and (UpStr[QuotePos] = '(') and
                    OpArgs(SrcFile, J, QuotePos, Args, Txt) and (Args.Count > Ops[K].Arg);
            end;
            if Ok and (Ops[K].Kind >= 0) then
            begin
              Note := Copy(SrcFile.Clean[J], CharPos, Length(Ops[K].Name)) + Txt;
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
                ValStr := AssignedName(SrcFile, J, AnsiUpperCase(Trim(Arg0)));
                Num1 := Ord((ValStr <> '') and (ValStr[1] <> #0));
              end
              else
                Num1 := Ord(Eval(Arg0, ValStr));
              if Num1 = 1 then
                AddName(ValStr, Use, True, SrcFile, J, Note)
              // Не вычислилось. В лог - только если в вызове есть строка в
              // кавычках: имя из параметра или поля ввода (FindFirst(ADir +
              // Mask)) к файлам программы не относится
              else if (FUnresolved <> nil) and (Pos('''', Note) > 0) then
                FUnresolved.Add(SrcFile.Path + #9 + IntToStr(J + 1) + #9 + Note);
            end;
            // Следующее вхождение в той же строке
            QuotePos := Pos(Ops[K].Name, Copy(UpStr, CharPos + 1, MaxInt));
            if QuotePos > 0 then
              CharPos := CharPos + QuotePos
            else
              CharPos := 0;
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
procedure TScanner.ScanDfm(SrcFile: TSrcFile);
const
  Props: array[0..2] of string = ('TABLENAME', 'FILENAME', 'DATABASENAME');
var
  J, K, CharPos, QuotePos: Integer;
  UpStr, ValStr: string;
begin
  for J := 0 to SrcFile.Upper.Count - 1 do
  begin
    UpStr := TrimLeft(SrcFile.Upper[J]);
    for K := Low(Props) to High(Props) do
      if Copy(UpStr, 1, Length(Props[K])) = Props[K] then
      begin
        CharPos := Pos('=', SrcFile.Clean[J]);
        if CharPos = 0 then
          Continue;
        QuotePos := CharPos + 1;
        while (QuotePos <= Length(SrcFile.Clean[J])) and (SrcFile.Clean[J][QuotePos] = ' ') do
          Inc(QuotePos);
        if ReadPasString(SrcFile.Clean[J], QuotePos, ValStr) then
          AddName(ValStr, [ruRead], True, SrcFile, J, Trim(SrcFile.Clean[J]));
      end;
  end;
end;

// Способ 2: строки в кавычках, похожие на имена, которых операции не дали
procedure TScanner.ScanLiterals;
var
  I, J, CharPos, Num: Integer;
  SrcFile: TSrcFile;
  Str, ValStr, Name: string;
  IsDir: Boolean;
  Idx: Integer;
begin
  for I := 0 to FFiles.Count - 1 do
  begin
    SrcFile := TSrcFile(FFiles[I]);
    for J := 0 to SrcFile.Clean.Count - 1 do
    begin
      Str := SrcFile.Clean[J];
      Num := Length(Str);
      CharPos := 1;
      while CharPos <= Num do
      begin
        if Str[CharPos] <> '''' then
        begin
          Inc(CharPos);
          Continue;
        end;
        if not ReadPasString(Str, CharPos, ValStr) then
          Break;
        if not FileLikeName(ValStr, Name, IsDir) then
          Continue;
        Idx := FItems.IndexOf(Name);
        if (Idx >= 0) and TRelRef(FItems.Objects[Idx]).ByOp then
          Continue;   // уже найдено по операции
        AddName(ValStr, [], False, SrcFile, J, 'строка в кавычках');
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
