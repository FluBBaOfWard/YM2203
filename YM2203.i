;@ ASM header for the YM2203 emulator
;@

#include "AY38910/AY38910.i"

#if !__ASSEMBLER__
	#error This header file is only for use in assembly files!
#endif

							;@ YM2203.s
	.struct 0
	ayChip:			.space aySize

	ymRegIndex:		.byte 0
	ymStatus:		.byte 0
	ymPadding0:		.space 2
	ymRegisters:	.space 0x10
					.space 0xF0
	ymCh0Enable:	.byte 0			;@ Four lowest bits per operator
	ymCh1Enable:	.byte 0
	ymCh2Enable:	.byte 0
	ymPadding1:		.space 1
	ymCh0Frequency:	.long 0
	ymCh0DetunePtr:	.long 0
	ymCh1Frequency:	.long 0
	ymCh1DetunePtr:	.long 0
	ymCh2Frequency:	.long 0
	ymCh2DetunePtr:	.long 0
	ymCh0Op0Frequency:	.long 0
	ymCh0Op1Frequency:	.long 0
	ymCh0Op2Frequency:	.long 0
	ymCh0Op3Frequency:	.long 0
	ymCh1Op0Frequency:	.long 0
	ymCh1Op1Frequency:	.long 0
	ymCh1Op2Frequency:	.long 0
	ymCh1Op3Frequency:	.long 0
	ymCh2Op0Frequency:	.long 0
	ymCh2Op1Frequency:	.long 0
	ymCh2Op2Frequency:	.long 0
	ymCh2Op3Frequency:	.long 0
	ymCh0Op0Counter:	.long 0
	ymCh0Op1Counter:	.long 0
	ymCh0Op2Counter:	.long 0
	ymCh0Op3Counter:	.long 0
	ymCh1Op0Counter:	.long 0
	ymCh1Op1Counter:	.long 0
	ymCh1Op2Counter:	.long 0
	ymCh1Op3Counter:	.long 0
	ymCh2Op0Counter:	.long 0
	ymCh2Op1Counter:	.long 0
	ymCh2Op2Counter:	.long 0
	ymCh2Op3Counter:	.long 0
	ymTimerA:		.long 0
	ymTimerB:		.long 0
	ymTimerIrqFunc:	.long 0
	ymSize:

;@----------------------------------------------------------------------------

