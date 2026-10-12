unit DsgPalette;

// ---------------------------------------------------------------------------
//  Палитра компонентов для конструктора форм
//
//  Панель с вкладками страниц и кнопками компонентов, как палитра Delphi 7.
//  Ставится в главное окно (на свою группу справа от поиска) и видна всегда.
//  Состав страниц - из DsgClasses (DsgPageCount и т. д.).
//
//  Кнопки компонентов палитра не создаёт: это массив PalBtn главного окна
//  (Unit1, BuildPaletteButtons), по кнопке на класс, номер сквозной по всем
//  страницам. Палитра ставит каждую кнопку на её страницу и заполняет
//  (PlaceButton): значок, подсказка, место. Кнопки всех страниц лежат на
//  одной области прокрутки; смена вкладки только показывает кнопки своей
//  страницы и прячет остальные (ShowPage) - ничего не пересоздаётся.
//
//  Первая кнопка - стрелка: выбора нет, мышь в конструкторе выделяет и
//  двигает. Нажатая кнопка компонента - выбран класс для вставки
//  (SelectedClass); повторный щелчок по ней или стрелка снимают выбор.
//
//  Значки берутся из design-пакетов Delphi (Bin\dcl*.bpl): они загружаются
//  только как файлы данных (LOAD_LIBRARY_AS_DATAFILE), код пакетов не
//  выполняется. Значок палитры в пакете - ресурс BITMAP с именем класса
//  прописными буквами (TBUTTON). Не нашёлся значок - на кнопке имя класса.
//
//  Сторонние компоненты (DsgForeign: из пакетов, установленных в Delphi) -
//  на своих страницах после страниц Delphi (AddPage, PlaceForeign). Класса
//  их в редакторе нет: в Tag кнопки 0, а выбор - строка "Модуль.Класс"
//  (SelectedForeign). Значки - из их design-пакетов (AddIconLib). Значок
//  стороннего читается при первом показе его страницы (ShowPage): их
//  больше сотни, а при запуске видна страница Standard. После загрузки
//  значка - OnGlyphLoaded (тёмная тема перекрашивает его).
//
//  Компоненты RapidQ (Unit1, DsgAddRapidQPages) - тоже на своих страницах,
//  выбор - строкой "RapidQ.КЛАСС", значок - сглаженный значок похожего
//  компонента Delphi (PlaceRapidQ).
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Controls, Forms, Graphics, ExtCtrls,
  ComCtrls, Buttons, Menus,
  UiComCtrls;     // вкладки палитры рисуются по теме (TUiTabControl)

