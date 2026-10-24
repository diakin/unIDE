unit FarFind;

// ---------------------------------------------------------------------------
//  Поиск файлов для unIDE FAR (Alt+F7, как Find file в FAR Manager):
//  обход папок в своём потоке, маски имён, поиск текста внутри файлов.
//
//  - маски - через ',' или ';' (*.pas;*.dfm), * и ?, без учёта регистра;
//    '*.*' - любое имя, и без точки (так в FAR); маска без * и ? - имя
//    целиком;
//  - текст: ищется в байтах файла сразу в нескольких кодировках (Windows
//    cp1251, DOS cp866, UTF-8, UTF-16LE) - «All code pages» FAR - или в
//    одной. Без учёта регистра у каждого символа два варианта (строчный и
//    прописной), сравнение - по байтам. Whole words - по краям совпадения
//    не буква, не цифра и не '_';
//  - файл читается кусками по 1 МБ с перекрытием (совпадение на стыке не
//    теряется); первое совпадение - файл найден, дальше не читается;
//  - папки-ссылки (reparse point: junction, symlink) не обходятся - нет
//    петель;
//  - поток кладёт найденное в очередь; окно забирает (TakeFound) по
//    таймеру; Cancel - остановить.
// ---------------------------------------------------------------------------

{$Q-}
{$R-}

interface

uses
  Windows, SysUtils, Classes;

type
  TFarFindItem = record
    Dir: WideString;        // папка (с '\' в конце)
    Name: WideString;
    IsDir: Boolean;
    Size: Int64;
    Time: TFileTime;        // время записи (UTC)
    Attr: DWORD;
  end;
  TFarFindItems = array of TFarFindItem;

  TFarFindMasks = array of WideString;

  // Кодировки поиска текста
  TFarFindCodePage = (fcpAll, fcpAnsi, fcpOem, fcpUtf8, fcpUtf16);

  TFarFindOptions = record
    Root: WideString;       // откуда (с '\' в конце)
    Masks: WideString;      // '*.*' / '*.pas;*.dfm'
    Text: WideString;       // '' - без поиска текста
    CodePage: TFarFindCodePage;
    CaseSensitive: Boolean;
    WholeWords: Boolean;
    Folders: Boolean;       // папки тоже (если текст не ищется)
    Recursive: Boolean;     // и в подпапках
  end;

  // Образец текста в одной кодировке: на каждый символ - варианты байтов
  TFarPatternUnit = record
    Alt1, Alt2: string;     // Alt2 = '' - вариант один
  end;
  TFarPattern = record
    Units: array of TFarPatternUnit;
    CodePage: UINT;         // 1251, 866, 65001, 1200 (UTF-16LE)
    FirstByte: array[0..255] of Boolean;
    WordByte: array[0..255] of Boolean;  // однобайтовые: буква / цифра / _
    MaxLen: Integer;        // наибольшая длина совпадения в байтах
  end;
  TFarPatterns = array of TFarPattern;

  TFarFindThread = class(TThread)
  private
    FOptions: TFarFindOptions;
    FMasks: TFarFindMasks;
    FPatterns: TFarPatterns;
    FLock: TRTLCriticalSection;
    FFound: TFarFindItems;       // ещё не забранное окном
    FFoundCount: Integer;
    FCurrentDir: WideString;
    FFileCount: Integer;
    FDirCount: Integer;
    FCancelled: Boolean;
    FFinished: Integer;
    procedure AddFound(const AItem: TFarFindItem);
    procedure ScanDir(const ADir: WideString);
    function FileHasText(const AFileName: WideString): Boolean;
    function GetFinished: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(const AOptions: TFarFindOptions);
    destructor Destroy; override;
    procedure Cancel;
    // Найденное с прошлого раза - в конец AItems; результат - сколько
    function TakeFound(var AItems: TFarFindItems): Integer;
    function CurrentDir: WideString;
    property FileCount: Integer read FFileCount;
    property DirCount: Integer read FDirCount;
    property Finished: Boolean read GetFinished;
    property Cancelled: Boolean read FCancelled;
  end;

