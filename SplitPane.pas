unit SplitPane;

// ---------------------------------------------------------------------------
//  Вторая панель редактора: окно делится на две по вертикали (панели слева
//  и справа) или по горизонтали (сверху и снизу).
//
//  Редактор с подсветкой в программе один (RichEdit1 в Unit1), и править
//  можно только в нём. Вторая панель показывает другую (или ту же) вкладку
//  только для чтения:
//    - текст с подсветкой по схеме файла (SchemeRtf -> RTF в RichEdit);
//    - при своём редакторе (план портирования, шаг 0.7.5) - текст в окне
//      TEdView (EdView.pas) с номерами строк и своими полосами прокрутки;
//      та же вкладка, что в редакторе, - тот же буфер TEdBuffer, правки
//      видны сразу (ShowEdText);
//    - или вид "по формату" (FmtView: страница IE, RTF, RVF).
//  Щелчок по тексту второй панели меняет панели местами: редактор
//  переезжает туда, где щёлкнули, и открывает её вкладку с кареткой в
//  месте щелчка, а прежняя вкладка редактора становится текстом второй
//  панели (это делает Unit1, SplitActivate). Так всегда правится та
//  панель, в которой работают, а вторая - только для чтения.
//
//  Панели меняются местами без смены родителя: редактор (FLeftHost) всегда
//  alClient, у второй панели и разделителя меняется сторона (alRight /
//  alLeft, alBottom / alTop). Смена родителя пересоздала бы окна RichEdit
//  редактора со всей их настройкой.
//
//  Заголовок (TPaneHeader) - у обеих панелей: у второй - здесь, у
//  редактора - сверху FLeftHost (Unit1, FEditHeader). Имя файла (щелчок -
//  выбор вкладки), кнопка Txt / Fmt (у файлов с видом "по формату"), у
//  второй панели - кнопка закрытия. Заголовок активной панели - цветом
//  активной вкладки. Вид каждой панели (текст / по формату) свой и при
//  переходе из панели в панель не меняется.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, ExtCtrls,
  StdCtrls, Menus, Forms, UiButton, UiMenus, FmtView, ClrScheme, EdBuffer,
  EdView, EdScheme;

