unit DsgIcons;

// ---------------------------------------------------------------------------
//  Значки палитры компонентов - сглаженные, рисуются кодом
//
//  Значки Delphi (Bin\dcl*.bpl) - пиксельные картинки 24x24 в 16 цветах, и
//  в тёмной теме их приходилось перекрашивать по точкам. Здесь у каждого
//  компонента палитры Delphi свой значок, нарисованный простыми фигурами по
//  образцу значка Delphi. Сглаживание - в DsgPalette (DsgDrawSmoothIcon):
//  значок рисуется в 4 раза крупнее и усредняется.
//
//  Значок - строка команд через ';', координаты - в точках значка 24x24
//  (дробные можно), ось Y вниз. Чёрное - значок, белое - пусто:
//    F x1 y1 x2 y2         - закрашенный прямоугольник
//    E x1 y1 x2 y2         - стереть прямоугольник (белым)
//    R x1 y1 x2 y2 [w]     - рамка толщиной w (1) внутрь от края
//    O x1 y1 x2 y2 r [w]   - рамка со скруглёнными углами радиуса r
//    L x1 y1 x2 y2 [w]     - линия толщиной w (1)
//    C cx cy r [w]         - окружность: кольцо внешнего радиуса r
//    D cx cy r             - круг; K cx cy r - стереть круг
//    P x1 y1 x2 y2 ...     - закрашенный многоугольник; Q - стереть
//    T x y h B|N текст     - текст Arial высотой h, B - жирный
//    @ RRGGBB              - дальше рисовать этим цветом (папка, стекло
//                            лупы, цветные квадраты); "@" без цвета -
//                            снова чёрным, то есть цветом значка
//  Скрипты сгенерированы из icons.py (icons\palette, превью - render.py).
//
//  Свои значки - без пересборки: файл palette_icons.txt рядом с программой,
//  строки "Класс=скрипт" (строка с // в начале - комментарий). Скрипт из
//  файла заменяет встроенный, можно дать значок и классу без встроенного.
//  Файл пишет окно значков (DlgIconEdit, View - Palette Icons).
// ---------------------------------------------------------------------------

interface

uses
  Windows, SysUtils, Classes, Graphics;

const
  DsgIconScale = 4;   // во сколько раз крупнее рисуется значок

// Скрипт значка класса AClass ('' - своего значка нет). Свои компоненты
// TUiX - значок TX (TUiButton - TButton) с меткой, которую ставит палитра.
function DsgIconScript(const AClass: string): string;

// Файл своих значков: palette_icons.txt рядом с программой
function DsgIconUserFile: string;

// Встроенный скрипт значка AName (без своих), '' - нет
function DsgIconBuiltin(const AName: string): string;

// Свой скрипт значка AName из файла, '' - нет
function DsgIconUser(const AName: string): string;

// Свой скрипт значка AName. AScript = '' - свой убирается, снова
// встроенный. В файл - DsgIconSaveUser.
procedure DsgIconSetUser(const AName, AScript: string);

// Записать свои скрипты в файл. False - не записался, причина - AError.
function DsgIconSaveUser(var AError: string): Boolean;

// Имена значков: встроенные по порядку, потом свои, у которых встроенного
// нет
procedure DsgIconNames(AList: TStrings);

// Нарисовать значок по скрипту на холсте размера 24 * DsgIconScale:
// холст заливается белым, значок - чёрным, части с командой @ - своим
// цветом. При уменьшении чёрное становится цветом значка темы, белое -
// фоном, остальное остаётся как есть (DsgDrawSmoothIcon).
procedure DsgPaintIcon(ACanvas: TCanvas; const AScript: string);

implementation

type
  TDsgIconDef = record
    Name: string;
    Script: string;
  end;

