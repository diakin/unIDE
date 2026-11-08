// ArdSim: UTFT drawing into SimScreen (RGB565). Pixel rules follow the
// UTFT library: inclusive rectangles, the same rounded corners, circles
// and the font format (x size, y size, first char, count; rows MSB first).
#include "UTFT.h"
#include "sim_internal.h"
#include <cstring>
#include <cstdio>

uint16_t SimScreen[SIM_SCREEN_H][SIM_SCREEN_W];
volatile uint32_t SimScreenVersion = 0;
volatile double SimLcdPixelNs = 400;

// Drawing time of the real display: every pixel costs SimLcdPixelNs; the
// sketch thread waits for the accumulated time (with simPoll, so timer
// ticks go on). Without it a screen is drawn in no time and, for
// example, a key code read by the 50 ms keypad timer is still there when
// the next screen starts waiting for a key.
static double LcdDebtNs = 0;

static inline void lcdPixels(double count)
{
  LcdDebtNs += count * SimLcdPixelNs;
}

static void lcdDone()
{
  SimScreenVersion++;
  if (LcdDebtNs < 200000)       // pay in portions of 0.2 ms and more
    return;
  uint64_t until = simMicrosNow() + (uint64_t)(LcdDebtNs / 1000);
  LcdDebtNs = 0;
  while (simMicrosNow() < until)
    simPoll();
}

UTFT::UTFT() : FrontColor(0xFFFF), BackColor(0), Transparent(false), Font(nullptr), Orient(LANDSCAPE) {}

UTFT::UTFT(byte model, int rs, int wr, int cs, int rst, int ser)
  : FrontColor(0xFFFF), BackColor(0), Transparent(false), Font(nullptr), Orient(LANDSCAPE)
{
  (void)model; (void)rs; (void)wr; (void)cs; (void)rst; (void)ser;
}

// 480x320 landscape; the orientation number only flips the panel on the
// device (InitLCD(1) / InitLCD(3)), the picture for the user is the same
void UTFT::InitLCD(byte orientation)
{
  Orient = orientation;
  clrScr();
}

int UTFT::getDisplayXSize() { return SIM_SCREEN_W; }
int UTFT::getDisplayYSize() { return SIM_SCREEN_H; }

void UTFT::putPixel(int x, int y, word color)
{
  if (x < 0 || y < 0 || x >= SIM_SCREEN_W || y >= SIM_SCREEN_H)
    return;
  SimScreen[y][x] = color;
  SimOwnerMap[y][x] = SimPixelOwner;
  lcdPixels(1);
}

void UTFT::hLine(int x, int y, int length)
{
  if (length < 0)
  {
    length = -length;
    x -= length;
  }
  for (int index = 0; index <= length; index++)
    putPixel(x + index, y, FrontColor);
  lcdDone();
}

void UTFT::vLine(int x, int y, int length)
{
  if (length < 0)
  {
    length = -length;
    y -= length;
  }
  for (int index = 0; index <= length; index++)
    putPixel(x, y + index, FrontColor);
  lcdDone();
}

void UTFT::clrScr()
{
  simPoll();
  SimScreenClears++;
  memset(SimScreen, 0, sizeof(SimScreen));
  memset(SimOwnerMap, 0, sizeof(SimOwnerMap));
  simAreaFilled(0, 0, SIM_SCREEN_W - 1, SIM_SCREEN_H - 1);
  lcdPixels(SIM_SCREEN_W * SIM_SCREEN_H);
  lcdDone();
}

void UTFT::fillScr(byte red, byte green, byte blue)
{
  fillScr((word)(((red & 0xF8) << 8) | ((green & 0xFC) << 3) | (blue >> 3)));
}

