// ArdSim debugger, sketch side: breakpoints, stepping, pause, call stack
// and variable values for the Emulator window of unIDE (host mode only).
// ardprep puts the hooks into the sketch (ardsim_debug.h); the debug
// area of the shared memory (sim_internal.h, SimDbg*) carries commands
// and answers. Everything here runs in the sketch thread, except
// simDebugHostTick (host loop thread). The screen text map is shared by
// both and guarded by TextLock.
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include "Arduino.h"
#include "sim_internal.h"
#include <algorithm>
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

volatile int SimDebugWanted = 0;
volatile int SimTopLine = 0;
int SimStepsUnpolled = 0;

namespace
{
const int MaxFrames = 512;
const size_t MaxValueText = 200;      // one value in the stop info
const size_t MaxWatchText = 2000;     // one Watch expression
const size_t ArrayShown = 16;         // elements of an array shown

struct FrameRec
{
  const char *Name;
  int CallerLine;      // SimTopLine of the caller at the call
  size_t LocalsStart;  // locals of the frame: from this index on
  bool Isr;
};

FrameRec Frames[MaxFrames];
int FrameDepth = 0;     // may exceed MaxFrames (deep recursion): not recorded

std::vector<SimVarInfo> &globals()
{
  static std::vector<SimVarInfo> list;
  return list;
}

std::vector<SimVarInfo> &locals()
{
  static std::vector<SimVarInfo> list;
  return list;
}

std::vector<std::string> &files()
{
  static std::vector<std::string> list;
  return list;
}

volatile uint32_t *DbgHeader = nullptr;
volatile uint32_t *DbgBreakList = nullptr;
volatile char *DbgWatchReq = nullptr;
volatile char *DbgFiles = nullptr;
volatile char *DbgInfo = nullptr;

// Sketch thread state
uint32_t SeenBpVersion = 0xFFFFFFFF;
std::vector<uint32_t> Breakpoints;   // sorted
uint32_t AnsweredWatch = 0;
enum StepModes
{
  StepNone,
  StepInto,
  StepOver,
  StepOut,
  StepRunTo
};
int StepMode = StepNone;
int StepDepth = 0;
uint32_t RunToCode = 0;
bool PausePending = false;
bool StepFromIsr = false;    // stopped inside an ISR: steps stay in ISRs too

void loadBreakpoints()
{
  SeenBpVersion = DbgHeader[SimDbgBpVersion];
  uint32_t count = DbgHeader[SimDbgBpCount];
  if (count > SimDbgMaxBreakpoints)
    count = SimDbgMaxBreakpoints;
  Breakpoints.clear();
  for (uint32_t index = 0; index < count; index++)
    Breakpoints.push_back((uint32_t)DbgBreakList[index]);
  std::sort(Breakpoints.begin(), Breakpoints.end());
}

void cleanText(std::string &text, size_t limit)
{
  if (text.size() > limit)
  {
    text.resize(limit);
    text += "...";
  }
  for (char &value : text)
    if (value == '\t' || value == '\n' || value == '\r')
      value = ' ';
}

std::string formatVar(const SimVarInfo &info, size_t limit)
{
  std::string text;
  if (info.Count == 0)
    info.Format(info.Ptr, text);
  else
    simFmtArray(text, info.Ptr, info.Count, info.ElemSize, info.Format, info.IsText);
  cleanText(text, limit);
  return text;
}

// Variable by name: locals of the top frame (the last declared first),
// then globals
const SimVarInfo *findVar(const std::string &name)
{
  std::vector<SimVarInfo> &localList = locals();
  size_t start = 0;
  if (FrameDepth > 0 && FrameDepth <= MaxFrames)
    start = Frames[FrameDepth - 1].LocalsStart;
  for (size_t index = localList.size(); index-- > start;)
    if (name == localList[index].Name)
      return &localList[index];
  for (const SimVarInfo &info : globals())
    if (name == info.Name)
      return &info;
  return nullptr;
}

std::string trim(const std::string &text)
{
  size_t first = text.find_first_not_of(" \t");
  if (first == std::string::npos)
    return std::string();
  size_t last = text.find_last_not_of(" \t");
  return text.substr(first, last - first + 1);
}

// Watch expression: name or name[index]. Result "=value", "?" (no such
// variable), "!" (not understood or index out of range)
std::string evalWatch(const std::string &expr)
{
  std::string text = trim(expr);
  std::string name = text, indexText;
  size_t bracket = text.find('[');
  if (bracket != std::string::npos)
  {
    if (text.back() != ']')
      return "!";
    name = trim(text.substr(0, bracket));
    indexText = trim(text.substr(bracket + 1, text.size() - bracket - 2));
  }
  const SimVarInfo *info = findVar(name);
  if (!info)
    return "?";
  if (indexText.empty())
    return "=" + formatVar(*info, MaxWatchText);
  char *endPtr = nullptr;
  long index = strtol(indexText.c_str(), &endPtr, 0);
  if (endPtr == indexText.c_str() || *endPtr != 0)
  {
    // index - a variable
    const SimVarInfo *indexVar = findVar(indexText);
    if (!indexVar || indexVar->Count != 0)
      return "!";
    std::string value;
    indexVar->Format(indexVar->Ptr, value);
    index = strtol(value.c_str(), &endPtr, 0);
    if (endPtr == value.c_str())
      return "!";
  }
  if (info->Count == 0 || index < 0 || (size_t)index >= info->Count)
    return "!";
  std::string value;
  info->Format((const char *)info->Ptr + (size_t)index * info->ElemSize, value);
  cleanText(value, MaxWatchText);
  return "=" + value;
}

// Info text: "S\tcode\tstopped\n", frames "F\tname\tcode\n" (top first),
// locals of the top frame "L\tname\tvalue\n", globals "G\tname\tvalue\n",
// Watch answers "W\tindex\tresult\n". Seqlock: odd InfoSeq - writing.
void writeInfo(bool stopped)
{
  std::string info;
  info.reserve(16384);
  info += "S\t" + std::to_string(SimTopLine) + "\t" + (stopped ? "1" : "0") + "\n";
  int topFrame = FrameDepth < MaxFrames ? FrameDepth : MaxFrames;
  int lineOfFrame = SimTopLine;
  for (int index = topFrame - 1; index >= 0; index--)
  {
    info += "F\t";
    info += Frames[index].Name;
    info += Frames[index].Isr ? " (ISR)" : "";
    info += "\t" + std::to_string(lineOfFrame) + "\n";
    lineOfFrame = Frames[index].CallerLine;
  }
  std::vector<SimVarInfo> &localList = locals();
  size_t start = topFrame > 0 ? Frames[topFrame - 1].LocalsStart : localList.size();
  for (size_t index = start; index < localList.size(); index++)
    info += std::string("L\t") + localList[index].Name + "\t" + formatVar(localList[index], MaxValueText) + "\n";
  // Watch answers before the globals: they must fit
  std::string request;
  for (size_t index = 0; index < SimDbgWatchReqBytes && DbgWatchReq[index]; index++)
    request += DbgWatchReq[index];
  size_t lineStart = 0;
  int exprIndex = 0;
  while (lineStart < request.size())
  {
    size_t lineEnd = request.find('\n', lineStart);
    if (lineEnd == std::string::npos)
      lineEnd = request.size();
    std::string expr = request.substr(lineStart, lineEnd - lineStart);
    if (!trim(expr).empty())
      info += "W\t" + std::to_string(exprIndex) + "\t" + evalWatch(expr) + "\n";
    exprIndex++;
    lineStart = lineEnd + 1;
  }
  for (const SimVarInfo &var : globals())
  {
    std::string line = std::string("G\t") + var.Name + "\t" + formatVar(var, MaxValueText) + "\n";
    if (info.size() + line.size() >= SimDbgInfoBytes - 1)
      break;
    info += line;
  }
  if (info.size() >= SimDbgInfoBytes)
    info.resize(SimDbgInfoBytes - 1);
  DbgHeader[SimDbgInfoSeq] = DbgHeader[SimDbgInfoSeq] + 1;   // odd
  MemoryBarrier();
  for (size_t index = 0; index < info.size(); index++)
    DbgInfo[index] = info[index];
  DbgInfo[info.size()] = 0;
  DbgHeader[SimDbgInfoBytesIdx] = (uint32_t)info.size();
  MemoryBarrier();
  DbgHeader[SimDbgInfoSeq] = DbgHeader[SimDbgInfoSeq] + 1;   // even
}

bool commandPending()
{
  return DbgHeader[SimDbgCmdSeq] != DbgHeader[SimDbgCmdDone];
}

// The command from the host; pause/step while running - stop at the
// next statement
void takeCommand(bool stopped)
{
  uint32_t code = DbgHeader[SimDbgCmdCode];
  uint32_t arg = DbgHeader[SimDbgCmdArg];
  DbgHeader[SimDbgCmdDone] = DbgHeader[SimDbgCmdSeq];
  if (!stopped)
  {
    if (code == SimCmdPause || code == SimCmdInto || code == SimCmdOver)
      PausePending = true;
    else if (code == SimCmdRunTo)
    {
      StepMode = StepRunTo;
      RunToCode = arg;
    }
    else if (code == SimCmdRun)
    {
      StepMode = StepNone;
      PausePending = false;
    }
    return;
  }
  PausePending = false;
  StepFromIsr = simInIsr();
  switch (code)
  {
    case SimCmdInto:
      StepMode = StepInto;
      break;
    case SimCmdOver:
      StepMode = StepOver;
      StepDepth = FrameDepth;
      break;
    case SimCmdOut:
      StepMode = StepOut;
      StepDepth = FrameDepth;
      break;
    case SimCmdRunTo:
      StepMode = StepRunTo;
      RunToCode = arg;
      break;
    default:
      StepMode = StepNone;
      break;
  }
}

void stopHere()
{
  simClockPause(true);
  DbgHeader[SimDbgStopCode] = (uint32_t)SimTopLine;
  DbgHeader[SimDbgState] = 1;
  writeInfo(true);
  AnsweredWatch = DbgHeader[SimDbgWatchSeq];
  DbgHeader[SimDbgStopSeq] = DbgHeader[SimDbgStopSeq] + 1;
  for (;;)
  {
    if (SimStopping)
      ExitThread(0);
    if (commandPending())
    {
      uint32_t code = DbgHeader[SimDbgCmdCode];
      if (code != SimCmdPause)
      {
        takeCommand(true);
        break;
      }
      DbgHeader[SimDbgCmdDone] = DbgHeader[SimDbgCmdSeq];
    }
    if (DbgHeader[SimDbgWatchSeq] != AnsweredWatch)
    {
      AnsweredWatch = DbgHeader[SimDbgWatchSeq];
      writeInfo(true);
    }
    if (DbgHeader[SimDbgBpVersion] != SeenBpVersion)
      loadBreakpoints();
    Sleep(5);
  }
  DbgHeader[SimDbgState] = 0;
  simClockPause(false);
}
}

