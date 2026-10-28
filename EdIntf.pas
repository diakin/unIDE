unit EdIntf;

// ---------------------------------------------------------------------------
//  Прослойка между Unit1 и окном редактора (план портирования на Lazarus,
//  шаг 0.1).
//
//  Сейчас за ней окно RichEdit1 (RichEdit 4.1). Каждый метод посылает то же
//  сообщение EM_*, с теми же параметрами, что раньше стояло прямо в Unit1,
//  поэтому поведение редактора не меняется.
//
//  Зачем. Unit1 обращается к тексту, выделению и прокрутке редактора только
//  через этот класс. На шаге 0.7 у него появится вторая реализация - свой
//  редактор (EdBuffer / EdView), и вызовы в Unit1 менять не придётся.
//
//  Позиции - сквозной индекс символа в модели RichEdit 4.1: перевод строки
//  считается одним символом. Номера строк - с 0.
//
//  Окно берётся при каждом вызове через функцию AGetHandle (у Unit1 - это
//  RichEdit1.Handle): VCL пересоздаёт окно контрола, хранить HWND нельзя.
//
//  Модуль без VCL - только Windows, Messages, RichEdit.
// ---------------------------------------------------------------------------

interface

uses
  Windows, Messages, RichEdit;

type
  // Окно редактора - спрашивается заново при каждом вызове
  TEdHandleFunc = function: HWND of object;

  TEdIntf = class
  private
    FGetHandle: TEdHandleFunc;
    function Wnd: HWND;
  public
    constructor Create(AGetHandle: TEdHandleFunc);

    // --- Строки ---
    // Число строк (EM_GETLINECOUNT)
    function LineCount: Integer;
    // Индекс первого символа строки ALine; -1 - строка каретки
    // (EM_LINEINDEX). Строки нет - -1
    function LineIndex(ALine: Integer): Integer;
    // Длина строки, в которой стоит символ ACharIdx (EM_LINELENGTH)
    function LineLength(ACharIdx: Integer): Integer;
    // Строка символа ACharIdx (EM_LINEFROMCHAR)
    function LineFromChar(ACharIdx: Integer): Integer;
    // То же через EM_EXLINEFROMCHAR (индекс в lParam, без предела 64К)
    function ExLineFromChar(ACharIdx: Integer): Integer;
    // Копия строки ALine в буфер ABuffer (EM_GETLINE). В первом слове
    // буфера перед вызовом - его размер. Результат - число символов
    function GetLine(ALine: Integer; ABuffer: Pointer): Integer;

    // --- Текст целиком и куски ---
    // Записи передаются как есть, без проверки типа: у Unit1 они объявлены
    // локально в своих функциях (GETTEXTLENGTHEX, GETTEXTEX, TEXTRANGE,
    // FINDTEXTEX - раскладка из RichEdit.h).
    // Длина текста (EM_GETTEXTLENGTHEX, AInfo - GETTEXTLENGTHEX)
    function GetTextLengthEx(var AInfo): Integer;
    // Текст в буфер ABuffer (EM_GETTEXTEX, AInfo - GETTEXTEX). Результат -
    // число записанных байт / символов
    function GetTextEx(var AInfo; ABuffer: Pointer): Integer;
    // Кусок текста (EM_GETTEXTRANGE, ARange - TEXTRANGE). Окно RichEdit 4.1
    // пишет его в UTF-16 - см. TRichEdit в Unit1
    function GetTextRange(var ARange): Integer;
    // Поиск (EM_FINDTEXTW через SendMessageW, AFind - FINDTEXTW). Результат -
    // позиция найденного, -1 - нет
    function FindTextW(AFlags: Integer; var AFind): Integer;

    // --- Выделение и правка ---
    procedure GetSel(var ASel: TCharRange);           // EM_EXGETSEL
    procedure SetSel(var ASel: TCharRange);           // EM_EXSETSEL
    procedure SetSelRange(AFrom, ATo: Integer);       // EM_SETSEL
    // Заменить выделение текстом AText; с записью в откат (EM_REPLACESEL)
    procedure ReplaceSel(const AText: string);
    function  CanUndo: Boolean;                       // EM_CANUNDO
    procedure Undo;                                   // EM_UNDO
    procedure Redo;                                   // EM_REDO

    // --- Экран ---
    // Номер первой видимой строки (EM_GETFIRSTVISIBLELINE)
    function FirstVisibleLine: Integer;
    // Прокрутить на ALines строк вниз (вверх - отрицательное) (EM_LINESCROLL)
    procedure LineScroll(ALines: Integer);
    // Показать каретку (EM_SCROLLCARET)
    procedure ScrollCaret;
    // Положение прокрутки в пикселях (EM_GETSCROLLPOS)
    procedure GetScrollPos(var APos: TPoint);
    // Координаты символа ACharIdx в окне (EM_POSFROMCHAR)
    procedure PosFromChar(var APt: TPoint; ACharIdx: Integer);
    // Символ под точкой окна APt (EM_CHARFROMPOS)
    function CharFromPos(const APt: TPoint): Integer;
    // Прямоугольник текста (EM_GETRECT / EM_SETRECT / EM_SETRECTNP - без
    // перерисовки)
    procedure GetRect(var ARect: TRect);
    procedure SetRect(const ARect: TRect);
    procedure SetRectNP(const ARect: TRect);

    // --- Оформление и пределы ---
    // Формат абзаца (EM_GETPARAFORMAT / EM_SETPARAFORMAT). AFormat -
    // TParaFormat или TParaFormat2 с заполненным cbSize
    procedure GetParaFormat(var AFormat);
    procedure SetParaFormat(var AFormat);
    // Предел объёма текста в символах (EM_GETLIMITTEXT / EM_EXLIMITTEXT)
    function  GetLimitText: Integer;
    procedure SetLimitText(ALimit: Integer);
    // Перенос строк: 0 - по ширине окна, 1 - без переноса
    // (EM_SETTARGETDEVICE, wParam 0). Результат - ответ окна
    function  SetTargetDevice(ALineWidth: Integer): Integer;
    // Какие уведомления окно шлёт родителю (EM_GETEVENTMASK /
    // EM_SETEVENTMASK)
    function  GetEventMask: Integer;
    procedure SetEventMask(AMask: Integer);
  end;

