// unIDE, Linux build: WinAPI calls implemented for real (not stubs):
// code pages, text output with ANSI (CP_ACP) strings, time, files,
// environment, character case, a few window functions.
// Rule as in Windows: *A text functions take CP_ACP text (1251 here),
// *W take UTF-16; LCL under gtk2 draws UTF-8.

{$I wincp.inc}

const
  UnixAcp = 1251;
  UnixOemCp = 866;

threadvar
  UnixLastError: DWORD;

// --- code pages ---

function CpHighOf(ACodePage: UINT; AByte: Byte): Word;
begin
  case ACodePage of
    1251: Result := Cp1251High[AByte];
    866: Result := Cp866High[AByte];
    1252: Result := Cp1252High[AByte];
  else
    Result := AByte; // 28591 and unknown: Latin-1
  end;
end;

function CpRealOf(ACodePage: UINT): UINT;
begin
  case ACodePage of
    CP_ACP, 3: Result := UnixAcp;
    CP_OEMCP: Result := UnixOemCp;
  else
    Result := ACodePage;
  end;
end;

// Decodes one UTF-8 sequence at ASrc (ALeft bytes); returns code point,
// AUsed - bytes taken. Bad bytes: U+FFFD, 1 byte
function Utf8Next(ASrc: PByte; ALeft: Integer; var AUsed: Integer): Cardinal;
var
  Lead: Byte;
  Need, Idx: Integer;
begin
  Lead := ASrc^;
  AUsed := 1;
  if Lead < $80 then
  begin
    Result := Lead;
    Exit;
  end;
  if (Lead and $E0) = $C0 then
  begin
    Need := 1;
    Result := Lead and $1F;
  end
  else if (Lead and $F0) = $E0 then
  begin
    Need := 2;
    Result := Lead and $0F;
  end
  else if (Lead and $F8) = $F0 then
  begin
    Need := 3;
    Result := Lead and $07;
  end
  else
  begin
    Result := $FFFD;
    Exit;
  end;
  if Need >= ALeft then
  begin
    Result := $FFFD;
    Exit;
  end;
  for Idx := 1 to Need do
  begin
    if (PByte(ASrc + Idx)^ and $C0) <> $80 then
    begin
      Result := $FFFD;
      Exit;
    end;
    Result := (Result shl 6) or (PByte(ASrc + Idx)^ and $3F);
  end;
  AUsed := Need + 1;
end;

function Impl_MultiByteToWideChar(ACodePage: UINT; AFlags: DWORD; AMulti: PAnsiChar; AMultiLen: Integer; AWide: PWideChar; AWideLen: Integer): Integer; stdcall; public name 'unidewin_MultiByteToWideChar';
var
  RealCp: UINT;
  SrcPos, OutCount, Used: Integer;
  Code: Cardinal;
  Src: PByte;

  procedure Put(AChar: Word);
  begin
    if (AWideLen > 0) and (AWide <> nil) then
    begin
      if OutCount >= AWideLen then
      begin
        OutCount := -1;
        Exit;
      end;
      AWide[OutCount] := WideChar(AChar);
    end;
    Inc(OutCount);
  end;

begin
  Result := 0;
  if AMulti = nil then
    Exit;
  if AMultiLen < 0 then
    AMultiLen := StrLen(AMulti) + 1;
  RealCp := CpRealOf(ACodePage);
  Src := PByte(AMulti);
  SrcPos := 0;
  OutCount := 0;
  while (SrcPos < AMultiLen) and (OutCount >= 0) do
  begin
    if RealCp = CP_UTF8 then
    begin
      Code := Utf8Next(Src + SrcPos, AMultiLen - SrcPos, Used);
      Inc(SrcPos, Used);
      if Code >= $10000 then
      begin
        Dec(Code, $10000);
        Put($D800 or (Code shr 10));
        if OutCount >= 0 then
          Put($DC00 or (Code and $3FF));
      end
      else
        Put(Word(Code));
    end
    else
    begin
      if Src[SrcPos] < $80 then
        Put(Src[SrcPos])
      else
        Put(CpHighOf(RealCp, Src[SrcPos]));
      Inc(SrcPos);
    end;
  end;
  if OutCount < 0 then
  begin
    UnixLastError := ERROR_INSUFFICIENT_BUFFER;
    Exit;
  end;
  Result := OutCount;
end;

function Impl_WideCharToMultiByte(ACodePage: UINT; AFlags: DWORD; AWide: PWideChar; AWideLen: Integer; AMulti: PAnsiChar; AMultiLen: Integer; ADefault: PAnsiChar; AUsedDefault: Pointer): Integer; stdcall; public name 'unidewin_WideCharToMultiByte';
var
  RealCp: UINT;
  SrcPos, OutCount, ByteIdx, Found: Integer;
  Code: Cardinal;
  Bytes: array[0..3] of Byte;
  ByteCount: Integer;
  DefChar: Byte;

  procedure PutBytes;
  var
    PutIdx: Integer;
  begin
    if (AMultiLen > 0) and (AMulti <> nil) then
    begin
      if OutCount + ByteCount > AMultiLen then
      begin
        OutCount := -1;
        Exit;
      end;
      for PutIdx := 0 to ByteCount - 1 do
        PByte(AMulti)[OutCount + PutIdx] := Bytes[PutIdx];
    end;
    Inc(OutCount, ByteCount);
  end;

begin
  Result := 0;
  if AWide = nil then
    Exit;
  if AWideLen < 0 then
  begin
    AWideLen := 0;
    while AWide[AWideLen] <> #0 do
      Inc(AWideLen);
    Inc(AWideLen);
  end;
  RealCp := CpRealOf(ACodePage);
  DefChar := Ord('?');
  if ADefault <> nil then
    DefChar := Byte(ADefault^);
  if AUsedDefault <> nil then
    PLongBool(AUsedDefault)^ := False;
  SrcPos := 0;
  OutCount := 0;
  while (SrcPos < AWideLen) and (OutCount >= 0) do
  begin
    Code := Word(AWide[SrcPos]);
    Inc(SrcPos);
    if (Code >= $D800) and (Code <= $DBFF) and (SrcPos < AWideLen) and
       (Word(AWide[SrcPos]) >= $DC00) and (Word(AWide[SrcPos]) <= $DFFF) then
    begin
      Code := $10000 + ((Code - $D800) shl 10) + (Word(AWide[SrcPos]) - $DC00);
      Inc(SrcPos);
    end;
    if RealCp = CP_UTF8 then
    begin
      if Code < $80 then
      begin
        Bytes[0] := Code;
        ByteCount := 1;
      end
      else if Code < $800 then
      begin
        Bytes[0] := $C0 or (Code shr 6);
        Bytes[1] := $80 or (Code and $3F);
        ByteCount := 2;
      end
      else if Code < $10000 then
      begin
        Bytes[0] := $E0 or (Code shr 12);
        Bytes[1] := $80 or ((Code shr 6) and $3F);
        Bytes[2] := $80 or (Code and $3F);
        ByteCount := 3;
      end
      else
      begin
        Bytes[0] := $F0 or (Code shr 18);
        Bytes[1] := $80 or ((Code shr 12) and $3F);
        Bytes[2] := $80 or ((Code shr 6) and $3F);
        Bytes[3] := $80 or (Code and $3F);
        ByteCount := 4;
      end;
    end
    else
    begin
      ByteCount := 1;
      if Code < $80 then
        Bytes[0] := Code
      else
      begin
        Found := -1;
        for ByteIdx := $80 to $FF do
          if CpHighOf(RealCp, ByteIdx) = Code then
          begin
            Found := ByteIdx;
            Break;
          end;
        if Found < 0 then
        begin
          Bytes[0] := DefChar;
          if AUsedDefault <> nil then
            PLongBool(AUsedDefault)^ := True;
        end
        else
          Bytes[0] := Found;
      end;
    end;
    PutBytes;
  end;
  if OutCount < 0 then
  begin
    UnixLastError := ERROR_INSUFFICIENT_BUFFER;
    Exit;
  end;
  Result := OutCount;
