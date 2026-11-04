unit DlgTtfToUtft;

// ---------------------------------------------------------------------------
//  TTF -> шрифт UTFT (меню Arduino - TTF to UTFT Font... и Файл - Создать
//  шрифт из TTF... в FontViewer).
//
//  Шрифт Windows (установленный или .ttf/.otf-файл, который подключается
//  только для unIDE - AddFontResourceEx с FR_PRIVATE) рисуется в клетки
//  ширина x высота точек, каждая точка - чёрная или нет, и записывается
//  .c-файлом UTFT: 4 байта заголовка (ширина, высота, первый код, число
//  символов), потом символы строками сверху вниз, ширина/8 байт в строке,
//  старший бит - левая точка. Формат читают UTFT и FontViewer.
//
//  Коды 0x80..0xFF - буквы CP1251 (кириллица): в скетче строка в CP1251
//  выводится этими символами.
//
//  Параметры: шрифт, жирный, курсив, сглаживание (вкл. - сглаженный текст
//  и порог яркости; выкл. - GDI рисует сразу без сглаживания, мелкие
//  размеры обычно чище), клетка, размер шрифта в точках (высота em), сдвиг
//  X, Y, символ по центру клетки, диапазон кодов, имя массива.
//  «Подобрать» - наибольший размер, при котором все символы диапазона
//  входят в клетку, и сдвиг Y, при котором они по высоте в середине.
//
//  Справа - образец 1:1 (как в FontViewer) и под ним выбранный символ
//  крупно (щелчок по образцу). Символы, вылезающие за клетку, перечислены
//  под параметрами.
//
//  Окно строится в коде, .dfm нет. Немодальное, одно (ShowTtfToUtft),
//  освобождается при закрытии.
// ---------------------------------------------------------------------------

interface

uses
  {$IFDEF FPC} LCLType, LCLIntf, IntfGraphics, FPImage, {$ENDIF}
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, Dialogs,
  UiButton,      // TUiButton
  UiEditCtrls,   // TUiEdit, TUiComboBox
  UiStdCtrls,    // TUiPanel, TUiLabel, TUiCheckBox
  UiTheme,       // UiThemeColor, UM_UITHEMECHANGED
  IniBuf,        // TBufIniFile - параметры
  DlgFontViewer; // TUtftFont, UtftSetSample, UtftMakeSample

type
  // Шрифт записан: имя .c-файла
  TTtfSavedEvent = procedure(const AFileName: string) of object;

  // Параметры построения
  TTtfParams = record
    FontName: string;
    Bold, Italic, Smooth, Center: Boolean;
    CellW, CellH: Integer;
    PixelSize: Integer;       // высота em, точки
    OffsetX, OffsetY: Integer;
    Threshold: Integer;       // %, при сглаживании
    FirstChar, LastChar: Integer;
  end;

  // Где точки символов (по всем символам диапазона), от начала клетки
  TTtfInk = record
    Found: Boolean;
    Left, Top, Right, Bottom: Integer;  // объединение
    Clipped: string;                    // символы, вылезающие за клетку
    ClippedCount: Integer;
  end;

  TDlgTtfToUtft = class;

  TTtfPreview = class(TCustomControl)
  private
    FOwnerDlg: TDlgTtfToUtft;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
                        PosX, PosY: Integer); override;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
  end;

  TDlgTtfToUtft = class(TForm)
  private
    FIniFile: string;
    FDefaultFolder: string;
    FOnSaved: TTtfSavedEvent;
    FPlaceSaved: Boolean;
    FLoading: Boolean;
    FNameEdited: Boolean;     // имя массива правили руками
    FSettingName: Boolean;
    FPrivateFiles: TStringList;  // подключённые .ttf (снять при закрытии)
    FFont: TUtftFont;         // построенный шрифт
    FSample: TBitmap;         // образец 1:1
    FSelCode: Integer;        // символ крупно
    FTimer: TTimer;
    FTextHeight: Integer;

    FSidePanel: TUiPanel;
    FCmbFont: TUiComboBox;
    FBtnTtf: TUiButton;
    FChkBold, FChkItalic, FChkSmooth, FChkCenter: TUiCheckBox;
    FEdCellW, FEdCellH, FEdSize, FEdOffX, FEdOffY, FEdThreshold: TUiEdit;
    FEdFirst, FEdLast: TUiEdit;
    FCmbRange: TUiComboBox;
    FEdName: TUiEdit;
    FBtnFit, FBtnSave, FBtnClose: TUiButton;
    FLblInfo: TUiLabel;
    FLblClip: TUiLabel;
    FScroll: TScrollBox;
    FPreview: TTtfPreview;

    procedure Build;
    function  AddLabel(const ACaption: string; ALeft, ATop: Integer): TUiLabel;
    function  AddEdit(ALeft, ATop, AWidth: Integer; const AHint: string): TUiEdit;
    function  AddCheck(const ACaption: string; ALeft, ATop: Integer;
                       const AHint: string): TUiCheckBox;
    function  ReadParams(var AParams: TTtfParams): Boolean;
    procedure WriteParams(const AParams: TTtfParams);
    procedure ParamChange(Sender: TObject);
    procedure NameChange(Sender: TObject);
    procedure RangeChange(Sender: TObject);
    procedure TimerTick(Sender: TObject);
    procedure Rebuild;
    procedure UpdateDefaultName;
    procedure LayoutPreview;
    procedure PaintPreview(ACanvas: TCanvas);
    procedure PreviewClick(PosX, PosY: Integer);
    function  ZoomTop: Integer;
    function  ZoomScale: Integer;
    procedure BtnTtfClick(Sender: TObject);
    procedure BtnFitClick(Sender: TObject);
    procedure BtnSaveClick(Sender: TObject);
    procedure BtnCloseClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure UMUiThemeChanged(var Message: TMessage); message UM_UITHEMECHANGED;
    procedure UpdateColors;
    procedure LoadSettings;
    procedure SaveSettings;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor CreateDlg(AOwner: TComponent);
    destructor Destroy; override;
    procedure SetIni(const AIniFile, ADefaultFolder: string);
    property OnSaved: TTtfSavedEvent read FOnSaved write FOnSaved;
  end;

// Окно конвертера: одно на программу; если уже открыто - поднять его.
// ADefaultFolder - куда предлагать записать .c (libraries\UTFT)
procedure ShowTtfToUtft(AOwner: TComponent; const AIniFile,
  ADefaultFolder: string; AOnSaved: TTtfSavedEvent);

// Построить шрифт UTFT по параметрам (AFont.Data, размеры, коды)
procedure TtfRenderFont(const AParams: TTtfParams; AFont: TUtftFont);
// Где точки символов диапазона при этих параметрах
function TtfMeasureInk(const AParams: TTtfParams): TTtfInk;
// Текст .c-файла UTFT
function TtfFontSource(AFont: TUtftFont; const AComment: string): string;
// Имя .ttf/.otf: имя семейства из таблицы name; '' - не прочитано
function TtfFamilyName(const AFileName: string): string;
// Юникод символа CP1251 (0 - символа нет)
function Cp1251ToUnicode(ACode: Integer): Integer;

implementation

const
  TtfSection = 'TtfToUtft';
  TtfSideWidth = 300;
  FR_PRIVATE_FLAG = $10;
  TtfPreviewGap = 10;

var
  TtfWindow: TDlgTtfToUtft = nil;

{$IFDEF UNIX}
function TtfAddFontResourceEx(AFileName: PAnsiChar; AFlags: DWORD;
  AReserved: Pointer): Integer; stdcall;
  external name 'unidewin_AddFontResourceExA';
{$ELSE}
function TtfAddFontResourceEx(AFileName: PAnsiChar; AFlags: DWORD;
  AReserved: Pointer): Integer; stdcall;
  external 'gdi32.dll' name 'AddFontResourceExA';
function TtfRemoveFontResourceEx(AFileName: PAnsiChar; AFlags: DWORD;
  AReserved: Pointer): BOOL; stdcall;
  external 'gdi32.dll' name 'RemoveFontResourceExA';
{$ENDIF}

