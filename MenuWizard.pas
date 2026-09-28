unit MenuWizard;

// ---------------------------------------------------------------------------
//  Мастер меню конструктора форм: готовые наборы меню (текстовый редактор,
//  IDE, браузер, ...) одним действием - в форму проекта.
//
//  Шаблон - список пунктов с отступами: уровень вложенности - два пробела
//  на уровень, подпись, за "|" - сочетание клавиш как в Delphi (Ctrl+N,
//  Shift+Ctrl+S, F9, Del). "-" - разделитель. Встроенные шаблоны - в этом
//  модуле; свои лежат файлами *.mnu в папке MenuTemplates рядом с
//  программой (свой с тем же названием заменяет встроенный):
//
//    ; комментарий
//    Title=Текстовый редактор
//    Kind=Main              (Main - TMainMenu, Popup - TPopupMenu)
//    &File
//      &New|Ctrl+N
//      -
//      E&xit
//
//  Вставка (как в Delphi) - только пункты: имена по подписям (New1,
//  Open1, N1 у разделителя), без обработчиков - их создаёт двойной щелчок.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, StdCtrls,
  CheckLst, Menus;

type
  // Пункт шаблона
  TMenuTplItem = class
  public
    Level: Integer;         // 0 - меню верхнего уровня
    Caption: string;        // '-' - разделитель
    ShortCutText: string;   // 'Ctrl+N'; '' - нет
    Checked: Boolean;       // оставлен в мастере
    // Только у меню формы (Редактировать): имя пункта в .dfm и его подпись
    // и клавиша, как они в .dfm сейчас
    ItemName: string;
    OrigCaption, OrigShortCut: string;
  end;

  TMenuTemplate = class
  public
    Title: string;
    IsPopup: Boolean;
    FileName: string;       // '' - встроенный
    MenuName: string;       // не '' - это меню формы с таким именем
    Items: TList;           // TMenuTplItem по порядку
    constructor Create;
    destructor Destroy; override;
  end;

  // Свободно ли имя в форме (нет такого объекта в .dfm и слова в .pas)
  TMenuNameFree = function(const AName: string): Boolean of object;

  // Что выбрано в мастере
  TMenuWizardChoice = record
    Template: TMenuTemplate;   // пункты с Checked - вставить
    IsPopup: Boolean;
    Name: string;              // имя компонента меню
    AssignToForm: Boolean;     // Menu формы = это меню
    ShortCuts: Boolean;        // писать ShortCut у пунктов
    Themed: Boolean;           // свои компоненты: TUiMainMenu, TUiPopupMenu
  end;

// Папка своих шаблонов рядом с программой
function MenuTemplateDir: string;

// Все шаблоны: встроенные и свои из ADir (*.mnu)
procedure MenuLoadTemplates(const ADir: string; AList: TList);
procedure MenuFreeTemplates(AList: TList);

type
  // Вставить выбранный набор в форму сейчас; False - не вставился
  TMenuWizardAdd = function(const AChoice: TMenuWizardChoice): Boolean
    of object;
  // Откатить одну вставку (шаг отката конструктора)
  TMenuWizardUndo = procedure of object;
  // Есть ли в форме главное меню (TMainMenu) сейчас
  TMenuWizardHasMain = function: Boolean of object;

  // Правки меню формы (Редактировать) - в .dfm; False - не применились
  TMenuWizardApply = function(ATemplate: TMenuTemplate): Boolean of object;
  // Меню формы - шаблонами (MenuName не пустое) в конец списка AList
  TMenuWizardExisting = procedure(AList: TList) of object;
  // Удалить меню формы целиком; False - не удалилось
  TMenuWizardDelete = function(const AMenuName: string): Boolean of object;

  // Что мастер спрашивает и делает через IDE
  TMenuWizardHost = record
    NameFree: TMenuNameFree;
    OnAdd: TMenuWizardAdd;
    OnUndo: TMenuWizardUndo;
    HasMain: TMenuWizardHasMain;
    OnApply: TMenuWizardApply;
    OnExisting: TMenuWizardExisting;
    OnDelete: TMenuWizardDelete;
    // Выбрать сразу меню формы с этим именем; EditMode и имя пустое -
    // первое меню формы
    SelectMenu: string;
    EditMode: Boolean;
  end;

// Окно мастера. Остаётся открытым: «Добавить» сразу вставляет набор - можно
// добавить ещё один. В конце списка наборов - меню самой формы («в
// форме»): их пункты можно снять, переименовать, сменить им клавишу, и
// «Применить» правит меню в форме; «Удалить» (с подтверждением) убирает
// меню формы целиком. Подпись и клавиша правятся у любого
// набора - поля под списком пунктов. Пока вставок и правок нет, вторая
// кнопка - «Выйти»; потом - «Отмена» (жирным): откатывает их все (OnUndo по
// разу на каждую), окно остаётся. Закрытие крестиком их оставляет.
// Результат - сколько вставок и правок осталось.
function MenuWizardRun(ATemplates: TList; const AHost: TMenuWizardHost): Integer;

// Меню формы из текста .dfm его объекта - шаблоном для правки: у пунктов
// имена, подписи и клавиши
function MenuTemplateFromDfmObj(const AObjText, AMenuName: string;
  AIsPopup: Boolean): TMenuTemplate;

// Текст .dfm компонента меню с выбранными пунктами. AItemNames получает
// имена пунктов (для полей в .pas).
function MenuBuildDfm(const AChoice: TMenuWizardChoice; X, Y: Integer;
  ANameFree: TMenuNameFree; AItemNames: TStrings): string;

// Шаблон из текста .dfm компонента меню (объект с вложенными TMenuItem) -
// текст файла .mnu
function MenuTemplateFromDfm(const AObjText, ATitle: string;
  AIsPopup: Boolean): string;

// Записать шаблон в папку своих шаблонов; результат - имя файла
function MenuSaveTemplate(const ATitle, AText: string): string;

// Окно «удалить свои шаблоны»: файлы *.mnu с флажками. Результат - сколько
// удалено. Встроенные наборы - в программе, их нет в списке.
function MenuDeleteTemplatesDialog: Integer;

// Выбор строки из списка (Select Menu...). -1 - не выбрали.
function MenuPickDialog(const ACaption, APrompt: string;
  AItems: TStrings): Integer;

// Первое меню (MENU / MENUEX) из текста ресурсного скрипта .rc - шаблоном.
// nil - меню в тексте нет.
function MenuTemplateFromRc(const AText, ATitle: string): TMenuTemplate;

// Текст .dfm одного пункта меню; AShortCut 0 - без клавиши
function MenuItemDfm(const AName, ACaption: string;
  AShortCut: Integer = 0): string;

// Имя нового пункта по подписи (New1, Open1, N1 у разделителя): свободное
// в форме (ANameFree) и не из AUsed; добавляется в AUsed
function MenuNewItemName(const ACaption: string; ANameFree: TMenuNameFree;
  AUsed: TStrings): string;

// Класс компонента меню в .dfm: главное меню (TMainMenu, TUiMainMenu),
// всплывающее (TPopupMenu, TUiPopupMenu)
function MenuIsMainClass(const AClassName: string): Boolean;
function MenuIsPopupClass(const AClassName: string): Boolean;

// Строка для .dfm: в кавычках, кавычка удвоена
function MenuDfmQuote(const S: string): string;

// Вставить объект AObjText перед объектом AName, тем же родителем. Нет
// такого объекта - AText.
function MenuDfmInsertBefore(const AText, AName, AObjText: string): string;

implementation

uses
  Dialogs, FormDesigner, UiStdCtrls, UiEditCtrls, UiButton, UiTheme,
  UiDialogs;      // последним: его ShowMessage - окно по теме

// ---------------------------------------------------------------------------
//  Встроенные шаблоны
// ---------------------------------------------------------------------------