void simStepSlow(int code)
{
  if (!DbgHeader)
  {
    SimDebugWanted = 0;
    return;
  }
  bool isr = simInIsr();
  if (DbgHeader[SimDbgBpVersion] != SeenBpVersion)
    loadBreakpoints();
  if (commandPending())
    takeCommand(false);
  bool stop = false;
  if (!Breakpoints.empty() &&
      std::binary_search(Breakpoints.begin(), Breakpoints.end(), (uint32_t)code))
    stop = true;
  if (!stop && StepMode == StepRunTo && (uint32_t)code == RunToCode)
    stop = true;
  if (!stop && (!isr || StepFromIsr))
  {
    if (PausePending || StepMode == StepInto)
      stop = true;
    else if (StepMode == StepOver && FrameDepth <= StepDepth)
      stop = true;
    else if (StepMode == StepOut && FrameDepth < StepDepth)
      stop = true;
  }
  if (stop)
  {
    PausePending = false;
    StepMode = StepNone;
    stopHere();
  }
  else if (DbgHeader[SimDbgWatchSeq] != AnsweredWatch)
  {
    // live Watch while running: values at this statement
    AnsweredWatch = DbgHeader[SimDbgWatchSeq];
    writeInfo(false);
  }
  SimDebugWanted = !Breakpoints.empty() || StepMode != StepNone || PausePending ||
                   commandPending() || DbgHeader[SimDbgWatchSeq] != AnsweredWatch;
}

