.var part_lo = $c1
.var part_hi = $c2

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
        sta $EB
        lda #>src 
        sta $EC
        lda #<dst // set our destination memory to copy to, $5000
        sta $ED 
        lda #>dst
        sta $EE

        ldx #size // size of copy
        ldy #$00

    copyloop:

        lda ($EB),y  // indirect index source memory address, starting at $00
        //eor ($FD),y  // indirect index dest memory address, starting at $00
        sta ($ED),y  // indirect index dest memory address, starting at $00
        iny
        bne copyloop // loop until our dest goes over 255

        inc $EC // increment high order source memory address
        inc $EE // increment high order dest memory address
        dex
        bne copyloop // if we're not there yet, loop

    }

    .macro copymem_eor_short(src,dst,size) {
        lda #<src // set our source memory address to copy from, $6000
        sta $DB
        lda #>src 
        sta $DC
        lda #<dst // set our destination memory to copy to, $5000
        sta $DD 
        lda #>dst
        sta $DE

        ldx #size // size of copy
        ldy #$00

    copyloop:

        lda ($DB),y  // indirect index source memory address, starting at $00
        eor ($DD),y  // indirect index dest memory address, starting at $00
        sta ($DD),y  // indirect index dest memory address, starting at $00
        iny
        bne copyloop // loop until our dest goes over 255

        inc $DC // increment high order source memory address
        inc $DE // increment high order dest memory address
        dex
        bne copyloop // if we're not there yet, loop

        ldy #$00

    copyloop2:

        lda ($DB),y  // indirect index source memory address, starting at $00
        eor ($DD),y  // indirect index dest memory address, starting at $00
        sta ($DD),y  // indirect index dest memory address, starting at $00
        iny
        cpy #190
        bne copyloop2 // loop until our dest goes over 255

    }

    .macro copymem_color(src,dst,size) {
        lda #<src // set our source memory address to copy from, $6000
        sta $EB
        lda #>src 
        sta $EC
        lda #<dst // set our destination memory to copy to, $5000
        sta $ED 
        lda #>dst
        sta $EE

        ldx #size // size of copy
        ldy #$00

    copyloop:

        lda ($EB),y  // indirect index source memory address, starting at $00
        //eor ($FD),y  // indirect index dest memory address, starting at $00
        sta ($ED),y  // indirect index dest memory address, starting at $00
        iny
        bne copyloop // loop until our dest goes over 255

        inc $EC // increment high order source memory address
        inc $EE // increment high order dest memory address
        dex
        bne copyloop // if we're not there yet, loop

        ldx #0
    copyloop2:

        lda ($EB),y  // indirect index source memory address, starting at $00
        //eor ($FD),y  // indirect index dest memory address, starting at $00
        sta ($ED),y  // indirect index dest memory address, starting at $00
        iny
        cpy #$e8
        bne copyloop2 // loop until our dest goes over 255

    }

    .macro setsprites() {
        lda #24
        sta $F1
        ldy #0
        ldx #0
    possprites:
        lda $f1
        sta $d000,x
        lda #226
        sta $d001,x
        lda #0
        sta $d027,y
        lda #168
        sta $63f8,y
        lda $f1
        clc
        adc #48
        sta $f1
        inx
        inx  
        iny
        cpy #8
        bne possprites
        lda #8
        sta $d00e

    }

    .macro revealsprites() {
    ldx #0
    stx $F0
possprites0_:
    ldx #0
    ldy #1
    jsr wait

possprites0:
    lda #226
    clc
    adc $F0
    sta $d001,x
    inx  
    inx  
    cpx #16
    bne possprites0

    inc $F0
    lda $F0
    cmp #25
    bne possprites0_

    }

    .macro fadetext() {

    lda #0
    sta $F0
    ldy #0
coltest0:
    ldx #255-16
    ldy #1
    jsr wait
coltest:

    lda $6370,x
    cmp #1
    beq no_alter
    ldy $F0
    lda fadetab2,y
    sta $6370,x
no_alter:
    dex
    cpx #255
    bne coltest
    inc $F0
    lda $F0
    cmp #8
    bne coltest0

    }

    .macro fadescreen() {

    lda #0
    sta $F0
    ldy #0
coltest0:
    ldx #0
    ldy #1
    jsr wait
coltest:

    lda $6000,x
    cmp #1
    beq no_alter1
    ldy $F0
    lda fadetab2,y
    sta $6000,x
no_alter1:
    lda $6100,x
    cmp #1
    beq no_alter2
    ldy $F0
    lda fadetab2,y
    sta $6100,x
no_alter2:
    lda $6200,x
    cmp #1
    beq no_alter3
    ldy $F0
    lda fadetab2,y
    sta $6200,x
no_alter3:
    lda $6300,x
    cmp #1
    beq no_alter4
    cpx #32+80
    bcs no_alter4
    ldy $F0
    lda fadetab2,y
    sta $6300,x
no_alter4:
    inx
    cpx #0
    bne coltest
    inc $F0
    lda $F0
    cmp #8
    bne coltest0

    }