const
  BuiltIn: array[0..9] of string = (
    // Текстовый редактор
    'Title=Text editor'#13'Kind=Main'#13 +
    '&File'#13'  &New|Ctrl+N'#13'  &Open...|Ctrl+O'#13'  &Save|Ctrl+S'#13 +
    '  Save &As...'#13'  -'#13'  &Print...|Ctrl+P'#13'  Print Set&up...'#13 +
    '  -'#13'  E&xit'#13 +
    '&Edit'#13'  &Undo|Ctrl+Z'#13'  &Redo|Ctrl+Y'#13'  -'#13 +
    '  Cu&t|Ctrl+X'#13'  &Copy|Ctrl+C'#13'  &Paste|Ctrl+V'#13 +
    '  &Delete|Del'#13'  -'#13'  Select &All|Ctrl+A'#13 +
    '&Search'#13'  &Find...|Ctrl+F'#13'  Find &Next|F3'#13 +
    '  &Replace...|Ctrl+H'#13'  -'#13'  &Go to Line...|Ctrl+G'#13 +
    'F&ormat'#13'  &Word Wrap'#13'  &Font...'#13 +
    '&View'#13'  &Toolbar'#13'  &Status Bar'#13 +
    '&Help'#13'  &Contents|F1'#13'  -'#13'  &About...',

    // IDE
    'Title=IDE'#13'Kind=Main'#13 +
    '&File'#13'  &New'#13'  &Open...|Ctrl+O'#13'  &Reopen'#13 +
    '  &Save|Ctrl+S'#13'  Save &As...'#13'  Save A&ll|Shift+Ctrl+S'#13 +
    '  &Close'#13'  -'#13'  E&xit'#13 +
    '&Edit'#13'  &Undo|Ctrl+Z'#13'  &Redo|Shift+Ctrl+Z'#13'  -'#13 +
    '  Cu&t|Ctrl+X'#13'  &Copy|Ctrl+C'#13'  &Paste|Ctrl+V'#13 +
    '  &Delete|Del'#13'  -'#13'  Select &All|Ctrl+A'#13 +
    '&Search'#13'  &Find...|Ctrl+F'#13'  Find in F&iles...|Shift+Ctrl+F'#13 +
    '  &Replace...|Ctrl+R'#13'  &Search Again|F3'#13'  -'#13 +
    '  &Go to Line...|Alt+G'#13 +
    '&View'#13'  &Project Manager'#13'  &Object Inspector|F11'#13 +
    '  -'#13'  &Toolbars'#13'  &Messages'#13 +
    '&Project'#13'  &Add to Project...'#13'  &Remove from Project...'#13 +
    '  -'#13'  &Compile|Ctrl+F9'#13'  &Build'#13'  -'#13 +
    '  &Options...|Shift+Ctrl+F11'#13 +
    '&Run'#13'  &Run|F9'#13'  Step &Over|F8'#13'  &Trace Into|F7'#13 +
    '  -'#13'  Program &Pause'#13'  Program R&eset|Ctrl+F2'#13'  -'#13 +
    '  Toggle &Breakpoint|F5'#13 +
    '&Tools'#13'  &Environment Options...'#13'  E&ditor Options...'#13 +
    '&Window'#13'  &Next Window'#13'  &Previous Window'#13 +
    '  &Close All'#13 +
    '&Help'#13'  &Contents|F1'#13'  -'#13'  &About...',

    // Браузер
    'Title=Browser'#13'Kind=Main'#13 +
    '&File'#13'  New &Tab|Ctrl+T'#13'  &New Window|Ctrl+N'#13 +
    '  &Open...|Ctrl+O'#13'  -'#13'  Save Page &As...|Ctrl+S'#13 +
    '  &Print...|Ctrl+P'#13'  -'#13'  &Close Tab|Ctrl+W'#13'  E&xit'#13 +
    '&Edit'#13'  &Undo|Ctrl+Z'#13'  -'#13'  Cu&t|Ctrl+X'#13 +
    '  &Copy|Ctrl+C'#13'  &Paste|Ctrl+V'#13'  -'#13 +
    '  Select &All|Ctrl+A'#13'  -'#13'  &Find...|Ctrl+F'#13 +
    '&View'#13'  &Toolbar'#13'  &Status Bar'#13'  -'#13'  Zoom &In'#13 +
    '  Zoom &Out'#13'  &Reset Zoom'#13'  -'#13'  Re&load|F5'#13 +
    '  &Stop|Esc'#13'  &Full Screen|F11'#13'  Page So&urce|Ctrl+U'#13 +
    '&History'#13'  &Back|Alt+Left'#13'  &Forward|Alt+Right'#13 +
    '  &Home|Alt+Home'#13'  -'#13'  Show All &History|Ctrl+H'#13 +
    '&Bookmarks'#13'  &Bookmark This Page|Ctrl+D'#13 +
    '  &Show All Bookmarks'#13'  -'#13'  Bookmarks &Toolbar'#13 +
    '&Tools'#13'  &Downloads|Ctrl+J'#13'  -'#13'  &Options...'#13 +
    '&Help'#13'  &Help|F1'#13'  -'#13'  &About...',

    // Просмотр изображений
    'Title=Image viewer'#13'Kind=Main'#13 +
    '&File'#13'  &Open...|Ctrl+O'#13'  Save &As...|Ctrl+S'#13'  -'#13 +
    '  &Print...|Ctrl+P'#13'  -'#13'  E&xit'#13 +
    '&Edit'#13'  &Undo|Ctrl+Z'#13'  -'#13'  &Copy|Ctrl+C'#13 +
    '  &Paste|Ctrl+V'#13'  -'#13'  Rotate &Left'#13'  Rotate &Right'#13 +
    '  Flip &Horizontal'#13'  Flip &Vertical'#13 +
    '&View'#13'  Zoom &In'#13'  Zoom &Out'#13'  &Actual Size'#13 +
    '  &Fit to Window'#13'  -'#13'  F&ull Screen|F11'#13'  -'#13 +
    '  &Next Image'#13'  &Previous Image'#13 +
    '&Image'#13'  &Resize...'#13'  &Crop'#13'  -'#13 +
    '  &Properties...'#13 +
    '&Help'#13'  &About...',

    // Табличные данные
    'Title=Data / spreadsheet'#13'Kind=Main'#13 +
    '&File'#13'  &New|Ctrl+N'#13'  &Open...|Ctrl+O'#13'  &Save|Ctrl+S'#13 +
    '  Save &As...'#13'  -'#13'  &Import...'#13'  &Export...'#13'  -'#13 +
    '  &Print...|Ctrl+P'#13'  -'#13'  E&xit'#13 +
    '&Edit'#13'  &Undo|Ctrl+Z'#13'  &Redo|Ctrl+Y'#13'  -'#13 +
    '  Cu&t|Ctrl+X'#13'  &Copy|Ctrl+C'#13'  &Paste|Ctrl+V'#13 +
    '  &Delete|Del'#13'  -'#13'  &Find...|Ctrl+F'#13'  R&eplace...|Ctrl+H'#13 +
    '&View'#13'  &Toolbar'#13'  &Status Bar'#13'  &Grid Lines'#13 +
    '&Insert'#13'  &Row'#13'  &Column'#13'  -'#13'  C&hart...'#13 +
    'F&ormat'#13'  &Cells...'#13'  &Row Height...'#13'  C&olumn Width...'#13 +
    '&Data'#13'  &Sort...'#13'  &Filter'#13'  -'#13'  &Refresh|F5'#13 +
    '&Window'#13'  &Cascade'#13'  &Tile'#13'  &Arrange Icons'#13 +
    '&Help'#13'  &Contents|F1'#13'  -'#13'  &About...',

    // Проигрыватель
    'Title=Media player'#13'Kind=Main'#13 +
    '&File'#13'  &Open File...|Ctrl+O'#13'  Open &Folder...'#13'  -'#13 +
    '  E&xit'#13 +
    '&Play'#13'  &Play/Pause'#13'  &Stop'#13'  -'#13'  &Next'#13 +
    '  P&revious'#13'  -'#13'  Re&peat'#13'  S&huffle'#13 +
    '&View'#13'  &Playlist'#13'  &Equalizer'#13'  -'#13 +
    '  &Full Screen|F11'#13 +
    '&Help'#13'  &About...',

    // Минимальный
    'Title=Minimal (File, Help)'#13'Kind=Main'#13 +
    '&File'#13'  E&xit'#13 +
    '&Help'#13'  &About...',

    // Всплывающие
    'Title=Popup: text editing'#13'Kind=Popup'#13 +
    '&Undo|Ctrl+Z'#13'-'#13'Cu&t|Ctrl+X'#13'&Copy|Ctrl+C'#13 +
    '&Paste|Ctrl+V'#13'&Delete|Del'#13'-'#13'Select &All|Ctrl+A',

    'Title=Popup: tray icon'#13'Kind=Popup'#13 +
    '&Show'#13'&Settings...'#13'-'#13'E&xit',

    'Title=Popup: list'#13'Kind=Popup'#13 +
    '&Add...|Ins'#13'&Edit...'#13'&Delete|Del'#13'-'#13'&Refresh|F5'
  );

// ---------------------------------------------------------------------------
//  Шаблоны: разбор, загрузка
// ---------------------------------------------------------------------------

