unit FormPreview;

// ---------------------------------------------------------------------------
//  Превью формы по файлу .dfm - для списка модулей и форм (View Unit /
//  View Form): при наведении мыши на строку справа показывается вид формы.
//
//  Форма строится из .dfm (TReader, как в конструкторе форм), рисуется в
//  картинку (PaintTo) и уменьшается. Сверху рисуется полоса заголовка с
//  Caption формы - окно без рамки было бы трудно узнать.
//
//  Как рисуется картинка. Обход элементов формы по одному
//  (CaptureByWalk), каждый - в своё место картинки:
//    - элемент, который рисует VCL (панель, рамка группы, вкладка, сама
//      форма - с метками, фигурами, картинками на них): WM_ERASEBKGND и
//      WM_PAINT с DC картинки, как в PaintTo;
//    - стандартное окно Windows (поле, список, кнопка, вкладки): WM_PRINT
//      этому окну - так стандартные элементы рисуют себя в чужой DC.
//  Место элемента - по его окну (GetWindowRect, клиентская часть - по
//  ClientToScreen), дети - поверх родителя в порядке Controls.
//  Канва картинки на время рисования запирается (Lock): иначе VCL по ходу
//  освобождает её DC (FreeMemoryContexts), и картинка остаётся одним фоном
//  - так было в первых вариантах превью (журнал: окна нарисованы, а
//  картинка одного цвета).
//  Окна у элементов есть, только когда форма показана. Поэтому форма без
//  рамки вкладывается в AHost (панель превью) и ставится далеко за его
//  край: окна созданы и видимы, на экране их нет, фокус не уходит.
//
//  Что делается, чтобы чтение не мешало программе:
//    - код формы не выполняется: обработчики событий не подключаются
//      (OnFindMethod), ошибки свойств пропускаются (OnError);
//    - Active = True и Connected = True (наборы данных, соединения) из
//      текста убираются - иначе превью открывало бы базы и порты;
//      Visible, FormStyle, WindowState, Position и ActiveControl формы -
//      тоже: окно не должно показываться и забирать фокус;
//    - класс, которого в программе нет: сначала AMap (у unIDE -
//      DsgMapClass, аналог стороннего компонента, как в конструкторе),
//      иначе визуальный (в его тексте есть Width) - панель с именем
//      класса, невизуальный - пустой компонент.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, ExtCtrls;

type
  // Класс-аналог для класса, которого в программе нет; nil - аналога нет
  TFormPreviewMap = function(const AClassName: string): TComponentClass
                    of object;

// Картинка формы из файла ADfmFile (текстового или двоичного), не больше
// AMaxW x AMaxH; меньшая не растягивается. AMap - аналоги сторонних
// классов (может быть nil). AHost - видимое окно, в которое форма
// вкладывается на время снимка (панель превью). False - форму построить
// не удалось, причина - в AError; True - в AError заметка для журнала
// (сколько компонентов и окон, не вышла ли картинка одним цветом).
function FormPreviewMake(const ADfmFile: string; AMaxW, AMaxH: Integer;
                         AMap: TFormPreviewMap; AHost: TWinControl;
                         ABitmap: TBitmap; var AError: string): Boolean;

implementation

const
  PreviewCaptionHeight = 22;

type
  // Визуальный компонент, класса которого в программе нет
  TPreviewBox = class(TPanel);
  // Невизуальный компонент, класса которого в программе нет
  TPreviewNonVis = class(TComponent);

  // Обработчики чтения .dfm
  TPreviewReader = class
  public
    Visual: TStringList;    // классы без регистрации, у которых есть Width
    Map: TFormPreviewMap;   // аналоги сторонних классов
    procedure FindClass(Reader: TReader; const ClassName: string;
                        var ComponentClass: TComponentClass);
    procedure FindMethod(Reader: TReader; const MethodName: string;
                         var Address: Pointer; var Error: Boolean);
    procedure ReadError(Reader: TReader; const Message: string;
                        var Handled: Boolean);
    constructor Create;
    destructor Destroy; override;
  end;

constructor TPreviewReader.Create;
begin
  inherited Create;
  Visual := TStringList.Create;
  Visual.Sorted := True;
  Visual.Duplicates := dupIgnore;
end;

