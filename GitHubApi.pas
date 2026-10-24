unit GitHubApi;

// ---------------------------------------------------------------------------
//  GitHub REST API для окна Clone Repository (DlgGitClone): список
//  репозиториев пользователя и проверка токена. Без VCL.
//
//  - запросы - WinINet (как загрузки SzSetup): HTTPS GET на
//    api.github.com с заголовками Authorization: token <токен>,
//    Accept: application/vnd.github+json, User-Agent: unIDE (без него
//    GitHub отвечает 403);
//  - список: GET /user/repos?per_page=100&page=N&affiliation=owner,
//    collaborator,organization_member&sort=full_name - страницы, пока
//    приходит по 100;
//  - токен: GET /user - логин владельца токена;
//  - ответ (UTF-8) разбирается своим маленьким разбором JSON: из массива
//    объектов берутся строки и логические значения верхнего уровня
//    объекта, вложенные объекты (owner, permissions) пропускаются.
// ---------------------------------------------------------------------------

interface

uses
  Windows, SysUtils, Classes;

type
  TGitHubRepo = record
    FullName: WideString;     // владелец/имя
    Name: WideString;         // имя - папка клона по умолчанию
    CloneUrl: WideString;     // https://github.com/владелец/имя.git
    Description: WideString;
    IsPrivate: Boolean;
    IsFork: Boolean;
  end;
  TGitHubRepos = array of TGitHubRepo;

// Репозитории владельца токена (свои, где соавтор, организаций). False -
// AError: почему (нет сети, 401 - токен не подходит ...)
function GitHubListRepos(const AToken: string; var ARepos: TGitHubRepos;
  var AError: string): Boolean;
// Логин владельца токена (GET /user). False - AError
function GitHubTokenLogin(const AToken: string; var ALogin: string;
  var AError: string): Boolean;
// 'владелец/имя', 'github.com/владелец/имя', адрес https или git@ ->
// адрес для git clone; имя репозитория - в AName. '' - не разобрать
function GitHubNormalizeUrl(const AText: string; var AName: string): string;

implementation

const
  GhApiHost = 'https://api.github.com';
  GhPerPage = 100;
  GhMaxPages = 20;

  GhOpenPreconfig = 0;
  GhFlagReload = $80000000;
  GhFlagNoCacheWrite = $04000000;
  GhFlagPragmaNoCache = $00000100;
  GhFlagNoUi = $00000200;
  GhFlagNoCookies = $00080000;
  GhFlagSecure = $00800000;
  GhOptionConnectTimeout = 2;
  GhOptionReceiveTimeout = 6;
  GhQueryStatusCode = 19;
  GhQueryFlagNumber = $20000000;
  GhCpUtf8 = 65001;

function GhInternetOpen(AAgent: PWideChar; AAccessType: DWORD;
  AProxy, AProxyBypass: PWideChar; AFlags: DWORD): Pointer; stdcall;
  external 'wininet.dll' name 'InternetOpenW';
function GhInternetOpenUrl(ASession: Pointer; AUrl: PWideChar;
  AHeaders: PWideChar; AHeadersLength: DWORD; AFlags: DWORD;
  AContext: DWORD): Pointer; stdcall;
  external 'wininet.dll' name 'InternetOpenUrlW';
function GhInternetReadFile(AFile: Pointer; ABuffer: Pointer;
  AToRead: DWORD; var ARead: DWORD): BOOL; stdcall;
  external 'wininet.dll' name 'InternetReadFile';
function GhInternetCloseHandle(AHandle: Pointer): BOOL; stdcall;
  external 'wininet.dll' name 'InternetCloseHandle';
function GhInternetSetOption(AHandle: Pointer; AOption: DWORD;
  ABuffer: Pointer; ABufferLength: DWORD): BOOL; stdcall;
  external 'wininet.dll' name 'InternetSetOptionW';
function GhHttpQueryInfo(ARequest: Pointer; AInfoLevel: DWORD;
  ABuffer: Pointer; var ABufferLength: DWORD; var AIndex: DWORD): BOOL;
  stdcall; external 'wininet.dll' name 'HttpQueryInfoW';
