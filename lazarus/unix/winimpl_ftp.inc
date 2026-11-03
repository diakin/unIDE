// --- WinInet FTP (Linux): то, что зовёт FarFtp ---
//
// Свой клиент FTP на ssockets (fcl-net): управляющее соединение, данные -
// всегда пассивный режим (PASV; EPSV, если PASV не принят). Дескрипторы
// WinInet - объекты TUnixFtpHandle (сеанс, соединение, поиск, файл).
// Ошибка ответа сервера - код 12003 (ERROR_INTERNET_EXTENDED_ERROR) и
// текст ответа для InternetGetLastResponseInfoA; ошибка сети - 12029
// (не соединиться), 12007 (имя не найдено), 12002 (время вышло), 12030
// (соединение разорвано). Текст для кода - FormatMessageA ниже.
// Список папки: MLSD; сервер его не знает - LIST (формат ls и DOS).

const
  UnixFtpErrTimeout = 12002;
  UnixFtpErrExtended = 12003;
  UnixFtpErrNameNotResolved = 12007;
  UnixFtpErrCannotConnect = 12029;
  UnixFtpErrAborted = 12030;
  UnixFtpErrNoMoreFiles = 18;

type
  TUnixFtpKind = (ufkSession, ufkConnect, ufkFind, ufkFile);

  TUnixFtpHandle = class
    Kind: TUnixFtpKind;
    // Сеанс: тайм-ауты, мс
    ConnectTimeout, IoTimeout: Integer;
    // Соединение
    Ctrl: TInetSocket;
    Host: string;
    // Поиск: найденное, следующий номер
    Found: array of WIN32_FIND_DATAA;
    FoundIdx: Integer;
    // Файл: соединение данных, его управляющее соединение
    Data: TInetSocket;
    Owner: TUnixFtpHandle;
  end;

threadvar
  UnixFtpResponse: AnsiString;

// Освободить дескриптор с его сокетами
procedure UnixFtpFree(AHandle: TUnixFtpHandle);
begin
  if AHandle = nil then
    Exit;
  AHandle.Data.Free;
  AHandle.Ctrl.Free;
  AHandle.Free;
end;

procedure UnixFtpFail(ACode: DWORD; const AText: AnsiString);
begin
  UnixFtpResponse := AText;
  UnixLastError := ACode;
end;

// Ошибка сокета (исключение ssockets) -> код WinInet
procedure UnixFtpSocketFail(AErr: Exception; const AHost: string);
var
  Code: DWORD;
begin
  Code := UnixFtpErrAborted;
  if AErr is ESocketError then
    case ESocketError(AErr).Code of
      seHostNotFound: Code := UnixFtpErrNameNotResolved;
      seConnectFailed: Code := UnixFtpErrCannotConnect;
      seConnectTimeOut, seIOTimeOut: Code := UnixFtpErrTimeout;
    end;
  UnixFtpFail(Code, AHost + ': ' + AErr.Message);
end;

// Строка ответа (без CRLF); False - соединение закрыто / ошибка
function UnixFtpReadLine(ASock: TInetSocket; var ALine: AnsiString): Boolean;
var
  OneChar: AnsiChar;
  Got: Integer;
begin
  Result := False;
  ALine := '';
  repeat
    Got := ASock.Read(OneChar, 1);
    if Got <= 0 then
      Exit;
    if OneChar = #10 then
      Break;
    if OneChar <> #13 then
      ALine := ALine + OneChar;
  until False;
  Result := True;
end;

// Ответ сервера (многострочный '123-' ... '123 '): код, весь текст -
// AText; 0 - соединение потеряно
function UnixFtpReply(ASock: TInetSocket; var AText: AnsiString): Integer;
var
  Line: AnsiString;
  Code: Integer;
begin
  Result := 0;
  AText := '';
  try
    if not UnixFtpReadLine(ASock, Line) then
      Exit;
    AText := Line;
    Code := StrToIntDef(Copy(Line, 1, 3), 0);
    if (Length(Line) >= 4) and (Line[4] = '-') then
      repeat
        if not UnixFtpReadLine(ASock, Line) then
          Exit;
        AText := AText + #13#10 + Line;
      until (Length(Line) >= 4) and (Copy(Line, 1, 3) = Copy(AText, 1, 3)) and
            (Line[4] = ' ');
    Result := Code;
  except
    Result := 0;
  end;
end;

