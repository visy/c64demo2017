

.function toSpritePtr(addr) {
    .return (addr)/$40
}

.macro SetMultiColorMode() {
    lda $d016
    ora #16
    sta $d016   
}


        .const Black   = 000 * 65536 + 000 * 256 + 000   
        .const White   = 255 * 65536 + 255 * 256 + 255
        .const Red     = 104 * 65536 + 055 * 256 + 043
        .const Cyan    = 112 * 65536 + 164 * 256 + 178
        .const Purple  = 111 * 65536 + 061 * 256 + 134
        .const Green   = 088 * 65536 + 141 * 256 + 067
        .const Blue    = 053 * 65536 + 040 * 256 + 121 
        .const Yellow  = 184 * 65536 + 199 * 256 + 111
        .const L_brown = 111 * 65536 + 079 * 256 + 037
        .const D_brown = 067 * 65536 + 057 * 256 + 000
        .const L_red   = 154 * 65536 + 103 * 256 + 089
        .const D_grey  = 068 * 65536 + 068 * 256 + 068
        .const Grey    = 108 * 65536 + 108 * 256 + 108
        .const L_green = 154 * 65536 + 210 * 256 + 132
        .const L_blue  = 108 * 65536 + 094 * 256 + 181
        .const L_grey  = 149 * 65536 + 149 * 256 + 149

        .var RGBColorTable  = Hashtable()

        .macro PNGtoKOALA(PNGpicture,BMPData,Chardata,D800data,BGC) {

        // Create RGB to C64 color index
        .var RGBtoC64 = Hashtable()
        .eval RGBtoC64.put(Black,0)
        .eval RGBtoC64.put(White,1)
        .eval RGBtoC64.put(Red,2)
        .eval RGBtoC64.put(Cyan,3)
        .eval RGBtoC64.put(Purple,4)
        .eval RGBtoC64.put(Green,5)
        .eval RGBtoC64.put(Blue,6)
        .eval RGBtoC64.put(Yellow,7)
        .eval RGBtoC64.put(L_brown,8)
        .eval RGBtoC64.put(D_brown,9)
        .eval RGBtoC64.put(L_red,10)
        .eval RGBtoC64.put(D_grey,11)
        .eval RGBtoC64.put(Grey,12)
        .eval RGBtoC64.put(L_green,13)
        .eval RGBtoC64.put(L_blue,14)
        .eval RGBtoC64.put(L_grey,15)

        // Hashtable for Storing all the colors.

        // Create a list to hold all the Bitmap and collor data
        .var AllData = List(10000)

        // Load the picture into the data list Graphics
        .var Graphics = LoadPicture(PNGpicture,List())

        // Convert and return thed Color
        // Hastable for storing 4x8 block colordata
        .var BlockColors = Hashtable()

        // Hashtable for potential background Colors from inside one block
        .var BG = Hashtable()

        // List for keeping track of background color candidates from all blocks
        .var BGCandidate  = List(4)

        // Declare some variables
        .var CurrentBlock = 0     // Keeps track of which block is being checked
        .var BGRemaining  = 4     // Remaining backgound color candidates (begins with 4 since the first block get's it's 4 colors copied into the BGCandidate Hastable)
        .var ColorCounter = 0     // Counter for keeping track of how many colors are found inside each block
        .var FirstMatch   = true  // Used to diferensiate between the first 4 color block (It has to contain the backgound color) and the rest of the blocks

        // Loop for checking all 1000 blocks
        .for (CurrentBlock=0 ; CurrentBlock<1000 ; CurrentBlock++) {

            // Clear out any block colors from the hashtable
            .eval BlockColors = Hashtable()

            // Fetch 4x8 pixel block colors (32 total)
            .for (var Pixel = 0 ; Pixel < 32 ; Pixel++) {
                .var PixelColor = Graphics.getPixel([8*CurrentBlock+[[Pixel<<1]&7]]-[320*[floor(CurrentBlock/40)]], [8*floor(CurrentBlock/40)]+[Pixel>>2])
                .eval BlockColors.put(PixelColor,Pixel)
            }

            // Reset the block color counter
            .eval ColorCounter = 0

            // Store the block colors in BG
            .if (BlockColors.containsKey(Black)  ==true) { 
                .eval BG.put(ColorCounter,Black)   
                .eval RGBColorTable.put([ColorCounter+[4*CurrentBlock]],Black)   
                .eval ColorCounter=ColorCounter+1 
            }
            .if (BlockColors.containsKey(White)  ==true) { 
                .eval BG.put(ColorCounter,White)   
                .eval RGBColorTable.put([ColorCounter+[4*CurrentBlock]],White)   
                .eval ColorCounter=ColorCounter+1 }
            .if (BlockColors.containsKey(Red)    ==true) { 
                .eval BG.put(ColorCounter,Red)     
                .eval RGBColorTable.put([ColorCounter+[4*CurrentBlock]],Red)     
                .eval ColorCounter=ColorCounter+1 }
            .if (BlockColors.containsKey(Cyan)   ==true) { 
                .eval BG.put(ColorCounter,Cyan)    
                .eval RGBColorTable.put([ColorCounter+[4*CurrentBlock]],Cyan)    
                .eval ColorCounter=ColorCounter+1 }
            .if (BlockColors.containsKey(Purple) ==true) { 
                .eval BG.put(ColorCounter,Purple)  
                .eval RGBColorTable.put([ColorCounter+[4*CurrentBlock]],Purple)  
                .eval ColorCounter=ColorCounter+1 }
            .if (BlockColors.containsKey(Green)  ==true) { 
                .eval BG.put(ColorCounter,Green)   
                .eval RGBColorTable.put([ColorCounter+[4*CurrentBlock]],Green)   
                .eval ColorCounter=ColorCounter+1 }
            .if (BlockColors.containsKey(Blue)   ==true) { 
                .eval BG.put(ColorCounter,Blue)    
                .eval RGBColorTable.put([ColorCounter+[4*CurrentBlock]],Blue)    
                .eval ColorCounter=ColorCounter+1 }
            .if (BlockColors.containsKey(Yellow) ==true) { 
                .eval BG.put(ColorCounter,Yellow)  
                .eval RGBColorTable.put([ColorCounter+[4*CurrentBlock]],Yellow)  
                .eval ColorCounter=ColorCounter+1 }
            .if (BlockColors.containsKey(L_brown)==true) { 
                .eval BG.put(ColorCounter,L_brown) 
                .eval RGBColorTable.put([ColorCounter+[4*CurrentBlock]],L_brown) 
                .eval ColorCounter=ColorCounter+1 }
            .if (BlockColors.containsKey(D_brown)==true) { 
                .eval BG.put(ColorCounter,D_brown) 
                .eval RGBColorTable.put([ColorCounter+[4*CurrentBlock]],D_brown) 
                .eval ColorCounter=ColorCounter+1 }
            .if (BlockColors.containsKey(L_red)  ==true) { 
                .eval BG.put(ColorCounter,L_red)   
                .eval RGBColorTable.put([ColorCounter+[4*CurrentBlock]],L_red)   
                .eval ColorCounter=ColorCounter+1 }
            .if (BlockColors.containsKey(D_grey) ==true) { 
                .eval BG.put(ColorCounter,D_grey)  
                .eval RGBColorTable.put([ColorCounter+[4*CurrentBlock]],D_grey)  
                .eval ColorCounter=ColorCounter+1 }
            .if (BlockColors.containsKey(Grey)   ==true) { 
                .eval BG.put(ColorCounter,Grey)    
                .eval RGBColorTable.put([ColorCounter+[4*CurrentBlock]],Grey)    
                .eval ColorCounter=ColorCounter+1 }
            .if (BlockColors.containsKey(L_green)==true) { 
                .eval BG.put(ColorCounter,L_green) 
                .eval RGBColorTable.put([ColorCounter+[4*CurrentBlock]],L_green) 
                .eval ColorCounter=ColorCounter+1 }
            .if (BlockColors.containsKey(L_blue) ==true) { 
                .eval BG.put(ColorCounter,L_blue)  
                .eval RGBColorTable.put([ColorCounter+[4*CurrentBlock]],L_blue)  
                .eval ColorCounter=ColorCounter+1 }
            .if (BlockColors.containsKey(L_grey) ==true) { 
                .eval BG.put(ColorCounter,L_grey)  
                .eval RGBColorTable.put([ColorCounter+[4*CurrentBlock]],L_grey)  
                .eval ColorCounter=ColorCounter+1 }

            // Carry out a background color check when there are 4 colors in a block
            .if (ColorCounter == 4 && BGCandidate.size()>1) {

                // Check if it is the first block with 4 collors
                .if (FirstMatch) {

                    // Copy the 4 collors as possible candidates
                    .eval BGCandidate.add(BG.get(0))
                    .eval BGCandidate.add(BG.get(1))
                    .eval BGCandidate.add(BG.get(2))
                    .eval BGCandidate.add(BG.get(3))
                    .eval FirstMatch = false
                } else {
                    .for (var i = 0 ; i < BGCandidate.size() ; i++) {
                        .if (BGCandidate.get(i) != BG.get(0)) {
                            .if (BGCandidate.get(i) != BG.get(1)) {
                                .if (BGCandidate.get(i) != BG.get(2)) {
                                    .if (BGCandidate.get(i) != BG.get(3)) {
                                        .eval BGCandidate.remove(i)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }


        .var BackgroundColor = BGCandidate.get(0)

        // Variable for keeping track of which byte is in use
        .var ByteNumber = 0

        // Create hashtable and ascociate bitmap patterns to RGB Colors (one for bit patterns and one for collor referance)
        .var ColorIndex = Hashtable()
        .var ColorIndex2 = Hashtable()

        // Define the BG Color into the Color Indexes
        .eval ColorIndex.put(BackgroundColor,0)
        .eval ColorIndex2.put(0,BackgroundColor)

        .for (var BlockNumber = 0 ; BlockNumber < 1000 ; BlockNumber++) {

            // Variable for keeping track of which collor is to be used inside the block
            .var colpos = 1

            // Place the RGB color data into the color indexes (Multicolor Bit-combinations 01, 10 & 11 assigned the 3 colors)
            .for (var i = 0 ; i < 4 ; i++) {
                .if (RGBColorTable.get(i+[BlockNumber*4]) != BackgroundColor) {
                    .if (RGBColorTable.get(i+[BlockNumber*4]) != null) {
                        .eval ColorIndex.put(RGBColorTable.get(i+[BlockNumber*4]),colpos)
                        .eval ColorIndex2.put(colpos,RGBColorTable.get(i+[BlockNumber*4]))
                        .eval colpos = colpos+1
                    }
                }
            }

            // Read Pixel Collors in current block and fill in BMPData accordingly
            .for (var Byte = 0 ; Byte < 8 ; Byte++) {

                // Temp Storage for bitmap byte, bitmap pattern and the pixelcolor
                .var BMPByte = 0
                .var BMPPattern = 0
                .var PixelColor = 0

                // Find the pixel collors and cross ref. with the bit patterns to create the BMP data
                .for (var Pixel = 0 ; Pixel < 4 ; Pixel++) {
                        .eval PixelColor = Graphics.getPixel([[8*BlockNumber]+[[Pixel<<1]&7]]-[320*[floor(BlockNumber/40)]], [8*floor(BlockNumber/40)]+Byte)
                        .eval BMPPattern = ColorIndex.get(PixelColor)
                        .eval BMPByte = BMPByte|[BMPPattern << [6 - Pixel*2]]
                }

                // Set the done BMP data into final data storage
                .eval AllData.set(ByteNumber,BMPByte)
                .eval ByteNumber = ByteNumber+1
            }

            // Create the color data
            .var CharacterColor = 0
            .var D800Color = 0

            .if (RGBtoC64.get(ColorIndex2.get(1)) != null) { .eval CharacterColor = [RGBtoC64.get(ColorIndex2.get(1))<<4] }
            .if (RGBtoC64.get(ColorIndex2.get(2)) != null) { .eval CharacterColor = CharacterColor|RGBtoC64.get(ColorIndex2.get(2)) }
            .if (RGBtoC64.get(ColorIndex2.get(3)) != null) { .eval D800Color = RGBtoC64.get(ColorIndex2.get(3)) }

            // Store the colors into final data storage
            .eval AllData.set(8000+BlockNumber,CharacterColor)
            .eval AllData.set(9000+BlockNumber,D800Color)
        }

        .pc = BMPData "KOALA - Bitmap Graphics"
        .fill 8000,AllData.get(i)
        .pc = Chardata "KOALA - Character Color Data"
        .fill 1000,AllData.get(i+8000)
        .pc = D800data "KOALA - D800 Color Data"
        .fill 1000,AllData.get(i+9000)
        .pc = BGC "KOALA - bg color"
        .fill 1,BackgroundColor

    }


//
// Enter hires bitmap mode (a.k.a. standard bitmap mode)
//
.macro SetHiresBitmapMode() {
    //
    // Clear extended color mode (bit 6) and set bitmap mode (bit 5)
    //
    lda $d011
    and #%10111111
    ora #%00100000
    sta $d011

    //
    // Clear multi color mode (bit 4)
    //
    lda $d016
    and #%11101111
    sta $d016
}

.macro ResetStandarbyteitMapMode() {
    lda $d011
    and #%11011111
    sta $d011
}

.macro SetBitmapAddress(address) {
    //
    // In standard bitmap mode the location of the bitmap area can
    // be set to either BANK address + $0000 or BANK address + $2000
    //
    // By setting bit 3, we can configure which of the locations to use.
    //

    .var bits=0

    lda $d018

    .if (address == $0000) {
        and #%11110111
    }

    .if (address == $2000) {
        ora #%00001000
    }

    sta $d018
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

.macro SetScreenMemory(address) {

    .var bits = (address / $0400) << 4

    lda $d018
    and #%00001111
    ora #bits
    sta $d018
}

//
// Fill screen memory with a value.
//
// Args:
//      address: Absolute base address of screen memory.
//      value: byte value to fill screen memory with
//
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

//
// Makes program halt until space is pressed. Useful when debugging.
//
.macro WaitForSpace() {
checkdown:
    lda $dc01
    cmp #$ef
    bne checkdown

checkup:
    lda $dc01
    cmp #$ef
    beq checkup
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

    .macro copymem_eor(src,dst,size) {
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

    .macro copymem_bitmap(src,dst) {
        lda #<src // set our source memory address to copy from, $6000
        sta $FB
        lda #>src 
        sta $FC
        lda #<dst // set our destination memory to copy to, $5000
        sta $FD 
        lda #>dst
        sta $FE

        ldx #31 // size of copy
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

        ldy #$00

    copyloop2:

        lda ($FB),y  // indirect index source memory address, starting at $00
        //eor ($FD),y  // indirect index dest memory address, starting at $00
        sta ($FD),y  // indirect index dest memory address, starting at $00
        iny
        cpy #64
        bne copyloop2 // loop until our dest goes over 255

    }


    .macro copymem_line(src,dst) {
        lda #<src // set our source memory address to copy from, $6000
        sta $FB
        lda #>src 
        sta $FC
        lda #<dst // set our destination memory to copy to, $5000
        sta $FD 
        lda #>dst
        sta $FE

        ldy #$00

    copyloop:

        lda ($FB),y  // indirect index source memory address, starting at $00
        //eor ($FD),y  // indirect index dest memory address, starting at $00
        sta ($FD),y  // indirect index dest memory address, starting at $00
        iny
        bne copyloop // loop until our dest goes over 255

        inc $FC // increment high order source memory address
        inc $FE // increment high order dest memory address

    copyloop2:

        lda ($FB),y  // indirect index source memory address, starting at $00
        //eor ($FD),y  // indirect index dest memory address, starting at $00
        sta ($FD),y  // indirect index dest memory address, starting at $00
        iny
        cpy #65
        bne copyloop2 // loop until our dest goes over 255

    }

    .macro clear_line(dst) {
        lda #<dst // set our destination memory to copy to, $5000
        sta $FD 
        lda #>dst
        sta $FE

        ldy #$00

    copyloop:

        lda #0
        sta ($FD),y  // indirect index dest memory address, starting at $00
        iny
        bne copyloop // loop until our dest goes over 255

        inc $FE // increment high order dest memory address

    copyloop2:

        lda #0
        sta ($FD),y  // indirect index dest memory address, starting at $00
        iny
        cpy #64
        bne copyloop2 // loop until our dest goes over 255

    }

    .macro copymem_colorline(src,dst) {
        lda #<src // set our source memory address to copy from, $6000
        sta $FB
        lda #>src 
        sta $FC
        lda #<dst // set our destination memory to copy to, $5000
        sta $FD 
        lda #>dst
        sta $FE

        ldy #0

    copyloop:

        lda ($FB),y  // indirect index source memory address, starting at $00
        //eor ($FD),y  // indirect index dest memory address, starting at $00
        sta ($FD),y  // indirect index dest memory address, starting at $00
        iny
        cpy #40
        bne copyloop // loop until our dest goes over 255

    }

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

.pc = $f00 "democode"

start:
	// clear memory so we won't have any bullshit in there
	FillBitmap($4000,0)
	FillBitmap($6000,0)
	FillBitmap($8000,0)
	
loop:
	inc $d020
	jmp loop

.fill 1024,0

