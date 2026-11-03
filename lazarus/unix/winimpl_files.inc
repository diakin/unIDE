// unIDE, Linux build: file functions for unIDE FAR (stage 5 of the port
// plan): FindFirstFileW/FindNextFileW/FindClose, free space, folder change
// "notifications" (polling of the folder time), SHFileOperationW (copy,
// move, rename, delete, delete to the desktop trash), ShellExecuteW
// (xdg-open), file attributes.

// Text of this file (CP_ACP, 1251) -> UTF-8
function AcpText(const AText: AnsiString): AnsiString;
begin
  Result := AcpToUtf8(PAnsiChar(AText), Length(AText));
end;

// --- FindFirstFileW ---

const
  UnixFindBase = $50000000;
  UnixWatchBase = $51000000;
  UnixHandleSpan = $00100000;

type
  TUnixFind = record
    Used: Boolean;
    Dir: AnsiString;       // folder of the mask, with '/'
    Search: TSearchRec;
  end;

var
  UnixFinds: array of TUnixFind;

procedure UnixFillFindData(const ADir, AName: AnsiString; var AData: WIN32_FIND_DATAW);
var
  StatBuf: BaseUnix.Stat;
  WideName: UnicodeString;
  CharIdx: Integer;
begin
  FillChar(AData, SizeOf(AData), 0);
  if (fpStat(PChar(ADir + AName), StatBuf) <> 0) and
     (fpLStat(PChar(ADir + AName), StatBuf) <> 0) then
    FillChar(StatBuf, SizeOf(StatBuf), 0);
  if fpS_ISDIR(StatBuf.st_mode) then
    AData.dwFileAttributes := FILE_ATTRIBUTE_DIRECTORY
  else
    AData.dwFileAttributes := FILE_ATTRIBUTE_ARCHIVE;
  if (AName <> '') and (AName[1] = '.') and (AName <> '.') and (AName <> '..') then
    AData.dwFileAttributes := AData.dwFileAttributes or FILE_ATTRIBUTE_HIDDEN;
  if fpAccess(PChar(ADir + AName), W_OK) <> 0 then
    AData.dwFileAttributes := AData.dwFileAttributes or FILE_ATTRIBUTE_READONLY;
  UnixToFileTime(StatBuf.st_mtime, AData.ftLastWriteTime);
  UnixToFileTime(StatBuf.st_atime, AData.ftLastAccessTime);
  UnixToFileTime(StatBuf.st_ctime, AData.ftCreationTime);
  if not fpS_ISDIR(StatBuf.st_mode) then
  begin
    AData.nFileSizeLow := DWORD(Int64(StatBuf.st_size) and $FFFFFFFF);
    AData.nFileSizeHigh := DWORD(Int64(StatBuf.st_size) shr 32);
  end;
  WideName := UTF8Decode(AName);
  for CharIdx := 1 to Length(WideName) do
  begin
    if CharIdx > High(AData.cFileName) then
      Break;
    AData.cFileName[CharIdx - 1] := WideName[CharIdx];
  end;
end;

function Impl_FindFirstFileW(AFileName: PWideChar; var AFindData): THandle; stdcall; public name 'unidewin_FindFirstFileW';
var
  Mask: AnsiString;
  FindIdx, SlashPos: Integer;
begin
  Result := INVALID_HANDLE_VALUE;
  Mask := WideToUtf8(AFileName, -1);
  FindIdx := 0;
  while (FindIdx <= High(UnixFinds)) and UnixFinds[FindIdx].Used do
    Inc(FindIdx);
  if FindIdx > High(UnixFinds) then
    SetLength(UnixFinds, FindIdx + 1);
  SlashPos := Length(Mask);
  while (SlashPos > 0) and (Mask[SlashPos] <> '/') do
    Dec(SlashPos);
  UnixFinds[FindIdx].Dir := Copy(Mask, 1, SlashPos);
  if SysUtils.FindFirst(Mask, faAnyFile or faDirectory or faHidden or faSysFile,
                        UnixFinds[FindIdx].Search) <> 0 then
  begin
    SysUtils.FindClose(UnixFinds[FindIdx].Search);
    UnixLastError := ERROR_FILE_NOT_FOUND;
    Exit;
  end;
  UnixFinds[FindIdx].Used := True;
  UnixFillFindData(UnixFinds[FindIdx].Dir, UnixFinds[FindIdx].Search.Name,
                   WIN32_FIND_DATAW(AFindData));
  Result := UnixFindBase + FindIdx;
