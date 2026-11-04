// ArdSim: the simulator window. Shows the 480x320 frame buffer, the BS10
// keypad (buttons and PC keys) and the Serial output. The sketch runs in
// its own thread (sim_core.cpp); this thread only reads its state.
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <shellapi.h>
#include "sim_internal.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>

static const int KeyHoldMs = 300;          // upper limit; released after the first scan (sim_core)
static const int SerialHeight = 140;
static const int KeyWidth = 60, KeyHeight = 44, KeyGap = 6;
static const int Margin = 8;
static const int IdKeyBase = 1000;
static const int IdSerial = 900;
static const int IdStatus = 901;

static HWND MainWindow, SerialEdit, StatusText;

// Signal panel (generator settings, see sim_signal.cpp)
static const int IdTachoOn = 950, IdRpm = 951, IdApply = 952, IdEditIni = 953, IdSignalInfo = 954;
static const int IdAmpBase = 960, IdPhaseBase = 970;   // + channel 0/1
static const int PanelChannels = 2;                    // A0, A1 on the panel; the rest in the ini
static const int IdRotorOn = 955, IdRotorInfo = 956, IdWeightsBase = 980;   // + plane
static HWND TachoBox, RpmEdit, SignalInfo, RotorBox, RotorInfo;
static HWND WeightsEdit[SIM_PLANES];
static HWND AmpEdit[PanelChannels], PhaseEdit[PanelChannels];
static SimSignalConfig SignalConfig;
static std::string IniPath;
static FILETIME IniTime;
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
  // Shift+3 / Shift+8 are '#' and '*': they come as WM_CHAR
  if (GetKeyState(VK_SHIFT) < 0 && key >= '0' && key <= '9')
    return false;
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


// ---------------------------------------------------------------- signal panel
static FILETIME iniWriteTime()
{
  FILETIME result = {0, 0};
  WIN32_FILE_ATTRIBUTE_DATA data;
  if (GetFileAttributesExA(IniPath.c_str(), GetFileExInfoStandard, &data))
    result = data.ftLastWriteTime;
  return result;
}

static void setEditNumber(HWND edit, double value)
{
  char text[32];
  snprintf(text, sizeof(text), "%g", value);
  SetWindowTextA(edit, text);
}

static double editNumber(HWND edit, double fallback)
{
  char text[32];
  GetWindowTextA(edit, text, sizeof(text));
  for (char *cursor = text; *cursor; cursor++)
    if (*cursor == ',')
      *cursor = '.';
  char *end;
  double value = strtod(text, &end);
  return end == text ? fallback : value;
}

static void showSignalInfo(const char *note)
{
  char text[128];
  snprintf(text, sizeof(text), "f = %.2f Hz, tacho pin %d%s%s", SignalConfig.Rpm / 60.0,
    SignalConfig.TachoPin, note[0] ? ", " : "", note);
  SetWindowTextA(SignalInfo, text);
}

static void configToPanel()
{
  SendMessageA(TachoBox, BM_SETCHECK, SignalConfig.TachoOn ? BST_CHECKED : BST_UNCHECKED, 0);
  setEditNumber(RpmEdit, SignalConfig.Rpm);
  bool rotorOn = SignalConfig.Rotor.Enabled;
  SendMessageA(RotorBox, BM_SETCHECK, rotorOn ? BST_CHECKED : BST_UNCHECKED, 0);
  for (int channel = 0; channel < PanelChannels; channel++)
  {
    setEditNumber(AmpEdit[channel], SignalConfig.Channel[channel].HarmAmp[1]);
    setEditNumber(PhaseEdit[channel], SignalConfig.Channel[channel].HarmPhase[1]);
    // with the rotor model the 1st harmonic is computed, not typed
    EnableWindow(AmpEdit[channel], !rotorOn);
    EnableWindow(PhaseEdit[channel], !rotorOn);
  }
  for (int plane = 0; plane < SIM_PLANES; plane++)
  {
    SetWindowTextA(WeightsEdit[plane], SignalConfig.Rotor.Weights[plane]);
    EnableWindow(WeightsEdit[plane], rotorOn);
  }
  char text[128] = "";
  if (rotorOn)
  {
    double amp0, phase0, amp1, phase1;
    simRotorResponse(SignalConfig, 0, amp0, phase0);
    simRotorResponse(SignalConfig, 1, amp1, phase1);
    snprintf(text, sizeof(text), "1x: A%d %.4f V %.0f deg, A%d %.4f V %.0f deg",
      SignalConfig.Rotor.Sensor[0], amp0, phase0, SignalConfig.Rotor.Sensor[1], amp1, phase1);
  }
  SetWindowTextA(RotorInfo, text);
}

