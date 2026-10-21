unit ResFile;

// ---------------------------------------------------------------------------
//  Файл ресурсов .res (32-битный формат Win32) - чтение, запись и правка
//  двух ресурсов, которые среда Delphi 7 ведёт в <проект>.res сама:
//
//    - VERSIONINFO (тип 16, имя 1) - страница Version Info настроек
//      проекта;
//    - MAINICON (RT_GROUP_ICON с именем MAINICON и его RT_ICON) - значок
//      на странице Application.
//
//  dcc32 файл .res не меняет, он только подключает его по {$R *.res}. Поэтому
//  то, что среда Delphi пишет в .res при сохранении и сборке, здесь делается
//  своим кодом.
//
//  Остальные ресурсы файла переносятся как есть, байт в байт.
//  Модуль без VCL.
// ---------------------------------------------------------------------------

interface

uses
  SysUtils, Classes;

const
  RtIcon      = 3;
  RtGroupIcon = 14;
  RtVersion   = 16;

type
  // Одна запись файла. Поля типа и имени хранятся как в файле: либо
  // $FFFF + номер, либо строка UTF-16 с нулём на конце.
  TResEntry = class
  public
    TypeRaw: string;
    NameRaw: string;
    DataVersion: LongWord;
    MemFlags: Word;
    LangId: Word;
    Version: LongWord;
    Characteristics: LongWord;
    Data: string;
    function TypeOrd: Integer;   // -1 - тип задан строкой
    function NameOrd: Integer;   // -1 - имя задано строкой
    function NameText: string;   // имя-строка в верхнем регистре, '' - номер
  end;

  TResFile = class
  private
    FItems: TList;
    function GetCount: Integer;
    function GetEntry(AIndex: Integer): TResEntry;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    // Пустой файл: только служебная нулевая запись, с которой начинается
    // каждый .res
    procedure InitEmpty;
    function LoadFromFile(const AFileName: string): Boolean;
    procedure SaveToFile(const AFileName: string);
    procedure Delete(AIndex: Integer);
    function Add: TResEntry;
    function FindByOrd(ATypeOrd, ANameOrd: Integer): Integer;
    function FindByName(ATypeOrd: Integer; const AName: string): Integer;
    property Count: Integer read GetCount;
    property Entries[AIndex: Integer]: TResEntry read GetEntry; default;
  end;

  // Данные страницы Version Info
  TVerInfo = record
    Major, Minor, Release, Build: Word;
    Debug, PreRelease, Special, PrivateBuild, IsDll: Boolean;
    LangId, CodePage: Word;
  end;

function ResOrdField(AValue: Word): string;
function ResNameField(const AName: string): string;

// Блок VS_VERSIONINFO. AKeys - строки "Ключ=Значение" для StringFileInfo.
function BuildVersionInfo(const AInfo: TVerInfo; AKeys: TStrings): string;

// VERSIONINFO в файле .res: прежний убирается, новый пишется. Файла нет -
// создаётся. AError - текст ошибки, если не удалось.
function ResWriteVersion(const AResFile: string; const AInfo: TVerInfo;
                         AKeys: TStrings; out AError: string): Boolean;
// Убрать VERSIONINFO из .res (галка Include version information снята)
function ResRemoveVersion(const AResFile: string; out AError: string): Boolean;

// MAINICON из .res - в поток в формате файла .ico. False - значка нет.
function ResExtractMainIcon(const AResFile: string; AStream: TStream): Boolean;
// MAINICON в .res заменить значком из файла .ico
function ResReplaceMainIcon(const AResFile, AIcoFile: string;
                            out AError: string): Boolean;

implementation

// ---------------------------------------------------------------------------
//  Байты
// ---------------------------------------------------------------------------

function WordBytes(AValue: Word): string;
begin
  SetLength(Result, 2);
  Result[1] := Chr(AValue and $FF);
  Result[2] := Chr((AValue shr 8) and $FF);
end;

function DWordBytes(AValue: LongWord): string;
begin
  Result := WordBytes(AValue and $FFFF) + WordBytes((AValue shr 16) and $FFFF);
end;

function ReadWordAt(const ABuf: string; APos: Integer): Word;
begin
  Result := Ord(ABuf[APos]) or (Ord(ABuf[APos + 1]) shl 8);
end;

