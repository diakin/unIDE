// ---------------------------------------------------------------------------
//  RqLcl: QSTRINGGRID (TStringGrid LCL) и QDIRTREE (TShellTreeView LCL) -
//  свойства и методы, которых нет в RTTI или которые у RapidQ другие.
//
//  Функции GridXxx возвращают True, если свойство или метод обработаны
//  здесь; False - искать дальше (RTTI). Строки - в кодировке Windows.
//
//  QSTRINGGRID:
//  - ScrollBars: у Delphi (RapidQ) полосы видны, только когда нужны -
//    ssBoth RapidQ = ssAutoBoth LCL (и так же Horizontal, Vertical);
//  - AddOptions / DelOptions: номера RapidQ goFixedVertLine 0 ...
//    goThumbTracking 14; в LCL после goEditing добавлен goAutoAddRows;
//  - LoadFromFile / SaveToFile (имя, RowOffset, ColOffset, MaxRows):
//    строка файла - строка таблицы, ячейки через Separator. Как RapidQ
//    обрабатывает RowOffset, ColOffset, MaxRows и меняет ли RowCount -
//    по документации не ясно, здесь: чтение с строки RowOffset и столбца
//    ColOffset, не больше MaxRows строк (MaxRows <= 0 - все), RowCount =
//    RowOffset + число строк файла, ColCount растёт, если в строке
//    файла больше ячеек.
// ---------------------------------------------------------------------------
unit rqlclgrid;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, StdCtrls, Grids, ComCtrls, ShellCtrls, Graphics,
  LazUTF8;

function GridGetInt(AObj: TObject; const AProp: string;
                    out AValue: Integer): Boolean;
function GridSetInt(AObj: TObject; const AProp: string;
                    AValue: Integer): Boolean;
function GridGetStr(AObj: TObject; const AProp: string;
                    out AValue: string): Boolean;
function GridSetStr(AObj: TObject; const AProp: string;
                    const AValue: string): Boolean;
function GridGetItemInt(AObj: TObject; const AProp: string; AIndex: Integer;
                        out AValue: Integer): Boolean;
function GridSetItemInt(AObj: TObject; const AProp: string; AIndex: Integer;
                        AValue: Integer): Boolean;
function GridGetCell(AObj: TObject; ACol, ARow: Integer;
                     out AValue: string): Boolean;
function GridSetCell(AObj: TObject; ACol, ARow: Integer;
                     const AValue: string): Boolean;
// Метод с параметрами (строка и до трёх целых). Результат - целое
// (AIntResult) или строка (AStrResult, AIsStr = True).
function GridCallEx(AObj: TObject; const AMethod, AStr: string;
                    AInt1, AInt2, AInt3: Integer; out AIntResult: Integer;
                    out AStrResult: string; out AIsStr: Boolean): Boolean;
// Рисование на таблице (обычно в OnDrawCell): FillRect, TextOut, Line,
// Rectangle, RoundRect, Circle, Pset, Paint. Координаты - в окне таблицы.
function GridDraw(AObj: TObject; const AMethod, AStr: string;
                  const AInts: array of Integer; out AResult: Integer): Boolean;
// Начальные значения как в RapidQ
procedure GridInitNew(AObj: TObject);

implementation

type
  // Данные QSTRINGGRID и QDIRTREE, которых нет у объекта LCL
  TRqGridExtra = class(TComponent)
  public
    Separator: string;
    InitialDir: string;
    FastLoad: Integer;
    ReadOnStart: Integer;
    DriveTypes: Integer;
  end;

  // Доступ к Loaded: дерево наполняется дисками в Loaded (при загрузке
  // из .lfm), у созданного в коде его надо вызвать самим
  TRqShellTreeAccess = class(TCustomShellTreeView);

function ExtraOf(AComp: TComponent): TRqGridExtra;
var
  CompIdx: Integer;
begin
  for CompIdx := 0 to AComp.ComponentCount - 1 do
    if AComp.Components[CompIdx] is TRqGridExtra then
    begin
      Result := TRqGridExtra(AComp.Components[CompIdx]);
      Exit;
    end;
  Result := TRqGridExtra.Create(AComp);
  Result.Separator := #9;
