unit Graphics;

// ---------------------------------------------------------------------------
//  uniFAR (Free Pascal, без LCL): заменитель модуля Graphics из VCL - ровно
//  то, что нужно общим модулям unIDE FAR (UnFar, ClrScheme, SchemeLine):
//  цвет TColor и его имена, холст TCanvas поверх HDC (кисть, перо,
//  FillRect, Rectangle, линии, Draw) и TBitmap - битмап в памяти.
//
//  Этот модуль - только в пути модулей uniFAR (uniFAR\vcl). unIDE (Delphi 7)
//  берёт настоящий VCL; если uniFAR когда-нибудь перейдёт на LCL, эту папку
//  надо убрать из пути.
// ---------------------------------------------------------------------------

{$mode delphi}

interface

uses
  Windows, SysUtils, Classes;

type
  TColor = -$7FFFFFFF - 1..$7FFFFFFF;

  TBrushStyle = (bsSolid, bsClear);
  TPenStyle = (psSolid, psDash, psDot, psClear);

  TBrush = class
  public
    Color: TColor;
    Style: TBrushStyle;
  end;

  TPen = class
  public
    Color: TColor;
    Width: Integer;
    Style: TPenStyle;
  end;

  TCanvas = class
  private
    FHandle: HDC;
    FBrush: TBrush;
    FPen: TPen;
    FPenPos: TPoint;
    function MakePen: HPEN;
  public
    constructor Create;
    destructor Destroy; override;
    procedure FillRect(const ARect: TRect);
    procedure Rectangle(ALeft, ATop, ARight, ABottom: Integer);
    procedure MoveTo(AX, AY: Integer);
    procedure LineTo(AX, AY: Integer);
    procedure Draw(AX, AY: Integer; AGraphic: TObject);
    property Handle: HDC read FHandle write FHandle;
    property Brush: TBrush read FBrush;
    property Pen: TPen read FPen;
  end;

  // Битмап в памяти, совместимый с экраном: Canvas.Handle - его DC
  TBitmap = class
  private
    FWidth: Integer;
    FHeight: Integer;
    FDC: HDC;
    FBitmap: HBITMAP;
    FOldBitmap: HGDIOBJ;
    FCanvas: TCanvas;
    procedure Recreate;
    procedure FreeBitmap;
    procedure SetWidth(AValue: Integer);
    procedure SetHeight(AValue: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    property Width: Integer read FWidth write SetWidth;
    property Height: Integer read FHeight write SetHeight;
    property Canvas: TCanvas read FCanvas;
  end;

const
  clBlack = TColor($000000);
  clMaroon = TColor($000080);
  clGreen = TColor($008000);
  clOlive = TColor($008080);
  clNavy = TColor($800000);
  clPurple = TColor($800080);
  clTeal = TColor($808000);
  clGray = TColor($808080);
  clSilver = TColor($C0C0C0);
  clRed = TColor($0000FF);
  clLime = TColor($00FF00);
  clYellow = TColor($00FFFF);
  clBlue = TColor($FF0000);
  clFuchsia = TColor($FF00FF);
  clAqua = TColor($FFFF00);
  clWhite = TColor($FFFFFF);
  clMoneyGreen = TColor($C0DCC0);
  clSkyBlue = TColor($F0CAA6);
  clCream = TColor($F0FBFF);
  clMedGray = TColor($A4A0A0);
  clNone = TColor($1FFFFFFF);
  clDefault = TColor($20000000);
  // Цвета системы: $80000000 + номер COLOR_*
  clScrollBar = TColor($80000000);
  clBackground = TColor($80000001);
  clActiveCaption = TColor($80000002);
  clInactiveCaption = TColor($80000003);
  clMenu = TColor($80000004);
  clWindow = TColor($80000005);
  clWindowFrame = TColor($80000006);
  clMenuText = TColor($80000007);
  clWindowText = TColor($80000008);
  clCaptionText = TColor($80000009);
  clActiveBorder = TColor($8000000A);
  clInactiveBorder = TColor($8000000B);
  clAppWorkSpace = TColor($8000000C);
  clHighlight = TColor($8000000D);
  clHighlightText = TColor($8000000E);
  clBtnFace = TColor($8000000F);
  clBtnShadow = TColor($80000010);
  clGrayText = TColor($80000011);
  clBtnText = TColor($80000012);
  clInactiveCaptionText = TColor($80000013);
  clBtnHighlight = TColor($80000014);
  cl3DDkShadow = TColor($80000015);
  cl3DLight = TColor($80000016);
  clInfoText = TColor($80000017);
  clInfoBk = TColor($80000018);

function ColorToRGB(AColor: TColor): Longint;
// Как в VCL: имя (clRed) или '$00BBGGRR'
function ColorToString(AColor: TColor): string;
// Имя цвета или число ('$00FF0000', '16711680'); не разобрать - исключение
function StringToColor(const AText: string): TColor;

implementation

type
  TColorName = record
    Value: TColor;
    Name: string;
  end;

const
  ColorNames: array[0..46] of TColorName = (
    (Value: clBlack; Name: 'clBlack'), (Value: clMaroon; Name: 'clMaroon'),
    (Value: clGreen; Name: 'clGreen'), (Value: clOlive; Name: 'clOlive'),
    (Value: clNavy; Name: 'clNavy'), (Value: clPurple; Name: 'clPurple'),
    (Value: clTeal; Name: 'clTeal'), (Value: clGray; Name: 'clGray'),
    (Value: clSilver; Name: 'clSilver'), (Value: clRed; Name: 'clRed'),
    (Value: clLime; Name: 'clLime'), (Value: clYellow; Name: 'clYellow'),
    (Value: clBlue; Name: 'clBlue'), (Value: clFuchsia; Name: 'clFuchsia'),
    (Value: clAqua; Name: 'clAqua'), (Value: clWhite; Name: 'clWhite'),
    (Value: clMoneyGreen; Name: 'clMoneyGreen'),
    (Value: clSkyBlue; Name: 'clSkyBlue'), (Value: clCream; Name: 'clCream'),
    (Value: clMedGray; Name: 'clMedGray'), (Value: clNone; Name: 'clNone'),
    (Value: clDefault; Name: 'clDefault'),
    (Value: clScrollBar; Name: 'clScrollBar'),
    (Value: clBackground; Name: 'clBackground'),
    (Value: clActiveCaption; Name: 'clActiveCaption'),
    (Value: clInactiveCaption; Name: 'clInactiveCaption'),
    (Value: clMenu; Name: 'clMenu'), (Value: clWindow; Name: 'clWindow'),
    (Value: clWindowFrame; Name: 'clWindowFrame'),
    (Value: clMenuText; Name: 'clMenuText'),
    (Value: clWindowText; Name: 'clWindowText'),
    (Value: clCaptionText; Name: 'clCaptionText'),
    (Value: clActiveBorder; Name: 'clActiveBorder'),
    (Value: clInactiveBorder; Name: 'clInactiveBorder'),
    (Value: clAppWorkSpace; Name: 'clAppWorkSpace'),
    (Value: clHighlight; Name: 'clHighlight'),
    (Value: clHighlightText; Name: 'clHighlightText'),
    (Value: clBtnFace; Name: 'clBtnFace'),
    (Value: clBtnShadow; Name: 'clBtnShadow'),
    (Value: clGrayText; Name: 'clGrayText'),
    (Value: clBtnText; Name: 'clBtnText'),
    (Value: clInactiveCaptionText; Name: 'clInactiveCaptionText'),
    (Value: clBtnHighlight; Name: 'clBtnHighlight'),
    (Value: cl3DDkShadow; Name: 'cl3DDkShadow'),
    (Value: cl3DLight; Name: 'cl3DLight'),
    (Value: clInfoText; Name: 'clInfoText'),
    (Value: clInfoBk; Name: 'clInfoBk'));

function ColorToRGB(AColor: TColor): Longint;
begin
  if AColor < 0 then
    Result := Longint(GetSysColor(AColor and $FF))
  else
    Result := AColor;
end;

function ColorToString(AColor: TColor): string;
var
  NameIdx: Integer;
begin
  for NameIdx := Low(ColorNames) to High(ColorNames) do
    if ColorNames[NameIdx].Value = AColor then
    begin
      Result := ColorNames[NameIdx].Name;
      Exit;
    end;
  Result := '$' + IntToHex(Cardinal(AColor), 8);
end;

function StringToColor(const AText: string): TColor;
var
  NameIdx: Integer;
  Text: string;
begin
  Text := Trim(AText);
  for NameIdx := Low(ColorNames) to High(ColorNames) do
    if CompareText(ColorNames[NameIdx].Name, Text) = 0 then
    begin
      Result := ColorNames[NameIdx].Value;
      Exit;
    end;
  Result := TColor(StrToInt(Text));
end;

// ---------------------------------------------------------------------------

constructor TCanvas.Create;
begin
  inherited Create;
  FBrush := TBrush.Create;
  FBrush.Color := clWhite;
  FBrush.Style := bsSolid;
  FPen := TPen.Create;
  FPen.Color := clBlack;
  FPen.Width := 1;
  FPen.Style := psSolid;
end;

destructor TCanvas.Destroy;
begin
  FBrush.Free;
  FPen.Free;
  inherited Destroy;
end;

function TCanvas.MakePen: HPEN;
var
  PenStyle: Integer;
begin
  case FPen.Style of
    psDash: PenStyle := PS_DASH;
    psDot: PenStyle := PS_DOT;
    psClear: PenStyle := PS_NULL;
  else
    PenStyle := PS_SOLID;
  end;
  Result := CreatePen(PenStyle, FPen.Width, COLORREF(ColorToRGB(FPen.Color)));
end;

procedure TCanvas.FillRect(const ARect: TRect);
var
  BrushHandle: HBRUSH;
begin
  if (FHandle = 0) or (FBrush.Style = bsClear) then
    Exit;
  BrushHandle := CreateSolidBrush(COLORREF(ColorToRGB(FBrush.Color)));
  Windows.FillRect(FHandle, ARect, BrushHandle);
  DeleteObject(BrushHandle);
end;

procedure TCanvas.Rectangle(ALeft, ATop, ARight, ABottom: Integer);
var
  PenHandle: HPEN;
  BrushHandle: HBRUSH;
  OldPen, OldBrush: HGDIOBJ;
begin
  if FHandle = 0 then
    Exit;
  PenHandle := MakePen;
  if FBrush.Style = bsClear then
    BrushHandle := GetStockObject(NULL_BRUSH)
  else
    BrushHandle := CreateSolidBrush(COLORREF(ColorToRGB(FBrush.Color)));
  OldPen := SelectObject(FHandle, PenHandle);
  OldBrush := SelectObject(FHandle, BrushHandle);
  Windows.Rectangle(FHandle, ALeft, ATop, ARight, ABottom);
  SelectObject(FHandle, OldPen);
  SelectObject(FHandle, OldBrush);
  DeleteObject(PenHandle);
  if FBrush.Style <> bsClear then
    DeleteObject(BrushHandle);
end;

procedure TCanvas.MoveTo(AX, AY: Integer);
begin
  FPenPos := Point(AX, AY);
  if FHandle <> 0 then
    MoveToEx(FHandle, AX, AY, nil);
end;

procedure TCanvas.LineTo(AX, AY: Integer);
var
  PenHandle: HPEN;
  OldPen: HGDIOBJ;
begin
  if FHandle = 0 then
    Exit;
  PenHandle := MakePen;
  OldPen := SelectObject(FHandle, PenHandle);
  MoveToEx(FHandle, FPenPos.X, FPenPos.Y, nil);
  Windows.LineTo(FHandle, AX, AY);
  SelectObject(FHandle, OldPen);
  DeleteObject(PenHandle);
  FPenPos := Point(AX, AY);
end;

procedure TCanvas.Draw(AX, AY: Integer; AGraphic: TObject);
var
  Source: TBitmap;
begin
  if (FHandle = 0) or not (AGraphic is TBitmap) then
    Exit;
  Source := TBitmap(AGraphic);
  if (Source.Width > 0) and (Source.Height > 0) then
    BitBlt(FHandle, AX, AY, Source.Width, Source.Height,
      Source.Canvas.Handle, 0, 0, SRCCOPY);
end;

// ---------------------------------------------------------------------------

constructor TBitmap.Create;
begin
  inherited Create;
  FCanvas := TCanvas.Create;
  FDC := CreateCompatibleDC(0);
  FCanvas.Handle := FDC;
end;

destructor TBitmap.Destroy;
begin
  FreeBitmap;
  FCanvas.Handle := 0;
  if FDC <> 0 then
    DeleteDC(FDC);
  FCanvas.Free;
  inherited Destroy;
end;

procedure TBitmap.FreeBitmap;
begin
  if FBitmap <> 0 then
  begin
    SelectObject(FDC, FOldBitmap);
    DeleteObject(FBitmap);
    FBitmap := 0;
  end;
end;

procedure TBitmap.Recreate;
var
  ScreenDC: HDC;
begin
  FreeBitmap;
  if (FWidth <= 0) or (FHeight <= 0) then
    Exit;
  ScreenDC := GetDC(0);
  FBitmap := CreateCompatibleBitmap(ScreenDC, FWidth, FHeight);
  ReleaseDC(0, ScreenDC);
  if FBitmap <> 0 then
    FOldBitmap := SelectObject(FDC, FBitmap);
end;

procedure TBitmap.SetWidth(AValue: Integer);
begin
  if AValue = FWidth then
    Exit;
  FWidth := AValue;
  Recreate;
end;

procedure TBitmap.SetHeight(AValue: Integer);
begin
  if AValue = FHeight then
    Exit;
  FHeight := AValue;
  Recreate;
end;

end.