type
  // Перекраска значка Delphi для тёмного фона (главное окно,
  // UiPaletteRecolor): прозрачный цвет и цвет значка
  TDsgRecolorProc = procedure(ABmp: TBitmap; ATransparent, AColor: TColor);

  // Исходный значок кнопки палитры: из чего строить её значок для темы
  TDsgGlyphInfo = class
  public
    Btn: TControl;
    Base: TBitmap;      // значок Delphi без метки; у сглаженного - заготовка
    Smooth: string;     // сглаженный значок, рисуется кодом ('YinYang')
    Mark: Boolean;      // свой компонент: метка в правом нижнем углу
    destructor Destroy; override;
  end;

  TDsgPalette = class(TPanel)
  private
    FTabs: TTabControl;
    FBox: TScrollBox;
    FArrow: TSpeedButton;
    FPageBtns: TList;         // по странице - TList её кнопок, в порядке постановки
    // Страницы и вкладки: вкладка - только у не спрятанной страницы
    // (SetPageHidden). FPageNames - имена всех страниц, FPageHidden -
    // спрятана ли, FTabPages - номер страницы по номеру вкладки.
    FPageNames: TStringList;
    FPageHidden: array of Boolean;
    FTabPages: TList;
    // Раскладка по странице: где следующая кнопка первого ряда, сколько в
    // нём кнопок, где первое свободное место второго ряда (свои компоненты)
    FNextX: array of Integer;
    FRow1Count: array of Integer;
    FNextFree: array of Integer;
    FMeter: TBitmap;          // замер ширины надписи: холст окна может ещё не быть
    FLibs: TList;             // HMODULE пакетов со значками
    FSelected: TComponentClass;
    FForeign: TStringList;    // кнопки сторонних: "Модуль.Класс", в Objects - кнопка
    FSelForeign: string;      // выбран сторонний: "Модуль.Класс"
    FGlyphPending: TList;     // кнопки сторонних, значок которых ещё не читали
    FOnGlyphLoaded: TNotifyEvent;
    FOnSelect: TNotifyEvent;
    FGlyphInfo: TList;        // TDsgGlyphInfo по кнопкам со значком
    FButtonPopup: TPopupMenu; // меню правой кнопки у кнопок компонентов
    // Вкладки в несколько рядов: на сколько пикселей ряды вкладок выше
    // одного ряда; меняется - OnTabRows (владелец подгоняет высоту панели)
    FTabRowsExtra: Integer;
    FOnTabRows: TNotifyEvent;
    procedure SetButtonPopup(AValue: TPopupMenu);
    function HasGlyphRes(const AName: string): Boolean;
    procedure LoadLibs(const ADelphiBin: string);
    function LoadGlyph(AClass: TClass; ABmp: TBitmap): Boolean;
    function LoadGlyphByName(const AName: string; ABmp: TBitmap): Boolean;
    function LoadCustomGlyph(AClass: TClass; ABmp: TBitmap;
                             var ASmooth: string): Boolean;
    function GlyphInfoOf(ABtn: TControl): TDsgGlyphInfo;
    procedure SetGlyphInfo(ABtn: TControl; ABase: TBitmap;
                           const ASmooth: string; AMark: Boolean);
    function StdButtonFor(ACustom: TComponentClass; AList: TList;
                          AFirstRowCount: Integer): TSpeedButton;
    procedure TabChange(Sender: TObject);
    function CurPage: Integer;
    procedure ArrowClick(Sender: TObject);
    procedure CompClick(Sender: TObject);
    procedure SetSelected(AClass: TComponentClass);
  protected
    procedure Resize; override;
  public
    // Пересчитать число рядов вкладок (после смены ширины или страниц)
    procedure CheckTabRows;
    property TabRowsExtra: Integer read FTabRowsExtra;
    property OnTabRows: TNotifyEvent read FOnTabRows write FOnTabRows;
    // AParent - куда встать (заполняет его целиком). ADelphiBin - папка
    // Bin установки Delphi со слэшем, '' - без значков.
    constructor CreatePalette(AOwner: TComponent; AParent: TWinControl;
                              const ADelphiBin: string);
    destructor Destroy; override;
    // Кнопку класса AClass - на страницу APage: родитель, значок, подсказка,
    // обработчик, место. ACustom - свой компонент, второй ряд. Кнопку
    // создаёт и называет владелец. Порядок: на каждой странице сначала все
    // компоненты Delphi, потом свои - свой встаёт под одноимённым первого
    // ряда (TUiButton - под TButton).
    procedure PlaceButton(ABtn: TSpeedButton; AClass: TComponentClass;
                          APage: Integer; ACustom: Boolean);
    // Видны кнопки открытой вкладки, остальные спрятаны; выбор снят
    procedure ShowPage;
    // Номер страницы (вкладки) кнопки ABtn; -1 - кнопка не из палитры
    function PageOf(ABtn: TControl): Integer;
    // Новая страница после имеющихся; номер страницы
    function AddPage(const AName: string): Integer;
    // Пакет со значками - как файл данных (сторонние design-пакеты)
    procedure AddIconLib(const APath: string);
    // Кнопка стороннего компонента AClass из модуля AUnit - на страницу
    // APage, в первый ряд. Значок - по имени класса.
    procedure PlaceForeign(ABtn: TSpeedButton; const AUnit, AClass,
                           AHint: string; APage: Integer);
    // "Модуль.Класс" кнопки стороннего компонента; '' - не сторонний
    function ForeignOf(ABtn: TControl): string;
    // Кнопка компонента RapidQ AClass (QBUTTON) - на страницу APage, в
    // первый ряд. Значок - сглаженный значок похожего класса Delphi
    // AIconClass (TButton); нет его - надпись без первой буквы. Выбор -
    // строкой "RapidQ.QBUTTON" (SelectedForeign), как у сторонних.
    procedure PlaceRapidQ(ABtn: TSpeedButton; const AClass, AIconClass,
                          AHint: string; APage: Integer);
    // Открыть вкладку APage
    procedure SetPage(APage: Integer);
    // Страница открытой вкладки
    function PageIndex: Integer;
    // Сколько страниц (и спрятанных)
    function PageCount: Integer;
    // Спрятать (AHidden) или вернуть вкладку страницы APage. Вкладки
    // перестраиваются в ApplyPages, после всех смен.
    procedure SetPageHidden(APage: Integer; AHidden: Boolean);
    // Вкладки - по видимым страницам. Открытая страница остаётся открытой,
    // если её не спрятали; иначе - первая видимая.
    procedure ApplyPages;
    // Значок кнопки ABtn для темы - в ABmp: значок Delphi (ADark - с
    // перекраской ARecolor в цвет AInk) или сглаженный, нарисованный цветом
    // AInk; у своих компонентов - сглаженная метка цветом AMarkInk. Края -
    // смесью с фоном ABack. False - кнопка без значка или не из палитры.
    function RenderGlyph(ABtn: TControl; ADark: Boolean;
                         AInk, AMarkInk, ABack: TColor;
                         ARecolor: TDsgRecolorProc; ABmp: TBitmap): Boolean;
    // Сглаженные значки заново - их скрипты сменились (свои значки
    // DsgIcons): светлый вид каждой такой кнопки на фоне ALightBack
    // (clNone - фон палитры) ставится ей в Glyph, сама кнопка - в
    // AButtons. Тёмный вид строит владелец.
    procedure RefreshSmooth(ALightBack: TColor; AButtons: TList);
    // Снять выбор: кнопка компонента отжимается, нажата стрелка
    procedure ClearSelection;
    // Меню правой кнопки у кнопок компонентов Delphi и своих (и стрелки);
    // кнопка - PopupComponent меню
    property ButtonPopup: TPopupMenu read FButtonPopup write SetButtonPopup;
    property SelectedClass: TComponentClass read FSelected;
    // Выбран сторонний компонент: "Модуль.Класс"; '' - нет
    property SelectedForeign: string read FSelForeign;
    // Значок кнопки стороннего компонента прочитан (Sender - кнопка)
    property OnGlyphLoaded: TNotifyEvent read FOnGlyphLoaded
                                         write FOnGlyphLoaded;
    property OnSelect: TNotifyEvent read FOnSelect write FOnSelect;
  end;

// Значок по скрипту (формат - DsgIcons) сглаженным: AInk - цвет значка,
// ABack - фон для краёв; пустые точки - прозрачный цвет кнопки (clOlive).
// ABmp - 24x24.
procedure DsgDrawSmoothScript(ABmp: TBitmap; const AScript: string;
                              AInk, ABack: TColor);

implementation

uses
  DsgClasses,
  DsgIcons;   // сглаженные значки компонентов Delphi - скриптами

type
  // PopupMenu у TControl - protected
  TPaletteBtnAcc = class(TControl);

const
  BtnSize = 28;
  // Второй ряд - свои компоненты (Custom): кнопки и значки того же размера,
  // что у компонентов Delphi в первом ряду
  CustomBtnSize = BtnSize;
  // Сторона метки своего компонента - треугольника в правом нижнем углу
  MarkSize = 7;
  AsDataFile = 2; // LOAD_LIBRARY_AS_DATAFILE

// Стрелка выбора, 16x16. Прозрачный цвет кнопки - левый нижний пиксель,
// он остаётся фоном.
procedure DrawArrow(ABmp: TBitmap);
begin
  ABmp.Width := 16;
  ABmp.Height := 16;
  with ABmp.Canvas do
  begin
    Brush.Color := clOlive;
    FillRect(Rect(0, 0, 16, 16));
    Brush.Color := clBlack;
    Pen.Color := clBlack;
    Polygon([Point(4, 1), Point(4, 13), Point(7, 10), Point(10, 15),
             Point(12, 14), Point(9, 9), Point(13, 9)]);
  end;
end;

constructor TDsgPalette.CreatePalette(AOwner: TComponent; AParent: TWinControl;
                                      const ADelphiBin: string);