const
  DsgIconDefs: array[0..91] of TDsgIconDef = (
    (Name: 'Arrow';
     Script: 'P 7 3 7 19.5 10.6 16 13.4 21.4 15.7 20.3 12.9 14.8 17.8 14.8'),
    (Name: 'TMainMenu';
     Script: 'R 2 3 22 21;L 2 7.5 22 7.5;F 4 4.8 7.5 5.8;F 9.5 4.8 13 5.8;F 15 4.8 18.5 5.8;R 9 7 18 17;L 11 10.5 16 10.5;L 11 13.5 16 13.5'),
    (Name: 'TPopupMenu';
     Script: 'R 8 5 22 21;L 10.5 9 19.5 9;L 10.5 13 19.5 13;L 10.5 17 19.5 17;P 2 2 2 11.5 4.3 9.3 6 12.8 7.4 12.1 5.7 8.7 8.8 8.7'),
    (Name: 'TLabel';
     Script: 'T 4.6 1.5 20 B A'),
    (Name: 'TEdit';
     Script: 'R 2 6 22 18;T 3.6 6.8 9.5 B ab;L 18.6 8 18.6 16;L 17.4 8 19.8 8;L 17.4 16 19.8 16'),
    (Name: 'TMemo';
     Script: 'R 3 2 21 22;L 6 6 18 6;L 6 10 18 10;L 6 14 18 14;L 6 18 14 18'),
    (Name: 'TButton';
     Script: 'O 2 6 22 18 3;T 6.3 7.3 8.5 B OK'),
    (Name: 'TCheckBox';
     Script: 'R 5 5 19 19;L 7.8 12.3 10.8 15.3 1.8;L 10.8 15.3 16.4 8.6 1.8'),
    (Name: 'TRadioButton';
     Script: 'C 12 12 7.5 1;D 12 12 3.2'),
    (Name: 'TListBox';
     Script: 'R 2 2 22 22;L 4.5 6 14.5 6;F 3 9 17 12.5;L 4.5 16 14.5 16;L 4.5 19.5 14.5 19.5;L 17 2 17 22;F 18.3 4.5 20.7 10'),
    (Name: 'TComboBox';
     Script: 'R 2 7 22 17;L 16 7 16 17;P 17.5 10.5 20.5 10.5 19 13;L 4.5 12 13 12'),
    (Name: 'TScrollBar';
     Script: 'R 2 8 22 16;L 7 8 7 16;L 17 8 17 16;P 5.6 10 5.6 14 3.6 12;P 18.4 10 18.4 14 20.4 12;F 9.5 10 13.5 14'),
    (Name: 'TGroupBox';
     Script: 'R 2 6 22 21;E 4 5 13 8;F 5 5.6 12 7'),
    (Name: 'TRadioGroup';
     Script: 'R 2 4 22 22;E 4 3 13 6;F 5 3.6 12 5;C 7 11 2.4 0.9;D 7 11 1;C 7 17 2.4 0.9;L 11 11 19 11;L 11 17 19 17'),
    (Name: 'TPanel';
     Script: 'R 2 5 22 19 1.4;L 5 8 19 8'),
    (Name: 'TActionList';
     Script: 'R 3 3 21 21;D 7 8 1.3;L 10 8 18 8;D 7 12 1.3;L 10 12 18 12;D 7 16 1.3;L 10 16 18 16'),
    (Name: 'TBitBtn';
     Script: 'O 2 6 22 18 3;@ 40B050;L 4.8 12 6.8 14 1.5;L 6.8 14 9.8 9.6 1.5;@;T 11.3 7.6 7.5 B OK'),
    (Name: 'TSpeedButton';
     Script: 'O 4 4 20 20 3;P 9.5 8 9.5 16 16 12'),
    (Name: 'TMaskEdit';
     Script: 'R 2 6 22 18;T 3.8 7.3 8.5 B #-#'),
    (Name: 'TStringGrid';
     Script: 'R 2 3 22 21;L 2 8 22 8 1.6;L 9 3 9 21 1.6;L 15.5 3 15.5 21;L 2 14.5 22 14.5;L 10.5 11.3 14 11.3;L 17 11.3 20.5 11.3;L 10.5 18 14 18;L 17 18 20.5 18'),
    (Name: 'TDrawGrid';
     Script: 'R 2 3 22 21;L 2 8 22 8 1.6;L 9 3 9 21 1.6;L 15.5 3 15.5 21;L 2 14.5 22 14.5;D 12.3 11.3 1.5;F 17.3 9.8 20.3 12.8;P 10.6 19.5 14 19.5 12.3 16.3;C 18.8 17.9 1.7 0.8'),
    (Name: 'TImage';
     Script: 'R 2 4 22 20;@ 40B050;P 4 18 9 11 12.5 15 15.5 12 20 18;@;@ E8B830;D 16.5 8 1.8;@'),
    (Name: 'TShape';
     Script: 'R 3 3 13.5 13.5;C 15 15 6.5 1'),
    (Name: 'TBevel';
     Script: 'R 2 4 22 20 0.7;R 4.5 6.5 19.5 17.5 0.7'),
    (Name: 'TScrollBox';
     Script: 'R 2 2 22 22;L 18 2 18 22;L 2 18 18 18;F 19.2 4 20.8 10;F 4 19.2 10 20.8;R 5 5 14 14 0.8'),
    (Name: 'TCheckListBox';
     Script: 'R 2 2 22 22;R 4 4.5 8 8.5 0.8;L 10 6.5 19 6.5;R 4 10.5 8 14.5 0.8;F 5.2 11.7 6.8 13.3;L 10 12.5 19 12.5;R 4 16.5 8 20.5 0.8;L 10 18.5 19 18.5'),
    (Name: 'TSplitter';
     Script: 'R 2 4 9 20;R 15 4 22 20;P 9.4 12 11.6 9.8 11.6 14.2;P 14.6 12 12.4 9.8 12.4 14.2'),
    (Name: 'TStaticText';
     Script: 'R 2 6 22 18 0.8;T 4.3 6.6 10 B Ab'),
    (Name: 'TControlBar';
     Script: 'R 2 3 22 21;R 4 5 20 11 0.8;R 4 13 20 19 0.8;L 6.2 6.5 6.2 9.5 0.8;L 7.6 6.5 7.6 9.5 0.8;L 6.2 14.5 6.2 17.5 0.8;L 7.6 14.5 7.6 17.5 0.8'),
    (Name: 'TApplicationEvents';
     Script: '@ E8B830;P 14 2 6 13.5 11 13.5 9 22 18 9.5 13 9.5 15.5 2;@'),
    (Name: 'TValueListEditor';
     Script: 'R 2 3 22 21;F 2 3 22 7.5;L 10 3 10 21;L 2 12 22 12;L 2 16.5 22 16.5'),
    (Name: 'TLabeledEdit';
     Script: 'T 3 0.5 9 B A;R 2 11 22 21;L 4.5 16 13 16'),
    (Name: 'TColorBox';
     Script: 'R 2 7 22 17;L 16 7 16 17;P 17.5 10.5 20.5 10.5 19 13;@ E04040;F 4 9 13 15;@'),
    (Name: 'TActionManager';
     Script: 'R 2 2 22 22 0.8;@ E8B830;P 13.5 4 7.5 13.5 11.5 13.5 10 20 16.5 10.5 12.5 10.5 14.5 4;@'),
    (Name: 'TActionMainMenuBar';
     Script: 'R 2 8 22 16;F 4 11 8 13;F 10 11 14 13;F 16 11 20 13'),
    (Name: 'TActionToolBar';
     Script: 'R 2 7 22 17;R 4 9 8.7 15 0.8;R 9.7 9 14.3 15 0.8;R 15.3 9 20 15 0.8'),
    (Name: 'TXPColorMap';
     Script: '@ 4080E0;F 3 3 11 11;@;R 13 3 21 11;R 3 13 11 21;@ E8B830;F 13 13 21 21;@'),
    (Name: 'TStandardColorMap';
     Script: 'R 3 3 21 21;L 9 3 9 21;L 15 3 15 21;L 3 9 21 9;L 3 15 21 15;@ E04040;F 3 3 9 9;@;@ 40B050;F 15 9 21 15;@;@ 4080E0;F 9 15 15 21;@'),
    (Name: 'TTwilightColorMap';
     Script: 'R 3 3 21 21;P 3 21 21 3 21 21'),
    (Name: 'TCustomizeDlg';
     Script: 'R 2 3 22 21;L 2 7 22 7;@ 40B050;L 6 13.5 9 16.5 1.6;L 9 16.5 15.5 10 1.6;@'),
    (Name: 'TTabControl';
     Script: 'R 2 8 22 21;R 2 4 9 9;R 9 5.5 15.5 8.6;E 3 7.8 8 9.3'),
    (Name: 'TPageControl';
     Script: 'R 2 8 22 21;R 2 4 9 9;R 9 5.5 15.5 8.6;E 3 7.8 8 9.3;L 5 13 18 13;L 5 17 15 17'),
    (Name: 'TImageList';
     Script: 'R 8 2 22 15;E 4.6 5.6 19.4 19.4;R 5 5 19 18;E 1.6 8.6 16.4 22.4;R 2 8 16 21;@ 40B050;P 3.5 19.5 6.8 15 9.5 17.8 11.5 15.8 14.5 19.5;@;@ E8B830;D 12 11.5 1.3;@'),
    (Name: 'TRichEdit';
     Script: 'R 3 2 21 22;@ E04040;T 5 2.8 8 B A;@;L 11.5 6.5 18 6.5;L 6 11 18 11 1.8;L 6 15 18 15;L 6 18.7 14 18.7'),
    (Name: 'TTrackBar';
     Script: 'L 3 11 21 11;L 4 15 4 18;L 8 15 8 17;L 12 15 12 18;L 16 15 16 17;L 20 15 20 18;P 9.8 6 14.2 6 14.2 12 12 14.2 9.8 12'),
    (Name: 'TProgressBar';
     Script: 'R 2 8 22 16;@ 40B050;F 4 10 7 14;F 8 10 11 14;F 12 10 15 14;@'),
    (Name: 'TUpDown';
     Script: 'R 7 2 17 22;L 7 12 17 12;P 9.5 9 14.5 9 12 5;P 9.5 15 14.5 15 12 19'),
    (Name: 'THotKey';
     Script: 'R 2 6 22 18;T 3.4 8.2 6.5 B Ctrl'),
    (Name: 'TAnimate';
     Script: 'R 3 2 21 22;L 7 2 7 22;L 17 2 17 22;F 4.2 4 5.8 6;F 4.2 9 5.8 11;F 4.2 14 5.8 16;F 4.2 18.5 5.8 20.5;F 18.2 4 19.8 6;F 18.2 9 19.8 11;F 18.2 14 19.8 16;F 18.2 18.5 19.8 20.5;P 10 8.5 10 15.5 14.8 12'),
    (Name: 'TDateTimePicker';
     Script: 'R 2 7 22 17;L 16 7 16 17;P 17.5 10.5 20.5 10.5 19 13;T 3.6 8.4 7 B 31'),
    (Name: 'TMonthCalendar';
     Script: 'R 3 3 21 21;@ 4080E0;F 3 3 21 7.5;@;D 6.5 11 0.9;D 10 11 0.9;D 13.5 11 0.9;D 17 11 0.9;D 6.5 14.5 0.9;D 10 14.5 0.9;D 13.5 14.5 0.9;D 17 14.5 0.9;D 6.5 18 0.9;D 10 18 0.9;D 13.5 18 0.9'),
    (Name: 'TTreeView';
     Script: 'F 3 2.5 7 6.5;L 5 6.5 5 18;L 5 12 9 12;L 5 18 9 18;F 9 10.5 12 13.5;F 9 16.5 12 19.5;L 9 4.5 20 4.5;L 14 12 20 12;L 14 18 20 18'),
    (Name: 'TListView';
     Script: 'R 3 3 9 9;R 15 3 21 9;R 3 13 9 19;R 15 13 21 19;L 3 11 9 11 0.8;L 15 11 21 11 0.8;L 3 21 9 21 0.8;L 15 21 21 21 0.8'),
    (Name: 'THeaderControl';
     Script: 'R 2 8 22 16;L 9 8 9 16;L 16 8 16 16;L 3.8 12 7.2 12;L 10.8 12 14.2 12;L 17.8 12 20.2 12'),
    (Name: 'TStatusBar';
     Script: 'R 2 4 22 20;L 2 15 22 15;L 10 15 10 20;L 16 15 16 20'),
    (Name: 'TToolBar';
     Script: 'R 2 6 22 18;D 6.5 12 2.2;P 10.3 9.5 10.3 14.5 14.3 12;F 16 10 20 14'),
    (Name: 'TCoolBar';
     Script: 'R 2 4 22 20;L 2 12 22 12;L 4.5 6 4.5 10 0.8;L 6 6 6 10 0.8;L 4.5 14 4.5 18 0.8;L 6 14 6 18 0.8;L 9 8 19 8;L 9 16 16 16'),
    (Name: 'TPageScroller';
     Script: 'R 7 6 17 18;P 5.3 8.5 5.3 15.5 1.8 12;P 18.7 8.5 18.7 15.5 22.2 12'),
    (Name: 'TComboBoxEx';
     Script: 'R 2 7 22 17;L 16 7 16 17;P 17.5 10.5 20.5 10.5 19 13;D 6.5 12 2.3;L 10.3 12 14 12'),
    (Name: 'TTimer';
     Script: 'C 12 13.5 8.5 1.2;L 12 13.5 12 8 1.2;L 12 13.5 15.8 15.8 1.2;F 10 2.2 14 3.8;L 12 3.8 12 5'),
    (Name: 'TPaintBox';
     Script: 'R 2 4 22 20 0.8;L 6 17 14.5 8.5 1.6;P 14 7.2 17.8 3.4 19.6 5.2 15.8 9'),
    (Name: 'TOpenDialog';
     Script: 'R 2 3 22 21;L 2 7 22 7;F 5 11 19 18.5;E 6.2 12.4 17.8 17.3;@ E8B830;F 6.2 12.4 17.8 17.3;@;F 5 9.5 9.8 11'),
    (Name: 'TSaveDialog';
     Script: 'R 2 3 22 21;L 2 7 22 7;R 6.5 9 17.5 20;@ 4080E0;F 7.5 10 16.5 19;@;F 9 9 15 12.2;E 9 15 15 20;R 9 15 15 20 0.8'),
    (Name: 'TOpenPictureDialog';
     Script: 'R 2 3 22 21;L 2 7 22 7;R 5 9.5 19 19;@ 40B050;P 6.5 17.5 9.8 13.5 12.3 16 14.5 14 17.5 17.5;@;@ E8B830;D 15.5 12 1.1;@'),
    (Name: 'TSavePictureDialog';
     Script: 'R 2 3 22 21;L 2 7 22 7;R 5 9.5 15.5 19;@ 40B050;P 6.3 17.5 8.8 14.2 11 16.4 12.3 15.2 14.2 17.5;@;@ 4080E0;F 16.5 14 21 19;@;E 17.3 16.7 20.2 19'),
    (Name: 'TFontDialog';
     Script: 'R 2 3 22 21;L 2 7 22 7;@ E04040;T 5.5 8.2 11 B Aa;@'),
    (Name: 'TColorDialog';
     Script: 'R 2 3 22 21;L 2 7 22 7;@ E04040;F 5 9.5 11 14.5;@;@ 40B050;F 13 9.5 19 14.5;@;@ 4080E0;F 5 15.5 11 20;@;@ E8B830;F 13 15.5 19 20;@'),
    (Name: 'TPrintDialog';
     Script: 'R 2 3 22 21;L 2 7 22 7;R 8 9 16 13.5 0.8;R 5 13 19 18.5;L 9 16 15 16 0.8'),
    (Name: 'TPrinterSetupDialog';
     Script: 'R 2 3 22 21;L 2 7 22 7;R 8 9 16 13.5 0.8;R 5 13 19 18.5;@ 40B050;D 16.5 15.8 1.1;@'),
    (Name: 'TFindDialog';
     Script: 'R 2 3 22 21;L 2 7 22 7;@ 8CC4F0;D 11 13.5 3.3;@;C 11 13.5 4.3 1.2;L 14 16.6 18.3 20 1.8'),
    (Name: 'TReplaceDialog';
     Script: 'R 2 3 22 21;L 2 7 22 7;@ 8CC4F0;D 9 12.5 2.5;@;C 9 12.5 3.4 1;L 11.3 15 13.8 17.5 1.5;@ E04040;L 13.5 10.5 18.5 10.5 0.9;P 18 8.8 18 12.2 20.3 10.5;@'),
    (Name: 'TPageSetupDialog';
     Script: 'R 2 3 22 21;L 2 7 22 7;R 7 8.5 17 20;R 9 10.5 15 18 0.5'),
    (Name: 'TTabSet';
     Script: 'R 2 4 22 14;E 3.2 13 11.8 15;L 3 13.6 5 19 0.9;L 5 19 10 19 0.9;L 10 19 12 13.6 0.9;L 12 14 13.6 18 0.9;L 13.6 18 18.4 18 0.9;L 18.4 18 20 14 0.9'),
    (Name: 'TOutline';
     Script: 'R 3 3 8 8 0.8;L 4.5 5.5 6.5 5.5 0.8;L 5.5 4.5 5.5 6.5 0.8;L 10 5.5 20 5.5;L 5.5 8 5.5 17;L 5.5 12 9 12;L 5.5 17 9 17;L 11 12 20 12;L 11 17 20 17'),
    (Name: 'TTabbedNotebook';
     Script: 'R 2 8 22 21;R 3 4 8 8.5 0.8;R 8 4 13 8.5 0.8;R 13 4 18 8.5 0.8;L 5 13 18 13;L 5 17 15 17'),
    (Name: 'TNotebook';
     Script: 'R 7 2 21 17;E 3.6 5.6 17.4 21.4;R 3 5 17 21;L 5.5 10 14.5 10 0.8;L 5.5 13.5 14.5 13.5 0.8;L 5.5 17 12 17 0.8'),
    (Name: 'THeader';
     Script: 'R 2 8 22 16;L 11 8 11 16;L 4 12 9 12;L 13.5 12 20 12'),
    (Name: 'TFileListBox';
     Script: 'R 2 2 22 22;R 4 4.5 7.5 8.5 0.7;L 9 6.5 19 6.5;R 4 10.5 7.5 14.5 0.7;L 9 12.5 19 12.5;R 4 16.5 7.5 20.5 0.7;L 9 18.5 19 18.5'),
    (Name: 'TDirectoryListBox';
     Script: 'R 2 2 22 22;L 6 7 6 18 0.8;L 6 12 9 12 0.8;L 6 18 9 18 0.8;L 10 5.5 19 5.5;L 14.5 12 20 12;L 14.5 18 20 18;@ E8B830;F 4 4 8.5 7;F 9 10.5 13 13.5;F 9 16.5 13 19.5;@'),
    (Name: 'TDriveComboBox';
     Script: 'R 2 7 22 17;L 16 7 16 17;P 17.5 10.5 20.5 10.5 19 13;R 4 9.5 13 14.5 0.8;@ 40B050;D 11 12 0.8;@'),
    (Name: 'TFilterComboBox';
     Script: 'R 2 7 22 17;L 16 7 16 17;P 17.5 10.5 20.5 10.5 19 13;P 4.5 9 12.5 9 9.5 12 9.5 15.5 7.5 15.5 7.5 12'),
    (Name: 'TGauge';
     Script: 'C 12 15 9 1.2;E 1 15.5 23 23;L 12 15 16.5 9.5 1.4;D 12 15 1.6;L 2.5 17 21.5 17'),
    (Name: 'TColorGrid';
     Script: 'R 3 3 21 21;@ E04040;F 3 3 9 9;@;@ 40B050;F 15 3 21 9;@;@ 4080E0;F 9 9 15 15;@;@ E8B830;F 3 15 9 21;@;@ C050C0;F 15 15 21 21;@'),
    (Name: 'TSpinButton';
     Script: 'R 7 3 17 12;R 7 12 17 21;P 9.5 9.5 14.5 9.5 12 5.5;P 9.5 14.5 14.5 14.5 12 18.5'),
    (Name: 'TSpinEdit';
     Script: 'R 2 6 22 18;L 16 6 16 18;L 16 12 22 12;P 17.5 10.3 20.5 10.3 19 8;P 17.5 13.7 20.5 13.7 19 16;T 3.8 7.4 8.5 B 12'),
    (Name: 'TDirectoryOutline';
     Script: 'R 3 3 8 8 0.8;L 4.5 5.5 6.5 5.5 0.8;L 5.5 8 5.5 17;L 5.5 12 9 12;L 5.5 17 9 17;L 15.5 12 20 12;L 15.5 17 20 17;@ E8B830;F 10 4 14 7;F 10 10.5 14 13.5;F 10 15.5 14 18.5;@'),
    (Name: 'TCalendar';
     Script: 'R 2 3 22 21;L 2 8 22 8;L 7 8 7 21;L 12 8 12 21;L 17 8 17 21;L 2 12.5 22 12.5;L 2 17 22 17;@ 4080E0;F 8 4.6 16 6.4;@'),
    (Name: 'TShellTreeView';
     Script: 'R 3 3 8 6.5 0.8;L 5 6.5 5 18;L 5 12 9 12;L 5 18 9 18;R 9 10.5 14 13.8 0.8;R 9 16.5 14 19.8 0.8;F 9 9.6 11 10.5;F 9 15.6 11 16.5;L 10 4.5 20 4.5;@ E8B830;F 3.8 3.8 7.2 5.7;F 9.8 11.3 13.2 13;F 9.8 17.3' +
      ' 13.2 19;@'),
    (Name: 'TShellComboBox';
     Script: 'R 2 7 22 17;L 16 7 16 17;P 17.5 10.5 20.5 10.5 19 13;@ E8B830;F 4 10 12 14.5;F 4 9 7 10;@'),
    (Name: 'TShellListView';
     Script: 'R 3 4 10 9 0.8;F 3 3 5.5 4;R 14 4 21 9 0.8;F 14 3 16.5 4;R 3 14 10 19 0.8;F 3 13 5.5 14;R 14 14 21 19 0.8;F 14 13 16.5 14;L 3 11 10 11 0.8;L 14 11 21 11 0.8;L 3 21 10 21 0.8;L 14 21 21 21 0.8;@ E8B830' +
      ';F 3.8 4.8 9.2 8.2;F 14.8 4.8 20.2 8.2;F 3.8 14.8 9.2 18.2;F 14.8 14.8 20.2 18.2;@'),
    (Name: 'TShellChangeNotifier';
     Script: 'R 2 9 13 17;@ E8B830;F 3 10 12 16;@;F 2 7.5 6.5 9;@ E8B830;P 17 2 12.5 11.5 15.5 11.5 14 20 20.5 9 17 9 19 2;@'),
    (Name: 'TUiIconButton';
     Script: 'O 3 3 21 21 5;D 12 12 4'));

  // Свои компоненты, у которых аналог называется иначе
  DsgIconAliases: array[0..1] of TDsgIconDef = (
    (Name: 'TUiColorDialog'; Script: 'TColorDialog'),
    (Name: 'TUiFontDialog'; Script: 'TFontDialog'));