void UTFT::fillScr(word color)
{
  simPoll();
  SimScreenClears++;
  for (int y = 0; y < SIM_SCREEN_H; y++)
    for (int x = 0; x < SIM_SCREEN_W; x++)
      SimScreen[y][x] = color;
  memset(SimOwnerMap, 0, sizeof(SimOwnerMap));
  simAreaFilled(0, 0, SIM_SCREEN_W - 1, SIM_SCREEN_H - 1);
  lcdPixels(SIM_SCREEN_W * SIM_SCREEN_H);
  lcdDone();
}

void UTFT::drawPixel(int x, int y)
{
  simGraphicDrawn(x, y, x, y, false);
  putPixel(x, y, FrontColor);
  lcdDone();
}

void UTFT::drawLine(int x1, int y1, int x2, int y2)
{
  simPoll();
  simGraphicDrawn(x1, y1, x2, y2, false);
  if (y1 == y2)
  {
    if (x1 > x2)
    {
      int temp = x1; x1 = x2; x2 = temp;
    }
    hLine(x1, y1, x2 - x1);
    return;
  }
  if (x1 == x2)
  {
    if (y1 > y2)
    {
      int temp = y1; y1 = y2; y2 = temp;
    }
    vLine(x1, y1, y2 - y1);
    return;
  }
  int deltaX = x2 > x1 ? x2 - x1 : x1 - x2;
  int deltaY = y2 > y1 ? y2 - y1 : y1 - y2;
  int stepX = x1 < x2 ? 1 : -1;
  int stepY = y1 < y2 ? 1 : -1;
  int error = deltaX - deltaY;
  for (;;)
  {
    putPixel(x1, y1, FrontColor);
    if (x1 == x2 && y1 == y2)
      break;
    int doubled = 2 * error;
    if (doubled > -deltaY)
    {
      error -= deltaY;
      x1 += stepX;
    }
    if (doubled < deltaX)
    {
      error += deltaX;
      y1 += stepY;
    }
  }
  lcdDone();
}

static void orderRect(int &x1, int &y1, int &x2, int &y2)
{
  if (x1 > x2)
  {
    int temp = x1; x1 = x2; x2 = temp;
  }
  if (y1 > y2)
  {
    int temp = y1; y1 = y2; y2 = temp;
  }
}

void UTFT::drawRect(int x1, int y1, int x2, int y2)
{
  simPoll();
  orderRect(x1, y1, x2, y2);
  simGraphicDrawn(x1, y1, x2, y2, false);
  hLine(x1, y1, x2 - x1);
  hLine(x1, y2, x2 - x1);
  vLine(x1, y1, y2 - y1);
  vLine(x2, y1, y2 - y1);
}

void UTFT::drawRoundRect(int x1, int y1, int x2, int y2)
{
  simPoll();
  orderRect(x1, y1, x2, y2);
  if ((x2 - x1) > 4 && (y2 - y1) > 4)
  {
    simGraphicDrawn(x1, y1, x2, y2, false);
    putPixel(x1 + 1, y1 + 1, FrontColor);
    putPixel(x2 - 1, y1 + 1, FrontColor);
    putPixel(x1 + 1, y2 - 1, FrontColor);
    putPixel(x2 - 1, y2 - 1, FrontColor);
    hLine(x1 + 2, y1, x2 - x1 - 4);
    hLine(x1 + 2, y2, x2 - x1 - 4);
    vLine(x1, y1 + 2, y2 - y1 - 4);
    vLine(x2, y1 + 2, y2 - y1 - 4);
  }
}

void UTFT::fillRect(int x1, int y1, int x2, int y2)
{
  simPoll();
  orderRect(x1, y1, x2, y2);
  simGraphicDrawn(x1, y1, x2, y2, true);
  for (int y = y1; y <= y2; y++)
    for (int x = x1; x <= x2; x++)
      putPixel(x, y, FrontColor);
  lcdDone();
}