type
  // soVertical - панели слева и справа (разделитель вертикальный)
  TSplitOrient = (soNone, soVertical, soHorizontal);
  // Что показано во второй панели
  // svEdText - текст в окне TEdView (свой редактор)
  TSplitView = (svNone, svText, svWeb, svFmt, svEdText);
  TSplitTextClickEvent = procedure(ALine, ACol, ATopLine: Integer) of object;

  // Строка заголовка панели редактора: имя файла (щелчок - выбор вкладки),
  // кнопка Txt / Fmt (у файлов с видом "по формату"), кнопка закрытия.
  // Цвет - по тому, активна ли панель (SetColors)
  TPaneHeader = class
  private
    FPanel: TPanel;
    FTitle: TLabel;
    FFmtBtn: TUiButton;
    FCloseBtn: TUiButton;
    FSyncBtn: TUiButton;
    FTitleText: string;
    FTitleMark: string;
    FOnTitleClick: TNotifyEvent;
    FOnFmtClick: TNotifyEvent;
    FOnCloseClick: TNotifyEvent;
    FOnSyncClick: TNotifyEvent;
    procedure TitleClick(Sender: TObject);
    procedure FmtBtnClick(Sender: TObject);
    procedure SyncBtnClick(Sender: TObject);
    procedure ShowTitle;
    procedure CloseBtnClick(Sender: TObject);
  public
    // AParent - панель, сверху которой встаёт заголовок (alTop);
    // AWithClose - с кнопкой закрытия
    constructor Create(AParent: TWinControl; AWithClose: Boolean;
      const ACloseHint: string);
    destructor Destroy; override;
    procedure SetTitle(const ATitle, AHint: string; AHasFmt, AFmtShown: Boolean);
    procedure SetColors(ABack, AText: TColor);
    // Кнопка синхронной прокрутки (только у заголовка второй панели):
    // AVisible - показать, AOn - включена
    procedure SetSync(AVisible, AOn: Boolean);
    // Пометка после имени файла (свой редактор); '' - без неё
    procedure SetTitleMark(const AMark: string);
    property Panel: TPanel read FPanel;
    property OnTitleClick: TNotifyEvent read FOnTitleClick write FOnTitleClick;
    property OnFmtClick: TNotifyEvent read FOnFmtClick write FOnFmtClick;
    property OnCloseClick: TNotifyEvent read FOnCloseClick write FOnCloseClick;
    property OnSyncClick: TNotifyEvent read FOnSyncClick write FOnSyncClick;
  end;

  // Первая видимая строка текста второй панели сменилась
  TSplitScrollEvent = procedure(ATopLine: Integer) of object;

  TSplitPane = class
  private
    FParent: TWinControl;
    FEditorHost: TWinControl;
    FPanel: TPanel;
    FHeader: TPaneHeader;
    FBody: TPanel;
    FSplitter: TSplitter;
    FText: TRtfPreview;      // текст с подсветкой
    FEdText: TEdView;        // текст с подсветкой - при своём редакторе
    FEdOwn: TEdBuffer;       // копия текста вкладки для FEdText
    FEdShared: TEdBuffer;    // или буфер своего редактора (та же вкладка)
    FEdHigh: TEdSchemeHighlighter;
    FWeb: TWebPreview;       // по формату: md, html, mht
    FFmt: TRtfPreview;       // по формату: rtf, rvf
    FMenu: TUiPopupMenu;     // правая кнопка: копировать, выделить всё
    FOrient: TSplitOrient;
    FEditorFirst: Boolean;
    FView: TSplitView;
    FOnTextClick: TSplitTextClickEvent;
    FOnTitleClick: TNotifyEvent;
    FOnFmtClick: TNotifyEvent;
    FOnCloseClick: TNotifyEvent;
    FOnTextScroll: TSplitScrollEvent;
    procedure EdTextScroll(Sender: TObject);
    procedure TextClickPos(Sender: TObject; ALine, ACol, ATopLine: Integer);
    procedure EdTextClick(Sender: TObject; ARow, ACol: Integer);
    procedure EdTextFree;
    procedure EdTextEnsure;
    procedure HeaderTitleClick(Sender: TObject);
    procedure HeaderFmtClick(Sender: TObject);
    procedure HeaderCloseClick(Sender: TObject);
    procedure CopyClick(Sender: TObject);
    procedure SelectAllClick(Sender: TObject);
    function IsShown: Boolean;
  public
    // AParent - панель, на которой лежит редактор (pnlMain); AEditorHost -
    // сам редактор (FLeftHost, alClient)
    constructor Create(AParent, AEditorHost: TWinControl);
    destructor Destroy; override;
    // Расположение: AOrient = soNone - панель убрана. AEditorFirst -
    // редактор слева / сверху. Смена только стороны (AEditorFirst) при той
    // же ориентации оставляет границу между панелями на месте
    procedure SetLayout(AOrient: TSplitOrient; AEditorFirst: Boolean);
    procedure SetTitle(const ATitle, AHint: string; AHasFmt, AFmtShown: Boolean);
    // Текст с подсветкой: ARtf - из SchemeTextToRtf, APaper - фон схемы
    procedure ShowText(const ARtf, ASourceFile: string; APaper: TColor;
      ATopLine: Integer);
    // Текст в окне TEdView: AShared - буфер своего редактора (в панели
    // та же вкладка; правки видны сразу), иначе - копия AText. AScheme
    // переходит панели (nil - без подсветки). Шрифт, табуляция, цвета -
    // SetEdLook, до ShowEdText
    procedure ShowEdText(AShared: TEdBuffer; const AText: WideString;
      AScheme: TClrScheme; ATopLine: Integer);
    procedure SetEdLook(AFont: TFont; ATabSize: Integer; AGutter, AGutterText,
      AGutterCur, AGutterCurText, ASel, ASelText: TColor);
    // Отпустить буфер своего редактора (его освобождают или он уходит к
    // другой вкладке); окно TEdView прячется
    procedure DetachShared;
    // Первая видимая строка окна TEdView
    procedure EdScrollTo(ATopLine: Integer);
    // Сообщение вместо содержимого (нет вкладки, ошибка)
    procedure ShowNotice(const AText: string);
    // После показа в Web или Fmt - убрать остальное
    procedure KeepOnly(AView: TSplitView);
    function TextTopLine: Integer;
    // Окно AWnd - одно из окон второй панели (для клавиш и правой кнопки)
    function OwnsWindow(AWnd: HWND): Boolean;
    function WebOwnsWindow(AWnd: HWND): Boolean;
    procedure ShowMenu(const APoint: TPoint);
    procedure CopySelection;
    procedure SelectAll;
    property Panel: TPanel read FPanel;
    property Header: TPaneHeader read FHeader;
    property Splitter: TSplitter read FSplitter;
    property Web: TWebPreview read FWeb;
    property Fmt: TRtfPreview read FFmt;
    property Orient: TSplitOrient read FOrient;
    property EditorFirst: Boolean read FEditorFirst;
    property View: TSplitView read FView;
    // Буфер своего редактора, который показывает панель; nil - нет
    property SharedBuffer: TEdBuffer read FEdShared;
    property Shown: Boolean read IsShown;
    property OnTextClick: TSplitTextClickEvent read FOnTextClick
      write FOnTextClick;
    property OnTitleClick: TNotifyEvent read FOnTitleClick write FOnTitleClick;
    property OnFmtClick: TNotifyEvent read FOnFmtClick write FOnFmtClick;
    property OnCloseClick: TNotifyEvent read FOnCloseClick write FOnCloseClick;
    // Текст в окне TEdView прокрутили (синхронная прокрутка, Unit1)
    property OnTextScroll: TSplitScrollEvent read FOnTextScroll
      write FOnTextScroll;
  end;

