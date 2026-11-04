// ArdSim: Arduino core on the PC - time, pins, keypad matrix, pin
// interrupts, DueTimer, Serial, small helpers.
//
// Interrupts and timer ticks are delivered at safe points of the sketch
// thread (simPoll: every Arduino API call and every String comparison),
// not by preempting it. So an ISR never runs in the middle of a heap
// operation of the sketch, and the simulator itself does not crash on
// String in an ISR; the order of events stays the one the sketch sees.
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include <mmsystem.h>
#include "Arduino.h"
#include "DueTimer.h"
#include "SPI.h"
#include "sim_internal.h"

SimSerial Serial;
SimSerial Serial1;
SimSerial SerialUSB;
SPIClass SPI;
volatile bool SimStopping = false;

// ---------------------------------------------------------------- time
static LARGE_INTEGER SimFreq, SimStart;
// Time the debugger held the sketch (QPC ticks): not counted
static volatile LONGLONG PausedTicks = 0;
static LONGLONG PauseStart = 0;

static uint64_t simMicros64()
{
  LARGE_INTEGER now;
  QueryPerformanceCounter(&now);
  LONGLONG ticks = now.QuadPart - SimStart.QuadPart - PausedTicks;
  return (uint64_t)(ticks / SimFreq.QuadPart * 1000000LL +
                    ticks % SimFreq.QuadPart * 1000000LL / SimFreq.QuadPart);
}

void simClockPause(bool paused)
{
  LARGE_INTEGER now;
  QueryPerformanceCounter(&now);
  if (paused)
    PauseStart = now.QuadPart;
  else if (PauseStart != 0)
  {
    PausedTicks = PausedTicks + (now.QuadPart - PauseStart);
    PauseStart = 0;
  }
}

uint64_t simMicrosNow() { return simMicros64(); }

unsigned long micros() { simPoll(); return (unsigned long)(uint32_t)simMicros64(); }
unsigned long millis() { simPoll(); return (unsigned long)(uint32_t)(simMicros64() / 1000); }

void delay(unsigned long ms)
{
  uint64_t until = simMicros64() + (uint64_t)ms * 1000;
  simPoll();
  while (simMicros64() < until)
  {
    uint64_t left = until - simMicros64();
    if (left > 2000)
      Sleep(1);
    simPoll();
  }
}

void delayMicroseconds(unsigned int us)
{
  uint64_t until = simMicros64() + us;
  while (simMicros64() < until)
    simPoll();
}

void yield() { simPoll(); }

// ---------------------------------------------------------------- pins
// BS10 keypad wiring (from the sketch): device row r (0 = top "F1 F2 # *")
// is on pin 13 - r, column c on pin 5 + c. Columns are inputs with pull-up
// and pin interrupts (FALLING); rows are outputs driven LOW.
static const int SimRowPin[SIM_KEY_ROWS] = {13, 12, 11, 10, 9};
static const int SimColPin[SIM_KEY_COLS] = {5, 6, 7, 8};
static const char *SimKeyText[SIM_KEY_ROWS][SIM_KEY_COLS] = {
  {"F1", "F2", "#", "*"},
  {"1", "2", "3", "^"},
  {"4", "5", "6", "v"},
  {"7", "8", "9", "Esc"},
  {"<", "0", ">", "Ent"}};

static uint8_t PinMode[SIM_PIN_COUNT];
static uint8_t PinOut[SIM_PIN_COUNT];      // digitalWrite value (pull-up for inputs)
static uint8_t PinLevel[SIM_PIN_COUNT];    // last level seen by interrupts
static voidFuncPtr PinIsr[SIM_PIN_COUNT];
static uint8_t PinIsrMode[SIM_PIN_COUNT];
static volatile bool PinIsrPending[SIM_PIN_COUNT];
static bool IrqEnabled = true;
static bool InIsr = false;
bool simInIsr() { return InIsr; }
static int AnalogBits = 10;

// Pressed key (sketch thread state): -1 - none
static int PressRow = -1, PressCol = -1;
static uint64_t PressUntil = 0;

// Key presses posted by the window thread
static CRITICAL_SECTION KeyLock;
static int PostRow = -1, PostCol = -1, PostHold = 0;
static volatile bool PostReady = false;

const char *simKeyCaption(int row, int col)
{
  if (row < 0 || row >= SIM_KEY_ROWS || col < 0 || col >= SIM_KEY_COLS)
    return "";
  return SimKeyText[row][col];
}

void simPostKey(int row, int col, int holdMs)
{
  EnterCriticalSection(&KeyLock);
  PostRow = row;
  PostCol = col;
  PostHold = holdMs;
  PostReady = true;
  LeaveCriticalSection(&KeyLock);
}

