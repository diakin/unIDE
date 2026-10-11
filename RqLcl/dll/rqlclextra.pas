// ---------------------------------------------------------------------------
//  RqLcl: QCANVAS (TPaintBox), QBITMAP (TRqBitmap), QSCROLLBAR (TScrollBar),
//  QTRACKBAR (TTrackBar), QSCROLLBOX (TScrollBox), QOVALBTN (TRqOvalBtn),
//  QOUTLINE (TRqOutline на TTreeView), QHEADER (TRqHeader на THeaderControl),
//  глобальный Printer (TRqPrinter - печать функциями Windows).
//  Свойства и методы, которых нет в RTTI LCL или которые у RapidQ другие.
//  Рисование на холсте (FillRect, TextOut...) - GridDraw / ImgDraw через
//  CanvasOf (rqlclmisc).
// ---------------------------------------------------------------------------
unit rqlclextra;

{$mode objfpc}{$H+}

interface

uses
  Windows, Classes, SysUtils, Types, Controls, StdCtrls, ExtCtrls, ComCtrls,
  Forms, Graphics, Buttons, Themes, WinSpool, Math, ImgList, LazUTF8,
  rqlclmisc;

type
  // QBITMAP: невидимая картинка с холстом
  TRqBitmap = class(TComponent)
  private
    FBitmap: TBitmap;
    FTop: Integer;
    function GetWidth: Integer;
    procedure SetWidth(AValue: Integer);
    function GetHeight: Integer;
    procedure SetHeight(AValue: Integer);
    function GetTransparent: Boolean;
    procedure SetTransparent(AValue: Boolean);
    function GetTransparentColor: TColor;
    procedure SetTransparentColor(AValue: TColor);
    function GetMonochrome: Boolean;
    procedure SetMonochrome(AValue: Boolean);
    function GetFont: TFont;
    procedure SetFont(AValue: TFont);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Bitmap: TBitmap read FBitmap;
  published
    property Width: Integer read GetWidth write SetWidth;
    property Height: Integer read GetHeight write SetHeight;
    property Transparent: Boolean read GetTransparent write SetTransparent;
    property TransparentColor: TColor read GetTransparentColor write SetTransparentColor;
    property Monochrome: Boolean read GetMonochrome write SetMonochrome;
    property Top: Integer read FTop write FTop;
    // шрифт холста картинки
    property Font: TFont read GetFont write SetFont;
  end;

  // QOVALBTN: кнопка-овал на основе TSpeedButton (картинка, Down,
  // GroupIndex, Layout, Spacing - от неё)
  TRqOvalBtn = class(TSpeedButton)
  private
    FColorHighLight: TColor;
    FColorShadow: TColor;
    FTransparentColor: TColor;
    procedure SetColorHighLight(AValue: TColor);
    procedure SetColorShadow(AValue: TColor);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Color;
    property ColorHighLight: TColor read FColorHighLight write SetColorHighLight;
    property ColorShadow: TColor read FColorShadow write SetColorShadow;
    property TransparentColor: TColor read FTransparentColor write FTransparentColor;
  end;

  // QOUTLINE: дерево в стиле Win 3.1 (TOutline Delphi) на TTreeView
  TRqOutline = class(TTreeView)
  private
    FOutlineStyle: Integer;
    FItemSeparator: string;
    FOutlineOptions: Integer;
    // картинки пунктов: 0 закрытый, 1 открытый, 2 лист (BMPClosed,
    // BMPOpen, BMPLeaf); список Images собирается из них
    FPictures: array[0..2] of TBitmap;
    FPictureList: TImageList;
    procedure SetOutlineStyle(AValue: Integer);
    procedure RebuildPictures;
    function PictureIndex(ANode: TTreeNode): Integer;
  protected
    procedure GetImageIndex(Node: TTreeNode); override;
    procedure GetSelectedIndex(Node: TTreeNode); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetPicture(ASlot: Integer; ABitmap: TBitmap);
    procedure ApplyOptions;
    property OutlineOptions: Integer read FOutlineOptions write FOutlineOptions;
  published
    property OutlineStyle: Integer read FOutlineStyle write SetOutlineStyle;
    property ItemSeparator: string read FItemSeparator write FItemSeparator;
  end;

  TRqDrawSectionEvent = procedure(Sender: TObject; AIndex, APressed: Integer;
                                  ARect: TRect) of object;

  // QHEADER: заголовки столбцов; у секции ещё Style (0 hsText, 1
  // hsOwnerDraw) и AllowClick, как у THeaderControl Delphi
  TRqHeader = class(THeaderControl)
  private
    FStyles: array of Integer;
    FNoClick: array of Boolean;
    FOnDrawSection: TRqDrawSectionEvent;
    procedure GrowExtra(AIndex: Integer);
  protected
    procedure SectionClick(Section: THeaderSection); override;
  public
    procedure PaintSection(Index: Integer); override;
    function GetSectionStyle(AIndex: Integer): Integer;
    procedure SetSectionStyle(AIndex, AValue: Integer);
    function GetAllowClick(AIndex: Integer): Boolean;
    procedure SetAllowClick(AIndex: Integer; AValue: Boolean);
  published
    property OnDrawSection: TRqDrawSectionEvent read FOnDrawSection write FOnDrawSection;
  end;

  // Printer RapidQ: печать функциями Windows (StartDoc, StartPage...),
  // холст - на DC принтера
  TRqPrinter = class(TComponent)
  private
    FNames: TStringList;
    FPorts: TStringList;
    FIndex: Integer;
    FCopies: Integer;
    FOrientation: Integer;
    FTitle: string;
    FDC: HDC;
    FCanvas: TCanvas;
    FPrinting: Boolean;
    FAborted: Boolean;
    FPageNumber: Integer;
    FFont: TFont;
    FCopyMode: Integer;
    procedure LoadPrinters;
    function CurrentName: string;
    function CreatePrinterDC(AInfoOnly: Boolean): HDC;
    function GetFont: TFont;
    procedure SetFont(AValue: TFont);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Canvas: TCanvas;
    procedure BeginDoc;
    procedure NewPage;
    procedure EndDoc;
    procedure Abort;
    function PageSize(AHeight: Boolean): Integer;
    function Capability(ACap: Word): Integer;
    property Names: TStringList read FNames;
  published
    property Font: TFont read GetFont write SetFont;
  end;

function ExtraGlobalObject(const AClassName: string): TObject;
function ExtraIsGlobal(AObj: TObject): Boolean;
// Холст объектов этого модуля; nil - не наш
function ExtraCanvasOf(AObj: TObject): TCanvas;
procedure ExtraInitNew(AObj: TObject);

