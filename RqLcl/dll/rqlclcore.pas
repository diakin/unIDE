// ---------------------------------------------------------------------------
//  RqLcl - компоненты RapidQ поверх LCL для программ на FreeBASIC
//
//  Прототип. DLL отдаёт плоский набор функций (stdcall): создать компонент
//  по имени класса RapidQ, читать и ставить свойства, назначать события,
//  вызывать методы. Сопоставление классов RapidQ и LCL - в RqClassTable
//  (QRICHEDIT - TRichMemo из пакета RichMemo, папка richmemo),
//  имён свойств - в RqPropTable (что совпадает по имени, берётся как есть).
//
//  Объект для вызывающей стороны - указатель на компонент LCL. Свой
//  указатель вызывающего (адрес переменной QFORM, QBUTTON в программе
//  FreeBASIC) хранится в TRqData, дочернем компоненте объекта, и
//  передаётся в обработчик события первым параметром.
//
//  Строки - в кодировке Windows (ANSI, у RapidQ - CP1251) с обеих
//  сторон; LCL работает в UTF-8, перевод - WinCPToUTF8 / UTF8ToWinCP.
//
//  Исключения через границу DLL не идут: каждая функция ловит их сама,
//  текст - в RqLastError.
// ---------------------------------------------------------------------------
unit rqlclcore;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, TypInfo, Math, Controls, StdCtrls, Forms, Graphics,
  LazUTF8, LCLType, ComCtrls, Grids, ShellCtrls, ExtCtrls, Buttons, Menus,
  FileCtrl, Dialogs, RichMemo, rqlclrich, rqlclgrid, rqlclmisc, rqlclmore,
  rqlclsys, rqlclview, rqlclimage, ImgList;

const
  RqLclVersion = 2;   // меняется при несовместимой смене набора функций

type
  // Обработчик события на стороне вызывающего:
  //   AUser - указатель, переданный в RqCreate; AObj - сам объект
  TRqEventProc = procedure(AUser: Pointer; AObj: Pointer); stdcall;

  // Событие с параметрами: целые - IntArgs (параметры var LCL - после
  // вызова берутся обратно), строка - StrArg (кодировка Windows)
  TRqEventArgs = record
    IntArgs: array[0..7] of Integer;
    StrArg: PChar;
  end;
  PRqEventArgs = ^TRqEventArgs;
  TRqEventProcEx = procedure(AUser: Pointer; AObj: Pointer; AEventId: Integer;
                             AArgs: PRqEventArgs); stdcall;

function RqInit: Integer; stdcall;
procedure RqDone; stdcall;
function RqCreate(AClassName: PChar; AParent: Pointer;
                  AUser: Pointer): Pointer; stdcall;
procedure RqFree(AObj: Pointer); stdcall;
function RqSetInt(AObj: Pointer; AProp: PChar; AValue: Integer): Integer;
  stdcall;
function RqGetInt(AObj: Pointer; AProp: PChar): Integer; stdcall;
function RqSetStr(AObj: Pointer; AProp: PChar; AValue: PChar): Integer;
  stdcall;
function RqGetStr(AObj: Pointer; AProp: PChar; ABuf: PChar;
                  ABufLen: Integer): Integer; stdcall;
function RqSetObj(AObj: Pointer; AProp: PChar; AValue: Pointer): Integer;
  stdcall;
function RqSetEvent(AObj: Pointer; AEvent: PChar;
                    AProc: TRqEventProc): Integer; stdcall;
function RqSetEventEx(AObj: Pointer; AEvent: PChar; AEventId: Integer;
                      AProc: TRqEventProcEx): Integer; stdcall;
function RqCallInts(AObj: Pointer; AMethod: PChar; AStr: PChar;
                    AInts: PInteger; ACount: Integer): Integer; stdcall;
function RqCallObj(AObj: Pointer; AMethod: PChar; AOther: Pointer;
                   AInt: Integer): Integer; stdcall;
function RqCall(AObj: Pointer; AMethod: PChar): Integer; stdcall;
function RqCallObjInts(AObj: Pointer; AMethod: PChar; AOther: Pointer;
                       AInts: PInteger; ACount: Integer): Integer; stdcall;
function RqCallInt(AObj: Pointer; AMethod: PChar; AValue: Integer): Integer;
  stdcall;
function RqGetObj(AObj: Pointer; AProp: PChar): Pointer; stdcall;
function RqGetHandle(AObj: Pointer): PtrInt; stdcall;
function RqGetItemStr(AObj: Pointer; AProp: PChar; AIndex: Integer;
                      ABuf: PChar; ABufLen: Integer): Integer; stdcall;
function RqSetItemStr(AObj: Pointer; AProp: PChar; AIndex: Integer;
                      AValue: PChar): Integer; stdcall;
function RqCallStr(AObj: Pointer; AMethod: PChar; AValue: PChar): Integer;
  stdcall;
function RqGetCell(AObj: Pointer; ACol, ARow: Integer; ABuf: PChar;
                   ABufLen: Integer): Integer; stdcall;
function RqSetCell(AObj: Pointer; ACol, ARow: Integer;
                   AValue: PChar): Integer; stdcall;
function RqGetItemInt(AObj: Pointer; AProp: PChar; AIndex: Integer): Integer;
  stdcall;
function RqSetItemInt(AObj: Pointer; AProp: PChar; AIndex: Integer;
                      AValue: Integer): Integer; stdcall;
function RqCallEx(AObj: Pointer; AMethod: PChar; AStr: PChar;
                  AInt1, AInt2, AInt3: Integer; ABuf: PChar;
                  ABufLen: Integer): Integer; stdcall;
procedure RqDoEvents; stdcall;
function RqLastError(ABuf: PChar; ABufLen: Integer): Integer; stdcall;

implementation

type
  // Привязка объекта к вызывающему: его указатель. Дочерний компонент
  // объекта - уничтожается вместе с ним.
  TRqData = class(TComponent)
  public
    User: Pointer;
  end;

  // Переходник одного события: LCL зовёт его метод, он - обработчик
  // вызывающего. Тоже дочерний компонент объекта, по одному на событие.
  TRqEventLink = class(TComponent)
  public
    User: Pointer;
    EventName: string;
    Proc: TRqEventProc;
    ProcEx: TRqEventProcEx;
    EventId: Integer;
    procedure FireNotify(Sender: TObject);
    procedure FireKey(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FireUTF8KeyPress(Sender: TObject; var UTF8Key: TUTF8Char);
    procedure FireMouse(Sender: TObject; Button: TMouseButton;
                        Shift: TShiftState; X, Y: Integer);
    procedure FireMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FireSelectCell(Sender: TObject; aCol, aRow: Integer;
                             var CanSelect: Boolean);
    procedure FireDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect;
                           aState: TGridDrawState);
    procedure FireSetEditText(Sender: TObject; ACol, ARow: Integer;
                              const Value: string);
    procedure FireDrawItem(Control: TWinControl; Index: Integer; ARect: TRect;
                           State: TOwnerDrawState);
    procedure FireTreeNode(Sender: TObject; Node: TTreeNode);
    procedure FireTreeAllow(Sender: TObject; Node: TTreeNode; var Allow: Boolean);
    procedure FireCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FireTreeChange(Sender: TObject; Node: TTreeNode);
    procedure FireListChange(Sender: TObject; Item: TListItem;
                             Change: TItemChange);
    procedure FireColumnClick(Sender: TObject; Column: TListColumn);
  end;

  // Класс RapidQ -> класс LCL
  TRqClassRec = record
    RqName: string;
    LclClass: TComponentClass;
  end;

  // Свойство RapidQ -> свойство LCL (только где имена расходятся)
  TRqPropRec = record
    RqName: string;
    LclName: string;
  end;

