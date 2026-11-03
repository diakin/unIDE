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
#endif
