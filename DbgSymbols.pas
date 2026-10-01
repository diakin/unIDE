unit DbgSymbols;

// ---------------------------------------------------------------------------
//  Отладочная информация TD32 из exe и значения переменных (окно Watch)
//
//  dcc32 с ключом -V дописывает в конец exe отладочную информацию в
//  формате Borland TD32. Последние 8 байт файла - подпись 'FB09' и
//  расстояние от конца файла до начала блока; в начале блока - та же
//  подпись и смещение каталога подразделов. Все смещения в каталоге -
//  от начала блока.
//
//  Нужные подразделы:
//    $130 - имена: символы и типы хранят номер имени (с 1), а не текст;
//    $12B - типы: таблица смещений записей типов, номер типа $1000 + i;
//    $125 - символы модуля: процедуры ($204/$205) со вложенными в них
//           локальными переменными и параметрами ($200 - смещение от EBP,
//           $002 - в регистре), данные модуля ($201/$202); область
//           процедуры, блока, with закрывает запись $006.
//
//  Устройство записей - по разбору формата в map2dbg/tds2pdb (Program.cs)
//  и JclTD32.pas: запись символа - длина (без самого поля длины), вид,
//  поля; запись типа - длина, вид (leaf), поля; номера типов меньше $1000 -
//  простые типы CodeView (биты 8-10 - указатель, 4-7 - вид, 0-2 - размер).
//
//  Сегмент данных символа - номер в карте сегментов: 1 - CODE, 2 - DATA,
//  3 - BSS. Адрес - база образа + адрес секции exe + смещение.
//
//  Выражение в окне Watch: имя или цепочка через точку (Self.FCount,
//  Rec.Field, Form1.Edit1). Имя ищется среди локальных переменных и
//  параметров процедуры, где стоит программа, потом среди данных модулей,
//  потом среди полей Self. Значение форматируется по типу: числа, символы,
//  Boolean, вещественные, строки, указатели, объекты (класс и адрес),
//  записи и массивы (поля и элементы, без глубокой вложенности),
//  перечисления и множества.
// ---------------------------------------------------------------------------

interface

uses
  Windows, SysUtils, Classes;

type
  // Чтение памяти программы: False - не прочитано
  TDbgReadMem = function(AAddress: Cardinal; ABuffer: Pointer;
                         ASize: Integer): Boolean of object;

  // Регистры потока на остановке: EAX, ECX, EDX, EBX, ESP, EBP, ESI, EDI
  TDbgRegs = array[0..7] of Cardinal;

  TDbgProcSym = record
    Name: string;
    Segment: Integer;
    Offset: Cardinal;
    Size: Cardinal;
    DebugStart: Cardinal;   // от начала процедуры: кадр EBP уже построен
    Module: Integer;
    Parent: Integer;        // объемлющая процедура, -1 - нет
  end;

  TDbgLocalSym = record
    Name: string;
    Kind: Integer;          // DbgLocal* ниже
    BpOffset: Integer;      // DbgLocalFrame: от EBP
    RegNo: Integer;         // DbgLocalReg: номер регистра CodeView
    Segment: Integer;       // DbgLocalData
    Offset: Cardinal;
    TypeId: Cardinal;
    ProcIdx: Integer;
  end;

  TDbgDataSym = record
    Name: string;
    Segment: Integer;
    Offset: Cardinal;
    TypeId: Cardinal;
    Module: Integer;
  end;

  TDbgSymbols = class
  private
    FBuf: string;              // файл exe целиком (байты)
    FNames: array of string;
    FTypePos: array of Integer;   // начало записи типа в FBuf (с 0)
    FProcs: array of TDbgProcSym;
    FProcCount: Integer;
    FLocals: array of TDbgLocalSym;
    FLocalCount: Integer;
    FDatas: array of TDbgDataSym;
    FDataCount: Integer;
    FSegRva: array[1..3] of Cardinal;
    FClassIndex: TStringList;  // имя класса/записи -> полное описание
    // Вычисление: память программы и регистры остановки
    FReadMem: TDbgReadMem;
    FRegValue: Cardinal;       // значение переменной в регистре
    FRegActive: Boolean;       // адрес 0 - это FRegValue
    function ByteAt(APos: Integer): Cardinal;
    function WordAt(APos: Integer): Cardinal;
    function DwordAt(APos: Integer): Cardinal;
    function NameOf(AIndex: Cardinal): string;
    function ReadNumeric(var APos: Integer; var AValue: Int64): Boolean;
    procedure ParseNames(APos: Integer);
    procedure ParseTypes(APos: Integer);
    procedure ParseSymbols(APos, AEnd, AModule: Integer; ASkipSig: Boolean);
    procedure AddProc(const AProc: TDbgProcSym);
    procedure AddLocal(const ALocal: TDbgLocalSym);
    procedure AddData(const AData: TDbgDataSym);
    procedure ReadSections;
    function TypeRec(ATypeId: Cardinal; var ALeaf, ABody, AEnd: Integer): Boolean;
    function Underlying(ATypeId: Cardinal): Cardinal;
    function FullStruct(ATypeId: Cardinal): Cardinal;
    function TypeSize(ATypeId: Cardinal): Integer;
    function TypeText(ATypeId: Cardinal): string;
    function NextMember(var APos: Integer; AEnd: Integer;
                        var ALeaf: Integer; var AType, AName: Cardinal;
                        var AValue: Int64): Boolean;
    function FindMember(AStructId: Cardinal; const AName: string;
                        var AOffset: Integer; var AMemberType: Cardinal): Boolean;
    function EnumName(AEnumId: Cardinal; AValue: Int64): string;
    function ReadMem(AAddress: Cardinal; ABuffer: Pointer; ASize: Integer): Boolean;
    function ReadDword(AAddress: Cardinal; var AValue: Cardinal): Boolean;
    function ReadAnsiText(AAddress: Cardinal; ALen: Integer): string;
    function ClassNameAt(AObject: Cardinal): string;
    function FormatPrimitive(AAddress, ATypeId: Cardinal): string;
    function FormatValue(AAddress, ATypeId: Cardinal; ADepth: Integer): string;
    function FindProc(ACodeOfs: Cardinal): Integer;
    function FindLocal(AProcIdx: Integer; const AName: string): Integer;
    function FindData(const AName: string; AModule: Integer): Integer;
    function SegAddress(ASeg: Integer; AOffset, AImageBase: Cardinal;
                        var AAddress: Cardinal): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    // False - в exe нет TD32 (сборка без -V) или блок повреждён; AError -
    // причина словами
    function LoadFromExe(const AExeFile: string; var AError: string): Boolean;
    // Значение выражения на остановке: AEip - где стоит поток, ARegs - его
    // регистры (EBP - кадр процедуры). ATypeText - тип словами.
    function Evaluate(const AExpr: string; AImageBase, AEip: Cardinal;
                      const ARegs: TDbgRegs; AReadMem: TDbgReadMem;
                      var ATypeText: string): string;
    // Процедура, где стоит программа (имя, '' - нет в TD32), и имена её
    // параметров и локальных переменных по порядку описания
    function ProcLocals(AImageBase, AEip: Cardinal; AList: TStrings): string;
    property ProcCount: Integer read FProcCount;
    property LocalCount: Integer read FLocalCount;
    property DataCount: Integer read FDataCount;
  end;

const
  DbgLocalFrame = 1;   // [EBP + смещение]
  DbgLocalReg   = 2;   // в регистре
  DbgLocalData  = 3;   // статическая (типизированная константа процедуры)

implementation