constructor TMenuTemplate.Create;
begin
  inherited Create;
  Items := TList.Create;
end;

destructor TMenuTemplate.Destroy;
var
  Index: Integer;
begin
  for Index := 0 to Items.Count - 1 do
    TMenuTplItem(Items[Index]).Free;
  Items.Free;
  inherited Destroy;
end;

function MenuTemplateDir: string;
begin
  Result := ExtractFilePath(Application.ExeName) + 'MenuTemplates';
end;

// Текст шаблона - в шаблон. nil - пунктов нет.
function ParseTemplate(const AText, AFileName: string): TMenuTemplate;
var
  Lines: TStringList;
  Index, Spaces, Bar: Integer;
  Line, Body: string;
  Item: TMenuTplItem;
begin
  Result := TMenuTemplate.Create;
  Result.FileName := AFileName;
  Lines := TStringList.Create;
  try
    Lines.Text := AText;
    for Index := 0 to Lines.Count - 1 do
    begin
      Line := TrimRight(Lines[Index]);
      Body := Trim(Line);
      if (Body = '') or (Body[1] = ';') then
        Continue;
      if (Result.Items.Count = 0) and
         (CompareText(Copy(Body, 1, 6), 'Title=') = 0) then
      begin
        Result.Title := Trim(Copy(Body, 7, MaxInt));
        Continue;
      end;
      if (Result.Items.Count = 0) and
         (CompareText(Copy(Body, 1, 5), 'Kind=') = 0) then
      begin
        Result.IsPopup := CompareText(Trim(Copy(Body, 6, MaxInt)),
                                      'Popup') = 0;
        Continue;
      end;
      Spaces := 0;
      while (Spaces < Length(Line)) and (Line[Spaces + 1] = ' ') do
        Inc(Spaces);
      Item := TMenuTplItem.Create;
      Item.Level := Spaces div 2;
      Item.Checked := True;
      Bar := LastDelimiter('|', Body);
      if Bar > 0 then
      begin
        Item.Caption := Trim(Copy(Body, 1, Bar - 1));
        Item.ShortCutText := Trim(Copy(Body, Bar + 1, MaxInt));
      end
      else
        Item.Caption := Body;
      Result.Items.Add(Item);
    end;
  finally
    Lines.Free;
  end;
  if Result.Title = '' then
    Result.Title := ChangeFileExt(ExtractFileName(AFileName), '');
  if Result.Items.Count = 0 then
    FreeAndNil(Result);
end;

procedure MenuLoadTemplates(const ADir: string; AList: TList);
var
  Index, Existing: Integer;
  Tpl: TMenuTemplate;
  Found: TSearchRec;
  FileText: TStringList;

  function IndexOfTitle(const ATitle: string): Integer;
  var
    TplPos: Integer;
  begin
    Result := -1;
    for TplPos := 0 to AList.Count - 1 do
      if CompareText(TMenuTemplate(AList[TplPos]).Title, ATitle) = 0 then
      begin
        Result := TplPos;
        Exit;
      end;
  end;

begin
  for Index := Low(BuiltIn) to High(BuiltIn) do
  begin
    Tpl := ParseTemplate(StringReplace(BuiltIn[Index], #13, #13#10,
                                       [rfReplaceAll]), '');
    if Tpl <> nil then
      AList.Add(Tpl);
  end;
  if FindFirst(IncludeTrailingPathDelimiter(ADir) + '*.mnu', faAnyFile,
               Found) = 0 then
  try
    repeat
      FileText := TStringList.Create;
      try
        try
          FileText.LoadFromFile(IncludeTrailingPathDelimiter(ADir) +
                                Found.Name);
          Tpl := ParseTemplate(FileText.Text,
                               IncludeTrailingPathDelimiter(ADir) + Found.Name);
        except
          Tpl := nil;
        end;
      finally
        FileText.Free;
      end;
      if Tpl = nil then
        Continue;
      // Свой с тем же названием - вместо встроенного
      Existing := IndexOfTitle(Tpl.Title);
      if Existing >= 0 then
      begin
        TMenuTemplate(AList[Existing]).Free;
        AList[Existing] := Tpl;
      end
      else
        AList.Add(Tpl);
    until FindNext(Found) <> 0;
  finally
    FindClose(Found);
  end;
end;

procedure MenuFreeTemplates(AList: TList);
var
  Index: Integer;
begin
  for Index := 0 to AList.Count - 1 do
    TMenuTemplate(AList[Index]).Free;
  AList.Clear;
end;

// ---------------------------------------------------------------------------
//  Окно мастера
// ---------------------------------------------------------------------------

type
  TMenuWizardForm = class(TForm)
  private
    FTemplates: TList;
    FHost: TMenuWizardHost;
    FDefaultName: string;       // имя, которое мастер предложил сам
    FAdded: Integer;            // вставок и правок, ещё не отменённых
    FLoading: Boolean;          // поля пункта заполняет сам мастер
    lstTemplates: TUiListBox;
    lstItems: TCheckListBox;
    edCaption, edShortCut: TUiEdit;
    rbMain, rbPopup: TUiRadioButton;
    edName: TUiEdit;
    chkAssign, chkShortCuts, chkThemed: TUiCheckBox;
    lblReplace: TUiLabel;
    BtnAdd, BtnClose, BtnDelete: TUiButton;
    BtnItemIns, BtnItemSub, BtnItemDel: TUiButton;
    function Current: TMenuTemplate;
    function CurrentItem: TMenuTplItem;
    function ItemLine(AItem: TMenuTplItem): string;
    procedure ShowItems;
    procedure SuggestName;
    procedure UpdateAddButton;
    procedure ShowCloseButton;
    procedure RefreshExisting(const ASelectMenu: string);
    procedure TemplateClick(Sender: TObject);
    procedure ItemClick(Sender: TObject);
    procedure ItemClickCheck(Sender: TObject);
    procedure ItemEditChange(Sender: TObject);
    procedure KindClick(Sender: TObject);
    procedure AddClick(Sender: TObject);
    procedure CloseClick(Sender: TObject);
    procedure DeleteClick(Sender: TObject);
    procedure ItemInsClick(Sender: TObject);
    procedure ItemDelClick(Sender: TObject);
    procedure InsertItemAt(AIndex, ALevel: Integer);
  public
    constructor CreateWizard(ATemplates: TList; const AHost: TMenuWizardHost);
  end;

constructor TMenuWizardForm.CreateWizard(ATemplates: TList;
  const AHost: TMenuWizardHost);
var
  Lbl: TUiLabel;