var
  I: Integer;
begin
  inherited Create(AOwner);
  FPageBtns := TList.Create;
  FPageNames := TStringList.Create;
  FTabPages := TList.Create;
  FLibs := TList.Create;
  FForeign := TStringList.Create;
  FGlyphPending := TList.Create;
  FGlyphInfo := TList.Create;
  FMeter := TBitmap.Create;

  Parent := AParent;
  Align := alClient;
  BevelOuter := bvNone;
  ParentFont := True;
  Caption := '';

  FTabs := TUiTabControl.Create(Self);
  FTabs.Parent := Self;
  FTabs.Align := alClient;
  FTabs.ParentFont := True;
  // Все вкладки видны сразу, в несколько рядов; ряды на своих местах
  // (TUiTabControl: в несколько рядов - стиль кнопок, Windows их не
  // переставляет)
  FTabs.MultiLine := True;
  SetLength(FPageHidden, DsgPageCount);
  for I := 0 to DsgPageCount - 1 do
  begin
    FTabs.Tabs.Add(DsgPageName(I));
    FPageNames.Add(DsgPageName(I));
    FPageHidden[I] := False;
    FTabPages.Add(Pointer(I));
  end;
  FTabs.OnChange := TabChange;

  FBox := TScrollBox.Create(Self);
  FBox.Parent := FTabs;
  FBox.Align := alClient;
  FBox.BorderStyle := bsNone;
  FBox.VertScrollBar.Visible := False;
  FBox.HorzScrollBar.Tracking := True;

  // Двойная буферизация - всем трём окнам палитры. Кнопки компонентов -
  // безоконные (TSpeedButton), их рисует FBox; без буфера при смене ширины
  // окна панель, вкладки и коробка с кнопками стирались и рисовались
  // каждая отдельно, и палитра моргала. Буфер у pnlPaletteIn (родителя)
  // окна-детей не покрывает.
  DoubleBuffered := True;
  FTabs.DoubleBuffered := True;
  FBox.DoubleBuffered := True;

  FArrow := TSpeedButton.Create(Self);
  FArrow.Parent := FBox;
  FArrow.SetBounds(2, 1, BtnSize, BtnSize);
  FArrow.Flat := True;
  FArrow.GroupIndex := 1;
  FArrow.Down := True;
  FArrow.Hint := 'Выбор (без компонента)';
  FArrow.ShowHint := True;
  DrawArrow(FArrow.Glyph);
  // Сглаженная стрелка (DsgIcons, 'Arrow') вместо пиксельной из DrawArrow
  SetGlyphInfo(FArrow, nil, 'Arrow', False);
  RenderGlyph(FArrow, False, clBlack, clTeal, FBox.Color, nil, FArrow.Glyph);
  FArrow.OnClick := ArrowClick;

  // Раскладка страниц - пустая; кнопки придут через PlaceButton
  SetLength(FNextX, DsgPageCount);
  SetLength(FRow1Count, DsgPageCount);
  SetLength(FNextFree, DsgPageCount);
  for I := 0 to DsgPageCount - 1 do
  begin
    FPageBtns.Add(TList.Create);
    FNextX[I] := FArrow.Left + BtnSize + 6;
    FRow1Count[I] := 0;
    FNextFree[I] := FArrow.Left + BtnSize + 6;
  end;

  LoadLibs(ADelphiBin);
  if FTabs.Tabs.Count > 0 then
    FTabs.TabIndex := 0;
end;

destructor TDsgPalette.Destroy;
var
  I: Integer;
begin
  for I := 0 to FLibs.Count - 1 do
    FreeLibrary(HMODULE(FLibs[I]));
  FLibs.Free;
  // Сами кнопки - владельца, здесь только списки
  for I := 0 to FPageBtns.Count - 1 do
    TObject(FPageBtns[I]).Free;
  FPageBtns.Free;
  FPageNames.Free;
  FTabPages.Free;
  FForeign.Free;
  FGlyphPending.Free;
  for I := 0 to FGlyphInfo.Count - 1 do
    TObject(FGlyphInfo[I]).Free;
  FGlyphInfo.Free;
  FMeter.Free;
  inherited;
end;

// Все design-пакеты Delphi из Bin - как файлы данных, только ради ресурсов
procedure TDsgPalette.LoadLibs(const ADelphiBin: string);
var
  SR: TSearchRec;
  H: HMODULE;
begin
  if (ADelphiBin = '') or not DirectoryExists(ADelphiBin) then
    Exit;
  if FindFirst(ADelphiBin + 'dcl*.bpl', faAnyFile, SR) = 0 then
  try
    repeat
      H := LoadLibraryEx(PChar(ADelphiBin + SR.Name), 0, AsDataFile);
      if H <> 0 then
        FLibs.Add(Pointer(H));
    until FindNext(SR) <> 0;
  finally
    FindClose(SR);
  end;
end;

function TDsgPalette.LoadGlyph(AClass: TClass; ABmp: TBitmap): Boolean;
begin
  Result := LoadGlyphByName(AClass.ClassName, ABmp);
end;

// ---------------------------------------------------------------------------
//  Сглаженные значки
//
//  Кнопки палитры - TSpeedButton: прозрачность у них - один цвет (левый
//  нижний пиксель), полупрозрачных точек нет. Поэтому край сглаживается
//  смесью с фоном палитры: точка края получает цвет между цветом значка и
//  фоном по доле, которую фигура в ней закрывает (покрытие). Покрытие
//  считается рисованием в 4 раза крупнее (GDI, без сглаживания) и
//  усреднением квадратов 4x4 - 16 ступеней на точку. Фон меняется с темой -
//  значок строится заново (RenderGlyph, UiApplyGlyph).
// ---------------------------------------------------------------------------

const
  SmoothSide = 24;           // сторона значка
  SmoothScale = 4;           // во сколько раз крупнее считается покрытие
  SmoothKey = clOlive;       // прозрачный цвет кнопки

// Смесь цветов: AInk с долей ACover из 255, остальное - ABack
function SmoothMix(AInk, ABack: TColor; ACover: Integer): TColor;
var
  InkRGB, BackRGB: Longint;
