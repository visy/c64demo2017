#!/bin/sh
./cc1541 -w ./bin/hires_Compiled.prg -w d_fox.bin -w d_broke.bin test.d64 && /Applications/Vice/x64.app/Contents/MacOS/x64 test.d64