// Команда и ответ; 0 - соединение потеряно (ошибка уже записана)
function UnixFtpCmd(AConn: TUnixFtpHandle; const ACommand: AnsiString;
  var AText: AnsiString): Integer;
var
  Line: AnsiString;
begin
  Result := 0;
  AText := '';
  if (AConn = nil) or (AConn.Ctrl = nil) then
  begin
    UnixFtpFail(UnixFtpErrAborted, AcpText('нет соединения'));
    Exit;
  end;
  try
    Line := ACommand + #13#10;
    if AConn.Ctrl.Write(Line[1], Length(Line)) <> Length(Line) then
    begin
      UnixFtpFail(UnixFtpErrAborted, AConn.Host + AcpText(': соединение разорвано'));
      Exit;
    end;
  except
    on Err: Exception do
    begin
      UnixFtpSocketFail(Err, AConn.Host);
      Exit;
    end;
  end;
  Result := UnixFtpReply(AConn.Ctrl, AText);
  if Result = 0 then
    UnixFtpFail(UnixFtpErrAborted, AConn.Host + AcpText(': соединение разорвано'));
end;

// Команда с ожидаемым ответом 2xx (ACodeClass = 2) или 3xx; иначе - ошибка
// 12003 с текстом ответа
function UnixFtpExpect(AConn: TUnixFtpHandle; const ACommand: AnsiString;
  ACodeClass: Integer): Boolean;
var
  Text: AnsiString;
  Code: Integer;
begin
  Code := UnixFtpCmd(AConn, ACommand, Text);
  Result := (Code div 100) = ACodeClass;
  if (Code <> 0) and not Result then
    UnixFtpFail(UnixFtpErrExtended, Text);
  if Result then
    UnixFtpResponse := Text;
end;

// Соединение данных: EPSV, иначе PASV; nil - ошибка записана
function UnixFtpOpenData(AConn: TUnixFtpHandle): TInetSocket;
var
  Text, Inner, DataHost: AnsiString;
  Code, OpenPos, ClosePos, PartIdx, DataPort: Integer;
  Parts: array[0..5] of Integer;
  Rest: AnsiString;
begin
  Result := nil;
  DataHost := AConn.Host;
  DataPort := 0;
  Code := UnixFtpCmd(AConn, 'EPSV', Text);
  if Code = 0 then
    Exit;
  if Code = 229 then
  begin
    // 229 Entering Extended Passive Mode (|||port|)
    OpenPos := Pos('(', Text);
    ClosePos := Pos(')', Text);
    if (OpenPos > 0) and (ClosePos > OpenPos) then
    begin
      Inner := Copy(Text, OpenPos + 1, ClosePos - OpenPos - 1);
      Inner := StringReplace(Inner, '|', ' ', [rfReplaceAll]);
      DataPort := StrToIntDef(Trim(Inner), 0);
    end;
  end;
  if DataPort = 0 then
  begin
    Code := UnixFtpCmd(AConn, 'PASV', Text);
    if Code = 0 then
      Exit;
    if Code <> 227 then
    begin
      UnixFtpFail(UnixFtpErrExtended, Text);
      Exit;
    end;
    // 227 Entering Passive Mode (h1,h2,h3,h4,p1,p2)
    OpenPos := Pos('(', Text);
    if OpenPos = 0 then
    begin
      // Без скобок: первые цифры после кода
      OpenPos := 4;
      while (OpenPos <= Length(Text)) and not (Text[OpenPos] in ['0'..'9']) do
        Inc(OpenPos);
      Dec(OpenPos);
    end;
    Rest := Copy(Text, OpenPos + 1, MaxInt);
    for PartIdx := 0 to 5 do
    begin
      Parts[PartIdx] := 0;
      while (Rest <> '') and (Rest[1] in ['0'..'9']) do
      begin
        Parts[PartIdx] := Parts[PartIdx] * 10 + Ord(Rest[1]) - 48;
        Delete(Rest, 1, 1);
      end;
      if Rest <> '' then
        Delete(Rest, 1, 1);
    end;
    DataPort := Parts[4] * 256 + Parts[5];
    // Адрес из ответа; 0.0.0.0 или частный адрес за NAT - адрес сервера
    if Parts[0] <> 0 then
      DataHost := Format('%d.%d.%d.%d', [Parts[0], Parts[1], Parts[2],
        Parts[3]]);
    if (DataHost <> AConn.Host) and ((Parts[0] = 10) or (Parts[0] = 127) or
       ((Parts[0] = 192) and (Parts[1] = 168)) or
       ((Parts[0] = 172) and (Parts[1] >= 16) and (Parts[1] <= 31))) then
      DataHost := AConn.Host;
  end;
  try
    Result := TInetSocket.Create(DataHost, DataPort, AConn.ConnectTimeout);
    Result.IOTimeout := AConn.IoTimeout;
  except
    on Err: Exception do
    begin
      Result := nil;
      UnixFtpSocketFail(Err, DataHost);
    end;
  end;
