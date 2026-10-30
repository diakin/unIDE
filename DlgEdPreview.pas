unit DlgEdPreview;

// ---------------------------------------------------------------------------
//  Окно «Свой редактор - проба» (View, план портирования, шаги 0.7.2 -
//  0.7.3): текст вкладки - копией на момент открытия - в окне TEdView
//  (EdView.pas) с подсветкой по схеме файла (EdScheme.pas). Копию можно
//  править (набор, выделение, буфер обмена, откат - см. EdView); в файл и
//  во вкладку правки не попадают. Нужно, чтобы сравнить вид, скорость и
//  поведение своего окна с RichEdit на тех же файлах, пока свой редактор
//  не заменил RichEdit.
//
//  Ярлыки главного меню unIDE (Ctrl+S, F9...) в этом окне не работают:
//  они действуют на RichEdit, а не на копию. Esc - закрыть окно.
//
//  Окно немодальное, их может быть несколько; закрытое освобождается.
// ---------------------------------------------------------------------------

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

interface

uses
  {$IFDEF MSWINDOWS}Windows,{$ENDIF}
  {$IFDEF FPC}LCLIntf, LCLType, LMessages,{$ELSE}Messages,{$ENDIF}
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
    {$IFDEF FPC}
    procedure FormShortCut(var Msg: TLMKey; var Handled: Boolean);
    {$ELSE}
    procedure FormShortCut(var Msg: TWMKey; var Handled: Boolean);
    {$ENDIF}
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
var
  ModText, InsText: string;
begin
  if FBuffer.Modified then
    ModText := 'изменён'
  else
    ModText := 'не изменён';
  if FView.Overwrite then
    InsText := 'замена'
  else
    InsText := 'вставка';
  FStatus.Caption := Format('  Строка %d, символ %d   |   %s   |   %s   |   ' +
    'строк %d, символов %d   |   открыто за %d мс   |   копия, в файл ' +
    'не записывается',
    [FView.CaretRow + 1, FView.CaretCol + 1, InsText, ModText, FBuffer.Count,
     FBuffer.TextLength, FLoadMs]);
end;

// Ярлыки главного меню unIDE - мимо: они правят RichEdit, а не эту копию.
// Глушатся только ярлыки - сочетания с Ctrl или с Alt и F-клавиши. Всё
// остальное (буквы, Shift+буквы) надо пропустить: нажатие, разобранное
// здесь, Windows уже не переводит в символ (TranslateMessage не
// вызывается) - набор не доходил до окна. Свои сочетания окно правки
// разбирает раньше (TEdView.CNKeyDown). Ctrl+Alt (AltGr) - тоже символ.
// Esc - закрыть; Alt+F4 - как обычно
{$IFDEF FPC}
procedure TEdPreviewForm.FormShortCut(var Msg: TLMKey; var Handled: Boolean);
{$ELSE}
procedure TEdPreviewForm.FormShortCut(var Msg: TWMKey; var Handled: Boolean);
{$ENDIF}
var
  CtrlDown, AltDown: Boolean;
begin
  if Msg.CharCode = VK_ESCAPE then
  begin
    Close;
    Handled := True;
    Exit;
  end;
  CtrlDown := GetKeyState(VK_CONTROL) < 0;
  AltDown := GetKeyState(VK_MENU) < 0;
  if (Msg.CharCode = VK_F4) and AltDown then
    Exit;
  if ((Msg.CharCode >= VK_F1) and (Msg.CharCode <= VK_F24)) or
     (CtrlDown <> AltDown) then
    Handled := True;
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
  Form.Caption := 'Свой редактор (проба, копия): ' + ATitle;
  Form.Position := poMainFormCenter;
  Form.Width := 900;
  Form.Height := 640;
  Form.OnClose := Form.FormClose;
  Form.OnShortCut := Form.FormShortCut;
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
  Form.FView.OnChange := Form.ViewCaretMove;
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
