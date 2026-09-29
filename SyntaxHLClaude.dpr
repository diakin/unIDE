program SyntaxHLClaude;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Unit2 in 'Unit2.pas' {Form2},
  DlgAskDisk in 'DlgAskDisk.pas' {DlgAskDisk},
  DlgChooseList in 'DlgChooseList.pas' {DlgChooseList},
  DlgFifDisk in 'DlgFifDisk.pas' {DlgFifDisk},
  DlgPickFolder in 'DlgPickFolder.pas' {DlgPickFolder},
  DlgProgress in 'DlgProgress.pas' {DlgProgress},
  DlgMatchList in 'DlgMatchList.pas' {DlgMatchList},
  DlgListWnd in 'DlgListWnd.pas' {DlgListWnd},
  DlgHotFolders in 'DlgHotFolders.pas' {DlgHotFolders},
  DlgDelPrj in 'DlgDelPrj.pas' {DlgDelPrj},
  DlgWinList in 'DlgWinList.pas' {DlgWinList},
  DlgNewPrj in 'DlgNewPrj.pas' {DlgNewPrj},
  DlgRelease in 'DlgRelease.pas' {DlgRelease},
  ReleaseBuild in 'ReleaseBuild.pas',
  ObjParse in 'ObjParse.pas',
  HangWatch in 'HangWatch.pas',
  TextMerge in 'TextMerge.pas',
  FileSearch in 'FileSearch.pas',
  DelphiProj in 'DelphiProj.pas',
  ClrScheme in 'ClrScheme.pas',
  UiScroll in 'UiScroll.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
