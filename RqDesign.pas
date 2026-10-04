unit RqDesign;

// ---------------------------------------------------------------------------
//  Конструктор форм RapidQ: заглушки компонентов
//
//  Форму RapidQ показывает тот же TFormDesigner, что и формы Delphi: из
//  CREATE-блоков строится текст в формате .dfm (Unit1, RqDsgBuildDfm), и
//  конструктор читает его как обычную форму. Компоненты RapidQ в этом тексте
//  - объекты TRqShape: окно, которое рисует себя по виду RapidQ-класса
//  (кнопка, поле ввода, панель...). Настоящих контролов VCL под RapidQ-
//  компоненты нет: свойства у них свои, по описанию классов (ComponentAll.
//  data), и значения бывают выражениями.
//
//  Вид класса - по первому встроенному классу в цепочке EXTENDS: QToolBarEX
//  EXTENDS QPANEL рисуется панелью. Класс без известного вида - серый
//  прямоугольник с именем и классом.
//
//  Невизуальные (QTIMER, QFILESTREAM, диалоги) - TRqNonVis: конструктор
//  показывает их значками. Меню (QMAINMENU, QPOPUPMENU, QMENUITEM) - меню
//  VCL: строка меню у формы видна так же, как в работающей программе.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, RqComponents;

type
  TRqKind = (rkBox, rkButton, rkOval, rkEdit, rkMemo, rkLabel, rkCheck,
             rkRadio, rkPanel, rkGroup, rkScrollBox, rkCombo, rkScrollBar,
             rkTrack, rkGauge, rkHeader, rkStatus, rkTab, rkSplitter,
             rkImage);

  // Визуальный компонент RapidQ на форме конструктора
  TRqShape = class(TCustomControl)
  private
    FRqClass: string;
    FKind: TRqKind;
    FText: string;
    FChecked: Boolean;
    FBevelOuter: Integer;
    FBevelInner: Integer;
    FBorderStyle: Integer;
    FAlignment: Integer;
    FDisabled: Boolean;
    // QTABCONTROL: названия вкладок (через #10), выбранная, размеры,
    // цвет невыбранных (clNone - как у самого компонента)
    FTabs: string;
    FTabIndex: Integer;
    FTabHeight: Integer;
    FTabWidth: Integer;
    FTabColor: TColor;
    // QSCROLLBAR: sbHorizontal=0, sbVertical=1; положение бегунка
    FSbKind: Integer;
    FSbPosition: Integer;
    FSbMin: Integer;
    FSbMax: Integer;
    FSbPageSize: Integer;
    procedure SetRqClass(const AValue: string);
    procedure SetText(const AValue: string);
    procedure SetChecked(AValue: Boolean);
    procedure SetBevelOuter(AValue: Integer);
    procedure SetBevelInner(AValue: Integer);
    procedure SetBorderStyle(AValue: Integer);
    procedure SetAlignment(AValue: Integer);
    procedure SetDisabled(AValue: Boolean);
    procedure SetTabs(const AValue: string);
    function GetTabInt(AIndex: Integer): Integer;
    procedure SetTabInt(AIndex: Integer; AValue: Integer);
    procedure SetTabColor(AValue: TColor);
    function GetSbInt(AIndex: Integer): Integer;
    procedure SetSbInt(AIndex: Integer; AValue: Integer);
    procedure PaintTabs(const AClientBox: TRect);
    procedure PaintScrollBar(const AClientBox: TRect);
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure DrawCaption(ARect: TRect; AFlags: Cardinal);
    procedure DrawNameTag(ARect: TRect);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    property Kind: TRqKind read FKind;
  published
    // Класс RapidQ - первым в тексте .dfm: от него зависят цвет и рамка по
    // умолчанию, которые следующие свойства могут поменять
    property RqClass: string read FRqClass write SetRqClass;
    property Align;
    property Caption;
    property Color;
    property Font;
    property ParentColor;
    property ParentFont;
    property Visible;
    // Text поля ввода и списка выбора. Своё имя: Text у TControl - это
    // заголовок окна, тот же, что Caption.
    property RqText: string read FText write SetText;
    property Checked: Boolean read FChecked write SetChecked default False;
    // Значения RapidQ: bvNone=0, bvLowered=1, bvRaised=2; bsNone=0,
    // bsSingle=1; taLeftJustify=0, taRightJustify=1, taCenter=2
    property RqBevelOuter: Integer read FBevelOuter write SetBevelOuter;
    property RqBevelInner: Integer read FBevelInner write SetBevelInner;
    property RqBorderStyle: Integer read FBorderStyle write SetBorderStyle;
    property RqAlignment: Integer read FAlignment write SetAlignment;
    // Enabled = 0 у компонента: рисуется серым. Сам контрол остаётся
    // включённым - иначе щелчки по нему уходили бы родителю.
    property RqDisabled: Boolean read FDisabled write SetDisabled default False;
    property RqTabs: string read FTabs write SetTabs;
    property RqTabIndex: Integer index 0 read GetTabInt write SetTabInt
      default 0;
    property RqTabHeight: Integer index 1 read GetTabInt write SetTabInt
      default 0;
    property RqTabWidth: Integer index 2 read GetTabInt write SetTabInt
      default 0;
    property RqTabColor: TColor read FTabColor write SetTabColor
      default clNone;
    property RqKind: Integer index 0 read GetSbInt write SetSbInt default 0;
    property RqPosition: Integer index 1 read GetSbInt write SetSbInt
      default 0;
    property RqMin: Integer index 2 read GetSbInt write SetSbInt default 0;
    property RqMax: Integer index 3 read GetSbInt write SetSbInt default 100;
    property RqPageSize: Integer index 4 read GetSbInt write SetSbInt
      default 10;
  end;

  // Невизуальный компонент RapidQ - значком конструктора
  TRqNonVis = class(TComponent);

