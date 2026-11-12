// ArdSim: Arduino core API for building a sketch as a Windows program.
// Covers what the Arduino Due (SAM) core gives a sketch: types, pins,
// time, interrupts, String, Serial. Hardware is simulated in ArdSim/src.
#ifndef ARDSIM_ARDUINO_H
#define ARDSIM_ARDUINO_H

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>
#ifdef __cplusplus
#include <algorithm>  // STL headers before the min/max macros below
#include <vector>
#endif
#include "WString.h"
#include "ardsim_debug.h"
#include "avr/pgmspace.h"

typedef uint8_t byte;
typedef bool boolean;
typedef uint16_t word;

#define HIGH 0x1
#define LOW  0x0
#define INPUT 0x0
#define OUTPUT 0x1
#define INPUT_PULLUP 0x2
#define CHANGE 2
#define FALLING 3
#define RISING 4
#define LSBFIRST 0
#define MSBFIRST 1
#define DEC 10
#define HEX 16
#define OCT 8
#define BIN 2

#define PI 3.1415926535897932384626433832795
#define HALF_PI 1.5707963267948966192313216916398
#define TWO_PI 6.283185307179586476925286766559
#define DEG_TO_RAD 0.017453292519943295769236907684886
#define RAD_TO_DEG 57.295779513082320876798154814105

// Arduino Due: A0 = 54 ... A11 = 65
static const uint8_t A0 = 54, A1 = 55, A2 = 56, A3 = 57, A4 = 58, A5 = 59,
  A6 = 60, A7 = 61, A8 = 62, A9 = 63, A10 = 64, A11 = 65;
static const uint8_t DAC0 = 66, DAC1 = 67;
#define LED_BUILTIN 13
#define SIM_PIN_COUNT 80

// Pins
void pinMode(uint32_t pin, uint32_t mode);
void digitalWrite(uint32_t pin, uint32_t value);
int digitalRead(uint32_t pin);
int analogRead(uint32_t pin);
void analogReadResolution(int bits);
void analogWrite(uint32_t pin, uint32_t value);
void analogWriteResolution(int bits);

// Time
unsigned long millis();
unsigned long micros();
void delay(unsigned long ms);
void delayMicroseconds(unsigned int us);
void yield();

// Interrupts
typedef void (*voidFuncPtr)(void);
void attachInterrupt(uint32_t pin, voidFuncPtr callback, uint32_t mode);
void detachInterrupt(uint32_t pin);
#define digitalPinToInterrupt(pin) (pin)
void interrupts();
void noInterrupts();

// Math helpers (SAM core)
#ifndef min
#define min(a, b) ((a) < (b) ? (a) : (b))
#endif
#ifndef max
#define max(a, b) ((a) > (b) ? (a) : (b))
#endif
#define constrain(amt, low, high) ((amt) < (low) ? (low) : ((amt) > (high) ? (high) : (amt)))
#define radians(deg) ((deg) * DEG_TO_RAD)
#define degrees(rad) ((rad) * RAD_TO_DEG)
#define sq(x) ((x) * (x))
#define lowByte(w) ((uint8_t)((w) & 0xff))
#define highByte(w) ((uint8_t)((w) >> 8))
#define bitRead(value, bit) (((value) >> (bit)) & 0x01)
#define bitSet(value, bit) ((value) |= (1UL << (bit)))
#define bitClear(value, bit) ((value) &= ~(1UL << (bit)))
#define bit(b) (1UL << (b))
long map(long value, long fromLow, long fromHigh, long toLow, long toHigh);
long random(long howBig);
long random(long howSmall, long howBig);
void randomSeed(unsigned long seed);
char *itoa(int value, char *buffer, int base);
char *ltoa(long value, char *buffer, int base);
char *dtostrf(double value, signed char width, unsigned char prec, char *buffer);

// Print / Serial
class Print
{
public:
  virtual ~Print() {}
  virtual size_t write(uint8_t value) = 0;
  virtual size_t write(const uint8_t *buffer, size_t size);
  size_t write(const char *text) { return text ? write((const uint8_t *)text, strlen(text)) : 0; }
  size_t print(const String &text);
  size_t print(const char *text);
  size_t print(char value);
  size_t print(unsigned char value, int base = DEC);
  size_t print(int value, int base = DEC);
  size_t print(unsigned int value, int base = DEC);
  size_t print(long value, int base = DEC);
  size_t print(unsigned long value, int base = DEC);
  size_t print(double value, int digits = 2);
  size_t println();
  template <typename ValueType>
  size_t println(const ValueType &value) { size_t count = print(value); return count + println(); }
  template <typename ValueType>
  size_t println(const ValueType &value, int format) { size_t count = print(value, format); return count + println(); }
  size_t println(const char *text) { size_t count = print(text); return count + println(); }
};

class SimSerial : public Print
{
public:
  void begin(unsigned long baud) { (void)baud; }
  void begin(unsigned long baud, int config) { (void)baud; (void)config; }
  void end() {}
  int available() { return 0; }
  int read() { return -1; }
  int peek() { return -1; }
  void flush() {}
  size_t write(uint8_t value) override;
  size_t write(const uint8_t *buffer, size_t size) override;
  using Print::write;
  operator bool() { return true; }
};
extern SimSerial Serial;
extern SimSerial Serial1;
extern SimSerial SerialUSB;

// Flash strings: plain memory on the PC
#define F(text) (reinterpret_cast<const __FlashStringHelper *>(PSTR(text)))

// Simulator hooks (ArdSim/src)
void simPoll();

// ArdSim only (a real board does not define ARDSIM): measurement file view
// of unIDE ("View files Test.dat", ardsim.ini [DataFile]).
#define ARDSIM 1
// 0 - no file is viewed; another value - changes when another file is chosen
uint32_t simDataFileVersion();
// The viewed file as the sketch would sample it: maxFrames frames of 4 values
// (A0, A1 counts of the 12-bit ADC, A4 tacho, 0), the frame numbers of the
// tacho marks and micros per frame. Returns frames taken from the file
// (frames past its end repeat the last one), 0 - no file
int simDataFileRead(uint16_t *frames, int maxFrames, int *marks, int maxMarks,
                    int *markCount, double *frameUs);
void setup();
void loop();

#endif
