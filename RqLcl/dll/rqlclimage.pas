// ---------------------------------------------------------------------------
//  RqLcl: QIMAGE (TImage) и QIMAGELIST (TImageList), кэш картинок RapidQ
//  (глава 8: Image.Icon = Form.Icon, Button.BMP = ImageList.GetBMP(0)).
//
//  Кэш: чтение BMP / Icon и GetBMP / GetICO кладут картинку в кэш и
//  возвращают ""; запись BMP = "" / Icon = "" берёт картинку из кэша
//  (кэш - в rqlclmisc: MiscBmpCache, MiscIcoCache).
//  BMPHandle / ICOHandle - ресурс $RESOURCE (RCDATA в exe).
// ---------------------------------------------------------------------------
unit rqlclimage;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Controls, ExtCtrls, Graphics, ImgList, Forms,
  LazUTF8, rqlclmisc;

function ImgGetInt(AObj: TObject; const AProp: string;
                   out AValue: Integer): Boolean;
function ImgSetInt(AObj: TObject; const AProp: string;
                   AValue: Integer): Boolean;
function ImgGetStr(AObj: TObject; const AProp: string;
                   out AValue: string): Boolean;
function ImgSetStr(AObj: TObject; const AProp: string;
                   const AValue: string): Boolean;
function ImgCallEx(AObj: TObject; const AMethod, AStr: string;
                   AInt1, AInt2, AInt3: Integer;
                   out AIntResult: Integer): Boolean;
// Рисование, которого нет в GridDraw: Draw, StretchDraw, TextRect
function ImgDraw(AObj: TObject; const AMethod, AStr: string;
                 const AInts: array of Integer; out AResult: Integer): Boolean;
// С другим объектом: QIMAGE.CopyRect(D, Image, S), QIMAGELIST.Draw(Image, X, Y, i)
function ImgCallObjInts(AObj: TObject; const AMethod: string; AOther: TObject;
                        const AInts: array of Integer;
                        out AResult: Integer): Boolean;

implementation

procedure NeedInts(const AMethod: string; const AInts: array of Integer;
                   ACount: Integer);
begin
  if Length(AInts) < ACount then
    raise Exception.Create(AMethod + ': ' + IntToStr(ACount) +
                           ' numbers expected');
end;

// Картинка по строке RapidQ: "" - кэш, иначе файл (в кодировке Windows)
procedure LoadBitmapArg(const AValue: string; ABitmap: TBitmap);
begin
  if AValue = '' then
    ABitmap.Assign(MiscBmpCache)
  else
    ABitmap.LoadFromFile(WinCPToUTF8(AValue));
end;

procedure LoadIconArg(const AValue: string; AIcon: TIcon);
begin
  if AValue = '' then
    AIcon.Assign(MiscIcoCache)
  else
    AIcon.LoadFromFile(WinCPToUTF8(AValue));
end;

// Ресурс $RESOURCE - в картинку; нет ресурса - ошибка
procedure LoadBitmapRes(AResId: Integer; ABitmap: TBitmap);
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

procedure LoadIconRes(AResId: Integer; AIcon: TIcon);
var
  ResStream: TStream;
begin
  ResStream := MiscResourceStream(AResId);
  if ResStream = nil then
    raise Exception.Create('ICOHandle: no resource ' + IntToStr(AResId));
  try
    AIcon.LoadFromStream(ResStream);
  finally
    ResStream.Free;
  end;
end;

procedure CheckIndex(const AWhat: string; AIndex, ACount: Integer);
begin
  if (AIndex < 0) or (AIndex >= ACount) then
    raise Exception.Create(AWhat + '(' + IntToStr(AIndex) + '): out of 0..' +
                           IntToStr(ACount - 1));
end;

// Картинка QIMAGE - в кэш
procedure ImageToCache(AImage: TImage);
begin
  if AImage.Picture.Graphic = nil then
    MiscBmpCache.SetSize(0, 0)
  else
    MiscBmpCache.Assign(AImage.Picture.Graphic);
end;

function ImgGetInt(AObj: TObject; const AProp: string;
                   out AValue: Integer): Boolean;
var
  Prop: string;
  DrawCanvas: TCanvas;