SimFrame::SimFrame(const char *name)
{
  if (FrameDepth < MaxFrames)
  {
    FrameRec &frame = Frames[FrameDepth];
    frame.Name = name;
    frame.CallerLine = SimTopLine;
    frame.LocalsStart = locals().size();
    frame.Isr = simInIsr();
  }
  FrameDepth++;
}

SimFrame::~SimFrame()
{
  FrameDepth--;
  if (FrameDepth < MaxFrames)
  {
    SimTopLine = Frames[FrameDepth].CallerLine;
    // locals left by an exception or longjmp
    if (locals().size() > Frames[FrameDepth].LocalsStart)
      locals().resize(Frames[FrameDepth].LocalsStart);
  }
}

void simWatchAddGlobal(const SimVarInfo &info) { globals().push_back(info); }
void simWatchPushLocal(const SimVarInfo &info) { locals().push_back(info); }
void simWatchPopLocal()
{
  if (!locals().empty())
    locals().pop_back();
}

SimFileReg::SimFileReg(int index, const char *path)
{
  std::vector<std::string> &list = files();
  if (index < 0 || index > 255)
    return;
  if ((size_t)index >= list.size())
    list.resize(index + 1);
  list[index] = path;
}

// ---------------------------------------------------------------- formatting
void simFmtBool(std::string &out, bool value) { out += value ? "true" : "false"; }