var
  UserIcons: TStringList = nil;   // свои: "Класс=скрипт"

function DsgIconUserFile: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + 'palette_icons.txt';
end;

function DsgIconUser(const AName: string): string;
var
  UserIdx: Integer;
begin
  Result := '';
  if UserIcons = nil then
    Exit;
  UserIdx := UserIcons.IndexOfName(AName);
  if UserIdx >= 0 then
    Result := Copy(UserIcons[UserIdx], Pos('=', UserIcons[UserIdx]) + 1,
                   MaxInt);
end;

procedure DsgIconSetUser(const AName, AScript: string);
var
  UserIdx: Integer;
begin
  if Trim(AName) = '' then
    Exit;
  if UserIcons = nil then
    UserIcons := TStringList.Create;
  UserIdx := UserIcons.IndexOfName(AName);
  if Trim(AScript) = '' then
  begin
    if UserIdx >= 0 then
      UserIcons.Delete(UserIdx);
  end
  else if UserIdx >= 0 then
    UserIcons[UserIdx] := AName + '=' + AScript
  else
    UserIcons.Add(AName + '=' + AScript);
end;

function DsgIconSaveUser(var AError: string): Boolean;
var
  Lines: TStringList;
  UserIdx: Integer;
begin
  Result := False;
  AError := '';
  Lines := TStringList.Create;
  try
    Lines.Add('// Свои значки палитры компонентов: Класс=скрипт (формат - в ' +
              'DsgIcons.pas).');
    Lines.Add('// Заменяют встроенные. Пишет окно View - Palette Icons.');
    if UserIcons <> nil then
      for UserIdx := 0 to UserIcons.Count - 1 do
        Lines.Add(UserIcons[UserIdx]);
    try
      Lines.SaveToFile(DsgIconUserFile);
      Result := True;
    except
      on E: Exception do
        AError := E.Message;
    end;
  finally
    Lines.Free;
  end;