void UTFT::fillRoundRect(int x1, int y1, int x2, int y2)
{
  simPoll();
  orderRect(x1, y1, x2, y2);
  if ((x2 - x1) > 4 && (y2 - y1) > 4)
  {
    simGraphicDrawn(x1, y1, x2, y2, true);
    for (int row = 0; row < ((y2 - y1) / 2) + 1; row++)
    {
      switch (row)
      {
      case 0:
        hLine(x1 + 2, y1 + row, x2 - x1 - 4);
        hLine(x1 + 2, y2 - row, x2 - x1 - 4);
        break;
      case 1:
        hLine(x1 + 1, y1 + row, x2 - x1 - 2);
        hLine(x1 + 1, y2 - row, x2 - x1 - 2);
        break;
      default:
        hLine(x1, y1 + row, x2 - x1);
        hLine(x1, y2 - row, x2 - x1);
      }
    }
  }
}

void UTFT::drawCircle(int x, int y, int radius)
{
  simPoll();
  simGraphicDrawn(x - radius, y - radius, x + radius, y + radius, false);
  int balance = 1 - radius;
  int deltaX = 1;
  int deltaY = -2 * radius;
  int offsetX = 0;
  int offsetY = radius;
  putPixel(x, y + radius, FrontColor);
  putPixel(x, y - radius, FrontColor);
  putPixel(x + radius, y, FrontColor);
  putPixel(x - radius, y, FrontColor);
  while (offsetX < offsetY)
  {
    if (balance >= 0)
    {
      offsetY--;
      deltaY += 2;
      balance += deltaY;
    }
    offsetX++;
    deltaX += 2;
    balance += deltaX;
    putPixel(x + offsetX, y + offsetY, FrontColor);
    putPixel(x - offsetX, y + offsetY, FrontColor);
    putPixel(x + offsetX, y - offsetY, FrontColor);
    putPixel(x - offsetX, y - offsetY, FrontColor);
    putPixel(x + offsetY, y + offsetX, FrontColor);
    putPixel(x - offsetY, y + offsetX, FrontColor);
    putPixel(x + offsetY, y - offsetX, FrontColor);
    putPixel(x - offsetY, y - offsetX, FrontColor);
  }
  lcdDone();
}

void UTFT::fillCircle(int x, int y, int radius)
{
  simPoll();
  simGraphicDrawn(x - radius, y - radius, x + radius, y + radius, true);
  for (int offsetY = -radius; offsetY <= 0; offsetY++)
    for (int offsetX = -radius; offsetX <= 0; offsetX++)
      if (offsetX * offsetX + offsetY * offsetY <= radius * radius)
      {
        hLine(x + offsetX, y + offsetY, 2 * (-offsetX));
        hLine(x + offsetX, y - offsetY, 2 * (-offsetX));
        break;
      }
}

void UTFT::setColor(byte red, byte green, byte blue)
{
  FrontColor = (word)(((red & 0xF8) << 8) | ((green & 0xFC) << 3) | (blue >> 3));
}

void UTFT::setColor(word color) { FrontColor = color; }
word UTFT::getColor() { return FrontColor; }

void UTFT::setBackColor(byte red, byte green, byte blue)
{
  BackColor = (word)(((red & 0xF8) << 8) | ((green & 0xFC) << 3) | (blue >> 3));
  Transparent = false;
}

void UTFT::setBackColor(uint32_t color)
{
  if (color == VGA_TRANSPARENT)
    Transparent = true;
  else
  {
    BackColor = (word)color;
    Transparent = false;
  }
}

word UTFT::getBackColor() { return BackColor; }

void UTFT::setFont(uint8_t *font) { Font = font; }
uint8_t *UTFT::getFont() { return Font; }
uint8_t UTFT::getFontXsize() { return Font ? Font[0] : 0; }
uint8_t UTFT::getFontYsize() { return Font ? Font[1] : 0; }

