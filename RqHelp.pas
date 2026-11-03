unit RqHelp;

// ---------------------------------------------------------------------------
//  Справка RapidQ: rapidq_ref\help\rapidq.chm и HTML-страницы
//  rapidq_ref\html_doc (CHM собирает rapidq_ref\compdoc\gen_chm.py).
//
//  CHM показывается через HtmlHelpA из hhctrl.ocx. Библиотека грузится
//  при первом вызове (LoadLibrary): если её нет, программа всё равно
//  запускается, а справка сообщает об ошибке.
//
//  Папка rapidq_ref ищется по порядку: рядом с exe, на уровень выше exe
//  (exe в Output\, rapidq_ref - рядом с .dpr), в каждом проекте папки
//  projects у exe. Для CHM и для HTML поиск отдельный: рядом с exe после
//  пересборки лежит только CHM (CopyOwnRunFiles), а html_doc - в исходниках.
//
//  Linux: hhctrl.ocx нет - HtmlHelpProc = UnixHtmlHelp: CHM распаковывается
//  (chmreader из FPC) в ~/.cache/unide/chm/<имя>_<время файла>/ при первом
//  обращении, страница открывается браузером системы (xdg-open). Указатель
//  (HH_DISPLAY_INDEX, HH_KEYWORD_LOOKUP) - поиск слова в .hhk CHM; слова
//  нет - стартовая страница.
//
//  F1: rapidq_ref\help\keywords.txt - строки СЛОВО=страница[#метка],
//  тоже из gen_chm.py. Слова нет - открывается указатель CHM с этим словом.
// ---------------------------------------------------------------------------

interface

uses
  Windows, SysUtils, Classes;

// Полный путь к файлу ARel (от папки rapidq_ref), '' - не найден
function RqHelpFind(const ARel: string): string;
// Страница ATopic в CHM ('contents.html', 'custom.html#x'). False - CHM нет
// или окно не открылось, причина - RqHelpLastError
function RqHelpShowTopic(const ATopic: string): Boolean;
// Указатель CHM; AKeyword - слово, которое в нём набрать ('' - без слова)
function RqHelpShowIndex(const AKeyword: string): Boolean;
// F1: страница слова AWord по keywords.txt, иначе указатель с этим словом
function RqHelpKeyword(const AWord: string): Boolean;
// html_doc\contents.html в программе, связанной с .html (браузер)
function RqHelpOpenHtml: Boolean;
// Закрыть окна справки - перед выходом из программы
procedure RqHelpCloseAll;
function RqHelpLastError: string;

// Любой CHM (справка FreeBASIC и другие): страница ATopic ('' - стартовая
// страница файла), указатель со словом, переход по слову указателя
// (HH_KEYWORD_LOOKUP: слово найдено - его страница, нет - указатель с ним)
function ChmShowTopic(const AChm, ATopic: string): Boolean;
function ChmShowIndex(const AChm, AKeyword: string): Boolean;
function ChmKeyword(const AChm, AWord: string): Boolean;

// Руководство FreeBASIC из исходников fbc (fb_ref\gen_fb_chm.py):
// fb_ref\help\freebasic.chm - путь, '' - нет (папка fb_ref ищется там же,
// где rapidq_ref)
function FbRefChm: string;
// Руководство unIDE (unide_ref\gen_unide_chm.py): unide_ref\help\unide.chm,
// '' - нет (папка unide_ref ищется там же, где rapidq_ref)
function UnideRefChm: string;
// Справка по Git (git_ref\gen_git_chm.py): git_ref\help\git.chm, '' - нет
// (папка git_ref ищется там же, где rapidq_ref)
function GitRefChm: string;
// Справка по QEMU (qemu_ref\gen_qemu_chm.py): qemu_ref\help\qemu.chm, ''
// - нет (папка qemu_ref ищется там же, где rapidq_ref)
function QemuRefChm: string;
// Справка по RosBE (rosbe_ref\gen_rosbe_chm.py): rosbe_ref\help\rosbe.chm,
// '' - нет (папка rosbe_ref ищется там же, где rapidq_ref)
function RosbeRefChm: string;
// F1: страница слова по fbkeywords.txt рядом с CHM (слово с суффиксом типа
// и без него), иначе переход по указателю CHM (ChmKeyword)
function FbHelpKeyword(const AChm, AWord: string): Boolean;

