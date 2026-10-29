unit EdClip;

// ---------------------------------------------------------------------------
//  Буфер обмена для своего редактора (EdEditor, EdView): текст Unicode.
//  Windows - CF_UNICODETEXT (чтение - и CF_TEXT), иначе - Clipboard LCL.
//  Строки - как есть (переводы строк делает вызывающий).
// ---------------------------------------------------------------------------

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  {$IFDEF MSWINDOWS}Windows,{$ELSE}Clipbrd,{$ENDIF}
  SysUtils;

function EdClipboardText: WideString;
procedure EdSetClipboardText(const AText: WideString);

implementation

const
  EdCfUnicodeText = 13;        // CF_UNICODETEXT
  EdCfText = 1;                // CF_TEXT

{$IFDEF MSWINDOWS}
// Буфер обмена занят другой программой - несколько попыток
function EdOpenClipboard: Boolean;
var
  TryIdx: Integer;
begin
  Result := False;
  for TryIdx := 1 to 10 do
  begin
    if OpenClipboard(0) then
    begin
      Result := True;
      Exit;
    end;
    Sleep(10);
  end;
end;

function EdClipboardText: WideString;
var
  DataHandle: THandle;
  DataPtr: Pointer;
  AnsiText: AnsiString;
  WideLen: Integer;
begin
  Result := '';
  if not EdOpenClipboard then
    Exit;
  try
    DataHandle := GetClipboardData(EdCfUnicodeText);
    if DataHandle <> 0 then
    begin
      DataPtr := GlobalLock(DataHandle);
      if DataPtr <> nil then
      try
        Result := PWideChar(DataPtr);
      finally
        GlobalUnlock(DataHandle);
      end;
      Exit;
    end;
    DataHandle := GetClipboardData(EdCfText);
    if DataHandle = 0 then
      Exit;
    DataPtr := GlobalLock(DataHandle);
    if DataPtr = nil then
      Exit;
    try
      AnsiText := PAnsiChar(DataPtr);
    finally
      GlobalUnlock(DataHandle);
    end;
    if AnsiText <> '' then
    begin
      WideLen := MultiByteToWideChar(CP_ACP, 0, PAnsiChar(AnsiText),
        Length(AnsiText), nil, 0);
      SetLength(Result, WideLen);
      if WideLen > 0 then
        MultiByteToWideChar(CP_ACP, 0, PAnsiChar(AnsiText), Length(AnsiText),
          PWideChar(Result), WideLen);
    end;
  finally
    CloseClipboard;
  end;
end;

procedure EdSetClipboardText(const AText: WideString);
var
  DataHandle: THandle;
  DataPtr: Pointer;
  ByteCount: Integer;
begin
  if not EdOpenClipboard then
    Exit;
  try
    EmptyClipboard;
    ByteCount := (Length(AText) + 1) * SizeOf(WideChar);
    DataHandle := GlobalAlloc(GMEM_MOVEABLE or GMEM_DDESHARE, ByteCount);
    if DataHandle = 0 then
      Exit;
    DataPtr := GlobalLock(DataHandle);
    if DataPtr = nil then
    begin
      GlobalFree(DataHandle);
      Exit;
    end;
    try
      FillChar(DataPtr^, ByteCount, 0);
      if AText <> '' then
        Move(AText[1], DataPtr^, Length(AText) * SizeOf(WideChar));
    finally
      GlobalUnlock(DataHandle);
    end;
    // CF_TEXT для старых программ Windows делает сама из CF_UNICODETEXT
    if SetClipboardData(EdCfUnicodeText, DataHandle) = 0 then
      GlobalFree(DataHandle);
  finally
    CloseClipboard;
  end;
end;
{$ELSE}
function EdClipboardText: WideString;
begin
  Result := UTF8Decode(Clipboard.AsText);
end;

procedure EdSetClipboardText(const AText: WideString);
begin
  Clipboard.AsText := UTF8Encode(AText);
end;
{$ENDIF}


end.