var
  RqClassTable: array[0..28] of TRqClassRec;
  RqPropTable: array[0..4] of TRqPropRec;
  RqLastErrorText: string = '';
  RqInitDone: Boolean = False;

// ---------------------------------------------------------------------------
//  Служебное
// ---------------------------------------------------------------------------

procedure FillTables;
begin
  RqClassTable[0].RqName := 'QFORM';
  RqClassTable[0].LclClass := TForm;
  RqClassTable[1].RqName := 'QBUTTON';
  // TBitBtn, как у RapidQ (QBUTTON: BMP, BMPHandle, NumBMPs, Kind)
  RqClassTable[1].LclClass := TBitBtn;
  RqClassTable[2].RqName := 'QLABEL';
  RqClassTable[2].LclClass := TLabel;
  RqClassTable[3].RqName := 'QEDIT';
  RqClassTable[3].LclClass := TEdit;
  RqClassTable[4].RqName := 'QRICHEDIT';
  RqClassTable[4].LclClass := TRichMemo;
  RqClassTable[5].RqName := 'QSTRINGGRID';
  RqClassTable[5].LclClass := TStringGrid;
  RqClassTable[6].RqName := 'QDIRTREE';
  RqClassTable[6].LclClass := TShellTreeView;
  RqClassTable[7].RqName := 'QMAINMENU';
  RqClassTable[7].LclClass := TMainMenu;
  RqClassTable[8].RqName := 'QMENUITEM';
  RqClassTable[8].LclClass := TMenuItem;
  RqClassTable[9].RqName := 'QPOPUPMENU';
  RqClassTable[9].LclClass := TPopupMenu;
  RqClassTable[10].RqName := 'QPANEL';
  RqClassTable[10].LclClass := TPanel;
  RqClassTable[11].RqName := 'QCOOLBTN';
  RqClassTable[11].LclClass := TSpeedButton;
  RqClassTable[12].RqName := 'QCOMBOBOX';
  RqClassTable[12].LclClass := TComboBox;
  RqClassTable[13].RqName := 'QCHECKBOX';
  RqClassTable[13].LclClass := TCheckBox;
  RqClassTable[14].RqName := 'QLISTBOX';
  RqClassTable[14].LclClass := TListBox;
  RqClassTable[15].RqName := 'QSPLITTER';
  RqClassTable[15].LclClass := TSplitter;
  RqClassTable[16].RqName := 'QGAUGE';
  RqClassTable[16].LclClass := TRqGauge;
  RqClassTable[17].RqName := 'QTABCONTROL';
  RqClassTable[17].LclClass := TTabControl;
  RqClassTable[18].RqName := 'QRADIOBUTTON';
  RqClassTable[18].LclClass := TRadioButton;
  RqClassTable[19].RqName := 'QGROUPBOX';
  RqClassTable[19].LclClass := TGroupBox;
  RqClassTable[20].RqName := 'QTREEVIEW';
  RqClassTable[20].LclClass := TTreeView;
  RqClassTable[21].RqName := 'QFILELISTBOX';
  RqClassTable[21].LclClass := TFileListBox;
  RqClassTable[22].RqName := 'QSTATUSBAR';
  RqClassTable[22].LclClass := TStatusBar;
  RqClassTable[23].RqName := 'QOPENDIALOG';
  RqClassTable[23].LclClass := TOpenDialog;
  RqClassTable[24].RqName := 'QSAVEDIALOG';
  RqClassTable[24].LclClass := TSaveDialog;
  RqClassTable[25].RqName := 'QLISTVIEW';
  RqClassTable[25].LclClass := TListView;
  RqClassTable[26].RqName := 'QFONTDIALOG';
  RqClassTable[26].LclClass := TFontDialog;
  RqClassTable[27].RqName := 'QIMAGE';
  RqClassTable[27].LclClass := TImage;
  RqClassTable[28].RqName := 'QIMAGELIST';
  RqClassTable[28].LclClass := TImageList;
  // У RapidQ OnClose формы - сигнал о закрытии без параметров; в LCL ему
  // ближе всего OnCloseQuery (FireCloseQuery разрешает закрытие)
  RqPropTable[0].RqName := 'ONCLOSE';
  RqPropTable[0].LclName := 'OnCloseQuery';
  // Буквы не только ASCII (кириллица) LCL сообщает в OnUTF8KeyPress
  RqPropTable[1].RqName := 'ONKEYPRESS';
  RqPropTable[1].LclName := 'OnUTF8KeyPress';
  // QTREEVIEW: OnExpand / OnCollapse RapidQ - после раскрытия
  RqPropTable[2].RqName := 'ONEXPAND';
  RqPropTable[2].LclName := 'OnExpanded';
  RqPropTable[3].RqName := 'ONCOLLAPSE';
  RqPropTable[3].LclName := 'OnCollapsed';
  // QFONTDIALOG: кнопка Apply
  RqPropTable[4].RqName := 'ONAPPLY';
  RqPropTable[4].LclName := 'OnApplyClicked';
end;

procedure SetError(const AText: string);
begin
  RqLastErrorText := AText;
end;

// Имя свойства LCL по имени RapidQ
function LclPropName(const ARqName: string): string;
var
  PropIdx: Integer;
begin
  Result := ARqName;
  for PropIdx := Low(RqPropTable) to High(RqPropTable) do
    if CompareText(RqPropTable[PropIdx].RqName, ARqName) = 0 then
    begin
      Result := RqPropTable[PropIdx].LclName;
      Exit;
    end;
end;

function FindClassRec(const ARqName: string): Integer;
var
  ClassIdx: Integer;
begin
  Result := -1;
  for ClassIdx := Low(RqClassTable) to High(RqClassTable) do
    if CompareText(RqClassTable[ClassIdx].RqName, ARqName) = 0 then
    begin
      Result := ClassIdx;
      Exit;
    end;
end;

function DataOf(AComp: TComponent): TRqData;
var
  CompIdx: Integer;
begin
  Result := nil;
  if AComp = nil then
    Exit;
  for CompIdx := 0 to AComp.ComponentCount - 1 do
    if AComp.Components[CompIdx] is TRqData then
    begin
      Result := TRqData(AComp.Components[CompIdx]);
      Exit;
    end;
end;

// Свойство по имени RapidQ; нет - nil и текст ошибки
function FindProp(AObj: TObject; const ARqName: string): PPropInfo;
begin
  Result := nil;
  if AObj = nil then
  begin
    SetError('no object');
    Exit;
  end;
  Result := GetPropInfo(AObj, LclPropName(ARqName));
  if Result = nil then
    SetError(AObj.ClassName + ': no property ' + ARqName);
end;

// ---------------------------------------------------------------------------
//  TRqEventLink
// ---------------------------------------------------------------------------

procedure TRqEventLink.FireNotify(Sender: TObject);
var
  Args: TRqEventArgs;
begin
  if Assigned(ProcEx) then
  begin
    FillChar(Args, SizeOf(Args), 0);
    ProcEx(User, Owner, EventId, @Args);
  end
  else if Assigned(Proc) then
    Proc(User, Owner);
end;

// OnDrawItem (QLISTBOX, QCOMBOBOX): Index, State, прямоугольник пункта.
// State как TOwnerDrawState Delphi: выделен 1, серый 2, недоступен 4,
// отмечен 8, в фокусе 16
procedure TRqEventLink.FireDrawItem(Control: TWinControl; Index: Integer;
                                    ARect: TRect; State: TOwnerDrawState);
var
  Args: TRqEventArgs;
  StateBits: Integer;