// Маски из строки ('*.pas;*.dfm', '*.*'); пусто - '*'
procedure FarSplitMasks(const AText: WideString; var AMasks: TFarFindMasks);
// Имя подходит под маску (* и ?, без учёта регистра)
function FarMaskMatch(const AName, AMask: WideString): Boolean;
// Имя подходит под одну из масок
function FarMasksMatch(const AName: WideString;
  const AMasks: TFarFindMasks): Boolean;
// Образцы текста для кодировок ACodePage (символы, которых в кодировке
// нет, - эта кодировка пропускается)
procedure FarBuildPatterns(const AText: WideString;
  ACodePage: TFarFindCodePage; ACaseSensitive: Boolean;
  var APatterns: TFarPatterns);
// Есть ли образец в буфере ABuffer длиной ALength; AWhole - отдельным
// словом. AFrom - с какого байта начинать (раньше - только для проверки
// края слова)
function FarPatternIn(const APattern: TFarPattern; ABuffer: PAnsiChar;
  ALength, AFrom: Integer; AWhole: Boolean): Boolean;

implementation

const
  FarFindChunk = 1024 * 1024;
  FarCpAnsi = 1251;
  FarCpOem = 866;
  FarCpUtf8 = 65001;
  FarCpUtf16 = 1200;
  FarReparsePoint = $400;     // FILE_ATTRIBUTE_REPARSE_POINT
  FarAttrDirectory = $10;
  FfShareAll = 7;             // FILE_SHARE_READ, WRITE, DELETE

type
  TFarWin32FindDataW = record
    dwFileAttributes: DWORD;
    ftCreationTime: TFileTime;
    ftLastAccessTime: TFileTime;
    ftLastWriteTime: TFileTime;
    nFileSizeHigh: DWORD;
    nFileSizeLow: DWORD;
    dwReserved0: DWORD;
    dwReserved1: DWORD;
    cFileName: array[0..MAX_PATH - 1] of WideChar;
    cAlternateFileName: array[0..13] of WideChar;
  end;

function FfFindFirst(AFileName: PWideChar;
  var AFindData: TFarWin32FindDataW): THandle; stdcall;
  external 'kernel32.dll' name 'FindFirstFileW';
function FfFindNext(AFindHandle: THandle;
  var AFindData: TFarWin32FindDataW): BOOL; stdcall;
  external 'kernel32.dll' name 'FindNextFileW';
function FfFindClose(AFindHandle: THandle): BOOL; stdcall;
  external 'kernel32.dll' name 'FindClose';
function FfCreateFile(AFileName: PWideChar; AAccess, AShare: DWORD;
  ASecurity: Pointer; ACreation, AFlags: DWORD;
  ATemplate: THandle): THandle; stdcall;
  external 'kernel32.dll' name 'CreateFileW';
function FfReadFile(AFile: THandle; ABuffer: Pointer; AToRead: DWORD;
  var ARead: DWORD; AOverlapped: Pointer): BOOL; stdcall;
  external 'kernel32.dll' name 'ReadFile';
function FfWideToMulti(ACodePage: UINT; AFlags: DWORD; AWide: PWideChar;
  AWideLen: Integer; AMulti: PAnsiChar; AMultiLen: Integer;
  ADefault: PAnsiChar; AUsedDefault: Pointer): Integer; stdcall;
  external 'kernel32.dll' name 'WideCharToMultiByte';
function FfMultiToWide(ACodePage: UINT; AFlags: DWORD; AMulti: PAnsiChar;
  AMultiLen: Integer; AWide: PWideChar; AWideLen: Integer): Integer; stdcall;
  external 'kernel32.dll' name 'MultiByteToWideChar';
function FfCharLower(AText: PWideChar): PWideChar; stdcall;
  external 'user32.dll' name 'CharLowerW';
function FfCharUpper(AText: PWideChar): PWideChar; stdcall;
  external 'user32.dll' name 'CharUpperW';