end;

function Impl_GetACP: UINT; stdcall; public name 'unidewin_GetACP';
begin
  Result := UnixAcp;
end;

function Impl_GetOEMCP: UINT; stdcall; public name 'unidewin_GetOEMCP';
begin
  Result := UnixOemCp;
end;

// ANSI (CP_ACP) text -> UTF-8 for LCL
function AcpToUtf8(AText: PAnsiChar; ACount: Integer): AnsiString;
var
  Wide: UnicodeString;
  WideLen: Integer;
begin
  Result := '';
  if (AText = nil) or (ACount = 0) then
    Exit;
  if ACount < 0 then
    ACount := StrLen(AText);
  SetLength(Wide, ACount);
  WideLen := Impl_MultiByteToWideChar(CP_ACP, 0, AText, ACount, PWideChar(Wide), ACount);
  SetLength(Wide, WideLen);
  Result := UTF8Encode(Wide);
end;

function WideToUtf8(AText: PWideChar; ACount: Integer): AnsiString;
var
  Wide: UnicodeString;
begin
  Result := '';
  if AText = nil then
    Exit;
  if ACount < 0 then
  begin
    ACount := 0;
    while AText[ACount] <> #0 do
      Inc(ACount);
  end;
  SetString(Wide, AText, ACount);
  Result := UTF8Encode(Wide);
end;

function Utf8OfWide(const AText: UnicodeString): AnsiString;
begin
  Result := UTF8Encode(AText);
end;

// Copies UTF-8 text into a UTF-16 buffer of AMax chars (with #0);
// returns chars written without #0
function PutWide(const AUtf8: AnsiString; ABuffer: PWideChar; AMax: Integer): Integer;
var
  Wide: UnicodeString;
begin
  Wide := UTF8Decode(AUtf8);
  Result := Length(Wide);
  if (ABuffer = nil) or (AMax <= 0) then
    Exit;
  if Result > AMax - 1 then
    Result := AMax - 1;
  if Result > 0 then
    Move(PWideChar(Wide)^, ABuffer^, Result * SizeOf(WideChar));
  ABuffer[Result] := #0;
end;

function PutAnsi(const AText: AnsiString; ABuffer: PAnsiChar; AMax: Integer): Integer;
begin
  Result := Length(AText);
  if (ABuffer = nil) or (AMax <= 0) then
    Exit;
  if Result > AMax - 1 then
    Result := AMax - 1;
  if Result > 0 then
    Move(PAnsiChar(AText)^, ABuffer^, Result);
  ABuffer[Result] := #0;
end;

// --- text output ---

function Impl_TextOutA(_para1:HDC; _para2:longint; _para3:longint; _para4:LPCSTR; _para5:longint): WINBOOL; stdcall; public name 'unidewin_TextOutA';
var
  Utf8: AnsiString;
begin
  Utf8 := AcpToUtf8(_para4, _para5);
  Result := LCLIntf.TextOut(_para1, _para2, _para3, PChar(Utf8), Length(Utf8));
end;

function Impl_DrawTextA(hDC:HDC; lpString:LPCSTR; nCount:longint; lpRect:LPRECT; uFormat:UINT): longint; stdcall; public name 'unidewin_DrawTextA';
var
  Utf8: AnsiString;
begin
  Utf8 := AcpToUtf8(lpString, nCount);
  Result := LCLIntf.DrawText(hDC, PChar(Utf8), Length(Utf8), lpRect^, uFormat);
end;

function Impl_DrawTextW(ADC: HDC; AText: PWideChar; ACount: Integer; var ARect: TRect; AFormat: UINT): Integer; stdcall; public name 'unidewin_DrawTextW';
var
  Utf8: AnsiString;
begin
  Utf8 := WideToUtf8(AText, ACount);
  Result := LCLIntf.DrawText(ADC, PChar(Utf8), Length(Utf8), ARect, AFormat);
end;

function Impl_GetTextExtentPoint32A(_para1:HDC; _para2:LPCSTR; _para3:longint; _para4:LPSIZE): WINBOOL; stdcall; public name 'unidewin_GetTextExtentPoint32A';
var
  Utf8: AnsiString;
begin
  Utf8 := AcpToUtf8(_para2, _para3);
  Result := LCLIntf.GetTextExtentPoint32(_para1, PChar(Utf8), Length(Utf8), _para4^);
end;

function Impl_GetTextExtentPoint32W(ADC: HDC; AText: PWideChar; ACount: Integer; var ASize): BOOL; stdcall; public name 'unidewin_GetTextExtentPoint32W';
var
  Utf8: AnsiString;
begin
  Utf8 := WideToUtf8(AText, ACount);
  Result := LCLIntf.GetTextExtentPoint32(ADC, PChar(Utf8), Length(Utf8), Types.TSize(ASize));
end;

// Fit/Dx per ANSI char: extent of each prefix (one call per char)
function Impl_GetTextExtentExPointA(DC: HDC; Str: PChar; Count, MaxExtent: Integer; Fit: PInteger; Dx: PInteger; var Size: Types.TSize): BOOL; stdcall; public name 'unidewin_GetTextExtentExPointA';
var
  Utf8: AnsiString;
  CharIdx, FitCount: Integer;
  PartSize: Types.TSize;
begin
  Utf8 := AcpToUtf8(Str, Count);
  Result := LCLIntf.GetTextExtentPoint32(DC, PChar(Utf8), Length(Utf8), Size);
  if (Fit = nil) and (Dx = nil) then
    Exit;
  FitCount := 0;
  for CharIdx := 1 to Count do
  begin
    Utf8 := AcpToUtf8(Str, CharIdx);
    LCLIntf.GetTextExtentPoint32(DC, PChar(Utf8), Length(Utf8), PartSize);
    if (Fit <> nil) and (PartSize.cx > MaxExtent) then
      Break;
    if Dx <> nil then
      PInteger(Dx + CharIdx - 1)^ := PartSize.cx;
    FitCount := CharIdx;
  end;
  if Fit <> nil then
    Fit^ := FitCount;
end;

function Impl_ExtTextOutW(ADC: HDC; AX, AY: Integer; AOptions: UINT; ARect: PRect; AStr: PWideChar; ACount: UINT; ADx: PInteger): BOOL; stdcall; public name 'unidewin_ExtTextOutW';
var
  Utf8: AnsiString;
begin
  Utf8 := WideToUtf8(AStr, ACount);
  Result := LCLIntf.ExtTextOut(ADC, AX, AY, AOptions, ARect, PChar(Utf8), Length(Utf8), ADx);
end;

// Tabs: one stop step (ATabCount = 1) or a list; ATabOrigin - X of tab 0
function TabNextX(APosX, ATabOrigin, ATabCount: Integer; ATabs: PInteger; ACharW: Integer): Integer;
var
  TabIdx, Step: Integer;
begin
  if (ATabCount <= 0) or (ATabs = nil) then
    Step := ACharW * 8
  else if ATabCount = 1 then
    Step := ATabs^
  else
  begin
    for TabIdx := 0 to ATabCount - 1 do
      if ATabOrigin + PInteger(ATabs + TabIdx)^ > APosX then
      begin
        Result := ATabOrigin + PInteger(ATabs + TabIdx)^;
        Exit;
      end;
    Step := PInteger(ATabs + ATabCount - 1)^;
  end;
  if Step <= 0 then
    Step := ACharW * 8;
  Result := ATabOrigin + ((APosX - ATabOrigin) div Step + 1) * Step;