destructor TPreviewReader.Destroy;
begin
  Visual.Free;
  inherited Destroy;
end;

procedure TPreviewReader.FindClass(Reader: TReader; const ClassName: string;
                                   var ComponentClass: TComponentClass);
var
  Found: Integer;
  Mapped: TComponentClass;
begin
  if (ComponentClass <> nil) and ComponentClass.InheritsFrom(TComponent) then
    Exit;
  Mapped := nil;
  if Assigned(Map) then
    Mapped := Map(ClassName);
  if Mapped <> nil then
    ComponentClass := Mapped
  else if Visual.Find(ClassName, Found) then
    ComponentClass := TPreviewBox
  else
    ComponentClass := TPreviewNonVis;
end;

// Обработчик события не ищется - код формы в превью не работает
procedure TPreviewReader.FindMethod(Reader: TReader; const MethodName: string;
                                    var Address: Pointer; var Error: Boolean);
begin
  Address := nil;
  Error := False;
end;

procedure TPreviewReader.ReadError(Reader: TReader; const Message: string;
                                   var Handled: Boolean);
begin
  Handled := True;
end;

// Текст .dfm: двоичный (TPF0, ресурс) переводится в текстовый
function DfmText(const AFile: string): string;
var
  Src, Dst: TMemoryStream;
  Head: string;