begin
  if not Assigned(ProcEx) then
    Exit;
  StateBits := 0;
  if odSelected in State then
    StateBits := StateBits or 1;
  if odGrayed in State then
    StateBits := StateBits or 2;
  if odDisabled in State then
    StateBits := StateBits or 4;
  if odChecked in State then
    StateBits := StateBits or 8;
  if odFocused in State then
    StateBits := StateBits or 16;
  FillChar(Args, SizeOf(Args), 0);
  Args.IntArgs[0] := Index;
  Args.IntArgs[1] := StateBits;
  Args.IntArgs[2] := ARect.Left;
  Args.IntArgs[3] := ARect.Top;
  Args.IntArgs[4] := ARect.Right;
  Args.IntArgs[5] := ARect.Bottom;
  ProcEx(User, Owner, EventId, @Args);
end;

// OnClose RapidQ: сигнал, закрытие разрешено
procedure TRqEventLink.FireCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := True;
  FireNotify(Sender);
end;

// Shift RapidQ (как TShiftState Delphi): Shift 1, Alt 2, Ctrl 4, кнопки
// мыши Left 8, Right 16, Middle 32, Double 64
function ShiftToInt(AShift: TShiftState): Integer;
const
  ShiftOrder: array[0..6] of TShiftStateEnum =
    (ssShift, ssAlt, ssCtrl, ssLeft, ssRight, ssMiddle, ssDouble);
var
  BitIdx: Integer;
begin
  Result := 0;
  for BitIdx := 0 to High(ShiftOrder) do
    if ShiftOrder[BitIdx] in AShift then
      Result := Result or (1 shl BitIdx);
end;

function GridStateToInt(AState: TGridDrawState): Integer;
begin
  Result := 0;
  if gdSelected in AState then
    Result := Result or 1;
  if gdFocused in AState then
    Result := Result or 2;
  if gdFixed in AState then
    Result := Result or 4;
end;

procedure TRqEventLink.FireKey(Sender: TObject; var Key: Word;
                               Shift: TShiftState);
var
  Args: TRqEventArgs;
begin
  if not Assigned(ProcEx) then
    Exit;
  FillChar(Args, SizeOf(Args), 0);
  Args.IntArgs[0] := Key;
  Args.IntArgs[1] := ShiftToInt(Shift);
  ProcEx(User, Owner, EventId, @Args);
  Key := Word(Args.IntArgs[0]);
end;

// OnKeyPress RapidQ: код символа в кодировке Windows (Key AS BYTE)
procedure TRqEventLink.FireUTF8KeyPress(Sender: TObject; var UTF8Key: TUTF8Char);
var
  Args: TRqEventArgs;
  AnsiKey: string;
begin
  if not Assigned(ProcEx) then
    Exit;
  AnsiKey := UTF8ToWinCP(UTF8Key);
  if Length(AnsiKey) <> 1 then
    Exit;
  FillChar(Args, SizeOf(Args), 0);
  Args.IntArgs[0] := Ord(AnsiKey[1]);
  ProcEx(User, Owner, EventId, @Args);
  // обработчик обнулил Key - символ не вводится
  if Args.IntArgs[0] = 0 then
    UTF8Key := ''
  else if Args.IntArgs[0] <> Ord(AnsiKey[1]) then
    UTF8Key := WinCPToUTF8(Chr(Byte(Args.IntArgs[0])));
end;

// OnMouseDown / OnMouseUp: Button (0 левая, 1 правая, 2 средняя), X, Y, Shift
procedure TRqEventLink.FireMouse(Sender: TObject; Button: TMouseButton;
                                 Shift: TShiftState; X, Y: Integer);
var
  Args: TRqEventArgs;
begin
  if not Assigned(ProcEx) then
    Exit;
  FillChar(Args, SizeOf(Args), 0);
  Args.IntArgs[0] := Ord(Button);
  Args.IntArgs[1] := X;
  Args.IntArgs[2] := Y;
  Args.IntArgs[3] := ShiftToInt(Shift);
  ProcEx(User, Owner, EventId, @Args);
end;

procedure TRqEventLink.FireMouseMove(Sender: TObject; Shift: TShiftState;
                                     X, Y: Integer);
var
  Args: TRqEventArgs;
begin
  if not Assigned(ProcEx) then
    Exit;
  FillChar(Args, SizeOf(Args), 0);
  Args.IntArgs[0] := X;
  Args.IntArgs[1] := Y;
  Args.IntArgs[2] := ShiftToInt(Shift);
  ProcEx(User, Owner, EventId, @Args);
end;

procedure TRqEventLink.FireSelectCell(Sender: TObject; aCol, aRow: Integer;
                                      var CanSelect: Boolean);
var
  Args: TRqEventArgs;
begin
  if not Assigned(ProcEx) then
    Exit;
  FillChar(Args, SizeOf(Args), 0);
  Args.IntArgs[0] := aCol;
  Args.IntArgs[1] := aRow;
  Args.IntArgs[2] := Ord(CanSelect);
  ProcEx(User, Owner, EventId, @Args);
  CanSelect := Args.IntArgs[2] <> 0;
end;

// OnDrawCell: Col, Row, State, прямоугольник ячейки Left, Top, Right, Bottom
procedure TRqEventLink.FireDrawCell(Sender: TObject; aCol, aRow: Integer;
                                    aRect: TRect; aState: TGridDrawState);
var
  Args: TRqEventArgs;
begin
  if not Assigned(ProcEx) then
    Exit;
  FillChar(Args, SizeOf(Args), 0);
  Args.IntArgs[0] := aCol;
  Args.IntArgs[1] := aRow;
  Args.IntArgs[2] := GridStateToInt(aState);
  Args.IntArgs[3] := aRect.Left;
  Args.IntArgs[4] := aRect.Top;
  Args.IntArgs[5] := aRect.Right;
  Args.IntArgs[6] := aRect.Bottom;
  ProcEx(User, Owner, EventId, @Args);
end;

procedure TRqEventLink.FireSetEditText(Sender: TObject; ACol, ARow: Integer;
                                       const Value: string);
var
  Args: TRqEventArgs;
  AnsiValue: string;
begin
  if not Assigned(ProcEx) then
    Exit;
  FillChar(Args, SizeOf(Args), 0);
  Args.IntArgs[0] := ACol;
  Args.IntArgs[1] := ARow;
  AnsiValue := UTF8ToWinCP(Value);
  Args.StrArg := PChar(AnsiValue);
  ProcEx(User, Owner, EventId, @Args);
end;

// QTREEVIEW: OnChange, OnExpand, OnCollapse - номер пункта (сквозной)
procedure TRqEventLink.FireTreeNode(Sender: TObject; Node: TTreeNode);
var
  Args: TRqEventArgs;
begin
  if not Assigned(ProcEx) then
    Exit;
  FillChar(Args, SizeOf(Args), 0);
  if Node = nil then
    Args.IntArgs[0] := -1
  else
    Args.IntArgs[0] := Node.AbsoluteIndex;
  ProcEx(User, Owner, EventId, @Args);
end;

// QTREEVIEW: OnChanging, OnExpanding, OnCollapsing - номер и разрешение
procedure TRqEventLink.FireTreeAllow(Sender: TObject; Node: TTreeNode;
                                     var Allow: Boolean);
var
  Args: TRqEventArgs;
begin
  if not Assigned(ProcEx) then
    Exit;
  FillChar(Args, SizeOf(Args), 0);
  if Node = nil then
    Args.IntArgs[0] := -1
  else
    Args.IntArgs[0] := Node.AbsoluteIndex;
  Args.IntArgs[1] := Ord(Allow);
  ProcEx(User, Owner, EventId, @Args);
  Allow := Args.IntArgs[1] <> 0;