end;

// Draws (ADraw) or measures text with tabs; returns width, AHeight - height
function TabbedRun(ADC: HDC; AX, AY: Integer; AText: PAnsiChar; ACount, ATabCount: Integer; ATabs: PInteger; ATabOrigin: Integer; ADraw: Boolean; var AHeight: Integer): Integer;
var
  PosX, PartStart, CharIdx: Integer;
  Utf8: AnsiString;
  PartSize: Types.TSize;
  SpaceSize: Types.TSize;

  procedure Flush(AUpTo: Integer);
  begin
    if AUpTo <= PartStart then
      Exit;
    Utf8 := AcpToUtf8(AText + PartStart, AUpTo - PartStart);
    LCLIntf.GetTextExtentPoint32(ADC, PChar(Utf8), Length(Utf8), PartSize);
    if ADraw then
      LCLIntf.TextOut(ADC, PosX, AY, PChar(Utf8), Length(Utf8));
    Inc(PosX, PartSize.cx);
    if PartSize.cy > AHeight then
      AHeight := PartSize.cy;
  end;

begin
  PosX := AX;
  AHeight := 0;
  if ACount < 0 then
    ACount := StrLen(AText);
  LCLIntf.GetTextExtentPoint32(ADC, ' ', 1, SpaceSize);
  if SpaceSize.cy > AHeight then
    AHeight := SpaceSize.cy;
  PartStart := 0;
  for CharIdx := 0 to ACount - 1 do
    if AText[CharIdx] = #9 then
    begin
      Flush(CharIdx);
      PosX := TabNextX(PosX, ATabOrigin, ATabCount, ATabs, SpaceSize.cx);
      PartStart := CharIdx + 1;
    end;
  Flush(ACount);
  Result := PosX - AX;
end;

function Impl_TabbedTextOutA(hDC:HDC; X:longint; Y:longint; lpString:LPCSTR; nCount:longint; nTabPositions:longint; lpnTabStopPositions:LPINT; nTabOrigin:longint): LONG; stdcall; public name 'unidewin_TabbedTextOutA';
var
  TextHeight, TextWidth: Integer;
begin
  TextWidth := TabbedRun(hDC, X, Y, lpString, nCount, nTabPositions, PInteger(lpnTabStopPositions), nTabOrigin, True, TextHeight);
  Result := (TextHeight shl 16) or (TextWidth and $FFFF);
end;

function Impl_GetTabbedTextExtentA(hDC:HDC; lpString:LPCSTR; nCount:longint; nTabPositions:longint; lpnTabStopPositions:LPINT): DWORD; stdcall; public name 'unidewin_GetTabbedTextExtentA';
var
  TextHeight, TextWidth: Integer;
begin
  TextWidth := TabbedRun(hDC, 0, 0, lpString, nCount, nTabPositions, PInteger(lpnTabStopPositions), 0, False, TextHeight);
  Result := (DWORD(TextHeight) shl 16) or DWORD(TextWidth and $FFFF);
end;

function Impl_MulDiv(nNumber:longint; nNumerator:longint; nDenominator:longint): longint; stdcall; public name 'unidewin_MulDiv';
begin
  if nDenominator = 0 then
    Result := -1
  else
    Result := (Int64(nNumber) * nNumerator + nDenominator div 2) div nDenominator;
end;

// PATCOPY with the brush selected into the DC, BLACKNESS, WHITENESS
function Impl_PatBlt(_para1:HDC; _para2:longint; _para3:longint; _para4:longint; _para5:longint; _para6:DWORD): WINBOOL; stdcall; public name 'unidewin_PatBlt';
var
  FillBox: TRect;
  Brush: HBRUSH;
  OwnBrush: Boolean;
begin
  FillBox := Rect(_para2, _para3, _para2 + _para4, _para3 + _para5);
  OwnBrush := False;
  if _para6 = BLACKNESS then
  begin
    Brush := LCLIntf.CreateSolidBrush(0);
    OwnBrush := True;
  end
  else if _para6 = WHITENESS then
  begin
    Brush := LCLIntf.CreateSolidBrush($FFFFFF);
    OwnBrush := True;
  end
  else
    Brush := LCLIntf.GetCurrentObject(_para1, OBJ_BRUSH);
  Result := LCLIntf.FillRect(_para1, FillBox, Brush);
  if OwnBrush then
    LCLIntf.DeleteObject(Brush);
end;

function Impl_Polygon(_para1:HDC; _para2:LPPOINT; _para3:longint): WINBOOL; stdcall; public name 'unidewin_Polygon';
begin
  Result := LCLIntf.Polygon(_para1, PPoint(_para2), _para3, False);
end;

function Impl_GdiFlush: WINBOOL; stdcall; public name 'unidewin_GdiFlush';
begin
  Result := True;
end;

function Impl_MessageBeep(uType:UINT): WINBOOL; stdcall; public name 'unidewin_MessageBeep';
begin
  SysUtils.Beep;
  Result := True;
end;

function Impl_MessageBoxW(AWnd: HWND; AText, ACaption: PWideChar; AType: UINT): Integer; stdcall; public name 'unidewin_MessageBoxW';
var
  Utf8Text, Utf8Caption: AnsiString;
begin
  Utf8Text := WideToUtf8(AText, -1);
  Utf8Caption := WideToUtf8(ACaption, -1);
  Result := LCLIntf.MessageBox(AWnd, PChar(Utf8Text), PChar(Utf8Caption), AType);
end;

// --- time, process ---

function Impl_GetTickCount: DWORD; stdcall; public name 'unidewin_GetTickCount';
begin
  Result := DWORD(SysUtils.GetTickCount64);
end;

function Impl_QueryPerformanceCounter(lpPerformanceCount:PLARGE_INTEGER): WINBOOL; stdcall; public name 'unidewin_QueryPerformanceCounter';
var
  TimeVal: BaseUnix.TTimeVal;
begin
  fpgettimeofday(@TimeVal, nil);
  PInt64(lpPerformanceCount)^ := Int64(TimeVal.tv_sec) * 1000000 + TimeVal.tv_usec;
  Result := True;
end;

function Impl_QueryPerformanceFrequency(lpFrequency:PLARGE_INTEGER): WINBOOL; stdcall; public name 'unidewin_QueryPerformanceFrequency';
begin
  PInt64(lpFrequency)^ := 1000000;
  Result := True;
end;

function Impl_GetCurrentProcessId: DWORD; stdcall; public name 'unidewin_GetCurrentProcessId';
begin
  Result := DWORD(fpGetPid);
end;

function Impl_GetCurrentThreadId: DWORD; stdcall; public name 'unidewin_GetCurrentThreadId';
begin
  Result := DWORD(PtrUInt(GetThreadID));
end;

function Impl_GetLastError: DWORD; stdcall; public name 'unidewin_GetLastError';
begin
  Result := UnixLastError;
end;

procedure Impl_SetLastError(dwErrCode:DWORD); stdcall; public name 'unidewin_SetLastError';
begin
  UnixLastError := dwErrCode;
end;

function Impl_GetModuleFileNameA(hModule:HINST; lpFilename:LPSTR; nSize:DWORD): DWORD; stdcall; public name 'unidewin_GetModuleFileNameA';
begin
  Result := PutAnsi(ParamStr(0), lpFilename, nSize);
end;

function Impl_GetModuleFileNameW(AModule: HMODULE; ABuffer: PWideChar; ASize: DWORD): DWORD; stdcall; public name 'unidewin_GetModuleFileNameW';
begin
  Result := PutWide(ParamStr(0), ABuffer, ASize);