begin
  InkRGB := ColorToRGB(AInk);
  BackRGB := ColorToRGB(ABack);
  Result := RGB((GetRValue(InkRGB) * ACover +
                 GetRValue(BackRGB) * (255 - ACover)) div 255,
                (GetGValue(InkRGB) * ACover +
                 GetGValue(BackRGB) * (255 - ACover)) div 255,
                (GetBValue(InkRGB) * ACover +
                 GetBValue(BackRGB) * (255 - ACover)) div 255);
end;

// Инь-ян крупно (сторона SmoothSide * SmoothScale): чёрное - значок, белое
// - пусто. Контур - тонкое кольцо, правая половина и нижний полукруг
// закрашены, точки: закрашенная вверху, пустая внизу.
procedure PaintYinYangBig(ACanvas: TCanvas);
const
  Big = SmoothSide * SmoothScale;   // 96
begin
  with ACanvas do
  begin
    Brush.Style := bsSolid;
    Brush.Color := clWhite;
    Pen.Color := clWhite;
    FillRect(Rect(0, 0, Big, Big));
    // Кольцо: чёрный круг и белый внутри, толщина 4 = 1 точка значка
    Brush.Color := clBlack;
    Pen.Color := clBlack;
    Ellipse(8, 8, 88, 88);
    Brush.Color := clWhite;
    Pen.Color := clWhite;
    Ellipse(13, 13, 83, 83);
    // Правая половина внутреннего круга
    Brush.Color := clBlack;
    Pen.Color := clBlack;
    Pie(13, 13, 83, 83, 48, 83, 48, 13);
    // Изгиб: верхний белый и нижний чёрный полукруги
    Brush.Color := clWhite;
    Pen.Color := clWhite;
    Ellipse(30, 13, 66, 48);
    Brush.Color := clBlack;
    Pen.Color := clBlack;
    Ellipse(30, 48, 66, 83);
    // Точки
    Ellipse(42, 24, 54, 36);
    Brush.Color := clWhite;
    Pen.Color := clWhite;
    Ellipse(42, 60, 54, 72);
  end;
end;

// AIcon = 'YinYang' - инь-ян, иначе значок по скрипту AScript
procedure DrawSmooth(ABmp: TBitmap; const AIcon, AScript: string;
                     AInk, ABack: TColor);
type
  TRGBLine = array[0..32767] of TRGBTriple;
  PRGBLine = ^TRGBLine;
var
  BigBmp: TBitmap;
  BigLines: array of PRGBLine;
  PosX, PosY, SubX, SubY, Cover, LineIdx: Integer;
  SumR, SumG, SumB, InkRGB, BackRGB: Longint;
  Sub: TRGBTriple;
  OutLine: PRGBLine;
  OutRGB: Longint;
begin
  InkRGB := ColorToRGB(AInk);
  BackRGB := ColorToRGB(ABack);
  BigBmp := TBitmap.Create;
  try
    BigBmp.PixelFormat := pf24bit;
    BigBmp.Width := SmoothSide * SmoothScale;
    BigBmp.Height := SmoothSide * SmoothScale;
    if CompareText(AIcon, 'YinYang') = 0 then
      PaintYinYangBig(BigBmp.Canvas)
    else
      // Значок по скрипту DsgIcons; пустой скрипт - пустой холст
      DsgPaintIcon(BigBmp.Canvas, AScript);
    SetLength(BigLines, BigBmp.Height);
    for LineIdx := 0 to BigBmp.Height - 1 do
      BigLines[LineIdx] := BigBmp.ScanLine[LineIdx];

    ABmp.PixelFormat := pf24bit;
    ABmp.Width := SmoothSide;
    ABmp.Height := SmoothSide;
    for PosY := 0 to SmoothSide - 1 do
    begin
      OutLine := ABmp.ScanLine[PosY];
      for PosX := 0 to SmoothSide - 1 do
      begin
        // Среднее по квадрату SmoothScale x SmoothScale: белое - фон,
        // чёрное - цвет значка AInk, остальное (части "@ цвет" скрипта) -
        // свой цвет. Ничего не нарисовано - прозрачный цвет кнопки.
        Cover := 0;
        SumR := 0;
        SumG := 0;
        SumB := 0;
        for SubY := 0 to SmoothScale - 1 do
          for SubX := 0 to SmoothScale - 1 do
          begin
            Sub := BigLines[PosY * SmoothScale + SubY]^
                     [PosX * SmoothScale + SubX];
            if (Sub.rgbtRed = 255) and (Sub.rgbtGreen = 255) and
               (Sub.rgbtBlue = 255) then
            begin
              Inc(SumR, GetRValue(BackRGB));
              Inc(SumG, GetGValue(BackRGB));
              Inc(SumB, GetBValue(BackRGB));
            end
            else
            begin
              Inc(Cover);
              if (Sub.rgbtRed = 0) and (Sub.rgbtGreen = 0) and
                 (Sub.rgbtBlue = 0) then
              begin
                Inc(SumR, GetRValue(InkRGB));
                Inc(SumG, GetGValue(InkRGB));
                Inc(SumB, GetBValue(InkRGB));
              end
              else
              begin
                Inc(SumR, Sub.rgbtRed);
                Inc(SumG, Sub.rgbtGreen);
                Inc(SumB, Sub.rgbtBlue);
              end;
            end;
          end;
        if Cover = 0 then
          OutRGB := ColorToRGB(SmoothKey)
        else
          OutRGB := RGB(SumR div (SmoothScale * SmoothScale),
                        SumG div (SmoothScale * SmoothScale),
                        SumB div (SmoothScale * SmoothScale));
        // Совпало с прозрачным цветом - сдвиг на единицу, иначе дыра
        if OutRGB = ColorToRGB(SmoothKey) then
          Inc(OutRGB);
        OutLine[PosX].rgbtRed := GetRValue(OutRGB);
        OutLine[PosX].rgbtGreen := GetGValue(OutRGB);
        OutLine[PosX].rgbtBlue := GetBValue(OutRGB);
      end;
    end;
  finally
    BigBmp.Free;
  end;
end;

// Значок класса (или 'Arrow', 'YinYang') - скрипт по имени из DsgIcons
procedure DsgDrawSmoothIcon(ABmp: TBitmap; const AIcon: string;
                            AInk, ABack: TColor);