end;

// OnChange дерева (QDIRTREE): выбрана другая папка
procedure TRqEventLink.FireTreeChange(Sender: TObject; Node: TTreeNode);
begin
  FireNotify(Sender);
end;

// QLISTVIEW: OnChange - номер пункта и что изменилось (ctText 0,
// ctImage 1, ctState 2)
procedure TRqEventLink.FireListChange(Sender: TObject; Item: TListItem;
                                      Change: TItemChange);
var
  Args: TRqEventArgs;
begin
  if not Assigned(ProcEx) then
    Exit;
  FillChar(Args, SizeOf(Args), 0);
  if Item = nil then
    Args.IntArgs[0] := -1
  else
    Args.IntArgs[0] := Item.Index;
  Args.IntArgs[1] := Ord(Change);
  ProcEx(User, Owner, EventId, @Args);
end;

// QLISTVIEW: OnColumnClick - номер столбца
procedure TRqEventLink.FireColumnClick(Sender: TObject; Column: TListColumn);
var
  Args: TRqEventArgs;
begin
  if not Assigned(ProcEx) then
    Exit;
  FillChar(Args, SizeOf(Args), 0);
  if Column = nil then
    Args.IntArgs[0] := -1
  else
    Args.IntArgs[0] := Column.Index;
  ProcEx(User, Owner, EventId, @Args);
end;

// Переходник события AEvent у объекта; нет - nil
function LinkOf(AComp: TComponent; const AEvent: string): TRqEventLink;
var
  CompIdx: Integer;
begin
  Result := nil;
  for CompIdx := 0 to AComp.ComponentCount - 1 do
    if (AComp.Components[CompIdx] is TRqEventLink) and
       (CompareText(TRqEventLink(AComp.Components[CompIdx]).EventName,
                    AEvent) = 0) then
    begin
      Result := TRqEventLink(AComp.Components[CompIdx]);
      Exit;
    end;
end;

// ---------------------------------------------------------------------------
//  Функции DLL
// ---------------------------------------------------------------------------

// Один раз до работы с компонентами. Возвращает RqLclVersion.
function RqInit: Integer; stdcall;
begin
  Result := RqLclVersion;
  try
    if RqInitDone then
      Exit;
    // Вызывающая программа (FreeBASIC, C) ждёт замаскированных исключений
    // FPU, как принято в Windows; RTL FPC их размаскирует
    SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow,
                      exUnderflow, exPrecision]);
    Application.Initialize;
    RqInitDone := True;
  except
    on E: Exception do
    begin
      SetError('RqInit: ' + E.Message);
      Result := 0;
    end;
  end;
end;

// Конец работы: формы, Application и widgetset освобождаются здесь, пока
// программа жива. Иначе это делает finalization LCL при выгрузке DLL, уже
// в конце процесса, когда окна разрушать поздно.
procedure RqDone; stdcall;
begin
  try
    if not RqInitDone then
      Exit;
    RqInitDone := False;
    FreeWidgetSet;
  except
    on E: Exception do
      SetError('RqDone: ' + E.Message);
  end;
end;

// Новый объект класса RapidQ AClassName. AParent - объект-родитель для
// элемента управления (nil - без родителя, у формы всегда nil). AUser -
// указатель вызывающего, приходит в обработчики событий. nil - ошибка.
function RqCreate(AClassName: PChar; AParent: Pointer;
                  AUser: Pointer): Pointer; stdcall;
var
  ClassIdx: Integer;
  Comp: TComponent;
  Data: TRqData;
begin
  Result := nil;
  try
    if not RqInitDone then
      RqInit;
    // QFONT - не компонент: TFont, без родителя и событий
    if CompareText(string(AClassName), 'QFONT') = 0 then
    begin
      Result := TFont.Create;
      Exit;
    end;
    // Application, Screen, Clipboard - объекты LCL, не создаются
    Result := SysGlobalObject(string(AClassName));
    if Result <> nil then
      Exit;
    ClassIdx := FindClassRec(string(AClassName));
    if ClassIdx < 0 then
    begin
      SetError('unknown class ' + string(AClassName));
      Exit;
    end;
    if RqClassTable[ClassIdx].LclClass.InheritsFrom(TCustomForm) then
      // Форма без .lfm: CreateNew, владелец - Application
      Comp := TCustomFormClass(RqClassTable[ClassIdx].LclClass).CreateNew(
                Application)
    else
      Comp := RqClassTable[ClassIdx].LclClass.Create(nil);
    Data := TRqData.Create(Comp);
    Data.User := AUser;
    GridInitNew(Comp);
    MoreInitNew(Comp);
    if (AParent <> nil) and (Comp is TControl) and
       (TObject(AParent) is TWinControl) then
      TControl(Comp).Parent := TWinControl(AParent);
    // Значения по умолчанию RapidQ (документация, Appendix A)
    if Comp is TCustomForm then
    begin
      TCustomForm(Comp).Position := poDesigned;
      TCustomForm(Comp).SetBounds(0, 0, 320, 240);
    end;
    Result := Comp;
  except
    on E: Exception do
      SetError('RqCreate ' + string(AClassName) + ': ' + E.Message);
  end;
end;

procedure RqFree(AObj: Pointer); stdcall;
begin
  try
    if not SysIsGlobal(TObject(AObj)) then
      TObject(AObj).Free;
  except
    on E: Exception do
      SetError('RqFree: ' + E.Message);
  end;
end;

// Целое свойство (числа, Boolean, перечисления по номеру). 1 - поставлено.
function RqSetInt(AObj: Pointer; AProp: PChar; AValue: Integer): Integer;
  stdcall;
var
  Info: PPropInfo;
begin
  Result := 0;
  try
    if EditSetInt(TObject(AObj), string(AProp), AValue) or
       GridSetInt(TObject(AObj), string(AProp), AValue) or
       MiscSetInt(TObject(AObj), string(AProp), AValue) or
       MoreSetInt(TObject(AObj), string(AProp), AValue) or
       SysSetInt(TObject(AObj), string(AProp), AValue) or
       ViewSetInt(TObject(AObj), string(AProp), AValue) or
       ImgSetInt(TObject(AObj), string(AProp), AValue) then
    begin
      Result := 1;
      Exit;
    end;
    Info := FindProp(TObject(AObj), string(AProp));
    if Info = nil then
      Exit;
    if not (Info^.PropType^.Kind in [tkInteger, tkChar, tkEnumeration, tkBool,
                                     tkSet, tkWChar, tkInt64, tkQWord]) then
    begin
      SetError(string(AProp) + ': not an integer property');
      Exit;
    end;
    // Boolean: любое ненулевое - True (у FreeBASIC True = -1)
    if Info^.PropType^.Kind = tkBool then
      SetOrdProp(TObject(AObj), Info, Ord(AValue <> 0))
    else
      SetOrdProp(TObject(AObj), Info, AValue);
    Result := 1;
  except
    on E: Exception do
      SetError('RqSetInt ' + string(AProp) + ': ' + E.Message);
  end;
end;

function RqGetInt(AObj: Pointer; AProp: PChar): Integer; stdcall;
var
  Info: PPropInfo;
begin
  Result := 0;
  try
    if EditGetInt(TObject(AObj), string(AProp), Result) or
       GridGetInt(TObject(AObj), string(AProp), Result) or
       MiscGetInt(TObject(AObj), string(AProp), Result) or
       MoreGetInt(TObject(AObj), string(AProp), Result) or
       SysGetInt(TObject(AObj), string(AProp), Result) or
       ViewGetInt(TObject(AObj), string(AProp), Result) or
       ImgGetInt(TObject(AObj), string(AProp), Result) then
      Exit;
    Info := FindProp(TObject(AObj), string(AProp));
    if Info = nil then
      Exit;
    Result := Integer(GetOrdProp(TObject(AObj), Info));
  except
    on E: Exception do
      SetError('RqGetInt ' + string(AProp) + ': ' + E.Message);
  end;