end;

// Returns chars needed (with #0) when the buffer is short, as Windows does
function Impl_GetEnvironmentVariableA(lpName:LPCSTR; lpBuffer:LPSTR; nSize:DWORD): DWORD; stdcall; public name 'unidewin_GetEnvironmentVariableA';
var
  Value: AnsiString;
begin
  Value := SysUtils.GetEnvironmentVariable(lpName);
  if Value = '' then
  begin
    Result := 0;
    UnixLastError := ERROR_ENVVAR_NOT_FOUND;
    Exit;
  end;
  if DWORD(Length(Value)) >= nSize then
    Result := Length(Value) + 1
  else
    Result := PutAnsi(Value, lpBuffer, nSize);
end;

function Impl_GetEnvironmentVariableW(AName: PWideChar; ABuffer: PWideChar; ASize: DWORD): DWORD; stdcall; public name 'unidewin_GetEnvironmentVariableW';
var
  Value: AnsiString;
begin
  Value := SysUtils.GetEnvironmentVariable(WideToUtf8(AName, -1));
  if Value = '' then
  begin
    Result := 0;
    UnixLastError := ERROR_ENVVAR_NOT_FOUND;
    Exit;
  end;
  if DWORD(Length(UTF8Decode(Value))) >= ASize then
    Result := Length(UTF8Decode(Value)) + 1
  else
    Result := PutWide(Value, ABuffer, ASize);
end;

function Impl_GetTempPathA(nBufferLength:DWORD; lpBuffer:LPSTR): DWORD; stdcall; public name 'unidewin_GetTempPathA';
begin
  Result := PutAnsi(IncludeTrailingPathDelimiter(GetTempDir), lpBuffer, nBufferLength);
end;

function Impl_GetTempPathW(ABufferLen: DWORD; ABuffer: PWideChar): DWORD; stdcall; public name 'unidewin_GetTempPathW';
begin
  Result := PutWide(IncludeTrailingPathDelimiter(GetTempDir), ABuffer, ABufferLen);
end;

// --- character case (ASCII, Latin-1, Cyrillic) ---

function WideUpperOf(ACode: Word): Word;
begin
  Result := ACode;
  case ACode of
    $61..$7A, $E0..$F6, $F8..$FE, $0430..$044F: Dec(Result, 32);
    $0450..$045F: Dec(Result, 80);
  end;
end;

function WideLowerOf(ACode: Word): Word;
begin
  Result := ACode;
  case ACode of
    $41..$5A, $C0..$D6, $D8..$DE, $0410..$042F: Inc(Result, 32);
    $0400..$040F: Inc(Result, 80);
  end;
end;

function Impl_CharUpperBuffW(lpsz:LPWSTR; cchLength:DWORD): DWORD; stdcall; public name 'unidewin_CharUpperBuffW';
var
  CharIdx: DWORD;
begin
  for CharIdx := 0 to Integer(cchLength) - 1 do
    lpsz[CharIdx] := WideChar(WideUpperOf(Word(lpsz[CharIdx])));
  Result := cchLength;
end;

function Impl_CharLowerBuffW(AText: PWideChar; ALength: DWORD): DWORD; stdcall; public name 'unidewin_CharLowerBuffW';
var
  CharIdx: DWORD;
begin
  for CharIdx := 0 to Integer(ALength) - 1 do
    AText[CharIdx] := WideChar(WideLowerOf(Word(AText[CharIdx])));
  Result := ALength;
end;

// A pointer below $10000 is one character in the low word (as in Windows)
function Impl_CharUpperW(AText: PWideChar): PWideChar; stdcall; public name 'unidewin_CharUpperW';
var
  CharIdx: Integer;
begin
  Result := AText;
  if PtrUInt(AText) < $10000 then
  begin
    Result := PWideChar(PtrUInt(WideUpperOf(Word(PtrUInt(AText)))));
    Exit;
  end;
  CharIdx := 0;
  while AText[CharIdx] <> #0 do
  begin
    AText[CharIdx] := WideChar(WideUpperOf(Word(AText[CharIdx])));
    Inc(CharIdx);
  end;
end;

function Impl_CharLowerW(AText: PWideChar): PWideChar; stdcall; public name 'unidewin_CharLowerW';
var
  CharIdx: Integer;
begin
  Result := AText;
  if PtrUInt(AText) < $10000 then
  begin
    Result := PWideChar(PtrUInt(WideLowerOf(Word(PtrUInt(AText)))));
    Exit;
  end;
  CharIdx := 0;
  while AText[CharIdx] <> #0 do
  begin
    AText[CharIdx] := WideChar(WideLowerOf(Word(AText[CharIdx])));
    Inc(CharIdx);
  end;
end;

function Impl_IsCharAlphaNumericW(AChar: WideChar): BOOL; stdcall; public name 'unidewin_IsCharAlphaNumericW';
begin
  case Word(AChar) of
    $30..$39, $41..$5A, $61..$7A, $AA, $B5, $BA, $C0..$D6, $D8..$F6, $F8..$24F,
    $0386..$03FF, $0400..$0481, $048A..$052F:
      Result := True;
  else
    Result := False;
  end;
end;

// NORM_IGNORECASE (1): compare lower-cased; result 1 less, 2 equal, 3 greater
function Impl_CompareStringW(ALocale: LCID; AFlags: DWORD; AStr1: PWideChar; ALen1: Integer; AStr2: PWideChar; ALen2: Integer): Integer; stdcall; public name 'unidewin_CompareStringW';
var
  CharIdx: Integer;
  Code1, Code2: Word;
begin
  if ALen1 < 0 then
  begin
    ALen1 := 0;
    while AStr1[ALen1] <> #0 do
      Inc(ALen1);
  end;
  if ALen2 < 0 then
  begin
    ALen2 := 0;
    while AStr2[ALen2] <> #0 do
      Inc(ALen2);
  end;
  for CharIdx := 0 to ALen1 - 1 do
  begin
    if CharIdx >= ALen2 then
    begin
      Result := 3;
      Exit;
    end;
    Code1 := Word(AStr1[CharIdx]);
    Code2 := Word(AStr2[CharIdx]);
    if AFlags and NORM_IGNORECASE <> 0 then
    begin
      Code1 := WideLowerOf(Code1);
      Code2 := WideLowerOf(Code2);
    end;
    if Code1 < Code2 then
    begin
      Result := 1;
      Exit;
    end;
    if Code1 > Code2 then
    begin
      Result := 3;
      Exit;
    end;
  end;
  if ALen1 < ALen2 then
    Result := 1
  else
    Result := 2;
end;

// --- files: handles are file descriptors, only those opened here ---

var
  UnixFileFds: array of THandle;

function FdIsOurs(AFile: THandle): Boolean;
var
  FdIdx: Integer;
begin
  Result := False;
  for FdIdx := 0 to High(UnixFileFds) do
    if UnixFileFds[FdIdx] = AFile then
    begin
      Result := True;
      Exit;
    end;
end;

// Serial port (\\.\COM5 on Windows): here \\.\/dev/ttyACM0 or /dev/ttyUSB0.
// Opened non-blocking without becoming the controlling terminal; on error
// UnixLastError is errno, so SysErrorMessage gives the system text
// (EACCES - user is not in the dialout group).
function OpenDeviceFd(const AName: AnsiString): THandle;
var
  DevFd: cint;
begin
  Result := INVALID_HANDLE_VALUE;
  DevFd := fpOpen(PChar(AName), O_RDWR or O_NOCTTY or O_NONBLOCK);
  if DevFd < 0 then
  begin
    UnixLastError := fpgeterrno;
    Exit;
  end;
  SetLength(UnixFileFds, Length(UnixFileFds) + 1);
  UnixFileFds[High(UnixFileFds)] := DevFd;
  Result := DevFd;
