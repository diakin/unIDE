// ArdSim: SPI is not simulated (SD and the display are simulated directly)
#ifndef ARDSIM_SPI_H
#define ARDSIM_SPI_H
#include "Arduino.h"
class SPIClass
{
public:
  void begin() {}
  void end() {}
  uint8_t transfer(uint8_t value) { return value; }
};
extern SPIClass SPI;
#endif
