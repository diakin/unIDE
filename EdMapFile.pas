unit EdMapFile;

// ---------------------------------------------------------------------------
//  Файл, отображённый в память только для чтения (шаг 0.7.8, большие
//  файлы). TEdBuffer.LoadMapped берёт байты прямо отсюда и освобождает
//  объект сам, когда текст буфера заменяется.
//
//  Файл открыт с FILE_SHARE_READ: пока он отображён, другие программы могут
//  его читать, но не писать, не удалять и не переименовывать - иначе байты
//  под буфером поменялись бы. Запись своего текста - через временный файл
//  (EdFileText.EdSaveMapped): отображение снимается, временный файл
//  становится на место прежнего и отображается заново.
//
//  Windows и Unix (fpmmap); без VCL/LCL.
// ---------------------------------------------------------------------------

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
{$IFDEF MSWINDOWS}
  Windows,
{$ELSE}
  BaseUnix,
{$ENDIF}
  SysUtils;

const
  // С этого размера файл открывается отображением, а не чтением в строку
  EdLargeFileSize = 100 * 1024 * 1024;

type
  TEdMappedFile = class
  private
    FFileName: string;
    FData: PAnsiChar;
    FSize: Integer;
{$IFDEF MSWINDOWS}
    FFile: THandle;
    FMapping: THandle;
{$ELSE}
    FHandle: cint;
{$ENDIF}
  public
    // Исключение, если файл не открыть или не отобразить (32-битной
    // программе может не хватить свободного места в адресах)
    constructor Create(const AFileName: string);
    destructor Destroy; override;
    property FileName: string read FFileName;
    property Data: PAnsiChar read FData;
    property Size: Integer read FSize;
  end;

// Размер файла; -1 - файла нет или не открыть
function EdFileSize(const AFileName: string): Int64;

implementation

function EdFileSize(const AFileName: string): Int64;
var
  SearchRec: TSearchRec;
begin
  Result := -1;
  if FindFirst(AFileName, faAnyFile, SearchRec) = 0 then
  begin
{$IFDEF MSWINDOWS}
    Result := Int64(SearchRec.FindData.nFileSizeHigh) shl 32 or
      SearchRec.FindData.nFileSizeLow;
{$ELSE}
    Result := SearchRec.Size;
{$ENDIF}
    FindClose(SearchRec);
  end;
end;

{$IFDEF MSWINDOWS}

constructor TEdMappedFile.Create(const AFileName: string);
var
  SizeHigh, SizeLow: DWORD;
  ErrorCode: DWORD;
begin
  inherited Create;
  FFileName := AFileName;
  FFile := CreateFile(PChar(AFileName), GENERIC_READ, FILE_SHARE_READ, nil,
    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN, 0);
  if FFile = INVALID_HANDLE_VALUE then
    raise Exception.Create('Файл не открыт: ' + SysErrorMessage(GetLastError));
  SizeLow := GetFileSize(FFile, @SizeHigh);
  if (SizeHigh <> 0) or (SizeLow > DWORD(MaxInt)) then
    raise Exception.Create('Файл больше 2 ГБ - пока не открывается');
  FSize := SizeLow;
  if FSize = 0 then
    Exit;
  FMapping := CreateFileMapping(FFile, nil, PAGE_READONLY, 0, 0, nil);
  if FMapping = 0 then
    raise Exception.Create('Отображение файла не создано: ' +
      SysErrorMessage(GetLastError));
  FData := MapViewOfFile(FMapping, FILE_MAP_READ, 0, 0, 0);
  if FData = nil then
  begin
    ErrorCode := GetLastError;
    raise Exception.Create(Format('Файл %d МБ не отображён в память: %s',
      [FSize div (1024 * 1024), SysErrorMessage(ErrorCode)]));
  end;
end;

destructor TEdMappedFile.Destroy;
begin
  if FData <> nil then
    UnmapViewOfFile(FData);
  FData := nil;
  if FMapping <> 0 then
    CloseHandle(FMapping);
  FMapping := 0;
  if (FFile <> 0) and (FFile <> INVALID_HANDLE_VALUE) then
    CloseHandle(FFile);
  FFile := 0;
  inherited Destroy;
end;

{$ELSE}

constructor TEdMappedFile.Create(const AFileName: string);
var
  FileInfo: Stat;
  MapAddr: Pointer;
begin
  inherited Create;
  FFileName := AFileName;
  FHandle := FpOpen(AFileName, O_RDONLY);
  if FHandle < 0 then
    raise Exception.Create('Файл не открыт: ' + SysErrorMessage(fpgeterrno));
  if FpFStat(FHandle, FileInfo) <> 0 then
    raise Exception.Create('Размер файла не получен');
  if FileInfo.st_size > MaxInt then
    raise Exception.Create('Файл больше 2 ГБ - пока не открывается');
  FSize := FileInfo.st_size;
  if FSize = 0 then
    Exit;
  MapAddr := FpMmap(nil, FSize, PROT_READ, MAP_PRIVATE, FHandle, 0);
  if MapAddr = MAP_FAILED then
    raise Exception.Create('Файл не отображён в память: ' +
      SysErrorMessage(fpgeterrno));
  FData := MapAddr;
end;

destructor TEdMappedFile.Destroy;
begin
  if FData <> nil then
    FpMunmap(FData, FSize);
  FData := nil;
  if FHandle > 0 then
    FpClose(FHandle);
  FHandle := 0;
  inherited Destroy;
end;

{$ENDIF}

end.
