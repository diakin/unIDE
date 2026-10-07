// ---------------------------------------------------------------------------
//  RqLcl: свойства и методы полей ввода, которых нет в RTTI LCL, и
//  QRICHEDIT (TRichMemo из пакета RichMemo, на Windows - окно RichEdit).
//
//  Функции EditXxx возвращают True, если свойство или метод найдены и
//  обработаны здесь; False - искать дальше по RTTI. Строки на входе и
//  выходе - в кодировке Windows, как во всём RqLcl.
//
//  SelAttributes: у каждого QRICHEDIT свой TFont (TRqRichExtra.SelFont).
//  При чтении SelAttributes он заполняется атрибутами выделения; когда
//  программа меняет его свойства, OnChange применяет к выделению только
//  то, что изменилось (у выделения с разными шрифтами меняется один
//  цвет, остальное остаётся). Без выделения - атрибуты точки ввода:
//  текст, вставленный следом, получит их.
// ---------------------------------------------------------------------------
unit rqlclrich;

{$mode objfpc}{$H+}

interface

uses
  Windows, RichEdit, Classes, SysUtils, Controls, StdCtrls, Graphics,
  LazUTF8, RichMemo;

function EditGetInt(AObj: TObject; const AProp: string;
                    out AValue: Integer): Boolean;
function EditSetInt(AObj: TObject; const AProp: string;
                    AValue: Integer): Boolean;
function EditGetStr(AObj: TObject; const AProp: string;
                    out AValue: string): Boolean;
function EditSetStr(AObj: TObject; const AProp: string;
                    const AValue: string): Boolean;
function EditCall(AObj: TObject; const AMethod: string): Boolean;
function EditCallStr(AObj: TObject; const AMethod: string;
                     const AValue: string): Boolean;
function EditGetObj(AObj: TObject; const AProp: string;
                    out AValue: TObject): Boolean;
function EditSetObj(AObj: TObject; const AProp: string;
                    AValue: TObject): Boolean;
function EditGetItem(AObj: TObject; const AProp: string; AIndex: Integer;
                     out AValue: string): Boolean;
function EditSetItem(AObj: TObject; const AProp: string; AIndex: Integer;
                     const AValue: string): Boolean;

implementation

type
  // Данные QRICHEDIT, которых нет у TRichMemo. Дочерний компонент.
  TRqRichExtra = class(TComponent)
  public
    PlainText: Boolean;
    HideScrollBars: Boolean;
    SelFont: TFont;
    PrevParams: TFontParams;     // атрибуты SelFont после последнего чтения
    InRefresh: Boolean;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SelFontChange(Sender: TObject);
    procedure Refresh;
  end;

function ExtraOf(AMemo: TCustomRichMemo): TRqRichExtra;
var
  CompIdx: Integer;
begin
  for CompIdx := 0 to AMemo.ComponentCount - 1 do
    if AMemo.Components[CompIdx] is TRqRichExtra then
    begin
      Result := TRqRichExtra(AMemo.Components[CompIdx]);
      Exit;
    end;
  Result := TRqRichExtra.Create(AMemo);
end;

// Число символов в окне RichEdit (перевод строки - один символ)
function RichLen(AMemo: TCustomRichMemo): Integer;
var
  LenInfo: GETTEXTLENGTHEX;
begin
  LenInfo.flags := GTL_DEFAULT;
  LenInfo.codepage := 1200;     // UTF-16
  Result := Integer(SendMessage(AMemo.Handle, EM_GETTEXTLENGTHEX,
                                WPARAM(@LenInfo), 0));
end;

// Вставить текст на место выделения; курсор - после него, атрибуты -
// точки ввода (как SelText в Delphi)
procedure RichReplaceSel(AMemo: TCustomRichMemo; const AText: string);
var
  WideText: UnicodeString;
begin
  WideText := UTF8Decode(WinCPToUTF8(AText));
  SendMessageW(AMemo.Handle, EM_REPLACESEL, 1, LPARAM(PWideChar(WideText)));
end;

// Строки в конец, каждая с новой строки (как Lines.Add). Выделение уже в
// конце - не трогается, чтобы не сбросить атрибуты точки ввода,
// заданные через SelAttributes.
procedure RichAddLine(AMemo: TCustomRichMemo; const AText: string);
var
  TextEnd: Integer;
  Prefix: string;
