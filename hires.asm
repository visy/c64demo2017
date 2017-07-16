//
// Switch bank in VIC-II
//
// Args:
//    bank: bank number to switch to. Valid values: 0-3.
//
.macro SwitchVICBank(bank) {
    //
    // The VIC-II chip can only access 16K bytes at a time. In order to
    // have it access all of the 64K available, we have to tell it to look
    // at one of four banks.
    //
    // This is controller by bits 0 and 1 in $dd00 (PORT A of CIA #2).
    //
    //  +------+-------+----------+-------------------------------------+
    //  | BITS |  BANK | STARTING |  VIC-II CHIP RANGE                  |
    //  |      |       | LOCATION |                                     |
    //  +------+-------+----------+-------------------------------------+
    //  |  00  |   3   |   49152  | ($C000-$FFFF)*                      |
    //  |  01  |   2   |   32768  | ($8000-$BFFF)                       |
    //  |  10  |   1   |   16384  | ($4000-$7FFF)*                      |
    //  |  11  |   0   |       0  | ($0000-$3FFF) (DEFAULT VALUE)       |
    //  +------+-------+----------+-------------------------------------+
    .var bits=%11

    .if (bank==0) .eval bits=%11
    .if (bank==1) .eval bits=%10
    .if (bank==2) .eval bits=%01
    .if (bank==3) .eval bits=%00

    .print "bits=%" + toBinaryString(bits)

    //
    // Set Data Direction for CIA #2, Port A to output
    //
    lda $dd02
    and #%11111100  // Mask the bits we're interested in.
    ora #$03        // Set bits 0 and 1.
    sta $dd02

    //
    // Tell VIC-II to switch to bank
    //
    lda $dd00
    and #%11111100
    ora #bits
    sta $dd00
}

.macro SetMultiColorMode() {
    lda $d016
    ora #16
    sta $d016   
}



    // VICE C64 PALETTE

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

.macro ResetStandardBitMapMode() {
    lda $d011
    and #%11011111
    sta $d011
}

//
// Set location of bitmap.
//
// Args:
//    address: Address relative to VIC-II bank address.
//             Valid values: $0000 (bitmap at $0000-$1FFF)
//                           $2000 (bitmap at $2000-$3FFF)
//
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