begin
  if CompareText(AIcon, 'YinYang') = 0 then
    DrawSmooth(ABmp, AIcon, '', AInk, ABack)
  else
    DrawSmooth(ABmp, '', DsgIconScript(AIcon), AInk, ABack);
end;

procedure DsgDrawSmoothScript(ABmp: TBitmap; const AScript: string;
                              AInk, ABack: TColor);
begin
  DrawSmooth(ABmp, '', AScript, AInk, ABack);
end;

procedure DsgDrawSmoothMark(ABmp: TBitmap; AInk, ABack: TColor);
type
  TRGBLine = array[0..32767] of TRGBTriple;
  PRGBLine = ^TRGBLine;
const
  MarkSide = 7;
var
  BmpW, BmpH, PosX, PosY, SubX, SubY, Hits: Integer;
  SampleX, SampleY: Double;
  KeyRGB, PixRGB, OutRGB: Longint;
  Line: PRGBLine;
begin
  if ABmp.Empty then
    Exit;
  ABmp.PixelFormat := pf24bit;
  BmpW := ABmp.Width;
  BmpH := ABmp.Height;
  KeyRGB := ColorToRGB(ABmp.Canvas.Pixels[0, BmpH - 1]);
  for PosY := BmpH - MarkSide to BmpH - 1 do
  begin
    if PosY < 0 then
      Continue;
    Line := ABmp.ScanLine[PosY];
    for PosX := BmpW - MarkSide to BmpW - 1 do
    begin
      if PosX < 0 then
        Continue;
      // Треугольник: прямой угол в правом нижнем углу, катеты MarkSide;
      // покрытие - по 16 пробным точкам внутри пикселя
      Hits := 0;
      for SubY := 0 to SmoothScale - 1 do
        for SubX := 0 to SmoothScale - 1 do
        begin
          SampleX := PosX + (SubX + 0.5) / SmoothScale;
          SampleY := PosY + (SubY + 0.5) / SmoothScale;
          if SampleX + SampleY >= BmpW + BmpH - MarkSide then
            Inc(Hits);
        end;
      if Hits = 0 then
        Continue;
      PixRGB := RGB(Line[PosX].rgbtRed, Line[PosX].rgbtGreen,
                    Line[PosX].rgbtBlue);
      if PixRGB = KeyRGB then
        PixRGB := ColorToRGB(ABack);
      OutRGB := ColorToRGB(SmoothMix(AInk, PixRGB,
                                     Hits * 255 div (SmoothScale * SmoothScale)));
      Line[PosX].rgbtRed := GetRValue(OutRGB);
      Line[PosX].rgbtGreen := GetGValue(OutRGB);
      Line[PosX].rgbtBlue := GetBValue(OutRGB);
    end;
  end;
end;

{ TDsgGlyphInfo }

destructor TDsgGlyphInfo.Destroy;
begin
  Base.Free;
  inherited;
end;

function TDsgPalette.GlyphInfoOf(ABtn: TControl): TDsgGlyphInfo;
var
  InfoIdx: Integer;
begin
  Result := nil;
  for InfoIdx := 0 to FGlyphInfo.Count - 1 do
    if TDsgGlyphInfo(FGlyphInfo[InfoIdx]).Btn = ABtn then
    begin
      Result := TDsgGlyphInfo(FGlyphInfo[InfoIdx]);
      Exit;
    end;
end;

procedure TDsgPalette.SetGlyphInfo(ABtn: TControl; ABase: TBitmap;
                                   const ASmooth: string; AMark: Boolean);
var
  Info: TDsgGlyphInfo;
begin
  Info := GlyphInfoOf(ABtn);
  if Info = nil then
  begin
    Info := TDsgGlyphInfo.Create;
    Info.Btn := ABtn;
    FGlyphInfo.Add(Info);
  end;
  if Info.Base = nil then
    Info.Base := TBitmap.Create;
  if ABase <> nil then
    Info.Base.Assign(ABase)
  else
    Info.Base.Assign(nil);
  Info.Smooth := ASmooth;
  Info.Mark := AMark;
end;

function TDsgPalette.RenderGlyph(ABtn: TControl; ADark: Boolean;
                                 AInk, AMarkInk, ABack: TColor;
                                 ARecolor: TDsgRecolorProc;
                                 ABmp: TBitmap): Boolean;
var
  Info: TDsgGlyphInfo;
  Work: TBitmap;
begin
  Result := False;
  Info := GlyphInfoOf(ABtn);
  if Info = nil then
    Exit;
  if (Info.Smooth = '') and ((Info.Base = nil) or Info.Base.Empty) then
    Exit;
  // Строится отдельно и ставится целиком (Assign): правка через ScanLine
  // не сообщает кнопке, что значок сменился
  Work := TBitmap.Create;
  try
    if Info.Smooth <> '' then
      DsgDrawSmoothIcon(Work, Info.Smooth, AInk, ABack)
    else
    begin
      Work.Assign(Info.Base);
      if ADark and Assigned(ARecolor) then
        ARecolor(Work, Work.Canvas.Pixels[0, Work.Height - 1], AInk);
    end;
    if Info.Mark then
      DsgDrawSmoothMark(Work, AMarkInk, ABack);
    ABmp.Assign(Work);
  finally
    Work.Free;
  end;
  Result := True;
end;

// Значок своего компонента: значок похожего компонента Delphi (TUiButton -
// TButton, TUiScrollBar - TScrollBar), без метки - метку (сглаженный
// треугольник в правом нижнем углу) ставит RenderGlyph. У TUiTheme похожего
// нет - сглаженный инь-ян (ASmooth = 'YinYang'), ABmp - заготовка нужного
// размера.
function TDsgPalette.LoadCustomGlyph(AClass: TClass; ABmp: TBitmap;
                                     var ASmooth: string): Boolean;
var
  ClsName: string;