const
  Td32SigDelphi = $39304246;   // 'FB09'
  Td32SigBcb    = $41304246;   // 'FB0A'

  SubNames       = $130;
  SubGlobalTypes = $12B;
  SubAlignSym    = $125;
  SubGlobalSym   = $129;

  SymRegister = $0002;
  SymEnd      = $0006;
  SymBpRel32  = $0200;
  SymLData32  = $0201;
  SymGData32  = $0202;
  SymLProc32  = $0204;
  SymGProc32  = $0205;
  SymThunk32  = $0206;
  SymBlock32  = $0207;
  SymWith32   = $0208;

  LeafModifier  = $0001;
  LeafPointer   = $0002;
  LeafArray     = $0003;
  LeafClass     = $0004;
  LeafStruct    = $0005;
  LeafEnum      = $0007;
  LeafProcedure = $0008;
  LeafPasSet    = $0030;
  LeafSubrange  = $0031;
  LeafPString   = $0033;
  LeafClosure   = $0034;
  LeafLString   = $0036;
  LeafVariant   = $0037;
  LeafClassRef  = $0038;

  MemRealBase    = $0400;
  MemVirtBaseDir = $0401;
  MemVirtBaseInd = $0402;
  MemEnumerate   = $0403;
  MemIndex       = $0405;
  MemData        = $0406;
  MemStaticData  = $0407;
  MemMethod      = $0408;
  MemNested      = $0409;
  MemVtabPtr     = $040A;

  StructFwdRef  = $0080;   // свойства записи/класса: только объявление

  MaxShowText   = 255;     // символов строки в окне
  MaxShowItems  = 16;      // элементов массива, полей записи
  MaxDepth      = 2;       // вложенность записей и массивов
  VmtClassNameOfs = -44;   // vmtClassName в System.pas Delphi 7

constructor TDbgSymbols.Create;
begin
  inherited Create;
  FClassIndex := TStringList.Create;
  FClassIndex.Sorted := True;
  FClassIndex.Duplicates := dupIgnore;
  FClassIndex.CaseSensitive := False;
end;

destructor TDbgSymbols.Destroy;
begin
  FClassIndex.Free;
  inherited Destroy;
end;

// ---------------------------------------------------------------------------
//  Байты блока (позиции с 0; за пределами - 0)
// ---------------------------------------------------------------------------

function TDbgSymbols.ByteAt(APos: Integer): Cardinal;
begin
  if (APos < 0) or (APos >= Length(FBuf)) then
    Result := 0
  else
    Result := Ord(FBuf[APos + 1]);
end;

function TDbgSymbols.WordAt(APos: Integer): Cardinal;
begin
  Result := ByteAt(APos) or (ByteAt(APos + 1) shl 8);
end;

function TDbgSymbols.DwordAt(APos: Integer): Cardinal;
begin
  Result := WordAt(APos) or (WordAt(APos + 2) shl 16);
end;

function TDbgSymbols.NameOf(AIndex: Cardinal): string;
begin
  if (AIndex = 0) or (Integer(AIndex) > Length(FNames)) then
    Result := ''
  else
    Result := FNames[AIndex - 1];
end;

// Число CodeView: меньше $8000 - само значение, иначе вид и значение за ним
function TDbgSymbols.ReadNumeric(var APos: Integer; var AValue: Int64): Boolean;
var
  Kind: Cardinal;
begin
  Result := True;
  Kind := WordAt(APos);
  Inc(APos, 2);
  if Kind < $8000 then
  begin
    AValue := Kind;
    Exit;
  end;
  case Kind of
    $8000:
      begin
        AValue := ShortInt(ByteAt(APos));
        Inc(APos, 1);
      end;
    $8001:
      begin
        AValue := SmallInt(WordAt(APos));
        Inc(APos, 2);
      end;
    $8002:
      begin
        AValue := WordAt(APos);
        Inc(APos, 2);
      end;
    $8003:
      begin
        AValue := Integer(DwordAt(APos));
        Inc(APos, 4);
      end;
    $8004:
      begin
        AValue := DwordAt(APos);
        Inc(APos, 4);
      end;
    $8009, $800A:
      begin
        AValue := Int64(DwordAt(APos)) or (Int64(DwordAt(APos + 4)) shl 32);
        Inc(APos, 8);
      end;
  else
    AValue := 0;
    Result := False;
  end;
end;

// ---------------------------------------------------------------------------
//  Загрузка
// ---------------------------------------------------------------------------

function TDbgSymbols.LoadFromExe(const AExeFile: string;
                                 var AError: string): Boolean;
var
  Stream: TFileStream;
  FileLen, BasePos, DirPos, HeadSize, EntrySize, EntryCount: Integer;
  EntryIdx, EntryPos, SubType, SubModule, SubPos, SubSize: Integer;
  TailSig, TailOfs: Cardinal;
begin
  Result := False;
  AError := '';
  FBuf := '';
  try
    Stream := TFileStream.Create(AExeFile, fmOpenRead or fmShareDenyNone);
    try
      SetLength(FBuf, Stream.Size);
      if Length(FBuf) > 0 then
        Stream.ReadBuffer(FBuf[1], Length(FBuf));
    finally
      Stream.Free;
    end;
  except
    on E: Exception do
    begin
      AError := 'не удалось прочитать ' + AExeFile + ': ' + E.Message;
      FBuf := '';
      Exit;
    end;
  end;

  FileLen := Length(FBuf);
  TailSig := DwordAt(FileLen - 8);
  TailOfs := DwordAt(FileLen - 4);
  if ((TailSig <> Td32SigDelphi) and (TailSig <> Td32SigBcb)) or
     (TailOfs < 8) or (Integer(TailOfs) > FileLen) then
  begin
    AError := 'в exe нет отладочной информации TD32 (нужна сборка с -V)';
    FBuf := '';
    Exit;
  end;
  BasePos := FileLen - Integer(TailOfs);
  if (DwordAt(BasePos) <> Td32SigDelphi) and (DwordAt(BasePos) <> Td32SigBcb) then
  begin
    AError := 'блок TD32 в exe не распознан';
    FBuf := '';
    Exit;
  end;

  DirPos := BasePos + Integer(DwordAt(BasePos + 4));
  HeadSize := WordAt(DirPos);
  EntrySize := WordAt(DirPos + 2);
  EntryCount := Integer(DwordAt(DirPos + 4));
  if (HeadSize < 8) or (EntrySize < 12) or (EntryCount <= 0) or
     (DirPos + HeadSize + EntryCount * EntrySize > FileLen) then
  begin
    AError := 'каталог TD32 повреждён';
    FBuf := '';
    Exit;
  end;

  // Сначала имена и типы: символы ссылаются на них
  for EntryIdx := 0 to EntryCount - 1 do
  begin
    EntryPos := DirPos + HeadSize + EntryIdx * EntrySize;
    SubType := WordAt(EntryPos);
    SubPos := BasePos + Integer(DwordAt(EntryPos + 4));
    if SubType = SubNames then
      ParseNames(SubPos)
    else if SubType = SubGlobalTypes then
      ParseTypes(SubPos);
  end;
  for EntryIdx := 0 to EntryCount - 1 do
  begin
    EntryPos := DirPos + HeadSize + EntryIdx * EntrySize;
    SubType := WordAt(EntryPos);
    SubModule := SmallInt(WordAt(EntryPos + 2));
    SubPos := BasePos + Integer(DwordAt(EntryPos + 4));
    SubSize := Integer(DwordAt(EntryPos + 8));
    if SubType = SubAlignSym then
      // В начале - подпись (DWORD), за ней записи
      ParseSymbols(SubPos, SubPos + SubSize, SubModule, True)
    else if SubType = SubGlobalSym then
      // Заголовок: два WORD и семь DWORD, первый DWORD - размер символов
      ParseSymbols(SubPos + 32,
                   SubPos + 32 + Integer(DwordAt(SubPos + 4)), 0, False);
  end;
  SetLength(FProcs, FProcCount);
  SetLength(FLocals, FLocalCount);
  SetLength(FDatas, FDataCount);
  ReadSections;
  Result := FProcCount > 0;
  if not Result then
    AError := 'в TD32 нет процедур';
end;

procedure TDbgSymbols.ParseNames(APos: Integer);
var
  NameCount, NameIdx, NameLen: Integer;
begin
  NameCount := Integer(DwordAt(APos));
  if (NameCount < 0) or (NameCount > Length(FBuf)) then
    Exit;
  SetLength(FNames, NameCount);
  Inc(APos, 4);
  for NameIdx := 0 to NameCount - 1 do
  begin
    NameLen := ByteAt(APos);
    Inc(APos);
    FNames[NameIdx] := Copy(FBuf, APos + 1, NameLen);
    Inc(APos, NameLen);
    // Имя длиннее 255: длина взята по модулю 256, конец - по нулю
    while (APos < Length(FBuf)) and (ByteAt(APos) <> 0) do
      Inc(APos, 256);
    Inc(APos);
  end;
end;

