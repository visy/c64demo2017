
.var part_lo = $c1
.var part_hi = $c2

.macro StabilizeRaster() {
    //
    // Register a new irq handler for the next line.
    //
    lda #<stabilizedirq
    sta $fffe
    lda #>stabilizedirq
    sta $ffff
    inc $d012

    //
    // ACK the current IRQ
    //
    lda #$ff
    sta $d019

    // Save the old stack pointer so we can just restore the stack as it was
    // before the stabilizing got in the way.
    tsx

    // Enable interrupts and call nop's until the end of the current line
    // should be reached
    cli

    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    // Add one more nop if NTSC

    // Here's or second irq handler
stabilizedirq:

    // Reset the SP so it looks like the extra irq stuff never happened
    txs

    //
    // Wait for line to finish.
    //

    // PAL-63  // NTSC-64    // NTSC-65
    //---------//------------//-----------
    ldx #$08   // ldx #$08   // ldx #$09
    dex        // dex        // dex
    bne *-1    // bne *-1    // bne *-1
    bit $00    // nop
               // nop

    //
    // Check at exactly what point we go to the next line
    //
    lda $d012
    cmp $d012
    beq *+2 // If we haven't changed line yet, wait an extra cycle.

    // Here our real logic can start running.
}

.macro FillBitmap(addr, value) {
    ldx #$00
    lda #value
!loop:
    sta addr,x
    sta (addr + $100),x
    sta (addr + $200),x
    sta (addr + $300),x
    sta (addr + $400),x
    sta (addr + $500),x
    sta (addr + $600),x
    sta (addr + $700),x
    sta (addr + $800),x
    sta (addr + $900),x
    sta (addr + $a00),x
    sta (addr + $b00),x
    sta (addr + $c00),x
    sta (addr + $d00),x
    sta (addr + $e00),x
    sta (addr + $f00),x
    sta (addr + $1000),x
    sta (addr + $1100),x
    sta (addr + $1200),x
    sta (addr + $1300),x
    sta (addr + $1400),x
    sta (addr + $1500),x
    sta (addr + $1600),x
    sta (addr + $1700),x
    sta (addr + $1800),x
    sta (addr + $1900),x
    sta (addr + $1a00),x
    sta (addr + $1b00),x
    sta (addr + $1c00),x
    sta (addr + $1d00),x
    sta (addr + $1e00),x
    sta (addr + $1f00),x
    dex
    bne !loop-
}

    .macro PNGtoHIRES(PNGpicture,BMPData,ColData) {

        .var Graphics = LoadPicture(PNGpicture)

        // Graphics RGB Colors. Must be adapted to the graphics

        .const C64Black   = 000 * 65536 + 000 * 256 + 000   
        .const C64White   = 255 * 65536 + 255 * 256 + 255
        .const C64Red     = 104 * 65536 + 055 * 256 + 043
        .const C64Cyan    = 112 * 65536 + 164 * 256 + 178
        .const C64Purple  = 111 * 65536 + 061 * 256 + 134
        .const C64Green   = 088 * 65536 + 141 * 256 + 067
        .const C64Blue    = 053 * 65536 + 040 * 256 + 121 
        .const C64Yellow  = 184 * 65536 + 199 * 256 + 111
        .const C64L_brown = 111 * 65536 + 079 * 256 + 037
        .const C64D_brown = 067 * 65536 + 057 * 256 + 000
        .const C64L_red   = 154 * 65536 + 103 * 256 + 089
        .const C64D_grey  = 068 * 65536 + 068 * 256 + 068
        .const C64Grey    = 108 * 65536 + 108 * 256 + 108
        .const C64L_green = 154 * 65536 + 210 * 256 + 132
        .const C64L_blue  = 108 * 65536 + 094 * 256 + 181
        .const C64L_grey  = 149 * 65536 + 149 * 256 + 149

        // Add the colors neatly into a Hashtable for easy lookup reference
        .var ColorTable = Hashtable()
        .eval ColorTable.put(C64Black,0)
        .eval ColorTable.put(C64White,1)
        .eval ColorTable.put(C64Red,2)
        .eval ColorTable.put(C64Cyan,3)
        .eval ColorTable.put(C64Purple,4)
        .eval ColorTable.put(C64Green,5)
        .eval ColorTable.put(C64Blue,6)
        .eval ColorTable.put(C64Yellow,7)
        .eval ColorTable.put(C64L_brown,8)
        .eval ColorTable.put(C64D_brown,9)
        .eval ColorTable.put(C64L_red,10)
        .eval ColorTable.put(C64D_grey,11)
        .eval ColorTable.put(C64Grey,12)
        .eval ColorTable.put(C64L_green,13)
        .eval ColorTable.put(C64L_blue,14)
        .eval ColorTable.put(C64L_grey,15)


        .pc = BMPData "Hires Bitmap"

        .var ScreenMem = List()
        .for (var Line = 0 ; Line < 200 ; Line = Line + 8) {
            .for (var Block = 0 ; Block < 320 ; Block=Block+8) {
                .var Coll1 = Graphics.getPixel(Block,Line)
                .var Coll2 = 0
                .for (var j = 0 ; j < 8 ; j++ ) {
                    .var ByteValue = 0
                    .for (var i = 0 ; i < 8 ; i++ ) {
                        .if (Graphics.getPixel(Block,Line) != Graphics.getPixel(Block+i,Line+j)) .eval ByteValue = ByteValue + pow(2,7-i)
                        .if (Graphics.getPixel(Block,Line) != Graphics.getPixel(Block+i,Line+j)) .eval Coll2 = Graphics.getPixel(Block+i,Line+j)
                    }
                .byte ByteValue
                }
            .var BlockColor = [ColorTable.get(Coll2)]*16+ColorTable.get(Coll1)
            .eval ScreenMem.add(BlockColor)
            }
        }
        .pc = ColData "Hires Color Data"
    ScreenMemColors:
        .for (var i = 0 ; i < 1000 ; i++ ) {
            .byte ScreenMem.get(i)
        }
    }