end;

function OpenFileUtf8(const AName: AnsiString; AAccess, ACreation: DWORD): THandle;
var
  Mode: Integer;
  FileFd: THandle;
begin
  Result := INVALID_HANDLE_VALUE;
  if Copy(AName, 1, 4) = '\\.\' then
  begin
    Result := OpenDeviceFd(Copy(AName, 5, MaxInt));
    Exit;
  end;
  if Copy(AName, 1, 5) = '/dev/' then
  begin
    Result := OpenDeviceFd(AName);
    Exit;
  end;
  if (AAccess and GENERIC_WRITE <> 0) and (AAccess and GENERIC_READ <> 0) then
    Mode := fmOpenReadWrite
  else if AAccess and GENERIC_WRITE <> 0 then
    Mode := fmOpenWrite
  else
    Mode := fmOpenRead;
  case ACreation of
    CREATE_NEW:
      begin
        if FileExists(AName) then
        begin
          UnixLastError := ERROR_FILE_EXISTS;
          Exit;
        end;
        FileFd := FileCreate(AName);
      end;
    CREATE_ALWAYS, TRUNCATE_EXISTING:
      FileFd := FileCreate(AName);
    OPEN_ALWAYS:
      if FileExists(AName) then
        FileFd := FileOpen(AName, Mode)
      else
        FileFd := FileCreate(AName);
  else
    FileFd := FileOpen(AName, Mode);
  end;
  if FileFd = THandle(-1) then
  begin
    if FileExists(AName) then
      UnixLastError := ERROR_ACCESS_DENIED
    else
      UnixLastError := ERROR_FILE_NOT_FOUND;
    Exit;
  end;
  SetLength(UnixFileFds, Length(UnixFileFds) + 1);
  UnixFileFds[High(UnixFileFds)] := FileFd;
  Result := FileFd;
end;

function Impl_CreateFileA(lpFileName:LPCSTR; dwDesiredAccess:DWORD; dwShareMode:DWORD; lpSecurityAttributes:LPSECURITY_ATTRIBUTES; dwCreationDisposition:DWORD; dwFlagsAndAttributes:DWORD; hTemplateFile:HANDLE): HANDLE; stdcall; public name 'unidewin_CreateFileA';
begin
  // A-names in unIDE under FPC are UTF-8 strings (LCL), passed as is
  Result := OpenFileUtf8(lpFileName, dwDesiredAccess, dwCreationDisposition);
end;

function Impl_CreateFileW(AName: PWideChar; AAccess, AShare: DWORD; ASecurity: Pointer; ACreation, AFlags: DWORD; ATemplate: THandle): THandle; stdcall; public name 'unidewin_CreateFileW';
begin
  Result := OpenFileUtf8(WideToUtf8(AName, -1), AAccess, ACreation);
end;

function Impl_ReadFile(AFile: THandle; ABuffer: Pointer; AToRead: DWORD; var ARead: DWORD; AOverlapped: Pointer): BOOL; stdcall; public name 'unidewin_ReadFile';
var
  ReadCount: LongInt;
begin
  ARead := 0;
  Result := False;
  if not FdIsOurs(AFile) then
    Exit;
  ReadCount := FileRead(AFile, ABuffer^, AToRead);
  if ReadCount < 0 then
  begin
    // Non-blocking device (serial port) with nothing to read
    if fpgeterrno = ESysEAGAIN then
    begin
      Result := True;
      Exit;
    end;
    UnixLastError := fpgeterrno;
    Exit;
  end;
  ARead := ReadCount;
  Result := True;
end;

function Impl_WriteFile(AFile: THandle; const ABuffer; ACount: DWORD; var AWritten: DWORD; AOverlapped: Pointer): BOOL; stdcall; public name 'unidewin_WriteFile';
var
  WriteCount: LongInt;
begin
  AWritten := 0;
  Result := False;
  if not FdIsOurs(AFile) then
    Exit;
  WriteCount := FileWrite(AFile, ABuffer, ACount);
  if WriteCount < 0 then
  begin
    UnixLastError := fpgeterrno;
    Exit;
  end;
  AWritten := WriteCount;
  Result := True;
end;

function Impl_GetFileSize(hFile:HANDLE; lpFileSizeHigh:LPDWORD): DWORD; stdcall; public name 'unidewin_GetFileSize';
var
  StatBuf: BaseUnix.Stat;
begin
  Result := $FFFFFFFF;
  if not FdIsOurs(hFile) or (fpFStat(hFile, StatBuf) <> 0) then
    Exit;
  Result := DWORD(StatBuf.st_size and $FFFFFFFF);
  if lpFileSizeHigh <> nil then
    lpFileSizeHigh^ := DWORD(Int64(StatBuf.st_size) shr 32);
end;

function Impl_SetFilePointer(hFile:HANDLE; lDistanceToMove:LONG; lpDistanceToMoveHigh:PLONG; dwMoveMethod:DWORD): DWORD; stdcall; public name 'unidewin_SetFilePointer';
var
  Distance, NewPos: Int64;
begin
  Result := $FFFFFFFF;
  if not FdIsOurs(hFile) then
    Exit;
  if lpDistanceToMoveHigh <> nil then
    Distance := (Int64(lpDistanceToMoveHigh^) shl 32) or DWORD(lDistanceToMove)
  else
    Distance := lDistanceToMove;
  NewPos := FileSeek(hFile, Distance, Integer(dwMoveMethod));
  if NewPos < 0 then
    Exit;
  Result := DWORD(NewPos and $FFFFFFFF);
  if lpDistanceToMoveHigh <> nil then
    lpDistanceToMoveHigh^ := LONG(NewPos shr 32);
end;

// --- processes started by ProcRun (DetachHandle) ---
// Handle = UnixProcBase + pid: WaitForSingleObject, GetExitCodeProcess,
// TerminateProcess, CloseHandle work on it as on a Windows process handle.
// Other handles: WaitForSingleObject answers WAIT_OBJECT_0 as before.

const
  UnixProcBase = $40000000;
  UnixProcLimit = $00400000;   // pid_max on Linux is at most 2^22

type
  TUnixProcState = record
    Pid: cint;
    Done: Boolean;
    Code: DWORD;
  end;

var
  UnixProcs: array of TUnixProcState;

function UnixProcIndex(AHandle: THandle): Integer;
var
  ProcIdx: Integer;
begin
  Result := -1;
  if (AHandle < UnixProcBase) or (AHandle >= UnixProcBase + UnixProcLimit) then
    Exit;
  for ProcIdx := 0 to High(UnixProcs) do
    if UnixProcs[ProcIdx].Pid = cint(AHandle - UnixProcBase) then
    begin
      Result := ProcIdx;
      Exit;
    end;
end;

function Impl_UnixProcHandle(APid: Cardinal): THandle; stdcall; public name 'unidewin_UnixProcHandle';
begin
  Result := 0;
  if (APid = 0) or (APid >= UnixProcLimit) then
    Exit;
  Result := UnixProcBase + APid;
  if UnixProcIndex(Result) >= 0 then
    Exit;
  SetLength(UnixProcs, Length(UnixProcs) + 1);
  UnixProcs[High(UnixProcs)].Pid := APid;
  UnixProcs[High(UnixProcs)].Done := False;
  UnixProcs[High(UnixProcs)].Code := 0;
end;

// Process ended? Reaps it (waitpid) and keeps the exit code
function UnixProcPoll(AIndex: Integer): Boolean;
var
  Status: cint;
  WaitRes: cint;
