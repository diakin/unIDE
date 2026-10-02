from icons import ICONS, ALIAS
def lit(s):
    # строка Паскаля частями не длиннее 200 знаков
    parts=[s[i:i+200] for i in range(0,len(s),200)] or ['']
    return (' +\n    ').join("'"+p.replace("'","''")+"'" for p in parts)
names=list(ICONS)
out=[]
out.append("""unit DsgIcons;

// ---------------------------------------------------------------------------
//  Значки палитры компонентов - сглаженные, рисуются кодом
//
//  Значки Delphi (Bin\\dcl*.bpl) - пиксельные картинки 24x24 в 16 цветах, и
//  в тёмной теме их приходилось перекрашивать по точкам. Здесь у каждого
//  компонента палитры Delphi свой значок, нарисованный простыми фигурами по
//  образцу значка Delphi. Сглаживание - в DsgPalette (DsgDrawSmoothIcon):
//  значок рисуется в 4 раза крупнее и усредняется.
//
//  Значок - строка команд через ';', координаты - в точках значка 24x24
//  (дробные можно), ось Y вниз. Чёрное - значок, белое - пусто:
//    F x1 y1 x2 y2         - закрашенный прямоугольник
//    E x1 y1 x2 y2         - стереть прямоугольник (белым)
//    R x1 y1 x2 y2 [w]     - рамка толщиной w (1) внутрь от края
//    O x1 y1 x2 y2 r [w]   - рамка со скруглёнными углами радиуса r
//    L x1 y1 x2 y2 [w]     - линия толщиной w (1)
//    C cx cy r [w]         - окружность: кольцо внешнего радиуса r
//    D cx cy r             - круг; K cx cy r - стереть круг
//    P x1 y1 x2 y2 ...     - закрашенный многоугольник; Q - стереть
//    T x y h B|N текст     - текст Arial высотой h, B - жирный
//  Скрипты сгенерированы из icons.py (scratchpad, превью - render.py);
//  править можно и здесь, формат простой.
// ---------------------------------------------------------------------------

interface

uses
  Windows, SysUtils, Classes, Graphics;

const
  DsgIconScale = 4;   // во сколько раз крупнее рисуется значок

// Скрипт значка класса AClass ('' - своего значка нет). Свои компоненты
// TUiX - значок TX (TUiButton - TButton) с меткой, которую ставит палитра.
function DsgIconScript(const AClass: string): string;

// Нарисовать значок по скрипту на холсте размера 24 * DsgIconScale:
// холст заливается белым, значок - чёрным
procedure DsgPaintIcon(ACanvas: TCanvas; const AScript: string);

implementation

type
  TDsgIconDef = record
    Name: string;
    Script: string;
  end;

const
""")
out.append("  DsgIconDefs: array[0..%d] of TDsgIconDef = (\n" % (len(names)-1))
items=[]
for n in names:
    items.append("    (Name: '%s';\n     Script: %s)" % (n, lit(ICONS[n]).replace('\n    ','\n      ')))