end;

procedure CheckCell(AGrid: TCustomStringGrid; ACol, ARow: Integer);
begin
  if (ACol < 0) or (ACol >= AGrid.ColCount) or (ARow < 0) or
     (ARow >= AGrid.RowCount) then
    raise Exception.Create('Cell(' + IntToStr(ACol) + ', ' + IntToStr(ARow) +
      '): out of grid, ColCount = ' + IntToStr(AGrid.ColCount) +
      ', RowCount = ' + IntToStr(AGrid.RowCount));
end;

procedure CheckIndex(const AWhat: string; AIndex, ACount: Integer);
begin
  if (AIndex < 0) or (AIndex >= ACount) then
    raise Exception.Create(AWhat + '(' + IntToStr(AIndex) + '): out of 0..' +
                           IntToStr(ACount - 1));
end;

// Номер опции RapidQ -> TGridOption
function GridOptionOf(ARqOption: Integer): TGridOption;
begin
  case ARqOption of
    0..10: Result := TGridOption(ARqOption);
    11: Result := goTabs;
    12: Result := goRowSelect;
    13: Result := goAlwaysShowEditor;
    14: Result := goThumbTracking;
  else
    raise Exception.Create('no grid option ' + IntToStr(ARqOption));
  end;
end;

// Таблица в текст: строки FromRow.., столбцы FromCol..ColCount-1
function GridToText(AGrid: TCustomStringGrid; ARowOffset, AColOffset,
                    AMaxRows: Integer): string;
var
  RowIdx, ColIdx, LastRow: Integer;
  Separator: string;
  Lines: TStringList;
  LineText: string;
begin
  Separator := UTF8ToWinCP(ExtraOf(AGrid).Separator);
  LastRow := AGrid.RowCount - 1;
  if (AMaxRows > 0) and (ARowOffset + AMaxRows - 1 < LastRow) then
    LastRow := ARowOffset + AMaxRows - 1;
  Lines := TStringList.Create;
  try
    for RowIdx := ARowOffset to LastRow do
    begin
      LineText := '';
      for ColIdx := AColOffset to AGrid.ColCount - 1 do
      begin
        if ColIdx > AColOffset then
          LineText := LineText + Separator;
        LineText := LineText + UTF8ToWinCP(AGrid.Cells[ColIdx, RowIdx]);
      end;
      Lines.Add(LineText);
    end;
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

procedure GridFromText(AGrid: TCustomStringGrid; const AText: string;
                       ARowOffset, AColOffset, AMaxRows: Integer);
var
  Lines: TStringList;
  LineIdx, ColIdx, LineCount, SepPos, StartPos: Integer;
  Separator, LineText: string;
  Cells: TStringList;
begin
  Separator := ExtraOf(AGrid).Separator;   // UTF-8
  Lines := TStringList.Create;
  Cells := TStringList.Create;
  AGrid.BeginUpdate;
  try
    Lines.Text := WinCPToUTF8(AText);
    LineCount := Lines.Count;
    if (AMaxRows > 0) and (LineCount > AMaxRows) then
      LineCount := AMaxRows;
    if ARowOffset + LineCount > AGrid.FixedRows then
      AGrid.RowCount := ARowOffset + LineCount;
    for LineIdx := 0 to LineCount - 1 do
    begin
      LineText := Lines[LineIdx];
      Cells.Clear;
      if Separator = '' then
        Cells.Add(LineText)
      else
      begin
        StartPos := 1;
        repeat
          SepPos := Pos(Separator, Copy(LineText, StartPos, MaxInt));
          if SepPos = 0 then
          begin
            Cells.Add(Copy(LineText, StartPos, MaxInt));
            Break;
          end;
          Cells.Add(Copy(LineText, StartPos, SepPos - 1));
          StartPos := StartPos + SepPos - 1 + Length(Separator);
        until False;
      end;
      if AColOffset + Cells.Count > AGrid.ColCount then
        AGrid.ColCount := AColOffset + Cells.Count;
      for ColIdx := 0 to Cells.Count - 1 do
        AGrid.Cells[AColOffset + ColIdx, ARowOffset + LineIdx] := Cells[ColIdx];
    end;
  finally
    AGrid.EndUpdate;
    Cells.Free;
    Lines.Free;
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

