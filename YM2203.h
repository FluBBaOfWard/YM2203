/*
*/

#ifndef ARMYM2203_HEADER
#define ARMYM2203_HEADER

#include "AY38910/AY38910.h"

typedef struct {
	AY38910 ay38910chip;

	u8 regIndex;
	u8 padding[3];

} YM2203;

void ym2203Reset(void *irqFunc, YM2203 *chip);
void ym2203Mixer(int len, void *dest, YM2203 *chip);
void ym2203IndexW(u8 value, YM2203 *chip);
void ym2203DataW(u8 value, YM2203 *chip);
void ym2203StatusR(YM2203 *chip);
void ym2203DataR(YM2203 *chip);


#endif