static int keyRowOfPin(uint32_t pin)
{
  for (int row = 0; row < SIM_KEY_ROWS; row++)
    if (SimRowPin[row] == (int)pin)
      return row;
  return -1;
}

static int keyColOfPin(uint32_t pin)
{
  for (int col = 0; col < SIM_KEY_COLS; col++)
    if (SimColPin[col] == (int)pin)
      return col;
  return -1;
}

// Level of a pin as the sketch reads it
static int pinLevel(uint32_t pin)
{
  if (pin >= SIM_PIN_COUNT)
    return LOW;
  int row = keyRowOfPin(pin);
  int col = keyColOfPin(pin);
  if (PinMode[pin] == OUTPUT)
    return PinOut[pin] ? HIGH : LOW;
  if ((int)pin == simTachoPin())
    return simTachoLevel() ? HIGH : LOW;
  // Input: a pressed key connects its row and column; the other side,
  // driven LOW, pulls this pin low; otherwise the pull-up gives HIGH
  if (PressRow >= 0)
  {
    if (col >= 0 && col == PressCol)
    {
      int rowPin = SimRowPin[PressRow];
      if (PinMode[rowPin] == OUTPUT && !PinOut[rowPin])
        return LOW;
    }
    if (row >= 0 && row == PressRow)
    {
      int colPin = SimColPin[PressCol];
      if (PinMode[colPin] == OUTPUT && !PinOut[colPin])
        return LOW;
    }
  }
  if (PinMode[pin] == INPUT_PULLUP || PinOut[pin])
    return HIGH;
  // Keypad lines have pull-ups on the board
  if (row >= 0 || col >= 0)
    return HIGH;
  return LOW;
}

// Edges on pins with interrupts -> pending ISRs (delivered by simPoll)
static void checkEdges()
{
  for (uint32_t pin = 0; pin < SIM_PIN_COUNT; pin++)
  {
    if (!PinIsr[pin] || (int)pin == simTachoPin())
      continue;   // the tacho edges come from simSignalAdvance
    uint8_t level = (uint8_t)pinLevel(pin);
    uint8_t old = PinLevel[pin];
    PinLevel[pin] = level;
    if (level == old)
      continue;
    uint8_t mode = PinIsrMode[pin];
    if (mode == CHANGE || (mode == FALLING && level == LOW) ||
        (mode == RISING && level == HIGH))
      PinIsrPending[pin] = true;
  }
}

// A click is one short press: the key is released when the sketch has
// scanned it once (its row pin switched to input and back to output).
// Without this a press longer than the 50 ms scan period repeats, since
// driving the rows LOW again after the scan gives a new falling edge on
// the column.
static bool PressScanned = false;

void pinMode(uint32_t pin, uint32_t mode)
{
  if (pin < SIM_PIN_COUNT)
  {
    int row = keyRowOfPin(pin);
    if (PressRow >= 0 && row == PressRow && mode != OUTPUT)
      PressScanned = true;
    else if (PressRow >= 0 && row >= 0 && mode == OUTPUT && PressScanned)
    {
      PressRow = -1;
      PressCol = -1;
      PressScanned = false;
    }
    PinMode[pin] = (uint8_t)mode;
    checkEdges();
  }
  simPoll();
}

void digitalWrite(uint32_t pin, uint32_t value)
{
  if (pin < SIM_PIN_COUNT)
  {
    PinOut[pin] = value ? 1 : 0;
    checkEdges();
  }
  simPoll();
}

int digitalRead(uint32_t pin)
{
  simPoll();
  return pinLevel(pin);
}

// Analog inputs: the generator (sim_signal.cpp) gives volts, the ADC
// turns them into counts of the current resolution (Due: 0..Vref)
int analogRead(uint32_t pin)
{
  simPoll();
  int channel = pin >= A0 ? (int)(pin - A0) : (int)pin;
  int full = (1 << AnalogBits) - 1;
  double counts = simSignalVolts(channel, simMicros64()) / simSignalVref() * (full + 1);
  if (counts < 0)
    counts = 0;
  if (counts > full)
    counts = full;
  return (int)counts;
}

void analogReadResolution(int bits)
{
  if (bits >= 8 && bits <= 16)
    AnalogBits = bits;
}

void analogWrite(uint32_t pin, uint32_t value) { (void)pin; (void)value; simPoll(); }
void analogWriteResolution(int bits) { (void)bits; }