end;

// Всё из соединения данных до конца
function UnixFtpReadAll(ASock: TInetSocket): AnsiString;
var
  Buf: array[0..65535] of Byte;
  Got, OldLen: Integer;
begin
  Result := '';
  repeat
    try
      Got := ASock.Read(Buf, SizeOf(Buf));
    except
      Got := 0;
    end;
    if Got <= 0 then
      Break;
    OldLen := Length(Result);
    SetLength(Result, OldLen + Got);
    Move(Buf, Result[OldLen + 1], Got);
  until False;
end;

// Время из MLSD 'YYYYMMDDHHMMSS[.sss]' (UTC)
procedure UnixFtpMlsdTime(const AText: AnsiString; var ATime: Windows.FILETIME);
var
  Stamp: TDateTime;
begin
  if Length(AText) < 14 then
    Exit;
  try
    Stamp := EncodeDate(StrToInt(Copy(AText, 1, 4)), StrToInt(Copy(AText, 5, 2)),
      StrToInt(Copy(AText, 7, 2))) + EncodeTime(StrToInt(Copy(AText, 9, 2)),
      StrToInt(Copy(AText, 11, 2)), StrToInt(Copy(AText, 13, 2)), 0);
    UnixToFileTime(DateTimeToUnix(Stamp), ATime);
  except
  end;
end;

// Строка MLSD: 'type=file;size=12;modify=20240101120000; name'
function UnixFtpParseMlsd(const ALine: AnsiString;
  var AData: WIN32_FIND_DATAA): Boolean;
var
  SpacePos, SemiPos: Integer;
  Facts, Fact, FactName, FactValue, FileName: AnsiString;
  EqPos: Integer;
  Size: Int64;
begin
  Result := False;
  FillChar(AData, SizeOf(AData), 0);
  SpacePos := Pos(' ', ALine);
  if SpacePos = 0 then
    Exit;
  Facts := Copy(ALine, 1, SpacePos - 1);
  FileName := Copy(ALine, SpacePos + 1, MaxInt);
  if (FileName = '') or (FileName = '.') or (FileName = '..') then
    Exit;
  AData.dwFileAttributes := FILE_ATTRIBUTE_NORMAL;
  while Facts <> '' do
  begin
    SemiPos := Pos(';', Facts);
    if SemiPos = 0 then
      SemiPos := Length(Facts) + 1;
    Fact := Copy(Facts, 1, SemiPos - 1);
    Delete(Facts, 1, SemiPos);
    EqPos := Pos('=', Fact);
    if EqPos = 0 then
      Continue;
    FactName := LowerCase(Copy(Fact, 1, EqPos - 1));
    FactValue := Copy(Fact, EqPos + 1, MaxInt);
    if FactName = 'type' then
    begin
      FactValue := LowerCase(FactValue);
      if (FactValue = 'cdir') or (FactValue = 'pdir') then
        Exit;
      if FactValue = 'dir' then
        AData.dwFileAttributes := FILE_ATTRIBUTE_DIRECTORY;
    end
    else if FactName = 'size' then
    begin
      Size := StrToInt64Def(FactValue, 0);
      AData.nFileSizeHigh := DWORD(Size shr 32);
      AData.nFileSizeLow := DWORD(Size and $FFFFFFFF);
    end
    else if FactName = 'modify' then
      UnixFtpMlsdTime(FactValue, AData.ftLastWriteTime);
  end;
  StrPLCopy(AData.cFileName, FileName, High(AData.cFileName));
  Result := True;
end;

// Месяц 'Jan'..'Dec' -> 1..12, 0 - нет
function UnixFtpMonth(const AText: AnsiString): Integer;
const
  Months = 'janfebmaraprmayjunjulaugsepoctnovdec';
var
  MonthPos: Integer;
begin
  Result := 0;
  if Length(AText) <> 3 then
    Exit;
  MonthPos := Pos(LowerCase(AText), Months);
  if (MonthPos > 0) and ((MonthPos - 1) mod 3 = 0) then
    Result := (MonthPos - 1) div 3 + 1;