begin
  Result := False;
  ASmooth := '';
  ClsName := AClass.ClassName;
  if CompareText(Copy(ClsName, 1, 3), 'TUi') <> 0 then
    Exit;
  if CompareText(ClsName, 'TUiTheme') = 0 then
    ASmooth := 'YinYang'
  else if DsgIconScript(ClsName) <> '' then
    ASmooth := ClsName;     // значок аналога (TUiButton - TButton)
  if ASmooth <> '' then
    DsgDrawSmoothIcon(ABmp, ASmooth, clBlack, clBtnFace)
  else if not LoadGlyphByName('T' + Copy(ClsName, 4, MaxInt), ABmp) then
    Exit;
  Result := True;
end;

function TDsgPalette.LoadGlyphByName(const AName: string;
                                     ABmp: TBitmap): Boolean;
var
  I: Integer;
  Nm: string;
  H: HMODULE;
begin
  Result := False;
  Nm := UpperCase(AName);
  for I := 0 to FLibs.Count - 1 do
  begin
    H := HMODULE(FLibs[I]);
    if FindResource(H, PChar(Nm), RT_BITMAP) <> 0 then
    try
      ABmp.LoadFromResourceName(H, Nm);
      Result := True;
      Exit;
    except
      // повреждённый ресурс - ищем дальше
    end;
  end;
end;

procedure TDsgPalette.PlaceButton(ABtn: TSpeedButton; AClass: TComponentClass;
                                  APage: Integer; ACustom: Boolean);
var
  List: TList;
  Twin: TSpeedButton;
  X, Y, Size, W: Integer;
  HasGlyph: Boolean;
  SmoothName: string;
begin
  if (ABtn = nil) or (AClass = nil) or (APage < 0) or
     (APage >= FPageBtns.Count) then
    Exit;
  List := TList(FPageBtns[APage]);

  ABtn.Parent := FBox;
  ABtn.Visible := APage = CurPage;
  ABtn.Flat := True;
  ABtn.GroupIndex := 1;
  ABtn.AllowAllUp := True;
  ABtn.Tag := Integer(AClass);   // класс кнопки - для CompClick
  if ACustom then
    ABtn.Hint := AClass.ClassName + ' (Custom - вид по теме Light / Dark / Custom)'
  else
    ABtn.Hint := AClass.ClassName;
  ABtn.ShowHint := True;
  ABtn.OnClick := CompClick;
  TPaletteBtnAcc(ABtn).PopupMenu := FButtonPopup;
  ABtn.Caption := '';

  // Ширина - по значку или по надписи
  SmoothName := '';
  if ACustom then
  begin
    Size := CustomBtnSize;
    HasGlyph := LoadCustomGlyph(AClass, ABtn.Glyph, SmoothName);
  end
  else
  begin
    Size := BtnSize;
    // Свой сглаженный значок (DsgIcons); нет - значок из пакета Delphi
    if DsgIconScript(AClass.ClassName) <> '' then
    begin
      SmoothName := AClass.ClassName;
      DsgDrawSmoothIcon(ABtn.Glyph, SmoothName, clBlack, clBtnFace);
      HasGlyph := True;
    end
    else
      HasGlyph := LoadGlyph(AClass, ABtn.Glyph);
  end;
  // Исходный значок - для перестройки под тему; светлый вид - сейчас
  if HasGlyph then
  begin
    SetGlyphInfo(ABtn, ABtn.Glyph, SmoothName, ACustom);
    RenderGlyph(ABtn, False, clBlack, clTeal, FBox.Color, nil, ABtn.Glyph);
  end;
  W := Size;
  if not HasGlyph then
  begin
    // Значка нет - имя класса без T
    ABtn.Caption := Copy(AClass.ClassName, 2, MaxInt);
    FMeter.Canvas.Font := Font;
    W := FMeter.Canvas.TextWidth(ABtn.Caption) + 10;
    if W < Size then
      W := Size;
  end;

  if not ACustom then
  begin
    // Первый ряд - подряд слева направо
    X := FNextX[APage];
    Y := 1;
    FNextX[APage] := X + W + 1;
    Inc(FRow1Count[APage]);
  end
  else
  begin
    // Свой компонент - под одноимённым компонентом Delphi первого ряда
    // (TUiButton - под TButton). Нет такого на странице - следом за
    // предыдущим своим. Налезать на предыдущий свой не даём.
    Y := 1 + BtnSize + 1;
    Twin := StdButtonFor(AClass, List, FRow1Count[APage]);
    if Twin <> nil then
      X := Twin.Left
    else
      X := FNextFree[APage];
    if X < FNextFree[APage] then
      X := FNextFree[APage];
    FNextFree[APage] := X + W + 1;
  end;
  ABtn.SetBounds(X, Y, W, Size);
  List.Add(ABtn);
end;

// Кнопка первого ряда страницы (среди первых AFirstRowCount кнопок списка
// AList) с компонентом Delphi, похожим на свой ACustom: TUiButton -
// TButton. nil - нет такой.
function TDsgPalette.StdButtonFor(ACustom: TComponentClass; AList: TList;
                                  AFirstRowCount: Integer): TSpeedButton;
var
  Index: Integer;
  TwinName: string;
  Btn: TSpeedButton;
begin
  Result := nil;
  TwinName := ACustom.ClassName;
  if CompareText(Copy(TwinName, 1, 3), 'TUi') <> 0 then
    Exit;
  TwinName := 'T' + Copy(TwinName, 4, MaxInt);
  for Index := 0 to AFirstRowCount - 1 do
  begin
    Btn := TSpeedButton(AList[Index]);
    if CompareText(TComponentClass(Btn.Tag).ClassName, TwinName) = 0 then
    begin
      Result := Btn;
      Exit;
    end;
  end;
end;

procedure TDsgPalette.ShowPage;
var
  Page, I: Integer;
  List: TList;
  GlyphClass: string;