.macro SetScreenMemory(address) {

    .var bits = (address / $0400) << 4

    lda $d018
    and #%00001111
    ora #bits
    sta $d018
}


.macro FillScreenMemory(address, value) {
    //
    // Screen memory is 40 * 25 = 1000 bytes ($3E8 bytes)
    //
    ldx #$00
    lda #value
!loop:
    sta address,x
    sta (address + $100),x
    sta (address + $200),x
    dex
    bne !loop-

    ldx #$e8
!loop:
    sta (address + $2ff),x     // Start one byte below the area we're clearing
                               // That way we can bail directly when zero without an additional comparison
    dex
    bne !loop-
}

    .macro copymem_add(src,src2,dst,size) {
        lda #<src // set our source memory address to copy from, $6000
        clc
        adc $E0
        sta $FB
        lda #>src 
        sta $FC
        lda #<src2 // set our source memory address to copy from, $6000
        sta $F8
        lda #>src2
        sta $F9

        lda #<dst // set our destination memory to copy to, $5000
        sta $FD 
        lda #>dst
        sta $FE

        ldx #size // size of copy
        ldy #$00

    copyloop:
        lda ($F8),y  // indirect index source memory address, starting at $00
        clc
        adc $E3
        sbc ($FB),y  // indirect index source memory address, starting at $00
        cmp #32
        bcs toobig
        sta ($FD),y  // indirect index dest memory address, starting at $00
toobig:
        iny
        bne copyloop // loop until our dest goes over 255
        inc $F9 // increment high order source memory address
        inc $FC // increment high order source memory address
        inc $FE // increment high order dest memory address
        dex
        bne copyloop // if we're not there yet, loop

    }

    .macro copymem(src,dst,size) {
        lda #<src // set our source memory address to copy from, $6000
        sta $FB
        lda #>src 
        sta $FC
        lda #<dst // set our destination memory to copy to, $5000
        sta $FD 
        lda #>dst
        sta $FE

        ldx #size // size of copy
        ldy #$00

    copyloop:

        lda ($FB),y  // indirect index source memory address, starting at $00
        sta ($FD),y  // indirect index dest memory address, starting at $00
        iny
        bne copyloop // loop until our dest goes over 255
        inc $FC // increment high order source memory address
        inc $FE // increment high order dest memory address
        dex
        bne copyloop // if we're not there yet, loop

    }

    .macro copymem_inc(src,dst,size) {
        lda #<src // set our source memory address to copy from, $6000
        sta $FB
        lda #>src 
        sta $FC
        lda #<dst // set our destination memory to copy to, $5000
        sta $FD 
        lda #>dst
        sta $FE

        ldx #size // size of copy
        ldy #$00

    copyloop:

        lda ($FB),y  // indirect index source memory address, starting at $00
        clc
        sbc $F2
        cmp #38
        bcs no_over
        cmp #0
        bcc no_over
        //eor ($FD),y  // indirect index dest memory address, starting at $00
        sta ($FD),y  // indirect index dest memory address, starting at $00
no_over:
        iny
        bne copyloop // loop until our dest goes over 255
        inc $FC // increment high order source memory address
        inc $FE // increment high order dest memory address
        dex
        bne copyloop // if we're not there yet, loop

    }

    .macro copymem_eor_short(src,dst,size) {
        lda #<src // set our source memory address to copy from, $6000
        sta $FB
        lda #>src 
        sta $FC
        lda #<dst // set our destination memory to copy to, $5000
        sta $FD 
        lda #>dst
        sta $FE

        ldx #size // size of copy
        ldy #$00

    copyloop:

        lda ($FB),y  // indirect index source memory address, starting at $00
        eor ($FD),y  // indirect index dest memory address, starting at $00
        sta ($FD),y  // indirect index dest memory address, starting at $00
        iny
        bne copyloop // loop until our dest goes over 255

        inc $FC // increment high order source memory address
        inc $FE // increment high order dest memory address
        dex
        bne copyloop // if we're not there yet, loop

        ldy #$00

    copyloop2:

        lda ($FB),y  // indirect index source memory address, starting at $00
        eor ($FD),y  // indirect index dest memory address, starting at $00
        sta ($FD),y  // indirect index dest memory address, starting at $00
        iny
        cpy #190
        bne copyloop2 // loop until our dest goes over 255

    }

   .macro set_line(dst,val) {
        lda #<dst // set our destination memory to copy to, $5000
        sta $FD 
        lda #>dst
        sta $FE

        ldy #$00

    copyloop:

        lda #val
        sta ($FD),y  // indirect index dest memory address, starting at $00
        iny
        cpy #40
        bne copyloop // loop until our dest goes over 255

    }