function FfIsAlphaNum(AChar: WideChar): BOOL; stdcall;
  external 'user32.dll' name 'IsCharAlphaNumericW';

// ---------------------------------------------------------------------------
//  Маски
// ---------------------------------------------------------------------------

function FfLowerChar(AChar: WideChar): WideChar;
var
  Buffer: array[0..1] of WideChar;
begin
  Buffer[0] := AChar;
  Buffer[1] := #0;
  FfCharLower(@Buffer[0]);
  Result := Buffer[0];
end;

function FfUpperChar(AChar: WideChar): WideChar;
var
  Buffer: array[0..1] of WideChar;
begin
  Buffer[0] := AChar;
  Buffer[1] := #0;
  FfCharUpper(@Buffer[0]);
  Result := Buffer[0];
end;

function FfLower(const AText: WideString): WideString;
var
  CharIdx: Integer;
begin
  Result := AText;
  for CharIdx := 1 to Length(Result) do
    Result[CharIdx] := FfLowerChar(Result[CharIdx]);
end;

procedure FarSplitMasks(const AText: WideString; var AMasks: TFarFindMasks);
var
  Pos0, PartEnd, Count: Integer;
  Part: WideString;
begin
  SetLength(AMasks, 0);
  Count := 0;
  Pos0 := 1;
  while Pos0 <= Length(AText) do
  begin
    PartEnd := Pos0;
    while (PartEnd <= Length(AText)) and (AText[PartEnd] <> ',') and
          (AText[PartEnd] <> ';') do
      Inc(PartEnd);
    Part := Copy(AText, Pos0, PartEnd - Pos0);
    Pos0 := PartEnd + 1;
    while (Part <> '') and (Part[1] = ' ') do
      Delete(Part, 1, 1);
    while (Part <> '') and (Part[Length(Part)] = ' ') do
      SetLength(Part, Length(Part) - 1);
    if (Part <> '') and (Part[1] = '"') and (Part[Length(Part)] = '"') then
      Part := Copy(Part, 2, Length(Part) - 2);
    if Part = '' then
      Continue;
    if Part = '*.*' then
      Part := '*';
    SetLength(AMasks, Count + 1);
    AMasks[Count] := FfLower(Part);
    Inc(Count);
  end;
  if Count = 0 then
  begin
    SetLength(AMasks, 1);
    AMasks[0] := '*';
  end;
end;

// Сопоставление с маской (маска уже строчными): * - любая часть, ? -
// один символ
function FfMatch(const AName, AMask: WideString): Boolean;
var
  NamePos, MaskPos, StarMask, StarName: Integer;
begin
  NamePos := 1;
  MaskPos := 1;
  StarMask := 0;
  StarName := 0;
  while NamePos <= Length(AName) do
  begin
    if (MaskPos <= Length(AMask)) and ((AMask[MaskPos] = '?') or
       (AMask[MaskPos] = AName[NamePos])) then
    begin
      Inc(NamePos);
      Inc(MaskPos);
    end
    else if (MaskPos <= Length(AMask)) and (AMask[MaskPos] = '*') then
    begin
      StarMask := MaskPos;
      StarName := NamePos;
      Inc(MaskPos);
    end
    else if StarMask > 0 then
    begin
      MaskPos := StarMask + 1;
      Inc(StarName);
      NamePos := StarName;
    end
    else
    begin
      Result := False;
      Exit;
    end;
  end;
  while (MaskPos <= Length(AMask)) and (AMask[MaskPos] = '*') do
    Inc(MaskPos);
  Result := MaskPos > Length(AMask);
end;

function FarMaskMatch(const AName, AMask: WideString): Boolean;
begin
  Result := FfMatch(FfLower(AName), FfLower(AMask));
end;

function FarMasksMatch(const AName: WideString;
  const AMasks: TFarFindMasks): Boolean;
var
  MaskIdx: Integer;
  LowName: WideString;
begin
  LowName := FfLower(AName);
  for MaskIdx := 0 to High(AMasks) do
    if FfMatch(LowName, AMasks[MaskIdx]) then
    begin
      Result := True;
      Exit;
    end;
  Result := False;