// Папка дерева: без "\" в конце, кроме корня диска (C:\)
function TreeDir(ATree: TCustomShellTreeView): string;
begin
  Result := ATree.Path;
  if (Length(Result) > 3) and (Result[Length(Result)] = PathDelim) then
    SetLength(Result, Length(Result) - 1);
end;

// ---------------------------------------------------------------------------

procedure NeedInts(const AMethod: string; const AInts: array of Integer;
                   ACount: Integer);
begin
  if Length(AInts) < ACount then
    raise Exception.Create(AMethod + ': ' + IntToStr(ACount) +
                           ' parameters expected');
end;

function GridDraw(AObj: TObject; const AMethod, AStr: string;
                  const AInts: array of Integer; out AResult: Integer): Boolean;
var
  Method: string;
  Canvas: TCanvas;
begin
  Result := False;
  AResult := 1;
  if not (AObj is TCustomGrid) then
    Exit;
  Canvas := TStringGrid(AObj).Canvas;
  Method := UpperCase(AMethod);
  Result := True;
  if Method = 'FILLRECT' then
  begin
    // (x1, y1, x2, y2, цвет)
    NeedInts(AMethod, AInts, 5);
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := TColor(AInts[4]);
    Canvas.FillRect(Rect(AInts[0], AInts[1], AInts[2], AInts[3]));
  end
  else if Method = 'TEXTOUT' then
  begin
    // (x, y, текст, цвет текста, цвет фона; -1 - фон прозрачный)
    NeedInts(AMethod, AInts, 4);
    Canvas.Font.Color := TColor(AInts[2]);
    if AInts[3] = -1 then
      Canvas.Brush.Style := bsClear
    else
    begin
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := TColor(AInts[3]);
    end;
    Canvas.TextOut(AInts[0], AInts[1], WinCPToUTF8(AStr));
  end
  else if Method = 'LINE' then
  begin
    NeedInts(AMethod, AInts, 5);
    Canvas.Pen.Color := TColor(AInts[4]);
    Canvas.Line(AInts[0], AInts[1], AInts[2], AInts[3]);
  end
  else if Method = 'RECTANGLE' then
  begin
    NeedInts(AMethod, AInts, 5);
    Canvas.Pen.Color := TColor(AInts[4]);
    Canvas.Brush.Style := bsClear;
    Canvas.Rectangle(AInts[0], AInts[1], AInts[2], AInts[3]);
  end
  else if Method = 'ROUNDRECT' then
  begin
    // (x1, y1, x2, y2, x3, y3, цвет) - с заливкой
    NeedInts(AMethod, AInts, 7);
    Canvas.Pen.Color := TColor(AInts[6]);
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := TColor(AInts[6]);
    Canvas.RoundRect(AInts[0], AInts[1], AInts[2], AInts[3], AInts[4], AInts[5]);
  end
  else if Method = 'CIRCLE' then
  begin
    // (x1, y1, x2, y2, цвет, заливка)
    NeedInts(AMethod, AInts, 6);
    Canvas.Pen.Color := TColor(AInts[4]);
    if AInts[5] <> 0 then
    begin
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := TColor(AInts[4]);
    end
    else
      Canvas.Brush.Style := bsClear;
    Canvas.Ellipse(AInts[0], AInts[1], AInts[2], AInts[3]);
  end
  else if Method = 'PSET' then
  begin
    NeedInts(AMethod, AInts, 3);
    Canvas.Pixels[AInts[0], AInts[1]] := TColor(AInts[2]);
  end
  else if Method = 'PAINT' then
  begin
    // (x, y, цвет заливки, цвет границы)
    NeedInts(AMethod, AInts, 4);
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := TColor(AInts[2]);
    Canvas.FloodFill(AInts[0], AInts[1], TColor(AInts[3]), fsBorder);
  end
  else
    Result := False;
end;

