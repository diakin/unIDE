unit DlgStrictFix;

// ---------------------------------------------------------------------------
//  Окно "Строгая проверка: ошибки" - после строгой проверки перед rc.exe
//  (галка "FB smart" в рамке Project, без "Info only"). Для каждой ошибки -
//  причина и что можно сделать (StrictFix): объект без DIM / CREATE - найти
//  его определение в других файлах и подключить файл; GOTO в чужую
//  процедуру - заменить похожей меткой своей процедуры. Правки идут через
//  редактор (AEditLine), их можно отменить там же. Окно строится кодом.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, StdCtrls,
  ExtCtrls, ComCtrls,
  StrictFix,    // разбор ошибок и варианты исправления
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

// Показать окно. AMessages - строки лога перевода (ошибки берутся из них);
// ARoots - папки поиска определений (Include, программа, папка выше);
// AMainFile - главный .bas, AIncDir - папка -I. mrIgnore - собрать rc.exe
// как есть, иначе - не собирать.
function StrictFixDialog(AOwner: TComponent; AMessages, ARoots: TStrings;
                         const AMainFile, AIncDir: string;
                         AOpenLine: TStrictOpenLine;
                         AEditLine: TStrictEditLine): TModalResult;

implementation

type
  TStrictFixForm = class(TForm)
  private
    FErrors: TList;          // TStrictError, свои
    FFound: TList;           // TStringList на ошибку: найденные определения
    FDone: TStringList;      // номера исправленных ошибок
    FRoots: TStrings;
    FMainFile, FIncDir: string;
    FOpenLine: TStrictOpenLine;
    FEditLine: TStrictEditLine;
    FBusy, FAbort: Boolean;
    FLastTick: Cardinal;
    lblInfo: TLabel;
    lvErrors: TListView;
    splErrors: TSplitter;
    memExplain: TMemo;
    pnlActions: TPanel;
    btnOpen: TUiButton;
    btnFind: TUiButton;
    btnApply: TUiButton;
    lblFound: TLabel;
    lbFound: TListBox;
    pnlBottom: TPanel;
    lblStatus: TLabel;
    btnBuild: TUiButton;
    btnClose: TUiButton;
    procedure BuildControls;
    procedure FillErrors(AMessages: TStrings);
    function  CurIndex: Integer;
    function  CurError: TStrictError;
    function  FileLines(const AFile: string; ALines: TStrings): Boolean;
    function  LabelFix(AErr: TStrictError; var AOld, ANew,
                       ATarget: string): Boolean;
    procedure ShowCurrent;
    procedure MarkDone(AIdx: Integer; const ANote: string);
    procedure Progress(const AText: string; var ACancel: Boolean);
    procedure lvErrorsSelectItem(Sender: TObject; Item: TListItem;
                                 Selected: Boolean);
    procedure lbFoundClick(Sender: TObject);
    procedure lbFoundDblClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnFindClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  public
    destructor Destroy; override;
  end;

{ TStrictFixForm }

destructor TStrictFixForm.Destroy;
var
  ItemIdx: Integer;
begin
  if FErrors <> nil then
    for ItemIdx := 0 to FErrors.Count - 1 do
      TObject(FErrors[ItemIdx]).Free;
  if FFound <> nil then
    for ItemIdx := 0 to FFound.Count - 1 do
      TObject(FFound[ItemIdx]).Free;
  FErrors.Free;
  FFound.Free;
  FDone.Free;
  inherited Destroy;
end;