function ExtraGetInt(AObj: TObject; const AProp: string;
                     out AValue: Integer): Boolean;
function ExtraSetInt(AObj: TObject; const AProp: string;
                     AValue: Integer): Boolean;
function ExtraGetStr(AObj: TObject; const AProp: string;
                     out AValue: string): Boolean;
function ExtraSetStr(AObj: TObject; const AProp: string;
                     const AValue: string): Boolean;
function ExtraGetItem(AObj: TObject; const AProp: string; AIndex: Integer;
                      out AValue: string): Boolean;
function ExtraSetItem(AObj: TObject; const AProp: string; AIndex: Integer;
                      const AValue: string): Boolean;
function ExtraGetItemInt(AObj: TObject; const AProp: string; AIndex: Integer;
                         out AValue: Integer): Boolean;
function ExtraSetItemInt(AObj: TObject; const AProp: string; AIndex: Integer;
                         AValue: Integer): Boolean;
function ExtraCallEx(AObj: TObject; const AMethod, AStr: string;
                     AInt1, AInt2, AInt3: Integer;
                     out AIntResult: Integer): Boolean;

implementation

var
  PrinterObj: TRqPrinter = nil;

const
  DC_COLLATE = 22;

function DeviceCapabilitiesA(ADevice, APort: PChar; ACapability: Word;
                             AOutput: PChar; ADevMode: Pointer): LongInt;
  stdcall; external 'winspool.drv' name 'DeviceCapabilitiesA';

// Ресурс $RESOURCE - в картинку; нет ресурса - ошибка
procedure LoadResBitmap(AResId: Integer; ABitmap: TBitmap);
var
  ResStream: TStream;
begin
  ResStream := MiscResourceStream(AResId);
  if ResStream = nil then
    raise Exception.Create('BMPHandle: no resource ' + IntToStr(AResId));
  try
    ABitmap.LoadFromStream(ResStream);
  finally
    ResStream.Free;
  end;
end;

// Картинка пункта QOUTLINE по имени свойства (BMPClosed, BMPHandleOpen...):
// номер места 0..2; BMPPlus / BMPMinus - 3 (принимаются, не показываются:
// у TTreeView кнопки +/- свои); не картинка - -1
function OutlineSlot(const AProp: string): Integer;
var
  Name: string;
begin
  Result := -1;
  Name := AProp;
  if Copy(Name, 1, 9) = 'BMPHANDLE' then
    Delete(Name, 1, 9)
  else if Copy(Name, 1, 3) = 'BMP' then
    Delete(Name, 1, 3)
  else
    Exit;
  if Name = 'CLOSED' then
    Result := 0
  else if Name = 'OPEN' then
    Result := 1
  else if Name = 'LEAF' then
    Result := 2
  else if (Name = 'PLUS') or (Name = 'MINUS') then
    Result := 3;
end;

procedure CheckIndex(const AWhat: string; AIndex, ACount: Integer);
begin
  if (AIndex < 0) or (AIndex >= ACount) then
    raise Exception.Create(AWhat + '(' + IntToStr(AIndex) + '): out of 0..' +
                           IntToStr(ACount - 1));
end;

// ---------------------------------------------------------------------------
//  TRqBitmap
// ---------------------------------------------------------------------------

constructor TRqBitmap.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBitmap := TBitmap.Create;
end;

destructor TRqBitmap.Destroy;
begin
  FBitmap.Free;
  inherited Destroy;
end;

function TRqBitmap.GetWidth: Integer;
begin
  Result := FBitmap.Width;
end;

procedure TRqBitmap.SetWidth(AValue: Integer);
begin
  FBitmap.Width := AValue;
end;

function TRqBitmap.GetHeight: Integer;
begin
  Result := FBitmap.Height;
end;

procedure TRqBitmap.SetHeight(AValue: Integer);
begin
  FBitmap.Height := AValue;
end;

function TRqBitmap.GetTransparent: Boolean;
begin
  Result := FBitmap.Transparent;
end;

procedure TRqBitmap.SetTransparent(AValue: Boolean);
begin
  FBitmap.Transparent := AValue;
end;

function TRqBitmap.GetTransparentColor: TColor;
begin
  Result := FBitmap.TransparentColor;
end;

procedure TRqBitmap.SetTransparentColor(AValue: TColor);
begin
  FBitmap.TransparentColor := AValue;
end;

function TRqBitmap.GetMonochrome: Boolean;
begin
  Result := FBitmap.Monochrome;
end;

procedure TRqBitmap.SetMonochrome(AValue: Boolean);
begin
  FBitmap.Monochrome := AValue;
end;

function TRqBitmap.GetFont: TFont;
begin
  Result := FBitmap.Canvas.Font;
end;

procedure TRqBitmap.SetFont(AValue: TFont);
begin
  FBitmap.Canvas.Font.Assign(AValue);
end;

// ---------------------------------------------------------------------------
//  TRqOvalBtn
// ---------------------------------------------------------------------------

constructor TRqOvalBtn.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Color := clBtnFace;
  FColorHighLight := clBtnHighlight;
  FColorShadow := clBtnShadow;
  FTransparentColor := clNone;
end;

procedure TRqOvalBtn.SetColorHighLight(AValue: TColor);
begin
  FColorHighLight := AValue;
  Invalidate;
end;

procedure TRqOvalBtn.SetColorShadow(AValue: TColor);
begin
  FColorShadow := AValue;
  Invalidate;
end;

// Овал цвета Color; рамка - светлая сверху слева, тёмная снизу справа
// (нажата - наоборот); картинка и текст - по центру
procedure TRqOvalBtn.Paint;
var
  OvalRect: TRect;
  Pressed: Boolean;
  TopColor, BottomColor: TColor;
  TextSize: TSize;
  ContentWidth, ContentHeight, StartX, StartY, Shift, GlyphWidth: Integer;
  GlyphIdx: Integer;
  PartBitmap: TBitmap;