// Вид класса AClass по цепочке EXTENDS (первый встроенный класс с видом)
function RqDsgKindOf(const AClass: string): TRqKind;
// Видимый компонент: у класса (по цепочке) есть Left и Width
function RqDsgIsVisual(const AClass: string): Boolean;
// Форма: QFORM или его наследник
function RqDsgIsForm(const AClass: string): Boolean;
// Меню: 1 - QMAINMENU, 2 - QPOPUPMENU, 3 - QMENUITEM (по цепочке), 0 - нет
function RqDsgMenuKind(const AClass: string): Integer;
// Контейнер: на нём лежат другие компоненты
function RqDsgIsContainer(AKind: TRqKind): Boolean;
// Строка в записи .dfm: 'текст' с удвоенными кавычками, управляющие и
// символы за 126 - #код
function RqDsgDfmString(const AText: string): string;
// Значение ARaw числом: десятичное, &H, False/True, вариант свойства
// AMember ("bvRaised=2"), константа программы или описания. False - не
// число (выражение).
function RqDsgNumber(AMember: TRqMember; const ARaw: string;
                     var ANum: Integer): Boolean;
// Имя годится для объекта .dfm: идентификатор Паскаля, не слово языка
function RqDsgNameOk(const AName: string): Boolean;

implementation

const
  KindNames: array[0..29] of string = (
    'QBUTTON', 'QCOOLBTN', 'QOVALBTN', 'QEDIT', 'QMAXEDIT', 'QREDIT',
    'QRICHEDIT', 'QLISTBOX', 'QFILELISTBOX', 'QDIRTREE', 'QTREEVIEW',
    'QOUTLINE', 'QLISTVIEW', 'QSTRINGGRID', 'QOLECONTAINER', 'QLABEL',
    'QCHECKBOX', 'QRADIOBUTTON', 'QPANEL', 'QGROUPBOX', 'QSCROLLBOX',
    'QCOMBOBOX', 'QSCROLLBAR', 'QTRACKBAR', 'QGAUGE', 'QHEADER',
    'QSTATUSBAR', 'QTABCONTROL', 'QSPLITTER', 'QIMAGE');
  KindOfName: array[0..29] of TRqKind = (
    rkButton, rkButton, rkOval, rkEdit, rkEdit, rkEdit,
    rkMemo, rkMemo, rkMemo, rkMemo, rkMemo,
    rkMemo, rkMemo, rkMemo, rkMemo, rkLabel,
    rkCheck, rkRadio, rkPanel, rkGroup, rkScrollBox,
    rkCombo, rkScrollBar, rkTrack, rkGauge, rkHeader,
    rkStatus, rkTab, rkSplitter, rkImage);
  // Ещё виды, которых нет в списке выше
  ExtraNames: array[0..2] of string = ('QCANVAS', 'QGLASSFRAME', 'QPROGRESSBAR');
  ExtraKinds: array[0..2] of TRqKind = (rkImage, rkImage, rkGauge);

  PascalWords: array[0..19] of string = (
    'BEGIN', 'END', 'OBJECT', 'INHERITED', 'INLINE', 'ITEM', 'TYPE', 'VAR',
    'CONST', 'PROCEDURE', 'FUNCTION', 'IF', 'THEN', 'ELSE', 'DO', 'WHILE',
    'FOR', 'TO', 'WITH', 'CLASS');

