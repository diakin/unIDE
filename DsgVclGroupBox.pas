unit DsgVclGroupBox;

// ---------------------------------------------------------------------------
//  Рамка с подписью для конструктора форм в сборке Lazarus: TGroupBox с
//  местом детей как в VCL.
//
//  В VCL Left/Top детей TGroupBox считаются от левого верхнего угла окна
//  рамки (вместе со строкой подписи). В LCL (win32) - от области под
//  подписью: GetLCLClientBoundsOffset (lcl/interfaces/win32/win32proc.pp)
//  для любого TCustomGroupBox сдвигает детей на высоту шрифта + 3 вниз и на
//  2 вправо. Форма Delphi (.dfm), прочитанная в LCL как есть, в конструкторе
//  выглядит иначе, чем в программе: всё внутри рамок ниже на строку подписи,
//  нижний ряд обрезан.
//
//  Здесь рамка - TCustomControl (не TCustomGroupBox), поэтому сдвига нет, и
//  Left/Top детей те же, что в .dfm и в программе Delphi. Класс назван
//  TGroupBox: имя класса (ClassName) в конструкторе сверяется с классом из
//  .dfm. В GetClass класс не регистрируется - палитра и прочий код видят
//  StdCtrls.TGroupBox; подменяет его только чтение формы конструктором.
//  Рисование - как у TCustomGroupBox.Paint Delphi 7 (с темой Windows и без).
//
//  Только для FPC; в Delphi модуль пустой.
// ---------------------------------------------------------------------------

interface

{$IFDEF FPC}
uses
  Types, LCLType, LCLIntf, Classes, Graphics, Controls, Themes;

type
  TGroupBox = class(TCustomControl)
  protected
    procedure Paint; override;
    procedure AdjustClientRect(var ARect: TRect); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Align;
    property Anchors;
    property AutoSize;
    property BidiMode;
    property BorderSpacing;
    property Caption;
    property ChildSizing;
    property ClientHeight;
    property ClientWidth;
    property Color;
    property Constraints;
    property DockSite;
    property DoubleBuffered;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property ParentBackground;
    property ParentBidiMode;
    property ParentColor;
    property ParentDoubleBuffered;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
    property OnStartDrag;
  end;
{$ENDIF}

implementation

{$IFDEF FPC}
type
  // Доступ к Color родителя
  TDsgGroupParentAcc = class(TControl);

constructor TGroupBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls, csCaptureMouse,
    csClickEvents, csSetCaption, csDoubleClicks, csReplicatable,
    csParentBackground];
  SetInitialBounds(0, 0, 185, 105);
end;

// Место детей с Align: как у TCustomGroupBox Delphi 7 (Ctl3D) - под
// строкой подписи, внутри рамки
procedure TGroupBox.AdjustClientRect(var ARect: TRect);
begin
  inherited AdjustClientRect(ARect);
  Canvas.Font := Font;
  Inc(ARect.Top, Canvas.TextHeight('0'));
  InflateRect(ARect, -2, -2);
end;

procedure TGroupBox.Paint;
var
  BackColor: TColor;
  CaptionRect, OuterRect, FrameVal: TRect;
  TextSize: TSize;
  Details: TThemedElementDetails;
  HeightPx: Integer;
  Str: string;
begin
  // Фон: свой Color; с ParentBackground - цвет родителя (в Delphi фон
  // родителя рисует тема Windows)
  if ParentBackground and (Parent <> nil) then
    BackColor := TDsgGroupParentAcc(TControl(Parent)).Color
  else
    BackColor := Color;
  if BackColor = clDefault then
    BackColor := clBtnFace;
  Str := Caption;
  with Canvas do
  begin
    Font := Self.Font;
    Brush.Style := bsSolid;
    Brush.Color := BackColor;
    FillRect(Rect(0, 0, Self.Width, Self.Height));

    if ThemeServices.ThemesEnabled then
    begin
      if Str <> '' then
      begin
        TextSize := TextExtent(Str);
        CaptionRect := Rect(8, 0, 8 + TextSize.cx, TextSize.cy);
      end
      else
        CaptionRect := Rect(0, 0, 0, 0);
      OuterRect := Rect(0, (CaptionRect.Bottom - CaptionRect.Top) div 2,
        Self.Width, Self.Height);
      if Self.Enabled then
        Details := ThemeServices.GetElementDetails(tbGroupBoxNormal)
      else
        Details := ThemeServices.GetElementDetails(tbGroupBoxDisabled);
      ExcludeClipRect(Handle, CaptionRect.Left, CaptionRect.Top,
        CaptionRect.Right, CaptionRect.Bottom);
      ThemeServices.DrawElement(Handle, Details, OuterRect);
      SelectClipRgn(Handle, 0);
      if Str <> '' then
        ThemeServices.DrawText(Handle, Details, Str, CaptionRect, DT_LEFT, 0);
    end
    else
    begin
      HeightPx := TextHeight('0');
      FrameVal := Rect(1, HeightPx div 2, Self.Width, Self.Height);
      Brush.Color := clBtnHighlight;
      FrameRect(FrameVal);
      Types.OffsetRect(FrameVal, -1, -1);
      Brush.Color := clBtnShadow;
      FrameRect(FrameVal);
      if Str <> '' then
      begin
        // Подпись с отступом 8 точек поверх рамки, на фоне рамки
        TextSize := TextExtent(Str);
        CaptionRect := Rect(8, 0, 8 + TextSize.cx, TextSize.cy);
        Brush.Color := BackColor;
        FillRect(CaptionRect);
        Brush.Style := bsClear;
        if not Self.Enabled then
          Font.Color := clGrayText;
        TextOut(CaptionRect.Left, CaptionRect.Top, Str);
      end;
    end;
  end;
end;
{$ENDIF}

end.
