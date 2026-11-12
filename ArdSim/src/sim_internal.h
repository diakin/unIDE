// ArdSim: state shared by the simulator parts (not for the sketch)
#ifndef ARDSIM_INTERNAL_H
#define ARDSIM_INTERNAL_H
#include <stdint.h>
#include <string>

#define SIM_SCREEN_W 480
#define SIM_SCREEN_H 320
#define SIM_KEY_ROWS 5
#define SIM_KEY_COLS 4

// Frame buffer RGB565, [y][x]; written by the sketch thread, read by the
// window thread (tearing is acceptable)
extern uint16_t SimScreen[SIM_SCREEN_H][SIM_SCREEN_W];
extern volatile uint32_t SimScreenVersion;
// Time of one pixel on the real display, ns ([LCD] PixelNs in ardsim.ini)
extern volatile double SimLcdPixelNs;

// Keypad: the window thread posts presses, the sketch thread applies them
// in simPoll(). Row/col - position in the device key grid (0-based, row 0
// = top row "F1 F2 # *")
void simPostKey(int row, int col, int holdMs);
// Text for the key in the grid
const char *simKeyCaption(int row, int col);

// Serial output: the sketch thread appends, the window thread shows
void simSerialAppend(const char *text, size_t length);
std::string simSerialTake();

// Folder of the simulator exe (with trailing backslash)
std::string simExeDir();

// Called by the window code
void simStartSketch();
void simRequestStop();
extern volatile bool SimStopping;
// Time since the simulator start, microseconds (no simPoll)
uint64_t simMicrosNow();

// Host mode: no own window, shared memory "Local\ArdSim_<name>"
// (sim_host.cpp); returns the exit code
int simHostRun(const char *name);

// Clock of the sketch stops while the debugger holds it (sim_core.cpp)
void simClockPause(bool paused);
bool simInIsr();