begin
  Result := False;
  AValue := 0;
  Prop := UpperCase(AProp);
  // CopyMode - у всех, у кого есть холст (QIMAGE, QCANVAS, QBITMAP...)
  if Prop = 'COPYMODE' then
  begin
    DrawCanvas := CanvasOf(AObj);
    if DrawCanvas <> nil then
    begin
      AValue := MiscCopyModeFromLcl(DrawCanvas.CopyMode);
      Result := True;
      Exit;
    end;
  end;
  if AObj is TImage then
  begin
    Result := True;
    if Prop = 'INCREMENTALDISPLAY' then
      AValue := 0
    else
      Result := False;
  end
  else if AObj is TCustomImageList then
  begin
    Result := True;
    if Prop = 'COUNT' then
      AValue := TCustomImageList(AObj).Count
    else
      Result := False;
  end;
end;

function ImgSetInt(AObj: TObject; const AProp: string;
                   AValue: Integer): Boolean;
var
  Prop: string;
  NewIcon: TIcon;
  DrawCanvas: TCanvas;
begin
  Result := False;
  Prop := UpperCase(AProp);
  if Prop = 'COPYMODE' then
  begin
    DrawCanvas := CanvasOf(AObj);
    if DrawCanvas <> nil then
    begin
      DrawCanvas.CopyMode := MiscCopyModeToLcl(AValue);
      Result := True;
      Exit;
    end;
  end;
  if not (AObj is TImage) then
    Exit;
  Result := True;
  if Prop = 'BMPHANDLE' then
    LoadBitmapRes(AValue, TImage(AObj).Picture.Bitmap)
  else if Prop = 'ICOHANDLE' then
  begin
    NewIcon := TIcon.Create;
    try
      LoadIconRes(AValue, NewIcon);
      TImage(AObj).Picture.Icon := NewIcon;
    finally
      NewIcon.Free;
    end;
  end
  // в LCL нет; рисование и так сразу целиком
  else if Prop = 'INCREMENTALDISPLAY' then
  else
    Result := False;
end;

function ImgGetStr(AObj: TObject; const AProp: string;
                   out AValue: string): Boolean;
var
  Prop: string;
begin
  Result := False;
  AValue := '';
  Prop := UpperCase(AProp);
  if (AObj is TImage) and (Prop = 'BMP') then
  begin
    ImageToCache(TImage(AObj));
    Result := True;
  end
  else if (AObj is TImage) and (Prop = 'ICON') then
  begin
    if TImage(AObj).Picture.Graphic is TIcon then
      MiscIcoCache.Assign(TImage(AObj).Picture.Icon);
    Result := True;
  end
  else if (AObj is TCustomForm) and (Prop = 'ICON') then
  begin
    MiscIcoCache.Assign(TCustomForm(AObj).Icon);
    Result := True;
  end;
end;

function ImgSetStr(AObj: TObject; const AProp: string;
                   const AValue: string): Boolean;
var
  Prop: string;
  NewIcon: TIcon;
begin
  Result := False;
  Prop := UpperCase(AProp);
  if (AObj is TImage) and (Prop = 'BMP') then
  begin
    LoadBitmapArg(AValue, TImage(AObj).Picture.Bitmap);
    Result := True;
  end
  else if ((AObj is TImage) or (AObj is TCustomForm)) and (Prop = 'ICON') then
  begin
    NewIcon := TIcon.Create;
    try
      LoadIconArg(AValue, NewIcon);
      if AObj is TImage then
        TImage(AObj).Picture.Icon := NewIcon
      else
        TCustomForm(AObj).Icon := NewIcon;
    finally
      NewIcon.Free;
    end;
    Result := True;
  end;
end;

// QIMAGELIST: картинка с маской по цвету (Masked) или без
procedure ListAddBitmap(AList: TCustomImageList; AIndex: Integer;
                        ABitmap: TBitmap; AMaskColor: Integer);
begin
  if AIndex < 0 then
  begin
    if AList.Masked then
      AList.AddMasked(ABitmap, TColor(AMaskColor))
    else
      AList.Add(ABitmap, nil);
  end
  else
  begin
    CheckIndex('Insert', AIndex, AList.Count + 1);
    if AList.Masked then
      AList.InsertMasked(AIndex, ABitmap, TColor(AMaskColor))
    else
      AList.Insert(AIndex, ABitmap, nil);
  end;