begin
  Result := UnixProcs[AIndex].Done;
  if Result then
    Exit;
  Status := 0;
  WaitRes := fpWaitPid(UnixProcs[AIndex].Pid, @Status, WNOHANG);
  if WaitRes = UnixProcs[AIndex].Pid then
  begin
    UnixProcs[AIndex].Done := True;
    if WIFEXITED(Status) then
      UnixProcs[AIndex].Code := WEXITSTATUS(Status)
    else
      UnixProcs[AIndex].Code := 1;
  end
  else if WaitRes < 0 then
  begin
    // Not our child any more (reaped elsewhere): alive while kill(0) works
    if fpKill(UnixProcs[AIndex].Pid, 0) <> 0 then
      UnixProcs[AIndex].Done := True;
  end;
  Result := UnixProcs[AIndex].Done;
end;

function Impl_WaitForSingleObject(hHandle:HANDLE; dwMilliseconds:DWORD): DWORD; stdcall; public name 'unidewin_WaitForSingleObject';
var
  ProcIdx: Integer;
  StartTick: QWord;
begin
  Result := WAIT_OBJECT_0;
  ProcIdx := UnixProcIndex(hHandle);
  if ProcIdx < 0 then
    Exit;
  StartTick := SysUtils.GetTickCount64;
  while not UnixProcPoll(ProcIdx) do
  begin
    if (dwMilliseconds <> INFINITE) and
       (SysUtils.GetTickCount64 - StartTick >= dwMilliseconds) then
    begin
      Result := WAIT_TIMEOUT;
      Exit;
    end;
    SysUtils.Sleep(5);
  end;
end;

function Impl_GetExitCodeProcess(hProcess:HANDLE; lpExitCode:LPDWORD): WINBOOL; stdcall; public name 'unidewin_GetExitCodeProcess';
var
  ProcIdx: Integer;
begin
  Result := False;
  ProcIdx := UnixProcIndex(hProcess);
  if (ProcIdx < 0) or (lpExitCode = nil) then
    Exit;
  if UnixProcPoll(ProcIdx) then
    lpExitCode^ := UnixProcs[ProcIdx].Code
  else
    lpExitCode^ := STILL_ACTIVE;
  Result := True;
end;

function Impl_TerminateProcess(hProcess:HANDLE; uExitCode:UINT): WINBOOL; stdcall; public name 'unidewin_TerminateProcess';
var
  ProcIdx: Integer;
begin
  Result := False;
  ProcIdx := UnixProcIndex(hProcess);
  if ProcIdx < 0 then
    Exit;
  if UnixProcPoll(ProcIdx) then
  begin
    Result := True;
    Exit;
  end;
  Result := fpKill(UnixProcs[ProcIdx].Pid, SIGKILL) = 0;
end;

// CloseHandle of a process handle: forget it (the process keeps running)
function UnixProcClose(AHandle: THandle): Boolean;
var
  ProcIdx: Integer;
begin
  ProcIdx := UnixProcIndex(AHandle);
  Result := ProcIdx >= 0;
  if not Result then
    Exit;
  UnixProcPoll(ProcIdx);
  UnixProcs[ProcIdx] := UnixProcs[High(UnixProcs)];
  SetLength(UnixProcs, Length(UnixProcs) - 1);
end;

function Impl_CloseHandle(hObject:HANDLE): WINBOOL; stdcall; public name 'unidewin_CloseHandle';
var
  FdIdx: Integer;
begin
  Result := UnixProcClose(hObject);
  if Result then
    Exit;
  for FdIdx := 0 to High(UnixFileFds) do
    if UnixFileFds[FdIdx] = hObject then
    begin
      FileClose(hObject);
      UnixFileFds[FdIdx] := UnixFileFds[High(UnixFileFds)];
      SetLength(UnixFileFds, Length(UnixFileFds) - 1);
      Result := True;
      Exit;
    end;
end;

// --- serial port (termios) ---
// What DlgArdSerial needs: speed, 8N1 raw mode, DTR/RTS on, bytes waiting,
// flush. Timeouts are not kept: the fd is non-blocking, ReadFile returns
// what has arrived (as ReadIntervalTimeout = MAXDWORD on Windows).

const
  CommDtrControlMask = $00000030;  // DCB.Flags fDtrControl
  CommDtrEnable = $00000010;
  CommRtsControlMask = $00003000;  // DCB.Flags fRtsControl
  CommRtsEnable = $00001000;

function CommSpeedOf(ABaud: DWORD; var ASpeed: Cardinal): Boolean;
begin
  Result := True;
  case ABaud of
    50: ASpeed := B50;
    75: ASpeed := B75;
    110: ASpeed := B110;
    134: ASpeed := B134;
    150: ASpeed := B150;
    200: ASpeed := B200;
    300: ASpeed := B300;
    600: ASpeed := B600;
    1200: ASpeed := B1200;
    1800: ASpeed := B1800;
    2400: ASpeed := B2400;
    4800: ASpeed := B4800;
    9600: ASpeed := B9600;
    19200: ASpeed := B19200;
    38400: ASpeed := B38400;
    57600: ASpeed := B57600;
    115200: ASpeed := B115200;
    230400: ASpeed := B230400;
    {$IFDEF LINUX}
    460800: ASpeed := B460800;
    500000: ASpeed := B500000;
    576000: ASpeed := B576000;
    921600: ASpeed := B921600;
    1000000: ASpeed := B1000000;
    1152000: ASpeed := B1152000;
    1500000: ASpeed := B1500000;
    2000000: ASpeed := B2000000;
    {$ENDIF}
  else
    Result := False;
  end;
end;

function CommBaudOf(ASpeed: Cardinal): DWORD;
const
  BaudList: array[0..17] of DWORD = (50, 75, 110, 134, 150, 200, 300, 600,
    1200, 1800, 2400, 4800, 9600, 19200, 38400, 57600, 115200, 230400);
var
  BaudIdx: Integer;
  OneSpeed: Cardinal;
begin
  Result := 0;
  for BaudIdx := Low(BaudList) to High(BaudList) do
    if CommSpeedOf(BaudList[BaudIdx], OneSpeed) and (OneSpeed = ASpeed) then
    begin
      Result := BaudList[BaudIdx];
      Exit;
    end;
end;

function Impl_GetCommState(hFile:HANDLE; lpDCB:PDCB): WINBOOL; stdcall; public name 'unidewin_GetCommState';
var
  Tio: Termios;
begin
  Result := False;
  if not FdIsOurs(hFile) or (lpDCB = nil) then
    Exit;
  if TCGetAttr(hFile, Tio) <> 0 then
  begin
    UnixLastError := fpgeterrno;
    Exit;
  end;
  lpDCB^.BaudRate := CommBaudOf(Tio.c_cflag and (CBAUD or CBAUDEX));
  lpDCB^.ByteSize := 8;
  lpDCB^.Parity := NOPARITY;
  lpDCB^.StopBits := ONESTOPBIT;
  lpDCB^.flags := 1; // fBinary
  Result := True;
end;

function Impl_SetCommState(hFile:HANDLE; lpDCB:LPDCB): WINBOOL; stdcall; public name 'unidewin_SetCommState';
var
  Tio: Termios;
  Speed: Cardinal;
  Lines: cint;
