         *= $1000
start:
         sei
         lda #51
         sta $01
         ldy #$00
a1:       lda $d000,y
         sta $2000,y
         lda $d100,y
         sta $2100,y
         lda $d200,y
         sta $2200,y
         lda $d300,y
         sta $2300,y
         iny
         bne a1
         lda #55
         sta $01

         lda #$c7
         sta $57

         lda #$00
         sta $58  //
         sta $59  //
         sta $5a  //counters
         sta $5b  //

         jsr $e518
         lda #$0b
         sta $d020
         lda #$00
         sta $d021
         lda #$01
         sta $0286
         lda #$93
         jsr $ffd2
         ldy #18
         sty 214
         jsr $e510

         jsr irq

         rts

//---------------------------------------

irq:      sei
         lda #$81
         sta $d01a
         lda #$7f
         sta $dc0d
         lda #48
         sta $d012
         lda #<irq1
         ldx #>irq1
         sta $0314
         stx $0315
         cli
         rts

irq1:     asl $d019

         lda $d012
         cmp #50
         bne irq1

         ldy #$05
         dey
         bne *-1

         lda $57
         sta $d016

irq2:     lda $d012
         cmp #50+(16*8)
         bne irq2

         ldy #$0a
         dey
         bne *-1

         lda #$c8
         sta $d016

         jsr scroll

         jmp $ea31

//---------------------------------------

scroll:   ldx #$00
sc1:      ldy $57
         dey
         sty $57
         cpy #$bf
         beq sc2
         inx
         cpx #$02 //speed of scroll
         bne sc1  //1,2,4,8 (8=fast)
         rts

sc2:     lda #$c7
         sta $57

scc:      lda $58
         bne sc6
         inc $58

         ldy $59
         lda txt,y
         bne sc3
         sta $59
sc3:      ldy $59
         lda txt,y

         ldx #$00
         stx $02

         ldy #$20
         ldx #$00
         stx $fa
         sty $fb

         asl
         rol $02
         asl
         rol $02
         asl
         rol $02
         clc
         adc $fa
         sta $fa
         lda $02
         adc $fb
         sta $fb

         ldy #$00
sc5:      lda ($fa),y
         sta $02c0,y
         iny
         cpy #$08
         bne sc5

sc6:      lda $5a
         bne sc10
         lda #$01
         sta $5a

         ldy #$04
         ldx #$00
         stx $fc
         sty $fd

         ldx #$00
sc9:      ldy #32
         asl $02c0,x
         bcc sc7
         ldy #160
sc7:      tya
         ldy #39
         sta ($fc),y
         ldy #39+40
         sta ($fc),y
         lda #80
         clc
         adc $fc
         sta $fc
         bcc sc8
         inc $fd
sc8:      inx
         cpx #$08
         bne sc9

         jmp sc13

sc10:     ldy #$04
         ldx #$26
         stx $fc
         sty $fd
         lda #$00
         sta $5a
         ldx #$00
sc12:     ldy #$00
         lda ($fc),y
         iny
         sta ($fc),y
         lda #40
         clc
         adc $fc
         sta $fc
         bcc sc11
         inc $fd
sc11:     inx
         cpx #$10
         bne sc12

sc13:     ldy #$00
sc14:     lda $0401,y
         sta $0400,y
         lda $0401+(1*40),y
         sta $0400+(1*40),y
         lda $0401+(2*40),y
         sta $0400+(2*40),y
         lda $0401+(3*40),y
         sta $0400+(3*40),y
         lda $0401+(4*40),y
         sta $0400+(4*40),y
         lda $0401+(5*40),y
         sta $0400+(5*40),y
         lda $0401+(6*40),y
         sta $0400+(6*40),y
         lda $0401+(7*40),y
         sta $0400+(7*40),y
         lda $0401+(8*40),y
         sta $0400+(8*40),y
         lda $0401+(9*40),y
         sta $0400+(9*40),y
         lda $0401+(10*40),y
         sta $0400+(10*40),y
         lda $0401+(11*40),y
         sta $0400+(11*40),y
         lda $0401+(12*40),y
         sta $0400+(12*40),y
         lda $0401+(13*40),y
         sta $0400+(13*40),y
         lda $0401+(14*40),y
         sta $0400+(14*40),y
         lda $0401+(15*40),y
         sta $0400+(15*40),y
         iny
         cpy #$27
         bne sc14

         inc $5b
         lda $5b
         cmp #$10
         bne sc15
         lda #$00
         sta $58
         sta $5b
         inc $59

sc15:     rts

//---------------------------------------

txt:      .byte $03,$08,$09,$03
         .byte $0f,$20,$20,$20,$03,$09
         .byte $16,$09,$14,$01,$13,$20
         .byte $20,$20,$03,$12,$19,$10
         .byte $14,$20,$20,$20,$20,$00
