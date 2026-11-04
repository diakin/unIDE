// ArdSim: SD library for the PC. The card is the folder sim_sd next to
// the simulator exe. Names follow FAT 8.3: SD.open() of a longer name
// fails and openNextFile() skips such files, as on the device.
#ifndef ARDSIM_SD_H
#define ARDSIM_SD_H
#include "Arduino.h"
#include <vector>
#include <string>

#define FILE_READ 0x01
#define FILE_WRITE 0x13
#define O_READ 0x01
#define O_RDONLY 0x01
#define O_WRITE 0x02
#define O_CREAT 0x10
#define O_APPEND 0x04
#define LS_DATE 1
#define LS_SIZE 2
#define LS_R 4
#define SD_CARD_TYPE_SD1 1
#define SD_CARD_TYPE_SD2 2
#define SD_CARD_TYPE_SDHC 3
#define SPI_HALF_SPEED 1
#define SPI_FULL_SPEED 0

struct SimFileState;

class File : public Print
{
public:
  File();
  File(const File &other);
  File &operator=(const File &other);
  ~File();
  size_t write(uint8_t value) override;
  size_t write(const uint8_t *buffer, size_t size) override;
  using Print::write;
  int read();
  int read(void *buffer, uint16_t size);
  int peek();
  int available();
  void flush();
  bool seek(uint32_t position);
  uint32_t position();
  uint32_t size();
  void close();
  operator bool() const;
  char *name();
  bool isDirectory();
  File openNextFile(uint8_t mode = O_RDONLY);
  void rewindDirectory();
  SimFileState *State;
};

class Sd2Card
{
public:
  bool init(uint8_t speed = SPI_HALF_SPEED, uint8_t csPin = 4) { (void)speed; (void)csPin; Inited = true; return true; }
  uint8_t type() const { return Inited ? SD_CARD_TYPE_SDHC : 0; }
  bool Inited = false;
};

class SdVolume
{
public:
  bool init(Sd2Card &card) { (void)card; return true; }
  uint32_t clusterCount() const { return 0; }
  uint8_t blocksPerCluster() const { return 0; }
  uint8_t fatType() const { return 0; }
};

class SDClass
{
public:
  bool begin(uint8_t csPin = 4);
  File open(const char *path, uint8_t mode = FILE_READ);
  File open(const String &path, uint8_t mode = FILE_READ) { return open(path.c_str(), mode); }
  bool exists(const char *path);
  bool exists(const String &path) { return exists(path.c_str()); }
  bool mkdir(const char *path);
  bool mkdir(const String &path) { return mkdir(path.c_str()); }
  bool remove(const char *path);
  bool remove(const String &path) { return remove(path.c_str()); }
  bool rmdir(const char *path);
  bool rmdir(const String &path) { return rmdir(path.c_str()); }
};
extern SDClass SD;
#endif