implementation

const
  SplitterSize = 5;
  MinPaneSize = 80;
  PaneHeaderHeight = 22;

// ---------------------------------------------------------------------------
//  TPaneHeader
// ---------------------------------------------------------------------------

constructor TPaneHeader.Create(AParent: TWinControl; AWithClose: Boolean;
  const ACloseHint: string);
begin
  inherited Create;
  FPanel := TPanel.Create(nil);
  FPanel.Parent := AParent;
  FPanel.Align := alTop;
  FPanel.Height := PaneHeaderHeight;
  FPanel.BevelOuter := bvNone;
  FPanel.Caption := '';
  // Свой цвет (активная панель - цветом активной вкладки): фон темы
  // Windows его перекрыл бы
  FPanel.ParentBackground := False;

  if AWithClose then
  begin
    FCloseBtn := TUiButton.Create(FPanel);
    FCloseBtn.Parent := FPanel;
    FCloseBtn.Left := 2000;   // у alRight правее тот, у кого Left больше
    FCloseBtn.Align := alRight;
    FCloseBtn.Width := 24;
    FCloseBtn.Caption := 'x';
    FCloseBtn.TabStop := False;
    FCloseBtn.Hint := ACloseHint;
    FCloseBtn.ShowHint := True;
    FCloseBtn.OnClick := CloseBtnClick;
  end;

  if AWithClose then
  begin
    FSyncBtn := TUiButton.Create(FPanel);
    FSyncBtn.Parent := FPanel;
    FSyncBtn.Left := 500;
    FSyncBtn.Align := alRight;
    FSyncBtn.Width := 70;
    FSyncBtn.Caption := 'Sync';
    FSyncBtn.TabStop := False;
    FSyncBtn.Hint := 'Синхронная прокрутка: панели показывают одни и те ' +
      'же номера строк';
    FSyncBtn.ShowHint := True;
    FSyncBtn.Visible := False;
    FSyncBtn.OnClick := SyncBtnClick;
  end;

  FFmtBtn := TUiButton.Create(FPanel);
  FFmtBtn.Parent := FPanel;
  FFmtBtn.Left := 1000;
  FFmtBtn.Align := alRight;
  FFmtBtn.Width := 40;
  FFmtBtn.Caption := 'Txt';
  FFmtBtn.TabStop := False;
  FFmtBtn.Hint := 'Текст / по формату';
  FFmtBtn.ShowHint := True;
  FFmtBtn.Visible := False;
  FFmtBtn.OnClick := FmtBtnClick;

  FTitle := TLabel.Create(FPanel);
  FTitle.Parent := FPanel;
  FTitle.Align := alClient;
  FTitle.Layout := tlCenter;
  FTitle.AutoSize := False;
  FTitle.Transparent := True;
  FTitle.ShowAccelChar := False;   // '&' в имени файла - не ускоритель
  FTitle.Cursor := crHandPoint;
  FTitle.ShowHint := True;
  FTitle.Caption := '';
  FTitle.OnClick := TitleClick;
