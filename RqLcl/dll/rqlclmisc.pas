// ---------------------------------------------------------------------------
//  RqLcl: меню (QMAINMENU, QMENUITEM, QPOPUPMENU), списки (QLISTBOX,
//  QCOMBOBOX), QCOOLBTN, а также общие свойства элементов, которых нет в
//  RTTI LCL (ClientWidth, ClientHeight).
//
//  Функции MiscXxx возвращают True, если свойство или метод обработаны
//  здесь; False - искать дальше. Строки - в кодировке Windows.
// ---------------------------------------------------------------------------
unit rqlclmisc;

{$mode objfpc}{$H+}

interface

uses
  Windows, Classes, SysUtils, Controls, StdCtrls, ExtCtrls, Buttons, Menus,
  Forms, Graphics, LCLProc, LCLType, LazUTF8;

// Ресурс $RESOURCE программы (RCDATA с номером в exe, содержимое - файл
// как есть) - поток; нет такого ресурса - nil
function MiscResourceStream(AResId: Integer): TStream;
// Кэш картинок RapidQ (глава 8): GetBMP / чтение BMP кладут сюда,
// BMP = "" берёт отсюда
function MiscBmpCache: TBitmap;
function MiscIcoCache: TIcon;

function MiscGetInt(AObj: TObject; const AProp: string;
                    out AValue: Integer): Boolean;
function MiscSetInt(AObj: TObject; const AProp: string;
                    AValue: Integer): Boolean;
function MiscGetStr(AObj: TObject; const AProp: string;
                    out AValue: string): Boolean;
function MiscSetStr(AObj: TObject; const AProp: string;
                    const AValue: string): Boolean;
function MiscGetItem(AObj: TObject; const AProp: string; AIndex: Integer;
                     out AValue: string): Boolean;
function MiscSetItem(AObj: TObject; const AProp: string; AIndex: Integer;
                     const AValue: string): Boolean;
function MiscGetItemInt(AObj: TObject; const AProp: string; AIndex: Integer;
                        out AValue: Integer): Boolean;
function MiscSetItemInt(AObj: TObject; const AProp: string; AIndex: Integer;
                        AValue: Integer): Boolean;
function MiscSetObj(AObj: TObject; const AProp: string;
                    AValue: TObject): Boolean;
// Метод со строкой и до трёх целых (как GridCallEx)
function MiscCallEx(AObj: TObject; const AMethod, AStr: string;
                    AInt1, AInt2, AInt3: Integer;
                    out AIntResult: Integer): Boolean;
// Метод с объектом и целым: AddItems, DelItems, Insert у меню
function MiscCallObj(AObj: TObject; const AMethod: string; AOther: TObject;
                     AInt: Integer): Boolean;
// Холст элемента для рисования (таблица, список, комбобокс); nil - нет
function CanvasOf(AObj: TObject): TCanvas;

implementation

uses
  Grids;

var
  BmpCacheObj: TBitmap = nil;
  IcoCacheObj: TIcon = nil;

function MiscBmpCache: TBitmap;
begin
  if BmpCacheObj = nil then
    BmpCacheObj := TBitmap.Create;
  Result := BmpCacheObj;
end;

function MiscIcoCache: TIcon;
begin
  if IcoCacheObj = nil then
    IcoCacheObj := TIcon.Create;
  Result := IcoCacheObj;
end;

function MiscResourceStream(AResId: Integer): TStream;
var
  ExeModule: HMODULE;
begin
  Result := nil;
  if (AResId <= 0) or (AResId > $FFFF) then
    Exit;
  ExeModule := GetModuleHandle(nil);
  if FindResource(ExeModule, MAKEINTRESOURCE(AResId), RT_RCDATA) = 0 then
    Exit;
  Result := TResourceStream.CreateFromID(ExeModule, AResId, RT_RCDATA);
end;

// Картинка кнопки QCOOLBTN (TSpeedButton) / QBUTTON (TBitBtn); нет - nil
function GlyphOf(AObj: TObject): TBitmap;
begin
  Result := nil;
  if AObj is TSpeedButton then
    Result := TSpeedButton(AObj).Glyph
  else if AObj is TCustomBitBtn then
    Result := TCustomBitBtn(AObj).Glyph;
end;

