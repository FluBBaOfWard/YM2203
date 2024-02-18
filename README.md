# YM2203 V0.0.5

YM2203 sound chip emulator skeleton for ARM32.

## How to use

First alloc chip struct, call init then set in/out function pointers.
Call YM2203Mixer with chip struct, length and destination.
Produces signed 16bit mono.

## Projects that use this code

* <https://github.com/FluBBaOfWard/BlackTigerDS>
* <https://github.com/FluBBaOfWard/DoubleDribbleDS>
* <https://github.com/FluBBaOfWard/GhostsNGoblinsDS>
* <https://github.com/FluBBaOfWard/IronHorseDS>

## Credits

Fredrik Ahlström

X/Twitter @TheRealFluBBa

<https://www.github.com/FluBBaOfWard>