end;

// Строка LIST: формат ls ('drwxr-xr-x 2 u g 4096 Jan  1 12:00 name') или
// DOS ('01-01-24  12:00PM  <DIR>  name')
function UnixFtpParseList(const ALine: AnsiString;
  var AData: WIN32_FIND_DATAA): Boolean;
var
  Words: array[0..8] of AnsiString;
  WordStart: array[0..8] of Integer;
  WordCount, CharPos, Month, Day, Year, Hour, Minute: Integer;
  FileName, TimeText: AnsiString;
  Size: Int64;
  NowYear, NowMonth, NowDay: Word;
  Stamp: TDateTime;
  ArrowPos: Integer;
begin
  Result := False;
  Size := 0;
  FillChar(AData, SizeOf(AData), 0);
  // Слова строки: первые 8, остальное - имя
  WordCount := 0;
  CharPos := 1;
  while (WordCount < 9) and (CharPos <= Length(ALine)) do
  begin
    while (CharPos <= Length(ALine)) and (ALine[CharPos] = ' ') do
      Inc(CharPos);
    if CharPos > Length(ALine) then
      Break;
    WordStart[WordCount] := CharPos;
    while (CharPos <= Length(ALine)) and (ALine[CharPos] <> ' ') do
      Inc(CharPos);
    Words[WordCount] := Copy(ALine, WordStart[WordCount],
      CharPos - WordStart[WordCount]);
    Inc(WordCount);
  end;
  if WordCount < 4 then
    Exit;
  if (Length(Words[0]) >= 10) and (Words[0][1] in ['-', 'd', 'l']) and
     (WordCount >= 9) then
  begin
    // ls: права, ссылки, владелец, группа, размер, месяц, день, время/год
    FileName := Copy(ALine, WordStart[8], MaxInt);
    if Words[0][1] = 'l' then
    begin
      ArrowPos := Pos(' -> ', FileName);
      if ArrowPos > 0 then
        FileName := Copy(FileName, 1, ArrowPos - 1);
    end;
    if Words[0][1] = 'd' then
      AData.dwFileAttributes := FILE_ATTRIBUTE_DIRECTORY
    else
      AData.dwFileAttributes := FILE_ATTRIBUTE_NORMAL;
    Size := StrToInt64Def(Words[4], 0);
    Month := UnixFtpMonth(Words[5]);
    Day := StrToIntDef(Words[6], 1);
    TimeText := Words[7];
    DecodeDate(Now, NowYear, NowMonth, NowDay);
    Hour := 0;
    Minute := 0;
    if Pos(':', TimeText) > 0 then
    begin
      Year := NowYear;
      if Month > NowMonth then
        Dec(Year);
      Hour := StrToIntDef(Copy(TimeText, 1, Pos(':', TimeText) - 1), 0);
      Minute := StrToIntDef(Copy(TimeText, Pos(':', TimeText) + 1, 2), 0);
    end
    else
      Year := StrToIntDef(TimeText, NowYear);
    if (Month > 0) and (Day >= 1) and (Day <= 31) then
      try
        Stamp := EncodeDate(Year, Month, Day) + EncodeTime(Hour mod 24,
          Minute mod 60, 0, 0);
        // Время ls - местное время сервера: считаем его местным здесь
        // (GetLocalTimeOffset - минуты UTC минус местное)
        UnixToFileTime(DateTimeToUnix(Stamp) +
          Int64(GetLocalTimeOffset) * 60, AData.ftLastWriteTime);
      except
      end;
  end
  else if (Length(Words[0]) >= 8) and (Words[0][3] = '-') then
  begin
    // DOS: дата, время, <DIR> или размер, имя
    FileName := Copy(ALine, WordStart[3], MaxInt);
    if UpperCase(Words[2]) = '<DIR>' then
      AData.dwFileAttributes := FILE_ATTRIBUTE_DIRECTORY
    else
    begin
      AData.dwFileAttributes := FILE_ATTRIBUTE_NORMAL;
      Size := StrToInt64Def(Words[2], 0);
    end;
  end
  else
    Exit;
  if AData.dwFileAttributes = FILE_ATTRIBUTE_NORMAL then
  begin
    AData.nFileSizeHigh := DWORD(Size shr 32);
    AData.nFileSizeLow := DWORD(Size and $FFFFFFFF);
  end;
  if (FileName = '') or (FileName = '.') or (FileName = '..') then
    Exit;
  StrPLCopy(AData.cFileName, FileName, High(AData.cFileName));
  Result := True;
