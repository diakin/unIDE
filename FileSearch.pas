unit FileSearch;

// ---------------------------------------------------------------------------
//  Find In Files: файлы на диске
//
//  Маски файлов, чтение файла для поиска (большие и двоичные - мимо) и
//  обход папки с вложенными. Строку состояния и Esc ведёт вызывающий -
//  через AProgress. Поиск в тексте и список результатов - в Unit1.
//
//  Вынесено из Unit1 без изменения поведения. Без VCL.
// ---------------------------------------------------------------------------

interface

uses
  SysUtils, Classes, Masks;

const
  FifMaxFileSize = 32 * 1024 * 1024;
  FifMaxHits = 50000;   // дальше грид результатов становится бесполезен

type
  // Ход обхода: папка, которую сейчас просматривают, и сколько файлов
  // найдено; ACancel := True - прервать
  TFifProgress = procedure(const ADir: string; ACount: Integer;
                           var ACancel: Boolean) of object;

// Подходит ли имя под одну из масок через ';' (*.pas;*.dpr)
function FifMatchMasks(const AName, AMasks: string): Boolean;
// Текст файла с диска. False - файл не читается, слишком большой или
// двоичный (нулевой байт в первых 4 КБ).
function FifReadFile(const AFile: string; var AText: string): Boolean;
// Файлы папки ADir (с '\' на конце) по маскам, с вложенными папками при
// ASubDirs. Служебные папки (.git, __history, __recovery) пропускаются.
procedure FifCollectFiles(const ADir, AMasks: string; ASubDirs: Boolean;
                          AList: TStrings; var ACancel: Boolean;
                          AProgress: TFifProgress);

implementation

// Подходит ли имя под одну из масок через ';' (*.pas;*.dpr)
function FifMatchMasks(const AName, AMasks: string): Boolean;
var
  Rest, M: string;
  P: Integer;
begin
  Result := False;
  Rest := AMasks;
  while Rest <> '' do
  begin
    P := Pos(';', Rest);
    if P > 0 then
    begin
      M := Trim(Copy(Rest, 1, P - 1));
      Rest := Copy(Rest, P + 1, MaxInt);
    end
    else
    begin
      M := Trim(Rest);
      Rest := '';
    end;
    if (M <> '') and MatchesMask(AName, M) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

// Текст файла с диска. False - файл не читается, слишком большой или
// двоичный.
function FifReadFile(const AFile: string; var AText: string): Boolean;
var
  F: TFileStream;
  Size, I, Lim: Integer;
begin
  Result := False;
  AText := '';
  try
    F := TFileStream.Create(AFile, fmOpenRead or fmShareDenyNone);
    try
      Size := F.Size;
      if Size > FifMaxFileSize then
        Exit;
      SetLength(AText, Size);
      if Size > 0 then
        F.ReadBuffer(AText[1], Size);
    finally
      F.Free;
    end;
  except
    Exit;
  end;
  Lim := Length(AText);
  if Lim > 4096 then
    Lim := 4096;
  for I := 1 to Lim do
    if AText[I] = #0 then
    begin
      AText := '';
      Exit;
    end;
  Result := True;
end;

// Файлы папки по маскам, при ASubDirs - и во вложенных. Служебные папки
// (с точки в начале: .git, .svn; __history, __recovery - копии Delphi)
// пропускаются. ADir - с разделителем в конце.
procedure FifCollectFiles(const ADir, AMasks: string; ASubDirs: Boolean;
                          AList: TStrings; var ACancel: Boolean;
                          AProgress: TFifProgress);
var
  SR: TSearchRec;
  Subs: TStringList;
  I: Integer;
begin
  if ACancel then
    Exit;
  // Перед папкой - спросить, не прервали ли (Esc)
  if Assigned(AProgress) then
    AProgress(ADir, AList.Count, ACancel);
  if ACancel then
    Exit;

  Subs := TStringList.Create;
  try
    if FindFirst(ADir + '*', faAnyFile, SR) = 0 then
    try
      repeat
        if (SR.Name = '.') or (SR.Name = '..') then
          Continue;
        if (SR.Attr and faDirectory) <> 0 then
        begin
          if ASubDirs and (SR.Name[1] <> '.') and
             (CompareText(SR.Name, '__history') <> 0) and
             (CompareText(SR.Name, '__recovery') <> 0) then
            Subs.Add(ADir + SR.Name + '\');
        end
        else if FifMatchMasks(SR.Name, AMasks) then
          AList.Add(ADir + SR.Name);
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;

    // После папки - сколько найдено (строка состояния у вызывающего)
    if Assigned(AProgress) then
      AProgress(ADir, AList.Count, ACancel);
    if ACancel then
      Exit;

    for I := 0 to Subs.Count - 1 do
    begin
      FifCollectFiles(Subs[I], AMasks, ASubDirs, AList, ACancel, AProgress);
      if ACancel then
        Exit;
    end;
  finally
    Subs.Free;
  end;
end;

end.