function KindByName(const AName: string; var AKind: TRqKind): Boolean;
var
  NameIdx: Integer;
  Upper: string;
begin
  Result := True;
  Upper := UpperCase(AName);
  for NameIdx := Low(KindNames) to High(KindNames) do
    if KindNames[NameIdx] = Upper then
    begin
      AKind := KindOfName[NameIdx];
      Exit;
    end;
  for NameIdx := Low(ExtraNames) to High(ExtraNames) do
    if ExtraNames[NameIdx] = Upper then
    begin
      AKind := ExtraKinds[NameIdx];
      Exit;
    end;
  Result := False;
end;

function RqDsgKindOf(const AClass: string): TRqKind;
var
  Chain: TList;
  ChainIdx: Integer;
begin
  Result := rkBox;
  if KindByName(AClass, Result) then
    Exit;
  Chain := TList.Create;
  try
    RqClassChain(AClass, Chain);
    for ChainIdx := 0 to Chain.Count - 1 do
      if KindByName(TRqClass(Chain[ChainIdx]).Name, Result) then
        Exit;
  finally
    Chain.Free;
  end;
  Result := rkBox;
end;

// В цепочке класса есть класс с именем AName
function ChainHas(const AClass, AName: string): Boolean;
var
  Chain: TList;
  ChainIdx: Integer;
begin
  Result := CompareText(AClass, AName) = 0;
  if Result then
    Exit;
  Chain := TList.Create;
  try
    RqClassChain(AClass, Chain);
    for ChainIdx := 0 to Chain.Count - 1 do
      if CompareText(TRqClass(Chain[ChainIdx]).Name, AName) = 0 then
      begin
        Result := True;
        Exit;
      end;
  finally
    Chain.Free;
  end;
end;

function RqDsgIsVisual(const AClass: string): Boolean;
var
  Chain: TList;
  ChainIdx: Integer;
  HasLeft, HasWidth: Boolean;
  Kind: TRqKind;
begin
  Result := KindByName(AClass, Kind) or RqDsgIsForm(AClass);
  if Result then
    Exit;
  HasLeft := False;
  HasWidth := False;
  Chain := TList.Create;
  try
    RqClassChain(AClass, Chain);
    for ChainIdx := 0 to Chain.Count - 1 do
    begin
      if TRqClass(Chain[ChainIdx]).PropOf('Left') <> nil then
        HasLeft := True;
      if TRqClass(Chain[ChainIdx]).PropOf('Width') <> nil then
        HasWidth := True;
      if KindByName(TRqClass(Chain[ChainIdx]).Name, Kind) then
      begin
        HasLeft := True;
        HasWidth := True;
      end;
    end;
  finally
    Chain.Free;
  end;
  Result := HasLeft and HasWidth;
end;

function RqDsgIsForm(const AClass: string): Boolean;
begin
  Result := ChainHas(AClass, 'QFORM');
end;

function RqDsgMenuKind(const AClass: string): Integer;
begin
  if ChainHas(AClass, 'QMAINMENU') then
    Result := 1
  else if ChainHas(AClass, 'QPOPUPMENU') then
    Result := 2
  else if ChainHas(AClass, 'QMENUITEM') then
    Result := 3
  else
    Result := 0;
end;

function RqDsgIsContainer(AKind: TRqKind): Boolean;
begin
  Result := AKind in [rkPanel, rkGroup, rkScrollBox, rkTab];
end;

function RqDsgDfmString(const AText: string): string;
var
  CharIdx: Integer;
  InQuote: Boolean;
begin
  Result := '';
  InQuote := False;
  for CharIdx := 1 to Length(AText) do
    if (AText[CharIdx] < ' ') or (Ord(AText[CharIdx]) > 126) then
    begin
      if InQuote then
      begin
        Result := Result + '''';
        InQuote := False;
      end;
      Result := Result + '#' + IntToStr(Ord(AText[CharIdx]));
    end
    else
    begin
      if not InQuote then
      begin
        Result := Result + '''';
        InQuote := True;
      end;
      if AText[CharIdx] = '''' then
        Result := Result + ''''''
      else
        Result := Result + AText[CharIdx];
    end;
  if InQuote then
    Result := Result + '''';
  if Result = '' then
    Result := '''''';
