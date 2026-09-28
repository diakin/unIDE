unit DsgClasses;

// Классы, которые конструктор форм и инспектор создают настоящими: всё, что
// лежит на вкладках палитры Delphi 7 Standard, Additional, Win32, System,
// Dialogs, Win 3.1 и Samples и не требует слоя БД или сети. Остальное
// (Data Access, BDE, ADO, dbExpress, Internet и т. д.) читается заглушками:
// невизуальный компонент с Active/Connected = True в .dfm при чтении
// настоящим классом открыл бы соединение.
//
// Не регистрируются намеренно, остаются заглушками:
//   TMediaPlayer   - при AutoOpen = True открывает устройство при загрузке;
//   TOleContainer  - поднимает OLE-объект из данных .dfm;
//   TDdeClientConv, TDdeClientItem, TDdeServerConv, TDdeServerItem -
//                    при ConnectMode = ddeAutomatic подключаются при загрузке;
//   TXPManifest    - модуль XPMan вкладывает манифест тем в exe редактора
//                    и меняет вид самого редактора;
//   TChart         - TeeChart, отдельный пакет.
//
// Модули, наличие которых в Delphi7\Lib не проверено, включены через
// условные символы: если dcc32 не найдёт модуль или класс, закомментируйте
// соответствующий {$DEFINE}.

{$DEFINE DSG_SHELLCTRLS}     // TShellTreeView, TShellComboBox, TShellListView
{$DEFINE DSG_PAGESETUPDLG}   // TPageSetupDialog

interface

uses
  Classes;

procedure RegisterDesignClasses;

// Страницы палитры в порядке Delphi 7 и компоненты на них. Классы
// TComponentClass в TList. Служебные классы (TTabSheet, TMenuItem, TAction,
// TToolButton, TForm, TFrame) зарегистрированы, но на палитру не попадают:
// в Delphi их добавляют не с палитры.
function DsgPageCount: Integer;
function DsgPageName(AIndex: Integer): string;
function DsgPageClasses(AIndex: Integer): TList;

// Свои компоненты страницы (ряд Custom палитры): классы набора UiTheme
// (TUiButton, TUiEdit, ...), похожие на компоненты этой страницы. nil -
// своих на странице нет.
function DsgPageCustomClasses(AIndex: Integer): TList;

implementation

uses
  SysUtils, Controls, Forms, Menus, StdCtrls, ExtCtrls, ActnList,
  // Additional
  Buttons, Mask, Grids, CheckLst, AppEvnts, ValEdit,
  ActnMan, ActnMenus, ActnCtrls, ActnColorMaps, CustomizeDlg,
  // Win32
  ComCtrls, ImgList,
  // Dialogs
  Dialogs, ExtDlgs,
  // Win 3.1
  Tabs, Outline, Tabnotbk, FileCtrl,
  // Samples
  Gauges, ColorGrd, Spin, DirOutln, Calendar,
  {$IFDEF DSG_SHELLCTRLS} ShellCtrls, {$ENDIF}
  // форматы Picture.Data в .dfm: initialization регистрирует TJPEGImage
  jpeg,
  // свои компоненты (ряд Custom): вид по теме Light / Dark / Custom
  UiTheme, UiScroll, UiButton, UiGroupBox, UiStdCtrls, UiEditCtrls,
  UiComCtrls, UiMenus, UiStdDlgs;

var
  FPages: TStringList = nil; // имя страницы -> TList классов
  FCustom: TStringList = nil; // имя страницы -> TList своих классов

procedure Reg(const AList: array of TPersistentClass);
var
  I: Integer;
begin
  // Занятое имя пропускаем заранее: исключение RegisterClass останавливает
  // программу под отладчиком. Так бывает, если в модуле программы объявлен
  // свой наследник с тем же именем (TRichEdit в Unit1).
  for I := Low(AList) to High(AList) do
    if GetClass(AList[I].ClassName) = nil then
      RegisterClass(AList[I]);
end;

// Регистрация и страница палитры
procedure RegPage(const APage: string; const AList: array of TPersistentClass);
var
  I, P: Integer;
  L: TList;
begin
  Reg(AList);
  P := FPages.IndexOf(APage);
  if P < 0 then
    P := FPages.AddObject(APage, TList.Create);
  L := TList(FPages.Objects[P]);
  for I := Low(AList) to High(AList) do
    if AList[I].InheritsFrom(TComponent) then
      L.Add(Pointer(AList[I]));
end;

// Свои компоненты страницы: регистрация и ряд Custom палитры
procedure RegCustom(const APage: string; const AList: array of TPersistentClass);
var
  I, P: Integer;
  L: TList;