// ---------------------------------------------------------------------------
//  CP1251
// ---------------------------------------------------------------------------

const
  Cp1251High: array[$80..$BF] of Word = (
    $0402, $0403, $201A, $0453, $201E, $2026, $2020, $2021,
    $20AC, $2030, $0409, $2039, $040A, $040C, $040B, $040F,
    $0452, $2018, $2019, $201C, $201D, $2022, $2013, $2014,
    $0000, $2122, $0459, $203A, $045A, $045C, $045B, $045F,
    $00A0, $040E, $045E, $0408, $00A4, $0490, $00A6, $00A7,
    $0401, $00A9, $0404, $00AB, $00AC, $00AD, $00AE, $0407,
    $00B0, $00B1, $0406, $0456, $0491, $00B5, $00B6, $00B7,
    $0451, $2116, $0454, $00BB, $0458, $0405, $0455, $0457);

function Cp1251ToUnicode(ACode: Integer): Integer;
begin
  if (ACode < 32) or (ACode > 255) or (ACode = 127) then
    Result := 0
  else if ACode < 128 then
    Result := ACode
  else if ACode >= $C0 then
    Result := $0410 + ACode - $C0
  else
    Result := Cp1251High[ACode];
end;

// ---------------------------------------------------------------------------
//  Отрисовка символов
// ---------------------------------------------------------------------------

// Шрифт на холст: имя, размер, начертание, сглаживание
procedure ApplyCanvasFont(ACanvas: TCanvas; const AParams: TTtfParams);
{$IFNDEF FPC}
var
  LogFont: TLogFont;
{$ENDIF}
begin
  ACanvas.Font.Name := AParams.FontName;
  ACanvas.Font.Height := -AParams.PixelSize;
  ACanvas.Font.Style := [];
  if AParams.Bold then
    ACanvas.Font.Style := ACanvas.Font.Style + [fsBold];
  if AParams.Italic then
    ACanvas.Font.Style := ACanvas.Font.Style + [fsItalic];
  ACanvas.Font.Color := clBlack;
  {$IFDEF FPC}
  if AParams.Smooth then
    ACanvas.Font.Quality := fqAntialiased
  else
    ACanvas.Font.Quality := fqNonAntialiased;
  {$ELSE}
  // В Delphi 7 у TFont нет Quality: тот же шрифт с другим lfQuality.
  // ANTIALIASED_QUALITY, а не ClearType: у ClearType цветная кайма
  if GetObject(ACanvas.Font.Handle, SizeOf(LogFont), @LogFont) <> 0 then
  begin
    if AParams.Smooth then
      LogFont.lfQuality := ANTIALIASED_QUALITY
    else
      LogFont.lfQuality := NONANTIALIASED_QUALITY;
    ACanvas.Font.Handle := CreateFontIndirect(LogFont);
  end;
  {$ENDIF}
end;

// Ширина символа (Юникод AChar) текущим шрифтом холста
function CharWidthOn(ACanvas: TCanvas; AChar: Integer): Integer;
{$IFNDEF FPC}
var
  WideCh: WideChar;
  Size: TSize;
{$ENDIF}
begin
  {$IFDEF FPC}
  Result := ACanvas.TextWidth(UTF8Encode(WideString(WideChar(AChar))));
  {$ELSE}
  WideCh := WideChar(AChar);
  ACanvas.TextWidth(' ');   // шрифт выбран в DC
  if GetTextExtentPoint32W(ACanvas.Handle, @WideCh, 1, Size) then
    Result := Size.cx
  else
    Result := 0;
  {$ENDIF}
end;

procedure CharOutOn(ACanvas: TCanvas; PosX, PosY, AChar: Integer);
{$IFNDEF FPC}
var
  WideCh: WideChar;
{$ENDIF}
begin
  {$IFDEF FPC}
  ACanvas.Brush.Style := bsClear;
  ACanvas.TextOut(PosX, PosY, UTF8Encode(WideString(WideChar(AChar))));
  ACanvas.Brush.Style := bsSolid;
  {$ELSE}
  WideCh := WideChar(AChar);
  ACanvas.TextWidth(' ');
  SetBkMode(ACanvas.Handle, TRANSPARENT);
  SetTextColor(ACanvas.Handle, ColorToRGB(clBlack));
  Windows.TextOutW(ACanvas.Handle, PosX, PosY, @WideCh, 1);
  {$ENDIF}
end;

type
  // Точки картинки: 1 - тёмная (ярче порога нет)
  TDarkMap = record
    Width, Height: Integer;
    Dark: array of Byte;
  end;

// Тёмные точки картинки (текст чёрным на белом)
procedure ReadDark(ABitmap: TBitmap; AThreshold: Integer; var AMap: TDarkMap);
var
  PosX, PosY, Level, Limit: Integer;
  {$IFDEF FPC}
  Image: TLazIntfImage;
  Pixel: TFPColor;
  {$ELSE}
  Line: PByteArray;
  {$ENDIF}
begin
  AMap.Width := ABitmap.Width;
  AMap.Height := ABitmap.Height;
  SetLength(AMap.Dark, AMap.Width * AMap.Height);
  // Порог: точка тёмная, если яркость меньше (100 - порог)% белого
  Limit := 255 * (100 - AThreshold) div 100;
  if Limit < 1 then
    Limit := 1;
  if Limit > 254 then
    Limit := 254;
  {$IFDEF FPC}
  Image := ABitmap.CreateIntfImage;
  try
    for PosY := 0 to AMap.Height - 1 do
      for PosX := 0 to AMap.Width - 1 do
      begin
        Pixel := Image.Colors[PosX, PosY];
        Level := ((Pixel.Red shr 8) * 30 + (Pixel.Green shr 8) * 59 +
                  (Pixel.Blue shr 8) * 11) div 100;
        if Level < Limit then
          AMap.Dark[PosY * AMap.Width + PosX] := 1
        else
          AMap.Dark[PosY * AMap.Width + PosX] := 0;
      end;
  finally
    Image.Free;
  end;
  {$ELSE}
  for PosY := 0 to AMap.Height - 1 do
  begin
    Line := ABitmap.ScanLine[PosY];
    for PosX := 0 to AMap.Width - 1 do
    begin
      // pf24bit: B, G, R
      Level := (Line[PosX * 3 + 2] * 30 + Line[PosX * 3 + 1] * 59 +
                Line[PosX * 3] * 11) div 100;
      if Level < Limit then
        AMap.Dark[PosY * AMap.Width + PosX] := 1
      else
        AMap.Dark[PosY * AMap.Width + PosX] := 0;
    end;
  end;
  {$ENDIF}
end;

// Символ ACode (CP1251) в картинку AWidth x AHeight: начало клетки - в
// (APadX, APadY), плюс сдвиг и выравнивание. Своя картинка на символ: он
// не залезает в соседние клетки
procedure RenderChar(const AParams: TTtfParams; ACode, AWidth, AHeight,
  APadX, APadY: Integer; ABitmap: TBitmap; var AMap: TDarkMap);
var
  Uni, PosX, Threshold: Integer;
begin
  ABitmap.Canvas.Brush.Style := bsSolid;
  ABitmap.Canvas.Brush.Color := clWhite;
  ABitmap.Canvas.FillRect(Rect(0, 0, AWidth, AHeight));
  Uni := Cp1251ToUnicode(ACode);
  if Uni > 32 then
  begin
    PosX := AParams.OffsetX;
    if AParams.Center then
      PosX := PosX + (AParams.CellW - CharWidthOn(ABitmap.Canvas, Uni)) div 2;
    CharOutOn(ABitmap.Canvas, APadX + PosX, APadY + AParams.OffsetY, Uni);
  end;
  if AParams.Smooth then
    Threshold := AParams.Threshold
  else
    Threshold := 50;
  ReadDark(ABitmap, Threshold, AMap);
end;

// Картинка для RenderChar
function NewCharBitmap(const AParams: TTtfParams; AWidth,
  AHeight: Integer): TBitmap;