// ini -> generator and panel; a missing ini is created with the defaults
static void loadSignalIni(bool first)
{
  if (!simSignalLoad(IniPath.c_str(), SignalConfig))
  {
    simSignalDefaults(SignalConfig);
    simSignalSave(IniPath.c_str(), SignalConfig);
  }
  IniTime = iniWriteTime();
  simSignalSet(SignalConfig);
  configToPanel();
  showSignalInfo(first ? "" : "ini reloaded");
}

static void applyPanel()
{
  SignalConfig.TachoOn = SendMessageA(TachoBox, BM_GETCHECK, 0, 0) == BST_CHECKED;
  SignalConfig.Rpm = editNumber(RpmEdit, SignalConfig.Rpm);
  if (SignalConfig.Rpm < 0)
    SignalConfig.Rpm = 0;
  if (SignalConfig.Rpm > 100000)
    SignalConfig.Rpm = 100000;
  SignalConfig.Rotor.Enabled = SendMessageA(RotorBox, BM_GETCHECK, 0, 0) == BST_CHECKED;
  for (int plane = 0; plane < SIM_PLANES; plane++)
    GetWindowTextA(WeightsEdit[plane], SignalConfig.Rotor.Weights[plane], SIM_WEIGHTS_TEXT);
  for (int channel = 0; channel < PanelChannels && !SignalConfig.Rotor.Enabled; channel++)
  {
    SignalConfig.Channel[channel].HarmAmp[1] = editNumber(AmpEdit[channel], SignalConfig.Channel[channel].HarmAmp[1]);
    SignalConfig.Channel[channel].HarmPhase[1] = editNumber(PhaseEdit[channel], SignalConfig.Channel[channel].HarmPhase[1]);
  }
  simRotorApply(SignalConfig);
  simSignalSet(SignalConfig);
  simSignalSave(IniPath.c_str(), SignalConfig);
  IniTime = iniWriteTime();
  configToPanel();
  showSignalInfo("applied");
}

static bool isPanelEdit(HWND window)
{
  if (window == RpmEdit)
    return true;
  for (int plane = 0; plane < SIM_PLANES; plane++)
    if (window == WeightsEdit[plane])
      return true;
  for (int channel = 0; channel < PanelChannels; channel++)
    if (window == AmpEdit[channel] || window == PhaseEdit[channel])
      return true;
  return false;
}

static HWND panelControl(HWND parent, const char *className, const char *text, DWORD style,
  int left, int top, int width, int height, int id)
{
  HWND control = CreateWindowExA(strcmp(className, "EDIT") == 0 ? WS_EX_CLIENTEDGE : 0, className, text,
    WS_CHILD | WS_VISIBLE | style, left, top, width, height, parent, (HMENU)(INT_PTR)id, nullptr, nullptr);
  SendMessageA(control, WM_SETFONT, (WPARAM)GetStockObject(DEFAULT_GUI_FONT), TRUE);
  return control;
}