function GhMultiToWide(ACodePage: UINT; AFlags: DWORD; AMulti: PAnsiChar;
  AMultiLen: Integer; AWide: PWideChar; AWideLen: Integer): Integer; stdcall;
  external 'kernel32.dll' name 'MultiByteToWideChar';

function GhFromUtf8(const AText: string): WideString;
var
  WideLen: Integer;
begin
  Result := '';
  if AText = '' then
    Exit;
  WideLen := GhMultiToWide(GhCpUtf8, 0, PAnsiChar(AText), Length(AText),
    nil, 0);
  if WideLen <= 0 then
    Exit;
  SetLength(Result, WideLen);
  GhMultiToWide(GhCpUtf8, 0, PAnsiChar(AText), Length(AText),
    PWideChar(Result), WideLen);
end;

// Текст ошибки Windows / WinINet
function GhErrorText(ACode: DWORD): string;
var
  Buffer: array[0..511] of Char;
  Len: DWORD;
begin
  Len := FormatMessage(FORMAT_MESSAGE_FROM_HMODULE or
    FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_IGNORE_INSERTS,
    Pointer(GetModuleHandle('wininet.dll')), ACode, 0, @Buffer[0],
    SizeOf(Buffer), nil);
  if Len = 0 then
    Result := 'ошибка ' + IntToStr(ACode)
  else
  begin
    SetString(Result, PChar(@Buffer[0]), Len);
    Result := Trim(Result) + ' (' + IntToStr(ACode) + ')';
  end;
end;

// GET APath (от api.github.com) с токеном. ABody - ответ (UTF-8),
// AStatus - код HTTP. False - запрос не прошёл (AError)
function GhGet(const AToken, APath: string; var ABody: string;
  var AStatus: Integer; var AError: string): Boolean;
var
  Session, Request: Pointer;
  Headers, Url, Agent: WideString;
  Buffer: array[0..16383] of AnsiChar;
  ReadCount, StatusCode, StatusLen, StatusIndex, Timeout: DWORD;
  Piece: string;
begin
  Result := False;
  ABody := '';
  AStatus := 0;
  AError := '';
  Agent := 'unIDE';
  Session := GhInternetOpen(PWideChar(Agent), GhOpenPreconfig, nil, nil, 0);
  if Session = nil then
  begin
    AError := 'WinINet: ' + GhErrorText(GetLastError);
    Exit;
  end;
  try
    Timeout := 20000;
    GhInternetSetOption(Session, GhOptionConnectTimeout, @Timeout,
      SizeOf(Timeout));
    GhInternetSetOption(Session, GhOptionReceiveTimeout, @Timeout,
      SizeOf(Timeout));
    Headers := 'Accept: application/vnd.github+json'#13#10;
    if AToken <> '' then
      Headers := Headers + 'Authorization: token ' + WideString(AToken) +
        #13#10;
    Url := GhApiHost + WideString(APath);
    Request := GhInternetOpenUrl(Session, PWideChar(Url), PWideChar(Headers),
      DWORD(Length(Headers)), GhFlagReload or GhFlagNoCacheWrite or
      GhFlagPragmaNoCache or GhFlagNoUi or GhFlagNoCookies or GhFlagSecure,
      0);
    if Request = nil then
    begin
      AError := 'api.github.com: ' + GhErrorText(GetLastError);
      Exit;
    end;
    try
      StatusCode := 0;
      StatusLen := SizeOf(StatusCode);
      StatusIndex := 0;
      if GhHttpQueryInfo(Request, GhQueryStatusCode or GhQueryFlagNumber,
         @StatusCode, StatusLen, StatusIndex) then
        AStatus := Integer(StatusCode);
      repeat
        ReadCount := 0;
        if not GhInternetReadFile(Request, @Buffer[0], SizeOf(Buffer),
           ReadCount) then
        begin
          AError := 'чтение ответа: ' + GhErrorText(GetLastError);
          Exit;
        end;
        if ReadCount > 0 then
        begin
          SetString(Piece, PAnsiChar(@Buffer[0]), ReadCount);
          ABody := ABody + Piece;
        end;
      until ReadCount = 0;
      Result := True;
    finally
      GhInternetCloseHandle(Request);
    end;
  finally
    GhInternetCloseHandle(Session);
  end;