begin
  inherited CreateNew(Application);
  FTemplates := ATemplates;
  FHost := AHost;
  Caption := 'Мастер меню';
  BorderStyle := bsDialog;
  Position := poScreenCenter;
  if Application.MainForm <> nil then
    Font := Application.MainForm.Font;
  Color := UiThemeColor('Window.BG');
  Font.Color := UiThemeColor('Window.Text');
  ClientWidth := 600;
  ClientHeight := 440;

  Lbl := TUiLabel.Create(Self);
  Lbl.Parent := Self;
  Lbl.Caption := 'Набор меню:';
  Lbl.SetBounds(12, 10, 200, 15);

  lstTemplates := TUiListBox.Create(Self);
  lstTemplates.Parent := Self;
  lstTemplates.SetBounds(12, 28, 200, 300);
  lstTemplates.OnClick := TemplateClick;

  Lbl := TUiLabel.Create(Self);
  Lbl.Parent := Self;
  Lbl.Caption := 'Пункты (снимите ненужные):';
  Lbl.SetBounds(224, 10, 300, 15);

  lstItems := TCheckListBox.Create(Self);
  lstItems.Parent := Self;
  lstItems.SetBounds(224, 28, 364, 248);
  lstItems.OnClick := ItemClick;
  lstItems.OnClickCheck := ItemClickCheck;

  // Подпись и клавиша выбранного пункта - правятся прямо здесь
  Lbl := TUiLabel.Create(Self);
  Lbl.Parent := Self;
  Lbl.Caption := 'Подпись:';
  Lbl.SetBounds(224, 289, 56, 15);

  edCaption := TUiEdit.Create(Self);
  edCaption.Parent := Self;
  edCaption.SetBounds(282, 286, 160, 21);
  edCaption.OnChange := ItemEditChange;

  Lbl := TUiLabel.Create(Self);
  Lbl.Parent := Self;
  Lbl.Caption := 'Клавиша:';
  Lbl.SetBounds(450, 289, 50, 15);

  edShortCut := TUiEdit.Create(Self);
  edShortCut.Parent := Self;
  edShortCut.SetBounds(502, 286, 86, 21);
  edShortCut.ShowHint := True;
  edShortCut.Hint := 'Как в Delphi: Ctrl+N, Shift+Ctrl+S, F9, Del. ' +
                     'Пусто - без клавиши';
  edShortCut.OnChange := ItemEditChange;

  rbMain := TUiRadioButton.Create(Self);
  rbMain.Parent := Self;
  rbMain.Caption := 'TMainMenu';
  rbMain.SetBounds(12, 340, 100, 17);
  rbMain.OnClick := KindClick;

  rbPopup := TUiRadioButton.Create(Self);
  rbPopup.Parent := Self;
  rbPopup.Caption := 'TPopupMenu';
  rbPopup.SetBounds(120, 340, 100, 17);
  rbPopup.OnClick := KindClick;

  Lbl := TUiLabel.Create(Self);
  Lbl.Parent := Self;
  Lbl.Caption := 'Имя:';
  Lbl.SetBounds(236, 341, 40, 15);

  edName := TUiEdit.Create(Self);
  edName.Parent := Self;
  edName.SetBounds(276, 338, 160, 21);

  chkAssign := TUiCheckBox.Create(Self);
  chkAssign.Parent := Self;
  chkAssign.Caption := 'Назначить форме (свойство Menu)';
  chkAssign.Checked := True;
  chkAssign.SetBounds(12, 368, 260, 17);

  // Главное меню у формы одно - вставка TMainMenu заменяет прежнее
  lblReplace := TUiLabel.Create(Self);
  lblReplace.Parent := Self;
  lblReplace.Caption := 'Главное меню формы будет заменено ' +
                        '(у формы оно одно).';
  lblReplace.SetBounds(12, 406, 280, 30);
  lblReplace.WordWrap := True;

  chkShortCuts := TUiCheckBox.Create(Self);
  chkShortCuts.Parent := Self;
  chkShortCuts.Caption := 'Сочетания клавиш (ShortCut)';
  chkShortCuts.Checked := True;
  chkShortCuts.SetBounds(280, 368, 260, 17);

  // Свои компоненты (TUiMainMenu, TUiPopupMenu): меню по теме программы
  chkThemed := TUiCheckBox.Create(Self);
  chkThemed.Parent := Self;
  chkThemed.Caption := 'Свои (по теме)';
  chkThemed.Checked := True;
  chkThemed.ShowHint := True;
  chkThemed.Hint := 'TUiMainMenu / TUiPopupMenu вместо TMainMenu / ' +
                    'TPopupMenu: меню рисуется по теме программы (UiTheme)';
  chkThemed.SetBounds(446, 340, 142, 17);

  // Пункты: новый перед выбранным, новый в подменю выбранного, убрать
  BtnItemIns := TUiButton.Create(Self);
  BtnItemIns.Parent := Self;
  BtnItemIns.Caption := 'Пункт перед';
  BtnItemIns.ShowHint := True;
  BtnItemIns.Hint := 'Новый пункт перед выбранным (Insert)';
  BtnItemIns.SetBounds(224, 311, 100, 22);
  BtnItemIns.OnClick := ItemInsClick;

  BtnItemSub := TUiButton.Create(Self);
  BtnItemSub.Parent := Self;
  BtnItemSub.Caption := 'Подменю';
  BtnItemSub.ShowHint := True;
  BtnItemSub.Hint := 'Новый пункт в подменю выбранного (Create Submenu)';
  BtnItemSub.SetBounds(330, 311, 90, 22);
  BtnItemSub.OnClick := ItemInsClick;

  BtnItemDel := TUiButton.Create(Self);
  BtnItemDel.Parent := Self;
  BtnItemDel.Caption := 'Удалить пункт';
  BtnItemDel.ShowHint := True;
  BtnItemDel.Hint := 'Убрать выбранный пункт с его подменю (Delete)';
  BtnItemDel.SetBounds(426, 311, 100, 22);
  BtnItemDel.OnClick := ItemDelClick;

  BtnClose := TUiButton.Create(Self);
  BtnClose.Parent := Self;
  BtnClose.Cancel := True;
  BtnClose.SetBounds(ClientWidth - 12 - 90, 400, 90, 25);
  BtnClose.OnClick := CloseClick;

  BtnAdd := TUiButton.Create(Self);
  BtnAdd.Parent := Self;
  BtnAdd.Default := True;
  BtnAdd.SetBounds(BtnClose.Left - 8 - 90, 400, 90, 25);
  BtnAdd.OnClick := AddClick;

  // Меню формы - убрать целиком (только для меню «в форме»)
  BtnDelete := TUiButton.Create(Self);
  BtnDelete.Parent := Self;
  BtnDelete.Caption := 'Удалить';
  BtnDelete.ShowHint := True;
  BtnDelete.Hint := 'Убрать это меню из формы целиком: все пункты, их поля ' +
                    'в .pas и ссылку Menu у формы';
  BtnDelete.SetBounds(BtnAdd.Left - 8 - 90, 400, 90, 25);
  BtnDelete.OnClick := DeleteClick;

  ShowCloseButton;
end;

function TMenuWizardForm.Current: TMenuTemplate;
begin
  Result := nil;
  if (lstTemplates.ItemIndex >= 0) and
     (lstTemplates.ItemIndex < FTemplates.Count) then
    Result := TMenuTemplate(FTemplates[lstTemplates.ItemIndex]);
end;

function TMenuWizardForm.CurrentItem: TMenuTplItem;
var
  Tpl: TMenuTemplate;
begin
  Result := nil;
  Tpl := Current;
  if (Tpl <> nil) and (lstItems.ItemIndex >= 0) and
     (lstItems.ItemIndex < Tpl.Items.Count) then
    Result := TMenuTplItem(Tpl.Items[lstItems.ItemIndex]);
end;

// Строка пункта в списке: отступ по уровню, подпись без &, клавиша
function TMenuWizardForm.ItemLine(AItem: TMenuTplItem): string;
begin
  if AItem.Caption = '-' then
    Result := '----------'
  else
    Result := StringReplace(AItem.Caption, '&', '', [rfReplaceAll]);
  if AItem.ShortCutText <> '' then
    Result := Result + '     ' + AItem.ShortCutText;
  Result := StringOfChar(' ', AItem.Level * 6) + Result;
end;

procedure TMenuWizardForm.ShowItems;
var
  Tpl: TMenuTemplate;
  Index: Integer;
begin
  lstItems.Items.Clear;
  Tpl := Current;
  if Tpl <> nil then
    for Index := 0 to Tpl.Items.Count - 1 do
    begin
      lstItems.Items.Add(ItemLine(TMenuTplItem(Tpl.Items[Index])));
      lstItems.Checked[Index] := TMenuTplItem(Tpl.Items[Index]).Checked;
    end;
  if lstItems.Items.Count > 0 then
    lstItems.ItemIndex := 0;
  ItemClick(nil);
end;

// Выбрали пункт - его подпись и клавиша в поля
procedure TMenuWizardForm.ItemClick(Sender: TObject);
var
  Item: TMenuTplItem;
begin
  Item := CurrentItem;
  FLoading := True;
  try
    edCaption.Enabled := Item <> nil;
    edShortCut.Enabled := Item <> nil;
    if Item <> nil then
    begin
      edCaption.Text := Item.Caption;
      edShortCut.Text := Item.ShortCutText;
    end
    else
    begin
      edCaption.Text := '';
      edShortCut.Text := '';
    end;
  finally
    FLoading := False;
  end;
end;

// Поле подписи или клавиши поменяли - в пункт и в строку списка
procedure TMenuWizardForm.ItemEditChange(Sender: TObject);
var
  Item: TMenuTplItem;
  Index: Integer;
  WasChecked: Boolean;
begin
  if FLoading then
    Exit;
  Item := CurrentItem;
  if Item = nil then
    Exit;
  Item.Caption := edCaption.Text;
  Item.ShortCutText := Trim(edShortCut.Text);
  Index := lstItems.ItemIndex;
  WasChecked := lstItems.Checked[Index];
  lstItems.Items[Index] := ItemLine(Item);
  lstItems.Checked[Index] := WasChecked;
  lstItems.ItemIndex := Index;
end;

// Имя по виду меню: MainMenu1 / PopupMenu1 - первое свободное. Своё имя,
// введённое руками, не трогаем.
procedure TMenuWizardForm.SuggestName;
var
  Base, CandName: string;
  Number: Integer;