void UTFT::printChar(byte character, int x, int y)
{
  SimPixelOwner = 0;   // text pixels: the text entry answers for them
  simPoll();
  if (!Font)
    return;
  int sizeX = Font[0];
  int sizeY = Font[1];
  int first = Font[2];
  int count = Font[3];
  int bytesPerRow = sizeX / 8;
  if (character < first || character >= first + count)
  {
    // UTFT would read past the table; here - an empty cell
    if (!Transparent)
      for (int row = 0; row < sizeY; row++)
        for (int col = 0; col < sizeX; col++)
          putPixel(x + col, y + row, BackColor);
    lcdDone();
    return;
  }
  const uint8_t *glyph = Font + 4 + (character - first) * bytesPerRow * sizeY;
  for (int row = 0; row < sizeY; row++)
    for (int part = 0; part < bytesPerRow; part++)
    {
      uint8_t bits = glyph[row * bytesPerRow + part];
      for (int bit = 0; bit < 8; bit++)
      {
        bool set = (bits & (0x80 >> bit)) != 0;
        if (set)
          putPixel(x + part * 8 + bit, y + row, FrontColor);
        else if (!Transparent)
          putPixel(x + part * 8 + bit, y + row, BackColor);
      }
    }
  lcdDone();
}

void UTFT::print(const char *text, int x, int y, int deg)
{
  (void)deg;
  if (!text || !Font)
    return;
  int length = (int)strlen(text);
  int sizeX = Font[0];
  if (x == RIGHT)
    x = SIM_SCREEN_W - length * sizeX;
  else if (x == CENTER)
    x = (SIM_SCREEN_W - length * sizeX) / 2;
  for (int index = 0; index < length; index++)
    printChar((byte)text[index], x + index * sizeX, y);
  if (length > 0)
    simTextDrawn(x, y, x + length * sizeX - 1, y + Font[1] - 1, text);
}

void UTFT::print(const String &text, int x, int y, int deg)
{
  print(text.c_str(), x, y, deg);
}

void UTFT::printNumI(long number, int x, int y, int length, char filler)
{
  char digits[32];
  snprintf(digits, sizeof(digits), "%ld", number);
  std::string text(digits);
  if (length > 0 && (int)text.size() < length)
  {
    bool negative = number < 0;
    std::string body = negative ? text.substr(1) : text;
    std::string pad((size_t)(length - (int)text.size()), filler);
    // UTFT: with '0' the sign goes first, then the zeros
    if (negative && filler == '0')
      text = "-" + pad + body;
    else
      text = pad + text;
  }
  print(text.c_str(), x, y);
}

void UTFT::printNumF(double number, byte decimals, int x, int y, char divider,
                     int length, char filler)
{
  char digits[64];
  snprintf(digits, sizeof(digits), "%.*f", (int)decimals, number);
  for (char *ptr = digits; *ptr; ptr++)
    if (*ptr == '.')
      *ptr = divider;
  std::string text(digits);
  if (length > 0 && (int)text.size() < length)
    text = std::string((size_t)(length - (int)text.size()), filler) + text;
  print(text.c_str(), x, y);
}

void UTFT::drawBitmap(int x, int y, int sx, int sy, bitmapdatatype data, int scale)
{
  (void)data;
  // Single color value overload of the original is not used for images
  (void)x; (void)y; (void)sx; (void)sy; (void)scale;
}

void UTFT::drawBitmap(int x, int y, int sx, int sy, const uint16_t *data, int scale)
{
  simPoll();
  if (!data)
    return;
  if (scale < 1)
    scale = 1;
  simGraphicDrawn(x, y, x + sx * scale - 1, y + sy * scale - 1, true);
  for (int row = 0; row < sy; row++)
    for (int col = 0; col < sx; col++)
    {
      uint16_t color = data[row * sx + col];
      for (int dy = 0; dy < scale; dy++)
        for (int dx = 0; dx < scale; dx++)
          putPixel(x + col * scale + dx, y + row * scale + dy, color);
    }
  lcdDone();
}
