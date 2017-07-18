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



.pc = $f00 "democode"

start:
bols:
    jsr $c90 // load colormap

    lda $d011
    eor #%00010000 // on
    sta $d011


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


    // bols
    lda #$11
    sta $d011

    lda #%00011000
    sta $d018

    lda #$02   // set vic bank #1 with the dkd loader way
    and #$03
    eor #$3f
    sta $dd02

    lda #0
    sta $d020
    lda #0
    sta $d021

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

    ldy #255
    jsr wait

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

    ldy #255
    ldx #255
    jsr wait


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


    ldy #255
    jsr wait
    .for (var i = 0; i < 13; i++) {
        SetScreenMemory($4400+i*$400)

        ldy #8
        jsr wait
    }  

    ldy #255
    jsr wait
    .for (var i = 1; i < 7; i++) {
        SetScreenMemory($4400+i*$400)

        ldy #16
        jsr wait
    }  

    ldy #255
    jsr wait


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

    :copymem($6800,$4400,4)
    FillScreenMemory($4800,0)


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
    jsr wait


    lda $F5
    cmp #7
    bne no_finenull
    lda #0
    sta $F5
    sta $F4

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
    cmp #$98
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

    ldx #100
    ldy #100
    jsr wait

    lda #%00011000 // 4400
    sta $d018

ranbyteols:

// ranbyteols

    lda #0
    sta $FA
    sta $FC
    sta $FD
    sta $FB

fillloop2:
    ldx #255
    ldy #1
    jsr wait
    ldx #255

fillloop3:
    lda $FB
    beq doEor2
    asl
    beq noEor2
    bcc noEor2
doEor2:  
    eor #$1d
noEor2:  
    sta $FB

    sta $43ff,x
    sta $44ff,x
    sta $45ff,x
    sta $46ff,x

    eor $FC
    sta $d7ff,x
    sta $d8ff,x
    sta $d9ff,x
    sta $daff,x
    dex
    bne fillloop3

    dex

    inc $FD


    lda $FD
    cmp #32
    bne no_incflasheor2
    lda #0
    sta $FD
    inc $FC
    inc $FA
    lda $FA
    cmp #20
    beq nobols
no_incflasheor2:
    sta $4400,x
    sta $4500,x
    sta $4600,x
    sta $4700,x

    eor $FC

    sta $d800,x
    sta $d900,x
    sta $da00,x
    sta $db00,x

    jmp fillloop2

nobols:

koalapic: // logoscene

    ldx #32
    ldy #32
    jsr wait

    jsr $c90 // load from disk (bit,chr,d80)

    lda #$d8
    sta $d016
    lda #$19
    sta $d018
    lda #$3b
    sta $d011
    lda #0
    sta $d020
    lda #0 // bgcolor
    sta $d021


    ldx #0

koalaloop:
    .for (var i=0; i<4; i++) {
        lda $9600+i*$100,x    // copy color to color ram
        sta $d800+i*$100,x
    }
    inx
    bne koalaloop

    ldx #200
    ldy #200
    jsr wait
    ldx #200
    ldy #200
    jsr wait

    :centerwipeoutmc_trans(10)

    ldy #100
    jsr wait

looper:
    jmp looper

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

bolchars:
.import binary "bolchars_flip.raw"

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
