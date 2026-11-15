// ArdSim: the simulator window when the exe runs on its own (without unIDE).
// Looks like the BS10 device: green case with the 480x320 screen, keypad
// panel with painted keys (mouse and PC keys). The signal panel and the
// Serial output are in a column on the right, shown by the "Signals" button.
// The sketch runs in its own thread (sim_core.cpp); this thread only reads
// its state.
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
static const int Margin = 8;
static const int IdSerial = 900;
static const int IdStatus = 901;
static const int IdSignalsToggle = 902;
static const int PanelWidth = 270;        // right column: signal panel, Serial

// Device geometry and colors - as the Emulator window of unIDE (ArdSimHost.pas):
// fractions of the screen width, the keypad 70% of the photo size
static const int BodyBorder = 40, RimWidth = 3;
static const double PadKMax = 0.7, PadWidthK = 1.22, PadTopK = 0.14, PadBottomK = 0.07;
static const double KeyWidthK = 0.23, KeyHeightK = 0.165, KeyPitchXK = 0.274, KeyPitchYK = 0.195;
static const COLORREF ClrRim = RGB(0x20, 0x20, 0x20), ClrBody = RGB(0x10, 0x9E, 0x7A),
  ClrPad = RGB(0x76, 0xD6, 0xB0), ClrBezel = RGB(0x30, 0x30, 0x30), ClrBack = RGB(0x40, 0x2C, 0x40),
  ClrKeyWhite = RGB(0xF2, 0xF2, 0xF2), ClrKeyYellow = RGB(0xFF, 0xD2, 0x1E),
  ClrKeyRed = RGB(0xDE, 0x3C, 0x46), ClrKeyText = RGB(0x30, 0x30, 0x30), ClrKeyEdge = RGB(0x80, 0x80, 0x80);
static const char *KeyCaptions[SIM_KEY_ROWS * SIM_KEY_COLS] = {
  "F1", "F2", "#", "*", "1", "2", "3", "^", "4", "5", "6", "v", "7", "8", "9", "Esc", "<", "0", ">", "Ent"};

static RECT BodyRect, ScreenRect, PadRect, KeyRects[SIM_KEY_ROWS * SIM_KEY_COLS];
static int DeviceWidth, DeviceHeight;
static int PressedKey = -1;
static bool SignalsShown = false;

static HWND MainWindow, SerialEdit, StatusText, SignalsButton;
static HWND PanelControls[64];
static int PanelControlCount = 0;

// Signal panel (generator settings, see sim_signal.cpp)
static const int IdTachoOn = 950, IdRpm = 951, IdApply = 952, IdEditIni = 953, IdSignalInfo = 954;
static const int IdAmpBase = 960, IdPhaseBase = 970;   // + channel 0/1
static const int PanelChannels = 2;                    // A0, A1 on the panel; the rest in the ini
static const int IdRotorOn = 955, IdRotorInfo = 956, IdWeightsBase = 980;   // + plane
static const int IdSdFail = 957;
static HWND SdFailBox;
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
static int panelLeft() { return DeviceWidth + Margin; }
static void convertScreen();

// Case on top (borders around the screen), keypad panel under it; padK - keypad
// size, smaller when the work area is low
static void arrangeDevice(double padK)
{
  int bodyW = screenWidth() + 2 * BodyBorder, bodyH = screenHeight() + 2 * BodyBorder;
  DeviceWidth = bodyW + 2 * Margin;
  BodyRect = {Margin, Margin, Margin + bodyW, Margin + bodyH};
  ScreenRect = {Margin + BodyBorder, Margin + BodyBorder, Margin + BodyBorder + screenWidth(),
                Margin + BodyBorder + screenHeight()};
  int padUnit = (int)(screenWidth() * padK + 0.5);
  int keyW = (int)(padUnit * KeyWidthK + 0.5), keyH = (int)(padUnit * KeyHeightK + 0.5);
  int pitchX = (int)(padUnit * KeyPitchXK + 0.5), pitchY = (int)(padUnit * KeyPitchYK + 0.5);
  int gridW = 3 * pitchX + keyW;
  int padW = (int)(padUnit * PadWidthK + 0.5);
  if (padW < gridW + 16) padW = gridW + 16;
  int padLeft = Margin + (bodyW - padW) / 2;
  int gridTop = BodyRect.bottom + (int)(padUnit * PadTopK + 0.5);
  int gridLeft = padLeft + (padW - gridW) / 2;
  PadRect = {padLeft, BodyRect.bottom - RimWidth, padLeft + padW,
             gridTop + 4 * pitchY + keyH + (int)(padUnit * PadBottomK + 0.5)};
  for (int row = 0; row < SIM_KEY_ROWS; row++)
    for (int col = 0; col < SIM_KEY_COLS; col++)
      KeyRects[row * SIM_KEY_COLS + col] = {gridLeft + col * pitchX, gridTop + row * pitchY,
                                            gridLeft + col * pitchX + keyW, gridTop + row * pitchY + keyH};
  DeviceHeight = PadRect.bottom + Margin;
}