end;

// Свои из файла - при запуске
procedure LoadUserIcons;
var
  Lines: TStringList;
  LineIdx, EqPos: Integer;
  Line: string;
begin
  if not FileExists(DsgIconUserFile) then
    Exit;
  Lines := TStringList.Create;
  try
    try
      Lines.LoadFromFile(DsgIconUserFile);
    except
      Exit;
    end;
    for LineIdx := 0 to Lines.Count - 1 do
    begin
      Line := Trim(Lines[LineIdx]);
      if (Line = '') or (Copy(Line, 1, 2) = '//') then
        Continue;
      EqPos := Pos('=', Line);
      if EqPos < 2 then
        Continue;
      DsgIconSetUser(Trim(Copy(Line, 1, EqPos - 1)),
                     Trim(Copy(Line, EqPos + 1, MaxInt)));
    end;
  finally
    Lines.Free;
  end;
end;

function DsgIconBuiltin(const AName: string): string;
var
  DefIdx: Integer;
begin
  Result := '';
  for DefIdx := Low(DsgIconDefs) to High(DsgIconDefs) do
    if CompareText(DsgIconDefs[DefIdx].Name, AName) = 0 then
    begin
      Result := DsgIconDefs[DefIdx].Script;
      Exit;
    end;
end;

// Свой скрипт, иначе встроенный
function FindScript(const AName: string): string;
begin
  Result := DsgIconUser(AName);
  if Result = '' then
    Result := DsgIconBuiltin(AName);