end;

destructor TPaneHeader.Destroy;
begin
  FreeAndNil(FPanel);   // кнопки и подпись - его компоненты
  inherited Destroy;
end;

procedure TPaneHeader.ShowTitle;
var
  NewCaption: string;
begin
  NewCaption := '  ' + FTitleText + '  ...' + FTitleMark;
  if FTitle.Caption <> NewCaption then
    FTitle.Caption := NewCaption;
end;

procedure TPaneHeader.SetTitleMark(const AMark: string);
begin
  if AMark = FTitleMark then
    Exit;
  FTitleMark := AMark;
  ShowTitle;
end;

procedure TPaneHeader.SetTitle(const ATitle, AHint: string;
  AHasFmt, AFmtShown: Boolean);
begin
  FTitleText := ATitle;
  ShowTitle;
  FTitle.Hint := AHint;
  // Скрытая кнопка alRight хранит прежний Left: показанная после сужения
  // заголовка, она могла бы встать правее кнопки закрытия
  if AHasFmt and not FFmtBtn.Visible then
  begin
    if FCloseBtn <> nil then
      FFmtBtn.Left := FCloseBtn.Left - FFmtBtn.Width
    else
      FFmtBtn.Left := FPanel.ClientWidth - FFmtBtn.Width;
  end;
  FFmtBtn.Visible := AHasFmt;
  if AFmtShown then
    FFmtBtn.Caption := 'Fmt'
  else
    FFmtBtn.Caption := 'Txt';
end;

procedure TPaneHeader.SetColors(ABack, AText: TColor);
begin
  if FPanel.Color <> ABack then
    FPanel.Color := ABack;
  if FTitle.Font.Color <> AText then
    FTitle.Font.Color := AText;
end;

procedure TPaneHeader.SetSync(AVisible, AOn: Boolean);
var
  NewCaption: string;
begin
  if FSyncBtn = nil then
    Exit;
  if AOn then
    NewCaption := 'Sync: on'
  else
    NewCaption := 'Sync: off';
  if FSyncBtn.Caption <> NewCaption then
    FSyncBtn.Caption := NewCaption;
  // Показанная кнопка alRight - левее кнопки Txt / Fmt
  if AVisible and not FSyncBtn.Visible then
    FSyncBtn.Left := FFmtBtn.Left - FSyncBtn.Width;
  if FSyncBtn.Visible <> AVisible then
    FSyncBtn.Visible := AVisible;
end;

procedure TPaneHeader.SyncBtnClick(Sender: TObject);
begin
  if Assigned(FOnSyncClick) then
    FOnSyncClick(Self);
end;

procedure TPaneHeader.TitleClick(Sender: TObject);
begin
  if Assigned(FOnTitleClick) then
    FOnTitleClick(Self);
end;

procedure TPaneHeader.FmtBtnClick(Sender: TObject);
begin
  if Assigned(FOnFmtClick) then
    FOnFmtClick(Self);
end;

procedure TPaneHeader.CloseBtnClick(Sender: TObject);
begin
  if Assigned(FOnCloseClick) then
    FOnCloseClick(Self);
end;

// ---------------------------------------------------------------------------
//  TSplitPane
// ---------------------------------------------------------------------------

constructor TSplitPane.Create(AParent, AEditorHost: TWinControl);
var
  MenuItem: TMenuItem;
