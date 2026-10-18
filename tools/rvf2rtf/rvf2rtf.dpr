program rvf2rtf;

// ---------------------------------------------------------------------------
//  rvf2rtf - RVF (TRichView) -> RTF для просмотра по формату в unIDE
//  (FmtView.pas, TRtfPreview.ShowRvfFile).
//
//  rvf2rtf.exe "файл.rvf" "файл.rtf"
//  Код выхода: 0 - готово, 1 - не те параметры, 2 - RVF не прочитан,
//  3 - RTF не записан.
//
//  Собирается в Delphi 7 с установленным TRichView (папка его исходников
//  или .dcu - в Library path). unIDE этот помощник только запускает:
//  сборка самого unIDE от TRichView не зависит. Готовый rvf2rtf.exe
//  положить рядом с exe unIDE или в его папку tools.
//
//  Окно не показывается. Форма-владелец (CreateNew, без .dfm) нужна, чтобы
//  у TRichView было окно: документ форматируется по канве.
// ---------------------------------------------------------------------------

uses
  Windows, SysUtils, Classes, Forms, Controls,
  jpeg,      // картинки JPEG в документе
  RVStyle, RichView;

var
  HostForm: TForm;
  Viewer: TRichView;
  ViewerStyle: TRVStyle;
  SourceFile, TargetFile: string;
begin
  ExitCode := 1;
  if ParamCount >= 2 then
  begin
    // Дальше любая ошибка до записи RTF - "RVF не прочитан"
    ExitCode := 2;
    SourceFile := ExpandFileName(ParamStr(1));
    TargetFile := ExpandFileName(ParamStr(2));
    Application.Initialize;
    HostForm := TForm.CreateNew(nil);
    try
      try
        ViewerStyle := TRVStyle.Create(HostForm);
        Viewer := TRichView.Create(HostForm);
        Viewer.Visible := False;
        Viewer.Parent := HostForm;
        Viewer.Style := ViewerStyle;
        // Стили текста и абзацев - из файла (RVF, записанный со стилями)
        Viewer.RVFTextStylesReadMode := rvf_sInsertMerge;
        Viewer.RVFParaStylesReadMode := rvf_sInsertMerge;
        // Незнакомые картинки и элементы - пропустить, а не бросать файл
        Viewer.RVFOptions := Viewer.RVFOptions + [rvfoIgnoreUnknownPicFmt,
          rvfoIgnoreUnknownCtrls, rvfoConvUnknownStylesToZero, rvfoLoadBack];
        ExitCode := 2;
        if Viewer.LoadRVF(SourceFile) then
        begin
          try
            Viewer.Format;
          except
            // форматирование для записи RTF не обязательно
          end;
          ExitCode := 3;
          if Viewer.SaveRTF(TargetFile, False) then
            ExitCode := 0;
        end;
      except
        // Окно с ошибкой не показываем: unIDE ждёт код выхода
        if ExitCode = 0 then
          ExitCode := 3;
      end;
    finally
      HostForm.Free;
    end;
  end;
end.