.plugin "se.triad.kickass.CruncherPlugins"

 .var music = LoadSid("intromusre.sid")

.pc = $f00 "democode"
start:

    lda #0
    sta $F0
    sta $F1
    lda #30
    sta $F2

    sei
    lda #<short_irq
    sta $fffe
    lda #>short_irq
    sta $ffff
    lda #$ff
    sta $d012

    cli

    lda #0
    sta $d020
    sta $d021

    lda #%00010000
    sta $d011

    lda #%00001000
    sta $d016

    FillScreenMemory($d800,1)
    lda #0
    sta $d021
    lda #0
    sta $E1

loop_envmap:
    lda #2
    sta $E3
    // load 6400, sub envmap, store 5400

    lda #<$6400
    sta lx1+1
    lda #>$6400
    sta lx1+2

    lda #<$9000
    adc $f0
    sta lx2+1
    lda #>$9000
    sta lx2+2

    lda #<$4400
    sta lx3+1
    lda #>$4400
    sta lx3+2

    ldy #0
xl:
    ldx #0
xl1:

lx1:
    lda $6400,x
    clc 
lx2:
    sbc $9000,x
    cmp #64
    bcs no_x1
lx3:
    sta $4400,x
no_x1:
    inx
    cpx #0
    bne xl1

    inc lx1+2
    inc lx2+2
    inc lx3+2

    iny
    cpy #4
    bne xl

    // load 6800, sub envmap, store 5800

    lda #<$6800
    sta lx21+1
    lda #>$6800
    sta lx21+2

    lda #<$9000
    adc $f0
    sta lx22+1
    lda #>$9000
    sta lx22+2

    lda #<$4800
    sta lx23+1
    lda #>$4800
    sta lx23+2

    ldy #0
