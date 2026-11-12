// ArdSim: signal generator for the analog inputs and the tacho.
//
// The rotor turns at Rpm. The tacho gives one pulse per turn on TachoPin:
// LOW for PulseDeg degrees from the mark, HIGH otherwise, so the falling
// edge is the mark. Analog channel n (An) gives, in volts:
//   Offset + sum over k of Hk.amp * cos(k * angle - Hk.phase)
//          + sum of fixed frequencies amp * cos(2*pi*hz*t + phase) + noise
// angle = 0 at the mark, so a phase of P degrees puts the peak of that
// harmonic P degrees of rotation after the mark.
// The settings come from ardsim.ini next to the exe (re-read when it
// changes) and from the window panel.
//
// [DataFile] Enabled=1: A0, A1 and the tacho come from a measurement file
// instead (replayDataFile below).
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include "sim_internal.h"
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cstdarg>
#include <string>
#include <vector>

static const double TwoPi = 6.283185307179586;

static CRITICAL_SECTION ConfigLock;
static bool ConfigLockReady = false;
static SimSignalConfig Pending;          // written by the window thread
static volatile bool PendingReady = false;
static SimSignalConfig Active;           // used by the sketch thread
static bool ActiveReady = false;

// Sketch thread state
static double Revs = 0;                   // turns since start
static uint64_t LastMicros = 0;
static uint32_t NoiseState = 0x12345678;

void simSignalDefaults(SimSignalConfig &config)
{
  memset(&config, 0, sizeof(config));
  config.TachoOn = true;
  config.Rpm = 1500;
  config.TachoPin = 3;
  config.PulseDeg = 10;
  config.TachoAnalog = 4;
  config.Vref = 3.3;
  config.LcdPixelNs = 400;
  for (int channel = 0; channel < SIM_ANALOG_CHANNELS; channel++)
    config.Channel[channel].Offset = channel == 0 || channel == 1 ? 1.65 : 0;
  config.Channel[0].Noise = 0.003;
  config.Channel[0].HarmAmp[1] = 0.30;
  config.Channel[0].HarmPhase[1] = 45;
  config.Channel[0].HarmAmp[2] = 0.05;
  config.Channel[1].Noise = 0.003;
  config.Channel[1].HarmAmp[1] = 0.20;
  config.Channel[1].HarmPhase[1] = 120;
  SimRotor &rotor = config.Rotor;
  rotor.Enabled = true;
  rotor.AnglesWithRotation = true;
  rotor.Sensor[0] = 0;
  rotor.Sensor[1] = 1;
  rotor.UnbMass[0] = 20;
  rotor.UnbAngle[0] = 60;
  rotor.UnbMass[1] = 12;
  rotor.UnbAngle[1] = 200;
  rotor.KAmp[0][0] = 0.010; rotor.KPhase[0][0] = 30;
  rotor.KAmp[0][1] = 0.004; rotor.KPhase[0][1] = 80;
  rotor.KAmp[1][0] = 0.003; rotor.KPhase[1][0] = 110;
  rotor.KAmp[1][1] = 0.009; rotor.KPhase[1][1] = 20;
  config.DataScale = 1;
  config.DataOffset = 2048;
  simRotorApply(config);
}

// ---------------------------------------------------------------- rotor
// "10@0; 5.2@137" -> sum of the weights as a complex number (re, im)
static void weightsSum(const char *text, double sign, double &sumRe, double &sumIm)
{
  sumRe = 0;
  sumIm = 0;
  const char *cursor = text;
  while (*cursor)
  {
    char *end;
    double mass = strtod(cursor, &end);
    if (end == cursor)
    {
      cursor++;
      continue;
    }
    cursor = end;
    while (*cursor == ' ')
      cursor++;
    double angle = 0;
    if (*cursor == '@')
    {
      angle = strtod(cursor + 1, &end);
      cursor = end;
    }
    sumRe += mass * std::cos(sign * angle * TwoPi / 360.0);
    sumIm += mass * std::sin(sign * angle * TwoPi / 360.0);
  }
}