procedure GridInitNew(AObj: TObject);
begin
  if AObj is TCustomStringGrid then
  begin
    // Значения по умолчанию RapidQ (документация QSTRINGGRID)
    TStringGrid(AObj).DefaultColWidth := 64;
    TStringGrid(AObj).DefaultRowHeight := 24;
    TStringGrid(AObj).ScrollBars := ssAutoBoth;
  end
  else if AObj is TCustomShellTreeView then
    TRqShellTreeAccess(AObj).Loaded;
end;

function GridGetInt(AObj: TObject; const AProp: string;
                    out AValue: Integer): Boolean;
var
  Prop: string;
  Grid: TStringGrid;
begin
  Result := False;
  AValue := 0;
  Prop := UpperCase(AProp);
  if AObj is TCustomStringGrid then
  begin
    Grid := TStringGrid(AObj);
    Result := True;
    if Prop = 'COL' then
      AValue := Grid.Col
    else if Prop = 'ROW' then
      AValue := Grid.Row
    else if Prop = 'LEFTCOL' then
      AValue := Grid.LeftCol
    else if Prop = 'TOPROW' then
      AValue := Grid.TopRow
    else if Prop = 'VISIBLECOLCOUNT' then
      AValue := Grid.VisibleColCount
    else if Prop = 'VISIBLEROWCOUNT' then
      AValue := Grid.VisibleRowCount
    else if Prop = 'EDITORMODE' then
      AValue := Ord(Grid.EditorMode)
    else if Prop = 'GRIDWIDTH' then
      AValue := Grid.GridWidth
    else if Prop = 'GRIDHEIGHT' then
      AValue := Grid.GridHeight
    else if Prop = 'SCROLLBARS' then
      case Grid.ScrollBars of
        ssHorizontal, ssAutoHorizontal: AValue := 1;
        ssVertical, ssAutoVertical: AValue := 2;
        ssBoth, ssAutoBoth: AValue := 3;
      else
        AValue := 0;
      end
    else
      Result := False;
  end
  else if AObj is TCustomShellTreeView then
  begin
    Result := True;
    if Prop = 'FASTLOAD' then
      AValue := ExtraOf(TComponent(AObj)).FastLoad
    else if Prop = 'READONSTART' then
      AValue := ExtraOf(TComponent(AObj)).ReadOnStart
    else
      Result := False;
  end;
end;

function GridSetInt(AObj: TObject; const AProp: string;
                    AValue: Integer): Boolean;
var
  Prop: string;
  Grid: TStringGrid;
begin
  Result := False;
  Prop := UpperCase(AProp);
  if AObj is TCustomStringGrid then
  begin
    Grid := TStringGrid(AObj);
    Result := True;
    if Prop = 'COL' then
      Grid.Col := AValue
    else if Prop = 'ROW' then
      Grid.Row := AValue
    else if Prop = 'LEFTCOL' then
      Grid.LeftCol := AValue
    else if Prop = 'TOPROW' then
      Grid.TopRow := AValue
    else if Prop = 'EDITORMODE' then
      Grid.EditorMode := AValue <> 0
    else if Prop = 'SCROLLBARS' then
      case AValue of
        0: Grid.ScrollBars := ssNone;
        1: Grid.ScrollBars := ssAutoHorizontal;
        2: Grid.ScrollBars := ssAutoVertical;
        3: Grid.ScrollBars := ssAutoBoth;
      else
        raise Exception.Create('ScrollBars: no value ' + IntToStr(AValue));
      end
    else
      Result := False;
  end
  else if AObj is TCustomShellTreeView then
  begin
    Result := True;
    // Запоминаются: дерево LCL читает папки по мере раскрытия
    if Prop = 'FASTLOAD' then
      ExtraOf(TComponent(AObj)).FastLoad := AValue
    else if Prop = 'READONSTART' then
      ExtraOf(TComponent(AObj)).ReadOnStart := AValue
    else
      Result := False;
  end;
end;

function GridGetStr(AObj: TObject; const AProp: string;
                    out AValue: string): Boolean;
var
  Prop: string;