begin
  OvalRect := Rect(1, 1, Width - 1, Height - 1);
  Pressed := (FState in [bsDown, bsExclusive]) or Down;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := Color;
  Canvas.Pen.Color := Color;
  Canvas.Pen.Width := 1;
  Canvas.Ellipse(OvalRect);
  if not Flat or MouseInControl or Pressed then
  begin
    if Pressed then
    begin
      TopColor := FColorShadow;
      BottomColor := FColorHighLight;
    end
    else
    begin
      TopColor := FColorHighLight;
      BottomColor := FColorShadow;
    end;
    Canvas.Pen.Width := 2;
    Canvas.Pen.Color := TopColor;
    Canvas.Arc(OvalRect.Left, OvalRect.Top, OvalRect.Right, OvalRect.Bottom,
               OvalRect.Right, OvalRect.Top, OvalRect.Left, OvalRect.Bottom);
    Canvas.Pen.Color := BottomColor;
    Canvas.Arc(OvalRect.Left, OvalRect.Top, OvalRect.Right, OvalRect.Bottom,
               OvalRect.Left, OvalRect.Bottom, OvalRect.Right, OvalRect.Top);
    Canvas.Pen.Width := 1;
  end;
  Shift := Ord(Pressed);
  GlyphWidth := 0;
  if not Glyph.Empty then
    GlyphWidth := Glyph.Width div Max(1, NumGlyphs);
  Canvas.Font := Font;
  if not Enabled then
    Canvas.Font.Color := clGrayText;
  TextSize := Canvas.TextExtent(Caption);
  ContentWidth := GlyphWidth + TextSize.cx;
  if (GlyphWidth > 0) and (Caption <> '') then
    Inc(ContentWidth, Max(0, Spacing));
  ContentHeight := Max(TextSize.cy, Glyph.Height);
  StartX := (Width - ContentWidth) div 2 + Shift;
  StartY := (Height - ContentHeight) div 2 + Shift;
  if GlyphWidth > 0 then
  begin
    // NumBMPs: 1 - обычная, 2 - недоступная, 3 - нажатая
    GlyphIdx := 0;
    if not Enabled and (NumGlyphs >= 2) then
      GlyphIdx := 1
    else if Pressed and (NumGlyphs >= 3) then
      GlyphIdx := 2;
    PartBitmap := TBitmap.Create;
    try
      PartBitmap.SetSize(GlyphWidth, Glyph.Height);
      PartBitmap.Canvas.CopyRect(Rect(0, 0, GlyphWidth, Glyph.Height),
                                 Glyph.Canvas,
                                 Rect(GlyphIdx * GlyphWidth, 0,
                                      (GlyphIdx + 1) * GlyphWidth, Glyph.Height));
      // прозрачный цвет: TransparentColor или левая нижняя точка
      PartBitmap.Transparent := True;
      if FTransparentColor <> clNone then
        PartBitmap.TransparentColor := FTransparentColor;
      Canvas.Draw(StartX, StartY + (ContentHeight - Glyph.Height) div 2,
                  PartBitmap);
    finally
      PartBitmap.Free;
    end;
    Inc(StartX, GlyphWidth + Max(0, Spacing));
  end;
  if Caption <> '' then
  begin
    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(StartX, StartY + (ContentHeight - TextSize.cy) div 2, Caption);
  end;
end;

// ---------------------------------------------------------------------------
//  TRqOutline
// ---------------------------------------------------------------------------

constructor TRqOutline.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItemSeparator := '\';
  FOutlineOptions := 1 or 2;   // ooDrawTreeRoot, ooDrawFocusRect
  ReadOnly := True;
  SetOutlineStyle(5);          // osTreePictureText
end;

destructor TRqOutline.Destroy;
var
  SlotIdx: Integer;
begin
  for SlotIdx := 0 to 2 do
    FPictures[SlotIdx].Free;
  inherited Destroy;
end;

procedure TRqOutline.SetPicture(ASlot: Integer; ABitmap: TBitmap);
begin
  if FPictures[ASlot] = nil then
    FPictures[ASlot] := TBitmap.Create;
  FPictures[ASlot].Assign(ABitmap);
  RebuildPictures;
end;

// Список картинок размером первой заданной; пустые места - пустые картинки
procedure TRqOutline.RebuildPictures;
var
  SlotIdx, PicWidth, PicHeight: Integer;
  Blank: TBitmap;
begin
  PicWidth := 0;
  PicHeight := 0;
  for SlotIdx := 0 to 2 do
    if (FPictures[SlotIdx] <> nil) and not FPictures[SlotIdx].Empty then
    begin
      PicWidth := FPictures[SlotIdx].Width;
      PicHeight := FPictures[SlotIdx].Height;
      Break;
    end;
  if PicWidth = 0 then
  begin
    Images := nil;
    Exit;
  end;
  if FPictureList = nil then
    FPictureList := TImageList.Create(Self);
  FPictureList.Clear;
  FPictureList.Width := PicWidth;
  FPictureList.Height := PicHeight;
  Blank := TBitmap.Create;
  try
    Blank.SetSize(PicWidth, PicHeight);
    for SlotIdx := 0 to 2 do
      if (FPictures[SlotIdx] <> nil) and not FPictures[SlotIdx].Empty and
         (FPictures[SlotIdx].Width = PicWidth) and
         (FPictures[SlotIdx].Height = PicHeight) then
        FPictureList.Add(FPictures[SlotIdx], nil)
      else
        FPictureList.Add(Blank, nil);
  finally
    Blank.Free;
  end;
  Images := FPictureList;
  Invalidate;
end;

function TRqOutline.PictureIndex(ANode: TTreeNode): Integer;
begin
  if not ANode.HasChildren then
    Result := 2
  else if ANode.Expanded then
    Result := 1
  else
    Result := 0;
  if (FPictures[Result] = nil) or FPictures[Result].Empty then
    Result := -1;
end;

procedure TRqOutline.GetImageIndex(Node: TTreeNode);
begin
  Node.ImageIndex := PictureIndex(Node);
  inherited GetImageIndex(Node);
end;

procedure TRqOutline.GetSelectedIndex(Node: TTreeNode);
begin
  Node.SelectedIndex := PictureIndex(Node);
  inherited GetSelectedIndex(Node);
end;

// osText 0, osPlusMinusText 1, osPictureText 2, osPlusMinusPictureText 3,
// osTreeText 4, osTreePictureText 5: линии - у 4, 5; кнопки +/- - у 1, 3
procedure TRqOutline.SetOutlineStyle(AValue: Integer);
begin
  FOutlineStyle := AValue;
  ShowLines := AValue in [4, 5];
  ShowButtons := AValue in [1, 3, 4, 5];
end;

// ooDrawTreeRoot (бит 0) - ShowRoot
procedure TRqOutline.ApplyOptions;
begin
  ShowRoot := (FOutlineOptions and 1) <> 0;
end;

// ---------------------------------------------------------------------------
//  TRqHeader
// ---------------------------------------------------------------------------

procedure TRqHeader.GrowExtra(AIndex: Integer);
var
  OldLen, ItemIdx: Integer;
begin
  if AIndex < Length(FStyles) then
    Exit;
  OldLen := Length(FStyles);
  SetLength(FStyles, AIndex + 1);
  SetLength(FNoClick, AIndex + 1);
  for ItemIdx := OldLen to AIndex do
  begin
    FStyles[ItemIdx] := 0;
    FNoClick[ItemIdx] := False;
  end;