end;

// ---------------------------------------------------------------------------
//  Образцы текста
// ---------------------------------------------------------------------------

// Символ в байты кодировки ACodePage; нет его там - False
function FfEncodeChar(AChar: WideChar; ACodePage: UINT;
  var ABytes: string): Boolean;
var
  Buffer: array[0..7] of AnsiChar;
  ByteCount: Integer;
  UsedDefault: BOOL;
begin
  Result := False;
  ABytes := '';
  if ACodePage = FarCpUtf16 then
  begin
    SetLength(ABytes, 2);
    ABytes[1] := AnsiChar(Ord(AChar) and $FF);
    ABytes[2] := AnsiChar(Ord(AChar) shr 8);
    Result := True;
    Exit;
  end;
  UsedDefault := False;
  if ACodePage = FarCpUtf8 then
    ByteCount := FfWideToMulti(ACodePage, 0, @AChar, 1, @Buffer[0],
      SizeOf(Buffer), nil, nil)
  else
    ByteCount := FfWideToMulti(ACodePage, 0, @AChar, 1, @Buffer[0],
      SizeOf(Buffer), nil, @UsedDefault);
  if (ByteCount <= 0) or UsedDefault then
    Exit;
  SetString(ABytes, PAnsiChar(@Buffer[0]), ByteCount);
  Result := True;
end;

function FfBuildOne(const AText: WideString; ACodePage: UINT;
  ACaseSensitive: Boolean; var APattern: TFarPattern): Boolean;
var
  CharIdx, ByteIdx, UnitLen: Integer;
  LowChar, UpChar: WideChar;
  LowBytes, UpBytes: string;
  Decoded: WideChar;
  ByteValue: AnsiChar;
begin
  Result := False;
  APattern.CodePage := ACodePage;
  SetLength(APattern.Units, Length(AText));
  APattern.MaxLen := 0;
  for CharIdx := 1 to Length(AText) do
  begin
    if ACaseSensitive then
    begin
      LowChar := AText[CharIdx];
      UpChar := LowChar;
    end
    else
    begin
      LowChar := FfLowerChar(AText[CharIdx]);
      UpChar := FfUpperChar(AText[CharIdx]);
    end;
    if not FfEncodeChar(LowChar, ACodePage, LowBytes) then
      Exit;
    if UpChar = LowChar then
      UpBytes := ''
    else if not FfEncodeChar(UpChar, ACodePage, UpBytes) then
      Exit;
    if UpBytes = LowBytes then
      UpBytes := '';
    APattern.Units[CharIdx - 1].Alt1 := LowBytes;
    APattern.Units[CharIdx - 1].Alt2 := UpBytes;
    UnitLen := Length(LowBytes);
    if Length(UpBytes) > UnitLen then
      UnitLen := Length(UpBytes);
    Inc(APattern.MaxLen, UnitLen);
  end;
  FillChar(APattern.FirstByte, SizeOf(APattern.FirstByte), 0);
  if Length(APattern.Units) > 0 then
  begin
    APattern.FirstByte[Ord(APattern.Units[0].Alt1[1])] := True;
    if APattern.Units[0].Alt2 <> '' then
      APattern.FirstByte[Ord(APattern.Units[0].Alt2[1])] := True;
  end;
  // Буквы и цифры однобайтовой кодировки (для Whole words); у UTF-8 -
  // только ASCII, байты от $80 считаются частью буквы
  FillChar(APattern.WordByte, SizeOf(APattern.WordByte), 0);
  for ByteIdx := 0 to 255 do
  begin
    if (ACodePage = FarCpUtf8) or (ACodePage = FarCpUtf16) then
    begin
      if ByteIdx >= $80 then
        APattern.WordByte[ByteIdx] := ACodePage = FarCpUtf8
      else
        APattern.WordByte[ByteIdx] := (AnsiChar(ByteIdx) in ['0'..'9',
          'A'..'Z', 'a'..'z', '_']);
      Continue;
    end;
    ByteValue := AnsiChar(ByteIdx);
    Decoded := #0;
    if FfMultiToWide(ACodePage, 0, @ByteValue, 1, @Decoded, 1) = 1 then
      APattern.WordByte[ByteIdx] := FfIsAlphaNum(Decoded) or (Decoded = '_');
  end;
  Result := Length(APattern.Units) > 0;
