// unIDE, сборка под Linux: реализация вызовов WinAPI, которые использует
// программа (символы unidewin_*, объявления - Windows.pas и свои external
// в модулях unIDE). Здесь - написанные руками (через LCLIntf, где у LCL
// есть такой же вызов); остальное - заглушки winimpl_auto.inc (genimpl.py).
unit WinImpl;
{$mode delphi}{$H+}
{$calling stdcall}
interface
implementation
uses Windows, Messages, CommCtrl, ShellAPI, ActiveX, WinInet, RichEdit, ctypes,
  Types, LCLType, LCLIntf, SysUtils, Classes, Controls, BaseUnix, Unix, termio,
  UnixFonts;

// --- Через LCLIntf (тот же вызов у LCL) ---

// LCL:  function BeginPaint(Handle : hwnd; var PS : TPaintStruct)
// Поля PAINTSTRUCT у LCL другого размера (BOOL - Boolean): копия полей
function Impl_BeginPaint(hWnd:HWND; lpPaint:LPPAINTSTRUCT): HDC; stdcall; public name 'unidewin_BeginPaint';
var
  LclPs: LCLType.TPaintStruct;
begin
  FillChar(LclPs, SizeOf(LclPs), 0);
  Result := LCLIntf.BeginPaint(hWnd, LclPs);
  FillChar(lpPaint^, SizeOf(lpPaint^), 0);
  lpPaint^.hdc := LclPs.hdc;
  lpPaint^.fErase := LclPs.fErase;
  lpPaint^.rcPaint := LclPs.rcPaint;
end;

// LCL: function BitBlt(DestDC: HDC; X, Y, Width, Height: Integer; SrcDC: HDC; XSrc, YSrc: Integer; Rop: DWORD)
function Impl_BitBlt(_para1:HDC; _para2:longint; _para3:longint; _para4:longint; _para5:longint; _para6:HDC; _para7:longint; _para8:longint; _para9:DWORD): WINBOOL; stdcall; public name 'unidewin_BitBlt';
begin
  Result := LCLIntf.BitBlt(_para1, _para2, _para3, _para4, _para5, _para6, _para7, _para8, _para9);
end;

// LCL:  function CallNextHookEx(hhk : HHOOK; ncode : Integer; WParam: WParam; LParam: LParam)
function Impl_CallNextHookEx(hhk:HHOOK; nCode:longint; wParam:WPARAM; lParam:LPARAM): LRESULT; stdcall; public name 'unidewin_CallNextHookEx';
begin
  Result := LCLIntf.CallNextHookEx(hhk, nCode, wParam, lParam);
end;

// LCL: function CallWindowProc(lpPrevWndFunc : TFarProc; Handle : HWND; Msg : UINT; WParam: WParam; LParam: LParam)
function Impl_CallWindowProcA(lpPrevWndFunc:WNDPROC; hWnd:HWND; Msg:UINT; wParam:WPARAM; lParam:LPARAM): LRESULT; stdcall; public name 'unidewin_CallWindowProcA';
begin
  Result := LCLIntf.CallWindowProc(TFarProc(@lpPrevWndFunc), hWnd, Msg, wParam, lParam);
end;

// LCL: function ClientToScreen(Handle : HWND; var P : TPoint)
function Impl_ClientToScreen(hWnd:HWND; lpPoint:LPPOINT): WINBOOL; stdcall; public name 'unidewin_ClientToScreen';
begin
  Result := LCLIntf.ClientToScreen(hWnd, lpPoint^);
end;

// LCL: function CombineRgn(Dest, Src1, Src2 : HRGN; fnCombineMode : Longint)
function Impl_CombineRgn(_para1:HRGN; _para2:HRGN; _para3:HRGN; _para4:longint): longint; stdcall; public name 'unidewin_CombineRgn';
begin
  Result := LCLIntf.CombineRgn(_para1, _para2, _para3, _para4);
end;

// LCL: function CreateCaret(Handle: HWND; Bitmap: hBitmap; width, Height: Integer)
function Impl_CreateCaret(hWnd:HWND; hBitmap:HBITMAP; nWidth:longint; nHeight:longint): WINBOOL; stdcall; public name 'unidewin_CreateCaret';
begin
  Result := LCLIntf.CreateCaret(hWnd, hBitmap, nWidth, nHeight);
end;

// LCL: function CreateCompatibleBitmap(DC: HDC; Width, Height: Integer)
function Impl_CreateCompatibleBitmap(_para1:HDC; _para2:longint; _para3:longint): HBITMAP; stdcall; public name 'unidewin_CreateCompatibleBitmap';
begin
  Result := LCLIntf.CreateCompatibleBitmap(_para1, _para2, _para3);
end;

// LCL: function CreateCompatibleDC(DC: HDC)
function Impl_CreateCompatibleDC(_para1:HDC): HDC; stdcall; public name 'unidewin_CreateCompatibleDC';
begin
  Result := LCLIntf.CreateCompatibleDC(_para1);
