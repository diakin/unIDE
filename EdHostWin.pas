unit EdHostWin;

// ---------------------------------------------------------------------------
//  Окно своего редактора без RichEdit (план портирования, шаг 0.7.7): то,
//  что раньше за свой редактор (TEdRichEmu) делал сам RichEdit, - здесь,
//  без VCL. Свой редактор отвечает на текст, выделение, откат, строки,
//  места символов, клавиатуру и мышь; оставшиеся сообщения окна - сюда:
//    - область текста (EM_GETRECT, EM_SETRECT, EM_SETRECTNP) и поля
//      (EM_SETMARGINS, EM_GETMARGINS);
//    - маска уведомлений (EM_SETEVENTMASK, EM_GETEVENTMASK): свой редактор
//      при запуске берёт её отсюда;
//    - «только чтение» (EM_SETREADONLY) - стиль ES_READONLY;
//    - до запуска своего редактора: текст окна (WM_SETTEXT хранит
//      DefWindowProc; EM_GETTEXTEX и EM_GETTEXTLENGTHEX - из него, его
//      забирает TEdRichEmu.TakeFromWindow), выделение 0, «изменён»;
//    - системная каретка (фокус), коды клавиш (WM_GETDLGCODE), фон;
//    - остальные сообщения RichEdit (формат символов и абзацев, поля
//      печати и т.п.) - 0: оформления у своего редактора нет.
//  Окно - EdHost.TEdHostEdit (VCL); здесь только разбор сообщений, его
//  можно проверить без VCL (tests/EdRichEmu/HostTest.dpr).
// ---------------------------------------------------------------------------

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  Windows, Messages;

type
  TEdHostState = record
    TextRect: TRect;        // область текста, заданная EM_SETRECT
    RectSet: Boolean;       // False - область текста = клиентская область
    LeftMargin: Integer;    // поля EM_SETMARGINS
    RightMargin: Integer;
    EventMask: Integer;
    ReadOnly: Boolean;
    Modified: Boolean;      // до запуска своего редактора
    CaretHeight: Integer;   // высота системной каретки
  end;

procedure EdHostInit(var AState: TEdHostState);

// Сообщение окну AWnd. True - разобрано (ответ в Message.Result), False -
// дальше, обычной обработке окна (DefWindowProc)
function EdHostHandle(AWnd: HWND; var AState: TEdHostState;
  var Message: TMessage): Boolean;

implementation

const
  EM_EXGETSEL_ = WM_USER + 52;
  EM_GETEVENTMASK_ = WM_USER + 59;
  EM_SETEVENTMASK_ = WM_USER + 69;
  EM_GETTEXTEX_ = WM_USER + 94;
  EM_GETTEXTLENGTHEX_ = WM_USER + 95;
  EM_SETTEXTEX_ = WM_USER + 97;
  EM_SETMARGINS_ = $00D3;
  EM_GETMARGINS_ = $00D4;
  EC_LEFTMARGIN_ = 1;
  EC_RIGHTMARGIN_ = 2;
  CP_UNICODE_ = 1200;
  GT_USECRLF_ = 1;

type
  TEmuGetTextEx = record
    cb: DWORD;
    flags: DWORD;
    codepage: UINT;
    lpDefaultChar: PAnsiChar;
    lpUsedDefChar: PBOOL;
  end;
  PEmuGetTextEx = ^TEmuGetTextEx;
  TEmuGetTextLengthEx = record
    flags: DWORD;
    codepage: UINT;
  end;
  PEmuGetTextLengthEx = ^TEmuGetTextLengthEx;
  TEmuSetTextEx = record
    flags: DWORD;
    codepage: UINT;
  end;
  PEmuSetTextEx = ^TEmuSetTextEx;
  TEmuCharRange = record
    cpMin: Longint;
    cpMax: Longint;
  end;
  PEmuCharRange = ^TEmuCharRange;

procedure EdHostInit(var AState: TEdHostState);
begin
  FillChar(AState, SizeOf(AState), 0);
  AState.CaretHeight := 16;
end;

// Перевод строки CRLF -> CR (модель RichEdit: перевод строки - один символ)
function CrOnly(const AText: WideString): WideString;
var
  SrcIdx, DstIdx: Integer;
