unit DlgFileCompare;

// ---------------------------------------------------------------------------
//  Сравнение двух файлов (как WinMerge): меню File - Compare Files... и
//  меню вкладки - «Сравнить с ...».
//
//  Две панели рядом, строки друг против друга: разницу по строкам и
//  выравнивание даёт TextDiff (DiffLines, DiffAlign). Короткая сторона
//  отличия дополняется пустыми строками (серым). Строки отличий - жёлтым
//  фоном, текущее отличие - голубым; изменённые слова внутри пары строк -
//  ярче (DiffInline). Код подсвечен по схеме unIDE для файла (OnScheme -
//  Unit1.SchemeCopyFor).
//
//  Прокрутка панелей - вместе. Слева - полоса обзора: все отличия файла в
//  масштабе, рамка - видимая часть; щелчок - туда.
//
//  Клавиши: Alt+Down / F8 - следующее отличие, Alt+Up / F7 - предыдущее,
//  Alt+Home / Alt+End - первое / последнее, F5 - перечитать, Esc - закрыть.
//
//  Сторона - файл на диске или текст вкладки unIDE (с несохранёнными
//  правками; OnTabs - список вкладок, OnTabText - текст). Файл читается
//  в кодировке по BOM / по содержимому (UTF-8 или кодовая страница
//  Windows); символы UTF-8 вне кодовой страницы показываются '?'.
//
//  Шаг 2 плана: только просмотр. Перенос блоков и запись - шаг 4.
//
//  Окно строится в коде, .dfm нет. Немодальное, освобождается при
//  закрытии.
// ---------------------------------------------------------------------------

interface

uses
  {$IFDEF FPC} LCLType, {$ENDIF}
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, Dialogs, Menus,
  UiButton,      // TUiButton
  UiEditCtrls,   // TUiEdit
  UiStdCtrls,    // TUiLabel, TUiPanel, TUiCheckBox
  UiTheme,       // UiThemeColor, UM_UITHEMECHANGED
  ClrScheme, SchemeRtf, EdView, EdRows, EdFileText,
  GitDiffView,   // TGitSchemeEvent
  IniBuf,        // TBufIniFile - положение окна и параметры
  TextDiff;

type
  // Вкладки unIDE: строки - имена файлов, Objects - номер окна
  TCompareTabsEvent = procedure(AList: TStrings) of object;
  // Имя файла и текст окна AWinIdx (с несохранёнными правками); AModified
  // - есть несохранённые правки. False - окна нет
  TCompareTabTextEvent = function(AWinIdx: Integer; var AFileName,
    AText: string; var AModified: Boolean): Boolean of object;

  // Вид строки сравнения
  TCmpRowKind = (crkEqual, crkDiff, crkFiller);

  // Панель сравнения: TEdRowsView, у строк отличий - свой фон, у
  // изменённых слов - ярче. Фон кладётся при отрисовке (OnLineRuns поверх
  // кусков TEdRowsView): смена текущего отличия - только перерисовка
  TCompareView = class(TEdRowsView)
  private
    FBaseRuns: TEdLineRunsEvent;
    FPrefixLen: Integer;
    FRowKind: array of TCmpRowKind;
    FRowDiff: array of Integer;
    FInline: array of TDiffRanges;   // символы с 1 в тексте строки
    FCurDiff: Integer;
    FCells: array of TEdRun;         // по символу: цвет, фон, начертание
    procedure CmpLineRuns(Sender: TObject; ARow: Integer;
      const ALine: WideString; var ARuns: TEdRuns; var ACount: Integer);
  public
    // Цвета: отличие, слово в нём, пустая строка; у текущего отличия -
    // свои; номера строк у отличий
    DiffBg, InlineBg, FillerBg: TColor;
    CurDiffBg, CurInlineBg, CurFillerBg: TColor;
    GutterDiffBg: TColor;
    constructor Create(AOwner: TComponent); override;
    property CurDiff: Integer read FCurDiff write FCurDiff;
  end;

  // Одна сторона сравнения
  TCompareSide = record
    FileName: string;
    WinIdx: Integer;        // вкладка unIDE; -1 - файл с диска
    Text: string;
    Encoding: string;       // 'UTF-8', 'UTF-8 BOM', 'ANSI'
    Modified: Boolean;      // текст вкладки не сохранён
    Binary: Boolean;        // в начале файла есть #0
    Loaded: Boolean;
  end;

  TDlgFileCompare = class(TForm)
  private
    FSide: array[0..1] of TCompareSide;
    FLines: array[0..1] of TStringList;
    FBlocks: TDiffBlocks;
    FRows: TDiffRows;
    FDiffCount: Integer;
    FDiffFirst, FDiffLast: array of Integer;  // строки отличий в FRows
    FCurDiff: Integer;
    FOptions: TDiffOptions;
    FOnScheme: TGitSchemeEvent;
    FOnTabs: TCompareTabsEvent;
    FOnTabText: TCompareTabTextEvent;
    FTabSize: Integer;
    FSyncing: Boolean;
    FIniFile: string;
    FPlaceSaved: Boolean;
    FLocDragging: Boolean;

    FToolPanel: TUiPanel;
    FBtnPrev, FBtnNext, FBtnFirst, FBtnLast: TUiButton;
    FBtnRefresh, FBtnSwap, FBtnClose: TUiButton;
    FChkCase, FChkSpaceChange, FChkAllSpace: TUiCheckBox;
    FLblDiff: TUiLabel;
    FLblIgnore: TUiLabel;
    FLocPanel: TUiPanel;
    FLocBox: TPaintBox;
    FPanes: TUiPanel;
    FSplit: TSplitter;
    FSidePanel: array[0..1] of TUiPanel;
    FHeadPanel: array[0..1] of TUiPanel;
    FPathEdit: array[0..1] of TUiEdit;
    FBtnBrowse: array[0..1] of TUiButton;
    FBtnTabs: array[0..1] of TUiButton;
    FLblInfo: array[0..1] of TUiLabel;
    FView: array[0..1] of TCompareView;
    FTabsMenu: TPopupMenu;
    FTabsMenuSide: Integer;

    procedure Build;
    procedure BuildSide(ASide: Integer);
    procedure LayoutTool(Sender: TObject);
    procedure LayoutHead(Sender: TObject);
    procedure PanesResize(Sender: TObject);
    procedure Recompare(AKeepPos: Boolean);
    procedure Render;
    procedure UpdateColors;
    procedure UpdateInfo;
    procedure GoDiff(AIndex: Integer);
    function DiffAtRow(ARow: Integer): Integer;
    function CaretRowOf(AView: TCompareView): Integer;
    procedure ViewScroll(Sender: TObject);
    procedure ViewCaretMove(Sender: TObject);
    procedure LocPaint(Sender: TObject);
    procedure LocMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure LocMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure LocMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure LocScrollTo(AY: Integer);
    procedure BtnPrevClick(Sender: TObject);
    procedure BtnNextClick(Sender: TObject);
    procedure BtnFirstClick(Sender: TObject);
    procedure BtnLastClick(Sender: TObject);
    procedure BtnRefreshClick(Sender: TObject);
    procedure BtnSwapClick(Sender: TObject);
    procedure BtnCloseClick(Sender: TObject);
    procedure BtnBrowseClick(Sender: TObject);
    procedure BtnTabsClick(Sender: TObject);
    procedure TabsMenuClick(Sender: TObject);
    procedure PathKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure OptionClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure LoadPlacement;
    procedure SavePlacement;
    function ReloadSide(ASide: Integer): Boolean;
    procedure UMUiThemeChanged(var Message: TMessage); message UM_UITHEMECHANGED;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor CreateDlg(AOwner: TComponent);
    destructor Destroy; override;
    // Сторона ASide (0 - слева, 1 - справа): файл с диска. False - не
    // прочитан (сообщение уже показано)
    function SetSideFile(ASide: Integer; const AFileName: string): Boolean;
    // Сторона - текст вкладки AWinIdx (OnTabText)
    function SetSideTab(ASide, AWinIdx: Integer): Boolean;
    // Сравнить заново и показать с первого отличия
    procedure CompareNow;
    // Схема подсветки по имени файла (Unit1.SchemeCopyFor)
    procedure SetSchemeProvider(AProvider: TGitSchemeEvent);
    // Шрифт панелей (как у редактора) и ширина табуляции
    procedure SetViewFont(AFont: TFont; ATabSize: Integer);
    // Положение окна и параметры сравнения - из файла настроек; при
    // закрытии - туда же
    procedure SetPlacementIni(const AIniFile: string);
    property OnTabs: TCompareTabsEvent read FOnTabs write FOnTabs;
    property OnTabText: TCompareTabTextEvent read FOnTabText write FOnTabText;
  end;