// BMPHandle = ресурс $RESOURCE (номер RCDATA в exe, документация RapidQ:
// тип RESOURCE); не ресурс - HBITMAP
procedure SetGlyphHandle(AObj: TObject; AValue: Integer);
var
  Glyph: TBitmap;
  ResStream: TStream;
begin
  Glyph := TBitmap.Create;
  try
    ResStream := MiscResourceStream(AValue);
    if ResStream <> nil then
      try
        Glyph.LoadFromStream(ResStream);
      finally
        ResStream.Free;
      end
    else
      Glyph.Handle := HBITMAP(PtrInt(AValue));
    if AObj is TSpeedButton then
      TSpeedButton(AObj).Glyph := Glyph
    else
      TCustomBitBtn(AObj).Glyph := Glyph;
  finally
    Glyph.Free;
  end;
end;

function ListOf(AObj: TObject): TStrings;
begin
  Result := nil;
  if AObj is TCustomListBox then
    Result := TCustomListBox(AObj).Items
  else if AObj is TCustomComboBox then
    Result := TCustomComboBox(AObj).Items;
end;

function CanvasOf(AObj: TObject): TCanvas;
begin
  Result := nil;
  if AObj is TCustomGrid then
    Result := TStringGrid(AObj).Canvas
  else if AObj is TCustomListBox then
    Result := TCustomListBox(AObj).Canvas
  else if AObj is TCustomComboBox then
    Result := TCustomComboBox(AObj).Canvas
  else if AObj is TCustomForm then
    Result := TCustomForm(AObj).Canvas
  // QIMAGE: холст картинки (LCL создаёт картинку размером с элемент)
  else if AObj is TImage then
    Result := TImage(AObj).Canvas;
end;

procedure CheckIndex(const AWhat: string; AIndex, ACount: Integer);
begin
  if (AIndex < 0) or (AIndex >= ACount) then
    raise Exception.Create(AWhat + '(' + IntToStr(AIndex) + '): out of 0..' +
                           IntToStr(ACount - 1));
end;

// Меню: пункты верхнего уровня у TMainMenu/TPopupMenu, подпункты у TMenuItem
function MenuItemsOf(AObj: TObject): TMenuItem;
begin
  Result := nil;
  if AObj is TMenuItem then
    Result := TMenuItem(AObj)
  else if AObj is TMenu then
    Result := TMenu(AObj).Items;
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

function MiscGetInt(AObj: TObject; const AProp: string;
                    out AValue: Integer): Boolean;
var
  Prop: string;
  Items: TStrings;
begin
  Result := False;
  AValue := 0;
  Prop := UpperCase(AProp);
  Items := ListOf(AObj);
  if (Items <> nil) and (Prop = 'ITEMCOUNT') then
  begin
    AValue := Items.Count;
    Result := True;
  end
  // ItemIndex не у всех списков published (TFileListBox)
  else if (AObj is TCustomListBox) and (Prop = 'ITEMINDEX') then
  begin
    AValue := TCustomListBox(AObj).ItemIndex;
    Result := True;
  end
  else if (AObj is TCustomComboBox) and (Prop = 'ITEMINDEX') then
  begin
    AValue := TCustomComboBox(AObj).ItemIndex;
    Result := True;
  end
  else if (AObj is TCustomListBox) and (Prop = 'SELCOUNT') then
  begin
    AValue := TCustomListBox(AObj).SelCount;
    Result := True;
  end
  else if (AObj is TCustomListBox) and (Prop = 'TOPINDEX') then
  begin
    AValue := TCustomListBox(AObj).TopIndex;
    Result := True;
  end
  else if (AObj is TMenuItem) and (Prop = 'MENUINDEX') then
  begin
    AValue := TMenuItem(AObj).MenuIndex;
    Result := True;
  end
  else if (AObj is TMenuItem) and (Prop = 'COUNT') then
  begin
    AValue := TMenuItem(AObj).Count;
    Result := True;
  end
  else if (AObj is TMenuItem) and (Prop = 'COMMAND') then
  begin
    AValue := TMenuItem(AObj).Command;
    Result := True;
  end
  else if (AObj is TSpeedButton) and (Prop = 'NUMBMPS') then
  begin
    AValue := TSpeedButton(AObj).NumGlyphs;
    Result := True;
  end
  else if (AObj is TCustomBitBtn) and (Prop = 'NUMBMPS') then
  begin
    AValue := TCustomBitBtn(AObj).NumGlyphs;
    Result := True;
  end
  else if (AObj is TControl) and (Prop = 'CLIENTWIDTH') then
  begin
    AValue := TControl(AObj).ClientWidth;
    Result := True;
  end
  // Color есть у всех элементов, но не везде published (TTabControl)
  else if (AObj is TControl) and (Prop = 'COLOR') then
  begin
    AValue := Integer(TControl(AObj).Color);
    Result := True;
  end
  else if (AObj is TControl) and (Prop = 'CLIENTHEIGHT') then
  begin
    AValue := TControl(AObj).ClientHeight;
    Result := True;
  end
  // Align, Tag, TabOrder - у всех элементов (не у всех классов LCL
  // published: TabOrder нет у TSpeedButton, TLabel)
  else if (AObj is TControl) and (Prop = 'ALIGN') then
  begin
    AValue := Ord(TControl(AObj).Align);
    Result := True;
  end
  else if (AObj is TComponent) and (Prop = 'TAG') then
  begin
    AValue := Integer(TComponent(AObj).Tag);
    Result := True;
  end
  else if (AObj is TControl) and (Prop = 'TABORDER') then
  begin
    if AObj is TWinControl then
      AValue := TWinControl(AObj).TabOrder
    else
      AValue := -1;
    Result := True;
  end;