end;

// ---------------------------------------------------------------------------
//  Разбор JSON: массив объектов / один объект; у объекта - пары верхнего
//  уровня со строкой, числом, true / false / null (как текст)
// ---------------------------------------------------------------------------

type
  TGhPairs = record
    Keys, Values: array of WideString;
  end;

  TGhJson = class
  private
    FText: WideString;
    FPos: Integer;
    function Peek: WideChar;
    procedure SkipSpaces;
    function ReadString: WideString;
    function ReadLiteral: WideString;
    procedure SkipValue;
  public
    constructor Create(const AText: WideString);
    // '[' / '{' / '' - что в начале текста
    function FirstChar: WideChar;
    // Объект с текущего места: пары верхнего уровня. False - не объект
    function ReadObject(var APairs: TGhPairs): Boolean;
    // Начало массива ('['); следующий элемент - True и место на нём,
    // конец массива - False
    function ArrayStart: Boolean;
    function ArrayNext(AFirst: Boolean): Boolean;
  end;

constructor TGhJson.Create(const AText: WideString);
begin
  inherited Create;
  FText := AText;
  FPos := 1;
end;

function TGhJson.Peek: WideChar;
begin
  if FPos <= Length(FText) then
    Result := FText[FPos]
  else
    Result := #0;
end;