end;

function UnixFtpConn(AHandle: Pointer): TUnixFtpHandle;
begin
  Result := nil;
  if (AHandle <> nil) and (TObject(AHandle) is TUnixFtpHandle) and
     (TUnixFtpHandle(AHandle).Kind = ufkConnect) then
    Result := TUnixFtpHandle(AHandle)
  else
    UnixFtpFail(6, AcpText('неверный дескриптор'));  // ERROR_INVALID_HANDLE
end;

function Impl_InternetOpenA(AAgent: PAnsiChar; AAccessType: DWORD; AProxy, AProxyBypass: PAnsiChar; AFlags: DWORD): Pointer; stdcall; public name 'unidewin_InternetOpenA';
var
  Session: TUnixFtpHandle;
begin
  Session := TUnixFtpHandle.Create;
  Session.Kind := ufkSession;
  Session.ConnectTimeout := 20000;
  Session.IoTimeout := 20000;
  Result := Session;
end;

function Impl_InternetSetOptionA(AHandle: Pointer; AOption: DWORD; ABuffer: Pointer; ABufferLength: DWORD): BOOL; stdcall; public name 'unidewin_InternetSetOptionA';
begin
  Result := False;
  if (AHandle = nil) or (ABuffer = nil) or (ABufferLength < SizeOf(DWORD)) then
    Exit;
  case AOption of
    2: TUnixFtpHandle(AHandle).ConnectTimeout := PDWORD(ABuffer)^;
    5, 6: TUnixFtpHandle(AHandle).IoTimeout := PDWORD(ABuffer)^;
  end;
  Result := True;
end;

function Impl_InternetConnectA(ASession: Pointer; AServer: PAnsiChar; APort: Word; AUser, APassword: PAnsiChar; AService, AFlags: DWORD; AContext: DWORD): Pointer; stdcall; public name 'unidewin_InternetConnectA';
var
  Conn: TUnixFtpHandle;
  Text: AnsiString;
  Code: Integer;
begin
  Result := nil;
  if ASession = nil then
    Exit;
  Conn := TUnixFtpHandle.Create;
  Conn.Kind := ufkConnect;
  Conn.ConnectTimeout := TUnixFtpHandle(ASession).ConnectTimeout;
  Conn.IoTimeout := TUnixFtpHandle(ASession).IoTimeout;
  Conn.Host := AServer;
  try
    Conn.Ctrl := TInetSocket.Create(Conn.Host, APort, Conn.ConnectTimeout);
    Conn.Ctrl.IOTimeout := Conn.IoTimeout;
  except
    on Err: Exception do
    begin
      UnixFtpSocketFail(Err, Conn.Host);
      UnixFtpFree(Conn);
      Exit;
    end;
  end;
  // Приветствие, вход
  Code := UnixFtpReply(Conn.Ctrl, Text);
  if Code div 100 <> 2 then
  begin
    if Code = 0 then
      UnixFtpFail(UnixFtpErrAborted, Conn.Host + AcpText(': соединение разорвано'))
    else
      UnixFtpFail(UnixFtpErrExtended, Text);
    UnixFtpFree(Conn);
    Exit;
  end;
  Code := UnixFtpCmd(Conn, 'USER ' + AnsiString(AUser), Text);
  if Code = 331 then
    Code := UnixFtpCmd(Conn, 'PASS ' + AnsiString(APassword), Text);
  if Code div 100 <> 2 then
  begin
    if Code <> 0 then
      UnixFtpFail(UnixFtpErrExtended, Text);
    UnixFtpFree(Conn);
    Exit;
  end;
  UnixFtpResponse := Text;
  // Двоичный режим - для всех передач
  UnixFtpCmd(Conn, 'TYPE I', Text);
  Result := Conn;
end;

function Impl_InternetCloseHandle(AHandle: Pointer): BOOL; stdcall; public name 'unidewin_InternetCloseHandle';
var
  Handle: TUnixFtpHandle;
  Text: AnsiString;
begin
  Result := False;
  if AHandle = nil then
    Exit;
  Handle := TUnixFtpHandle(AHandle);
  case Handle.Kind of
    ufkConnect:
      if Handle.Ctrl <> nil then
        try
          UnixFtpCmd(Handle, 'QUIT', Text);
        except
        end;
    ufkFile:
      begin
        // Конец передачи: закрыть данные, прочитать ответ (226)
        FreeAndNil(Handle.Data);
        if (Handle.Owner <> nil) and (Handle.Owner.Ctrl <> nil) then
          UnixFtpReply(Handle.Owner.Ctrl, Text);
      end;
  end;
  UnixFtpFree(Handle);
  Result := True;