end;

function RqDsgNumber(AMember: TRqMember; const ARaw: string;
                     var ANum: Integer): Boolean;
var
  Value, ChoiceName: string;
  ChoiceIdx, EqPos, Code: Integer;
begin
  Result := False;
  Value := Trim(ARaw);
  if Value = '' then
    Exit;
  if (Length(Value) > 2) and (Value[1] = '&') and (UpCase(Value[2]) = 'H') then
  begin
    Val('$' + Copy(Value, 3, MaxInt), ANum, Code);
    Result := Code = 0;
    Exit;
  end;
  Val(Value, ANum, Code);
  if Code = 0 then
  begin
    Result := True;
    Exit;
  end;
  if CompareText(Value, 'False') = 0 then
  begin
    ANum := 0;
    Result := True;
    Exit;
  end;
  if CompareText(Value, 'True') = 0 then
  begin
    ANum := 1;
    Result := True;
    Exit;
  end;
  if AMember <> nil then
    for ChoiceIdx := 0 to AMember.Choices.Count - 1 do
    begin
      EqPos := Pos('=', AMember.Choices[ChoiceIdx]);
      if EqPos = 0 then
        Continue;
      ChoiceName := Copy(AMember.Choices[ChoiceIdx], 1, EqPos - 1);
      if CompareText(ChoiceName, Value) = 0 then
      begin
        Val(Trim(Copy(AMember.Choices[ChoiceIdx], EqPos + 1, MaxInt)), ANum,
            Code);
        if Code = 0 then
        begin
          Result := True;
          Exit;
        end;
      end;
    end;
  Result := RqConstValue(Value, ANum);
end;

function RqDsgNameOk(const AName: string): Boolean;
var
  CharIdx, WordIdx: Integer;
  Upper: string;
begin
  Result := (AName <> '') and (AName[1] in ['A'..'Z', 'a'..'z', '_']);
  if not Result then
    Exit;
  for CharIdx := 2 to Length(AName) do
    if not (AName[CharIdx] in ['A'..'Z', 'a'..'z', '0'..'9', '_']) then
    begin
      Result := False;
      Exit;
    end;
  Upper := UpperCase(AName);
  for WordIdx := Low(PascalWords) to High(PascalWords) do
    if PascalWords[WordIdx] = Upper then
    begin
      Result := False;
      Exit;
    end;
end;

{ TRqShape }

constructor TRqShape.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csReplicatable];
  Width := 75;
  Height := 25;
  Color := clBtnFace;
  FKind := rkBox;
  FBevelOuter := 2;
  FBevelInner := 0;
  FBorderStyle := 1;
  FAlignment := 0;
  FTabColor := clNone;
  FSbMax := 100;
  FSbPageSize := 10;
end;

procedure TRqShape.SetRqClass(const AValue: string);
begin
  FRqClass := AValue;
  FKind := RqDsgKindOf(AValue);
  if RqDsgIsContainer(FKind) then
    ControlStyle := ControlStyle + [csAcceptsControls]
  else
    ControlStyle := ControlStyle - [csAcceptsControls];
  // Цвет по умолчанию - как у компонента RapidQ; Color из текста, если он
  // есть, идёт в .dfm после RqClass и заменит этот
  case FKind of
    rkEdit, rkMemo, rkCombo:
      Color := clWindow;
    rkLabel, rkCheck, rkRadio, rkGroup:
      ParentColor := True;
  else
    Color := clBtnFace;
  end;
  if FKind = rkPanel then
    FAlignment := 2;
  Invalidate;
end;

procedure TRqShape.SetText(const AValue: string);
begin
  FText := AValue;
  Invalidate;
end;

procedure TRqShape.SetChecked(AValue: Boolean);
begin
  FChecked := AValue;
  Invalidate;
end;

procedure TRqShape.SetBevelOuter(AValue: Integer);
begin
  FBevelOuter := AValue;
  Invalidate;
end;

procedure TRqShape.SetBevelInner(AValue: Integer);
begin
  FBevelInner := AValue;
  Invalidate;
end;

procedure TRqShape.SetBorderStyle(AValue: Integer);
begin
  FBorderStyle := AValue;
  Invalidate;
end;

procedure TRqShape.SetAlignment(AValue: Integer);
begin
  FAlignment := AValue;
  Invalidate;
end;

procedure TRqShape.SetDisabled(AValue: Boolean);
begin
  FDisabled := AValue;
  Invalidate;
end;