end;

function MiscSetInt(AObj: TObject; const AProp: string;
                    AValue: Integer): Boolean;
var
  Prop: string;
  ResStream: TStream;
begin
  Result := False;
  Prop := UpperCase(AProp);
  if (AObj is TCustomListBox) and (Prop = 'ITEMINDEX') then
  begin
    TCustomListBox(AObj).ItemIndex := AValue;
    Result := True;
  end
  else if (AObj is TCustomComboBox) and (Prop = 'ITEMINDEX') then
  begin
    TCustomComboBox(AObj).ItemIndex := AValue;
    Result := True;
  end
  else if (AObj is TCustomListBox) and (Prop = 'TOPINDEX') then
  begin
    TCustomListBox(AObj).TopIndex := AValue;
    Result := True;
  end
  else if (AObj is TMenuItem) and (Prop = 'MENUINDEX') then
  begin
    TMenuItem(AObj).MenuIndex := AValue;
    Result := True;
  end
  else if (AObj is TSpeedButton) and (Prop = 'NUMBMPS') then
  begin
    TSpeedButton(AObj).NumGlyphs := AValue;
    Result := True;
  end
  else if (AObj is TCustomBitBtn) and (Prop = 'NUMBMPS') then
  begin
    TCustomBitBtn(AObj).NumGlyphs := AValue;
    Result := True;
  end
  else if (GlyphOf(AObj) <> nil) and (Prop = 'BMPHANDLE') then
  begin
    SetGlyphHandle(AObj, AValue);
    Result := True;
  end
  // QFORM.ICOHandle = ресурс $RESOURCE с файлом .ico
  else if (AObj is TCustomForm) and (Prop = 'ICOHANDLE') then
  begin
    ResStream := MiscResourceStream(AValue);
    if ResStream = nil then
      raise Exception.Create('ICOHandle: no resource ' + IntToStr(AValue));
    try
      TCustomForm(AObj).Icon.LoadFromStream(ResStream);
    finally
      ResStream.Free;
    end;
    Result := True;
  end
  else if (AObj is TControl) and (Prop = 'CLIENTWIDTH') then
  begin
    TControl(AObj).ClientWidth := AValue;
    Result := True;
  end
  else if (AObj is TControl) and (Prop = 'COLOR') then
  begin
    TControl(AObj).Color := TColor(AValue);
    Result := True;
  end
  else if (AObj is TControl) and (Prop = 'CLIENTHEIGHT') then
  begin
    TControl(AObj).ClientHeight := AValue;
    Result := True;
  end
  else if (AObj is TControl) and (Prop = 'ALIGN') then
  begin
    if (AValue < Ord(Low(TAlign))) or (AValue > Ord(High(TAlign))) then
      raise Exception.CreateFmt('Align: %d - out of range', [AValue]);
    TControl(AObj).Align := TAlign(AValue);
    Result := True;
  end
  else if (AObj is TComponent) and (Prop = 'TAG') then
  begin
    TComponent(AObj).Tag := AValue;
    Result := True;
  end
  else if (AObj is TControl) and (Prop = 'TABORDER') then
  begin
    // у элемента без окна (QLABEL, QCOOLBTN) TabOrder нет - пропускается
    if AObj is TWinControl then
      TWinControl(AObj).TabOrder := TTabOrder(AValue);
    Result := True;
  end;
