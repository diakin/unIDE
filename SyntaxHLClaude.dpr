program SyntaxHLClaude;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Unit2 in 'Unit2.pas' {Form2},
  DlgAskDisk in 'DlgAskDisk.pas' {DlgAskDisk},
  DlgChooseList in 'DlgChooseList.pas' {DlgChooseList},
  DlgFifDisk in 'DlgFifDisk.pas' {DlgFifDisk},
  DlgPickFolder in 'DlgPickFolder.pas' {DlgPickFolder},
  FolderDlg in 'FolderDlg.pas',
  DlgProgress in 'DlgProgress.pas' {DlgProgress},
  DlgMatchList in 'DlgMatchList.pas' {DlgMatchList},
  DlgListWnd in 'DlgListWnd.pas' {DlgListWnd},
  DlgHotFolders in 'DlgHotFolders.pas' {DlgHotFolders},
  DlgDelPrj in 'DlgDelPrj.pas' {DlgDelPrj},
  DlgWinList in 'DlgWinList.pas' {DlgWinList},
  DlgNewPrj in 'DlgNewPrj.pas' {DlgNewPrj},
  DlgRelease in 'DlgRelease.pas' {DlgRelease},
  DlgWatch in 'DlgWatch.pas' {DlgWatch},
  DlgArdBoards in 'DlgArdBoards.pas' {DlgArdBoards},
  DlgArdLibs in 'DlgArdLibs.pas' {DlgArdLibs},
  DlgArdCli in 'DlgArdCli.pas' {DlgArdCli},
  ArduinoCli in 'ArduinoCli.pas',
  ArduinoHw in 'ArduinoHw.pas',
  ArduinoPorts in 'ArduinoPorts.pas',
  EnvOptions in 'EnvOptions.pas',
  CodeInsight in 'CodeInsight.pas',
  DlgArdSerial in 'DlgArdSerial.pas' {DlgArdSerial},
  ReleaseBuild in 'ReleaseBuild.pas',
  ObjParse in 'ObjParse.pas',
  PrjStore in 'PrjStore.pas',
  RqComponents in 'RqComponents.pas',
  RqDesign in 'RqDesign.pas',
  RqHelp in 'RqHelp.pas',
  IniTidy in 'IniTidy.pas',
  HangWatch in 'HangWatch.pas',
  WndWatch in 'WndWatch.pas',
  DbgEngine in 'DbgEngine.pas',
  DbgSymbols in 'DbgSymbols.pas',
  RqDbgInstr in 'RqDbgInstr.pas',
  TextMerge in 'TextMerge.pas',
  FileSearch in 'FileSearch.pas',
  DelphiProj in 'DelphiProj.pas',
  ClrScheme in 'ClrScheme.pas',
  RqToFb in 'RqLcl\tofb\RqToFb.pas',
  UiScroll in 'UiScroll.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
