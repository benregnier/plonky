# plonky

> plonk (/plɒŋk/) - to play a musical instrument, usually not very well but often loudly
> - Cambride Dictionary


https://vimeo.com/514823601


plonky is a keyboard and sequencer. i made it to be able to play [mx.samples](https://llllllll.co/t/mx-samples/41400) directly from the grid. the grid layout (and name) is inspired by the [plinky synth](https://www.plinkysynth.com/), i.e. it is a 8x8 layout with notes spaced out between columns by a specified interval. by default each column is a fifth apart and it is a C-major scale (all customizable in menu).



### Requirements

- norns
- grid

### Documentation

use the grid to play an engine. by default the engine is "PolyPerc", but if you install [mx.samples](https://llllllll.co/t/mx-samples/41400) you can also play that. engine options are found in the parameters menu `PLONKY`.

each 8x8 section of the grid is a voice (1 voice for 64-grid, 2 voices for 128-grid). you can play notes in that voice by pressing pads. the notes correspond to a C-major scale, where each column is a fifth apart (all adjustable in menu).

**arps:** you can do arps by turning E2 or E3 to the right. in "arp" mode you can press multiple keys and have them play. in "arp+latch" mode the last keys you pressed will play. change the speed using the `PLONKY > division` parameter in the menu.

**patterns:** you can record patterns by pressing K1+K2 (voice 1) or K1+K3 (voice 2). press a note (or multiple) and it will become a new step in the pattern. you can hold out a step by holding the notes and pressing K2 (if voice 1, else K3). you can add a rest by releasing notes and pressing K2 (if voice 1, else K3). when done recording press K1+K3 (voice 2: K1+K3). to play a pattern press K2 (voice 1, else K3).


### Install

from maiden:

```
;install https://github.com/schollz/plonky
```