void simRotorResponse(const SimSignalConfig &config, int sensor, double &amp, double &phase)
{
  const SimRotor &rotor = config.Rotor;
  double totalRe = 0, totalIm = 0;
  // the model works with angles against rotation
  double sign = rotor.AnglesWithRotation ? -1 : 1;
  for (int plane = 0; plane < SIM_PLANES; plane++)
  {
    double weightRe, weightIm;
    weightsSum(rotor.Weights[plane], sign, weightRe, weightIm);
    double unbAngle = sign * rotor.UnbAngle[plane] * TwoPi / 360.0;
    double unbRe = rotor.UnbMass[plane] * std::cos(unbAngle) + weightRe;
    double unbIm = rotor.UnbMass[plane] * std::sin(unbAngle) + weightIm;
    double kRe = rotor.KAmp[sensor][plane] * std::cos(rotor.KPhase[sensor][plane] * TwoPi / 360.0);
    double kIm = rotor.KAmp[sensor][plane] * std::sin(rotor.KPhase[sensor][plane] * TwoPi / 360.0);
    totalRe += kRe * unbRe - kIm * unbIm;
    totalIm += kRe * unbIm + kIm * unbRe;
  }
  amp = std::sqrt(totalRe * totalRe + totalIm * totalIm);
  phase = std::atan2(totalIm, totalRe) * 360.0 / TwoPi;
  if (phase < 0)
    phase += 360;
}

void simRotorApply(SimSignalConfig &config)
{
  if (!config.Rotor.Enabled)
    return;
  for (int sensor = 0; sensor < SIM_PLANES; sensor++)
  {
    int channel = config.Rotor.Sensor[sensor];
    if (channel < 0 || channel >= SIM_ANALOG_CHANNELS)
      continue;
    simRotorResponse(config, sensor, config.Channel[channel].HarmAmp[1], config.Channel[channel].HarmPhase[1]);
  }
}

static void ensureLock()
{
  if (!ConfigLockReady)
  {
    InitializeCriticalSection(&ConfigLock);
    ConfigLockReady = true;
  }
}

void simSignalSet(const SimSignalConfig &config)
{
  SimLcdPixelNs = config.LcdPixelNs;
  ensureLock();
  EnterCriticalSection(&ConfigLock);
  Pending = config;
  PendingReady = true;
  LeaveCriticalSection(&ConfigLock);
}

// ---------------------------------------------------------------- ini
static double iniNumber(const char *path, const char *section, const char *key, double fallback)
{
  char text[64];
  GetPrivateProfileStringA(section, key, "", text, sizeof(text), path);
  if (!text[0])
    return fallback;
  return strtod(text, nullptr);
}

// "amp,phase" or "hz,amp,phase"
static int iniList(const char *path, const char *section, const char *key, double *values, int count)
{
  char text[128];
  GetPrivateProfileStringA(section, key, "", text, sizeof(text), path);
  int found = 0;
  char *cursor = text;
  while (found < count && *cursor)
  {
    char *end;
    double value = strtod(cursor, &end);
    if (end == cursor)
      break;
    values[found++] = value;
    cursor = end;
    while (*cursor == ',' || *cursor == ' ' || *cursor == ';')
      cursor++;
  }
  return found;
}