implementation

uses
  Forms, OsShell{$IFDEF UNIX}, chmreader, chmsitemap{$ENDIF};

const
  ChmRel = 'help' + PathDelim + 'rapidq.chm';
  KeywordsRel = 'help' + PathDelim + 'keywords.txt';
  HtmlRel = 'html_doc' + PathDelim + 'contents.html';
  HH_DISPLAY_TOPIC = $0000;
  HH_DISPLAY_INDEX = $0002;
  HH_CLOSE_ALL = $0012;
  HH_KEYWORD_LOOKUP = $000D;
  // окно [WINDOWS] main из rapidq.hhp: оглавление, указатель, поиск
  ChmWindow = '>main';

type
  // HH_AKLINK из htmlhelp.h
  THhAkLink = packed record
    cbStruct: Integer;
    fReserved: BOOL;
    pszKeywords: PChar;
    pszUrl: PChar;
    pszMsgText: PChar;
    pszMsgTitle: PChar;
    pszWindow: PChar;
    fIndexOnFail: BOOL;
  end;

  // DWORD_PTR: 4 байта в Win32, 8 в Win64
  THhData = {$IFDEF FPC}PtrUInt{$ELSE}DWORD{$ENDIF};

  THtmlHelpA = function(hwndCaller: HWND; pszFile: PChar; uCommand: UINT;
                        dwData: THhData): HWND; stdcall;

var
  HhLib: HMODULE = 0;
  HtmlHelpProc: THtmlHelpA = nil;
  HelpError: string = '';
  Keywords: TStringList = nil;
  KeywordsFile: string = '';
  KeywordsAge: Integer = -1;

function RqHelpLastError: string;
begin
  Result := HelpError;
end;

// Папки-кандидаты AFolder (rapidq_ref, fb_ref), с разделителем в конце
procedure CandidateDirs(AList: TStrings; const AFolder: string = 'rapidq_ref');
var
  ExeDir, ProjDir: string;
  Found: TSearchRec;
begin
  ExeDir := ExtractFilePath(Application.ExeName);
  AList.Add(ExeDir + AFolder + PathDelim);
  AList.Add(ExtractFilePath(ExcludeTrailingPathDelimiter(ExeDir)) + AFolder +
            PathDelim);
  ProjDir := ExeDir + 'projects' + PathDelim;
  if FindFirst(ProjDir + '*', faDirectory, Found) = 0 then
  try
    repeat
      if ((Found.Attr and faDirectory) <> 0) and (Found.Name <> '.') and
         (Found.Name <> '..') then
        AList.Add(ProjDir + Found.Name + PathDelim + AFolder + PathDelim);
    until FindNext(Found) <> 0;
  finally
    FindClose(Found);
  end;
end;

function RqHelpFind(const ARel: string): string;
var
  Dirs: TStringList;
  DirIdx: Integer;