end;

function RqSetStr(AObj: Pointer; AProp: PChar; AValue: PChar): Integer;
  stdcall;
var
  Info: PPropInfo;
begin
  Result := 0;
  try
    if EditSetStr(TObject(AObj), string(AProp), string(AValue)) or
       GridSetStr(TObject(AObj), string(AProp), string(AValue)) or
       MiscSetStr(TObject(AObj), string(AProp), string(AValue)) or
       MoreSetStr(TObject(AObj), string(AProp), string(AValue)) or
       SysSetStr(TObject(AObj), string(AProp), string(AValue)) or
       ViewSetStr(TObject(AObj), string(AProp), string(AValue)) or
       ImgSetStr(TObject(AObj), string(AProp), string(AValue)) then
    begin
      Result := 1;
      Exit;
    end;
    Info := FindProp(TObject(AObj), string(AProp));
    if Info = nil then
      Exit;
    if not (Info^.PropType^.Kind in [tkSString, tkLString, tkAString,
                                     tkUString, tkWString]) then
    begin
      SetError(string(AProp) + ': not a string property');
      Exit;
    end;
    SetStrProp(TObject(AObj), Info, WinCPToUTF8(string(AValue)));
    Result := 1;
  except
    on E: Exception do
      SetError('RqSetStr ' + string(AProp) + ': ' + E.Message);
  end;
end;

// Строковое свойство в буфер ABuf (ABufLen байт вместе с нулём в конце).
// Возвращает длину строки без нуля: больше ABufLen - 1 - буфер мал, в нём
// начало строки.
function RqGetStr(AObj: Pointer; AProp: PChar; ABuf: PChar;
                  ABufLen: Integer): Integer; stdcall;
var
  Info: PPropInfo;
  Value: string;
begin
  Result := 0;
  try
    if (ABuf <> nil) and (ABufLen > 0) then
      ABuf^ := #0;
    if not EditGetStr(TObject(AObj), string(AProp), Value) and
       not GridGetStr(TObject(AObj), string(AProp), Value) and
       not MiscGetStr(TObject(AObj), string(AProp), Value) and
       not MoreGetStr(TObject(AObj), string(AProp), Value) and
       not SysGetStr(TObject(AObj), string(AProp), Value) and
       not ViewGetStr(TObject(AObj), string(AProp), Value) and
       not ImgGetStr(TObject(AObj), string(AProp), Value) then
    begin
      Info := FindProp(TObject(AObj), string(AProp));
      if Info = nil then
        Exit;
      Value := UTF8ToWinCP(GetStrProp(TObject(AObj), Info));
    end;
    Result := Length(Value);
    if (ABuf <> nil) and (ABufLen > 0) then
      StrPLCopy(ABuf, Value, ABufLen - 1);
  except
    on E: Exception do
      SetError('RqGetStr ' + string(AProp) + ': ' + E.Message);
  end;
end;

// Свойство-объект. Parent у LCL не published - ставится напрямую.
function RqSetObj(AObj: Pointer; AProp: PChar; AValue: Pointer): Integer;
  stdcall;
var
  Info: PPropInfo;
begin
  Result := 0;
  try
    if MiscSetObj(TObject(AObj), string(AProp), TObject(AValue)) then
    begin
      Result := 1;
      Exit;
    end;
    if CompareText(string(AProp), 'PARENT') = 0 then
    begin
      if not (TObject(AObj) is TControl) then
      begin
        SetError('Parent: object is not a control');
        Exit;
      end;
      if (AValue <> nil) and not (TObject(AValue) is TWinControl) then
      begin
        SetError('Parent: parent cannot contain controls');
        Exit;
      end;
      MoreBeforeParent(TObject(AObj), TObject(AValue));
      TControl(AObj).Parent := TWinControl(AValue);
      MoreAfterParent(TObject(AObj));
      Result := 1;
      Exit;
    end;
    // Font2 = Font1 (QFONT): значения копируются
    if CompareText(string(AProp), 'ASSIGN') = 0 then
    begin
      if not (TObject(AObj) is TPersistent) or
         not (TObject(AValue) is TPersistent) then
      begin
        SetError('Assign: no object');
        Exit;
      end;
      TPersistent(AObj).Assign(TPersistent(AValue));
      Result := 1;
      Exit;
    end;
    if EditSetObj(TObject(AObj), string(AProp), TObject(AValue)) then
    begin
      Result := 1;
      Exit;
    end;
    Info := FindProp(TObject(AObj), string(AProp));
    if Info = nil then
      Exit;
    SetObjectProp(TObject(AObj), Info, TObject(AValue));
    Result := 1;
  except
    on E: Exception do
      SetError('RqSetObj ' + string(AProp) + ': ' + E.Message);
  end;
end;

// Обработчик события AEvent (OnClick, OnChange, OnShow, OnClose...).
// nil - снять. 1 - назначено.
function RqSetEvent(AObj: Pointer; AEvent: PChar;
                    AProc: TRqEventProc): Integer; stdcall;
var
  Info: PPropInfo;
  Comp: TComponent;
  Data: TRqData;
  Link: TRqEventLink;
  Handler: TMethod;
  NotifyProc: TNotifyEvent;
  CloseQueryProc: TCloseQueryEvent;
  TreeChangeProc: TTVChangedEvent;
  TypeName: string;
begin
  Result := 0;
  try
    if not (TObject(AObj) is TComponent) then
    begin
      SetError('RqSetEvent: no object');
      Exit;
    end;
    Comp := TComponent(AObj);
    Info := FindProp(Comp, string(AEvent));
    if Info = nil then
      Exit;
    if Info^.PropType^.Kind <> tkMethod then
    begin
      SetError(string(AEvent) + ': not an event');
      Exit;
    end;
    Link := LinkOf(Comp, string(AEvent));
    if not Assigned(AProc) then
    begin
      // Снять: свойство пустое, переходник не нужен
      Handler.Code := nil;
      Handler.Data := nil;
      SetMethodProp(Comp, Info, Handler);
      Link.Free;
      Result := 1;
      Exit;
    end;
    TypeName := Info^.PropType^.Name;
    if (TypeName <> 'TNotifyEvent') and (TypeName <> 'TCloseQueryEvent') and
       (TypeName <> 'TTVChangedEvent') then
    begin
      SetError(string(AEvent) + ': event type ' + TypeName +
               ' is not supported yet');
      Exit;
    end;
    if Link = nil then
    begin
      Link := TRqEventLink.Create(Comp);
      Link.EventName := string(AEvent);
    end;
    Data := DataOf(Comp);
    if Data <> nil then
      Link.User := Data.User;
    Link.Proc := AProc;
    Link.ProcEx := nil;
    if TypeName = 'TNotifyEvent' then
    begin
      NotifyProc := @Link.FireNotify;
      Handler := TMethod(NotifyProc);
    end
    else if TypeName = 'TTVChangedEvent' then
    begin
      TreeChangeProc := @Link.FireTreeChange;
      Handler := TMethod(TreeChangeProc);
    end
    else
    begin
      CloseQueryProc := @Link.FireCloseQuery;
      Handler := TMethod(CloseQueryProc);
    end;
    SetMethodProp(Comp, Info, Handler);
    Result := 1;
  except
    on E: Exception do
      SetError('RqSetEvent ' + string(AEvent) + ': ' + E.Message);
  end;
end;

