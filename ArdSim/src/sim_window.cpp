// ArdSim: the simulator window. Shows the 480x320 frame buffer, the BS10
// keypad (buttons and PC keys) and the Serial output. The sketch runs in
// its own thread (sim_core.cpp); this thread only reads its state.
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include "sim_internal.h"
#include <string>

static const int KeyHoldMs = 120;          // > 50 ms period of kbdcheck2
static const int SerialHeight = 140;
static const int KeyWidth = 60, KeyHeight = 44, KeyGap = 6;
static const int Margin = 8;
static const int IdKeyBase = 1000;
static const int IdSerial = 900;
static const int IdStatus = 901;

static HWND MainWindow, SerialEdit, StatusText;
static int Scale = 1;
static uint32_t ShownVersion = 0xFFFFFFFF;
static uint32_t *Pixels;                   // 32-bit copy of SimScreen
static BITMAPINFO PixelInfo;

static int screenWidth() { return SIM_SCREEN_W * Scale; }
static int screenHeight() { return SIM_SCREEN_H * Scale; }
static int keypadLeft() { return Margin + screenWidth() + Margin * 2; }

static void convertScreen()
{
  for (int row = 0; row < SIM_SCREEN_H; row++)
    for (int col = 0; col < SIM_SCREEN_W; col++)
    {
      uint16_t color = SimScreen[row][col];
      uint32_t red = (color >> 11) & 0x1F, green = (color >> 5) & 0x3F, blue = color & 0x1F;
      red = (red << 3) | (red >> 2);
      green = (green << 2) | (green >> 4);
      blue = (blue << 3) | (blue >> 2);
      Pixels[row * SIM_SCREEN_W + col] = (red << 16) | (green << 8) | blue;
    }
}

static void appendSerial(const std::string &text)
{
  std::string converted;
  for (size_t index = 0; index < text.size(); index++)
  {
    char value = text[index];
    if (value == '\n' && (index == 0 || text[index - 1] != '\r'))
      converted += '\r';
    converted += value;
  }
  int length = GetWindowTextLengthA(SerialEdit);
  if (length > 60000)
  {
    SendMessageA(SerialEdit, EM_SETSEL, 0, 20000);
    SendMessageA(SerialEdit, EM_REPLACESEL, FALSE, (LPARAM)"");
    length = GetWindowTextLengthA(SerialEdit);
  }
  SendMessageA(SerialEdit, EM_SETSEL, length, length);
  SendMessageA(SerialEdit, EM_REPLACESEL, FALSE, (LPARAM)converted.c_str());
}

// PC key -> keypad position; false if the key is not on the keypad
static bool keyOfVirtualKey(WPARAM key, int &row, int &col)
{
  static const struct { WPARAM Key; int Row, Col; } Map[] = {
    {VK_F1, 0, 0}, {VK_F2, 0, 1}, {VK_MULTIPLY, 0, 3},
    {'1', 1, 0}, {'2', 1, 1}, {'3', 1, 2}, {VK_UP, 1, 3},
    {'4', 2, 0}, {'5', 2, 1}, {'6', 2, 2}, {VK_DOWN, 2, 3},
    {'7', 3, 0}, {'8', 3, 1}, {'9', 3, 2}, {VK_ESCAPE, 3, 3},
    {VK_LEFT, 4, 0}, {'0', 4, 1}, {VK_RIGHT, 4, 2}, {VK_RETURN, 4, 3},
    {VK_NUMPAD1, 1, 0}, {VK_NUMPAD2, 1, 1}, {VK_NUMPAD3, 1, 2},
    {VK_NUMPAD4, 2, 0}, {VK_NUMPAD5, 2, 1}, {VK_NUMPAD6, 2, 2},
    {VK_NUMPAD7, 3, 0}, {VK_NUMPAD8, 3, 1}, {VK_NUMPAD9, 3, 2},
    {VK_NUMPAD0, 4, 1}, {VK_BACK, 3, 3}};
  for (const auto &entry : Map)
    if (entry.Key == key)
    {
      row = entry.Row;
      col = entry.Col;
      return true;
    }
  // '#' and '*' on the main keyboard come as characters (WM_CHAR)
  return false;
}

