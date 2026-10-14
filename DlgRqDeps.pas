unit DlgRqDeps;

// ---------------------------------------------------------------------------
//  Окно "Недостающие файлы" перед сборкой RapidQ (RqDeps). Показывается,
//  когда $INCLUDE, $RESOURCE или DLL из DECLARE ... LIB нет там, где их
//  возьмёт rc.exe / Windows. Сразу ищет их на диске (Include, общая
//  Include, папка программы с подпапками, папка выше), выбирает копию
//  (inc - совпадающую с эталоном) и копирует отмеченные: inc и ресурсы - в
//  папку -I сборки (её можно сменить на папку программы), DLL - в папку
//  программы (exe). Окно строится кодом, без .dfm.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, StdCtrls,
  ExtCtrls, ComCtrls, Dialogs, RichEdit, CommCtrl, IniFiles,
  ClrScheme,    // схема подсветки для просмотра
  SchemeRtf,    // текст -> RTF с цветами схемы
  IncCheck,     // эталон, TIncProgress
  RqDeps,       // TRqDepScan, поиск и выбор копий
  UiButton,     // TUiButton
  UiComCtrls,   // TUiListView - шапка колонок в цветах темы
  UiStdCtrls;   // TUiCheckBox

type
  // Выбор папок поиска - окно Directory Tree главного окна. APreselect -
  // папка, которую раскрыть; ADirs - отмеченные папки через ";"
  TRqPickDirs = function(const APreselect: string;
                         var ADirs: string): Boolean of object;
  // Замена строки ALine файла AFile в редакторе (AOld - прежний текст) и
  // сохранение файла; True - заменено
  TRqEditLine = function(const AFile: string; ALine: Integer;
                         const AOld, ANew: string;
                         AInsert: Boolean): Boolean of object;

// Показать окно. AScan - результат проверки (есть недостающие); ARoots -
// шаги поиска "подпись|папка"; ARefDir / ASysDir - эталон для inc. ALog -
// что скопировано (строки для лога сборки); AIgnore - имена (верхний
// регистр), про которые больше не спрашивать. AIniFile - editor.ini:
// положение окна, свои папки поиска. True - собирать дальше.
//
// Окно немодальное: пока оно открыто, с главным окном можно работать.
// Функция ждёт его закрытия (свой цикл сообщений), поэтому сборка
// продолжается после него, как раньше.
function RqDepsDialog(AOwner: TComponent; AScan: TRqDepScan; ARoots: TStrings;
                      const ARefDir, ASysDir: string;
                      ALog, AIgnore: TStrings;
                      AScheme: TClrScheme = nil;
                      const AIniFile: string = '';
                      APickDirs: TRqPickDirs = nil;
                      AEditLine: TRqEditLine = nil): Boolean;

// Окно уже открыто (сборка ждёт его): поднять его наверх, True
function RqDepsDialogActive: Boolean;

// Свои папки поиска (кнопка [...] в окне) - в конец ARoots шагами
// "RqDepsUserRootLabel|папка"; хранятся в AIniFile, [RqDepsSearch] Dirs
procedure RqDepsAddUserRoots(ARoots: TStrings; const AIniFile: string);

const
  RqDepsUserRootLabel = 'своя папка';

implementation

type
  // TRichEdit Delphi 7 создаёт окно RichEdit 1.0 (RICHED32.DLL, класс
  // RICHEDIT). Оно не показывает подложку символов из RTF (\highlight), а
  // ею просмотр выделяет строки с ошибками и строку перехода. Этот - то же
  // самое окном RichEdit 2.0 (RICHED20.DLL, класс RichEdit20A); нет DLL -
  // остаётся 1.0.
  TRichEdit20 = class(TRichEdit)
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  end;

var
  RichEdit20Lib: HMODULE = 0;

procedure TRichEdit20.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  if RichEdit20Lib = 0 then
    RichEdit20Lib := LoadLibrary('RICHED20.DLL');
  if RichEdit20Lib <> 0 then
    CreateSubClass(Params, 'RichEdit20A');
end;

type
  // Таблица темы IDE (TUiListView: цвета, шапка колонок), у которой и
  // выделенная строка - в цветах самой таблицы: Windows рисует выделение
  // системными цветами, и без фокуса строка выходила белой. Цвет выделения
  // - смесь фона и текста таблицы.
  TRqListView = class(TUiListView)
  private
    procedure CNNotify(var Message: TWMNotify); message CN_NOTIFY;
  end;

// Цвет между AColor и ATo: APercent - доля ATo
function MixColor(AColor, ATo: TColor; APercent: Integer): TColor;
var
  FromRgb, ToRgb: Integer;

  function Part(AShift: Integer): Integer;
  begin
    Result := ((FromRgb shr AShift) and $FF) * (100 - APercent) div 100 +
              ((ToRgb shr AShift) and $FF) * APercent div 100;
  end;

begin
  FromRgb := ColorToRGB(AColor);
  ToRgb := ColorToRGB(ATo);
  Result := TColor(Part(0) or (Part(8) shl 8) or (Part(16) shl 16));
end;

procedure TRqListView.CNNotify(var Message: TWMNotify);
var
  Draw: PNMLVCustomDraw;
begin
  if Message.NMHdr^.code <> NM_CUSTOMDRAW then
  begin
    inherited;
    Exit;
  end;
  Draw := PNMLVCustomDraw(Message.NMHdr);
  inherited;
  case Draw^.nmcd.dwDrawStage of
    CDDS_PREPAINT:
      Message.Result := Message.Result or CDRF_NOTIFYITEMDRAW;
    CDDS_ITEMPREPAINT:
      if ListView_GetItemState(Handle, Integer(Draw^.nmcd.dwItemSpec),
                               LVIS_SELECTED) <> 0 then
      begin
        // Без признака "выделена" Windows берёт наши цвета строки
        Draw^.nmcd.uItemState := Draw^.nmcd.uItemState and
                                 not (CDIS_SELECTED or CDIS_FOCUS);
        Draw^.clrTextBk := ColorToRGB(MixColor(Color, Font.Color, 30));
        Draw^.clrText := ColorToRGB(Font.Color);
      end;
  end;
end;

type
  TRqDepsForm = class(TForm)
  private
    FScan: TRqDepScan;
    FRoots: TStrings;
    FRefDir: string;
    FSysDir: string;
    FRef: TIncRefIndex;
    FLog: TStrings;
    FIgnore: TStrings;
    FBusy: Boolean;
    FAbort: Boolean;
    FLastTick: Cardinal;
    FFilling: Boolean;
    FStartTimer: TTimer;
    FIniFile: string;
    // Верхнее поле: что не найдено, папки по умолчанию, кнопка поиска и
    // список папок поиска
    pnlTop: TPanel;
    lblHead: TLabel;
    lblUnIdeName: TLabel;
    edUnIdePath: TEdit;     // пути - полем: выделить и скопировать
    lblUserName: TLabel;
    edUserPath: TEdit;
    lblPress: TLabel;
    btnDirs: TUiButton;
    FPickDirs: TRqPickDirs;
    FEditLine: TRqEditLine;
    lvDeps: TRqListView;
    lblCands: TLabel;
    pnlCands: TPanel;
    lvCands: TRqListView;     // копии на диске: путь, размер, создан, изменён
    splDeps: TSplitter;
    splCands: TSplitter;
    memPreview: TRichEdit20;  // текст копии, выделенной в lvCands
    // Схема подсветки просмотра (не своя - её освобождает вызвавший); nil -
    // просмотр без подсветки
    FScheme: TClrScheme;
    lblNote: TLabel;
    pnlBottom: TPanel;
    lblTarget: TLabel;
    cbTarget: TComboBox;
    chkIgnore: TUiCheckBox;
    btnSearch: TUiButton;
    btnCopy: TUiButton;
    btnCopyOnly: TUiButton;  // скопировать без сборки, окно не закрывается
    btnBuild: TUiButton;
    btnCancel: TUiButton;
    btnFix: TUiButton;      // проверить выбранную копию inc и исправить
    btnUndo: TUiButton;     // отменить исправления файлов
    // Исправленные файлы и их копии до исправления (IncAutoFix) - для Undo
    FFixFiles: TStringList;
    FFixBaks: TStringList;
    // Предложение исправить - панелью над просмотром, не окном: сначала
    // смотрят список ошибок, потом решают. FOfferFiles - что исправлять.
    pnlOffer: TPanel;
    lblOffer: TLabel;
    btnOfferFix: TUiButton;
    btnOfferSkip: TUiButton;
    FOfferFiles: TStringList;
    FOfferReport: TStringList;
    // Список ошибок проверки - отдельно от просмотра, чтобы выбор копии
    // его не стирал. Щелчок по строке "стр. N" - файл в просмотре на
    // строке N. FReportPaths - файл каждой строки списка.
    lbReport: TListBox;
    splReport: TSplitter;
    FReportPaths: TStringList;
    // Что из середины окна видно: панель-предложение, список ошибок
    // (копии на диске - только когда их у выбранного файла больше одной)
    FShowOffer: Boolean;
    FShowReport: Boolean;
    lblStatus: TLabel;
    procedure BuildControls;
    procedure FillTop;
    procedure PlaceTop;
    procedure btnDirsClick(Sender: TObject);
    procedure lvDepsClick(Sender: TObject);
    function  WrongSubDir(ADep: TRqDep; var ARootLabel, ARootDir: string): Boolean;
    procedure AskSubDir(ADep: TRqDep);
    procedure FitColumns(AList: TListView);
    procedure LoadPlacement;
    procedure SavePlacement;
    procedure EmptyPreview(const AText: string);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FillList;
    procedure FillRow(AItem: TListItem);
    procedure ShowSelected;
    procedure RunSearch(AFull: Boolean);
    procedure SetBusy(ABusy: Boolean);
    function  SelectedDep: TRqDep;
    procedure ProgressStep(const AText: string; var ACancel: Boolean);
    procedure RefreshFoundRows;
    procedure StartTimerTick(Sender: TObject);
    procedure lvDepsSelectItem(Sender: TObject; Item: TListItem;
                               Selected: Boolean);
    procedure lvCandsSelectItem(Sender: TObject; Item: TListItem;
                                Selected: Boolean);
    procedure UpdateNote;
    procedure ShowPreview;
    procedure LoadPreview(const AFile: string; AIsText: Boolean;
                          ACurLine: Integer = 0);
    procedure SetReport(AReport: TStrings);
    procedure ArrangeTop;
    procedure lbReportClick(Sender: TObject);
    procedure lbReportDrawItem(Control: TWinControl; Index: Integer;
                               Rect: TRect; State: TOwnerDrawState);
    procedure cbTargetChange(Sender: TObject);
    procedure btnSearchClick(Sender: TObject);
    procedure btnCopyClick(Sender: TObject);
    procedure btnCopyOnlyClick(Sender: TObject);
    function  CopyChecked(var ACopied, AFailed: Integer): Boolean;
    procedure btnBuildClick(Sender: TObject);
    procedure btnFixClick(Sender: TObject);
    procedure btnUndoClick(Sender: TObject);
    procedure ShowOffer(AFiles, AReport: TStrings; AErrors: Integer);
    procedure btnOfferFixClick(Sender: TObject);
    procedure btnOfferSkipClick(Sender: TObject);
    function  CheckFiles(AFiles, AReport: TStrings): Integer;
    procedure FixFiles(AFiles, AReport: TStrings);
    procedure CheckUserIncludes;
    function  EnsureRef: Boolean;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure CollectIgnore;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    destructor Destroy; override;
  end;

