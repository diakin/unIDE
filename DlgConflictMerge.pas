unit DlgConflictMerge;

// ---------------------------------------------------------------------------
//  Разбор конфликтов git (как в WinMerge): панель Git - Conflicts...
//
//  Файл с маркерами <<<<<<< ======= >>>>>>> показывается в двух панелях:
//  слева - версия текущей ветки (части от <<<<<<< до =======), справа -
//  вливаемая (от ======= до >>>>>>>). Общие строки вне конфликтов - в
//  обеих панелях одинаковые. Внутри конфликта строки выравниваются и
//  сравниваются (TextDiff), изменённые слова - ярче, как в окне
//  сравнения файлов (DlgFileCompare, TCompareView).
//
//  По каждому конфликту - выбор: текущая, вливаемая, обе (в одном или
//  другом порядке) или не выбрано. Взятая сторона - зелёным, отброшенная
//  - серым текстом. Внизу - результат: каким станет файл; у
//  невыбранного конфликта - маркеры как есть.
//
//  Сохранить - результат в файл: байты строк - как в файле (кодировка,
//  CR LF / LF, BOM не меняются), у невыбранных конфликтов маркеры
//  остаются. После записи файл перечитывается: остаются только
//  невыбранные конфликты. Часть ||||||| (стиль diff3) в результат не
//  попадает ни с какой стороны.
//
//  Клавиши: Alt+Left - текущая, Alt+Right - вливаемая, Alt+Up / F7,
//  Alt+Down / F8 - конфликт выше / ниже, Ctrl+S - сохранить, Esc -
//  закрыть. Двойной щелчок в панели по конфликту - взять эту сторону.
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
  UiStdCtrls,    // TUiLabel, TUiPanel
  UiTheme,       // UiThemeColor, UM_UITHEMECHANGED
  ClrScheme, SchemeRtf, EdView, EdRows, EdFileText,
  GitDiffView,   // TGitSchemeEvent
  IniBuf,        // TBufIniFile - положение окна
  TextDiff,
  DlgFileCompare; // TCompareView, CompareViewColors, CompareExpandTabs

type
  // Что взять из конфликта в результат
  TConflictChoice = (ccNone, ccOurs, ccTheirs, ccOursTheirs, ccTheirsOurs);

  // Открыть файл в редакторе unIDE на строке ALine (с 1)
  TConflictOpenEvent = procedure(const AFileName: string;
    ALine: Integer) of object;
  // Файл записан окном - перечитать открытые вкладки, обновить панель Git
  TConflictSavedEvent = procedure(const AFileName: string) of object;

  // Конфликт в файле: номера строк маркеров (с 0, в FRaw); BaseLine -
  // строка ||||||| (-1 - нет)
  TMergeConflict = record
    StartLine, BaseLine, SepLine, EndLine: Integer;
    OursLabel, TheirsLabel: string;
    Choice: TConflictChoice;
  end;

  TRawLines = array of AnsiString;

  TDlgConflictMerge = class(TForm)
  private
    FFileName: string;
    FRawText: AnsiString;         // файл как прочитан (без BOM)
    FRaw: TRawLines;              // строки - байты как в файле (с #13)
    FHasBom, FIsUtf8: Boolean;
    FConf: array of TMergeConflict;
    FModified: Boolean;
    FRepoRoot: string;
    FFiles: TStringList;          // файлы с конфликтом: пути git

    // Две панели: строки версий и строки окна
    FLines: array[0..1] of TStringList;
    FRows: TDiffRows;
    FDiffFirst, FDiffLast: array of Integer;
    FCurDiff: Integer;
    // Результат: строки, отличие строки, строки конфликтов
    FResLines: TStringList;
    FResDiff: array of Integer;
    FResFirst, FResLast: array of Integer;

    FOptions: TDiffOptions;
    FOnScheme: TGitSchemeEvent;
    FOnOpenLine: TConflictOpenEvent;
    FOnSaved: TConflictSavedEvent;
    FTabSize: Integer;
    FSyncing: Boolean;
    FIniFile: string;
    FPlaceSaved: Boolean;

    FToolPanel: TUiPanel;
    FLblConf: TUiLabel;
    FBtnPrev, FBtnNext: TUiButton;
    FBtnOurs, FBtnTheirs, FBtnOursTheirs, FBtnTheirsOurs, FBtnUndo: TUiButton;
    FBtnFile, FBtnAllOurs, FBtnAllTheirs, FBtnEditor: TUiButton;
    FBtnSave, FBtnClose: TUiButton;
    FPanes: TUiPanel;
    FSplit: TSplitter;
    FSidePanel: array[0..1] of TUiPanel;
    FHeadLabel: array[0..1] of TUiLabel;
    FView: array[0..1] of TCompareView;
    FResSplit: TSplitter;
    FResPanel: TUiPanel;
    FResHead: TUiLabel;
    FResView: TCompareView;
    FStatusPanel: TUiPanel;
    FLblStatus: TUiLabel;
    FFilesMenu: TPopupMenu;

    procedure Build;
    procedure BuildSide(ASide: Integer);
    procedure LayoutTool(Sender: TObject);
    procedure PanesResize(Sender: TObject);
    function ConflictCount: Integer;
    function OpenCount: Integer;
    function DisplayLine(const ARaw: AnsiString): string;
    procedure ParseConflicts;
    procedure OursRange(AConf: Integer; var AFirst, ALast: Integer);
    procedure TheirsRange(AConf: Integer; var AFirst, ALast: Integer);
    procedure BuildRows;
    procedure BuildResult;
    function ResultText: AnsiString;
    procedure RenderSides;
    procedure RenderResult;
    procedure RenderView(AView: TCompareView; const ARows: TSchemeRows);
    procedure UpdateMarks;
    procedure UpdateInfo;
    procedure GoDiff(AIndex: Integer);
    procedure ScrollResult;
    procedure SetChoice(AConf: Integer; AChoice: TConflictChoice;
      AAdvance: Boolean);
    procedure SetAllChoice(AChoice: TConflictChoice);
    function SaveFile: Boolean;
    function AskSave: Boolean;
    procedure ViewScroll(Sender: TObject);
    procedure ViewCaretMove(Sender: TObject);
    procedure ResCaretMove(Sender: TObject);
    procedure ViewDblClick(Sender: TObject);
    procedure BtnPrevClick(Sender: TObject);
    procedure BtnNextClick(Sender: TObject);
    procedure BtnChoiceClick(Sender: TObject);
    procedure BtnAllClick(Sender: TObject);
    procedure BtnFileClick(Sender: TObject);
    procedure FilesMenuClick(Sender: TObject);
    procedure BtnEditorClick(Sender: TObject);
    procedure BtnSaveClick(Sender: TObject);
    procedure BtnCloseClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure LoadPlacement;
    procedure SavePlacement;
    procedure UMUiThemeChanged(var Message: TMessage); message UM_UITHEMECHANGED;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor CreateDlg(AOwner: TComponent);
    destructor Destroy; override;
    // Файл с конфликтами. False - не прочитан (сообщение уже показано)
    function LoadFile(const AFileName: string): Boolean;
    // Все файлы с конфликтом (пути git от корня ARepoRoot) - для кнопки
    // «Файл...»
    procedure SetFiles(const ARepoRoot: string; AFiles: TStrings);
    procedure SetSchemeProvider(AProvider: TGitSchemeEvent);
    procedure SetViewFont(AFont: TFont; ATabSize: Integer);
    procedure SetPlacementIni(const AIniFile: string);
    property OnOpenLine: TConflictOpenEvent read FOnOpenLine write FOnOpenLine;
    property OnSaved: TConflictSavedEvent read FOnSaved write FOnSaved;
  end;