end;

procedure DsgIconNames(AList: TStrings);
var
  DefIdx, UserIdx: Integer;
  UserName: string;
begin
  AList.Clear;
  for DefIdx := Low(DsgIconDefs) to High(DsgIconDefs) do
    AList.Add(DsgIconDefs[DefIdx].Name);
  if UserIcons <> nil then
    for UserIdx := 0 to UserIcons.Count - 1 do
    begin
      UserName := UserIcons.Names[UserIdx];
      if AList.IndexOf(UserName) < 0 then
        AList.Add(UserName);
    end;
end;

function DsgIconScript(const AClass: string): string;
var
  AliasIdx: Integer;
begin
  Result := FindScript(AClass);
  if Result <> '' then
    Exit;
  for AliasIdx := Low(DsgIconAliases) to High(DsgIconAliases) do
    if CompareText(DsgIconAliases[AliasIdx].Name, AClass) = 0 then
    begin
      Result := FindScript(DsgIconAliases[AliasIdx].Script);
      Exit;
    end;
  // TUiButton -> TButton
  if CompareText(Copy(AClass, 1, 3), 'TUi') = 0 then
    Result := FindScript('T' + Copy(AClass, 4, MaxInt));
end;

// Координата значка -> точка большого холста
function Big(AValue: Double): Integer;
begin
  Result := Round(AValue * DsgIconScale);