procedure TStrictFixForm.BuildControls;

  procedure AddCol(const ACaption: string; AWidth: Integer);
  var
    Col: TListColumn;
  begin
    Col := lvErrors.Columns.Add;
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
  Caption := 'Строгая проверка: ошибки';
  Width := 900;
  Height := 640;
  Position := poScreenCenter;
  BorderIcons := [biSystemMenu, biMaximize];
  Constraints.MinWidth := 640;
  Constraints.MinHeight := 460;
  Font.Name := 'Tahoma';
  Font.Height := -11;
  ShowHint := True;
  AutoScroll := False;
  OnCloseQuery := FormCloseQuery;

  FErrors := TList.Create;
  FFound := TList.Create;
  FDone := TStringList.Create;

  lblInfo := TLabel.Create(Self);
  lblInfo.Parent := Self;
  lblInfo.Align := alTop;
  lblInfo.AutoSize := True;
  lblInfo.WordWrap := True;

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
  btnBuild.Hint := 'Запустить rc.exe, не исправляя ошибки строгой проверки';
  btnClose := MakeButton(pnlBottom, 'Закрыть', 196, 26, 100, nil);
  btnClose.ModalResult := mrCancel;
  btnClose.Hint := 'Закрыть окно, rc.exe не запускать';

  // Сверху вниз: ошибки | сплиттер | пояснение | кнопки | найденное
  lvErrors := TListView.Create(Self);
  lvErrors.Parent := Self;
  lvErrors.Top := 40;
  lvErrors.Height := 150;
  lvErrors.Align := alTop;
  lvErrors.ViewStyle := vsReport;
  lvErrors.RowSelect := True;
  lvErrors.ReadOnly := True;
  lvErrors.HideSelection := False;
  lvErrors.OnSelectItem := lvErrorsSelectItem;
  AddCol('Где', 210);
  AddCol('Ошибка', 640);

  splErrors := TSplitter.Create(Self);
  splErrors.Parent := Self;
  splErrors.Top := 200;
  splErrors.Height := 5;
  splErrors.Align := alTop;
  splErrors.MinSize := 60;

  memExplain := TMemo.Create(Self);
  memExplain.Parent := Self;
  memExplain.Top := 210;
  memExplain.Height := 170;
  memExplain.Align := alTop;
  memExplain.ReadOnly := True;
  memExplain.WordWrap := True;
  memExplain.ScrollBars := ssVertical;

  pnlActions := TPanel.Create(Self);
  pnlActions.Parent := Self;
  pnlActions.Top := 390;
  pnlActions.Height := 34;
  pnlActions.Align := alTop;
  pnlActions.BevelOuter := bvNone;
  pnlActions.Caption := '';
  btnOpen := MakeButton(pnlActions, 'Открыть строку', 8, 5, 120, btnOpenClick);
  btnOpen.Hint := 'Открыть файл в редакторе на строке ошибки';
  btnFind := MakeButton(pnlActions, 'Найти определение', 136, 5, 140,
                        btnFindClick);
  btnFind.Hint := 'Искать DIM / CREATE в .inc, .bas, .cmp папок Include, ' +
                  'программы и папки выше; во время поиска - остановить';
  btnApply := MakeButton(pnlActions, 'Исправить', 284, 5, 300, btnApplyClick);

  lblFound := TLabel.Create(Self);
  lblFound.Parent := Self;
  lblFound.Top := 430;
  lblFound.Align := alTop;
  lblFound.Caption := ' Найденные определения (выберите, какой файл подключить; ' +
                      'двойной щелчок - открыть):';
  lbFound := TListBox.Create(Self);
  lbFound.Parent := Self;
  lbFound.Align := alClient;
  lbFound.OnClick := lbFoundClick;
  lbFound.OnDblClick := lbFoundDblClick;
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

procedure TStrictFixForm.FillErrors(AMessages: TStrings);
var
  MsgIdx: Integer;
  Err: TStrictError;
  Item: TListItem;
begin
  for MsgIdx := 0 to AMessages.Count - 1 do
  begin
    Err := StrictParseError(AMessages[MsgIdx]);
    if Err = nil then
      Continue;
    FErrors.Add(Err);
    FFound.Add(TStringList.Create);
    Item := lvErrors.Items.Add;
    Item.Caption := ExtractFileName(Err.FileName) + '(' +
                    IntToStr(Err.Line) + ')';
    Item.SubItems.Add(Err.Text);
  end;
  lblInfo.Caption := ' Строгая проверка (FB Smart) нашла ошибок: ' +
    IntToStr(FErrors.Count) + '. rc.exe не запускался. Ниже - причина ' +
    'каждой и что можно сделать; правки идут через редактор, их можно ' +
    'отменить там же (Undo).';
  if lvErrors.Items.Count > 0 then
    lvErrors.Selected := lvErrors.Items[0];
  ShowCurrent;
end;

function TStrictFixForm.CurIndex: Integer;
begin
  Result := -1;
  if lvErrors.Selected <> nil then
    Result := lvErrors.Selected.Index;
end;

function TStrictFixForm.CurError: TStrictError;
begin
  Result := nil;
  if (CurIndex >= 0) and (CurIndex < FErrors.Count) then
    Result := TStrictError(FErrors[CurIndex]);
end;

