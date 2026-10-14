unit DlgStrictFix;

// ---------------------------------------------------------------------------
//  Окно "Строгая проверка" - после строгой проверки перед rc.exe (галка
//  "FB smart" в рамке Project, без "Info only"), если нашлись ошибки
//  программы или подозрения. Ограничения самого перевода сюда не идут: для
//  rc.exe это правильный код.
//
//  Для каждой записи - причина и что можно сделать (StrictFix):
//   - найти определение (DIM / CREATE, тело SUB / FUNCTION) в других файлах
//     и подключить файл;
//   - похожее имя (метка, переменная, процедура) - заменить им;
//   - CASE > x - CASE IS > x;
//   - открыть первое объявление (повторные объявления).
//  Правки идут через редактор (AEditLine), их можно отменить там же. Окно
//  строится кодом.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, StdCtrls,
  ExtCtrls, ComCtrls, IniFiles,
  StrictFix,    // разбор записей и варианты исправления
  UiButton,     // TUiButton
  UiStdCtrls,   // TUiCheckBox
  UiEditCtrls,  // TUiEdit
  UiComCtrls,   // TUiListView
  SearchDirs;   // папки поиска: стандартные и свои, галки

type
  // Открыть файл в редакторе на строке (с 1)
  TStrictOpenLine = procedure(const AFile: string; ALine: Integer) of object;
  // Правка строки в редакторе: AInsert - вставить ANew перед строкой ALine,
  // иначе строку ALine (её текст должен быть AOld) заменить на ANew.
  // False - не вышло (файл не открылся, строка уже другая)
  TStrictEditLine = function(const AFile: string; ALine: Integer;
                             const AOld, ANew: string;
                             AInsert: Boolean): Boolean of object;

// Записи лога перевода: ошибки программы, подозрения в её файлах,
// подозрения в файлах папок Include ALibDirs (чужие библиотеки: окно их
// прячет и из-за них не открывается), ограничения перевода
procedure StrictCount(AMessages, ALibDirs: TStrings;
                      var AErrors, ASuspects, ALibSuspects, ALimits: Integer);

// Файл - в одной из папок ALibDirs (с подпапками)
function StrictInLibDir(const AFile: string; ALibDirs: TStrings): Boolean;

// Показать окно. AMessages - строки лога перевода; ARoots - папки поиска
// определений (Include, программа, папка выше); AMainFile - главный .bas,
// AIncDir - папка -I. mrIgnore - собрать rc.exe, иначе - не собирать.
//
// Окно немодальное: пока оно открыто, с главным окном можно работать
// (смотреть и править исходник). Функция ждёт его закрытия своим циклом
// сообщений, поэтому сборка продолжается после него, как раньше.
type
  // Папки поиска - окно Directory Tree главного окна (SearchDirsDialog):
  // AFixed - стандартные папки, AItems - галки и свои папки (SearchDirs)
  TStrictPickDirs = function(const ACaption: string;
                             AFixed, AItems: TStrings): Boolean of object;

function StrictFixDialog(AOwner: TComponent;
                         AMessages, ARoots, ALibDirs: TStrings;
                         const AMainFile, AIncDir: string;
                         AOpenLine: TStrictOpenLine;
                         AEditLine: TStrictEditLine;
                         const AIniFile: string = '';
                         APickDirs: TStrictPickDirs = nil): TModalResult;

// Окно уже открыто (сборка ждёт его): поднять его наверх, True
function StrictFixDialogActive: Boolean;

// Пропущенные записи (галка снята в окне) - ключи StrictItemKey, хранятся
// в editor.ini, раздел "RapidQ.StrictSkip <главный файл>"
function  StrictItemKey(AItem: TStrictError): string;
procedure StrictLoadSkipped(const AIniFile, AMainFile: string;
                            ASkipped: TStrings);
procedure StrictSaveSkipped(const AIniFile, AMainFile: string;
                            ASkipped: TStrings);
// Из AMessages - строки пропущенных записей; результат - сколько убрано
function  StrictDropSkipped(AMessages, ASkipped: TStrings): Integer;

implementation

type
  TStrictFixForm = class(TForm)
  private
    FItems: TList;           // TStrictError, свои: ошибки, потом подозрения
    FOptions: TList;         // TStringList на запись: варианты
    FPrepared: TStringList;  // номера записей, для которых варианты собраны
    FDone: TStringList;      // номера исправленных записей
    FRoots: TStrings;
    FLibDirs: TStrings;
    FMessages: TStrings;
    FMainFile, FIncDir: string;
    FOpenLine: TStrictOpenLine;
    FEditLine: TStrictEditLine;
    FIniFile: string;        // editor.ini: положение окна, [StrictFixWindow]
    FBusy, FAbort: Boolean;
    FLastTick: Cardinal;
    FErrCount: Integer;
    lblInfo: TLabel;
    chkLib: TUiCheckBox;     // показать подозрения в файлах папок Include
    chkSkipped: TUiCheckBox; // показать пропущенные (галка снята)
    FSkipped: TStringList;   // ключи пропущенных записей (StrictItemKey)
    lvItems: TUiListView;    // с галками: снята - пропускать в следующий раз
    splItems: TSplitter;
    memExplain: TMemo;
    pnlActions: TPanel;
    btnOpen: TUiButton;
    btnOpenOther: TUiButton;
    btnFind: TUiButton;
    edExts: TUiEdit;         // где искать определение: расширения через ";"
    btnDirs: TUiButton;      // [...] - свои папки поиска (Directory Tree)
    // Типовые расширения программ RapidQ: галка - расширение в edExts
    FExtChecks: array of TUiCheckBox;
    FExtSyncing: Boolean;    // галки и поле правятся друг из друга
    FDirItems: TStringList;  // галки стандартных и свои папки (SearchDirs)
    FPickDirs: TStrictPickDirs;
    btnApply: TUiButton;
    lblOptions: TLabel;
    lbOptions: TListBox;
    // Вместо списка вариантов, когда их нет: цветом списка (берётся при
    // отрисовке - тема IDE ложится после заполнения), с пояснением; иначе
    // место выглядело пустым
    pbNoOptions: TPaintBox;
    FNoOptionsText: string;
    pnlBottom: TPanel;
    lblStatus: TLabel;
    btnBuild: TUiButton;
    btnClose: TUiButton;
    procedure BuildControls;
    procedure pbNoOptionsPaint(Sender: TObject);
    procedure ExtCheckClick(Sender: TObject);
    procedure edExtsChange(Sender: TObject);
    procedure SyncExtChecks;
    procedure btnDirsClick(Sender: TObject);
    procedure PlaceActions;
    procedure FillItems;
    procedure chkLibClick(Sender: TObject);
    procedure CollectChecks;
    function  CurIndex: Integer;
    function  CurItem: TStrictError;
    function  CurOptions: TStringList;
    function  IsDone: Boolean;
    function  FileLines(const AFile: string; ALines: TStrings): Boolean;
    function  LabelFix(AItem: TStrictError; var AOld, ANew,
                       ATarget: string): Boolean;
    procedure PrepareOptions;
    procedure ShowCurrent;
    procedure UpdateApply;
    procedure MarkDone(const ANote: string);
    function  ReplaceInLine(AItem: TStrictError; const AOld, ANew: string;
                            AFix: Integer): Boolean;
    procedure Progress(const AText: string; var ACancel: Boolean);
    procedure lvItemsSelectItem(Sender: TObject; Item: TListItem;
                                Selected: Boolean);
    procedure lbOptionsClick(Sender: TObject);
    procedure lbOptionsDblClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnOpenOtherClick(Sender: TObject);
    procedure btnFindClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure LoadPlacement;
    procedure SavePlacement;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    destructor Destroy; override;
  end;