end;

// LCL: function CreateDIBSection(DC: HDC; const BitmapInfo: tagBitmapInfo; Usage: UINT; var Bits: Pointer; SectionHandle: THandle; Offset: DWORD)
function Impl_CreateDIBSection(_para1:HDC; var _para2:BITMAPINFO; _para3:UINT; var _para4:pointer; _para5:HANDLE; _para6:DWORD): HBITMAP; stdcall; public name 'unidewin_CreateDIBSection';
begin
  Result := LCLIntf.CreateDIBSection(_para1, _para2, _para3, _para4, _para5, _para6);
end;

// LCL: function CreateEllipticRgn(X1, Y1, X2, Y2: Integer)
function Impl_CreateEllipticRgn(_para1:longint; _para2:longint; _para3:longint; _para4:longint): HRGN; stdcall; public name 'unidewin_CreateEllipticRgn';
begin
  Result := LCLIntf.CreateEllipticRgn(_para1, _para2, _para3, _para4);
end;

// LCL: function CreateFont(Height, Width, Escapement, Orientation, Weight: Integer; Italic, Underline, StrikeOut, CharSet, OutputPrecision, ClipPrecision, Quality, PitchAndFamily: Byte; FaceName: PChar)
function Impl_CreateFontA(_para1:longint; _para2:longint; _para3:longint; _para4:longint; _para5:longint; _para6:DWORD; _para7:DWORD; _para8:DWORD; _para9:DWORD; _para10:DWORD; _para11:DWORD; _para12:DWORD; _para13:DWORD; _para14:LPCSTR): HFONT; stdcall; public name 'unidewin_CreateFontA';
begin
  Result := LCLIntf.CreateFont(_para1, _para2, _para3, _para4, _para5, _para6, _para7, _para8, _para9, _para10, _para11, _para12, _para13, _para14);
end;

// LCL: function CreateFontIndirect(const LogFont: TLogFont)
function Impl_CreateFontIndirectA(_para1:LPLOGFONT): HFONT; stdcall; public name 'unidewin_CreateFontIndirectA';
begin
  Result := LCLIntf.CreateFontIndirect(_para1^);
end;

// LCL: function CreatePatternBrush(ABitmap: HBITMAP)
function Impl_CreatePatternBrush(_para1:HBITMAP): HBRUSH; stdcall; public name 'unidewin_CreatePatternBrush';
begin
  Result := LCLIntf.CreatePatternBrush(_para1);
end;

// LCL: function CreatePen(Style, Width: Integer; Color: TColorRef)
function Impl_CreatePen(_para1:longint; _para2:longint; _para3:COLORREF): HPEN; stdcall; public name 'unidewin_CreatePen';
begin
  Result := LCLIntf.CreatePen(_para1, _para2, _para3);
end;

// LCL: function CreateRectRgn(X1,Y1,X2,Y2 : Integer)
function Impl_CreateRectRgn(_para1:longint; _para2:longint; _para3:longint; _para4:longint): HRGN; stdcall; public name 'unidewin_CreateRectRgn';
begin
  Result := LCLIntf.CreateRectRgn(_para1, _para2, _para3, _para4);
end;

// LCL: function CreateRectRgnIndirect(const ARect: TRect)
function Impl_CreateRectRgnIndirect(const _para1:RECT): HRGN; stdcall; public name 'unidewin_CreateRectRgnIndirect';
begin
  Result := LCLIntf.CreateRectRgnIndirect(_para1);
end;

// LCL: function CreateRoundRectRgn(X1, Y1, X2, Y2, nWidthEllipse, nHeightEllipse: Integer)
function Impl_CreateRoundRectRgn(_para1:longint; _para2:longint; _para3:longint; _para4:longint; _para5:longint; _para6:longint): HRGN; stdcall; public name 'unidewin_CreateRoundRectRgn';
begin
  Result := LCLIntf.CreateRoundRectRgn(_para1, _para2, _para3, _para4, _para5, _para6);
end;

// LCL: function CreateSolidBrush(Color: TColorRef)
function Impl_CreateSolidBrush(_para1:COLORREF): HBRUSH; stdcall; public name 'unidewin_CreateSolidBrush';
begin
  Result := LCLIntf.CreateSolidBrush(_para1);
end;

// LCL:  procedure DeleteCriticalSection(var CritSection: TCriticalSection)
procedure Impl_DeleteCriticalSection(lpCriticalSection:LPCRITICAL_SECTION); stdcall; public name 'unidewin_DeleteCriticalSection';
begin
  LCLIntf.DeleteCriticalSection(PPtrUInt(lpCriticalSection)^);
end;

// LCL: function DeleteDC(hDC: HDC)
function Impl_DeleteDC(_para1:HDC): WINBOOL; stdcall; public name 'unidewin_DeleteDC';
begin
  Result := LCLIntf.DeleteDC(_para1);
end;