begin
  // Прокрутку - в начало до переключения: сдвиг прокрутки переносится на
  // все кнопки области, и у спрятанных тоже
  FBox.HorzScrollBar.Position := 0;
  // Значки сторонних на открытой странице - при первом её показе
  if (FGlyphPending.Count > 0) and (CurPage >= 0) and
     (CurPage < FPageBtns.Count) then
  begin
    List := TList(FPageBtns[CurPage]);
    for I := 0 to List.Count - 1 do
      if FGlyphPending.IndexOf(List[I]) >= 0 then
      begin
        FGlyphPending.Remove(List[I]);
        GlyphClass := ForeignOf(TControl(List[I]));
        GlyphClass := Copy(GlyphClass, Pos('.', GlyphClass) + 1, MaxInt);
        if LoadGlyphByName(GlyphClass, TSpeedButton(List[I]).Glyph) then
        begin
          SetGlyphInfo(TControl(List[I]), TSpeedButton(List[I]).Glyph, '',
                       False);
          if Assigned(FOnGlyphLoaded) then
            FOnGlyphLoaded(TSpeedButton(List[I]));
        end;
      end;
  end;
  for Page := 0 to FPageBtns.Count - 1 do
  begin
    List := TList(FPageBtns[Page]);
    for I := 0 to List.Count - 1 do
      TSpeedButton(List[I]).Visible := Page = CurPage;
  end;
  SetSelected(nil);
end;

function TDsgPalette.PageOf(ABtn: TControl): Integer;
var
  Page: Integer;
begin
  for Page := 0 to FPageBtns.Count - 1 do
    if TList(FPageBtns[Page]).IndexOf(ABtn) >= 0 then
    begin
      Result := Page;
      Exit;
    end;
  Result := -1;
end;

procedure TDsgPalette.TabChange(Sender: TObject);
begin
  ShowPage;
end;

// Страница открытой вкладки; вкладок нет - -1
function TDsgPalette.CurPage: Integer;
begin
  Result := -1;
  if (FTabs.TabIndex >= 0) and (FTabs.TabIndex < FTabPages.Count) then
    Result := Integer(FTabPages[FTabs.TabIndex]);
end;

procedure TDsgPalette.SetPageHidden(APage: Integer; AHidden: Boolean);
begin
  if (APage >= 0) and (APage < Length(FPageHidden)) then
    FPageHidden[APage] := AHidden;
end;

procedure TDsgPalette.ApplyPages;
var
  OldPage, Page, TabIdx: Integer;
begin
  OldPage := CurPage;
  FTabs.Tabs.BeginUpdate;
  try
    FTabs.Tabs.Clear;
    FTabPages.Clear;
    for Page := 0 to FPageNames.Count - 1 do
      if not FPageHidden[Page] then
      begin
        FTabs.Tabs.Add(FPageNames[Page]);
        FTabPages.Add(Pointer(Page));
      end;
  finally
    FTabs.Tabs.EndUpdate;
  end;
  TabIdx := FTabPages.IndexOf(Pointer(OldPage));
  if (TabIdx < 0) and (FTabPages.Count > 0) then
    TabIdx := 0;
  FTabs.TabIndex := TabIdx;
  ShowPage;
  CheckTabRows;
end;

procedure TDsgPalette.Resize;
begin
  inherited Resize;
  CheckTabRows;
end;

// Ряды вкладок: от низа верхнего ряда до низа нижнего - добавка к одному
procedure TDsgPalette.CheckTabRows;
var
  TabIdx, TopBottom, LowBottom, NewExtra: Integer;
  TabBox: TRect;
begin
  if (FTabs = nil) or not FTabs.HandleAllocated then
    Exit;
  TopBottom := MaxInt;
  LowBottom := 0;
  for TabIdx := 0 to FTabs.Tabs.Count - 1 do
  begin
    TabBox := FTabs.TabRect(TabIdx);
    if TabBox.Bottom <= TabBox.Top then
      Continue;
    if TabBox.Bottom < TopBottom then
      TopBottom := TabBox.Bottom;
    if TabBox.Bottom > LowBottom then
      LowBottom := TabBox.Bottom;
  end;
  if TopBottom = MaxInt then
    NewExtra := 0
  else
    NewExtra := LowBottom - TopBottom;
  if NewExtra = FTabRowsExtra then
    Exit;
  FTabRowsExtra := NewExtra;
  if Assigned(FOnTabRows) then
    FOnTabRows(Self);
end;

procedure TDsgPalette.ArrowClick(Sender: TObject);
begin
  SetSelected(nil);
end;

procedure TDsgPalette.CompClick(Sender: TObject);
var
  B: TSpeedButton;
begin
  B := TSpeedButton(Sender);
  if not B.Down then
    SetSelected(nil) // повторный щелчок по нажатой - выбор снят
  else if B.Tag = 0 then
  begin
    // Сторонний: класса нет, выбор - строкой
    FSelected := nil;
    FSelForeign := ForeignOf(B);
    if Assigned(FOnSelect) then
      FOnSelect(Self);
  end
  else
    SetSelected(TComponentClass(B.Tag));
end;

procedure TDsgPalette.SetSelected(AClass: TComponentClass);
begin
  FSelected := AClass;
  FSelForeign := '';
  if AClass = nil then
    FArrow.Down := True;
  if Assigned(FOnSelect) then
    FOnSelect(Self);
end;

procedure TDsgPalette.SetButtonPopup(AValue: TPopupMenu);
var
  PageIdx, BtnIdx: Integer;
  List: TList;
begin
  FButtonPopup := AValue;
  TPaletteBtnAcc(FArrow).PopupMenu := AValue;
  for PageIdx := 0 to FPageBtns.Count - 1 do
  begin
    List := TList(FPageBtns[PageIdx]);
    for BtnIdx := 0 to List.Count - 1 do
      if ForeignOf(TControl(List[BtnIdx])) = '' then
        TPaletteBtnAcc(List[BtnIdx]).PopupMenu := AValue;
  end;
end;

procedure TDsgPalette.RefreshSmooth(ALightBack: TColor; AButtons: TList);
var
  InfoIdx: Integer;
  Info: TDsgGlyphInfo;
  Back: TColor;
begin
  Back := ALightBack;
  if Back = clNone then
    Back := FBox.Color;
  for InfoIdx := 0 to FGlyphInfo.Count - 1 do
  begin
    Info := TDsgGlyphInfo(FGlyphInfo[InfoIdx]);
    if (Info.Smooth = '') or (CompareText(Info.Smooth, 'YinYang') = 0) or
       not (Info.Btn is TSpeedButton) then
      Continue;
    if RenderGlyph(Info.Btn, False, clBlack, clTeal, Back, nil,
                   TSpeedButton(Info.Btn).Glyph) and (AButtons <> nil) then
      AButtons.Add(Info.Btn);
  end;
end;

procedure TDsgPalette.ClearSelection;
begin
  SetSelected(nil);