var
  // Открытое окно (сборка ждёт его) - второй раз не открывается
  OpenDlg: TRqDepsForm = nil;

function DepWhere(ADep: TRqDep): string;
begin
  Result := ExtractFileName(ADep.FromFile) + ' (' + IntToStr(ADep.FromLine) + ')';
end;

{ TRqDepsForm }

// Окно немодальное, но над главным окном IDE: иначе оно уходило бы за него
procedure TRqDepsForm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  if (Application.MainForm <> nil) and Application.MainForm.HandleAllocated then
    Params.WndParent := Application.MainForm.Handle;
end;

destructor TRqDepsForm.Destroy;
begin
  FFixFiles.Free;
  FFixBaks.Free;
  FOfferFiles.Free;
  FOfferReport.Free;
  FReportPaths.Free;
  FRef.Free;
  inherited Destroy;
end;

procedure TRqDepsForm.BuildControls;

  procedure AddCol(AList: TListView; const ACaption: string; AWidth: Integer);
  var
    Col: TListColumn;
  begin
    Col := AList.Columns.Add;
    Col.Caption := ACaption;
    Col.Width := AWidth;
  end;

  function MakeButton(const ACaption: string; ALeft, AWidth: Integer;
                      AClick: TNotifyEvent): TUiButton;
  begin
    Result := TUiButton.Create(Self);
    Result.Parent := pnlBottom;
    Result.SetBounds(ALeft, 62, AWidth, 25);
    Result.Caption := ACaption;
    Result.OnClick := AClick;
  end;

begin
  Caption := 'Недостающие файлы программы';
  Width := 960;
  Height := 720;
  Position := poScreenCenter;
  BorderIcons := [biSystemMenu, biMaximize];
  Constraints.MinWidth := 700;
  Constraints.MinHeight := 520;
  Font.Name := 'Tahoma';
  Font.Height := -11;
  ShowHint := True;
  AutoScroll := False;   // всё размещает выравнивание, прокрутка не нужна
  OnCloseQuery := FormCloseQuery;
  OnClose := FormClose;

  // Верхнее поле: заголовок, папки Include, кнопка "Искать", папки поиска
  // и кнопка [...] их списка. Тексты и места - FillTop / PlaceTop.
  pnlTop := TPanel.Create(Self);
  pnlTop.Parent := Self;
  pnlTop.Top := 0;
  pnlTop.Height := 118;
  pnlTop.Align := alTop;
  pnlTop.BevelOuter := bvNone;
  pnlTop.Caption := '';

  lblHead := TLabel.Create(Self);
  lblHead.Parent := pnlTop;
  lblHead.Left := 8;
  lblHead.Top := 6;
  lblHead.Font.Style := [fsBold];
  lblUnIdeName := TLabel.Create(Self);
  lblUnIdeName.Parent := pnlTop;
  lblUnIdeName.SetBounds(8, 26, 90, 13);
  lblUnIdeName.Caption := 'Include UnIde';
  edUnIdePath := TEdit.Create(Self);
  edUnIdePath.Parent := pnlTop;
  edUnIdePath.SetBounds(100, 26, ClientWidth - 108, 15);
  edUnIdePath.Anchors := [akLeft, akTop, akRight];
  lblUserName := TLabel.Create(Self);
  lblUserName.Parent := pnlTop;
  lblUserName.SetBounds(8, 44, 90, 13);
  lblUserName.Caption := 'Include User';
  edUserPath := TEdit.Create(Self);
  edUserPath.Parent := pnlTop;
  edUserPath.SetBounds(100, 44, ClientWidth - 108, 15);
  edUserPath.Anchors := [akLeft, akTop, akRight];
  lblPress := TLabel.Create(Self);
  lblPress.Parent := pnlTop;
  lblPress.Left := 8;
  lblPress.Top := 68;
  btnDirs := TUiButton.Create(Self);
  btnDirs.Parent := pnlTop;
  btnDirs.SetBounds(0, 65, 30, 20);
  btnDirs.Caption := '...';
  btnDirs.OnClick := btnDirsClick;
  btnDirs.Hint := 'Свои папки для поиска: окно Directory Tree, отмеченные ' +
                  'в его списке папки';
  btnSearch := TUiButton.Create(Self);
  btnSearch.Parent := pnlTop;
  btnSearch.SetBounds(8, 89, 90, 23);
  btnSearch.Caption := 'Искать';
  btnSearch.OnClick := btnSearchClick;
  btnSearch.Hint := 'Искать недостающие файлы в папках из строки выше; во ' +
                    'время поиска - остановить';

  // Низ окна: пояснение, куда, кнопки, строка хода
  pnlBottom := TPanel.Create(Self);
  pnlBottom.Parent := Self;
  // Ширина задаётся сразу: от неё отсчитываются якоря akRight внутри
  pnlBottom.SetBounds(0, ClientHeight - 112, ClientWidth, 112);
  pnlBottom.Align := alBottom;
  pnlBottom.BevelOuter := bvNone;
  pnlBottom.Caption := '';

  lblNote := TLabel.Create(Self);
  lblNote.Parent := pnlBottom;
  lblNote.AutoSize := False;
  lblNote.WordWrap := True;
  lblNote.SetBounds(8, 4, ClientWidth - 16, 28);
  lblNote.Anchors := [akLeft, akTop, akRight];

  lblTarget := TLabel.Create(Self);
  lblTarget.Parent := pnlBottom;
  lblTarget.SetBounds(8, 38, 40, 13);
  lblTarget.Caption := 'Куда:';
  cbTarget := TComboBox.Create(Self);
  cbTarget.Parent := pnlBottom;
  cbTarget.Style := csDropDownList;
  cbTarget.SetBounds(50, 34, 560, 21);
  cbTarget.OnChange := cbTargetChange;
  cbTarget.Hint := 'Куда копировать выбранный файл. Путь из $INCLUDE ' +
                   '(Object\QINI.inc) сохраняется: файл ляжет в подпапку. ' +
                   'DLL - по умолчанию в папку программы: при запуске exe ' +
                   'Windows ищет её там, а не в папке -I';
  chkIgnore := TUiCheckBox.Create(Self);
  chkIgnore.Parent := pnlBottom;
  chkIgnore.SetBounds(620, 36, 270, 17);
  chkIgnore.Caption := 'Не спрашивать про неотмеченные';
  chkIgnore.Hint := 'Неотмеченные файлы для этой программы больше не ' +
                    'проверяются (editor.ini, [RqDepsIgnore])';

  btnCopyOnly := MakeButton('Скопировать', 8, 100, btnCopyOnlyClick);
  btnCopyOnly.Hint := 'Скопировать выбранные копии отмеченных файлов туда, ' +
                      'куда указано, без сборки; окно остаётся открытым';
  btnCopy := MakeButton('Копировать отмеченные и собрать', 116, 200, btnCopyClick);
  btnCopy.Hint := 'Скопировать выбранные копии отмеченных файлов и начать сборку';
  btnBuild := MakeButton('Собрать без копирования', 324, 160, btnBuildClick);
  btnCancel := MakeButton('Отмена', 492, 80, nil);
  btnCancel.ModalResult := mrCancel;
  btnFix := MakeButton('Проверить и исправить', 580, 150, btnFixClick);
  btnUndo := MakeButton('Undo', 738, 60, btnUndoClick);
  btnUndo.Hint := 'Отменить исправления: исправленные файлы удалить, ' +
                  'прежние вернуть из .bak';
  btnUndo.Enabled := False;
  FFixFiles := TStringList.Create;
  FFixBaks := TStringList.Create;
  btnFix.Hint := 'Проверка INC Manager выбранной копии inc; однозначные ' +
                 'ошибки (директивы без $, U/L и 0x из C, ";" вне строки) - ' +
                 'исправить в самом файле, прежний текст - в .bak';

  lblStatus := TLabel.Create(Self);
  lblStatus.Parent := pnlBottom;
  lblStatus.AutoSize := False;
  lblStatus.SetBounds(8, 94, ClientWidth - 16, 13);
  lblStatus.Anchors := [akLeft, akTop, akRight];

  // Середина сверху вниз: недостающие | сплиттер | копии | сплиттер |
  // просмотр. Порядок alTop - по Top, поэтому Top задаётся до Align.
  lvDeps := TRqListView.Create(Self);
  lvDeps.Parent := Self;
  lvDeps.Top := 200;
  lvDeps.Height := 170;
  lvDeps.Align := alTop;
  lvDeps.ViewStyle := vsReport;
  lvDeps.Checkboxes := True;
  lvDeps.RowSelect := True;
  lvDeps.ReadOnly := True;
  lvDeps.HideSelection := False;
  lvDeps.OnSelectItem := lvDepsSelectItem;
  lvDeps.OnClick := lvDepsClick;
  AddCol(lvDeps, 'Файл', 170);
  AddCol(lvDeps, 'Вид', 55);
  AddCol(lvDeps, 'Подключён', 170);
  AddCol(lvDeps, 'Копий', 50);
  AddCol(lvDeps, 'Размер', 70);
  AddCol(lvDeps, 'Создан', 105);
  AddCol(lvDeps, 'Изменён', 105);
  AddCol(lvDeps, 'Взять', 480);

  splDeps := TSplitter.Create(Self);
  splDeps.Parent := Self;
  splDeps.Top := 300;
  splDeps.Height := 5;
  splDeps.Align := alTop;
  splDeps.MinSize := 60;

  pnlCands := TPanel.Create(Self);
  pnlCands.Parent := Self;
  pnlCands.Top := 310;
  pnlCands.Height := 160;
  pnlCands.Align := alTop;
  pnlCands.BevelOuter := bvNone;
  pnlCands.Caption := '';
  pnlCands.Visible := False;

  lblCands := TLabel.Create(Self);
  lblCands.Parent := pnlCands;
  lblCands.Align := alTop;
  lblCands.Caption := ' Копий на диске несколько (выделенная - берётся, её ' +
                      'текст - ниже):';

  lvCands := TRqListView.Create(Self);
  lvCands.Parent := pnlCands;
  lvCands.Align := alClient;
  lvCands.ViewStyle := vsReport;
  lvCands.RowSelect := True;
  lvCands.ReadOnly := True;
  lvCands.HideSelection := False;
  lvCands.OnSelectItem := lvCandsSelectItem;
  AddCol(lvCands, 'Путь', 560);
  AddCol(lvCands, 'Размер', 80);
  AddCol(lvCands, 'Создан', 115);
  AddCol(lvCands, 'Изменён', 115);

  splCands := TSplitter.Create(Self);
  splCands.Parent := Self;
  splCands.Top := 480;
  splCands.Height := 5;
  splCands.Align := alTop;
  splCands.MinSize := 60;
  splCands.Visible := False;

  // Панель-предложение исправить ошибки: яркая, над просмотром со списком
  // ошибок; видна, только когда ошибки нашлись
  pnlOffer := TPanel.Create(Self);
  pnlOffer.Parent := Self;
  pnlOffer.Top := 490;
  pnlOffer.Height := 34;
  pnlOffer.Align := alTop;
  pnlOffer.BevelOuter := bvNone;
  pnlOffer.Caption := '';
  pnlOffer.Color := $0040C0FF;          // оранжевый
  pnlOffer.Visible := False;
  lblOffer := TLabel.Create(Self);
  lblOffer.Parent := pnlOffer;
  lblOffer.AutoSize := False;
  lblOffer.WordWrap := True;
  lblOffer.SetBounds(8, 2, ClientWidth - 260, 30);
  lblOffer.Anchors := [akLeft, akTop, akRight];
  lblOffer.Layout := tlCenter;
  // Не clBlack: тема заменяет его на цвет текста темы (UiThemeFgSys)
  lblOffer.ParentFont := False;
  lblOffer.Transparent := True;
  lblOffer.Font.Color := TColor($00101010);
  lblOffer.Font.Style := [fsBold];
  btnOfferFix := TUiButton.Create(Self);
  btnOfferFix.Parent := pnlOffer;
  btnOfferFix.SetBounds(ClientWidth - 244, 5, 110, 25);
  btnOfferFix.Anchors := [akTop, akRight];
  btnOfferFix.Caption := 'Исправить';
  btnOfferFix.OnClick := btnOfferFixClick;
  btnOfferSkip := TUiButton.Create(Self);
  btnOfferSkip.Parent := pnlOffer;
  btnOfferSkip.SetBounds(ClientWidth - 128, 5, 120, 25);
  btnOfferSkip.Anchors := [akTop, akRight];
  btnOfferSkip.Caption := 'Не исправлять';
  btnOfferSkip.OnClick := btnOfferSkipClick;
  FOfferFiles := TStringList.Create;
  FOfferReport := TStringList.Create;

  // Список ошибок: под панелью-предложением, над просмотром; виден после
  // проверки
  lbReport := TListBox.Create(Self);
  lbReport.Parent := Self;
  lbReport.Top := 530;
  lbReport.Height := 130;
  lbReport.Align := alTop;
  lbReport.Visible := False;
  lbReport.OnClick := lbReportClick;
  // Строки с именем файла - своим фоном и жирным (lbReportDrawItem)
  lbReport.Style := lbOwnerDrawFixed;
  lbReport.ItemHeight := 16;
  lbReport.OnDrawItem := lbReportDrawItem;
  lbReport.Hint := 'Щелчок по строке "стр. N" - этот файл в просмотре на ' +
                   'строке N';
  splReport := TSplitter.Create(Self);
  splReport.Parent := Self;
  splReport.Top := 670;
  splReport.Height := 5;
  splReport.Align := alTop;
  splReport.MinSize := 40;
  splReport.Visible := False;
  FReportPaths := TStringList.Create;

  memPreview := TRichEdit20.Create(Self);
  memPreview.Parent := Self;
  memPreview.Align := alClient;
  memPreview.ReadOnly := True;
  memPreview.WordWrap := False;
  memPreview.ScrollBars := ssBoth;
  memPreview.HideSelection := False;
  memPreview.Font.Name := 'Courier New';
  memPreview.Font.Height := -12;
  // Цвет пустого просмотра - как у таблицы (тема), см. EmptyPreview
  memPreview.ParentColor := False;

  FStartTimer := TTimer.Create(Self);
  FStartTimer.Interval := 50;
  FStartTimer.OnTimer := StartTimerTick;
  FStartTimer.Enabled := True;
