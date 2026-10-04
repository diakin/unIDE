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
    procedure SetRqClass(const AValue: string);
    procedure SetText(const AValue: string);
    procedure SetChecked(AValue: Boolean);
    procedure SetBevelOuter(AValue: Integer);
    procedure SetBevelInner(AValue: Integer);
    procedure SetBorderStyle(AValue: Integer);
    procedure SetAlignment(AValue: Integer);
    procedure SetDisabled(AValue: Boolean);
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
      begin
        if Width >= Height then
        begin
          DrawFrameControl(Canvas.Handle,
                           Rect(0, 0, Height, Height), DFC_SCROLL,
                           DFCS_SCROLLLEFT);
          DrawFrameControl(Canvas.Handle,
                           Rect(Width - Height, 0, Width, Height), DFC_SCROLL,
                           DFCS_SCROLLRIGHT);
        end
        else
        begin
          DrawFrameControl(Canvas.Handle, Rect(0, 0, Width, Width),
                           DFC_SCROLL, DFCS_SCROLLUP);
          DrawFrameControl(Canvas.Handle,
                           Rect(0, Height - Width, Width, Height), DFC_SCROLL,
                           DFCS_SCROLLDOWN);
        end;
      end;
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
      begin
        Canvas.Font := Font;
        TextHeight := Canvas.TextHeight('Wg') + 6;
        Part := ClientBox;
        Part.Top := Part.Top + TextHeight - 2;
        DrawEdge(Canvas.Handle, Part, EDGE_RAISED, BF_RECT);
        Part := Rect(2, 0, 2 + Canvas.TextWidth('Tab') + 16, TextHeight);
        DrawEdge(Canvas.Handle, Part, EDGE_RAISED,
                 BF_LEFT or BF_TOP or BF_RIGHT or BF_SOFT);
        SetBkMode(Canvas.Handle, TRANSPARENT);
        DrawText(Canvas.Handle, 'Tab', 3, Part,
                 DT_CENTER or DT_VCENTER or DT_SINGLELINE);
      end;
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