end;

procedure FarBuildPatterns(const AText: WideString;
  ACodePage: TFarFindCodePage; ACaseSensitive: Boolean;
  var APatterns: TFarPatterns);
var
  Pages: array of UINT;
  PageIdx, Count: Integer;
  Pattern: TFarPattern;
begin
  SetLength(APatterns, 0);
  if AText = '' then
    Exit;
  case ACodePage of
    fcpAnsi:
      begin
        SetLength(Pages, 1);
        Pages[0] := FarCpAnsi;
      end;
    fcpOem:
      begin
        SetLength(Pages, 1);
        Pages[0] := FarCpOem;
      end;
    fcpUtf8:
      begin
        SetLength(Pages, 1);
        Pages[0] := FarCpUtf8;
      end;
    fcpUtf16:
      begin
        SetLength(Pages, 1);
        Pages[0] := FarCpUtf16;
      end;
  else
    SetLength(Pages, 4);
    Pages[0] := FarCpAnsi;
    Pages[1] := FarCpOem;
    Pages[2] := FarCpUtf8;
    Pages[3] := FarCpUtf16;
  end;
  Count := 0;
  for PageIdx := 0 to High(Pages) do
    if FfBuildOne(AText, Pages[PageIdx], ACaseSensitive, Pattern) then
    begin
      SetLength(APatterns, Count + 1);
      APatterns[Count] := Pattern;
      Inc(Count);
    end;
end;

// Совпадение образца с байтами с позиции AStart (0-based); AEnd - за
// последним байтом совпадения
function FfMatchAt(const APattern: TFarPattern; ABuffer: PAnsiChar;
  ALength, AStart: Integer; var AEnd: Integer): Boolean;
var
  UnitIdx, BytePos: Integer;

  function Same(const AAlt: string): Boolean;
  var
    AltIdx: Integer;
  begin
    Result := False;
    if (AAlt = '') or (BytePos + Length(AAlt) > ALength) then
      Exit;
    for AltIdx := 1 to Length(AAlt) do
      if ABuffer[BytePos + AltIdx - 1] <> AAlt[AltIdx] then
        Exit;
    Result := True;
  end;

begin
  Result := False;
  BytePos := AStart;
  for UnitIdx := 0 to High(APattern.Units) do
  begin
    if Same(APattern.Units[UnitIdx].Alt1) then
      Inc(BytePos, Length(APattern.Units[UnitIdx].Alt1))
    else if Same(APattern.Units[UnitIdx].Alt2) then
      Inc(BytePos, Length(APattern.Units[UnitIdx].Alt2))
    else
      Exit;
  end;
  AEnd := BytePos;
  Result := True;
end;

// Край слова: символ перед AStart и после AEnd - не буква / цифра / _
function FfWordEdges(const APattern: TFarPattern; ABuffer: PAnsiChar;
  ALength, AStart, AEnd: Integer): Boolean;
var
  WideValue: WideChar;
begin
  Result := False;
  if APattern.CodePage = FarCpUtf16 then
  begin
    if AStart >= 2 then
    begin
      WideValue := WideChar(Ord(ABuffer[AStart - 2]) or
        (Ord(ABuffer[AStart - 1]) shl 8));
      if FfIsAlphaNum(WideValue) or (WideValue = '_') then
        Exit;
    end;
    if AEnd + 1 < ALength then
    begin
      WideValue := WideChar(Ord(ABuffer[AEnd]) or (Ord(ABuffer[AEnd + 1]) shl 8));
      if FfIsAlphaNum(WideValue) or (WideValue = '_') then
        Exit;
    end;
    Result := True;
    Exit;
  end;
  if (AStart > 0) and APattern.WordByte[Ord(ABuffer[AStart - 1])] then
    Exit;
  if (AEnd < ALength) and APattern.WordByte[Ord(ABuffer[AEnd])] then
    Exit;
  Result := True;