.macro putcol(xx,yy,col) {
    lda xx
    cmp #40
    bcs no_put

    lda yy
    cmp #25
    bcs no_put

    lda xx
    cmp #240
    bcs no_put

    lda yy
    cmp #240
    bcs no_put

    lda #col
    sta $e1
    ldx xx
    stx $e2
    ldy yy
    tya
    asl
    tax
    lda screenmemtab,x
    sta screenadd+1
    lda screenmemtab+1,x
    sta screenadd+2
    ldy $e2

    lda $e1
screenadd:
    sta $d800,y

no_put:
}


.pc = $f00 "democode"

part_init:
    lda #$ff
    sta $d012

bols:
/*
    ldy #$14
    jsr waitforpart
*/


    // enable all sprites
    lda #%11111111
    sta $d015
    // sprite 0 pos
    lda #80
    sta $d000
    lda #230
    sta $d001
    
    lda #120
    sta $d002
    lda #230
    sta $d003
    
    lda #140
    sta $d004
    lda #230
    sta $d005

    lda #160
    sta $d006
    lda #230
    sta $d007

    lda #180
    sta $d008
    lda #230
    sta $d009

    lda #200
    sta $d00a
    lda #230
    sta $d00b

    lda #220
    sta $d00c
    lda #230
    sta $d00d

    lda #240
    sta $d00e
    lda #230
    sta $d00f

    lda #0
    sta $d010
    lda #$00

    // sprite pointer
    lda #$cc
    sta $47f8
    sta $47f9
    sta $47fa
    sta $47fb
    sta $47fc
    sta $47fd
    sta $47fe
    sta $47ff


    // behind screen sprites
    lda #$0
    sta $d01b

    // sprite color
    lda #0
    sta $d027
    sta $d028
    sta $d029
    sta $d02a
    sta $d02b
    sta $d02c
    sta $d02d
    sta $d02e

    // single color sprites
    lda #0
    sta $d01c

    // stretch sprites
    lda #$ff
    sta $d01d
    lda #$00
    sta $d017

    lda #%00011000
    sta $d018

    :copymem(bolchars,$6000,8)
    :FillScreenMemory($4400, 0)
    lda #0
    sta $d020
    lda #0
    sta $d021

// boleorring

    lda #0
    sta $ee
    sta $ef
    sta $f0
    lda #0
    sta frame
    sta frame2
    sta $d5

    // bols
    lda #$11
    sta $d011

bolop:

//    :FillScreenMemory($4400, 0)

    // reversed coords, y = x, x = y

    lda frame
    clc
    adc $f0
    tax
    lda costab2,x
    clc
    ror
    clc
    ror
    adc #15
    tay

    ldx frame
    lda sintab2,x
    clc
    ror
    clc
    ror
    adc #2
    tax

    lda #%10001000
    jsr bolpix
    inc frame

    inc $ee
    lda $ee
    cmp #3
    bne no_bloslow
    lda #0
    sta $ee

    ldx #1
    ldy #1
    jsr wait

    :copymem_eor_short($4400,$4400+40,3)

    inc frame2
    lda frame2
    cmp #200
    bne cont_boleor
    jmp bolscroll
cont_boleor:

no_bloslow:

    inc $ef
    lda $ef
    cmp $f0
    bne nobf

    lda #0
    sta $ef
    inc $f0
nobf:
/*
    ldx #0
    ldy #0

    stx bres_x1
    sty bres_y1

    ldx frame
    ldy #49

    inc frame
    stx bres_x2
    sty bres_y2
    :bresenham(bres_x1,bres_y1,bres_x2,bres_y2,bres_err,bres_cntr,bres_dx,bres_dy)
*/

    jmp bolop