void simFmtChar(std::string &out, char value)
{
  char buffer[32];
  unsigned char code = (unsigned char)value;
  if (code >= 32 && code != 127)
    snprintf(buffer, sizeof(buffer), "'%c' %d", value, (int)(signed char)value);
  else
    snprintf(buffer, sizeof(buffer), "%d", (int)(signed char)value);
  out += buffer;
}

void simFmtInt(std::string &out, long long value) { out += std::to_string(value); }
void simFmtUInt(std::string &out, unsigned long long value) { out += std::to_string(value); }

void simFmtDouble(std::string &out, double value, int digits)
{
  char buffer[64];
  snprintf(buffer, sizeof(buffer), "%.*g", digits, value);
  out += buffer;
}

void simFmtPtr(std::string &out, const void *value)
{
  char buffer[32];
  if (!value)
    out += "nullptr";
  else
  {
    snprintf(buffer, sizeof(buffer), "0x%p", value);
    out += buffer;
  }
}

static void appendQuoted(std::string &out, const char *text, size_t length)
{
  out += '"';
  for (size_t index = 0; index < length; index++)
  {
    char value = text[index];
    if (value == '\n')
      out += "\\n";
    else if (value == '\r')
      out += "\\r";
    else if (value == '\t')
      out += "\\t";
    else if ((unsigned char)value < 32)
      out += '.';
    else
      out += value;
  }
  out += '"';
}

void simFmtCharPtr(std::string &out, const char *value)
{
  if (!value)
  {
    out += "nullptr";
    return;
  }
  // do not crash on a wild pointer
  MEMORY_BASIC_INFORMATION memInfo;
  if (VirtualQuery(value, &memInfo, sizeof(memInfo)) == 0 || memInfo.State != MEM_COMMIT ||
      (memInfo.Protect & (PAGE_NOACCESS | PAGE_GUARD)))
  {
    simFmtPtr(out, value);
    return;
  }
  size_t room = (size_t)((const char *)memInfo.BaseAddress + memInfo.RegionSize - value);
  size_t length = 0;
  while (length < room && length < MaxValueText && value[length])
    length++;
  appendQuoted(out, value, length);
}

void simFmtString(std::string &out, const String &value)
{
  appendQuoted(out, value.c_str(), value.length());
}

void simFmtArray(std::string &out, const void *first, size_t count, size_t elemSize,
                 SimFormatFn format, bool isText)
{
  const char *bytes = (const char *)first;
  if (isText)
  {
    size_t length = 0;
    while (length < count && bytes[length])
      length++;
    appendQuoted(out, bytes, length);
    return;
  }
  out += "{";
  for (size_t index = 0; index < count && index < ArrayShown; index++)
  {
    if (index > 0)
      out += ", ";
    format(bytes + index * elemSize, out);
  }
  if (count > ArrayShown)
    out += ", ...";
  out += "} [" + std::to_string(count) + "]";
}

// ---------------------------------------------------------------- screen texts
// Each print() of UTFT: the rectangle, the text and the statements that
// drew it (SimTopLine and the call lines outwards). Graphic primitives
// (lines, rects, circles, pixels) are kept the same way without text;
// consecutive primitives from the same statement and call chain are merged
// into one entry (a chart curve drawn in a loop is one entry). Each screen
// pixel remembers the graphic entry that painted it last (SimOwnerMap). The
// host asks for a screen point; the answer is the last text drawn there that
// is still on the screen (not covered by a later fill or text), otherwise a
// line or dot within GraphicMargin pixels, otherwise the fill under the point.
uint32_t SimPixelOwner = 0;
uint32_t SimOwnerMap[SIM_SCREEN_H][SIM_SCREEN_W];