// Debugger (sim_debug.cpp). The debug area follows the Serial ring in
// the shared memory of host mode; offsets from its start:
//   0      uint32[64] header (SimDbg* indexes)
//   256    uint32[1024] breakpoints, (file << 20) | line   host
//   4352   char[4096] Watch expressions, one per line      host
//   8448   char[4096] .ino paths by file index, "\n"       simulator
//   12544  char[65536] stop info (sim_debug.cpp, writeInfo)  simulator
enum SimDbgIndex
{
  SimDbgCmdSeq = 0,        // host: +1 with each command
  SimDbgCmdCode = 1,       // host: SimCmd*
  SimDbgCmdArg = 2,        // host: code of the line for SimCmdRunTo
  SimDbgCmdDone = 3,       // simulator: CmdSeq of the last command taken
  SimDbgState = 4,         // simulator: 1 - stopped
  SimDbgStopCode = 5,      // simulator: (file << 20) | line of the stop
  SimDbgStopSeq = 6,       // simulator: +1 with each stop
  SimDbgBpVersion = 7,     // host: +1 when the list changes
  SimDbgBpCount = 8,       // host
  SimDbgWatchSeq = 9,      // host: +1 - write the info again
  SimDbgInfoSeq = 10,      // simulator: odd while writing the info
  SimDbgInfoBytesIdx = 11, // simulator
  SimDbgInstrumented = 12, // simulator: 1 - the sketch has the hooks
  // "where is this text drawn": a click on the screen in the host
  SimDbgWhereSeq = 13,     // host: +1 with each question
  SimDbgWhereXY = 14,      // host: x | (y << 16), screen point
  SimDbgWhereDone = 15,    // simulator: WhereSeq answered (after the fields below)
  SimDbgWhereCount = 16,   // simulator: number of codes, 0 - no text there
  SimDbgWhereCodes = 17,   // simulator: SimDbgWhereMax codes, the drawing statement first,
                           // then the calls that led to it (callers outwards)
  SimDbgWhereText = 23     // simulator: the text drawn, up to the end of the header, 0-ended
};
const int SimDbgWhereMax = 6;
const size_t SimDbgWhereTextBytes = (64 - SimDbgWhereText) * 4;
enum SimDbgCommand
{
  SimCmdPause = 1,
  SimCmdRun = 2,
  SimCmdInto = 3,
  SimCmdOver = 4,
  SimCmdOut = 5,
  SimCmdRunTo = 6
};
const unsigned SimDbgMaxBreakpoints = 1024;
const size_t SimDbgBreakOffset = 256;
const size_t SimDbgWatchReqOffset = 4352;
const size_t SimDbgWatchReqBytes = 4096;
const size_t SimDbgFilesOffset = 8448;
const size_t SimDbgFilesBytes = 4096;
const size_t SimDbgInfoOffset = 12544;
const size_t SimDbgInfoBytes = 65536;
const size_t SimDbgAreaBytes = SimDbgInfoOffset + SimDbgInfoBytes;
void simDebugAttach(void *area);
// Live arguments (ardsim_debug.h, SIM_ARG): table of the host after the
// debug area. Offsets from its start:
//   0     uint32 count of entries in use (host; entries are only added
//         or changed in place, kind written last)
//   16    entries of SimArgEntryBytes:
//         uint32 code, hash, occurrence, index, kind (0 - empty, 1 -
//         number, 2 - font); int32 number; char font[40] (array name)
const size_t SimArgEntryBytes = 64;
const size_t SimArgMaxEntries = 256;
const size_t SimArgTableBytes = 16 + SimArgEntryBytes * SimArgMaxEntries;
void simArgAttach(void *area);
// Live controls (ardsim_debug.h, simCtl*): host table after the arguments
// table. Offsets from its start:
//   0     uint32 count of entries in use; 4 uint32 version (host: +1 after
//         every change)
//   16    entries of SimCtlEntryBytes: uint32 hash (FNV-1a of the control
//         name), property, kind (0 - empty, 1 - number, 2 - font, 3 -
//         text); int32 number; char text[SimCtlTextBytes] (font array name
//         or text, ANSI, zero-terminated)
//   SimCtlShownOffset: what the controls show now (the simulator writes,
//         the host draws the marker and drags): uint32 screen clears now
//         (SimScreenClears), count of controls, SimCtlShownBytes (the
//         host checks it); from +16 entries of SimCtlShownBytes in the
//         order of registration: uint32 hash of the name, screen clears at
//         the last drawing (0xFFFFFFFF - not drawn), int16 left, top (as
//         drawn), int16 box left, top, right, bottom (pixels it took),
//         uint16 font color, color (text background); uint8 font width,
//         height; from +32 the caption as drawn (ANSI, zero-ended)
const size_t SimCtlEntryBytes = 128;
const size_t SimCtlTextBytes = SimCtlEntryBytes - 16;
const size_t SimCtlMaxEntries = 128;
const size_t SimCtlShownOffset = 16 + SimCtlEntryBytes * SimCtlMaxEntries;
const size_t SimCtlShownBytes = 128;
const size_t SimCtlShownTextOffset = 32;
const size_t SimCtlMaxControls = 1024;
const size_t SimCtlTableBytes = SimCtlShownOffset + 16 + SimCtlShownBytes * SimCtlMaxControls;
void simCtlAttach(void *area);
// clrScr / fillScr: SimScreenClears + 1, also in the host table
void simCtlScreenCleared();
// the point is inside a control drawn on this screen: the lines of its
// drawing (smallest control there); false - none
bool simCtlWhere(int px, int py, uint32_t *codes, int &count);
// simPoll: redraw controls whose host entries changed
void simCtlPoll();
void simDebugHostTick();
// Screen texts for "where is this drawn" (sim_utft.cpp -> sim_debug.cpp):
// a text with its rectangle and the call stack; a filled area forgets
// the texts lying wholly inside it
void simTextDrawn(int x1, int y1, int x2, int y2, const char *text);
// graphic entry that the pixels being drawn now belong to (0: text or none)
extern uint32_t SimPixelOwner;
extern uint32_t SimOwnerMap[SIM_SCREEN_H][SIM_SCREEN_W];
void simGraphicDrawn(int x1, int y1, int x2, int y2, bool filled);
void simAreaFilled(int x1, int y1, int x2, int y2);

