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
function NoEols(const S: string): string;

// Равны ли тексты, если не считать CR и LF (без копий строк)
function SameNoEols(const A, B: string): Boolean;

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
function NoEols(const S: string): string;
var
  I, N: Integer;
  P: PChar;
begin
  SetLength(Result, Length(S));
  N := 0;
  P := PChar(Result);
  for I := 1 to Length(S) do
    if (S[I] <> #13) and (S[I] <> #10) then
    begin
      P[N] := S[I];
      Inc(N);
    end;
  SetLength(Result, N);
end;

// Равны ли тексты, если не считать CR и LF. Идёт по обоим сразу, пропуская
// переводы строк; на первом несовпадении выходит. Копий строк не делает,
// в отличие от NoEols(A) = NoEols(B).
function SameNoEols(const A, B: string): Boolean;
var
  I, J, LA, LB: Integer;
begin
  I := 1;
  J := 1;
  LA := Length(A);
  LB := Length(B);
  while True do
  begin
    while (I <= LA) and ((A[I] = #13) or (A[I] = #10)) do
      Inc(I);
    while (J <= LB) and ((B[J] = #13) or (B[J] = #10)) do
      Inc(J);
    if (I > LA) or (J > LB) then
      Break;
    if A[I] <> B[J] then
    begin
      Result := False;
      Exit;
    end;
    Inc(I);
    Inc(J);
  end;
  // Равны, только если оба кончились
  Result := (I > LA) and (J > LB);
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
procedure MergeDiff(A, B: TStrings; ASide: Integer; var H: TMergeHunks);
const
  MaxCells = 4000000;
var
  Pre, SufA, SufB, N, M, I, J, K, S1, S2: Integer;
  L: array of array of SmallInt;

  procedure Add(ABS, ABE, AOS, AOE: Integer);
  begin
    if (ABS = ABE) and (AOS = AOE) then
      Exit;
    K := Length(H);
    SetLength(H, K + 1);
    H[K].BS := ABS;
    H[K].BE := ABE;
    H[K].OS := AOS;
    H[K].OE := AOE;
    H[K].Side := ASide;
  end;

begin
  Pre := 0;
  while (Pre < A.Count) and (Pre < B.Count) and (A[Pre] = B[Pre]) do
    Inc(Pre);
  SufA := A.Count;
  SufB := B.Count;
  while (SufA > Pre) and (SufB > Pre) and (A[SufA - 1] = B[SufB - 1]) do
  begin
    Dec(SufA);
    Dec(SufB);
  end;
  N := SufA - Pre;
  M := SufB - Pre;
  if (N = 0) and (M = 0) then
    Exit;
  if (N = 0) or (M = 0) or (Int64(N + 1) * (M + 1) > MaxCells) or
     (N > 32000) or (M > 32000) then
  begin
    Add(Pre, SufA, Pre, SufB);
    Exit;
  end;

  // L[I][J] - длина общей подпоследовательности хвостов A[Pre+I..] и
  // B[Pre+J..] в пределах середины
  SetLength(L, N + 1, M + 1);
  for I := N - 1 downto 0 do
    for J := M - 1 downto 0 do
      if A[Pre + I] = B[Pre + J] then
        L[I][J] := L[I + 1][J + 1] + 1
      else if L[I + 1][J] >= L[I][J + 1] then
        L[I][J] := L[I + 1][J]
      else
        L[I][J] := L[I][J + 1];

  I := 0;
  J := 0;
  S1 := -1;
  S2 := -1;
  while (I < N) or (J < M) do
  begin
    if (I < N) and (J < M) and (A[Pre + I] = B[Pre + J]) then
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
      if (J >= M) or ((I < N) and (L[I + 1][J] >= L[I][J + 1])) then
        Inc(I)
      else
        Inc(J);
    end;
  end;
  if S1 >= 0 then
    Add(Pre + S1, Pre + N, Pre + S2, Pre + M);
end;

// Версия стороны на участке предка [GS, GE): строки предка, где сторона
// ничего не меняла, и её строки на месте её правок
procedure MergeSideText(Base, Own: TStrings; const H: TMergeHunks;
                        ASide, GS, GE: Integer; AOut: TStrings);
var
  I, K, P: Integer;
begin
  P := GS;
  for I := 0 to High(H) do
  begin
    if (H[I].Side <> ASide) or (H[I].BS < GS) or (H[I].BE > GE) then
      Continue;
    if (H[I].BS = H[I].BE) and (H[I].BS = GE) and (GE > GS) then
      Continue;   // вставка на границе - не этого участка
    for K := P to H[I].BS - 1 do
      AOut.Add(Base[K]);
    for K := H[I].OS to H[I].OE - 1 do
      AOut.Add(Own[K]);
    if H[I].BE > P then
      P := H[I].BE
    else if H[I].BS > P then
      P := H[I].BS;
  end;
  for K := P to GE - 1 do
    AOut.Add(Base[K]);
end;

// Слить: предок ABase, окно AMine, диск ATheirs. AConflicts - число
// участков с метками.
function Merge3(const ABase, AMine, ATheirs: string;
                var AConflicts: Integer): string;
var
  B, Mi, Th, Res, X, Y: TStringList;
  H: TMergeHunks;
  I, J, K, Pos0, GS, GE: Integer;
  T: TMergeHunk;
  HasMine, HasTheirs: Boolean;
begin
  AConflicts := 0;
  B := TStringList.Create;
  Mi := TStringList.Create;
  Th := TStringList.Create;
  Res := TStringList.Create;
  X := TStringList.Create;
  Y := TStringList.Create;
  try
    B.Text := ABase;
    Mi.Text := AMine;
    Th.Text := ATheirs;
    SetLength(H, 0);
    MergeDiff(B, Mi, 0, H);
    MergeDiff(B, Th, 1, H);

    // По началу участка; при равном начале - сначала вставки
    for I := 1 to High(H) do
    begin
      T := H[I];
      J := I - 1;
      while (J >= 0) and ((H[J].BS > T.BS) or
            ((H[J].BS = T.BS) and (H[J].BE > T.BE))) do
      begin
        H[J + 1] := H[J];
        Dec(J);
      end;
      H[J + 1] := T;
    end;

    Pos0 := 0;
    I := 0;
    while I <= High(H) do
    begin
      // Группа пересекающихся участков: правки обеих сторон в ней
      // касаются одних и тех же строк предка
      GS := H[I].BS;
      GE := H[I].BE;
      HasMine := H[I].Side = 0;
      HasTheirs := H[I].Side = 1;
      J := I + 1;
      while (J <= High(H)) and ((H[J].BS < GE) or (H[J].BS = GS)) do
      begin
        if H[J].BE > GE then
          GE := H[J].BE;
        if H[J].Side = 0 then
          HasMine := True
        else
          HasTheirs := True;
        Inc(J);
      end;

      for K := Pos0 to GS - 1 do
        Res.Add(B[K]);

      X.Clear;
      Y.Clear;
      if HasMine then
        MergeSideText(B, Mi, Copy(H, I, J - I), 0, GS, GE, X);
      if HasTheirs then
        MergeSideText(B, Th, Copy(H, I, J - I), 1, GS, GE, Y);

      if HasMine and not HasTheirs then
        Res.AddStrings(X)
      else if HasTheirs and not HasMine then
        Res.AddStrings(Y)
      else if X.Text = Y.Text then
        Res.AddStrings(X)   // обе стороны сделали одно и то же
      else
      begin
        Inc(AConflicts);
        Res.Add('<<<<<<< в окне');
        Res.AddStrings(X);
        Res.Add('=======');
        Res.AddStrings(Y);
        Res.Add('>>>>>>> на диске');
      end;
      Pos0 := GE;
      I := J;
    end;
    for K := Pos0 to B.Count - 1 do
      Res.Add(B[K]);
    Result := Res.Text;
  finally
    Y.Free;
    X.Free;
    Res.Free;
    Th.Free;
    Mi.Free;
    B.Free;
  end;
end;

end.