end;

function Impl_InternetGetLastResponseInfoA(var AError: DWORD; ABuffer: PAnsiChar; var ALength: DWORD): BOOL; stdcall; public name 'unidewin_InternetGetLastResponseInfoA';
var
  Text: AnsiString;
begin
  Result := False;
  AError := 0;
  Text := UnixFtpResponse;
  if Text <> '' then
    AError := StrToIntDef(Copy(Text, 1, 3), 0);
  if (ABuffer = nil) or (ALength <= DWORD(Length(Text))) then
  begin
    ALength := Length(Text) + 1;
    UnixLastError := ERROR_INSUFFICIENT_BUFFER;
    Exit;
  end;
  if Text <> '' then
    Move(Text[1], ABuffer^, Length(Text));
  ABuffer[Length(Text)] := #0;
  ALength := Length(Text);
  Result := True;
end;

function Impl_FtpGetCurrentDirectoryA(AConnect: Pointer; ADir: PAnsiChar; var ALength: DWORD): BOOL; stdcall; public name 'unidewin_FtpGetCurrentDirectoryA';
var
  Conn: TUnixFtpHandle;
  Text, DirText: AnsiString;
  Code, QuotePos, CharPos: Integer;
begin
  Result := False;
  Conn := UnixFtpConn(AConnect);
  if Conn = nil then
    Exit;
  Code := UnixFtpCmd(Conn, 'PWD', Text);
  if Code = 0 then
    Exit;
  if Code <> 257 then
  begin
    UnixFtpFail(UnixFtpErrExtended, Text);
    Exit;
  end;
  // 257 "/path" ... ('""' внутри - одна кавычка)
  DirText := '';
  QuotePos := Pos('"', Text);
  if QuotePos > 0 then
  begin
    CharPos := QuotePos + 1;
    while CharPos <= Length(Text) do
    begin
      if Text[CharPos] = '"' then
      begin
        if (CharPos < Length(Text)) and (Text[CharPos + 1] = '"') then
        begin
          DirText := DirText + '"';
          Inc(CharPos, 2);
          Continue;
        end;
        Break;
      end;
      DirText := DirText + Text[CharPos];
      Inc(CharPos);
    end;
  end;
  if (ADir = nil) or (ALength <= DWORD(Length(DirText))) then
  begin
    ALength := Length(DirText) + 1;
    UnixLastError := ERROR_INSUFFICIENT_BUFFER;
    Exit;
  end;
  StrPLCopy(ADir, DirText, ALength - 1);
  ALength := Length(DirText);
  Result := True;
end;

function Impl_FtpSetCurrentDirectoryA(AConnect: Pointer; ADir: PAnsiChar): BOOL; stdcall; public name 'unidewin_FtpSetCurrentDirectoryA';
begin
  Result := (UnixFtpConn(AConnect) <> nil) and
    UnixFtpExpect(UnixFtpConn(AConnect), 'CWD ' + AnsiString(ADir), 2);
end;

function Impl_FtpCreateDirectoryA(AConnect: Pointer; ADir: PAnsiChar): BOOL; stdcall; public name 'unidewin_FtpCreateDirectoryA';
begin
  Result := (UnixFtpConn(AConnect) <> nil) and
    UnixFtpExpect(UnixFtpConn(AConnect), 'MKD ' + AnsiString(ADir), 2);
end;

function Impl_FtpRemoveDirectoryA(AConnect: Pointer; ADir: PAnsiChar): BOOL; stdcall; public name 'unidewin_FtpRemoveDirectoryA';
begin
  Result := (UnixFtpConn(AConnect) <> nil) and
    UnixFtpExpect(UnixFtpConn(AConnect), 'RMD ' + AnsiString(ADir), 2);
end;

function Impl_FtpDeleteFileA(AConnect: Pointer; AFileName: PAnsiChar): BOOL; stdcall; public name 'unidewin_FtpDeleteFileA';
begin
  Result := (UnixFtpConn(AConnect) <> nil) and
    UnixFtpExpect(UnixFtpConn(AConnect), 'DELE ' + AnsiString(AFileName), 2);
end;