end;

procedure ListAddIcon(AList: TCustomImageList; AIndex: Integer; AIcon: TIcon);
begin
  if AIndex < 0 then
    AList.AddIcon(AIcon)
  else
  begin
    CheckIndex('Insert', AIndex, AList.Count + 1);
    AList.InsertIcon(AIndex, AIcon);
  end;
end;

function ImageListCallEx(AList: TCustomImageList; const AMethod, AStr: string;
                         AInt1, AInt2, AInt3: Integer): Boolean;
var
  NewBitmap: TBitmap;
  NewIcon: TIcon;
  ItemIdx: Integer;
begin
  Result := True;
  // Insert...: AInt1 - место; Add...: -1
  if (AMethod = 'ADDBMPFILE') or (AMethod = 'INSERTBMPFILE') or
     (AMethod = 'ADDBMPHANDLE') or (AMethod = 'INSERTBMPHANDLE') then
  begin
    NewBitmap := TBitmap.Create;
    try
      if Pos('HANDLE', AMethod) > 0 then
        LoadBitmapRes(AInt2, NewBitmap)
      else
        LoadBitmapArg(AStr, NewBitmap);
      if Copy(AMethod, 1, 3) = 'ADD' then
        ListAddBitmap(AList, -1, NewBitmap, AInt3)
      else
        ListAddBitmap(AList, AInt1, NewBitmap, AInt3);
    finally
      NewBitmap.Free;
    end;
  end
  else if (AMethod = 'ADDICOFILE') or (AMethod = 'INSERTICOFILE') or
          (AMethod = 'ADDICOHANDLE') or (AMethod = 'INSERTICOHANDLE') then
  begin
    NewIcon := TIcon.Create;
    try
      if Pos('HANDLE', AMethod) > 0 then
        LoadIconRes(AInt2, NewIcon)
      else
        LoadIconArg(AStr, NewIcon);
      if Copy(AMethod, 1, 3) = 'ADD' then
        ListAddIcon(AList, -1, NewIcon)
      else
        ListAddIcon(AList, AInt1, NewIcon);
    finally
      NewIcon.Free;
    end;
  end
  else if AMethod = 'CLEAR' then
    AList.Clear
  else if AMethod = 'DELETE' then
  begin
    CheckIndex('Delete', AInt1, AList.Count);
    AList.Delete(AInt1);
  end
  else if AMethod = 'GETBMP' then
  begin
    ItemIdx := AInt1;
    CheckIndex('GetBMP', ItemIdx, AList.Count);
    AList.GetBitmap(ItemIdx, MiscBmpCache);
  end
  else if AMethod = 'GETICO' then
  begin
    ItemIdx := AInt1;
    CheckIndex('GetICO', ItemIdx, AList.Count);
    AList.GetIcon(ItemIdx, MiscIcoCache);
  end
  else
    Result := False;
end;

function ImgCallEx(AObj: TObject; const AMethod, AStr: string;
                   AInt1, AInt2, AInt3: Integer;
                   out AIntResult: Integer): Boolean;
var
  Method: string;
  ImageCanvas: TCanvas;
begin
  Result := False;
  AIntResult := 1;
  Method := UpperCase(AMethod);
  if AObj is TCustomImageList then
  begin
    Result := ImageListCallEx(TCustomImageList(AObj), Method, AStr, AInt1,
                              AInt2, AInt3);
    Exit;
  end;
  // Pixel, TextWidth... - у всех, у кого есть холст
  ImageCanvas := CanvasOf(AObj);
  if ImageCanvas = nil then
    Exit;
  Result := True;
  if Method = 'GETPIXEL' then
    AIntResult := Integer(ImageCanvas.Pixels[AInt1, AInt2])
  else if Method = 'SETPIXEL' then
    ImageCanvas.Pixels[AInt1, AInt2] := TColor(AInt3)
  else if Method = 'TEXTWIDTH' then
    AIntResult := ImageCanvas.TextWidth(WinCPToUTF8(AStr))
  else if Method = 'TEXTHEIGHT' then
    AIntResult := ImageCanvas.TextHeight(WinCPToUTF8(AStr))
  else if Method = 'ROTATE' then
    raise Exception.Create('Rotate is not supported yet')
  else
    Result := False;