bool simSignalLoad(const char *path, SimSignalConfig &config)
{
  if (GetFileAttributesA(path) == INVALID_FILE_ATTRIBUTES)
    return false;
  SimSignalConfig defaults;
  simSignalDefaults(defaults);
  memset(&config, 0, sizeof(config));
  config.TachoOn = iniNumber(path, "Tacho", "Enabled", 1) != 0;
  config.Rpm = iniNumber(path, "Tacho", "RPM", defaults.Rpm);
  config.TachoPin = (int)iniNumber(path, "Tacho", "Pin", defaults.TachoPin);
  config.PulseDeg = iniNumber(path, "Tacho", "PulseDeg", defaults.PulseDeg);
  config.TachoAnalog = (int)iniNumber(path, "Tacho", "Analog", defaults.TachoAnalog);
  config.Vref = iniNumber(path, "ADC", "Vref", defaults.Vref);
  config.SdFail = iniNumber(path, "SD", "Fail", 0) != 0;
  config.LcdPixelNs = iniNumber(path, "LCD", "PixelNs", defaults.LcdPixelNs);
  config.DataOn = iniNumber(path, "DataFile", "Enabled", 0) != 0;
  GetPrivateProfileStringA("DataFile", "Path", "", config.DataPath, sizeof(config.DataPath), path);
  config.DataScale = iniNumber(path, "DataFile", "Scale", defaults.DataScale);
  config.DataOffset = iniNumber(path, "DataFile", "Offset", defaults.DataOffset);
  config.DataRpm = iniNumber(path, "DataFile", "RPM", 0);
  for (int channel = 0; channel < SIM_ANALOG_CHANNELS; channel++)
  {
    char section[8];
    snprintf(section, sizeof(section), "A%d", channel);
    SimChannel &target = config.Channel[channel];
    target.Offset = iniNumber(path, section, "Offset", 0);
    target.Noise = iniNumber(path, section, "Noise", 0);
    for (int harmonic = 1; harmonic <= SIM_HARMONICS; harmonic++)
    {
      char key[8];
      snprintf(key, sizeof(key), "H%d", harmonic);
      double values[2] = {0, 0};
      if (iniList(path, section, key, values, 2) > 0)
      {
        target.HarmAmp[harmonic] = values[0];
        target.HarmPhase[harmonic] = values[1];
      }
    }
    for (int index = 0; index < SIM_FIXED_FREQS; index++)
    {
      char key[8];
      snprintf(key, sizeof(key), "Freq%d", index + 1);
      double values[3] = {0, 0, 0};
      if (iniList(path, section, key, values, 3) >= 2)
      {
        target.FreqHz[index] = values[0];
        target.FreqAmp[index] = values[1];
        target.FreqPhase[index] = values[2];
      }
    }
  }
  SimRotor &rotor = config.Rotor;
  rotor.Enabled = iniNumber(path, "Rotor", "Enabled", defaults.Rotor.Enabled ? 1 : 0) != 0;
  {
    char direction[32];
    GetPrivateProfileStringA("Rotor", "Angles", "with", direction, sizeof(direction), path);
    rotor.AnglesWithRotation = _stricmp(direction, "against") != 0;
  }
  for (int plane = 0; plane < SIM_PLANES; plane++)
  {
    char key[16];
    snprintf(key, sizeof(key), "Sensor%d", plane + 1);
    rotor.Sensor[plane] = (int)iniNumber(path, "Rotor", key, defaults.Rotor.Sensor[plane]);
    double values[2] = {defaults.Rotor.UnbMass[plane], defaults.Rotor.UnbAngle[plane]};
    snprintf(key, sizeof(key), "Unbalance%d", plane + 1);
    iniList(path, "Rotor", key, values, 2);
    rotor.UnbMass[plane] = values[0];
    rotor.UnbAngle[plane] = values[1];
    snprintf(key, sizeof(key), "Weights%d", plane + 1);
    GetPrivateProfileStringA("Rotor", key, "", rotor.Weights[plane], SIM_WEIGHTS_TEXT, path);
    for (int sensor = 0; sensor < SIM_PLANES; sensor++)
    {
      snprintf(key, sizeof(key), "K%d%d", sensor + 1, plane + 1);
      values[0] = defaults.Rotor.KAmp[sensor][plane];
      values[1] = defaults.Rotor.KPhase[sensor][plane];
      iniList(path, "Rotor", key, values, 2);
      rotor.KAmp[sensor][plane] = values[0];
      rotor.KPhase[sensor][plane] = values[1];
    }
  }
  simRotorApply(config);
  return true;
}

static void iniWrite(const char *path, const char *section, const char *key, const char *format, ...)
{
  char text[96];
  va_list args;
  va_start(args, format);
  vsnprintf(text, sizeof(text), format, args);
  va_end(args);
  WritePrivateProfileStringA(section, key, text, path);
}