begin
  Result := '';
  Dirs := TStringList.Create;
  try
    CandidateDirs(Dirs);
    for DirIdx := 0 to Dirs.Count - 1 do
      if FileExists(Dirs[DirIdx] + ARel) then
      begin
        Result := ExpandFileName(Dirs[DirIdx] + ARel);
        Exit;
      end;
    HelpError := 'не найден rapidq_ref\' + ARel + ' (проверено: ' +
                 StringReplace(Trim(Dirs.Text), #13#10, '; ', [rfReplaceAll]) + ')';
  finally
    Dirs.Free;
  end;
end;

{$IFDEF UNIX}
type
  // Распаковка CHM: каждый файл - в папку Dest
  TChmUnpacker = class
    Reader: TChmReader;
    Dest: string;
    Failed: Boolean;
    procedure SaveEntry(Name: String; Offset, UncompressedSize,
      Section: Integer);
  end;

procedure TChmUnpacker.SaveEntry(Name: String; Offset, UncompressedSize,
  Section: Integer);
var
  Data: TMemoryStream;
  Target: string;
begin
  // Папки и служебные файлы CHM (#SYSTEM, $FIftiMain ...) - пропустить
  if (Name = '') or (Name[Length(Name)] = '/') or (Pos('/#', Name) = 1) or
     (Pos('/$', Name) = 1) or (Pos('::', Name) > 0) then
    Exit;
  Data := Reader.GetObject(Name);
  if Data = nil then
    Exit;
  try
    Target := Dest + Copy(Name, 2, MaxInt);
    if not ForceDirectories(ExtractFileDir(Target)) then
    begin
      Failed := True;
      Exit;
    end;
    try
      Data.SaveToFile(Target);
    except
      Failed := True;
    end;
  finally
    Data.Free;
  end;
end;

// Папка распакованного AChm (с '/' на конце); распаковать, если её ещё нет.
// '' - не вышло (HelpError)
function ChmUnpackedDir(const AChm: string; out ADefaultPage: string;
  out AIndexFile: string): string;
var
  CacheBase, InfoFile: string;
  Info: TStringList;
  Unpacker: TChmUnpacker;
  ChmStream: TFileStream;
begin
  Result := '';
  ADefaultPage := '';
  AIndexFile := '';
  if not FileExists(AChm) then
  begin
    HelpError := 'нет файла ' + AChm;
    Exit;
  end;
  CacheBase := GetEnvironmentVariable('XDG_CACHE_HOME');
  if CacheBase = '' then
    CacheBase := GetEnvironmentVariable('HOME') + '/.cache';
  Result := IncludeTrailingPathDelimiter(CacheBase) + 'unide/chm/' +
    ChangeFileExt(ExtractFileName(AChm), '') + '_' +
    IntToStr(FileAge(AChm)) + '/';
  // .unide_chm.txt - распаковано полностью: стартовая страница, указатель
  InfoFile := Result + '.unide_chm.txt';
  Info := TStringList.Create;
  try
    if FileExists(InfoFile) then
    begin
      Info.LoadFromFile(InfoFile);
      ADefaultPage := Info.Values['default'];
      AIndexFile := Info.Values['index'];
      Exit;
    end;
    if not ForceDirectories(Result) then
    begin
      HelpError := 'папка не создаётся: ' + Result;
      Result := '';
      Exit;
    end;
    Unpacker := TChmUnpacker.Create;
    try
      try
        ChmStream := TFileStream.Create(AChm, fmOpenRead or fmShareDenyWrite);
        Unpacker.Reader := TChmReader.Create(ChmStream, True);
        Unpacker.Dest := Result;
        Unpacker.Reader.GetCompleteFileList(Unpacker.SaveEntry, False);
        ADefaultPage := Unpacker.Reader.DefaultPage;
        AIndexFile := Unpacker.Reader.IndexFile;
      except
        on Err: Exception do
        begin
          HelpError := 'CHM не читается: ' + AChm + ' (' + Err.Message + ')';
          Unpacker.Failed := True;
        end;
      end;
      Unpacker.Reader.Free;
      if Unpacker.Failed then
      begin
        if HelpError = '' then
          HelpError := 'CHM не распакован в ' + Result;
        Result := '';
        Exit;
      end;
    finally
      Unpacker.Free;
    end;
    // Указатель: .hhk (имя из #SYSTEM, иначе первый .hhk в корне)
    if (AIndexFile = '') or not FileExists(Result + Copy(AIndexFile, 2, MaxInt))
    then
    begin
      AIndexFile := '';
      Info.Clear;
    end;
    Info.Values['default'] := ADefaultPage;
    Info.Values['index'] := AIndexFile;
    Info.SaveToFile(InfoFile);
  finally
    Info.Free;
  end;
end;

// Слово AKeyword в указателе (.hhk): страница первого совпадения (сначала
// точное, потом начало слова); '' - нет
function ChmIndexLookup(const AHhkFile, AKeyword: string): string;
var
  SiteMap: TChmSiteMap;
  Prefix: string;

  function Walk(AItems: TChmSiteMapItems; AExact: Boolean): string;
  var
    ItemIdx: Integer;
    Item: TChmSiteMapItem;
  begin
    Result := '';
    if AItems = nil then
      Exit;
    for ItemIdx := 0 to AItems.Count - 1 do
    begin
      Item := AItems.Item[ItemIdx];
      if (Item.Local <> '') and
         ((AExact and (CompareText(Item.Name, AKeyword) = 0)) or
          (not AExact and (CompareText(Copy(Item.Name, 1, Length(Prefix)),
            Prefix) = 0))) then
      begin
        Result := Item.Local;
        Exit;
      end;
      Result := Walk(Item.Children, AExact);
      if Result <> '' then
        Exit;
    end;
  end;

begin
  Result := '';
  if (AHhkFile = '') or not FileExists(AHhkFile) or (AKeyword = '') then
    Exit;
  Prefix := AKeyword;
  SiteMap := TChmSiteMap.Create(stIndex);
  try
    try
      SiteMap.LoadFromFile(AHhkFile);
      Result := Walk(SiteMap.Items, True);
      if Result = '' then
        Result := Walk(SiteMap.Items, False);
    except
      Result := '';
    end;
  finally
    SiteMap.Free;
  end;
end;

// Замена HtmlHelpA: APath - 'файл.chm[::/страница][>окно]'
function UnixHtmlHelp(hwndCaller: HWND; pszFile: PChar; uCommand: UINT;
  dwData: THhData): HWND; stdcall;
var
  PathText, ChmFile, Topic, Keyword, Dir, DefaultPage, IndexFile,
    Anchor, Found: string;
  SepPos, WndPos, HashPos: Integer;
begin
  Result := 0;
  if uCommand = HH_CLOSE_ALL then
    Exit;
  PathText := pszFile;
  WndPos := LastDelimiter('>', PathText);
  if WndPos > 0 then
    SetLength(PathText, WndPos - 1);
  SepPos := Pos('::', PathText);
  if SepPos > 0 then
  begin
    ChmFile := Copy(PathText, 1, SepPos - 1);
    Topic := Copy(PathText, SepPos + 2, MaxInt);
  end
  else
  begin
    ChmFile := PathText;
    Topic := '';
  end;
  Dir := ChmUnpackedDir(ChmFile, DefaultPage, IndexFile);
  if Dir = '' then
    Exit;
  Keyword := '';
  if uCommand = HH_DISPLAY_INDEX then
  begin
    if dwData <> 0 then
      Keyword := PChar(dwData);
  end
  else if uCommand = HH_KEYWORD_LOOKUP then
  begin
    if (dwData <> 0) and (THhAkLink(Pointer(dwData)^).pszKeywords <> nil) then
      Keyword := THhAkLink(Pointer(dwData)^).pszKeywords;
  end;
  if Keyword <> '' then
  begin
    Found := ChmIndexLookup(Dir + Copy(IndexFile, 2, MaxInt), Keyword);
    if Found <> '' then
      Topic := Found
    else if uCommand = HH_KEYWORD_LOOKUP then
      Exit;  // вызывающий откроет указатель (стартовую страницу)
  end;
  if Topic = '' then
    Topic := DefaultPage;
  if Topic = '' then
    Topic := '/index.html';
  while (Topic <> '') and (Topic[1] = '/') do
    Delete(Topic, 1, 1);
  Anchor := '';
  HashPos := Pos('#', Topic);
  if HashPos > 0 then
  begin
    Anchor := Copy(Topic, HashPos, MaxInt);
    SetLength(Topic, HashPos - 1);
  end;
  if not FileExists(Dir + Topic) then
  begin
    HelpError := 'в справке нет страницы ' + Topic + ' (' + ChmFile + ')';
    Exit;
  end;
  if ShellOpenIn(0, 'file://' + Dir + Topic + Anchor, Dir) then
    Result := 1
  else
    HelpError := 'браузер не открылся: ' + Dir + Topic;
end;
{$ENDIF}

function LoadHtmlHelp: Boolean;
begin
{$IFDEF UNIX}
  HtmlHelpProc := UnixHtmlHelp;
  Result := True;
  Exit;
{$ENDIF}
  if not Assigned(HtmlHelpProc) then
  begin
    if HhLib = 0 then
      HhLib := LoadLibrary('hhctrl.ocx');
    if HhLib <> 0 then
      @HtmlHelpProc := GetProcAddress(HhLib, 'HtmlHelpA');
  end;
  Result := Assigned(HtmlHelpProc);
  if not Result then
    HelpError := 'нет hhctrl.ocx (просмотр CHM в Windows)';
end;

function RqHelpShowTopic(const ATopic: string): Boolean;
var
  ChmFile: string;
begin
  Result := False;
  ChmFile := RqHelpFind(ChmRel);
  if (ChmFile = '') or not LoadHtmlHelp then
    Exit;
  Result := HtmlHelpProc(0, PChar(ChmFile + '::/' + ATopic + ChmWindow),
                         HH_DISPLAY_TOPIC, 0) <> 0;
  if not Result then
    HelpError := 'окно справки не открылось: ' + ChmFile + '::/' + ATopic;
end;

function RqHelpShowIndex(const AKeyword: string): Boolean;
var
  ChmFile: string;
begin
  Result := False;
  ChmFile := RqHelpFind(ChmRel);
  if (ChmFile = '') or not LoadHtmlHelp then
    Exit;
  Result := HtmlHelpProc(0, PChar(ChmFile + ChmWindow), HH_DISPLAY_INDEX,
                         THhData(PChar(AKeyword))) <> 0;
  if not Result then
    HelpError := 'указатель справки не открылся: ' + ChmFile;
end;

// keywords.txt - заново, если файл другой или изменился
procedure LoadKeywords;
var
  FileName: string;
  Age: Integer;
begin
  FileName := RqHelpFind(KeywordsRel);
  if FileName = '' then
  begin
    FreeAndNil(Keywords);
    KeywordsFile := '';
    Exit;
  end;
  Age := FileAge(FileName);
  if (Keywords <> nil) and (CompareText(FileName, KeywordsFile) = 0) and
     (Age = KeywordsAge) then
    Exit;
  if Keywords = nil then
    Keywords := TStringList.Create;
  Keywords.LoadFromFile(FileName);
  KeywordsFile := FileName;
  KeywordsAge := Age;
end;

function RqHelpKeyword(const AWord: string): Boolean;
var
  Topic: string;
begin
  Topic := '';
  if AWord <> '' then
  begin
    LoadKeywords;
    if Keywords <> nil then
      Topic := Keywords.Values[UpperCase(AWord)];
  end;
  if Topic <> '' then
    Result := RqHelpShowTopic(Topic)
  else
    Result := RqHelpShowIndex(AWord);
end;

function RqHelpOpenHtml: Boolean;
var
  HtmlFile: string;
begin
  Result := False;
  HtmlFile := RqHelpFind(HtmlRel);
  if HtmlFile = '' then
    Exit;
  Result := ShellOpenIn(0, HtmlFile, ExtractFilePath(HtmlFile));
  if not Result then
    HelpError := 'не открылся ' + HtmlFile;
end;

function ChmShowTopic(const AChm, ATopic: string): Boolean;
var
  Target: string;
begin
  Result := False;
  if not LoadHtmlHelp then
    Exit;
  Target := AChm;
  if ATopic <> '' then
    Target := Target + '::/' + ATopic;
  Result := HtmlHelpProc(0, PChar(Target), HH_DISPLAY_TOPIC, 0) <> 0;
  if not Result then
    HelpError := 'окно справки не открылось: ' + Target;
end;

function ChmShowIndex(const AChm, AKeyword: string): Boolean;
begin
  Result := False;
  if not LoadHtmlHelp then
    Exit;
  Result := HtmlHelpProc(0, PChar(AChm), HH_DISPLAY_INDEX,
                         THhData(PChar(AKeyword))) <> 0;
  if not Result then
    HelpError := 'указатель справки не открылся: ' + AChm;
end;

function ChmKeyword(const AChm, AWord: string): Boolean;
var
  Link: THhAkLink;
  HelpWnd: HWND;
begin
  Result := False;
  if not LoadHtmlHelp then
    Exit;
  if AWord = '' then
  begin
    Result := ChmShowTopic(AChm, '');
    Exit;
  end;
  // Поиск по указателю работает в открытом окне справки - сначала оно
  HelpWnd := HtmlHelpProc(0, PChar(AChm), HH_DISPLAY_TOPIC, 0);
  if HelpWnd = 0 then
  begin
    HelpError := 'окно справки не открылось: ' + AChm;
    Exit;
  end;
  FillChar(Link, SizeOf(Link), 0);
  Link.cbStruct := SizeOf(Link);
  Link.pszKeywords := PChar(AWord);
  Link.fIndexOnFail := True;
  Result := HtmlHelpProc(0, PChar(AChm), HH_KEYWORD_LOOKUP,
                         THhData(@Link)) <> 0;
  if not Result then
    // Указатель не открылся по слову - хотя бы указатель с ним
    Result := ChmShowIndex(AChm, AWord);
end;

function FbRefChm: string;
var
  Dirs: TStringList;
  DirIdx: Integer;
begin
  Result := '';
  Dirs := TStringList.Create;
  try
    CandidateDirs(Dirs, 'fb_ref');
    for DirIdx := 0 to Dirs.Count - 1 do
      if FileExists(Dirs[DirIdx] + 'help' + PathDelim + 'freebasic.chm') then
      begin
        Result := ExpandFileName(Dirs[DirIdx] + 'help' + PathDelim + 'freebasic.chm');
        Exit;
      end;
  finally
    Dirs.Free;
  end;
end;

function UnideRefChm: string;
var
  Dirs: TStringList;
  DirIdx: Integer;
begin
  Result := '';
  Dirs := TStringList.Create;
  try
    CandidateDirs(Dirs, 'unide_ref');
    for DirIdx := 0 to Dirs.Count - 1 do
      if FileExists(Dirs[DirIdx] + 'help' + PathDelim + 'unide.chm') then
      begin
        Result := ExpandFileName(Dirs[DirIdx] + 'help' + PathDelim + 'unide.chm');
        Exit;
      end;
    HelpError := 'не найден unide_ref\help\unide.chm (проверено: ' +
                 StringReplace(Trim(Dirs.Text), #13#10, '; ', [rfReplaceAll]) + ')';
  finally
    Dirs.Free;
  end;
end;

function GitRefChm: string;
var
  Dirs: TStringList;
  DirIdx: Integer;
begin
  Result := '';
  Dirs := TStringList.Create;
  try
    CandidateDirs(Dirs, 'git_ref');
    for DirIdx := 0 to Dirs.Count - 1 do
      if FileExists(Dirs[DirIdx] + 'help' + PathDelim + 'git.chm') then
      begin
        Result := ExpandFileName(Dirs[DirIdx] + 'help' + PathDelim + 'git.chm');
        Exit;
      end;
    HelpError := 'не найден git_ref\help\git.chm (проверено: ' +
                 StringReplace(Trim(Dirs.Text), #13#10, '; ', [rfReplaceAll]) + ')';
  finally
    Dirs.Free;
  end;
end;

function QemuRefChm: string;
var
  Dirs: TStringList;
  DirIdx: Integer;
begin
  Result := '';
  Dirs := TStringList.Create;
  try
    CandidateDirs(Dirs, 'qemu_ref');
    for DirIdx := 0 to Dirs.Count - 1 do
      if FileExists(Dirs[DirIdx] + 'help' + PathDelim + 'qemu.chm') then
      begin
        Result := ExpandFileName(Dirs[DirIdx] + 'help' + PathDelim + 'qemu.chm');
        Exit;
      end;
    HelpError := 'не найден qemu_ref\help\qemu.chm (проверено: ' +
                 StringReplace(Trim(Dirs.Text), #13#10, '; ', [rfReplaceAll]) + ')';
  finally
    Dirs.Free;
  end;
end;

function RosbeRefChm: string;
var
  Dirs: TStringList;
  DirIdx: Integer;
begin
  Result := '';
  Dirs := TStringList.Create;
  try
    CandidateDirs(Dirs, 'rosbe_ref');
    for DirIdx := 0 to Dirs.Count - 1 do
      if FileExists(Dirs[DirIdx] + 'help' + PathDelim + 'rosbe.chm') then
      begin
        Result := ExpandFileName(Dirs[DirIdx] + 'help' + PathDelim + 'rosbe.chm');
        Exit;
      end;
    HelpError := 'не найден rosbe_ref\help\rosbe.chm (проверено: ' +
                 StringReplace(Trim(Dirs.Text), #13#10, '; ', [rfReplaceAll]) + ')';
  finally
    Dirs.Free;
  end;
end;

var
  FbKeywords: TStringList = nil;
  FbKeywordsFile: string = '';
  FbKeywordsAge: Integer = -1;

function FbHelpKeyword(const AChm, AWord: string): Boolean;
var
  KeyFile, Topic, Bare: string;
  Age: Integer;
begin
  Topic := '';
  KeyFile := ExtractFilePath(AChm) + 'fbkeywords.txt';
  if (AWord <> '') and FileExists(KeyFile) then
  begin
    Age := FileAge(KeyFile);
    if (FbKeywords = nil) or (CompareText(KeyFile, FbKeywordsFile) <> 0) or
       (Age <> FbKeywordsAge) then
    begin
      if FbKeywords = nil then
        FbKeywords := TStringList.Create;
      FbKeywords.LoadFromFile(KeyFile);
      FbKeywordsFile := KeyFile;
      FbKeywordsAge := Age;
    end;
    Topic := FbKeywords.Values[UpperCase(AWord)];
    // Left$ - страница Left: суффикс типа в списке не пишется
    if (Topic = '') and (Length(AWord) > 1) and
       (AWord[Length(AWord)] in ['$', '%', '&', '!', '#']) then
    begin
      Bare := Copy(AWord, 1, Length(AWord) - 1);
      Topic := FbKeywords.Values[UpperCase(Bare)];
    end;
  end;
  if Topic <> '' then
    Result := ChmShowTopic(AChm, Topic)
  else
    Result := ChmKeyword(AChm, AWord);
end;

procedure RqHelpCloseAll;
begin
  // Окна справки - до выхода: потоки hhctrl.ocx при выгрузке программы с
  // открытым окном могут уронить её. Библиотеку не выгружаем.
  if Assigned(HtmlHelpProc) then
    HtmlHelpProc(0, nil, HH_CLOSE_ALL, 0);
end;

initialization

finalization
  FreeAndNil(Keywords);
  FreeAndNil(FbKeywords);

end.
