// ArdSim: UTFT drawing into SimScreen (RGB565). Pixel rules follow the
// UTFT library: inclusive rectangles, the same rounded corners, circles
// and the font format (x size, y size, first char, count; rows MSB first).
#include "UTFT.h"
#include "sim_internal.h"
#include <cstring>
#include <cstdio>
#include <vector>

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

// ---- drawing log: every top-level drawing call since the last clrScr /
// fillScr, with the colors and font it used and the control (TLabel) that
// drew it. A control moved or changed from unIDE is drawn again over the
// screen replayed without its last drawing, so what lay under it comes
// back (simScreenRestoreWithout). Entries covered by a later opaque area
// are dropped when the log grows; if it still does not fit, the log stops
// until the next clear and the restore answers false.
namespace
{
enum DrawKind
{
  dkPixel, dkLine, dkRect, dkRoundRect, dkFillRect, dkFillRoundRect, dkCircle,
  dkFillCircle, dkChar, dkPrint, dkBitmap, dkHLine, dkVLine
};
struct DrawOp
{
  uint8_t Kind;
  UTFT *Obj;
  int Args[4];
  word Fore, Back;
  bool Transparent;
  uint8_t *Font;
  std::string Text;
  const uint16_t *Data;
  int Scale;
  const void *Ctl;       // control drawing it, null - the sketch itself
  uint32_t CtlSeq;       // which drawing of the control
  int CtlLeft, CtlTop;   // Left, Top of the control in that drawing (simDrawCtlEnd)
  bool CtlPlaced;        // CtlLeft, CtlTop known
  uint32_t Seq;
  uint32_t Owner;        // SimPixelOwner of its pixels
  int X1, Y1, X2, Y2;    // pixels it may touch
  bool Opaque;           // all pixels of the box written
};
std::vector<DrawOp> DrawLog;
word DrawLogBase = 0;            // fillScr color, black after clrScr
bool DrawLogOverflow = false;
int DrawDepth = 0;               // > 0 - inside a recorded call
uint32_t DrawSeqCounter = 0;
bool Replaying = false;
const size_t DrawLogCompactAt = 20000;
const size_t DrawLogMax = 60000;
const void *DrawCtl = nullptr;
uint32_t DrawCtlSeq = 0, DrawCtlCounter = 0;

bool inside(const DrawOp &op, const DrawOp &cover)
{
  return op.X1 >= cover.X1 && op.Y1 >= cover.Y1 && op.X2 <= cover.X2 && op.Y2 <= cover.Y2;
}

// drop entries wholly under a later opaque entry (the last 64 such)
void compactLog()
{
  std::vector<const DrawOp *> covers;
  std::vector<bool> keep(DrawLog.size(), true);
  for (size_t index = DrawLog.size(); index-- > 0;)
  {
    const DrawOp &op = DrawLog[index];
    for (const DrawOp *cover : covers)
      if (inside(op, *cover))
      {
        keep[index] = false;
        break;
      }
    if (keep[index] && op.Opaque)
    {
      covers.push_back(&op);
      if (covers.size() > 64)
        covers.erase(covers.begin());
    }
  }
  std::vector<DrawOp> kept;
  kept.reserve(DrawLog.size());
  for (size_t index = 0; index < DrawLog.size(); index++)
    if (keep[index])
      kept.push_back(DrawLog[index]);
  DrawLog.swap(kept);
}

void clearLog(word base)
{
  DrawLog.clear();
  DrawLogBase = base;
  DrawLogOverflow = false;
}

// one recorded call: the entry is added when the outermost drawing call
// starts; nested calls (drawRect -> hLine, print -> printChar) are not
struct DrawScope
{
  bool Recorded;
  uint32_t Seq;
  DrawScope(UTFT *obj, word fore, word back, bool transparent, uint8_t *font, uint8_t kind,
            int arg0, int arg1, int arg2, int arg3, int x1, int y1, int x2, int y2, bool opaque,
            const char *text = nullptr, const uint16_t *data = nullptr, int scale = 1)
    : Recorded(false), Seq(0)
  {
    if (Replaying || DrawDepth++ > 0 || DrawLogOverflow)
      return;
    DrawOp op;
    op.Kind = kind;
    op.Obj = obj;
    op.Args[0] = arg0; op.Args[1] = arg1; op.Args[2] = arg2; op.Args[3] = arg3;
    op.Fore = fore; op.Back = back; op.Transparent = transparent; op.Font = font;
    if (text)
      op.Text = text;
    op.Data = data;
    op.Scale = scale;
    op.Ctl = DrawCtl;
    op.CtlSeq = DrawCtlSeq;
    op.CtlLeft = op.CtlTop = 0;
    op.CtlPlaced = false;
    op.Seq = Seq = ++DrawSeqCounter;
    op.Owner = 0;
    op.X1 = x1 < x2 ? x1 : x2; op.X2 = x1 < x2 ? x2 : x1;
    op.Y1 = y1 < y2 ? y1 : y2; op.Y2 = y1 < y2 ? y2 : y1;
    op.Opaque = opaque;
    if (DrawLog.size() >= DrawLogCompactAt)
      compactLog();
    if (DrawLog.size() >= DrawLogMax)
    {
      DrawLogOverflow = true;
      return;
    }
    DrawLog.push_back(op);
    Recorded = true;
  }
  ~DrawScope()
  {
    if (Replaying)
      return;
    DrawDepth--;
    if (!Recorded)
      return;
    // a redraw from simPoll may have removed entries meanwhile
    for (size_t index = DrawLog.size(); index-- > 0;)
      if (DrawLog[index].Seq == Seq)
      {
        DrawLog[index].Owner = SimPixelOwner;
        break;
      }
  }
};

inline void drawPoll()
{
  if (!Replaying)
    simPoll();
}
}

