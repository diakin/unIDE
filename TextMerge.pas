unit TextMerge;

// ---------------------------------------------------------------------------
//  Слияние трёх версий текста по строкам - для файла, изменённого снаружи,
//  пока в окне есть свои правки: общий предок (что было на диске при
//  чтении), текст окна и текст на диске сейчас. Изменения, которые не
//  задевают одни и те же строки, переносятся оба. Разные изменения одних и
//  тех же строк - конфликт, в текст ставятся метки:
//    <<<<<<< в окне
//    ...
//    =======
//    ...
//    >>>>>>> на диске
//
//  Вынесено из Unit1 без изменения поведения. Без VCL.
// ---------------------------------------------------------------------------

interface

uses
  SysUtils, Classes;

// Текст без CR и LF - чтобы переводы строк не считались разницей
function NoEols(const Str: string): string;

// Равны ли тексты, если не считать CR и LF (без копий строк)
function SameNoEols(const ArgStr, BufStr: string): Boolean;

// Слить: предок ABase, окно AMine, диск ATheirs. AConflicts - число
// участков с метками.
function Merge3(const ABase, AMine, ATheirs: string;
                var AConflicts: Integer): string;

implementation

// Текст без CR и LF - чтобы переводы строк не считались разницей.
//
// Один проход по строке, память под результат - один раз. StringReplace
// из SysUtils Delphi 7 на каждую замену копирует остаток строки заново, и
// время растёт быстрее квадрата длины: тем же алгоритмом на тексте в
// 16 000 строк (734 КБ) - около 12 с на один вызов. На файле размером с
// Unit1.pas (31 000 строк) - порядка минуты, а проверка изменений на диске
// (CheckDiskChanges) зовёт NoEols дважды.
function NoEols(const Str: string): string;
var
  I, Num: Integer;
  CharPtr: PChar;