function ReadDWordAt(const ABuf: string; APos: Integer): LongWord;
begin
  Result := LongWord(ReadWordAt(ABuf, APos)) or
            (LongWord(ReadWordAt(ABuf, APos + 2)) shl 16);
end;

// Строка в UTF-16LE без завершающего нуля. Перевод - через WideString:
// в Delphi 7 он идёт по кодовой странице Windows (CP_ACP).
function WideBytes(const AText: string): string;
var
  WideText: WideString;
  CharIdx: Integer;
begin
  WideText := AText;
  SetLength(Result, Length(WideText) * 2);
  for CharIdx := 1 to Length(WideText) do
  begin
    Result[CharIdx * 2 - 1] := Chr(Ord(WideText[CharIdx]) and $FF);
    Result[CharIdx * 2] := Chr((Ord(WideText[CharIdx]) shr 8) and $FF);
  end;
end;

// Дополнить нулями до границы 4 байт
procedure PadTo4(var ABuf: string);
begin
  while Length(ABuf) mod 4 <> 0 do
    ABuf := ABuf + #0;
end;

function ResOrdField(AValue: Word): string;
begin
  Result := WordBytes($FFFF) + WordBytes(AValue);
end;

function ResNameField(const AName: string): string;
begin
  Result := WideBytes(AnsiUpperCase(AName)) + #0#0;
end;

// ---------------------------------------------------------------------------
//  TResEntry
// ---------------------------------------------------------------------------

function OrdOfField(const ARaw: string): Integer;
begin
  if (Length(ARaw) = 4) and (ReadWordAt(ARaw, 1) = $FFFF) then
    Result := ReadWordAt(ARaw, 3)
  else
    Result := -1;
end;

function TResEntry.TypeOrd: Integer;
begin
  Result := OrdOfField(TypeRaw);
end;

function TResEntry.NameOrd: Integer;
begin
  Result := OrdOfField(NameRaw);
end;

function TResEntry.NameText: string;
var
  BytePos: Integer;
  CharCode: Word;
begin
  Result := '';
  if NameOrd >= 0 then
    Exit;
  BytePos := 1;
  while BytePos + 1 <= Length(NameRaw) do
  begin
    CharCode := ReadWordAt(NameRaw, BytePos);
    if CharCode = 0 then
      Break;
    // Имена ресурсов Delphi - латиница; прочее заменяется знаком "?"
    if CharCode < 128 then
      Result := Result + Chr(CharCode)
    else
      Result := Result + '?';
    Inc(BytePos, 2);
  end;
  Result := AnsiUpperCase(Result);
end;

// ---------------------------------------------------------------------------
//  TResFile
// ---------------------------------------------------------------------------

constructor TResFile.Create;
begin
  inherited Create;
  FItems := TList.Create;
end;

destructor TResFile.Destroy;
begin
  Clear;
  FItems.Free;
  inherited Destroy;
end;

procedure TResFile.Clear;
var
  ItemIdx: Integer;
begin
  for ItemIdx := 0 to FItems.Count - 1 do
    TResEntry(FItems[ItemIdx]).Free;
  FItems.Clear;
end;

function TResFile.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TResFile.GetEntry(AIndex: Integer): TResEntry;
begin
  Result := TResEntry(FItems[AIndex]);
end;

procedure TResFile.Delete(AIndex: Integer);
begin
  TResEntry(FItems[AIndex]).Free;
  FItems.Delete(AIndex);
end;

function TResFile.Add: TResEntry;
begin
  Result := TResEntry.Create;
  FItems.Add(Result);
end;

procedure TResFile.InitEmpty;
var
  Header: TResEntry;
begin
  Clear;
  Header := Add;
  Header.TypeRaw := ResOrdField(0);
  Header.NameRaw := ResOrdField(0);
end;

function TResFile.FindByOrd(ATypeOrd, ANameOrd: Integer): Integer;
var
  ItemIdx: Integer;
begin
  Result := -1;
  for ItemIdx := 0 to Count - 1 do
    if (Entries[ItemIdx].TypeOrd = ATypeOrd) and
       (Entries[ItemIdx].NameOrd = ANameOrd) then
    begin
      Result := ItemIdx;
      Exit;
    end;
end;

function TResFile.FindByName(ATypeOrd: Integer; const AName: string): Integer;
var
  ItemIdx: Integer;
