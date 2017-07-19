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
.pc = $f00 "democode"

part_init:
charrotator:
    lda #%00000010
    sta $dd00

    lda #$02   // set vic bank #1 with the dkd loader way
    and #$03
    eor #$3f
    sta $dd02

    lda #%01010011
    sta $d011

    // Setup some sprites
    lda #%11101111
    sta $d015

    lda #0
    sta $d01c

    lda #11
    sta $d027
    sta $d028
    sta $d029
    sta $d02a

    lda #1
    sta $d02c
    lda #10
    sta $d02d
    lda #0
    sta $d02e


    lda #%00001010
    sta $d010

    lda #24
    ldy #54
    sta $d000
    sty $d001

    lda #64
    ldy #54
    sta $d002
    sty $d003

    lda #24
    ldy #225
    sta $d004
    sty $d005

    lda #64
    ldy #225
    sta $d006
    sty $d007


    lda #64
    ldy #100
    sta $d00a
    sty $d00b
    sta $d00c
    sty $d00d
    sta $d00e
    sty $d00f



    // ecm colors

    lda #5
    sta $D022
    lda #12
    sta $D023
    lda #15
    sta $D024

    lda #11
    sta $d020

    :FillScreenMemory($6000, 0) // character mem aka 128x128 "framebuffer"
    :FillScreenMemory($63e8, 0) // character mem
    :FillScreenMemory($63e8+$3e8*1, 0) // character mem
    :FillScreenMemory($63e8+$3e8*2, 0) // character mem
    FillScreenMemory($d800,0)

    lda #%00011000
    sta $d018


    .for(var i = 0; i < 25; i+=4) {
    set_line($4400+40*i,2<<6)
    set_line($4400+40*(i+1),1<<6)
    set_line($4400+40*(i+2),3<<6)
    set_line($4400+40*(i+3),1<<6)
    }

    set_line($4400+40*10,(2<<6)+3)
    set_line($4400+40*11,3)
    set_line($4400+40*12,(3<<6)+2)
    set_line($4400+40*13,1)
    set_line($4400+40*14,(2<<6)+1)


    lda #$0
    sta $4400+$3f8
    lda #$1
    sta $4400+$3f9
    lda #$2
    sta $4400+$3fa
    lda #$3
    sta $4400+$3fb

    lda #$7
    sta $4400+$3fd
    lda #$6
    sta $4400+$3fe
    lda #$5
    sta $4400+$3ff


//    jsr init16
    .for(var xx = 0; xx < 8; xx++) {
    ldx #xx
    ldy #xx
    jsr putpix16
    }

    .for(var xx = 8; xx < 16; xx++) {
    lda #xx
    and #7
    tax
    ldy #xx
    jsr putpix16
    }

    .for(var xx = 16; xx < 20; xx++) {
    lda #7
    sbc #(xx-16)
    and #7

    tax
    ldy #xx
    jsr putpix16
    }

    .for(var xx = 20; xx < 24; xx++) {
    lda #xx
    adc #0
    and #7
    tax
    ldy #xx
    jsr putpix16
    }

    .for(var xx = 24; xx < 32; xx++) {
    lda #7
    sbc #(xx-24)
    and #7
    tax
    ldy #xx
    jsr putpix16
    }

do_pixel:
    clc
    .for (var i = 0; i < 5; i++) {
        lda $6000+i
        asl
        adc #0
        eor $6000+i+1
        sta $6000+i
    }

    lda #0
    sta $F1
pixloop:

    clc
    // x scrolls
    .for (var i = 0; i < 8; i++) {
        lda $6000+8+i
        asl
        adc #0
        sta $6000+8+i
        lda $6000+16+i
        asl
        adc #0
        sta $6000+16+i
        lda $6000+24+i
        asl
        adc #0
        sta $6000+24+i

    }

    // y scroll
    lda $6000+7
    sta $F2

    ldx #0
ycopy1:
    lda $6000,x
    sta $E1,x
    inx
    cpx #8
    bne ycopy1


    ldx #0
