// ArdSim debugger, sketch side: breakpoints, stepping, pause, call stack
// and variable values for the Emulator window of unIDE (host mode only).
// ardprep puts the hooks into the sketch (ardsim_debug.h); the debug
// area of the shared memory (sim_internal.h, SimDbg*) carries commands
// and answers. Everything here runs in the sketch thread, except
// simDebugHostTick (host loop thread).
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
  SimDebugWanted = 1;
}

// Host loop (every 20 ms): wake simStep up when there is something to do
void simDebugHostTick()
{
  if (!DbgHeader)
    return;
  if (DbgHeader[SimDbgBpCount] != 0 || DbgHeader[SimDbgBpVersion] != SeenBpVersion ||
      commandPending() || DbgHeader[SimDbgWatchSeq] != AnsweredWatch)
    SimDebugWanted = 1;
}