procedure TRqShape.SetTabs(const AValue: string);
begin
  FTabs := AValue;
  Invalidate;
end;

function TRqShape.GetTabInt(AIndex: Integer): Integer;
begin
  case AIndex of
    0: Result := FTabIndex;
    1: Result := FTabHeight;
  else
    Result := FTabWidth;
  end;
end;

procedure TRqShape.SetTabInt(AIndex: Integer; AValue: Integer);
begin
  case AIndex of
    0: FTabIndex := AValue;
    1: FTabHeight := AValue;
    2: FTabWidth := AValue;
  end;
  Invalidate;
end;

procedure TRqShape.SetTabColor(AValue: TColor);
begin
  FTabColor := AValue;
  Invalidate;
end;

function TRqShape.GetSbInt(AIndex: Integer): Integer;
begin
  case AIndex of
    0: Result := FSbKind;
    1: Result := FSbPosition;
    2: Result := FSbMin;
    3: Result := FSbMax;
  else
    Result := FSbPageSize;
  end;
end;

procedure TRqShape.SetSbInt(AIndex: Integer; AValue: Integer);
begin
  case AIndex of
    0: FSbKind := AValue;
    1: FSbPosition := AValue;
    2: FSbMin := AValue;
    3: FSbMax := AValue;
    4: FSbPageSize := AValue;
  end;
  Invalidate;
end;

// Вкладки QTABCONTROL: ряд ярлыков сверху, выбранный - выше и цветом
// компонента, под ними - рамка тела. Названий нет - одна вкладка "Tab".
procedure TRqShape.PaintTabs(const AClientBox: TRect);
var
  Names: TStringList;
  NameIdx, TabLeft, TabWide, TabHigh: Integer;
  Body, TabBox: TRect;
  TabName: string;
begin
  Canvas.Font := Font;
  TabHigh := FTabHeight;
  if TabHigh <= 0 then
    TabHigh := Canvas.TextHeight('Wg') + 6;
  Body := AClientBox;
  Body.Top := Body.Top + TabHigh;
  DrawEdge(Canvas.Handle, Body, EDGE_RAISED, BF_RECT);
  Names := TStringList.Create;
  try
    Names.Text := FTabs;
    if Names.Count = 0 then
      Names.Add('Tab');
    SetBkMode(Canvas.Handle, TRANSPARENT);
    TabLeft := AClientBox.Left + 2;
    for NameIdx := 0 to Names.Count - 1 do
    begin
      TabName := Names[NameIdx];
      TabWide := FTabWidth;
      if TabWide <= 0 then
        TabWide := Canvas.TextWidth(TabName) + 16;
      if NameIdx = FTabIndex then
      begin
        // Выбранная - на 2 точки шире и выше, сливается с телом
        TabBox := Rect(TabLeft - 2, AClientBox.Top, TabLeft + TabWide + 2,
                       AClientBox.Top + TabHigh + 1);
        Canvas.Brush.Color := Color;
      end
      else
      begin
        TabBox := Rect(TabLeft, AClientBox.Top + 2, TabLeft + TabWide,
                       AClientBox.Top + TabHigh);
        if FTabColor <> clNone then
          Canvas.Brush.Color := FTabColor
        else
          Canvas.Brush.Color := Color;
      end;
      Canvas.FillRect(TabBox);
      DrawEdge(Canvas.Handle, TabBox, EDGE_RAISED,
               BF_LEFT or BF_TOP or BF_RIGHT or BF_SOFT);
      DrawText(Canvas.Handle, PChar(TabName), Length(TabName), TabBox,
               DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX or
               DT_END_ELLIPSIS);
      Inc(TabLeft, TabWide);
      if TabLeft >= AClientBox.Right then
        Break;
    end;
  finally
    Names.Free;
  end;
end;

// QSCROLLBAR: стрелки по краям, поле и бегунок, как у полосы Windows.
// Направление - RqKind (свойство Kind), а не соотношение сторон.
procedure TRqShape.PaintScrollBar(const AClientBox: TRect);
var
  Vertical: Boolean;
  ArrowSize, TrackStart, TrackLen, ThumbLen, ThumbStart, Range, Page,
    Offset: Integer;
  FirstArrow, LastArrow, Thumb: TRect;