implementation

const
  // Сообщения RichEdit по RichEdit.h. Свои константы, а не из RichEdit.pas:
  // в модуле Delphi 7 части из них нет, у других другие имена. Значения -
  // те же, что у локальных констант, которыми Unit1 пользовался раньше
  EM_GETTEXTRANGE_     = WM_USER + 75;
  EM_GETEVENTMASK_     = WM_USER + 59;
  EM_SETEVENTMASK_     = WM_USER + 69;
  EM_SETTARGETDEVICE_  = WM_USER + 72;
  EM_GETTEXTEX_        = WM_USER + 94;
  EM_GETTEXTLENGTHEX_  = WM_USER + 95;
  EM_FINDTEXTW_        = WM_USER + 123;

constructor TEdIntf.Create(AGetHandle: TEdHandleFunc);
begin
  inherited Create;
  FGetHandle := AGetHandle;
end;

function TEdIntf.Wnd: HWND;
begin
  Result := FGetHandle();
end;

// --- Строки ---

function TEdIntf.LineCount: Integer;
begin
  Result := SendMessageA(Wnd, EM_GETLINECOUNT, 0, 0);
end;

function TEdIntf.LineIndex(ALine: Integer): Integer;
begin
  Result := SendMessageA(Wnd, EM_LINEINDEX, ALine, 0);
end;

function TEdIntf.LineLength(ACharIdx: Integer): Integer;
begin
  Result := SendMessageA(Wnd, EM_LINELENGTH, ACharIdx, 0);
end;

function TEdIntf.LineFromChar(ACharIdx: Integer): Integer;
begin
  Result := SendMessageA(Wnd, EM_LINEFROMCHAR, ACharIdx, 0);
end;

function TEdIntf.ExLineFromChar(ACharIdx: Integer): Integer;
begin
  Result := SendMessageA(Wnd, EM_EXLINEFROMCHAR, 0, ACharIdx);
end;

function TEdIntf.GetLine(ALine: Integer; ABuffer: Pointer): Integer;
begin
  Result := SendMessageA(Wnd, EM_GETLINE, ALine, Integer(ABuffer));
end;

// --- Текст целиком и куски ---

function TEdIntf.GetTextLengthEx(var AInfo): Integer;
begin
  Result := SendMessageA(Wnd, EM_GETTEXTLENGTHEX_, Integer(@AInfo), 0);
end;

function TEdIntf.GetTextEx(var AInfo; ABuffer: Pointer): Integer;
begin
  Result := SendMessageA(Wnd, EM_GETTEXTEX_, Integer(@AInfo), Integer(ABuffer));
end;

function TEdIntf.GetTextRange(var ARange): Integer;
begin
  Result := SendMessageA(Wnd, EM_GETTEXTRANGE_, 0, Integer(@ARange));