var
  // Открытое окно (сборка ждёт его) - второй раз не открывается
  OpenStrictDlg: TStrictFixForm = nil;

const
  // Где искать определение по умолчанию - файлы программ RapidQ
  StrictDefaultExts = '.inc;.bas;.cmp';
  StrictDirsSection = 'StrictFixDirs';
  // Галки рядом с полем: типовые расширения файлов программ RapidQ
  StrictTypicalExts: array[0..3] of string = ('.inc', '.bas', '.cmp', '.rqb');
  // Вид правки строки (ReplaceInLine)
  fixWord = 0;     // слово AOld - на ANew
  fixGoto = 1;     // GOTO / GOSUB AOld - на ANew
  fixCase = 2;     // CASE > - CASE IS >

function StrictInLibDir(const AFile: string; ALibDirs: TStrings): Boolean;
var
  DirIdx: Integer;
  DirSlash: string;
begin
  Result := False;
  if ALibDirs = nil then
    Exit;
  for DirIdx := 0 to ALibDirs.Count - 1 do
  begin
    if Trim(ALibDirs[DirIdx]) = '' then
      Continue;
    DirSlash := IncludeTrailingPathDelimiter(ExpandFileName(ALibDirs[DirIdx]));
    if CompareText(Copy(ExpandFileName(AFile), 1, Length(DirSlash)),
                   DirSlash) = 0 then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

procedure StrictCount(AMessages, ALibDirs: TStrings;
                      var AErrors, ASuspects, ALibSuspects, ALimits: Integer);
var
  MsgIdx: Integer;
  Item: TStrictError;
begin
  AErrors := 0;
  ASuspects := 0;
  ALibSuspects := 0;
  ALimits := 0;
  for MsgIdx := 0 to AMessages.Count - 1 do
  begin
    Item := StrictParseMessage(AMessages[MsgIdx]);
    if Item = nil then
      Continue;
    if Item.Kind = skLimit then
      Inc(ALimits)
    else if Item.Level = slError then
      Inc(AErrors)
    else if StrictInLibDir(Item.FileName, ALibDirs) then
      Inc(ALibSuspects)
    else
      Inc(ASuspects);
    Item.Free;
  end;
end;

// Вариант из списка: "N|имя|строка" - заменить именем, "D|файл|строка|
// закомментировано|текст" - найденное определение (подключить файл)
function OptionField(const AOption: string; AIndex: Integer): string;
var
  Rest: string;
  FieldIdx, SepPos: Integer;
begin
  Rest := AOption;
  for FieldIdx := 0 to AIndex - 1 do
  begin
    SepPos := Pos('|', Rest);
    if SepPos = 0 then
    begin
      Rest := '';
      Break;
    end;
    Delete(Rest, 1, SepPos);
  end;
  SepPos := Pos('|', Rest);
  // последнее поле записи D - текст строки, в нём может быть "|"
  if (SepPos > 0) and not ((AOption[1] = 'D') and (AIndex = 4)) then
    Result := Copy(Rest, 1, SepPos - 1)
  else
    Result := Rest;
end;

{ TStrictFixForm }

destructor TStrictFixForm.Destroy;
var
  ItemIdx: Integer;
begin
  if FItems <> nil then
    for ItemIdx := 0 to FItems.Count - 1 do
      TObject(FItems[ItemIdx]).Free;
  if FOptions <> nil then
    for ItemIdx := 0 to FOptions.Count - 1 do
      TObject(FOptions[ItemIdx]).Free;
  FItems.Free;
  FOptions.Free;
  FPrepared.Free;
  FDone.Free;
  FSkipped.Free;
  FDirItems.Free;
  inherited Destroy;
end;

procedure TStrictFixForm.BuildControls;

  procedure AddCol(const ACaption: string; AWidth: Integer);
  var
    Col: TListColumn;
  begin
    Col := lvItems.Columns.Add;
    Col.Caption := ACaption;
    Col.Width := AWidth;
  end;

  function MakeButton(AParent: TWinControl; const ACaption: string;
                      ALeft, ATop, AWidth: Integer;
                      AClick: TNotifyEvent): TUiButton;
  begin
    Result := TUiButton.Create(Self);
    Result.Parent := AParent;
    Result.SetBounds(ALeft, ATop, AWidth, 25);
    Result.Caption := ACaption;
    Result.OnClick := AClick;
  end;

var
  ExtIdx: Integer;