end;

function UnixFindIndex(AHandle: THandle): Integer;
begin
  Result := -1;
  if (AHandle < UnixFindBase) or (AHandle >= UnixFindBase + UnixHandleSpan) then
    Exit;
  Result := AHandle - UnixFindBase;
  if (Result > High(UnixFinds)) or not UnixFinds[Result].Used then
    Result := -1;
end;

function Impl_FindNextFileW(AFindHandle: THandle; var AFindData): BOOL; stdcall; public name 'unidewin_FindNextFileW';
var
  FindIdx: Integer;
begin
  Result := False;
  FindIdx := UnixFindIndex(AFindHandle);
  if FindIdx < 0 then
    Exit;
  if SysUtils.FindNext(UnixFinds[FindIdx].Search) <> 0 then
  begin
    UnixLastError := ERROR_NO_MORE_FILES;
    Exit;
  end;
  UnixFillFindData(UnixFinds[FindIdx].Dir, UnixFinds[FindIdx].Search.Name,
                   WIN32_FIND_DATAW(AFindData));
  Result := True;
end;

function Impl_FindClose(AFindHandle: THandle): BOOL; stdcall; public name 'unidewin_FindClose';
var
  FindIdx: Integer;
begin
  Result := False;
  FindIdx := UnixFindIndex(AFindHandle);
  if FindIdx < 0 then
    Exit;
  SysUtils.FindClose(UnixFinds[FindIdx].Search);
  UnixFinds[FindIdx].Used := False;
  Result := True;
end;

// --- space, times, drives ---

function Impl_GetDiskFreeSpaceExW(ADir: PWideChar; AFreeAvail, ATotalBytes, ATotalFree: PInt64): BOOL; stdcall; public name 'unidewin_GetDiskFreeSpaceExW';
var
  FsInfo: TStatFS;
  DirName: AnsiString;
begin
  Result := False;
  DirName := WideToUtf8(ADir, -1);
  if fpStatFS(PChar(DirName), @FsInfo) <> 0 then
    Exit;
  if AFreeAvail <> nil then
    AFreeAvail^ := Int64(FsInfo.bavail) * FsInfo.bsize;
  if ATotalBytes <> nil then
    ATotalBytes^ := Int64(FsInfo.blocks) * FsInfo.bsize;
  if ATotalFree <> nil then
    ATotalFree^ := Int64(FsInfo.bfree) * FsInfo.bsize;
  Result := True;
end;

function Impl_CompareFileTime(AFirst, ASecond: PFileTime): Longint; stdcall; public name 'unidewin_CompareFileTime';
var
  FirstTicks, SecondTicks: Int64;
begin
  FirstTicks := (Int64(AFirst^.dwHighDateTime) shl 32) or AFirst^.dwLowDateTime;
  SecondTicks := (Int64(ASecond^.dwHighDateTime) shl 32) or ASecond^.dwLowDateTime;
  if FirstTicks < SecondTicks then
    Result := -1
  else if FirstTicks > SecondTicks then
    Result := 1
  else
    Result := 0;
end;

function Impl_GetDriveTypeW(ARoot: PWideChar): UINT; stdcall; public name 'unidewin_GetDriveTypeW';
begin
  if DirectoryExists(WideToUtf8(ARoot, -1)) then
    Result := DRIVE_FIXED
  else
    Result := DRIVE_NO_ROOT_DIR;
end;

function Impl_GetShortPathNameW(ALongPath, AShortPath: PWideChar; ABufferLen: DWORD): DWORD; stdcall; public name 'unidewin_GetShortPathNameW';
var
  PathLen: DWORD;
begin
  PathLen := 0;
  while ALongPath[PathLen] <> #0 do
    Inc(PathLen);
  Result := PathLen;
  if (AShortPath = nil) or (ABufferLen <= PathLen) then
  begin
    Result := PathLen + 1;
    Exit;
  end;
  Move(ALongPath^, AShortPath^, (PathLen + 1) * SizeOf(WideChar));
end;

// Read-only: write bits of the owner off / on; other attributes - nothing
function Impl_SetFileAttributesW(AFileName: PWideChar; AAttr: DWORD): BOOL; stdcall; public name 'unidewin_SetFileAttributesW';
var
  FileName: AnsiString;
  StatBuf: BaseUnix.Stat;
  NewMode: TMode;