void attachInterrupt(uint32_t pin, voidFuncPtr callback, uint32_t mode)
{
  if (pin < SIM_PIN_COUNT)
  {
    PinIsr[pin] = callback;
    PinIsrMode[pin] = (uint8_t)mode;
    PinLevel[pin] = (uint8_t)pinLevel(pin);
    PinIsrPending[pin] = false;
  }
}

void detachInterrupt(uint32_t pin)
{
  if (pin < SIM_PIN_COUNT)
  {
    PinIsr[pin] = nullptr;
    PinIsrPending[pin] = false;
  }
}

void interrupts() { IrqEnabled = true; simPoll(); }
void noInterrupts() { IrqEnabled = false; }

// ---------------------------------------------------------------- timers
#define SIM_TIMER_COUNT 9
struct SimTimer
{
  void (*Isr)();
  uint64_t Period;
  uint64_t Next;
  bool Running;
};
static SimTimer Timers[SIM_TIMER_COUNT];

DueTimer Timer(0);
DueTimer Timer0(0), Timer1(1), Timer2(2), Timer3(3), Timer4(4), Timer5(5),
  Timer6(6), Timer7(7), Timer8(8);

DueTimer DueTimer::getAvailable()
{
  for (unsigned short index = 0; index < SIM_TIMER_COUNT; index++)
    if (!Timers[index].Isr)
      return DueTimer(index);
  return DueTimer(0);
}

DueTimer &DueTimer::attachInterrupt(void (*isr)())
{
  Timers[Number].Isr = isr;
  return *this;
}

DueTimer &DueTimer::detachInterrupt()
{
  Timers[Number].Isr = nullptr;
  Timers[Number].Running = false;
  return *this;
}

DueTimer &DueTimer::start(long microseconds)
{
  if (microseconds > 0)
    Timers[Number].Period = (uint64_t)microseconds;
  if (Timers[Number].Period == 0)
    Timers[Number].Period = 1000000;
  Timers[Number].Next = simMicros64() + Timers[Number].Period;
  Timers[Number].Running = true;
  return *this;
}

DueTimer &DueTimer::stop()
{
  Timers[Number].Running = false;
  return *this;
}

DueTimer &DueTimer::setFrequency(double frequency)
{
  if (frequency > 0)
    Timers[Number].Period = (uint64_t)(1000000.0 / frequency);
  return *this;
}

DueTimer &DueTimer::setPeriod(unsigned long microseconds)
{
  Timers[Number].Period = microseconds;
  return *this;
}

double DueTimer::getFrequency() const
{
  return Timers[Number].Period ? 1000000.0 / (double)Timers[Number].Period : 0;
}

long DueTimer::getPeriod() const { return (long)Timers[Number].Period; }

// ---------------------------------------------------------------- poll
void simPoll()
{
  if (InIsr)
    return;
  if (SimStopping)
  {
    // Window closed: the sketch thread ends here
    ExitThread(0);
  }
  uint64_t now = simMicros64();
  InIsr = true;
  // Tacho: edges since the last poll -> pin interrupt
  int tachoEdges = simSignalAdvance(now);
  int tachoPin = simTachoPin();
  if (tachoEdges && tachoPin >= 0 && tachoPin < SIM_PIN_COUNT && PinIsr[tachoPin])
  {
    uint8_t mode = PinIsrMode[tachoPin];
    if (((tachoEdges & 1) && (mode == FALLING || mode == CHANGE)) ||
        ((tachoEdges & 2) && (mode == RISING || mode == CHANGE)))
      PinIsrPending[tachoPin] = true;
  }
  // Keypad: posted press -> matrix state; release after the hold time
  if (PostReady)
  {
    EnterCriticalSection(&KeyLock);
    PressRow = PostRow;
    PressCol = PostCol;
    PressUntil = now + (uint64_t)PostHold * 1000;
    PressScanned = false;
    PostReady = false;
    LeaveCriticalSection(&KeyLock);
    checkEdges();
  }
  else if (PressRow >= 0 && now >= PressUntil)
  {
    PressRow = -1;
    PressCol = -1;
    checkEdges();
  }
  if (IrqEnabled)
  {
    for (uint32_t pin = 0; pin < SIM_PIN_COUNT; pin++)
      if (PinIsrPending[pin])
      {
        PinIsrPending[pin] = false;
        if (PinIsr[pin])
          PinIsr[pin]();
      }
    for (int index = 0; index < SIM_TIMER_COUNT; index++)
    {
      SimTimer &timer = Timers[index];
      if (!timer.Running || !timer.Isr || now < timer.Next)
        continue;
      // Late (the sketch was busy): one tick, the next one a period later
      timer.Next += timer.Period;
      if (timer.Next <= now)
        timer.Next = now + timer.Period;
      timer.Isr();
      // The ISR may have changed pins (kbdcheck2 drives the rows)
      for (uint32_t pin = 0; pin < SIM_PIN_COUNT; pin++)
        if (PinIsrPending[pin])
        {
          PinIsrPending[pin] = false;
          if (PinIsr[pin])
            PinIsr[pin]();
        }
    }
  }
  InIsr = false;
}