// Сколько конфликтов (строк <<<<<<< в начале) в файле AFileName
function ConflictMarkerCount(const AFileName: string): Integer;

implementation

const
  MergeSection = 'ConflictMergeWindow';
  MergePadMax = 400;     // строки длиннее не дополняются пробелами

// ---------------------------------------------------------------------------
//  Вспомогательное
// ---------------------------------------------------------------------------

function ReadRawFile(const AFileName: string): AnsiString;
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Result, Stream.Size);
    if Length(Result) > 0 then
      Stream.ReadBuffer(Result[1], Length(Result));
  finally
    Stream.Free;
  end;
end;

// Строки через #10; #13 перед #10 остаётся в строке. Текст с #10 в конце
// - последняя строка пустая: склейка через #10 даёт исходный текст
function SplitRaw(const AText: AnsiString): TRawLines;
var
  Count, LineStart, CharIdx: Integer;
begin
  Result := nil;
  Count := 0;
  LineStart := 1;
  for CharIdx := 1 to Length(AText) do
    if AText[CharIdx] = #10 then
    begin
      SetLength(Result, Count + 1);
      Result[Count] := Copy(AText, LineStart, CharIdx - LineStart);
      Inc(Count);
      LineStart := CharIdx + 1;
    end;
  SetLength(Result, Count + 1);
  Result[Count] := Copy(AText, LineStart, MaxInt);
end;