end;

function TRqHeader.GetSectionStyle(AIndex: Integer): Integer;
begin
  Result := 0;
  if AIndex < Length(FStyles) then
    Result := FStyles[AIndex];
end;

procedure TRqHeader.SetSectionStyle(AIndex, AValue: Integer);
begin
  GrowExtra(AIndex);
  FStyles[AIndex] := AValue;
  Invalidate;
end;

function TRqHeader.GetAllowClick(AIndex: Integer): Boolean;
begin
  Result := True;
  if AIndex < Length(FNoClick) then
    Result := not FNoClick[AIndex];
end;

procedure TRqHeader.SetAllowClick(AIndex: Integer; AValue: Boolean);
begin
  GrowExtra(AIndex);
  FNoClick[AIndex] := not AValue;
end;

procedure TRqHeader.SectionClick(Section: THeaderSection);
begin
  if GetAllowClick(Section.Index) then
    inherited SectionClick(Section);
end;

// hsOwnerDraw: рамка секции - как обычно, содержимое рисует OnDrawSection
procedure TRqHeader.PaintSection(Index: Integer);
var
  Section: THeaderSection;
  SectionRect, ContentRect: TRect;
  Details: TThemedElementDetails;
begin
  if (GetSectionStyle(Index) <> 1) or not Assigned(FOnDrawSection) then
  begin
    inherited PaintSection(Index);
    Exit;
  end;
  Section := Sections[Index];
  if not Section.Visible then
    Exit;
  SectionRect := Rect(Section.Left, 0, Section.Right, ClientHeight);
  if SectionRect.Right <= SectionRect.Left then
    Exit;
  case Section.State of
    hsHot: Details := ThemeServices.GetElementDetails(thHeaderItemHot);
    hsPressed: Details := ThemeServices.GetElementDetails(thHeaderItemPressed);
  else
    Details := ThemeServices.GetElementDetails(thHeaderItemNormal);
  end;
  ThemeServices.DrawElement(Canvas.Handle, Details, SectionRect);
  ContentRect := SectionRect;
  InflateRect(ContentRect, -2, -2);
  FOnDrawSection(Self, Index, Ord(Section.State = hsPressed), ContentRect);
end;

// ---------------------------------------------------------------------------
//  TRqPrinter
// ---------------------------------------------------------------------------

constructor TRqPrinter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FNames := TStringList.Create;
  FPorts := TStringList.Create;
  FCopies := 1;
  FCopyMode := $CC0020;   // cmSrcCopy (код Windows, см. MiscCopyModeToLcl)
  FIndex := -1;
  FTitle := '';
  LoadPrinters;
end;

destructor TRqPrinter.Destroy;
begin
  if FPrinting then
    Abort;
  FCanvas.Free;
  FFont.Free;
  FNames.Free;
  FPorts.Free;
  inherited Destroy;
end;

// Список принтеров (EnumPrinters, уровень 2: имя и порт); текущий - по
// умолчанию Windows
procedure TRqPrinter.LoadPrinters;
var
  Needed, Returned, ItemIdx: DWORD;
  Buffer: array of Byte;
  InfoPtr: PPRINTER_INFO_2A;
  DefaultName: array[0..511] of Char;
  NameLen: DWORD;
begin
  FNames.Clear;
  FPorts.Clear;
  Needed := 0;
  Returned := 0;
  EnumPrintersA(PRINTER_ENUM_LOCAL or PRINTER_ENUM_CONNECTIONS, nil, 2, nil, 0,
                @Needed, @Returned);
  if Needed > 0 then
  begin
    SetLength(Buffer, Needed);
    if EnumPrintersA(PRINTER_ENUM_LOCAL or PRINTER_ENUM_CONNECTIONS, nil, 2,
                     @Buffer[0], Needed, @Needed, @Returned) then
    begin
      InfoPtr := PPRINTER_INFO_2A(@Buffer[0]);
      for ItemIdx := 1 to Returned do
      begin
        FNames.Add(string(InfoPtr^.pPrinterName));
        FPorts.Add(string(InfoPtr^.pPortName));
        Inc(InfoPtr);
      end;
    end;
  end;
  FIndex := -1;
  if FNames.Count > 0 then
  begin
    FIndex := 0;
    NameLen := SizeOf(DefaultName);
    if GetDefaultPrinterA(@DefaultName[0], @NameLen) and
       (FNames.IndexOf(string(PChar(@DefaultName[0]))) >= 0) then
      FIndex := FNames.IndexOf(string(PChar(@DefaultName[0])));
  end;
end;

function TRqPrinter.CurrentName: string;
begin
  if (FIndex < 0) or (FIndex >= FNames.Count) then
    raise Exception.Create('no printer');
  Result := FNames[FIndex];
end;

// DC принтера с Orientation и Copies (DEVMODE драйвера); AInfoOnly - только
// для сведений (размер страницы)
function TRqPrinter.CreatePrinterDC(AInfoOnly: Boolean): HDC;
var
  PrinterName: string;
  PrinterHandle: THandle;
  ModeSize: LongInt;
  ModeBuf: array of Byte;
  ModePtr: PDeviceMode;
begin
  PrinterName := CurrentName;
  ModePtr := nil;
  if OpenPrinterA(PChar(PrinterName), @PrinterHandle, nil) then
  try
    ModeSize := DocumentPropertiesA(0, PrinterHandle, PChar(PrinterName), nil, nil, 0);
    if ModeSize > 0 then
    begin
      SetLength(ModeBuf, ModeSize);
      ModePtr := PDeviceMode(@ModeBuf[0]);
      if DocumentPropertiesA(0, PrinterHandle, PChar(PrinterName), ModePtr, nil,
                             DM_OUT_BUFFER) = IDOK then
      begin
        ModePtr^.dmFields := ModePtr^.dmFields or DM_ORIENTATION or DM_COPIES;
        if FOrientation = 1 then
          ModePtr^.dmOrientation := DMORIENT_LANDSCAPE
        else
          ModePtr^.dmOrientation := DMORIENT_PORTRAIT;
        ModePtr^.dmCopies := Max(1, FCopies);
      end
      else
        ModePtr := nil;
    end;
  finally
    ClosePrinter(PrinterHandle);
  end;
  if AInfoOnly then
    Result := CreateICA('WINSPOOL', PChar(PrinterName), nil, ModePtr)
  else
    Result := CreateDCA('WINSPOOL', PChar(PrinterName), nil, ModePtr);
  if Result = 0 then
    raise Exception.Create('cannot open printer "' + PrinterName + '"');
end;