// LCL: function DeleteObject(GDIObject: HGDIOBJ)
function Impl_DeleteObject(_para1:HGDIOBJ): WINBOOL; stdcall; public name 'unidewin_DeleteObject';
begin
  Result := LCLIntf.DeleteObject(_para1);
end;

// LCL: function DrawEdge(DC: HDC; var Rect: TRect; edge: Cardinal; grfFlags: Cardinal)
function Impl_DrawEdge(hdc:HDC; qrc:LPRECT; edge:UINT; grfFlags:UINT): WINBOOL; stdcall; public name 'unidewin_DrawEdge';
begin
  Result := LCLIntf.DrawEdge(hdc, qrc^, edge, grfFlags);
end;

// LCL: function DrawFocusRect(DC: HDC; const Rect: TRect)
function Impl_DrawFocusRect(hDC:HDC; const lprc:RECT): WINBOOL; stdcall; public name 'unidewin_DrawFocusRect';
begin
  Result := LCLIntf.DrawFocusRect(hDC, lprc);
end;

// LCL: function DrawFrameControl(DC: HDC; const Rect : TRect; uType, uState : Cardinal)
function Impl_DrawFrameControl(_para1:HDC; _para2:LPRECT; _para3:UINT; _para4:UINT): WINBOOL; stdcall; public name 'unidewin_DrawFrameControl';
begin
  Result := LCLIntf.DrawFrameControl(_para1, _para2^, _para3, _para4);
end;

// LCL: function DrawText(DC: HDC; Str: PChar; Count: Integer; var Rect: TRect; Flags: Cardinal)
// LCL: function EndPaint(Handle : hwnd; var PS : TPaintStruct)
function Impl_EndPaint(hWnd:HWND; lpPaint:LPPAINTSTRUCT): WINBOOL; stdcall; public name 'unidewin_EndPaint';
var
  LclPs: LCLType.TPaintStruct;
begin
  FillChar(LclPs, SizeOf(LclPs), 0);
  LclPs.hdc := lpPaint^.hdc;
  LclPs.rcPaint := lpPaint^.rcPaint;
  Result := LCLIntf.EndPaint(hWnd, LclPs) <> 0;
end;

// LCL: procedure EnterCriticalSection(var CritSection: TCriticalSection)
procedure Impl_EnterCriticalSection(lpCriticalSection:LPCRITICAL_SECTION); stdcall; public name 'unidewin_EnterCriticalSection';
begin
  LCLIntf.EnterCriticalSection(PPtrUInt(lpCriticalSection)^);
end;

// LCL:  function EqualRect(const lprc1, lprc2: TRect)
function Impl_EqualRect(const lprc1:RECT; const lprc2:RECT): WINBOOL; stdcall; public name 'unidewin_EqualRect';
begin
  Result := LCLIntf.EqualRect(lprc1, lprc2);
end;

// LCL: function ExcludeClipRect(dc: hdc; Left, Top, Right, Bottom : Integer)
function Impl_ExcludeClipRect(_para1:HDC; _para2:longint; _para3:longint; _para4:longint; _para5:longint): longint; stdcall; public name 'unidewin_ExcludeClipRect';
begin
  Result := LCLIntf.ExcludeClipRect(_para1, _para2, _para3, _para4, _para5);
end;

// LCL:  function FillRect(DC: HDC; const Rect: TRect; Brush: HBRUSH)
function Impl_FillRect(hDC:HDC; const lprc:RECT; hbr:HBRUSH): longint; stdcall; public name 'unidewin_FillRect';
begin
  Result := Ord(LCLIntf.FillRect(hDC, lprc, hbr));
end;

// LCL: function FillRgn(DC: HDC; RegionHnd: HRGN; hbr: HBRUSH)
function Impl_FillRgn(_para1:HDC; _para2:HRGN; _para3:HBRUSH): WINBOOL; stdcall; public name 'unidewin_FillRgn';
begin
  Result := LCLIntf.FillRgn(_para1, _para2, _para3);
end;

// LCL: function FrameRect(DC: HDC; const ARect: TRect; hBr: HBRUSH)
function Impl_FrameRect(hDC:HDC; const lprc:RECT; hbr:HBRUSH): longint; stdcall; public name 'unidewin_FrameRect';
begin
  Result := LCLIntf.FrameRect(hDC, lprc, hbr);
end;

// LCL:  function GetActiveWindow 
function Impl_GetActiveWindow: HWND; stdcall; public name 'unidewin_GetActiveWindow';
begin
  Result := LCLIntf.GetActiveWindow();
end;

// LCL: function GetCapture 
function Impl_GetCapture: HWND; stdcall; public name 'unidewin_GetCapture';
begin
  Result := LCLIntf.GetCapture();
end;

// LCL: function GetClientRect(handle : HWND; var Rect: TRect)
function Impl_GetClientRect(hWnd:HWND; lpRect:LPRECT): WINBOOL; stdcall; public name 'unidewin_GetClientRect';
begin
  Result := LCLIntf.GetClientRect(hWnd, lpRect^);