bool simSignalSave(const char *path, const SimSignalConfig &config)
{
  iniWrite(path, "Tacho", "Enabled", "%d", config.TachoOn ? 1 : 0);
  iniWrite(path, "Tacho", "RPM", "%g", config.Rpm);
  iniWrite(path, "Tacho", "Pin", "%d", config.TachoPin);
  iniWrite(path, "Tacho", "PulseDeg", "%g", config.PulseDeg);
  iniWrite(path, "Tacho", "Analog", "%d", config.TachoAnalog);
  iniWrite(path, "ADC", "Vref", "%g", config.Vref);
  iniWrite(path, "SD", "Fail", "%d", config.SdFail ? 1 : 0);
  iniWrite(path, "LCD", "PixelNs", "%g", config.LcdPixelNs);
  iniWrite(path, "DataFile", "Enabled", "%d", config.DataOn ? 1 : 0);
  WritePrivateProfileStringA("DataFile", "Path", config.DataPath, path);
  iniWrite(path, "DataFile", "Scale", "%g", config.DataScale);
  iniWrite(path, "DataFile", "Offset", "%g", config.DataOffset);
  iniWrite(path, "DataFile", "RPM", "%g", config.DataRpm);
  const SimRotor &rotor = config.Rotor;
  iniWrite(path, "Rotor", "Enabled", "%d", rotor.Enabled ? 1 : 0);
  WritePrivateProfileStringA("Rotor", "Angles", rotor.AnglesWithRotation ? "with" : "against", path);
  for (int plane = 0; plane < SIM_PLANES; plane++)
  {
    char key[16];
    snprintf(key, sizeof(key), "Sensor%d", plane + 1);
    iniWrite(path, "Rotor", key, "%d", rotor.Sensor[plane]);
    snprintf(key, sizeof(key), "Unbalance%d", plane + 1);
    iniWrite(path, "Rotor", key, "%g,%g", rotor.UnbMass[plane], rotor.UnbAngle[plane]);
    for (int sensor = 0; sensor < SIM_PLANES; sensor++)
    {
      snprintf(key, sizeof(key), "K%d%d", sensor + 1, plane + 1);
      iniWrite(path, "Rotor", key, "%g,%g", rotor.KAmp[sensor][plane], rotor.KPhase[sensor][plane]);
    }
    snprintf(key, sizeof(key), "Weights%d", plane + 1);
    WritePrivateProfileStringA("Rotor", key, rotor.Weights[plane], path);
  }
  for (int channel = 0; channel < SIM_ANALOG_CHANNELS; channel++)
  {
    const SimChannel &source = config.Channel[channel];
    bool used = source.Offset != 0 || source.Noise != 0;
    for (int harmonic = 1; harmonic <= SIM_HARMONICS; harmonic++)
      used = used || source.HarmAmp[harmonic] != 0;
    for (int index = 0; index < SIM_FIXED_FREQS; index++)
      used = used || source.FreqAmp[index] != 0;
    char section[8];
    snprintf(section, sizeof(section), "A%d", channel);
    if (!used)
    {
      WritePrivateProfileStringA(section, nullptr, nullptr, path);   // drop the section
      continue;
    }
    iniWrite(path, section, "Offset", "%g", source.Offset);
    iniWrite(path, section, "Noise", "%g", source.Noise);
    for (int harmonic = 1; harmonic <= SIM_HARMONICS; harmonic++)
    {
      char key[8];
      snprintf(key, sizeof(key), "H%d", harmonic);
      if (source.HarmAmp[harmonic] != 0)
        iniWrite(path, section, key, "%g,%g", source.HarmAmp[harmonic], source.HarmPhase[harmonic]);
      else
        WritePrivateProfileStringA(section, key, nullptr, path);
    }
    for (int index = 0; index < SIM_FIXED_FREQS; index++)
    {
      char key[8];
      snprintf(key, sizeof(key), "Freq%d", index + 1);
      if (source.FreqAmp[index] != 0)
        iniWrite(path, section, key, "%g,%g,%g", source.FreqHz[index], source.FreqAmp[index], source.FreqPhase[index]);
      else
        WritePrivateProfileStringA(section, key, nullptr, path);
    }
  }
  return true;
}

