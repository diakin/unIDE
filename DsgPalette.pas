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
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Controls, Forms, Graphics, ExtCtrls,
  ComCtrls, Buttons,
  UiComCtrls;     // вкладки палитры рисуются по теме (TUiTabControl)

type
  TDsgPalette = class(TPanel)
  private
    FTabs: TTabControl;
    FBox: TScrollBox;
    FArrow: TSpeedButton;
    FPageBtns: TList;         // по странице - TList её кнопок, в порядке постановки
    // Раскладка по странице: где следующая кнопка первого ряда, сколько в
    // нём кнопок, где первое свободное место второго ряда (свои компоненты)
    FNextX: array of Integer;
    FRow1Count: array of Integer;
    FNextFree: array of Integer;
    FMeter: TBitmap;          // замер ширины надписи: холст окна может ещё не быть
    FLibs: TList;             // HMODULE пакетов со значками
    FSelected: TComponentClass;
    FOnSelect: TNotifyEvent;
    procedure LoadLibs(const ADelphiBin: string);
    function LoadGlyph(AClass: TClass; ABmp: TBitmap): Boolean;
    function LoadGlyphByName(const AName: string; ABmp: TBitmap): Boolean;
    function LoadCustomGlyph(AClass: TClass; ABmp: TBitmap): Boolean;
    function StdButtonFor(ACustom: TComponentClass; AList: TList;
                          AFirstRowCount: Integer): TSpeedButton;
    procedure TabChange(Sender: TObject);
    procedure ArrowClick(Sender: TObject);
    procedure CompClick(Sender: TObject);
    procedure SetSelected(AClass: TComponentClass);
  public
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
    // Снять выбор: кнопка компонента отжимается, нажата стрелка
    procedure ClearSelection;
    property SelectedClass: TComponentClass read FSelected;
    property OnSelect: TNotifyEvent read FOnSelect write FOnSelect;
  end;

implementation

uses
  DsgClasses;

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
  FLibs := TList.Create;
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
  for I := 0 to DsgPageCount - 1 do
    FTabs.Tabs.Add(DsgPageName(I));
  FTabs.OnChange := TabChange;

  FBox := TScrollBox.Create(Self);
  FBox.Parent := FTabs;
  FBox.Align := alClient;
  FBox.BorderStyle := bsNone;
  FBox.VertScrollBar.Visible := False;
  FBox.HorzScrollBar.Tracking := True;

  FArrow := TSpeedButton.Create(Self);
  FArrow.Parent := FBox;
  FArrow.SetBounds(2, 1, BtnSize, BtnSize);
  FArrow.Flat := True;
  FArrow.GroupIndex := 1;
  FArrow.Down := True;
  FArrow.Hint := 'Выбор (без компонента)';
  FArrow.ShowHint := True;
  DrawArrow(FArrow.Glyph);
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

// Значок своего компонента: значок похожего компонента Delphi (TUiButton -
// TButton, TUiScrollBar - TScrollBar) того же размера, с меткой в правом
// нижнем углу - чтобы ряды отличались
function TDsgPalette.LoadCustomGlyph(AClass: TClass; ABmp: TBitmap): Boolean;
var
  ClsName: string;
  GlyphW, GlyphH: Integer;
  Back: TColor;
begin
  Result := False;
  ClsName := AClass.ClassName;
  if CompareText(Copy(ClsName, 1, 3), 'TUi') <> 0 then
    Exit;
  if not LoadGlyphByName('T' + Copy(ClsName, 4, MaxInt), ABmp) then
    Exit;
  GlyphW := ABmp.Width;
  GlyphH := ABmp.Height;
  // Левый нижний пиксель - прозрачный цвет кнопки: метка его не трогает
  Back := ABmp.Canvas.Pixels[0, GlyphH - 1];
  ABmp.Canvas.Brush.Color := clTeal;
  ABmp.Canvas.Pen.Color := clTeal;
  ABmp.Canvas.Polygon([Point(GlyphW - 1, GlyphH - MarkSize),
                       Point(GlyphW - 1, GlyphH - 1),
                       Point(GlyphW - MarkSize, GlyphH - 1)]);
  ABmp.Canvas.Pixels[0, GlyphH - 1] := Back;
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
begin
  if (ABtn = nil) or (AClass = nil) or (APage < 0) or
     (APage >= FPageBtns.Count) then
    Exit;
  List := TList(FPageBtns[APage]);

  ABtn.Parent := FBox;
  ABtn.Visible := APage = FTabs.TabIndex;
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
  ABtn.Caption := '';

  // Ширина - по значку или по надписи
  if ACustom then
  begin
    Size := CustomBtnSize;
    HasGlyph := LoadCustomGlyph(AClass, ABtn.Glyph);
  end
  else
  begin
    Size := BtnSize;
    HasGlyph := LoadGlyph(AClass, ABtn.Glyph);
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
begin
  // Прокрутку - в начало до переключения: сдвиг прокрутки переносится на
  // все кнопки области, и у спрятанных тоже
  FBox.HorzScrollBar.Position := 0;
  for Page := 0 to FPageBtns.Count - 1 do
  begin
    List := TList(FPageBtns[Page]);
    for I := 0 to List.Count - 1 do
      TSpeedButton(List[I]).Visible := Page = FTabs.TabIndex;
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

procedure TDsgPalette.ArrowClick(Sender: TObject);
begin
  SetSelected(nil);
end;

procedure TDsgPalette.CompClick(Sender: TObject);
var
  B: TSpeedButton;
begin
  B := TSpeedButton(Sender);
  if B.Down then
    SetSelected(TComponentClass(B.Tag))
  else
    SetSelected(nil); // повторный щелчок по нажатой - выбор снят
end;

procedure TDsgPalette.SetSelected(AClass: TComponentClass);
begin
  FSelected := AClass;
  if AClass = nil then
    FArrow.Down := True;
  if Assigned(FOnSelect) then
    FOnSelect(Self);
end;

procedure TDsgPalette.ClearSelection;
begin
  SetSelected(nil);
end;

end.