// Текст файла для сравнения: BOM UTF-8 и содержимое -> AEncoding.
// Исключение - файл не прочитан
function CompareReadFile(const AFileName: string; var AEncoding: string;
  var ABinary: Boolean): string;

implementation

const
  CmpSection = 'FileCompareWindow';
  CmpPadMax = 400;        // строки длиннее не дополняются пробелами
  CmpLocWidth = 26;       // ширина полосы обзора

// ---------------------------------------------------------------------------
//  Вспомогательное
// ---------------------------------------------------------------------------

function IsDarkColor(AColor: TColor): Boolean;
var
  ColorRgb: Longint;
begin
  ColorRgb := ColorToRGB(AColor);
  Result := (GetRValue(ColorRgb) * 299 + GetGValue(ColorRgb) * 587 +
    GetBValue(ColorRgb) * 114) div 1000 < 128;
end;

// Табуляции - пробелами до позиции, кратной ATabSize
function ExpandTabsTo(const ALine: string; ATabSize: Integer): string;
var
  CharIdx, OutLen, Spaces: Integer;
begin
  if Pos(#9, ALine) = 0 then
  begin
    Result := ALine;
    Exit;
  end;
  if ATabSize < 1 then
    ATabSize := 1;
  SetLength(Result, Length(ALine) * ATabSize);
  OutLen := 0;
  for CharIdx := 1 to Length(ALine) do
    if ALine[CharIdx] = #9 then
    begin
      Spaces := ATabSize - OutLen mod ATabSize;
      while Spaces > 0 do
      begin
        Inc(OutLen);
        Result[OutLen] := ' ';
        Dec(Spaces);
      end;
    end
    else
    begin
      Inc(OutLen);
      Result[OutLen] := ALine[CharIdx];
    end;
  SetLength(Result, OutLen);
end;

function CompareReadFile(const AFileName: string; var AEncoding: string;
  var ABinary: Boolean): string;
var
  Stream: TFileStream;
  Raw: AnsiString;
  IsUtf8: Boolean;
  ScanLen, ByteIdx: Integer;
begin
  Stream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Raw, Stream.Size);
    if Length(Raw) > 0 then
      Stream.ReadBuffer(Raw[1], Length(Raw));
  finally
    Stream.Free;
  end;
  ABinary := False;
  ScanLen := Length(Raw);
  if ScanLen > 65536 then
    ScanLen := 65536;
  for ByteIdx := 1 to ScanLen do
    if Raw[ByteIdx] = #0 then
    begin
      ABinary := True;
      Break;
    end;
  if (Length(Raw) >= 3) and (Raw[1] = #$EF) and (Raw[2] = #$BB) and
     (Raw[3] = #$BF) then
  begin
    Delete(Raw, 1, 3);
    IsUtf8 := True;
    AEncoding := 'UTF-8 BOM';
  end
  else
  begin
    IsUtf8 := (Length(Raw) > 0) and EdLooksUtf8(PAnsiChar(Raw), Length(Raw));
    if IsUtf8 then
      AEncoding := 'UTF-8'
    else
      AEncoding := 'ANSI';
  end;
  // Строки через #10; символы вне кодовой страницы - '?'
  Result := string(EdDecodeBytes(Raw, IsUtf8));
end;

// ---------------------------------------------------------------------------
//  TCompareView
// ---------------------------------------------------------------------------

constructor TCompareView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // Куски строки даёт TEdRowsView; фон отличий - поверх (CmpLineRuns)
  FBaseRuns := OnLineRuns;
  OnLineRuns := CmpLineRuns;
  FCurDiff := -1;
end;

procedure TCompareView.CmpLineRuns(Sender: TObject; ARow: Integer;
  const ALine: WideString; var ARuns: TEdRuns; var ACount: Integer);
var
  LineLen, RunIdx, CharIdx, RangeIdx, CellIdx, Count: Integer;
  Kind: TCmpRowKind;
  IsCur: Boolean;
  RowBg, WordBg: TColor;
  Range: TDiffRange;
begin
  ACount := 0;
  if Assigned(FBaseRuns) then
    FBaseRuns(Sender, ARow, ALine, ARuns, ACount);
  if (ARow < 0) or (ARow > High(FRowKind)) then
    Exit;
  Kind := FRowKind[ARow];
  if Kind = crkEqual then
    Exit;
  IsCur := FRowDiff[ARow] = FCurDiff;
  if Kind = crkFiller then
  begin
    if IsCur then
      RowBg := CurFillerBg
    else
      RowBg := FillerBg;
  end
  else if IsCur then
    RowBg := CurDiffBg
  else
    RowBg := DiffBg;
  if IsCur then
    WordBg := CurInlineBg
  else
    WordBg := InlineBg;

  // По символу: вид из кусков, потом фон отличия и слов
  LineLen := Length(ALine);
  if Length(FCells) < LineLen then
    SetLength(FCells, LineLen + 64);
  for CharIdx := 0 to LineLen - 1 do
  begin
    FCells[CharIdx].Fore := clNone;
    FCells[CharIdx].Back := clNone;
    FCells[CharIdx].Style := [];
  end;
  for RunIdx := 0 to ACount - 1 do
    for CharIdx := ARuns[RunIdx].Start to
        ARuns[RunIdx].Start + ARuns[RunIdx].Len - 1 do
      if (CharIdx >= 0) and (CharIdx < LineLen) then
      begin
        FCells[CharIdx].Fore := ARuns[RunIdx].Fore;
        FCells[CharIdx].Back := ARuns[RunIdx].Back;
        FCells[CharIdx].Style := ARuns[RunIdx].Style;
      end;
  for CharIdx := 0 to LineLen - 1 do
    if CharIdx < FPrefixLen then
      FCells[CharIdx].Back := GutterDiffBg
    else
      FCells[CharIdx].Back := RowBg;
  if Kind = crkDiff then
    for RangeIdx := 0 to High(FInline[ARow]) do
    begin
      Range := FInline[ARow][RangeIdx];
      for CharIdx := FPrefixLen + Range.Start - 1 to
          FPrefixLen + Range.Start + Range.Len - 2 do
        if (CharIdx >= 0) and (CharIdx < LineLen) then
          FCells[CharIdx].Back := WordBg;
    end;

  // Обратно в куски: соседние символы одного вида - один кусок
  Count := 0;
  CellIdx := 0;
  while CellIdx < LineLen do
  begin
    if Count >= Length(ARuns) then
      SetLength(ARuns, Count * 2 + 8);
    ARuns[Count].Start := CellIdx;
    ARuns[Count].Fore := FCells[CellIdx].Fore;
    ARuns[Count].Back := FCells[CellIdx].Back;
    ARuns[Count].Style := FCells[CellIdx].Style;
    CharIdx := CellIdx + 1;
    while (CharIdx < LineLen) and
          (FCells[CharIdx].Fore = FCells[CellIdx].Fore) and
          (FCells[CharIdx].Back = FCells[CellIdx].Back) and
          (FCells[CharIdx].Style = FCells[CellIdx].Style) do
      Inc(CharIdx);
    ARuns[Count].Len := CharIdx - CellIdx;
    Inc(Count);
    CellIdx := CharIdx;
  end;
  ACount := Count;
end;

// ---------------------------------------------------------------------------
//  TDlgFileCompare - окно
// ---------------------------------------------------------------------------

constructor TDlgFileCompare.CreateDlg(AOwner: TComponent);
var
  SideIdx: Integer;
begin
  inherited CreateNew(AOwner);
  for SideIdx := 0 to 1 do
  begin
    FLines[SideIdx] := TStringList.Create;
    FSide[SideIdx].WinIdx := -1;
    FSide[SideIdx].Loaded := False;
  end;
  FOptions := DiffDefaultOptions;
  FTabSize := 4;
  FCurDiff := -1;
  Build;
  UiThemeAddClient(Self);
end;

destructor TDlgFileCompare.Destroy;
var
  SideIdx: Integer;
begin
  UiThemeRemoveClient(Self);
  if not FPlaceSaved then
    SavePlacement;
  for SideIdx := 0 to 1 do
    FLines[SideIdx].Free;
  inherited Destroy;
end;

// Владелец окна - главное окно: окно над ним, а не под ним
procedure TDlgFileCompare.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  if (Owner is TWinControl) and TWinControl(Owner).HandleAllocated then
    Params.WndParent := TWinControl(Owner).Handle;
end;

procedure TDlgFileCompare.Build;

  function MakeButton(AParent: TWinControl; const ACaption, AHint: string;
    AOnClick: TNotifyEvent): TUiButton;
  begin
    Result := TUiButton.Create(Self);
    Result.Parent := AParent;
    Result.Caption := ACaption;
    Result.Hint := AHint;
    Result.ShowHint := True;
    Result.OnClick := AOnClick;
  end;

  function MakeCheck(const ACaption, AHint: string): TUiCheckBox;
  begin
    Result := TUiCheckBox.Create(Self);
    Result.Parent := FToolPanel;
    Result.Caption := ACaption;
    Result.Hint := AHint;
    Result.ShowHint := True;
    Result.OnClick := OptionClick;
  end;

begin
  Caption := 'Сравнение файлов';
  OnClose := FormClose;
  OnKeyDown := FormKeyDown;
  KeyPreview := True;
  Position := poMainFormCenter;
  BorderStyle := bsSizeable;
  BorderIcons := [biSystemMenu, biMinimize, biMaximize];
  Width := 1200;
  Height := 700;
  Constraints.MinWidth := 640;
  Constraints.MinHeight := 360;

  FToolPanel := TUiPanel.Create(Self);
  FToolPanel.Parent := Self;
  FToolPanel.Align := alTop;
  FToolPanel.Height := 34;
  FToolPanel.BevelOuter := bvNone;
  FToolPanel.Caption := '';

  FBtnPrev := MakeButton(FToolPanel, '< Пред.',
    'Предыдущее отличие (Alt+Up, F7)', BtnPrevClick);
  FBtnNext := MakeButton(FToolPanel, 'След. >',
    'Следующее отличие (Alt+Down, F8)', BtnNextClick);
  FBtnFirst := MakeButton(FToolPanel, 'Первое',
    'Первое отличие (Alt+Home)', BtnFirstClick);
  FBtnLast := MakeButton(FToolPanel, 'Последнее',
    'Последнее отличие (Alt+End)', BtnLastClick);
  FBtnRefresh := MakeButton(FToolPanel, 'Обновить',
    'Перечитать файлы и сравнить заново (F5)', BtnRefreshClick);
  FBtnSwap := MakeButton(FToolPanel, 'Местами',
    'Левая и правая стороны - местами', BtnSwapClick);
  FLblIgnore := TUiLabel.Create(Self);
  FLblIgnore.Parent := FToolPanel;
  FLblIgnore.AutoSize := True;
  FLblIgnore.Caption := 'Не учитывать:';
  FChkCase := MakeCheck('регистр',
    'Строки, отличающиеся только регистром букв, - одинаковые');
  FChkSpaceChange := MakeCheck('число пробелов',
    'Число пробелов и табуляций между словами, пробелы в начале и в ' +
    'конце строки не учитываются');
  FChkAllSpace := MakeCheck('все пробелы',
    'Пробелы и табуляции не учитываются совсем');
  FBtnClose := MakeButton(FToolPanel, 'Закрыть', 'Закрыть окно (Esc)',
    BtnCloseClick);

  FLblDiff := TUiLabel.Create(Self);
  FLblDiff.Parent := FToolPanel;
  FLblDiff.AutoSize := True;
  FLblDiff.Caption := '';
  // Раскладка - когда все кнопки уже есть
  FToolPanel.OnResize := LayoutTool;

  // Слева - полоса обзора
  FLocPanel := TUiPanel.Create(Self);
  FLocPanel.Parent := Self;
  FLocPanel.Align := alLeft;
  FLocPanel.Width := CmpLocWidth;
  FLocPanel.BevelOuter := bvNone;
  FLocPanel.Caption := '';
  FLocBox := TPaintBox.Create(Self);
  FLocBox.Parent := FLocPanel;
  FLocBox.Align := alClient;
  FLocBox.OnPaint := LocPaint;
  FLocBox.OnMouseDown := LocMouseDown;
  FLocBox.OnMouseMove := LocMouseMove;
  FLocBox.OnMouseUp := LocMouseUp;

  FPanes := TUiPanel.Create(Self);
  FPanes.Parent := Self;
  FPanes.Align := alClient;
  FPanes.BevelOuter := bvNone;
  FPanes.Caption := '';
  FPanes.OnResize := PanesResize;

  BuildSide(0);
  FSplit := TSplitter.Create(Self);
  FSplit.Parent := FPanes;
  FSplit.Align := alLeft;
  FSplit.Left := FSidePanel[0].Width + 1;
  FSplit.Width := 5;
  BuildSide(1);

  FTabsMenu := TPopupMenu.Create(Self);

  UpdateColors;
  UpdateInfo;
end;

procedure TDlgFileCompare.BuildSide(ASide: Integer);
var
  Side: TUiPanel;
begin
  Side := TUiPanel.Create(Self);
  Side.Parent := FPanes;
  if ASide = 0 then
  begin
    Side.Align := alLeft;
    Side.Width := 500;
  end
  else
    Side.Align := alClient;
  Side.BevelOuter := bvNone;
  Side.Caption := '';
  FSidePanel[ASide] := Side;

  FHeadPanel[ASide] := TUiPanel.Create(Self);
  FHeadPanel[ASide].Parent := Side;
  FHeadPanel[ASide].Align := alTop;
  FHeadPanel[ASide].Height := 28;
  FHeadPanel[ASide].BevelOuter := bvNone;
  FHeadPanel[ASide].Caption := '';
  FHeadPanel[ASide].Tag := ASide;

  FPathEdit[ASide] := TUiEdit.Create(Self);
  FPathEdit[ASide].Parent := FHeadPanel[ASide];
  FPathEdit[ASide].Tag := ASide;
  FPathEdit[ASide].Hint := 'Путь к файлу; Enter - открыть';
  FPathEdit[ASide].ShowHint := True;
  FPathEdit[ASide].OnKeyDown := PathKeyDown;

  FBtnBrowse[ASide] := TUiButton.Create(Self);
  FBtnBrowse[ASide].Parent := FHeadPanel[ASide];
  FBtnBrowse[ASide].Caption := '...';
  FBtnBrowse[ASide].Hint := 'Выбрать файл';
  FBtnBrowse[ASide].ShowHint := True;
  FBtnBrowse[ASide].Tag := ASide;
  FBtnBrowse[ASide].OnClick := BtnBrowseClick;

  FBtnTabs[ASide] := TUiButton.Create(Self);
  FBtnTabs[ASide].Parent := FHeadPanel[ASide];
  FBtnTabs[ASide].Caption := 'Вкладка...';
  FBtnTabs[ASide].Hint := 'Текст открытой вкладки unIDE (с несохранёнными ' +
    'правками)';
  FBtnTabs[ASide].ShowHint := True;
  FBtnTabs[ASide].Tag := ASide;
  FBtnTabs[ASide].OnClick := BtnTabsClick;
  FHeadPanel[ASide].OnResize := LayoutHead;

  FLblInfo[ASide] := TUiLabel.Create(Self);
  FLblInfo[ASide].Parent := Side;
  FLblInfo[ASide].Align := alBottom;
  FLblInfo[ASide].AutoSize := False;
  FLblInfo[ASide].Height := 18;
  FLblInfo[ASide].Caption := '';

  FView[ASide] := TCompareView.Create(Self);
  FView[ASide].Parent := Side;
  FView[ASide].Align := alClient;
  FView[ASide].Font.Name := 'Courier New';
  FView[ASide].Font.Size := 9;
  FView[ASide].Tag := ASide;
  FView[ASide].OnViewScroll := ViewScroll;
  FView[ASide].OnCaretMove := ViewCaretMove;
end;

procedure TDlgFileCompare.LayoutTool(Sender: TObject);
const
  BtnGap = 6;
  BtnH = 24;
var
  BtnTop, PosLeft: Integer;

  procedure Place(ACtl: TControl; AWidth: Integer);
  begin
    ACtl.SetBounds(PosLeft, BtnTop, AWidth, BtnH);
    Inc(PosLeft, AWidth + BtnGap);
  end;

begin
  BtnTop := (FToolPanel.ClientHeight - BtnH) div 2;
  // Слева - «Отличие N из M», потом кнопки
  FLblDiff.Left := 8;
  FLblDiff.Top := BtnTop + (BtnH - FLblDiff.Height) div 2;
  PosLeft := 8 + 128;
  Place(FBtnFirst, 70);
  Place(FBtnPrev, 64);
  Place(FBtnNext, 64);
  Place(FBtnLast, 80);
  Inc(PosLeft, BtnGap);
  Place(FBtnRefresh, 76);
  Place(FBtnSwap, 70);
  Inc(PosLeft, BtnGap);
  FLblIgnore.Left := PosLeft;
  FLblIgnore.Top := BtnTop + (BtnH - FLblIgnore.Height) div 2;
  Inc(PosLeft, FLblIgnore.Width + BtnGap);
  Place(FChkCase, 76);
  Place(FChkSpaceChange, 122);
  Place(FChkAllSpace, 104);
  FBtnClose.SetBounds(FToolPanel.ClientWidth - 80, BtnTop, 76, BtnH);
end;

procedure TDlgFileCompare.LayoutHead(Sender: TObject);
const
  BtnH = 22;
var
  SideIdx, BtnTop, PanelW: Integer;
begin
  SideIdx := TComponent(Sender).Tag;
  PanelW := FHeadPanel[SideIdx].ClientWidth;
  BtnTop := (FHeadPanel[SideIdx].ClientHeight - BtnH) div 2;
  FBtnTabs[SideIdx].SetBounds(PanelW - 80, BtnTop, 78, BtnH);
  FBtnBrowse[SideIdx].SetBounds(PanelW - 112, BtnTop, 28, BtnH);
  FPathEdit[SideIdx].SetBounds(2, BtnTop, PanelW - 118, BtnH);
end;

// Панели - поровну
procedure TDlgFileCompare.PanesResize(Sender: TObject);
begin
  if (FSidePanel[0] <> nil) and (FSplit <> nil) then
    FSidePanel[0].Width := (FPanes.ClientWidth - FSplit.Width) div 2;
end;

procedure TDlgFileCompare.SetSchemeProvider(AProvider: TGitSchemeEvent);
begin
  FOnScheme := AProvider;
end;

procedure TDlgFileCompare.SetViewFont(AFont: TFont; ATabSize: Integer);
var
  SideIdx: Integer;
begin
  for SideIdx := 0 to 1 do
  begin
    FView[SideIdx].Font.Name := AFont.Name;
    FView[SideIdx].Font.Size := AFont.Size;
    FView[SideIdx].Font.Charset := AFont.Charset;
  end;
  if ATabSize > 0 then
    FTabSize := ATabSize;
end;

// ---------------------------------------------------------------------------
//  Стороны
// ---------------------------------------------------------------------------

function TDlgFileCompare.SetSideFile(ASide: Integer;
  const AFileName: string): Boolean;
var
  Text, Encoding: string;
  IsBinary: Boolean;
begin
  Result := False;
  if not FileExists(AFileName) then
  begin
    MessageDlg('Файла нет:'#13#10 + AFileName, mtWarning, [mbOK], 0);
    Exit;
  end;
  try
    Text := CompareReadFile(AFileName, Encoding, IsBinary);
  except
    on Error: Exception do
    begin
      MessageDlg('Файл не прочитан:'#13#10 + AFileName + #13#10#13#10 +
        Error.Message, mtWarning, [mbOK], 0);
      Exit;
    end;
  end;
  FSide[ASide].FileName := AFileName;
  FSide[ASide].WinIdx := -1;
  FSide[ASide].Text := Text;
  FSide[ASide].Encoding := Encoding;
  FSide[ASide].Binary := IsBinary;
  FSide[ASide].Modified := False;
  FSide[ASide].Loaded := True;
  FPathEdit[ASide].Text := AFileName;
  Result := True;
end;

function TDlgFileCompare.SetSideTab(ASide, AWinIdx: Integer): Boolean;
var
  FileName, Text: string;
  IsModified: Boolean;
begin
  Result := False;
  if not Assigned(FOnTabText) then
    Exit;
  FileName := '';
  Text := '';
  IsModified := False;
  if not FOnTabText(AWinIdx, FileName, Text, IsModified) then
    Exit;
  FSide[ASide].FileName := FileName;
  FSide[ASide].WinIdx := AWinIdx;
  FSide[ASide].Text := Text;
  FSide[ASide].Encoding := 'вкладка';
  FSide[ASide].Binary := False;
  FSide[ASide].Modified := IsModified;
  FSide[ASide].Loaded := True;
  FPathEdit[ASide].Text := FileName;
  Result := True;
end;

// Сторона заново: вкладка - текст вкладки сейчас, файл - с диска
function TDlgFileCompare.ReloadSide(ASide: Integer): Boolean;
begin
  Result := False;
  if not FSide[ASide].Loaded then
    Exit;
  if FSide[ASide].WinIdx >= 0 then
    Result := SetSideTab(ASide, FSide[ASide].WinIdx)
  else
    Result := SetSideFile(ASide, FSide[ASide].FileName);
end;

// ---------------------------------------------------------------------------
//  Сравнение и показ
// ---------------------------------------------------------------------------

procedure TDlgFileCompare.CompareNow;
begin
  Recompare(False);
end;

procedure TDlgFileCompare.Recompare(AKeepPos: Boolean);
var
  SideIdx, RowIdx, DiffIdx, KeepTop, KeepCaret, RowCount: Integer;
  OldCursor: TCursor;
begin
  KeepTop := FView[0].TopRow;
  KeepCaret := CaretRowOf(FView[0]);
  OldCursor := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  try
    for SideIdx := 0 to 1 do
      FLines[SideIdx].Text := FSide[SideIdx].Text;
    if FSide[0].Loaded and FSide[1].Loaded then
    begin
      FBlocks := DiffLines(FLines[0], FLines[1], FOptions);
      FRows := DiffAlign(FBlocks);
      FDiffCount := DiffCount(FBlocks);
    end
    else
    begin
      // Вторая сторона не выбрана - текст одной стороны без отличий
      FBlocks := nil;
      FDiffCount := 0;
      RowCount := FLines[0].Count;
      if FLines[1].Count > RowCount then
        RowCount := FLines[1].Count;
      SetLength(FRows, RowCount);
      for RowIdx := 0 to RowCount - 1 do
      begin
        FRows[RowIdx].LeftLine := -1;
        FRows[RowIdx].RightLine := -1;
        if RowIdx < FLines[0].Count then
          FRows[RowIdx].LeftLine := RowIdx;
        if RowIdx < FLines[1].Count then
          FRows[RowIdx].RightLine := RowIdx;
        FRows[RowIdx].DiffIndex := -1;
      end;
    end;
    SetLength(FDiffFirst, FDiffCount);
    SetLength(FDiffLast, FDiffCount);
    for RowIdx := 0 to High(FRows) do
    begin
      DiffIdx := FRows[RowIdx].DiffIndex;
      if DiffIdx < 0 then
        Continue;
      if (RowIdx = 0) or (FRows[RowIdx - 1].DiffIndex <> DiffIdx) then
        FDiffFirst[DiffIdx] := RowIdx;
      FDiffLast[DiffIdx] := RowIdx;
    end;
    Render;
  finally
    Screen.Cursor := OldCursor;
  end;

  if AKeepPos then
  begin
    FView[0].ScrollTo(KeepTop, 0);
    FView[0].CaretTo(KeepCaret, 0);
    FCurDiff := DiffAtRow(KeepCaret);
    FView[0].CurDiff := FCurDiff;
    FView[1].CurDiff := FCurDiff;
    UpdateInfo;
  end
  else if FDiffCount > 0 then
    GoDiff(0)
  else
  begin
    FCurDiff := -1;
    UpdateInfo;
  end;
  FLocBox.Invalidate;
end;

// Цвета отличий - по фону панели (тёмный / светлый)
procedure TDlgFileCompare.UpdateColors;
var
  SideIdx: Integer;
  View: TCompareView;
begin
  for SideIdx := 0 to 1 do
  begin
    View := FView[SideIdx];
    if IsDarkColor(View.BackColor) then
    begin
      View.DiffBg := $00284050;
      View.InlineBg := $00306A88;
      View.FillerBg := $00262626;
      View.CurDiffBg := $00584A20;
      View.CurInlineBg := $00207A90;
      View.CurFillerBg := $00585858;
      View.GutterDiffBg := $00303A44;
    end
    else
    begin
      // Как в WinMerge: отличие - жёлтым, текущее - голубым, нет строк -
      // серым, изменённые слова - ярче
      View.DiffBg := $00C8F0FF;
      View.InlineBg := $0060DCFF;
      View.FillerBg := $00E4E4E4;
      View.CurDiffBg := $00FFF0B4;
      View.CurInlineBg := $0000F0FF;
      View.CurFillerBg := $00C8C8C8;
      View.GutterDiffBg := $00D0E4EC;
    end;
    View.SelColor := UiThemeColor('Menu.HotBG');
    View.SelTextColor := UiThemeColor('Menu.HotText');
  end;
end;

procedure TDlgFileCompare.Render;
var
  SideIdx, RowIdx, LineIdx, MaxWidth, Digits, PairLine: Integer;
  Rows: TSchemeRows;
  Scheme: TClrScheme;
  PageBg, TextFg: TColor;
  View: TCompareView;
  Texts: array[0..1] of TStringList;
  BlankPrefix: string;
  LeftRanges, RightRanges: TDiffRanges;
begin
  // Тексты строк с раскрытыми табуляциями; ширина полос - по самой
  // длинной строке обеих сторон
  MaxWidth := 0;
  for SideIdx := 0 to 1 do
  begin
    Texts[SideIdx] := TStringList.Create;
    for LineIdx := 0 to FLines[SideIdx].Count - 1 do
    begin
      Texts[SideIdx].Add(ExpandTabsTo(FLines[SideIdx][LineIdx], FTabSize));
      if (Length(Texts[SideIdx][LineIdx]) <= CmpPadMax) and
         (Length(Texts[SideIdx][LineIdx]) > MaxWidth) then
        MaxWidth := Length(Texts[SideIdx][LineIdx]);
    end;
  end;
  Inc(MaxWidth, 2);
  Digits := Length(IntToStr(FLines[0].Count));
  if Length(IntToStr(FLines[1].Count)) > Digits then
    Digits := Length(IntToStr(FLines[1].Count));
  if Digits < 4 then
    Digits := 4;
  BlankPrefix := StringOfChar(' ', Digits + 1);

  // ShowRows ставит каретку и прокрутку в начало - панели не согласовывать
  FSyncing := True;
  try
    for SideIdx := 0 to 1 do
    begin
      View := FView[SideIdx];
      SetLength(Rows, Length(FRows));
      SetLength(View.FRowKind, Length(FRows));
      SetLength(View.FRowDiff, Length(FRows));
      SetLength(View.FInline, Length(FRows));
      View.FPrefixLen := Length(BlankPrefix);
      for RowIdx := 0 to High(FRows) do
      begin
        if SideIdx = 0 then
          LineIdx := FRows[RowIdx].LeftLine
        else
          LineIdx := FRows[RowIdx].RightLine;
        if LineIdx >= 0 then
        begin
          Rows[RowIdx].Prefix := StringOfChar(' ',
            Digits - Length(IntToStr(LineIdx + 1))) + IntToStr(LineIdx + 1) + ' ';
          Rows[RowIdx].Text := Texts[SideIdx][LineIdx];
          Rows[RowIdx].Highlight := True;
        end
        else
        begin
          Rows[RowIdx].Prefix := BlankPrefix;
          Rows[RowIdx].Text := '';
          Rows[RowIdx].Highlight := False;
        end;
        Rows[RowIdx].PrefixFg := $00808080;
        Rows[RowIdx].PrefixBg := clNone;
        Rows[RowIdx].Lead := '';
        Rows[RowIdx].TextFg := clNone;
        Rows[RowIdx].RowBg := clNone;
        Rows[RowIdx].PadTo := MaxWidth;
        Rows[RowIdx].ResetBlock := False;

        View.FRowDiff[RowIdx] := FRows[RowIdx].DiffIndex;
        View.FInline[RowIdx] := nil;
        if FRows[RowIdx].DiffIndex < 0 then
          View.FRowKind[RowIdx] := crkEqual
        else if LineIdx < 0 then
          View.FRowKind[RowIdx] := crkFiller
        else
          View.FRowKind[RowIdx] := crkDiff;
      end;

      Scheme := nil;
      try
        if Assigned(FOnScheme) and (FSide[SideIdx].FileName <> '') then
          Scheme := FOnScheme(FSide[SideIdx].FileName);
        if Scheme <> nil then
        begin
          PageBg := SchemePageColor(Scheme);
          TextFg := Scheme.FTextFG;
          if (TextFg = clNone) or (TextFg = clDefault) then
            TextFg := clWindowText;
        end
        else
        begin
          PageBg := UiThemeColor('Edit.BG');
          TextFg := UiThemeColor('Edit.Text');
        end;
        View.ShowRows(Rows, Scheme, TextFg, PageBg);
      finally
        Scheme.Free;
      end;
    end;

    // Изменённые слова в парах строк
    for RowIdx := 0 to High(FRows) do
      if (FRows[RowIdx].DiffIndex >= 0) and (FRows[RowIdx].LeftLine >= 0) and
         (FRows[RowIdx].RightLine >= 0) then
      begin
        PairLine := FRows[RowIdx].RightLine;
        DiffInline(Texts[0][FRows[RowIdx].LeftLine], Texts[1][PairLine],
          FOptions, LeftRanges, RightRanges);
        FView[0].FInline[RowIdx] := LeftRanges;
        FView[1].FInline[RowIdx] := RightRanges;
      end;
  finally
    FSyncing := False;
    Texts[0].Free;
    Texts[1].Free;
  end;
  UpdateColors;
  for SideIdx := 0 to 1 do
    FView[SideIdx].Invalidate;
end;

procedure TDlgFileCompare.UpdateInfo;
var
  SideIdx: Integer;
  Info: string;
begin
  for SideIdx := 0 to 1 do
  begin
    if not FSide[SideIdx].Loaded then
    begin
      FLblInfo[SideIdx].Caption := '  Файл не выбран';
      Continue;
    end;
    Info := '  Строк: ' + IntToStr(FLines[SideIdx].Count) + '   ' +
      FSide[SideIdx].Encoding;
    if FSide[SideIdx].Modified then
      Info := Info + ', не сохранено';
    if FSide[SideIdx].Binary then
      Info := Info + '   двоичный файл';
    FLblInfo[SideIdx].Caption := Info;
  end;
  if not FSide[0].Loaded or not FSide[1].Loaded then
    FLblDiff.Caption := ''
  else if FDiffCount = 0 then
    FLblDiff.Caption := 'Отличий нет'
  else if FCurDiff >= 0 then
    FLblDiff.Caption := 'Отличие ' + IntToStr(FCurDiff + 1) + ' из ' +
      IntToStr(FDiffCount)
  else
    FLblDiff.Caption := 'Отличий: ' + IntToStr(FDiffCount);
  Caption := 'Сравнение - ' + ExtractFileName(FSide[0].FileName) + ' и ' +
    ExtractFileName(FSide[1].FileName);
  FBtnPrev.Enabled := FDiffCount > 0;
  FBtnNext.Enabled := FDiffCount > 0;
  FBtnFirst.Enabled := FDiffCount > 0;
  FBtnLast.Enabled := FDiffCount > 0;
end;

// ---------------------------------------------------------------------------
//  Переходы
// ---------------------------------------------------------------------------

function TDlgFileCompare.DiffAtRow(ARow: Integer): Integer;
begin
  Result := -1;
  if (ARow >= 0) and (ARow <= High(FRows)) then
    Result := FRows[ARow].DiffIndex;
end;

function TDlgFileCompare.CaretRowOf(AView: TCompareView): Integer;
begin
  Result := AView.CaretRow;
end;

procedure TDlgFileCompare.GoDiff(AIndex: Integer);
var
  SideIdx, Row, Top: Integer;
begin
  if FDiffCount = 0 then
    Exit;
  if AIndex < 0 then
    AIndex := 0;
  if AIndex > FDiffCount - 1 then
    AIndex := FDiffCount - 1;
  FCurDiff := AIndex;
  Row := FDiffFirst[AIndex];
  // Отличие - на треть окна от верха
  Top := Row - FView[0].VisibleRows div 3;
  if Top < 0 then
    Top := 0;
  FSyncing := True;
  try
    for SideIdx := 0 to 1 do
    begin
      FView[SideIdx].CurDiff := FCurDiff;
      FView[SideIdx].CaretTo(Row, 0);
      FView[SideIdx].ScrollTo(Top, FView[SideIdx].LeftCol);
      FView[SideIdx].Invalidate;
    end;
  finally
    FSyncing := False;
  end;
  UpdateInfo;
  FLocBox.Invalidate;
end;

// Предыдущее отличие: выше отличия под кареткой (или выше каретки)
procedure TDlgFileCompare.BtnPrevClick(Sender: TObject);
var
  Row, DiffIdx: Integer;
begin
  if FDiffCount = 0 then
    Exit;
  Row := CaretRowOf(FView[0]);
  DiffIdx := DiffAtRow(Row);
  if DiffIdx >= 0 then
    Row := FDiffFirst[DiffIdx];
  for DiffIdx := FDiffCount - 1 downto 0 do
    if FDiffLast[DiffIdx] < Row then
    begin
      GoDiff(DiffIdx);
      Exit;
    end;
  GoDiff(0);
end;

// Следующее отличие: ниже отличия под кареткой (или ниже каретки)
procedure TDlgFileCompare.BtnNextClick(Sender: TObject);
var
  Row, DiffIdx: Integer;
begin
  if FDiffCount = 0 then
    Exit;
  Row := CaretRowOf(FView[0]);
  DiffIdx := DiffAtRow(Row);
  if DiffIdx >= 0 then
    Row := FDiffLast[DiffIdx];
  for DiffIdx := 0 to FDiffCount - 1 do
    if FDiffFirst[DiffIdx] > Row then
    begin
      GoDiff(DiffIdx);
      Exit;
    end;
  GoDiff(FDiffCount - 1);
end;

procedure TDlgFileCompare.BtnFirstClick(Sender: TObject);
begin
  GoDiff(0);
end;

procedure TDlgFileCompare.BtnLastClick(Sender: TObject);
begin
  GoDiff(FDiffCount - 1);
end;

// Прокрутка одной панели - и другой
procedure TDlgFileCompare.ViewScroll(Sender: TObject);
var
  Source, Target: TCompareView;
begin
  if FSyncing then
    Exit;
  Source := Sender as TCompareView;
  Target := FView[1 - Source.Tag];
  FSyncing := True;
  try
    Target.ScrollTo(Source.TopRow, Source.LeftCol);
  finally
    FSyncing := False;
  end;
  FLocBox.Invalidate;
end;

// Каретка в одной панели - та же строка в другой; текущее отличие - под
// кареткой
procedure TDlgFileCompare.ViewCaretMove(Sender: TObject);
var
  Source, Target: TCompareView;
  Row, DiffIdx, SideIdx: Integer;
begin
  if FSyncing then
    Exit;
  Source := Sender as TCompareView;
  Target := FView[1 - Source.Tag];
  Row := Source.CaretRow;
  FSyncing := True;
  try
    if Target.CaretRow <> Row then
      Target.CaretTo(Row, 0);
    Target.ScrollTo(Source.TopRow, Source.LeftCol);
  finally
    FSyncing := False;
  end;
  DiffIdx := DiffAtRow(Row);
  if (DiffIdx >= 0) and (DiffIdx <> FCurDiff) then
  begin
    FCurDiff := DiffIdx;
    for SideIdx := 0 to 1 do
    begin
      FView[SideIdx].CurDiff := FCurDiff;
      FView[SideIdx].Invalidate;
    end;
    UpdateInfo;
  end;
  FLocBox.Invalidate;
end;

// ---------------------------------------------------------------------------
//  Полоса обзора
// ---------------------------------------------------------------------------

procedure TDlgFileCompare.LocPaint(Sender: TObject);
var
  Canvas: TCanvas;
  BoxW, BoxH, RowCount, DiffIdx, TopY, BottomY, ColW, SideIdx, RowIdx: Integer;
  ViewTop, ViewBottom: Integer;
  HasLines: Boolean;
  PageBg, LineColor: TColor;
begin
  Canvas := FLocBox.Canvas;
  BoxW := FLocBox.Width;
  BoxH := FLocBox.Height;
  PageBg := FView[0].BackColor;
  Canvas.Brush.Color := PageBg;
  Canvas.FillRect(Rect(0, 0, BoxW, BoxH));
  RowCount := Length(FRows);
  if (RowCount = 0) or (BoxH <= 0) then
    Exit;
  ColW := (BoxW - 6) div 2;
  for DiffIdx := 0 to FDiffCount - 1 do
  begin
    TopY := Int64(FDiffFirst[DiffIdx]) * BoxH div RowCount;
    BottomY := Int64(FDiffLast[DiffIdx] + 1) * BoxH div RowCount;
    if BottomY < TopY + 2 then
      BottomY := TopY + 2;
    for SideIdx := 0 to 1 do
    begin
      // У стороны в отличии есть свои строки - цвет отличия, нет - серый
      HasLines := False;
      for RowIdx := FDiffFirst[DiffIdx] to FDiffLast[DiffIdx] do
        if ((SideIdx = 0) and (FRows[RowIdx].LeftLine >= 0)) or
           ((SideIdx = 1) and (FRows[RowIdx].RightLine >= 0)) then
        begin
          HasLines := True;
          Break;
        end;
      if DiffIdx = FCurDiff then
      begin
        if HasLines then
          LineColor := FView[SideIdx].CurDiffBg
        else
          LineColor := FView[SideIdx].CurFillerBg;
      end
      else if HasLines then
        LineColor := FView[SideIdx].InlineBg
      else
        LineColor := FView[SideIdx].CurFillerBg;
      Canvas.Brush.Color := LineColor;
      Canvas.FillRect(Rect(2 + SideIdx * (ColW + 2), TopY,
        2 + SideIdx * (ColW + 2) + ColW, BottomY));
    end;
  end;
  // Видимая часть
  ViewTop := Int64(FView[0].TopRow) * BoxH div RowCount;
  ViewBottom := Int64(FView[0].TopRow + FView[0].VisibleRows) * BoxH div RowCount;
  if ViewBottom > BoxH then
    ViewBottom := BoxH;
  if ViewBottom < ViewTop + 3 then
    ViewBottom := ViewTop + 3;
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Color := FView[0].TextColor;
  Canvas.Rectangle(0, ViewTop, BoxW, ViewBottom);
  Canvas.Brush.Style := bsSolid;
end;

procedure TDlgFileCompare.LocScrollTo(AY: Integer);
var
  Row, Top: Integer;
begin
  if (Length(FRows) = 0) or (FLocBox.Height <= 0) then
    Exit;
  Row := Int64(AY) * Length(FRows) div FLocBox.Height;
  Top := Row - FView[0].VisibleRows div 2;
  if Top < 0 then
    Top := 0;
  FView[0].ScrollTo(Top, FView[0].LeftCol);   // вторую - ViewScroll
  FLocBox.Invalidate;
end;

procedure TDlgFileCompare.LocMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then
    Exit;
  FLocDragging := True;
  LocScrollTo(Y);
end;

procedure TDlgFileCompare.LocMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  if FLocDragging and (ssLeft in Shift) then
    LocScrollTo(Y);
end;

procedure TDlgFileCompare.LocMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FLocDragging := False;
end;

// ---------------------------------------------------------------------------
//  Кнопки и клавиши
// ---------------------------------------------------------------------------

procedure TDlgFileCompare.BtnRefreshClick(Sender: TObject);
begin
  ReloadSide(0);
  ReloadSide(1);
  Recompare(True);
end;

procedure TDlgFileCompare.BtnSwapClick(Sender: TObject);
var
  Temp: TCompareSide;
begin
  Temp := FSide[0];
  FSide[0] := FSide[1];
  FSide[1] := Temp;
  FPathEdit[0].Text := FSide[0].FileName;
  FPathEdit[1].Text := FSide[1].FileName;
  Recompare(True);
end;

procedure TDlgFileCompare.BtnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TDlgFileCompare.BtnBrowseClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
  SideIdx: Integer;
begin
  SideIdx := TComponent(Sender).Tag;
  OpenDlg := TOpenDialog.Create(Self);
  try
    OpenDlg.Title := 'Файл для сравнения';
    OpenDlg.Filter := 'Все файлы (*.*)|*.*';
    OpenDlg.Options := [ofFileMustExist, ofHideReadOnly, ofEnableSizing];
    if FSide[SideIdx].FileName <> '' then
      OpenDlg.InitialDir := ExtractFileDir(FSide[SideIdx].FileName)
    else if FSide[1 - SideIdx].FileName <> '' then
      OpenDlg.InitialDir := ExtractFileDir(FSide[1 - SideIdx].FileName);
    if not OpenDlg.Execute then
      Exit;
    if SetSideFile(SideIdx, OpenDlg.FileName) then
      Recompare(False);
  finally
    OpenDlg.Free;
  end;
end;

procedure TDlgFileCompare.BtnTabsClick(Sender: TObject);
var
  Tabs: TStringList;
  TabIdx: Integer;
  Item: TMenuItem;
  ScreenPt: TPoint;
  Button: TUiButton;
begin
  if not Assigned(FOnTabs) then
    Exit;
  Button := Sender as TUiButton;
  FTabsMenuSide := Button.Tag;
  FTabsMenu.Items.Clear;
  Tabs := TStringList.Create;
  try
    FOnTabs(Tabs);
    for TabIdx := 0 to Tabs.Count - 1 do
    begin
      Item := TMenuItem.Create(FTabsMenu);
      Item.Caption := Tabs[TabIdx];
      Item.Tag := Integer(Tabs.Objects[TabIdx]);
      Item.OnClick := TabsMenuClick;
      FTabsMenu.Items.Add(Item);
    end;
  finally
    Tabs.Free;
  end;
  if FTabsMenu.Items.Count = 0 then
    Exit;
  ScreenPt := Button.ClientToScreen(Point(0, Button.Height));
  FTabsMenu.Popup(ScreenPt.X, ScreenPt.Y);
end;

procedure TDlgFileCompare.TabsMenuClick(Sender: TObject);
begin
  if SetSideTab(FTabsMenuSide, TMenuItem(Sender).Tag) then
    Recompare(False);
end;

procedure TDlgFileCompare.PathKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  SideIdx: Integer;
  FileName: string;
begin
  if Key <> VK_RETURN then
    Exit;
  Key := 0;
  SideIdx := TComponent(Sender).Tag;
  FileName := Trim(FPathEdit[SideIdx].Text);
  if (FileName <> '') and (FileName[1] = '"') then
    FileName := Copy(FileName, 2, Length(FileName) - 2);
  if (FileName <> '') and SetSideFile(SideIdx, FileName) then
    Recompare(False);
end;

procedure TDlgFileCompare.OptionClick(Sender: TObject);
begin
  FOptions.IgnoreCase := FChkCase.Checked;
  FOptions.IgnoreSpaceChange := FChkSpaceChange.Checked;
  FOptions.IgnoreAllSpace := FChkAllSpace.Checked;
  if FSide[0].Loaded and FSide[1].Loaded then
    Recompare(True);
end;

procedure TDlgFileCompare.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // В поле пути клавиши - свои
  if (ActiveControl is TUiEdit) and (Key <> VK_ESCAPE) and
     (Key <> VK_F5) then
    Exit;
  if (Key = VK_DOWN) and (ssAlt in Shift) or (Key = VK_F8) then
    BtnNextClick(nil)
  else if (Key = VK_UP) and (ssAlt in Shift) or (Key = VK_F7) then
    BtnPrevClick(nil)
  else if (Key = VK_HOME) and (ssAlt in Shift) then
    BtnFirstClick(nil)
  else if (Key = VK_END) and (ssAlt in Shift) then
    BtnLastClick(nil)
  else if Key = VK_F5 then
    BtnRefreshClick(nil)
  else if Key = VK_ESCAPE then
    Close
  else
    Exit;
  Key := 0;
end;

procedure TDlgFileCompare.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SavePlacement;
  Action := caFree;
end;

procedure TDlgFileCompare.UMUiThemeChanged(var Message: TMessage);
begin
  if FSide[0].Loaded or FSide[1].Loaded then
    Recompare(True)
  else
    UpdateColors;
  Message.Result := 1;
end;

// ---------------------------------------------------------------------------
//  Положение окна и параметры
// ---------------------------------------------------------------------------

procedure TDlgFileCompare.SetPlacementIni(const AIniFile: string);
begin
  FIniFile := AIniFile;
  LoadPlacement;
end;

procedure TDlgFileCompare.LoadPlacement;
var
  Ini: TBufIniFile;
  WinLeft, WinTop, WinWidth, WinHeight: Integer;
  Work: TRect;
begin
  if (FIniFile = '') or not FileExists(FIniFile) then
    Exit;
  Ini := TBufIniFile.Create(FIniFile);
  try
    WinWidth := Ini.ReadInteger(CmpSection, 'Width', 0);
    WinHeight := Ini.ReadInteger(CmpSection, 'Height', 0);
    if (WinWidth >= Constraints.MinWidth) and
       (WinHeight >= Constraints.MinHeight) then
    begin
      WinLeft := Ini.ReadInteger(CmpSection, 'Left', Left);
      WinTop := Ini.ReadInteger(CmpSection, 'Top', Top);
      Work := Screen.DesktopRect;
      if WinWidth > Work.Right - Work.Left then
        WinWidth := Work.Right - Work.Left;
      if WinHeight > Work.Bottom - Work.Top then
        WinHeight := Work.Bottom - Work.Top;
      if WinLeft + WinWidth > Work.Right then
        WinLeft := Work.Right - WinWidth;
      if WinTop + WinHeight > Work.Bottom then
        WinTop := Work.Bottom - WinHeight;
      if WinLeft < Work.Left then
        WinLeft := Work.Left;
      if WinTop < Work.Top then
        WinTop := Work.Top;
      Position := poDesigned;
      SetBounds(WinLeft, WinTop, WinWidth, WinHeight);
    end;
    if Ini.ReadBool(CmpSection, 'Maximized', False) then
      WindowState := wsMaximized;
    FChkCase.Checked := Ini.ReadBool(CmpSection, 'IgnoreCase', False);
    FChkSpaceChange.Checked := Ini.ReadBool(CmpSection, 'IgnoreSpaceChange',
      False);
    FChkAllSpace.Checked := Ini.ReadBool(CmpSection, 'IgnoreAllSpace', False);
    FOptions.IgnoreCase := FChkCase.Checked;
    FOptions.IgnoreSpaceChange := FChkSpaceChange.Checked;
    FOptions.IgnoreAllSpace := FChkAllSpace.Checked;
  finally
    Ini.Free;
  end;
end;

procedure TDlgFileCompare.SavePlacement;
var
  Ini: TBufIniFile;
  Place: TWindowPlacement;
begin
  FPlaceSaved := True;
  if (FIniFile = '') or not HandleAllocated then
    Exit;
  Place.length := SizeOf(Place);
  if not GetWindowPlacement(Handle, @Place) then
    Exit;
  Ini := TBufIniFile.Create(FIniFile);
  try
    Ini.WriteInteger(CmpSection, 'Left', Place.rcNormalPosition.Left);
    Ini.WriteInteger(CmpSection, 'Top', Place.rcNormalPosition.Top);
    Ini.WriteInteger(CmpSection, 'Width', Place.rcNormalPosition.Right -
      Place.rcNormalPosition.Left);
    Ini.WriteInteger(CmpSection, 'Height', Place.rcNormalPosition.Bottom -
      Place.rcNormalPosition.Top);
    Ini.WriteBool(CmpSection, 'Maximized', WindowState = wsMaximized);
    Ini.WriteBool(CmpSection, 'IgnoreCase', FOptions.IgnoreCase);
    Ini.WriteBool(CmpSection, 'IgnoreSpaceChange', FOptions.IgnoreSpaceChange);
    Ini.WriteBool(CmpSection, 'IgnoreAllSpace', FOptions.IgnoreAllSpace);
  finally
    Ini.Free;
  end;
end;

end.