begin
  if (edName.Text <> '') and (edName.Text <> FDefaultName) then
    Exit;
  if rbPopup.Checked then
    Base := 'PopupMenu'
  else
    Base := 'MainMenu';
  Number := 1;
  repeat
    CandName := Base + IntToStr(Number);
    Inc(Number);
  until not Assigned(FHost.NameFree) or FHost.NameFree(CandName);
  FDefaultName := CandName;
  edName.Text := CandName;
end;

// «Применить» - меню формы; «Заменить» - вставляется TMainMenu, а главное
// меню в форме уже есть; иначе «Добавить»
procedure TMenuWizardForm.UpdateAddButton;
var
  Tpl: TMenuTemplate;
  Replace: Boolean;
begin
  Tpl := Current;
  BtnDelete.Enabled := (Tpl <> nil) and (Tpl.MenuName <> '') and
                       Assigned(FHost.OnDelete);
  if (Tpl <> nil) and (Tpl.MenuName <> '') then
  begin
    BtnAdd.Caption := 'Применить';
    lblReplace.Visible := False;
    Exit;
  end;
  Replace := rbMain.Checked and Assigned(FHost.HasMain) and FHost.HasMain;
  if Replace then
    BtnAdd.Caption := 'Заменить'
  else
    BtnAdd.Caption := 'Добавить';
  lblReplace.Visible := Replace;
end;

procedure TMenuWizardForm.ShowCloseButton;
begin
  if FAdded > 0 then
  begin
    BtnClose.Caption := 'Отмена';
    BtnClose.Font.Style := [fsBold];
    BtnClose.TextColor := $000060FF;
    BtnClose.Hint := 'Откатить вставки и правки, сделанные в этом окне';
    BtnClose.ShowHint := True;
  end
  else
  begin
    BtnClose.Caption := 'Выйти';
    BtnClose.Font.Style := [];
    BtnClose.TextColor := clNone;
    BtnClose.ShowHint := False;
  end;
end;

// Меню формы в конце списка - заново, по форме сейчас: после вставки,
// правки и отката их состав и пункты другие. Выбирается меню ASelectMenu,
// иначе то, что было выбрано.
procedure TMenuWizardForm.RefreshExisting(const ASelectMenu: string);
var
  Index, Pick: Integer;
  WasTitle, WasMenu: string;
  Tpl: TMenuTemplate;
begin
  WasTitle := '';
  WasMenu := ASelectMenu;
  if Current <> nil then
  begin
    WasTitle := Current.Title;
    if WasMenu = '' then
      WasMenu := Current.MenuName;
  end;
  for Index := FTemplates.Count - 1 downto 0 do
    if TMenuTemplate(FTemplates[Index]).MenuName <> '' then
    begin
      TMenuTemplate(FTemplates[Index]).Free;
      FTemplates.Delete(Index);
    end;
  if Assigned(FHost.OnExisting) then
    FHost.OnExisting(FTemplates);

  lstTemplates.Items.Clear;
  Pick := -1;
  for Index := 0 to FTemplates.Count - 1 do
  begin
    Tpl := TMenuTemplate(FTemplates[Index]);
    lstTemplates.Items.Add(Tpl.Title);
    if (Pick < 0) and (WasMenu <> '') and
       (CompareText(Tpl.MenuName, WasMenu) = 0) then
      Pick := Index;
  end;
  if (Pick < 0) and (WasTitle <> '') then
    Pick := lstTemplates.Items.IndexOf(WasTitle);
  if (Pick < 0) and (lstTemplates.Items.Count > 0) then
    Pick := 0;
  lstTemplates.ItemIndex := Pick;
  TemplateClick(nil);
end;

procedure TMenuWizardForm.TemplateClick(Sender: TObject);
var
  Tpl: TMenuTemplate;
  IsMenu: Boolean;
begin
  Tpl := Current;
  if Tpl = nil then
    Exit;
  ShowItems;
  IsMenu := Tpl.MenuName <> '';
  if Tpl.IsPopup then
    rbPopup.Checked := True
  else
    rbMain.Checked := True;
  // Меню формы: вид и имя - его собственные, их не меняем
  rbMain.Enabled := not IsMenu;
  rbPopup.Enabled := not IsMenu;
  edName.Enabled := not IsMenu;
  chkThemed.Enabled := not IsMenu;
  if IsMenu then
  begin
    edName.Text := Tpl.MenuName;
    FDefaultName := Tpl.MenuName;
  end
  else if (edName.Text = FDefaultName) or not edName.Enabled then
    edName.Text := '';
  KindClick(nil);
end;

procedure TMenuWizardForm.KindClick(Sender: TObject);
var
  Tpl: TMenuTemplate;
begin
  Tpl := Current;
  chkAssign.Enabled := rbMain.Checked and
                       ((Tpl = nil) or (Tpl.MenuName = ''));
  if (Tpl = nil) or (Tpl.MenuName = '') then
    SuggestName;
  UpdateAddButton;
end;

// Снят пункт - сняты и его вложенные; отмечен - отмечены его владельцы
procedure TMenuWizardForm.ItemClickCheck(Sender: TObject);
var
  Tpl: TMenuTemplate;
  Index, ItemPos, Level: Integer;
  IsOn: Boolean;
begin
  Tpl := Current;
  Index := lstItems.ItemIndex;
  if (Tpl = nil) or (Index < 0) or (Index >= Tpl.Items.Count) then
    Exit;
  IsOn := lstItems.Checked[Index];
  TMenuTplItem(Tpl.Items[Index]).Checked := IsOn;
  Level := TMenuTplItem(Tpl.Items[Index]).Level;
  if not IsOn then
  begin
    ItemPos := Index + 1;
    while (ItemPos < Tpl.Items.Count) and
          (TMenuTplItem(Tpl.Items[ItemPos]).Level > Level) do
    begin
      TMenuTplItem(Tpl.Items[ItemPos]).Checked := False;
      lstItems.Checked[ItemPos] := False;
      Inc(ItemPos);
    end;
  end
  else
    for ItemPos := Index - 1 downto 0 do
      if TMenuTplItem(Tpl.Items[ItemPos]).Level < Level then
      begin
        Level := TMenuTplItem(Tpl.Items[ItemPos]).Level;
        TMenuTplItem(Tpl.Items[ItemPos]).Checked := True;
        lstItems.Checked[ItemPos] := True;
        if Level = 0 then
          Break;
      end;
end;

procedure TMenuWizardForm.AddClick(Sender: TObject);
var
  Choice: TMenuWizardChoice;
  NewName, MenuName: string;
  Tpl: TMenuTemplate;
begin
  Tpl := Current;
  if Tpl = nil then
  begin
    ShowMessage('Выберите набор меню');
    Exit;
  end;

  // Меню формы - правки прямо в нём
  if Tpl.MenuName <> '' then
  begin
    MenuName := Tpl.MenuName;
    if not Assigned(FHost.OnApply) or not FHost.OnApply(Tpl) then
      Exit;
    Inc(FAdded);
    ShowCloseButton;
    RefreshExisting(MenuName);
    Exit;
  end;

  NewName := Trim(edName.Text);
  if not IsValidIdent(NewName) then
  begin
    ShowMessage('Имя меню должно быть именем Delphi: ' + NewName);
    Exit;
  end;
  if Assigned(FHost.NameFree) and not FHost.NameFree(NewName) then
  begin
    ShowMessage('Имя уже занято в форме: ' + NewName);
    Exit;
  end;
  Choice.Template := Tpl;
  Choice.IsPopup := rbPopup.Checked;
  Choice.Name := NewName;
  Choice.AssignToForm := rbMain.Checked and chkAssign.Checked;
  Choice.ShortCuts := chkShortCuts.Checked;
  Choice.Themed := chkThemed.Checked;
  if not Assigned(FHost.OnAdd) or not FHost.OnAdd(Choice) then
    Exit;
  Inc(FAdded);
  ShowCloseButton;
  // Имя занято - предложить следующее свободное; новое меню - в конец
  // списка «в форме»
  if edName.Text = FDefaultName then
    edName.Text := '';
  RefreshExisting('');
end;

// Новый пункт «New Item» на место AIndex с уровнем ALevel: в список
// набора (или меню формы - в .dfm он попадёт при «Применить»)
procedure TMenuWizardForm.InsertItemAt(AIndex, ALevel: Integer);
var
  Tpl: TMenuTemplate;
  Item: TMenuTplItem;
  Row: Integer;