static void createSignalPanel(HWND window, int top)
{
  int left = keypadLeft();
  panelControl(window, "STATIC", "Signals (A0, A1: 1st harmonic; all in ardsim.ini)", 0, left, top, 264, 16, -1);
  top += 20;
  TachoBox = panelControl(window, "BUTTON", "Tacho", BS_AUTOCHECKBOX, left, top, 60, 20, IdTachoOn);
  panelControl(window, "STATIC", "RPM", 0, left + 70, top + 3, 30, 16, -1);
  RpmEdit = panelControl(window, "EDIT", "", ES_AUTOHSCROLL, left + 100, top, 70, 20, IdRpm);
  top += 26;
  panelControl(window, "STATIC", "Amp, V", 0, left + 40, top, 70, 16, -1);
  panelControl(window, "STATIC", "Phase, deg", 0, left + 120, top, 80, 16, -1);
  top += 18;
  for (int channel = 0; channel < PanelChannels; channel++)
  {
    char caption[8];
    snprintf(caption, sizeof(caption), "A%d", channel);
    panelControl(window, "STATIC", caption, 0, left, top + 3, 30, 16, -1);
    AmpEdit[channel] = panelControl(window, "EDIT", "", ES_AUTOHSCROLL, left + 40, top, 70, 20, IdAmpBase + channel);
    PhaseEdit[channel] = panelControl(window, "EDIT", "", ES_AUTOHSCROLL, left + 120, top, 70, 20, IdPhaseBase + channel);
    top += 24;
  }
  RotorBox = panelControl(window, "BUTTON", "Rotor model (1x of A0/A1 from the weights)", BS_AUTOCHECKBOX,
    left, top, 264, 20, IdRotorOn);
  top += 22;
  panelControl(window, "STATIC", "Weights on the rotor: g@deg; g@deg ...", 0, left, top, 264, 16, -1);
  top += 18;
  for (int plane = 0; plane < SIM_PLANES; plane++)
  {
    char caption[16];
    snprintf(caption, sizeof(caption), "Plane %d", plane + 1);
    panelControl(window, "STATIC", caption, 0, left, top + 3, 45, 16, -1);
    WeightsEdit[plane] = panelControl(window, "EDIT", "", ES_AUTOHSCROLL, left + 50, top, 210, 20, IdWeightsBase + plane);
    top += 24;
  }
  top += 4;
  panelControl(window, "BUTTON", "Apply", BS_PUSHBUTTON, left, top, 80, 24, IdApply);
  panelControl(window, "BUTTON", "ardsim.ini...", BS_PUSHBUTTON, left + 90, top, 100, 24, IdEditIni);
  top += 30;
  SignalInfo = panelControl(window, "STATIC", "", 0, left, top, 264, 16, IdSignalInfo);
  top += 18;
  RotorInfo = panelControl(window, "STATIC", "", 0, left, top, 264, 16, IdRotorInfo);
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
    createSignalPanel(window, keypadBottom + 76);
    IniPath = simExeDir() + "ardsim.ini";
    loadSignalIni(true);
    SerialEdit = CreateWindowExA(WS_EX_CLIENTEDGE, "EDIT", "",
      WS_CHILD | WS_VISIBLE | WS_VSCROLL | ES_MULTILINE | ES_AUTOVSCROLL | ES_READONLY,
      Margin, Margin * 2 + screenHeight(), screenWidth(), SerialHeight, window, (HMENU)IdSerial, nullptr, nullptr);
    SendMessageA(SerialEdit, WM_SETFONT, (WPARAM)GetStockObject(ANSI_FIXED_FONT), TRUE);
    SetTimer(window, 1, 33, nullptr);
    SetTimer(window, 2, 500, nullptr);
    return 0;
  }
  case WM_TIMER:
  {
    if (wParam == 2)
    {
      // ardsim.ini edited outside: take the new settings
      FILETIME current = iniWriteTime();
      if (CompareFileTime(&current, &IniTime) != 0)
        loadSignalIni(false);
      return 0;
    }
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
    if (HIWORD(wParam) == EN_SETFOCUS && isPanelEdit((HWND)lParam))
    {
      // the whole value is selected, so typing replaces it
      PostMessageA((HWND)lParam, EM_SETSEL, 0, -1);
      return 0;
    }
    if (id == IdApply || ((id == IdTachoOn || id == IdRotorOn) && HIWORD(wParam) == BN_CLICKED))
    {
      applyPanel();
      return 0;
    }
    if (id == IdEditIni)
    {
      ShellExecuteA(window, "open", "notepad.exe", IniPath.c_str(), nullptr, SW_SHOWNORMAL);
      return 0;
    }
    if (id >= IdKeyBase && id < IdKeyBase + SIM_KEY_ROWS * SIM_KEY_COLS)
    {
      simPostKey((id - IdKeyBase) / SIM_KEY_COLS, (id - IdKeyBase) % SIM_KEY_COLS, KeyHoldMs);
      SetFocus(window);
    }
    return 0;
  }
  case WM_LBUTTONDOWN:
    SetFocus(window);   // leave the panel edits: keys go to the keypad
    return 0;
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

  int clientHeight = Margin * 3 + screenHeight() + SerialHeight;
  if (clientHeight < 610)
    clientHeight = 610;   // room for the signal panel at x1
  RECT frame = {0, 0, keypadLeft() + 4 * (KeyWidth + KeyGap) + Margin, clientHeight};
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
    // typing in the signal panel: Enter applies, other keys go to the edit
    if (isPanelEdit(message.hwnd))
    {
      if (message.message == WM_KEYDOWN && message.wParam == VK_RETURN)
      {
        applyPanel();
        SetFocus(MainWindow);   // the keypad keys work again
        continue;
      }
      TranslateMessage(&message);
      DispatchMessageA(&message);
      continue;
    }
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