begin
  Result := False;
  FileName := WideToUtf8(AFileName, -1);
  if fpStat(PChar(FileName), StatBuf) <> 0 then
    Exit;
  NewMode := StatBuf.st_mode and $FFF;
  if AAttr and FILE_ATTRIBUTE_READONLY <> 0 then
    NewMode := NewMode and not (S_IWUSR or S_IWGRP or S_IWOTH)
  else
    NewMode := NewMode or S_IWUSR;
  Result := fpChmod(PChar(FileName), NewMode) = 0;
end;

// --- folder change "notifications": the folder time is polled ---

type
  TUnixWatch = record
    Used: Boolean;
    Dir: AnsiString;
    Stamp: Int64;
  end;

var
  UnixWatches: array of TUnixWatch;

function UnixDirStamp(const ADir: AnsiString): Int64;
var
  StatBuf: BaseUnix.Stat;
begin
  Result := -1;
  if fpStat(PChar(ADir), StatBuf) = 0 then
    Result := Int64(StatBuf.st_mtime) * 1000000000 + StatBuf.st_mtime_nsec +
              Int64(StatBuf.st_ctime) * 7;
end;

function UnixWatchIndex(AHandle: THandle): Integer;
begin
  Result := -1;
  if (AHandle < UnixWatchBase) or (AHandle >= UnixWatchBase + UnixHandleSpan) then
    Exit;
  Result := AHandle - UnixWatchBase;
  if (Result > High(UnixWatches)) or not UnixWatches[Result].Used then
    Result := -1;
end;

function Impl_FindFirstChangeNotificationW(APath: PWideChar; AWatchSubtree: BOOL; AFilter: DWORD): THandle; stdcall; public name 'unidewin_FindFirstChangeNotificationW';
var
  WatchIdx: Integer;
begin
  Result := INVALID_HANDLE_VALUE;
  WatchIdx := 0;
  while (WatchIdx <= High(UnixWatches)) and UnixWatches[WatchIdx].Used do
    Inc(WatchIdx);
  if WatchIdx > High(UnixWatches) then
    SetLength(UnixWatches, WatchIdx + 1);
  UnixWatches[WatchIdx].Dir := WideToUtf8(APath, -1);
  UnixWatches[WatchIdx].Stamp := UnixDirStamp(UnixWatches[WatchIdx].Dir);
  if UnixWatches[WatchIdx].Stamp < 0 then
    Exit;
  UnixWatches[WatchIdx].Used := True;
  Result := UnixWatchBase + WatchIdx;
end;

function Impl_FindNextChangeNotification(AHandle: THandle): BOOL; stdcall; public name 'unidewin_FindNextChangeNotification';
var
  WatchIdx: Integer;
begin
  WatchIdx := UnixWatchIndex(AHandle);
  Result := WatchIdx >= 0;
  if Result then
    UnixWatches[WatchIdx].Stamp := UnixDirStamp(UnixWatches[WatchIdx].Dir);
end;

function Impl_FindCloseChangeNotification(AHandle: THandle): BOOL; stdcall; public name 'unidewin_FindCloseChangeNotification';
var
  WatchIdx: Integer;
begin
  WatchIdx := UnixWatchIndex(AHandle);
  Result := WatchIdx >= 0;
  if Result then
    UnixWatches[WatchIdx].Used := False;
end;

// WaitForSingleObject on a watch handle: changed since the last
// FindNextChangeNotification -> WAIT_OBJECT_0
function UnixWatchSignaled(AHandle: THandle; var ASignaled: Boolean): Boolean;
var
  WatchIdx: Integer;
begin
  WatchIdx := UnixWatchIndex(AHandle);
  Result := WatchIdx >= 0;
  if Result then
    ASignaled := UnixDirStamp(UnixWatches[WatchIdx].Dir) <>
                 UnixWatches[WatchIdx].Stamp;
end;

// --- SHFileOperationW ---

type
  // SHFILEOPSTRUCTW, 64-bit layout (natural alignment)
  TUnixShFileOp = record
    Wnd: HWND;
    Func: UINT;
    From: PWideChar;
    Dest: PWideChar;
    Flags: Word;
    AnyAborted: BOOL;
    NameMappings: Pointer;
    ProgressTitle: PWideChar;
  end;
  PUnixShFileOp = ^TUnixShFileOp;