begin
  Result := False;
  if not FdIsOurs(hFile) or (lpDCB = nil) then
    Exit;
  if not CommSpeedOf(lpDCB^.BaudRate, Speed) then
  begin
    UnixLastError := ESysEINVAL;
    Exit;
  end;
  if TCGetAttr(hFile, Tio) <> 0 then
  begin
    UnixLastError := fpgeterrno;
    Exit;
  end;
  CFMakeRaw(Tio);
  Tio.c_cflag := Tio.c_cflag and not (CSIZE or PARENB or PARODD or CSTOPB or
                                       CRTSCTS);
  case lpDCB^.ByteSize of
    5: Tio.c_cflag := Tio.c_cflag or CS5;
    6: Tio.c_cflag := Tio.c_cflag or CS6;
    7: Tio.c_cflag := Tio.c_cflag or CS7;
  else
    Tio.c_cflag := Tio.c_cflag or CS8;
  end;
  case lpDCB^.Parity of
    ODDPARITY: Tio.c_cflag := Tio.c_cflag or PARENB or PARODD;
    EVENPARITY: Tio.c_cflag := Tio.c_cflag or PARENB;
  end;
  if lpDCB^.StopBits = TWOSTOPBITS then
    Tio.c_cflag := Tio.c_cflag or CSTOPB;
  Tio.c_cflag := Tio.c_cflag or CLOCAL or CREAD;
  Tio.c_cc[VMIN] := 0;
  Tio.c_cc[VTIME] := 0;
  CFSetISpeed(Tio, Speed);
  CFSetOSpeed(Tio, Speed);
  if TCSetAttr(hFile, TCSANOW, Tio) <> 0 then
  begin
    UnixLastError := fpgeterrno;
    Exit;
  end;
  // DTR and RTS on, as DTR_CONTROL_ENABLE / RTS_CONTROL_ENABLE (many boards
  // reset on DTR)
  Lines := 0;
  if lpDCB^.flags and CommDtrControlMask = CommDtrEnable then
    Lines := Lines or TIOCM_DTR;
  if lpDCB^.flags and CommRtsControlMask = CommRtsEnable then
    Lines := Lines or TIOCM_RTS;
  if Lines <> 0 then
    fpIOCtl(hFile, TIOCMBIS, @Lines);
  Result := True;
end;

function Impl_SetCommTimeouts(hFile:HANDLE; lpCommTimeouts:LPCOMMTIMEOUTS): WINBOOL; stdcall; public name 'unidewin_SetCommTimeouts';
begin
  Result := FdIsOurs(hFile);
end;

function Impl_SetupComm(hFile:HANDLE; dwInQueue:DWORD; dwOutQueue:DWORD): WINBOOL; stdcall; public name 'unidewin_SetupComm';
begin
  Result := FdIsOurs(hFile);
end;

function Impl_PurgeComm(hFile:HANDLE; dwFlags:DWORD): WINBOOL; stdcall; public name 'unidewin_PurgeComm';
begin
  Result := FdIsOurs(hFile) and (TCFlush(hFile, TCIOFLUSH) = 0);
end;

// Bytes waiting in cbInQue. Unplugged device: ioctl fails (EIO) -> False
function Impl_ClearCommError(hFile:HANDLE; lpErrors:LPDWORD; lpStat:LPCOMSTAT): WINBOOL; stdcall; public name 'unidewin_ClearCommError';
var
  Waiting: cint;
begin
  Result := False;
  if lpErrors <> nil then
    lpErrors^ := 0;
  if not FdIsOurs(hFile) then
    Exit;
  Waiting := 0;
  if fpIOCtl(hFile, FIONREAD, @Waiting) <> 0 then
  begin
    UnixLastError := fpgeterrno;
    Exit;
  end;
  if lpStat <> nil then
  begin
    FillChar(lpStat^, SizeOf(lpStat^), 0);
    lpStat^.cbInQue := Waiting;
  end;
  Result := True;
end;

function AttrOfPath(const AName: AnsiString): DWORD;
begin
  if DirectoryExists(AName) then
    Result := FILE_ATTRIBUTE_DIRECTORY
  else if FileExists(AName) then
  begin
    Result := FILE_ATTRIBUTE_NORMAL;
    if fpAccess(AName, W_OK) <> 0 then
      Result := FILE_ATTRIBUTE_READONLY;
  end
  else
  begin
    Result := $FFFFFFFF;
    UnixLastError := ERROR_FILE_NOT_FOUND;
  end;
end;

function Impl_GetFileAttributesW(AFileName: PWideChar): DWORD; stdcall; public name 'unidewin_GetFileAttributesW';
begin
  Result := AttrOfPath(WideToUtf8(AFileName, -1));
end;

// Unix time (s) -> FILETIME (100 ns since 1601)
procedure UnixToFileTime(AUnixTime: Int64; var AFileTime: Windows.FILETIME);
var
  Ticks: Int64;
begin
  Ticks := (AUnixTime + 11644473600) * 10000000;
  AFileTime.dwLowDateTime := DWORD(Ticks and $FFFFFFFF);
  AFileTime.dwHighDateTime := DWORD(Ticks shr 32);
end;

function Impl_GetFileAttributesExA(lpFileName:LPCSTR; fInfoLevelId:TGET_FILEEX_INFO_LEVELS; lpFileInformation:pointer): BOOL; stdcall; public name 'unidewin_GetFileAttributesExA';
var
  StatBuf: BaseUnix.Stat;
  Info: LPWIN32_FILE_ATTRIBUTE_DATA;
begin
  Result := False;
  if fpStat(lpFileName, StatBuf) <> 0 then
  begin
    UnixLastError := ERROR_FILE_NOT_FOUND;
    Exit;
  end;
  Info := LPWIN32_FILE_ATTRIBUTE_DATA(lpFileInformation);
  FillChar(Info^, SizeOf(Info^), 0);
  Info^.dwFileAttributes := AttrOfPath(lpFileName);
  UnixToFileTime(StatBuf.st_ctime, Info^.ftCreationTime);
  UnixToFileTime(StatBuf.st_atime, Info^.ftLastAccessTime);
  UnixToFileTime(StatBuf.st_mtime, Info^.ftLastWriteTime);
  Info^.nFileSizeHigh := DWORD(Int64(StatBuf.st_size) shr 32);
  Info^.nFileSizeLow := DWORD(StatBuf.st_size and $FFFFFFFF);
  Result := True;
end;

function Impl_FileTimeToLocalFileTime(lpFileTime:LPFILETIME; lpLocalFileTime:LPFILETIME): WINBOOL; stdcall; public name 'unidewin_FileTimeToLocalFileTime';
var
  Ticks: Int64;
begin
  Ticks := (Int64(lpFileTime^.dwHighDateTime) shl 32) or lpFileTime^.dwLowDateTime;
  Ticks := Ticks - Int64(GetLocalTimeOffset) * 60 * 10000000;
  lpLocalFileTime^.dwLowDateTime := DWORD(Ticks and $FFFFFFFF);
  lpLocalFileTime^.dwHighDateTime := DWORD(Ticks shr 32);
  Result := True;
end;

function Impl_FileTimeToSystemTime(lpFileTime:LPFILETIME; lpSystemTime:LPSYSTEMTIME): WINBOOL; stdcall; public name 'unidewin_FileTimeToSystemTime';
var
  Ticks: Int64;
  Stamp: TDateTime;
  YearVal, MonthVal, DayVal, HourVal, MinVal, SecVal, MsecVal: Word;
begin
  Ticks := (Int64(lpFileTime^.dwHighDateTime) shl 32) or lpFileTime^.dwLowDateTime;
  // 1601-01-01 = TDateTime -109205
  Stamp := -109205 + Ticks / (10000000.0 * 86400);
  DecodeDate(Stamp, YearVal, MonthVal, DayVal);
  DecodeTime(Stamp, HourVal, MinVal, SecVal, MsecVal);
  lpSystemTime^.wYear := YearVal;
  lpSystemTime^.wMonth := MonthVal;
  lpSystemTime^.wDay := DayVal;
  lpSystemTime^.wDayOfWeek := DayOfWeek(Stamp) - 1;
  lpSystemTime^.wHour := HourVal;
  lpSystemTime^.wMinute := MinVal;
  lpSystemTime^.wSecond := SecVal;
  lpSystemTime^.wMilliseconds := MsecVal;
  Result := True;