static COLORREF darker(COLORREF color, int shift)
{
  int red = GetRValue(color) - shift, green = GetGValue(color) - shift, blue = GetBValue(color) - shift;
  return RGB(red < 0 ? 0 : red, green < 0 ? 0 : green, blue < 0 ? 0 : blue);
}

// One key: color and shape as on the device, arrows as triangles
static void drawKey(HDC context, int keyIdx)
{
  RECT area = KeyRects[keyIdx];
  int keyW = area.right - area.left, keyH = area.bottom - area.top;
  bool oval = keyIdx == 15 || keyIdx == 19;
  COLORREF fill = ClrKeyWhite;
  if (keyIdx == 0 || keyIdx == 1) fill = ClrKeyYellow;
  else if (keyIdx == 2 || keyIdx == 3 || oval) fill = ClrKeyRed;
  if (keyIdx == PressedKey) fill = darker(fill, 70);
  COLORREF textColor = oval ? RGB(255, 255, 255) : ClrKeyText;
  HBRUSH brush = CreateSolidBrush(fill);
  HPEN pen = CreatePen(PS_SOLID, 1, oval ? darker(fill, 40) : ClrKeyEdge);
  HGDIOBJ oldBrush = SelectObject(context, brush), oldPen = SelectObject(context, pen);
  if (oval)
    Ellipse(context, area.left, area.top, area.right, area.bottom);
  else
    RoundRect(context, area.left, area.top, area.right, area.bottom, keyH / 4, keyH / 4);
  SelectObject(context, oldBrush);
  SelectObject(context, oldPen);
  DeleteObject(brush);
  DeleteObject(pen);

  int midX = (area.left + area.right) / 2, midY = (area.top + area.bottom) / 2;
  int arrowDir = keyIdx == 7 ? 0 : keyIdx == 11 ? 1 : keyIdx == 16 ? 2 : keyIdx == 18 ? 3 : -1;
  if (arrowDir >= 0)
  {
    int half = keyH / 5;
    POINT arrow[3];
    if (arrowDir == 0) { arrow[0] = {midX, midY - half}; arrow[1] = {midX - half, midY + half}; arrow[2] = {midX + half, midY + half}; }
    else if (arrowDir == 1) { arrow[0] = {midX, midY + half}; arrow[1] = {midX - half, midY - half}; arrow[2] = {midX + half, midY - half}; }
    else if (arrowDir == 2) { arrow[0] = {midX - half, midY}; arrow[1] = {midX + half, midY - half}; arrow[2] = {midX + half, midY + half}; }
    else { arrow[0] = {midX + half, midY}; arrow[1] = {midX - half, midY - half}; arrow[2] = {midX - half, midY + half}; }
    HBRUSH arrowBrush = CreateSolidBrush(textColor);
    HPEN arrowPen = CreatePen(PS_SOLID, 1, textColor);
    oldBrush = SelectObject(context, arrowBrush);
    oldPen = SelectObject(context, arrowPen);
    Polygon(context, arrow, 3);
    SelectObject(context, oldBrush);
    SelectObject(context, oldPen);
    DeleteObject(arrowBrush);
    DeleteObject(arrowPen);
    return;
  }
  const char *caption = KeyCaptions[keyIdx];
  int fontH = keyH * 11 / 20;
  SIZE size;
  HFONT font = nullptr;
  for (int attempt = 0; attempt < 2; attempt++)
  {
    font = CreateFontA(-fontH, 0, 0, 0, FW_BOLD, 0, 0, 0, DEFAULT_CHARSET, 0, 0, ANTIALIASED_QUALITY, 0, "Arial");
    HGDIOBJ oldFont = SelectObject(context, font);
    GetTextExtentPoint32A(context, caption, (int)strlen(caption), &size);
    SelectObject(context, oldFont);
    // wide captions (Esc, Ent) smaller, to fit into the oval
    if (attempt == 0 && size.cx > keyW * 4 / 5)
    {
      fontH = fontH * (keyW * 4 / 5) / size.cx;
      DeleteObject(font);
      continue;
    }
    break;
  }
  HGDIOBJ oldFont = SelectObject(context, font);
  SetBkMode(context, TRANSPARENT);
  SetTextColor(context, textColor);
  TextOutA(context, midX - size.cx / 2, midY - size.cy / 2, caption, (int)strlen(caption));
  SelectObject(context, oldFont);
  DeleteObject(font);
}