// Обработчик события с параметрами (OnKeyDown, OnKeyPress, OnKeyUp,
// OnMouseDown, OnMouseUp, OnMouseMove, OnSelectCell, OnDrawCell,
// OnSetEditText). AEventId возвращается в AProc - по нему вызывающий
// находит свой обработчик. nil - снять. 1 - назначено.
function RqSetEventEx(AObj: Pointer; AEvent: PChar; AEventId: Integer;
                      AProc: TRqEventProcEx): Integer; stdcall;
var
  Info: PPropInfo;
  Comp: TComponent;
  Data: TRqData;
  Link: TRqEventLink;
  Handler: TMethod;
  TypeName: string;
  KeyProc: TKeyEvent;
  KeyPressProc: TUTF8KeyPressEvent;
  MouseProc: TMouseEvent;
  MouseMoveProc: TMouseMoveEvent;
  SelectCellProc: TOnSelectCellEvent;
  DrawCellProc: TOnDrawCell;
  SetEditProc: TSetEditEvent;
  NotifyExProc: TNotifyEvent;
  DrawItemProc: TDrawItemEvent;
  TreeNodeProc: TTVChangedEvent;
  TreeAllowProc: TTVChangingEvent;
  ListChangeProc: TLVChangeEvent;
  ColumnClickProc: TLVColumnClickEvent;
begin
  Result := 0;
  try
    if not (TObject(AObj) is TComponent) then
    begin
      SetError('RqSetEventEx: no object');
      Exit;
    end;
    Comp := TComponent(AObj);
    Info := FindProp(Comp, string(AEvent));
    if Info = nil then
      Exit;
    if Info^.PropType^.Kind <> tkMethod then
    begin
      SetError(string(AEvent) + ': not an event');
      Exit;
    end;
    Link := LinkOf(Comp, string(AEvent));
    if not Assigned(AProc) then
    begin
      Handler.Code := nil;
      Handler.Data := nil;
      SetMethodProp(Comp, Info, Handler);
      Link.Free;
      Result := 1;
      Exit;
    end;
    if Link = nil then
    begin
      Link := TRqEventLink.Create(Comp);
      Link.EventName := string(AEvent);
    end;
    Data := DataOf(Comp);
    if Data <> nil then
      Link.User := Data.User;
    Link.ProcEx := AProc;
    Link.Proc := nil;
    Link.EventId := AEventId;
    TypeName := Info^.PropType^.Name;
    if TypeName = 'TNotifyEvent' then
    begin
      NotifyExProc := @Link.FireNotify;
      Handler := TMethod(NotifyExProc);
    end
    else if TypeName = 'TDrawItemEvent' then
    begin
      DrawItemProc := @Link.FireDrawItem;
      Handler := TMethod(DrawItemProc);
    end
    else if (TypeName = 'TTVChangedEvent') or (TypeName = 'TTVExpandedEvent') then
    begin
      TreeNodeProc := @Link.FireTreeNode;
      Handler := TMethod(TreeNodeProc);
    end
    else if (TypeName = 'TTVChangingEvent') or (TypeName = 'TTVExpandingEvent') then
    begin
      TreeAllowProc := @Link.FireTreeAllow;
      Handler := TMethod(TreeAllowProc);
    end
    else if TypeName = 'TLVChangeEvent' then
    begin
      ListChangeProc := @Link.FireListChange;
      Handler := TMethod(ListChangeProc);
    end
    else if TypeName = 'TLVColumnClickEvent' then
    begin
      ColumnClickProc := @Link.FireColumnClick;
      Handler := TMethod(ColumnClickProc);
    end
    else if TypeName = 'TKeyEvent' then
    begin
      KeyProc := @Link.FireKey;
      Handler := TMethod(KeyProc);
    end
    else if TypeName = 'TUTF8KeyPressEvent' then
    begin
      KeyPressProc := @Link.FireUTF8KeyPress;
      Handler := TMethod(KeyPressProc);
    end
    else if TypeName = 'TMouseEvent' then
    begin
      MouseProc := @Link.FireMouse;
      Handler := TMethod(MouseProc);
    end
    else if TypeName = 'TMouseMoveEvent' then
    begin
      MouseMoveProc := @Link.FireMouseMove;
      Handler := TMethod(MouseMoveProc);
    end
    else if TypeName = 'TOnSelectCellEvent' then
    begin
      SelectCellProc := @Link.FireSelectCell;
      Handler := TMethod(SelectCellProc);
    end
    else if TypeName = 'TOnDrawCell' then
    begin
      DrawCellProc := @Link.FireDrawCell;
      Handler := TMethod(DrawCellProc);
    end
    else if TypeName = 'TSetEditEvent' then
    begin
      SetEditProc := @Link.FireSetEditText;
      Handler := TMethod(SetEditProc);
    end
    else
    begin
      SetError(string(AEvent) + ': event type ' + TypeName +
               ' is not supported yet');
      Exit;
    end;
    SetMethodProp(Comp, Info, Handler);
    Result := 1;
  except
    on E: Exception do
      SetError('RqSetEventEx ' + string(AEvent) + ': ' + E.Message);
  end;
end;

// Метод со строкой и списком целых (рисование: FillRect, TextOut, Line...)
function RqCallInts(AObj: Pointer; AMethod: PChar; AStr: PChar;
                    AInts: PInteger; ACount: Integer): Integer; stdcall;
var
  IntList: array of Integer;
  IntIdx: Integer;
begin
  Result := 0;
  try
    SetLength(IntList, ACount);
    for IntIdx := 0 to ACount - 1 do
      IntList[IntIdx] := PInteger(PtrUInt(AInts) + PtrUInt(IntIdx * SizeOf(Integer)))^;
    if GridDraw(TObject(AObj), string(AMethod), string(AStr), IntList, Result) or
       ImgDraw(TObject(AObj), string(AMethod), string(AStr), IntList, Result) then
      Exit;
    if AObj = nil then
      SetError('RqCallInts ' + string(AMethod) + ': no object')
    else
      SetError(TObject(AObj).ClassName + ': no method ' + string(AMethod));
    Result := 0;
  except
    on E: Exception do
    begin
      SetError(string(AMethod) + ': ' + E.Message);
      Result := 0;
    end;
  end;
end;

// Метод с объектом и целым: AddItems, DelItems, Insert у меню. 1 - выполнен.
function RqCallObj(AObj: Pointer; AMethod: PChar; AOther: Pointer;
                   AInt: Integer): Integer; stdcall;
begin
  Result := 0;
  try
    if MiscCallObj(TObject(AObj), string(AMethod), TObject(AOther), AInt) then
      Result := 1
    else if AObj = nil then
      SetError('RqCallObj ' + string(AMethod) + ': no object')
    else
      SetError(TObject(AObj).ClassName + ': no method ' + string(AMethod));
  except
    on E: Exception do
      SetError(string(AMethod) + ': ' + E.Message);
  end;
end;

// Метод с другим объектом и списком целых: QIMAGELIST.Draw(Image, X, Y, i),
// QIMAGE.CopyRect(D, Image, S). Результат - как у RqCallInts.
function RqCallObjInts(AObj: Pointer; AMethod: PChar; AOther: Pointer;
                       AInts: PInteger; ACount: Integer): Integer; stdcall;
var
  IntList: array of Integer;
  IntIdx: Integer;
