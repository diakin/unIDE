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

    // --- Поиск ---
    // Текст целиком и куски Unit1 берёт прямо из буфера своего редактора
    // (TEdRichEmu.GetRange, GetAllText), без сообщений.
    // Поиск - тоже напрямую (TEdRichEmu.FindText).

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

    // --- Оформление ---
    // Формат абзаца (EM_GETPARAFORMAT / EM_SETPARAFORMAT). AFormat -
    // TParaFormat или TParaFormat2 с заполненным cbSize
    procedure GetParaFormat(var AFormat);
    procedure SetParaFormat(var AFormat);
  end;

implementation

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


// --- Поиск ---


// --- Выделение и правка ---

procedure TEdIntf.GetSel(var ASel: TCharRange);
begin
  SendMessageA(Wnd, EM_EXGETSEL, 0, LPARAM(@ASel));
end;

procedure TEdIntf.SetSel(var ASel: TCharRange);
begin
  SendMessageA(Wnd, EM_EXSETSEL, 0, LPARAM(@ASel));
end;

procedure TEdIntf.SetSelRange(AFrom, ATo: Integer);
begin
  SendMessageA(Wnd, EM_SETSEL, AFrom, ATo);
end;

procedure TEdIntf.ReplaceSel(const AText: string);
begin
  SendMessageA(Wnd, EM_REPLACESEL, 1, LPARAM(PChar(AText)));
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
  SendMessageA(Wnd, EM_GETSCROLLPOS_, 0, LPARAM(@APos));
end;

procedure TEdIntf.PosFromChar(var APt: TPoint; ACharIdx: Integer);
begin
  SendMessageA(Wnd, EM_POSFROMCHAR, WPARAM(@APt), ACharIdx);
end;

function TEdIntf.CharFromPos(const APt: TPoint): Integer;
begin
  Result := SendMessageA(Wnd, EM_CHARFROMPOS, 0, LPARAM(@APt));
end;

procedure TEdIntf.GetRect(var ARect: TRect);
begin
  SendMessageA(Wnd, EM_GETRECT, 0, LPARAM(@ARect));
end;

procedure TEdIntf.SetRect(const ARect: TRect);
begin
  SendMessageA(Wnd, EM_SETRECT, 0, LPARAM(@ARect));
end;

procedure TEdIntf.SetRectNP(const ARect: TRect);
begin
  SendMessageA(Wnd, EM_SETRECTNP, 0, LPARAM(@ARect));
end;

// --- Оформление ---

procedure TEdIntf.GetParaFormat(var AFormat);
begin
  SendMessageA(Wnd, EM_GETPARAFORMAT, 0, LPARAM(@AFormat));
end;

procedure TEdIntf.SetParaFormat(var AFormat);
begin
  SendMessageA(Wnd, EM_SETPARAFORMAT, 0, LPARAM(@AFormat));
end;

end.