end;

function TEdIntf.FindTextW(AFlags: Integer; var AFind): Integer;
begin
  Result := SendMessageW(Wnd, EM_FINDTEXTW_, AFlags, Integer(@AFind));
end;

// --- Выделение и правка ---

procedure TEdIntf.GetSel(var ASel: TCharRange);
begin
  SendMessageA(Wnd, EM_EXGETSEL, 0, Integer(@ASel));
end;

procedure TEdIntf.SetSel(var ASel: TCharRange);
begin
  SendMessageA(Wnd, EM_EXSETSEL, 0, Integer(@ASel));
end;

procedure TEdIntf.SetSelRange(AFrom, ATo: Integer);
begin
  SendMessageA(Wnd, EM_SETSEL, AFrom, ATo);
end;

procedure TEdIntf.ReplaceSel(const AText: string);
begin
  SendMessageA(Wnd, EM_REPLACESEL, 1, Integer(PChar(AText)));
end;

function TEdIntf.CanUndo: Boolean;
begin
  Result := SendMessageA(Wnd, EM_CANUNDO, 0, 0) <> 0;
end;

procedure TEdIntf.Undo;
begin
  SendMessageA(Wnd, EM_UNDO, 0, 0);
end;

procedure TEdIntf.Redo;
begin
  SendMessageA(Wnd, EM_REDO, 0, 0);
end;

// --- Экран ---

function TEdIntf.FirstVisibleLine: Integer;
begin
  Result := SendMessageA(Wnd, EM_GETFIRSTVISIBLELINE, 0, 0);
end;

procedure TEdIntf.LineScroll(ALines: Integer);
begin
  SendMessageA(Wnd, EM_LINESCROLL, 0, ALines);
end;

procedure TEdIntf.ScrollCaret;
begin
  SendMessageA(Wnd, EM_SCROLLCARET, 0, 0);
end;

procedure TEdIntf.GetScrollPos(var APos: TPoint);
const
  // В RichEdit.pas Delphi 7 этой константы нет
  EM_GETSCROLLPOS_ = WM_USER + 221;
begin
  SendMessageA(Wnd, EM_GETSCROLLPOS_, 0, Integer(@APos));
end;

procedure TEdIntf.PosFromChar(var APt: TPoint; ACharIdx: Integer);
begin
  SendMessageA(Wnd, EM_POSFROMCHAR, Integer(@APt), ACharIdx);
end;

function TEdIntf.CharFromPos(const APt: TPoint): Integer;
begin
  Result := SendMessageA(Wnd, EM_CHARFROMPOS, 0, Integer(@APt));
end;

procedure TEdIntf.GetRect(var ARect: TRect);
begin
  SendMessageA(Wnd, EM_GETRECT, 0, Integer(@ARect));
end;

procedure TEdIntf.SetRect(const ARect: TRect);
begin
  SendMessageA(Wnd, EM_SETRECT, 0, Integer(@ARect));
end;

procedure TEdIntf.SetRectNP(const ARect: TRect);
begin
  SendMessageA(Wnd, EM_SETRECTNP, 0, Integer(@ARect));
end;

// --- Оформление и пределы ---

procedure TEdIntf.GetParaFormat(var AFormat);
begin
  SendMessageA(Wnd, EM_GETPARAFORMAT, 0, Integer(@AFormat));
end;

procedure TEdIntf.SetParaFormat(var AFormat);
begin
  SendMessageA(Wnd, EM_SETPARAFORMAT, 0, Integer(@AFormat));
end;

function TEdIntf.GetLimitText: Integer;
const
  // В RichEdit.pas Delphi 7 этой константы нет
  EM_GETLIMITTEXT_ = WM_USER + 37;
begin
  Result := SendMessageA(Wnd, EM_GETLIMITTEXT_, 0, 0);
end;

procedure TEdIntf.SetLimitText(ALimit: Integer);
begin
  SendMessageA(Wnd, EM_EXLIMITTEXT, 0, ALimit);
end;

function TEdIntf.SetTargetDevice(ALineWidth: Integer): Integer;
begin
  Result := SendMessageA(Wnd, EM_SETTARGETDEVICE_, 0, ALineWidth);
end;

function TEdIntf.GetEventMask: Integer;
begin
  Result := SendMessageA(Wnd, EM_GETEVENTMASK_, 0, 0);
end;

procedure TEdIntf.SetEventMask(AMask: Integer);
begin
  SendMessageA(Wnd, EM_SETEVENTMASK_, 0, AMask);
end;

end.