namespace
{
struct ScreenText
{
  short X1, Y1, X2, Y2;
  uint32_t Codes[SimDbgWhereMax];
  int CodeCount;
  bool Graphic;
  bool Filled;
  uint32_t Id;
  char Text[SimDbgWhereTextBytes];
};

const int GraphicMargin = 2;      // a click this close to a thin line hits it
const size_t MergeLookBack = 32;  // how far back a primitive looks for its entry

const size_t MaxScreenTexts = 4096;
std::vector<ScreenText> ScreenTexts;
CRITICAL_SECTION TextLock;
bool TextLockReady = false;
uint32_t AnsweredWhere = 0;
uint32_t LastOwnerId = 0;

void textLock()
{
  if (!TextLockReady)
  {
    InitializeCriticalSection(&TextLock);
    TextLockReady = true;
  }
  EnterCriticalSection(&TextLock);
}

void textUnlock() { LeaveCriticalSection(&TextLock); }

// drop the texts lying wholly inside x1..x2, y1..y2 (caller holds the lock)
void forgetInside(int x1, int y1, int x2, int y2)
{
  size_t kept = 0;
  for (size_t index = 0; index < ScreenTexts.size(); index++)
  {
    const ScreenText &item = ScreenTexts[index];
    bool inside = item.X1 >= x1 && item.X2 <= x2 && item.Y1 >= y1 && item.Y2 <= y2;
    if (!inside)
      ScreenTexts[kept++] = item;
  }
  ScreenTexts.resize(kept);
}

// the statement being executed and the call lines outwards
bool collectCodes(ScreenText &item)
{
  item.CodeCount = 0;
  if (SimTopLine != 0)
    item.Codes[item.CodeCount++] = (uint32_t)SimTopLine;
  int depth = FrameDepth < MaxFrames ? FrameDepth : MaxFrames;
  for (int index = depth - 1; index >= 0 && item.CodeCount < SimDbgWhereMax; index--)
    if (Frames[index].CallerLine != 0)
      item.Codes[item.CodeCount++] = (uint32_t)Frames[index].CallerLine;
  return item.CodeCount != 0;   // zero: not an instrumented sketch
}

const ScreenText *findOwner(uint32_t owner)
{
  for (size_t index = ScreenTexts.size(); index-- > 0;)
    if (ScreenTexts[index].Graphic && ScreenTexts[index].Id == owner)
      return &ScreenTexts[index];
  return nullptr;
}

void pushEntry(const ScreenText &item)
{
  if (ScreenTexts.size() >= MaxScreenTexts)
    ScreenTexts.erase(ScreenTexts.begin(), ScreenTexts.begin() + MaxScreenTexts / 4);
  ScreenTexts.push_back(item);
}

bool sameCodes(const ScreenText &left, const ScreenText &right)
{
  if (left.CodeCount != right.CodeCount)
    return false;
  for (int index = 0; index < left.CodeCount; index++)
    if (left.Codes[index] != right.Codes[index])
      return false;
  return true;
}
}

void simTextDrawn(int x1, int y1, int x2, int y2, const char *text)
{
  if (!DbgHeader || !text || !*text)
    return;
  ScreenText item;
  item.X1 = (short)x1;
  item.Y1 = (short)y1;
  item.X2 = (short)x2;
  item.Y2 = (short)y2;
  item.Graphic = false;
  item.Filled = false;
  item.Id = 0;
  if (!collectCodes(item))
    return;
  strncpy(item.Text, text, sizeof(item.Text) - 1);
  item.Text[sizeof(item.Text) - 1] = 0;
  textLock();
  forgetInside(x1, y1, x2, y2);
  pushEntry(item);
  textUnlock();
}

