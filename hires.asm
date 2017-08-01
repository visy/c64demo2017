.var part_lo = $c1
.var part_hi = $c2

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
        eor ($ED),y  // indirect index dest memory address, starting at $00
        sta ($ED),y  // indirect index dest memory address, starting at $00
        iny
        bne copyloop // loop until our dest goes over 255

        inc $EC // increment high order source memory address
        inc $EE // increment high order dest memory address
        dex
        bne copyloop // if we're not there yet, loop

    }

    .macro copymem_eor2(src,dst,size) {
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
        eor ($ED),y  // indirect index dest memory address, starting at $00
        sta ($ED),y  // indirect index dest memory address, starting at $00
        iny
        cpy #92
        bne copyloop // loop until our dest goes over 255

        inc $EC // increment high order source memory address
        inc $EE // increment high order dest memory address
        dex
        bne copyloop // if we're not there yet, loop

    }


    .macro copymem_eor_short(src,dst,size) {
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
        eor ($ED),y  // indirect index dest memory address, starting at $00
        sta ($ED),y  // indirect index dest memory address, starting at $00
        iny
        bne copyloop // loop until our dest goes over 255

        inc $EC // increment high order source memory address
        inc $EE // increment high order dest memory address
        dex
        bne copyloop // if we're not there yet, loop

        ldy #$00

    copyloop2:

        lda ($EB),y  // indirect index source memory address, starting at $00
        eor ($ED),y  // indirect index dest memory address, starting at $00
        sta ($ED),y  // indirect index dest memory address, starting at $00
        iny
        cpy #190
        bne copyloop2 // loop until our dest goes over 255

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

    .macro copymem_bitmap(src,dst) {
        lda #<src // set our source memory address to copy from, $6000
        sta $EB
        lda #>src 
        sta $EC
        lda #<dst // set our destination memory to copy to, $5000
        sta $ED 
        lda #>dst
        sta $EE

        ldx #31 // size of copy
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

        ldy #$00

    copyloop2:

        lda ($EB),y  // indirect index source memory address, starting at $00
        //eor ($FD),y  // indirect index dest memory address, starting at $00
        sta ($ED),y  // indirect index dest memory address, starting at $00
        iny
        cpy #64
        bne copyloop2 // loop until our dest goes over 255

    }


    .macro copymem_line(src,dst) {
        lda #<src // set our source memory address to copy from, $6000
        sta $EB
        lda #>src 
        sta $EC
        lda #<dst // set our destination memory to copy to, $5000
        sta $ED 
        lda #>dst
        sta $EE

        ldy #$00

    copyloop:

        lda ($EB),y  // indirect index source memory address, starting at $00
        //eor ($FD),y  // indirect index dest memory address, starting at $00
        sta ($ED),y  // indirect index dest memory address, starting at $00
        iny
        bne copyloop // loop until our dest goes over 255

        inc $EC // increment high order source memory address
        inc $EE // increment high order dest memory address

    copyloop2:

        lda ($EB),y  // indirect index source memory address, starting at $00
        //eor ($FD),y  // indirect index dest memory address, starting at $00
        sta ($ED),y  // indirect index dest memory address, starting at $00
        iny
        cpy #65
        bne copyloop2 // loop until our dest goes over 255

    }

    .macro clear_line(dst) {
        lda #<dst // set our destination memory to copy to, $5000
        sta $ED 
        lda #>dst
        sta $EE

        ldy #$00

    copyloop:

        lda #0
        sta ($ED),y  // indirect index dest memory address, starting at $00
        iny
        bne copyloop // loop until our dest goes over 255

        inc $FE // increment high order dest memory address

    copyloop2:

        lda #0
        sta ($ED),y  // indirect index dest memory address, starting at $00
        iny
        cpy #64
        bne copyloop2 // loop until our dest goes over 255

    }

    .macro copymem_colorline(src,dst) {
        lda #<src // set our source memory address to copy from, $6000
        sta $EB
        lda #>src 
        sta $EC
        lda #<dst // set our destination memory to copy to, $5000
        sta $ED 
        lda #>dst
        sta $EE

        ldy #0

    copyloop:

        lda ($EB),y  // indirect index source memory address, starting at $00
        //eor ($FD),y  // indirect index dest memory address, starting at $00
        sta ($ED),y  // indirect index dest memory address, starting at $00
        iny
        cpy #40
        bne copyloop // loop until our dest goes over 255

    }

    .macro clear_colorline(dst) {
        lda #<dst // set our destination memory to copy to, $5000
        sta $ED 
        lda #>dst
        sta $EE
        ldy #0
    copyloop:
        lda #0    
        sta ($ED),y  // indirect index dest memory address, starting at $00
        iny
        cpy #40
        bne copyloop // loop until our dest goes over 255

    }

    .macro clear_colorline_blue(dst) {
        lda #<dst // set our destination memory to copy to, $5000
        sta $ED 
        lda #>dst
        sta $EE
        ldy #0
    copyloop:
        lda #6    
        sta ($ED),y  // indirect index dest memory address, starting at $00
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
        .for (var Line = 0 ; Line < 64 ; Line = Line + 8) {
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
        .for (var i = 0 ; i < 320 ; i++ ) {
            .byte ScreenMem.get(i)
        }
    }


.plugin "se.triad.kickass.CruncherPlugins"



.var vic_bank=1
.var vic_base=$4000*vic_bank    // A VIC-II bank indicates a 16K region
.var screen_memory=$1000 + vic_base
.var bitmap_address=$2000 + vic_base


.pc = $1000 "democode"

start:
init_text:  ldx #$00         // init X register with $00
loop_text:  lda line1,x      // read characters from line1 table of text...
           sta $0428,x      // ...and store in screen ram near the center

           inx 
           cpx #$28         // finished when all 40 cols of a line are processed
           bne loop_text    // loop if we are not done yet

    ldy #255
    jsr wait
    ldy #255
    jsr wait


    lda #1
    sta $d1

    lda #0
    jsr $c000

    sei
    lda #<short_irq
    sta $fffe
    lda #>short_irq
    sta $ffff
    lda #$7f
    sta $dc0d
    lda #$01
    sta $d01a

    lda #255
    sta $d012

    cli

    lda #0
    sta $d020
    sta $d021
    sta part_lo
    sta part_hi

    lda #$40 // rti
    sta $0900

    // restore handler
    lda #<$0900
    sta $fffa
    lda #>$0900
    sta $fffb


loop1:

    bit $d011 // Wait for new frame
    bpl *-3
    bit $d011
    bmi *-3



    lda #$1b // Set y-scroll to normal position (because we do FLD later on..)
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
    sta $d011

    dex // Decrease counter
    bne loop2 // Branch if counter not 0

    jmp loop1 // Next frame

CalcNumLines:
    lda no_new_fld_calc
    cmp #1
    bne do_calc_fld
    rts
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
    ldx #0
    lda sinus,x
    clc
    adc fldframe+1
    sta NumFLDLines
    cmp #200
    bcc no_stop_fld
    bne real_start0
no_stop_fld:
    inc CalcNumLines2+1
    rts
real_start0:
    jmp real_start

no_new_fld_calc:
    .byte 0
NumFLDLines:
    .byte 0

fldframe:
    .byte 0,0

line1: .text "    **** only 8580 sid working ****     "

.align $100
sinus:
    .fill 256, 64.5*abs(sin(toRadians(i*360/128))) // Generates a sine curve

fadetab:
    .byte $00, $06, $0b, $04, $0c, $03, $0d, $01
real_start:

    lda $d011
    eor #%00010000 // off
    sta $d011

    FillScreenMemory($0400,$20)

    ldy #64
    jsr wait

    lda #$02   // set vic bank #1 with the dkd loader way
    and #$03
    eor #$3f
    sta $dd02

    FillScreenMemory($4400,255)

    FillScreenMemory($d800,$01)


    ldx #0
fadetowhite:
    lda fadetab,x

    sta $d020
    sta $d021

    ldy #10
    jsr wait3

    inx
    cpx #7
    bne fadetowhite
    jmp demo_init


    // demo init
demo_init:

    // Set up raster interrupt.
    lda     #$3b
    sta     $d011
    lda     #255
    sta     $d012
    lda     #$01
    sta     $d01a

    lsr     $d019

    lda #0
    sta $d1

    lda #$d8
    sta $d016

    lda #%01001000
    sta $d018

    lda #1
    sta $d020
    lda #1 // bgcolor
    sta $d021

    FillScreenMemory($4000,%00010001)

    SetHiresBitmapMode()

    lda #%00111011
    sta $d011

    ldy #1
    jsr waitforpart


titlepics:

    lda #%00000000
    sta $d018

    copymem($8000,$5000,10)
    copymem($9000,$6000,30)

    lda #%01001000
    sta $d018

    ldy #2
    jsr waitforpart

    lda #%00000000
    sta $d018

    copymem($b000,$5000,10)
    copymem($e000,$6000,30)

    lda #%01001000
    sta $d018


    jsr $c90


    ldy #3
    jsr waitforpart

    lda #0
    sta $d020
    sta $d021
    lda #%00110000
    sta $d018

    lda #%00101011
    sta $d011

    FillBitmap($4000,0)

    lda #%00111011
    sta $d011

koalapic: // logoscene
    copymem($ee00,$4000,1)
    copymem($8000,$6000,30)
    copymem($e000,$4400,8)

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

    // Setup some sprites
    lda #%00111111
    sta $d015

    lda #0
    sta $d01c

    lda #1
    sta $d027
    sta $d028
    sta $d029
    lda #0
    sta $d02a
    sta $d02b
    sta $d02c

    lda #$0
    sta $4400+$3f8
    lda #$1
    sta $4400+$3f9
    lda #$2
    sta $4400+$3fa
    lda #$0
    sta $4400+$3fb
    lda #$1
    sta $4400+$3fc
    lda #$2
    sta $4400+$3fd

    ldy #50
    lda #68
    sta $d000
    sty $d001
    lda #70+24*1
    sta $d002
    sty $d003
    lda #70+24*2
    sta $d004
    sty $d005

    ldy #52
    lda #70
    sta $d006
    sty $d007
    lda #72+24*1
    sta $d008
    sty $d009
    lda #72+24*2
    sta $d00a
    sty $d00b


    ldx #0

koalaloop:
    .for (var i=0; i<4; i++) {
        lda $e400+i*$100,x    // copy color to color ram
        sta $d800+i*$100,x
    }
    inx
    bne koalaloop

    ldy #5
    jsr waitforpart

    :centerwipeoutmc_trans(3)


    ldx #50
sprlogomove:
    txa
    tay
    lda #68
    sta $d000
    sty $d001
    lda #70+24*1
    sta $d002
    sty $d003
    lda #70+24*2
    sta $d004
    sty $d005
    lda #70+24*3
    sta $d006
    sty $d007
    lda #70+24*4
    sta $d008
    sty $d009
    lda #70+24*5
    sta $d00a
    sty $d00b

    ldy #1
    jsr wait

    dex
    cpx #50-24
    bne sprlogomove


    lda #%00000000
    sta $d015

metropart:
    jsr $c90

    lda #0
    sta $d012

    lda #2
    sta $C9

    lda #%00111011
    sta $d011

    lda #%11001000
    sta $d016
    lda #0

    SetScreenMemory(screen_memory - vic_base)
    SetBitmapAddress(bitmap_address - vic_base)

    copymem($5000,$f000,4)
    lda #0
    sta $F0

metroloop:
    lda #200
    clc
    sbc $F0
    tay
    jsr wait
    ldy #5
    jsr wait
    copymem($9000,$5000,4)
    ldy #5
    jsr wait
    copymem($f000,$5000,4)
    ldy #5
    jsr wait
    copymem($9000,$5000,4)
    ldy #5
    jsr wait
    copymem($f000,$5000,4)
    ldy #5
    jsr wait
    ldy #5
    jsr wait
    copymem($9000,$5000,4)
    ldy #5
    jsr wait
    copymem($f000,$5000,4)
    ldy #5
    jsr wait

    inc $F0
    lda $F0
    cmp #5
    bne metroloop0
    jmp metrodone
metroloop0:
    jmp metroloop
metrodone:

    ldy #7
    jsr waitforpart


    lda #0
    sta $C9

    lda #<short_irq
    sta $fffe
    lda #>short_irq
    sta $ffff

    lda #6
    sta $d020
    sta $d021

    ldy #8
bitclrs2:
    ldx #255
bitclr:
.for(var xx = 0; xx < 32;xx++) {
    lda $6000+xx*$100,x
    asl
    sta $6000+xx*$100,x
}
    lda #6
    sta $5000,x
    sta $5100,x
    sta $5200,x
    sta $5300,x

    dex
    cpx #255
    bne bitclr0
    jmp toclr2
bitclr0:
    jmp bitclr
toclr2:
    dey
    bne bitclr2
    jmp bitclrdone
bitclr2:
    jmp bitclrs2
bitclrdone:

    ldy #255
    jsr wait3
    ldy #255
    jsr wait3
    ldy #210
    jsr wait3


    lda #%11001000
    sta $d016

    lda #240
    sta $d012

quadlogo:
    lda #%00101011
    sta $d011

    SetScreenMemory(screen_memory - vic_base)
    SetBitmapAddress(bitmap_address - vic_base)


dithersandpics:

    copymem($a000, $6000,32)
    copymem($e800, $5000,6)

    lda #%00111011
    sta $d011

    ldy #8
    jsr waitforpart


    jsr dithers
afterdithers:
    lda #%01111011
    sta $d011
    
    FillBitmap($6000,255)
    lda #%00111011
    sta $d011

    lda #00
    sta $d020
    sta $d021
    ldy #24
    jsr wait
    lda #6
    sta $d020
    sta $d021
    ldy #24
    jsr wait
    lda #11
    sta $d020
    sta $d021

    jsr $c90 // load fox && broke


    :centerwipein_trans3(3)

    ldy #13
    jsr waitforpart

    ldy #255
    jsr wait 
    lda #0
    sta $f0
foxglitch:
    copymem_eor2($7020+64+64,$7028+64+64,1) 
    copymem_eor2($7160+64+64,$7168+64+64,1) 
    copymem_eor2($72a0+64+64,$72a8+64+64,1) 
    ldy #1
    jsr wait

    inc $f0
    lda $f0
    bne foxglitch

    ldy #15
    jsr waitforpart

    :centerwipeout_trans(3)

    lda #11
    sta $d020
    ldy #16
    jsr wait
    lda #6
    sta $d020
    ldy #16
    jsr wait
    lda #0
    sta $d020

    copymem($8000,$9000,10)
    copymem($e000,$a000,32)

    :centerwipein_trans(3)


waiterlooper:
    lda $d012
    rol
    rol
    rol
    eor $d016
    and #%00000111
    sta $d016

    ldy #16
    cpy part_hi
    bne waiterlooper

    lda #%11000000
    sta $d016

    :centerwipeout_trans(3)

    FillBitmap($6000,0)
    FillScreenMemory($5000,1<<4)
    lda #%11001000
    sta $d016

    copymem($8400,$6a00-64+32+32,10)

    jsr $c90 // load spacebunny

    ldy #17
    jsr waitforpart

    lda #0
    sta $d020

    lda #0
    sta $F0
    ldy #0
coltest0:
    ldx #0
    ldy #1
    jsr wait
coltest:

    lda $5000,x
    cmp #1
    beq no_alter1
    ldy $F0
    lda fadetab2,y
    sta $5000,x
no_alter1:
    lda $5100,x
    cmp #1
    beq no_alter2
    ldy $F0
    lda fadetab2,y
    sta $5100,x
no_alter2:
    lda $5200,x
    cmp #1
    beq no_alter3
    ldy $F0
    lda fadetab2,y
    sta $5200,x
no_alter3:
    lda $5300,x
    cmp #1
    beq no_alter4
    cpx #32+80
    bcs no_alter4
    ldy $F0
    lda fadetab2,y
    sta $5300,x
no_alter4:
    inx
    cpx #0
    bne coltest
    inc $F0
    lda $F0
    cmp #8
    bne coltest0

    ldy #64
    jsr wait

    :centerwipein_trans(3)

    lda #0
    sta $d020

    // Setup some sprites
    lda #%00000001
    sta $d015

    lda #0
    sta $d01c

    lda #0
    sta $d027

    lda #$0
    sta $4400+$3f8

    lda #80
    ldy #124
    sta $d000
    sty $d001

    // glitch logo top & bot
    /*
    :copymem_eor($6000,$6000-1,5)
    :copymem_eor($6000+320*20,$6000+320*20-1,5)
    */

    ldy #128
    jsr wait

    ldx #0
eyefader:
    lda eyefade1,x
    sta $d027
    ldy #8
    jsr wait
    inx
    cpx #6
    bne eyefader

    ldy #128
    jsr wait

    ldx #5
eyefader3:
    lda eyefade1,x
    sta $d027
    ldy #8
    jsr wait
    inx
    cpx #8
    bne eyefader3

    ldy #255
    jsr wait

    ldx #3
eyemove0:
    inc $d000
    ldy #16
    jsr wait
    dex
    bne eyemove0

    ldy #128
    jsr wait

    ldx #3
eyemove1:
    dec $d000
    ldy #16
    jsr wait
    dex
    bne eyemove1

    ldy #200
    jsr wait

    ldx #2
eyemove2:
    dec $d000
    ldy #16
    jsr wait
    dex
    bne eyemove2

    ldy #128
    jsr wait

    ldx #2
eyemove3:
    inc $d000
    ldy #16
    jsr wait
    dex
    bne eyemove3

    ldy #19 //19
    jsr waitforpart

    ldx #4
eyefader2:
    lda eyefade,x
    sta $d027
    ldy #8
    jsr wait
    dex
    cpx #255
    bne eyefader2

    lda #%00000000
    sta $d015
    ldy #32
    jsr wait

    :centerwipeout_trans(3)

bols:
    lda #%01110011
    sta $d011
    jmp partswitch

eyefade:
.byte $00,$09,$02,$04,$0a

eyefade1:
.byte $00,$06,$0b,$04,$0c,$05,$0c,$0a

fadetab2:
.byte $01<<4, $0d<<4, $03<<4, $0c<<4, $04<<4, $02<<4, $09<<4, $00<<4

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
fade_border_tab:
    .byte 14,8,4,11,10,9,6,0

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

dithers:

    jsr $c90 // init to 8000, a000, e000

    lda #0
    sta $d020

    lda #%00001011
    sta $d011

    :FillBitmap($6000,0)
    :FillScreenMemory($5000,(11<<4) + 0)

    :copymem_eor($8000,$6000,32)

    lda #%00111011
    sta $d011

    lda #0
    sta $d020

    // Setup some sprites
    lda #%00000000
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

    ldy #60

    lda #68
    sta $d000
    sty $d001
    lda #67+24*1
    sta $d002
    sty $d003
    lda #68+24*2
    sta $d004
    sty $d005
    lda #69+24*3
    sta $d006
    sty $d007
    lda #69+24*4
    sta $d008
    sty $d009


    ldy #9
    jsr waitforpart


    lda #%00000111
    sta $d015

    ldy #10
    jsr waitforpart


    jsr $c90

    :FillScreenMemory($5000,(12<<4) + 0)

    :copymem_eor($a000,$6000,32)

    lda #%00000111
    sta $d015

    ldy #11
    jsr waitforpart

    lda #%00000111
    sta $d015

    jsr $c90

    :FillScreenMemory($5000,(15<<4) + 0)

    :copymem_eor($e000,$6000,32)

    lda #%00000111
    sta $d015

    ldy #12
    jsr waitforpart

    lda #%00000000
    sta $d015


    :FillScreenMemory($5000,(1<<4) + 0)

    :copymem_eor($a000,$6000,32)

    ldy #32
    jsr wait

    :FillScreenMemory($5000,(15<<4) + 0)

    :copymem_eor($8000,$6000,32)

    ldy #32
    jsr wait

    :FillScreenMemory($5000,(12<<4) + 0)

    :copymem_eor($e000,$6000,32)

    ldy #32
    jsr wait

    :FillScreenMemory($5000,(11<<4) + 0)

    lda #%00000000
    sta $d015

    rts


prgnum:
    .byte 1

    .byte 0
clear_y:
    .byte 0,0

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

.macro centerwipeout16_trans(waittime) {
    ldx #0
    .for(var i=0;i<13;i++) { 
        ldy #waittime
        jsr wait
        :clear_colorline($4400+40*12+40*i)
        :clear_colorline($4400+40*12-40*i)
    }
}

.macro centerwipeout_trans(waittime) {
    ldx #0
    .for(var i=0;i<13;i++) { 
        ldy #waittime
        jsr wait
        :clear_colorline($5000+40*12+40*i)
        :clear_colorline($5000+40*12-40*i)
    }
}

.macro centerwipeout_trans_blue(waittime) {
    ldx #0
    .for(var i=0;i<13;i++) { 
        ldy #waittime
        jsr wait
        :clear_colorline_blue($5000+40*12+40*i)
        :clear_colorline_blue($5000+40*12-40*i)
    }
}


.macro centerwipein_trans(waittime) {
    :FillScreenMemory($5000,(0<<4)+0)
    :copymem($a000,$6000,32)

    ldx #0
    .for(var i=0;i<13;i++) { 
        ldy #waittime
        jsr wait
        :copymem_colorline($9000+40*12+40*i,$5000+40*12+40*i)
        :copymem_colorline($9000+40*12-40*i,$5000+40*12-40*i)
    }
}

.macro centerwipein_trans3(waittime) {
    :FillScreenMemory($5000,(11<<4)+11)
    :copymem($a000,$6000,32)

    ldx #0
    .for(var i=0;i<13;i++) { 
        ldy #waittime
        jsr wait
        :copymem_colorline($9000+40*12+40*i,$5000+40*12+40*i)
        :copymem_colorline($9000+40*12-40*i,$5000+40*12-40*i)
    }
}

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

wait3:
waiter4:
    lda #10
    cmp $D012
    bne *-3
    dey
    cpy #0
    bne wait3
    rts


.var bres_x1 = $50
.var bres_y1 = $51
.var bres_x2 = $60
.var bres_y2 = $61
.var bres_err = $62
.var bres_cntr = $63
.var bres_dx = $64
.var bres_dy = $65

hline_sto:
    .byte 0,0,0
.macro hline() {
    sta hline_sto
    stx hline_sto+1
    sty hline_sto+2
hlineloop:
    ldy hline_sto+1
    ldx hline_sto+2
    txa
    tay
    ldx hline_sto+1
    lda #%00001000 // color, 0/8/136
//    jsr bolpix

    ldx hline_sto+1
    ldy hline_sto+2

    inx
    stx hline_sto+1
    cpx hline_sto
    bne hlineloop

}

.macro bresenham(xa,ya,xb,yb,err,cntr,dx,dy) {
    ldy ya
    cpy yb
    bne no_hline
    ldx xa
    lda xb
    :hline()
    jmp bhamdone
no_hline:

    ldy xb
    ldx yb
    lda #%10001000 // color, 0/8/136
//    jsr bolpix

    lda #$00        // initialise err
    sta err
    lda xb      // check if the line is going right or left (delta x is positive or negative)
    sec
    sbc xa
    bpl dxpos
    lda ya      // if the line is going leftward, swap xa/ya and xb/yb around so it goes rightward
    ldx yb
    sta yb
    stx ya
    lda xa
    ldx xb
    sta xb
    stx xa
    sec
    sbc xa
dxpos:          // here we have secured a rightward line, accumulator is filled with delta xa/xb
    sta dx      // save the delta
    sta cntr        // use the delta as counter for the loop
    inc cntr        // and increment by one to prevent off-by-one when we compare with 0

    lda yb      // now we check for y
    sec
    sbc ya
    bmi dyneg       // check if the line is going up or downward (delta ya/yb is negative)
    sta dy
    cmp dx      // compare delta ya/yb with delta xa/xy to see if we loop over x or y axis
    lda #$c8        // c8 is the opcode iny
    sta bhamyloop   // because delta ya/yb was positive, we increment y in this loop
    sta bhamyy      // and also in the loop over y
    bcc blup
    jmp bremenovery // and into the loop over y
blup:
    jmp dypos       // or loop over x, knowing that delta ya/yb is positive 
dyneg:
    lda #$88        // 88 is the opcode for dey
    sta bhamyloop   // because delta ya/yb was negative, we decrement y in this loop
    sta bhamyy
    lda ya      // calculate and store delta ya/yb again (this time ya-yb instead of yb-ya)
    sec
    sbc yb
    sta dy
    cmp dx
    bcs bremenovery // if delta ya/yb is larger then delta xa/xb, we loop over y
dypos:

    ldx xa      // see the C++ implementation at https://www.cs.helsinki.fi/group/goa/mallinnus/lines/bresenh.html
    ldy ya      // this is for ( int x = x1; x <= x2; 

bhamoverx:      // here the loop over x begins
    dec cntr        // first we check if we're done
    beq bhamxdone
    inx         // x++ )  {
    stx xa
    sty ya

    txa
    tay
    ldx ya
    lda #%10001000 // color, 0/8/136
//    jsr bolpix

    ldx xa
    ldy ya
    lda err     // eps += dy;
    clc
    adc dy
    sta err
    bvs bhamyloop   // if ( (eps << 1) >= dx )  {
    cmp dx
    bcc bhamoverx
bhamyloop:
    iny         // y++; 
                // or y-- if the delta ya/yb was negative
    lda err     // eps -= dx;
    sec
    sbc dx
    sta err
    jmp bhamoverx

bhamxdone:
    jmp bhamdone

bremenovery:
    lda dy
    sta cntr
    inc cntr
    ldx xa
    ldy ya

bhamovery:
    dec cntr
    beq bhamdone
bhamyy:
    iny
    stx xa
    sty ya
    txa
    tay
    ldx ya
    lda #%10001000 // color, 0/8/136
//    jsr bolpix

    ldx xa
    ldy ya
    lda err
    clc
    adc dx
    sta err
    bvs bhamxloop
    cmp dy
    bcc bhamovery
bhamxloop:
    inx
    lda err
    sec
    sbc dy
    sta err
    jmp bhamovery

bhamdone:
}

.macro drawtri(xx,yy) {
    lda #64
    sta frame
triloop:
    ldx #160
    lda #0
    clc
    adc yy
    tay
    stx bres_x1
    sty bres_y1
    lda frame
    clc
    adc xx
    tax
    lda #100
    clc
    adc yy
    tay
    stx bres_x2
    sty bres_y2
    :bresenham(bres_x1,bres_y1,bres_x2,bres_y2,bres_err,bres_cntr,bres_dx,bres_dy)

    inc frame
    lda frame
    cmp #200
    bcc no_nullframe
    jmp tri_done
no_nullframe:
    jmp triloop
tri_done:
}

loadfile:
    rts

/*
.macro drawlinetri() {
        ldx frame2
    lda #28
    clc
    adc sintab,x
    tay
    ldx #160

    stx bres_x1
    sty bres_y1

    ldx frame2
    lda #100
    clc
    adc sintab,x
    tay
    ldx #100

    stx bres_x2
    sty bres_y2
    :bresenham(bres_x1,bres_y1,bres_x2,bres_y2,bres_err,bres_cntr,bres_dx,bres_dy)

    ldx frame2
    lda #28
    clc
    adc sintab,x
    tay
    ldx #160
    stx bres_x1
    sty bres_y1

    ldx frame2
    lda #100
    clc
    adc sintab,x
    tay
    ldx #255

    stx bres_x2
    sty bres_y2
    :bresenham(bres_x1,bres_y1,bres_x2,bres_y2,bres_err,bres_cntr,bres_dx,bres_dy)

    ldx frame2
    lda #100
    clc
    adc sintab,x
    tay

    ldx #100
    stx bres_x1
    sty bres_y1
    ldx #255
    stx bres_x2
    sty bres_y2
    :bresenham(bres_x1,bres_y1,bres_x2,bres_y2,bres_err,bres_cntr,bres_dx,bres_dy)

}

*/

frame:
.byte 0
frame2:
.byte 2

bolchars:
.import binary "bolchars_flip.raw"


.pc = $3f00
short_irq:
    sta restorea+1
    stx restorex+1
    sty restorey+1

    inc $d019

    lda $C9
    cmp #2
    bne no_border
    lda #11
    sta $d020

    lda #50
    sta $d012

    lda #<short_irq2
    sta $fffe
    lda #>short_irq2
    sta $ffff

no_border:

    lda $d1
    cmp #0
    bne no_part_hi_add

    inc part_lo
    lda part_lo
    bne no_part_hi_add
    inc part_hi
no_part_hi_add:

    jsr $c003 // le musica
restorea: lda #$00
restorex: ldx #$00
restorey: ldy #$00
    rti

short_irq2:
    sta restorea2+1
    stx restorex2+1
    sty restorey2+1

    inc $d019

    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

    lda $C9
    cmp #2
    bne no_border2
    lda #0
    sta $d020

    lda #240
    sta $d012

    lda #<short_irq
    sta $fffe
    lda #>short_irq
    sta $ffff

no_border2:

restorea2: lda #$00
restorex2: ldx #$00
restorey2: ldy #$00
    rti

.pc = $3ff0 "partswitch"
partswitch:
    lda #255
waitforrasters:
    cmp $d012
    bne waitforrasters

    jsr $c90 // load part1 -> hires2.asm
.pc = * "partswitch_jmp"
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




.print "vic_bank: " + toHexString(vic_bank)
.print "vic_base: " + toHexString(vic_base)
.print "screen_memory: " + toHexString(screen_memory)
.print "bitmap_address: " + toHexString(bitmap_address)