begin
  Result := False;
  AValue := '';
  Prop := UpperCase(AProp);
  if (AObj is TCustomStringGrid) and (Prop = 'SEPARATOR') then
  begin
    AValue := UTF8ToWinCP(ExtraOf(TComponent(AObj)).Separator);
    Result := True;
  end
  else if AObj is TCustomShellTreeView then
  begin
    Result := True;
    if Prop = 'DIRECTORY' then
      AValue := UTF8ToWinCP(TreeDir(TCustomShellTreeView(AObj)))
    else if Prop = 'INITIALDIR' then
      AValue := UTF8ToWinCP(ExtraOf(TComponent(AObj)).InitialDir)
    else
      Result := False;
  end;
end;

function GridSetStr(AObj: TObject; const AProp: string;
                    const AValue: string): Boolean;
var
  Prop: string;
begin
  Result := False;
  Prop := UpperCase(AProp);
  if (AObj is TCustomStringGrid) and (Prop = 'SEPARATOR') then
  begin
    ExtraOf(TComponent(AObj)).Separator := WinCPToUTF8(AValue);
    Result := True;
  end
  else if AObj is TCustomShellTreeView then
  begin
    Result := True;
    if Prop = 'DIRECTORY' then
      TCustomShellTreeView(AObj).Path := WinCPToUTF8(AValue)
    else if Prop = 'INITIALDIR' then
    begin
      ExtraOf(TComponent(AObj)).InitialDir := WinCPToUTF8(AValue);
      if AValue <> '' then
        TCustomShellTreeView(AObj).Path := WinCPToUTF8(AValue);
    end
    else
      Result := False;
  end;
end;

function GridGetItemInt(AObj: TObject; const AProp: string; AIndex: Integer;
                        out AValue: Integer): Boolean;
var
  Prop: string;
  Grid: TStringGrid;
begin
  Result := False;
  AValue := 0;
  if not (AObj is TCustomStringGrid) then
    Exit;
  Grid := TStringGrid(AObj);
  Prop := UpperCase(AProp);
  Result := True;
  if Prop = 'COLWIDTHS' then
  begin
    CheckIndex('ColWidths', AIndex, Grid.ColCount);
    AValue := Grid.ColWidths[AIndex];
  end
  else if Prop = 'ROWHEIGHTS' then
  begin
    CheckIndex('RowHeights', AIndex, Grid.RowCount);
    AValue := Grid.RowHeights[AIndex];
  end
  else
    Result := False;
end;

function GridSetItemInt(AObj: TObject; const AProp: string; AIndex: Integer;
                        AValue: Integer): Boolean;
var
  Prop: string;
  Grid: TStringGrid;
begin
  Result := False;
  if not (AObj is TCustomStringGrid) then
    Exit;
  Grid := TStringGrid(AObj);
  Prop := UpperCase(AProp);
  Result := True;
  if Prop = 'COLWIDTHS' then
  begin
    CheckIndex('ColWidths', AIndex, Grid.ColCount);
    Grid.ColWidths[AIndex] := AValue;
  end
  else if Prop = 'ROWHEIGHTS' then
  begin
    CheckIndex('RowHeights', AIndex, Grid.RowCount);
    Grid.RowHeights[AIndex] := AValue;
  end
  else
    Result := False;
end;

function GridGetCell(AObj: TObject; ACol, ARow: Integer;
                     out AValue: string): Boolean;
begin
  Result := False;
  AValue := '';
  if not (AObj is TCustomStringGrid) then
    Exit;
  CheckCell(TCustomStringGrid(AObj), ACol, ARow);
  AValue := UTF8ToWinCP(TCustomStringGrid(AObj).Cells[ACol, ARow]);
  Result := True;
end;

function GridSetCell(AObj: TObject; ACol, ARow: Integer;
                     const AValue: string): Boolean;
begin
  Result := False;
  if not (AObj is TCustomStringGrid) then
    Exit;
  CheckCell(TCustomStringGrid(AObj), ACol, ARow);
  TCustomStringGrid(AObj).Cells[ACol, ARow] := WinCPToUTF8(AValue);
  Result := True;
end;

function GridCallEx(AObj: TObject; const AMethod, AStr: string;
                    AInt1, AInt2, AInt3: Integer; out AIntResult: Integer;
                    out AStrResult: string; out AIsStr: Boolean): Boolean;