begin
  Vertical := FSbKind = 1;
  Canvas.Brush.Color := clScrollBar;
  Canvas.FillRect(AClientBox);
  if Vertical then
  begin
    ArrowSize := AClientBox.Right - AClientBox.Left;
    if ArrowSize > (AClientBox.Bottom - AClientBox.Top) div 2 then
      ArrowSize := (AClientBox.Bottom - AClientBox.Top) div 2;
    FirstArrow := Rect(AClientBox.Left, AClientBox.Top, AClientBox.Right,
                       AClientBox.Top + ArrowSize);
    LastArrow := Rect(AClientBox.Left, AClientBox.Bottom - ArrowSize,
                      AClientBox.Right, AClientBox.Bottom);
    DrawFrameControl(Canvas.Handle, FirstArrow, DFC_SCROLL, DFCS_SCROLLUP);
    DrawFrameControl(Canvas.Handle, LastArrow, DFC_SCROLL, DFCS_SCROLLDOWN);
    TrackStart := FirstArrow.Bottom;
    TrackLen := LastArrow.Top - FirstArrow.Bottom;
  end
  else
  begin
    ArrowSize := AClientBox.Bottom - AClientBox.Top;
    if ArrowSize > (AClientBox.Right - AClientBox.Left) div 2 then
      ArrowSize := (AClientBox.Right - AClientBox.Left) div 2;
    FirstArrow := Rect(AClientBox.Left, AClientBox.Top,
                       AClientBox.Left + ArrowSize, AClientBox.Bottom);
    LastArrow := Rect(AClientBox.Right - ArrowSize, AClientBox.Top,
                      AClientBox.Right, AClientBox.Bottom);
    DrawFrameControl(Canvas.Handle, FirstArrow, DFC_SCROLL, DFCS_SCROLLLEFT);
    DrawFrameControl(Canvas.Handle, LastArrow, DFC_SCROLL, DFCS_SCROLLRIGHT);
    TrackStart := FirstArrow.Right;
    TrackLen := LastArrow.Left - FirstArrow.Right;
  end;
  if TrackLen < 8 then
    Exit;
  // Бегунок: длина - доля страницы в диапазоне, место - Position
  Range := FSbMax - FSbMin;
  if Range < 1 then
    Range := 1;
  Page := FSbPageSize;
  if Page < 0 then
    Page := 0;
  if Page > 0 then
    ThumbLen := TrackLen * Page div (Range + Page)
  else
    ThumbLen := ArrowSize;
  if ThumbLen < 8 then
    ThumbLen := 8;
  if ThumbLen > TrackLen then
    ThumbLen := TrackLen;
  Offset := FSbPosition - FSbMin;
  if Offset < 0 then
    Offset := 0;
  if Offset > Range then
    Offset := Range;
  ThumbStart := TrackStart + (TrackLen - ThumbLen) * Offset div Range;
  if Vertical then
    Thumb := Rect(AClientBox.Left, ThumbStart, AClientBox.Right,
                  ThumbStart + ThumbLen)
  else
    Thumb := Rect(ThumbStart, AClientBox.Top, ThumbStart + ThumbLen,
                  AClientBox.Bottom);
  Canvas.Brush.Color := clBtnFace;
  Canvas.FillRect(Thumb);
  DrawEdge(Canvas.Handle, Thumb, EDGE_RAISED, BF_RECT);
end;

procedure TRqShape.CMTextChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

// Подпись Caption в ARect: шрифт компонента, серым - если выключен
procedure TRqShape.DrawCaption(ARect: TRect; AFlags: Cardinal);
var
  CaptionText: string;
begin
  CaptionText := Caption;
  if CaptionText = '' then
    Exit;
  Canvas.Font := Font;
  if FDisabled then
    Canvas.Font.Color := clGrayText;
  SetBkMode(Canvas.Handle, TRANSPARENT);
  DrawText(Canvas.Handle, PChar(CaptionText), Length(CaptionText), ARect,
           AFlags or DT_NOPREFIX);
end;

// Имя и класс мелким серым в левом верхнем углу ARect - у списков, деревьев
// и прочего, что без данных пусто
procedure TRqShape.DrawNameTag(ARect: TRect);
var
  TagText: string;
begin
  TagText := Name + ': ' + FRqClass;
  Canvas.Font.Name := 'Tahoma';
  Canvas.Font.Height := -10;
  Canvas.Font.Style := [];
  Canvas.Font.Color := clGrayText;
  SetBkMode(Canvas.Handle, TRANSPARENT);
  InflateRect(ARect, -3, -2);
  DrawText(Canvas.Handle, PChar(TagText), Length(TagText), ARect,
           DT_LEFT or DT_TOP or DT_SINGLELINE or DT_END_ELLIPSIS or
           DT_NOPREFIX);
end;

