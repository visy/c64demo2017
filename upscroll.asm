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
!loop:
    lda #0
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
    ldy #1
    jsr wait
    dex
    bne !loop-
}


    .macro PNGtoHIRES_single(PNGpicture,BMPData,ColData,color,bgcolor) {

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
                .var Coll2 = bgcolor
                .for (var j = 0 ; j < 8 ; j++ ) {
                    .var ByteValue = 0
                    .for (var i = 0 ; i < 8 ; i++ ) {
                        .if (Graphics.getPixel(Block+i,Line+j) != 0) .eval ByteValue = ByteValue + pow(2,7-i)
                    }
                .byte ByteValue
                }
            .var BlockColor = bgcolor*16+color
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

.plugin "se.triad.kickass.CruncherPlugins"

.pc = $2000 "democode"

start:
    lda #%00111011
    sta $d011
    lda #%10000000 // bitmap at $4000, screen at $6000
    sta $d018

    lda #2
    sta $dd00

    lda #0
    sta $d020
    lda #0
    sta $d021

    lda #%01111111
    sta $d015
    sta $d01d

    lda #64+24
    sta $F1
    ldy #0
    ldx #0
possprites:
    lda $f1
    sta $d000,x
    lda #246
    sta $d001,x
    lda #0
    sta $d027,y
    lda #$1f
    sta $63f8,y
    lda #255
    lda $f1
    clc
    adc #24
    sta $f1
    inx
    inx  
    iny
    cpy #8
    bne possprites

part_init:
/*
    ldx #0
    ldy #0
    lda #music.startSong-1
    jsr music.init
*/
    bit $d011 // Wait for new frame
    bpl *-3
    bit $d011
    bmi *-3

    lda $d011
    eor #%00010000 // off
    sta $d011

    lda #0
    sta $F0 // crunchindex
    B2_DECRUNCH(crunch_pic0)
    lda #255
    sta $47c0
    sta $47c1
    sta $47c2
    sta $47c3
    sta $47c4
    sta $47c5
    sta $47c6
    sta $47c7
    sta $47c8


    ldy #64
    jsr wait

    lda $d011
    eor #%00010000 // on
    sta $d011

nextbitmap:
loop1:

    bit $d011 // Wait for new frame
    bpl *-3
    bit $d011
    bmi *-3



    lda #%00111011
    sta $d011

    jsr CalcNumLines // Call sinus substitute routine

    lda #$30 // Wait for position where we want FLD to start
    cmp $d012
    bne *-3

    ldx NumFLDLines
    beq loop1 // Skip if we want 0 lines FLD
loop2:
    lda $d012 // Wait for beginning of next line
    cmp $d012
    beq *-3

    clc // Do one line of FLD
    lda $d011
    adc #1
    and #7
    ora #$18
    ora #%00100000
    sta $d011

    dex // Decrease counter
    bne loop2 // Branch if counter not 0

the_actual_effect:
    lda do_one_fld_frame
    cmp #0
    beq no_turnon
    lda $d011
    eor #%00010000 // on
    sta $d011
    lda #0
    sta do_one_fld_frame
no_turnon:
    jmp loop1 // Next frame

CalcNumLines:
do_calc_fld:
    inc fldframe
    lda fldframe
    cmp #2
    bne no_incfldframe
    lda #0
    sta fldframe
    inc fldframe+1
no_incfldframe:
CalcNumLines2:
    ldx #220
    lda $c400,x
    clc
    sbc fldframe+1
    sta NumFLDLines
    cmp #5
    bcs no_stop_fld
    jmp stopfld
no_stop_fld:
    inc CalcNumLines2+1
    rts
stopfld:
    ldy #255
    jsr wait
    ldy #255
    jsr wait
    ldy #255
    jsr wait

    FillBitmap($4000,0)

    lda $d011
    eor #%00010000 // off
    sta $d011

    lda #1
    sta do_one_fld_frame

    inc $F0
    lda $F0
    cmp #1
    bne pic2
    B2_DECRUNCH(crunch_pic1)
    jmp donecru
pic2:    
loopforever:
    ldy #60
    jsr wait

    sei
    lda #0
    sta $d404
    sta $d40b
    sta $d412
    sta $d418

    jmp loopforever
donecru:
    lda #0
    sta fldframe 
    lda #75
    sta fldframe+1 
    lda #220
    sta CalcNumLines2+1
    lda #0
    sta NumFLDLines
    jmp nextbitmap

no_new_fld_calc:
    .byte 0
NumFLDLines:
    .byte 0
do_one_fld_frame:
    .byte 0
fldframe:
    .byte 0,75


wait:
waiter1:
    lda #255
    cmp $D012
    bne *-3
    dey
    cpy #0
    bne wait
    rts

// decruncher

.const B2_ZP_BASE = $03
// ByteBoozer Decruncher    /HCL May.2003
// B2 Decruncher            December 2014

.label zp_base  = B2_ZP_BASE
.label bits     = zp_base
.label put      = zp_base + 2

.macro B2_DECRUNCH(addr) {
    ldy #<addr
    ldx #>addr
    jsr Decrunch
}

.macro  GetNextBit() {
    asl bits
    bne DgEnd
    jsr GetNewBits
DgEnd:
}

.macro  GetLen() {
    lda #1
GlLoop:
    :GetNextBit()
    bcc GlEnd
    :GetNextBit()
    rol
    bpl GlLoop
GlEnd:
}

Decrunch:
    sty Get1+1
    sty Get2+1
    sty Get3+1
    stx Get1+2
    stx Get2+2
    stx Get3+2

    ldx #0
    jsr GetNewBits
    sty put-1,x
    cpx #2
    bcc *-7
    lda #$80
    sta bits
DLoop:
    :GetNextBit()
    bcs Match
Literal:
    // Literal run.. get length.
    :GetLen()
    sta LLen+1

    ldy #0
LLoop:
Get3:
    lda $feed,x
    inx
    bne *+5
    jsr GnbInc
L1: sta (put),y
    iny
LLen:
    cpy #0
    bne LLoop

    clc
    tya
    adc put
    sta put
    bcc *+4
    inc put+1

    iny
    beq DLoop

    // Has to continue with a match..

Match:
    // Match.. get length.
    :GetLen()
    sta MLen+1

    // Length 255 -> EOF
    cmp #$ff
    beq End

    // Get num bits
    cmp #2
    lda #0
    rol
    :GetNextBit()
    rol
    :GetNextBit()
    rol
    tay
    lda Tab,y
    beq M8

    // Get bits < 8
M_1: 
    :GetNextBit()
    rol
    bcs M_1
    bmi MShort
M8:
    // Get byte
    eor #$ff
    tay
Get2:
    lda $feed,x
    inx
    bne *+5
    jsr GnbInc
    jmp Mdone
MShort:
    ldy #$ff
Mdone:
    //clc
    adc put
    sta MLda+1
    tya
    adc put+1
    sta MLda+2

    ldy #$ff
MLoop:
    iny
MLda:
    lda $beef,y
    sta (put),y
MLen:
    cpy #0
    bne MLoop

    //sec
    tya
    adc put
    sta put
    bcc *+4
    inc put+1

    jmp DLoop

End:

    rts

GetNewBits:
Get1:
    ldy $feed,x
    sty bits
    rol bits
    inx
    bne GnbEnd
GnbInc: 
    inc Get1+2
    inc Get2+2
    inc Get3+2
GnbEnd:
    rts

Tab:
    // Short offsets
    .byte %11011111 // 3
    .byte %11111011 // 6
    .byte %00000000 // 8
    .byte %10000000 // 10
    // Long offsets
    .byte %11101111 // 4
    .byte %11111101 // 7
    .byte %10000000 // 10
    .byte %11110000 // 13

.pc = $2300 "crunchdata"

.label crunch_pic0 = *
.modify B2() {
    :PNGtoHIRES_single("upscroll.png",$4000,$6000,0,1)
}
.label crunch_pic1 = *
.modify B2() {
    :PNGtoHIRES_single("upscroll2.png",$4000,$6000,0,1)
}