function TRqPrinter.GetFont: TFont;
begin
  if FFont = nil then
    FFont := TFont.Create;
  Result := FFont;
end;

procedure TRqPrinter.SetFont(AValue: TFont);
begin
  GetFont.Assign(AValue);
  if FCanvas <> nil then
    FCanvas.Font.Assign(AValue);
end;

// Холст есть только между BeginDoc и EndDoc
function TRqPrinter.Canvas: TCanvas;
begin
  if not FPrinting then
    raise Exception.Create('Printer: BeginDoc first');
  Result := FCanvas;
end;

procedure TRqPrinter.BeginDoc;
var
  DocInfo: TDocInfoA;
  TitleText: string;
begin
  if FPrinting then
    raise Exception.Create('Printer: already printing');
  FDC := CreatePrinterDC(False);
  TitleText := FTitle;
  if TitleText = '' then
    TitleText := 'RapidQ';
  FillChar(DocInfo, SizeOf(DocInfo), 0);
  DocInfo.cbSize := SizeOf(DocInfo);
  DocInfo.lpszDocName := PChar(TitleText);
  if StartDocA(FDC, @DocInfo) <= 0 then
  begin
    DeleteDC(FDC);
    FDC := 0;
    raise Exception.Create('Printer: StartDoc failed');
  end;
  StartPage(FDC);
  if FCanvas = nil then
    FCanvas := TCanvas.Create;
  FCanvas.Handle := FDC;
  if FFont <> nil then
    FCanvas.Font.Assign(FFont);
  FCanvas.CopyMode := MiscCopyModeToLcl(FCopyMode);
  FPrinting := True;
  FAborted := False;
  FPageNumber := 1;
end;

procedure TRqPrinter.NewPage;
begin
  if not FPrinting then
    raise Exception.Create('Printer: BeginDoc first');
  EndPage(FDC);
  StartPage(FDC);
  FCanvas.Handle := 0;
  FCanvas.Handle := FDC;
  Inc(FPageNumber);
end;

procedure TRqPrinter.EndDoc;
begin
  if not FPrinting then
    raise Exception.Create('Printer: BeginDoc first');
  FCanvas.Handle := 0;
  EndPage(FDC);
  Windows.EndDoc(FDC);
  DeleteDC(FDC);
  FDC := 0;
  FPrinting := False;
end;

procedure TRqPrinter.Abort;
begin
  if not FPrinting then
    Exit;
  FCanvas.Handle := 0;
  AbortDoc(FDC);
  DeleteDC(FDC);
  FDC := 0;
  FPrinting := False;
  FAborted := True;
end;

function TRqPrinter.PageSize(AHeight: Boolean): Integer;
var
  InfoDC: HDC;
begin
  if FPrinting then
    InfoDC := FDC
  else
    InfoDC := CreatePrinterDC(True);
  try
    if AHeight then
      Result := GetDeviceCaps(InfoDC, VERTRES)
    else
      Result := GetDeviceCaps(InfoDC, HORZRES);
  finally
    if not FPrinting then
      DeleteDC(InfoDC);
  end;
end;

// Capabilities: DC_COPIES - число копий (> 1 - умеет), DC_ORIENTATION,
// DC_COLLATE
function TRqPrinter.Capability(ACap: Word): Integer;
var
  PortName: string;
begin
  CurrentName;
  PortName := FPorts[FIndex];
  Result := DeviceCapabilitiesA(PChar(FNames[FIndex]), PChar(PortName), ACap,
                                nil, nil);
  if Result < 0 then
    Result := 0;
end;

// ---------------------------------------------------------------------------
//  Общее
// ---------------------------------------------------------------------------

function ExtraGlobalObject(const AClassName: string): TObject;
begin
  Result := nil;
  if UpperCase(AClassName) = 'QPRINTER' then
  begin
    if PrinterObj = nil then
      PrinterObj := TRqPrinter.Create(nil);
    Result := PrinterObj;
  end;
end;

function ExtraIsGlobal(AObj: TObject): Boolean;
begin
  Result := (AObj <> nil) and (AObj = PrinterObj);
end;

// У QCANVAS и Printer шрифт холста - Font объекта (рисовать можно и вне
// OnPaint)
function ExtraCanvasOf(AObj: TObject): TCanvas;
begin
  Result := nil;
  if AObj is TPaintBox then
  begin
    Result := TPaintBox(AObj).Canvas;
    if not Result.Font.IsEqual(TPaintBox(AObj).Font) then
      Result.Font.Assign(TPaintBox(AObj).Font);
  end
  else if AObj is TRqBitmap then
    Result := TRqBitmap(AObj).Bitmap.Canvas
  else if AObj is TCustomHeaderControl then
    Result := TCustomHeaderControl(AObj).Canvas
  else if AObj is TRqPrinter then
  begin
    Result := TRqPrinter(AObj).Canvas;
    if not Result.Font.IsEqual(TRqPrinter(AObj).Font) then
      Result.Font.Assign(TRqPrinter(AObj).Font);
  end;
end;

// Значения по умолчанию RapidQ
procedure ExtraInitNew(AObj: TObject);
begin
  if AObj is TRqOvalBtn then
  begin
    TRqOvalBtn(AObj).Width := 75;
    TRqOvalBtn(AObj).Height := 25;
  end
  else if AObj is TScrollBox then
    TScrollBox(AObj).AutoScroll := True;
end;

function ScrollBarOf(AObj: TObject; const AProp: string;
                     out ARest: string): TControlScrollBar;
begin
  Result := nil;
  ARest := '';
  if not (AObj is TScrollingWinControl) or (AObj is TCustomForm) then
    Exit;
  if Copy(AProp, 1, 4) = 'HORZ' then
    Result := TScrollingWinControl(AObj).HorzScrollBar
  else if Copy(AProp, 1, 4) = 'VERT' then
    Result := TScrollingWinControl(AObj).VertScrollBar;
  if Result <> nil then
    ARest := Copy(AProp, 5, MaxInt);
end;

function ExtraGetInt(AObj: TObject; const AProp: string;
                     out AValue: Integer): Boolean;
var
  Prop, Rest: string;
  ScrollBar: TControlScrollBar;
