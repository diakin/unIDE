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
  ExtCtrls, ComCtrls,
  StrictFix,    // разбор записей и варианты исправления
  UiButton;     // TUiButton

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
function StrictFixDialog(AOwner: TComponent;
                         AMessages, ARoots, ALibDirs: TStrings;
                         const AMainFile, AIncDir: string;
                         AOpenLine: TStrictOpenLine;
                         AEditLine: TStrictEditLine): TModalResult;

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
    FBusy, FAbort: Boolean;
    FLastTick: Cardinal;
    FErrCount: Integer;
    lblInfo: TLabel;
    chkLib: TCheckBox;       // показать подозрения в файлах папок Include
    lvItems: TListView;
    splItems: TSplitter;
    memExplain: TMemo;
    pnlActions: TPanel;
    btnOpen: TUiButton;
    btnOpenOther: TUiButton;
    btnFind: TUiButton;
    btnApply: TUiButton;
    lblOptions: TLabel;
    lbOptions: TListBox;
    pnlBottom: TPanel;
    lblStatus: TLabel;
    btnBuild: TUiButton;
    btnClose: TUiButton;
    procedure BuildControls;
    procedure FillItems;
    procedure chkLibClick(Sender: TObject);
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
  public
    destructor Destroy; override;
  end;

const
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

  FItems := TList.Create;
  FOptions := TList.Create;
  FPrepared := TStringList.Create;
  FDone := TStringList.Create;

  lblInfo := TLabel.Create(Self);
  lblInfo.Parent := Self;
  lblInfo.Align := alTop;
  lblInfo.AutoSize := True;
  lblInfo.WordWrap := True;
  chkLib := TCheckBox.Create(Self);
  chkLib.Parent := Self;
  chkLib.Top := 30;
  chkLib.Height := 20;
  chkLib.Align := alTop;
  chkLib.Caption := ' Подозрения в файлах папок Include';
  chkLib.Hint := 'Чужие библиотеки (inc из папок Include): подозрения в них ' +
                 'обычно не про вашу программу - по умолчанию скрыты';
  chkLib.Checked := False;
  chkLib.OnClick := chkLibClick;

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
  lvItems := TListView.Create(Self);
  lvItems.Parent := Self;
  lvItems.Top := 40;
  lvItems.Height := 170;
  lvItems.Align := alTop;
  lvItems.ViewStyle := vsReport;
  lvItems.RowSelect := True;
  lvItems.ReadOnly := True;
  lvItems.HideSelection := False;
  lvItems.OnSelectItem := lvItemsSelectItem;
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
  btnApply := MakeButton(pnlActions, 'Исправить', 472, 5, 300, btnApplyClick);

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
  Pass, MsgIdx, Limits, Suspects, LibSuspects, ItemIdx: Integer;
  Item: TStrictError;
  Row: TListItem;
begin
  // Заново (переключение "Подозрения в файлах папок Include")
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
      if Item.Level = slError then
        Inc(FErrCount)
      else
        Inc(Suspects);
      FItems.Add(Item);
      FOptions.Add(TStringList.Create);
      Row := lvItems.Items.Add;
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

procedure TStrictFixForm.Progress(const AText: string; var ACancel: Boolean);
begin
  ACancel := FAbort;
  if ACancel or (GetTickCount - FLastTick < 100) then
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
  Found: TStringList;
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
    Done := StrictFindDefinitions(Item.Name, AsProc, FRoots, FMainFile,
                                  Found, Progress);
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

function StrictFixDialog(AOwner: TComponent;
                         AMessages, ARoots, ALibDirs: TStrings;
                         const AMainFile, AIncDir: string;
                         AOpenLine: TStrictOpenLine;
                         AEditLine: TStrictEditLine): TModalResult;
var
  Dlg: TStrictFixForm;
begin
  Dlg := TStrictFixForm.CreateNew(AOwner);
  try
    Dlg.FRoots := ARoots;
    Dlg.FLibDirs := ALibDirs;
    Dlg.FMessages := AMessages;
    Dlg.FMainFile := AMainFile;
    Dlg.FIncDir := AIncDir;
    Dlg.FOpenLine := AOpenLine;
    Dlg.FEditLine := AEditLine;
    Dlg.BuildControls;
    Dlg.FillItems;
    Result := Dlg.ShowModal;
  finally
    Dlg.Free;
  end;
end;

end.