end;

function FarPatternIn(const APattern: TFarPattern; ABuffer: PAnsiChar;
  ALength, AFrom: Integer; AWhole: Boolean): Boolean;
var
  BytePos, MatchEnd: Integer;
begin
  Result := False;
  if Length(APattern.Units) = 0 then
    Exit;
  for BytePos := AFrom to ALength - 1 do
    if APattern.FirstByte[Ord(ABuffer[BytePos])] and
       FfMatchAt(APattern, ABuffer, ALength, BytePos, MatchEnd) and
       (not AWhole or FfWordEdges(APattern, ABuffer, ALength, BytePos,
        MatchEnd)) then
    begin
      Result := True;
      Exit;
    end;
end;

// ---------------------------------------------------------------------------
//  Поток поиска
// ---------------------------------------------------------------------------

constructor TFarFindThread.Create(const AOptions: TFarFindOptions);
begin
  FOptions := AOptions;
  if (FOptions.Root <> '') and (FOptions.Root[Length(FOptions.Root)] <> '\') then
    FOptions.Root := FOptions.Root + '\';
  FarSplitMasks(FOptions.Masks, FMasks);
  FarBuildPatterns(FOptions.Text, FOptions.CodePage, FOptions.CaseSensitive,
    FPatterns);
  InitializeCriticalSection(FLock);
  FFoundCount := 0;
  FFinished := 0;
  FreeOnTerminate := False;
  inherited Create(False);
end;

destructor TFarFindThread.Destroy;
begin
  FCancelled := True;
  inherited Destroy;   // ждёт конца Execute
  DeleteCriticalSection(FLock);
end;

procedure TFarFindThread.Cancel;
begin
  FCancelled := True;
end;

function TFarFindThread.GetFinished: Boolean;
begin
  Result := FFinished <> 0;
end;

function TFarFindThread.CurrentDir: WideString;
begin
  EnterCriticalSection(FLock);
  try
    Result := FCurrentDir;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TFarFindThread.AddFound(const AItem: TFarFindItem);
begin
  EnterCriticalSection(FLock);
  try
    if FFoundCount >= Length(FFound) then
      SetLength(FFound, FFoundCount * 2 + 64);
    FFound[FFoundCount] := AItem;
    Inc(FFoundCount);
    if AItem.IsDir then
      Inc(FDirCount)
    else
      Inc(FFileCount);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TFarFindThread.TakeFound(var AItems: TFarFindItems): Integer;
var
  OldLen, ItemIdx: Integer;
begin
  EnterCriticalSection(FLock);
  try
    Result := FFoundCount;
    if Result > 0 then
    begin
      OldLen := Length(AItems);
      SetLength(AItems, OldLen + Result);
      for ItemIdx := 0 to Result - 1 do
        AItems[OldLen + ItemIdx] := FFound[ItemIdx];
      FFoundCount := 0;
      SetLength(FFound, 0);
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

// Есть ли текст в файле (хотя бы в одной кодировке). Кусок читается в
// буфер после хвоста прошлого куска (Carry байт) - совпадение на стыке
// не теряется
function TFarFindThread.FileHasText(const AFileName: WideString): Boolean;
var
  FileHandle: THandle;
  Buffer: string;
  Carry, ReadCount: DWORD;
  KeepLen, PatIdx, MaxPattern, From: Integer;
begin
  Result := False;
  FileHandle := FfCreateFile(PWideChar(AFileName), GENERIC_READ,
    FfShareAll, nil,
    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if FileHandle = INVALID_HANDLE_VALUE then
    Exit;
  try
    MaxPattern := 0;
    for PatIdx := 0 to High(FPatterns) do
      if FPatterns[PatIdx].MaxLen > MaxPattern then
        MaxPattern := FPatterns[PatIdx].MaxLen;
    // Хвост: совпадение, начатое в прошлом куске, плюс символ перед ним
    // (край слова)
    KeepLen := MaxPattern + 4;
    SetLength(Buffer, FarFindChunk + KeepLen);
    Carry := 0;
    repeat
      if FCancelled then
        Exit;
      ReadCount := 0;
      if not FfReadFile(FileHandle, @Buffer[Carry + 1], FarFindChunk,
         ReadCount, nil) or (ReadCount = 0) then
        Break;
      // Новые позиции - с начала прочитанного, но не раньше, чем
      // кончились проверенные в прошлом куске (Carry - его хвост)
      From := 0;
      if Carry > DWORD(MaxPattern) then
        From := Carry - DWORD(MaxPattern);
      for PatIdx := 0 to High(FPatterns) do
        if FarPatternIn(FPatterns[PatIdx], PAnsiChar(Buffer),
           Integer(Carry + ReadCount), From, FOptions.WholeWords) then
        begin
          Result := True;
          Exit;
        end;
      // Хвост - в начало буфера
      if Carry + ReadCount > DWORD(KeepLen) then
      begin
        Move(Buffer[Carry + ReadCount - DWORD(KeepLen) + 1], Buffer[1], KeepLen);
        Carry := KeepLen;
      end
      else
        Carry := Carry + ReadCount;
    until ReadCount < FarFindChunk;
  finally
    CloseHandle(FileHandle);
  end;
end;

procedure TFarFindThread.ScanDir(const ADir: WideString);
var
  FindHandle: THandle;
  FindData: TFarWin32FindDataW;
  Name: WideString;
  Item: TFarFindItem;
  IsDir, Matches: Boolean;
  SubDirs: array of WideString;
  SubCount, SubIdx: Integer;
begin
  if FCancelled then
    Exit;
  EnterCriticalSection(FLock);
  try
    FCurrentDir := ADir;
  finally
    LeaveCriticalSection(FLock);
  end;
  SubCount := 0;
  SetLength(SubDirs, 0);
  FindHandle := FfFindFirst(PWideChar(ADir + '*'), FindData);
  if FindHandle = INVALID_HANDLE_VALUE then
    Exit;
  try
    repeat
      if FCancelled then
        Exit;
      Name := PWideChar(@FindData.cFileName[0]);
      if (Name = '.') or (Name = '..') then
        Continue;
      IsDir := (FindData.dwFileAttributes and FarAttrDirectory) <> 0;
      Matches := FarMasksMatch(Name, FMasks);
      if Matches then
      begin
        if IsDir then
          Matches := FOptions.Folders and (Length(FPatterns) = 0)
        else if Length(FPatterns) > 0 then
          Matches := FileHasText(ADir + Name);
      end;
      if Matches then
      begin
        Item.Dir := ADir;
        Item.Name := Name;
        Item.IsDir := IsDir;
        Item.Size := (Int64(FindData.nFileSizeHigh) shl 32) or
          FindData.nFileSizeLow;
        Item.Time := FindData.ftLastWriteTime;
        Item.Attr := FindData.dwFileAttributes;
        AddFound(Item);
      end;
      // Подпапки - после файлов этой папки (в списке папка - одним
      // блоком); ссылки (reparse point) не обходятся
      if IsDir and FOptions.Recursive and
         ((FindData.dwFileAttributes and FarReparsePoint) = 0) then
      begin
        SetLength(SubDirs, SubCount + 1);
        SubDirs[SubCount] := ADir + Name + '\';
        Inc(SubCount);
      end;
    until not FfFindNext(FindHandle, FindData);
  finally
    FfFindClose(FindHandle);
  end;
  for SubIdx := 0 to SubCount - 1 do
  begin
    if FCancelled then
      Exit;
    ScanDir(SubDirs[SubIdx]);
  end;
end;

procedure TFarFindThread.Execute;
begin
  try
    ScanDir(FOptions.Root);
  except
    // ошибка обхода - поиск просто кончается
  end;
  InterlockedExchange(FFinished, 1);
end;

end.