begin
  inherited Create;
  FParent := AParent;
  FEditorHost := AEditorHost;
  FOrient := soNone;
  FEditorFirst := True;
  FView := svNone;

  FMenu := TUiPopupMenu.Create(nil);
  MenuItem := TMenuItem.Create(FMenu);
  MenuItem.Caption := 'Копировать'#9'Ctrl+C';
  MenuItem.OnClick := CopyClick;
  FMenu.Items.Add(MenuItem);
  MenuItem := TMenuItem.Create(FMenu);
  MenuItem.Caption := 'Выделить всё'#9'Ctrl+A';
  MenuItem.OnClick := SelectAllClick;
  FMenu.Items.Add(MenuItem);

  FPanel := TPanel.Create(nil);
  FPanel.Visible := False;
  FPanel.Parent := AParent;
  FPanel.BevelOuter := bvNone;
  FPanel.Caption := '';

  FSplitter := TSplitter.Create(nil);
  FSplitter.Visible := False;
  FSplitter.Parent := AParent;
  FSplitter.AutoSnap := False;
  FSplitter.MinSize := MinPaneSize;
  FSplitter.ResizeStyle := rsUpdate;

  FHeader := TPaneHeader.Create(FPanel, True, 'Убрать вторую панель');
  FHeader.OnTitleClick := HeaderTitleClick;
  FHeader.OnFmtClick := HeaderFmtClick;
  FHeader.OnCloseClick := HeaderCloseClick;

  FBody := TPanel.Create(FPanel);
  FBody.Parent := FPanel;
  FBody.Align := alClient;
  FBody.BevelOuter := bvNone;
  FBody.Caption := '';

  FText := TRtfPreview.Create(FBody, FMenu);
  FText.WrapLines := False;
  FText.OnClickPos := TextClickPos;
  FWeb := TWebPreview.Create(FBody);
  FFmt := TRtfPreview.Create(FBody, FMenu);
end;

destructor TSplitPane.Destroy;
begin
  EdTextFree;
  FreeAndNil(FEdText);
  FreeAndNil(FText);
  FreeAndNil(FWeb);
  FreeAndNil(FFmt);
  FreeAndNil(FHeader);
  FreeAndNil(FSplitter);
  FreeAndNil(FPanel);
  FreeAndNil(FMenu);
  inherited Destroy;
end;

function TSplitPane.IsShown: Boolean;
begin
  Result := (FOrient <> soNone) and FPanel.Visible;
end;

procedure TSplitPane.SetLayout(AOrient: TSplitOrient; AEditorFirst: Boolean);
var
  Area: TRect;
  AreaSize, PaneSize: Integer;
  Vertical, WasShown: Boolean;
begin
  if AOrient = soNone then
  begin
    FPanel.Visible := False;
    FSplitter.Visible := False;
    FOrient := soNone;
    Exit;
  end;

  // Место редактора вместе со второй панелью и разделителем
  WasShown := IsShown;
  Area := FEditorHost.BoundsRect;
  if WasShown then
  begin
    UnionRect(Area, Area, FPanel.BoundsRect);
    UnionRect(Area, Area, FSplitter.BoundsRect);
  end;
  Vertical := AOrient = soVertical;
  if Vertical then
    AreaSize := Area.Right - Area.Left
  else
    AreaSize := Area.Bottom - Area.Top;

  // Размер второй панели: та же ориентация - граница остаётся на месте
  // (при смене стороны панель берёт размер, который был у редактора);
  // иначе - половина
  if WasShown and (AOrient = FOrient) then
  begin
    if Vertical then
      PaneSize := FPanel.Width
    else
      PaneSize := FPanel.Height;
    if AEditorFirst <> FEditorFirst then
      PaneSize := AreaSize - PaneSize - SplitterSize;
  end
  else
    PaneSize := (AreaSize - SplitterSize) div 2;
  if PaneSize > AreaSize - SplitterSize - MinPaneSize then
    PaneSize := AreaSize - SplitterSize - MinPaneSize;
  if PaneSize < MinPaneSize then
    PaneSize := MinPaneSize;

  FParent.DisableAlign;
  try
    FPanel.Align := alNone;
    FSplitter.Align := alNone;
    FPanel.Visible := True;
    FSplitter.Visible := True;
    // Порядок у выровненных к одной стороне задают координаты: панель -
    // у края, разделитель - между ней и редактором
    if Vertical then
    begin
      FSplitter.Cursor := crHSplit;
      if AEditorFirst then
      begin
        FPanel.SetBounds(Area.Right - PaneSize, Area.Top, PaneSize,
                         Area.Bottom - Area.Top);
        FSplitter.SetBounds(Area.Right - PaneSize - SplitterSize, Area.Top,
                            SplitterSize, Area.Bottom - Area.Top);
        FPanel.Align := alRight;
        FSplitter.Align := alRight;
      end
      else
      begin
        FPanel.SetBounds(Area.Left, Area.Top, PaneSize,
                         Area.Bottom - Area.Top);
        FSplitter.SetBounds(Area.Left + PaneSize, Area.Top, SplitterSize,
                            Area.Bottom - Area.Top);
        FPanel.Align := alLeft;
        FSplitter.Align := alLeft;
      end;
    end
    else
    begin
      FSplitter.Cursor := crVSplit;
      if AEditorFirst then
      begin
        FPanel.SetBounds(Area.Left, Area.Bottom - PaneSize,
                         Area.Right - Area.Left, PaneSize);
        FSplitter.SetBounds(Area.Left, Area.Bottom - PaneSize - SplitterSize,
                            Area.Right - Area.Left, SplitterSize);
        FPanel.Align := alBottom;
        FSplitter.Align := alBottom;
      end
      else
      begin
        FPanel.SetBounds(Area.Left, Area.Top, Area.Right - Area.Left,
                         PaneSize);
        FSplitter.SetBounds(Area.Left, Area.Top + PaneSize,
                            Area.Right - Area.Left, SplitterSize);
        FPanel.Align := alTop;
        FSplitter.Align := alTop;
      end;
    end;
  finally
    FParent.EnableAlign;
  end;
  FOrient := AOrient;
  FEditorFirst := AEditorFirst;