begin
  Caption := 'Строгая проверка';
  Width := 940;
  Height := 680;
  Position := poScreenCenter;
  BorderIcons := [biSystemMenu, biMaximize];
  Constraints.MinWidth := 700;
  Constraints.MinHeight := 480;
  Font.Name := 'Tahoma';
  Font.Height := -11;
  ShowHint := True;
  AutoScroll := False;
  OnCloseQuery := FormCloseQuery;
  OnClose := FormClose;

  FItems := TList.Create;
  FOptions := TList.Create;
  FPrepared := TStringList.Create;
  FDone := TStringList.Create;

  lblInfo := TLabel.Create(Self);
  lblInfo.Parent := Self;
  lblInfo.Align := alTop;
  lblInfo.AutoSize := True;
  lblInfo.WordWrap := True;
  chkLib := TUiCheckBox.Create(Self);
  chkLib.Parent := Self;
  chkLib.Top := 30;
  chkLib.Height := 20;
  chkLib.Align := alTop;
  chkLib.Caption := ' Подозрения в файлах папок Include';
  chkLib.Hint := 'Чужие библиотеки (inc из папок Include): подозрения в них ' +
                 'обычно не про вашу программу - по умолчанию скрыты';
  chkLib.Checked := False;
  chkLib.OnClick := chkLibClick;
  chkSkipped := TUiCheckBox.Create(Self);
  chkSkipped.Parent := Self;
  chkSkipped.Top := 52;
  chkSkipped.Height := 20;
  chkSkipped.Align := alTop;
  chkSkipped.Caption := ' Пропущенные';
  chkSkipped.Hint := 'Записи со снятой галкой при следующих проверках не ' +
                     'показываются и не открывают окно; галка - вернуть';
  chkSkipped.Checked := False;
  chkSkipped.OnClick := chkLibClick;
  FSkipped := TStringList.Create;
  FSkipped.Sorted := True;
  FSkipped.Duplicates := dupIgnore;
  FSkipped.CaseSensitive := False;

  pnlBottom := TPanel.Create(Self);
  pnlBottom.Parent := Self;
  pnlBottom.SetBounds(0, ClientHeight - 60, ClientWidth, 60);
  pnlBottom.Align := alBottom;
  pnlBottom.BevelOuter := bvNone;
  pnlBottom.Caption := '';
  lblStatus := TLabel.Create(Self);
  lblStatus.Parent := pnlBottom;
  lblStatus.AutoSize := False;
  lblStatus.SetBounds(8, 4, ClientWidth - 16, 14);
  lblStatus.Anchors := [akLeft, akTop, akRight];
  btnBuild := MakeButton(pnlBottom, 'Собрать rc.exe как есть', 8, 26, 180, nil);
  btnBuild.ModalResult := mrIgnore;
  btnBuild.Hint := 'Запустить rc.exe, не исправляя того, что осталось';
  btnClose := MakeButton(pnlBottom, 'Закрыть', 196, 26, 100, nil);
  btnClose.ModalResult := mrCancel;
  btnClose.Hint := 'Закрыть окно, rc.exe не запускать';

  // Сверху вниз: записи | сплиттер | пояснение | кнопки | варианты
  lvItems := TUiListView.Create(Self);
  lvItems.Parent := Self;
  lvItems.Checkboxes := True;
  lvItems.Top := 80;
  lvItems.Height := 170;
  lvItems.Align := alTop;
  lvItems.ViewStyle := vsReport;
  lvItems.RowSelect := True;
  lvItems.ReadOnly := True;
  lvItems.HideSelection := False;
  lvItems.OnSelectItem := lvItemsSelectItem;
  // Двойной щелчок по записи - как "Открыть строку"
  lvItems.OnDblClick := btnOpenClick;
  AddCol('Вид', 90);
  AddCol('Где', 200);
  AddCol('Текст', 590);

  splItems := TSplitter.Create(Self);
  splItems.Parent := Self;
  splItems.Top := 220;
  splItems.Height := 5;
  splItems.Align := alTop;
  splItems.MinSize := 60;

  memExplain := TMemo.Create(Self);
  memExplain.Parent := Self;
  memExplain.Top := 230;
  memExplain.Height := 170;
  memExplain.Align := alTop;
  memExplain.ReadOnly := True;
  memExplain.WordWrap := True;
  memExplain.ScrollBars := ssVertical;

  pnlActions := TPanel.Create(Self);
  pnlActions.Parent := Self;
  pnlActions.Top := 410;
  pnlActions.Height := 34;
  pnlActions.Align := alTop;
  pnlActions.BevelOuter := bvNone;
  pnlActions.Caption := '';
  btnOpen := MakeButton(pnlActions, 'Открыть строку', 8, 5, 120, btnOpenClick);
  btnOpen.Hint := 'Открыть файл в редакторе на строке записи';
  btnOpenOther := MakeButton(pnlActions, 'Открыть первое объявление', 136, 5,
                             180, btnOpenOtherClick);
  btnFind := MakeButton(pnlActions, 'Найти определение', 324, 5, 140,
                        btnFindClick);
  btnFind.Hint := 'Искать определение в .inc, .bas, .cmp папок Include, ' +
                  'программы и папки выше; во время поиска - остановить';
  // Расширения файлов для "Найти определение" - справа от кнопки
  btnDirs := MakeButton(pnlActions, '...', 468, 5, 28, btnDirsClick);
  btnDirs.Hint := 'Свои папки для поиска определения: окно Directory Tree, ' +
                  'отмеченные в его списке папки (с подпапками)';
  FDirItems := TStringList.Create;
  edExts := TUiEdit.Create(Self);
  edExts.Parent := pnlActions;
  edExts.SetBounds(502, 7, 110, 21);
  edExts.Text := StrictDefaultExts;
  edExts.Hint := 'Где искать определение: расширения файлов через ";". ' +
                 'Галки справа ставят и убирают типовые; можно дописать своё';
  edExts.OnChange := edExtsChange;
  SetLength(FExtChecks, Length(StrictTypicalExts));
  for ExtIdx := 0 to High(StrictTypicalExts) do
  begin
    FExtChecks[ExtIdx] := TUiCheckBox.Create(Self);
    FExtChecks[ExtIdx].Parent := pnlActions;
    FExtChecks[ExtIdx].SetBounds(620 + ExtIdx * 52, 9, 50, 17);
    FExtChecks[ExtIdx].Caption := StrictTypicalExts[ExtIdx];
    FExtChecks[ExtIdx].OnClick := ExtCheckClick;
  end;
  btnApply := MakeButton(pnlActions, 'Исправить', 836, 5, 300, btnApplyClick);

  lblOptions := TLabel.Create(Self);
  lblOptions.Parent := Self;
  lblOptions.Top := 450;
  lblOptions.Align := alTop;
  lblOptions.Caption := ' Варианты (выберите; двойной щелчок по найденному ' +
                        'файлу - открыть его):';
  lbOptions := TListBox.Create(Self);
  lbOptions.Parent := Self;
  lbOptions.Align := alClient;
  lbOptions.OnClick := lbOptionsClick;
  lbOptions.OnDblClick := lbOptionsDblClick;

  pbNoOptions := TPaintBox.Create(Self);
  pbNoOptions.Parent := Self;
  pbNoOptions.Align := alClient;
  pbNoOptions.Visible := False;
  pbNoOptions.OnPaint := pbNoOptionsPaint;

  // Строка хода поиска меняется часто - без мерцания
  pnlBottom.DoubleBuffered := True;
  SyncExtChecks;
end;

function TStrictFixForm.FileLines(const AFile: string;
                                  ALines: TStrings): Boolean;
begin
  Result := False;
  ALines.Clear;
  if not FileExists(AFile) then
    Exit;
  try
    ALines.LoadFromFile(AFile);
    Result := True;
  except
    Result := False;
  end;
end;

procedure TStrictFixForm.FillItems;
var
  Pass, MsgIdx, Limits, Suspects, LibSuspects, ItemIdx, SkipCount: Integer;
  Item: TStrictError;
  Row: TListItem;
  IsSkipped: Boolean;