end;

function TDsgPalette.AddPage(const AName: string): Integer;
begin
  FTabs.Tabs.Add(AName);
  CheckTabRows;
  FPageBtns.Add(TList.Create);
  Result := FPageBtns.Count - 1;
  FPageNames.Add(AName);
  SetLength(FPageHidden, Result + 1);
  FPageHidden[Result] := False;
  FTabPages.Add(Pointer(Result));
  SetLength(FNextX, Result + 1);
  SetLength(FRow1Count, Result + 1);
  SetLength(FNextFree, Result + 1);
  FNextX[Result] := FArrow.Left + BtnSize + 6;
  FRow1Count[Result] := 0;
  FNextFree[Result] := FArrow.Left + BtnSize + 6;
end;

procedure TDsgPalette.AddIconLib(const APath: string);
var
  LibHandle: HMODULE;
begin
  LibHandle := LoadLibraryEx(PChar(APath), 0, AsDataFile);
  if LibHandle <> 0 then
    FLibs.Add(Pointer(LibHandle));
end;

procedure TDsgPalette.PlaceForeign(ABtn: TSpeedButton; const AUnit, AClass,
                                   AHint: string; APage: Integer);
var
  BtnWidth, PosX: Integer;
begin
  if (ABtn = nil) or (APage < 0) or (APage >= FPageBtns.Count) then
    Exit;
  ABtn.Parent := FBox;
  ABtn.Visible := APage = CurPage;
  ABtn.Flat := True;
  ABtn.GroupIndex := 1;
  ABtn.AllowAllUp := True;
  ABtn.Tag := 0;                 // класса нет - выбор по FForeign
  ABtn.Hint := AHint;
  ABtn.ShowHint := True;
  ABtn.OnClick := CompClick;
  ABtn.Caption := '';
  BtnWidth := BtnSize;
  // Значок есть - прочитается при показе страницы (ShowPage); здесь только
  // проверка, есть ли он: от этого зависит ширина кнопки
  if HasGlyphRes(AClass) then
    FGlyphPending.Add(ABtn)
  else
  begin
    // Значка нет - имя класса без T
    ABtn.Caption := Copy(AClass, 2, MaxInt);
    FMeter.Canvas.Font := Font;
    BtnWidth := FMeter.Canvas.TextWidth(ABtn.Caption) + 10;
    if BtnWidth < BtnSize then
      BtnWidth := BtnSize;
  end;
  PosX := FNextX[APage];
  FNextX[APage] := PosX + BtnWidth + 1;
  Inc(FRow1Count[APage]);
  ABtn.SetBounds(PosX, 1, BtnWidth, BtnSize);
  TList(FPageBtns[APage]).Add(ABtn);
  FForeign.AddObject(AUnit + '.' + AClass, ABtn);
end;

function TDsgPalette.HasGlyphRes(const AName: string): Boolean;
var
  LibIdx: Integer;
  ResName: string;
begin
  Result := False;
  ResName := UpperCase(AName);
  for LibIdx := 0 to FLibs.Count - 1 do
    if FindResource(HMODULE(FLibs[LibIdx]), PChar(ResName), RT_BITMAP) <> 0 then
    begin
      Result := True;
      Exit;
    end;
end;

procedure TDsgPalette.PlaceRapidQ(ABtn: TSpeedButton; const AClass,
                                  AIconClass, AHint: string; APage: Integer);
var
  BtnWidth, PosX: Integer;
begin
  if (ABtn = nil) or (APage < 0) or (APage >= FPageBtns.Count) then
    Exit;
  ABtn.Parent := FBox;
  ABtn.Visible := APage = CurPage;
  ABtn.Flat := True;
  ABtn.GroupIndex := 1;
  ABtn.AllowAllUp := True;
  ABtn.Tag := 0;                 // класса VCL нет - выбор по FForeign
  ABtn.Hint := AHint;
  ABtn.ShowHint := True;
  ABtn.OnClick := CompClick;
  ABtn.Caption := '';
  BtnWidth := BtnSize;
  if (AIconClass <> '') and (DsgIconScript(AIconClass) <> '') then
  begin
    DsgDrawSmoothIcon(ABtn.Glyph, AIconClass, clBlack, clBtnFace);
    SetGlyphInfo(ABtn, ABtn.Glyph, AIconClass, False);
    RenderGlyph(ABtn, False, clBlack, clTeal, FBox.Color, nil, ABtn.Glyph);
  end
  else
  begin
    // Значка нет - имя класса без Q (QSTRINGLIST - STRINGLIST); класс
    // не на Q (ComPort из rapidqComponents.inc) - как есть
    if (AClass <> '') and (AClass[1] in ['Q', 'q']) then
      ABtn.Caption := Copy(AClass, 2, MaxInt)
    else
      ABtn.Caption := AClass;
    FMeter.Canvas.Font := Font;
    BtnWidth := FMeter.Canvas.TextWidth(ABtn.Caption) + 10;
    if BtnWidth < BtnSize then
      BtnWidth := BtnSize;
  end;
  PosX := FNextX[APage];
  FNextX[APage] := PosX + BtnWidth + 1;
  Inc(FRow1Count[APage]);
  ABtn.SetBounds(PosX, 1, BtnWidth, BtnSize);
  TList(FPageBtns[APage]).Add(ABtn);
  FForeign.AddObject('RapidQ.' + AClass, ABtn);
end;

procedure TDsgPalette.SetPage(APage: Integer);
var
  TabIdx: Integer;
begin
  TabIdx := FTabPages.IndexOf(Pointer(APage));
  if (TabIdx < 0) or (TabIdx = FTabs.TabIndex) then
    Exit;
  FTabs.TabIndex := TabIdx;
  ShowPage;
end;

function TDsgPalette.PageIndex: Integer;
begin
  Result := CurPage;
end;

function TDsgPalette.PageCount: Integer;
begin
  Result := FPageNames.Count;
end;

function TDsgPalette.ForeignOf(ABtn: TControl): string;
var
  ForeignIdx: Integer;
begin
  Result := '';
  ForeignIdx := FForeign.IndexOfObject(ABtn);
  if ForeignIdx >= 0 then
    Result := FForeign[ForeignIdx];
end;

end.