begin
  Tpl := Current;
  if Tpl = nil then
    Exit;
  Item := TMenuTplItem.Create;
  Item.Level := ALevel;
  Item.Caption := 'New Item';
  Item.Checked := True;
  if AIndex > Tpl.Items.Count then
    AIndex := Tpl.Items.Count;
  Tpl.Items.Insert(AIndex, Item);
  ShowItems;
  Row := Tpl.Items.IndexOf(Item);
  lstItems.ItemIndex := Row;
  ItemClick(nil);
  // Подпись - сразу править
  if edCaption.CanFocus then
  begin
    edCaption.SetFocus;
    edCaption.SelectAll;
  end;
end;

procedure TMenuWizardForm.ItemInsClick(Sender: TObject);
var
  Tpl: TMenuTemplate;
  Item: TMenuTplItem;
  Index: Integer;
begin
  Tpl := Current;
  if Tpl = nil then
    Exit;
  Item := CurrentItem;
  if Item = nil then
  begin
    // Пусто или ничего не выбрано - в конец, верхним уровнем
    InsertItemAt(Tpl.Items.Count, 0);
    Exit;
  end;
  Index := Tpl.Items.IndexOf(Item);
  if Sender = BtnItemSub then
    InsertItemAt(Index + 1, Item.Level + 1)
  else
    InsertItemAt(Index, Item.Level);
end;

// Убрать пункт с подменю. Пункт меню формы (есть в .dfm) только снимается -
// «Применить» удалит его из формы; новый пункт убирается из списка совсем.
procedure TMenuWizardForm.ItemDelClick(Sender: TObject);
var
  Tpl: TMenuTemplate;
  Item: TMenuTplItem;
  Index, Last: Integer;
begin
  Tpl := Current;
  Item := CurrentItem;
  if (Tpl = nil) or (Item = nil) then
    Exit;
  Index := Tpl.Items.IndexOf(Item);
  Last := Index;
  while (Last + 1 < Tpl.Items.Count) and
        (TMenuTplItem(Tpl.Items[Last + 1]).Level > Item.Level) do
    Inc(Last);
  while Last >= Index do
  begin
    if TMenuTplItem(Tpl.Items[Last]).ItemName <> '' then
      TMenuTplItem(Tpl.Items[Last]).Checked := False
    else
    begin
      TMenuTplItem(Tpl.Items[Last]).Free;
      Tpl.Items.Delete(Last);
    end;
    Dec(Last);
  end;
  ShowItems;
  if Index >= lstItems.Items.Count then
    Index := lstItems.Items.Count - 1;
  lstItems.ItemIndex := Index;
  ItemClick(nil);
end;

// Меню формы - целиком из формы, после подтверждения. Шаг отката, как
// вставка и правка: «Отмена» его вернёт.
procedure TMenuWizardForm.DeleteClick(Sender: TObject);
var
  Tpl: TMenuTemplate;
  MenuName: string;
