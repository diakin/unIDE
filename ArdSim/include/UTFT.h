// ArdSim: UTFT (Rinky-Dink Electronics) for the PC. Draws into a 16-bit
// RGB565 frame buffer that the simulator window shows. Same font format
// and drawing rules as UTFT, so text and shapes land on the same pixels.
#ifndef ARDSIM_UTFT_H
#define ARDSIM_UTFT_H
#include "Arduino.h"

#define LEFT 0
#define RIGHT 9999
#define CENTER 9998
#define PORTRAIT 0
#define LANDSCAPE 1

// Display models (only the size matters here)
#define CTE32HR 2
#define HX8357A 2
#define ILI9481 16
#define ILI9486 16
#define CTE32_R2 16
#define CTE40 17
#define CTE50 27
#define CTE70 28
#define ITDB32S 2
#define ITDB50 27
#define TFT01_32 1

#define VGA_BLACK   0x0000
#define VGA_WHITE   0xFFFF
#define VGA_RED     0xF800
#define VGA_GREEN   0x0400
#define VGA_BLUE    0x001F
#define VGA_SILVER  0xC618
#define VGA_GRAY    0x8410
#define VGA_MAROON  0x8000
#define VGA_YELLOW  0xFFE0
#define VGA_OLIVE   0x8400
#define VGA_LIME    0x07E0
#define VGA_AQUA    0x07FF
#define VGA_TEAL    0x0410
#define VGA_NAVY    0x0010
#define VGA_FUCHSIA 0xF81F
#define VGA_PURPLE  0x8010
#define VGA_TRANSPARENT 0xFFFFFFFF

typedef uint8_t fontdatatype;
typedef uint16_t bitmapdatatype;

class UTFT
{
public:
  UTFT();
  UTFT(byte model, int rs, int wr, int cs, int rst, int ser = 0);
  void InitLCD(byte orientation = LANDSCAPE);
  void clrScr();
  void drawPixel(int x, int y);
  void drawLine(int x1, int y1, int x2, int y2);
  void fillScr(byte red, byte green, byte blue);
  void fillScr(word color);
  void drawRect(int x1, int y1, int x2, int y2);
  void drawRoundRect(int x1, int y1, int x2, int y2);
  void fillRect(int x1, int y1, int x2, int y2);
  void fillRoundRect(int x1, int y1, int x2, int y2);
  void drawCircle(int x, int y, int radius);
  void fillCircle(int x, int y, int radius);
  void setColor(byte red, byte green, byte blue);
  void setColor(word color);
  word getColor();
  void setBackColor(byte red, byte green, byte blue);
  void setBackColor(uint32_t color);
  word getBackColor();
  void print(const char *text, int x, int y, int deg = 0);
  void print(const String &text, int x, int y, int deg = 0);
  void printNumI(long number, int x, int y, int length = 0, char filler = ' ');
  void printNumF(double number, byte decimals, int x, int y, char divider = '.',
                 int length = 0, char filler = ' ');
  void printChar(byte character, int x, int y);
  void setFont(uint8_t *font);
  uint8_t *getFont();
  uint8_t getFontXsize();
  uint8_t getFontYsize();
  void drawBitmap(int x, int y, int sx, int sy, bitmapdatatype data, int scale = 1);
  void drawBitmap(int x, int y, int sx, int sy, const uint16_t *data, int scale = 1);
  void lcdOff() {}
  void lcdOn() {}
  void setContrast(char contrast) { (void)contrast; }
  int getDisplayXSize();
  int getDisplayYSize();
  void setBrightness(byte brightness) { (void)brightness; }
  void LCD_Write_COM(char command) { (void)command; }
  void LCD_Write_DATA(char high, char low) { (void)high; (void)low; }

private:
  void hLine(int x, int y, int length);
  void vLine(int x, int y, int length);
  void putPixel(int x, int y, word color);
  word FrontColor;
  word BackColor;
  bool Transparent;
  uint8_t *Font;
  byte Orient;
};
#endif