void simGraphicDrawn(int x1, int y1, int x2, int y2, bool filled)
{
  SimPixelOwner = 0;
  if (!DbgHeader)
    return;
  if (x1 > x2)
    std::swap(x1, x2);
  if (y1 > y2)
    std::swap(y1, y2);
  if (x2 < 0 || y2 < 0 || x1 >= SIM_SCREEN_W || y1 >= SIM_SCREEN_H)
    return;
  x1 = x1 < 0 ? 0 : x1;
  y1 = y1 < 0 ? 0 : y1;
  x2 = x2 >= SIM_SCREEN_W ? SIM_SCREEN_W - 1 : x2;
  y2 = y2 >= SIM_SCREEN_H ? SIM_SCREEN_H - 1 : y2;
  ScreenText item;
  item.Graphic = true;
  item.Filled = filled;
  item.Text[0] = 0;
  if (!collectCodes(item))
    return;
  textLock();
  if (filled)
    forgetInside(x1, y1, x2, y2);
  // the same statement in the same call chain: widen its entry, move it last
  size_t stop = ScreenTexts.size() > MergeLookBack ? ScreenTexts.size() - MergeLookBack : 0;
  for (size_t index = ScreenTexts.size(); index-- > stop;)
  {
    ScreenText &prev = ScreenTexts[index];
    if (prev.Graphic && sameCodes(prev, item))
    {
      item.X1 = prev.X1 < x1 ? prev.X1 : (short)x1;
      item.Y1 = prev.Y1 < y1 ? prev.Y1 : (short)y1;
      item.X2 = prev.X2 > x2 ? prev.X2 : (short)x2;
      item.Y2 = prev.Y2 > y2 ? prev.Y2 : (short)y2;
      item.Id = prev.Id;
      item.Filled = prev.Filled || filled;
      SimPixelOwner = item.Id;
      ScreenTexts.erase(ScreenTexts.begin() + index);
      ScreenTexts.push_back(item);
      textUnlock();
      return;
    }
  }
  item.X1 = (short)x1;
  item.Y1 = (short)y1;
  item.X2 = (short)x2;
  item.Y2 = (short)y2;
  if (++LastOwnerId == 0)
    LastOwnerId = 1;
  item.Id = LastOwnerId;
  SimPixelOwner = item.Id;
  pushEntry(item);
  textUnlock();
}

void simAreaFilled(int x1, int y1, int x2, int y2)
{
  if (!DbgHeader)
    return;
  textLock();
  forgetInside(x1, y1, x2, y2);
  textUnlock();
}

namespace
{
// host thread: answer the question about a screen point
void answerWhere()
{
  uint32_t seq = DbgHeader[SimDbgWhereSeq];
  uint32_t point = DbgHeader[SimDbgWhereXY];
  int px = (int)(point & 0xFFFF), py = (int)(point >> 16);
  int count = 0;
  char text[SimDbgWhereTextBytes] = {0};
  uint32_t codes[SimDbgWhereMax] = {0};
  textLock();
  // texts first: the last one whose rectangle holds the point
  const ScreenText *found = nullptr;
  for (size_t index = ScreenTexts.size(); index-- > 0 && !found;)
  {
    const ScreenText &item = ScreenTexts[index];
    if (!item.Graphic && px >= item.X1 && px <= item.X2 && py >= item.Y1 && py <= item.Y2)
      found = &item;
  }
  // then the pixel owners: the nearest line or dot, otherwise the fill there
  const ScreenText *fill = nullptr;
  int bestDistance = 1 << 30;
  for (int dy = -GraphicMargin; dy <= GraphicMargin && !found; dy++)
    for (int dx = -GraphicMargin; dx <= GraphicMargin; dx++)
    {
      int cx = px + dx, cy = py + dy;
      if (cx < 0 || cy < 0 || cx >= SIM_SCREEN_W || cy >= SIM_SCREEN_H)
        continue;
      uint32_t owner = SimOwnerMap[cy][cx];
      if (owner == 0)
        continue;
      const ScreenText *entry = findOwner(owner);
      if (!entry)
        continue;
      int distance = dx * dx + dy * dy;
      if (entry->Filled)
      {
        if (distance == 0)
          fill = entry;
      }
      else if (distance < bestDistance)
      {
        bestDistance = distance;
        found = entry;
      }
    }
  if (!found)
    found = fill;
  if (found)
  {
    count = found->CodeCount;
    memcpy(codes, found->Codes, sizeof(codes));
    memcpy(text, found->Text, sizeof(text));
  }
  textUnlock();
  for (int index = 0; index < SimDbgWhereMax; index++)
    DbgHeader[SimDbgWhereCodes + index] = codes[index];
  for (size_t word = 0; word < SimDbgWhereTextBytes / 4; word++)
  {
    uint32_t value;
    memcpy(&value, text + word * 4, 4);
    DbgHeader[SimDbgWhereText + word] = value;
  }
  DbgHeader[SimDbgWhereCount] = (uint32_t)count;
  MemoryBarrier();
  DbgHeader[SimDbgWhereDone] = seq;
  AnsweredWhere = seq;
}
}

