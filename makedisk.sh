#!/bin/sh
./cc1541 -w ./bin/hires_Compiled.prg -w d_fox.bin -w d_broke.bin -w d_dither1_a.bin -w d_dither2_a.bin -w d_dither3_a.bin test.d64 && /Applications/Vice/x64.app/Contents/MacOS/x64 test.d64