end;

function MiscGetStr(AObj: TObject; const AProp: string;
                    out AValue: string): Boolean;
var
  Prop: string;
  Items: TStrings;
begin
  Result := False;
  AValue := '';
  Prop := UpperCase(AProp);
  Items := ListOf(AObj);
  if (AObj is TCustomListBox) and (Prop = 'TEXT') then
  begin
    // строки списка через CR LF
    AValue := UTF8ToWinCP(Items.Text);
    Result := True;
  end
  else if (AObj is TMenuItem) and (Prop = 'SHORTCUT') then
  begin
    AValue := UTF8ToWinCP(ShortCutToTextRaw(TMenuItem(AObj).ShortCut));
    Result := True;
  end;
end;

function MiscSetStr(AObj: TObject; const AProp: string;
                    const AValue: string): Boolean;
var
  Prop: string;
  Items: TStrings;
begin
  Result := False;
  Prop := UpperCase(AProp);
  Items := ListOf(AObj);
  if (AObj is TCustomListBox) and (Prop = 'TEXT') then
  begin
    Items.Text := WinCPToUTF8(AValue);
    Result := True;
  end
  else if (AObj is TMenuItem) and (Prop = 'SHORTCUT') then
  begin
    // "Ctrl+O", "F5"...; названия клавиш - английские, как в Delphi
    TMenuItem(AObj).ShortCut := TextToShortCutRaw(AValue);
    if (TMenuItem(AObj).ShortCut = 0) and (AValue <> '') then
      raise Exception.Create('ShortCut: unknown key combination "' + AValue + '"');
    Result := True;
  end
  else if (GlyphOf(AObj) <> nil) and (Prop = 'BMP') then
  begin
    // файл .bmp - картинка кнопки (имя - в кодировке Windows); "" - кэш
    if AValue = '' then
      GlyphOf(AObj).Assign(MiscBmpCache)
    else
      GlyphOf(AObj).LoadFromFile(WinCPToUTF8(AValue));
    Result := True;
  end;
end;

// Item(i) у QLISTBOX и QCOMBOBOX
function MiscGetItem(AObj: TObject; const AProp: string; AIndex: Integer;
                     out AValue: string): Boolean;
var
  Items: TStrings;
begin
  Result := False;
  AValue := '';
  Items := ListOf(AObj);
  if (Items = nil) or (CompareText(AProp, 'ITEM') <> 0) then
    Exit;
  CheckIndex('Item', AIndex, Items.Count);
  AValue := UTF8ToWinCP(Items[AIndex]);
  Result := True;
end;

function MiscSetItem(AObj: TObject; const AProp: string; AIndex: Integer;
                     const AValue: string): Boolean;
var
  Items: TStrings;
begin
  Result := False;
  Items := ListOf(AObj);
  if (Items = nil) or (CompareText(AProp, 'ITEM') <> 0) then
    Exit;
  CheckIndex('Item', AIndex, Items.Count);
  Items[AIndex] := WinCPToUTF8(AValue);
  Result := True;
end;

// Selected(i) у QLISTBOX
function MiscGetItemInt(AObj: TObject; const AProp: string; AIndex: Integer;
                        out AValue: Integer): Boolean;
begin
  Result := False;
  AValue := 0;
  if not (AObj is TCustomListBox) or (CompareText(AProp, 'SELECTED') <> 0) then
    Exit;
  CheckIndex('Selected', AIndex, TCustomListBox(AObj).Items.Count);
  AValue := Ord(TCustomListBox(AObj).Selected[AIndex]);
  Result := True;
end;

function MiscSetItemInt(AObj: TObject; const AProp: string; AIndex: Integer;
                        AValue: Integer): Boolean;
begin
  Result := False;
  if not (AObj is TCustomListBox) or (CompareText(AProp, 'SELECTED') <> 0) then
    Exit;
  CheckIndex('Selected', AIndex, TCustomListBox(AObj).Items.Count);
  TCustomListBox(AObj).Selected[AIndex] := AValue <> 0;
  Result := True;
end;

