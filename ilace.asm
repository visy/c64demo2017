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


 .var music = LoadSid("introre.sid")

BasicUpstart2(start)
.pc = $1000
start:

    lda #2
    sta $dd00
    lda #%01001000
    sta $d018

    lda #0
    sta $d020

    ldx #0
    ldy #0
    lda #music.startSong-1
    jsr music.init

    sei
    lda #$7f   //Disable CIA IRQ's
    sta $dc0d
    sta $dd0d

    lda #$35   //Bank out kernal and basic
    sta $01    //$e000-$ffff
    lda #<irq1 //Install RASTER IRQ
    ldx #>irq1 //into Hardware
    sta $fffe  //Interrupt Vector
    stx $ffff

    lda #$01   //Enable RASTER IRQs
    sta $d01a
    lda #52   //IRQ on line 52
    sta $d012
    lda #$00   //Set Background
    sta $d020  //and Border colors
    lda #$00
    sta $d021
    lda #$00
    sta $d015  //turn off sprites

    asl $d019  // Ack any previous raster interrupt
    bit $dc0d      // reading the interrupt control registers 
    bit $dd0d  // clears them

    cli        //Allow IRQ's

loop:

    jmp loop


//===========================================================================================
// Main interrupt handler
// [x] denotes the number of cycles 
//=========================================================================================== 
irq1:
        //The CPU cycles spent to get in here       [7]
     sta reseta1    //Preserve A,X and Y                [4]
     stx resetx1    //Registers                 [4]
     sty resety1    //using self modifying code         [4]

     lda #<irq2 //Set IRQ Vector                [4]
     ldx #>irq2 //to point to the               [4]
        //next part of the  
     sta $fffe  //Stable IRQ                    [4]
     stx $ffff      //                      [4]
     inc $d012  //set raster interrupt to the next line     [6]
     asl $d019  //Ack raster interrupt              [6]
     tsx        //Store the stack pointer! It points to the [2]
     cli        //return information of irq1.           [2]
            //Total spent cycles up to this point       [51]
     nop        //                      [53]
     nop        //                      [55]
     nop        //                      [57]
     nop        //                      [59]
     nop        //Execute nop's                 [61]
     nop        //until next RASTER             [63]
     nop        //IRQ Triggers                  


.align $1000
//===========================================================================================
// Part 2 of the Main interrupt handler
//===========================================================================================                  
irq2:
     txs        //Restore stack pointer to point the the return
        //information of irq1, being our endless loop.

     ldx #$09   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$03   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$01   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

///////////////

     ldx #$03   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

///////////////

     ldx #$03   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011
///////////////

     ldx #$03   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011
///////////////

     ldx #$03   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011
///////////////

     ldx #$03   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011
///////////////

     ldx #$03   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011
///////////////

     ldx #$03   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011
///////////////

     ldx #$03   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

///////////////   pagecross --------------------------------------------------------

     ldx #$01   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

///////////////

     ldx #$03   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011
///////////////

     ldx #$03   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011
///////////////

     ldx #$03   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011
///////////////

     ldx #$03   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011
///////////////

     ldx #$03   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011
///////////////

     ldx #$03   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0b   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     nop
     lda #%00111011
     sta $d011
///////////////

     ldx #$03   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011
///////////////

     ldx #$03   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011
///////////////

     ldx #$03   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011
///////////////

     ldx #$03   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011
///////////////

     ldx #$03   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011
///////////////

     ldx #$03   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011
///////////////

     ldx #$03   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     ldx #$0a   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%01111011
     sta $d011

     ldx #$0c   //Wait exactly 9 * (2+3) cycles so that the raster line
     dex        //is in the border              [2]
     bne *-1    //                              [3]

     lda #%00111011
     sta $d011

     lda #<irq3 //Set IRQ to point
     ldx #>irq3 //to subsequent IRQ
     ldy #252
     sta $fffe
     stx $ffff
     sty $d012
     asl $d019  //Ack RASTER IRQ

lab_a1: lda #$00    //Reload A,X,and Y
.label reseta1 = lab_a1+1

lab_x1: ldx #$00
.label resetx1 = lab_x1+1

lab_y1: ldy #$00
.label  resety1 = lab_y1+1

     rti        //Return from IRQ

//===========================================================================================
// Part 3 of the Main interrupt handler
//===========================================================================================           
irq3:
     sta reseta2    //Preserve A,X,and Y
     stx resetx2    //Registers
     sty resety2         

     ldy #$13   //Waste time so this line is drawn completely
     dey        //  [2]
     bne *-1    //  [3]
        //same line!
     
          jsr music.play

     lda #<irq1 //Reset Vectors to
     ldx #>irq1 //first IRQ again
     ldy #52  
     sta $fffe
     stx $ffff
     sty $d012
     asl $d019  //Ack RASTER IRQ

lab_a2: lda #$00    //Reload A,X,and Y
.label reseta2  = lab_a2+1

lab_x2: ldx #$00
.label resetx2  = lab_x2+1

lab_y2: ldy #$00
.label resety2  = lab_y2+1

     rti        //Return from IRQ


*=music.location "Music"
.fill music.size, music.getData(i)

PNGtoHIRES("lace.png",$6000,$5000)