begin
  Result := False;
  AValue := 0;
  Prop := UpperCase(AProp);
  ScrollBar := ScrollBarOf(AObj, Prop, Rest);
  if ScrollBar <> nil then
  begin
    Result := True;
    if Rest = 'INCREMENT' then
      AValue := ScrollBar.Increment
    else if Rest = 'POSITION' then
      AValue := ScrollBar.Position
    else if Rest = 'RANGE' then
      AValue := ScrollBar.Range
    else if Rest = 'TRACKING' then
      AValue := Ord(ScrollBar.Tracking)
    else if Rest = 'VISIBLE' then
      AValue := Ord(ScrollBar.Visible)
    // в LCL нет: всегда 0
    else if Rest = 'MARGIN' then
      AValue := 0
    else
      Result := False;
  end
  else if AObj is TRqBitmap then
  begin
    Result := True;
    // пустая - без размера (LCL считает пустой и картинку без данных)
    if Prop = 'EMPTY' then
      AValue := Ord((TRqBitmap(AObj).Bitmap.Width = 0) or
                    (TRqBitmap(AObj).Bitmap.Height = 0))
    else if Prop = 'PIXELFORMAT' then
      AValue := Ord(TRqBitmap(AObj).Bitmap.PixelFormat)
    else if Prop = 'TRANSPARENTMODE' then
      AValue := Ord(TRqBitmap(AObj).Bitmap.TransparentMode)
    else if Prop = 'HANDLE' then
      AValue := Integer(TRqBitmap(AObj).Bitmap.Handle)
    else
      Result := False;
  end
  else if AObj is TRqOutline then
  begin
    Result := True;
    if (Prop = 'LINECOUNT') or (Prop = 'ITEMCOUNT') then
      AValue := TRqOutline(AObj).Items.Count
    else if (Prop = 'ITEMINDEX') or (Prop = 'ROW') then
    begin
      if TRqOutline(AObj).Selected = nil then
        AValue := -1
      else
        AValue := TRqOutline(AObj).Selected.AbsoluteIndex;
    end
    else if Prop = 'ITEMHEIGHT' then
      AValue := TRqOutline(AObj).DefaultItemHeight
    else
      Result := False;
  end
  else if AObj is TRqHeader then
  begin
    Result := True;
    if Prop = 'SECTIONSCOUNT' then
      AValue := TRqHeader(AObj).Sections.Count
    else if Prop = 'HOTTRACK' then
      AValue := 1
    else
      Result := False;
  end
  else if AObj is TRqPrinter then
  begin
    Result := True;
    if Prop = 'PRINTERSCOUNT' then
      AValue := TRqPrinter(AObj).FNames.Count
    else if Prop = 'PRINTERINDEX' then
      AValue := TRqPrinter(AObj).FIndex
    else if Prop = 'COPIES' then
      AValue := TRqPrinter(AObj).FCopies
    else if Prop = 'ORIENTATION' then
      AValue := TRqPrinter(AObj).FOrientation
    else if Prop = 'PRINTING' then
      AValue := Ord(TRqPrinter(AObj).FPrinting)
    else if Prop = 'ABORTED' then
      AValue := Ord(TRqPrinter(AObj).FAborted)
    else if Prop = 'PAGENUMBER' then
      AValue := TRqPrinter(AObj).FPageNumber
    else if Prop = 'PAGEWIDTH' then
      AValue := TRqPrinter(AObj).PageSize(False)
    else if Prop = 'PAGEHEIGHT' then
      AValue := TRqPrinter(AObj).PageSize(True)
    else if Prop = 'HANDLE' then
      AValue := Integer(TRqPrinter(AObj).FDC)
    else if Prop = 'FONTSCOUNT' then
      AValue := Screen.Fonts.Count
    else if Prop = 'COPYMODE' then
      AValue := TRqPrinter(AObj).FCopyMode
    else if Prop = 'CAPABILITIES.COPIES' then
      AValue := Ord(TRqPrinter(AObj).Capability(DC_COPIES) > 1)
    else if Prop = 'CAPABILITIES.ORIENTATION' then
      AValue := Ord(TRqPrinter(AObj).Capability(DC_ORIENTATION) <> 0)
    else if Prop = 'CAPABILITIES.COLLATE' then
      AValue := Ord(TRqPrinter(AObj).Capability(DC_COLLATE) <> 0)
    else
      Result := False;
  end;
end;

function ExtraSetInt(AObj: TObject; const AProp: string;
                     AValue: Integer): Boolean;
var
  Prop, Rest: string;
  ScrollBar: TControlScrollBar;
  NewBitmap: TBitmap;
begin
  Result := False;
  Prop := UpperCase(AProp);
  ScrollBar := ScrollBarOf(AObj, Prop, Rest);
  if ScrollBar <> nil then
  begin
    Result := True;
    if Rest = 'INCREMENT' then
      ScrollBar.Increment := AValue
    else if Rest = 'POSITION' then
      ScrollBar.Position := AValue
    else if Rest = 'RANGE' then
      ScrollBar.Range := AValue
    else if Rest = 'TRACKING' then
      ScrollBar.Tracking := AValue <> 0
    else if Rest = 'VISIBLE' then
      ScrollBar.Visible := AValue <> 0
    // в LCL нет - не действует
    else if Rest = 'MARGIN' then
    else
      Result := False;
  end
  else if AObj is TRqBitmap then
  begin
    Result := True;
    if Prop = 'PIXELFORMAT' then
    begin
      if (AValue < Ord(Low(TPixelFormat))) or (AValue > Ord(pf32bit)) then
        raise Exception.Create('PixelFormat: no format ' + IntToStr(AValue));
      TRqBitmap(AObj).Bitmap.PixelFormat := TPixelFormat(AValue);
    end
    else if Prop = 'TRANSPARENTMODE' then
      TRqBitmap(AObj).Bitmap.TransparentMode := TTransparentMode(AValue and 1)
    else if Prop = 'HANDLE' then
      TRqBitmap(AObj).Bitmap.Handle := HBITMAP(PtrInt(AValue))
    else if Prop = 'BMPHANDLE' then
      LoadResBitmap(AValue, TRqBitmap(AObj).Bitmap)
    else
      Result := False;
  end
  else if AObj is TRqOutline then
  begin
    Result := True;
    if (Prop = 'ITEMINDEX') or (Prop = 'ROW') then
    begin
      if AValue = -1 then
        TRqOutline(AObj).Selected := nil
      else
      begin
        CheckIndex(AProp, AValue, TRqOutline(AObj).Items.Count);
        TRqOutline(AObj).Selected := TRqOutline(AObj).Items[AValue];
      end;
    end
    else if Prop = 'ITEMHEIGHT' then
      TRqOutline(AObj).DefaultItemHeight := AValue
    else if (Copy(Prop, 1, 9) = 'BMPHANDLE') and (OutlineSlot(Prop) >= 0) then
    begin
      NewBitmap := TBitmap.Create;
      try
        LoadResBitmap(AValue, NewBitmap);
        if OutlineSlot(Prop) < 3 then
          TRqOutline(AObj).SetPicture(OutlineSlot(Prop), NewBitmap);
      finally
        NewBitmap.Free;
      end;
    end
    else
      Result := False;
  end
  else if AObj is TRqHeader then
  begin
    // HotTrack: у LCL подсветка всегда
    Result := Prop = 'HOTTRACK';
  end
  else if AObj is TRqPrinter then
  begin
    Result := True;
    if Prop = 'PRINTERINDEX' then
    begin
      if AValue <> -1 then
        CheckIndex('PrinterIndex', AValue, TRqPrinter(AObj).FNames.Count);
      TRqPrinter(AObj).FIndex := AValue;
    end
    else if Prop = 'COPIES' then
      TRqPrinter(AObj).FCopies := AValue
    else if Prop = 'ORIENTATION' then
    begin
      if TRqPrinter(AObj).FPrinting then
        raise Exception.Create('Orientation: printing');
      TRqPrinter(AObj).FOrientation := AValue;
    end
    else if Prop = 'COPYMODE' then
    begin
      MiscCopyModeToLcl(AValue);
      TRqPrinter(AObj).FCopyMode := AValue;
      if TRqPrinter(AObj).FPrinting then
        TRqPrinter(AObj).FCanvas.CopyMode := MiscCopyModeToLcl(AValue);
    end
    else
      Result := False;
  end;