static void paintDevice(HDC context, const RECT &client)
{
  HBRUSH back = CreateSolidBrush(ClrBack);
  FillRect(context, &client, back);
  DeleteObject(back);
  HPEN rim = CreatePen(PS_SOLID, RimWidth, ClrRim);
  HGDIOBJ oldPen = SelectObject(context, rim);
  HBRUSH pad = CreateSolidBrush(ClrPad);
  HGDIOBJ oldBrush = SelectObject(context, pad);
  int corner = (PadRect.right - PadRect.left) / 6;
  RoundRect(context, PadRect.left + 1, PadRect.top + 1, PadRect.right - 1, PadRect.bottom - 1, corner, corner);
  HBRUSH body = CreateSolidBrush(ClrBody);
  SelectObject(context, body);
  corner = BodyBorder * 4;
  RoundRect(context, BodyRect.left + 1, BodyRect.top + 1, BodyRect.right - 1, BodyRect.bottom - 1, corner, corner);
  SelectObject(context, oldPen);
  SelectObject(context, oldBrush);
  DeleteObject(rim);
  DeleteObject(pad);
  DeleteObject(body);
  RECT bezel = {ScreenRect.left - 3, ScreenRect.top - 3, ScreenRect.right + 3, ScreenRect.bottom + 3};
  HBRUSH bezelBrush = CreateSolidBrush(ClrBezel);
  FillRect(context, &bezel, bezelBrush);
  DeleteObject(bezelBrush);
  convertScreen();
  SetStretchBltMode(context, COLORONCOLOR);
  StretchDIBits(context, ScreenRect.left, ScreenRect.top, screenWidth(), screenHeight(), 0, 0,
    SIM_SCREEN_W, SIM_SCREEN_H, Pixels, &PixelInfo, DIB_RGB_COLORS, SRCCOPY);
  for (int keyIdx = 0; keyIdx < SIM_KEY_ROWS * SIM_KEY_COLS; keyIdx++)
    drawKey(context, keyIdx);
}

static void invalidateKey(int keyIdx)
{
  if (keyIdx >= 0)
    InvalidateRect(MainWindow, &KeyRects[keyIdx], FALSE);
}

// Key pressed (mouse or PC key): to the sketch and darker for a moment
static void pressKey(int row, int col)
{
  simPostKey(row, col, KeyHoldMs);
  invalidateKey(PressedKey);
  PressedKey = row * SIM_KEY_COLS + col;
  invalidateKey(PressedKey);
  SetTimer(MainWindow, 3, 150, nullptr);
}

static int clientWidth() { return DeviceWidth + (SignalsShown ? PanelWidth + Margin * 2 : 0); }
static int clientHeight()
{
  return DeviceHeight;
}