begin
  Result := 0;
  try
    SetLength(IntList, ACount);
    for IntIdx := 0 to ACount - 1 do
      IntList[IntIdx] := PInteger(PtrUInt(AInts) + PtrUInt(IntIdx * SizeOf(Integer)))^;
    if ImgCallObjInts(TObject(AObj), string(AMethod), TObject(AOther), IntList,
                      Result) then
      Exit;
    Result := 0;
    if AObj = nil then
      SetError('RqCallObjInts ' + string(AMethod) + ': no object')
    else
      SetError(TObject(AObj).ClassName + ': no method ' + string(AMethod));
  except
    on E: Exception do
    begin
      SetError(string(AMethod) + ': ' + E.Message);
      Result := 0;
    end;
  end;
end;

// Метод без параметров: ShowModal (возвращает ModalResult), Show, Hide,
// Close, Center, SetFocus, Repaint, BringToFront; Click у кнопки
function RqCall(AObj: Pointer; AMethod: PChar): Integer; stdcall;
var
  Method: string;
  Obj: TObject;
  CallResult: Integer;
begin
  Result := 0;
  try
    Obj := TObject(AObj);
    Method := UpperCase(string(AMethod));
    if SysCall(Obj, Method, CallResult) then
    begin
      Result := CallResult;
      Exit;
    end;
    if EditCall(Obj, Method) then
    begin
      Result := 1;
      Exit;
    end;
    if Obj is TCustomForm then
    begin
      if Method = 'SHOWMODAL' then
      begin
        Result := TCustomForm(Obj).ShowModal;
        Exit;
      end
      else if Method = 'CLOSE' then
      begin
        TCustomForm(Obj).Close;
        Result := 1;
        Exit;
      end
      else if Method = 'CENTER' then
      begin
        TCustomForm(Obj).Position := poScreenCenter;
        Result := 1;
        Exit;
      end;
    end;
    if Obj is TControl then
    begin
      if Method = 'SHOW' then
        TControl(Obj).Show
      else if Method = 'HIDE' then
        TControl(Obj).Hide
      else if Method = 'REPAINT' then
        TControl(Obj).Repaint
      else if Method = 'BRINGTOFRONT' then
        TControl(Obj).BringToFront
      else if (Method = 'SETFOCUS') and (Obj is TWinControl) then
        TWinControl(Obj).SetFocus
      // Нажатие кнопки из программы (как щелчок мышью) - для проверки
      // событий без пользователя
      else if (Method = 'CLICK') and (Obj is TCustomButton) then
        TCustomButton(Obj).Click
      else
      begin
        SetError(Obj.ClassName + ': no method ' + string(AMethod));
        Exit;
      end;
      Result := 1;
      Exit;
    end;
    SetError('RqCall ' + string(AMethod) + ': no object');
  except
    on E: Exception do
      SetError('RqCall ' + string(AMethod) + ': ' + E.Message);
  end;
end;

// Метод с одним целым параметром: у QFONT AddStyle / DelStyle (номер
// стиля fsBold 0, fsItalic 1, fsUnderline 2, fsStrikeOut 3)
function RqCallInt(AObj: Pointer; AMethod: PChar; AValue: Integer): Integer;
  stdcall;
var
  Method: string;
  Obj: TObject;
  CallResult: Integer;
begin
  Result := 0;
  try
    Obj := TObject(AObj);
    Method := UpperCase(string(AMethod));
    if SysCallInt(Obj, Method, AValue, CallResult) then
    begin
      Result := CallResult;
      Exit;
    end;
    if (Obj is TFont) and ((Method = 'ADDSTYLE') or (Method = 'DELSTYLE')) then
    begin
      if (AValue < Ord(Low(TFontStyle))) or (AValue > Ord(High(TFontStyle))) then
      begin
        SetError(string(AMethod) + ': no font style ' + IntToStr(AValue));
        Exit;
      end;
      if Method = 'ADDSTYLE' then
      begin
        TFont(Obj).Style := TFont(Obj).Style + [TFontStyle(AValue)];
        Result := 1;
        Exit;
      end;
      if Method = 'DELSTYLE' then
      begin
        TFont(Obj).Style := TFont(Obj).Style - [TFontStyle(AValue)];
        Result := 1;
        Exit;
      end;
    end;
    if Obj is TFont then
    begin
      // Число шрифтов в системе (QFONT.FontCount)
      if Method = 'FONTCOUNT' then
      begin
        Result := Screen.Fonts.Count;
        Exit;
      end;
      // QFONT.Handle = h. HFONT - 32-битное значение и в Win64
      if Method = 'SETHANDLE' then
      begin
        TFont(Obj).Handle := HFONT(PtrInt(AValue));
        Result := 1;
        Exit;
      end;
    end;
    if Obj = nil then
      SetError('RqCallInt ' + string(AMethod) + ': no object')
    else
      SetError(Obj.ClassName + ': no method ' + string(AMethod));
  except
    on E: Exception do
      SetError('RqCallInt ' + string(AMethod) + ': ' + E.Message);
  end;
end;

// Свойство-объект (Font у элемента) - сам объект LCL; nil - нет
function RqGetObj(AObj: Pointer; AProp: PChar): Pointer; stdcall;
var
  Info: PPropInfo;
  Found: TObject;
begin
  Result := nil;
  try
    if EditGetObj(TObject(AObj), string(AProp), Found) then
    begin
      Result := Found;
      Exit;
    end;
    Info := FindProp(TObject(AObj), string(AProp));
    if Info = nil then
      Exit;
    if Info^.PropType^.Kind <> tkClass then
    begin
      SetError(string(AProp) + ': not an object property');
      Exit;
    end;
    Result := GetObjectProp(TObject(AObj), Info);
  except
    on E: Exception do
      SetError('RqGetObj ' + string(AProp) + ': ' + E.Message);
  end;
end;

// Handle Windows: окно элемента, HFONT шрифта; 0 - нет
function RqGetHandle(AObj: Pointer): PtrInt; stdcall;
begin
  Result := 0;
  try
    if TObject(AObj) is TWinControl then
      Result := PtrInt(TWinControl(AObj).Handle)
    else if TObject(AObj) is TFont then
      Result := PtrInt(TFont(AObj).Handle)
    else
      SetError('RqGetHandle: object has no handle');
  except
    on E: Exception do
      SetError('RqGetHandle: ' + E.Message);
  end;
end;

// Строка из списка по номеру (с 0): у QFONT FontName(i) - имя шрифта
// системы. Буфер и результат - как у RqGetStr.
function RqGetItemStr(AObj: Pointer; AProp: PChar; AIndex: Integer;
                      ABuf: PChar; ABufLen: Integer): Integer; stdcall;
var
  Prop: string;
  Value: string;
  Found: Boolean;
begin
  Result := 0;
  try
    if (ABuf <> nil) and (ABufLen > 0) then
      ABuf^ := #0;
    Prop := UpperCase(string(AProp));
    Found := False;
    Value := '';
    if EditGetItem(TObject(AObj), Prop, AIndex, Value) or
       MiscGetItem(TObject(AObj), Prop, AIndex, Value) or
       MoreGetItem(TObject(AObj), Prop, AIndex, Value) or
       ViewGetItem(TObject(AObj), Prop, AIndex, Value) then
      Found := True
    else if (TObject(AObj) is TFont) and (Prop = 'FONTNAME') then
    begin
      Found := True;
      if (AIndex < 0) or (AIndex >= Screen.Fonts.Count) then
      begin
        SetError('FontName: index ' + IntToStr(AIndex) + ' out of 0..' +
                 IntToStr(Screen.Fonts.Count - 1));
        Result := -1;
        Exit;
      end;
      Value := UTF8ToWinCP(Screen.Fonts[AIndex]);
    end;
    if not Found then
    begin
      if AObj = nil then
        SetError('RqGetItemStr ' + string(AProp) + ': no object')
      else
        SetError(TObject(AObj).ClassName + ': no list ' + string(AProp));
      Result := -1;
      Exit;
    end;
    Result := Length(Value);
    if (ABuf <> nil) and (ABufLen > 0) then
      StrPLCopy(ABuf, Value, ABufLen - 1);
  except
    on E: Exception do
    begin
      SetError('RqGetItemStr ' + string(AProp) + ': ' + E.Message);
      Result := -1;
    end;
  end;