end;

// Число из скрипта: точка - разделитель дробной части при любых
// настройках Windows (Val)
function ScriptNum(const AText: string): Double;
var
  ErrPos: Integer;
begin
  Val(AText, Result, ErrPos);
  if ErrPos <> 0 then
    Result := 0;
end;

// Слова команды через пробел
procedure SplitWords(const AText: string; AWords: TStringList);
var
  Rest: string;
  SpacePos: Integer;
begin
  AWords.Clear;
  Rest := Trim(AText);
  while Rest <> '' do
  begin
    SpacePos := Pos(' ', Rest);
    if SpacePos = 0 then
      SpacePos := Length(Rest) + 1;
    AWords.Add(Copy(Rest, 1, SpacePos - 1));
    Rest := TrimLeft(Copy(Rest, SpacePos + 1, MaxInt));
  end;
end;

procedure DsgPaintIcon(ACanvas: TCanvas; const AScript: string);
var
  Commands, Words: TStringList;
  CmdIdx, NumIdx, PointIdx, WordIdx, PointCount: Integer;
  Cmd, Op, TextPart: string;
  Nums: array of Double;
  Points: array of TPoint;
  Width, LineLen, NormX, NormY, PosX1, PosY1, PosX2, PosY2: Double;
  Outer, Inner: HRGN;
  InkBrush: HBRUSH;
  FontRec: TLogFont;
  RestPos: Integer;
  InkColor: TColor;   // текущий цвет: clBlack - цвет значка

  function Num(AIndex: Integer; ADefault: Double): Double;
  begin
    if AIndex < Length(Nums) then
      Result := Nums[AIndex]
    else
      Result := ADefault;
  end;

  procedure SetInk(AErase: Boolean);
  begin
    if AErase then
    begin
      ACanvas.Brush.Color := clWhite;
      ACanvas.Pen.Color := clWhite;
    end
    else
    begin
      ACanvas.Brush.Color := InkColor;
      ACanvas.Pen.Color := InkColor;
    end;
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Pen.Style := psSolid;
    ACanvas.Pen.Width := 1;
  end;

  procedure FillBox(AX1, AY1, AX2, AY2: Double);
  begin
    ACanvas.FillRect(Rect(Big(AX1), Big(AY1), Big(AX2), Big(AY2)));
  end;

