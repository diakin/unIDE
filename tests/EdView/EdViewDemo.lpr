program EdViewDemo;

// Проверка окна TEdView (EdView.pas) без unIDE: Lazarus / Free Pascal, LCL.
// Файл, схема, место каретки, выделение и сценарий клавиш и мыши - из
// параметров; окно показывается, снимок экрана делает тот, кто запускает
// (под Linux - Xvfb и import). После каждого шага сценария - каретка и
// окно в stdout; show - строки текста, выделение, откат.
//
//   EdViewDemo <файл cp1251> <папка схем> <ключ схемы> <строка> <колонка>
//     <выделить строк> <ширина табуляции> ['сценарий']
//   сценарий - см. RunKeys (например 't:abc cZ show')
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

procedure SendKey(AKey: Word; AShift: TShiftState);
begin
  TViewAccess(Demo_View).KeyDown(AKey, AShift);
end;

// Сценарий: слова через пробел.
//   U D L R P p H E T B S - клавиши перемещения (S - Ctrl+Down),
//   sU sD sL sR sH sE - с Shift, cL cR - Ctrl+стрелки, csR - Ctrl+Shift+Right
//   t:текст - набор (подчёркивание = пробел), BS DEL cBS cDEL ENT TAB sTAB INS
//   cA cC cX cV cZ cY csZ aBS - сочетания
//   m:X,Y - щелчок, ms:X,Y - Shift+щелчок, md:X,Y - двойной, mt:X,Y - тройной,
//   drag:X1,Y1,X2,Y2 - протяжка
//   show - строки 1..12 и каретка в stdout
procedure RunKeys(const AKeys: string);
var
  Words: TStringList;
  WordIdx, CharIdx, X1, Y1, X2, Y2: Integer;
  Cmd, Arg: string;
  Utf: TUTF8Char;
  Parts: TStringList;
  RowIdx: Integer;