const
  UnixFoMove = 1;
  UnixFoCopy = 2;
  UnixFoDelete = 3;
  UnixFoRename = 4;
  UnixFofMultiDest = $0001;
  UnixFofSilent = $0004;
  UnixFofNoConfirmation = $0010;
  UnixFofAllowUndo = $0040;
  UnixFofNoErrorUi = $0400;

// Double-null list -> strings (UTF-8)
procedure UnixSplitList(AList: PWideChar; AItems: TStrings);
var
  ItemText: UnicodeString;
begin
  AItems.Clear;
  if AList = nil then
    Exit;
  while AList^ <> #0 do
  begin
    ItemText := AList;
    AItems.Add(UTF8Encode(ItemText));
    Inc(AList, Length(ItemText) + 1);
  end;
end;

function UnixStripSlash(const APath: AnsiString): AnsiString;
begin
  Result := APath;
  while (Length(Result) > 1) and (Result[Length(Result)] = '/') do
    SetLength(Result, Length(Result) - 1);
end;

function UnixIsDir(const APath: AnsiString): Boolean;
var
  StatBuf: BaseUnix.Stat;
begin
  Result := (fpLStat(PChar(APath), StatBuf) = 0) and fpS_ISDIR(StatBuf.st_mode);
end;

function UnixExists(const APath: AnsiString): Boolean;
var
  StatBuf: BaseUnix.Stat;
begin
  Result := fpLStat(PChar(APath), StatBuf) = 0;
end;

// Remove a file, link or folder with everything in it
function UnixRemoveTree(const APath: AnsiString): Boolean;
var
  Found: TSearchRec;
begin
  if not UnixIsDir(APath) then
  begin
    Result := fpUnlink(PChar(APath)) = 0;
    Exit;
  end;
  if SysUtils.FindFirst(APath + '/*', faAnyFile or faDirectory or faHidden or
                        faSysFile, Found) = 0 then
  try
    repeat
      if (Found.Name = '.') or (Found.Name = '..') then
        Continue;
      UnixRemoveTree(APath + '/' + Found.Name);
    until SysUtils.FindNext(Found) <> 0;
  finally
    SysUtils.FindClose(Found);
  end;
  Result := fpRmdir(PChar(APath)) = 0;
end;

function UnixCopyFileData(const ASource, ATarget: AnsiString): Boolean;
var
  SourceFd, TargetFd: cint;
  Buffer: array[0..65535] of Byte;
  ReadCount, WriteCount: TSsize;
  StatBuf: BaseUnix.Stat;
  Times: TUTimBuf;
begin
  Result := False;
  if fpStat(PChar(ASource), StatBuf) <> 0 then
    Exit;
  SourceFd := fpOpen(PChar(ASource), O_RDONLY);
  if SourceFd < 0 then
    Exit;
  try
    TargetFd := fpOpen(PChar(ATarget), O_WRONLY or O_CREAT or O_TRUNC,
                       StatBuf.st_mode and $FFF);
    if TargetFd < 0 then
      Exit;
    try
      repeat
        ReadCount := fpRead(SourceFd, Buffer, SizeOf(Buffer));
        if ReadCount < 0 then
          Exit;
        if ReadCount = 0 then
          Break;
        WriteCount := fpWrite(TargetFd, Buffer, ReadCount);
        if WriteCount <> ReadCount then
          Exit;
      until False;
    finally
      fpClose(TargetFd);
    end;
  finally
    fpClose(SourceFd);
  end;
  Times.actime := StatBuf.st_atime;
  Times.modtime := StatBuf.st_mtime;
  fpUtime(PChar(ATarget), @Times);
  Result := True;
end;

// Copy a file, link or folder (recursively) to ATarget (full new name)
function UnixCopyTree(const ASource, ATarget: AnsiString): Boolean;
var
  StatBuf: BaseUnix.Stat;
  Found: TSearchRec;
  LinkText: AnsiString;
