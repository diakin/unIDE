// ArdSim debugger: hooks that ardprep puts into the sketch code.
//   SIM_STEP(file, line)  before each statement of a sketch function
//   SimFrame              at the start of each sketch function (call stack)
//   SimWatchReg           after a global variable (Watch)
//   SimLocalReg           after a local variable (Watch, while in scope)
//   SimFileReg            file index -> path of the .ino
// The debugger works only in host mode (the Emulator window of unIDE);
// otherwise simStep() costs one check of SimDebugWanted.
#ifndef ARDSIM_DEBUG_H
#define ARDSIM_DEBUG_H
#ifdef __cplusplus
#include <stddef.h>
#include <stdint.h>
#include <string>
#include <type_traits>

class String;

// != 0: simStep() goes the slow way (breakpoints, stepping, pause, Watch)
extern volatile int SimDebugWanted;
// Statement being executed: (file << 20) | line
extern volatile int SimTopLine;
void simStepSlow(int code);
void simPoll();
// Body of an empty wait loop whose condition only an interrupt can change
// (ardprep): simPoll, then Sleep while no timer tick, tacho edge or key
// release is close
void simSpinWait();
// Statements since the last simPoll() from simStep()
extern int SimStepsUnpolled;
const int SimStepsPerPoll = 64;

// Every SimStepsPerPoll statements a simPoll(): interrupts and timer ticks
// come also in loops without Arduino calls or String comparisons, such as
// a wait on a volatile variable that an ISR sets (on the board an
// interrupt comes between any two instructions)
inline void simStep(int code)
{
  SimTopLine = code;
  if (++SimStepsUnpolled >= SimStepsPerPoll)
  {
    SimStepsUnpolled = 0;
    simPoll();
  }
  if (SimDebugWanted)
    simStepSlow(code);
}
#define SIM_STEP(file, line) simStep(((file) << 20) | (line))

struct SimFrame
{
  explicit SimFrame(const char *name);
  ~SimFrame();
};

// Formatting of one value of a known type (Watch)
typedef void (*SimFormatFn)(const void *value, std::string &out);
void simFmtBool(std::string &out, bool value);
void simFmtChar(std::string &out, char value);
void simFmtInt(std::string &out, long long value);
void simFmtUInt(std::string &out, unsigned long long value);
void simFmtDouble(std::string &out, double value, int digits);
void simFmtPtr(std::string &out, const void *value);
void simFmtCharPtr(std::string &out, const char *value);
void simFmtString(std::string &out, const String &value);

template <class ValueType>
constexpr bool simPrintable()
{
  typedef typename std::remove_cv<ValueType>::type Plain;
  if constexpr (std::is_array<Plain>::value)
    return simPrintable<typename std::remove_extent<Plain>::type>();
  else
    return std::is_arithmetic<Plain>::value || std::is_enum<Plain>::value ||
           std::is_pointer<Plain>::value || std::is_same<Plain, String>::value;
}

template <class ValueType>
void simFormatValue(const ValueType &value, std::string &out);

// Whole array: "{e0, e1, ...}", char arrays as text
void simFmtArray(std::string &out, const void *first, size_t count, size_t elemSize,
                 SimFormatFn format, bool isText);

template <class ValueType>
void simFormatThunk(const void *value, std::string &out)
{
  simFormatValue(*(const ValueType *)value, out);
}

template <class ValueType>
void simFormatValue(const ValueType &value, std::string &out)
{
  typedef typename std::remove_cv<ValueType>::type Plain;
  if constexpr (std::is_same<Plain, bool>::value)
    simFmtBool(out, value);
  else if constexpr (std::is_same<Plain, char>::value)
    simFmtChar(out, value);
  else if constexpr (std::is_enum<Plain>::value)
    simFmtInt(out, (long long)value);
  else if constexpr (std::is_integral<Plain>::value && std::is_signed<Plain>::value)
    simFmtInt(out, (long long)value);
  else if constexpr (std::is_integral<Plain>::value)
    simFmtUInt(out, (unsigned long long)value);
  else if constexpr (std::is_same<Plain, float>::value)
    simFmtDouble(out, (double)value, 7);
  else if constexpr (std::is_floating_point<Plain>::value)
    simFmtDouble(out, (double)value, 15);
  else if constexpr (std::is_pointer<Plain>::value)
  {
    typedef typename std::remove_cv<typename std::remove_pointer<Plain>::type>::type Target;
    if constexpr (std::is_same<Target, char>::value)
      simFmtCharPtr(out, (const char *)value);
    else
      simFmtPtr(out, (const void *)value);
  }
  else if constexpr (std::is_same<Plain, String>::value)
    simFmtString(out, value);
  else if constexpr (std::is_array<Plain>::value)
  {
    typedef typename std::remove_extent<Plain>::type Elem;
    simFmtArray(out, (const void *)&value[0], std::extent<Plain>::value, sizeof(Elem),
                &simFormatThunk<Elem>,
                std::is_same<typename std::remove_cv<Elem>::type, char>::value);
  }
}

// Registered variable. Count = 0: a scalar; > 0: an array of Count
// elements of ElemSize bytes, Format formats one element
struct SimVarInfo
{
  const char *Name;
  const void *Ptr;
  SimFormatFn Format;
  size_t Count;
  size_t ElemSize;
  bool IsText;
};
void simWatchAddGlobal(const SimVarInfo &info);
void simWatchPushLocal(const SimVarInfo &info);
void simWatchPopLocal();

