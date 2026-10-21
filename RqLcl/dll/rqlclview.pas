// ---------------------------------------------------------------------------
//  RqLcl: QLISTVIEW (TListView) и QFONTDIALOG (TFontDialog) - свойства и
//  методы, которых нет в RTTI LCL или которые у RapidQ другие.
//
//  Пункты и столбцы QLISTVIEW - по номеру: "Item.Caption", "Item.Checked",
//  "Column.Width"... через RqGetItemStr / RqGetItemInt; SubItem(Index,
//  SubIndex) - через RqGetCell / RqSetCell (ACol = SubIndex, ARow = Index).
// ---------------------------------------------------------------------------
unit rqlclview;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, ComCtrls, Dialogs, Forms, Graphics, LazUTF8;

function ViewGetInt(AObj: TObject; const AProp: string;
                    out AValue: Integer): Boolean;
function ViewSetInt(AObj: TObject; const AProp: string;
                    AValue: Integer): Boolean;
function ViewGetStr(AObj: TObject; const AProp: string;
                    out AValue: string): Boolean;
function ViewSetStr(AObj: TObject; const AProp: string;
                    const AValue: string): Boolean;
function ViewGetItem(AObj: TObject; const AProp: string; AIndex: Integer;
                     out AValue: string): Boolean;
function ViewSetItem(AObj: TObject; const AProp: string; AIndex: Integer;
                     const AValue: string): Boolean;
function ViewGetItemInt(AObj: TObject; const AProp: string; AIndex: Integer;
                        out AValue: Integer): Boolean;
function ViewSetItemInt(AObj: TObject; const AProp: string; AIndex: Integer;
                        AValue: Integer): Boolean;
function ViewGetCell(AObj: TObject; ACol, ARow: Integer;
                     out AValue: string): Boolean;
function ViewSetCell(AObj: TObject; ACol, ARow: Integer;
                     const AValue: string): Boolean;
function ViewCallEx(AObj: TObject; const AMethod, AStr: string;
                    AInt1, AInt2, AInt3: Integer;
                    out AIntResult: Integer): Boolean;

implementation

procedure CheckIndex(const AWhat: string; AIndex, ACount: Integer);
begin
  if (AIndex < 0) or (AIndex >= ACount) then
    raise Exception.Create(AWhat + '(' + IntToStr(AIndex) + '): out of 0..' +
                           IntToStr(ACount - 1));
end;

function ItemOf(AList: TCustomListView; AIndex: Integer): TListItem;
begin
  CheckIndex('Item', AIndex, AList.Items.Count);
  Result := AList.Items[AIndex];
end;

function ColumnOf(AList: TCustomListView; AIndex: Integer): TListColumn;
begin
  CheckIndex('Column', AIndex, TListView(AList).Columns.Count);
  Result := TListView(AList).Columns[AIndex];
end;

// Число столбцов: лишние удаляются с конца, новые - без заголовка
procedure SetColumnCount(AList: TListView; ACount: Integer);
begin
  if ACount < 0 then
    ACount := 0;
  while AList.Columns.Count > ACount do
    AList.Columns.Delete(AList.Columns.Count - 1);
  while AList.Columns.Count < ACount do
    AList.Columns.Add;
end;

function ViewGetInt(AObj: TObject; const AProp: string;
                    out AValue: Integer): Boolean;
var
  Prop: string;
begin
  Result := False;
  AValue := 0;
  Prop := UpperCase(AProp);
  if AObj is TListView then
  begin
    Result := True;
    if Prop = 'ITEMCOUNT' then
      AValue := TListView(AObj).Items.Count
    else if Prop = 'ITEMINDEX' then
      AValue := TListView(AObj).ItemIndex
    else if Prop = 'COLUMNSCOUNT' then
      AValue := TListView(AObj).Columns.Count
    else if Prop = 'SELCOUNT' then
      AValue := TListView(AObj).SelCount
    else
      Result := False;
  end
  else if AObj is TFontDialog then
  begin
    Result := True;
    if Prop = 'SIZE' then
      AValue := TFontDialog(AObj).Font.Size
    else if Prop = 'COLOR' then
      AValue := Integer(TFontDialog(AObj).Font.Color)
    else if Prop = 'FONTCOUNT' then
      AValue := Screen.Fonts.Count
    else
      Result := False;
  end;
end;

function ViewSetInt(AObj: TObject; const AProp: string;
                    AValue: Integer): Boolean;
var
  Prop: string;
begin
  Result := False;
  Prop := UpperCase(AProp);
  if AObj is TListView then
  begin
    Result := True;
    if Prop = 'ITEMINDEX' then
    begin
      // -1 - снять выделение; номер вне списка - ошибка
      if AValue <> -1 then
        CheckIndex('ItemIndex', AValue, TListView(AObj).Items.Count);
      TListView(AObj).ItemIndex := AValue;
    end
    else if Prop = 'COLUMNSCOUNT' then
      SetColumnCount(TListView(AObj), AValue)
    else
      Result := False;
  end
  else if AObj is TFontDialog then
  begin
    Result := True;
    if Prop = 'SIZE' then
      TFontDialog(AObj).Font.Size := AValue
    else if Prop = 'COLOR' then
      TFontDialog(AObj).Font.Color := TColor(AValue)
    else
      Result := False;
  end;