begin
  Reg(AList);
  P := FCustom.IndexOf(APage);
  if P < 0 then
    P := FCustom.AddObject(APage, TList.Create);
  L := TList(FCustom.Objects[P]);
  for I := Low(AList) to High(AList) do
    if AList[I].InheritsFrom(TComponent) then
      L.Add(Pointer(AList[I]));
end;

function DsgPageCustomClasses(AIndex: Integer): TList;
var
  P: Integer;
begin
  Result := nil;
  if (FCustom = nil) or (FPages = nil) or (AIndex < 0) or
     (AIndex >= FPages.Count) then
    Exit;
  P := FCustom.IndexOf(FPages[AIndex]);
  if P >= 0 then
    Result := TList(FCustom.Objects[P]);
end;

function DsgPageCount: Integer;
begin
  if FPages = nil then
    Result := 0
  else
    Result := FPages.Count;
end;

function DsgPageName(AIndex: Integer): string;
begin
  Result := FPages[AIndex];
end;

function DsgPageClasses(AIndex: Integer): TList;
begin
  Result := TList(FPages.Objects[AIndex]);
end;

procedure RegisterDesignClasses;
begin
  if FPages <> nil then
    Exit; // уже
  FPages := TStringList.Create;
  FCustom := TStringList.Create;

  // Служебные: не с палитры
  Reg([TForm, TFrame, TMenuItem, TAction, TTabSheet, TToolButton]);

  RegPage('Standard',
    [TMainMenu, TPopupMenu, TLabel, TEdit, TMemo, TButton, TCheckBox,
     TRadioButton, TListBox, TComboBox, TScrollBar, TGroupBox, TRadioGroup,
     TPanel, TActionList]);

  RegPage('Additional',
    [TBitBtn, TSpeedButton, TMaskEdit, TStringGrid, TDrawGrid, TImage,
     TShape, TBevel, TScrollBox, TCheckListBox, TSplitter, TStaticText,
     TControlBar, TApplicationEvents, TValueListEditor, TLabeledEdit,
     TColorBox, TActionManager, TActionMainMenuBar, TActionToolBar,
     TXPColorMap, TStandardColorMap, TTwilightColorMap, TCustomizeDlg]);

  RegPage('Win32',
    [TTabControl, TPageControl, TImageList, TRichEdit, TTrackBar,
     TProgressBar, TUpDown, THotKey, TAnimate, TDateTimePicker,
     TMonthCalendar, TTreeView, TListView, THeaderControl, TStatusBar,
     TToolBar, TCoolBar, TPageScroller, TComboBoxEx]);

  RegPage('System', [TTimer, TPaintBox]);

  RegPage('Dialogs',
    [TOpenDialog, TSaveDialog, TOpenPictureDialog, TSavePictureDialog,
     TFontDialog, TColorDialog, TPrintDialog, TPrinterSetupDialog,
     TFindDialog, TReplaceDialog]);
  {$IFDEF DSG_PAGESETUPDLG}
  RegPage('Dialogs', [TPageSetupDialog]);
  {$ENDIF}

  RegPage('Win 3.1',
    [TTabSet, TOutline, TTabbedNotebook, TNotebook, THeader,
     TFileListBox, TDirectoryListBox, TDriveComboBox, TFilterComboBox]);

  RegPage('Samples',
    [TGauge, TColorGrid, TSpinButton, TSpinEdit, TDirectoryOutline,
     TCalendar]);
  {$IFDEF DSG_SHELLCTRLS}
  RegPage('Samples',
    [TShellTreeView, TShellComboBox, TShellListView, TShellChangeNotifier]);
  {$ENDIF}

  // Свои компоненты - вторым рядом на тех же страницах
  RegCustom('Standard',
    [TUiMainMenu, TUiPopupMenu,
     TUiLabel, TUiEdit, TUiMemo, TUiButton, TUiCheckBox, TUiRadioButton,
     TUiListBox, TUiComboBox, TUiScrollBar, TUiGroupBox, TUiRadioGroup,
     TUiPanel]);
  RegCustom('Win32',
    [TUiTabControl, TUiPageControl, TUiUpDown, TUiTreeView, TUiListView,
     TUiStatusBar]);
  // Невидимый: тема программы (Light / Dark / Custom)
  RegCustom('System', [TUiTheme]);
  RegCustom('Dialogs', [TUiColorDialog, TUiFontDialog]);
end;

procedure FreePages;
var
  I: Integer;
begin
  if FPages = nil then
    Exit;
  for I := 0 to FPages.Count - 1 do
    FPages.Objects[I].Free;
  FreeAndNil(FPages);
  if FCustom <> nil then
    for I := 0 to FCustom.Count - 1 do
      FCustom.Objects[I].Free;
  FreeAndNil(FCustom);
end;

initialization

finalization
  FreePages;

end.