begin
  InkColor := clBlack;
  Commands := TStringList.Create;
  Words := TStringList.Create;
  try
    SetInk(True);
    ACanvas.FillRect(Rect(0, 0, 24 * DsgIconScale, 24 * DsgIconScale));
    // Команды через ';'
    TextPart := AScript;
    while TextPart <> '' do
    begin
      RestPos := Pos(';', TextPart);
      if RestPos = 0 then
        RestPos := Length(TextPart) + 1;
      Cmd := Trim(Copy(TextPart, 1, RestPos - 1));
      if Cmd <> '' then
        Commands.Add(Cmd);
      Delete(TextPart, 1, RestPos);
    end;

    for CmdIdx := 0 to Commands.Count - 1 do
    begin
      Cmd := Commands[CmdIdx];
      Op := UpperCase(Cmd[1]);
      if Op = '@' then
      begin
        // @ RRGGBB - свой цвет; чистые чёрный и белый заняты (значок и
        // пусто), их сдвигаем на единицу
        SplitWords(Copy(Cmd, 2, MaxInt), Words);
        if Words.Count = 0 then
          InkColor := clBlack
        else
        begin
          InkColor := StrToIntDef('$' + Words[0], 0);
          InkColor := RGB((InkColor shr 16) and $FF, (InkColor shr 8) and $FF,
                          InkColor and $FF);
          if InkColor = clBlack then
            InkColor := RGB(1, 1, 1)
          else if InkColor = clWhite then
            InkColor := RGB(254, 254, 254);
        end;
        Continue;
      end;
      if Op = 'T' then
      begin
        // T x y h B|N текст
        SplitWords(Copy(Cmd, 2, MaxInt), Words);
        if Words.Count < 5 then
          Continue;
        TextPart := Trim(Copy(Cmd, 2, MaxInt));
        for WordIdx := 1 to 4 do
          TextPart := TrimLeft(Copy(TextPart, Pos(' ', TextPart) + 1, MaxInt));
        FillChar(FontRec, SizeOf(FontRec), 0);
        FontRec.lfHeight := -Big(ScriptNum(Words[2]));
        if UpperCase(Words[3]) = 'B' then
          FontRec.lfWeight := FW_BOLD
        else
          FontRec.lfWeight := FW_NORMAL;
        FontRec.lfCharSet := DEFAULT_CHARSET;
        // Без сглаживания Windows: сглаживает усреднение (ClearType дал
        // бы цветные края)
        FontRec.lfQuality := NONANTIALIASED_QUALITY;
        StrPCopy(FontRec.lfFaceName, 'Arial');
        ACanvas.Font.Handle := CreateFontIndirect(FontRec);
        ACanvas.Font.Color := InkColor;
        ACanvas.Brush.Style := bsClear;
        ACanvas.TextOut(Big(ScriptNum(Words[0])), Big(ScriptNum(Words[1])),
                        TextPart);
        ACanvas.Brush.Style := bsSolid;
        Continue;
      end;

      SplitWords(Copy(Cmd, 2, MaxInt), Words);
      SetLength(Nums, Words.Count);
      for NumIdx := 0 to Words.Count - 1 do
        Nums[NumIdx] := ScriptNum(Words[NumIdx]);

      if (Op = 'F') or (Op = 'E') then
      begin
        SetInk(Op = 'E');
        FillBox(Num(0, 0), Num(1, 0), Num(2, 0), Num(3, 0));
      end
      else if Op = 'R' then
      begin
        SetInk(False);
        Width := Num(4, 1);
        FillBox(Num(0, 0), Num(1, 0), Num(2, 0), Num(1, 0) + Width);
        FillBox(Num(0, 0), Num(3, 0) - Width, Num(2, 0), Num(3, 0));
        FillBox(Num(0, 0), Num(1, 0), Num(0, 0) + Width, Num(3, 0));
        FillBox(Num(2, 0) - Width, Num(1, 0), Num(2, 0), Num(3, 0));
      end
      else if Op = 'L' then
      begin
        SetInk(False);
        Width := Num(4, 1);
        PosX1 := Num(0, 0);
        PosY1 := Num(1, 0);
        PosX2 := Num(2, 0);
        PosY2 := Num(3, 0);
        SetLength(Points, 4);
        if PosY1 = PosY2 then
        begin
          // Горизонталь и вертикаль - прямоугольником от края до края
          Points[0] := Point(Big(PosX1), Big(PosY1 - Width / 2));
          Points[1] := Point(Big(PosX2), Big(PosY1 - Width / 2));
          Points[2] := Point(Big(PosX2), Big(PosY1 + Width / 2));
          Points[3] := Point(Big(PosX1), Big(PosY1 + Width / 2));
        end
        else if PosX1 = PosX2 then
        begin
          Points[0] := Point(Big(PosX1 - Width / 2), Big(PosY1));
          Points[1] := Point(Big(PosX1 + Width / 2), Big(PosY1));
          Points[2] := Point(Big(PosX1 + Width / 2), Big(PosY2));
          Points[3] := Point(Big(PosX1 - Width / 2), Big(PosY2));
        end
        else
        begin
          LineLen := Sqrt(Sqr(PosX2 - PosX1) + Sqr(PosY2 - PosY1));
          NormX := -(PosY2 - PosY1) / LineLen * Width / 2;
          NormY := (PosX2 - PosX1) / LineLen * Width / 2;
          Points[0] := Point(Big(PosX1 + NormX), Big(PosY1 + NormY));
          Points[1] := Point(Big(PosX2 + NormX), Big(PosY2 + NormY));
          Points[2] := Point(Big(PosX2 - NormX), Big(PosY2 - NormY));
          Points[3] := Point(Big(PosX1 - NormX), Big(PosY1 - NormY));
        end;
        ACanvas.Polygon(Points);
      end
      else if (Op = 'D') or (Op = 'K') then
      begin
        SetInk(Op = 'K');
        ACanvas.Ellipse(Big(Num(0, 0) - Num(2, 0)), Big(Num(1, 0) - Num(2, 0)),
                        Big(Num(0, 0) + Num(2, 0)), Big(Num(1, 0) + Num(2, 0)));
      end
      else if (Op = 'C') or (Op = 'O') then
      begin
        // Кольцо и скруглённая рамка - разность двух областей
        if Op = 'C' then
        begin
          Width := Num(3, 1);
          Outer := CreateEllipticRgn(
            Big(Num(0, 0) - Num(2, 0)), Big(Num(1, 0) - Num(2, 0)),
            Big(Num(0, 0) + Num(2, 0)), Big(Num(1, 0) + Num(2, 0)));
          Inner := CreateEllipticRgn(
            Big(Num(0, 0) - Num(2, 0) + Width),
            Big(Num(1, 0) - Num(2, 0) + Width),
            Big(Num(0, 0) + Num(2, 0) - Width),
            Big(Num(1, 0) + Num(2, 0) - Width));
        end
        else
        begin
          Width := Num(5, 1);
          Outer := CreateRoundRectRgn(Big(Num(0, 0)), Big(Num(1, 0)),
                                      Big(Num(2, 0)) + 1, Big(Num(3, 0)) + 1,
                                      2 * Big(Num(4, 0)), 2 * Big(Num(4, 0)));
          Inner := CreateRoundRectRgn(Big(Num(0, 0) + Width),
                                      Big(Num(1, 0) + Width),
                                      Big(Num(2, 0) - Width) + 1,
                                      Big(Num(3, 0) - Width) + 1,
                                      2 * Big(Num(4, 0) - Width),
                                      2 * Big(Num(4, 0) - Width));
        end;
        CombineRgn(Outer, Outer, Inner, RGN_DIFF);
        InkBrush := CreateSolidBrush(ColorToRGB(InkColor));
        FillRgn(ACanvas.Handle, Outer, InkBrush);
        DeleteObject(InkBrush);
        DeleteObject(Inner);
        DeleteObject(Outer);
      end
      else if (Op = 'P') or (Op = 'Q') then
      begin
        SetInk(Op = 'Q');
        PointCount := Length(Nums) div 2;
        if PointCount < 3 then
          Continue;
        SetLength(Points, PointCount);
        for PointIdx := 0 to PointCount - 1 do
          Points[PointIdx] := Point(Big(Nums[PointIdx * 2]),
                                    Big(Nums[PointIdx * 2 + 1]));
        ACanvas.Polygon(Points);
      end;
    end;
  finally
    Words.Free;
    Commands.Free;
  end;
end;

initialization
  LoadUserIcons;

finalization
  UserIcons.Free;

end.