static void showPixelInfo(int mouseX, int mouseY)
{
  int pixelX = (mouseX - Margin) / Scale;
  int pixelY = (mouseY - Margin) / Scale;
  char text[128];
  if (pixelX >= 0 && pixelX < SIM_SCREEN_W && pixelY >= 0 && pixelY < SIM_SCREEN_H)
    snprintf(text, sizeof(text), "x=%d  y=%d  color=0x%04X", pixelX, pixelY, SimScreen[pixelY][pixelX]);
  else
    text[0] = 0;
  SetWindowTextA(StatusText, text);
}

static LRESULT CALLBACK windowProc(HWND window, UINT message, WPARAM wParam, LPARAM lParam)
{
  switch (message)
  {
  case WM_CREATE:
  {
    HFONT guiFont = (HFONT)GetStockObject(DEFAULT_GUI_FONT);
    for (int row = 0; row < SIM_KEY_ROWS; row++)
      for (int col = 0; col < SIM_KEY_COLS; col++)
      {
        HWND button = CreateWindowA("BUTTON", simKeyCaption(row, col), WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
          keypadLeft() + col * (KeyWidth + KeyGap), Margin + row * (KeyHeight + KeyGap), KeyWidth, KeyHeight,
          window, (HMENU)(INT_PTR)(IdKeyBase + row * SIM_KEY_COLS + col), nullptr, nullptr);
        SendMessageA(button, WM_SETFONT, (WPARAM)guiFont, TRUE);
      }
    int keypadBottom = Margin + SIM_KEY_ROWS * (KeyHeight + KeyGap);
    HWND help = CreateWindowA("STATIC",
      "PC keys: 0-9, F1, F2, #, *,\r\narrows, Enter, Esc", WS_CHILD | WS_VISIBLE,
      keypadLeft(), keypadBottom + 4, 4 * (KeyWidth + KeyGap), 36, window, nullptr, nullptr, nullptr);
    SendMessageA(help, WM_SETFONT, (WPARAM)guiFont, TRUE);
    StatusText = CreateWindowA("STATIC", "", WS_CHILD | WS_VISIBLE,
      keypadLeft(), keypadBottom + 44, 4 * (KeyWidth + KeyGap), 20, window, (HMENU)IdStatus, nullptr, nullptr);
    SendMessageA(StatusText, WM_SETFONT, (WPARAM)guiFont, TRUE);
    SerialEdit = CreateWindowExA(WS_EX_CLIENTEDGE, "EDIT", "",
      WS_CHILD | WS_VISIBLE | WS_VSCROLL | ES_MULTILINE | ES_AUTOVSCROLL | ES_READONLY,
      Margin, Margin * 2 + screenHeight(), screenWidth(), SerialHeight, window, (HMENU)IdSerial, nullptr, nullptr);
    SendMessageA(SerialEdit, WM_SETFONT, (WPARAM)GetStockObject(ANSI_FIXED_FONT), TRUE);
    SetTimer(window, 1, 33, nullptr);
    return 0;
  }
  case WM_TIMER:
  {
    if (SimScreenVersion != ShownVersion)
    {
      ShownVersion = SimScreenVersion;
      RECT area = {Margin, Margin, Margin + screenWidth(), Margin + screenHeight()};
      InvalidateRect(window, &area, FALSE);
    }
    std::string serial = simSerialTake();
    if (!serial.empty())
      appendSerial(serial);
    return 0;
  }
  case WM_PAINT:
  {
    PAINTSTRUCT paint;
    HDC context = BeginPaint(window, &paint);
    convertScreen();
    SetStretchBltMode(context, COLORONCOLOR);
    StretchDIBits(context, Margin, Margin, screenWidth(), screenHeight(), 0, 0, SIM_SCREEN_W, SIM_SCREEN_H,
      Pixels, &PixelInfo, DIB_RGB_COLORS, SRCCOPY);
    EndPaint(window, &paint);
    return 0;
  }
  case WM_COMMAND:
  {
    int id = LOWORD(wParam);
    if (id >= IdKeyBase && id < IdKeyBase + SIM_KEY_ROWS * SIM_KEY_COLS)
    {
      simPostKey((id - IdKeyBase) / SIM_KEY_COLS, (id - IdKeyBase) % SIM_KEY_COLS, KeyHoldMs);
      SetFocus(window);
    }
    return 0;
  }
  case WM_MOUSEMOVE:
    showPixelInfo((short)LOWORD(lParam), (short)HIWORD(lParam));
    return 0;
  case WM_CLOSE:
    simRequestStop();
    DestroyWindow(window);
    return 0;
  case WM_DESTROY:
    PostQuitMessage(0);
    return 0;
  }
  return DefWindowProcA(window, message, wParam, lParam);
}