begin
  Result := -1;
  for ItemIdx := 0 to Count - 1 do
    if (Entries[ItemIdx].TypeOrd = ATypeOrd) and
       (Entries[ItemIdx].NameText = AnsiUpperCase(AName)) then
    begin
      Result := ItemIdx;
      Exit;
    end;
end;

// Поле типа или имени, начиная с позиции APos. Возвращает сырые байты поля,
// APos переводит за поле.
function ReadIdField(const ABuf: string; var APos: Integer;
                     ALimit: Integer): string;
var
  StartPos: Integer;
begin
  StartPos := APos;
  if (APos + 1 <= ALimit) and (ReadWordAt(ABuf, APos) = $FFFF) then
    Inc(APos, 4)
  else
  begin
    while (APos + 1 <= ALimit) and (ReadWordAt(ABuf, APos) <> 0) do
      Inc(APos, 2);
    Inc(APos, 2); // завершающий ноль
  end;
  Result := Copy(ABuf, StartPos, APos - StartPos);
end;

function TResFile.LoadFromFile(const AFileName: string): Boolean;
var
  FileStream: TFileStream;
  Buf: string;
  EntryPos, FieldPos, BufLen: Integer;
  DataSize, HeaderSize: LongWord;
  Entry: TResEntry;
begin
  Result := False;
  Clear;
  if not FileExists(AFileName) then
    Exit;

  FileStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(Buf, FileStream.Size);
    if FileStream.Size > 0 then
      FileStream.ReadBuffer(Buf[1], FileStream.Size);
  finally
    FileStream.Free;
  end;

  BufLen := Length(Buf);
  EntryPos := 1;
  while EntryPos + 31 <= BufLen do
  begin
    DataSize := ReadDWordAt(Buf, EntryPos);
    HeaderSize := ReadDWordAt(Buf, EntryPos + 4);
    if (HeaderSize < 32) or
       (Int64(EntryPos) + HeaderSize + DataSize - 1 > BufLen) then
    begin
      Clear;
      Exit;
    end;

    Entry := Add;
    FieldPos := EntryPos + 8;
    Entry.TypeRaw := ReadIdField(Buf, FieldPos, EntryPos + Integer(HeaderSize) - 1);
    Entry.NameRaw := ReadIdField(Buf, FieldPos, EntryPos + Integer(HeaderSize) - 1);
    // Остаток заголовка - 16 байт в его конце
    FieldPos := EntryPos + Integer(HeaderSize) - 16;
    Entry.DataVersion := ReadDWordAt(Buf, FieldPos);
    Entry.MemFlags := ReadWordAt(Buf, FieldPos + 4);
    Entry.LangId := ReadWordAt(Buf, FieldPos + 6);
    Entry.Version := ReadDWordAt(Buf, FieldPos + 8);
    Entry.Characteristics := ReadDWordAt(Buf, FieldPos + 12);
    Entry.Data := Copy(Buf, EntryPos + Integer(HeaderSize), DataSize);

    EntryPos := EntryPos + Integer(HeaderSize) + Integer(DataSize);
    // Следующая запись - с границы 4 байт от начала файла
    while (EntryPos - 1) mod 4 <> 0 do
      Inc(EntryPos);
  end;

  Result := Count > 0;
end;

procedure TResFile.SaveToFile(const AFileName: string);
var
  OutBuf, Header: string;
  ItemIdx: Integer;
  Entry: TResEntry;
  FileStream: TFileStream;
begin
  OutBuf := '';
  for ItemIdx := 0 to Count - 1 do
  begin
    Entry := Entries[ItemIdx];
    Header := Entry.TypeRaw + Entry.NameRaw;
    // 8 байт размеров + поля + выравнивание - до границы 4
    while (8 + Length(Header)) mod 4 <> 0 do
      Header := Header + #0;
    Header := Header + DWordBytes(Entry.DataVersion) +
              WordBytes(Entry.MemFlags) + WordBytes(Entry.LangId) +
              DWordBytes(Entry.Version) + DWordBytes(Entry.Characteristics);
    OutBuf := OutBuf + DWordBytes(Length(Entry.Data)) +
              DWordBytes(8 + Length(Header)) + Header + Entry.Data;
    PadTo4(OutBuf);
  end;

  FileStream := TFileStream.Create(AFileName, fmCreate);
  try
    if OutBuf <> '' then
      FileStream.WriteBuffer(OutBuf[1], Length(OutBuf));
  finally
    FileStream.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  VERSIONINFO
