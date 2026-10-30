unit DlgGitCommit;

// ---------------------------------------------------------------------------
//  Окно Commit для меню Repository / панели Git (Unit1): список изменённых
//  файлов с флажками (что войдёт в коммит), разница выбранного файла
//  (git diff - строит Unit1, OnDiff), заголовок и описание коммита, кнопки
//  Commit, Commit and Push, Cancel. Как окно изменений GitHub Desktop.
//
//  Окно строится в коде (CreateDlg), .dfm нет. Коммит делает Unit1:
//  отмеченные файлы (CheckedChanges) и текст (MessageText) забирает после
//  ShowModal = mrOk; PushAfter - нажата Commit and Push.
//
//  Discard Selected (и правый щелчок по строке - Discard Changes) -
//  отменить изменения выделенных строк (OnDiscard - Unit1 спрашивает и
//  выполняет). Ignore... (и правый щелчок - Ignore) - чтобы выделенные
//  файлы больше не предлагались к коммиту (OnIgnore - Unit1: .gitignore,
//  .git/info/exclude, git rm --cached, skip-worktree). После обоих список
//  перечитывается (OnStatus), флажки сохраняются.
//
//  Строки раскрашены по виду файла (GitFileKind) и отсортированы по нему:
//  сверху красные - то, что обычно не коммитят (exe, old, log, $$$, dcu,
//  obj, tmp, bak, ~*, архивы zip / 7z / rar ...), затем жёлтые -
//  библиотеки (dll, bpl, ocx, lib, res), фиолетовые - картинки, зелёные -
//  исходники, голубые - текст и настройки, остальные - цветом темы.
//  Красные при первом показе - без флажка (остальные - с флажком).
//  Над списком - флажок на каждый вид, что есть в списке: отметить / снять
//  сразу все его строки (часть отмечена - флажок серый). Цвета - для светлого и
//  тёмного фона списка свои.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, ComCtrls, Menus,
  UiMenus,       // TUiPopupMenu
  UiButton,      // TUiButton
  UiEditCtrls,   // TUiEdit, TUiMemo
  UiStdCtrls,    // TUiCheckBox, TUiLabel, TUiPanel
  UiComCtrls,    // TUiListView
  GitDiffView,   // TGitDiffView - разница с подсветкой
  GitRun;        // TGitChange