static void resizeForSignals()
{
  for (int index = 0; index < PanelControlCount; index++)
    ShowWindow(PanelControls[index], SignalsShown ? SW_SHOW : SW_HIDE);
  SetWindowTextA(SignalsButton, SignalsShown ? "Signals <<" : "Signals >>");
  RECT frame = {0, 0, clientWidth(), clientHeight()};
  AdjustWindowRect(&frame, (DWORD)GetWindowLongA(MainWindow, GWL_STYLE), FALSE);
  SetWindowPos(MainWindow, nullptr, 0, 0, frame.right - frame.left, frame.bottom - frame.top,
    SWP_NOMOVE | SWP_NOZORDER);
}

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
  if (!SignalsShown)
    return;
  int pixelX = (mouseX - ScreenRect.left) / Scale;
  int pixelY = (mouseY - ScreenRect.top) / Scale;
  if (mouseX < ScreenRect.left || mouseY < ScreenRect.top)
    pixelX = -1;
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
  SendMessageA(SdFailBox, BM_SETCHECK, SignalConfig.SdFail ? BST_CHECKED : BST_UNCHECKED, 0);
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
  SignalConfig.SdFail = SendMessageA(SdFailBox, BM_GETCHECK, 0, 0) == BST_CHECKED;
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
    WS_CHILD | style, left, top, width, height, parent, (HMENU)(INT_PTR)id, nullptr, nullptr);
  SendMessageA(control, WM_SETFONT, (WPARAM)GetStockObject(DEFAULT_GUI_FONT), TRUE);
  if (PanelControlCount < (int)(sizeof(PanelControls) / sizeof(PanelControls[0])))
    PanelControls[PanelControlCount++] = control;
  return control;
}