end;

function ExtraGetStr(AObj: TObject; const AProp: string;
                     out AValue: string): Boolean;
var
  Prop: string;
begin
  Result := False;
  AValue := '';
  Prop := UpperCase(AProp);
  if (AObj is TRqBitmap) and (Prop = 'BMP') then
  begin
    MiscBmpCache.Assign(TRqBitmap(AObj).Bitmap);
    Result := True;
  end
  else if (AObj is TRqPrinter) and (Prop = 'TITLE') then
  begin
    AValue := TRqPrinter(AObj).FTitle;
    Result := True;
  end;
end;

function ExtraSetStr(AObj: TObject; const AProp: string;
                     const AValue: string): Boolean;
var
  Prop: string;
  NewBitmap: TBitmap;
begin
  Result := False;
  Prop := UpperCase(AProp);
  if (AObj is TRqOutline) and (Copy(Prop, 1, 9) <> 'BMPHANDLE') and
     (OutlineSlot(Prop) >= 0) then
  begin
    NewBitmap := TBitmap.Create;
    try
      if AValue = '' then
        NewBitmap.Assign(MiscBmpCache)
      else
        NewBitmap.LoadFromFile(WinCPToUTF8(AValue));
      if OutlineSlot(Prop) < 3 then
        TRqOutline(AObj).SetPicture(OutlineSlot(Prop), NewBitmap);
    finally
      NewBitmap.Free;
    end;
    Result := True;
    Exit;
  end;
  if (AObj is TRqBitmap) and (Prop = 'BMP') then
  begin
    if AValue = '' then
      TRqBitmap(AObj).Bitmap.Assign(MiscBmpCache)
    else
      TRqBitmap(AObj).Bitmap.LoadFromFile(WinCPToUTF8(AValue));
    Result := True;
  end
  else if (AObj is TRqPrinter) and (Prop = 'TITLE') then
  begin
    TRqPrinter(AObj).FTitle := AValue;
    Result := True;
  end;
end;

function ExtraGetItem(AObj: TObject; const AProp: string; AIndex: Integer;
                      out AValue: string): Boolean;
var
  Prop: string;
begin
  Result := False;
  AValue := '';
  Prop := UpperCase(AProp);
  if (AObj is TRqOutline) and (Prop = 'ITEM') then
  begin
    CheckIndex('Item', AIndex, TRqOutline(AObj).Items.Count);
    AValue := UTF8ToWinCP(TRqOutline(AObj).Items[AIndex].Text);
    Result := True;
  end
  else if (AObj is TRqHeader) and (Prop = 'SECTIONS.CAPTION') then
  begin
    CheckIndex('Sections', AIndex, TRqHeader(AObj).Sections.Count);
    AValue := UTF8ToWinCP(TRqHeader(AObj).Sections[AIndex].Text);
    Result := True;
  end
  else if AObj is TRqPrinter then
  begin
    Result := True;
    if Prop = 'PRINTERS' then
    begin
      CheckIndex('Printers', AIndex, TRqPrinter(AObj).FNames.Count);
      AValue := TRqPrinter(AObj).FNames[AIndex];
    end
    else if Prop = 'FONTS' then
    begin
      CheckIndex('Fonts', AIndex, Screen.Fonts.Count);
      AValue := UTF8ToWinCP(Screen.Fonts[AIndex]);
    end
    else
      Result := False;
  end;
end;

function ExtraSetItem(AObj: TObject; const AProp: string; AIndex: Integer;
                      const AValue: string): Boolean;
var
  Prop: string;
begin
  Result := False;
  Prop := UpperCase(AProp);
  if (AObj is TRqOutline) and (Prop = 'ITEM') then
  begin
    CheckIndex('Item', AIndex, TRqOutline(AObj).Items.Count);
    TRqOutline(AObj).Items[AIndex].Text := WinCPToUTF8(AValue);
    Result := True;
  end
  else if (AObj is TRqHeader) and (Prop = 'SECTIONS.CAPTION') then
  begin
    CheckIndex('Sections', AIndex, TRqHeader(AObj).Sections.Count);
    TRqHeader(AObj).Sections[AIndex].Text := WinCPToUTF8(AValue);
    Result := True;
  end;
end;

function ExtraGetItemInt(AObj: TObject; const AProp: string; AIndex: Integer;
                         out AValue: Integer): Boolean;
var
  Prop: string;
  Header: TRqHeader;
begin
  Result := False;
  AValue := 0;
  Prop := UpperCase(AProp);
  if AObj is TRqOutline then
  begin
    Result := True;
    CheckIndex('Item', AIndex, TRqOutline(AObj).Items.Count);
    if Prop = 'ITEM.LEVEL' then
      AValue := TRqOutline(AObj).Items[AIndex].Level
    else
      Result := False;
  end
  else if AObj is TRqHeader then
  begin
    Header := TRqHeader(AObj);
    CheckIndex('Sections', AIndex, Header.Sections.Count);
    Result := True;
    if Prop = 'SECTIONS.WIDTH' then
      AValue := Header.Sections[AIndex].Width
    else if Prop = 'SECTIONS.MINWIDTH' then
      AValue := Header.Sections[AIndex].MinWidth
    else if Prop = 'SECTIONS.MAXWIDTH' then
      AValue := Header.Sections[AIndex].MaxWidth
    else if Prop = 'SECTIONS.ALIGNMENT' then
      AValue := Ord(Header.Sections[AIndex].Alignment)
    else if Prop = 'SECTIONS.STYLE' then
      AValue := Header.GetSectionStyle(AIndex)
    else if Prop = 'SECTIONS.ALLOWCLICK' then
      AValue := Ord(Header.GetAllowClick(AIndex))
    else
      Result := False;
  end;