// ---------------------------------------------------------------- host side
void simDebugAttach(void *area)
{
  char *base = (char *)area;
  DbgHeader = (volatile uint32_t *)base;
  DbgBreakList = (volatile uint32_t *)(base + SimDbgBreakOffset);
  DbgWatchReq = (volatile char *)(base + SimDbgWatchReqOffset);
  DbgFiles = (volatile char *)(base + SimDbgFilesOffset);
  DbgInfo = (volatile char *)(base + SimDbgInfoOffset);
  std::string list;
  for (const std::string &path : files())
    list += path + "\n";
  if (list.size() >= SimDbgFilesBytes)
    list.resize(SimDbgFilesBytes - 1);
  for (size_t index = 0; index < list.size(); index++)
    DbgFiles[index] = list[index];
  DbgFiles[list.size()] = 0;
  DbgHeader[SimDbgInstrumented] = files().empty() ? 0 : 1;
  AnsweredWhere = DbgHeader[SimDbgWhereSeq];
  DbgHeader[SimDbgWhereDone] = AnsweredWhere;
  SimDebugWanted = 1;
}

// ---- live arguments
volatile uint32_t *SimArgTable = nullptr;

namespace
{
struct FontRec
{
  const char *Name;
  const uint8_t *Font;
};
std::vector<FontRec> &fonts()
{
  static std::vector<FontRec> list;
  return list;
}
}

SimFontReg::SimFontReg(const char *name, const uint8_t *font)
{
  FontRec rec;
  rec.Name = name;
  rec.Font = font;
  fonts().push_back(rec);
}

void simArgAttach(void *area)
{
  SimArgTable = (volatile uint32_t *)area;
}

bool simArgLookup(int code, uint32_t hash, int occurrence, int index, SimArgHit &hit)
{
  if (!SimArgTable)
    return false;
  uint32_t count = SimArgTable[0];
  if (count > SimArgMaxEntries)
    count = SimArgMaxEntries;
  const size_t entryWords = SimArgEntryBytes / 4;
  for (uint32_t entry = 0; entry < count; entry++)
  {
    volatile uint32_t *fields = SimArgTable + 4 + entry * entryWords;
    if (fields[0] != (uint32_t)code || fields[1] != hash || fields[2] != (uint32_t)occurrence ||
        fields[3] != (uint32_t)index)
      continue;
    hit.Kind = (int)fields[4];
    hit.Number = (int32_t)fields[5];
    hit.Font = nullptr;
    if (hit.Kind == 2)
    {
      char name[41];
      volatile char *text = (volatile char *)(fields + 6);
      size_t length = 0;
      while (length < 40 && text[length])
      {
        name[length] = text[length];
        length++;
      }
      name[length] = 0;
      for (const FontRec &rec : fonts())
        if (strcmp(rec.Name, name) == 0)
          hit.Font = rec.Font;
    }
    return hit.Kind == 1 || hit.Kind == 2;
  }
  return false;
}

// ---- live controls
namespace
{
volatile uint32_t *CtlTable = nullptr;
struct CtlRec
{
  std::string Name;
  uint32_t Hash;
  void *Control;
  SimCtlRedrawFn Redraw;
};
std::vector<CtlRec> &controls()
{
  static std::vector<CtlRec> list;
  return list;
}
// entries as last seen by simCtlPoll: what changed since
struct CtlSeen
{
  uint32_t Hash, Prop, Kind;
  int32_t Number;
  std::string Text;
};
std::vector<CtlSeen> CtlSeenEntries;
uint32_t CtlSeenVersion = 0;
bool CtlRedrawing = false;

uint32_t ctlHash(const char *text)
{
  uint32_t hash = 2166136261u;
  for (; *text; text++)
  {
    hash ^= (unsigned char)*text;
    hash *= 16777619u;
  }
  return hash;
}

const CtlRec *ctlOf(const void *control)
{
  for (const CtlRec &rec : controls())
    if (rec.Control == control)
      return &rec;
  return nullptr;
}

// entry of the host for this control and property, null - none
volatile uint32_t *ctlEntry(const void *control, int prop)
{
  if (!CtlTable || CtlTable[0] == 0)
    return nullptr;
  const CtlRec *rec = ctlOf(control);
  if (!rec)
    return nullptr;
  uint32_t count = CtlTable[0];
  if (count > SimCtlMaxEntries)
    count = SimCtlMaxEntries;
  const size_t entryWords = SimCtlEntryBytes / 4;
  for (uint32_t entry = 0; entry < count; entry++)
  {
    volatile uint32_t *fields = CtlTable + 4 + entry * entryWords;
    if (fields[0] == rec->Hash && fields[1] == (uint32_t)prop && fields[2] != 0)
      return fields;
  }
  return nullptr;
}

std::string ctlText(volatile uint32_t *fields)
{
  std::string text;
  volatile char *chars = (volatile char *)(fields + 4);
  for (size_t index = 0; index < SimCtlTextBytes - 1 && chars[index]; index++)
    text += chars[index];
  return text;
}
}