begin
  SetLength(Result, Length(AText));
  DstIdx := 0;
  SrcIdx := 1;
  while SrcIdx <= Length(AText) do
  begin
    Inc(DstIdx);
    Result[DstIdx] := AText[SrcIdx];
    if (AText[SrcIdx] = #13) and (SrcIdx < Length(AText)) and
       (AText[SrcIdx + 1] = #10) then
      Inc(SrcIdx);
    Inc(SrcIdx);
  end;
  SetLength(Result, DstIdx);
end;

// Текст окна (до своего редактора) в UTF-16, с CRLF как записан. Прямо у
// DefWindowProc: GetWindowText прошёл бы через оконную процедуру, а там уже
// может стоять свой редактор (TEdRichEmu.TakeFromWindow)
function WindowTextW(AWnd: HWND): WideString;
var
  TextLen: Integer;
begin
  TextLen := DefWindowProcW(AWnd, WM_GETTEXTLENGTH, 0, 0);
  SetLength(Result, TextLen + 1);
  if TextLen > 0 then
    TextLen := DefWindowProcW(AWnd, WM_GETTEXT, TextLen + 1,
      LPARAM(PWideChar(Result)));
  if TextLen < 0 then
    TextLen := 0;
  SetLength(Result, TextLen);
end;

// EM_GETTEXTEX до своего редактора: текст окна в буфер ABuffer
function GetTextEx(AWnd: HWND; const AInfo: TEmuGetTextEx;
  ABuffer: Pointer): Integer;
var
  Text: WideString;
  AnsiText: AnsiString;
  MaxChars: Integer;
begin
  Result := 0;
  if (ABuffer = nil) or (AInfo.cb = 0) then
    Exit;
  Text := WindowTextW(AWnd);
  if AInfo.flags and GT_USECRLF_ = 0 then
    Text := CrOnly(Text);
  if AInfo.codepage = CP_UNICODE_ then
  begin
    MaxChars := Integer(AInfo.cb div 2) - 1;
    if MaxChars < 0 then
      Exit;
    Result := Length(Text);
    if Result > MaxChars then
      Result := MaxChars;
    if Result > 0 then
      Move(Text[1], ABuffer^, Result * 2);
    PWideChar(ABuffer)[Result] := #0;
  end
  else
  begin
    AnsiText := AnsiString(Text);
    MaxChars := Integer(AInfo.cb) - 1;
    Result := Length(AnsiText);
    if Result > MaxChars then
      Result := MaxChars;
    if Result > 0 then
      Move(AnsiText[1], ABuffer^, Result);
    PAnsiChar(ABuffer)[Result] := #0;
  end;
end;

function GetTextLengthEx(AWnd: HWND; const AInfo: TEmuGetTextLengthEx): Integer;
var
  Text: WideString;
begin
  Text := WindowTextW(AWnd);
  if AInfo.flags and GT_USECRLF_ = 0 then
    Text := CrOnly(Text);
  if AInfo.codepage = CP_UNICODE_ then
    Result := Length(Text)
  else
    Result := Length(AnsiString(Text));
end;

function EdHostHandle(AWnd: HWND; var AState: TEdHostState;
  var Message: TMessage): Boolean;
var
  RectPtr: PRect;
  Range: PEmuCharRange;
  OldMask, Style: Integer;
begin
  Result := True;
  case Message.Msg of
    // --- Область текста и поля ---
    EM_GETRECT:
      begin
        RectPtr := PRect(Message.LParam);
        if RectPtr <> nil then
        begin
          if AState.RectSet then
            RectPtr^ := AState.TextRect
          else
          begin
            if (AWnd = 0) or not GetClientRect(AWnd, RectPtr^) then
              SetRectEmpty(RectPtr^);
            Inc(RectPtr^.Left, AState.LeftMargin);
            Dec(RectPtr^.Right, AState.RightMargin);
          end;
        end;
        Message.Result := 0;
      end;
    EM_SETRECT, EM_SETRECTNP:
      begin
        RectPtr := PRect(Message.LParam);
        if RectPtr = nil then
          AState.RectSet := False
        else
        begin
          AState.TextRect := RectPtr^;
          AState.RectSet := True;
        end;
        if (Message.Msg = EM_SETRECT) and (AWnd <> 0) then
          InvalidateRect(AWnd, nil, False);
        Message.Result := 0;
      end;
    EM_SETMARGINS_:
      begin
        if Message.WParam and EC_LEFTMARGIN_ <> 0 then
          AState.LeftMargin := LoWord(Message.LParam);
        if Message.WParam and EC_RIGHTMARGIN_ <> 0 then
          AState.RightMargin := HiWord(Message.LParam);
        Message.Result := 0;
      end;
    EM_GETMARGINS_:
      Message.Result := MakeLong(Word(AState.LeftMargin),
        Word(AState.RightMargin));

    // --- Уведомления и «только чтение» ---
    EM_SETEVENTMASK_:
      begin
        OldMask := AState.EventMask;
        AState.EventMask := Message.LParam;
        Message.Result := OldMask;
      end;
    EM_GETEVENTMASK_:
      Message.Result := AState.EventMask;
    EM_SETREADONLY:
      begin
        AState.ReadOnly := Message.WParam <> 0;
        if AWnd <> 0 then
        begin
          Style := GetWindowLong(AWnd, GWL_STYLE);
          if AState.ReadOnly then
            Style := Style or ES_READONLY
          else
            Style := Style and not ES_READONLY;
          SetWindowLong(AWnd, GWL_STYLE, Style);
        end;
        Message.Result := 1;
      end;

    // --- До своего редактора: текст окна, выделение, «изменён» ---
    EM_GETTEXTEX_:
      Message.Result := GetTextEx(AWnd, PEmuGetTextEx(Message.WParam)^,
        Pointer(Message.LParam));
    EM_GETTEXTLENGTHEX_:
      Message.Result := GetTextLengthEx(AWnd,
        PEmuGetTextLengthEx(Message.WParam)^);
    EM_SETTEXTEX_:
      begin
        // Мимо оконной процедуры - как в WindowTextW
        if (Message.WParam <> 0) and
           (PEmuSetTextEx(Message.WParam)^.codepage = CP_UNICODE_) then
          DefWindowProcW(AWnd, WM_SETTEXT, 0, Message.LParam)
        else
          DefWindowProcA(AWnd, WM_SETTEXT, 0, Message.LParam);
        Message.Result := 1;
      end;
    EM_EXGETSEL_:
      begin
        Range := PEmuCharRange(Message.LParam);
        if Range <> nil then
        begin
          Range^.cpMin := 0;
          Range^.cpMax := 0;
        end;
        Message.Result := 0;
      end;
    EM_GETSEL:
      begin
        if Message.WParam <> 0 then
          PDWORD(Message.WParam)^ := 0;
        if Message.LParam <> 0 then
          PDWORD(Message.LParam)^ := 0;
        Message.Result := 0;
      end;
    EM_GETMODIFY:
      Message.Result := Ord(AState.Modified);
    EM_SETMODIFY:
      begin
        AState.Modified := Message.WParam <> 0;
        Message.Result := 0;
      end;

    // --- Окно ---
    WM_GETDLGCODE:
      Message.Result := DLGC_WANTARROWS or DLGC_WANTTAB or DLGC_WANTCHARS or
        DLGC_WANTALLKEYS;
    WM_ERASEBKGND:
      // Фон рисует отрисовка Unit1 вместе с текстом
      Message.Result := 1;
    WM_SETFOCUS:
      begin
        // Системная каретка: по ней место ввода находят индикатор
        // раскладки и IME; видимую каретку рисует Unit1
        CreateCaret(AWnd, 0, 1, AState.CaretHeight);
        ShowCaret(AWnd);
        Result := False;
      end;
    WM_KILLFOCUS:
      begin
        DestroyCaret;
        Result := False;
      end;
  else
    // Остальные сообщения RichEdit и поля ввода - ответ 0, без DefWindowProc
    Result := ((Message.Msg >= WM_USER) and (Message.Msg < WM_USER + $200)) or
      ((Message.Msg >= EM_GETSEL) and (Message.Msg <= $00DA));
    if Result then
      Message.Result := 0;
  end;
end;

end.