begin
  SetLength(Result, Length(Str));
  Num := 0;
  CharPtr := PChar(Result);
  for I := 1 to Length(Str) do
    if (Str[I] <> #13) and (Str[I] <> #10) then
    begin
      CharPtr[Num] := Str[I];
      Inc(Num);
    end;
  SetLength(Result, Num);
end;

// Равны ли тексты, если не считать CR и LF. Идёт по обоим сразу, пропуская
// переводы строк; на первом несовпадении выходит. Копий строк не делает,
// в отличие от NoEols(A) = NoEols(B).
function SameNoEols(const ArgStr, BufStr: string): Boolean;
var
  Idx, Idx2, LA, LB: Integer;
begin
  Idx := 1;
  Idx2 := 1;
  LA := Length(ArgStr);
  LB := Length(BufStr);
  while True do
  begin
    while (Idx <= LA) and ((ArgStr[Idx] = #13) or (ArgStr[Idx] = #10)) do
      Inc(Idx);
    while (Idx2 <= LB) and ((BufStr[Idx2] = #13) or (BufStr[Idx2] = #10)) do
      Inc(Idx2);
    if (Idx > LA) or (Idx2 > LB) then
      Break;
    if ArgStr[Idx] <> BufStr[Idx2] then
    begin
      Result := False;
      Exit;
    end;
    Inc(Idx);
    Inc(Idx2);
  end;
  // Равны, только если оба кончились
  Result := (Idx > LA) and (Idx2 > LB);
end;

type
  // Участок правки: строки предка [BS, BE) заменены строками [OS, OE)
  // своей версии. BS = BE - вставка.
  TMergeHunk = record
    BS, BE, OS, OE: Integer;
    Side: Integer;   // 0 - окно, 1 - диск
  end;
  TMergeHunks = array of TMergeHunk;

// Правки от A (предок) к B. Общие начало и конец отбрасываются; середина -
// по наибольшей общей подпоследовательности строк, если она не слишком
// велика, иначе одним участком.
procedure MergeDiff(StrList, StrList2: TStrings; ASide: Integer; var MergeHunks: TMergeHunks);
const
  MaxCells = 4000000;
var
  Pre, SufA, SufB, Num, Mid, I, J, Idx3, S1, S2: Integer;
  LcsLen: array of array of SmallInt;

  procedure Add(ABS, ABE, AOS, AOE: Integer);
  begin
    if (ABS = ABE) and (AOS = AOE) then
      Exit;
    Idx3 := Length(MergeHunks);
    SetLength(MergeHunks, Idx3 + 1);
    MergeHunks[Idx3].BS := ABS;
    MergeHunks[Idx3].BE := ABE;
    MergeHunks[Idx3].OS := AOS;
    MergeHunks[Idx3].OE := AOE;
    MergeHunks[Idx3].Side := ASide;
  end;

begin
  Pre := 0;
  while (Pre < StrList.Count) and (Pre < StrList2.Count) and (StrList[Pre] = StrList2[Pre]) do
    Inc(Pre);
  SufA := StrList.Count;
  SufB := StrList2.Count;
  while (SufA > Pre) and (SufB > Pre) and (StrList[SufA - 1] = StrList2[SufB - 1]) do
  begin
    Dec(SufA);
    Dec(SufB);
  end;
  Num := SufA - Pre;
  Mid := SufB - Pre;
  if (Num = 0) and (Mid = 0) then
    Exit;
  if (Num = 0) or (Mid = 0) or (Int64(Num + 1) * (Mid + 1) > MaxCells) or
     (Num > 32000) or (Mid > 32000) then
  begin
    Add(Pre, SufA, Pre, SufB);
    Exit;
  end;

  // L[I][J] - длина общей подпоследовательности хвостов A[Pre+I..] и
  // B[Pre+J..] в пределах середины
  SetLength(LcsLen, Num + 1, Mid + 1);
  for I := Num - 1 downto 0 do
    for J := Mid - 1 downto 0 do
      if StrList[Pre + I] = StrList2[Pre + J] then
        LcsLen[I][J] := LcsLen[I + 1][J + 1] + 1
      else if LcsLen[I + 1][J] >= LcsLen[I][J + 1] then
        LcsLen[I][J] := LcsLen[I + 1][J]
      else
        LcsLen[I][J] := LcsLen[I][J + 1];

  I := 0;
  J := 0;
  S1 := -1;
  S2 := -1;
  while (I < Num) or (J < Mid) do
  begin
    if (I < Num) and (J < Mid) and (StrList[Pre + I] = StrList2[Pre + J]) then
    begin
      if S1 >= 0 then
      begin
        Add(Pre + S1, Pre + I, Pre + S2, Pre + J);
        S1 := -1;
      end;
      Inc(I);
      Inc(J);
    end
    else
    begin
      if S1 < 0 then
      begin
        S1 := I;
        S2 := J;
      end;
      if (J >= Mid) or ((I < Num) and (LcsLen[I + 1][J] >= LcsLen[I][J + 1])) then
        Inc(I)
      else
        Inc(J);
    end;
  end;
  if S1 >= 0 then
    Add(Pre + S1, Pre + Num, Pre + S2, Pre + Mid);
end;

// Версия стороны на участке предка [GS, GE): строки предка, где сторона
// ничего не меняла, и её строки на месте её правок
procedure MergeSideText(Base, Own: TStrings; const MergeHunks: TMergeHunks;
                        ASide, GS, GE: Integer; AOut: TStrings);
var
  I, K, CharPos: Integer;
begin
  CharPos := GS;
  for I := 0 to High(MergeHunks) do
  begin
    if (MergeHunks[I].Side <> ASide) or (MergeHunks[I].BS < GS) or (MergeHunks[I].BE > GE) then
      Continue;
    if (MergeHunks[I].BS = MergeHunks[I].BE) and (MergeHunks[I].BS = GE) and (GE > GS) then
      Continue;   // вставка на границе - не этого участка
    for K := CharPos to MergeHunks[I].BS - 1 do
      AOut.Add(Base[K]);
    for K := MergeHunks[I].OS to MergeHunks[I].OE - 1 do
      AOut.Add(Own[K]);
    if MergeHunks[I].BE > CharPos then
      CharPos := MergeHunks[I].BE
    else if MergeHunks[I].BS > CharPos then
      CharPos := MergeHunks[I].BS;
  end;
  for K := CharPos to GE - 1 do
    AOut.Add(Base[K]);
end;

// Слить: предок ABase, окно AMine, диск ATheirs. AConflicts - число
// участков с метками.
function Merge3(const ABase, AMine, ATheirs: string;
                var AConflicts: Integer): string;
var
  StrList, Mi, Th, Res, StrList2, StrList3: TStringList;
  MergeHunks: TMergeHunks;
  I, Idx2, K, Pos0, GS, GE: Integer;
  MergeHunk: TMergeHunk;
  HasMine, HasTheirs: Boolean;
begin
  AConflicts := 0;
  StrList := TStringList.Create;
  Mi := TStringList.Create;
  Th := TStringList.Create;
  Res := TStringList.Create;
  StrList2 := TStringList.Create;
  StrList3 := TStringList.Create;
  try
    StrList.Text := ABase;
    Mi.Text := AMine;
    Th.Text := ATheirs;
    SetLength(MergeHunks, 0);
    MergeDiff(StrList, Mi, 0, MergeHunks);
    MergeDiff(StrList, Th, 1, MergeHunks);

    // По началу участка; при равном начале - сначала вставки
    for I := 1 to High(MergeHunks) do
    begin
      MergeHunk := MergeHunks[I];
      Idx2 := I - 1;
      while (Idx2 >= 0) and ((MergeHunks[Idx2].BS > MergeHunk.BS) or
            ((MergeHunks[Idx2].BS = MergeHunk.BS) and (MergeHunks[Idx2].BE > MergeHunk.BE))) do
      begin
        MergeHunks[Idx2 + 1] := MergeHunks[Idx2];
        Dec(Idx2);
      end;
      MergeHunks[Idx2 + 1] := MergeHunk;
    end;

    Pos0 := 0;
    I := 0;
    while I <= High(MergeHunks) do
    begin
      // Группа пересекающихся участков: правки обеих сторон в ней
      // касаются одних и тех же строк предка
      GS := MergeHunks[I].BS;
      GE := MergeHunks[I].BE;
      HasMine := MergeHunks[I].Side = 0;
      HasTheirs := MergeHunks[I].Side = 1;
      Idx2 := I + 1;
      while (Idx2 <= High(MergeHunks)) and ((MergeHunks[Idx2].BS < GE) or (MergeHunks[Idx2].BS = GS)) do
      begin
        if MergeHunks[Idx2].BE > GE then
          GE := MergeHunks[Idx2].BE;
        if MergeHunks[Idx2].Side = 0 then
          HasMine := True
        else
          HasTheirs := True;
        Inc(Idx2);
      end;

      for K := Pos0 to GS - 1 do
        Res.Add(StrList[K]);

      StrList2.Clear;
      StrList3.Clear;
      if HasMine then
        MergeSideText(StrList, Mi, Copy(MergeHunks, I, Idx2 - I), 0, GS, GE, StrList2);
      if HasTheirs then
        MergeSideText(StrList, Th, Copy(MergeHunks, I, Idx2 - I), 1, GS, GE, StrList3);

      if HasMine and not HasTheirs then
        Res.AddStrings(StrList2)
      else if HasTheirs and not HasMine then
        Res.AddStrings(StrList3)
      else if StrList2.Text = StrList3.Text then
        Res.AddStrings(StrList2)   // обе стороны сделали одно и то же
      else
      begin
        Inc(AConflicts);
        Res.Add('<<<<<<< в окне');
        Res.AddStrings(StrList2);
        Res.Add('=======');
        Res.AddStrings(StrList3);
        Res.Add('>>>>>>> на диске');
      end;
      Pos0 := GE;
      I := Idx2;
    end;
    for K := Pos0 to StrList.Count - 1 do
      Res.Add(StrList[K]);
    Result := Res.Text;
  finally
    StrList3.Free;
    StrList2.Free;
    Res.Free;
    Th.Free;
    Mi.Free;
    StrList.Free;
  end;
end;

end.