begin
  Tpl := Current;
  if (Tpl = nil) or (Tpl.MenuName = '') or not Assigned(FHost.OnDelete) then
    Exit;
  MenuName := Tpl.MenuName;
  if MessageDlg('Удалить меню ' + MenuName + ' из формы целиком?'#13#10 +
                'Уйдут все его пункты, их поля в .pas и ссылка Menu у ' +
                'формы. Обработчики пунктов в коде останутся.',
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;
  if not FHost.OnDelete(MenuName) then
    Exit;
  Inc(FAdded);
  ShowCloseButton;
  RefreshExisting('');
end;

procedure TMenuWizardForm.CloseClick(Sender: TObject);
begin
  if FAdded = 0 then
  begin
    ModalResult := mrCancel;
    Exit;
  end;
  // Отмена: все вставки и правки этого окна - назад, окно остаётся
  while FAdded > 0 do
  begin
    if Assigned(FHost.OnUndo) then
      FHost.OnUndo;
    Dec(FAdded);
  end;
  ShowCloseButton;
  edName.Text := '';
  RefreshExisting('');
end;

function MenuWizardRun(ATemplates: TList; const AHost: TMenuWizardHost): Integer;
var
  Form: TMenuWizardForm;
  Index: Integer;
begin
  Form := TMenuWizardForm.CreateWizard(ATemplates, AHost);
  try
    Form.RefreshExisting(AHost.SelectMenu);
    // Редактировать: сразу меню формы - заданное или первое
    if AHost.EditMode and (AHost.SelectMenu = '') then
      for Index := 0 to ATemplates.Count - 1 do
        if TMenuTemplate(ATemplates[Index]).MenuName <> '' then
        begin
          Form.lstTemplates.ItemIndex := Index;
          Form.TemplateClick(nil);
          Break;
        end;
    Form.ShowModal;
    Result := Form.FAdded;
  finally
    Form.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  Текст .dfm
// ---------------------------------------------------------------------------

// Строка .dfm: в кавычках, кавычка удваивается
function DfmQuote(const S: string): string;
begin
  Result := '''' + StringReplace(S, '''', '''''', [rfReplaceAll]) + '''';
end;

// Основа имени пункта по подписи: только латинские буквы и цифры (имя
// Delphi); ничего не осталось - Item. Разделитель - N, как в Delphi.
function ItemBaseName(const ACaption: string): string;
var
  Index: Integer;
  Ch: Char;
begin
  if ACaption = '-' then
  begin
    Result := 'N';
    Exit;
  end;
  Result := '';
  for Index := 1 to Length(ACaption) do
  begin
    Ch := ACaption[Index];
    if Ch in ['A'..'Z', 'a'..'z', '0'..'9'] then
      Result := Result + Ch;
  end;
  if (Result = '') or (Result[1] in ['0'..'9']) then
    Result := 'Item' + Result;
end;

function MenuBuildDfm(const AChoice: TMenuWizardChoice; X, Y: Integer;
  ANameFree: TMenuNameFree; AItemNames: TStrings): string;
var
  Lines: TStringList;
  Tpl: TMenuTemplate;
  Item: TMenuTplItem;
  Index, Depth, Number, Code: Integer;
  Base, Name, Pad: string;

  function NameFree(const AName: string): Boolean;
  begin
    Result := (AItemNames.IndexOf(AName) < 0) and
              (CompareText(AName, AChoice.Name) <> 0) and
              (not Assigned(ANameFree) or ANameFree(AName));
  end;

  procedure CloseTo(ALevel: Integer);
  begin
    while Depth > ALevel do
    begin
      Dec(Depth);
      Lines.Add(StringOfChar(' ', 2 + Depth * 2) + 'end');
    end;
  end;

begin
  Lines := TStringList.Create;
  try
    if AChoice.IsPopup and AChoice.Themed then
      Lines.Add('object ' + AChoice.Name + ': TUiPopupMenu')
    else if AChoice.IsPopup then
      Lines.Add('object ' + AChoice.Name + ': TPopupMenu')
    else if AChoice.Themed then
      Lines.Add('object ' + AChoice.Name + ': TUiMainMenu')
    else
      Lines.Add('object ' + AChoice.Name + ': TMainMenu');
    Lines.Add('  Left = ' + IntToStr(X));
    Lines.Add('  Top = ' + IntToStr(Y));

    // Depth - сколько пунктов сейчас открыто (object без end)
    Depth := 0;
    Tpl := AChoice.Template;
    for Index := 0 to Tpl.Items.Count - 1 do
    begin
      Item := TMenuTplItem(Tpl.Items[Index]);
      if not Item.Checked then
        Continue;
      CloseTo(Item.Level);
      if Item.Level > Depth then
        Continue;             // владелец пункта снят - пункт не вставляется
      Base := ItemBaseName(Item.Caption);
      Number := 1;
      repeat
        Name := Base + IntToStr(Number);
        Inc(Number);
      until NameFree(Name);
      AItemNames.Add(Name);

      Pad := StringOfChar(' ', 2 + Depth * 2);
      Lines.Add(Pad + 'object ' + Name + ': TMenuItem');
      Lines.Add(Pad + '  Caption = ' + DfmQuote(Item.Caption));
      if AChoice.ShortCuts and (Item.ShortCutText <> '') then
      begin
        Code := TextToShortCut(Item.ShortCutText);
        if Code <> 0 then
          Lines.Add(Pad + '  ShortCut = ' + IntToStr(Code));
      end;
      Inc(Depth);
    end;
    CloseTo(0);
    Lines.Add('end');
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  Сохранить как шаблон
// ---------------------------------------------------------------------------

// Значение строки .dfm: 'abc'#1234'def' - склеенная строка
function DfmUnquote(const S: string): string;
var
  Index, Code: Integer;
  Num: string;
begin
  Result := '';
  Index := 1;
  while Index <= Length(S) do
  begin
    if S[Index] = '''' then
    begin
      Inc(Index);
      while Index <= Length(S) do
      begin
        if S[Index] = '''' then
        begin
          if (Index < Length(S)) and (S[Index + 1] = '''') then
          begin
            Result := Result + '''';
            Inc(Index, 2);
            Continue;
          end;
          Inc(Index);
          Break;
        end;
        Result := Result + S[Index];
        Inc(Index);
      end;
    end
    else if S[Index] = '#' then
    begin
      Inc(Index);
      Num := '';
      while (Index <= Length(S)) and (S[Index] in ['0'..'9']) do
      begin
        Num := Num + S[Index];
        Inc(Index);
      end;
      Code := StrToIntDef(Num, 32);
      if Code < 256 then
        Result := Result + Chr(Code)
      else
        Result := Result + string(WideString(WideChar(Code)));
    end
    else
      Inc(Index);
  end;
end;

function MenuTemplateFromDfm(const AObjText, ATitle: string;
  AIsPopup: Boolean): string;
var
  Src, Dst: TStringList;
  Index, Depth, Eq: Integer;
  Line, Name, Value: string;
  Caption, ShortCut: string;
  Open: Boolean;          // пункт начат, его строка ещё не записана

  procedure Flush;
  var
    Text: string;
  begin
    if not Open then
      Exit;
    Text := StringOfChar(' ', (Depth - 1) * 2) + Caption;
    if ShortCut <> '' then
      Text := Text + '|' + ShortCut;
    Dst.Add(Text);
    Open := False;
  end;

begin
  Src := TStringList.Create;
  Dst := TStringList.Create;
  try
    Dst.Add('; Шаблон меню (мастер меню SyntaxHLClaude)');
    Dst.Add('Title=' + ATitle);
    if AIsPopup then
      Dst.Add('Kind=Popup')
    else
      Dst.Add('Kind=Main');
    Src.Text := AObjText;
    Depth := -1;          // корень - само меню, его пункты - уровень 0
    Open := False;
    for Index := 0 to Src.Count - 1 do
    begin
      Line := Trim(Src[Index]);
      if (CompareText(Copy(Line, 1, 7), 'object ') = 0) or
         (CompareText(Copy(Line, 1, 10), 'inherited ') = 0) then
      begin
        Flush;
        Inc(Depth);
        if Depth > 0 then
        begin
          Open := True;
          Caption := '';
          ShortCut := '';
        end;
        Continue;
      end;
      if CompareText(Line, 'end') = 0 then
      begin
        Flush;
        Dec(Depth);
        Continue;
      end;
      if not Open then
        Continue;
      Eq := Pos('=', Line);
      if Eq = 0 then
        Continue;
      Name := Trim(Copy(Line, 1, Eq - 1));
      Value := Trim(Copy(Line, Eq + 1, MaxInt));
      if CompareText(Name, 'Caption') = 0 then
        Caption := DfmUnquote(Value)
      else if CompareText(Name, 'ShortCut') = 0 then
        ShortCut := ShortCutToText(StrToIntDef(Value, 0));
    end;
    Result := Dst.Text;
  finally
    Dst.Free;
    Src.Free;
  end;
end;

function MenuSaveTemplate(const ATitle, AText: string): string;
var
  Base: string;
  Index: Integer;
  Lines: TStringList;
begin
  // Имя файла - по названию, без знаков, запрещённых в именах файлов
  Base := ATitle;
  for Index := 1 to Length(Base) do
    if Base[Index] in ['\', '/', ':', '*', '?', '"', '<', '>', '|'] then
      Base[Index] := '_';
  if Trim(Base) = '' then
    Base := 'Menu';
  ForceDirectories(MenuTemplateDir);
  Result := IncludeTrailingPathDelimiter(MenuTemplateDir) + Base + '.mnu';
  Lines := TStringList.Create;
  try
    Lines.Text := AText;
    Lines.SaveToFile(Result);
  finally
    Lines.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  Удалить свои шаблоны, выбор из списка
// ---------------------------------------------------------------------------

function NewSmallDialog(const ACaption: string; AWidth, AHeight: Integer): TForm;
begin
  Result := TForm.CreateNew(Application);
  Result.Caption := ACaption;
  Result.BorderStyle := bsDialog;
  Result.Position := poScreenCenter;
  if Application.MainForm <> nil then
    Result.Font := Application.MainForm.Font;
  Result.Color := UiThemeColor('Window.BG');
  Result.Font.Color := UiThemeColor('Window.Text');
  Result.ClientWidth := AWidth;
  Result.ClientHeight := AHeight;
end;

procedure AddDialogButtons(AForm: TForm; const AOkCaption: string);
var
  BtnOk, BtnCancel: TUiButton;
begin
  BtnCancel := TUiButton.Create(AForm);
  BtnCancel.Parent := AForm;
  BtnCancel.Caption := 'Отмена';
  BtnCancel.Cancel := True;
  BtnCancel.ModalResult := mrCancel;
  BtnCancel.SetBounds(AForm.ClientWidth - 12 - 90, AForm.ClientHeight - 37,
                      90, 25);
  BtnOk := TUiButton.Create(AForm);
  BtnOk.Parent := AForm;
  BtnOk.Caption := AOkCaption;
  BtnOk.Default := True;
  BtnOk.ModalResult := mrOk;
  BtnOk.SetBounds(BtnCancel.Left - 8 - 90, BtnCancel.Top, 90, 25);
end;

function MenuDeleteTemplatesDialog: Integer;
var
  Form: TForm;
  List: TCheckListBox;
  Files: TStringList;
  Found: TSearchRec;
  Dir: string;
  Index: Integer;
  Tpl: TMenuTemplate;
  FileText: TStringList;
begin
  Result := 0;
  Dir := IncludeTrailingPathDelimiter(MenuTemplateDir);
  Files := TStringList.Create;
  try
    if FindFirst(Dir + '*.mnu', faAnyFile, Found) = 0 then
    try
      repeat
        Files.Add(Dir + Found.Name);
      until FindNext(Found) <> 0;
    finally
      FindClose(Found);
    end;
    if Files.Count = 0 then
    begin
      ShowMessage('Своих шаблонов меню нет (папка ' + MenuTemplateDir + ').');
      Exit;
    end;

    Form := NewSmallDialog('Удалить шаблоны меню', 420, 320);
    try
      List := TCheckListBox.Create(Form);
      List.Parent := Form;
      List.SetBounds(12, 12, Form.ClientWidth - 24, Form.ClientHeight - 62);
      for Index := 0 to Files.Count - 1 do
      begin
        // Название из файла, иначе имя файла
        FileText := TStringList.Create;
        try
          try
            FileText.LoadFromFile(Files[Index]);
            Tpl := ParseTemplate(FileText.Text, Files[Index]);
          except
            Tpl := nil;
          end;
        finally
          FileText.Free;
        end;
        if Tpl <> nil then
        begin
          List.Items.Add(Tpl.Title + '   (' + ExtractFileName(Files[Index]) +
                         ')');
          Tpl.Free;
        end
        else
          List.Items.Add(ExtractFileName(Files[Index]));
      end;
      AddDialogButtons(Form, 'Удалить');
      if Form.ShowModal <> mrOk then
        Exit;
      for Index := 0 to List.Items.Count - 1 do
        if List.Checked[Index] and DeleteFile(Files[Index]) then
          Inc(Result);
    finally
      Form.Free;
    end;
  finally
    Files.Free;
  end;
end;

function MenuPickDialog(const ACaption, APrompt: string;
  AItems: TStrings): Integer;
var
  Form: TForm;
  PromptLabel: TUiLabel;
  List: TUiListBox;
begin
  Result := -1;
  Form := NewSmallDialog(ACaption, 360, 300);
  try
    PromptLabel := TUiLabel.Create(Form);
    PromptLabel.Parent := Form;
    PromptLabel.Caption := APrompt;
    PromptLabel.SetBounds(12, 10, 330, 15);
    List := TUiListBox.Create(Form);
    List.Parent := Form;
    List.SetBounds(12, 28, Form.ClientWidth - 24, Form.ClientHeight - 78);
    List.Items.Assign(AItems);
    if List.Items.Count > 0 then
      List.ItemIndex := 0;
    AddDialogButtons(Form, 'OK');
    Form.ActiveControl := List;
    if (Form.ShowModal = mrOk) then
      Result := List.ItemIndex;
  finally
    Form.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  Меню из ресурсного скрипта (.rc)
// ---------------------------------------------------------------------------

// Строка в кавычках из строки .rc: "a""b\tCtrl+O" - с разбором \t и "".
// '' - кавычек нет.
function RcQuoted(const ALine: string): string;
var
  Index: Integer;
begin
  Result := '';
  Index := Pos('"', ALine);
  if Index = 0 then
    Exit;
  Inc(Index);
  while Index <= Length(ALine) do
  begin
    if ALine[Index] = '"' then
    begin
      if (Index < Length(ALine)) and (ALine[Index + 1] = '"') then
      begin
        Result := Result + '"';
        Inc(Index, 2);
        Continue;
      end;
      Break;
    end;
    if (ALine[Index] = '\') and (Index < Length(ALine)) then
    begin
      Inc(Index);
      case ALine[Index] of
        't': Result := Result + #9;
        'a': Result := Result + #8;   // в меню - выравнивание вправо
        'n': Result := Result + ' ';
      else
        Result := Result + ALine[Index];
      end;
      Inc(Index);
      Continue;
    end;
    Result := Result + ALine[Index];
    Inc(Index);
  end;
end;

function MenuTemplateFromRc(const AText, ATitle: string): TMenuTemplate;
var
  Lines: TStringList;
  Index, Level, Tab: Integer;
  Line, Upper, Text: string;
  Started: Boolean;
  Item: TMenuTplItem;

  function FirstWord(const S: string): string;
  var
    P: Integer;
  begin
    P := 1;
    while (P <= Length(S)) and not (S[P] in [' ', #9, ',', '"']) do
      Inc(P);
    Result := UpperCase(Copy(S, 1, P - 1));
  end;

  procedure AddItem(const ACaption: string);
  begin
    Item := TMenuTplItem.Create;
    Item.Level := Level;
    Item.Checked := True;
    Tab := Pos(#9, ACaption);
    if Tab > 0 then
    begin
      Item.Caption := Copy(ACaption, 1, Tab - 1);
      Item.ShortCutText := Trim(Copy(ACaption, Tab + 1, MaxInt));
    end
    else
      Item.Caption := ACaption;
    Result.Items.Add(Item);
  end;

begin
  Result := TMenuTemplate.Create;
  Result.Title := ATitle;
  Lines := TStringList.Create;
  try
    Lines.Text := AText;
    Started := False;
    Level := -1;       // до BEGIN меню
    for Index := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[Index]);
      if (Line = '') or (Copy(Line, 1, 2) = '//') then
        Continue;
      Upper := UpperCase(Line);
      if not Started then
      begin
        // Заголовок ресурса меню: "IDR_MAIN MENU" / "... MENUEX"
        if (Pos(' MENU', Upper + ' ') > 0) and
           ((Copy(Upper, Length(Upper) - 4, 5) = ' MENU') or
            (Pos(' MENU ', Upper + ' ') > 0) or (Pos(' MENUEX', Upper) > 0)) then
          Started := True;
        Continue;
      end;
      if (FirstWord(Line) = 'BEGIN') or (Line = '{') then
      begin
        Inc(Level);
        Continue;
      end;
      if (FirstWord(Line) = 'END') or (Line = '}') then
      begin
        Dec(Level);
        if Level < 0 then
          Break;           // конец меню
        Continue;
      end;
      if Level < 0 then
        Continue;
      if FirstWord(Line) = 'POPUP' then
        AddItem(RcQuoted(Line))
      else if FirstWord(Line) = 'MENUITEM' then
      begin
        if (Pos('SEPARATOR', Upper) > 0) and (Pos('"', Line) = 0) then
          AddItem('-')
        else
        begin
          Text := RcQuoted(Line);
          if Text = '' then
            AddItem('-')
          else
            AddItem(Text);
        end;
      end;
    end;
  finally
    Lines.Free;
  end;
  if Result.Items.Count = 0 then
    FreeAndNil(Result);
end;

// ---------------------------------------------------------------------------
//  Пункт меню в тексте .dfm
// ---------------------------------------------------------------------------

function MenuItemDfm(const AName, ACaption: string;
  AShortCut: Integer): string;
begin
  Result := 'object ' + AName + ': TMenuItem'#13#10 +
            '  Caption = ' + DfmQuote(ACaption) + #13#10;
  if AShortCut <> 0 then
    Result := Result + '  ShortCut = ' + IntToStr(AShortCut) + #13#10;
  Result := Result + 'end'#13#10;
end;

function MenuNewItemName(const ACaption: string; ANameFree: TMenuNameFree;
  AUsed: TStrings): string;
var
  Base: string;
  Number: Integer;
begin
  Base := ItemBaseName(ACaption);
  Number := 1;
  repeat
    Result := Base + IntToStr(Number);
    Inc(Number);
  until (AUsed.IndexOf(Result) < 0) and
        (not Assigned(ANameFree) or ANameFree(Result));
  AUsed.Add(Result);
end;

function MenuIsMainClass(const AClassName: string): Boolean;
begin
  Result := (CompareText(AClassName, 'TMainMenu') = 0) or
            (CompareText(AClassName, 'TUiMainMenu') = 0);
end;

function MenuIsPopupClass(const AClassName: string): Boolean;
begin
  Result := (CompareText(AClassName, 'TPopupMenu') = 0) or
            (CompareText(AClassName, 'TUiPopupMenu') = 0);
end;

function MenuDfmInsertBefore(const AText, AName, AObjText: string): string;
var
  Lines, Obj: TStringList;
  First, Last, Index, Indent: Integer;
begin
  Result := AText;
  if not DfmObjectRange(AText, AName, First, Last) then
    Exit;
  Lines := TStringList.Create;
  Obj := TStringList.Create;
  try
    Lines.Text := AText;
    Indent := 0;
    while (Indent < Length(Lines[First])) and
          (Lines[First][Indent + 1] = ' ') do
      Inc(Indent);
    Obj.Text := AObjText;
    for Index := Obj.Count - 1 downto 0 do
      if Obj[Index] <> '' then
        Lines.Insert(First, StringOfChar(' ', Indent) + Obj[Index]);
    Result := Lines.Text;
  finally
    Obj.Free;
    Lines.Free;
  end;
end;

// Меню формы из текста .dfm его объекта: пункты с именами, подписями и
// клавишами
function MenuTemplateFromDfmObj(const AObjText, AMenuName: string;
  AIsPopup: Boolean): TMenuTemplate;
var
  Src: TStringList;
  Index, Depth, Eq, Colon: Integer;
  Line, PropName, Value: string;
  Item: TMenuTplItem;
begin
  Result := TMenuTemplate.Create;
  Result.Title := AMenuName + ' (в форме)';
  Result.MenuName := AMenuName;
  Result.IsPopup := AIsPopup;
  Src := TStringList.Create;
  try
    Src.Text := AObjText;
    Depth := -1;          // корень - само меню, его пункты - уровень 0
    Item := nil;
    for Index := 0 to Src.Count - 1 do
    begin
      Line := Trim(Src[Index]);
      if (CompareText(Copy(Line, 1, 7), 'object ') = 0) or
         (CompareText(Copy(Line, 1, 10), 'inherited ') = 0) then
      begin
        Inc(Depth);
        Item := nil;
        if Depth > 0 then
        begin
          Item := TMenuTplItem.Create;
          Item.Level := Depth - 1;
          Item.Checked := True;
          Colon := Pos(':', Line);
          if Colon > 0 then
            Item.ItemName := Trim(Copy(Line, Pos(' ', Line) + 1,
                                       Colon - Pos(' ', Line) - 1));
          Result.Items.Add(Item);
        end;
        Continue;
      end;
      if CompareText(Line, 'end') = 0 then
      begin
        Dec(Depth);
        Item := nil;
        Continue;
      end;
      if Item = nil then
        Continue;
      Eq := Pos('=', Line);
      if Eq = 0 then
        Continue;
      PropName := Trim(Copy(Line, 1, Eq - 1));
      Value := Trim(Copy(Line, Eq + 1, MaxInt));
      if CompareText(PropName, 'Caption') = 0 then
      begin
        Item.Caption := DfmUnquote(Value);
        Item.OrigCaption := Item.Caption;
      end
      else if CompareText(PropName, 'ShortCut') = 0 then
      begin
        Item.ShortCutText := ShortCutToText(StrToIntDef(Value, 0));
        Item.OrigShortCut := Item.ShortCutText;
      end;
    end;
  finally
    Src.Free;
  end;
end;

function MenuDfmQuote(const S: string): string;
begin
  Result := DfmQuote(S);
end;

end.