begin
  if Demo_View = nil then
    Exit;
  Words := TStringList.Create;
  Parts := TStringList.Create;
  try
    Words.Delimiter := ' ';
    Words.StrictDelimiter := True;
    Words.DelimitedText := AKeys;
    for WordIdx := 0 to Words.Count - 1 do
    begin
      Cmd := Words[WordIdx];
      Arg := '';
      if Pos(':', Cmd) > 0 then
      begin
        Arg := Copy(Cmd, Pos(':', Cmd) + 1, MaxInt);
        Cmd := Copy(Cmd, 1, Pos(':', Cmd) - 1);
      end;
      Parts.CommaText := Arg;
      if Cmd = 'U' then SendKey(VK_UP, [])
      else if Cmd = 'D' then SendKey(VK_DOWN, [])
      else if Cmd = 'L' then SendKey(VK_LEFT, [])
      else if Cmd = 'R' then SendKey(VK_RIGHT, [])
      else if Cmd = 'P' then SendKey(VK_NEXT, [])
      else if Cmd = 'p' then SendKey(VK_PRIOR, [])
      else if Cmd = 'H' then SendKey(VK_HOME, [])
      else if Cmd = 'E' then SendKey(VK_END, [])
      else if Cmd = 'T' then SendKey(VK_HOME, [ssCtrl])
      else if Cmd = 'B' then SendKey(VK_END, [ssCtrl])
      else if Cmd = 'S' then SendKey(VK_DOWN, [ssCtrl])
      else if Cmd = 'sU' then SendKey(VK_UP, [ssShift])
      else if Cmd = 'sD' then SendKey(VK_DOWN, [ssShift])
      else if Cmd = 'sL' then SendKey(VK_LEFT, [ssShift])
      else if Cmd = 'sR' then SendKey(VK_RIGHT, [ssShift])
      else if Cmd = 'sH' then SendKey(VK_HOME, [ssShift])
      else if Cmd = 'sE' then SendKey(VK_END, [ssShift])
      else if Cmd = 'cL' then SendKey(VK_LEFT, [ssCtrl])
      else if Cmd = 'cR' then SendKey(VK_RIGHT, [ssCtrl])
      else if Cmd = 'csR' then SendKey(VK_RIGHT, [ssCtrl, ssShift])
      else if Cmd = 'BS' then SendKey(VK_BACK, [])
      else if Cmd = 'cBS' then SendKey(VK_BACK, [ssCtrl])
      else if Cmd = 'aBS' then SendKey(VK_BACK, [ssAlt])
      else if Cmd = 'DEL' then SendKey(VK_DELETE, [])
      else if Cmd = 'cDEL' then SendKey(VK_DELETE, [ssCtrl])
      else if Cmd = 'ENT' then SendKey(VK_RETURN, [])
      else if Cmd = 'TAB' then SendKey(VK_TAB, [])
      else if Cmd = 'sTAB' then SendKey(VK_TAB, [ssShift])
      else if Cmd = 'INS' then SendKey(VK_INSERT, [])
      else if Cmd = 'cA' then SendKey(Ord('A'), [ssCtrl])
      else if Cmd = 'cC' then SendKey(Ord('C'), [ssCtrl])
      else if Cmd = 'cX' then SendKey(Ord('X'), [ssCtrl])
      else if Cmd = 'cV' then SendKey(Ord('V'), [ssCtrl])
      else if Cmd = 'cZ' then SendKey(Ord('Z'), [ssCtrl])
      else if Cmd = 'cY' then SendKey(Ord('Y'), [ssCtrl])
      else if Cmd = 'csZ' then SendKey(Ord('Z'), [ssCtrl, ssShift])
      else if Cmd = 't' then
      begin
        Arg := StringReplace(Arg, '_', ' ', [rfReplaceAll]);
        CharIdx := 1;
        while CharIdx <= Length(Arg) do
        begin
          // символ UTF-8 целиком
          Utf := Arg[CharIdx];
          Inc(CharIdx);
          while (CharIdx <= Length(Arg)) and (Ord(Arg[CharIdx]) and $C0 = $80) do
          begin
            Utf := Utf + Arg[CharIdx];
            Inc(CharIdx);
          end;
          TViewAccess(Demo_View).UTF8KeyPress(Utf);
        end;
      end
      else if (Cmd = 'm') or (Cmd = 'ms') or (Cmd = 'md') or (Cmd = 'mt') then
      begin
        X1 := StrToInt(Parts[0]);
        Y1 := StrToInt(Parts[1]);
        if Cmd = 'm' then
          TViewAccess(Demo_View).MouseDown(mbLeft, [ssLeft], X1, Y1)
        else if Cmd = 'ms' then
          TViewAccess(Demo_View).MouseDown(mbLeft, [ssLeft, ssShift], X1, Y1)
        else if Cmd = 'md' then
          TViewAccess(Demo_View).MouseDown(mbLeft, [ssLeft, ssDouble], X1, Y1)
        else
          TViewAccess(Demo_View).MouseDown(mbLeft, [ssLeft, ssTriple], X1, Y1);
        TViewAccess(Demo_View).MouseUp(mbLeft, [], X1, Y1);
      end
      else if Cmd = 'drag' then
      begin
        X1 := StrToInt(Parts[0]); Y1 := StrToInt(Parts[1]);
        X2 := StrToInt(Parts[2]); Y2 := StrToInt(Parts[3]);
        TViewAccess(Demo_View).MouseDown(mbLeft, [ssLeft], X1, Y1);
        TViewAccess(Demo_View).MouseMove([ssLeft], (X1 + X2) div 2, (Y1 + Y2) div 2);
        TViewAccess(Demo_View).MouseMove([ssLeft], X2, Y2);
        TViewAccess(Demo_View).MouseUp(mbLeft, [], X2, Y2);
      end
      else if Cmd = 'info' then
        Writeln('  charw ', Demo_View.CharW, ' lineh ', Demo_View.LineH, ' gutter ', Demo_View.GutterWidth)
      else if Cmd = 'show' then
      begin
        for RowIdx := 0 to Demo_View.Buffer.Count - 1 do
          if RowIdx < 12 then
            Writeln('  |', UTF8Encode(Demo_View.Buffer[RowIdx]), '|');
        Writeln('  sel "', StringReplace(UTF8Encode(Demo_View.SelectedText), #13#10, '\n', [rfReplaceAll]), '"');
        Writeln('  undo ', Demo_View.Buffer.UndoCount, ' redo ', Demo_View.Buffer.RedoCount,
          ' modified ', Demo_View.Buffer.Modified);
      end
      else
        Writeln('?? ', Cmd);
      Writeln(Words[WordIdx], ' caret ', Demo_View.CaretRow + 1, ':', Demo_View.CaretCol + 1,
        ' top ', Demo_View.TopRow + 1, ' left ', Demo_View.LeftCol);
      Flush(Output);
    end;
  finally
    Parts.Free;
    Words.Free;
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