end;

// Тексты верхнего поля: заголовок, папки Include (из шагов поиска), папки
// поиска с подпапками - свои папки из списка [...]
procedure TRqDepsForm.FillTop;
var
  RootIdx: Integer;
  RootLabel, RootDir, DirsText: string;
begin
  if (FScan.CountOf(dpkResource) = 0) and (FScan.CountOf(dpkLib) = 0) then
    lblHead.Caption := 'Inc файлы не найдены в папках по умолчанию'
  else
    lblHead.Caption := Format('Файлы не найдены в папках по умолчанию ' +
      '(inc: %d, ресурсы: %d, DLL: %d)', [FScan.CountOf(dpkInclude),
      FScan.CountOf(dpkResource), FScan.CountOf(dpkLib)]);
  edUnIdePath.Text := '(не задана)';
  edUserPath.Text := '(не задана)';
  DirsText := 'Нажмите "Искать" для поиска недостающих файлов в папках:  ' +
              'папка программы с подпапками, папка выше,';
  for RootIdx := 0 to FRoots.Count - 1 do
  begin
    RootLabel := Copy(FRoots[RootIdx], 1, Pos('|', FRoots[RootIdx]) - 1);
    RootDir := Copy(FRoots[RootIdx], Pos('|', FRoots[RootIdx]) + 1, MaxInt);
    if (CompareText(RootLabel, 'Include UnIde') = 0) and (RootDir <> '') then
      edUnIdePath.Text := RootDir
    else if (CompareText(RootLabel, 'Include User') = 0) and (RootDir <> '') then
      edUserPath.Text := RootDir
    else if RootLabel = RqDepsUserRootLabel then
      DirsText := DirsText + ' ' + RootDir + ',';
  end;
  lblPress.Caption := DirsText;
  PlaceTop;
end;

// Кнопки - сразу за текстом своей строки
procedure TRqDepsForm.PlaceTop;

  // Поле пути - как надпись: без рамки, цветами панели (тема уже легла)
  procedure AsLabel(AEdit: TEdit);
  begin
    AEdit.BorderStyle := bsNone;
    AEdit.ReadOnly := True;
    AEdit.Color := pnlTop.Color;
    AEdit.Font.Color := lblUnIdeName.Font.Color;
  end;

begin
  btnDirs.Left := lblPress.Left + lblPress.Width + 6;
  AsLabel(edUnIdePath);
  AsLabel(edUserPath);
end;

// Ширина столбцов - по самому длинному тексту (и заголовку)
procedure TRqDepsForm.FitColumns(AList: TListView);
var
  ColIdx, ItemIdx, TextW, MaxW: Integer;
  Item: TListItem;
begin
  if not AList.HandleAllocated then
    Exit;
  AList.Canvas.Font := AList.Font;
  for ColIdx := 0 to AList.Columns.Count - 1 do
  begin
    MaxW := AList.Canvas.TextWidth(AList.Columns[ColIdx].Caption);
    for ItemIdx := 0 to AList.Items.Count - 1 do
    begin
      Item := AList.Items[ItemIdx];
      if ColIdx = 0 then
        TextW := AList.Canvas.TextWidth(Item.Caption)
      else if ColIdx - 1 < Item.SubItems.Count then
        TextW := AList.Canvas.TextWidth(Item.SubItems[ColIdx - 1])
      else
        TextW := 0;
      if TextW > MaxW then
        MaxW := TextW;
    end;
    // Поля ячейки; у первого столбца ещё флажок
    Inc(MaxW, 16);
    if (ColIdx = 0) and AList.Checkboxes then
      Inc(MaxW, 20);
    AList.Columns[ColIdx].Width := MaxW;
  end;
end;

// Свои папки поиска: окно Directory Tree главного окна (отмеченные в его
// списке папки). Итог - в шаги поиска (FRoots) и в editor.ini.
procedure TRqDepsForm.btnDirsClick(Sender: TObject);
var
  RootIdx: Integer;
  Preselect, Picked, Joined: string;
  NewDirs: TStringList;
  Ini: TIniFile;
  SemiAt: Integer;
