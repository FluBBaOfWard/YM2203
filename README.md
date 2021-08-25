# YM2203
YM2203 sound chip emulator skeleton for ARM32.

First alloc chip struct, call init then set in/out function pointers.
Call YM2203Mixer with chip struct, length and destination.
Produces 16bit mono.