begin
  TextEnd := RichLen(AMemo);
  if (AMemo.SelStart <> TextEnd) or (AMemo.SelLength <> 0) then
  begin
    AMemo.SelStart := TextEnd;
    AMemo.SelLength := 0;
  end;
  Prefix := '';
  if (TextEnd > 0) and not (AMemo.GetUText(TextEnd - 1, 1) = #13) and
     not (AMemo.GetUText(TextEnd - 1, 1) = #10) then
    Prefix := #13#10;
  RichReplaceSel(AMemo, Prefix + AText + #13#10);
end;

// Текст из файла или потока: RTF, если начинается с {\rtf и не PlainText,
// иначе обычный текст в кодировке Windows
procedure RichLoad(AMemo: TCustomRichMemo; const AData: string);
var
  Source: TStringStream;
begin
  if not ExtraOf(AMemo).PlainText and (Copy(AData, 1, 5) = '{\rtf') then
  begin
    Source := TStringStream.Create(AData);
    try
      AMemo.Lines.Clear;
      if not AMemo.LoadRichText(Source) then
        raise Exception.Create('cannot load RTF');
    finally
      Source.Free;
    end;
  end
  else
    AMemo.Text := WinCPToUTF8(AData);
  AMemo.Modified := False;
end;

function RichSave(AMemo: TCustomRichMemo): string;
var
  Dest: TStringStream;
begin
  if ExtraOf(AMemo).PlainText then
  begin
    Result := UTF8ToWinCP(AMemo.Text);
    Exit;
  end;
  Dest := TStringStream.Create('');
  try
    if not AMemo.SaveRichText(Dest) then
      raise Exception.Create('cannot save RTF');
    Result := Dest.DataString;
  finally
    Dest.Free;
  end;
end;

function ReadWholeFile(const AFileName: string): string;
var
  Source: TFileStream;
begin
  Source := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(Result, Source.Size);
    if Length(Result) > 0 then
      Source.ReadBuffer(Result[1], Length(Result));
  finally
    Source.Free;
  end;
end;

procedure WriteWholeFile(const AFileName, AData: string);
var
  Dest: TFileStream;
begin
  Dest := TFileStream.Create(AFileName, fmCreate);
  try
    if Length(AData) > 0 then
      Dest.WriteBuffer(AData[1], Length(AData));
  finally
    Dest.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  TRqRichExtra
// ---------------------------------------------------------------------------

constructor TRqRichExtra.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SelFont := TFont.Create;
  SelFont.OnChange := @SelFontChange;
end;

destructor TRqRichExtra.Destroy;
begin
  SelFont.OnChange := nil;
  SelFont.Free;
  inherited Destroy;
end;

// SelFont <- атрибуты выделения (или точки ввода)
procedure TRqRichExtra.Refresh;
var
  Memo: TCustomRichMemo;
  Params: TFontParams;
begin
  Memo := TCustomRichMemo(Owner);
  InitFontParams(Params);
  if not Memo.GetTextAttributes(Memo.SelStart, Params) then
    Params := GetFontParams(Memo.Font);
  InRefresh := True;
  try
    SelFont.Name := Params.Name;
    SelFont.Size := Params.Size;
    SelFont.Color := Params.Color;
    SelFont.Style := Params.Style;
  finally
    InRefresh := False;
  end;
  PrevParams := Params;
end;

// Программа поменяла SelFont: к выделению - только изменённое
procedure TRqRichExtra.SelFontChange(Sender: TObject);
var
  Memo: TCustomRichMemo;
  Params: TFontParams;
  Mask: TTextModifyMask;
begin
  if InRefresh then
    Exit;
  Memo := TCustomRichMemo(Owner);
  Params := GetFontParams(SelFont);
  Mask := [];
  if Params.Name <> PrevParams.Name then
    Include(Mask, tmm_Name);
  if Params.Size <> PrevParams.Size then
    Include(Mask, tmm_Size);
  if Params.Color <> PrevParams.Color then
    Include(Mask, tmm_Color);
  if Params.Style <> PrevParams.Style then
    Include(Mask, tmm_Styles);
  if Mask = [] then
    Exit;
  if Memo.SelLength = 0 then
    // Точка ввода: SetTextAttributes на текущем выделении не двигает его
    Memo.SetTextAttributes(Memo.SelStart, 0, Params)
  else
    Memo.SetRangeParams(Memo.SelStart, Memo.SelLength, Mask, Params,
                        Params.Style, [fsBold, fsItalic, fsUnderline,
                        fsStrikeOut] - Params.Style);
  PrevParams := Params;
end;

// ---------------------------------------------------------------------------
//  Свойства и методы
// ---------------------------------------------------------------------------

function EditGetInt(AObj: TObject; const AProp: string;
                    out AValue: Integer): Boolean;
var
  Prop: string;
begin
  Result := False;
  AValue := 0;
  if not (AObj is TCustomEdit) then
    Exit;
  Prop := UpperCase(AProp);
  Result := True;
  if Prop = 'SELSTART' then
    AValue := TCustomEdit(AObj).SelStart
  else if Prop = 'SELLENGTH' then
    AValue := TCustomEdit(AObj).SelLength
  else if Prop = 'MODIFIED' then
    AValue := Ord(TCustomEdit(AObj).Modified)
  else if (AObj is TCustomMemo) and (Prop = 'LINECOUNT') then
    AValue := TCustomMemo(AObj).Lines.Count
  else if (AObj is TCustomMemo) and (Prop = 'WHEREX') then
    AValue := TCustomMemo(AObj).CaretPos.X
  else if (AObj is TCustomMemo) and (Prop = 'WHEREY') then
    AValue := TCustomMemo(AObj).CaretPos.Y
  else if (AObj is TCustomRichMemo) and (Prop = 'PLAINTEXT') then
    AValue := Ord(ExtraOf(TCustomRichMemo(AObj)).PlainText)
  else if (AObj is TCustomRichMemo) and (Prop = 'HIDESCROLLBARS') then
    AValue := Ord(ExtraOf(TCustomRichMemo(AObj)).HideScrollBars)
  else
    Result := False;
end;

function EditSetInt(AObj: TObject; const AProp: string;
                    AValue: Integer): Boolean;
var
  Prop: string;
begin
  Result := False;
  if not (AObj is TCustomEdit) then
    Exit;
  Prop := UpperCase(AProp);
  Result := True;
  if Prop = 'SELSTART' then
    TCustomEdit(AObj).SelStart := AValue
  else if Prop = 'SELLENGTH' then
    TCustomEdit(AObj).SelLength := AValue
  else if Prop = 'MODIFIED' then
    TCustomEdit(AObj).Modified := AValue <> 0
  else if (AObj is TCustomRichMemo) and (Prop = 'PLAINTEXT') then
    ExtraOf(TCustomRichMemo(AObj)).PlainText := AValue <> 0
  // RichEdit Windows прячет полосы прокрутки сам, когда они не нужны;
  // значение только запоминается
  else if (AObj is TCustomRichMemo) and (Prop = 'HIDESCROLLBARS') then
    ExtraOf(TCustomRichMemo(AObj)).HideScrollBars := AValue <> 0
  else
    Result := False;
end;

function EditGetStr(AObj: TObject; const AProp: string;
                    out AValue: string): Boolean;
var
  Prop: string;
begin
  Result := False;
  AValue := '';
  if not (AObj is TCustomEdit) then
    Exit;
  Prop := UpperCase(AProp);
  Result := True;
  if Prop = 'SELTEXT' then
    AValue := UTF8ToWinCP(TCustomEdit(AObj).SelText)
  else if (AObj is TCustomMemo) and (Prop = 'TEXT') then
    AValue := UTF8ToWinCP(TCustomMemo(AObj).Text)
  // Весь текст как RTF (PlainText - обычный): SaveToStream
  else if (AObj is TCustomRichMemo) and (Prop = 'RICHTEXT') then
    AValue := RichSave(TCustomRichMemo(AObj))
  else
    Result := False;
end;

function EditSetStr(AObj: TObject; const AProp: string;
                    const AValue: string): Boolean;
var
  Prop: string;
begin
  Result := False;
  if not (AObj is TCustomEdit) then
    Exit;
  Prop := UpperCase(AProp);
  Result := True;
  if (AObj is TCustomRichMemo) and (Prop = 'SELTEXT') then
    RichReplaceSel(TCustomRichMemo(AObj), AValue)
  else if Prop = 'SELTEXT' then
    TCustomEdit(AObj).SelText := WinCPToUTF8(AValue)
  else if (AObj is TCustomMemo) and (Prop = 'TEXT') then
    TCustomMemo(AObj).Text := WinCPToUTF8(AValue)
  // LoadFromStream: RTF или обычный текст
  else if (AObj is TCustomRichMemo) and (Prop = 'RICHTEXT') then
    RichLoad(TCustomRichMemo(AObj), AValue)
  else
    Result := False;
end;

function EditCall(AObj: TObject; const AMethod: string): Boolean;
var
  Method: string;
begin
  Result := False;
  if not (AObj is TCustomEdit) then
    Exit;
  Method := UpperCase(AMethod);
  Result := True;
  if Method = 'CLEAR' then
    TCustomEdit(AObj).Clear
  else if Method = 'SELECTALL' then
    TCustomEdit(AObj).SelectAll
  else if Method = 'COPYTOCLIPBOARD' then
    TCustomEdit(AObj).CopyToClipboard
  else if Method = 'CUTTOCLIPBOARD' then
    TCustomEdit(AObj).CutToClipboard
  else if Method = 'PASTEFROMCLIPBOARD' then
    TCustomEdit(AObj).PasteFromClipboard
  else
    Result := False;
end;

function EditCallStr(AObj: TObject; const AMethod: string;
                     const AValue: string): Boolean;
var
  Method: string;
begin
  Result := False;
  if not (AObj is TCustomMemo) then
    Exit;
  Method := UpperCase(AMethod);
  Result := True;
  if (Method = 'ADDSTRINGS') or (Method = 'ADDSTRING') then
  begin
    if AObj is TCustomRichMemo then
      RichAddLine(TCustomRichMemo(AObj), AValue)
    else
      TCustomMemo(AObj).Lines.Add(WinCPToUTF8(AValue));
  end
  else if Method = 'LOADFROMFILE' then
  begin
    if AObj is TCustomRichMemo then
      RichLoad(TCustomRichMemo(AObj), ReadWholeFile(AValue))
    else
      TCustomMemo(AObj).Text := WinCPToUTF8(ReadWholeFile(AValue));
  end
  else if Method = 'SAVETOFILE' then
  begin
    if AObj is TCustomRichMemo then
      WriteWholeFile(AValue, RichSave(TCustomRichMemo(AObj)))
    else
      WriteWholeFile(AValue, UTF8ToWinCP(TCustomMemo(AObj).Text));
  end
  else
    Result := False;
end;

function EditGetObj(AObj: TObject; const AProp: string;
                    out AValue: TObject): Boolean;
var
  Extra: TRqRichExtra;
begin
  Result := False;
  AValue := nil;
  if not (AObj is TCustomRichMemo) or
     (CompareText(AProp, 'SELATTRIBUTES') <> 0) then
    Exit;
  Extra := ExtraOf(TCustomRichMemo(AObj));
  Extra.Refresh;
  AValue := Extra.SelFont;
  Result := True;
end;

// RichEdit.SelAttributes = Font: значения шрифта - выделению
function EditSetObj(AObj: TObject; const AProp: string;
                    AValue: TObject): Boolean;
var
  Extra: TRqRichExtra;
begin
  Result := False;
  if not (AObj is TCustomRichMemo) or
     (CompareText(AProp, 'SELATTRIBUTES') <> 0) then
    Exit;
  if not (AValue is TFont) then
    raise Exception.Create('SelAttributes: value is not a QFONT');
  Extra := ExtraOf(TCustomRichMemo(AObj));
  Extra.Refresh;
  Extra.SelFont.Assign(TFont(AValue));
  Result := True;
end;

// Line(i) - строка с номером i (с 0)
function EditGetItem(AObj: TObject; const AProp: string; AIndex: Integer;
                     out AValue: string): Boolean;
var
  Memo: TCustomMemo;
begin
  Result := False;
  AValue := '';
  if not (AObj is TCustomMemo) or (CompareText(AProp, 'LINE') <> 0) then
    Exit;
  Memo := TCustomMemo(AObj);
  if (AIndex < 0) or (AIndex >= Memo.Lines.Count) then
    raise Exception.Create('Line: index ' + IntToStr(AIndex) +
                           ' out of 0..' + IntToStr(Memo.Lines.Count - 1));
  AValue := UTF8ToWinCP(Memo.Lines[AIndex]);
  Result := True;
end;

function EditSetItem(AObj: TObject; const AProp: string; AIndex: Integer;
                     const AValue: string): Boolean;
var
  Memo: TCustomMemo;
begin
  Result := False;
  if not (AObj is TCustomMemo) or (CompareText(AProp, 'LINE') <> 0) then
    Exit;
  Memo := TCustomMemo(AObj);
  if (AIndex < 0) or (AIndex >= Memo.Lines.Count) then
    raise Exception.Create('Line: index ' + IntToStr(AIndex) +
                           ' out of 0..' + IntToStr(Memo.Lines.Count - 1));
  Memo.Lines[AIndex] := WinCPToUTF8(AValue);
  Result := True;
end;

end.