// ---------------------------------------------------------------------------

// Узел дерева VS_VERSIONINFO: wLength, wValueLength, wType, ключ, значение,
// дочерние узлы. AChildren - узлы подряд, каждый с границы 4 байт.
// Длина узла - без выравнивания после него.
function VerNode(const AKey, AValue: string; AValueLen, AType: Word;
                 const AChildren: string): string;
var
  Body: string;
begin
  Body := WideBytes(AKey) + #0#0;
  // 6 байт - три поля длины и типа
  while (6 + Length(Body)) mod 4 <> 0 do
    Body := Body + #0;
  Body := Body + AValue;
  if AChildren <> '' then
  begin
    while (6 + Length(Body)) mod 4 <> 0 do
      Body := Body + #0;
    Body := Body + AChildren;
  end;
  Result := WordBytes(6 + Length(Body)) + WordBytes(AValueLen) +
            WordBytes(AType) + Body;
end;

// Дочерний узел добавить к списку: с границы 4 байт
procedure AppendNode(var AList: string; const ANode: string);
begin
  PadTo4(AList);
  AList := AList + ANode;
end;

function BuildVersionInfo(const AInfo: TVerInfo; AKeys: TStrings): string;
const
  VsFfDebug        = $01;
  VsFfPreRelease   = $02;
  VsFfPrivateBuild = $08;
  VsFfSpecialBuild = $20;
  VosWindows32     = $00000004;
  VftApp           = 1;
  VftDll           = 2;
var
  FixedInfo, Strings, Table, Children, KeyName, KeyValue: string;
  FileFlags, FileType: LongWord;
  KeyIdx: Integer;
begin
  FileFlags := 0;
  if AInfo.Debug then
    FileFlags := FileFlags or VsFfDebug;
  if AInfo.PreRelease then
    FileFlags := FileFlags or VsFfPreRelease;
  if AInfo.PrivateBuild then
    FileFlags := FileFlags or VsFfPrivateBuild;
  if AInfo.Special then
    FileFlags := FileFlags or VsFfSpecialBuild;
  if AInfo.IsDll then
    FileType := VftDll
  else
    FileType := VftApp;

  // VS_FIXEDFILEINFO, 52 байта
  FixedInfo := DWordBytes($FEEF04BD) + DWordBytes($00010000) +
    DWordBytes((LongWord(AInfo.Major) shl 16) or AInfo.Minor) +
    DWordBytes((LongWord(AInfo.Release) shl 16) or AInfo.Build) +
    DWordBytes((LongWord(AInfo.Major) shl 16) or AInfo.Minor) +
    DWordBytes((LongWord(AInfo.Release) shl 16) or AInfo.Build) +
    DWordBytes($3F) + DWordBytes(FileFlags) + DWordBytes(VosWindows32) +
    DWordBytes(FileType) + DWordBytes(0) + DWordBytes(0) + DWordBytes(0);

  // Строки: значение - UTF-16 с нулём, длина - в символах вместе с нулём
  Strings := '';
  if AKeys <> nil then
    for KeyIdx := 0 to AKeys.Count - 1 do
    begin
      KeyName := Trim(AKeys.Names[KeyIdx]);
      if KeyName = '' then
        Continue;
      KeyValue := Copy(AKeys[KeyIdx], Pos('=', AKeys[KeyIdx]) + 1, MaxInt);
      AppendNode(Strings, VerNode(KeyName, WideBytes(KeyValue) + #0#0,
                                  Length(WideBytes(KeyValue)) div 2 + 1, 1,
                                  ''));
    end;

  Table := VerNode(Format('%.4x%.4x', [AInfo.LangId, AInfo.CodePage]), '', 0,
                   1, Strings);

  Children := '';
  AppendNode(Children, VerNode('StringFileInfo', '', 0, 1, Table));
  AppendNode(Children, VerNode('VarFileInfo', '', 0, 1,
             VerNode('Translation', WordBytes(AInfo.LangId) +
                     WordBytes(AInfo.CodePage), 4, 0, '')));

  Result := VerNode('VS_VERSION_INFO', FixedInfo, 52, 0, Children);
end;

function LoadOrInit(AResFile: TResFile; const AFileName: string;
                    out AError: string): Boolean;
begin
  Result := True;
  AError := '';
  if not FileExists(AFileName) then
    AResFile.InitEmpty
  else if not AResFile.LoadFromFile(AFileName) then
  begin
    AError := 'Файл ресурсов не разобран: ' + AFileName;
    Result := False;
  end;
