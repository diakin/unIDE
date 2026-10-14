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
// F1: страница слова по fbkeywords.txt рядом с CHM (слово с суффиксом типа
// и без него), иначе переход по указателю CHM (ChmKeyword)
function FbHelpKeyword(const AChm, AWord: string): Boolean;

implementation

uses
  Forms, ShellAPI;

const
  ChmRel = 'help\rapidq.chm';
  KeywordsRel = 'help\keywords.txt';
  HtmlRel = 'html_doc\contents.html';
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

  THtmlHelpA = function(hwndCaller: HWND; pszFile: PChar; uCommand: UINT;
                        dwData: DWORD): HWND; stdcall;

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

// Папки-кандидаты AFolder (rapidq_ref, fb_ref), с "\" в конце
procedure CandidateDirs(AList: TStrings; const AFolder: string = 'rapidq_ref');
var
  ExeDir, ProjDir: string;
  Found: TSearchRec;
begin
  ExeDir := ExtractFilePath(Application.ExeName);
  AList.Add(ExeDir + AFolder + '\');
  AList.Add(ExtractFilePath(ExcludeTrailingPathDelimiter(ExeDir)) + AFolder +
            '\');
  ProjDir := ExeDir + 'projects\';
  if FindFirst(ProjDir + '*', faDirectory, Found) = 0 then
  try
    repeat
      if ((Found.Attr and faDirectory) <> 0) and (Found.Name <> '.') and
         (Found.Name <> '..') then
        AList.Add(ProjDir + Found.Name + '\' + AFolder + '\');
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

function LoadHtmlHelp: Boolean;
begin
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
                         DWORD(PChar(AKeyword))) <> 0;
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
  Result := ShellExecute(0, 'open', PChar(HtmlFile), nil,
                         PChar(ExtractFilePath(HtmlFile)), SW_SHOWNORMAL) > 32;
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
                         DWORD(PChar(AKeyword))) <> 0;
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
                         DWORD(@Link)) <> 0;
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
      if FileExists(Dirs[DirIdx] + 'help\freebasic.chm') then
      begin
        Result := ExpandFileName(Dirs[DirIdx] + 'help\freebasic.chm');
        Exit;
      end;
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