end;

// LCL: function GetClipBox(DC : hDC; lpRect : PRect)
function Impl_GetClipBox(_para1:HDC; _para2:LPRECT): longint; stdcall; public name 'unidewin_GetClipBox';
begin
  Result := LCLIntf.GetClipBox(_para1, _para2);
end;

// LCL: function GetCursorPos(var lpPoint: TPoint)
function Impl_GetCursorPos(lpPoint:LPPOINT): WINBOOL; stdcall; public name 'unidewin_GetCursorPos';
begin
  Result := LCLIntf.GetCursorPos(lpPoint^);
end;

// LCL: function GetDC(hWnd: HWND)
function Impl_GetDC(hWnd:HWND): HDC; stdcall; public name 'unidewin_GetDC';
begin
  Result := LCLIntf.GetDC(hWnd);
end;

// LCL: function GetDeviceCaps(DC: HDC; Index: Integer)
function Impl_GetDeviceCaps(_para1:HDC; _para2:longint): longint; stdcall; public name 'unidewin_GetDeviceCaps';
begin
  Result := LCLIntf.GetDeviceCaps(_para1, _para2);
end;

// LCL: function GetDoubleClickTime
function Impl_GetDoubleClickTime: UINT; stdcall; public name 'unidewin_GetDoubleClickTime';
begin
  Result := LCLIntf.GetDoubleClickTime();
end;

// LCL: function GetFocus
function Impl_GetFocus: HWND; stdcall; public name 'unidewin_GetFocus';
begin
  Result := LCLIntf.GetFocus();
end;

// LCL: function GetForegroundWindow
function Impl_GetForegroundWindow: HWND; stdcall; public name 'unidewin_GetForegroundWindow';
begin
  Result := LCLIntf.GetForegroundWindow();
end;

// LCL: function GetKeyState(nVirtKey: Integer)
function Impl_GetKeyState(nVirtKey:longint): SHORT; stdcall; public name 'unidewin_GetKeyState';
begin
  Result := LCLIntf.GetKeyState(nVirtKey);
end;

// LCL: function GetParent(Handle : HWND)
function Impl_GetParent(hWnd:HWND): HWND; stdcall; public name 'unidewin_GetParent';
begin
  Result := LCLIntf.GetParent(hWnd);
end;

// LCL: function GetProp(Handle : hwnd; Str : PChar)
function Impl_GetPropA(hWnd:HWND; lpString:LPCSTR): HANDLE; stdcall; public name 'unidewin_GetPropA';
begin
  Result := THandle(LCLIntf.GetProp(hWnd, lpString));
end;

// LCL: function GetScrollInfo(Handle: HWND; SBStyle: Integer; var ScrollInfo: TScrollInfo)
function Impl_GetScrollInfo(_para1:HWND; _para2:longint; _para3:LPSCROLLINFO): WINBOOL; stdcall; public name 'unidewin_GetScrollInfo';
begin
  Result := LCLIntf.GetScrollInfo(_para1, _para2, LCLType.TScrollInfo(_para3^));
end;

// LCL:  function GetScrollPos(Handle: HWND; nBar: Integer)
function Impl_GetScrollPos(hWnd:HWND; nBar:longint): longint; stdcall; public name 'unidewin_GetScrollPos';
begin
  Result := LCLIntf.GetScrollPos(hWnd, nBar);
end;

// LCL: function GetSystemMetrics(nIndex: Integer)
function Impl_GetSystemMetrics(nIndex:longint): longint; stdcall; public name 'unidewin_GetSystemMetrics';
begin
  Result := LCLIntf.GetSystemMetrics(nIndex);
end;

// LCL: function GetTextExtentExPoint(DC: HDC; Str: PChar; Count, MaxWidth: Integer; MaxCount, PartialWidths: PInteger; var Size: TSize)
// LCL: function GetTextExtentPoint32(DC: HDC; Str: PChar; Count: Integer; var Size: TSize)
// LCL: function GetTextMetrics(DC: HDC; var TM: TTextMetric)
function Impl_GetTextMetricsA(_para1:HDC; _para2:LPTEXTMETRIC): WINBOOL; stdcall; public name 'unidewin_GetTextMetricsA';
begin
  Result := LCLIntf.GetTextMetrics(_para1, LCLType.TTextMetric(_para2^));
end;

// LCL: function GetWindowLong(Handle : hwnd; int : Integer)
function Impl_GetWindowLongA(hWnd:HWND; nIndex:longint): LONG; stdcall; public name 'unidewin_GetWindowLongA';
begin
  Result := LCLIntf.GetWindowLong(hWnd, nIndex);
end;

// LCL: function GetWindowRect(Handle : hwnd; var Rect : TRect)
function Impl_GetWindowRect(hWnd:HWND; lpRect:LPRECT): WINBOOL; stdcall; public name 'unidewin_GetWindowRect';
begin
  Result := LCLIntf.GetWindowRect(hWnd, lpRect^) <> 0;
