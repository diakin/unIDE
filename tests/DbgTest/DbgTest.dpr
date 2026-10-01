program DbgTest;

// Проверочный проект для отладчика SyntaxHLClaude: точки останова, шаги
// F7/F8, Run to cursor (F4), окно Watch (Ctrl+F5). Порядок проверки - в
// начале DbgTestMain.pas.

uses
  Forms,
  DbgTestMain in 'DbgTestMain.pas' {FormDbgTest};

begin
  Application.Initialize;
  Application.CreateForm(TFormDbgTest, FormDbgTest);
  Application.Run;
end.