begin
  // Заново (переключение галок над списком): сначала - галки строк
  CollectChecks;
  SkipCount := 0;
  for ItemIdx := 0 to FItems.Count - 1 do
    TObject(FItems[ItemIdx]).Free;
  for ItemIdx := 0 to FOptions.Count - 1 do
    TObject(FOptions[ItemIdx]).Free;
  FItems.Clear;
  FOptions.Clear;
  FPrepared.Clear;
  FDone.Clear;
  lvItems.Items.Clear;
  FErrCount := 0;
  Limits := 0;
  Suspects := 0;
  LibSuspects := 0;
  // Сначала ошибки программы, потом подозрения
  for Pass := 0 to 1 do
    for MsgIdx := 0 to FMessages.Count - 1 do
    begin
      Item := StrictParseMessage(FMessages[MsgIdx]);
      if Item = nil then
        Continue;
      if (Item.Kind = skLimit) or (Ord(Item.Level) <> Pass) then
      begin
        if (Pass = 0) and (Item.Kind = skLimit) then
          Inc(Limits);
        Item.Free;
        Continue;
      end;
      if (Item.Level = slSuspect) and StrictInLibDir(Item.FileName, FLibDirs) then
      begin
        Inc(LibSuspects);
        if not chkLib.Checked then
        begin
          Item.Free;
          Continue;
        end;
      end;
      IsSkipped := FSkipped.IndexOf(StrictItemKey(Item)) >= 0;
      if IsSkipped then
      begin
        Inc(SkipCount);
        if not chkSkipped.Checked then
        begin
          Item.Free;
          Continue;
        end;
      end
      else if Item.Level = slError then
        Inc(FErrCount)
      else
        Inc(Suspects);
      FItems.Add(Item);
      FOptions.Add(TStringList.Create);
      Row := lvItems.Items.Add;
      Row.Checked := not IsSkipped;
      if Item.Level = slError then
        Row.Caption := 'Ошибка'
      else
        Row.Caption := 'Подозрение';
      Row.SubItems.Add(ExtractFileName(Item.FileName) + '(' +
                       IntToStr(Item.Line) + ')');
      Row.SubItems.Add(Item.Text);
    end;
  if chkLib.Checked then
    Dec(Suspects, LibSuspects);
  lblInfo.Caption := Format(' Строгая проверка (FB Smart): ошибок программы %d, ' +
    'подозрений %d - то, что rc.exe пропускает, а программа из-за этого ' +
    'может работать не так.', [FErrCount, Suspects]);
  chkLib.Caption := Format(' Подозрения в файлах папок Include: %d',
                           [LibSuspects]);
  chkLib.Enabled := LibSuspects > 0;
  chkSkipped.Caption := Format(' Пропущенные (галка снята): %d', [SkipCount]);
  chkSkipped.Enabled := SkipCount > 0;
  if Limits > 0 then
    lblInfo.Caption := lblInfo.Caption + Format(' Ограничений перевода в ' +
      'FreeBASIC: %d - для rc.exe не важны, они только в логе.', [Limits]);
  lblInfo.Caption := lblInfo.Caption + ' Правки идут через редактор, их ' +
    'можно отменить там же (Undo).';
  if FErrCount = 0 then
    btnBuild.Caption := 'Собрать rc.exe'
  else
    btnBuild.Caption := 'Собрать rc.exe как есть';
  if lvItems.Items.Count > 0 then
    lvItems.Selected := lvItems.Items[0];
  ShowCurrent;
end;

function TStrictFixForm.CurIndex: Integer;
begin
  Result := -1;
  if lvItems.Selected <> nil then
    Result := lvItems.Selected.Index;
end;

function TStrictFixForm.CurItem: TStrictError;
begin
  Result := nil;
  if (CurIndex >= 0) and (CurIndex < FItems.Count) then
    Result := TStrictError(FItems[CurIndex]);
end;

function TStrictFixForm.CurOptions: TStringList;
begin
  Result := nil;
  if (CurIndex >= 0) and (CurIndex < FOptions.Count) then
    Result := TStringList(FOptions[CurIndex]);
end;

function TStrictFixForm.IsDone: Boolean;
begin
  Result := FDone.IndexOf(IntToStr(CurIndex)) >= 0;
end;

// Замена метки: строка GOTO и её текст с похожей меткой. False - похожей
// метки в процедуре нет
function TStrictFixForm.LabelFix(AItem: TStrictError; var AOld, ANew,
                                 ATarget: string): Boolean;
var
  Lines, Labels, Similar: TStringList;
  First, Last: Integer;
  ProcName: string;
begin
  Result := False;
  Lines := TStringList.Create;
  Labels := TStringList.Create;
  Similar := TStringList.Create;
  try
    if not FileLines(AItem.FileName, Lines) or (AItem.Line < 1) or
       (AItem.Line > Lines.Count) then
      Exit;
    if not StrictProcAt(Lines, AItem.Line - 1, First, Last, ProcName) then
      Exit;
    StrictLabelsIn(Lines, First, Last, Labels);
    StrictSimilarNames(AItem.Name, Labels, Similar);
    if Similar.Count = 0 then
      Exit;
    ATarget := Similar.Names[0];
    AOld := Lines[AItem.Line - 1];
    Result := StrictReplaceGoto(AOld, AItem.Name, ATarget, ANew);
  finally
    Similar.Free;
    Labels.Free;
    Lines.Free;
  end;
end;

// Варианты записи, которые видны без поиска: похожие имена программы
// (переменные, процедуры), RAPIDQ.INC в папках Include
procedure TStrictFixForm.PrepareOptions;
var
  Item: TStrictError;
  Options, Lines, Names, Similar: TStringList;
  NameIdx, RootIdx: Integer;
  Candidate: string;
begin
  Item := CurItem;
  if (Item = nil) or (FPrepared.IndexOf(IntToStr(CurIndex)) >= 0) then
    Exit;
  FPrepared.Add(IntToStr(CurIndex));
  Options := CurOptions;
  Lines := TStringList.Create;
  Names := TStringList.Create;
  Similar := TStringList.Create;
  try
    if Item.Kind in [skUndeclaredVar, skSusNoValue, skBindNoProc] then
    begin
      // Имена - из файла записи и главного файла
      if FileLines(Item.FileName, Lines) then
        StrictNamesIn(Lines, Item.Kind = skBindNoProc, Names);
      if (CompareText(ExpandFileName(Item.FileName),
                      ExpandFileName(FMainFile)) <> 0) and
         FileLines(FMainFile, Lines) then
        StrictNamesIn(Lines, Item.Kind = skBindNoProc, Names);
      StrictSimilarNames(Item.Name, Names, Similar);
      for NameIdx := 0 to Similar.Count - 1 do
        Options.Add('N|' + Similar.Names[NameIdx] + '|' +
                    Similar.ValueFromIndex[NameIdx]);
    end;
    if (Item.Kind = skSusTrueFalse) and (FRoots <> nil) then
      for RootIdx := 0 to FRoots.Count - 1 do
      begin
        if FRoots[RootIdx] = '' then
          Continue;
        Candidate := IncludeTrailingPathDelimiter(FRoots[RootIdx]) + 'RAPIDQ.INC';
        if FileExists(Candidate) then
        begin
          Options.Add('D|' + Candidate + '|1|0|RAPIDQ.INC');
          Break;
        end;
      end;
  finally
    Similar.Free;
    Names.Free;
    Lines.Free;
  end;
end;

procedure TStrictFixForm.ShowCurrent;
var
  ExtIdx: Integer;
  Item: TStrictError;
  Lines, Options: TStringList;
  OptIdx: Integer;
  Text, Note: string;
  NeedProc: Boolean;