//
// Switch location of screen memory.
//
// Args:
//   address: Address relative to current VIC-II bank base address.
//            Valid values: $0000-$3c00. Must be a multiple of $0400.
//
.macro SetScreenMemory(address) {
    // 
    // The most significant nibble of $D018 selects where the screen is
    // located in the current VIC-II bank.
    //
    //  +------------+-----------------------------+
    //  |            |         LOCATION*           |
    //  |    BITS    +---------+-------------------+
    //  |            | DECIMAL |        HEX        |
    //  +------------+---------+-------------------+
    //  |  0000XXXX  |      0  |  $0000            |
    //  |  0001XXXX  |   1024  |  $0400 (DEFAULT)  |
    //  |  0010XXXX  |   2048  |  $0800            |
    //  |  0011XXXX  |   3072  |  $0C00            |
    //  |  0100XXXX  |   4096  |  $1000            |
    //  |  0101XXXX  |   5120  |  $1400            |
    //  |  0110XXXX  |   6144  |  $1800            |
    //  |  0111XXXX  |   7168  |  $1C00            |
    //  |  1000XXXX  |   8192  |  $2000            |
    //  |  1001XXXX  |   9216  |  $2400            |
    //  |  1010XXXX  |  10240  |  $2800            |
    //  |  1011XXXX  |  11264  |  $2C00            |
    //  |  1100XXXX  |  12288  |  $3000            |
    //  |  1101XXXX  |  13312  |  $3400            |
    //  |  1110XXXX  |  14336  |  $3800            |
    //  |  1111XXXX  |  15360  |  $3C00            |
    //  +------------+---------+-------------------+
    //
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

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    PNGtoHIRES
    ~~~~~~~~~~

        By: TWW/CTR

    USAGE
    ~~~~~

        :PNGtoHIRES("Filename.png", BitmapMemoryAddress, ScreenMemoryColors)

        @SIGNATURE      void PNGtoHIRES (STR Filename.png ,U16 BitmapMemoryAddress, U16 ScreenMemoryColors)
        @AUTHOR         tww@creators.no

        @PARAM          Filename.png        - Filename & path to picture file
        @PARAM          BitmapMemoryAddress - Memorylocation for output of bmp-data
        @PARAM          ScreenMemoryColors  - Memorylocation for output of Char-data


    EXAMPLES
    ~~~~~~~~

        :PNGtoHIRES("something.png", $2000, $2000+8000)


    NOTES
    ~~~~~

        For now, only handles 320x200


    IMPROVEMENTS
    ~~~~~~~~~~~~

        Add variable picture sizes
        Handle assertions if the format is unsupported (size, color restrictions etc.)

    TODO
    ~~~~


    BUGS
    ~~~~


~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

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


//
// Stabilize the IRQ so that the handler function is called exactly when the
// line scan begins.
//
// If an interrupt is registered when the raster reaches a line, an IRQ is
// triggered on the first cycle of that line scan. This means that the code we
// want to esecute at that line will not be called immediately. There's quite
// a lot of housekeeping that needs to be done before we get called.
//
// What's worse is that it isn't deterministic how many cycles will pass from
// when the raster starts at the current line untill we get the call.
//
// First, the CPU needs to finish its current operation. This can mean a delay
// of 0 to 7 cycles, depending on what operation is currently running.
//
// Then we spend 7+13 cycles invoking the interrupt handler and pushing stuff to
// the stack.
//
// So all in all we're being called between 20 and 27 cycles after the current line
// scan begins.
//
// This macro removes that uncertainty by registering a new irq on the next line,
// after that second interrupt is registered, it calls nop's until a line change
// should occur.
//
// Now we know that the cycle type of the current op is only one cycle, so the only
// uncertainty left is wether ran one extra cycle or not. We can determine that by
// loading and comparing the current raster line ($d012) with itself. If they're not
// equal, we switched raster line between the load and the compare -> we're ready to go.
//
// If they're equal, we haven't switched yet but we know we'll switch at the next cycle.
// So we just wait an extra cycle in this case.
//
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

.macro RasterInterrupt(address, line) {
    //
    // Address to jump to when raster reaches line.
    // Since we have the kernal banked out, we set the address
    // of our interrupt routine directly in $fffe-$ffff instead
    // of in $0314-$0315.
    //
    // If the kernal isn't banked out, it will push registers on the stack,
    // check if the interrupt is caused by a brk instruction, and eventually
    // call the interrupt function stored in the $0134-$0315 vector.
    //
    lda #<address
    sta $fffe       // Instead of $0314 as we have no kernal rom
    lda #>address
    sta $ffff       // Instead of $0315 as we have no kernal rom

    //
    // Configure line to trigger interrupt at
    //
    /* .if(line > $ff) { */
        lda $d011
        ora #%10000000
        sta $d011

        lda #>line
        sta $d012
    /* } else { */
    /*     lda $d011 */
    /*     and #%01111111 */
    /*     sta $d011 */
    /*  */
    /*     lda #line */
    /*     sta $d012 */
    /* } */
}

.plugin "se.triad.kickass.CruncherPlugins"



.var vic_bank=1
.var vic_base=$4000*vic_bank    // A VIC-II bank indicates a 16K region
.var screen_memory=$1000 + vic_base
.var bitmap_address=$2000 + vic_base

.var music = LoadSid("nightre.sid")


BasicUpstart2(start)

start:
    jmp start2


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

generate_lookups:
    ldx #$00
genloop:
    txa
    and #$07
    asl
    asl
    sta $FC
    txa
    lsr
    lsr
    lsr
    sta $FD
    lsr
    ror $FC
    lsr
    ror $FC
    adc $FD
    ora #$60 // bitmap address $6000
    sta YTABHI,x
    lda $FC
    sta YTABLO,x
    inx
    cpx #200
    bne genloop

    lda #$80
    sta $FC
    ldx #$00
genloop2:
    txa
    and #$F8
    sta XTAB,x
    lda $FC
    sta BITTAB,x
    lsr
    bcc genskip
    lda #$80
genskip:
    sta $FC
    inx
    bne genloop2

    rts

YTABHI:
.fill 200,0

YTABLO:
.fill 200,0

BITTAB:
.fill 256,0

XTAB:
.fill 256,0

.macro putpixel() {
    lda YTABLO,y
    sta $FC
    lda YTABHI,y
    sta $FD
    ldy XTAB,x
    lda ($FC),y
    ora BITTAB,x
    sta ($FC),y
}

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
    jsr bolpix

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
    jsr bolpix

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
    jsr bolpix

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
    jsr bolpix

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

.pc = $9000 "dkdloader" // will be overwritten with gfx runtime

dkdloader:
.import c64 "dkdload.prg"

.pc = $0cdb "democode"

loadfile:
    ldx $FB
    ldy $FC
    jsr $0100
    rts

start2:
    lda #0
    sta $d020
    sta $d021

    SwitchVICBank(1)

    lda #$36
    sta $01
    lda #$01
    jsr dkdloader // init the dkd loader to $0100

    jsr generate_lookups

    sei

    // Turn off interrupts from the two CIA chips.
    // Used by the kernal to flash cursor and scan 
    // keyboard.
    lda #$7f
    sta $dc0d //Turn off CIA 1 interrupts
    sta $dd0d //Turn off CIA 2 interrupts

    lda #<nmi_nop
    sta $fffa
    lda #>nmi_nop
    sta $fffb
    // Reading these registers we ack any pending CIA interrupts.
    // Otherwise, we might get a trailing interrupt after setup.

    // Tell VIC-II to start generating raster interrupts
    lda #$01
    sta $d01a //Turn on raster interrupts

    // Bank out BASIC and KERNAL.
    // This causes the CPU to see RAM instead of KERNAL and
    // BASIC ROM at $E000-$FFFF and $A000-$BFFF respectively.
    //
    // This causes the CPU to see RAM everywhere except for
    // $D000-$E000, where the VIC-II, SID, CIA's etc are located.
    //
    lda #$35
    sta $01

    lda #<nmi_nop
    sta $fffa
    lda #>nmi_nop
    sta $fffb

    lda #$00
    sta $dd0e       // Stop timer A
    sta $dd04       // Set timer A to 0, NMI will occure immediately after start
    sta $dd0e

    lda #$81
    sta $dd0d       // Set timer A as source for NMI

    lda #$01
    sta $dd0e       // Start timer A -> NMI

    ldx #0
    ldy #0
    lda #music.startSong                      //<- Here we get the startsong and init address from the sid file
    jsr music.init  

    RasterInterrupt(mainirq, $35)

    cli

koalapic:

    lda #$d8
    sta $d016
    lda #$19
    sta $d018
    lda #$3b
    sta $d011
    lda #0
    sta $d020
    lda $a000 // bgcolor
    sta $d021

    ldx #0

koalaloop:
    .for (var i=0; i<4; i++) {
        lda $9600+i*$100,x    // copy color to color ram
        sta $d800+i*$100,x
    }
    inx
    bne koalaloop

    ldx #255
    ldy #255
    jsr wait
    ldx #255
    ldy #255
    jsr wait

    ldx #255
    ldy #255
    jsr wait

    :centerwipeoutmc_trans(50)

    lda $d011
    eor #%00010000 // off
    sta $d011

    ldx #255
    ldy #255
    jsr wait

    lda #7
    sta $FA
fade_screen1:
    ldx #255
    ldy #45
    jsr wait
    ldx $FA
    lda fade_border_tab,x
    sta $d020
    dex
    stx $FA
    cpx #0
    bne fade_screen1

    lda $d011
    eor #%00010000 // on
    sta $d011

dotball:

// 16x16
    lda #$11
    sta $d011

    lda #6
    sta $d020
    sta $d021

    :FillScreenMemory($d800,(0<<4) + 1) // color ram
    :FillScreenMemory($4400, 0) // screen mem
    :FillScreenMemory($6000, 0) // character mem aka 128x128 "framebuffer"
    :FillScreenMemory($63e8, 0) // character mem
    :FillScreenMemory($63e8+$3e8*1, 0) // character mem
    :FillScreenMemory($63e8+$3e8*2, 0) // character mem
    lda #%00011000
    sta $d018

    lda #$02   // set vic bank #1 with the dkd loader way
    and #$03
    eor #$3f
    sta $dd02

    lda #$02   // set vic bank #1
    sta $dd00


loop16:
    ldy #1
    jsr wait

    sei

    lda #$44
    sta i162+2
    lda index16
    tax
    clc
    lda sintab,x

    sta $FC
    cmp #128
    bcc over_half_sin
    lda #$65 // adc zp
    sta sinop

    lda $FC
    clc
    ror
    clc
    ror
    clc
    ror
    clc
    sta $FC
    lda #32
    sbc $FC
    sta $FC

    jmp no_neg_sin
over_half_sin:
    lda $FC
    clc
    ror
    clc
    ror
    clc
    ror
    clc
    sta $FC

    lda #$e5 // sbc zp
    sta sinop

no_neg_sin:
    
    lda #4*40+12
    clc
sinop:
    adc $FC

    sta i162+1
    jsr init16 // address for 16x16 screen pos
    cli
    lda #0
    ldx index16
    clc
    adc sintab,x 
    clc
    adc #64
    tax
    lda index16
    clc
    adc index16+1
    and #255
    tay
    lda #63
    adc costab,y
    tay

    jsr putpix16

    inc frame
    inc index16

    lda index16
    cmp #255
    bne no_index_clear
    lda #0
    sta index16
    :FillScreenMemory($4400, 0) // screen mem

no_index_clear:

    lda frame
    cmp #32
    bne no_fres

    inc index16+1
    lda #0
    sta frame
    lda index16+1
    cmp #5
    beq exit16

no_fres:
    jsr feedback16

    jmp loop16

feedback16:
//    copymem_eor($6000,$6081,4) // sierpinski

    copymem_eor($6000,$6081,4)

    rts

fade_border_tab:
    .byte 14,8,4,11,10,9,6,0


exit16:

    :centerwipeout16_trans(30)

    lda #0
    sta $FA
// hires part
fade_border1:
    ldx #255
    ldy #45
    jsr wait
    ldx $FA
    lda fade_border_tab,x
    sta $d020
    inx
    stx $FA
    cpx #7
    bne fade_border1

    lda #0
    sta $d020
    sta $d021

    ldy #255
    jsr wait

dithersandpics:

    lda $d011
    eor #%00010000 // off
    sta $d011

    lda #$02   // set vic bank #1 with the dkd loader way
    and #$03
    eor #$3f
    sta $dd02

    SetHiresBitmapMode()
    SetScreenMemory(screen_memory - vic_base)
    SetBitmapAddress(bitmap_address - vic_base)

    lda #0
    sta $d020

    :B2_DECRUNCH(crunch_logo)

    lda $d011
    eor #%00010000 // on
    sta $d011

    ldy #255
    jsr wait
    ldy #255
    jsr wait
    ldy #255
    jsr wait
    ldy #255
    jsr wait


    ldy #255
    jsr wait

    jsr dithers
afterdithers:
    lda #<$9000
    sta $FB
    lda #>$9000
    sta $FC
    lda #1
    jsr loadfile 

    :centerwipein_trans(30)


    lda #<$9000
    sta $FB
    lda #>$9000
    sta $FC
    lda #2
    jsr loadfile 

    :centerwipeout_trans(30)

    :centerwipein_trans(30)


    lda #<$9000
    sta $FB
    lda #>$9000
    sta $FC
    lda #6
    jsr loadfile 

    :centerwipeout_trans(30)

    lda #6
    sta $d020

    :centerwipein_trans(30)

    ldx #255
    ldy #255
    jsr wait
    ldy #255
    jsr wait
    ldy #255
    jsr wait

    :centerwipeout_trans(30)

    lda #0
    sta $d020

    // glitch logo top & bot
    /*
    :copymem_eor($6000,$6000-1,5)
    :copymem_eor($6000+320*20,$6000+320*20-1,5)
    */


bols:
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

    :copymem(bolchars,$6000,16)
    :FillScreenMemory($d800,(1<<4) + 1) // color ram
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
    ldx #3
    ldy #3
    jsr wait
    :copymem_eor_short($4400,$4400+40,3)

    inc frame2
    lda frame2
    cmp #255
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
bolscroll:
    lda #$10
    sta $d011

    lda #$02   // set vic bank #1 with the dkd loader way
    and #$03
    eor #$3f
    sta $dd02

    lda #0
    sta $d020
    lda #0
    sta $d021

    :copymem(bolchars,$6000,16)
    :FillScreenMemory($d800,(1<<4) + 1) // color ram
    :FillScreenMemory($4400, 0)


    lda #0 // disable sprites
    sta $d015

    centerwipeoutmc_trans(30)

    :FillScreenMemory($d800,(1<<4) + 1) // color ram
    lda #0
    sta $d021

    // load bolscroll-data to 6800-c8000
    lda #<$6800
    sta $FB
    lda #>$6800
    sta $FC
    lda #7
    jsr loadfile 

    :FillScreenMemory($d800,(1<<4) + 1) // color ram

    :copymem($6800,$4400,4)
/*
.for (var f = 0; f<16; f++) {
    lda #<$6800+1000*f
    sta $FB
    lda #>$6800+1000*f
    sta $FC
    lda #f
    clc
    adc #7
    jsr loadfile 
}
*/
    lda #<$6800
    sta $F9
    lda #>$6800
    sta $FA

    lda $F9
    sta $FB
    lda $FA
    sta $FC
    lda #<$4400
    sta $FD
    lda #>$4400
    sta $FE

    lda #0
    sta $F6
    sta $F7
    sta $F8

    lda #0
    sta $F5
    lda #%10010111
    sta $d011

    lda #0
    sta $DB // dblbuf

fillloop1:

    lda $DB
    cmp #0
    bne bolbuf1
bolbuf0:
    lda #%00101000 // 4400
    sta $d018
    ldx #0
    lda #<$4400
    sta $FD
    lda #>$4400
    sta $FE

    jmp bolbufflipped
bolbuf1:
    lda #%00011000 // 4800
    sta $d018
    ldx #0
    lda #<$4800
    sta $FD
    lda #>$4800
    sta $FE

bolbufflipped:
    inc $DB
    lda $DB
    cmp #2
    bne no_boldblres
    lda #0
    sta $DB
no_boldblres:


    lda #0
    sta $F5

finescrbol:
    
    lda #%10011000
    clc
    sbc $f5
    sta $d011
    ldy #1
    jsr wait

    inc $F5
    lda $F5
    cmp #8
    bne finescrbol

    lda #0
    sta $F5

//    2db2
/*
    ldx #00

fillloop:
    lda $F6
    beq doEor
    asl
    beq noEor
    bcc noEor
doEor:  
    eor #$1d
noEor:  
    sta $F6
    eor $F7
    sta $d800,x
    sta $d900,x
    sta $da00,x
    sta $db00,x
    inx
    bne fillloop

    inc $F8

    lda $F8
    cmp #32
    bne no_incflasheor
    lda #0
    sta $F8
    inc $F7
no_incflasheor:
    sta $4400,x
    sta $4500,x
    sta $4600,x
    sta $4700,x

    eor $F7
    sta $d800,x
    sta $d900,x
    sta $da00,x
    sta $db00,x
*/
    ldx #0
bol_copyloop_y:
    ldy #0

bol_copyloop_x:

    lda ($FB),y  // indirect index source memory address, starting at $00
    sta ($FD),y  // indirect index dest memory address, starting at $00
    iny
    cpy #40
    bne bol_copyloop_x // loop until our dest goes over 255

    lda $FB
    clc
    adc #40
    sta $FB
    bcc bol_no_fb_up
    inc $FC
bol_no_fb_up:
    lda $FD
    clc
    adc #40
    sta $FD
    bcc bol_no_fd_up
    inc $FE
bol_no_fd_up:
    
    inx
    cpx #25
    bne bol_copyloop_y




    lda $F9
    clc
    adc #40
    sta $F9
    bcc bol_no_fb_up2
    inc $FA
bol_no_fb_up2:


    lda $F9
    sta $FB
    lda $FA
    sta $FC
    cmp #$a3
    beq boscroll_over


    ldx #0

    jmp fillloop1

boscroll_over:

    ldx #255
    ldy #255
    jsr wait
    ldx #255
    ldy #255
    jsr wait

randbols:

// randbols

    lda #0
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

    // bols end

endloop:
    jmp endloop


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
    .byte $44,$44,$44,$44,$44,$44,$44
    .byte $45,$45,$45,$45,$45,$45
    .byte $46,$46,$46,$46,$46,$46,$46
    .byte $47,$47,$47,$47,$47
    

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

dithers:
    :FillBitmap($6000,0)
    :FillScreenMemory($5000,(11<<4) + 0)

    lda #<$9000
    sta $FB
    lda #>$9000
    sta $FC
    lda #5 
    jsr loadfile 

    :copymem_eor($9000,$6000,40)

    ldy #255
    jsr wait

    lda #<$9000
    sta $FB
    lda #>$9000
    sta $FC
    lda #3 
    jsr loadfile 

    :FillScreenMemory($5000,(12<<4) + 0)

    :copymem_eor($9000,$6000,40)

    ldy #255
    jsr wait

    lda #<$9000
    sta $FB
    lda #>$9000
    sta $FC
    lda #4
    jsr loadfile 

    :FillScreenMemory($5000,(15<<4) + 0)

    :copymem_eor($9000,$6000,40)

    ldy #255
    jsr wait

    lda #<$9000
    sta $FB
    lda #>$9000
    sta $FC
    lda #5
    jsr loadfile 

    :FillScreenMemory($5000,(1<<4) + 0)

    :copymem_eor($9000,$6000,40)

    ldy #255
    jsr wait

    lda #<$9000
    sta $FB
    lda #>$9000
    sta $FC
    lda #3
    jsr loadfile 

    :FillScreenMemory($5000,(15<<4) + 0)

    :copymem_eor($9000,$6000,40)

    ldy #255
    jsr wait

    lda #<$9000
    sta $FB
    lda #>$9000
    sta $FC
    lda #4
    jsr loadfile 

    :FillScreenMemory($5000,(12<<4) + 0)

    :copymem_eor($9000,$6000,40)

    ldy #255
    jsr wait

    :FillScreenMemory($5000,(11<<4) + 0)

    rts

pics_fromdisk:
/*
    lda #<$9000
    sta $FB
    lda #>$9000
    sta $FC
    lda prgnum // prg index
    jsr loadfile // load file #1 to $5000 (hires gfx memory dump)
    :centerwipein_trans(10)

    :drawtri(frame2,frame2)

    inc frame2
    inc prgnum

    lda prgnum
    cmp #6
    bne no_resetprg
    lda #1
    sta prgnum
no_resetprg:
*/
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
.macro centerwipein_trans(waittime) {
    :FillScreenMemory($5000,(0<<4)+0)
    :copymem($a000,$6000,35)

    ldx #0
    .for(var i=0;i<13;i++) { 
        ldy #waittime
        jsr wait
        :copymem_colorline($9000+40*12+40*i,$5000+40*12+40*i)
        :copymem_colorline($9000+40*12-40*i,$5000+40*12-40*i)
    }
}



wait:
    tya
    tax
waiter1:
waiter: 
    cpx $d012 
    bne waiter 
    dey
    bne waiter1
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


nmi_nop:
    //
    // This is the irq handler for the NMI. Just returns without acknowledge.
    // This prevents subsequent NMI's from interfering.
    //
    rti


mainirq:
    //
    // Since the kernal is switced off, we need to push the
    // values of the registers to the stack ourselves so
    // that they're restored when we're done.
    //
    // If we don't do anything advanced like calling cli to let another
    // irq occur, we don't need to use the stack.
    //
    // In that case it's faster to:
    //
    // sta restorea+1
    // stx restorex+1
    // sty restorey+1
    //
    // ... do stuff ...
    //
    // lda #$ff
    // sta $d019
    //
    // restorea: lda #$00
    // restorex: ldx #$00
    // restorey: ldy #$00
    // rti
    //
    pha
    txa
    pha
    tya
    pha

    //
    // Stabilize raster using double irq's.
//    StabilizeRaster()

    jsr music.play 

    //
    // Reset the raster interrupt since the stabilizing registered another
    // function. 
    // We can also register another irq for something further down the screen
    // or at next frame.
    //
    RasterInterrupt(mainirq, $35)

    //
    // Restore the interrupt condition so that we can get
    // another one.
    //
    lda #$ff
    sta $d019   //ACK interrupt so it can be called again

    //
    // Restore the values of the registers and return.
    //
    pla
    tay
    pla
    tax
    pla
    rti

frame:
.byte 0
frame2:
.byte 2

bolchars:
.import binary "bolchars_flip.raw"

.pc = music.location "Music"
.fill music.size, music.getData(i)

:PNGtoKOALA("terminal.png", $6000, $4400, $9600, $a000)


.pc = $8000 "crunchdata"

.label crunch_logo = *
.modify B2() {
    :PNGtoHIRES("quadlogo.png", bitmap_address, screen_memory)
}
.pc = * "crunchdata end"

.pc = $be00  "sintab"
sintab:
 .fill 256,round(63*sin(toRadians(i*360/63)))
costab:
 .fill 256,round(63*cos(toRadians(i*360/63)))
sintab2:
 .fill 256,90+round(90*sin(toRadians(i*360/255)))
costab2:
 .fill 256,100+round(100*cos(toRadians(i*360/255)))

.print "vic_bank: " + toHexString(vic_bank)
.print "vic_base: " + toHexString(vic_base)
.print "screen_memory: " + toHexString(screen_memory)
.print "bitmap_address: " + toHexString(bitmap_address)