end;

procedure TSplitPane.SetTitle(const ATitle, AHint: string;
  AHasFmt, AFmtShown: Boolean);
begin
  FHeader.SetTitle(ATitle, AHint, AHasFmt, AFmtShown);
end;

procedure TSplitPane.KeepOnly(AView: TSplitView);
begin
  FView := AView;
  if (AView <> svEdText) and (FEdText <> nil) and FEdText.Visible then
    FEdText.Visible := False;
  if (AView <> svText) and FText.IsShown then
    FText.HideView;
  if (AView <> svWeb) and FWeb.IsShown then
    FWeb.HideView;
  if (AView <> svFmt) and FFmt.IsShown then
    FFmt.HideView;
end;

procedure TSplitPane.ShowText(const ARtf, ASourceFile: string; APaper: TColor;
  ATopLine: Integer);
begin
  FText.PaperColor := APaper;
  FText.ShowRtf(ARtf, ASourceFile);
  FText.SetTopLine(ATopLine);
  KeepOnly(svText);
end;

// Окно отпускает буфер, подсветка и копия текста освобождаются
procedure TSplitPane.EdTextFree;
begin
  if FEdText <> nil then
    FEdText.Buffer := nil;
  FreeAndNil(FEdHigh);
  FreeAndNil(FEdOwn);
  FEdShared := nil;
end;

procedure TSplitPane.EdTextEnsure;
begin
  if FEdText <> nil then
    Exit;
  FEdText := TEdView.Create(nil);
  FEdText.Visible := False;
  FEdText.Parent := FBody;
  FEdText.Align := alClient;
  FEdText.ReadOnly := True;
  FEdText.TabStop := False;
  FEdText.PopupMenu := FMenu;
  FEdText.OnTextClick := EdTextClick;
  FEdText.OnViewScroll := EdTextScroll;
end;

procedure TSplitPane.ShowEdText(AShared: TEdBuffer; const AText: WideString;
  AScheme: TClrScheme; ATopLine: Integer);
var
  ShowBuf: TEdBuffer;
begin
  EdTextEnsure;
  EdTextFree;
  if AShared <> nil then
    ShowBuf := AShared
  else
  begin
    FEdOwn := TEdBuffer.Create;
    FEdOwn.SetText(AText);
    ShowBuf := FEdOwn;
  end;
  FEdShared := AShared;
  FEdHigh := TEdSchemeHighlighter.Create(ShowBuf, AScheme, clWindowText,
    clWindow);
  FEdText.TextColor := FEdHigh.TextColor;
  FEdText.BackColor := FEdHigh.BackColor;
  FEdText.OnLineRuns := FEdHigh.LineRuns;
  FEdText.Buffer := ShowBuf;
  FEdText.Visible := True;
  KeepOnly(svEdText);
  FEdText.RefreshAll;
  if ATopLine > 0 then
    FEdText.ScrollTo(ATopLine, 0);
end;

