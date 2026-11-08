unit DlgFontViewer;

// ---------------------------------------------------------------------------
//  FontViewer - просмотр шрифтов UTFT (меню Arduino - Font Viewer (UTFT)).
//
//  Шрифт UTFT - массив байт в .c-файле (libraries\UTFT\*.c):
//    fontdatatype Grotesk16x32[6084] PROGMEM={ 0x10,0x20,0x20,0x5F, ... };
//  Первые 4 байта - ширина символа, высота, код первого символа, число
//  символов; дальше символы подряд, каждый - строками сверху вниз, в
//  строке ширина/8 байт, старший бит - левая точка (как в UTFT::printChar
//  и в ArdSim/src/sim_utft.cpp).
//
//  Окно шириной 480 точек (ширина экрана 480x320 прибора) и высотой
//  рабочей области экрана. Для каждого шрифта: имя массива, размер символа
//  в точках, диапазон кодов, размер данных, файл и образец - все символы
//  шрифта (или свой текст: Вид - Текст образца...) в масштабе 1:1, белым
//  на чёрном, как на экране. Шрифты - из всех .c папки (Файл - Открыть
//  папку...) или из выбранных файлов (Файл - Открыть файл...). В одном
//  файле может быть несколько шрифтов (DefaultFonts.c). Массивы, которые
//  не похожи на шрифт (картинки unsigned short, неверный заголовок, данных
//  меньше, чем нужно), перечислены в конце списка с причиной.
//
//  Щелчок - выбрать шрифт; Ctrl+C - имя массива, Ctrl+Shift+C - строка
//  extern uint8_t Имя[]; для скетча; Enter или двойной щелчок - открыть
//  .c в unIDE (OnOpenFile). Под мышью - код символа в строке состояния.
//
//  Вид - Сортировка: по имени или по размеру (высота, потом ширина).
//  Вид - Скрыть: группы по имени массива (7-сегментные, Italic, Bold),
//  неполные (до 16 символов: цифры, значки) и не шрифты.
//
//  Файл - Создать шрифт из TTF... - окно DlgTtfToUtft (OnMakeFont).
//  Правка - Редактировать символы... (Ctrl+E) - окно DlgUtftEdit: правка
//  выбранного шрифта по точкам, замена символа копией другого, запись в
//  новый .c-файл; записанный файл открывается в списке.
//
//  Окно строится в коде, .dfm нет. Немодальное, одно (ShowFontViewer),
//  освобождается при закрытии.
// ---------------------------------------------------------------------------

interface

uses
  {$IFDEF FPC} LCLType, {$ENDIF}
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  StdCtrls, ExtCtrls, Dialogs, Menus, Clipbrd,
  UiStdCtrls,    // TUiPanel, TUiLabel
  UiMenus,       // TUiMenuBar - меню окна в темах Dark и Custom
  UiScroll,      // TUiScrollBar
  UiTheme,       // UiThemeColor, UM_UITHEMECHANGED
  FolderDlg,     // BrowseFolderDialog
  IniBuf;        // TBufIniFile - положение окна и последняя папка

const
  // Ширина образца - ширина экрана прибора
  FontViewWidth = 480;

