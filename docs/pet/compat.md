# Compatibility Notes
## NPA Demo

```
(C:$e0c1) load "d:\pet\npa.prg" 0
Loading d:\pet\npa.prg from 0401 to 7E94 (7A94 bytes)
```

### Uses VRAM mirroring to detect 40 vs. 80 columns
```
.C:0517  A9 21       LDA #$21
.C:0519  8D 00 84    STA $8400
.C:051c  A9 20       LDA #$20
.C:051e  8D 00 80    STA $8000
.C:0521  AD 00 84    LDA $8400
.C:0524  C9 21       CMP #$21
.C:0526  F0 59       BEQ $0581  ; Quit if $8000 does not overwrite $8400
```

### Uses timing to detect 50 vs. 60 Hz
```
.C:055e  AC 44 E8    LDY $E844
.C:0561  AE 45 E8    LDX $E845
.C:0564  AD D7 05    LDA $05D7
.C:0567  C9 B7       CMP #$B7
.C:0569  B0 01       BCS $056C  ; Quit
.C:056b  60          RTS
```