// MainMenu.Parent = Form: меню формы
function MiscSetObj(AObj: TObject; const AProp: string;
                    AValue: TObject): Boolean;
begin
  Result := False;
  if (AObj is TMainMenu) and (CompareText(AProp, 'PARENT') = 0) then
  begin
    if not (AValue is TCustomForm) then
      raise Exception.Create('QMAINMENU.Parent: not a form');
    TCustomForm(AValue).Menu := TMainMenu(AObj);
    Result := True;
  end;
end;

function MiscCallEx(AObj: TObject; const AMethod, AStr: string;
                    AInt1, AInt2, AInt3: Integer;
                    out AIntResult: Integer): Boolean;
var
  Method: string;
  Items: TStrings;
  Canvas: TCanvas;
  MenuItems: TMenuItem;
begin
  Result := False;
  AIntResult := 1;
  Method := UpperCase(AMethod);
  Items := ListOf(AObj);
  if Items <> nil then
  begin
    Result := True;
    if Method = 'ADDITEMS' then
      Items.Add(WinCPToUTF8(AStr))
    else if Method = 'DELITEMS' then
    begin
      CheckIndex('DelItems', AInt1, Items.Count);
      Items.Delete(AInt1);
    end
    else if Method = 'INSERTITEM' then
    begin
      // вставка в конец (номер = ItemCount) допустима
      if (AInt1 < 0) or (AInt1 > Items.Count) then
        CheckIndex('InsertItem', AInt1, Items.Count);
      Items.Insert(AInt1, WinCPToUTF8(AStr));
    end
    else if Method = 'CLEAR' then
      Items.Clear
    else if Method = 'LOADFROMFILE' then
      Items.Text := WinCPToUTF8(ReadWholeFile(AStr))
    else if Method = 'SAVETOFILE' then
      WriteWholeFile(AStr, UTF8ToWinCP(Items.Text))
    else
      Result := False;
    if Result then
      Exit;
  end;
  if (Method = 'TEXTWIDTH') or (Method = 'TEXTHEIGHT') then
  begin
    Canvas := CanvasOf(AObj);
    if Canvas <> nil then
    begin
      if Method = 'TEXTWIDTH' then
        AIntResult := Canvas.TextWidth(WinCPToUTF8(AStr))
      else
        AIntResult := Canvas.TextHeight(WinCPToUTF8(AStr));
      Result := True;
      Exit;
    end;
  end;
  if (AObj is TPopupMenu) and (Method = 'POPUP') then
  begin
    TPopupMenu(AObj).PopUp(AInt1, AInt2);
    Result := True;
    Exit;
  end;
  MenuItems := MenuItemsOf(AObj);
  if (MenuItems <> nil) and (Method = 'DELINDEX') then
  begin
    CheckIndex('DelIndex', AInt1, MenuItems.Count);
    MenuItems.Delete(AInt1);
    Result := True;
  end;
end;

function MiscCallObj(AObj: TObject; const AMethod: string; AOther: TObject;
                     AInt: Integer): Boolean;
var
  Method: string;
  MenuItems: TMenuItem;
begin
  Result := False;
  Method := UpperCase(AMethod);
  MenuItems := MenuItemsOf(AObj);
  if MenuItems = nil then
    Exit;
  if not (AOther is TMenuItem) then
    raise Exception.Create(AMethod + ': not a QMENUITEM');
  if Method = 'ADDITEMS' then
  begin
    // пункт уже в другом меню - перенести
    if TMenuItem(AOther).Parent <> nil then
      TMenuItem(AOther).Parent.Remove(TMenuItem(AOther));
    MenuItems.Add(TMenuItem(AOther));
    Result := True;
  end
  else if Method = 'DELITEMS' then
  begin
    if TMenuItem(AOther).Parent = MenuItems then
      MenuItems.Remove(TMenuItem(AOther));
    Result := True;
  end
  else if Method = 'INSERT' then
  begin
    if (AInt < 0) or (AInt > MenuItems.Count) then
      CheckIndex('Insert', AInt, MenuItems.Count);
    if TMenuItem(AOther).Parent <> nil then
      TMenuItem(AOther).Parent.Remove(TMenuItem(AOther));
    MenuItems.Insert(AInt, TMenuItem(AOther));
    Result := True;
  end;
end;

finalization
  FreeAndNil(BmpCacheObj);
  FreeAndNil(IcoCacheObj);
end.