bolerase:
    ldx #255
    stx $F1
bolerase_loopx:
.for (var i=0; i < 8;i++) {
    lda $6000+i,x
    lsr
    sta $6000+i,x
    lda $6100+i,x
    asl
    sta $6100+i,x
    lda $6200+i,x
    lsr
    sta $6200+i,x
    lda $6300+i,x
    asl
    sta $6300+i,x
    lda $6400+i,x
    lsr
    sta $6400+i,x
    lda $6500+i,x
    asl
    sta $6500+i,x
    lda $6600+i,x
    lsr
    sta $6600+i,x
    lda $6700+i,x
    asl
    sta $6700+i,x
    lda $6800+i,x
    lsr
    sta $6800+i,x
}
    
    inc $F1
    lda $F1
    cmp #3
    bne no_bloeraseslow
    lda #0
    sta $F1
    ldy #1
    jsr wait
no_bloeraseslow:

    dex
    bne bolerase_looper
    jmp bolend
bolerase_looper:
    jmp bolerase_loopx
bolend:
    FillScreenMemory($4400,0)

    rts

bolscroll:

    jsr bolerase

    lda #0 // disable sprites
    sta $d015

//    FillScreenMemory($4400,0)

    :copymem($4400,$4000,4)

    :copymem(bolchars,$7800,8)

    lda #%00001111 // $4000, chars at $7800
    sta $d018

    lda #4
    sta $D5

    lda #0
    sta $D9
bolfiller:
bolfiller_y:
    lda #0
    sta $D8

bolfiller_x:

    ldy $D8
    ldx $D9

    lda #%10001000
    jsr bolpix

    inc $D8
    lda $D8
    cmp #80
    bne bolfiller_x

    inc $D9
    lda $D9
    cmp #50

    bne bolfiller_y


    lda #<$6828
    sta $F9
    lda #>$6828
    sta $FA

    lda #0
    sta $F4
    sta $F6
    sta $F7
    sta $F8

    lda #0
    sta $F5


    lda #0
    sta $DB // bytelbuf
    lda #0
    sta $d020
    lda #%00001111 // $4000, chars at $7800
    sta $d018

// eye anim
    jsr $c90 // load eye data

    copymem($e000,$4000,4)

    ldy #$17
    jsr waitforpart


    .for (var i = 0; i < 13; i++) {
        SetScreenMemory($4400+i*$400)

        ldy #6
        jsr wait
    }  

    ldy #$18
    jsr waitforpart


    .for (var i = 1; i < 7; i++) {
        SetScreenMemory($4400+i*$400)

        ldy #10
        jsr wait
    }  



    :copymem($5c00,$4400,4)
    SetScreenMemory($4400)
    :copymem(bolchars,$6000,8)
    lda #%00011000
    sta $d018

    jsr bolerase
/*
    lda #0
    sta $D5
    sta $D9
bolfiller2:
    lda #0
    sta $D8

bolfiller_x2:

    ldx $d8
    lda #0
bolfilc0:
    sta $d800,x
bolfilc1:
    sta $d900,x
bolfilc2:
    sta $da00,x
bolfilc3:
    sta $db00,x
    ldy #1
    jsr wait

    inc $D8
    lda $D8
    cmp #0
    bne bolfiller_x2
*/
    lda #0
    sta $d020
    :copymem(bolchars,$6000,8)
    FillScreenMemory($4400,0)
    SetScreenMemory($4400) // reset to screen at $4400, chars at $6000
    lda #%00011000
    sta $d018

    jsr $c90 // load color mask and scroller data

bolwaitter:
    ldx #80
    cpx part_lo
    bcc bolwaitter

    :copymem($6800,$4400,4)
    FillScreenMemory($4800,0)

actualscroll:

fillloop1:
    
bol_copyloop_y:
    lda $F4
    cmp #4
    beq copy_done

    ldx #255
bol_copyloop_x:
    lda $6828,x
bol_copyloop_target:
    sta $4800,x 
    dex
    cpx #255
    bne bol_copyloop_x // loop until our dest goes over 255

    inc bol_copyloop_x+2
    inc bol_copyloop_target+2
    inc $F4 // pagecount