uint32_t SimScreenClears = 0;

uint32_t simPixelOwnerGet()
{
  return SimPixelOwner;
}

void simPixelOwnerSet(uint32_t owner)
{
  SimPixelOwner = owner;
}

void simCtlRegister(const char *name, void *control, SimCtlRedrawFn redraw)
{
  CtlRec rec;
  rec.Name = name;
  rec.Hash = ctlHash(name);
  rec.Control = control;
  rec.Redraw = redraw;
  controls().push_back(rec);
}

void simCtlAttach(void *area)
{
  CtlTable = (volatile uint32_t *)area;
}

bool simCtlNumber(const void *control, int prop, long &value)
{
  volatile uint32_t *fields = ctlEntry(control, prop);
  if (!fields || fields[2] != 1)
    return false;
  value = (int32_t)fields[3];
  return true;
}

bool simCtlText(const void *control, int prop, String &value)
{
  volatile uint32_t *fields = ctlEntry(control, prop);
  if (!fields || fields[2] != 3)
    return false;
  value = ctlText(fields).c_str();
  return true;
}

bool simCtlFont(const void *control, int prop, uint8_t *&font)
{
  volatile uint32_t *fields = ctlEntry(control, prop);
  if (!fields || fields[2] != 2)
    return false;
  std::string name = ctlText(fields);
  for (const FontRec &rec : fonts())
    if (name == rec.Name)
    {
      font = (uint8_t *)rec.Font;
      return true;
    }
  return false;
}

void simCtlPoll()
{
  if (!CtlTable || CtlRedrawing || CtlTable[1] == CtlSeenVersion)
    return;
  CtlSeenVersion = CtlTable[1];
  uint32_t count = CtlTable[0];
  if (count > SimCtlMaxEntries)
    count = SimCtlMaxEntries;
  const size_t entryWords = SimCtlEntryBytes / 4;
  std::vector<uint32_t> changed;
  std::vector<CtlSeen> now;
  for (uint32_t entry = 0; entry < count; entry++)
  {
    volatile uint32_t *fields = CtlTable + 4 + entry * entryWords;
    CtlSeen seen;
    seen.Hash = fields[0];
    seen.Prop = fields[1];
    seen.Kind = fields[2];
    seen.Number = (int32_t)fields[3];
    seen.Text = ctlText(fields);
    bool same = entry < CtlSeenEntries.size() && CtlSeenEntries[entry].Hash == seen.Hash &&
                CtlSeenEntries[entry].Prop == seen.Prop && CtlSeenEntries[entry].Kind == seen.Kind &&
                CtlSeenEntries[entry].Number == seen.Number && CtlSeenEntries[entry].Text == seen.Text;
    if (!same && std::find(changed.begin(), changed.end(), seen.Hash) == changed.end())
      changed.push_back(seen.Hash);
    now.push_back(seen);
  }
  CtlSeenEntries = now;
  CtlRedrawing = true;
  for (uint32_t hash : changed)
    for (const CtlRec &rec : controls())
      if (rec.Hash == hash && rec.Redraw)
        rec.Redraw(rec.Control);
  CtlRedrawing = false;
}

// Host loop (every 20 ms): wake simStep up when there is something to do
void simDebugHostTick()
{
  if (!DbgHeader)
    return;
  if (DbgHeader[SimDbgWhereSeq] != AnsweredWhere)
    answerWhere();
  if (DbgHeader[SimDbgBpCount] != 0 || DbgHeader[SimDbgBpVersion] != SeenBpVersion ||
      commandPending() || DbgHeader[SimDbgWatchSeq] != AnsweredWatch)
    SimDebugWanted = 1;
}