end;

function ResWriteVersion(const AResFile: string; const AInfo: TVerInfo;
                         AKeys: TStrings; out AError: string): Boolean;
var
  ResData: TResFile;
  ItemIdx: Integer;
  Entry: TResEntry;
begin
  Result := False;
  ResData := TResFile.Create;
  try
    if not LoadOrInit(ResData, AResFile, AError) then
      Exit;
    for ItemIdx := ResData.Count - 1 downto 0 do
      if ResData[ItemIdx].TypeOrd = RtVersion then
        ResData.Delete(ItemIdx);

    Entry := ResData.Add;
    Entry.TypeRaw := ResOrdField(RtVersion);
    Entry.NameRaw := ResOrdField(1);
    Entry.MemFlags := $0030;   // MOVEABLE, PURE
    Entry.LangId := AInfo.LangId;
    Entry.Data := BuildVersionInfo(AInfo, AKeys);

    try
      ResData.SaveToFile(AResFile);
      Result := True;
    except
      on E: Exception do
        AError := 'Не записан ' + AResFile + ': ' + E.Message;
    end;
  finally
    ResData.Free;
  end;
end;

function ResRemoveVersion(const AResFile: string; out AError: string): Boolean;
var
  ResData: TResFile;
  ItemIdx: Integer;
  Removed: Boolean;
begin
  Result := True;
  AError := '';
  if not FileExists(AResFile) then
    Exit;
  ResData := TResFile.Create;
  try
    if not ResData.LoadFromFile(AResFile) then
    begin
      AError := 'Файл ресурсов не разобран: ' + AResFile;
      Result := False;
      Exit;
    end;
    Removed := False;
    for ItemIdx := ResData.Count - 1 downto 0 do
      if ResData[ItemIdx].TypeOrd = RtVersion then
      begin
        ResData.Delete(ItemIdx);
        Removed := True;
      end;
    if Removed then
      try
        ResData.SaveToFile(AResFile);
      except
        on E: Exception do
        begin
          AError := 'Не записан ' + AResFile + ': ' + E.Message;
          Result := False;
        end;
      end;
  finally
    ResData.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  MAINICON
// ---------------------------------------------------------------------------

function ResExtractMainIcon(const AResFile: string; AStream: TStream): Boolean;
var
  ResData: TResFile;
  GroupIdx, IconIdx, ImageCount, ImageIdx, ImageOffset: Integer;
  GroupData, Header, Images, ImageData: string;
begin
  Result := False;
  ResData := TResFile.Create;
  try
    if not ResData.LoadFromFile(AResFile) then
      Exit;
    GroupIdx := ResData.FindByName(RtGroupIcon, 'MAINICON');
    if GroupIdx < 0 then
      Exit;
    GroupData := ResData[GroupIdx].Data;
    if Length(GroupData) < 6 then
      Exit;
    ImageCount := ReadWordAt(GroupData, 5);
    if Length(GroupData) < 6 + ImageCount * 14 then
      Exit;

    Header := Copy(GroupData, 1, 6);
    Images := '';
    ImageOffset := 6 + ImageCount * 16;
    for ImageIdx := 0 to ImageCount - 1 do
    begin
      IconIdx := ResData.FindByOrd(RtIcon,
                                   ReadWordAt(GroupData, 6 + ImageIdx * 14 + 13));
      if IconIdx < 0 then
        Exit;
      ImageData := ResData[IconIdx].Data;
      // Запись каталога .ico: 12 байт как в группе, затем смещение
      Header := Header + Copy(GroupData, 6 + ImageIdx * 14 + 1, 8) +
                DWordBytes(Length(ImageData)) + DWordBytes(ImageOffset);
      Images := Images + ImageData;
      Inc(ImageOffset, Length(ImageData));
    end;

    Header := Header + Images;
    AStream.WriteBuffer(Header[1], Length(Header));
    Result := True;
  finally
    ResData.Free;
  end;
end;

function ResReplaceMainIcon(const AResFile, AIcoFile: string;
                            out AError: string): Boolean;
var
  ResData: TResFile;
  FileStream: TFileStream;
  IcoBuf, GroupData, ImageData: string;
  ImageCount, ImageIdx, DirPos, ItemIdx, NextId, LangId: Integer;
  ImageSize, ImageOffset: LongWord;
  OldIds: TList;
  GroupIdx: Integer;
  Entry: TResEntry;
