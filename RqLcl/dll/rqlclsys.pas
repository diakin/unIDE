// ---------------------------------------------------------------------------
//  RqLcl: QOPENDIALOG / QSAVEDIALOG (TOpenDialog / TSaveDialog) и
//  глобальные объекты RapidQ Application, Screen, Clipboard
//  (TApplication, TScreen, TClipboard LCL) - свойства и методы, которых нет
//  в RTTI LCL или которые у RapidQ называются иначе.
//
//  Глобальные объекты не создаются: RqCreate("QAPPLICATION" / "QSCREEN" /
//  "QCLIPBOARD") возвращает объект LCL, RqFree его не освобождает.
// ---------------------------------------------------------------------------
unit rqlclsys;

{$mode objfpc}{$H+}

interface

uses
  Windows, Classes, SysUtils, Controls, Forms, Dialogs, ExtCtrls, Clipbrd,
  Graphics, LCLType, LazUTF8;

// Глобальный объект по имени класса RapidQ (nil - не глобальный)
function SysGlobalObject(const AClassName: string): TObject;
function SysIsGlobal(AObj: TObject): Boolean;

function SysGetInt(AObj: TObject; const AProp: string;
                   out AValue: Integer): Boolean;
function SysSetInt(AObj: TObject; const AProp: string;
                   AValue: Integer): Boolean;
function SysGetStr(AObj: TObject; const AProp: string;
                   out AValue: string): Boolean;
function SysSetStr(AObj: TObject; const AProp: string;
                   const AValue: string): Boolean;
// Метод без параметров; AResult - его значение (Execute: 1 - выбрано)
function SysCall(AObj: TObject; const AMethod: string;
                 out AResult: Integer): Boolean;
// Метод с целым параметром (Clipboard.HasFormat)
function SysCallInt(AObj: TObject; const AMethod: string; AValue: Integer;
                    out AResult: Integer): Boolean;

implementation

function SysGlobalObject(const AClassName: string): TObject;
var
  Name: string;
begin
  Result := nil;
  Name := UpperCase(AClassName);
  if Name = 'QAPPLICATION' then
    Result := Application
  else if Name = 'QSCREEN' then
    Result := Screen
  else if Name = 'QCLIPBOARD' then
    Result := Clipboard;
end;

function SysIsGlobal(AObj: TObject): Boolean;
begin
  Result := (AObj <> nil) and ((AObj = Application) or (AObj = Screen) or
            (AObj is TClipboard));
end;

function SysGetInt(AObj: TObject; const AProp: string;
                   out AValue: Integer): Boolean;
var
  Prop: string;
  MousePos: TPoint;
begin
  Result := False;
  AValue := 0;
  Prop := UpperCase(AProp);
  if AObj is TApplication then
  begin
    Result := True;
    if Prop = 'HINTCOLOR' then
      AValue := Integer(Application.HintColor)
    else if Prop = 'HINTPAUSE' then
      AValue := Application.HintPause
    else if Prop = 'HINTHIDEPAUSE' then
      AValue := Application.HintHidePause
    else if Prop = 'HINTSHORTPAUSE' then
      AValue := Application.HintShortPause
    else if Prop = 'SHOWHINT' then
      AValue := Ord(Application.ShowHint)
    else
      Result := False;
  end
  else if AObj is TScreen then
  begin
    Result := True;
    if Prop = 'WIDTH' then
      AValue := Screen.Width
    else if Prop = 'HEIGHT' then
      AValue := Screen.Height
    else if Prop = 'CURSOR' then
      AValue := Integer(Screen.Cursor)
    else if (Prop = 'MOUSEX') or (Prop = 'MOUSEY') then
    begin
      MousePos := Mouse.CursorPos;
      if Prop = 'MOUSEX' then
        AValue := MousePos.X
      else
        AValue := MousePos.Y;
    end
    else
      Result := False;
  end
  else if AObj is TClipboard then
  begin
    // число форматов в буфере обмена Windows
    if Prop = 'FORMATCOUNT' then
    begin
      AValue := CountClipboardFormats;
      Result := True;
    end;
  end;
end;

function SysSetInt(AObj: TObject; const AProp: string;
                   AValue: Integer): Boolean;
var
  Prop: string;
