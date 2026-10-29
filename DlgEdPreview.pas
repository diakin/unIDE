unit DlgEdPreview;

// ---------------------------------------------------------------------------
//  Окно «Свой редактор - просмотр» (View, план портирования, шаг 0.7.2):
//  текст вкладки - снимком на момент открытия - в окне TEdView (EdView.pas)
//  с подсветкой по схеме файла (EdScheme.pas). Только просмотр: стрелки,
//  PgUp / PgDn, Home / End, Ctrl+Home / Ctrl+End, Ctrl+стрелки - прокрутка,
//  колесо, щелчок мышью. Нужно, чтобы сравнить вид и скорость своего окна
//  с RichEdit на тех же файлах, пока свой редактор не заменил RichEdit.
//
//  Окно немодальное, их может быть несколько; закрытое освобождается.
// ---------------------------------------------------------------------------

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  {$IFDEF MSWINDOWS}Windows,{$ENDIF}
  SysUtils, Classes, Graphics, Controls, Forms, ExtCtrls, StdCtrls,
  ClrScheme, EdBuffer, EdView, EdScheme;

type
  // Цвета IDE для окна; clNone / clDefault - свои цвета окна
  TEdPreviewColors = record
    Gutter: TColor;
    GutterText: TColor;
    GutterCur: TColor;
    GutterCurText: TColor;
    Sel: TColor;
    SelText: TColor;
  end;

// Показать AText (строки через CRLF) в новом окне. AScheme переходит окну
// (nil - без подсветки); каретка - строка ACaretRow, символ ACaretCol (с 0)
procedure ShowEdPreview(const ATitle: string; const AText: WideString;
  AScheme: TClrScheme; AFont: TFont; ATabSize, ACaretRow, ACaretCol: Integer;
  const AColors: TEdPreviewColors);

implementation

function EdTicks: Cardinal;
begin
  {$IFDEF FPC}
  Result := Cardinal(GetTickCount64);
  {$ELSE}
  Result := GetTickCount;
  {$ENDIF}
end;

type
  TEdPreviewForm = class(TForm)
  private
    FBuffer: TEdBuffer;
    FHighlighter: TEdSchemeHighlighter;
    FView: TEdView;
    FStatus: TPanel;
    FLoadMs: Cardinal;
    procedure ViewCaretMove(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
  end;

function PickColor(AColor, ADefault: TColor): TColor;
begin
  if (AColor = clNone) or (AColor = clDefault) then
    Result := ADefault
  else
    Result := AColor;
end;

procedure TEdPreviewForm.ViewCaretMove(Sender: TObject);
begin
  FStatus.Caption := Format('  Строка %d, символ %d   |   строк %d, ' +
    'символов %d   |   открыто за %d мс   |   только просмотр (шаг 0.7.2)',
    [FView.CaretRow + 1, FView.CaretCol + 1, FBuffer.Count,
     FBuffer.TextLength, FLoadMs]);
end;

procedure TEdPreviewForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TEdPreviewForm.FormDestroy(Sender: TObject);
begin
  // Окно и подсветка отписываются от буфера, пока он жив
  FView.Buffer := nil;
  FreeAndNil(FHighlighter);
  FreeAndNil(FBuffer);
end;

procedure ShowEdPreview(const ATitle: string; const AText: WideString;
  AScheme: TClrScheme; AFont: TFont; ATabSize, ACaretRow, ACaretCol: Integer;
  const AColors: TEdPreviewColors);
var
  Form: TEdPreviewForm;
  StartTick: Cardinal;
begin
  StartTick := EdTicks;
  Form := TEdPreviewForm.CreateNew(Application);
  Form.Caption := 'Свой редактор (просмотр): ' + ATitle;
  Form.Position := poMainFormCenter;
  Form.Width := 900;
  Form.Height := 640;
  Form.OnClose := Form.FormClose;
  Form.OnDestroy := Form.FormDestroy;

  Form.FBuffer := TEdBuffer.Create;
  Form.FBuffer.SetText(AText);
  Form.FHighlighter := TEdSchemeHighlighter.Create(Form.FBuffer, AScheme,
    clWindowText, clWindow);

  Form.FStatus := TPanel.Create(Form);
  Form.FStatus.Parent := Form;
  Form.FStatus.Align := alBottom;
  Form.FStatus.Height := 22;
  Form.FStatus.BevelOuter := bvNone;
  Form.FStatus.Alignment := taLeftJustify;

  Form.FView := TEdView.Create(Form);
  Form.FView.Parent := Form;
  Form.FView.Align := alClient;
  if AFont <> nil then
    Form.FView.Font.Assign(AFont);
  Form.FView.TabSize := ATabSize;
  Form.FView.TextColor := Form.FHighlighter.TextColor;
  Form.FView.BackColor := Form.FHighlighter.BackColor;
  Form.FView.GutterColor := PickColor(AColors.Gutter, clBtnFace);
  Form.FView.GutterTextColor := PickColor(AColors.GutterText, clGrayText);
  Form.FView.GutterCurColor := PickColor(AColors.GutterCur, clNone);
  Form.FView.GutterCurText := PickColor(AColors.GutterCurText,
    Form.FView.GutterTextColor);
  Form.FView.SelColor := PickColor(AColors.Sel, clHighlight);
  Form.FView.SelTextColor := PickColor(AColors.SelText, clHighlightText);
  Form.FView.OnLineRuns := Form.FHighlighter.LineRuns;
  Form.FView.OnCaretMove := Form.ViewCaretMove;
  Form.FView.Buffer := Form.FBuffer;
  Form.FView.RefreshAll;

  Form.Show;
  Form.FView.SetFocus;
  Form.FView.CaretTo(ACaretRow, ACaretCol);
  // Строка каретки - посередине окна, как при переходе в редакторе
  Form.FView.ScrollTo(ACaretRow - Form.FView.VisibleRows div 2, 0);
  Form.FView.EnsureCaretVisible;
  Form.FLoadMs := EdTicks - StartTick;
  Form.ViewCaretMove(nil);
end;

end.