type
  // Разница для файла (текст для показа)
  TGitDiffEvent = function(const AChange: TGitChange): WideString of object;
  // Отменить изменения файлов (Discard) или игнорировать их (Ignore);
  // True - сделано
  TGitDiscardEvent = function(const AChanges: TGitChanges): Boolean of object;
  // Перечитать изменения (git status); False - не вышло
  TGitStatusEvent = function(var AChanges: TGitChanges): Boolean of object;

  TDlgGitCommit = class(TForm)
  private
    FChanges: TGitChanges;
    FOnDiff: TGitDiffEvent;
    FOnDiscard: TGitDiscardEvent;
    FOnIgnore: TGitDiscardEvent;
    FOnStatus: TGitStatusEvent;
    FBtnIgnore: TUiButton;
    FTopPanel: TUiPanel;
    FBtnDiscard: TUiButton;
    FListMenu: TUiPopupMenu;
    FPushAfter: Boolean;
    FLeft: TUiPanel;
    FMsgPanel: TUiPanel;
    FBtnPanel: TUiPanel;
    FChkAll: TUiCheckBox;
    FList: TUiListView;
    FLblSummary: TUiLabel;
    FSummary: TUiEdit;
    FLblDescr: TUiLabel;
    FDescr: TUiMemo;
    FDiff: TGitDiffView;
    FSplitter: TSplitter;
    FBtnCommit: TUiButton;
    FBtnPush: TUiButton;
    FBtnCancel: TUiButton;
    FFilling: Boolean;
    // Флажки видов файлов (индекс - вид gfk*, 0..5) и их панель;
    // FKindUpdating - флажки ставит код (их OnClick не трогает строки)
    FKindPanel: TUiPanel;
    FKindChecks: array[0..5] of TUiCheckBox;
    FKindUpdating: Boolean;
    FKindLaying: Boolean;
    // Заголовок, подставленный автоматически (AutoSummary); пока поле
    // совпадает с ним, он обновляется вслед за флажками
    FAutoSummary: string;
    procedure UpdateAutoSummary;
    procedure KindCheckClick(Sender: TObject);
    procedure LayoutKinds(Sender: TObject);
    procedure ListSelect(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure ListChange(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure ChkAllClick(Sender: TObject);
    procedure BtnDiscardClick(Sender: TObject);
    procedure BtnIgnoreClick(Sender: TObject);
    function SelectedChanges(var APicked: TGitChanges): Integer;
    procedure FillList;
    procedure ListCustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure ListCustomDrawSubItem(Sender: TCustomListView; Item: TListItem;
      SubItem: Integer; State: TCustomDrawState; var DefaultDraw: Boolean);
    function ItemKindColor(Item: TListItem): TColor;
    procedure Reload;
    procedure BtnCommitClick(Sender: TObject);
    procedure BtnPushClick(Sender: TObject);
    procedure LayoutButtons(Sender: TObject);
    procedure LayoutTop(Sender: TObject);
    procedure LayoutMsg(Sender: TObject);
    procedure UpdateCount;
    function TryClose: Boolean;
    // $0128 - WM_UPDATEUISTATE (кнопки не пропадают по Alt, как в других окнах)
    procedure WMUpdateUIState(var Message: TMessage); message $0128;
  public
    constructor CreateDlg(AOwner: TComponent; const ATitle: string;
      const AChanges: TGitChanges; AOnDiff: TGitDiffEvent;
      AOnDiscard, AOnIgnore: TGitDiscardEvent; AOnStatus: TGitStatusEvent);
    // Отмеченные файлы
    procedure CheckedChanges(var AList: TGitChanges);
    // Заголовок, пустая строка, описание - как пишет GitHub Desktop
    function MessageText: string;
    property PushAfter: Boolean read FPushAfter;
    // Схема подсветки кода в разнице (Unit1.SchemeCopyFor)
    procedure SetSchemeProvider(AProvider: TGitSchemeEvent);
  end;

// Вид файла и его цвет - и для окна Tracked but Ignored (DlgGitTracked)
const
  // Вид файла в окне Commit (порядок - порядок строк)
  gfkJunk = 0;      // красный: сборка, журналы, резервные копии
  gfkBinary = 1;    // жёлтый: библиотеки, архивы, ресурсы
  gfkImage = 2;     // фиолетовый: картинки
  gfkSource = 3;    // зелёный: исходники
  gfkText = 4;      // голубой: текст, настройки, скрипты
  gfkOther = 5;     // цвет темы
  gfkCount = 6;

  GitKindNames: array[0..gfkCount - 1] of string = (
    'не коммитить?', 'библиотека', 'картинка', 'исходник', 'текст', '');

// Вид файла по имени и расширению (gfk*)
function GitFileKind(const APath: WideString): Integer;
// Цвет текста вида AKind на фоне ABack (светлый / тёмный - свои цвета);
// clNone - цвет темы
function GitKindColor(AKind: Integer; ABack: TColor): TColor;

implementation

const
  // Подписи флажков видов над списком
  GitKindGroupNames: array[0..gfkCount - 1] of string = (
    'не коммитить', 'библиотеки', 'картинки', 'исходники', 'текст', 'прочее');

  // Расширения через ';' с ';' по краям - поиск по ';.ext;'
  GitJunkExts = ';.exe;.com;.old;.log;.$$$;.tmp;.temp;.bak;.dcu;.obj;.o;' +
    '.map;.tds;.ilk;.pdb;.dsk;.ddp;.local;.identcache;.stat;.cbk;.drc;' +
    '.zip;.rar;.7z;.cab;.msi;.jar;.tar;.gz;.tgz;.bz2;.xz;.arj;.lzh;.lha;' +
    '.iso;.ace;.zst;';
  GitBinaryExts = ';.dll;.ocx;.bpl;.dpl;.dcp;.so;.lib;.a;.sys;.drv;.cpl;' +
    '.res;.chm;.pdf;.db;';
  GitImageExts = ';.png;.jpg;.jpeg;.gif;.bmp;.ico;.cur;.ani;.svg;.tif;' +
    '.tiff;.webp;.psd;.emf;.wmf;';
  GitSourceExts = ';.pas;.pp;.dpr;.dpk;.dfm;.lfm;.lpr;.lpi;.lpk;.inc;.bas;' +
    '.bi;.rqb;.rq;.c;.cpp;.cc;.cxx;.h;.hpp;.ino;.py;.go;.rs;.js;.ts;.java;' +
    '.cs;.vb;.vbp;.frm;.asm;.ahk;.rc;.cmake;.lua;';
  GitTextExts = ';.txt;.md;.ini;.cfg;.conf;.json;.xml;.html;.htm;.css;' +
    '.bat;.cmd;.sh;.ps1;.lst;.csv;.yml;.yaml;.toml;.dof;.clr;.manifest;' +
    '.gitignore;.gitattributes;';

// Вид файла по имени и расширению
function GitFileKind(const APath: WideString): Integer;
var
  FileName, Ext: string;
begin
  FileName := LowerCase(ExtractFileName(StringReplace(string(APath), '/',
    '\', [rfReplaceAll])));
  Ext := ExtractFileExt(FileName);
  if Ext = '' then
    Ext := FileName;               // .gitignore и т. п. без имени
  if (FileName = 'thumbs.db') or (FileName = 'desktop.ini') or
     (Copy(Ext, 1, 2) = '.~') or (Pos(';' + Ext + ';', GitJunkExts) > 0) then
    Result := gfkJunk
  else if Pos(';' + Ext + ';', GitBinaryExts) > 0 then
    Result := gfkBinary
  else if Pos(';' + Ext + ';', GitImageExts) > 0 then
    Result := gfkImage
  else if Pos(';' + Ext + ';', GitSourceExts) > 0 then
    Result := gfkSource
  else if (Pos(';' + Ext + ';', GitTextExts) > 0) or
          (Pos(';.' + FileName + ';', GitTextExts) > 0) then
    Result := gfkText
  else
    Result := gfkOther;
end;

// Цвет текста вида AKind на фоне ABack (светлый / тёмный - свои цвета);
// clNone - цвет темы
function GitKindColor(AKind: Integer; ABack: TColor): TColor;
const
  // $00BBGGRR
  DarkColors: array[0..gfkCount - 1] of TColor = (
    $005A5AFF, $0040E0F0, $00FF80D0, $0070D070, $00E0D060, clNone);
  LightColors: array[0..gfkCount - 1] of TColor = (
    $000000C8, $000088A8, $00A00080, $00008000, $00A06000, clNone);
var
  BackRgb: Longint;
  Brightness: Integer;
begin
  Result := clNone;
  if (AKind < 0) or (AKind >= gfkCount) then
    Exit;
  BackRgb := ColorToRGB(ABack);
  Brightness := (GetRValue(BackRgb) * 299 + GetGValue(BackRgb) * 587 +
    GetBValue(BackRgb) * 114) div 1000;
  if Brightness < 128 then
    Result := DarkColors[AKind]
  else
    Result := LightColors[AKind];
end;

constructor TDlgGitCommit.CreateDlg(AOwner: TComponent; const ATitle: string;
  const AChanges: TGitChanges; AOnDiff: TGitDiffEvent;
  AOnDiscard, AOnIgnore: TGitDiscardEvent; AOnStatus: TGitStatusEvent);
var
  Column: TListColumn;
  MenuItem: TMenuItem;
  KindIdx: Integer;
begin
  inherited CreateNew(AOwner);
  FChanges := AChanges;
  FOnDiff := AOnDiff;
  FOnDiscard := AOnDiscard;
  FOnIgnore := AOnIgnore;
  FOnStatus := AOnStatus;
  FPushAfter := False;
  Caption := ATitle;
  Position := poMainFormCenter;
  BorderStyle := bsSizeable;
  BorderIcons := [biSystemMenu, biMaximize];
  Width := 900;
  Height := 600;
  Constraints.MinWidth := 600;
  Constraints.MinHeight := 400;
  KeyPreview := True;

  FLeft := TUiPanel.Create(Self);
  FLeft.Parent := Self;
  FLeft.Align := alLeft;
  FLeft.Width := 460;
  FLeft.BevelOuter := bvNone;
  FLeft.Caption := '';

  FSplitter := TSplitter.Create(Self);
  FSplitter.Parent := Self;
  FSplitter.Align := alLeft;
  FSplitter.Left := FLeft.Width + 1;
  FSplitter.Width := 5;

  FDiff := TGitDiffView.Create(Self);
  FDiff.Parent := Self;
  FDiff.Align := alClient;
  FDiff.ShowDiff('Выберите файл слева - здесь будет его разница ' +
    '(git diff).');

  // Сверху слева: флажок «все» и Discard Selected
  FTopPanel := TUiPanel.Create(Self);
  FTopPanel.Parent := FLeft;
  FTopPanel.Align := alTop;
  FTopPanel.Height := 28;
  FTopPanel.BevelOuter := bvNone;
  FTopPanel.Caption := '';

  FChkAll := TUiCheckBox.Create(Self);
  FChkAll.Parent := FTopPanel;
  FChkAll.SetBounds(2, 4, 200, 20);
  FChkAll.Checked := True;
  FChkAll.OnClick := ChkAllClick;

  FBtnDiscard := TUiButton.Create(Self);
  FBtnDiscard.Parent := FTopPanel;
  // Место - в LayoutTop: до первого показа окна выравнивание (Align) ещё
  // не прошло, ширина панели - не та, и якоря дали бы кнопку за краем
  FTopPanel.OnResize := LayoutTop;
  FBtnDiscard.Caption := 'Discard Selected...';
  FBtnDiscard.Hint := 'Отменить изменения выделенных строк (не флажков): ' +
    'файлы - как в последнем коммите, новые файлы - в корзину';
  FBtnDiscard.ShowHint := True;
  FBtnDiscard.OnClick := BtnDiscardClick;
  FBtnDiscard.Visible := Assigned(AOnDiscard);

  FBtnIgnore := TUiButton.Create(Self);
  FBtnIgnore.Parent := FTopPanel;
  FBtnIgnore.Caption := 'Ignore...';
  FBtnIgnore.Hint := 'Чтобы выделенные файлы больше не предлагались к ' +
    'коммиту: .gitignore, только у себя (.git/info/exclude), перестать ' +
    'отслеживать или скрыть свои изменения';
  FBtnIgnore.ShowHint := True;
  FBtnIgnore.OnClick := BtnIgnoreClick;
  FBtnIgnore.Visible := Assigned(AOnIgnore);
  LayoutTop(nil);

  // Под ним: флажки видов файлов (видны только те виды, что есть в списке)
  FKindPanel := TUiPanel.Create(Self);
  FKindPanel.Parent := FLeft;
  FKindPanel.Align := alTop;
  FKindPanel.Top := FTopPanel.Top + FTopPanel.Height;
  FKindPanel.Height := 24;
  FKindPanel.BevelOuter := bvNone;
  FKindPanel.Caption := '';
  for KindIdx := 0 to gfkCount - 1 do
  begin
    FKindChecks[KindIdx] := TUiCheckBox.Create(Self);
    FKindChecks[KindIdx].Parent := FKindPanel;
    FKindChecks[KindIdx].Tag := KindIdx;
    FKindChecks[KindIdx].Visible := False;
    FKindChecks[KindIdx].Hint := 'Отметить / снять все строки этого вида';
    FKindChecks[KindIdx].ShowHint := True;
    FKindChecks[KindIdx].OnClick := KindCheckClick;
  end;
  FKindPanel.OnResize := LayoutKinds;

  // Низ левой части: заголовок, описание, кнопки
  FMsgPanel := TUiPanel.Create(Self);
  FMsgPanel.Parent := FLeft;
  FMsgPanel.Align := alBottom;
  FMsgPanel.Height := 200;
  FMsgPanel.BevelOuter := bvNone;
  FMsgPanel.Caption := '';

  // У TUiEdit нет Align - место и якоря вручную (ширина панели - как у
  // левой части)
  FLblSummary := TUiLabel.Create(Self);
  FLblSummary.Parent := FMsgPanel;
  FLblSummary.SetBounds(2, 4, 300, 16);
  FLblSummary.Caption := 'Заголовок (Summary, обязательно):';

  FSummary := TUiEdit.Create(Self);
  FSummary.Parent := FMsgPanel;
  FSummary.SetBounds(2, 22, 200, 22);

  FLblDescr := TUiLabel.Create(Self);
  FLblDescr.Parent := FMsgPanel;
  FLblDescr.SetBounds(2, 50, 300, 16);
  FLblDescr.Caption := 'Описание (Description):';

  FBtnPanel := TUiPanel.Create(Self);
  FBtnPanel.Parent := FMsgPanel;
  FBtnPanel.Align := alBottom;
  FBtnPanel.Height := 34;
  FBtnPanel.BevelOuter := bvNone;
  FBtnPanel.Caption := '';
  FBtnPanel.OnResize := LayoutButtons;

  FDescr := TUiMemo.Create(Self);
  FDescr.Parent := FMsgPanel;
  FDescr.SetBounds(2, 68, 200, 60);
  // Ширина поля заголовка и размер описания - в LayoutMsg (по панели)
  FMsgPanel.OnResize := LayoutMsg;
  FDescr.ScrollBars := ssVertical;

  FBtnCommit := TUiButton.Create(Self);
  FBtnCommit.Parent := FBtnPanel;
  FBtnCommit.Caption := 'Commit';
  FBtnCommit.Default := True;
  FBtnCommit.OnClick := BtnCommitClick;
  FBtnCommit.Hint := 'Закоммитить отмеченные файлы в текущую ветку';
  FBtnCommit.ShowHint := True;

  FBtnPush := TUiButton.Create(Self);
  FBtnPush.Parent := FBtnPanel;
  FBtnPush.Caption := 'Commit and Push';
  FBtnPush.OnClick := BtnPushClick;
  FBtnPush.Hint := 'Закоммитить и сразу отправить на сервер (git push)';
  FBtnPush.ShowHint := True;

  FBtnCancel := TUiButton.Create(Self);
  FBtnCancel.Parent := FBtnPanel;
  FBtnCancel.Caption := 'Cancel';
  FBtnCancel.Cancel := True;
  FBtnCancel.ModalResult := mrCancel;

  FList := TUiListView.Create(Self);
  FList.Parent := FLeft;
  FList.Align := alClient;
  FList.ViewStyle := vsReport;
  FList.Checkboxes := True;
  FList.ReadOnly := True;
  FList.RowSelect := True;
  FList.MultiSelect := True;
  FList.HideSelection := False;
  Column := FList.Columns.Add;
  Column.Caption := 'Файл';
  Column.Width := 230;
  Column := FList.Columns.Add;
  Column.Caption := 'Что';
  Column.Width := 80;
  Column := FList.Columns.Add;
  Column.Caption := 'Вид';
  Column.Width := 90;
  FList.OnCustomDrawItem := ListCustomDrawItem;
  FList.OnCustomDrawSubItem := ListCustomDrawSubItem;
  FillList;
  // Правый щелчок по строке - меню (Discard Changes, Ignore)
  FListMenu := TUiPopupMenu.Create(Self);
  MenuItem := TMenuItem.Create(Self);
  MenuItem.Caption := 'Discard Changes...';
  MenuItem.OnClick := BtnDiscardClick;
  FListMenu.Items.Add(MenuItem);
  MenuItem := TMenuItem.Create(Self);
  MenuItem.Caption := 'Ignore...';
  MenuItem.OnClick := BtnIgnoreClick;
  FListMenu.Items.Add(MenuItem);
  FList.PopupMenu := FListMenu;
  FList.OnSelectItem := ListSelect;
  FList.OnChange := ListChange;
  UpdateCount;
  ActiveControl := FSummary;
end;

procedure TDlgGitCommit.SetSchemeProvider(AProvider: TGitSchemeEvent);
begin
  FDiff.OnScheme := AProvider;
end;

procedure TDlgGitCommit.WMUpdateUIState(var Message: TMessage);
begin
  Message.Result := 0;
end;

procedure TDlgGitCommit.LayoutButtons(Sender: TObject);
const
  BtnGap = 6;
  BtnH = 24;
var
  BtnTop, BtnLeft: Integer;
begin
  BtnTop := (FBtnPanel.ClientHeight - BtnH) div 2;
  BtnLeft := 0;
  FBtnCommit.SetBounds(BtnLeft, BtnTop, 80, BtnH);
  Inc(BtnLeft, 80 + BtnGap);
  FBtnPush.SetBounds(BtnLeft, BtnTop, 120, BtnH);
  FBtnCancel.SetBounds(FBtnPanel.ClientWidth - 70, BtnTop, 70, BtnH);
end;

procedure TDlgGitCommit.LayoutTop(Sender: TObject);
begin
  FBtnDiscard.SetBounds(FTopPanel.ClientWidth - 122, 2, 118, 23);
  if FBtnIgnore <> nil then
    FBtnIgnore.SetBounds(FTopPanel.ClientWidth - 122 - 6 - 70, 2, 70, 23);
end;

// Строки списка из FChanges - по виду файла (красные сверху), внутри
// вида - в порядке git status. Строка, что была до перечитывания, -
// с прежним флажком; новая - с флажком, кроме красных (не коммитить)
procedure TDlgGitCommit.FillList;
var
  Unchecked, Checked: TStringList;
  ChangeIdx, ItemIdx, KindIdx, OrderIdx: Integer;
  Order: array of Integer;
  Item: TListItem;
begin
  // Порядок строк: сначала все красные, затем жёлтые и т. д.
  SetLength(Order, Length(FChanges));
  OrderIdx := 0;
  for KindIdx := 0 to gfkCount - 1 do
    for ChangeIdx := 0 to High(FChanges) do
      if GitFileKind(FChanges[ChangeIdx].Path) = KindIdx then
      begin
        Order[OrderIdx] := ChangeIdx;
        Inc(OrderIdx);
      end;
  Unchecked := TStringList.Create;
  Checked := TStringList.Create;
  FFilling := True;
  try
    for ItemIdx := 0 to FList.Items.Count - 1 do
      if FList.Items[ItemIdx].Checked then
        Checked.Add(FList.Items[ItemIdx].Caption)
      else
        Unchecked.Add(FList.Items[ItemIdx].Caption);
    FList.Items.BeginUpdate;
    try
      FList.Items.Clear;
      for OrderIdx := 0 to High(Order) do
      begin
        ChangeIdx := Order[OrderIdx];
        Item := FList.Items.Add;
        if FChanges[ChangeIdx].OrigPath <> '' then
          Item.Caption := string(GitWinPath(FChanges[ChangeIdx].Path)) +
            '  <-  ' + string(GitWinPath(FChanges[ChangeIdx].OrigPath))
        else
          Item.Caption := string(GitWinPath(FChanges[ChangeIdx].Path));
        Item.SubItems.Add(GitChangeText(FChanges[ChangeIdx].Code));
        Item.SubItems.Add(GitKindNames[GitFileKind(FChanges[ChangeIdx].Path)]);
        if Checked.IndexOf(Item.Caption) >= 0 then
          Item.Checked := True
        else if Unchecked.IndexOf(Item.Caption) >= 0 then
          Item.Checked := False
        else
          Item.Checked := GitFileKind(FChanges[ChangeIdx].Path) <> gfkJunk;
        Item.Data := Pointer(ChangeIdx);
      end;
    finally
      FList.Items.EndUpdate;
    end;
  finally
    FFilling := False;
    Unchecked.Free;
    Checked.Free;
  end;
  UpdateCount;
end;

// Цвет строки - по виду файла (clNone - цвет темы)
function TDlgGitCommit.ItemKindColor(Item: TListItem): TColor;
var
  ChangeIdx: Integer;
begin
  Result := clNone;
  if Item = nil then
    Exit;
  ChangeIdx := Integer(Item.Data);
  if (ChangeIdx < 0) or (ChangeIdx > High(FChanges)) then
    Exit;
  Result := GitKindColor(GitFileKind(FChanges[ChangeIdx].Path), FList.Color);
end;

procedure TDlgGitCommit.ListCustomDrawItem(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  KindColor: TColor;
begin
  KindColor := ItemKindColor(Item);
  if KindColor <> clNone then
    Sender.Canvas.Font.Color := KindColor
  else
    Sender.Canvas.Font.Color := FList.Font.Color;
  DefaultDraw := True;
end;

procedure TDlgGitCommit.ListCustomDrawSubItem(Sender: TCustomListView;
  Item: TListItem; SubItem: Integer; State: TCustomDrawState;
  var DefaultDraw: Boolean);
begin
  ListCustomDrawItem(Sender, Item, State, DefaultDraw);
end;

// После Discard / Ignore: изменения - заново (git status); пусто - окно
// закрывается
procedure TDlgGitCommit.Reload;
var
  Fresh: TGitChanges;
begin
  if not Assigned(FOnStatus) or not FOnStatus(Fresh) then
    Exit;
  FChanges := Fresh;
  FillList;
  FDiff.ShowDiff('');
  if FList.Items.Count = 0 then
    ModalResult := mrCancel;
end;

// Выделенные строки (не флажки) -> изменения; результат - сколько
function TDlgGitCommit.SelectedChanges(var APicked: TGitChanges): Integer;
var
  ItemIdx, ChangeIdx: Integer;
begin
  SetLength(APicked, 0);
  Result := 0;
  for ItemIdx := 0 to FList.Items.Count - 1 do
    if FList.Items[ItemIdx].Selected then
    begin
      ChangeIdx := Integer(FList.Items[ItemIdx].Data);
      if (ChangeIdx < 0) or (ChangeIdx > High(FChanges)) then
        Continue;
      SetLength(APicked, Result + 1);
      APicked[Result] := FChanges[ChangeIdx];
      Inc(Result);
    end;
end;

procedure TDlgGitCommit.BtnIgnoreClick(Sender: TObject);
var
  Picked: TGitChanges;
begin
  if not Assigned(FOnIgnore) then
    Exit;
  if SelectedChanges(Picked) = 0 then
  begin
    MessageBox(Handle, 'Выделите строки (щелчок, Ctrl+щелчок, Shift+щелчок) ' +
      '- какие файлы игнорировать.'#13#10#13#10'Флажки - это что войдёт в ' +
      'коммит; Ignore работает только с выделенными строками.', 'Ignore',
      MB_OK or MB_ICONINFORMATION);
    Exit;
  end;
  if FOnIgnore(Picked) then
    Reload;
end;

procedure TDlgGitCommit.LayoutMsg(Sender: TObject);
var
  DescrHeight: Integer;
begin
  FSummary.SetBounds(2, 22, FMsgPanel.ClientWidth - 4, 22);
  DescrHeight := FMsgPanel.ClientHeight - 68 - FBtnPanel.Height - 4;
  if DescrHeight < 20 then
    DescrHeight := 20;
  FDescr.SetBounds(2, 68, FMsgPanel.ClientWidth - 4, DescrHeight);
end;

// Счётчик отмеченных; флажок «все» и флажки видов: все строки отмечены -
// с флажком, часть - серый, ни одной - без флажка
procedure TDlgGitCommit.UpdateCount;
var
  ItemIdx, CheckedCount, KindIdx, ChangeIdx: Integer;
  KindTotal, KindChecked: array[0..gfkCount - 1] of Integer;
  KindColor: TColor;
  KindsChanged: Boolean;

  function StateOf(AChecked, ATotal: Integer): TCheckBoxState;
  begin
    if (ATotal > 0) and (AChecked = ATotal) then
      Result := cbChecked
    else if AChecked > 0 then
      Result := cbGrayed
    else
      Result := cbUnchecked;
  end;

begin
  CheckedCount := 0;
  for KindIdx := 0 to gfkCount - 1 do
  begin
    KindTotal[KindIdx] := 0;
    KindChecked[KindIdx] := 0;
  end;
  for ItemIdx := 0 to FList.Items.Count - 1 do
  begin
    ChangeIdx := Integer(FList.Items[ItemIdx].Data);
    KindIdx := gfkOther;
    if (ChangeIdx >= 0) and (ChangeIdx <= High(FChanges)) then
      KindIdx := GitFileKind(FChanges[ChangeIdx].Path);
    Inc(KindTotal[KindIdx]);
    if FList.Items[ItemIdx].Checked then
    begin
      Inc(CheckedCount);
      Inc(KindChecked[KindIdx]);
    end;
  end;
  FChkAll.Caption := 'Изменения: ' + IntToStr(CheckedCount) + ' из ' +
    IntToStr(FList.Items.Count) + ' отмечено';
  KindsChanged := False;
  FKindUpdating := True;
  try
    FChkAll.State := StateOf(CheckedCount, FList.Items.Count);
    if FKindPanel = nil then
      Exit;
    for KindIdx := 0 to gfkCount - 1 do
    begin
      if FKindChecks[KindIdx].Visible <> (KindTotal[KindIdx] > 0) then
        KindsChanged := True;
      FKindChecks[KindIdx].Visible := KindTotal[KindIdx] > 0;
      FKindChecks[KindIdx].Caption := GitKindGroupNames[KindIdx] + ' (' +
        IntToStr(KindChecked[KindIdx]) + '/' + IntToStr(KindTotal[KindIdx]) +
        ')';
      KindColor := GitKindColor(KindIdx, FList.Color);
      if KindColor <> clNone then
        FKindChecks[KindIdx].TextColor := KindColor;
      FKindChecks[KindIdx].State := StateOf(KindChecked[KindIdx],
        KindTotal[KindIdx]);
    end;
  finally
    FKindUpdating := False;
  end;
  if KindsChanged then
    LayoutKinds(nil);
  UpdateAutoSummary;
end;

// Заголовок коммита по отмеченным файлам, как у GitHub Desktop
// (по-английски): один файл - «Update Unit1.pas», «Add x.bas», «Delete
// y.txt», «Rename a.pas»; несколько одного вида - имена, если коротко,
// иначе «Update 5 files»; разные виды - «Add 2 files, update 3 files».
// Поле, которое правили руками, не трогается
procedure TDlgGitCommit.UpdateAutoSummary;
const
  VerbCount = 4;
  Verbs: array[0..VerbCount - 1] of string = ('Add', 'Update', 'Delete',
    'Rename');
  MaxNamesLen = 60;
var
  ItemIdx, ChangeIdx, VerbIdx, UsedVerbs, LastVerb: Integer;
  Counts: array[0..VerbCount - 1] of Integer;
  Names: array[0..VerbCount - 1] of string;
  Code, FileName, NewSummary, Part: string;
begin
  if FSummary = nil then
    Exit;
  if (Trim(FSummary.Text) <> '') and (FSummary.Text <> FAutoSummary) then
    Exit;
  for VerbIdx := 0 to VerbCount - 1 do
  begin
    Counts[VerbIdx] := 0;
    Names[VerbIdx] := '';
  end;
  for ItemIdx := 0 to FList.Items.Count - 1 do
  begin
    if not FList.Items[ItemIdx].Checked then
      Continue;
    ChangeIdx := Integer(FList.Items[ItemIdx].Data);
    if (ChangeIdx < 0) or (ChangeIdx > High(FChanges)) then
      Continue;
    Code := FChanges[ChangeIdx].Code;
    if (Code = '??') or (Pos('A', Code) > 0) then
      VerbIdx := 0
    else if Pos('D', Code) > 0 then
      VerbIdx := 2
    else if (Pos('R', Code) > 0) or (FChanges[ChangeIdx].OrigPath <> '') then
      VerbIdx := 3
    else
      VerbIdx := 1;
    FileName := ExtractFileName(StringReplace(
      string(FChanges[ChangeIdx].Path), '/', '\', [rfReplaceAll]));
    Inc(Counts[VerbIdx]);
    if Names[VerbIdx] <> '' then
      Names[VerbIdx] := Names[VerbIdx] + ', ';
    Names[VerbIdx] := Names[VerbIdx] + FileName;
  end;
  UsedVerbs := 0;
  LastVerb := -1;
  for VerbIdx := 0 to VerbCount - 1 do
    if Counts[VerbIdx] > 0 then
    begin
      Inc(UsedVerbs);
      LastVerb := VerbIdx;
    end;
  NewSummary := '';
  if UsedVerbs = 1 then
  begin
    if Length(Names[LastVerb]) <= MaxNamesLen then
      NewSummary := Verbs[LastVerb] + ' ' + Names[LastVerb]
    else
      NewSummary := Verbs[LastVerb] + ' ' + IntToStr(Counts[LastVerb]) +
        ' files';
  end
  else if UsedVerbs > 1 then
    for VerbIdx := 0 to VerbCount - 1 do
      if Counts[VerbIdx] > 0 then
      begin
        if Counts[VerbIdx] = 1 then
          Part := Verbs[VerbIdx] + ' ' + Names[VerbIdx]
        else
          Part := Verbs[VerbIdx] + ' ' + IntToStr(Counts[VerbIdx]) + ' files';
        if NewSummary <> '' then
          NewSummary := NewSummary + ', ' + LowerCase(Copy(Part, 1, 1)) +
            Copy(Part, 2, MaxInt)
        else
          NewSummary := Part;
      end;
  FAutoSummary := NewSummary;
  FSummary.Text := NewSummary;
end;

// Флажок вида: отметить (или снять) все строки этого вида
procedure TDlgGitCommit.KindCheckClick(Sender: TObject);
var
  ItemIdx, ChangeIdx, KindIdx: Integer;
  NewState: Boolean;
begin
  if FKindUpdating or not (Sender is TUiCheckBox) then
    Exit;
  KindIdx := TUiCheckBox(Sender).Tag;
  NewState := TUiCheckBox(Sender).State = cbChecked;
  FFilling := True;
  try
    for ItemIdx := 0 to FList.Items.Count - 1 do
    begin
      ChangeIdx := Integer(FList.Items[ItemIdx].Data);
      if (ChangeIdx >= 0) and (ChangeIdx <= High(FChanges)) and
         (GitFileKind(FChanges[ChangeIdx].Path) = KindIdx) then
        FList.Items[ItemIdx].Checked := NewState;
    end;
  finally
    FFilling := False;
  end;
  UpdateCount;
end;

// Флажки видов - в строку, не влезают - со следующей строки; высота
// панели - по числу строк
procedure TDlgGitCommit.LayoutKinds(Sender: TObject);
const
  RowHeight = 22;
var
  KindIdx, NextLeft, NextTop, CheckWidth: Integer;
begin
  if FKindLaying or (FKindPanel = nil) then
    Exit;
  FKindLaying := True;
  try
    NextLeft := 2;
    NextTop := 2;
    for KindIdx := 0 to gfkCount - 1 do
    begin
      if not FKindChecks[KindIdx].Visible then
        Continue;
      Canvas.Font.Assign(FKindChecks[KindIdx].Font);
      CheckWidth := Canvas.TextWidth(FKindChecks[KindIdx].Caption) + 26;
      if (NextLeft > 2) and (NextLeft + CheckWidth > FKindPanel.ClientWidth) then
      begin
        NextLeft := 2;
        Inc(NextTop, RowHeight);
      end;
      FKindChecks[KindIdx].SetBounds(NextLeft, NextTop, CheckWidth, 20);
      Inc(NextLeft, CheckWidth + 6);
    end;
    FKindPanel.Height := NextTop + RowHeight + 2;
  finally
    FKindLaying := False;
  end;
end;

procedure TDlgGitCommit.ListSelect(Sender: TObject; Item: TListItem;
  Selected: Boolean);
var
  ChangeIdx: Integer;
begin
  if FFilling or not Selected or (Item = nil) or not Assigned(FOnDiff) then
    Exit;
  ChangeIdx := Integer(Item.Data);
  if (ChangeIdx < 0) or (ChangeIdx > High(FChanges)) then
    Exit;
  Screen.Cursor := crHourGlass;
  try
    FDiff.ShowDiff(string(FOnDiff(FChanges[ChangeIdx])));
  finally
    Screen.Cursor := crDefault;
  end;
end;

// Флажок строки поменялся (щелчок, пробел) - пересчёт
procedure TDlgGitCommit.ListChange(Sender: TObject; Item: TListItem;
  Change: TItemChange);
begin
  if not FFilling and (Change = ctState) then
    UpdateCount;
end;

procedure TDlgGitCommit.ChkAllClick(Sender: TObject);
var
  ItemIdx: Integer;
begin
  if FKindUpdating then
    Exit;
  FFilling := True;
  try
    for ItemIdx := 0 to FList.Items.Count - 1 do
      FList.Items[ItemIdx].Checked := FChkAll.Checked;
  finally
    FFilling := False;
  end;
  UpdateCount;
end;

// Discard Selected: выделенные строки - в OnDiscard; вышло - убрать их
procedure TDlgGitCommit.BtnDiscardClick(Sender: TObject);
var
  ItemIdx: Integer;
  Picked: TGitChanges;
begin
  if not Assigned(FOnDiscard) then
    Exit;
  if SelectedChanges(Picked) = 0 then
  begin
    MessageBox(Handle, 'Выделите строки (щелчок, Ctrl+щелчок, Shift+щелчок) ' +
      '- изменения каких файлов отменить.'#13#10#13#10'Флажки - это что ' +
      'войдёт в коммит; Discard работает только с выделенными строками, ' +
      'чтобы не отменить лишнего.', 'Discard', MB_OK or
      MB_ICONINFORMATION);
    Exit;
  end;
  if not FOnDiscard(Picked) then
    Exit;
  if Assigned(FOnStatus) then
  begin
    Reload;
    Exit;
  end;
  FFilling := True;
  try
    for ItemIdx := FList.Items.Count - 1 downto 0 do
      if FList.Items[ItemIdx].Selected then
        FList.Items[ItemIdx].Delete;
  finally
    FFilling := False;
  end;
  FDiff.ShowDiff('');
  UpdateCount;
  if FList.Items.Count = 0 then
    ModalResult := mrCancel;
end;

function TDlgGitCommit.TryClose: Boolean;
var
  ItemIdx: Integer;
  AnyChecked: Boolean;
begin
  Result := False;
  AnyChecked := False;
  for ItemIdx := 0 to FList.Items.Count - 1 do
    if FList.Items[ItemIdx].Checked then
      AnyChecked := True;
  if not AnyChecked then
  begin
    MessageBox(Handle, 'Не отмечено ни одного файла.', 'Commit',
      MB_OK or MB_ICONINFORMATION);
    Exit;
  end;
  if Trim(FSummary.Text) = '' then
  begin
    MessageBox(Handle, 'Нужен заголовок коммита (Summary).', 'Commit',
      MB_OK or MB_ICONINFORMATION);
    if FSummary.CanFocus then
      FSummary.SetFocus;
    Exit;
  end;
  Result := True;
end;

procedure TDlgGitCommit.BtnCommitClick(Sender: TObject);
begin
  if not TryClose then
    Exit;
  FPushAfter := False;
  ModalResult := mrOk;
end;

procedure TDlgGitCommit.BtnPushClick(Sender: TObject);
begin
  if not TryClose then
    Exit;
  FPushAfter := True;
  ModalResult := mrOk;
end;

procedure TDlgGitCommit.CheckedChanges(var AList: TGitChanges);
var
  ItemIdx, ChangeIdx, Count: Integer;
begin
  SetLength(AList, 0);
  Count := 0;
  for ItemIdx := 0 to FList.Items.Count - 1 do
    if FList.Items[ItemIdx].Checked then
    begin
      ChangeIdx := Integer(FList.Items[ItemIdx].Data);
      if (ChangeIdx < 0) or (ChangeIdx > High(FChanges)) then
        Continue;
      SetLength(AList, Count + 1);
      AList[Count] := FChanges[ChangeIdx];
      Inc(Count);
    end;
end;

function TDlgGitCommit.MessageText: string;
begin
  Result := Trim(FSummary.Text);
  if Trim(FDescr.Lines.Text) <> '' then
    Result := Result + #10#10 + TrimRight(FDescr.Lines.Text);
end;

end.