procedure TRqShape.Paint;
const
  AlignFlags: array[0..2] of Cardinal = (DT_LEFT, DT_RIGHT, DT_CENTER);
var
  ClientBox, Part: TRect;
  BoxSize, ButtonWidth, TextHeight, MidY, EdgeFlags: Integer;
  ShownText: string;
  AlignFlag: Cardinal;
begin
  ClientBox := ClientRect;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientBox);
  AlignFlag := DT_LEFT;
  if (FAlignment >= 0) and (FAlignment <= 2) then
    AlignFlag := AlignFlags[FAlignment];

  case FKind of
    rkButton:
      begin
        DrawFrameControl(Canvas.Handle, ClientBox, DFC_BUTTON, DFCS_BUTTONPUSH);
        Part := ClientBox;
        InflateRect(Part, -3, -3);
        DrawCaption(Part, DT_CENTER or DT_VCENTER or DT_SINGLELINE or
                    DT_END_ELLIPSIS);
      end;
    rkOval:
      begin
        Canvas.Pen.Color := clBtnShadow;
        Canvas.Ellipse(ClientBox.Left, ClientBox.Top, ClientBox.Right,
                       ClientBox.Bottom);
        DrawCaption(ClientBox, DT_CENTER or DT_VCENTER or DT_SINGLELINE or
                    DT_END_ELLIPSIS);
      end;
    rkEdit, rkCombo:
      begin
        if FBorderStyle <> 0 then
          DrawEdge(Canvas.Handle, ClientBox, EDGE_SUNKEN, BF_RECT);
        Part := ClientBox;
        InflateRect(Part, -3, -2);
        if FKind = rkCombo then
        begin
          ButtonWidth := GetSystemMetrics(SM_CXVSCROLL);
          Part.Right := ClientBox.Right - 2 - ButtonWidth;
          DrawFrameControl(Canvas.Handle,
                           Rect(Part.Right, ClientBox.Top + 2,
                                ClientBox.Right - 2, ClientBox.Bottom - 2),
                           DFC_SCROLL, DFCS_SCROLLCOMBOBOX);
        end;
        ShownText := FText;
        if (ShownText = '') and (FKind = rkCombo) then
          ShownText := Caption;
        if ShownText <> '' then
        begin
          Canvas.Font := Font;
          if FDisabled then
            Canvas.Font.Color := clGrayText;
          SetBkMode(Canvas.Handle, TRANSPARENT);
          DrawText(Canvas.Handle, PChar(ShownText), Length(ShownText), Part,
                   DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX or
                   DT_END_ELLIPSIS);
        end;
      end;
    rkMemo:
      begin
        if FBorderStyle <> 0 then
          DrawEdge(Canvas.Handle, ClientBox, EDGE_SUNKEN, BF_RECT);
        DrawNameTag(ClientBox);
      end;
    rkLabel:
      begin
        Part := ClientBox;
        DrawCaption(Part, AlignFlag or DT_WORDBREAK);
        // Пустую подпись на форме не видно - серая пунктирная рамка
        if Caption = '' then
        begin
          Canvas.Pen.Color := clGray;
          Canvas.Pen.Style := psDot;
          Canvas.Brush.Style := bsClear;
          Canvas.Rectangle(ClientBox);
          Canvas.Pen.Style := psSolid;
        end;
      end;
    rkCheck, rkRadio:
      begin
        BoxSize := 13;
        MidY := (ClientBox.Top + ClientBox.Bottom) div 2;
        Part := Rect(ClientBox.Left, MidY - BoxSize div 2,
                     ClientBox.Left + BoxSize, MidY - BoxSize div 2 + BoxSize);
        if FKind = rkCheck then
          EdgeFlags := DFCS_BUTTONCHECK
        else
          EdgeFlags := DFCS_BUTTONRADIO;
        if FChecked then
          EdgeFlags := EdgeFlags or DFCS_CHECKED;
        if FDisabled then
          EdgeFlags := EdgeFlags or DFCS_INACTIVE;
        DrawFrameControl(Canvas.Handle, Part, DFC_BUTTON, EdgeFlags);
        Part := ClientBox;
        Part.Left := ClientBox.Left + BoxSize + 4;
        DrawCaption(Part, DT_LEFT or DT_VCENTER or DT_SINGLELINE or
                    DT_END_ELLIPSIS);
      end;
    rkPanel:
      begin
        Part := ClientBox;
        if FBevelOuter = 2 then
          DrawEdge(Canvas.Handle, Part, BDR_RAISEDOUTER, BF_RECT)
        else if FBevelOuter = 1 then
          DrawEdge(Canvas.Handle, Part, BDR_SUNKENOUTER, BF_RECT);
        if FBevelOuter <> 0 then
          InflateRect(Part, -1, -1);
        if FBevelInner = 2 then
          DrawEdge(Canvas.Handle, Part, BDR_RAISEDINNER, BF_RECT)
        else if FBevelInner = 1 then
          DrawEdge(Canvas.Handle, Part, BDR_SUNKENINNER, BF_RECT);
        // Панель без рамки на форме не видна - пунктир
        if (FBevelOuter = 0) and (FBevelInner = 0) then
        begin
          Canvas.Pen.Color := clGray;
          Canvas.Pen.Style := psDot;
          Canvas.Brush.Style := bsClear;
          Canvas.Rectangle(ClientBox);
          Canvas.Pen.Style := psSolid;
        end;
        InflateRect(Part, -2, -2);
        DrawCaption(Part, AlignFlag or DT_VCENTER or DT_SINGLELINE or
                    DT_END_ELLIPSIS);
      end;
    rkGroup:
      begin
        Canvas.Font := Font;
        TextHeight := Canvas.TextHeight('Wg');
        Part := ClientBox;
        Part.Top := Part.Top + TextHeight div 2;
        DrawEdge(Canvas.Handle, Part, EDGE_ETCHED, BF_RECT);
        if Caption <> '' then
        begin
          Part := Rect(ClientBox.Left + 8, ClientBox.Top,
                       ClientBox.Left + 12 + Canvas.TextWidth(Caption),
                       ClientBox.Top + TextHeight);
          Canvas.Brush.Color := Color;
          Canvas.FillRect(Part);
          InflateRect(Part, -2, 0);
          DrawCaption(Part, DT_LEFT or DT_SINGLELINE);
        end;
      end;
    rkScrollBox:
      DrawEdge(Canvas.Handle, ClientBox, EDGE_SUNKEN, BF_RECT);
    rkScrollBar:
      PaintScrollBar(ClientBox);
    rkTrack:
      begin
        MidY := ClientBox.Bottom div 2;
        Part := Rect(8, MidY - 2, ClientBox.Right - 8, MidY + 2);
        DrawEdge(Canvas.Handle, Part, EDGE_SUNKEN, BF_RECT);
        Part := Rect(8, MidY - 10, 19, MidY + 10);
        DrawEdge(Canvas.Handle, Part, EDGE_RAISED, BF_RECT or BF_MIDDLE);
      end;
    rkGauge:
      begin
        DrawEdge(Canvas.Handle, ClientBox, EDGE_SUNKEN, BF_RECT);
        Part := ClientBox;
        InflateRect(Part, -2, -2);
        Part.Right := Part.Left + (Part.Right - Part.Left) div 3;
        Canvas.Brush.Color := clHighlight;
        Canvas.FillRect(Part);
      end;
    rkHeader:
      begin
        Part := ClientBox;
        Part.Right := Part.Left + 80;
        while Part.Left < ClientBox.Right do
        begin
          DrawFrameControl(Canvas.Handle, Part, DFC_BUTTON, DFCS_BUTTONPUSH);
          OffsetRect(Part, 80, 0);
        end;
      end;
    rkStatus:
      begin
        Part := ClientBox;
        InflateRect(Part, -2, -2);
        DrawEdge(Canvas.Handle, Part, BDR_SUNKENOUTER, BF_RECT);
        InflateRect(Part, -3, 0);
        DrawCaption(Part, DT_LEFT or DT_VCENTER or DT_SINGLELINE or
                    DT_END_ELLIPSIS);
      end;
    rkTab:
      PaintTabs(ClientBox);
    rkSplitter:
      begin
        Canvas.Brush.Color := clBtnShadow;
        Canvas.FrameRect(ClientBox);
      end;
    rkImage:
      begin
        Canvas.Pen.Color := clGray;
        Canvas.Pen.Style := psDash;
        Canvas.Brush.Style := bsClear;
        Canvas.Rectangle(ClientBox);
        Canvas.Pen.Style := psSolid;
        DrawNameTag(ClientBox);
      end;
  else
    begin
      DrawEdge(Canvas.Handle, ClientBox, EDGE_ETCHED, BF_RECT);
      DrawNameTag(ClientBox);
    end;
  end;
end;

initialization
  RegisterClasses([TRqShape, TRqNonVis]);

end.