copy_done:

    lda #%00011111
    clc
    sbc $f5
    sta $d011
    inc $F5

    ldy #1
    jsr wait2


    lda $F5
    cmp #7
    bcc no_finenull
    beq do_offsetting
    cmp #8
    beq do_fine
do_fine:
    lda #0
    sta $F4
    sta $F5
    lda #%00011111
    clc
    sbc $f5
    sta $d011
    jmp no_finenull
do_offsetting:

    lda $F9
    clc
    adc #40
    sta $F9
    bcc bol_no_src_inc
    inc $FA
bol_no_src_inc:
    lda $F9
    sta bol_copyloop_x+1
    lda $FA
    sta bol_copyloop_x+2
    cmp #$9b
    beq boscroll_over

    lda $db
    cmp #0
    bne bolbuf1
bolbuf0:
    lda #%00101000 // 4800
    sta $d018
    lda #<$4400
    sta bol_copyloop_target+1
    lda #>$4400
    sta bol_copyloop_target+2

    jmp bolbufflipped
bolbuf1:
    lda #%00011000 // 4400
    sta $d018
    lda #<$4800
    sta bol_copyloop_target+1
    lda #>$4800
    sta bol_copyloop_target+2

bolbufflipped:
    inc $db
    lda $db
    cmp #2
    bne no_bolbytelres
    lda #0
    sta $db
no_bolbytelres:

no_finenull:

    jmp fillloop1

boscroll_over:


    lda #%00011000 // 4400
    sta $d018

ranbyteols:

// ranbyteols

    lda #0
    sta $DA
    sta $DC
    sta $DD
    sta $DB

fillloop2:
    ldx #255
    ldy #1
    jsr wait
    ldx #255

fillloop3:
    lda $DB
    beq doEor2
    asl
    beq noEor2
    bcc noEor2
doEor2:  
    eor #$1d
noEor2:  
    sta $DB

    sta $43ff,x
    sta $44ff,x
    sta $45ff,x
    sta $46ff,x

    eor $DC
    sta $d7ff,x
    sta $d8ff,x
    sta $d9ff,x
    sta $daff,x
    dex
    bne fillloop3

    dex

    inc $DD


    lda $DD
    cmp #32
    bne no_incflasheor2
    lda #0
    sta $DD
    inc $DC
    inc $DA

    ldy part_hi
    cpy #$26
    beq nobols

no_incflasheor2:
    sta $4400,x
    sta $4500,x
    sta $4600,x
    sta $4700,x

    eor $DC

    sta $d800,x
    sta $d900,x
    sta $da00,x
    sta $db00,x

    jmp fillloop2

nobols:

    .var a = $D0
    .var a2 = $D1
    .var a3 = $D2

    lda #0
    sta a
    sta a2
    sta a3
    sta $D9
    sta $D8

nextloop:
    lda #0
    sta $D3

loop:
    inc a

    lda a
    cmp #0
    bne no_a_adder
    inc a2
    lda a2
    cmp #4
    bne no_a2
    lda a3
    clc
    adc #2
    sta a3
    lda #0
    sta a2
no_a2:
no_a_adder:

    lda a3

    cmp #164
    bcs no_trapixel

    ldx a
    lda tradata,x
    adc a3
    sta $D5


    ldx a
    lda tradata+256,x
    adc #12
    sta $D6

    putcol($D5,$D6,0)
no_trapixel:
    inc $D3
    lda $D3
    cmp #32

    bne loop
    inc $D9
    lda $D9
    cmp #150
    bne boltracont
    inc $D8
    lda $D8
    cmp #11
    beq boltradone
boltracont:

    jmp nextloop
boltradone:

sundial:
    jsr $c90 // load sundial data

    lda #0
    sta $d020
    lda #%00111011
    sta $d011
    lda #%10000000 // bitmap at $4000, screen at $6000
    sta $d018

    lda #%11111111
    sta $d015

    sta $d017
    sta $d01d

    lda #%11000000
    sta $d010

    setsprites()

    copymem($8400,$5c00-128,4)
    copymem_color($7000,$6000,3)

    ldy #255
    jsr wait

    revealsprites()

    ldy #255
    jsr wait
    ldy #255
    jsr wait

    fadetext()

    ldy #255
    jsr wait

    setsprites()
    copymem_color($7000,$6000,3)
    copymem($8800,$5c00-128,4)

    revealsprites()

    ldy #255
    jsr wait
    ldy #255
    jsr wait

    fadetext()

    ldy #255
    jsr wait
    setsprites()
    copymem_color($7000,$6000,3)
    copymem($8000,$5c00-128,4)

    revealsprites()

    ldy #255
    jsr wait
    ldy #255
    jsr wait

    fadetext()

    ldy #255
    jsr wait

    fadescreen()

    lda $d011
    eor #%00010000 // off
    sta $d011

    ldy #$2b
    jsr waitforpart


borderopen:
    
    jsr $c90 // load creditsprites

    lda $d011
    eor #%00010000 // on
    sta $d011

    lda #0
    sta frame

    lda #$00
    sta $d017

    lda #0
    sta $d010

    lda #%00111011
    sta $d011

    lda #%01001000
    sta $d018

    lda #%11001000
    sta $d016

    // Setup some sprites
    lda #%00111111
    sta $d015

    lda #0
    sta $d01c

    lda #$0
    sta $5000+$3f8
    lda #$1
    sta $5000+$3f9
    lda #$2
    sta $5000+$3fa
    lda #$3
    sta $5000+$3fb
    lda #$4
    sta $5000+$3fc
    lda #$5
    sta $5000+$3fd

    ldy #30

    lda #68-45
    sta $d000
    sty $d001
    lda #67-45+24*1
    sta $d002
    sty $d003
    lda #68-46+24*2
    sta $d004
    sty $d005
    lda #69-44+24*3
    sta $d006
    sty $d007
    lda #69-38+24*4
    sta $d008
    sty $d009
    lda #69-33+24*5
    sta $d00a
    sty $d00b

    sei
    lda #<irq1
    sta $fffe
    lda #>irq1
    sta $ffff
    cli

    ldy #$2e
    jsr waitforpart

    lda #0
    sta $d015

    lda #<nextirq
    sta $fffe
    lda #>nextirq
    sta $ffff

    lda #0
    sta $a9
forever:

    lda #%00111011
    sta $d011

    lda #252
    clc
    sbc $a9
waitfor:
    cmp $d012
    bne waitfor

    lda #%01111011
    sta $d011

no_fuller:
    lda #254
waitfor2:
    cmp $d012
    bne waitfor2

    inc $a9
    lda $a9
    cmp #252
    beq jumpout
    jmp forever
jumpout:

    lda #255
waitforrasters:
    cmp $d012
    bne waitforrasters

go_partswitch:


    FillBitmap($4000,0)
    FillBitmap($5000,0)
    FillBitmap($6000,0)
    FillBitmap($7000,0)
    FillBitmap($8000,0)
    FillBitmap($9000,0)

    jmp partswitch

.align $100
tradata:
.import c64 "tradata.bin"

screenmemtab:
.word $d800, $d828, $d850,$d878,$d8a0,$d8c8,$d8f0,$d918,$d940,$d968,$d990,$d9b8,$d9e0,$da08,$da30,$da58,$da80,$daa8,$dad0,$daf8,$db20,$db48,$db70,$db98,$dbc0


fadetab:
    .byte $01,$0d,$07,$0f,$03,$05,$0a,$0c,$0e,$08,$04,$02,$0b,$06,$09,$00,$09,$06,$0b,$02,$04,$08,$0e,$0c,$0a,$05,$03,$0f,$07,$0d
fadetab2:
.byte $01<<4, $0d<<4, $03<<4, $0c<<4, $04<<4, $02<<4, $09<<4, $00<<4

faders:
    .byte 0,1,2,3,4,5

.pc = $3000 "raster irqs"
irq1:    
    sta restorea+1
    stx restorex+1
    sty restorey+1

    inc part_lo
    lda part_lo
    bne no_part_hi_add2
    inc part_hi