end;

function ExtraSetItemInt(AObj: TObject; const AProp: string; AIndex: Integer;
                         AValue: Integer): Boolean;
var
  Prop: string;
  Header: TRqHeader;
begin
  Result := False;
  Prop := UpperCase(AProp);
  if not (AObj is TRqHeader) then
    Exit;
  Header := TRqHeader(AObj);
  CheckIndex('Sections', AIndex, Header.Sections.Count);
  Result := True;
  if Prop = 'SECTIONS.WIDTH' then
    Header.Sections[AIndex].Width := AValue
  else if Prop = 'SECTIONS.MINWIDTH' then
    Header.Sections[AIndex].MinWidth := AValue
  else if Prop = 'SECTIONS.MAXWIDTH' then
    Header.Sections[AIndex].MaxWidth := AValue
  else if Prop = 'SECTIONS.ALIGNMENT' then
  begin
    // taLeftJustify 0, taRightJustify 1, taCenter 2
    if (AValue < 0) or (AValue > 2) then
      raise Exception.Create('Alignment: no value ' + IntToStr(AValue));
    Header.Sections[AIndex].Alignment := TAlignment(AValue);
  end
  else if Prop = 'SECTIONS.STYLE' then
    Header.SetSectionStyle(AIndex, AValue)
  else if Prop = 'SECTIONS.ALLOWCLICK' then
    Header.SetAllowClick(AIndex, AValue <> 0)
  else
    Result := False;
end;

// Строка QOUTLINE: ведущие пробелы и табуляции - уровень
procedure OutlineAddLine(AOutline: TRqOutline; const ALine: string);
var
  Level, CharIdx: Integer;
  ParentNode: TTreeNode;
  LineText: string;
begin
  Level := 0;
  CharIdx := 1;
  while (CharIdx <= Length(ALine)) and (ALine[CharIdx] in [' ', #9]) do
  begin
    Inc(Level);
    Inc(CharIdx);
  end;
  LineText := WinCPToUTF8(Copy(ALine, CharIdx, MaxInt));
  // родитель - последний пункт уровня Level - 1
  ParentNode := AOutline.Items.GetLastNode;
  while (ParentNode <> nil) and (ParentNode.Level >= Level) do
    ParentNode := ParentNode.Parent;
  if ParentNode = nil then
    AOutline.Items.Add(nil, LineText)
  else
    AOutline.Items.AddChild(ParentNode, LineText);
end;

function OutlineCallEx(AOutline: TRqOutline; const AMethod, AStr: string;
                       AInt1: Integer): Boolean;
var
  Node: TTreeNode;
begin
  Result := True;
  if AMethod = 'ADDLINES' then
    OutlineAddLine(AOutline, AStr)
  else if AMethod = 'ADDCHILD' then
  begin
    CheckIndex('AddChild', AInt1, AOutline.Items.Count);
    AOutline.Items.AddChild(AOutline.Items[AInt1], WinCPToUTF8(AStr));
  end
  else if AMethod = 'INSERT' then
  begin
    // перед пунктом AInt1 (ItemCount - в конец)
    CheckIndex('Insert', AInt1, AOutline.Items.Count + 1);
    if AInt1 = AOutline.Items.Count then
      AOutline.Items.Add(nil, WinCPToUTF8(AStr))
    else
    begin
      Node := AOutline.Items[AInt1];
      AOutline.Items.Insert(Node, WinCPToUTF8(AStr));
    end;
  end
  else if AMethod = 'DELLINES' then
  begin
    CheckIndex('DelLines', AInt1, AOutline.Items.Count);
    AOutline.Items[AInt1].Delete;
  end
  else if AMethod = 'CLEAR' then
    AOutline.Items.Clear
  else if (AMethod = 'ADDOPTIONS') or (AMethod = 'DELOPTIONS') then
  begin
    // ooDrawTreeRoot 0, ooDrawFocusRect 1, ooDrawStretchBitmaps 2
    if (AInt1 < 0) or (AInt1 > 2) then
      raise Exception.Create('no outline option ' + IntToStr(AInt1));
    if AMethod = 'ADDOPTIONS' then
      AOutline.OutlineOptions := AOutline.OutlineOptions or (1 shl AInt1)
    else
      AOutline.OutlineOptions := AOutline.OutlineOptions and not (1 shl AInt1);
    AOutline.ApplyOptions;
  end
  else if AMethod = 'FULLEXPAND' then
    AOutline.FullExpand
  else if AMethod = 'FULLCOLLAPSE' then
    AOutline.FullCollapse
  else
    Result := False;
end;

function ExtraCallEx(AObj: TObject; const AMethod, AStr: string;
                     AInt1, AInt2, AInt3: Integer;
                     out AIntResult: Integer): Boolean;
var
  Method: string;
begin
  Result := False;
  AIntResult := 1;
  Method := UpperCase(AMethod);
  if AObj is TRqOutline then
    Result := OutlineCallEx(TRqOutline(AObj), Method, AStr, AInt1)
  else if AObj is TRqHeader then
  begin
    Result := True;
    if Method = 'ADDSECTIONS' then
      TRqHeader(AObj).Sections.Add.Text := WinCPToUTF8(AStr)
    else if Method = 'CLEAR' then
      TRqHeader(AObj).Sections.Clear
    else
      Result := False;
  end
  else if AObj is TTrackBar then
  begin
    Result := Method = 'SETTICK';
    if Result then
      TTrackBar(AObj).SetTick(AInt1);
  end
  else if AObj is TRqBitmap then
  begin
    Result := True;
    if Method = 'LOADFROMFILE' then
      TRqBitmap(AObj).Bitmap.LoadFromFile(WinCPToUTF8(AStr))
    else if Method = 'SAVETOFILE' then
      TRqBitmap(AObj).Bitmap.SaveToFile(WinCPToUTF8(AStr))
    else
      Result := False;
  end
  else if AObj is TRqPrinter then
  begin
    Result := True;
    if Method = 'BEGINDOC' then
      TRqPrinter(AObj).BeginDoc
    else if Method = 'ENDDOC' then
      TRqPrinter(AObj).EndDoc
    else if Method = 'NEWPAGE' then
      TRqPrinter(AObj).NewPage
    else if Method = 'ABORT' then
      TRqPrinter(AObj).Abort
    else
      Result := False;
  end;
end;

finalization
  FreeAndNil(PrinterObj);
end.