// ---------------------------------------------------------------- sketch thread
static void takePending()
{
  if (!PendingReady)
    return;
  EnterCriticalSection(&ConfigLock);
  Active = Pending;
  PendingReady = false;
  LeaveCriticalSection(&ConfigLock);
  ActiveReady = true;
}

// ---------------------------------------------------------------- data file
// Measurement file (Test.dat written by the PC program from BalA-190
// firmware data): frames of 4 little-endian int16 - A0, A1 (around zero),
// A4 tacho (raw ADC), and -32000, or at a mark (the frame after the tacho
// falling edge) the micros since the previous mark minus 32000. The file
// is played as a signal in real (sim) time: frame time is taken from the
// mark times, without them from the tacho channel and the RPM. The span
// from the first to the last mark (whole turns) repeats, so the sketch
// measures as on a running rotor. A0/A1 counts = Offset + Scale * value.
struct DataReplay
{
  std::string Path;
  bool Loaded;
  std::vector<short> Frames;     // 4 values per frame
  int Count;                     // frames
  std::vector<int> Marks;        // frame index of each mark, rising order
  double FrameUs;                // micros per frame
  double Pos;                    // current frame position (Marks.front() .. Marks.back())
  double RevBase;                // whole turns of the passed loops
  double DataRpm, TachoRpm;      // ini values of the last load
};
static DataReplay Replay = {"", false, std::vector<short>(), 0, std::vector<int>(), 0, 0, 0, 0, 0};

static bool replayActive()
{
  return Active.DataOn && Replay.Loaded;
}

// Garmoniki.txt next to Test.dat (PC program): line k - harmonic k of the
// rotation frequency, "Hz<TAB>A1<TAB>A2" with decimal commas, line 0 - 0 Hz
// without the Hz column. RPM = 60 * Hz of the last line / its number;
// 0 - no file or nothing to read
static double harmonicsRpm(const std::string &dataPath)
{
  size_t slash = dataPath.find_last_of("\\/");
  std::string dir = slash == std::string::npos ? std::string() : dataPath.substr(0, slash + 1);
  FILE *input = fopen((dir + "Garmoniki.txt").c_str(), "r");
  if (!input)
    return 0;
  char line[256];
  int lineNo = -1;
  double rpm = 0;
  while (fgets(line, sizeof(line), input))
  {
    lineNo++;
    if (lineNo == 0 || line[0] == '\t')
      continue;
    for (char *cursor = line; *cursor && *cursor != '\t'; cursor++)
      if (*cursor == ',')
        *cursor = '.';
    double hz = atof(line);
    if (hz > 0)
      rpm = 60.0 * hz / lineNo;
  }
  fclose(input);
  return rpm;
}