end;

function ViewGetStr(AObj: TObject; const AProp: string;
                    out AValue: string): Boolean;
begin
  Result := False;
  AValue := '';
  if (AObj is TFontDialog) and (UpperCase(AProp) = 'NAME') then
  begin
    AValue := UTF8ToWinCP(TFontDialog(AObj).Font.Name);
    Result := True;
  end;
end;

function ViewSetStr(AObj: TObject; const AProp: string;
                    const AValue: string): Boolean;
begin
  Result := False;
  if (AObj is TFontDialog) and (UpperCase(AProp) = 'NAME') then
  begin
    TFontDialog(AObj).Font.Name := WinCPToUTF8(AValue);
    Result := True;
  end;
end;

function ViewGetItem(AObj: TObject; const AProp: string; AIndex: Integer;
                     out AValue: string): Boolean;
var
  Prop: string;
begin
  Result := False;
  AValue := '';
  Prop := UpperCase(AProp);
  if AObj is TListView then
  begin
    Result := True;
    if Prop = 'ITEM.CAPTION' then
      AValue := UTF8ToWinCP(ItemOf(TListView(AObj), AIndex).Caption)
    else if Prop = 'COLUMN.CAPTION' then
      AValue := UTF8ToWinCP(ColumnOf(TListView(AObj), AIndex).Caption)
    else
      Result := False;
  end
  else if (AObj is TFontDialog) and (Prop = 'FONTNAME') then
  begin
    CheckIndex('FontName', AIndex, Screen.Fonts.Count);
    AValue := UTF8ToWinCP(Screen.Fonts[AIndex]);
    Result := True;
  end;
end;

function ViewSetItem(AObj: TObject; const AProp: string; AIndex: Integer;
                     const AValue: string): Boolean;
var
  Prop: string;
begin
  Result := False;
  Prop := UpperCase(AProp);
  if AObj is TListView then
  begin
    Result := True;
    if Prop = 'ITEM.CAPTION' then
      ItemOf(TListView(AObj), AIndex).Caption := WinCPToUTF8(AValue)
    else if Prop = 'COLUMN.CAPTION' then
      ColumnOf(TListView(AObj), AIndex).Caption := WinCPToUTF8(AValue)
    else
      Result := False;
  end;
end;

function ViewGetItemInt(AObj: TObject; const AProp: string; AIndex: Integer;
                        out AValue: Integer): Boolean;
var
  Prop: string;
  List: TListView;
begin
  Result := False;
  AValue := 0;
  Prop := UpperCase(AProp);
  if not (AObj is TListView) then
    Exit;
  List := TListView(AObj);
  Result := True;
  if Prop = 'ITEM.CHECKED' then
    AValue := Ord(ItemOf(List, AIndex).Checked)
  else if Prop = 'ITEM.IMAGEINDEX' then
    AValue := ItemOf(List, AIndex).ImageIndex
  else if (Prop = 'ITEM.SELECTED') or (Prop = 'SELECTED') then
    AValue := Ord(ItemOf(List, AIndex).Selected)
  else if Prop = 'ITEM.STATEINDEX' then
    AValue := ItemOf(List, AIndex).StateIndex
  else if Prop = 'ITEM.INDEX' then
    AValue := ItemOf(List, AIndex).Index
  // Как TListItem.Handle Delphi: окно списка
  else if Prop = 'ITEM.HANDLE' then
  begin
    ItemOf(List, AIndex);
    AValue := Integer(List.Handle);
  end
  else if Prop = 'COLUMN.WIDTH' then
    AValue := ColumnOf(List, AIndex).Width
  else
    Result := False;
end;

function ViewSetItemInt(AObj: TObject; const AProp: string; AIndex: Integer;
                        AValue: Integer): Boolean;
var
  Prop: string;
  List: TListView;
begin
  Result := False;
  Prop := UpperCase(AProp);
  if not (AObj is TListView) then
    Exit;
  List := TListView(AObj);
  Result := True;
  if Prop = 'ITEM.CHECKED' then
    ItemOf(List, AIndex).Checked := AValue <> 0
  else if Prop = 'ITEM.IMAGEINDEX' then
    ItemOf(List, AIndex).ImageIndex := AValue
  else if (Prop = 'ITEM.SELECTED') or (Prop = 'SELECTED') then
    ItemOf(List, AIndex).Selected := AValue <> 0
  else if Prop = 'ITEM.STATEINDEX' then
    ItemOf(List, AIndex).StateIndex := AValue
  else if Prop = 'COLUMN.WIDTH' then
    ColumnOf(List, AIndex).Width := AValue
  else
    Result := False;
end;

// SubItem(Index, SubIndex): ARow - пункт, ACol - подпункт (с 0)
function ViewGetCell(AObj: TObject; ACol, ARow: Integer;
                     out AValue: string): Boolean;
var
  ListItem: TListItem;