ycopy2:
    lda $E1,x
    sta $6001,x
    inx
    cpx #7
    bne ycopy2

    lda $F2
    sta $6000
    // y scroll end
no_yscroll:
    ldy #1
    jsr wait



    inc $F1
    lda $F1
    cmp #8
    bne no_scrollreset
    lda #0
    sta $F1
no_scrollreset:

    jmp pixloop

    jmp *


colors:
    .byte 2<<6,1<<6,2<<6,3<<6

putpix16:
    lda #<$6000
    sta $fb

    // ptr = (x / 8) * 128
    txa
    lsr                     // x / 8
    lsr
    lsr

    lsr                     // * 128 (16-bit)
    ror $fb
    adc #>$6000
    sta $fc

    // mask = 2 ^ (x & 3)
    txa
    and #%00000111
    tax
    lda ($fb),y
    ora bitmask16,x
    sta ($fb),y
    rts

index16:
    .byte 0,0

bitmask16:
     .byte $80,$40,$20,$10,$08,$04,$02,$01

init16:

ichar:
    ldx #0
initic: 
    txa
    ldy #0
i162:
    sta $4400,y
    clc
    adc #16
    iny
    cpy #16
    bne i162

    lda i162+1
    clc
    adc #40
    sta i162+1
    bcc *+5
    inc i162+2

    inx
    cpx #16
    bne initic

    rts

wait:
waiter1:
    lda #255
    cmp $D012
    bne *-3
    dey
    cpy #0
    bne wait
    rts

frame:
    .byte 0
frame2:
    .byte 0
frame3:
    .byte 0

.pc = $4000
sprite1:    
            .byte %11111000, %00000000, %00000000   
            .byte %11100000, %00000000, %00000000   
            .byte %11000000, %00000000, %00000000   
            .byte %10000000, %00000000, %00000000   
            .byte %10000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte $00
sprite2:    
            .byte %00000000, %00000000, %00011111   
            .byte %00000000, %00000000, %00000111   
            .byte %00000000, %00000000, %00000011   
            .byte %00000000, %00000000, %00000001   
            .byte %00000000, %00000000, %00000001   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte $00
sprite3:    
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %10000000, %00000000, %00000000   
            .byte %10000000, %00000000, %00000000   
            .byte %11000000, %00000000, %00000000   
            .byte %11100000, %00000000, %00000000   
            .byte %11111000, %00000000, %00000000   
            .byte $00
sprite4:    
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000001   
            .byte %00000000, %00000000, %00000001   
            .byte %00000000, %00000000, %00000011   
            .byte %00000000, %00000000, %00000111   
            .byte %00000000, %00000000, %00011111   
            .byte $00
sprite5:
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte %00000000, %00000000, %00000000   
            .byte $00

sprite6:
.byte $00,$00,$00,$00,$00,$00,$03,$C3,$C0,$04,$24,$20,$08,$18,$10,$10,$00,$08,$10,$00,$08,$10,$00,$08,$10,$00,$08,$08,$00,$10,$08,$00,$10,$04,$00,$20,$02,$00,$40,$01,$00,$80,$00,$81,$00,$00,$42,$00,$00,$24,$00,$00,$18,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$10

sprite7:
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$C3,$C0,$07,$E7,$E0,$0F,$FF,$F0,$0F,$FF,$F0,$0F,$FF,$F0,$0F,$FF,$F0,$07,$FF,$E0,$07,$FF,$E0,$03,$FF,$C0,$01,$FF,$80,$00,$FF,$00,$00,$7E,$00,$00,$3C,$00,$00,$18,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$1A

sprite8:
.byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$03,$00,$00,$04,$00,$00,$04,$00,$00,$04,$00,$00,$02,$00,$00,$02,$00,$00,$01,$00,$00,$00,$80,$00,$00,$40,$00,$00,$20,$00,$00,$10,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$01


.pc = $e000  "sintab" virtual
sintab:
    .fill 256,0
.pc = $e100  "costab" virtual
costab:
    .fill 256,0
.pc = $e200 "sintab2" virtual
sintab2:
    .fill 256,0
.pc = $e300 "costab2" virtual
costab2:
    .fill 256,0