// Замена метки: строка GOTO и её текст с похожей меткой. False - похожей
// метки в процедуре нет
function TStrictFixForm.LabelFix(AErr: TStrictError; var AOld, ANew,
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
    if not FileLines(AErr.FileName, Lines) or (AErr.Line < 1) or
       (AErr.Line > Lines.Count) then
      Exit;
    if not StrictProcAt(Lines, AErr.Line - 1, First, Last, ProcName) then
      Exit;
    StrictLabelsIn(Lines, First, Last, Labels);
    StrictSimilarLabels(AErr.Name, Labels, Similar);
    if Similar.Count = 0 then
      Exit;
    ATarget := Similar.Names[0];
    AOld := Lines[AErr.Line - 1];
    Result := StrictReplaceGoto(AOld, AErr.Name, ATarget, ANew);
  finally
    Similar.Free;
    Labels.Free;
    Lines.Free;
  end;
end;

procedure TStrictFixForm.ShowCurrent;
var
  Err: TStrictError;
  Lines, Found: TStringList;
  FoundIdx: Integer;
  OldText, NewText, Target, Line, Note: string;
  Parts: TStringList;
begin
  Err := CurError;
  btnOpen.Enabled := Err <> nil;
  btnFind.Visible := (Err <> nil) and (Err.Kind = skUndeclared);
  btnApply.Visible := False;
  lblFound.Visible := (Err <> nil) and (Err.Kind = skUndeclared);
  lbFound.Visible := lblFound.Visible;
  memExplain.Lines.Clear;
  if Err = nil then
    Exit;
  Lines := TStringList.Create;
  try
    if FileLines(Err.FileName, Lines) then
      memExplain.Text := StrictExplain(Err, Lines)
    else
      memExplain.Text := StrictExplain(Err, nil);
  finally
    Lines.Free;
  end;
  if FDone.IndexOf(IntToStr(CurIndex)) >= 0 then
    memExplain.Lines.Insert(0, 'ИСПРАВЛЕНО. Проверка пройдёт заново при ' +
                               'следующей сборке.'#13#10);

  case Err.Kind of
    skLabelElsewhere, skLabelMissing:
      if LabelFix(Err, OldText, NewText, Target) then
      begin
        btnApply.Caption := 'Заменить на ' + Err.Statement + ' ' + Target;
        btnApply.Hint := 'Строка ' + IntToStr(Err.Line) + ': ' + Trim(OldText) +
                         '  ->  ' + Trim(NewText);
        btnApply.Visible := True;
        btnApply.Enabled := FDone.IndexOf(IntToStr(CurIndex)) < 0;
      end;
    skUndeclared:
      begin
        Found := TStringList(FFound[CurIndex]);
        lbFound.Items.Clear;
        Parts := TStringList.Create;
        try
          for FoundIdx := 0 to Found.Count - 1 do
          begin
            // файл|строка|закомментировано|текст
            Parts.Clear;
            Line := Found[FoundIdx];
            while Pos('|', Line) > 0 do
            begin
              if Parts.Count = 3 then
                Break;
              Parts.Add(Copy(Line, 1, Pos('|', Line) - 1));
              Delete(Line, 1, Pos('|', Line));
            end;
            Parts.Add(Line);
            if Parts.Count < 4 then
              Continue;
            Note := '';
            if Parts[2] = '1' then
              Note := '  [закомментировано]';
            lbFound.Items.Add(Parts[0] + '(' + Parts[1] + '): ' + Parts[3] +
                              Note);
          end;
        finally
          Parts.Free;
        end;
        btnApply.Caption := 'Подключить выбранный файл';
        btnApply.Hint := 'Раскомментировать $INCLUDE этого файла в программе ' +
                         'или добавить строку $INCLUDE';
        btnApply.Visible := Found.Count > 0;
        btnApply.Enabled := (lbFound.ItemIndex >= 0) and
                            (FDone.IndexOf(IntToStr(CurIndex)) < 0);
      end;
  end;
end;

procedure TStrictFixForm.MarkDone(AIdx: Integer; const ANote: string);
begin
  if FDone.IndexOf(IntToStr(AIdx)) < 0 then
    FDone.Add(IntToStr(AIdx));
  if (AIdx >= 0) and (AIdx < lvErrors.Items.Count) then
    lvErrors.Items[AIdx].SubItems[0] := 'исправлено (' + ANote + '): ' +
      TStrictError(FErrors[AIdx]).Text;
  lblStatus.Caption := ANote;
  ShowCurrent;
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

procedure TStrictFixForm.lvErrorsSelectItem(Sender: TObject; Item: TListItem;
                                            Selected: Boolean);
begin
  if Selected and not FBusy then
    ShowCurrent;
end;

procedure TStrictFixForm.lbFoundClick(Sender: TObject);
begin
  btnApply.Enabled := (lbFound.ItemIndex >= 0) and (CurError <> nil) and
                      (FDone.IndexOf(IntToStr(CurIndex)) < 0);
end;

// Найденное определение: файл и строка - из записи FFound
procedure TStrictFixForm.lbFoundDblClick(Sender: TObject);
var
  Rec: string;
  SepPos: Integer;
  FileName: string;
begin
  if (CurError = nil) or (lbFound.ItemIndex < 0) or
     not Assigned(FOpenLine) then
    Exit;
  Rec := TStringList(FFound[CurIndex])[lbFound.ItemIndex];
  SepPos := Pos('|', Rec);
  FileName := Copy(Rec, 1, SepPos - 1);
  Delete(Rec, 1, SepPos);
  FOpenLine(FileName, StrToIntDef(Copy(Rec, 1, Pos('|', Rec) - 1), 1));
end;

procedure TStrictFixForm.btnOpenClick(Sender: TObject);
begin
  if (CurError <> nil) and Assigned(FOpenLine) then
    FOpenLine(CurError.FileName, CurError.Line);
end;

procedure TStrictFixForm.btnFindClick(Sender: TObject);
var
  Err: TStrictError;
  Found: TStringList;
  Done: Boolean;
begin
  if FBusy then
  begin
    FAbort := True;
    Exit;
  end;
  Err := CurError;
  if (Err = nil) or (Err.Kind <> skUndeclared) then
    Exit;
  Found := TStringList(FFound[CurIndex]);
  Found.Clear;
  FBusy := True;
  FAbort := False;
  FLastTick := 0;
  btnFind.Caption := 'Стоп';
  lvErrors.Enabled := False;
  btnBuild.Enabled := False;
  btnClose.Enabled := False;
  try
    Done := StrictFindDefinitions(Err.Name, FRoots, FMainFile, Found, Progress);
  finally
    FBusy := False;
    btnFind.Caption := 'Найти определение';
    lvErrors.Enabled := True;
    btnBuild.Enabled := True;
    btnClose.Enabled := True;
  end;
  if Found.Count = 0 then
    lblStatus.Caption := 'DIM / CREATE ' + Err.Name + ' не найдено - не могу ' +
                         'предложить вариант исправления'
  else
    lblStatus.Caption := Format('Найдено определений %s: %d',
                                [Err.Name, Found.Count]);
  if not Done then
    lblStatus.Caption := 'Поиск остановлен. ' + lblStatus.Caption;
  ShowCurrent;
end;

procedure TStrictFixForm.btnApplyClick(Sender: TObject);
var
  Err: TStrictError;
  OldText, NewText, Target, Rec, IncFile: string;
  MainLines: TStringList;
  LineNo: Integer;
  AddLine: Boolean;
begin
  Err := CurError;
  if (Err = nil) or not Assigned(FEditLine) then
    Exit;
  case Err.Kind of
    skLabelElsewhere, skLabelMissing:
      begin
        if not LabelFix(Err, OldText, NewText, Target) then
          Exit;
        if FEditLine(Err.FileName, Err.Line, OldText, NewText, False) then
          MarkDone(CurIndex, 'строка ' + IntToStr(Err.Line) + ': ' +
                   Trim(NewText))
        else
          lblStatus.Caption := 'Не исправлено: строка ' + IntToStr(Err.Line) +
            ' в редакторе уже другая или файл не открылся';
      end;
    skUndeclared:
      begin
        if lbFound.ItemIndex < 0 then
          Exit;
        Rec := TStringList(FFound[CurIndex])[lbFound.ItemIndex];
        IncFile := Copy(Rec, 1, Pos('|', Rec) - 1);
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
            MarkDone(CurIndex, ExtractFileName(FMainFile) + ', строка ' +
                     IntToStr(LineNo) + ' добавлена: ' + NewText)
          else
            MarkDone(CurIndex, ExtractFileName(FMainFile) + ', строка ' +
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

function StrictFixDialog(AOwner: TComponent; AMessages, ARoots: TStrings;
                         const AMainFile, AIncDir: string;
                         AOpenLine: TStrictOpenLine;
                         AEditLine: TStrictEditLine): TModalResult;
var
  Dlg: TStrictFixForm;
begin
  Dlg := TStrictFixForm.CreateNew(AOwner);
  try
    Dlg.FRoots := ARoots;
    Dlg.FMainFile := AMainFile;
    Dlg.FIncDir := AIncDir;
    Dlg.FOpenLine := AOpenLine;
    Dlg.FEditLine := AEditLine;
    Dlg.BuildControls;
    Dlg.FillErrors(AMessages);
    Result := Dlg.ShowModal;
  finally
    Dlg.Free;
  end;
end;

end.