// ---------------------------------------------------------------- Serial
static CRITICAL_SECTION SerialLock;
static std::string SerialBuffer;

void simSerialAppend(const char *text, size_t length)
{
  EnterCriticalSection(&SerialLock);
  SerialBuffer.append(text, length);
  if (SerialBuffer.size() > 1000000)
    SerialBuffer.erase(0, SerialBuffer.size() - 500000);
  LeaveCriticalSection(&SerialLock);
}

std::string simSerialTake()
{
  EnterCriticalSection(&SerialLock);
  std::string text;
  text.swap(SerialBuffer);
  LeaveCriticalSection(&SerialLock);
  return text;
}

size_t SimSerial::write(uint8_t value)
{
  char text = (char)value;
  simSerialAppend(&text, 1);
  return 1;
}

size_t SimSerial::write(const uint8_t *buffer, size_t size)
{
  simSerialAppend((const char *)buffer, size);
  return size;
}

size_t Print::write(const uint8_t *buffer, size_t size)
{
  size_t count = 0;
  while (size--)
    count += write(*buffer++);
  return count;
}

size_t Print::print(const String &text) { return write((const uint8_t *)text.c_str(), text.length()); }
size_t Print::print(const char *text) { return write(text); }
size_t Print::print(char value) { return write((uint8_t)value); }
size_t Print::print(unsigned char value, int base) { return print(String((unsigned long)value, (unsigned char)base)); }
size_t Print::print(int value, int base) { return print(String((long)value, (unsigned char)base)); }
size_t Print::print(unsigned int value, int base) { return print(String((unsigned long)value, (unsigned char)base)); }
size_t Print::print(long value, int base) { return print(String(value, (unsigned char)base)); }
size_t Print::print(unsigned long value, int base) { return print(String(value, (unsigned char)base)); }
size_t Print::print(double value, int digits) { return print(String(value, (unsigned char)digits)); }
size_t Print::println() { return write((const uint8_t *)"\r\n", 2); }

// ---------------------------------------------------------------- helpers
long map(long value, long fromLow, long fromHigh, long toLow, long toHigh)
{
  if (fromHigh == fromLow)
    return toLow;
  return (value - fromLow) * (toHigh - toLow) / (fromHigh - fromLow) + toLow;
}

long random(long howBig)
{
  if (howBig <= 0)
    return 0;
  return (long)(((unsigned long)rand() << 15 | (unsigned long)rand()) % (unsigned long)howBig);
}

long random(long howSmall, long howBig)
{
  if (howSmall >= howBig)
    return howSmall;
  return howSmall + random(howBig - howSmall);
}

void randomSeed(unsigned long seed) { srand((unsigned int)seed); }

char *dtostrf(double value, signed char width, unsigned char prec, char *buffer)
{
  sprintf(buffer, "%*.*f", width, prec, value);
  return buffer;
}

std::string simExeDir()
{
  char path[MAX_PATH];
  DWORD length = GetModuleFileNameA(nullptr, path, MAX_PATH);
  std::string dir(path, length);
  size_t slash = dir.find_last_of("\\/");
  return slash == std::string::npos ? std::string() : dir.substr(0, slash + 1);
}

// ---------------------------------------------------------------- sketch thread
static DWORD WINAPI sketchThread(LPVOID)
{
  setup();
  for (;;)
  {
    loop();
    simPoll();
  }
  return 0;
}

void simStartSketch()
{
  QueryPerformanceFrequency(&SimFreq);
  QueryPerformanceCounter(&SimStart);
  timeBeginPeriod(1);
  InitializeCriticalSection(&KeyLock);
  InitializeCriticalSection(&SerialLock);
  // Arduino: pins start as inputs
  for (int pin = 0; pin < SIM_PIN_COUNT; pin++)
  {
    PinMode[pin] = INPUT;
    PinOut[pin] = 0;
  }
  // Big stack: sketches keep large local arrays (String tables)
  CreateThread(nullptr, 16 * 1024 * 1024, sketchThread, nullptr,
               STACK_SIZE_PARAM_IS_A_RESERVATION, nullptr);
}

void simRequestStop() { SimStopping = true; }
