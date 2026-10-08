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
  // окно [WINDOWS] main из rapidq.hhp: оглавление, указатель, поиск
  ChmWindow = '>main';

type
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

// Папки-кандидаты rapidq_ref, с "\" в конце
procedure CandidateDirs(AList: TStrings);
var
  ExeDir, ProjDir: string;
  Found: TSearchRec;
begin
  ExeDir := ExtractFilePath(Application.ExeName);
  AList.Add(ExeDir + 'rapidq_ref\');
  AList.Add(ExtractFilePath(ExcludeTrailingPathDelimiter(ExeDir)) + 'rapidq_ref\');
  ProjDir := ExeDir + 'projects\';
  if FindFirst(ProjDir + '*', faDirectory, Found) = 0 then
  try
    repeat
      if ((Found.Attr and faDirectory) <> 0) and (Found.Name <> '.') and
         (Found.Name <> '..') then
        AList.Add(ProjDir + Found.Name + '\rapidq_ref\');
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

end.