end;

// LCL:  function HideCaret(hWnd: HWND)
function Impl_HideCaret(hWnd:HWND): WINBOOL; stdcall; public name 'unidewin_HideCaret';
begin
  Result := LCLIntf.HideCaret(hWnd);
end;

// LCL: function InflateRect(var ARect: TRect; dx, dy: Integer)
function Impl_InflateRect(lprc:LPRECT; dx:longint; dy:longint): WINBOOL; stdcall; public name 'unidewin_InflateRect';
begin
  Result := LCLIntf.InflateRect(lprc^, dx, dy);
end;

// LCL: procedure InitializeCriticalSection(var CritSection: TCriticalSection)
procedure Impl_InitializeCriticalSection(lpCriticalSection:LPCRITICAL_SECTION); stdcall; public name 'unidewin_InitializeCriticalSection';
begin
  LCLIntf.InitializeCriticalSection(PPtrUInt(lpCriticalSection)^);
end;

// LCL: function IntersectClipRect(dc: hdc; Left, Top, Right,Bottom: Integer)
function Impl_IntersectClipRect(_para1:HDC; _para2:longint; _para3:longint; _para4:longint; _para5:longint): longint; stdcall; public name 'unidewin_IntersectClipRect';
begin
  Result := LCLIntf.IntersectClipRect(_para1, _para2, _para3, _para4, _para5);
end;

// LCL: function IntersectRect(var DestRect: TRect; const SrcRect1, SrcRect2: TRect)
function Impl_IntersectRect(lprcDst:LPRECT; const lprcSrc1:RECT; const lprcSrc2:RECT): WINBOOL; stdcall; public name 'unidewin_IntersectRect';
begin
  Result := LCLIntf.IntersectRect(lprcDst^, lprcSrc1, lprcSrc2);
end;

// LCL: function InvalidateRect(aHandle : HWND; ARect : pRect; bErase : Boolean)
function Impl_InvalidateRect(hWnd:HWND; const lpRect:RECT; bErase:WINBOOL): WINBOOL; stdcall; public name 'unidewin_InvalidateRect';
begin
  Result := LCLIntf.InvalidateRect(hWnd, @lpRect, bErase);
end;

// LCL: function IsIconic(handle: HWND)
function Impl_IsIconic(hWnd:HWND): WINBOOL; stdcall; public name 'unidewin_IsIconic';
begin
  Result := LCLIntf.IsIconic(hWnd);
end;

// LCL: function IsRectEmpty(const ARect: TRect)
function Impl_IsRectEmpty(const lprc:RECT): WINBOOL; stdcall; public name 'unidewin_IsRectEmpty';
begin
  Result := LCLIntf.IsRectEmpty(lprc);
end;

// LCL: function IsWindow(handle: HWND)
function Impl_IsWindow(hWnd:HWND): WINBOOL; stdcall; public name 'unidewin_IsWindow';
begin
  Result := LCLIntf.IsWindow(hWnd);
end;

// LCL: function IsWindowEnabled(handle: HWND)
function Impl_IsWindowEnabled(hWnd:HWND): WINBOOL; stdcall; public name 'unidewin_IsWindowEnabled';
begin
  Result := LCLIntf.IsWindowEnabled(hWnd);
end;

// LCL: function IsWindowVisible(handle: HWND)
function Impl_IsWindowVisible(hWnd:HWND): WINBOOL; stdcall; public name 'unidewin_IsWindowVisible';
begin
  Result := LCLIntf.IsWindowVisible(hWnd);
end;

// LCL: function IsZoomed(handle: HWND)
function Impl_IsZoomed(hWnd:HWND): WINBOOL; stdcall; public name 'unidewin_IsZoomed';
begin
  Result := LCLIntf.IsZoomed(hWnd);
end;

// LCL:  function KillTimer(Wnd: HWND; uIDEvent: UINT_PTR)
function Impl_KillTimer(hWnd:HWND; uIDEvent:UINT_PTR): WINBOOL; stdcall; public name 'unidewin_KillTimer';
begin
  Result := LCLIntf.KillTimer(hWnd, uIDEvent);
end;

// LCL: function LPtoDP(DC: HDC; var Points; Count: Integer)
function Impl_LPtoDP(_para1:HDC; _para2:LPPOINT; _para3:longint): WINBOOL; stdcall; public name 'unidewin_LPtoDP';
begin
  Result := LCLIntf.LPtoDP(_para1, _para2^, _para3);
end;

// LCL:  procedure LeaveCriticalSection(var CritSection: TCriticalSection)
procedure Impl_LeaveCriticalSection(lpCriticalSection:LPCRITICAL_SECTION); stdcall; public name 'unidewin_LeaveCriticalSection';
begin
  LCLIntf.LeaveCriticalSection(PPtrUInt(lpCriticalSection)^);
end;