void simDrawCtlBegin(const void *control)
{
  DrawCtl = control;
  DrawCtlSeq = ++DrawCtlCounter;
}

void simDrawCtlEnd(int left, int top)
{
  // the entries of this drawing get the place of the control
  if (DrawCtl)
    for (size_t index = DrawLog.size(); index-- > 0;)
    {
      DrawOp &op = DrawLog[index];
      if (op.Ctl == DrawCtl && op.CtlSeq == DrawCtlSeq)
      {
        op.CtlLeft = left;
        op.CtlTop = top;
        op.CtlPlaced = true;
      }
      else if (op.Ctl == nullptr || op.CtlSeq < DrawCtlSeq)
        break;
    }
  DrawCtl = nullptr;
}

// a control redraw from simPoll may come inside a recorded call of the
// sketch: its own calls are recorded as top-level ones
static int SavedDrawDepth = 0;

void simDrawCtlSave(const void *&control, uint32_t &seq)
{
  control = DrawCtl;
  seq = DrawCtlSeq;
  SavedDrawDepth = DrawDepth;
  DrawDepth = 0;
}

void simDrawCtlRestore(const void *control, uint32_t seq)
{
  DrawCtl = control;
  DrawCtlSeq = seq;
  DrawDepth = SavedDrawDepth;
}

bool simDrawReplaying()
{
  return Replaying;
}

static void lcdDone()
{
  SimScreenVersion++;
  if (Replaying)
    return;
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
  drawPoll();
  clearLog(0);
  simCtlScreenCleared();
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
  drawPoll();
  clearLog(color);
  simCtlScreenCleared();
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
  DrawScope scope(this, FrontColor, BackColor, Transparent, Font, dkPixel, x, y, 0, 0, x, y, x, y, false);
  simGraphicDrawn(x, y, x, y, false);
  putPixel(x, y, FrontColor);
  lcdDone();
}

void UTFT::drawLine(int x1, int y1, int x2, int y2)
{
  DrawScope scope(this, FrontColor, BackColor, Transparent, Font, dkLine, x1, y1, x2, y2, x1, y1, x2, y2, false);
  drawPoll();
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
  DrawScope scope(this, FrontColor, BackColor, Transparent, Font, dkRect, x1, y1, x2, y2, x1, y1, x2, y2, false);
  drawPoll();
  orderRect(x1, y1, x2, y2);
  simGraphicDrawn(x1, y1, x2, y2, false);
  hLine(x1, y1, x2 - x1);
  hLine(x1, y2, x2 - x1);
  vLine(x1, y1, y2 - y1);
  vLine(x2, y1, y2 - y1);
}

void UTFT::drawRoundRect(int x1, int y1, int x2, int y2)
{
  DrawScope scope(this, FrontColor, BackColor, Transparent, Font, dkRoundRect, x1, y1, x2, y2, x1, y1, x2, y2, false);
  drawPoll();
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
  DrawScope scope(this, FrontColor, BackColor, Transparent, Font, dkFillRect, x1, y1, x2, y2, x1, y1, x2, y2, true);
  drawPoll();
  orderRect(x1, y1, x2, y2);
  simGraphicDrawn(x1, y1, x2, y2, true);
  for (int y = y1; y <= y2; y++)
    for (int x = x1; x <= x2; x++)
      putPixel(x, y, FrontColor);
  lcdDone();
}