type
  TFontOpenFileEvent = procedure(const AFileName: string) of object;

  // Один массив из .c-файла: шрифт или то, что им не оказалось (Problem)
  TUtftFont = class
  public
    Name: string;
    FileName: string;
    DeclSize: Integer;      // число в [] объявления; -1 - нет
    Data: array of Byte;
    SizeX, SizeY: Integer;
    FirstChar, CharCount: Integer;
    Problem: string;        // '' - шрифт; иначе почему не шрифт
    Note: string;           // замечание к шрифту (размер в [] другой)
    // Раскладка в окне (от начала списка)
    Top, Height: Integer;
    SampleTop: Integer;     // начало образца
    SampleCols: Integer;
    SampleCodes: array of Integer;
    Bitmap: TBitmap;        // образец; строится при первом показе
    destructor Destroy; override;
    function IsFont: Boolean;
    function GlyphOffset(ACode: Integer): Integer;  // -1 - кода нет
  end;

  TDlgFontViewer = class;

  // Список шрифтов: рисует сам, прокрутка - TUiScrollBar окна
  TFontListView = class(TCustomControl)
  private
    FOwnerDlg: TDlgFontViewer;
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
                        PosX, PosY: Integer); override;
    procedure MouseMove(Shift: TShiftState; PosX, PosY: Integer); override;
    procedure DblClick; override;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TDlgFontViewer = class(TForm)
  private
    FFonts: TList;            // TUtftFont: сначала шрифты, потом остальное
    FShown: TList;            // показанные из FFonts (без скрытых групп);
                              // FSelected - индекс в FShown
    FSortBySize: Boolean;
    FHideMask: Integer;       // скрытые группы: бит 1 shl FvGroup*
    FFileCount: Integer;
    FSourceText: string;      // что открыто: папка или файлы - для заголовка
    FFolder: string;          // открытая папка ('' - открыты файлы)
    FFiles: TStringList;      // открытые файлы (FFolder = '')
    FSampleText: string;      // '' - все символы шрифта
    FShowCells: Boolean;
    FSelected: Integer;
    FTopPos: Integer;         // прокрутка, точки
    FContentHeight: Integer;
    FIniFile: string;
    FDefaultFolder: string;
    FPlaceSaved: Boolean;
    FOnOpenFile: TFontOpenFileEvent;
    FOnMakeFont: TNotifyEvent;
    FMiMakeFont: TMenuItem;
    FClickCode: Integer;      // символ под последним щелчком

    FMainMenu: TMainMenu;
    FMenuBar: TUiMenuBar;
    FMiAllChars, FMiSampleText, FMiCells: TMenuItem;
    FMiOpenInEditor: TMenuItem;
    FMiSortName, FMiSortSize: TMenuItem;
    FMiHide: array of TMenuItem;
    FStatusPanel: TUiPanel;
    FStatusLabel: TUiLabel;
    FHoverLabel: TUiLabel;
    FScrollBar: TUiScrollBar;
    FView: TFontListView;
    FHeadFontHeight: Integer;

    procedure Build;
    procedure BuildMenu;
    procedure ClearFonts;
    procedure LoadFile(const AFileName: string);
    procedure SortFonts;
    procedure ApplyFilter;
    procedure MenuSortClick(Sender: TObject);
    procedure MenuHideClick(Sender: TObject);
    procedure Relayout;
    procedure UpdateScroll;
    procedure UpdateColors;
    procedure UpdateStatus;
    procedure ScrollTo(APos: Integer);
    procedure EnsureVisible(AIndex: Integer);
    function  FontAt(PosY: Integer): Integer;
    function  CodeAt(AFont: TUtftFont; PosX, PosY: Integer): Integer;
    procedure PaintView(ACanvas: TCanvas; const AClip: TRect);
    procedure ViewMouseDown(PosX, PosY: Integer);
    procedure ViewMouseMove(PosX, PosY: Integer);
    procedure ViewDblClick;

    procedure MenuOpenFileClick(Sender: TObject);
    procedure MenuOpenFolderClick(Sender: TObject);
    procedure MenuReloadClick(Sender: TObject);
    procedure MenuOpenInEditorClick(Sender: TObject);
    procedure MenuCloseClick(Sender: TObject);
    procedure MenuMakeFontClick(Sender: TObject);
    procedure MenuCopyNameClick(Sender: TObject);
    procedure MenuCopyExternClick(Sender: TObject);
    procedure MenuEditFontClick(Sender: TObject);
    procedure FontSaved(const AFileName: string);
    procedure MenuAllCharsClick(Sender: TObject);
    procedure MenuSampleTextClick(Sender: TObject);
    procedure MenuCellsClick(Sender: TObject);
    procedure ScrollChange(Sender: TObject);
    procedure ViewResize(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure UMUiThemeChanged(var Message: TMessage); message UM_UITHEMECHANGED;
    procedure LoadPlacement;
    procedure SavePlacement;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    constructor CreateDlg(AOwner: TComponent);
    destructor Destroy; override;
    // Папка со шрифтами: все *.c
    procedure OpenFolder(const AFolder: string);
    // Отдельные файлы
    procedure OpenFiles(AFiles: TStrings);
    // Ini для положения окна, последней папки и текста образца; ADefault -
    // папка, если в ini её нет (libraries\UTFT)
    procedure SetPlacementIni(const AIniFile, ADefaultFolder: string);
    property OnOpenFile: TFontOpenFileEvent read FOnOpenFile write FOnOpenFile;
    property OnMakeFont: TNotifyEvent read FOnMakeFont write FOnMakeFont;
  end;

// Окно FontViewer: одно на программу; если уже открыто - поднять его.
// AOnMakeFont - пункт Файл - Создать шрифт из TTF... (nil - пункта нет)
procedure ShowFontViewer(AOwner: TComponent; const AIniFile,
  ADefaultFolder: string; AOnOpenFile: TFontOpenFileEvent;
  AOnMakeFont: TNotifyEvent);

// Символы образца AFont (SampleCodes, SampleCols): все символы шрифта
// (ASampleText = '') или текст
procedure UtftSetSample(AFont: TUtftFont; const ASampleText: string);
// Окно FontViewer, если открыто; nil - нет
function FontViewerInstance: TDlgFontViewer;
// Образец 1:1 белым на чёрном шириной FontViewWidth по SampleCodes;
// AShowCells - клетки через одну темнее
function UtftMakeSample(AFont: TUtftFont; AShowCells: Boolean): TBitmap;

// Разбор .c-файла: каждый массив с инициализатором { } - в AList
// (TUtftFont). Результат - False, если файл не прочитан
function UtftParseFile(const AFileName: string; AList: TList): Boolean;

implementation

uses
  DlgUtftEdit;   // EditUtftFont

const
  FvSection = 'FontViewer';
  FvGap = 6;              // отступ слева у заголовка
  FvItemGap = 14;         // между шрифтами
  FvGlyphColor = clWhite;
  FvScreenColor = clBlack;
  FvCellColor = $00242424;     // клетка через одну (Вид - Клетки символов)
  FvMissingColor = $00000050;  // символа нет в шрифте (свой текст)

  // Группы для Вид - Скрыть
  FvGroupSeg = 0;
  FvGroupItalic = 1;
  FvGroupBold = 2;
  FvGroupPartial = 3;
  FvGroupNotFont = 4;
  FvGroupCount = 5;
  FvGroupNames: array[0..FvGroupCount - 1] of string = (
    '&7-сегментные (Seg, Seven в имени)', '&Italic (Ital, Oblique в имени)',
    '&Bold (в имени)', '&Неполные: цифры, значки (до 16 символов)',
    'Н&е шрифты');
  FvPartialMax = 16;

var
  FontViewerWindow: TDlgFontViewer = nil;

// Шрифт из группы AGroup (Вид - Скрыть)
function FontInGroup(AFont: TUtftFont; AGroup: Integer): Boolean;
var
  LowName: string;
begin
  LowName := LowerCase(AFont.Name);
  case AGroup of
    FvGroupSeg:
      Result := AFont.IsFont and ((Pos('seg', LowName) > 0) or
        (Pos('seven', LowName) > 0));
    FvGroupItalic:
      Result := AFont.IsFont and ((Pos('ital', LowName) > 0) or
        (Pos('oblique', LowName) > 0));
    FvGroupBold:
      Result := AFont.IsFont and (Pos('bold', LowName) > 0);
    FvGroupPartial:
      Result := AFont.IsFont and (AFont.CharCount <= FvPartialMax);
    FvGroupNotFont:
      Result := not AFont.IsFont;
  else
    Result := False;
  end;
end;

// Высота строки текста шрифтом AFont
function FontTextHeight(AFont: TFont): Integer;
var
  Measure: TBitmap;
begin
  Measure := TBitmap.Create;
  try
    Measure.Width := 4;
    Measure.Height := 4;
    Measure.Canvas.Font := AFont;
    Result := Measure.Canvas.TextHeight('Wg');
  finally
    Measure.Free;
  end;
  if Result < 8 then
    Result := 14;
end;

function IsDarkColorValue(AColor: TColor): Boolean;
var
  Rgb: Longint;
begin
  Rgb := ColorToRGB(AColor);
  Result := (GetRValue(Rgb) * 30 + GetGValue(Rgb) * 59 +
             GetBValue(Rgb) * 11) < 128 * 100;
end;

// ---------------------------------------------------------------------------
//  Разбор .c
// ---------------------------------------------------------------------------

// Комментарии и строки препроцессора - пробелами (позиции те же)
function StripCSource(const ASrc: string): string;
var
  Index, SrcLen: Integer;
  LineStart: Boolean;
  Quote: Char;

  // Перед переводом строки APos - '\' (строка препроцессора продолжается)
  function PrevIsBackslash(APos: Integer): Boolean;
  var
    Back: Integer;
  begin
    Back := APos - 1;
    if (Back >= 1) and (ASrc[Back] = #13) then
      Dec(Back);
    Result := (Back >= 1) and (ASrc[Back] = '\');
  end;

begin
  Result := ASrc;
  SrcLen := Length(Result);
  Index := 1;
  LineStart := True;
  while Index <= SrcLen do
  begin
    if (Result[Index] = '/') and (Index < SrcLen) and (Result[Index + 1] = '/') then
    begin
      while (Index <= SrcLen) and (Result[Index] <> #10) do
      begin
        if Result[Index] <> #13 then
          Result[Index] := ' ';
        Inc(Index);
      end;
      Continue;
    end;
    if (Result[Index] = '/') and (Index < SrcLen) and (Result[Index + 1] = '*') then
    begin
      Result[Index] := ' ';
      Result[Index + 1] := ' ';
      Inc(Index, 2);
      while (Index <= SrcLen) and
            not ((Result[Index] = '*') and (Index < SrcLen) and (Result[Index + 1] = '/')) do
      begin
        if not (Result[Index] in [#10, #13]) then
          Result[Index] := ' ';
        Inc(Index);
      end;
      if Index <= SrcLen then
      begin
        Result[Index] := ' ';
        if Index < SrcLen then
          Result[Index + 1] := ' ';
        Inc(Index, 2);
      end;
      Continue;
    end;
    if LineStart and (Result[Index] = '#') then
    begin
      // #define, #include, #if: до конца строки (с переносом \)
      while Index <= SrcLen do
      begin
        if (Result[Index] = #10) and not PrevIsBackslash(Index) then
          Break;
        if not (Result[Index] in [#10, #13]) then
          Result[Index] := ' ';
        Inc(Index);
      end;
      Continue;
    end;
    if (Result[Index] = '"') or (Result[Index] = '''') then
    begin
      // Строки и символы оставляем, но внутри них не ищем комментарии
      Quote := Result[Index];
      Inc(Index);
      while (Index <= SrcLen) and (Result[Index] <> Quote) and
            (Result[Index] <> #10) do
      begin
        if (Result[Index] = '\') and (Index < SrcLen) then
          Inc(Index);
        Inc(Index);
      end;
      Inc(Index);
      LineStart := False;
      Continue;
    end;
    if Result[Index] = #10 then
      LineStart := True
    else if not (Result[Index] in [' ', #9, #13]) then
      LineStart := False;
    Inc(Index);
  end;
end;

function IsIdentChar(ACh: Char): Boolean;
begin
  Result := ACh in ['A'..'Z', 'a'..'z', '0'..'9', '_'];
end;

// Число C: 0x.., 0b.., Arduino B0101, восьмеричное 0.., десятичное,
// 'c'; суффиксы U, L
function ParseCNumber(const AToken: string; var AValue: Integer): Boolean;
var
  Text: string;
  Index, Digit, Base: Integer;
  Value: Int64;
begin
  Result := False;
  Text := Trim(AToken);
  if Text = '' then
    Exit;
  if (Length(Text) >= 3) and (Text[1] = '''') and (Text[Length(Text)] = '''') then
  begin
    if Length(Text) = 3 then
    begin
      AValue := Ord(Text[2]);
      Result := True;
    end;
    Exit;
  end;
  while (Text <> '') and (UpCase(Text[Length(Text)]) in ['U', 'L']) do
    Delete(Text, Length(Text), 1);
  if Text = '' then
    Exit;
  Base := 10;
  Index := 1;
  if (Length(Text) > 2) and (Text[1] = '0') and (UpCase(Text[2]) = 'X') then
  begin
    Base := 16;
    Index := 3;
  end
  else if (Length(Text) > 2) and (Text[1] = '0') and (UpCase(Text[2]) = 'B') then
  begin
    Base := 2;
    Index := 3;
  end
  else if (Length(Text) > 1) and (Text[1] = 'B') then
  begin
    Base := 2;
    Index := 2;
  end
  else if (Length(Text) > 1) and (Text[1] = '0') then
  begin
    Base := 8;
    Index := 2;
  end;
  Value := 0;
  while Index <= Length(Text) do
  begin
    case Text[Index] of
      '0'..'9': Digit := Ord(Text[Index]) - Ord('0');
      'A'..'F': Digit := Ord(Text[Index]) - Ord('A') + 10;
      'a'..'f': Digit := Ord(Text[Index]) - Ord('a') + 10;
    else
      Exit;
    end;
    if Digit >= Base then
      Exit;
    Value := Value * Base + Digit;
    if Value > MaxInt then
      Exit;
    Inc(Index);
  end;
  AValue := Integer(Value);
  Result := True;
end;

// Слово AWord есть в ADecl отдельным словом
function HasWord(const ADecl, AWord: string): Boolean;
var
  Lower: string;
  Start, Found: Integer;
begin
  Result := False;
  Lower := ' ' + LowerCase(ADecl) + ' ';
  Start := 1;
  repeat
    Found := Pos(AWord, Copy(Lower, Start, MaxInt));
    if Found = 0 then
      Exit;
    Found := Found + Start - 1;
    if not IsIdentChar(Lower[Found - 1]) and
       not IsIdentChar(Lower[Found + Length(AWord)]) then
    begin
      Result := True;
      Exit;
    end;
    Start := Found + 1;
  until False;
end;

// Шрифт ли это; Problem - почему нет
// Тип в объявлении - не байт (unsigned short картинки UTFT и т.п.)
function TypeNotBytes(const ADecl: string): Boolean;
begin
  Result := HasWord(ADecl, 'short') or HasWord(ADecl, 'int') or
    HasWord(ADecl, 'long') or HasWord(ADecl, 'uint16_t') or
    HasWord(ADecl, 'int16_t') or HasWord(ADecl, 'uint32_t') or
    HasWord(ADecl, 'int32_t') or HasWord(ADecl, 'word') or
    HasWord(ADecl, 'bitmapdatatype');
end;

procedure CheckFont(AFont: TUtftFont);
var
  Need, BytesPerRow: Integer;
begin
  if Length(AFont.Data) < 4 then
  begin
    AFont.Problem := 'меньше 4 байт - нет заголовка шрифта';
    Exit;
  end;
  AFont.SizeX := AFont.Data[0];
  AFont.SizeY := AFont.Data[1];
  AFont.FirstChar := AFont.Data[2];
  AFont.CharCount := AFont.Data[3];
  if (AFont.SizeX = 0) or (AFont.SizeY = 0) or (AFont.CharCount = 0) then
  begin
    AFont.Problem := Format('заголовок %d, %d, %d, %d - не шрифт',
      [AFont.SizeX, AFont.SizeY, AFont.FirstChar, AFont.CharCount]);
    Exit;
  end;
  if AFont.SizeX mod 8 <> 0 then
  begin
    AFont.Problem := Format('ширина символа %d не кратна 8', [AFont.SizeX]);
    Exit;
  end;
  BytesPerRow := AFont.SizeX div 8;
  Need := 4 + AFont.CharCount * BytesPerRow * AFont.SizeY;
  if Length(AFont.Data) < Need then
  begin
    AFont.Problem := Format('%d x %d, %d символов: нужно %d байт, в ' +
      'массиве %d', [AFont.SizeX, AFont.SizeY, AFont.CharCount, Need,
      Length(AFont.Data)]);
    Exit;
  end;
  if Length(AFont.Data) > Need then
    AFont.Note := Format('в массиве %d байт, шрифту нужно %d',
      [Length(AFont.Data), Need])
  else if (AFont.DeclSize >= 0) and (AFont.DeclSize <> Length(AFont.Data)) then
    AFont.Note := Format('в объявлении [%d], значений %d',
      [AFont.DeclSize, Length(AFont.Data)]);
end;

function UtftParseFile(const AFileName: string; AList: TList): Boolean;
var
  Raw: TStringList;
  Src: string;
  SrcLen, Index, BraceAt, EqAt, DeclStart, CloseAt, Depth: Integer;
  ValStart, ValIdx, Value, Count, NameEnd, NameStart, BrOpen, BrClose: Integer;
  Decl, Token: string;
  Font: TUtftFont;
  Bad: Boolean;
begin
  Result := False;
  Raw := TStringList.Create;
  try
    try
      Raw.LoadFromFile(AFileName);
    except
      Exit;
    end;
    Src := StripCSource(Raw.Text);
  finally
    Raw.Free;
  end;
  Result := True;
  SrcLen := Length(Src);
  Index := 1;
  DeclStart := 1;
  while Index <= SrcLen do
  begin
    if Src[Index] in [';', '}'] then
    begin
      DeclStart := Index + 1;
      Inc(Index);
      Continue;
    end;
    if Src[Index] <> '{' then
    begin
      Inc(Index);
      Continue;
    end;
    BraceAt := Index;
    // Конец { }: с учётом вложенных
    Depth := 0;
    CloseAt := BraceAt;
    while CloseAt <= SrcLen do
    begin
      if Src[CloseAt] = '{' then
        Inc(Depth)
      else if Src[CloseAt] = '}' then
      begin
        Dec(Depth);
        if Depth = 0 then
          Break;
      end;
      Inc(CloseAt);
    end;
    // Перед { - '=': инициализатор массива; иначе (функция, struct) - мимо
    EqAt := BraceAt - 1;
    while (EqAt >= DeclStart) and (Src[EqAt] in [' ', #9, #13, #10]) do
      Dec(EqAt);
    if (EqAt < DeclStart) or (Src[EqAt] <> '=') then
    begin
      Index := CloseAt + 1;
      DeclStart := Index;
      Continue;
    end;
    Decl := Copy(Src, DeclStart, EqAt - DeclStart);
    // Имя - перед первой '[' (или последнее слово)
    BrOpen := Pos('[', Decl);
    if BrOpen > 0 then
      NameEnd := BrOpen - 1
    else
      NameEnd := Length(Decl);
    while (NameEnd > 0) and not IsIdentChar(Decl[NameEnd]) do
      Dec(NameEnd);
    NameStart := NameEnd;
    while (NameStart > 1) and IsIdentChar(Decl[NameStart - 1]) do
      Dec(NameStart);
    Font := TUtftFont.Create;
    Font.FileName := AFileName;
    Font.DeclSize := -1;
    if NameEnd > 0 then
      Font.Name := Copy(Decl, NameStart, NameEnd - NameStart + 1)
    else
      Font.Name := '(без имени)';
    if BrOpen > 0 then
    begin
      BrClose := Pos(']', Decl);
      if (BrClose > BrOpen) and
         not ParseCNumber(Copy(Decl, BrOpen + 1, BrClose - BrOpen - 1), Font.DeclSize) then
        Font.DeclSize := -1;
    end;
    // Тип элементов - не байт: картинка (unsigned short) или таблица
    if TypeNotBytes(Copy(Decl, 1, NameStart - 1)) then
      Font.Problem := 'не массив байт (картинка или таблица): ' +
        Trim(Copy(Decl, 1, NameStart - 1));
    // Значения
    SetLength(Font.Data, CloseAt - BraceAt);
    Count := 0;
    Bad := False;
    ValStart := BraceAt + 1;
    for ValIdx := BraceAt + 1 to CloseAt do
    begin
      if (ValIdx < CloseAt) and (Src[ValIdx] <> ',') then
        Continue;
      Token := Trim(Copy(Src, ValStart, ValIdx - ValStart));
      ValStart := ValIdx + 1;
      if Token = '' then
        Continue;
      if not ParseCNumber(Token, Value) or (Value < 0) or (Value > 255) then
      begin
        if Font.Problem = '' then
          Font.Problem := 'значение "' + Copy(Token, 1, 20) + '" - не байт';
        Bad := True;
        Continue;
      end;
      Font.Data[Count] := Byte(Value);
      Inc(Count);
    end;
    SetLength(Font.Data, Count);
    if Pos('{', Copy(Src, BraceAt + 1, CloseAt - BraceAt - 1)) > 0 then
    begin
      Bad := True;
      Font.Problem := 'вложенные { } - не таблица байт';
    end;
    if not Bad and (Font.Problem = '') then
      CheckFont(Font);
    AList.Add(Font);
    Index := CloseAt + 1;
    DeclStart := Index;
  end;
end;

// ---------------------------------------------------------------------------
//  TUtftFont
// ---------------------------------------------------------------------------

destructor TUtftFont.Destroy;
begin
  Bitmap.Free;
  inherited Destroy;
end;

function TUtftFont.IsFont: Boolean;
begin
  Result := Problem = '';
end;

function TUtftFont.GlyphOffset(ACode: Integer): Integer;
begin
  if (ACode < FirstChar) or (ACode >= FirstChar + CharCount) then
    Result := -1
  else
    Result := 4 + (ACode - FirstChar) * (SizeX div 8) * SizeY;
end;

// По размеру: сначала шрифты, потом остальное; внутри - по высоте
// символа, ширине, имени
function CompareFontsBySize(Item1, Item2: Pointer): Integer;
var
  Font1, Font2: TUtftFont;
begin
  Font1 := TUtftFont(Item1);
  Font2 := TUtftFont(Item2);
  if Font1.IsFont <> Font2.IsFont then
  begin
    if Font1.IsFont then
      Result := -1
    else
      Result := 1;
    Exit;
  end;
  Result := 0;
  if Font1.IsFont then
  begin
    Result := Font1.SizeY - Font2.SizeY;
    if Result = 0 then
      Result := Font1.SizeX - Font2.SizeX;
  end;
  if Result = 0 then
    Result := CompareText(Font1.Name, Font2.Name);
  if Result = 0 then
    Result := CompareText(Font1.FileName, Font2.FileName);
end;

function CompareFonts(Item1, Item2: Pointer): Integer;
var
  Font1, Font2: TUtftFont;
begin
  Font1 := TUtftFont(Item1);
  Font2 := TUtftFont(Item2);
  // Сначала шрифты, потом остальное; внутри - по имени массива
  if Font1.IsFont <> Font2.IsFont then
  begin
    if Font1.IsFont then
      Result := -1
    else
      Result := 1;
    Exit;
  end;
  Result := CompareText(Font1.Name, Font2.Name);
  if Result = 0 then
    Result := CompareText(Font1.FileName, Font2.FileName);
end;

// Образец шрифта: FontViewWidth x строки символов, 1:1
function UtftMakeSample(AFont: TUtftFont; AShowCells: Boolean): TBitmap;
var
  CodeIdx, Code, Offset, CellX, CellY, Row, Part, Bit, RunStart: Integer;
  BytesPerRow, Rows: Integer;
  Bits: Byte;
  Canvas: TCanvas;
begin
  Result := TBitmap.Create;
  Rows := (Length(AFont.SampleCodes) + AFont.SampleCols - 1) div AFont.SampleCols;
  Result.PixelFormat := pf24bit;
  Result.Width := FontViewWidth;
  Result.Height := Rows * AFont.SizeY;
  if Result.Height = 0 then
    Exit;
  Canvas := Result.Canvas;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := FvScreenColor;
  Canvas.FillRect(Rect(0, 0, Result.Width, Result.Height));
  BytesPerRow := AFont.SizeX div 8;
  for CodeIdx := 0 to High(AFont.SampleCodes) do
  begin
    Code := AFont.SampleCodes[CodeIdx];
    CellX := (CodeIdx mod AFont.SampleCols) * AFont.SizeX;
    CellY := (CodeIdx div AFont.SampleCols) * AFont.SizeY;
    Offset := AFont.GlyphOffset(Code);
    if Offset < 0 then
    begin
      // Такого символа в шрифте нет (UTFT нарисовал бы мусор за таблицей)
      Canvas.Brush.Color := FvMissingColor;
      Canvas.FillRect(Rect(CellX, CellY, CellX + AFont.SizeX, CellY + AFont.SizeY));
      Continue;
    end;
    if AShowCells and Odd(CodeIdx mod AFont.SampleCols + CodeIdx div AFont.SampleCols) then
    begin
      Canvas.Brush.Color := FvCellColor;
      Canvas.FillRect(Rect(CellX, CellY, CellX + AFont.SizeX, CellY + AFont.SizeY));
    end;
    Canvas.Brush.Color := FvGlyphColor;
    for Row := 0 to AFont.SizeY - 1 do
    begin
      // Подряд идущие точки строки - одним прямоугольником
      RunStart := -1;
      for Part := 0 to BytesPerRow - 1 do
      begin
        Bits := AFont.Data[Offset + Row * BytesPerRow + Part];
        for Bit := 0 to 7 do
          if (Bits and ($80 shr Bit)) <> 0 then
          begin
            if RunStart < 0 then
              RunStart := Part * 8 + Bit;
          end
          else if RunStart >= 0 then
          begin
            Canvas.FillRect(Rect(CellX + RunStart, CellY + Row,
              CellX + Part * 8 + Bit, CellY + Row + 1));
            RunStart := -1;
          end;
      end;
      if RunStart >= 0 then
        Canvas.FillRect(Rect(CellX + RunStart, CellY + Row,
          CellX + AFont.SizeX, CellY + Row + 1));
    end;
  end;
end;

// Символы образца: все символы шрифта (ASampleText = '') или текст;
// столбцов - сколько клеток входит в FontViewWidth
procedure UtftSetSample(AFont: TUtftFont; const ASampleText: string);
var
  CodeIdx: Integer;
begin
  if ASampleText = '' then
  begin
    SetLength(AFont.SampleCodes, AFont.CharCount);
    for CodeIdx := 0 to AFont.CharCount - 1 do
      AFont.SampleCodes[CodeIdx] := AFont.FirstChar + CodeIdx;
  end
  else
  begin
    SetLength(AFont.SampleCodes, Length(ASampleText));
    for CodeIdx := 1 to Length(ASampleText) do
      AFont.SampleCodes[CodeIdx - 1] := Ord(ASampleText[CodeIdx]);
  end;
  AFont.SampleCols := 1;
  if AFont.SizeX > 0 then
    AFont.SampleCols := FontViewWidth div AFont.SizeX;
  if AFont.SampleCols < 1 then
    AFont.SampleCols := 1;
end;

// ---------------------------------------------------------------------------
//  TFontListView
// ---------------------------------------------------------------------------

constructor TFontListView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  DoubleBuffered := True;
  TabStop := True;
end;

procedure TFontListView.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  Message.Result := 1;
end;

procedure TFontListView.Paint;
begin
  if FOwnerDlg <> nil then
    FOwnerDlg.PaintView(Canvas, Canvas.ClipRect);
end;

procedure TFontListView.MouseDown(Button: TMouseButton; Shift: TShiftState;
  PosX, PosY: Integer);
begin
  inherited MouseDown(Button, Shift, PosX, PosY);
  if CanFocus then
    SetFocus;
  if FOwnerDlg <> nil then
    FOwnerDlg.ViewMouseDown(PosX, PosY);
end;

procedure TFontListView.MouseMove(Shift: TShiftState; PosX, PosY: Integer);
begin
  inherited MouseMove(Shift, PosX, PosY);
  if FOwnerDlg <> nil then
    FOwnerDlg.ViewMouseMove(PosX, PosY);
end;

procedure TFontListView.DblClick;
begin
  inherited DblClick;
  if FOwnerDlg <> nil then
    FOwnerDlg.ViewDblClick;
end;

// ---------------------------------------------------------------------------
//  TDlgFontViewer
// ---------------------------------------------------------------------------

function FontViewerInstance: TDlgFontViewer;
begin
  Result := FontViewerWindow;
end;

procedure ShowFontViewer(AOwner: TComponent; const AIniFile,
  ADefaultFolder: string; AOnOpenFile: TFontOpenFileEvent;
  AOnMakeFont: TNotifyEvent);
begin
  if FontViewerWindow = nil then
  begin
    FontViewerWindow := TDlgFontViewer.CreateDlg(AOwner);
    FontViewerWindow.OnOpenFile := AOnOpenFile;
    FontViewerWindow.OnMakeFont := AOnMakeFont;
    FontViewerWindow.SetPlacementIni(AIniFile, ADefaultFolder);
  end;
  FontViewerWindow.Show;
  if FontViewerWindow.WindowState = wsMinimized then
    FontViewerWindow.WindowState := wsNormal;
  FontViewerWindow.BringToFront;
end;

constructor TDlgFontViewer.CreateDlg(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  FFonts := TList.Create;
  FShown := TList.Create;
  FFiles := TStringList.Create;
  FSelected := -1;
  FClickCode := -1;
  Build;
  UiThemeAddClient(Self);
end;

destructor TDlgFontViewer.Destroy;
begin
  UiThemeRemoveClient(Self);
  if not FPlaceSaved then
    SavePlacement;
  ClearFonts;
  FFonts.Free;
  FShown.Free;
  FFiles.Free;
  if FontViewerWindow = Self then
    FontViewerWindow := nil;
  inherited Destroy;
end;

// Владелец окна - главное окно: окно над ним, а не под ним
procedure TDlgFontViewer.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  if (Owner is TWinControl) and TWinControl(Owner).HandleAllocated then
    Params.WndParent := TWinControl(Owner).Handle;
end;

procedure TDlgFontViewer.Build;
var
  Work: TRect;
  BarWidth, TextHeightPx: Integer;
begin
  Caption := 'Font Viewer (UTFT)';
  OnClose := FormClose;
  OnKeyDown := FormKeyDown;
  OnMouseWheel := FormMouseWheel;
  KeyPreview := True;
  BorderStyle := bsSizeable;
  BorderIcons := [biSystemMenu, biMinimize];
  // Шрифт окна - как у меню; без размера (Linux: 'default', 0) жирный
  // заголовок выходил огромным
  Font.Assign(Screen.MenuFont);
  if Font.Height = 0 then
    Font.Size := 9;
  TextHeightPx := FontTextHeight(Font);

  BuildMenu;

  FStatusPanel := TUiPanel.Create(Self);
  FStatusPanel.Parent := Self;
  FStatusPanel.Align := alBottom;
  FStatusPanel.BevelOuter := bvNone;
  FStatusPanel.Caption := '';
  FStatusPanel.Height := 2 * (TextHeightPx + 4) + 6;
  FStatusLabel := TUiLabel.Create(Self);
  FStatusLabel.Parent := FStatusPanel;
  FStatusLabel.AutoSize := False;
  FStatusLabel.SetBounds(FvGap, 3, FontViewWidth - 2 * FvGap, TextHeightPx + 4);
  FStatusLabel.Caption := '';
  FHoverLabel := TUiLabel.Create(Self);
  FHoverLabel.Parent := FStatusPanel;
  FHoverLabel.AutoSize := False;
  FHoverLabel.SetBounds(FvGap, FStatusLabel.Top + FStatusLabel.Height,
    FontViewWidth - 2 * FvGap, TextHeightPx + 4);
  FHoverLabel.Caption := '';

  BarWidth := GetSystemMetrics(SM_CXVSCROLL);
  if BarWidth < 12 then
    BarWidth := 17;
  FScrollBar := TUiScrollBar.Create(Self);
  FScrollBar.Parent := Self;
  FScrollBar.Kind := sbVertical;
  FScrollBar.Align := alRight;
  FScrollBar.Width := BarWidth;
  FScrollBar.SmallChange := 32;
  FScrollBar.OnChange := ScrollChange;

  FView := TFontListView.Create(Self);
  FView.FOwnerDlg := Self;
  FView.Parent := Self;
  FView.Align := alClient;
  FView.OnResize := ViewResize;

  // Ширина образца - 480 точек экрана; высота - рабочая область экрана
  ClientWidth := FontViewWidth + BarWidth;
  Constraints.MinWidth := Width;
  Constraints.MaxWidth := Width;
  Constraints.MinHeight := 240;
  Work := Screen.WorkAreaRect;
  Position := poDesigned;
  SetBounds(Work.Left + (Work.Right - Work.Left - Width) div 2, Work.Top,
    Width, Work.Bottom - Work.Top);

  UpdateColors;
  UpdateStatus;
end;

procedure TDlgFontViewer.BuildMenu;

  function AddItem(AParent: TMenuItem; const ACaption: string;
    AShortCut: TShortCut; AClick: TNotifyEvent): TMenuItem;
  begin
    Result := TMenuItem.Create(Self);
    Result.Caption := ACaption;
    Result.ShortCut := AShortCut;
    Result.OnClick := AClick;
    AParent.Add(Result);
  end;

var
  FileMenu, EditMenu, ViewMenu, SortMenu, HideMenu: TMenuItem;
  Group: Integer;
begin
  FMainMenu := TMainMenu.Create(Self);
  {$IFNDEF FPC}FMainMenu.AutoHotkeys := maManual;{$ENDIF}
  FileMenu := TMenuItem.Create(Self);
  FileMenu.Caption := '&Файл';
  FMainMenu.Items.Add(FileMenu);
  AddItem(FileMenu, '&Открыть файл...', ShortCut(Ord('O'), [ssCtrl]),
    MenuOpenFileClick);
  AddItem(FileMenu, 'Открыть &папку...', ShortCut(Ord('O'), [ssCtrl, ssShift]),
    MenuOpenFolderClick);
  AddItem(FileMenu, 'П&еречитать', ShortCut(VK_F5, []), MenuReloadClick);
  AddItem(FileMenu, '-', 0, nil);
  FMiOpenInEditor := AddItem(FileMenu, 'Открыть .c в &редакторе',
    ShortCut(VK_RETURN, []), MenuOpenInEditorClick);
  AddItem(FileMenu, '-', 0, nil);
  FMiMakeFont := AddItem(FileMenu, 'Создать шрифт из &TTF...',
    ShortCut(Ord('N'), [ssCtrl]), MenuMakeFontClick);
  AddItem(FileMenu, '-', 0, nil);
  AddItem(FileMenu, '&Закрыть', ShortCut(VK_ESCAPE, []), MenuCloseClick);

  EditMenu := TMenuItem.Create(Self);
  EditMenu.Caption := '&Правка';
  FMainMenu.Items.Add(EditMenu);
  AddItem(EditMenu, '&Копировать имя шрифта', ShortCut(Ord('C'), [ssCtrl]),
    MenuCopyNameClick);
  AddItem(EditMenu, 'Копировать &extern для скетча',
    ShortCut(Ord('C'), [ssCtrl, ssShift]), MenuCopyExternClick);
  AddItem(EditMenu, '-', 0, nil);
  AddItem(EditMenu, '&Редактировать символы...', ShortCut(Ord('E'), [ssCtrl]),
    MenuEditFontClick);

  ViewMenu := TMenuItem.Create(Self);
  ViewMenu.Caption := '&Вид';
  FMainMenu.Items.Add(ViewMenu);
  FMiAllChars := AddItem(ViewMenu, '&Все символы шрифта', 0, MenuAllCharsClick);
  FMiAllChars.RadioItem := True;
  FMiAllChars.GroupIndex := 1;
  FMiAllChars.Checked := True;
  FMiSampleText := AddItem(ViewMenu, '&Текст образца...',
    ShortCut(Ord('T'), [ssCtrl]), MenuSampleTextClick);
  FMiSampleText.RadioItem := True;
  FMiSampleText.GroupIndex := 1;
  AddItem(ViewMenu, '-', 0, nil);
  FMiCells := AddItem(ViewMenu, '&Клетки символов', ShortCut(Ord('G'), [ssCtrl]),
    MenuCellsClick);
  AddItem(ViewMenu, '-', 0, nil);
  SortMenu := AddItem(ViewMenu, '&Сортировка', 0, nil);
  FMiSortName := AddItem(SortMenu, 'По &имени', 0, MenuSortClick);
  FMiSortName.RadioItem := True;
  FMiSortName.GroupIndex := 2;
  FMiSortName.Tag := 0;
  FMiSortName.Checked := True;
  FMiSortSize := AddItem(SortMenu, 'По &размеру (высота, ширина)', 0,
    MenuSortClick);
  FMiSortSize.RadioItem := True;
  FMiSortSize.GroupIndex := 2;
  FMiSortSize.Tag := 1;
  HideMenu := AddItem(ViewMenu, 'С&крыть', 0, nil);
  SetLength(FMiHide, FvGroupCount);
  for Group := 0 to FvGroupCount - 1 do
  begin
    FMiHide[Group] := AddItem(HideMenu, FvGroupNames[Group], 0, MenuHideClick);
    FMiHide[Group].Tag := Group;
  end;

  // Меню Windows в теме Light, своя строка - в Dark и Custom
  Menu := FMainMenu;
  FMenuBar := TUiMenuBar.Create(Self);
  FMenuBar.Parent := Self;
  FMenuBar.Menu := FMainMenu;
end;

procedure TDlgFontViewer.ClearFonts;
var
  Index: Integer;
begin
  for Index := 0 to FFonts.Count - 1 do
    TUtftFont(FFonts[Index]).Free;
  FFonts.Clear;
  FShown.Clear;
  FSelected := -1;
  FFileCount := 0;
end;

procedure TDlgFontViewer.LoadFile(const AFileName: string);
begin
  if UtftParseFile(AFileName, FFonts) then
    Inc(FFileCount);
end;

procedure TDlgFontViewer.SortFonts;
begin
  if FSortBySize then
    FFonts.Sort(CompareFontsBySize)
  else
    FFonts.Sort(CompareFonts);
  ApplyFilter;
end;

// FShown - шрифты FFonts без скрытых групп; выбранный остаётся выбранным,
// если он виден
procedure TDlgFontViewer.ApplyFilter;
var
  Index, Group: Integer;
  FontItem, SelectedItem: TUtftFont;
  Hidden: Boolean;
begin
  SelectedItem := nil;
  if (FSelected >= 0) and (FSelected < FShown.Count) then
    SelectedItem := TUtftFont(FShown[FSelected]);
  FShown.Clear;
  FSelected := -1;
  for Index := 0 to FFonts.Count - 1 do
  begin
    FontItem := TUtftFont(FFonts[Index]);
    Hidden := False;
    for Group := 0 to FvGroupCount - 1 do
      if ((FHideMask and (1 shl Group)) <> 0) and FontInGroup(FontItem, Group) then
      begin
        Hidden := True;
        Break;
      end;
    if Hidden then
      Continue;
    if FontItem = SelectedItem then
      FSelected := FShown.Count;
    FShown.Add(FontItem);
  end;
end;

procedure TDlgFontViewer.MenuSortClick(Sender: TObject);
begin
  FSortBySize := TComponent(Sender).Tag = 1;
  FMiSortName.Checked := not FSortBySize;
  FMiSortSize.Checked := FSortBySize;
  SortFonts;
  Relayout;
  if FSelected >= 0 then
    EnsureVisible(FSelected);
  UpdateStatus;
end;

procedure TDlgFontViewer.MenuHideClick(Sender: TObject);
var
  Group: Integer;
begin
  Group := TComponent(Sender).Tag;
  FHideMask := FHideMask xor (1 shl Group);
  FMiHide[Group].Checked := (FHideMask and (1 shl Group)) <> 0;
  ApplyFilter;
  Relayout;
  if FSelected >= 0 then
    EnsureVisible(FSelected);
  UpdateStatus;
end;

procedure TDlgFontViewer.OpenFolder(const AFolder: string);
var
  Search: TSearchRec;
  Names: TStringList;
  Folder: string;
  Index: Integer;
begin
  Folder := ExcludeTrailingPathDelimiter(AFolder);
  Screen.Cursor := crHourGlass;
  Names := TStringList.Create;
  try
    ClearFonts;
    FFolder := Folder;
    FFiles.Clear;
    if FindFirst(IncludeTrailingPathDelimiter(Folder) + '*.c', faAnyFile, Search) = 0 then
    begin
      repeat
        if (Search.Attr and faDirectory) = 0 then
          Names.Add(IncludeTrailingPathDelimiter(Folder) + Search.Name);
      until FindNext(Search) <> 0;
      FindClose(Search);
    end;
    Names.Sort;
    for Index := 0 to Names.Count - 1 do
      LoadFile(Names[Index]);
    SortFonts;
    FSourceText := Folder;
  finally
    Names.Free;
    Screen.Cursor := crDefault;
  end;
  FTopPos := 0;
  Relayout;
  UpdateStatus;
end;

procedure TDlgFontViewer.OpenFiles(AFiles: TStrings);
var
  Index: Integer;
begin
  Screen.Cursor := crHourGlass;
  try
    ClearFonts;
    FFolder := '';
    FFiles.Assign(AFiles);
    for Index := 0 to AFiles.Count - 1 do
      LoadFile(AFiles[Index]);
    SortFonts;
    if AFiles.Count = 1 then
      FSourceText := AFiles[0]
    else if AFiles.Count > 1 then
      FSourceText := ExtractFileDir(AFiles[0]) + ' (' +
        IntToStr(AFiles.Count) + ' файлов)'
    else
      FSourceText := '';
  finally
    Screen.Cursor := crDefault;
  end;
  FTopPos := 0;
  Relayout;
  UpdateStatus;
end;

// Места шрифтов в списке; образцы - заново
procedure TDlgFontViewer.Relayout;
var
  Index, PosY, LineHeight, Rows, CodeCount: Integer;
  FontItem: TUtftFont;
begin
  FView.Canvas.Font := FView.Font;
  LineHeight := FView.Canvas.TextHeight('Wg') + 2;
  FHeadFontHeight := LineHeight;
  PosY := FvItemGap div 2;
  for Index := 0 to FShown.Count - 1 do
  begin
    FontItem := TUtftFont(FShown[Index]);
    FreeAndNil(FontItem.Bitmap);
    FontItem.Top := PosY;
    if FontItem.IsFont then
    begin
      UtftSetSample(FontItem, FSampleText);
      CodeCount := Length(FontItem.SampleCodes);
      Rows := (CodeCount + FontItem.SampleCols - 1) div FontItem.SampleCols;
      FontItem.SampleTop := 2 * LineHeight + 4;
      if FontItem.Note <> '' then
        Inc(FontItem.SampleTop, LineHeight);
      FontItem.Height := FontItem.SampleTop + Rows * FontItem.SizeY;
    end
    else
    begin
      SetLength(FontItem.SampleCodes, 0);
      FontItem.SampleTop := 0;
      FontItem.SampleCols := 0;
      FontItem.Height := 2 * LineHeight;
    end;
    Inc(PosY, FontItem.Height + FvItemGap);
  end;
  FContentHeight := PosY;
  UpdateScroll;
  FView.Invalidate;
end;

procedure TDlgFontViewer.UpdateScroll;
var
  Page, MaxPos: Integer;
begin
  Page := FView.ClientHeight;
  if Page < 1 then
    Page := 1;
  MaxPos := FContentHeight - Page;
  if MaxPos < 0 then
    MaxPos := 0;
  if FTopPos > MaxPos then
    FTopPos := MaxPos;
  FScrollBar.LargeChange := Page;
  FScrollBar.Max := MaxPos;
  FScrollBar.Position := FTopPos;
  FScrollBar.Enabled := MaxPos > 0;
end;

procedure TDlgFontViewer.ScrollTo(APos: Integer);
begin
  if APos > FScrollBar.Max then
    APos := FScrollBar.Max;
  if APos < 0 then
    APos := 0;
  if APos = FTopPos then
    Exit;
  FTopPos := APos;
  FScrollBar.Position := APos;
  FView.Invalidate;
end;

procedure TDlgFontViewer.ScrollChange(Sender: TObject);
begin
  if FScrollBar.Position <> FTopPos then
  begin
    FTopPos := FScrollBar.Position;
    FView.Invalidate;
  end;
end;

procedure TDlgFontViewer.ViewResize(Sender: TObject);
begin
  UpdateScroll;
end;

procedure TDlgFontViewer.EnsureVisible(AIndex: Integer);
var
  FontItem: TUtftFont;
begin
  if (AIndex < 0) or (AIndex >= FShown.Count) then
    Exit;
  FontItem := TUtftFont(FShown[AIndex]);
  if FontItem.Top < FTopPos then
    ScrollTo(FontItem.Top - FvItemGap div 2)
  else if FontItem.Top + FontItem.Height > FTopPos + FView.ClientHeight then
  begin
    if FontItem.Height + FvItemGap > FView.ClientHeight then
      ScrollTo(FontItem.Top - FvItemGap div 2)
    else
      ScrollTo(FontItem.Top + FontItem.Height + FvItemGap div 2 - FView.ClientHeight);
  end;
end;


procedure TDlgFontViewer.PaintView(ACanvas: TCanvas; const AClip: TRect);
var
  Index, PosY, LineHeight, LastCode: Integer;
  FontItem: TUtftFont;
  BackColor, TextColor, DimColor, HotBack, HotText: TColor;
  HeadRect: TRect;
  Info: string;
begin
  BackColor := UiThemeColor('List.BG');
  TextColor := UiThemeColor('List.Text');
  DimColor := UiThemeColor('OffText');
  HotBack := UiThemeColor('Menu.HotBG');
  HotText := UiThemeColor('Menu.HotText');
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := BackColor;
  ACanvas.FillRect(AClip);
  ACanvas.Font := FView.Font;
  LineHeight := FHeadFontHeight;

  if FShown.Count = 0 then
  begin
    ACanvas.Font.Color := DimColor;
    if FFonts.Count > 0 then
      ACanvas.TextOut(FvGap, FvGap, 'Все шрифты скрыты: Вид - Скрыть')
    else if FSourceText = '' then
      ACanvas.TextOut(FvGap, FvGap, 'Файл - Открыть файл... или Открыть папку...')
    else
      ACanvas.TextOut(FvGap, FvGap, 'Массивов в .c-файлах не найдено');
    Exit;
  end;

  for Index := 0 to FShown.Count - 1 do
  begin
    FontItem := TUtftFont(FShown[Index]);
    PosY := FontItem.Top - FTopPos;
    if PosY + FontItem.Height < AClip.Top then
      Continue;
    if PosY > AClip.Bottom then
      Break;

    // Заголовок: имя массива и файл; выбранный шрифт - цветом выделения
    HeadRect := Rect(0, PosY - 2, FontViewWidth, PosY + LineHeight);
    if Index = FSelected then
    begin
      ACanvas.Brush.Color := HotBack;
      ACanvas.FillRect(HeadRect);
      ACanvas.Font.Color := HotText;
    end
    else
    begin
      ACanvas.Brush.Color := BackColor;
      ACanvas.Font.Color := TextColor;
    end;
    ACanvas.Font.Style := [fsBold];
    ACanvas.TextOut(FvGap, PosY, FontItem.Name);
    ACanvas.Font.Style := [];
    Info := ExtractFileName(FontItem.FileName);
    if Index <> FSelected then
      ACanvas.Font.Color := DimColor;
    ACanvas.TextOut(FontViewWidth - FvGap - ACanvas.TextWidth(Info), PosY, Info);

    ACanvas.Brush.Color := BackColor;
    if FontItem.IsFont then
    begin
      LastCode := FontItem.FirstChar + FontItem.CharCount - 1;
      Info := Format('%d x %d точек, символы %d..%d ($%.2x..$%.2x), %d шт., ' +
        '%d байт', [FontItem.SizeX, FontItem.SizeY, FontItem.FirstChar, LastCode,
        FontItem.FirstChar, LastCode, FontItem.CharCount, Length(FontItem.Data)]);
      ACanvas.Font.Color := TextColor;
      ACanvas.TextOut(FvGap, PosY + LineHeight, Info);
      if FontItem.Note <> '' then
      begin
        ACanvas.Font.Color := DimColor;
        ACanvas.TextOut(FvGap, PosY + 2 * LineHeight, FontItem.Note);
      end;
      if Length(FontItem.SampleCodes) > 0 then
      begin
        if FontItem.Bitmap = nil then
          FontItem.Bitmap := UtftMakeSample(FontItem, FShowCells);
        if FontItem.Bitmap.Height > 0 then
          ACanvas.Draw(0, PosY + FontItem.SampleTop, FontItem.Bitmap);
      end;
    end
    else
    begin
      ACanvas.Font.Color := $000000C0;
      if IsDarkColorValue(BackColor) then
        ACanvas.Font.Color := $006060FF;
      ACanvas.TextOut(FvGap, PosY + LineHeight, 'Не шрифт: ' + FontItem.Problem);
    end;
  end;
end;

function TDlgFontViewer.FontAt(PosY: Integer): Integer;
var
  Index, ContentY: Integer;
  FontItem: TUtftFont;
begin
  Result := -1;
  ContentY := PosY + FTopPos;
  for Index := 0 to FShown.Count - 1 do
  begin
    FontItem := TUtftFont(FShown[Index]);
    if (ContentY >= FontItem.Top - FvItemGap div 2) and
       (ContentY < FontItem.Top + FontItem.Height + FvItemGap div 2) then
    begin
      Result := Index;
      Exit;
    end;
  end;
end;

// Код символа образца под точкой окна; -1 - не на образце
function TDlgFontViewer.CodeAt(AFont: TUtftFont; PosX, PosY: Integer): Integer;
var
  LocalY, Col, Row, CodeIdx: Integer;
begin
  Result := -1;
  if not AFont.IsFont or (AFont.SampleCols = 0) then
    Exit;
  LocalY := PosY + FTopPos - AFont.Top - AFont.SampleTop;
  if (LocalY < 0) or (PosX < 0) then
    Exit;
  Col := PosX div AFont.SizeX;
  Row := LocalY div AFont.SizeY;
  if Col >= AFont.SampleCols then
    Exit;
  CodeIdx := Row * AFont.SampleCols + Col;
  if CodeIdx <= High(AFont.SampleCodes) then
    Result := AFont.SampleCodes[CodeIdx];
end;

procedure TDlgFontViewer.ViewMouseDown(PosX, PosY: Integer);
var
  Index: Integer;
begin
  Index := FontAt(PosY);
  FClickCode := -1;
  if Index >= 0 then
    FClickCode := CodeAt(TUtftFont(FShown[Index]), PosX, PosY);
  if Index <> FSelected then
  begin
    FSelected := Index;
    FView.Invalidate;
    UpdateStatus;
  end;
end;

procedure TDlgFontViewer.ViewMouseMove(PosX, PosY: Integer);
var
  Index, Code: Integer;
  FontItem: TUtftFont;
  Text, CharText: string;
begin
  Text := '';
  Index := FontAt(PosY);
  if Index >= 0 then
  begin
    FontItem := TUtftFont(FShown[Index]);
    Code := CodeAt(FontItem, PosX, PosY);
    if Code >= 0 then
    begin
      if (Code >= 32) and (Code < 127) then
        CharText := ' ''' + Chr(Code) + ''''
      else
        CharText := '';
      Text := Format('%s: символ %d ($%.2x)%s', [FontItem.Name, Code, Code, CharText]);
      if FontItem.GlyphOffset(Code) < 0 then
        Text := Text + ' - нет в шрифте'
      else
        Text := Text + Format(', номер %d в таблице', [Code - FontItem.FirstChar]);
    end;
  end;
  if FHoverLabel.Caption <> Text then
    FHoverLabel.Caption := Text;
end;

procedure TDlgFontViewer.ViewDblClick;
begin
  MenuOpenInEditorClick(nil);
end;

procedure TDlgFontViewer.UpdateStatus;
var
  Index, FontCount: Integer;
  Text: string;
begin
  FontCount := 0;
  for Index := 0 to FFonts.Count - 1 do
    if TUtftFont(FFonts[Index]).IsFont then
      Inc(FontCount);
  if FSourceText = '' then
    Caption := 'Font Viewer (UTFT)'
  else
    Caption := 'Font Viewer (UTFT) - ' + FSourceText;
  if FSourceText = '' then
    Text := 'Ничего не открыто'
  else
  begin
    Text := Format('Файлов .c: %d, шрифтов: %d', [FFileCount, FontCount]);
    if FFonts.Count > FontCount then
      Text := Text + Format(', не шрифты: %d', [FFonts.Count - FontCount]);
    if FShown.Count < FFonts.Count then
      Text := Text + Format(', скрыто: %d', [FFonts.Count - FShown.Count]);
  end;
  if (FSelected >= 0) and (FSelected < FShown.Count) then
    Text := Text + '; выбран ' + TUtftFont(FShown[FSelected]).Name;
  FStatusLabel.Caption := Text;
  FMiOpenInEditor.Enabled := Assigned(FOnOpenFile) and (FSelected >= 0);
  FMiMakeFont.Enabled := Assigned(FOnMakeFont);
end;

procedure TDlgFontViewer.UpdateColors;
begin
  Color := UiThemeColor('Window.BG');
  Font.Color := UiThemeColor('Window.Text');
  FView.Color := UiThemeColor('List.BG');
end;

// ---------------------------------------------------------------------------
//  Меню
// ---------------------------------------------------------------------------

procedure TDlgFontViewer.MenuOpenFileClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(Self);
  try
    OpenDlg.Title := 'Шрифты UTFT';
    OpenDlg.Filter := 'Шрифты UTFT (*.c)|*.c|Все файлы (*.*)|*.*';
    OpenDlg.Options := [ofFileMustExist, ofHideReadOnly, ofEnableSizing,
      ofAllowMultiSelect];
    if FFolder <> '' then
      OpenDlg.InitialDir := FFolder
    else if FFiles.Count > 0 then
      OpenDlg.InitialDir := ExtractFileDir(FFiles[0])
    else
      OpenDlg.InitialDir := FDefaultFolder;
    if OpenDlg.Execute then
      OpenFiles(OpenDlg.Files);
  finally
    OpenDlg.Free;
  end;
end;

procedure TDlgFontViewer.MenuOpenFolderClick(Sender: TObject);
var
  Folder: string;
begin
  Folder := FFolder;
  if (Folder = '') and (FFiles.Count > 0) then
    Folder := ExtractFileDir(FFiles[0]);
  if Folder = '' then
    Folder := FDefaultFolder;
  if BrowseFolderDialog('Папка со шрифтами UTFT (*.c)', Folder) then
    OpenFolder(Folder);
end;

procedure TDlgFontViewer.MenuReloadClick(Sender: TObject);
var
  Files: TStringList;
begin
  if FFolder <> '' then
    OpenFolder(FFolder)
  else if FFiles.Count > 0 then
  begin
    Files := TStringList.Create;
    try
      Files.Assign(FFiles);
      OpenFiles(Files);
    finally
      Files.Free;
    end;
  end;
end;

procedure TDlgFontViewer.MenuOpenInEditorClick(Sender: TObject);
begin
  if (FSelected < 0) or (FSelected >= FShown.Count) or
     not Assigned(FOnOpenFile) then
    Exit;
  FOnOpenFile(TUtftFont(FShown[FSelected]).FileName);
end;

procedure TDlgFontViewer.MenuCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TDlgFontViewer.MenuMakeFontClick(Sender: TObject);
begin
  if Assigned(FOnMakeFont) then
    FOnMakeFont(Self);
end;

procedure TDlgFontViewer.MenuCopyNameClick(Sender: TObject);
begin
  if (FSelected >= 0) and (FSelected < FShown.Count) then
    Clipboard.AsText := TUtftFont(FShown[FSelected]).Name;
end;

procedure TDlgFontViewer.MenuCopyExternClick(Sender: TObject);
begin
  if (FSelected >= 0) and (FSelected < FShown.Count) then
    Clipboard.AsText := 'extern uint8_t ' + TUtftFont(FShown[FSelected]).Name + '[];';
end;

procedure TDlgFontViewer.MenuEditFontClick(Sender: TObject);
var
  FontItem: TUtftFont;
begin
  if (FSelected < 0) or (FSelected >= FShown.Count) then
  begin
    MessageDlg('Выберите шрифт щелчком в списке', mtInformation, [mbOK], 0);
    Exit;
  end;
  FontItem := TUtftFont(FShown[FSelected]);
  if not FontItem.IsFont then
  begin
    MessageDlg(FontItem.Name + ' - не шрифт: ' + FontItem.Problem,
      mtInformation, [mbOK], 0);
    Exit;
  end;
  EditUtftFont(Self, FontItem, FClickCode, FontSaved);
end;

// Редактор записал шрифт: показать файл в списке и выбрать его
procedure TDlgFontViewer.FontSaved(const AFileName: string);
var
  Files: TStringList;
  Index: Integer;
begin
  if (FFolder <> '') and SameText(ExtractFileDir(ExpandFileName(AFileName)),
     ExpandFileName(FFolder)) then
    OpenFolder(FFolder)
  else
  begin
    Files := TStringList.Create;
    try
      if FFolder = '' then
        Files.Assign(FFiles);
      if Files.IndexOf(AFileName) < 0 then
        Files.Add(AFileName);
      OpenFiles(Files);
    finally
      Files.Free;
    end;
  end;
  for Index := 0 to FShown.Count - 1 do
    if SameText(TUtftFont(FShown[Index]).FileName, AFileName) then
    begin
      FSelected := Index;
      EnsureVisible(Index);
      Break;
    end;
  FView.Invalidate;
  UpdateStatus;
end;

procedure TDlgFontViewer.MenuAllCharsClick(Sender: TObject);
begin
  FMiAllChars.Checked := True;
  if FSampleText = '' then
    Exit;
  FSampleText := '';
  Relayout;
end;

procedure TDlgFontViewer.MenuSampleTextClick(Sender: TObject);
var
  Text: string;
begin
  Text := FSampleText;
  if Text = '' then
    Text := '0123456789 RPM 1500';
  if not InputQuery('Текст образца', 'Текст (пусто - все символы шрифта):', Text) then
    Exit;
  FSampleText := Text;
  FMiSampleText.Checked := FSampleText <> '';
  FMiAllChars.Checked := FSampleText = '';
  Relayout;
end;

procedure TDlgFontViewer.MenuCellsClick(Sender: TObject);
begin
  FShowCells := not FShowCells;
  FMiCells.Checked := FShowCells;
  Relayout;
end;

procedure TDlgFontViewer.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  Page: Integer;
begin
  Page := FView.ClientHeight - FHeadFontHeight;
  if Page < 16 then
    Page := 16;
  case Key of
    VK_UP:
      if ssCtrl in Shift then
        ScrollTo(FTopPos - FScrollBar.SmallChange)
      else if FSelected > 0 then
      begin
        FSelected := FSelected - 1;
        EnsureVisible(FSelected);
        FView.Invalidate;
        UpdateStatus;
      end;
    VK_DOWN:
      if ssCtrl in Shift then
        ScrollTo(FTopPos + FScrollBar.SmallChange)
      else if FSelected < FShown.Count - 1 then
      begin
        FSelected := FSelected + 1;
        EnsureVisible(FSelected);
        FView.Invalidate;
        UpdateStatus;
      end;
    VK_PRIOR: ScrollTo(FTopPos - Page);
    VK_NEXT: ScrollTo(FTopPos + Page);
    VK_HOME: ScrollTo(0);
    VK_END: ScrollTo(FContentHeight);
  else
    Exit;
  end;
  Key := 0;
end;

procedure TDlgFontViewer.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  ScrollTo(FTopPos - WheelDelta * 3 * FScrollBar.SmallChange div 120);
  Handled := True;
end;

procedure TDlgFontViewer.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SavePlacement;
  Action := caFree;
end;

procedure TDlgFontViewer.UMUiThemeChanged(var Message: TMessage);
begin
  UpdateColors;
  FView.Invalidate;
  Message.Result := 1;
end;

// ---------------------------------------------------------------------------
//  Положение окна, папка, текст образца
// ---------------------------------------------------------------------------

procedure TDlgFontViewer.SetPlacementIni(const AIniFile, ADefaultFolder: string);
begin
  FIniFile := AIniFile;
  FDefaultFolder := ADefaultFolder;
  LoadPlacement;
end;

procedure TDlgFontViewer.LoadPlacement;
var
  Ini: TBufIniFile;
  WinLeft, WinTop, WinHeight, Group: Integer;
  Folder: string;
  Work: TRect;
begin
  Folder := '';
  if (FIniFile <> '') and FileExists(FIniFile) then
  begin
    Ini := TBufIniFile.Create(FIniFile);
    try
      WinHeight := Ini.ReadInteger(FvSection, 'Height', 0);
      if WinHeight >= Constraints.MinHeight then
      begin
        WinLeft := Ini.ReadInteger(FvSection, 'Left', Left);
        WinTop := Ini.ReadInteger(FvSection, 'Top', Top);
        Work := Screen.DesktopRect;
        if WinHeight > Work.Bottom - Work.Top then
          WinHeight := Work.Bottom - Work.Top;
        if WinLeft + Width > Work.Right then
          WinLeft := Work.Right - Width;
        if WinTop + WinHeight > Work.Bottom then
          WinTop := Work.Bottom - WinHeight;
        if WinLeft < Work.Left then
          WinLeft := Work.Left;
        if WinTop < Work.Top then
          WinTop := Work.Top;
        SetBounds(WinLeft, WinTop, Width, WinHeight);
      end;
      Folder := Ini.ReadString(FvSection, 'Folder', '');
      FSampleText := Ini.ReadString(FvSection, 'SampleText', '');
      FShowCells := Ini.ReadBool(FvSection, 'Cells', False);
      FSortBySize := Ini.ReadBool(FvSection, 'SortBySize', False);
      FHideMask := Ini.ReadInteger(FvSection, 'Hide', 0);
    finally
      Ini.Free;
    end;
  end;
  FMiCells.Checked := FShowCells;
  FMiSortName.Checked := not FSortBySize;
  FMiSortSize.Checked := FSortBySize;
  for Group := 0 to FvGroupCount - 1 do
    FMiHide[Group].Checked := (FHideMask and (1 shl Group)) <> 0;
  FMiSampleText.Checked := FSampleText <> '';
  FMiAllChars.Checked := FSampleText = '';
  if (Folder = '') or not DirectoryExists(Folder) then
    Folder := FDefaultFolder;
  if (Folder <> '') and DirectoryExists(Folder) then
    OpenFolder(Folder)
  else
  begin
    Relayout;
    UpdateStatus;
  end;
end;

procedure TDlgFontViewer.SavePlacement;
var
  Ini: TBufIniFile;
  Place: TWindowPlacement;
  Folder: string;
begin
  FPlaceSaved := True;
  if (FIniFile = '') or not HandleAllocated then
    Exit;
  Place.length := SizeOf(Place);
  if not GetWindowPlacement(Handle, @Place) then
    Exit;
  Folder := FFolder;
  if (Folder = '') and (FFiles.Count > 0) then
    Folder := ExtractFileDir(FFiles[0]);
  Ini := TBufIniFile.Create(FIniFile);
  try
    Ini.WriteInteger(FvSection, 'Left', Place.rcNormalPosition.Left);
    Ini.WriteInteger(FvSection, 'Top', Place.rcNormalPosition.Top);
    Ini.WriteInteger(FvSection, 'Height', Place.rcNormalPosition.Bottom -
      Place.rcNormalPosition.Top);
    Ini.WriteString(FvSection, 'Folder', Folder);
    Ini.WriteString(FvSection, 'SampleText', FSampleText);
    Ini.WriteBool(FvSection, 'Cells', FShowCells);
    Ini.WriteBool(FvSection, 'SortBySize', FSortBySize);
    Ini.WriteInteger(FvSection, 'Hide', FHideMask);
  finally
    Ini.Free;
  end;
end;

end.