no_part_hi_add2:

    inc frame  
    lda #%00000000
    sta $d015

    lda #$00
    sta $d012
    lda #$00
    sta $d011
    lda #<irq2
    sta $fffe
    lda #>irq2
    sta $ffff

    lda #$00
    sta $d01d

    inc faders  
    inc faders+1 
    inc faders+2
    inc faders+3 
    inc faders+4 
    inc faders+5

    lda faders
    and #29
    tax
    lda fadetab,x
    sta $d027
    
    lda faders+1
    and #29
    tax
    lda fadetab,x
    sta $d028
    
    lda faders+1
    and #29
    tax
    lda fadetab,x
    sta $d029
    
    lda faders+2
    and #29
    tax
    lda fadetab,x
    sta $d02a
    
    lda faders+3
    and #29
    tax
    lda fadetab,x
    sta $d02b

    lda faders+4
    and #29
    tax
    lda fadetab,x
    sta $d02c

    jsr $c003 // le musica

    lda #$ff
    sta $d019
restorea: lda #$00
restorex: ldx #$00
restorey: ldy #$00
    rti

irq2:    
    sta restorea2+1
    stx restorex2+1
    sty restorey2+1

    lda #$fa
    sta $d012
    lda #%00111111
    sta $d015

    lda #$3b //If you want to display a bitmap pic, use #$3b instead
    sta $d011
    lda #<irq1
    sta $fffe
    lda #>irq1
    sta $ffff

    lda #$ff
    sta $d019

restorea2: lda #$00
restorex2: ldx #$00
restorey2: ldy #$00
    rti

loopere:
    jmp loopere

    .macro clear_colorline(dst) {
        lda #<dst // set our destination memory to copy to, $5000
        sta $FD 
        lda #>dst
        sta $FE
        ldy #0
    copyloop:
        lda #0    
        sta ($FD),y  // indirect index dest memory address, starting at $00
        iny
        cpy #40
        bne copyloop // loop until our dest goes over 255

    }

.macro centerwipeoutmc_trans(waittime) {
    ldx #0
    .for(var i=0;i<13;i++) { 
        ldy #waittime
        jsr wait
        :clear_colorline($4400+40*12+40*i)
        :clear_colorline($4400+40*12-40*i)
        :clear_colorline($d800+40*12+40*i)
        :clear_colorline($d800+40*12-40*i)
    }
}

bolpix: // params, a = 0, 8 or 136 
    sta $F2

    tya
    lsr 
    bcc bp1       
    lsr $F2     //Point shifts right
bp1:
    tay         //if division has a
    txa         //remainder
    lsr
    bcc bp2     
    lsr $F2     //Point moves down
    lsr $F2     //on remainder
bp2:
    tax     

    lda #2
    sta $F4
    lda blotable,x   //Table holds the
    sta $F5          //leftmost screen
    lda bhitable,x   // address of row.
    clc
    sbc $D5
    sta $F6
    lda ($F5),y      // Get screen graphic
    sta $F3

    ora $F2          // mask in new value.
    sta ($F5),y
    rts

blotable: 
    .byte $00,$28,$50,$78,$a0,$c8,$f0
    .byte $18,$40,$68,$90,$b8,$e0
    .byte $08,$30,$58,$80,$a8,$d0,$f8
    .byte $20,$48,$70,$98,$c0
    
bhitable:
    .byte $45,$45,$45,$45,$45,$45,$45
    .byte $46,$46,$46,$46,$46,$46
    .byte $47,$47,$47,$47,$47,$47,$47
    .byte $48,$48,$48,$48,$48

waitforpart:
    dey

waiter0:
    cpy part_hi
    bcs waiter0
    rts

.pc = * "wait"
wait:
waiter1:
    lda #64
    cmp $D012
    bne *-3
    dey
    cpy #0
    bne wait
    rts


wait2:
waiter2:
    lda #248
    cmp $D012
    bne *-3
    dey
    cpy #0
    bne wait2
    rts

frame:
    .byte 0
frame2:
    .byte 0


bolchars:
.import binary "bolchars_flip.raw"


.pc = $3f00 "next part irq"
nextirq:
    sta restoreaa+1
    stx restorexa+1
    sty restoreya+1

    inc part_lo
    lda part_lo
    bne no_part_hi_add
    inc part_hi
no_part_hi_add:

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



.pc = $ba00  "sintab" virtual
sintab:
    .fill 256,0
.pc = $bb00  "costab" virtual
costab:
    .fill 256,0
.pc = $bc00 "sintab2" virtual
sintab2:
    .fill 256,0
.pc = $bd00 "costab2" virtual
costab2:
    .fill 256,0