procedure TSplitPane.SetEdLook(AFont: TFont; ATabSize: Integer; AGutter,
  AGutterText, AGutterCur, AGutterCurText, ASel, ASelText: TColor);
begin
  EdTextEnsure;
  if AFont <> nil then
    FEdText.Font.Assign(AFont);
  FEdText.TabSize := ATabSize;
  FEdText.GutterColor := AGutter;
  FEdText.GutterTextColor := AGutterText;
  FEdText.GutterCurColor := AGutterCur;
  FEdText.GutterCurText := AGutterCurText;
  FEdText.SelColor := ASel;
  FEdText.SelTextColor := ASelText;
  FEdText.RefreshAll;
end;

procedure TSplitPane.DetachShared;
begin
  if FEdShared = nil then
    Exit;
  EdTextFree;
  if FEdText <> nil then
    FEdText.Visible := False;
  if FView = svEdText then
    FView := svNone;
end;

procedure TSplitPane.EdScrollTo(ATopLine: Integer);
begin
  if (FEdText <> nil) and (FEdText.Buffer <> nil) and (ATopLine >= 0) then
    FEdText.ScrollTo(ATopLine, FEdText.LeftCol);
end;

procedure TSplitPane.EdTextScroll(Sender: TObject);
begin
  if Assigned(FOnTextScroll) and (FEdText.Buffer <> nil) then
    FOnTextScroll(FEdText.TopRow);
end;

procedure TSplitPane.EdTextClick(Sender: TObject; ARow, ACol: Integer);
begin
  if Assigned(FOnTextClick) then
    FOnTextClick(ARow, ACol, FEdText.TopRow);
end;

procedure TSplitPane.ShowNotice(const AText: string);
begin
  FText.PaperColor := clWhite;
  FText.ShowRtf(FmtPlainToRtf(AText), '');
  KeepOnly(svText);
end;

function TSplitPane.TextTopLine: Integer;
begin
  if (FView = svEdText) and (FEdText <> nil) then
    Result := FEdText.TopRow
  else
    Result := FText.TopLine;
end;

function TSplitPane.OwnsWindow(AWnd: HWND): Boolean;
begin
  Result := IsShown and (FText.OwnsWindow(AWnd) or FFmt.OwnsWindow(AWnd) or
                         FWeb.OwnsWindow(AWnd) or
                         ((FEdText <> nil) and FEdText.HandleAllocated and
                          ((AWnd = FEdText.Handle) or
                           IsChild(FEdText.Handle, AWnd))));
end;

function TSplitPane.WebOwnsWindow(AWnd: HWND): Boolean;
begin
  Result := IsShown and FWeb.OwnsWindow(AWnd);
end;

procedure TSplitPane.ShowMenu(const APoint: TPoint);
begin
  FMenu.Popup(APoint.X, APoint.Y);
end;

procedure TSplitPane.CopySelection;
begin
  case FView of
    svText: FText.CopySelection;
    svEdText: FEdText.CopyToClipboard;
    svWeb: FWeb.CopySelection;
    svFmt: FFmt.CopySelection;
  end;
end;

procedure TSplitPane.SelectAll;
begin
  case FView of
    svText: FText.SelectAll;
    svEdText: FEdText.SelectAll;
    svWeb: FWeb.SelectAll;
    svFmt: FFmt.SelectAll;
  end;
end;

procedure TSplitPane.TextClickPos(Sender: TObject;
  ALine, ACol, ATopLine: Integer);
begin
  if Assigned(FOnTextClick) then
    FOnTextClick(ALine, ACol, ATopLine);
end;

procedure TSplitPane.HeaderTitleClick(Sender: TObject);
begin
  if Assigned(FOnTitleClick) then
    FOnTitleClick(Self);
end;

procedure TSplitPane.HeaderFmtClick(Sender: TObject);
begin
  if Assigned(FOnFmtClick) then
    FOnFmtClick(Self);
end;

procedure TSplitPane.HeaderCloseClick(Sender: TObject);
begin
  if Assigned(FOnCloseClick) then
    FOnCloseClick(Self);
end;

procedure TSplitPane.CopyClick(Sender: TObject);
begin
  CopySelection;
end;

procedure TSplitPane.SelectAllClick(Sender: TObject);
begin
  SelectAll;
end;

end.