procedure TGhJson.SkipSpaces;
begin
  while (FPos <= Length(FText)) and ((FText[FPos] = ' ') or
        (FText[FPos] = #9) or (FText[FPos] = #10) or (FText[FPos] = #13)) do
    Inc(FPos);
end;

function TGhJson.FirstChar: WideChar;
begin
  SkipSpaces;
  Result := Peek;
end;

// Строка в кавычках (место - на открывающей кавычке)
function TGhJson.ReadString: WideString;
var
  CurChar: WideChar;
  HexText: string;
  CodeValue: Integer;
begin
  Result := '';
  if Peek <> '"' then
    Exit;
  Inc(FPos);
  while FPos <= Length(FText) do
  begin
    CurChar := FText[FPos];
    Inc(FPos);
    if CurChar = '"' then
      Exit;
    if CurChar <> '\' then
    begin
      Result := Result + CurChar;
      Continue;
    end;
    if FPos > Length(FText) then
      Exit;
    CurChar := FText[FPos];
    Inc(FPos);
    case CurChar of
      'n': Result := Result + #10;
      'r': Result := Result + #13;
      't': Result := Result + #9;
      'b': Result := Result + #8;
      'f': Result := Result + #12;
      'u':
        begin
          HexText := string(Copy(FText, FPos, 4));
          Inc(FPos, 4);
          CodeValue := StrToIntDef('$' + HexText, Ord('?'));
          Result := Result + WideChar(CodeValue);
        end;
    else
      Result := Result + CurChar;   // \" \\ \/
    end;
  end;
end;

// Число, true, false, null - до разделителя
function TGhJson.ReadLiteral: WideString;
var
  StartPos: Integer;
begin
  StartPos := FPos;
  while (FPos <= Length(FText)) and not ((FText[FPos] = ',') or
        (FText[FPos] = '}') or (FText[FPos] = ']') or (FText[FPos] = ' ') or
        (FText[FPos] = #9) or (FText[FPos] = #10) or (FText[FPos] = #13)) do
    Inc(FPos);
  Result := Copy(FText, StartPos, FPos - StartPos);
end;

// Пропустить значение любого вида (вложенные - по глубине, строки -
// целиком: в них бывают скобки)
procedure TGhJson.SkipValue;
var
  Depth: Integer;
begin
  SkipSpaces;
  case Peek of
    '"': ReadString;
    '{', '[':
      begin
        Depth := 0;
        while FPos <= Length(FText) do
        begin
          case FText[FPos] of
            '"':
              begin
                ReadString;
                Continue;
              end;
            '{', '[': Inc(Depth);
            '}', ']':
              begin
                Dec(Depth);
                if Depth = 0 then
                begin
                  Inc(FPos);
                  Exit;
                end;
              end;
          end;
          Inc(FPos);
        end;
      end;
  else
    ReadLiteral;
  end;
end;

function TGhJson.ReadObject(var APairs: TGhPairs): Boolean;
var
  Key, Value: WideString;
  Count: Integer;
begin
  Result := False;
  SetLength(APairs.Keys, 0);
  SetLength(APairs.Values, 0);
  SkipSpaces;
  if Peek <> '{' then
    Exit;
  Inc(FPos);
  Count := 0;
  repeat
    SkipSpaces;
    if Peek = '}' then
    begin
      Inc(FPos);
      Break;
    end;
    if Peek <> '"' then
      Exit;
    Key := ReadString;
    SkipSpaces;
    if Peek <> ':' then
      Exit;
    Inc(FPos);
    SkipSpaces;
    case Peek of
      '"':
        begin
          Value := ReadString;
          SetLength(APairs.Keys, Count + 1);
          SetLength(APairs.Values, Count + 1);
          APairs.Keys[Count] := Key;
          APairs.Values[Count] := Value;
          Inc(Count);
        end;
      '{', '[': SkipValue;
    else
      Value := ReadLiteral;
      if Value = 'null' then
        Value := '';
      SetLength(APairs.Keys, Count + 1);
      SetLength(APairs.Values, Count + 1);
      APairs.Keys[Count] := Key;
      APairs.Values[Count] := Value;
      Inc(Count);
    end;
    SkipSpaces;
    if Peek = ',' then
      Inc(FPos)
    else if Peek = '}' then
    begin
      Inc(FPos);
      Break;
    end
    else
      Exit;
  until FPos > Length(FText);
  Result := True;
end;

function TGhJson.ArrayStart: Boolean;
begin
  SkipSpaces;
  Result := Peek = '[';
  if Result then
    Inc(FPos);
end;

function TGhJson.ArrayNext(AFirst: Boolean): Boolean;
begin
  Result := False;
  SkipSpaces;
  if not AFirst then
  begin
    if Peek = ',' then
      Inc(FPos)
    else
      Exit;          // ']' или конец текста
    SkipSpaces;
  end;
  Result := (Peek <> ']') and (Peek <> #0);
end;

function GhPair(const APairs: TGhPairs; const AKey: WideString): WideString;
var
  PairIndex: Integer;
begin
  Result := '';
  for PairIndex := 0 to High(APairs.Keys) do
    if APairs.Keys[PairIndex] = AKey then
    begin
      Result := APairs.Values[PairIndex];
      Exit;
    end;
end;

// Текст ошибки по ответу: код HTTP и "message" из JSON
function GhStatusError(AStatus: Integer; const ABody: string): string;
var
  Reader: TGhJson;
  Pairs: TGhPairs;
  MessageText: string;
begin
  MessageText := '';
  Reader := TGhJson.Create(GhFromUtf8(ABody));
  try
    if Reader.ReadObject(Pairs) then
      MessageText := string(GhPair(Pairs, 'message'));
  finally
    Reader.Free;
  end;
  case AStatus of
    401: Result := 'GitHub: токен не подходит (401)';
    403: Result := 'GitHub: доступ запрещён (403)';
  else
    Result := 'GitHub: ответ ' + IntToStr(AStatus);
  end;
  if MessageText <> '' then
    Result := Result + ' - ' + MessageText;
end;

function GitHubListRepos(const AToken: string; var ARepos: TGitHubRepos;
  var AError: string): Boolean;
var
  Body: string;
  Status, PageIndex, PageCount, RepoCount: Integer;
  Reader: TGhJson;
  Pairs: TGhPairs;
  FirstItem: Boolean;
begin
  Result := False;
  SetLength(ARepos, 0);
  RepoCount := 0;
  for PageIndex := 1 to GhMaxPages do
  begin
    if not GhGet(AToken, '/user/repos?per_page=' + IntToStr(GhPerPage) +
       '&page=' + IntToStr(PageIndex) + '&sort=full_name&affiliation=owner,' +
       'collaborator,organization_member', Body, Status, AError) then
      Exit;
    if Status <> 200 then
    begin
      AError := GhStatusError(Status, Body);
      Exit;
    end;
    PageCount := 0;
    Reader := TGhJson.Create(GhFromUtf8(Body));
    try
      if not Reader.ArrayStart then
      begin
        AError := 'GitHub: ответ не список репозиториев';
        Exit;
      end;
      FirstItem := True;
      while Reader.ArrayNext(FirstItem) do
      begin
        FirstItem := False;
        if not Reader.ReadObject(Pairs) then
        begin
          AError := 'GitHub: ответ не разобран';
          Exit;
        end;
        Inc(PageCount);
        SetLength(ARepos, RepoCount + 1);
        ARepos[RepoCount].FullName := GhPair(Pairs, 'full_name');
        ARepos[RepoCount].Name := GhPair(Pairs, 'name');
        ARepos[RepoCount].CloneUrl := GhPair(Pairs, 'clone_url');
        ARepos[RepoCount].Description := GhPair(Pairs, 'description');
        ARepos[RepoCount].IsPrivate := GhPair(Pairs, 'private') = 'true';
        ARepos[RepoCount].IsFork := GhPair(Pairs, 'fork') = 'true';
        Inc(RepoCount);
      end;
    finally
      Reader.Free;
    end;
    if PageCount < GhPerPage then
      Break;
  end;
  Result := True;
end;

function GitHubTokenLogin(const AToken: string; var ALogin: string;
  var AError: string): Boolean;
var
  Body: string;
  Status: Integer;
  Reader: TGhJson;
  Pairs: TGhPairs;
begin
  Result := False;
  ALogin := '';
  if not GhGet(AToken, '/user', Body, Status, AError) then
    Exit;
  if Status <> 200 then
  begin
    AError := GhStatusError(Status, Body);
    Exit;
  end;
  Reader := TGhJson.Create(GhFromUtf8(Body));
  try
    if Reader.ReadObject(Pairs) then
      ALogin := string(GhPair(Pairs, 'login'));
  finally
    Reader.Free;
  end;
  Result := ALogin <> '';
  if not Result then
    AError := 'GitHub: в ответе нет логина';
end;

function GitHubNormalizeUrl(const AText: string; var AName: string): string;
var
  Text, LowText, Path: string;
  SlashPos: Integer;
begin
  Result := '';
  AName := '';
  Text := Trim(AText);
  while (Text <> '') and ((Text[Length(Text)] = '/') or
        (Text[Length(Text)] = '\')) do
    SetLength(Text, Length(Text) - 1);
  if Text = '' then
    Exit;
  LowText := LowerCase(Text);
  if (Pos('://', LowText) > 0) or (Copy(LowText, 1, 4) = 'git@') then
    Result := Text                       // полный адрес - как есть
  else
  begin
    // github.com/владелец/имя или владелец/имя
    Path := Text;
    if Copy(LowText, 1, 11) = 'github.com/' then
      Path := Copy(Text, 12, MaxInt);
    SlashPos := Pos('/', Path);
    if (SlashPos <= 1) or (SlashPos = Length(Path)) or
       (Pos('/', Copy(Path, SlashPos + 1, MaxInt)) > 0) or
       (Pos(' ', Path) > 0) then
      Exit;
    Result := 'https://github.com/' + Path;
    if LowerCase(Copy(Result, Length(Result) - 3, 4)) <> '.git' then
      Result := Result + '.git';
  end;
  // Имя - последняя часть без .git
  AName := Result;
  SlashPos := LastDelimiter('/:', AName);
  AName := Copy(AName, SlashPos + 1, MaxInt);
  if LowerCase(Copy(AName, Length(AName) - 3, 4)) = '.git' then
    SetLength(AName, Length(AName) - 4);
  if AName = '' then
    Result := '';
end;

end.
