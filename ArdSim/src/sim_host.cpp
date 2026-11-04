// ArdSim: host mode. The simulator runs without its own window; the
// screen, the Serial output and the keypad go through shared memory that
// another program (the "Emulator" tab of unIDE) created:
//   sketch_sim.exe /host:<name>
// opens the file mapping "Local\ArdSim_<name>". Layout (ArdSimHost.pas
// in unIDE has the same):
//   offset 0     uint32[32] header (indexes below)
//   offset 128   uint16 screen[320][480], RGB565, as UTFT
//   offset 307328 char serial[65536], ring buffer
// The signal settings stay in ardsim.ini next to the exe: it is reloaded
// when it changes, so the host edits the file.
#define WIN32_LEAN_AND_MEAN
#define NOMINMAX
#include <windows.h>
#include "sim_internal.h"
#include <cstring>
#include <string>

namespace
{
const uint32_t HostMagic = 0x4D495341;   // 'ASIM'
const uint32_t HostLayout = 1;
enum HeaderIndex
{
  HdrMagic = 0,         // host
  HdrLayout = 1,        // host
  HdrHostPid = 2,       // host: the simulator ends when this process ends
  HdrSimPid = 3,        // simulator
  HdrScreenVersion = 4, // simulator: +1 after each screen copy
  HdrKeyWrite = 5,      // host: keys put into the queue (counter)
  HdrKeyRead = 6,       // simulator: keys taken (counter)
  HdrSerialWrite = 7,   // simulator: bytes put into the ring (counter)
  HdrState = 8,         // simulator: 1 running, 2 ended
  HdrStopRequest = 9,   // host: 1 - end the simulator
  HdrKeyQueue = 16      // 16 slots: row * 4 + col
};
const int KeyQueueSize = 16;
const size_t HeaderBytes = 128;
const size_t ScreenBytes = SIM_SCREEN_W * SIM_SCREEN_H * 2;
const size_t SerialRingBytes = 65536;
const size_t SharedBytes = HeaderBytes + ScreenBytes + SerialRingBytes;
const int KeyHoldMs = 300;
const DWORD KeyGapMs = 150;   // one key per scan; the next waits a little

volatile uint32_t *Header;
uint16_t *SharedScreen;
char *SerialRing;

FILETIME iniWriteTime(const std::string &path)
{
  FILETIME result = {0, 0};
  WIN32_FILE_ATTRIBUTE_DATA data;
  if (GetFileAttributesExA(path.c_str(), GetFileExInfoStandard, &data))
    result = data.ftLastWriteTime;
  return result;
}

void loadIni(const std::string &path)
{
  SimSignalConfig config;
  if (!simSignalLoad(path.c_str(), config))
  {
    simSignalDefaults(config);
    simSignalSave(path.c_str(), config);
  }
  simSignalSet(config);
}

void putSerial(const std::string &text)
{
  uint32_t written = Header[HdrSerialWrite];
  for (size_t index = 0; index < text.size(); index++)
    SerialRing[(written + index) % SerialRingBytes] = text[index];
  MemoryBarrier();
  Header[HdrSerialWrite] = written + (uint32_t)text.size();
}
}

// Run the simulator for the host; returns the exit code
int simHostRun(const char *name)
{
  std::string mapName = std::string("Local\\ArdSim_") + name;
  HANDLE mapping = OpenFileMappingA(FILE_MAP_ALL_ACCESS, FALSE, mapName.c_str());
  if (!mapping)
    return 3;
  void *view = MapViewOfFile(mapping, FILE_MAP_ALL_ACCESS, 0, 0, SharedBytes);
  if (!view)
    return 3;
  Header = (volatile uint32_t *)view;
  if (Header[HdrMagic] != HostMagic || Header[HdrLayout] != HostLayout)
    return 4;
  SharedScreen = (uint16_t *)((char *)view + HeaderBytes);
  SerialRing = (char *)view + HeaderBytes + ScreenBytes;
  HANDLE hostProcess = OpenProcess(SYNCHRONIZE, FALSE, Header[HdrHostPid]);

  std::string iniPath = simExeDir() + "ardsim.ini";
  loadIni(iniPath);
  FILETIME iniTime = iniWriteTime(iniPath);

  Header[HdrSimPid] = GetCurrentProcessId();
  Header[HdrState] = 1;
  simStartSketch();

  uint32_t copiedVersion = 0xFFFFFFFF;
  DWORD lastKeyTick = 0, lastIniTick = GetTickCount();
  for (;;)
  {
    if (Header[HdrStopRequest] != 0)
      break;
    if (hostProcess && WaitForSingleObject(hostProcess, 0) == WAIT_OBJECT_0)
      break;
    if (SimScreenVersion != copiedVersion)
    {
      copiedVersion = SimScreenVersion;
      memcpy(SharedScreen, SimScreen, ScreenBytes);
      MemoryBarrier();
      Header[HdrScreenVersion] = Header[HdrScreenVersion] + 1;
    }
    std::string serial = simSerialTake();
    if (!serial.empty())
      putSerial(serial);
    DWORD now = GetTickCount();
    uint32_t keyRead = Header[HdrKeyRead];
    if (keyRead != Header[HdrKeyWrite] && now - lastKeyTick >= KeyGapMs)
    {
      uint32_t code = Header[HdrKeyQueue + keyRead % KeyQueueSize];
      Header[HdrKeyRead] = keyRead + 1;
      int row = (int)(code / SIM_KEY_COLS), col = (int)(code % SIM_KEY_COLS);
      if (row < SIM_KEY_ROWS)
        simPostKey(row, col, KeyHoldMs);
      lastKeyTick = now;
    }
    if (now - lastIniTick >= 500)
    {
      lastIniTick = now;
      FILETIME current = iniWriteTime(iniPath);
      if (CompareFileTime(&current, &iniTime) != 0)
      {
        iniTime = current;
        loadIni(iniPath);
      }
    }
    Sleep(20);
  }
  Header[HdrState] = 2;
  simRequestStop();
  // the sketch thread may be inside a long computation: do not wait for it
  ExitProcess(0);
  return 0;
}
