;@ YM2203 sound chip shell for using AY38910.
#ifdef __arm__

#include "YM2203.i"

	.global ym2203Reset
	.global ym2203Mixer
	.global ym2203Run
	.global ym2203IndexW
	.global ym2203DataW
	.global ym2203StatusR
	.global ym2203DataR

	.syntax unified
	.arm

#ifdef NDS
	.section .itcm						;@ For the NDS
#elif GBA
	.section .iwram, "ax", %progbits	;@ For the GBA
#else
	.section .text
#endif
	.align 2
;@----------------------------------------------------------------------------
ym2203Mixer:				;@ r0=len, r1=dest, ymptr=r2=pointer to struct
	.type   ym2203Mixer STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4-r11,lr}

	ldr r12,=sinusTable
	ldr r3,[r2,#ymCh0Op0Counter]
	ldr r4,[r2,#ymCh1Op0Counter]
	ldr r5,[r2,#ymCh2Op0Counter]
	ldr r6,[r2,#ymCh0Op3Frequency]
	ldr r7,[r2,#ymCh1Op3Frequency]
	ldr r8,[r2,#ymCh2Op3Frequency]
	ldr lr,[r2,#ymCh0Enable]
mixerLoop:
	mov r9,r3,lsr#22
	add r3,r3,r6,lsl#12
	ands r11,lr,#0x00000F
	ldrne r11,[r12,r9,lsl#2]
	mov r9,r4,lsr#22
	add r4,r4,r7,lsl#12
	tst lr,#0x000F00
	ldrne r10,[r12,r9,lsl#2]
	addne r11,r11,r10
	mov r9,r5,lsr#22
	add r5,r5,r8,lsl#12
	tst lr,#0x0F0000
	ldrne r10,[r12,r9,lsl#2]
	addne r11,r11,r10
	mov r11,r11,lsl#4
	strh r11,[r1],#2
	subs r0,r0,#1
	bhi mixerLoop

	str r3,[r2,#ymCh0Op0Counter]
	str r4,[r2,#ymCh1Op0Counter]
	str r5,[r2,#ymCh2Op0Counter]

	ldmfd sp!,{r4-r11,lr}
	bx lr

;@----------------------------------------------------------------------------
ym2203Run:					;@ r0=cycles, ymptr=r1=pointer to struct
	.type   ym2203Run STT_FUNC
;@----------------------------------------------------------------------------
	stmfd sp!,{r4,lr}
	mov r4,#0
	ldrb r12,[r1,#ymRegisters+0x27]
	tst r12,#0x01				;@ Timer A enabled
	beq chkTmrB
	ldr r2,[r1,#ymTimerA]
	subs r2,r2,r0
	str r2,[r1,#ymTimerA]
	orrcc r4,r4,#0x01
chkTmrB:
	tst r12,#0x02				;@ Timer B enabled
	beq endTmrs
	ldr r2,[r1,#ymTimerB]
	subs r2,r2,r0
	str r2,[r1,#ymTimerB]
	orrcc r4,r4,#0x02
endTmrs:
	ands r4,r4,r12,lsr#2		;@ Have any timers expired
	ldrbne r2,[r1,#ymStatus]
	orrne r2,r2,r4
	strbne r2,[r1,#ymStatus]
	movne r0,#1
	movne lr,pc
	ldrne pc,[r1,#ymTimerIrqFunc]

	ldmfd sp!,{r4,lr}
	bx lr

;@----------------------------------------------------------------------------
.pool
	.section .text
	.align 2
;@----------------------------------------------------------------------------
ym2203Reset:				;@ r0=ymptr, r1=IRQ(timerIrqFunc)
	.type   ym2203Reset STT_FUNC
;@----------------------------------------------------------------------------

	mov r3,#0
	mov r2,#ymSize/4			;@ Clear YM2203 state
rLoop:
	subs r2,r2,#1
	strpl r3,[r0,r2,lsl#2]
	bhi rLoop

	cmp r1,#0
	adreq r1,dummyFunc
	str r1,[r0,#ymTimerIrqFunc]
	ldr r1,=detuneAdjustment
	str r1,[r0,#ymCh0DetunePtr]
	str r1,[r0,#ymCh1DetunePtr]
	str r1,[r0,#ymCh2DetunePtr]
	b ay38910Reset
;@----------------------------------------------------------------------------
dummyFunc:
	bx lr

;@----------------------------------------------------------------------------
ym2203StatusR:
	.type   ym2203StatusR STT_FUNC
;@----------------------------------------------------------------------------
	mov r11,r11
	ldrb r2,[r0,#ymStatus]
	bic r1,r2,#0x80
	strb r1,[r0,#ymStatus]
	mov r0,r2
	bx lr
;@----------------------------------------------------------------------------
ym2203DataR:
	.type   ym2203DataR STT_FUNC
;@----------------------------------------------------------------------------
	ldrb r1,[r0,#ymRegIndex]
	tst r1,#0xF0
	beq ay38910DataR
	mov r0,#0xFF
//	add r0,r0,#ymRegisters
//	ldrb r0,[r0,r1]
	bx lr
;@----------------------------------------------------------------------------
ym2203IndexW:				;@ r0=val, r1=ymptr
	.type   ym2203IndexW STT_FUNC
;@----------------------------------------------------------------------------
	strb r0,[r1,#ymRegIndex]
	tst r0,#0xF0
	beq ay38910IndexW
//	ldrb r2,[r0,#ymStatus]
//	orr r2,r2,#0x80
//	strb r2,[r0,#ymStatus]
	bx lr
;@----------------------------------------------------------------------------
ym2203DataW:				;@ r0=val, r1=ymptr
	.type   ym2203DataW STT_FUNC
;@----------------------------------------------------------------------------
	ldrb r2,[r1,#ymRegIndex]
	tst r2,#0xF0
	beq ay38910DataW
//	ldrb r12,[r1,#ymStatus]
//	orr r12,r12,#0x80
//	strb r12,[r1,#ymStatus]
	mov r11,r11
	add r12,r1,#ymRegisters
	strb r0,[r12,r2]
	cmp r2,#0xB3
	ldrmi pc,[pc,r2,lsl#2]
	bx lr
//0x00
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
//0x10
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
//0x20
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long ymTimerControl
	.long ymSetChannelEnable
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
//0x30
	.long ymSetCh0OpDetune
	.long ymSetCh1OpDetune
	.long ymSetCh2OpDetune
	.long NOT_IMPLEMENTED
	.long ymSetCh0OpDetune
	.long ymSetCh1OpDetune
	.long ymSetCh2OpDetune
	.long NOT_IMPLEMENTED
	.long ymSetCh0OpDetune
	.long ymSetCh1OpDetune
	.long ymSetCh2OpDetune
	.long NOT_IMPLEMENTED
	.long ymSetCh0OpDetune
	.long ymSetCh1OpDetune
	.long ymSetCh2OpDetune
	.long NOT_IMPLEMENTED
//0x40
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
//0x50
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
//0x60
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
//0x70
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
//0x80
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
//0x90
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
//0xA0
	.long ymCh0SetFreq
	.long ymCh1SetFreq
	.long ymCh2SetFreq
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
//0xB0
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED
	.long NOT_IMPLEMENTED

	.pool
;@----------------------------------------------------------------------------
ymTimerControl:			;@ 0x27
;@----------------------------------------------------------------------------
	tst r0,#0x01			;@ Load timer A
	ldrbne r12,[r1,#ymRegisters+0x24]
	ldrbne r2,[r1,#ymRegisters+0x25]
	andne r2,r2,#0x03
	orrne r12,r2,r12,lsl#2
	rsbne r12,r12,#0x400
	addne r12,r12,r12,lsl#3	;@ * 72 (* 9)
	movne r12,r12,lsl#3		;@ (* 8)
	strne r12,[r1,#ymTimerA]

	tst r0,#0x02			;@ Load timer B
	ldrbne r12,[r1,#ymRegisters+0x26]
	rsbne r12,r12,#0x100
	addne r12,r12,r12,lsl#3	;@ * 72 (* 9)
	movne r12,r12,lsl#3+4		;@ (* 8) * 16
	strne r12,[r1,#ymTimerB]

	ands r0,#0x30
	ldrbne r12,[r1,#ymStatus]
	bicne r12,r12,r0,lsr#4
	strbne r12,[r1,#ymStatus]

	bx lr

;@----------------------------------------------------------------------------
ymSetChannelEnable:		;@ 0x28
;@----------------------------------------------------------------------------
	add r2,r1,#ymCh0Enable
	mov r12,r0,lsr#4				;@ Operators enabled
	and r0,r0,#0x3				;@ Which channel
	strb r12,[r2,r0]
	bx lr
;@----------------------------------------------------------------------------
ymSetCh0OpDetune:		;@ 0x30, 0x34, 0x38, 0x3C
;@----------------------------------------------------------------------------
	stmfd sp!,{r3}
	ldr r2,[r1,#ymCh0DetunePtr]
	movs r3,r0,lsl#26
	ldrb r2,[r2,r3,lsr#30]
	rsbcs r2,r2,#0
	ldr r3,[r1,#ymCh0Frequency]
	add r2,r3,r2
	ands r0,r0,#0xF
	moveq r2,r2,lsr#1
	mulne r2,r0,r2
	and r12,r12,#0x0C
	add r12,r12,#ymCh0Op0Frequency
	str r2,[r1,r12]

	ldmfd sp!,{r3}
	bx lr
;@----------------------------------------------------------------------------
ymSetCh1OpDetune:		;@ 0x31, 0x35, 0x39, 0x3D
;@----------------------------------------------------------------------------
	stmfd sp!,{r3}
	ldr r2,[r1,#ymCh1DetunePtr]
	movs r3,r0,lsl#26
	ldrb r2,[r2,r3,lsr#30]
	rsbcs r2,r2,#0
	ldr r3,[r1,#ymCh1Frequency]
	add r2,r3,r2
	ands r0,r0,#0xF
	moveq r2,r2,lsr#1
	mulne r2,r0,r2
	and r12,r12,#0x0C
	add r12,r12,#ymCh1Op0Frequency
	str r2,[r1,r12]

	ldmfd sp!,{r3}
	bx lr
;@----------------------------------------------------------------------------
ymSetCh2OpDetune:		;@ 0x32, 0x36, 0x3A, 0x3E
;@----------------------------------------------------------------------------
	stmfd sp!,{r3}
	ldr r2,[r1,#ymCh2DetunePtr]
	movs r3,r0,lsl#26
	ldrb r2,[r2,r3,lsr#30]
	rsbcs r2,r2,#0
	ldr r3,[r1,#ymCh2Frequency]
	add r2,r3,r2
	ands r0,r0,#0xF
	moveq r2,r2,lsr#1
	mulne r2,r0,r2
	and r12,r12,#0x0C
	add r12,r12,#ymCh2Op0Frequency
	str r2,[r1,r12]

	ldmfd sp!,{r3}
	bx lr

;@----------------------------------------------------------------------------
ymCh0SetFreq:			;@ 0xA0
;@----------------------------------------------------------------------------
	ldrb r12,[r1,#ymRegisters+0xA4]
	and r2,r12,#0x7
	orr r0,r0,r2,lsl#8
	mov r12,r12,lsr#3
	and r12,r12,#7
	mov r2,r0,lsl r12
	mov r2,r2,lsr#1
	str r2,[r1,#ymCh0Frequency]
	and r2,r0,#0x780
	cmp r2,#0x400
	orrpl r12,r12,#0x80000000		;@ N4
	orrhi r12,r12,#0x40000000		;@ N3
	cmp r2,#0x380
	orreq r12,r12,#0x40000000		;@ N3
	mov r12,r12,ror#30
	adr r2,detuneAdjustment
	add r2,r2,r12,lsl#2
	str r2,[r1,#ymCh0DetunePtr]

	stmfd sp!,{r3,lr}
	mov r3,#0x30
ym0DeLoop:
	mov r12,r3
	add r2,r1,#ymRegisters
	ldrb r0,[r2,r12]
	bl ymSetCh0OpDetune
	add r3,r3,#4
	cmp r3,#0x40
	bmi ym0DeLoop

	ldmfd sp!,{r3,lr}
	bx lr
;@----------------------------------------------------------------------------
ymCh1SetFreq:			;@ 0xA1
;@----------------------------------------------------------------------------
	ldrb r12,[r1,#ymRegisters+0xA5]
	and r2,r12,#0x7
	orr r0,r0,r2,lsl#8
	mov r12,r12,lsr#3
	and r12,r12,#7
	mov r2,r0,lsl r12
	mov r2,r2,lsr#1
	str r2,[r1,#ymCh1Frequency]
	and r2,r0,#0x780
	cmp r2,#0x400
	orrpl r12,r12,#0x80000000		;@ N4
	orrhi r12,r12,#0x40000000		;@ N3
	cmp r2,#0x380
	orreq r12,r12,#0x40000000		;@ N3
	mov r12,r12,ror#30
	adr r2,detuneAdjustment
	add r2,r2,r12,lsl#2
	str r2,[r1,#ymCh1DetunePtr]

	stmfd sp!,{r3,lr}
	mov r3,#0x31
ym1DeLoop:
	mov r12,r3
	add r2,r1,#ymRegisters
	ldrb r0,[r2,r12]
	bl ymSetCh1OpDetune
	add r3,r3,#4
	cmp r3,#0x40
	bmi ym1DeLoop

	ldmfd sp!,{r3,lr}
	bx lr
;@----------------------------------------------------------------------------
ymCh2SetFreq:			;@ 0xA2
;@----------------------------------------------------------------------------
	ldrb r12,[r1,#ymRegisters+0xA6]
	and r2,r12,#0x7
	orr r0,r0,r2,lsl#8
	mov r12,r12,lsr#3
	and r12,r12,#7
	mov r0,r0,lsl r12
	mov r0,r0,lsr#1
	str r0,[r1,#ymCh2Frequency]
	and r2,r0,#0x780
	cmp r2,#0x400
	orrpl r12,r12,#0x80000000		;@ N4
	orrhi r12,r12,#0x40000000		;@ N3
	cmp r2,#0x380
	orreq r12,r12,#0x40000000		;@ N3
	mov r12,r12,ror#30
	adr r2,detuneAdjustment
	add r2,r2,r12,lsl#2
	str r2,[r1,#ymCh2DetunePtr]

	stmfd sp!,{r3,lr}
	mov r3,#0x32
ym2DeLoop:
	mov r12,r3
	add r2,r1,#ymRegisters
	ldrb r0,[r2,r12]
	bl ymSetCh2OpDetune
	add r3,r3,#4
	cmp r3,#0x40
	bmi ym2DeLoop

	ldmfd sp!,{r3,lr}
	bx lr
;@----------------------------------------------------------------------------

NOT_IMPLEMENTED:
	bx lr

detuneAdjustment:
	.byte 0,  0,  1,  2
	.byte 0,  0,  1,  2
	.byte 0,  0,  1,  2
	.byte 0,  0,  1,  2
	.byte 0,  1,  2,  2
	.byte 0,  1,  2,  3
	.byte 0,  1,  2,  3
	.byte 0,  1,  2,  3
	.byte 0,  1,  2,  4
	.byte 0,  1,  3,  4
	.byte 0,  1,  3,  4
	.byte 0,  1,  3,  5
	.byte 0,  2,  4,  5
	.byte 0,  2,  4,  6
	.byte 0,  2,  4,  6
	.byte 0,  2,  5,  7
	.byte 0,  2,  5,  8
	.byte 0,  3,  6,  8
	.byte 0,  3,  6,  9
	.byte 0,  3,  7, 10
	.byte 0,  4,  8, 11
	.byte 0,  4,  8, 12
	.byte 0,  4,  9, 13
	.byte 0,  5, 10, 14
	.byte 0,  5, 11, 16
	.byte 0,  6, 12, 17
	.byte 0,  6, 13, 19
	.byte 0,  7, 14, 20
	.byte 0,  8, 16, 22
	.byte 0,  8, 16, 22
	.byte 0,  8, 16, 22
	.byte 0,  8, 16, 22

sinusTable:		// 1024 long
	.long 0x00000000, 0x00000003, 0x00000006, 0x00000009, 0x0000000C, 0x0000000F, 0x00000012, 0x00000015
	.long 0x00000019, 0x0000001C, 0x0000001F, 0x00000022, 0x00000025, 0x00000028, 0x0000002B, 0x0000002F
	.long 0x00000032, 0x00000035, 0x00000038, 0x0000003B, 0x0000003E, 0x00000041, 0x00000044, 0x00000048
	.long 0x0000004B, 0x0000004E, 0x00000051, 0x00000054, 0x00000057, 0x0000005A, 0x0000005D, 0x00000060
	.long 0x00000063, 0x00000066, 0x0000006A, 0x0000006D, 0x00000070, 0x00000073, 0x00000076, 0x00000079
	.long 0x0000007C, 0x0000007F, 0x00000082, 0x00000085, 0x00000088, 0x0000008B, 0x0000008E, 0x00000091
	.long 0x00000094, 0x00000097, 0x0000009A, 0x0000009D, 0x000000A0, 0x000000A3, 0x000000A6, 0x000000A9
	.long 0x000000AC, 0x000000AF, 0x000000B2, 0x000000B5, 0x000000B8, 0x000000BB, 0x000000BE, 0x000000C1
	.long 0x000000C3, 0x000000C6, 0x000000C9, 0x000000CC, 0x000000CF, 0x000000D2, 0x000000D5, 0x000000D8
	.long 0x000000DA, 0x000000DD, 0x000000E0, 0x000000E3, 0x000000E6, 0x000000E9, 0x000000EB, 0x000000EE
	.long 0x000000F1, 0x000000F4, 0x000000F6, 0x000000F9, 0x000000FC, 0x000000FF, 0x00000101, 0x00000104
	.long 0x00000107, 0x00000109, 0x0000010C, 0x0000010F, 0x00000111, 0x00000114, 0x00000117, 0x00000119
	.long 0x0000011C, 0x0000011F, 0x00000121, 0x00000124, 0x00000126, 0x00000129, 0x0000012B, 0x0000012E
	.long 0x00000130, 0x00000133, 0x00000136, 0x00000138, 0x0000013A, 0x0000013D, 0x0000013F, 0x00000142
	.long 0x00000144, 0x00000147, 0x00000149, 0x0000014C, 0x0000014E, 0x00000150, 0x00000153, 0x00000155
	.long 0x00000157, 0x0000015A, 0x0000015C, 0x0000015E, 0x00000161, 0x00000163, 0x00000165, 0x00000167
	.long 0x0000016A, 0x0000016C, 0x0000016E, 0x00000170, 0x00000172, 0x00000174, 0x00000177, 0x00000179
	.long 0x0000017B, 0x0000017D, 0x0000017F, 0x00000181, 0x00000183, 0x00000185, 0x00000187, 0x00000189
	.long 0x0000018B, 0x0000018D, 0x0000018F, 0x00000191, 0x00000193, 0x00000195, 0x00000197, 0x00000199
	.long 0x0000019B, 0x0000019D, 0x0000019E, 0x000001A0, 0x000001A2, 0x000001A4, 0x000001A6, 0x000001A7
	.long 0x000001A9, 0x000001AB, 0x000001AD, 0x000001AE, 0x000001B0, 0x000001B2, 0x000001B3, 0x000001B5
	.long 0x000001B7, 0x000001B8, 0x000001BA, 0x000001BB, 0x000001BD, 0x000001BF, 0x000001C0, 0x000001C2
	.long 0x000001C3, 0x000001C5, 0x000001C6, 0x000001C7, 0x000001C9, 0x000001CA, 0x000001CC, 0x000001CD
	.long 0x000001CE, 0x000001D0, 0x000001D1, 0x000001D2, 0x000001D4, 0x000001D5, 0x000001D6, 0x000001D7
	.long 0x000001D9, 0x000001DA, 0x000001DB, 0x000001DC, 0x000001DD, 0x000001DE, 0x000001DF, 0x000001E1
	.long 0x000001E2, 0x000001E3, 0x000001E4, 0x000001E5, 0x000001E6, 0x000001E7, 0x000001E8, 0x000001E9
	.long 0x000001E9, 0x000001EA, 0x000001EB, 0x000001EC, 0x000001ED, 0x000001EE, 0x000001EF, 0x000001EF
	.long 0x000001F0, 0x000001F1, 0x000001F2, 0x000001F2, 0x000001F3, 0x000001F4, 0x000001F4, 0x000001F5
	.long 0x000001F6, 0x000001F6, 0x000001F7, 0x000001F7, 0x000001F8, 0x000001F8, 0x000001F9, 0x000001F9
	.long 0x000001FA, 0x000001FA, 0x000001FB, 0x000001FB, 0x000001FC, 0x000001FC, 0x000001FC, 0x000001FD
	.long 0x000001FD, 0x000001FD, 0x000001FE, 0x000001FE, 0x000001FE, 0x000001FE, 0x000001FF, 0x000001FF
	.long 0x000001FF, 0x000001FF, 0x000001FF, 0x000001FF, 0x000001FF, 0x000001FF, 0x000001FF, 0x000001FF
	.long 0x00000200, 0x000001FF, 0x000001FF, 0x000001FF, 0x000001FF, 0x000001FF, 0x000001FF, 0x000001FF
	.long 0x000001FF, 0x000001FF, 0x000001FF, 0x000001FE, 0x000001FE, 0x000001FE, 0x000001FE, 0x000001FD
	.long 0x000001FD, 0x000001FD, 0x000001FC, 0x000001FC, 0x000001FC, 0x000001FB, 0x000001FB, 0x000001FA
	.long 0x000001FA, 0x000001F9, 0x000001F9, 0x000001F8, 0x000001F8, 0x000001F7, 0x000001F7, 0x000001F6
	.long 0x000001F6, 0x000001F5, 0x000001F4, 0x000001F4, 0x000001F3, 0x000001F2, 0x000001F2, 0x000001F1
	.long 0x000001F0, 0x000001EF, 0x000001EF, 0x000001EE, 0x000001ED, 0x000001EC, 0x000001EB, 0x000001EA
	.long 0x000001E9, 0x000001E9, 0x000001E8, 0x000001E7, 0x000001E6, 0x000001E5, 0x000001E4, 0x000001E3
	.long 0x000001E2, 0x000001E1, 0x000001DF, 0x000001DE, 0x000001DD, 0x000001DC, 0x000001DB, 0x000001DA
	.long 0x000001D9, 0x000001D7, 0x000001D6, 0x000001D5, 0x000001D4, 0x000001D2, 0x000001D1, 0x000001D0
	.long 0x000001CE, 0x000001CD, 0x000001CC, 0x000001CA, 0x000001C9, 0x000001C7, 0x000001C6, 0x000001C5
	.long 0x000001C3, 0x000001C2, 0x000001C0, 0x000001BF, 0x000001BD, 0x000001BB, 0x000001BA, 0x000001B8
	.long 0x000001B7, 0x000001B5, 0x000001B3, 0x000001B2, 0x000001B0, 0x000001AE, 0x000001AD, 0x000001AB
	.long 0x000001A9, 0x000001A7, 0x000001A6, 0x000001A4, 0x000001A2, 0x000001A0, 0x0000019E, 0x0000019D
	.long 0x0000019B, 0x00000199, 0x00000197, 0x00000195, 0x00000193, 0x00000191, 0x0000018F, 0x0000018D
	.long 0x0000018B, 0x00000189, 0x00000187, 0x00000185, 0x00000183, 0x00000181, 0x0000017F, 0x0000017D
	.long 0x0000017B, 0x00000179, 0x00000177, 0x00000174, 0x00000172, 0x00000170, 0x0000016E, 0x0000016C
	.long 0x0000016A, 0x00000167, 0x00000165, 0x00000163, 0x00000161, 0x0000015E, 0x0000015C, 0x0000015A
	.long 0x00000157, 0x00000155, 0x00000153, 0x00000150, 0x0000014E, 0x0000014C, 0x00000149, 0x00000147
	.long 0x00000144, 0x00000142, 0x0000013F, 0x0000013D, 0x0000013A, 0x00000138, 0x00000136, 0x00000133
	.long 0x00000130, 0x0000012E, 0x0000012B, 0x00000129, 0x00000126, 0x00000124, 0x00000121, 0x0000011F
	.long 0x0000011C, 0x00000119, 0x00000117, 0x00000114, 0x00000111, 0x0000010F, 0x0000010C, 0x00000109
	.long 0x00000107, 0x00000104, 0x00000101, 0x000000FF, 0x000000FC, 0x000000F9, 0x000000F6, 0x000000F4
	.long 0x000000F1, 0x000000EE, 0x000000EB, 0x000000E9, 0x000000E6, 0x000000E3, 0x000000E0, 0x000000DD
	.long 0x000000DA, 0x000000D8, 0x000000D5, 0x000000D2, 0x000000CF, 0x000000CC, 0x000000C9, 0x000000C6
	.long 0x000000C3, 0x000000C1, 0x000000BE, 0x000000BB, 0x000000B8, 0x000000B5, 0x000000B2, 0x000000AF
	.long 0x000000AC, 0x000000A9, 0x000000A6, 0x000000A3, 0x000000A0, 0x0000009D, 0x0000009A, 0x00000097
	.long 0x00000094, 0x00000091, 0x0000008E, 0x0000008B, 0x00000088, 0x00000085, 0x00000082, 0x0000007F
	.long 0x0000007C, 0x00000079, 0x00000076, 0x00000073, 0x00000070, 0x0000006D, 0x0000006A, 0x00000066
	.long 0x00000063, 0x00000060, 0x0000005D, 0x0000005A, 0x00000057, 0x00000054, 0x00000051, 0x0000004E
	.long 0x0000004B, 0x00000048, 0x00000044, 0x00000041, 0x0000003E, 0x0000003B, 0x00000038, 0x00000035
	.long 0x00000032, 0x0000002F, 0x0000002B, 0x00000028, 0x00000025, 0x00000022, 0x0000001F, 0x0000001C
	.long 0x00000019, 0x00000015, 0x00000012, 0x0000000F, 0x0000000C, 0x00000009, 0x00000006, 0x00000003
	.long 0x00000000, 0xFFFFFFFD, 0xFFFFFFFA, 0xFFFFFFF7, 0xFFFFFFF4, 0xFFFFFFF1, 0xFFFFFFEE, 0xFFFFFFEB
	.long 0xFFFFFFE7, 0xFFFFFFE4, 0xFFFFFFE1, 0xFFFFFFDE, 0xFFFFFFDB, 0xFFFFFFD8, 0xFFFFFFD5, 0xFFFFFFD1
	.long 0xFFFFFFCE, 0xFFFFFFCB, 0xFFFFFFC8, 0xFFFFFFC5, 0xFFFFFFC2, 0xFFFFFFBF, 0xFFFFFFBC, 0xFFFFFFB8
	.long 0xFFFFFFB5, 0xFFFFFFB2, 0xFFFFFFAF, 0xFFFFFFAC, 0xFFFFFFA9, 0xFFFFFFA6, 0xFFFFFFA3, 0xFFFFFFA0
	.long 0xFFFFFF9D, 0xFFFFFF9A, 0xFFFFFF96, 0xFFFFFF93, 0xFFFFFF90, 0xFFFFFF8D, 0xFFFFFF8A, 0xFFFFFF87
	.long 0xFFFFFF84, 0xFFFFFF81, 0xFFFFFF7E, 0xFFFFFF7B, 0xFFFFFF78, 0xFFFFFF75, 0xFFFFFF72, 0xFFFFFF6F
	.long 0xFFFFFF6C, 0xFFFFFF69, 0xFFFFFF66, 0xFFFFFF63, 0xFFFFFF60, 0xFFFFFF5D, 0xFFFFFF5A, 0xFFFFFF57
	.long 0xFFFFFF54, 0xFFFFFF51, 0xFFFFFF4E, 0xFFFFFF4B, 0xFFFFFF48, 0xFFFFFF45, 0xFFFFFF42, 0xFFFFFF3F
	.long 0xFFFFFF3D, 0xFFFFFF3A, 0xFFFFFF37, 0xFFFFFF34, 0xFFFFFF31, 0xFFFFFF2E, 0xFFFFFF2B, 0xFFFFFF28
	.long 0xFFFFFF26, 0xFFFFFF23, 0xFFFFFF20, 0xFFFFFF1D, 0xFFFFFF1A, 0xFFFFFF17, 0xFFFFFF15, 0xFFFFFF12
	.long 0xFFFFFF0F, 0xFFFFFF0C, 0xFFFFFF0A, 0xFFFFFF07, 0xFFFFFF04, 0xFFFFFF01, 0xFFFFFEFF, 0xFFFFFEFC
	.long 0xFFFFFEF9, 0xFFFFFEF7, 0xFFFFFEF4, 0xFFFFFEF1, 0xFFFFFEEF, 0xFFFFFEEC, 0xFFFFFEE9, 0xFFFFFEE7
	.long 0xFFFFFEE4, 0xFFFFFEE1, 0xFFFFFEDF, 0xFFFFFEDC, 0xFFFFFEDA, 0xFFFFFED7, 0xFFFFFED5, 0xFFFFFED2
	.long 0xFFFFFED0, 0xFFFFFECD, 0xFFFFFECA, 0xFFFFFEC8, 0xFFFFFEC6, 0xFFFFFEC3, 0xFFFFFEC1, 0xFFFFFEBE
	.long 0xFFFFFEBC, 0xFFFFFEB9, 0xFFFFFEB7, 0xFFFFFEB4, 0xFFFFFEB2, 0xFFFFFEB0, 0xFFFFFEAD, 0xFFFFFEAB
	.long 0xFFFFFEA9, 0xFFFFFEA6, 0xFFFFFEA4, 0xFFFFFEA2, 0xFFFFFE9F, 0xFFFFFE9D, 0xFFFFFE9B, 0xFFFFFE99
	.long 0xFFFFFE96, 0xFFFFFE94, 0xFFFFFE92, 0xFFFFFE90, 0xFFFFFE8E, 0xFFFFFE8C, 0xFFFFFE89, 0xFFFFFE87
	.long 0xFFFFFE85, 0xFFFFFE83, 0xFFFFFE81, 0xFFFFFE7F, 0xFFFFFE7D, 0xFFFFFE7B, 0xFFFFFE79, 0xFFFFFE77
	.long 0xFFFFFE75, 0xFFFFFE73, 0xFFFFFE71, 0xFFFFFE6F, 0xFFFFFE6D, 0xFFFFFE6B, 0xFFFFFE69, 0xFFFFFE67
	.long 0xFFFFFE65, 0xFFFFFE63, 0xFFFFFE62, 0xFFFFFE60, 0xFFFFFE5E, 0xFFFFFE5C, 0xFFFFFE5A, 0xFFFFFE59
	.long 0xFFFFFE57, 0xFFFFFE55, 0xFFFFFE53, 0xFFFFFE52, 0xFFFFFE50, 0xFFFFFE4E, 0xFFFFFE4D, 0xFFFFFE4B
	.long 0xFFFFFE49, 0xFFFFFE48, 0xFFFFFE46, 0xFFFFFE45, 0xFFFFFE43, 0xFFFFFE41, 0xFFFFFE40, 0xFFFFFE3E
	.long 0xFFFFFE3D, 0xFFFFFE3B, 0xFFFFFE3A, 0xFFFFFE39, 0xFFFFFE37, 0xFFFFFE36, 0xFFFFFE34, 0xFFFFFE33
	.long 0xFFFFFE32, 0xFFFFFE30, 0xFFFFFE2F, 0xFFFFFE2E, 0xFFFFFE2C, 0xFFFFFE2B, 0xFFFFFE2A, 0xFFFFFE29
	.long 0xFFFFFE27, 0xFFFFFE26, 0xFFFFFE25, 0xFFFFFE24, 0xFFFFFE23, 0xFFFFFE22, 0xFFFFFE21, 0xFFFFFE1F
	.long 0xFFFFFE1E, 0xFFFFFE1D, 0xFFFFFE1C, 0xFFFFFE1B, 0xFFFFFE1A, 0xFFFFFE19, 0xFFFFFE18, 0xFFFFFE17
	.long 0xFFFFFE17, 0xFFFFFE16, 0xFFFFFE15, 0xFFFFFE14, 0xFFFFFE13, 0xFFFFFE12, 0xFFFFFE11, 0xFFFFFE11
	.long 0xFFFFFE10, 0xFFFFFE0F, 0xFFFFFE0E, 0xFFFFFE0E, 0xFFFFFE0D, 0xFFFFFE0C, 0xFFFFFE0C, 0xFFFFFE0B
	.long 0xFFFFFE0A, 0xFFFFFE0A, 0xFFFFFE09, 0xFFFFFE09, 0xFFFFFE08, 0xFFFFFE08, 0xFFFFFE07, 0xFFFFFE07
	.long 0xFFFFFE06, 0xFFFFFE06, 0xFFFFFE05, 0xFFFFFE05, 0xFFFFFE04, 0xFFFFFE04, 0xFFFFFE04, 0xFFFFFE03
	.long 0xFFFFFE03, 0xFFFFFE03, 0xFFFFFE02, 0xFFFFFE02, 0xFFFFFE02, 0xFFFFFE02, 0xFFFFFE01, 0xFFFFFE01
	.long 0xFFFFFE01, 0xFFFFFE01, 0xFFFFFE01, 0xFFFFFE01, 0xFFFFFE01, 0xFFFFFE01, 0xFFFFFE01, 0xFFFFFE01
	.long 0xFFFFFE00, 0xFFFFFE01, 0xFFFFFE01, 0xFFFFFE01, 0xFFFFFE01, 0xFFFFFE01, 0xFFFFFE01, 0xFFFFFE01
	.long 0xFFFFFE01, 0xFFFFFE01, 0xFFFFFE01, 0xFFFFFE02, 0xFFFFFE02, 0xFFFFFE02, 0xFFFFFE02, 0xFFFFFE03
	.long 0xFFFFFE03, 0xFFFFFE03, 0xFFFFFE04, 0xFFFFFE04, 0xFFFFFE04, 0xFFFFFE05, 0xFFFFFE05, 0xFFFFFE06
	.long 0xFFFFFE06, 0xFFFFFE07, 0xFFFFFE07, 0xFFFFFE08, 0xFFFFFE08, 0xFFFFFE09, 0xFFFFFE09, 0xFFFFFE0A
	.long 0xFFFFFE0A, 0xFFFFFE0B, 0xFFFFFE0C, 0xFFFFFE0C, 0xFFFFFE0D, 0xFFFFFE0E, 0xFFFFFE0E, 0xFFFFFE0F
	.long 0xFFFFFE10, 0xFFFFFE11, 0xFFFFFE11, 0xFFFFFE12, 0xFFFFFE13, 0xFFFFFE14, 0xFFFFFE15, 0xFFFFFE16
	.long 0xFFFFFE17, 0xFFFFFE17, 0xFFFFFE18, 0xFFFFFE19, 0xFFFFFE1A, 0xFFFFFE1B, 0xFFFFFE1C, 0xFFFFFE1D
	.long 0xFFFFFE1E, 0xFFFFFE1F, 0xFFFFFE21, 0xFFFFFE22, 0xFFFFFE23, 0xFFFFFE24, 0xFFFFFE25, 0xFFFFFE26
	.long 0xFFFFFE27, 0xFFFFFE29, 0xFFFFFE2A, 0xFFFFFE2B, 0xFFFFFE2C, 0xFFFFFE2E, 0xFFFFFE2F, 0xFFFFFE30
	.long 0xFFFFFE32, 0xFFFFFE33, 0xFFFFFE34, 0xFFFFFE36, 0xFFFFFE37, 0xFFFFFE39, 0xFFFFFE3A, 0xFFFFFE3B
	.long 0xFFFFFE3D, 0xFFFFFE3E, 0xFFFFFE40, 0xFFFFFE41, 0xFFFFFE43, 0xFFFFFE45, 0xFFFFFE46, 0xFFFFFE48
	.long 0xFFFFFE49, 0xFFFFFE4B, 0xFFFFFE4D, 0xFFFFFE4E, 0xFFFFFE50, 0xFFFFFE52, 0xFFFFFE53, 0xFFFFFE55
	.long 0xFFFFFE57, 0xFFFFFE59, 0xFFFFFE5A, 0xFFFFFE5C, 0xFFFFFE5E, 0xFFFFFE60, 0xFFFFFE62, 0xFFFFFE63
	.long 0xFFFFFE65, 0xFFFFFE67, 0xFFFFFE69, 0xFFFFFE6B, 0xFFFFFE6D, 0xFFFFFE6F, 0xFFFFFE71, 0xFFFFFE73
	.long 0xFFFFFE75, 0xFFFFFE77, 0xFFFFFE79, 0xFFFFFE7B, 0xFFFFFE7D, 0xFFFFFE7F, 0xFFFFFE81, 0xFFFFFE83
	.long 0xFFFFFE85, 0xFFFFFE87, 0xFFFFFE89, 0xFFFFFE8C, 0xFFFFFE8E, 0xFFFFFE90, 0xFFFFFE92, 0xFFFFFE94
	.long 0xFFFFFE96, 0xFFFFFE99, 0xFFFFFE9B, 0xFFFFFE9D, 0xFFFFFE9F, 0xFFFFFEA2, 0xFFFFFEA4, 0xFFFFFEA6
	.long 0xFFFFFEA9, 0xFFFFFEAB, 0xFFFFFEAD, 0xFFFFFEB0, 0xFFFFFEB2, 0xFFFFFEB4, 0xFFFFFEB7, 0xFFFFFEB9
	.long 0xFFFFFEBC, 0xFFFFFEBE, 0xFFFFFEC1, 0xFFFFFEC3, 0xFFFFFEC6, 0xFFFFFEC8, 0xFFFFFECA, 0xFFFFFECD
	.long 0xFFFFFED0, 0xFFFFFED2, 0xFFFFFED5, 0xFFFFFED7, 0xFFFFFEDA, 0xFFFFFEDC, 0xFFFFFEDF, 0xFFFFFEE1
	.long 0xFFFFFEE4, 0xFFFFFEE7, 0xFFFFFEE9, 0xFFFFFEEC, 0xFFFFFEEF, 0xFFFFFEF1, 0xFFFFFEF4, 0xFFFFFEF7
	.long 0xFFFFFEF9, 0xFFFFFEFC, 0xFFFFFEFF, 0xFFFFFF01, 0xFFFFFF04, 0xFFFFFF07, 0xFFFFFF0A, 0xFFFFFF0C
	.long 0xFFFFFF0F, 0xFFFFFF12, 0xFFFFFF15, 0xFFFFFF17, 0xFFFFFF1A, 0xFFFFFF1D, 0xFFFFFF20, 0xFFFFFF23
	.long 0xFFFFFF26, 0xFFFFFF28, 0xFFFFFF2B, 0xFFFFFF2E, 0xFFFFFF31, 0xFFFFFF34, 0xFFFFFF37, 0xFFFFFF3A
	.long 0xFFFFFF3D, 0xFFFFFF3F, 0xFFFFFF42, 0xFFFFFF45, 0xFFFFFF48, 0xFFFFFF4B, 0xFFFFFF4E, 0xFFFFFF51
	.long 0xFFFFFF54, 0xFFFFFF57, 0xFFFFFF5A, 0xFFFFFF5D, 0xFFFFFF60, 0xFFFFFF63, 0xFFFFFF66, 0xFFFFFF69
	.long 0xFFFFFF6C, 0xFFFFFF6F, 0xFFFFFF72, 0xFFFFFF75, 0xFFFFFF78, 0xFFFFFF7B, 0xFFFFFF7E, 0xFFFFFF81
	.long 0xFFFFFF84, 0xFFFFFF87, 0xFFFFFF8A, 0xFFFFFF8D, 0xFFFFFF90, 0xFFFFFF93, 0xFFFFFF96, 0xFFFFFF9A
	.long 0xFFFFFF9D, 0xFFFFFFA0, 0xFFFFFFA3, 0xFFFFFFA6, 0xFFFFFFA9, 0xFFFFFFAC, 0xFFFFFFAF, 0xFFFFFFB2
	.long 0xFFFFFFB5, 0xFFFFFFB8, 0xFFFFFFBC, 0xFFFFFFBF, 0xFFFFFFC2, 0xFFFFFFC5, 0xFFFFFFC8, 0xFFFFFFCB
	.long 0xFFFFFFCE, 0xFFFFFFD1, 0xFFFFFFD5, 0xFFFFFFD8, 0xFFFFFFDB, 0xFFFFFFDE, 0xFFFFFFE1, 0xFFFFFFE4
	.long 0xFFFFFFE7, 0xFFFFFFEB, 0xFFFFFFEE, 0xFFFFFFF1, 0xFFFFFFF4, 0xFFFFFFF7, 0xFFFFFFFA, 0xFFFFFFFD

#endif