// LCL: function LineTo(DC: HDC; X, Y: Integer)
function Impl_LineTo(_para1:HDC; _para2:longint; _para3:longint): WINBOOL; stdcall; public name 'unidewin_LineTo';
begin
  Result := LCLIntf.LineTo(_para1, _para2, _para3);
end;

// LCL: function LoadCursor(hInstance: THandle; lpCursorName: PChar)
function Impl_LoadCursorA(hInstance:HINST; lpCursorName:LPCSTR): HCURSOR; stdcall; public name 'unidewin_LoadCursorA';
begin
  Result := LCLIntf.LoadCursor(hInstance, lpCursorName);
end;

// LCL: function LoadIcon(hInstance: THandle; lpIconName: PChar)
function Impl_LoadIconA(hInstance:HINST; lpIconName:LPCSTR): HICON; stdcall; public name 'unidewin_LoadIconA';
begin
  Result := LCLIntf.LoadIcon(hInstance, lpIconName);
end;

// LCL:  function MoveToEx(DC: HDC; X, Y: Integer; OldPoint: PPoint)
function Impl_MoveToEx(_para1:HDC; _para2:longint; _para3:longint; _para4:LPPOINT): WINBOOL; stdcall; public name 'unidewin_MoveToEx';
begin
  Result := LCLIntf.MoveToEx(_para1, _para2, _para3, _para4);
end;

// LCL: function OffsetRect(var Rect: TRect; dx,dy: Integer)
function Impl_OffsetRect(lprc:LPRECT; dx:longint; dy:longint): WINBOOL; stdcall; public name 'unidewin_OffsetRect';
begin
  Result := LCLIntf.OffsetRect(lprc^, dx, dy);
end;

// LCL: function PeekMessage(var lpMsg : TMsg; Handle : HWND; wMsgFilterMin, wMsgFilterMax,wRemoveMsg : UINT)
function Impl_PeekMessageA(lpMsg:LPMSG; hWnd:HWND; wMsgFilterMin:UINT; wMsgFilterMax:UINT; wRemoveMsg:UINT): WINBOOL; stdcall; public name 'unidewin_PeekMessageA';
var
  LclMsg: LCLType.TMsg;
begin
  FillChar(LclMsg, SizeOf(LclMsg), 0);
  Result := LCLIntf.PeekMessage(LclMsg, hWnd, wMsgFilterMin, wMsgFilterMax, wRemoveMsg);
  lpMsg^.hwnd := LclMsg.hwnd;
  lpMsg^.message := LclMsg.message;
  lpMsg^.wParam := LclMsg.wParam;
  lpMsg^.lParam := LclMsg.lParam;
  lpMsg^.time := LclMsg.time;
  lpMsg^.pt := LclMsg.pt;
end;

// LCL: function PostMessage(Handle: HWND; Msg: Cardinal; WParam: WParam; LParam: LParam)
function Impl_PostMessageA(hWnd:HWND; Msg:UINT; wParam:WPARAM; lParam:LPARAM): WINBOOL; stdcall; public name 'unidewin_PostMessageA';
begin
  Result := LCLIntf.PostMessage(hWnd, Msg, wParam, lParam);
end;

// LCL:  function PtInRect(const Rect : TRect; const Point : TPoint)
function Impl_PtInRect(const lprc:RECT; pt:POINT): WINBOOL; stdcall; public name 'unidewin_PtInRect';
begin
  Result := LCLIntf.PtInRect(lprc, pt);
end;

// LCL: function Rectangle(DC: HDC; X1, Y1, X2, Y2: Integer)
function Impl_Rectangle(_para1:HDC; _para2:longint; _para3:longint; _para4:longint; _para5:longint): WINBOOL; stdcall; public name 'unidewin_Rectangle';
begin
  Result := LCLIntf.Rectangle(_para1, _para2, _para3, _para4, _para5);
end;

// LCL: function RedrawWindow(Wnd: HWND; lprcUpdate: PRECT; hrgnUpdate: HRGN; flags: UINT)
function Impl_RedrawWindow(hWnd:HWND; const lprcUpdate:RECT; hrgnUpdate:HRGN; flags:UINT): WINBOOL; stdcall; public name 'unidewin_RedrawWindow';
begin
  Result := LCLIntf.RedrawWindow(hWnd, @lprcUpdate, hrgnUpdate, flags);
end;

// LCL: function ReleaseCapture 
function Impl_ReleaseCapture: WINBOOL; stdcall; public name 'unidewin_ReleaseCapture';
begin
  Result := LCLIntf.ReleaseCapture();
end;

// LCL: function ReleaseDC(hWnd: HWND; DC: HDC)
function Impl_ReleaseDC(hWnd:HWND; hDC:HDC): longint; stdcall; public name 'unidewin_ReleaseDC';
begin
  Result := LCLIntf.ReleaseDC(hWnd, hDC);
end;