function Impl_FtpRenameFileA(AConnect: Pointer; AExisting, ANew: PAnsiChar): BOOL; stdcall; public name 'unidewin_FtpRenameFileA';
var
  Conn: TUnixFtpHandle;
begin
  Conn := UnixFtpConn(AConnect);
  Result := (Conn <> nil) and
    UnixFtpExpect(Conn, 'RNFR ' + AnsiString(AExisting), 3) and
    UnixFtpExpect(Conn, 'RNTO ' + AnsiString(ANew), 2);
end;

// Передача: соединение данных + команда (RETR, STOR, LIST, MLSD) с
// ответом 1xx; nil - ошибка записана
function UnixFtpStartTransfer(AConn: TUnixFtpHandle;
  const ACommand: AnsiString; var ACode: Integer): TInetSocket;
var
  Text: AnsiString;
begin
  Result := UnixFtpOpenData(AConn);
  ACode := 0;
  if Result = nil then
    Exit;
  ACode := UnixFtpCmd(AConn, ACommand, Text);
  if ACode div 100 <> 1 then
  begin
    if ACode <> 0 then
      UnixFtpFail(UnixFtpErrExtended, Text);
    FreeAndNil(Result);
  end;
end;

function Impl_FtpFindFirstFileA(AConnect: Pointer; ASearch: PAnsiChar; var AFindData; AFlags: DWORD; AContext: DWORD): Pointer; stdcall; public name 'unidewin_FtpFindFirstFileA';
var
  Conn, Find: TUnixFtpHandle;
  DataSock: TInetSocket;
  Listing, Line, Text: AnsiString;
  Code, LinePos, LineEnd: Integer;
  UseMlsd: Boolean;
  Entry: WIN32_FIND_DATAA;