begin
  Result := TBitmap.Create;
  Result.PixelFormat := pf24bit;
  Result.Width := AWidth;
  Result.Height := AHeight;
  ApplyCanvasFont(Result.Canvas, AParams);
end;

procedure TtfRenderFont(const AParams: TTtfParams; AFont: TUtftFont);
var
  Map: TDarkMap;
  Bitmap: TBitmap;
  Count, CodeIdx, Row, Col, BytesPerRow, BitIdx: Integer;
  Bits: Byte;
begin
  Count := AParams.LastChar - AParams.FirstChar + 1;
  BytesPerRow := AParams.CellW div 8;
  AFont.SizeX := AParams.CellW;
  AFont.SizeY := AParams.CellH;
  AFont.FirstChar := AParams.FirstChar;
  AFont.CharCount := Count;
  AFont.Problem := '';
  AFont.Note := '';
  SetLength(AFont.Data, 4 + Count * BytesPerRow * AParams.CellH);
  AFont.Data[0] := AParams.CellW;
  AFont.Data[1] := AParams.CellH;
  AFont.Data[2] := AParams.FirstChar;
  AFont.Data[3] := Count;
  Bitmap := NewCharBitmap(AParams, AParams.CellW, AParams.CellH);
  try
    for CodeIdx := 0 to Count - 1 do
    begin
      RenderChar(AParams, AParams.FirstChar + CodeIdx, AParams.CellW,
        AParams.CellH, 0, 0, Bitmap, Map);
      for Row := 0 to AParams.CellH - 1 do
        for Col := 0 to BytesPerRow - 1 do
        begin
          Bits := 0;
          for BitIdx := 0 to 7 do
            if Map.Dark[Row * Map.Width + Col * 8 + BitIdx] <> 0 then
              Bits := Bits or ($80 shr BitIdx);
          AFont.Data[4 + (CodeIdx * AParams.CellH + Row) * BytesPerRow + Col] := Bits;
        end;
    end;
  finally
    Bitmap.Free;
  end;
end;

function TtfMeasureInk(const AParams: TTtfParams): TTtfInk;
var
  Map: TDarkMap;
  Bitmap: TBitmap;
  Count, CodeIdx, PadX, PadY, BigW, BigH, PosX, PosY: Integer;
  InkX, InkY: Integer;
  CharLeft, CharTop, CharRight, CharBottom: Integer;
  HasInk: Boolean;
begin
  Result.Found := False;
  Result.Clipped := '';
  Result.ClippedCount := 0;
  Result.Left := 0;
  Result.Top := 0;
  Result.Right := -1;
  Result.Bottom := -1;
  // Клетка с запасом вокруг: видно, что вылезает за клетку
  PadX := AParams.PixelSize + 4;
  PadY := AParams.PixelSize + 4;
  BigW := AParams.CellW + 2 * PadX;
  BigH := AParams.CellH + 2 * PadY;
  Count := AParams.LastChar - AParams.FirstChar + 1;
  Bitmap := NewCharBitmap(AParams, BigW, BigH);
  try
    for CodeIdx := 0 to Count - 1 do
    begin
      RenderChar(AParams, AParams.FirstChar + CodeIdx, BigW, BigH, PadX, PadY,
        Bitmap, Map);
      HasInk := False;
      CharLeft := MaxInt;
      CharTop := MaxInt;
      CharRight := -MaxInt;
      CharBottom := -MaxInt;
      for PosY := 0 to BigH - 1 do
        for PosX := 0 to BigW - 1 do
          if Map.Dark[PosY * Map.Width + PosX] <> 0 then
          begin
            InkX := PosX - PadX;
            InkY := PosY - PadY;
            HasInk := True;
            if InkX < CharLeft then CharLeft := InkX;
            if InkX > CharRight then CharRight := InkX;
            if InkY < CharTop then CharTop := InkY;
            if InkY > CharBottom then CharBottom := InkY;
          end;
      if not HasInk then
        Continue;
      if not Result.Found then
      begin
        Result.Left := CharLeft;
        Result.Top := CharTop;
        Result.Right := CharRight;
        Result.Bottom := CharBottom;
        Result.Found := True;
      end
      else
      begin
        if CharLeft < Result.Left then Result.Left := CharLeft;
        if CharTop < Result.Top then Result.Top := CharTop;
        if CharRight > Result.Right then Result.Right := CharRight;
        if CharBottom > Result.Bottom then Result.Bottom := CharBottom;
      end;
      if (CharLeft < 0) or (CharTop < 0) or (CharRight >= AParams.CellW) or
         (CharBottom >= AParams.CellH) then
      begin
        Inc(Result.ClippedCount);
        if Result.ClippedCount <= 24 then
        begin
          if AParams.FirstChar + CodeIdx < 128 then
            Result.Clipped := Result.Clipped + Chr(AParams.FirstChar + CodeIdx)
          else
            Result.Clipped := Result.Clipped +
              Format(' $%.2x', [AParams.FirstChar + CodeIdx]);
        end;
      end;
    end;
  finally
    Bitmap.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  .c-файл
// ---------------------------------------------------------------------------

function TtfFontSource(AFont: TUtftFont; const AComment: string): string;
var
  Lines: TStringList;
  CodeIdx, ByteIdx, Code, BytesPerChar, Offset: Integer;
  Line, CharText, FontType: string;
