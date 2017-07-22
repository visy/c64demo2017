#!/bin/sh
cp bin/hires_Compiled.prg demo.prg
cp bin/hires2_Compiled.prg demo2.prg
cp bin/hires2a_Compiled.prg demo2a.prg
cp bin/hires3_Compiled.prg demo3.prg
./spindle-2.3/spindle/spin -v -a dirart.txt -t BROKEN -e f00 script
cp disk.d64 test.d64
/Applications/Vice/x64.app/Contents/MacOS/x64 test.d64