begin
  Result := False;
  AValue := '';
  if not (AObj is TListView) then
    Exit;
  ListItem := ItemOf(TListView(AObj), ARow);
  CheckIndex('SubItem(' + IntToStr(ARow) + ', ...): SubIndex', ACol,
             ListItem.SubItems.Count);
  AValue := UTF8ToWinCP(ListItem.SubItems[ACol]);
  Result := True;
end;

// Запись за последним подпунктом добавляет пустые подпункты до него
function ViewSetCell(AObj: TObject; ACol, ARow: Integer;
                     const AValue: string): Boolean;
var
  ListItem: TListItem;
begin
  Result := False;
  if not (AObj is TListView) then
    Exit;
  ListItem := ItemOf(TListView(AObj), ARow);
  if ACol < 0 then
    CheckIndex('SubItem(' + IntToStr(ARow) + ', ...): SubIndex', ACol,
               ListItem.SubItems.Count);
  while ListItem.SubItems.Count <= ACol do
    ListItem.SubItems.Add('');
  ListItem.SubItems[ACol] := WinCPToUTF8(AValue);
  Result := True;
end;

function ListCallEx(AList: TListView; const AMethod, AStr: string;
                    AInt1, AInt2: Integer): Boolean;
var
  ListItem: TListItem;
begin
  Result := True;
  if AMethod = 'ADDITEMS' then
    AList.Items.Add.Caption := WinCPToUTF8(AStr)
  else if AMethod = 'ADDCOLUMNS' then
    AList.Columns.Add.Caption := WinCPToUTF8(AStr)
  else if AMethod = 'ADDSUBITEM' then
    ItemOf(AList, AInt1).SubItems.Add(WinCPToUTF8(AStr))
  else if AMethod = 'CLEAR' then
    AList.Items.Clear
  else if AMethod = 'CLEARCOLUMNS' then
    AList.Columns.Clear
  else if AMethod = 'DELITEMS' then
  begin
    ItemOf(AList, AInt1);
    AList.Items.Delete(AInt1);
  end
  else if AMethod = 'DELSUBITEM' then
  begin
    ListItem := ItemOf(AList, AInt1);
    CheckIndex('DelSubItem: SubIndex', AInt2, ListItem.SubItems.Count);
    ListItem.SubItems.Delete(AInt2);
  end
  // Index = ItemCount - в конец
  else if AMethod = 'INSERTITEM' then
  begin
    CheckIndex('InsertItem', AInt1, AList.Items.Count + 1);
    AList.Items.Insert(AInt1).Caption := WinCPToUTF8(AStr);
  end
  else if AMethod = 'INSERTSUBITEM' then
  begin
    ListItem := ItemOf(AList, AInt1);
    CheckIndex('InsertSubItem: SubIndex', AInt2, ListItem.SubItems.Count + 1);
    ListItem.SubItems.Insert(AInt2, WinCPToUTF8(AStr));
  end
  else if AMethod = 'SWAPITEM' then
  begin
    ItemOf(AList, AInt1);
    ItemOf(AList, AInt2);
    if AInt1 <> AInt2 then
      AList.Items.Exchange(AInt1, AInt2);
  end
  else
    Result := False;
end;

function FontDialogCallEx(ADialog: TFontDialog; const AMethod: string;
                          AInt1: Integer): Boolean;
begin
  Result := True;
  // Стиль: fsBold 0, fsItalic 1, fsUnderline 2, fsStrikeOut 3
  if (AMethod = 'ADDSTYLES') or (AMethod = 'DELSTYLES') then
  begin
    if (AInt1 < Ord(Low(TFontStyle))) or (AInt1 > Ord(High(TFontStyle))) then
      raise Exception.Create('no font style ' + IntToStr(AInt1));
    if AMethod = 'ADDSTYLES' then
      ADialog.Font.Style := ADialog.Font.Style + [TFontStyle(AInt1)]
    else
      ADialog.Font.Style := ADialog.Font.Style - [TFontStyle(AInt1)];
  end
  // Параметры fdAnsiOnly 0 ... fdApplyButton 15 - номера как в RapidQ
  else if (AMethod = 'ADDOPTIONS') or (AMethod = 'DELOPTIONS') then
  begin
    if (AInt1 < Ord(Low(TFontDialogOption))) or
       (AInt1 > Ord(High(TFontDialogOption))) then
      raise Exception.Create('no font dialog option ' + IntToStr(AInt1));
    if AMethod = 'ADDOPTIONS' then
      ADialog.Options := ADialog.Options + [TFontDialogOption(AInt1)]
    else
      ADialog.Options := ADialog.Options - [TFontDialogOption(AInt1)];
  end
  else
    Result := False;
end;

function ViewCallEx(AObj: TObject; const AMethod, AStr: string;
                    AInt1, AInt2, AInt3: Integer;
                    out AIntResult: Integer): Boolean;
var
  Method: string;
begin
  Result := False;
  AIntResult := 1;
  Method := UpperCase(AMethod);
  if AObj is TListView then
    Result := ListCallEx(TListView(AObj), Method, AStr, AInt1, AInt2)
  else if AObj is TFontDialog then
    Result := FontDialogCallEx(TFontDialog(AObj), Method, AInt1);
end;

end.
