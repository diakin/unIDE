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
double simSignalVolts(int channel, uint64_t now);
double simSignalVref();
int simTachoPin();
int simTachoLevel();
#endif