end;

function ImgDraw(AObj: TObject; const AMethod, AStr: string;
                 const AInts: array of Integer; out AResult: Integer): Boolean;
var
  Method: string;
  DrawCanvas: TCanvas;
  DrawBitmap: TBitmap;
  TextStyle: TTextStyle;
begin
  Result := False;
  AResult := 1;
  DrawCanvas := CanvasOf(AObj);
  if DrawCanvas = nil then
    Exit;
  Method := UpperCase(AMethod);
  Result := True;
  if (Method = 'DRAW') or (Method = 'STRETCHDRAW') then
  begin
    // Draw (x, y, картинка), StretchDraw (прямоугольник, картинка);
    // картинка - файл или "" (кэш)
    DrawBitmap := TBitmap.Create;
    try
      LoadBitmapArg(AStr, DrawBitmap);
      if Method = 'DRAW' then
      begin
        NeedInts(AMethod, AInts, 2);
        DrawCanvas.Draw(AInts[0], AInts[1], DrawBitmap);
      end
      else
      begin
        NeedInts(AMethod, AInts, 4);
        DrawCanvas.StretchDraw(Rect(AInts[0], AInts[1], AInts[2], AInts[3]),
                               DrawBitmap);
      end;
    finally
      DrawBitmap.Free;
    end;
  end
  else if Method = 'TEXTRECT' then
  begin
    // (прямоугольник, x, y, текст, цвет текста, цвет фона; -1 - прозрачный)
    NeedInts(AMethod, AInts, 8);
    DrawCanvas.Font.Color := TColor(AInts[6]);
    TextStyle := DrawCanvas.TextStyle;
    TextStyle.Clipping := True;
    if AInts[7] = -1 then
    begin
      DrawCanvas.Brush.Style := bsClear;
      TextStyle.Opaque := False;
    end
    else
    begin
      DrawCanvas.Brush.Style := bsSolid;
      DrawCanvas.Brush.Color := TColor(AInts[7]);
      TextStyle.Opaque := True;
    end;
    DrawCanvas.TextRect(Rect(AInts[0], AInts[1], AInts[2], AInts[3]),
                        AInts[4], AInts[5], WinCPToUTF8(AStr), TextStyle);
  end
  else
    Result := False;
end;

function ImgCallObjInts(AObj: TObject; const AMethod: string; AOther: TObject;
                        const AInts: array of Integer;
                        out AResult: Integer): Boolean;
var
  Method: string;
  SourceCanvas, TargetCanvas: TCanvas;
begin
  Result := False;
  AResult := 1;
  Method := UpperCase(AMethod);
  if (AObj is TCustomImageList) and (Method = 'DRAW') then
  begin
    // ImageList.Draw(Image, X, Y, Index)
    TargetCanvas := CanvasOf(AOther);
    if TargetCanvas = nil then
      raise Exception.Create('Draw: object has no canvas');
    NeedInts(AMethod, AInts, 3);
    CheckIndex('Draw', AInts[2], TCustomImageList(AObj).Count);
    TCustomImageList(AObj).Draw(TargetCanvas, AInts[0], AInts[1], AInts[2]);
    if AOther is TControl then
      TControl(AOther).Invalidate;
    Result := True;
  end
  else if Method = 'COPYRECT' then
  begin
    // Image.CopyRect(D, Image2, S): D, S - прямоугольники
    TargetCanvas := CanvasOf(AObj);
    SourceCanvas := CanvasOf(AOther);
    if (TargetCanvas = nil) or (SourceCanvas = nil) then
      Exit;
    NeedInts(AMethod, AInts, 8);
    TargetCanvas.CopyRect(Rect(AInts[0], AInts[1], AInts[2], AInts[3]),
                          SourceCanvas,
                          Rect(AInts[4], AInts[5], AInts[6], AInts[7]));
    Result := True;
  end;
end;

end.
