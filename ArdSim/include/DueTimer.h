// ArdSim: DueTimer (ivanseidel/DueTimer) - periodic callbacks; called by
// the simulator at its safe points (simPoll), like a timer interrupt
#ifndef ARDSIM_DUETIMER_H
#define ARDSIM_DUETIMER_H
#include "Arduino.h"

class DueTimer
{
public:
  explicit DueTimer(unsigned short number) : Number(number) {}
  static DueTimer getAvailable();
  DueTimer &attachInterrupt(void (*isr)());
  DueTimer &detachInterrupt();
  DueTimer &start(long microseconds = -1);
  DueTimer &stop();
  DueTimer &setFrequency(double frequency);
  DueTimer &setPeriod(unsigned long microseconds);
  double getFrequency() const;
  long getPeriod() const;
  unsigned short Number;
};

extern DueTimer Timer;
extern DueTimer Timer0, Timer1, Timer2, Timer3, Timer4, Timer5, Timer6,
  Timer7, Timer8;
#endif