out.append(',\n'.join(items)+");\n\n")
out.append("  // Свои компоненты, у которых аналог называется иначе\n")
out.append("  DsgIconAliases: array[0..%d] of TDsgIconDef = (\n" % (len(ALIAS)-1))
out.append(',\n'.join("    (Name: '%s'; Script: '%s')" % (k,v) for k,v in ALIAS.items())+");\n")
out.append(r"""
function FindScript(const AName: string): string;
var
  DefIdx: Integer;
begin
  Result := '';
  for DefIdx := Low(DsgIconDefs) to High(DsgIconDefs) do
    if CompareText(DsgIconDefs[DefIdx].Name, AName) = 0 then
    begin
      Result := DsgIconDefs[DefIdx].Script;
      Exit;
    end;
end;

function DsgIconScript(const AClass: string): string;
var
  AliasIdx: Integer;
begin
  Result := FindScript(AClass);
  if Result <> '' then
    Exit;
  for AliasIdx := Low(DsgIconAliases) to High(DsgIconAliases) do
    if CompareText(DsgIconAliases[AliasIdx].Name, AClass) = 0 then
    begin
      Result := FindScript(DsgIconAliases[AliasIdx].Script);
      Exit;
    end;
  // TUiButton -> TButton
  if CompareText(Copy(AClass, 1, 3), 'TUi') = 0 then
    Result := FindScript('T' + Copy(AClass, 4, MaxInt));
end;

// Координата значка -> точка большого холста
function Big(AValue: Double): Integer;
begin
  Result := Round(AValue * DsgIconScale);
end;

// Число из скрипта: точка - разделитель дробной части при любых
// настройках Windows (Val)
function ScriptNum(const AText: string): Double;
var
  ErrPos: Integer;
begin
  Val(AText, Result, ErrPos);
  if ErrPos <> 0 then
    Result := 0;
end;

// Слова команды через пробел
procedure SplitWords(const AText: string; AWords: TStringList);
var
  Rest: string;
  SpacePos: Integer;
begin
  AWords.Clear;
  Rest := Trim(AText);
  while Rest <> '' do
  begin
    SpacePos := Pos(' ', Rest);
    if SpacePos = 0 then
      SpacePos := Length(Rest) + 1;
    AWords.Add(Copy(Rest, 1, SpacePos - 1));
    Rest := TrimLeft(Copy(Rest, SpacePos + 1, MaxInt));
  end;
end;

procedure DsgPaintIcon(ACanvas: TCanvas; const AScript: string);
var
  Commands, Words: TStringList;
  CmdIdx, NumIdx, PointIdx, WordIdx, PointCount: Integer;
  Cmd, Op, TextPart: string;
  Nums: array of Double;
  Points: array of TPoint;
  Width, LineLen, NormX, NormY, PosX1, PosY1, PosX2, PosY2: Double;
  Outer, Inner: HRGN;
  InkBrush: HBRUSH;
  FontRec: TLogFont;
  RestPos: Integer;

  function Num(AIndex: Integer; ADefault: Double): Double;
  begin
    if AIndex < Length(Nums) then
      Result := Nums[AIndex]
    else
      Result := ADefault;
  end;

  procedure SetInk(AErase: Boolean);
  begin
    if AErase then
    begin
      ACanvas.Brush.Color := clWhite;
      ACanvas.Pen.Color := clWhite;
    end
    else
    begin
      ACanvas.Brush.Color := clBlack;
      ACanvas.Pen.Color := clBlack;
    end;
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Pen.Style := psSolid;
    ACanvas.Pen.Width := 1;
  end;

  procedure FillBox(AX1, AY1, AX2, AY2: Double);
  begin
    ACanvas.FillRect(Rect(Big(AX1), Big(AY1), Big(AX2), Big(AY2)));
  end;

begin
  Commands := TStringList.Create;
  Words := TStringList.Create;
  try
    SetInk(True);
    ACanvas.FillRect(Rect(0, 0, 24 * DsgIconScale, 24 * DsgIconScale));
    // Команды через ';'
    TextPart := AScript;
    while TextPart <> '' do
    begin
      RestPos := Pos(';', TextPart);
      if RestPos = 0 then
        RestPos := Length(TextPart) + 1;
      Cmd := Trim(Copy(TextPart, 1, RestPos - 1));
      if Cmd <> '' then
        Commands.Add(Cmd);
      Delete(TextPart, 1, RestPos);
    end;

    for CmdIdx := 0 to Commands.Count - 1 do
    begin
      Cmd := Commands[CmdIdx];
      Op := UpperCase(Cmd[1]);
      if Op = 'T' then
      begin
        // T x y h B|N текст
        SplitWords(Copy(Cmd, 2, MaxInt), Words);
        if Words.Count < 5 then
          Continue;
        TextPart := Trim(Copy(Cmd, 2, MaxInt));
        for WordIdx := 1 to 4 do
          TextPart := TrimLeft(Copy(TextPart, Pos(' ', TextPart) + 1, MaxInt));
        FillChar(FontRec, SizeOf(FontRec), 0);
        FontRec.lfHeight := -Big(ScriptNum(Words[2]));
        if UpperCase(Words[3]) = 'B' then
          FontRec.lfWeight := FW_BOLD
        else
          FontRec.lfWeight := FW_NORMAL;
        FontRec.lfCharSet := DEFAULT_CHARSET;
        // Без сглаживания Windows: сглаживает усреднение (ClearType дал
        // бы цветные края)
        FontRec.lfQuality := NONANTIALIASED_QUALITY;
        StrPCopy(FontRec.lfFaceName, 'Arial');
        ACanvas.Font.Handle := CreateFontIndirect(FontRec);
        ACanvas.Font.Color := clBlack;
        ACanvas.Brush.Style := bsClear;
        ACanvas.TextOut(Big(ScriptNum(Words[0])), Big(ScriptNum(Words[1])),
                        TextPart);
        ACanvas.Brush.Style := bsSolid;
        Continue;
      end;

      SplitWords(Copy(Cmd, 2, MaxInt), Words);
      SetLength(Nums, Words.Count);
      for NumIdx := 0 to Words.Count - 1 do
        Nums[NumIdx] := ScriptNum(Words[NumIdx]);

      if (Op = 'F') or (Op = 'E') then
      begin
        SetInk(Op = 'E');
        FillBox(Num(0, 0), Num(1, 0), Num(2, 0), Num(3, 0));
      end
      else if Op = 'R' then
      begin
        SetInk(False);
        Width := Num(4, 1);
        FillBox(Num(0, 0), Num(1, 0), Num(2, 0), Num(1, 0) + Width);
        FillBox(Num(0, 0), Num(3, 0) - Width, Num(2, 0), Num(3, 0));
        FillBox(Num(0, 0), Num(1, 0), Num(0, 0) + Width, Num(3, 0));
        FillBox(Num(2, 0) - Width, Num(1, 0), Num(2, 0), Num(3, 0));
      end
      else if Op = 'L' then
      begin
        SetInk(False);
        Width := Num(4, 1);
        PosX1 := Num(0, 0);
        PosY1 := Num(1, 0);
        PosX2 := Num(2, 0);
        PosY2 := Num(3, 0);
        SetLength(Points, 4);
        if PosY1 = PosY2 then
        begin
          // Горизонталь и вертикаль - прямоугольником от края до края
          Points[0] := Point(Big(PosX1), Big(PosY1 - Width / 2));
          Points[1] := Point(Big(PosX2), Big(PosY1 - Width / 2));
          Points[2] := Point(Big(PosX2), Big(PosY1 + Width / 2));
          Points[3] := Point(Big(PosX1), Big(PosY1 + Width / 2));
        end
        else if PosX1 = PosX2 then
        begin
          Points[0] := Point(Big(PosX1 - Width / 2), Big(PosY1));
          Points[1] := Point(Big(PosX1 + Width / 2), Big(PosY1));
          Points[2] := Point(Big(PosX1 + Width / 2), Big(PosY2));
          Points[3] := Point(Big(PosX1 - Width / 2), Big(PosY2));
        end
        else
        begin
          LineLen := Sqrt(Sqr(PosX2 - PosX1) + Sqr(PosY2 - PosY1));
          NormX := -(PosY2 - PosY1) / LineLen * Width / 2;
          NormY := (PosX2 - PosX1) / LineLen * Width / 2;
          Points[0] := Point(Big(PosX1 + NormX), Big(PosY1 + NormY));
          Points[1] := Point(Big(PosX2 + NormX), Big(PosY2 + NormY));
          Points[2] := Point(Big(PosX2 - NormX), Big(PosY2 - NormY));
          Points[3] := Point(Big(PosX1 - NormX), Big(PosY1 - NormY));
        end;
        ACanvas.Polygon(Points);
      end
      else if (Op = 'D') or (Op = 'K') then
      begin
        SetInk(Op = 'K');
        ACanvas.Ellipse(Big(Num(0, 0) - Num(2, 0)), Big(Num(1, 0) - Num(2, 0)),
                        Big(Num(0, 0) + Num(2, 0)), Big(Num(1, 0) + Num(2, 0)));
      end
      else if (Op = 'C') or (Op = 'O') then
      begin
        // Кольцо и скруглённая рамка - разность двух областей
        if Op = 'C' then
        begin
          Width := Num(3, 1);
          Outer := CreateEllipticRgn(
            Big(Num(0, 0) - Num(2, 0)), Big(Num(1, 0) - Num(2, 0)),
            Big(Num(0, 0) + Num(2, 0)), Big(Num(1, 0) + Num(2, 0)));
          Inner := CreateEllipticRgn(
            Big(Num(0, 0) - Num(2, 0) + Width),
            Big(Num(1, 0) - Num(2, 0) + Width),
            Big(Num(0, 0) + Num(2, 0) - Width),
            Big(Num(1, 0) + Num(2, 0) - Width));
        end
        else
        begin
          Width := Num(5, 1);
          Outer := CreateRoundRectRgn(Big(Num(0, 0)), Big(Num(1, 0)),
                                      Big(Num(2, 0)) + 1, Big(Num(3, 0)) + 1,
                                      2 * Big(Num(4, 0)), 2 * Big(Num(4, 0)));
          Inner := CreateRoundRectRgn(Big(Num(0, 0) + Width),
                                      Big(Num(1, 0) + Width),
                                      Big(Num(2, 0) - Width) + 1,
                                      Big(Num(3, 0) - Width) + 1,
                                      2 * Big(Num(4, 0) - Width),
                                      2 * Big(Num(4, 0) - Width));
        end;
        CombineRgn(Outer, Outer, Inner, RGN_DIFF);
        InkBrush := CreateSolidBrush(0);
        FillRgn(ACanvas.Handle, Outer, InkBrush);
        DeleteObject(InkBrush);
        DeleteObject(Inner);
        DeleteObject(Outer);
      end
      else if (Op = 'P') or (Op = 'Q') then
      begin
        SetInk(Op = 'Q');
        PointCount := Length(Nums) div 2;
        if PointCount < 3 then
          Continue;
        SetLength(Points, PointCount);
        for PointIdx := 0 to PointCount - 1 do
          Points[PointIdx] := Point(Big(Nums[PointIdx * 2]),
                                    Big(Nums[PointIdx * 2 + 1]));
        ACanvas.Polygon(Points);
      end;
    end;
  finally
    Words.Free;
    Commands.Free;
  end;
end;

end.
""")
# В корень проекта: CP1251 и CRLF, как остальные модули
import os
text=''.join(out).replace('\r\n','\n').replace('\n','\r\n')
dst=os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','..','DsgIcons.pas')
open(dst,'wb').write(text.encode('cp1251'))
print('ok')
