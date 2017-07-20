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
        //eor ($FD),y  // indirect index dest memory address, starting at $00
        sta ($FD),y  // indirect index dest memory address, starting at $00
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

 .var music = LoadSid("intromusre.sid")
    BasicUpstart2(start)

.pc = $f00 "democode"

start:
    lda #%00000000
    sta $d011
    lda #2
    sta $dd00
part_init:
    ldx #0
    ldy #0
    lda #music.startSong-1
    jsr music.init

    sei
    lda #<irq1
    sta $314
    lda #>irq1
    sta $315
    lda #$7f
    sta $dc0d
    lda #$01
    sta $d01a

    lda #52
    sta $d012

    cli


charrotator:

    lda #%00010011
    sta $d011

    // Setup some sprites
    lda #%00000111
    sta $d015

    lda #0
    sta $d01c


    lda #1
    sta $d027
    lda #10
    sta $d028
    lda #0
    sta $d029

    lda #%00000000
    sta $d01d
    lda #%00000000
    sta $d017

    lda #%00000000
    sta $d010

    lda #160+12
    ldy #12
    sta $d000
    sty $d001
    sta $d002
    sty $d003
    sta $d004
    sty $d005

FillScreenMemory($d800,0)

    lda #0
    sta $d020
    lda #4
    sta $d021

    ldx #255
drawscr:
    lda #0
    sta $4400
    inc *-2

    lda #0
    sta $4500
    inc *-2

    lda #0
    sta $4600
    inc *-2
    dex
    cpx #255
    bne drawscr

    ldx #232
drawscr2:
    lda #0
    sta $4700
    inc *-2
    dex

    bne drawscr2

loop:
    inc frame3
    lda frame3
    cmp #255
    bne loop
    lda #0
    sta frame3
    inc frame4
    lda frame4
    cmp #32
    bne loop
    lda #0
    sta frame4
//    inc $d021 
    inc frame2
    jsr chrfuck
    jmp loop

wait:
waiter1:
    lda #255
    cmp $D012
    bne *-3
    dey
    cpy #0
    bne wait
    rts

chrfuck:
    lda frame4
    tax
    and #7
    sta $d016
    eor frame2
    lsr
    sta $5000
    asl
    sta $5001
    lsr
    sta $5002
    asl
    sta $5003
    lsr
    sta $5004
    asl
    sta $5005
    lsr
    sta $5006
    asl
    sta $5007
    lsr
    sta $5008
/*
    txa
    and #2
    lsr
    sbc frame
*/
//    txa
    and #2
    adc $d012
    eor $d000,x
    eor $d41b
    lsr $d405
    and #%00011000
    lda frame4
    and #127
    sta $d016
//    sta $d015

    rts
frame:
    .byte 0,8,16,24,32,40,48,56

colors: 
    .byte 12,5,3,2,6,7,9,12

sprcolors: 
    .byte 10,5,3,2,6,7,9,12

frame2:
    .byte 0
frame3:
    .byte 0
frame4:
    .byte 0
sprx:
    .byte 0
spry:
    .byte 0
heartindex:
    .byte 0
yoffs:
    .byte 0

.pc = $3000 "raster irqs"
irq1:    

    lda #<stabilizedirq
    sta $314
    lda #>stabilizedirq
    sta $315
    inc $d012

    //
    // ACK the current IRQ
    //

    inc $d019

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

    lda spry
    cmp #52
    bne music_done
    jsr music.play
music_done:

    lda #0

    nop
    nop
    nop
    ldx heartindex
    lda colors,x
    sta $d020

    ldy #0
nextsprite:
    lda spry // Wait for position where we want LineCrunch to start
    clc
    adc #24
    sta spry
    adc yoffs

    sta $d012
    clc
    sbc #20
    sta $d001
    sta $d003
    sta $d005

    ldy heartindex
    lda frame,y
    tax
    lda sintab,x

    clc
    adc #110
    sta $d000
    sta $d002
    sta $d004

    lda sprcolors,y
    sta $d028

    lda spry
.pc = * "compare"
compare:
    cmp #230
    bcc no_spryreset
    lda #52
    sta spry
    sta $d012

    lda #0
    sta heartindex


    inc frame
    inc frame+1
    inc frame+2
    inc frame+3
    inc frame+4
    inc frame+5
    inc frame+6
    inc frame+7

    lda #12
    sta $d020

    ldx frame
    lda sintab,x
    lsr
    lsr
    sbc #10
//    adc frame
    sta yoffs

  //  jsr chrfuck
    jmp $ea7e
no_spryreset:
    lda #$ff
    sta $d019   //ACK interrupt so it can be called again

    inc heartindex
 //   jsr chrfuck
    jmp $ea7e


.pc = $4000
.import c64 "charscrollvic2.bin"

*=music.location "Music"
.fill music.size, music.getData(i)

.pc = $9000  "sintab"
sintab:
 .fill 512,round(63.5+63.5*sin(toRadians(i*360/64)))