static void createSignalPanel(HWND window, int top)
{
  int left = panelLeft();
  panelControl(window, "STATIC", "Signals (A0, A1: 1st harmonic; all in ardsim.ini)", 0, left, top, 264, 16, -1);
  top += 20;
  TachoBox = panelControl(window, "BUTTON", "Tacho", BS_AUTOCHECKBOX, left, top, 60, 20, IdTachoOn);
  panelControl(window, "STATIC", "RPM", 0, left + 70, top + 3, 30, 16, -1);
  RpmEdit = panelControl(window, "EDIT", "", ES_AUTOHSCROLL, left + 100, top, 70, 20, IdRpm);
  SdFailBox = panelControl(window, "BUTTON", "No SD card", BS_AUTOCHECKBOX, left + 180, top, 84, 20, IdSdFail);
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
    MainWindow = window;
    HFONT guiFont = (HFONT)GetStockObject(DEFAULT_GUI_FONT);
    // left of the keypad panel, under the case
    SignalsButton = CreateWindowA("BUTTON", "Signals >>", WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
      BodyRect.left + 4, BodyRect.bottom + 8, PadRect.left - BodyRect.left - 10, 24, window,
      (HMENU)(INT_PTR)IdSignalsToggle, nullptr, nullptr);
    SendMessageA(SignalsButton, WM_SETFONT, (WPARAM)guiFont, TRUE);
    int top = Margin;
    panelControl(window, "STATIC", "PC keys: 0-9, F1, F2, #, *, arrows, Enter, Esc", 0,
      panelLeft(), top, PanelWidth, 16, -1);
    top += 20;
    StatusText = panelControl(window, "STATIC", "", 0, panelLeft(), top, PanelWidth, 16, IdStatus);
    top += 24;
    createSignalPanel(window, top);
    IniPath = simExeDir() + "ardsim.ini";
    loadSignalIni(true);
    top += 290;
    SerialEdit = CreateWindowExA(WS_EX_CLIENTEDGE, "EDIT", "",
      WS_CHILD | WS_VSCROLL | ES_MULTILINE | ES_AUTOVSCROLL | ES_READONLY,
      panelLeft(), top, PanelWidth, DeviceHeight - top - Margin, window, (HMENU)IdSerial, nullptr, nullptr);
    SendMessageA(SerialEdit, WM_SETFONT, (WPARAM)GetStockObject(ANSI_FIXED_FONT), TRUE);
    PanelControls[PanelControlCount++] = SerialEdit;
    SetTimer(window, 1, 33, nullptr);
    SetTimer(window, 2, 500, nullptr);
    return 0;
  }
  case WM_ERASEBKGND:
    return 1;
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
    if (wParam == 3)
    {
      KillTimer(window, 3);
      int released = PressedKey;
      PressedKey = -1;
      invalidateKey(released);
      return 0;
    }
    if (SimScreenVersion != ShownVersion)
    {
      ShownVersion = SimScreenVersion;
      InvalidateRect(window, &ScreenRect, FALSE);
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
    RECT client = {0, 0, DeviceWidth, DeviceHeight};
    HDC memory = CreateCompatibleDC(context);
    HBITMAP bitmap = CreateCompatibleBitmap(context, client.right, client.bottom);
    HGDIOBJ oldBitmap = SelectObject(memory, bitmap);
    paintDevice(memory, client);
    BitBlt(context, 0, 0, client.right, client.bottom, memory, 0, 0, SRCCOPY);
    SelectObject(memory, oldBitmap);
    DeleteObject(bitmap);
    DeleteDC(memory);
    // right column background (behind the panel controls)
    RECT column = {DeviceWidth, 0, DeviceWidth + PanelWidth + Margin * 2, DeviceHeight};
    FillRect(context, &column, (HBRUSH)(COLOR_BTNFACE + 1));
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
    if (id == IdSignalsToggle)
    {
      SignalsShown = !SignalsShown;
      resizeForSignals();
      SetFocus(window);
      return 0;
    }
    if (id == IdApply || ((id == IdTachoOn || id == IdRotorOn || id == IdSdFail) && HIWORD(wParam) == BN_CLICKED))
    {
      applyPanel();
      return 0;
    }
    if (id == IdEditIni)
    {
      ShellExecuteA(window, "open", "notepad.exe", IniPath.c_str(), nullptr, SW_SHOWNORMAL);
      return 0;
    }
    return 0;
  }
  case WM_LBUTTONDOWN:
  {
    SetFocus(window);   // leave the panel edits: keys go to the keypad
    POINT point = {(short)LOWORD(lParam), (short)HIWORD(lParam)};
    for (int keyIdx = 0; keyIdx < SIM_KEY_ROWS * SIM_KEY_COLS; keyIdx++)
      if (PtInRect(&KeyRects[keyIdx], point))
      {
        pressKey(keyIdx / SIM_KEY_COLS, keyIdx % SIM_KEY_COLS);
        break;
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
  // /host:<name> - no window, the screen goes to the host (sim_host.cpp)
  if (const char *hostArg = strstr(GetCommandLineA(), "/host:"))
  {
    std::string hostName(hostArg + 6);
    size_t nameEnd = hostName.find_first_of(" \t\"");
    if (nameEnd != std::string::npos)
      hostName.resize(nameEnd);
    return simHostRun(hostName.c_str());
  }
  // screen 1:1 (/x2 - twice, if the work area has room); the keypad is made
  // smaller when the device does not fit the work area height
  RECT work;
  SystemParametersInfoA(SPI_GETWORKAREA, 0, &work, 0);
  int workH = work.bottom - work.top - GetSystemMetrics(SM_CYCAPTION) - 2 * GetSystemMetrics(SM_CYFIXEDFRAME) - 8;
  Scale = 1;
  if (strstr(GetCommandLineA(), "/x2"))
  {
    Scale = 2;
    arrangeDevice(PadKMax * 2);
    if (DeviceHeight > workH)
      Scale = 1;
  }
  double padK = PadKMax * Scale;
  arrangeDevice(padK);
  while (DeviceHeight > workH && padK > 0.3 * Scale)
  {
    padK -= 0.02 * Scale;
    arrangeDevice(padK);
  }

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
  windowClass.hbrBackground = nullptr;
  windowClass.lpszClassName = "ArdSimWindow";
  RegisterClassA(&windowClass);

  RECT frame = {0, 0, clientWidth(), clientHeight()};
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
        pressKey(row, col);
        continue;
      }
    }
    if (message.message == WM_CHAR && (message.wParam == '#' || message.wParam == '*'))
    {
      pressKey(0, message.wParam == '#' ? 2 : 3);
      continue;
    }
    TranslateMessage(&message);
    DispatchMessageA(&message);
  }
  // the sketch thread may be inside a long computation: do not wait for it
  ExitProcess(0);
  return 0;
}
