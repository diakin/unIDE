program EdViewDemo;

// Проверка окна TEdView (EdView.pas) без unIDE: Lazarus / Free Pascal, LCL.
// Файл, схема, место каретки, выделение и клавиши - из параметров; окно
// показывается, снимок экрана делает тот, кто запускает (под Linux - Xvfb
// и import). Каретка и окно после каждой клавиши - в stdout.
//
//   EdViewDemo <файл cp1251> <папка схем> <ключ схемы> <строка> <колонка>
//     <выделить строк> <ширина табуляции> [клавиши]
//   клавиши: U D L R - стрелки, P p - PgDn / PgUp, H E - Home / End,
//     T B - Ctrl+Home / Ctrl+End, S - Ctrl+Down
//
// Сборка под Linux (gtk2), из этой папки:
//   fpc -Mdelphi -FcCP1251 -dLCL -dLCLgtk2 -Fu<lazarus>/lcl/units/x86_64-linux/gtk2
//     -Fu<lazarus>/lcl/units/x86_64-linux
//     -Fu<lazarus>/components/lazutils/lib/x86_64-linux -Fu../.. EdViewDemo.lpr

{$MODE DELPHI}

uses
  Interfaces, LCLType, Forms, Graphics, Controls, SysUtils, Classes, LConvEncoding,
  EdBuffer, EdView, EdScheme, ClrScheme, SchemeFiles;

var
  Demo_View: TEdView;

type
  TViewAccess = class(TEdView);

  TDemo = class
    Form: TForm;
    View: TEdView;
    Buffer: TEdBuffer;
    Highlighter: TEdSchemeHighlighter;
    procedure Run;
    procedure AppException(Sender: TObject; E: Exception);
  end;

procedure TDemo.AppException(Sender: TObject; E: Exception);
begin
  Writeln(StdErr, 'EXCEPTION: ', E.ClassName, ': ', E.Message);
  DumpExceptionBackTrace(StdErr);
  Halt(3);
end;

procedure RunKeys(const AKeys: string);
var
  KeyIdx: Integer;
  Key: Word;
  Shift: TShiftState;
begin
  if Demo_View = nil then
    Exit;
  for KeyIdx := 1 to Length(AKeys) do
  begin
    Shift := [];
    case AKeys[KeyIdx] of
      'U': Key := VK_UP;
      'D': Key := VK_DOWN;
      'L': Key := VK_LEFT;
      'R': Key := VK_RIGHT;
      'P': Key := VK_NEXT;
      'p': Key := VK_PRIOR;
      'H': Key := VK_HOME;
      'E': Key := VK_END;
      'T': begin Key := VK_HOME; Shift := [ssCtrl]; end;
      'B': begin Key := VK_END; Shift := [ssCtrl]; end;
      'S': begin Key := VK_DOWN; Shift := [ssCtrl]; end;
    else
      Continue;
    end;
    TViewAccess(Demo_View).KeyDown(Key, Shift);
    Writeln(AKeys[KeyIdx], ' caret ', Demo_View.CaretRow + 1, ':', Demo_View.CaretCol + 1,
      ' top ', Demo_View.TopRow + 1, ' left ', Demo_View.LeftCol);
    Flush(Output);
  end;
end;

procedure TDemo.Run;
var
  Raw: TStringList;
  Scheme: TClrScheme;
  CaretRow, CaretCol, SelRows: Integer;
begin
  Raw := TStringList.Create;
  try
    Raw.LoadFromFile(ParamStr(1));
    Buffer := TEdBuffer.Create;
    Buffer.SetText(UTF8Decode(CP1251ToUTF8(Raw.Text)));
  finally
    Raw.Free;
  end;
  // Схема .clr - в cp1251, разбор сравнивает со строками модуля в cp1251:
  // на время чтения кодировка строк по умолчанию - 1251 (под Linux - UTF-8)
  DefaultSystemCodePage := 1251;
  Scheme := SchemeLoadFromDir(ParamStr(2), ParamStr(3), '', clBlack, clWhite);
  DefaultSystemCodePage := CP_UTF8;
  Highlighter := TEdSchemeHighlighter.Create(Buffer, Scheme, clBlack, clWhite);
  Form := TForm.CreateNew(nil);
  Form.Caption := 'EdView demo';
  Form.SetBounds(0, 0, 900, 560);
  View := TEdView.Create(Form);
  Demo_View := View;
  View.Parent := Form;
  View.Align := alClient;
  View.Font.Name := 'DejaVu Sans Mono';
  View.Font.Size := 10;
  View.TabSize := StrToIntDef(ParamStr(7), 8);
  View.TextColor := Highlighter.TextColor;
  View.BackColor := Highlighter.BackColor;
  View.GutterColor := $00E1F2FD;
  View.GutterTextColor := $00606060;
  View.GutterCurColor := $00C0E0F0;
  View.CurLineColor := $00E8F8FF;
  View.OnLineRuns := Highlighter.LineRuns;
  View.Buffer := Buffer;
  View.RefreshAll;
  Form.Show;
  View.SetFocus;
  CaretRow := StrToIntDef(ParamStr(4), 1) - 1;
  CaretCol := StrToIntDef(ParamStr(5), 1) - 1;
  SelRows := StrToIntDef(ParamStr(6), 0);
  if SelRows > 0 then
  begin
    View.CaretTo(CaretRow, CaretCol);
    View.SetSelection(CaretRow, CaretCol);
    View.CaretTo(CaretRow + SelRows, 3);
  end
  else
    View.CaretTo(CaretRow, CaretCol);
  RunKeys(ParamStr(8));
end;

var
  Demo: TDemo;
begin
  Application.Initialize;
  Demo := TDemo.Create;
  Application.OnException := Demo.AppException;
  Demo.Run;
  Application.Run;
end.