// Signal generator (sim_signal.cpp)
#define SIM_ANALOG_CHANNELS 12
#define SIM_HARMONICS 10
#define SIM_FIXED_FREQS 4
struct SimChannel
{
  double Offset, Noise;                                  // volts
  double HarmAmp[SIM_HARMONICS + 1], HarmPhase[SIM_HARMONICS + 1];  // [1..10]: volts, degrees
  double FreqHz[SIM_FIXED_FREQS], FreqAmp[SIM_FIXED_FREQS], FreqPhase[SIM_FIXED_FREQS];
};
// Rotor: the 1st harmonic of the sensor channels comes from the
// unbalance. Plane p carries the initial unbalance and the weights put
// on the rotor (mass at the trial radius, angle in degrees from the
// zero mark). AnglesWithRotation: angles go in the direction of rotation
// (as the device shows the correction angle); otherwise against it.
// A weight B degrees against rotation from the mark passes the sensor B
// degrees of rotation after the mark, so its response phase grows by B.
// Sensor s gives
//   V_s = sum_p K[s][p] * (initial_p + weights_p)   (complex)
// K: volts per gram and phase lag in degrees.
#define SIM_PLANES 2
#define SIM_WEIGHTS_TEXT 256
struct SimRotor
{
  bool Enabled;
  bool AnglesWithRotation;
  int Sensor[SIM_PLANES];                    // analog channels (A0, A1)
  double UnbMass[SIM_PLANES], UnbAngle[SIM_PLANES];
  double KAmp[SIM_PLANES][SIM_PLANES], KPhase[SIM_PLANES][SIM_PLANES];   // [sensor][plane]
  char Weights[SIM_PLANES][SIM_WEIGHTS_TEXT]; // "10@0; 5.2@137"
};
struct SimSignalConfig
{
  bool TachoOn;
  double Rpm;
  int TachoPin;          // digital pin of the tacho (falling edge = mark)
  double PulseDeg;       // pulse length, degrees of rotation
  int TachoAnalog;       // analog channel that repeats the tacho (-1: none)
  double Vref;
  double LcdPixelNs;
  SimChannel Channel[SIM_ANALOG_CHANNELS];
  SimRotor Rotor;
  bool SdFail;           // [SD] Fail=1: no card, SD.begin and card.init fail
  // [DataFile]: A0, A1 and the tacho replay a measurement file (Test.dat of
  // BalA-190: frames of 4 int16 - A0, A1, A4 tacho, us between marks - 32000)
  bool DataOn;
  char DataPath[260];
  double DataScale;      // ADC counts per file unit
  double DataOffset;     // ADC counts added (file values are around zero)
  double DataRpm;        // file without mark times: RPM (0 - Garmoniki.txt, else [Tacho] RPM)
};
// Rotor -> H1 of the sensor channels (no-op when the rotor is off)
void simRotorApply(SimSignalConfig &config);
// Resulting 1st harmonic of a sensor: volts and phase in degrees
void simRotorResponse(const SimSignalConfig &config, int sensor, double &amp, double &phase);
void simSignalDefaults(SimSignalConfig &config);
bool simSignalLoad(const char *path, SimSignalConfig &config);
bool simSignalSave(const char *path, const SimSignalConfig &config);
void simSignalSet(const SimSignalConfig &config);       // window thread
int simSignalAdvance(uint64_t now);                     // sketch thread
// Time of the next tacho edge after the last simSignalAdvance, micros;
// UINT64_MAX when the tacho is off
uint64_t simSignalNextEdge();                           // sketch thread
double simSignalVolts(int channel, uint64_t now);
double simSignalVref();
int simTachoPin();
bool simSdFail();                                       // sketch thread
int simTachoLevel();
#endif