x2l:
    ldx #0
x2l1:

lx21:
    lda $6800,x
    clc 
lx22:
    sbc $9000,x
    cmp #64
    bcs no_x21
lx23:
    sta $4800,x
no_x21:
    inx
    cpx #0
    bne x2l1

    inc lx21+2
    inc lx22+2
    inc lx23+2

    iny
    cpy #4
    bne x2l
    
    inc $F1
    ldx $f1
    lda $9500,x
    lsr
    adc #10
    sta $F0


    lda part_hi
    cmp #$33
    bcs loop_fadetowhite11
    jmp loop_envmap


loop_fadetowhite11:
    lda #30
    sta $F2
    lda #0
    sta $f0


loop_fadetowhite:
 
    lda #<$6400
    sta flx1+1
    lda #>$6400
    sta flx1+2

    lda #<$4400
    sta flx3+1
    lda #>$4400
    sta flx3+2

    ldy #0
fxl:
    ldx #0
fxl1:

flx1:
    lda $6400,x
    clc 
    sbc $F2
    cmp #38
    bcs no_over1
    cmp #0
    bcc no_over1
flx3:
    sta $4400,x
no_over1:
fno_x1:
    inx
    cpx #0
    bne fxl1

    inc flx1+2
    inc flx3+2

    iny
    cpy #4
    bne fxl

    // load 6800, sub envmap, store 5800

    lda #<$6800
    sta flx21+1
    lda #>$6800
    sta flx21+2

    lda #<$4800
    sta flx23+1
    lda #>$4800
    sta flx23+2

    ldy #0
fx2l:
    ldx #0
fx2l1:

flx21:
    lda $6800,x
    clc 
    sbc $F2
    cmp #38
    bcs no_over2
    cmp #0
    bcc no_over2

flx23:
    sta $4800,x
no_over2:
fno_x21:
    inx
    cpx #0
    bne fx2l1

    inc flx21+2
    inc flx23+2

    iny
    cpy #4
    bne fx2l


    lda $F2
    cmp #210
    bne no_reset_color0

    jmp partswitch
no_reset_color0:

    jmp loop_fadetowhite

flipper:
    .byte 0

short_irq:
    sta restorea+1
    stx restorex+1
    sty restorey+1

    inc $d019

    inc part_lo
    lda part_lo
    bne no_part_hi_add
    inc part_hi
no_part_hi_add:

    lda part_hi
    cmp #$31
    bcc no_inc
    inc $F0
    lda $F0
    cmp #4
    bne no_inc
    lda #0
    sta $F0
/*
    ldx $F1
    lda sintab,x
    lsr
*/
    dec $F2
no_inc:

    lda flipper
    cmp #1
    beq show_offsetted
    lda #%00010100 // $400
    sta $d018
    lda #%00000000
    sta $d016    
    jmp do_flipper
show_offsetted:
    lda #%00100100 // $800
    sta $d018
    lda #%00000100
    sta $d016
do_flipper:
    inc flipper
    lda flipper
    cmp #2
    bne no_resetflip
    lda #0
    sta flipper
no_resetflip:

    jsr $c003 // le musica
restorea: lda #$00
restorex: ldx #$00
restorey: ldy #$00
    rti


waitforpart:
    dey

waiter0:
    cpy part_hi
    bcs waiter0
    rts


wait:
waiter1:
    lda #64
    cmp $D012
    bne *-3
    dey
    cpy #0
    bne wait
    rts

.pc = $3f00 "next part irq"
nextirq:
    sta restoreaa+1
    stx restorexa+1
    sty restoreya+1

    inc part_lo
    lda part_lo
    bne no_part_hi_add2
    inc part_hi
no_part_hi_add2:

    jsr $c003 // le musica

    lda #$ff
    sta $d019
restoreaa: lda #$00
restorexa: ldx #$00
restoreya: ldy #$00
    rti

.pc = $3fc0 "partswitch"

partswitch:
    lda #<nextirq
    sta $fffe
    lda #>nextirq
    sta $ffff

    jsr $c90 // load part2 -> hires3.asm
partswitch2:
    jmp $f00