begin
  Lines := TStringList.Create;
  try
    BytesPerChar := (AFont.SizeX div 8) * AFont.SizeY;
    if (AFont.FirstChar = $20) and (AFont.CharCount = 95) then
      FontType := 'Full (95 characters)'
    else
      FontType := Format('%d characters, $%.2x..$%.2x', [AFont.CharCount,
        AFont.FirstChar, AFont.FirstChar + AFont.CharCount - 1]);
    Lines.Add('// ' + AFont.Name + '.c');
    Lines.Add('// Font type    : ' + FontType);
    Lines.Add(Format('// Font size    : %dx%d pixels', [AFont.SizeX, AFont.SizeY]));
    Lines.Add(Format('// Memory usage : %d bytes', [Length(AFont.Data)]));
    if AComment <> '' then
      Lines.Add('// ' + AComment);
    Lines.Add('');
    Lines.Add('#if defined(__AVR__)');
    Lines.Add('    #include <avr/pgmspace.h>');
    Lines.Add('    #define fontdatatype const uint8_t');
    Lines.Add('#elif defined(__PIC32MX__)');
    Lines.Add('    #define PROGMEM');
    Lines.Add('    #define fontdatatype const unsigned char');
    Lines.Add('#elif defined(__arm__)');
    Lines.Add('    #define PROGMEM');
    Lines.Add('    #define fontdatatype const unsigned char');
    Lines.Add('#endif');
    Lines.Add('');
    Lines.Add(Format('fontdatatype %s[%d] PROGMEM={', [AFont.Name, Length(AFont.Data)]));
    Lines.Add(Format('0x%.2X,0x%.2X,0x%.2X,0x%.2X,', [AFont.Data[0],
      AFont.Data[1], AFont.Data[2], AFont.Data[3]]));
    for CodeIdx := 0 to AFont.CharCount - 1 do
    begin
      Code := AFont.FirstChar + CodeIdx;
      Offset := 4 + CodeIdx * BytesPerChar;
      Line := '';
      for ByteIdx := 0 to BytesPerChar - 1 do
        Line := Line + Format('0x%.2X,', [AFont.Data[Offset + ByteIdx]]);
      // В комментарии - символ; '\' в конце // продлил бы комментарий на
      // следующую строку
      if Code = 32 then
        CharText := '<space>'
      else if Code = Ord('\') then
        CharText := '<backslash>'
      else if (Code > 32) and (Code < 127) then
        CharText := Chr(Code)
      else
        CharText := Format('0x%.2X', [Code]);
      Lines.Add(Line + '  // ' + CharText);
    end;
    Lines.Add('};');
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

// ---------------------------------------------------------------------------
//  Имя семейства .ttf / .otf (таблица name, nameID 1)
// ---------------------------------------------------------------------------

function TtfFamilyName(const AFileName: string): string;
var
  Stream: TFileStream;
  Buf: array of Byte;
  TableCount, TableIdx, Pos0, NameOff, RecCount, StrBase, RecIdx: Integer;
  Platform, Encoding, NameId, StrLen, StrOff, CharIdx: Integer;
  BestText: string;
  BestRank, Rank: Integer;
  Text: string;
  WideText: WideString;

  function U16(AAt: Integer): Integer;
  begin
    if (AAt < 0) or (AAt + 1 >= Length(Buf)) then
      Result := 0
    else
      Result := (Buf[AAt] shl 8) or Buf[AAt + 1];
  end;

  function U32(AAt: Integer): Integer;
  begin
    Result := (U16(AAt) shl 16) or U16(AAt + 2);
  end;

begin
  Result := '';
  try
    Stream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
    try
      SetLength(Buf, Stream.Size);
      if Length(Buf) > 0 then
        Stream.ReadBuffer(Buf[0], Length(Buf));
    finally
      Stream.Free;
    end;
  except
    Exit;
  end;
  if Length(Buf) < 12 then
    Exit;
  TableCount := U16(4);
  NameOff := -1;
  for TableIdx := 0 to TableCount - 1 do
  begin
    Pos0 := 12 + TableIdx * 16;
    if (Pos0 + 16 <= Length(Buf)) and (Buf[Pos0] = Ord('n')) and
       (Buf[Pos0 + 1] = Ord('a')) and (Buf[Pos0 + 2] = Ord('m')) and
       (Buf[Pos0 + 3] = Ord('e')) then
    begin
      NameOff := U32(Pos0 + 8);
      Break;
    end;
  end;
  if (NameOff < 0) or (NameOff + 6 > Length(Buf)) then
    Exit;
  RecCount := U16(NameOff + 2);
  StrBase := NameOff + U16(NameOff + 4);
  BestText := '';
  BestRank := 0;
  for RecIdx := 0 to RecCount - 1 do
  begin
    Pos0 := NameOff + 6 + RecIdx * 12;
    Platform := U16(Pos0);
    Encoding := U16(Pos0 + 2);
    NameId := U16(Pos0 + 6);
    StrLen := U16(Pos0 + 8);
    StrOff := StrBase + U16(Pos0 + 10);
    if (NameId <> 1) or (StrOff + StrLen > Length(Buf)) then
      Continue;
    Text := '';
    if Platform = 3 then
    begin
      // Windows: UTF-16 BE; английское имя (0x409) - лучше
      SetLength(WideText, StrLen div 2);
      for CharIdx := 1 to StrLen div 2 do
        WideText[CharIdx] := WideChar(U16(StrOff + (CharIdx - 1) * 2));
      {$IFDEF FPC}
      Text := UTF8Encode(WideText);
      {$ELSE}
      Text := string(WideText);
      {$ENDIF}
      if U16(Pos0 + 4) = $0409 then
        Rank := 3
      else
        Rank := 2;
    end
    else if (Platform = 1) and (Encoding = 0) then
    begin
      SetLength(Text, StrLen);
      for CharIdx := 1 to StrLen do
        Text[CharIdx] := Chr(Buf[StrOff + CharIdx - 1]);
      Rank := 1;
    end
    else
      Continue;
    if (Text <> '') and (Rank > BestRank) then
    begin
      BestText := Text;
      BestRank := Rank;
    end;
  end;
  Result := BestText;
end;

// ---------------------------------------------------------------------------
//  TTtfPreview
// ---------------------------------------------------------------------------

procedure TTtfPreview.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TTtfPreview.Paint;
begin
  if FOwnerDlg <> nil then
    FOwnerDlg.PaintPreview(Canvas);
end;

procedure TTtfPreview.MouseDown(Button: TMouseButton; Shift: TShiftState;
  PosX, PosY: Integer);
begin
  inherited MouseDown(Button, Shift, PosX, PosY);
  if FOwnerDlg <> nil then
    FOwnerDlg.PreviewClick(PosX, PosY);
end;

// ---------------------------------------------------------------------------
//  TDlgTtfToUtft
// ---------------------------------------------------------------------------

procedure ShowTtfToUtft(AOwner: TComponent; const AIniFile,
  ADefaultFolder: string; AOnSaved: TTtfSavedEvent);
begin
  if TtfWindow = nil then
  begin
    TtfWindow := TDlgTtfToUtft.CreateDlg(AOwner);
    TtfWindow.OnSaved := AOnSaved;
    TtfWindow.SetIni(AIniFile, ADefaultFolder);
  end;
  TtfWindow.Show;
  if TtfWindow.WindowState = wsMinimized then
    TtfWindow.WindowState := wsNormal;
  TtfWindow.BringToFront;
end;

constructor TDlgTtfToUtft.CreateDlg(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  FPrivateFiles := TStringList.Create;
  FFont := TUtftFont.Create;
  FFont.DeclSize := -1;
  FSelCode := Ord('A');
  FLoading := True;
  Build;
  FLoading := False;
  UiThemeAddClient(Self);
end;

destructor TDlgTtfToUtft.Destroy;
{$IFNDEF UNIX}
var
  FileIdx: Integer;
{$ENDIF}
begin
  UiThemeRemoveClient(Self);
  if not FPlaceSaved then
    SaveSettings;
  {$IFNDEF UNIX}
  for FileIdx := 0 to FPrivateFiles.Count - 1 do
    TtfRemoveFontResourceEx(PAnsiChar(AnsiString(FPrivateFiles[FileIdx])),
      FR_PRIVATE_FLAG, nil);
  {$ENDIF}
  FPrivateFiles.Free;
  FSample.Free;
  FFont.Free;
  if TtfWindow = Self then
    TtfWindow := nil;
  inherited Destroy;
end;

procedure TDlgTtfToUtft.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  if (Owner is TWinControl) and TWinControl(Owner).HandleAllocated then
    Params.WndParent := TWinControl(Owner).Handle;
end;

function TDlgTtfToUtft.AddLabel(const ACaption: string; ALeft,
  ATop: Integer): TUiLabel;
begin
  Result := TUiLabel.Create(Self);
  Result.Parent := FSidePanel;
  Result.AutoSize := True;
  Result.Caption := ACaption;
  Result.Left := ALeft;
  Result.Top := ATop + 3;
end;

function TDlgTtfToUtft.AddEdit(ALeft, ATop, AWidth: Integer;
  const AHint: string): TUiEdit;
begin
  Result := TUiEdit.Create(Self);
  Result.Parent := FSidePanel;
  Result.SetBounds(ALeft, ATop, AWidth, FTextHeight + 8);
  Result.Hint := AHint;
  Result.ShowHint := AHint <> '';
  Result.OnChange := ParamChange;
end;

function TDlgTtfToUtft.AddCheck(const ACaption: string; ALeft, ATop: Integer;
  const AHint: string): TUiCheckBox;
begin
  Result := TUiCheckBox.Create(Self);
  Result.Parent := FSidePanel;
  Result.Caption := ACaption;
  Result.SetBounds(ALeft, ATop, 130, FTextHeight + 6);
  Result.Hint := AHint;
  Result.ShowHint := AHint <> '';
  Result.OnClick := ParamChange;
end;

procedure TDlgTtfToUtft.Build;
var
  Measure: TBitmap;
  RowY, RowStep, ColX: Integer;

  function MakeButton(const ACaption, AHint: string; ALeft, ATop,
    AWidth: Integer; AOnClick: TNotifyEvent): TUiButton;
  begin
    Result := TUiButton.Create(Self);
    Result.Parent := FSidePanel;
    Result.Caption := ACaption;
    Result.Hint := AHint;
    Result.ShowHint := AHint <> '';
    Result.SetBounds(ALeft, ATop, AWidth, FTextHeight + 10);
    Result.OnClick := AOnClick;
  end;

begin
  Caption := 'TTF to UTFT Font';
  OnClose := FormClose;
  OnKeyDown := FormKeyDown;
  KeyPreview := True;
  BorderStyle := bsSizeable;
  BorderIcons := [biSystemMenu, biMinimize, biMaximize];
  Font.Assign(Screen.MenuFont);
  if Font.Height = 0 then
    Font.Size := 9;
  Measure := TBitmap.Create;
  try
    Measure.Width := 4;
    Measure.Height := 4;
    Measure.Canvas.Font := Font;
    FTextHeight := Measure.Canvas.TextHeight('Wg');
  finally
    Measure.Free;
  end;
  if FTextHeight < 8 then
    FTextHeight := 14;
  RowStep := FTextHeight + 14;
  Position := poMainFormCenter;
  Width := 900;
  Height := 700;
  Constraints.MinWidth := 700;
  Constraints.MinHeight := 520;

  FSidePanel := TUiPanel.Create(Self);
  FSidePanel.Parent := Self;
  FSidePanel.Align := alLeft;
  FSidePanel.Width := TtfSideWidth;
  FSidePanel.BevelOuter := bvNone;
  FSidePanel.Caption := '';

  ColX := 110;
  RowY := 8;
  AddLabel('Шрифт:', 8, RowY);
  FCmbFont := TUiComboBox.Create(Self);
  FCmbFont.Parent := FSidePanel;
  FCmbFont.Style := csDropDownList;
  FCmbFont.SetBounds(ColX - 50, RowY, TtfSideWidth - ColX + 50 - 8, FTextHeight + 8);
  FCmbFont.DropDownCount := 24;
  FCmbFont.Sorted := True;
  FCmbFont.Items.Assign(Screen.Fonts);
  FCmbFont.OnChange := ParamChange;
  Inc(RowY, RowStep);
  FBtnTtf := MakeButton('Файл .ttf / .otf...', 'Шрифт из файла (не ' +
    'установленный): подключается только для unIDE до закрытия окна',
    ColX - 50, RowY, TtfSideWidth - ColX + 50 - 8, BtnTtfClick);
  Inc(RowY, RowStep + 2);

  FChkBold := AddCheck('Жирный', 8, RowY, '');
  FChkItalic := AddCheck('Курсив', 150, RowY, '');
  Inc(RowY, RowStep - 4);
  FChkSmooth := AddCheck('Сглаживание', 8, RowY, 'Вкл.: сглаженный ' +
    'текст, точка - темнее порога. Выкл.: Windows рисует без сглаживания ' +
    '(мелкие размеры обычно чище)');
  FChkCenter := AddCheck('По центру', 150, RowY, 'Каждый символ - по ' +
    'центру клетки по ширине (иначе - от левого края + сдвиг X)');
  Inc(RowY, RowStep);

  AddLabel('Клетка, точек:', 8, RowY);
  FEdCellW := AddEdit(ColX, RowY, 50, 'Ширина символа: кратна 8 (UTFT ' +
    'читает строку символа целыми байтами), до 248');
  AddLabel('x', ColX + 56, RowY);
  FEdCellH := AddEdit(ColX + 70, RowY, 50, 'Высота символа, до 255');
  Inc(RowY, RowStep);
  AddLabel('Размер шрифта:', 8, RowY);
  FEdSize := AddEdit(ColX, RowY, 50, 'Высота em шрифта, точек');
  FBtnFit := MakeButton('Подобрать', 'Наибольший размер, при котором все ' +
    'символы диапазона входят в клетку; сдвиг Y - по середине',
    ColX + 70, RowY - 1, 100, BtnFitClick);
  Inc(RowY, RowStep);
  AddLabel('Сдвиг X, Y:', 8, RowY);
  FEdOffX := AddEdit(ColX, RowY, 50, 'Сдвиг символа вправо, точек');
  FEdOffY := AddEdit(ColX + 70, RowY, 50, 'Сдвиг символа вниз, точек ' +
    '(0 - верх текста у верха клетки)');
  Inc(RowY, RowStep);
  AddLabel('Порог, %:', 8, RowY);
  FEdThreshold := AddEdit(ColX, RowY, 50, 'При сглаживании: точка ' +
    'считается чёрной, если темнее этого процента (больше - тоньше)');
  Inc(RowY, RowStep + 4);

  AddLabel('Символы:', 8, RowY);
  FCmbRange := TUiComboBox.Create(Self);
  FCmbRange.Parent := FSidePanel;
  FCmbRange.Style := csDropDownList;
  FCmbRange.SetBounds(ColX - 30, RowY, TtfSideWidth - ColX + 30 - 8, FTextHeight + 8);
  FCmbRange.Items.Add('$20..$7E - латиница (95)');
  FCmbRange.Items.Add('$20..$FF - с кириллицей CP1251 (224)');
  FCmbRange.Items.Add('$30..$39 - цифры (10)');
  FCmbRange.Items.Add('$2D..$39 - цифры и - . / (13)');
  FCmbRange.Items.Add('свой диапазон');
  FCmbRange.OnChange := RangeChange;
  Inc(RowY, RowStep);
  AddLabel('Коды с, по:', 8, RowY);
  FEdFirst := AddEdit(ColX, RowY, 50, 'Первый код (десятичный или $hex)');
  FEdLast := AddEdit(ColX + 70, RowY, 50, 'Последний код');
  Inc(RowY, RowStep + 4);

  AddLabel('Имя массива:', 8, RowY);
  FEdName := AddEdit(ColX, RowY, TtfSideWidth - ColX - 8,
    'Имя массива в .c и в скетче: extern uint8_t Имя[]; setFont(Имя)');
  FEdName.OnChange := NameChange;
  Inc(RowY, RowStep + 4);

  FBtnSave := MakeButton('Сохранить .c...', 'Записать шрифт .c-файлом ' +
    'UTFT и открыть его в FontViewer (Ctrl+S)', 8, RowY, 135, BtnSaveClick);
  FBtnClose := MakeButton('Закрыть', 'Esc', 155, RowY, 135, BtnCloseClick);
  Inc(RowY, RowStep + 6);

  FLblInfo := TUiLabel.Create(Self);
  FLblInfo.Parent := FSidePanel;
  FLblInfo.AutoSize := False;
  FLblInfo.WordWrap := True;
  FLblInfo.SetBounds(8, RowY, TtfSideWidth - 16, 3 * FTextHeight + 4);
  FLblInfo.Caption := '';
  Inc(RowY, 3 * FTextHeight + 8);
  FLblClip := TUiLabel.Create(Self);
  FLblClip.Parent := FSidePanel;
  FLblClip.AutoSize := False;
  FLblClip.WordWrap := True;
  FLblClip.SetBounds(8, RowY, TtfSideWidth - 16, 4 * FTextHeight + 4);
  FLblClip.Caption := '';

  FScroll := TScrollBox.Create(Self);
  FScroll.Parent := Self;
  FScroll.Align := alClient;
  FScroll.BorderStyle := bsNone;
  FScroll.HorzScrollBar.Tracking := True;
  FScroll.VertScrollBar.Tracking := True;
  FPreview := TTtfPreview.Create(Self);
  FPreview.FOwnerDlg := Self;
  FPreview.Parent := FScroll;
  FPreview.SetBounds(0, 0, FontViewWidth + 2 * TtfPreviewGap, 200);

  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := 150;
  FTimer.OnTimer := TimerTick;

  // Значения по умолчанию - до LoadSettings
  if FCmbFont.Items.IndexOf('Arial') >= 0 then
    FCmbFont.ItemIndex := FCmbFont.Items.IndexOf('Arial')
  else if FCmbFont.Items.Count > 0 then
    FCmbFont.ItemIndex := 0;
  FChkCenter.Checked := True;
  FEdCellW.Text := '16';
  FEdCellH.Text := '24';
  FEdSize.Text := '22';
  FEdOffX.Text := '0';
  FEdOffY.Text := '0';
  FEdThreshold.Text := '50';
  FCmbRange.ItemIndex := 0;
  FEdFirst.Text := '32';
  FEdLast.Text := '126';
  UpdateColors;
end;

// Число из поля: десятичное или $hex / 0x
function EditNumber(AEdit: TUiEdit; var AValue: Integer): Boolean;
var
  Text: string;
begin
  Text := Trim(AEdit.Text);
  if (Length(Text) > 2) and (Text[1] = '0') and (UpCase(Text[2]) = 'X') then
    Text := '$' + Copy(Text, 3, MaxInt);
  Result := TryStrToInt(Text, AValue);
end;

function TDlgTtfToUtft.ReadParams(var AParams: TTtfParams): Boolean;
var
  Problem: string;
begin
  Result := False;
  Problem := '';
  if FCmbFont.ItemIndex >= 0 then
    AParams.FontName := FCmbFont.Items[FCmbFont.ItemIndex]
  else
    AParams.FontName := '';
  AParams.Bold := FChkBold.Checked;
  AParams.Italic := FChkItalic.Checked;
  AParams.Smooth := FChkSmooth.Checked;
  AParams.Center := FChkCenter.Checked;
  if not EditNumber(FEdCellW, AParams.CellW) or (AParams.CellW < 8) or
     (AParams.CellW > 248) or (AParams.CellW mod 8 <> 0) then
    Problem := 'Ширина клетки: 8..248, кратна 8'
  else if not EditNumber(FEdCellH, AParams.CellH) or (AParams.CellH < 1) or
     (AParams.CellH > 255) then
    Problem := 'Высота клетки: 1..255'
  else if not EditNumber(FEdSize, AParams.PixelSize) or (AParams.PixelSize < 2) or
     (AParams.PixelSize > 600) then
    Problem := 'Размер шрифта: 2..600'
  else if not EditNumber(FEdOffX, AParams.OffsetX) or
     not EditNumber(FEdOffY, AParams.OffsetY) then
    Problem := 'Сдвиг X, Y - числа'
  else if not EditNumber(FEdThreshold, AParams.Threshold) or
     (AParams.Threshold < 1) or (AParams.Threshold > 99) then
    Problem := 'Порог: 1..99 %'
  else if not EditNumber(FEdFirst, AParams.FirstChar) or
     not EditNumber(FEdLast, AParams.LastChar) or (AParams.FirstChar < 0) or
     (AParams.LastChar > 255) or (AParams.LastChar < AParams.FirstChar) then
    Problem := 'Коды: 0..255, первый не больше последнего'
  else if AParams.LastChar - AParams.FirstChar + 1 > 255 then
    Problem := 'Символов не больше 255 (число - один байт заголовка)'
  else if AParams.FontName = '' then
    Problem := 'Не выбран шрифт';
  if Problem <> '' then
  begin
    FLblInfo.Font.Color := $000000C0;
    FLblInfo.Caption := Problem;
    Exit;
  end;
  Result := True;
end;

procedure TDlgTtfToUtft.WriteParams(const AParams: TTtfParams);
var
  FontIdx: Integer;
begin
  FLoading := True;
  try
    FontIdx := FCmbFont.Items.IndexOf(AParams.FontName);
    if FontIdx >= 0 then
      FCmbFont.ItemIndex := FontIdx;
    FChkBold.Checked := AParams.Bold;
    FChkItalic.Checked := AParams.Italic;
    FChkSmooth.Checked := AParams.Smooth;
    FChkCenter.Checked := AParams.Center;
    FEdCellW.Text := IntToStr(AParams.CellW);
    FEdCellH.Text := IntToStr(AParams.CellH);
    FEdSize.Text := IntToStr(AParams.PixelSize);
    FEdOffX.Text := IntToStr(AParams.OffsetX);
    FEdOffY.Text := IntToStr(AParams.OffsetY);
    FEdThreshold.Text := IntToStr(AParams.Threshold);
    FEdFirst.Text := IntToStr(AParams.FirstChar);
    FEdLast.Text := IntToStr(AParams.LastChar);
  finally
    FLoading := False;
  end;
end;

procedure TDlgTtfToUtft.ParamChange(Sender: TObject);
begin
  if FLoading then
    Exit;
  if (Sender = FEdFirst) or (Sender = FEdLast) then
    FCmbRange.ItemIndex := FCmbRange.Items.Count - 1;
  FTimer.Enabled := False;
  FTimer.Enabled := True;
end;

procedure TDlgTtfToUtft.NameChange(Sender: TObject);
begin
  if not FSettingName and not FLoading then
    FNameEdited := Trim(FEdName.Text) <> '';
end;

procedure TDlgTtfToUtft.RangeChange(Sender: TObject);
var
  FirstCode, LastCode: Integer;
begin
  case FCmbRange.ItemIndex of
    0: begin FirstCode := $20; LastCode := $7E; end;
    1: begin FirstCode := $20; LastCode := $FF; end;
    2: begin FirstCode := $30; LastCode := $39; end;
    3: begin FirstCode := $2D; LastCode := $39; end;
  else
    Exit;
  end;
  FLoading := True;
  try
    FEdFirst.Text := IntToStr(FirstCode);
    FEdLast.Text := IntToStr(LastCode);
  finally
    FLoading := False;
  end;
  ParamChange(nil);
end;

procedure TDlgTtfToUtft.TimerTick(Sender: TObject);
begin
  FTimer.Enabled := False;
  Rebuild;
end;

// Имя массива по шрифту и клетке: Arial16x24
procedure TDlgTtfToUtft.UpdateDefaultName;
var
  Params: TTtfParams;
  Base: string;
  CharIdx: Integer;
begin
  if FNameEdited or not ReadParams(Params) then
    Exit;
  Base := '';
  for CharIdx := 1 to Length(Params.FontName) do
    if Params.FontName[CharIdx] in ['A'..'Z', 'a'..'z', '0'..'9', '_'] then
      Base := Base + Params.FontName[CharIdx];
  if (Base = '') or (Base[1] in ['0'..'9']) then
    Base := 'Font' + Base;
  if Params.Bold then
    Base := Base + 'Bold';
  if Params.Italic then
    Base := Base + 'Italic';
  Base := Base + Format('%dx%d', [Params.CellW, Params.CellH]);
  if (Params.FirstChar = $30) and (Params.LastChar = $39) then
    Base := Base + 'Num';
  FSettingName := True;
  try
    FEdName.Text := Base;
  finally
    FSettingName := False;
  end;
end;

procedure TDlgTtfToUtft.Rebuild;
var
  Params: TTtfParams;
  Ink: TTtfInk;
begin
  if not ReadParams(Params) then
  begin
    FreeAndNil(FSample);
    SetLength(FFont.Data, 0);
    FFont.CharCount := 0;
    LayoutPreview;
    Exit;
  end;
  UpdateDefaultName;
  Screen.Cursor := crHourGlass;
  try
    TtfRenderFont(Params, FFont);
    FFont.Name := Trim(FEdName.Text);
    UtftSetSample(FFont, '');
    FreeAndNil(FSample);
    FSample := UtftMakeSample(FFont, True);
    Ink := TtfMeasureInk(Params);
  finally
    Screen.Cursor := crDefault;
  end;
  FLblInfo.Font.Color := UiThemeColor('Window.Text');
  FLblInfo.Caption := Format('%d x %d точек, символы %d..%d ($%.2x..$%.2x), ' +
    '%d шт., %d байт', [FFont.SizeX, FFont.SizeY, Params.FirstChar,
    Params.LastChar, Params.FirstChar, Params.LastChar, FFont.CharCount,
    Length(FFont.Data)]);
  if Ink.Found then
    FLblInfo.Caption := FLblInfo.Caption + Format('; точки символов: ' +
      'x %d..%d, y %d..%d', [Ink.Left, Ink.Right, Ink.Top, Ink.Bottom]);
  if Ink.ClippedCount > 0 then
  begin
    FLblClip.Font.Color := $000000C0;
    if UiThemeKind <> utLight then
      FLblClip.Font.Color := $006060FF;
    FLblClip.Caption := Format('За клетку вылезают %d символов: %s',
      [Ink.ClippedCount, Ink.Clipped]) +
      ' - уменьшите размер, сдвиньте или нажмите «Подобрать»';
  end
  else
    FLblClip.Caption := '';
  if (FSelCode < FFont.FirstChar) or
     (FSelCode >= FFont.FirstChar + FFont.CharCount) then
    FSelCode := FFont.FirstChar;
  LayoutPreview;
end;

function TDlgTtfToUtft.ZoomScale: Integer;
begin
  Result := 1;
  if (FFont.SizeX > 0) and (FFont.SizeY > 0) then
  begin
    Result := 320 div FFont.SizeY;
    if Result * FFont.SizeX > FontViewWidth then
      Result := FontViewWidth div FFont.SizeX;
    if Result > 16 then
      Result := 16;
    if Result < 1 then
      Result := 1;
  end;
end;

function TDlgTtfToUtft.ZoomTop: Integer;
begin
  Result := TtfPreviewGap + FTextHeight + 4;
  if FSample <> nil then
    Result := Result + FSample.Height + 2 * TtfPreviewGap + FTextHeight + 4;
end;

procedure TDlgTtfToUtft.LayoutPreview;
var
  NewHeight: Integer;
begin
  NewHeight := ZoomTop + ZoomScale * FFont.SizeY + 2 * TtfPreviewGap;
  FPreview.SetBounds(0, 0, FontViewWidth + 2 * TtfPreviewGap, NewHeight);
  FPreview.Invalidate;
end;

procedure TDlgTtfToUtft.PaintPreview(ACanvas: TCanvas);
var
  BackColor, TextColor, GridColor: TColor;
  Scale, Offset, Row, Col, BytesPerRow, TopY, LeftX: Integer;
  CharText: string;
  IsSet: Boolean;
begin
  BackColor := UiThemeColor('List.BG');
  TextColor := UiThemeColor('List.Text');
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := BackColor;
  ACanvas.FillRect(Rect(0, 0, FPreview.Width, FPreview.Height));
  ACanvas.Font := Font;
  ACanvas.Font.Color := TextColor;
  if FSample = nil then
  begin
    ACanvas.TextOut(TtfPreviewGap, TtfPreviewGap, 'Нет образца: проверьте ' +
      'параметры слева');
    Exit;
  end;
  ACanvas.TextOut(TtfPreviewGap, TtfPreviewGap, 'Образец 1:1 (щелчок - ' +
    'символ крупно):');
  ACanvas.Draw(TtfPreviewGap, TtfPreviewGap + FTextHeight + 4, FSample);

  // Выбранный символ крупно: точки и сетка
  Scale := ZoomScale;
  TopY := ZoomTop;
  LeftX := TtfPreviewGap;
  if (FSelCode >= 32) and (FSelCode < 127) then
    CharText := '''' + Chr(FSelCode) + ''''
  else
    CharText := '';
  ACanvas.Brush.Color := BackColor;
  ACanvas.TextOut(TtfPreviewGap, TopY - FTextHeight - 4, Format('Символ %d ' +
    '($%.2x) %s, x%d:', [FSelCode, FSelCode, CharText, Scale]));
  Offset := FFont.GlyphOffset(FSelCode);
  if Offset < 0 then
    Exit;
  BytesPerRow := FFont.SizeX div 8;
  if Scale >= 4 then
    GridColor := $00303030
  else
    GridColor := clBlack;
  for Row := 0 to FFont.SizeY - 1 do
    for Col := 0 to FFont.SizeX - 1 do
    begin
      IsSet := (FFont.Data[Offset + Row * BytesPerRow + Col div 8] and
                ($80 shr (Col mod 8))) <> 0;
      if IsSet then
        ACanvas.Brush.Color := clWhite
      else
        ACanvas.Brush.Color := clBlack;
      ACanvas.FillRect(Rect(LeftX + Col * Scale, TopY + Row * Scale,
        LeftX + (Col + 1) * Scale, TopY + (Row + 1) * Scale));
      if Scale >= 4 then
      begin
        ACanvas.Brush.Color := GridColor;
        ACanvas.FrameRect(Rect(LeftX + Col * Scale, TopY + Row * Scale,
          LeftX + (Col + 1) * Scale + 1, TopY + (Row + 1) * Scale + 1));
      end;
    end;
end;

procedure TDlgTtfToUtft.PreviewClick(PosX, PosY: Integer);
var
  LocalX, LocalY, CodeIdx: Integer;
begin
  if (FSample = nil) or (FFont.SampleCols = 0) then
    Exit;
  LocalX := PosX - TtfPreviewGap;
  LocalY := PosY - (TtfPreviewGap + FTextHeight + 4);
  if (LocalX < 0) or (LocalY < 0) or (LocalY >= FSample.Height) or
     (LocalX >= FFont.SampleCols * FFont.SizeX) then
    Exit;
  CodeIdx := (LocalY div FFont.SizeY) * FFont.SampleCols + LocalX div FFont.SizeX;
  if CodeIdx <= High(FFont.SampleCodes) then
  begin
    FSelCode := FFont.SampleCodes[CodeIdx];
    FPreview.Invalidate;
  end;
end;

procedure TDlgTtfToUtft.BtnTtfClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
  Family: string;
  FontIdx: Integer;
begin
  OpenDlg := TOpenDialog.Create(Self);
  try
    OpenDlg.Title := 'Файл шрифта';
    OpenDlg.Filter := 'Шрифты (*.ttf;*.otf)|*.ttf;*.otf|Все файлы (*.*)|*.*';
    OpenDlg.Options := [ofFileMustExist, ofHideReadOnly, ofEnableSizing];
    if not OpenDlg.Execute then
      Exit;
    Family := TtfFamilyName(OpenDlg.FileName);
    if Family = '' then
    begin
      MessageDlg('В файле не найдено имя шрифта (таблица name):'#13#10 +
        OpenDlg.FileName, mtWarning, [mbOK], 0);
      Exit;
    end;
    if FPrivateFiles.IndexOf(OpenDlg.FileName) < 0 then
    begin
      if TtfAddFontResourceEx(PAnsiChar(AnsiString(OpenDlg.FileName)),
         FR_PRIVATE_FLAG, nil) = 0 then
      begin
        MessageDlg('Шрифт не подключён (AddFontResourceEx):'#13#10 +
          OpenDlg.FileName, mtWarning, [mbOK], 0);
        Exit;
      end;
      FPrivateFiles.Add(OpenDlg.FileName);
    end;
    FontIdx := FCmbFont.Items.IndexOf(Family);
    if FontIdx < 0 then
      FontIdx := FCmbFont.Items.Add(Family);
    FCmbFont.ItemIndex := FontIdx;
    FNameEdited := False;
    ParamChange(nil);
  finally
    OpenDlg.Free;
  end;
end;

// Наибольший размер, при котором точки всех символов входят в клетку
procedure TDlgTtfToUtft.BtnFitClick(Sender: TObject);
var
  Params, Probe: TTtfParams;
  Ink: TTtfInk;
  LowSize, HighSize, MidSize, BestSize: Integer;

  function Fits(ASize: Integer; var AInk: TTtfInk): Boolean;
  begin
    Probe := Params;
    Probe.PixelSize := ASize;
    Probe.OffsetX := 0;
    Probe.OffsetY := 0;
    AInk := TtfMeasureInk(Probe);
    Result := AInk.Found and (AInk.Bottom - AInk.Top + 1 <= Params.CellH);
    if Result then
    begin
      if Params.Center then
        // По центру: левая и правая точки - внутри клетки
        Result := (AInk.Left >= 0) and (AInk.Right < Params.CellW)
      else
        Result := AInk.Right - AInk.Left + 1 <= Params.CellW;
    end;
  end;

begin
  if not ReadParams(Params) then
    Exit;
  Screen.Cursor := crHourGlass;
  try
    LowSize := 2;
    HighSize := Params.CellH * 3;
    BestSize := 0;
    while LowSize <= HighSize do
    begin
      MidSize := (LowSize + HighSize) div 2;
      if Fits(MidSize, Ink) then
      begin
        BestSize := MidSize;
        LowSize := MidSize + 1;
      end
      else
        HighSize := MidSize - 1;
    end;
    if BestSize = 0 then
      Exit;
    Fits(BestSize, Ink);
    Params.PixelSize := BestSize;
    // По высоте - в середине клетки
    Params.OffsetY := (Params.CellH - (Ink.Bottom - Ink.Top + 1)) div 2 - Ink.Top;
    if Params.Center then
      Params.OffsetX := 0
    else
      Params.OffsetX := (Params.CellW - (Ink.Right - Ink.Left + 1)) div 2 - Ink.Left;
    WriteParams(Params);
  finally
    Screen.Cursor := crDefault;
  end;
  Rebuild;
end;

procedure TDlgTtfToUtft.BtnSaveClick(Sender: TObject);
var
  SaveDlg: TSaveDialog;
  Params: TTtfParams;
  Source: TStringList;
  ArrayName, Comment: string;
  CharIdx: Integer;
begin
  FTimer.Enabled := False;
  Rebuild;
  if not ReadParams(Params) or (Length(FFont.Data) = 0) then
    Exit;
  ArrayName := Trim(FEdName.Text);
  if ArrayName = '' then
  begin
    MessageDlg('Нет имени массива', mtWarning, [mbOK], 0);
    Exit;
  end;
  for CharIdx := 1 to Length(ArrayName) do
    if not (ArrayName[CharIdx] in ['A'..'Z', 'a'..'z', '0'..'9', '_']) or
       ((CharIdx = 1) and (ArrayName[CharIdx] in ['0'..'9'])) then
    begin
      MessageDlg('Имя массива - латинские буквы, цифры и _, не с цифры: ' +
        ArrayName, mtWarning, [mbOK], 0);
      Exit;
    end;
  FFont.Name := ArrayName;
  SaveDlg := TSaveDialog.Create(Self);
  try
    SaveDlg.Title := 'Шрифт UTFT';
    SaveDlg.Filter := 'Шрифты UTFT (*.c)|*.c|Все файлы (*.*)|*.*';
    SaveDlg.DefaultExt := 'c';
    SaveDlg.FileName := ArrayName + '.c';
    SaveDlg.Options := [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing,
      ofPathMustExist];
    if FDefaultFolder <> '' then
      SaveDlg.InitialDir := FDefaultFolder;
    if not SaveDlg.Execute then
      Exit;
    Comment := 'Made by unIDE TTF to UTFT from "' + Params.FontName + '"';
    if Params.Bold then
      Comment := Comment + ' bold';
    if Params.Italic then
      Comment := Comment + ' italic';
    Comment := Comment + Format(', %d px', [Params.PixelSize]);
    Source := TStringList.Create;
    try
      Source.Text := TtfFontSource(FFont, Comment);
      try
        Source.SaveToFile(SaveDlg.FileName);
      except
        on E: Exception do
        begin
          MessageDlg('Файл не записан: ' + E.Message, mtError, [mbOK], 0);
          Exit;
        end;
      end;
    finally
      Source.Free;
    end;
    FDefaultFolder := ExtractFileDir(SaveDlg.FileName);
    if Assigned(FOnSaved) then
      FOnSaved(SaveDlg.FileName);
  finally
    SaveDlg.Free;
  end;
end;

procedure TDlgTtfToUtft.BtnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TDlgTtfToUtft.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    Close
  else if (Key = Ord('S')) and (ssCtrl in Shift) then
    BtnSaveClick(nil)
  else
    Exit;
  Key := 0;
end;

procedure TDlgTtfToUtft.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveSettings;
  Action := caFree;
end;

procedure TDlgTtfToUtft.UpdateColors;
begin
  Color := UiThemeColor('Window.BG');
  Font.Color := UiThemeColor('Window.Text');
  FScroll.Color := UiThemeColor('List.BG');
end;

procedure TDlgTtfToUtft.UMUiThemeChanged(var Message: TMessage);
begin
  UpdateColors;
  FPreview.Invalidate;
  Message.Result := 1;
end;

// ---------------------------------------------------------------------------
//  Параметры в ini
// ---------------------------------------------------------------------------

procedure TDlgTtfToUtft.SetIni(const AIniFile, ADefaultFolder: string);
begin
  FIniFile := AIniFile;
  FDefaultFolder := ADefaultFolder;
  LoadSettings;
  Rebuild;
end;

procedure TDlgTtfToUtft.LoadSettings;
var
  Ini: TBufIniFile;
  Params: TTtfParams;
  Folder: string;
begin
  if (FIniFile = '') or not FileExists(FIniFile) then
    Exit;
  if not ReadParams(Params) then
    Exit;
  Ini := TBufIniFile.Create(FIniFile);
  try
    Params.FontName := Ini.ReadString(TtfSection, 'Font', Params.FontName);
    Params.Bold := Ini.ReadBool(TtfSection, 'Bold', Params.Bold);
    Params.Italic := Ini.ReadBool(TtfSection, 'Italic', Params.Italic);
    Params.Smooth := Ini.ReadBool(TtfSection, 'Smooth', Params.Smooth);
    Params.Center := Ini.ReadBool(TtfSection, 'Center', Params.Center);
    Params.CellW := Ini.ReadInteger(TtfSection, 'CellW', Params.CellW);
    Params.CellH := Ini.ReadInteger(TtfSection, 'CellH', Params.CellH);
    Params.PixelSize := Ini.ReadInteger(TtfSection, 'Size', Params.PixelSize);
    Params.OffsetX := Ini.ReadInteger(TtfSection, 'OffsetX', Params.OffsetX);
    Params.OffsetY := Ini.ReadInteger(TtfSection, 'OffsetY', Params.OffsetY);
    Params.Threshold := Ini.ReadInteger(TtfSection, 'Threshold', Params.Threshold);
    Params.FirstChar := Ini.ReadInteger(TtfSection, 'First', Params.FirstChar);
    Params.LastChar := Ini.ReadInteger(TtfSection, 'Last', Params.LastChar);
    Folder := Ini.ReadString(TtfSection, 'Folder', '');
    if (Folder <> '') and DirectoryExists(Folder) then
      FDefaultFolder := Folder;
    WriteParams(Params);
    FLoading := True;
    try
      FCmbRange.ItemIndex := Ini.ReadInteger(TtfSection, 'Range', 0);
      if (FCmbRange.ItemIndex < 0) then
        FCmbRange.ItemIndex := 0;
    finally
      FLoading := False;
    end;
  finally
    Ini.Free;
  end;
end;

procedure TDlgTtfToUtft.SaveSettings;
var
  Ini: TBufIniFile;
  Params: TTtfParams;
begin
  FPlaceSaved := True;
  if FIniFile = '' then
    Exit;
  if not ReadParams(Params) then
    Exit;
  Ini := TBufIniFile.Create(FIniFile);
  try
    // Шрифт из файла (.ttf) в следующий раз может быть не подключён -
    // тогда останется выбранный по умолчанию
    Ini.WriteString(TtfSection, 'Font', Params.FontName);
    Ini.WriteBool(TtfSection, 'Bold', Params.Bold);
    Ini.WriteBool(TtfSection, 'Italic', Params.Italic);
    Ini.WriteBool(TtfSection, 'Smooth', Params.Smooth);
    Ini.WriteBool(TtfSection, 'Center', Params.Center);
    Ini.WriteInteger(TtfSection, 'CellW', Params.CellW);
    Ini.WriteInteger(TtfSection, 'CellH', Params.CellH);
    Ini.WriteInteger(TtfSection, 'Size', Params.PixelSize);
    Ini.WriteInteger(TtfSection, 'OffsetX', Params.OffsetX);
    Ini.WriteInteger(TtfSection, 'OffsetY', Params.OffsetY);
    Ini.WriteInteger(TtfSection, 'Threshold', Params.Threshold);
    Ini.WriteInteger(TtfSection, 'First', Params.FirstChar);
    Ini.WriteInteger(TtfSection, 'Last', Params.LastChar);
    Ini.WriteInteger(TtfSection, 'Range', FCmbRange.ItemIndex);
    Ini.WriteString(TtfSection, 'Folder', FDefaultFolder);
  finally
    Ini.Free;
  end;
end;

end.