procedure TDbgSymbols.ParseTypes(APos: Integer);
var
  TypeCount, TypeIdx: Integer;
begin
  TypeCount := Integer(DwordAt(APos + 4));
  if (TypeCount < 0) or (TypeCount > Length(FBuf) div 4) then
    Exit;
  SetLength(FTypePos, TypeCount);
  for TypeIdx := 0 to TypeCount - 1 do
    FTypePos[TypeIdx] := APos + Integer(DwordAt(APos + 8 + TypeIdx * 4));
end;

procedure TDbgSymbols.AddProc(const AProc: TDbgProcSym);
begin
  if FProcCount = Length(FProcs) then
    SetLength(FProcs, FProcCount + 1024);
  FProcs[FProcCount] := AProc;
  Inc(FProcCount);
end;

procedure TDbgSymbols.AddLocal(const ALocal: TDbgLocalSym);
begin
  if FLocalCount = Length(FLocals) then
    SetLength(FLocals, FLocalCount + 4096);
  FLocals[FLocalCount] := ALocal;
  Inc(FLocalCount);
end;

procedure TDbgSymbols.AddData(const AData: TDbgDataSym);
begin
  if FDataCount = Length(FDatas) then
    SetLength(FDatas, FDataCount + 1024);
  FDatas[FDataCount] := AData;
  Inc(FDataCount);
end;

// Символы модуля. Стек областей: процедура - её номер, блок/with/thunk -
// -1. Локальные относятся к ближайшей процедуре в стеке.
procedure TDbgSymbols.ParseSymbols(APos, AEnd, AModule: Integer;
                                   ASkipSig: Boolean);
var
  RecLen, RecType, Body, Depth, StackIdx, OwnerProc: Integer;
  Scope: array of Integer;
  Proc: TDbgProcSym;
  Local: TDbgLocalSym;
  Data: TDbgDataSym;
begin
  if ASkipSig then
    Inc(APos, 4);
  if AEnd > Length(FBuf) then
    AEnd := Length(FBuf);
  Depth := 0;
  SetLength(Scope, 64);
  while APos + 4 <= AEnd do
  begin
    RecLen := WordAt(APos);
    RecType := WordAt(APos + 2);
    Body := APos + 4;
    if RecLen < 2 then
      Break;

    OwnerProc := -1;
    for StackIdx := Depth - 1 downto 0 do
      if Scope[StackIdx] >= 0 then
      begin
        OwnerProc := Scope[StackIdx];
        Break;
      end;

    case RecType of
      SymLProc32, SymGProc32:
        begin
          // pParent, pEnd, pNext, длина, начало и конец отладки, смещение,
          // сегмент, тип, имя (одинаково в JclTD32 и tds2pdb)
          Proc.Size := DwordAt(Body + 12);
          Proc.DebugStart := DwordAt(Body + 16);
          Proc.Offset := DwordAt(Body + 24);
          Proc.Segment := WordAt(Body + 28);
          Proc.Name := NameOf(DwordAt(Body + 36));
          Proc.Module := AModule;
          Proc.Parent := OwnerProc;
          AddProc(Proc);
          if Depth = Length(Scope) then
            SetLength(Scope, Depth + 64);
          Scope[Depth] := FProcCount - 1;
          Inc(Depth);
        end;
      SymThunk32, SymBlock32, SymWith32:
        begin
          if Depth = Length(Scope) then
            SetLength(Scope, Depth + 64);
          Scope[Depth] := -1;
          Inc(Depth);
        end;
      SymEnd:
        if Depth > 0 then
          Dec(Depth);
      SymBpRel32:
        if OwnerProc >= 0 then
        begin
          Local.Kind := DbgLocalFrame;
          Local.BpOffset := Integer(DwordAt(Body));
          Local.TypeId := DwordAt(Body + 4);
          Local.Name := NameOf(DwordAt(Body + 8));
          Local.RegNo := 0;
          Local.Segment := 0;
          Local.Offset := 0;
          Local.ProcIdx := OwnerProc;
          AddLocal(Local);
        end;
      SymRegister:
        if OwnerProc >= 0 then
        begin
          Local.Kind := DbgLocalReg;
          Local.TypeId := DwordAt(Body);
          Local.RegNo := WordAt(Body + 4);
          Local.Name := NameOf(DwordAt(Body + 6));
          Local.BpOffset := 0;
          Local.Segment := 0;
          Local.Offset := 0;
          Local.ProcIdx := OwnerProc;
          AddLocal(Local);
        end;
      SymLData32, SymGData32:
        begin
          if OwnerProc >= 0 then
          begin
            Local.Kind := DbgLocalData;
            Local.Offset := DwordAt(Body);
            Local.Segment := WordAt(Body + 4);
            Local.TypeId := DwordAt(Body + 8);
            Local.Name := NameOf(DwordAt(Body + 12));
            Local.BpOffset := 0;
            Local.RegNo := 0;
            Local.ProcIdx := OwnerProc;
            AddLocal(Local);
          end
          else
          begin
            Data.Offset := DwordAt(Body);
            Data.Segment := WordAt(Body + 4);
            Data.TypeId := DwordAt(Body + 8);
            Data.Name := NameOf(DwordAt(Body + 12));
            Data.Module := AModule;
            AddData(Data);
          end;
        end;
    end;
    Inc(APos, RecLen + 2);
  end;
end;

// Адреса секций CODE, DATA, BSS по заголовку PE (тот же exe)
procedure TDbgSymbols.ReadSections;
var
  PeOfs, SecCount, OptSize, SecPos, SecIdx: Integer;
  SecName: string;