begin
  Src := TMemoryStream.Create;
  Dst := TMemoryStream.Create;
  try
    Src.LoadFromFile(AFile);
    SetLength(Head, 4);
    if Src.Size >= 4 then
      Move(Src.Memory^, Head[1], 4)
    else
      Head := '';
    if Head = 'TPF0' then
    begin
      ObjectBinaryToText(Src, Dst);
      SetString(Result, PChar(Dst.Memory), Dst.Size);
    end
    else if (Head <> '') and (Head[1] = #$FF) then
    begin
      ObjectResourceToText(Src, Dst);
      SetString(Result, PChar(Dst.Memory), Dst.Size);
    end
    else
      SetString(Result, PChar(Src.Memory), Src.Size);
  finally
    Dst.Free;
    Src.Free;
  end;
end;

// Заголовок объекта: "object Name: TClass", "inherited ...", "inline ...";
// AClass - класс без индекса [n]
function ObjectHeader(const ALine: string; var AName, AClass: string): Boolean;
var
  Txt: string;
  ColonAt, SpaceAt, BracketAt: Integer;
begin
  Result := False;
  Txt := Trim(ALine);
  if not ((Copy(Txt, 1, 7) = 'object ') or (Copy(Txt, 1, 10) = 'inherited ') or
          (Copy(Txt, 1, 7) = 'inline ')) then
    Exit;
  SpaceAt := Pos(' ', Txt);
  Txt := Trim(Copy(Txt, SpaceAt + 1, MaxInt));
  ColonAt := Pos(':', Txt);
  if ColonAt = 0 then
  begin
    AName := '';
    AClass := Txt;
  end
  else
  begin
    AName := Trim(Copy(Txt, 1, ColonAt - 1));
    AClass := Trim(Copy(Txt, ColonAt + 1, MaxInt));
  end;
  BracketAt := Pos('[', AClass);
  if BracketAt > 0 then
    AClass := Trim(Copy(AClass, 1, BracketAt - 1));
  Result := AClass <> '';
end;

// Подготовка текста (см. начало модуля). AVisual - классы без регистрации
// с Width; ABoxes - имя=класс таких компонентов (подпись панели)
function PrepareText(const AText: string; AVisual, ABoxes: TStrings): string;
var
  Lines, Stack: TStringList;
  LineIdx, Depth: Integer;
  Txt, Name, Cls, Top: string;
begin
  Lines := TStringList.Create;
  Stack := TStringList.Create;
  try
    Lines.Text := AText;
    Depth := 0;
    LineIdx := 0;
    while LineIdx < Lines.Count do
    begin
      Txt := Trim(Lines[LineIdx]);
      if ObjectHeader(Lines[LineIdx], Name, Cls) then
      begin
        Stack.Add(Name + '=' + Cls);
        Inc(Depth);
      end
      else if CompareText(Txt, 'item') = 0 then
        Stack.Add('')
      else if (CompareText(Txt, 'end') = 0) or (CompareText(Txt, 'end>') = 0) then
      begin
        if Stack.Count > 0 then
        begin
          if Stack[Stack.Count - 1] <> '' then
            Dec(Depth);
          Stack.Delete(Stack.Count - 1);
        end;
      end
      else if Stack.Count > 0 then
      begin
        Top := Stack[Stack.Count - 1];
        // открытие баз и портов - мимо
        if (Copy(Txt, 1, 8) = 'Active =') or (Copy(Txt, 1, 11) = 'Connected =') then
        begin
          Lines.Delete(LineIdx);
          Continue;
        end;
        // окно превью не показывается
        if (Depth = 1) and (Stack.Count = 1) and
           ((Copy(Txt, 1, 10) = 'Visible = ') or
            (Copy(Txt, 1, 12) = 'FormStyle = ') or
            (Copy(Txt, 1, 14) = 'WindowState = ') or
            (Copy(Txt, 1, 11) = 'Position = ') or
            (Copy(Txt, 1, 16) = 'ActiveControl = ')) then
        begin
          Lines.Delete(LineIdx);
          Continue;
        end;
        // Width у объекта неизвестного класса - он визуальный
        if (Top <> '') and (Copy(Txt, 1, 8) = 'Width = ') then
        begin
          Cls := Copy(Top, Pos('=', Top) + 1, MaxInt);
          if GetClass(Cls) = nil then
          begin
            AVisual.Add(Cls);
            ABoxes.Add(Top);
          end;
        end;
      end;
      Inc(LineIdx);
    end;
    Result := Lines.Text;
  finally
    Stack.Free;
    Lines.Free;
  end;
end;

// Форма из текста .dfm - невидимая, без кода
function BuildForm(const AText: string; AMap: TFormPreviewMap;
                   ABoxes: TStrings): TForm;
var
  Src: TStringStream;
  Bin: TMemoryStream;
  Reader: TReader;
  Events: TPreviewReader;
  DfmSrc: string;
  CompIdx, BoxIdx: Integer;
  Comp: TComponent;
begin
  Result := nil;
  Events := TPreviewReader.Create;
  Events.Map := AMap;
  try
    DfmSrc := PrepareText(AText, Events.Visual, ABoxes);
    Src := TStringStream.Create(DfmSrc);
    Bin := TMemoryStream.Create;
    try
      ObjectTextToBinary(Src, Bin);
      Bin.Position := 0;
      Result := TForm.CreateNew(nil);
      try
        Reader := TReader.Create(Bin, 4096);
        try
          Reader.OnFindComponentClass := Events.FindClass;
          Reader.OnFindMethod := Events.FindMethod;
          Reader.OnError := Events.ReadError;
          Reader.ReadRootComponent(Result);
        finally
          Reader.Free;
        end;
      except
        FreeAndNil(Result);
        raise;
      end;
    finally
      Bin.Free;
      Src.Free;
    end;
  finally
    Events.Free;
  end;

  // Панели вместо неизвестных классов - с именем класса
  for CompIdx := 0 to Result.ComponentCount - 1 do
  begin
    Comp := Result.Components[CompIdx];
    if Comp is TPreviewBox then
    begin
      BoxIdx := ABoxes.IndexOfName(Comp.Name);
      if BoxIdx >= 0 then
        TPreviewBox(Comp).Caption := ABoxes.ValueFromIndex[BoxIdx]
      else
        TPreviewBox(Comp).Caption := Comp.Name;
    end;
  end;
end;

// Элемент рисует VCL (не стандартное окно Windows): WM_PAINT с DC в
// wParam он понимает (PaintHandler)
function VclPainted(ACtl: TWinControl): Boolean;
begin
  Result := (ACtl is TCustomControl) or (ACtl is TScrollingWinControl) or
            (ACtl.ClassType = TWinControl) or
            (CompareText(ACtl.ClassName, 'TTabSheet') = 0);
end;

// Элемент ACtl и его вложенные окна - в ADC. AOrigin - экранная точка,
// которая в картинке стоит в (0, ATop) (левый верхний угол клиентской
// части формы)
procedure WalkPaint(ACtl: TWinControl; ADC: HDC; const AOrigin: TPoint;
                    ATop: Integer; var ACount: Integer);
var
  WinRect: TRect;
  ClientPt: TPoint;
  SaveIdx, CtlIdx: Integer;
  Child: TControl;
begin
  if not ACtl.HandleAllocated then
    Exit;
  GetWindowRect(ACtl.Handle, WinRect);
  ClientPt := Point(0, 0);
  Windows.ClientToScreen(ACtl.Handle, ClientPt);
  SaveIdx := SaveDC(ADC);
  try
    if VclPainted(ACtl) then
    begin
      // клиентская часть: фон и рисунок VCL вместе с метками и фигурами
      SetViewportOrgEx(ADC, ClientPt.X - AOrigin.X, ClientPt.Y - AOrigin.Y +
                       ATop, nil);
      IntersectClipRect(ADC, 0, 0, ACtl.ClientWidth, ACtl.ClientHeight);
      ACtl.Perform(WM_ERASEBKGND, Integer(ADC), Integer(ADC));
      ACtl.Perform(WM_PAINT, Integer(ADC), 0);
    end
    else
    begin
      // стандартное окно - целиком, с рамкой
      SetViewportOrgEx(ADC, WinRect.Left - AOrigin.X, WinRect.Top - AOrigin.Y +
                       ATop, nil);
      IntersectClipRect(ADC, 0, 0, WinRect.Right - WinRect.Left,
                        WinRect.Bottom - WinRect.Top);
      SendMessage(ACtl.Handle, WM_PRINT, Integer(ADC), PRF_NONCLIENT or
                  PRF_CLIENT or PRF_ERASEBKGND);
    end;
    Inc(ACount);
  finally
    RestoreDC(ADC, SaveIdx);
  end;
  // вложенные окна - поверх, в порядке Controls (нижние раньше)
  for CtlIdx := 0 to ACtl.ControlCount - 1 do
  begin
    Child := ACtl.Controls[CtlIdx];
    if (Child is TWinControl) and Child.Visible then
      WalkPaint(TWinControl(Child), ADC, AOrigin, ATop, ACount);
  end;
end;

// Форма - в AHost за его край, видима (окна элементов созданы); обход
// элементов в ADC с отступом сверху ATop; форма прячется. Число
// нарисованных окон - в результат
function CaptureByWalk(AForm: TForm; AHost: TWinControl; ADC: HDC;
                       ATop, AWidth, AHeight: Integer): Integer;
var
  Origin: TPoint;
begin
  Result := 0;
  AForm.Parent := AHost;
  AForm.SetBounds(-30000, -30000, AWidth, AHeight);
  AForm.Visible := True;
  try
    Origin := Point(0, 0);
    Windows.ClientToScreen(AForm.Handle, Origin);
    WalkPaint(AForm, ADC, Origin, ATop, Result);
  finally
    AForm.Visible := False;
  end;
end;

// Сколько разных цветов в клиентской части картинки (до 3) - для
// записи в журнал: один цвет - на картинке только фон
function ColorsIn(ABitmap: TBitmap; ATop: Integer): Integer;
var
  PosX, PosY, StepX, StepY: Integer;
  First, Pixel: TColor;
begin
  Result := 0;
  if (ABitmap.Width < 2) or (ABitmap.Height <= ATop + 1) then
    Exit;
  First := ABitmap.Canvas.Pixels[1, ATop + 1];
  Result := 1;
  StepX := ABitmap.Width div 40 + 1;
  StepY := (ABitmap.Height - ATop) div 40 + 1;
  PosY := ATop + 1;
  while PosY < ABitmap.Height do
  begin
    PosX := 1;
    while PosX < ABitmap.Width do
    begin
      Pixel := ABitmap.Canvas.Pixels[PosX, PosY];
      if Pixel <> First then
      begin
        Result := 2;
        Exit;
      end;
      Inc(PosX, StepX);
    end;
    Inc(PosY, StepY);
  end;
end;

function FormPreviewMake(const ADfmFile: string; AMaxW, AMaxH: Integer;
                         AMap: TFormPreviewMap; AHost: TWinControl;
                         ABitmap: TBitmap; var AError: string): Boolean;
var
  Form: TForm;
  Boxes: TStringList;
  Full: TBitmap;
  FullW, FullH, ClientW, ClientH, DstW, DstH, Painted: Integer;
  Scale: Double;
  CapRect: TRect;
begin
  Result := False;
  AError := '';
  Form := nil;
  Boxes := TStringList.Create;
  Full := TBitmap.Create;
  try
    try
      Form := BuildForm(DfmText(ADfmFile), AMap, Boxes);
      ClientW := Form.ClientWidth;
      ClientH := Form.ClientHeight;
      if (ClientW <= 0) or (ClientH <= 0) then
      begin
        AError := 'у формы нулевой размер';
        Exit;
      end;
      FullW := ClientW;
      FullH := ClientH + PreviewCaptionHeight;

      // Без рамки: окно - ровно клиентская часть формы
      Form.BorderStyle := bsNone;

      // Во весь размер: полоса заголовка и клиентская часть формы
      Full.PixelFormat := pf24bit;
      Full.Width := FullW;
      Full.Height := FullH;
      CapRect := Rect(0, 0, FullW, PreviewCaptionHeight);
      Full.Canvas.Brush.Color := clActiveCaption;
      Full.Canvas.FillRect(CapRect);
      Full.Canvas.Font.Name := 'Tahoma';
      Full.Canvas.Font.Height := -12;
      Full.Canvas.Font.Style := [fsBold];
      Full.Canvas.Font.Color := clCaptionText;
      Full.Canvas.Brush.Style := bsClear;
      Full.Canvas.TextOut(6, (PreviewCaptionHeight - Full.Canvas.TextHeight('W'))
                          div 2, Form.Caption);
      Full.Canvas.Brush.Style := bsSolid;
      Full.Canvas.Brush.Color := Form.Color;
      Full.Canvas.FillRect(Rect(0, PreviewCaptionHeight, FullW, FullH));
      // Канва картинки - запертой, пока её DC отдан элементам: пока они
      // рисуются, VCL создаёт другие картинки (буферы кнопок, значки) и
      // освобождает DC незапертых канв (FreeMemoryContexts) - всё
      // нарисованное после этого уходило в удалённый DC, и картинка
      // оставалась одним фоном
      Full.Canvas.Lock;
      try
        if (AHost <> nil) and AHost.HandleAllocated then
          Painted := CaptureByWalk(Form, AHost, Full.Canvas.Handle,
                                   PreviewCaptionHeight, ClientW, ClientH)
        else
        begin
          Form.PaintTo(Full.Canvas.Handle, 0, PreviewCaptionHeight);
          Painted := -1;
        end;
      finally
        Full.Canvas.Unlock;
      end;
      // для журнала: что вышло (AError при успехе - заметка)
      AError := 'компонентов ' + IntToStr(Form.ComponentCount) +
                ', нарисовано окон ' + IntToStr(Painted);
      if ColorsIn(Full, PreviewCaptionHeight) < 2 then
        AError := AError + ', картинка одного цвета';

      // Уменьшение до места справа; больше своего размера - нет
      Scale := 1;
      if FullW > AMaxW then
        Scale := AMaxW / FullW;
      if FullH * Scale > AMaxH then
        Scale := AMaxH / FullH;
      DstW := Round(FullW * Scale);
      DstH := Round(FullH * Scale);
      if DstW < 1 then
        DstW := 1;
      if DstH < 1 then
        DstH := 1;
      ABitmap.PixelFormat := pf24bit;
      ABitmap.Width := DstW;
      ABitmap.Height := DstH;
      ABitmap.Canvas.Lock;
      Full.Canvas.Lock;
      try
        SetStretchBltMode(ABitmap.Canvas.Handle, HALFTONE);
        SetBrushOrgEx(ABitmap.Canvas.Handle, 0, 0, nil);
        StretchBlt(ABitmap.Canvas.Handle, 0, 0, DstW, DstH,
                   Full.Canvas.Handle, 0, 0, FullW, FullH, SRCCOPY);
      finally
        Full.Canvas.Unlock;
        ABitmap.Canvas.Unlock;
      end;
      // Рамка окна
      ABitmap.Canvas.Brush.Color := clGray;
      ABitmap.Canvas.FrameRect(Rect(0, 0, DstW, DstH));
      Result := True;
    except
      on E: Exception do
        AError := E.Message;
    end;
  finally
    Form.Free;
    Full.Free;
    Boxes.Free;
  end;
end;

end.