begin
  Result := nil;
  Conn := UnixFtpConn(AConnect);
  if Conn = nil then
    Exit;
  UseMlsd := True;
  DataSock := UnixFtpStartTransfer(Conn, 'MLSD', Code);
  if (DataSock = nil) and (Code div 100 = 5) then
  begin
    // Сервер без MLSD - LIST
    UseMlsd := False;
    DataSock := UnixFtpStartTransfer(Conn, 'LIST', Code);
  end;
  if DataSock = nil then
    Exit;
  Listing := UnixFtpReadAll(DataSock);
  DataSock.Free;
  Code := UnixFtpReply(Conn.Ctrl, Text);
  if Code div 100 <> 2 then
  begin
    if Code = 0 then
      UnixFtpFail(UnixFtpErrAborted, Conn.Host + AcpText(': соединение разорвано'))
    else
      UnixFtpFail(UnixFtpErrExtended, Text);
    Exit;
  end;
  Find := TUnixFtpHandle.Create;
  Find.Kind := ufkFind;
  LinePos := 1;
  while LinePos <= Length(Listing) do
  begin
    LineEnd := LinePos;
    while (LineEnd <= Length(Listing)) and (Listing[LineEnd] <> #10) do
      Inc(LineEnd);
    Line := Copy(Listing, LinePos, LineEnd - LinePos);
    LinePos := LineEnd + 1;
    if (Line <> '') and (Line[Length(Line)] = #13) then
      SetLength(Line, Length(Line) - 1);
    if Line = '' then
      Continue;
    if (UseMlsd and UnixFtpParseMlsd(Line, Entry)) or
       (not UseMlsd and UnixFtpParseList(Line, Entry)) then
    begin
      SetLength(Find.Found, Length(Find.Found) + 1);
      Find.Found[High(Find.Found)] := Entry;
    end;
  end;
  if Length(Find.Found) = 0 then
  begin
    UnixFtpFree(Find);
    UnixFtpFail(UnixFtpErrNoMoreFiles, '');
    Exit;
  end;
  WIN32_FIND_DATAA(AFindData) := Find.Found[0];
  Find.FoundIdx := 1;
  Result := Find;
end;

function Impl_InternetFindNextFileA(AFind: Pointer; var AFindData): BOOL; stdcall; public name 'unidewin_InternetFindNextFileA';
var
  Find: TUnixFtpHandle;
begin
  Result := False;
  if AFind = nil then
    Exit;
  Find := TUnixFtpHandle(AFind);
  if Find.FoundIdx > High(Find.Found) then
  begin
    UnixFtpFail(UnixFtpErrNoMoreFiles, '');
    Exit;
  end;
  WIN32_FIND_DATAA(AFindData) := Find.Found[Find.FoundIdx];
  Inc(Find.FoundIdx);
  Result := True;
end;

function Impl_FtpOpenFileA(AConnect: Pointer; AFileName: PAnsiChar; AAccess, AFlags, AContext: DWORD): Pointer; stdcall; public name 'unidewin_FtpOpenFileA';
var
  Conn, FileHandle: TUnixFtpHandle;
  DataSock: TInetSocket;
  Code: Integer;
  Command: AnsiString;
begin
  Result := nil;
  Conn := UnixFtpConn(AConnect);
  if Conn = nil then
    Exit;
  if AAccess and GENERIC_WRITE <> 0 then
    Command := 'STOR '
  else
    Command := 'RETR ';
  DataSock := UnixFtpStartTransfer(Conn, Command + AnsiString(AFileName), Code);
  if DataSock = nil then
    Exit;
  FileHandle := TUnixFtpHandle.Create;
  FileHandle.Kind := ufkFile;
  FileHandle.Data := DataSock;
  FileHandle.Owner := Conn;
  Result := FileHandle;
end;

function Impl_InternetReadFile(AFile: Pointer; ABuffer: Pointer; AToRead: DWORD; var ARead: DWORD): BOOL; stdcall; public name 'unidewin_InternetReadFile';
var
  Got: Integer;
begin
  Result := False;
  ARead := 0;
  if (AFile = nil) or (TUnixFtpHandle(AFile).Data = nil) then
    Exit;
  try
    Got := TUnixFtpHandle(AFile).Data.Read(ABuffer^, AToRead);
  except
    on Err: Exception do
    begin
      UnixFtpSocketFail(Err, TUnixFtpHandle(AFile).Owner.Host);
      Exit;
    end;
  end;
  // 0 - конец файла (сервер закрыл соединение данных)
  if Got < 0 then
  begin
    UnixFtpFail(UnixFtpErrAborted, AcpText('соединение данных разорвано'));
    Exit;
  end;
  ARead := Got;
  Result := True;
end;

function Impl_InternetWriteFile(AFile: Pointer; ABuffer: Pointer; AToWrite: DWORD; var AWritten: DWORD): BOOL; stdcall; public name 'unidewin_InternetWriteFile';
var
  Sent, Total: Integer;
begin
  Result := False;
  AWritten := 0;
  if (AFile = nil) or (TUnixFtpHandle(AFile).Data = nil) then
    Exit;
  Total := 0;
  try
    while Total < Integer(AToWrite) do
    begin
      Sent := TUnixFtpHandle(AFile).Data.Write(PByte(ABuffer)[Total],
        Integer(AToWrite) - Total);
      if Sent <= 0 then
      begin
        UnixFtpFail(UnixFtpErrAborted, AcpText('соединение данных разорвано'));
        Exit;
      end;
      Inc(Total, Sent);
    end;
  except
    on Err: Exception do
    begin
      UnixFtpSocketFail(Err, TUnixFtpHandle(AFile).Owner.Host);
      Exit;
    end;
  end;
  AWritten := Total;
  Result := True;
end;

// Текст ошибки: коды WinInet выше (ASource - модуль wininet.dll или
// система); остальное - 0 (вызывающий покажет номер)
function Impl_FormatMessageA(AFlags: DWORD; ASource: Pointer; AMessageId: DWORD; ALanguageId: DWORD; ABuffer: PChar; ASize: DWORD; AArguments: Pointer): DWORD; stdcall; public name 'unidewin_FormatMessageA';
var
  Text: AnsiString;
begin
  Result := 0;
  case AMessageId of
    UnixFtpErrTimeout: Text := 'время ожидания вышло';
    UnixFtpErrNameNotResolved: Text := 'имя сервера не найдено';
    UnixFtpErrCannotConnect: Text := 'не удалось соединиться с сервером';
    UnixFtpErrAborted: Text := 'соединение разорвано';
    UnixFtpErrNoMoreFiles: Text := 'файлов больше нет';
  else
    Exit;
  end;
  // Файл - cp1251, строки программы - UTF-8; в конце - текст сети
  Text := AcpText(Text);
  if UnixFtpResponse <> '' then
    Text := Text + ' - ' + UnixFtpResponse;
  if (AFlags and FORMAT_MESSAGE_ALLOCATE_BUFFER <> 0) or (ABuffer = nil) or
     (ASize <= DWORD(Length(Text))) then
    Exit;
  Move(Text[1], ABuffer^, Length(Text));
  ABuffer[Length(Text)] := #0;
  Result := Length(Text);
end;