int WINAPI WinMain(HINSTANCE instance, HINSTANCE, LPSTR, int show)
{
  // x2 when the screen has room for it
  int clientWidth2 = Margin + SIM_SCREEN_W * 2 + Margin * 3 + 4 * (KeyWidth + KeyGap);
  int clientHeight2 = Margin * 3 + SIM_SCREEN_H * 2 + SerialHeight;
  Scale = (GetSystemMetrics(SM_CXSCREEN) >= clientWidth2 + 40 &&
           GetSystemMetrics(SM_CYSCREEN) >= clientHeight2 + 80) ? 2 : 1;
  if (strstr(GetCommandLineA(), "/x1"))
    Scale = 1;

  Pixels = new uint32_t[SIM_SCREEN_W * SIM_SCREEN_H];
  PixelInfo.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
  PixelInfo.bmiHeader.biWidth = SIM_SCREEN_W;
  PixelInfo.bmiHeader.biHeight = -SIM_SCREEN_H;   // top-down
  PixelInfo.bmiHeader.biPlanes = 1;
  PixelInfo.bmiHeader.biBitCount = 32;
  PixelInfo.bmiHeader.biCompression = BI_RGB;

  WNDCLASSA windowClass = {};
  windowClass.lpfnWndProc = windowProc;
  windowClass.hInstance = instance;
  windowClass.hCursor = LoadCursor(nullptr, IDC_ARROW);
  windowClass.hbrBackground = (HBRUSH)(COLOR_BTNFACE + 1);
  windowClass.lpszClassName = "ArdSimWindow";
  RegisterClassA(&windowClass);

  RECT frame = {0, 0, keypadLeft() + 4 * (KeyWidth + KeyGap) + Margin, Margin * 3 + screenHeight() + SerialHeight};
  DWORD style = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX;
  AdjustWindowRect(&frame, style, FALSE);
  MainWindow = CreateWindowA("ArdSimWindow", "ArdSim - BS10", style, CW_USEDEFAULT, CW_USEDEFAULT,
    frame.right - frame.left, frame.bottom - frame.top, nullptr, nullptr, instance, nullptr);
  ShowWindow(MainWindow, show);

  simStartSketch();

  MSG message;
  while (GetMessageA(&message, nullptr, 0, 0) > 0)
  {
    // keypad keys work whatever control has the focus
    if (message.message == WM_KEYDOWN)
    {
      int row, col;
      if (keyOfVirtualKey(message.wParam, row, col))
      {
        simPostKey(row, col, KeyHoldMs);
        continue;
      }
    }
    if (message.message == WM_CHAR && (message.wParam == '#' || message.wParam == '*'))
    {
      simPostKey(0, message.wParam == '#' ? 2 : 3, KeyHoldMs);
      continue;
    }
    TranslateMessage(&message);
    DispatchMessageA(&message);
  }
  // the sketch thread may be inside a long computation: do not wait for it
  ExitProcess(0);
  return 0;
}