// File -> Replay; false: not readable, too short or without turns
static bool replayLoad(const char *path, double rpm)
{
  Replay.Path = path;
  Replay.Loaded = false;
  Replay.Frames.clear();
  Replay.Marks.clear();
  Replay.Count = 0;
  // relative path - from the exe folder (ardsim.ini is there too)
  std::string fullPath = path;
  if (!fullPath.empty() && fullPath[0] != '\\' && fullPath[0] != '/' &&
      (fullPath.size() < 2 || fullPath[1] != ':'))
    fullPath = simExeDir() + fullPath;
  FILE *input = fopen(fullPath.c_str(), "rb");
  if (!input)
    return false;
  std::vector<short> data;
  short chunk[4096];
  size_t got;
  while ((got = fread(chunk, sizeof(short), 4096, input)) > 0)
    data.insert(data.end(), chunk, chunk + got);
  fclose(input);
  int count = (int)(data.size() / 4);
  if (count < 64)
    return false;
  // Mark times in channel 3
  std::vector<int> marks;
  double markUs = 0;
  for (int frame = 0; frame < count; frame++)
    if (data[frame * 4 + 3] != -32000 && data[frame * 4 + 3] != 0)
    {
      if (marks.empty())
        marks.push_back(0);      // the measurement starts at a mark
      // the same time in two frames in a row (seen in a real file): one mark
      if (frame - marks.back() < 4)
        continue;
      marks.push_back(frame);
      markUs += data[frame * 4 + 3] + 32000.0;
    }
  double frameUs = 0;
  if (marks.size() >= 2)
    frameUs = markUs / marks.back();
  else
  {
    // No mark times: falling edges of the tacho channel, frame time from the RPM
    marks.clear();
    int low = 32767, high = -32768;
    for (int frame = 0; frame < count; frame++)
    {
      int value = data[frame * 4 + 2];
      if (value < low) low = value;
      if (value > high) high = value;
    }
    if (high - low > 100)
    {
      int lowLevel = low + (high - low) / 3, highLevel = high - (high - low) / 3;
      bool isHigh = data[2] > lowLevel;
      for (int frame = 1; frame < count; frame++)
      {
        int value = data[frame * 4 + 2];
        if (isHigh && value < lowLevel)
        {
          isHigh = false;
          marks.push_back(frame);
        }
        else if (!isHigh && value > highLevel)
          isHigh = true;
      }
    }
    // RPM: [DataFile] RPM, else Garmoniki.txt next to the file, else [Tacho] RPM
    if (rpm <= 0)
      rpm = harmonicsRpm(fullPath);
    if (rpm <= 0)
      rpm = Active.Rpm;
    if (marks.size() < 2 || rpm <= 0)
      return false;
    frameUs = 60e6 / rpm * (marks.size() - 1) / (marks.back() - marks.front());
  }
  if (frameUs <= 0)
    return false;
  Replay.Frames.swap(data);
  Replay.Count = count;
  Replay.Marks.swap(marks);
  Replay.FrameUs = frameUs;
  Replay.Pos = Replay.Marks.front();
  Replay.RevBase = std::ceil(Revs);
  Replay.Loaded = true;
  return true;
}

// Index of the turn that holds frame position pos
static int replayTurn(double pos)
{
  const std::vector<int> &marks = Replay.Marks;
  int low = 0, high = (int)marks.size() - 2;
  while (low < high)
  {
    int middle = (low + high + 1) / 2;
    if (marks[middle] <= pos)
      low = middle;
    else
      high = middle - 1;
  }
  return low;
}

static double replayRevs()
{
  int turn = replayTurn(Replay.Pos);
  double length = Replay.Marks[turn + 1] - Replay.Marks[turn];
  return Replay.RevBase + turn + (Replay.Pos - Replay.Marks[turn]) / length;
}

// Path or switch changed in the ini: (re)load on the sketch thread
static void replayCheck()
{
  if (!Active.DataOn)
    return;
  // the RPM fields matter for a file without mark times: reload on a change
  if (Replay.Path != Active.DataPath || Replay.DataRpm != Active.DataRpm ||
      Replay.TachoRpm != Active.Rpm)
  {
    Replay.DataRpm = Active.DataRpm;
    Replay.TachoRpm = Active.Rpm;
    replayLoad(Active.DataPath, Active.DataRpm);
  }
}

static double replayValue(int channel)
{
  double pos = Replay.Pos;
  int frame = (int)pos;
  if (frame >= Replay.Count - 1)
    frame = Replay.Count - 2;
  double frac = pos - frame;
  double first = Replay.Frames[frame * 4 + channel];
  double second = Replay.Frames[(frame + 1) * 4 + channel];
  return first + (second - first) * frac;
}

// Advances the rotor to "now". Returns tacho edges since the last call:
// bit 0 - a falling edge (mark), bit 1 - a rising edge (end of pulse)
int simSignalAdvance(uint64_t now)
{
  takePending();
  if (!ActiveReady)
  {
    simSignalDefaults(Active);
    ActiveReady = true;
  }
  if (LastMicros == 0 || now < LastMicros)
  {
    LastMicros = now;
    return 0;
  }
  replayCheck();
  double pulse = Active.PulseDeg / 360.0;
  double before = Revs;
  if (replayActive())
  {
    Replay.Pos += (double)(now - LastMicros) / Replay.FrameUs;
    LastMicros = now;
    double loopLength = Replay.Marks.back() - Replay.Marks.front();
    while (Replay.Pos >= Replay.Marks.back())
    {
      Replay.Pos -= loopLength;
      Replay.RevBase += Replay.Marks.size() - 1;
    }
    Revs = replayRevs();
    if (Revs <= before)
      return 0;
  }
  else
  {
    double turns = (double)(now - LastMicros) * Active.Rpm / 60e6;
    LastMicros = now;
    if (turns <= 0)
      return 0;
    Revs += turns;
  }
  if (!Active.TachoOn)
    return 0;
  int edges = 0;
  if (std::floor(Revs) != std::floor(before))
    edges |= 1;
  if (std::floor(Revs - pulse) != std::floor(before - pulse))
    edges |= 2;
  return edges;
}