end;

// Записать строку списка по номеру (с 0): Line(i) у QRICHEDIT
function RqSetItemStr(AObj: Pointer; AProp: PChar; AIndex: Integer;
                      AValue: PChar): Integer; stdcall;
begin
  Result := 0;
  try
    if EditSetItem(TObject(AObj), string(AProp), AIndex, string(AValue)) or
       MiscSetItem(TObject(AObj), string(AProp), AIndex, string(AValue)) or
       MoreSetItem(TObject(AObj), string(AProp), AIndex, string(AValue)) or
       ViewSetItem(TObject(AObj), string(AProp), AIndex, string(AValue)) then
      Result := 1
    else if AObj = nil then
      SetError('RqSetItemStr ' + string(AProp) + ': no object')
    else
      SetError(TObject(AObj).ClassName + ': no list ' + string(AProp));
  except
    on E: Exception do
      SetError('RqSetItemStr ' + string(AProp) + ': ' + E.Message);
  end;
end;

// Метод с одним строковым параметром: AddStrings, LoadFromFile,
// SaveToFile. 1 - выполнен.
function RqCallStr(AObj: Pointer; AMethod: PChar; AValue: PChar): Integer;
  stdcall;
begin
  Result := 0;
  try
    if EditCallStr(TObject(AObj), string(AMethod), string(AValue)) then
      Result := 1
    else if AObj = nil then
      SetError('RqCallStr ' + string(AMethod) + ': no object')
    else
      SetError(TObject(AObj).ClassName + ': no method ' + string(AMethod));
  except
    on E: Exception do
      SetError('RqCallStr ' + string(AMethod) + ': ' + E.Message);
  end;
end;

// Строка в буфер вызывающего: как у RqGetStr
function CopyOut(const AValue: string; ABuf: PChar; ABufLen: Integer): Integer;
begin
  Result := Length(AValue);
  if (ABuf <> nil) and (ABufLen > 0) then
    StrPLCopy(ABuf, AValue, ABufLen - 1);
end;

// Ячейка таблицы (QSTRINGGRID.Cell(Col, Row)). Вне таблицы - -1.
function RqGetCell(AObj: Pointer; ACol, ARow: Integer; ABuf: PChar;
                   ABufLen: Integer): Integer; stdcall;
var
  Value: string;
begin
  Result := -1;
  try
    if (ABuf <> nil) and (ABufLen > 0) then
      ABuf^ := #0;
    if GridGetCell(TObject(AObj), ACol, ARow, Value) or
       ViewGetCell(TObject(AObj), ACol, ARow, Value) then
      Result := CopyOut(Value, ABuf, ABufLen)
    else
      SetError('RqGetCell: object has no cells');
  except
    on E: Exception do
      SetError(E.Message);
  end;
end;

function RqSetCell(AObj: Pointer; ACol, ARow: Integer;
                   AValue: PChar): Integer; stdcall;
begin
  Result := 0;
  try
    if GridSetCell(TObject(AObj), ACol, ARow, string(AValue)) or
       ViewSetCell(TObject(AObj), ACol, ARow, string(AValue)) then
      Result := 1
    else
      SetError('RqSetCell: object has no cells');
  except
    on E: Exception do
      SetError(E.Message);
  end;
end;

// Целое из списка по номеру: ColWidths(i), RowHeights(i)
function RqGetItemInt(AObj: Pointer; AProp: PChar; AIndex: Integer): Integer;
  stdcall;
begin
  Result := 0;
  // 0 - и значение, и ошибка; вызывающий отличает их по RqLastError
  RqLastErrorText := '';
  try
    if not GridGetItemInt(TObject(AObj), string(AProp), AIndex, Result) and
       not MiscGetItemInt(TObject(AObj), string(AProp), AIndex, Result) and
       not MoreGetItemInt(TObject(AObj), string(AProp), AIndex, Result) and
       not ViewGetItemInt(TObject(AObj), string(AProp), AIndex, Result) then
      SetError('RqGetItemInt: no list ' + string(AProp));
  except
    on E: Exception do
      SetError(E.Message);
  end;
end;

function RqSetItemInt(AObj: Pointer; AProp: PChar; AIndex: Integer;
                      AValue: Integer): Integer; stdcall;
begin
  Result := 0;
  try
    if GridSetItemInt(TObject(AObj), string(AProp), AIndex, AValue) or
       MiscSetItemInt(TObject(AObj), string(AProp), AIndex, AValue) or
       MoreSetItemInt(TObject(AObj), string(AProp), AIndex, AValue) or
       ViewSetItemInt(TObject(AObj), string(AProp), AIndex, AValue) then
      Result := 1
    else
      SetError('RqSetItemInt: no list ' + string(AProp));
  except
    on E: Exception do
      SetError(E.Message);
  end;
end;

// Метод со строкой и тремя целыми (LoadFromFile таблицы, SwapCols...).
// Результат - целое метода (ошибка - 0, текст в RqLastError) или, у
// методов со строкой-результатом, её длина (как у RqGetStr; ошибка - -1).
function RqCallEx(AObj: Pointer; AMethod: PChar; AStr: PChar;
                  AInt1, AInt2, AInt3: Integer; ABuf: PChar;
                  ABufLen: Integer): Integer; stdcall;
var
  IntResult: Integer;
  StrResult: string;
  IsStr: Boolean;
begin
  Result := 0;
  IsStr := False;
  try
    if (ABuf <> nil) and (ABufLen > 0) then
      ABuf^ := #0;
    if GridCallEx(TObject(AObj), string(AMethod), string(AStr), AInt1, AInt2,
                  AInt3, IntResult, StrResult, IsStr) then
    begin
      if IsStr then
        Result := CopyOut(StrResult, ABuf, ABufLen)
      else
        Result := IntResult;
    end
    else if MiscCallEx(TObject(AObj), string(AMethod), string(AStr), AInt1,
                       AInt2, AInt3, IntResult) or
            MoreCallEx(TObject(AObj), string(AMethod), string(AStr), AInt1,
                       AInt2, AInt3, IntResult) or
            ViewCallEx(TObject(AObj), string(AMethod), string(AStr), AInt1,
                       AInt2, AInt3, IntResult) or
            ImgCallEx(TObject(AObj), string(AMethod), string(AStr), AInt1,
                      AInt2, AInt3, IntResult) then
      Result := IntResult
    else if AObj = nil then
      SetError('RqCallEx ' + string(AMethod) + ': no object')
    else
      SetError(TObject(AObj).ClassName + ': no method ' + string(AMethod));
  except
    on E: Exception do
    begin
      SetError(string(AMethod) + ': ' + E.Message);
      if IsStr then
        Result := -1;
    end;
  end;
end;

// DoEvents RapidQ
procedure RqDoEvents; stdcall;
begin
  try
    Application.ProcessMessages;
  except
    on E: Exception do
      SetError('RqDoEvents: ' + E.Message);
  end;
end;

// Текст последней ошибки (ANSI) в буфер; возвращает его длину
function RqLastError(ABuf: PChar; ABufLen: Integer): Integer; stdcall;
var
  Value: string;
begin
  Value := UTF8ToWinCP(RqLastErrorText);
  Result := Length(Value);
  if (ABuf <> nil) and (ABufLen > 0) then
    StrPLCopy(ABuf, Value, ABufLen - 1);
end;

initialization
  FillTables;
end.