begin
  Result := False;
  Prop := UpperCase(AProp);
  if AObj is TApplication then
  begin
    Result := True;
    if Prop = 'HINTCOLOR' then
      Application.HintColor := TColor(AValue)
    else if Prop = 'HINTPAUSE' then
      Application.HintPause := AValue
    else if Prop = 'HINTHIDEPAUSE' then
      Application.HintHidePause := AValue
    else if Prop = 'HINTSHORTPAUSE' then
      Application.HintShortPause := AValue
    else if Prop = 'SHOWHINT' then
      Application.ShowHint := AValue <> 0
    else
      Result := False;
  end
  else if AObj is TScreen then
  begin
    if Prop = 'CURSOR' then
    begin
      Screen.Cursor := TCursor(AValue);
      Result := True;
    end;
  end;
end;

function SysGetStr(AObj: TObject; const AProp: string;
                   out AValue: string): Boolean;
var
  Prop: string;
begin
  Result := False;
  AValue := '';
  Prop := UpperCase(AProp);
  if AObj is TApplication then
  begin
    Result := True;
    // RapidQ: имя exe без пути (путь - COMMAND$(0))
    if Prop = 'EXENAME' then
      AValue := UTF8ToWinCP(ExtractFileName(Application.ExeName))
    else if Prop = 'TITLE' then
      AValue := UTF8ToWinCP(Application.Title)
    else if Prop = 'HELPFILE' then
      AValue := UTF8ToWinCP(Application.HelpFile)
    else
      Result := False;
  end
  else if (AObj is TClipboard) and (Prop = 'TEXT') then
  begin
    AValue := UTF8ToWinCP(TClipboard(AObj).AsText);
    Result := True;
  end
  // Заголовок окна диалога: Caption у RapidQ, Title у LCL
  else if (AObj is TCommonDialog) and (Prop = 'CAPTION') then
  begin
    AValue := UTF8ToWinCP(TCommonDialog(AObj).Title);
    Result := True;
  end;
end;

function SysSetStr(AObj: TObject; const AProp: string;
                   const AValue: string): Boolean;
var
  Prop: string;
begin
  Result := False;
  Prop := UpperCase(AProp);
  if AObj is TApplication then
  begin
    Result := True;
    if Prop = 'TITLE' then
      Application.Title := WinCPToUTF8(AValue)
    else if Prop = 'HELPFILE' then
      Application.HelpFile := WinCPToUTF8(AValue)
    else if Prop = 'ICON' then
      Application.Icon.LoadFromFile(WinCPToUTF8(AValue))
    else
      Result := False;
  end
  else if (AObj is TClipboard) and (Prop = 'TEXT') then
  begin
    TClipboard(AObj).AsText := WinCPToUTF8(AValue);
    Result := True;
  end
  else if (AObj is TCommonDialog) and (Prop = 'CAPTION') then
  begin
    TCommonDialog(AObj).Title := WinCPToUTF8(AValue);
    Result := True;
  end;
end;

function SysCall(AObj: TObject; const AMethod: string;
                 out AResult: Integer): Boolean;
var
  Method: string;
begin
  Result := False;
  AResult := 1;
  Method := UpperCase(AMethod);
  if (AObj is TCommonDialog) and (Method = 'EXECUTE') then
  begin
    AResult := Ord(TCommonDialog(AObj).Execute);
    Result := True;
  end
  else if AObj is TApplication then
  begin
    Result := True;
    if Method = 'TERMINATE' then
      Application.Terminate
    else if Method = 'MINIMIZE' then
      Application.Minimize
    else if Method = 'RESTORE' then
      Application.Restore
    else
      Result := False;
  end
  else if AObj is TClipboard then
  begin
    Result := True;
    if Method = 'CLEAR' then
      TClipboard(AObj).Clear
    else if Method = 'OPEN' then
      TClipboard(AObj).Open
    else if Method = 'CLOSE' then
      TClipboard(AObj).Close
    else
      Result := False;
  end;
end;

function SysCallInt(AObj: TObject; const AMethod: string; AValue: Integer;
                    out AResult: Integer): Boolean;
begin
  Result := False;
  AResult := 0;
  if (AObj is TClipboard) and (UpperCase(AMethod) = 'HASFORMAT') then
  begin
    // номер формата Windows (CF_TEXT = 1...), как в RapidQ
    AResult := Ord(IsClipboardFormatAvailable(UINT(AValue)));
    Result := True;
  end;
end;

end.