template <class ValueType>
SimVarInfo simVarOf(const char *name, const ValueType *ptr, size_t count)
{
  SimVarInfo info;
  info.Name = name;
  info.Ptr = (const void *)ptr;
  info.Format = &simFormatThunk<ValueType>;
  info.Count = count;
  info.ElemSize = sizeof(ValueType);
  info.IsText = count > 0 && std::is_same<typename std::remove_cv<ValueType>::type, char>::value;
  return info;
}

struct SimWatchReg
{
  template <class ValueType>
  SimWatchReg(const char *name, ValueType &value)
  {
    if constexpr (simPrintable<ValueType>() && !std::is_array<ValueType>::value)
      simWatchAddGlobal(simVarOf(name, &value, 0));
  }
  // arrays: ardprep passes &name[0] and the element count
  template <class ValueType>
  SimWatchReg(const char *name, ValueType *first, size_t count)
  {
    if constexpr (simPrintable<ValueType>())
      simWatchAddGlobal(simVarOf(name, first, count));
  }
};

struct SimLocalReg
{
  bool Pushed;
  template <class ValueType>
  SimLocalReg(const char *name, ValueType &value) : Pushed(false)
  {
    if constexpr (simPrintable<ValueType>() && !std::is_array<ValueType>::value)
    {
      simWatchPushLocal(simVarOf(name, &value, 0));
      Pushed = true;
    }
  }
  template <class ValueType>
  SimLocalReg(const char *name, ValueType *first, size_t count) : Pushed(false)
  {
    if constexpr (simPrintable<ValueType>())
    {
      simWatchPushLocal(simVarOf(name, first, count));
      Pushed = true;
    }
  }
  ~SimLocalReg()
  {
    if (Pushed)
      simWatchPopLocal();
  }
  SimLocalReg(const SimLocalReg &) = delete;
  SimLocalReg &operator=(const SimLocalReg &) = delete;
};

struct SimFileReg
{
  SimFileReg(int index, const char *path);
};

// ---- live arguments (ardprep): the unIDE inspector changes a number,
// color or font of a screen call while the emulator runs. ardprep wraps
// the arguments as SIM_ARG(code, hash, occurrence, index, expression):
// code = (file << 20) | line of the call, hash = FNV-1a of the method or
// function name, occurrence = calls of that name earlier on the line,
// index = argument from 0. Fonts: SimFontReg after "extern uint8_t X[];".
struct SimFontReg
{
  SimFontReg(const char *name, const uint8_t *font);
};
// Table of the host (shared memory, sim_host.cpp); null or count 0 - no
// overrides, simArg returns the expression at once
extern volatile uint32_t *SimArgTable;
struct SimArgHit
{
  int Kind;               // 1 - number, 2 - font
  long long Number;
  const uint8_t *Font;    // Kind 2: registered font, null - unknown name
};
bool simArgLookup(int code, uint32_t hash, int occurrence, int index, SimArgHit &hit);

template <class ValueType>
inline ValueType simArg(int code, uint32_t hash, int occurrence, int index, ValueType value)
{
  if (!SimArgTable || SimArgTable[0] == 0)
    return value;
  typedef typename std::remove_cv<ValueType>::type Plain;
  if constexpr (std::is_arithmetic<Plain>::value || std::is_pointer<Plain>::value)
  {
    SimArgHit hit;
    if (!simArgLookup(code, hash, occurrence, index, hit))
      return value;
    if constexpr (std::is_arithmetic<Plain>::value)
    {
      if (hit.Kind == 1)
        return (ValueType)hit.Number;
    }
    else
    {
      typedef typename std::remove_cv<typename std::remove_pointer<Plain>::type>::type Target;
      if constexpr (std::is_same<Target, uint8_t>::value)
        if (hit.Kind == 2 && hit.Font)
          return (ValueType)hit.Font;
    }
  }
  return value;
}
#define SIM_ARG(code, hash, occurrence, index, expr) simArg((code), (hash), (occurrence), (index), (expr))

// ---- live controls: named objects of the sketch (TLabel in BS10Controls.h)
// whose properties the unIDE inspector changes while the emulator runs.
// ardprep registers every "TLabel name = {...}" of the sketch's own
// #include "..." files (SimCtlReg, defined by the control header). The
// host table (sim_internal.h, SimCtl*) holds name hash, property number
// and the new value; the control asks for it when it draws, and simPoll
// calls Redraw of a control whose entries changed.
typedef void (*SimCtlRedrawFn)(void *control);
void simCtlRegister(const char *name, void *control, SimCtlRedrawFn redraw);
// value set by the host for property prop of control: false - none
bool simCtlNumber(const void *control, int prop, long &value);
bool simCtlText(const void *control, int prop, String &value);
bool simCtlFont(const void *control, int prop, uint8_t *&font);
// the sketch draws the control now: its statement and call lines are kept,
// a redraw from simPoll answers screen clicks with them
void simCtlDrawing(const void *control);
// the control has been drawn: left, top as drawn and the box of pixels it
// took (for the marker and the dragging in unIDE)
void simCtlShown(const void *control, int left, int top, int boxLeft, int boxTop,
                 int boxRight, int boxBottom);
// +1 at every clrScr / fillScr: a control drawn before is no longer on
// the screen
extern uint32_t SimScreenClears;
// graphic entry of the pixels being drawn (where-is-it map): a redraw
// from simPoll keeps the one of the interrupted drawing
uint32_t simPixelOwnerGet();
void simPixelOwnerSet(uint32_t owner);
#endif
#endif
