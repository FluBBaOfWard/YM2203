/*
*/

#ifndef ARMYM2203_HEADER
#define ARMYM2203_HEADER

#include "AY38910/AY38910.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
	AY38910 ay38910chip;

	u8 regIndex;
	u8 padding[3];

} YM2203;

void ym2203Reset(YM2203 *chip, void *irqFunc);
void ym2203Mixer(int len, void *dest, YM2203 *chip);
void ym2203Run(u8 cycles, YM2203 *chip);
void ym2203IndexW(u8 value, YM2203 *chip);
void ym2203DataW(u8 value, YM2203 *chip);
u8 ym2203StatusR(YM2203 *chip);
u8 ym2203DataR(YM2203 *chip);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // ARMYM2203_HEADER