var
  Method: string;
  Grid: TStringGrid;
  Tree: TCustomShellTreeView;
begin
  Result := False;
  AIntResult := 1;
  AStrResult := '';
  AIsStr := False;
  Method := UpperCase(AMethod);
  if AObj is TCustomStringGrid then
  begin
    Grid := TStringGrid(AObj);
    Result := True;
    if Method = 'ADDOPTIONS' then
      Grid.Options := Grid.Options + [GridOptionOf(AInt1)]
    else if Method = 'DELOPTIONS' then
      Grid.Options := Grid.Options - [GridOptionOf(AInt1)]
    else if Method = 'DELETECOL' then
    begin
      CheckIndex('DeleteCol', AInt1, Grid.ColCount);
      Grid.DeleteCol(AInt1);
    end
    else if Method = 'DELETEROW' then
    begin
      CheckIndex('DeleteRow', AInt1, Grid.RowCount);
      Grid.DeleteRow(AInt1);
    end
    else if Method = 'INSERTCOL' then
      Grid.InsertColRow(True, AInt1)
    else if Method = 'INSERTROW' then
      Grid.InsertColRow(False, AInt1)
    else if Method = 'SWAPCOLS' then
    begin
      CheckIndex('SwapCols', AInt1, Grid.ColCount);
      CheckIndex('SwapCols', AInt2, Grid.ColCount);
      Grid.ExchangeColRow(True, AInt1, AInt2);
    end
    else if Method = 'SWAPROWS' then
    begin
      CheckIndex('SwapRows', AInt1, Grid.RowCount);
      CheckIndex('SwapRows', AInt2, Grid.RowCount);
      Grid.ExchangeColRow(False, AInt1, AInt2);
    end
    else if Method = 'LOADFROMFILE' then
      GridFromText(Grid, ReadWholeFile(AStr), AInt1, AInt2, AInt3)
    else if Method = 'SAVETOFILE' then
      WriteWholeFile(AStr, GridToText(Grid, AInt1, AInt2, AInt3))
    // Потоки: текст передаёт и принимает обёртка FreeBASIC
    else if Method = 'LOADFROMTEXT' then
      GridFromText(Grid, AStr, AInt1, AInt2, AInt3)
    else if Method = 'SAVETOTEXT' then
    begin
      AStrResult := GridToText(Grid, AInt1, AInt2, AInt3);
      AIsStr := True;
    end
    else if Method = 'TEXTWIDTH' then
      AIntResult := Grid.Canvas.TextWidth(WinCPToUTF8(AStr))
    else if Method = 'TEXTHEIGHT' then
      AIntResult := Grid.Canvas.TextHeight(WinCPToUTF8(AStr))
    else
      Result := False;
  end
  else if AObj is TCustomShellTreeView then
  begin
    Tree := TCustomShellTreeView(AObj);
    Result := True;
    // Скрытые и системные папки: dtHidden 1, dtSystem 2, dtAll 4
    if Method = 'ADDDIRTYPES' then
    begin
      if AInt1 in [1, 2, 4] then
        Tree.ObjectTypes := Tree.ObjectTypes + [otHidden];
    end
    else if Method = 'DELDIRTYPES' then
    begin
      if AInt1 in [1, 2, 4] then
        Tree.ObjectTypes := Tree.ObjectTypes - [otHidden];
    end
    // Типы дисков: дерево LCL показывает все диски; значение запоминается
    else if Method = 'ADDDRIVETYPES' then
      ExtraOf(Tree).DriveTypes := ExtraOf(Tree).DriveTypes or (1 shl AInt1)
    else if Method = 'DELDRIVETYPES' then
      ExtraOf(Tree).DriveTypes := ExtraOf(Tree).DriveTypes and not (1 shl AInt1)
    else if Method = 'FULLCOLLAPSE' then
      Tree.FullCollapse
    else if Method = 'FULLEXPAND' then
      Tree.FullExpand
    else if Method = 'RELOAD' then
      Tree.Refresh(nil)
    else
      Result := False;
  end;
end;

end.