begin
  Result := False;
  AError := '';
  if not FileExists(AIcoFile) then
  begin
    AError := 'Файл не найден: ' + AIcoFile;
    Exit;
  end;

  FileStream := TFileStream.Create(AIcoFile, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(IcoBuf, FileStream.Size);
    if FileStream.Size > 0 then
      FileStream.ReadBuffer(IcoBuf[1], FileStream.Size);
  finally
    FileStream.Free;
  end;

  if (Length(IcoBuf) < 6) or (ReadWordAt(IcoBuf, 1) <> 0) or
     (ReadWordAt(IcoBuf, 3) <> 1) then
  begin
    AError := 'Это не файл значка (.ico): ' + AIcoFile;
    Exit;
  end;
  ImageCount := ReadWordAt(IcoBuf, 5);
  if (ImageCount = 0) or (Length(IcoBuf) < 6 + ImageCount * 16) then
  begin
    AError := 'В файле значка нет изображений: ' + AIcoFile;
    Exit;
  end;

  ResData := TResFile.Create;
  OldIds := TList.Create;
  try
    if not LoadOrInit(ResData, AResFile, AError) then
      Exit;

    // Прежний MAINICON и его изображения - вон
    LangId := $0409;
    GroupIdx := ResData.FindByName(RtGroupIcon, 'MAINICON');
    if GroupIdx >= 0 then
    begin
      LangId := ResData[GroupIdx].LangId;
      GroupData := ResData[GroupIdx].Data;
      if Length(GroupData) >= 6 then
        for ImageIdx := 0 to ReadWordAt(GroupData, 5) - 1 do
          if Length(GroupData) >= 6 + (ImageIdx + 1) * 14 then
            OldIds.Add(Pointer(Integer(ReadWordAt(GroupData,
                                                  6 + ImageIdx * 14 + 13))));
      ResData.Delete(GroupIdx);
      for ItemIdx := ResData.Count - 1 downto 0 do
        if (ResData[ItemIdx].TypeOrd = RtIcon) and
           (OldIds.IndexOf(Pointer(ResData[ItemIdx].NameOrd)) >= 0) then
          ResData.Delete(ItemIdx);
    end;

    // Номера новых изображений - после занятых другими значками
    NextId := 1;
    for ItemIdx := 0 to ResData.Count - 1 do
      if (ResData[ItemIdx].TypeOrd = RtIcon) and
         (ResData[ItemIdx].NameOrd >= NextId) then
        NextId := ResData[ItemIdx].NameOrd + 1;

    GroupData := Copy(IcoBuf, 1, 6);
    for ImageIdx := 0 to ImageCount - 1 do
    begin
      DirPos := 7 + ImageIdx * 16;
      ImageSize := ReadDWordAt(IcoBuf, DirPos + 8);
      ImageOffset := ReadDWordAt(IcoBuf, DirPos + 12);
      if Int64(ImageOffset) + ImageSize > Length(IcoBuf) then
      begin
        AError := 'Файл значка повреждён: ' + AIcoFile;
        Exit;
      end;
      ImageData := Copy(IcoBuf, ImageOffset + 1, ImageSize);

      Entry := ResData.Add;
      Entry.TypeRaw := ResOrdField(RtIcon);
      Entry.NameRaw := ResOrdField(NextId + ImageIdx);
      Entry.MemFlags := $1010;   // MOVEABLE, DISCARDABLE
      Entry.LangId := LangId;
      Entry.Data := ImageData;

      // Запись группы: 12 байт каталога .ico и номер изображения
      GroupData := GroupData + Copy(IcoBuf, DirPos, 12) +
                   WordBytes(NextId + ImageIdx);
    end;

    Entry := ResData.Add;
    Entry.TypeRaw := ResOrdField(RtGroupIcon);
    Entry.NameRaw := ResNameField('MAINICON');
    Entry.MemFlags := $1030;     // MOVEABLE, PURE, DISCARDABLE
    Entry.LangId := LangId;
    Entry.Data := GroupData;

    try
      ResData.SaveToFile(AResFile);
      Result := True;
    except
      on E: Exception do
        AError := 'Не записан ' + AResFile + ': ' + E.Message;
    end;
  finally
    OldIds.Free;
    ResData.Free;
  end;
end;

end.