void UTFT::fillRoundRect(int x1, int y1, int x2, int y2)
{
  DrawScope scope(this, FrontColor, BackColor, Transparent, Font, dkFillRoundRect, x1, y1, x2, y2, x1, y1, x2, y2, false);
  drawPoll();
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
  DrawScope scope(this, FrontColor, BackColor, Transparent, Font, dkCircle, x, y, radius, 0, x - radius, y - radius, x + radius, y + radius,
                  false);
  drawPoll();
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
  DrawScope scope(this, FrontColor, BackColor, Transparent, Font, dkFillCircle, x, y, radius, 0, x - radius, y - radius, x + radius, y + radius,
                  false);
  drawPoll();
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
  DrawScope scope(this, FrontColor, BackColor, Transparent, Font, dkChar, character, x, y, 0, x, y,
                  x + (Font ? Font[0] : 1) - 1, y + (Font ? Font[1] : 1) - 1, !Transparent && Font);
  SimPixelOwner = 0;   // text pixels: the text entry answers for them
  drawPoll();
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
  DrawScope scope(this, FrontColor, BackColor, Transparent, Font, dkPrint, x, y, 0, 0, x, y, x + length * sizeX - 1,
                  y + Font[1] - 1, !Transparent && length > 0, text);
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
  DrawScope scope(this, FrontColor, BackColor, Transparent, Font, dkBitmap, x, y, sx, sy, x, y, x + sx * (scale < 1 ? 1 : scale) - 1,
                  y + sy * (scale < 1 ? 1 : scale) - 1, data != nullptr, nullptr, data, scale);
  drawPoll();
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

// Screen as the log has it, without the last drawing of control: the
// entries of that drawing are removed (the control draws itself again
// after this). false - the log is not complete (overflow) or the control
// is not in it; the screen is then not changed.
bool simScreenRestoreWithout(const void *control)
{
  if (DrawLogOverflow || !control)
    return false;
  // the last drawing of the control and all its drawings at the same
  // place: the sketch may draw a label again and again (Paused!), each
  // would show through after the move
  const DrawOp *last = nullptr;
  for (size_t index = DrawLog.size(); index-- > 0;)
    if (DrawLog[index].Ctl == control)
    {
      last = &DrawLog[index];
      break;
    }
  if (!last)
    return false;
  uint32_t lastSeq = last->CtlSeq;
  bool lastPlaced = last->CtlPlaced;
  int lastLeft = last->CtlLeft, lastTop = last->CtlTop;
  std::vector<DrawOp> kept;
  kept.reserve(DrawLog.size());
  for (const DrawOp &op : DrawLog)
  {
    bool drop = op.Ctl == control &&
                (op.CtlSeq == lastSeq ||
                 (lastPlaced && op.CtlPlaced && op.CtlLeft == lastLeft && op.CtlTop == lastTop));
    if (!drop)
      kept.push_back(op);
  }
  DrawLog.swap(kept);

  uint32_t oldOwner = SimPixelOwner;
  double oldDebt = LcdDebtNs;
  for (int y = 0; y < SIM_SCREEN_H; y++)
    for (int x = 0; x < SIM_SCREEN_W; x++)
      SimScreen[y][x] = DrawLogBase;
  memset(SimOwnerMap, 0, sizeof(SimOwnerMap));
  Replaying = true;
  for (const DrawOp &op : DrawLog)
  {
    UTFT *obj = op.Obj;
    word oldFore = obj->FrontColor, oldBack = obj->BackColor;
    bool oldTransparent = obj->Transparent;
    uint8_t *oldFont = obj->Font;
    obj->FrontColor = op.Fore;
    obj->BackColor = op.Back;
    obj->Transparent = op.Transparent;
    obj->Font = op.Font;
    SimPixelOwner = op.Owner;
    const int *args = op.Args;
    switch (op.Kind)
    {
    case dkPixel: obj->drawPixel(args[0], args[1]); break;
    case dkLine: obj->drawLine(args[0], args[1], args[2], args[3]); break;
    case dkRect: obj->drawRect(args[0], args[1], args[2], args[3]); break;
    case dkRoundRect: obj->drawRoundRect(args[0], args[1], args[2], args[3]); break;
    case dkFillRect: obj->fillRect(args[0], args[1], args[2], args[3]); break;
    case dkFillRoundRect: obj->fillRoundRect(args[0], args[1], args[2], args[3]); break;
    case dkCircle: obj->drawCircle(args[0], args[1], args[2]); break;
    case dkFillCircle: obj->fillCircle(args[0], args[1], args[2]); break;
    case dkChar: obj->printChar((byte)args[0], args[1], args[2]); break;
    case dkPrint: obj->print(op.Text.c_str(), args[0], args[1]); break;
    case dkBitmap: obj->drawBitmap(args[0], args[1], args[2], args[3], op.Data, op.Scale); break;
    default: break;
    }
    obj->FrontColor = oldFore;
    obj->BackColor = oldBack;
    obj->Transparent = oldTransparent;
    obj->Font = oldFont;
  }
  Replaying = false;
  LcdDebtNs = oldDebt;
  SimPixelOwner = oldOwner;
  SimScreenVersion++;
  return true;
}
