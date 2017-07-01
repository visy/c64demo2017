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

.var music = LoadSid("music.sid")

/*

    memory map:
    $080e - $2fff code
    $3000 - $4fff music
    $5000 - $7fff vic1
    $8000 -> crunched data
*/

BasicUpstart2(start)

start:
    jmp start2

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


start2:

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

    lda #0
    sta $d020
    sta $d021

    :B2_DECRUNCH(crunch_screen1a)
    :B2_DECRUNCH(crunch_music)
    ldx #0
    ldy #0
    lda #music.startSong                      //<- Here we get the startsong and init address from the sid file
    jsr music.init  

    SwitchVICBank(vic_bank)
    SetHiresBitmapMode()
    SetScreenMemory(screen_memory - vic_base)
    SetBitmapAddress(bitmap_address - vic_base)

    RasterInterrupt(mainirq, $35)

    cli


loop:

wait: 
    lda #$ff 
    cmp $d012 
    bne wait 

    lda frame
    cmp #$80
    bne no_switch
    lda #0
    sta frame
    inc base

    lda base
    cmp #5
    bne no_zero
    lda #0
    sta base

no_zero:

    lda $d011
    eor #%00010000
    sta $d011

    lda base
    cmp #0
    beq switch0
    cmp #1
    beq switch1
    cmp #2
    beq switch2
    cmp #3
    beq switch3
    bne switch4

switch0:
    :B2_DECRUNCH(crunch_screen1a)
    jmp no_switch2
switch1:
    :B2_DECRUNCH(crunch_screen1b)
    jmp no_switch2
switch2:
    :B2_DECRUNCH(crunch_screen1c)
    jmp no_switch2
switch3:
    :B2_DECRUNCH(crunch_screen1d)
    jmp no_switch2
switch4:
    :B2_DECRUNCH(crunch_screen1e)
    jmp no_switch2


no_switch2:
    lda $d011
    eor #%00010000
    sta $d011
no_switch:

    jmp loop
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
    StabilizeRaster()

    inc frame
    lda frame
//    sta $d020

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

base:
.byte 0

// crunched data


.label crunch_music = *
.modify B2() {
    .pc = music.location "Music"
    .fill music.size, music.getData(i)
}

.pc=$8000

.label crunch_screen1a = *
.modify B2() {
    :PNGtoHIRES("test.png", bitmap_address, screen_memory)
}

.label crunch_screen1b = *
.modify B2() {
    :PNGtoHIRES("test_a.png", bitmap_address, screen_memory)
}

.label crunch_screen1c = *
.modify B2() {
    :PNGtoHIRES("test4.png", bitmap_address, screen_memory)
}

.label crunch_screen1d = *
.modify B2() {
    :PNGtoHIRES("test5.png", bitmap_address, screen_memory)
}

.label crunch_screen1e = *
.modify B2() {
    :PNGtoHIRES("test_b.png", bitmap_address, screen_memory)
}

.print "vic_bank: " + toHexString(vic_bank)
.print "vic_base: " + toHexString(vic_base)
.print "screen_memory: " + toHexString(screen_memory)
.print "bitmap_address: " + toHexString(bitmap_address)