// LCL: function RemoveProp(Handle: hwnd; Str: PChar)
function Impl_RemovePropA(hWnd:HWND; lpString:LPCSTR): HANDLE; stdcall; public name 'unidewin_RemovePropA';
begin
  Result := LCLIntf.RemoveProp(hWnd, lpString);
end;

// LCL: function RestoreDC(DC: HDC; SavedDC: Integer)
function Impl_RestoreDC(_para1:HDC; _para2:longint): WINBOOL; stdcall; public name 'unidewin_RestoreDC';
begin
  Result := LCLIntf.RestoreDC(_para1, _para2);
end;

// LCL:  function SaveDC(DC: HDC)
function Impl_SaveDC(_para1:HDC): longint; stdcall; public name 'unidewin_SaveDC';
begin
  Result := LCLIntf.SaveDC(_para1);
end;

// LCL: function ScreenToClient(Handle : HWND; var P : TPoint)
function Impl_ScreenToClient(hWnd:HWND; lpPoint:LPPOINT): WINBOOL; stdcall; public name 'unidewin_ScreenToClient';
begin
  Result := LCLIntf.ScreenToClient(hWnd, lpPoint^) <> 0;
end;

// LCL: function SelectObject(DC: HDC; GDIObj: HGDIOBJ)
function Impl_SelectObject(_para1:HDC; _para2:HGDIOBJ): HGDIOBJ; stdcall; public name 'unidewin_SelectObject';
begin
  Result := LCLIntf.SelectObject(_para1, _para2);
end;

// LCL: function SendMessage(HandleWnd: HWND; Msg: Cardinal; WParam: WParam; LParam: LParam)
function Impl_SendMessageA(hWnd:HWND; Msg:UINT; wParam:WPARAM; lParam:LPARAM): LRESULT; stdcall; public name 'unidewin_SendMessageA';
begin
  Result := LCLIntf.SendMessage(hWnd, Msg, wParam, lParam);
end;

// LCL: function SetBkColor(DC: HDC; Color: TColorRef)
function Impl_SetBkColor(_para1:HDC; _para2:COLORREF): COLORREF; stdcall; public name 'unidewin_SetBkColor';
begin
  Result := LCLIntf.SetBkColor(_para1, _para2);
end;

// LCL: function SetBkMode(DC: HDC; bkMode : Integer)
function Impl_SetBkMode(_para1:HDC; _para2:longint): longint; stdcall; public name 'unidewin_SetBkMode';
begin
  Result := LCLIntf.SetBkMode(_para1, _para2);
end;

// LCL: function SetCapture (AHandle: HWND)
function Impl_SetCapture(hWnd:HWND): HWND; stdcall; public name 'unidewin_SetCapture';
begin
  Result := LCLIntf.SetCapture(hWnd);
end;

// LCL: function SetCaretPos(X, Y: Integer)
function Impl_SetCaretPos(X:longint; Y:longint): WINBOOL; stdcall; public name 'unidewin_SetCaretPos';
begin
  Result := LCLIntf.SetCaretPos(X, Y);
end;

// LCL: function SetCursor(hCursor: HICON)
function Impl_SetCursor(hCursor:HCURSOR): HCURSOR; stdcall; public name 'unidewin_SetCursor';
begin
  Result := LCLIntf.SetCursor(hCursor);
end;

// LCL: function SetFocus(hWnd: HWND)
function Impl_SetFocus(hWnd:HWND): HWND; stdcall; public name 'unidewin_SetFocus';
begin
  Result := LCLIntf.SetFocus(hWnd);
end;

// LCL: function SetForegroundWindow(hWnd : HWND)
function Impl_SetForegroundWindow(hWnd:HWND): WINBOOL; stdcall; public name 'unidewin_SetForegroundWindow';
begin
  Result := LCLIntf.SetForegroundWindow(hWnd);
end;

// LCL: function SetProp(Handle: hwnd; Str : PChar; Data : Pointer)
function Impl_SetPropA(hWnd:HWND; lpString:LPCSTR; hData:HANDLE): WINBOOL; stdcall; public name 'unidewin_SetPropA';
begin
  Result := LCLIntf.SetProp(hWnd, lpString, Pointer(hData));
end;

// LCL: function SetRectEmpty(var ARect: TRect)
function Impl_SetRectEmpty(lprc:LPRECT): WINBOOL; stdcall; public name 'unidewin_SetRectEmpty';
begin
  Result := LCLIntf.SetRectEmpty(lprc^);
end;

// LCL: function SetStretchBltMode(DC: HDC; StretchMode: Integer)
function Impl_SetStretchBltMode(_para1:HDC; _para2:longint): longint; stdcall; public name 'unidewin_SetStretchBltMode';
begin
  Result := LCLIntf.SetStretchBltMode(_para1, _para2);
end;

// LCL: function SetTextColor(DC: HDC; Color: TColorRef)
function Impl_SetTextColor(_para1:HDC; _para2:COLORREF): COLORREF; stdcall; public name 'unidewin_SetTextColor';
begin
  Result := LCLIntf.SetTextColor(_para1, _para2);