begin
  Result := False;
  if fpLStat(PChar(ASource), StatBuf) <> 0 then
    Exit;
  if fpS_ISLNK(StatBuf.st_mode) then
  begin
    LinkText := fpReadLink(ASource);
    if UnixExists(ATarget) then
      fpUnlink(PChar(ATarget));
    Result := fpSymlink(PChar(LinkText), PChar(ATarget)) = 0;
    Exit;
  end;
  if not fpS_ISDIR(StatBuf.st_mode) then
  begin
    Result := UnixCopyFileData(ASource, ATarget);
    Exit;
  end;
  if not UnixIsDir(ATarget) and (fpMkdir(PChar(ATarget), StatBuf.st_mode and $FFF) <> 0) then
    Exit;
  Result := True;
  if SysUtils.FindFirst(ASource + '/*', faAnyFile or faDirectory or faHidden or
                        faSysFile, Found) = 0 then
  try
    repeat
      if (Found.Name = '.') or (Found.Name = '..') then
        Continue;
      if not UnixCopyTree(ASource + '/' + Found.Name, ATarget + '/' + Found.Name) then
        Result := False;
    until SysUtils.FindNext(Found) <> 0;
  finally
    SysUtils.FindClose(Found);
  end;
end;

// Desktop trash (freedesktop.org): ~/.local/share/Trash/files + info
function UnixToTrash(const APath: AnsiString): Boolean;
var
  TrashDir, BaseName, TrashName, InfoText: AnsiString;
  NameNo: Integer;
  InfoFile: TextFile;
begin
  Result := False;
  TrashDir := SysUtils.GetEnvironmentVariable('XDG_DATA_HOME');
  if TrashDir = '' then
    TrashDir := SysUtils.GetEnvironmentVariable('HOME') + '/.local/share';
  TrashDir := TrashDir + '/Trash/';
  if not ForceDirectories(TrashDir + 'files') or
     not ForceDirectories(TrashDir + 'info') then
    Exit;
  BaseName := ExtractFileName(UnixStripSlash(APath));
  TrashName := BaseName;
  NameNo := 1;
  while UnixExists(TrashDir + 'files/' + TrashName) or
        FileExists(TrashDir + 'info/' + TrashName + '.trashinfo') do
  begin
    Inc(NameNo);
    TrashName := BaseName + '.' + IntToStr(NameNo);
  end;
  InfoText := '[Trash Info]'#10'Path=' + UnixStripSlash(APath) + #10 +
              'DeletionDate=' + FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now) + #10;
  try
    AssignFile(InfoFile, TrashDir + 'info/' + TrashName + '.trashinfo');
    Rewrite(InfoFile);
    Write(InfoFile, InfoText);
    CloseFile(InfoFile);
  except
    Exit;
  end;
  // Another file system: rename fails (EXDEV) - the file stays in place
  if fpRename(PChar(UnixStripSlash(APath)), PChar(TrashDir + 'files/' + TrashName)) <> 0 then
  begin
    DeleteFile(TrashDir + 'info/' + TrashName + '.trashinfo');
    Exit;
  end;
  Result := True;
end;

// Overwrite question when the operation has no FOF_NOCONFIRMATION:
// IDYES, IDNO (skip), IDCANCEL
function UnixAskReplace(AOp: PUnixShFileOp; const ATarget: AnsiString;
  var AReplaceAll: Boolean): Integer;
var
  QuestionText: UnicodeString;
begin
  if AReplaceAll or (AOp^.Flags and UnixFofNoConfirmation <> 0) then
  begin
    Result := IDYES;
    Exit;
  end;
  QuestionText := UTF8Decode(AcpText('Файл уже есть:') + LineEnding + ATarget +
    LineEnding + AcpText('Заменить его?'));
  Result := Impl_MessageBoxW(AOp^.Wnd, PWideChar(QuestionText),
    PWideChar(UnicodeString('unIDE')), MB_YESNOCANCEL or MB_ICONQUESTION);
end;

function Impl_SHFileOperationW(var AOp): Integer; stdcall; public name 'unidewin_SHFileOperationW';
var
  FileOp: PUnixShFileOp;
  Sources, Targets: TStringList;
  ItemIdx, Answer: Integer;
  Source, Target, TargetDir: AnsiString;
  ReplaceAll, AllOk, IntoDir: Boolean;
