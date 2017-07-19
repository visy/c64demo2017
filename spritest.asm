*= $0800
.byte $00,$0c,$08,$0a,$00,$9e,$32,$30,$36,$34,$00,$00,$00,$00
     
 *= $0810
  
//--------------------------------------------------   
         
         lda #00
         sta $d020
         sta $d021        
         lda #147
//         jsr $ffd2        
         jsr setup_sprite // init Sprite 1 
//--------------------------------------------------
//  New Raster-IRQ
//--------------------------------------------------
         
         sei  
         lda #<int
         sta $0314
         lda #>int
         sta $0315        // new IRQ
         lda #$00
         sta $d012        
         lda #$7f
         sta $dc0d        // Timer off
         lda #$01
         sta $d019
         sta $d01a        
         cli
         jmp *

//--------------------------------------------------

int:      lda $d019
         and #$01
         sta $d019        
         bne irq
         jmp $ea81
          
//--------------------------------------------------           

irq:     lda #$00
         sta $d012

         jsr animate      // move on x-axis


l0:      lda $d012
         cmp #78          // y = 78
         bne l0     
         sta $d001
         lda #$28         // Spritepointer Sprite 1 
         sta $07f8        // $0a00 = $28*$40

l1:      lda $d012
         cmp #100         // y = 100
         bne l1
         sta $d001          
         lda #$28        // write Sprite-Pointer again
         sta $07f8
         lda #6           // a new color
         sta $d026

l2:      lda $d012
         cmp #122         // y = 122      
         bne l2
         sta $d001          
         lda #$28         // write Sprite-Pointer again
         sta $07f8
         lda #3
         sta $d026

l3:      lda $d012
         cmp #144          // y =144     
         bne l3
         sta $d001            
         lda #$28          // write Sprite-Pointer again
         sta $07f8
         lda #2
         sta $d026         // a new color

le:      lda $d012
         cmp #255
         bne le        
         jmp $ea81
         
//--------------------------------------------------
//   move sprite
//--------------------------------------------------    

animate:  inc $d000
          lda $d000
          bne ex
          lda #50
          sta $d000        
ex:       rts

//--------------------------------------------------
//   Sprite 1 init
//--------------------------------------------------

setup_sprite:

          lda #1           // Colors
          sta $d025
          lda #11
          sta $d026
          lda #15
          sta $d027        // 
          lda #64
          sta $d000        // X-Position
          lda #$01         //
          sta $d015        // Sprite 1 on
          lda #1
          sta $d01c        // Multicolor
          rts

//--------------------------------------------------
//   2 Sprites 
//--------------------------------------------------

*=$0a00
 
.byte $ff,$ff,$ff,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$f0 
.byte $00,$00,$b0,$00,$00,$A0,$00,$00,$AC,$00,$00,$F8,$00,$00,$FE,$0E 
.byte $f0,$aa,$a9,$7c,$aa,$aa,$5b,$ab,$ea,$aa,$eb,$fa,$ab,$03,$f0,$00 
.byte $03,$f0,$00,$03,$c0,$00,$03,$00,$00,$00,$00,$00,$ff,$ff,$ff,$ff 

// $0a40
 
.byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
.byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  
.byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF  
.byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
