// ArdSim: program memory macros - on the PC everything is in RAM
#ifndef ARDSIM_PGMSPACE_H
#define ARDSIM_PGMSPACE_H
#include <stdint.h>
#include <string.h>
#define PROGMEM
#define PGM_P const char *
#define PSTR(text) (text)
#define pgm_read_byte(addr) (*(const uint8_t *)(addr))
#define pgm_read_word(addr) (*(const uint16_t *)(addr))
#define pgm_read_dword(addr) (*(const uint32_t *)(addr))
#define pgm_read_float(addr) (*(const float *)(addr))
#define pgm_read_ptr(addr) (*(void *const *)(addr))
#define memcpy_P memcpy
#define strcpy_P strcpy
#define strlen_P strlen
typedef uint8_t prog_uchar;
#endif