begin
  Item := CurItem;
  btnOpen.Enabled := Item <> nil;
  btnOpenOther.Visible := (Item <> nil) and (Item.OtherFile <> '');
  if btnOpenOther.Visible then
    btnOpenOther.Hint := Item.OtherFile + ', строка ' + IntToStr(Item.OtherLine);
  btnFind.Visible := (Item <> nil) and StrictNeedsSearch(Item, NeedProc);
  edExts.Visible := btnFind.Visible;
  btnDirs.Visible := btnFind.Visible;
  for ExtIdx := 0 to High(FExtChecks) do
    FExtChecks[ExtIdx].Visible := btnFind.Visible;
  memExplain.Lines.Clear;
  lbOptions.Items.Clear;
  if Item = nil then
  begin
    UpdateApply;
    Exit;
  end;
  PrepareOptions;
  Lines := TStringList.Create;
  try
    if FileLines(Item.FileName, Lines) then
      memExplain.Text := StrictExplain(Item, Lines)
    else
      memExplain.Text := StrictExplain(Item, nil);
  finally
    Lines.Free;
  end;
  if IsDone then
    memExplain.Lines.Insert(0, 'ИСПРАВЛЕНО. Проверка пройдёт заново при ' +
                               'следующей сборке.'#13#10);
  Options := CurOptions;
  for OptIdx := 0 to Options.Count - 1 do
  begin
    Text := Options[OptIdx];
    if Text[1] = 'N' then
      lbOptions.Items.Add('Заменить на ' + OptionField(Text, 1) +
                          '   (встречается в строке ' + OptionField(Text, 2) + ')')
    else
    begin
      Note := '';
      if OptionField(Text, 3) = '1' then
        Note := '  [закомментировано]';
      lbOptions.Items.Add('Подключить ' + OptionField(Text, 1) + '(' +
                          OptionField(Text, 2) + '): ' + OptionField(Text, 4) +
                          Note);
    end;
  end;
  lblOptions.Visible := Options.Count > 0;
  lbOptions.Visible := Options.Count > 0;
  // Вариантов нет - на их месте поле цвета списка с пояснением
  pbNoOptions.Visible := Options.Count = 0;
  if pbNoOptions.Visible then
  begin
    if btnFind.Visible then
      FNoOptionsText := 'Вариантов исправления пока нет. "Найти ' +
        'определение" ищет их в папках Include, программы и выше - найденные ' +
        'файлы появятся здесь'
    else
      FNoOptionsText := 'Вариантов исправления для этой записи нет - ' +
        'причина и что можно сделать - в пояснении выше';
    pbNoOptions.Invalidate;
  end;
  UpdateApply;
end;

// Кнопка "Исправить": что сделает - по записи и выбранному варианту
procedure TStrictFixForm.UpdateApply;
var
  Item: TStrictError;
  OldText, NewText, Target, Option: string;
begin
  Item := CurItem;
  btnApply.Visible := False;
  if Item = nil then
    Exit;
  case Item.Kind of
    skLabelElsewhere, skLabelMissing:
      if LabelFix(Item, OldText, NewText, Target) then
      begin
        btnApply.Caption := 'Заменить на ' + Item.Statement + ' ' + Target;
        btnApply.Hint := 'Строка ' + IntToStr(Item.Line) + ': ' +
                         Trim(OldText) + '  ->  ' + Trim(NewText);
        btnApply.Visible := True;
      end;
    skCaseOp:
      begin
        btnApply.Caption := 'Вставить IS: CASE IS ...';
        btnApply.Hint := 'В строке ' + IntToStr(Item.Line) + ' CASE > x ' +
                         'станет CASE IS > x';
        btnApply.Visible := True;
      end;
  else
    if lbOptions.Visible then
    begin
      btnApply.Visible := True;
      if lbOptions.ItemIndex < 0 then
        btnApply.Caption := 'Выберите вариант ниже'
      else
      begin
        Option := CurOptions[lbOptions.ItemIndex];
        if Option[1] = 'N' then
          btnApply.Caption := 'Заменить на ' + OptionField(Option, 1)
        else
          btnApply.Caption := 'Подключить ' +
                              ExtractFileName(OptionField(Option, 1));
      end;
    end;
  end;
  PlaceActions;
  btnApply.Enabled := btnApply.Visible and not IsDone and
    ((Item.Kind in [skLabelElsewhere, skLabelMissing, skCaseOp]) or
     (lbOptions.ItemIndex >= 0));
end;

procedure TStrictFixForm.MarkDone(const ANote: string);
var
  Idx: Integer;
begin
  Idx := CurIndex;
  if FDone.IndexOf(IntToStr(Idx)) < 0 then
    FDone.Add(IntToStr(Idx));
  if (Idx >= 0) and (Idx < lvItems.Items.Count) then
    lvItems.Items[Idx].SubItems[1] := 'исправлено (' + ANote + '): ' +
      TStrictError(FItems[Idx]).Text;
  lblStatus.Caption := ANote;
  ShowCurrent;
end;

// Правка строки записи: AFix - вид (fixWord, fixGoto, fixCase)
function TStrictFixForm.ReplaceInLine(AItem: TStrictError;
                                      const AOld, ANew: string;
                                      AFix: Integer): Boolean;
var
  Lines: TStringList;
  OldText, NewText: string;
  Made: Boolean;
begin
  Result := False;
  Lines := TStringList.Create;
  try
    if not FileLines(AItem.FileName, Lines) or (AItem.Line < 1) or
       (AItem.Line > Lines.Count) then
    begin
      lblStatus.Caption := 'Не прочитан ' + AItem.FileName;
      Exit;
    end;
    OldText := Lines[AItem.Line - 1];
  finally
    Lines.Free;
  end;
  case AFix of
    fixGoto:
      Made := StrictReplaceGoto(OldText, AOld, ANew, NewText);
    fixCase:
      Made := StrictFixCase(OldText, NewText);
  else
    Made := StrictReplaceWord(OldText, AOld, ANew, NewText);
  end;
  if not Made then
  begin
    lblStatus.Caption := 'В строке ' + IntToStr(AItem.Line) + ' не нашлось, ' +
                         'что заменить: ' + Trim(OldText);
    Exit;
  end;
  Result := FEditLine(AItem.FileName, AItem.Line, OldText, NewText, False);
  if Result then
    MarkDone('строка ' + IntToStr(AItem.Line) + ': ' + Trim(NewText))
  else
    lblStatus.Caption := 'Не исправлено: строка ' + IntToStr(AItem.Line) +
      ' в редакторе уже другая или файл не открылся';
end;

procedure TStrictFixForm.pbNoOptionsPaint(Sender: TObject);
var
  PaintCanvas: TCanvas;
  DrawArea: TRect;
begin
  // Без with: у TCanvas свои Rect-подобные имена (TextRect)
  PaintCanvas := pbNoOptions.Canvas;
  PaintCanvas.Brush.Color := lvItems.Color;
  PaintCanvas.FillRect(pbNoOptions.ClientRect);
  PaintCanvas.Font := Font;
  PaintCanvas.Font.Color := lvItems.Font.Color;
  PaintCanvas.Brush.Style := bsClear;
  DrawArea := Rect(16, 0, pbNoOptions.Width - 16, pbNoOptions.Height);
  // По центру, с переносом: размер текста узнаём, потом сдвигаем
  DrawText(PaintCanvas.Handle, PChar(FNoOptionsText), -1, DrawArea,
           DT_CENTER or DT_WORDBREAK or DT_CALCRECT);
  OffsetRect(DrawArea, (pbNoOptions.Width - 32 -
             (DrawArea.Right - DrawArea.Left)) div 2,
             (pbNoOptions.Height - (DrawArea.Bottom - DrawArea.Top)) div 2);
  DrawText(PaintCanvas.Handle, PChar(FNoOptionsText), -1, DrawArea,
           DT_CENTER or DT_WORDBREAK);
end;

// Расширения из поля - списком ".INC", ".BAS" (с точкой, верхний регистр)
procedure ExtsOfText(const AText: string; AList: TStrings);
var
  Rest, OneExt: string;
  SemiAt: Integer;
begin
  AList.Clear;
  Rest := StringReplace(AText, ',', ';', [rfReplaceAll]);
  Rest := StringReplace(Rest, ' ', ';', [rfReplaceAll]);
  while Rest <> '' do
  begin
    SemiAt := Pos(';', Rest);
    if SemiAt = 0 then
      SemiAt := Length(Rest) + 1;
    OneExt := UpperCase(Trim(Copy(Rest, 1, SemiAt - 1)));
    Delete(Rest, 1, SemiAt);
    if Copy(OneExt, 1, 1) = '*' then
      Delete(OneExt, 1, 1);
    if (OneExt <> '') and (OneExt[1] <> '.') then
      OneExt := '.' + OneExt;
    if (OneExt <> '') and (AList.IndexOf(OneExt) < 0) then
      AList.Add(OneExt);
  end;
end;

// Галки - по полю: расширение есть в поле - галка стоит
procedure TStrictFixForm.SyncExtChecks;
var
  Exts: TStringList;
  ExtIdx: Integer;
begin
  if FExtSyncing then
    Exit;
  FExtSyncing := True;
  Exts := TStringList.Create;
  try
    ExtsOfText(edExts.Text, Exts);
    for ExtIdx := 0 to High(FExtChecks) do
      FExtChecks[ExtIdx].Checked :=
        Exts.IndexOf(UpperCase(StrictTypicalExts[ExtIdx])) >= 0;
  finally
    Exts.Free;
    FExtSyncing := False;
  end;
end;

procedure TStrictFixForm.edExtsChange(Sender: TObject);
begin
  SyncExtChecks;
end;

// Галка: расширение - в поле или из поля; остальное в поле (дописанное
// руками) остаётся
procedure TStrictFixForm.ExtCheckClick(Sender: TObject);
var
  Exts: TStringList;
  ExtIdx, Found: Integer;
  Joined: string;
begin
  if FExtSyncing then
    Exit;
  Exts := TStringList.Create;
  try
    ExtsOfText(edExts.Text, Exts);
    for ExtIdx := 0 to High(FExtChecks) do
      if Sender = FExtChecks[ExtIdx] then
      begin
        Found := Exts.IndexOf(UpperCase(StrictTypicalExts[ExtIdx]));
        if FExtChecks[ExtIdx].Checked and (Found < 0) then
          Exts.Add(UpperCase(StrictTypicalExts[ExtIdx]))
        else if not FExtChecks[ExtIdx].Checked and (Found >= 0) then
          Exts.Delete(Found);
      end;
    Joined := '';
    for ExtIdx := 0 to Exts.Count - 1 do
    begin
      if Joined <> '' then
        Joined := Joined + ';';
      Joined := Joined + LowerCase(Exts[ExtIdx]);
    end;
    FExtSyncing := True;
    try
      edExts.Text := Joined;
    finally
      FExtSyncing := False;
    end;
  finally
    Exts.Free;
  end;
end;

// [...]: папки поиска определения - Directory Tree: стандартные (Include,
// программа, выше) с галками и свои
procedure TStrictFixForm.btnDirsClick(Sender: TObject);
var
  Checked: TStringList;
begin
  if not Assigned(FPickDirs) or FBusy then
    Exit;
  if not FPickDirs('Directory Tree - папки поиска определения', FRoots,
                   FDirItems) then
    Exit;
  SearchDirsSave(FIniFile, StrictDirsSection, FDirItems);
  Checked := TStringList.Create;
  try
    SearchDirsChecked(FRoots, FDirItems, Checked);
    if Checked.Count = 0 then
      lblStatus.Caption := 'Папок поиска нет: отметьте хотя бы одну'
    else
      lblStatus.Caption := 'Папки поиска: ' +
        StringReplace(Trim(Checked.Text), #13#10, '; ', [rfReplaceAll]);
    btnDirs.Hint := lblStatus.Caption;
  finally
    Checked.Free;
  end;
end;

// "Исправить" - правее последнего видимого элемента ряда
procedure TStrictFixForm.PlaceActions;
var
  CtlIdx, RightEdge: Integer;
  OneCtl: TControl;
begin
  RightEdge := 0;
  for CtlIdx := 0 to pnlActions.ControlCount - 1 do
  begin
    OneCtl := pnlActions.Controls[CtlIdx];
    if (OneCtl <> btnApply) and OneCtl.Visible and
       (OneCtl.Left + OneCtl.Width > RightEdge) then
      RightEdge := OneCtl.Left + OneCtl.Width;
  end;
  btnApply.Left := RightEdge + 8;
end;

procedure TStrictFixForm.Progress(const AText: string; var ACancel: Boolean);
begin
  ACancel := FAbort;
  // Не чаще трёх раз в секунду: строка не мелькает, а ход виден
  if ACancel or (GetTickCount - FLastTick < 300) then
    Exit;
  FLastTick := GetTickCount;
  lblStatus.Caption := AText;
  Application.ProcessMessages;
  ACancel := FAbort;
end;

procedure TStrictFixForm.lvItemsSelectItem(Sender: TObject; Item: TListItem;
                                           Selected: Boolean);
begin
  if Selected and not FBusy then
    ShowCurrent;
end;

// Галки строк - в список пропущенных: снята - ключ записи туда, стоит -
// оттуда. Строки, которых в списке нет (скрытые), не трогаются.
procedure TStrictFixForm.CollectChecks;
var
  RowIdx: Integer;
  Key: string;
  SkipIdx: Integer;
begin
  for RowIdx := 0 to lvItems.Items.Count - 1 do
  begin
    if RowIdx >= FItems.Count then
      Break;
    Key := StrictItemKey(TStrictError(FItems[RowIdx]));
    if lvItems.Items[RowIdx].Checked then
    begin
      SkipIdx := FSkipped.IndexOf(Key);
      if SkipIdx >= 0 then
        FSkipped.Delete(SkipIdx);
    end
    else
      FSkipped.Add(Key);
  end;
end;

procedure TStrictFixForm.chkLibClick(Sender: TObject);
begin
  if not FBusy and (FMessages <> nil) then
    FillItems;
end;

procedure TStrictFixForm.lbOptionsClick(Sender: TObject);
begin
  UpdateApply;
end;

// Двойной щелчок по найденному определению - открыть его
procedure TStrictFixForm.lbOptionsDblClick(Sender: TObject);
var
  Option: string;
begin
  if (CurOptions = nil) or (lbOptions.ItemIndex < 0) or
     not Assigned(FOpenLine) then
    Exit;
  Option := CurOptions[lbOptions.ItemIndex];
  if Option[1] = 'D' then
    FOpenLine(OptionField(Option, 1), StrToIntDef(OptionField(Option, 2), 1))
  else if CurItem <> nil then
    FOpenLine(CurItem.FileName, StrToIntDef(OptionField(Option, 2), 1));
end;

procedure TStrictFixForm.btnOpenClick(Sender: TObject);
begin
  if (CurItem <> nil) and Assigned(FOpenLine) then
    FOpenLine(CurItem.FileName, CurItem.Line);
end;

procedure TStrictFixForm.btnOpenOtherClick(Sender: TObject);
begin
  if (CurItem <> nil) and (CurItem.OtherFile <> '') and Assigned(FOpenLine) then
    FOpenLine(CurItem.OtherFile, CurItem.OtherLine);
end;

procedure TStrictFixForm.btnFindClick(Sender: TObject);
var
  Item: TStrictError;
  Found, SearchRoots: TStringList;
  FoundIdx, FoundTotal: Integer;
  Done, AsProc: Boolean;
begin
  if FBusy then
  begin
    FAbort := True;
    Exit;
  end;
  Item := CurItem;
  if (Item = nil) or not StrictNeedsSearch(Item, AsProc) then
    Exit;
  SearchRoots := TStringList.Create;
  Found := TStringList.Create;
  FoundTotal := 0;
  FBusy := True;
  FAbort := False;
  FLastTick := 0;
  btnFind.Caption := 'Стоп';
  lvItems.Enabled := False;
  btnBuild.Enabled := False;
  btnClose.Enabled := False;
  try
    // Отмеченные стандартные и свои; вложенные в отмеченную - не дважды
    SearchDirsChecked(FRoots, FDirItems, SearchRoots);
    Done := StrictFindDefinitions(Item.Name, AsProc, SearchRoots, FMainFile,
                                  Found, Progress, edExts.Text);
    // Найденное - к вариантам (прежние найденные - заново)
    FoundTotal := Found.Count;
    for FoundIdx := CurOptions.Count - 1 downto 0 do
      if CurOptions[FoundIdx][1] = 'D' then
        CurOptions.Delete(FoundIdx);
    for FoundIdx := 0 to Found.Count - 1 do
      CurOptions.Add('D|' + Found[FoundIdx]);
  finally
    FBusy := False;
    btnFind.Caption := 'Найти определение';
    lvItems.Enabled := True;
    btnBuild.Enabled := True;
    btnClose.Enabled := True;
    Found.Free;
    SearchRoots.Free;
  end;
  if FoundTotal = 0 then
    lblStatus.Caption := 'Определение ' + Item.Name + ' не найдено - не могу ' +
                         'предложить вариант исправления'
  else
    lblStatus.Caption := 'Поиск определения ' + Item.Name + ' закончен';
  if not Done then
    lblStatus.Caption := 'Поиск остановлен. ' + lblStatus.Caption;
  ShowCurrent;
end;

procedure TStrictFixForm.btnApplyClick(Sender: TObject);
var
  Item: TStrictError;
  OldText, NewText, Target, Option, IncFile: string;
  MainLines: TStringList;
  LineNo: Integer;
  AddLine: Boolean;
begin
  Item := CurItem;
  if (Item = nil) or IsDone or not Assigned(FEditLine) then
    Exit;
  case Item.Kind of
    skLabelElsewhere, skLabelMissing:
      if LabelFix(Item, OldText, NewText, Target) then
        ReplaceInLine(Item, Item.Name, Target, fixGoto);
    skCaseOp:
      ReplaceInLine(Item, '', '', fixCase);
  else
    begin
      if lbOptions.ItemIndex < 0 then
        Exit;
      Option := CurOptions[lbOptions.ItemIndex];
      if Option[1] = 'N' then
      begin
        ReplaceInLine(Item, Item.Name, OptionField(Option, 1), fixWord);
        Exit;
      end;
      // Подключить найденный файл к главному
      IncFile := OptionField(Option, 1);
      MainLines := TStringList.Create;
      try
        if not FileLines(FMainFile, MainLines) then
        begin
          lblStatus.Caption := 'Не прочитан ' + FMainFile;
          Exit;
        end;
        StrictIncludePlan(MainLines, IncFile, ExtractFilePath(FMainFile),
                          FIncDir, LineNo, OldText, NewText, AddLine);
      finally
        MainLines.Free;
      end;
      if FEditLine(FMainFile, LineNo, OldText, NewText, AddLine) then
      begin
        if AddLine then
          MarkDone(ExtractFileName(FMainFile) + ', строка ' +
                   IntToStr(LineNo) + ' добавлена: ' + NewText)
        else
          MarkDone(ExtractFileName(FMainFile) + ', строка ' +
                   IntToStr(LineNo) + ' раскомментирована: ' + Trim(NewText));
      end
      else
        lblStatus.Caption := 'Не подключено: строка ' + IntToStr(LineNo) +
          ' в редакторе уже другая или файл не открылся';
    end;
  end;
end;

procedure TStrictFixForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FBusy then
  begin
    FAbort := True;
    CanClose := False;
  end;
end;

// Окно немодальное и обычное: может уйти за главное окно - поднимает его
// меню Started Util
procedure TStrictFixForm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  // Не над главным окном: окна утилит - обычные, на передний план их
  // поднимает меню Started Util
end;

// Положение и размер окна, высота списка записей и пояснения - из
// editor.ini
procedure TStrictFixForm.LoadPlacement;
const
  Sect = 'StrictFixWindow';
var
  Ini: TIniFile;
  WinLeft, WinTop, WinWidth, WinHeight, ListHeight, ExplainHeight: Integer;
  Work: TRect;
begin
  if (FIniFile = '') or not FileExists(FIniFile) then
    Exit;
  Ini := TIniFile.Create(FIniFile);
  try
    WinLeft := Ini.ReadInteger(Sect, 'Left', MaxInt);
    WinTop := Ini.ReadInteger(Sect, 'Top', MaxInt);
    WinWidth := Ini.ReadInteger(Sect, 'Width', Width);
    WinHeight := Ini.ReadInteger(Sect, 'Height', Height);
    ListHeight := Ini.ReadInteger(Sect, 'ListHeight', 0);
    ExplainHeight := Ini.ReadInteger(Sect, 'ExplainHeight', 0);
    if (WinLeft <> MaxInt) and (WinTop <> MaxInt) then
    begin
      // Окно - целиком на рабочем столе (монитор могли отключить)
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
    if ListHeight >= 60 then
      lvItems.Height := ListHeight;
    if ExplainHeight >= 30 then
      memExplain.Height := ExplainHeight;
    edExts.Text := Ini.ReadString(Sect, 'Exts', StrictDefaultExts);
    SearchDirsLoad(FIniFile, StrictDirsSection, FDirItems);
    if Ini.ReadBool(Sect, 'Maximized', False) then
      WindowState := wsMaximized;
  finally
    Ini.Free;
  end;
end;

procedure TStrictFixForm.SavePlacement;
const
  Sect = 'StrictFixWindow';
var
  Ini: TIniFile;
  Place: TWindowPlacement;
begin
  if FIniFile = '' then
    Exit;
  // Размер "в обычном виде", и когда окно развёрнуто
  Place.length := SizeOf(Place);
  if not GetWindowPlacement(Handle, @Place) then
    Exit;
  Ini := TIniFile.Create(FIniFile);
  try
    Ini.WriteInteger(Sect, 'Left', Place.rcNormalPosition.Left);
    Ini.WriteInteger(Sect, 'Top', Place.rcNormalPosition.Top);
    Ini.WriteInteger(Sect, 'Width', Place.rcNormalPosition.Right -
                     Place.rcNormalPosition.Left);
    Ini.WriteInteger(Sect, 'Height', Place.rcNormalPosition.Bottom -
                     Place.rcNormalPosition.Top);
    Ini.WriteBool(Sect, 'Maximized', WindowState = wsMaximized);
    Ini.WriteInteger(Sect, 'ListHeight', lvItems.Height);
    Ini.WriteInteger(Sect, 'ExplainHeight', memExplain.Height);
    Ini.WriteString(Sect, 'Exts', Trim(edExts.Text));

  finally
    Ini.Free;
  end;
end;

// Крестик: окно немодальное, закрытие = Закрыть (без сборки)
procedure TStrictFixForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if ModalResult = mrNone then
    ModalResult := mrCancel;
  Action := caHide;
end;

function StrictFixDialog(AOwner: TComponent;
                         AMessages, ARoots, ALibDirs: TStrings;
                         const AMainFile, AIncDir: string;
                         AOpenLine: TStrictOpenLine;
                         AEditLine: TStrictEditLine;
                         const AIniFile: string;
                         APickDirs: TStrictPickDirs): TModalResult;
var
  Dlg: TStrictFixForm;
begin
  Result := mrCancel;
  if OpenStrictDlg <> nil then
    Exit;
  Dlg := TStrictFixForm.CreateNew(AOwner);
  OpenStrictDlg := Dlg;
  try
    Dlg.FRoots := ARoots;
    Dlg.FLibDirs := ALibDirs;
    Dlg.FMessages := AMessages;
    Dlg.FMainFile := AMainFile;
    Dlg.FIncDir := AIncDir;
    Dlg.FOpenLine := AOpenLine;
    Dlg.FEditLine := AEditLine;
    Dlg.FIniFile := AIniFile;
    Dlg.FPickDirs := APickDirs;
    Dlg.BuildControls;
    Dlg.LoadPlacement;
    StrictLoadSkipped(AIniFile, AMainFile, Dlg.FSkipped);
    Dlg.FillItems;
    // Немодально: ждём здесь, пока окно не закроют кнопкой (ModalResult)
    // или крестиком; программу закрыли - без сборки
    Dlg.Show;
    repeat
      Application.HandleMessage;
    until (Dlg.ModalResult <> mrNone) or not Dlg.Visible or
          Application.Terminated;
    Result := Dlg.ModalResult;
    if Application.Terminated or (Result = mrNone) then
      Result := mrCancel;
    Dlg.SavePlacement;
    Dlg.CollectChecks;
    StrictSaveSkipped(AIniFile, AMainFile, Dlg.FSkipped);
    Dlg.Hide;
  finally
    OpenStrictDlg := nil;
    Dlg.Free;
  end;
end;

function StrictItemKey(AItem: TStrictError): string;
begin
  // Без номера строки: строки сдвигаются при правках выше
  Result := UpperCase(ExtractFileName(AItem.FileName)) + ': ' + AItem.Text;
end;

function SkipSection(const AMainFile: string): string;
begin
  Result := 'RapidQ.StrictSkip ' + LowerCase(ExpandFileName(AMainFile));
end;

procedure StrictLoadSkipped(const AIniFile, AMainFile: string;
                            ASkipped: TStrings);
var
  Ini: TIniFile;
  Count, KeyIdx: Integer;
begin
  ASkipped.Clear;
  if (AIniFile = '') or not FileExists(AIniFile) then
    Exit;
  Ini := TIniFile.Create(AIniFile);
  try
    Count := Ini.ReadInteger(SkipSection(AMainFile), 'Count', 0);
    for KeyIdx := 1 to Count do
      ASkipped.Add(Ini.ReadString(SkipSection(AMainFile), IntToStr(KeyIdx), ''));
  finally
    Ini.Free;
  end;
end;

procedure StrictSaveSkipped(const AIniFile, AMainFile: string;
                            ASkipped: TStrings);
var
  Ini: TIniFile;
  KeyIdx: Integer;
begin
  if AIniFile = '' then
    Exit;
  Ini := TIniFile.Create(AIniFile);
  try
    Ini.EraseSection(SkipSection(AMainFile));
    if ASkipped.Count = 0 then
      Exit;
    Ini.WriteInteger(SkipSection(AMainFile), 'Count', ASkipped.Count);
    for KeyIdx := 0 to ASkipped.Count - 1 do
      Ini.WriteString(SkipSection(AMainFile), IntToStr(KeyIdx + 1),
                      ASkipped[KeyIdx]);
  finally
    Ini.Free;
  end;
end;

function StrictDropSkipped(AMessages, ASkipped: TStrings): Integer;
var
  MsgIdx: Integer;
  Item: TStrictError;
begin
  Result := 0;
  if ASkipped.Count = 0 then
    Exit;
  for MsgIdx := AMessages.Count - 1 downto 0 do
  begin
    Item := StrictParseMessage(AMessages[MsgIdx]);
    if Item = nil then
      Continue;
    try
      if (Item.Kind <> skLimit) and
         (ASkipped.IndexOf(StrictItemKey(Item)) >= 0) then
      begin
        AMessages.Delete(MsgIdx);
        Inc(Result);
      end;
    finally
      Item.Free;
    end;
  end;
end;

function StrictFixDialogActive: Boolean;
begin
  Result := OpenStrictDlg <> nil;
  if Result then
  begin
    if OpenStrictDlg.WindowState = wsMinimized then
      OpenStrictDlg.WindowState := wsNormal;
    OpenStrictDlg.BringToFront;
  end;
end;

end.