function StripCR(const ALine: AnsiString): AnsiString;
begin
  Result := ALine;
  if (Result <> '') and (Result[Length(Result)] = #13) then
    SetLength(Result, Length(Result) - 1);
end;

function IsMarker(const ALine: AnsiString; AChar: AnsiChar): Boolean;
begin
  Result := (Length(ALine) >= 7) and
    (Copy(ALine, 1, 7) = StringOfChar(AChar, 7));
end;

function ConflictMarkerCount(const AFileName: string): Integer;
var
  Lines: TRawLines;
  LineIdx: Integer;
begin
  Result := 0;
  if not FileExists(AFileName) then
    Exit;
  try
    Lines := SplitRaw(ReadRawFile(AFileName));
  except
    Exit;
  end;
  for LineIdx := 0 to High(Lines) do
    if IsMarker(Lines[LineIdx], '<') then
      Inc(Result);
end;

function NewSchemeRow(const APrefix, AText: string;
  AHighlight: Boolean; APadTo: Integer): TSchemeRow;
begin
  Result.Prefix := APrefix;
  Result.PrefixFg := $00808080;
  Result.PrefixBg := clNone;
  Result.Lead := '';
  Result.Text := AText;
  Result.Highlight := AHighlight;
  Result.TextFg := clNone;
  Result.RowBg := clNone;
  Result.PadTo := APadTo;
  Result.ResetBlock := False;
end;

// ---------------------------------------------------------------------------
//  Окно
// ---------------------------------------------------------------------------

constructor TDlgConflictMerge.CreateDlg(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  FLines[0] := TStringList.Create;
  FLines[1] := TStringList.Create;
  FResLines := TStringList.Create;
  FFiles := TStringList.Create;
  FOptions := DiffDefaultOptions;
  FTabSize := 4;
  FCurDiff := -1;
  Build;
  UiThemeAddClient(Self);
end;

destructor TDlgConflictMerge.Destroy;
begin
  UiThemeRemoveClient(Self);
  if not FPlaceSaved then
    SavePlacement;
  FLines[0].Free;
  FLines[1].Free;
  FResLines.Free;
  FFiles.Free;
  inherited Destroy;
end;

procedure TDlgConflictMerge.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  if (Owner is TWinControl) and TWinControl(Owner).HandleAllocated then
    Params.WndParent := TWinControl(Owner).Handle;
end;

procedure TDlgConflictMerge.Build;

  function MakeButton(const ACaption, AHint: string;
    AOnClick: TNotifyEvent; ATag: Integer): TUiButton;
  begin
    Result := TUiButton.Create(Self);
    Result.Parent := FToolPanel;
    Result.Caption := ACaption;
    Result.Hint := AHint;
    Result.ShowHint := True;
    Result.OnClick := AOnClick;
    Result.Tag := ATag;
  end;

begin
  Caption := 'Конфликты';
  OnClose := FormClose;
  OnCloseQuery := FormCloseQuery;
  OnKeyDown := FormKeyDown;
  KeyPreview := True;
  Position := poMainFormCenter;
  BorderStyle := bsSizeable;
  BorderIcons := [biSystemMenu, biMinimize, biMaximize];
  Width := 1200;
  Height := 760;
  Constraints.MinWidth := 760;
  Constraints.MinHeight := 420;

  FToolPanel := TUiPanel.Create(Self);
  FToolPanel.Parent := Self;
  FToolPanel.Align := alTop;
  FToolPanel.Height := 62;
  FToolPanel.BevelOuter := bvNone;
  FToolPanel.Caption := '';

  FLblConf := TUiLabel.Create(Self);
  FLblConf.Parent := FToolPanel;
  FLblConf.AutoSize := True;
  FLblConf.Caption := '';
  FBtnPrev := MakeButton('< Пред.', 'Конфликт выше (Alt+Up, F7)',
    BtnPrevClick, 0);
  FBtnNext := MakeButton('След. >', 'Конфликт ниже (Alt+Down, F8)',
    BtnNextClick, 0);
  FBtnOurs := MakeButton('<< Текущая', 'Взять строки текущей ветки ' +
    '(левая панель) (Alt+Left; двойной щелчок слева)', BtnChoiceClick,
    Ord(ccOurs));
  FBtnTheirs := MakeButton('Вливаемое >>', 'Взять вливаемые строки ' +
    '(правая панель) (Alt+Right; двойной щелчок справа)', BtnChoiceClick,
    Ord(ccTheirs));
  FBtnOursTheirs := MakeButton('Обе: текущая, затем вливаемое',
    'Взять обе стороны: сначала строки текущей ветки, за ними вливаемые',
    BtnChoiceClick, Ord(ccOursTheirs));
  FBtnTheirsOurs := MakeButton('Обе: вливаемое, затем текущая',
    'Взять обе стороны: сначала вливаемые строки, за ними текущей ветки',
    BtnChoiceClick, Ord(ccTheirsOurs));
  FBtnUndo := MakeButton('Не выбрано', 'Отменить выбор: в результате - ' +
    'конфликт с маркерами', BtnChoiceClick, Ord(ccNone));

  FBtnFile := MakeButton('Файл...', 'Другой файл с конфликтом',
    BtnFileClick, 0);
  FBtnAllOurs := MakeButton('Все невыбранные - текущая', 'Во всех ' +
    'невыбранных конфликтах файла взять текущую ветку', BtnAllClick,
    Ord(ccOurs));
  FBtnAllTheirs := MakeButton('Все невыбранные - вливаемое', 'Во всех ' +
    'невыбранных конфликтах файла взять вливаемое', BtnAllClick,
    Ord(ccTheirs));
  FBtnEditor := MakeButton('В редакторе', 'Открыть файл в редакторе unIDE ' +
    'на текущем конфликте - править вручную', BtnEditorClick, 0);
  FBtnSave := MakeButton('Сохранить', 'Записать результат в файл (Ctrl+S); ' +
    'невыбранные конфликты остаются с маркерами', BtnSaveClick, 0);
  FBtnClose := MakeButton('Закрыть', 'Закрыть окно (Esc)', BtnCloseClick, 0);
  FToolPanel.OnResize := LayoutTool;

  // Строка состояния - на панели: цвета темы у панели, не у формы
  FStatusPanel := TUiPanel.Create(Self);
  FStatusPanel.Parent := Self;
  FStatusPanel.Align := alBottom;
  FStatusPanel.Height := 20;
  FStatusPanel.BevelOuter := bvNone;
  FStatusPanel.Caption := '';
  FLblStatus := TUiLabel.Create(Self);
  FLblStatus.Parent := FStatusPanel;
  FLblStatus.Align := alClient;
  FLblStatus.AutoSize := False;
  FLblStatus.Caption := '';

  // Внизу - результат
  FResPanel := TUiPanel.Create(Self);
  FResPanel.Parent := Self;
  FResPanel.Align := alBottom;
  FResPanel.Height := 220;
  FResPanel.BevelOuter := bvNone;
  FResPanel.Caption := '';
  FResHead := TUiLabel.Create(Self);
  FResHead.Parent := FResPanel;
  FResHead.Align := alTop;
  FResHead.AutoSize := False;
  FResHead.Height := 20;
  FResHead.Caption := '  Результат';
  FResView := TCompareView.Create(Self);
  FResView.Parent := FResPanel;
  FResView.Align := alClient;
  FResView.Font.Name := 'Courier New';
  FResView.Font.Size := 9;
  FResView.Tag := 2;
  FResView.OnCaretMove := ResCaretMove;

  FResSplit := TSplitter.Create(Self);
  FResSplit.Parent := Self;
  FResSplit.Align := alBottom;
  FResSplit.Height := 5;
  FResSplit.Top := FResPanel.Top - 5;

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

  // Снизу вверх: строка состояния, результат, разделитель
  FStatusPanel.Top := 30000;
  FResPanel.Top := 20000;
  FResSplit.Top := 10000;

  FFilesMenu := TPopupMenu.Create(Self);
  CompareViewColors(FView[0]);
  CompareViewColors(FView[1]);
  CompareViewColors(FResView);
  UpdateInfo;
end;

procedure TDlgConflictMerge.BuildSide(ASide: Integer);
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

  FHeadLabel[ASide] := TUiLabel.Create(Self);
  FHeadLabel[ASide].Parent := Side;
  FHeadLabel[ASide].Align := alTop;
  FHeadLabel[ASide].AutoSize := False;
  FHeadLabel[ASide].Height := 20;
  FHeadLabel[ASide].Caption := '';

  FView[ASide] := TCompareView.Create(Self);
  FView[ASide].Parent := Side;
  FView[ASide].Align := alClient;
  FView[ASide].Font.Name := 'Courier New';
  FView[ASide].Font.Size := 9;
  FView[ASide].Tag := ASide;
  FView[ASide].OnViewScroll := ViewScroll;
  FView[ASide].OnCaretMove := ViewCaretMove;
  FView[ASide].OnDblClick := ViewDblClick;
end;

procedure TDlgConflictMerge.LayoutTool(Sender: TObject);
const
  BtnGap = 6;
  BtnH = 24;
var
  RowTop, PosLeft: Integer;

  procedure Place(ACtl: TControl; AWidth: Integer);
  begin
    ACtl.SetBounds(PosLeft, RowTop, AWidth, BtnH);
    Inc(PosLeft, AWidth + BtnGap);
  end;

begin
  // Первый ряд: «Конфликт N из M», переходы, выбор
  RowTop := 4;
  FLblConf.Left := 8;
  FLblConf.Top := RowTop + (BtnH - FLblConf.Height) div 2;
  PosLeft := 8 + 190;
  Place(FBtnPrev, 64);
  Place(FBtnNext, 64);
  Inc(PosLeft, BtnGap * 2);
  Place(FBtnOurs, 96);
  Place(FBtnTheirs, 104);
  Place(FBtnOursTheirs, 200);
  Place(FBtnTheirsOurs, 200);
  Place(FBtnUndo, 90);
  // Второй ряд: файл, все сразу, редактор; справа - сохранить, закрыть
  RowTop := 4 + BtnH + 6;
  PosLeft := 8;
  Place(FBtnFile, 76);
  Inc(PosLeft, BtnGap * 2);
  Place(FBtnAllOurs, 184);
  Place(FBtnAllTheirs, 196);
  Inc(PosLeft, BtnGap * 2);
  Place(FBtnEditor, 96);
  FBtnClose.SetBounds(FToolPanel.ClientWidth - 80, RowTop, 76, BtnH);
  FBtnSave.SetBounds(FToolPanel.ClientWidth - 80 - 96, RowTop, 90, BtnH);
end;

procedure TDlgConflictMerge.PanesResize(Sender: TObject);
begin
  if (FSidePanel[0] <> nil) and (FSplit <> nil) then
    FSidePanel[0].Width := (FPanes.ClientWidth - FSplit.Width) div 2;
end;

procedure TDlgConflictMerge.SetSchemeProvider(AProvider: TGitSchemeEvent);
begin
  FOnScheme := AProvider;
end;

procedure TDlgConflictMerge.SetViewFont(AFont: TFont; ATabSize: Integer);
var
  SideIdx: Integer;
  View: TCompareView;
begin
  for SideIdx := 0 to 2 do
  begin
    if SideIdx = 2 then
      View := FResView
    else
      View := FView[SideIdx];
    View.Font.Name := AFont.Name;
    View.Font.Size := AFont.Size;
    View.Font.Charset := AFont.Charset;
  end;
  if ATabSize > 0 then
    FTabSize := ATabSize;
end;

procedure TDlgConflictMerge.SetFiles(const ARepoRoot: string; AFiles: TStrings);
begin
  FRepoRoot := ARepoRoot;
  FFiles.Assign(AFiles);
end;

// ---------------------------------------------------------------------------
//  Файл и конфликты
// ---------------------------------------------------------------------------

function TDlgConflictMerge.ConflictCount: Integer;
begin
  Result := Length(FConf);
end;

// Сколько конфликтов без выбора
function TDlgConflictMerge.OpenCount: Integer;
var
  ConfIdx: Integer;
begin
  Result := 0;
  for ConfIdx := 0 to High(FConf) do
    if FConf[ConfIdx].Choice = ccNone then
      Inc(Result);
end;

function TDlgConflictMerge.DisplayLine(const ARaw: AnsiString): string;
begin
  Result := string(EdDecodeBytes(StripCR(ARaw), FIsUtf8));
end;

function TDlgConflictMerge.LoadFile(const AFileName: string): Boolean;
var
  Text: AnsiString;
begin
  Result := False;
  try
    Text := ReadRawFile(AFileName);
  except
    on Error: Exception do
    begin
      MessageDlg('Файл не прочитан:'#13#10 + AFileName + #13#10#13#10 +
        Error.Message, mtWarning, [mbOK], 0);
      Exit;
    end;
  end;
  FHasBom := (Length(Text) >= 3) and (Text[1] = #$EF) and (Text[2] = #$BB) and
    (Text[3] = #$BF);
  if FHasBom then
    Delete(Text, 1, 3);
  FIsUtf8 := FHasBom or
    ((Length(Text) > 0) and EdLooksUtf8(PAnsiChar(Text), Length(Text)));
  FFileName := AFileName;
  FRawText := Text;
  FRaw := SplitRaw(Text);
  ParseConflicts;
  FModified := False;
  BuildRows;
  BuildResult;
  RenderSides;
  RenderResult;
  UpdateMarks;
  if ConflictCount > 0 then
    GoDiff(0)
  else
  begin
    FCurDiff := -1;
    FResView.ScrollTo(0, 0);
    UpdateInfo;
  end;
  Result := True;
end;

// Блоки <<<<<<< [||||||| ...] ======= >>>>>>>; незакрытый блок - текст
procedure TDlgConflictMerge.ParseConflicts;
var
  LineIdx, Part, Count: Integer;
  Line: AnsiString;
  Cur: TMergeConflict;
begin
  SetLength(FConf, 0);
  Count := 0;
  Part := 0;   // 0 - вне блока, 1 - текущая, 2 - общая, 3 - вливаемое
  Cur.StartLine := -1;
  for LineIdx := 0 to High(FRaw) do
  begin
    Line := StripCR(FRaw[LineIdx]);
    if (Part = 0) and IsMarker(Line, '<') then
    begin
      Cur.StartLine := LineIdx;
      Cur.BaseLine := -1;
      Cur.SepLine := -1;
      Cur.OursLabel := Trim(DisplayLine(Copy(Line, 8, MaxInt)));
      Cur.TheirsLabel := '';
      Cur.Choice := ccNone;
      Part := 1;
    end
    else if (Part = 1) and IsMarker(Line, '|') then
    begin
      Cur.BaseLine := LineIdx;
      Part := 2;
    end
    else if (Part in [1, 2]) and (TrimRight(Line) = '=======') then
    begin
      Cur.SepLine := LineIdx;
      Part := 3;
    end
    else if (Part = 3) and IsMarker(Line, '>') then
    begin
      Cur.EndLine := LineIdx;
      Cur.TheirsLabel := Trim(DisplayLine(Copy(Line, 8, MaxInt)));
      SetLength(FConf, Count + 1);
      FConf[Count] := Cur;
      Inc(Count);
      Part := 0;
    end;
  end;
end;

procedure TDlgConflictMerge.OursRange(AConf: Integer;
  var AFirst, ALast: Integer);
begin
  AFirst := FConf[AConf].StartLine + 1;
  if FConf[AConf].BaseLine >= 0 then
    ALast := FConf[AConf].BaseLine - 1
  else
    ALast := FConf[AConf].SepLine - 1;
end;

procedure TDlgConflictMerge.TheirsRange(AConf: Integer;
  var AFirst, ALast: Integer);
begin
  AFirst := FConf[AConf].SepLine + 1;
  ALast := FConf[AConf].EndLine - 1;
end;

// Строки двух панелей: общие - друг против друга, в конфликте -
// выровнены по разнице (TextDiff), короткая сторона - пустыми строками
procedure TDlgConflictMerge.BuildRows;
var
  RowCount, RawIdx, ConfIdx, LineIdx, AlignIdx, LeftBase, RightBase: Integer;
  OursFirst, OursLast, TheirsFirst, TheirsLast: Integer;
  OursList, TheirsList: TStringList;
  Aligned: TDiffRows;

  procedure AddRow(ALeft, ARight, ADiff: Integer);
  begin
    if RowCount >= Length(FRows) then
      SetLength(FRows, RowCount * 2 + 64);
    FRows[RowCount].LeftLine := ALeft;
    FRows[RowCount].RightLine := ARight;
    FRows[RowCount].DiffIndex := ADiff;
    Inc(RowCount);
  end;

  procedure AddCommon(AFrom, ATo: Integer);
  var
    CommonIdx: Integer;
  begin
    for CommonIdx := AFrom to ATo do
    begin
      FLines[0].Add(DisplayLine(FRaw[CommonIdx]));
      FLines[1].Add(DisplayLine(FRaw[CommonIdx]));
      AddRow(FLines[0].Count - 1, FLines[1].Count - 1, -1);
    end;
  end;

begin
  FLines[0].Clear;
  FLines[1].Clear;
  SetLength(FRows, 0);
  RowCount := 0;
  SetLength(FDiffFirst, ConflictCount);
  SetLength(FDiffLast, ConflictCount);
  RawIdx := 0;
  OursList := TStringList.Create;
  TheirsList := TStringList.Create;
  try
    for ConfIdx := 0 to ConflictCount - 1 do
    begin
      AddCommon(RawIdx, FConf[ConfIdx].StartLine - 1);
      OursRange(ConfIdx, OursFirst, OursLast);
      TheirsRange(ConfIdx, TheirsFirst, TheirsLast);
      OursList.Clear;
      TheirsList.Clear;
      for LineIdx := OursFirst to OursLast do
        OursList.Add(DisplayLine(FRaw[LineIdx]));
      for LineIdx := TheirsFirst to TheirsLast do
        TheirsList.Add(DisplayLine(FRaw[LineIdx]));
      LeftBase := FLines[0].Count;
      RightBase := FLines[1].Count;
      FLines[0].AddStrings(OursList);
      FLines[1].AddStrings(TheirsList);
      Aligned := DiffAlign(DiffLines(OursList, TheirsList, FOptions));
      FDiffFirst[ConfIdx] := RowCount;
      for AlignIdx := 0 to High(Aligned) do
      begin
        if Aligned[AlignIdx].LeftLine >= 0 then
          Aligned[AlignIdx].LeftLine := LeftBase + Aligned[AlignIdx].LeftLine;
        if Aligned[AlignIdx].RightLine >= 0 then
          Aligned[AlignIdx].RightLine :=
            RightBase + Aligned[AlignIdx].RightLine;
        AddRow(Aligned[AlignIdx].LeftLine, Aligned[AlignIdx].RightLine,
          ConfIdx);
      end;
      // Обе стороны пустые - одна пустая строка, чтобы конфликт был виден
      if Length(Aligned) = 0 then
        AddRow(-1, -1, ConfIdx);
      FDiffLast[ConfIdx] := RowCount - 1;
      RawIdx := FConf[ConfIdx].EndLine + 1;
    end;
    AddCommon(RawIdx, High(FRaw));
  finally
    TheirsList.Free;
    OursList.Free;
  end;
  SetLength(FRows, RowCount);
end;

// Строки результата: общие, у выбранного конфликта - взятые строки, у
// невыбранного - весь блок с маркерами
procedure TDlgConflictMerge.BuildResult;
var
  RawIdx, ConfIdx, Count: Integer;
  OursFirst, OursLast, TheirsFirst, TheirsLast: Integer;

  procedure AddLines(AFrom, ATo, ADiff: Integer);
  var
    LineIdx: Integer;
  begin
    for LineIdx := AFrom to ATo do
    begin
      FResLines.Add(DisplayLine(FRaw[LineIdx]));
      if Count >= Length(FResDiff) then
        SetLength(FResDiff, Count * 2 + 64);
      FResDiff[Count] := ADiff;
      Inc(Count);
    end;
  end;

begin
  FResLines.Clear;
  SetLength(FResDiff, 0);
  Count := 0;
  SetLength(FResFirst, ConflictCount);
  SetLength(FResLast, ConflictCount);
  RawIdx := 0;
  for ConfIdx := 0 to ConflictCount - 1 do
  begin
    AddLines(RawIdx, FConf[ConfIdx].StartLine - 1, -1);
    OursRange(ConfIdx, OursFirst, OursLast);
    TheirsRange(ConfIdx, TheirsFirst, TheirsLast);
    FResFirst[ConfIdx] := Count;
    case FConf[ConfIdx].Choice of
      ccOurs:
        AddLines(OursFirst, OursLast, ConfIdx);
      ccTheirs:
        AddLines(TheirsFirst, TheirsLast, ConfIdx);
      ccOursTheirs:
        begin
          AddLines(OursFirst, OursLast, ConfIdx);
          AddLines(TheirsFirst, TheirsLast, ConfIdx);
        end;
      ccTheirsOurs:
        begin
          AddLines(TheirsFirst, TheirsLast, ConfIdx);
          AddLines(OursFirst, OursLast, ConfIdx);
        end;
    else
      AddLines(FConf[ConfIdx].StartLine, FConf[ConfIdx].EndLine, ConfIdx);
    end;
    FResLast[ConfIdx] := Count - 1;
    RawIdx := FConf[ConfIdx].EndLine + 1;
  end;
  AddLines(RawIdx, High(FRaw), -1);
  SetLength(FResDiff, Count);
end;

// Текст результата - байты строк файла через #10 (без BOM)
function TDlgConflictMerge.ResultText: AnsiString;
var
  Parts: TRawLines;
  Count, RawIdx, ConfIdx: Integer;
  OursFirst, OursLast, TheirsFirst, TheirsLast: Integer;

  procedure AddLines(AFrom, ATo: Integer);
  var
    LineIdx: Integer;
  begin
    for LineIdx := AFrom to ATo do
    begin
      if Count >= Length(Parts) then
        SetLength(Parts, Count * 2 + 64);
      Parts[Count] := FRaw[LineIdx];
      Inc(Count);
    end;
  end;

var
  TotalLen, PartIdx, OutPos: Integer;
begin
  Parts := nil;
  Count := 0;
  RawIdx := 0;
  for ConfIdx := 0 to ConflictCount - 1 do
  begin
    AddLines(RawIdx, FConf[ConfIdx].StartLine - 1);
    OursRange(ConfIdx, OursFirst, OursLast);
    TheirsRange(ConfIdx, TheirsFirst, TheirsLast);
    case FConf[ConfIdx].Choice of
      ccOurs:
        AddLines(OursFirst, OursLast);
      ccTheirs:
        AddLines(TheirsFirst, TheirsLast);
      ccOursTheirs:
        begin
          AddLines(OursFirst, OursLast);
          AddLines(TheirsFirst, TheirsLast);
        end;
      ccTheirsOurs:
        begin
          AddLines(TheirsFirst, TheirsLast);
          AddLines(OursFirst, OursLast);
        end;
    else
      AddLines(FConf[ConfIdx].StartLine, FConf[ConfIdx].EndLine);
    end;
    RawIdx := FConf[ConfIdx].EndLine + 1;
  end;
  AddLines(RawIdx, High(FRaw));
  // Склейка через #10
  TotalLen := 0;
  for PartIdx := 0 to Count - 1 do
    Inc(TotalLen, Length(Parts[PartIdx]) + 1);
  if TotalLen > 0 then
    Dec(TotalLen);
  SetLength(Result, TotalLen);
  OutPos := 1;
  for PartIdx := 0 to Count - 1 do
  begin
    if Length(Parts[PartIdx]) > 0 then
    begin
      Move(Parts[PartIdx][1], Result[OutPos], Length(Parts[PartIdx]));
      Inc(OutPos, Length(Parts[PartIdx]));
    end;
    if PartIdx < Count - 1 then
    begin
      Result[OutPos] := #10;
      Inc(OutPos);
    end;
  end;
end;

// ---------------------------------------------------------------------------
//  Показ
// ---------------------------------------------------------------------------

procedure TDlgConflictMerge.RenderView(AView: TCompareView;
  const ARows: TSchemeRows);
var
  Scheme: TClrScheme;
  PageBg, TextFg: TColor;
begin
  Scheme := nil;
  try
    if Assigned(FOnScheme) and (FFileName <> '') then
      Scheme := FOnScheme(FFileName);
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
    AView.ShowRows(ARows, Scheme, TextFg, PageBg);
  finally
    Scheme.Free;
  end;
  CompareViewColors(AView);
end;

procedure TDlgConflictMerge.RenderSides;
var
  SideIdx, RowIdx, LineIdx, MaxWidth, Digits: Integer;
  Rows: TSchemeRows;
  View: TCompareView;
  Texts: array[0..1] of TStringList;
  BlankPrefix: string;
  LeftRanges, RightRanges: TDiffRanges;
begin
  MaxWidth := 0;
  for SideIdx := 0 to 1 do
  begin
    Texts[SideIdx] := TStringList.Create;
    for LineIdx := 0 to FLines[SideIdx].Count - 1 do
    begin
      Texts[SideIdx].Add(CompareExpandTabs(FLines[SideIdx][LineIdx], FTabSize));
      if (Length(Texts[SideIdx][LineIdx]) <= MergePadMax) and
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

  FSyncing := True;
  try
    for SideIdx := 0 to 1 do
    begin
      View := FView[SideIdx];
      SetLength(Rows, Length(FRows));
      for RowIdx := 0 to High(FRows) do
      begin
        if SideIdx = 0 then
          LineIdx := FRows[RowIdx].LeftLine
        else
          LineIdx := FRows[RowIdx].RightLine;
        if LineIdx >= 0 then
          Rows[RowIdx] := NewSchemeRow(StringOfChar(' ',
            Digits - Length(IntToStr(LineIdx + 1))) + IntToStr(LineIdx + 1) +
            ' ', Texts[SideIdx][LineIdx], True, MaxWidth)
        else
          Rows[RowIdx] := NewSchemeRow(BlankPrefix, '', False, MaxWidth);
      end;
      RenderView(View, Rows);
      View.SetRowCount(Length(FRows), Length(BlankPrefix));
      View.SetDiffCount(ConflictCount);
      for RowIdx := 0 to High(FRows) do
      begin
        if SideIdx = 0 then
          LineIdx := FRows[RowIdx].LeftLine
        else
          LineIdx := FRows[RowIdx].RightLine;
        if FRows[RowIdx].DiffIndex < 0 then
          View.SetRowMark(RowIdx, crkEqual, -1)
        else if LineIdx < 0 then
          View.SetRowMark(RowIdx, crkFiller, FRows[RowIdx].DiffIndex)
        else
          View.SetRowMark(RowIdx, crkDiff, FRows[RowIdx].DiffIndex);
      end;
    end;

    // Изменённые слова в парах строк конфликта
    for RowIdx := 0 to High(FRows) do
      if (FRows[RowIdx].DiffIndex >= 0) and (FRows[RowIdx].LeftLine >= 0) and
         (FRows[RowIdx].RightLine >= 0) and
         (Texts[0][FRows[RowIdx].LeftLine] <>
          Texts[1][FRows[RowIdx].RightLine]) then
      begin
        DiffInline(Texts[0][FRows[RowIdx].LeftLine],
          Texts[1][FRows[RowIdx].RightLine], FOptions, LeftRanges,
          RightRanges);
        FView[0].SetRowInline(RowIdx, LeftRanges);
        FView[1].SetRowInline(RowIdx, RightRanges);
      end;
  finally
    FSyncing := False;
    Texts[0].Free;
    Texts[1].Free;
  end;
end;

procedure TDlgConflictMerge.RenderResult;
var
  RowIdx, MaxWidth, Digits, KeepTop: Integer;
  Rows: TSchemeRows;
  Text: string;
begin
  KeepTop := FResView.TopRow;
  MaxWidth := 0;
  Digits := Length(IntToStr(FResLines.Count));
  if Digits < 4 then
    Digits := 4;
  SetLength(Rows, FResLines.Count);
  for RowIdx := 0 to FResLines.Count - 1 do
  begin
    Text := CompareExpandTabs(FResLines[RowIdx], FTabSize);
    if (Length(Text) <= MergePadMax) and (Length(Text) > MaxWidth) then
      MaxWidth := Length(Text);
    Rows[RowIdx] := NewSchemeRow(StringOfChar(' ',
      Digits - Length(IntToStr(RowIdx + 1))) + IntToStr(RowIdx + 1) + ' ',
      Text, True, 0);
  end;
  for RowIdx := 0 to High(Rows) do
    Rows[RowIdx].PadTo := MaxWidth + 2;
  FSyncing := True;
  try
    RenderView(FResView, Rows);
    FResView.SetRowCount(FResLines.Count, Digits + 1);
    FResView.SetDiffCount(ConflictCount);
    for RowIdx := 0 to FResLines.Count - 1 do
      if FResDiff[RowIdx] >= 0 then
        FResView.SetRowMark(RowIdx, crkDiff, FResDiff[RowIdx]);
    FResView.ScrollTo(KeepTop, 0);
  finally
    FSyncing := False;
  end;
end;

// Отметки выбора в панелях и в результате
procedure TDlgConflictMerge.UpdateMarks;
var
  ConfIdx: Integer;
  OursMark, TheirsMark: TCmpDiffMark;
begin
  for ConfIdx := 0 to ConflictCount - 1 do
  begin
    case FConf[ConfIdx].Choice of
      ccOurs:
        begin
          OursMark := cdmTaken;
          TheirsMark := cdmDropped;
        end;
      ccTheirs:
        begin
          OursMark := cdmDropped;
          TheirsMark := cdmTaken;
        end;
      ccOursTheirs, ccTheirsOurs:
        begin
          OursMark := cdmTaken;
          TheirsMark := cdmTaken;
        end;
    else
      OursMark := cdmNone;
      TheirsMark := cdmNone;
    end;
    FView[0].SetDiffMark(ConfIdx, OursMark);
    FView[1].SetDiffMark(ConfIdx, TheirsMark);
    if FConf[ConfIdx].Choice = ccNone then
      FResView.SetDiffMark(ConfIdx, cdmNone)
    else
      FResView.SetDiffMark(ConfIdx, cdmTaken);
  end;
  FView[0].CurDiff := FCurDiff;
  FView[1].CurDiff := FCurDiff;
  FResView.CurDiff := FCurDiff;
  FView[0].Invalidate;
  FView[1].Invalidate;
  FResView.Invalidate;
end;

procedure TDlgConflictMerge.UpdateInfo;
var
  OpenLeft, FileIdx, OtherFiles: Integer;
  Status, ChoiceText: string;
  HasBase: Boolean;
  ConfIdx: Integer;
begin
  OpenLeft := OpenCount;
  if FFileName = '' then
    FLblConf.Caption := ''
  else if ConflictCount = 0 then
    FLblConf.Caption := 'Конфликтов нет'
  else if FCurDiff >= 0 then
    FLblConf.Caption := 'Конфликт ' + IntToStr(FCurDiff + 1) + ' из ' +
      IntToStr(ConflictCount) + ', не выбрано ' + IntToStr(OpenLeft)
  else
    FLblConf.Caption := 'Конфликтов: ' + IntToStr(ConflictCount);
  if FModified then
    Caption := 'Конфликты - ' + ExtractFileName(FFileName) + ' *'
  else
    Caption := 'Конфликты - ' + ExtractFileName(FFileName);

  if ConflictCount > 0 then
  begin
    FHeadLabel[0].Caption := '  Текущая ветка: ' + FConf[0].OursLabel;
    FHeadLabel[1].Caption := '  Вливаемое: ' + FConf[0].TheirsLabel;
  end
  else
  begin
    FHeadLabel[0].Caption := '  Текущая ветка';
    FHeadLabel[1].Caption := '  Вливаемое';
  end;
  ChoiceText := '';
  if (FCurDiff >= 0) and (FCurDiff < ConflictCount) then
    case FConf[FCurDiff].Choice of
      ccOurs: ChoiceText := ' - конфликт ' + IntToStr(FCurDiff + 1) +
        ': текущая';
      ccTheirs: ChoiceText := ' - конфликт ' + IntToStr(FCurDiff + 1) +
        ': вливаемое';
      ccOursTheirs: ChoiceText := ' - конфликт ' + IntToStr(FCurDiff + 1) +
        ': обе, сначала текущая';
      ccTheirsOurs: ChoiceText := ' - конфликт ' + IntToStr(FCurDiff + 1) +
        ': обе, сначала вливаемое';
    end;
  FResHead.Caption := '  Результат' + ChoiceText + '   (' + FFileName + ')';

  HasBase := False;
  for ConfIdx := 0 to ConflictCount - 1 do
    if FConf[ConfIdx].BaseLine >= 0 then
      HasBase := True;
  if FIsUtf8 then
    Status := '  UTF-8'
  else
    Status := '  ANSI';
  if FHasBom then
    Status := Status + ' BOM';
  if HasBase then
    Status := Status + '   часть ||||||| (общая версия) в результат не ' +
      'попадает';
  if FFileName = '' then
    Status := ''
  else if ConflictCount = 0 then
  begin
    OtherFiles := 0;
    for FileIdx := 0 to FFiles.Count - 1 do
      if ConflictMarkerCount(IncludeTrailingPathDelimiter(FRepoRoot) +
         StringReplace(FFiles[FileIdx], '/', PathDelim, [rfReplaceAll])) > 0 then
        Inc(OtherFiles);
    if OtherFiles > 0 then
      Status := Status + '   В этом файле маркеров нет. Файлов с ' +
        'конфликтами ещё: ' + IntToStr(OtherFiles) + ' - кнопка Файл...'
    else
      Status := Status + '   Маркеров нет ни в одном файле - Continue на ' +
        'панели Git';
  end
  else if OpenLeft = 0 then
    Status := Status + '   Выбор сделан во всех конфликтах - Сохранить'
  else if FModified then
    Status := Status + '   Выбор не записан - Сохранить';
  FLblStatus.Caption := Status;

  FBtnPrev.Enabled := ConflictCount > 0;
  FBtnNext.Enabled := ConflictCount > 0;
  FBtnOurs.Enabled := FCurDiff >= 0;
  FBtnTheirs.Enabled := FCurDiff >= 0;
  FBtnOursTheirs.Enabled := FCurDiff >= 0;
  FBtnTheirsOurs.Enabled := FCurDiff >= 0;
  FBtnUndo.Enabled := FCurDiff >= 0;
  FBtnAllOurs.Enabled := OpenLeft > 0;
  FBtnAllTheirs.Enabled := OpenLeft > 0;
  FBtnSave.Enabled := FModified;
  FBtnFile.Enabled := FFiles.Count > 0;
end;

// ---------------------------------------------------------------------------
//  Переходы и выбор
// ---------------------------------------------------------------------------

procedure TDlgConflictMerge.ScrollResult;
var
  Top: Integer;
begin
  if (FCurDiff < 0) or (FCurDiff >= ConflictCount) then
    Exit;
  Top := FResFirst[FCurDiff] - FResView.VisibleRows div 3;
  if Top < 0 then
    Top := 0;
  FSyncing := True;
  try
    FResView.ScrollTo(Top, 0);
  finally
    FSyncing := False;
  end;
end;

procedure TDlgConflictMerge.GoDiff(AIndex: Integer);
var
  SideIdx, Row, Top: Integer;
begin
  if ConflictCount = 0 then
    Exit;
  if AIndex < 0 then
    AIndex := 0;
  if AIndex > ConflictCount - 1 then
    AIndex := ConflictCount - 1;
  FCurDiff := AIndex;
  Row := FDiffFirst[AIndex];
  Top := Row - FView[0].VisibleRows div 3;
  if Top < 0 then
    Top := 0;
  FSyncing := True;
  try
    for SideIdx := 0 to 1 do
    begin
      FView[SideIdx].CaretTo(Row, 0);
      FView[SideIdx].ScrollTo(Top, FView[SideIdx].LeftCol);
    end;
  finally
    FSyncing := False;
  end;
  ScrollResult;
  UpdateMarks;
  UpdateInfo;
end;

// Выбор в конфликте AConf; AAdvance - потом к следующему невыбранному
procedure TDlgConflictMerge.SetChoice(AConf: Integer;
  AChoice: TConflictChoice; AAdvance: Boolean);
var
  ConfIdx, NextConf: Integer;
begin
  if (AConf < 0) or (AConf >= ConflictCount) then
    Exit;
  if FConf[AConf].Choice <> AChoice then
  begin
    FConf[AConf].Choice := AChoice;
    FModified := True;
    BuildResult;
    RenderResult;
  end;
  FCurDiff := AConf;
  NextConf := -1;
  if AAdvance and (AChoice <> ccNone) then
    for ConfIdx := 1 to ConflictCount - 1 do
      if FConf[(AConf + ConfIdx) mod ConflictCount].Choice = ccNone then
      begin
        NextConf := (AConf + ConfIdx) mod ConflictCount;
        Break;
      end;
  if NextConf >= 0 then
    GoDiff(NextConf)
  else
  begin
    ScrollResult;
    UpdateMarks;
    UpdateInfo;
  end;
end;

procedure TDlgConflictMerge.SetAllChoice(AChoice: TConflictChoice);
var
  ConfIdx: Integer;
begin
  for ConfIdx := 0 to ConflictCount - 1 do
    if FConf[ConfIdx].Choice = ccNone then
    begin
      FConf[ConfIdx].Choice := AChoice;
      FModified := True;
    end;
  BuildResult;
  RenderResult;
  ScrollResult;
  UpdateMarks;
  UpdateInfo;
end;

procedure TDlgConflictMerge.BtnChoiceClick(Sender: TObject);
begin
  SetChoice(FCurDiff, TConflictChoice(TComponent(Sender).Tag), True);
end;

procedure TDlgConflictMerge.BtnAllClick(Sender: TObject);
begin
  SetAllChoice(TConflictChoice(TComponent(Sender).Tag));
end;

procedure TDlgConflictMerge.BtnPrevClick(Sender: TObject);
var
  Row, DiffIdx: Integer;
begin
  if ConflictCount = 0 then
    Exit;
  Row := FView[0].CaretRow;
  DiffIdx := FView[0].RowDiff(Row);
  if DiffIdx >= 0 then
    Row := FDiffFirst[DiffIdx];
  for DiffIdx := ConflictCount - 1 downto 0 do
    if FDiffLast[DiffIdx] < Row then
    begin
      GoDiff(DiffIdx);
      Exit;
    end;
  GoDiff(0);
end;

procedure TDlgConflictMerge.BtnNextClick(Sender: TObject);
var
  Row, DiffIdx: Integer;
begin
  if ConflictCount = 0 then
    Exit;
  Row := FView[0].CaretRow;
  DiffIdx := FView[0].RowDiff(Row);
  if DiffIdx >= 0 then
    Row := FDiffLast[DiffIdx];
  for DiffIdx := 0 to ConflictCount - 1 do
    if FDiffFirst[DiffIdx] > Row then
    begin
      GoDiff(DiffIdx);
      Exit;
    end;
  GoDiff(ConflictCount - 1);
end;

procedure TDlgConflictMerge.ViewScroll(Sender: TObject);
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
end;

procedure TDlgConflictMerge.ViewCaretMove(Sender: TObject);
var
  Source, Target: TCompareView;
  Row, DiffIdx: Integer;
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
  DiffIdx := Source.RowDiff(Row);
  if (DiffIdx >= 0) and (DiffIdx <> FCurDiff) then
  begin
    FCurDiff := DiffIdx;
    ScrollResult;
    UpdateMarks;
    UpdateInfo;
  end;
end;

// Каретка в результате на конфликте - он текущий, панели - к нему
procedure TDlgConflictMerge.ResCaretMove(Sender: TObject);
var
  DiffIdx, SideIdx, Top: Integer;
begin
  if FSyncing then
    Exit;
  DiffIdx := FResView.RowDiff(FResView.CaretRow);
  if (DiffIdx < 0) or (DiffIdx = FCurDiff) then
    Exit;
  FCurDiff := DiffIdx;
  Top := FDiffFirst[DiffIdx] - FView[0].VisibleRows div 3;
  if Top < 0 then
    Top := 0;
  FSyncing := True;
  try
    for SideIdx := 0 to 1 do
    begin
      FView[SideIdx].CaretTo(FDiffFirst[DiffIdx], 0);
      FView[SideIdx].ScrollTo(Top, FView[SideIdx].LeftCol);
    end;
  finally
    FSyncing := False;
  end;
  UpdateMarks;
  UpdateInfo;
end;

// Двойной щелчок по конфликту: левая панель - текущая, правая - вливаемое
procedure TDlgConflictMerge.ViewDblClick(Sender: TObject);
var
  View: TCompareView;
  DiffIdx: Integer;
begin
  View := Sender as TCompareView;
  DiffIdx := View.RowDiff(View.CaretRow);
  if DiffIdx < 0 then
    Exit;
  if View.Tag = 0 then
    SetChoice(DiffIdx, ccOurs, True)
  else
    SetChoice(DiffIdx, ccTheirs, True);
end;

// ---------------------------------------------------------------------------
//  Запись, файлы, редактор
// ---------------------------------------------------------------------------

function TDlgConflictMerge.SaveFile: Boolean;
var
  Disk, Text: AnsiString;
  Stream: TFileStream;
begin
  Result := False;
  if FFileName = '' then
    Exit;
  // Файл поменяли после открытия окна (редактор, git) - спросить
  try
    Disk := ReadRawFile(FFileName);
  except
    Disk := '';
  end;
  if FHasBom and (Length(Disk) >= 3) and (Copy(Disk, 1, 3) = #$EF#$BB#$BF) then
    Delete(Disk, 1, 3);
  if (Disk <> FRawText) and
     (MessageDlg('Файл изменён на диске после открытия окна:'#13#10 +
       FFileName + #13#10#13#10'Записать результат поверх?', mtWarning,
       [mbYes, mbNo], 0) <> mrYes) then
    Exit;
  Text := ResultText;
  if FHasBom then
    Text := #$EF#$BB#$BF + Text;
  try
    Stream := TFileStream.Create(FFileName, fmCreate);
    try
      if Length(Text) > 0 then
        Stream.WriteBuffer(Text[1], Length(Text));
    finally
      Stream.Free;
    end;
  except
    on Error: Exception do
    begin
      MessageDlg('Файл не записан:'#13#10 + FFileName + #13#10#13#10 +
        Error.Message, mtError, [mbOK], 0);
      Exit;
    end;
  end;
  FModified := False;
  Result := True;
  if Assigned(FOnSaved) then
    FOnSaved(FFileName);
  // Заново: остались только невыбранные конфликты
  LoadFile(FFileName);
end;

// Есть невыбранное в файле: сохранить? False - отмена
function TDlgConflictMerge.AskSave: Boolean;
var
  Answer: Integer;
begin
  Result := True;
  if not FModified then
    Exit;
  Answer := MessageDlg('Выбор в конфликтах не записан в файл:'#13#10 +
    FFileName + #13#10#13#10'Сохранить?', mtConfirmation,
    [mbYes, mbNo, mbCancel], 0);
  if Answer = mrCancel then
    Result := False
  else if Answer = mrYes then
    Result := SaveFile;
end;

procedure TDlgConflictMerge.BtnSaveClick(Sender: TObject);
begin
  SaveFile;
end;

procedure TDlgConflictMerge.BtnFileClick(Sender: TObject);
var
  FileIdx, Markers: Integer;
  Item: TMenuItem;
  FullPath: string;
  ScreenPt: TPoint;
begin
  FFilesMenu.Items.Clear;
  for FileIdx := 0 to FFiles.Count - 1 do
  begin
    FullPath := IncludeTrailingPathDelimiter(FRepoRoot) +
      StringReplace(FFiles[FileIdx], '/', PathDelim, [rfReplaceAll]);
    Markers := ConflictMarkerCount(FullPath);
    Item := TMenuItem.Create(FFilesMenu);
    if Markers > 0 then
      Item.Caption := FFiles[FileIdx] + '  (конфликтов: ' +
        IntToStr(Markers) + ')'
    else
      Item.Caption := FFiles[FileIdx] + '  (маркеров нет)';
    Item.Checked := AnsiSameText(FullPath, FFileName);
    Item.Enabled := Markers > 0;
    Item.Tag := FileIdx;
    Item.OnClick := FilesMenuClick;
    FFilesMenu.Items.Add(Item);
  end;
  if FFilesMenu.Items.Count = 0 then
    Exit;
  ScreenPt := FBtnFile.ClientToScreen(Point(0, FBtnFile.Height));
  FFilesMenu.Popup(ScreenPt.X, ScreenPt.Y);
end;

procedure TDlgConflictMerge.FilesMenuClick(Sender: TObject);
var
  FileIdx: Integer;
begin
  FileIdx := TMenuItem(Sender).Tag;
  if (FileIdx < 0) or (FileIdx >= FFiles.Count) or not AskSave then
    Exit;
  LoadFile(IncludeTrailingPathDelimiter(FRepoRoot) +
    StringReplace(FFiles[FileIdx], '/', PathDelim, [rfReplaceAll]));
end;

// В редакторе - файл на диске: сначала записать выбор
procedure TDlgConflictMerge.BtnEditorClick(Sender: TObject);
var
  Line: Integer;
begin
  if not Assigned(FOnOpenLine) or (FFileName = '') or not AskSave then
    Exit;
  Line := 1;
  if (FCurDiff >= 0) and (FCurDiff < ConflictCount) then
    Line := FConf[FCurDiff].StartLine + 1
  else if ConflictCount > 0 then
    Line := FConf[0].StartLine + 1;
  FOnOpenLine(FFileName, Line);
end;

procedure TDlgConflictMerge.BtnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TDlgConflictMerge.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_LEFT) and (ssAlt in Shift) then
    SetChoice(FCurDiff, ccOurs, True)
  else if (Key = VK_RIGHT) and (ssAlt in Shift) then
    SetChoice(FCurDiff, ccTheirs, True)
  else if (Key = VK_DOWN) and (ssAlt in Shift) or (Key = VK_F8) then
    BtnNextClick(nil)
  else if (Key = VK_UP) and (ssAlt in Shift) or (Key = VK_F7) then
    BtnPrevClick(nil)
  else if (Key = Ord('S')) and (ssCtrl in Shift) then
    SaveFile
  else if Key = VK_ESCAPE then
    Close
  else
    Exit;
  Key := 0;
end;

procedure TDlgConflictMerge.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  CanClose := AskSave;
end;

procedure TDlgConflictMerge.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  SavePlacement;
  Action := caFree;
end;

procedure TDlgConflictMerge.UMUiThemeChanged(var Message: TMessage);
begin
  if FFileName <> '' then
  begin
    RenderSides;
    RenderResult;
    UpdateMarks;
  end
  else
  begin
    CompareViewColors(FView[0]);
    CompareViewColors(FView[1]);
    CompareViewColors(FResView);
  end;
  Message.Result := 1;
end;

// ---------------------------------------------------------------------------
//  Положение окна
// ---------------------------------------------------------------------------

procedure TDlgConflictMerge.SetPlacementIni(const AIniFile: string);
begin
  FIniFile := AIniFile;
  CompareSetColorsIni(AIniFile);
  LoadPlacement;
  CompareViewColors(FView[0]);
  CompareViewColors(FView[1]);
  CompareViewColors(FResView);
end;

procedure TDlgConflictMerge.LoadPlacement;
var
  Ini: TBufIniFile;
  WinLeft, WinTop, WinWidth, WinHeight, ResHeight: Integer;
  Work: TRect;
begin
  if (FIniFile = '') or not FileExists(FIniFile) then
    Exit;
  Ini := TBufIniFile.Create(FIniFile);
  try
    WinWidth := Ini.ReadInteger(MergeSection, 'Width', 0);
    WinHeight := Ini.ReadInteger(MergeSection, 'Height', 0);
    if (WinWidth >= Constraints.MinWidth) and
       (WinHeight >= Constraints.MinHeight) then
    begin
      WinLeft := Ini.ReadInteger(MergeSection, 'Left', Left);
      WinTop := Ini.ReadInteger(MergeSection, 'Top', Top);
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
    ResHeight := Ini.ReadInteger(MergeSection, 'ResultHeight', 0);
    if (ResHeight >= 60) and (ResHeight < Height - 160) then
      FResPanel.Height := ResHeight;
    if Ini.ReadBool(MergeSection, 'Maximized', False) then
      WindowState := wsMaximized;
  finally
    Ini.Free;
  end;
end;

procedure TDlgConflictMerge.SavePlacement;
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
    Ini.WriteInteger(MergeSection, 'Left', Place.rcNormalPosition.Left);
    Ini.WriteInteger(MergeSection, 'Top', Place.rcNormalPosition.Top);
    Ini.WriteInteger(MergeSection, 'Width', Place.rcNormalPosition.Right -
      Place.rcNormalPosition.Left);
    Ini.WriteInteger(MergeSection, 'Height', Place.rcNormalPosition.Bottom -
      Place.rcNormalPosition.Top);
    Ini.WriteBool(MergeSection, 'Maximized', WindowState = wsMaximized);
    Ini.WriteInteger(MergeSection, 'ResultHeight', FResPanel.Height);
  finally
    Ini.Free;
  end;
end;

end.