begin
  FillChar(FSegRva, SizeOf(FSegRva), 0);
  if WordAt(0) <> $5A4D then
    Exit;
  PeOfs := Integer(DwordAt($3C));
  if DwordAt(PeOfs) <> $00004550 then
    Exit;
  SecCount := WordAt(PeOfs + 6);
  OptSize := WordAt(PeOfs + 20);
  SecPos := PeOfs + 24 + OptSize;
  for SecIdx := 0 to SecCount - 1 do
  begin
    SecName := Copy(FBuf, SecPos + 1, 8);
    if Pos(#0, SecName) > 0 then
      SetLength(SecName, Pos(#0, SecName) - 1);
    SecName := UpperCase(SecName);
    if ((SecName = 'CODE') or (SecName = '.TEXT')) and (FSegRva[1] = 0) then
      FSegRva[1] := DwordAt(SecPos + 12)
    else if ((SecName = 'DATA') or (SecName = '.DATA')) and (FSegRva[2] = 0) then
      FSegRva[2] := DwordAt(SecPos + 12)
    else if ((SecName = 'BSS') or (SecName = '.BSS')) and (FSegRva[3] = 0) then
      FSegRva[3] := DwordAt(SecPos + 12);
    Inc(SecPos, 40);
  end;
end;

function TDbgSymbols.SegAddress(ASeg: Integer; AOffset, AImageBase: Cardinal;
                                var AAddress: Cardinal): Boolean;
begin
  Result := (ASeg >= 1) and (ASeg <= 3) and (FSegRva[ASeg] <> 0);
  if Result then
    AAddress := AImageBase + FSegRva[ASeg] + AOffset;
end;

// ---------------------------------------------------------------------------
//  Типы
// ---------------------------------------------------------------------------

// Запись типа: вид, начало полей и конец записи. Простые типы - False.
function TDbgSymbols.TypeRec(ATypeId: Cardinal;
                             var ALeaf, ABody, AEnd: Integer): Boolean;
var
  TypeIdx, RecPos: Integer;
begin
  Result := False;
  if ATypeId < $1000 then
    Exit;
  TypeIdx := Integer(ATypeId - $1000);
  if TypeIdx >= Length(FTypePos) then
    Exit;
  RecPos := FTypePos[TypeIdx];
  ALeaf := WordAt(RecPos + 2);
  ABody := RecPos + 4;
  AEnd := RecPos + 2 + Integer(WordAt(RecPos));
  Result := True;
end;

// Без модификаторов (const, volatile)
function TDbgSymbols.Underlying(ATypeId: Cardinal): Cardinal;
var
  Leaf, Body, RecEnd, Guard: Integer;
begin
  Result := ATypeId;
  Guard := 0;
  while TypeRec(Result, Leaf, Body, RecEnd) and (Leaf = LeafModifier) and
        (Guard < 16) do
  begin
    Result := DwordAt(Body + 2);
    Inc(Guard);
  end;
end;

// Класс или запись, объявленные заранее (fwdref): полное описание - другая
// запись того же имени
function TDbgSymbols.FullStruct(ATypeId: Cardinal): Cardinal;
var
  Leaf, Body, RecEnd, TypeIdx, Found: Integer;
  Props: Cardinal;
  StructName: string;
  OtherLeaf, OtherBody, OtherEnd: Integer;
begin
  Result := ATypeId;
  if not TypeRec(ATypeId, Leaf, Body, RecEnd) or
     not ((Leaf = LeafClass) or (Leaf = LeafStruct)) then
    Exit;
  Props := WordAt(Body + 6);
  if ((Props and StructFwdRef) = 0) and (DwordAt(Body + 2) <> 0) then
    Exit;
  StructName := NameOf(DwordAt(Body + 20));
  if StructName = '' then
    Exit;
  if FClassIndex.Count = 0 then
    // Указатель на полное описание - по имени, один раз на все имена
    for TypeIdx := 0 to High(FTypePos) do
      if TypeRec($1000 + Cardinal(TypeIdx), OtherLeaf, OtherBody, OtherEnd) and
         ((OtherLeaf = LeafClass) or (OtherLeaf = LeafStruct)) and
         ((WordAt(OtherBody + 6) and StructFwdRef) = 0) and
         (DwordAt(OtherBody + 2) <> 0) then
        FClassIndex.AddObject(NameOf(DwordAt(OtherBody + 20)),
                              TObject($1000 + TypeIdx));
  Found := FClassIndex.IndexOf(StructName);
  if Found >= 0 then
    Result := Cardinal(FClassIndex.Objects[Found]);
end;

// Размер значения типа в байтах; 0 - неизвестен
function TDbgSymbols.TypeSize(ATypeId: Cardinal): Integer;
const
  IntSizes: array[0..3] of Integer = (1, 2, 4, 8);
  RealSizes: array[0..4] of Integer = (4, 8, 10, 16, 6);
var
  Leaf, Body, RecEnd, NumPos: Integer;
  Kind, SizeCode: Cardinal;
  NumValue: Int64;
begin
  Result := 0;
  ATypeId := Underlying(ATypeId);
  if ATypeId < $1000 then
  begin
    if ((ATypeId shr 8) and 7) <> 0 then
    begin
      Result := 4;
      Exit;
    end;
    Kind := (ATypeId shr 4) and $F;
    SizeCode := ATypeId and $F;
    case Kind of
      1, 2, 3:
        if SizeCode <= 3 then
          Result := IntSizes[SizeCode];
      4:
        if SizeCode <= 4 then
          Result := RealSizes[SizeCode];
      6:
        if (SizeCode = 8) or (SizeCode = 9) then
          Result := 1;
      7:
        case SizeCode of
          0: Result := 1;
          1, 2, 3: Result := 2;
          4, 5: Result := 4;
          6, 7: Result := 8;
        end;
    end;
    Exit;
  end;
  if not TypeRec(ATypeId, Leaf, Body, RecEnd) then
    Exit;
  case Leaf of
    LeafPointer, LeafLString, LeafClassRef, LeafProcedure:
      Result := 4;
    LeafClosure:
      Result := 8;
    LeafVariant:
      Result := 16;
    LeafArray:
      begin
        NumPos := Body + 12;
        if ReadNumeric(NumPos, NumValue) then
          Result := Integer(NumValue);
      end;
    LeafStruct, LeafClass:
      begin
        NumPos := Body + 24;
        if ReadNumeric(NumPos, NumValue) then
          Result := Integer(NumValue);
      end;
    LeafEnum:
      Result := TypeSize(DwordAt(Body + 2));
    LeafSubrange:
      begin
        NumPos := Body + 8;
        if ReadNumeric(NumPos, NumValue) and ReadNumeric(NumPos, NumValue) and
           ReadNumeric(NumPos, NumValue) then
          Result := Integer(NumValue);
      end;
    LeafPasSet:
      begin
        NumPos := Body + 8;
        if ReadNumeric(NumPos, NumValue) and ReadNumeric(NumPos, NumValue) then
          Result := Integer(NumValue);
      end;
  end;
end;

function TDbgSymbols.TypeText(ATypeId: Cardinal): string;
var
  Leaf, Body, RecEnd: Integer;
  Kind, SizeCode: Cardinal;
begin
  Result := '';
  ATypeId := Underlying(ATypeId);
  if ATypeId < $1000 then
  begin
    if ((ATypeId shr 8) and 7) <> 0 then
    begin
      if (ATypeId and $FF) = $03 then
        Result := 'Pointer'
      else if ((ATypeId and $FF) = $10) or ((ATypeId and $FF) = $20) or
              ((ATypeId and $FF) = $70) then
        Result := 'PChar'
      else
        Result := '^' + TypeText(ATypeId and $FF);
      Exit;
    end;
    Kind := (ATypeId shr 4) and $F;
    SizeCode := ATypeId and $F;
    case Kind of
      0: if SizeCode = 3 then Result := 'void';
      1: Result := 'int' + IntToStr(8 shl SizeCode);
      2: Result := 'uint' + IntToStr(8 shl SizeCode);
      3: Result := 'Boolean' + IntToStr(8 shl SizeCode);
      4:
        case SizeCode of
          0: Result := 'Single';
          1: Result := 'Double';
          2: Result := 'Extended';
          4: Result := 'Real48';
        end;
      6:
        if SizeCode = 8 then
          Result := 'int8'
        else if SizeCode = 9 then
          Result := 'uint8';
      7:
        case SizeCode of
          0: Result := 'Char';
          1: Result := 'WideChar';
          2: Result := 'int16';
          3: Result := 'uint16';
          4: Result := 'Integer';
          5: Result := 'Cardinal';
          6: Result := 'Int64';
          7: Result := 'UInt64';
        end;
    end;
    if Result = '' then
      Result := 'тип $' + IntToHex(ATypeId, 4);
    Exit;
  end;
  if not TypeRec(ATypeId, Leaf, Body, RecEnd) then
  begin
    Result := 'тип $' + IntToHex(ATypeId, 4);
    Exit;
  end;
  case Leaf of
    LeafPointer:
      if ((WordAt(Body) shr 5) and 7) = 1 then
        Result := 'var ' + TypeText(DwordAt(Body + 2))
      else
        Result := '^' + TypeText(DwordAt(Body + 2));
    LeafClass, LeafStruct:
      Result := NameOf(DwordAt(Body + 20));
    LeafEnum:
      Result := NameOf(DwordAt(Body + 14));
    LeafArray:
      Result := 'array of ' + TypeText(DwordAt(Body));
    LeafPasSet:
      Result := 'set of ' + TypeText(DwordAt(Body));
    LeafSubrange:
      Result := NameOf(DwordAt(Body + 4));
    LeafPString:
      Result := 'ShortString';
    LeafLString:
      Result := 'AnsiString';
    LeafVariant:
      Result := 'Variant';
    LeafClassRef:
      Result := 'class of ' + TypeText(DwordAt(Body));
    LeafProcedure, LeafClosure:
      Result := 'procedure';
  end;
  if Result = '' then
    Result := 'тип $' + IntToHex(ATypeId, 4) + ' (вид $' + IntToHex(Leaf, 4) + ')';
end;

// Одна запись списка полей (LF_FIELDLIST) с позиции APos: вид, тип, имя
// и число (смещение поля, значение перечисления, смещение предка). APos -
// на следующую запись, выравнивание пропущено. Продолжение списка
// (LF_INDEX) - переход в другую запись, AEnd меняется. False - конец
// списка или незнакомая запись.
function TDbgSymbols.NextMember(var APos: Integer; AEnd: Integer;
                                var ALeaf: Integer; var AType, AName: Cardinal;
                                var AValue: Int64): Boolean;
var
  ListLeaf, ListBody, ListEnd: Integer;
  PadByte: Cardinal;
  Skip: Int64;
begin
  Result := False;
  if APos + 2 > AEnd then
    Exit;
  ALeaf := WordAt(APos);
  Inc(APos, 2);
  AType := 0;
  AName := 0;
  AValue := 0;
  case ALeaf of
    MemData:
      begin
        AType := DwordAt(APos);
        AName := DwordAt(APos + 6);
        Inc(APos, 14);
        if not ReadNumeric(APos, AValue) then
          Exit;
      end;
    MemRealBase:
      begin
        AType := DwordAt(APos);
        Inc(APos, 6);
        if not ReadNumeric(APos, AValue) then
          Exit;
      end;
    MemVirtBaseDir, MemVirtBaseInd:
      begin
        Inc(APos, 10);
        if not ReadNumeric(APos, Skip) or not ReadNumeric(APos, Skip) then
          Exit;
      end;
    MemEnumerate:
      begin
        AName := DwordAt(APos + 2);
        Inc(APos, 10);
        if not ReadNumeric(APos, AValue) then
          Exit;
      end;
    MemIndex:
      begin
        // Продолжение - в другой записи; вызывающий читает её с начала
        AType := DwordAt(APos);
        Inc(APos, 4);
        if not TypeRec(AType, ListLeaf, ListBody, ListEnd) then
          Exit;
      end;
    MemStaticData:
      begin
        AType := DwordAt(APos);
        AName := DwordAt(APos + 6);
        Inc(APos, 14);
      end;
    MemMethod:
      begin
        AName := DwordAt(APos + 6);
        Inc(APos, 10);
      end;
    MemNested:
      begin
        AType := DwordAt(APos);
        AName := DwordAt(APos + 4);
        Inc(APos, 12);
      end;
    MemVtabPtr:
      begin
        Inc(APos, 4);
        if not ReadNumeric(APos, Skip) then
          Exit;
      end;
  else
    Exit;
  end;
  // Выравнивание: байты $F1..$FF, младшие 4 бита - сколько пропустить
  while APos < AEnd do
  begin
    PadByte := ByteAt(APos);
    if PadByte <= $F0 then
      Break;
    Inc(APos, PadByte and $F);
  end;
  Result := True;
end;

// Поле записи или класса по имени - с учётом предков (RealBaseClass)
function TDbgSymbols.FindMember(AStructId: Cardinal; const AName: string;
                                var AOffset: Integer;
                                var AMemberType: Cardinal): Boolean;
var
  Leaf, Body, RecEnd, ListLeaf, ListBody, ListEnd, ItemPos, MemLeaf: Integer;
  Guard, BaseOffset: Integer;
  MemType, MemName: Cardinal;
  NumValue: Int64;
begin
  Result := False;
  AStructId := FullStruct(Underlying(AStructId));
  if not TypeRec(AStructId, Leaf, Body, RecEnd) or
     not ((Leaf = LeafClass) or (Leaf = LeafStruct)) then
    Exit;
  if not TypeRec(DwordAt(Body + 2), ListLeaf, ListBody, ListEnd) then
    Exit;
  ItemPos := ListBody;
  Guard := 0;
  while (Guard < 10000) and
        NextMember(ItemPos, ListEnd, MemLeaf, MemType, MemName, NumValue) do
  begin
    Inc(Guard);
    case MemLeaf of
      MemData:
        if CompareText(NameOf(MemName), AName) = 0 then
        begin
          AMemberType := MemType;
          AOffset := Integer(NumValue);
          Result := True;
          Exit;
        end;
      MemRealBase:
        if FindMember(MemType, AName, BaseOffset, AMemberType) then
        begin
          AOffset := Integer(NumValue) + BaseOffset;
          Result := True;
          Exit;
        end;
      MemIndex:
        if TypeRec(MemType, ListLeaf, ListBody, ListEnd) then
          ItemPos := ListBody;
    end;
  end;
end;

// Имя значения перечисления
function TDbgSymbols.EnumName(AEnumId: Cardinal; AValue: Int64): string;
var
  Leaf, Body, RecEnd, ListLeaf, ListBody, ListEnd, ItemPos, MemLeaf: Integer;
  Guard: Integer;
  MemType, MemName: Cardinal;
  NumValue: Int64;
begin
  Result := '';
  if not TypeRec(Underlying(AEnumId), Leaf, Body, RecEnd) or
     (Leaf <> LeafEnum) then
    Exit;
  if not TypeRec(DwordAt(Body + 6), ListLeaf, ListBody, ListEnd) then
    Exit;
  ItemPos := ListBody;
  Guard := 0;
  while (Guard < 100000) and
        NextMember(ItemPos, ListEnd, MemLeaf, MemType, MemName, NumValue) do
  begin
    Inc(Guard);
    if (MemLeaf = MemEnumerate) and (NumValue = AValue) then
    begin
      Result := NameOf(MemName);
      Exit;
    end;
    if (MemLeaf = MemIndex) and
       TypeRec(MemType, ListLeaf, ListBody, ListEnd) then
      ItemPos := ListBody;
  end;
end;

// ---------------------------------------------------------------------------
//  Память программы и форматирование
// ---------------------------------------------------------------------------

function TDbgSymbols.ReadMem(AAddress: Cardinal; ABuffer: Pointer;
                             ASize: Integer): Boolean;
begin
  // Адрес 0 при FRegActive - значение переменной из регистра
  if FRegActive and (AAddress = 0) then
  begin
    Result := ASize <= 4;
    if Result then
      Move(FRegValue, ABuffer^, ASize);
    Exit;
  end;
  Result := (ASize > 0) and Assigned(FReadMem) and
            FReadMem(AAddress, ABuffer, ASize);
end;

function TDbgSymbols.ReadDword(AAddress: Cardinal; var AValue: Cardinal): Boolean;
begin
  AValue := 0;
  Result := ReadMem(AAddress, @AValue, 4);
end;

function TDbgSymbols.ReadAnsiText(AAddress: Cardinal; ALen: Integer): string;
var
  CharIdx: Integer;
  Text: string;
begin
  Result := '';
  if ALen <= 0 then
    Exit;
  SetLength(Text, ALen);
  if not ReadMem(AAddress, PChar(Text), ALen) then
    Exit;
  for CharIdx := 1 to ALen do
    if Text[CharIdx] < ' ' then
      Result := Result + '''#' + IntToStr(Ord(Text[CharIdx])) + ''''
    else if Text[CharIdx] = '''' then
      Result := Result + ''''''
    else
      Result := Result + Text[CharIdx];
end;

function TDbgSymbols.ClassNameAt(AObject: Cardinal): string;
var
  VmtAddr, NameAddr: Cardinal;
  NameLen: Byte;
begin
  Result := '';
  if not ReadDword(AObject, VmtAddr) or (VmtAddr = 0) then
    Exit;
  if not ReadDword(Cardinal(Integer(VmtAddr) + VmtClassNameOfs), NameAddr) then
    Exit;
  if not ReadMem(NameAddr, @NameLen, 1) or (NameLen = 0) then
    Exit;
  SetLength(Result, NameLen);
  if not ReadMem(NameAddr + 1, PChar(Result), NameLen) then
    Result := '';
end;

// Простой тип CodeView - символ (char, uchar, rchar)
function IsCharPrim(ACode: Cardinal): Boolean;
begin
  Result := (ACode = $10) or (ACode = $20) or (ACode = $70);
end;

function CharText(ACode: Cardinal): string;
begin
  if (ACode < 32) or (ACode > 255) then
    Result := '#' + IntToStr(ACode)
  else if ACode = Ord('''') then
    Result := ''''''''''
  else
    Result := '''' + Chr(ACode) + '''';
end;

function TDbgSymbols.FormatPrimitive(AAddress, ATypeId: Cardinal): string;
var
  Bytes: array[0..15] of Byte;
  Kind, SizeCode, PtrValue: Cardinal;
  ByteSize: Integer;
  SingleValue: Single;
  DoubleValue: Double;
  ExtValue: Extended;
  Real48Value: Real48;
  Int64Value: Int64;
  TextLen: Integer;
begin
  Result := '';
  // Указатель на простой тип
  if ((ATypeId shr 8) and 7) <> 0 then
  begin
    if not ReadDword(AAddress, PtrValue) then
    begin
      Result := '<ошибка чтения памяти $' + IntToHex(AAddress, 8) + '>';
      Exit;
    end;
    if PtrValue = 0 then
      Result := 'nil'
    else if IsCharPrim(ATypeId and $FF) then
    begin
      // PChar: до нуля, не длиннее MaxShowText
      FillChar(Bytes, SizeOf(Bytes), 0);
      TextLen := 0;
      while TextLen < MaxShowText do
      begin
        if not ReadMem(PtrValue + Cardinal(TextLen), @Bytes[0], 1) or
           (Bytes[0] = 0) then
          Break;
        Inc(TextLen);
      end;
      Result := '''' + ReadAnsiText(PtrValue, TextLen) + '''';
      if TextLen >= MaxShowText then
        Result := Result + '...';
    end
    else
      Result := '$' + IntToHex(PtrValue, 8);
    Exit;
  end;

  ByteSize := TypeSize(ATypeId);
  if (ByteSize <= 0) or (ByteSize > SizeOf(Bytes)) then
  begin
    Result := '<' + TypeText(ATypeId) + '>';
    Exit;
  end;
  FillChar(Bytes, SizeOf(Bytes), 0);
  if not ReadMem(AAddress, @Bytes[0], ByteSize) then
  begin
    Result := '<ошибка чтения памяти $' + IntToHex(AAddress, 8) + '>';
    Exit;
  end;
  Move(Bytes[0], Int64Value, 8);
  Kind := (ATypeId shr 4) and $F;
  SizeCode := ATypeId and $F;
  if (Kind = 6) and (SizeCode = 9) then
    Kind := 2;   // $69 - uint8
  case Kind of
    1, 6:
      // знаковые целые; $68 - int8
      case ByteSize of
        1: Result := IntToStr(ShortInt(Bytes[0]));
        2: Result := IntToStr(SmallInt(Int64Value and $FFFF));
        4: Result := IntToStr(Integer(Int64Value and $FFFFFFFF));
      else
        Result := IntToStr(Int64Value);
      end;
    2:
      if ByteSize = 8 then
        Result := IntToStr(Int64Value)
      else
        Result := IntToStr(Int64Value and ((Int64(1) shl (ByteSize * 8)) - 1));
    3:
      if Int64Value = 0 then
        Result := 'False'
      else
        Result := 'True';
    4:
      case SizeCode of
        0:
          begin
            Move(Bytes[0], SingleValue, 4);
            Result := FloatToStr(SingleValue);
          end;
        1:
          begin
            Move(Bytes[0], DoubleValue, 8);
            Result := FloatToStr(DoubleValue);
          end;
        2:
          begin
            Move(Bytes[0], ExtValue, 10);
            Result := FloatToStr(ExtValue);
          end;
        4:
          begin
            Move(Bytes[0], Real48Value, 6);
            ExtValue := Real48Value;
            Result := FloatToStr(ExtValue);
          end;
      end;
    7:
      case SizeCode of
        0: Result := CharText(Bytes[0]);
        1: Result := CharText(Bytes[0] or (Bytes[1] shl 8));
        2: Result := IntToStr(SmallInt(Int64Value and $FFFF));
        3: Result := IntToStr(Int64Value and $FFFF);
        4: Result := IntToStr(Integer(Int64Value and $FFFFFFFF));
        5: Result := IntToStr(Int64Value and $FFFFFFFF);
        6, 7: Result := IntToStr(Int64Value);
      end;
  end;
  if Result = '' then
    Result := '$' + IntToHex(Int64Value, ByteSize * 2);
end;

function TDbgSymbols.FormatValue(AAddress, ATypeId: Cardinal;
                                 ADepth: Integer): string;
var
  Leaf, Body, RecEnd, ListLeaf, ListBody, ListEnd, ItemPos, MemLeaf: Integer;
  ElemSize, ElemCount, ElemIdx, NumPos, ValueSize, BitIdx, Shown, Guard: Integer;
  PtrValue, MemberType, BaseType, NameIdx, StrLen: Cardinal;
  NumValue, LowValue, OrdValue: Int64;
  Bytes: array[0..31] of Byte;
  ItemText, ClassText: string;
begin
  ATypeId := Underlying(ATypeId);
  if ATypeId < $1000 then
  begin
    Result := FormatPrimitive(AAddress, ATypeId);
    Exit;
  end;
  if not TypeRec(ATypeId, Leaf, Body, RecEnd) then
  begin
    Result := '<тип $' + IntToHex(ATypeId, 4) + ' не найден>';
    Exit;
  end;

  case Leaf of
    LeafPointer:
      begin
        if not ReadDword(AAddress, PtrValue) then
        begin
          Result := '<ошибка чтения памяти $' + IntToHex(AAddress, 8) + '>';
          Exit;
        end;
        MemberType := FullStruct(Underlying(DwordAt(Body + 2)));
        // var-параметр: в кадре - адрес значения
        if ((WordAt(Body) shr 5) and 7) = 1 then
        begin
          if PtrValue = 0 then
            Result := '<nil>'
          else
            Result := FormatValue(PtrValue, MemberType, ADepth);
          Exit;
        end;
        if PtrValue = 0 then
        begin
          Result := 'nil';
          Exit;
        end;
        if TypeRec(MemberType, ListLeaf, ListBody, ListEnd) and
           (ListLeaf = LeafClass) then
        begin
          // Объект: класс по VMT в памяти программы (настоящий, а не
          // объявленный) и адрес
          ClassText := ClassNameAt(PtrValue);
          if ClassText = '' then
            ClassText := NameOf(DwordAt(ListBody + 20));
          Result := ClassText + '($' + IntToHex(PtrValue, 8) + ')';
          Exit;
        end;
        if (MemberType < $1000) and IsCharPrim(MemberType and $FF) then
        begin
          // PChar с описанием через запись указателя
          Result := FormatPrimitive(AAddress, $0400 or (MemberType and $FF));
          Exit;
        end;
        Result := '$' + IntToHex(PtrValue, 8);
      end;

    LeafLString:
      begin
        if not ReadDword(AAddress, PtrValue) then
        begin
          Result := '<ошибка чтения памяти $' + IntToHex(AAddress, 8) + '>';
          Exit;
        end;
        if PtrValue = 0 then
        begin
          Result := '''''';
          Exit;
        end;
        if not ReadDword(PtrValue - 4, StrLen) then
        begin
          Result := '<ошибка чтения строки>';
          Exit;
        end;
        if StrLen > MaxShowText then
          Result := '''' + ReadAnsiText(PtrValue, MaxShowText) + '''...'
        else
          Result := '''' + ReadAnsiText(PtrValue, Integer(StrLen)) + '''';
      end;

    LeafPString:
      begin
        if not ReadMem(AAddress, @Bytes[0], 1) then
        begin
          Result := '<ошибка чтения памяти $' + IntToHex(AAddress, 8) + '>';
          Exit;
        end;
        Result := '''' + ReadAnsiText(AAddress + 1, Bytes[0]) + '''';
      end;

    LeafClassRef:
      begin
        if not ReadDword(AAddress, PtrValue) then
        begin
          Result := '<ошибка чтения памяти>';
          Exit;
        end;
        if PtrValue = 0 then
          Result := 'nil'
        else
        begin
          // Ссылка на класс - сам VMT; имя по тому же смещению
          Result := '';
          if ReadDword(Cardinal(Integer(PtrValue) + VmtClassNameOfs), MemberType) and
             ReadMem(MemberType, @Bytes[0], 1) and (Bytes[0] > 0) then
          begin
            SetLength(Result, Bytes[0]);
            if not ReadMem(MemberType + 1, PChar(Result), Bytes[0]) then
              Result := '';
          end;
          if Result = '' then
            Result := '$' + IntToHex(PtrValue, 8);
        end;
      end;

    LeafEnum, LeafSubrange:
      begin
        ValueSize := TypeSize(ATypeId);
        if (ValueSize <= 0) or (ValueSize > 8) then
          ValueSize := 1;
        FillChar(Bytes, SizeOf(Bytes), 0);
        if not ReadMem(AAddress, @Bytes[0], ValueSize) then
        begin
          Result := '<ошибка чтения памяти $' + IntToHex(AAddress, 8) + '>';
          Exit;
        end;
        Move(Bytes[0], OrdValue, 8);
        if Leaf = LeafEnum then
        begin
          Result := EnumName(ATypeId, OrdValue);
          if Result = '' then
            Result := IntToStr(OrdValue);
          Exit;
        end;
        // Поддиапазон: нижняя граница отрицательная - число со знаком
        NumPos := Body + 8;
        LowValue := 0;
        ReadNumeric(NumPos, LowValue);
        if LowValue < 0 then
          case ValueSize of
            1: OrdValue := ShortInt(Bytes[0]);
            2: OrdValue := SmallInt(Bytes[0] or (Bytes[1] shl 8));
            4: OrdValue := Integer(OrdValue and $FFFFFFFF);
          end;
        BaseType := Underlying(DwordAt(Body));
        if TypeRec(BaseType, ListLeaf, ListBody, ListEnd) and
           (ListLeaf = LeafEnum) then
        begin
          Result := EnumName(BaseType, OrdValue);
          if Result <> '' then
            Exit;
        end;
        if IsCharPrim(BaseType) then
          Result := CharText(Cardinal(OrdValue))
        else
          Result := IntToStr(OrdValue);
      end;

    LeafPasSet:
      begin
        ValueSize := TypeSize(ATypeId);
        if (ValueSize <= 0) or (ValueSize > 32) then
        begin
          Result := '<' + TypeText(ATypeId) + '>';
          Exit;
        end;
        FillChar(Bytes, SizeOf(Bytes), 0);
        if not ReadMem(AAddress, @Bytes[0], ValueSize) then
        begin
          Result := '<ошибка чтения памяти $' + IntToHex(AAddress, 8) + '>';
          Exit;
        end;
        NumPos := Body + 8;
        LowValue := 0;
        ReadNumeric(NumPos, LowValue);   // первый байт множества
        BaseType := Underlying(DwordAt(Body));
        Result := '';
        for BitIdx := 0 to ValueSize * 8 - 1 do
          if (Bytes[BitIdx shr 3] and (1 shl (BitIdx and 7))) <> 0 then
          begin
            OrdValue := LowValue * 8 + BitIdx;
            ItemText := EnumName(BaseType, OrdValue);
            if ItemText = '' then
              ItemText := IntToStr(OrdValue);
            if Result <> '' then
              Result := Result + ', ';
            Result := Result + ItemText;
          end;
        Result := '[' + Result + ']';
      end;

    LeafStruct, LeafClass:
      begin
        if ADepth >= MaxDepth then
        begin
          Result := '(...)';
          Exit;
        end;
        ATypeId := FullStruct(ATypeId);
        if not TypeRec(ATypeId, Leaf, Body, RecEnd) or
           not TypeRec(DwordAt(Body + 2), ListLeaf, ListBody, ListEnd) then
        begin
          Result := '(...)';
          Exit;
        end;
        // Поля по порядку описания (поля предков класса не показываются)
        Result := '';
        Shown := 0;
        ItemPos := ListBody;
        Guard := 0;
        while (Shown < MaxShowItems) and (Guard < 10000) and
              NextMember(ItemPos, ListEnd, MemLeaf, MemberType, NameIdx,
                         NumValue) do
        begin
          Inc(Guard);
          if MemLeaf = MemIndex then
          begin
            if TypeRec(MemberType, ListLeaf, ListBody, ListEnd) then
              ItemPos := ListBody;
            Continue;
          end;
          if MemLeaf <> MemData then
            Continue;
          if Result <> '' then
            Result := Result + '; ';
          Result := Result + NameOf(NameIdx) + ': ' +
                    FormatValue(AAddress + Cardinal(NumValue), MemberType,
                                ADepth + 1);
          Inc(Shown);
        end;
        Result := '(' + Result + ')';
      end;

    LeafArray:
      begin
        if ADepth >= MaxDepth then
        begin
          Result := '(...)';
          Exit;
        end;
        ElemSize := TypeSize(DwordAt(Body));
        ValueSize := TypeSize(ATypeId);
        if (ElemSize <= 0) or (ValueSize <= 0) then
        begin
          Result := '<' + TypeText(ATypeId) + '>';
          Exit;
        end;
        ElemCount := ValueSize div ElemSize;
        Result := '';
        for ElemIdx := 0 to ElemCount - 1 do
        begin
          if ElemIdx >= MaxShowItems then
          begin
            Result := Result + ', ...';
            Break;
          end;
          if Result <> '' then
            Result := Result + ', ';
          Result := Result + FormatValue(AAddress + Cardinal(ElemIdx * ElemSize),
                                         DwordAt(Body), ADepth + 1);
        end;
        Result := '(' + Result + ')';
      end;

    LeafVariant:
      Result := '<Variant>';

    LeafProcedure, LeafClosure:
      begin
        if ReadDword(AAddress, PtrValue) then
        begin
          if PtrValue = 0 then
            Result := 'nil'
          else
            Result := '$' + IntToHex(PtrValue, 8);
        end
        else
          Result := '<ошибка чтения памяти>';
      end;
  else
    Result := '<' + TypeText(ATypeId) + '>';
  end;
end;

// ---------------------------------------------------------------------------
//  Поиск символов и вычисление
// ---------------------------------------------------------------------------

// Самая внутренняя процедура (вложенные процедуры Delphi - внутри
// объемлющей) с кодом по смещению ACodeOfs в сегменте кода
function TDbgSymbols.FindProc(ACodeOfs: Cardinal): Integer;
var
  ProcIdx: Integer;
begin
  Result := -1;
  for ProcIdx := 0 to FProcCount - 1 do
    if (FProcs[ProcIdx].Segment = 1) and
       (ACodeOfs >= FProcs[ProcIdx].Offset) and
       (ACodeOfs < FProcs[ProcIdx].Offset + FProcs[ProcIdx].Size) then
      if (Result < 0) or (FProcs[ProcIdx].Size < FProcs[Result].Size) then
        Result := ProcIdx;
end;

function TDbgSymbols.FindLocal(AProcIdx: Integer; const AName: string): Integer;
var
  LocalIdx: Integer;
begin
  Result := -1;
  for LocalIdx := 0 to FLocalCount - 1 do
    if (FLocals[LocalIdx].ProcIdx = AProcIdx) and
       (CompareText(FLocals[LocalIdx].Name, AName) = 0) then
    begin
      Result := LocalIdx;
      Exit;
    end;
end;

// Имя данных в TD32 бывает с модулем впереди - сравнивается и хвост
function DataNameMatches(const ASymName, AName: string): Boolean;
var
  CharIdx: Integer;
begin
  Result := CompareText(ASymName, AName) = 0;
  if Result then
    Exit;
  for CharIdx := Length(ASymName) downto 1 do
    if ASymName[CharIdx] in ['.', '@'] then
    begin
      Result := CompareText(Copy(ASymName, CharIdx + 1, MaxInt), AName) = 0;
      Exit;
    end;
end;

// Данные модуля: сначала того же модуля, где процедура, потом любого
function TDbgSymbols.FindData(const AName: string; AModule: Integer): Integer;
var
  DataIdx: Integer;
begin
  Result := -1;
  for DataIdx := 0 to FDataCount - 1 do
    if DataNameMatches(FDatas[DataIdx].Name, AName) then
    begin
      if FDatas[DataIdx].Module = AModule then
      begin
        Result := DataIdx;
        Exit;
      end;
      if Result < 0 then
        Result := DataIdx;
    end;
end;

function IsIdent(const AText: string): Boolean;
var
  CharIdx: Integer;
begin
  Result := (AText <> '') and (AText[1] in ['A'..'Z', 'a'..'z', '_']);
  if not Result then
    Exit;
  for CharIdx := 2 to Length(AText) do
    if not (AText[CharIdx] in ['A'..'Z', 'a'..'z', '0'..'9', '_']) then
    begin
      Result := False;
      Exit;
    end;
end;

function TDbgSymbols.Evaluate(const AExpr: string;
                              AImageBase, AEip: Cardinal;
                              const ARegs: TDbgRegs; AReadMem: TDbgReadMem;
                              var ATypeText: string): string;
const
  RegFirst = 17;   // EAX в нумерации CodeView, дальше ECX, EDX, EBX, ESP,
                   // EBP, ESI, EDI - тот же порядок, что в TDbgRegs
var
  Parts: TStringList;
  PartIdx, ProcIdx, LocalIdx, DataIdx, MemberOfs, Leaf, Body, RecEnd: Integer;
  ListLeaf, ListBody, ListEnd: Integer;
  CodeOfs, CodeBase, CurAddr, CurType, PtrValue, MemberType, Ebp: Cardinal;
  Rest, PartText, FieldNote: string;
  Found: Boolean;
begin
  Result := '';
  ATypeText := '';
  FieldNote := '';
  FReadMem := AReadMem;
  FRegActive := False;
  if FBuf = '' then
  begin
    Result := '<нет отладочной информации>';
    Exit;
  end;

  Parts := TStringList.Create;
  try
    Rest := Trim(AExpr);
    while Rest <> '' do
    begin
      if Pos('.', Rest) > 0 then
      begin
        PartText := Trim(Copy(Rest, 1, Pos('.', Rest) - 1));
        Rest := Trim(Copy(Rest, Pos('.', Rest) + 1, MaxInt));
      end
      else
      begin
        PartText := Rest;
        Rest := '';
      end;
      if not IsIdent(PartText) then
      begin
        Result := '<выражение не поддерживается: только имена через точку>';
        Exit;
      end;
      Parts.Add(PartText);
    end;
    if Parts.Count = 0 then
      Exit;

    if not SegAddress(1, 0, AImageBase, CodeBase) or (AEip < CodeBase) then
    begin
      Result := '<не найден сегмент кода>';
      Exit;
    end;
    CodeOfs := AEip - CodeBase;
    ProcIdx := FindProc(CodeOfs);
    Ebp := ARegs[5];

    // Первое имя: локальное процедуры, данные модуля, поле Self
    Found := False;
    CurAddr := 0;
    CurType := 0;
    LocalIdx := -1;
    if ProcIdx >= 0 then
      LocalIdx := FindLocal(ProcIdx, Parts[0]);
    if LocalIdx >= 0 then
    begin
      CurType := FLocals[LocalIdx].TypeId;
      case FLocals[LocalIdx].Kind of
        DbgLocalFrame:
          begin
            if CodeOfs < FProcs[ProcIdx].Offset + FProcs[ProcIdx].DebugStart then
            begin
              Result := '<кадр процедуры ещё не построен - шаг дальше>';
              Exit;
            end;
            CurAddr := Cardinal(Integer(Ebp) + FLocals[LocalIdx].BpOffset);
            Found := True;
          end;
        DbgLocalReg:
          if (FLocals[LocalIdx].RegNo >= RegFirst) and
             (FLocals[LocalIdx].RegNo <= RegFirst + 7) then
          begin
            FRegValue := ARegs[FLocals[LocalIdx].RegNo - RegFirst];
            FRegActive := True;
            CurAddr := 0;
            Found := True;
          end
          else
          begin
            Result := '<в регистре ' + IntToStr(FLocals[LocalIdx].RegNo) +
                      ', не читается>';
            Exit;
          end;
        DbgLocalData:
          Found := SegAddress(FLocals[LocalIdx].Segment,
                              FLocals[LocalIdx].Offset, AImageBase, CurAddr);
      end;
    end;
    if not Found then
    begin
      if ProcIdx >= 0 then
        DataIdx := FindData(Parts[0], FProcs[ProcIdx].Module)
      else
        DataIdx := FindData(Parts[0], -1);
      if DataIdx >= 0 then
      begin
        CurType := FDatas[DataIdx].TypeId;
        Found := SegAddress(FDatas[DataIdx].Segment, FDatas[DataIdx].Offset,
                            AImageBase, CurAddr);
        if not Found then
        begin
          Result := '<данные в сегменте ' + IntToStr(FDatas[DataIdx].Segment) +
                    ' (threadvar?) не читаются>';
          Exit;
        end;
      end;
    end;
    if not Found and (ProcIdx >= 0) and
       (CompareText(Parts[0], 'Self') <> 0) then
    begin
      // Поле объекта метода: Self.<имя>
      LocalIdx := FindLocal(ProcIdx, 'Self');
      if (LocalIdx >= 0) and (FLocals[LocalIdx].Kind = DbgLocalFrame) then
      begin
        Parts.Insert(0, 'Self');
        CurType := FLocals[LocalIdx].TypeId;
        CurAddr := Cardinal(Integer(Ebp) + FLocals[LocalIdx].BpOffset);
        Found := True;
      end;
    end;
    if not Found and (ProcIdx >= 0) then
    begin
      // Переменная объемлющей процедуры (вложенная процедура Delphi): её
      // кадр - другой, по EBP этой не найти
      LocalIdx := FProcs[ProcIdx].Parent;
      while LocalIdx >= 0 do
      begin
        if FindLocal(LocalIdx, Parts[0]) >= 0 then
        begin
          Result := '<переменная объемлющей процедуры ' +
                    FProcs[LocalIdx].Name + ' - не читается>';
          Exit;
        end;
        LocalIdx := FProcs[LocalIdx].Parent;
      end;
    end;
    if not Found then
    begin
      if ProcIdx < 0 then
        Result := '<не найдено: ' + Parts[0] + ' (программа стоит вне кода ' +
                  'с отладочной информацией)>'
      else
        Result := '<не найдено: ' + Parts[0] + '>';
      Exit;
    end;

    // Остальные имена - поля записей и объектов
    for PartIdx := 1 to Parts.Count - 1 do
    begin
      CurType := Underlying(CurType);
      if TypeRec(CurType, Leaf, Body, RecEnd) and (Leaf = LeafPointer) then
      begin
        // Объект или var-параметр: дальше - по адресу из указателя
        if not ReadDword(CurAddr, PtrValue) then
        begin
          Result := '<ошибка чтения памяти $' + IntToHex(CurAddr, 8) + '>';
          Exit;
        end;
        FRegActive := False;
        if PtrValue = 0 then
        begin
          Result := '<' + Parts[PartIdx - 1] + ' = nil>';
          Exit;
        end;
        CurAddr := PtrValue;
        CurType := Underlying(DwordAt(Body + 2));
        // var-параметр с объектом: ещё один указатель
        if TypeRec(CurType, ListLeaf, ListBody, ListEnd) and
           (ListLeaf = LeafPointer) then
        begin
          if not ReadDword(CurAddr, PtrValue) or (PtrValue = 0) then
          begin
            Result := '<' + Parts[PartIdx - 1] + ' = nil>';
            Exit;
          end;
          CurAddr := PtrValue;
          CurType := Underlying(DwordAt(ListBody + 2));
        end;
      end;
      if FRegActive then
      begin
        Result := '<поле значения в регистре не читается>';
        Exit;
      end;
      FieldNote := '';
      if not FindMember(CurType, Parts[PartIdx], MemberOfs, MemberType) then
      begin
        // Свойство на поле: Tag - FTag, Left - FLeft (так в VCL)
        if FindMember(CurType, 'F' + Parts[PartIdx], MemberOfs, MemberType) then
          FieldNote := ' (поле F' + Parts[PartIdx] + ')'
        else
        begin
          Result := '<нет поля ' + Parts[PartIdx] + ' у ' + TypeText(CurType) +
                    ' (свойства с методом чтения не показываются - только ' +
                    'поля)>';
          Exit;
        end;
      end;
      CurAddr := CurAddr + Cardinal(MemberOfs);
      CurType := MemberType;
    end;

    ATypeText := TypeText(CurType) + FieldNote;
    Result := FormatValue(CurAddr, CurType, 0);
  finally
    Parts.Free;
    FRegActive := False;
  end;
end;

function TDbgSymbols.ProcLocals(AImageBase, AEip: Cardinal;
                                AList: TStrings): string;
var
  CodeBase: Cardinal;
  ProcIdx, LocalIdx: Integer;
begin
  Result := '';
  AList.Clear;
  if (FBuf = '') or not SegAddress(1, 0, AImageBase, CodeBase) or
     (AEip < CodeBase) then
    Exit;
  ProcIdx := FindProc(AEip - CodeBase);
  if ProcIdx < 0 then
    Exit;
  Result := FProcs[ProcIdx].Name;
  for LocalIdx := 0 to FLocalCount - 1 do
    if (FLocals[LocalIdx].ProcIdx = ProcIdx) and
       IsIdent(FLocals[LocalIdx].Name) and
       (AList.IndexOf(FLocals[LocalIdx].Name) < 0) then
      AList.Add(FLocals[LocalIdx].Name);
end;

end.