begin
  FileOp := PUnixShFileOp(@AOp);
  FileOp^.AnyAborted := False;
  Result := 0;
  AllOk := True;
  ReplaceAll := False;
  Sources := TStringList.Create;
  Targets := TStringList.Create;
  try
    UnixSplitList(FileOp^.From, Sources);
    UnixSplitList(FileOp^.Dest, Targets);
    if Sources.Count = 0 then
      Exit;
    if FileOp^.Func = UnixFoDelete then
    begin
      for ItemIdx := 0 to Sources.Count - 1 do
      begin
        Source := UnixStripSlash(Sources[ItemIdx]);
        if not UnixExists(Source) then
          Continue;
        if FileOp^.Flags and UnixFofAllowUndo <> 0 then
        begin
          if not UnixToTrash(Source) then
            AllOk := False;
        end
        else if not UnixRemoveTree(Source) then
          AllOk := False;
      end;
    end
    else
    begin
      if Targets.Count = 0 then
      begin
        Result := ERROR_INVALID_PARAMETER;
        Exit;
      end;
      TargetDir := '';
      IntoDir := False;
      if FileOp^.Flags and UnixFofMultiDest = 0 then
      begin
        TargetDir := UnixStripSlash(Targets[0]);
        // Several sources or an existing folder - into the folder
        IntoDir := (FileOp^.Func <> UnixFoRename) and
                   ((Sources.Count > 1) or UnixIsDir(TargetDir) or
                    (Copy(Targets[0], Length(Targets[0]), 1) = '/'));
        if IntoDir and not UnixIsDir(TargetDir) then
          ForceDirectories(TargetDir);
      end;
      for ItemIdx := 0 to Sources.Count - 1 do
      begin
        Source := UnixStripSlash(Sources[ItemIdx]);
        if FileOp^.Flags and UnixFofMultiDest <> 0 then
        begin
          if ItemIdx >= Targets.Count then
            Break;
          Target := UnixStripSlash(Targets[ItemIdx]);
        end
        else if IntoDir then
          Target := TargetDir + '/' + ExtractFileName(Source)
        else
          Target := TargetDir;
        if Target = Source then
          Continue;
        if UnixExists(Target) then
        begin
          Answer := UnixAskReplace(FileOp, Target, ReplaceAll);
          if Answer = IDCANCEL then
          begin
            FileOp^.AnyAborted := True;
            Break;
          end;
          if Answer = IDNO then
            Continue;
          if UnixIsDir(Target) <> UnixIsDir(Source) then
            UnixRemoveTree(Target)
          else if not UnixIsDir(Target) then
            fpUnlink(PChar(Target));
        end;
        case FileOp^.Func of
          UnixFoCopy:
            if not UnixCopyTree(Source, Target) then
              AllOk := False;
          UnixFoMove, UnixFoRename:
            if fpRename(PChar(Source), PChar(Target)) <> 0 then
            begin
              // Another file system or a folder over a folder: copy + remove
              if UnixCopyTree(Source, Target) then
                UnixRemoveTree(Source)
              else
                AllOk := False;
            end;
        end;
      end;
    end;
  finally
    Targets.Free;
    Sources.Free;
  end;
  if not AllOk then
  begin
    Result := ERROR_ACCESS_DENIED;
    if FileOp^.Flags and (UnixFofNoErrorUi or UnixFofSilent) = 0 then
      Impl_MessageBoxW(FileOp^.Wnd,
        PWideChar(UTF8Decode(AcpText('Часть файлов не обработана (нет прав, ' +
          'файл занят или корзина на другом диске).'))),
        PWideChar(UnicodeString('unIDE')), MB_OK or MB_ICONWARNING);
  end;
end;

// --- ShellExecuteW: open with the desktop program (xdg-open) ---

function Impl_ShellExecuteW(AWnd: HWND; AOperation, AFile, AParameters, ADirectory: PWideChar; AShowCmd: Integer): THandle; stdcall; public name 'unidewin_ShellExecuteW';
var
  Launch: TProcess;
  FileName: AnsiString;
begin
  Result := 2;  // <= 32: error, as in Windows
  if AFile = nil then
    Exit;
  FileName := WideToUtf8(AFile, -1);
  Launch := TProcess.Create(nil);
  try
    if (fpAccess(PChar(FileName), X_OK) = 0) and not DirectoryExists(FileName) then
    begin
      Launch.Executable := FileName;
      if (AParameters <> nil) and (AParameters^ <> #0) then
        CommandToList(WideToUtf8(AParameters, -1), Launch.Parameters);
    end
    else
    begin
      Launch.Executable := 'xdg-open';
      Launch.Parameters.Add(FileName);
    end;
    if (ADirectory <> nil) and (ADirectory^ <> #0) then
      Launch.CurrentDirectory := WideToUtf8(ADirectory, -1);
    try
      Launch.Execute;
      Result := 42;
    except
      Result := 2;
    end;
  finally
    Launch.Free;
  end;
end;
