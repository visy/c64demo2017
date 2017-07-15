#!/bin/sh
exomizer sfx basic bin/hires_Compiled.prg
cp a.out demo.prg
./cc1541 -w demo.prg -w d_fox.bin -w d_broke.bin -w d_dither1.bin -w d_dither2.bin -w d_dither3.bin -w d_bune.bin -w bol0.bin -w bol1.bin -w bol2.bin -w bol3.bin -w bol4.bin -w bol5.bin -w bol6.bin -w bol7.bin -w bol8.bin -w bol9.bin -w bol10.bin -w bol11.bin -w bol12.bin -w bol13.bin -w bol14.bin -w bol15.bin test.d64 && /Applications/Vice/x64.app/Contents/MacOS/x64 test.d64
#           0           1            2              3                4                5                6             7-23