begin
  if not Assigned(FPickDirs) then
    Exit;
  Preselect := '';
  for RootIdx := 0 to FRoots.Count - 1 do
    if (Preselect = '') and
       (Copy(FRoots[RootIdx], 1, Pos('|', FRoots[RootIdx]) - 1) =
        RqDepsUserRootLabel) then
      Preselect := Copy(FRoots[RootIdx], Pos('|', FRoots[RootIdx]) + 1, MaxInt);
  if Preselect = '' then
    Preselect := FScan.MainDir;
  Picked := '';
  if not FPickDirs(Preselect, Picked) then
    Exit;
  NewDirs := TStringList.Create;
  try
    while Picked <> '' do
    begin
      SemiAt := Pos(';', Picked);
      if SemiAt = 0 then
        SemiAt := Length(Picked) + 1;
      Joined := Trim(Copy(Picked, 1, SemiAt - 1));
      Delete(Picked, 1, SemiAt);
      if Length(Joined) > 3 then
        Joined := ExcludeTrailingPathDelimiter(Joined);
      if (Joined <> '') and (NewDirs.IndexOf(Joined) < 0) then
        NewDirs.Add(Joined);
    end;
    // Шаги поиска: прежние свои папки - долой, новые - в конец
    for RootIdx := FRoots.Count - 1 downto 0 do
      if Copy(FRoots[RootIdx], 1, Pos('|', FRoots[RootIdx]) - 1) =
         RqDepsUserRootLabel then
        FRoots.Delete(RootIdx);
    Joined := '';
    for RootIdx := 0 to NewDirs.Count - 1 do
    begin
      FRoots.Add(RqDepsUserRootLabel + '|' + NewDirs[RootIdx]);
      if Joined <> '' then
        Joined := Joined + '|';
      Joined := Joined + NewDirs[RootIdx];
    end;
  finally
    NewDirs.Free;
  end;
  if FIniFile <> '' then
  begin
    Ini := TIniFile.Create(FIniFile);
    try
      Ini.WriteString('RqDepsSearch', 'Dirs', Joined);
    finally
      Ini.Free;
    end;
  end;
  FillTop;
end;

// Положение и размер окна, высота списка недостающих - из editor.ini
procedure TRqDepsForm.LoadPlacement;
var
  Ini: TIniFile;
  WinLeft, WinTop, WinWidth, WinHeight, ListHeight: Integer;
  Work: TRect;
begin
  if (FIniFile = '') or not FileExists(FIniFile) then
    Exit;
  Ini := TIniFile.Create(FIniFile);
  try
    WinLeft := Ini.ReadInteger('RqDepsWindow', 'Left', MaxInt);
    WinTop := Ini.ReadInteger('RqDepsWindow', 'Top', MaxInt);
    WinWidth := Ini.ReadInteger('RqDepsWindow', 'Width', Width);
    WinHeight := Ini.ReadInteger('RqDepsWindow', 'Height', Height);
    ListHeight := Ini.ReadInteger('RqDepsWindow', 'ListHeight', 0);
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
      lvDeps.Height := ListHeight;
    if Ini.ReadBool('RqDepsWindow', 'Maximized', False) then
      WindowState := wsMaximized;
  finally
    Ini.Free;
  end;
end;

procedure TRqDepsForm.SavePlacement;
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
    Ini.WriteInteger('RqDepsWindow', 'Left', Place.rcNormalPosition.Left);
    Ini.WriteInteger('RqDepsWindow', 'Top', Place.rcNormalPosition.Top);
    Ini.WriteInteger('RqDepsWindow', 'Width', Place.rcNormalPosition.Right -
                     Place.rcNormalPosition.Left);
    Ini.WriteInteger('RqDepsWindow', 'Height', Place.rcNormalPosition.Bottom -
                     Place.rcNormalPosition.Top);
    Ini.WriteBool('RqDepsWindow', 'Maximized', WindowState = wsMaximized);
    Ini.WriteInteger('RqDepsWindow', 'ListHeight', lvDeps.Height);
  finally
    Ini.Free;
  end;
end;

// Крестик: окно немодальное, закрытие = Отмена
procedure TRqDepsForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if ModalResult = mrNone then
    ModalResult := mrCancel;
  Action := caHide;
end;

// $INCLUDE с подпапкой ("Object\QStatusBarEx.inc"), а копия найдена в
// корне папки Include (по одному имени файла): подпапки там нет. ARootLabel /
// ARootDir - эта папка Include.
function TRqDepsForm.WrongSubDir(ADep: TRqDep;
                                 var ARootLabel, ARootDir: string): Boolean;
var
  RootIdx: Integer;
  RelName: string;