end;

// LCL: function SetTimer(Wnd: HWND; nIDEvent: UINT_PTR; uElapse: UINT; lpTimerFunc: TTimerProc)
function Impl_SetTimer(hWnd:HWND; nIDEvent:UINT_PTR; uElapse:UINT; lpTimerFunc:TIMERPROC): UINT_PTR; stdcall; public name 'unidewin_SetTimer';
begin
  Result := LCLIntf.SetTimer(hWnd, nIDEvent, uElapse, TTimerProc(lpTimerFunc));
end;

// LCL: function SetViewPortOrgEx(DC: HDC; NewX, NewY: Integer; OldPoint: PPoint)
function Impl_SetViewportOrgEx(_para1:HDC; _para2:longint; _para3:longint; _para4:LPPOINT): WINBOOL; stdcall; public name 'unidewin_SetViewportOrgEx';
begin
  Result := LCLIntf.SetViewportOrgEx(_para1, _para2, _para3, _para4);
end;

// LCL: function SetWindowLong(Handle: HWND; Idx: Integer; NewLong : PtrInt)
function Impl_SetWindowLongA(hWnd:HWND; nIndex:longint; dwNewLong:LONG): LONG; stdcall; public name 'unidewin_SetWindowLongA';
begin
  Result := LCLIntf.SetWindowLong(hWnd, nIndex, dwNewLong);
end;

// LCL: function SetWindowPos(hWnd: HWND; hWndInsertAfter: HWND; X, Y, cx, cy: Integer; uFlags: UINT)
function Impl_SetWindowPos(hWnd:HWND; hWndInsertAfter:HWND; X:longint; Y:longint; cx:longint; cy:longint; uFlags:UINT): WINBOOL; stdcall; public name 'unidewin_SetWindowPos';
begin
  Result := LCLIntf.SetWindowPos(hWnd, hWndInsertAfter, X, Y, cx, cy, uFlags);
end;

// LCL: function ShowCaret(hWnd: HWND)
function Impl_ShowCaret(hWnd:HWND): WINBOOL; stdcall; public name 'unidewin_ShowCaret';
begin
  Result := LCLIntf.ShowCaret(hWnd);
end;

// LCL: function ShowWindow(hWnd: HWND; nCmdShow: Integer)
function Impl_ShowWindow(hWnd:HWND; nCmdShow:longint): WINBOOL; stdcall; public name 'unidewin_ShowWindow';
begin
  Result := LCLIntf.ShowWindow(hWnd, nCmdShow);
end;

// LCL: function StretchBlt(DestDC: HDC; X, Y, Width, Height: Integer; SrcDC: HDC; XSrc, YSrc, SrcWidth, SrcHeight: Integer; Rop: Cardinal)
function Impl_StretchBlt(_para1:HDC; _para2:longint; _para3:longint; _para4:longint; _para5:longint; _para6:HDC; _para7:longint; _para8:longint; _para9:longint; _para10:longint; _para11:DWORD): WINBOOL; stdcall; public name 'unidewin_StretchBlt';
begin
  Result := LCLIntf.StretchBlt(_para1, _para2, _para3, _para4, _para5, _para6, _para7, _para8, _para9, _para10, _para11);
end;

// LCL: function SystemParametersInfo(uiAction: DWord; uiParam: DWord; pvParam: Pointer; fWinIni: DWord)
function Impl_SystemParametersInfoA(uiAction:UINT; uiParam:UINT; pvParam:PVOID; fWinIni:UINT): WINBOOL; stdcall; public name 'unidewin_SystemParametersInfoA';
begin
  Result := LCLIntf.SystemParametersInfo(uiAction, uiParam, pvParam, fWinIni);
end;

// LCL:  function TextOut(DC: HDC; X,Y : Integer; Str : Pchar; Count: Integer)
// LCL:  function UnionRect(var DestRect: TRect; const SrcRect1, SrcRect2: TRect)
function Impl_UnionRect(lprcDst:LPRECT; const lprcSrc1:RECT; const lprcSrc2:RECT): WINBOOL; stdcall; public name 'unidewin_UnionRect';
begin
  Result := LCLIntf.UnionRect(lprcDst^, lprcSrc1, lprcSrc2);
end;

// LCL:  function UpdateWindow(Handle: HWND)
function Impl_UpdateWindow(hWnd:HWND): WINBOOL; stdcall; public name 'unidewin_UpdateWindow';
begin
  Result := LCLIntf.UpdateWindow(hWnd);
end;

// LCL:  function WindowFromPoint(Point : TPoint)
function Impl_WindowFromPoint(Point:POINT): HWND; stdcall; public name 'unidewin_WindowFromPoint';
begin
  Result := LCLIntf.WindowFromPoint(Point);
end;

{$I winimpl_rt.inc}
{$I winimpl_auto.inc}

end.