end;

function Impl_DeleteFileW(AFileName: PWideChar): BOOL; stdcall; public name 'unidewin_DeleteFileW';
begin
  Result := SysUtils.DeleteFile(WideToUtf8(AFileName, -1));
end;

function Impl_CreateDirectoryW(APath: PWideChar; ASecurity: Pointer): BOOL; stdcall; public name 'unidewin_CreateDirectoryW';
begin
  Result := CreateDir(WideToUtf8(APath, -1));
end;

function Impl_RemoveDirectoryW(APath: PWideChar): BOOL; stdcall; public name 'unidewin_RemoveDirectoryW';
begin
  Result := RemoveDir(WideToUtf8(APath, -1));
end;

function CopyFileUtf8(const AFrom, ATo: AnsiString; AFailIfExists: Boolean): Boolean;
var
  SrcStream, DstStream: TFileStream;
begin
  Result := False;
  if AFailIfExists and FileExists(ATo) then
    Exit;
  try
    SrcStream := TFileStream.Create(AFrom, fmOpenRead or fmShareDenyNone);
    try
      DstStream := TFileStream.Create(ATo, fmCreate);
      try
        if SrcStream.Size > 0 then
          DstStream.CopyFrom(SrcStream, SrcStream.Size);
      finally
        DstStream.Free;
      end;
    finally
      SrcStream.Free;
    end;
    FileSetDate(ATo, FileAge(AFrom));
    Result := True;
  except
    Result := False;
  end;
end;

function Impl_CopyFileW(lpExistingFileName:LPCWSTR; lpNewFileName:LPCWSTR; bFailIfExists:WINBOOL): WINBOOL; stdcall; public name 'unidewin_CopyFileW';
begin
  Result := CopyFileUtf8(WideToUtf8(lpExistingFileName, -1), WideToUtf8(lpNewFileName, -1), bFailIfExists);
end;

function Impl_MoveFileExW(AExisting, ANew: PWideChar; AFlags: DWORD): BOOL; stdcall; public name 'unidewin_MoveFileExW';
var
  NewName: AnsiString;
begin
  NewName := WideToUtf8(ANew, -1);
  if (AFlags and MOVEFILE_REPLACE_EXISTING = 0) and FileExists(NewName) then
  begin
    Result := False;
    Exit;
  end;
  Result := RenameFile(WideToUtf8(AExisting, -1), NewName);
end;

function Impl_GetFullPathNameW(AFileName: PWideChar; ABufferLen: DWORD; ABuffer: PWideChar; AFilePart: Pointer): DWORD; stdcall; public name 'unidewin_GetFullPathNameW';
begin
  Result := PutWide(ExpandFileName(WideToUtf8(AFileName, -1)), ABuffer, ABufferLen);
  if AFilePart <> nil then
    PPWideChar(AFilePart)^ := nil;
end;

// --- windows ---

function Impl_SendMessageW(hWnd:HWND; Msg:UINT; wParam:WPARAM; lParam:LPARAM): LRESULT; stdcall; public name 'unidewin_SendMessageW';
begin
  Result := LCLIntf.SendMessage(hWnd, Msg, wParam, lParam);
end;

function Impl_MapWindowPoints(hWndFrom:HWND; hWndTo:HWND; lpPoints:LPPOINT; cPoints:UINT): longint; stdcall; public name 'unidewin_MapWindowPoints';
var
  PtIdx: Integer;
  Origin, Target: TPoint;
begin
  Origin := Point(0, 0);
  if hWndFrom <> 0 then
    LCLIntf.ClientToScreen(hWndFrom, Origin);
  Target := Point(0, 0);
  if hWndTo <> 0 then
    LCLIntf.ClientToScreen(hWndTo, Target);
  for PtIdx := 0 to Integer(cPoints) - 1 do
  begin
    Inc(PPoint(lpPoints + PtIdx)^.X, Origin.X - Target.X);
    Inc(PPoint(lpPoints + PtIdx)^.Y, Origin.Y - Target.Y);
  end;
  Result := MakeLong(Word(Origin.X - Target.X), Word(Origin.Y - Target.Y));
end;

function Impl_IsChild(hWndParent:HWND; hWnd:HWND): WINBOOL; stdcall; public name 'unidewin_IsChild';
var
  Cur: HWND;
begin
  Result := False;
  if (hWndParent = 0) or (hWnd = 0) then
    Exit;
  Cur := LCLIntf.GetParent(hWnd);
  while Cur <> 0 do
  begin
    if Cur = hWndParent then
    begin
      Result := True;
      Exit;
    end;
    Cur := LCLIntf.GetParent(Cur);
  end;
end;

function Impl_GetAncestor(AWnd: HWND; AFlags: UINT): HWND; stdcall; public name 'unidewin_GetAncestor';
var
  Cur: HWND;
begin
  Result := AWnd;
  if AFlags = GA_PARENT then
  begin
    Result := LCLIntf.GetParent(AWnd);
    Exit;
  end;
  Cur := LCLIntf.GetParent(AWnd);
  while Cur <> 0 do
  begin
    Result := Cur;
    Cur := LCLIntf.GetParent(Cur);
  end;
end;

function ControlOfWnd(AWnd: HWND): TWinControl;
begin
  Result := Controls.FindControl(AWnd);
end;

function Impl_GetWindowTextW(AWnd: HWND; AText: PWideChar; AMax: Integer): Integer; stdcall; public name 'unidewin_GetWindowTextW';
var
  Ctl: TWinControl;
begin
  Ctl := ControlOfWnd(AWnd);
  if Ctl = nil then
  begin
    Result := 0;
    if (AText <> nil) and (AMax > 0) then
      AText^ := #0;
    Exit;
  end;
  Result := PutWide(Ctl.Caption, AText, AMax);
end;

function Impl_SetWindowTextW(AWnd: HWND; AText: PWideChar): BOOL; stdcall; public name 'unidewin_SetWindowTextW';
var
  Ctl: TWinControl;
begin
  Ctl := ControlOfWnd(AWnd);
  Result := Ctl <> nil;
  if Result then
    Ctl.Caption := WideToUtf8(AText, -1);
end;

// --- resources: FPC resources of the program (the .res is linked in) ---

function Impl_FindResourceA(hModule:HINST; lpName:LPCSTR; lpType:LPCSTR): HRSRC; stdcall; public name 'unidewin_FindResourceA';
begin
  Result := HRSRC(System.FindResource(TFPResourceHMODULE(hModule), lpName, lpType));
end;

function Impl_LoadResource(hModule:HINST; hResInfo:HRSRC): HGLOBAL; stdcall; public name 'unidewin_LoadResource';
begin
  Result := HGLOBAL(System.LoadResource(TFPResourceHMODULE(hModule), TFPResourceHandle(hResInfo)));
end;

function Impl_LockResource(hResData:HGLOBAL): LPVOID; stdcall; public name 'unidewin_LockResource';
begin
  Result := System.LockResource(TFPResourceHGLOBAL(hResData));
end;

function Impl_SizeofResource(hModule:HINST; hResInfo:HRSRC): DWORD; stdcall; public name 'unidewin_SizeofResource';
begin
  Result := System.SizeofResource(TFPResourceHMODULE(hModule), TFPResourceHandle(hResInfo));
end;

function Impl_GetModuleHandleA(lpModuleName:LPCSTR): HMODULE; stdcall; public name 'unidewin_GetModuleHandleA';
begin
  if lpModuleName = nil then
    Result := HMODULE(HInstance)
  else
    Result := 0;
end;