begin
  Result := False;
  if (ADep = nil) or (ADep.Kind <> dpkInclude) or (ADep.Chosen < 0) or
     (ADep.Chosen >= ADep.Where.Count) then
    Exit;
  RelName := StringReplace(ADep.Name, '/', '\', [rfReplaceAll]);
  if (Pos('\', RelName) = 0) or (ExtractFileDrive(RelName) <> '') then
    Exit;
  ARootLabel := ADep.Where[ADep.Chosen];
  if CompareText(Copy(ARootLabel, 1, 7), 'Include') <> 0 then
    Exit;
  ARootDir := '';
  for RootIdx := 0 to FRoots.Count - 1 do
    if CompareText(Copy(FRoots[RootIdx], 1, Pos('|', FRoots[RootIdx]) - 1),
                   ARootLabel) = 0 then
      ARootDir := Copy(FRoots[RootIdx], Pos('|', FRoots[RootIdx]) + 1, MaxInt);
  if ARootDir = '' then
    Exit;
  ARootDir := IncludeTrailingPathDelimiter(ExpandFileName(ARootDir));
  Result := CompareText(ExpandFileName(ADep.Candidates[ADep.Chosen]),
                        ARootDir + ADep.FileNameOnly) = 0;
end;

// Щелчок по строке недостающего: подпапки из $INCLUDE нет - спросить,
// что делать
procedure TRqDepsForm.lvDepsClick(Sender: TObject);
var
  RootLabel, RootDir: string;
begin
  if FBusy then
    Exit;
  if WrongSubDir(SelectedDep, RootLabel, RootDir) then
    AskSubDir(SelectedDep);
end;

// Окно с выбором: исправить путь в $INCLUDE исходника или создать подпапку
// в папке Include и скопировать туда файл
procedure TRqDepsForm.AskSubDir(ADep: TRqDep);
var
  AskDlg: TForm;
  lblText: TLabel;
  rbFixSource, rbMakeDir: TUiRadioButton;
  btnOk, btnCancel: TUiButton;
  RootLabel, RootDir, RelName, SubDir, Found, Target, LineText, NewLine: string;
  Lines: TStringList;
  NamePos: Integer;
  Done: Boolean;

  // Найденная копия - там, где её возьмёт rc.exe: больше не недостающий
  procedure MarkResolved(const APath: string);
  begin
    if (CompareText(ExtractFilePath(ExpandFileName(APath)),
         IncludeTrailingPathDelimiter(ExpandFileName(FScan.IncDir))) = 0) or
       (CompareText(ExtractFilePath(ExpandFileName(APath)),
         IncludeTrailingPathDelimiter(ExpandFileName(FScan.MainDir))) = 0) then
      ADep.Resolved := APath;
  end;

begin
  if not WrongSubDir(ADep, RootLabel, RootDir) then
    Exit;
  RelName := StringReplace(ADep.Name, '/', '\', [rfReplaceAll]);
  SubDir := ExtractFilePath(RelName);           // "Object\"
  Found := ADep.Candidates[ADep.Chosen];
  AskDlg := TForm.CreateNew(Self);
  try
    AskDlg.Caption := 'Подпапки из $INCLUDE нет';
    AskDlg.BorderStyle := bsDialog;
    AskDlg.Position := poOwnerFormCenter;
    AskDlg.Font := Font;
    AskDlg.ClientWidth := 620;
    AskDlg.ClientHeight := 168;
    lblText := TLabel.Create(AskDlg);
    lblText.Parent := AskDlg;
    lblText.AutoSize := False;
    lblText.WordWrap := True;
    lblText.SetBounds(12, 10, 596, 56);
    lblText.Caption := 'В исходнике ' + ExtractFileName(ADep.FromFile) +
      ' (строка ' + IntToStr(ADep.FromLine) + '): $INCLUDE "' + ADep.Name +
      '". Файл ' + ADep.FileNameOnly + ' лежит в ' + RootDir + ' (' +
      RootLabel + '), подпапки ' + SubDir + ' там нет.';
    rbFixSource := TUiRadioButton.Create(AskDlg);
    rbFixSource.Parent := AskDlg;
    rbFixSource.SetBounds(12, 72, 596, 18);
    rbFixSource.Caption := 'Исправить путь в исходном файле: $INCLUDE "' +
                           ADep.FileNameOnly + '"';
    rbFixSource.Checked := True;
    rbMakeDir := TUiRadioButton.Create(AskDlg);
    rbMakeDir.Parent := AskDlg;
    rbMakeDir.SetBounds(12, 96, 596, 18);
    rbMakeDir.Caption := 'Создать подпапку \' + SubDir + ' в ' + RootLabel +
                         ' и скопировать туда ' + ADep.FileNameOnly;
    btnOk := TUiButton.Create(AskDlg);
    btnOk.Parent := AskDlg;
    btnOk.SetBounds(AskDlg.ClientWidth - 196, 130, 90, 25);
    btnOk.Caption := 'OK';
    btnOk.ModalResult := mrOk;
    btnCancel := TUiButton.Create(AskDlg);
    btnCancel.Parent := AskDlg;
    btnCancel.SetBounds(AskDlg.ClientWidth - 100, 130, 90, 25);
    btnCancel.Caption := 'Отмена';
    btnCancel.ModalResult := mrCancel;
    if AskDlg.ShowModal <> mrOk then
      Exit;

    Done := False;
    if rbFixSource.Checked then
    begin
      // Строка $INCLUDE - с диска (перед сборкой файлы сохранены), правка -
      // в редакторе, как правки строгой проверки
      Lines := TStringList.Create;
      try
        try
          Lines.LoadFromFile(ADep.FromFile);
        except
          Lines.Clear;
        end;
        LineText := '';
        if (ADep.FromLine >= 1) and (ADep.FromLine <= Lines.Count) then
          LineText := Lines[ADep.FromLine - 1];
      finally
        Lines.Free;
      end;
      NamePos := Pos(UpperCase(ADep.Name), UpperCase(LineText));
      if NamePos = 0 then
        lblStatus.Caption := 'Путь не исправлен: в строке ' +
          IntToStr(ADep.FromLine) + ' ' + ExtractFileName(ADep.FromFile) +
          ' нет "' + ADep.Name + '"'
      else if not Assigned(FEditLine) then
        lblStatus.Caption := 'Путь не исправлен: правка исходника отсюда ' +
                             'недоступна'
      else
      begin
        NewLine := Copy(LineText, 1, NamePos - 1) + ADep.FileNameOnly +
                   Copy(LineText, NamePos + Length(ADep.Name), MaxInt);
        if FEditLine(ADep.FromFile, ADep.FromLine, LineText, NewLine, False) then
        begin
          FLog.Add('Исправлен путь $INCLUDE: ' + ExtractFileName(ADep.FromFile) +
                   '(' + IntToStr(ADep.FromLine) + ') "' + ADep.Name +
                   '" -> "' + ADep.FileNameOnly + '"');
          lblStatus.Caption := 'Исправлено: $INCLUDE "' + ADep.FileNameOnly +
                               '" в ' + ExtractFileName(ADep.FromFile);
          ADep.Name := ADep.FileNameOnly;
          MarkResolved(Found);
          Done := True;
        end
        else
          lblStatus.Caption := 'Путь не исправлен: строка ' +
            IntToStr(ADep.FromLine) + ' в редакторе другая или файл не ' +
            'сохранён';
      end;
    end
    else
    begin
      Target := RootDir + RelName;
      ForceDirectories(ExtractFilePath(Target));
      if FileExists(Target) then
        lblStatus.Caption := 'Не скопирован: ' + Target + ' уже есть'
      else if CopyFile(PChar(Found), PChar(Target), True) then
      begin
        FLog.Add('Скопирован ' + ADep.Name + ': ' + Found + ' -> ' + Target);
        lblStatus.Caption := 'Скопирован в ' + Target;
        ADep.Candidates[ADep.Chosen] := Target;
        MarkResolved(Target);
        Done := True;
      end
      else
        lblStatus.Caption := 'Не скопирован: ' + SysErrorMessage(GetLastError);
    end;
    if Done then
      FillList;
  finally
    AskDlg.Free;
  end;
end;

function TRqDepsForm.SelectedDep: TRqDep;
begin
  Result := nil;
  if (lvDeps <> nil) and (lvDeps.Selected <> nil) then
    Result := TRqDep(lvDeps.Selected.Data);
end;

// Размер и время файла: создан, изменён (местное время)
function FileStampText(const AFile: string; var ASize, ACreated,
                       AWritten: string): Boolean;
var
  SR: TSearchRec;
  LocalTime: TFileTime;
  SysTime: TSystemTime;
  FileSize: Int64;

  function TimeText(const AStamp: TFileTime): string;
  begin
    Result := '';
    if FileTimeToLocalFileTime(AStamp, LocalTime) and
       FileTimeToSystemTime(LocalTime, SysTime) then
      Result := FormatDateTime('dd.mm.yyyy hh:nn', SystemTimeToDateTime(SysTime));
  end;

begin
  ASize := '';
  ACreated := '';
  AWritten := '';
  Result := FindFirst(AFile, faAnyFile, SR) = 0;
  if not Result then
    Exit;
  try
    FileSize := Int64(SR.FindData.nFileSizeHigh) shl 32 +
                SR.FindData.nFileSizeLow;
    ASize := FormatFloat('#,##0', FileSize);
    ACreated := TimeText(SR.FindData.ftCreationTime);
    AWritten := TimeText(SR.FindData.ftLastWriteTime);
  finally
    FindClose(SR);
  end;
end;

procedure TRqDepsForm.FillRow(AItem: TListItem);
var
  Dep: TRqDep;
  SizeText, CreatedText, WrittenText: string;
begin
  Dep := TRqDep(AItem.Data);
  AItem.SubItems.Clear;
  AItem.Caption := Dep.Name;
  AItem.SubItems.Add(RqDepKindNames[Dep.Kind]);
  AItem.SubItems.Add(DepWhere(Dep));
  AItem.SubItems.Add(IntToStr(Dep.Candidates.Count));
  // Размер и время - взятой копии
  SizeText := '';
  CreatedText := '';
  WrittenText := '';
  if Dep.Chosen >= 0 then
    FileStampText(Dep.Candidates[Dep.Chosen], SizeText, CreatedText,
                  WrittenText)
  else if FBusy and (Dep.Candidates.Count > 0) then
    // Идёт поиск, копия выбирается после него - пока первая найденная
    FileStampText(Dep.Candidates[0], SizeText, CreatedText, WrittenText);
  AItem.SubItems.Add(SizeText);
  AItem.SubItems.Add(CreatedText);
  AItem.SubItems.Add(WrittenText);
  if Dep.Chosen >= 0 then
    AItem.SubItems.Add(Dep.Candidates[Dep.Chosen])
  else if FBusy and (Dep.Candidates.Count > 0) then
    AItem.SubItems.Add(Dep.Candidates[0] + '  (найдено, поиск идёт)')
  else if FBusy then
    AItem.SubItems.Add('ищется...')
  else
    AItem.SubItems.Add('не найден');
end;

procedure TRqDepsForm.FillList;
var
  ItemIdx: Integer;
  Item: TListItem;
  KeepIdx: Integer;
begin
  FFilling := True;
  KeepIdx := 0;
  if lvDeps.Selected <> nil then
    KeepIdx := lvDeps.Selected.Index;
  lvDeps.Items.BeginUpdate;
  try
    lvDeps.Items.Clear;
    for ItemIdx := 0 to FScan.Count - 1 do
      if FScan[ItemIdx].Missing then
      begin
        Item := lvDeps.Items.Add;
        Item.Data := FScan[ItemIdx];
        FillRow(Item);
        Item.Checked := FScan[ItemIdx].Chosen >= 0;
      end;
  finally
    lvDeps.Items.EndUpdate;
    FFilling := False;
  end;
  FitColumns(lvDeps);
  if lvDeps.Items.Count > 0 then
  begin
    if KeepIdx >= lvDeps.Items.Count then
      KeepIdx := 0;
    lvDeps.Selected := lvDeps.Items[KeepIdx];
  end;
  ShowSelected;
end;

procedure TRqDepsForm.ShowSelected;
var
  Dep: TRqDep;
  CandIdx: Integer;
  IncText, SizeText, CreatedText, WrittenText: string;
  Item: TListItem;
begin
  Dep := SelectedDep;
  FFilling := True;
  try
    lvCands.Items.BeginUpdate;
    try
      lvCands.Items.Clear;
      if Dep <> nil then
        for CandIdx := 0 to Dep.Candidates.Count - 1 do
        begin
          Item := lvCands.Items.Add;
          Item.Caption := Dep.Candidates[CandIdx];
          FileStampText(Dep.Candidates[CandIdx], SizeText, CreatedText,
                        WrittenText);
          Item.SubItems.Add(SizeText);
          Item.SubItems.Add(CreatedText);
          Item.SubItems.Add(WrittenText);
        end;
    finally
      lvCands.Items.EndUpdate;
    end;
    FitColumns(lvCands);
    if (Dep <> nil) and (Dep.Chosen >= 0) and
       (Dep.Chosen < lvCands.Items.Count) then
    begin
      lvCands.Selected := lvCands.Items[Dep.Chosen];
      lvCands.Selected.MakeVisible(False);
    end;
  finally
    FFilling := False;
  end;
  ArrangeTop;
  cbTarget.Items.Clear;
  if Dep = nil then
  begin
    lblNote.Caption := '';
    cbTarget.Enabled := False;
    ShowPreview;
    Exit;
  end;
  IncText := FScan.IncDir;
  if IncText = '' then
    IncText := '(не задана - папка программы)';
  cbTarget.Items.Add('в папку -I сборки: ' + IncText);
  cbTarget.Items.Add('в папку программы: ' + FScan.MainDir);
  cbTarget.ItemIndex := Ord(Dep.Target);
  cbTarget.Enabled := not FBusy;
  UpdateNote;
  ShowPreview;
end;

// Пояснение под списками: почему взята копия и куда она ляжет
procedure TRqDepsForm.UpdateNote;
var
  Dep: TRqDep;
begin
  Dep := SelectedDep;
  if Dep = nil then
    lblNote.Caption := ''
  else if Dep.Chosen >= 0 then
    lblNote.Caption := Dep.ChosenNote + '. Копия ляжет в ' +
                       RqDepTargetPath(Dep, FScan.IncDir, FScan.MainDir)
  else if FBusy then
    lblNote.Caption := ''
  else
    lblNote.Caption := 'Копий не найдено. Поиск по всем дискам - View - Find ' +
                       'inc file, галка "Все локальные диски"';
end;

// Текст выбранной копии (inc и прочие текстовые; DLL и картинки - нет)
procedure TRqDepsForm.ShowPreview;
var
  Dep: TRqDep;
  FileName, Ext: string;
begin
  Dep := SelectedDep;
  if (Dep = nil) or (lvCands.Selected = nil) then
  begin
    EmptyPreview('');
    Exit;
  end;
  FileName := lvCands.Selected.Caption;
  Ext := LowerCase(ExtractFileExt(FileName));
  LoadPreview(FileName, not ((Dep.Kind = dpkLib) or (Ext = '.bmp') or
              (Ext = '.ico') or (Ext = '.jpg') or (Ext = '.gif') or
              (Ext = '.cur') or (Ext = '.wav')));
end;

// Текст файла в просмотр; строки - как в файле (LF -> CRLF), чтобы номер
// строки из проверки совпадал со строкой просмотра. Есть схема - с
// подсветкой: текст переводится в RTF и загружается разом.
procedure TRqDepsForm.LoadPreview(const AFile: string; AIsText: Boolean;
                                  ACurLine: Integer);
const
  PreviewMax = 1048576;
var
  Stream: TFileStream;
  RtfStream: TStringStream;
  Buf: string;
  ErrLines: TList;
  ItemIdx, HeadIdx, LineNo: Integer;
  Txt: string;
begin
  // Без этого RichEdit берёт не больше 32К знаков
  memPreview.Perform(EM_EXLIMITTEXT, 0, $7FFFFFF0);
  memPreview.Lines.Clear;
  if not AIsText then
  begin
    EmptyPreview('(' + AFile + ' - не текст, просмотра нет)');
    Exit;
  end;
  try
    Stream := TFileStream.Create(AFile, fmOpenRead or fmShareDenyNone);
    try
      if Stream.Size > PreviewMax then
        SetLength(Buf, PreviewMax)
      else
        SetLength(Buf, Stream.Size);
      if Length(Buf) > 0 then
        Stream.ReadBuffer(Buf[1], Length(Buf));
    finally
      Stream.Free;
    end;
    if FScheme <> nil then
    begin
      // Строки с ошибками этого файла - из последней его проверки в списке
      // ошибок: от последней строки с его именем до следующего файла
      ErrLines := TList.Create;
      try
        HeadIdx := -1;
        for ItemIdx := 0 to lbReport.Items.Count - 1 do
          if (lbReport.Items.Objects[ItemIdx] <> nil) and
             (CompareText(FReportPaths[ItemIdx], AFile) = 0) then
            HeadIdx := ItemIdx;
        if HeadIdx >= 0 then
          for ItemIdx := HeadIdx + 1 to lbReport.Items.Count - 1 do
          begin
            if (lbReport.Items.Objects[ItemIdx] <> nil) or
               (CompareText(FReportPaths[ItemIdx], AFile) <> 0) then
              Break;
            // "    стр. 16: ошибка: ..." ("замечание:" - не выделяется)
            Txt := TrimLeft(lbReport.Items[ItemIdx]);
            if (Copy(Txt, 1, 5) = 'стр. ') and (Pos('ошибка:', Txt) > 0) then
            begin
              LineNo := StrToIntDef(Copy(Txt, 6, Pos(':', Txt) - 6), 0);
              if LineNo > 0 then
                ErrLines.Add(Pointer(LineNo));
            end;
          end;
        memPreview.Color := SchemePageColor(FScheme);
        RtfStream := TStringStream.Create(SchemeTextToRtf(AdjustLineBreaks(Buf),
                                          FScheme, 'Courier New', 9, ErrLines,
                                          ACurLine));
        try
          memPreview.PlainText := False;
          memPreview.Lines.LoadFromStream(RtfStream);
        finally
          RtfStream.Free;
        end;
      finally
        ErrLines.Free;
      end;
    end
    else
    begin
      EmptyPreview('');
      memPreview.Text := AdjustLineBreaks(Buf);
    end;
    memPreview.SelStart := 0;
  except
    on E: Exception do
      EmptyPreview('Не прочитан: ' + E.Message);
  end;
end;

// Просмотр без подсветки: цвета таблицы (тема IDE), не белый фон и не
// фон схемы от прошлого файла. AText - пояснение вместо текста файла.
procedure TRqDepsForm.EmptyPreview(const AText: string);
begin
  memPreview.Color := lvDeps.Color;
  memPreview.Font.Color := lvDeps.Font.Color;
  memPreview.DefAttributes.Color := lvDeps.Font.Color;
  // Не Lines.Add: у окна RichEdit 2.0 вставка строки через Lines
  // кончается исключением "RichEdit line insertion error"
  memPreview.Text := AText;
end;

// Отчёт проверки / исправления - в список ошибок. Строка "путь - ..." задаёт
// файл для следующих строк "стр. N: ..."
procedure TRqDepsForm.SetReport(AReport: TStrings);
var
  LineIdx, DashAt, MaxWidth: Integer;
  CurFile, Line: string;
  IsHead: Boolean;
begin
  MaxWidth := 0;
  lbReport.Canvas.Font := lbReport.Font;
  lbReport.Canvas.Font.Style := [fsBold];
  lbReport.Items.BeginUpdate;
  try
    lbReport.Items.Clear;
    FReportPaths.Clear;
    CurFile := '';
    for LineIdx := 0 to AReport.Count - 1 do
    begin
      Line := AReport[LineIdx];
      DashAt := Pos(' - ', Line);
      IsHead := (Line <> '') and (Line[1] <> ' ') and (DashAt > 1) and
                FileExists(Copy(Line, 1, DashAt - 1));
      if IsHead then
        CurFile := Copy(Line, 1, DashAt - 1)
      else if Trim(Line) = '' then
        CurFile := '';
      // Objects <> nil - строка с именем файла
      lbReport.Items.AddObject(Line, TObject(Ord(IsHead)));
      FReportPaths.Add(CurFile);
      if lbReport.Canvas.TextWidth(Line) > MaxWidth then
        MaxWidth := lbReport.Canvas.TextWidth(Line);
    end;
  finally
    lbReport.Items.EndUpdate;
  end;
  // Длинные строки - горизонтальной прокруткой
  lbReport.ScrollWidth := MaxWidth + 8;
  FShowReport := True;
  ArrangeTop;
end;

// Середина окна под списком недостающих, сверху вниз: копии на диске (если
// их несколько) | панель-предложение | список ошибок | просмотр. Порядок
// alTop - по Top: здесь Top задаётся по порядку ниже списка недостающих,
// при выключенном выравнивании, и выравнивание расставляет их разом.
procedure TRqDepsForm.ArrangeTop;
var
  Dep: TRqDep;
  NextTop: Integer;

  procedure Place(ACtl: TControl; AShow: Boolean);
  begin
    if AShow then
    begin
      ACtl.Top := NextTop;
      Inc(NextTop);
    end;
    ACtl.Visible := AShow;
  end;

begin
  Dep := SelectedDep;
  // Сразу под сплиттером недостающих и по 1 вниз: порядок задан, а
  // Top не уходит за окно (за окном у формы появлялась прокрутка)
  NextTop := splDeps.Top + splDeps.Height + 1;
  DisableAlign;
  try
    Place(pnlCands, (Dep <> nil) and (Dep.Candidates.Count > 1));
    Place(splCands, pnlCands.Visible);
    Place(pnlOffer, FShowOffer);
    Place(lbReport, FShowReport);
    Place(splReport, FShowReport);
  finally
    EnableAlign;
  end;
end;

procedure TRqDepsForm.lbReportDrawItem(Control: TWinControl; Index: Integer;
                                       Rect: TRect; State: TOwnerDrawState);
var
  Cv: TCanvas;
  IsHead: Boolean;
begin
  Cv := lbReport.Canvas;
  IsHead := (Index >= 0) and (Index < lbReport.Items.Count) and
            (lbReport.Items.Objects[Index] <> nil);
  Cv.Font := lbReport.Font;
  if odSelected in State then
    // Не системное выделение: в тёмной теме оно было белым пятном
    Cv.Brush.Color := MixColor(lbReport.Color, lbReport.Font.Color, 30)
  else if IsHead then
    // Оттенок оранжевой панели поверх фона списка - и в светлой теме, и
    // в тёмной
    Cv.Brush.Color := MixColor(lbReport.Color, pnlOffer.Color, 30)
  else
  begin
    Cv.Brush.Color := lbReport.Color;
    // Ошибки - красным: их число и есть "ошибок: N"; замечания - обычным
    if (Index >= 0) and (Index < lbReport.Items.Count) and
       (Pos('ошибка:', lbReport.Items[Index]) > 0) then
      Cv.Font.Color := MixColor(lbReport.Font.Color, clRed, 60);
  end;
  if IsHead then
    Cv.Font.Style := [fsBold];
  Cv.FillRect(Rect);
  if (Index >= 0) and (Index < lbReport.Items.Count) then
    Cv.TextOut(Rect.Left + 2, Rect.Top + 1, lbReport.Items[Index]);
end;

procedure TRqDepsForm.lbReportClick(Sender: TObject);
var
  ItemIdx, LineNo, CharPos, FirstVisible: Integer;
  Txt: string;
begin
  ItemIdx := lbReport.ItemIndex;
  if (ItemIdx < 0) or (ItemIdx >= FReportPaths.Count) or
     (FReportPaths[ItemIdx] = '') then
    Exit;
  // "    стр. 12: ..." или "стр. 12: ... -> ..." (исправление)
  Txt := TrimLeft(lbReport.Items[ItemIdx]);
  LineNo := 0;
  if Copy(Txt, 1, 5) = 'стр. ' then
    LineNo := StrToIntDef(Copy(Txt, 6, Pos(':', Txt) - 6), 0);
  // Строка LineNo - своей подложкой (SchemeTextToRtf), не выделением:
  // на системном выделении светлые цвета схемы не видны
  LoadPreview(FReportPaths[ItemIdx], True, LineNo);
  if LineNo <= 0 then
    Exit;
  CharPos := memPreview.Perform(EM_LINEINDEX, LineNo - 1, 0);
  if CharPos < 0 then
    Exit;
  memPreview.SelStart := CharPos;
  memPreview.SelLength := 0;
  // Строку - не к самому верху, с тремя строками перед ней
  FirstVisible := memPreview.Perform(EM_GETFIRSTVISIBLELINE, 0, 0);
  memPreview.Perform(EM_LINESCROLL, 0, LineNo - 4 - FirstVisible);
end;

procedure TRqDepsForm.lvDepsSelectItem(Sender: TObject; Item: TListItem;
                                       Selected: Boolean);
begin
  if not FFilling and Selected then
    ShowSelected;
end;

// Выделенная копия - та, что берётся
procedure TRqDepsForm.lvCandsSelectItem(Sender: TObject; Item: TListItem;
                                        Selected: Boolean);
var
  Dep: TRqDep;
begin
  if FFilling or not Selected or (Item = nil) then
    Exit;
  Dep := SelectedDep;
  if Dep <> nil then
  begin
    if not FBusy and (Item.Index <> Dep.Chosen) then
    begin
      Dep.Chosen := Item.Index;
      Dep.ChosenNote := 'выбрана вручную';
      FillRow(lvDeps.Selected);
      lvDeps.Selected.Checked := True;
    end;
    UpdateNote;
  end;
  ShowPreview;
end;

procedure TRqDepsForm.cbTargetChange(Sender: TObject);
var
  Dep: TRqDep;
begin
  Dep := SelectedDep;
  if (Dep = nil) or (cbTarget.ItemIndex < 0) then
    Exit;
  Dep.Target := TRqDepTarget(cbTarget.ItemIndex);
  ShowSelected;
end;

// Во время поиска: строки, у которых прибавились копии, - заново (число
// копий, первая найденная, её размер и время)
procedure TRqDepsForm.RefreshFoundRows;
var
  ItemIdx, Total: Integer;
  Dep: TRqDep;
  Changed: Boolean;
begin
  Changed := False;
  for ItemIdx := 0 to lvDeps.Items.Count - 1 do
  begin
    Dep := TRqDep(lvDeps.Items[ItemIdx].Data);
    if (Dep = nil) or
       (lvDeps.Items[ItemIdx].SubItems.Count < 3) or
       (lvDeps.Items[ItemIdx].SubItems[2] = IntToStr(Dep.Candidates.Count)) then
      Continue;
    FFilling := True;
    try
      FillRow(lvDeps.Items[ItemIdx]);
    finally
      FFilling := False;
    end;
    Changed := True;
  end;
  if Changed then
    FitColumns(lvDeps);
  Total := 0;
  for ItemIdx := 0 to FScan.Count - 1 do
    if FScan[ItemIdx].Missing and (FScan[ItemIdx].Candidates.Count > 0) then
      Inc(Total);
  if Total > 0 then
    lblStatus.Caption := Format('Найдены копии: %d из %d. %s',
                                [Total, FScan.MissingCount, lblStatus.Caption]);
end;

procedure TRqDepsForm.ProgressStep(const AText: string; var ACancel: Boolean);
begin
  ACancel := FAbort;
  if ACancel or (GetTickCount - FLastTick < 100) then
    Exit;
  FLastTick := GetTickCount;
  lblStatus.Caption := AText;
  RefreshFoundRows;
  Application.ProcessMessages;
  ACancel := FAbort;
end;

procedure TRqDepsForm.SetBusy(ABusy: Boolean);
begin
  FBusy := ABusy;
  if ABusy then
  begin
    FAbort := False;
    FLastTick := 0;
    btnSearch.Caption := 'Стоп';
  end
  else
    btnSearch.Caption := 'Искать';
  btnDirs.Enabled := not ABusy;
  btnCopy.Enabled := not ABusy;
  btnCopyOnly.Enabled := not ABusy;
  btnFix.Enabled := not ABusy;
  btnUndo.Enabled := not ABusy and (FFixFiles <> nil) and (FFixFiles.Count > 0);
  btnBuild.Enabled := not ABusy;
  btnCancel.Enabled := not ABusy;
  chkIgnore.Enabled := not ABusy;
end;

// AFull = False (первый поиск при открытии окна): нашлось в папках
// Include UnIde / Include User - на этом поиск кончается; остальное -
// "Искать снова" (AFull = True), с папкой программы и папкой выше
procedure TRqDepsForm.RunSearch(AFull: Boolean);
var
  Done, NeedRef: Boolean;
  ItemIdx, FoundCount, NotFound: Integer;
begin
  SetBusy(True);
  try
    FillList;
    Done := RqDepsFindOnDisk(FScan, FRoots, ProgressStep, not AFull);
    // Эталон - только если есть копии inc для сравнения
    NeedRef := False;
    for ItemIdx := 0 to FScan.Count - 1 do
      if FScan[ItemIdx].Missing and (FScan[ItemIdx].Kind = dpkInclude) and
         (FScan[ItemIdx].Candidates.Count > 0) then
        NeedRef := True;
    if NeedRef and (FRef = nil) and Done then
    begin
      FRef := TIncRefIndex.Create;
      if not FRef.Load(FRefDir, FSysDir, ProgressStep) then
        FreeAndNil(FRef);
    end;
    RqDepsChoose(FScan, FRef);
    FoundCount := 0;
    for ItemIdx := 0 to FScan.Count - 1 do
      if FScan[ItemIdx].Missing and (FScan[ItemIdx].Chosen >= 0) then
        Inc(FoundCount);
    lblStatus.Caption := Format('Нет на месте: %d, найдены копии: %d',
                                [FScan.MissingCount, FoundCount]);
    NotFound := FScan.MissingCount - FoundCount;
    if not AFull and (NotFound > 0) then
      lblStatus.Caption := lblStatus.Caption + Format('. Не найдено в папках ' +
        'Include: %d - "Искать" ищет их в папках из верхнего поля',
        [NotFound]);
    if not Done then
      lblStatus.Caption := 'Поиск остановлен. ' + lblStatus.Caption;
  finally
    SetBusy(False);
  end;
  FillList;
  // Найденное в Include User - проверить сразу, и после «Стоп» тоже
  CheckUserIncludes;
end;

procedure TRqDepsForm.StartTimerTick(Sender: TObject);
begin
  FStartTimer.Enabled := False;
  // Шрифты окна к этому времени - по теме IDE: кнопки - за текстом заново
  PlaceTop;
  RunSearch(False);
end;

procedure TRqDepsForm.btnSearchClick(Sender: TObject);
begin
  if FBusy then
    FAbort := True
  else
    RunSearch(True);
end;

procedure TRqDepsForm.CollectIgnore;
var
  ItemIdx: Integer;
  Dep: TRqDep;
begin
  if not chkIgnore.Checked then
    Exit;
  for ItemIdx := 0 to lvDeps.Items.Count - 1 do
    if not lvDeps.Items[ItemIdx].Checked then
    begin
      Dep := TRqDep(lvDeps.Items[ItemIdx].Data);
      FIgnore.Add(UpperCase(Dep.Name));
    end;
end;

// Отмеченные - выбранной копией туда, куда указано (RqDepTargetPath); что
// скопировано - в лог сборки (FLog). Скопированное снимается с отметки:
// второй раз не копируется. Результат - было ли что копировать.
function TRqDepsForm.CopyChecked(var ACopied, AFailed: Integer): Boolean;
var
  ItemIdx: Integer;
  Dep: TRqDep;
  Target: string;
begin
  ACopied := 0;
  AFailed := 0;
  Result := False;
  for ItemIdx := 0 to lvDeps.Items.Count - 1 do
  begin
    if not lvDeps.Items[ItemIdx].Checked then
      Continue;
    Dep := TRqDep(lvDeps.Items[ItemIdx].Data);
    if Dep.Chosen < 0 then
      Continue;
    Result := True;
    Target := RqDepTargetPath(Dep, FScan.IncDir, FScan.MainDir);
    if FileExists(Target) then
    begin
      FLog.Add('Не скопирован ' + Dep.Name + ': ' + Target + ' уже есть');
      Inc(AFailed);
      Continue;
    end;
    ForceDirectories(ExtractFilePath(Target));
    if CopyFile(PChar(Dep.Candidates[Dep.Chosen]), PChar(Target), True) then
    begin
      FLog.Add('Скопирован ' + Dep.Name + ': ' + Dep.Candidates[Dep.Chosen] +
               ' -> ' + Target + ' (' + Dep.ChosenNote + ')');
      Inc(ACopied);
      FFilling := True;
      try
        lvDeps.Items[ItemIdx].Checked := False;
      finally
        FFilling := False;
      end;
    end
    else
    begin
      FLog.Add('Не скопирован ' + Dep.Name + ': ' +
               SysErrorMessage(GetLastError));
      Inc(AFailed);
    end;
  end;
end;

procedure TRqDepsForm.btnCopyClick(Sender: TObject);
var
  Copied, Failed: Integer;
begin
  CopyChecked(Copied, Failed);
  CollectIgnore;
  if Failed > 0 then
  begin
    lblStatus.Caption := Format('Скопировано: %d, не скопировано: %d - ' +
                                'подробности в логе сборки', [Copied, Failed]);
  end;
  ModalResult := mrOk;
end;

// Только скопировать: окно остаётся, итог - в строке состояния, подробности
// (что, откуда, куда) - в логе сборки после закрытия окна
procedure TRqDepsForm.btnCopyOnlyClick(Sender: TObject);
var
  Copied, Failed, LogFrom: Integer;
begin
  LogFrom := FLog.Count;
  if not CopyChecked(Copied, Failed) then
  begin
    lblStatus.Caption := 'Нечего копировать: нет отмеченных файлов с ' +
                         'найденной копией';
    Exit;
  end;
  lblStatus.Caption := Format('Скопировано: %d', [Copied]);
  if Failed > 0 then
    lblStatus.Caption := lblStatus.Caption +
      Format(', не скопировано: %d (%s)', [Failed, FLog[FLog.Count - 1]]);
  if (Copied = 1) and (Failed = 0) and (FLog.Count > LogFrom) then
    lblStatus.Caption := FLog[FLog.Count - 1];
end;

// Эталон для проверки inc - один раз за окно. False - не прочитан.
function TRqDepsForm.EnsureRef: Boolean;
begin
  if FRef = nil then
  begin
    SetBusy(True);
    try
      FRef := TIncRefIndex.Create;
      if not FRef.Load(FRefDir, FSysDir, ProgressStep) then
        FreeAndNil(FRef);
    finally
      SetBusy(False);
    end;
  end;
  Result := FRef <> nil;
  if not Result then
    lblStatus.Caption := 'Эталон не прочитан - проверка прервана';
end;

// Проверка INC Manager по файлам AFiles: отчёт - в AReport, результат -
// сколько ошибок всего
function TRqDepsForm.CheckFiles(AFiles, AReport: TStrings): Integer;
var
  FileIdx, MsgIdx, ColonAt: Integer;
  Info: TIncFileInfo;
  Msg: string;
begin
  Result := 0;
  for FileIdx := 0 to AFiles.Count - 1 do
  begin
    Info := TIncFileInfo.Create(AFiles[FileIdx]);
    try
      IncCheckFile(Info, FRef);
      Inc(Result, Info.Errors);
      // Замечания (без "ошибка:") в число ошибок не входят - считаются
      // отдельно, чтобы "ошибок: 0" рядом со списком строк не путало
      AReport.Add(AFiles[FileIdx] + ' - ' + IncStatusNames[Info.Status] +
                  Format(', ошибок: %d, замечаний: %d',
                         [Info.Errors, Info.Messages.Count - Info.Errors]));
      for MsgIdx := 0 to Info.Messages.Count - 1 do
      begin
        Msg := Info.Messages[MsgIdx];
        // "стр. 6: замечание: ..." - номер строки остаётся в начале, по
        // нему щелчок переходит к строке
        if Pos('ошибка:', Msg) = 0 then
        begin
          ColonAt := Pos(': ', Msg);
          if (Copy(Msg, 1, 5) = 'стр. ') and (ColonAt > 0) then
            Insert('замечание: ', Msg, ColonAt + 2)
          else
            Msg := 'замечание: ' + Msg;
        end;
        AReport.Add('    ' + Msg);
      end;
    finally
      Info.Free;
    end;
  end;
end;

// Исправить однозначные ошибки в AFiles (IncAutoFix); копии до
// исправления - в список Undo
procedure TRqDepsForm.FixFiles(AFiles, AReport: TStrings);
var
  FileIdx, Fixed: Integer;
  Backup, Err: string;
  FixRep: TStringList;
begin
  FixRep := TStringList.Create;
  try
    for FileIdx := 0 to AFiles.Count - 1 do
    begin
      FixRep.Clear;
      Fixed := IncAutoFix(AFiles[FileIdx], FixRep, Backup, Err);
      if Fixed < 0 then
        AReport.Add(AFiles[FileIdx] + ' - не исправлен: ' + Err)
      else if Fixed = 0 then
        AReport.Add(AFiles[FileIdx] + ' - исправлять нечего ' +
                    '(ошибки только те, что правят руками)')
      else
      begin
        AReport.Add(Format('%s - исправлено строк: %d, прежний текст - %s',
                           [AFiles[FileIdx], Fixed, ExtractFileName(Backup)]));
        AReport.AddStrings(FixRep);
        FFixFiles.Add(AFiles[FileIdx]);
        FFixBaks.Add(Backup);
      end;
    end;
  finally
    FixRep.Free;
  end;
  btnUndo.Enabled := FFixFiles.Count > 0;
end;

// После поиска: копии, найденные в Include User, - проверить; есть
// ошибки - список в просмотре и вопрос, исправить ли файлы
procedure TRqDepsForm.CheckUserIncludes;
var
  ItemIdx, ErrCount: Integer;
  Dep: TRqDep;
  Files, Report: TStringList;
begin
  Files := TStringList.Create;
  Report := TStringList.Create;
  try
    for ItemIdx := 0 to FScan.Count - 1 do
    begin
      Dep := FScan[ItemIdx];
      if Dep.Missing and (Dep.Kind = dpkInclude) and (Dep.Chosen >= 0) and
         (CompareText(Dep.Where[Dep.Chosen], 'Include User') = 0) and
         (Files.IndexOf(Dep.Candidates[Dep.Chosen]) < 0) then
        Files.Add(Dep.Candidates[Dep.Chosen]);
    end;
    if (Files.Count = 0) or not EnsureRef then
      Exit;
    Report.Add(Format('Найдены в Include User: %d. Проверка:', [Files.Count]));
    ErrCount := CheckFiles(Files, Report);
    SetReport(Report);
    if ErrCount = 0 then
    begin
      lblStatus.Caption := 'Файлы из Include User проверены - ошибок нет';
      Exit;
    end;
    lblStatus.Caption := Format('В файлах из Include User ошибок: %d',
                                [ErrCount]);
    ShowOffer(Files, Report, ErrCount);
  finally
    Report.Free;
    Files.Free;
  end;
end;

// Проверить выбранную копию inc (как INC Manager) и исправить однозначные
// ошибки на месте; отчёт - в окне просмотра
procedure TRqDepsForm.btnFixClick(Sender: TObject);
var
  Dep: TRqDep;
  Files, Report: TStringList;
  ErrCount: Integer;
begin
  Dep := SelectedDep;
  if (Dep = nil) or (lvCands.Selected = nil) or FBusy then
    Exit;
  if Dep.Kind <> dpkInclude then
  begin
    lblStatus.Caption := 'Проверка - только для inc';
    Exit;
  end;
  if not EnsureRef then
    Exit;
  Files := TStringList.Create;
  Report := TStringList.Create;
  try
    Files.Add(lvCands.Selected.Caption);
    ErrCount := CheckFiles(Files, Report);
    SetReport(Report);
    lblStatus.Caption := Format('%s: ошибок %d', [ExtractFileName(Files[0]),
                                                  ErrCount]);
    if ErrCount > 0 then
      ShowOffer(Files, Report, ErrCount)
    else
    begin
      FShowOffer := False;
      ArrangeTop;
    end;
  finally
    Report.Free;
    Files.Free;
  end;
end;

// Панель-предложение: ошибки - в просмотре, решение - кнопками на панели
procedure TRqDepsForm.ShowOffer(AFiles, AReport: TStrings; AErrors: Integer);
begin
  FOfferFiles.Assign(AFiles);
  FOfferReport.Assign(AReport);
  if AFiles.Count = 1 then
    lblOffer.Caption := Format('%s: ошибок %d (список ниже). Исправить файл? ' +
      'Исходный будет сохранён с расширением .bak',
      [ExtractFileName(AFiles[0]), AErrors])
  else
    lblOffer.Caption := Format('В файлах из Include User ошибок: %d (список ' +
      'ниже). Исправить файлы? Исходные будут сохранены с расширением .bak',
      [AErrors]);
  lblOffer.Hint := 'Исправляются однозначные ошибки (директивы без $, числа ' +
                   'с U/L и 0x из C, ";" вне строки), остальные правят ' +
                   'руками. Кнопка Undo вернёт прежние файлы.';
  lblOffer.ShowHint := True;
  FShowOffer := True;
  SetReport(AReport);
end;

procedure TRqDepsForm.btnOfferFixClick(Sender: TObject);
var
  Report: TStringList;
  ErrCount: Integer;
begin
  FShowOffer := False;
  ArrangeTop;
  if FOfferFiles.Count = 0 then
    Exit;
  Report := TStringList.Create;
  try
    Report.Assign(FOfferReport);
    Report.Add('');
    Report.Add('Исправление:');
    FixFiles(FOfferFiles, Report);
    Report.Add('');
    Report.Add('После исправления:');
    ErrCount := CheckFiles(FOfferFiles, Report);
    SetReport(Report);
    lblStatus.Caption := Format('Исправлено; ошибок осталось: %d', [ErrCount]);
  finally
    Report.Free;
  end;
  FOfferFiles.Clear;
end;

procedure TRqDepsForm.btnOfferSkipClick(Sender: TObject);
begin
  FShowOffer := False;
  ArrangeTop;
  FOfferFiles.Clear;
  lblStatus.Caption := 'Файлы не исправлены';
end;

// Undo: исправленные файлы удалить, прежние - из .bak обратно
procedure TRqDepsForm.btnUndoClick(Sender: TObject);
var
  FileIdx: Integer;
  Err: string;
  Report: TStringList;
begin
  if FFixFiles.Count = 0 then
    Exit;
  Report := TStringList.Create;
  try
    Report.Add('Undo:');
    for FileIdx := FFixFiles.Count - 1 downto 0 do
      if IncUndoFix(FFixFiles[FileIdx], FFixBaks[FileIdx], Err) then
      begin
        Report.Add(FFixFiles[FileIdx] + ' - возвращён прежний');
        FFixFiles.Delete(FileIdx);
        FFixBaks.Delete(FileIdx);
      end
      else
        Report.Add(FFixFiles[FileIdx] + ' - не вышло: ' + Err);
    SetReport(Report);
    if FFixFiles.Count = 0 then
      lblStatus.Caption := 'Исправления отменены'
    else
      lblStatus.Caption := Format('Не отменено файлов: %d', [FFixFiles.Count]);
  finally
    Report.Free;
  end;
  btnUndo.Enabled := FFixFiles.Count > 0;
end;

procedure TRqDepsForm.btnBuildClick(Sender: TObject);
begin
  CollectIgnore;
  ModalResult := mrOk;
end;

procedure TRqDepsForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FBusy then
  begin
    FAbort := True;
    CanClose := False;
  end;
end;

function RqDepsDialog(AOwner: TComponent; AScan: TRqDepScan; ARoots: TStrings;
                      const ARefDir, ASysDir: string;
                      ALog, AIgnore: TStrings;
                      AScheme: TClrScheme; const AIniFile: string;
                      APickDirs: TRqPickDirs;
                      AEditLine: TRqEditLine): Boolean;
var
  Dlg: TRqDepsForm;
begin
  Result := False;
  if OpenDlg <> nil then
    Exit;
  Dlg := TRqDepsForm.CreateNew(AOwner);
  OpenDlg := Dlg;
  try
    Dlg.FScan := AScan;
    Dlg.FRoots := ARoots;
    Dlg.FRefDir := ARefDir;
    Dlg.FSysDir := ASysDir;
    Dlg.FLog := ALog;
    Dlg.FIgnore := AIgnore;
    Dlg.FScheme := AScheme;
    Dlg.FIniFile := AIniFile;
    Dlg.FPickDirs := APickDirs;
    Dlg.FEditLine := AEditLine;
    Dlg.BuildControls;
    Dlg.LoadPlacement;
    Dlg.FillTop;
    // Немодально: главное окно доступно. Ждём здесь, пока окно не закроют
    // кнопкой (ModalResult) или крестиком; программу закрыли - отмена.
    Dlg.Show;
    repeat
      Application.HandleMessage;
    until (Dlg.ModalResult <> mrNone) or not Dlg.Visible or
          Application.Terminated;
    Result := Dlg.ModalResult = mrOk;
    Dlg.SavePlacement;
    Dlg.Hide;
  finally
    OpenDlg := nil;
    Dlg.Free;
  end;
end;

function RqDepsDialogActive: Boolean;
begin
  Result := OpenDlg <> nil;
  if Result then
  begin
    if OpenDlg.WindowState = wsMinimized then
      OpenDlg.WindowState := wsNormal;
    OpenDlg.BringToFront;
  end;
end;

procedure RqDepsAddUserRoots(ARoots: TStrings; const AIniFile: string);
var
  Ini: TIniFile;
  Rest, OneDir: string;
  SepPos: Integer;
begin
  if (AIniFile = '') or not FileExists(AIniFile) then
    Exit;
  Ini := TIniFile.Create(AIniFile);
  try
    Rest := Ini.ReadString('RqDepsSearch', 'Dirs', '');
  finally
    Ini.Free;
  end;
  while Rest <> '' do
  begin
    SepPos := Pos('|', Rest);
    if SepPos = 0 then
      SepPos := Length(Rest) + 1;
    OneDir := Trim(Copy(Rest, 1, SepPos - 1));
    if OneDir <> '' then
      ARoots.Add(RqDepsUserRootLabel + '|' + OneDir);
    Delete(Rest, 1, SepPos);
  end;
end;

initialization

finalization
  if RichEdit20Lib <> 0 then
    FreeLibrary(RichEdit20Lib);

end.