uint64_t simSignalNextEdge()
{
  if (!ActiveReady || !Active.TachoOn || LastMicros == 0)
    return UINT64_MAX;
  bool replay = replayActive();
  if (!replay && Active.Rpm <= 0)
    return UINT64_MAX;
  double pulse = Active.PulseDeg / 360.0;
  double toFall = std::floor(Revs) + 1 - Revs;
  double toRise = std::floor(Revs - pulse) + 1 - (Revs - pulse);
  double turns = toFall < toRise ? toFall : toRise;
  if (replay)
  {
    // turn length of the current turn of the file
    int turn = replayTurn(Replay.Pos);
    double frames = Replay.Marks[turn + 1] - Replay.Marks[turn];
    return LastMicros + (uint64_t)(turns * frames * Replay.FrameUs);
  }
  return LastMicros + (uint64_t)(turns * 60e6 / Active.Rpm);
}

// takes a changed ini first: SD.begin in setup() may run before the first tick
bool simSdFail()
{
  takePending();
  return ActiveReady && Active.SdFail;
}

int simTachoPin()
{
  return ActiveReady ? Active.TachoPin : 3;
}

int simTachoLevel()
{
  if (!ActiveReady || !Active.TachoOn || (Active.Rpm <= 0 && !replayActive()))
    return 1;
  double fraction = Revs - std::floor(Revs);
  return fraction < Active.PulseDeg / 360.0 ? 0 : 1;
}

static double noise()
{
  // sum of 4 uniform values: close to normal, sigma ~ 1
  double sum = 0;
  for (int index = 0; index < 4; index++)
  {
    NoiseState ^= NoiseState << 13;
    NoiseState ^= NoiseState >> 17;
    NoiseState ^= NoiseState << 5;
    sum += (NoiseState & 0xFFFF) / 65535.0 - 0.5;
  }
  return sum * 1.732;
}

double simSignalVolts(int channel, uint64_t now)
{
  if (!ActiveReady || channel < 0 || channel >= SIM_ANALOG_CHANNELS)
    return 0;
  if (channel == Active.TachoAnalog && Active.TachoOn)
    return simTachoLevel() ? Active.Vref : 0;
  if (replayActive())
  {
    if (channel != 0 && channel != 1)
      return 0;
    double counts = Active.DataOffset + Active.DataScale * replayValue(channel);
    return counts / 4096.0 * Active.Vref;
  }
  const SimChannel &source = Active.Channel[channel];
  double angle = TwoPi * (Revs - std::floor(Revs));
  double volts = source.Offset;
  for (int harmonic = 1; harmonic <= SIM_HARMONICS; harmonic++)
    if (source.HarmAmp[harmonic] != 0)
      volts += source.HarmAmp[harmonic] * std::cos(harmonic * angle - source.HarmPhase[harmonic] * TwoPi / 360.0);
  double seconds = now / 1e6;
  for (int index = 0; index < SIM_FIXED_FREQS; index++)
    if (source.FreqAmp[index] != 0)
    {
      double cycles = source.FreqHz[index] * seconds;
      cycles -= std::floor(cycles);
      volts += source.FreqAmp[index] * std::cos(TwoPi * cycles + source.FreqPhase[index] * TwoPi / 360.0);
    }
  if (source.Noise != 0)
    volts += source.Noise * noise();
  return volts;
}

double simSignalVref() { return ActiveReady ? Active.Vref : 3.3; }
